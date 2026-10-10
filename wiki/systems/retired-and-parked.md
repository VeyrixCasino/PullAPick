---
title: Retired and parked
type: system
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - docs/AUDIT.md §5
  - docs/TODO.md §0.12
  - docs/TODO.md §0.21
  - docs/TODO.md §0.26
  - docs/PROPOSAL.md §0
  - docs/OPEN.md
  - docs/START-HERE.md §4
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ReplicatedStorage/Mine/Shared/MineBags.luau
  - src/ReplicatedStorage/Mine/Shared/MineStats.luau
  - src/ReplicatedStorage/Mine/Shared/MineZonePacks.luau
  - src/ServerStorage/MineParked/GroupWheel/README.txt
  - tools/verify/orepacks.js
related: [charms, traits, pets, hats-and-faces, save-data-and-migrations, rojo-and-studio, code-map, luau-traps]
---

# Retired and parked

> Everything that is gone from play, half-gone, or waiting to be cut, but is still on
> disk or in player saves. Read this before deleting or renaming anything. A stat key,
> an id or a list index here is often **save data**, not dead code (START-HERE §4.4).

## Removed from play, with a remnant you must keep

| thing | status | what remains, and why | never rename / delete |
|---|---|---|---|
| **Fossils** | retired by the owner on 2026-10-02 (§0.12). `MineFossils` and `MineFossilEconomy` were deleted in `c55ac49`. | `FossilPay` and `retireFossils(p)` in MineServer cash out `p.fossilPieces`, `p.fossilTools` and any held fossil packs to gems on load, once. Its own comment says it can be deleted after old saves drain. | — |
| `fossilFind` stat | the **key** stays, shown as "Ore Finder" (§0.12, `MineStats`) | still on the Seeking trait, three legacy charms, runes, and the tree (`MineStats.TYPE_KITS` is gone, 2026-10-10). A grep found no live reader on the ore path (unverified). | **the key** |
| 60 fossil-track bags | unobtainable; `fossil = true` hides them from every shelf and count | `MineBags.LIST` index padding: a bag id is `bag_<index>`, so deleting rows would hand every player a different backpack | **the rows** |
| **Ore packs** (`<ore>_ore_pack`) | no longer drop: ore goes straight to the pouch | `Dig.bankOrePacks(p)` banks them on load at the midpoint yield, only as many as fit. There is no version stamp, so it retries every load. `MineZonePacks` keeps the ids so a leftover can still be opened by hand. Guarded by `tools/verify/orepacks.js`. | the `_ore_pack` suffix |
| Retired stats `backpack`, `walkSpeed` | `legacy = true` since 2026-10-04 (§0.21); out of `STAT_ORDER` and every roll pool | the entries stay so `boosts(p).backpack` / `.walkSpeed` and old kits still resolve. They are **still on** 182/11 pet kits, 24 ore charms, the tide set and pet traits. | the keys |
| `echo`, `autoMine` | barred as buffs | paid out as swing rate (`MineStats.ECHO_TO_SWING`) and gem find (`AUTO_MINE_TO_GEM`) in `boosts()` | the keys |
| `oreYield` | renamed `blastChance` in `eb973f6` (2026-10-04) | `MineStats.LEGACY_STAT` maps it on load for saved runes and gear | — |
| Traits Deep, Fleet | removed with backpack and walkSpeed | an unknown id makes `MineTraits.byId` return nil | the other 23 trait `id`s |
| Pet seats 4–8, VIP's 4th seat | clamped to 3 on load (`effectivePetSlots`) | `PET_SLOT_PRICE {0,0,0}` is kept so old rows resolve | — |
| Hats on pets | `p.petHats` deleted; those hats fold into your seats | `ClientFns.petHatPiece` is a stub that returns nil | — |
| Six gear slots | head, amulet, chestplate, leggings, boots, gloves | `MineGear.LEGACY_SLOTS`, `migrateSlot`, `OLD_RARITY` | the slot names in saves |
| `MineEventHorizonPets.luau` | deleted in `f6bb23f` (a byte-identical duplicate) | consumers still try `FindFirstChild("MineEventHorizonPets")` as a fallback | don't reuse that name |
| `prestigeYield` | deleted (§0.27); nothing read it | — | — |

## Still live, slated to go

| thing | status | blocker |
|---|---|---|
| **Runes, scrolls, sockets** (`MineRunes`, `MineRunesView`, `MineSocketsView`, `MineScrolls` rune items) | paying out; the Enchanter tabs Merge, Sockets and Summon. Save fields `p.runes`, `p.toolSockets`, `p.petSockets`, `p.scrolls`. | stage 3 of §0.17 waits until traits are verified in engine (OPEN P2). `boosts()` ends in `MineRunes.clampBoosts`. See [traits](traits.md). |
| **Legacy 31 charms** | PROPOSAL line 33 decided "keep the items, kill the three sources", but all their sources still fire | not built yet. See [charms](charms.md). |
| ~~**Group wheel**~~ | **Un-parked 2026-10-10** as the daily wheel (`299dd2c`, [social-quests-and-leaderboards](social-quests-and-leaderboards.md)). It is built in the lobby again. | the `MineParked/GroupWheel/` copy is a stale snapshot; do not edit it. It can be deleted once the owner says so. |

## AUDIT §5 cut lists (2026-10-04): status at `26036a0`

The owner asked to archive the unfinished and delete the useless (§0.26). **Nothing has
moved: no `archive/` folder exists, and every file below is still in `src/`.**

- **ARCHIVE:** runes, trading, group wheel, leaderboards, event pass, lucky blocks,
  potions/scrolls/credits shop. Since the audit, lucky blocks got the one fix ever
  confirmed in engine (§0.27), and PROPOSAL line 23 makes potions the coin sink. **Those
  two now contradict the archive list.**
- **DELETE** (all present and required by nothing, by a grep for `require` /
  `WaitForChild`):

| file | lines | note |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/_c.luau` | 1,710 | a stale MineConfig copy with its own `ORES` and `coinsFor`. **deleted 2026-10-08** per PROPOSAL line 38, after a launch audit found it still held the old wall-clock season functions. |
| `src/ServerScriptService/Mine/MineDepthPlazas_OLD_pre_v4.luau` | 673 | superseded by `MineDepthPlazas` |
| `src/ReplicatedStorage/Mine/Shared/MineBenchView.luau` | 366 | unmounted (Forge replaced it), yet edited on 2026-10-05 in `2700164` |
| `src/ReplicatedStorage/MineGear_AdminTest.luau` | 738 | test scaffold shipped to every client |
| `src/ReplicatedStorage/MineBags_NameCheck.luau` | 367 | same; it requires the root `MineBagNames` |
| `src/ServerStorage/CaptureToolIcons*.luau`, `_CaptureToolIcons_Reload.luau` | 401 × 3 + 353 | four copies of one Studio script |
| `src/ServerStorage/chk_824649944.luau`, `rig_545528744.luau` | 1,816 + 1,809 | scratch copies of `PetModelFactory` |

- **Not on AUDIT's list but just as dead:** `src/ReplicatedStorage/MineGear.luau` (348
  lines, the old six-slot gear; it requires a sibling `MineRunes` that does not exist at that
  level) and `src/ReplicatedStorage/MineBagNames.luau` (identical to the Shared copy).
  `src/ServerStorage/OreBalanceSim.luau` is broken (BLOCKED #13).

## Why nothing was just deleted

- **Removing a file can delete a live Studio instance.** Rojo drops the instance when
  the file goes, and Cursor edits the same tree. Commit `067c7fb` logged the EH duplicate
  instead of deleting it for that reason, calling it "the owner's call".
- **The opposite trap:** with `$ignoreUnknownInstances`, a module deleted from git
  can survive in the place file (START-HERE §3). See [rojo-and-studio](../code/rojo-and-studio.md).
- **Ids are data.** Charm ids `<ore>_charm`, trait `id`s, `lucky_charm`, the bag index,
  the stat keys above, and the `MineCards.TRAITS` order are all read back from saves.
  See [save-data-and-migrations](../code/save-data-and-migrations.md).

## Stale docs found while checking

- OPEN P2 says "delete the duplicate Event Horizon pet module". That was done in `f6bb23f`.
- OPEN P2 says "Group wheel and battle pass — both archived in MineParked". Only the wheel is
  there; the battle pass (`TCGServer/BattlePass.luau`, `MineScrolls.BATTLE_PASS`) is live.

## See also

[charms](charms.md) · [traits](traits.md) · [pets](pets.md) ·
[hats-and-faces](hats-and-faces.md) · [code-map](../code/code-map.md) ·
[luau-traps](../code/luau-traps.md)
