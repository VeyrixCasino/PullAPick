---
title: World events
type: system
status: current
verified: 2026-10-19 @ 3863d14
sources:
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ServerScriptService/Mine/MineEventHorizon.luau
  - src/ReplicatedStorage/Mine/Shared/MineHorizonTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineSpaceMatter.luau
  - src/ReplicatedStorage/Mine/Shared/MineEventPass.luau
  - src/ReplicatedStorage/Mine/Shared/MineEHPets.luau
  - src/ReplicatedStorage/Mine/Shared/MineEventsView/init.luau
  - src/ReplicatedStorage/Mine/Shared/MineEventTabs.luau
  - src/ReplicatedStorage/Mine/Shared/MineCryptView.luau
  - src/ReplicatedStorage/Mine/Shared/MineEventNotice.luau
  - src/ReplicatedStorage/Mine/Shared/MineTheme.luau
  - tools/verify/crypt-ui.js
  - src/ReplicatedStorage/Mine/Shared/MineWorldEvents.luau
  - src/ReplicatedStorage/Mine/Shared/MineWorldPulseUI.luau
  - src/ServerScriptService/Mine/MineBloodLake.luau
  - src/ServerScriptService/Mine/MineHarbor.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ReplicatedStorage/Mine/Shared/MineCandyTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineTrickOrTreat.luau
  - src/ReplicatedStorage/Mine/Shared/MineCryptRules.luau
  - src/ServerScriptService/Mine/MineCrypt.luau
  - src/ReplicatedStorage/Mine/Shared/MineCryptChests.luau
  - src/ServerScriptService/Mine/TradeService.luau
  - tools/verify/crypt.js
  - tools/verify/_crypt.js
  - tools/gen/crypt-doc.js
  - docs/CANDY-CRYPT.md
  - src/ReplicatedStorage/Mine/Shared/MineCryptIcons.luau
  - tools/cursor/tasks/crypt-icons.md
  - wiki/open-questions.md §0e
  - wiki/open-questions.md "Candy Crypt v2"
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

> **Built 2026-10-10, redesigned twice on 2026-10-19**: the first redesign
> ([open-questions §0e](../open-questions.md)), then **"Candy Crypt v2"** the same
> day, which replaced much of it. The **server and shared half of v2 is in**
> (below, pinned by `tools/verify/crypt.js`); its screens are the next client
> session's (the v2 verbs and pushes are listed as awaiting the client in
> `tools/verify/crypt-ui.js`). **Every number is in `docs/CANDY-CRYPT.md`**,
> generated from the code by `tools/gen/crypt-doc.js` (and kept current by
> `tools/verify/crypt-doc.js`). Nothing here has run in Studio. Every number the
> owner did not give is PROPOSED in the code.

**v2, as built** (`MineCryptRules` holds the rules for both sides; the server
module `MineCrypt` grants, gates and is the authority for every roll, payout and
price; the tables are `MineConfig.CANDY_ECONOMY`, `MineCandyTools`,
`MineCryptChests` and `MineTrickOrTreat`):

- **Candy blocks only.** The zone row carries `candyOnly`: `veinOreAt`,
  `oreIdentity` and `rollOre` answer nil there, so no normal ore spawns, and
  `CANDY_ORE_SHARE` is 1, so every block that is not a chest is a candy block.
  The 20-minute reset and the rock (zone 3 at the top to zone 10 at layer 120,
  `cryptRockHp`, still selling for little through `cryptHaulRatio`) are unchanged.
- **Sixteen candy ores, two per rarity** (Common .. Exotic, by value). Each drops
  a **fixed** number of its ore item (`drop`: 4 for Commons down to 1 for
  Divine and Exotic) and its block pays a **flat** candy amount, the same at every
  depth: a quarter of `drop` x `value` (`value` is what one item sells for).
  **The odds shift every ten layers** (`candyRarityOdds`): each rarity is `q` times
  as common as the one below, `q` walking from 0.30 in section 1 to 0.58 in
  section 12 and holding below; the Exotic pair is capped at 1% (it reaches 0.94%).
  `capRatioWeights` is the shape, shared with the chests.
- **Only Halloween tools dig it** (`eventToolsOnly`, `MineSpaceMatter`'s event-only
  rule; `MineCryptRules.heldRow` swaps the held tool). **Sixteen Halloween tools,
  one per candy ore** (`MineCandyTools`), four families (Pick, Mallet, Auger,
  Cracker), ids `hallow_<ore>_<noun>`. Claiming the Crypt gives the **Candy Corn
  Pick**; a claimed save with no tool gets it back on load.
  - **Crafted at the Forge** from N of the tool's own ore (`cryptCraft`; 40 for a
    Common ore down to 10 for an Exotic one), **never dropped**.
  - **Prestige 1-10** (`cryptPrestige`), paid in more of that ore: step k costs
    `ceil(craft x 0.5 x 1.2^(k-1))`, all ten about 13 crafts. Each prestige adds
    +30% of the base power (x4 at 10). No levels, no merging. **Prestige keeps
    working after the event.** `MineCryptRules.prestigeLadder` gives each tool's
    damage at every prestige, in the Crypt and in the main world.
  - **At most ten.** The eleventh craft is refused until you **scrap** one
    (`cryptScrap`, asks first): half the candy value of every ore spent on it
    (the tool's own `spent` ledger), no ore back. The last tool cannot be scrapped.
  - **Power in the Crypt:** a tool is tuned so a pick of its base power takes 12
    hits at layer 15 + 7 x (rank - 1) (the Candy Corn Pick at 15, the Jawbreaker
    Auger at 120), the other families scaled by `MineOreTools.FAMILY_POWER`.
  - **In the main world, after the event** (`cryptEquip { world = true }`), a
    Halloween tool hits like a forged tool of its family: ore tier
    `8 + 74 x x^1.5` at level `1 + 29 x prestige / 10`, where x runs from 0 (the
    Candy Corn Pick at prestige 0) to 1 (the Jawbreaker Auger at prestige 10), and
    it breaks what that ore breaks. So the **top tool at prestige 10 is exactly a
    level-30 Oganesson drill**, the best normal tool at the top level (owner); every
    other tool and prestige is weaker. They also work in a later event mine.
  - **Each tool has its own factor on Halloween-set skins** (`skinFactor`, 1.5 to
    2.5): `MineToolSkins.wear` multiplies a Halloween skin's whole damage
    multiplier by it (owner: *"always multiplier to the full multiplier"*). The
    kit stats are not scaled.
- **Crypt chests** (`MineCryptChests`, `chestMult` 3, about ten in the Crypt):
  **eight ranks with Halloween names**, F Candy Sack, D Pumpkin Pail, C Cobweb
  Crate, B Bat Box, A Coffin Chest, S Witch's Cauldron, SS Phantom Vault, SSS
  Pumpkin King's Hoard. Rarer ranks are rarer and more common deeper (the same
  shape as the ores, SSS capped at 1%); the rank is stamped on the block at spawn.
  A chest pays **Halloween packs** (more and luckier at higher ranks: the
  Halloween 2026 Pack with the bag row's `luck`, which `openPack` already honours)
  and **flat candy** (40 at F to 25,000 at SSS); **the rank's own Halloween charm
  at 0.5% x Chest Luck** (`MineCharms.cryptChestCharm(rank)`, another agent's) and
  **a Halloween enchant book** when `MineEnchants.rollHalloweenBook(rankIndex, rng)`
  gives one (another agent's). No coins, gems or tools.
  - **A Crypt chest is soft.** Its HP is the main mines' chest curve
    (`MineConfig.chestHp`: the meadow's dirt × the look's multiplier), not the
    Crypt's rock: an F chest has 220 HP at layer 60, where the rock has 143,357,
    and 400 at layer 120 against 41,992,188. Lucky blocks there are the same.
    Unchanged since the first design; asked of the owner (2026-10-19).
- **The Trick-or-Treat case** (`MineTrickOrTreat`, 4,000 candy, bought and opened in
  one action while the Crypt is open and claimed): **Halloween pets and Halloween
  skins only**. The server rolls a rarity (40 / 25 / 15 / 10 / 6 / 2.5 / 1.2 /
  0.3%), a kind (pet 70%, skin 30%) and which one (`MineCryptRules.casePrize`:
  `MineHalloweenPets.pool` when it exists, else the Halloween 2026 Pack's list;
  the Halloween skin set), **then the 50/50: TREAT you get it, TRICK you get
  nothing**. One push, `trickOrTreatOpened { rarityIndex, rarity, kind, reward,
  outcome, price, candyLeft }`, so the client shows the rarity, then spins the
  wheel to the server's result. A skin you own pays stardust. `MineCryptRules.caseOdds()`
  is the odds sheet (the 50% is on it).
- **The Halloween inventory** (`p.halloween`): while the event runs, Halloween
  pets (with **their own team**, `cryptTeam`), Halloween tools, candy ores and
  Halloween charms (with **their own slot**, `cryptCharm`) are kept apart and are
  **what counts inside the Crypt**: `MineCrypt.petTeam` and `charmFor` feed
  `boosts()`, so in the Crypt only Halloween pets and a Halloween charm count, and
  elsewhere Halloween pets and charms count for nothing until the event ends.
  Skins and hats are shared. The main team's `equip` refuses a Halloween pet.
  Candy ores go to `p.halloween.ores` (never the main pouch); Halloween pets stay
  in `p.cards` and Halloween charms in `p.charms` (`MineCryptRules.isHalloweenItem`
  says which). **When the event ends it all moves into the main inventory**
  (`MineCrypt.moveToMain`, idempotent): on load, and every 30 s for everyone
  online (`MineCrypt.tick`, pushing `cryptClosed`). Candy ores land in `p.ores`,
  where they take no pouch room (`MineOrePouch.held` skips them).
- **Trading:** Halloween tools, candy ores and Halloween-inventory items cannot be
  traded while the event runs (`MineCrypt.tradeLocked`; `TradeService` asks it at
  offer, peek and commit). The Halloween 2026 Pack is locked with them
  (PROPOSED: it comes only from Crypt chests); other packs are not.
- **Selling candy ores** (`cryptSellCandyOres`, ask then confirm) sells from
  wherever they live now, at the ore's `value`.
- **Retired from the first design:** Crypt tools from chests and cases, the
  Golden / Prism / Rainbow merge (`cryptMerge`), the six crafted candy charms and
  `cryptCraftCharm`, normal ores in the Crypt, and the v1 save fields
  (`cryptTools`, `cryptToolEquipped`, `candySeen`), dropped on load.
- **First entry** pushes `eventNotice` until `cryptNoticeSeen` marks it.
- **The Crypt is remade** on the 20-minute mine-reset beat while it is open.
- **Gems:** nothing in the Crypt pays gems (candy ores never sell for gems; the
  first design's normal ores did, about 190 to 720 an hour by section, and are
  gone; `docs/CANDY-CRYPT.md` §8).
- **Art:** none yet. `MineCryptIcons` holds the icon ids (empty, and `SHARED =
  false`); `MineCryptRules` puts `icon` on tool, recipe, candy-ore and chest
  rows. The Cursor job `tools/cursor/tasks/crypt-icons.md` makes the 40 Canva
  images (16 ores, 16 tools, 8 chests) and fills it; the owner shares the
  uploads and flips `SHARED`.

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
  per-zone filter. Which candy a block is comes from its section's odds, rolled
  on a Random seeded from the cell position (the same block on every server).

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

### Events tab (both events, 2026-10-19)
`MineEventsView` (mounted as `eventsCtl` in the client, through `pcall`) shows
**every event whose window is open**, one pill each, so the Crypt shows while
Event Horizon is open too. It used to show the first open event, and Event
Horizon is open all season, so the Crypt had no screen. Which events show,
which one opens first and what each claim button says are
`MineEventTabs` (pure; run by `tools/verify/crypt-ui.js`):
- **Shown:** every event open by the snapshot's `limitedOpen` (else the Crypt's
  `crypt.window`). A closed event is not shown; a Crypt card after the event
  (for its tools' main-world switch) waits for the new tools API.
- **Opens on** the event whose zone you stand in, else the Crypt while it is
  open, else the first.
- **Each card its own claim:** the Crypt reads `crypt.owned` (`hallowOwned`),
  never `bigbangOwned`; "Claim Candy Crypt · FREE" / "Claim Event Horizon ·
  FREE" sends `buyZone` with that card's zone; owned reads "Owned — enter from
  Planets" and opens Planets.
- **The (i)** shows the event's own notice (`MineCryptRules.NOTICES`; the
  pop-up's words). Event Horizon has none, so its (i) shows its blurb, not
  the Crypt's notice (that one promises a main-world life its tools do not
  have).
- **Themes:** each card wears its event's palette (Event Horizon dark
  universe, the Crypt Halloween; `MineTheme.EVENT_THEMES`), and the panel
  around it takes the theme of the one showing (`MineUI.applyTheme`).
- **Event Horizon's card** keeps its banner, countdown (`limitedCountdown`,
  the pre-launch teaser) and Event Pass.
- **The Crypt's card** (`MineCryptView`, the shell): the candy balance beside
  the rule (`R.NOTICE.text`), and the Trick-or-Treat case's OPEN, which sends
  `buyTrickOrTreat`. It shows the snapshot's `casePrice`, and greys out and
  does nothing with "NEED n MORE 🍬" when short, "CLAIM THE CRYPT FIRST", or
  "OPENS SOON" / "THE CRYPT HAS CLOSED" (`MineCryptView.openState`). One case
  at a time: a second tap within 3 s, before the server answers, sends
  nothing. The window line on the card head shows its close date in the
  player's local time.
- **Not built yet (the next client session's, against v2's server):** the
  Halloween inventory screen (tools with EQUIP / PRESTIGE / SCRAP and each
  tool's damage ladder, the Halloween team and charm slot, candy ores), the
  Forge's sixteen Halloween recipes, the main-world switch after the event, and
  the case's odds sheet and result reveal (rarity, then the TREAT / TRICK
  wheel). The odds sheet's place is kept: `MineCryptView.mountCaseOdds` (builds
  nothing yet) and a hidden `OddsSlot` frame beside OPEN. Until then OPEN shows
  **no odds**; `buyTrickOrTreat` is not on `Verbs.PAID_RANDOM`, because candy
  does not trace back to Robux.
- **Results:** `trickOrTreatOpened` lets OPEN be pressed again; what came out
  is the server's toast for now (`MineCrypt.CASE_RESULT_TOAST`, to be turned off
  when the wheel shows it). A Crypt chest's popup shows the candy and the
  Halloween packs it paid; its charm and book rows wait for the client.

**First-entry pop-up** (`MineEventNotice`): on `eventNotice`, or when a snapshot
finds you in the Crypt with its notice unseen (`crypt.noticeSeen`), once a
session per event; only "Got it" closes it, and it sends `cryptNoticeSeen
{ zoneId }`, so the server never asks again. In the event's theme, no scale
animation.

**Wallet:** a candy pill joins the wallet only while you stand in the Crypt
(`ClientFns.paintCandyPill`); outside the event the HUD is unchanged.

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
| `src/ReplicatedStorage/Mine/Shared/MineCryptRules.luau` | the Candy Crypt's rules, shared | `heldRow`, `window`, `separate`, `isHalloweenItem`, `prestigeLadder`, `craftPlan`, `prestigePlan`, `scrapPlan`, `teamFor`, `charmFor`, `casePrize`, `caseOdds`, `chestOdds`, `inventoryOf`, `stateFor`, `NOTICE` |
| `src/ServerScriptService/Mine/MineCrypt.luau` | Crypt grants, verbs, hooks, the Halloween inventory | `dispatch`, `normalize`, `heldTool`, `petTeam`, `charmFor`, `mainTeamRefuses`, `inventoryOf`, `tradeLocked`, `moveToMain`, `tick`, `onClaim`, `onBlockBroken`, `openChest`, `buyTrickOrTreat`, `haulPoints` |
| `src/ReplicatedStorage/Mine/Shared/MineConfig.luau` | the candy ores and their odds; candy-only zones | `CANDY_ECONOMY`, `CANDY_ORES`, `candyFor`, `candyDropFor`, `candyOreValue`, `candyRarityOdds`, `candyOreOdds`, `candyOreAt`, `capRatioWeights`, `isCandyOnly` |
| `src/ReplicatedStorage/Mine/Shared/MineCandyTools.luau` | the sixteen Halloween tools | `TOOL_TABLE`, `TOOLS`, `prestigeCost`, `totalSpent`, `scrapCandy`, `cryptPower`, `worldEquivalent`, `worldPower` |
| `src/ReplicatedStorage/Mine/Shared/MineCryptChests.luau` | the eight Crypt chests | `RANKS`, `rankOdds`, `rollRank`, `spawnDef`, `charmChance`, `packRows` |
| `src/ReplicatedStorage/Mine/Shared/MineTrickOrTreat.luau` | the case | `PRICE`, `RARITIES`, `KIND_WEIGHTS`, `TREAT_CHANCE`, `roll`, `odds` |
| `src/ReplicatedStorage/Mine/Shared/MineCryptIcons.luau` | the Crypt's icon ids, behind `SHARED` | `ORES`, `TOOLS`, `CHESTS`, `ore`, `tool`, `chest` |
| `tools/verify/crypt.js`, `tools/verify/_crypt.js` | runs the real modules and `MineCrypt` on one shared harness: v2 end to end | |
| `tools/gen/crypt-doc.js`, `docs/CANDY-CRYPT.md`, `tools/verify/crypt-doc.js` | the numbers document, generated from the code, and its freshness check | |
| `src/ReplicatedStorage/Mine/Shared/MineEventsView/init.luau` | the Events tab: pills, one card per event, (i), Event Pass | `mount`, `view.onCaseOpened` |
| `src/ReplicatedStorage/Mine/Shared/MineEventTabs.luau` | which events show, which first, each claim (pure) | `shown`, `defaultId`, `owned`, `claim`, `notice`, `cryptWindowLine` |
| `src/ReplicatedStorage/Mine/Shared/MineCryptView.luau` | the Crypt card's shell: candy, Trick-or-Treat OPEN | `mount`, `openState`, `mountCaseOdds` (placeholder) |
| `src/ReplicatedStorage/Mine/Shared/MineEventNotice.luau` | the first-entry pop-up | `mount`, `shouldShow` |
| `tools/verify/crypt-ui.js` | the client half: verbs sent, pushes handled, both events, own claim, pouch, pop-up, themes; mounts the screens on a GUI stand-in and presses their buttons | |
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
- **Candy Crypt v2: server and shared built (2026-10-19), screens next.** The
  server and shared data are pinned by `tools/verify/crypt.js`. The first
  redesign's screens are pinned by `tools/verify/crypt-ui.js`, which also mounts
  them on a GUI stand-in: the Events tab's two cards, the Crypt card's shell,
  the candy sale and SELL UP TO in the pouch, the pop-up and the candy pill. The
  pouch's candy section still reads `p.ores`, where v2 keeps candy ores only
  after the event: during it they are in the Halloween inventory. v2's own
  screens (above) are the next client session's. **Nothing has run in Studio.**
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
- Candy Crypt (2026-10-19, asked in the first build report): should the Crypt
  end at layer 120 instead of hardening on below it? Should Event Digging also
  boost Event Horizon tools (it does not)? (v2 settled the other two: candy is
  flat per ore, and a chest pays packs, candy, a charm and books.)
- Candy Crypt v2 (2026-10-19, asked in the V2-A build report): may a NEW
  Halloween tool be crafted after the event (`CRAFT_AFTER_EVENT`, now no)? Are
  Halloween packs trade-locked during the event like the pets they open into
  (now not)? Does a Halloween tool's skin factor also scale the skin's kit stats
  (now damage only)? Should the pop-up's "Tools you find" become "Tools you
  craft" now that nothing drops one?
- The Crypt's screens (2026-10-19, asked in the client build report): does
  Event Horizon get a first-entry notice of its own (its (i) shows its blurb
  meanwhile)? Should the TODAY row for the Crypt open the Events tab rather
  than Planets? Until the odds sheet is built, should OPEN stay live with no
  odds on screen (as the scope change asked)? TODO B3 says "show the odds
  wherever a roll can be bought".

## See also
[zones-layers-and-seams](zones-layers-and-seams.md) · [cards-and-packs](cards-and-packs.md) · [shops-and-monetisation](shops-and-monetisation.md) · [social-quests-and-leaderboards](social-quests-and-leaderboards.md) · [pets](pets.md)
