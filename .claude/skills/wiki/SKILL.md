---
name: wiki
description: Maintain and use the Mine For Cards project wiki in wiki/. Use when the owner says "wiki", "add this to the wiki", "ingest", "what does the wiki say", "update the wiki", "lint the wiki", or hands over a new doc, PR, branch, transcript folder or decision that the wiki should absorb. Also use at the start of any broad task to orient yourself.
---

# /wiki — ingest, query, lint

The wiki's rules are in `wiki/SCHEMA.md`. Read it before writing to the wiki.
This skill is the short operating procedure.

Arguments: `/wiki <mode> [target]`. Modes are `ingest`, `query`, `lint` and
`status`. With no mode, infer it from the request. If you cannot tell which one
the owner wants, **ask**; see "Ask first, always" in `CLAUDE.md`. The owner wants to be hounded with questions so nothing is ever unclear.

## ingest `<source>`

The source can be a doc path, a PR number, a branch, `transcripts/`,
`tools/export/in/`, or a decision the owner just stated in chat.

1. **Get the newest state first.** Run `git fetch origin`, then compare the
   branches. Open PRs often hold newer work than `main`.
2. Read the source in full. For transcripts and exports, read them only because
   the owner asked, and never copy them into tracked files; see `CLAUDE.md`.
3. Before writing, tell the owner the takeaways you plan to file and ask about
   anything you would otherwise be guessing. Do this even for a small source.
4. Update every page the source touches, and create pages only for recurring
   topics. Cite paths and symbols, and bump `verified:` on every page you
   re-checked against code.
5. Update `wiki/glossary.md`, `wiki/ambiguous-terms.md`,
   `wiki/open-questions.md` and `wiki/index.md` as needed.
6. Append to `wiki/log.md`:

   ```
   ## [YYYY-MM-DD] ingest | <source>
   ```

   Follow it with 1–3 lines saying what changed.
7. Run `node tools/verify/wiki.js` and fix any failures.

## query `<question>`

1. Read `wiki/index.md`, then the relevant pages, then the sources they cite.
   When the answer depends on behaviour, check the code. The wiki can be stale,
   and the code wins.
2. Answer with citations, as `path` or `Module.SYMBOL`.
3. If the answer is durable, file it into the right page and add a `query`
   entry to the log. Durable means a comparison, a derived number, a decision,
   or a gotcha.

## lint

1. Run `node tools/verify/wiki.js` and fix every `FAIL`. Treat each `warn` as a
   lead: the symbol may have been renamed or deleted.
2. Do the semantic pass described in `wiki/SCHEMA.md`, under Lint:
   - pages that contradict each other or the code
   - claims superseded by newer commits (`git log --since=<verified date> -- <sources>`)
   - concepts with no page yet
   - stale `verified:` stamps
3. Fix what you can and put the rest in `wiki/open-questions.md`. Add a `lint`
   entry to the log.

## status

Report the last five log entries (`grep "^## \[" wiki/log.md | tail -5`). Then
list the pages whose `sources` changed in git after their `verified` date.
