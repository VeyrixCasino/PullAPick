# PROPOSAL — every open number, decided

Owner, 2026-10-05: *"do all things i have to do.. propose numbers, thats it.."*

Every number below is derived from the live modules, with the arithmetic shown.

---

# APPROVED 2026-10-05 — these are decisions, not proposals

The owner pasted §0 back **unchanged**. Every line is signed off and is to be
built as written. Do not reopen one without the owner saying so; the reasoning
for each is in the section under it.

**Two lines came back truncated by the paste, not edited.** The `PITY / DROPS`
header, all of line 26, and line 27's label were lost, leaving an orphaned
`NONE (your own rule); optional soft-pity OFF` — which is line 27's value,
intact. Since every other line matched character-for-character, 26 and 27 stand
as written. Flagged to the owner; correct here if that reading is wrong.

Implementation order, hardest constraint first:

1. **The three code bugs** — 21 (chest coin crash), 14 (`ORE_REACH` unwired),
   and seam pricing from §H1. Bugs, not balance; no regeneration needed.
2. **The generated rosters** — 3–8 and 30. `MinePetBoosts` is generated from
   `roster/pets.txt` + `tiers.txt`, and `MineStats.TYPE_KITS` has to be
   regenerated first or the 193 dead stat lines come straight back.
3. **The flat tables** — 1–2 (`MineGear.SHEET`), 29 (gear sets), 9–12, 15–20,
   23–25, 28.
4. **New systems** — 26 (pack pity) is the only line that needs state that does
   not exist yet: a per-player pull counter.
5. **38** (`_c.luau` delete) last, so nothing is chasing a moving file.

---

# 0. THE APPROVED BLOCK

```
BOOSTS
 1. hat ladder (F..SSS)       16 20 25 32 40 51 64 80       (today 30..350)
 2. face ladder (F..SSS)      20 25 32 40 50 63 79 100      (today 15..175)
 3. pet, Normal/PL1 (Com..Exo) 34 39 46 55 68 89 116 150    (today median 13..621, max 1106)
 4. pet variant stack         Rainbow 1.6 / Shadow 1.25 / PL25 1.25 = x2.5 -> perfect Exotic = 375
 5. blast on pets             blastChance on <=15% of roster (65 of 431, Rare+ only; today 140 = 32%)
 6. blastRadius on pets       keep 26, cap 30
 7. procPower                 no change: cap 3.0, tree 2.06, never on pets or gear
 8. dead pet lines            re-roll 182 backpack -> type secondary, 11 walkSpeed -> mineSpeed

CRAFT / BREAKING / RECYCLE
 9. CRAFT_BLOCKS              30 -> 25
10. CRAFT_DEPTH_SLOPE         4 -> 10        (tier 82 = 122 blocks, was 66)
11. CRAFT_BAND_EASE           keep 0.18
12. WOOD_PICK_COIN_GROW       1.55 -> 1.40
13. breaking dials            keep LAYERS_PER_RUNG 50, ZONE_STEP 1, ORE_POW 2.0, MAX 209
14. ORE_REACH                 keep 15 -- but WIRE IT into MineBreaking (UI promises it, gate ignores it)
15. TOOL_RECYCLE_PCT          0.50 flat -> 0.50 + 0.10 * (tier-1)/81, cap 0.60

GEMS
16. ORE_GEM_SPREAD            1e6 -> 1e4      (top ore 3,000,000 -> 30,000 gems)
17. gemvault / warren         2.5M / 4M -> 60 * gemValue(zone's top ore) each  (tracks the curve)
18. rune fuse                 keep 50 x 3.5^(t-1)
19. trait roll                keep 500 gems flat
20. charm merge               keep 1200 x 1.14^(t-1)

COINS
21. chest coin reward         FIX THE CRASH: coinsFor("dirt", zone, layer) -> Depth.dirtHp(zoneTierOf(zone), layer)
22. rebirth "base 2x coins"   DOES NOT EXIST in code. Nothing to remove.
23. potions                   add a coin price = dust * 40   (Sip 1,600 .. Elixir 56,000); dust stays
24. SEAM_MINUTES              keep 30  (honest once 21 is fixed -- see table)
25. REBIRTH_BASE              keep 7500 x 2.08^(n-1)

PITY / DROPS
26. pack pity                 Mythic+ guaranteed by pull 25, Divine+ by pull 150, per player, resets on hit
27. trait pity                NONE (your own rule), optional soft-pity OFF
28. pack Exotic floor         tier-1 0.02% -> 0.10% (1 in 1000), tier-6 0.21% -> 0.50%

SETS / ELEMENTS / LAYERS
29. gear sets                 tide backpack->reach, prism rareOre->oreLuck, umbra luck->packLuck, canopy blastChance->chestLuck
30. MineStats.TYPE_KITS       regenerate from ENERGIES (still lists backpack/walkSpeed/fossilFind)
31. elements                  DONE -- Ground=earthquake, Electric=ricochet already live. Clear BLOCKED #9.
32. prestige/VIP/pass layer   NEITHER (multiply the final). prestigeLuck +5%/rebirth stays.

CARRIED OVER (unchanged suggested answers)
33. legacy 31 charms          keep the items, kill the three sources
34. VIP 4th seat              leave at three, delete the dead copy
35. big suffixes              keep the formatter's (Vg Uvg Dvg), delete the §0.8 line
36. forge bag                 don't build it
37. oreYield key              keep the key, keep the "Blast Chance" label

CLEANUP
38. _c.luau                   DELETE -- 1,710-line dead copy of MineConfig, required by nothing
```

---

# A. Boost ladders

Your anchor: **SSS hat 80, face 100, pet 375**, Layer 2 ceiling ×15.65
(`3×80 + 100 + 3×375 = 1465`). Measured Layer 1 is ×17.55 on `dirtBreak`
(`docs/BALANCE-MEASURED.md`), so this is near parity. Held.

**Hats and faces** — live table is `MineGear.SHEET`: hat F 30 → SSS 350, face
F 15 → SSS 175, hat exactly 2× face. You want face *bigger* than hat, so the
2:1 inverts. Ladder is geometric, F = one fifth of SSS (`×1.258` a step):

| grade | F | D | C | B | A | S | SS | SSS |
|---|---|---|---|---|---|---|---|---|
| hat | 16 | 20 | 25 | 32 | 40 | 51 | 64 | **80** |
| face | 20 | 25 | 32 | 40 | 50 | 63 | 79 | **100** |

SSS hat goes 350 → 80: a **4.4× nerf**, which is what "nerf hats
substantially" means in numbers.

**Pets** — a pet's boost is `kit base × cardPower`, and `cardPower` is
`RARITY_MULT (Common 1 → Exotic 4.4) × VARIANT_MULT (Rainbow 5.5) × shadow 3 ×
(1 + 0.04 × (powerLevel−1))`, PL cap 25 → **×1.96**. Stacked: `4.4 × 5.5 × 3 ×
1.96 = ×142` over a Common. Measured today on `Rocket` (Exotic, base 2.514):
**+1106% at Normal, +24,800% Rainbow Shadow PL10.** That is the "every other
pet stack pointless" problem, in one pet.

375 has to be the *everything-included* ceiling or the ×15.65 you signed off is
fiction. So the variant stack is compressed to **×2.5** (Rainbow 1.6, Shadow
1.25, PL25 1.25 — shiny and shadow exclusive), and Exotic at Normal/PL1 is
`375 / 2.5 = 150`. The rarity shape keeps `RARITY_MULT` (it is shared with
cards) so Common is `150 / 4.4 = 34`:

| Common | Uncommon | Rare | Epic | Legendary | Mythic | Divine | Exotic | *perfect Exotic* |
|---|---|---|---|---|---|---|---|---|
| 34 | 39 | 46 | 55 | 68 | 89 | 116 | **150** | **375** |

Against today's medians: Common **13 → 34** (commons get better, by design),
Exotic **621 → 150**, Rocket 1106 → 150. The roster compresses 7.4× at the top
and the floor rises 2.6×.

Rule for regenerating `MinePetBoosts` (it is generated from `roster/pets.txt` +
`tiers.txt`): primary stat = the tier number above; secondary = half of it.

# B. Blast distribution, and 193 dead lines

140 of 431 pets (32%) grant `blastChance`; 26 grant `blastRadius`. Cut
`blastChance` to **≤15% (65 pets), Rare or better only** — blast becomes a
mid-tier identity, not a default. Keep the 26 radius pets, cap 30.

While regenerating: **182 pets carry a `backpack` line and 11 carry
`walkSpeed`**, both `legacy = true` in `MineStats` since 2026-10-04. Those lines
do nothing. Re-roll `backpack` → the pet's type secondary, `walkSpeed` →
`mineSpeed`. That is 193 of 431 pets with a dead stat today.

# C. procPower — nothing to change

`procDamage = base × share × (1 + procPower)`, cap 3.0. At `procPower` 0 every
proc is under one swing (blast 0.35, zap 0.45, ricochet 0.60, quake 0.60 over
5s). The only source is the Space wedge of the tree, **+206% maxed** — under the
cap, and it costs a tenth of the tree. No pet or gear grants it. That is exactly
"almost no effect does full damage without a dedicated amplifier". Keep all of
it; just never put `procPower` on a pet or a set.

# D. Craft cost

`TOOL_CRAFT_BASE` in BLOCKED #1 **no longer exists** — craft cost is
`CRAFT_BLOCKS × bandFactor × depthFactor` now. Live: 30, ease 0.18, slope 4.

| | t1 | t21 | t41 | t62 | t82 |
|---|---|---|---|---|---|
| today 30 / slope 4 | 30 | 44 | 58 | 58 | **66** |
| proposed 25 / slope 10 | 25 | 64 | 96 | 103 | **122** |

First forge a minute faster; Oganesson tool nearly twice the grind. Upgrades add
their own increasing cost on top, which is where "endgame tools are a real
grind" actually lives. `WOOD_PICK_COIN_GROW` 1.55 → 1.40 stands from BLOCKED #1.

# E. Gems

Ore sells for gems: `ORE_GEM_BASE 3 × work^k`, scaled so the top ore is
`ORE_GEM_SPREAD` × the bottom. At **1e6 an Oganesson is 3,000,000 gems** — one
block of it buys the Gem Vault (2.5M). That is why the flat tables "get outrun".

| spread | tier 1 | tier 41 | tier 82 |
|---|---|---|---|
| 1e6 (today) | 3 | ~3,000 | 3,000,000 |
| **1e4** | 3 | ~300 | **30,000** |

At 1e4 the sinks read sanely: trait roll 500 = 170 Stone or 2% of an Oganesson;
rune fuse T6 26k ≈ 1 Oganesson, T10 3.9M ≈ 130 (aspirational, correct); charm
merge t24 24,600 ≈ 1. Gem Vault / Warren become **60 × gemValue of the zone's
top ore** so they move with the curve instead of sitting on 2.5M / 4M.

You deferred this one. It is proposed anyway because every other gem number
above is meaningless until it is set.

# F0. Breaking power — the curve IS specified

`docs/OPEN.md` said "the curve is the one number still unspecified". It is in
`MineBreaking.luau`: `LAYERS_PER_RUNG 50`, `ZONE_STEP 1`, `ORE_POW 2.0`,
`MAX 209`. Layer strength `1 + (zone−1) + ⌊(layer−1)/50⌋`; ore strength
`1 + round(((t−1)/81)² × 208)`; a block needs the *harder* of the two; a forged
tool has its ore's strength. What that gives:

| tool tier | BP | zone 1 reaches | zone 5 | zone 10 |
|---|---|---|---|---|
| 1 | 1 | layer 50 | — | — |
| 10 | 4 | 200 | — | — |
| 20 | 12 | 600 | 400 | 150 |
| 41 | 52 | 2,600 | 2,400 | 2,150 |
| 62 | 119 | 5,950 | 5,750 | 5,500 |
| 82 | 209 | 10,000 | 10,000 | 10,000 |

Shop picks are BP 1–5: 250 layers in zone 1, and zone 5's surface needs BP 5 —
"the shop takes you sideways, forged tools take you down." Keep all four dials.

**One real bug.** `MineConfig.ORE_REACH = 15` is your rule ("a tool reaches
+15 tiers of ore") and `MineConfig.canBreakOre` shows it in the UI. **The live
gate never reads it.** `oreStrength` is monotonic, so a tier-T tool breaks ore
up to tier T only. The UI promises +15, the server gives +0. Fix: evaluate
`oreStrength(max(1, oreTier − ORE_REACH))` in `blockStrength`. Keep 15.

# G. Recycle

`TOOL_RECYCLE_PCT 0.50` flat. You asked for "50% plus a value-scaled extra,
decent but not game breaking": `0.50 + 0.10 × (tier−1)/81`, cap 0.60. Stone
tool 50%, Oganesson 60%.

# H1. Coins — the crash, and the multiplier that doesn't exist

**The crash.** `rollChestLoot` (`MineServer:4726`) calls
`C.coinsFor("dirt", zone, layer)`. `MineConfig.coinsFor` takes `(kind, mult)`
and does `base × mult`. `zone` there is a **table** — `zoneTierOf(zone)` reads
`zone.id` four lines up — and this Luau build throws on `number × table`
(reproduced: *"attempt to perform arithmetic (mul) on number and table"*). So
**every chest that rolls the `coins` reward errors out** before paying. That
is one of the lucky-block / chest bugs you reported, found by arithmetic. One
line: `Depth.dirtHp(zoneTierOf(zone), layer)` — the same 1-coin-per-HP rule
the dig path already uses (`:5531`).

**The multiplier.** You asked to "remove base 2× coins from rebirths". Searched
every `prestige`, `rebirth`, `coinMult`, `2 ^` path on server and shared:
**there is no coin multiplier on rebirth.** Prestige gives `+5% luck` per
rebirth and skill points. Nothing to remove.

**The model.** Coins already are *access*: seams (30 min of band income),
rebirth (`7500 × 2.08^(n−1)`: R1 7,500 · R3 32,400 · R5 140k · R10 5.47M),
shop tools (`power × 800`). Dig pays 1 coin per HP, so income follows
`dirtHp = (20 + 1.5L) × 5^(z−1)`. Seam pricing uses `gateCoinValue`, a
*different* curve — the table shows what that costs:

| seam | price (z1) | hours at live payout | hours if payout = gate curve |
|---|---|---|---|
| 500 | 14,428 | 2.4 | 0.50 |
| 1000 | 38,109 | 6.4 | 0.50 |
| 2500 | 101,546 | 16.9 | 0.50 |
| 5000 | 189,008 | 31.5 | 0.50 |

**Seams cost 5–60× the 30 minutes they were priced at** because the payout
curve and the price curve are not the same function. Fix: price seams off
`dirtHp`, the curve players are actually paid on. Then `SEAM_MINUTES 30` is
honest and stays.

*Consumables*: potions are dust-only today (Sip 40 … Elixir 1,400). Add a coin
price at **dust × 40** (1,600 … 56,000), keep dust as the alternative. That is
the coin sink you asked for, without touching ore or gems.

# I. Pity and drop tables

Packs come from chests only (~20 chests/hour at `CHEST_CHANCE 0.003`, ~5% carry
a pack → **~1 pack/hour early**). Exotic is 0.02% in a tier-1 pack: **1 in
5,000 — 5,000 hours.** That is not rare, it is absent.

- Exotic floor **0.10% at tier 1 (1 in 1,000), 0.50% at tier 6** — your own
  "exotic should be 1 in 1000" instinct, applied to packs.
- Pity: **Mythic-or-better guaranteed by the 25th pull, Divine-or-better by the
  150th**, per player, reset on hit. Cheap to track, kills the dead streak.
- Traits: **no pity.** Your words — *"broke players aren't going to try to get
  exotic V, endgame players will."* The 500-gem flat price is the self-regulating
  sink. A soft pity (SSS weight 10 → 20 after 500 misses) is written up but
  **off** unless you say otherwise.

"New drop tables" was never defined; this is my reading. If you meant the
chest→pack table instead, say so.

# J. Gear sets

`tide` rolls `backpack` — **retired, so Tide is a dead set.** Three of the ten
sets move to the new lucks you asked for; blast leaves gear entirely, consistent
with fewer blast sources:

| set | today | proposed |
|---|---|---|
| tide | backpack | **reach** (Water's new identity) |
| prism | rareOre | **oreLuck** |
| umbra | luck | **packLuck** |
| canopy | blastChance | **chestLuck** |

# K. Elements — done, and one stale table

`MineSkillData.ENERGIES` already has Ground → `earthquake`, Electric →
`ricochet`, and all 75 nodes were regenerated. **BLOCKED #9 is cleared.**

But `MineStats.TYPE_KITS` (`:178–181`) — the table *pets* draw their kits from
— still lists `backpack`, `walkSpeed` and `fossilFind` for Fire/Frost/Water/
Grass. That is the source of the 193 dead pet lines in §B. Regenerate it from
`ENERGIES`.

# L. Prestige / VIP / event pass

**Neither layer.** They multiply the final. Putting them in Layer 2 makes your
×15.65 ceiling climb with every rebirth; in Layer 1 it dilutes the tree.
`prestigeLuck` stays.

# O. A calibration note, not a change

Maxing the tree costs 1,355 points; rebirth `n` grants `2 + ⌊(n−1)/2⌋`.
Cumulative: **R10 = 3% of the tree, R30 = 20%, R50 = 52%, R70 = 98%.** So the
measured ×17.55 Layer 1 is a rebirth-70 ceiling. Early, Layer 2 (pets) is the
whole game; late, the tree catches up. That is a good shape. Stated so nobody
"fixes" it.

# P. Cleanup with a number

`src/ReplicatedStorage/Mine/Shared/_c.luau` is a **1,710-line copy of
MineConfig**, required by nothing, last touched in the `oreYield` rename. It
carries its own `ORES`, `STARTER_PET_SLOTS`, `coinsFor`. Delete it before it
becomes a third source of truth.
