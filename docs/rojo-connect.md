# Connecting Rojo without losing Studio work

`rojo serve` has never been attached from Studio, so none of the committed source is
live yet. Connecting is safe, but the order matters. Read the loss matrix first.

## The one rule

**Rojo only touches what it manages.** Every service node in `default.project.json`
sets `$ignoreUnknownInstances: true`, so Rojo never deletes an instance it does not
own. What it *will* do is overwrite a managed instance with the file on disk.

So the danger is never "Studio loses something Rojo doesn't know about". It is
"a script you edited in Studio, and never synced back, gets replaced by the older
version in `src/`".

## Loss matrix

| Thing | On connect | Why |
| --- | --- | --- |
| Workspace, Lighting, Teams, TextChatService | **Untouched** | Not in the project tree at all |
| `ReplicatedStorage.ToolModels_50` (~80 MB) | **Untouched** | Studio-only, `$ignoreUnknownInstances` |
| `ServerStorage.OreShapes` and other place-only folders | **Untouched** | Same |
| Any instance you added in Studio under a managed folder | **Kept** | Same |
| A script that exists in both Studio and `src/` | **Overwritten by `src/`** | Rojo manages it |
| A script you edited in Studio but never synced back | **Lost** | Overwritten by the older file |

Only the last row is a real risk, and the procedure below removes it.

## First connect

1. **Save a place backup.** In Studio: File -> Save to File As, keep the `.rbxl`
   somewhere outside the repo. `*.rbxl` is gitignored, so it will not be committed.
   This is the only true undo.
2. **Decide whether Studio has unported edits.** The last sync was commit `0122667`.
   If anyone has edited scripts in Studio since, run the syncback first (next section),
   commit the result, and only then connect.
3. **Install the pinned toolchain:** `rokit install` (gets Rojo 7.7.0).
4. **Serve:** `rojo serve default.project.json`, or in VS Code press
   Ctrl+Shift+B ("Rojo: serve").
5. **Connect** from the Rojo plugin in Studio.
6. **Spot-check** one file you know the contents of before trusting the rest.

## Pulling Studio's state into `src/` (syncback)

Run this *before* connecting if Studio is ahead. From `tools/export/`:

1. Start the receiver: `pwsh -NoProfile -File tools/export/receiver.ps1`
   (listens on `http://localhost:34999`).
2. Run `tools/export/export.luau` in Studio — command bar, or the Studio MCP
   `execute_luau` against the Edit datamodel.
3. Stop the receiver, then run `pwsh -NoProfile -File tools/export/sync.ps1`.

`sync.ps1` reassembles the chunked `.rbxm` parts, builds `combined.rbxm`, runs
`rojo syncback`, then deletes `ToolModels_50` (80 MB, deliberately Studio-only) and
clears the inbox. VS Code has both steps as tasks.

Commit the result before connecting, so the overwrite direction is a no-op.

## VS Code

`.vscode/extensions.json` recommends Rojo, Luau LSP and StyLua. Luau LSP is wired to
autogenerate a sourcemap from `default.project.json`, which is what gives you
cross-module type info across the 199 `.luau` files. `sourcemap.json` is gitignored.

Tasks: serve (default build task), sourcemap watch, build place file, and the two
syncback steps.

## Never

- Hand-edit a `.rbxm`. There are 581 of them and they are binary; `.claude/settings.json`
  denies it. Model changes are a Studio job.
- Connect with unported Studio edits outstanding. That is the one way to lose work.
