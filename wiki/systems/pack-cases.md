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

- **Wild cases**, nine of them: 1★ to 5★ in half steps (`MineCases.WILD_GRADES`).
  - The whole grades are `case_1` to `case_6`, one per pack star level
    (`MineSetPacks.STARS`).
  - The half grades 2.5★, 3.5★ and 4.5★ are `case_3_4`, `case_4_5` and
    `case_5_6`. The sets have no half-star packs, so each pack in one is a
    coin flip between its two neighbours (owner: "Mix of both").
  - Each case holds 3–5 random packs from any set (`MineSetPacks.CASE_SIZE`),
    with top-graded sets rarer (`MineSetPacks.GRADE_WEIGHT`).
  - A better case is better only because of its packs' own odds: no luck
    boost (owner: "by design (Not a % boos[t])").
  - Chests drop them, the wheel pays them, and both shops sell them.
  - **The SSS set (Chaos Theory)** only comes out of a wild case bought with
    credits, in exactly 0.5% of its slots (`MineCases.PAID_ONLY_GRADES`,
    `PAID_ONLY_SHARE`). A credit-bought case has `paid` on its bag row. Chest,
    wheel and stardust wild cases never roll it.
- **Set cases** `<setKey>_case_starter|collector|vault`, three per set. Each
  has fixed contents (`MineCases.SET_CASES`) and is sold for stardust, **but
  only for the 9 sets graded B or lower** (`MineCases.SHOP_MAX_GRADE`). Every
  set has the rows, so a case already in a bag still opens.
  - Starter: ★ + ★½ + ★★
  - Collector: ★★ + ★★★ + ★★★ + ★★★★
  - Vault: ★★★★ + ★★★★ + ★★★★★

How a case behaves in the game:

- **Bag and tiles.** `MinePackConfig` registers every case in `PACK_BY_ID`.
  - The bag tile, stars, sort and shops read a case like a pack.
  - A case sorts just above the best pack inside it.
  - A wild case's set line reads "Any set".
  - A half-star case sorts between its two neighbours.
- **Opening.** `openFrom`, `openAt` and `openMany` hand a case to
  `MineCases.open` before `openPack`, the same way lucky blocks are handed off.
  - The reveal shows one card per pack, with its art, its stars and its set
    and grade.
  - No luck is stamped on the packs.
- **Chest drops.** In `openChestBlock`, `MineCases.rollChestCase` uses
  `MineSetPacks.CHEST_CASE_CHANCE` for the chance, by chest rank.
  - The grade comes from `MineCases.chestGradeWeight`: whole grades take
    `MineSetPacks.CHEST_CASE_STARS`; a half grade takes half the geometric
    mean of its neighbours (`CHEST_HALF_SHARE`).
  - The player's chest luck multiplies the chance, capped at ×3
    (`CHEST_LUCK_CAP`). The owner chose to keep this; the grade itself is never
    boosted.
  - ★★★★ cases and better (4.5★ included) trigger a "PACK CASE" popup.
- **Grant paths.** `Verbs.grantPacks`, the cart, the box and the admin grant
  all write a case as `MineCases.bagRow`, never with a random old set.
- **Art.** Each set has a booster box from Canva, and the wild cases share a
  mystery box, whatever their star grade (`MinePackArt.caseArt`, from
  `ids.json` `cases`). The tile's colour says the grade. How the images were
  made is in [assets-and-uploads](../code/assets-and-uploads.md). The owner
  shared all 20 on 2026-10-10, and they load and draw in the game.

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
  the model. Each image shows **a booster box**: the set's themed display box
  with its lid open and packs peeking out.
- Owner, later the same day:
  - **"Better does still cost more [10% more than last]".** Each set is valued
    ×1.10 over the set before (`SET_VALUE_STEP`).
  - **"Make it so shops dont carry any sets above b".** Set cases and featured
    set packs are sold only for sets graded F to B. The A to SS sets come
    only out of wild cases, which is what makes a wild case the better buy.
  - **Chaos Theory (SSS): "credits, and 0.5% only".** It comes only from
    wild cases bought with credits, at 0.5% of their slots. Everyone else
    trades for it.
  - Wild cases stay in both shops.
  - **"I need 2.5, 3.5 and 4.5 stars per case".** There are nine wild
    grades, and a half grade mixes its two neighbours.
  - **"A luck boost per each star/grade"** meant only that a higher grade
    has better drop rates by design, "Not a % boos[t]". The luck carry-over
    was removed. Chest luck still raises the chance of a case dropping.

## The pricing pass: every number below is PROPOSED

Owner: *"put in the wiki and todolist of determining how much everything is
worth"*. Derived numbers, from the code after the owner's later answers:

- **Stardust** = expected stardust of the contents / 0.65 (`MineSetPacks.CASE_RTP`).
  - Expected stardust = `MineSetPacks.expectedPackDust` over
    `MinePackConfig.RECYCLE_STARDUST`, times the set's value.
  - Set value = 1.10^(set − 1) (`MineCases.SET_VALUE_STEP`, *decided*: "10%
    more than last").
  - A wild case is valued over the sets it can actually roll.
- **Credits** = 12 × (expected stardust / 250)^0.45 (`MineCases.CREDIT_CURVE`).
  This is fitted to the old credit shelf: Hopper was 12 credits at about 250
  expected stardust, Heirloom 55 at about 6,900 and Shiny 95 at about 24,000.
  A wild case is priced as the credit-bought kind, the one that can roll SSS.

| wild case | expected stardust | stardust | credits |
|---|---|---|---|
| ★ | 369 | 570 | 14 |
| ★½ | 660 | 1,015 | 19 |
| ★★ | 1,503 | 2,315 | 27 |
| ★★½ | 3,184 | 4,900 | 38 |
| ★★★ | 4,865 | 7,485 | 46 |
| ★★★½ | 11,375 | 17,500 | 67 |
| ★★★★ | 17,884 | 27,515 | 82 |
| ★★★★½ | 38,439 | 59,135 | 116 |
| ★★★★★ | 58,995 | 90,760 | 141 |

Set cases, in stardust (Starter / Collector / Vault), for the 9 sets the
shops carry:

- Pebblebound (F): 525 / 6,040 / 19,650
- Sugar Rush (D): 580 / 6,640 / 21,615
- Starfront (C): 770 / 8,840 / 28,770
- Arcade Legends (B): 845 / 9,725 / 31,650
- Royal Reserve (B): 1,125 / 12,945 / 42,125

Every set steps by ×1.10. `MineCases.dustPrice` prints any of them, and it
returns nil for the sets above B.

Featured set packs in credits (sets F to B only):

- ★★★ costs 19 (Pebblebound) to 26 (Royal Reserve).
- ★★★★★ costs 57 to about 80.
- Four are featured each UTC day, at ★★★, ★★★★, ★★★★ and ★★★★★
  (`FEATURED_LEVELS`).

Wild-slot odds by set grade (`MineCases.wildGradeOdds`):

| grade | share |
|---|---|
| F | 10.3% |
| D | 9.3% |
| C | 24.7% |
| B | 24.7% |
| A | 24.7% |
| S | 5.1% |
| SS | 1.2% |
| SSS | 0.5%, credit-bought cases only |

**Still to price or approve:**
- every number above;
- the chest case rates (`MineSetPacks.CHEST_CASE_CHANCE`, `MineSetPacks.CHEST_CASE_STARS`,
  `MineCases.CHEST_HALF_SHARE`). For example, an S chest's case comes out:
  - ★ 12%, ★½ 15%, ★★ 17%, ★★½ 9%, ★★★ 18%;
  - ★★★½ 8%, ★★★★ 14%, ★★★★½ 4%, ★★★★★ 5%;
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

- **Credit purchases stamp `paid`.** The cart and the box call
  `MineCases.bagRow(id, true)`. Any new paid path must do the same, or SSS
  never drops from it.
- **Never let a case reach `openPack`.** Dispatch on `MineCases.get(packId)`,
  not on `kind`. Old grant paths write rows without `kind`.
- **`MineCases` must not require `MinePackConfig` at load.** MinePackConfig
  requires MineCases, and a require loop never returns. The prices read it
  lazily.
- **`MineServer` has 4 top-level locals left.** The case code uses inline
  requires and a `Verbs` field.

## Open questions

- Another session reported that the owner has case icons of their own on
  the way. If those replace the Canva boxes, re-point `ids.json` `cases` and
  re-run `gen-pack-art.js`.
- **Bag stacking.** Credit-bought and earned wild cases of the same grade
  stack on one tile, and the server opens whichever comes first. The only
  difference between them is the 0.5% SSS chance.

## See also

[cards-and-packs](cards-and-packs.md) · [shops-and-monetisation](shops-and-monetisation.md) ·
[chests-and-lucky-blocks](chests-and-lucky-blocks.md) · [assets-and-uploads](../code/assets-and-uploads.md)
