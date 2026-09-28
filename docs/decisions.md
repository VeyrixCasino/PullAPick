# Design decisions

Why things are the way they are, so the reasoning survives the session it was
made in. Newest last.

## Ore identity is carried by the name, not the colour

The server has always stamped `OreId` / `OreName` / `OreTier` onto an ore part
and **nothing ever read them** — the client had exactly one ore reference in
392k characters, and it was the `rareOre` stat.

Worse, the block card had a branch-order fault: an ore block carries a
`SectionName` like every other block, so it hit the *section* branch first and
read `Clayfall | L312`. The one thing it could not tell you was which of the
121 ores you were looking at.

Ore is now checked first, and there is a name tag on the block itself. With 121
ores sharing a palette, a Cobalt vein and a Niobium one are the same blue cube —
colour cannot carry identity at this roster size.

## Ore shapes: eight archetypes, no bespoke art

Every ore uses one of eight procedural shells in `ServerStorage.OreShapes`
(Vein, Seam, Nugget, Druse, Cluster, Shard, Geode, Massive). Parts carrying a
`Tint` attribute take the ore's colour and material at spawn; the host rock
stays grey. That is the whole contract, and it means 121 ores need zero unique
models.

**The trap, learned the hard way:** the first build placed ore features at
`B*0.42` (2.1 studs) when the host cube's half-extent is 2.5 — so they were
*inside* the rock. Seam and Geode rendered as plain grey cubes. Every feature
must sit on or past the host surface, with jitter sliding *along* the face
rather than back into it. Geode needed a third pass: a 5.3-stud ball inside a
4.95 cube only protrudes 0.18 studs, so the core is now larger than the block
with rock surviving as shell plates over the face centres.

## Tools run a per-tool 1–1000 scale

Ore tier used to set a tool's **starting level** — a tier-121 tool was born at
level 700. Finding one was the end of its story rather than the start, and there
was no reason to spend stardust on something you just pulled out of a wall.

Tier is now a **multiplier**, not a head start. Every tool opens at level 1 and
climbs the same 1000. `tierSpan` says how many ×6 steps separate tier 1 from
tier 121 — the same unit the mine measures depth in, so "this tool is four zones
better" reads straight off the slider.

This also puts the pressure back on ore, because levels cost ore.

## Recycling is a flat 50% of what you spent

Earlier designs carried a tier falloff, a type falloff, a level tax, and a base
of *theoretical build cost* rather than dust-you-paid. All of that machinery
existed to stop a tool **found in a wall** from being a payout, because a found
tool arrived at level 700 with a huge notional build cost behind it.

On the 1–1000 scale a found tool arrives at **level 1 with nothing behind it**,
so the exploit is gone by construction. The rate can be generous and legible
instead of defensive. Recycling returns ore as well as dust.

### The constraint that killed the earlier design

A refund that is not worth collecting does not mean the tool leaves the economy —
it means the player **gives it away instead**, supply inflates, and the sink
never runs. That was the fatal objection to paying only on purchased upgrades.
The 1–1000 rescale dissolves it rather than working around it: a found tool is
worth *using or trading for its tier*, not scrapping.

## Gems come from scrap ore, and the price is ours

Gems are a secondary currency minted by selling ore. That is deliberate: the
price is set rather than emergent, so the economy cannot drift.

The curve must stay **regulated** — a modest edge deeper, not an exponential
one. At `gemSpan 1.5` a find pays **12 → 45 → 176** gems across tiers 1 → 60 →
121, a 14.7× spread. An earlier `gemSpan 9` gave 10 **million**×, which is the
kind of number that eats a currency.

### Bulk ores (the lapis idea)

Every Nth tier drops a pile instead of a couple, and each unit is worth
proportionally less. A bulk find comes out worth ~1.02× its neighbour — same
value, completely different feel: a heap you cash in rather than a single good
rock.

## Non-negotiables

- **No pity systems anywhere.**
- **Do not cripple the datastore.** Ore ids are load-bearing: `p.ores[oreId]` is
  banked, and pack ids are `<oreid>_ore_pack`. Renaming or reordering ores
  orphans both — any roster change needs an id→id migration with old ids kept
  as aliases.
- No limits on the upside. Infinitely lucky is the point.
- Studio is the source of truth; Cursor edits the same scripts concurrently, so
  every edit anchors and asserts the source is unchanged before committing.
