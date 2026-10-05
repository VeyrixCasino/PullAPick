// Can you actually CLIMB the new breaking ladder?
//
// The ZONE_STEP change (1 -> 100) makes each mine demand about eight more ore
// tiers than the one above it. That is only a ladder if the ore you need is
// obtainable from where you already are. If the ore that opens zone N+1 only
// spawns inside zone N+1, the game deadlocks and nobody can leave zone 1.
//
// This reads the spawn curve; it never changes it. Owner's standing rule:
// never touch spawn chances.
//
//   oreDifficulty(zone, layer) = log(dirtHp / 20) / log(6)        -- "dl"
//   each ore sits at d = (tier-1) * ORE_DMAX / (ORE_COUNT-1)
//   x = d - dl
//   w = 1 / (1 + exp((x - X0) / K))            and for x < 0 it is additionally
//       multiplied by exp(x/S) * exp(-(x/W)^2)
//
// So ore AT or BELOW the local difficulty is common and ore above it falls off.
// The question is whether the falloff still leaves a usable share of the tiers
// you need, at the deepest rock your current tool can actually break.
//
// Run: node tools/verify/ladder-climbable.js
const path = require("path");
const { readSrc } = require("./_luau.js");
const ROOT = path.join(__dirname, "..", "..");
const cfg = readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau"));
const brk = readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineBreaking.luau"));
const dep = readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineDepth.luau"));

const n1 = (src, k, d) => {
  const g = new RegExp(k + "\\s*=\\s*(-?[0-9.eE+-]+)", "g");
  let v = null, m;
  while ((m = g.exec(src))) v = Number(m[1]);
  return v === null ? d : v;
};

let fails = 0, checks = 0;
const ok = (c, msg, detail) => {
  checks++;
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

// ---- dials ------------------------------------------------------------------
const NORE = 82;
const ZONE_STEP = n1(brk, "MineBreaking\\.ZONE_STEP", 100);
const ZONES = n1(brk, "MineBreaking\\.ZONES", 10);
const LPR = n1(brk, "MineBreaking\\.LAYERS_PER_RUNG", 50);
const MAX_LAYER = n1(brk, "MineBreaking\\.MAX_LAYER", 5000);
const ORE_POW = n1(brk, "MineBreaking\\.ORE_POW", 1);
const ORE_REACH = n1(brk, "MineBreaking\\.ORE_REACH", 15);
const MAXP = 1 + (ZONES - 1) * ZONE_STEP + Math.floor((MAX_LAYER - 1) / LPR);
const LAYERS = 5000;

const HP_BASE = n1(dep, "MineDepth\\.HP_BASE", 20);
const HP_PER = n1(dep, "MineDepth\\.HP_PER_LAYER", 1.5);
const ZMULT = n1(dep, "MineDepth\\.ZONE_HP_MULT", 5);
const dirtHp = (zi, L) => (HP_BASE + HP_PER * L) * Math.pow(ZMULT, zi - 1);

const X0 = n1(cfg, "MineConfig\\.ORE_X0", -4.2);
const K = n1(cfg, "MineConfig\\.ORE_K", 0.45);
const S = n1(cfg, "MineConfig\\.ORE_S", 4.0);
const W = n1(cfg, "MineConfig\\.ORE_W", 3.0);
const FLOOR = n1(cfg, "MineConfig\\.ORE_WEIGHT_FLOOR", 0);

// ORE_DMAX, exactly as MineConfig derives it NOW: off the LIVE depth curve,
// anchored to the deepest normal mine minus ORE_DMAX_MARGIN.
//
// It used to come off Depth.SECTIONS' last row (Terminus, 9.30735e+18) times 2
// times 6^9, which is the retired table -- that produced 32.09 against a deepest
// reachable difficulty of 11.39 and deadlocked the forge ladder at tier 8.
const LADDER_ZONES = n1(cfg, "MineConfig\.ORE_LADDER_ZONES", 10);
const DMAX_MARGIN = n1(cfg, "MineConfig\.ORE_DMAX_MARGIN", 0.4);
const deepHpForOre = dirtHp(LADDER_ZONES, LAYERS);
const ORE_DMAX = Math.max(1,
  Math.log(Math.max(20, deepHpForOre) / 20) / Math.log(6) - DMAX_MARGIN);
const dOf = (tier) => (tier - 1) * ORE_DMAX / (NORE - 1);

const clampInt = (v, lo, hi) => Math.max(lo, Math.min(hi, Math.round(v)));
const layerStrength = (zi, L) =>
  clampInt(1 + (zi - 1) * ZONE_STEP + Math.floor((L - 1) / LPR), 1, MAXP);
const oreStrength = (t) =>
  clampInt(1 + Math.floor(Math.pow((Math.max(1, t) - 1) / (NORE - 1), ORE_POW) * (MAXP - 1) + 0.5), 1, MAXP);

// Share of each ore tier at a spot, normalised. Read-only mirror of oreWeights.
function oreShares(zi, L) {
  const dl = Math.log(Math.max(20, dirtHp(zi, L)) / 20) / Math.log(6);
  const w = [];
  let tot = 0;
  for (let t = 1; t <= NORE; t++) {
    const x = dOf(t) - dl;
    let v = 1 / (1 + Math.exp((x - X0) / K));
    if (x < 0) v *= Math.exp(x / S) * Math.exp(-Math.pow(x / W, 2));
    if (v < FLOOR) v = FLOOR;   // MineConfig.ORE_WEIGHT_FLOOR
    w[t] = v;
    tot += v;
  }
  return { w, tot };
}

// The deepest rock a tier-t tool can break, searching every zone it can work in.
function deepestBreakable(t) {
  const P = oreStrength(t);
  let best = null;
  for (let zi = ZONES; zi >= 1; zi--) {
    for (let L = LAYERS; L >= 1; L--) {
      if (layerStrength(zi, L) <= P) { best = { zi, L }; break; }
    }
    if (best) break;
  }
  return best;
}

console.log("ladder-climbable: ZONE_STEP " + ZONE_STEP + ", ORE_POW " + ORE_POW +
  ", MAX " + MAXP + ", reach +" + ORE_REACH);
console.log("  ORE_DMAX " + ORE_DMAX.toFixed(3) + "  (ore d runs 0 -> " + ORE_DMAX.toFixed(1) + ")");
ok(Math.abs(ORE_DMAX - 10.9936) < 1e-3,
  "ORE_DMAX matches the live module", ORE_DMAX.toFixed(4) + " vs 10.9936 read from Studio");

//[[ THE D-LADDER IS CALIBRATED TO A CURVE THAT NO LONGER EXISTS ]]
// ORE_DMAX is derived from Depth.SECTIONS' last row (1.639e12) times 2 times
// 6^9. SECTIONS is the RETIRED HP table -- MineDepth.dirtHp does not read it and
// tops out at 14.7e9, about a thousand times lower. So ore d runs 0 -> 32.09
// while the deepest oreDifficulty a player can ever reach is 11.39.
//
// Everything above that coordinate is unreachable: the ore exists on the roster
// and no depth in the game ever rolls it.
const deepestDl = Math.log(Math.max(20, dirtHp(ZONES, LAYERS)) / 20) / Math.log(6);
const topReachableTier = Math.floor(deepestDl / (ORE_DMAX / (NORE - 1))) + 1;
console.log("  deepest oreDifficulty in the game: " + deepestDl.toFixed(3) +
  "  -> ore above tier " + topReachableTier + " sits past it\n");
ok(topReachableTier >= NORE,
  "every ore on the roster sits within reachable depth",
  "ore d reaches " + ORE_DMAX.toFixed(2) + " but depth only reaches " +
  deepestDl.toFixed(2) + " -- tiers " + (topReachableTier + 1) + "-" + NORE +
  " are unspawnable (" + (NORE - topReachableTier) + " of " + NORE + " ores)");

// ---- the walk ---------------------------------------------------------------
// Start with the starter tool and repeat: go as deep as your tool allows, see
// what ore is actually on offer there, forge the best of it you may break, and
// check that you got strictly stronger.
// 0.02% of ore rolls. At ORE_CHANCE 1/200 and 10 blocks/s that is one find
// per ~13 hours of solid mining -- rare, but a real drop rather than a rounding
// error. The old 0.5% floor was far too strict and made the top of the roster
// look unobtainable even when it was merely rare.
const MIN_SHARE = 0.0002;
let tier = 1;
const path_ = [1];
let stalledAt = null;
for (let step = 0; step < 60; step++) {
  const spot = deepestBreakable(tier);
  if (!spot) { stalledAt = tier; break; }
  const { w, tot } = oreShares(spot.zi, spot.L);
  // best ore here that this tool may break AND that actually drops
  let best = tier;
  for (let t = NORE; t > tier; t--) {
    if (t - ORE_REACH > tier) continue;              // outside the tool's reach
    if (oreStrength(Math.max(1, t - ORE_REACH)) > oreStrength(tier)) continue;
    if (w[t] / tot >= MIN_SHARE) { best = t; break; }
  }
  if (best <= tier) { stalledAt = tier; break; }
  tier = best;
  path_.push(tier);
  if (tier >= NORE) break;
}

console.log("THE FORGE WALK, starting from tier 1");
console.log("  " + path_.join(" -> "));
const end = deepestBreakable(tier);
console.log("  ends at tier " + tier + ", breaking rock down to zone " +
  (end ? end.zi : "-") + " layer " + (end ? end.L : "-") + "\n");

ok(tier >= NORE, "the walk reaches the top of the roster",
  "ended at tier " + tier + (stalledAt ? " (stalled)" : ""));
ok(end && end.zi >= ZONES && end.L >= LAYERS,
  "the final tool breaks the deepest normal rock",
  end ? "zone " + end.zi + " layer " + end.L : "nowhere");

// ---- per zone: is the ore that opens the NEXT zone reachable from this one? --
console.log("\nOPENING EACH ZONE -- is the ore you need on offer before you need it?");
console.log("  zone   needs ore   best ore on offer at your deepest reachable rock");
const minTier = (need) => { for (let t = 1; t <= NORE; t++) if (oreStrength(t) >= need) return t; return null; };
let deadlock = 0;
for (let zi = 1; zi < ZONES; zi++) {
  const needTier = minTier(layerStrength(zi + 1, 1));   // to open the next zone
  // the deepest rock you can break while still only holding the tier that
  // finishes THIS zone
  const holding = minTier(layerStrength(zi, LAYERS));
  // EVERY spot that tool can break, not just the deepest zone it can enter.
  // The richest ore within reach is usually the FLOOR of the zone below the
  // deepest one, because a zone's surface is poorer than the previous zone's
  // bottom -- scoring only the deepest zone reported deadlocks that are not
  // there, which is how this check disagreed with the forge walk above it.
  const P = oreStrength(holding);
  let best = 0, at = null;
  for (let z = 1; z <= ZONES; z++) {
    for (let L = LAYERS; L >= 1; L -= 50) {
      if (layerStrength(z, L) > P) continue;
      const { w, tot } = oreShares(z, L);
      for (let t = NORE; t > best; t--) {
        if (t - ORE_REACH > holding) continue;
        if (oreStrength(Math.max(1, t - ORE_REACH)) > P) continue;
        if (w[t] / tot >= MIN_SHARE) { best = t; at = { z, L }; break; }
      }
      break;   // the deepest layer reachable in this zone is its richest
    }
  }
  const good = best >= needTier;
  if (!good) deadlock++;
  console.log("  " + String(zi + 1).padEnd(7) + ("t" + needTier).padEnd(11) +
    "t" + best + " (holding t" + holding + ", at z" + (at ? at.z : "-") +
    " L" + (at ? at.L : "-") + ")" + (good ? "   ok" : "   <- DEADLOCK"));
}
ok(deadlock === 0, "no zone is locked behind ore that only spawns inside it",
  deadlock === 0 ? "every zone opens from the one before" : deadlock + " deadlocked");

// --- and the top of the roster must stay RARE --------------------------------
//
// Climbability pulls ORE_DMAX down; rarity pushes it up. This is the other end
// of that, and it is the one with history: on 2026-10-04 a smaller DMAX made
// Oganesson the commonest ore in the game at 31.7%, an exotic a minute. Owner,
// 2026-10-05, on a 21% Exotic band: "21% exotic is like 100-1000x rare" -- so
// the band belongs around 0.02-0.2% of ore rolls at the deepest spot.
const BANDS = [["Common", 1, 18], ["Uncommon", 19, 29], ["Rare", 30, 49],
  ["Epic", 50, 60], ["Legendary", 61, 69], ["Mythic", 70, 75],
  ["Divine", 76, 79], ["Exotic", 80, NORE]];
{
  const { w, tot } = oreShares(ZONES, LAYERS);
  let exotic = 0;
  for (let t = 80; t <= NORE; t++) exotic += w[t] / tot;
  ok(exotic <= 0.002,
    "the Exotic band stays rare at the deepest spot",
    (exotic * 100).toFixed(3) + "% of ore rolls (ceiling 0.2%)");
  ok(exotic >= 0.00002,
    "...but is still obtainable there",
    (exotic * 100).toFixed(3) + "% (floor 0.002%)");
  // EVERY rarity must be possible in EVERY zone. Owner, 2026-10-05: "every
  // rarity should be POSSIBLE in every zone, just super highly unlikely (even 1
  // in a million zone one)". Before ORE_WEIGHT_FLOOR the logistic put Oganesson
  // at 3e-11 in Dirt Meadow -- one find per 187,000 years, which is a wall
  // wearing a probability's clothes.
  let zeroAt = null, worstOdds = 0;
  for (let z = 1; z <= ZONES && zeroAt === null; z++) {
    const s = oreShares(z, LAYERS);
    for (let t = 1; t <= NORE; t++) {
      const share = s.w[t] / s.tot;
      if (!(share > 0)) { zeroAt = "zone " + z + " tier " + t; break; }
      if (1 / share > worstOdds) worstOdds = 1 / share;
    }
  }
  ok(zeroAt === null, "every ore can roll in every zone",
    zeroAt === null ? "longest odds anywhere: 1 in " +
      Math.round(worstOdds).toLocaleString("en-US") : "impossible at " + zeroAt);
  // ...and the longest odds should be a lottery, not a geological age.
  ok(worstOdds <= 5e6,
    "the longest odds are still a lottery ticket",
    "1 in " + Math.round(worstOdds).toLocaleString("en-US") + " (ceiling 1 in 5,000,000)");

  const ORE_CHANCE = 1 / 200, BPS = 10;
  const hrs = 1 / (ORE_CHANCE * (w[NORE] / tot)) / BPS / 3600;
  console.log("\n  share by band at the deepest spot:");
  for (const [nm, lo, hi] of BANDS) {
    let s = 0;
    for (let t = lo; t <= hi; t++) s += w[t] / tot;
    console.log("    " + nm.padEnd(11) + (s * 100).toFixed(2) + "%");
  }
  console.log("  top ore: one per " + hrs.toFixed(1) + " hours at " + BPS + " blocks/s");
}

console.log(fails === 0 ? "\n>>> ladder-climbable: all " + checks + " checks passed"
  : "\n>>> ladder-climbable: " + fails + " of " + checks + " FAILED");
process.exit(fails === 0 ? 0 : 1);
