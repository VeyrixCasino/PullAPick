---
title: Traits and runes (retired)
type: system
status: retired
verified: 2026-10-12 @ 4e4fbb3
sources:
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ReplicatedStorage/Mine/Shared/MineEnchants.luau
  - src/ReplicatedStorage/Mine/Shared/MineScrolls.luau
  - src/ReplicatedStorage/Mine/Shared/MineFounders.luau
  - src/ReplicatedStorage/Mine/Shared/MineGroupWheel.luau
  - src/ReplicatedStorage/Mine/Shared/MineQuests.luau
  - src/ReplicatedStorage/Mine/Shared/MineCards.luau
  - src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau
  - tools/verify/runes-retired.js
related: [enchants, boosts-and-stats, retired-and-parked, tools, hats-and-faces, pets, shops-and-monetisation, social-quests-and-leaderboards]
---

# Traits and runes (retired)

> **Retired on 2026-10-12.** Tool traits, runes, scrolls and sockets are gone from
> the game. [Enchants](enchants.md) took their field. The owner, 2026-10-11:
> *"RETIRE RUNES AND TRAITS.. ENCHNATS TAKE OVERTHAT FEILD"*. Then, 2026-10-12,
> on refunds: *"no one has played.. ur good"*. So nothing was refunded.

## What they were

- **A tool trait** was one prefix word on one forged tool ("Sharp Stone Pickaxe").
  It was rolled at the Enchanter for 500 gems and paid one stat in layer 1. Save
  field: `tool.trait = { id, level }`.
- **Runes** were socketable stat stones. They were rolled at Summon, fused, and
  socketed into a tool family, a chest tool, a shop tool, a pet or a gear piece.
  Save fields: `p.runes`, `p.toolSockets`, `p.petSockets`, `p.shopToolRunes`.
- **Scrolls** (White, Black, Omniscroll, the Runesmith Package) were rune tools
  bought with credits. Save field: `p.scrolls`.

## What replaced each payout

| place | before | now |
|---|---|---|
| Layer 1 of `boosts()` | the held tool's trait | the held tool's Damage and Utility enchants |
| The proc | rune and trait proc stats | the Special enchant (pets only boost it) |
| The gem sink | rune rolls and fuses | the Forge's gem book bundle (owner's pick) |
| Premium pass tiers 25 / 55 / 88 | a White / Black / Omni scroll | 3 / 4 / 5 enchant books |
| Founders pack | 1 White Scroll | 3 enchant books (`MineFounders.BOOKS`) |
| Daily wheel, 6% | a Heavy Rune Case | "3 LUCKY BOOKS": 3 books at an S chest's levels |
| Tutorial steps 8 and 9 | "ROLL A RUNE", then socket it | step 8: 2 free Damage books, ENCHANT your pick at the Forge |
| Quests | rune5, trait1, rune40, contract c_rune_s | ench1, bookmerge1, bookmerge10, c_ench_s |
| The Enchanter | Traits, Merge, Sockets, Summon, Temper, Salvage, Dust | Summon, Temper, Salvage, Dust |

- **The owner's picks** (2026-10-12):
  - only tool traits go; pet per-print perks (`MineCards.TRAITS`, e.g. Lone Wolf) stay;
  - gems buy book bundles;
  - the Enchanter is kept with four tabs;
  - the wheel's slice is *"3 lucky enchanted books"*;
  - the pass uses books, *"but we have to rework the entire battle pass"* (open).
- **An assistant default, not the owner's:** the Founders pack's 3 books.
- **The rune and trait rungs** became enchant rungs in the same places, with the
  same rewards:
  - *ench1*: enchant a tool;
  - *bookmerge1*: merge 3 books;
  - *bookmerge10*: merge 10 times;
  - *c_ench_s*: fill 2 slots.
  The server counts `enchants` (filled slots) and `bookmerges` (`p.bookMerges`).

## How the retirement works

- **Old saves drop it all on load:**
  - `p.runes`, `p.toolSockets`, `p.petSockets`, `p.shopToolRunes` and
    `p.scrolls` are set to nil;
  - every forged tool's `trait` and every chest tool's `runeId` are cleared;
  - gear `sockets` are emptied.
- **No verb is left.** The rolls, fuses, socket verbs, scroll verbs, pouches,
  crates and `rollTrait` are gone, and so are their dispatch lines and their
  `PAID_RANDOM` rows. The gem book bundle (`enchBuyBundle`) took a
  `PAID_RANDOM` row, so the regional paid-random rule covers it.
- **Deleted:**
  - `MineRunes`, `MineRunesView`, `MineSocketsView`, `MineTraits` and
    `MineTraitView`;
  - the three rune cases;
  - the scroll items (`MineScrolls.ITEMS` is empty);
  - rune trading;
  - the Inventory and Collection Runes tabs;
  - the Loadout's Gems and Traits sections;
  - the old Forge's SOCKET A RUNE button.
- **The floor moved.** `MineRunes.clampBoosts` is now `MineCards.clampBoosts`,
  and it floors every `ADDITIVE_STATS` stat at 0. Its old list had fallen behind:
  Tidal Wave, every proc's damage, Proc Power and Ore Haul were floored like
  multipliers, at 0.05. So every tool rolled a 5% Tidal Wave and everyone had
  +5% Ore Haul, even after the Special gate zeroed them.
  [boosts-and-stats](boosts-and-stats.md) has the details.
- `tools/verify/runes-retired.js` keeps it gone and checks every replacement.

## Open

- **Coolant and Short Fuse now come only from the skill tree.** Drill spin-up
  (`coolant`, Water's primary) and bomb cooldown (`shortFuse`, Metal's third)
  also came from runes and traits. Pets and gear cannot roll them. Should
  enchants offer them too?
- **The battle pass rework** the owner mentioned has no brief yet.

## Kept on purpose

- `MineStats.RUNE_ONLY`: MineCards uses it to keep those stats off pet kits.
- `MineTradeValue.RUNE_DUST`: `tierOf` reads it. `runeValue` remains but nothing
  calls it.
- The `heavy_runes` id on the wheel slice: an id is identity.
- `src/ReplicatedStorage/MineGear.luau` and `MineGear_AdminTest.luau`: stale root
  copies that nothing requires. They still name MineRunes.

## Gotchas

- **"Trait" still names a pet's per-print perk** (`MineCards.TRAITS`). That one is
  live. See [pets](pets.md).
- **Do not reuse the rune ids or the `p.runes` field.** Old saves on other
  machines may still carry them until they next load.
