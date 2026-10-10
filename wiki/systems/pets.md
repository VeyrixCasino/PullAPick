---
title: Pets
type: system
status: partial
verified: 2026-10-10 @ 5f74929
sources:
  - src/ReplicatedStorage/Mine/Shared/MinePetRoster.luau
  - src/ReplicatedStorage/Mine/Shared/MineSetPets.luau
  - src/ReplicatedStorage/Mine/Shared/SetPets/
  - src/ReplicatedStorage/Mine/Shared/PetBodies/
  - tools/gen/set-pets.js
  - tools/gen/sets/README.md
  - tools/verify/set-pets.js
  - docs/SET-PETS.md
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
  - tools/verify/petskins.js
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
- **Kit.** A named pet reads `MinePetBoosts.boostsFor(name)`, which answers
  from **one table**: `PET_BOOSTS.Z` = `MineZonePets.KITS`. That covers all 773
  named pets, Event Horizon included. An unnamed print falls back to
  `MineCards.getKit` (a role's primary and secondary).
  - **Deleted 2026-10-10** (owner: *"remove all old information"*):
    - the X and Y kit bags;
    - a second Event Horizon kit copy that disagreed on 69 of 73 pets;
    - Event Horizon's old budget table;
    - the X/Y card lists in `MinePackConfig`;
    - `MineStats`' X/Y kit generator (`TYPE_KITS`, `TIER_BUDGET`, `kitFor`).

    `tools/verify/zone-pets.js` fails if any of them comes back.
- **Identity: every pet also has a family and a pet trait.** `MineCards.applyIdentity`
  adds a `FAMILY` boost (8 types, for example Fire "Forge Heart" +22% damage) and a
  **pet trait** from `MineCards.TRAITS`. There are 12, hashed from (setId, index) or from the name.
  Lone Wolf pays only when that pet is your only one; Squad Bond scales with the number of *other* pets.
  This is **not** the tool trait in [traits](traits.md).

## Roster

| what | count | where |
|---|---|---|
| rows in the file | 253 (C 75 · U 34 · R 31 · E 23 · L 19 · M 18 · D 24 · X 29) | `MinePetRoster.PETS` |
| new zone pets | **457** | `MineZonePets.PETS`, merged into the roster at load |
| unique names at runtime | **779** = 243 regular + 457 zone + 73 Event Horizon + 6 holiday | after `mergeIntoRoster` and the zone merge |
| kits | **779**, one per named pet | `MinePetBoosts.PET_BOOSTS.Z` |

## Zone pots (2026-10-10)

The owner asked for 70 pets per zone (`docs/PETS-AND-SETS.md`). Each of the 10
regular zones has its own pot: Common 25, Uncommon 15, Rare 10, Epic 7,
Legendary 5, Mythic 2, Divine 3, Exotic 3. Event Horizon keeps its own 73.

- **Generated.** `tools/gen/zone-pets.js` writes
  `src/ReplicatedStorage/Mine/Shared/MineZonePets.luau` and the names sheet
  `docs/ZONE-PETS.md`. Edit the generator, not its output.
  `tools/verify/zone-pets.js` fails when either is stale.
- **Existing pets:** the 243 regular pets were dealt into zones by tier. None
  was renamed or changed tier, and none changed its look.
- **New pets:** 457 new ones on everyday bodies, never a holiday body. Each one
  has a colour at least 60 RGB apart from every other pet on the same body
  (relaxing to 30 only if it has to).
- **Kits** follow the approved ladder (PROPOSAL §0 line 3), **lifted 2026-10-10**.
  - The owner asked for *"489 at top, 300 at start"* and *"commons stay the same,
    but everything else grows in relitivity"*. So each rung is multiplied by
    (4/3)^(rank/7): Common stays 34 primary (51 a kit) and Exotic reaches 200
    (300 a kit at Meadow, 489 at Event Horizon).
  - The secondary is half the primary, ×1.05 per zone (zone 10 is ×1.55).
  - **Common to Legendary** get a role from their body: Striker, Bruiser,
    Digger, Seeker, Prospector, Tidecaller, Trader or Mystic.
  - **Mythic, Divine and Exotic** carry their zone's own three-stat buff set
    (meadow Harvest … primordium Primal). A later zone never makes an earlier
    zone's top pets useless.
  - Blast is on 25 of 700 pets, Rare or better only.
  - **Proc buff sets (2026-10-10):**
    - Mistreef Tide: Tidal Wave, Tidal Wave Damage, Pulverize;
    - Arcwork Volt: Zap, Zap Damage, Swing Rate;
    - Eclipse Shadow: Blast, Blast Damage, Earthquake;
    - Riftmarch Shatter: Shatter, Shatter Damage, Earthquake.

    Mistreef's three top Tidal Wave pets total 50.4% at Normal, within the owner's
    50–60%. No pet's proc chance tops 40% (the highest is Quasarin's Zap at 37.1%).
  - **Rare+ roles:** Tidecallers roll Tidal Wave + its damage, and Mystics roll Zap,
    Shatter or Blast with their damage.
- **Holiday pets are not in the game** (owner: *"only allow it from {Holiday}
  {year} Pack"*).
  - `MineZonePets.HOLIDAY` lists six: Spindle, Spooky and Wisp (Halloween), and
    Jolly, Tinsel and Tinseltoe (Christmas).
  - They are in no pot. The roster stamps `pet.holiday`, and
    `MineGroupWheel.rollPetOfTier` (wheel and lucky blocks) skips them.
  - They keep a zone-1 kit, so an owned copy still pays.
  - New pets never use a holiday body, so 457 new pets fill the pots, not 451.
- **Lookups.** `MinePetRoster.BY_ZONE[zone]` lists a zone's pets, and every
  regular pet has a `zone`. `MineZonePets.zoneOf(name)` and `zoneMult(zone)`
  answer the same questions.
- **Zone pots are the drop source for packs** (2026-10-10): every card pack
  that is not a set pack pays a named pet from its zone's pot, at the rarity
  the pack rolled ([cards-and-packs](cards-and-packs.md)). Set packs pay from
  their set (`MinePetRoster.BY_SET`). The wheel and lucky blocks still pick
  from any tier.

## The 19 sets (2026-10-10)

The owner's 19 exclusive sets, graded F to SSS, each sold only through its own
six packs ([cards-and-packs](cards-and-packs.md)). **2,043 named pets** on **98
new bodies**. The full names sheet is `docs/SET-PETS.md` (generated).
- **Owner:** set 1 (Pebblebound) starts at zone 1's level and each set is +5%,
  so Chaos Theory is ×2.41. Names ship now and the owner reviews the sheet after.
- **Counts are the owner's**, per set and rarity (`tools/gen/sets/_sets.json`),
  from Pebblebound's 120 down to Chaos Theory's 95.
- **Kits** follow the zone pots' rules: the pet ladder × 1.05 per set. Mythic,
  Divine and Exotic take the set's own three-stat buff set; the rest take a role
  from their body. The highest single proc chance is 53.5% (Segfault, Chaos
  Theory, Shatter), under the 60% line.
- **A proc always fits its set** (owner, 2026-10-10: *"buffs (that make
  sense)"*; chose "use the set's own proc"). A role can carry another theme's
  proc (every Mystic body zaps). Below Mythic that proc becomes the set's own
  (Dragonfall Mystics quake, Atlantis Mystics make waves). A set with no proc
  (Pebblebound, Mosswood, Lost & Found, Royal Reserve, Rainbow Road) gets its
  plain buff stats instead. Only the stat changes, never the power
  (`fitToSet` in the generator; checked by `tools/verify/set-pets.js`).
- **Theme is the predominant type** (owner: *"not every single pet in atlantis has
  to be underwater but it should DEFINATLY be the prodionent type"*). Each set's
  own themed bodies are weighted double, so they dress 71–85% of its pets; the
  2–4 `extraBodies` are existing species that also fit (Atlantis: turtle,
  dolphin, ray, fish). About 85–98% of names are plainly on theme.
- **Where it lives:**
  - `tools/gen/sets/<key>.json`: each set's names, palette, buffs and bodies
    (written by hand, following `tools/gen/sets/README.md`).
  - `PetBodies/<Set>.luau`: each set's 5 or 6 bodies, as `return function(K)`
    over `PetModelFactory.KIT`. The factory loads every module in the folder.
  - `tools/gen/set-pets.js` writes `SetPets/<Set>.luau` and `docs/SET-PETS.md`.
    `MineSetPets` gathers the modules in the owner's order; the roster, the kit
    table and the factory merge them.
- **Serials** live in their own range, 0x400–0xBFF, so a zone pet added later
  can never collide with a set pet.
- **The zone pots come first.** The set generator avoids every zone pet's name;
  the zone generator does not read the sets, so adding a set never renames a
  zone pet. (Reading them once did: it shifted the shuffled name pool.)
- **Checked by** `tools/verify/set-pets.js`: counts, unique names and looks,
  body use, no holiday bodies, kit values, buff sets, proc odds, a luau load
  of every module, and the wiring.
- **Seen in Studio:** the display builds all 2,837 pets (794 + 2,043) with no
  fallback body. Only a sample was looked at closely (Atlantis Rising); a full
  look pass per set is still to do ([next-up](../next-up.md)).

**The display.** `src/ServerStorage/PetShowcaseBuilder.luau` builds
`workspace.PetShowcase` at (3000, 0, 0): every pet on a plinth, one block per
zone, then one per set, one row per tier, A to Z.
- **Rebuild it** after any pet change, from Studio's command bar in Edit mode:
  `require(game.ServerStorage.PetShowcaseBuilder).build()`.
- **Name tags show only within 22 studs** (owner: "proximity name tags").
- **It never ships.** MineServer strips it on a live server. The old hand-built
  rack was deleted in `d57fedc`.

**Holiday bodies** carry `season = "Halloween"` or `"Christmas"` in `SPECIES`, and that tag is what
makes a body a holiday body. The zone generator and its check read the tags, so a new holiday
body is kept out of every pot without editing a list.
- **Halloween 2026 added ten:** Bat, Mummy, Zombie, Vampire, Cauldron, Candy Corn, Scarecrow,
  Haunted Lantern (`lantern`), Frankenstein and Eyeball. `PetModelFactory.HALLOWEEN` lists all
  15 Halloween bodies, and the display draws them as a block.
- **They are bodies, not pets yet.** A Halloween 2026 Pack is the only way one should ever reach
  a player. The owner's brief (60 Halloween pets, an event mine) is in [next-up](../next-up.md).
- **Penguin lost its Christmas tag** (2026-10-10). It is an everyday animal worn by 22 ordinary
  pets, and the tag would have pulled them all out of the game.
- **Mind FIT_SIZE.** It scales a model so its LARGEST dimension fits 2.5 studs, so wide wings or
  a tall handle shrink the whole pet. Bat and Lantern set `scale` (1.30, 1.18) to read the same
  size as everything else.

**Trying a pet in Studio.** `devGrant { pet = "Fizzgig" }` (Studio only) mints the
pet through `mint` and puts it in seat 1. That is how a pet's ability can be tested
in the engine; the admin commands cannot grant a pet.

- **`MinePetRoster` is hand-maintained.** Its original generator and inputs were never
  in the repo. The zone pets and every kit are generated by `tools/gen/zone-pets.js`.
  `tierVia` records how each tier was resolved: `"animal"` (52, the Divine/Exotic clash goes
  to the higher tier) or `"default"` (43; the header says 42).
- `MinePetBoosts.displayName` puts the animal on the card. `LOCKED_DISPLAY` keeps Matter+,
  Matter-, Cosmo and Albert Minestein as names. `NAME_ALIASES` maps Horizon+ to Matter+
  and similar.

## Event Horizon pets

- `MineEHPets` (its internal table is still called `MineEventHorizonPets`) has 73 pets, set ids
  `genesis_spark` / `first_light` / `proto_ore`, and mine `bigbang`. See [world-events](world-events.md).
- **Their kits sit on the ladder as zone 11** (×1.63), keeping each pet's own
  hand-authored stat mix. Before 2026-10-10 they spent `BUDGET` Common 25 … Exotic 380
  before rarity, so an Event Horizon Exotic was worth about 4.5× a top zone Exotic.
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
- **Pets wear no hats.** `ClientFns.petHatPiece` is a stub that returns nil, and `p.petHats` is gone.

### Body shape

`block()` is the shared chassis. By default it is **one ovoid with the face
painted on its front** — no head volume — which is why every species built on it
used to read as a cube with nubs.

`shape = "<profile>"` shrinks that core and fills the envelope back out with a
few rounded masses. `size` stays the envelope, because the face, legs and every
`DETAILS` prop are positioned off it. Three profiles in `SHAPES`, 33 species:

| profile | core | masses | used by |
| --- | --- | --- | --- |
| `quad` | `0.80 × 0.78 × 0.86` | brow, chest, back, cheeks, haunches | 20 four-legged |
| `bird` | `0.76 × 0.80 × 0.80` | crown, breast, back, rump, flanks | bird, duck, penguin, owl, hawk |
| `round` | `0.84³` | dome, belly, front, rear, sides | slime, toad, pumpkin, fish, dolphin, ray, crab, beetle |

Rows are **fractions of the envelope**, so a species overriding `bodySize`
keeps its shape. `ghost` is deliberately left out: it sets `body.Transparency`
and opaque masses would break it.

Two traps, both hit once:

- **Do not move the face onto a head volume.** Species hardcode face detail
  against the body — cat whiskers at `z = 1.02`, bunny teeth at `z = 1.00`, fox
  cheek ruffs at `y = -0.16`. A head strands all of them on the chest, each
  piece still correct alone. Add mass *around* the face instead.
- **The envelope must stay filled, on every face.** Details are placed on the
  envelope, so a profile that does not reach one of its faces strands whatever
  sits there. It happened twice: a cookie dog's chip at `(0.02, 1.00, -0.62)`
  when `quad` had no `back` mass, and six fish and dolphin tails when `round`
  had no rear mass. Both were found by the gap audit, not by looking. **Re-run
  it after touching a profile.**

`ridge()` makes its plates at least as deep as their spacing. Every caller
spaced them wider than they were (lizard `0.36` vs `0.24`), and the gap only
shows on the **last** plate — the earlier ones sit over the body and borrow its
mass.

### How a pet gets its look

Three tables, and a pet needs a row in the middle one or it renders as a fox:

| Table | Holds | Count |
| --- | --- | --- |
| `PetModelFactory.SPECIES` | the body builders — one blocky chassis each | 54 (10 Halloween bodies added 2026-10-10) |
| `PetModelFactory.ANIMALS` | `animal` → `{ species, tint, glow?, detail?, transparency? }` | 322 in the file + 451 from `MineZonePets.ANIMALS` |
| `PetModelFactory.DETAILS` | prop packs that name the creature (`spots`, `soda`, `discoball`) | 18 |

`build()` reads `opts.animal`, looks it up in `ANIMALS`, and resolves the body
from `skin.species`. **`resolveSpecies` ends in `return "fox"`**
(`PetModelFactory.luau:2724`), so an animal with no `ANIMALS` row gets no skin
and falls all the way through to a default fox. That is silent: nothing warns,
and the pet just looks wrong.

**Pack-generated cards have no `ANIMALS` row** (names like "Ember Fox"). Their
colour comes from `def.tint` and then `TYPE_TINT[card.typeId]`, and none of the
16 generated species sets a `def.tint`. So the colour comes from the card's
**element** (8 types reach cards through `MineCards` `THEME_TYPES`), **not from
its name**.
- Two "Ember Fox" cards can differ in colour.
- An Ember Fox and a Storm Fox of the same element look identical, apart from
  rarity effects and variants.
- That caps generated looks at 16 bodies × 8 colours = 128 (checked 2026-10-10).

`opts.tint` overrides `skin.tint`, which is what lets a probe reproduce any
skin without the roster — useful when Studio is in Play mode and Rojo will not
sync.

- **`tools/verify/petskins.js`** is the guard, and it asserts three things that
  each caught a real defect: no two animals share a `(species, tint)` pair, no
  two roster rows share an `animal`, and every roster animal has an `ANIMALS`
  row. It is idempotent and fails if an edit matches zero or twice. It also
  refuses to reassign a row whose `tierVia` is `"animal"`, since that would
  move the pet's tier.

## Decided by the owner

- §0.24 (2026-10-04): three pet seats, and the formation is centred behind you.
- §0.18 / §0.19: gear powering pets — *"get rid of this"*. Pets get no enchantment
  of their own, and pets sit in layer 2.
- **PROPOSAL §0 lines 3–8 (approved 2026-10-05):**
  - **Built for every named pet, 2026-10-10.** The ladder is Common 34 … Exotic 150.
    Blast is on 25 of 773 pets, Rare or better only. No pet carries
    `blastRadius`, `procPower`, `backpack` or `walkSpeed`.
  - **Not built: line 4, the variant stack.** That is Rainbow 1.6 / Shadow 1.25 /
    PL25 1.25, for a perfect Exotic at 375. Code today is Rainbow 5.5 and
    `SHADOW_MULT` 3.
- **+5% per zone, and each zone's Mythic/Divine/Exotic gets its own buff set**
  (owner, 2026-10-10; [zone pots](#zone-pots-2026-10-10)).
- PROPOSAL line 34: the VIP fourth seat stays retired; the seat count is three.

## Gotchas

- **Two pets sharing one animal are the same pet** — fixed 2026-10-10, now
  asserted. 41 pets across 19 groups pointed at a single `animal` (Boomer and
  Brisket were both `"Bulldog"`; Button, Cheddar, Pipsqueak and Tinker were all
  `"Mouse"`). 22 were reassigned to 22 new animals, one pet per group keeping
  the original. The factory was correct throughout — identical input, identical
  output — so the fix is roster content, not `PetModelFactory`.
  **Counting this from geometry undercounts it.** The first pass found 12
  groups, not 19, because it filed each identical group under one cause: a
  group of 12 hounds whose animals mostly differed got labelled "same tint",
  and Boomer/Brisket sharing an animal inside it never showed. `petskins.js`
  now asserts animal uniqueness on the roster directly, which is the only check
  that sees them.
- **A floating part on a pet is usually art, not a break.** Soda Cub's four
  0.14-stud cubes, Disco Duck's four neon discs and the `sprite` body's six
  motes all sit 0.1–0.4 studs off the body on purpose. Verified by building
  each body with and without its skin: `D.soda` adds 10 parts, `D.discoball`
  adds 19 including the 4 neon, and `sprite` ships its motes in the body
  itself. A connectivity audit that flags these is reporting FX, so check the
  builder before "fixing" a gap.
- **Pet blastRadius pays nothing.** `MineCards.addStat` drops anything in
  `MineStats.RUNE_ONLY` (blastRadius, reach, coolant, shortFuse), so no kit carries one
  any more (the generator bans them).
- **Pet traits and families carry retired stats.** Pack Lord and Cart Push carry backpack;
  Afterimage and Heavy Yield carry walkSpeed; Echo Strike's echo is paid as swing rate; the Earth and Water
  families carry backpack. The comment on `MineCards.TRAITS` says **its order is load-bearing**:
  reordering it gives every pet a different trait.
- The `MineGear` header comment and `MineGear.hatMeansLine` still describe hats multiplying pets.
  That was the behaviour before §0.19.

## Open questions

- Re-roll the pet traits that pay retired stats, given the list order cannot change?
- What replaces VIP's lost perk (BLOCKED #6)?

## See also

[cards-and-packs](cards-and-packs.md) · [hats-and-faces](hats-and-faces.md) ·
[boosts-and-stats](boosts-and-stats.md) · [client-and-ui](../code/client-and-ui.md)
