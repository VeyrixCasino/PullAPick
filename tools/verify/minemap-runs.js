// The mine map page has to actually RUN, not just parse.
//
// node --check only proves the script is syntactically valid. The first build
// shipped a page where every readout stayed on its placeholder dash and the
// zone dropdown was empty, because render() threw on the first call and nothing
// said so. A page that silently renders nothing looks identical to a page that
// has not loaded.
//
// So: stub enough DOM to execute the script for real, let any throw escape, and
// assert the page actually wrote values into its own elements.
//
//   node tools/verify/minemap-runs.js
const fs = require("fs");
const vm = require("vm");
const path = require("path");

const ROOT = path.resolve(__dirname, "../..");
const PAGE = path.join(ROOT, "tools/mine-map.html");
if (!fs.existsSync(PAGE)) {
  console.error("FAIL tools/mine-map.html missing - run node tools/gen-mine-map.js");
  process.exit(1);
}
const html = fs.readFileSync(PAGE, "utf8");
const m = html.match(/<script>([\s\S]*?)<\/script>/);
if (!m) {
  console.error("FAIL no script block in the page");
  process.exit(1);
}

// A canvas 2d context that accepts everything and returns something harmless.
const ctx2d = new Proxy({}, {
  get: (t, k) => (k === "canvas" ? { width: 900, height: 300 }
    : k === "measureText" ? () => ({ width: 10 })
    : k === "createLinearGradient" ? () => ({ addColorStop() {} })
    : () => {}),
  set: () => true,
});

//[[ Seed each element's value from the HTML, the way a browser does.
//
// Without this the stub hands every slider value="" -> 0, three readouts come
// back 0, and the check reports a failure the page does not have. A harness
// that invents failures gets ignored exactly as fast as one that invents passes.
const INITIAL = {};
const tagRe = /<(input|select)\b[^>]*\bid="([a-z0-9_]+)"[^>]*>/gi;
let tag;
while ((tag = tagRe.exec(html))) {
  const v = tag[0].match(/\bvalue="([^"]*)"/i);
  if (v) INITIAL[tag[2]] = v[1];
}

const nodes = {};
function el(id) {
  const e = {
    id, textContent: "", innerHTML: "", value: INITIAL[id] || "", className: "", style: {},
    width: 900, height: 300, children: [], max: "", min: "",
    getContext: () => ctx2d,
    getBoundingClientRect: () => ({ left: 0, top: 0, width: 900, height: 300 }),
    appendChild(c) { this.children.push(c); return c; },
    addEventListener() {},
    setAttribute() {}, getAttribute: () => null,
    classList: { add() {}, remove() {}, toggle() {} },
  };
  return e;
}

const sandbox = {
  console, Math, Number, String, Object, Array, JSON, isFinite, parseFloat, parseInt,
  getComputedStyle: () => ({ getPropertyValue: () => "#888" }),
  devicePixelRatio: 1,
  document: {
    documentElement: el("root"), body: el("body"),
    getElementById: (id) => nodes[id] || (nodes[id] = el(id)),
    createElement: () => el("new"),
    addEventListener() {},
  },
  window: { addEventListener() {} },
  requestAnimationFrame() {}, setTimeout() {},
};
vm.createContext(sandbox);

let threw = null;
try {
  vm.runInContext(m[1], sandbox, { timeout: 5000 });
} catch (e) {
  threw = e;
}

let fails = 0;
const ok = (name, cond, detail) => {
  console.log((cond ? "  ok    " : "  FAIL  ") + name + (detail ? "   " + detail : ""));
  if (!cond) fails++;
};

ok("the page script runs without throwing", !threw,
  threw ? (threw.message || String(threw)) : "");

if (!threw) {
  // Every readout the page promises must hold a real value, not its dash.
  const readouts = ["mSec", "mDirt", "mOre", "mSeam", "tDmg", "tBp", "tReach", "tCap",
    "layerLab", "lvlLab", "tierLab", "vBig", "vWhy", "foot", "mineSub", "toolSub"];
  const dead = readouts.filter((id) => {
    const t = nodes[id] && nodes[id].textContent;
    return !t || t === "—" || t === "-";
  });
  ok("every readout is filled in", dead.length === 0,
    dead.length ? "still blank: " + dead.join(", ") : readouts.length + " of them");

  const zones = nodes.zone && nodes.zone.children.length;
  ok("the zone dropdown is populated", zones > 0, zones + " options");

  ok("the layer slider reaches the real floor",
    nodes.layer && Number(nodes.layer.max) > 1000,
    nodes.layer ? "max=" + nodes.layer.max : "no slider");

  ok("the tier slider covers the roster",
    nodes.tier && Number(nodes.tier.max) >= 80,
    nodes.tier ? "max=" + nodes.tier.max : "no slider");
}

console.log("");
console.log(fails ? ">>> minemap: " + fails + " FAILED" : ">>> minemap: the page renders");
process.exit(fails ? 1 : 0);
