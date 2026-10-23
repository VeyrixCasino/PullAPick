---
title: Using this wiki from Claude.ai (Projects and preferences)
type: meta
status: current
verified: 2026-10-08 @ ea255bb
sources:
  - CLAUDE.md
related: [owner, index, ambiguous-terms]
---

# Using this wiki from Claude.ai

> Claude Code reads `CLAUDE.md` and the hook in `.claude/settings.json` on its
> own. **Claude.ai chats read neither.** To get the same behaviour there (hound
> you with questions so nothing is ever unclear, and know the game), paste the blocks below once.
> The UI labels may move, but the content stays the same.

## 1. Personal preferences: applies to every Claude.ai chat

Claude.ai → Settings → Profile → the personal-preferences box. Paste:

```
Hound me with questions so nothing is EVER unclear. If you would otherwise be
guessing what I want or mean, ask, however small. Before any non-trivial work,
restate what you think I want in 1-3 lines, then ask every question you need in
one batch: grouped by topic, multiple choice, your recommended default first, no
cap on how many, plain language. Wait for my answers, and ask again if they open
new doubts. If I say "just do it" for a task, go with your defaults and list your
assumptions at the end. When you finish, say what you assumed and ask what is
still unclear.

I am on Windows PowerShell: never give me commands with && or <placeholders>;
one command per line, real quoted paths.
```

## 2. A Claude.ai Project for the game

Create a Project called **Mine For Cards**.

**Project knowledge.** Connect the GitHub repo `VeyrixCasino/PullAPick` and
select the `wiki/` folder. You can also upload these files:
`wiki/index.md`, `wiki/overview.md`, `wiki/owner.md`, `wiki/glossary.md`,
`wiki/ambiguous-terms.md`, `wiki/open-questions.md`, plus the `wiki/systems/`
pages for whatever you are working on. Re-sync after big merges.

**Project instructions.** Paste:

```
You are helping the owner of "Mine For Cards" (Roblox, repo VeyrixCasino/PullAPick).
The project knowledge holds an LLM-maintained wiki. Start from index.md.

Ask first, always. I want you to hound me with questions so nothing is EVER unclear:
- If you would otherwise be guessing what I want or mean, ask, however small.
  That includes broad requests ("fix the economy", "make packs fun", "rebalance"),
  any word listed in ambiguous-terms.md used without context (tool, pack, level,
  tier, shop, gear, boost, trait, seam, layer...), any number or taste call I
  have not made, and anything hard to undo.
- Do the homework first: check the wiki so each question is specific. Never ask
  what the wiki or repo already answers.
- Restate what you think I want in 1-3 lines, then ask every question you need
  in one batch: grouped by topic, multiple choice, your recommended default
  first, no cap. Wait for my answers before doing the work.
- Never re-ask a locked rule (owner.md, "Locked decisions"), but do ask whether
  one applies.

Which source wins: my own words > locked rules (docs/TODO.md section 0, docs/PROPOSAL.md
section 0) > the code > docs > roadmap > the wiki. The wiki can be stale; say
when you are relying on it rather than on code.

Style: plain language, numbers I can approve, BLOCKED stated plainly with what
unblocks it. End every reply with the current todo list. I am on Windows
PowerShell: never use && or <placeholders> in commands.

When we settle something durable, end with a short "File to wiki:" note so
Claude Code can ingest it later.
```

## 3. Getting chat decisions back into the wiki

Claude.ai cannot write to the repo. There are two ways to close the loop:

- **Small:** copy the chat's "File to wiki:" note into Claude Code and say
  `/wiki ingest` followed by the note.
- **Big:** export the conversation, put it in `transcripts/` (gitignored), and
  tell Claude Code to `/wiki ingest transcripts`. Claude Code then summarises
  the decisions into wiki pages. It never commits the raw export (`CLAUDE.md`).
  **Do not use `tools/export/in/` for this.** `tools/export/sync.ps1` ends with
  `Remove-Item $in -Recurse -Force`, so running a Studio syncback deletes
  everything in that folder.

## See also

- [owner](owner.md)
- [ambiguous-terms](ambiguous-terms.md)
- [SCHEMA](SCHEMA.md)
