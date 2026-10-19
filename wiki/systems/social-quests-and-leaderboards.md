---
title: Social, quests and leaderboards
type: system
status: current
verified: 2026-10-19 @ 3863d14
sources:
  - src/ServerScriptService/Mine/SocialService.luau
  - tools/verify/quests-honest.js
  - src/ReplicatedStorage/Mine/Shared/MineGroupWheelView.luau
  - tools/verify/daily-wheel.js
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
related: [shops-and-monetisation, trading, world-events, rebirth-and-skill-tree, cards-and-packs, enchants, traits]
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
surprise pack (`Verbs.claimDailySurprise`), **given regardless** (owner, 2026-10-19,
launch audit S20). The popup used to ask for a Like and a Favorite first; now it asks
for nothing, its optional FAVORITE is Roblox's own prompt
(`AvatarEditorService:PromptSetFavorite`), and closing it claims the pack too.

**Quest fixes from the launch audit (2026-10-19):**
- **Chain rung 3 is "Forge your first tool"** (id still `pick2`, because the
  `CHAIN_V1`/`V2` remaps name it): stat `oretools`, goal 1, `absolute = true`, so a
  tool forged before the rung went live counts. It matches the tutorial's step 3
  ([client-and-ui](../code/client-and-ui.md)). It was "Buy a better pickaxe", which
  nothing sells (M1).
- **No "Rebirth once" daily before the first rebirth** (S40). Tier B was only that
  quest, so day-one players got a daily they could not finish. Until `p.prestige` is
  1, `rollDaily(day, userId, { prestige })` gives "Sell 10 hauls" for the same 90 gems
  instead (`MineQuests.DAILY_NO_REBIRTH`, PROPOSED). The other two tiers roll as before.
- **Four stale tips were rewritten** (S40): `cards10` (three pet seats, not "more slots
  unlock"), `sell5` (coins pay for rebirth; gems buy zones, bags and books), `cards250`
  (+5% luck a rebirth; `prestigeYield` is gone) and `mine75k` (AFK after 2 idle minutes,
  not a "chill pad"). `tools/verify/quests-launch.js` checks each tip against the config
  value it quotes.
- **Milestones say what they count** (2026-10-19; the owner took the default, "relabel").
  `ms_cards_100/500` and `ms_gear_15` read what you hold (`#p.cards`, `#p.gear`) and say
  "Own 100 cards", "Own 15 gear pieces"; `ms_depth_*` read this run's deepest (depth resets
  on rebirth) and say "Reach depth 250 in one run". Blocks, packs and merges are true
  lifetime counters (`p.stats`) and keep "Lifetime:". The panel's header reads
  "MILESTONES - claim when ready" (it said "lifetime").
- **Chain rung `forge1` levels a tool up** (2026-10-19). It was "Forge a tool out of ore",
  which rung 3 (`pick2`, above) now teaches. It is "Level up a tool once at the Forge"
  (stat `upgrades`, goal 1, counted from when the rung goes active like the others; 60 gems
  as before). `questValue` reads `p.stats.upgrades`, which `Verbs.upgradeOreTool` bumps on
  every level-up it sells, the wooden pick's coin levels included. The wording is PROPOSED.
  Both are checked by `tools/verify/quests-honest.js`.

**The rune and trait quests teach enchants** (2026-10-12, when runes and traits
were retired; same rewards, same places in the ladder):
- chain `rune5` → `ench1` "Enchant a tool" (stat `enchants`);
- chain `trait1` → `bookmerge1` "Merge 3 books into a better one" (stat `bookmerges`);
- chain `rune40` → `bookmerge10` "Merge books 10 times";
- contract `c_rune_s` → `c_ench_s` "Fill 2 enchant slots".

MineServer's `questValue` derives `enchants` (filled enchant slots across all
forged tools) and reads `bookmerges` from `p.bookMerges`, which survives a
rebirth. Tips that mentioned runes or scrolls were rewritten.

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
- **No reward text** (owner, 2026-10-19, launch audit S39). The boards used to print a
  prize on every rank (`rewardForRank`, "5,000 gems + Event pack" down to "100 gems") and
  a "101+ Everyone else — 100 gems" row, and nothing ever paid any of it. Both are
  deleted, and the player's own row (MineClient's `YouRow`) shows the rank alone.
  `tools/verify/promises.js` keeps any gem amount off the boards.

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

**Daily wheel** (was the group wheel; shipped 2026-10-10 in `299dd2c`, TODO NOW A1).
A 16-slice prize wheel in the lobby, at about (40, 6, 0).
- **Free spins.** Everyone gets free spins every UTC day, and they reset at
  midnight without a save write. The rules are in `MineGroupWheel.allowance`:
  - `FREE_PER_DAY` (1) for everyone;
  - `GROUP_BONUS` (+1) for members of `MineConfig.GROUP_ID`. The server caches
    membership per player. In Studio with no group id, everyone counts as a member;
  - `STREAK_BONUS` (+1) on a claimed day that is a multiple of `STREAK_EVERY` (7).

  These numbers and the slice weights are **PROPOSED**: the owner has not
  approved them.
- **Pack slices pay wild pack cases** (2026-10-10; owner: the slices become
  star-graded cases, and the wheel stops giving zone packs). The slices are:
  - jackpot: 15K gems and a ★★★★★ case;
  - `apex`: a ★★★★ case;
  - `heirloom`: a ★★★ case;
  - `anomaly`: a ★★ case.

  The ids are unchanged. The star grade each slice pays is PROPOSED. The gear
  case slice stays. See [pack-cases](pack-cases.md).
- **The rune slice pays 3 Lucky Books** (2026-10-12; owner: *"3 lucky enchanted
  books"*). The 6% slice keeps its id `heavy_runes`, because ids are data, but
  its label is "3 LUCKY BOOKS" and it pays 3 enchant books rolled at an S
  chest's levels (`MineGroupWheel.SEGMENTS`, `reward.books`; granted in
  `GroupWheelService.applyReward`). Before, it paid one Heavy Rune Case.
- **Paid spins.** Products `group_wheel_1/5/10` bank 1, 5 or 10 spins. Free spins
  are spent first. Paid spins are blocked where paid random items are not allowed
  (`PolicyNoRandom`). All three products have `productId = 0`, so none can be
  bought yet. The buy row hides itself until they have ids.
- **Odds are printed on every slice,** on the world wheel and in the panel. Both
  use `Wheel.oddsText`: `%` at 1% and above, "1 in N" below that.
- **Where you open it:**
  - the gold **Wheel** dock button, second from the top; its badge counts the
    free spins left (`MineNotifs`);
  - the Spin prompt on the pad in front of the world wheel.
- **Save:** `p.groupWheel = { day, used, paid, last }`. A spin saves at once.
  Rebirth keeps the field (`Verbs.KEEP_ON_REBIRTH`). The snapshot carries only
  `GroupWheelService.snapState`. The prize table travels with `payload` when the
  panel opens.
- **The world wheel turns on each client,** in `MineGroupWheelView.mount`, never
  on the server. It waits until all `PartCount` parts have streamed in, records
  the pose, and turns the model about its pivot's up axis (the axle) at
  `SpinSpeed` °/s. It re-records whenever the wheel streams back in. The earlier
  `AmbSpin` idle spin captured a half-streamed wheel, which turned it edge-on so
  the face read blank.
- **The parked copy is older than the live one.** `src/ServerStorage/MineParked/GroupWheel/`
  (README: *"Parked 2026-09-23"*) is stale. Edit only the live modules.

**Discord, invites and codes:**
- **Discord link.** The owner runs the bot (2026-10-19): `!link` in Discord, the bot
  writes the code into `Mine_v1_discord_pending` through Open Cloud, the player types it
  in Inventory → Account (or the `MineDiscordLinkClient` Ctrl+L panel), and the bot reads
  `Mine_v1_discord_claims`. `MineDiscordLink.redeem`:
  - a code **not in pending is refused** ("That code isn't valid. Type !link in our
    Discord to get a new one.") and writes nothing. Until 2026-10-19 any 4–12 letters got
    "Code accepted!" and a claim-store write (launch audit S38);
  - a real code writes both link rows, removes the pending code, and then writes **one
    claim** (`robloxUserId`, `discordId`, `linked = true`), which is how the bot learns
    the code was used.

  `Verbs.discordLink` pays `Verbs.DISCORD_LINK_GEMS` (5,000) once through
  `Verbs.payDiscordBonus`. It is throttled: 2 s between tries, doubling per miss up to
  60 s (PROPOSED); until 2026-10-19 its cooldown read a nil global, so every redeem threw.
  **A link finished on the Discord side pays on the next join** (`Verbs.discordJoinBonus`,
  from `hookPlayer`), only where `PolicyDiscord` is true, like the verb. The Account tab
  promises the gems only (not "player markets and remote trading") and shows the invite
  **discord.gg/Ab5ZpVdRvp** as plain text: Roblox does not allow a clickable off-site
  link. `tools/verify/discord-link.js` runs `redeem` against a stubbed DataStore.
  `MineDiscordLinkServer` answers a `!link` typed in chat with a pointer to the tab.
  `MineDiscordBridge` is a stub.
- **Invites** (`Verbs.INVITE_REWARD`). A new friend gets a crimson_pack; the
  inviter gets a cobalt_pack, at most 5 a day.
- **Codes** (`Verbs.CODES`). There is one code, `LAUNCH`.

## Where it lives
| file | role |
|---|---|
| `src/ServerScriptService/Mine/SocialService.luau`, `src/ReplicatedStorage/Mine/Shared/MineSocialView.luau`, `src/ReplicatedStorage/Mine/Shared/MineProfileView.luau` | friends, chat and profile; the views are unmounted |
| `src/ReplicatedStorage/Mine/Shared/MineQuests.luau`, `src/ReplicatedStorage/Mine/Shared/MineContractor.luau` | quest data and the Job Board UI |
| `src/ServerScriptService/Mine/LeaderboardService/init.luau` | boards, pedestals, depth boards (`_Bak/` holds old copies) |
| `src/ServerScriptService/Mine/MineBadges.luau`, `src/ReplicatedStorage/Mine/Shared/MineFounders.luau` | badges; Founders membership |
| `src/ServerScriptService/Mine/GroupWheelService.luau`, `src/ReplicatedStorage/Mine/Shared/MineGroupWheel.luau`, `src/ReplicatedStorage/Mine/Shared/MineGroupWheelView.luau` | wheel: live copies, plus the parked copy under `ServerStorage/MineParked` |
| `src/ReplicatedStorage/Mine/Shared/MineDiscordLink.luau`, `src/ServerScriptService/Mine/MineDiscordLinkServer.server.luau`, `src/ServerScriptService/Mine/MineDiscordBridge.server.luau`, `src/StarterPlayer/StarterPlayerScripts/MineDiscordLinkClient.client.luau` | Discord link and flags |

## Decided by the owner
- **Depth leaderboard.** The owner asked for one in the 2026-10-04 list (TODO
  §0.27). It became OPEN #16: *"Live update. Deepest-depth tracking already
  exists server-side."*
- **Group wheel → daily wheel.** *"Group wheel sucks"* (HANDOFF §2.6 table) put
  it on the ARCHIVE list. The owner reversed that on 2026-10-10: *"we need that
  daily wheel working"*. Their decisions: everyone spins daily, group members get
  a bonus, streaks add more, it stands in the lobby, and the odds are printed
  ([owner](../owner.md)).
- **What AUDIT §5 proposes to archive:** leaderboards (~1,750 lines, "needs a
  player base"), the group wheel and trading. These are proposals; the owner's
  yes to the cut list is not recorded.

## State right now
- **Shipped and wired:** quests, the Job Board, leaderboards, badges, Discord link,
  invites, codes, and the daily wheel. The wheel was verified in Studio on
  2026-10-10: a free spin landed on the rolled slice, the pack was granted, the
  badge counted down, and the used spin survived a restart.
- **Dormant:** the social and profile UI.
- **Most of this code is unchanged since the import** (`566eecf`). Quests and the
  wheel lost their fossil rows (`ba345b7`), and on 2026-10-12 their rune and
  trait rows became enchant rows (above).

## Gotchas
- **Some quest copy predates the Forge and charms work.** For example:
  - chain rungs such as `chests3` reward coin-shop tools (`meadow_surface_N_pick`)
    (`pick2` itself became "Forge your first tool" on 2026-10-19);
  - `merge1` says "Merge three of a kind";
  - `open10`'s tip still says "Summon tab: Gear 75g".

  The rune tips ("Gems buy zones, runes, and gear" and others) were rewritten on
  2026-10-12; `sell5` now says "Gems buy zones, gear and enchant books".

  Rewrite before launch (`MineQuests.CHAIN`).
- **OPEN P2 is wrong** where it says the group wheel and the battle pass are
  "both archived in MineParked". Both are live; only a stale copy of the wheel
  sits in MineParked (see [shops-and-monetisation](shops-and-monetisation.md)).
- **Never reorder or rename the wheel's slice ids.** Each one is data: the
  `index` the client lands on, and the `group_wheel` card set.
- **The allowlist file has an old name in it.** Its header says
  *"Dig for Cards"* (see [admin-and-debug](admin-and-debug.md)).

## Open questions
- Ship the social UI, or delete `SocialService` and its two views?
- Keep or cut the leaderboards (AUDIT §5)? (The wheel was kept, 2026-10-10.)
- Approve the daily wheel's PROPOSED numbers: the allowances, and the slice
  weights in `MineGroupWheel.SEGMENTS`.
- The Robux product ids for `group_wheel_1/5/10` (BLOCKED until the owner makes them).
- ~~Who pays leaderboard placement rewards, and when (`rewardForRank`)?~~ **Answered
  2026-10-19:** nobody, so the reward text is removed (S39).
- ~~The "Lifetime" card, gear and depth milestones read what you hold now: add lifetime
  counters, or relabel them "Own N"?~~ **Answered 2026-10-19:** relabelled (above).

## See also
[shops-and-monetisation](shops-and-monetisation.md) · [trading](trading.md) · [world-events](world-events.md) · [rebirth-and-skill-tree](rebirth-and-skill-tree.md) · [server](../code/server.md)
