// docs/CANDY-CRYPT.md must say what the code says.
//
// Owner, 2026-10-19 ("Candy Crypt v2"): the Crypt's numbers -- block HP, spawn
// chances, drops and candy with their spread, chests, the case, every tool's
// costs and damage -- "in the repo, generated from the code". A document that
// is generated once and then drifts is the mine-map story again
// (tools/verify/generated-fresh.js): every number plausible, every number wrong.
//
// So this runs the generator in --check mode: it rebuilds the document from the
// real Luau modules and fails if the committed one differs by a byte (line
// endings aside, for the owner's CRLF clone). The fix is always the same:
//
//   node tools/gen/crypt-doc.js
//
// It also pins what the document must contain, so a generator that quietly
// stopped emitting a section cannot pass by agreeing with itself.
//
//   node tools/verify/crypt-doc.js
//   node tools/verify/crypt-doc.js --root <path to another checkout>   (proves it bites)
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");

const argRoot = (() => {
  const i = process.argv.indexOf("--root");
  return i > 0 && process.argv[i + 1] ? path.resolve(process.argv[i + 1]) : null;
})();
const ROOT = argRoot || path.resolve(__dirname, "../..");
const DOC = path.join(ROOT, "docs/CANDY-CRYPT.md");
const GEN = path.join(ROOT, "tools/gen/crypt-doc.js");

let fail = 0;
const check = (ok, msg, detail) => {
  console.log((ok ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!ok) fail++;
};

console.log("crypt-doc: docs/CANDY-CRYPT.md is generated from the code and current");
check(fs.existsSync(GEN), "the generator exists (tools/gen/crypt-doc.js)");
check(fs.existsSync(DOC), "the document exists (docs/CANDY-CRYPT.md)");
const doc = fs.existsSync(DOC) ? Luau.readSrc(DOC) : "";
for (const [what, re] of [
  ["block HP per section", /## 1\. Block HP per section/],
  ["the sixteen ores with their drop and candy", /## 2\. The sixteen candy ores[\s\S]*\| 16 \| Jawbreaker \|/],
  ["each ore's spawn chance per section", /## 3\. Spawn chance per section[\s\S]*### By ore/],
  ["the per-block mix with its spread", /## 4\. What a block pays, per section[\s\S]*\| SD \|/],
  ["the chests, their pay and their odds", /## 5\. Crypt chests[\s\S]*### Rank odds per section/],
  ["the Trick-or-Treat odds", /## 6\. The Trick-or-Treat case[\s\S]*TREAT you get it, TRICK you get nothing/],
  ["every tool's craft and prestige cost", /### Prestige cost, in the tool's own ore/],
  ["every tool's damage at every prestige, in the Crypt and in the main world",
    /### Damage in the Crypt, at every prestige[\s\S]*### Damage in the main world, after the event/],
  ["scrap value", /### Scrap value, in candy/],
  ["gems an hour", /## 8\. Gems/],
]) {
  check(re.test(doc), "it has " + what);
}

if (!Luau.ready) {
  console.log("  " + Luau.missing("luau") + "; skipping the regeneration");
  console.log(fail === 0 ? ">>> crypt-doc OK (static only)" : `>>> crypt-doc: ${fail} FAILED`);
  process.exit(fail === 0 ? 0 : 1);
}
let out = "";
let ok = true;
try {
  out = execFileSync(process.execPath, [GEN, "--check"], { cwd: ROOT, encoding: "utf8", maxBuffer: 1 << 24 });
} catch (e) {
  ok = false;
  out = ((e.stdout || "") + (e.stderr || "")).toString();
}
check(ok, "regenerating it from the code gives the committed document byte for byte", out.trim().split("\n").pop());
console.log(fail === 0 ? ">>> crypt-doc OK" : `>>> crypt-doc: ${fail} FAILED`);
process.exit(fail === 0 ? 0 : 1);
