// THE FIX, modelled before it is written. Owner, 2026-10-05: "fix the damage
// curve so levelling matters past 34, and fix it for all tools so theres still
// purpose to get a pick abive teir 60", then "if need be dissect them
// individually".
//
// Bands are read off ORE_YIELD_BANDS, which is where the roster actually
// divides -- Epic ENDS at tier 60, so "a pick above tier 60" means the four top
// bands, Legendary 61-69 / Mythic 70-75 / Divine 76-79 / Exotic 80-82.
//
// THREE PROBLEMS, THREE LEVERS.
//
// 1. LEVELLING DIES AT 34 because TOOL_CLIMB_DAMAGE is 3.9e8 -- a tool gets
//    390 million times stronger over 99 levels while its home content never
//    changes. Nothing can absorb that, so it one-shots and the rest of the
//    ladder is decoration.
//
//    The principled size for the climb is the HP growth a tool has to chew
//    through during its own working life. A tool is forged at the top of a zone
//    and carries the player to the bottom of it, and within one zone HP goes
//    from (20 + 1.5*1) to (20 + 1.5*5000) -- a factor of 350. So the climb
//    should be about 350, not 390 million. That is not a fitted number; it is
//    the one piece of content the levels have to cover.
//
// 2. TIER IS SHORT-CHANGED because toolTierPower divides by a hardcoded 120,
//    which was #ORES-1 back when the roster held 121 ores. At 82 the exponent
//    only travels 81/120 of its range, so TOOL_TIER_SPAN = 16 delivers 6^10.8
//    instead of 6^16. Fixed to ORE_COUNT-1 so the constant means what it says.
//
// 3. NOTHING ABOVE TIER 67 BUYS ACCESS, which is the real "why bother past 60".
//    ORE_REACH is 15 and the roster ends at 82, so a tier-67 tool already
//    reaches every ore in the game, and the deepest dirt only demands breaking
//    power 109 against a scale that runs to 209. Tiers 68-82 are access-
//    identical by construction. PROPOSAL 0 line 14 keeps ORE_REACH at 15, so
//    the breaking gate is not the lever -- damage has to carry those 15 tiers
//    on its own, and a smooth exponential spreads them too thinly to feel.
//
//    Hence the per-band step: the four top bands get a multiplier ON TOP of the
//    smooth curve, so forging into Legendary, Mythic, Divine and Exotic is a
//    visible jump rather than another 1.3%. This is the "dissect them
//    individually" the owner asked for, and it follows the shape MineConfig
//    already uses for cost (toolCostMult's bell).
const NORE = 82, MAXLVL = 100, DMG_BASE = 10, ORE_REACH = 15;
const HP_BASE = 20, HP_PER_LAYER = 1.5, ZONE_HP_MULT = 5, ORE_HP_MULT = 3;
const LPR = 50, ZONES = 10, MAX_LAYER = 10000, ORE_POW = 2.0, LAYERS = 5000;
const MAXP = 1 + (ZONES - 1) + Math.floor((MAX_LAYER - 1) / LPR);

const clampInt = (v, lo, hi) => Math.max(lo, Math.min(hi, Math.round(v)));
const dirtHp = (zi, L) => (HP_BASE + HP_PER_LAYER * L) * Math.pow(ZONE_HP_MULT, zi - 1);
const oreStrength = (t) => clampInt(
  1 + Math.floor(Math.pow((Math.max(1, t) - 1) / (NORE - 1), ORE_POW) * (MAXP - 1) + 0.5), 1, MAXP);

// Straight off MineConfig.ORE_YIELD_BANDS.
const BANDS = [["Common", 18], ["Uncommon", 29], ["Rare", 49], ["Epic", 60],
  ["Legendary", 69], ["Mythic", 75], ["Divine", 79], ["Exotic", 82]];
function bandOf(t) {
  for (let i = 0; i < BANDS.length; i++) if (t <= BANDS[i][1]) return [BANDS[i][0], i + 1];
  return ["Exotic", 8];
}

const SUF = ["K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No"];
const big = (v) => {
  if (!isFinite(v)) return "inf";
  if (v < 1000) return String(Math.round(v));
  let s = 0;
  while (v >= 1000 && s < SUF.length) { v /= 1000; s++; }
  const dp = v >= 100 ? 1 : v >= 10 ? 2 : 3;
  return (Math.floor(v * Math.pow(10, dp)) / Math.pow(10, dp)).toFixed(dp) + SUF[s - 1];
};

// Where a player holding tier t is mining.
//
// Across ELEVEN zones, not ten. Event Horizon is real content and the top of
// the roster spawns in it, so scoring tier 82 against zone 10 flatters it by a
// factor of five and makes the top bands look stronger than they play. Mapping
// over all eleven puts Oganesson's home at Event Horizon L5000 -- the hardest
// block in the game, which is what the best tool in the game is for.
const HOME_ZONES = 11;
function spawnHome(t) {
  const abs = ((t - 1) / (NORE - 1)) * (HOME_ZONES * LAYERS);
  const zi = Math.min(HOME_ZONES, Math.floor(abs / LAYERS) + 1);
  const L = Math.max(1, Math.min(LAYERS, Math.round(abs - (zi - 1) * LAYERS)));
  return { zi, L, hp: dirtHp(zi, L) * ORE_HP_MULT };
}

// --- the curve, READ FROM THE LIVE CONFIG ------------------------------------
// This file chose the numbers, so it must not keep its own copy of them -- that
// is how tools/upgrade-calculator.html ended up asserting a 1000-level curve
// against a 100-level game for months.
const fs = require("fs"), path = require("path");
const cfg = fs.readFileSync(
  path.join(__dirname, "..", "src/ReplicatedStorage/Mine/Shared/MineConfig.luau"), "utf8")
  .split("\r\n").join("\n");
const lastNum = (k) => {
  const g = new RegExp("MineConfig\\." + k + "\\s*=\\s*([0-9.eE+-]+)", "g");
  let v = null, m;
  while ((m = g.exec(cfg))) v = Number(m[1]);
  return v;
};
const SPAN = lastNum("TOOL_TIER_SPAN");
const CLIMB = lastNum("TOOL_CLIMB_DAMAGE");
const STEP = Math.pow(CLIMB, 1 / (MAXLVL - 1));
const BAND_MULT = {};
for (const m of (cfg.match(/MineConfig\.TOOL_BAND_DMG\s*=\s*\{([\s\S]*?)\n\}/) || [, ""])[1]
  .matchAll(/(\w+)\s*=\s*([\d.]+)/g)) BAND_MULT[m[1]] = Number(m[2]);

const nowDmg = (t, L) => DMG_BASE * Math.pow(6, 16 * (t - 1) / 120) * Math.pow(Math.pow(3.9e8, 1 / 99), L - 1);
const newDmg = (t, L) => DMG_BASE * Math.pow(6, SPAN * (t - 1) / (NORE - 1))
  * BAND_MULT[bandOf(t)[0]] * Math.pow(STEP, L - 1);

function liveLevels(dmg, t) {
  const h = spawnHome(t);
  for (let L = 1; L <= MAXLVL; L++) if (Math.ceil(h.hp / dmg(t, L)) <= 1) return L;
  return MAXLVL;
}

console.log("PROPOSED: TOOL_TIER_SPAN " + SPAN + " over divisor " + (NORE - 1) +
  ", TOOL_CLIMB_DAMAGE " + CLIMB + " (+" + ((STEP - 1) * 100).toFixed(2) + "%/level)");
console.log("plus a per-band step on the four bands above tier 60.\n");

console.log("band        tiers    live levels      swings at home L1 -> L100     band step");
console.log("                     now    after     now          after");
for (let i = 0; i < BANDS.length; i++) {
  const lo = i === 0 ? 1 : BANDS[i - 1][1] + 1, hi = BANDS[i][1];
  const mid = Math.round((lo + hi) / 2);
  const h = spawnHome(mid);
  let ln = 0, la = 0;
  for (let t = lo; t <= hi; t++) { ln += liveLevels(nowDmg, t); la += liveLevels(newDmg, t); }
  const n = hi - lo + 1;
  console.log("  " + BANDS[i][0].padEnd(11) + (lo + "-" + hi).padEnd(8) +
    (ln / n).toFixed(0).padStart(4) + "  " + (la / n).toFixed(0).padStart(6) + "     " +
    (big(Math.ceil(h.hp / nowDmg(mid, 1))) + "->" + big(Math.ceil(h.hp / nowDmg(mid, MAXLVL)))).padEnd(13) +
    (big(Math.ceil(h.hp / newDmg(mid, 1))) + "->" + big(Math.ceil(h.hp / newDmg(mid, MAXLVL)))).padEnd(13) +
    "x" + BAND_MULT[BANDS[i][0]]);
}

console.log("\nIS IT WORTH FORGING UP? damage at max level, each band's top tier");
let prev = null;
for (const [name, hi] of BANDS) {
  const d = newDmg(hi, MAXLVL);
  console.log("  " + name.padEnd(11) + "tier " + String(hi).padEnd(4) + big(d).padStart(10) +
    (prev ? "   x" + (d / prev).toFixed(1) + " over the band below" : ""));
  prev = d;
}

console.log("\nTHE TWO ASKS, CHECKED");
const l34 = liveLevels(newDmg, 67), l34n = liveLevels(nowDmg, 67);
console.log("  1. levelling past 34:  tier 67 had " + l34n +
  " live levels, now has " + l34);
let worst = 100, worstT = 0;
for (let t = 1; t <= NORE; t++) { const v = liveLevels(newDmg, t); if (v < worst) { worst = v; worstT = t; } }
console.log("     worst tier in the game: tier " + worstT + " with " + worst + " live levels");
const r60 = newDmg(82, MAXLVL) / newDmg(60, MAXLVL);
const r60n = nowDmg(82, MAXLVL) / nowDmg(60, MAXLVL);
console.log("  2. purpose above tier 60:  was x" + r60n.toFixed(0) +
  " spread smoothly, now x" + r60.toFixed(0) + " with four visible steps");
const hardest = dirtHp(11, 5000) * ORE_HP_MULT;
console.log("\n  hardest block in the game, Event Horizon L5000 ore (" + big(hardest) + "):");
console.log("    tier 82 L1   " + big(newDmg(82, 1)) + " a swing -> " +
  Math.ceil(hardest / newDmg(82, 1)).toLocaleString("en-US") + " swings");
console.log("    tier 82 L100 " + big(newDmg(82, MAXLVL)) + " a swing -> " +
  Math.ceil(hardest / newDmg(82, MAXLVL)).toLocaleString("en-US") + " swings");
console.log("    tier 61 L100 " + big(newDmg(61, MAXLVL)) + " a swing -> " +
  Math.ceil(hardest / newDmg(61, MAXLVL)).toLocaleString("en-US") + " swings");
