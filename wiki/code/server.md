---
title: The server — MineServer.server.luau
type: code
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - src/ServerScriptService/Mine/MineServer.server.luau
  - docs/START-HERE.md §4, §5
  - docs/HANDOFF.md §2.2, §2.3, §2.8
  - docs/TODO.md §0.14, §1
related: [code-map, client-and-ui, save-data-and-migrations, luau-traps, admin-and-debug, trading, social-quests-and-leaderboards]
---

# The server — `MineServer.server.luau`

> One Script runs the whole game. It loads and saves players, routes every
> client request, deals block damage and pays out loot. It is authoritative:
> the client only displays (TODO §3, pillar 6).

## Size and shape

- `src/ServerScriptService/Mine/MineServer.server.luau` is **17,050 lines** at
  `26036a0`. Older docs give 16.7k (HANDOFF §2.2) or about 14,800 (TODO §1,
  `tools/agent/house-rules.txt`). Read only the part you need. Never rewrite it.
- It has **197 top-level `local` lines**, against Luau's limit of 200 local
  registers per function. See [luau-traps](luau-traps.md).
- The order of the file, top to bottom:
  1. requires
  2. the `Dig` and `Const` tables
  3. the DataStores
  4. `blank()`, `load()` and `save()` (see [save-data-and-migrations](save-data-and-migrations.md))
  5. `snap()` and `markDirty()`
  6. gameplay functions
  7. `local Verbs = {}` and its 107 `Verbs.x` definitions
  8. `WorldBuilder.build()` and `LeaderboardService.start(net)`
  9. the player hooks, and the 45-second autosave
  10. the action router
  11. world binding
  12. a final `print("[Mine] server ready …")`

## The `Dig.*` pattern (the 200-local ceiling)

A new module or helper does **not** get a new top-level `local`. It goes on a
table that already exists:

- `local Dig = { Traits, Layers, Depth, Auth, Shop, Plazas, Breaking }` holds
  requires. The comment there says the script "sits at 197 of Luau's 200".
- 26 more `Dig.x` fields are added further down: `Dig.bankOrePacks`, `Dig.addOre`,
  `Dig.pouch`, `Dig.QUAKE`, `Dig.echoAt`, `Dig.procsAt`, `Dig.boostSources`, and others.
- `local Const = { THROW_SPEED, … }` packs scalars into one register.
- One-shot setup goes in `do … end` blocks, so its locals do not count. The
  `ensureRemote` block is an example.

A table field is looked up when it is called, so `Dig.x` is also safe from the
declaration-order trap (HANDOFF §2.3).

## Remotes and the action router

- The server **creates** `ReplicatedStorage.Mine.Remotes.MineNet`, a single
  RemoteEvent. The folder in git is empty. `AdminReady`, `AdminNotify` and
  `AdminInvoke` are created early in the file, because `MineAdminClient` waits on
  them with no timeout.
- Every client request arrives as `net:FireServer(action, payload)` and is handled
  by **one** `net.OnServerEvent:Connect(function(plr, action, payload)`. That
  handler is one long `if action == "…" elseif …` **string compare**. At
  `26036a0` it has **142 distinct action strings**. There is no Remotes type system
  (START-HERE §5).
- Handler order:
  1. `swing` takes a fast path: no lock, `pcall(swingBlock, …)`.
  2. Every other action takes a per-player `busy[userId]` lock. A second request
     that arrives while one is running is **dropped**, not queued.
  3. `Verbs.policyBlocks` refuses paid-random actions (when the PolicyNoRandom
     attribute is set) and refuses `discordLink`.
  4. The branch runs inside a `pcall`. An error goes to `warn("[Mine] …")`.
- 57 of the 141 branch lines call `Verbs.x` on the same line. The rest call
  file-local functions (`buy`, `equip`, `openAt`, `swingBlock`…), call
  `Verbs.Afk.*` on the next line, or have the logic written inline
  (`drinkPotion`, `buyDustPack`, `devGrant`).
- Old names are kept so stale clients still work. `skillSacrifice` maps to
  `Verbs.skillSell`. `fossil_assemble`, `fossil_equip` and `fossil_sell` answer
  with a toast. `devGrant` only runs in Studio (`RunService:IsStudio()`).
- Trade, social and leaderboard actions are forwarded:
  `TradeService.invite`, `TradeService.setOffer`, `SocialService.friendRequest`,
  `LeaderboardService.payloadFor`, and similar.
- Every string literal the client fires has a branch on the server (diffed at
  `26036a0`: 122 client literals, none unhandled). These 20 server branches have
  no client literal: `dig`, `buyPouch`, `buyCrate`, `buyCharter`, `skillBuySlot`,
  `unequipTool`, the debug grants, the fossil verbs, and some social and trade
  verbs. Some of them may be fired with a computed name *(unverified)*.

## Server → client events

The server calls `net:FireClient(plr, event, payload)` with about 48 distinct
event names. The client handles them in a single `net.OnClientEvent` ladder.

| event | what it carries |
|---|---|
| `snapshot` | the full player view, sent by `snap(plr)`. `markDirty` batches these to at most 10 a second. |
| `toast` | a text notice. About 437 call sites. |
| `loot`, `purchaseFx`, `opened`, `foundTool` | feedback for rewards |
| `seamGate`, `openElevator`, `openPanel`, `confirmSellAll` | ask the client to open a UI |

## Round trips are named differently on each side

| server fires | client opens | client fires back | server handles |
|---|---|---|---|
| `seamGate` | the seam panel | `buySeam` | `Verbs.buySeam` |
| `openElevator` | `elevCtl.open` | `rideElevator` | `Dig.Plazas.ride` |

So a grep for one name finds only half the chain. HANDOFF §2.8 and OPEN P0 #1
record that the seam purchase was wrongly declared "unwired" this way. **Grep the
verb and the event before concluding anything is dead.** The line numbers HANDOFF
gives for this chain have drifted, so search by name.

## Player data in memory

- `profiles[userId]` is `p`: the whole save, loaded by `load()` and written back
  as-is by `save()`.
- The main groups of fields:
  - wallet: `p.coins`, `p.gems`, `p.dust`, `p.credits`
  - ore: `p.ores[id]`, `p.oreTools`, `p.orePouchTier`, `p.oreLocks`, `p.oresSeen`
  - depth: `p.deepest`, `p.seams`
  - inventory: `p.packs`, `p.cards`, `p.charms`, `p.gear`, `p.runes`
  - progression: `p.prestige`, `p.skillPresets`
  - counters: `p.stats`, `p.quest`, `p.intro`
- Full shape and migrations: [save-data-and-migrations](save-data-and-migrations.md).

## Other server modules and how they are wired

| module | how it is wired |
|---|---|
| `MineDigAuth`, `MineDepthPlazas` | required onto `Dig.Auth` and `Dig.Plazas` |
| `MinePatterns`, `MineAntiGear`, `MineBadges`, `WorldBuilder`, `LeaderboardService`, `GroupWheelService`, `TradeService`, `SocialService` | top-level requires |
| `WorldBuilder` | `WorldBuilder.build()` at boot builds the map. It loads `MineHarbor` (mistreef), `MineBloodLake` (bloodmoon) and `MineEventHorizon` (bigbang) per zone, and `MineShopFronts`. |
| `MineEdgeBarriers`, `MinePlayerCollision`, `MineDepthLive`, `MineEventHorizon`, `MineBigNum` | required inline where used, which saves registers |
| `MineAdmin` | `start()` is called at the bottom of the file and adopts the early remotes ([admin-and-debug](../systems/admin-and-debug.md)) |
| `MineWorldEvents` (Shared) | `.bind({ … net … })` near the top ([world-events](../systems/world-events.md)) |
| `TCGServer/*` | not wired. AfkService and PortalService are disabled by `.meta.json` ([code-map](code-map.md)). |

## Gotchas

- Docs cite MineServer by line number (`MineServer:6406` and so on). Those numbers
  drift by hundreds as the file grows. Cite symbols.
- Studio and Cursor edit this file at the same time (TODO §9). Anchor every edit
  on unique text, and re-read the file before committing.
- Changes to `Dig.Breaking` must reach every path that deals damage.
  `tools/verify/gate-coverage.js` checks this.
