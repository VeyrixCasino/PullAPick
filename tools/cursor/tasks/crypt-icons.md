# Job: Canva icons for the Candy Crypt (16 candy ores, 16 Halloween tools, 8 Crypt chests)

## Why

The owner, 2026-10-19 (`wiki/open-questions.md`, "Candy Crypt v2", "Chests, charms
and art"): *"get cursor to get images for everything with canva then get
everything done"*: Cursor jobs make Canva images for everything new. This job is
the Candy Crypt's own three sets. Charms, enchant books and pets are other jobs.

Today none of them has art. The screens fall back to a coloured tile, because
`MineCryptIcons` (below) is empty.

## What to make (read the files at job time; they may have changed)

**16 candy ores**, `MineConfig.CANDY_ORES` in
`src/ReplicatedStorage/Mine/Shared/MineConfig.luau` (each row has its `color` and
`material`; the rarity is `band`, two ores per rarity):

| id | name | rarity |
|---|---|---|
| candy_corn | Candy Corn | Common |
| gumdrop | Gumdrop | Common |
| licorice | Licorice | Uncommon |
| cotton_candy | Cotton Candy | Uncommon |
| caramel | Caramel | Rare |
| taffy | Taffy | Rare |
| pop_rocks | Pop Rocks | Epic |
| toffee_shard | Toffee Shard | Epic |
| nougat | Nougat | Legendary |
| rock_candy | Rock Candy | Legendary |
| milk_chocolate | Milk Chocolate | Mythic |
| candy_apple | Candy Apple | Mythic |
| white_chocolate | White Chocolate | Divine |
| sugar_skull | Sugar Skull | Divine |
| chocolate_skull | Chocolate Skull | Exotic |
| jawbreaker | Jawbreaker | Exotic |

**16 Halloween tools**, `MineCandyTools.TOOLS` in
`src/ReplicatedStorage/Mine/Shared/MineCandyTools.luau`, one per candy ore. The
family is the tool's shape: pickaxe = **Pick**, hammer = **Mallet**, drill =
**Auger**, explosive = **Cracker** (a throwable candy bomb).

| id | name | family |
|---|---|---|
| hallow_candy_corn_pick | Candy Corn Pick | pickaxe |
| hallow_gumdrop_mallet | Gumdrop Mallet | hammer |
| hallow_licorice_auger | Licorice Auger | drill |
| hallow_cotton_candy_cracker | Cotton Candy Cracker | explosive |
| hallow_caramel_mallet | Caramel Mallet | hammer |
| hallow_taffy_pick | Taffy Pick | pickaxe |
| hallow_pop_rocks_cracker | Pop Rocks Cracker | explosive |
| hallow_toffee_shard_auger | Toffee Shard Auger | drill |
| hallow_nougat_pick | Nougat Pick | pickaxe |
| hallow_rock_candy_mallet | Rock Candy Mallet | hammer |
| hallow_milk_chocolate_auger | Milk Chocolate Auger | drill |
| hallow_candy_apple_cracker | Candy Apple Cracker | explosive |
| hallow_white_chocolate_mallet | White Chocolate Mallet | hammer |
| hallow_sugar_skull_pick | Sugar Skull Pick | pickaxe |
| hallow_chocolate_skull_cracker | Chocolate Skull Cracker | explosive |
| hallow_jawbreaker_auger | Jawbreaker Auger | drill |

**8 Crypt chests**, `MineCryptChests.RANKS` in
`src/ReplicatedStorage/Mine/Shared/MineCryptChests.luau`, keyed by rank:

| key | name | what to draw |
|---|---|---|
| F | Candy Sack | a paper trick-or-treat bag, candy spilling out |
| D | Pumpkin Pail | a jack-o'-lantern candy bucket |
| C | Cobweb Crate | a small wooden crate draped in cobwebs |
| B | Bat Box | a lidded box with little bat wings |
| A | Coffin Chest | a friendly purple coffin-shaped chest |
| S | Witch's Cauldron | a bubbling cauldron full of candy |
| SS | Phantom Vault | a ghostly glowing vault door, half see-through |
| SSS | Pumpkin King's Hoard | a golden crowned pumpkin on a pile of treasure |

The names are PROPOSED (2026-10-19) and may change before you start; draw what the
file says then.

## The look

- **Halloween theme** (`MineTheme.EVENT_THEMES.halloween`, see
  `wiki/code/candy-style.md` "Event themes"): night purple-black, candy purple,
  pumpkin orange, bone white, a slime-green glow. **Cute-spooky for kids, never
  scary or gory.**
- **Like the existing Canva tool icons** (`wiki/code/assets-and-uploads.md`, "Tool
  icons from Canva"): one object, three-quarter view, chunky readable silhouette,
  soft lighting, transparent background, 512 x 512.
- **Candy ores:** a chunky ore nugget made of that candy, in its row's colour, with
  candy texture (Candy Corn's yellow-orange-white bands, Licorice twists, a
  glossy Candy Apple, a layered Jawbreaker sphere). Rarer ores sparkle a little
  more, but **draw no rarity frame or letter**: the screens add the rim.
- **Halloween tools:** the family's shape kept (a pick is a pick, a mallet a
  mallet, an auger a drill, a cracker a round bomb with a fuse), built from or
  decorated with its candy. Rarer tools look grander. Match the two tools of a
  rarity to each other.
- **Chests:** each its own container (the table above). **No rank badge in the
  image**: the screens show F..SSS as a badge. A rarer chest looks richer.

## Steps

1. Generate each image with Canva `generate-image`, then `remove-background`, and
   export a transparent 512 x 512 PNG. Save them as
   `art/crypt-icons/ores/<id>.png`, `art/crypt-icons/tools/<id>.png` and
   `art/crypt-icons/chests/<key>.png`. Keep Canva's media ids in
   `build/crypt-icons/canva-media.json` and your progress in
   `build/crypt-icons/state.json`: Canva allows about 7 generations per 30
   minutes, so resume from the state file.
2. Upload each PNG with `upload_image` (this task lists them, so the upload is in
   scope; it uploads as the owner's account), named `mfc_crypt_ore_<id>_v1`,
   `mfc_crypt_tool_<id>_v1` and `mfc_crypt_chest_<key>_v1`. Write every id to
   `build/crypt-icons/ids.json` and the list the owner must share to
   `build/crypt-icons/share-list.txt`.
3. **Wire them, in one file only:** fill the three maps in
   `src/ReplicatedStorage/Mine/Shared/MineCryptIcons.luau`,
   `ORES[id]`, `TOOLS[id]` and `CHESTS[key]`, each `"rbxassetid://<id>"`.
   **Leave `SHARED = false`.** An unshared image draws nothing in the group place;
   the owner shares the uploads in the Creator Hub and flips it, as with
   `MineIcons.NEW_TOOL_ICONS_SHARED`. Everything else already reads through it:
   `MineCryptRules` puts `icon` on the tool rows, the Forge recipes, the candy-ore
   rows and the chest-odds rows, and `chestOpened` carries the chest's.

Do not change any id, name, number or odds in `MineConfig`, `MineCandyTools` or
`MineCryptChests`, and do not touch any screen.

## Verify and finish

- Run `node tools/verify/crypt.js`, `node tools/verify/compile.js` and the full
  suite (`bash tools/verify/suite.sh --quiet`).
- In Studio (Edit mode, never Play, never save): set `SHARED` to true in a
  **command-bar copy** of the module only, build an ImageLabel per id in a
  `_CryptIconsCheck` ScreenGui, screenshot it, delete it. An unshared image shows
  blank; list which.
- Update `wiki/code/assets-and-uploads.md` (the new ids file, the flag, the share
  list) and `wiki/systems/world-events.md` (the Crypt's art: made, waiting to be
  shared). Add a `wiki/log.md` entry.
- Commit only `MineCryptIcons.luau` and those wiki pages.
- In the report: every uploaded id, the share list, and any image you are not sure
  reads as its item. The owner decides on taste.
