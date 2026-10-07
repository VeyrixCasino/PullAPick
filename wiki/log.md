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
schema, 11 top-level pages, 22 system pages and 10 code pages (43 in all). Also
added the `CLAUDE.md` "Ask before you assume" rules, the `UserPromptSubmit`
reminder hook, the `/wiki` skill, and `tools/verify/wiki.js` (which `suite.sh`
runs with the other checks). Lint proven on planted errors; suite: 34 passed,
0 failed, 0 did not run.

## [2026-10-05] ingest | docs/, roadmap/, src/ (first pass)
First full pass over every doc in `docs/` and `roadmap/` and the shared and
server modules, by five parallel research passes (core loop, ore and tools,
build and collectibles, loot and social, codebase). Contradictions and probable
bugs found on the way are in [open-questions](open-questions.md). How current
each doc is, is in [sources-of-truth](sources-of-truth.md). I (the wiki-building
session) re-checked three findings against the code myself: the held-tool
breaking-power fallback, the roster-migration guard, and the `sync.ps1`
deletion of `tools/export/in/`. Everything else in open-questions is marked
*reported*.

## [2026-10-05] ingest | commit 9733a05 (PR #6): tools are forged, not bought
PR #6 gained a commit after the wiki's `26036a0` baseline. It removes every
coin-bought tool path (owner, 2026-10-05), keeps Backpacks, the Ore Pouch and
Secrets, and gives each ore tier its own pickaxe icon. Merged into this branch.
Updated: tools, shops-and-monetisation, currencies-and-economy, owner, glossary,
overview, open-questions, verify-suite (35 checks; `oreskins`),
tools-and-generators (new `tools/icons` scripts), luau-traps (the 200-local
ceiling broke the server again). Re-checked that `equippedTool` and the
`oreRosterV` guard are untouched by it, so probable bugs 1 and 2 still stand.
Pages not touched by that commit keep their `26036a0` stamp.

## [2026-10-05] ingest | commit b19c4c2 (PR #6): the wiki's first two bugs, fixed
Found by the 50-minute drift check. PR #6 gained "Forged tools can break rock
again, and migrations stop re-running", which fixes probable bugs 1 and 2 from
[open-questions](open-questions.md): the held-tool row now carries `oreTier` and
`oreId` (before, every forged tool stalled at zone 1, layer 50, measured live),
and both roster-migration guards are `< version`. Read the diff to confirm both.
It also records that the `sync.ps1` deletion of `tools/export/in/` is **not a
bug** (a gitignored scratch folder, deleted by design); I reworded that entry,
keeping the advice to put Claude.ai exports in `transcripts/`. New check
`heldtool.js` (36 checks now) and new `extract-svg-icons.js` / `_png.js`.
Updated: open-questions, tools, mining-and-breaking, ores,
save-data-and-migrations, verify-suite, tools-and-generators, index. Not
rechecked: Event Horizon tools' breaking power, and whether saves hit by the
migration re-runs need repair.
