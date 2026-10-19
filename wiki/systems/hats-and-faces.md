---
title: Hats and faces (gear)
type: system
status: partial
verified: 2026-10-12 @ 4e4fbb3
sources:
  - src/ReplicatedStorage/Mine/Shared/MineGear.luau
  - src/ReplicatedStorage/Mine/Shared/MineHats.luau
  - src/ReplicatedStorage/Mine/Shared/MineLootPacks.luau
  - src/ReplicatedStorage/Mine/NewGear/Catalog.luau
  - src/ReplicatedStorage/Mine/Shared/MineInventoryView.luau
  - tools/verify/cards-tab.js
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - docs/TODO.md §0.19
  - docs/TODO.md §0.24
  - docs/TODO.md §6.2
  - docs/PROPOSAL.md §0
  - docs/PROPOSAL.md §A
  - docs/AUDIT.md §4
related: [traits, pets, boosts-and-stats, rebirth-and-skill-tree, chests-and-lucky-blocks, shops-and-monetisation, retired-and-parked]
---

# Hats and faces (gear)

> In code, "gear" now means **three hat seats and one face**, all worn by the player.
> Each piece is a real Roblox catalog item with a letter grade F–SSS and one to four
> stat lines. All of it is summed once, flat, into **layer 2** (TODO §0.19). You buy hats
> with rebirth tokens. In the owner's two-layer rule this is the "equipment".

## How it works

- **Seats.** `MineGear.HAT_SLOTS` = `{ hat, hat2, hat3 }` plus `face`, saved in
  `p.equippedGear`; owned pieces live in `p.gear`. The old slots in `MineGear.LEGACY_SLOTS`
  (head, amulet, chestplate, leggings, boots, gloves) fold into `hat` on load
  (`MineGear.migrateSlot`).
- **Value by grade** (`MineGear.SHEET`, total %): hat F 30 · D 50 · C 70 · B 100 ·
  A 140 · S 200 · SS 260 · SSS 350. A face is exactly half (15 → 175).
- **Lines.** `MineGear.applyTownSkills` splits a piece's total into lines. Grades F–C get a
  universal line (dirtBreak or mineSpeed, 44%), the set stat (32–36%), and one or two
  extras from swingRate / backpack / coinBonus / luck. Grades B and up get the set stat
  (62–82%) plus one universal line.
- **Combining hats: three of a kind** (owner, 2026-10-10: *"make sure only 3 ... of
  the SAME HAT can merge for a ... tier up (up to a)"*). Three of the same hat
  (same catalog hat, else set) at the same grade fuse into one of exactly the next
  grade, capped at A (`MineToolGrades.FUSE_CAP`). It is the only way hats
  combine: the two-hat multi-stat merge (`mergeHats`) is retired, and multi-stat
  hats already made keep their stats but cannot fuse. Faces still fuse in pairs.
  Rules: `MineGear.canFuse` / `FUSE_NEED` / `upgradePairs`; verb
  `Verbs.upgradeGear` (`{ ids }`); the hat panel's Upgrade list. Checked in
  Studio with made-up pieces.
- **Sets** (`MineGear.SETS`, 10). Each hat's catalog row picks its set: inferno = blastRadius,
  glacier = swingRate, **tide = Tidal Wave + Tidal Wave Damage**, **canopy = blastChance +
  Blast Damage**, bedrock = dirtBreak, foundry = coinBonus, **storm = zap + Zap Damage**,
  **prism = Shatter + Shatter Damage**, umbra = luck, void = gemFind.
- **The procs on hats** (owner, 2026-10-10: *"add all these new ones to hats"*):
  - **`stat2` rides along.** A proc set's second stat (its damage) is on every
    piece of the set, at `STAT2_SHARE` 0.5 of the chance line.
  - **`was` re-themes owned hats.** Tide's old Backpack and Prism's old Rare Ore
    lines now read as the set's new stat.
  - **`MineGear.PRICED_BY_WEIGHT`:** proc chance and proc damage lines are
    divided by their MineStats weight when read. An SSS Tide hat is +26–35% Tidal
    Wave, not +350%. An SSS Storm hat's Zap went from about +259% to +34%.
    Hats already owned are repriced too, because `boostLines` applies this.
- **Paid out in layer 2.** `Dig.layer2` adds `MineGear.flatBoost(MineGear.wornHats(eq,
  pieces), face)` once. The per-pet multiplication is gone (§0.19). Until 2026-10-12
  each piece also had one rune socket, paid after the layers by `applyEquipped`.
  Runes were retired then, and that function was removed with them
  ([traits](traits.md)). Load empties every piece's `sockets`; old pieces keep an
  empty table that nothing reads. `SOCKETS_PER_PIECE` and `SHEET.slots` are
  leftovers from sockets.
- **Getting one:**
  - **Hat crate** (`gear_pack`) from the Enchanter's Summon tab: `Verbs.rollGearBanner`,
    `MineGear.ROLL_TOKEN_COST` 5 tokens from `p.temperTokens`, and your first draw is free
    (`p.freeGearUsed`). Tokens come from rebirth (`MineSkillData.rebirthTokens`) and from some loot.
  - **Chests:** the `CHEST_LOOT` `hat` row (weight 9, about 90 per 1,000 chests) calls
    `MineGear.rollPiece(id, rng, "head")`. The slot is forced, so a chest never pays a face.
  - **The roll:** grade comes from the skins ladder (`MineGear.rollRarity` reads
    `MineTemper.RARITY_WEIGHTS`; SSS is 1 in 5,000). Slot comes from `SLOT_ODDS` hat 78 /
    face 22 unless forced. Faces snap to a grade that actually has one
    (`MineHats.nearestFaceGrade`).
- **On your avatar.** `applyPlayerCosmetics` (MineServer) applies the face through
  HumanoidDescription and wears `hat` and `hat2` through InsertService.

## Catalogs

| table | contents | used for |
|---|---|---|
| `MineHats.LIST` | 116 droppable hats (F 17 · D 14 · C 14 · B 15 · A 12 · S 10 · SS 15 · SSS 19), each with a catalogId, RAP and set | drops, and the Collection → Hats browser |
| `MineHats.LEFTOVERS` | 54 rows. Only the 23 `kind = "Face"` rows are droppable (D 5 · C 3 · B 1 · A 4 · S 9 · SSS 1). Neck and Back rows are coded but have no slot. | face drops, and the Collection → Faces browser |
| `src/ReplicatedStorage/Mine/NewGear/` | **Prototype.** 180 hats and 120 faces, Roblox limiteds ranked by Rolimons RAP, with `Icon.rbxm` folders per grade. Its header says: "Not wired to drops, rolls, or equipped stats." | only `NG.icon` thumbnails in `MineInventoryView` |

**The collection lists what can drop** (owner, 2026-10-19, launch audit S37). Inventory →
Collection → Hats/Faces showed the 300 NewGear limiteds: 67 of them drop, and 72 of the 139
hats and faces that do drop were missing. It reads `MineHats.dropCatalog(kind, grade)` now:
the `DROP_BY_GRADE` and `FACE_BY_GRADE` pools that `MineGear.catalogFor` rolls from, best
grade first, with a grade chip only for grades that have something. Checked by
`tools/verify/cards-tab.js`.

## Decided by the owner

- §0.24 (2026-10-04): three hat seats. The fourth was already gone.
- TODO §6.2: hats are player-only, so `p.petHats`, `Verbs.equipPetHat` and the pet-hat column
  are deleted; hats cost rebirth tokens.
- §0.19: *"Gear powers pets. Should just be a boost."* Equipment sits in layer 2, flat,
  counted once. This overrode §0.17/§0.18's "delete gear".
- **PROPOSAL §0 lines 1–2, approved and NOT in code:** hat ladder 16 20 25 32 40 51 64 **80**, face
  20 25 32 40 50 63 79 **100**. Faces become bigger than hats, and the SSS hat is a 4.4× nerf
  (§A). `MineGear.SHEET` still reads 30…350 and 15…175.
- **PROPOSAL line 29** (tide → reach, prism → oreLuck, umbra → packLuck, canopy → chestLuck)
  is **superseded for tide, prism and canopy** by the 2026-10-10 proc sets above. Umbra →
  packLuck is still approved and not built.

## State right now

- Live and paying, and never run in the engine (START-HERE §5).
- OPEN §10 / TODO §6.2 still list "add hats and faces as chest drops" as open. Hats already
  drop from chests (see above); faces do not.
- OPEN P0 #5 "hat crates must not increase on rebirth" is still open. Not checked here.

## Gotchas

- **The tutorial hands out three SSS hats.** At step 29 (`Intro.steps[29]`) the three
  rigged crates are re-minted at the best grade that has a catalog row, which is SSS. At
  today's `SHEET` that is +350% each, +1050% in layer 2 for a new player. The step's text
  ("the best hats for the pets you have out") is also stale. Found by reading the code.
- **Only two of the three hats show on your avatar.** `applyPlayerCosmetics` never wears `hat3`,
  although `hat3` still pays its stats.
- **Stale text from before §0.19:** the `MineGear` header, `SLOT_BLURB.hat` ("added to every
  pet") and the unused `MineGear.hatMeansLine` all describe hats multiplying pets. The
  `MineHats` header says faces are "OFF the drop table"; they drop now.
- **Town kits still roll `backpack`** as an extra (`TOWN_MATCH`), which is a retired stat. The
  tide set itself no longer does (2026-10-10).
- **`p.temperTokens` is named after temperaments** (skins) but also pays for hats. The two now share one wallet on purpose.
- AUDIT §4 scores gear "pure degree": one stat, bigger at a higher grade. That fails the
  differ-in-kind test.
- **"Gear" means three different things.** This system. `MineAntiGear`, which blocks Roblox
  catalog Gear *tools*. And `MineGearIcons`, icons for the retired six-slot pieces.
- **Two dead copies at the ReplicatedStorage root** (`MineGear.luau`, the old six-slot
  version, and `MineGear_AdminTest.luau`, the hats-on-pets version) were **deleted 2026-10-19** (owner: "Small cleanup").
  Nothing required either. See [retired-and-parked](retired-and-parked.md).

## Open questions

- Is NewGear meant to replace `MineHats` as the drop catalog? Nothing says so.
- ~~When stage 3 retires runes, what happens to the rune sitting in each gear piece's socket?~~
  **Answered 2026-10-12:** it is dropped on load, with no refund (owner: *"no one
  has played.. ur good"*).
- Should faces drop from chests?

## See also

[pets](pets.md) · [traits](traits.md) · [boosts-and-stats](boosts-and-stats.md) ·
[rebirth-and-skill-tree](rebirth-and-skill-tree.md) ·
[chests-and-lucky-blocks](chests-and-lucky-blocks.md)
