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
