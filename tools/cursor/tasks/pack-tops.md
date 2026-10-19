# Job: take the set name off the top of the 19 sets' pack images, and re-upload them

## Why

The owner, 2026-10-19 (`wiki/open-questions.md`, "Chests, charms and art"):
**"Pack tops: the set name baked onto the crinkled top of the 19 sets' pack
images comes off; the renderer (`tools/pack-sprites/PackRender3D.cs`) leaves it
blank and the PC session re-renders and re-uploads."**

The renderer half is done. `tools/pack-sprites/render.ps1` now leaves the top
seal blank unless it is run with `-Title` (`PackRender3D.BuildTitleMask` draws
nothing for an empty title). The 57 pack sprites the game shows (19 sets x 3
covers, `build/pack-art/ids.json` `packs`, read by
`src/ReplicatedStorage/Mine/Shared/MinePackArt.luau`) were rendered on
2026-10-10 with the name on the seal. This job re-renders them, uploads them and
points the game at the new ones. Background: `wiki/code/assets-and-uploads.md`
("Personal upload, then share") and `wiki/systems/pack-cases.md` ("Art").

## Needs

- The owner's PC: Windows PowerShell 5.1 (render.ps1 compiles
  `PackRender3D.cs` with `Add-Type` and System.Drawing) and node.
- The covers, `art/cover-art/{Set}Coverart{1,2,3}.png` (untracked; on the PC
  since 2026-10-10). `node tools/pack-sprites/jobs.js` lists any that are
  missing. If any are, stop: **BLOCKED: the cover art is not in art/cover-art**.
- Studio open on the place, for `upload_image` (it uploads as the owner's own
  account). If no place is open, stop: **BLOCKED: open the place in Studio**.

## Steps

1. **Keep the old sprites.** Copy `art/pack-sprites` to
   `art/pack-sprites-titled-2026-10-10` (copy, do not move). `art/` is untracked,
   so this copy is the only way back to the titled images.
2. **Render**, without `-Title`:

   ```
   powershell -ExecutionPolicy Bypass -File "tools\pack-sprites\render.ps1"
   ```

   It overwrites the 57 files `art/pack-sprites/{Set}Pack_{1-2star,2.5-3.5star,4-5star}.png`
   (732 x 1024). Open three of them (one per cover band) next to their copies
   from step 1: **the top crimp must be blank** and everything else (angle, cover
   art, seal colour, shadow) must look the same. If anything else changed, stop
   and say what.
3. **Serve the repo** so `upload_image` can fetch the files (it takes http/https
   only, at most 15 per call; `build/ore-sheet/ASSETS.md`):

   ```
   node tools/serve.js
   ```

   That serves the repo root on port 7421, so a sprite is
   `http://localhost:7421/art/pack-sprites/<file>`, the same URLs the 2026-10-10
   upload used. (Its header says `.claude/launch.json` starts it; starting it by
   hand for this upload is fine. Stop it when the uploads are done.)
4. **Upload the 57** with `upload_image`, in calls of up to 15, named
   `mfc_pack_<Set>_<band>_v2` (versioned names, `wiki/code/assets-and-uploads.md`).
   Upload only these 57: the set icons, rarity icons and case art keep their ids.
   Append each call's result, the JSON object of URL -> `rbxassetid://...`, as one
   line to `build/pack-art/uploads-tops.jsonl`.
5. **Record the ids:**

   ```
   node tools/pack-sprites/write-ids.js < build/pack-art/uploads-tops.jsonl
   ```

   It merges into `build/pack-art/ids.json`: the 57 pack ids change, the set
   icons, rarity icons and `cases` keep theirs (it refuses if any file is left
   with no id). It also writes `build/pack-art/share-list-new.txt`, the 57 ids
   the owner must share. Check its output says `84 files ... 57 new`.
6. **Do the new ids load in the group place?** An unshared personal asset draws
   nothing there (`wiki/code/assets-and-uploads.md`). In Studio (Edit mode), try
   a few with `AssetService:CreateEditableImageAsync` (the string form of
   `ContentProvider:PreloadAsync` reports Failure in Studio Edit even for art in
   use) and the leading-zero id trick for a load that failed earlier.
   - **If they load:** run `node tools/pack-sprites/gen-pack-art.js` (it
     rewrites `MinePackArt.luau` from `ids.json`; never hand-edit that file),
     then open the inventory's Packs tab and the credit shop in Play, check the
     set packs draw without a name on top, screenshot, and stop Play.
   - **If they do not:** do NOT regenerate `MinePackArt.luau` (pointing the game
     at unshared images would blank every set pack). Write **BLOCKED: share the
     57 ids in build/pack-art/share-list-new.txt with the experience in the
     Creator Hub, then run `node tools/pack-sprites/gen-pack-art.js` and check
     the Packs tab in Studio** in the report, and finish.

## Finish

- Commit `build/pack-art/ids.json`, `build/pack-art/share-list-new.txt`,
  `build/pack-art/uploads-tops.jsonl` and, only if step 6 loaded,
  `src/ReplicatedStorage/Mine/Shared/MinePackArt.luau`. Nothing under `art/`
  (it is untracked).
- Fix the wiki in the same commit: `wiki/systems/pack-cases.md` ("Art") and
  `wiki/code/assets-and-uploads.md` ("Personal upload, then share") say the
  sprites have the set name on the seal and give the 2026-10-10 ids' state.
  Add an entry at the end of `wiki/log.md`, then `node tools/verify/wiki.js`.
- To undo: `build/pack-art/ids.json` from the commit before yours, then
  `node tools/pack-sprites/gen-pack-art.js` (the old ids are still shared).
- The report needs: the before/after of one sprite's top, the upload count,
  the `write-ids.js` output, whether the ids load, and any BLOCKED line.
