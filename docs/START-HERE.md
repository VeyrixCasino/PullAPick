# START HERE — the cold-start prompt

Owner, 2026-10-05: *"update the goddamn handoff with a prompt to get it knowing
exactly what its doing 100% with absolutely no prior knowledge."*

**§1 is the thing to paste.** §2 onward is what the agent reads after pasting it.
If you are the owner: copy §1, paste it, stop reading. If you are the agent: §1
was your instruction, now read everything below it.

---

# 1. THE PROMPT — paste this and nothing else

```
You are taking over development of a Roblox game called "Mine For Cards".
You have no prior knowledge of it and you must not assume any.

Before you write a single line of code, do all of this, in this order:

1. Read docs/START-HERE.md in full. It is written for exactly this moment.
2. Read AGENTS.md, then CLAUDE.md. They define the Rojo mapping and the
   file conventions. Do not guess at either.
3. Read docs/TODO.md section 0 ("LOCKED RULES"). Every rule there is a
   decision the owner already made and does not want reopened. Treat a
   locked rule as settled fact, not a suggestion.
4. Read docs/HANDOFF.md section 2 ("the bible"), then docs/AUDIT.md.
5. Read transcripts/OWNER-MESSAGES.md -- a folder in the repo root that is
   gitignored on purpose, so it is on my disk and not on GitHub. It is
   every message I have sent, verbatim, in order: the real requirements
   document. Also in there: TRANSCRIPT.md (the full exchange), images/
   (screenshots I pasted), session-raw.jsonl.gz (the unprocessed log).
   If that folder is missing, STOP and ask me for it before continuing.
6. Read docs/OPEN.md -- every open task in one place, prioritised.
7. Run: bash tools/verify/syntax.sh
   then:  bash tools/verify/suite.sh
   Confirm it before you change anything, so any later failure is yours.
   Run syntax.sh FIRST and never skip it: 11 of the 23 checks shell out to
   the luau binary it fetches, and without it they print "skipping" and
   exit 0. suite.sh exists to catch exactly that -- it reports DID NOT RUN
   separately from pass and fails the run. trap.js fails on clean main;
   that one is pre-existing and is listed as a known failure.

Then tell me, in plain language and before doing any work:
  - what you understand the game to be
  - what state you believe the branch is in
  - what you think the single most important next task is, and why
  - anything in the docs that contradicts anything else in the docs

Do not start coding until I answer. After that, work on the branch
claude/vigilant-fermi-aucqjy and nowhere else.

Four standing rules the last agent worked under, which still apply:
  - Hound me with questions so nothing is EVER unclear. If you would
    otherwise be guessing what I want or mean, ask, however small. Look
    in the repo first, restate what you think I want in 1-3 lines, then
    ask every question you need in one batch (grouped by topic, multiple
    choice, your recommended default first, no cap) and wait for the
    answers. Stop and ask the moment a new doubt appears. If you cannot
    reach me, do only safe reversible steps and list your questions.
  - Verify a claim in the code before you act on it. The docs are good
    but they are not the code, and "the code already does X" has been
    wrong here more than once.
  - I am on Windows PowerShell. Never hand me a command with && in it,
    and never hand me a command with a <placeholder> in it -- angle
    brackets are a reserved operator and the command will not run.
  - End every reply with the current todo list.
```

---

# 2. What the game is

**"MINE FOR CARDS! SEASON ONE"** — Roblox, placeId `73982848847016`, owned by the
**Mine For Cards group, `35326298`** (not a personal account; see §6).

A mining game. You swing a pickaxe at blocks, blocks drop ore, ore buys better
pickaxes, better pickaxes reach deeper layers, deeper layers hold rarer ore. On
top of that loop sit the collection systems: card packs, pets, skins, traits,
charms, a skill tree, and rebirths.

The loop in one line: **dig → ore → forge a better tool → dig deeper → repeat**,
with packs and pets as the dopamine on the side.

What a new player actually does, in order:

1. Spawns at the **surface outpost**. Gets a free starter pickaxe.
2. Mines surface blocks. Ore goes in a backpack with a capacity limit.
3. Walks back to the outpost, **sells** ore for coins, **banks** it, repeats.
4. At the **Forge**, spends ore to craft a better tool *of that ore*. A stone
   pickaxe costs stone. Upgrading it costs more stone. (This was a deliberate
   redesign — see locked rules.)
5. Descends through **layers**. Each layer needs more breaking power than the
   last.
6. Hits **layer 500** and stops, because the seam-purchase prompt was never
   wired. **This is the ship blocker.** See §5.

---

# 3. Where the code lives

The repo is a Roblox source tree synced into Roblox Studio with **Rojo 7.7**.
`default.project.json` maps `src/` onto Roblox services. 210 `.luau` files.

| path | what it is |
|---|---|
| `src/ReplicatedStorage/Mine/Shared/` | the data modules — ores, tools, traits, packs, skills, config. Most design work happens here. |
| `src/ServerScriptService/Mine/MineServer.server.luau` | the server. Authoritative for everything. Large. |
| `src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau` | the client. UI, input, pet movement. |
| `src/ServerStorage/MineParked/` | archived features, deliberately not deleted |
| `tools/verify/` | the test suite. Node scripts + one shell script. |
| `docs/` | everything written down. Start with TODO.md. |

**`$ignoreUnknownInstances` is set, which means Rojo never deletes anything in
Studio that is not in the repo.** That is load-bearing. These live **only in the
place file and are not in git**:

- the entire Workspace (the map, the mine, the outpost)
- Lighting, Teams, TextChatService
- `ToolModels_50` — the tool meshes

So: **`rojo build` from this repo produces a place that opens with no game in
it.** That is not a bug and it is not fixable from the repo alone. To see the
game you must open the real place file in Studio and sync Rojo into it.

---

# 4. The traps — read this twice

Every one of these cost real time. They are not hypothetical.

**4.1 — Luau's 200 top-level-local ceiling.** `MineServer.server.luau` sits at
about 197 top-level locals. Add four more and the file will not compile, with an
error that does not obviously say that. The workaround used throughout is to hang
new things off an existing table instead of declaring a new local — that is why
you will see `Dig.Traits`, `Dig.Layers`, `Dig.QUAKE`. Follow that pattern.

**4.2 — the global-read trap, the worst one.** In Luau, referencing a `local`
*above* the line that declares it does not error. It compiles as a **global
read** and is `nil` at runtime, silently. No warning, no crash, just wrong
behaviour somewhere else.

```lua
local function craft()
    p.oreToolEquipped = uid   -- uid is nil here, silently
end
local uid = row.uid           -- declared below, too late
```

This caused at least three bugs in this project, including one where crafting a
tool silently unequipped it. **When something is mysteriously nil, check the
declaration order first.**

**4.3 — this Luau build has no `os.exit`** and no infix bitwise operators (use
`bit32.bxor`, not `~`). `Random` is a Roblox API and does not exist in standalone
luau, so test harnesses must stub it.

**4.4 — a stat key is DATA.** Keys like `fossilFind` are stored on saved runes
and gear in live player data. Renaming one is a **save migration**, not a
refactor. This is why `fossilFind` still has that name even though fossils were
deleted from the game.

**4.5 — verification scripts must strip comments before matching.** Four separate
checks in `tools/verify/` were written with a regex that matched the agent's own
explanatory comments and passed or failed for the wrong reason. If you add a
check, strip comments first.

---

# 5. State of the branch, honestly

Branch `claude/vigilant-fermi-aucqjy`, **101 commits ahead of main**, open as a
draft PR. The verification suite passes except `tools/verify/trap.js`, which
**fails on clean main too** — pre-existing, not yours.

**The thing you most need to know:** almost none of the recent work has ever run
in Roblox. The Forge rewrite, the proc split, the two-layer boost system, the
regenerated skill tree and the traits system were all written, verified by static
analysis, and pushed — **without once being loaded into the engine.** Exactly one
change in the entire session was confirmed working in-game (a UI layering fix).

So treat the branch as **plausible but unproven**. The highest-value thing anyone
with Studio access can do is not write code. It is open the place, sync, and play
through it.

**A correction worth reading, because it shows how this repo bites.** This file
previously said the seam purchase was an unwired ship blocker — that
`Verbs.buySeam` existed and nothing called it, so every player stopped at layer
500 forever. **That was wrong.** The chain is complete: the server fires a
`seamGate` event, the client's handler opens the panel, the panel fires
`buySeam` back. See `docs/OPEN.md` P0 item 1 for the six-line call chain.

The mistake was grepping for `buySeam` and finding only the server half. The
client reaches it through a *different* name — the event — so one grep looked
like proof of absence. **Client/server round-trips here are named differently on
each side. Grep both the verb and the event name before you conclude anything is
unwired.** There is no `Remotes` type system to lean on; the router is a string
compare on `action`.

---

# 6. Working with this owner

Learned the hard way over about a week. None of this is optional.

- **Ask first, always (2026-10-08).** *"from now on i want ALL agents to fucking
  hound me with questions so noithing is EVER unclear"*. If you would otherwise be
  guessing, ask, however small. The full rule is in `CLAUDE.md`; the reasoning is in
  `wiki/owner.md`. Do not re-ask what `docs/TODO.md` §0 locked, but do ask whether
  one applies.
- **Windows PowerShell.** `&&` is not a statement separator in 5.1. `<angle
  brackets>` are a reserved operator and will throw a parser error. Never use
  either. One command per line, real quoted paths, never a placeholder.
- **The owner does not know their repo path and should not need to.**
  `tools/start-local-agent.ps1` finds it by searching `$HOME` for
  `default.project.json`.
- **Verify before you implement.** Repeatedly, something assumed missing already
  existed, and something assumed present was dead code. Check the code.
- **Say BLOCKED plainly, then say exactly what unblocks it.** `docs/BLOCKED.md`
  has the format and eleven unanswered questions with suggested defaults.
- **Icons are the owner's job.** They said so. Do not generate any.
- **Asset uploads go to the group, never the personal account.** Set
  `creationContext.creator.groupId = "35326298"`. Names are prefixed
  `mfc_<feature>_<name>_vN`. If an upload shows creator *iPressBars*, stop and
  re-upload — that is the personal account and it must not own shipping assets.
- **End every reply with the todo list.** A standing instruction.
- The owner swears when frustrated and it is almost always because something was
  promised and did not work. Fix the thing; do not manage the tone.

---

# 7. Reading order

| # | file | why |
|---|---|---|
| 1 | `AGENTS.md` | Rojo mapping, file conventions, sync workflow |
| 2 | `CLAUDE.md` | working rules |
| 3 | `docs/TODO.md` §0 | the locked rules — settled decisions |
| 4 | `docs/HANDOFF.md` §2 | the bible |
| 5 | `docs/AUDIT.md` | what the game is and what is worth keeping |
| 6 | `transcripts/OWNER-MESSAGES.md` *(gitignored, on the owner's disk)* | every owner message, verbatim — the real spec |
| 6b | `docs/OPEN.md` | every unfinished task in one place, prioritised |
| 7 | `docs/BLOCKED.md` | the eleven open questions |
| 8 | `docs/ROADMAP.md` | the 1-min to 96-hour progression plan |
| 9 | `docs/BALANCE-PROPOSAL.md`, `docs/SKILL-TREE.md` | the numbers |

Then run the suite, in this order:

```
bash tools/verify/syntax.sh     # fetches the luau binary -- do not skip
bash tools/verify/suite.sh      # runs all 23 checks, PASS / FAIL / DID NOT RUN
```

**4.6 — a skip is not a pass, and the suite used to say it was.** Eleven of the
twenty-three checks shell out to the luau binary that `syntax.sh` fetches into
the gitignored `.luau-bin/`. When that binary is missing they print
`luau not present — skipping` and **exit 0**. There was no runner, so checks
were run by hand and eleven silent greens looked exactly like eleven real ones.

Measured 2026-10-05 on this branch, binary removed: **10 passed, 11 did not
run** — and the old way of running them reported that as a clean suite.
`suite.sh` now counts DID NOT RUN separately and exits non-zero for it.

The related worry — that a regex matching nothing leaves a check asserting over
an empty slice and passing — is real in principle but was **not** what was
happening here. The checks that parse rosters (`charms`, `orepacks`,
`build-stamp`) do floor their row counts and fail loudly on zero. The ones to
watch are negative assertions of the form `check(x.length === 0)`, which pass
when the regex finds nothing: `skilltree.js:48` and `:100`, and
`forge-snap.js:63`. Those three want a non-zero floor on their source set.

---

# 8. If the local agent will not start

The owner hit **"Credit balance too low · Add funds"** when launching Claude Code
locally. That is not a Claude Code fault and adding funds is not the fix.

Claude Code bills to **API credits** whenever `ANTHROPIC_API_KEY` is set in the
environment — an API key always outranks a subscription login. The account it was
billing has a zero balance. To use a Claude subscription instead, clear the key
and log in:

```powershell
Remove-Item Env:\ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
[Environment]::SetEnvironmentVariable('ANTHROPIC_API_KEY', $null, 'User')
claude
```

Pick the Claude-account option at the login prompt. Inside a running session,
`/login` switches accounts. Only add credits if you actually want pay-as-you-go
API billing rather than a subscription.

---

# 9. The conversation history — handed over as files, not in this repo

`CLAUDE.md` forbids committing raw conversation exports into tracked files, and
the tooling enforces that. So the record of how this branch came to exist lives
in a **`transcripts/` folder at the repo root, which is in `.gitignore`** — on
the owner's disk, never pushed.

**Owner:** unzip `mine-for-cards-transcripts.zip` into the repo root so the path
is `PullAPick/transcripts/`. That is the one place the prompt in §1 tells the
agent to look. Nothing in it can be committed by accident.

| `transcripts/…` | what it is |
|---|---|
| `OWNER-MESSAGES.md` | every message the owner sent, verbatim, in order — 79 of them. The requirements document. |
| `TRANSCRIPT.md` | the full exchange, owner and agent. Tool *calls* appear as one-line markers; tool *output* and internal reasoning are stripped out. |
| `images/1`–`images/8` | the screenshots the owner pasted — Forge UI, the inventory layering bug, a jewellery reference for charm icons. |
| `session-raw.jsonl.gz` | the unprocessed session log, if anything above looks wrong. |

**Agent: if that folder is not there, stop and ask for it.** Everything in
`docs/` is one agent's interpretation of what the owner wanted.
`OWNER-MESSAGES.md` is what they actually said. Where the two disagree, they win.
