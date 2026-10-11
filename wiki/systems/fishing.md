---
title: Fishing
type: system
status: partial
verified: 2026-10-11 @ 9b160ef
sources:
  - src/ReplicatedStorage/Mine/Shared/MineFishing.luau
  - src/ReplicatedStorage/Mine/Shared/MineFishingFight.luau
  - src/ReplicatedStorage/Mine/Shared/MineFishingView.luau
  - src/ServerScriptService/Mine/MineFishingService.luau
  - src/ServerScriptService/Mine/MineFishPonds.luau
  - src/ServerScriptService/Mine/WorldBuilder.luau
  - src/ServerScriptService/Mine/MineDepthPlazas.luau
  - tools/sim/fishing-tune.js
  - tools/verify/fishing.js
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

**Fish.** Each zone has its own list (`MineFishing.FISH`). Greyvein has 12, from
★ to ★★★★★ in half steps, Gravel Minnow to Monolith Koi. Before luck, the odds
(`GRADE_WEIGHT`) are:

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
  - a rod at your side, and a line (a Beam) that sags when slack and pulls straight
    and reddens as the tension climbs;
  - the cast throws a bobber out along an arc, further for more power;
  - the bite splashes;
  - the **fish marker** is a 🐟 bubble in the fish's colour, with the distance
    under it. It swims the pool: toward the far rim as it gets away (100 m = the
    rim), side to side, harder when it runs.
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
(the COOLER tab). Selling, trading and album set bonuses are not built
(owner: *"just make it give fish cards for now"*).

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
- Catches are fish cards in a cooler. Selling waits.

## State right now
- **Built and play-tested in Studio on the Greyvein pond** (first cut): cast → bite →
  fight → result, the catch cards, the cooler, buying bait with tokens, buying and
  levelling a rod.
- **The pond view and the harder fight (2026-10-11) compile and pass
  `tools/verify/fishing.js`, but have not been played yet.** Studio was in use by
  another session. Things to look at first: the rod's angle at your side, and
  whether the marker reads well from the dock.
- **Not yet seen in Studio:** the underground pools. They build only when a seam's
  plaza opens.
- **Only Greyvein has fish.** Other zones need their own lists in
  `MineFishing.FISH` (and `ZONE_DIFFICULTY`) before their outposts get pools.
- **Not built:**
  - fish selling and trading;
  - album set bonuses;
  - TODAY's "catch of the day";
  - a rod model in the hand and a bobber on the water;
  - fish art (cards use 🐟).
- **PROPOSED, for the owner:** rod prices, starter bait, fish names, the 9 grade
  odds and the tuning targets.

## Gotchas
- **Fight determinism.** The fight must stay `+ - * /` and its own generator.
  `math.log`, `Random` or anything platform-dependent would let the client's
  fight and the server's replay disagree.
- **When the tuning goes stale.** Changing `MineFishingFight` or the rods
  invalidates the tuning. Rerun `fishing-tune.js` (about 2 minutes) and paste
  its row.
