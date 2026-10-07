# Claude Code Project Notes

This repository is a Roblox experience source tree synced to Studio with Rojo.
Read `AGENTS.md` first; it defines the Rojo mapping, file conventions, and
Studio sync workflow.

## Ask before you assume — standing instruction from the owner

The owner wants Claude to **always ask follow-up questions when a request is
broad, or when Claude is not sure what they mean**. Guessing has cost this
project days (see `wiki/owner.md`). A good question is cheaper than a wrong
change.

Stop and ask before doing the work when any of these is true:

- **The request is broad.** Examples: "fix the economy", "make packs fun",
  "rebalance", "redo the UI", "clean it up", "make it better". Ask what outcome
  they want, how far the change should reach, and which systems it should touch.
- **The request uses an ambiguous word with no context.** Examples: tool, pack,
  level, tier, shop, gear, boost, chest, case, rune. `wiki/ambiguous-terms.md`
  lists them; ask which meaning they intend.
- **The change needs a number or a taste call the owner has not made.** Check
  `docs/TODO.md` §0, `docs/PROPOSAL.md` §0 and `docs/BLOCKED.md` first. If the
  answer is not there, ask, and offer your default.
- **The request conflicts with a locked rule, a doc or the code.** Say so plainly
  and ask. Do not quietly pick a side.
- **Two reasonable readings would produce different work.**
- **You hit any of the above partway through.** Stop and ask before guessing,
  and always before anything hard to undo.

How to ask:

- **Do the cheap homework first.** Read the wiki page and the code, so the
  question is specific. Never ask something the repo can answer.
- **Ask 1–4 short questions at once.** Give each one concrete options, with your
  recommended default first. Use `AskUserQuestion` when it is available. Use
  plain language, since the owner is not always looking at code.
- **If the owner says "just do it" or "you decide", go ahead** with your
  defaults, then list every assumption you made at the end.
- **Do not ask when the request is clear and small.** Never re-ask a locked rule
  in TODO §0; those are marked "do not ask again".

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
