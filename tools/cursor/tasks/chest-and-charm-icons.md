# Job: Canva icons for every chest and every charm

## Why

The owner, 2026-10-19 (`wiki/open-questions.md`, "§0e decided"): *"get cursor to
get images for everything with canva then get everything done"*. Cursor jobs
make Canva images for everything new, charms and chests included.

The same day the chests and charms were rebuilt (`wiki/systems/chests-and-lucky-blocks.md`,
`wiki/systems/charms.md`):

- **Chests are ranked F to SSS** (`MineChestRanks`). Every chest has its own
  name, and its rank is shown as a coloured **letter badge** drawn by the game.
  So **never paint a rank letter into the art**; make the rank readable from the
  chest itself.
- **Each of the 19 pack sets has three named chests** (`MineSetChests`), which
  spawn where that set's pets live and pay that set's packs.
- **Every charm has one rarity, F to SSS, forever.** There are 32 new charm
  types (four per rarity) and 8 Halloween charms that the Crypt chests pay.

Most of these have no picture. A chest with no image shows a blank tile in
Collection → Chests. A charm with no `art` falls back to a plain glyph in the bag.

## What to draw

Read the files at job time; agents are editing them in parallel. The lists below
were correct on 2026-10-19.

### A. Chests (2D icons, not the 3D wall models)

1. **The 57 set chests.** Ids are `<set key>_chest_low`, `_mid` and `_high`
   (`MineSetChests.chestId`). Low is rank D, mid is B, high is S. Theme each one
   on its set; read the set's pets in `src/ReplicatedStorage/Mine/Shared/SetPets/`.

| set | lives in | low (D) | mid (B) | high (S) |
|---|---|---|---|---|
| Pebblebound (`pebblebound`) | Dirt Meadow | Pebble Pouch | Geode Crate | Earthheart Coffer |
| Sugar Rush (`sugar_rush`) | Greyvein Quarry | Gumdrop Tin | Lollipop Locker | Candy Castle Chest |
| Mosswood (`mosswood`) | Greyvein Quarry, layer 250+ | Mossy Stump Box | Fern Hollow Chest | Heartwood Hoard |
| Lost & Found (`lost_and_found`) | Mistreef Depths | Lost Luggage | Map Maker's Trunk | Forgotten Treasure Chest |
| Starfront (`starfront`) | Mistreef Depths, layer 250+ | Supply Pod | Cargo Capsule | Starship Vault |
| Arcade Legends (`arcade_legends`) | Arcwork Veins | Token Tub | Prize Crane Box | High Score Safe |
| Crystal Hollow (`crystal_hollow`) | Arcwork Veins, layer 250+ | Quartz Crate | Amethyst Coffer | Prismatic Geode Vault |
| Shogun's Oath (`shoguns_oath`) | Bloodmoon Hollow | Bamboo Box | Lacquer Chest | Gold-Leaf Treasury |
| Royal Reserve (`royal_reserve`) | Bloodmoon Hollow, layer 250+ | Velvet Purse | Crown Jewel Case | Sovereign's Vault |
| Crimson Eclipse (`crimson_eclipse`) | Eclipse Core | Red Moon Box | Midnight Reliquary | Eclipse Crown Coffer |
| Holo Havoc (`holo_havoc`) | Eclipse Core, layer 250+ | Foil Tin | Chrome Locker | Hyperholo Vault |
| Rainbow Road (`rainbow_road`) | Riftmarch Scarps | Pastel Pail | Prism Trunk | Celestial Rainbow Chest |
| Infernal Reign (`infernal_reign`) | Riftmarch Scarps, layer 250+ | Cinder Crate | Obsidian Strongbox | Magma Citadel Vault |
| Atlantis Rising (`atlantis_rising`) | Starfall Barrens | Tidepool Clam | Coral Coffer | Sunken City Vault |
| Divine Relics (`divine_relics`) | Starfall Barrens, layer 250+ | Idol Box | Sacred Ark | Pantheon Reliquary |
| Dragonfall (`dragonfall`) | Mythral Catacombs | Hatchling Nest | Drakefire Coffer | Great Wyrm Hoard |
| Eternal Roots (`eternal_roots`) | Mythral Catacombs, layer 250+ | Root Knot Box | Spring Hollow Chest | World Root Vault |
| Mythic Menagerie (`mythic_menagerie`) | Primordium Heart | Egg Basket | Beast Den Crate | Titan's Nest |
| Chaos Theory (`chaos_theory`) | Primordium Heart, layer 250+ | Glitch Box | Paradox Cube | Fractured Reality Vault |

2. **Three new Event Horizon chests** (`MineZoneChests.ZONE_CHESTS.bigbang`):
   `hz_nebula` Nebula Locker (B), `hz_quasar` Quasar Reliquary (SS) and
   `hz_bigbang` Big Bang Crown (SSS). Match the five Event Horizon chests that
   already have art (`hz_event`, `hz_pulse`, `hz_singularity`, `hz_collapse`,
   `hz_horizon` in `MineIcons.IMAGES`): dark universe, star glow, nebula purple
   to cyan.
3. **The Shiny Chest** (`shiny_chest`, rank S, the rare chase chest). It has no
   picture at all.
4. **The 8 Crypt chests**, one per rank, in `MineCryptRules` (the Crypt v2
   work). On 2026-10-19 they were F Candy Sack, D Pumpkin Pail, C Cobweb Crate,
   B Bat Box, A Coffin Chest, S Witch's Cauldron, SS Phantom Vault and SSS Pumpkin
   King's Hoard, with ids like `crypt_chest_<rank>`. Use the ids and names in the
   file when you start. Halloween theme, friendly: candy, pumpkins, bats,
   cobwebs, moonlight. Nothing gory or scary; the players are kids.
5. **Last, the 88 zone chests that already have pictures** (2026-09-14 cutouts in
   `MineIcons.IMAGES`, keyed by the ids in `MineZoneChests.ZONE_CHESTS`). Several
   were renamed on 2026-10-19 (for example `meadow_age_s1` is now Dewvault, rank
   SS), so the old picture may not fit the new name. Redraw them in the new style
   behind their own flag (see Wiring). Do this part only after 1 to 4 are done.

**The look of a chest.** A chunky 3/4 view on a transparent background, readable
at 72 px, like the existing zone chest cutouts. The rank shows in the materials:

| rank | materials |
|---|---|
| F, D | plain wood, rope, tin; no glow |
| C, B | banded wood, iron or silver straps, a small gem |
| A, S | gold trim, several gems, a soft glow |
| SS, SSS | crowned or ornate, glowing, sparkles; SSS is the grandest |

Match the badge colours (`MineChestRanks.COLOR`) where a tint helps.

### B. Charms

`MineCharms.LIST` holds 277 charms. The 36 original graded charms already wear
art (`art = "rbxassetid://…"` on their rows; they came from the owner's
`charms2.svg`). **Match their style:** the owner's reference is ornate jewellery,
meaning amulets, pendants, beaded strings, brooches, gem-set lockets, aged brass and
enamel (`docs/HANDOFF.md` §2.6). The 164 icons from
`tools/icons/gen-charm-art.js` were rejected; do not reuse them. Rarity should read
at a glance: humble metals for F and D, gold and gems up the ladder, a glow from S.

Draw these, in this order:

1. **The 32 new charm types** (`MineCharms.NEW_GRADED`). Each row carries a
   `look` line; draw that.

| rarity | id | name | look |
|---|---|---|---|
| F | `clover_sprig` | Clover Sprig | a three-leaf clover on a tin ring |
| F | `lucky_penny` | Lucky Penny | a shiny copper penny on a string |
| F | `firecracker_charm` | Firecracker Charm | a tiny red firecracker with a gold fuse |
| F | `pebble_pal` | Pebble Pal | a round grey pebble with a painted smile |
| D | `four_leaf` | Four-Leaf Clover | a bright four-leaf clover in clear resin |
| D | `horseshoe_charm` | Horseshoe Charm | a silver horseshoe with gold nails |
| D | `cherry_bomb` | Cherry Bomb | two red cherry-shaped bombs on one stem |
| D | `tin_soldier` | Tin Soldier | a toy tin soldier with a drum |
| C | `rocket_fin` | Rocket Fin | a red rocket fin with a white stripe |
| C | `treasure_map` | Treasure Map | a rolled map with a red X and a gold ribbon |
| C | `thunder_egg` | Thunder Egg | a cracked stone egg with a lightning geode inside |
| C | `honeycomb_charm` | Honeycomb Charm | a golden honeycomb dripping honey |
| B | `comet_tail` | Comet Tail | a blue comet with a long sparkling tail |
| B | `clockwork_heart` | Clockwork Heart | a brass heart full of turning gears |
| B | `coin_fountain` | Coin Fountain | a tiny fountain spilling gold coins |
| B | `lantern_fish` | Lantern Fish | a deep-sea fish with a glowing lure |
| A | `phoenix_feather` | Phoenix Feather | a fiery orange feather with flame tips |
| A | `wizard_monocle` | Wizard's Monocle | a star-etched monocle on a purple chain |
| A | `kraken_tooth` | Kraken Tooth | a curved sea-green tooth wrapped in rope |
| A | `golden_goose` | Golden Goose Egg | a shining golden egg in a little nest |
| S | `storm_crown` | Storm Crown | a silver crown crackling with lightning |
| S | `meteor_core` | Meteor Core | a glowing red meteor in a cage of iron |
| S | `moonstone_key` | Moonstone Key | a pale moonstone key that glows blue |
| S | `unicorn_horn` | Unicorn Horn | a spiral pearl horn with rainbow glints |
| SS | `world_seed` | World Seed | a glowing seed with tiny roots and leaves |
| SS | `halo_ring` | Halo Ring | a floating golden halo with white wings |
| SS | `supernova_shard` | Supernova Shard | a crystal shard bursting with star light |
| SS | `golden_gauntlet` | Golden Gauntlet | a golden glove set with six bright gems |
| SSS | `black_hole_heart` | Black Hole Heart | a swirling black hole inside a gold ring |
| SSS | `sunheart_crown` | Sunheart Crown | a blazing sun set in a golden crown |
| SSS | `dragon_pearl` | Rainbow Dragon Pearl | a rainbow pearl held in a dragon's claw |
| SSS | `big_bang_bell` | Big Bang Bell | a cosmic bell that rings with exploding stars |

2. **The 8 Crypt chest charms** (`MineCharms.CRYPT_CHEST_CHARMS`; one per Crypt
   chest rank, given by `MineCharms.cryptChestCharm(rank)`):

| rarity | id | name | look |
|---|---|---|---|
| F | `hallow_wrapper` | Candy Wrapper Charm | a twisted orange-and-black candy wrapper |
| D | `hallow_batwing` | Bat Wing Charm | a little purple bat wing on a silver loop |
| C | `hallow_catbell` | Black Cat Bell | a black cat's collar bell with green eyes |
| B | `hallow_broom` | Witch's Broom Charm | a tiny witch's broom with a starry ribbon |
| A | `hallow_spidersilk` | Spider Silk Locket | a locket wrapped in shining spider silk |
| S | `hallow_pumpkincrown` | Pumpkin King Crown | a carved pumpkin crown with a candle glow |
| SS | `hallow_ravenfeather` | Raven Moon Feather | a black raven feather under a full moon |
| SSS | `hallow_cryptkey` | Crypt Keeper's Key | an old bone-white key with a glowing purple gem |

3. **The 6 candy charms** (`MineCharms.CANDY_CHARMS`), drawn from their names:
   `hallow_kernel` Candy Corn Kernel (D), `hallow_wisp` Cotton Candy Wisp (C),
   `hallow_fizz` Pop Rocks Fizz (B), `hallow_lantern` Rock Candy Lantern (A),
   `hallow_moon` White Chocolate Moon (S), `hallow_skull` Jawbreaker Skull (SS;
   a cute candy skull, not a scary one).
4. **The 31 older charms:** the 15 zone charms and the 15 pack charms (the
   `source = "zone"` and `source = "pack"` rows in `MineCharms.luau`; draw from
   each row's name and stat line), plus Pot of Gold (`lucky_charm`, a pot of gold
   coins under a rainbow).
5. **Last, the 164 ore charms** (`source = "ore"`, generated at load: ids
   `<ore>_charm` and `<ore>_charm_2`, names `<Ore> <Word> Charm`). Draw one
   piece of jewellery per charm, set with that ore's colour (`MineConfig.ORES`)
   and carrying its shape's motif. The `<Word>` in the name is the shape
   (`MineCharms.SHAPE_WORD`): Focus a single big stone, Twin two stones, Pact a
   split light-and-dark stone, Ward a shield-shaped setting, Brink a stone on a
   knife-edge setting, Surge a stone with rising sparks. An ore's two charms
   always have different shapes, so they must look different.

Not in this job: Charm Pack icons (the shelf shows the rarity letter), pack art,
pets, and the 3D chest models in `MineChestModel`.

## How to make them

Use the pipeline that made the case art and the tool icons
(`wiki/code/assets-and-uploads.md`):

1. Canva `generate-image`, one image per item, then `remove-background`.
2. Lay them out in a grid on a working Canva design, export transparent PNGs, and
   cut them into 512 x 512 icons with `tools/icons/slice-grid.ps1`. Save them to
   `art/chest-icons/<id>.png` and `art/charm-icons/<id>.png`.
3. Canva allows about 7 generations per 30 minutes, plus a monthly allowance.
   Keep each list's progress in a `state.json` in `build/chest-art/` and
   `build/charm-art/`, so a later run resumes where this one stopped. Do the
   lists in the order above: if the allowance runs out, the newest things have
   pictures first.
4. Upload with the Studio MCP `upload_image` (uploads go to the owner's own
   account, which the owner allows: "you can upload it via personal account, and
   i just have to share access"). Name them `mfc_chest_<id>_v1` and
   `mfc_charm_<id>_v1`.
5. Write the ids to `build/chest-art/ids.json` and `build/charm-art/ids.json`
   (`{ "<id>": <assetId> }`, keyed by the game's id, never by the name) and the
   uploads the owner must share to `build/chest-art/share-list.txt` and
   `build/charm-art/share-list.txt`.

## Wiring (behind flags, off until the owner shares)

An unshared image draws nothing in the group place, and a blank tile is worse
than the fallback. So, the same as `MineIcons.NEW_TOOL_ICONS_SHARED`:

- **Chests,** `src/ReplicatedStorage/Mine/Shared/MineIcons.luau`:
  - add `MineIcons.CHEST_ART = { [chestId] = "rbxassetid://N", ... }` for every
    new chest in A1 to A4, and `MineIcons.CHEST_ART_SHARED = false`;
  - next to the `if MineIcons.NEW_TOOL_ICONS_SHARED then` block at the end of the
    file, add `if MineIcons.CHEST_ART_SHARED then` copying each entry into
    `MineIcons.IMAGES` when the key is not there yet;
  - the A5 redraws go in a second table, `MineIcons.CHEST_ART_REDRAW`, behind
    `MineIcons.CHEST_ART_REDRAW_SHARED = false`. That one **does** overwrite
    the old `IMAGES` entry, so the owner can compare and choose.
  - The chest dex already reads `Icons.image(def.id)` (`MineInventoryView`,
    Collection → Chests), so nothing else changes for a main-game chest. For
    the Crypt chests, find what the Crypt screens read for a chest's picture.
    If it is not `Icons.image(<chest id>)`, wire it the way that screen expects and
    say so in the report.
- **Charms,** `src/ReplicatedStorage/Mine/Shared/MineCharms.luau`:
  - add `MineCharms.CHARM_ART = { [charmId] = "rbxassetid://N", ... }` and
    `MineCharms.CHARM_ART_SHARED = false` near the end of the file;
  - just before `return MineCharms`, when the flag is on, give every charm in
    `LIST` its `CHARM_ART` entry if it has no `art` yet. Never replace the 36
    originals' art. Every screen draws a charm's picture from `def.art`.
- **A check.** Add `tools/verify/art-ids.js`. Every key in `CHEST_ART`,
  `CHEST_ART_REDRAW` and `CHARM_ART` must be a real chest or charm id, every
  value must be an `rbxassetid://` with digits, no asset id may be used twice,
  and both flags must still be `false` in the commit.

Leave the flags `false` in the commit. The owner shares the uploads in the
Creator Hub and flips them, as with the tool icons.

## Rules

- Change no stats, prices, odds, names or ranks. If a name does not fit the
  picture that comes out, report it; do not rename anything.
- Do not hand-edit generated files (`MinePackArt`, `MineSkins` and the like).
- Add no new top-level `local` in `MineServer` or `MineClient`. This job should
  not touch either file.

## Check it in Studio (Edit mode only; do not start Play)

1. With both flags set to `true` **locally** (do not commit that), build a grid
   of `ImageLabel`s under `_ArtCheck` in a ScreenGui in StarterGui, one per new
   id, labelled with the name and rank.
2. Screen-capture it. Look for cut-off edges, leftover background, two items that
   look alike, and a rank that does not read (an F chest that looks grander than
   an S one).
3. Confirm every image loads with `AssetService:CreateEditableImageAsync` (the
   string form of `ContentProvider:PreloadAsync` reports Failure in Edit mode even
   for art that works).
4. Delete `_ArtCheck`, set the flags back to `false`, and never save the place.

## Verify and finish

- Run `node tools/verify/art-ids.js`, `node tools/verify/charm-tiers.js`,
  `node tools/verify/chest-ranks.js`, `node tools/verify/compile.js` and the
  full suite.
- Update `wiki/code/assets-and-uploads.md` (the flags, the folders, the share
  lists), `wiki/systems/charms.md` and `wiki/systems/chests-and-lucky-blocks.md`
  (which have art now). Add a `wiki/log.md` entry.
- Commit only `MineIcons.luau`, `MineCharms.luau`, `tools/verify/art-ids.js`,
  those wiki pages and the `build/` id and share lists. The PNGs in `art/` stay
  untracked unless the owner says otherwise.
- In the report: how many of each list are drawn and uploaded, the share lists
  for the owner, any picture you are unsure of, and any name that does not fit
  its picture. The owner decides on taste.
