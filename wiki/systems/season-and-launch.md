---
title: Season and launch
type: system
status: partial
verified: 2026-10-08 @ bae3c5b
sources:
  - src/ReplicatedStorage/Mine/Shared/MineLaunch.luau
  - src/ReplicatedStorage/Mine/Shared/MineRotatingOffers.luau
  - src/ReplicatedStorage/Mine/Shared/MineScrolls.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
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
- **There is no "unlaunch".** Rewinding would re-lock what players earned. A mistaken
  launch is fixed by a deliberate DataStore edit, not by a verb.
- **Defaulted inside the modules, not at call sites.** `MineRotatingOffers`
  (`now = now or Launch.seasonNow()`) and `MineScrolls` (battle pass, `PASS_SEASON_*`)
  default to `seasonNow()`. Client panels are among their callers, and one still
  reading `os.time()` would show a different season than the server runs.

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
| `src/ReplicatedStorage/Mine/Shared/MineLaunch.luau` | the rule | `launchedAt`, `SEASON_START`, `seasonNow`, `elapsed`, `teaserLeft`, `launch`, `isLaunched` |
| `src/ServerScriptService/Mine/MineServer.server.luau` | persistence and the switch | `Verbs._loadLaunch`, `Verbs.launchSeason`, dispatch `launchSeason` |
| `src/ReplicatedStorage/Mine/Shared/MineRotatingOffers.luau` | offer slots | `SEASON_START`, `SEASON_END` |
| `src/ReplicatedStorage/Mine/Shared/MineScrolls.luau` | battle pass | `PASS_SEASON_START`, `PASS_SEASON_END` |
| `tools/verify/launch.js` | rule, persistence order, constants agree | needs `luau` |

## Decided by the owner

- The timer **keeps ticking visibly** but the real season does not start until they
  say launch (TODO §6.1, 2026-10-07: *"a server-side `launched` flag (not a date)"*).
- **Nothing may key off a wall-clock date alone** to decide the game has started.

## State right now

- **Built and harnessed, never run in the engine.** The author wrote that the place
  was closed when they went to check, so the boot path and the admin verb are covered
  statically only.
- `SEASON_START` is stored **three times** (`MineLaunch`, `MineRotatingOffers`,
  `MineScrolls.PASS_SEASON_START`); `launch.js` asserts they agree, because drift
  would put the season weeks out without failing anything else.

## Gotchas

- **Nothing in `src/` calls `launchSeason`.** The server dispatches the action, but I
  searched `src/`, `tools/` and `docs/`: the only other mentions are inside
  `launch.js`. No admin panel button or client script sends it, so **the owner has no
  button to press** (see [open-questions](../open-questions.md) §1b).
- **The limited-event window is a separate clock.** `MineConfig.LIMITED_START_UNIX` /
  `LIMITED_DAYS` for Event Horizon still run on real time and were not moved.
  See [world-events](world-events.md).
- **The two season ends disagree.** `MineRotatingOffers.SEASON_END` is 2026-11-01
  **plus `EXTEND_SEC` (one week)** = 2026-11-08, but `MineScrolls.PASS_SEASON_END` is
  still `1793505600` = 2026-11-01 04:00 UTC. So the battle pass is one week shorter
  than the offers around it. `launch.js` pins the three **start** constants only.
  I have not asked the owner whether that is intended (see
  [open-questions](../open-questions.md) §1b). Once launched, each end is
  `launchedAt + (END − SEASON_START)`, so the lengths are 40 days and 47 days (measured
  from the constants).

## Open questions

- How does the owner throw the switch? (No caller exists today.)
- Should Event Horizon's window also wait for launch? It does not.
- What should players see before launch: the rolling teaser, or something that says
  "launching soon"?

## See also
[shops-and-monetisation](shops-and-monetisation.md) · [world-events](world-events.md) · [social-quests-and-leaderboards](social-quests-and-leaderboards.md) · [wandering-traders](wandering-traders.md)
