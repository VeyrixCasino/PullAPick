# What has already been tried, and how it failed

Read this before proposing a redesign. Every item below was built, verified against
a passing assert suite, and turned out wrong anyway. The point is not the list —
it is the *pattern*, which is at the bottom.

---

## 1. Ore tier wired to tool damage

**What:** tool power anchored to the ore's tier, so a deeper ore made a stronger
tool.

**Why it failed:** ore is found by depth, depth is ungated, so ore power ignored
the prestige ladder entirely. A Meadow player at L2500 out-damaged the zone's best
shop tool by **561×**. This is the root cause of "numbers off the screen by minute
30" and of the bootstrap loop.

**Lesson:** `PRINCIPLES.md` §1 and §2.

---

## 2. Hours-to-max as the cost anchor

**What:** upgrade costs derived from `hoursToMax(rank)` — 40h Common to 80h
Exotic — times the ore's supply per hour.

**Why it failed:** it tunes the game around its own ceiling. Maxing is not what the
game is about, and the owner said so directly. Worse, it made every other number
downstream of a figure nobody should care about: `totalOre`, per-level costs, the
dust-only stretches all inherited it.

Measured afterwards: levelling is worth **36×** over 99 levels; *finding* the ore is
worth **500×**. The entire cost model was tuning the smaller lever.

**Lesson:** design for the first hour and the hundredth, not the ceiling. If a
number's justification starts "so that time-to-max lands on…", it is the wrong
number.

---

## 3. Band weights to make rare bands rare

**What:** `ORE_BAND_WEIGHT` — a per-band multiplier on spawn weight, because the
depth curve alone could not make Legendary+ rare enough.

**Why it failed:** it created a **14.7× discontinuity** between Epic and Legendary
while every other band step was 1.0–1.5×. Since costs were priced in supply, the
totals inherited the cliff: 63,001 ore for an Epic tool, 3,138 for a Legendary,
49 for an Exotic. The owner's reaction — *"why did everything drop off so fuckin
fast"* — was reading that cliff directly.

**Lesson:** a multiplier added at one point in a smooth curve puts a step in it.
If you need a band to be rarer, change the curve, not one band's coefficient.

---

## 4. Clamping the power anchor to reachable rock

**What:** `oreHomeHp` clamped each ore's anchor to the deepest hardness a main zone
reaches (19.14), so tools were not sized for rock that does not exist.

**Why it failed:** every ore above that hardness got the **same** anchor — tiers 57
to 82, **26 ores, a quarter of the roster, producing byte-identical tools.**
Oganesson and Ruby made the same pick to the digit. The clamp was locally
reasonable and globally destroyed the top half of the content.

**Lesson:** when you clamp, check what lands on the clamp. A clamp that catches one
value is a guard; a clamp that catches a quarter of your data is a redesign in
disguise.

---

## 5. Capping the ceiling to fit a float

**What:** `ORE_POWER_TOP = 16.4`, chosen so the strongest possible tool stayed
under 2⁵³.

**Why it failed:** it let a representation limit make a balance decision. The
owner's response was correct — a mantissa/exponent number type removes the
constraint, so the constant should never have been a design value.

**Lesson:** `PRINCIPLES.md` §6. Fix the representation, do not shrink the game.

---

## 6. Asserts that passed while testing nothing

Two of the verification checks were written wrong in ways that made them
vacuously true:

- **"Ore cost must never decrease per level."** Fires on every ore, because
  flooring a series whose true per-level cost is a fraction legitimately yields
  0, 1, 0, 1, 1 — which the brief explicitly wanted. The assert was fighting the
  intended behaviour.
- **"Last ten levels cost ≥50× the first ten."** Divides by `max(1, first)` where
  `first` is 0, so it measured absolute cost, not a ratio.

And in the generator guard, a drift check asked whether the doc was *missing* the
old ore id rather than whether it *had* it — so it never fired on the 121-row table
it existed to protect. Caught only by testing it against a second input.

**Lesson:** an assert that has never failed has not been tested. Feed each one an
input you know is bad and watch it fail before you trust a PASS.

---

## The pattern

Eighteen tuning dials now sit in the ore system. Eight existed; ten were added
during one redesign:

```
ORE_PEAK_OFFSET   ORE_BAND_WEIGHT   ORE_EXOTIC_OFF_ZONE   ZONE_ORE_SHIFT
ORE_POWER_TOP     ORE_PACK_FIND_CAP TOOL_POWER_START      TOOL_HOURS_BASE
TOOL_HOURS_SPAN   ORE_RATE_STRONG
```

**Every one was added to satisfy an assert rather than to improve play.** The brief
said "do not stop until every assert passes", so each time the shape did not fit,
a term was added instead of the shape being questioned. `ORE_PEAK_OFFSET` because
the curve peaked in the wrong place. `ORE_BAND_WEIGHT` because the curve could not
make bands rare enough. `ORE_EXOTIC_OFF_ZONE` because the weights could not gate by
zone. `ORE_POWER_TOP` because a float ran out of bits.

The result is a machine where moving one dial shifts four things you did not
intend — which is why items 3, 4 and 6 above were all discovered *after* the suite
reported PASS. That is not bad luck. It is what eighteen coupled parameters do.

**The failure mode to avoid is not a wrong number. It is optimising against a
specification instead of against the game.** A passing assert suite is evidence
that you satisfied the brief, and no evidence at all that the game is good. When
the two diverge, the brief is wrong.
