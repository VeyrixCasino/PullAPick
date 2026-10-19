---
title: World events
type: system
status: current
verified: 2026-10-19 @ 2efdf89
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
  - src/ReplicatedStorage/Mine/Shared/MineCandyTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineTrickOrTreat.luau
  - src/ReplicatedStorage/Mine/Shared/MineCryptRules.luau
  - src/ServerScriptService/Mine/MineCrypt.luau
  - tools/verify/crypt.js
  - wiki/open-questions.md §0e
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

> **Built 2026-10-10, redesigned 2026-10-19** to the owner's build spec
> ([open-questions §0e](../open-questions.md), "The Candy Crypt, redesigned").
> The server and shared-data half is in; the client screens are the next job.
> Nothing here has run in Studio yet. Every number the owner did not give is
> PROPOSED in the code.

**The rules, as built** (`MineCryptRules` holds them for both sides; the server
module `MineCrypt` grants and gates; `MineCandyTools` is the tool table):

- **Only event tools dig it.** The zone row carries `eventToolsOnly`.
  `equippedTool` hands the player their Crypt tool there (`MineCryptRules.heldRow`),
  and `MineSpaceMatter` refuses any other tool on Crypt rock, on both damage paths
  ("Only event tools work here."). A Crypt tool's event row spends no other rock.
  Event Horizon is untouched.
- **Claiming** (the Events tab's `buyZone`, or the free claim on entry) checks the
  Crypt's own window and sets `hallowOwned`. `buyZone` used to read Event
  Horizon's window and grant Event Horizon (launch audit M2). A claim gives the
  starter `candy_corn_pickaxe`; a claimed save with no tool gets it back on load.
- **Crypt tools.** 12 rows, 3 tiers (Candy Corn, Toffee, Jawbreaker; bands of 40
  layers) x 4 families. Each borrows its family's forged frame and
  `MineOreTools.FAMILY_POWER`, and is tuned to take `PICK_HITS` 12 pick hits at
  layer 31, 71 or 111. No row has a price: the candy shop is gone.
- **Where they come from.** Crypt chests (`chestMult` 3, about ten in the Crypt)
  pay candy (5 candy blocks' worth) and a tool 30% of the time (x chest luck,
  capped x3), from the chest's own band, a tier better 15% of the time. And the
  Trick-or-Treat case (below).
- **Save:** `p.cryptTools` (`"<id>|<variant>"` -> copies), `p.cryptToolEquipped`,
  `p.cryptToolWorld`, `p.eventNoticeSeen`, `p.candySeen`.
- **Merging** (`cryptMerge`): 3 x (tool, variant) -> 1 x the next variant,
  Golden -> Prism -> Rainbow, at `MineConfig.VARIANT_MULT` (2.25 / 3.5 / 5.5).
- **After the event** the tools stay. They always work in the Crypt; in the main
  world only once the window has ended and the player chose it
  (`cryptEquip { world = true }`), as a level-1 forged tool of the row's
  `worldOreTier` (ore 8, 24 or 41) times its variant, with that ore's breaking
  power; and in a later event mine (one with `eventToolsOnly`) once the Crypt has
  ended. During the event they do nothing outside the Crypt.
- **Rock:** `MineConfig.cryptRockHp`, zone 3's surface (538) at the top to zone
  10's (41,992,188) at layer 120, smooth per layer, still hardening below. It
  still **sells for little**: coins keep the old curve (`cryptSellHp`, x3 per 10
  layers from 1), through `cryptHaulRatio` in `payDamage`; the normal-ore mix
  keeps the old curve too (`oreDifficulty`). No strength gate (`noStrengthGate`,
  read by both damage paths): HP is the gate.
- **Candy is 3x** (`CANDY_RATE_MULT`). A candy block pays candy **and one candy
  ore** into the pouch (`MineCrypt.onBlockBroken`), whatever kind of block it is.
  The old payout sat in the ore branch, so almost no candy block paid.
- **Sixteen candy ores** in value order (Cotton Candy, Pop Rocks, Milk and White
  Chocolate are new), evenly spaced, two per pouch band. They take pouch room,
  never sell for gems, and sell for candy (`cryptSellCandyOres`, at
  `candyOreValue`: half a block at the ore's home depth).
- **Six Halloween charms** are crafted from candy ores (`cryptCraftCharm`); see
  [charms](charms.md).
- **First entry** pushes `eventNotice` until `cryptNoticeSeen` marks it.
- **The Crypt is remade** on the 20-minute mine-reset beat while it is open, so
  there is always a top for the starter pick.

**The Trick-or-Treat case** (`MineTrickOrTreat`, 2,500 candy, bought and opened
in one action, only while the Crypt is open and claimed):

| outcome | rate | what it is |
|---|---|---|
| Crypt tool | 85% | tier 1/2/3 at 60/30/10, any family, Normal |
| skin case | 5% | an ore case in the bag (`<ore>_ore_case`, ore tier 10-40) |
| hat | 7% | `Gear.rollPiece(id, rng, "head")` -> `p.gear` |
| Halloween 2026 Pack | 2.9% | a real bag row with `packId` (it was `{ setId }`, which openPack cannot resolve); folds into hats if the pack is missing |
| **Trick-or-Treat Bucket** | **0.1%** | a bag (`candyMult = 2`), never demotes a bigger one |

No candy back (owner, 2026-10-19). `MineCryptRules.caseOdds()` is the odds sheet.

**Three profile fields do not exist, and each compiles fine if you guess:**
- `p.hats[id]` — a hat is a **gear piece** appended to `p.gear` (an array).
- `p.tempers` is a **map keyed by `kit.id`** holding `{ rarity, n }`, not a list.
- `p.bagsOwned` — `backpackTier` is an **index** into `C.BACKPACKS`; limited
  bags are owned through a dedicated flag, like `p.wormholeBag` and `p.trickBucket`.

**Built 2026-10-10, still true:**
- **Halloween runs on real calendar dates** (owner, 2026-10-10: *"if the game
  isn't live by then, it doesn't happen"*): `LIMITED_WINDOWS.hallow` is
  2026-10-17 00:00 to 2026-11-08 00:00 US Eastern on `os.time()`, while Event
  Horizon keeps day offsets on `MineLaunch.seasonNow()`. `limitedActive(zoneId)`
  takes the zone; no argument still means `bigbang`.
- **Each limited zone names its own `ownedFlag`** (`hallowOwned` here), read by
  `Gate.zoneUnlocked`, `enterZone`, `buyZone`, Planets Travel and the portals
  (the snapshot's `limitedOpen` carries every limited zone's own window).
- **Blocks per layer is per zone** (`MineConfig.gridFor`): `grid = 3`, nine
  blocks a layer with a true centre block.
- **`sets` is meadow's, not candy**, because they are `MineCards` set ids; the
  Halloween pets come only from the Halloween 2026 Pack.
- **Candy ores are not in `MineConfig.ORES`** (`CANDY_ORES`), because `ORES` has no
  per-zone filter. The mix walks with depth and is chosen from the cell position.

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
| `src/ReplicatedStorage/Mine/Shared/MineSpaceMatter.luau` | which HP pool a tool may spend; the event-only rule | `classOf`, `reject`, `chip`, `TOAST` |
| `src/ReplicatedStorage/Mine/Shared/MineCryptRules.luau` | the Candy Crypt's rules, shared | `heldRow`, `window`, `mergePlan`, `worldPower`, `caseOdds`, `charmRecipes`, `stateFor`, `NOTICE` |
| `src/ServerScriptService/Mine/MineCrypt.luau` | Crypt grants, verbs, hooks | `dispatch`, `heldTool`, `onClaim`, `onBlockBroken`, `openChest`, `buyTrickOrTreat`, `haulPoints` |
| `src/ReplicatedStorage/Mine/Shared/MineCandyTools.luau`, `src/ReplicatedStorage/Mine/Shared/MineTrickOrTreat.luau` | Crypt tool table; the case | `TOOLS`, `rollChestTool`, `rollCaseTool`; `WEIGHTS`, `roll`, `odds` |
| `tools/verify/crypt.js` | runs the real modules: gating, drops, merge, keep-after-event | |
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
- **The Candy Crypt redesign is half built (2026-10-19).** The server and shared
  data are in and pinned by `tools/verify/crypt.js`; the client screens (Crypt
  tool inventory, merge, candy sell, charm crafting, the pop-up, Sell up to) are
  not, and nothing has run in Studio.
- **On the ARCHIVE list.** AUDIT §5 lists "Event pass / limited events (~900)"
  for archiving. That is a proposal, and no archive has happened.

## Gotchas
- **A stale comment.** MineServer still says *"World Pulse loop: idle 15m →
  random event 1–5m → repeat"* above `startLoop`, but the loop does nothing.
- **Three different clocks.** The limited window, the rotating-offer season and
  the group wheel are separate. Offers now end 2026-11-08
  (`MineRotatingOffers.SEASON_END` = 11-01 + `EXTEND_SEC`, one week), and
  `LIMITED_DAYS` also runs to 11-08, but the battle pass
  (`MineScrolls.PASS_SEASON_END`) still ends 11-01. A fourth rule now sits on top:
  the season clock does not start until the owner launches it, see
  [season-and-launch](season-and-launch.md). Since `cc0262f` the Event Horizon window
  (`bigbang`) reads that season clock too (`LIMITED_DAYS` is now 47), while a
  window with real calendar dates (`opensUnix`, such as the Hallow one) still reads
  `os.time()`.
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
- Candy Crypt (2026-10-19, asked in the build report): should the Crypt end at
  layer 120 instead of hardening on below it? Should candy keep tripling every
  10 layers (a deep candy block is worth hundreds of 2,500-candy cases)? Should
  Event Digging also boost Event Horizon tools (it does not)? Is "candy and
  maybe a tool" the whole of a Crypt chest?

## See also
[zones-layers-and-seams](zones-layers-and-seams.md) · [cards-and-packs](cards-and-packs.md) · [shops-and-monetisation](shops-and-monetisation.md) · [social-quests-and-leaderboards](social-quests-and-leaderboards.md) · [pets](pets.md)
