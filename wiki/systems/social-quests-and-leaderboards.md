---
title: Social, quests and leaderboards
type: system
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - src/ServerScriptService/Mine/SocialService.luau
  - src/ReplicatedStorage/Mine/Shared/MineSocialView.luau
  - src/ReplicatedStorage/Mine/Shared/MineProfileView.luau
  - src/ReplicatedStorage/Mine/Shared/MineQuests.luau
  - src/ReplicatedStorage/Mine/Shared/MineContractor.luau
  - src/ServerScriptService/Mine/LeaderboardService/init.luau
  - src/ServerScriptService/Mine/MineBadges.luau
  - src/ReplicatedStorage/Mine/Shared/MineFounders.luau
  - src/ServerScriptService/Mine/GroupWheelService.luau
  - src/ReplicatedStorage/Mine/Shared/MineGroupWheel.luau
  - src/ServerStorage/MineParked/GroupWheel/README.txt
  - src/ReplicatedStorage/Mine/Shared/MineDiscordLink.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - docs/OPEN.md P1 §16, P2
  - docs/AUDIT.md §5
related: [shops-and-monetisation, trading, world-events, rebirth-and-skill-tree, cards-and-packs]
---

# Social, quests and leaderboards

> This page covers the parts of the game that are not mining:
> - **friends and chat** (built, but no screen opens them);
> - **quests** and the **Job Board**;
> - **leaderboards**, including depth;
> - **badges**, **Founders**, the **group wheel**;
> - the **Discord link**, **invites** and **codes**.
>
> Most of it was inherited from the import and has not been reworked on this branch.

`MineServer` below means `src/ServerScriptService/Mine/MineServer.server.luau`.

## How it works

**Social.** `SocialService` handles friends, DMs, global chat and player groups
across servers, using MessagingService plus DataStores (`Mine_v1_friends`,
`Mine_v1_inbox`, `Mine_v1_groups`). It adds a `_Studio` suffix in Studio, and text
goes through `TextService:FilterStringAsync`. MineServer routes the actions
`friendRequest`, `profileView` and the others to it.
**The client never shows any of it** (static grep):
- `MineSocialView` is required by nothing.
- `MineProfileView`, which has the friend, trade and coinflip buttons, is required by nothing.
- MineClient has no `profileView` handler.

**Quests** (`MineQuests`, claimed through `Verbs.claimQuest`, `Verbs.claimDailyQuest`, `Quests.svClaimContract` and `Quests.svClaimMilestone`):

| kind | what | symbol |
|---|---|---|
| chain | a ladder of about 50 rungs, one at a time; progress counts from when a quest goes active (`questBase`) | `CHAIN`, `COUNT` |
| milestones | lifetime thresholds, claimable any time | `MILESTONES` |
| dailies | 3 a day on the UTC-day boundary, scaled by zone | `DAILY_POOL`, `DAILY_COUNT`, `rollDaily` |
| contracts | 3 Job Board jobs a day | `CONTRACT_POOL`, `CONTRACT_COUNT` |
| playtime | rewards for time played | `PLAYTIME` |

There is also a daily login streak (`Verbs.claimDaily`), and its day 4 pays a
surprise pack (`Verbs.claimDailySurprise`).

**Job Board.** `MineContractor` shows every quest in one place, plus the
battle-pass XP each one feeds. It opens from the world pad (machine `contractor`)
and from the Jobs dock button, and is mounted as `depthHud.contractor`.

**Leaderboards.** `LeaderboardService` keeps global OrderedDataStore boards:
- `Mine_v1_lb_prestige`, `_gems` and `_stardust_value`;
- one depth board per zone, `Mine_v1_lb_depth_<zone>`.

They are painted on lobby pedestals and podiums.
- **Probe first.** `dataStoresUsable` checks once that DataStores are reachable,
  so Studio prints one warning instead of fifty.
- **Banned list.** A list of banned UserIds lives in the file; ids are not repeated here.
- **Rewards text.** `rewardForRank` returns reward strings for display only. Its
  comment says *"payout is separate"*, and no payout code was found.

**How depth reaches the board.** Each time a dig sets a new personal deepest
(`Dig.Auth.creditDeepest`), MineServer calls `LeaderboardService.queueDepth`,
then `flushAndPaintDepth` and `refreshDepthBoards`. **So the board does update
live in code.** OPEN #16 ("Live update") may already be done. It needs an
in-engine check.
- **Deep-dig flag.** A dig far below the server's dug depth writes a row through
  `MineDiscordLink.flag("deep_dig", …)` to `Mine_v1_flags`, for the Discord bot to
  read. This replaced an auto-kick that ejected honest players. It only flags.

**Badges.** `MineBadges.BADGE_IDS` defines 10 Roblox badges: welcome,
fresh_bread, first_dig, pack_opener, meadow_bound, zone_hopper, and
blockbuster_i–iv at 1k / 10k / 100k / 1M blocks. They are awarded from
`bumpStat`, from entering a zone and from unlocking one.

**Founders.** `MineFounders` handles a membership (`p.vip.since`) bought for 799
credits or with the Founders gamepass. It grants a `[Founder]` tag and a few
perks. See [shops-and-monetisation](shops-and-monetisation.md).

**Group wheel.** A lobby prize wheel.
- **Spins.** Group members get a free spin every 6 h (`MineGroupWheel.COOLDOWN_SEC`, `MineConfig.GROUP_ID`).
- **Paid spins.** Products `group_wheel_1/5/10` sell 1, 5 or 10 spins. All have `productId = 0`, so none can be bought yet.
- **Live copies:**
  - `src/ServerScriptService/Mine/GroupWheelService.luau`, reached by the `groupWheelSpin` verb;
  - `MineGroupWheel` and `MineGroupWheelView`, both in `Shared`. The view is mounted on the client.
- **The world wheel is not built.** The `GroupWheelService.build(lobby)` call is
  commented out (*"Group wheel removed. Uncomment to bring it back"*). The panel
  only opens from a `groupWheel` machine prompt, which needs a wheel in the world.
  Whether the place file has one is unverified.
- **The parked copy is older than the live one.** `src/ServerStorage/MineParked/GroupWheel/`
  (README: *"Parked 2026-09-23"*) predates the live modules, which have since
  moved the placement and relabelled the slices. Both are on disk.

**Discord, invites and codes:**
- **Discord link.** `MineDiscordLink.redeem` takes a `!link` code and pays
  `Verbs.DISCORD_LINK_GEMS` 5,000 gems once. Codes are entered in Inventory →
  Account, or in the `MineDiscordLinkClient` Ctrl+L panel. `MineDiscordLinkServer`
  answers a `!link` typed in chat with a pointer to that tab. `MineDiscordBridge`
  is a stub.
- **Invites** (`Verbs.INVITE_REWARD`). A new friend gets a crimson_pack; the
  inviter gets a cobalt_pack, at most 5 a day.
- **Codes** (`Verbs.CODES`). There is one code, `LAUNCH`.

## Where it lives
| file | role |
|---|---|
| `SocialService.luau`, `MineSocialView.luau`, `MineProfileView.luau` | friends, chat and profile; the views are unmounted |
| `MineQuests.luau`, `MineContractor.luau` | quest data and the Job Board UI |
| `LeaderboardService/init.luau` | boards, pedestals, depth boards (`_Bak/` holds old copies) |
| `MineBadges.luau`, `MineFounders.luau` | badges; Founders membership |
| `GroupWheelService.luau`, `MineGroupWheel.luau`, `MineGroupWheelView.luau` | wheel: live copies, plus the parked copy under `ServerStorage/MineParked` |
| `MineDiscordLink.luau` and the `MineDiscordLink*` / `MineDiscordBridge` scripts | Discord link and flags |

## Decided by the owner
- **Depth leaderboard.** The owner asked for one in the 2026-10-04 list (TODO
  §0.27). It became OPEN #16: *"Live update. Deepest-depth tracking already
  exists server-side."*
- **Group wheel.** *"Group wheel sucks"* (HANDOFF §2.6 table). The agent's answer:
  it is on the ARCHIVE list, *"do not polish."*
- **What AUDIT §5 proposes to archive:** leaderboards (~1,750 lines, "needs a
  player base"), the group wheel and trading. These are proposals; the owner's
  yes to the cut list is not recorded.

## State right now
- **Shipped and wired:** quests, the Job Board, leaderboards, badges, Discord link, invites and codes.
- **Dormant:** the social and profile UI; the world group wheel.
- **Most of this code is unchanged since the import** (`566eecf`). Quests and the
  wheel only lost their fossil rows (`ba345b7`).

## Gotchas
- **Quest copy predates the Forge, traits and charms work.** For example:
  - chain rung `pick2` says "Buy a better pickaxe" and rewards coin-shop tools (`meadow_surface_N_pick`);
  - `merge1` says "Merge three of a kind";
  - tips mention runes, a "Summon tab" and "Gems buy zones, runes, and gear".

  Rewrite before launch (`MineQuests.CHAIN`).
- **OPEN P2 is half wrong** where it says the group wheel and the battle pass
  are "both archived in MineParked". Only the wheel is parked, and a live copy
  still exists. The battle pass is live (see [shops-and-monetisation](shops-and-monetisation.md)).
- **The allowlist file has an old name in it.** Its header says
  *"Dig for Cards"* (see [admin-and-debug](admin-and-debug.md)).

## Open questions
- Ship the social UI, or delete `SocialService` and its two views?
- Keep or cut the group wheel and the leaderboards (AUDIT §5)?
- Who pays leaderboard placement rewards, and when (`rewardForRank`)?

## See also
[shops-and-monetisation](shops-and-monetisation.md) · [trading](trading.md) · [world-events](world-events.md) · [rebirth-and-skill-tree](rebirth-and-skill-tree.md) · [server](../code/server.md)
