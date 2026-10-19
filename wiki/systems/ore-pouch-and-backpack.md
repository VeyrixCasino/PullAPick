---
title: Ore pouch and backpack
type: system
status: current
verified: 2026-10-19 @ 3863d14
sources:
  - src/ReplicatedStorage/Mine/Shared/MineOrePouch.luau
  - src/ReplicatedStorage/Mine/Shared/MineOrePouchView.luau
  - src/ReplicatedStorage/Mine/Shared/MineForgeHub.luau
  - tools/verify/crypt-ui.js
  - src/ReplicatedStorage/Mine/Shared/MineBags.luau
  - src/ReplicatedStorage/Mine/Shared/MineBagNames.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ReplicatedStorage/Mine/Shared/MineShopView.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ServerScriptService/Mine/MineCrypt.luau
  - docs/TODO.md §0.12
  - docs/TODO.md §6.1
  - docs/PROPOSAL.md §0
related: [ores, forge-and-recycling, currencies-and-economy, rebirth-and-skill-tree, shops-and-monetisation, save-data-and-migrations]
---

# Ore pouch and backpack

> Three different containers that all get called "the bag". The **ore pouch**
> holds ore and sells it for gems. The **backpack** holds the dirt haul you
> carry to a sell pad for coins. The **item bag** is the inventory shelf for
> cards, packs, tempers, chest tools and event tools (`MineConfig.ITEM_BAG_FIELDS`;
> runes counted too until they were retired on 2026-10-12). Only the pouch
> survives a rebirth.

## How it works

**Ore pouch** (`MineOrePouch`, save fields `p.ores`, `p.orePouchTier`,
`p.oreLocks`, `p.oresSeen`):
- **Capacity** is total units across all ores, not per ore.
  `MineOrePouch.TIERS` has 10 rungs: Canvas Pouch 2,000 → Leather 4,000 → … →
  Bottomless Pouch 1,024,000 (it doubles each rung).
- **One way in: `Dig.addOre`.** It is used for the ore drop, the recycle refund
  and legacy pack banking. When the pouch is full it **refuses** the overflow,
  and that overflow is lost. The toast "Ore pouch is FULL" is throttled to once
  every 6 s (`Dig.pouchFullToast`). Discovery (`p.oresSeen`, which drives the
  Forge recipe list) is recorded whether or not there was room.
- **Selling mints gems.** `MineOrePouch.gemValue(ore) = floor(ORE_GEM_BASE 3 ×
  workOf^k)`, where `workOf = homeHp / mid-yield` (the rock HP the ore costs per
  unit). The exponent `k` is solved by `gemCompress` so that tier 82 is worth
  `ORE_GEM_SPREAD` (1e4 in the code) × tier 1. The `MineOrePouch` header quotes
  4 gems at tier 1, 279 at tier 41 and 42,727 at tier 82, measured off the
  modules (at the old 1e6 they were 5, 2.7K and 5.1M).
- **Selling verbs.** `Verbs.sellOre(oreId, count)` sells one row, even a locked
  one. `Verbs.sellAllOres` works in two calls: the first prices the sale and
  fires `confirmSellAll`; the second (`confirm = true`) applies it. Both build
  the plan with `MineOrePouch.sellAllPlan`, which skips locked ores **and candy
  ores**. `Verbs.toggleOreLock` sets or clears a lock (candy ores too).
- **Sell up to** (owner, 2026-10-19). `sellAllOres { upTo, confirm }` takes a
  ceiling from `MineOrePouch.SELL_UP_TO` (Common, Uncommon, Rare, Epic,
  Legendary, Everything; a band and everything below it). A valid one is
  remembered in `p.settings.oreSellUpTo`; no `upTo` means Everything, what SELL
  ALL always did. `confirmSellAll` now also carries `upTo` and `candyUnits`.
- **Candy ores** (Candy Crypt v2, 2026-10-19). A Candy Crypt candy block drops its
  candy ore's fixed amount (`MineConfig.CANDY_ORES`, `drop`) into the
  **Halloween inventory** while the event runs (`p.halloween.ores`,
  `MineCrypt.addCandyOre`, never into `oresSeen`), and they **move into
  `p.ores` when the event ends**. In `p.ores` they **take no pouch room**
  (`MineOrePouch.held` skips them), have a band for display (two per band) and
  never sell for gems; they sell for **candy** through `cryptSellCandyOres`
  (from wherever they live; ticked ores, or `all = true`, which skips locked
  ones; same ask-then-confirm round trip, `cryptSellCandyConfirm`) and craft and
  prestige the Halloween tools. `MineOrePouch.rows(..., { includeCandy = true })`
  lists the ones in `p.ores` with `candy = true` and `candyUnit`.
- **Upgrade with gems** through `Verbs.upgradeOrePouch`. `upgradeCost(n) =
  capacity(n) × gemValue(rungOre(n)) × RUNG_COST_SHARE 0.75`. The price is
  derived, not authored: it is three quarters of a full pouch of the ore you
  are plausibly mining at that rung. Computed: 7,500 gems for rung 1→2, 63K for
  2→3, 486K for 3→4, up to about 2.6e11 for 9→10.
- **UI.** The pouch panel (`MineOrePouchView`, hosted by the old shop) sorts by
  rarity, depth, amount, value or name, filters by band, hides empty rows and
  has Sell All behind a confirm. The Forge also shows a read-only pouch strip
  ([forge](forge-and-recycling.md)).
  - **How to open it (2026-10-19):** the Forge hub's **💎 SELL ORE** button
    (`opts.onShop("pouch")` -> `ClientFns.routePanel("shop", "pouch")` ->
    `shopCtl.setTab("pouch")`). From 2026-10-11 (when the shop lost its pouch
    tab) to 2026-10-19 nothing could open it, so ore could not be sold for gems.
    Intro step 15 names the same route (`panel = "shop", tab = "pouch"`) but is
    not in `Intro.order`. It is not a tab on the old shop's rail (S13 keeps that
    rail to Bags); `MineShopView`'s `forgeRoute` lets `pouch` through.
  - **SELL UP TO:** a chip beside SELL ALL that cycles through
    `MineOrePouch.SELL_UP_TO` on each tap, captioned by `SELL_UP_TO_LABEL`, like
    the panel's filter and sort (a row of six chips cost a phone's ore list most
    of its height). It starts on the remembered ceiling (`settings.oreSellUpTo`,
    passed in as `sellUpTo`). SELL ALL asks with the ceiling and confirms with
    the one the server priced (`confirmSellAll` carries `upTo`); the preview is
    `sellAllPlan(ores, locks, upTo)`.
  - **Candy ores** have their own section at the foot of the list, in the
    Crypt's Halloween theme: a tick box per ore (a locked one shows 🔒 and cannot
    be ticked), LOCK, and **SELL TICKED FOR CANDY**, which asks
    `cryptSellCandyOres { oreIds }`, opens the dialog on `cryptSellCandyConfirm`'s
    figures, and on YES resends the same ores with `confirm = true`. A locked
    candy ore is never sent, so never sold (the server would sell a named one).
- **Survives rebirth.** The rung, the contents, the locks and `oresSeen` all
  carry over (`tryPrestige`).

**Backpack** (the haul bag; `p.backpackTier`, `p.haulMix`, `p.load`):
- **Filling.** Every point of damage you land pays `1 × coinBonus` into
  `p.haulMix` (`payDamage`), until `cap(p)` slots are full. When the bag is
  full, rock still breaks but pays nothing, and the server fires `bagFull`.
- **Selling.** Walk onto a sell pad (`Verbs.bindSellPad` → `Verbs.sellAtPad` →
  `sellAll`). You get coins (space coins in Event Horizon). Depth desks pay
  more via `MineDepthShop.sellPayout`. The surface desk buys any dirt.
- **Rungs.** `MineConfig.BACKPACKS = MineBags.LIST`, sorted by slots with at
  least 100 slots between rungs. A bag id is `bag_<index>`. Per zone there are
  16 surface satchels, 24 depth-desk packs and 6 fossil bags; across 10 zones
  that is 460 bags, plus the Wormhole Bag and the Founders Rig (infinite) = 462.
  The rig is sold for 799 credits, in two taps (owner, 2026-10-19, audit M4), and
  the Founders Pack grants it too (M6). Names come from `MineBagNames`.
- **Price: the server charges gems.** It uses `MineBags.gemPrice(tier) = 100 ×
  1.08^(tier-1)`. Any rung can be bought in any order.
- **What `cap(p)` adds up.** The bag's slots, `p.backpackBonus`, the retired
  `backpack` boost (still read) and chest-tool `slots`.
- **Resets on rebirth.** `backpackTier` is not in `Verbs.KEEP_ON_REBIRTH`.

**Item bag**: `MineConfig.itemSlotCap = ITEM_SLOTS_BASE 500 + 100` per upgrade,
bought with gems at `100 × 1.08^x`. It counts every field in
`MineConfig.ITEM_BAG_FIELDS`. `itemSlotUpgrades` is not carried through rebirth
either.

**Legacy ore packs.** Ore used to arrive as `<id>_ore_pack` rows. `Dig.bankOrePacks`
runs on every load, after the roster migrations:
- It converts each pack to its band midpoint × its stamped finder, capped at
  `ORE_PACK_FIND_CAP`.
- It converts a pack only if the whole yield fits in the pouch. Anything that
  does not fit stays a pack.
- It has no version stamp, so it is idempotent, and it does not bump the
  `packs` stat.

`tools/verify/orepacks.js` guards it.

## Where it lives

| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineOrePouch.luau` | rungs, gem value, sell plan | `TIERS`, `gemValue`, `upgradeCost`, `sellAllPlan`, `ORE_GEM_SPREAD` |
| `src/ReplicatedStorage/Mine/Shared/MineOrePouchView.luau` | pouch panel | — |
| `src/ReplicatedStorage/Mine/Shared/MineBags.luau` | backpack ladder | `LIST`, `gemPrice`, `shopRows`, `sellable` |
| `src/ServerScriptService/Mine/MineServer.server.luau` | verbs, haul, legacy banking | `Dig.addOre`, `Dig.bankOrePacks`, `Verbs.sellAllOres`, `payDamage`, `sellAll`, `cap` |

## Decided by the owner

- The ore pouch, zones and runes are gem sinks. Gems come from selling ore
  (TODO §0.13 rule 7; TODO §9). Runes were retired on 2026-10-12; the Forge's
  enchant book bundles took their place as the gem sink (owner's pick, see
  [enchants](enchants.md)).
- The 60 fossil bags stay in `MineBags.LIST`, unobtainable and hidden.
  Deleting them would renumber every `bag_<index>` (TODO §0.12).
- **`ORE_GEM_SPREAD` 1e6 → 1e4** (PROPOSAL §0 line 16), and the gemvault/warren
  prices should become 60 × the gem value of the zone's top ore (line 17).
  The spread **is 1e4 in the code** (`MineOrePouch.ORE_GEM_SPREAD`, pinned by
  `tools/verify/gem-spread.js`); this page said 1e6 until 2026-10-19. Whether
  the vault prices moved was not rechecked.
- `backpack` is retired as a boost. Capacity comes only from the bag ladder and
  the pouch (TODO §0.21).

## State right now

The pouch, its verbs and its UI are shipped, and so is legacy pack banking.
SELL UP TO, the candy section and the SELL ORE door are built (2026-10-19) and
pinned by `tools/verify/crypt-ui.js`, which also mounts the panel on a GUI
stand-in and presses its buttons. None of this has been tested in the engine.

## Gotchas

- **The shop shows the wrong price for bags.** `MineShopView` displays
  `row.price` (the coin figure) labelled "coins", and its `statusOf` checks
  `state.coins`. The tab blurb also says "Coins for most rungs". But the buy
  verb charges `MineBags.gemPrice` in **gems**. The `MineBags` header ("Coin
  prices only. Never gems") is stale as well.
- **The pouch header is stale.** `MineOrePouch` says "THE POUCH IS THE ONE THING
  THAT SURVIVES A REBIRTH … levels go". Forged tools and their levels now
  survive too. Its "6 gems … 1.9 billion" range is also outdated.
- **Two docs disagree about `ORE_GEM_SPREAD`.** OPEN.md "Deferred" says the owner
  deferred it. PROPOSAL §0 line 16 later approved 1e4.
- **Gems are not quite single-source.** Code comments call ore "the only gem
  tap", but the rebirth gem reward (`MineSkillData.rebirthGemReward`) and
  currency packs also pay gems.
- **START-HERE §2 step 3 is wrong.** It says players "sell ore for coins". In
  fact ore sells for **gems** in the pouch panel, and coins come from the dirt
  haul at a pad. `sellOre` has no location check (UI gating unverified).
- **A full pouch eats refunds.** When you recycle a tool, any ore refund that
  does not fit is lost ([forge](forge-and-recycling.md)).
- **Bag ids are indexes into a list sorted by slots.** Any new bag inserted
  mid-ladder renumbers every `bag_<i>` above it and changes what each player
  owns.

## Open questions

- Should gem-bought backpack rungs and item slots survive rebirth? ROADMAP's
  Forge section proposes making them permanent; the code resets them.
- Where should the pouch live? It opens from the Forge hub's SELL ORE button
  (2026-10-19); a dock button or a tab of its own are the alternatives (asked in
  the Crypt client build report).

## See also

[ores](ores.md) · [rebirth-and-skill-tree](rebirth-and-skill-tree.md) ·
[shops-and-monetisation](shops-and-monetisation.md)
