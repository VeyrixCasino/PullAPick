---
title: World events
type: system
status: current
verified: 2026-10-10 @ 31ecb3d
sources:
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ServerScriptService/Mine/MineEventHorizon.luau
  - src/ReplicatedStorage/Mine/Shared/MineHorizonTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineSpaceMatter.luau
  - src/ReplicatedStorage/Mine/Shared/MineEventPass.luau
  - src/ReplicatedStorage/Mine/Shared/MineEHPets.luau
  - src/ReplicatedStorage/Mine/Shared/MineEventsView/init.luau
  - src/ReplicatedStorage/Mine/Shared/MineWorldEvents.luau
  - src/ReplicatedStorage/Mine/Shared/MineWorldPulseUI.luau
  - src/ServerScriptService/Mine/MineBloodLake.luau
  - src/ServerScriptService/Mine/MineHarbor.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - docs/OPEN.md P0 §3, P2
  - docs/PROPOSAL.md §0 line 32
  - docs/AUDIT.md §5
related: [zones-layers-and-seams, cards-and-packs, boosts-and-stats, shops-and-monetisation, social-quests-and-leaderboards]
---

# World events

> "Event" covers three different things in this repo:
> - **Event Horizon**, a limited-time mine (zone 11, id `bigbang`);
> - the **Event Pass**, its own small progression track;
> - **World Pulse**, random server-wide buffs. These are switched off.
>
> Blood Lake and Harbor are **not** events. They are zone theme builders (bottom
> of this page).

`MineServer` below means `src/ServerScriptService/Mine/MineServer.server.luau`.

## How it works

### Event Horizon (`bigbang`, zone index 11)
- **The zone.** It is the last row of `MineConfig.ZONES`, with `limited = true`,
  `chestMult = 3`, and sets `genesis_spark`, `first_light` and `proto_ore`. The
  Events tab lists it in `MineConfig.EVENTS[1]`, id `event_horizon`.
- **The window.** It opens at `MineConfig.LIMITED_START_UNIX` 1790049600
  (2026-09-22 00:00 ET) and lasts `LIMITED_DAYS` 47 days. That ends it on
  **2026-11-08 04:00 UTC** (computed). `MineConfig.limitedActive()` reports
  whether it is open.
- **Claiming it.** Claiming is free and sets `p.bigbangOwned`.
  `Gate.zoneUnlocked` checks ownership, not the window, so a player who claimed
  it keeps the mine after it closes. On load they also get the Wormhole Bag and
  the starter `eh_shallow_pick`.
- **Rock and tools.** The rock is **SpaceHP** (`MineSpaceMatter`): meadow tools
  cannot spend it, and event tools cannot spend normal HP. The tools come from
  `MineHorizonTools`, one per family per dirt section. They are priced in **space
  coins** (`p.spaceCoins`), bought through `MineShopBuy.buyEvent`, and gated by
  `p.deepest.bigbang`.
- **Packs and pets.** Packs found here mint only Event Horizon sets (`openPack`).
  The limited pets are Matter+, Matter−, Cosmo and Albert Minestein (the
  `MineConfig.EVENTS` blurb, `MineEHPets`).
- **The world.** `MineEventHorizon` builds a research station with a black hole.
  The hole collapses every `MineConfig.MINE_RESET_SEC` (20 min), on the same
  beat the mines reset, and `MineAmbience` plays the blast on clients.
- **Off the breaking ladder.** Event Horizon does not use ore tools (OPEN P0 §3).

### Candy Crypt (`hallow`, zone index 12) — Halloween 2026

> **Partly built (2026-10-10).** The zone, its window, its claim, the tiny pit,
> no chests, the candy balance and its strata exist. The candy ores, the
> 10-layer sections and 3× curve, sell values, the Trick-or-Treat cases and the
> Halloween tools do not.

A second limited mine, open **alongside** Event Horizon rather than after it.
Owner's brief: candy ores dropping candy corn, **no chests**, nothing sells for
much (more the deeper you go), **no hardness gate** so surface tools work, **ten
layers to a section and about ten blocks to a layer**, 3× per section, and candy
buys Trick-or-Treat cases, seasonal packs, skin and hat cases, and the Halloween
bucket. Halloween tools are buyable with candy and must be sold with an explicit
warning that they are very weak and only for seasonal events.

Adding it forced three things that assumed exactly one limited zone:

| was | now |
| --- | --- |
| `limitedActive()` took no argument | `limitedActive(zoneId)`, windows in `MineConfig.LIMITED_WINDOWS`. No argument still means `bigbang`. |
| `Gate.zoneUnlocked` / `enterZone` read `p.bigbangOwned` for any limited zone | each zone names its own `ownedFlag` (`hallowOwned` here) |
| `rollKind` named `bigbang` for chest density | reads `zone.chestMult`, so Halloween can set **0** |

- **Windows are day offsets from SEASON START, not real dates.** The clock is
  `MineLaunch.seasonNow()`, and a wall-clock window is the exact failure
  MineLaunch exists to prevent — it would count down before the game opened.
  `hallow = { startDay = 25, days = 21 }` gives the owner's **17 Oct – 7 Nov**
  if the season starts 2026-09-22 as configured, and slips with launch if not.
  Verified in Studio.
- **Blocks per layer is per zone** (`MineConfig.gridFor`). A layer is square, so
  no grid gives exactly 10: `grid = 3` gives 9 and keeps a true centre block,
  which the elevator and pit centre are computed from. Applied at the three
  places that decide what a layer *is* — generation, and `MineDigAuth`'s cell
  lookup and pit bounds. Zones omitting `grid` read 21 and are unchanged.
- **`sets` is meadow's, not candy.** It is read as `MineCards` set ids, and
  `candy_corn` / `gummy_vein` / `sugar_glass` are **not registered** there —
  using them hands broken set ids to every pack the zone can produce. Limited
  zones already draw pets from the meadow pot. It becomes the Halloween 2026
  set once that pack exists, which under the holiday rule is the only legal
  source of holiday pets anyway.
- **There is no "hardness gate" to switch off.** The gate is block HP, not a
  flag. `zone.noStrengthGate` is set on the row but **nothing reads it yet** —
  making surface tools viable means giving the zone a low HP curve, which is
  part of the unbuilt work.

### Event Pass
- **What it is.** `MineEventPass.TRACKS.event_horizon` has 6 tiers. Event XP
  (0 → 360) comes from 10 event quests: blocks, sells, depth and packs.
- **What it pays.** Only boosts, never currency or packs. At the top tier it
  gives luck ×1.25, sell ×1.18, gems ×1.15, and "ore" ×1.12, which is folded in as
  +0.12 `blastChance`.
- **When it applies.** In `boosts()`, only while you stand in `bigbang` and
  `limitedActive()` is true.
- **A kept id.** Quest id `eh_fossils` survives, but it is now a depth quest. The
  id stays because progress is keyed by id.

### Events tab
`MineEventsView` (mounted as `eventsCtl` in the client) shows the live limited
event: a banner image, a countdown from `MineConfig.limitedCountdown`, and
the pass.

### World Pulse — disabled
- **The design.** `MineWorldEvents.EVENTS` lists 8 short buffs: Lucky Breeze,
  Pocket Change, Gem Glow, Fortune 150, Double Sell, Gem Tide, High Roller, Rich
  Haul. Tiers 1–4 are gated by zone, rebirth or best gear grade (`canAccess`).
- **The switch.** `startLoop` is a **no-op**: it sets `_nextAt = math.huge`, so
  nothing ever fires. `chestSpawnMult` returns 1.
- **What still loads.** The banner in `MineWorldPulseUI` is still installed, and
  `foldBoosts` still runs; both simply find no event.

### Not events: Blood Lake and Harbor
These two modules build zone outposts. Each builds `Outpost_<zone>` with
`MineShopFronts`, and `WorldBuilder` places the stand and portals.
- **`MineBloodLake`** is Bloodmoon Hollow: an island in a lake of blood. Each
  client sees red water through `MineAmbience`.
- **`MineHarbor`** is Mistreef Depths, built as a harbour wharf.

See [zones-layers-and-seams](zones-layers-and-seams.md).

## Where it lives
| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineConfig.luau` | event zone row, window, catalog | `ZONES`, `EVENTS`, `LIMITED_START_UNIX`, `LIMITED_DAYS`, `limitedActive`, `MINE_RESET_SEC` |
| `src/ServerScriptService/Mine/MineEventHorizon.luau` | station and black-hole build | `HOLE_AT`, `outpost`, `setLowGravity` |
| `src/ReplicatedStorage/Mine/Shared/MineHorizonTools.luau` | event tool shop | `TOOLS`, `ZONE_INDEX`, `byId` |
| `src/ReplicatedStorage/Mine/Shared/MineSpaceMatter.luau` | which HP pool a tool may spend | `classOf` |
| `src/ReplicatedStorage/Mine/Shared/MineEventPass.luau` | pass tiers and quests | `TRACKS`, `ensure`, `activeBonus`, `tick` |
| `src/ReplicatedStorage/Mine/Shared/MineWorldEvents.luau`, `src/ReplicatedStorage/Mine/Shared/MineWorldPulseUI.luau` | World Pulse, inert | `EVENTS`, `startLoop`, `foldBoosts` |
| MineServer | gates, boost fold, sets | `Gate.zoneUnlocked`, `boosts`, `openPack` |

## Decided by the owner
- **PROPOSAL §0 line 32** puts prestige, VIP and the event pass in **neither**
  boost layer: *"(multiply the final)"*. See [boosts-and-stats](boosts-and-stats.md).
- **The roster stays at 82.** TODO §0.13 rule 4: *"Event Horizon ores may be added later."*
- **Fossils are gone** (§0.12). The Event Pass's fossil quest was repointed to depth.

## State right now
- **Event Horizon is live by the clock today** (2026-10-05), going by the window
  above.
- **The event code is inherited.** It is unchanged since the import (`566eecf`),
  apart from fossil removal.
- **World Pulse is off.** It was switched off before this branch.
- **On the ARCHIVE list.** AUDIT §5 lists "Event pass / limited events (~900)"
  for archiving. That is a proposal, and no archive has happened.

## Gotchas
- **A stale comment.** MineServer still says *"World Pulse loop: idle 15m →
  random event 1–5m → repeat"* above `startLoop`, but the loop does nothing.
- **Three different clocks.** The limited window, the rotating-offer season and
  the group wheel are separate. Offers end 2026-11-01
  (`MineRotatingOffers.SEASON_END`), but `LIMITED_DAYS` runs to 11-08. The
  comment on `LIMITED_DAYS` says offers were "extended by a week", but
  `SEASON_END` still reads 11-01.
- **A rebirth mismatch.** Event Horizon's `minRebirth` is 0 while its surface
  rock is 1.30e9 HP (OPEN P2, `docs/live-config.md`).
- **A possible stray module.** OPEN P2 asks to delete a duplicate Event Horizon
  pet module of 34 KB. Only `MineEHPets` exists in `src/`. `MinePetRoster` also
  looks for `MineEventHorizonPets`, so the duplicate may live only in the place
  file. Unverified.

## Open questions
- Archive the event pass and limited events, or keep them for launch (AUDIT §5)?
- What happens to Event Horizon after 2026-11-08? Is a new event planned? Nothing in the repo says.
- Should World Pulse be deleted, or revived?

## See also
[zones-layers-and-seams](zones-layers-and-seams.md) · [cards-and-packs](cards-and-packs.md) · [shops-and-monetisation](shops-and-monetisation.md) · [social-quests-and-leaderboards](social-quests-and-leaderboards.md) · [pets](pets.md)
