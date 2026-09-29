# Real magnitudes

Every number here was read out of the code or computed from it. Cited so you can
re-derive rather than trust. If the code has moved, the code is right.

## Block health

```lua
dirtHp(zi, layer) = meadowDirtHp(layer) × 6^(zi-1) × 2   -- then MineAbbrev.ceil
hardness          = log6(hp / 20)                        -- MineConfig.oreDifficulty
```

**One zone step = exactly +1.0 hardness.** Depth inside a zone adds ~10.2 more.
Main zones span hardness **0.00** (Meadow L1) to **19.14** (Primordium L2441).

| zone | L1 | L500 | L1500 | L2500 |
|---|---|---|---|---|
| meadow | 20 | 74,400 | 80,500,000 | 1,600,000,000 |
| sunscar | 120 | 446,000 | 482,800,000 | 9,400,000,000 |
| mistreef | 720 | 2,700,000 | 2,900,000,000 | 56,100,000,000 |
| arcwork | 4,400 | 16,100,000 | 17,400,000,000 | 336,200,000,000 |
| bloodmoon | 26,000 | 96,400,000 | 104,300,000,000 | 2,100,000,000,000 |
| eclipse | 155,600 | 578,000,000 | 625,700,000,000 | 12,200,000,000,000 |
| riftmarch | 933,200 | 3,500,000,000 | 3,800,000,000,000 | 72,700,000,000,000 |
| starfall | 5,600,000 | 20,900,000,000 | 22,600,000,000,000 | 435,700,000,000,000 |
| mythral | 33,600,000 | 124,900,000,000 | 135,200,000,000,000 | 2,700,000,000,000,000 |
| primordium | 201,600,000 | 749,100,000,000 | 810,900,000,000,000 | 15,700,000,000,000,000 |

**Why it explodes**, multiplicatively:

```
10 zones at ×6 each                      10,077,696×
depth inside one zone (L1 → L2500)       80,000,000×
sections continuing past L2500            5,678,428×
                              total ≈ 4.6 × 10^21
```

If you want readable numbers, `ZONE_HP_MULT = 6` across ten zones is the lever. It
is also the spine of shop tool prices (`MineShopEconomy.toolPowerRaw` multiplies by
`Depth.zoneMult`), so it cannot be changed alone.

### The 2⁵³ bug — live on `main`

A Luau number holds integers exactly to **9,007,199,254,740,992**.

**Primordium HP crosses it at layer 2281.** Past there, HP cannot be represented
exactly and damage subtraction rounds — blocks can survive a hit that should kill
them, or die early. The deepest authored section (L9961+) in Primordium computes to
`187,593,287,731,200,014,621,343,744`, about 2 × 10¹⁰ times past the limit.

The fix is a mantissa/exponent number type. **Do not cap the game's scale to dodge
this** — see `PRINCIPLES.md` §6.

## Zones and depth

| zone | index | prestige to enter |
|---|---|---|
| meadow | 1 | 0 |
| sunscar | 2 | 0 |
| mistreef | 3 | 1 |
| arcwork | 4 | 2 |
| bloodmoon | 5 | 3 |
| eclipse | 6 | 4 |
| riftmarch | 7 | 5 |
| starfall | 8 | 6 |
| mythral | 9 | 7 |
| primordium | 10 | 8 |
| bigbang | 11 | 0 (event; own tool system, `MineHorizonTools`) |

Depth: seams at 500, 1000, 1500 … 5000; 5 layers of air before each
(`MineDepth.AIR_GAP`). Bands: shallow 1–500, mid 501–1500, deep 1501–2500,
abyss 2501+. **No depth gate** — `rebirthForSeam` and `rebirthForLayer` return 0.
The unused scaffolding for one is `REBIRTH_PER_ZONE_B = 10` and
`REBIRTH_BAND_C_BASE = 60`.

## Boosts

**322 pets, 13 boost types, 3 slots rising to 8** (`MAX_PET_SLOTS = 8`).

| boost | pets carrying it | min | max | mean |
|---|---|---|---|---|
| dirtBreak | 182 | 0.043 | 2.514 | 0.506 |
| backpack | 182 | 0.060 | 2.686 | 0.726 |
| oreYield | 140 | 0.011 | 0.706 | 0.102 |
| mineSpeed | 136 | 0.044 | 1.404 | 0.386 |
| luck | 125 | 0.016 | 0.950 | 0.240 |
| coinBonus | 85 | 0.038 | 3.071 | 0.520 |
| gemFind | 79 | 0.030 | 1.203 | 0.492 |
| swingRate | 55 | 0.033 | 0.884 | 0.362 |
| chestLuck | 46 | 0.033 | 0.484 | 0.233 |
| blastRadius | 26 | 0.020 | 0.399 | 0.198 |
| zap | 24 | 0.043 | 1.094 | 0.249 |
| walkSpeed | 11 | 0.343 | 3.000 | 1.314 |
| pulverize | 10 | 0.020 | 0.151 | 0.071 |

Stacking, quoting `MineServer`'s own comment:

> *Each pet × its rune × (its hat + your hat), the three added up, × your face*

then × prestige luck, × VIP 1.05, × event-pass bonus, × rebirth skills
(multiplicative for `mineSpeed / dirtBreak / walkSpeed / luck / rareOre`, additive
for `echo / zap / blastRadius / oreYield / luckyFind / fossilFind`).

**A hat multiplies per pet**, so its real leverage is up to 8×. Size a hat as if it
were eight hats.

## Charms

31 charms, one slot. Bands: shallow **+100–140%**, mid **+170–230%**, deep
**+250–320%**. Ranges seen: `mineSpeed 1.10–3.00`, `dirtBreak 0.50–2.60`,
`coinBonus 1.70–2.80`, `luck 0.50–2.00`. See `CHARMS.md`.

## Economy rates

```lua
CHEST_CHANCE = 0.003                    -- flat, per block
CHEST_LOOT weights: pack 70, coins 17, hat 9, dust 2.2, charm 1.1, relic 0.6
chest dust roll = zoneTier^2 × 120 × (0.6..1.6)     -- mean zoneTier^2 × 132
ORE_CHANCE = 1/200                      -- flat, per block
```

Measured dust per hour at 145,000 blocks/h, from chest rolls alone:
**1,265 (Meadow) → 126,450 (Primordium)**. Pulverize and quests are not in that
figure — they are player-initiated rather than per-block.

Trade value ladders (`MineTradeValue`), ~×2.2 per rarity step:

```
runes  Common 8  → Exotic 2,200
gear   Common 12 → Exotic 3,600
GEM_TO_DUST 2 · COIN_TO_DUST 0.002
```

## Coins

`coins == block HP` for every block (`ore 3/3, stone 18/18 … primordium
14,600,000/14,600,000`), so coin income inherits the full 4.6 × 10²¹ span.

`VAL_ZONE = 2.2` / `VAL_DEPTH = 14.0` / `valueScale()` were **dead code** — no
callers — and are removed on the `ore-tools-power` branch, replaced by
`ZONE_COIN_STEP = 5` and `zoneCoinRate(zone) = 5^(zi-1)`, flat within a zone.

**That rate is defined but not wired to the payout.** Two decisions block it:

1. Per-block pay needs the block-**break** event; `payDamage` currently runs on
   partial damage and pays a fraction.
2. The backpack is denominated in the same HP units, so coins going per-block while
   the bag stays per-HP makes them fill at different rates and changes what
   `cap(p)` means.
