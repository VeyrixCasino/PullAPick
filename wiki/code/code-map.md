---
title: Code map
type: code
status: current
verified: 2026-10-08 @ bae3c5b
sources:
  - default.project.json
  - AGENTS.md
  - docs/START-HERE.md §3
  - docs/HANDOFF.md §2.2
  - docs/AUDIT.md §5
  - docs/TODO.md §1, §4
related: [server, client-and-ui, rojo-and-studio, tools-and-generators, verify-suite, retired-and-parked]
---

# Code map

> Where everything lives, folder by folder, and which files are the game versus
> leftovers. At `26036a0`, `src/` holds 212 `.luau`, 581 `.rbxm`, 396 `.json`
> and 75 `.txt` files (counted with `find`). Older docs say 199 or 210 `.luau`.

## Top level

| path | what it is |
|---|---|
| `src/` | the Roblox source. Rojo maps it onto services (table below). |
| `default.project.json` | the Rojo map. Every service node sets `$ignoreUnknownInstances`. See [rojo-and-studio](rojo-and-studio.md). |
| `rokit.toml` | pins Rojo 7.7.0 (`rokit install`). |
| `docs/` | current docs: `docs/START-HERE.md` is the front door, `docs/TODO.md` §0 holds the locked rules. See [sources-of-truth](../sources-of-truth.md). |
| `roadmap/` | direction docs from a merge. TODO §0 outranks them, and `roadmap/ORE.md` is marked OVERRULED. |
| `tools/` | Node generators, one-off patch scripts, calculator pages, and the `tools/verify/` checks. See [tools-and-generators](tools-and-generators.md) and [verify-suite](verify-suite.md). |
| `build/` | generated art and data. Some is tracked, some is gitignored. See [assets-and-uploads](assets-and-uploads.md). |
| `wiki/` | this wiki (`wiki/SCHEMA.md`). |
| `.claude/`, `.vscode/` | agent permissions and hooks, VS Code tasks. See [local-setup](local-setup.md). |

## `src/` → Roblox services (`default.project.json`)

| folder | service | what lives there |
|---|---|---|
| `src/ReplicatedFirst` | ReplicatedFirst | `MineLoadingScreen.client.luau` only: the loading splash. |
| `src/ReplicatedStorage` | ReplicatedStorage | shared modules, views and models (below) |
| `src/ServerScriptService` | ServerScriptService | the server, under `Mine/`, plus legacy `TCGServer/` |
| `src/ServerStorage` | ServerStorage | Studio-only bakers and tools, parked features, and a lot of leftovers |
| `src/StarterPlayer/StarterPlayerScripts` | StarterPlayer.StarterPlayerScripts | the client |
| `src/StarterPlayer/StarterCharacterScripts` | StarterPlayer.StarterCharacterScripts | empty (`.gitkeep`) |

File suffixes: `*.server.luau` is a Script, `*.client.luau` is a LocalScript,
plain `*.luau` is a ModuleScript, and a folder holding `init.luau` is a script with
children (AGENTS.md).

## ReplicatedStorage

**`src/ReplicatedStorage/Mine/Shared/`** is where most design work happens. It has
94 entries: data modules (`MineConfig`, `MineDepth`, `MineStats`, `MineTraits`,
`MineCharms`, `MinePackConfig`…) and the client **views** (`*View.luau`, `MineForge`,
`MineHotbar`, `MineUI`, `MineTheme`). The largest, by lines:

| module | lines | note |
|---|---|---|
| `MineInventoryView` | 7,867 | the one big window for packs, cards, chests, shop and passes |
| `MineConfig` | 3,805 | zones, ores (`MineConfig.ORES`, 82 rows), tools, the migration tables, the DataStore name |
| `PetModelFactory` | 3,241 | the procedural pet builder |
| `MinePackConfig` | 2,725 | packs |
| `MineShopView` | 2,483 | the shop. It hosts the Forge and Ore Pouch tabs. |
| `MineToolIcons`, `MineOreArt` | 106 KB, 133 KB | data blobs. `MineOreArt` is packed pixels for block faces. |

`MineSkillData` and `MineTools` carry a GENERATED header. The skill tree
is rebuilt by `tools/skills/gen.js`. The generator for `MineTools` is missing (HANDOFF §2.3).

Other ReplicatedStorage contents:

- `src/ReplicatedStorage/ToolModelFactory.luau`: 108 KB of procedural tool models.
  It is live, with about 65 files referring to it.
- `src/ReplicatedStorage/Mine/NewGear/`: the hat and face catalog, with 420 `.rbxm`
  files. `MineInventoryView` reads it.
- `Mine/PetModels` (43 `.rbxm`), `Mine/BagModels` (2), `Mine/ToolPreviews` (11),
  `ToolKitMeshes/{Swing,Drill,Explosive}` (102 `.rbxm`).
- `Mine/Remotes/` is an empty folder in git. `MineNet` and the `Admin*` remotes are
  created at runtime by the server ([server](server.md)).
- `TCG/` is legacy from the "TCG Life" place this game came out of: `PlaceConfig`,
  `MarketConfig` and an empty `Remotes/`.

## ServerScriptService

- `src/ServerScriptService/Mine/MineServer.server.luau`: **the whole game server**,
  17,714 lines (17,050 at `26036a0`). See [server](server.md).
- **New 2026-10-07:** `MineTraderNPC` (the five wandering traders' bodies, prompt and
  roster check: [wandering-traders](../systems/wandering-traders.md)). Shared:
  `MineTrader` (the rules), `MineLaunch` (the season clock:
  [season-and-launch](../systems/season-and-launch.md)). `MineDigAuth` gained
  `canCreditDepth` and `chunkCeiling` ([zones-layers-and-seams](../systems/zones-layers-and-seams.md)).
- Other modules in `Mine/`: `MineDigAuth`, `MineDepthPlazas` (outposts, elevator
  rides), `MineDepthLive`, `WorldBuilder` (builds the map at boot), the zone themes
  `MineHarbor`, `MineBloodLake` and `MineEventHorizon` (loaded by `WorldBuilder` per
  zone), `MineThemeKit`, `MineShopFronts`, `MineEdgeBarriers`, `MinePlayerCollision`,
  `MinePatterns`, `MineAntiGear`, `MineBadges`, `MineBigNum`, `TradeService`,
  `SocialService`, `GroupWheelService`, `LeaderboardService/` and `Admin/`
  (`MineAdmin`, `AdminAllowlist`).
- `TCGServer/` is dormant legacy from the AFK place. `AfkService.server.luau` and
  `PortalService.server.luau` are `Disabled: true` in their `.meta.json`.
  `Wallet`, `Progression` and `BattlePass` are only required by the disabled AfkService.

## StarterPlayerScripts

`MineClient.client.luau` (12,488 lines) is the client; see [client-and-ui](client-and-ui.md).
Alongside it: `MineAdminClient` (the admin panel), `MineAmbience` (client-side bobbing
and other motion), `MineDiscordLinkClient`, and `LoadPlayerModule` (boots the default
PlayerModule so WASD and the camera work). `TCGAfkClient` is disabled by its
`.meta.json`. `TCGUI/` is an empty folder.

## Live versus leftovers

Nearly everything below came in with the first Studio import, `566eecf`
(2026-09-27), which copied all of Studio into `src/` (see [rojo-and-studio](rojo-and-studio.md)).

| what | status | evidence |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/_c.luau` | dead 1,710-line copy of MineConfig. Nothing requires it. | AUDIT §5, OPEN Housekeeping |
| `src/ServerScriptService/Mine/MineDepthPlazas_OLD_pre_v4.luau` | superseded, and nothing refers to it | AUDIT §5, grep |
| `src/ServerScriptService/Mine/MineDiscordBridge.server.luau` | a stub that only prints "idle" | file header |
| `src/ReplicatedStorage/MineGear_AdminTest.luau`, `MineBags_NameCheck.luau` | old copies of the modules, at the RS root. They require siblings that do not exist there. | AUDIT §5, file headers |
| `src/ReplicatedStorage/MineGear.luau`, `MineBagNames.luau` (RS root) | stale or byte-identical copies of the `Mine/Shared` modules. **Not on AUDIT's list.** | md5sum |
| `src/ServerStorage/chk_824649944.luau`, `rig_545528744.luau` | numbered scratch copies of PetModelFactory | AUDIT §5 |
| `CaptureToolIcons`, `CaptureToolIconsFresh`, `CaptureToolIcons_Live` | three byte-identical Studio scripts | md5sum, AUDIT §5 |
| `ServerStorage/Wave13Batches`, `Wave14Batches`, `Wave14Existing`, `Wave12*.luau` | batches from mesh-generation jobs (GenerationService prompts) | file contents |
| `ServerStorage/_AgentDump`, `_ToolRenameMap`, `_ToolFolderNames`, `_Icon*`, `_HQInstall*`, `_UniqueInstallProgress*` | state files and dumps from Studio agents | names, contents |
| `ServerStorage/ToolGenerationQueue.rbxm`, `ToolGenerationLeftovers.rbxm` | 2.4 MB and 5.7 MB of models | sizes |
| `LeaderboardService/_Bak/`, `Shared/MineEventsView/_Export/`, `ReplicatedStorage/_MassPipe/` | chunked text backups | contents |
| empty folders: `_BagProbe`, `_CursorSrc`, `_AudioPush`, `_BakerB64`, `_EMKeep`, `_PB_PUSH`, `BlockLuaScripts`, `ToolKitEditableMeshes`, `Shared/_PetBoostChunks`; zero-byte `IconCaptureRunner.luau`, `_ToolRenameMapMod.luau`, `_MineHatsB64.txt` | placeholders | `ls -la` |
| `src/ServerStorage/OreToolBaker.luau` | committed, but nothing requires it. It has its own 82-row roster. | TODO §4 (corrected 2026-10-05), BLOCKED #14 |
| `src/ServerStorage/OreBalanceSim.luau` | an offline sim. It reads five MineConfig symbols that no longer exist. | BLOCKED, "Broken, not blocked" |
| `src/ServerStorage/MineParked/GroupWheel/` | the parked group wheel. The live `GroupWheelService` is still routed (`spin`), but the lobby build call is commented out in MineServer. | README.txt, grep |
| `MineBenchView` | superseded by the Forge (AUDIT says "already unmounted") | AUDIT §5 |

The Studio bakers in ServerStorage (`OreToolBaker`, `UniqueToolBaker`,
`ExplosiveMeshBaker`, `ToolKitProceduralBake`, `BagMeshPrompts`) are tools, not
game code. AUDIT §5 says to keep them where they are.

**Not in git at all** (place file only): Workspace, Lighting, Teams,
TextChatService, `ReplicatedStorage.ToolModels_50` (about 80 MB) and
`ServerStorage.OreShapes` (AGENTS.md, TODO §1).

## Gotchas

- The owner proposed the cut (TODO §0.26), and AUDIT §5 lists what to delete.
  At `26036a0` none of the deletes have been done. Do them in one commit, and
  grep for `require` first. For example, `MineShopLadders` looks for
  `ApplyToolRename` in both `Shared/` and `ServerStorage/`, and the two copies
  are identical.
- MineServer and MineClient have both hit Luau's 200-local ceiling. See [luau-traps](luau-traps.md).
