# Balance pass: damage curve, level cap, and the zone gate

Paste this as the PR body. Open the PR here:
<https://github.com/VeyrixCasino/PullAPick/compare/main...claude/vigilant-fermi-aucqjy>

---

Six things the owner asked for, and the structural bugs found underneath each.
The one blocker this branch opened with — that 53 of 82 ores could never spawn —
is closed; see §4.

## 1. Levelling stopped mattering at level 34

Damage and HP were never on the same scale:

| | span |
| --- | --- |
| block HP, surface to the Event Horizon floor | ×1.0e10 |
| damage, tier 1 L1 to tier 82 L100 | ×9.9e16 |

Damage outran content by about ten million to one, so a tool one-shot its own
seam around level 34 and the remaining two thirds of the ladder changed nothing
a player could see.

**`TOOL_CLIMB_DAMAGE` 3.9e8 → 350.** Measured, not fitted: it is the HP growth
across one zone's 5,000 layers (`20 + 1.5×L`, so 21.5 → 7,520), which is the span
a tool's own levelling has to cover. A full climb is now worth exactly one zone
of depth instead of 222× past the bottom of the mine.

**`toolTierPower` divided by a hardcoded 120.** That was `#ORES-1` when the roster
held 121 ores; at 82 the exponent only travelled 81/120 of its range, so
`TOOL_TIER_SPAN = 16` delivered 6^10.8 and the top of the roster was short by a
factor of 11,000. It reads `ORE_COUNT` now.

**`TOOL_TIER_SPAN` 16 → 7.** Fixing the divisor *alone makes it worse* — it hands
the overshoot to tier instead of level and the live-level count drops from 23 to
8 out of 100. 7 and not 10 because two multipliers sit above this constant that
the first pass missed: the Frack type is ×4 and the Exotic band step is ×16, so
the top of the ladder carries ×64 the constant does not show. `check.js` caught
it — the best tool was 90× over the deepest rock.

**`TOOL_BAND_DMG`, new.** The reason tier 60+ felt pointless is structural:
`ORE_REACH` is 15 and the roster ends at 82, so a tier-67 tool already reaches
every ore in the game. Tiers 68–82 are access-identical by construction. Damage
has to carry them, and a smooth exponential spreads them at 13% a tier. The four
bands above 60 now take a step on top of the curve — Legendary ×2, Mythic ×4,
Divine ×8, Exotic ×16.

Result, measured per tier at the depth each ore spawns: levels that still change
a swing count go from **24–30 per band to 96–100**. Tier 60 → 82 at max level
goes from ×192 to ×483.

## 2. "Something I could advertise — each level UP %X"

The per-level number is arithmetic: `TOOL_CLIMB_DAMAGE ^ (1/(TOOL_MAX_LEVEL-1))`.
At climb 350 over 99 steps that is **+6.1%**, which is not a number anyone puts
on a button. The climb cannot grow — it is pinned to one zone's HP growth, and
`check.js` refuses a maxed tool that trivialises the deepest rock. So the only
lever is fewer levels.

**`TOOL_MAX_LEVEL` 100 → 30.** This is the move the config was written for: every
per-level rate comes out of `perLevel()`, so one line restretches all three and
**neither end point moves**. A maxed tool is exactly as strong as before.

| | cap 100 | cap 30 |
| --- | --- | --- |
| per level | +6.1% | **+22.4%** |
| ore for a full climb | 89.2K | 23.8K |
| hours at 10 blocks/s | **45.1** | **12.0** |
| levels that still change a swing count | 99% | **99%** |

Shortening the ladder cost nothing in whether levelling matters.

It is now on the two panels where a player actually spends — `MineForge` (build a
tool, then level it) and `MineBenchView` — leading the cost line with the gain:

```
+22% damage  ·  51 Topaz  ·  315 dust
held  1.2K  ·  4.0K
```

Both read `C.TOOL_DMG_STEP` rather than writing the number out, so a cap change
moves the forge with it.

## 3. Breaking power now gates the zone

The owner's premise was half right and the half that was wrong was the important
one. **A stone pick could never reach depth 1000** — it caps at layer 50. Depth
*inside* a mine was already gated hard.

What was broken was the **zone**. `ZONE_STEP` was 1, so stepping from Dirt Meadow
to Event Horizon cost one rung while HP multiplies ×5 a zone. At layer 2500 that
was tier 41 vs tier 44 — **three tiers for ×9.77 million HP**. And zone 1 alone
demanded tier 57 of 82, leaving nine zones to share three tiers.

Three dials: `ZONE_STEP` 1 → 100 (a zone is worth one mine's depth), `ORE_POW`
2.0 → 1.0 (quadratic made the bottom half of the roster worth almost no power),
`MAX_LAYER` 10000 → 5000 (it fed only the `MAX` derivation and read 10000 while
`MineConfig.LAYERS` exports 5000, so the ladder pointed 100 rungs past anything
reachable).

| zone | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| enter | t1 | t10 | t18 | t26 | t34 | t42 | t50 | t58 | t66 | t74 |
| finish | t9 | t18 | t26 | t34 | t42 | t50 | t58 | t66 | t74 | **t82** |

Finishing a mine *is* entering the next, eight tiers apiece, tier 82 landing
exactly on zone 10's floor. Event Horizon sits off this ladder — it does not use
ore tools.

**The owner's two statements on `ZONE_STEP` do not agree**, and the disagreement
is recorded at the constant rather than buried. "unlocking zone 3 is like zone 1
3 down (1000) … zone 10 would be 9 down" is `ZONE_STEP` 10; "a new pick from next
zone to come back to 501-1000 depth" read as a zone being worth a whole mine is
100. 100 was chosen on the zone-1 figure (11% of the roster vs 60%, continuous vs
a 33-tier jump). One line to change back.

Failing the gate is **a hard block, not a barrier**: nothing gates where a player
may walk, and `canBreak` false means the swing lands for zero on that block.

## 4. The ore ladder was calibrated to a curve that no longer exists

Found while verifying the new gate is climbable. **Pre-existing, not caused by
anything else here**, but the new gate made it load-bearing.

`MineConfig` derived `ORE_DMAX` from `Depth.SECTIONS`' **last row** — Terminus,
`dirtHp = 9.30735e+18`. `SECTIONS` is the retired HP table; `MineDepth.dirtHp`
does not read it and tops out at **14,687,500,000**. SECTIONS' top is ~1.2
quadrillion times the deepest block a player can hit.

So the ore d-ladder ran 0 → 32.09 while the deepest `oreDifficulty` in the game
is **11.39**. Measured against the live module: at the deepest point in the game
**62 of 82 ores rolled under 0.05%**, the hardest ore appearing anywhere was tier
26, and **the forge ladder deadlocked at tier 8** — nobody could climb past it.
The old gate wanted tier 60 at the mine floor and could not get it either.

Anchored to the live curve instead, at the deepest *normal* mine (Event Horizon
is not on the ore-tool ladder) minus a margin:

```
ORE_LADDER_ZONES = 10
ORE_DMAX_MARGIN  = 0.4
ORE_DMAX = oreDifficulty(10, LAYERS) - MARGIN = 10.9936
```

The margin is the whole balance, and it is a tug-of-war — climbability pulls it
down, rarity pushes it up:

| margin | Exotic at the deepest spot | forge ladder |
| --- | --- | --- |
| 0.0 | 0.08% | stalls at t75 |
| **0.4** | **0.17%** | **completes to t82** |
| 2.4 | 3.59% | completes to t82 |
| 4.2 | 21.7% | completes — and is the 2026-10-04 mistake, an exotic a minute |

0.4 is the largest margin inside the owner's 0.02–0.2% band that still lets the
ladder finish. The forge walk now completes:
`1 → 16 → 31 → 44 → 53 → 61 → 68 → 73 → 77 → 81 → 82`.

## 5. Every rarity is possible in every zone

Owner: *"every rarity should be POSSIBLE in every zone, just super highly
unlikely (even 1 in a million zone one)."* It was not unlikely, it was
impossible — the logistic put Oganesson at 3e-11 in Dirt Meadow, one find per
187,000 years.

`ORE_MIN_SHARE = 1e-6`, applied **after** the natural total is known, as a
minimum share of the roll, **and as a fixed point** — lifting ore raises the
total, which raises the floor, so a single pass lands each ore at
`minShare × totBefore/totAfter`, which differs by depth. Iterating puts every
floored ore on exactly `ORE_MIN_SHARE`.

That flatness is what makes it monotonic, which was the second bug: flooring the
raw *weight* made the top ore 1 in 985k at zone 1 but 1 in 4.3M at zone 5 — a long
shot that got *longer* as you dug.

| zone | 1–6 | 7 | 8 | 9 | 10 |
| --- | --- | --- | --- | --- | --- |
| Oganesson | **1 in 1,000,000** | 1 in 809,273 | 1 in 109,965 | 1 in 14,938 | 1 in 2,281 |

Impossible ore/zone combinations: **0**. Zone 10 Exotic band: **0.173%**,
unchanged by the floor. A gentler `ORE_K` would reach the same odds and drag the
whole distribution with it — zone 10 falls from 55% Epic to 52% Rare — whereas
the floor only lifts what was already beneath it.

## Harnesses

Every existing damage check reimplemented the formula in JS and none executed it.

- **`verify/damage-curve.js`** — asserts both asks against the live constants,
  including the type multiplier the first version missed.
- **`verify/dmg-live.js`** — runs the real `toolTierPower` through `luau.exe`,
  slices kept in file order, because it now calls `ORE_COUNT` and
  `oreBandForTier` declared ~500 lines further down.
- **`verify/ladder-climbable.js`** — guards both ends of §4 and §5 at once: the
  forge ladder must reach tier 82, the Exotic band must stay between 0.002% and
  0.2% at the deepest spot, every ore must be able to roll in every zone, and the
  top ore must never get *rarer* with depth. It prints the per-zone curve on every
  run, because its own first pass after the monotonicity fix still reported the
  bug — an earlier edit to strip its stale in-loop floor had silently failed to
  match, so it was modelling the broken version and agreeing with the broken game.

Three harnesses were passing **vacuously** and are fixed:

- `verify/breaking.js` pinned the four dials as literals *and* derived `MAX` from
  its own copy, so when the dials moved, "the top ore reaches the mine floor"
  compared 209 against 209 and passed. Reads live now and asserts relationships.
- `verify/check.js` read the upgrade calculator, whose `dmgStep` sat at `1.02` —
  the rate for a **1000-level** cap — while the game has been at 100. The page
  showed a full climb as 7.1× while the game applied 3.9e8. The generator derives
  the damage constants now.
- `verify/minemap-runs.js` only asserted sliders with `>` bounds, which is why a
  hardcoded `max="100"` sailed through against a cap of 30. It asserts equality.

## Chart pages

- `mine-map` read **`SECTIONS[].dirtHp`** for block HP — the retired table, which
  put Finalite at 1.64 trillion where the live curve gives 7,520. Every swing
  count on that page came off it.
- Its verdict judged on `ORE_REACH` alone and never on depth, so it told a tier-1
  pick it "reaches the ore" at layer 992. It runs the whole gate now.
- The upgrade calculator's ladder built rows with `for(h=100;h<=1000;h+=100)` —
  at a cap of 30 every row was out of range and **the table came out empty**.
- Its generated caption was a one-shot replace that froze at "level cap 100".

## Merge

The other agent's three commits touched the same dials. Resolved with the owner:
kept this side's `ZONE_STEP`/`ORE_POW`/`MAX_LAYER`, took their `ORE_REACH_HOME = 5`
and `reachFor()` (reach is tight in the zone you stand in, full once you have
unlocked the one above), plus their docs, forge-ladder walker and extra
assertions.

## Verified in Studio, not just by harness

Rojo 7.7.0 serving; `MineConfig`, `MineForge`, `MineBenchView`, `MineBreaking` all
require cleanly. `TOOL_MAX_LEVEL=30`, `CLIMB=350`, `SPAN=7`,
`TOOL_DMG_STEP=1.223845` → the advertised +22%, `toolPower(82, max, 4)` =
`6.27057e+10` — the same figure `check.js` and `dmg-live.js` assert.
`canBreak(stone, zone 1, layer 1000)` = **false**, layer 50 = **true**.

`suite.sh`: **26 passed**. `procs`, `zones` and `trap` fail as they did before this
branch and are untouched by it — all three are harness bugs rather than balance
problems; see **Still open**.

One note on verifying in Studio: `require()` caches per ModuleScript **instance**,
so a Rojo source update does not invalidate a module already required that
session. Three probes came back stale before the module was cloned and required
fresh. Worth knowing before trusting any in-Studio reading taken after an edit.

## 6. Forging up was a downgrade at every tier

`craftOreTool` built the tool row with `level = 1`, so a freshly forged
tier-(T+1) tool was **×0.003** of the maxed tier-T tool already in your hand and
had to be levelled to 30 of 30 just to break even — at every tier, all the way up
the roster.

It is not tunable. A fresh tool only wins if **one tier step is worth a whole
climb**, and with 81 tier steps inside the damage budget the best possible case is
`tierStep == climb == ×1.265`, which makes levelling a tool worth nothing at all.
The roster being 82 long is what forces the step small, so the fix has to be
mechanical rather than numerical.

A forged tool now inherits the best level on the rack:

| | at level 1 | inheriting |
| --- | --- | --- |
| tier 40 → 41 | ×0.0033 | **×1.1675** |
| at a band border (60 → 61) | ×0.0067 | **×2.335** |

Inherited from the *best* tool rather than one of the same family, because those
levels were paid for in ore and dust once and the player does not owe them again
for choosing a different frame. This recasts the two axes rather than softening a
number: **levels are an early ramp you climb once and keep, tier is the
progression** — which is already how `ORE_REACH` and the breaking gate treat the
game.

### The cap migration needed its own stamp

The roster migration clamps over-cap levels but is gated on `ORE_ROSTER_V` and
runs **once**. Every profile stamped while `TOOL_MAX_LEVEL` was 100 never
re-enters it, and the cap is 30 now — those saves still hold tools stored at
level 80. `clampLevel` makes them *behave* as 30 wherever damage is computed, so
nothing is broken, but the stored number is a lie and the bench shows a level the
game will not honour. `MineConfig.TOOL_CAP_V` + `p.toolCapV` fixes that,
separately from the roster stamp because the two move for different reasons.

**A pre-existing bug found doing it:** the roster migration's refund has never
paid out a single ore. It computes `toolSpent(saved) − toolSpent(cap)`, and
`MineConfig.toolSpent` runs its level through `clampLevel` — so once the saved
level is over the cap both terms are identical and the difference is always zero.
Dead since it was written, in every case it exists for.

It cannot be repaired by unclamping either: `TOOL_CLIMB_ORE` and
`TOOL_CLIMB_DUST` are restretched by `perLevel()` whenever the cap moves, so the
series that priced level 80 when it was bought no longer exists anywhere in the
config. What a player actually spent is not recoverable from the save. So the new
migration does not pretend to refund — and clamping is its own compensation,
because on this curve the cap **is** the full ×350 climb: a tool comes back
**maxed**, skipping the whole ~12-hour climb.

`verify/forge-upgrade.js` asserts the mechanism stays wired — it is one line in a
15,000-line server file — and keeps the level-1 counterfactual in its output so
the number justifying the change lives in the harness, not only in a commit
message.

## Still open

- `zones.js` validates `upgrade-calculator.html`'s zone panel, which still runs
  the **retired** depth and ore models: `ORE_SPACING = 0.2674` (121 ores over
  D 0–32.09) against a live `ORE_DMAX/(NORE-1)` of 0.13572, `DMAX = 23.41`
  against a live 10.9936, zone HP as `20 × 6^(d+zone−1)` against a live
  `(20 + 1.5·L) × 5^(zone−1)`, and no `ORE_MIN_SHARE` floor. Same class of bug
  already fixed in the mine map; the page's logistic and its `oreX0/K/S/W`
  defaults are already correct, so only the inputs need syncing.
- `trap.js` crashes before asserting anything: it exports `toolLevel` out of the
  calculator and that function no longer exists.
- `procs.js` asserts `hops <= 8` and `fall < 0.85`; the live values are 16 and
  0.89, both set deliberately. The thresholds are stale, not the game.
