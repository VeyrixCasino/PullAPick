// A local called above its own declaration is a GLOBAL READ, and nil.
//
// This is the one trap in this codebase that every other gate waves through.
// Luau scoping is positional: a `local function foo` on line 2662 is simply not
// in scope on line 2293, so a call there does not resolve to it -- it compiles
// to a global lookup, which is nil at runtime. That is legal Luau, so
// `luau-compile` passes, `luau-analyze` passes, and the suite goes green.
//
// It shipped on 2026-10-11 and took the game's core loop out:
//
//     MineServer:2293: attempt to call a nil value
//     ... function equippedTool / boosts / mineTick
//
// skinBase was defined beside boosts(), ~370 lines below the two places that
// called it. equippedTool is called by givePickaxe, snap, boosts and mineTick,
// so one mis-ordered local broke spawning, the snapshot and mining at once.
// Three earlier instances are recorded in the wiki (luau-traps).
//
// What this checks, per .luau file:
//
//   * every top-level `local function NAME(`
//   * minus any that were forward-declared earlier (`local NAME` / `local NAME =`)
//   * fails if NAME is CALLED anywhere above its declaration line
//
// Calls through a table (`t.NAME(`, `t:NAME(`) are not this bug and are
// ignored, as are comments and string literals.
//
//   node tools/verify/localorder.js
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "../..");
const SRC = path.join(ROOT, "src");

function luauFiles(dir, out) {
  out = out || [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) luauFiles(p, out);
    else if (e.name.endsWith(".luau")) out.push(p);
  }
  return out;
}

// Blank out comments and string bodies so an identifier inside either cannot
// be mistaken for a call. Positions are preserved -- characters are replaced,
// never removed -- so line numbers stay true.
function blank(src) {
  const out = src.split("");
  let i = 0;
  const n = src.length;
  const wipe = (from, to) => {
    for (let k = from; k < to && k < n; k++) if (out[k] !== "\n") out[k] = " ";
  };
  while (i < n) {
    const two = src.slice(i, i + 2);
    if (two === "--") {
      const long = /^--\[(=*)\[/.exec(src.slice(i));
      if (long) {
        const close = "]" + long[1] + "]";
        const end = src.indexOf(close, i);
        const stop = end === -1 ? n : end + close.length;
        wipe(i, stop);
        i = stop;
        continue;
      }
      let end = src.indexOf("\n", i);
      if (end === -1) end = n;
      wipe(i, end);
      i = end;
      continue;
    }
    if (src[i] === '"' || src[i] === "'") {
      const q = src[i];
      let k = i + 1;
      while (k < n && src[k] !== q) {
        if (src[k] === "\\") k++;
        if (src[k] === "\n") break;
        k++;
      }
      wipe(i, k + 1);
      i = k + 1;
      continue;
    }
    const long = /^\[(=*)\[/.exec(src.slice(i));
    if (long) {
      const close = "]" + long[1] + "]";
      const end = src.indexOf(close, i);
      const stop = end === -1 ? n : end + close.length;
      wipe(i, stop);
      i = stop;
      continue;
    }
    i++;
  }
  return out.join("");
}

let failures = 0;
let scanned = 0;
let decls = 0;

for (const file of luauFiles(SRC)) {
  const raw = fs.readFileSync(file, "utf8");
  const lines = blank(raw).split(/\r?\n/);
  scanned++;

  //[[
  //  EVERY declaration of a name, not just one.
  //
  //  A name can be declared more than once at file scope -- MineClient has two
  //  separate `local function clear`, several hundred lines apart, and each
  //  serves the code below it. Comparing a call against the LAST declaration
  //  flags perfectly legal calls to the first one, which is what the first
  //  version of this gate did. What matters is whether ANY declaration of the
  //  name stands above the call.
  //
  //  Forward declarations (`local NAME`, `local NAME = ...`) count, because
  //  they are exactly how the order is legally fixed.
  //]]
  // Two sets, and the asymmetry is the whole design:
  //   topDecl -- what gets CHECKED: file-scope `local function NAME`, the
  //              shape skinBase had.
  //   declAt  -- what EXCUSES a call: any declaration at any depth, because
  //              this gate cannot see block boundaries and must not guess.
  const topDecl = new Map();
  const declAt = new Map(); // name -> [line, ...] ascending
  const note = (nm, idx) => {
    if (!declAt.has(nm)) declAt.set(nm, []);
    declAt.get(nm).push(idx);
  };
  //[[
  //  Declarations count at ANY indentation, deliberately.
  //
  //  A nested `local function clear` inside a do-block is invisible to the
  //  file scope, so strictly it does not legalise a later top-level call --
  //  but it DOES legalise the calls beside it inside that block, and this gate
  //  cannot see block boundaries. MineClient has exactly that: an indented
  //  `local function clear` at 5244 used at 5266 and 5312, and a separate
  //  top-level one much further down.
  //
  //  So the rule is deliberately conservative: if ANY declaration of the name
  //  stands above the call, say nothing. It can miss a contrived case; it
  //  cannot cry wolf, and a gate that cries wolf gets switched off. The bug
  //  this exists for -- skinBase -- had no declaration above it at any depth.
  //]]
  lines.forEach((ln, idx) => {
    const d = /^\s*local\s+function\s+([A-Za-z_][\w]*)\s*\(/.exec(ln);
    if (d) {
      note(d[1], idx);
      if (/^local\s/.test(ln)) {
        decls++;
        if (!topDecl.has(d[1])) topDecl.set(d[1], idx);
      }
      return;
    }
    const fwd = /^\s*local\s+([A-Za-z_][\w]*(?:\s*,\s*[A-Za-z_][\w]*)*)\s*(=|$)/.exec(ln);
    if (fwd) {
      for (const nm of fwd[1].split(",").map((s) => s.trim())) note(nm, idx);
    }
  });

  for (const [name, first] of topDecl) {
    const at = declAt.get(name) || [first];
    if (first === 0) continue;
    // An earlier declaration of any kind, at any depth, legalises everything
    // above it -- see the note on why this is deliberately conservative.
    if (at[0] < first) continue;
    for (let i = 0; i < first; i++) {
      const ln = lines[i];
      let from = 0;
      for (;;) {
        const k = ln.indexOf(name, from);
        if (k === -1) break;
        from = k + 1;
        const before = k > 0 ? ln[k - 1] : "";
        const after = ln.slice(k + name.length);
        if (/[\w]/.test(before)) continue;              // part of a longer word
        if (before === "." || before === ":") continue; // a field, not this local
        if (!/^\s*\(/.test(after)) continue;            // not a call
        failures++;
        console.log(
          `  FAIL  ${path.relative(ROOT, file)}:${i + 1} calls '${name}', ` +
            `first declared at line ${first + 1}`
        );
        console.log(`          ${lines[i].trim().slice(0, 100)}`);
        break;
      }
    }
  }
}

console.log("");
console.log(
  `  scanned ${scanned} .luau files, ${decls} top-level local functions`
);
if (failures > 0) {
  console.log("");
  console.log(
    `>>> localorder: ${failures} FAILED -- each one reads as nil at runtime`
  );
  process.exit(1);
}
console.log(">>> localorder: no local is called above its declaration");
process.exit(0);
