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

// readNumber only matches \d+, which silently misses 3.9e8 and 1.5. Takes the
// LAST assignment, because MineConfig assigns some keys twice and the last one
// is the one the module exports.
function readFloat(src, key) {
  const g = new RegExp("MineConfig\\." + key + "\\s*=\\s*([0-9.eE+-]+)", "g");
  let v = null, m;
  while ((m = g.exec(src))) v = Number(m[1]);
  if (v === null || !isFinite(v)) throw new Error("MineConfig." + key + " not found");
  return v;
}

const src = luauSource(CONFIG);
const ores = readOres(src);
const maxLevel = readNumber(src, "TOOL_MAX_LEVEL");

// THE DAMAGE MODEL WAS NEVER SYNCED, AND THAT HID A REAL BUG.
//
// This generator kept ORES, NORE and MAXLVL in step with MineConfig and left
// the T block's damage numbers hand-written. They drifted:
//
//   dmgStep was 1.02, which is the per-level rate for a 1000-LEVEL cap. The
//   game has been at 100 for a long time, where the rate is 1.0609. So the
//   calculator showed a full climb as 1.02^99 = 7.1x while the game applied
//   350x, and tools/verify/check.js asserted on the 7.1 and passed.
//
// A harness that reads a stale copy of the formula is not testing the game, so
// the damage constants are derived here now, the same way the roster is.
const dmgBase = readFloat(src, "TOOL_DMG_BASE");
const tierSpan = readFloat(src, "TOOL_TIER_SPAN");
const climbDmg = readFloat(src, "TOOL_CLIMB_DAMAGE");
const dmgStep = Math.pow(climbDmg, 1 / Math.max(1, maxLevel - 1));

// Per-band step and the band cutoffs, so the page grades ore the way the game
// does rather than restating two tables that can disagree.
const bandBody = (src.match(/MineConfig\.TOOL_BAND_DMG\s*=\s*\{([\s\S]*?)\n\}/) || [, ""])[1];
const bandDmg = {};
for (const m of bandBody.matchAll(/(\w+)\s*=\s*([\d.]+)/g)) bandDmg[m[1]] = Number(m[2]);
const bandOrder = (src.match(/MineConfig\.ORE_BAND_ORDER\s*=\s*\{([^}]*)\}/) || [, ""])[1]
  .split(",").map((s) => s.trim().replace(/"/g, "")).filter(Boolean);
const bandCuts = [...(src.match(/MineConfig\.ORE_YIELD_BANDS\s*=\s*\{([\s\S]*?)\n\}/) || [, ""])[1]
  .matchAll(/upTo\s*=\s*(\d+)/g)].map((m) => Number(m[1]));
if (Object.keys(bandDmg).length === 0 || bandCuts.length === 0) {
  console.error("FAIL could not read TOOL_BAND_DMG / ORE_YIELD_BANDS from MineConfig");
  process.exit(1);
}

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

// The damage constants, from MineConfig rather than hand-written.
html = html.replace(/dmgBase:\s*[\d.]+\s*,\s*dmgStep:\s*[\d.]+\s*,\s*tierSpan:\s*[\d.]+\s*,/,
  "dmgBase:" + dmgBase + ", dmgStep:" + Number(dmgStep.toFixed(6)) +
  ", tierSpan:" + tierSpan + ",");

// tierPower's divisor, the same stale 120 that was live in MineConfig until
// 2026-10-05, plus the per-band step that now rides on top of it.
html = html.replace(/function tierPower\(tier\)\{[^}]*\}/,
  "function tierPower(tier){ return Math.pow(6, T.tierSpan*(tier-1)/(NORE-1))*bandDmg(tier); }");

// Inject the band tables and the lookup, once, just above tierPower.
if (!/function bandDmg/.test(html)) {
  html = html.replace(/(\s*)function tierPower\(tier\)\{/,
    "$1var BAND_DMG=" + JSON.stringify(bandDmg) + ";" +
    "$1var BAND_CUTS=" + JSON.stringify(bandCuts) + ";" +
    "$1var BAND_ORDER=" + JSON.stringify(bandOrder) + ";" +
    "$1// Per-band damage step. 1.0 up to tier 60; above it ORE_REACH buys no" +
    "$1// new access, so damage is the only thing forging up is worth." +
    "$1function bandDmg(t){" +
    "$1  for(var i=0;i<BAND_CUTS.length;i++) if(t<=BAND_CUTS[i]) return BAND_DMG[BAND_ORDER[i]]||1;" +
    "$1  return BAND_DMG[BAND_ORDER[BAND_ORDER.length-1]]||1;" +
    "$1}" +
    "$1function tierPower(tier){");
} else {
  html = html.replace(/var BAND_DMG=\{[^}]*\};/, "var BAND_DMG=" + JSON.stringify(bandDmg) + ";");
  html = html.replace(/var BAND_CUTS=\[[^\]]*\];/, "var BAND_CUTS=" + JSON.stringify(bandCuts) + ";");
  html = html.replace(/var BAND_ORDER=\[[^\]]*\];/, "var BAND_ORDER=" + JSON.stringify(bandOrder) + ";");
}

// Say where the numbers came from, on the page itself.
//
// This matched only the ORIGINAL "Proposal -- nothing committed." text, so it
// fired once and never again: the caption then froze at whatever roster and cap
// were live that day and went on claiming "level cap 100" after the cap moved to
// 30. The pattern matches its own output too now, so the caption re-stamps on
// every run.
const CAPTION = `Generated from MineConfig by tools/gen/upgrade-calculator.js &mdash; ` +
  `${ores.length} ores, level cap ${maxLevel}. Do not hand-edit the data block.`;
html = html.replace(
  /Proposal &mdash; nothing committed\.|Generated from MineConfig by tools\/gen\/upgrade-calculator\.js &mdash; \d+ ores, level cap \d+\. Do not hand-edit the data block\./,
  CAPTION);

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
