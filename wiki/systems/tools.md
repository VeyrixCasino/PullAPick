---
title: Tools
type: system
status: partial
verified: 2026-10-05 @ 26036a0
sources:
  - src/ReplicatedStorage/Mine/Shared/MineOreTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ReplicatedStorage/Mine/Shared/MineBreaking.luau
  - src/ReplicatedStorage/Mine/Shared/MineShopLadders.luau
  - src/ReplicatedStorage/Mine/Shared/MineBandTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineHorizonTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineToolGrades.luau
  - src/ReplicatedStorage/Mine/Shared/MineHotbar.luau
  - src/ReplicatedStorage/ToolModelFactory.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - docs/TODO.md §0.13
  - docs/TODO.md §0.15
  - docs/PR-BALANCE-PASS.md
related: [ores, forge-and-recycling, mining-and-breaking, skins-cases-and-temper, enchantments-runes-and-gear, chests-and-lucky-blocks, shops-and-monetisation, assets-and-uploads]
---

# Tools

> Pickaxes, drills and explosives. The main tool is now **forged from ore** and
> named after it, for example "Stone Pickaxe". Several older rosters (the coin
> shop, chest flagships, zone shops, Event Horizon) still exist alongside it.
> A tool has **damage**, which grows with level, and **breaking power**, which
> is fixed by its ore. These are two separate gates.

## How it works

**What you are holding.** `equippedTool(p)` in MineServer resolves the tool in
this order:
1. **Event Horizon tool.** In zone `bigbang`, the tool comes from
   `MineHorizonTools` (one per dirt section, paid in space coins).
2. **Forged ore tool.** `p.oreToolEquipped` holds a uid, which points at a row in
   `p.oreTools`: `{uid, typeId, familyId, tier, level, trait?}`. Here `tier` is
   the **ore's index** in `MineConfig.ORES`. The rack holds at most 200.
3. **Chest flagship ("forever tool", the shop's "Secrets" tab).** This is
   `p.chestTool`, looked up in `MineTools.CHEST_TOOLS`, `MineBandTools` (80 band
   tools) or `MineTools.PASS_TOOLS` (3). Flagships are never sold on a shelf.
4. **Zone shop tool.** `p.shopToolId`, from `MineShopLadders`: 19 per zone, 190
   in total.
5. **Coin ladder.** `MineTools.TOOLS` has 25 pickaxes (including `wood_pick`),
   16 drills and 16 explosives. `p.tools[fam]` is the highest rung owned and
   `p.toolTier[fam]` is the rung held. These rows also serve as the **frames**
   for forged tools.
6. `MineConfig.BARE_HANDS`, if no pickaxe has been collected yet.

**Families.** Pickaxe (aim and swing), drill (hold to mine), explosive (throw,
with a cooldown). A weapon family is planned (`MineTools.FAMILIES`). You can
forge in the order given by `MineOreTools.FAMILY_ORDER`.

**Forged tools.** "A forged tool IS its ore" (TODO §0.15):
- **Name** is `{Ore} {Noun}`, plus a trait prefix (`MineOreTools.name` →
  `MineTraits.decorate`).
- **Frame** is never picked. `MineOreTools.frameForTier` derives it by mapping
  ore tier 1..82 proportionally onto the family's priced rungs (24 pickaxe, 16
  drill, 16 explosive).
- **`typeMult`** is the frame's `RARITY_RANK`, which `MineTools.rarityForTier`
  stamps from the rung position.
- **Levelling and recycling** happen at the [Forge](forge-and-recycling.md).

**Levels.** The cap is `MineConfig.TOOL_MAX_LEVEL = 30`, cut from 100 in
commit `d505d6c`. The owner wanted a per-level gain they could advertise (*"each
level UP%X"*). All per-level rates come from `perLevel(total)`:
- **Damage:** `TOOL_DMG_STEP = 350^(1/29) ≈ +22.4%` per level. The whole climb
  is worth `TOOL_CLIMB_DAMAGE 350`, which is one zone's HP growth.
- **Upgrade cost:** `MineConfig.toolUpgradeCost` charges the tool's own ore
  (`TOOL_ORE_BASE 4 × TOOL_ORE_GROW^(L-1)`) plus stardust (`25 ×
  TOOL_DUST_GROW^(L-1)`). Both are multiplied by `toolCostMult`: a bell curve
  peaking at Epic ×18 and lowest at Exotic ×1 (`TOOL_COST_BANDS`), times
  `typeMult^0.5`.
- **Inheritance:** a newly forged tool takes the best level on your rack
  (`12b528a`).
- **Old saves:** levels above the cap are clamped on load under the
  `TOOL_CAP_V` stamp, with no refund.

**Damage.** `MineConfig.toolPower = TOOL_DMG_BASE 10 × toolTierPower(tier) ×
typeMult × STEP^(L-1)`.
- `toolTierPower = 6^(TOOL_TIER_SPAN 7 × (t-1)/81) × TOOL_BAND_DMG[band]`.
- The band bonus is Legendary ×2, Mythic ×4, Divine ×8 and Exotic ×16. It exists
  because tiers 68–82 gain no new ore access at reach 15.
- Finishes on a row multiply power: Shiny ×1.5, Shadow ×3, Nightmare ×4.5
  (`SHINY_MULT` and so on).

**Breaking power** (TODO §0.13 rules 1, 2, 11). Breaking power is never damage.
`MineBreaking.toolBreakingPower` checks, in order:
1. a stamped `breakingPower` or `bp`;
2. otherwise, if the tool has `oreId` or `ore`, it returns `oreStrength(oreTier)`
   on a 1..1000 scale;
3. otherwise it returns `SHOP_POWER[rung]`, where `SHOP_POWER` is `{1,2,3,4,5}`.

**Tutorial wooden pickaxe** (§0.13 rule 10). `Verbs.grantFirstPick` sets
`p.tools.pickaxe = 1` (coin rung `wood_pick`). The constants are
`WOOD_PICK_MAX_LEVEL 5` and `WOOD_PICK_COIN_BASE 35 × WOOD_PICK_COIN_GROW 1.55^(L-1)`.
At the cap, `Verbs._graduateTutorialPick` grants `TUTORIAL_GRADUATION_TOOL =
"stone_pick"`.

**Models and icons.** `givePickaxe` builds the Roblox Tool. Forged tools resolve
their mesh by ore name through `ToolModelFactory.fromNamed`, using
`ReplicatedStorage.ToolModels_50`. That folder is Studio-only, about 80 MB, and
not in git (AGENTS.md). Anything else is procedural, coloured by
`ToolModelFactory.oreLook`. `src/ServerStorage/OreToolBaker.luau` bakes the 82
heads. `MineToolIcons` is a spritesheet atlas for named tools.

**Hotbar and equip.** `MineHotbar` turns off Roblox's Backpack CoreGui (the "grey
cube"). It has up to 5 slots: 1 tool slot (2 for VIP), and the rest for
consumables. Clicking the held slot calls `equipOreTool` with an empty uid,
which unequips. `Verbs.equipOreTool(uid)` sets `p.oreToolEquipped`, clears the
flagship and shop-tool selections, and calls `givePickaxe`.

**Rebirth.** Forged tools, their levels and the equipped one survive. The coin
ladder resets.

## Where it lives

| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineOreTools.luau` | forged naming and frames | `name`, `frameForTier`, `oreOf`, `typeMult` |
| `src/ReplicatedStorage/Mine/Shared/MineTools.luau` | coin ladder, flagships, pass tools | `TOOLS`, `CHEST_TOOLS`, `PASS_TOOLS`, `RARITY_RANK` |
| `src/ReplicatedStorage/Mine/Shared/MineConfig.luau` | level and damage curve | `TOOL_MAX_LEVEL`, `toolPower`, `toolUpgradeCost`, `TOOL_BAND_DMG` |
| `src/ReplicatedStorage/Mine/Shared/MineBreaking.luau` | breaking power gate | `toolBreakingPower`, `SHOP_POWER`, `canBreak` |
| `src/ServerScriptService/Mine/MineServer.server.luau` | what is held, equip | `equippedTool`, `givePickaxe`, `Verbs.equipOreTool` |
| `src/ReplicatedStorage/Mine/Shared/MineHotbar.luau` | custom hotbar | `mount` |

## Decided by the owner

- Ore tier = breaking power; level never raises it; damage is separate (§0.13
  rules 1, 2, 11). Name = `{Ore} {Noun}`; the frame is derived; levelling costs
  the tool's own ore (§0.15). The wooden pickaxe is a 5-level tutorial pick paid
  in coins (§0.13 rule 10).
- Cap 30 (owner, 2026-10-05; `docs/PR-BALANCE-PASS.md` §2).
- **Approved, not applied:** `WOOD_PICK_COIN_GROW` 1.55 → 1.40 (PROPOSAL §0 line
  12).

## State right now

The forged-tool system is shipped, but the breaking-power gate looks broken for
held tools (see below). Nothing here has run in the engine.

## Gotchas

- **Probable P0 bug: every held tool has breaking power 1 at the gate.** The
  table that `equippedTool` returns for a forged tool has no `oreId`, `oreTier`
  or `breakingPower`, and coin-ladder rows have string ids. For both,
  `MineBreaking.toolBreakingPower` falls through to `SHOP_POWER[1] = 1`.
  - I confirmed this by running `MineBreaking` in standalone Luau.
  - Zone 1 needs strength 2 from layer 51, so in the engine everyone would stall
    at layer 50.
  - A second `if p.oreToolEquipped` block later in `equippedTool` does set
    `oreTier`, but it is unreachable, and it still lacks `oreId`.
  - There are three different "breaking power" numbers: the `BreakPower`
    attribute (`MineConfig.toolBreakingPower`, the raw ore tier, which is 0 for
    the synthesized row), the equip toast (the raw tier) and the gate
    (`oreStrength`, 1..1000).
- **The wooden pickaxe's coin path is unreachable.** `_upgradeCoinTool` and the
  graduation step run only for a `p.oreTools` row with `typeId wood_pick`, and
  nothing on this branch creates one. The starter is coin rung 1 instead.
- **The family skin skips forged tools.** `equippedTool` returns rung `0` for a
  forged tool, so the family temperament never applies while you hold one
  ([skins](skins-cases-and-temper.md)).
- **"tier" means three things.** On a forged row it is the ore index. On a coin
  row it is the rung. On the Tool instance, the attribute `Tier` is
  `lookTier`, which is cosmetic.
- **"grade" is not a tool grade.** `MineToolGrades` is the F→SSS Clash-Royale
  climb (`UPGRADE_P 1/3`, `MISS_LIMIT 3`) used by lucky blocks and gear. Forged
  tools have no grade.
- **Raising the cap above 100 fails silently.** MineServer and OreBalanceSim
  read `math.min(100, TOOL_MAX_LEVEL)`.
- **The coin ladder's generator is missing.** The `MineTools` header says
  "GENERATED BY skills-src/gentools.js", but that folder is not in the repo.

## Open questions

- Does the coin shop survive (OPEN #7)? The wood-pick graduation design depends
  on it.
- Should the `MineBreaking` scale (1..1000) or the raw-tier scale be the one a
  player sees? See [mining-and-breaking](mining-and-breaking.md).

## See also

[ores](ores.md) · [forge-and-recycling](forge-and-recycling.md) ·
[enchantments-runes-and-gear](enchantments-runes-and-gear.md) ·
[chests-and-lucky-blocks](chests-and-lucky-blocks.md)
