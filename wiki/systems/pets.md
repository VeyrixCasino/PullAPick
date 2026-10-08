---
title: Pets
type: system
status: partial
verified: 2026-10-08 @ ea255bb
sources:
  - src/ReplicatedStorage/Mine/Shared/MinePetRoster.luau
  - src/ReplicatedStorage/Mine/Shared/MinePetBoosts.luau
  - src/ReplicatedStorage/Mine/Shared/MineEHPets.luau
  - src/ReplicatedStorage/Mine/Shared/MineCards.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ReplicatedStorage/Mine/Shared/MineGear.luau
  - src/ReplicatedStorage/Mine/Shared/MineStats.luau
  - src/ReplicatedStorage/Mine/Shared/PetModelFactory.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau
  - tools/verify/pet-spring.js
  - docs/TODO.md §0.24
  - docs/TODO.md §0.19
  - docs/TODO.md §6.2
  - docs/PROPOSAL.md §0
  - docs/PROPOSAL.md §B
related: [cards-and-packs, boosts-and-stats, hats-and-faces, traits, world-events, retired-and-parked, client-and-ui]
---

# Pets

> In this game a pet is a card. You pull it from a pack, and up to three walk
> behind you. Each one adds its boost kit to **layer 2**, which multiplies
> everything in layer 1 (TODO §0.19). The owner treats pets as support for the
> real build, which is charms and skins (§0.13).

## How it works

- **Seats.** You own cards in `p.cards`, and the ones out are `p.equipped`. `MineConfig.MAX_PET_SLOTS` =
  `STARTER_PET_SLOTS` = 3, and `MineConfig.effectivePetSlots` clamps to 3..3. A save that
  bought up to eight seats is clamped on load and keeps every pet. `PET_SLOT_PRICE`
  `{0,0,0}` survives only so old rows still resolve. VIP's fourth seat is gone.
- **Boost path.** `Dig.petRows` runs `MineCards.applyKit(one, card, cardPower(card), n)`
  for each pet, where `n` is the number of pets out. It keeps only what the pet adds, then multiplies that by
  `1 + MineRunes.wearBroad(its rune)`. `MineGear.stackPets` sums the pets and
  `Dig.layer2` adds the gear, giving layer 2. Gear no longer multiplies per pet (§0.19).
- **Power.** `MineConfig.cardPower` = `RARITY_MULT` (Common 1 … Exotic 4.4) ×
  `VARIANT_MULT` (Normal 1, Shiny 1.5, Golden 2.25, Prism 3.5, Rainbow 5.5) ×
  (`SHADOW_MULT` 3, or `SHINY_MULT` 1.5) × (1 + 0.04 × (powerLevel − 1)).
- **Kit.** A named pet reads `MinePetBoosts.boostsFor(name, setKey)` from
  `PET_BOOSTS.X`, `.Y` or `.EH`. Chest cards roll set X or Y 50/50
  (`MinePackConfig.SET_SPLIT`), so one name can carry two different kits; 109 names are in
  both sets. An unnamed print falls back to `MineCards.getKit` (a role's primary and secondary).
- **Identity: every pet also has a family and a pet trait.** `MineCards.applyIdentity`
  adds a `FAMILY` boost (8 types, for example Fire "Forge Heart" +22% damage) and a
  **pet trait** from `MineCards.TRAITS`. There are 12, hashed from (setId, index) or from the name.
  Lone Wolf pays only when that pet is your only one; Squad Bond scales with the number of *other* pets.
  This is **not** the tool trait in [traits](traits.md).

## Roster

| what | count | where |
|---|---|---|
| rows in the file | 253 (C 75 · U 34 · R 31 · E 23 · L 19 · M 18 · D 24 · X 29) | `MinePetRoster.PETS` |
| unique names at runtime | **322**, after `MineEHPets.mergeIntoRoster` | matches "322 named pets" in `MineCards.applyIdentity` |
| boost-kit rows | **431** = X 179 + Y 179 + EH 73 | `MinePetBoosts.PET_BOOSTS` |

- `MinePetRoster` says it is generated from `roster/pets.txt` + `roster/tiers.txt`, and
  `MinePetBoosts` says `_gen_all_pet_boosts.js`. **Neither input nor generator is in the repo.**
  `tierVia` records how each tier was resolved: `"animal"` (52, the Divine/Exotic clash goes
  to the higher tier) or `"default"` (43; the header says 42).
- `MinePetBoosts.displayName` puts the animal on the card. `LOCKED_DISPLAY` keeps Matter+,
  Matter-, Cosmo and Albert Minestein as names. `NAME_ALIASES` maps Horizon+ to Matter+
  and similar.

## Event Horizon pets

- `MineEHPets` (its internal table is still called `MineEventHorizonPets`) has 73 pets, set ids
  `genesis_spark` / `first_light` / `proto_ore`, mine `bigbang`, and `BUDGET` Common 25
  … Exotic 380. See [world-events](world-events.md).
- Every consumer does `FindFirstChild("MineEHPets") or FindFirstChild("MineEventHorizonPets")`
  (MinePetRoster twice, MinePackConfig once). The byte-identical long-name file was **deleted**
  in `f6bb23f` (2026-09-29). OPEN P2 still says to delete it, which is stale. A copy may linger in
  the Studio place because of `$ignoreUnknownInstances` (unverified).
- `MinePetRoster` also calls `eh.applyToPetRoster`, which `MineEHPets` does not define, so the call does nothing.

## Models and the follow

- `PetModelFactory` builds a procedural model per card (`fromCard`, `build`,
  `buildFromRoster`) plus variant and rarity FX. It has not changed since import (`566eecf`).
  `src/ServerStorage/chk_824649944.luau` and `rig_545528744.luau` are scratch copies
  that AUDIT puts on the DELETE list.
- **Formation** (`ClientFns.stepPetFollow`, §0.24 fix): the centre is `(n+1)/2`, lateral offset
  `(slot − centre) × 2.15`, and back offset `3.15 + |slot − centre| × 0.18`. One pet sits directly behind you.
- **Spring** (`PF` table plus `PF.spring` in MineClient, commit `26036a0`, 2026-10-05). It is
  a closed-form damped spring: `SPRING_HZ` 3.6, plus up to `SPRING_HZ_CATCHUP` 2.6 when the pet is behind,
  and `SPRING_ZETA` 0.86. dt is clamped to 0.1, and the pet snaps when `dist > 22`. It replaced explicit
  Euler, which diverged at 30 fps and below (owner: pets *"kinda just fly around the screen
  like crazy"*). `tools/verify/pet-spring.js` sweeps both integrators across framerates.
- **Bob rate** (`39d94bf`; owner: pets were *"bobing up and down super fucking
  fast"*). The bob was aliasing, not just fast: 1.9 to 4.1 Hz, and the larger dt
  clamp let one frame advance the phase past half a cycle. It is now 0.55 Hz at
  rest to 1.65 Hz walking, and no frame may advance the cosmetic wave more than
  a quarter cycle. Position still tracks real time. Measured live: 0.50 bobs per
  second at rest.
- **Pets wear no hats.** `ClientFns.petHatPiece` is a stub that returns nil, and `p.petHats` is gone.

## Decided by the owner

- §0.24 (2026-10-04): three pet seats, and the formation is centred behind you.
- §0.18 / §0.19: gear powering pets — *"get rid of this"*. Pets get no enchantment
  of their own, and pets sit in layer 2.
- **PROPOSAL §0 lines 3–8 are approved and not implemented.** They set the pet ladder at
  Common 34 … Exotic 150 with a perfect Exotic at 375, and the variant stack at Rainbow 1.6 /
  Shadow 1.25 / PL25 1.25. blastChance goes on at most 15% of pets, blastRadius stays on 26
  with a cap of 30, procPower never appears on a pet, and 182 `backpack` and 11 `walkSpeed`
  lines get re-rolled. Code today: Rainbow 5.5, `SHADOW_MULT` 3, and the kits still have
  140 blastChance, 26 blastRadius, 182 backpack and 11 walkSpeed lines.
- PROPOSAL line 34: the VIP fourth seat stays retired; the seat count is three.

## Gotchas

- **Pet blastRadius pays nothing.** `MineCards.addStat` drops anything in
  `MineStats.RUNE_ONLY` (blastRadius, reach, coolant, shortFuse). So the 26 pets' radius
  lines are zeroed before layer 2, and PROPOSAL lines 5–6 tune a dead line.
  Found by reading the code; not checked in engine.
- **Pet traits and families carry retired stats.** Pack Lord and Cart Push carry backpack;
  Afterimage and Heavy Yield carry walkSpeed; Echo Strike's echo is paid as swing rate; the Earth and Water
  families carry backpack. The comment on `MineCards.TRAITS` says **its order is load-bearing**:
  reordering it gives every pet a different trait.
- The `MineGear` header comment and `MineGear.hatMeansLine` still describe hats multiplying pets.
  That was the behaviour before §0.19.

## Open questions

- Where are the pet generator and its inputs? PROPOSAL step 2 needs them, after
  `MineStats.TYPE_KITS` is regenerated.
- Re-roll the pet traits that pay retired stats, given the list order cannot change?
- What replaces VIP's lost perk (BLOCKED #6)?

## See also

[cards-and-packs](cards-and-packs.md) · [hats-and-faces](hats-and-faces.md) ·
[boosts-and-stats](boosts-and-stats.md) · [client-and-ui](../code/client-and-ui.md)
