// A stat key that was renamed has to stay readable in old saves.
//
// Owner, 2026-10-04: "rename it". `oreYield` was named for ore QUANTITY and had
// meant blast CHANCE for a long time, so every reader had to know that. 403
// occurrences moved to `blastChance`.
//
// The trap: a stat key is DATA, not just code. It is stored on a saved rune
// (rune.stat) and on a saved gear piece (piece.stat, and every row of
// piece.stats). Renaming the code without migrating those silently zeroes
// whatever a player had rolled.
//
//   node tools/verify/statkeys.js
const fs = require("fs");
const path = require("path");
const ROOT = path.resolve(__dirname, "../..");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8");
const walk = (d, out = []) => {
  for (const e of fs.readdirSync(path.join(ROOT, d), { withFileTypes: true })) {
    const rel = `${d}/${e.name}`;
    if (e.isDirectory()) walk(rel, out);
    else if (e.name.endsWith(".luau")) out.push(rel);
  }
  return out;
};

let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

const stats = read("src/ReplicatedStorage/Mine/Shared/MineStats.luau");
const runes = read("src/ReplicatedStorage/Mine/Shared/MineRunes.luau");
const gear = read("src/ReplicatedStorage/Mine/Shared/MineGear.luau");

// Nothing may still use the old key — except oreYieldFor, which is the genuine
// ore-quantity band table and was deliberately left alone.
// Comments are stripped, and the LEGACY_STAT table is cut out, because both
// MUST still contain the old key — the alias is the whole point of the
// migration, and the comments explain it. The first run of this check flagged
// all three and called them stragglers.
const stripLua = (t) => t
  .replace(/--\[\[[\s\S]*?\]\]/g, "")
  .replace(/--[^\n]*/g, "")
  .replace(/MineStats\.LEGACY_STAT = \{[\s\S]*?\n\}/, "");
const stragglers = [];
for (const f of walk("src")) {
  if (stripLua(read(f)).match(/oreYield(?!For)/)) stragglers.push(f);
}
check(stragglers.length === 0,
  "no bare oreYield left in src/" +
    (stragglers.length ? "  — " + [...new Set(stragglers)].join(", ") : ""));

// ...and the one that stays, stays. Renaming it would have been the real bug.
check(/function MineConfig\.oreYieldFor\(tier\)/.test(
  read("src/ReplicatedStorage/Mine/Shared/MineConfig.luau")),
  "MineConfig.oreYieldFor survives — it really is about ore quantity");

check(/blastChance\s*=\s*\{ label = "Blast Chance"/.test(stats),
  "blastChance is a real stat with the honest label");
check(/MineStats\.LEGACY_STAT = \{[\s\S]*?oreYield = "blastChance"/.test(stats),
  "LEGACY_STAT maps the old key to the new one");
check(/function MineStats\.canonStat\(stat\)/.test(stats), "canonStat exists");

// The two places a stat key is stored in a save.
const rnorm = (runes.match(/function MineRunes\.normalize\(rune\)[\s\S]*?\n^end$/m) || [""])[0];
check(/rune\.stat = MineStats\.canonStat\(rune\.stat\)/.test(rnorm),
  "MineRunes.normalize migrates rune.stat");

const gnorm = (gear.match(/function MineGear\.normalize\(piece\)[\s\S]*?\n^end$/m) || [""])[0];
check(/piece\.stat = MineGear\.canonStat\(piece\.stat\)/.test(gnorm),
  "MineGear.normalize migrates piece.stat");
check(/row\.stat = MineGear\.canonStat\(row\.stat\)/.test(gnorm),
  "...and every row of piece.stats, which boostLines reads first");

// Both normalizers are actually called on load, or none of the above runs.
const server = read("src/ServerScriptService/Mine/MineServer.server.luau");
check(/Runes\.normalize\(r\)/.test(server), "the server normalizes saved runes on load");
check(/Gear\.normalize\(piece\)/.test(server), "...and saved gear pieces");

console.log("");
console.log(fail > 0 ? `>>> statkeys: ${fail} FAILED` : ">>> statkeys: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
