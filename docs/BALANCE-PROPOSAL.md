# Balance proposal — 2026-10-03

Owner's brief: *"I want the game progression to feel snappy, yet still quick.
propose balanced numbers with all new enchants. Just make damage and chance 2
different stats."*

Two halves. **§1 is applied and verified** — it is the damage/chance split,
which was a direct instruction. **§2–§4 are proposals**: they move the live
economy, so they are written as exact replacement tables for you to approve or
redline rather than applied behind your back.

---

## 1. APPLIED — proc damage is now a separate stat from proc chance

### What was wrong

Every proc handed its neighbour `dmg`: **the player's whole swing**. One stat
bought both how often a proc fired and how hard, so the only way to make a proc
feel good was to make it fire constantly, and the only way to balance one was to
make it rare.

| proc | chance stat | damage it dealt | worst case per swing |
|---|---|---|---|
| Blast | `oreYield` | full swing × 6 faces | **6.00×** |
| Zap | `zap` | full swing, 0.9^hop, 32 hops | **9.70×** |
| Ricochet | `ricochet` | full swing × 1 | **1.00×** |
| Earthquake | `earthquake` | 20%/s × 5s | **1.00×** |

Zap was the real offender. 0.9 is almost no decay — at `zap = 0.8` the chain
still has a 0.38 chance to continue on hop 9 — so the 32-hop cap was doing all
the balancing and the falloff none.

### What it is now

**Chance** stays on the existing per-proc stat. **Damage** is `PROC_SHARE`
scaled by one new stat, `procPower`.

```
MineConfig.PROC_SHARE = {
    blast    = 0.35,   -- × 6 faces = 2.10 per proc
    zap      = 0.45,   -- first hop, then ZAP_FALLOFF
    ricochet = 0.60,   -- one block, cannot chain
    quake    = 0.12,   -- per second, × 5s = 0.60 per life
}
MineConfig.ZAP_MAX_HOPS   = 6      -- was 32
MineConfig.ZAP_FALLOFF    = 0.75   -- was 0.9, on both chance and damage
MineConfig.PROC_POWER_CAP = 3.0    -- +300% ceiling on procPower
```

| proc | before | after | change |
|---|---|---|---|
| Blast | 6.00× | **2.10×** | −65% |
| Zap (whole chain) | 9.70× | **1.48×** | −85% |
| Ricochet | 1.00× | **0.60×** | −40% |
| Earthquake (whole life) | 1.00× | **0.60×** | −40% |

Every share is **under 1.0**, which is the owner's *"almost no effect should do
full pickaxe damage"* stated as an assertion the test suite enforces.

### The new stat

```
procPower  "Proc Power"  weight 3.0  additive %
"How hard Blast, Zap, Earthquake and Ricochet hit.
 Does nothing without a proc chance to scale."
```

Weighted **3.0** — above any single proc chance, below Blast's 4.0. It is worth
more than one chance stat because it multiplies all four; less than Blast
because it is worth exactly nothing on a build with no proc chance.

Rollable on gear (`0.38`) and on **pet, pickaxe, explosive and drill** runes.

At the +300% cap a blast is `1.40 × 6 = 8.4×` a swing — enormous, and it cost a
whole stat budget to reach. That is the point: procs become a *build* instead of
a tax on every other build.

Guarded by `tools/verify/procs.js` (30 assertions).

---

## 2. PROPOSED — nerf hats substantially

### Where it stands

`MineGear.SHEET`, with 3 hat slots and 1 face:

| grade | hat | face |
|---|---|---|
| F | 30% | 15% |
| B | 100% | 50% |
| S | 200% | 100% |
| SSS | **350%** | **175%** |

**Full SSS gear = 3 × 350% + 175% = +1225%.** A 12.25× multiplier from
cosmetics, before pets, runes, charms, skills, prestige or the event pass.

### Proposed sheet

Halve the floor, compress the ceiling, keep the documented hat = 2 × face rule.

| grade | hat (now → proposed) | face (now → proposed) |
|---|---|---|
| F | 30% → **12%** | 15% → **6%** |
| D | 50% → **18%** | 25% → **9%** |
| C | 70% → **26%** | 35% → **13%** |
| B | 100% → **36%** | 50% → **18%** |
| A | 140% → **50%** | 70% → **25%** |
| S | 200% → **68%** | 100% → **34%** |
| SS | 260% → **90%** | 130% → **45%** |
| SSS | 350% → **120%** | 175% → **60%** |

**Full SSS gear: +1225% → +420%.** A 2.9× nerf.

The *shape* is deliberately kept: SSS/F stays ~10× and SSS/B stays ~3.3×, so
chasing grades still feels worth it. What goes away is gear being the single
biggest multiplier in the game — which is what makes charms and skins the build
(**TODO 0.13**) rather than the garnish.

---

## 3. PROPOSED — "snappy, yet still quick"

The climb is already parameterised well: `TOOL_MAX_LEVEL = 100` with three
cap-independent climb totals. Per level today:

| knob | total | per level |
|---|---|---|
| `TOOL_CLIMB_DAMAGE` | 3.9e8 | **+22.1%** damage |
| `TOOL_CLIMB_ORE` | 1747 | +7.8% cost |
| `TOOL_CLIMB_DUST` | 55800 | +11.7% cost |

**+22% damage a level against +8% ore is genuinely snappy** — every level is a
visible jump and levelling gets *cheaper in real terms* as you climb. I would
not touch the damage curve.

What actually makes early play drag is the **entry price**, not the climb:

```
MineConfig.TOOL_CRAFT_BASE = 250        -- proposed: 150
```

250 of one specific ore tier before you own anything is a long first errand at
tier 1–3 drop rates. **150** keeps the same ladder shape and cuts the wait to
first forge by 40%.

Second, the gap the tutorial leaves:

```
MineConfig.WOOD_PICK_MAX_LEVEL = 5      -- keep
MineConfig.WOOD_PICK_COIN_GROW = 1.55   -- proposed: 1.40
```

1.55^4 means the last starter level costs 5.8× the first. **1.40** makes it
3.8× — the errand still ends, it just stops stalling right before the stone pick
handover.

Both are one-line changes and neither touches the late game.

---

## 4. PROPOSED — the enchant roster, stated once

What a player can roll, after the split. Weights are `MineStats.weight`.

### Proc chance — *how often*

| stat | label | weight | effect |
|---|---|---|---|
| `oreYield` | Blast Chance | 4.0 | death also hits 6 neighbours |
| `earthquake` | Earthquake Chance | 2.6 | block shakes, bleeds 5s |
| `zap` | Zap Chance | 2.5 | chains up to 6 hops |
| `ricochet` | Ricochet Chance | 2.4 | one jump, never chains |

### Proc damage — *how hard*

| stat | label | weight | effect |
|---|---|---|---|
| `procPower` | Proc Power | **3.0** | scales all four, capped +300% |

### Luck, split three ways (shipped `c4ca8c4`)

| stat | weight | channel |
|---|---|---|
| `luck` | 0.75 (gear) | the shared base — prestige, VIP, pass, skills |
| `oreLuck` | 0.45 | ore-case chance only |
| `packLuck` | 0.40 | pack stamps and the AFK stamp only |
| `chestLuck` | 0.35 | chest spawn |

### Drill-friendly (the standing ask)

A drill *holds* to mine, so `swingRate` is close to dead weight on one, and half
the drill rune pool was built for a swing. Procs fire on a drill's digs like
anything else, so the drill pool now also rolls **`procPower`** and
**`earthquake`** — two stats that are about drilling rather than swinging.

Still open for drills if you want more: a `coolant`-style stat that raises
*sustained* throughput rather than per-hit damage would be the honest answer, but
that is a new mechanic, not a number.

---

## What I need from you

1. **§2 hat sheet** — approve the table, or give me a target multiplier and I
   will fit the curve to it.
2. **§3** — `TOOL_CRAFT_BASE 250 → 150` and `WOOD_PICK_COIN_GROW 1.55 → 1.40`.
   Yes/no each.
3. **`EARTHQUAKE_SEC = 5`** — still my number, not yours. The share is now 0.12
   so a whole quake is 0.60 of a swing; changing the duration changes that total.
4. **Blast still rides `oreYield`** — a stat named for ore quantity doing proc
   chance. Renaming the key is a save migration, so I have not. Worth doing?
