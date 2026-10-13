---
title: Ambiguous terms — words that mean more than one thing here
type: meta
status: current
verified: 2026-10-12 @ 4e4fbb3
sources:
  - docs/TODO.md §0
  - docs/OPEN.md
  - src/ReplicatedStorage/Mine/Shared/MineCards.luau
  - src/ReplicatedStorage/Mine/Shared/MineEnchants.luau
  - src/ReplicatedStorage/Mine/Shared/MineGear.luau
  - src/ReplicatedStorage/Mine/Shared/MineBreaking.luau
related: [glossary, owner, open-questions, overview]
---

# Ambiguous terms

> **This is the list behind the owner's "ask me first" rule.** If a request uses
> one of these words with no context, **do not guess. Ask which meaning** (see
> `CLAUDE.md`, "Ask before you assume"). Put the options in your question, in
> player terms, with your best guess first. Check the page for each system first,
> so the question is specific.
>
> Add a row when you discover a new collision. Many of these exist because the
> game was renamed several times (runes → enchantments → traits; bench →
> Blacksmith → Forge), so old docs use the old word for the new thing. On
> 2026-10-12 runes, scrolls, sockets and tool traits were retired, and
> **enchants** (books in tool slots) became a new, separate system
> ([traits](systems/traits.md), [enchants](systems/enchants.md)).

## Items and tools

| word | it can mean | ask |
|---|---|---|
| **tool** | a forged ore tool (`{Ore} {Noun}`), a coin-ladder shop pick, a chest flagship tool, an Event Horizon tool, or the tutorial wooden pick | Which kind of tool? See [tools](systems/tools.md) |
| **tier** | the ore's index (1–82), a coin-ladder rung, the cosmetic `lookTier`, a pouch rung, or the word "Tier" in the UI | Which ladder? |
| **level** | tool level (cap 30), wooden pick level (cap 5), enchant level (I–V), the player level that unlocks enchant slots, pet power level, or a depth layer. (Trait levels 1–5 were retired on 2026-10-12.) | Level of what? |
| **grade** | the temper letters F…SSS, the lucky-block grade-up climb (`MineToolGrades`), or a gear grade | Tempers, lucky blocks, or gear? |
| **breaking power** | ore tier (1–82; the Forge UI) or strength (1–1000; the gate), and never the same thing as damage | Which scale should a player see? See [mining-and-breaking](systems/mining-and-breaking.md) |
| **Forge / bench / Blacksmith** | the same panel under three names; older docs say bench or Blacksmith | Probably the Forge: confirm |
| **finish** | Shiny / Shadow / Nightmare power multipliers on a tool | Power finish, or a cosmetic? |
| **skin** | today a **temper** (a stat kit F…SSS); the plan was a cosmetic wrap | Does the owner mean power or looks? See [skins](systems/skins-cases-and-temper.md) |
| **gear** | hats + face (current), the old six-slot armour, or Roblox catalog Gear tools (`MineAntiGear`) | Which? See [hats-and-faces](systems/hats-and-faces.md) |
| **face** | a gear piece, an avatar face, or a block-face texture on an ore | Which? |
| **set** | a gear set (10 stat identities), a pet set X/Y, a card `setId`, or Event Horizon set ids. Old docs also mean a rune set (retired 2026-10-12). | Which? |

## Boosts, traits and building

| word | it can mean | ask |
|---|---|---|
| **trait** | a pet's per-print perk (`MineCards.TRAITS`, e.g. Lone Wolf), which is live, **or** the prefix on a forged tool, which was retired on 2026-10-12 | Usually the pet perk now. If they mean tool traits, they are gone: did they mean enchants? See [pets](systems/pets.md), [traits](systems/traits.md) |
| **enchant / enchantment** | the live **enchants** (books in a tool's Damage / Utility / Special slots, applied at the Forge, `MineEnchants`), the Enchanter *building* (which does not enchant: its tabs are Summon, Temper, Salvage, Dust), or the old name of traits in older docs | Books at the Forge, or the Enchanter building? See [enchants](systems/enchants.md) |
| **rune** | the old socketed-stat system, retired on 2026-10-12 (enchants took its field). The id `heavy_runes` survives as the daily wheel slice that now pays 3 Lucky Books. | Runes are gone: did they mean enchants? See [traits](systems/traits.md) |
| **boost** | layer 1, layer 2, charms (in neither layer), or potions | Which layer? See [boosts-and-stats](systems/boosts-and-stats.md) |
| **layer** | a depth row of the mine, or one of the two **boost layers** | Mine or boosts? |
| **slot / seat** | pet seats (3), hat seats (3), a tool's three enchant slots, or bag capacity. Rune sockets were retired on 2026-10-12; `MineGear.SHEET.slots` is their dead socket count. | Which? |
| **merge** | charm merge (gems), hat merge (three of a kind), enchant book merge (three of a book make one a level up), or card "MERGE 3". Rune fuse is retired. | Which? |
| **build** | the player's charms-and-skins build, the `MineBuild` stamp, or `rojo build` | Which? |
| **echo** | a retired stat, a tool special, or the Space element's verb | Which? |
| **oreYield** | the old key for blast chance (now `blastChance`), or `MineConfig.oreYieldFor` (ore quantity) | Chance or quantity? |
| **tokens** | **temper tokens** (`p.temperTokens`). Owner, 2026-10-11: *"ALL 'TEMPER' TOKENS ARE JUST TOKENS. IF I EVER SAY TOKENS I MEAN TEMPER TOKENS"*. Skill-tree tokens (`skillState.tokens`) are the other thing in code. | Settled: do not ask again. |

## Ore, packs and loot

| word | it can mean | ask |
|---|---|---|
| **pack** | a card pack, a currency pouch, a gear case, an ore case, a lucky block, or the legacy `<ore>_ore_pack`. (The three rune cases were removed on 2026-10-12.) | Which? See [cards-and-packs](systems/cards-and-packs.md) |
| **case** | an ore case, a temper (skin) case, a "Gear Case", or the old pack | Which? |
| **chest** | a zone chest, a `Mine1ChestsData` catalog chest, a Shiny chase chest, or the dead `MinePackConfig.CHESTS` | Which table is the real list? See [chests](systems/chests-and-lucky-blocks.md) |
| **card** | a pet (the pet *is* the card), or a collectible card | Should players ever see "card"? |
| **bag** | the ore pouch, the backpack (haul bag), or the item bag | Which? See [ore-pouch-and-backpack](systems/ore-pouch-and-backpack.md) |
| **sell** | ore → gems (pouch), or haul → coins (sell pad) | Which? |
| **ore** | an ore *type* (one of 82), an ore *block* in the world, or banked ore in `p.ores` | Which? See [ores](systems/ores.md) |

## Currencies and progression

| word | it can mean | ask |
|---|---|---|
| **rebirth / prestige** | one mechanic with two counters (`p.prestige`, `p.stats.rebirth`) | Same thing; which counter if it matters? |
| **dust** | stardust (`p.dust`) or TCG FusionDust | Which? |
| **coins** | the haul currency; its purpose is **unresolved** (see [open-questions](open-questions.md)) | What should coins be for? |
| **floor** | layer 5000 (`MAX_LAYER`) or uncapped in Dirt Meadow | Which is real? |
| **seam** | a gate every 500 layers (free now); older docs treat it as a priced purchase | Free gate, or a priced one? |
| **zone** | one of 11 mines, or Event Horizon (zone 11 `bigbang`, a limited event) | Which? See [zones-layers-and-seams](systems/zones-layers-and-seams.md) |

## Shops, events and social

| word | it can mean | ask |
|---|---|---|
| **shop** | the Shop panel, the depth desk, the Event Horizon shop, Inventory → Shop, or rotating offers | Which screen? See [shops-and-monetisation](systems/shops-and-monetisation.md) |
| **VIP** | the VIP gamepass, or **Founders** membership (the code's `isVip()` means Founders) | Which? |
| **pass** | Battle Pass, Event Pass, or a gamepass | Which? |
| **event** | Event Horizon, World Pulse (disabled), or a limited season/offer | Which? See [world-events](systems/world-events.md) |

## Workflow words

| word | it can mean | ask |
|---|---|---|
| **verified** | passes the verify suite, checked in Studio by an agent, or **confirmed in-engine by the owner** | Which level? **Almost nothing has had the third.** |
| **done / works** | written, verified by script, or played in Roblox | Same: say which |
| **sync** | `rojo serve` (repo → Studio), syncback (Studio → repo), or `git pull` | Which direction? See [rojo-and-studio](code/rojo-and-studio.md) |
| **export** | the Studio syncback inbox (`tools/export/in/`) or Claude.ai chat exports | Which? **Never put chat exports in `tools/export/in/`**; `sync.ps1` deletes it |
| **stamp** | `MineBuild.STAMP`, a migration stamp (`oreRosterV`), or a pack's stamped finder | Which? |
| **generated** | made by a tool script (`gen-*.js`) or procedurally made in-game | Which? Generated files say "edit the generator" |
| **main** | the git branch `main` (behind), or `MAIN_PLACE_ID` in `PlaceConfig` | Which? |
| **MineUI** | the UI kit module or the HUD ScreenGui | Which? |

## Vague requests that always need a question

These are not ambiguous words but broad asks. Ask what outcome, how far it
should reach, and what must not change. The owner's own standing preferences are
on [owner](owner.md).

- "fix / rebalance / improve the economy", "make packs fun", "make progression
  snappier": which currency, which part of the game, what feeling?
- "clean it up" / "remove unused things": the audit cut list was never approved.
- "make it like the reference": which image or screenshot?
- "add X": check [retired-and-parked](systems/retired-and-parked.md); X may have
  been cut on purpose.
