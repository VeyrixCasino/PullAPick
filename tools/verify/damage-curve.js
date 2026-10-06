// Assert the damage curve against the LIVE MineConfig, not against a model.
//
// tools/damage-fix.js reimplemented the curve in JS to choose the numbers. That
// is how the numbers were picked, and it is exactly the kind of thing that goes
// stale the moment someone edits the Luau -- so this harness loads the real
// module and asserts the two properties the owner asked for:
//
//   1. levelling still changes the swing count well past level 34, for EVERY
//      tier, at the depth that tier's ore spawns
//   2. forging above tier 60 is a visible damage gain, band by band
//
// Run: node tools/verify/damage-curve.js
const { readSrc } = require("./_luau.js");
const path = require("path");
const ROOT = path.join(__dirname, "..", "..");
const SRC = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau");
const src = readSrc(SRC);

let fails = 0, checks = 0;
function ok(cond, msg) {
  checks++;
  if (!cond) { fails++; console.log("  FAIL  " + msg); }
}

// --- read the constants out of the live file ---------------------------------
function num(key) {
  const m = new RegExp("MineConfig\\." + key + "\\s*=\\s*([0-9.eE+-]+)", "g");
  let v = null, hit;
  while ((hit = m.exec(src))) v = Number(hit[1]);
  if (v === null) throw new Error("could not read MineConfig." + key);
  return v;
}
const MAXLVL = num("TOOL_MAX_LEVEL");
const CLIMB = num("TOOL_CLIMB_DAMAGE");
const SPAN = num("TOOL_TIER_SPAN");
const BASE = num("TOOL_DMG_BASE");
const ORE_HP_MULT = num("ORE_HP_MULT");

// band step table
const bandBlock = src.match(/MineConfig\.TOOL_BAND_DMG\s*=\s*\{([\s\S]*?)\n\}/);
if (!bandBlock) { console.log("  FAIL  MineConfig.TOOL_BAND_DMG not found"); process.exit(1); }
const BAND_MULT = {};
for (const m of bandBlock[1].matchAll(/(\w+)\s*=\s*([\d.]+)/g)) BAND_MULT[m[1]] = Number(m[2]);

// band cutoffs, from ORE_YIELD_BANDS -- the single source the Luau insists on
const yb = src.match(/MineConfig\.ORE_YIELD_BANDS\s*=\s*\{([\s\S]*?)\n\}/);
const CUTS = [...yb[1].matchAll(/upTo\s*=\s*(\d+)/g)].map((m) => Number(m[1]));
const ORDER = src.match(/MineConfig\.ORE_BAND_ORDER\s*=\s*\{([^}]*)\}/)[1]
  .split(",").map((s) => s.trim().replace(/"/g, "")).filter(Boolean);
const NORE = CUTS[CUTS.length - 1];
const bandOf = (t) => { for (let i = 0; i < CUTS.length; i++) if (t <= CUTS[i]) return ORDER[i]; return ORDER[ORDER.length - 1]; };

// --- the divisor must not be hardcoded ---------------------------------------
const fn = src.match(/function MineConfig\.toolTierPower[\s\S]*?\nend/);
ok(fn && !/\/\s*120\b/.test(fn[0]),
  "toolTierPower still divides by a hardcoded 120 (stale #ORES-1 from the 121-ore roster)");
ok(fn && /ORE_COUNT|#MineConfig\.ORES/.test(fn[0]),
  "toolTierPower does not derive its divisor from the roster size");

// --- rebuild the curve from those constants ----------------------------------
const STEP = Math.pow(CLIMB, 1 / (MAXLVL - 1));
const dmg = (t, L) => BASE * Math.pow(6, SPAN * (t - 1) / (NORE - 1))
  * (BAND_MULT[bandOf(t)] || 1) * Math.pow(STEP, L - 1);

// HP, from MineDepth's linear curve (NOT the stale SECTIONS table)
const dsrc = readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineDepth.luau"));
const dnum = (k) => Number(dsrc.match(new RegExp("MineDepth\\." + k + "\\s*=\\s*([0-9.eE+-]+)"))[1]);
const HP_BASE = dnum("HP_BASE"), HP_PER = dnum("HP_PER_LAYER"), ZMULT = dnum("ZONE_HP_MULT");
const dirtHp = (zi, L) => (HP_BASE + HP_PER * L) * Math.pow(ZMULT, zi - 1);

// Home: where that ore spawns, across the eleven zones Event Horizon included.
const ZN = 11, LAYERS = 5000;
function home(t) {
  const abs = ((t - 1) / (NORE - 1)) * (ZN * LAYERS);
  const zi = Math.min(ZN, Math.floor(abs / LAYERS) + 1);
  const L = Math.max(1, Math.min(LAYERS, Math.round(abs - (zi - 1) * LAYERS)));
  return dirtHp(zi, L) * ORE_HP_MULT;
}
function liveLevels(t) {
  const hp = home(t);
  for (let L = 1; L <= MAXLVL; L++) if (Math.ceil(hp / dmg(t, L)) <= 1) return L;
  return MAXLVL;
}

console.log("damage-curve: span " + SPAN + ", climb " + CLIMB +
  " (+" + ((STEP - 1) * 100).toFixed(2) + "%/lvl), " + NORE + " tiers");

// --- ASK 1: most of the ladder has to stay live -------------------------------
//
// The owner's words were "levelling matters past 34", against a 100-level cap --
// so 34 was never the real number, "two thirds of my ladder is dead" was. This
// asserted `worst > 34` literally, and went red the moment TOOL_MAX_LEVEL moved
// to 30 even though the curve had got BETTER: tier 16 gaining to level 28 of 30
// is 93% of the ladder live, where level 34 of 100 was 34%.
//
// Expressed as a SHARE of the cap, so it measures the property the owner cares
// about at any cap instead of re-breaking every time the cap moves.
const LIVE_SHARE = 0.8;
let worst = Infinity, worstT = 0;
for (let t = 2; t <= NORE; t++) {
  const lv = liveLevels(t);
  if (lv < worst) { worst = lv; worstT = t; }
}
ok(worst / MAXLVL >= LIVE_SHARE,
  "tier " + worstT + " stops gaining at level " + worst + " of " + MAXLVL +
  " (" + (worst / MAXLVL * 100).toFixed(0) + "% of the ladder) -- at least " +
  (LIVE_SHARE * 100) + "% must stay live");
console.log("  worst tier is " + worstT + ", gaining to level " + worst + " of " + MAXLVL +
  "  (" + (worst / MAXLVL * 100).toFixed(0) + "% live)");

// The advertisable number, since that is now a design requirement rather than a
// side effect: a per-level step too small to print is a failure.
const perLevelPct = (STEP - 1) * 100;
ok(perLevelPct >= 15, "the per-level step is +" + perLevelPct.toFixed(1) +
  "%, too small to advertise on the forge (want +15% or better)");
console.log("  advertisable: +" + perLevelPct.toFixed(1) + "% damage per level, " +
  MAXLVL + " levels to max");

// --- ASK 2: purpose above tier 60 --------------------------------------------
// Each band above 60 must be a real step over the band below it, at max level.
const topBands = ORDER.slice(ORDER.indexOf("Legendary"));
let prevTop = null, prevName = null;
for (let i = 0; i < ORDER.length; i++) {
  const hi = CUTS[i];
  const d = dmg(hi, MAXLVL);
  if (prevTop && topBands.includes(ORDER[i])) {
    const r = d / prevTop;
    ok(r >= 3, "forging " + prevName + " -> " + ORDER[i] + " is only x" + r.toFixed(1) +
      " damage; above tier 60 ORE_REACH buys no new access, so damage must carry it");
  }
  prevTop = d; prevName = ORDER[i];
}
const r6082 = dmg(NORE, MAXLVL) / dmg(60, MAXLVL);
ok(r6082 >= 100, "tier 60 -> " + NORE + " is only x" + r6082.toFixed(0) + " at max level");
console.log("  tier 60 -> " + NORE + " at max level: x" + r6082.toFixed(0));

// --- the best tool must still beat the hardest block, WITHOUT trivialising it -
//
// The first version of this file scored a bare pickaxe and passed while the
// real best tool was 90x over the deepest rock. toolPower takes a typeMult and
// the Frack is x4, so "the best tool in the game" is a tier-82 Frack and the
// type multiplier belongs in this assertion. check.js caught it; this is the
// same gate, close to where the constants live.
const TYPE_MAX = 4;    // Frack, the largest dmgMult in the TYPES table
// Deepest rock, the same anchor check.js uses: zone 11 pins itself to 11 and
// the seam table runs past the 5000 layer floor.
const hardestDirt = (HP_BASE + HP_PER * 10040) * Math.pow(ZMULT, 11 - 1);
const topTool = dmg(NORE, MAXLVL) * TYPE_MAX;
const sw = hardestDirt / topTool;
ok(sw > 1, "the best tool (tier " + NORE + " Frack, max level) clears the deepest rock in " +
  sw.toFixed(2) + " swings -- it must not trivialise it");
ok(sw <= 100, "the deepest rock is a wall: " + sw.toFixed(0) + " swings for the best tool");
console.log("  deepest rock " + hardestDirt.toExponential(2) + " vs best tool " +
  topTool.toExponential(2) + " = " + sw.toFixed(2) + " swings raw");

// And a plain pickaxe at max must still be able to work the deepest ORE.
const hardestOre = dirtHp(ZN, LAYERS) * ORE_HP_MULT;
const pickSw = Math.ceil(hardestOre / dmg(NORE, MAXLVL));
ok(pickSw <= 30, "a maxed tier-" + NORE + " pickaxe needs " + pickSw +
  " swings on the deepest ore -- over 30 and the plain type is dead weight");
console.log("  deepest ore: maxed pickaxe " + pickSw + " swings, level-1 " +
  Math.ceil(hardestOre / dmg(NORE, 1)).toLocaleString("en-US"));

// --- the band table must cover every band ------------------------------------
for (const b of ORDER) ok(BAND_MULT[b] !== undefined, "TOOL_BAND_DMG has no entry for " + b);
// and must never go backwards
for (let i = 1; i < ORDER.length; i++) {
  ok(BAND_MULT[ORDER[i]] >= BAND_MULT[ORDER[i - 1]],
    "TOOL_BAND_DMG goes backwards at " + ORDER[i]);
}

console.log(fails === 0 ? "  OK  " + checks + " checks" : "  " + fails + " of " + checks + " FAILED");
process.exit(fails === 0 ? 0 : 1);
