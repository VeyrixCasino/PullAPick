// Where the luau interpreter is, on whatever machine this is.
//
// Six verify scripts each hardcoded `.luau-bin/luau`, which is the Linux name.
// That was right while this repo was worked on inside a Claude cloud container
// and wrong the moment it moved to the owner's Windows box: the binary there is
// `luau.exe`, so every one of those six shelled out to a path that does not
// exist.
//
// They did not say so. Each one wraps execFileSync in a try/catch that writes
// `e.stdout` and `e.stderr` -- both empty for ENOENT -- and exits 1. So
// bignum, charms, orepacks, packs and stats failed SILENTLY: no output, exit 1,
// nothing naming the cause. Five checks that look like five broken checks and
// are really one missing file extension.
//
// One resolver, so the next platform move is one edit instead of six, and
// `missing()` gives the caller a reason to print instead of dying mute.
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "../..");
const BIN = path.join(ROOT, ".luau-bin");

// Windows first on win32: a stale ELF `luau` with no extension can sit beside a
// good `luau.exe`, and picking the extensionless one gets ENOEXEC.
function resolve(tool) {
  const names = process.platform === "win32"
    ? [tool + ".exe", tool]
    : [tool, tool + ".exe"];
  for (const n of names) {
    const p = path.join(BIN, n);
    if (fs.existsSync(p)) {
      return p;
    }
  }
  return null;
}

// An ELF binary on Windows exists and still cannot run, which is exactly the
// state this repo arrived in. Read the magic rather than trusting the name.
function runnableHere(p) {
  if (!p) {
    return false;
  }
  let fd;
  try {
    fd = fs.openSync(p, "r");
    const head = Buffer.alloc(4);
    fs.readSync(fd, head, 0, 4, 0);
    const isELF = head[0] === 0x7f && head[1] === 0x45 && head[2] === 0x4c && head[3] === 0x46;
    const isPE = head[0] === 0x4d && head[1] === 0x5a; // "MZ"
    if (process.platform === "win32") {
      return isPE;
    }
    return !isPE || isELF;
  } catch (e) {
    return false;
  } finally {
    if (fd !== undefined) {
      try { fs.closeSync(fd); } catch (e) { /* nothing to do */ }
    }
  }
}

const LUAU = resolve("luau");
const ANALYZE = resolve("luau-analyze");

// The one line every caller prints when it cannot run. Says which platform it
// needed and what to run, because "skipping" on its own taught nobody anything.
function missing(tool) {
  const want = process.platform === "win32" ? "luau-windows.zip"
    : process.platform === "darwin" ? "luau-macos.zip"
    : "luau-ubuntu.zip";
  const p = resolve(tool);
  if (p && !runnableHere(p)) {
    return tool + " in .luau-bin/ is built for another platform (this is " +
      process.platform + "); delete .luau-bin and run tools/verify/syntax.sh to fetch " + want;
  }
  return tool + " not present in .luau-bin/; run tools/verify/syntax.sh to fetch " + want;
}

module.exports = {
  ROOT,
  BIN,
  LUAU,
  ANALYZE,
  resolve,
  runnableHere,
  missing,
  // True when the interpreter is here AND can actually execute on this box.
  ready: runnableHere(LUAU),
};

//[[ Read Luau source the way the regexes in these checks expect it.
//
// The owner's clone has core.autocrlf=true, so every .luau file on disk is
// CRLF. Every harness here was written in a Linux container against LF and
// pattern-matches with `\n`. `oretools` and `stats` failed outright because of
// it -- "could not find ToolModelFactory.oreLook", which is there at line 260.
//
// The quieter danger is the other way round: a regex that matches NOTHING and
// leaves the check asserting over an empty slice, which passes. Reading through
// here removes the whole class.
function readSrc(p) {
  return require("fs").readFileSync(p, "utf8").split("\r\n").join("\n");
}
module.exports.readSrc = readSrc;
