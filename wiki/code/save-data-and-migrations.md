---
title: Save data and migrations
type: code
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ReplicatedStorage/Mine/Shared/MineStats.luau
  - src/ServerScriptService/Mine/LeaderboardService/init.luau
  - src/ServerScriptService/Mine/SocialService.luau
  - docs/START-HERE.md §4.4
  - docs/HANDOFF.md §2.3
  - docs/TODO.md §9
  - tools/verify/statkeys.js
  - tools/verify/orepacks.js
related: [server, luau-traps, ores, ore-pouch-and-backpack, tools, traits, retired-and-parked]
---

# Save data and migrations

> A player's whole save is one table, `p`, stored under one key. Every rename of
> an id or a stat key is therefore a **save migration**, and the migrations
> already in `load()` show how this project does one safely.

## DataStores

| store | key | holds | where |
|---|---|---|---|
| `Mine_v1` (`MineConfig.DATASTORE`) | `u_<userId>` | the whole profile `p`, plus `_lock` | MineServer `load` / `save` |
| `Mine_v1_card_serials` | card serial | the owning userId for each card | MineServer `serialStore` |
| `DustShopGlobal_v1`, `InviteRewards_v1` | — | the stardust shop's global stock, and invite rewards | MineServer, via `MineConfig.storeName` |
| `Mine_v1_lb_{prestige,gems,stardust_value}`, `_lb_depth_<zone>`, `_lb_roster`, `_lb_meta` | — | leaderboards (Ordered stores) | `LeaderboardService` |
| `Mine_v1_{friends,inbox,groups,user_groups}` | — | social data | `SocialService` |
| `Mine_v1_discord_{pending,claims,links}`, `Mine_StudioFlags` | — | Discord link state, Studio-only flags | `MineDiscordLink`, `MineStudioGrant` |
| `TCGProgression_v1`, `TCGPlayerWallet_v1` | — | legacy AFK-place data. Dormant, because AfkService is disabled. | `TCGServer/` |

**Studio never touches live data.** In Studio every name gets `_Studio` appended
(`MineConfig.DATASTORE_SUFFIX`, `MineConfig.storeName`, and each service's own
`STORE_SUFFIX`). Published servers use the plain names.

## Load and save (`load`, `save` in MineServer)

- **Session lock.** `load` claims the save with `UpdateAsync`, writing
  `_lock = { job = JobId, t = os.time() }`.
  - It tries up to 8 times. A lock from another server that is less than 120 s
    old makes it wait.
  - If the save still cannot be read, the player is **kicked with a "rejoin"
    message**. A blank profile is never written over a real one.
  - In Studio, if claiming fails, it falls back to `GetAsync`.
- **Ephemeral profiles.** If `load` throws, `Verbs.hookPlayer` gives the player a
  blank profile marked `_ephemeral`. `save` refuses to write it.
- **Writing.** `save` writes the **entire** `p` back with `UpdateAsync`.
  - It tries 3 times.
  - It refuses to write if another server holds a fresh lock.
  - A final save (leaving, or shutdown) releases the lock.
- **When saves happen.** An autosave runs every 45 s. On leave and at shutdown,
  saves are tracked so `BindToClose` waits for the ones still running.
- **A one-off owner reset.** On a published server, a one-time branch backs up the
  owner's test save to `u_<id>_prelaunch_backup` and clears it. The existence of
  the backup key stops it from ever running again.

## The save shape (`blank()` plus normalisation in `load`)

- **Wallet:** `coins`, `gems`, `dust` (stardust), `credits`, `spaceCoins`
- **Ore** ([ores](../systems/ores.md), [pouch](../systems/ore-pouch-and-backpack.md)):
  - `ores[id] = n`: banked ore
  - `orePouchTier`, `oreLocks`
  - `oresSeen`: a set that only grows
  - `oreTools`: rows of `{ uid, tier, typeId, level }`. **`uid` is minted once and
    never regenerated. `tier` is an index into `MineConfig.ORES`.**
- **Depth:** `deepest[zone]` (keys normalised to strings), `seams`, `zoneId`,
  `maxUnlockedZone`, `prestige`
- **Collections:** `packs` (each `{packId, packName, setId}`), `cards`, `charms`,
  `tempers`, `gear`, `runes`, `relics`, `chestTools`, `vfx`, `potions`, `scrolls`
- **Progression:** `skillPresets`, `skillSlot`, `stats` (counters), `quest`,
  `dailyQuests`, `intro`, `pass`, `daily`
- **Migration stamps** are fields too: `oreRosterV`, `toolCapV`, `introVer`,
  `questVer`, `backpackCoinV2`, `backpackCatalogV3`, `_drillBombLadderV2`

**Ore ids are load-bearing twice**: in `p.ores[id]`, and in every `"<id>_ore_pack"`.
A roster change needs an id→id map that keeps the old ids as aliases (TODO §9).

## Every migration in `load()` (in run order, roughly)

| migration | stamp | what it does |
|---|---|---|
| Event Horizon renames | none (alias maps) | renames pet cards via `PetRoster.NAME_ALIASES`, and remaps event tool ids |
| Gear seats | none | moves `equippedGear.gloves` to `face`. The hat seats come from `Gear.HAT_SLOTS`, so `hat2` survives a rejoin. |
| Runes and gear | none (runs every load) | `Runes.normalize` and `Gear.normalize`: labels tiers, converts word grades to letters, and **canonicalises stat keys** (below) |
| Dropped fields | none | sets `fusePity`, `toolMastery` and `petHats` to nil. Ranged sockets fold into the pickaxe. |
| Intro and quest ladders | `introVer` 2→4, `questVer` 2 | moves saved step numbers onto the new ladders (`Quests.remapV1`) |
| Backpack ladder | `backpackCoinV2`, `backpackCatalogV3` | the old 6-rung gem ladder becomes the 30-rung coin ladder, matched by capacity |
| **Ore roster v1** | `oreRosterV = 1` | `MineConfig.ORE_MIGRATION`: 33 retired ids. Sums `p.ores` and renames packs. |
| **Ore roster v2 (121 → 82)** | `oreRosterV = MineConfig.ORE_ROSTER_V` (2) | `MineConfig.ORE_MIGRATION_V2`, and `MineConfig.ORE_TIER_REMAP_V2` for `oreTools[].tier`. Clamps levels. Its 50 % refund **has never paid out**; the comment in the code explains why and says not to copy it. |
| **Tool level cap** | `toolCapV < MineConfig.TOOL_CAP_V` (1) | clamps `oreTools` levels to `TOOL_MAX_LEVEL` (30). Deliberately no refund, because the clamped tool comes back maxed. **Bump the stamp whenever the cap goes DOWN.** |
| Drill and explosive ladder | `_drillBombLadderV2` | adds 1 to owned drill and explosive rungs after new tier-1 tools were inserted |
| **Fossils cash-out** | none (it clears the fields) | `retireFossils(p)` pays gems for pieces and tools, then toasts the player. Fossil verbs now only answer with a toast ([retired-and-parked](../systems/retired-and-parked.md)). |
| **Legacy ore packs banked** | **none, on purpose** | `Dig.bankOrePacks(p)` turns each `<id>_ore_pack` into banked ore: the yield band's midpoint × the pack's stamped finder, capped by `MineConfig.ORE_PACK_FIND_CAP`. It only converts if the ore fits the pouch. Runs after the roster passes. |
| Depth grandfathering | none (add-only) | `Dig.Depth.grantReachedSeams(p)` grants seams from `p.deepest` |

There are a few more lazy one-offs: the 70-tool table in `equippedTool`, and the
legacy single temper moving into slot 1 when a temper is rolled.

## "A stat key is DATA"

Stat names such as `blastChance` are **stored** on saved runes (`rune.stat`) and
gear (`piece.stat` and each `piece.stats[]`). Renaming one in code without a
migration silently zeroes what players rolled (START-HERE §4.4, HANDOFF §2.3 #4).

- `oreYield` → `blastChance` (2026-10-04): `MineStats.LEGACY_STAT` and
  `MineStats.canonStat` map the old key on load, via `Runes.normalize` and
  `MineGear.canonStat`. `tools/verify/statkeys.js` guards it.
- `fossilFind` keeps its name even though fossils are gone, for exactly this reason.
- Set runes take their stats from `MineRunes.SETS` and **bypass** `NO_ROLL_STATS`.
  Retiring a stat means editing that table by hand as well (HANDOFF §2.3 #5).

## How to add a migration

1. Give it a **new** stamp of its own. Never edit an old pass in place, or saves
   that predate it skip a step. The ORE_MIGRATION_V2 comment explains this.
2. If a stamp would strand data (a full pouch), make the pass idempotent instead.
3. Never map an id to itself. That deletes the pile.
4. Tell the player with a toast when their bag visibly changes.
5. Write a `tools/verify/` check that fails on the broken save shape.

## Gotchas

- `MineStudioGrant.playtestReset` wipes a Studio profile when the
  `ForcePlaytestReset` attribute is set (`src/ReplicatedStorage/Mine/init.meta.json`
  sets it to false).
- The 45-second autosave window once lost daily-streak and pass claims. Those
  paths now persist immediately (MineServer comments near `claimPass`).
