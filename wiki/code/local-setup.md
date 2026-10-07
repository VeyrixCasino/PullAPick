---
title: Local setup on the owner's machine
type: code
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - docs/HANDOFF.md §1
  - docs/START-HERE.md §1, §6, §8, §9
  - docs/TODO.md §0.31, §0.32, §2
  - tools/start-local-agent.ps1
  - tools/claude-rojo-clean.ps1
  - .claude/settings.json
  - .claude/launch.json
  - .vscode/extensions.json
  - .gitignore
  - CLAUDE.md
related: [owner, rojo-and-studio, verify-suite, tools-and-generators, assets-and-uploads]
---

# Local setup on the owner's machine

> A cloud session cannot see Studio, the place file or the owner's disk
> (TODO §2). A Claude Code session on the owner's **Windows** machine can do all
> of that. This page covers how to start one, what to tell it, and the rules for
> commands handed to the owner.

## Starting a local agent (HANDOFF §1)

**Option A: run Claude Code locally.** This is what the owner wants.

- **Bootstrap script:**
  `powershell -ExecutionPolicy Bypass -File .\tools\start-local-agent.ps1`
  (or right-click the file and choose Run with PowerShell). The script:
  1. finds the repo, by searching `$HOME` for `default.project.json` when it is
     not run from inside the repo
  2. runs `git pull`
  3. checks that Node is installed
  4. runs `npm install -g @anthropic-ai/claude-code` if `claude` is missing
  5. **adds the npm global folder to PATH in the current window**
  6. launches `claude`
- **No-script version:** four lines in HANDOFF §1 do the same search, `cd` and
  `git pull`. The owner does not know the repo path and should not need to
  (TODO §0.32).
- **First thing to say:** paste §1 of `docs/START-HERE.md` (TODO §0.33). The
  script's closing hint says "read docs/HANDOFF.md and continue", which predates
  START-HERE. Prefer the START-HERE prompt.

**Option B:** run `claude remote-control` inside the repo folder, so a cloud
session can reach the disk.

**`tools/claude-rojo-clean.ps1`** is an alternative launcher. It:

- removes `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_API_KEY` and `ANTHROPIC_BASE_URL`
  from the user's Claude settings and environment
- asks "[1] Claude account sign-in (default) [2] Anthropic API key". The key is
  read hidden and only lives for that session.
- starts `claude --add-dir tools\export\in`
- passes extra arguments through, for example `--continue`

## "Credit balance too low · Add funds" (START-HERE §8, TODO §0.32)

That message is about **where Claude Code gets its auth**, not about money.

- When `ANTHROPIC_API_KEY` is set, Claude Code bills **API credits**. A key always
  outranks a subscription login.
- The fix is to clear the key, run `claude`, and pick the Claude-account option.
  `/login` switches accounts inside a running session.
- **Do not tell this owner to add funds.**

The exact PowerShell lines are in START-HERE §8 and HANDOFF §1.

## Rules for any command handed to the owner (TODO §0.31)

- They use **Windows PowerShell 5.1**. **Never use `&&`**: use a new line, or `;`.
- **Never use `<angle-bracket placeholders>`.** They are a reserved operator and
  throw a parser error.
- Give one command per line, with real quoted paths. If a path has to be found,
  give the search command, as HANDOFF does with `Get-ChildItem … default.project.json`.
- Even repo files slip on this. The not-found branch of
  `tools/start-local-agent.ps1` prints a `cd "<that path>"` hint.
- End every reply with the current todo list, and say BLOCKED plainly (`CLAUDE.md`).

## What the local agent has that the cloud does not

- Studio, so it can run Rojo serve and connect ([rojo-and-studio](rojo-and-studio.md))
- the Output window and screenshots
- the place file, and the syncback in `tools/export/`
- if Studio MCP is attached: uploads, following the group rules in
  [assets-and-uploads](assets-and-uploads.md)

Its checks run the same way ([verify-suite](verify-suite.md)): `syntax.sh` needs
a bash, such as Git Bash *(the owner's setup is unverified)*.

## Repo configuration for agents

**`.claude/settings.json`:**

- `defaultMode: bypassPermissions`
- **deny:**
  - force-push, `git reset --hard`, `git clean`, `sudo`
  - editing any `.rbxm` or `.rbxl`, or anything under the export inbox
  - reading `.env` files and `~/.ssh`
- **allow:** reading and editing `src/`, `docs/`, `tools/` and `.claude/`, plus
  `node tools/*.js`, `rojo`, `rokit` and the read-only git commands
- Added in the wiki commit just after `26036a0`:
  - `Edit(wiki/**)`
  - a `UserPromptSubmit` hook that repeats the clarify-first rule on every prompt
  - the `/wiki` skill under `.claude/skills/`

**`.claude/launch.json`:** one config, "tools", which runs `node tools/serve.js`
on port 7421 ([tools-and-generators](tools-and-generators.md)).

**`.vscode/`:**

- recommends the Rojo, Luau LSP and StyLua extensions
- the Luau LSP builds a sourcemap from `default.project.json`
- `tasks.json` holds serve, sourcemap, build and the two syncback steps

## The `transcripts/` folder (START-HERE §9)

- **What it is.** The owner's chat history, handed over as files and **never
  committed**. The owner unzips `mine-for-cards-transcripts.zip` into the repo
  root, so that `transcripts/` holds:
  - `OWNER-MESSAGES.md`: every owner message, verbatim (79 of them). **This is
    the real spec.**
  - `TRANSCRIPT.md`
  - `images/1`–`8`
  - `session-raw.jsonl.gz`
- **It is gitignored.** `.gitignore` ignores `transcripts/`, and also
  `mine-for-cards-transcripts/` and the `.zip`. The folder used that name on disk
  and was only *untracked*, which put 15 MB one `git add -A` away from GitHub.
- **If it is missing, stop and ask for it** (START-HERE §1 step 5). Where the
  owner's words disagree with `docs/`, the owner wins (`wiki/SCHEMA.md`).
- **Claude.ai exports** go in the gitignored `tools/export/in/`, under the same
  rules (`CLAUDE.md`): read them only when asked, summarise decisions, never
  commit raw text. Note that a Studio syncback deletes that folder
  ([rojo-and-studio](rojo-and-studio.md)).
