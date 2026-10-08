# Mine For Cards (Roblox, Rojo project)

Source for the Roblox place "⛏️ MINE FOR CARDS! 🃏 SEASON ONE" (placeId 73982848847016), synced with [Rojo](https://rojo.space) 7.7.

## Layout

`default.project.json` maps folders to services:

| Folder | Roblox service |
| --- | --- |
| `src/ReplicatedFirst` | ReplicatedFirst |
| `src/ReplicatedStorage` | ReplicatedStorage |
| `src/ServerScriptService` | ServerScriptService |
| `src/ServerStorage` | ServerStorage |
| `src/StarterPlayer/StarterPlayerScripts` | StarterPlayer.StarterPlayerScripts |
| `src/StarterPlayer/StarterCharacterScripts` | StarterPlayer.StarterCharacterScripts |

File conventions:

- `*.server.luau` = Script, `*.client.luau` = LocalScript, plain `*.luau` = ModuleScript.
- A folder with `init.luau` / `init.server.luau` / `init.client.luau` is a script with children.
- `*.rbxm` = binary model (parts, meshes, UI). Edit these in Studio, not by hand.
- `*.meta.json` / `*.model.json` = instance properties and attributes.
- `*.txt` = StringValue.

Not in the repo (lives only in the place file): Workspace (map), Lighting, Teams, TextChatService, and `ReplicatedStorage.ToolModels_50` (80 MB of generated tool models). Every service node uses `$ignoreUnknownInstances`, so Rojo never deletes Studio-only instances.

## Workflow

1. `rojo serve` in the repo root.
2. In Studio, open the Rojo plugin and click Connect. File edits sync into Studio live.
3. Changes made in Studio are not written back automatically. To pull Studio's current state into `src/`, follow the steps at the top of `tools/export/sync.ps1`.

## Ask first, always

**The owner's standing instruction (2026-10-08): hound them with questions so nothing is EVER unclear.** If you would otherwise be guessing what they want or mean, ask, however small it looks.

- Look in the repo first and never ask what it can answer. Put what you found in the question.
- Before non-trivial work, restate in 1-3 lines what you will change, what you will leave alone, and your assumptions.
- Ask every question you need in one batch, grouped by topic, each multiple choice with your recommended default first. There is no cap. Wait for the answers, and ask again if they open new doubts.
- Stop and ask the moment a new doubt appears mid-task. When you finish, list your assumptions and ask what is still unclear.
- Do not re-ask decisions locked in `docs/TODO.md` section 0, but do ask whether one applies, or whether new work might conflict with one.
- If nobody can answer (background run, scheduled check-in, subagent), take only safe reversible steps and write the questions down. A subagent puts its questions at the top of its report for the parent to ask.

The full rules are in `CLAUDE.md`.

## Knowledge base

`wiki/` is an LLM-maintained knowledge base for this game. Start at `wiki/index.md`. Its rules are in `wiki/SCHEMA.md`. Code and the owner's decisions outrank it, so fix a page when you find it wrong. `wiki/ambiguous-terms.md` lists the words that mean several things here, which are always worth a question.
