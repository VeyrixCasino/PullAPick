// Turns upload_image results (one JSON object per line on stdin, URL -> asset
// id) into build/pack-art/ids.json, grouped by kind, and checks every art file
// has exactly one id.
//
//   node tools/pack-sprites/write-ids.js < uploads.jsonl
//
// Uploaded 2026-10-10 by the owner's personal account (iPressBars) via Studio
// MCP, then shared with the group experience by the owner.
const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..", "..");
const ART = path.join(ROOT, "art");

const map = {};
for (const line of fs.readFileSync(0, "utf8").split(/\r?\n/)) {
  if (!line.trim()) continue;
  for (const [url, id] of Object.entries(JSON.parse(line))) {
    const rel = url.replace(/^https?:\/\/[^/]+\//, "");
    map[rel] = id; // a later upload of the same file wins
  }
}

const out = { uploadedBy: "user 465369561 (iPressBars), shared with group 35326298", packs: {}, sets: {}, rarity: {} };
const missing = [];
const want = [];
for (const f of fs.readdirSync(path.join(ART, "pack-sprites")).filter(f => /Pack_.*\.png$/.test(f))) want.push(`art/pack-sprites/${f}`);
for (const f of fs.readdirSync(path.join(ART, "icons", "sets")).filter(f => f.endsWith(".png"))) want.push(`art/icons/sets/${f}`);
for (const f of fs.readdirSync(path.join(ART, "icons", "rarity")).filter(f => f.endsWith(".png"))) want.push(`art/icons/rarity/${f}`);

for (const rel of want.sort()) {
  const id = map[rel];
  if (!id) { missing.push(rel); continue; }
  const base = path.basename(rel, ".png");
  let m;
  if ((m = base.match(/^(.+)Pack_(.+)$/))) (out.packs[m[1]] ||= {})[m[2]] = id;
  else if ((m = base.match(/^(.+)SetIcon$/))) out.sets[m[1]] = id;
  else if ((m = base.match(/^Rarity_(.+)$/))) out.rarity[m[1]] = id;
}

if (missing.length) {
  console.error("no id for:\n  " + missing.join("\n  "));
  process.exit(1);
}
const dest = path.join(ROOT, "build", "pack-art", "ids.json");
fs.mkdirSync(path.dirname(dest), { recursive: true });
fs.writeFileSync(dest, JSON.stringify(out, null, 2) + "\n");
const n = want.length, uniq = new Set(want.map(w => map[w])).size;
console.log(`wrote ${dest}: ${n} files, ${uniq} distinct ids`);
