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

// ORE_DMAX, exactly as MineConfig derives it (off the SECTIONS table's last row).
//
// The first version of this matched /dirtHp = (\d+)/ over the whole MineDepth
// file and took the last hit, which is NOT the last SECTIONS row -- it landed on
// a small number elsewhere and produced ORE_DMAX 8.941 against the real 32.092.
// Every conclusion drawn from that was wrong. Anchored to the SECTIONS block
// only, and asserted against the live value below.
// Taking the LARGEST dirtHp in the file rather than "the last one": the
// SECTIONS table is a staircase so its final row is its maximum, and a
// non-greedy block match stops at the first inner "}" and truncates the table.
// ([0-9.eE+-]+), not (\d+): the last section is written `dirtHp = 9.30735e+18`
// and \d+ captured just the "9", which silently made ORE_DMAX 23.41 instead of
// 32.09 and inverted every conclusion drawn from it.
const secs = [...dep.matchAll(/dirtHp = ([0-9.eE+-]+)/g)].map((m) => Number(m[1]));
const topDirt = secs.length ? Math.max(...secs) : 1639071525950;
const ORE_DMAX = Math.log((topDirt * 2 * Math.pow(6, 9)) / 20) / Math.log(6);
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
ok(Math.abs(ORE_DMAX - 32.0916881992669) < 1e-6,
  "ORE_DMAX matches the live module", ORE_DMAX.toFixed(6) + " vs 32.091688 read from Studio");

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
const MIN_SHARE = 0.005;   // an ore worth 0.5% of rolls is obtainable in practice
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
  const spot = deepestBreakable(holding);
  const { w, tot } = oreShares(spot.zi, spot.L);
  let best = 0;
  for (let t = NORE; t >= 1; t--) {
    if (t - ORE_REACH > holding) continue;
    if (w[t] / tot >= MIN_SHARE) { best = t; break; }
  }
  const good = best >= needTier;
  if (!good) deadlock++;
  console.log("  " + String(zi + 1).padEnd(7) + ("t" + needTier).padEnd(11) +
    "t" + best + " (holding t" + holding + ", at z" + spot.zi + " L" + spot.L + ")" +
    (good ? "   ok" : "   <- DEADLOCK"));
}
ok(deadlock === 0, "no zone is locked behind ore that only spawns inside it",
  deadlock === 0 ? "every zone opens from the one before" : deadlock + " deadlocked");

console.log(fails === 0 ? "\n>>> ladder-climbable: all " + checks + " checks passed"
  : "\n>>> ladder-climbable: " + fails + " of " + checks + " FAILED");
process.exit(fails === 0 ? 0 : 1);
