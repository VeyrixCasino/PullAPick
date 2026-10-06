// Make the ZONE the gate, so each mine needs a pick forged in the one before.
//
// Owner, 2026-10-05: "breaking power should make you need to get a new pick from
// next zone to come back to 501-1000 depth, and so on".
//
// WHAT IS ACTUALLY WRONG (tools/depth-gate.js has the full measurement):
//
//   The stone pick is fine -- it caps at layer 50 and cannot see depth 1000.
//   Depth INSIDE a zone is gated hard: +1 power every 50 layers, so a full
//   5000-layer mine is +99.
//
//   The ZONE is not gated at all. ZONE_STEP is +1, so stepping from Dirt Meadow
//   to Event Horizon costs 10 power while HP multiplies by 9.77 MILLION. And
//   because one mine is worth +99 while a zone is worth +1, zone 1 alone demands
//   tier 57 of 82 -- an ore whose own home is zone 8 -- leaving zones 2..11 to
//   share three tiers.
//
// THE FIX, two constants:
//
//   ZONE_STEP  1 -> 100.  A zone is now worth exactly one mine's depth
//              (LAYERS / LAYERS_PER_RUNG = 5000/50 = 100), so finishing a zone
//              and entering the next cost the same, and the ladder is continuous
//              instead of front-loaded into zone 1.
//
//   ORE_POW    2.0 -> 1.0.  Quadratic made the bottom half of the roster worth
//              almost no breaking power, which is why tier 1-17 could not clear
//              even the first 500 layers. Linear spreads 82 tiers evenly over
//              the scale, which is what makes "about seven tiers per zone" fall
//              out instead of being tuned in.
//
// This file does NOT write anything. It models the change and checks the one
// thing that could make it unshippable: whether the ore you can actually reach
// in zone N is enough to enter zone N+1.
const NORE = 82, ORE_REACH = 15, LPR = 50, ZONES = 10, MAX_LAYER = 5000, LAYERS = 5000;
const HP_BASE = 20, HP_PER = 1.5, ZMULT = 5, ORE_HP_MULT = 3;
const clampInt = (v, lo, hi) => Math.max(lo, Math.min(hi, Math.round(v)));
const dirtHp = (zi, L) => (HP_BASE + HP_PER * L) * Math.pow(ZMULT, zi - 1);

function model(zoneStep, orePow) {
  const MAXP = 1 + (ZONES - 1) * zoneStep + Math.floor((MAX_LAYER - 1) / LPR);
  return {
    MAXP, zoneStep, orePow,
    layer: (zi, L) => clampInt(1 + (zi - 1) * zoneStep + Math.floor((L - 1) / LPR), 1, MAXP),
    ore: (t) => clampInt(
      1 + Math.floor(Math.pow((Math.max(1, t) - 1) / (NORE - 1), orePow) * (MAXP - 1) + 0.5), 1, MAXP),
  };
}
const minTier = (m, need) => { for (let t = 1; t <= NORE; t++) if (m.ore(t) >= need) return t; return null; };

const NOW = model(1, 2.0);
const NEW = model(100, 1.0);

const SUF = ["K", "M", "B", "T", "Qa"];
const big = (v) => {
  if (v < 1000) return String(Math.round(v));
  let s = 0;
  while (v >= 1000 && s < SUF.length) { v /= 1000; s++; }
  const dp = v >= 100 ? 1 : v >= 10 ? 2 : 3;
  return (Math.floor(v * Math.pow(10, dp)) / Math.pow(10, dp)).toFixed(dp) + SUF[s - 1];
};

console.log("scale tops out at " + NOW.MAXP + " now, " + NEW.MAXP + " after\n");

console.log("THE TIER YOU NEED TO ENTER EACH ZONE, AND TO FINISH IT");
console.log("  zone   enter (now -> after)     finish layer 5000 (now -> after)   dirt HP at floor");
for (let zi = 1; zi <= 11; zi++) {
  const eN = minTier(NOW, NOW.layer(zi, 1)), eA = minTier(NEW, NEW.layer(zi, 1));
  const fN = minTier(NOW, NOW.layer(zi, LAYERS)), fA = minTier(NEW, NEW.layer(zi, LAYERS));
  console.log("  " + String(zi).padEnd(7) +
    (("t" + eN) + " -> " + ("t" + (eA ?? "-"))).padEnd(25) +
    (("t" + fN) + " -> " + ("t" + (fA ?? "-"))).padEnd(35) +
    big(dirtHp(zi, LAYERS)));
}

console.log("\nIS THE LADDER CONTINUOUS? finishing zone N should be about entering N+1");
let broken = 0;
for (let zi = 1; zi < 11; zi++) {
  const finish = minTier(NEW, NEW.layer(zi, LAYERS));
  const next = minTier(NEW, NEW.layer(zi + 1, 1));
  const gap = (next ?? NORE) - (finish ?? NORE);
  if (gap > 2 || gap < -2) broken++;
  console.log("  finish zone " + String(zi).padEnd(3) + "t" + finish +
    "   enter zone " + String(zi + 1).padEnd(3) + "t" + next +
    "   gap " + (gap >= 0 ? "+" : "") + gap +
    (Math.abs(gap) <= 2 ? "   continuous" : "   <- JUMP"));
}

// ---- the feasibility question ----------------------------------------------
// You forge from ore you can reach. ORE_REACH lets a tier-T tool break ore up to
// T+15, so from a tier-T tool you can forge at most tier T+15 -- IF that ore
// spawns somewhere you can stand. Walk the chain from the starter and see how
// deep it actually gets.
console.log("\nCAN YOU ACTUALLY CLIMB IT? walking the forge chain from tier 1");
console.log("  Each step: your tool reaches ore 15 tiers up, you forge that, it");
console.log("  lets you stand deeper, which exposes more ore.");
for (const [name, m] of [["now", NOW], ["after", NEW]]) {
  let t = 1, steps = 0, seen = new Set();
  while (steps < 40) {
    // deepest layer/zone this tool can stand at
    let bestZone = 1, bestLayer = 0;
    for (let zi = 11; zi >= 1; zi--) {
      if (m.layer(zi, 1) <= m.ore(t)) {
        bestZone = zi;
        for (let L = LAYERS; L >= 1; L--) if (m.layer(zi, L) <= m.ore(t)) { bestLayer = L; break; }
        break;
      }
    }
    const next = Math.min(NORE, t + ORE_REACH);
    if (seen.has(t)) break;
    seen.add(t);
    if (next === t) break;
    t = next; steps++;
  }
  // how deep does the FINAL tool reach
  let fz = 1, fl = 0;
  for (let zi = 11; zi >= 1; zi--) {
    if (m.layer(zi, 1) <= m.ore(t)) {
      fz = zi;
      for (let L = LAYERS; L >= 1; L--) if (m.layer(zi, L) <= m.ore(t)) { fl = L; break; }
      break;
    }
  }
  console.log("  " + name.padEnd(7) + steps + " forges to reach tier " + t +
    ", which stands at zone " + fz + " layer " + fl +
    (fz >= 11 && fl >= LAYERS ? "   -> reaches the floor" : "   -> STOPS SHORT"));
}

console.log("\nWHAT A STONE PICK CAN DO, BEFORE AND AFTER");
for (const [name, m] of [["now", NOW], ["after", NEW]]) {
  let deep = 0;
  for (let L = LAYERS; L >= 1; L--) if (m.layer(1, L) <= m.ore(1)) { deep = L; break; }
  console.log("  " + name.padEnd(7) + "power " + m.ore(1) + ", deepest layer in zone 1: " + deep);
}
