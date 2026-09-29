# Ore: what it is for

## Why ore exists at all

Read this first, because it has been forgotten twice.

The game had a content problem: **not enough tools.** No generator produced enough
distinct tool identities to fill a 10-zone, 25-rung ladder plus chests plus
rewards. Ore was invented to solve that, and it does, completely:

```
82 ores × 57 tool types = 4,674 distinct tools
```

Each one visually its own object, because the ore supplies colour, material,
roughness, metalness and glow (`MineConfig.ORES`), and the tool type supplies the
silhouette.

**Ore was never meant to be a progression system.** It became one when ore tier
started deciding damage, and every problem in the ore layer traces back to that
single decision.

## What went wrong, in one number

Ore power follows **depth**. Depth is ungated. So:

| where | best shop pick | ore pick findable there | ratio |
|---|---|---|---|
| Meadow L1 | 15 | 2 | 0.1× |
| Meadow L1500 | 15 | 2,832 | 189× |
| Meadow L2500 | 15 | 8,408 | **561×** |

And the levelling system, which absorbed most of the design effort, is worth
**36×** over 99 levels — against the find's **500×**. The effort went into the
small lever.

## The recommended direction

> **Ore decides which tool you have. The zone ladder decides how hard you hit.**

An ore tool performs at its family's zone-appropriate power — the same
`MineShopEconomy` ladder that already works — and the ore supplies **identity,
rarity and trade value**, not a damage multiplier.

What this buys, checked against the owner's stated goals:

| goal | effect |
|---|---|
| collecting | 4,674 distinct things to want, with real rarity behind the roll |
| trading | items priced on rarity, which is the axis `MineTradeValue` already speaks |
| balanced | numbers stay in the range the working game already had |
| doesn't fuck itself | no second power economy, so nothing to mint |

And it resolves three invariant violations at once: the bootstrap loop
(`PRINCIPLES.md` §1) stops being a loop because the reward is no longer power;
power leaves the ungated axis (§2); and trade value and power stop disagreeing
(§3) because the item no longer carries power.

### If ore must affect power at all

Some flavour is fine. Keep it **small, capped, and not on the thing that finds
ore**:

- A modest multiplier band — say ±20% around the zone-appropriate value — so the
  ore you got matters without becoming the ladder.
- **Never** let an ore tool boost `oreYield`, `rareOre`, `luck` or anything that
  increases ore acquisition. That rebuilds the loop (§1).
- Never let it exceed the best shop tool of the next zone, or it substitutes for
  prestige.

## The level system

Given levelling is worth 36× against the find's 500×, it is not carrying its
weight. Options, in order of preference:

1. **Remove it.** Ore tools arrive finished. Deletes `TOOL_MAX_LEVEL`, the cost
   curves, hours-to-max, the dust-only-levels problem, and roughly half the
   remaining dials.
2. **Make it cosmetic or small** — a few percent, or visual tiers.
3. Keep it as-is only if there is a reason nobody has articulated yet.

If it is removed, the following become dead and should go with it:
`TOOL_HOURS_BASE`, `TOOL_HOURS_SPAN`, `ORE_RATE_STRONG`, `TOOL_POWER_START`,
`ORE_POWER_TOP`, `TOOL_CLIMB_ORE`, `TOOL_CLIMB_DUST`, and the
`toolUpgradeCost`/`toolSpent`/`toolRecycle` series machinery.

## Current state of the code (as of this writing)

Not merged. All on branches; `main` has none of it.

| what | where | state |
|---|---|---|
| 82-ore roster, bands, migration, spawn curve | branch `ore-roster-82`, PR #3 | green, unmerged |
| Six-face ore block art | branch `ore-face-art`, PR #2 | green, unmerged |
| Tool power/costs, coin rate, generator guard | branch `ore-tools-power` | pushed, no PR |

`main` is the working game. Nothing here is load-bearing, which makes this a cheap
place to change direction.

## Facts worth keeping whatever happens

These are independent of the power question and were expensive to work out:

- **Roster:** 82 ores in 8 bands — Common 18, Uncommon 11, Rare 20, Epic 11,
  Legendary 9, Mythic 6, Divine 4, Exotic 3. The 82 order is the old 121 order
  with 39 removed, no reshuffle.
- **Migration:** removed ids must chain to a *kept* ore. Seven pre-existing
  `ORE_MIGRATION` entries pointed at ores the cut removes (`alumina → selenite`
  etc.); they are re-pointed on the branch. `p.oreTools[].tier` is an **index**,
  not an id, so renumbering silently re-points every tool a player owns —
  `ORE_TIER_REMAP_V2` handles it.
- **`ore.d` is derived, never declared.** It comes from each ore's authored `home`
  in the `ORE_BY_ID` loop.
- **`MineConfig.ORES` is generated** by `tools/gen-ores.js` from
  `docs/ore-remake.md`, and the doc is behind the code. The generator has a guard
  that refuses `--write` on drift. Do not bypass it.
- **Pack yields should rise with rarity, not fall.** A rare ore you find twice a
  day handing over 2–4 units makes its own progression absurd; the maths wants the
  rarest ores giving the biggest hauls.
