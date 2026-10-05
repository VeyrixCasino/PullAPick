# HANDOFF

> **New agent with no context? Read [`START-HERE.md`](START-HERE.md) instead.**
> It carries the cold-start prompt the owner pastes, what the game is, the
> traps that cost this project days, and the honest state of the branch.
> This file is the deeper reference you read second.

Owner, 2026-10-04: *"YOUR A FUCKING CLOUD CLIENT SO ALL YOUR SHIT IS IN A PLACE
I CANT ACCESS.. I NEED AN EASY WAY TO YOU TO TRANSFER YOURSELF OVER TO A NORMAL
WORKPLACE, OR A BIBLE FOR THE NEXT AGENT TO TAKE ON THIS CASE"*

This is both. **§1 moves the work onto your machine. §2 is the bible.**

---

# 1. Getting off the cloud client

Nothing is trapped. **Everything I have ever done is in the git repo** — there is
no hidden state, no scratch directory that matters, no "my" copy of anything. The
cloud container is just a machine that ran `git push`.

## Option A — run Claude Code locally (what you want)

**The owner is on Windows PowerShell.** Bash syntax does not work there, and the
first version of this doc got that wrong:

- `&&` is not a statement separator in Windows PowerShell 5.1 — use a newline or `;`
- `<angle brackets>` are a reserved operator — never type them, they were a
  placeholder meaning "your path here"
- Paths with spaces need quotes

### THE NO-SCRIPT VERSION — you do not need to know your path

Owner, 2026-10-04: *"i dont know my path"*. You do not have to. Paste these four
lines into PowerShell; the first one finds the repo by looking for
`default.project.json`, which only exists at the repo root.

```powershell
$p = (Get-ChildItem $HOME -Filter default.project.json -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).Directory.FullName
echo $p
cd $p
git pull
```

`echo $p` prints the folder so you can check it found the right one. Then:

```powershell
npm install -g @anthropic-ai/claude-code
claude
```

### OR: run the bootstrap script, which does all of the above

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\start-local-agent.ps1
```

It finds the repo, pulls, checks for Node, installs Claude Code if missing,
fixes PATH in the current window, and launches. Right-click → Run with
PowerShell works too.

**First thing to say to it:** paste §1 of [`START-HERE.md`](START-HERE.md).
That prompt makes it read itself in before it touches anything.

### If something goes wrong

- **"Credit balance too low · Add funds"** → Claude Code is billing **API
  credits**, not your subscription, because `ANTHROPIC_API_KEY` is set in the
  environment and an API key always outranks a subscription login. Adding funds
  is not the fix unless you actually want pay-as-you-go billing. Clear the key
  and log in with the Claude account instead:

  ```powershell
  Remove-Item Env:\ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
  [Environment]::SetEnvironmentVariable('ANTHROPIC_API_KEY', $null, 'User')
  claude
  ```

  Then pick the Claude-account option at the prompt. `/login` switches accounts
  inside a running session.
- `npm` not recognised → install Node **LTS** from https://nodejs.org, reopen PowerShell.
- `claude` not recognised right after install → close and reopen PowerShell; a
  new npm global is not on PATH until the shell restarts.
- The search finds the wrong folder (you have more than one clone) → open GitHub
  Desktop, right-click the repo, **Show in Explorer**, copy the path from the
  address bar, and `cd "that path"` instead.

That agent has your disk, your Rojo, your Studio. It reads this repo, including
this file, and picks up exactly where I am. **It can do everything I can and
several things I cannot** — run the game, read the Output window, take
screenshots, edit the place file.

## Option B — link this session to your machine

```powershell
cd "C:\path\to\PullAPick"
claude remote-control
```

Run it **inside the repo folder**. Then a cloud session can reach your disk.

## What is NOT in the repo, and never was

- `ReplicatedStorage.ToolModels_50` — 80 MB of generated tool models, Studio only.
- Workspace (the map), Lighting, Teams, TextChatService — all live in the place
  file. `$ignoreUnknownInstances` means Rojo never deletes them.
- The balance design docs `AGENT_PROMPT.md` / `PROMPTS.md` — kept outside version
  control. **Ask the owner for these; they matter.**

---

# 2. The bible

## 2.1 What the game is

**You break rock to get ore. Ore is the only thing that makes you stronger.
Everything else decides WHICH ore is worth breaking, and how fast.**

The test for every feature: *"does this change which ore I go break next?"* If
no, it is probably cuttable. See `docs/AUDIT.md`.

## 2.2 Where things are

| | |
|---|---|
| Rojo map | `default.project.json` → `src/` |
| Server | `src/ServerScriptService/Mine/MineServer.server.luau` — **16.7k lines**, the whole game |
| Client | `src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau` — 11.9k lines |
| Shared | `src/ReplicatedStorage/Mine/Shared/` — 88 modules |
| Checks | `tools/verify/*.js` — run them, they are the only safety net |
| Rules | `docs/TODO.md` §0 — **LOCKED RULES, do not relitigate** |

## 2.3 The five traps that have already cost days

1. **Luau's 200 top-level-local ceiling.** `MineServer` sits at ~197. Adding
   `local x = ...` at file scope can break the build. Hang it off an existing
   table instead: `Dig.Traits = require(...)`. There are several of these.
2. **A local referenced above its declaration is a GLOBAL READ, and nil at
   runtime.** It compiles fine and fails silently. This has cost this project
   three bugs — the most recent was a tap-to-close button that did nothing.
   Table fields (`Dig.x`) are safe because lookup happens at call time.
3. **Generated files.** `MineSkillData` and `MineTools` say "GENERATED, edit the
   generator". `tools/skills/gen.js` is the skill-tree one (I rebuilt it; the
   original was never committed). `MineTools`' generator is still missing.
4. **A stat key is DATA.** It is stored on saved runes and gear pieces. Renaming
   one in code without migrating saves silently zeroes what players rolled. See
   `MineStats.LEGACY_STAT` / `canonStat` and `tools/verify/statkeys.js`.
5. **Set runes bypass `NO_ROLL_STATS`.** `MineRunes.SETS` takes stats straight
   from its own list. Retiring a stat means editing that table by hand too.

## 2.4 How to not break things

```
bash tools/verify/syntax.sh          # real luau-analyze over every file
for f in tools/verify/*.js; do node "$f"; done
node tools/skills/gen.js --check     # is the skill tree stale?
```

`trap.js` **fails on clean main** and has for the whole project. Everything else
passing is the bar.

**Every check in `tools/verify/` was written after a real bug.** If one fails,
it is describing something that actually happened once. Several of them caught
me writing the same bug a second time.

## 2.5 What is true right now (2026-10-04)

Branch `claude/vigilant-fermi-aucqjy`, PR #6, ~30 commits ahead of `main`.

**Built and tested-by-harness, NEVER RUN IN ROBLOX:**
- The Forge, rewritten ore-first. A tool IS its ore: `{Ore} {Noun}`.
- Traits (was "enchantments", was "runes") — a prefix on your tool.
  `{Trait} {Ore} {Noun}`. Exotic 1/1000, Exotic V 1/5000.
- Proc damage split from proc chance (`PROC_SHARE` + `procPower`).
- Two boost layers: skills+skins+tools+traits, then equipment+pets, multiplied.
- The skill tree regenerated; ten roads were 2.44x apart, now 1.001x.
- `blastRadius` reweighted 6 → 18 because a blast is a SPHERE and scales r³.

**Known broken / missing:** see §2.6 and `docs/BLOCKED.md`.

## 2.6 The owner's live complaint list, fact-checked

I checked each of these against the code rather than taking them at face value.
Several are not what they look like.

| complaint | verdict |
|---|---|
| "Remove the base 2x coins from rebirths" | **Already gone.** `prestigeYield` (1 + 0.15R, not 2x) was dead — nothing read it. I deleted the function so it cannot be rewired by accident. |
| "Potions don't exist" | **They do, end to end.** 289-line module, `drinkPotion` verb, client callback, UI at `MineInventoryView:4812`, granted by packs/quests/offers/scrolls. The real problem is they are buried and weightless — a DESIGN gap, not a missing feature. |
| "Depth leaderboard doesn't track deepest block / anti-cheat?" | **Server-side tracking exists**: `p.deepest`, `creditDeepest`, normalized on load. Whether the leaderboard reads it live is unverified. |
| "Packs make you say DONE" | **True, fixed.** Tap-anywhere added; DONE kept as an affordance. |
| "Lucky blocks don't close/reopen the inventory" | **FIXED.** Owner clarified: "the inventory stays OVER the lucky block". The lucky screen was DisplayOrder 110 and now matches MinePackReveal at 120 — the layer the owner already signed off on. Older note: **Reproduced in code, NOT fixed.** The inventory deliberately stays open under pack reveals (a documented decision — opening six packs should not mean reopening the bag six times). Lucky screen is DisplayOrder 110, pack reveal 120, HUD 80. I could not tell from the code which half is wrong without running it. **Needs an in-engine repro.** |
| "Charm icons are hideous" | Owner supplied a reference: ornate **jewellery** — amulets, pendants, beaded strings, brooches, gem-set lockets, aged brass and enamel. The 164 generated icons are already marked SUPERSEDED. |
| "Group wheel sucks" / "battle pass is lazy" | Both are on the ARCHIVE list in `docs/AUDIT.md`. Do not polish them; cut them until there is a game. |

## 2.7 The coin problem (unsolved, and the most important one)

Owner: *"now that coins are basically useless, there's no point... I want the
economy to be stable, and a type of economy where everyone has a chance to
contribute. Right now it's all progression, less pull rare shit."*

**The diagnosis.** Coins have exactly one sink — the coin-shop tool ladder —
and that ladder was superseded by the Forge, which runs on ore. So coins are a
faucet with no drain. Rebirth income multipliers would have made it worse, which
is why the owner called for their removal.

**The shape of the fix** (NOT yet agreed, do not build without the owner):

- Coins should buy **consumables and access, never power.** Power is ore.
- The underground outposts are the natural home: each seam's outpost sells
  things *for coins* that help you mine the NEXT seam — potions, repairs,
  temporary licences, a faster cart.
- **Potions are the obvious coin sink** and already exist. Give them real weight
  and price them in coins, and coins have a job from minute one to hour fifty.
- Keep gems for gambling (traits, charm merges, cases) and ore for power. Three
  currencies, three jobs, no overlap.

## 2.8 The seam / underground outpost direction

Owner's words: a seam should open an **underground outpost, 1:1 with the surface
one** (shop, sell), themed underground, and **visibly deeper and darker each
time**, following the mine's theme.

**CORRECTED 2026-10-05 — NOT A BLOCKER.** The seam chain is wired end to end: server fires `seamGate` (`MineServer:6406`), client opens the panel (`MineClient:10859` -> `7415`), the panel fires `buySeam` (`7489`), `Verbs.buySeam` handles it (`9266`). The earlier claim came from grepping only `buySeam`, which finds the server half alone. What remains is confirming it in-game. See `docs/OPEN.md` P0 item 1.

~~This was recorded as the ship blocker.~~ Formerly:
so every player stops at layer 500. `MineDepthPlazas` owns the prompt geometry
and `MineDepth.seamPrice(seam, zi)` gives the figure. A local agent can place the
prompt in Studio and wire it in an afternoon. **This is the single highest-value
task in the project.**

## 2.9 House style, so the next agent matches

- Comments explain **why**, and name the bug that caused the code to exist. The
  codebase is written this way throughout; match it.
- Never invent a balance number silently. Derive it from existing data
  (`MineStats.weight` is the canonical source of what a stat is worth) or put it
  in front of the owner.
- Write the check **after** finding a real bug, and make sure it fails on the
  broken code before you fix it.
- The owner wants to be told when they are wrong, with evidence. Several entries
  in §2.6 exist because I checked instead of agreeing.

## 2.10 Where to start

1. Read `docs/AUDIT.md` — the state of the game and the three-week plan.
2. Read `docs/BLOCKED.md` — what needs the owner, with suggested answers.
3. Read `docs/TODO.md` §0 — the locked rules.
4. **Pull the branch, open Studio, and play it.** Nothing in §2.5 has ever run.
