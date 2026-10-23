---
title: Chests and lucky blocks
type: system
status: current
verified: 2026-10-19 @ 3863d14
sources:
  - src/ReplicatedStorage/Mine/Shared/MineZoneChests.luau
  - src/ReplicatedStorage/Mine/Shared/MineSetChests.luau
  - src/ReplicatedStorage/Mine/Shared/MineEnchants.luau
  - tools/verify/chest-ranks.js
  - tools/verify/economy-gems.js
  - tools/cursor/tasks/chest-and-charm-icons.md
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
related: [cards-and-packs, mining-and-breaking, zones-layers-and-seams, shops-and-monetisation, currencies-and-economy, charms, pack-cases, enchants]
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
| Candy Crypt | ×3 (was 0 until 2026-10-19) | `zone.chestMult`; one of eight Crypt chest ranks (F..SSS, Halloween names, `MineCryptChests`), rarer deeper, paying Halloween packs, flat candy, the rank's Halloween charm (0.5% x Chest Luck) and Halloween books, through `MineCrypt.openChest`, not the zone-chest tables ([world-events](world-events.md)) |
| Meadow, layers 1–100 | ×2 | `MEADOW_SHALLOW_CHEST_MULT` |
| during a World Pulse | ×`worldChestMult` | disabled, see [world-events](world-events.md) |

**Which chest it is: rank first, F to SSS** (owner, 2026-10-19: chests rank F to
SSS like packs and charms, *"all separate names"*, the rank shown as a badge).
`MineZoneChests.rollSpawn(zone, layer, zoneIndex, better)` draws one row of
`MineZoneChests.spawnTable`, which lists every chest a block there can be with
its exact chance:
- **The rank** comes from `MineChestRanks.odds(better)`. `WEIGHT` is F 480, D 280,
  C 140, B 64, A 25, S 8, SS 2.5, SSS 1. At a zone's top that is F 48.0%, D 28.0%,
  C 14.0%, B 6.4%, A 2.5%, S 0.8%, SS 0.25% and SSS 0.1% of chests.
- **Better chests deeper** (owner, 2026-10-10/11). How MANY chests stays
  `CHEST_CHANCE` everywhere; how GOOD they are rises with depth inside every zone
  except Dirt Meadow. `MineConfig.chestRankLuck(zone, layer)` is ×1 at a zone's top
  and ×3 at its floor, on a log of block HP, so it is front-loaded: ×1.7 at layer
  100, ×2.2 at 500, ×2.45 at 1,000. Each rank's weight is multiplied by
  `better ^ LIFT` (`MineChestRanks.LIFT`: F and D 0, C 0.25, B 0.5, A 0.75, S 1,
  SS 1.25, SSS 1.5), so the rarer the rank, the harder depth lifts it. At a floor:
  F 41.7%, D 24.3%, C 16.0%, B 9.6%, A 4.95%, S 2.08%, SS 0.86%, SSS 0.45%. Meadow
  and the event mines stay ×1. The owner's reason: *"i can picture people with
  explosoves nuking starter mine bcuz everything is one shot. there should be
  incentive to go a little deeper"*. `tools/verify/chest-depth.js` checks it.
- **Then the chest.** Every zone has a chest of every rank, each with its own
  name (`MineZoneChests.ZONE_CHESTS`). Two chests of one rank split its share.
  Dirt Meadow runs F Topsoil Cache and Sod Crate, D Rootbox, C Briar Chest,
  B Hillock Cache, A Loam Vault, S Sunrise Strongbox, SS Dewvault and SSS Canopy
  Coffer. Event Horizon runs F Event Cache up to SSS Big Bang Crown. Its Nebula
  Locker (B), Quasar Reliquary (SS) and Big Bang Crown (SSS) are new and have no
  icon yet.
- **Set chests** (`MineSetChests`; owner, 2026-10-19: *each of the 19 pack sets
  gets 3 named chests of its own, a low, a mid and a high rank, paying that set's
  packs, where that set's pets live*). Ids are `<set>_chest_low` (rank D), `_mid`
  (B) and `_high` (S). A set lives in one zone (`SETS[i].zoneId`, from layer
  `from`): Pebblebound in Dirt Meadow, then two sets per zone from Greyvein Quarry
  to Primordium Heart, the first from layer 1 and the second from layer 250. At
  ranks D, B and S, `SHARE` 0.2 of that rank's chests are a living set's chest,
  split between the sets living there. So the chest count and the rank split do
  not change. The 57 names are PROPOSED for the owner to approve:

  | set | low (D) | mid (B) | high (S) |
  |---|---|---|---|
  | Pebblebound | Pebble Pouch | Geode Crate | Earthheart Coffer |
  | Sugar Rush | Gumdrop Tin | Lollipop Locker | Candy Castle Chest |
  | Mosswood | Mossy Stump Box | Fern Hollow Chest | Heartwood Hoard |
  | Lost & Found | Lost Luggage | Map Maker's Trunk | Forgotten Treasure Chest |
  | Starfront | Supply Pod | Cargo Capsule | Starship Vault |
  | Arcade Legends | Token Tub | Prize Crane Box | High Score Safe |
  | Crystal Hollow | Quartz Crate | Amethyst Coffer | Prismatic Geode Vault |
  | Shogun's Oath | Bamboo Box | Lacquer Chest | Gold-Leaf Treasury |
  | Royal Reserve | Velvet Purse | Crown Jewel Case | Sovereign's Vault |
  | Crimson Eclipse | Red Moon Box | Midnight Reliquary | Eclipse Crown Coffer |
  | Holo Havoc | Foil Tin | Chrome Locker | Hyperholo Vault |
  | Rainbow Road | Pastel Pail | Prism Trunk | Celestial Rainbow Chest |
  | Infernal Reign | Cinder Crate | Obsidian Strongbox | Magma Citadel Vault |
  | Atlantis Rising | Tidepool Clam | Coral Coffer | Sunken City Vault |
  | Divine Relics | Idol Box | Sacred Ark | Pantheon Reliquary |
  | Dragonfall | Hatchling Nest | Drakefire Coffer | Great Wyrm Hoard |
  | Eternal Roots | Root Knot Box | Spring Hollow Chest | World Root Vault |
  | Mythic Menagerie | Egg Basket | Beast Den Crate | Titan's Nest |
  | Chaos Theory | Glitch Box | Paradox Cube | Fractured Reality Vault |

- **The Shiny Chest (chase, rank S)** takes its chance off the top of the table.
  In zone 1 it can appear only at layer ≥ 2500, at 1/8000. In zones 2–10 the
  chance lerps from 1/2500 up to 0.8%.
- **Retired on 2026-10-19:** the Mine 1 catalog chests (`Mine1ChestsData` through
  `MinePackConfig.rollChestAt`, 45% of chests) no longer spawn, and rank aging
  (`agePool`, `onPermanentZoneUnlocked`) does nothing. A block that spawned
  earlier with an id the table does not know re-rolls from its zone's spawn table
  when opened.

**The badge.** The rank shows as a letter in `MineChestRanks.COLOR` on the
chest's lid (`MineChestModel`, from the block's `ChestRank` attribute), on the
hover line and the chest card ("Name · S"), and on the chest dex tile
(Collection → Chests). S, SS and SSS also play the pluck sound.
`MineChestRanks.badge(rank)` reads "S · Mythic"; the words are the packs'
(`LABEL`, Common to Exotic).

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

**What a chest pays** (`openChestBlock` in MineServer, from
`MineZoneChests.payout(def, zone, layer)`; every number PROPOSED 2026-10-19):
- **The chest def** is the block's own (`ZoneChests.def`), paid by its rank. The
  old Meadow and Event Horizon override, which paid a section chest from
  `exclusiveFor` instead, is gone.
- **Coins and gems.** The means are `COIN_BASE[zone]` (`flat` plus `perHp` ×
  the dirt HP at the layer) × `PAY[rank]` and `GEM_BASE[zone]` × `PAY[rank]`, rolled
  in a band of ±30% for coins (`COIN_SPREAD`) and ±20% for gems (`GEM_SPREAD`), then
  multiplied by `coinBonus` and `gemFind`. `PAY` is F 0.55, D 0.85, C 1.2, B 1.7,
  A 2.4, S 3.5, SS 5.5, SSS 9. A chest pays its home zone's bases; the Shiny
  Chest pays where it is opened. Dirt Meadow and Event Horizon chests pay no gems
  (`GEM_BASE` 0), and Meadow's first 50 layers pay ×3 coins
  (`MEADOW_EARLY_LAYERS`, `MEADOW_EARLY_COIN_MULT`). In Greyvein Quarry at layer 1,
  the F Flagstone Chest pays 26–49 coins and 502–752 gems; the SSS Slate Crown pays
  432–803 coins and 8,208–12,312 gems.
- **Stardust** from the `scrap` stat.
- **Packs.** Each slot is an independent roll of `PACK_BASE[zone][slot]` ×
  `PACK_MULT[slot][rank]` percent (`rollPackDrops`). Over 100% pays one for sure
  and rolls the rest. A rarer rank pays more rare and legendary packs and fewer
  common ones. A legendary pack fires the "BONKERS PACK" popup.
  - **A set chest** pays one of its own set's packs for sure instead of the
    zone's card packs, plus the currency slots. Low pays ★, mid ★★★, high ★★★★
    (70%) or ★★★★★ (30%) (`MineSetChests.PACK_STARS`). The pack goes in the bag
    as a set pack row (`MineCases.packRow`).
- **Pack cases.** A zone chest can also drop a wild pack case
  (`MineCases.rollChestCase`, 2026-10-10).
  - *Decided* by the owner, 2026-10-10. 10% of chests drop one
    (`MineCases.CHEST_CASE_CHANCE`).
  - Each case grade is half as common as the one below.
  - A better rank starts the ladder higher, in half-star steps
    (`CHEST_RANK_SHIFT`: F −0.5, D 0, C 0.5, B 1.25, A 2, S 2.75, SS 3.5, SSS 4.5;
    a fraction mixes the two whole shifts). An F chest drops a case 7.5% of the
    time, every other rank 10%.
  - Chest luck raises the chance, up to ×3. See [pack-cases](pack-cases.md).
- **Skin cases** (owner, 2026-10-11: skins follow the pack cases' *"same
  logic/rates"*; chose "better chests → better skin tiers").
  - 3% of zone chests drop one (`MineConfig.CHEST_SKIN_CASE_CHANCE`), raised by
    chest luck up to ×3. It opens on the spot: a skin of the rolled tier, or
    stardust for a duplicate (`Dig.grantChestSkin`).
  - The tier comes from `SKIN_CASE_TIERS`, shifted up by the chest's rank
    (`CHEST_SKIN_RANK_SHIFT`: C 0.5, B 1, A 2, S 3, SS 4, SSS 5; F and D roll it as
    written). The case is SSS 0.4% of the time from an F or D chest, 6.4% from an
    S chest and 19% from an SSS chest.
- **Book bundles and enchant XP** by rank: B and A chests give 3 books, S and SS 4,
  SSS 5 (`MineEnchants.CHEST_BUNDLE`); level II and III chances run from C 5%/0% to
  SSS 60%/25% (`BOOK_RANK_LEVEL`); XP is × `XP_CHEST_RANK` (F 0.8 … SSS 7). See
  [enchants](enchants.md).
- **A charm,** 0.5% × chest luck: the rarity by the 36 graded charms' old
  shares, then any charm of that rarity ([charms](charms.md)).
- **The average chest pays what it did on `3863d14`.** `tools/verify/economy-gems.js`
  sums the spawn table at 77 depths. Gems are within 3.5% everywhere, coins within
  6.1%, cases, skins, books and XP within 10.2%, and each pack slot within 18.1%.
  The cards in its packs rise at most 30.3%, in Meadow's first layers, where the
  Pebblebound chests are new, and about 0% deeper.
  - **Before this, chests paid no skin cases at all.** The `CHEST_LOOT` skincase
    row (2026-10-10) is read only by `rollChestLoot`, whose only caller,
    `giveDrop`, is never called. Wall chests open through `openChestBlock`.
- **Tutorial chests** force how many packs drop through the `PackQty` attribute.
- **Persist bag.** Mid and deep layers have a small chance (0.8% / 0.4%, times
  `chestLuck`) at a one-off bag that adds `backpackBonus`.

**Rank aging is retired** (2026-10-19). Unlocking a zone used to age every
earlier zone's pool one rank. Ranks are fixed now, so
`MineZoneChests.onPermanentZoneUnlocked` does nothing and stays only for old callers.

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
    roll (and with it the lucky-block pet mint). Scrolls then left the game
    entirely on 2026-10-12, with runes ([traits](traits.md)).
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
    its case art and name, and a skin case in its ore's colour. SKIP ALL's
    card (`runRows`) lists the whole run the same way: each mystery and skin
    case by name with its count, potions, tools, gems, stardust and the
    enchant books. Until 2026-10-19 (launch audit S29) it showed only gems,
    stardust and a case count.
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
| `src/ReplicatedStorage/Mine/Shared/MineZoneChests.luau` | every chest by zone and rank, the spawn table, payouts | `ZONE_CHESTS`, `DEFS`, `spawnTable`, `rollSpawn`, `roll`, `payout`, `rollCurrency`, `rollPackDrops`, `PAY`, `GEM_BASE`, `COIN_BASE`, `PACK_BASE`, `PACK_MULT` |
| `src/ReplicatedStorage/Mine/Shared/MineSetChests.luau` | the 19 sets' 57 chests, where they live, their packs | `SETS`, `RANK`, `SHARE`, `PACK_STARS`, `chestId`, `livingAt`, `rollPack` |
| `src/ReplicatedStorage/Mine/Shared/MineChestRanks.luau` | the F..SSS ladder, depth lift, badge | `LADDER`, `WEIGHT`, `LIFT`, `COLOR`, `LABEL`, `odds`, `badge` |
| `src/ReplicatedStorage/Mine/Shared/Mine1ChestsData.luau` | 80-row Mine 1 catalog; no longer spawns (2026-10-19) | `layers`, `weight`, `packs` |
| `src/ReplicatedStorage/Mine/Shared/MineChestModel.luau` | the visible chest and its lid badge | `PALETTE`, `RankBadge` |
| `src/ReplicatedStorage/Mine/Shared/MineLuckyBlocks.luau` | types, shop rows, loot tables | `TYPES`, `SHOP`, `UPGRADE_P`, `KIND_TABLES`, `MYSTERY_CASE`, `SKIN_CASE_TIERS`, `rollLoot`, `GRADE_UP_ON` |
| MineServer | spawn, break, open | `rollKind`, `openChestBlock`, `openLuckyBlock`, `Verbs.openLucky`, `Verbs.luckyGradeUp` (refuses) |

## Decided by the owner
- **Lucky screen layering is fixed and confirmed in engine.** Owner, after
  pulling: *"inventory is under"* (TODO §0.32). It is the first change on the
  branch that anyone confirmed by running it.
- **PROPOSAL §0 line 21** ("chest coin reward: FIX THE CRASH") is approved and
  marked fixed. See the gotcha below.
- **Chests drop graded charms at 0.5%** (2026-10-07, settled 2026-10-17; TODO
  §0.13 rule 5 amended). See [charms](charms.md).
- **F to SSS chests, every one named, the rank as a badge, three named chests per
  pack set** (2026-10-19, [open-questions](../open-questions.md) §0e). The
  numbers and the 57 names are PROPOSED.
- **Lucky blocks pay cases, plus fixed gems and stardust, and grade-ups are
  gone** (2026-10-10, see Loot above). The numbers are PROPOSED.

## State right now
- **The F..SSS chests and the set chests are built and harnessed, never run in
  the engine** (2026-10-19). `tools/verify/chest-ranks.js` runs the real modules
  (the ladder, the spawn table at every zone, the payouts, the set chests and the
  wiring). `tools/verify/economy-gems.js` compares an average chest and the gems
  per hour with `3863d14`.
- **Chest icons:** the set chests, the three new Event Horizon chests and the
  Shiny Chest have none yet. `tools/cursor/tasks/chest-and-charm-icons.md` is the
  Cursor job that draws them.
- **Lucky blocks are mostly inherited.** They last changed in the import or in
  fossil removal (`ba345b7`).
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
- ~~**Chest flagship tools never roll from zone chests**~~ **FIXED 2026-10-14.**
  Was the global-read trap: `openChestBlock` saw a nil `rollChestTool` because
  the real function was a later `local function`. Now forward-declared before
  `openChestBlock` and assigned with `function rollChestTool`.
  `tools/verify/chest-tools.js` pins it. Zone chests roll Secrets again.
- **Catalog `m1_*` chests no longer spawn** (2026-10-19). A block that spawned
  before carrying one re-rolls from its zone's spawn table when it is opened.
- ~~**Rank aging is server-wide and in memory.**~~ Retired 2026-10-19: ranks are
  fixed.
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
