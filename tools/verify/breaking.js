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

// The bug this file exists for: the gate must actually subtract the reach.
ok("blockStrength applies ORE_REACH",
   /ORE_REACH[\s\S]{0,200}?oreStrength\(\s*asked/.test(brk) ||
   /oreStrength\(\s*math\.max\(1,[^)]*ORE_REACH/.test(brk),
   "the gate subtracts reach before asking oreStrength");

const dials = {
  LAYERS_PER_RUNG: 50,
  ZONE_STEP: 1,
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
const shop = (brk.match(/MineBreaking\.SHOP_POWER\s*=\s*\{([^}]*)\}/) || [])[1];
const rungs = shop ? shop.split(",").map((x) => Number(x.trim())).filter((n) => !isNaN(n)) : [];
ok("shop picks are 5 rungs at the bottom",
   rungs.length === 5 && rungs[rungs.length - 1] === 5, rungs.join(" "));
ok("the best shop pick stops short of the forge",
   rungs[rungs.length - 1] * dials.LAYERS_PER_RUNG <= 250,
   `reaches layer ${rungs[rungs.length - 1] * dials.LAYERS_PER_RUNG} in zone 1`);

console.log(fails ? `\n>>> breaking: ${fails} FAILED` : "\n>>> breaking: all assertions passed");
process.exit(fails ? 1 : 0);
