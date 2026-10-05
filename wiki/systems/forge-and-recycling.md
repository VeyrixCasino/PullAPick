---
title: Forge and recycling
type: system
status: partial
verified: 2026-10-05 @ 26036a0
sources:
  - src/ReplicatedStorage/Mine/Shared/MineForge.luau
  - src/ReplicatedStorage/Mine/Shared/MineShopView.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ReplicatedStorage/Mine/Shared/MineOreTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineScrapSelect.luau
  - src/ReplicatedStorage/Mine/Shared/MineBenchView.luau
  - src/ReplicatedStorage/Mine/Shared/MineForgeView.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - docs/TODO.md §0.15
  - docs/TODO.md §6.1
  - docs/PROPOSAL.md §0
  - docs/OPEN.md P0 #4
related: [tools, ores, ore-pouch-and-backpack, skins-cases-and-temper, rebirth-and-skill-tree, client-and-ui, enchantments-runes-and-gear]
---

# Forge and recycling

> The Forge (it used to be called the Blacksmith) is where ore becomes a tool.
> You **craft** a tool of an ore by paying that same ore, **upgrade** it with
> more of that ore plus stardust, and **scrap** it for half of what the levels
> cost. Bulk recycling covers everything else in the inventory.

## How it works

**The panel.** The shop's first tab has id `bench` and label "Forge"
(`MineShopView` `TABS`), and the shop opens on it. `MineForge.mount` draws:
- a left rail with three modes: CRAFT, UPGRADE and a COIN SHOP shortcut
- a family picker
- a rail listing every tool, with a detail pane beside it
- a read-only ore-pouch strip along the bottom

Only discovered ores are drawn (`snapshot.oresSeen`). Every price comes from
MineConfig, and every button sends a uid. `MineBenchView` is the older panel
this replaced; nothing mounts it now.

**Craft.** `Verbs.craftOreTool({familyId, oreId})`:
- **Frame is re-derived.** The verb ignores `payload.typeId` and re-derives the
  frame with `MineOreTools.frameForTier`, so a modified client cannot pick a
  cheap frame. It refuses `wood_pick` and refuses a full rack (200).
- **Cost** is `MineConfig.toolCraftCost(tier, typeMult) = ceil(craftBlocks(tier)
  × oreYieldMid(tier) × typeMult)`. It is priced in **blocks broken** (commit
  `417cd4a`; owner wanted it to vary with drop amount, rarity and depth):
  `craftBlocks = CRAFT_BLOCKS 30 × 1/(1 + CRAFT_BAND_EASE 0.18 × (band-1)) ×
  (1 + CRAFT_DEPTH_SLOPE 4 × (t-1)/81)`.
- **Worked examples** (my arithmetic from these formulas):
  - Stone Pickaxe: 30 blocks × 9 ore = **270 Stone** (Common frame, typeMult 1).
  - Oganesson Pickaxe: about 66 blocks × 3 = 200 × typeMult 8 for the top
    Exotic frame = **1,600**.
- **Atomic.** The ore is debited and the row inserted in one synchronous block,
  with no yields, inside the router's per-player `busy` lock. The client
  supplies no costs.
- **Forging carries your level.** The new row takes the highest level on the
  rack, clamped to the cap (commit `12b528a`; `tools/forge-feel.js`). Without
  this, every forge was a downgrade.
- **Auto-equip.** The new tool is equipped straight away. This is the fix for
  the `uid` global-read bug (TODO §0.15).

**Upgrade.** `Verbs.upgradeOreTool({uid, count})` walks through as many steps
as you can afford, up to `count` (+1, +10 or MAX) and the cap of 30. It pays
`toolUpgradeCost` in the tool's own ore plus stardust; the curve is on
[tools](tools.md). The panel shows the gain before the cost: "+22% damage ·
51 Topaz · 315 dust" (`docs/PR-BALANCE-PASS.md` §2).

**Recycle a forged tool.** `Verbs.recycleOreTool(uid)` handles one tool at a
time:
- It removes the row (unequipping it if it was held), then refunds
  `MineConfig.toolRecycle = floor(toolSpent(tier, level, typeMult) ×
  TOOL_RECYCLE_PCT 0.5)`.
- The ore goes back through `Dig.addOre`, and the stardust is added to the
  balance.
- `toolSpent` counts **level spend only**. It does not include the craft cost.

**Bulk recycle.** `MineScrapSelect` is the shared SELECT/RECYCLE control used in
the inventory and the Enchanter. The flow:
1. Tick items. There is no select-all.
2. The server prices them with `scrapPlan` (read-only).
3. A review screen lists the payout.
4. Hold for 3 s to confirm.

The kinds are card, rune, gear and pack. The batch is **all-or-none**, capped
at `MineConfig.SCRAP_MAX 200`, and socketed gear is blocked. Forged tools are
not in this flow.

**Rebirth.** The rack, its levels, the equipped tool and the pouch all survive.
The coin ladder resets ([rebirth](rebirth-and-skill-tree.md)).

## Where it lives

| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineForge.luau` | Forge panel | `mount`, `discoveredOres` |
| `src/ReplicatedStorage/Mine/Shared/MineConfig.luau` | every price | `toolCraftCost`, `craftBlocks`, `toolUpgradeCost`, `toolSpent`, `toolRecycle` |
| `src/ServerScriptService/Mine/MineServer.server.luau` | verbs | `Verbs.craftOreTool`, `Verbs.upgradeOreTool`, `Verbs.recycleOreTool`, `scrapPlan`, `scrapMany` |
| `src/ReplicatedStorage/Mine/Shared/MineScrapSelect.luau` | bulk select control | `new` |
| `src/ReplicatedStorage/Mine/Shared/MineForgeView.luau` | temper UI (the Enchanter's tab), not yet folded in | — |

## Decided by the owner

- **A forged tool is its ore** (TODO §0.15). Owner: *"If i want to upgrade my
  stone pick, it should cost stone, at an increasing amount each time."* CRAFT,
  UPGRADE and SHOP are modes on the left rail.
- **Decided, not shipped** (PROPOSAL §0):
  - `CRAFT_BLOCKS` 30 → **25**, and `CRAFT_DEPTH_SLOPE` 4 → **10** (lines 9–10).
    Tier 82 would then cost 122 blocks.
  - `TOOL_RECYCLE_PCT` flat 0.50 → **0.50 + 0.10 × (tier-1)/81, capped at 0.60**
    (line 15). The code is still flat 0.5.
- The bag stays out of the Forge (PROPOSAL line 36).
- Universal recycling is 50% back in ore and stardust (TODO §6.1).

## State right now

- **Shipped:** craft, upgrade with +N, single-tool scrap, level inheritance,
  bulk recycle for four kinds.
- **Open** (OPEN #13, #15):
  - fold `MineForgeView` (tempers) into the Forge
  - keep the 3D stage from `583d9ad`
  - decide whether the Temper and Sockets tabs move here
  - apply the approved recycle curve
- **Untested:** nothing here has run in the engine.

## Gotchas

- **Probable exploit: recycle refunds levels the tool never paid for.** A
  forged tool inherits your best level, but `toolRecycle` refunds 50% of
  `toolSpent(level)` as if those levels had been bought on it.
  - Example: with any level-30 tool on the rack, forging a Stone Pickaxe costs
    270 Stone, and scrapping it returns about **23.8K Stone and 3.05M
    stardust**. This is my arithmetic from MineConfig; I have not run it.
  - It can be repeated until the pouch is full, and the stone sells for gems.
  - Fix: store the amount actually spent on the row, or refund only the levels
    bought on it. This is a design call for the owner.
- **Recycle is not all-or-nothing (OPEN P0 #4).** The tool is removed first, and
  any ore refund that does not fit in the pouch is lost. The toast reports only
  what landed. Craft and upgrade do meet the "one transaction" bar.
- **Stale cost knob in TODO.** TODO §6.1 says "`TOOL_CRAFT_BASE = 250` is the
  single knob". That constant is gone; PROPOSAL §D says so.
- **Stale scale in decisions.md.** `docs/decisions.md` still describes a
  "1–1000 scale". TODO §10.3 still lists the recycle curve as open, although
  PROPOSAL line 15 decided it.
- **`MineBenchView` is dead code.** The PR text in `docs/PR-BALANCE-PASS.md`
  still names it as a live panel.
- **The rack tracks equip on the profile.** `recycleOreTool` checks
  `tool.equipped`, but forged rows never carry that field.

## Open questions

- How should the recycle exploit be fixed, and does the refund cover the craft
  cost?
- Does the recycle curve apply to pets, runes and charms too ("universal")?
- Do the Temper and Sockets tabs move into the Forge?

## See also

[tools](tools.md) · [ores](ores.md) · [ore-pouch-and-backpack](ore-pouch-and-backpack.md) ·
[skins-cases-and-temper](skins-cases-and-temper.md) · [client-and-ui](../code/client-and-ui.md)
