// The zap chain, modelled exactly as the server loop runs it.
//
// The loop in MineServer:
//
//     chance = startZap
//     for hop = 1, maxHops do
//         ...deal zapBase...
//         chance *= falloff
//         if rng >= chance then break end
//     end
//
// So hop 1 always lands once the chain has started, and the gate BEFORE hop n
// is chance = zap * falloff^(n-1). That makes
//
//     P(reach hop n) = product over k = 1..n-1 of min(1, zap * falloff^k)
//
// My first pass used k = 0..n-2, which is the same count of terms but starts a
// step too early -- it folds in min(1, zap), which is 1 for any zap >= 1, and
// drops the deepest decay. That is one missing falloff and it is optimistic:
// it put 250% zap at 7.7% to reach sixteen when the loop actually gives 3.4%.
const HOPS = 16;

function reach(zap, fall, n) {
  let p = 1;
  for (let k = 1; k <= n - 1; k++) p *= Math.min(1, zap * Math.pow(fall, k));
  return p;
}
function expected(zap, fall, share) {
  let t = 0;
  for (let n = 1; n <= HOPS; n++) t += reach(zap, fall, n) * share;
  return t;
}
function blocks(zap, fall) {
  let t = 0;
  for (let n = 1; n <= HOPS; n++) t += reach(zap, fall, n);
  return t;
}
function solve(zap, target) {
  let lo = 0.5, hi = 0.999;
  for (let i = 0; i < 300; i++) {
    const mid = (lo + hi) / 2;
    if (reach(zap, mid, HOPS) < target) lo = mid; else hi = mid;
  }
  return (lo + hi) / 2;
}

const SHARE = 0.25;
console.log("CORRECTED MODEL (gate before hop n is zap * fall^(n-1))\n");
console.log("shipped falloff 0.89, share 0.25:");
console.log("  zap      blocks   expected swings   P(all 16)");
for (const z of [0.5, 1.0, 1.5, 2.5, 4.0]) {
  console.log("  " + (Math.round(z * 100) + "%").padEnd(9) +
    blocks(z, 0.89).toFixed(2).padStart(7) +
    expected(z, 0.89, SHARE).toFixed(2).padStart(18) +
    (reach(z, 0.89, HOPS) * 100).toFixed(2).padStart(11) + "%");
}
const want = solve(2.5, 0.07);
console.log("\nto hit the owner's 7% at 250%, falloff = " + want.toFixed(4));
console.log("  zap      blocks   expected swings   P(all 16)");
for (const z of [1.0, 2.5, 4.0]) {
  console.log("  " + (Math.round(z * 100) + "%").padEnd(9) +
    blocks(z, want).toFixed(2).padStart(7) +
    expected(z, want, SHARE).toFixed(2).padStart(18) +
    (reach(z, want, HOPS) * 100).toFixed(2).padStart(11) + "%");
}
