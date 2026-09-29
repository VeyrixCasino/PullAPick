// Generate MineConfig.ORES from docs/ore-remake.md, and work out the save
// migration the swap needs. Run with --write to apply; default is a dry run.
const fs = require("fs"), path = require("path");
const ROOT = path.join(__dirname, "..");
const DOC = path.join(ROOT, "docs", "ore-remake.md");
const CFG = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau");

// ---- parse the first python LOOKS block (the main 121) ----
const doc = fs.readFileSync(DOC, "utf8").split("\r\n").join("\n");
const blocks = [...doc.matchAll(/```python\n([\s\S]*?)```/g)].map(m => m[1]);
if (!blocks.length) throw new Error("no python block in ore-remake.md");

const LINE = /^\s*"([^"]+)"\s*:\s*\(\((\d+),\s*(\d+),\s*(\d+)\),\s*([\d.]+),\s*([\d.]+),\s*(None|\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)),\s*"([^"]+)",\s*"([^"]*)"\),\s*#\s*(\d+)/;

function parse(src) {
  const out = [];
  for (const raw of src.split("\n")) {
    const m = raw.match(LINE);
    if (!m) continue;
    out.push({
      name: m[1],
      rgb: [+m[2], +m[3], +m[4]],
      met: parseFloat(m[5]),
      rough: parseFloat(m[6]),
      glow: m[7] === "None" ? null : { rgb: [+m[8], +m[9], +m[10]], bright: parseFloat(m[11]) },
      material: m[12],
      desc: m[13],
      tier: +m[14]
    });
  }
  return out;
}
const ores = parse(blocks[0]);

// ---- ids: lowercase, non-alphanumeric collapses to _ ----
function toId(name) {
  return name.toLowerCase().replace(/['']/g, "").replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "");
}
ores.forEach(o => o.id = toId(o.name));

// ---- sanity ----
const errs = [];
if (ores.length !== 121) errs.push("parsed " + ores.length + " ores, expected 121");
ores.forEach((o, i) => { if (o.tier !== i + 1) errs.push("tier gap at " + o.name + ": " + o.tier + " != " + (i + 1)); });
const seen = new Map();
ores.forEach(o => { if (seen.has(o.id)) errs.push("duplicate id " + o.id + " (" + seen.get(o.id) + " / " + o.name + ")"); seen.set(o.id, o.name); });

// materials Roblox actually has
const MATS = new Set(["Rock","Cobblestone","Mud","Sandstone","Limestone","Concrete","Salt","Slate",
  "Basalt","Plaster","Granite","Metal","Pebble","CorrodedMetal","CrackedLava","Sand","DiamondPlate",
  "Foil","Glass","Marble","SmoothPlastic","Ice","Wood","ForceField","Neon","Glacier","Ground"]);
ores.forEach(o => { if (!MATS.has(o.material)) errs.push("unknown material " + o.material + " on " + o.name); });

// ---- the old roster, straight out of the live file ----
const cfg = fs.readFileSync(CFG, "utf8");
const CRLF = cfg.indexOf("\r\n") >= 0;
const cfgLines = cfg.split("\r\n").join("\n").split("\n");
const start = cfgLines.findIndex(l => l.startsWith("MineConfig.ORES = {"));
if (start < 0) throw new Error("ORES table not found");
let end = start;
while (end < cfgLines.length && cfgLines[end].trim() !== "}") end++;
const oldIds = [];
for (let i = start + 1; i < end; i++) {
  const m = cfgLines[i].match(/id = "([^"]+)".*?name = "([^"]+)".*?tier = (\d+)/);
  if (m) oldIds.push({ id: m[1], name: m[2], tier: +m[3] });
}

// ---- migration: every old id must land somewhere ----
// The doc's replacement tables, resolved through their chains.
const CHAIN = {
  steel: "bismuth", damascus_steel: "labradorite", cast_iron: "sulfur",
  meteoric_iron: "iridium", bronze: "cinnabar", brass: "tigers_eye",
  pewter: "lapis_lazuli", vanadium_steel: "osmium", brick: "pumice",
  charcoal: "rock_salt", alumina: "selenite", silicon_nitride: "rhodochrosite",
  boron_nitride: "starmetal", graphene: "galaxyrock", prismarine: "frostfire_crystal",
  boron_carbide: "phoenix_stone",
  // round 2
  halite: "rock_salt", lignite: "coal", bituminous_coal: "emberstone",
  sphalerite: "aluminum", anthracite: "pearl", bauxite: "frost_crystal",
  dunite: "bloodstone", shungite: "geode", wolframite: "stormstone",
  ilmenite: "lithium", impactite: "moon_rock", musgravite: "phoenix_stone",
  benitoite: "starmetal", monazite: "aether_crystal", pallasite: "soulstone",
  grandidierite: "galaxyrock", painite: "frostfire_crystal",
  coesite: "shadow_shard", stishovite: "celestial_crystal",
  ringwoodite: "rainbow_crystal", bridgmanite: "dragonstone",
  silicon_carbide: "moissanite"
};
const newIds = new Set(ores.map(o => o.id));
const migration = {}, unmapped = [];
for (const o of oldIds) {
  if (newIds.has(o.id)) continue;            // survives, nothing to do
  const to = CHAIN[o.id];
  if (to && newIds.has(to)) migration[o.id] = to;
  else unmapped.push(o.id + (to ? " -> " + to + " (target missing!)" : ""));
}

// ---- report ----
console.log("parsed " + ores.length + " ores from the doc");
console.log("old roster: " + oldIds.length + " ores");
const survive = oldIds.filter(o => newIds.has(o.id)).length;
console.log("  survive by id : " + survive);
console.log("  need migration: " + Object.keys(migration).length);
console.log("  UNMAPPED      : " + unmapped.length + (unmapped.length ? "  " + unmapped.join(", ") : ""));
const brandNew = ores.filter(o => !oldIds.some(x => x.id === o.id)).map(o => o.name);
console.log("brand new ores (" + brandNew.length + "): " + brandNew.join(", "));
if (errs.length) { console.log("\nERRORS:"); errs.forEach(e => console.log("  " + e)); }

// ---- emit ----
function luaColor(rgb) { return "Color3.fromRGB(" + rgb.join(", ") + ")"; }
function num(x) {
  const s = String(x);
  return s.startsWith("0.") ? s.slice(1) : s;      // match the file's .9 style
}
const body = ores.map(o => {
  let s = "\t{ id = \"" + o.id + "\", name = \"" + o.name + "\", tier = " + o.tier +
    ", color = " + luaColor(o.rgb) + ", material = Enum.Material." + o.material +
    ", met = " + num(o.met) + ", rough = " + num(o.rough);
  if (o.glow) s += ", glow = " + luaColor(o.glow.rgb) + ", glowBright = " + o.glow.bright;
  if (/rainbow/i.test(o.desc)) s += ", rainbow = true";
  return s + " },";
}).join("\n");

const migLines = Object.entries(migration)
  .sort((a, b) => a[0].localeCompare(b[0]))
  .map(([k, v]) => "\t" + k + " = \"" + v + "\",").join("\n");

const out = {
  ores: "MineConfig.ORES = {\n" + body + "\n}",
  migration:
`--[[
	Ore ids that no longer exist, and what a save holding one becomes.

	Ore ids are load-bearing in two places: p.ores[id] is banked stardust-worth
	of material, and every ore pack is "<id>_ore_pack". Dropping an id without a
	map silently deletes both, so the roster swap ships with this table and a
	one-time pass over the profile on load.

	Chains are already resolved -- charcoal went to halite and halite went to
	rock_salt, so charcoal maps straight to rock_salt.
]]
MineConfig.ORE_MIGRATION = {
${migLines}
}`
};

// ---- has the live table moved past what this generator can express? ----
//
// This writes id/name/tier/colour/material/met/rough/glow and nothing else, from
// a doc that is a snapshot of one moment. Two later commits went further than
// that doc, so a --write today is not a regeneration, it is a revert:
//
//   72b81ed renamed 14 ores. docs/ore-remake.md still says "Rock Salt",
//           "Tiger's Eye", "Frostfire Crystal", "Galaxyrock"; the live table
//           says halite, tigereye, frostfire, galaxite.
//   the 82-cut dropped 39 ores and put `band`, `home` and `yield` on every row.
//           This emitter knows about none of those three, and the doc still
//           holds all 121.
//
// So the roster is now authored in MineConfig.luau, and the doc is history. The
// checks below refuse rather than silently undo that. If the generator is ever
// meant to lead again, teach it the new columns first and re-snapshot the doc.
const liveHasBand = cfgLines.slice(start, end).some(l => /\bband = "/.test(l));
const liveHasHome = cfgLines.slice(start, end).some(l => /\bhome = /.test(l));
const liveCount = oldIds.length;
const drift = [];
if (liveHasBand || liveHasHome) {
  drift.push("live rows carry " + [liveHasBand && "band", liveHasHome && "home"]
    .filter(Boolean).join(" and ") + ", which this generator does not emit");
}
if (liveCount !== ores.length) {
  drift.push("live table has " + liveCount + " ores, the doc has " + ores.length);
}
for (const [was, now] of [["rock_salt", "halite"], ["tigers_eye", "tigereye"],
                          ["frostfire_crystal", "frostfire"], ["galaxyrock", "galaxite"]]) {
  // Drift is: the DOC still carries the old id while the LIVE table has the new
  // one. (Written the other way round first, which made this check silently
  // never fire on the 121-row table it exists to protect.)
  if (seen.has(was) && oldIds.some(o => o.id === now)) {
    drift.push("doc still calls " + now + " by its old name (" + was + ")");
  }
}
if (drift.length) {
  console.log("\nGENERATOR IS BEHIND THE LIVE TABLE:");
  drift.forEach(d => console.log("  - " + d));
  console.log("\n  The roster is authored in MineConfig.luau now; this doc is a snapshot.");
  console.log("  Writing would revert work, so --write is refused. Pass --force-stale");
  console.log("  only if you have just taught this script the new columns.");
}

if (process.argv.includes("--write")) {
  if (drift.length && !process.argv.includes("--force-stale")) { process.exit(1); }
  if (errs.length) { console.log("\nrefusing to write with errors above"); process.exit(1); }
  if (unmapped.length) { console.log("\nrefusing to write with unmapped ids"); process.exit(1); }
  const next = cfgLines.slice(0, start).concat(
    out.ores.split("\n"), "", out.migration.split("\n"), cfgLines.slice(end + 1)).join("\n");
  fs.writeFileSync(CFG, CRLF ? next.split("\n").join("\r\n") : next);
  console.log("\nwritten to MineConfig.luau");
} else {
  console.log("\n--- first 3 emitted ---");
  console.log(body.split("\n").slice(0, 3).join("\n"));
  console.log("--- last 2 ---");
  console.log(body.split("\n").slice(-2).join("\n"));
  console.log("\n--- migration (" + Object.keys(migration).length + " entries) ---");
  console.log(migLines || "(none)");
  console.log("\ndry run. re-run with --write to apply.");
}
