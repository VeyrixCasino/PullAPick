// What a zap is WORTH, not just how far it can reach.
//
// procs.js asserts the worst case -- every hop lands -- and at 16 hops / 0.89
// that is 3.46 swings, up from 1.48. But the worst case is now deliberately
// rare (7.7% even at 250% zap), so the number that decides whether zap is
// balanced is the EXPECTED total, which is what a player actually averages.
const SHARE = 0.45;        // PROC_SHARE.zap
const HOPS = 16;
const FALL = Number(process.argv[2] || 0.89);

// P(hop n happens) = product of min(1, zap * FALL^k) for k = 0..n-2
function reach(zap, n) {
  let p = 1;
  for (let k = 0; k <= n - 2; k++) p *= Math.min(1, zap * Math.pow(FALL, k));
  return p;
}

console.log("zap stat   avg blocks   expected swings   worst case   P(all 16)");
for (const zap of [0.25, 0.5, 1.0, 1.5, 2.5, 4.0]) {
  let blocks = 0, dmg = 0;
  for (let n = 1; n <= HOPS; n++) {
    const p = reach(zap, n);
    blocks += p;
    // hop n deals SHARE * FALL^(n-1) of a swing, when it happens
    dmg += p * SHARE * Math.pow(FALL, n - 1);
  }
  let worst = 0;
  for (let n = 1; n <= HOPS; n++) worst += SHARE * Math.pow(FALL, n - 1);
  console.log(
    (Math.round(zap * 100) + "%").padEnd(11) +
    blocks.toFixed(2).padStart(10) +
    dmg.toFixed(2).padStart(18) +
    worst.toFixed(2).padStart(13) +
    (reach(zap, HOPS) * 100).toFixed(2).padStart(11) + "%");
}
console.log("");
console.log("for comparison, the other procs at their worst:");
console.log("  blast      0.35 x 6 faces      = 2.10 swings");
console.log("  ricochet   0.60 x 1 block      = 0.60 swings (plus its rerolls now)");
console.log("  quake      0.1 x 100 stacks /s = 10.0 swings a second at the cap");
