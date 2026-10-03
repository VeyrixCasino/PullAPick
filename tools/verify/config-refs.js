// Every MineConfig symbol the code reads must actually exist.
//
// This exists because of a real bug that four commits shipped over the top of.
// A merge took main's MineConfig wholesale and dropped a block of ~10 symbols
// while every caller of them stayed:
//
//     C.toolBreakingPower(row)     -- called on EVERY tool grant
//     C.toolCraftCost(tier, mult)  -- called on every craft
//     C.woodPickCoinCost(level)    -- the starter pickaxe's whole coin ladder
//     C.WOOD_PICK_MAX_LEVEL        -- compared with >=, so nil threw
//
// Luau parses all of that happily: a missing field is nil until it is called
// or compared, and then it throws at runtime, in Studio, on a path a test
// never walks. syntax.sh cannot see it. This can.
//
// It only trusts `C.` in files that actually bind C to MineConfig, so a file
// using C for something else is not misread.
//
//   node tools/verify/config-refs.js
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "../..");
const SRC = path.join(ROOT, "src");
const CONFIG = path.join(SRC, "ReplicatedStorage/Mine/Shared/MineConfig.luau");

function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out);
    else if (e.name.endsWith(".luau")) out.push(p);
  }
  return out;
}

const cfg = fs.readFileSync(CONFIG, "utf8");

// What MineConfig defines. Assignment, function, and the derived ones written
// inside do-blocks all look the same from here: a key off the module table.
const defined = new Set();
for (const m of cfg.matchAll(/\bMineConfig\.([A-Za-z_]\w*)\s*(?:=|\.)/g)) defined.add(m[1]);
for (const m of cfg.matchAll(/\bfunction\s+MineConfig[.:]([A-Za-z_]\w*)/g)) defined.add(m[1]);
// `MineConfig[expr] = ...` means some keys are built at runtime; record that so
// a dynamic-key module is not reported as if every read were a typo.
const dynamic = /\bMineConfig\[/.test(cfg);

if (defined.size === 0) {
  console.error("FAIL could not read any MineConfig definitions — has the module moved?");
  process.exit(1);
}

// A module nothing requires cannot break the game, so a stale read inside one
// is reported rather than failed. Scratch files and offline sims live in the
// tree on purpose and should not hold the build hostage; a live module reading
// a symbol that does not exist is a different thing entirely.
const files = walk(SRC);
// Comments are stripped first, and a file naming ITSELF does not count. An
// offline sim whose docstring shows `require(game.ServerStorage.X).run()` was
// otherwise reading as a live module required by something.
const stripComments = (s) => s.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");
const required = new Set();
for (const f of files) {
  const text = stripComments(fs.readFileSync(f, "utf8"));
  const self = path.basename(f, ".luau").replace(/\.(server|client)$/, "");
  for (const m of text.matchAll(/(?:WaitForChild|FindFirstChild)\(\s*"([A-Za-z_]\w*)"|require\([^)]*?[.:]([A-Za-z_]\w*)\)/g)) {
    const name = m[1] || m[2];
    if (name && name !== self) required.add(name);
  }
}
const isLive = (file) => {
  const stem = path.basename(file, ".luau").replace(/\.(server|client)$/, "");
  // A .server/.client script is an entry point: it runs whether or not anything
  // requires it.
  return /\.(server|client)\.luau$/.test(file) || required.has(stem);
};

// Reads. `C.` counts only where C is bound to MineConfig in that same file.
const missing = new Map();
const dormant = new Map();
let scanned = 0;
for (const file of files) {
  if (file === CONFIG) continue;
  const text = fs.readFileSync(file, "utf8");
  const aliases = ["MineConfig"];
  if (/\blocal\s+C\s*=\s*require\([^)]*MineConfig/.test(text)) aliases.push("C");
  if (!aliases.some((a) => text.includes(a + "."))) continue;
  scanned++;
  const rel = path.relative(ROOT, file);
  const bucket = isLive(file) ? missing : dormant;
  for (const alias of aliases) {
    const re = new RegExp(`\\b${alias}\\.([A-Za-z_]\\w*)`, "g");
    for (const m of text.matchAll(re)) {
      const name = m[1];
      if (defined.has(name)) continue;
      const line = text.slice(0, m.index).split("\n").length;
      if (!bucket.has(name)) bucket.set(name, []);
      bucket.get(name).push(`${rel}:${line}`);
    }
  }
}

console.log(`  scanned ${scanned} files against ${defined.size} MineConfig symbols`);
if (dynamic) {
  console.log("  note: MineConfig also assigns some keys dynamically (MineConfig[expr])");
}

if (dormant.size > 0) {
  console.log("");
  console.log("  note: stale reads in modules nothing requires (not failed):");
  for (const [name, where] of [...dormant].sort()) {
    console.log(`          MineConfig.${name}  <- ${where[0]}${where.length > 1 ? ` (+${where.length - 1})` : ""}`);
  }
}

if (missing.size === 0) {
  console.log("");
  console.log("  ok    every MineConfig symbol a LIVE module reads exists");
  console.log("");
  console.log(">>> config-refs: all assertions passed");
  process.exit(0);
}

console.log("");
for (const [name, where] of [...missing].sort()) {
  console.log(`  FAIL  MineConfig.${name} is read but never defined`);
  for (const w of where.slice(0, 6)) console.log(`          ${w}`);
  if (where.length > 6) console.log(`          ... and ${where.length - 6} more`);
}
console.log("");
console.log(`>>> config-refs: ${missing.size} FAILED — symbol(s) read but not defined`);
process.exit(1);
