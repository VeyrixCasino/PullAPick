---
title: Cards and packs
type: system
status: current
verified: 2026-10-10 @ f6baac2
sources:
  - src/ReplicatedStorage/Mine/Shared/MineCards.luau
  - src/ReplicatedStorage/Mine/Shared/MineSetPacks.luau
  - src/ReplicatedStorage/Mine/Shared/MineSetPets.luau
  - src/ReplicatedStorage/Mine/Shared/MinePetRoster.luau
  - src/ReplicatedStorage/Mine/Shared/MinePackConfig.luau
  - src/ReplicatedStorage/Mine/Shared/Mine1PacksData.luau
  - src/ReplicatedStorage/Mine/Shared/MineZonePacks.luau
  - src/ReplicatedStorage/Mine/Shared/MineLootPacks.luau
  - src/ReplicatedStorage/Mine/Shared/MinePackReveal.luau
  - src/ReplicatedStorage/Mine/Shared/MinePackFX.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - tools/verify/buyqty.js
  - tools/verify/orepacks.js
  - docs/TODO.md §0, §9
  - docs/PROPOSAL.md §0, §I
related: [pets, chests-and-lucky-blocks, shops-and-monetisation, skins-cases-and-temper, charms, ore-pouch-and-backpack, trading]
---

# Cards and packs

> The game is *Mine For Cards*: a **card is a pet**. Packs are sealed bags of
> cards (or runes, gear, coins) that you find in chests, earn, or buy with
> credits, then rip open in a tap-through reveal. The pet's power is covered in
> [pets](pets.md); this page covers where cards come from.

`MineServer` below means `src/ServerScriptService/Mine/MineServer.server.luau`.

## How it works

**A card is a pet.** The comment on `MineConfig.ITEM_BAG_FIELDS` says it directly: "a pet IS a card here, p.equipped holds pet card ids".

**Card identity is procedural.** `MineCards.getCard(setId, index)` builds the
card from its set and its index. The name is a PREFIX plus a SPECIES, for example
"Ember Fox". Rarity comes from where the index sits in the set
(`rarityFromIndex`), and indices past `cardCount` are the secret Exotics.
`MineCards.SETS` holds **41 sets**: 26 Season-1 sets (including three `le_*`
limited sets), 3 Horizon sets, and 12 sets for zones 7–10. Each zone lists three
sets, and `MineConfig.setForLayer` picks one by depth, switching at 25% and 60%
of `MineConfig.LAYERS`. Every serial is claimed in a global registry by `mint` in
MineServer, which is what makes trading safe.

**Who comes out of a pack: named pets only** (owner, 2026-10-10: old
generated cards *"stop dropping"*). Since then `openPack` mints from two
sources; the old card sets below now only supply a fallback rarity:
- **A set pack** (`<setkey>_pack_1..6`, `MineSetPacks`) pays only its own
  set's named pets (`MinePetRoster.BY_SET`). This is the owner's *"make some
  packs draw certain cards"*.
- **Every other card pack pays from a zone pot** (`MinePetRoster.BY_ZONE`, 70
  named pets a zone). The zone is the pack's own (a zone pack, or a pack found
  in a zone). Failing that, it is the zone that lists the pack's old set, or
  the zone the set is named after (Bloodmoon, Eclipse, Mythral). A "Universal"
  set's pack pays from the deepest regular zone the player has opened.
  Event Horizon packs pay Event Horizon pets.
- **The rarity is rolled exactly as before**, from the same tables; only *who*
  changes. `MineSetPacks.pickPet` picks a pet of that rarity, falls a rarity
  down if the pot has none, and never picks a holiday pet.
- **The card** is `MineSetPacks.petCard`: `setId` is the pet's home (set key
  or zone id), and `cardKey` is `"<home>:<name>"`, so copies from packs merge.
- **The starter bundle's free pet** is a meadow Common from the pot.
- **Old cards already owned keep working** and stay tradeable.
- Verified in a Studio play test (2026-10-10): meadow, eclipse, primordium and
  Event Horizon packs paid named pets of their own zone.

**The old set system, for reference** (counted 2026-10-10, before the switch):
- **Size.** 41 sets hold **4,023 card slots, but only 207 distinct pets.** Names
  come from 16 prefixes × 16 species, and the body is one of those 16 species.
  The same "Ember Fox" can be Common in one set and Exotic in another.
- **A chest pack** found while mining gets its zone's set by depth
  (`setForLayer`). One zone has 217–333 slots, holding 96–165 distinct pets, and
  most of those names repeat in every other zone.
- **Every other pack picks a random set from all 41.** That covers shop,
  bundles, stardust, daily rewards, quests and the wheel (`Verbs.grantPacks`,
  `SET_IDS`). A Meadow player can open a Primordium or Event Horizon set. 9 sets
  (837 slots) are reachable only this way, because no zone lists them.
- **Mythral lists `"brutalcrusher"`, which is a tool id, as a set.** So
  `mythral_choir` is reachable only at random.
- The old card sets now only supply the rarity for a pack that has no `odds`
  table of its own (`MineCards.rollPack`, the fallback below).

The owner's rework (`docs/PETS-AND-SETS.md`): zone pots plus 19 exclusive sets.

**The 8-rung rarity ladder** is Common, Uncommon, Rare, Epic, Legendary, Mythic,
Divine, Exotic (`MineCards.RARITY_ORDER` = `MinePackConfig.TIERS`). The old TCG
names (HoloRare, UltraRare, HyperRare, SecretRare) are kept as aliases in
`MineCards.RARITY_ALIAS`, so cards in old saves still sort correctly.

**What a pack rolls.** These are the steps in `openPack` in MineServer:
1. **Tier.** It comes from the pack's own `odds` table (`MinePackConfig.rollCard`).
   If the row carries stamped pack luck, `siphonOdds` moves weight from Epic and
   below onto Legendary and up, **in proportion to the weight those rungs
   already have**.
2. **God Pack.** The chance is half the pack's Exotic %
   (`godPackChancePercent`). When it hits, every card in the pack is Mythic or
   better (`rollGodCard`).
3. **Which pet.** A named pet of that rarity, from the set (set packs) or the
   zone pot (everything else); see "Who comes out of a pack" above. The old
   per-pack 60% card window (`cardPoolFor`) no longer decides anything.
4. **Variant.** `variantOdds` overrides each pack's own `variants` row. Every
   pack pays Golden 1% and nothing else (`VARIANT_BASE`), except the packs named
   in `VARIANT_HEADLINE`, such as `void_pack` at Void 2%.
5. **Finish.** Shiny is the pack's `shiny` % (default `SHINY_CHANCE` 4). One shiny
   in 100 comes out Shadow instead (`MineConfig.SHADOW_OF_SHINY`); the Shiny Pack
   uses 1 in 20.
6. **Fallback.** `MineCards.HIT` / `slotOdds` (softened by `SLOT_SOFTEN` 3) is
   used only when a pack has no `odds` table of its own.

**Stars and the pack order in the inventory** (2026-10-10, uncommitted at the time of writing).
- `MinePackConfig.packStars` is derived from a pack's odds, card count and shiny rate on a
  log scale between the weakest and strongest `Mine1PacksData` row. A row's own
  `stars` field, if set, wins, so hand-rated packs do not drift.
- `MinePackConfig.isRated` covers every pack in `PACK_BY_ID` (the set packs and pack
  cases included) **and the zone card packs**. Owner, 2026-10-10: *"EVERY PACK HAS A
  STAR VALUE"*. This reversed the old "zone packs carry no stars". In every zone,
  `ZONE_PACK_STARS` makes the Pack ★, the Rare Pack ★★ and the Legendary Pack
  ★★★. Currency pouches and ore cases stay unrated.
- A set case shows its set's grade instead of stars ([pack-cases](pack-cases.md)).
- Inventory pack tiles draw the star row at y 86 (same as lucky blocks) and print
  `Set · Grade` on the set line when the set has a `grade` (`MineCards.setGrade`).
  No Season-1 set has one yet, so grades appear once the 19 graded sets are wired.
- The default order is **best first**: stars, then set grade
  (`MineCards.GRADE_RANK`, falling back to the set's T1–T9 tier), then odds tier,
  luck, name. Owner: *"5 star pebble bound trumps 4.5 star Chaos Theory"*. This
  replaced the old worst-first order. Lucky blocks stay pinned first.
- **The star row** (`MineInventoryView` `starRow`) draws each star in its own
  cell with the glyph centred, filled whole, half or not at all. Until
  2026-10-10 it clipped one "★★★★★" string to a width guessed as 5.1 × the text
  size. BuilderSans draws five stars at 13 px in 40 px, not 66, so a 4-star clip
  covered all five glyphs and the row sat left of centre. Owner: *"these 4 stars
  be saying their 5 star packs ... also stars are far from centered"*.
- Set cases show their grade, not stars, but still sort by their hidden stars:
  Starter ★★, Collector ★★★★, Vault ★★★★★. So a GRADE SSS Collector Case sorts
  after 5-star packs of any grade.

**Order of the reveal.** Cards are sorted worst-to-best **on the server** (by
`MinePackFX.BAND_ORDER`, then by true odds), so each flip is at least as good as
the last. Cards of Rare or better that rolled rarer than 1 in 200 carry an
`oneIn` ribbon, priced by `MinePackConfig.pullOdds`.

**A set's grade scales its odds** (`MineSetPacks.GRADE_ODDS_MULT`, 2026-10-10,
PROPOSED).
- Owner: *"i swear some lower grade packs are pulling nothing but epics"*. They
  then named low-grade set packs.
- Until then the grade never entered the roll. An F set's ★★★★★ pack paid the
  same 60% Epic-or-better per card as the SSS set's.
- Now each Epic-and-up chance is multiplied by F 0.40, D 0.50, C 0.60, B 0.70,
  A 0.80, S 0.90, SS 0.95 or SSS 1.00. The removed share goes back to Common,
  Uncommon and Rare in proportion, so every row still sums to 100.
- ★★★★★ Epic-or-better per card: F 24%, C 36%, B 42%, A 48%, S 54%, SSS 60%.
  ★★★★: F 12.8%, SSS 32%.
- Stars do not change; the pack's value does. Case prices follow
  ([pack-cases](pack-cases.md)).

An audit the same day (a seeded replay of `openPack`, 4,000 opens per set pack)
found no roll bug: every pack paid its table. It also flagged three things,
reported to the owner and not changed:
- Chest-found zone packs use depth only, not the zone. A 1★ Meadow Pack from
  deep layers pays 25% Epic or better.
- `apex_pack` is rated 2.5★ but pays Epic or better 77% of the time (one card).
  **Retired 2026-10-11** (owner: *"we dont need apex pack anymore"*). Nothing
  hands it out now: the four quests that paid it (`merge25`, `merge60`,
  `cards500`, `cards1k`) and the Pot of Gold deal pay a ★★★ Wild Case each
  instead. That case is the nearest in value: about 1,360 stardust expected,
  against Apex's 1,500. Packs already in bags still open. The dead
  `Mine1ChestsData` rows still list it.
- The open-all YOUR HITS screen counts an Epic with a "1 in X" ribbon as a hit.

**The build-up** (`MinePackReveal` `buildUp`, 2026-10-10). Before a Legendary
or better turns over, its back flashes every rarity from Legendary up to the
one below it, twice each, then flickers its own rarity three times. An Exotic
goes Legendary ×2, Mythic ×2, Divine ×2, Exotic ×3. One tap skips straight to
the flip, and the protected window after the flip drops that tap. Rush (mashing)
and SKIP ALL skip it. Epic and below keep the old glow-and-shiver. Owner:
*"make the card flash legendary twice, mythic twice..... and the flicker
whatever it really is 3 times (just a buildup.. one click skips it tho)"*.

**Looking at what you pulled.** When a pack ends, every card in the YOU PULLED
strip can be tapped to lift it to the middle at full size, with its stats. Tap
again to put it back. This broke when TapAnywhere (z-index 24, closes the
reveal) went over the strip (z-index 8): a tap on a card closed the screen. The
strip and the open-all hits grid now rise to z-index 25 while the prompt is up.
The open-all YOUR HITS grid builds each hit full size and scaled down, so its
cards can be tapped too (`addPick`). Checked in Studio on 2026-10-10.

### Pack kinds (the `kind` on a pack definition)
| kind | ids | what opens |
|---|---|---|
| `cards` | `<zone>_pack_common/rare/legendary` (3/4/5 cards) | odds from `MineZonePacks` `cardOdds(zoneIndex, heat)`; a chest-found pack (with `layer`) uses `depthCardOdds` instead |
| `currency` | `<zone>_currency_common/rare` | coins + gems, no cards |
| `holiday` | `halloween_2026` (3 cards) | `MineSetPacks.HOLIDAY_ODDS` (PROPOSED); only its holiday pets, the one pack allowed to pay them. Kind `holiday` keeps it out of the day-4 surprise. Paid by the Trick-or-Treat case. |
| `cards` + `setKey` | `<setkey>_pack_1..6` (★ to ★★★★★; 3, 3, 4, 4, 5, 5 cards) | `MineSetPacks.ODDS` by star grade, scaled by the set's grade (`oddsFor`); only that set's pets |
| card pack, no kind | 19 in `Mine1PacksData` (loam … heirloom; hopper 6 cards, magma 8, apex 1) | own `odds` table |
| `rune` / `gear` | `rune_*_pack`, `gear_*_pack` | `MineLootPacks` rolls one item per slot |
| `ore_case` | `<ore>_ore_case` | a skin or a charm, see [skins-cases-and-temper](skins-cases-and-temper.md) |
| `ore` (legacy) | `<ore>_ore_pack` | ore; converted on load (below) |
| `lucky_block` | stored in `p.packs` | see [chests-and-lucky-blocks](chests-and-lucky-blocks.md) |
| `pack_case` | `case_<1..6>`, `<set>_case_<starter\|collector\|vault>` | packs, never cards; see [pack-cases](pack-cases.md) |

**Where packs come from:** zone chests ([chests-and-lucky-blocks](chests-and-lucky-blocks.md)),
the credits shop ([shops-and-monetisation](shops-and-monetisation.md)), quests
(`MineQuests.CHAIN`), invites and codes (`Verbs.INVITE_REWARD`, `Verbs.CODES`),
the day-4 surprise (`Verbs.claimDailySurprise`), AFK (`Verbs.Afk.grantPack`; 20%
from your top zone, `Const.AFK_TOP_ZONE_SHARE`), lucky blocks and Weekend Haul.

**Opening and buying.** Three verbs open packs: `open`, `openAt` and `openMany`.
`openMany` opens up to `Const.OPEN_RUN_MAX` = 50 packs, but only 3 gear or rune
cases. The owner asked for a typed buy quantity ("a custom amount of packs to
buy… default 1", quoted in `tools/verify/buyqty.js`). It is a TextBox now, and
three ceilings agree at 100: `Const.BUY_QTY_MAX`, `Const.CART_MAX_QTY` and the
view's `CART_QTY_MAX`. A ten-pack costs 70% of ten singles (`BUNDLE_QTY`,
`BUNDLE_RATE`).

**Ore packs are gone, and ore cases replaced them.** An ore block now pays ore
straight into the pouch (the `kind == "ore"` break branch in MineServer) and
rolls a 2% case (`MineConfig.ORE_CASE_CHANCE`). An unopened `_ore_pack` is
banked on load by `Dig.bankOrePacks`:
- it pays the midpoint of the yield band;
- it converts only when the whole yield fits in the pouch;
- it has no version stamp, so it can run again on a later load.

The ids stay registered in `MineZonePacks.get`, so a pack that did not fit can
still be opened by hand. `tools/verify/orepacks.js` guards this.

## Where it lives
| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineCards.luau` | card sets, identity, fallback odds, colours | `SETS`, `getCard`, `HIT`, `slotOdds`, `rollPack` |
| `src/ReplicatedStorage/Mine/Shared/MinePackConfig.luau` | pack odds helpers, prices, God Pack, card pools, stardust shop | `rollCard`, `siphonOdds`, `cardPoolFor`, `variantOdds`, `PACK_PRICE` |
| `src/ReplicatedStorage/Mine/Shared/Mine1PacksData.luau` | 25 authored pack rows | `odds`, `cards`, `shiny`, `kind` |
| `src/ReplicatedStorage/Mine/Shared/MineZonePacks.luau` | 5 generated slots × 11 zones, plus ore packs and cases | `buildAll`, `get`, `SLOTS` |
| `src/ReplicatedStorage/Mine/Shared/MineLootPacks.luau` | rune and gear pack roller | `rollRarity`, `isLoot` |
| `src/ReplicatedStorage/Mine/Shared/MineSetPacks.luau` | the 19 sets' six packs each, the pack cases, the named-pet pick (all numbers PROPOSED) | `PACK_BY_ID`, `ODDS`, `pickPet`, `petCard`, `rollCase`, `casePrice` |
| MineServer | minting, opening, legacy banking | `mint`, `openPack`, `openMany`, `Dig.bankOrePacks` |
| `src/ReplicatedStorage/Mine/Shared/MinePackReveal.luau`, `src/ReplicatedStorage/Mine/Shared/MinePackFX.luau` | the reveal, and the 1.4 s tear (ported from TCG Life) | `mount`, `ART`, `BAND_ORDER`, `pullScore` |

## Decided by the owner
- **Packs close on a tap anywhere**, and DONE is kept as a button. Owner, 2026-10-04: *"PACKS MAKE YOU SAY DONE"* (TODO §0.27, `MinePackReveal`).
- **The reveal sits at DisplayOrder 120**, and the inventory stays open underneath it (TODO §0.27).
- **Fossil packs are deleted.** Any held at load are cashed out (TODO §0.12).
- **Ore ids and `<id>_ore_pack` ids are load-bearing.** Renaming one is a migration (TODO §9).
- **Pity is a CONTRADICTION.** PROPOSAL §0 line 26, approved 2026-10-05, says:
  *"pack pity: Mythic+ guaranteed by pull 25, Divine+ by pull 150"*. Line 28
  raises the Exotic floor. Older text says the opposite: TODO §9 (*"No pity
  systems. No floors, no guarantees after N."*), `docs/decisions.md` (*"No pity
  systems anywhere."*) and the `MinePackConfig` header rule 1. **Neither line 26 nor line 28 is built**: no
  pull counter exists in `src/`. Ask the owner before building either.

## State right now
- **Shipped and inherited.** Most of this code dates from the import (`566eecf`).
- **Recent branch work:** typed buy quantity (`4368c03`), per-pack card pools
  (`c62ba47`), legacy ore-pack banking (`873ba45`), fossil removal (`ba345b7`).
- **Never confirmed in engine**, like the rest of the branch (START-HERE §5).

## Gotchas
- **Meadow zone packs WITHOUT a depth stamp can never pay Mythic, Divine or
  Exotic** (AFK, tutorial and grant packs). `cardOdds(1, heat)` maps zone 1 to
  layer 1, where `t = 0` zeroes those three rungs. Siphon and the God Pack scale
  existing weight, so they stay 0. This was computed from the formula, not
  observed. OPEN P2 says `cardOdds` ignores the zone index; that is stale,
  because it does use it.
  - **A chest-found zone pack is different.** It carries `layer`, and openPack
    swaps its odds for `depthCardOdds(layer, maxL, heat)` (MineServer, about
    line 8507). That uses depth within the zone and ignores the zone itself, so
    a deep Meadow Pack can pay Mythic+ (audit, 2026-10-10).
- **Set packs live in `PACK_BY_ID` but not in `PACKS`.** `MinePackConfig`
  registers them at the end of the file, so every lookup (bag tile, inspector,
  admin grant, opener) finds them, but nothing that walks the universal list
  sells or re-rates them. **One side effect:** the day-4 surprise walks
  `PACK_BY_ID` for packs of 2★ and up, so it can now hand out a set pack.
- **One stack key per named pet** (owner, 2026-10-10: *"fix the merge thing so
  pets stack"*). Stacks and merges compare `cardKey`, and lucky blocks, the
  wheel, devGrant and Event Horizon each used to mint their own
  (`"lucky_block:Name"`...), so copies never stacked. Every named pet now has one
  key, `MinePetRoster.cardKeyOf(name)` = `"<set, holiday pack or zone>:<name>"`;
  `mint` applies it and `load` re-keys old saves. `setId` still records the
  source. Generated cards (`"set#007"`) are untouched.
- **`MinePackConfig.CARD_SUBSET_SHARE` / `cardPoolFor` are now dead for packs**:
  they narrowed the old card sets, which no pack draws from any more.
- **Stale comments in `MinePackConfig`:**
  - the header says packs cannot be bought with coins or gems — true, but they sell for credits;
  - the header's "chest is the identity" text describes `MinePackConfig.CHESTS`, which only a dead path reads ([chests-and-lucky-blocks](chests-and-lucky-blocks.md));
  - the `PACK_PRICE` comment says Apex costs 220 and Hopper 35; the table says 60 and 12.
- **Void is unreachable by merging.** Void is a pack variant (`MinePackConfig.VARIANT_MULT`)
  but is not on the merge ladder `MineConfig.VARIANTS` (Normal, Golden, Prism,
  Rainbow). The `variantOdds` comment talks about "merging up to a Void pet"
  anyway. Static read.
- **The pack rows' `variants` columns are ignored.** Edit `VARIANT_BASE` or `VARIANT_HEADLINE` instead.

## Open questions
- Pack pity and the Exotic floor (PROPOSAL lines 26 and 28) against the no-pity rule. See [open-questions](../open-questions.md).
- Is a Meadow pack with no Mythic+ at all intended? Compare PROPOSAL §I: *"Exotic … 1 in 5,000 … is not rare, it is absent."*
- "New drop tables" was never defined (OPEN #12).
- Should the 28 legacy packs move onto the ore system (OPEN P2)?

## See also
[pets](pets.md) · [chests-and-lucky-blocks](chests-and-lucky-blocks.md) · [shops-and-monetisation](shops-and-monetisation.md) · [trading](trading.md) · [ore-pouch-and-backpack](ore-pouch-and-backpack.md) · [glossary](../glossary.md)
