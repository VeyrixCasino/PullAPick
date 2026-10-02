# Economy: supply, sinks, trade, money

The owner's requirement is *"precautions so it doesn't fuck itself"*. This file is
those precautions. It assumes you have read `PRINCIPLES.md`.

## The four questions

Any change to an item, drop or price has to answer all four:

1. **Where does it come from?** (supply)
2. **Where does it go?** (sink)
3. **Can it move between players?** (trade)
4. **What is it worth, and does that match what it does?** (price vs power)

Most economy failures are a missing answer to 2 or a mismatch in 4.

## Supply

| item | source | rate | scales with power? |
|---|---|---|---|
| coins | every block | `coins == block HP` | **yes** — and with the boost stack |
| ore | 1 in 200 blocks | flat | no, but which ore scales with depth |
| ore tools | 0.5% of ore packs | flat | no |
| chests | 0.3% of blocks | flat | no |
| stardust | chest rolls (2.2% of chests), card salvage, pulverize, quests | — | weakly |
| pets | packs (gems / Robux) | — | no |
| charms | zone×band roll + pack pool | — | weakly |

The "scales with power" column is the one to watch. **Flat per-block rates are
self-limiting** — mining twice as fast doubles them, nothing more. Rates that
multiply by the boost stack compound instead, and the stack's top is far above its
middle (`NUMBERS.md`).

Coins are the one row marked yes, twice over: the payout equals block HP *and*
`coinBonus` multiplies it, with pets reaching `coinBonus 3.07` each across 8 slots.

## Sinks

Existing sinks: tool recycle (50% of what went in), shop purchases, charm/pet
packs, pulverize.

**The hole:** recycling returns 50%, but **giving the item away returns 100% of its
usefulness to the economy**. A veteran pawning a tool to a new player removes it
from one inventory without removing it from the game. The sink is therefore
decorative for exactly the population that has the most to dump.

Fixes, in order of preference:

1. **Make the traded thing not worth pawning** — if an ore tool is a collectible
   rather than a power spike (`ORE.md`), pawning it is a gift, not a progression
   skip. This solves it at the root.
2. **Strip investment on transfer** — a traded charm arrives at base level
   (`CHARMS.md`). The sunk stardust does not transfer, so the sink stays real.
3. Trade restrictions. Last resort: you will be patching individual routes forever
   while the underlying mismatch keeps making new ones.

## Trade

Trading is priced by `MineTradeValue` in stardust-equivalent:

```
runes  Common 8  → Exotic 2,200      (~×2.2 per rarity step)
gear   Common 12 → Exotic 3,600
GEM_TO_DUST 2 · COIN_TO_DUST 0.002
```

Restrictions today: socketed runes, worn gear, and cards without a registry serial
cannot be offered; ephemeral profiles cannot trade.

**The structural problem** (`PRINCIPLES.md` §3): price ladders ×2.2 per step, ore
tool power ladders **500×** across the roster. The pricing model cannot see the
difference between a fair trade and a progression skip, because it is measuring a
different quantity than the one that matters.

**Rule for anything new that is tradable:** its entry in `MineTradeValue` must be a
function of what it *does*, not only of what rarity it *is*. If you cannot write
that function, the item should not grant power.

## Monetisation

What is sold: pet slots (3 → 8), luck, VIP (remote sell, +1 pet seat, AFK income,
tag), packs, the event pass.

This is a sound set — slots, luck and time are what converts in this genre. The
problem is not the offer.

**The problem is that a free strategy dominates it.** The bootstrap loop
(`PRINCIPLES.md` §1) is faster than prestige, costs nothing, and needs no pets. As
long as it exists, none of the above is worth buying, because the thing being sold
is *acceleration* and the loop accelerates harder for free.

**Order of operations: fix the loop first, then price.** Pricing against a free
dominant strategy is pricing against zero.

Second-order point worth keeping in mind: what people pay for is **the feeling of
progress per session**, not the ceiling. That is another reason the ore work's
focus on time-to-max was misplaced — nobody has ever bought a pack to reach level
100 faster; they buy it because this session felt good.

## Precaution checklist

Run this before shipping any economy change:

- [ ] Every new item has an answer to all four questions above.
- [ ] No reward improves the rate of acquiring itself, unless gated by prestige or
      Robux.
- [ ] Nothing the boost stack multiplies is uncapped.
- [ ] Anything tradable that grants power has a price that scales with the power.
- [ ] The intended sink is the *cheapest* way to dispose of the thing.
- [ ] No free strategy dominates a paid one.
- [ ] Numbers stay inside 2⁵³, or the big-number type is in place first.
- [ ] You did not add a tuning constant to make the above pass.
