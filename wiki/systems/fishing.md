---
title: Fishing
type: system
status: partial
verified: 2026-10-13 @ 98c141a
sources:
  - src/ReplicatedStorage/Mine/Shared/MineFishing.luau
  - src/ReplicatedStorage/Mine/Shared/MineFishingFight.luau
  - src/ReplicatedStorage/Mine/Shared/MineFishingView.luau
  - src/ReplicatedStorage/Mine/Shared/MineToday.luau
  - src/ServerScriptService/Mine/MineFishingService.luau
  - src/ServerScriptService/Mine/MineFishPonds.luau
  - src/ServerScriptService/Mine/WorldBuilder.luau
  - src/ServerScriptService/Mine/MineDepthPlazas.luau
  - tools/sim/fishing-tune.js
  - tools/verify/fishing.js
  - tools/verify/today.js
  - docs/FISHING-TUNING.md
  - docs/TODO.md A3
related: [zones-layers-and-seams, currencies-and-economy, social-quests-and-leaderboards, rebirth-and-skill-tree, client-and-ui]
---

# Fishing

> The second progression track (TODO A3). You walk out on a pier and cast, which
> is a timing bar where a good or perfect cast adds luck. Then you reel, which is
> a fight against a fish that turns green, yellow or red. A landed fish is a
> **fish card** in your **cooler**. Bait is limited to 15 a day. Rods cost coins
> and level up for coins, with a token prestige every 10 levels. The first spot is
> Greyvein Quarry's surface pool.

## How it works

**Where.** `MineFishing.SPOTS` lists the spots.
- **Greyvein's surface pool.** `sunscar_pond` ("Quarry Pool") sits on the back
  corner of the outpost square (`WorldBuilder.buildOutpost`).
- **Underground pools.** There is one in each fishing zone's station bay at the
  1,000 and 3,000 outposts: `sunscar_1000` "Seep Pool", luck ×1.25, and
  `sunscar_3000` "Deep Sump", luck ×1.6 (`MineDepthPlazas.wallOutpost`).
- `MineFishPonds.build` draws the pool, the pier and the **dock**. The dock is
  tagged `MineFishSpot`, with attributes `SpotId` and `Machine="fish"`, and holds
  the Fish prompt.
- The server accepts a cast only within `SPOT_RADIUS` (40) of the dock.

**Fish.** Each permanent zone has its own list (`MineFishing.FISH`): 12 fish from
★ to ★★★★★ in half steps (two each of ★ / ★½ / ★★, then one per higher half-step).
Greyvein's run from Gravel Minnow to Monolith Koi; the other nine zones mirror that
grade shape with thematic names (PROPOSED). `ZONE_DIFFICULTY` scales fight hardness
by zone (PROPOSED: ~1.05^(zoneIndex−2), Greyvein = 1). Event Horizon has no list yet.
Before luck, the odds (`GRADE_WEIGHT`) are:

| ★ | ★½ | ★★ | ★★½ | ★★★ | ★★★½ | ★★★★ | ★★★★½ | ★★★★★ |
|---|---|---|---|---|---|---|---|---|
| 45% | 25% | 14% | 8% | 4.5% | 2.2% | 1 in 111 | 1 in 333 | 1 in 2,000 |

- Luck lifts grade g by luck^((g−1)/8). Total luck is rod × spot × cast:
  perfect ×1.5, good ×1.2.
- A fish's size is a uniform roll squared, so most catches are small.
- The size also sets how hard it fights: `MineFishingFight.spiritOf`, ×0.6 to
  ×1.6.

**The fight** (`MineFishingFight`, pure and deterministic).
- **Per tick (30 a second):**
  - Reeling pulls the fish in on every colour, fastest on green. A held reel also
    cancels part of the fish's run (`hold`). So even on red, a tap "holds it off
    a bit" and spam-tapping through a run is a real strategy (owner, 2026-10-11).
  - Reeling also raises the tension, divided by the rod's line strength: barely on
    green, a fair bit on yellow, steeply on red.
  - Letting go lets the tension fall back, but not below the **floor**.
  - The floor creeps up while you hold the tension above 0.6.
- **The finish is a fight** (owner: *"Finish has to be more of a challange"*).
  Inside 14 m the fish stops tiring, runs 1.7× as often and pulls 1.3× as hard.
  The first time it gets inside 9 m, it lunges: a run starts at once.
- **Losing.** Tension 1 snaps the line. Past 100 m, each metre over is a 3% a
  second escape chance (owner's rule). At 140 m it is gone.
- **Harder grades.** They run more often and for longer, swim harder and tire
  later. 20% of runs are long ones. Since 2026-10-11, fights start closer (25–45 m)
  and calm for less, so they are risky without being long.

**On screen and in the pond** (`MineFishingView`; owner, 2026-10-11: *"make it look
like your fishing in a pond"*).
- **The FISH tab:** icons and numbers, with sentences behind (?). A 👆 points at
  CAST until your first cast.
- **The minigame is mostly in the world**, and client-side only:
  - a **procedural wood rod** (Parts + WeldConstraint to `RightHand`, no mesh
    upload) in `Workspace.MineFishFx`, with handle, reel and tip eye; a line
    (Beam) from the tip that sags when slack and pulls straight / reddens as
    tension climbs;
  - a **cork bobber** (tan ball + red cap + stem) that sits on the tip during
    the cast wind-up, flies out on an arc (further for more power), then floats
    on the pond; it **stays visible** under the fish marker during the fight;
  - the bite splashes;
  - the **fish marker** is a 🐟 bubble in the fish's colour, with the distance
    under it. It swims the pool: toward the far rim as it gets away (100 m = the
    rim), side to side, harder when it runs.
  - **0 m is the tip of the dock**, not the rim behind it (`findPond` measures the
    Dock and Pier parts along the pool; `pondPoint` counts from there). Before
    2026-10-12 the pool counted from the rim. On the Quarry Pool (32 studs long,
    the pier 10 in), that put the first third of every fight under the planks.
  - **The tutorial's hint card** (the `Intro` frame MineClient builds) hides while the cast/reel HUD is
    up, because it sat over the gauge. It comes back after.
- **One button, bottom centre:** Cast, then Reel (or F). A half-circle gauge round
  it shows the power while casting (gold = perfect) and the tension while
  reeling (the floor in dark red). It shakes near the snap.
- **No instructions** except on the first cast ever.
- **Big words** for FISH ON!, LANDED!, SNAP! and GOT AWAY. A catch celebrates by
  its real rarity (`MineCelebrate`).

**Anti-cheat by replay** (`MineFishingService`).
1. `fishStart`: the server checks you are at the spot and have bait.
2. `fishCast {tick}`: the cast bar is a pure function of the tick
   (`MineFishing.castBar`). The server checks that enough real time passed,
   grades the cast, spends the bait, rolls the catch and sends the fight: a seed,
   the hardest fish's numbers, the rod and the bite delay.
3. `fishReel {toggles, ticks}`: the client sends only the ticks on which REEL went
   down or up. The server replays them with `MineFishingFight.replay` and checks
   the fight took at least that long. Only a replayed "caught" lands the fish.

**A 5-bait rod** (the Trawler). Five fish bite and you get one fight, against the
best of them. Win and all five reveal worst to best. Lose and all five go (owner's
pick).

**Bait.**
- At most `BAIT_DAY_CAP` 15 gained a day, from three sources that share the cap:
  - AFK: 1 per 8 minutes online (`afkTick`, every 20 s);
  - daily quests: +2 each (`Verbs.claimDailyQuest` → `Verbs.Fish.questBait`);
  - **tokens**: 10 each (`fishBuyBait`).
- A new player gets 3 starter bait (PROPOSED, `STARTER_BAIT`).

**Rods** (`MineFishing.RODS`, coins; PROPOSED prices).

| rod | price | reel | line | luck | bait/cast | level base |
|---|---|---|---|---|---|---|
| Twig Rod | free | 6.0 | ×1.00 | ×1.00 | 1 | 400 |
| Quarry Rod | 60K | 7.2 | ×1.25 | ×1.12 | 1 | 6K |
| Deepline Rod | 4M | 8.4 | ×1.55 | ×1.25 | 1 | 300K |
| Trawler Rod | 300M | 9.0 | ×1.80 | ×1.35 | **5** | 20M |

(Reel speeds went up ×1.5 on 2026-10-11, when fights got spikier: the tuner found
the slower rods made every fight minutes long.)

- A level costs level base × 1.6^level coins.
- Each level adds 2% reel, 2.5% line and 1.5% luck.
- Every 10 levels the rod stops until a **prestige** is paid in tokens: 100, 300,
  1,000, then 3,000. Fifty levels in all.
- `p.fishing` is on `Verbs.KEEP_ON_REBIRTH`, so rods, levels, bait and the cooler
  survive rebirth.

**The cooler.** `p.fishing.cooler[fishId] = { n, best }`, opened from any spot
(the COOLER tab). **Selling for coins is built** (`fishSell` / `fishSellAll`):
one SELL on a card, or SELL ALL with a server-priced confirm (ore-pouch
pattern). Coins only — not gems. Selling to `n = 0` keeps the row so the card
stays known. Trading is not built.

**Album set bonuses (PROPOSED, first cut 2026-10-13).** The album is cooler
known fish (a row present = ever caught; `n` may be 0). One set per zone
(12 fish). Bonuses apply only at that zone's spots:

| progress | luck at that zone's spots |
|---|---|
| 3 of 12 (milestone) | ×1.02 (+2% PROPOSED) |
| 12 of 12 (complete) | ×1.05 (+5% PROPOSED) |

Complete replaces the milestone (does not stack 2%+5%). Completing other zones
does not stack onto this spot; soft-cap later if needed. Cast luck is
`rod × spot × album × cast quality` (`MineFishing.albumLuck`, applied in
`MineFishingService.fishCast` / `fullState`). Progress shows on the FISH tab
and COOLER tab (`📗 ALBUM n/12`), and as a chip on ODDS.

**Sell price (PROPOSED).** `MineFishing.sellCoins`:
`floor(120 × 2.8^(gradeIndex−1) × (0.55 + size))`. Cooler sells use
`TYPICAL_SIZE` 0.25 (median of the squared size roll), because the cooler does
not store every fish's kg. At that size: ★ ≈ 96 coins, ★★★★★ ≈ 363K.

**Catch of the day.** One global target fish per UTC day
(`MineFishing.catchOfDay(day)`), seeded so every server agrees. Landing it sets
`cotdGot`; `fishClaimCotd` pays coins (`CATCH_OF_DAY_BASE` 2500 × 2.8^(g−1) ×
0.5, PROPOSED). TODAY shows the row while unfinished or claimable
(`MineToday`, open `"fish"`): claim when ready, else open the nearest pond.
Also on the FISH tab.

## The learning machine (tuning)

Owner: *"test with a little shitty learning machine, and figure out whats the brink
of possibility, and tone down from there"*.

`node tools/sim/fishing-tune.js` trains a bot on the real fight module in luau. It
uses the cross-entropy method over a small policy: a tension limit per colour, a
hysteresis, a distance panic and a tap rhythm for runs.
- **The brink:** with the Quarry Rod at level 10, a perfect-reflex bot lands
  difficulty 1.134 half the time.
- **Harder, 2026-10-11** (owner: *"make the fishing harder"*, *"close calls"*):
  - the ★★★★★ fish sits at the brink's cap, 1.077;
  - the ★ fish is 0.15;
  - the grades between step up geometrically.
  - Tuning every grade to a catch rate instead made the small fish minute-long
    fights, so only the top is tuned to a rate.
- **How a human-like bot does** (233 ms reactions, a shaky read of the bar):

  | rod | ★ | ★★ | ★★★ | ★★★★ | ★★★★½ | ★★★★★ |
  |---|---|---|---|---|---|---|
  | Twig L0 | 98% · 15 s | 84% · 20 s | 66% · 36 s | 26% | 1% | 0% |
  | Quarry L10 | 100% | 100% | 98% · 20 s | 76% · 48 s | 63% | 42% · 2½ min |
  | Deepline L30 | 100% | 100% | 100% | 100% | 99% | 85% · 50 s |

The full table is in `docs/FISHING-TUNING.md`. `tools/verify/fishing.js` checks
that `MineFishing.DIFFICULTY` is the row the machine printed.

**Two findings from tuning.**
1. With every fish of a grade identical, the catch rate fell off a cliff:
   always caught or never.
2. Tuning the common fish to "almost always" then made them minute-long fights.

Letting a fish's size set its fight fixed both.

## Decided by the owner (2026-10-10/11)
- The first spot is in zone 2. Every zone gets "a couple underground fishing
  areas … (at outposts)": the 1,000 and 3,000 station bays. Each zone has its own
  fish. *"make rare fish actually rare"*.
- **Bait is not a coin sink any more.** Rods are: *"make the rods cost coins, but
  make the bait need to be afked for or claimed from quests or bought with tokens
  (max amount of bait per dsy)"*. This supersedes TODO §0 "bait costs coins".
- Bait numbers: 15 a day; AFK 1 per 8 min, quests +2, 10 tokens each.
- Tokens are temper tokens ([ambiguous-terms](../ambiguous-terms.md)).
- Rods: 4 rods and 50 levels at ×1.6, with a token prestige every 10. Levels stay
  through rebirth. One rod casts 5 bait.
- Cast and reel are both minigames, and **no skipping**. The colour, tension, floor
  and escape rules are quoted in `MineFishingFight`'s header.
- Catches are fish cards in a cooler. First cut: selling waited (owner: *"just
  make it give fish cards for now"*). **2026-10-13:** cooler sells for coins;
  trading still waits.

## State right now
- **Built and play-tested in Studio on the Greyvein pond** (first cut): cast → bite →
  fight → result, the catch cards, the cooler, buying bait with tokens, buying and
  levelling a rod.
- **The pond view and the harder fight were played in Studio on 2026-10-12** on the
  Quarry Pool (the owner's profile). Open, CAST with the half-circle gauge, the bite,
  and REEL with the tension ring all work, with no console errors.
  - **Fixed then:** the bobber landed under the dock (0 m was the rim), and the
    tutorial card covered the gauge.
  - **Still to judge:** the marker itself. It is on, on top and on screen, but
    Studio's screenshots do not draw in-world labels, so nobody has seen it yet.
    With the default camera, the far end of the pool sits near the right-hand
    button column; turning the camera toward the pool while fishing would help
    (not built).
- **Not yet seen in Studio:** the underground pools. They build only when a seam's
  plaza opens.
- **All ten permanent zones have fish lists** (meadow → primordium). Listing a
  zone in `MineFishing.FISH` also registers its 1,000 / 3,000 outpost spots, so
  `MineDepthPlazas` builds those pools when the seam opens. Only Greyvein has a
  surface pond. Event Horizon still needs a list if it should fish.
- **DONE 2026-10-13:** cooler sell for coins; catch of the day on TODAY + FISH
  tab (global UTC target, coins claim).
- **DONE 2026-10-13 (rod + bobber):** procedural hand rod + cork bobber in
  `MineFishingView.rigFx` (Studio Play on Quarry Pool: wood shaft welded to
  `RightHand`, cork lands on pond surface, Beam line on, cork stays visible
  through the fight). Older stub used a classic Weld C0 without posing world
  CFrame first and hid the cork on bite (`Transparency = 1`), so it read as
  "not built".
- **DONE 2026-10-13:** album set bonuses (cooler known = album; per-zone 12-fish
  sets; PROPOSED +2% at 3/12, +5% at 12/12 on that zone's spots; FISH + COOLER
  progress).
- **Not built:**
  - fish trading;
  - fish art (cards use 🐟).
- **PROPOSED, for the owner:** rod prices, starter bait, fish names (all zones),
  `ZONE_DIFFICULTY` multipliers, the 9 grade odds, the tuning targets, sell
  prices (`SELL_BASE` 120 / `SELL_GROW` 2.8), catch-of-day rewards
  (`CATCH_OF_DAY_BASE` 2500), and album luck
  (`ALBUM_MILESTONE_LUCK` 0.02 / `ALBUM_COMPLETE_LUCK` 0.05).

## Gotchas
- **Fight determinism.** The fight must stay `+ - * /` and its own generator.
  `math.log`, `Random` or anything platform-dependent would let the client's
  fight and the server's replay disagree.
- **When the tuning goes stale.** Changing `MineFishingFight` or the rods
  invalidates the tuning. Rerun `fishing-tune.js` (about 2 minutes) and paste
  its row.
