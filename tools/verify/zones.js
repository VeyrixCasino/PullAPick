// Does the page's zone panel reproduce the LIVE game numbers?
const fs = require("fs"), vm = require("vm");
const html = fs.readFileSync(require("path").join(__dirname,"..","upgrade-calculator.html"),"utf8");
const m = html.match(/<script>([\s\S]*)<\/script>/);
const ctx2d = new Proxy({}, { get: (t, k) => k === "canvas" ? { width: 1000, height: 400 }
  : k === "measureText" ? (() => ({ width: 10 }))
  : k === "createLinearGradient" ? (() => ({ addColorStop() {} }))
  : k === "getImageData" ? (() => ({ data: [] })) : (() => {}), set: () => true });
function el(v) { return { textContent: "", innerHTML: "", value: v === undefined ? "" : v,
  style: {}, className: "", width: 1000, height: 400, children: [],
  getContext() { return ctx2d; },
  getBoundingClientRect() { return { left: 0, top: 0, width: 1000, height: 400 }; },
  appendChild(c) { this.children.push(c); return c; }, addEventListener() {},
  setAttribute() {}, getAttribute() { return null; }, querySelector() { return el(); },
  querySelectorAll() { return []; }, insertAdjacentHTML() {}, focus() {},
  classList: { add() {}, remove() {}, toggle() {} } }; }
const nodes = {};
const sb = { console, Math, Number, String, Object, Array, JSON, isFinite, parseFloat, parseInt,
  getComputedStyle() { return { getPropertyValue() { return "#888"; } }; }, devicePixelRatio: 1,
  document: { documentElement: el(), body: el(),
    getElementById(id) { return nodes[id] || (nodes[id] = el(id === "zLayer" ? "250" : "")); },
    createElement() { return el(); }, querySelector() { return el(); },
    querySelectorAll() { return []; }, addEventListener() {} },
  window: { addEventListener() {} }, requestAnimationFrame() {}, setTimeout() {} };
vm.createContext(sb);
vm.runInContext("var __EXPORT;" + m[1].replace(/\}\)\(\);\s*$/,
  "__EXPORT={T:T,zoneD:zoneD,zoneDirtHp:zoneDirtHp,oreShares:oreShares,dMeadow:dMeadow," +
  "ORES:ORES,ZONES:ZONES,oreDg:oreDg};\n})();"), sb);
const X = sb.__EXPORT;

let fails = 0;
const ok = (n, c, d) => { console.log((c ? "PASS  " : "FAIL  ") + n + (d ? "   " + d : "")); if (!c) fails++; };

//[[ dirt HP, re-probed off the LIVE module 2026-10-05 ]]
// The previous table was the RETIRED curve: it had Meadow layer 5000 at 3.3e12
// and zone 11 layer 5000 at 1.983e20. MineDepth.dirtHp gives 7,520 and 7.34e10
// for those -- the old numbers came from the SECTIONS staircase with a x6 zone
// step, which the module stopped reading. The page was checked against them and
// agreed, because the page ran the same retired model.
//
// Live: dirtHp(zone, layer) = (HP_BASE + HP_PER_LAYER * layer) * ZONE_HP_MULT^(zone-1)
// -- linear in layer, x5 a zone. Exact integers, so these are exact.
const HP = {
  // zone index -> { layer: hp }
  1: { 1: 22, 500: 770, 1000: 1520, 5000: 7520 },
  5: { 1: 13438, 500: 481250, 1000: 950000, 5000: 4700000 },
  10: { 1: 41992188, 500: 1503906250, 1000: 2968750000, 5000: 14687500000 },
  11: { 1: 209960938, 500: 7519531250, 1000: 14843750000, 5000: 73437500000 }
};
console.log("--- dirt HP vs live MineConfig.blockHp ---");
console.log("zone".padEnd(6) + "layer".padEnd(8) + "game".padEnd(13) + "page".padEnd(13) + "err");
let worstHp = 0, worstMeadow = 0;
for (const zi of Object.keys(HP)) {
  for (const L of Object.keys(HP[zi])) {
    const want = HP[zi][L], got = X.zoneDirtHp(+zi, +L);
    const err = Math.abs(got - want) / want;
    if (err > worstHp) worstHp = err;
    if (+zi === 1 && err > worstMeadow) worstMeadow = err;
    console.log(String(zi).padEnd(6) + String(L).padEnd(8) + want.toExponential(3).padEnd(13) +
      got.toExponential(3).padEnd(13) + (err * 100).toFixed(2) + "%");
  }
}
// the game snaps HP to clean numbers (MineAbbrev.ceil), so exact equality is not
// expected -- only that the page lands on the same value to within the snap.
// Meadow must be exact. Other zones are snapped by the game from the RAW value,
// while the page only has Meadow's already-snapped health to scale from, so they
// can sit one snap step off -- always inside the third significant digit.
ok("Meadow HP matches the game exactly", worstMeadow < 1e-9,
  "worst meadow error " + (worstMeadow * 100).toFixed(4) + "%");
ok("other zones within one snap step", worstHp < 0.01,
  "worst error " + (worstHp * 100).toFixed(2) + "% (one tenth-step is ~5%)");

// --- ore spread, straight off the Studio probe ---
//[[ ore spread, re-probed off the LIVE module 2026-10-05 ]]
// Also a snapshot of the retired curve: it had Meadow layer 1 at D 0.0 with a
// 44.8% top ore, and bigbang 5000 at D 24.41. Live D only reaches 11.39, because
// ORE_DMAX now comes off the depth curve instead of SECTIONS' 9.3e18 last row.
//
// bigbang (zone 11) is dropped for primordium (zone 10): Event Horizon is not on
// the ore-tool ladder -- "horizon is different... doesnt use normal tools" -- so
// the roster is calibrated to the deepest NORMAL mine and that is the spot worth
// pinning.
const SPREAD = [
  ["meadow", 1, 1, 0.05, 25.8, 10], ["meadow", 1, 500, 2.04, 20.0, 13],
  ["meadow", 1, 2500, 2.92, 17.5, 14], ["meadow", 1, 5000, 3.31, 16.0, 15],
  ["sunscar", 2, 1, 0.94, 22.7, 11], ["bloodmoon", 5, 1, 3.63, 14.3, 16],
  ["eclipse", 6, 1, 4.53, 8.2, 19], ["riftmarch", 7, 500, 7.43, 5.7, 32],
  ["primordium", 10, 1, 8.12, 5.7, 33], ["primordium", 10, 5000, 11.39, 5.7, 33]
];
console.log("\n--- ore spread vs live MineConfig.oreWeights ---");
console.log("zone".padEnd(12) + "layer".padEnd(7) + "D game/page".padEnd(16) +
            "top% game/page".padEnd(18) + "n95 game/page");
let dBad = 0, topBad = 0, nBad = 0;
for (const [name, zi, L, wantD, wantTop, wantN] of SPREAD) {
  const gotD = X.zoneD(zi, L), s = X.oreShares(zi, L);
  const gotTop = s.list[0].share * 100, gotN = s.n95;
  dBad = Math.max(dBad, Math.abs(gotD - wantD));
  topBad = Math.max(topBad, Math.abs(gotTop - wantTop));
  nBad = Math.max(nBad, Math.abs(gotN - wantN));
  console.log(name.padEnd(12) + String(L).padEnd(7) +
    (wantD.toFixed(2) + "/" + gotD.toFixed(2)).padEnd(16) +
    (wantTop.toFixed(1) + "/" + gotTop.toFixed(1)).padEnd(18) +
    wantN + "/" + gotN);
}
ok("difficulty D matches to display precision", dBad < 0.02, "worst " + dBad.toFixed(3));
ok("top-ore share matches", topBad < 0.6, "worst " + topBad.toFixed(2) + " points");
ok("ores-at-95% matches", nBad <= 1, "worst off by " + nBad);

// --- what the sliders can actually do about the smear ---
console.log("\n--- can S and W concentrate the spread? (Meadow L500, D 4.59) ---");
console.log("S".padEnd(6) + "W".padEnd(6) + "top ore".padEnd(10) + "2nd".padEnd(9) +
            "3rd".padEnd(9) + "n@95%");
for (const [S, W] of [[4, 3], [2, 1.5], [1.2, 1.0], [0.8, 0.6], [0.5, 0.4]]) {
  X.T.oreS = S; X.T.oreW = W;
  const s = X.oreShares(1, 500);
  console.log(String(S).padEnd(6) + String(W).padEnd(6) +
    (s.list[0].share * 100).toFixed(1).padEnd(10) +
    (s.list[1].share * 100).toFixed(1).padEnd(9) +
    (s.list[2].share * 100).toFixed(1).padEnd(9) + s.n95);
}
X.T.oreS = 4; X.T.oreW = 3;

console.log("\n" + (fails ? fails + " CHECK(S) FAILED" : "all checks passed"));
process.exit(fails ? 1 : 0);
