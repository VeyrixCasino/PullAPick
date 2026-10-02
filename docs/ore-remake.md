# Ore roster

> ## STALE — the roster is 82 ores, not 121
>
> **82 ores is final** (Event Horizon ores may be added later). The 121-row
> table below was generated from `MineConfig.ORES`, which has NOT caught up
> with the live game.
>
> The authority is `game.ReplicatedStorage.Mine.ToolBakers.OreToolBaker`, which
> houses every ore actually in the game and is **not committed to this repo**.
> Sync it back, diff it against `MineConfig.ORES`, cut `MineConfig` down to the
> real 82, then regenerate this file.
>
> Until that happens, treat every ore count, tier number and rarity band in this
> file as wrong. The band ladder below (Common 1-24 ... Exotic 119-121) is
> scaled to 121 and needs rebuilding for 82.

**Status of the tables below: applied to `MineConfig`, but `MineConfig` is stale.**

**Original note.** The 121-ore roster below is generated from
`MineConfig.ORES` in `src/ReplicatedStorage/Mine/Shared/MineConfig.luau`,
which is the source of truth. Landed across `deb8f35` (roster + save
migration) and `72b81ed` (14 renames, migration regenerated).

Regenerate this section after any roster change:

```
node tools/gen-ores.js          # roster helpers
node tools/rename-ores.js       # renames + migration
node tools/add-ore-migration.js # id -> id aliases
```

> The Space set at the bottom of this file is **not** applied. It is still
> queued content; see `docs/TODO.md`.

## Rules

- Rank by what the ore actually is (real rarity, value, how prized it is), adjusted for player expectations. Not by material type.
- Mix types in every band. Ore minerals sit next to their metal.
- Gold, Silver, Diamond: earned, but not endgame.
- Nuclear stays at the peak, order unchanged.
- No variants, alloys, man-made or lab-made materials.
- 121 ores total, so the tier-to-depth math in `MineConfig` is unchanged.

Bands use the game's full rarity ladder, Exotic on top:
Common 1-24, Uncommon 25-48, Rare 49-72, Epic 73-96, Legendary 97-108, Mythic 109-114, Divine 115-118, Exotic 119-121.

## The roster

**Removed.** This section held a generated 121-row table. The roster is **82
ores**, so that table was wrong in its count, its tier numbers and its rarity
bands, and a wrong roster here is worse than none.

The live list is `ReplicatedStorage.Mine.ToolBakers.OreToolBaker`. Sync it back,
cut `MineConfig.ORES` down to it, then regenerate this section from
`MineConfig` as before.

Roster size is `MineConfig.ORE_COUNT` (82). Rarity bands derive from it as
fractions via `MineConfig.oreGrade(tier)`, so they rescale with the roster
instead of being pinned to tier numbers:

| band | tiers at 82 |
| --- | --- |
| Common | 1-16 |
| Uncommon | 17-33 |
| Rare | 34-49 |
| Epic | 50-65 |
| Legendary | 66-73 |
| Mythic | 74-77 |
| Divine | 78-80 |
| Exotic | 81-82 |

## Appearance reference (generator LOOKS format)

The roster above is the order of record. This block is kept because it is the
only written source for each ore's **glow colour and intensity** — `MineConfig.ORES`
rows carry `color` / `material` / `met` / `rough` but no `glow` key. The tool
generator LOOKS table reads from here.

Format: `name: ((r,g,b), met, rough, (glow r,g,b,intensity) or None, material, note)`

```python
    # ── COMMON (1-24) ──
    "Stone"           : ((131, 131, 131), 0.0, 0.9, None, "Rock", ""),                                   # 1
    "Cobblestone"     : ((105, 107, 113), 0.0, 0.95, None, "Cobblestone", "Chunky cobble pattern"),      # 2
    "Clay"            : ((184, 93, 48), 0.0, 0.95, None, "Mud", "Clay-pot grenade"),                    # 3
    "Sandstone"       : ((231, 182, 102), 0.0, 0.95, None, "Sandstone", "Layered bands"),                # 4
    "Limestone"       : ((240, 229, 191), 0.0, 0.9, None, "Limestone", ""),                              # 5
    "Pumice"          : ((200, 195, 185), 0.0, 1.0, None, "Concrete", "Porous, light gray"),             # 6  NEW
    "Rock Salt"       : ((255, 196, 196), 0.0, 0.4, None, "Salt", "Pale pink salt cubes"),                   # 7 NEW
    "Coal"            : ((40, 40, 46), 0.0, 0.7, None, "Slate", "Plain black coal"),                         # 8 NEW
    "Flint"           : ((138, 119, 100), 0.0, 0.35, None, "Slate", "Glossy chipped faces"),                # 9
    "Chert"           : ((178, 110, 61), 0.0, 0.5, None, "Limestone", ""),                               # 10
    "Basalt"          : ((55, 57, 70), 0.0, 0.85, None, "Basalt", ""),                                   # 11
    "Slate"           : ((41, 81, 138), 0.0, 0.6, None, "Slate", "Blue-gray"),                           # 12
    "Bone"            : ((243, 211, 140), 0.0, 0.7, None, "Plaster", ""),                                # 13
    "Granite"         : ((189, 131, 128), 0.0, 0.5, None, "Granite", "Speckled"),                        # 14
    "Copper"          : ((205, 87, 5), 1.0, 0.3, None, "Metal", ""),                                   # 15
    "Diorite"         : ((215, 215, 215), 0.0, 0.6, None, "Pebble", "Black/white speckle"),              # 16
    "Tin"             : ((210, 212, 218), 1.0, 0.45, None, "CorrodedMetal", ""),                         # 17
    "Cassiterite"     : ((138, 52, 0), 0.6, 0.2, None, "Slate", ""),                                    # 18
    "Emberstone"      : ((80, 32, 18), 0.0, 0.8, (255, 100, 20, 0.5), "CrackedLava", "Dark rock, ember cracks"), # 19 NEW
    "Sulfur"          : ((254, 226, 0), 0.0, 0.6, None, "Sand", "Bright yellow crust"),                 # 20 NEW
    "Lead"            : ((71, 91, 138), 1.0, 0.6, None, "CorrodedMetal", "Dull blue-gray"),              # 21
    "Galena"          : ((147, 159, 181), 1.0, 0.08, None, "DiamondPlate", "Cubic mirror"),              # 22
    "Zinc"            : ((137, 178, 211), 1.0, 0.5, None, "Foil", ""),                                   # 23
    "Aluminum"        : ((200, 210, 225), 1.0, 0.35, None, "Metal", "Light matte silver"),                   # 24 NEW

    # ── UNCOMMON (25-48) ──
    "Iron"            : ((166, 166, 172), 1.0, 0.5, None, "Metal", ""),                                  # 25
    "Hematite"        : ((63, 63, 76), 1.0, 0.08, None, "Metal", "Silver-black mirror"),                 # 26
    "Graphite"        : ((102, 113, 138), 0.5, 0.35, None, "Metal", "Pencil-lead sheen"),                   # 27
    "Pyrite"          : ((227, 206, 75), 1.0, 0.15, None, "DiamondPlate", "Fool's gold, sparks"),       # 28
    "Quartzite"       : ((255, 172, 192), 0.0, 0.45, None, "Salt", "Pale pink"),                         # 29
    "Selenite"        : ((255, 255, 245), 0.0, 0.2, (255, 255, 240, 0.2), "Glass", "Milky satin glow"),  # 30 NEW
    "Chalcopyrite"    : ((231, 178, 1), 1.0, 0.2, None, "Foil", "Brassy"),                              # 31
    "Marble"          : ((254, 252, 246), 0.0, 0.25, None, "Marble", "Gray veins"),                      # 32
    "Pearl"           : ((252, 245, 236), 0.2, 0.15, None, "SmoothPlastic", "Soft iridescent white"),        # 33 NEW
    "Frost Crystal"   : ((140, 225, 255), 0.0, 0.05, (170, 235, 255, 0.4), "Ice", "Icy blue shards"),        # 34 NEW
    "Quartz"          : ((249, 249, 255), 0.0, 0.05, None, "Glass", "Clear"),                            # 35
    "Agate"           : ((205, 86, 26), 0.0, 0.15, None, "Marble", "Banded"),                           # 36
    "Jasper"          : ((184, 14, 0), 0.0, 0.3, None, "Rock", "Opaque red-brown"),                     # 37
    "Amber"           : ((255, 152, 0), 0.0, 0.12, None, "Glass", "Warm, glassy"),                      # 38
    "Petrified Wood"  : ((151, 79, 45), 0.0, 0.4, None, "Wood", "Polished wood grain"),                  # 39
    "Nickel"          : ((227, 195, 131), 1.0, 0.3, None, "Foil", "Champagne silver"),                   # 40
    "Magnetite"       : ((31, 31, 44), 0.9, 0.4, (67, 136, 255, 0.5), "Basalt", "Magnetic arcs"),       # 41
    "Manganese"       : ((205, 97, 159), 1.0, 0.5, None, "Metal", "Pinkish gray"),                      # 42
    "Malachite"       : ((0, 151, 76), 0.0, 0.2, None, "Marble", "Green bands"),                        # 43
    "Azurite"         : ((0, 92, 229), 0.0, 0.1, None, "Marble", ""),                                   # 44
    "Cinnabar"        : ((194, 0, 6), 0.0, 0.35, None, "Slate", "Blood red, mercury ore"),             # 45 NEW
    "Fluorite"        : ((139, 69, 255), 0.0, 0.08, (149, 93, 255, 0.4), "Glass", "Lavender, fluoresces"), # 46
    "Chromite"        : ((60, 31, 31), 0.6, 0.35, None, "Rock", ""),                                     # 47
    "Onyx"            : ((15, 15, 15), 0.0, 0.04, None, "Marble", "Black gloss"),                        # 48

    # ── RARE (49-72) ──
    "Kimberlite"      : ((83, 138, 113), 0.0, 0.8, None, "Pebble", "Diamond specks"),                      # 49
    "Bloodstone"      : ((20, 95, 50), 0.0, 0.3, None, "Marble", "Dark green, red flecks"),                  # 50 NEW
    "Garnet"          : ((151, 0, 15), 0.0, 0.07, None, "Glass", "Deep red"),                           # 51
    "Citrine"         : ((255, 212, 0), 0.0, 0.07, None, "Glass", ""),                                  # 52
    "Chromium"        : ((171, 201, 255), 1.0, 0.04, None, "Metal", "Mirror chrome"),                    # 53
    "Turquoise"       : ((11, 216, 201), 0.0, 0.4, None, "Marble", "Opaque, dark veins"),                # 54
    "Rhodochrosite"   : ((243, 48, 93), 0.0, 0.25, None, "Marble", "Pink banded"),                      # 55 NEW
    "Bismuth"         : ((188, 156, 238), 1.0, 0.1, None, "Foil", "Rainbow stair-step crystals"),        # 56 NEW
    "Silver"          : ((250, 248, 242), 1.0, 0.12, None, "Metal", ""),                                 # 57
    "Amethyst"        : ((112, 8, 186), 0.0, 0.07, None, "Glass", ""),                                  # 58
    "Apatite"         : ((0, 216, 173), 0.0, 0.1, None, "Glass", "Teal-green"),                          # 59
    "Moissanite"      : ((34, 72, 61), 0.4, 0.14, None, "Foil", "Dark teal, iridescent"),                # 60 was Silicon Carbide
    "Tiger's Eye"     : ((189, 112, 0), 0.3, 0.2, None, "Marble", "Gold silky bands"),                  # 61 NEW
    "Lapis Lazuli"    : ((0, 39, 184), 0.0, 0.3, None, "Marble", "Deep blue, gold flecks"),             # 62 NEW
    "Geode"           : ((150, 80, 240), 0.0, 0.2, None, "Glass", "Rough shell, purple crystal inside"),     # 63 NEW
    "Topaz"           : ((255, 113, 57), 0.0, 0.05, None, "Glass", "Pink-orange"),                      # 64
    "Phosphorus"      : ((255, 252, 175), 0.0, 0.4, (80, 255, 108, 0.7), "SmoothPlastic", "Waxy pale yellow, eerie green glow"), # 65
    "Peridot"         : ((176, 229, 0), 0.0, 0.07, None, "Glass", "Lime"),                              # 66
    "Jade"            : ((58, 194, 104), 0.0, 0.35, None, "Marble", "Waxy"),                             # 67
    "Phoenix Stone"   : ((255, 90, 0), 0.3, 0.1, (255, 140, 30, 1.0), "Glass", "Fire orange, flickering"),   # 68 NEW
    "Tungsten"        : ((113, 118, 138), 1.0, 0.35, None, "Metal", "Heavy gray"),                         # 69
    "Lithium"         : ((215, 222, 235), 1.0, 0.3, (255, 60, 80, 0.2), "Metal", "Soft silver, red flame flicker"), # 70 NEW
    "Titanium"        : ((103, 58, 216), 1.0, 0.32, None, "Metal", "Anodized purple"),                   # 71
    "Obsidian"        : ((26, 9, 48), 0.0, 0.06, None, "Glass", "Glassy, faint purple"),                # 72

    # ── EPIC (73-96) ──
    "Electrum"        : ((251, 220, 98), 1.0, 0.2, None, "Metal", "Pale gold"),                         # 73
    "Cobalt"          : ((0, 73, 248), 1.0, 0.28, None, "Metal", "Cobalt-blue tint"),                  # 74
    "Labradorite"     : ((71, 104, 138), 0.2, 0.15, (15, 152, 255, 0.4), "Glass", "Blue-green flash"),     # 75 NEW
    "Zirconium"       : ((31, 31, 44), 0.8, 0.18, (255, 255, 210, 0.3), "Metal", "Black zirconium, white flash"), # 76
    "Beryllium"       : ((97, 243, 151), 1.0, 0.3, None, "Metal", "Mint metal"),                        # 77
    "Niobium"         : ((0, 162, 221), 1.0, 0.22, None, "Metal", "Anodized cyan"),                     # 78
    "Gold"            : ((255, 186, 0), 1.0, 0.15, None, "Metal", ""),                                  # 79
    "Fulgurite"       : ((227, 189, 117), 0.0, 0.4, (158, 203, 255, 0.3), "Glass", "Lightning glass"),   # 80
    "Tektite"         : ((68, 51, 1), 0.0, 0.15, None, "Glass", "Dark glass"),                          # 81
    "Moldavite"       : ((42, 138, 10), 0.0, 0.1, (52, 216, 23, 0.4), "Glass", "Forest-green glass"),    # 82
    "Moon Rock"       : ((175, 175, 188), 0.0, 0.8, None, "Pebble", "Pale gray, cratered"),                  # 83 NEW
    "Sunstone"        : ((255, 97, 0), 0.3, 0.1, (255, 112, 0, 0.9), "Foil", "Glitter flecks"),       # 84
    "Spinel"          : ((255, 0, 131), 0.0, 0.03, None, "Glass", "Hot pink"),                          # 85
    "Emerald"         : ((0, 173, 86), 0.0, 0.05, None, "Glass", ""),                                    # 86
    "Tourmaline"      : ((0, 240, 251), 0.0, 0.05, None, "Glass", "Neon blue-green"),                    # 87
    "Zircon"          : ((0, 154, 255), 0.0, 0.02, None, "Glass", "Vivid sky blue"),                    # 88
    "Moonstone"       : ((132, 168, 255), 0.0, 0.1, (132, 175, 255, 0.5), "Glass", "Blue sheen"),        # 89
    "Alexandrite"     : ((0, 151, 140), 0.0, 0.04, None, "Glass", "Teal, shift to purple if animated"),  # 90
    "Sapphire"        : ((0, 79, 201), 0.0, 0.03, None, "Glass", ""),                                   # 91
    "Ruby"            : ((242, 0, 91), 0.0, 0.03, (255, 0, 68, 0.6), "Glass", "Laser red"),            # 92
    "Palladium"       : ((118, 164, 255), 1.0, 0.18, None, "Metal", "Cool blue silver"),                 # 93
    "Aquamarine"      : ((123, 224, 251), 0.0, 0.05, None, "Ice", "Pale sea blue"),                      # 94
    "Tanzanite"       : ((38, 9, 216), 0.0, 0.04, None, "Glass", "Blue-violet"),                        # 95
    "Opal"            : ((240, 240, 255), 0.0, 0.1, None, "ForceField", "Rainbow pattern"),              # 96

    # ── LEGENDARY (97-108) ──
    "Platinum"        : ((232, 223, 185), 1.0, 0.1, None, "Metal", "Darker, warmer than silver"),        # 97
    "Stormstone"      : ((60, 85, 160), 0.3, 0.3, (140, 190, 255, 0.6), "Slate", "Storm blue, lightning veins"), # 98 NEW
    "Rhodium"         : ((244, 248, 255), 1.0, 0.02, None, "Glass", "Most mirror-like metal"),           # 99
    "Diamond"         : ((199, 240, 255), 0.0, 0.0, (197, 238, 255, 0.4), "Glass", "Faint sparkle"),     # 100
    "Starmetal"       : ((55, 65, 130), 1.0, 0.1, (200, 220, 255, 0.5), "Metal", "Midnight blue, star flecks"), # 101 NEW
    "Aether Crystal"  : ((225, 245, 255), 0.0, 0.02, (200, 240, 255, 0.9), "Glass", "White-cyan, radiant"),  # 102 NEW
    "Meteorite"       : ((138, 94, 66), 0.6, 0.5, (255, 95, 0, 0.3), "CrackedLava", "Burnt crust, glowing cracks"), # 103
    "Soulstone"       : ((70, 255, 200), 0.0, 0.1, (80, 255, 200, 0.9), "Glass", "Ghostly teal glow"),       # 104 NEW
    "Osmium"          : ((102, 134, 189), 1.0, 0.1, None, "Metal", "Blue tint, densest metal"),          # 105 NEW
    "Galaxyrock"      : ((40, 20, 90), 0.2, 0.3, (140, 90, 255, 0.8), "Basalt", "Dark rock full of swirling stars"), # 106 NEW
    "Iridium"         : ((236, 242, 252), 1.0, 0.05, (210, 228, 255, 0.3), "Metal", "Brilliant white, rarest metal"), # 107 NEW
    "Frostfire Crystal": ((120, 200, 255), 0.0, 0.03, (255, 120, 60, 1.0), "Glass", "Ice-blue crystal, burning orange core"), # 108 NEW

    # ── MYTHIC (109-114) ──
    "Shadow Shard"    : ((20, 10, 32), 0.3, 0.05, (130, 40, 255, 1.0), "Glass", "Black shard, violet edge glow"), # 109 NEW
    "Celestial Crystal": ((255, 228, 140), 0.2, 0.02, (255, 240, 180, 1.2), "Glass", "Golden starlight"),  # 110 NEW
    "Orichalcum"      : ((255, 145, 0), 1.0, 0.15, None, "Metal", "Bright orange, clearly not gold"),    # 111
    "Rainbow Crystal" : ((255, 255, 255), 0.0, 0.02, (255, 255, 255, 1.2), "ForceField", "Body and glow cycle through the rainbow"), # 112 NEW
    "Mythril"         : ((132, 207, 255), 1.0, 0.08, (106, 191, 255, 0.8), "Metal", "Silver-blue"),      # 113
    "Dragonstone"     : ((185, 10, 20), 0.4, 0.15, (255, 60, 0, 1.3), "Slate", "Crimson scale-rock, fiery glow"), # 114 NEW

    # ── DIVINE (115-118) ──
    "Adamantite"      : ((184, 0, 32), 1.0, 0.18, None, "Metal", "Crimson"),                            # 115
    "Thorium"         : ((191, 191, 181), 1.0, 0.3, (171, 171, 255, 0.6), "Metal", ""),                  # 116
    "Uranium"         : ((255, 226, 0), 0.6, 0.3, (255, 236, 40, 1.2), "Neon", "Bright yellow glow"),    # 117
    "Plutonium"       : ((222, 150, 105), 0.85, 0.25, (255, 120, 30, 1.2), "Metal", "Silvery metal, orange-tinted, orange glow"), # 118

    # ── EXOTIC (119-121) ──
    "Fermium"         : ((255, 2, 70), 0.8, 0.12, (255, 15, 97, 1.5), "Metal", ""),                   # 119
    "Lawrencium"      : ((255, 235, 177), 1.0, 0.05, (255, 239, 190, 1.7), "Metal", "White-gold"),       # 120
    "Oganesson"       : ((17, 0, 42), 1.0, 0.05, (137, 54, 255, 2.0), "ForceField", "Void black; cycle the glow through the rainbow"), # 121
```


## Space ores (40, separate set)

Own progression, 1-40, same rarity ladder scaled down:
Common 1-8, Uncommon 9-16, Rare 17-23, Epic 24-29, Legendary 30-34, Mythic 35-37, Divine 38-39, Exotic 40.
Names are unique against the main list. Event Horizon Shard and Big Bang Fragment tie into the existing `eventhorizon` / `bigbang` zones.

```python
    # ── COMMON (1-8) ──
    "Stardust"            : ((200, 200, 225), 0.0, 0.9, (220, 220, 255, 0.1), "Sand", "Glittery gray dust"),            # 1
    "Moon Dust"           : ((190, 190, 195), 0.0, 1.0, None, "Sand", "Fine pale powder"),                              # 2
    "Asteroid Rock"       : ((95, 85, 80), 0.1, 0.9, None, "Rock", "Pitted brown-gray"),                                # 3
    "Comet Ice"           : ((190, 235, 255), 0.0, 0.2, None, "Ice", "Dirty blue ice"),                                 # 4
    "Martian Rock"        : ((200, 80, 40), 0.0, 0.9, None, "Sandstone", "Rust red"),                                   # 5
    "Cosmic Ash"          : ((70, 65, 80), 0.0, 1.0, None, "Ground", "Soft violet-gray ash"),                           # 6
    "Ring Ice"            : ((235, 220, 190), 0.0, 0.3, None, "Glacier", "Saturn-ring cream ice"),                      # 7
    "Space Glass"         : ((120, 200, 220), 0.0, 0.05, None, "Glass", "Smoky cyan glass"),                            # 8

    # ── UNCOMMON (9-16) ──
    "Meteor Shard"        : ((110, 75, 55), 0.6, 0.4, (255, 110, 30, 0.3), "CrackedLava", "Scorched, hot cracks"),       # 9
    "Lunar Crystal"       : ((200, 215, 255), 0.0, 0.05, (200, 215, 255, 0.4), "Glass", "Pale moonlight blue"),         # 10
    "Solar Glass"         : ((255, 200, 60), 0.0, 0.05, (255, 210, 80, 0.4), "Glass", "Sun-gold glass"),                # 11
    "Titan Ice"           : ((255, 170, 60), 0.0, 0.2, None, "Ice", "Orange methane ice"),                              # 12
    "Io Sulfur"           : ((240, 220, 30), 0.0, 0.6, (255, 230, 60, 0.2), "Sand", "Volcanic moon yellow"),            # 13
    "Ion Crystal"         : ((60, 180, 255), 0.0, 0.05, (80, 200, 255, 0.6), "Glass", "Electric blue"),                 # 14
    "Plasma Rock"         : ((255, 60, 200), 0.0, 0.5, (255, 80, 220, 0.6), "Slate", "Hot pink plasma veins"),          # 15
    "Orbitite"            : ((150, 160, 180), 1.0, 0.2, None, "Metal", "Ringed metallic bands"),                        # 16

    # ── RARE (17-23) ──
    "Helium-3"            : ((170, 255, 240), 0.0, 0.05, (170, 255, 240, 0.7), "Glass", "Pale mint fuel crystal"),      # 17
    "Aurora Crystal"      : ((60, 255, 150), 0.0, 0.05, (120, 255, 200, 0.8), "Glass", "Green-to-pink shimmer"),        # 18
    "Cosmic Quartz"       : ((220, 180, 255), 0.0, 0.05, None, "Glass", "Lilac, star specks"),                          # 19
    "Nova Glass"          : ((255, 120, 60), 0.0, 0.05, (255, 140, 80, 0.7), "Glass", "Exploding orange core"),         # 20
    "Astralite"           : ((100, 120, 255), 0.8, 0.15, (140, 160, 255, 0.5), "Metal", "Blue astral metal"),           # 21
    "Solar Flare Stone"   : ((255, 80, 0), 0.2, 0.3, (255, 120, 0, 1.0), "CrackedLava", "Flaring orange"),              # 22
    "Gravity Stone"       : ((40, 20, 70), 0.5, 0.2, (150, 80, 255, 0.5), "Basalt", "Heavy purple, bends light"),       # 23

    # ── EPIC (24-29) ──
    "Pulsar Crystal"      : ((0, 220, 255), 0.0, 0.03, (0, 230, 255, 1.0), "Glass", "Pulsing cyan beam"),               # 24
    "Nebulite"            : ((170, 60, 255), 0.0, 0.1, (255, 100, 220, 0.8), "Glass", "Purple-pink cloud swirl"),       # 25
    "Zero-G Crystal"      : ((230, 255, 255), 0.0, 0.02, (200, 255, 255, 0.6), "Glass", "Weightless shimmer"),          # 26
    "Cosmic Pearl"        : ((240, 230, 255), 0.3, 0.1, (220, 200, 255, 0.5), "SmoothPlastic", "Iridescent violet pearl"), # 27
    "Supernova Shard"     : ((255, 240, 180), 0.2, 0.05, (255, 200, 100, 1.2), "Glass", "White-hot burst"),             # 28
    "Photon Crystal"      : ((255, 255, 200), 0.0, 0.0, (255, 255, 220, 1.3), "Neon", "Pure light"),                    # 29

    # ── LEGENDARY (30-34) ──
    "Quasar Crystal"      : ((120, 180, 255), 0.0, 0.02, (160, 210, 255, 1.4), "Glass", "Blazing blue-white core"),     # 30
    "Neutronium"          : ((200, 205, 220), 1.0, 0.05, (220, 230, 255, 0.8), "Metal", "Impossibly dense silver"),     # 31
    "Dark Matter"         : ((10, 5, 20), 0.5, 0.1, (90, 40, 200, 1.0), "ForceField", "Barely visible, purple haze"),   # 32
    "Wormhole Crystal"    : ((60, 20, 160), 0.0, 0.05, (0, 255, 255, 1.2), "Glass", "Violet with a cyan tunnel glow"),  # 33
    "Solar Core"          : ((255, 170, 0), 0.3, 0.1, (255, 190, 40, 1.6), "Neon", "Miniature sun"),                    # 34

    # ── MYTHIC (35-37) ──
    "Antimatter"          : ((255, 255, 255), 0.0, 0.0, (255, 60, 200, 1.6), "ForceField", "White with magenta arcs"),  # 35
    "Black Hole Shard"    : ((0, 0, 0), 1.0, 0.0, (255, 140, 40, 1.4), "Glass", "Pure black, orange accretion ring"),   # 36
    "Cosmic String"       : ((200, 240, 255), 1.0, 0.0, (160, 220, 255, 1.8), "Neon", "Thin blinding thread"),          # 37

    # ── DIVINE (38-39) ──
    "Event Horizon Shard" : ((5, 0, 15), 1.0, 0.0, (255, 200, 120, 2.0), "ForceField", "Light bends around it"),        # 38
    "Big Bang Fragment"   : ((255, 250, 240), 0.5, 0.0, (255, 255, 255, 2.2), "Neon", "Origin light, all colors"),      # 39

    # ── EXOTIC (40) ──
    "Singularity"         : ((0, 0, 0), 1.0, 0.0, (255, 255, 255, 2.5), "ForceField", "Void; glow cycles the rainbow"), # 40
```

## Change log (user adjustments)

1. Initial remake: 8 alloys/variants replaced, interleaved bands.
2. Cut man-made / lab-made / Minecraft entries (Brick, Charcoal, Alumina, Silicon Nitride, Boron Nitride, Graphene, Prismarine).
3. Up: Amethyst +, Chromium +, Sunstone ++, Moonstone ++, Chalcopyrite ++, Onyx +. Down: Topaz -, Graphite --.
4. Opal ++.
5. Aquamarine ++.
6. Swapped Moonstone and Emerald. Alexandrite down. Aquamarine took Moissanite's slot; Moissanite dropped to mid-Rare.
7. Boron Carbide replaced with Musgravite.
8. Colors boosted to pop: saturation x1.3 (+0.05) and a brightness floor for colored ores; intentionally dark ores (Obsidian, Onyx, coals, Oganesson, etc.) keep their darkness with a richer tint; grays unchanged. Glow colors boosted the same way.
9. Uranium recolored bright yellow. Plutonium changed from solid orange neon to orange-tinted silvery metal with an orange glow.
10. Added Exotic as the top rarity; re-split Legendary / Mythic / Divine / Exotic.
11. Round 2 swaps: 21 obscure ores replaced with recognizable real ores (Coal, Rock Salt, Aluminum, Pearl, Lithium, Moon Rock, Geode, Bloodstone) and fantasy ores (Shadow Shard, Rainbow Crystal, Dragonstone and others). Rainbow Crystal carries the `rainbow` flag like Oganesson.
12. Position swaps: Rainbow Crystal and Heartstone (now 108 / 112), Dragonstone and Starmetal (101 / 114), Stormstone and Phoenix Stone (98 / 68). Nebula Crystal replaced by Galaxyrock (106).
13. Added a separate 40-ore space set.
14. Reverted Rainbow Crystal (112) and Dragonstone (114) to Mythic; Starmetal back to 101. Heartstone dropped, Frostfire Crystal at 108.


## Applying the Space set

- Edit `MineConfig.ORES` (ids, names, tiers, looks). Ore packs and pack art regenerate from it automatically.
- Old saves: players holding removed ores (`p.ores[id]`) or unopened `<id>_ore_pack` rows need a one-time migration to a replacement id.
- Tool generator LOOKS table needs the same list so ore blocks and tools stay in sync.
