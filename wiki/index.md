---
title: Wiki index
type: meta
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - wiki/SCHEMA.md
related: [README, overview, owner, SCHEMA, log]
---

# Index

> Every page in the wiki, one line each. **Read [overview](overview.md) first**,
> then [owner](owner.md). Then pick the system you are touching. Update this
> page whenever you add one (see [SCHEMA](SCHEMA.md)).

## Start here

- [README](README.md): what this wiki is and how to talk to it
- [overview](overview.md): the game in one page
- [owner](owner.md): the owner's goals, locked decisions and working rules
- [ambiguous-terms](ambiguous-terms.md): words that mean several things; **ask which**
- [glossary](glossary.md): every term, one line each
- [open-questions](open-questions.md): probable bugs, contradictions and unanswered questions
- [sources-of-truth](sources-of-truth.md): every doc, its date, and how far to trust it

## Systems (what the game does)

**The loop**
- [mining-and-breaking](systems/mining-and-breaking.md): swing, damage, the breaking-power gate, procs, drops
- [zones-layers-and-seams](systems/zones-layers-and-seams.md): 11 zones, layers, free seams, outposts every 500
- [ores](systems/ores.md): the 82-ore roster, spawn curve, veins, reach, migrations
- [ore-pouch-and-backpack](systems/ore-pouch-and-backpack.md): selling ore, gems, bags
- [tools](systems/tools.md): every tool kind, forged naming, level cap 30, hotbar
- [forge-and-recycling](systems/forge-and-recycling.md): craft, upgrade, recycle, bulk scrap

**The build**
- [boosts-and-stats](systems/boosts-and-stats.md): stat keys, the two boost layers, luck, caps, potions
- [charms](systems/charms.md): ore charms, shapes, merging, legacy charms
- [skins-cases-and-temper](systems/skins-cases-and-temper.md): F…SSS tempers, ore cases, grade reveal
- [traits](systems/traits.md): the tool prefix, the Enchanter, and the runes it replaces
- [pets](systems/pets.md): three seats, boost path, pet traits, Event Horizon pets
- [hats-and-faces](systems/hats-and-faces.md): gear (3 hats + a face), grades, sets, hat crates
- [rebirth-and-skill-tree](systems/rebirth-and-skill-tree.md): rebirth (= prestige), what persists, the 75-node tree

**Collecting, money and community**
- [currencies-and-economy](systems/currencies-and-economy.md): coins, gems, stardust, sinks, number formatting
- [cards-and-packs](systems/cards-and-packs.md): cards, pack odds, reveal, the pity contradiction
- [chests-and-lucky-blocks](systems/chests-and-lucky-blocks.md): section chests, ranks, lucky blocks
- [world-events](systems/world-events.md): Event Horizon, Event Pass, World Pulse
- [trading](systems/trading.md): the trade flow, pricing, the "pawning to new players" concern
- [social-quests-and-leaderboards](systems/social-quests-and-leaderboards.md): quests, Job Board, leaderboards, group wheel, Discord
- [shops-and-monetisation](systems/shops-and-monetisation.md): every shop, Robux products, VIP vs Founders, battle pass
- [admin-and-debug](systems/admin-and-debug.md): admin panel, anti-gear, dev-only code
- [retired-and-parked](systems/retired-and-parked.md): what is gone but must not be renamed, and the cut list

## Code and workflow

- [code-map](code/code-map.md): every `src/` folder, what is live and what is leftover
- [server](code/server.md): MineServer, the 142-action router, `Verbs`, `Dig`
- [client-and-ui](code/client-and-ui.md): MineClient, view modules, house style, layering
- [candy-style](code/candy-style.md): **the UI house style. Read before touching any UI.** Kit, colours, motion, honest wins, checklist.
- [save-data-and-migrations](code/save-data-and-migrations.md): DataStores, save shape, every migration
- [rojo-and-studio](code/rojo-and-studio.md): the Rojo mapping, place-only content, syncback, the loss matrix
- [verify-suite](code/verify-suite.md): all 36 checks, `suite.sh`, `syntax.sh`, how to add one
- [tools-and-generators](code/tools-and-generators.md): generators, one-off scripts, calculators
- [assets-and-uploads](code/assets-and-uploads.md): group upload rules, icons, `build/`
- [luau-traps](code/luau-traps.md): nine traps that have cost days. **Read before editing Luau.**
- [local-setup](code/local-setup.md): running Claude Code on the owner's Windows machine

## Maintenance

- [SCHEMA](SCHEMA.md): page format, which source wins, ingest / query / lint
- [claude-ai-setup](claude-ai-setup.md): paste-in text so Claude.ai chats ask first too
- [log](log.md): what was ingested, queried and linted, and when
