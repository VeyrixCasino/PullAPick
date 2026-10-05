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

//[[ READ THE DIALS, DO NOT RESTATE THEM ]]
// This block used to hardcode the four dials as the EXPECTED values and then
// derive MAX from its own copy. That made the most important assertion below
// vacuous: when ZONE_STEP moved 1 -> 100 and MAX_LAYER 10000 -> 5000, "the top
// ore reaches the mine floor" went on comparing 209 against 209 and PASSED,
// because both sides came from the hardcoded table rather than the module.
//
// The dials are read live now, and what is asserted is the RELATIONSHIPS the
// design depends on, not four literals that have to be edited in two places
// every time the balance moves.
const dials = {};
for (const k of ["LAYERS_PER_RUNG", "ZONE_STEP", "ZONES", "MAX_LAYER"]) {
  dials[k] = num(brk, new RegExp("MineBreaking\\." + k + "\\s*=\\s*(\\d+)"), k);
}
const pow = num(brk, /MineBreaking\.ORE_POW\s*=\s*([\d.]+)/, "ORE_POW");
const LAYERS = 5000;   // MineConfig.LAYERS, the live mine floor

// MAX is derived, and the top ore must reach the mine floor exactly.
const MAX = 1 + (dials.ZONES - 1) * dials.ZONE_STEP
  + Math.floor((dials.MAX_LAYER - 1) / dials.LAYERS_PER_RUNG);
const oreStrength = (t, n) => 1 + Math.round(Math.pow((t - 1) / (n - 1), pow) * (MAX - 1));
const layerStrength = (zi, L) => Math.min(MAX,
  1 + (zi - 1) * dials.ZONE_STEP + Math.floor((L - 1) / dials.LAYERS_PER_RUNG));
const minTier = (need) => { for (let t = 1; t <= 82; t++) if (oreStrength(t, 82) >= need) return t; return null; };

ok("the top ore reaches the mine floor", oreStrength(82, 82) === MAX,
   `tier 82 -> ${oreStrength(82, 82)}, floor needs ${MAX}`);
ok("the first ore is the bottom rung", oreStrength(1, 82) === 1, String(oreStrength(1, 82)));

// The breaking scale must END where the game does. MAX_LAYER fed only this
// derivation and read 10000 while MineConfig.LAYERS exports 5000, so the ladder
// used to point a hundred rungs past anything a player can stand on.
ok("the scale ends at the live mine floor",
   dials.MAX_LAYER === LAYERS,
   `MAX_LAYER ${dials.MAX_LAYER} vs MineConfig.LAYERS ${LAYERS}`);
ok("the deepest normal block demands exactly the top ore",
   layerStrength(dials.ZONES, LAYERS) === MAX,
   `zone ${dials.ZONES} layer ${LAYERS} needs ${layerStrength(dials.ZONES, LAYERS)}, top ore gives ${MAX}`);

//[[ THE OWNER'S RULE, ASSERTED ]]
// 2026-10-05: "breaking power should make you need to get a new pick from next
// zone to come back to 501-1000 depth, and so on". That means the ladder has to
// be CONTINUOUS -- the tier that finishes a zone is the tier that opens the
// next. With ZONE_STEP at 1 this was wildly false: zone 1 demanded tier 57 of
// 82 and the remaining nine zones shared three tiers between them.
let worstGap = 0, worstAt = 0;
for (let zi = 1; zi < dials.ZONES; zi++) {
  const finish = minTier(layerStrength(zi, LAYERS));
  const next = minTier(layerStrength(zi + 1, 1));
  const gap = Math.abs((next ?? 82) - (finish ?? 82));
  if (gap > worstGap) { worstGap = gap; worstAt = zi; }
}
ok("finishing a zone is the same tier as entering the next",
   worstGap <= 1,
   worstGap === 0 ? "exact at every boundary"
     : `worst gap ${worstGap} tiers, at the zone ${worstAt} -> ${worstAt + 1} border`);

// And every zone must be worth a real slice of the roster, so no single zone
// swallows the ladder the way zone 1 did.
let thinnest = 82, thinnestZone = 0;
for (let zi = 1; zi <= dials.ZONES; zi++) {
  const span = (minTier(layerStrength(zi, LAYERS)) ?? 82) - (minTier(layerStrength(zi, 1)) ?? 1);
  if (span < thinnest) { thinnest = span; thinnestZone = zi; }
}
ok("no zone is a throwaway -- each spans several tiers",
   thinnest >= 4,
   `thinnest is zone ${thinnestZone} at ${thinnest} tiers`);

// A starter pick must not be able to walk into the mid game.
ok("a stone pick cannot reach layer 1000",
   layerStrength(1, 1000) > oreStrength(1, 82),
   `layer 1000 needs ${layerStrength(1, 1000)}, a tier-1 tool has ${oreStrength(1, 82)}`);

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
