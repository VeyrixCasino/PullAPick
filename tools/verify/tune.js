// Which dial actually controls "too many ores"?
const fs = require("fs"), vm = require("vm");
const html = fs.readFileSync(require("path").join(__dirname,"..","upgrade-calculator.html"),"utf8");
const m = html.match(/<script>([\s\S]*)<\/script>/);
const ctx2d = new Proxy({}, { get: (t, k) => k === "canvas" ? { width: 1000, height: 400 }
  : k === "measureText" ? (() => ({ width: 10 }))
  : k === "createLinearGradient" ? (() => ({ addColorStop() {} }))
  : k === "getImageData" ? (() => ({ data: [] })) : (() => {}), set: () => true });
function el(v) { return { textContent: "", innerHTML: "", value: v || "", style: {}, className: "",
  width: 1000, height: 400, children: [], getContext() { return ctx2d; },
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
  "__EXPORT={T:T,oreShares:oreShares,zoneD:zoneD,ORES:ORES,ORE_SPACING:ORE_SPACING};\n})();"), sb);
const X = sb.__EXPORT, T = X.T;
const base = { X0: T.oreX0, K: T.oreK, S: T.oreS, W: T.oreW };
const reset = () => { T.oreX0 = base.X0; T.oreK = base.K; T.oreS = base.S; T.oreW = base.W; };

function line(zi, L) {
  const s = X.oreShares(zi, L);
  return { top: s.list[0].share * 100, second: s.list[1].share * 100,
           n95: s.n95, name: X.ORES[s.list[0].tier - 1] };
}
function row(label, zi, L) {
  const a = line(zi, L);
  return label.padEnd(14) + a.name.padEnd(13) + a.top.toFixed(1).padEnd(9) +
         a.second.toFixed(1).padEnd(9) + a.n95;
}
const hdr = "".padEnd(14) + "top ore".padEnd(13) + "share".padEnd(9) + "2nd".padEnd(9) + "n@95%";

console.log("Two regimes, two different dials.\n");
console.log("K decides how fast ores ABOVE your depth fall off  -> early game");
console.log("S,W decide how fast ores BELOW your depth fade out -> deep game");
console.log("ore tiers are " + X.ORE_SPACING + " D apart, so a dial of 0.27 == one tier\n");

console.log("=== K sweep, at the SURFACE (Meadow L1, D=0) ===");
console.log(hdr);
for (const K of [0.45, 0.30, 0.20, 0.116, 0.08]) {
  reset(); T.oreK = K;
  console.log(row("K=" + K.toFixed(3), 1, 1));
}
console.log("\n  ratio between neighbouring tiers = exp(0.2674 / K):");
for (const K of [0.45, 0.30, 0.20, 0.116, 0.08])
  console.log("    K=" + K.toFixed(3) + "  each tier is " +
    Math.exp(X.ORE_SPACING / K).toFixed(1) + "x rarer than the one above it");

console.log("\n=== same K sweep, DEEP (Meadow L2500, D=10.16) ===");
console.log(hdr);
for (const K of [0.45, 0.30, 0.20, 0.116, 0.08]) {
  reset(); T.oreK = K;
  console.log(row("K=" + K.toFixed(3), 1, 2500));
}
console.log("  -> K barely moves the deep smear. It is not the deep dial.");

console.log("\n=== S,W sweep, DEEP (Meadow L2500) ===");
console.log(hdr);
for (const [S, W] of [[4, 3], [2, 1.5], [1.2, 1.0], [0.8, 0.6], [0.5, 0.4], [0.35, 0.3]]) {
  reset(); T.oreS = S; T.oreW = W;
  console.log(row("S=" + S + " W=" + W, 1, 2500));
}

console.log("\n=== both together ===");
console.log(hdr);
for (const [K, S, W, tag] of [[0.45, 4, 3, "shipped"], [0.20, 1.0, 0.8, "moderate"],
                               [0.116, 0.6, 0.5, "tight"], [0.08, 0.4, 0.35, "very tight"]]) {
  reset(); T.oreK = K; T.oreS = S; T.oreW = W;
  console.log("-- " + tag + " (K=" + K + " S=" + S + " W=" + W + ")");
  console.log(row("  surface", 1, 1));
  console.log(row("  L500", 1, 500));
  console.log(row("  L2500", 1, 2500));
}
reset();
