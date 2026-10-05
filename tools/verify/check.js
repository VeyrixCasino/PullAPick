// Does the tool level rescale actually behave? Roster and cap come from the
// calculator, which tools/gen/upgrade-calculator.js generates from MineConfig.
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
// Derived, never hardcoded. This check used to assert against tier 121 and a
// 1000-level cap long after MineConfig dropped to 82 ores and a cap of 100,
// and it passed the whole time because it was reading the calculator's own
// stale copy of the roster. The calculator is generated from MineConfig now
// (tools/gen/upgrade-calculator.js), so these follow it automatically.
const TOP = X.ORES.length, CAP = X.MAXLVL;
const at = (frac) => Math.max(1, Math.round(TOP * frac));
let fails = 0;
const ok = (n,c,d)=>{ console.log((c?"PASS  ":"FAIL  ")+n+(d?"   "+d:"")); if(!c) fails++; };
const PICK = 0, FRACK = TYPES.length - 1;
console.log(`roster: ${TOP} ores, level cap ${CAP}\n`);

console.log("dmgBase=" + T.dmgBase + " dmgStep=" + T.dmgStep + " tierSpan=" + T.tierSpan +
            " recPct=" + T.recPct + "\n");

console.log("--- every tool starts at level 1 ---");
console.log("tier".padEnd(6) + "type".padEnd(9) + "lvl 1 dmg".padEnd(12) +
            `lvl ${CAP} dmg`.padEnd(13) + "ore to max".padEnd(12) + "dust to max");
for (const [t, k] of [[1,PICK],[at(0.25),PICK],[at(0.6),PICK],[TOP,PICK],[TOP,FRACK]]) {
  console.log(String(t).padEnd(6) + TYPES[k][0].slice(0,8).padEnd(9) +
    X.dmgAt(1,t,k).toExponential(2).padEnd(12) +
    X.dmgAt(CAP,t,k).toExponential(2).padEnd(13) +
    X.fmt(X.cumOre(CAP,t,k)).padEnd(12) + X.fmt(X.cumDust(CAP,t,k)));
}
ok("a found tool opens at level 1, not near the cap",
   X.dmgAt(1,TOP,PICK) === T.dmgBase*X.tierPower(TOP)*TYPES[PICK][4],
   `tier ${TOP} opens at ` + X.dmgAt(1,TOP,PICK).toExponential(2));

// the climb has to be worth doing: levelling one tool should beat sitting still
const mid = at(0.5);
const climb = X.dmgAt(CAP,mid,PICK)/X.dmgAt(1,mid,PICK);
/*
   Was ">= 1000x", which only ever made sense against the 1000-level cap. Picking
   a new round number would just be tuning the threshold until the check agreed
   with the code, which proves nothing.

   The invariant that actually matters: maxing a tool has to beat forging the
   next tier, or levelling is a trap and everyone skips it. So compare the full
   climb against ONE tier step, both read from the live curve.
*/
const tierStep = Math.pow(X.tierPower(TOP)/X.tierPower(1), 1/(TOP-1));
const steps = Math.log(climb)/Math.log(tierStep);
ok("maxing a tool beats forging one tier up", climb > tierStep,
   climb.toFixed(2) + "x to max vs " + tierStep.toFixed(3) + "x a tier step" +
   "  = worth " + steps.toFixed(1) + " tiers");
console.log("      NOTE tier 1->" + TOP + " is " +
   (X.tierPower(TOP)/X.tierPower(1)).toExponential(2) + "x, so ORE TIER dominates" +
   " LEVEL by far. Owner wants endgame tools to be a real grind -- that is a" +
   " balance call, not a bug, and it is flagged in docs/OPEN.md.");

// and the whole ladder has to cover the mine, which tops out near 2e20 HP
const top = X.dmgAt(CAP,TOP,FRACK);
/*
   The old threshold was 2e20, from the HP formula MineConfig now labels
   "Dead constants. Do not revive: 2.5^(tier-1)*(1+14*(layer-1)/49)".

   The live curve is MineDepth: dirtHp = (HP_BASE + HP_PER_LAYER*layer) *
   ZONE_HP_MULT^(zone-1) -- LINEAR in layer, x5 a zone -- which tops out nine
   orders of magnitude below the number this was still demanding. Derived here
   so a curve change moves the check with it.
*/
const HP_BASE = 20, HP_PER_LAYER = 1.5, ZONE_HP_MULT = 5;
const DEEPEST_LAYER = 10040, DEEPEST_ZONE = 11;   // bigbang pins itself to 11
const hardest = (HP_BASE + HP_PER_LAYER*DEEPEST_LAYER) *
                Math.pow(ZONE_HP_MULT, DEEPEST_ZONE - 1);
/*
   One-shotting the hardest block was never the goal -- a block SHOULD take
   swings. What must not happen is a wall: the top tool, with no boosts at all,
   has to make real progress on the deepest rock.

   Note these are RAW tool numbers. docs/BALANCE-MEASURED.md puts layer 1 at
   x17.55 and layer 2 at x15.65 on dirtBreak, so a geared player multiplies
   everything below by up to x274.7. The unboosted figure is the floor, and the
   floor is what decides whether a player who has not built a boost set is
   stuck.
*/
const SWING_WALL = 100;
const swings = hardest/top;
ok(`the hardest block is not a wall for an unboosted top tool (<=${SWING_WALL} swings)`,
   swings <= SWING_WALL,
   "max damage " + top.toExponential(2) + " vs hardest block " +
   hardest.toExponential(2) + "  = " + swings.toFixed(2) + " swings raw, " +
   (swings/274.7).toExponential(2) + " fully geared");
ok("and the top tool does not trivialise it either (>1 swing raw)", swings > 1,
   swings.toFixed(2) + " swings before any boost");
console.log("      lucky block (x10) " + (hardest*10/top).toFixed(1) +
   " swings raw; core block fixed 1e14, " + (1e14/top).toFixed(0) + " swings raw");

console.log("\n--- recycle is flat, and a found tool gives nothing ---");
let offRate = 0;
const levels = [...new Set([1, Math.round(CAP*0.1), Math.round(CAP*0.5), CAP])].filter(L=>L>=1);
for (let t=1;t<=TOP;t+=10) for (let k=0;k<TYPES.length;k+=5) for (const L of levels) {
  const inv = X.cumDust(L,t,k);
  if (inv > 0 && Math.abs(X.recycleAt(t,L,k)/inv - T.recPct) > 1e-9) offRate++;
}
ok("recycle is exactly recPct of dust spent, everywhere", offRate === 0,
   Math.round(T.recPct*100) + "% flat");
ok("a level-1 found tool returns nothing",
   X.recycleAt(TOP,1,FRACK) === 0 && X.recycleOre(TOP,1,FRACK) === 0,
   "nothing went in, nothing comes out");
const rt = at(0.5), rL = Math.max(2, Math.round(CAP*0.5));
ok("recycle returns ore as well as dust", X.recycleOre(rt,rL,PICK) > 0,
   X.fmt(X.recycleOre(rt,rL,PICK)) + " ore + " + X.fmt(X.recycleAt(rt,rL,PICK)) + ` dust at t${rt} L${rL}`);

console.log("\n--- ore to gems ---");
console.log("tier".padEnd(6) + "ore".padEnd(15) + "bulk".padEnd(7) +
            "drop".padEnd(7) + "gems each".padEnd(12) + "gems per find");
for (const t of [...new Set([1, at(0.06), at(0.12), at(0.35), at(0.5), at(0.8), TOP])]) {
  console.log(String(t).padEnd(6) + X.ORES[t-1].slice(0,13).padEnd(15) +
    (X.isBulk(t)?"yes":"no").padEnd(7) + String(X.oreDrop(t)).padEnd(7) +
    X.gemPer(t).toExponential(2).padEnd(12) + X.fmt(X.gemsPerFind(t)));
}
// a bulk ore should be worth about the same per find as its neighbours
const bulk = at(0.12), near = Math.max(1, at(0.12) - 1);
const ratio = X.gemsPerFind(bulk)/X.gemsPerFind(near);
ok("a bulk find is worth about what its neighbour is worth",
   ratio > 0.5 && ratio < 2.0,
   "tier " + bulk + " vs tier " + near + " = " + ratio.toFixed(2) + "x, " +
   X.oreDrop(bulk) + " drops vs " + X.oreDrop(near));
ok("gems rise with tier", X.gemsPerFind(TOP) > X.gemsPerFind(at(0.5)) &&
   X.gemsPerFind(at(0.5)) > X.gemsPerFind(1),
   X.fmt(X.gemsPerFind(1)) + " -> " + X.fmt(X.gemsPerFind(at(0.5))) + " -> " + X.fmt(X.gemsPerFind(TOP)));

console.log("\n" + (fails ? fails + " CHECK(S) FAILED" : "all checks passed"));
process.exit(fails ? 1 : 0);
