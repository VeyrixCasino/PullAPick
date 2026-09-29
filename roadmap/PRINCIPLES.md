# Invariants

These are not preferences. Each one has already been broken in this codebase and
each break produced a specific, traceable failure. Breaking one is a bug.

---

## 1. No reward may increase your ability to obtain more of that same reward

This is the **bootstrap loop**, and it is the most expensive mistake in the game
right now.

Ore tools are found by mining. Ore tools make you mine better. Better mining
reaches deeper rock. Deeper rock holds better ore. Nothing in that circle touches
prestige, coins, or a shop:

```
find ore → stronger tool → dig deeper → find better ore → stronger tool → …
```

Block HP is the only brake, and an ore tool is precisely the thing that removes
it. The loop is self-funding, self-accelerating, and it terminates at the bottom
of the game rather than at a gate.

**Rule:** if reward X improves your rate of acquiring X, something outside the
loop must gate it. Prestige, a currency you cannot mine, a per-day cap — anything
the loop does not produce.

**Applies to:** ore tools, charms that boost ore find (see `CHARMS.md`), pets that
boost pet acquisition, luck that boosts luck.

---

## 2. Power belongs on a gated axis

This game has two progression axes. **Only one is gated.**

- **Zones** are gated by prestige: `meadow 0, sunscar 0, mistreef 1, arcwork 2,
  bloodmoon 3, eclipse 4, riftmarch 5, starfall 6, mythral 7, primordium 8`.
- **Depth is gated by nothing.** In `MineDepth.luau`, both
  `rebirthForSeam()` and `rebirthForLayer()` `return 0`, with the comment
  *"Rebirth is not a dig cap."*

Shop tool power follows zone. Ore tool power follows depth. So:

| where | best shop pick | ore pick findable there | ratio |
|---|---|---|---|
| Meadow L1 | 15 | 2 | 0.1× |
| Meadow L1500 | 15 | 2,832 | **189×** |
| Meadow L2500 | 15 | 8,408 | **561×** |
| Bloodmoon L1500 | 36,450 | 74,136 | 2× |

A player who never leaves the starter zone but digs deep beats a player who
progressed properly, by 561×. That is not a mistuned constant — it is a power
source attached to the free axis.

**Rule:** never attach power to depth while depth is ungated. Either gate depth,
or keep depth paying in things that are not power (cosmetics, collectibles,
currency, trade value).

---

## 3. An item's trade value must share a scale with its power

Trade prices ladder by rarity at about ×2.2 per step:

```
runes   Common 8 → Exotic 2,200      (275× across eight rarities)
gear    Common 12 → Exotic 3,600     (300×)
```

Ore tool power ladders **500×** across the roster, and is usable immediately by
whoever receives it.

So a veteran can hand a new player an item the pricing model calls "a few thousand
dust" that delivers hundreds of times their zone's power. The trade looks fair to
`MineTradeValue` and is catastrophic to progression. **This is the "pawning it off
to new players" problem, and it cannot be fixed with trade restrictions** — you
would be blocking individual routes forever while the mismatch keeps generating
new ones.

**Rule:** either bind price to power, or make the item not grant power. The
recommended resolution for ore is the second — see `ORE.md`.

---

## 4. Anything multiplied by the boost stack needs a cap

Boosts are multiplicative and several layers deep. From `MineServer` itself:

> *Each pet × its rune × (its hat + your hat), the three added up, × your face*

then × prestige luck, × VIP, × event pass, × rebirth skills. With 8 pet slots and
322 pets whose individual boosts reach `coinBonus 3.07`, `backpack 2.69`,
`dirtBreak 2.51`, the top of that stack is far above the middle.

**Rule:** before adding any per-block or per-pack reward, ask whether a maxed
stack multiplies it. If yes it needs an explicit cap, or it is not a reward — it
is a lever for whoever stacked hardest. `ORE_PACK_FIND_CAP` exists for exactly
this reason.

---

## 5. Sinks must be the cheapest exit

Recycling a tool returns 50% of what went in. That is a sink. But **pawning the
tool to a new player bypasses it entirely** — the item leaves one inventory
without leaving the economy.

**Rule:** a sink only works if it is the most attractive way to get rid of a thing.
If giving it away beats destroying it, the sink is decorative.

---

## 6. Numbers must stay inside what the runtime can represent

A Luau number holds integers exactly to 2⁵³ = `9,007,199,254,740,992`.

**Primordium block HP crosses that at layer 2281.** Past there, damage subtraction
loses precision: blocks can become unkillable, or die to the wrong hit. This is
live on `main` today.

The correct fix is a mantissa/exponent number type, not capping the game's scale.
Do **not** cap a progression ceiling to dodge a float limit — that is letting a
representation detail make a design decision. (`ORE_POWER_TOP` currently does
exactly that and is marked for revisiting; see `NUMBERS.md`.)

---

## 7. Do not add a constant to make a rule pass

The ore system carries **18 interacting tuning dials**. Eight existed. Ten were
added during one redesign, each to satisfy an assert:

```
ORE_PEAK_OFFSET   ORE_BAND_WEIGHT   ORE_EXOTIC_OFF_ZONE   ZONE_ORE_SHIFT
ORE_POWER_TOP     ORE_PACK_FIND_CAP TOOL_POWER_START      TOOL_HOURS_BASE
TOOL_HOURS_SPAN   ORE_RATE_STRONG
```

Every one was locally justified. Together they are a machine where moving one dial
shifts four things you did not intend — which is how a 14.7× rarity cliff, 26 ores
producing byte-identical tools, and 58 consecutive zero-cost upgrade levels all
shipped unnoticed inside a suite that reported PASS.

**Rule:** if a rule needs a new dial to hold, the rule is probably wrong, or the
shape underneath it is. Fixing the shape is cheaper than a nineteenth dial.
Prefer deriving a value from an existing one over introducing a new free
parameter.

---

## 8. A free path must never outperform a paid one

Monetisation here is slots, luck and time — pet slots (3→8), luck boosts, VIP.
None of it matters while the bootstrap loop (§1) exists, because the loop is
faster than prestige, costs nothing, and needs no pets.

**Rule:** before pricing anything, check there is no free strategy that dominates
it. If there is, fix the strategy; no price will compete with zero.
