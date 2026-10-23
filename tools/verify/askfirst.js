// THE OWNER'S "ASK FIRST, ALWAYS" RULE HAS TO REACH EVERY AGENT, AND STAY THERE.
//
// Owner, 2026-10-08: "from now on i want ALL agents to fucking hound me with
// questions so noithing is EVER unclear".
//
// "ALL agents" is a promise about several separate doors, and each one is a place
// the rule can quietly rot:
//
//   Claude Code        CLAUDE.md, plus a hook on every prompt, plus a hook on every
//                      subagent (subagents never see the prompt hook)
//   Cursor, Codex...   AGENTS.md
//   pasted prompts     tools/agent/house-rules.txt, docs/START-HERE.md section 1,
//                      docs/FABLE-PROMPT.md, roadmap/AGENT_PROMPT.md
//   Claude.ai          wiki/claude-ai-setup.md (preferences AND project instructions)
//   the record         docs/TODO.md section 0.35, wiki/owner.md
//
// This asserts the rule is present at each door. It does not judge the wording;
// it makes deleting the rule a red build rather than a silent regression.
//
// It also guards two ways the hooks can break without anyone noticing:
//   * a hook command that PowerShell cannot run (the owner is on Windows PowerShell,
//     where "&&" is not a separator and <angle brackets> are reserved), and
//   * a stray apostrophe, which unbalances the single-quoted echo and turns the
//     rule into a shell syntax error.
// And it fails if the OLD, softer rule ("ask 1-4 short questions", "if it is clear
// and small, just do it") reappears, because that is the text this replaced.
//
// ASKFIRST_ROOT points it at another tree, which is how the failure case is proved.
//
//   node tools/verify/askfirst.js
const fs = require("fs");
const path = require("path");

const ROOT = process.env.ASKFIRST_ROOT
  ? path.resolve(process.env.ASKFIRST_ROOT)
  : path.resolve(__dirname, "../..");

let fail = 0;
const check = (ok, msg) => {
  console.log((ok ? "  ok    " : "  FAIL  ") + msg);
  if (!ok) fail++;
};
const read = (p) => {
  try {
    return fs.readFileSync(path.join(ROOT, p), "utf8");
  } catch {
    return null;
  }
};
// Line breaks and runs of spaces inside a sentence must not defeat a match.
const flat = (s) => s.replace(/\s+/g, " ");

// "so nothing is EVER unclear" -- or the owner's own spelling, "noithing".
const RULE = /so no[i]?thing is ever unclear/i;

// path, and how many separate copies of the rule it must carry
const DOORS = [
  ["CLAUDE.md", 1],
  ["AGENTS.md", 1],
  ["tools/agent/house-rules.txt", 1],
  ["docs/START-HERE.md", 2], // the pasted prompt AND the "working with this owner" list
  ["docs/FABLE-PROMPT.md", 1],
  ["roadmap/AGENT_PROMPT.md", 1],
  ["wiki/claude-ai-setup.md", 2], // personal preferences AND project instructions
  ["wiki/owner.md", 1],
  ["docs/TODO.md", 1],
];

console.log("askfirst: the owner's ask-first rule reaches every agent");

for (const [file, want] of DOORS) {
  const text = read(file);
  if (text === null) {
    check(false, `${file} exists`);
    continue;
  }
  const hits = (flat(text).match(new RegExp(RULE.source, "gi")) || []).length;
  check(hits >= want, `${file} carries the rule`, `${hits} of ${want} needed`);
}

for (const file of ["CLAUDE.md", "AGENTS.md"]) {
  const text = read(file) || "";
  check(/^## Ask first, always\b/m.test(text), `${file} has the "Ask first, always" section`);
}

// ---- the hooks ----------------------------------------------------------
let settings = null;
try {
  settings = JSON.parse(read(".claude/settings.json"));
} catch (e) {
  check(false, ".claude/settings.json parses as JSON", String(e.message || e));
}

const commandsFor = (event) =>
  ((settings && settings.hooks && settings.hooks[event]) || [])
    .flatMap((g) => g.hooks || [])
    .filter((h) => h.type === "command")
    .map((h) => h.command || "");

for (const event of ["UserPromptSubmit", "SubagentStart"]) {
  const cmds = commandsFor(event);
  const mine = cmds.filter((c) => /ASK FIRST/.test(c));
  check(mine.length > 0, `a ${event} hook carries the rule`, `${mine.length} found`);
  for (const c of mine) {
    check(/^echo '/.test(c) && /'$/.test(c), `${event} hook is a plain single-quoted echo`);
    const quotes = (c.match(/'/g) || []).length;
    check(quotes === 2, `${event} hook has balanced quoting`, `${quotes} apostrophes, need exactly 2`);
    check(!/&&|\|\||<|>/.test(c), `${event} hook is safe for Windows PowerShell`, "no &&, ||, < or >");
  }
}

// Subagents only take context from the JSON form. A plain echo was tried and a
// general-purpose subagent saw nothing, so the shape matters and is pinned here.
const sub = commandsFor("SubagentStart").find((c) => /ASK FIRST/.test(c));
if (sub) {
  let ok = false;
  let detail = "";
  try {
    const json = JSON.parse(sub.replace(/^echo '/, "").replace(/'$/, ""));
    const h = json.hookSpecificOutput || {};
    ok = h.hookEventName === "SubagentStart" && /ASK FIRST/.test(h.additionalContext || "");
    detail = ok ? "" : "missing hookEventName or additionalContext";
  } catch (e) {
    detail = "not valid JSON: " + String(e.message || e);
  }
  check(ok, "SubagentStart hook prints hookSpecificOutput.additionalContext JSON", detail);
}

// ---- the old, softer rule must not come back ------------------------------
const STALE = [
  [/ask 1-4 short questions/i, "ask 1-4 short questions"],
  [/if it is clear and small, just do it/i, "if it is clear and small, just do it"],
  [/Ask before you assume/, "the old heading Ask before you assume"],
];
const surfaces = [
  "CLAUDE.md",
  "AGENTS.md",
  "wiki/claude-ai-setup.md",
  "wiki/owner.md",
  "wiki/README.md",
  "tools/agent/house-rules.txt",
  ".claude/settings.json",
];
for (const [re, label] of STALE) {
  const bad = surfaces.filter((f) => re.test(flat(read(f) || "")));
  check(bad.length === 0, `the old rule "${label}" is gone`, bad.length ? "still in: " + bad.join(", ") : "");
}

console.log(`\n  ${fail} failure(s)`);
process.exit(fail ? 1 : 0);
