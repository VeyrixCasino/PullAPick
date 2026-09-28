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
vm.runInContext("var __EXPORT;" + m[1].replace(/\}\)\(\);\s*$/,
  "__EXPORT={T:T,recycleBuysBack:recycleBuysBack,toolLevel:toolLevel,TYPES:TYPES," +
  "cumDust:cumDust,dustAt:dustAt,recycleAt:recycleAt,recRate:recRate,dmgAt:dmgAt};\n})();"), sb);
const X = sb.__EXPORT, T = X.T, TYPES = X.TYPES;

// closed form: top-n levels = p * cumDust(N)  =>  1 - g^-n = p
const predict = (p, g) => Math.log(1 / (1 - p)) / Math.log(g);

console.log("closed form  n = ln(1/(1-recPct)) / ln(dustGrow)");
console.log("prediction at defaults: " + predict(T.recPct, T.dustGrow).toFixed(1) + " levels\n");

console.log("observed, across wildly different tools (recDisp makes the RATE differ):");
console.log("tier".padEnd(6) + "type".padEnd(16) + "level".padEnd(8) +
            "rate".padEnd(8) + "re-buys");
for (const [t, k, L] of [[121, 15, 0], [121, 15, 5000], [100, 0, 500],
                          [60, 7, 0], [30, 3, 2000], [12, 9, 100]]) {
  console.log(String(t).padEnd(6) + TYPES[k][0].padEnd(16) +
    String(X.toolLevel(t, L, k)).padEnd(8) +
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

// the user's actual number
console.log("\n=== the case pasted: level 50, 6,344 dust ===");
console.log("damage at level 50: " + X.dmgAt(50).toFixed(0) +
  "  (dmgBase " + T.dmgBase + " x " + T.dmgStep + "^50)");
for (const mult of [1, 2, 4]) {
  const cm = mult;
  const c = T.dustBase * (Math.pow(T.dustGrow, 50) - 1) / (T.dustGrow - 1) * cm;
  console.log("  cumDust(50) at costMult " + cm + " = " + Math.ceil(c).toLocaleString("en-US"));
}
console.log("refund on that tool re-buys " + predict(T.recPct, T.dustGrow).toFixed(0) +
  " of its 50 levels = " + (predict(T.recPct, T.dustGrow) / 50 * 100).toFixed(0) + "% of the climb");
