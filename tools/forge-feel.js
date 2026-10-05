// "the difference being so subtle in the tool until it gets leveled up".
//
// This is the question the cap change does NOT answer, so it gets measured on
// its own: when you forge the next tier, is the new tool an upgrade IN YOUR
// HAND, or a downgrade you have to grind back out of?
//
// You are holding a maxed tier-T tool. You forge tier T+1. It arrives at level 1.
//
//     old  =  tierPow(T)   * CLIMB
//     new  =  tierPow(T+1) * 1
//     ratio = tierStep / CLIMB
//
// tierStep is 6^(TOOL_TIER_SPAN / (ORE_COUNT-1)) and CLIMB is 350, so the ratio
// is about 1/300 regardless of the cap. A fresh tool is three hundred times
// weaker than the one you were already using. THAT is the feeling, and no cap
// value changes it, because the cap cancels out of both sides.
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
const NORE = 82;
const CAP = lastNum("TOOL_MAX_LEVEL", 30);
const CLIMB = lastNum("TOOL_CLIMB_DAMAGE", 350);
const SPAN = lastNum("TOOL_TIER_SPAN", 7);
const STEP = Math.pow(CLIMB, 1 / (CAP - 1));
const BAND = {};
for (const m of (cfg.match(/MineConfig\.TOOL_BAND_DMG\s*=\s*\{([\s\S]*?)\n\}/) || [, ""])[1]
  .matchAll(/(\w+)\s*=\s*([\d.]+)/g)) BAND[m[1]] = Number(m[2]);
const ORDER = (cfg.match(/MineConfig\.ORE_BAND_ORDER\s*=\s*\{([^}]*)\}/) || [, ""])[1]
  .split(",").map((s) => s.trim().replace(/"/g, "")).filter(Boolean);
const CUTS = [...(cfg.match(/MineConfig\.ORE_YIELD_BANDS\s*=\s*\{([\s\S]*?)\n\}/) || [, ""])[1]
  .matchAll(/upTo\s*=\s*(\d+)/g)].map((m) => Number(m[1]));
const bandOf = (t) => { for (let i = 0; i < CUTS.length; i++) if (t <= CUTS[i]) return ORDER[i];
  return ORDER[ORDER.length - 1]; };
const tierPow = (t) => Math.pow(6, SPAN * (t - 1) / (NORE - 1)) * BAND[bandOf(t)];
const dmg = (t, L) => 10 * tierPow(t) * Math.pow(STEP, L - 1);

console.log("cap " + CAP + ", +" + ((STEP - 1) * 100).toFixed(1) + "%/level, climb x" + CLIMB + "\n");
console.log("FORGING THE NEXT TIER, HOLDING A MAXED ONE");
console.log("  from -> to     fresh vs your maxed tool   level it must reach to break even");
for (const t of [10, 20, 30, 40, 50, 60, 61, 70, 71, 80, 81]) {
  const old = dmg(t, CAP), fresh = dmg(t + 1, 1);
  let breakeven = null;
  for (let L = 1; L <= CAP; L++) if (dmg(t + 1, L) >= old) { breakeven = L; break; }
  const cross = bandOf(t) !== bandOf(t + 1) ? "  (band border: " + bandOf(t) + " -> " + bandOf(t + 1) + ")" : "";
  console.log("  " + (t + " -> " + (t + 1)).padEnd(15) +
    ("x" + (fresh / old).toFixed(3)).padEnd(27) +
    (breakeven ? "level " + breakeven + " of " + CAP : "NEVER -- worse even at max") + cross);
}

// ---- can tuning fix this at all? -------------------------------------------
// For a fresh tier-(T+1) tool to beat a maxed tier-T tool you need
// tierStep >= CLIMB. There are ORE_COUNT-1 tier steps and the total is capped
// by check.js at about 2.3e8 before the band and type multipliers, so:
//     tierStep^81 * CLIMB <= 2.3e8   with   tierStep >= CLIMB
// The best case is tierStep == CLIMB == x, giving x^82 = 2.3e8.
const BUDGET = 2.3e8;
const x = Math.pow(BUDGET, 1 / (NORE));
console.log("\nCAN THIS BE TUNED AWAY? No, and here is the arithmetic.");
console.log("  A fresh tool only beats your maxed one if a tier step is worth at");
console.log("  least a whole climb. With " + (NORE - 1) + " tier steps inside a total damage");
console.log("  budget of " + BUDGET.toExponential(1) + ", the best possible case is");
console.log("  tier step = climb = x" + x.toFixed(3) + " -- i.e. a full climb worth +" +
  ((x - 1) * 100).toFixed(0) + "%,");
console.log("  which means levelling a tool is worth almost nothing. The ladder is");
console.log("  82 tiers long; that length is what forces the per-tier step small.");

// ---- the fix that does work ------------------------------------------------
// Carry the level across the forge. Then a new tool arrives already levelled and
// the tier step is a pure gain.
console.log("\nWHAT ACTUALLY FIXES IT: carry the level across the forge.");
console.log("  inherit   fresh tier+1 vs your maxed tier   verdict");
for (const f of [0, 0.25, 0.5, 0.75, 0.9, 1.0]) {
  const start = Math.max(1, Math.round(f * CAP));
  const r = dmg(51, start) / dmg(50, CAP);
  console.log("  " + (f * 100).toFixed(0).padStart(3) + "%      " +
    ("x" + r.toFixed(3)).padEnd(32) +
    (r >= 1 ? "an upgrade the moment you forge it" : "still a downgrade"));
}
console.log("\n  Only full inheritance makes forging feel like an upgrade, because a");
console.log("  tier step (+" + ((tierPow(51) / tierPow(50) - 1) * 100).toFixed(1) +
  "%) is smaller than one level (+" + ((STEP - 1) * 100).toFixed(1) + "%).");
console.log("  With it, levels become the early ramp you climb once and keep, and");
console.log("  TIER becomes the real progression -- which is what ORE_REACH and the");
console.log("  breaking gate already treat as the ladder.");
