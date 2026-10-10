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

// [file prefix, seal colour, name printed on the top seal]
const SETS = [
  ["Pebblebound", "#9a6b3f", "PEBBLEBOUND"], ["SugarRush", "#ff6fae", "SUGAR RUSH"],
  ["Mosswood", "#4e9a3c", "MOSSWOOD"], ["LostAndFound", "#b9832f", "LOST & FOUND"],
  ["Starfront", "#3f78e0", "STARFRONT"], ["ArcadeLegends", "#c23cff", "ARCADE LEGENDS"],
  ["CrystalHollow", "#8a5cff", "CRYSTAL HOLLOW"], ["ShogunsOath", "#d6334a", "SHOGUN'S OATH"],
  ["RoyalReserve", "#1f7a52", "ROYAL RESERVE"], ["CrimsonEclipse", "#b0142e", "CRIMSON ECLIPSE"],
  ["HoloHavoc", "#8fb3ff", "HOLO HAVOC"], ["RainbowRoad", "#ff7ed4", "RAINBOW ROAD"],
  ["InfernalReign", "#e8501c", "INFERNAL REIGN"], ["AtlantisRising", "#12b5b0", "ATLANTIS RISING"],
  ["DivineRelics", "#7a62e0", "DIVINE RELICS"], ["Dragonfall", "#d0631c", "DRAGONFALL"],
  ["EternalRoots", "#1fa07c", "ETERNAL ROOTS"], ["MythicMenagerie", "#6a46d6", "MYTHIC MENAGERIE"],
  ["ChaosTheory", "#19c8ff", "CHAOS THEORY"],
];
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
