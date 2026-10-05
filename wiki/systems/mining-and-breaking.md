---
title: Mining and breaking
type: system
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ReplicatedStorage/Mine/Shared/MineBreaking.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ServerScriptService/Mine/MineDigAuth.luau
  - src/ServerScriptService/Mine/MinePatterns.luau
  - docs/TODO.md §0.13, §0.16
  - docs/OPEN.md P0 §3
  - docs/PROPOSAL.md §0, §F0
related: [zones-layers-and-seams, boosts-and-stats, tools, ores, forge-and-recycling, chests-and-lucky-blocks, ore-pouch-and-backpack, server]
---

# Mining and breaking

> You click a block with the tool in your hand. The server decides whether the swing lands at all, how hard it hits, which neighbours the procs reach, and what the block pays when it dies. There are two separate gates: **breaking power** decides *whether* a block can be damaged, and **damage** decides *how fast* it dies.

## How it works

**One swing.** `swingBlock` in `MineServer.server.luau` runs these steps in order:
1. **Refusals.** You have no first pick yet (`p.gotFirstPick == false`). The zone is not owned (`Gate.canMine`). `Dig.Auth.canDigLayer` says no: either an air gap, or `need_seam`, which fires `seamGate` (see [zones](zones-layers-and-seams.md)). No tool is equipped. `MineSpaceMatter.reject` refuses because a normal tool is in Event Horizon, or an event tool is outside it.
2. **Reach.** The distance must be ≤ `MineTools.reachOf(tool) × (1 + b.reach)`.
3. **Rate.** Each player has a 3-token bucket that refills at `max(rate / swingSec, autoMine) × 1.35`, which stops macros. Explosives use `cooldown / (1 + shortFuse)`. Drills wind up for `turn / (1 + coolant)`.
4. **Breaking gate.** `Dig.Breaking.canBreak(tool, zoneIndex, layer, OreTier attr, #C.ORES, p.maxUnlockedZone)`. If it returns false, the swing does **zero** damage, not reduced damage. The server also fires a `tooWeak` event {need, have, ore}, throttled to once per 1.2 s, which `ClientFns.tooWeak` shows in red.
5. **Damage.** `tool.power × b.mineSpeed × b.dirtBreak`, times `1 + shortFuse` on explosives. The fraction is rounded by chance, so small boosts still count on average. The minimum is 1.
6. **Cells hit.** `MinePatterns.resolve` decides which cells the tool touches. The pattern is a sphere of radius × (1 + blastRadius). Each extra cell goes through `swingNeighbour` at `dmg × factor`. The cell you aimed at always takes the full hit.
7. **Procs.** `Dig.procsAt` runs, then Echo.

**Breaking power** lives in `MineBreaking.luau`. It is pure arithmetic and requires no other module.
- **Rock.** `layerStrength = 1 + (zone−1)·ZONE_STEP + ⌊(layer−1)/LAYERS_PER_RUNG⌋`, clamped to `MAX`. The dials are `LAYERS_PER_RUNG 50`, `ZONE_STEP 100`, `ORE_POW 1.0`, `MAX_LAYER 5000` and `ZONES 10`, which give `MAX 1000`.
- **Ore.** `MineBreaking.oreStrength(t) = 1 + round(((t−1)/81)^ORE_POW × 999)`. Tier 1 → 1, tier 10 → 112, tier 82 → 1000.
- **The block.** `MineBreaking.blockStrength` takes the *harder* of the two numbers, never their sum. The ore number is computed as `oreStrength(tier − reach)`. `MineBreaking.reachFor` picks the reach: `ORE_REACH_HOME 5` in a zone you have not unlocked past, and `ORE_REACH 15` once `maxUnlockedZone > zone`. A nil progress value gets 15.
- **The tool.** `MineBreaking.toolBreakingPower` checks three things in order:
  - a stamped `breakingPower` or `bp` field wins;
  - otherwise `oreStrength(oreTier)`, but **only if the table has `oreId` or `ore`**;
  - otherwise the shop rung, `SHOP_POWER[rung or id]`, which runs 1 to 5.
- **"The zone is the gate."** Zone N's surface needs 1 + (N−1)·100. Each zone takes about 8 ore tiers: you enter zone 2 at tier 10, and zone 10's floor needs tier 82. The full table is in `docs/OPEN.md` P0 §3. I re-ran it against the module with luau.

**Procs.** All of them come from `Dig.procsAt` and `Dig.echoAt`, and every hit lands through `swingNeighbour`. `swingNeighbour` re-runs `canBreak` and silently drops any hit that fails it.

| proc | chance stat | fires on | damage (× `1 + procPower`, procPower capped at 3.0) |
|---|---|---|---|
| Blast | `blastChance`, clamped ≤ 1 | break | `PROC_SHARE.blast` 0.35 to each of the 6 faces |
| Ricochet | `ricochet`, clamped ≤ 1 | break | 0.60 to one neighbour, **then back** into the cell you aimed at |
| Earthquake | `earthquake`, clamped ≤ 1 | hit (not break) | A stack bank. Each tick is `QUAKE_STACK_SHARE 0.1 × stacks × stored dmg` per second. Stacks cap at 100. At most 5 blocks shake at once. The bank dies after 5 s with no new quake. |
| Zap | `zap`, **not clamped** | any swing | 0.25 per hop, up to `ZAP_MAX_HOPS 16`. The chance to continue is multiplied by `ZAP_FALLOFF 0.89` each hop. |
| Echo | only a tool with `special == "echo"` (the `echo` stat is folded into swing rate) | any swing | A full hit on a different neighbour. That neighbour rolls its own procs, but never its own echo. |

`Dig.PROC_SKIP` covers chests, crates, cores and lucky blocks:
- They never *start* Blast, Ricochet or Earthquake.
- Blast and Ricochet also never *land on* them.
- **Zap's target list does not check `PROC_SKIP`**, so a zap hop can hit one.

Proc damage is computed in `MineConfig.procDamage` and nowhere else.

**Pay while digging.** `payDamage` turns every point of HP landed into one dirt in the bag and one coin (× `coinBonus`). The coins are priced into `haulMix` at the moment you mine, and are paid out when you sell at an outpost. With a full bag the rock still breaks and the ore still drops; you just stop being paid. See [currencies](currencies-and-economy.md).

**How a block dies.** `finishBreak` runs these steps:
- **Depth credit.** It credits `p.deepest` through `MineDigAuth.creditDeepest`, which feeds the leaderboards, `MineDepthLive` and the plaza openings. A dig deeper than `serverDepth + 250` is *flagged* to Discord. The player is never ejected.
- **Bookkeeping.** It rolls the zone-band charm, gives +1 pass XP, adds to `stats.blocks`, bumps the charm ramp and generates the next slice of the mine (`ensureZone`).
- **Drops, by block kind.**
  - **Ore:** `MineConfig.oreYieldFor(tier)` units go into the pouch through `Dig.addOre`, and an ore case drops at `ORE_CASE_CHANCE 0.02 × oreLuck`.
  - **Chest or crate:** `openChestBlock`.
  - **Core:** the `geothermal_nuke` chest tool.
  - **Lucky block:** `LuckyBlocks.grant`.
  - **Dirt:** a lucky-block roll at `LUCKY_BLOCK_CHANCE 0.0002 × (1 + luckyFind)`, plus stardust from `pulverize`.
- **Removal.** The voxel is marked `VOXEL_SKIP` and the part is destroyed. `REGEN_SEC 0` means a broken block never grows back.

**Block HP** comes from `MineConfig.blockHp`, which calls `MineDepth.dirtHp = (20 + 1.5·layer) × 5^(zone−1)`. Chests, crates and lucky blocks get × `CHEST_HP_MULT 2`.

## Where it lives
| file | role | key symbols |
|---|---|---|
| `src/ServerScriptService/Mine/MineServer.server.luau` | the swing, the procs, block death | `swingBlock`, `swingNeighbour`, `Dig.procsAt`, `Dig.echoAt`, `Dig.startQuake`, `finishBreak`, `payDamage`, `equippedTool`, `throwAt`, `detonate` |
| `src/ReplicatedStorage/Mine/Shared/MineBreaking.luau` | the breaking-power gate | `MineBreaking.canBreak`, `MineBreaking.blockStrength`, `MineBreaking.toolBreakingPower`, `MineBreaking.reachFor` |
| `src/ReplicatedStorage/Mine/Shared/MineConfig.luau` | proc constants, reach as shown in the UI, block HP | `MineConfig.PROC_SHARE`, `MineConfig.procDamage`, `MineConfig.toolBreakingPower`, `MineConfig.oreReachCap`, `MineConfig.blockHp` |
| `src/ServerScriptService/Mine/MineDigAuth.luau` | depth entitlement, deepest credit | `MineDigAuth.canDigLayer`, `MineDigAuth.creditDeepest`, `MineDigAuth.serverDepth` |
| `src/ServerScriptService/Mine/MinePatterns.luau` | which cells a tool hits | `MinePatterns.resolve` |
| `src/ReplicatedStorage/Mine/Shared/MineSpaceMatter.luau` | Event Horizon tool class, damage chip | `MineSpaceMatter.reject`, `MineSpaceMatter.chip` |

Checks: `tools/verify/breaking.js`, `tools/verify/gate-coverage.js`, `tools/verify/procs.js`, `tools/verify/ladder-climbable.js`.

## Decided by the owner
- **Ore tier is breaking power.** Breaking power is not damage, block strength comes from layer and zone, and breaking power cannot be upgraded. Source: `docs/TODO.md` §0.13 rules 1–3 and 11.
- **Proc damage and proc chance are two stats.** Owner, 2026-10-03: *"Just make damage and chance 2 different stats."* Source: §0.16.
- **Reach has two values.** Owner, 2026-10-05: *"make the ore requirement elevated until they go to next zone"*. That gave home 5 and cleared 15. Home reach 0 would deadlock progress at tier 4, and `breaking.js` asserts that. Source: the banner in `docs/PROPOSAL.md`.
- **`ZONE_STEP` is 100, not 10.** Owner, 2026-10-05: *"get a new pick from next zone to come back to 501-1000 depth"*. Source: the comment above `MineBreaking.ZONE_STEP`.
- **Procs obey the gate.** The owner asked for "the full rule", ore included (`docs/OPEN.md` P0 §3).
- **Zap.** Zap above 100% is meaningful, and falloff affects only the odds, not the damage. The share was cut from 0.45 to 0.25. Source: the comments on `MineConfig.PROC_SHARE`, 2026-10-05.

## State right now
- Shipped in code, but **never run in engine** (`docs/START-HERE.md` §5).
- **Suspected blocker.** Found by reading the code and simulating `MineBreaking` with luau; not tested in engine.
  - **The gate cannot see breaking power.** For a forged ore tool, `equippedTool` returns `{id = "oretool_<uid>", power, level, …}`. That table has no `oreTier`, no `oreId` and no `bp`. A second branch below it does set `oreTier`, but that branch is unreachable and has no `oreId` either.
  - **So every tool gets breaking power 1.** `toolBreakingPower` falls through to `SHOP_POWER[1] = 1`, and shop-ladder and Event Horizon tools land in the same place.
  - **What breaks.** A tool at breaking power 1 is refused below zone 1 layer 50, and on any ore above tier 6. Event Horizon is zone index 11, so all of its rock needs 1000.
  - **No check catches it.** The `BreakPower` attribute that `givePickaxe` stamps is never read by the gate, and no verify check tests the shape of the tool table.

## Gotchas
- **Two scales are both called "breaking power".** The Forge UI (`MineForge`) shows `MineConfig.toolBreakingPower`, which is the ore tier (1–82). `tooWeak` shows strength (1–1000).
- **Reach is duplicated.** `ORE_REACH` and `ORE_REACH_HOME` exist in both `MineConfig` and `MineBreaking`. `breaking.js` fails if they drift apart.
- **Stale comments in `MineBreaking.luau`.**
  - "ZONE COSTS A RUNG … exactly 1".
  - "MAX is … 1100".
  - "the ORE_POW curve steepening".
  - All three describe the old `ZONE_STEP 1` / `ORE_POW 2.0` ladder. The `MineConfig.TOOL_BAND_DMG` comment still says "a scale that runs to 209".
- **Superseded proposal lines.** `docs/PROPOSAL.md` §0 line 13 and §F0 (ZONE_STEP 1, ORE_POW 2.0, MAX 209) are superseded by the re-cut of 2026-10-05.
- **Earthquake's real cap may be lower than stated.** `MineConfig` says the cap is "10x a swing per second". But `Dig.procsAt` passes in `procDamage(dmg, "quake")`, which is already × 0.12, so the real cap is ≈ 1.2 × (1 + procPower) swings per second. Which was intended is unverified.
- **Stale `MineStats` descriptions.** Zap says "up to 6 hops"; the real cap is 16. Earthquake says "Does not stack"; it does.
- **Snap-back no longer exists.** The `MineDigAuth` header promises it. In the code, `watchPlayer` ejects no one and `canDigLayer` ends by returning true.
- **A client/server round-trip has two names.** Grep for both `tooWeak` and `ClientFns.tooWeak`; see [luau-traps](../code/luau-traps.md).

## Open questions
- Is the tool-table gap real in engine? If it is, the fix belongs on the `equippedTool` def. Separate calls are needed on what breaking power shop-ladder tools get, and how Event Horizon tools pass the gate. See [open-questions](../open-questions.md).
- Was the earthquake cap meant to be 10× or 1.2× a swing?
- `docs/OPEN.md` P0 §3 is still open: "Document damage ≠ breaking power everywhere both appear."

## See also
[zones-layers-and-seams](zones-layers-and-seams.md) · [boosts-and-stats](boosts-and-stats.md) · [tools](tools.md) · [ores](ores.md) · [forge-and-recycling](forge-and-recycling.md) · [chests-and-lucky-blocks](chests-and-lucky-blocks.md) · [server](../code/server.md)
