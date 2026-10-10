---
title: Rebirth and skill tree
type: system
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ReplicatedStorage/Mine/Shared/MineSkillData.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - tools/skills/gen.js
  - tools/verify/skilltree.js
  - docs/SKILL-TREE.md
  - docs/TODO.md §0.19, §0.20, §0.21, §0.27, 6.1 Rebirth
  - docs/PROPOSAL.md §0 lines 22, 25, 31, 32
  - docs/OPEN.md §10, §14
related: [boosts-and-stats, currencies-and-economy, zones-layers-and-seams, skins-cases-and-temper, forge-and-recycling, save-data-and-migrations]
---

# Rebirth and skill tree

> **Rebirth and prestige are the same thing.** "Rebirth" is the player-facing word. `prestige` is the code word: the `"prestige"` action, `tryPrestige`, and the `p.prestige` count. A rebirth spends coins, wipes the run (wallet, depth, seams, coin-ladder tools), and pays out skill points, tokens, gems and +5% luck. You spend skill points on a radial tree of ten elements. The tree is the main permanent power you build across rebirths.

## How it works

**What a rebirth costs.** You send the `"prestige"` action, which calls `tryPrestige`.
- **The fee is coins only:** `MineSkillData.rebirthCost(n) = 7500 × 2.08^(n−1)`, rounded to three significant figures. Examples:

  | rebirth | fee (coins) |
  |---|---|
  | R1 | 7,500 |
  | R2 | 15,600 |
  | R3 | 32,400 |
  | R5 | 140,000 |
  | R10 | 5.47M |
  | R20 | 8.28B |

- **Recommended bank (advisory only).** `MineSkillData.minRebirthCoins` = fee × `rebirthRatio`, where the ratio is 2.65 at R1 and decays toward 1.55. Rebirthing below it only shows an "Early rebirth" toast. `rebirthAdvice` feeds the UI.

**What a rebirth does to the profile.** `fresh = blank()`, so everything resets unless it is explicitly carried.
- **Resets:**
  - coins (the leftover goes to **0**, not just the fee);
  - `deepest`, `seams` and `depthUnlock`;
  - the bag and haul;
  - the coin-ladder tools (`pickaxeTier`, `tools`) and `backpackTier`;
  - the current zone (back to meadow).
- **Carried by `tryPrestige`:**
  - cards, equipped pets, stardust and packs;
  - relics, charter, chest tools and `found`;
  - `maxUnlockedZone`, `bigbangOwned` and core samples;
  - skill fields (`skillEarned`, `skillBought`, presets, `skillBurned`) and `temperTokens`;
  - **forged ore tools** (`oreTools`, `oreToolEquipped`);
  - runes, gear, sockets, charms, `tempers` and `toolTempers`;
  - **the whole ore pouch** (tier, ores, locks, `oresSeen`);
  - gems, credits, scrolls, dailies, pass and stats.
- **Also carried:** the `Verbs.KEEP_ON_REBIRTH` list (tutorial flags, codes, receipts, owned pets, potions, VIP, `shopToolRunes`, settings…).

**What a rebirth pays.**
- **Skill points:** `MineSkillData.tokensFor(n) = 2 + ⌊(n−1)/2⌋`, so 460 points over 40 rebirths.
- **Temper tokens:** `MineSkillData.rebirthTokens(n) = tokensFor(n) × 30`.
- **Gems:** `MineSkillData.rebirthGemReward = (150 + 50(n−1)) × (1 + 0.6(zone−1))`.
- **Luck:** `MineConfig.prestigeLuck = 1 + 0.05·prestige`, multiplied onto `b.luck` before the boost layers ([boosts](boosts-and-stats.md)).
- **Zone eligibility:** the `minRebirth` column ([zones](zones-layers-and-seams.md)).
- **Forever-tool cap:** the power cap on forever tools is ×1.20 per rebirth (`foreverPowerCap`, which reads `p.stats.rebirth`).
- **After the rebirth** the profile saves immediately, you are teleported to the Clouds, and the skills panel opens.

**The skill tree** is `MineSkillData`.
- **Elements.** `MineSkillData.ENERGIES` has ten elements, 36° apart. Each has a verb and a primary / secondary / tertiary stat:

  | element | verb | primary | secondary | tertiary |
  |---|---|---|---|---|
  | Fire | Blast | blastRadius | mineSpeed | swingRate |
  | Frost | Endurance | swingRate | dirtBreak | mineSpeed |
  | Water | Flow | coolant | reach | coinBonus |
  | Grass | Harvest | blastChance | pulverize | dirtBreak |
  | Ground | Excavate | dirtBreak | earthquake | blastChance |
  | Metal | Refine | coinBonus | blastChance | shortFuse |
  | Electric | Zap | zap | ricochet (Shatter) | swingRate |
  | Crystal | Prospect | rareOre | gemFind | oreLuck |
  | Shadow | Fortune | luck | chestLuck | packLuck |
  | Space | Echo | procPower | gemFind | luck |

- **75 nodes in `MineSkillData.NODES`.** Each element has a `root` (5 ranks), two `split` nodes that form an XOR **road** (`xorGroup`), two `cross` nodes, and a `key`. Then come 10 `fuse` nodes between neighbouring elements and 5 `cap` nodes. The paired keys are **rivals** (`MineSkillData.RIVALS`): Fire–Metal, Frost–Electric, Water–Crystal, Grass–Shadow, Ground–Space. `MineSkillData.blockedBy` enforces roads, rivals and prereqs.
- **How a node's stats are priced.** Each node is worth `points` of MineStats budget, split 50/30/20 across the element's three stats and divided by each stat's weight. `tools/skills/gen.js` re-prices `stats` only (`--check` reports drift); the tree's shape is never touched. TODO §0.21 records the spread between the best and worst road going from 2.44× to 1.001×.
- **Price inflation.** `MineSkillData.inflation = 1 + 0.05·owned nodes + 0.015·levels`. Maxing the tree costs `maxTreePoints` 1,355 points.
- **The rules.**
  - You edit the tree only **in the Clouds** (`MineSkillData.canEdit`, `MineConfig.playerInClouds`).
  - There are 2 presets, and the second slot costs 25 points.
  - **Reset is free** and refunds exactly what you spent.
  - You can sell a point for 30 temper tokens, and buy it back for 30 tokens (only a point you sold).
  - Verbs: `Verbs.skillBuy`, `Verbs.skillPreset`, `Verbs.skillBuySlot`, `Verbs.skillReset`, `Verbs.skillSell` (alias `skillSacrifice`), `Verbs.skillBuyBack`.
- **How the server applies it.** `MineSkillData.totalStats` sums the tree. In `boosts()`, only `mineSpeed`, `dirtBreak`, `walkSpeed`, `luck` and `rareOre` enter **Layer 1**. Every other stat is applied directly, outside the layers. `tools/verify/skilltree.js` fails if the tree grants a stat that the server never reads.

## Where it lives
| file | role | key symbols |
|---|---|---|
| `src/ServerScriptService/Mine/MineServer.server.luau` | the rebirth, the skill verbs, applying the tree | `tryPrestige`, `blank`, `Verbs.KEEP_ON_REBIRTH`, `skillState`, `boosts`, `foreverPowerCap` |
| `src/ReplicatedStorage/Mine/Shared/MineSkillData.luau` | the tree data and the rebirth curve | `MineSkillData.ENERGIES`, `MineSkillData.NODES`, `MineSkillData.rebirthCost`, `MineSkillData.tokensFor` |
| `src/ReplicatedStorage/Mine/Shared/MineSkillView.luau` | the tree UI | — |
| `tools/skills/gen.js` | the stat re-pricer | `--check` |

## Decided by the owner
- **The elements are the skill tree** (§0.20). Applied changes: the five element swaps, Water rebuilt, and `backpack` / `walkSpeed` retired (§0.21; PROPOSAL line 31 "DONE").
- **"Base 2x coins" from rebirth never existed.** `prestigeYield` has been deleted, and `prestigeLuck` +5% per rebirth stays (§0.27; PROPOSAL lines 22 and 32).
- **Prestige, VIP and the event pass are in neither boost layer.** They multiply the final result (PROPOSAL line 32).
- **`REBIRTH_BASE 7500 × 2.08^(n−1)` is kept** (PROPOSAL line 25).

## State right now
- Shipped, and never run in engine (START-HERE §5).
- `docs/OPEN.md` §14 still has two open items: multiple rebirths at once, and re-deciding "rebirth raises coin value".
- `docs/OPEN.md` §10 still has to widen the Layer-1 skill filter beyond five keys and drop the dead `walkSpeed` entry.

## Gotchas
- **Stale generator note.** `MineSkillData`'s header says "GENERATED by skills/gen.js + skills/emit.js". `tools/skills/gen.js` exists; emit.js is **not in the repo**.
- **`docs/SKILL-TREE.md` is stale.** Its roster table is from before the remap (Water `backpack`, Space `echo`, `oreYield`), and it says no generator exists. The code table above is current.
- **Stale cap note.** The `MineSkillData` header still talks about "MineStats caps from ALL sources". `MineStats` says "No magnitude caps".
- **Stale income note.** The `rebirthCost` comment still cites `prestigeYield` as income growth, but that function has been deleted.
- **Two rebirth counts can drift apart.** `p.prestige` is the authoritative count. `p.stats.rebirth` is a separate stat counter (`bumpStat`) that `foreverPowerCap` reads, and the two can diverge on old saves (unverified).
- **TODO 6.1 says `shopToolRunes` is not carried.** It is carried, through `Verbs.KEEP_ON_REBIRTH`.
- **"Tokens" means two things.** `skillState(p).tokens` is *skill points*. `p.temperTokens` is a separate currency. See [ambiguous-terms](../ambiguous-terms.md).
- **`MineBuild` is not part of this.** It is the Studio build stamp (`MineBuild.STAMP`, `MineBuild.EXPECT`), not a player "build"; see [rojo-and-studio](../code/rojo-and-studio.md).

## Open questions
- Multiple rebirths at once, and whether rebirth should touch coin value (`docs/OPEN.md` §14).
- When the coin wallet is pointless, is a coin-priced rebirth still the right gate? See [currencies](currencies-and-economy.md) and [open-questions](../open-questions.md).

## See also
[boosts-and-stats](boosts-and-stats.md) · [currencies-and-economy](currencies-and-economy.md) · [skins-cases-and-temper](skins-cases-and-temper.md) · [save-data-and-migrations](../code/save-data-and-migrations.md)
