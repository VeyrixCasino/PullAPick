// THE GEM FAUCET MATCHES THE SIGNED-OFF NUMBER.
//
// docs/PROPOSAL.md §0 line 16 is a DECISION, not a proposal: owner pasted the
// 38-line approved block back unchanged on 2026-10-05, and TODO §0.34 makes it
// law. ORE_GEM_SPREAD 1e6 -> 1e4. It sat unapplied for three days because
// docs/OPEN.md still carried an older "owner deferred it" note, and nothing in
// the tree could tell that the code and the decision had diverged.
//
// That is what this guards. Not the arithmetic -- the AGREEMENT.
//
// WHY IT DOES NOT RE-DERIVE THE CURVE. gemValue reaches through workOf ->
// oreYieldFor and ore.homeHp, which MineConfig attaches to the roster rather
// than storing on the rows. Slicing all of that into a harness means
// re-implementing the model, and a harness that re-implements the thing it
// checks measures its own copy -- this project has already been bitten by
// exactly that (tools/verify/veins.js read `MineConfig.X or <default>` and
// reported a byte-identical histogram across a real change). The number and the
// SHAPE of the formula are checkable without re-deriving either.
//
// The live curve was measured against the real modules in Studio when the value
// changed: tier 1 = 4 gems, tier 41 = 279, tier 82 = 42,727, measured spread
// 10,682x. The proposal's own table says 3 / ~300 / 30,000.
//
// Run: node tools/verify/gem-spread.js
const path = require("path");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const POUCH = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineOrePouch.luau"));
const PROPOSAL = require("fs").readFileSync(path.join(ROOT, "docs/PROPOSAL.md"), "utf8");

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

console.log("gem-spread: the code matches the approved block");

// ------------------------------------------------- what was signed off --
// "16. ORE_GEM_SPREAD            1e6 -> 1e4      (top ore 3,000,000 -> 30,000 gems)"
const line = /ORE_GEM_SPREAD\s+(\S+)\s*->\s*(\S+)/.exec(PROPOSAL);
ok(!!line, "PROPOSAL §0 still carries the ORE_GEM_SPREAD decision",
  "if this line is gone the decision has been edited, not implemented");
if (!line) {
  console.log(">>> 1 FAILED");
  process.exit(1);
}
const wasSpec = line[1], nowSpec = line[2];

const num = (s) => Number(String(s).replace(/_/g, ""));
const approved = num(nowSpec);
ok(Number.isFinite(approved) && approved > 0, "the approved value parses", `${wasSpec} -> ${nowSpec}`);

// ------------------------------------------------------ what the code has --
const code = /MineOrePouch\.ORE_GEM_SPREAD\s*=\s*([0-9.eE+_]+)/.exec(POUCH);
ok(!!code, "MineOrePouch declares ORE_GEM_SPREAD");
const actual = code ? num(code[1]) : NaN;

ok(actual === approved,
  "the code's spread IS the approved spread",
  `code ${code ? code[1] : "?"} vs approved ${nowSpec}`);
ok(actual !== num(wasSpec),
  "...and is no longer the value the decision replaced",
  `the old value was ${wasSpec}`);

// -------------------------------------------------------- the formula shape --
//[[ The spread is only meaningful because the exponent is SOLVED from it. If
// someone ever hardcodes k, changing the spread silently stops doing anything
// and this file's first assertion would still pass. ]]
ok(/k\s*=\s*math\.log\(MineOrePouch\.ORE_GEM_SPREAD\)\s*\/\s*math\.log\(/.test(POUCH),
  "the exponent is solved FROM the spread, not tuned beside it",
  "a hardcoded k would make the spread decorative");
ok(/MineOrePouch\.ORE_GEM_BASE\s*\n?\s*\*\s*\(MineOrePouch\.workOf\(ore\)\s*\^\s*MineOrePouch\.gemCompress\(\)\)/.test(
    POUCH.replace(/\r/g, "")),
  "gemValue is BASE * work^k",
  "the curve's shape is what the spread scales");
ok(/_compress/.test(POUCH), "the solved exponent is cached",
  "it is solved per call otherwise, on a function the pouch UI runs per row");

// ---------------------------------------------------------- the stale twin --
//[[ tools/upgrade-calculator.html carries its OWN gem model --
// gemBase * 6^(gemSpan*(tier-1)/120) -- with gemBase and gemSpan as hardcoded
// SLIDER DEFAULTS that exist nowhere in the game, and the retired /120 divisor
// (the roster is 82, not 121). tools/verify/check.js prints and asserts off
// that model, so its two gem checks pass against numbers the game never uses:
// it reports the top ore at 12.3 gems while the live module pays 42,727.
//
// Not failing the suite over a design toy, but it must not be mistaken for a
// guard on the real number -- that is what this file is for. ]]
ok(true, "note: check.js's gem section measures tools/upgrade-calculator.html",
  "slider defaults + retired /120 divisor; it is not a guard on the live curve");

console.log(fails === 0 ? ">>> gem-spread OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
