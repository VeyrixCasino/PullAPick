---
title: Using this wiki from Claude.ai (Projects and preferences)
type: meta
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - CLAUDE.md
related: [owner, index, ambiguous-terms]
---

# Using this wiki from Claude.ai

> Claude Code reads `CLAUDE.md` and the hook in `.claude/settings.json` on its
> own. **Claude.ai chats read neither.** To get the same behaviour there (ask
> first when you are broad, and know the game), paste the blocks below once.
> The UI labels may move, but the content stays the same.

## 1. Personal preferences: applies to every Claude.ai chat

Claude.ai → Settings → Profile → the personal-preferences box. Paste:

```
When my request is broad or you are not sure what I mean, ask me 1-4 short
questions before doing the work. Give each question concrete options with your
recommended default first, in plain language. If the request is clear and small,
just do it. If I say "just do it" or "you decide", go with your defaults and list
the assumptions at the end.

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

Ask before you assume:
- If my request is broad ("fix the economy", "make packs fun", "rebalance"),
  ambiguous, uses a word listed in ambiguous-terms.md without context (tool,
  pack, level, tier, shop, gear, boost, trait, seam, layer...), or needs a
  number or taste call I have not made, ask 1-4 short questions with options
  and your recommended default BEFORE answering in full.
- Do the homework first: check the wiki so the question is specific.
- Never re-ask a locked rule (owner.md, "Locked decisions"). Those are settled.

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
