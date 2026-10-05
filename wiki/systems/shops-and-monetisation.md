---
title: Shops and monetisation
type: system
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - src/ReplicatedStorage/Mine/Shared/MineShopView.luau
  - src/ReplicatedStorage/Mine/Shared/MineShopBuy.luau
  - src/ReplicatedStorage/Mine/Shared/MineShopEconomy.luau
  - src/ReplicatedStorage/Mine/Shared/MineShopLadders.luau
  - src/ServerScriptService/Mine/MineShopFronts.luau
  - src/ReplicatedStorage/Mine/Shared/MineDepthShop.luau
  - src/ReplicatedStorage/Mine/Shared/MineDepthShopView.luau
  - src/ReplicatedStorage/Mine/Shared/MineRotatingOffers.luau
  - src/ReplicatedStorage/Mine/Shared/MineShopBackgrounds.luau
  - src/ReplicatedStorage/Mine/Shared/MineScrolls.luau
  - src/ReplicatedStorage/Mine/Shared/MineFounders.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ReplicatedStorage/Mine/Shared/MinePackConfig.luau
  - src/ReplicatedStorage/TCG/Shared/MarketConfig.luau
  - src/ReplicatedStorage/TCG/Shared/PlaceConfig.luau
  - src/ServerScriptService/TCGServer/BattlePass.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - roadmap/PRINCIPLES.md §8
  - docs/PROPOSAL.md §0 lines 23, 34
  - docs/BLOCKED.md §6
  - docs/TODO.md §0.14, §0.24, §0.28
related: [currencies-and-economy, cards-and-packs, chests-and-lucky-blocks, tools, forge-and-recycling, social-quests-and-leaderboards]
---

# Shops and monetisation

> "Shop" means at least five different screens in this game, paid in four
> currencies. **Robux reach the game in one way only: credits (and two
> gamepasses).** Credits buy packs, lucky blocks, scrolls, the battle pass and
> limited deals.

`MineServer` below means `src/ServerScriptService/Mine/MineServer.server.luau`.

## How it works — the shops
| shop | where | paid in | code |
|---|---|---|---|
| **Shop panel** | world shop pad | ore (Forge), coins (tools, backpacks) | `MineShopView`, with tabs Forge (`bench`), Ore Pouch, Pickaxes, Drills, Explosives, Backpacks, Secrets |
| **Depth desks** | seam outposts (`Machine=depth_shop`) | coins | `MineDepthShop`, `MineDepthShopView` (Deeprock and Shadowzone themes) |
| **Event Horizon tools** | `bigbang` shop | space coins | `MineHorizonTools` via `MineShopBuy.buyEvent` |
| **Inventory → Shop** | menu | credits; stardust for the Stardust tab | `MineInventoryView` tabs home, box, limited, packs, dust, currencies, vip |
| **Rotating offers** | Shop → Limited | credits or Robux | `MineRotatingOffers` (3 slots, season 2026-09-22 → 2026-11-01 ET) |

**Coin-shop tools.** `MineShopLadders` sells 10 tools per zone on the surface
plus 3 per depth desk: "19 per zone · 190 shop tools total", per its header.
`MineShopEconomy` prices them in "hauls". They are bought one rung at a time
(`MineShopBuy.buySurface`). Backpacks cost coins, except the Robux top rung,
the Founders Rig (`patron_rig`). At a seam desk, selling pays `DEPTH_SELL_FRAC`
0.78.

**The credits store.** It runs through `buyCart`. Payment is `p.credits`, at
`MinePackConfig.creditPrice`, which takes 10% off for everyone. It sells:
- card packs (`PACK_PRICE`), with a 10-pack at 70% of ten singles;
- Build-a-Box: any 10 packs at 12% off;
- lucky blocks (`MineLuckyBlocks.SHOP`);
- scrolls (`MineScrolls.ITEMS`: white, black, omni, runesmith; these are rune-era items).

The Stardust tab is separate. It rotates every 6 h (`DUST_ROTATION_HOURS`), with
4 pack offers and 4 potion offers (`MinePackConfig.dustRotation`).

**Art and buildings.** `MineShopBackgrounds` gives the full-screen art per zone
and seam (0 to 5000, every 500). `MineShopFronts` builds a different-looking
building for each trade: forge, depot, arcane, works, spire, board, rotunda.

## How it works — Robux
- **Credits.** Eight dev products, from 10 credits for 10 R$ up to 7,000 credits
  for 4,999 R$ (`MineScrolls.CREDIT_PACKS`, live product ids). One credit is
  roughly one Robux at face value.
- **Battle Pass.** `MineScrolls.BATTLE_PASS` costs 399 R$ (live id) or 399 credits
  (`buyBattlePassCredits`).
  - It has 100 tiers (`PASS_TIERS`) at 280 XP each, with a 1,000 XP daily cap and
    a 28-day season, `PASS_SEASON_ID` "2026-10".
  - XP comes from digging (+1), selling (+25) and packs (+10 to +25).
  - The free track pays at most 100 credits in total; the premium track pays at most 1,200.
  - `TCGServer/BattlePass.luau` is an unrelated AFK-place stub.
- **`MineConfig.PRODUCTS`** lists: patron_rig, lucky_charm, lucky_block_pet, two
  deals, starter_bundle 129, weekend_haul 349, group_wheel_1/5/10, coin_double
  299, auto_mine 499, founders, and pet_slot (retired). **Every one has
  `productId = 0`**, so none can be bought with Robux until ids are pasted in.
  Most can be bought with credits (`buyProductWithCredits`), up to
  `CREDIT_BUY_LIMIT` 3 times each.
- **Receipts.** `MarketplaceService.ProcessReceipt` saves `p.receipts[PurchaseId]`
  *before* it reports a grant, so a retried receipt is never paid twice. It keeps
  the newest 100. The grant itself is `Verbs.grantReceipt`.
- **Not Robux code.** `TCG/Shared/MarketConfig` and `PlaceConfig` are config for
  the old TCG Life AFK place (AFK ticks, place ids). See [admin-and-debug](admin-and-debug.md).

## VIP versus Founders — two products, one word
- **VIP gamepass** (`MineConfig.VIP_GAMEPASS_ID`, stored as `p.vipPass`, checked by `hasVipPass`).
  - **What it gives in code:** AFK coins ×1.5 (`VIP_AFK_MULT`), +1 gem per AFK
    tick (`VIP_AFK_GEMS`), and a `[VIP]` name tag.
  - **What it does not give:** `MineConfig.vipPrice` and `vipPayout` return
    their input unchanged, so there is no discount.
  - **The lost perk.** VIP used to add a 4th pet seat. It can't now:
    `MineConfig.effectivePetSlots` clamps every player to 3 (TODO §0.24).
- **Founders Pack** (`MineFounders`, stored as `p.vip.since`).
  - **Price:** 799 credits, or the Founders gamepass.
  - **What it gives:** a White Scroll, the Founder tag VFX, and +5% luck in `boosts`.
  - **Seats:** `VIP_SEATS` 500 per *server*, reset whenever that server restarts.
  - **The name clash.** MineServer's `isVip(p)` and `MinePackConfig.VIP_*`
    (VIP_PRICE, VIP_SEATS, VIP_DISCOUNT) mean **Founders**, not the VIP gamepass.

## Decided by the owner
- **The Forge leads the Shop panel.** The coin shop stays reachable, but not first (TODO §0.14, `MineShopView.TABS` comment).
- **VIP's fourth seat: leave it at three.** PROPOSAL §0 line 34: *"leave at three,
  delete the dead copy"*. This answers BLOCKED §6.
- **Potions get a coin price** (PROPOSAL line 23): dust × 40. **Not built**:
  `MinePotions` is still dust-only.
- **Proposed, not agreed** (TODO §0.28): *"ore = power, gems = gambling, coins =
  consumables and access"*. OPEN §7 still asks whether the coin shop survives at all.
- **Direction only** (roadmap): *"A free path must never outperform a paid one"*
  (PRINCIPLES §8, and the ECONOMY checklist). It is not a locked rule.

## State right now
- **Shipped and inherited.** `MineScrolls`, `MineRotatingOffers` and the store
  tabs are unchanged since the import.
- **Changed on this branch:** the Forge tab leads the panel, and the quantity
  box is typed (`4368c03`). The 4th pet seat was already gone before the branch
  (TODO §0.24).
- **Battle pass is live.** It is not parked. AUDIT §5 lists it for archiving,
  which is a proposal.

## Gotchas
- **The VIP purchase toast lies.** It still says *"sell from anywhere, bigger bag,
  faster walk, better AFK"*. The `MineConfig` comment says VIP gives "remote sell",
  but the bag's Sell button walks *anyone* to the pad and sells (`bagGo`).
- **Founders comments disagree with the numbers.** Comments in `MineConfig` and
  MineServer say "1000 credits / R$999", but `FOUNDERS_CREDITS` and
  `FOUNDERS_ROBUX` are both 799.
- **A dead discount comment.** The `MinePackConfig` comment says the Warehouse
  Pass "doubles" the discount, but `VIP_DISCOUNT` equals `CREDIT_DISCOUNT` (0.10).
- **A dashboard name mismatch.** One credits product is listed on Roblox as
  "1200 Cash" (`MineScrolls` note). Rename it on the dashboard.
- **Two place ids.** `PlaceConfig.MAIN_PLACE_ID` (136170535919017) is not the
  game's placeId (73982848847016, START-HERE §2).
- **`MineStudioGrant` is not a grant of anything paid.** It is a Studio playtest
  reset ([admin-and-debug](admin-and-debug.md)).

## Open questions
- Does the coin shop survive, and what are coins for (OPEN §7)?
- Product ids for every `MineConfig.PRODUCTS` row, or should the unsold rows be cut?
- Keep or archive the battle pass (AUDIT §5)?
- Should Founders seats be per server, or global?

## See also
[currencies-and-economy](currencies-and-economy.md) · [cards-and-packs](cards-and-packs.md) · [chests-and-lucky-blocks](chests-and-lucky-blocks.md) · [tools](tools.md) · [forge-and-recycling](forge-and-recycling.md) · [social-quests-and-leaderboards](social-quests-and-leaderboards.md)
