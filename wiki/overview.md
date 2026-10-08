---
title: Mine For Cards — the game in one page
type: meta
status: current
verified: 2026-10-08 @ ea255bb
sources:
  - docs/START-HERE.md §2, §5
  - docs/HANDOFF.md §2.1, §2.5
  - docs/AUDIT.md
  - docs/live-config.md
  - roadmap/README.md
related: [owner, glossary, code-map, open-questions]
---

# Mine For Cards — the game in one page

> **"⛏️ MINE FOR CARDS! 🃏 SEASON ONE"** is a live Roblox mining game (placeId
> `73982848847016`, owned by the Mine For Cards group). The GitHub repo is
> `VeyrixCasino/PullAPick`; "Pull A Pick" and "Mine For Cards" are the same
> project. The code is Luau, synced into Roblox Studio with Rojo 7.7.

## The loop

**dig → ore → forge a better tool → dig deeper → repeat**, with packs, pets,
skins and charms on the side (`docs/START-HERE.md` §2).

> *You break rock to get ore. Ore is the only thing that makes you stronger.
> Everything else decides WHICH ore is worth breaking, and how fast.*
> (`docs/HANDOFF.md` §2.1)

The test for any feature: **does it change which ore I go and break next?** If
not, it is probably cuttable (`docs/AUDIT.md`).

What a new player does:

1. Spawns at the surface **outpost** with a tutorial wooden pick. The tutorial
   hands over the stone pick.
2. Mines blocks. Ore goes into a capped **backpack**.
3. Walks back to **sell** or **bank** the ore (the [ore pouch](systems/ore-pouch-and-backpack.md)).
   Selling ore mints **gems**.
4. At the **Forge**, spends ore to craft a tool made *of that ore* ("Stone
   Pickaxe"), and spends more of the same ore to level it up
   ([forge](systems/forge-and-recycling.md), [tools](systems/tools.md)).
5. Goes deeper through **layers**. **Breaking power** decides which ore and rock
   a tool can break, and it is separate from damage
   ([mining-and-breaking](systems/mining-and-breaking.md)).
6. Moves outward through **zones**, which are gated by **rebirth**. Underground
   **outposts** sit every 500 layers
   ([zones-layers-and-seams](systems/zones-layers-and-seams.md),
   [rebirth](systems/rebirth-and-skill-tree.md)).

## Two axes

| axis | what | gated by |
|---|---|---|
| **Breadth** | 11 zones, from Dirt Meadow to Event Horizon | rebirth count |
| **Depth** | layers inside a zone; effectively unbounded | breaking power (seams are free now) |

Most past balance failures came from attaching a reward to the wrong axis, or
to an axis that nothing gated. `roadmap/PRINCIPLES.md` §1–§2 tells the
"bootstrap loop" story.

## Three currencies, three jobs (the intended design)

- **Ore** is power: tools are forged from it and levelled with it.
- **Gems** are for gambling and access: traits, charm merges, cases, zones,
  pouch upgrades. They are minted by selling ore.
- **Coins** are for consumables and access. **This is not solved yet.** Coins
  have almost nothing to buy now that the Forge runs on ore, seams are free, and
  tools are no longer sold for coins (TODO §0.28, PROPOSAL line 23, commit
  `9733a05`).

See [currencies-and-economy](systems/currencies-and-economy.md).

## The build: what makes two players different

Locked rule 0.13: **charms and skins are the build.** Everything else supports
them.

- [charms](systems/charms.md): ore drops; each one has a *shape*.
- [skins](systems/skins-cases-and-temper.md): the top prize, hunted from ore
  cases.
- [traits](systems/traits.md): a rolled prefix on your tool, such as "Lucky Stone Drill".
- [pets](systems/pets.md) and [hats](systems/hats-and-faces.md): support.
- [skill tree](systems/rebirth-and-skill-tree.md): bought with rebirth tokens.

Bonuses combine in **two layers**: within a layer they add, and the layers
multiply ([boosts-and-stats](systems/boosts-and-stats.md)).

## Collecting, trading, community

- [Cards and packs](systems/cards-and-packs.md): the game is named after them.
- [chests and lucky blocks](systems/chests-and-lucky-blocks.md)
- [world events](systems/world-events.md)
- [trading](systems/trading.md)
- [social, quests and leaderboards](systems/social-quests-and-leaderboards.md)
- [shops and Robux](systems/shops-and-monetisation.md)

## State of things (2026-10-08)

- PR #6 (the balance pass, forged-tool skins, economy fixes, performance) was
  **merged into `main` on 2026-10-06**. The recent commit messages report live
  Studio verification for many changes, so "has it run in Roblox?" is **unknown
  per feature**, not "almost none" as `docs/START-HERE.md` §5 says. Ask the owner
  or check the commit message.
- The audit found about **1 line in 6 unreachable**. Some features are
  archived or cut ([retired-and-parked](systems/retired-and-parked.md)).
- What is still undecided lives in [open-questions](open-questions.md) and
  `docs/OPEN.md`.

## Where to go next

- **Changing code:** [code-map](code/code-map.md), [server](code/server.md),
  and [luau-traps](code/luau-traps.md). Read the traps first.
- **Working with the owner:** [owner](owner.md).
- **Confused by a word:** [glossary](glossary.md) and
  [ambiguous-terms](ambiguous-terms.md).
