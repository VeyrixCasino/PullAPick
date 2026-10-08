---
title: Wandering traders
type: system
status: partial
verified: 2026-10-08 @ bae3c5b
sources:
  - src/ReplicatedStorage/Mine/Shared/MineTrader.luau
  - src/ServerScriptService/Mine/MineTraderNPC.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau
  - tools/verify/trader.js
  - docs/TODO.md §6.1
related: [shops-and-monetisation, skins-cases-and-temper, charms, tools, hats-and-faces, zones-layers-and-seams, season-and-launch]
---

# Wandering traders

> Five travelling shops that stand on random depth outposts and sell **cases for
> temper tokens**. Where they stand and what they sell changes every 15 minutes,
> and is the same on every server.

Owner, 2026-10-07: *"make a rotating shop with tokens with a wandering trader
that spawns at random depth outposts in random zones, and dependant on what
depths/zone has different stuff (5 different cases (random tool), custom hats case,
random charm case)"* and *"5 different traders at once"*. The NPCs are static
part-built figures, which was the owner's choice.

## How it works

- **Everything is a pure function of the rotation number.** `MineTrader.rotationFor(now)`
  is `floor(now / ROTATE_SECONDS)` with `ROTATE_SECONDS 900`. Placement and stock
  are derived from `(rotation, zone, seam)` with a 32-bit hash. There is no saved
  table and no roll at spawn time, so **every server agrees** and a late joiner sees
  what everyone sees. This is also why a harness can test the "random" part.
- **Placement draws without replacement** (`MineTrader.placements`, a partial
  Fisher-Yates), `COUNT 5`. Five independent draws over about 50 spots would collide
  roughly a quarter of the time, and two traders on one pad would read as a bug.
  The author measured 0 collisions over 5,000 rotations.
- **Where they can stand.** `MineTraderNPC.spots()` lists every built
  `DepthPlaza_<zone>_<seam>` folder that has a `SurfaceClone.Square` (the pad the
  elevator lands on). The author measured **120 of 165** plazas qualifying. The list
  is **sorted** before placement indexes into it, because `GetChildren` order is not
  guaranteed and unsorted would make two servers disagree.
- **Stock is gated, then drawn** (`MineTrader.stockFor`). `minSeam` / `minZone` on
  each case decide what *could* be at a spot; the rotation decides which 3–5
  (`STOCK_MIN 3`, `STOCK_MAX 5`) it actually brought.
- **Seven cases** (`MineTrader.CASES`), base price in temper tokens:

  | case | kind | base | needs seam / zone | pays |
  |---|---|---|---|---|
  | `case_rough` Rough Tool Case | tool | 25 | 0 / 1 | a tool of tier 1–20 |
  | `case_keen` Keen Tool Case | tool | 60 | 500 / 1 | tier 15–38 |
  | `case_fine` Fine Tool Case | tool | 140 | 1500 / 2 | tier 32–55 |
  | `case_prime` Prime Tool Case | tool | 320 | 2500 / 4 | tier 50–70 |
  | `case_apex` Apex Tool Case | tool | 750 | 3500 / 6 | tier 66–82 |
  | `case_hats` Travelling Hats Case | hat | 180 | 500 / 1 | a hat; grade on `MineTemper` weights |
  | `case_charm` Charm Case | charm | 200 | 1000 / 1 | one graded charm; same ladder as the chest drop |

- **Price scales with where the trader stands** (`MineTrader.priceFor`):
  `base × (1 + 0.10 × seam/500) × (1 + 0.18 × (zoneIndex − 1))`, rounded, never below
  base. The deeper trader sells better tools out of the same case id, so a flat price
  would make the shallow stop strictly worse. The author measured `case_rough` at 25
  on the zone 1 surface and 67 at Mythral 500.
- **What a tool case pays** is a tier drawn **uniformly** inside the case's band, in
  a random family (pickaxe, drill or explosive) chosen by `Verbs.buyTraderCase`. The
  tool starts at **level 1 with `base = 1`**, not at your inherited best, "the case
  is the tool, not a free run up the upgrade ladder" (see
  [forge-and-recycling](forge-and-recycling.md) for why `base` matters).
- **Buying** is `Verbs.buyTraderCase`. Before a token moves it re-derives what the
  client could lie about: `Dig.TraderNPC.canTrade` re-derives the roster from the
  clock (naming an outpost is not standing at it), the `caseId` must be on that
  trader's shelf, `canAccessSeam` must pass, and the **price is the shelf row's**,
  never the payload's. The reward is rolled before the debit; a reward that cannot
  be built refunds.
- **The client panel** (`ClientFns.showTraderShop`, commit `d38b65e`) renders the
  offer the server sent and computes nothing: not prices, not stock, not
  affordability gates. It is rebuilt on every open, and its countdown ticks on
  `RunService.Heartbeat`.
- **The world.** `MineTraderNPC.start` checks the rotation every `task.wait(60)` and
  **destroys and rebuilds** the five models when it turns (no tweening, so a trader
  is never briefly in two places). Each is a counter, awning, hooded figure, lantern
  and one `ProximityPrompt` ("Trade" / "Wandering Trader", 16 studs) in a
  `WanderingTraders` folder. No Humanoid, no rig.

## Where it lives

| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineTrader.luau` | the rules, shared with the client | `CASES`, `COUNT`, `ROTATE_SECONDS`, `rotationFor`, `placements`, `stockFor`, `priceFor`, `rollCase` |
| `src/ServerScriptService/Mine/MineTraderNPC.luau` | bodies, prompt, spot list, roster check | `spots`, `build`, `start`, `offer`, `canTrade` |
| `src/ServerScriptService/Mine/MineServer.server.luau` | the till | `Verbs.buyTraderCase`, the `traderShop` remote |
| `src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau` | the panel | `ClientFns.showTraderShop` |
| `tools/verify/trader.js` | rules, placement spread, server wiring, client wiring | needs `luau` |

## Decided by the owner

- Five traders at once, at random depth outposts in random zones, rotating, paid in
  **tokens**, with stock that depends on depth and zone (2026-10-07, above).
- **Static part-built NPCs** (owner's choice, per the `31df92e` message).
- A charm from a trader is **no commoner than from a chest**: "you pay for the
  certainty of getting one, not for better odds" (`MineTrader.rollCase`).

## State right now

- **Rules, world, till and panel are all built.** The author played it: the panel
  opens from a real offer, the countdown runs, affordability tints correctly, the
  depth and zone pricing reaches the player, and `buyTraderCase` refuses an outpost
  with no trader (*"No trader there right now"*) and an unopened seam.
- **One check was never run live**, and the author said so: the shelf check (a
  trader cannot sell a case outside its depth gate), because the test profile could
  not reach any seam a trader stood at. It is covered statically in `trader.js`.
- **No trader-specific hats exist.** The rules commit (`a1f4cc1`) said the hat models
  were not in it, and I found no later commit that adds any. `case_hats` pays a gear
  piece from the normal catalogue (`Gear.catalogFor`).
- **Never run by the owner in Roblox.**

## Gotchas

- **"Tokens" here means `p.temperTokens`**, the same balance as skin cases and the
  Enchanter, not skill-tree tokens. See [ambiguous-terms](../ambiguous-terms.md).
- **The roster can lag by up to a minute.** The world checks every 60 seconds, but
  `canTrade` re-derives from `os.time()` on every purchase, so the till can
  disagree with the models for a moment. The till is the authority.
- **A manually built roster grants no purchase rights.** The author's own test hit
  this: forcing `NPC.build` at rotation 2 and then buying returned "no trader there".
  That is correct.
- **Placement took four tries** (`31df92e`): casting from above hit the Ceiling,
  casting from under the topmost part started underground in bigbang and bloodmoon,
  and the widest slab was the Ceiling again. The answer was already in the codebase:
  `MineDepthPlazas.ride` lands players on `SurfaceClone.Square`.
- `MineTrader` carries its **own** `mul32`; `MineConfig`'s is a file-local.
- **Server script locals.** The `buyCharm` comment says `MineServer` "sits at 197 of
  Luau's 200"; `compile.js` measured **5 left** on 2026-10-08. Trust the measurement,
  and see [luau-traps](../code/luau-traps.md).

## Open questions

- Should a trader pay the **hat case** a custom hat set of its own? The owner asked
  for a "custom hats case"; the code reuses the normal catalogue.
- Are 15-minute rotations and 5 traders right for the real player count? Nothing
  measures how long a player waits to find one.
- Should a trader's tool case ever pay an **Event Horizon** tool? Not today.

## See also
[shops-and-monetisation](shops-and-monetisation.md) · [skins-cases-and-temper](skins-cases-and-temper.md) · [charms](charms.md) · [tools](tools.md) · [hats-and-faces](hats-and-faces.md) · [zones-layers-and-seams](zones-layers-and-seams.md) · [season-and-launch](season-and-launch.md)
