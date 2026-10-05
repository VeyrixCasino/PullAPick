// Breaking power: the dials, and the one rule that lives in two files.
//
// ORE_REACH is the owner's rule -- "a tool forged from ore tier T reaches
// T + 15 tiers of ore". It is READ by MineBreaking.blockStrength (the live
// gate) and SHOWN by MineConfig.canBreakOre / oreReachCap (the Forge UI).
// Until 2026-10-05 only the UI had it, so the UI promised +15 and the gate
// gave +0. It is duplicated rather than required because MineBreaking has no
// requires and is pure arithmetic; this check is the price of that choice.
const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..", "..");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8")
  .replace(/--\[\[[\s\S]*?\]\]/g, "")
  .replace(/^[ \t]*--.*$/gm, "");

const brk = read("src/ReplicatedStorage/Mine/Shared/MineBreaking.luau");
const cfg = read("src/ReplicatedStorage/Mine/Shared/MineConfig.luau");

let fails = 0;
const ok = (name, cond, detail) => {
  console.log((cond ? "  ok    " : "  FAIL  ") + name + (detail ? "   " + detail : ""));
  if (!cond) fails++;
};
const num = (src, re, what) => {
  const m = src.match(re);
  if (!m) { console.log("  FAIL  could not read " + what); fails++; return null; }
  return Number(m[1]);
};

const bReach = num(brk, /MineBreaking\.ORE_REACH\s*=\s*(\d+)/, "MineBreaking.ORE_REACH");
const cReach = num(cfg, /MineConfig\.ORE_REACH\s*=\s*(\d+)/, "MineConfig.ORE_REACH");
ok("ORE_REACH agrees across the gate and the UI", bReach !== null && bReach === cReach,
   `MineBreaking ${bReach} vs MineConfig ${cReach}`);

const bHome = num(brk, /MineBreaking\.ORE_REACH_HOME\s*=\s*(\d+)/, "MineBreaking.ORE_REACH_HOME");
const cHome = num(cfg, /MineConfig\.ORE_REACH_HOME\s*=\s*(\d+)/, "MineConfig.ORE_REACH_HOME");
ok("ORE_REACH_HOME agrees across the gate and the UI", bHome !== null && bHome === cHome,
   `MineBreaking ${bHome} vs MineConfig ${cHome}`);
ok("the home reach is tighter than the cleared one", bHome < bReach,
   `home ${bHome} < cleared ${bReach}`);

// The bug this file exists for: the gate must actually subtract the reach,
// and must pick it per-zone rather than using one flat number.
const gate = (brk.match(/function MineBreaking\.blockStrength[\s\S]*?\nend/) || [""])[0];
ok("blockStrength picks the reach per zone", /reachFor\s*\(/.test(gate),
   "goes through MineBreaking.reachFor");
ok("blockStrength subtracts the reach before asking oreStrength",
   /oreStrength\(\s*asked/.test(gate) && /asked\s*=[\s\S]*?-\s*reach/.test(gate),
   "ore is asked for `reach` tiers lower");
ok("blockStrength still gates depth separately", /math\.max\(\s*byLayer/.test(gate),
   "byLayer is not loosened by reach");
ok("canBreak forwards the player's zone progress",
   /function MineBreaking\.canBreak\([^)]*maxUnlockedZone/.test(brk) &&
   /blockStrength\([^)]*maxUnlockedZone/.test(brk),
   "maxUnlockedZone reaches blockStrength");

const dials = {
  LAYERS_PER_RUNG: 50,
  ZONE_STEP: 10,   // a zone is worth 500 layers (owner, 2026-10-05)
  ZONES: 10,
  MAX_LAYER: 10000,
};
for (const [k, want] of Object.entries(dials)) {
  const got = num(brk, new RegExp("MineBreaking\\." + k + "\\s*=\\s*(\\d+)"), k);
  ok(`${k} is ${want}`, got === want, String(got));
}
const pow = num(brk, /MineBreaking\.ORE_POW\s*=\s*([\d.]+)/, "ORE_POW");
ok("ORE_POW is 2.0", pow === 2, String(pow));

// MAX is derived, and the top ore must reach the mine floor exactly.
const MAX = 1 + (dials.ZONES - 1) * dials.ZONE_STEP
  + Math.floor((dials.MAX_LAYER - 1) / dials.LAYERS_PER_RUNG);
const oreStrength = (t, n) => 1 + Math.round(Math.pow((t - 1) / (n - 1), pow) * (MAX - 1));
ok("the top ore reaches the mine floor", oreStrength(82, 82) === MAX,
   `tier 82 -> ${oreStrength(82, 82)}, floor needs ${MAX}`);
ok("the first ore is the bottom rung", oreStrength(1, 82) === 1, String(oreStrength(1, 82)));

// Shop picks must not open the forge's territory.
//[DEADLOCK] Reach is load-bearing, not generosity. A tier-T tool has breaking
// power oreStrength(T), so with reach R it clears ore up to T+R; the ore needed
// to forge T+1 is tier T+1. At reach 0 that is a wall at tier 4. This asserts
// every tier below the top can still reach SOME higher ore at the home reach,
// so nobody can tighten ORE_REACH_HOME into a dead game.
{
  const topBreakable = (T, R) => {
    for (let o = T + 1; o <= 82; o++) if (oreStrength(Math.max(1, o - R), 82) <= oreStrength(T, 82)) return o;
    return T;
  };
  let stuck = null;
  for (let T = 1; T < 82 && stuck === null; T++) if (topBreakable(T, bHome) <= T) stuck = T;
  ok("the home reach never deadlocks progression", stuck === null,
     stuck === null ? `every tier 1-81 can reach higher ore at reach ${bHome}`
                    : `tier ${stuck} can break nothing above itself at reach ${bHome}`);
  let stuck0 = null;
  for (let T = 1; T < 82 && stuck0 === null; T++) if (topBreakable(T, 0) <= T) stuck0 = T;
  ok("...and reach 0 would, which is why it is not zero", stuck0 === 4,
     `reach 0 walls at tier ${stuck0}`);
}

const shop = (brk.match(/MineBreaking\.SHOP_POWER\s*=\s*\{([^}]*)\}/) || [])[1];
const rungs = shop ? shop.split(",").map((x) => Number(x.trim())).filter((n) => !isNaN(n)) : [];
ok("shop picks are 5 rungs at the bottom",
   rungs.length === 5 && rungs[rungs.length - 1] === 5, rungs.join(" "));
ok("the best shop pick stops short of the forge",
   rungs[rungs.length - 1] * dials.LAYERS_PER_RUNG <= 250,
   `reaches layer ${rungs[rungs.length - 1] * dials.LAYERS_PER_RUNG} in zone 1`);

console.log(fails ? `\n>>> breaking: ${fails} FAILED` : "\n>>> breaking: all assertions passed");
process.exit(fails ? 1 : 0);
