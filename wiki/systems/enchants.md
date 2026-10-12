---
title: Enchants and the player level
type: system
status: partial
verified: 2026-10-12 @ ffb716f
sources:
  - src/ReplicatedStorage/Mine/Shared/MineEnchants.luau
  - src/ServerScriptService/Mine/MineEnchantService.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - tools/verify/enchants.js
related: [traits, boosts-and-stats, mining-and-breaking, pets, chests-and-lucky-blocks, rebirth-and-skill-tree]
---

# Enchants and the player level

> Every compatible tool has three enchant slots: Damage, Utility and Special.
> Each slot holds one enchant, levelled I to V. Enchants come as books from
> chests (cases next). Three of the same book merge into one a level up. The
> slots unlock with the new player level, which is earned from ore and chests.
> Enchants take over from traits and runes, which are being retired.

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
- with no Special enchant there is no proc at all;
- a chance over 100% converts into that proc's damage (owner).

The families are Zap (`zap`/`zapDamage`), Blast (`blastChance`/`blastDamage`/`blastRadius`),
Tidal Wave (`tidalWave`/`tideDamage`), Shatter (`ricochet`/`shatterDamage`) and
Earthquake (`earthquake`, with `procPower` as its damage). Explosives roll no procs, so
they take no Special.

**Damage and Utility are Layer 1** (`MineEnchantService.layerStats`), beside the
trait, skin and skills (owner §0.19: the layers multiply, sources inside a layer
add). Only the held tool's enchants count.

**The enchants** (`MineEnchants.LIST`). *Live* means the effect works today;
*soon* means the book exists and drops, but the Forge shows COMING SOON and the
server refuses to apply it until the mining code lands.

| slot | enchant | effect at V | live |
|---|---|---|---|
| Damage | Power | +27.6% damage (+5% a level, compounded; owner) | live |
| Damage | Heavy Impact | +30% damage, -20% swing speed (owner) | live |
| Damage | Critical Strike | 20% for ×2.5 | soon |
| Damage | Executioner | +100% within 2 hits of breaking | soon |
| Damage | Demolitionist | +40% on blocks of 8+ hits | soon |
| Damage | Overclock | +5% speed a one-shot in a row, max 20 (owner) | soon |
| Damage | Combo | +2% a hit in a row, max 100 (owner) | soon |
| Utility | Fortune | +50% ore haul | live |
| Utility | Scavenger | +61% coins | live |
| Utility | Gemfinder | +47% gems | live |
| Utility | Treasure Hunter | +47% chest luck | live |
| Utility | Reach | +40% reach | live |
| Utility | Experience | +61% player XP | live |
| Utility | Vein Miner | +10 vein blocks (ore only) | soon |
| Utility | Alchemy | 10% to upgrade the ore | soon |
| Utility | Duplicator | 20% double drops | soon |
| Special | Zap / Blast / Tidal Wave / Shatter / Earthquake | 20–30% chance, +50% damage | live |

The numbers the owner gave are marked; the rest are PROPOSED.

**Books** (`p.enchantBooks["power:1"] = n`):
- 5% of chests drop one (`CHEST_BOOK_CHANCE`), raised by chest luck up to ×3.
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
- Books from chests and cases; merge 3 for +1 level.
- Slots unlock at levels 1 / 10 / 25, with a gift every 5 levels.
- Traits and runes are retired; what players own is refunded (next step).

## State right now
- **Built and checked** (`tools/verify/enchants.js`): the data, the server verbs, books
  from chests, XP and levels, Layer 1 stats, and the Special proc gate.
- **Not built yet:**
  - the Forge hub UI (Forge A) that shows and applies all of this;
  - books from cases;
  - the "soon" enchants' mining code;
  - the trait and rune retirement with refunds;
  - the pet overlap fix;
  - auto-equip that reads the Special.
- **Watch: no procs before a Special enchant.** Because the Special decides the proc, a
  player has none until they apply one, which needs level 25. Pets with procs do
  nothing until then. This is what the rules say; it is flagged for the owner.
