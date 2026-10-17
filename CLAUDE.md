# Claude Code Project Notes

This repository is a Roblox experience source tree synced to Studio with Rojo.
Read `AGENTS.md` first; it defines the Rojo mapping, file conventions, and
Studio sync workflow.

## Ask first, always — standing instruction from the owner (2026-10-08)

The owner wants **every agent to hound them with questions so nothing is EVER
unclear.** This replaces the softer rule that used to sit here. Guessing has cost
this project days (see `wiki/owner.md`); a question costs them seconds.

**The test: if you would otherwise be guessing what the owner wants or means,
ask. However small it looks.** Being wrong quietly is the failure, not asking too
much.

**Before you start any non-trivial work:**

1. **Look first.** Read the wiki page, the code, `docs/TODO.md` §0,
   `docs/PROPOSAL.md` §0 and `docs/BLOCKED.md`. Never ask what the repo can
   answer. Put what you found *in* the question, so they only have to decide.
2. **Restate it.** In 1–3 lines: what you think they want, what you will change,
   what you will leave alone, and every assumption you are making.
3. **Ask every question you need, in one batch.** Group by topic, most important
   first. Make each one multiple choice with your recommended default first, and
   leave room for their own words. There is **no cap** on how many; use
   `AskUserQuestion` when available (it takes 4 at a time, so make several calls
   or list the rest in text). Plain language: they are not always reading code.
4. **Wait for the answers** before doing the work. If an answer opens a new doubt,
   ask again. Keep going until nothing is unclear.

**Always ask when:** the request is broad ("fix the economy", "make packs fun",
"rebalance", "clean it up"); it uses a word from `wiki/ambiguous-terms.md` with no
context; it needs a number or a taste call they have not made; it conflicts with a
locked rule, a doc or the code; two readings would produce different work; the
scope could grow; anything is hard to undo or outward-facing (push, merge, delete,
post, spend); or **you catch yourself assuming something**.

**While you work:** the moment a new doubt appears, stop and ask. Do not push
through on a guess.

**When you finish:** list what you assumed, what you verified and how, and what
you could not verify, then ask what is still unclear.

**What not to ask:**

- Facts the repo can answer (look, then cite).
- Decisions already locked in `docs/TODO.md` §0, which says "do not relitigate".
  But **do ask** when it is unclear whether a locked rule applies, or when new
  work might conflict with one.

**When nobody can answer** (scheduled check-ins, background runs, PR babysitting,
subagents): do not guess on anything non-trivial. Take only safe, reversible
steps, write the questions down (in your report, the PR, or
`wiki/open-questions.md`), and ask at the next chance. **Subagents cannot reach the
owner:** put your questions at the top of your final report, with options and a
default, so the parent agent asks them.

**"Just do it"** counts only when the owner says it for that task. Then go ahead on
your defaults and list every assumption at the end.

## Project wiki (`wiki/`)

`wiki/` is an LLM-maintained knowledge base for this game. You keep it current.

- **Orient yourself there first.** Read `wiki/index.md`, then the pages for the
  area you are touching. The pages cite the code and docs they summarise, so
  verify against the code before you act. Code and the owner outrank the wiki.
- **Follow `wiki/SCHEMA.md`.** It covers page format, which source wins, and the
  ingest / query / lint workflows. The `/wiki` skill runs them.
- **Fix a page in the same commit** when a change makes it wrong. Then run
  `node tools/verify/wiki.js`.
- **File durable answers back into the wiki**, with an entry in `wiki/log.md`.
  This covers comparisons, derived numbers and decisions.

## Working with the owner

Details are in `wiki/owner.md` and `docs/START-HERE.md` §6.

- The owner is on **Windows PowerShell**. Never give them a command containing
  `&&` or a `<placeholder>`. Give one command per line, with real quoted paths.
- End every reply with the **current todo list**.
- Say **BLOCKED** plainly, followed by exactly what would unblock it.

## Working rules

- Make Roblox source changes under `src/`; keep Studio-only binary assets in
  Studio unless the task explicitly involves an exportable model.
- Before changing gameplay, inspect the owning server/client module and a nearby
  caller or test. Keep edits narrow and preserve existing APIs.
- Run the relevant checks under `tools/verify/` after Luau changes.
- Treat `docs/TODO.md` as project context, not permission to take on unrelated
  tasks.

## Claude.ai chat export

Claude.ai exports may be placed in the ignored `tools/export/in/` folder. **Prefer
`transcripts/` (also ignored):** `tools/export/sync.ps1` ends with
`Remove-Item $in -Recurse -Force`, so a Studio syncback deletes everything in
`tools/export/in/`. They are user data, not training data. Only inspect them when the user asks; extract
durable project decisions and preferences into a concise, reviewable summary
instead of repeatedly sending entire transcripts to the API. Never move raw
exports into tracked files or commit them.

The same rule covers the gitignored `transcripts/` folder (`docs/START-HERE.md`
§9). When the owner asks you to ingest it, file the decisions into the wiki as
short summaries, never as copied transcript text.
