// Primordium Heart, layer 5000: what breaks it, and with what.
//
// Two independent gates, and a tool has to pass both:
//
//   BREAKING POWER   MineBreaking.blockStrength vs toolBreakingPower. Binary --
//                    fail it and damage is irrelevant, the swing does nothing.
//   DAMAGE           MineConfig.toolPower vs the block's HP. Decides swings.
const fs = require("fs");
const read = (p) => fs.readFileSync(p, "utf8").split("\r\n").join("\n");
const S = "src/ReplicatedStorage/Mine/Shared/";
const cfg = read(S + "MineConfig.luau");

const lastNum = (src, k, d) => {
  const g = new RegExp(k + "\\s*=\\s*([0-9.eE+]+)", "g");
  let v = null, m;
  while ((m = g.exec(src))) v = Number(m[1]);
  return v === null ? d : v;
};

// --- depth / HP (MineDepth.dirtHp: the LINEAR curve, not the SECTIONS table) --
const HP_BASE = 20, HP_PER_LAYER = 1.5, ZONE_HP_MULT = 5, ORE_HP_MULT = 3;
const dirtHp = (zi, L) => (HP_BASE + HP_PER_LAYER * L) * Math.pow(ZONE_HP_MULT, zi - 1);

// --- breaking (MineBreaking) -------------------------------------------------
const LAYERS_PER_RUNG = 50, ZONE_STEP = 1, ZONES = 10, MAX_LAYER = 10000, ORE_POW = 2.0;
const ORE_REACH = 15, NORE = 82;
const MAXP = 1 + (ZONES - 1) * ZONE_STEP + Math.floor((MAX_LAYER - 1) / LAYERS_PER_RUNG);
const clampInt = (v, lo, hi) => Math.max(lo, Math.min(hi, Math.round(v)));
const layerStrength = (zi, L) =>
  clampInt(1 + (zi - 1) * ZONE_STEP + Math.floor((L - 1) / LAYERS_PER_RUNG), 1, MAXP);
const oreStrength = (tier) =>
  clampInt(1 + Math.floor(Math.pow((Math.max(1, tier) - 1) / (NORE - 1), ORE_POW) * (MAXP - 1) + 0.5), 1, MAXP);
const blockStrength = (zi, L, oreTier) => {
  const byLayer = layerStrength(zi, L);
  if (oreTier == null) return byLayer;
  return Math.max(byLayer, oreStrength(Math.max(1, oreTier - ORE_REACH)));
};

// --- damage (MineConfig.toolPower) -------------------------------------------
const MAXLVL = lastNum(cfg, "MineConfig\\.TOOL_MAX_LEVEL", 100);
const DMG_BASE = lastNum(cfg, "MineConfig\\.TOOL_DMG_BASE", 10);
const TIER_SPAN = lastNum(cfg, "MineConfig\\.TOOL_TIER_SPAN", 16);
const CLIMB = lastNum(cfg, "MineConfig\\.TOOL_CLIMB_DAMAGE", 3.9e8);
const step = Math.pow(CLIMB, 1 / (MAXLVL - 1));

// The divisor used to be a hardcoded 120 here, mirroring a hardcoded 120 in
// toolTierPower -- #ORES-1 from the old 121-ore roster. Both are fixed; this
// reads the roster and the band table so the answer cannot drift from the game.
const bandBody = (cfg.match(/MineConfig\.TOOL_BAND_DMG\s*=\s*\{([\s\S]*?)\n\}/) || [, ""])[1];
const BAND_DMG = {};
for (const m of bandBody.matchAll(/(\w+)\s*=\s*([\d.]+)/g)) BAND_DMG[m[1]] = Number(m[2]);
const BAND_ORDER = (cfg.match(/MineConfig\.ORE_BAND_ORDER\s*=\s*\{([^}]*)\}/) || [, ""])[1]
  .split(",").map((s) => s.trim().replace(/"/g, "")).filter(Boolean);
const BAND_CUTS = [...(cfg.match(/MineConfig\.ORE_YIELD_BANDS\s*=\s*\{([\s\S]*?)\n\}/) || [, ""])[1]
  .matchAll(/upTo\s*=\s*(\d+)/g)].map((m) => Number(m[1]));
const bandOf = (t) => {
  for (let i = 0; i < BAND_CUTS.length; i++) if (t <= BAND_CUTS[i]) return BAND_ORDER[i];
  return BAND_ORDER[BAND_ORDER.length - 1];
};
const tierPow = (t) =>
  Math.pow(6, TIER_SPAN * (t - 1) / (NORE - 1)) * (BAND_DMG[bandOf(t)] || 1);
const dmg = (t, L) => DMG_BASE * tierPow(t) * Math.pow(step, L - 1);

const SUF = ["K", "M", "B", "T", "Qa", "Qi", "Sx"];
const big = (v) => {
  if (v < 1000) return String(Math.floor(v));
  let s = 0;
  while (v >= 1000 && s < SUF.length) { v /= 1000; s++; }
  const dp = v >= 100 ? 1 : v >= 10 ? 2 : 3;
  const f = Math.pow(10, dp);
  return (Math.floor(v * f) / f).toFixed(dp) + SUF[s - 1];
};
const n = (v) => Math.round(v).toLocaleString("en-US");

const ZI = 10, L = 5000;
const DIRT = dirtHp(ZI, L), ORE = DIRT * ORE_HP_MULT;

console.log("PRIMORDIUM HEART, LAYER 5000");
console.log("  dirt " + big(DIRT) + " = " + n(DIRT) + "      ore " + big(ORE) + " = " + n(ORE));
console.log("  breaking power needed:  dirt " + blockStrength(ZI, L, null) +
  "   ore tier 82 " + blockStrength(ZI, L, 82) + "   (scale maxes at " + MAXP + ")");
console.log("");

console.log("TOP PICK (tier 82, Oganesson)");
for (const lv of [1, MAXLVL]) {
  const d = dmg(82, lv);
  console.log("  level " + String(lv).padEnd(4) + " damage " + big(d).padEnd(10) + n(d));
  console.log("        vs dirt " + n(Math.ceil(DIRT / d)) + " swings" +
    "      vs ore " + n(Math.ceil(ORE / d)) + " swings");
}
console.log("  breaking power " + oreStrength(82) + " vs the " + blockStrength(ZI, L, 82) + " that ore needs" +
  (oreStrength(82) >= blockStrength(ZI, L, 82) ? "  -> passes" : "  -> FAILS"));
console.log("");

// --- lowest tier that passes the gate, and the level it needs ---------------
function lowestTier(need) {
  for (let t = 1; t <= NORE; t++) if (oreStrength(t) >= need) return t;
  return null;
}
function levelFor(t, hp, swings) {
  for (let lv = 1; lv <= MAXLVL; lv++) if (dmg(t, lv) * swings >= hp) return lv;
  return null;
}

for (const [label, hp, need] of [
  ["DIRT", DIRT, blockStrength(ZI, L, null)],
  ["ORE (tier 82)", ORE, blockStrength(ZI, L, 82)],
]) {
  const t = lowestTier(need);
  console.log("LOWEST TOOL THAT CAN BREAK THE " + label);
  console.log("  needs breaking power " + need + "  ->  lowest ore tier that reaches it: " +
    (t ? "tier " + t + " (power " + oreStrength(t) + ")" : "NOTHING ON THE ROSTER"));
  if (t) {
    for (const sw of [1, 5, 20, 100]) {
      const lv = levelFor(t, hp, sw);
      console.log("    to kill it in " + String(sw).padStart(3) + " swing(s): " +
        (lv ? "level " + lv : "impossible even at level " + MAXLVL +
          " (" + big(dmg(t, MAXLVL)) + " a swing, needs " + n(Math.ceil(hp / dmg(t, MAXLVL))) + ")"));
    }
  }
  console.log("");
}
