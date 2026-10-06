// EVERY FILE MUST COMPILE, AND THE BIG SCRIPTS MUST HAVE ROOM LEFT.
//
// syntax.sh runs luau-analyze, which parses and type-checks. It does NOT
// allocate registers, so it accepts a script the engine will refuse to load:
//
//     190 live top-level locals -> analyze ok, compile ok
//     200 live top-level locals -> analyze ok, compile: Out of local registers
//     205 live top-level locals -> analyze ok, compile: Out of upvalue registers
//
// Luau gives a function 200 registers. The main chunk of a script is a function,
// so top-level locals spend that budget, and a script that exceeds it fails at
// COMPILE time -- meaning the whole script never runs.
//
// That failure is close to invisible. On 2026-10-05 one added local took
// MineServer over: the server script never ran, so MineNet was never created,
// and every client sat on WaitForChild("MineNet") forever. The only clue was a
// single line in the output. It happened twice the same day, once in each big
// script, which is what this check exists to stop.
//
// HEADROOM, NOT JUST PASS/FAIL. "It compiles today" is not the useful fact --
// a file one local from the ceiling is a trap for whoever edits it next. So
// this measures how many more top-level locals each big script could take, by
// appending live ones and binary-searching the limit, and fails while that
// number is below MIN_HEADROOM. Live and table-valued on purpose: an unused or
// constant local is folded away and would measure nothing.
//
// Run: node tools/verify/compile.js
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");

const ROOT = path.join(__dirname, "..", "..");
const SRC = path.join(ROOT, "src");

// Scripts whose main chunk is big enough to be worth watching. Both have been
// over the ceiling at least once.
const WATCH = [
  "src/ServerScriptService/Mine/MineServer.server.luau",
  "src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau",
];
const MIN_HEADROOM = 4;

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

const COMPILE = (() => {
  const names = process.platform === "win32" ? ["luau-compile.exe", "luau-compile"] : ["luau-compile", "luau-compile.exe"];
  for (const n of names) {
    const p = path.join(ROOT, ".luau-bin", n);
    if (fs.existsSync(p) && Luau.runnableHere(p)) return p;
  }
  return null;
})();

console.log("compile: every file compiles, and the big scripts have registers left");

if (!COMPILE) {
  console.log("  luau-compile not runnable on this platform; skipping");
  process.exit(0);
}

function compiles(file) {
  try {
    execFileSync(COMPILE, ["--binary", file], { stdio: "pipe" });
    return { ok: true };
  } catch (e) {
    const out = ((e.stdout || "") + (e.stderr || "")).toString().trim();
    return { ok: false, why: out.split("\n")[0] || "unknown compile error" };
  }
}

function compilesSource(src) {
  const f = path.join(os.tmpdir(), "mfc-compile-probe.luau");
  fs.writeFileSync(f, src);
  return compiles(f).ok;
}

// --------------------------------------------------- every file compiles --
const files = [];
(function walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p);
    else if (e.name.endsWith(".luau")) files.push(p);
  }
})(SRC);

const broken = [];
for (const f of files) {
  const r = compiles(f);
  if (!r.ok) broken.push({ f: path.relative(ROOT, f).replace(/\\/g, "/"), why: r.why });
}
ok(broken.length === 0, `all ${files.length} source files compile`,
  broken.length ? broken.map((b) => `${b.f}: ${b.why}`).join(" | ") : "luau-compile, not just luau-analyze");

// ------------------------------------------------------------- headroom --
//[[ Appending LIVE table locals: a local that is never read, or that holds a
// constant, is optimised away and would report infinite headroom. ]]
function withExtra(src, n) {
  let s = src + "\n";
  for (let i = 1; i <= n; i++) s += `local __hr${i} = {}\n`;
  if (n > 0) {
    s += "local function __hrUse()\n";
    for (let i = 1; i <= n; i++) s += `  __hr${i}.x = 1\n`;
    s += "end\n__hrUse()\n";
  }
  return s;
}

function headroom(rel) {
  const src = fs.readFileSync(path.join(ROOT, rel), "utf8");
  if (!compilesSource(src)) return -1;
  const CAP = 256;
  if (compilesSource(withExtra(src, CAP))) return CAP;
  let lo = 0, hi = CAP;
  while (lo < hi) {
    const mid = Math.ceil((lo + hi) / 2);
    if (compilesSource(withExtra(src, mid))) lo = mid;
    else hi = mid - 1;
  }
  return lo;
}

for (const rel of WATCH) {
  if (!fs.existsSync(path.join(ROOT, rel))) {
    ok(false, `${rel} exists`);
    continue;
  }
  const h = headroom(rel);
  const name = rel.split("/").pop();
  ok(h >= MIN_HEADROOM,
    `${name} has at least ${MIN_HEADROOM} top-level locals of headroom`,
    h < 0 ? "does not compile at all" :
      `${h} left` + (h < MIN_HEADROOM
        ? " -- the next local added here stops the whole script running"
        : ""));
}

console.log(fails === 0 ? ">>> compile OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
