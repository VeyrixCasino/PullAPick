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
- **Chest drops** (*decided*, owner 2026-10-10: the old 0.5–10% was "WAY to
  high … make each rarity 2x as rare as the last.. 10% base drop rate").
  `MineCases.rollChestCase` and `chestCaseOdds` work like this:
  - 10% of chests drop a case (`CHEST_CASE_CHANCE`).
  - Each grade is half as common as the one below (`CHEST_GRADE_FALLOFF`).
  - A better chest shifts the ladder up one half-star per rank
    (`CHEST_RANK_SHIFT`): B starts at ★½, A at ★★, S at ★★½.
  - F and D start below ★, and a grade below ★ is no case, so they drop one
    2.5% and 5% of the time.

  | chest | any case | ★ | ★★ | ★★★ | ★★★★ | ★★★★★ | value per chest |
  |---|---|---|---|---|---|---|---|
  | F | 2.5% | 1.25% | 0.31% | 0.08% | 0.02% | 0.005% | ~18 dust |
  | C | 10% | 5% | 1.25% | 0.31% | 0.08% | 0.02% | ~73 dust |
  | S | 10% | – | – | 2.5% | 0.64% | 0.16% | ~373 dust |

  "Value per chest" is what the cases' cards recycle for. A ★★★★★ case
  comes from about 1 in 5,000 C chests.
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
- Credit shop: "Cases by star + a few featured set packs". The old packs came
  off it, and later off the rotating stardust shelf too ("remove old packs
  from the stardust shelf too"), which now deals potions only
  (`MinePackConfig.DUST_OLD_PACKS`).
- Cases replace the wheel's pack slices.
- Prices come "from expected value".
- One case image per set plus one wild image. The star grade does not change
  the model. Each image shows **a booster box**: the set's themed display box
  with its lid open and packs peeking out.
- Owner, later the same day:
  - **"Better does still cost more [10% more than last]".** This was later
    replaced by the return rule below: "+10% per set" priced the stronger
    pets on top of the recycle value and returned as little as 30%.
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
  - **"Make it even, pretty numbers.. 50-70% rtp".** Wild cases "should return
    70% stardust value across the board". Set cases "55-65 (Higher teir less
    rtp, but more volitile)": 65% for the lowest set the shops carry, down to
    55% for the highest.

## The prices (decided 2026-10-10)

A case is priced by its **return**: what its cards recycle for, as a share of
the price (`MineCases.rtpOf`). Prices are rounded to pretty numbers
(`MineCases.prettyPrice`): under 100 to the nearest 5, otherwise two figures
with the second a 0 or a 5.

- **Recycle value** comes from `MineCases.expectedDust`:
  `MineSetPacks.expectedPackDust` over `MinePackConfig.RECYCLE_STARDUST`.
  Recycling pays by rarity only, so the set does not change it.
- **Stardust** = recycle value / return.
  - Wild cases return 70% (`WILD_RTP`).
  - Set cases return 65% for Pebblebound, falling evenly to 55% for Royal
    Reserve (`SET_RTP_TOP`, `SET_RTP_LOW`). A better set costs more because
    its pets are stronger, which recycling does not pay for.
- **Credits** use the curve the old credit shelf sat on:
  12 × (recycle value / 250)^0.45 (`CREDIT_CURVE`).
  - It is scaled by 70% / the return, so a set pack costs a little more than
    a wild case of the same value.
  - The result is rounded pretty.

| wild case | recycle value | stardust | return | credits |
|---|---|---|---|---|
| ★ | 182 | 260 | 70% | 10 |
| ★½ | 325 | 465 | 70% | 15 |
| ★★ | 740 | 1,050 | 70% | 20 |
| ★★½ | 1,567 | 2,250 | 70% | 25 |
| ★★★ | 2,394 | 3,400 | 70% | 35 |
| ★★★½ | 5,596 | 8,000 | 70% | 50 |
| ★★★★ | 8,799 | 12,500 | 70% | 60 |
| ★★★★½ | 18,913 | 27,000 | 70% | 85 |
| ★★★★★ | 29,026 | 41,500 | 70% | 100 |

| set case (stardust) | Starter | Collector | Vault | return |
|---|---|---|---|---|
| Pebblebound (F) | 525 | 6,050 | 19,500 | 65% |
| Sugar Rush (D) | 535 | 6,150 | 20,000 | 64% |
| Mosswood (C) | 545 | 6,300 | 20,500 | 62% |
| Lost & Found (C) | 555 | 6,400 | 21,000 | 61% |
| Starfront (C) | 570 | 6,550 | 21,500 | 60% |
| Arcade Legends (B) | 580 | 6,700 | 21,500 | 59% |
| Crystal Hollow (B) | 595 | 6,850 | 22,000 | 57% |
| Shogun's Oath (B) | 605 | 7,000 | 22,500 | 56% |
| Royal Reserve (B) | 620 | 7,150 | 23,000 | 55% |

Featured set packs in credits (sets F to B only):
- ★★★ is about 25.
- ★★★★ is 35–40.
- ★★★★★ is about 70.
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

**Also decided (owner, 2026-10-10), closing the pricing pass:**
- The wheel's case slices stay: Anomaly ★★ 10%, Heirloom ★★★ 10%, Apex ★★★★ 6%,
  Jackpot ★★★★★ + 15K gems 0.8%. That is about 1,000 stardust of value a spin.
- The featured set packs stay: 4 a day at ★★★, ★★★★, ★★★★ and ★★★★★.
- **A set case shows its set's grade, not stars.** Owner: *"A 1 star pack of
  the top set and a 1 star of shittiest set means vastly different things."*
  The bag tile and the stardust tile draw "GRADE F" and so on in the grade's
  colour (`MineInventoryView` gradeRow). A set case still sorts by its best
  pack's stars.
- The credit curve (`CREDIT_CURVE`) was not asked about separately. It is
  what turns value into credits.

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
