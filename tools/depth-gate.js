// Does breaking power actually force a new pick as you go deeper?
//
// Owner, 2026-10-05: "if i can take my stone pick and go to 1000 depth then
// thats an issue.. that why i said breaking power should make you need to get a
// new pick from next zone to come back to 501-1000 depth, and so on".
//
// Measured, not assumed. Two separate questions, and they have different
// answers:
//
//   WITHIN a zone, does depth demand a better pick?   layerStrength adds
//     +1 every LAYERS_PER_RUNG layers, so 500 layers is +10 power.
//
//   ACROSS zones, does the next zone demand a better pick?   ZONE_STEP is +1
//     per zone, while MineDepth multiplies HP by ZONE_HP_MULT = 5 per zone.
//     One is additive and the other multiplicative, which is the thing worth
//     checking.
const NORE = 82, ORE_REACH = 15;
const LPR = 50, ZONE_STEP = 1, ZONES = 10, MAX_LAYER = 10000, ORE_POW = 2.0;
const HP_BASE = 20, HP_PER = 1.5, ZMULT = 5, ORE_HP_MULT = 3;
const MAXP = 1 + (ZONES - 1) * ZONE_STEP + Math.floor((MAX_LAYER - 1) / LPR);
const clampInt = (v, lo, hi) => Math.max(lo, Math.min(hi, Math.round(v)));

const layerStrength = (zi, L) =>
  clampInt(1 + (zi - 1) * ZONE_STEP + Math.floor((L - 1) / LPR), 1, MAXP);
const oreStrength = (t) =>
  clampInt(1 + Math.floor(Math.pow((Math.max(1, t) - 1) / (NORE - 1), ORE_POW) * (MAXP - 1) + 0.5), 1, MAXP);
const dirtHp = (zi, L) => (HP_BASE + HP_PER * L) * Math.pow(ZMULT, zi - 1);

// Lowest ore tier whose forged tool has at least this much breaking power.
function minTier(need) {
  for (let t = 1; t <= NORE; t++) if (oreStrength(t) >= need) return t;
  return null;
}
// Deepest layer a tool forged from tier t may stand at, in a given zone.
function deepestLayer(t, zi) {
  const P = oreStrength(t);
  for (let L = MAX_LAYER; L >= 1; L--) if (layerStrength(zi, L) <= P) return L;
  return 0;
}

const SUF = ["K", "M", "B", "T", "Qa"];
const big = (v) => {
  if (v < 1000) return String(Math.round(v));
  let s = 0;
  while (v >= 1000 && s < SUF.length) { v /= 1000; s++; }
  const dp = v >= 100 ? 1 : v >= 10 ? 2 : 3;
  return (Math.floor(v * Math.pow(10, dp)) / Math.pow(10, dp)).toFixed(dp) + SUF[s - 1];
};

console.log("THE STONE PICK. Tier 1, breaking power " + oreStrength(1) + ".");
console.log("  deepest layer it may stand at in zone 1: " + deepestLayer(1, 1));
console.log("  (layer 1000 in zone 1 demands power " + layerStrength(1, 1000) + ")");
console.log("  -> a stone pick " +
  (deepestLayer(1, 1) >= 1000 ? "CAN reach depth 1000. The gate is broken."
    : "CANNOT reach depth 1000. The gate holds."));

console.log("\nWITHIN ZONE 1 -- what each 500-layer band demands");
console.log("  layers        power   min ore tier   that ore reaches   dirt HP there");
for (let lo = 1; lo <= 5000; lo += 500) {
  const hi = lo + 499;
  const need = layerStrength(1, hi);
  const t = minTier(need);
  console.log("  " + (lo + "-" + hi).padEnd(14) +
    String(need).padEnd(8) +
    ("tier " + (t ?? "-")).padEnd(15) +
    ("ore " + (t ? Math.min(NORE, t + ORE_REACH) : "-")).padEnd(19) +
    big(dirtHp(1, hi)));
}

console.log("\nACROSS ZONES -- the SAME layer, zone by zone");
console.log("  zone   power at layer 2500   min ore tier   dirt HP        HP vs zone 1");
const base = dirtHp(1, 2500);
for (let zi = 1; zi <= 11; zi++) {
  const need = layerStrength(zi, 2500);
  const t = minTier(need);
  const hp = dirtHp(zi, 2500);
  console.log("  " + String(zi).padEnd(7) + String(need).padEnd(21) +
    ("tier " + (t ?? "-")).padEnd(15) + big(hp).padEnd(15) +
    "x" + big(hp / base));
}

console.log("\nTHE MISMATCH, STATED");
console.log("  Going from zone 1 to zone 10 multiplies HP by x" + big(Math.pow(ZMULT, 9)) +
  " and adds " + ((ZONES - 1) * ZONE_STEP) + " to the power needed.");
console.log("  Going 500 layers deeper multiplies HP by about x" +
  (dirtHp(1, 2500) / dirtHp(1, 2000)).toFixed(2) + " and adds " +
  (layerStrength(1, 2500) - layerStrength(1, 2000)) + ".");
console.log("  So DEPTH inside a zone is gated hard and ZONE is barely gated at all:");
console.log("  the zone jump is where the HP lives and where the gate is weakest.");

console.log("\nWHO CAN STAND AT THE BOTTOM OF EACH ZONE (layer 5000)");
console.log("  zone   power   min ore tier   but that ore's own HOME is zone...");
for (let zi = 1; zi <= 11; zi++) {
  const need = layerStrength(zi, 5000);
  const t = minTier(need);
  // where that ore actually spawns, by the same 11-zone map used elsewhere
  const homeZone = t ? Math.min(11, Math.floor(((t - 1) / (NORE - 1)) * (11 * 5000) / 5000) + 1) : "-";
  console.log("  " + String(zi).padEnd(7) + String(need).padEnd(8) +
    ("tier " + (t ?? "-")).padEnd(15) + homeZone);
}
