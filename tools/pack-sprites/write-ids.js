// Turns upload_image results (one JSON object per line on stdin, URL -> asset
// id) into build/pack-art/ids.json, grouped by kind, and checks every art file
// has exactly one id.
//
//   node tools/pack-sprites/write-ids.js < uploads.jsonl
//
// Uploaded 2026-10-10 by the owner's personal account (iPressBars) via Studio
// MCP, then shared with the group experience by the owner.
//
// MERGES into the ids.json already there (2026-10-19). A re-upload of some of
// the files -- the 57 pack sprites re-rendered with a blank top seal, say --
// replaces just those ids; the set icons, the rarity icons and the `cases` art
// (which this script never wrote) keep theirs. Every file must still end up with
// an id from one or the other. The ids that changed are written to
// build/pack-art/share-list-new.txt: the ones the owner must share with the
// experience before they draw in the group place.
const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..", "..");
const ART = path.join(ROOT, "art");
const dest = path.join(ROOT, "build", "pack-art", "ids.json");

const map = {};
for (const line of fs.readFileSync(0, "utf8").split(/\r?\n/)) {
  if (!line.trim()) continue;
  for (const [url, id] of Object.entries(JSON.parse(line))) {
    const rel = url.replace(/^https?:\/\/[^/]+\//, "");
    map[rel] = id; // a later upload of the same file wins
  }
}

// What the last run recorded, as art path -> id, so a partial upload merges.
const prev = fs.existsSync(dest) ? JSON.parse(fs.readFileSync(dest, "utf8")) : {};
const had = {};
for (const [set, bands] of Object.entries(prev.packs || {})) {
  for (const [band, id] of Object.entries(bands)) had[`art/pack-sprites/${set}Pack_${band}.png`] = id;
}
for (const [set, id] of Object.entries(prev.sets || {})) had[`art/icons/sets/${set}SetIcon.png`] = id;
for (const [r, id] of Object.entries(prev.rarity || {})) had[`art/icons/rarity/Rarity_${r}.png`] = id;

const out = Object.assign({ uploadedBy: "user 465369561 (iPressBars), shared with group 35326298" }, prev,
  { packs: {}, sets: {}, rarity: {} });
const missing = [];
const want = [];
const fresh = [];
for (const f of fs.readdirSync(path.join(ART, "pack-sprites")).filter(f => /Pack_.*\.png$/.test(f))) want.push(`art/pack-sprites/${f}`);
for (const f of fs.readdirSync(path.join(ART, "icons", "sets")).filter(f => f.endsWith(".png"))) want.push(`art/icons/sets/${f}`);
for (const f of fs.readdirSync(path.join(ART, "icons", "rarity")).filter(f => f.endsWith(".png"))) want.push(`art/icons/rarity/${f}`);

for (const rel of want.sort()) {
  const id = map[rel] || had[rel];
  if (!id) { missing.push(rel); continue; }
  if (map[rel] && map[rel] !== had[rel]) fresh.push([id, rel]);
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
fs.mkdirSync(path.dirname(dest), { recursive: true });
fs.writeFileSync(dest, JSON.stringify(out, null, 2) + "\n");
const n = want.length, uniq = new Set(want.map(w => map[w] || had[w])).size;
console.log(`wrote ${dest}: ${n} files, ${uniq} distinct ids, ${fresh.length} new`);
if (fresh.length) {
  const share = path.join(ROOT, "build", "pack-art", "share-list-new.txt");
  const lines = fresh.map(([id, rel]) => `${String(id).replace(/^rbxassetid:\/\//, "")}\t${path.basename(rel, ".png")}`);
  fs.writeFileSync(share, "# New asset ids to share with the experience (write-ids.js)\n" + lines.join("\n") + "\n");
  console.log(`wrote ${share}: ${fresh.length} ids to share`);
}
