---
title: Rojo and Studio
type: code
status: current
verified: 2026-10-08 @ ea255bb
sources:
  - default.project.json
  - rokit.toml
  - AGENTS.md
  - docs/rojo-connect.md
  - docs/TODO.md §0.14, §0.32, §1, §2
  - tools/export/sync.ps1
  - tools/export/export.luau
  - .vscode/tasks.json
  - src/ReplicatedStorage/Mine/Shared/MineBuild.luau
related: [code-map, local-setup, client-and-ui, assets-and-uploads]
---

# Rojo and Studio

> The repo is the source of truth for **code**. The place file is the source of
> truth for the **world**. Rojo pushes `src/` into Studio. It never pulls back,
> and it never deletes what it does not manage.

## The mapping

- `default.project.json` maps six folders onto services. The table is in
  [code-map](code-map.md) and AGENTS.md.
- **Every** service node sets `"$ignoreUnknownInstances": true`, including
  `StarterPlayer` and both of its children.
- Rojo is pinned to 7.7.0 in `rokit.toml`; run `rokit install`.
- VS Code tasks are in `.vscode/tasks.json`:
  - "Rojo: serve" (the default build task)
  - sourcemap watch
  - build place file, which writes the gitignored `*.rbxl`
  - the two syncback steps

## What lives only in the place file

Workspace (the map, the mine, the outpost), Lighting, Teams, TextChatService,
`ReplicatedStorage.ToolModels_50` (about 80 MB of tool meshes) and
`ServerStorage.OreShapes` are **not in git** (AGENTS.md, TODO §1). So **`rojo build`
from this repo makes a place that opens with no game in it.** That is not a bug.
You need the real place file plus a Rojo sync (TODO §0.32, START-HERE §3).

## The loss matrix (`docs/rojo-connect.md`)

| thing | on connect |
|---|---|
| Workspace, Lighting, Teams, TextChatService | untouched |
| `ToolModels_50`, `OreShapes`, other place-only folders | untouched |
| an instance added in Studio under a managed folder | kept |
| a script that exists in both Studio and `src/` | **overwritten by `src/`** |
| a script edited in Studio and never synced back | **lost** |

Only the last row is a real risk.

- **Before connecting:** save a `.rbxl` backup outside the repo, and run a
  syncback if anyone has edited scripts in Studio.
- **Never** hand-edit a `.rbxm` file. `.claude/settings.json` denies it.

## Syncback: pulling Studio into `src/` (`tools/export/`)

This needs Studio on the owner's machine. A cloud agent cannot do it (BLOCKED #13, TODO §2).

1. `pwsh -NoProfile -File tools/export/receiver.ps1`. This listens on
   `localhost:34999` and writes chunks into `tools/export/in/`.
2. Run `tools/export/export.luau` in Studio, either from the command bar or with
   Studio MCP `execute_luau` against Edit. It serialises the five services and
   POSTs them in chunks of about 900 KB.
3. Stop the receiver, then run `pwsh -NoProfile -File tools/export/sync.ps1`.
   This script:
   - reassembles the parts
   - runs `rojo build combine.project.json`
   - runs `rojo syncback sync.project.json`
   - deletes `ToolModels_50`
   - **deletes the whole `tools/export/in/` folder**
4. Commit, then connect.

**Hazard.** `CLAUDE.md` says Claude.ai chat exports may also be placed in
`tools/export/in/`. Step 3 runs `Remove-Item $in -Recurse -Force` on that folder,
so it would delete any exports sitting there. Move them out before a syncback.

Syncback captures **everything** in those services, including agent state files
and scratch copies. That is how the leftovers listed in [code-map](code-map.md)
got into git: they all arrived in the first import, `566eecf` (2026-09-27).
The last full syncback was `0122667` (2026-09-28, per `docs/rojo-connect.md`).

## "Studio may be running older code than `src/`"

Rojo uses `$ignoreUnknownInstances`, so a Studio that is **not** connected keeps
running whatever scripts were last written into the place, with no warning.

- TODO §0.14: twice the owner reported "no Forge". Both times the Forge was in
  the repo, and the Studio was running code from before `0122667`.
- The fix is never in `src/`. Run `git pull` in the clone that `rojo serve` uses,
  then reconnect the plugin.
- To date a running build: ask what the on-screen tabs say, or run
  `git log --all -S'<string from the screenshot>'`. (That is git syntax for an
  agent's shell. Do not hand it to the owner as written; see [local-setup](local-setup.md).)

**The build stamp.**

- `MineBuild.announce` runs first in MineClient.
- It prints `MineBuild.STAMP`, which is a hint a human maintains.
- It also checks `MineBuild.EXPECT` against the live DataModel. That check is the
  proof: a Studio missing MineForge warns "MISSING MineForge".
- `tools/verify/build-stamp.js` keeps the list real.
- **Bump `MineBuild.STAMP` when `src/` ships.** At `26036a0` it still reads
  `"2026-10-04 traits + centred pets"`, which is older than the 2026-10-05 UI and
  vein commits.

## Studio and Cursor at the same time

Studio and Cursor edit the same scripts at the same time (TODO §9). Anchor every
edit on unique surrounding text, never on line numbers, and re-read a file before
committing. `tools/port-studio-edits.js` is an example of carrying Studio-only
edits back into `src/`, and it is a one-off.

## Gotchas

- **Never run a branch checkout in the tree `rojo serve` is serving without
  re-checking what Studio holds afterwards** (`8d5c230`). `git checkout main`
  there rewrote every file to PR #5's state, Studio synced it, and the plugin
  dropped before the tree came forward. Two console errors the author spent time
  on (`givePickaxe` and `snap` calling nil) were just calls into code Studio did
  not have yet. This is the "Studio may be running older code" trap above.
- **Some changes cannot live in the repo.** `Lighting` is place-only, so the
  shadow removal (`8d68717`: *"remove shadows peroid"*, one property,
  `Lighting.GlobalShadows = false`) was applied in Studio, not in `src/`. The
  only `GlobalShadows` in `src/` is a scratch icon-capture script. *(Inferred
  from that grep; not confirmed with the author.)* Dev scaffolding folders in
  Workspace (pet and ore showcases, tool racks) are stripped at server start
  rather than deleted, so the place file keeps them for authoring.
- `docs/rojo-connect.md` says `rojo serve` "has never been attached". TODO §0.14
  shows that Rojo was being served later. Treat that line as stale.
- The file counts in `docs/rojo-connect.md` (199 `.luau`) are stale. The current
  counts are in [code-map](code-map.md).
- `sourcemap.json` and `*.rbxl` are gitignored. The Luau LSP regenerates the
  sourcemap (`.vscode/settings.json`).
