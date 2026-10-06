// Recut the ore drop tables. Owner, 2026-10-05: "we also have to remake ore drop
// tables, now that only certian ores arent aloud after cetrian depths, they
// shouldnt appear as often".
//
// MODELS ONLY. Writes nothing. The last time ORE_DMAX moved without this kind of
// sheet in front of it, Oganesson became the commonest ore in the game at 31.7%
// -- an exotic a minute -- so every candidate here is scored on how often the
// top of the roster actually drops, not just on whether it is reachable.
//
// THE BUG. ORE_DMAX is derived from Depth.SECTIONS' LAST row:
//
//     ORE_DMAX = log((top.dirtHp * 2 * 6^9) / 20) / log(6)
//
// That row is Terminus, 9.30735e+18. SECTIONS is the RETIRED HP table --
// MineDepth.dirtHp does not read it and tops out at 14,687,500,000. So the ore
// d-ladder runs 0 -> 32.09 while the deepest oreDifficulty a player can reach is
// 11.39, and tiers 27-82 never roll anywhere.
//
// The question is not "what makes them reachable" -- almost any smaller DMAX
// does. It is where to put the TOP of the ladder relative to the deepest spot,
// because the weight curve peaks about 4.2 d-units BELOW local difficulty
// (ORE_X0), not at it.
const fs = require("fs"), path = require("path");
const read = (p) => fs.readFileSync(path.join(__dirname, "..", p), "utf8").split("\r\n").join("\n");
const cfg = read("src/ReplicatedStorage/Mine/Shared/MineConfig.luau");
const dep = read("src/ReplicatedStorage/Mine/Shared/MineDepth.luau");
const num = (src, k, d) => {
  const g = new RegExp(k + "\\s*=\\s*(-?[0-9.eE+-]+)", "g");
  let v = null, m;
  while ((m = g.exec(src))) v = Number(m[1]);
  return v === null ? d : v;
};

const NORE = 82;
const X0 = num(cfg, "MineConfig\\.ORE_X0", -4.2);
const K = num(cfg, "MineConfig\\.ORE_K", 0.45);
const S = num(cfg, "MineConfig\\.ORE_S", 4.0);
const W = num(cfg, "MineConfig\\.ORE_W", 3.0);
const ORE_CHANCE = 1 / 200;              // MineConfig.ORE_CHANCE
const HP_BASE = num(dep, "MineDepth\\.HP_BASE", 20);
const HP_PER = num(dep, "MineDepth\\.HP_PER_LAYER", 1.5);
const ZMULT = num(dep, "MineDepth\\.ZONE_HP_MULT", 5);
const dirtHp = (z, L) => (HP_BASE + HP_PER * L) * Math.pow(ZMULT, z - 1);
const dl = (z, L) => Math.log(Math.max(20, dirtHp(z, L))) / Math.log(6) - Math.log(20) / Math.log(6);

// live DMAX, off the retired SECTIONS top
const secHp = [...dep.matchAll(/dirtHp = ([0-9.eE+-]+)/g)].map((m) => Number(m[1]));
const LIVE_DMAX = Math.log((Math.max(...secHp) * 2 * Math.pow(6, 9)) / 20) / Math.log(6);

// Ore names, for saying which ore we are talking about.
const NAMES = cfg.match(/MineConfig\.ORES = \{([\s\S]*?)\n\}/)[1]
  .split("\n").filter((l) => /\{\s*id = "/.test(l))
  .map((l) => (l.match(/name = "([^"]+)"/) || [])[1]);

// The weight curve, exactly as MineConfig.oreWeights computes it.
function shares(DMAX, z, L) {
  const d0 = dl(z, L);
  const w = [];
  let tot = 0;
  for (let t = 1; t <= NORE; t++) {
    const x = (t - 1) * DMAX / (NORE - 1) - d0;
    let v = 1 / (1 + Math.exp((x - X0) / K));
    if (x < 0) v *= Math.exp(x / S) * Math.exp(-Math.pow(x / W, 2));
    w[t] = v;
    tot += v;
  }
  return w.map((v) => (tot > 0 ? v / tot : 0));
}

// How long to find ONE of a given tier, at 10 blocks/s, at a spot.
const BPS = 10;
function minutesFor(share) {
  if (share <= 0) return Infinity;
  const perBlock = ORE_CHANCE * share;
  return 1 / perBlock / BPS / 60;
}

const DEEP = [10, 5000];
const deepestDl = dl(DEEP[0], DEEP[1]);

console.log("ORE_X0 " + X0 + "  ORE_K " + K + "  ORE_S " + S + "  ORE_W " + W);
console.log("deepest oreDifficulty in the game: " + deepestDl.toFixed(3) +
  "   (zone " + DEEP[0] + " layer " + DEEP[1] + ")");
console.log("live ORE_DMAX: " + LIVE_DMAX.toFixed(3) + "  <- derived from the RETIRED SECTIONS top\n");

// Where does the weight curve actually peak, relative to local difficulty?
let peakX = 0, peakV = 0;
for (let x = -12; x <= 2; x += 0.01) {
  let v = 1 / (1 + Math.exp((x - X0) / K));
  if (x < 0) v *= Math.exp(x / S) * Math.exp(-Math.pow(x / W, 2));
  if (v > peakV) { peakV = v; peakX = x; }
}
console.log("the weight curve peaks at x = " + peakX.toFixed(2) +
  " d-units below local difficulty, so the ore you MOSTLY pull");
console.log("sits that far under the rock you are standing in.\n");

console.log("CANDIDATES. 'top share' is Oganesson's share of ore rolls at the");
console.log("deepest spot; 'one in' is minutes to find one there at 10 blocks/s.\n");
console.log("ORE_DMAX  peak tier at depth   top-tier share   one in      t82 reachable?");

const cands = [
  ["live (broken)", LIVE_DMAX],
  ["deepest dl", deepestDl],
  ["dl + |X0|", deepestDl + Math.abs(X0)],
  ["dl - 2", deepestDl - 2],
  ["dl - |X0| (t82 peaks)", deepestDl + peakX],
];
for (const [label, DMAX] of cands) {
  if (DMAX <= 0) continue;
  const sh = shares(DMAX, DEEP[0], DEEP[1]);
  let peak = 1;
  for (let t = 2; t <= NORE; t++) if (sh[t] > sh[peak]) peak = t;
  const top = sh[NORE];
  const mins = minutesFor(top);
  console.log("  " + DMAX.toFixed(2).padEnd(10) +
    ("t" + peak + " " + (NAMES[peak - 1] || "")).padEnd(20) +
    ((top * 100).toFixed(2) + "%").padEnd(17) +
    (mins === Infinity ? "never" : mins < 60 ? mins.toFixed(1) + " min"
      : (mins / 60).toFixed(1) + " hr").padEnd(12) +
    (top >= 0.0005 ? "yes" : "NO") + "   " + label);
}

// ---- the chosen shape, zone by zone -----------------------------------------
const PICK = deepestDl + Math.abs(X0) === 0 ? deepestDl : null;
function sheet(DMAX, label) {
  console.log("\n\n=== " + label + "  (ORE_DMAX " + DMAX.toFixed(3) + ") ===");
  console.log("zone   dl      peak ore            highest >=0.5%      t82 share   t82 one in");
  for (let z = 1; z <= 10; z++) {
    const sh = shares(DMAX, z, 5000);
    let peak = 1, hi = 1;
    for (let t = 1; t <= NORE; t++) {
      if (sh[t] > sh[peak]) peak = t;
      if (sh[t] >= 0.005) hi = t;
    }
    const mins = minutesFor(sh[NORE]);
    console.log("  " + String(z).padEnd(7) + dl(z, 5000).toFixed(2).padEnd(8) +
      ("t" + peak + " " + (NAMES[peak - 1] || "")).padEnd(20) +
      ("t" + hi + " " + (NAMES[hi - 1] || "")).padEnd(20) +
      ((sh[NORE] * 100).toFixed(3) + "%").padEnd(12) +
      (mins === Infinity ? "never" : mins < 60 ? mins.toFixed(0) + " min"
        : mins < 1440 ? (mins / 60).toFixed(1) + " hr" : (mins / 1440).toFixed(1) + " d"));
  }
  // Rarity-band shares at the deepest spot -- the thing that went wrong before.
  const sh = shares(DMAX, DEEP[0], DEEP[1]);
  const BANDS = [["Common", 1, 18], ["Uncommon", 19, 29], ["Rare", 30, 49],
    ["Epic", 50, 60], ["Legendary", 61, 69], ["Mythic", 70, 75],
    ["Divine", 76, 79], ["Exotic", 80, 82]];
  console.log("\n  at the deepest spot, share by rarity band:");
  for (const [nm, lo, hi2] of BANDS) {
    let s = 0;
    for (let t = lo; t <= hi2; t++) s += sh[t];
    console.log("    " + nm.padEnd(11) + (s * 100).toFixed(2) + "%" +
      (nm === "Exotic" && s > 0.15 ? "   <- TOO COMMON, this is the 2026-10-04 mistake" : ""));
  }
}

sheet(deepestDl + peakX, "A  top ore PEAKS at the deepest spot");
sheet(deepestDl, "B  top ore sits AT the deepest difficulty");
sheet(deepestDl + Math.abs(X0), "C  top ore sits |X0| ABOVE it (rarest)");
