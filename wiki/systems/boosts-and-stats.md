---
title: Boosts and stats
type: system
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - src/ReplicatedStorage/Mine/Shared/MineStats.luau
  - src/ReplicatedStorage/Mine/Shared/MineBoostLayers.luau
  - src/ReplicatedStorage/Mine/Shared/MineCards.luau
  - src/ReplicatedStorage/Mine/Shared/MinePotions.luau
  - src/ReplicatedStorage/Mine/Shared/MineRunes.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - tools/verify/layers.js
  - tools/verify/statkeys.js
  - docs/TODO.md §0.12, §0.16, §0.19, §0.21
  - docs/PROPOSAL.md §0, §A, §C
  - docs/OPEN.md §10
  - docs/BALANCE-MEASURED.md
related: [mining-and-breaking, rebirth-and-skill-tree, pets-and-traits, hats-and-faces, enchantments-runes-and-gear, charms, skins-cases-and-temper, save-data-and-migrations]
---

# Boosts and stats

> Every buff in the game is expressed in one vocabulary of about 25 **stat keys**: mine speed, luck, blast chance and so on. Pets, hats, the skill tree, runes, traits, charms, potions and skins all write into one boost table. That table is computed fresh by `boosts(p)` on the server. The owner's rule for how the sources combine is "two layers, and the second multiplies the first".

## How it works

**The stat roster** is `MineStats.STATS`: 27 keys, each with a label, a description and a `weight` in budget points per +1%.
- **Weights are the canonical price of a stat.** The skill tree, traits, gear and runes all divide by them (`docs/HANDOFF.md` §2.9).
- **`blastRadius` is weighted 18.0** because a blast is a sphere: +50% radius is about 3.4× the blocks (§0.21).
- **`MineStats.STAT_ORDER`** lists the 23 live keys. Four keys are **legacy** and appear nowhere else:
  - `backpack` and `walkSpeed`, retired 2026-10-04;
  - `echo`, paid out as swing rate at `ECHO_TO_SWING`;
  - `autoMine`, paid out as gem find at `AUTO_MINE_TO_GEM`.
- **Restricted stats.** `MineStats.RUNE_ONLY` is blastRadius, reach, coolant and shortFuse. `MineStats.PET_ONLY` is mineSpeed, luckyFind and scrap.

**Stat keys are data.** Keys are saved on runes (`rune.stat`) and gear (`piece.stat`, `piece.stats`) in live player saves.
- **Renaming a key is a save migration** (`docs/START-HERE.md` §4.4).
- **The one rename so far:** `oreYield` became `blastChance` on 2026-10-04. `MineStats.LEGACY_STAT` and `MineStats.canonStat` map the old key on load, and `tools/verify/statkeys.js` guards it.
- **`fossilFind` keeps its key** but means "Ore Finder" (§0.12).

**The boost table.**
- **Starting values.** `MineCards.emptyBoosts` sets multiplier stats to 1, additive stats to 0, and `swingSec` (a *duration*) to 1. `MineCards.ADDITIVE_STATS` lists the additive (chance) stats.
- **How `boosts(p)` builds it** (in `MineServer.server.luau`), in this order:
  1. **Base multipliers.** `MineConfig.prestigeLuck` (+5% luck per rebirth). VIP ×1.05 luck. The sell haste: ×1.08 mineSpeed for 20 s after a sale. Event-pass bonuses inside Event Horizon.
  2. **Layer 1 (`T1`).** The trait on the held ore tool (`Dig.Traits`), plus the skill tree's `mineSpeed`, `dirtBreak`, `walkSpeed`, `luck` and `rareOre`.
  3. **Layer 2 (`T2`).** `Dig.layer2`: pets (`MineGear.stackPets`) plus worn hats and face, counted once (`MineGear.flatBoost`).
  4. **Combine.** `MineBoostLayers.apply` computes `base × (1 + T1) × (1 + T2)` per stat. Additive stats are summed, not layered. The owner's example: 100 → **300**, not 250 (`tools/verify/layers.js` asserts it).
  5. **Applied outside both layers:**
     - the rest of the tree's stats;
     - relics and charter;
     - runes in gear, tool, chest-tool, shop-tool and pet sockets, plus rune set bonuses;
     - the equipped charm (`MineCharms.applyEquipped`);
     - world events (`MineWorldEvents.foldBoosts`);
     - potions (`MinePotions.applyBoosts`);
     - the tool's skin or temperament (`MineTemper.applyTemper`).
  6. **Folds and floors.** Echo is folded into swing rate and autoMine into gem find, and the auto-mine licence is applied. Then `MineRunes.clampBoosts` applies **floors only**: additive stats ≥ 0, multipliers ≥ 0.05, `swingSec` ≥ 0.05.

**The three luck channels** (TODO 6.2). Generic `luck` remains the shared base that prestige, VIP, the pass, skills, runes and the Umbra set feed. Two channel stats multiply on top of it, and chest luck reuses an existing stat:

| channel | formula | what it moves |
|---|---|---|
| ore luck | `Dig.oreLuck` = luck × oreLuck | ore-case chance, `ORE_CASE_CHANCE 0.02 × max(1, …)` |
| chest luck | luck decides *if* a chest spawns (`rollKind`); luck × `chestLuck` decides *which* | chest spawns and chest loot |
| pack luck | `Dig.packLuck` = luck × packLuck | stamped on a pack row when you get it, then siphons its card odds when you open it |

**Caps.** `MineStats` states "No magnitude caps", and `clampBoosts` only floors. The real limits are applied where each stat is used:
- blast, ricochet and earthquake chances are clamped to ≤ 1 in `Dig.procsAt`;
- zap is deliberately not clamped;
- `procPower` ≤ `MineConfig.PROC_POWER_CAP 3.0`;
- the forever-tool power cap is `foreverPowerCap`;
- rune fusing has a ceiling (`MineRunes.FUSE_CEILING_MULT`).

**Potions** are `MinePotions.DEFS`: 25 potions, 5 stats × 5 tiers.
- **Stats:** Haste → mineSpeed, Power → dirtBreak, Fortune → luck, Purse → coinBonus, Haul → `backpack`.
- **Tiers:**

  | tier | boost | duration | stardust price |
  |---|---|---|---|
  | Sip | +30% | 5 min | 40 |
  | Vial | +60% | 5 min | 90 |
  | Flask | +120% | 10 min | 220 |
  | Tonic | +240% | 10 min | 520 |
  | Elixir | +400% | 15 min | 1,400 |

- **Drinking.** Drinks of the same stat queue, strongest first (`drinkPotion` → `MinePotions.applyBoosts`). They multiply outside the layers.
- **Sources:** packs, quests, offers and scrolls (§0.27).

## Where it lives
| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineStats.luau` | stat roster, weights, migration | `MineStats.STATS`, `MineStats.STAT_ORDER`, `MineStats.LEGACY_STAT`, `MineStats.canonStat`, `MineStats.TYPE_KITS` |
| `src/ReplicatedStorage/Mine/Shared/MineBoostLayers.luau` | the two-layer rule | `MineBoostLayers.LAYER1`, `MineBoostLayers.LAYER2`, `MineBoostLayers.apply` |
| `src/ReplicatedStorage/Mine/Shared/MineCards.luau` | empty table, additive list | `MineCards.emptyBoosts`, `MineCards.ADDITIVE_STATS`, `MineCards.foldSwingRate` |
| `src/ServerScriptService/Mine/MineServer.server.luau` | the fold | `boosts`, `Dig.layer2`, `Dig.oreLuck`, `Dig.packLuck` |
| `src/ReplicatedStorage/Mine/Shared/MineRunes.luau` | floors, rune pools | `MineRunes.clampBoosts`, `MineRunes.FAMILY_STATS`, `MineRunes.NO_ROLL_STATS` |
| `src/ReplicatedStorage/Mine/Shared/MinePotions.luau` | potions | `MinePotions.DEFS`, `MinePotions.applyBoosts` |

## Decided by the owner
- **Two boost layers.** Owner, 2026-10-04: *"skills+skins+tools+traits are the very bottom … equipment+pets are #2"*. Inside a layer, sources add; the layers multiply each other. Chance stats are never layered (§0.19).
- **Prestige, VIP and the pass are in neither layer** (PROPOSAL line 32).
- **Proc chance and proc damage are separate stats** (§0.16).
- **Retirements and weights.** `backpack` and `walkSpeed` are retired, and `blastRadius` is weighted 18 (§0.21).
- **Approved boost numbers** (PROPOSAL §0 lines 1–8; anchors in §A and `docs/BALANCE-MEASURED.md`):
  - hats 16…80 and faces 20…100;
  - pets 34…150, with the variant stack bringing a perfect Exotic to 375;
  - blast chance on at most 15% of pets.
  - **Not yet built** (Layer 2 tables still differ; see [hats-and-faces](hats-and-faces.md), [pets-and-traits](pets-and-traits.md)).
- **Line 30 is not done either.** It said to regenerate `MineStats.TYPE_KITS` from the elements. The table still lists `backpack`, `walkSpeed` and `fossilFind`, which leaves 193 pets with a dead stat.

## State right now
- The two layers are **only partly wired** (`docs/OPEN.md` §10).
  - **Skins and tools** never enter `T1`: the skin is applied afterwards through `MineTemper.applyTemper`, and tools are not read at all.
  - **The skill filter** passes 5 keys out of the ~20 the tree grants.
  - So Layer 1 really holds the trait plus those five keys.
- Never run in engine (START-HERE §5).

## Gotchas
- **Line 37 was superseded before it was approved.** PROPOSAL §0 line 37 says "keep the `oreYield` key", but the key had already been renamed, with a migration, in `eb973f6` (2026-10-04). §0.16 still says "CHANCE stays on oreYield".
- **PROPOSAL §C is wrong about procPower's sources.** It says Space is its only source and no pet or gear grants it. In code, pet, pickaxe, explosive and drill rune pools roll it (`MineRunes.FAMILY_STATS`), the `Violent` trait grants it (`MineTraits`), and `MineGear.STAT_WEIGHT` prices it.
- **"Retired" `backpack` is still live.** It is still read by `cap(p)`, and Haul potions still raise it. The `MineStats` comment "they now simply never move off 1" is not true for potions.
- **Stale descriptions.**
  - `MineStats` descriptions: zap "up to 6 hops" (it is 16), earthquake "Does not stack" (it does), gemFind "dropped by ore" (it only applies to chests).
  - The `MineSkillData` header promises caps that do not exist.
- **Additive-stat lists are duplicated** in `MineCards.ADDITIVE_STATS`, an inline `ADDITIVE_BOOST` in `boosts`, `MineRunes.clampBoosts` and `MinePotions.applyBoosts`. They have drifted: the potions list lacks `procPower` and `earthquake`.

## Open questions
- Wire skins and tools into `T1`, and widen the skill filter (`docs/OPEN.md` §10).
- Hats as chest drops, drill-friendly boosts and overlap guardrails (§10). Gear sets on the new luck channels (PROPOSAL line 29).

## See also
[pets-and-traits](pets-and-traits.md) · [hats-and-faces](hats-and-faces.md) · [enchantments-runes-and-gear](enchantments-runes-and-gear.md) · [charms](charms.md) · [skins-cases-and-temper](skins-cases-and-temper.md) · [rebirth-and-skill-tree](rebirth-and-skill-tree.md) · [save-data-and-migrations](../code/save-data-and-migrations.md)
