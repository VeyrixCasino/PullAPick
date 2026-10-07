---
title: Admin and debug
type: system
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - src/ServerScriptService/Mine/Admin/MineAdmin.luau
  - src/ServerScriptService/Mine/Admin/AdminAllowlist.luau
  - src/StarterPlayer/StarterPlayerScripts/MineAdminClient.client.luau
  - src/ServerScriptService/Mine/MineAntiGear.luau
  - src/ReplicatedStorage/Mine/Shared/MineStudioGrant.luau
  - src/ReplicatedStorage/MineGear_AdminTest.luau
  - src/ReplicatedStorage/MineBags_NameCheck.luau
  - src/ServerScriptService/TCGServer/AfkService.server.luau
  - src/ServerScriptService/TCGServer/PortalService.server.luau
  - src/ReplicatedStorage/TCG/Shared/PlaceConfig.luau
  - src/ReplicatedStorage/Mine/Shared/MineBuild.luau
  - docs/AUDIT.md §5
related: [shops-and-monetisation, social-quests-and-leaderboards, retired-and-parked]
---

# Admin and debug

> These are the tools for the owner and developers, not for players: an admin
> grant panel, an anti-exploit tool filter, a Studio save reset, leftover test
> scaffolding, and the TCG Life place services this game was built on top of.

`MineServer` below means `src/ServerScriptService/Mine/MineServer.server.luau`.

## How it works

**Admin panel.**
- **Who is an admin.** The list of numeric UserIds lives in
  `src/ServerScriptService/Mine/Admin/AdminAllowlist.luau` (`ADMIN_USER_IDS`,
  checked by `AdminAllowlist.isAdmin`). It is server-only, so clients can't
  require it. Ids are not repeated here.
- **Startup.** MineServer's last block calls `MineAdmin.start(deps)`. It creates
  the remotes `AdminReady`, `AdminNotify` and `AdminInvoke` under
  `ReplicatedStorage.Mine.Remotes`. **Every call re-checks the allowlist.**
- **Actions** on `AdminInvoke`: `isAdmin`, `catalog`, `refresh`,
  `unlockAllZonesDepths`, `forgeItem`, `grant` and `resetSave`.
  `forgeItem` creates admin-made items whose ids start with the reserved prefix `adm_`.
- **Chat.** `/admin` or `/mineadmin` with `give <who> credits|coins|gems|dust|skill|temper <n>`,
  `pack`, `zone`, `tool`, `alltools` or `say`. Both `Chatted` and `TextChatCommand` are hooked.
- **Limits:** `MAX_GRANTS_PER_MINUTE` 40, `MAX_CURRENCY` 1e12, `MAX_PACK_QTY` 50.
  A player who makes 5 unauthorised calls is kicked. Actions are logged through `adminLog`.
- **The UI.** `MineAdminClient` is cosmetic only. It shows nothing until the
  server fires `AdminReady(true)`, and opens with F8 or a corner button.

**Anti-gear.** `MineAntiGear` removes Roblox catalog and StarterGear tools:
btools, F3X, hammer, clone and similar. A game-made Tool must call
`MineAntiGear.mark()` **before** it is parented, or it is removed too. MineServer
calls `MineAntiGear.start()`. Avatar clothes and accessories are left alone.

**Studio reset.** `MineStudioGrant.playtestReset` works only in Studio:
1. In Edit mode, set the `ForcePlaytestReset` attribute on `ReplicatedStorage.Mine`.
2. Press Play once. The next join gets a clean starter profile.

A DataStore marker (`Mine_StudioFlags`) makes each enable fire only once.
Despite the name, it grants nothing.

**Studio isolation.** Studio sessions write to `_Studio` copies of the stores:
social and leaderboard stores, Discord and flag stores, and saves
(`MineConfig.storeName`). Testing never touches live data.

**Build stamp.** `MineBuild.STAMP` and `EXPECT` print a warning when Studio is
running older code than `src/` (TODO §0.14). Covered in
[rojo-and-studio](../code/rojo-and-studio.md).

**Moderation hooks:**
- `LeaderboardService` holds a banned-user list in-file.
- `MineDiscordLink.flag` writes suspicious deep digs to `Mine_v1_flags` for the
  Discord bot. It is not an auto-kick.

See [social-quests-and-leaderboards](social-quests-and-leaderboards.md).

### TCG Life leftovers (`TCGServer/`, `ReplicatedStorage/TCG/`)
| file | what it does in this place |
|---|---|
| `src/ServerScriptService/TCGServer/AfkService.server.luau` | AFK-lounge coin faucet. It **returns at once** unless `PlaceConfig.isAfk()`, so it is inert here. |
| `src/ServerScriptService/TCGServer/PortalService.server.luau` | Teleports through parts tagged `PortalTarget` to the city, exchange or AFK places. It shuts portals whose place is not configured. |
| `Progression`, `Wallet`, `BattlePass` | AFK-place shims. `BattlePass.addXp` is a no-op stub. |
| `TCG/Shared/PlaceConfig`, `MarketConfig` | Place ids and AFK tick numbers. `MAIN_PLACE_ID` is not this game's placeId. |
| `src/StarterPlayer/StarterPlayerScripts/TCGAfkClient.client.luau` | AFK HUD. It exits unless this is the AFK place. |

In-game AFK is a different system: `Verbs.Afk` in MineServer, with the AfkChill
pad and the VIP AFK bonus.

## Where it lives
| file | role | key symbols |
|---|---|---|
| `src/ServerScriptService/Mine/Admin/MineAdmin.luau` | grant backend | `start`, `ADMIN_ITEM_ID_PREFIX`, `MAX_GRANTS_PER_MINUTE` |
| `src/ServerScriptService/Mine/Admin/AdminAllowlist.luau` | the UserId list | `isAdmin` |
| `src/StarterPlayer/StarterPlayerScripts/MineAdminClient.client.luau` | admin UI | `AdminReady`, `AdminInvoke` |
| `src/ServerScriptService/Mine/MineAntiGear.luau` | tool filter | `mark`, `start`, `TAG` |
| `src/ReplicatedStorage/Mine/Shared/MineStudioGrant.luau` | Studio reset | `playtestReset` |

## Decided by the owner
No admin-specific decisions are recorded. AUDIT §5 puts `MineGear_AdminTest` and
`MineBags_NameCheck` on the **DELETE** list as *"test scaffolding in
ReplicatedStorage, shipped to every client"*. That is a proposal, and both files
are still there.

## State right now
- **Unchanged since the import** (`566eecf`): the admin, anti-gear and Studio-reset code.
- **Dead scaffolding.** Nothing requires these root-level `ReplicatedStorage`
  files (static grep):
  - `src/ReplicatedStorage/MineGear_AdminTest.luau` and `src/ReplicatedStorage/MineGear.luau`, two old gear copies. Both
    require `MineRunes` from `ReplicatedStorage`'s root, where there is no such
    module, so either would hang if required.
  - `src/ReplicatedStorage/MineBags_NameCheck.luau`.
  - `src/ReplicatedStorage/MineBagNames.luau`, byte-identical to the `Shared` copy.

## Gotchas
- **`AdminAllowlist`'s header still says "Dig for Cards"**, an old name for the game.
- **Do not move the allowlist to `ReplicatedStorage`.** Its own header says so: clients could then read it.
- **Admin grants are not purchases.** They skip `ProcessReceipt` and `p.receipts`.
- **Mark game tools before parenting.** Code that creates a Tool without
  `MineAntiGear.mark()` first has that tool deleted on the spot.

## Open questions
- Delete the root-level scaffolding now, or wait for the cut-list sign-off (AUDIT §5)?
- Are the TCG Life services still needed by the published place (portals to an AFK lounge)? Unverified.

## See also
[shops-and-monetisation](shops-and-monetisation.md) · [retired-and-parked](retired-and-parked.md) · [code-map](../code/code-map.md) · [server](../code/server.md) · [rojo-and-studio](../code/rojo-and-studio.md)
