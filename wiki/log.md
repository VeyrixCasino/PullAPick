---
title: Wiki log
type: meta
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - wiki/SCHEMA.md
related: [index, SCHEMA]
---

# Wiki log

Append-only. Newest last. Each entry starts `## [YYYY-MM-DD] kind | subject`,
where kind is `setup`, `ingest`, `query`, `lint` or `refactor`.

To see the latest entries, run `grep "^## \[" wiki/log.md | tail -5`.

## [2026-10-05] setup | Wiki created
Built on `claude/vigilant-fermi-aucqjy` @ `26036a0` (draft PR #6). That branch
was the newest state on GitHub, about 100 commits ahead of `main`. Added the
schema, the meta pages, 22 system pages and 10 code pages. Also added the
`CLAUDE.md` "Ask before you assume" rules, the `UserPromptSubmit` reminder hook,
the `/wiki` skill, and `tools/verify/wiki.js`.

## [2026-10-05] ingest | docs/, roadmap/, src/ (first pass)
First full pass over every doc in `docs/` and `roadmap/` and the shared and
server modules. Contradictions found on the way are in
[open-questions](open-questions.md). How current each doc is, is in
[sources-of-truth](sources-of-truth.md).
