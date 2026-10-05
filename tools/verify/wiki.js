// The wiki only helps if it is telling the truth.
//
// wiki/ is the LLM-maintained map of this repo (see wiki/SCHEMA.md). A map that
// points at files which moved, or names a MineConfig field that was renamed,
// is worse than no map: the next agent trusts it and goes the wrong way.
//
// This is the mechanical half of a wiki lint. It checks:
//   * every page has the frontmatter SCHEMA.md asks for
//   * every relative link lands on a real file
//   * every page is reachable from wiki/index.md
//   * every `related:` slug is a real page
//   * every cited repo path exists (frontmatter sources and backticked paths)
//   * warn: a backticked `MineX.SYMBOL` whose module no longer mentions SYMBOL
//
// The semantic half -- contradictions, stale claims, missing pages -- is a
// Claude job, described under "Lint" in wiki/SCHEMA.md.
//
//   node tools/verify/wiki.js
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "../..");
const WIKI = path.join(ROOT, "wiki");
const rel = (p) => path.relative(ROOT, p).split(path.sep).join("/");

let fail = 0;
let warn = 0;
const check = (ok, msg) => {
  console.log((ok ? "  ok    " : "  FAIL  ") + msg);
  if (!ok) fail++;
};
const warnIf = (bad, msg) => {
  if (bad) {
    console.log("  warn  " + msg);
    warn++;
  }
};

if (!fs.existsSync(WIKI)) {
  check(false, "wiki/ exists");
  process.exit(1);
}

const walk = (dir) =>
  fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
    const p = path.join(dir, e.name);
    return e.isDirectory() ? walk(p) : e.name.endsWith(".md") ? [p] : [];
  });
const pages = walk(WIKI).sort();
check(pages.length >= 10, `wiki has ${pages.length} pages`);

const slugOf = (p) => path.basename(p, ".md");
const bySlug = new Map();
for (const p of pages) bySlug.set(slugOf(p), p);

// --- frontmatter -------------------------------------------------------------
// Deliberately tiny: `key: value` lines and `- item` lists. SCHEMA.md says to
// keep it flat so this does not need a YAML library.
const parseFront = (text) => {
  const m = text.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
  if (!m) return null;
  const out = {};
  let listKey = null;
  for (const line of m[1].split(/\r?\n/)) {
    const item = line.match(/^\s+-\s+(.*)$/);
    if (item && listKey) {
      out[listKey].push(item[1].trim());
      continue;
    }
    const kv = line.match(/^([A-Za-z_]+):\s*(.*)$/);
    if (!kv) continue;
    const [, k, v] = kv;
    const val = v.replace(/\s+#.*$/, "").trim();
    if (val === "") {
      out[k] = [];
      listKey = k;
    } else {
      out[k] = val;
      listKey = null;
    }
  }
  return { data: out, body: text.slice(m[0].length) };
};

const TYPES = ["system", "code", "meta"];
const STATUSES = ["current", "partial", "stale", "retired"];
const parsed = new Map();
const badFront = [];
for (const p of pages) {
  const f = parseFront(fs.readFileSync(p, "utf8"));
  if (!f) {
    badFront.push(`${rel(p)}: no frontmatter`);
    continue;
  }
  parsed.set(p, f);
  const d = f.data;
  const problems = [];
  if (!d.title) problems.push("title");
  if (!TYPES.includes(d.type)) problems.push(`type (${d.type || "missing"})`);
  if (!STATUSES.includes(d.status)) problems.push(`status (${d.status || "missing"})`);
  if (!/^\d{4}-\d{2}-\d{2} @ [0-9a-f]{7,}$/.test(d.verified || ""))
    problems.push(`verified (${d.verified || "missing"})`);
  if (d.type !== "meta" && !(Array.isArray(d.sources) && d.sources.length))
    problems.push("sources (a system or code page must cite at least one)");
  if (problems.length) badFront.push(`${rel(p)}: ${problems.join(", ")}`);
}
check(
  badFront.length === 0,
  "every page has valid frontmatter" + (badFront.length ? "\n        " + badFront.join("\n        ") : "")
);

// --- links -------------------------------------------------------------------
// Code spans and fenced blocks are prose about links, not links.
const stripCode = (s) => s.replace(/```[\s\S]*?```/g, "").replace(/`[^`\n]*`/g, "");
const brokenLinks = [];
const linkedFromIndex = new Set();
for (const p of pages) {
  const f = parsed.get(p);
  const body = stripCode(f ? f.body : fs.readFileSync(p, "utf8"));
  for (const m of body.matchAll(/\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g)) {
    const target = m[1];
    if (/^(https?:|mailto:|#)/.test(target)) continue;
    const file = decodeURIComponent(target.split("#")[0]);
    const abs = path.resolve(path.dirname(p), file);
    if (!fs.existsSync(abs)) brokenLinks.push(`${rel(p)} -> ${target}`);
    else if (slugOf(p) === "index") linkedFromIndex.add(abs);
  }
}
check(
  brokenLinks.length === 0,
  "every relative link resolves" + (brokenLinks.length ? "\n        " + brokenLinks.join("\n        ") : "")
);

const index = path.join(WIKI, "index.md");
const orphans = pages.filter((p) => p !== index && !linkedFromIndex.has(p)).map(rel);
check(
  orphans.length === 0,
  "every page is listed in wiki/index.md" + (orphans.length ? "\n        " + orphans.join("\n        ") : "")
);

const badRelated = [];
for (const [p, f] of parsed) {
  const r = f.data.related;
  const slugs = Array.isArray(r) ? r : (r || "").replace(/^\[|\]$/g, "").split(",");
  for (const s of slugs.map((x) => x.trim()).filter(Boolean)) {
    if (!bySlug.has(s)) badRelated.push(`${rel(p)}: related "${s}"`);
  }
}
check(
  badRelated.length === 0,
  "every related: slug is a page" + (badRelated.length ? "\n        " + badRelated.join("\n        ") : "")
);

// --- cited paths -------------------------------------------------------------
// A path cited as a source must exist. In prose, a path may be named BECAUSE it
// is gone ("MineFossils.luau was deleted"), so a line that says so is exempt.
const PATH_RE = /^(src|docs|roadmap|tools|build|wiki|\.claude|\.vscode)\/[^\s*<>{}]+$|^(AGENTS|CLAUDE)\.md$|^default\.project\.json$/;
const GONE_RE =
  /deleted|removed|retired|renamed|not in (the )?repo|not in git|not committed|gitignored|untracked|place[- ]file|studio[- ]only|does not exist|no longer|proposed|suggest|would|planned|was /i;
// Owner-disk folders: real, but never in a clone.
const OFFLINE_RE = /^(transcripts|mine-for-cards-transcripts|tools\/export\/in|\.luau-bin)(\/|$)/;

const cleanPath = (s) =>
  s
    .replace(/\s+(§|#).*$/, "")
    .replace(/\s.*$/, "")
    .replace(/[),.;:]+$/, "")
    .replace(/:\d+(-\d+)?$/, "")
    .replace(/#.*$/, "")
    .replace(/\/$/, "");

const missingSources = [];
const missingCited = [];
for (const [p, f] of parsed) {
  for (const s of Array.isArray(f.data.sources) ? f.data.sources : []) {
    const c = cleanPath(s);
    if (OFFLINE_RE.test(c) || !PATH_RE.test(c)) continue;
    if (!fs.existsSync(path.join(ROOT, c))) missingSources.push(`${rel(p)}: ${s}`);
  }
  const lines = f.body.replace(/```[\s\S]*?```/g, "").split(/\r?\n/);
  for (const line of lines) {
    for (const m of line.matchAll(/`([^`\n]+)`/g)) {
      const c = cleanPath(m[1].trim());
      if (OFFLINE_RE.test(c) || !PATH_RE.test(c)) continue;
      if (fs.existsSync(path.join(ROOT, c))) continue;
      if (GONE_RE.test(line)) continue;
      missingCited.push(`${rel(p)}: ${m[1]}`);
    }
  }
}
check(
  missingSources.length === 0,
  "every frontmatter source exists" +
    (missingSources.length ? "\n        " + missingSources.join("\n        ") : "")
);
check(
  missingCited.length === 0,
  "every backticked repo path exists (or the line says it is gone)" +
    (missingCited.length ? "\n        " + missingCited.join("\n        ") : "")
);

// --- symbol drift (warning) --------------------------------------------------
// `MineConfig.ORE_REACH` in a page is a claim that MineConfig still has it.
// Only modules that exist as files are checked; Verbs.x, Dig.x, p.x are tables
// inside MineServer and are left to the semantic lint.
const moduleFiles = new Map();
const walkSrc = (dir) => {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) {
      const init = ["init.luau", "init.server.luau", "init.client.luau"]
        .map((n) => path.join(p, n))
        .find((n) => fs.existsSync(n));
      if (init) moduleFiles.set(e.name, init);
      walkSrc(p);
    } else {
      const m = e.name.match(/^([A-Za-z_][A-Za-z0-9_]*)(\.server|\.client)?\.luau$/);
      if (m && m[1] !== "init" && !moduleFiles.has(m[1])) moduleFiles.set(m[1], p);
    }
  }
};
walkSrc(path.join(ROOT, "src"));

const srcCache = new Map();
const srcOf = (f) => {
  if (!srcCache.has(f)) srcCache.set(f, fs.readFileSync(f, "utf8"));
  return srcCache.get(f);
};
let symbolsChecked = 0;
for (const [p, f] of parsed) {
  const body = f.body.replace(/```[\s\S]*?```/g, "");
  for (const m of body.matchAll(/`([^`\n]+)`/g)) {
    for (const s of m[1].matchAll(/\b([A-Z][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)\b/g)) {
      const file = moduleFiles.get(s[1]);
      if (!file) continue;
      symbolsChecked++;
      const has = new RegExp("\\b" + s[2] + "\\b").test(srcOf(file));
      warnIf(!has, `${rel(p)}: \`${s[1]}.${s[2]}\` -- ${rel(file)} no longer mentions ${s[2]}`);
    }
  }
}
console.log(`  info  ${symbolsChecked} Module.SYMBOL references checked against src/`);

// --- log ---------------------------------------------------------------------
const logPath = path.join(WIKI, "log.md");
const log = fs.existsSync(logPath) ? fs.readFileSync(logPath, "utf8") : "";
check(
  /^## \[\d{4}-\d{2}-\d{2}\] (ingest|query|lint|refactor|setup) \| .+$/m.test(log),
  "wiki/log.md has at least one well-formed entry"
);

console.log(`\n  ${fail} failure(s), ${warn} warning(s)`);
process.exit(fail ? 1 : 0);
