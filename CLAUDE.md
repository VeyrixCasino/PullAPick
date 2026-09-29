# Claude Code Project Notes

This repository is a Roblox experience source tree synced to Studio with Rojo.
Read `AGENTS.md` first; it defines the Rojo mapping, file conventions, and
Studio sync workflow.

## Working rules

- Make Roblox source changes under `src/`; keep Studio-only binary assets in
  Studio unless the task explicitly involves an exportable model.
- Before changing gameplay, inspect the owning server/client module and a nearby
  caller or test. Keep edits narrow and preserve existing APIs.
- Run the relevant checks under `tools/verify/` after Luau changes.
- Treat `docs/TODO.md` as project context, not permission to take on unrelated
  tasks.

## Claude.ai chat export

Claude.ai exports may be placed in the ignored `tools/export/in/` folder. They
are user data, not training data. Only inspect them when the user asks; extract
durable project decisions and preferences into a concise, reviewable summary
instead of repeatedly sending entire transcripts to the API. Never move raw
exports into tracked files or commit them.