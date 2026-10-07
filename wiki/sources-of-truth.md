---
title: Sources of truth — every doc, and how far to trust it
type: meta
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - docs/START-HERE.md
  - docs/TODO.md §0
  - roadmap/README.md
related: [index, owner, open-questions, SCHEMA]
---

# Sources of truth

> Dates are the last git change to each file, checked on 2026-10-05. The repo
> moves fast, so **check the code before you trust a doc**; every researcher on
> this wiki found at least one stale claim. See [open-questions](open-questions.md)
> for the specific contradictions.

## Order of authority

See [SCHEMA](SCHEMA.md). In short: the owner's own words, then locked decisions,
then the code on the newest working branch, then current docs, then `roadmap/`,
and last this wiki.

## Where the newest work is

`main` is **behind**. The newest state is the open draft
[PR #6](https://github.com/VeyrixCasino/PullAPick/pull/6), branch
`claude/vigilant-fermi-aucqjy`, about 100 commits ahead of `main`. Other
branches (`ore-face-art`, `ore-tools-power`, `cursor/slice-gem-sprites-cdbb`) are
older, with open draft PRs #1, #2 and #4 on them. `ore-tools-power` carries
the only copy of the `gen-ores.js` `--force-stale` guard, according to the
ore researcher; it is not on the working branch.

**Always `git fetch` and look at open PRs before relying on `main`.**

## Docs that are the authority

| doc | what it is | last change | trust |
|---|---|---|---|
| `docs/TODO.md` §0 | **Locked rules.** Owner decisions, "do not relitigate". | 2026-10-05 | Authority. Some sub-claims are stale; see open-questions. |
| `docs/PROPOSAL.md` §0 | **The 38 signed-off numbers.** Two lines changed afterwards (seams free, two ore reaches). | 2026-10-05 | Authority on *intent*. Several lines are approved but **not built**. |
| `docs/START-HERE.md` | The cold-start prompt plus the traps and the honest branch state. | 2026-10-05 | Good. §2 still says players "sell ore for coins"; it sells for gems. |
| `docs/HANDOFF.md` | "The bible": traps, house style, the owner's complaint list. | 2026-10-05 | Good. §2.5 implies runes are gone; they are not. |
| `docs/OPEN.md` | Every unfinished task, prioritised. | 2026-10-05 | Index into TODO. Some line numbers are stale. |
| `docs/BLOCKED.md` | Questions only the owner can answer (TASTE / FACT / REACH). | 2026-10-05 | Mostly superseded by PROPOSAL §0; a few still open. |

## Docs that are context

| doc | what it is | last change | trust |
|---|---|---|---|
| `docs/AUDIT.md` | Full game audit and the cut list (archive / delete / keep). | 2026-10-04 | Good for the analysis. **Nothing on its cut list has moved yet.** |
| `docs/BALANCE-MEASURED.md` | Boost ceilings and reach measurements, read off the modules. | 2026-10-05 | Good. Reproducible. |
| `docs/PR-BALANCE-PASS.md` | The PR body for the damage curve, level cap and zone gate. | 2026-10-05 | A write-up, not a spec. |
| `docs/BALANCE-PROPOSAL.md` | The 2026-10-03 balance proposal. | 2026-10-03 | Partly superseded by PROPOSAL.md. |
| `docs/SKILL-TREE.md` | Elements and the skill tree. | 2026-10-04 | Roster table predates a remap. |
| `docs/ROADMAP.md` | Older launch roadmap and the redesign plan. | 2026-09-30 | Older. Superseded in places by OPEN.md. |
| `docs/FABLE-PROMPT.md` | A prompt for spending API budget on three scoped jobs. | 2026-10-05 | A tool, not a spec. |
| `docs/rojo-connect.md` | How to connect Rojo without losing Studio work. | 2026-10-01 | Still correct. See [rojo-and-studio](code/rojo-and-studio.md). |

## Docs that are stale or superseded

| doc | what it is | last change | what is wrong |
|---|---|---|---|
| `docs/decisions.md` | Design decisions from the ore remake. | 2026-10-02 | Describes a 1–1000 tool level scale, `gemSpan`, `OreShapes` and "no pity". The code has moved on. |
| `docs/live-config.md` | Config read out of the live place on 2026-09-27. | 2026-10-02 | Measured, but before the ore roster and breaking changes. Useful as history. |
| `docs/ore-remake.md` | The ore roster, with per-ore looks. | 2026-10-02 | Roster table is **121 rows; the real roster is 82**. |
| `docs/depth-sheet.md` | The rock-HP equation, generated. | 2026-10-02 | Describes the old HP formula. |
| `roadmap/*` | Direction documents (principles, economy, gating, progression). | 2026-10-02 | Direction only, **never load-bearing**. `ORE.md` is **OVERRULED** by TODO §0.1. `CHARMS.md` is entirely superseded. |

Still worth reading in `roadmap/`: `PRINCIPLES.md` (invariants that each came
from a real failure), `POSTMORTEM.md` (what has been tried and how it failed),
and `GATING.md` (which axis gates which reward). Their warnings still hold.

## Not in the repo

- **The owner's messages.** `transcripts/OWNER-MESSAGES.md` is gitignored and
  lives only on the owner's disk (`docs/START-HERE.md` §9). If it is missing,
  stop and ask. Claude.ai exports go in `tools/export/in/`, also gitignored.
- **The place file.** Workspace, Lighting, Teams, TextChatService and
  `ToolModels_50` live only in Roblox Studio (see
  [rojo-and-studio](code/rojo-and-studio.md)).
- **Roblox itself.** Almost none of the recent work has run in the engine
  (`docs/START-HERE.md` §5). Treat every "works" as *unproven* until someone
  has played it.

## See also

- [owner](owner.md)
- [open-questions](open-questions.md)
- [code-map](code/code-map.md)
