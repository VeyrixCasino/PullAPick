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
