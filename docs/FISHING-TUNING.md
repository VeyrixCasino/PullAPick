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
   of difficulty **0.951** half the time. Anything harder is out of reach.
3. **Toned down.** The ★★★★★ fish is set where the human-like bot (below) with the
   reference rod lands it 35% of the time, and never past 0.95 × the brink. The ★
   fish is 0.08, a quick sure catch, and the grades between step up geometrically.
   A fish's fight also follows its size (`MineFishingFight.spiritOf`), so every cell
   below averages small and big catches as they are rolled. PROPOSED numbers. The row
   for `MineFishing.DIFFICULTY`:

   `{ 0.080, 0.108, 0.147, 0.199, 0.269, 0.364, 0.493, 0.667, 0.903 }`

4. Measured each grade with each rod, for the expert bot and a HUMAN-like bot (it
   reacts 7 ticks late, about 233 ms, and reads the tension bar ±0.06;
   also trained). Cells are catch rate · mean seconds to land.

## Human-like bot

| grade | difficulty | twig L0 | twig L10 | quarry L10 | quarry L20 | deepline L30 | trawler L50 |
|---|---|---|---|---|---|---|---|
| ★ | 0.080 | 100% · 14s | 100% · 10s | 100% · 8s | 100% · 7s | 100% · 5s | 100% · 3s |
| ★½ | 0.108 | 100% · 15s | 100% · 11s | 100% · 9s | 100% · 7s | 100% · 5s | 100% · 4s |
| ★★ | 0.147 | 100% · 17s | 100% · 12s | 100% · 9s | 100% · 8s | 100% · 5s | 100% · 4s |
| ★★½ | 0.199 | 100% · 20s | 100% · 14s | 100% · 11s | 100% · 8s | 100% · 6s | 100% · 4s |
| ★★★ | 0.269 | 100% · 25s | 100% · 17s | 100% · 13s | 100% · 10s | 100% · 7s | 100% · 5s |
| ★★★½ | 0.364 | 98% · 35s | 100% · 23s | 100% · 17s | 100% · 13s | 100% · 8s | 100% · 5s |
| ★★★★ | 0.493 | 84% · 51s | 99% · 39s | 100% · 26s | 100% · 18s | 100% · 11s | 100% · 7s |
| ★★★★½ | 0.667 | 62% · 88s | 81% · 63s | 90% · 46s | 97% · 35s | 99% · 18s | 100% · 10s |
| ★★★★★ | 0.903 | 19% · 186s | 41% · 120s | 55% · 89s | 66% · 64s | 84% · 34s | 95% · 19s |

## Perfect-reflex bot

| grade | difficulty | twig L0 | twig L10 | quarry L10 | quarry L20 | deepline L30 | trawler L50 |
|---|---|---|---|---|---|---|---|
| ★ | 0.080 | 100% · 13s | 100% · 10s | 100% · 8s | 100% · 6s | 100% · 5s | 100% · 3s |
| ★½ | 0.108 | 100% · 14s | 100% · 11s | 100% · 8s | 100% · 7s | 100% · 5s | 100% · 4s |
| ★★ | 0.147 | 100% · 15s | 100% · 12s | 100% · 9s | 100% · 7s | 100% · 5s | 100% · 4s |
| ★★½ | 0.199 | 100% · 18s | 100% · 13s | 100% · 10s | 100% · 8s | 100% · 6s | 100% · 4s |
| ★★★ | 0.269 | 100% · 22s | 100% · 16s | 100% · 12s | 100% · 9s | 100% · 6s | 100% · 4s |
| ★★★½ | 0.364 | 100% · 31s | 100% · 21s | 100% · 16s | 100% · 12s | 100% · 8s | 100% · 5s |
| ★★★★ | 0.493 | 99% · 53s | 100% · 35s | 100% · 23s | 100% · 17s | 100% · 10s | 100% · 7s |
| ★★★★½ | 0.667 | 78% · 86s | 86% · 60s | 93% · 44s | 96% · 32s | 100% · 18s | 100% · 10s |
| ★★★★★ | 0.903 | 29% · 156s | 47% · 114s | 59% · 82s | 65% · 56s | 86% · 33s | 96% · 19s |

Took 98 s.
