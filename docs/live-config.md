# Live config snapshot

Read out of the running place (`73982848847016`) via the Studio MCP on **2026-09-27**.
Everything here is measured, not assumed. The calculator in `tools/` reproduces it.

## Difficulty

One axis drives the whole game:

```
D = log6(dirtHp / 20)
```

A zone step is exactly **×6**, so:

```
D(zone, layer) = Dmeadow(layer) + (zoneIndex - 1)
```

Verified against all 11 zones. That means one sampled Meadow curve rebuilds every
zone's block health *and* its ore spread.

**D is a step function, not a curve.** It is constant across a whole named
section — layers 1–40 are all `D = 0`, layers 41–80 are all `D = 0.44`.
Interpolating between samples invents difficulty the game does not have.
There are 75 section boundaries over layers 1–5000.

## Health snapping

Every HP in the game is rounded up by `MineAbbrev.ceil`, which takes one decimal
of the thousands-unit:

```lua
exp   = clamp(floor(log10(n)/3), 1, cap)
unit  = 10 ^ (exp*3)
shown = ceilTenth(n / unit)
return shown * unit
```

This is why Event Horizon's surface reads **1.3B** and not the 1.209B the raw
formula gives. Anything reproducing block health must apply it or it will
disagree with the tooltip a player actually sees.

## Zones

| # | id | name | minRebirth | dirt HP @L1 | @L500 | @L5000 |
|---|----|------|-----------|------------|-------|--------|
| 1 | meadow | Dirt Meadow | 0 | 20 | 74,400 | 3.30e12 |
| 2 | sunscar | Greyvein Quarry | 0 | 120 | 446,000 | 1.97e13 |
| 3 | mistreef | Mistreef Depths | 1 | 720 | 2.70e6 | 1.181e14 |
| 4 | arcwork | Arcwork Veins | 2 | 4,400 | 1.61e7 | 7.081e14 |
| 5 | bloodmoon | Bloodmoon Hollow | 3 | 26,000 | 9.64e7 | 4.30e15 |
| 6 | eclipse | Eclipse Core | 4 | 155,600 | 5.78e8 | 2.55e16 |
| 7 | riftmarch | Riftmarch Scarps | 5 | 933,200 | 3.50e9 | 1.53e17 |
| 8 | starfall | Starfall Barrens | 6 | 5.60e6 | 2.09e10 | 9.177e17 |
| 9 | mythral | Mythral Catacombs | 7 | 3.36e7 | 1.249e11 | 5.60e18 |
| 10 | primordium | Primordium Heart | 8 | 2.016e8 | 7.491e11 | 3.31e19 |
| 11 | bigbang | Event Horizon | 0 | 1.30e9 | 4.50e12 | 1.983e20 |

Meadow sits at `radius = 300`, `island = 72`, `angle = 0`. Far zones are at
radius 6000–9000 and are portals, not walks.

## Ore

- `ORE_CHANCE = 0.005` — 1 block in 200
- `ORE_HP_MULT = 3` — applied at spawn in MineServer, **not** in `blockHp`:
  `maxHp = floor(C.blockHp("dirt", zone, y) * (C.ORE_HP_MULT or 3))`
- **82 ores** (the roster is 82; this line read 121 when measured on 2026-09-27,
  from the stale `MineConfig.ORES`). Spacing re-derives from the live count.

### Spread curve

```lua
x = ore.d - D
v = 1 / (1 + exp((x - X0) / K))
if x < 0 then v = v * exp(x/S) * exp(-((x/W)^2)) end
```

Shipped: `X0 = -4.2, K = 0.45, S = 4.0, W = 3.0`.

**Two regimes, two different dials:**

| regime | dial | what it governs |
|--------|------|-----------------|
| surface | **K** | how fast ores *above* your depth fall off |
| deep | **S, W** | how fast ores *below* your depth fade out |

K barely moves the deep smear; S and W barely move the surface. You need both.

### The problem this exposed

Past the surface the roll is a flat smear **everywhere** — 11.1% / 10.7% / 10.5%,
**17 ores to cover 95%**, 32 to cover 99.9%, identical in every zone at every
depth. There is no dominant ore anywhere except the first few layers.

At `K = 0.45` each tier is only **1.8× rarer** than the one above it, which is
why six ores share the surface:

| K | each tier | Stone at surface | ores @95% |
|---|-----------|------------------|-----------|
| 0.45 (shipped) | 1.8× | 44.8% | 6 |
| 0.20 | 3.8× | 73.7% | 3 |
| 0.116 | 10× | 90.0% | 2 |
| 0.08 | 28× | 96.5% | 1 |

`rollOre` also carries the comment *"ore is no longer filtered by zone"* — there
used to be a per-zone gate and it was removed. That is the harder lever if the
curve alone is not enough.

## World build

`WorldBuilder` **destroys and rebuilds** `MineWorld` on every server start
(line ~2906), deriving island, pit, gate and outpost from `MineConfig.zoneOrigin`.
Any geometry saved in the place is throwaway — move the mine by changing
`radius`, never by dragging parts.

```lua
gatePos = origin - dir * (island - 8)
```
