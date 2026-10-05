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
related: [ores, forge-and-recycling, mining-and-breaking, skins-cases-and-temper, traits, chests-and-lucky-blocks, shops-and-monetisation, assets-and-uploads]
---

# Tools

> Pickaxes, drills and explosives. The main tool is now **forged from ore** and
> named after it, for example "Stone Pickaxe". Several older rosters (the coin
> shop, chest flagships, zone shops, Event Horizon) still exist alongside it.
> A tool has **damage**, which grows with level, and **breaking power**, which
> is fixed by its ore. These are two separate gates.

## How it works

**What you are holding.** `equippedTool(p)` in MineServer checks, in order:
1. **Event Horizon tool** (zone `bigbang`): `MineHorizonTools`, one per dirt
   section, paid in space coins.
2. **Forged ore tool**: `p.oreToolEquipped` (a uid) → a `p.oreTools` row
   `{uid, typeId, familyId, tier, level, trait?}`. `tier` is the **ore's index**
   in `MineConfig.ORES`. Rack cap 200.
3. **Chest flagship / "forever tool"** (shop "Secrets" tab): `p.chestTool` in
   `MineTools.CHEST_TOOLS`, `MineBandTools` (80) or `MineTools.PASS_TOOLS` (3).
4. **Zone shop tool**: `p.shopToolId`, `MineShopLadders` (19 per zone, 190).
5. **Coin ladder**: `MineTools.TOOLS` — 25 pickaxes (incl. `wood_pick`), 16
   drills, 16 explosives; `p.tools[fam]` = highest rung owned, `p.toolTier[fam]`
   = rung held. These rows are also the **frames** for forged tools.
6. `MineConfig.BARE_HANDS` if no pickaxe was ever collected.

Families: pickaxe (aim, swing), drill (hold), explosive (throw, cooldown);
weapon is planned (`MineTools.FAMILIES`). Forgeable: `MineOreTools.FAMILY_ORDER`.

**Forged tools** ("a forged tool IS its ore", TODO §0.15). Name `{Ore} {Noun}`
plus a trait prefix (`MineOreTools.name` → `MineTraits.decorate`). The frame is
never picked: `MineOreTools.frameForTier` maps ore tier 1..82 proportionally
onto the family's priced rungs (24 / 16 / 16). `typeMult` = the frame's
`RARITY_RANK` (stamped by `MineTools.rarityForTier`). Craft, level and scrap at
the [Forge](forge-and-recycling.md).

**Levels.** `MineConfig.TOOL_MAX_LEVEL = 30` (commit `d505d6c`, was 100; owner
wanted an advertisable *"each level UP%X"*). Rates come from `perLevel(total)`:
`TOOL_DMG_STEP = 350^(1/29) ≈ +22.4%`/level; a full climb is
`TOOL_CLIMB_DAMAGE 350` (one zone's HP growth). `MineConfig.toolUpgradeCost` =
own ore `TOOL_ORE_BASE 4 × TOOL_ORE_GROW^(L-1)` + stardust `25 ×
TOOL_DUST_GROW^(L-1)`, both × `toolCostMult` (bell `TOOL_COST_BANDS`, Epic ×18
peak, Exotic ×1 floor, × `typeMult^0.5`). A new forge inherits the best level on
the rack (`12b528a`). Over-cap saves are clamped on load (`TOOL_CAP_V`), no refund.

**Damage.** `MineConfig.toolPower = TOOL_DMG_BASE 10 × toolTierPower(tier) ×
typeMult × STEP^(L-1)`; `toolTierPower = 6^(TOOL_TIER_SPAN 7 × (t-1)/81) ×
TOOL_BAND_DMG` (Legendary ×2, Mythic ×4, Divine ×8, Exotic ×16 — because tiers
68–82 buy no new ore access at reach 15). Row finishes: Shiny ×1.5, Shadow ×3,
Nightmare ×4.5 (`SHINY_MULT` etc.).

**Breaking power** (§0.13 rules 1, 2, 11) is never damage.
`MineBreaking.toolBreakingPower`: a stamped `breakingPower`/`bp`; else, if the
tool has `oreId`/`ore`, `oreStrength(oreTier)` on a 1..1000 scale; else
`SHOP_POWER[rung]` (`{1,2,3,4,5}`).

**Tutorial wooden pickaxe** (§0.13 rule 10). `Verbs.grantFirstPick` sets
`p.tools.pickaxe = 1` (coin rung `wood_pick`). `WOOD_PICK_MAX_LEVEL 5`, cost
`WOOD_PICK_COIN_BASE 35 × WOOD_PICK_COIN_GROW 1.55^(L-1)` coins; at the cap
`Verbs._graduateTutorialPick` grants `TUTORIAL_GRADUATION_TOOL = "stone_pick"`.

**Models and icons.** `givePickaxe` builds the Roblox Tool. Forged tools look up
their mesh by ore name via `ToolModelFactory.fromNamed` in
`ReplicatedStorage.ToolModels_50` (Studio-only, ~80 MB, not in git — AGENTS.md);
otherwise procedural, coloured by `ToolModelFactory.oreLook`.
`src/ServerStorage/OreToolBaker.luau` bakes the 82 heads. `MineToolIcons` is a
spritesheet atlas for named tools.

**Hotbar and equip.** `MineHotbar` switches off Roblox's Backpack CoreGui (the
"grey cube"): max 5 slots, 1 tool slot (2 for VIP), the rest for consumables;
clicking the held slot sends `equipOreTool` with an empty uid (unequip).
`Verbs.equipOreTool(uid)` sets `p.oreToolEquipped`, clears flagship and shop-tool
picks, and calls `givePickaxe`. **Rebirth** keeps forged tools, levels and the
equip; the coin ladder resets.

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
- **Decided, not shipped:** `WOOD_PICK_COIN_GROW` 1.55 → 1.40 (PROPOSAL §0 line
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
  climb (`UPGRADE_P 1/3`, `MISS_LIMIT 3`); its one live server caller is the
  lucky-block grade-up (gear now rolls letters from the temper weights, per its
  header). Forged tools have no grade.
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
[traits](traits.md) ·
[chests-and-lucky-blocks](chests-and-lucky-blocks.md)
