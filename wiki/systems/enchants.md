---
title: Enchants and the player level
type: system
status: partial
verified: 2026-10-19 @ 3863d14
sources:
  - src/ReplicatedStorage/Mine/Shared/MineEnchants.luau
  - src/ServerScriptService/Mine/MineEnchantService.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ReplicatedStorage/Mine/Shared/MineForgeHub.luau
  - src/ReplicatedStorage/Mine/Shared/MineGradeReveal.luau
  - src/ReplicatedStorage/Mine/Shared/MineProcFx.luau
  - tools/verify/enchants.js
  - tools/verify/orehaul.js
  - tools/verify/enchant-audit.js
  - tools/verify/enchant-balance.js
  - tools/verify/enchant-balance.luau
  - tools/verify/_enchant-sim.js
related: [traits, boosts-and-stats, mining-and-breaking, pets, chests-and-lucky-blocks, rebirth-and-skill-tree]
---

# Enchants and the player level

> Every compatible tool has three enchant slots: Damage, Utility and Special.
> Each slot holds one enchant, levelled I to V. Enchants come as books, in
> bundles: from chests, from every lucky block, and for gems at the Forge (never
> from cases). Three of the same book merge into one a level up. The slots
> unlock with the new player level, which is earned from ore and chests.
> Enchants took over from tool traits and runes, which were retired on
> 2026-10-12 ([traits](traits.md)). Since 2026-10-19 there are 26: the 22
> below and four **Halloween** ones (Sugar Rush, Grave Digger, Spellbook,
> Flashlight) whose books come only from Candy Crypt chests and which work
> everywhere, forever; inside the Crypt they are the only enchants that work.

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
- a chance over 100% converts into that proc's damage (owner);
- **one ceiling on proc damage** (balance pass, 2026-10-19): Proc Power plus that
  family's own damage (Zap Damage, Tidal Wave Damage, ...) at most +300%
  (`MineEnchants.TUNING.procDamageCap`, the number of `MineConfig.PROC_POWER_CAP`).
  `procDamage` capped Proc Power alone and added the family's own damage on top
  uncapped, and the overflow above pours into it, so Rainbow pets, a skin and a charm
  stacked a hit without limit;
- **Spellbook** (a Halloween Special) has family `spell`: every family's chance and
  damage go to 0 (the book, not your pets, picks the ability), generic Proc Power
  stays, and `b.spellEvery` / `b.spellPower` say how often and how hard it casts.
  `MineEnchants.liveFamily` reads `"spell"` off that, so a pet card dims every
  family's line on a Spellbook tool, and Equip Best (`Dig.heldProcFamily`) values
  pets by their plain stats and Proc Power.

The families are Zap (`zap`/`zapDamage`), Blast (`blastChance`/`blastDamage`/`blastRadius`),
Tidal Wave (`tidalWave`/`tideDamage`), Shatter (`ricochet`/`shatterDamage`) and
Earthquake (`earthquake`, with `procPower` as its damage). Explosives roll no procs, so
they take no Special.

**Equip Best reads the Special** (`Dig.planUpgrades`, since 2026-10-18; the
owner's enchant brief: *"[make sure to encorperate this into auto equip]"*). The
gate zeroes every other family's proc, so a pet's chance and damage for another
family is worth nothing on this tool.
- `Dig.petShares` splits each pet's whole kit (named kit and print perk) into
  plain stats, each proc family's stats, and generic proc damage (`procPower`
  pays any family). It weights them the way the kits were priced (MineStats
  weights). `MineEnchants.familyOfStat` says which family a stat belongs to.
- `Dig.petWorth` scales the pet's card power by the share the held tool can use:
  plain stats, plus generic proc damage and its own family's proc.
- With a Special, the team is the best for that family. Without one, the tool
  keeps its gear's best proc, so Equip Best tries no proc and every family, and
  keeps the strongest team.
- Ties break on the card id, so the pick never flickers.

**The pet card says what the gate zeroes** (2026-10-19, launch audit S34). A pet
line for another family's proc is dimmed with "needs a Zap Special" (or "needs a
Special" for generic proc damage when nothing fires). `MineEnchants.gateNote`
marks the line off the same `familyOfStat` map, and `MineEnchants.liveFamily`
reads the family still firing off the server's gated boosts in the snapshot.
See [pets](pets.md).

**Three tiers per ability** (owner, 2026-10-12: *"Make 3 levels of abilities"*, tiers that change how it works). The Special's level picks the tier: I–II tier 1, III–IV tier 2, V tier 3 (`MineEnchants.TIERS`, read by `Dig.procsAt` as `b.procTier`). Pets' best proc alone is tier 1. Each ability also carries its own proc chance and damage, both rising per level (owner: *"also made the ability itself have a proc chance and dmage"*). PROPOSED, each capped:

| ability | tier 1 | tier 2 | tier 3 |
|---|---|---|---|
| Zap | Spark: 1 chain | Fork: 2 chains | Storm: 3 chains (continue 80%, was 85% until 2026-10-19) |
| Blast | Pop: 6 sides | Burst: 18 around | Detonation: 26 around, breaks pop again (max 3) |
| Tidal Wave | Swell: 1 layer | Breaker: 2 layers down | Tsunami: 3 layers down |
| Shatter | Crack: 3 bursts | Splinter: 6 | Cascade: 7 (was 10 until 2026-10-19) |
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
| Special | Zap / Blast / Tidal Wave / Shatter | 20–30% chance, +50% damage | the proc gate |
| Special | Earthquake | 25% chance, +125% Proc Power (was 20%, +50% until 2026-10-19) | the proc gate |
| Damage | 🍬 Sugar Rush (Halloween) | +2% swing speed a block broken in one hit, in a row, max +100% (owner) | swing |
| Damage | 🪦 Grave Digger (Halloween) | up to +60% damage at the bottom of the mine | swing |
| Utility | 🔦 Flashlight (Halloween) | 10% a broken block to light the rarest ore within 8 blocks for 10 s, then 30 s rest | block break |
| Special | 📖 Spellbook (Halloween) | every 4 hits, a random ability at 60% power, tier 3 | the proc gate |

The numbers the owner gave are marked; the rest are PROPOSED. Every number the
2026-10-19 pass proposed is in one table, `MineEnchants.TUNING`.

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
- **Sugar Rush** (`MineEnchants.rushSpeed`, `MineEnchantService.afterSwing`):
  every block a swing breaks in one hit adds to the run -- the aimed block and the
  tool's own area cells, so a 3x3 jackhammer adds up to nine -- while the aimed block
  was itself a one-shot. A swing whose aimed block takes more than one hit ends it,
  and so do 2.5 s without a one-shot. It shares Overclock's speed path (the server's
  swing budget and the client's `enchSpeed` pacing) and its +100% cap, so the two
  never stack: Overclock counts swings, Sugar Rush blocks. Flashes SUGAR RUSH +n%.
- **Grave Digger** (`MineEnchants.depthBonus`): + 12% a level at the floor, on
  (layer / floor)^0.6, so V is +15% a tenth of the way down, +39% halfway and +60% at
  the floor. The floor is `MineConfig.LAYERS` (5,000; Meadow is full strength from
  there down) or, in the Crypt, `MineConfig.CANDY_DEPTH_LAYERS`. In the swing like
  Critical Strike, so it scales the swing's area cells and abilities too.
- **Spellbook** (`MineEnchantService.spellCast`): every `b.spellEvery` swings that
  land (8 at I down to 4 at V), one of Zap, Blast, Tidal Wave, Shatter and Earthquake
  at random -- Earthquake is left out when the aimed block has just broken, as it would
  shake nothing -- runs through the same `Dig.procsAt` a natural proc does, with that
  ability made certain, at the Special's tier and 60% of the swing's damage. So a cast
  IS the real ability, caps and the breaking gate included. Flashes SPELL.
- **Flashlight** (`MineEnchantService.flashlight`, called from `finishBreak` for every
  broken block): off its cooldown, a broken block rolls 2% a level; a hit looks through
  the zone's voxels within 4 + level blocks for the rarest ore the held tool can break
  (highest ore tier, or candy rank in the Crypt; nearest on a tie) and fires
  `flashlight` to the client, then rests 60 s at I down to 30 s at V (5 s when nothing
  was in reach). The client (`MineProcFx.flashlight`) lights that block through the
  rock with a Highlight in the ore's colour and its name above, for 6 + level seconds;
  it fades, and no text scales.
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
  Its **ODDS** button (owner, 2026-10-19, launch audit M3: gems trace back to
  Robux) shows each book's chance from `MineEnchants.bookOdds`, the weights
  `rollBookId` rolls (`tools/verify/paid-odds.js` rolls one against the other).
- **Never cases.**
- **Halloween books come only from Candy Crypt chests** (owner, 2026-10-19:
  "Halloween enchant books drop from Crypt chests (rarer chests more often)").
  `MineEnchants.rollHalloweenBook(rankIndex, rng, chestLuck)` takes the chest's rank
  1..8 (F..SSS) and returns an id or nil; `halloweenBookOdds` is the sheet it draws
  from. A chest drops one 3% (F) to 27% (SSS) of the time, times chest luck (capped
  x3), and better chests lean rarer: each book's rarity weight is raised to 1 - 0.5 x
  (rank - 1) / 7, so Spellbook (Legendary) is 7% of F books and 14% of SSS books. A
  Halloween book is level I and merges like any book. `rollBookId` and `bookOdds` skip
  them (`event = "halloween"`), so no main-game chest, lucky block, gem bundle, level
  gift, pass tier or wheel slice pays one. The Crypt (agent V2-A's area) calls it.
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

## In the Candy Crypt (owner, 2026-10-19)

"Normal enchants don't work" in the Crypt; the Halloween ones do.
`MineEnchants.activeHere(zoneId, enchantId)` is false for every normal enchant in
`NORMAL_OFF_ZONES` (`hallow`) and true otherwise; an id that is no enchant is never
active. Every read of an enchant's effect in `MineEnchantService` goes through it with
the zone the player stands in (`p.zoneId`): the Layer 1 stats, the Special (a normal
Special there leaves the tool on its pets' best proc, as if it had none), the swing,
the streaks, the ore rolls, XP and the reveal. Which tool's enchants count in the
Crypt is unchanged: the service reads the forged tool you have equipped
(`p.oreToolEquipped`) while you swing a Crypt tool (see the questions below).

## Every enchant, checked end to end (2026-10-19)

The owner: *"make sure all enchants works"*. `tools/verify/enchant-audit.js` follows
each of the 26 from its book to what the player sees, on the real modules, the real
`MineEnchantService` and MineServer's own `Dig.procsAt`, `Dig.startQuake` and quake
tick, sliced out of the script in file order (`tools/verify/_enchant-sim.js`). Book:
the main game's rolls (or only Crypt chests). Equip: the real `enchApply` at V on a
tool it fits (an unfitting tool refuses it). Effect: what the server does, run. Crypt:
off for the 22, on for the four. Client: the Forge's line at every level, the words,
an animation for every ability word.

| enchant | slot | what the server did at V | status |
|---|---|---|---|
| Power | Damage | Mine Speed +27.6% | works |
| Heavy Impact | Damage | Mine Speed +30%, swing time +25% | works |
| Critical Strike | Damage | x1.29 on average (20% for x2.5), CRIT! | works |
| Executioner | Damage | x2 within 2 hits of breaking | works |
| Demolitionist | Damage | x1.4 on a block of 8+ hits | works |
| Overclock | Damage | x2 swing speed after 20 one-shots; lapses after a miss or 2.5 s | works |
| Short Fuse | Damage | Short Fuse +15% (explosives) | works |
| Combo | Damage | first hit plain, x3 at 100 in a row, resets after 2 s | works |
| Fortune | Utility | Ore Haul +50% | works |
| Scavenger | Utility | Coin Bonus +61% | works |
| Gemfinder | Utility | Gem Find +47% (chest gems only: ore sales do not read gemFind) | works |
| Treasure Hunter | Utility | Chest Luck +47% | works |
| Reach | Utility | Reach +40% (the snapshot's tool reach includes it) | works |
| Experience | Utility | 100 XP pays 161 | works |
| Vein Miner | Utility | 10 more blocks of the vein | works |
| Alchemy | Utility | 10% of ore drops upgraded | works |
| Duplicator | Utility | 20% of ore drops doubled | works |
| Zap | Special | 25%, tier 3 | works |
| Blast | Special | 25%, tier 3 | **fixed**: its tier 2 and 3 words (BURST, DETONATION) played no animation or sound |
| Tidal Wave | Special | 20%, tier 3 | **fixed**: tiers 2 and 3 rolled the wave UP into dug space (`cy - layerOff`; depth is +cy) |
| Shatter | Special | 30%, tier 3 | works |
| Earthquake | Special | 25%, tier 3 | works (weak, see the balance pass) |
| Sugar Rush | Damage | x2 after 50 one-shot blocks (six 9-block swings) | new |
| Grave Digger | Damage | x1.6 at the floor, x1.4 halfway, x1.0 at the top | new |
| Spellbook | Special | a cast every 4 swings, all five abilities | new |
| Flashlight | Utility | lit the rarest ore it can break, then rested 30 s | new |

The check also pins the swing it runs to `swingBlock`'s text step by step, checks the
server reads every stat a Layer 1 enchant writes, and fails on `3863d14` (13 failures).

## The balance pass (2026-10-19)

The owner: *"Do balancing checks to make sure good enough, but not too overpowered
stacked with enchants too, i want every ability enchant to be viable with different
builds, depending on what their going for"*. `tools/verify/enchant-balance.js` digs, on
the real proc code, with each ability Special on each tool family at three stages:
early (Greyvein Quarry, layer 2500, ore tier 14, Special II, Normal pets, a B skin, the
Sod Charm), mid (Bloodmoon, 2500, tier 38, IV, Golden pets, an S skin, Tideglass) and
late (Primordium, 4500, tier 82, V, Rainbow pets, an SSS skin, Gatebreaker). Builds:
*plain* (Equip Best's plain pets), *charm* (plus the family's proc charm: Omni Blast or
Chainlink), *pets* (Equip Best for that ability) and *stack* (pets, proc charm and a
skin carrying the ability). Goals: AREA (blocks a second on the stage's rock, where
the gear breaks every block in one hit), TOUGH (damage a second on rock taking eight
swings) and SINGLE (damage a second on one block that never breaks). Each build is
measured against itself with every ability off, so pets' and charms' plain stats
cancel and what is left is what the ability stack adds.

**Rules (PROPOSED):** every ability is the strongest choice somewhere; every ability
adds +10% to some goal at every stage; on AREA the strongest ability's best build is at
most 2.25x the median ability's best; on TOUGH and SINGLE no ability's best build is
over 2x the runner-up's; Flashlight lights at most 2.5 ores a minute and glows at most
40% of the time.

**What each ability's best build adds (x over the same build with no ability), area / tough / single:**

| ability | early | mid | late |
|---|---|---|---|
| Zap | 4.0 / 2.0 / 1.0 | 5.6 / 5.2 / 1.0 | 5.6 / 10.2 / 1.0 (was 6.1 / 12.2 / 1.1) |
| Blast | 1.5 / 1.0 / 1.0 | 5.9 / 1.2 / 1.0 | 9.9 / 3.5 / 1.0 |
| Tidal Wave | 3.2 / 1.1 / 1.0 | 5.7 / 1.8 / 1.0 (was 5.7 / 4.1) | 6.2 / 2.1 / 1.0 (was 6.2 / 11.5) |
| Shatter | 2.3 / 1.0 / 1.0 | 8.3 / 1.1 / 1.0 | 13.0 / 1.1 / 1.0 (was 18.6) |
| Earthquake | 1.0 / 1.1 / 1.1 | 1.0 / 3.7 / 1.9 (was 2.9 / 1.7) | 1.0 / 5.7 / 2.7 |
| Spellbook (new) | 1.4 / 1.1 / 1.0 | 3.3 / 1.3 / 1.0 | 4.6 / 1.8 / 1.1 |

"Was" is the same harness with `3863d14`'s numbers (the Tidal Wave direction fix in
both). Each ability is the strongest choice in 6 to 41 of the 144 build-and-goal cells:
Tidal Wave and Shatter clear area (Shatter is the late pickaxe's: its chain follows the
rock you have not dug, 2.1x the median ability there), Blast with an Omni Blast charm,
Zap on tough rock and when it fires every swing, Earthquake on a stubborn block and
tough rock, Spellbook with no matching pets.

**The four changes** (all in `MineEnchants.TUNING`): Shatter's Cascade 10 -> 7 bursts;
Storm continues 80% a hop, not 85%; Earthquake 5% chance and +25% Proc Power a level
(was 4%, +10%); the proc damage ceiling above.

**Found, not changed:** Earthquake only rolls on a hit that does not break, so on rock
your gear one-shots (most of the game, once pets and a charm are on) it never fires.
Its tick is still `procDamage(.., "quake")` (12% of a swing) x 0.1 a stack, about 1.2x
a swing a second at 100 stacks, not the 10x `MineConfig` documents: the open question
in [open-questions](../open-questions.md) section 3. Zap's best mid and late builds owe
much of their speed to the swing rate the Volt pets bring (64 swings a second late),
which the ability multiplier above leaves out.

**The Damage slot** (plain build, no Special, a short pause every 15 s), x over no
Damage enchant, area / tough: Sugar Rush matches Overclock on one-shot rock (x1.3 early
to x2.0 late, within 5% of each other: the same +100% cap) and adds nothing on tough
rock; Grave Digger adds x1.2 halfway down and x1.4 near the floor on tough rock (Power
x1.07, Combo x1.5 to x2.4) and nothing where blocks break in one hit.

**Flashlight:** about 0.9 ores a minute at I (glowing 9% of the time) and 1.9 at V
(glowing 32%), at every stage: the cooldown, not the chance, sets the pace.

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
- **Built and checked 2026-10-19:** the four Halloween enchants, `activeHere`, Crypt
  books (`rollHalloweenBook`), the audit (`tools/verify/enchant-audit.js`) and the
  balance pass (`tools/verify/enchant-balance.js`). Not seen in Studio or a live server.
- **Built and checked** (`tools/verify/enchants.js`):
  - the data, the server verbs, XP and levels, Layer 1 stats and the Special proc gate;
  - all eight mining enchants;
  - book bundles from chests and lucky blocks, and the Forge's gem bundle.
- **The Forge hub** shows and applies all of this ([client-and-ui](../code/client-and-ui.md)).
  The Blacksmith counter opens it.
- **Retired for them (2026-10-12):** tool traits, runes, scrolls and sockets. The
  rewards that paid scrolls pay books now: the Founders pack (3) and the daily
  wheel's 6% slice ("3 LUCKY BOOKS", S-chest levels). The reworked battle pass
  (2026-10-16) pays books on most tiers
  ([shops-and-monetisation](shops-and-monetisation.md)). The tutorial's step 8 gives 2 free Damage
  books and opens the Forge on ENCHANT; the quests ask for enchants and book
  merges. See [traits](traits.md).
- **Built since:** Equip Best reads the Special (2026-10-18, above); the Short
  Fuse enchant (2026-10-16). Coolant stays on the skill tree only (owner).
- **Not yet seen in a live server:** the mining enchants and bundles are checked
  by code, not by play.
- **Before level 25** the tool keeps its gear's best proc; the owner chose this over
  "no procs before a Special enchant" (2026-10-12).

## Open questions (2026-10-19, for the owner)

- **Which tool's enchants count inside the Crypt?** You swing a Crypt tool there,
  but the service reads the enchants of the forged tool you have equipped, so the
  Halloween enchants on your main pick work in the Crypt. The other readings: Crypt
  tools get enchant slots of their own (the Crypt's redesign), or no enchants in the
  Crypt at all.
- **Earthquake on rock you break in one hit** never fires. Let a quake shake a
  neighbouring block when the hit breaks yours ("aftershock"), or keep it the
  stubborn-rock ability? And its tick: about 1.2x a swing a second at the stack cap
  (the code) or 10x ([open-questions](../open-questions.md) section 3)?
- **Sugar Rush comes out level with Overclock** (the same +100% cap). Keep it so, or
  set it apart (a higher cap for an event book, or a run that survives a two-hit
  block)?
- **Gemfinder** multiplies chest gems only; selling ore pays gems without it.
