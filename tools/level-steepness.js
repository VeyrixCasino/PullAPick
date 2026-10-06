// How steep can a level be, and what does it cost? Owner, 2026-10-05:
//
//   "i dont know how i feel about the difference being so subtle in the tool
//    until it gets leveled up... it makes sense once everything is lv 100 but
//    thats 10s of hours of grinding... keep the current values ub mine map and
//    tool, but try a bit of an instant damage formula"
//   "or even if the levels were steeper, something i could advertise when people
//    crafting a new tool by each level UP%X"
//
// The advertisable number is TOOL_DMG_STEP, and it is arithmetic, not taste:
//
//     per-level %  =  TOOL_CLIMB_DAMAGE ^ (1 / (TOOL_MAX_LEVEL - 1))
//
// At climb 350 over 99 steps that is +6.1%, which is not a thing anyone puts on
// a button. The climb cannot grow -- it is pinned to one zone's HP growth, and
// check.js refuses a maxed tool that trivialises the deepest rock. So the only
// way to a steep per-level number is FEWER LEVELS over the same total climb.
//
// MineConfig was built for exactly this. Its own comment: "THE CAP IS ONE LINE,
// ON PURPOSE... the per-level rates are DERIVED from what a whole climb is
// worth instead of being stated directly. Move the cap and the curve
// restretches." TOOL_DMG_STEP, TOOL_ORE_GROW and TOOL_DUST_GROW all come out of
// perLevel(), so moving the cap moves all three and the END POINTS DO NOT MOVE.
// A maxed tool is exactly as strong at cap 30 as at cap 100.
//
// That is the "instant damage formula": the same power, reached in a quarter of
// the steps, with a headline number worth printing on the forge.
const fs = require("fs"), path = require("path");
const cfg = fs.readFileSync(
  path.join(__dirname, "..", "src/ReplicatedStorage/Mine/Shared/MineConfig.luau"), "utf8")
  .split("\r\n").join("\n");
const lastNum = (k, d) => {
  const g = new RegExp("MineConfig\\." + k + "\\s*=\\s*([0-9.eE+-]+)", "g");
  let v = null, m;
  while ((m = g.exec(cfg))) v = Number(m[1]);
  return v === null ? d : v;
};

const CLIMB_DMG = lastNum("TOOL_CLIMB_DAMAGE", 350);
const CLIMB_ORE = lastNum("TOOL_CLIMB_ORE", 1747);
const CLIMB_DUST = lastNum("TOOL_CLIMB_DUST", 55800);
const ORE_BASE = lastNum("TOOL_ORE_BASE", 4);
const DUST_BASE = lastNum("TOOL_DUST_BASE", 25);
const LIVE_CAP = lastNum("TOOL_MAX_LEVEL", 100);

const SUF = ["K", "M", "B", "T", "Qa"];
const big = (v) => {
  if (v < 1000) return String(Math.round(v));
  let s = 0;
  while (v >= 1000 && s < SUF.length) { v /= 1000; s++; }
  const dp = v >= 100 ? 1 : v >= 10 ? 2 : 3;
  return (Math.floor(v * Math.pow(10, dp)) / Math.pow(10, dp)).toFixed(dp) + SUF[s - 1];
};

// Cost of a whole climb at a given cap, for a 1x tool (tier 1 pickaxe).
function climbCost(cap) {
  const oreGrow = Math.pow(CLIMB_ORE, 1 / Math.max(1, cap - 1));
  const dustGrow = Math.pow(CLIMB_DUST, 1 / Math.max(1, cap - 1));
  let ore = 0, dust = 0;
  for (let L = 1; L < cap; L++) {
    ore += Math.ceil(ORE_BASE * Math.pow(oreGrow, L - 1));
    dust += Math.ceil(DUST_BASE * Math.pow(dustGrow, L - 1));
  }
  return { ore, dust };
}

// At 10 blocks/s, roughly how long does the ore for a full climb take? Ore comes
// in packs; MineConfig.ORE_CHANCE is 1/200 and a pack yields ~8-15 by band, so
// call it 1 ore per 200/11 blocks as a single honest order-of-magnitude figure.
const BLOCKS_PER_SEC = 10, ORE_PER_BLOCK = 11 / 200;
const hoursFor = (ore) => ore / ORE_PER_BLOCK / BLOCKS_PER_SEC / 3600;

console.log("climb is fixed at x" + CLIMB_DMG + " damage, so the ONLY lever on the");
console.log("per-level number is the cap. End points never move.\n");
console.log("cap    per level   levels to 50% / 80% of max dmg   ore to max   hours*   dust to max");

const CAPS = [100, 60, 50, 40, 30, 25, 20, 15, 10];
for (const cap of CAPS) {
  const step = Math.pow(CLIMB_DMG, 1 / (cap - 1));
  // level at which damage reaches a fraction of max
  const lvlAt = (frac) => {
    for (let L = 1; L <= cap; L++) {
      if (Math.pow(step, L - 1) / CLIMB_DMG >= frac) return L;
    }
    return cap;
  };
  const c = climbCost(cap);
  const mark = cap === LIVE_CAP ? "  <- live" : "";
  console.log(
    String(cap).padEnd(7) +
    ("+" + ((step - 1) * 100).toFixed(1) + "%").padEnd(12) +
    (lvlAt(0.5) + " / " + lvlAt(0.8)).padEnd(32) +
    big(c.ore).padEnd(13) +
    hoursFor(c.ore).toFixed(1).padEnd(9) +
    big(c.dust) + mark);
}
console.log("\n* one tier-1 pickaxe, 10 blocks/s, ~1 ore per 18 blocks. Higher tiers");
console.log("  cost more by toolCostMult's bell, so treat this as the floor.");

// ---- what a player SEES on the forge --------------------------------------
console.log("\nWHAT THE FORGE COULD ADVERTISE");
for (const cap of [100, 40, 30, 25, 20]) {
  const step = Math.pow(CLIMB_DMG, 1 / (cap - 1));
  const pct = (step - 1) * 100;
  console.log("  cap " + String(cap).padEnd(4) + '"+' + pct.toFixed(0) + '% damage per level"' +
    (pct >= 15 ? "   <- worth a button" : "   -- too small to print"));
}

// ---- does levelling still MATTER at a lower cap? --------------------------
// Fewer levels means each one is a bigger share, so the thing that died at the
// old curve (levels that change nothing) gets better, not worse. Measured the
// same way as tools/damage-fix.js: at the depth each ore spawns.
const NORE = 82, DMG_BASE = lastNum("TOOL_DMG_BASE", 10);
const SPAN = lastNum("TOOL_TIER_SPAN", 7);
const HP_BASE = 20, HP_PER = 1.5, ZMULT = 5, ORE_HP_MULT = 3, ZN = 11, LAYERS = 5000;
const BAND_DMG = {};
for (const m of (cfg.match(/MineConfig\.TOOL_BAND_DMG\s*=\s*\{([\s\S]*?)\n\}/) || [, ""])[1]
  .matchAll(/(\w+)\s*=\s*([\d.]+)/g)) BAND_DMG[m[1]] = Number(m[2]);
const ORDER = (cfg.match(/MineConfig\.ORE_BAND_ORDER\s*=\s*\{([^}]*)\}/) || [, ""])[1]
  .split(",").map((s) => s.trim().replace(/"/g, "")).filter(Boolean);
const CUTS = [...(cfg.match(/MineConfig\.ORE_YIELD_BANDS\s*=\s*\{([\s\S]*?)\n\}/) || [, ""])[1]
  .matchAll(/upTo\s*=\s*(\d+)/g)].map((m) => Number(m[1]));
const bandOf = (t) => { for (let i = 0; i < CUTS.length; i++) if (t <= CUTS[i]) return ORDER[i];
  return ORDER[ORDER.length - 1]; };
const dirtHp = (zi, L) => (HP_BASE + HP_PER * L) * Math.pow(ZMULT, zi - 1);
const homeHp = (t) => {
  const abs = ((t - 1) / (NORE - 1)) * (ZN * LAYERS);
  const zi = Math.min(ZN, Math.floor(abs / LAYERS) + 1);
  const L = Math.max(1, Math.min(LAYERS, Math.round(abs - (zi - 1) * LAYERS)));
  return dirtHp(zi, L) * ORE_HP_MULT;
};
console.log("\nDOES LEVELLING STILL MATTER? (levels that change the swing count, as a %)");
for (const cap of [100, 40, 30, 25, 20]) {
  const step = Math.pow(CLIMB_DMG, 1 / (cap - 1));
  let sum = 0;
  for (let t = 1; t <= NORE; t++) {
    const hp = homeHp(t);
    let live = cap;
    for (let L = 1; L <= cap; L++) {
      const d = DMG_BASE * Math.pow(6, SPAN * (t - 1) / (NORE - 1)) * BAND_DMG[bandOf(t)]
        * Math.pow(step, L - 1);
      if (hp / d <= 1) { live = L; break; }
    }
    sum += live / cap;
  }
  console.log("  cap " + String(cap).padEnd(4) + (sum / NORE * 100).toFixed(1) + "% of levels are live" +
    "   (+" + ((step - 1) * 100).toFixed(1) + "%/level)");
}
