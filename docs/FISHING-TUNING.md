# Fishing tuning (generated)

Written by `node tools/sim/fishing-tune.js` on 2026-10-11.
Do not hand-edit; rerun it after touching `MineFishingFight` or the rods.

Owner, 2026-10-10: *"test with a little shitty learning machine, and figure out whats
the brink of possibility, and tone down from there"*.

## What it did

1. Trained a bot (cross-entropy method over a small policy: the tension to allow
   on green, yellow and red, a hysteresis, when to panic about distance, and a tap
   rhythm for runs) on the real `MineFishingFight`, run in luau.
2. **The brink.** With the quarry_rod at level 10, a perfect-reflex bot lands a fish
   of difficulty **1.134** half the time. Anything harder is out of reach.
3. **Toned down.** The ★★★★★ fish is set where the human-like bot (below) with the
   reference rod lands it 22% of the time (owner: "make the fishing harder"),
   never past 0.95 × the brink. The ★ fish is 0.15, and the grades step up
   geometrically between, which keeps the small fish short.
   A fish's fight also follows its size (`MineFishingFight.spiritOf`), so every cell
   below averages small and big catches as they are rolled. PROPOSED numbers. The row
   for `MineFishing.DIFFICULTY`:

   `{ 0.150, 0.192, 0.246, 0.314, 0.402, 0.514, 0.658, 0.842, 1.077 }`

4. Measured each grade with each rod, for the expert bot and a HUMAN-like bot (it
   reacts 7 ticks late, about 233 ms, and reads the tension bar ±0.06;
   also trained). Cells are catch rate · mean seconds to land.

## Human-like bot

| grade | difficulty | twig L0 | twig L10 | quarry L10 | quarry L20 | deepline L30 | trawler L50 |
|---|---|---|---|---|---|---|---|
| ★ | 0.150 | 98% · 15s | 100% · 11s | 100% · 8s | 100% · 6s | 100% · 4s | 100% · 3s |
| ★½ | 0.192 | 93% · 17s | 100% · 13s | 100% · 9s | 100% · 7s | 100% · 4s | 100% · 3s |
| ★★ | 0.246 | 84% · 20s | 99% · 16s | 100% · 11s | 100% · 8s | 100% · 5s | 100% · 3s |
| ★★½ | 0.314 | 76% · 26s | 94% · 21s | 100% · 15s | 100% · 10s | 100% · 6s | 100% · 4s |
| ★★★ | 0.402 | 66% · 36s | 86% · 27s | 98% · 20s | 100% · 13s | 100% · 7s | 100% · 4s |
| ★★★½ | 0.514 | 49% · 72s | 71% · 42s | 92% · 31s | 100% · 21s | 100% · 10s | 100% · 5s |
| ★★★★ | 0.658 | 26% · 170s | 57% · 87s | 76% · 48s | 92% · 33s | 100% · 16s | 100% · 7s |
| ★★★★½ | 0.842 | 1% · 162s | 37% · 149s | 63% · 88s | 77% · 59s | 99% · 29s | 100% · 12s |
| ★★★★★ | 1.077 | 0% · 0s | 10% · 222s | 42% · 158s | 60% · 104s | 85% · 50s | 100% · 22s |

## Perfect-reflex bot

| grade | difficulty | twig L0 | twig L10 | quarry L10 | quarry L20 | deepline L30 | trawler L50 |
|---|---|---|---|---|---|---|---|
| ★ | 0.150 | 100% · 14s | 100% · 10s | 100% · 7s | 100% · 6s | 100% · 4s | 100% · 3s |
| ★½ | 0.192 | 100% · 18s | 100% · 12s | 100% · 8s | 100% · 6s | 100% · 4s | 100% · 3s |
| ★★ | 0.246 | 100% · 23s | 100% · 14s | 100% · 10s | 100% · 7s | 100% · 5s | 100% · 3s |
| ★★½ | 0.314 | 100% · 34s | 100% · 19s | 100% · 13s | 100% · 9s | 100% · 5s | 100% · 4s |
| ★★★ | 0.402 | 100% · 64s | 100% · 31s | 100% · 18s | 100% · 12s | 100% · 6s | 100% · 4s |
| ★★★½ | 0.514 | 89% · 187s | 100% · 83s | 100% · 32s | 100% · 20s | 100% · 9s | 100% · 5s |
| ★★★★ | 0.658 | 56% · 261s | 86% · 150s | 100% · 64s | 100% · 35s | 100% · 15s | 100% · 7s |
| ★★★★½ | 0.842 | 34% · 490s | 70% · 215s | 86% · 108s | 92% · 65s | 100% · 28s | 100% · 11s |
| ★★★★★ | 1.077 | 6% · 697s | 43% · 289s | 58% · 154s | 68% · 102s | 88% · 49s | 100% · 20s |

Took 219 s.
