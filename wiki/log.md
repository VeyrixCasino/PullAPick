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

## [2026-10-08] ingest | main after PR #6 merged (9 commits since b19c4c2)
Asked "are we good to go?", I found PR #6 merged into `main` on 2026-10-06
(`ea255bb`) and its branch nine commits past the last ingest, so PR #7 pointed at
a stale base and the wiki described old code. Merged `main` into this branch (no
conflicts) and read all nine commit messages. The owner's session had **fixed
three more of the wiki's findings**: depth desks (bug 5) and the recycle loop
(bug 3) in `4cc82a5`, and the 200-local ceiling (bug 15) with a new `compile.js`
check in `5d59714`. I read the new code to confirm each and ran `compile.js`
(5 and 7 registers left). Other ingests: 246 per-ore tool skins, forge frame
stats baked so the coin tool roster can be deleted, UI rescale, vein cost and
random-mine fix, first layers mostly stone, pet bob rate, shadows (a Studio-only
change), the Rojo stale-sync gotcha, and a correction that the 2026-10-05 upload
"ownership" problem was moderation latency. Suite: **40 passed, 0 failed, 0 did not
run** (was 36; new checks `compile`, `economy-exploits`, `oreframes`, `ui-scale`).
Owner's newest decisions are in [owner](owner.md). Still open: bugs 4 and 6-13 and
16 in [open-questions](open-questions.md). Retargeted PR #7 to `main`.

## [2026-10-08] refactor | ask first, always: a stronger rule for ALL agents
The owner said: *"from now on i want ALL agents to fucking hound me with questions
so noithing is EVER unclear"*. That replaces the softer 2026-10-05 rule. Rewrote
"Ask first, always" in `CLAUDE.md` (no cap on questions, restate before starting,
ask the moment a new doubt appears, list assumptions at the end, and what to do when
nobody can answer) and added it to `AGENTS.md`, `tools/agent/house-rules.txt`, the
pasted prompts in `docs/START-HERE.md` and `docs/FABLE-PROMPT.md`,
`roadmap/AGENT_PROMPT.md`, `roadmap/PROMPTS.md`, `docs/HANDOFF.md`, TODO §0.35 and
§9, and the Claude.ai text. Replaced the `FABLE-PROMPT` line that said to ask only
"one sharp question rather than guessing or stopping". Added a `SubagentStart` hook
beside the prompt hook, and `tools/verify/askfirst.js` (proved to fail on a broken
copy). Subagent coverage was tested rather than assumed: the JSON hook reached a
general-purpose subagent, and did not reach the built-in `Explore` type (see
[local-setup](code/local-setup.md)). Four design points were applied on my defaults
and put to the owner as questions: the cap, locked rules, unattended runs, and
restating before work.

## [2026-10-08] query | owner confirms the four ask-first design points
Asked the owner four open design points about the ask-first rule (question cap,
locked rules, unattended runs, restating first). Every answer was the recommended
default, which was already live, so no rule changed. Recorded in [owner](owner.md)
and TODO §0.35. Found while checking the branches: the owner's working branch
`claude/vigilant-fermi-aucqjy` holds an older merge of this wiki (`c04adad`) plus its
own ingest (`c9b93c6`), and does not have the ask-first rule or hooks. Reconciling
the two lines is an open question for the owner (5 wiki files would conflict).
