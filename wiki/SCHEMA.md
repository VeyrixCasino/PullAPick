---
title: Wiki schema
type: meta
status: current
verified: 2026-10-05 @ 26036a0
sources:
  - CLAUDE.md
related: [index, log]
---

# Wiki schema — how this wiki works and how to keep it

This is an **LLM-maintained wiki** for Mine For Cards (the repo is called
PullAPick). Claude writes and maintains it. The owner reads it, points Claude at
new sources and asks questions. The rules below keep it accurate.

## The three layers

| layer | what | who edits |
|---|---|---|
| **Raw sources** | the code in `src/`, `docs/`, `roadmap/`, git history, GitHub PRs, and the owner's own words: `transcripts/` and `tools/export/in/`. Both folders are gitignored and exist only on the owner's disk. | Claude edits code and docs only when asked. Transcripts and exports are read-only. |
| **The wiki** (`wiki/`) | short, linked pages, one topic each. Each page says what is true now and where in the source it comes from. | Claude edits it on every ingest, query or lint, and whenever a change makes a page wrong. |
| **The schema** | this file, plus the wiki section of `CLAUDE.md` | Changed only together with the owner. |

The wiki is a **map and a memory**, not a second copy of the docs. It summarises
each source and links to it. It never replaces a source.

## Which source wins

When sources disagree, the higher one on this list wins. Record the disagreement
in [open-questions](open-questions.md), or on the page itself.

1. **The owner's own words**: in chat, in `transcripts/OWNER-MESSAGES.md`, or in
   a Claude.ai export.
2. **Locked decisions:** `docs/TODO.md` §0 ("LOCKED RULES") and the approved
   block in `docs/PROPOSAL.md` §0.
3. **The code** on the newest working branch. Check open PRs, not only `main`.
4. **Current docs:** `docs/START-HERE.md`, `docs/HANDOFF.md`, `docs/OPEN.md`,
   `docs/BLOCKED.md` and the rest of `docs/`.
5. **`roadmap/`**, which gives direction only. `roadmap/ORE.md` is overruled by
   TODO §0.
6. **This wiki.** It summarises everything above, so it never outranks a source.
   If a page disagrees with a source, fix the page.

## Page types and layout

```
wiki/
  README.md          human front door
  SCHEMA.md          this file
  index.md           catalog: every page, one line each
  log.md             append-only history of ingests, queries, lints
  overview.md        the game in one page
  owner.md           how the owner works and what they have decided
  sources-of-truth.md  every doc in the repo: what it is, how current it is
  glossary.md        every term, one line each
  ambiguous-terms.md words that mean more than one thing, so Claude must ask which
  open-questions.md  undecided items and contradictions
  claude-ai-setup.md paste-in instructions for Claude.ai Projects
  systems/*.md       one page per game system
  code/*.md          one page per codebase or workflow topic
```

File names are `kebab-case.md`. Link between pages with relative markdown links,
for example `[ores](../systems/ores.md)`, so the links work on GitHub, in
Obsidian and in a plain editor.

## Frontmatter, on every page

```yaml
---
title: Ores
type: system            # system | code | meta
status: current         # current | partial | stale | retired
verified: 2026-10-05 @ 26036a0   # date and commit the claims were checked against
sources:                # repo-relative paths, optionally with a § or symbol
  - src/ReplicatedStorage/Mine/Shared/MineConfig.luau
  - docs/TODO.md §0
related: [ore-pouch, tools]     # page slugs, no .md
---
```

`node tools/verify/wiki.js` parses this format, so keep it flat: `key: value`,
plus `- item` lists under `sources`.

## Body template for a system page

```markdown
# <Title>

> Two or three sentences saying what this is from the player's side, and why it exists.

## How it works
Short, concrete, present tense. Numbers only if they come from code or a locked decision.

## Where it lives
| file | role | key symbols |

## Decided by the owner
Locked rules that govern this system, cited to TODO §0, PROPOSAL §0, or the owner's words.

## State right now
Shipped, partial, proposed, blocked, or retired. Name the branch or PR if it matters.

## Gotchas
What has already gone wrong here, and the trap to avoid.

## Open questions
Anything undecided. Link to open-questions.md or docs/BLOCKED.md.

## See also
```

Code pages use the same frontmatter and pick whichever sections fit.

## Writing rules

- **Cite or don't claim.** Every factual claim names its source: a backticked
  repo path, a `Module.SYMBOL`, or a doc section. Prefer symbols to line numbers,
  because lines drift. Studio and Cursor edit the same files at the same time.
- **Label anything you did not check.** Write *(per docs/X, not checked in code)*
  or *(unverified)*. Never smooth over a gap.
- **Summarise, don't paste.** Keep pages under about 150 lines. Link to the long
  doc instead of copying it.
- **Use the status words exactly:** *decided* (the owner said so), *shipped*
  (it is in the code), *proposed*, *blocked*, *retired*.
- **The owner's words.** Quote one or two lines at most, with the date. Never
  copy raw transcripts or exports into tracked files; see `CLAUDE.md`.
- **No secrets, tokens, personal paths or account names** beyond what the
  repo's own docs already state.

## Workflows

### Ingest: a new source arrives
The source can be a doc, a PR, a merged branch, a transcript folder or an
owner message.
1. Read it in full. If it is big or ambiguous, tell the owner the 3–5 takeaways
   you plan to file and ask whether anything is wrong. Use the clarify rules in
   `CLAUDE.md`.
2. Update every page it touches. One source often touches many pages. Create a
   page only for a topic that will come up again.
3. Bump `verified` on every page you re-checked against code.
4. Add new terms to [glossary](glossary.md). If a word now has two meanings, add
   it to [ambiguous-terms](ambiguous-terms.md).
5. Update [index](index.md), then append to [log](log.md).

### Query: the owner asks something
1. Read [index](index.md), then the relevant pages, then the sources they cite.
   Check the code whenever the answer depends on behaviour.
2. Answer with citations.
3. If the answer is durable, such as a comparison, a derived number or a
   decision, file it in the right page and log it. Good answers should compound,
   not vanish into chat history.

### Lint: health check
1. Run `node tools/verify/wiki.js`. It checks frontmatter, broken links, pages
   missing from the index, cited paths that no longer exist, and `Module.SYMBOL`
   references whose symbol has disappeared.
2. Then do the semantic pass that a script cannot do:
   - pages contradicting each other or the code
   - claims superseded by newer commits
   - concepts mentioned often but with no page
   - stale `verified` stamps on systems that changed since
3. Fix what you can and log the rest to [open-questions](open-questions.md).

### Keeping it true while coding
When a code change makes a wiki statement false, fix the page **in the same
commit**. This is the wiki version of the repo's standing rule: kill stale
comments on sight.

## Log format

Each entry starts with a greppable header:

```
## [2026-10-05] ingest | docs/OPEN.md
One to three lines: what changed, which pages were touched.
```

Kinds: `ingest`, `query`, `lint`, `refactor`, `setup`.
`grep "^## \[" wiki/log.md | tail -5` shows the latest activity.
