// EVERY path that deals damage must run the breaking gate.
//
// Dig.Breaking.canBreak was wired in on 2026-10-05 and only into the main swing.
// swingNeighbour predates it and never got the check, so for a while `canBreak`
// had exactly ONE call site while TWO functions dealt damage -- and every AoE
// proc (blast, zap, ricochet, earthquake, echo) arrives through the one that was
// missing it. A tier-1 pick with a proc chipped rock it could not scratch.
//
// That is the kind of hole that reappears the next time a damage path is added,
// because nothing about adding one reminds you the gate exists. This asserts the
// coverage directly: find the functions that deal block damage, and require each
// of them to consult the gate.
//
// Run: node tools/verify/gate-coverage.js
const path = require("path");
const { readSrc } = require("./_luau.js");
const ROOT = path.join(__dirname, "..", "..");
const SRV = path.join(ROOT, "src/ServerScriptService/Mine/MineServer.server.luau");
const src = readSrc(SRV);

let fails = 0, checks = 0;
const ok = (c, msg, detail) => {
  checks++;
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

// Slice a top-level `local function NAME(` / `function NAME(` body: from its
// header to the next line that is exactly "end" at column 0.
function body(name) {
  const lines = src.split("\n");
  const re = new RegExp("^(local )?function " + name + "\\s*\\(");
  const i = lines.findIndex((l) => re.test(l));
  if (i < 0) return null;
  for (let j = i + 1; j < lines.length; j++) {
    if (lines[j] === "end") return lines.slice(i, j + 1).join("\n");
  }
  return null;
}

// The functions that actually reduce a block's HP. payDamage is the common
// sink, so anything calling it with a landed amount is a damage path.
const DAMAGE_PATHS = ["swingNeighbour", "swingBlock"];

console.log("gate-coverage: every damage path must consult Dig.Breaking.canBreak");

for (const fn of DAMAGE_PATHS) {
  const b = body(fn);
  ok(!!b, fn + " is findable in MineServer");
  if (!b) continue;
  ok(/Dig\.Breaking\.canBreak\s*\(/.test(b),
    fn + " runs the breaking gate",
    /Dig\.Breaking\.canBreak\s*\(/.test(b) ? "calls canBreak" : "NO canBreak call -- procs would route around the gate");
  // and it must actually bail on a false, not merely compute it
  ok(/if not okBreak then[\s\S]{0,400}?return/.test(b),
    fn + " returns without damage when the gate refuses",
    "a computed-but-ignored gate is the same as no gate");
}

// Nothing else should be calling payDamage from a path we have not checked.
const payCallers = [];
{
  const lines = src.split("\n");
  let cur = null;
  for (const l of lines) {
    const m = l.match(/^(?:local )?function ([A-Za-z_][\w.:]*)\s*\(/);
    if (m) cur = m[1];
    // `cur !== "payDamage"` skips its own declaration line, which otherwise
    // matches as a caller of itself.
    if (/\bpayDamage\s*\(/.test(l) && cur && cur !== "payDamage"
      && !payCallers.includes(cur)) payCallers.push(cur);
  }
}
const unchecked = payCallers.filter((f) => !DAMAGE_PATHS.includes(f.replace(/^.*[.:]/, "")));
ok(unchecked.length === 0,
  "no damage path escapes this check",
  unchecked.length === 0
    ? "payDamage is reached only from " + DAMAGE_PATHS.join(" and ")
    : "unchecked caller(s) of payDamage: " + unchecked.join(", ") +
      " -- add them to DAMAGE_PATHS and gate them");

console.log(fails === 0 ? ">>> gate-coverage: all " + checks + " checks passed"
  : ">>> gate-coverage: " + fails + " of " + checks + " FAILED");
process.exit(fails === 0 ? 0 : 1);
