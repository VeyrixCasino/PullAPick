---
title: Glossary
type: meta
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - docs/TODO.md §0
  - docs/START-HERE.md
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
related: [ambiguous-terms, overview, index]
---

# Glossary

> One line per term, with the page that explains it. If a word means more than
> one thing, it is in [ambiguous-terms](ambiguous-terms.md) too. Definitions
> come from the code and docs as of `26036a0`; follow the link before relying on
> one.

## The game

- **Ore** — what you mine; 82 types, final (`MineConfig.ORES`). [ores](systems/ores.md)
- **Forged tool / ore tool** — a tool made from one ore, named `{Ore} {Noun}`. [tools](systems/tools.md)
- **Forge** (was bench, Blacksmith) — the crafting and levelling panel. [forge-and-recycling](systems/forge-and-recycling.md)
- **Breaking power** — whether a tool can damage a block at all. **Not damage.** [mining-and-breaking](systems/mining-and-breaking.md)
- **Block strength** — the harder of the depth strength and the ore's strength, minus reach. [mining-and-breaking](systems/mining-and-breaking.md)
- **Ore reach** — how many tiers above its own a tool can break: 5 at home, 15 once you are past the zone. [mining-and-breaking](systems/mining-and-breaking.md)
- **`tooWeak`** — the event sent when the gate refuses a swing. [mining-and-breaking](systems/mining-and-breaking.md)
- **Proc** — a chance effect on a swing: blast, zap, ricochet, earthquake, echo. [mining-and-breaking](systems/mining-and-breaking.md)
- **Vein** — a 1–8 block cluster of one ore. [ores](systems/ores.md)
- **Band** — a Common…Exotic group of ore tiers. [ores](systems/ores.md)
- **Ore finder** (`rareOre`, `fossilFind`) — shifts *which* ore you roll, not how much. The `fossilFind` key is a fossil-era leftover kept on purpose. [ores](systems/ores.md), [retired-and-parked](systems/retired-and-parked.md)
- **Frame** — the coin-ladder rung a forged tool wears. **Coin ladder** — `MineTools.TOOLS`; no longer sold for coins, kept as the source of forged-tool frames. [tools](systems/tools.md)
- **Flagship tool** — a chest-dropped tool that is never sold. [tools](systems/tools.md)
- **Finish** (Shiny / Shadow / Nightmare) — a power multiplier on a tool. [tools](systems/tools.md)
- **Recycle / scrap** — returns about half of a tool's level spend. [forge-and-recycling](systems/forge-and-recycling.md)

## Places and depth

- **Zone** — one of 11 mines (`MineConfig.ZONES`); zone 11 is the limited Event Horizon (`bigbang`). [zones-layers-and-seams](systems/zones-layers-and-seams.md)
- **Layer / section** — a depth row; a named range of rows. **Band** (Surface / Deeprock / Shadowzone) — a depth label. [zones-layers-and-seams](systems/zones-layers-and-seams.md)
- **Seam / air gap** — a gate every 500 layers ending in 5 air layers; **free** now. [zones-layers-and-seams](systems/zones-layers-and-seams.md)
- **Outpost / depth plaza / depth desk / station bay** — the underground copy of the surface outpost, its sell desk, and the room reserved behind it. [zones-layers-and-seams](systems/zones-layers-and-seams.md)
- **Event Horizon** — the limited-time zone 11. **Space coins, SpaceHP** — its economy. [world-events](systems/world-events.md)
- **World Pulse** — a world-event feature, currently disabled. [world-events](systems/world-events.md)

## Money

- **Coins** — the haul currency, paid at a sell pad. **Gems** — minted by selling ore; the sink for zones, trait rolls, charm merges. **Stardust** (`p.dust`) — upgrade currency. **Temper tokens** — the rebirth-token currency for hats and cases. **Credits** — Robux-bought. [currencies-and-economy](systems/currencies-and-economy.md)
- **Haul / `haulMix`** — coins priced while mining, paid at a sell desk. [currencies-and-economy](systems/currencies-and-economy.md)
- **Ore pouch** — the gem-sellable ore store. **Backpack** — the haul bag. **Item bag** — the inventory shelf. [ore-pouch-and-backpack](systems/ore-pouch-and-backpack.md)
- **`ORE_GEM_SPREAD`** — how much more the top ore sells for than the bottom one. [currencies-and-economy](systems/currencies-and-economy.md)
- **`MineAbbrev.currency` / `MineBigNum`** — the wallet formatter (4 figures, floored) and the server-only big-number formatter. [currencies-and-economy](systems/currencies-and-economy.md)
- **Rebirth (= prestige)** — the run reset that gates zones. [rebirth-and-skill-tree](systems/rebirth-and-skill-tree.md)
- **Skill point, element, road, rival key, fuse/cap node, the Clouds** — skill-tree terms. [rebirth-and-skill-tree](systems/rebirth-and-skill-tree.md)

## The build

- **Layer 1 / Layer 2** — the two boost layers; bonuses add inside a layer and the layers multiply. [boosts-and-stats](systems/boosts-and-stats.md)
- **Stat key / legacy stat** — a saved stat name, which is data: renaming one needs a save migration. [boosts-and-stats](systems/boosts-and-stats.md)
- **`PROC_SHARE` / `procPower`** — the share of a swing a proc deals, and the stat that scales it (cap 3.0). [boosts-and-stats](systems/boosts-and-stats.md)
- **`blastChance`** (was `oreYield`) — chance of a blast. [boosts-and-stats](systems/boosts-and-stats.md)
- **`oreLuck` / `chestLuck` / `packLuck`** — the three luck channels. [boosts-and-stats](systems/boosts-and-stats.md)
- **Potion** — a timed consumable; the proposed coin sink. [boosts-and-stats](systems/boosts-and-stats.md)
- **Charm** — an equipped item; 164 ore charms (2 per ore, `<ore>_charm`, `<ore>_charm_2`) plus 31 legacy. [charms](systems/charms.md)
- **Charm shape** — Focus, Twin, Pact, Ward, Brink or Surge: how a charm spends its budget. **Charm merge** — 1 copy plus gems gives the same variant one ore tier deeper. [charms](systems/charms.md)
- **Ore case** — a 2% per-ore-block drop that pays a skin (75%) or a charm (25%). [skins-cases-and-temper](systems/skins-cases-and-temper.md)
- **Temper / temperament** — an F…SSS stat kit (what the code calls a skin). **Temper case** — a roll for one. [skins-cases-and-temper](systems/skins-cases-and-temper.md)
- **Trait** — the prefix on one forged tool, rolled at the Enchanter (500 gems; Exotic V is 1 in 5,000). [traits](systems/traits.md)
- **Enchanter** — the building with tabs Traits / Merge / Sockets / Summon / Temper / Salvage / Dust. [traits](systems/traits.md)
- **Rune / socket / scroll** — the old socketed-stat system, still live. **Stage 3** — its deferred retirement. [traits](systems/traits.md)
- **Pet trait** — a pet's per-print perk (`MineCards.TRAITS`, 12 of them). **`cardPower`** — rarity × variant × shadow × power level. **Set X/Y** — two kit variants per pet name. [pets](systems/pets.md)
- **Pet seat / hat seat** — 3 each. **EH pets** — the 73 Event Horizon pets. [pets](systems/pets.md)
- **Gear** — hats plus a face. **Hat crate** (`gear_pack`) — 5 rebirth tokens. **Gear set** — one of 10 stat identities. **NewGear** — a prototype catalog not wired to drops. [hats-and-faces](systems/hats-and-faces.md)

## Loot and social

- **Card** — a pet; the pet *is* the card. **Pack** — a sealed bag in `p.packs`. **Zone pack** — `<zone>_pack_*`. **Ore pack** — the legacy `<ore>_ore_pack`, banked on load. **God Pack** — all Mythic+, at half the pack's Exotic rate. [cards-and-packs](systems/cards-and-packs.md)
- **Variant / finish** — Golden, Prism, Rainbow, Void / Shiny, Shadow on a pet. **Rarity ladder** — Common…Exotic, 8 rungs. [cards-and-packs](systems/cards-and-packs.md)
- **Section chest** — one per 25 layers. **Chest rank** — S, A, B, C, D, F (F is extinct), with aging. **Lucky block / grade-up** — [chests-and-lucky-blocks](systems/chests-and-lucky-blocks.md)
- **Serial** — a card's global id, used in trades. **Coinflip** — off. [trading](systems/trading.md)
- **Job Board** (contractor), contracts, dailies, milestones — [social-quests-and-leaderboards](systems/social-quests-and-leaderboards.md)
- **Founders Pack / VIP / Battle Pass / Build-a-Box / Stardust shop / Event Pass** — [shops-and-monetisation](systems/shops-and-monetisation.md)
- **`adm_` prefix / allowlist** — admin tooling. [admin-and-debug](systems/admin-and-debug.md)

## Codebase

- **MineNet** — the one RemoteEvent for all client↔server traffic. **Action router** — the string compare on `action`. **Verbs** — the server's table of request handlers. [server](code/server.md)
- **`Dig` / `Const` / `ClientFns` / `Svc`** — tables that dodge the 200-local limit (`Svc` holds seven Roblox services since `5d59714`). **Global-read trap** — a local used above its declaration is silently nil. [luau-traps](code/luau-traps.md)
- **`snap()`** — the player view pushed to the client (at most 10 per second). **Busy lock** — drops a second request from the same player. [server](code/server.md)
- **Toast** — a text notice event. **House style** (`MineTheme` + `MineUI`), **`NoAdopt`** — [client-and-ui](code/client-and-ui.md)
- **Migration stamp** (`oreRosterV`, `toolCapV`), **`_lock`** (save session lock, 120 s), **ephemeral profile**, **`_Studio` suffix** — [save-data-and-migrations](code/save-data-and-migrations.md)
- **`MineBuild` `STAMP`/`EXPECT`** — tells you if Studio is running old code. **Syncback** — Studio → `src/`. **Loss matrix** — what Rojo overwrites on connect. **`ToolModels_50`** — place-only tool meshes. [rojo-and-studio](code/rojo-and-studio.md)
- **DID NOT RUN / `KNOWN_FAIL`** — suite verdicts. [verify-suite](code/verify-suite.md)
- **`mfc_<feature>_<name>_vN`** — the upload naming scheme. [assets-and-uploads](code/assets-and-uploads.md)
- **TCG legacy** — dormant AFK-place code. [code-map](code/code-map.md)
- **`MineParked`** — parked, not deleted, archives. [retired-and-parked](systems/retired-and-parked.md)
