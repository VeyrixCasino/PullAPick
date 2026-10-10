---
title: Assets and uploads
type: code
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - docs/TODO.md §2, §6.3, §7, §9
  - docs/START-HERE.md §6
  - docs/BLOCKED.md #11, #12
  - build/ore-sheet/ASSETS.md
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - tools/gen-ore-icons.js
  - tools/gen-charm-icons.js
related: [tools-and-generators, rojo-and-studio, owner, charms, ores, open-questions]
---

# Assets and uploads

> The game is owned by a **group**, so every image, mesh, model, sound and decal
> that ships must be created **as the group**. An asset in a personal inventory
> cannot be moved, and a group experience may not be able to load it. Icon art
> is the owner's job.

## The rules (TODO §7, decided by the owner)

- **Creator = the Mine For Cards group, id `35326298`.** This matches
  `MineConfig.GROUP_ID`.
  - Open Cloud: `creationContext.creator.groupId = "35326298"`, never `userId`.
    The API key must be a **group** key.
  - Asset Manager or the 3D Importer: open the group place (`73982848847016`)
    first, and set Creator to Mine For Cards.
  - The uploading account needs the group role "Create and configure development
    items".
- **The personal-account warning.** If an upload shows the creator as the owner's
  personal account (named in TODO §7), **stop and upload again as the group**.
  Roblox cannot move assets between user and group inventories, so an upload to
  "My Inventory for now" is permanent.
- **Naming:** `mfc_<feature>_<name>_vN`, for example `mfc_pack_loam_v2`. Use
  feature folders in the group inventory (`packs/`, `tools/`, `ui/`, `audio/`).
  Version the name, or replace the id in code. Never re-upload under a generic name.
- **In code:** use stable `rbxassetid://…`, not `rbxgameasset://`. Write the ids
  into the real modules and record them in the feature's handoff file. An
  uploaded id that nothing references is as good as lost.
- **Before shipping:**
  1. Asset Manager, filtered to the group, lists the asset with the group as creator.
  2. The id loads in a fresh session.
  3. The code points at the new id.
- **Studio MCP `upload_image`** uploads as the signed-in **user**, and cannot
  target a group (`build/ore-sheet/ASSETS.md`). Confirm the creator after every
  upload.

## Personal upload, then share (owner, 2026-10-10)

The owner relaxed the group-only rule above for the pack art: *"you can upload
it via personal account, and i just have to share access"*.

- Studio MCP `upload_image` uploads as the signed-in user (iPressBars,
  `465369561`). The owner then grants the asset to the experience or group in
  the Creator Hub. Until that is done the image does **not** draw in the group
  place.
- Proven on `rbxassetid://121132243117622`: unshared it failed to load; after
  sharing it loaded at full size (732x1024) through `AssetService`.
- **Studio caches a failed load for the session.** After sharing, the same
  `rbxassetid://N` kept failing in that Studio session, while `rbxassetid://0N`
  (a leading zero, same asset) loaded. Retest with a fresh session or a
  leading-zero id before concluding the share did not work.
- The 84 pack sprites and icons are in `build/pack-art/ids.json`, written by
  `tools/pack-sprites/write-ids.js`; `build/pack-art/share-list.txt` lists them
  for sharing. **All 84 shared and loading in the group place** (2026-10-10,
  `PreloadAsync` 84/84; spot-checked sizes 732x1024 and 512x512).
- **In the game:** `tools/pack-sprites/gen-pack-art.js` turns `ids.json` into
  `MinePackArt` (do not hand-edit). `MinePackFX.art` asks it for any
  `<setKey>_pack_<n>` id, so every set pack wears its set's sprite, picked by
  the pack's stars: up to 2 -> sprite 1, 2.5 to 3.5 -> 2, 4 and up -> 3.
  It also holds the set icons and rarity icons (`setIcon`, `rarityIcon`).
- **Pack case art** (`MinePackArt.caseArt`) reads the `cases` map in
  `ids.json`: one image per set, keyed by the set's file name, plus `Wild`.
  - With no image, a set case wears its set's medallion and a wild case wears
    the gem of its star tier.
  - **The 20 images were made 2026-10-10.** The owner chose a booster box,
    lid open, packs peeking out. How they were made:
    - Canva `generate-image`, then `remove-background`;
    - laid out on two pages of a working copy of the cover sheet, then
      exported as transparent PNGs;
    - cut into 732×1024 by `tools/pack-sprites/slice-cases.ps1`, into
      `art/case-art/{Set}Case.png`.
  - The Canva media ids are in `build/case-art/canva-media.json`.
  - The images were uploaded as the owner's account and listed in
    `build/case-art/share-list.txt`. Unshared, they failed to load. **The
    owner shared all 20 on 2026-10-10.** After that, `PreloadAsync` loaded
    20/20 at 732×1024 (checked with leading-zero ids), and the boxes drew on
    the bag tiles and the opening screen in a play test.
- The owner has seen personal assets in the group they never shared by hand.
  Roblox appears to grant an experience use of an asset its owner uses there
  from Studio; *unverified*, so still share explicitly and test.

## Icons are the owner's job

The owner said so (START-HERE §6, BLOCKED #11). Do not generate icon art
unless asked. On 2026-10-10 the owner did ask: pack sprites, set icons and
rarity icons, made by `tools/pack-sprites/` (see the section above).

- The 164 generated charm icons (`tools/icons/gen-charm-art.js`) are **superseded**.
  The owner wants ornate jewellery instead, from a reference they supplied
  (HANDOFF §2.6).
- The pipeline is built and waiting for art. The steps are: upload as the
  group; write the ids file (`build/charm-icons/ids.json`, which does not exist yet);
  then run `node tools/gen-charm-icons.js`. That writes `MineCharmIcons`,
  which does not exist yet either, so nothing reads charm icons today.

## What is in `build/`

| path | tracked? | what |
|---|---|---|
| `build/icons/ids.json`, `build/icons/roster.txt` | yes | ore name → asset id for **82 ore icons and 82 case icons**, uploaded 2026-09-30 (`f5b6c34`). `tools/gen-ore-icons.js` turns them into `MineOreIcons`. |
| `build/charm-icons/manifest.json` | yes | metadata for the 164 generated charm icons |
| `build/charm-icons/*.png` | no (gitignored) | rebuilt by `gen-charm-art.js` |
| `build/ore-sheet/` | yes | 30 hand-made ore faces (`ore_NN.png`), the source sheet, `tiles.json`, `ORE_FACE.lua`, and `ASSETS.md`, which explains why the uploaded faces did not render |
| `build/tools/roster.json`, `build/tools/roster-plan.json` | yes | a tool roster snapshot and plan *(contents not reviewed)* |
| `build/*.json` at the top level | no (gitignored) | generated intermediates: `depth-sheet.json`, `balance-board.json` |

## Lessons already paid for (`build/ore-sheet/ASSETS.md`)

- **Moderation delay.** A new upload resolves through `GetProductInfo`
  immediately, but draws **nothing** until it clears moderation, and raises no error.
- **Ownership.** The 30 ore faces were uploaded as the user, so the group place
  rendered nothing, again silently. Check the owner first:
  `MarketplaceService:GetProductInfo(id).Creator`.
- **The workaround** was `tools/pack-ore-art.js`. It packs the pixels into Luau
  (`MineOreArt`), so block faces need no uploaded asset at all.

## What a cloud container cannot do (TODO §2, BLOCKED #12–#13)

- read the owner's disk (the original art lives in the owner's Downloads folder)
- connect to Studio, run Rojo against the live place, or run the game
- **upload anything to Roblox**

Uploads must be done by the owner in Studio, or by a local agent that genuinely
has Studio MCP, following §7. See [local-setup](local-setup.md).

## Open questions

- `build/ore-sheet/ASSETS.md` names the group as `7706885185`. TODO §7 and
  `MineConfig.GROUP_ID` say `35326298`. Which is that other number? It might be
  a universe or creator id *(unverified)*. See [open-questions](../open-questions.md).
- **Who owns the 164 ore and case icons** in `build/icons/ids.json`?
  - The `f5b6c34` message says they "resolve" and preload in the live place.
  - `upload_image` can only upload as the user.
  - TODO §6.3 and BLOCKED #11 still describe that ore art as not yet applied.
- `build/ore-sheet/ASSETS.md` still says `MineConfig.ORE_FACE` maps "all 121" ores.
  The roster is 82.
