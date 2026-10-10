---
title: Cards and packs
type: system
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - src/ReplicatedStorage/Mine/Shared/MineCards.luau
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

**The set system is live, and it is how every pack works** (counted 2026-10-10):
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
- **The 322 hand-named pets** (`MinePetRoster` plus `MineEHPets`) are separate.
  They drop only from the wheel, lucky blocks and Event Horizon chests, never
  from packs.

The owner's rework replaces all of this with zone pots plus 19 exclusive sets
(`docs/PETS-AND-SETS.md`).

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
3. **Which card.** The card is drawn from that rarity in the set, narrowed to a
   60% window per pack (`cardPoolFor`, `CARD_SUBSET_SHARE`). Two packs from the
   same set therefore pay different pets.
4. **Variant.** `variantOdds` overrides each pack's own `variants` row. Every
   pack pays Golden 1% and nothing else (`VARIANT_BASE`), except the packs named
   in `VARIANT_HEADLINE`, such as `void_pack` at Void 2%.
5. **Finish.** Shiny is the pack's `shiny` % (default `SHINY_CHANCE` 4). One shiny
   in 100 comes out Shadow instead (`MineConfig.SHADOW_OF_SHINY`); the Shiny Pack
   uses 1 in 20.
6. **Fallback.** `MineCards.HIT` / `slotOdds` (softened by `SLOT_SOFTEN` 3) is
   used only when a pack has no `odds` table of its own.

**Order of the reveal.** Cards are sorted worst-to-best **on the server** (by
`MinePackFX.BAND_ORDER`, then by true odds), so each flip is at least as good as
the last. Cards of Rare or better that rolled rarer than 1 in 200 carry an
`oneIn` ribbon, priced by `MinePackConfig.pullOdds`.

### Pack kinds (the `kind` on a pack definition)
| kind | ids | what opens |
|---|---|---|
| `cards` | `<zone>_pack_common/rare/legendary` (3/4/5 cards) | odds from `MineZonePacks` `cardOdds(zoneIndex, heat)` |
| `currency` | `<zone>_currency_common/rare` | coins + gems, no cards |
| card pack, no kind | 19 in `Mine1PacksData` (loam … heirloom; hopper 6 cards, magma 8, apex 1) | own `odds` table |
| `rune` / `gear` | `rune_*_pack`, `gear_*_pack` | `MineLootPacks` rolls one item per slot |
| `ore_case` | `<ore>_ore_case` | a skin or a charm, see [skins-cases-and-temper](skins-cases-and-temper.md) |
| `ore` (legacy) | `<ore>_ore_pack` | ore; converted on load (below) |
| `lucky_block` | stored in `p.packs` | see [chests-and-lucky-blocks](chests-and-lucky-blocks.md) |

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
- **`MinePackConfig.NEW_CARD_BIAS` (0.70) is read nowhere.** Packs do not prefer cards you are missing.
- **The two card rosters are not joined.** The named X/Y animals in
  `MinePackConfig.SET_CARDS` are **not** used when minting. The comment above
  `openPack` says "NOT YET WIRED"; identity comes from `MineCards` sets.
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
- Should the X/Y roster be wired into minting?

## See also
[pets](pets.md) · [chests-and-lucky-blocks](chests-and-lucky-blocks.md) · [shops-and-monetisation](shops-and-monetisation.md) · [trading](trading.md) · [ore-pouch-and-backpack](ore-pouch-and-backpack.md) · [glossary](../glossary.md)
