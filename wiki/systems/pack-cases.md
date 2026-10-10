---
title: Pack cases
type: system
status: partial
verified: 2026-10-10 @ f6ca7a6
sources:
  - src/ReplicatedStorage/Mine/Shared/MineCases.luau
  - src/ReplicatedStorage/Mine/Shared/MineSetPacks.luau
  - src/ReplicatedStorage/Mine/Shared/MinePackConfig.luau
  - src/ReplicatedStorage/Mine/Shared/MineGroupWheel.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - docs/PETS-AND-SETS.md
related: [cards-and-packs, shops-and-monetisation, chests-and-lucky-blocks, social-quests-and-leaderboards, currencies-and-economy, assets-and-uploads]
---

# Pack cases

> A pack case holds **packs, never cards**. Opening one drops its packs into
> the bag, where they open like any other pack. Cases are how the 19 sets'
> packs reach players: from chests, the daily wheel, the credit shop and the
> stardust shop.

## How it works

There are two kinds (`MineCases.CASES`, kind `pack_case`):

- **Wild cases** `case_1` to `case_6`, one per star grade (`MineSetPacks.STARS`):
  - each holds 3–5 random packs of that grade, from any set (`MineSetPacks.CASE_SIZE`);
  - top-graded sets are rarer (`MineSetPacks.GRADE_WEIGHT`).
  - Chests drop them, the wheel pays them, and both shops sell them.
- **Set cases** `<setKey>_case_starter|collector|vault`, three per set. Each
  has fixed contents (`MineCases.SET_CASES`) and is sold for stardust:
  - Starter: ★ + ★½ + ★★
  - Collector: ★★ + ★★★ + ★★★ + ★★★★
  - Vault: ★★★★ + ★★★★ + ★★★★★

How a case behaves in the game:

- **Bag and tiles.** `MinePackConfig` registers every case in `PACK_BY_ID`.
  - The bag tile, stars, sort and shops read a case like a pack.
  - A case sorts just above the best pack inside it.
  - A wild case's set line reads "Any set".
- **Opening.** `openFrom`, `openAt` and `openMany` hand a case to
  `MineCases.open` before `openPack`, the same way lucky blocks are handed off.
  - The reveal shows one card per pack, with its art, its stars and its set
    and grade.
  - A case from a lucky chest passes that chest's pack luck to every pack inside.
- **Chest drops.** In `openChestBlock`, `MineCases.rollChestCase` uses
  `MineSetPacks.CHEST_CASE_CHANCE` and `CHEST_CASE_STARS` by chest rank.
  - Chest luck multiplies the chance, capped at ×3 (`CHEST_LUCK_CAP`).
  - ★★★★ cases and better trigger a "PACK CASE" popup.
- **Grant paths.** `Verbs.grantPacks`, the cart, the box and the admin grant
  all write a case as `MineCases.bagRow`, never with a random old set.
- **Art.**
  - Placeholder: a set case wears its set's medallion; a wild case wears the
    gem of its star tier (`MinePackArt.caseArt`).
  - The Canva case art drops in through `ids.json` `cases`.

## Where it lives

| file | role | key symbols |
|---|---|---|
| `MineCases.luau` | both case kinds, rolling, opening, prices, shelves | `CASES`, `open`, `rollChestCase`, `dustPrice`, `creditPrice`, `creditShelf`, `featuredSetPacks` |
| `MinePackConfig.luau` | registers cases; `priceOf` falls back to MineCases | `PACK_BY_ID`, `priceOf`, `PACK_UNIT.pack_case` |
| `MineServer.server.luau` | open dispatch, chest drop, cart grants, stardust buy | `Verbs.buyDustCase`, `openChestBlock` |
| `MineGroupWheel.luau` | the wheel's pack slices now pay wild cases | `SEGMENTS` |
| `MineInventoryView.luau` | bag tile, case inspector, credit shelf, stardust Cases tab | `dustTab`, `FEATURED` |
| `MinePackArt.luau` | generated; case art lookup | `caseArt`, `WILD_CASE` |

## Decided by the owner (2026-10-10)

- Two kinds: set cases, with exact contents, at least 3 packs, sold for
  stardust; and wild cases, a "complete wild draw".
- Three per set: Starter / Collector / Vault.
- Credit shop: "Cases by star + a few featured set packs". The old packs came off it.
- Cases replace the wheel's pack slices.
- Prices come "from expected value".
- One case image per set plus one wild image. The star grade does not change
  the model.

## The pricing pass: every number below is PROPOSED

Owner: *"put in the wiki and todolist of determining how much everything is
worth"*. Derived numbers, from the code at `f6ca7a6`:

- **Stardust** = expected stardust of the contents / 0.65 (`MineSetPacks.CASE_RTP`).
  - Expected stardust = `MineSetPacks.expectedPackDust` over
    `MinePackConfig.RECYCLE_STARDUST`, times the set's value.
  - Set value = 1.05^(set − 1) (`MineCases.SET_VALUE_STEP`), because pets are
    5% stronger per set.
  - Without the set value, a Chaos Theory Vault would cost the same as a
    Pebblebound one.
- **Credits** = 12 × (expected stardust / 250)^0.45 (`MineCases.CREDIT_CURVE`).
  This is fitted to the old credit shelf: Hopper was 12 credits at about 250
  expected stardust, Heirloom 55 at about 6,900 and Shiny 95 at about 24,000.

| wild case | expected stardust | stardust | credits |
|---|---|---|---|
| ★ | 255 | 390 | 12 |
| ★½ | 455 | 700 | 16 |
| ★★ | 1,038 | 1,595 | 23 |
| ★★★ | 3,359 | 5,165 | 39 |
| ★★★★ | 12,345 | 18,995 | 69 |
| ★★★★★ | 40,725 | 62,655 | 119 |

Set cases, in stardust (Starter / Collector / Vault):

- Pebblebound (F): 525 / 6,040 / 19,650
- Royal Reserve (B): 775 / 8,920 / 29,035
- Atlantis Rising (A): 990 / 11,385 / 37,055
- Chaos Theory (SSS): 1,265 / 14,530 / 47,295

Every set steps by ×1.05. `MineCases.dustPrice` prints any of them.

Featured set packs in credits:

- ★★★ costs 19 (Pebblebound) to 27 (Chaos Theory).
- ★★★★★ costs 57 to 85.
- Four are featured each UTC day, at ★★★, ★★★★, ★★★★ and ★★★★★
  (`FEATURED_LEVELS`).

**Still to price or approve:**
- every number above;
- the chest case rates (`MineSetPacks.CHEST_CASE_CHANCE`, `MineSetPacks.CHEST_CASE_STARS`);
- which star grade each wheel slice pays (jackpot ★★★★★, apex ★★★★, heirloom
  ★★★, anomaly ★★);
- the rotating stardust shelf, which still sells the old card packs;
- a set case's shown stars, which are its best pack's.

## State right now

**Shipped 2026-10-10.** Played in Studio with no errors:

- bought a set case for stardust;
- opened single cases and a run of them;
- read the bag tiles and the case inspector;
- browsed the credit shelf and the stardust Cases tab;
- checked the wheel's reward lines.

**Not yet seen in play:** a case dropping from a real chest. The roll was
tested on its own: S-rank chests drop one about 10% of the time.

## Gotchas

- **Never let a case reach `openPack`.** Dispatch on `MineCases.get(packId)`,
  not on `kind`. Old grant paths write rows without `kind`.
- **`MineCases` must not require `MinePackConfig` at load.** MinePackConfig
  requires MineCases, and a require loop never returns. The prices read it
  lazily.
- **`MineServer` has 4 top-level locals left.** The case code uses inline
  requires and a `Verbs` field.

## Open questions

- Owner, earlier: *"a luck boost per each star/grade"*. Built as "each star
  grade is better packs", plus chest luck carried onto the packs. It is not
  confirmed.
- Should wild cases also be sold for stardust? They are now (the doc's earlier
  decision), as well as for credits.
- Case art is still due from Canva: 19 set images plus 1 wild image.

## See also

[cards-and-packs](cards-and-packs.md) · [shops-and-monetisation](shops-and-monetisation.md) ·
[chests-and-lucky-blocks](chests-and-lucky-blocks.md) · [assets-and-uploads](../code/assets-and-uploads.md)
