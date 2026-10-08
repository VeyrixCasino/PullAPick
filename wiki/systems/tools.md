---
title: Tools
type: system
status: partial
verified: 2026-10-08 @ bae3c5b
sources:
  - src/ReplicatedStorage/Mine/Shared/MineOreTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineIcons.luau
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
> named after it, for example "Stone Pickaxe". **The coin shop no longer sells
> tools** (`9733a05`, below). Chest flagships, zone shops and Event Horizon
> tools still exist alongside it.
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
   **Since `9733a05` nothing sells them for coins**: `MineConfig.FORGE_ONLY_FAMILIES`
   (pickaxe, drill, explosive, weapon) is refused at the surface shop, the depth
   desks and the legacy `buy "pickaxe"` action (`buyTool`, `buyDepthTool`). The
   roster is kept because `MineOreTools.frames()` filters it on `price > 0`: the
   prices are now a forge input, not a shelf price.
   **Owner, 2026-10-06** (`312721b`, `bef7b0d`): *"delete all tools in the game
   besides for chest tools (if they still even exist) and ore tools"*. The chest
   flagships (`MineTools.CHEST_TOOLS`, about 52, never sold) stay, and so does the
   given wooden starter (without it a new player spawns with no tool and needs
   about 2,800 blocks to forge one). To make deletion safe, the forge no longer
   reads the roster: `MineOreTools.typeMult(family, tier)` and
   `MineOreTools.FRAME_STATS` / `frameStats` are baked step tables, compared
   against the roster for all 2,460 values by `tools/verify/oreframes.js`
   (0 mismatches). **`MineTools.TOOLS` is still in the tree**; I did not check
   whether a later commit deletes it.
6. `MineConfig.BARE_HANDS` if no pickaxe was ever collected.

Families: pickaxe (aim, swing), drill (hold), explosive (throw, cooldown);
weapon is planned (`MineTools.FAMILIES`). Forgeable: `MineOreTools.FAMILY_ORDER`.

**Other ways a tool arrives (2026-10-07).** A **wandering trader's tool case** pays a
forged-style tool of a tier inside the case's band, in a random family, at level 1 with
`base = 1`, for temper tokens ([wandering-traders](wandering-traders.md)). It is not
bought with coins, so the 2026-10-05 rule still holds.

**Forged tools** ("a forged tool IS its ore", TODO §0.15). Name `{Ore} {Noun}`
plus a trait prefix (`MineOreTools.name` → `MineTraits.decorate`). The frame is
never picked: `MineOreTools.frameForTier` maps ore tier 1..82 proportionally
onto the family's priced rungs (24 / 16 / 16). `typeMult` is a baked step
function of tier per family (`312721b`; pickaxe 1–6 = 1 … 70–82 = 8, drills and
explosives 1–9 = 1 … 74–82 = 8), identical to the old frame lookup. A forged
tool's name is the family noun (`bef7b0d`), no longer the frame's invented title. Craft, level and scrap at
the [Forge](forge-and-recycling.md).

**Levels.** `MineConfig.TOOL_MAX_LEVEL = 30` (commit `d505d6c`, was 100; owner
wanted an advertisable *"each level UP%X"*). Rates come from `perLevel(total)`:
`TOOL_DMG_STEP = 350^(1/29) ≈ +22.4%`/level; a full climb is
`TOOL_CLIMB_DAMAGE 350` (one zone's HP growth). `MineConfig.toolUpgradeCost` =
own ore `TOOL_ORE_BASE 4 × TOOL_ORE_GROW^(L-1)` + stardust `25 ×
TOOL_DUST_GROW^(L-1)`, both × `toolCostMult` (bell `TOOL_COST_BANDS`, Epic ×18
peak, Exotic ×1 floor, × `typeMult^0.5`). A new forge inherits the best level on
the rack (`12b528a`); the row stamps the level it was forged at (`base`), and
scrapping refunds only the climb above it (`4cc82a5`). Over-cap saves are clamped on load (`TOOL_CAP_V`), no refund.

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

**2026-10-07: 2,060 of those models were archived to `ServerStorage`.** Measured
in a live client, `ToolModels_50` held 4,148 models / 80,797 instances and was
**58% of every client's datamodel** (137,444 instances, replicated to every player
on join). Only **196** were referenced by anything live — they match
`MineShopLadders.LIST` names; the other 3,952 appeared in no live module, only in
the `Wave13Batches` generator scripts that produced them. The 2,060 heaviest
(70,040 instances, ~33 each: 6 real meshes plus a particle/trail/highlight/light
rig sitting in cold storage) moved to
`ServerStorage.ToolModels_50_Unreferenced`. Client `InstanceCount` went
**137,444 → 67,537**, and shop resolution was unchanged at 196 resolved / 54
procedural / 0 errors.

- **It is named `_Unreferenced` deliberately.** `ToolModelFactory.toolModelsRoot()`
  returns the **first** container it finds (ReplicatedStorage → ServerStorage →
  workspace) and does not search across them, so a `ServerStorage` folder sharing
  the name would silently become the live roster if the ReplicatedStorage one were
  ever removed.
- **`git` cannot revert this.** `ToolModels_50` lives in the place file, not the
  Rojo-synced tree. Reversing it means dragging the folder back in Studio; the
  owner chose moving over deleting to keep that option.
- A `fromNamed` miss degrades to a procedural model, so a wrongly-archived tool
  shows up as a plain mesh rather than an error. Verify any change here by
  counting shop resolution: `MineShopLadders.LIST` must stay 196 resolved / 54
  procedural.
- **Measuring the client in Studio play-solo:** trust `Stats.InstanceCount`, not
  `GetTotalMemoryUsageMb()`. Play-solo shares one process with the server, so the
  archive still occupies memory there and the memory figure hides the win.
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
| `src/ReplicatedStorage/Mine/Shared/MineOreTools.luau` | forged naming and frames | `name`, `frameForTier`, `oreOf`, `typeMult`, `FRAME_STATS`, `frameStats` |
| `src/ReplicatedStorage/Mine/Shared/MineIcons.luau` | per-ore tool skins | `ORE_PICK`, `ORE_DRILL`, `ORE_BOMB`, `forTool` |
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
- **No coin-bought tools** (owner, 2026-10-05, quoted in the `9733a05` comments:
  *"i think its time to get rid of all coin bought tools"*). Every tool family is
  forged from ore. Backpacks, the Ore Pouch and chest Secrets stay. The wooden
  pickaxe is given, never sold, and the commit says it **still levels on coins**
  (`MineConfig.isCoinTool`), kept on purpose as the on-ramp to the Forge.
- **Every forged tool wears its ore: 246 skins** (`97c42ac`; owner, 2026-10-05:
  *"apply the skins to each tool"*, and on the sheets: *"1st is wooden, then its
  in order, last one is admin drill, hand gernade and pickaxe"*). `MineIcons`
  holds a table per family (`ORE_PICK` with the wooden `ORE_PICK_STARTER` first,
  `ORE_DRILL`, `ORE_BOMB`) of 82 tiers each, and `MineIcons.forTool(tool)` picks
  the table by family, falling back to the flat family icon so one family cannot
  borrow another's art. The sheet order is the owner's and replaced an earlier
  colour-matching guess (that script was deleted). The author counted 246
  distinct images live. `tools/verify/oreskins.js` pins it.
- **Decided, not shipped:** `WOOD_PICK_COIN_GROW` 1.55 → 1.40 (PROPOSAL §0 line
  12).

## State right now

The forged-tool system is shipped and, per the commit messages, has been exercised
in live Studio sessions (breaking power fixed in `b19c4c2`; skins wired and
counted live in `97c42ac`). I have not run it. The coin tool roster is being
wound down (below).

## Gotchas

- **Fixed in `b19c4c2`: forged tools used to have breaking power 1 at the gate.**
  The row `equippedTool` synthesised for a forged tool had no `oreId`, `oreTier`
  or `breakingPower`, so `MineBreaking.toolBreakingPower` fell through to
  `SHOP_POWER[1] = 1` and every tool stalled at zone 1, layer 50 (measured live
  by the fix's author). The row now carries `oreTier` and `oreId`, derived per
  swing. `tools/verify/heldtool.js` runs the real function against the real row
  shape. **Event Horizon tools and coin-ladder rows take a different path and
  that commit does not mention them**, so their breaking power is not rechecked.
  - There are still three different "breaking power" numbers: the `BreakPower`
    attribute (`MineConfig.toolBreakingPower`, the raw ore tier), the equip toast
    (the raw tier) and the gate (`oreStrength`, 1..1000).
- **The wooden pickaxe's coin path looks unreachable** (found before `9733a05`,
  not re-checked since; that commit says the owner kept the coin path on
  purpose). `_upgradeCoinTool` and the graduation step run only for a
  `p.oreTools` row with `typeId wood_pick`, and nothing on this branch creates
  one. The starter is coin rung 1 instead.
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

- The coin shop no longer sells tools (`9733a05`). What are coins for now? OPEN #7
  is still open, and the wood-pick graduation design depends on the answer.
- Should the `MineBreaking` scale (1..1000) or the raw-tier scale be the one a
  player sees? See [mining-and-breaking](mining-and-breaking.md).

## See also

[ores](ores.md) · [forge-and-recycling](forge-and-recycling.md) ·
[traits](traits.md) ·
[chests-and-lucky-blocks](chests-and-lucky-blocks.md)
