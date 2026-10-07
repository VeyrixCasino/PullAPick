---
title: Zones, layers and seams
type: system
status: current
verified: 2026-10-07 @ 41d8f3a
sources:
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ReplicatedStorage/Mine/Shared/MineDepth.luau
  - tools/verify/depthgate.js
  - tools/verify/chunkload.js
  - src/ReplicatedStorage/Mine/Shared/MineDepthShop.luau
  - src/ServerScriptService/Mine/MineDigAuth.luau
  - src/ServerScriptService/Mine/MineDepthPlazas.luau
  - src/ServerScriptService/Mine/WorldBuilder.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - docs/OPEN.md P0 §1, P1 §6, §7a
  - docs/TODO.md §0.29
  - docs/PROPOSAL.md §0 banner
related: [mining-and-breaking, currencies-and-economy, rebirth-and-skill-tree, ores, world-events, social-quests-and-leaderboards, server]
---

# Zones, layers and seams

> The world is ten mines, called **zones**, plus one limited event mine. You buy each zone with gems. You then dig straight down through **layers**. Every 500 layers there is a **seam**: five layers of air that you must open before you can dig past it, with an **underground outpost** standing at it (shop, sell desk, elevator). Depth is the progression axis, and breaking power is what actually limits it.

## How it works

**Zones** come from `MineConfig.ZONES`. Zone order is the array index, and `MineConfig.zoneIndex` returns 1 for an unknown id. The ids are save data.

| # | id | name | `buyCost` (gems) | `minRebirth` |
|---|---|---|---|---|
| 1 | meadow | Dirt Meadow | 0 | 0 |
| 2 | sunscar | Greyvein Quarry | 7,500 | 0 |
| 3 | mistreef | Mistreef Depths | 11,500 | 1 |
| 4 | arcwork | Arcwork Veins | 27,500 | 2 |
| 5 | bloodmoon | Bloodmoon Hollow | 55,000 | 3 |
| 6 | eclipse | Eclipse Core | 105,000 | 4 |
| 7 | riftmarch | Riftmarch Scarps | 170,000 | 5 |
| 8 | starfall | Starfall Barrens | 360,000 | 6 |
| 9 | mythral | Mythral Catacombs | 520,000 | 7 |
| 10 | primordium | Primordium Heart | 880,000 | 8 |
| 11 | bigbang | Event Horizon | free claim while live (`limited = true`) | 0 |

- **Buying a zone.** `buyZone` sells zones in order only (index = `maxUnlockedZone + 1`). It requires `p.prestige ≥ minRebirth` and enough gems, then sets `p.maxUnlockedZone`. A rebirth keeps `maxUnlockedZone` and does not gift the next zone ([rebirth](rebirth-and-skill-tree.md)). Each row also carries a `prestige` field with the same value as `minRebirth`.
- **Event Horizon** is claimed through `p.bigbangOwned`. It uses event tools and pays `spaceCoins`. `MineConfig.blockHp` treats it as zone 11, one step past Primordium. See [world-events](world-events.md).
- **Two gates on every zone:** you must own it (`Gate.zoneUnlocked`), and your tool must pass the breaking gate. Zone N's surface needs strength 1 + (N−1)·100 ([mining](mining-and-breaking.md)).

**Layers and sections.**
- **Layer size.** A layer is `GRID 21` × 21 = 441 blocks, each `BLOCK 5` studs.
- **Generation.** Layers are generated on demand by `ensureZone`, `LAYER_WINDOW 8` below the deepest point reached, `Const.ENSURE_BAND 3` layers at a time.
- **Generation stops at the open chunk** (2026-10-07). `ensureZone` clamps its
  target to `MineDigAuth.chunkCeiling(MineDigAuth.deepestReachedAcross(profiles, zone))`.
  A chunk is `MineConfig.DIG_CHUNK_LAYERS 50`; the open one holds the frontier, so
  generation may fill it to its floor and no further, and reaching that floor opens
  the next. Clamped **in `ensureZone`, not at the five call sites**, because that is
  the only place a request becomes rock. `reached` counts a depth pass, so elevators
  and plazas still land on rock rather than in a void.
- **The far path must not claim the frontier.** `ensureZone` has two modes: digging
  down extends contiguously, while arriving deep (`Const.ENSURE_FAR 64`) builds one
  detached band at the target. The latter used to run `builtTo = max(builtTo, target)`
  unconditionally, so riding to seam 2500 with 3 layers built claimed 2508 and left
  layers 4–2505 ungeneratable by anything — ride back up and you stood in a void no
  amount of digging filled. Only the near path advances `builtTo` now.
- **The floor is 5000** (`MineConfig.LAYERS`; the second assignment wins). **But Dirt Meadow is uncapped:** in `ensureZone`, `uncapped = zone.id == "meadow"`, and `MineConfig.zoneLayers` gives meadow `MINE1_LAYERS 10000`.
- **Block HP is a straight line.** `MineDepth.dirtHp = (HP_BASE 20 + HP_PER_LAYER 1.5 · layer) × ZONE_HP_MULT 5^(zone−1)`. Since 2026-09-29 it no longer comes from the section table.
- **`MineDepth.SECTIONS`** has 138 named rows, from Loam (layers 1–40) to Terminus (9961–10040). They now carry names, signs and colours only. Their own `dirtHp` column is dead.
- **Bands.** `MineDepth.bandForLayer` gives ≤500 `shallow`, ≤1500 `mid`, deeper `deep`. Players see these as Surface, Deeprock and Shadowzone (`MineDepth.BAND_LABEL`).

**Seams.**
- **Where they are.** `MineDepth.SEAMS` = every 500 from 500 to 5000, then every 1000 to 10000. Each seam ends `AIR_GAP 5` layers of air (for example 496–500).
- **Which seam gates a layer.** `MineDepth.gateForLayer` returns the deepest seam whose depth is ≤ the layer.
- **Ownership.** Owning a seam means `p.seams["<zoneIndex>:<seam>"] = true`.
- **The round-trip.** Grep both names; see `docs/OPEN.md` P0 §1.
  1. `MineDigAuth.canDigLayer` → `need_seam`.
  2. `swingBlock` fires `seamGate` {seam, price, minutes, coins}, throttled to once per 1.5 s.
  3. `ClientFns.confirmSeam` opens the "Break the seam" panel.
  4. The panel fires `buySeam`.
  5. `Verbs.buySeam` checks that the seam exists and is not owned, and that **every shallower seam is open (order is enforced)**. Then it calls `MineDepth.grantSeam`.
- **Seams are free.** `MineDepth.seamPrice` returns **0** (owner, 2026-10-05: *"buy seams shouldnt cost anything"*). `SEAM_MINUTES 30` and `gateCoinValue` remain, but no price uses them.
- **Grandfathering.** `MineDepth.grantReachedSeams` re-grants every seam whose depth is ≤ `p.deepest` on load.
- **Rebirth wipes `seams` and `deepest`.** Both come back from `blank()`, so seams must be re-opened. They are free.
- **Depth is not rebirth-gated.** `MineDepth.rebirthForSeam` and `MineDepth.rebirthForLayer` return 0. The `need_rebirth` and `REBIRTH_PER_ZONE_B` paths are effectively dead.

**Depth credit is gated separately from digging** (2026-10-07, owner: the chunk
gate is *"to ensure hackers dont break one block in every chunk and unlock the
depth points"*).

- **`MineDigAuth.canDigLayer` ends in an unconditional `return true`.** Every
  entitlement check above it is therefore unreachable, and that is deliberate for
  *mining*: refusing a swing only leaves someone standing in rock that will not
  break, which stops no exploit. It was **not** deliberate for *crediting* — one
  block broken at layer 5000 credited depth 5000 to anyone who could reach it.
- **`MineDigAuth.canCreditDepth(p, zoneId, layer)`** is the strict half, and
  `MineServer` calls it alongside `canDigLayer` on the branch that awards
  `p.deepest`. Two rules:
  - **STEP** — a credit advances depth by at most `MineDepth.DIG_LEAD` past what
    you reached (`too_deep`).
  - **CHUNK** — layer L is in chunk `ceil(L / DIG_CHUNK_LAYERS)`, and nothing in a
    chunk credits until the floor above is reached (`chunk_locked`).
- **Why both.** The step rule alone permits the patient version indefinitely:
  measured, hopping `DIG_LEAD` at a time bought **8 layers of depth per block
  broken, forever**. With the chunk rule, 6 blocks buy 48 layers and then dead-end
  until layer 50 is genuinely mined.
- `reached = max(deepest, depthPass)`, so elevator and plaza passes still credit
  where they put you. Pinned both directions by `tools/verify/depthgate.js` — the
  cheat must fail *and* digging layer-by-layer to 600 must never be refused.

**Underground outposts (depth plazas).** `MineDepthPlazas` builds one per seam, per zone, under `workspace.MineWorld.Pits.DepthPlaza_<zone>_<seam>`:
- **The building.** `dressOutpostFromSurface` clones the surface outpost (`SurfaceClone`, with shop and sell). `wallOutpost` adds a reserved `StationBay`. `depthLook(seam)` darkens and warms deeper outposts.
- **When it opens.** `MineDepthPlazas.tryOpenSeam` runs when you dig within the air gap (`MineDepthPlazas.onDepthCredit`).
- **The elevator.** The mineshaft elevator (`MineDepthPlazas.ride`) needs `deepest ≥ seam`.
- **Desk keys.** `MineDepth.bandUnlockKey` names the desk: `deeprock` 500, `thousand` 1000, `shadowzone` 1500, `twothou` 2000, `outpost_<n>` from 2500. `MineDepthShop.DESK_SEAM` maps them back.
- **Depth desks.** A depth desk sells the haul × `MineDepth.depthSellMult` (`MineDepthShop.sellPayout`) and stocks the depth tool catalogue (`MineDepthShop.catalog`). It is gated by `MineDigAuth.clampDesk` and `MineDigAuth.canAccessSeam`, which use your earned depth, never your Y position.

**World and portals.**
- **The world is rebuilt at boot.** `WorldBuilder.build()` runs when the server starts. It destroys and rebuilds `workspace.MineWorld`: lobby, `Camp`, biome plates, surface outposts, `Pits`, portals. It also clears Terrain.
- **Portals.** Each zone gets a next-zone portal (`Portal_<nextId>`) on the far rim of the pit. Islands that are not within walking distance also get a `Lobby` return portal. Only Dirt Meadow is close enough (`WALK_TO_MAX 800`) to get a road instead.
- **Entering an unowned portal** attempts `buyZone`.

**The mine map tool.** `tools/gen-mine-map.js` writes `tools/mine-map.html` from `build/depth-sheet.json` (generated, untracked, made by `tools/depth-sheet-data.js`). It parses the `MineBreaking` dials. `tools/verify/minemap-runs.js` executes the page. In game, the zone list is the swipeable `MineZoneMapView`.

## Where it lives
| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineConfig.luau` | zone roster, floor, block HP | `MineConfig.ZONES`, `MineConfig.LAYERS`, `MineConfig.zoneLayers`, `MineConfig.blockHp` |
| `src/ReplicatedStorage/Mine/Shared/MineDepth.luau` | HP curve, sections, bands, seams | `MineDepth.SEAMS`, `MineDepth.dirtHp`, `MineDepth.seamPrice`, `MineDepth.gateForLayer`, `MineDepth.depthSellMult` |
| `src/ServerScriptService/Mine/MineDigAuth.luau` | depth entitlement | `MineDigAuth.canDigLayer`, `MineDigAuth.canAccessSeam`, `MineDigAuth.clampDesk` |
| `src/ServerScriptService/Mine/MineDepthPlazas.luau` | outposts, elevators | `MineDepthPlazas.tryOpenSeam`, `MineDepthPlazas.ride` |
| `src/ReplicatedStorage/Mine/Shared/MineDepthShop.luau` | depth desks | `MineDepthShop.sellPayout`, `MineDepthShop.catalog` |
| `src/ServerScriptService/Mine/WorldBuilder.luau` | surface world, portals | `WorldBuilder.build`, `WorldBuilder.buildOutpost` |
| `src/ServerScriptService/Mine/MineServer.server.luau` | verbs | `buyZone`, `enterZone`, `Gate.zoneUnlocked`, `Verbs.buySeam`, `ensureZone` |

## Decided by the owner
- **Seams are underground outposts.** They are 1:1 with the surface one, themed, and deeper and darker each time (`docs/TODO.md` §0.29).
- **Outposts every 500, all the way down** (owner, 2026-10-05). There is a reserved station bay behind each one (`docs/OPEN.md` P1 §6).
- **Seams cost nothing** (2026-10-05). This supersedes PROPOSAL §0 line 24 and the seam half of §H1.
- **Zones and the ore pouch are gem sinks**, per `docs/TODO.md` §0.13 rule 7.
- **The zone is the breaking gate** (`ZONE_STEP 100`); see [mining](mining-and-breaking.md).

## State right now
- The seam chain is wired, free and still **unconfirmed in engine** (`docs/OPEN.md` P0 §1).
- Ten outposts per zone are wired, and the station bay content is undecided.

## Gotchas
- **Huge depth-desk payouts (found by reading the code).** `MineDepth.equivZoneIndex` treats seam 500 as "zone + 4" and seam 1500 as "zone + 6". So `depthSellMult` pays **×487.5** (5⁴ × 0.78) at the seam-500 desk and **×12,187.5** at the seam-1500 desk. Every other seam pays ×0.78, which is *worse* than the surface's ×1. The `MineServer` comment saying "depth desks stay strictly better" is only true for 500 and 1500. The equivalence dates from the old geometric HP curve. See [currencies](currencies-and-economy.md).
- **Seams below 5000 are only reachable in Dirt Meadow** (seams 6000–10000 sit under the 5000 floor elsewhere). The meadow pit generates without a floor. `MineBreaking.MAX_LAYER 5000` calls 5000 "the live floor", and in meadow that is not true.
- **The world is code-built, not place-only.** `AGENTS.md` and START-HERE §3 say Workspace lives only in the place file. But `WorldBuilder.build()` rebuilds `MineWorld` at boot, so the lobby, outposts and portals come from code. `docs/OPEN.md` §6 describes plaza folders found in the place file; at runtime `MineDepthPlazas` builds its own.
- **Stale descriptions.**
  - The `MineDepth` header says `6^(zoneIndex-1)`, but the code uses 5.
  - `docs/depth-sheet.md` still describes the old step function (SECTIONS × 6^z × 2, ceiled).
  - `docs/START-HERE.md` §2 step 6 still calls layer 500 the ship blocker; §5 of the same file corrects it.
- **Band boundaries disagree.** `SECTIONS[].band` and `bandForLayer` disagree at the edges: Blackearth (481–520) is tagged `mid`.

## Open questions
- What goes in the station bay (`docs/OPEN.md` P1 §6)?
- Is the depth-desk multiplier intended? It is a coin faucet worth hundreds of times the dig price.
- Should Event Horizon stay at `minRebirth` 0 (`docs/OPEN.md` P2)? Should the meadow floor be 5000?

## See also
[mining-and-breaking](mining-and-breaking.md) · [currencies-and-economy](currencies-and-economy.md) · [rebirth-and-skill-tree](rebirth-and-skill-tree.md) · [world-events](world-events.md) · [social-quests-and-leaderboards](social-quests-and-leaderboards.md) · [rojo-and-studio](../code/rojo-and-studio.md)
