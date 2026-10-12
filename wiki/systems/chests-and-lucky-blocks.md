---
title: Chests and lucky blocks
type: system
status: current
verified: 2026-10-10 @ 4ac7320
sources:
  - src/ReplicatedStorage/Mine/Shared/MineZoneChests.luau
  - src/ReplicatedStorage/Mine/Shared/Mine1ChestsData.luau
  - src/ReplicatedStorage/Mine/Shared/MineChestModel.luau
  - src/ReplicatedStorage/Mine/Shared/MineChestRanks.luau
  - src/ReplicatedStorage/Mine/Shared/MineLuckyBlocks.luau
  - src/ReplicatedStorage/Mine/Shared/MineCases.luau
  - src/ReplicatedStorage/Mine/Shared/MineGradeReveal.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - docs/TODO.md §0.27, §0.32
  - docs/PROPOSAL.md §0 line 21
  - docs/AUDIT.md §5
related: [cards-and-packs, mining-and-breaking, zones-layers-and-seams, shops-and-monetisation, currencies-and-economy]
---

# Chests and lucky blocks

> **Chests** are blocks in the mine wall. You break one and it pays coins, gems
> and maybe packs. **Lucky blocks** are a second gacha. They drop rarely off
> ordinary rock, sit in your bag like packs, and on opening climb an F→SSS grade
> before paying out: a mystery case, a skin case, or some gems or stardust. Both exist to give the dig a hit between ore finds.

`MineServer` below means `src/ServerScriptService/Mine/MineServer.server.luau`.

## How it works — chests

**Where a chest spawns.** `rollKind` in MineServer makes a block a chest when a
roll beats `MineConfig.CHEST_CHANCE` (0.003). That chance is multiplied in a few places:

| where | multiplier | source |
|---|---|---|
| Event Horizon | ×3 | `zone.chestMult` |
| Meadow, layers 1–100 | ×2 | `MEADOW_SHALLOW_CHEST_MULT` |
| during a World Pulse | ×`worldChestMult` | disabled, see [world-events](world-events.md) |

**Which chest it is**, decided at spawn by `MineZoneChests.rollSpawn`:
- **A catalog chest from `Mine1ChestsData`** (80 rows, layer bands), picked by
  `MinePackConfig.rollChestAt`. The share is 45% of chests, but only 2.5% in zone 1
  at layer ≤ 120 and 12% deeper in zone 1. `m1_lookingglass` is never picked.
- **Otherwise, the zone's pool**, rolled by rank in `MineChestRanks`. The weights
  are S 4, A 10, B 22, C 100, D 35, F 0.
- **Better chests deeper** (owner, 2026-10-10/11). How MANY chests stays
  `CHEST_CHANCE` everywhere; how GOOD they are rises with depth inside every zone
  except Dirt Meadow. `MineConfig.chestRankLuck(zone, layer)` is ×1 at a zone's top
  and ×3 at its floor, on a log of block HP, so it is front-loaded: ×1.7 at layer
  100, ×2.2 at 500, ×2.45 at 1,000. It multiplies the pool's **B, A and S** weights
  (`MineChestRanks.roll` `better`, which leaves D and C alone) and the catalog
  chests' luck. In Greyvein's pool that takes S from 0.9% to 2.2%, A from 2.2% to
  4.9% and B from 16% to 34% of chests. Meadow and the event mines stay ×1. The
  owner's reason: *"i can picture people with explosoves nuking starter mine bcuz
  everything is one shot. there should be incentive to go a little deeper"*.
  Better ranks then pay better pack cases and skin cases (below).
  `tools/verify/chest-depth.js` checks it.
- **The Shiny Chest (chase).** In zone 1 it can appear only at layer ≥ 2500, at
  1/8000. In zones 2–10 the chance lerps from 1/2500 up to 0.8%.

`MineChestModel` builds the visible chest. It has five palettes: native, broad,
currency, item, chase. The model's parts are `CanQuery` false, so they never
steal the aim raycast.

**`build(part, kind, scale)` builds INTO a MineBlock — it does not return a
model.** The pieces become children of the block, so they die with it when it
breaks. Calling it like a model factory fails; an audit has to pass it a host
part.

Geometry is sound: 23 pieces per kind, worst gap −0.040 studs (overlapping),
nothing floating, verified in engine 2026-10-10 across all five kinds.

**All five kinds are the same shape.** Only `Color` differs, plus a `PointLight`
on currency, item and chase. That leaves the module's own premise unmet — its
header argues a chest was bad because *"the only thing telling you a Ledger
Vault from a Topsoil Chest was its tint — and at shaft distance, in shadow,
that is nothing at all."* The base shape is much better than the old cube, but
the five kinds are still separated by tint alone. Open question below.

**What a chest pays** (`openChestBlock` in MineServer):
- **The chest def.**
  - Meadow and Event Horizon **always** use the section-exclusive chest from
    `MineZoneChests.exclusiveFor`: one per 25-layer section, with coins taken from
    that section's dirt HP and 0 gems.
  - Other zones use the block's own chest when it is in `MineZoneChests.DEFS`.
    If it is not, they re-roll from the zone pool.
- **Coins and gems** come from the def's fixed bands (`rollCurrency`), then are
  multiplied by `coinBonus` and `gemFind`. Each def's gems were already multiplied
  once by `MineZoneChests.GEM_MULT` for its home zone.
- **Stardust** from the `scrap` stat.
- **Packs.** Each entry in the chest's `packs` list is an independent % roll for
  a zone pack slot (`rollPackDrops`). A Meadow section chest rolls currency_common
  72, pack_common 18, pack_rare 6, pack_legendary 1 and currency_rare 3. A
  legendary pack fires the "BONKERS PACK" popup.
- **Pack cases.** A zone chest can also drop a wild pack case
  (`MineCases.rollChestCase`, 2026-10-10).
  - *Decided* by the owner, 2026-10-10. 10% of chests drop one
    (`MineCases.CHEST_CASE_CHANCE`).
  - Each case grade is half as common as the one below.
  - A better chest rank starts the ladder a half-star higher (S starts at
    ★★½). F and D chests drop a case only 2.5% and 5% of the time.
  - Chest luck raises the chance, up to ×3. See [pack-cases](pack-cases.md).
- **Skin cases** (owner, 2026-10-11: skins follow the pack cases' *"same
  logic/rates"*; chose "better chests → better skin tiers").
  - 3% of zone chests drop one (`MineConfig.CHEST_SKIN_CASE_CHANCE`), raised by
    chest luck up to ×3. It opens on the spot: a skin of the rolled tier, or
    stardust for a duplicate (`Dig.grantChestSkin`).
  - The tier comes from `SKIN_CASE_TIERS`, shifted up by the chest's rank
    (`CHEST_SKIN_RANK_SHIFT`: B +1, A +2, S +3, the pack cases' rule). A C chest's
    case is SSS 0.4% of the time, an S chest's about 6%. Low ranks are never
    pushed down.
  - **Before this, chests paid no skin cases at all.** The `CHEST_LOOT` skincase
    row (2026-10-10) is read only by `rollChestLoot`, whose only caller,
    `giveDrop`, is never called. Wall chests open through `openChestBlock`.
- **Tutorial chests** force how many packs drop through the `PackQty` attribute.
- **Persist bag.** Mid and deep layers have a small chance (0.8% / 0.4%, times
  `chestLuck`) at a one-off bag that adds `backpackBonus`.

**Rank aging.** Unlocking a zone runs `MineZoneChests.onPermanentZoneUnlocked`.
Every earlier zone's pool ages one rank (S→A→…→D→F, extinct) and the next S chest
is injected from `S_QUEUE`.

## How it works — lucky blocks
- **Found.** Every break of ordinary rock rolls `MineConfig.LUCKY_BLOCK_CHANCE`
  (0.0002) × (1 + `luckyFind`). Ore, chests and cores don't roll. The code is the
  last `else` branch of the break handler.
- **Type.** `MineLuckyBlocks.PIT_WEIGHTS` sets the mix: Lucky 80, Diamond 15,
  Godly 5. The ids are `lucky_block`, `super_lucky_block`, `godly_lucky_block`.
- **Starting grade.** A found block may start graded (`PRESET_WEIGHTS`: F 70,
  D 18, C 8, B 3, A 1).
- **Other sources.** The battle-pass track, the credits shop (45 / 120 / 280
  credits, or 10 for 350), rotating offers and the Weekend Haul product.
- **Stored** in `p.packs` as `kind = "lucky_block"`. The stack key is
  block | grade | luck | levels bought (`stackKey`).
- **Grade-ups are off** (owner, 2026-10-10: *"Remove grade-ups"*).
  `MineLuckyBlocks.GRADE_UP_ON` is false, so `gradeUpPrice` returns nil. That
  hides the GRADE UP button, and `Verbs.luckyGradeUp` refuses. Blocks that
  already bought levels keep them. When it was on, it cost `GRADE_UP_BASE`
  25,000 × `GRADE_UP_GROWTH` 5^n gems.
- **Opening.** `Verbs.openLucky` climbs the grade with `MineToolGrades.rollClash`.
  The odds per step are `UPGRADE_P` {½, ½, ⅓, ¼, 2/7, 2/7, 2/7}, and three misses
  end the climb. SSS lands about 0.85% of the time, per the comment on
  `UPGRADE_P`.
- **Loot: cases, plus fixed gems and stardust** (owner, 2026-10-10: the blocks
  were *"hella boring, and not worth shit"*). Every number is PROPOSED.
  - **The owner's rules.** Gems and stardust stay, as **fixed** amounts
    (*"not scaled.. good way to break economy"*), and kept small. Pets, skins
    and charms come **through cases**: *"it should give cases/packs to give you
    pets, skins and charms"*. A better block or grade pays a better case; there
    is no % luck boost.
  - **Gone:** zone packs, the dead shop pickaxes, scrolls and the direct pet
    roll (and with it the lucky-block pet mint).
  - **The four kinds** are in `KIND_TABLES`, by block and grade band:
    - **mystery**: a wild pack case (`MYSTERY_CASE`). One spin, then 3 of the
      set pack it lands on ([pack-cases](pack-cases.md)). This is where pets
      come from.
    - **skincase**: an ore case (`<ore>_ore_case`). It opens to a skin, or that
      ore's charm. The server picks an ore evenly from the block's tier range
      (`SKIN_CASE_TIERS`), so a deeper ore means a better charm.
    - **gems** and **dust**: the fixed `GEMS` and `DUST` ranges.
  - **The Godly stardust bonus** on every open is unchanged.
  - **A book bundle with every block** (owner, 2026-10-12: *"Book buddles from
    lucky blocks, and chest(not cases)"*): Lucky 2 books, Diamond 3, Godly 5,
    on top of the loot (`MineEnchants.LUCKY_BUNDLE`). The end of the reveal
    lists them. Chests drop bundles too, and cases never do. See
    [enchants](enchants.md).

  Which mystery case each block pays, by final grade:

  | block | F/D | C | B | A | S | SS | SSS |
  |---|---|---|---|---|---|---|---|
  | Lucky | ★ | ★½ | ★★ | ★★½ | ★★★ | ★★★½ | ★★★★ |
  | Diamond | ★★ | ★★½ | ★★★ | ★★★½ | ★★★★ | ★★★★½ | ★★★★★ |
  | Godly | ★★★ | ★★★½ | ★★★★ | ★★★★ | ★★★★½ | ★★★★★ | 2× ★★★★★ |

  Skin case ore tiers, by band (low F/D, mid C/B, high A/S, top SS/SSS):
  Lucky 1–10 / 8–20 / 15–30 / 25–40, Diamond 15–30 / 25–40 / 35–55 / 45–65, and
  Godly 35–55 / 45–65 / 55–75 / 65–82.

  Chance per open from an F start (computed from the same tables, 2026-10-10):

  | block | mystery case | skin case | gems | stardust |
  |---|---|---|---|---|
  | Lucky | 44.3% | 14.3% | 20.7% | 20.7% |
  | Diamond | 51.9% | 19.2% | 14.6% | 14.3% |
  | Godly | 56.8% | 24.0% | 9.8% | 9.4% |

  - **Granted** by `openLuckyBlock` in MineServer: `MineCases.bagRow(caseId)`
    × qty, or the same ore case row a broken ore block drops.
  - Mystery cases from lucky blocks are **not** `paid`, so they never reach the
    0.5% SSS-set share that credit-bought cases have.
  - **The loot card** (`MineGradeReveal` `lootRows`) shows a mystery case with
    its case art and name, and a skin case in its ore's colour. SKIP ALL
    totals the cases.
  - Checked in Studio on 2026-10-10: 15 opens across all three blocks paid ★
    to ★★★★★ cases, two skin cases (Peridot, Starmetal) and stardust. They
    were in the bag, and the card showed "2x ★★★★★ Wild Case".
  - *History:* until 2026-10-08 the loot card left out pets and potions, which
    showed only through the `lootText` fallback.
- **The lucky screen** is the lucky path in `MineGradeReveal` (`LuckyReveal`).
  `MineClient` now passes `displayOrder = 120`, the same layer as the pack
  reveal and the case reel. It had sat on the module default, 95, because
  `bca50ca` meant to move it but changed `caseSpin` instead.
- **The win** plays the tier stinger, and S and up add the `MineCelebrate`
  title. It had no win sound before. The title ("SSS!") is cleared when you
  collect, close, or start the next block or case spin (`clearCelebration`,
  2026-10-10). It used to hold about 3.7 s over whatever came next. Owner:
  *"make it so the sss doesnt stick around"*.
- **Odds are shown (since 2026-10-08).** Blocks are sold for credits, which
  Robux buy, and Roblox requires paid random items to show odds. They showed
  none. Now:
  - `MineLuckyBlocks.gradeOdds(start)` computes the final-grade odds
    **exactly**, by walking the same climb `rollClash` runs.
  - `oddsSheet` folds in `KIND_TABLES`, the loot rows `rollLoot` reads.
    `PET_TABLES` is empty since the 2026-10-10 redo, because pets come out of
    the cases.
  - `MineLuckyOddsView` draws the sheet in three places: an ODDS button on
    every credit-shop row, the bag tile's ⓘ (which used to open the unrelated
    pack inspector), and an ODDS button on the lucky screen, for the grade
    the block is on now.
  - `tools/verify/lucky-odds.js` guards all of it. Since 2026-10-10 it also
    checks that every prize is a real wild case and an ore tier that exists,
    that a better grade or block never pays a worse case, and that grade-ups
    are off.
  - From F the grade odds are F 12.5%, D 18.8%, C 31.0%, B 23.0%, A 8.8%,
    S 3.68%, SS 1.45% and SSS 0.85%. That matches the table in the module
    comment.
- **The Limited tab drew nothing past its first offer** until 2026-10-08.
  `iconArt` was a local of the shop's Home branch, so it read as a nil global
  in Limited and threw. All three lucky rows and the 10× bundle sat below that
  line. It is module-level now.
- **One name: "Godly Lucky Block"** (owner, 2026-10-10: "Godly everywhere").
  It used to have three: id `godly_lucky_block`, the name "Mythic Lucky Block"
  (in the bag, the lucky screen, quests and the pass) and the shop label "Goldy
  Lucky Block". Every name and label is Godly now, and so are the offer texts
  (`MineRotatingOffers`: "Godly Cube"). "Mythic" stays a pet and card rarity
  only.

## Where it lives
| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineZoneChests.luau` | zone chest defs, pools, exclusives, payouts | `DEFS`, `POOLS`, `rollSpawn`, `exclusiveFor`, `rollPackDrops`, `GEM_MULT` |
| `src/ReplicatedStorage/Mine/Shared/Mine1ChestsData.luau` | 80-row catalog of chests with layer bands | `layers`, `weight`, `packs` |
| `src/ReplicatedStorage/Mine/Shared/MineChestRanks.luau` | S..F ladder and aging | `WEIGHT`, `agePool`, `roll` |
| `src/ReplicatedStorage/Mine/Shared/MineChestModel.luau` | the visible chest | `PALETTE` |
| `src/ReplicatedStorage/Mine/Shared/MineLuckyBlocks.luau` | types, shop rows, loot tables | `TYPES`, `SHOP`, `UPGRADE_P`, `KIND_TABLES`, `MYSTERY_CASE`, `SKIN_CASE_TIERS`, `rollLoot`, `GRADE_UP_ON` |
| MineServer | spawn, break, open | `rollKind`, `openChestBlock`, `openLuckyBlock`, `Verbs.openLucky`, `Verbs.luckyGradeUp` (refuses) |

## Decided by the owner
- **Lucky screen layering is fixed and confirmed in engine.** Owner, after
  pulling: *"inventory is under"* (TODO §0.32). It is the first change on the
  branch that anyone confirmed by running it.
- **PROPOSAL §0 line 21** ("chest coin reward: FIX THE CRASH") is approved and
  marked fixed. See the gotcha below.
- **Chests do not drop charms.** Charms drop from ore (TODO §0.13 rule 5).
- **Lucky blocks pay cases, plus fixed gems and stardust, and grade-ups are
  gone** (2026-10-10, see Loot above). The numbers are PROPOSED.

## State right now
- **Shipped, and mostly inherited.** These modules last changed in the import or
  in fossil removal (`ba345b7`).
- **Lucky blocks are on the AUDIT §5 ARCHIVE list** ("a second gacha"). That is a
  proposal; the owner's yes to the cut list is not recorded, and nothing has been
  archived.

## Gotchas
- **The crash fix landed in dead code** (static read). PROPOSAL line 21 was fixed
  in `e77d84e` inside `rollChestLoot`. Only `giveDrop` calls that function, and
  **nothing calls `giveDrop`**. Live chests pay through
  `MineZoneChests.rollCurrency`, which never had the crash. The same dead path is
  the only caller of `MinePackConfig.rollChest`, `MinePackConfig.CHESTS` and
  `MineConfig.chestPackCount`.
- **Chest flagship tools never roll from zone chests** (static read, the
  global-read trap). `openChestBlock` checks `if rollChestTool then`, but
  `local function rollChestTool` is declared about 2,600 lines lower. At that
  call site the name is a nil global, so the "Secrets" tools cannot drop there.
  Only `openFrom` reaches it, and that path needs chest items in `p.backpack`,
  which nothing creates any more.
- **A catalog `m1_*` chest's own loot table is never used** (static read). The
  block shows that chest, but `ZoneChests.def` does not know the id, so opening
  re-rolls from the zone pool. In Meadow and Event Horizon the section chest
  always wins anyway.
- **Rank aging is server-wide and in memory** (static read). `POOLS` is module
  state. Any player's unlock ages it for everyone in that server, and a server
  restart resets it.
- ~~**One lucky block has three names.**~~ Resolved 2026-10-10: "Godly Lucky
  Block" everywhere (see above).

## Open questions
- **Give the five chest kinds different silhouettes?** They are one shape in
  five palettes today (see above), which is the problem `MineChestModel`'s
  header set out to solve. Cheapest fix that would actually read at shaft
  distance: vary the lid (flat plank vs ribbed barrel vs domed), the lock plate
  and the foot count per kind, inside the existing builder — no new assets.
- Archive lucky blocks or keep them (AUDIT §5)?
- Should the dead `giveDrop` path be deleted, or should flagship chest tools be
  reconnected? See [open-questions](../open-questions.md).
- "Chests spawn everywhere but supremely rare, like ore" (OPEN P2) is not started.

## See also
[cards-and-packs](cards-and-packs.md) · [mining-and-breaking](mining-and-breaking.md) · [zones-layers-and-seams](zones-layers-and-seams.md) · [shops-and-monetisation](shops-and-monetisation.md) · [luau-traps](../code/luau-traps.md)
