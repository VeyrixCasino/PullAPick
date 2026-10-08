---
title: Wiki log
type: meta
status: current
verified: 2026-10-08 @ bae3c5b
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

## [2026-10-07] ingest | the owner's session: chunking, veins, the ToolModels archive
Ingested from the working branch (`8d5c230`..`41d8f3a`) and from live Studio
measurements, because most of this was measured rather than reasoned.

**Chunking.** `MineDigAuth.canCreditDepth` splits depth CREDIT from digging:
`canDigLayer` ends in an unconditional `return true`, so one block at layer 5000
credited depth 5000 to anyone. `chunkCeiling` is the generation twin, clamped
inside `ensureZone`. Also fixed `ensureZone`'s far path claiming `builtTo`, which
left layers 4–2505 permanently ungeneratable after a plaza arrival. New checks
`depthgate.js` and `chunkload.js`.

**Veins, rebuilt.** `VEIN_ORDER` gave every size exactly one silhouette (a four
was always a flat 2×2 slab; 6 and 8 never occurred). Shapes are grown per cell
now, seeded per ore. Size comes from cost/drop/rarity plus a per-ore spread
instead of three tier-index bands. Density and per-ore shares are conserved
throughout — `veinWeights` divides by the mean — and `veins.js` measures both
sides. Two of my own errors are recorded: pricing cost with `toolCraftCost`
double-counted yield, and an unsliced constant with an `or` fallback made the
harness measure defaults silently.

**`oreWeights` cached per section while computing `dl` per layer**, so the first
layer asked set the mix for 49 layers and two servers disagreed at the same
depth. Now keyed on quantised `dl`.

**`ToolModels_50`** was 58% of every client's datamodel; 2,060 unreferenced models
(70,040 instances) moved to `ServerStorage.ToolModels_50_Unreferenced`. Client
`InstanceCount` 137,444 → 67,537, shop resolution unchanged.

Marked probable bugs 3, 5 and 15 **fixed** with their measured before/after. Added
§1b with four new entries, the first being that **nothing multiplies ore
quantity** although the owner expects endgame enchants to.

Updated: ores, zones-layers-and-seams, tools, verify-suite, open-questions, log.
Not rechecked: bugs 4, 6–14, 16, and every rule/code disagreement in §2.

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

## [2026-10-08] refactor | the wiki now follows the owner's working branch
The owner chose (asked twice) that the wiki follows `claude/vigilant-fermi-aucqjy`,
that the ask-first rule reaches their branch through a PR their other session merges
(never a push from here), and that conflicts resolve as "merge both; theirs wins on
code facts". Merged that branch (`bae3c5b`) into this one (`06b5f89`). Five pages
conflicted: `ores` (their rebuilt Veins block won; my K 0.228/0.353/0.434 figures were
stale because `ORE_K_TOP` is now 0.040 after `41d8f3a`, so I replaced them), `open-questions`
(kept my rows 3, 5 and 15 for the commit hashes and measurements, added their "caught the
same break twice more"), `verify-suite`, `zones-layers-and-seams` and this log. After the
merge: `wiki.js`, `askfirst.js` and `syntax.sh` clean, and the suite is **45 passed, 0
failed, 0 did not run**, with `compile.js` at 5 and 7 registers left (215 files).

## [2026-10-08] ingest | the owner's session: 36 charms, traders, season hold (`b09cc4a`..`bae3c5b`)
Eight commits the other session's own ingest (`c9b93c6`) predates. Read the code, not only
the messages. New pages: [wandering-traders](systems/wandering-traders.md) and
[season-and-launch](systems/season-and-launch.md). Updated: charms (the 36 graded charms,
their two ways in, prices), chests-and-lucky-blocks (the 0.5% drop), shops-and-monetisation,
skins-cases-and-temper (new temper-token sinks), world-events (the season-end gotcha was
stale: offers now end 11-08), tools, glossary, ambiguous-terms (`launch`, `trader`,
`charm`, `tokens`), index, overview, owner, sources-of-truth, server, client-and-ui,
code-map, tools-and-generators, verify-suite (`launch`, `trader`; 45 checks, 22 run the luau
binary) and open-questions.

**Four findings from reading the code, none fixed** ([open-questions](open-questions.md)
§1b, #21–#24): nothing in `src/` sends `buyCharm`, so the token half of the graded charms
has no shop; nothing sends `launchSeason`, so the owner has no launch button; the battle
pass ends 2026-11-01 while the offers end 11-08; and Chest Luck raises the chest charm drop
though a code comment says it does not. Also reframed bug 4 (Event Horizon) as the owner
did in TODO §6.1: a missing progression, not a breaking-power bug. Not rechecked: the
`ToolModels` archive move and anything not in the eight commits.
