// Apply the approved ore renames and REGENERATE the save migration from the
// original roster, rather than hand-patching targets that moved.
const fs = require("fs"), path = require("path"), cp = require("child_process");
const ROOT = path.join(__dirname, "..");
const CFG = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau");
const BASE_COMMIT = "566eecf";     // the import, before any roster work

// name -> new name. "keep" rows are simply absent.
const RENAME = {
  "Rock Salt": "Halite",
  "Emberstone": "Ember",
  "Frost Crystal": "Rime",
  "Petrified Wood": "Petrifact",
  "Tiger's Eye": "Tigereye",
  "Lapis Lazuli": "Lapis",
  "Phoenix Stone": "Emberglass",
  "Moon Rock": "Regolith",
  "Aether Crystal": "Aetherite",
  "Galaxyrock": "Galaxite",
  "Frostfire Crystal": "Frostfire",
  "Shadow Shard": "Umbrite",
  "Celestial Crystal": "Celestine",
  "Rainbow Crystal": "Spectrite"
};

// Retired original ids -> where a save holding one lands, in FINAL names.
const CHAIN = {
  steel: "Bismuth", damascus_steel: "Labradorite", cast_iron: "Sulfur",
  meteoric_iron: "Iridium", bronze: "Cinnabar", brass: "Tigereye",
  pewter: "Lapis", vanadium_steel: "Osmium", brick: "Pumice",
  charcoal: "Halite", alumina: "Selenite", silicon_nitride: "Rhodochrosite",
  boron_nitride: "Starmetal", graphene: "Galaxite", prismarine: "Frostfire",
  boron_carbide: "Emberglass", halite: "Halite", lignite: "Coal",
  bituminous_coal: "Ember", sphalerite: "Aluminum", anthracite: "Pearl",
  bauxite: "Rime", dunite: "Bloodstone", shungite: "Geode",
  wolframite: "Stormstone", ilmenite: "Lithium", impactite: "Regolith",
  musgravite: "Emberglass", benitoite: "Starmetal", monazite: "Aetherite",
  pallasite: "Soulstone", grandidierite: "Galaxite", painite: "Frostfire",
  coesite: "Umbrite", stishovite: "Celestine", ringwoodite: "Spectrite",
  bridgmanite: "Dragonstone", silicon_carbide: "Moissanite",
  // Survived the roster swap under its old id, so live saves hold it; the
  // rename retires that id and it needs somewhere to land like any other.
  petrified_wood: "Petrifact"
};

const toId = n => n.toLowerCase().replace(/['']/g, "").replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "");

function oresOf(text) {
  const lines = text.split("\r\n").join("\n").split("\n");
  const a = lines.findIndex(l => l.startsWith("MineConfig.ORES = {"));
  if (a < 0) throw new Error("no ORES table");
  let e = a; while (lines[e].trim() !== "}") e++;
  const rows = [];
  for (let i = a + 1; i < e; i++) {
    const m = lines[i].match(/id = "([^"]+)", name = "([^"]+)"/);
    if (m) rows.push({ line: i, raw: lines[i], id: m[1], name: m[2] });
  }
  return { lines, a, e, rows };
}

// ---- 1. rename in place ----
const raw = fs.readFileSync(CFG, "utf8");
const CRLF = raw.indexOf("\r\n") >= 0;
const cur = oresOf(raw);
let renamed = 0;
const applied = [];
for (const r of cur.rows) {
  const to = RENAME[r.name];
  if (!to) continue;
  const newId = toId(to);
  cur.lines[r.line] = r.raw
    .replace('id = "' + r.id + '"', 'id = "' + newId + '"')
    .replace('name = "' + r.name + '"', 'name = "' + to + '"');
  applied.push(r.name + " -> " + to + "  (" + r.id + " -> " + newId + ")");
  renamed++;
}
const missing = Object.keys(RENAME).filter(n => !cur.rows.some(r => r.name === n));
if (missing.length) throw new Error("rename targets not in roster: " + missing.join(", "));

// final roster
const finalIds = new Set(cur.rows.map(r => RENAME[r.name] ? toId(RENAME[r.name]) : r.id));

// ---- 2. regenerate the migration against the ORIGINAL roster ----
const orig = oresOf(cp.execSync("git show " + BASE_COMMIT + ":src/ReplicatedStorage/Mine/Shared/MineConfig.luau",
  { cwd: ROOT, maxBuffer: 64 * 1024 * 1024 }).toString("utf8"));

const migration = {}, problems = [];
for (const o of orig.rows) {
  if (finalIds.has(o.id)) continue;                 // survives by id
  const toName = CHAIN[o.id];
  if (!toName) { problems.push("unmapped: " + o.id); continue; }
  const toIdv = toId(toName);
  if (!finalIds.has(toIdv)) { problems.push(o.id + " -> " + toIdv + " (target not in roster)"); continue; }
  if (toIdv === o.id) { problems.push("IDENTITY: " + o.id); continue; }
  migration[o.id] = toIdv;
}

console.log("renamed " + renamed + " ores:");
applied.forEach(a => console.log("  " + a));
console.log("\noriginal roster " + orig.rows.length + ", final " + cur.rows.length);
console.log("  survive by id : " + orig.rows.filter(o => finalIds.has(o.id)).length);
console.log("  migrate       : " + Object.keys(migration).length);
if (problems.length) { console.log("\nPROBLEMS:\n  " + problems.join("\n  ")); process.exit(1); }

// identity check, the one that would double-then-delete a save
for (const [k, v] of Object.entries(migration)) if (k === v) throw new Error("identity " + k);

// ---- 3. write ----
const migLines = Object.entries(migration).sort((a, b) => a[0].localeCompare(b[0]))
  .map(([k, v]) => "\t" + k + ' = "' + v + '",').join("\n");
let out = cur.lines.join("\n");
const ms = out.indexOf("MineConfig.ORE_MIGRATION = {");
if (ms < 0) throw new Error("no migration table");
let me = out.indexOf("\n}", ms);
out = out.slice(0, ms) + "MineConfig.ORE_MIGRATION = {\n" + migLines + out.slice(me);

if (process.argv.includes("--write")) {
  fs.writeFileSync(CFG, CRLF ? out.split("\n").join("\r\n") : out);
  console.log("\nwritten.");
} else {
  console.log("\nmigration would be:\n" + migLines);
  console.log("\ndry run. --write to apply.");
}
