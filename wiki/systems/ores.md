---
title: Ores
type: system
status: current
verified: 2026-10-05 @ b19c4c2
sources:
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ReplicatedStorage/Mine/Shared/MineBreaking.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ReplicatedStorage/Mine/Shared/MineZonePacks.luau
  - src/ReplicatedStorage/Mine/Shared/MineOreArt.luau
  - src/ReplicatedStorage/Mine/Shared/MineOreIcons.luau
  - src/ServerStorage/OreToolBaker.luau
  - tools/gen-ores.js
  - docs/TODO.md §0.13
  - docs/PROPOSAL.md §0
  - docs/OPEN.md P0 #3
related: [ore-pouch-and-backpack, tools, forge-and-recycling, skins-cases-and-temper, mining-and-breaking, zones-layers-and-seams, charms, save-data-and-migrations, tools-and-generators, assets-and-uploads]
---

# Ores

> 82 minerals, Stone (tier 1) to Oganesson (tier 82). Ore is the power currency:
> you mine it in veins, it lands in the [ore pouch](ore-pouch-and-backpack.md),
> and you forge and level tools from it ("a forged tool *is* its ore",
> [tools](tools.md)). It also sells for gems.

## How it works

- **Roster.** `MineConfig.ORES`, 82 rows: `id, name, tier, color, material, met,
  rough`, optional `glow`/`glowBright` (27 rows) and `rainbow` (4). Read
  `MineConfig.ORE_COUNT`, never a literal. The `ORE_BY_ID` block derives `d =
  (tier-1)*ORE_DMAX/81`, `packId = <id>_ore_pack`, `band`/`bandIndex`, and
  `homeHp = 20*6^d`. Lookup: `MineConfig.oreById`.
- **Bands** = `MineConfig.ORE_YIELD_BANDS` (also the ore-per-block table), read
  through `oreBandForTier`:

  | band | Common | Uncommon | Rare | Epic | Legendary | Mythic | Divine | Exotic |
  |---|---|---|---|---|---|---|---|---|
  | tiers | 1–18 | 19–29 | 30–49 | 50–60 | 61–69 | 70–75 | 76–79 | 80–82 |
  | ore/block | 8–10 | 10–12 | 11–13 | 12–15 | 8–10 | 6–8 | 4–6 | 2–4 |

- **Is it ore?** Flat `MineConfig.ORE_CHANCE = 1/200` per block, everywhere. The
  curve only picks *which* ore.
- **Which ore.** `MineConfig.oreWeights(zone, layer, rareOre)`: local hardness
  `oreDifficulty = log6(dirt blockHp / 20)`; per ore `x = d - hardness`; weight
  is a logistic cliff above hardness (`ORE_X0 -4.2`, `ORE_K 0.45`) times a decay
  below (`ORE_S 4`, `ORE_W 3`). It peaks ~21 tiers under local hardness.
  `ORE_MIN_SHARE = 1e-6` floors each ore's **share** of the final total (fixed
  point), so every ore is possible everywhere and odds never fall with depth.
- **Zone dependence is only through block HP.** No per-zone ore lists
  (`MineConfig.oresFor` returns all 82). `ORE_DMAX` = log6 of
  `Depth.dirtHp(10, LAYERS)` minus `ORE_DMAX_MARGIN 0.4`, so Oganesson sits just
  under zone 10's floor. Event Horizon is off the ladder (`ORE_LADDER_ZONES = 10`).
- **Ore finder** (`rareOre` stat): `MineConfig.oreFindShift` = `log6(rareOre)`
  raises the hardness the roll thinks it is at. Better ore, not more ore; it is
  not applied again at break.
- **Veins** (commit `219d0ab`; owner 2026-10-05: *"8 MAXIUM OF ALL ORES[2-3 ores
  TOTAL will group in 6-8s], but most will group in 3-4"*). `MineConfig.veinOreAt`
  is a pure function of `(zone, x, y, z, rareOre)`: 4×4×4 cells (`VEIN_CELL`),
  murmur3 hash per zone. `veinSizeFor`: tiers 1–3 in 6–8; the rarest 18%
  (`VEIN_SOLO_FRAC`, tiers 68–82) in 1–2; everything else 3–4. Max 8 by
  construction (`VEIN_ORDER` fills a 2×2×2). Expected ore per block is unchanged
  (size cancels), so bigger veins are rarer veins. Server `rollKind` and
  `spawnVoxel` both ask `veinOreAt`, so a vein is one ore and regen agrees.
  `rollOre`/`oreIdentity` stay for sims and harnesses.
- **An ore block** has dirt HP × `ORE_HP_MULT 3`, is stamped `OreId`/`OreName`/
  `OreTier`, and wears a name tag. Breaking it puts `oreYieldFor(tier)` (uniform
  lo..hi) **straight into the pouch** via `Dig.addOre` (no pack), pays coin haul
  per HP like any block, and rolls 2% × ore luck for an
  [ore case](skins-cases-and-temper.md).
- **Ore reach.** `MineBreaking.blockStrength` asks for the ore as if it sat
  `reach` tiers lower and takes the harder of that and layer strength.
  `MineBreaking.reachFor`: `ORE_REACH_HOME 5` in the zone you are working,
  `ORE_REACH 15` once `p.maxUnlockedZone` is past it. Mirrored in MineConfig
  (`canBreakOre`, `oreReachCap` — what the Forge quotes); `tools/verify/breaking.js`
  fails on drift and asserts home reach 0 deadlocks at tier 4. Full gate:
  [mining-and-breaking](mining-and-breaking.md).
- **Art.** A block is the zone rock (darkened SmoothPlastic) wearing one of 30
  hand-drawn faces: `MineConfig.ORE_FACE[id]` → `MineOreArt` tile, rebuilt
  client-side as an EditableImage — not an uploaded asset, so no group-ownership
  problem. Packed by `tools/pack-ore-art.js`, mapped by `tools/map-ores-to-tiles.js`.
  `MineOreIcons.BY_ID` holds 82 icons + 82 case images (164 uploaded assets,
  `tools/gen-ore-icons.js`) and **nothing reads it yet**. Tool look:
  `ToolModelFactory.oreLook`, `src/ServerStorage/OreToolBaker.luau`.

## Where it lives

| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineConfig.luau` | roster, bands, curve, veins, migrations | `ORES`, `oreWeights`, `veinOreAt`, `ORE_MIGRATION_V2`, `ORE_TIER_REMAP_V2` |
| `src/ReplicatedStorage/Mine/Shared/MineBreaking.luau` | live reach gate | `reachFor`, `oreStrength`, `blockStrength` |
| `src/ServerScriptService/Mine/MineServer.server.luau` | spawn, drop, roster migration | `rollKind`, `spawnVoxel`, `Dig.addOre`, `oreRosterV` blocks in `load` |
| `src/ReplicatedStorage/Mine/Shared/MineZonePacks.luau` | `<id>_ore_pack` + `<id>_ore_case` for all 82 | `PACKS`, `get` |
| `src/ReplicatedStorage/Mine/Shared/MineOreArt.luau` | 30 packed face tiles | `image`, `apply` |

## Decided by the owner

- 82 ores, final; Event Horizon ores may come later (TODO §0.13 rule 4).
- Ore tier = the tool's breaking power, with reach above it (§0.13 rule 1);
  reach later split into 5 at home / 15 once cleared (PROPOSAL banner, "Line 14 was
  also changed"). `roadmap/ORE.md`'s contrary argument is OVERRULED.
- Gems come from selling ore (§0.13 rule 7). Ore ids are load-bearing; ore is
  mined, never bought (TODO §9).
- Every rarity possible in every zone; veins (owner, 2026-10-05, quoted in
  MineConfig). `tools/verify/ladder-climbable.js` also cites *"never touch spawn
  chances"* as an owner rule — not found in TODO §0.

## State right now

Shipped on `claude/vigilant-fermi-aucqjy`: 82 roster, veins, share floor, reach
split, ore dropping straight into the pouch. **None of it has run in Roblox**
(START-HERE §5).

## Gotchas

- **Ore ids are save data**: `p.ores`, `p.oresSeen`, `p.oreLocks`,
  `<id>_ore_pack`, `<id>_ore_case`, `ORE_FACE`, `MineOreIcons`. Renames need a
  migration: `ORE_MIGRATION` (v1), `ORE_MIGRATION_V2` (121→82, 39 ids),
  `ORE_TIER_REMAP_V2` — because `p.oreTools[].tier` is an **index** into `ORES`,
  not an id. Stamp `p.oreRosterV`, `ORE_ROSTER_V = 2`.
- **Fixed in `b19c4c2`: the roster migrations used to re-run on every load.**
  The v1 and v2 guards were `~=`, so a profile stamped 2 re-entered v1, was
  re-stamped 1, then re-entered v2. Both are now `< version`. Whether saves
  already touched by the re-runs were repaired is not stated (unverified). See
  [save-data-and-migrations](../code/save-data-and-migrations.md).
- **`tools/gen-ores.js` is stale — never `--write`.** It parses 121 rows from
  `docs/ore-remake.md`. The `--force-stale` staleness guard described by
  `roadmap/README.md`, `roadmap/AGENT_PROMPT.md` and `roadmap/PROMPTS.md` is
  commit `9932508`, which is only on `origin/ore-tools-power`, not this branch.
  Here `--write` refuses only by accident (13 live ids unmapped). Dry run is safe.
- `docs/ore-remake.md`'s own banner is stale: it says MineConfig "has NOT caught
  up" and the OreToolBaker authority is "not committed". MineConfig is 82, and
  `src/ServerStorage/OreToolBaker.luau` is committed and matches `MineConfig.ORES`
  name-for-name and band-for-band (checked).
- TODO §6.1 "Ore drops ore" says yield comes from a roster `yield` field scaled by
  the `oreYield` boost — stale: it is `ORE_YIELD_BANDS`, and `oreYield` is now the
  blast-chance key. `roadmap/ORE.md` says `ore.d` comes from an authored `home` —
  not on this branch (linear in tier).
- `ServerStorage.OreShapes` (the ten plate patterns in `docs/decisions.md`) is
  place-file only, not in git, and nothing in `src/` reads it any more.
- `ORE_DMAX` was once anchored on the retired `Depth.SECTIONS` and deadlocked the
  forge ladder at tier 8 — treat old balance numbers in docs as suspect.

## Open questions

- Space ores (40, `docs/ore-remake.md`, unapplied): are they the "Event Horizon
  ores later"?
- `MineOreIcons`: where should icons show (pouch, Forge, case), and were the 164
  assets uploaded to the group? (unverified; [assets-and-uploads](../code/assets-and-uploads.md))
- OreShapes: export to `.rbxm` (OPEN P2) or delete?
- BLOCKED #4: does the Studio copy of `ToolBakers.OreToolBaker` match the repo
  copy? ([open-questions](../open-questions.md))

## See also

[forge-and-recycling](forge-and-recycling.md) · [zones-layers-and-seams](zones-layers-and-seams.md) ·
[charms](charms.md) · [tools-and-generators](../code/tools-and-generators.md)
