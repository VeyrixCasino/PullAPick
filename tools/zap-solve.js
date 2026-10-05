// Find the ZAP_FALLOFF that makes 250% zap "borderline" over 16 hops.
//
// The loop is: chance starts at the player's zap stat, each hop multiplies it by
// falloff, and the chain continues while rng < chance. A chance above 1 is a
// guaranteed hop, so a big zap stat buys certainty on the EARLY hops and the
// falloff decides where it stops being certain.
//
//   P(reach all N) = product over k=0..N-2 of min(1, zap * falloff^k)
//
// Owner: "max 16, and even at 250% only about a 7% chance it goes all 16."
const HOPS = 16;

function pAll(zap, f, hops) {
  let p = 1;
  for (let k = 0; k <= hops - 2; k++) {
    p *= Math.min(1, zap * Math.pow(f, k));
  }
  return p;
}

// Solve falloff for a target probability at 250%, by bisection.
function solve(zap, hops, target) {
  let lo = 0.5, hi = 0.999;
  for (let i = 0; i < 200; i++) {
    const mid = (lo + hi) / 2;
    if (pAll(zap, mid, hops) < target) lo = mid; else hi = mid;
  }
  return (lo + hi) / 2;
}

const f = solve(2.5, HOPS, 0.07);
console.log("to put 250% zap at 7% over " + HOPS + " hops, falloff = " + f.toFixed(4));
console.log("");
console.log("falloff   zap 50%    zap 100%   zap 150%   zap 250%   zap 400%");
for (const cand of [0.75, 0.85, 0.88, 0.90, Number(f.toFixed(2)), 0.92]) {
  const row = [0.5, 1.0, 1.5, 2.5, 4.0]
    .map((z) => (pAll(z, cand, HOPS) * 100).toFixed(4).padStart(10))
    .join("");
  console.log(String(cand).padEnd(10) + row);
}
console.log("");
console.log("expected hops at the chosen falloff (" + f.toFixed(2) + "):");
for (const z of [0.25, 0.5, 1.0, 1.5, 2.5, 4.0]) {
  let exp = 0;
  for (let n = 1; n <= HOPS; n++) exp += pAll(z, Number(f.toFixed(2)), n + 1);
  console.log("  zap " + String(Math.round(z * 100) + "%").padEnd(6) +
    " reaches " + (1 + exp).toFixed(2) + " blocks on average, " +
    (pAll(z, Number(f.toFixed(2)), HOPS) * 100).toFixed(3) + "% go the full 16");
}
