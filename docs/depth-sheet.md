# Depth sheet — the rock HP equation, verbatim

Generated from `MineDepth.SECTIONS` by `tools/gen-depth-sheet.js`. Regenerate
after any change to the section table; do not hand-edit the tables below.

## The equation, exactly as the game runs it

```
dirtHp(zone, layer) = MineAbbrev.ceil(
    SECTIONS[sectionFor(layer)].dirtHp   -- authored per-section constant
  * 6 ^ (zoneIndex - 1)                  -- MineDepth.ZONE_HP_MULT
  * 2                                    -- flat toughness factor
)
```

`MineConfig.blockHp(kind, zone, layer)` wraps it:

- `core` -> flat `BLOCKS.core.hp`
- `chest` / `crate` / `lucky_block` -> `floor(dirt * CHEST_HP_MULT(2) + 0.5)`
- anything else -> `dirt`
- `bigbang` is forced to `zoneIndex = 11` (it sits above Primordium, not beside Meadow)

**It is a step function, not a curve.** HP is constant across a whole named
section and jumps at the boundary. Interpolating between sections invents
difficulty the game does not have.

`MineAbbrev.ceil` snaps up to one decimal of the thousands unit, so the block
and the label a player reads are the same number (1.209B becomes 1.3B).

## Section-size progression (current)

```
  40 x  25 =  1000 layers  (L1-1000)
  80 x 113 =  9040 layers  (L1001-10040)
```

So: **(40x25) + (80x113)**, 138 sections, layers 1-10040.

### HP step between consecutive sections

| band | sections | avg step | min | max |
| --- | ---: | ---: | ---: | ---: |
| shallow | 11 | x2.0442 | x1.550 | x2.200 |
| mid | 38 | x1.3724 | x1.280 | x1.550 |
| deep | 88 | x1.2800 | x1.280 | x1.280 |

The deep band is a flat x1.28 per section. Shallow front-loads at x2.04.

## Zones 1-10 to depth 10,000

Dirt HP. Every zone is exactly x6 the one before, so Zone N = Zone 1 x 6^(N-1).

| depth | Z1 | Z2 | Z3 | Z4 | Z5 | Z6 | Z7 | Z8 | Z9 | Z10 |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 20 | 120 | 720 | 4.4K | 26K | 155.6K | 933.2K | 5.6M | 33.6M | 201.6M |
| 100 | 94 | 564 | 3.4K | 20.4K | 121.9K | 731K | 4.4M | 26.4M | 157.9M | 947.4M |
| 250 | 2.1K | 12.1K | 72.3K | 433.8K | 2.7M | 15.7M | 93.7M | 562.2M | 3.4B | 20.3B |
| 500 | 74.4K | 446K | 2.7M | 16.1M | 96.4M | 578M | 3.5B | 20.9B | 124.9B | 749.1B |
| 750 | 1.1M | 6.2M | 37.2M | 222.7M | 1.4B | 8.1B | 48.1B | 288.6B | 1.8T | 10.4T |
| 1000 | 14.3M | 85.8M | 514.6M | 3.1B | 18.6B | 111.2B | 666.9B | 4.1T | 24.1T | 144.1T |
| 1500 | 80.5M | 482.8M | 2.9B | 17.4B | 104.3B | 625.7B | 3.8T | 22.6T | 135.2T | 810.9T |
| 2000 | 353.9M | 2.2B | 12.8B | 76.5B | 458.7B | 2.8T | 16.6T | 99.1T | 594.4T | 3.6Qa |
| 2500 | 1.6B | 9.4B | 56.1B | 336.2B | 2.1T | 12.2T | 72.7T | 435.7T | 2.7Qa | 15.7Qa |
| 3000 | 6.9B | 41.1B | 246.5B | 1.5T | 8.9T | 53.3T | 319.4T | 2Qa | 11.5Qa | 69Qa |
| 4000 | 169.5B | 1.1T | 6.2T | 36.7T | 219.7T | 1.4Qa | 8Qa | 47.5Qa | 284.7Qa | 1.8Qi |
| 5000 | 3.3T | 19.7T | 118.1T | 708.1T | 4.3Qa | 25.5Qa | 153Qa | 917.7Qa | 5.6Qi | 33.1Qi |
| 6000 | 81.2T | 487T | 3Qa | 17.6Qa | 105.2Qa | 631.2Qa | 3.8Qi | 22.8Qi | 136.4Qi | 818Qi |
| 7000 | 1.6Qa | 9.5Qa | 56.6Qa | 339.2Qa | 2.1Qi | 12.3Qi | 73.3Qi | 439.5Qi | 2.7Sx | 15.9Sx |
| 8000 | 38.9Qa | 233.3Qa | 1.4Qi | 8.4Qi | 50.4Qi | 302.3Qi | 1.9Sx | 10.9Sx | 65.3Sx | 391.8Sx |
| 9000 | 751.9Qa | 4.6Qi | 27.1Qi | 162.4Qi | 974.4Qi | 5.9Sx | 35.1Sx | 210.5Sx | 1.3Sp | 7.6Sp |
| 10000 | 18.7Qi | 111.7Qi | 670.2Qi | 4.1Sx | 24.2Sx | 144.8Sx | 868.5Sx | 5.3Sp | 31.3Sp | 187.6Sp |

### Zone multipliers

| zone | x | zone | x |
| ---: | ---: | ---: | ---: |
| 1 | 1 | 6 | 7,776 |
| 2 | 6 | 7 | 46,656 |
| 3 | 36 | 8 | 279,936 |
| 4 | 216 | 9 | 1,679,616 |
| 5 | 1,296 | 10 | 10,077,696 |

## Every section (Zone 1 dirt HP)

Multiply by 6^(zone-1) for other zones, then snap with `MineAbbrev.ceil`.

| # | section | layers | band | Z1 dirt HP |
| ---: | --- | --- | --- | ---: |
| 1 | Loam | 1-40 | shallow | 20 |
| 2 | Topsoil | 41-80 | shallow | 44 |
| 3 | Sod | 81-120 | shallow | 94 |
| 4 | Clay | 121-160 | shallow | 202 |
| 5 | Marl | 161-200 | shallow | 434 |
| 6 | Peat | 201-240 | shallow | 934 |
| 7 | Silt | 241-280 | shallow | 2.1K |
| 8 | Ochre | 281-320 | shallow | 4.4K |
| 9 | Humus | 321-360 | shallow | 9.3K |
| 10 | Mudflat | 361-400 | shallow | 20K |
| 11 | Ashsoil | 401-440 | shallow | 31K |
| 12 | Redclay | 441-480 | shallow | 48K |
| 13 | Blackearth | 481-520 | mid | 74.4K |
| 14 | Meadowdirt | 521-560 | mid | 115.3K |
| 15 | Fernsoil | 561-600 | mid | 178.6K |
| 16 | Rootbed | 601-640 | mid | 276.8K |
| 17 | Compost | 641-680 | mid | 429.1K |
| 18 | Softmarl | 681-720 | mid | 665K |
| 19 | Wetclay | 721-760 | mid | 1.1M |
| 20 | Leafmold | 761-800 | mid | 1.6M |
| 21 | Ironsoil | 801-840 | mid | 2.5M |
| 22 | Nightclay | 841-880 | mid | 3.9M |
| 23 | Embersoil | 881-920 | mid | 6M |
| 24 | Gloomdirt | 921-960 | mid | 9.3M |
| 25 | Mossbed | 961-1000 | mid | 14.3M |
| 26 | Hollowchalk | 1001-1080 | mid | 18.3M |
| 27 | Shaleflint | 1081-1160 | mid | 23.5M |
| 28 | Duskslate | 1161-1240 | mid | 30M |
| 29 | Gravestone | 1241-1320 | mid | 38.4M |
| 30 | Pitchshale | 1321-1400 | mid | 49.2M |
| 31 | Widowrock | 1401-1480 | mid | 62.9M |
| 32 | Bonestone | 1481-1560 | mid | 80.5M |
| 33 | Cinderrock | 1561-1640 | mid | 103M |
| 34 | Blackslate | 1641-1720 | mid | 131.9M |
| 35 | Veinrock | 1721-1800 | mid | 168.8M |
| 36 | Quarryrock | 1801-1880 | mid | 216M |
| 37 | Ironstone | 1881-1960 | mid | 276.5M |
| 38 | Deeprock | 1961-2040 | mid | 353.9M |
| 39 | Nightstone | 2041-2120 | mid | 453M |
| 40 | Emberflint | 2121-2200 | mid | 579.9M |
| 41 | Gloomstone | 2201-2280 | mid | 742.2M |
| 42 | Aetherrock | 2281-2360 | mid | 950M |
| 43 | Voidstone | 2361-2440 | mid | 1.3B |
| 44 | Starite | 2441-2520 | mid | 1.6B |
| 45 | Mythrock | 2521-2600 | mid | 2B |
| 46 | Endstone | 2601-2680 | mid | 2.6B |
| 47 | Abyssrock | 2681-2760 | mid | 3.3B |
| 48 | Cryptstone | 2761-2840 | mid | 4.2B |
| 49 | Nullrock | 2841-2920 | mid | 5.4B |
| 50 | Obsidian | 2921-3000 | mid | 6.9B |
| 51 | Riftstone | 3001-3080 | deep | 8.8B |
| 52 | Scarrock | 3081-3160 | deep | 11.3B |
| 53 | Moonstone | 3161-3240 | deep | 14.4B |
| 54 | Eclipseite | 3241-3320 | deep | 18.4B |
| 55 | Sollite | 3321-3400 | deep | 23.6B |
| 56 | Asterrock | 3401-3480 | deep | 30.2B |
| 57 | Nebulite | 3481-3560 | deep | 38.6B |
| 58 | Cosmorock | 3561-3640 | deep | 49.4B |
| 59 | Singulite | 3641-3720 | deep | 63.2B |
| 60 | Eventite | 3721-3800 | deep | 80.9B |
| 61 | Darkstone | 3801-3880 | deep | 103.5B |
| 62 | Horizonite | 3881-3960 | deep | 132.5B |
| 63 | Corestone | 3961-4040 | deep | 169.5B |
| 64 | Primordite | 4041-4120 | deep | 217B |
| 65 | Mantlerock | 4121-4200 | deep | 277.7B |
| 66 | Crustite | 4201-4280 | deep | 355.5B |
| 67 | Magmarock | 4281-4360 | deep | 455B |
| 68 | Pressureite | 4361-4440 | deep | 582.4B |
| 69 | Fathomstone | 4441-4520 | deep | 745.4B |
| 70 | Leviathanite | 4521-4600 | deep | 954.1B |
| 71 | Krakenstone | 4601-4680 | deep | 1.3T |
| 72 | Trenchite | 4681-4760 | deep | 1.6T |
| 73 | Hadalrock | 4761-4840 | deep | 2.1T |
| 74 | Inkstone | 4841-4920 | deep | 2.6T |
| 75 | Finalite | 4921-5000 | deep | 3.3T |
| 76 | Aftermath | 5001-5080 | deep | 4.2T |
| 77 | Nullshelf | 5081-5160 | deep | 5.4T |
| 78 | Voidcrust | 5161-5240 | deep | 6.9T |
| 79 | Hollowdeep | 5241-5320 | deep | 8.8T |
| 80 | Blackreach | 5321-5400 | deep | 11.3T |
| 81 | Sunkstone | 5401-5480 | deep | 14.5T |
| 82 | Dreadrock | 5481-5560 | deep | 18.5T |
| 83 | Mournstone | 5561-5640 | deep | 23.7T |
| 84 | Gravewell | 5641-5720 | deep | 30.3T |
| 85 | Lastlight | 5721-5800 | deep | 38.8T |
| 86 | Duskfall | 5801-5880 | deep | 49.6T |
| 87 | Nethercrust | 5881-5960 | deep | 63.5T |
| 88 | Umbralrock | 5961-6040 | deep | 81.2T |
| 89 | Silentstone | 6041-6120 | deep | 103.9T |
| 90 | Coldforge | 6121-6200 | deep | 133T |
| 91 | Deadvein | 6201-6280 | deep | 170.3T |
| 92 | Ashenfall | 6281-6360 | deep | 217.9T |
| 93 | Ruinstone | 6361-6440 | deep | 278.9T |
| 94 | Sorrowrock | 6441-6520 | deep | 357T |
| 95 | Fadestone | 6521-6600 | deep | 457T |
| 96 | Wraithrock | 6601-6680 | deep | 584.9T |
| 97 | Palefall | 6681-6760 | deep | 748.6T |
| 98 | Grimstone | 6761-6840 | deep | 958.3T |
| 99 | Hushrock | 6841-6920 | deep | 1.3Qa |
| 100 | Veilstone | 6921-7000 | deep | 1.6Qa |
| 101 | Chasmrock | 7001-7080 | deep | 2.1Qa |
| 102 | Abyssfall | 7081-7160 | deep | 2.6Qa |
| 103 | Deepnull | 7161-7240 | deep | 3.3Qa |
| 104 | Farstone | 7241-7320 | deep | 4.3Qa |
| 105 | Endreach | 7321-7400 | deep | 5.4Qa |
| 106 | Lostvein | 7401-7480 | deep | 7Qa |
| 107 | Bleakrock | 7481-7560 | deep | 8.9Qa |
| 108 | Frostnull | 7561-7640 | deep | 11.4Qa |
| 109 | Ironnight | 7641-7720 | deep | 14.5Qa |
| 110 | Shardrock | 7721-7800 | deep | 18.6Qa |
| 111 | Glasscrust | 7801-7880 | deep | 23.8Qa |
| 112 | Riftfall | 7881-7960 | deep | 30.4Qa |
| 113 | Tearstone | 7961-8040 | deep | 38.9Qa |
| 114 | Scarnull | 8041-8120 | deep | 49.8Qa |
| 115 | Breakstone | 8121-8200 | deep | 63.7Qa |
| 116 | Cleftrock | 8201-8280 | deep | 81.6Qa |
| 117 | Fracturite | 8281-8360 | deep | 104.4Qa |
| 118 | Splitstone | 8361-8440 | deep | 133.6Qa |
| 119 | Shearrock | 8441-8520 | deep | 171Qa |
| 120 | Crushstone | 8521-8600 | deep | 218.9Qa |
| 121 | Pressfall | 8601-8680 | deep | 280.1Qa |
| 122 | Weightstone | 8681-8760 | deep | 358.6Qa |
| 123 | Densecore | 8761-8840 | deep | 458.9Qa |
| 124 | Leadenrock | 8841-8920 | deep | 587.4Qa |
| 125 | Heavystone | 8921-9000 | deep | 751.9Qa |
| 126 | Massrock | 9001-9080 | deep | 962.4Qa |
| 127 | Gravitite | 9081-9160 | deep | 1.3Qi |
| 128 | Collapsite | 9161-9240 | deep | 1.6Qi |
| 129 | Implodite | 9241-9320 | deep | 2.1Qi |
| 130 | Singulstone | 9321-9400 | deep | 2.6Qi |
| 131 | Eventfall | 9401-9480 | deep | 3.4Qi |
| 132 | Horizonfall | 9481-9560 | deep | 4.3Qi |
| 133 | Lightless | 9561-9640 | deep | 5.5Qi |
| 134 | Nullcore | 9641-9720 | deep | 7Qi |
| 135 | Voidheart | 9721-9800 | deep | 8.9Qi |
| 136 | Endcore | 9801-9880 | deep | 11.4Qi |
| 137 | Finality | 9881-9960 | deep | 14.6Qi |
| 138 | Terminus | 9961-10040 | deep | 18.7Qi |
