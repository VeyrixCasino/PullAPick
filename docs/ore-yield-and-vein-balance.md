# Ore yield, vein size, and what a tool actually costs

Measured 2026-10-06 against the live modules in Studio (`MineConfig` required
from a **clone**, because `require` caches per ModuleScript instance and the
in-session copy returns stale values). Every number here is read out of the
shipped code, not restated from it — regenerate by re-running the probes
described at the bottom rather than editing figures by hand.

---

## 1. The headline: ore per block broken

`ORE_CHANCE = 0.005`, so **1 block in 200 carries ore**, and each ore block drops
its band's quantity. Expected ore units per block broken:

| Zone | E\[drop\] per ore block | Ore units per block broken | Commonest ore there |
| --- | --- | --- | --- |
| meadow (zone 1), L2500 | 9.03 | **0.0450** | stone, 17.5% |
| bloodmoon (zone 5), L2500 | 10.10 | **0.0505** | aluminum, 5.7% |
| bigbang (zone 11), L2500 | 11.45 | **0.0573** | palladium, 5.7% |

So across the whole game it is roughly **one ore unit per 20 blocks broken**, and
that number barely moves with depth or zone — the mix shifts to richer ore, but
the drop bands are a bell (peak 12-15 at Epic, down to 2-4 at Exotic) so the
expected quantity stays near 9-11.

**This is the number endgame enchants are supposed to multiply, and see §4 —
right now nothing multiplies it.**

## 2. Blocks broken to afford one tool

Each ore's share peaks in a particular zone and depth; this is the **best case**,
measured at each ore's peak share across all 11 zones and a layer sweep to 2500.
Real play is worse, because you are not always standing where your ore peaks.

| Band | Tiers | Peak share | Blocks broken for its tool |
| --- | --- | --- | --- |
| Common | 1-18 | 5.8% - 44.5% | **13,500 - 192,000** |
| Uncommon | 19-29 | 5.7% | 168,000 - 214,000 |
| Rare | 30-49 | 5.7% | 190,000 - 263,000 |
| Epic | 50-60 | 5.4% - 5.7% | 236,000 - 282,000 |
| Legendary | 61-69 | 1.7% - 5.1% | 272,000 - 887,000 |
| Mythic | 70-75 | 0.5% - 1.4% | 973,000 - 2,762,000 |
| Divine | 76-79 | 0.2% - 0.4% | 3,157,000 - 6,312,000 |
| Exotic | 80-82 | 0.11% - 0.18% | **7,414,000 - 12,131,000** |

Read the two ends: the cheapest craftable tool is about **13.5 thousand blocks**,
and the dearest is about **12 million**. The ladder is monotone and nothing is
impossible, which is the intended shape ("every rarity should be POSSIBLE in
every zone, just super highly unlikely") — but the top end only works if
something multiplies yield.

`craftBlocks` reads 30-76 and is *not* this number. It counts blocks **of that
ore**, so it has to be divided by how often that ore is the block you broke.

## 3. Vein size by band

Vein size is a **clustering** knob, not a rate. `veinWeights` divides each ore's
share by its mean size (`q_i = share_i / mean_i`), so a vein twice as big is half
as frequent and both the per-ore share and the overall density come out
unchanged. Verified in `tools/verify/veins.js`: measured density 1 in 208 against
`ORE_CHANCE`'s 1 in 200, with the big/mid/solo shares each landing within a point
of what `oreWeights` predicts.

| Band | Mean vein | Drop per ore block | craftBlocks |
| --- | --- | --- | --- |
| Common | 3.50 - **13.00** | 8-10 | 30-55 |
| Uncommon | 3.50 | 10-12 | 48-61 |
| Rare | 3.48 - 3.50 | 11-13 | 54-74 |
| Epic | 3.48 - 3.50 | 12-15 | 67-76 |
| Legendary | 3.12 - 3.39 | 8-10 | 69-76 |
| Mythic | 2.67 - 3.03 | 6-8 | 70-73 |
| Divine | 2.07 - 2.42 | 4-6 | 68-70 |
| Exotic | **1.25 - 1.59** | 2-4 | 65-66 |

Monotone from Common down to Exotic: rarer ore comes in smaller finds, which is
the intended direction. Stone is the single 13-block outlier. Across the roster:
**1 ore averages 12-14, 81 of 82 average under 8, 68 of 82 sit at 3-4, 12 at
1-2.**

Size comes from one 0..1 "effort" position built from three drivers —
`craftBlocks` (weight 0.60), drop count inverted (0.25), and rarity band (0.15) —
then mapped through a curve with separate tail powers: steep at the big end
(`VEIN_TAIL_POWER_BIG = 12`) so 12-14 stays one or two ores, gentler at the small
end (`..._SMALL = 5`) so rarity is a visible gradient rather than a cliff.

Shapes are **grown**, not stamped: a vein starts at one block and bolts
neighbours on, seeded per ore with an axis bias, so each ore has a recognisable
habit and sizes are contiguous by construction. Measured cluster sizes span
3,4,5,7,8,9,13 rather than one fixed silhouette per size.

## 4. Nothing currently multiplies ore quantity

This is the open issue, and it is the one that decides whether §2's top end is
reachable.

`MineServer` rolls ore as `math.random(lo, hi)` straight off
`MineConfig.oreYieldFor(tier)` — **no boost, enchant, luck or finder multiplier is
applied.** That is deliberate and the comment says so: the ore finder is "a
quality stat, not a quantity one", and it already did its work in `oreWeights`
via `oreFindShift` when the block chose which ore to be. Paying it again as
material "would quietly turn it into a yield multiplier".

So at present, 12 million blocks for an Exotic tool is the real figure, not a
pre-multiplier figure.

One inconsistency worth knowing: the **legacy ore-pack conversion** path does
apply `(1 + oreFind)` as a straight quantity multiplier
(`each = mid * (1 + find)`), so the retired pack route and the live drop route
disagree about whether the finder is quantity or quality.

If endgame enchants are meant to buff yield, that multiplier has to be added
somewhere, and the choice is between:

- a **quantity** multiplier on the drop roll, which is the simplest and is what
  the comment warns compounds on a flat per-block rate; or
- raising the **base** bands for the top rarities, which keeps the no-multiplier
  design and makes the Exotic 2-4 drop less punishing; or
- lifting `ORE_CHANCE` for deep zones, which raises everything at once.

Not changed here — it moves the economy in several places at once (gem value
derives from work-per-unit, and `toolCraftCost` derives from the drop band), so
it wants its own measured pass.

## 5. The knobs

| Constant | Now | What it moves |
| --- | --- | --- |
| `ORE_CHANCE` | 0.005 | How often any block is ore. Scales everything in §1 and §2 linearly. |
| `ORE_YIELD_BANDS` | 8 bands, 2-15 | Drop per ore block. Also feeds `toolCraftCost` and gem value. |
| `VEIN_MEAN_AT_EASY` | 13.0 | The single biggest average. |
| `VEIN_MEAN_TYPICAL` | 3.5 | Where the bulk of the roster sits. |
| `VEIN_MEAN_AT_HARD` | 1.25 | The smallest average. |
| `VEIN_TAIL_POWER_BIG` | 12 | Raise to make 12-14 rarer still. |
| `VEIN_TAIL_POWER_SMALL` | 5 | Lower to drag more ores down to 1-2. |
| `VEIN_W_COST/_YIELD/_RARITY` | .60/.25/.15 | Which driver decides size. |
| `VEIN_AXIS_BIAS` | 0.62 | How strongly an ore's veins follow its own axis. |
| `VEIN_MAX` | 14 | Hard ceiling on one vein. |
| `CRAFT_BLOCKS` | 30 | Base blocks-of-that-ore a craft is worth. |
| `CRAFT_BAND_EASE` | 0.18 | How much rarity discounts a craft. Raise to make rare tools need less ore. |
| `CRAFT_DEPTH_SLOPE` | 4 | How much dearer a late tool is. |

Changing a vein constant does **not** change a spawn rate — the density
correction absorbs it. Changing `ORE_CHANCE`, `ORE_YIELD_BANDS` or the `CRAFT_*`
constants does.

## 6. Reproducing these numbers

`tools/verify/veins.js` covers the distribution, the density conservation and the
per-server randomness, and fails loudly if any of it drifts. The per-band tables
above came from requiring a **clone** of `MineConfig` inside Studio and walking
`ORES` against `oreWeights`, `oreYieldFor`, `craftBlocks`, `toolCraftCost` and
`veinSizeMean` — cloned because `require` caches per instance, so a probe against
the live module silently reports the values from the first time this session
touched it.

Two traps worth remembering when re-measuring:

- `oreWeights(zoneId, layer, rareOre)` takes a **layer**, and converts it through
  `oreDifficulty`, which scales with **zone**. Sampling only meadow makes every
  ore past Uncommon look like it never spawns — peak shares of 0.0000 and
  blocks-per-tool in the billions. Sweep all 11 zones.
- Its result is cached per section, so a sweep over layers inside one section
  returns the same row every time and the mix looks flat.
