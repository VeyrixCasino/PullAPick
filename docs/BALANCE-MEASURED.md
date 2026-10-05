# Measured boost ceilings — 2026-10-05

Read off the live modules, not estimated. Reproduce with the commands at the
bottom. **Everything here is `dirtBreak`**, because that is this game's damage
stat — there is no stat called `damage` anywhere in the codebase.

---

# The headline

| layer | sources measured | ceiling on `dirtBreak` |
|---|---|---|
| **Layer 1** | skill tree (all 75 nodes maxed, xor-aware) + the equipped tool's trait | **+1655% → ×17.55** |
| **Layer 2** | 3 hats @ +80%, 1 face @ +100%, 3 pets @ +375% (owner, 2026-10-05) | **+1465% → ×15.65** |

`final = base × (1 + L1) × (1 + L2)` → **×274.7** at both ceilings.

**The two layers are at near parity, tilted slightly toward Layer 1.** The owner's
80/100/375 budget is sound. An earlier recommendation of a ×3.0 Layer-2 ceiling
was wrong — it assumed Layer 1 topped out near ×4 without measuring it.

Both figures are theoretical maxima. Layer 1 assumes every node maxed, which the
skill-point budget does not allow; Layer 2 assumes three SSS pets, three SSS hats
and an SSS face. Ceiling-against-ceiling is still the fair comparison.

---

# Layer 1, broken down

### Skill tree — `MineSkillData.luau`, 75 nodes
Summed as `stat × maxLevel` per node. "xor-aware" takes only the better road in
each `xorGroup`, since those are mutually exclusive.

| stat | all nodes maxed | xor-aware |
|---|---|---|
| `dirtBreak` | +1253.0% | **+1205.4%** |
| `mineSpeed` | +634.9% | +587.3% |
| `luck` | +398.8% | +398.8% |
| `rareOre` | +343.4% | +343.4% |
| `walkSpeed` | +0.0% | +0.0% |

### The equipped tool's trait — `MineTraits.luau`
`amount = perLevel × level × rarityMult`, and `perLevel = BUDGET / weight`
clamped to `[PER_MIN, PER_MAX]`.

```
BUDGET 0.12  /  dirtBreak weight 1.0  = 0.12 per level
0.12 × level 5 × SSS 7.50             = 4.50  → +450%
```

`Churning` is the only `dirtBreak` trait of the 23. One trait, on the tool in
your hands, so this is not multiplied by anything.

**Layer 1 total: 1205.4 + 450 = +1655.4% → ×17.55**

---

# Three gaps that make this an UNDER-count

The owner's spec was *"skills+skins+tools+traits are the very bottom"*. Only two
of those four reach Layer 1.

**1. Skins do not enter Layer 1.** `MineTemper.applyTemper(b, ct)` writes
straight onto the boost table (`MineServer:2578` and `:2593`), outside both
layers. A skin therefore multiplies the base directly instead of adding into L1.

**2. Tools do not enter Layer 1 either.** Nothing adds a tool's own contribution
to `T1`. There are exactly four `Layers.add` calls in the whole server:

| line | layer | source |
|---|---|---|
| `MineServer:2298` | 2 | pets (`Gear.stackPets`) |
| `MineServer:2302` | 2 | hats + face (`Gear.flatBoost`) |
| `MineServer:2364` | 1 | the equipped tool's trait |
| `MineServer:2385` | 1 | skills, filtered to five keys |

**3. The Layer-1 skill filter passes five keys and the tree grants twenty.**
`MineServer:2383` filters to `mineSpeed, dirtBreak, walkSpeed, luck, rareOre`.
These sixteen bypass both layers and multiply on the base:

| stat | tree total | stat | tree total |
|---|---|---|---|
| `coinBonus` | +996.8% | `reach` | +325.4% |
| `swingRate` | +697.8% | `blastChance` | +313.3% |
| `gemFind` | +506.0% | `coolant` | +247.3% |
| `zap` | +247.3% | `chestLuck` | +207.1% |
| `procPower` | +206.0% | `ricochet` | +189.8% |
| `earthquake` | +175.2% | `pulverize` | +113.9% |
| `shortFuse` | +81.5% | `oreLuck` | +74.8% |
| `packLuck` | +74.8% | `blastRadius` | +34.4% |

`swingRate` at +698% is the biggest throughput stat in the game and it is
outside the layer system entirely. `procPower` at +206% sits under its
`PROC_POWER_CAP` of 3.0, so proc builds are reachable but not maxed by the tree
alone.

**`walkSpeed` is a dead key in that filter** — it is listed, and no skill node
grants it (+0.0%). Consistent with the owner's "remove walkspeed as a boost";
the filter entry is vestigial and can go.

---

# Reproduce it

```bash
# Layer 1 skill sums, xor-aware, and the bypass list
node -e '<the script in this commit message>'

# trait magnitude
grep -n 'BUDGET\|PER_MIN\|PER_MAX' src/ReplicatedStorage/Mine/Shared/MineTraits.luau
grep -n 'dirtBreak' src/ReplicatedStorage/Mine/Shared/MineStats.luau   # weight 1.0
grep -n 'RARITY_MULT' -A4 src/ReplicatedStorage/Mine/Shared/MineTemper.luau

# every write into a layer
grep -n 'Layers.add' src/ServerScriptService/Mine/MineServer.server.luau
```

---

# What follows from this

- **Approve 80 / 100 / 375.** It lands Layer 2 at ×15.65 against a measured
  Layer 1 of ×17.55.
- **Closing the three gaps raises Layer 1, not Layer 2.** Wiring skins and tools
  into `T1` and widening the five-key filter all push L1 above ×17.55, which
  makes the owner's Layer-2 numbers *more* conservative over time, not less.
- **Do not renumber `PROC_SHARE` or `EARTHQUAKE_SEC`.** At `procPower` 0 every
  proc is already under one swing (blast 0.35, zap 0.45, ricochet 0.60, quake
  0.60 over its 5s life). The 8.4× blast exists only at the `procPower` cap, and
  that cap is the dedicated amplifier the owner asked for. The blast problem is
  **how many pets grant it**, not how hard it hits.

---

# The forge ladder — how far reach 5 actually takes you

Owner, 2026-10-05: *"how far can this pattern take us"*. Measured by walking the
climb: hold a tier-T tool, take the best ore it can break, forge that, repeat.

**Reach 5 is a 16-forge climb from Stone to Oganesson**, and the steps are
almost perfectly even:

| # | forge | unlocks up to | gain |
|---|---|---|---|
| 1 | t1 Stone | t9 Slate | **+8** |
| 2 | t9 Slate | t14 Ember | +5 |
| 3 | t14 Ember | t19 Iron | +5 |
| 4 | t19 Iron | t24 Rime | +5 |
| 5 | t24 Rime | t29 Onyx | +5 |
| 6 | t29 Onyx | t34 Turquoise | +5 |
| 7 | t34 Turquoise | t39 Lapis | +5 |
| 8 | t39 Lapis | t44 Jade | +5 |
| 9 | t44 Jade | t49 Obsidian | +5 |
| 10 | t49 Obsidian | t54 Emerald | +5 |
| 11 | t54 Emerald | t59 Aquamarine | +5 |
| 12 | t59 Aquamarine | t64 Starmetal | +5 |
| 13 | t64 Starmetal | t69 Frostfire | +5 |
| 14 | t69 Frostfire | t74 Mythril | +5 |
| 15 | t74 Mythril | t79 Plutonium | +5 |
| 16 | t79 Plutonium | t82 Oganesson | **+3** |

The +8 at the start is the bottom of the `ORE_POW` curve being flat — several
early ores need the same breaking power, so the first forge is a free jump. The
+3 at the end is the same curve steepening: near the top one tier is worth ~5
rungs, so the reach stops buying much. Neither is a special case in the code.

**The same climb in a zone you have already cleared (reach 15) is 6 forges** —
Stone → Iron → Turquoise → Obsidian → Starmetal → Plutonium → Oganesson. That
is the point of the split: forward is sixteen deliberate steps, backward is a
mop-up.

## Reach against climb length

| reach | forges | |
|---|---|---|
| 0 | **deadlocks at tier 4** | not a setting |
| 1 | 73 | |
| 2 | 38 | |
| 3 | 26 | tighter, if 16 milestones feels thin |
| 4 | 19 | |
| **5** | **16** | **chosen** — round number, dead-even steps |
| 6 | 13 | |
| 8 | 10 | |
| 10 | 8 | |
| 15 | 6 | cleared zones |
| 20 | 4 | |

## Calibration

16 forges is the entire tool progression. Against `docs/ROADMAP.md` (first 15
minutes out to 96 hours) that is **roughly one major tool upgrade every 5–6
hours**, and it front-loads: the first step is +8 and low-tier ore is cheap
(25 blocks at tier 1 against 122 at tier 82, approved lines 9–10), so expect
four or five forges in the first couple of hours and a widening gap after.

That shape is intended. Flagged here so nobody reads the sparse late game as a
bug and "fixes" the reach.
