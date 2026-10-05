# Balance pass: damage curve, level cap, and the zone gate

Paste this as the PR body. Open the PR here:
<https://github.com/VeyrixCasino/PullAPick/compare/main...claude/vigilant-fermi-aucqjy>

---

Three things the owner asked for, one structural bug found on the way, and one
blocker that has to be cleared before this is safe to ship.

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

## 🚨 Blocker: 53 of 82 ores never spawn

Found while verifying the new ladder is climbable. **This is pre-existing and not
caused by anything here**, but the new ladder makes it load-bearing.

`MineConfig` derives `ORE_DMAX` from `Depth.SECTIONS`' **last row** — Terminus,
`dirtHp = 9.30735e+18`. But `SECTIONS` is the retired HP table; `MineDepth.dirtHp`
does not read it and tops out at **14,687,500,000**. SECTIONS' top is ~1.2
quadrillion times the deepest block a player can hit.

So the ore d-ladder runs 0 → 32.09 while the deepest `oreDifficulty` in the game
is **11.39**. Everything past that exists on the roster and no depth ever rolls
it. Confirmed against the live module in Studio:

```
zone  1  peak t1  (39.9%)   highest >=0.5%: t8
zone  5  peak t8  (16.6%)   highest >=0.5%: t15
zone 10  peak t19 (16.4%)   highest >=0.5%: t26

At the DEEPEST point in the game, 62 of 82 ores roll under 0.05%.
```

The old gate wanted tier 60 at the mine floor and could not get it either. The
new gate wants tier 82. **The drop tables have to be recut before this ships** —
the owner has asked for that and it is the next task.

`tools/verify/ladder-climbable.js` measures it and is in `KNOWN_FAIL` until it is
fixed. It changes nothing about spawning; it only reports.

## Harnesses

Every existing damage check reimplemented the formula in JS and none executed it.

- **`verify/damage-curve.js`** — asserts both asks against the live constants,
  including the type multiplier the first version missed.
- **`verify/dmg-live.js`** — runs the real `toolTierPower` through `luau.exe`,
  slices kept in file order, because it now calls `ORE_COUNT` and
  `oreBandForTier` declared ~500 lines further down.
- **`verify/ladder-climbable.js`** — the ore-reachability measurement above.

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

`suite.sh`: **24 passed**. `procs`, `zones` and `trap` fail as they did before this
branch; `ladder-climbable` is the known blocker above.

## Still open

- **Recut the ore drop tables** — the blocker. `ORE_DMAX` must come off the live
  depth curve, not `SECTIONS`.
- **Carry the level across the forge.** A freshly forged next-tier tool is
  **×0.003** of the maxed tool in your hand and must reach level 30 of 30 to break
  even. It is cap-independent and cannot be tuned away: a fresh tool only wins if
  one tier step is worth a whole climb, and with 81 tier steps inside the damage
  budget the best case is tier step = climb = ×1.265, which makes levelling worth
  nothing. Full inheritance is the only thing that works (×1.167).
- **Rescale saved tool levels on load** after the 100 → 30 cap change.
  `clampLevel` pins a level-80 tool to 30, which makes it *stronger* (×350 vs
  ×109) — a silent 3.2× buff to every existing tool. `round(saved / 100 * 30)`
  preserves what the player actually earned.
- `procs.js` zap assertions predate the odds-only design; `zones` ore-share is in
  the spawn area and untouched by request; `trap.js` known.
