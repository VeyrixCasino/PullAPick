// Does the 1-1000 rescale actually behave?
const fs = require("fs"), vm = require("vm");
const html = fs.readFileSync(require("path").join(__dirname,"..","upgrade-calculator.html"),"utf8");
const m = html.match(/<script>([\s\S]*)<\/script>/);
const ctx2d = new Proxy({}, { get: (t, k) => k === "canvas" ? { width: 1000, height: 400 }
  : k === "measureText" ? (() => ({ width: 10 }))
  : k === "createLinearGradient" ? (() => ({ addColorStop() {} }))
  : k === "getImageData" ? (() => ({ data: [] })) : (() => {}), set: () => true });
function el(v) { return { textContent:"", innerHTML:"", value: v||"", style:{}, className:"",
  width:1000, height:400, children:[], getContext(){return ctx2d;},
  getBoundingClientRect(){return {left:0,top:0,width:1000,height:400};},
  appendChild(c){this.children.push(c);return c;}, addEventListener(){},
  setAttribute(){}, getAttribute(){return null;}, querySelector(){return el();},
  querySelectorAll(){return [];}, insertAdjacentHTML(){}, focus(){},
  classList:{add(){},remove(){},toggle(){}} }; }
const nodes = {};
const sb = { console, Math, Number, String, Object, Array, JSON, isFinite, parseFloat, parseInt,
  getComputedStyle(){return {getPropertyValue(){return "#888";}};}, devicePixelRatio:1,
  document:{ documentElement:el(), body:el(),
    getElementById(id){ return nodes[id] || (nodes[id] = el(id==="lvl"?"0":(id==="zLayer"?"250":""))); },
    createElement(){return el();}, querySelector(){return el();},
    querySelectorAll(){return [];}, addEventListener(){} },
  window:{ addEventListener(){} }, requestAnimationFrame(){}, setTimeout(){} };
vm.createContext(sb);
vm.runInContext("var __E;" + m[1].replace(/\}\)\(\);\s*$/,
  "__E={T:T,TYPES:TYPES,ORES:ORES,MAXLVL:MAXLVL,dmgAt:dmgAt,tierPower:tierPower," +
  "oreAt:oreAt,dustAt:dustAt,cumOre:cumOre,cumDust:cumDust,recycleAt:recycleAt," +
  "recycleOre:recycleOre,isBulk:isBulk,oreDrop:oreDrop,gemPer:gemPer," +
  "gemsPerFind:gemsPerFind,fmt:fmt};\n})();"), sb);
const X = sb.__E, T = X.T, TYPES = X.TYPES;
let fails = 0;
const ok = (n,c,d)=>{ console.log((c?"PASS  ":"FAIL  ")+n+(d?"   "+d:"")); if(!c) fails++; };
const PICK = 0, FRACK = TYPES.length - 1;

console.log("dmgBase=" + T.dmgBase + " dmgStep=" + T.dmgStep + " tierSpan=" + T.tierSpan +
            " recPct=" + T.recPct + "\n");

console.log("--- every tool starts at level 1 ---");
console.log("tier".padEnd(6) + "type".padEnd(9) + "lvl 1 dmg".padEnd(12) +
            "lvl 1000 dmg".padEnd(13) + "ore to max".padEnd(12) + "dust to max");
for (const [t, k] of [[1,PICK],[32,PICK],[74,PICK],[121,PICK],[121,FRACK]]) {
  console.log(String(t).padEnd(6) + TYPES[k][0].slice(0,8).padEnd(9) +
    X.dmgAt(1,t,k).toExponential(2).padEnd(12) +
    X.dmgAt(1000,t,k).toExponential(2).padEnd(13) +
    X.fmt(X.cumOre(1000,t,k)).padEnd(12) + X.fmt(X.cumDust(1000,t,k)));
}
ok("a found tool opens at level 1, not 700",
   X.dmgAt(1,121,PICK) === T.dmgBase*X.tierPower(121)*TYPES[PICK][4],
   "tier 121 opens at " + X.dmgAt(1,121,PICK).toExponential(2));

// the climb has to be worth doing: levelling one tool should beat sitting still
const climb = X.dmgAt(1000,60,PICK)/X.dmgAt(1,60,PICK);
ok("levelling 1->1000 is a real climb (>=1000x)", climb >= 1000,
   climb.toExponential(2) + "x on one tool");

// and the whole ladder has to cover the mine, which tops out near 2e20 HP
const top = X.dmgAt(1000,121,FRACK);
ok("max tool can break the deepest block (HP ~2e20)", top >= 2e20,
   "max damage " + top.toExponential(2));
ok("but not absurdly past it (<1e26)", top < 1e26, top.toExponential(2));

console.log("\n--- recycle is flat, and a found tool gives nothing ---");
let offRate = 0;
for (let t=1;t<=121;t+=10) for (let k=0;k<TYPES.length;k+=5) for (const L of [1,100,500,1000]) {
  const inv = X.cumDust(L,t,k);
  if (inv > 0 && Math.abs(X.recycleAt(t,L,k)/inv - T.recPct) > 1e-9) offRate++;
}
ok("recycle is exactly recPct of dust spent, everywhere", offRate === 0,
   Math.round(T.recPct*100) + "% flat");
ok("a level-1 found tool returns nothing",
   X.recycleAt(121,1,FRACK) === 0 && X.recycleOre(121,1,FRACK) === 0,
   "nothing went in, nothing comes out");
ok("recycle returns ore as well as dust", X.recycleOre(60,500,PICK) > 0,
   X.fmt(X.recycleOre(60,500,PICK)) + " ore + " + X.fmt(X.recycleAt(60,500,PICK)) + " dust at t60 L500");

console.log("\n--- ore to gems ---");
console.log("tier".padEnd(6) + "ore".padEnd(15) + "bulk".padEnd(7) +
            "drop".padEnd(7) + "gems each".padEnd(12) + "gems per find");
for (const t of [1,7,14,42,60,98,121]) {
  console.log(String(t).padEnd(6) + X.ORES[t-1].slice(0,13).padEnd(15) +
    (X.isBulk(t)?"yes":"no").padEnd(7) + String(X.oreDrop(t)).padEnd(7) +
    X.gemPer(t).toExponential(2).padEnd(12) + X.fmt(X.gemsPerFind(t)));
}
// a bulk ore should be worth about the same per find as its neighbours
const bulk = 14, near = 13;
const ratio = X.gemsPerFind(bulk)/X.gemsPerFind(near);
ok("a bulk find is worth about what its neighbour is worth",
   ratio > 0.5 && ratio < 2.0,
   "tier " + bulk + " (bulk) vs tier " + near + " = " + ratio.toFixed(2) + "x, " +
   X.oreDrop(bulk) + " drops vs " + X.oreDrop(near));
ok("gems rise with tier", X.gemsPerFind(121) > X.gemsPerFind(60) &&
   X.gemsPerFind(60) > X.gemsPerFind(1),
   X.fmt(X.gemsPerFind(1)) + " -> " + X.fmt(X.gemsPerFind(60)) + " -> " + X.fmt(X.gemsPerFind(121)));

console.log("\n" + (fails ? fails + " CHECK(S) FAILED" : "all checks passed"));
process.exit(fails ? 1 : 0);
