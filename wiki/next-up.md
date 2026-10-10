---
title: Next up (handoff, 2026-10-10, evening)
type: meta
status: current
verified: 2026-10-10 @ 5f74929
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
| **The 19 sets: 2,043 named pets on 98 new bodies** (this page's commit) | [pets](systems/pets.md#the-19-sets-2026-10-10), `docs/SET-PETS.md` |
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
- **Open, for the owner:**
  - **The window.** The owner said real dates, and *"if the game isn't live by
    then, it doesn't happen"*. The Crypt counts days from season start, so it
    moves with launch.
  - **The pack's odds and the three PROPOSED buffs.**
  - **Names**, for review in `docs/HOLIDAY-PETS.md`.

## 2. Pets: what is left

- **DONE 2026-10-10: the look pass of the 98 set bodies.** It fixed the
  factory's invisible cones and the Disco Ball (see [pets](systems/pets.md)).
  Still worth an eye later:
  - Satellite is the smallest body (0.83 after the fit).
  - Hydra Pup has 38 parts.
  - Riftling is only 1.13 studs deep.
  - Gummy, Bottle and Sapshell are glass, so a Golden variant may hide it.
  - Some accent colours never take the tint (gold, lava, the rainbow bands,
    the ninja's headband).
- **Pets of one name can fail to merge.** Pack pets use `"<home>:<name>"`;
  lucky blocks mint `"lucky_block:<name>"` and the group wheel
  `"group_wheel:<name>"`. Merging needs equal `cardKey`s. **Ask** before
  re-keying, because it touches saved cards.
- **Studio Edit caches modules per session.** After a Studio restart the display
  shows current stat labels; before one, it can show old labels.

## 3. Still open from before

- A2 (the TODAY checklist in the Quests panel), A3 (fishing), B tools, C art,
  D planets ([open-questions](open-questions.md)).
- **BLOCKED:**
  - **The PR:** the owner runs `gh auth login`, or opens it at
    https://github.com/VeyrixCasino/PullAPick/compare/main...claude/vigilant-fermi-aucqjy?expand=1
  - **The wheel's Robux product ids:** the owner supplies them.
  - **The wheel's image face:** needs its art uploaded to group 35326298.

## How to test in Studio

- `devGrant { pet = "Fizzgig" }` (Studio only) mints a pet and seats it.
  `devGrant { packIds = { "atlantis_rising_pack_6" } }` grants exact packs, and
  `openMany { packId = ..., count = 1 }` opens one. Fire them from a Client
  `execute_luau` through `ReplicatedStorage.Mine.Remotes.MineNet`; the server
  answers `openedRun`.
- The display rebuilds with `require(game.ServerStorage.PetShowcaseBuilder).build()`
  in Edit mode (2,837 pets; about 6 seconds). It loads fresh module copies.
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
