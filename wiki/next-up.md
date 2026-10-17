---
title: Next up (handoff, 2026-10-10, evening)
type: meta
status: current
verified: 2026-10-14 @ a299374
sources:
  - docs/PETS-AND-SETS.md
  - docs/SET-PETS.md
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - src/ReplicatedStorage/Mine/Shared/MineHorizonTools.luau
  - src/ReplicatedStorage/Mine/Shared/MineZoneChests.luau
  - src/ReplicatedStorage/Mine/Shared/MineZonePets.luau
  - src/ReplicatedStorage/Mine/Shared/MineSetPacks.luau
  - src/ReplicatedStorage/Mine/Shared/PetModelFactory.luau
  - src/ServerScriptService/Mine/MineServer.server.luau
related: [owner, pets, cards-and-packs, zones-layers-and-seams, chests-and-lucky-blocks]
---

# Next up: the owner's queued work, with a prompt to start it

> The owner, 2026-10-10: *"you should finish with pets.. hand this off"*. The
> pets are finished; this page hands off what is left. Everything below is the
> owner's decision unless it is marked **assumed** or **ask**. Paste the prompt
> at the bottom into a new session to start.

## Where things stand (all pushed to `claude/vigilant-fermi-aucqjy`)

| done | where |
|---|---|
| Zone pots (70 a zone), pet ladder lifted, procs reworked, Tidal Wave, Shatter | [pets](systems/pets.md), [mining-and-breaking](systems/mining-and-breaking.md) |
| Holiday pets out of the game; 10 Halloween bodies | [pets](systems/pets.md) |
| **Packs pay named pets:** set packs draw their set, every other pack a zone pot (`1332e3d`) | [cards-and-packs](systems/cards-and-packs.md) |
| **The 19 sets: 2,493 named pets; 900 unique Epic+ tops in `src/`** (2026-10-13; was 2,043 on 98 recolour bodies) | [pets](systems/pets.md#the-19-sets-2026-10-10-unique-epic-tops-2026-10-13), `docs/SET-PETS.md` |
| Set pack sprites by star band (`5f74929`, the other session) | [assets-and-uploads](code/assets-and-uploads.md) |

## Who owns what (two sessions share this checkout)

- **The "Collection pack designs" session** is building pack cases, chest case
  drops, the credit shop, the stardust shop's Cases tab and the daily wheel
  (in MineServer, MineInventoryView, MinePackConfig, MineRotatingOffers,
  MineGroupWheel and MineZoneChests). It reads `MineSetPacks` as committed.
  **Check `git log` and message it before touching those files.**
- **Nobody** remaps the universal grants (codes, invites, quests, weekend haul,
  the day-4 surprise, `Verbs.grantPacks` callers) until the owner asks. The
  owner: universal packs go, but *"don't nuke them"* yet.

## 1. Halloween 2026 — DONE 2026-10-10

- **The mine** is the Candy Crypt, built by another session; see
  [world-events](systems/world-events.md).
- **The pack and its 60 pets** are built; see
  [pets](systems/pets.md#holiday-pets-halloween-2026). The Trick-or-Treat case
  pays the pack.
- **The window is real dates** now (owner's choice): 17 Oct – 7 Nov 2026.
- **Open, for the owner:**
  - **The pack's odds and the three PROPOSED buffs.**
  - **Names**, for review in `docs/HOLIDAY-PETS.md`.

## 2. Pets: what is left

- **DONE 2026-10-13: unique Epic+ Top bodies for all 19 sets,** integrated into
  `src/ReplicatedStorage/Mine/Shared/PetBodies/*Top.luau` (50 modules total: 19 base + 19 Top + 12 Extra).
  Set-pets regenerated: **2,493 pets**, original **2,043 kits locked**
  (`readLock` / serials `0x400`–`0xBFF`). Creature-repeat renames landed in
  `src/`. Studio Edit loads the new species through `PetModelFactory`'s
  PetBodies folder require. See [pets](systems/pets.md).
- **DONE 2026-10-13: placeholder palette labels** — CE / Atlantis / Mythic
  Menagerie `Swatch NNN` colours renamed to thematic names; set-pets regenerated.
- **DONE 2026-10-13: agent kid-friendly name pass** — none flagged
  (`build/pet-bodies/_KID_FRIENDLY_REVIEW.md`). Optional soft renames only.
- **DONE 2026-10-13: Studio Edit probe bake** — 20 Top/Extra/core samples in
  `workspace._TopBodyProbe` (parts 21–49, extents in range, 4 screenshots); no
  build errors. Full showcase rebuild still optional:
  `PetShowcaseBuilder.build()` (~3,287 plinths).
- **DONE 2026-10-10: the look pass of the first 98 set (recolour) bodies.** It
  fixed the factory's invisible cones and the Disco Ball (see
  [pets](systems/pets.md)). Still worth an eye later:
  - Satellite is the smallest body (0.83 after the fit).
  - Hydra Pup has 38 parts.
  - Riftling is only 1.13 studs deep.
  - Gummy, Bottle and Sapshell are glass, so a Golden variant may hide it.
  - Some accent colours never take the tint (gold, lava, the rainbow bands,
    the ninja's headband).
- **DONE 2026-10-10: pets of one name stack and merge** (one `cardKey` per
  named pet; see [cards-and-packs](systems/cards-and-packs.md)).
- **Studio Edit caches modules per session.** After a Studio restart the display
  shows current stat labels; before one, it can show old labels.
- **Still BLOCKED / owner-only (no agent decision):**
  - **Optional owner eye** on Top looks in Studio / showcase (taste only; name
    safety pass already clean).
  - **Tool icon share:** `MineIcons.NEW_TOOL_ICONS_SHARED` stays false until the
    owner shares the personal uploads ([assets-and-uploads](code/assets-and-uploads.md)).
  - **Case / chest owner calls** (odds, shelves, what still ships) — other
    session owns those files; do not invent answers.
  - **Commit on request only** for this Top integration work.

## 3. Still open from before

- **A2 TODAY: DONE 2026-10-10** (active rows only, at the top of the Quests
  panel; see [client-and-ui](code/client-and-ui.md)). **Catch of the day wired
  2026-10-13** (global UTC target; claim coins from TODAY or the FISH tab).
- **A3 fishing: FIRST CUT 2026-10-11** ([fishing](systems/fishing.md)): Greyvein's pond
  and outpost pools, play-tested. **DONE 2026-10-13: 12-fish tables for all 10
  permanent zones** (meadow→primordium; Event Horizon skipped); outpost spots
  auto-register. **DONE 2026-10-13: cooler sell for coins + catch of the day.**
  **DONE 2026-10-13: rod + cork bobber in the world** (`MineFishingView`).
  **DONE 2026-10-13: album set bonuses** (per-zone 12-fish; PROPOSED +2%/+5%
  luck at that zone's spots; FISH + COOLER progress). Next: trading.
- **DONE 2026-10-13: B4 grade ★ reference** — `wiki/systems/grades-and-stars.md`
  + `MineStars` helper; Loadout inspect shows letter + stars. **2026-10-14:**
  also pack odds, inventory Grade, forge temper words, skins badge, lucky odds.
- **DONE 2026-10-14: B1 hammer niche LOCKED** — slow / heavy / single-target,
  hardest hit + highest single-block DPS (`FAMILY_POWER.hammer = 3.7`).
- **DONE 2026-10-14: B2 archetype rebalance** — `tool-dps.js` green.
  Explosive area `edps` tops same-grade (`FAMILY_POWER.explosive = 4`, line
  depth baked, mid line length + sphere cooldown). Hammer crowns single-block
  `dps`; jackhammer ≈ drill; pick stays faster.
- **DONE 2026-10-14: B3 slice (no new rates)** — open-questions #7 fixed
  (`rollChestTool` forward-declare; zone chests drop Secrets again). Secrets /
  Found forever tools show ★ beside word rarity via `MineStars.beside`.
  `tools/verify/chest-tools.js`. Full B3 (5–6 themed sets / event tables /
  purchasable rolls) still owner. Next tools work: C art
  ([tools](systems/tools.md)).
- **The PR is open:** [VeyrixCasino/PullAPick#8](https://github.com/VeyrixCasino/PullAPick/pull/8) (2026-10-11), `claude/vigilant-fermi-aucqjy` into `main`. The repo has no CI checks; the verify suite is local.
- **BLOCKED:**
  - **The wheel's Robux product ids:** the owner supplies them.
  - **The wheel's image face:** needs its art uploaded to group 35326298.

## How to test in Studio

- `devGrant { pet = "Fizzgig" }` (Studio only) mints a pet and seats it.
  `devGrant { packIds = { "atlantis_rising_pack_6" } }` grants exact packs, and
  `openMany { packId = ..., count = 1 }` opens one. Fire them from a Client
  `execute_luau` through `ReplicatedStorage.Mine.Remotes.MineNet`; the server
  answers `openedRun`.
- The display rebuilds with `require(game.ServerStorage.PetShowcaseBuilder).build()`
  in Edit mode (about 3,287 pets after the Epic+ double; about 6–8 seconds).
  It loads fresh module copies.
- **Restart play after code changes.** A running session keeps its old modules.

## The prompt (paste into a new session)

```
Read CLAUDE.md, then wiki/index.md, wiki/owner.md and wiki/next-up.md. Do
wiki/next-up.md section 1 (Halloween 2026), then section 2, on branch
claude/vigilant-fermi-aucqjy.

Rules:
- Before building, ask me the questions marked "Ask" in next-up.md, and confirm
  the "assumed" readings (above all "divided by 10000"). Give me options with
  your recommended default first.
- Another session is building cases, shops and the wheel in MineServer,
  MineInventoryView, MinePackConfig, MineRotatingOffers, MineGroupWheel and
  MineZoneChests. Check git log, and message it before editing those files.
  Commit only your own hunks, never git add -A.
- Ids and stat keys are data: never rename one without an alias.
- Never add top-level locals to MineServer or MineClient (MineServer has 4 left).
- After Luau changes run node tools/verify/compile.js,
  bash tools/verify/suite.sh --quiet and node tools/verify/wiki.js.
- Prove every change in Studio, not just in tests: screenshots for looks, real
  pack opens and block breaks for drops.
- Keep the wiki current in the same commit, add a wiki/log.md entry, and push.
- I am on Windows PowerShell: one command per line, no &&. End every reply with
  the current todo list.
```
