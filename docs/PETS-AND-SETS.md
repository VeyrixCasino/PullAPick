# Pets and pack sets: the owner's spec (2026-10-10)

The owner's latest direction. It outranks older docs on these topics.
`docs/TODO.md` ★ NOW points here.

## What to do NOW

The owner: *"Just make the pet models and give me advice about how to go
forward. Once all pets are in place I'll get you to re-evaluate rewards."*

So the current job is **pets only**:

1. **Make more pets.** "We're going to need them."
2. **Two pet layers:**
   - **Zone pots.** Divide every current pet among the 11 zones, so each zone
     draws from its own pot. A later zone's pets are better, but not
     exponentially better. Each zone's Mythic, Divine and Exotic pets get a
     **different buff set**, so a new zone never makes the last zone's pets
     useless.
   - **The 19 exclusive sets** in the table below. Each set gets its own pets.
     These sets are not tied to a zone.
3. **Rename** any pet where it helps, and **name all the new pets**.
4. **Think out each pet's abilities** properly.
5. **Add about 100 new body types.** The owner first said 20–30, then raised
   it: *"prob more like 100, but then we will be set for good"*. Today there
   are 44 species builders in
   `src/ReplicatedStorage/Mine/Shared/PetModelFactory.luau`. Most pets use four
   of them: hound, cat, critter and bird.

**Decided 2026-10-10 (the owner's answers):**
- **Every pet gets its own name.** That includes all 2,043 set cards. No
  generated "Ember Fox" names in the new sets.
- **Power steps +5%, not +12%.**
  - Each zone's pot is 5% better than the zone before it. Zone 11 ends up about
    1.63× zone 1 (1.05^10).
  - **Each set gets its own pet budget, 5% above the set before it.** Set 19
    ends up about 2.41× set 1 (1.05^18).
- **Set 17 is renamed "Eternal Roots"** (was Worldtree; owner, 2026-10-10). Its
  ★★★★ pack keeps the name "Worldtree's Crown" until the owner says otherwise.
- **Heartwood:** Mosswood ★★★★★ keeps "Heartwood". **Eternal Roots ★★ (then Worldtree) becomes
  "Sapwood"** (the owner said to rename the other one; the name is Claude's pick).
- **Universal packs go.** In the rework, no pack draws from a random set out of
  everything. *Direction only: nothing is removed yet* (the owner: "don't nuke
  them").

## Today's pets, counted (2026-10-10)

**The set system is still live.** Every pack carries a `setId`, and opening it
draws from that set.

| what | count |
|---|---|
| Hand-named pets with their own look (`MinePetRoster` 253 + `MineEHPets` 73, 4 names shared) | **322** |
| Old generated card sets (`MineCards.SETS`) | **41** |
| Card slots in them (cards + secret Exotics) | **4,023** |
| **Distinct pets** among those slots (16 prefixes × 16 animals; 16 bodies) | **207** |
| Sets no zone lists, reachable only as a random set on a granted pack | 9 sets, 837 slots |

**How a pack picks its set today:**
- **Chest packs from mining:** the zone's 3 sets by depth (`MineConfig.setForLayer`).
- **Every other pack** (shop, bundles, stardust, daily rewards, quests, wheel):
  **a random set out of all 41.** These are the "universal" packs.

**Per zone today:**

| zone | card slots | distinct pets |
|---|---|---|
| meadow | 278 | 99 |
| sunscar | 275 | 96 |
| mistreef | 279 | 133 |
| arcwork | 278 | 165 |
| bloodmoon | 279 | 147 |
| eclipse | 316 | 145 |
| riftmarch | 312 | 138 |
| starfall | 319 | 130 |
| mythral | 217 (one set is a tool id, `brutalcrusher`) | 124 |
| primordium | 333 | 111 |
| bigbang (Event Horizon) | 300 | 137 |

The same 207 names repeat in every zone, so **no zone owns a pet today.**

**If the 322 named pets are split into zone pots:** Event Horizon keeps its 73,
and the other 249 make about **25 per zone** for the 10 regular zones. Zone pots
need new pets to reach a real collection size (owner to choose; see
`wiki/open-questions.md` H9).

**Totals after the plan:**
- **Pets:** 322 existing + 2,043 set pets + new zone pets, so 2,365 or more.
- **Body types:** 44 + about 100, so about 144.

## The 19 exclusive sets (the owner's table)

Grade is the set's quality, F to SSS. The six pack columns are the set's packs,
from worst (★) to best (★★★★★). Rarities: C Common, U Uncommon, R Rare, E Epic,
L Legendary, M Mythic, D Divine, X Exotic.

| # | Set (grade) | ★ | ★½ | ★★ | ★★★ | ★★★★ | ★★★★★ |
|---|---|---|---|---|---|---|---|
| 1 | Pebblebound (F) | Stone Cache | Copper Vein | Iron Hollow | Crystal Pocket | Deepcore Deposit | Earth's Heart |
| 2 | Sugar Rush (D) | Candy Corner | Sprinkle Party | Jelly Pop | Sugar Kingdom | Royal Confectionery | Infinite Sweetness |
| 3 | Mosswood (C) | Fallen Branch | Mossy Stones | Fern Hollow | Hidden Spring | Ancient Grove | Heartwood |
| 4 | Lost & Found (C) | Forgotten Trinket | Brass Compass | Buried Cache | Hidden Chamber | Collector's Trove | Lost Civilization |
| 5 | Starfront (C) | Launch Sequence | Outer Rim | Nebula Raiders | Galactic Frontline | Stellar Armada | Cosmic Singularity |
| 6 | Arcade Legends (B) | Insert Coin | Bonus Round | Power-Up | Boss Rush | High Score | One More Life |
| 7 | Crystal Hollow (B) | Quartz Pocket | Amethyst Vein | Geode Chamber | Emerald Cavern | Prismatic Vault | Earth's Prism |
| 8 | Shogun's Oath (B) | Rusted Tanto | Steel Petals | Crimson Dojo | Blade of Honor | Shogun's Treasury | Thousand-Year Katana |
| 9 | Royal Reserve (B) | Gilded Entry | Noble Lineage | Gold Standard | Imperial Vault | Crown Jewels | Sovereign's Edition |
| 10 | Crimson Eclipse (A) | Blood Oath | Midnight Veil | Crimson Court | Eclipse Ritual | Immortal Dynasty | Blood Moon Ascendant |
| 11 | Holo Havoc (A) | Foil Frenzy | Color Shift | Mirror Match | Prismatic Chaos | Hyperholo | Infinite Spectrum |
| 12 | Rainbow Road (A) | Pastel Parade | Rainbow Starter | Prism Path | Spectrum Surge | Crystal Crossing | Celestial Rainbow |
| 13 | Infernal Reign (A) | Cinderborn | Ashen Pact | Hellbound | Demonforge | Infernal Citadel | Ninth Circle |
| 14 | Atlantis Rising (A) | Tidepool Treasures | Coral Crown | Sunken City | Leviathan's Wake | Atlantean Vault | Throne of the Deep |
| 15 | Divine Relics (A) | Forgotten Idol | Sacred Fragment | Relic of Ages | Celestial Artifact | Pantheon's Key | Origin of Divinity |
| 16 | Dragonfall (S) | Scaled Beginnings | Hatchling's Hoard | Drakefire | Wyrm's Treasury | Dragon King's Vault | World Eater |
| 17 | Eternal Roots (S) *(was Worldtree)* | Seedling | Rootbound | Sapwood *(was Heartwood)* | Verdant Awakening | Worldtree's Crown | Genesis Bloom |
| 18 | Mythic Menagerie (SS) | Tiny Terrors | Wildlings | Beastbound | Apex Predators | Mythical Beasts | Primordial Titans |
| 19 | Chaos Theory (SSS) | Minor Glitch | Broken Pattern | Fracture Point | Reality Shift | Paradox Engine | Infinite Collapse |

| # | Set | Cards | C | U | R | E | L | M | D | X | Flavour |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Pebblebound | 120 | 54 | 28 | 17 | 9 | 6 | 3 | 1 | 2 | plain starter |
| 2 | Sugar Rush | 119 | 52 | 29 | 17 | 9 | 5 | 2 | 4 | 1 | Divine-leaning |
| 3 | Mosswood | 117 | 50 | 28 | 17 | 9 | 6 | 3 | 1 | 3 | even |
| 4 | Lost & Found | 116 | 48 | 28 | 17 | 9 | 6 | 4 | 2 | 2 | Mythic-leaning |
| 5 | Starfront | 114 | 48 | 27 | 16 | 9 | 6 | 2 | 1 | 5 | Exotic-heavy |
| 6 | Arcade Legends | 113 | 46 | 27 | 17 | 9 | 6 | 3 | 3 | 2 | even |
| 7 | Crystal Hollow | 112 | 45 | 27 | 16 | 9 | 6 | 2 | 6 | 1 | Divine-heavy |
| 8 | Shogun's Oath | 110 | 44 | 26 | 16 | 9 | 6 | 4 | 2 | 3 | Mythic-leaning |
| 9 | Royal Reserve | 109 | 44 | 26 | 15 | 9 | 6 | 2 | 2 | 5 | Exotic-heavy |
| 10 | Crimson Eclipse | 108 | 43 | 25 | 16 | 9 | 6 | 3 | 5 | 1 | Divine-heavy |
| 11 | Holo Havoc | 106 | 42 | 25 | 15 | 9 | 6 | 2 | 1 | 6 | Exotic-heavy |
| 12 | Rainbow Road | 105 | 40 | 25 | 15 | 9 | 6 | 5 | 3 | 2 | Mythic-heavy |
| 13 | Infernal Reign | 103 | 40 | 24 | 15 | 9 | 6 | 3 | 4 | 2 | Divine-leaning |
| 14 | Atlantis Rising | 102 | 40 | 24 | 14 | 9 | 7 | 3 | 2 | 3 | even |
| 15 | Divine Relics | 101 | 38 | 23 | 14 | 9 | 6 | 2 | 8 | 1 | Divine-heavy |
| 16 | Dragonfall | 99 | 37 | 23 | 14 | 9 | 6 | 3 | 2 | 5 | Exotic-heavy |
| 17 | Eternal Roots | 98 | 36 | 23 | 14 | 9 | 7 | 4 | 3 | 2 | Mythic-leaning |
| 18 | Mythic Menagerie | 96 | 34 | 22 | 14 | 9 | 6 | 6 | 3 | 2 | Mythic-heavy |
| 19 | Chaos Theory | 95 | 38 | 22 | 13 | 7 | 5 | 2 | 2 | 6 | Exotic-heavy |

**Checked 2026-10-10:**
- Every row adds up to its card count.
- The sets hold **2,043 cards** in total: 819 C, 482 U, 292 R, 169 E, 114 L, 58 M, 55 D and 54 X.
- **450 of them are Epic or better.**
- **"Heartwood" was used twice:** Mosswood ★★★★★ and Worldtree (now Eternal Roots) ★★. That one becomes **"Sapwood"** (decided above).

## Facts that shape the job (code, 2026-10-10)

- **A card IS a pet** (`MineConfig.ITEM_BAG_FIELDS` comment). So 2,043 cards
  means 2,043 pets. Today, pack-minted cards are named `PREFIX .. SPECIES` from
  16 procedural species (`MineCards`). The 322 hand-named pets live in
  `MinePetRoster` plus `MineEHPets`.
- **Pet names are save data.** Owned pets are whole card tables in `p.cards`.
  Renaming a pet breaks four things unless an alias maps the old name:
  - its kit (`MinePetBoosts.boostsFor`);
  - its serial prefix (`HEX3_BY_NAME`);
  - `cardKey` strings;
  - its body (the `ANIMALS` key; an unknown key falls back to a fox).

  `NAME_ALIASES` and a load-time rename migration exist, but they only cover
  Event Horizon names. **Every rename needs an alias row.**
- **No pet has a zone today.** Named pets drop from three places: the daily
  wheel, lucky blocks and Event Horizon chests. Each zone's packs draw from 3 of
  the 41 card sets (`MineConfig.ZONES[].sets`).
- **Bug from the import:** Mythral's `sets[1]` is `"brutalcrusher"`, which is a
  tool id, so Mythral's shallow packs mint nothing.

## Legacy: do not build on it

The owner: *"XY is old asf, those drop rates of prism… is old asf, stuff like
that."* Treat these as legacy and retire them in the rework:

| what | where | why it is old |
|---|---|---|
| The X / Y named-pet sets | `MinePackConfig.SET_CARDS` X/Y | old TCG sets; not wired into minting (MineServer ~7726) |
| The X / Y kits | `MinePetBoosts.PET_BOOSTS.X`, `.Y` | the boosts behind those old sets |
| Variant odds rolled at pack open (Golden 7%, Prism 3.5%, Rainbow 1.2%, Void 0.3%) | `MinePackConfig.VARIANT_ODDS` and every pack row's `variants` | variants come from the merge ladder (`MineConfig.VARIANTS`) |

**Probably old too, but the owner should confirm before anyone deletes them:**
- the 41 current card sets (`MineCards.SETS`);
- the 55 generated zone packs (`MineZonePacks`);
- the 19 authored card packs (`Mine1PacksData`).

**Ids are data.** Retiring something means it stops dropping. Cards that players
already own keep working.

## Queued for the rewards pass (after pets, when the owner says)

- **Daily wheel:**
  - a new free spin **every 6 hours** (the owner's idea; it replaces 1 a day);
  - the world wheel's face becomes **one generated image** showing all the
    rewards, instead of parts;
  - the slices become **star-graded pack cases** ("★★★★★ Pack") instead of
    specific prizes. It must stop giving zone packs.
- **Pack cases:**
  - a case holds **3–5 packs** of a **known star grade**;
  - they are rare-ish drops from chests, so packs can be earned by mining;
  - each case says its star grade on it. **Zone packs get no stars.**
- **A stardust NPC** sells pack cases, not single packs: random packs of a
  known star grade, at about **60–70% RTP**. Packs are oversaturated, so packs
  must feel very different from each other.
- **Rework the packs:**
  - some packs are genuinely awesome and others mediocre at best;
  - rare packs are worth trading for;
  - add more packs;
  - divide the pets between packs, and let some packs draw specific cards
    ("a 'special rare' pack that picks pets from the same pot is pathetic").
  - Only **exclusive, non-zone** packs are given as rewards.
- **The TODAY checklist** (TODO A2) goes **inside the Quests panel**. Decided.

## Open, for the owner

See `wiki/open-questions.md`, the section "Help needed: pets and pack sets".
