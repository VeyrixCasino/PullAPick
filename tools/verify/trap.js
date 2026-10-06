// Is "levels re-bought" really independent of tier/type/level?
const fs = require("fs"), vm = require("vm");
const html = fs.readFileSync(require("path").join(__dirname,"..","upgrade-calculator.html"),"utf8");
const m = html.match(/<script>([\s\S]*)<\/script>/);
const ctx2d = new Proxy({}, { get: (t, k) => k === "canvas" ? { width: 800, height: 400 }
  : k === "measureText" ? (() => ({ width: 10 }))
  : k === "createLinearGradient" ? (() => ({ addColorStop() {} }))
  : k === "getImageData" ? (() => ({ data: [] })) : (() => {}), set: () => true });
function el() { return { textContent: "", innerHTML: "", value: "", style: {}, className: "",
  width: 800, height: 400, children: [], getContext() { return ctx2d; },
  getBoundingClientRect() { return { left: 0, top: 0, width: 800, height: 400 }; },
  appendChild(c) { this.children.push(c); return c; }, addEventListener() {},
  setAttribute() {}, getAttribute() { return null; }, querySelector() { return el(); },
  querySelectorAll() { return []; }, insertAdjacentHTML() {}, focus() {},
  classList: { add() {}, remove() {}, toggle() {} } }; }
const sb = { console, Math, Number, String, Object, Array, JSON, isFinite, parseFloat, parseInt,
  getComputedStyle() { return { getPropertyValue() { return "#888"; } }; }, devicePixelRatio: 1,
  document: { documentElement: el(), body: el(), getElementById() { return el(); },
    createElement() { return el(); }, querySelector() { return el(); },
    querySelectorAll() { return []; }, addEventListener() {} },
  window: { addEventListener() {} }, requestAnimationFrame() {}, setTimeout() {} };
vm.createContext(sb);
//[[ toolLevel is GONE, and this file crashed on it ]]
// The export list asked the calculator for `toolLevel`, which no longer exists
// -- a tool's level IS its upgrade level now, where it used to be derived from
// tier ("a tier-121 pick is BORN at level 700"). Luau is forgiving about unknown
// globals; this vm context is not, so the whole file threw a ReferenceError
// before a single assertion ran. It has been counted as a "known failure" ever
// since, which is how a crash gets mistaken for a red test.
vm.runInContext("var __EXPORT;" + m[1].replace(/\}\)\(\);\s*$/,
  "__EXPORT={T:T,recycleBuysBack:recycleBuysBack,TYPES:TYPES,ORES:ORES,MAXLVL:MAXLVL," +
  "cumDust:cumDust,dustAt:dustAt,recycleAt:recycleAt,recRate:recRate,dmgAt:dmgAt};\n})();"), sb);
const X = sb.__EXPORT, T = X.T, TYPES = X.TYPES;
// Derived from the page, never restated -- the same rule check.js follows. This
// file used to probe tier 121 and level 5000, from the 121-ore roster and the
// 1000-level cap, and would have gone on "passing" against tiers and levels the
// game no longer has.
const TOP = X.ORES.length, CAP = X.MAXLVL;

// closed form: top-n levels = p * cumDust(N)  =>  1 - g^-n = p
const predict = (p, g) => Math.log(1 / (1 - p)) / Math.log(g);

console.log("closed form  n = ln(1/(1-recPct)) / ln(dustGrow)");
console.log("prediction at defaults: " + predict(T.recPct, T.dustGrow).toFixed(1) + " levels\n");

console.log("observed, across wildly different tools (recDisp makes the RATE differ):");
console.log("tier".padEnd(6) + "type".padEnd(16) + "level".padEnd(8) +
            "rate".padEnd(8) + "re-buys");
const mid = Math.max(1, Math.round(CAP / 2));
for (const [t, k, L] of [[TOP, TYPES.length - 1, 1], [TOP, TYPES.length - 1, CAP],
                         [Math.round(TOP * 0.75), 0, mid],
                         [Math.round(TOP * 0.5), 7, 1],
                         [Math.round(TOP * 0.3), 3, CAP],
                         [Math.max(1, Math.round(TOP * 0.12)), 9, mid]]) {
  console.log(String(t).padEnd(6) + TYPES[k][0].padEnd(16) +
    String(L).padEnd(8) +
    (X.recRate(t, L, k) * 100).toFixed(0).padEnd(8) +
    X.recycleBuysBack(t, L, k));
}
console.log("\n-> the LEVELS re-bought barely move; only recPct and dustGrow set them.");
console.log("   (small spread is the tier falloff cutting the rate, plus rounding)\n");

console.log("=== the trap, as a dial ===");
console.log("how many levels the refund re-buys:\n");
const ps = [0.15, 0.25, 0.4, 0.6, 0.8];
const gs = [1.004, 1.008, 1.011, 1.016, 1.022];
console.log("          " + gs.map(g => ("+" + ((g - 1) * 100).toFixed(1) + "%/lvl").padStart(11)).join(""));
for (const p of ps) {
  let row = ("recPct " + (p * 100).toFixed(0) + "%").padEnd(10);
  for (const g of gs) row += predict(p, g).toFixed(0).padStart(11);
  console.log(row);
}
console.log("\nrows = refund share, cols = dust cost growth per level");

//[[ worked example, against the LIVE cap ]]
// This used to be "the case pasted: level 50, 6,344 dust" -- a one-off from the
// 1000-level era, calling X.dmgAt(50) with ONE argument when dmgAt takes
// (L, tier, typeIndex). TYPES[undefined][4] threw, so even once the export list
// was fixed this file still died before finishing. Anchored to the cap now, so
// the example is always a tool the game can actually produce.
console.log("\n=== a worked example at the cap ===");
const exTier = Math.round(TOP * 0.5), exType = 0;
console.log("tier " + exTier + " " + TYPES[exType][0] + " at level " + CAP + ": damage " +
  X.dmgAt(CAP, exTier, exType).toFixed(0) +
  "  (dmgBase " + T.dmgBase + " x " + T.dmgStep.toFixed(4) + "^" + (CAP - 1) + ")");
for (const cm of [1, 2, 4]) {
  const c = T.dustBase * (Math.pow(T.dustGrow, CAP) - 1) / (T.dustGrow - 1) * cm;
  console.log("  cumDust(" + CAP + ") at costMult " + cm + " = " +
    Math.ceil(c).toLocaleString("en-US"));
}
const rebought = predict(T.recPct, T.dustGrow);
console.log("refund on that tool re-buys " + rebought.toFixed(1) +
  " of its " + CAP + " levels = " + (rebought / CAP * 100).toFixed(0) + "% of the climb");
