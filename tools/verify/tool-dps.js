// TODO B2 — DPS table for forged tool families.
//
// docs/TODO.md B2 + owner 2026-10-14:
//   - hammer (B1 LOCKED): slow / heavy / single-target, hardest hit, and the
//     highest *single-block* DPS of every family
//   - drills and explosives get area (3×3 and up)
//   - same-grade explosive *area* edps tops the chart (full blast footprint);
//     higher-grade tools may beat a low explosive
//   - pickaxe faster than hammer; jackhammer single-cell dps ≈ drill
//
// Metrics (pre-cap, no falloff, no boosts, level 1):
//   hit     = toolPower(tier,1,typeMult) × FAMILY_POWER
//   aps     = rate  (melee/drill/jackhammer)  or  1/cooldown  (explosive)
//   dps     = hit × aps                         (single-cell / single-block)
//   edps    = hit × affectedBlocks × aps        (full footprint throughput)
//             explosives: blocksPerBomb × bombs
//               line/linesplash → max(cells, depth) when depth is baked
//               else cells (sphere/cluster/splash quote)
//             other families: cells (hammer sink-2 is already in cells)
//
// Pure JS (no luau). suite.sh picks this up; on Windows:
//   node tools/verify/tool-dps.js
//
const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..", "..");
const CFG = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau");
const ORE = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineOreTools.luau");

const cfg = fs.readFileSync(CFG, "utf8");
const ore = fs.readFileSync(ORE, "utf8");

let fails = 0;
let checks = 0;
function ok(cond, msg) {
  checks++;
  if (!cond) {
    fails++;
    console.log("  FAIL  " + msg);
  } else {
    console.log("  ok    " + msg);
  }
}
function softFail(cond, msg) {
  // Same as ok — "soft" means documenting intent, not that failures are ignored.
  ok(cond, msg);
}

function num(src, key) {
  const m = new RegExp("MineConfig\\." + key + "\\s*=\\s*([0-9.eE+-]+)", "g");
  let v = null, hit;
  while ((hit = m.exec(src))) v = Number(hit[1]);
  if (v === null) throw new Error("could not read MineConfig." + key);
  return v;
}

function braceBlock(src, head) {
  const i = src.indexOf(head);
  if (i < 0) throw new Error("not found: " + head);
  const start = src.indexOf("{", i);
  let depth = 0;
  for (let j = start; j < src.length; j++) {
    const c = src[j];
    if (c === "{") depth++;
    else if (c === "}") {
      depth--;
      if (depth === 0) return src.slice(start, j + 1);
    }
  }
  throw new Error("unterminated: " + head);
}

// Strip Luau block and line comments so nested --[[ ]] inside FAMILY_POWER
// does not break field reads.
function stripComments(s) {
  return s
    .replace(/--\[\[[\s\S]*?\]\]/g, "")
    .replace(/--[^\n]*/g, "");
}

function parseRleList(body) {
  // {upTo, value} pairs. value is number, string, true/false.
  const out = [];
  const re = /\{\s*([0-9.]+)\s*,\s*([0-9.]+|"[^"]*"|true|false)\s*\}/g;
  let m;
  while ((m = re.exec(body))) {
    let v = m[2];
    if (v === "true") v = true;
    else if (v === "false") v = false;
    else if (v[0] === '"') v = v.slice(1, -1);
    else v = Number(v);
    out.push({ upTo: Number(m[1]), value: v });
  }
  return out;
}

function rleAt(steps, tier) {
  for (const p of steps) {
    if (tier <= p.upTo) {
      if (p.value === false) return null;
      return p.value;
    }
  }
  return null;
}

function parseTypeMultSteps(clean) {
  const block = braceBlock(clean, "MineOreTools.TYPE_MULT_STEPS = {");
  const fams = {};
  const re = /(\w+)\s*=\s*\{([^}]*)\}/g;
  let m;
  while ((m = re.exec(block))) {
    fams[m[1]] = m[2].split(",").map((s) => Number(s.trim())).filter((n) => !Number.isNaN(n));
  }
  return fams;
}

function parseFamilyPower(clean) {
  const block = braceBlock(clean, "MineOreTools.FAMILY_POWER = {");
  const fams = {};
  // jackhammer = 1 / 1.5  or  pickaxe = 1
  const re = /(\w+)\s*=\s*([0-9.]+(?:\s*\/\s*[0-9.]+)?)/g;
  let m;
  while ((m = re.exec(block))) {
    const parts = m[2].split("/").map((s) => Number(s.trim()));
    fams[m[1]] = parts.length === 2 ? parts[0] / parts[1] : parts[0];
  }
  return fams;
}

function parseFrameStats(clean) {
  const block = braceBlock(clean, "MineOreTools.FRAME_STATS = {");
  // Split top-level family keys by scanning braces.
  const fams = {};
  let i = 1; // skip opening {
  while (i < block.length) {
    while (i < block.length && /[\s,]/.test(block[i])) i++;
    if (i >= block.length - 1) break;
    const keyM = block.slice(i).match(/^(\w+)\s*=\s*\{/);
    if (!keyM) break;
    const fam = keyM[1];
    i += keyM[0].length - 1; // on {
    const start = i;
    let depth = 0;
    for (; i < block.length; i++) {
      if (block[i] === "{") depth++;
      else if (block[i] === "}") {
        depth--;
        if (depth === 0) {
          i++;
          break;
        }
      }
    }
    const body = block.slice(start, i);
    const stats = {};
    // Each stat key = { ... RLE ... }
    let j = 1;
    while (j < body.length) {
      while (j < body.length && /[\s,]/.test(body[j])) j++;
      const sm = body.slice(j).match(/^(\w+)\s*=\s*\{/);
      if (!sm) break;
      const sk = sm[1];
      j += sm[0].length - 1;
      const s0 = j;
      let d = 0;
      for (; j < body.length; j++) {
        if (body[j] === "{") d++;
        else if (body[j] === "}") {
          d--;
          if (d === 0) {
            j++;
            break;
          }
        }
      }
      stats[sk] = parseRleList(body.slice(s0, j));
    }
    fams[fam] = stats;
  }
  return fams;
}

function parseFamilyOrder(clean) {
  const m = clean.match(/MineOreTools\.FAMILY_ORDER\s*=\s*\{([^}]+)\}/);
  if (!m) return [];
  return [...m[1].matchAll(/"(\w+)"/g)].map((x) => x[1]);
}

// --- MineConfig damage curve (same shape as damage-curve.js) ----------------
const ORE_COUNT = (() => {
  const m = cfg.match(/MineConfig\.ORE_COUNT\s*=\s*(\d+)/);
  if (m) return Number(m[1]);
  return 82;
})();
const SPAN = num(cfg, "TOOL_TIER_SPAN");
const BASE = num(cfg, "TOOL_DMG_BASE");
const MAXLVL = num(cfg, "TOOL_MAX_LEVEL");
const CLIMB = num(cfg, "TOOL_CLIMB_DAMAGE");
const STEP = Math.pow(CLIMB, 1 / (MAXLVL - 1));

const bandBlock = cfg.match(/MineConfig\.TOOL_BAND_DMG\s*=\s*\{([\s\S]*?)\n\}/);
if (!bandBlock) throw new Error("TOOL_BAND_DMG missing");
const BAND_MULT = {};
for (const m of bandBlock[1].matchAll(/(\w+)\s*=\s*([\d.]+)/g)) {
  BAND_MULT[m[1]] = Number(m[2]);
}
const yb = cfg.match(/MineConfig\.ORE_YIELD_BANDS\s*=\s*\{([\s\S]*?)\n\}/);
const CUTS = [...yb[1].matchAll(/upTo\s*=\s*(\d+)/g)].map((m) => Number(m[1]));
const ORDER = cfg.match(/MineConfig\.ORE_BAND_ORDER\s*=\s*\{([^}]*)\}/)[1]
  .split(",").map((s) => s.trim().replace(/"/g, "")).filter(Boolean);
function bandOf(t) {
  for (let i = 0; i < CUTS.length; i++) if (t <= CUTS[i]) return ORDER[i];
  return ORDER[ORDER.length - 1];
}
function toolTierPower(t) {
  const smooth = Math.pow(6, SPAN * (t - 1) / (ORE_COUNT - 1));
  return smooth * (BAND_MULT[bandOf(t)] || 1);
}
function toolPower(tier, level, typeMult) {
  return BASE * toolTierPower(tier) * Math.max(0.01, typeMult) * Math.pow(STEP, level - 1);
}

const cleanOre = stripComments(ore);
const FAMILY_ORDER = parseFamilyOrder(cleanOre);
const FAMILY_POWER = parseFamilyPower(cleanOre);
const TYPE_MULT_STEPS = parseTypeMultSteps(cleanOre);
const FRAME_STATS = parseFrameStats(cleanOre);

function typeMult(familyId, oreTier) {
  const steps = TYPE_MULT_STEPS[familyId] || TYPE_MULT_STEPS.pickaxe;
  for (let i = 0; i < steps.length; i++) {
    if (oreTier <= steps[i]) return i + 1;
  }
  return steps.length;
}

function frameStats(familyId, oreTier) {
  const fam = FRAME_STATS[familyId] || FRAME_STATS.pickaxe;
  const out = {};
  for (const key of Object.keys(fam)) {
    out[key] = rleAt(fam[key], oreTier);
  }
  return out;
}

/** Full blast / swing footprint in blocks (owner 2026-10-14). */
function affectedBlocks(familyId, stats) {
  const cells = Math.max(1, Number(stats.cells) || 1);
  const bombs = Math.max(1, Number(stats.bombs) || 1);
  const isExpl = familyId === "explosive" ||
    (stats.cooldown != null && stats.cooldown !== false);
  if (!isExpl) {
    return { cells, bombs: 1, perBomb: cells, spread: cells };
  }
  let perBomb = cells;
  const pat = stats.pattern;
  if (pat === "line" || pat === "linesplash") {
    const d = Number(stats.depth);
    if (Number.isFinite(d) && d > 0) perBomb = Math.max(cells, d);
  }
  return { cells, bombs, perBomb, spread: perBomb * bombs };
}

function profile(familyId, tier, level) {
  const stats = frameStats(familyId, tier);
  const tm = typeMult(familyId, tier);
  const famPow = FAMILY_POWER[familyId] ?? 1;
  const hit = toolPower(tier, level, tm) * famPow;
  const isExpl = familyId === "explosive" ||
    (stats.cooldown != null && stats.cooldown !== false);
  let aps;
  if (isExpl) {
    const cd = Math.max(0.05, Number(stats.cooldown) || 2);
    aps = 1 / cd;
  } else {
    aps = Math.max(0.05, Number(stats.rate) || 2.6);
  }
  const foot = affectedBlocks(familyId, stats);
  const dps = hit * aps;
  const edps = hit * foot.spread * aps;
  return {
    familyId, tier, level, hit, aps,
    cells: foot.cells, bombs: foot.bombs, perBomb: foot.perBomb, spread: foot.spread,
    dps, edps,
    rate: stats.rate, cooldown: stats.cooldown, depth: stats.depth,
    pattern: stats.pattern, radius: stats.radius,
    width: stats.width, shape: stats.shape, sink: stats.sink,
    typeMult: tm, famPow,
  };
}

// Representative forged ores: early, mid (area drills kick in ~31–57), line
// explosives (~42–46, 58–63), and the top rung.
const SAMPLE_TIERS = [1, 20, 41, 46, 57, 63, 82];
const FAMILIES = ["pickaxe", "hammer", "drill", "jackhammer", "explosive"];
const LEVEL = 1;

console.log("tool-dps: forged family DPS table (TODO B2, level " + LEVEL + ")");
console.log("  ORE_COUNT=" + ORE_COUNT + "  TOOL_TIER_SPAN=" + SPAN +
  "  STEP=+" + ((STEP - 1) * 100).toFixed(2) + "%/lvl");
console.log("  families: " + FAMILY_ORDER.join(", "));
console.log("");

// Sanity: parsers found what we need.
ok(FAMILY_ORDER.length >= 5, "FAMILY_ORDER has five forgeable families (got " +
  FAMILY_ORDER.length + ": " + FAMILY_ORDER.join(",") + ")");
for (const f of FAMILIES) {
  ok(!!FRAME_STATS[f], "FRAME_STATS." + f + " exists");
  ok(FAMILY_POWER[f] != null, "FAMILY_POWER." + f + " = " + FAMILY_POWER[f]);
  ok(!!TYPE_MULT_STEPS[f], "TYPE_MULT_STEPS." + f + " exists");
}

// Print the table.
const rows = [];
for (const t of SAMPLE_TIERS) {
  for (const f of FAMILIES) rows.push(profile(f, t, LEVEL));
}

function fmt(n) {
  if (!Number.isFinite(n)) return "?";
  if (n >= 1e6) return n.toExponential(3);
  if (n >= 1000) return n.toFixed(0);
  if (n >= 10) return n.toFixed(1);
  return n.toFixed(2);
}

console.log("  tier  family       hit        aps  perBomb×bombs  dps        edps     notes");
for (const r of rows) {
  const note = r.familyId === "explosive"
    ? (r.pattern || "?") + " r" + (r.radius ?? "?") +
      (r.depth != null ? (" d" + r.depth) : "") +
      " cd" + fmt(r.cooldown)
    : (r.shape || "") + (r.width ? (" w" + r.width) : "") +
      (r.sink ? (" sink" + r.sink) : "");
  console.log(
    "  " + String(r.tier).padStart(3) + "  " +
    r.familyId.padEnd(11) +
    fmt(r.hit).padStart(10) +
    fmt(r.aps).padStart(9) +
    (r.perBomb + "×" + r.bombs).padStart(12) +
    fmt(r.dps).padStart(10) +
    fmt(r.edps).padStart(11) +
    "  " + note
  );
}
console.log("");

// --- Assertions from TODO B2 + owner 2026-10-14 -----------------------------

// 1) pickaxe faster than hammer; hammer hardest per blow.
for (const t of SAMPLE_TIERS) {
  const p = profile("pickaxe", t, LEVEL);
  const h = profile("hammer", t, LEVEL);
  softFail(p.aps > h.aps,
    "tier " + t + ": pickaxe is faster than hammer (" +
    fmt(p.aps) + "/s vs " + fmt(h.aps) + "/s)");
  softFail(h.hit > p.hit,
    "tier " + t + ": hammer hits harder per blow than pickaxe (" +
    fmt(h.hit) + " vs " + fmt(p.hit) + ")");
}

// 1b) B1 LOCKED: hammer single-block dps crowns every other family.
for (const t of SAMPLE_TIERS) {
  const h = profile("hammer", t, LEVEL);
  for (const f of FAMILIES) {
    if (f === "hammer") continue;
    const o = profile(f, t, LEVEL);
    softFail(h.dps >= o.dps,
      "tier " + t + ": hammer single-block dps >= " + f +
      " (" + fmt(h.dps) + " vs " + fmt(o.dps) + ")");
  }
}

// 2) drills and explosives get area (3×3 and up).
const drillAreaTiers = [];
for (let t = 1; t <= ORE_COUNT; t++) {
  const s = frameStats("drill", t);
  if ((s.cells || 0) >= 9) drillAreaTiers.push(t);
}
softFail(drillAreaTiers.length > 0,
  "some drill frames clear 3×3+ (cells>=9); found " + drillAreaTiers.length +
  " tiers" + (drillAreaTiers.length ? " (e.g. " + drillAreaTiers[0] + ")" : ""));
let explAreaOk = true;
const explThin = [];
for (let t = 1; t <= ORE_COUNT; t++) {
  const s = frameStats("explosive", t);
  if ((s.cells || 0) < 7) {
    explAreaOk = false;
    explThin.push(t);
  }
}
softFail(explAreaOk,
  "every explosive frame quotes area (cells>=7); thin tiers: " +
  (explThin.slice(0, 8).join(",") || "none"));

// Jackhammer mirrors drill footprint (area when drill has area).
if (drillAreaTiers.length) {
  const t = drillAreaTiers[0];
  const j = frameStats("jackhammer", t);
  softFail((j.cells || 0) >= 9,
    "jackhammer shares drill area at tier " + t + " (cells=" + j.cells + ")");
}

// 3) long-range / same-grade explosives top area edps.
const lineTiers = [];
for (let t = 1; t <= ORE_COUNT; t++) {
  if (frameStats("explosive", t).pattern === "line") lineTiers.push(t);
}
ok(lineTiers.length > 0,
  "line-pattern (long) explosives exist (" + lineTiers.length + " tiers)");

// Line frames must bake depth so MinePatterns coverage matches the cells quote.
{
  let depthOk = true;
  const bad = [];
  for (const t of lineTiers) {
    const s = frameStats("explosive", t);
    const d = Number(s.depth);
    const c = Number(s.cells);
    if (!(Number.isFinite(d) && d >= 1) || !(Number.isFinite(c) && c >= 1) || d < c) {
      depthOk = false;
      bad.push(t + "(d=" + s.depth + ",c=" + s.cells + ")");
    }
  }
  softFail(depthOk,
    "line explosives bake depth >= cells (MinePatterns); bad: " +
    (bad.slice(0, 8).join(",") || "none"));
}

function topsChart(tier, label) {
  const byFam = {};
  for (const f of FAMILIES) byFam[f] = profile(f, tier, LEVEL);
  const expl = byFam.explosive;
  const others = FAMILIES.filter((f) => f !== "explosive");
  const bestOther = others.reduce((a, f) =>
    byFam[f].edps > a.edps ? byFam[f] : a, byFam[others[0]]);
  softFail(expl.edps >= bestOther.edps,
    label + " tier " + tier + ": explosive edps tops same-grade chart (" +
    fmt(expl.edps) + " vs best other " + bestOther.familyId + " " +
    fmt(bestOther.edps) + ")");
  return { expl, bestOther, byFam };
}

for (const t of SAMPLE_TIERS) {
  topsChart(t, "same-grade");
}
// Long-range line frames not already covered by SAMPLE_TIERS.
{
  const extra = [lineTiers[0], lineTiers[lineTiers.length - 1]]
    .filter((t, i, a) => t != null && a.indexOf(t) === i && !SAMPLE_TIERS.includes(t));
  for (const t of extra) topsChart(t, "long-range line");
}

// Higher-grade may beat a lower-grade explosive (the "short of higher-grade" clause).
{
  const lowExpl = profile("explosive", 1, LEVEL);
  const highPick = profile("pickaxe", ORE_COUNT, LEVEL);
  const highDrill = profile("drill", ORE_COUNT, LEVEL);
  const highBest = highPick.edps >= highDrill.edps ? highPick : highDrill;
  softFail(highBest.edps > lowExpl.edps,
    "higher-grade tool may beat a low explosive: " + highBest.familyId +
    " t" + ORE_COUNT + " edps " + fmt(highBest.edps) + " > explosive t1 " +
    fmt(lowExpl.edps));
}

// Top explosive should still beat same-grade top of every other family.
{
  const top = topsChart(ORE_COUNT, "top-rung");
  softFail(top.expl.edps >= top.bestOther.edps,
    "tier " + ORE_COUNT + " explosive remains top edps vs " + top.bestOther.familyId);
}

// 4) Jackhammer vs drill: same single-cell DPS (FAMILY_POWER cancels rate×1.5).
for (const t of SAMPLE_TIERS) {
  const d = profile("drill", t, LEVEL);
  const j = profile("jackhammer", t, LEVEL);
  const ratio = j.dps / d.dps;
  softFail(ratio > 0.98 && ratio < 1.02,
    "tier " + t + ": jackhammer dps ≈ drill dps (ratio " + ratio.toFixed(3) + ")");
}

console.log("");
console.log(fails === 0
  ? ">>> tool-dps OK (" + checks + " checks)"
  : ">>> tool-dps FAILED " + fails + "/" + checks +
    " — gaps vs TODO B2 / B1 hammer niche ordering");
process.exit(fails === 0 ? 0 : 1);
