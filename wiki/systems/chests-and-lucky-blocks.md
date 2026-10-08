---
title: Chests and lucky blocks
type: system
status: current
verified: 2026-10-08 @ bae3c5b
sources:
  - src/ReplicatedStorage/Mine/Shared/MineZoneChests.luau
  - src/ReplicatedStorage/Mine/Shared/Mine1ChestsData.luau
  - src/ReplicatedStorage/Mine/Shared/MineChestModel.luau
  - src/ReplicatedStorage/Mine/Shared/MineChestRanks.luau
  - src/ReplicatedStorage/Mine/Shared/MineLuckyBlocks.luau
  - src/ReplicatedStorage/Mine/Shared/MineGradeReveal.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - docs/TODO.md §0.27, §0.32
  - docs/PROPOSAL.md §0 line 21
  - docs/AUDIT.md §5
related: [cards-and-packs, mining-and-breaking, zones-layers-and-seams, shops-and-monetisation, currencies-and-economy]
---

# Chests and lucky blocks

> **Chests** are blocks in the mine wall. You break one and it pays coins, gems
> and maybe packs. **Lucky blocks** are a second gacha. They drop rarely off
> ordinary rock, sit in your bag like packs, and on opening climb an F→SSS grade
> before paying out. Both exist to give the dig a hit between ore finds.

`MineServer` below means `src/ServerScriptService/Mine/MineServer.server.luau`.

## How it works — chests

**Where a chest spawns.** `rollKind` in MineServer makes a block a chest when a
roll beats `MineConfig.CHEST_CHANCE` (0.003). That chance is multiplied in a few places:

| where | multiplier | source |
|---|---|---|
| Event Horizon | ×3 | `zone.chestMult` |
| Meadow, layers 1–100 | ×2 | `MEADOW_SHALLOW_CHEST_MULT` |
| during a World Pulse | ×`worldChestMult` | disabled, see [world-events](world-events.md) |

**Which chest it is**, decided at spawn by `MineZoneChests.rollSpawn`:
- **A catalog chest from `Mine1ChestsData`** (80 rows, layer bands), picked by
  `MinePackConfig.rollChestAt`. The share is 45% of chests, but only 2.5% in zone 1
  at layer ≤ 120 and 12% deeper in zone 1. `m1_lookingglass` is never picked.
- **Otherwise, the zone's pool**, rolled by rank in `MineChestRanks`. The weights
  are S 4, A 10, B 22, C 100, D 35, F 0.
- **The Shiny Chest (chase).** In zone 1 it can appear only at layer ≥ 2500, at
  1/8000. In zones 2–10 the chance lerps from 1/2500 up to 0.8%.

`MineChestModel` builds the visible chest. It has five palettes: native, broad,
currency, item, chase. The model's parts are `CanQuery` false, so they never
steal the aim raycast.

**What a chest pays** (`openChestBlock` in MineServer):
- **The chest def.**
  - Meadow and Event Horizon **always** use the section-exclusive chest from
    `MineZoneChests.exclusiveFor`: one per 25-layer section, with coins taken from
    that section's dirt HP and 0 gems.
  - Other zones use the block's own chest when it is in `MineZoneChests.DEFS`.
    If it is not, they re-roll from the zone pool.
- **Coins and gems** come from the def's fixed bands (`rollCurrency`), then are
  multiplied by `coinBonus` and `gemFind`. Each def's gems were already multiplied
  once by `MineZoneChests.GEM_MULT` for its home zone.
- **Stardust** from the `scrap` stat.
- **Packs.** Each entry in the chest's `packs` list is an independent % roll for
  a zone pack slot (`rollPackDrops`). A Meadow section chest rolls currency_common
  72, pack_common 18, pack_rare 6, pack_legendary 1 and currency_rare 3. A
  legendary pack fires the "BONKERS PACK" popup.
- **Tutorial chests** force how many packs drop through the `PackQty` attribute.
- **Persist bag.** Mid and deep layers have a small chance (0.8% / 0.4%, times
  `chestLuck`) at a one-off bag that adds `backpackBonus`.
- **A graded charm, 0.5%** (2026-10-07, `fd5c432`). `MineCharms.CHARM_CHEST_CHANCE
  0.005 × chestLuck`, rolled in `openChestBlock` on every chest. `rollChestCharm`
  then picks which of the 36 graded charms by `MineTemper` rarity weights, so it is
  mostly F and D. It is written against the `Charms` upvalue, **not** the
  `rollChestTool` local that open-questions #7 says reads as nil, and `charms.js`
  asserts the declaration comes before the use. See [charms](charms.md).

**Rank aging.** Unlocking a zone runs `MineZoneChests.onPermanentZoneUnlocked`.
Every earlier zone's pool ages one rank (S→A→…→D→F, extinct) and the next S chest
is injected from `S_QUEUE`.

## How it works — lucky blocks
- **Found.** Every break of ordinary rock rolls `MineConfig.LUCKY_BLOCK_CHANCE`
  (0.0002) × (1 + `luckyFind`). Ore, chests and cores don't roll. The code is the
  last `else` branch of the break handler.
- **Type.** `MineLuckyBlocks.PIT_WEIGHTS` sets the mix: Lucky 80, Diamond 15,
  Mythic 5. The ids are `lucky_block`, `super_lucky_block`, `godly_lucky_block`.
- **Starting grade.** A found block may start graded (`PRESET_WEIGHTS`: F 70,
  D 18, C 8, B 3, A 1).
- **Other sources.** The battle-pass track, the credits shop (45 / 120 / 280
  credits, or 10 for 350), rotating offers and the Weekend Haul product.
- **Stored** in `p.packs` as `kind = "lucky_block"`. The stack key is
  block | grade | luck | levels bought (`stackKey`).
- **Grade-up.** `Verbs.luckyGradeUp` costs gems before you open:
  `GRADE_UP_BASE` 25,000 × `GRADE_UP_GROWTH` 5^n, so 25K, then 125K, and so on.
- **Opening.** `Verbs.openLucky` climbs the grade with `MineToolGrades.rollClash`.
  The odds per step are `UPGRADE_P` {½, ½, ⅓, ¼, 2/7, 2/7, 2/7}, and three misses
  end the climb. SSS lands about 0.85% of the time, per the comment on
  `UPGRADE_P`.
- **Loot.** `MineLuckyBlocks.rollLoot(blockId, finalGrade)` picks the kind from
  the block type and the grade band: pack, gems, dust, tool, scroll or pet.
- **The lucky screen** is the lucky path in `MineGradeReveal`. It runs at
  DisplayOrder **120**, the same as `MinePackReveal`, since `bca50ca`.

## Where it lives
| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineZoneChests.luau` | zone chest defs, pools, exclusives, payouts | `DEFS`, `POOLS`, `rollSpawn`, `exclusiveFor`, `rollPackDrops`, `GEM_MULT` |
| `src/ReplicatedStorage/Mine/Shared/Mine1ChestsData.luau` | 80-row catalog of chests with layer bands | `layers`, `weight`, `packs` |
| `src/ReplicatedStorage/Mine/Shared/MineChestRanks.luau` | S..F ladder and aging | `WEIGHT`, `agePool`, `roll` |
| `src/ReplicatedStorage/Mine/Shared/MineChestModel.luau` | the visible chest | `PALETTE` |
| `src/ReplicatedStorage/Mine/Shared/MineLuckyBlocks.luau` | types, shop rows, grade-up, loot | `TYPES`, `SHOP`, `UPGRADE_P`, `rollLoot` |
| MineServer | spawn, break, open | `rollKind`, `openChestBlock`, `Verbs.openLucky`, `Verbs.luckyGradeUp` |

## Decided by the owner
- **Lucky screen layering is fixed and confirmed in engine.** Owner, after
  pulling: *"inventory is under"* (TODO §0.32). It is the first change on the
  branch that anyone confirmed by running it.
- **PROPOSAL §0 line 21** ("chest coin reward: FIX THE CRASH") is approved and
  marked fixed. See the gotcha below.
- **Chests do not drop charms.** Charms drop from ore (TODO §0.13 rule 5).

## State right now
- **Shipped, and mostly inherited.** These modules last changed in the import or
  in fossil removal (`ba345b7`).
- **Lucky blocks are on the AUDIT §5 ARCHIVE list** ("a second gacha"). That is a
  proposal; the owner's yes to the cut list is not recorded, and nothing has been
  archived.

## Gotchas
- **The crash fix landed in dead code** (static read). PROPOSAL line 21 was fixed
  in `e77d84e` inside `rollChestLoot`. Only `giveDrop` calls that function, and
  **nothing calls `giveDrop`**. Live chests pay through
  `MineZoneChests.rollCurrency`, which never had the crash. The same dead path is
  the only caller of `MinePackConfig.rollChest`, `MinePackConfig.CHESTS` and
  `MineConfig.chestPackCount`.
- **Chest flagship tools never roll from zone chests** (static read, the
  global-read trap). `openChestBlock` checks `if rollChestTool then`, but
  `local function rollChestTool` is declared about 2,600 lines lower. At that
  call site the name is a nil global, so the "Secrets" tools cannot drop there.
  Only `openFrom` reaches it, and that path needs chest items in `p.backpack`,
  which nothing creates any more.
- **A catalog `m1_*` chest's own loot table is never used** (static read). The
  block shows that chest, but `ZoneChests.def` does not know the id, so opening
  re-rolls from the zone pool. In Meadow and Event Horizon the section chest
  always wins anyway.
- **Rank aging is server-wide and in memory** (static read). `POOLS` is module
  state. Any player's unlock ages it for everyone in that server, and a server
  restart resets it.
- **One lucky block has three names.** `TYPES.godly_lucky_block.name` is
  "Mythic Lucky Block", but its shop row label says "Goldy Lucky Block".

## Open questions
- Archive lucky blocks or keep them (AUDIT §5)?
- Should the dead `giveDrop` path be deleted, or should flagship chest tools be
  reconnected? See [open-questions](../open-questions.md).
- "Chests spawn everywhere but supremely rare, like ore" (OPEN P2) is not started.

## See also
[cards-and-packs](cards-and-packs.md) · [mining-and-breaking](mining-and-breaking.md) · [zones-layers-and-seams](zones-layers-and-seams.md) · [shops-and-monetisation](shops-and-monetisation.md) · [luau-traps](../code/luau-traps.md)
