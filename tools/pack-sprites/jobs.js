// Builds the render job list for the pack sprites: 3 sprites per set, one per
// cover, all with theme-colour seals. How good a pack is shows in the game UI
// (stars, tile treatment), not on the wrapper -- owner, 2026-10-10.
//   1-2 star    -> cover 1
//   2.5-3.5     -> cover 2
//   4-5 star    -> cover 3
// Covers are read from art/cover-art/{Set}Coverart{1,2,3}.png; sprites are
// written to art/pack-sprites/{Set}Pack_{label}.png.
//
// Usage: node tools/pack-sprites/jobs.js [outFile]
// render.ps1 calls this itself; you only need it to inspect the job list.
const fs = require("fs");
const os = require("os");
const path = require("path");

const ART = path.join(__dirname, "..", "..", "art");

// [file prefix, seal colour, name printed on the top seal], from sets.js.
const SETS = require("./sets.js").map(s => [s.file, s.accent, s.title]);
const VARIANTS = [
  ["1-2star", 1, "plain"], ["2.5-3.5star", 2, "plain"], ["4-5star", 3, "plain"],
];

const jobs = [];
for (const [set, accent, title] of SETS) {
  for (const [label, cover, style] of VARIANTS) {
    jobs.push({
      cover: path.join(ART, "cover-art", `${set}Coverart${cover}.png`),
      out: path.join(ART, "pack-sprites", `${set}Pack_${label}.png`),
      style,
      accent,
      title,
    });
  }
}

const missing = jobs.filter(j => !fs.existsSync(j.cover)).map(j => j.cover);
if (missing.length) {
  console.error("missing covers:\n  " + [...new Set(missing)].join("\n  "));
  process.exit(1);
}

const out = process.argv[2] || path.join(os.tmpdir(), "mfc-pack-sprite-jobs.json");
fs.writeFileSync(out, JSON.stringify(jobs, null, 2));
console.log(out);
