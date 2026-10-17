---
title: Enchants and the player level
type: system
status: partial
verified: 2026-10-12 @ 4e4fbb3
sources:
  - src/ReplicatedStorage/Mine/Shared/MineEnchants.luau
  - src/ServerScriptService/Mine/MineEnchantService.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ReplicatedStorage/Mine/Shared/MineForgeHub.luau
  - src/ReplicatedStorage/Mine/Shared/MineGradeReveal.luau
  - tools/verify/enchants.js
  - tools/verify/orehaul.js
related: [traits, boosts-and-stats, mining-and-breaking, pets, chests-and-lucky-blocks, rebirth-and-skill-tree]
---

# Enchants and the player level

> Every compatible tool has three enchant slots: Damage, Utility and Special.
> Each slot holds one enchant, levelled I to V. Enchants come as books, in
> bundles: from chests, from every lucky block, and for gems at the Forge (never
> from cases). Three of the same book merge into one a level up. The slots
> unlock with the new player level, which is earned from ore and chests.
> Enchants took over from tool traits and runes, which were retired on
> 2026-10-12 ([traits](traits.md)).

## How it works

**The slots** (`MineEnchants.SLOTS`):

| slot | purpose | unlocks at |
|---|---|---|
| Damage | break blocks faster | level 1 |
| Utility | get more from every block | level 10 |
| Special | the tool's proc | level 25 |

**The Special slot decides the proc** (`MineEnchants.gateProcs`, the last step of
`boosts()`). On the tool in hand:
- every other proc family's chance and damage goes to 0, so pets, skins and charms
  only boost the proc your Special picked (owner: *"This slot determines which effect
  your tool will have, regardless of pet setup. The pets only boost this."*);
- with no Special enchant yet, the tool keeps the one proc your gear gives the most
  chance of (owner, 2026-10-12: *"Pets' best proc until you pick one"*), so new players
  keep a proc before the slot opens at level 25;
- a chance over 100% converts into that proc's damage (owner).

The families are Zap (`zap`/`zapDamage`), Blast (`blastChance`/`blastDamage`/`blastRadius`),
Tidal Wave (`tidalWave`/`tideDamage`), Shatter (`ricochet`/`shatterDamage`) and
Earthquake (`earthquake`, with `procPower` as its damage). Explosives roll no procs, so
they take no Special.

**Three tiers per ability** (owner, 2026-10-12: *"Make 3 levels of abilities"*, tiers that change how it works). The Special's level picks the tier: I–II tier 1, III–IV tier 2, V tier 3 (`MineEnchants.TIERS`, read by `Dig.procsAt` as `b.procTier`). Pets' best proc alone is tier 1. Each ability also carries its own proc chance and damage, both rising per level (owner: *"also made the ability itself have a proc chance and dmage"*). PROPOSED, each capped:

| ability | tier 1 | tier 2 | tier 3 |
|---|---|---|---|
| Zap | Spark: 1 chain | Fork: 2 chains | Storm: 3 chains, continue 85% |
| Blast | Pop: 6 sides | Burst: 18 around | Detonation: 26 around, breaks pop again (max 3) |
| Tidal Wave | Swell: 1 layer | Breaker: 2 layers | Tsunami: 3 layers |
| Shatter | Crack: 3 bursts | Splinter: 6 | Cascade: 10 |
| Earthquake | Tremor: 1 block | Rumble: +2 blocks | Cataclysm: +4 blocks, +50% damage |

**Damage and Utility are Layer 1** (`MineEnchantService.layerStats`), where the
trait sat, beside the skin and skills (owner §0.19: the layers multiply, sources inside a layer
add). Only the held tool's enchants count.

**The enchants** (`MineEnchants.LIST`). Every one is live since 2026-10-12
(owner: *"Make the 'coming soon' enchants actually work"*). The `live` flag and
the Forge's COMING SOON stay for the next enchant that needs new code. *How*
says where it acts: Layer 1 (a stat in `boosts()`), the swing, or the ore drop.

| slot | enchant | effect at V | how |
|---|---|---|---|
| Damage | Power | +27.6% damage (+5% a level, compounded; owner) | Layer 1 |
| Damage | Heavy Impact | +30% damage, -20% swing speed (owner) | Layer 1 |
| Damage | Critical Strike | 20% for ×2.5, flashes CRIT! | swing |
| Damage | Executioner | +100% on a block within 2 hits of breaking | swing |
| Damage | Demolitionist | +40% on a block that takes 8+ hits | swing |
| Damage | Overclock | +5% swing speed a one-shot in a row, max 20 (owner) | swing |
| Damage | Combo | +2% damage a hit in a row, max 100 (owner) | swing |
| Damage | Short Fuse | +15% shortFuse: bomb cooldown / 1.15, explosives only (owner: *"dont overdo it"*) | Layer 1 |
| Utility | Fortune | +50% ore haul | Layer 1 |
| Utility | Scavenger | +61% coins | Layer 1 |
| Utility | Gemfinder | +47% gems | Layer 1 |
| Utility | Treasure Hunter | +47% chest luck | Layer 1 |
| Utility | Reach | +40% reach | Layer 1 |
| Utility | Experience | +61% player XP | XP grant |
| Utility | Vein Miner | the next 10 blocks of the same ore | ore drop |
| Utility | Alchemy | 10% to turn the ore into the next ore up | ore drop |
| Utility | Duplicator | 20% double ore | ore drop |
| Special | Zap / Blast / Tidal Wave / Shatter / Earthquake | 20–30% chance, +50% damage | the proc gate |

The numbers the owner gave are marked; the rest are PROPOSED.

**How the mining enchants work** (`MineEnchants.hitMult`, `overclockSpeed`,
`oreChance`, `veinBlocks`; `MineEnchantService` keeps the streaks; MineServer
calls it):
- **In the swing** (`swingBlock`, after the damage is rolled): Critical Strike,
  Executioner, Demolitionist and Combo multiply that swing's damage, rounded by
  chance like the swing itself. Executioner reads the block's HP before the
  swing; Demolitionist reads its max HP against your hit.
- **Streaks are per player and never saved.** Combo ends after 2 s without a hit
  (`COMBO_GRACE`); its first hit is plain, and it flashes COMBO 25/50/75/100.
  Overclock counts one-shots (a whole block broken by one swing). Any other swing
  ends it, and so do 2.5 s without one (`OVERCLOCK_GRACE`). Both graces are
  PROPOSED.
- **Overclock is real speed.** The server's swing budget scales by
  `swingSpeed(p)`, and the client paces its swing bar by the same number (the
  `enchSpeed` event), lapsing after the grace.
- **Not on explosives.** A thrown charge never swings, so the five in-swing
  enchants list only pickaxes, hammers, drills and jackhammers. Power and Heavy
  still fit explosives.
- **On an ore drop** (`finishBreak`):
  - Alchemy rolls before the yield, so the upgraded ore gets its own yield.
  - Duplicator rolls after Ore Haul.
  - Vein Miner (`Dig.veinAt`) then breaks up to n touching blocks of the same
    ore. Each is a full-HP neighbour hit, so it pays and gates like a proc.
    A vein block never starts its own vein (`Dig.veining`).
- **Ore Haul never paid until 2026-10-12.** The drop read `b.oreHaul`, but that
  function's boosts are `bb`. So gear, pets and the Fortune enchant moved nothing.
  The fix is in `tools/verify/orehaul.js`.

**Books** (`p.enchantBooks["power:1"] = n`) come in **bundles**. The owner,
2026-10-12: *"Book buddles from lucky blocks, and chest(not cases)"*, choosing 2–5
books, scaled.
- **Chests.** 5% of chests drop a bundle (`CHEST_BOOK_CHANCE`), raised by chest
  luck up to ×3. A bundle is 2 books, 3 from a B or A chest and 4 from an S
  (`CHEST_BUNDLE`). The toast names the books.
- **Lucky blocks.** Every lucky block pays a bundle on top of its loot
  (`LUCKY_BUNDLE`): Lucky 2, Diamond 3 (A-chest levels) and Godly 5 (S-chest
  levels). The end of the lucky reveal lists them.
- **Gems at the Forge.** MY BOOKS has a BOOK BUNDLE card: 3 random books for 500
  gems, ×1.15 for each zone you have opened (PROPOSED). The owner chose this as
  the gem sink runes used to be. The bundle opens on screen (`ctl.showBundle`).
- **Never cases.**
- Which enchant is picked by rarity weight (Common 100 … Legendary 2.5).
- B, A and S chests can give level II or III (`BOOK_RANK_LEVEL`).
- `enchApply` uses a book up, and whatever was in the slot comes back as a book.
- `enchRemove` returns the book.
- `enchMerge` turns three of one book at one level into one a level up.
- Recycling a tool returns its enchants as books.

**The player level** (`p.level`, `p.xp`; kept through rebirth):
- An ore block pays 3 XP; a chest pays 15 × its rank (F 0.6 … S 3).
- The step to the next level is 40 × 1.1^(level − 1): about 550 XP to level 10 and
  3,500 to 25.
- Every 5 levels pays a gift: a book for a slot you have open, plus 250 × (level / 5)
  gems. Never pass XP (owner).

**Server-authoritative.** The client names a tool, a slot and a book.
`MineEnchantService` checks the tool, the level, the slot, the book, compatibility and
liveness before anything changes. `enchDebugGrant` (3 of every book plus level 25)
works only in Studio.

## Decided by the owner (2026-10-11)
- Three slots: Damage, Utility, Special. Special decides the proc; pets only boost it;
  chance over 100% becomes damage.
- Levels I–V, compounded for progressive boosts; the owner's example values are above.
- Books from chests and cases; merge 3 for +1 level. (2026-10-12: bundles from
  chests and lucky blocks, not cases; gems buy bundles; the eight "soon" enchants
  made to work.)
- Slots unlock at levels 1 / 10 / 25, with a gift every 5 levels.
- Traits and runes are retired; what players own is refunded (next step).
  2026-10-12: *"no one has played.. ur good"*, so nothing is refunded.

## State right now
- **Built and checked** (`tools/verify/enchants.js`):
  - the data, the server verbs, XP and levels, Layer 1 stats and the Special proc gate;
  - all eight mining enchants;
  - book bundles from chests and lucky blocks, and the Forge's gem bundle.
- **The Forge hub** shows and applies all of this ([client-and-ui](../code/client-and-ui.md)).
  The Blacksmith counter opens it.
- **Retired for them (2026-10-12):** tool traits, runes, scrolls and sockets. The
  rewards that paid scrolls pay books now: the premium pass's tiers 25 / 55 / 88
  (3 / 4 / 5 books), the Founders pack (3), and the daily wheel's 6% slice
  ("3 LUCKY BOOKS", S-chest levels). The tutorial's step 8 gives 2 free Damage
  books and opens the Forge on ENCHANT; the quests ask for enchants and book
  merges. See [traits](traits.md).
- **Not built yet:**
  - auto-equip that reads the Special;
  - an enchant for Coolant or Short Fuse (open: they now come only from the
    skill tree).
- **Not yet seen in a live server:** the mining enchants and bundles are checked
  by code, not by play.
- **Before level 25** the tool keeps its gear's best proc; the owner chose this over
  "no procs before a Special enchant" (2026-10-12).
