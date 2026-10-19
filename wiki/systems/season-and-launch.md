---
title: Season and launch
type: system
status: partial
verified: 2026-10-19 @ b4aa4ed
sources:
  - src/ReplicatedStorage/Mine/Shared/MineLaunch.luau
  - src/ReplicatedStorage/Mine/Shared/MineRotatingOffers.luau
  - src/ReplicatedStorage/Mine/Shared/MineScrolls.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
  - src/ServerScriptService/Mine/Admin/MineAdmin.luau
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - tools/verify/launch.js
  - docs/TODO.md §6.1
related: [shops-and-monetisation, world-events, social-quests-and-leaderboards, open-questions]
---

# Season and launch

> The season clock **does not start until the owner says launch**. Until then it
> is pinned to second zero. This page covers that switch and what reads the clock.

Owner, 2026-10-07: *"i want the timer to not actually start until i say launch,
and rather just keep ticking down"* (`bae3c5b`).

## Why it exists

The season was two absolute dates, `MineRotatingOffers.SEASON_START` (2026-09-22)
and `SEASON_END` (2026-11-01). So it was **already running** with nobody playing:
week one gone, the battle pass counting down, offers rotated past their slots, and
nothing reported it. Whenever the game opened, players would have arrived midway
through a season they never saw begin.

## How it works

- **The season is a duration, not a date.** `MineLaunch.seasonNow(realNow)` is what
  every season-timed system reads instead of `os.time()`.
  - **Before launch** it returns `SEASON_START` exactly. Zero seconds have elapsed,
    offer slot one is live, nothing can expire.
  - **After launch** it returns `SEASON_START + max(0, now − launchedAt)`. The
    `max(0, …)` stops a backwards clock from rewinding the season and resurrecting
    expired offers.
- **The visible countdown still moves**, which is the half of the ask that sounds
  contradictory. `MineLaunch.teaserLeft()` runs off real `os.time()`, falls every
  second, and **rolls over** at `TEASER_PERIOD 86400` instead of reaching zero. It
  is cosmetic: nothing reads it, nothing fires. It returns `nil` once launched.
- **Launching is a flag, not a date.** `Verbs.launchSeason` is admin-gated
  (`AdminAllowlist.isAdmin`), stamps `MineLaunch.launch(os.time())`, and persists
  `{ at, by }` to the DataStore key `launch_v1`, **server-wide, not per profile**.
  `Verbs._loadLaunch` reads it once at boot.
- **The switch is the chat command `/admin launch now`** (added in `cc0262f`, "Launch
  audit, part 1"). `/admin launch` alone, or with `status`, only reports whether the
  season is live. It is a command and not a button on purpose, so it is hard to hit by
  accident, and `now` must be typed as the second word. `MineAdmin` calls the verb
  through its `deps` table rather than re-implementing it, so there is one copy of
  "throw the switch".
- **There is no "unlaunch".** Rewinding would re-lock what players earned. A mistaken
  launch is fixed by a deliberate DataStore edit, not by a verb.
- **Defaulted inside the modules, not at call sites.** `MineRotatingOffers`
  (`now = now or Launch.seasonNow()`) and `MineScrolls` (battle pass, `PASS_SEASON_*`)
  default to `seasonNow()`. Client panels are among their callers, and one still
  reading `os.time()` would show a different season than the server runs.
- **More clocks were moved onto it in `cc0262f`.** `limitedSaleOpen` (it gates real
  Robux purchases, and used to read a date already in the past) went onto the season
  clock, and so did the group wheel's sale window. **The wheel has since been reworked**
  into the daily wheel (`299dd2c`), so its old sale-window functions are gone
  and I do not describe them here. Event Horizon's window (`bigbang`) reads the season
  clock too (`MineConfig.limitedActive` via `launchClock()`), but a window with real
  calendar dates (`opensUnix`, such as Hallow) reads `os.time()`.

### Three failure directions, chosen on purpose (pinned in `launch.js`)

1. A **failed or empty DataStore read leaves the game unlaunched**. A blip must never
   start the season by accident.
2. The launch is **saved before it is announced**. An announced but unsaved launch
   would rewind on the next restart.
3. A **failed save rolls the flag back** (`launchedAt = 0`) rather than leaving the
   server half-launched against its own saved state.

## Where it lives

| file | role | key symbols |
|---|---|---|
| `src/ReplicatedStorage/Mine/Shared/MineLaunch.luau` | the rule | `launchedAt`, `stamp`, `ATTRIBUTE`, `SEASON_START`, `seasonNow`, `elapsed`, `teaserLeft`, `launch`, `isLaunched` |
| `src/ServerScriptService/Mine/MineServer.server.luau` | persistence and the switch | `Verbs._loadLaunch`, `Verbs.launchSeason`, dispatch `launchSeason` |
| `src/ServerScriptService/Mine/Admin/MineAdmin.luau` | the `/admin launch` command | `cmd == "launch"`, `deps.launchSeason` |
| `src/ReplicatedStorage/Mine/Shared/MineConfig.luau` | limited windows on the season clock | `limitedActive`, `limitedWindow`, `LIMITED_WINDOWS`, `LIMITED_DAYS` (47) |
| `src/ReplicatedStorage/Mine/Shared/MineRotatingOffers.luau` | offer slots | `SEASON_START`, `SEASON_END` |
| `src/ReplicatedStorage/Mine/Shared/MineScrolls.luau` | battle pass | `PASS_SEASON_START`, `PASS_SEASON_END`, `seasonClock`, `passEndLabel` |
| `src/ReplicatedStorage/Mine/Shared/MineInventoryView.luau` | the pass panel's countdown | `SeasonClock` row |
| `tools/verify/launch.js` | rule, persistence order, constants agree | needs `luau` |

## Decided by the owner

- The timer **keeps ticking visibly** but the real season does not start until they
  say launch (TODO §6.1, 2026-10-07: *"a server-side `launched` flag (not a date)"*).
- **Nothing may key off a wall-clock date alone** to decide the game has started.

## State right now

- **Built, wired and harnessed.** The launch audit (`cc0262f`) added the missing caller.
  Whether the owner has actually run `/admin launch` in Studio is not recorded in
  the commit; its message describes the boot path and the verb from the code. **The season
  is unlaunched until someone types it.**
- `SEASON_START` is stored **three times** (`MineLaunch`, `MineRotatingOffers`,
  `MineScrolls.PASS_SEASON_START`); `launch.js` asserts they agree, because drift
  would put the season weeks out without failing anything else.

## Gotchas

- **Until `cc0262f`, nothing called `launchSeason`.** I recorded that as a finding on
  2026-10-08; the owner's session found the same thing in its launch audit and fixed it
  with `/admin launch now`. There is still **no button**, by design.
- **Calendar windows are not on the season clock.** A limited window with real dates
  (`opensUnix`, for example the Hallow one and the Candy Crypt) runs on `os.time()`, so
  launching late does not shift it. See [world-events](world-events.md).
- **A launch reaches only the server it was typed on.** `Verbs._loadLaunch` reads
  `launch_v1` once at boot, and nothing tells other running servers. After
  `/admin launch now`, every other live server stays unlaunched (season at second zero)
  until it restarts. **On launch day: launch before opening the game to players, or
  restart all servers right after launching.** A live broadcast (MessagingService) would
  remove the step; it is not built.
- **The battle pass is 28 days from launch** (owner, 2026-10-18: *"28 days"*). It
  ended at 40 days on the working branch and at 47 for one day on this branch, while the
  pass rework had already added `MineScrolls.PASS_SEASON_DAYS = 28` that nothing read. The
  end is now derived from it (`PASS_SEASON_START + PASS_SEASON_DAYS * 86400`), so the length
  is one number. The offers and Event Horizon still run 47 days; the pass ends inside that.
  `launch.js` checks the pass is exactly `PASS_SEASON_DAYS` long and ends inside the season.
- **Day 29: decided 2026-10-19, not built.** The owner will have a new pass ready (*"i'll
  having something ready"*), and picked a safety net: if the new track has not shipped by
  day 29, the old pass **pauses** (no XP, no claims, "Next pass coming soon"). Today
  `reconcilePass` moves every player to `PASS_SEASON_NEXT` ("2026-11") on the same
  `PASS_TRACK`, wipes XP and claims and sets `owned = false`, and the panel says "Next season
  is live" (`MineInventoryView` 7389), so without the pause players would re-earn the season
  pets and Season One skins and re-buy premium. See [open-questions](../open-questions.md) (24).
- **Clients used to stay at second zero forever.** A client never runs `_loadLaunch`, so
  its copy of `MineLaunch` never learned `launchedAt`. After a launch the shop would have
  kept showing week one's deals (`RotatingOffers.active()`), which the server then refuses
  as not live, and the sale and Event Horizon countdowns would never have moved. Fixed on
  2026-10-17: the server mirrors the stamp onto `ReplicatedStorage` as the attribute
  `MineLaunchedAt` (`Verbs._mirrorLaunch`, called after a successful read or save) and
  `MineLaunch.stamp()` reads it **on clients only**.
- **The pass panel used the raw clock.** `MineInventoryView` passed
  `workspace:GetServerTimeNow()` straight to the countdown and printed "Oct 31 · 11:59 PM
  ET". Before launch it counted down to a calendar date; after a late launch it would have
  said SEASON OVER mid-season. It now uses `MineScrolls.seasonClock(...)`, and the end label
  comes from `MineScrolls.passEndLabel()`: "Starts at launch" before launch, then the real
  end in the player's local time. **Not yet seen in Studio.**

## Open questions

- What should players see before launch: the rolling teaser, or something that says
  "launching soon"?

## See also
[shops-and-monetisation](shops-and-monetisation.md) · [world-events](world-events.md) · [social-quests-and-leaderboards](social-quests-and-leaderboards.md) · [wandering-traders](wandering-traders.md)
