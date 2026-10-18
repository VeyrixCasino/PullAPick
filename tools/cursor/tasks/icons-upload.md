# Job: upload the new drill and explosive icons and wire them in

## Why

The owner asked for every tool to have high-quality icons: *"redo the rests ...
make sure the colors make sense"*. Canva has now drawn drills and explosives for
tiers 1-81. Tier 82 of each family keeps its current art, which the owner liked.

The pickaxes went in on 2026-10-12. Do the drills and explosives the same way:
- the pickaxe tables are in `MineIcons.ORE_PICK_CANVA`;
- the history is in `wiki/log.md`, under "tool icons uploaded and wired behind the
  share flag".

## Inputs

- `art/tool-icons/drill/NN_<ore>.png`: 81 files, tiers 01-81.
- `art/tool-icons/explosive/NN_<ore>.png`: 81 files, tiers 01-81.
- The upload ledger from the pickaxe run: `build/tool-icons/ids.json` and
  `build/tool-icons/uploads.jsonl`. Keep their formats.

## Steps

1. Serve the art: run `node tools/serve.js` in the background. It serves the repo
   root on port 7421.
2. Check Studio is open on the place (`list_roblox_studios`, then
   `get_studio_state`). If no place is open, stop and report **BLOCKED: open the
   place in Studio**.
3. Upload each PNG with `upload_image`, using the URL
   `http://localhost:7421/art/tool-icons/<family>/<file>`.
   - Record every result as you go:
     - `ids.json`: under `"drill"` and `"explosive"`, keyed by tier, as
       `{ "id": "<number>", "ore": "<ore id>" }`. This is the same shape as
       `"pickaxe"`.
     - `uploads.jsonl`: one line per batch, mapping each URL to its
       `rbxassetid://`.
   - The run must be safe to resume: skip any tier already in `ids.json`.
   - If an upload fails, retry it once, then list it in the report and move on.
4. Add lines to the end of `build/hammer-icons/share-list.txt`, in the existing
   format. This is the owner's list of images to share in the Creator Hub.
   - Drills: `drill_NN_<ore><TAB>rbxassetid://<id>`
   - Explosives: `explosive_NN_<ore><TAB>rbxassetid://<id>`
5. In `src/ReplicatedStorage/Mine/Shared/MineIcons.luau`:
   - Add `MineIcons.ORE_DRILL_CANVA` and `MineIcons.ORE_BOMB_CANVA`, tiers 1-81,
     just after `ORE_PICK_CANVA`. Write them in its style:
     `[n] = "rbxassetid://ID", -- Ore Name`, under a short comment block that
     quotes the owner.
   - Inside the existing `if MineIcons.NEW_TOOL_ICONS_SHARED then` block, lay
     them over `ORE_DRILL` and `ORE_BOMB` the same way the pickaxe loop lays
     `ORE_PICK_CANVA` over `ORE_PICK`.
   - **Do not set `NEW_TOOL_ICONS_SHARED` to true.** The owner must share the
     uploads first.
6. In `tools/verify/oreskins.js`:
   - Add `ORE_DRILL_CANVA` and `ORE_BOMB_CANVA` to the coverage loop, with tier
     82 as the allowed gap, like `ORE_PICK_CANVA`.
   - Check that both overlay loops exist.
   - Keep the "shares no asset" check meaningful: new ids must not repeat any
     other table's id.
7. Wiki: update `wiki/systems/tools.md` and `wiki/code/assets-and-uploads.md`
   wherever they list which icons are uploaded or still to come. Add a
   `wiki/log.md` entry.
8. Run `node tools/verify/oreskins.js`, `node tools/verify/compile.js`,
   `node tools/verify/wiki.js` and the full suite. Commit only the files above.
   - `build/` is untracked; do not add it.
   - Stop the `serve.js` process when you are done.

## Do not

- Do not regenerate or edit any image.
- Do not touch the hammer or jackhammer tables. Jackhammers 75-82 are still
  missing; that is a separate job.

## Put these in the report for the owner to look at

Do not fix these. The Canva run flagged them:
- **Explosives 19, 29, 65, 67, 68, 71 and 77:** background removal clipped the
  fuse spark.
- **Pickaxes 52 and 57:** the heads read a little like axes.
- **The reminder:** share the new uploads in the Creator Hub
  (`build/hammer-icons/share-list.txt`). Then switch on
  `MineIcons.NEW_TOOL_ICONS_SHARED`, or ask Claude to.
