---
title: Mine For Cards wiki — start here
type: meta
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - CLAUDE.md
related: [index, SCHEMA, overview]
---

# Mine For Cards wiki

This is the project's knowledge base for **Mine For Cards** (the repo is called
PullAPick). **Claude writes and maintains it; you read it and steer it.** It
follows the "LLM wiki" pattern:

- Claude reads the raw sources: the code, `docs/`, `roadmap/`, PRs and your
  messages.
- It distils them into short, linked pages.
- It keeps those pages current as the game changes.

The point is that every new Claude session starts informed, rather than
rediscovering the game from scratch.

- **Browsing?** Start at [index](index.md), or read [overview](overview.md) for
  the game in one page.
- **Want to know how it is maintained?** See [SCHEMA](SCHEMA.md).
- **Using Claude.ai rather than Claude Code?** See
  [claude-ai-setup](claude-ai-setup.md).

## Talking to it, in Claude Code

| say | what happens |
|---|---|
| `/wiki ingest docs/OPEN.md` | Claude reads the source, updates every page it affects, and logs it. |
| `/wiki ingest transcripts` | Claude summarises your decisions from the gitignored transcripts into the wiki. Raw text is never committed. |
| `/wiki query how does breaking power work?` | Claude answers from the wiki plus the code, with citations. If the answer is durable, it files it back. |
| `/wiki lint` | Claude runs `node tools/verify/wiki.js`, then checks for contradictions and stale pages. |
| `/wiki status` | Shows recent activity and which pages are out of date. |

You do not have to use the slash command; asking in plain words works too.

## "Ask me first"

Claude is set up to **ask follow-up questions when a request is broad or
unclear** instead of guessing. Three things make that happen:

- the "Ask before you assume" rules in `CLAUDE.md`
- a reminder hook that runs on every prompt (`.claude/settings.json`)
- [ambiguous-terms](ambiguous-terms.md), a list of the words in this project
  that mean more than one thing

If it ever asks too much or too little, tell it. That feedback goes into
[owner](owner.md).
