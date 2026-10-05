// Regenerate tools/upgrade-calculator.html's DATA from MineConfig.
//
// Why this exists (2026-10-05): the calculator carried its own hand-written
// copy of the ore roster -- 121 ores and a 1000-level cap, pricing Sandstone,
// Electrum and Zircon, none of which exist any more. Live MineConfig.ORES is
// 82 (Stone -> Oganesson) and TOOL_MAX_LEVEL is 100. tools/verify/check.js
// runs the calculator's embedded tables, so the one check with "ore" and
// "gems" in its output was measuring a design that had been deleted.
//
// Two hand-maintained copies of the same table is the actual bug; regenerating
// it by hand would just reset the clock on it. So: MineConfig is the source,
// this is the generator, and the HTML is the view. Only the DATA block is
// rewritten -- the 47 KB of UI around it is untouched.
//
//   node tools/gen/upgrade-calculator.js          # rewrite
//   node tools/gen/upgrade-calculator.js --check  # fail if stale (for CI)

const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..", "..");
const CONFIG = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau");
const HTML = path.join(ROOT, "tools/upgrade-calculator.html");

// Comments are stripped first. A check regex matching its own explanatory
// comment has burned this repo at least four times.
function luauSource(file) {
  return fs.readFileSync(file, "utf8")
    .replace(/--\[\[[\s\S]*?\]\]/g, "")
    .replace(/^[ \t]*--.*$/gm, "");
}

function readOres(src) {
  const at = src.search(/MineConfig\.ORES\s*=\s*\{/);
  if (at < 0) throw new Error("MineConfig.ORES not found");
  let i = src.indexOf("{", at) + 1, depth = 1, body = "";
  while (i < src.length && depth > 0) {
    const c = src[i];
    if (c === "{") depth++;
    else if (c === "}") depth--;
    if (depth > 0) body += c;
    i++;
  }
  const rows = [...body.matchAll(/\{[^{}]*?name\s*=\s*"([^"]+)"[^{}]*?tier\s*=\s*(\d+)[^{}]*?\}/g)]
    .map((m) => ({ name: m[1], tier: Number(m[2]) }));
  rows.sort((a, b) => a.tier - b.tier);
  return rows;
}

function readNumber(src, key) {
  const m = src.match(new RegExp("MineConfig\\." + key + "\\s*=\\s*(\\d+)"));
  if (!m) throw new Error("MineConfig." + key + " not found");
  return Number(m[1]);
}

const src = luauSource(CONFIG);
const ores = readOres(src);
const maxLevel = readNumber(src, "TOOL_MAX_LEVEL");

if (ores.length === 0) {
  console.error("FAIL read 0 ores from MineConfig -- refusing to write an empty roster");
  process.exit(1);
}
// Tiers must be 1..n with no gaps, or ORES[t-1] indexing in the calculator and
// in check.js silently reads the wrong ore.
for (let i = 0; i < ores.length; i++) {
  if (ores[i].tier !== i + 1) {
    console.error(`FAIL tier ${i + 1} is "${ores[i].name}" with tier=${ores[i].tier}` +
      " -- the roster must be a contiguous 1..n for ORES[t-1] to mean anything");
    process.exit(1);
  }
}

let html = fs.readFileSync(HTML, "utf8");
const before = html;

const oreLine = 'ORES="' + ores.map((o) => o.name).join(",") + '".split(",");';
html = html.replace(/ORES="[\s\S]*?"\.split\(","\);/, oreLine);
html = html.replace(/NORE=\d+/, "NORE=" + ores.length);
html = html.replace(/MAXLVL=\d+/, "MAXLVL=" + maxLevel);

// oreD(t) divided by a hardcoded 120, which was NORE-1 back when the roster
// was 121. With 82 ores that divisor silently rescales every ore's difficulty,
// which is what made the page disagree with the live game at bigbang/5000.
// Expressed structurally so it follows the roster from here on.
html = html.replace(/\(t-1\)\*DMAX\/\d+/, "(t-1)*DMAX/(NORE-1)");

// Say where the numbers came from, on the page itself.
html = html.replace(/Proposal &mdash; nothing committed\./,
  `Generated from MineConfig by tools/gen/upgrade-calculator.js &mdash; ` +
  `${ores.length} ores, level cap ${maxLevel}. Do not hand-edit the data block.`);

const stale = html !== before;

if (process.argv.includes("--check")) {
  if (stale) {
    console.error(`FAIL upgrade-calculator.html is stale -- MineConfig has ${ores.length} ores` +
      ` and TOOL_MAX_LEVEL ${maxLevel}. Run: node tools/gen/upgrade-calculator.js`);
    process.exit(1);
  }
  console.log(`ok  upgrade-calculator.html matches MineConfig: ${ores.length} ores, cap ${maxLevel}`);
  process.exit(0);
}

fs.writeFileSync(HTML, html);
console.log(`wrote ${path.relative(ROOT, HTML)}`);
console.log(`  ores      ${ores.length}  (${ores[0].name} 1 -> ${ores[ores.length - 1].name} ${ores.length})`);
console.log(`  level cap ${maxLevel}`);
console.log(stale ? "  data block updated" : "  already current");
