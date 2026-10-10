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
- `MinePackConfig.isRated` is true only for `Mine1PacksData` packs. **Zone packs carry
  no stars** (owner, `docs/PETS-AND-SETS.md` §rewards), so their tiles draw no star row.
- Inventory pack tiles draw the star row at y 86 (same as lucky blocks) and print
  `Set · Grade` on the set line when the set has a `grade` (`MineCards.setGrade`).
  No Season-1 set has one yet, so grades appear once the 19 graded sets are wired.
- The default order is **best first**: stars, then set grade
  (`MineCards.GRADE_RANK`, falling back to the set's T1–T9 tier), then odds tier,
  luck, name. Owner: *"5 star pebble bound trumps 4.5 star Chaos Theory"*. This
  replaced the old worst-first order. Lucky blocks stay pinned first.

**Order of the reveal.** Cards are sorted worst-to-best **on the server** (by
`MinePackFX.BAND_ORDER`, then by true odds), so each flip is at least as good as
the last. Cards of Rare or better that rolled rarer than 1 in 200 carry an
`oneIn` ribbon, priced by `MinePackConfig.pullOdds`.

### Pack kinds (the `kind` on a pack definition)
| kind | ids | what opens |
|---|---|---|
| `cards` | `<zone>_pack_common/rare/legendary` (3/4/5 cards) | odds from `MineZonePacks` `cardOdds(zoneIndex, heat)` |
| `currency` | `<zone>_currency_common/rare` | coins + gems, no cards |
| `holiday` | `halloween_2026` (3 cards) | `MineSetPacks.HOLIDAY_ODDS` (PROPOSED); only its holiday pets, the one pack allowed to pay them. Kind `holiday` keeps it out of the day-4 surprise. Paid by the Trick-or-Treat case. |
| `cards` + `setKey` | `<setkey>_pack_1..6` (★ to ★★★★★; 3, 3, 4, 4, 5, 5 cards) | `MineSetPacks.ODDS` by star grade; only that set's pets |
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
- **Meadow zone packs can never pay Mythic, Divine or Exotic.** `cardOdds(1, heat)`
  maps zone 1 to layer 1, where `t = 0` zeroes those three rungs. Siphon and the
  God Pack scale existing weight, so they stay 0. This was computed from the
  formula, not observed. OPEN P2 says `cardOdds` ignores the zone index; that is
  stale, because it does use it.
- **Set packs live in `PACK_BY_ID` but not in `PACKS`.** `MinePackConfig`
  registers them at the end of the file, so every lookup (bag tile, inspector,
  admin grant, opener) finds them, but nothing that walks the universal list
  sells or re-rates them. **One side effect:** the day-4 surprise walks
  `PACK_BY_ID` for packs of 2★ and up, so it can now hand out a set pack.
- **Two pets of one name can fail to merge.** Pack pets use `"<home>:<name>"`,
  but lucky blocks mint `"lucky_block:<name>"` and the group wheel
  `"group_wheel:<name>"`, and merging needs equal `cardKey`s. Not changed yet;
  ask before re-keying, because it touches saved cards.
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
