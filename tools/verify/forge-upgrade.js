// Forging the next tier must be an UPGRADE, not a thirty-level apology.
//
// A forged tool used to arrive at level 1, which made every forge a downgrade:
// a fresh tier-(T+1) tool is x0.003 of the maxed tier-T tool already in your
// hand and has to be levelled to the cap just to break even. At every tier, all
// the way up the roster.
//
// It is not tunable. A fresh tool only wins if ONE TIER STEP is worth A WHOLE
// CLIMB, and with ORE_COUNT-1 tier steps inside the damage budget the best
// possible case is tierStep == climb == about x1.27 -- which makes levelling a
// tool worth nothing at all. The roster being 82 long is what forces the step
// small, so the fix has to be mechanical: craftOreTool carries the level across.
//
// This asserts the mechanism is still wired, because it is one line in a 15,000
// line server file and nothing else would notice if it went back to `level = 1`.
//
// Run: node tools/verify/forge-upgrade.js
const path = require("path");
const { readSrc } = require("./_luau.js");
const ROOT = path.join(__dirname, "..", "..");
const cfg = readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau"));
const srv = readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineServer.server.luau"));

let fails = 0, checks = 0;
const ok = (c, msg, detail) => {
  checks++;
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};
const num = (src, k, d) => {
  const g = new RegExp(k + "\\s*=\\s*(-?[0-9.eE+-]+)", "g");
  let v = null, m;
  while ((m = g.exec(src))) v = Number(m[1]);
  return v === null ? d : v;
};

const NORE = 82;
const MAXLVL = num(cfg, "MineConfig\\.TOOL_MAX_LEVEL", 30);
const CLIMB = num(cfg, "MineConfig\\.TOOL_CLIMB_DAMAGE", 350);
const SPAN = num(cfg, "MineConfig\\.TOOL_TIER_SPAN", 7);
const BASE = num(cfg, "MineConfig\\.TOOL_DMG_BASE", 10);
const STEP = Math.pow(CLIMB, 1 / (MAXLVL - 1));

const BAND = {};
for (const m of (cfg.match(/MineConfig\.TOOL_BAND_DMG\s*=\s*\{([\s\S]*?)\n\}/) || [, ""])[1]
  .matchAll(/(\w+)\s*=\s*([\d.]+)/g)) BAND[m[1]] = Number(m[2]);
const ORDER = (cfg.match(/MineConfig\.ORE_BAND_ORDER\s*=\s*\{([^}]*)\}/) || [, ""])[1]
  .split(",").map((s) => s.trim().replace(/"/g, "")).filter(Boolean);
const CUTS = [...(cfg.match(/MineConfig\.ORE_YIELD_BANDS\s*=\s*\{([\s\S]*?)\n\}/) || [, ""])[1]
  .matchAll(/upTo\s*=\s*(\d+)/g)].map((m) => Number(m[1]));
const bandOf = (t) => { for (let i = 0; i < CUTS.length; i++) if (t <= CUTS[i]) return ORDER[i];
  return ORDER[ORDER.length - 1]; };
const dmg = (t, L) => BASE * Math.pow(6, SPAN * (t - 1) / (NORE - 1))
  * (BAND[bandOf(t)] || 1) * Math.pow(STEP, L - 1);

console.log("forge-upgrade: cap " + MAXLVL + ", climb x" + CLIMB + ", span " + SPAN);

// --- the mechanism is wired ---------------------------------------------------
const craft = srv.match(/function Verbs\.craftOreTool[\s\S]*?\n\tlocal row = \{[\s\S]*?\n\t\}/);
ok(!!craft, "craftOreTool still builds the tool row");
if (craft) {
  ok(!/\blevel = 1\b/.test(craft[0]),
    "a forged tool does not arrive at level 1",
    "level = 1 would make every forge a downgrade");
  ok(/level = inherited/.test(craft[0]) && /t\.level/.test(craft[0]),
    "the forged level is inherited from the rack",
    "craftOreTool scans p.oreTools for the best level");
  ok(/math\.clamp\(inherited/.test(craft[0]),
    "the inherited level is clamped to the cap");
}

// --- and it actually makes forging worth it ----------------------------------
// Holding a MAXED tier-T tool, forge tier T+1. Inheriting the level means the
// comparison is the bare tier step; arriving at level 1 means tierStep / climb.
let worstInherit = Infinity, worstAt = 0, anyDowngrade = null;
for (let t = 1; t < NORE; t++) {
  const mine = dmg(t, MAXLVL);
  const inherited = dmg(t + 1, MAXLVL);
  const fresh = dmg(t + 1, 1);
  const r = inherited / mine;
  if (r < worstInherit) { worstInherit = r; worstAt = t; }
  if (r < 1 && anyDowngrade === null) anyDowngrade = t;
  if (t === 40) {
    console.log("  tier 40 -> 41:  at level 1 x" + (fresh / mine).toFixed(4) +
      ", inheriting x" + r.toFixed(4));
  }
}
ok(anyDowngrade === null,
  "forging the next tier is never a downgrade",
  anyDowngrade === null ? "worst step is tier " + worstAt + " -> " + (worstAt + 1) +
    " at x" + worstInherit.toFixed(4) : "tier " + anyDowngrade + " loses damage");

// The level-1 case is kept as the counterfactual, so the number that justifies
// the mechanism is in the output rather than only in a commit message.
const flat = dmg(41, 1) / dmg(40, MAXLVL);
ok(flat < 0.01,
  "...and arriving at level 1 would still be a downgrade",
  "x" + flat.toFixed(4) + " if the level were not carried");

// --- the cap migration is stamped separately ---------------------------------
ok(/MineConfig\.TOOL_CAP_V\s*=\s*\d+/.test(cfg),
  "TOOL_CAP_V exists, so the cap migration has its own stamp");
ok(/p\.toolCapV/.test(srv),
  "the server reads and writes p.toolCapV",
  "the roster stamp runs once and cannot carry a later cap change");

console.log(fails === 0 ? ">>> forge-upgrade: all " + checks + " checks passed"
  : ">>> forge-upgrade: " + fails + " of " + checks + " FAILED");
process.exit(fails === 0 ? 0 : 1);
