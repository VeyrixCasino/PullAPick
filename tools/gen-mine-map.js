// Generate tools/mine-map.html from the live config.
//
// Regenerated rather than hand-edited, so it cannot drift the way
// tools/upgrade-calculator.html did (still 121 ores and a 1000 level cap while
// the game moved to 82 and 100). Run it again after any balance change:
//
//   node tools/depth-sheet-data.js
//   node tools/gen-mine-map.js
const fs = require("fs");
const path = require("path");
const read = (p) => fs.readFileSync(p, "utf8").split("\r\n").join("\n");

const d = JSON.parse(fs.readFileSync("build/depth-sheet.json", "utf8"));
const cfg = read("src/ReplicatedStorage/Mine/Shared/MineConfig.luau");

const n = (k, dflt) => {
  const g = new RegExp("MineConfig\\." + k + "\\s*=\\s*([0-9.eE+]+)", "g");
  let v = null, x;
  while ((x = g.exec(cfg))) v = Number(x[1]);
  return v === null ? dflt : v;
};

// ---- the ore roster, for tier -> name on the tool side -------------------
const oreRows = cfg.match(/MineConfig\.ORES = \{([\s\S]*?)\n\}/)[1]
  .split("\n").filter((l) => /\{\s*id = "/.test(l))
  .map((l) => (l.match(/name = "([^"]+)"/) || [])[1]);

const MODEL = {
  sections: d.sections,
  zones: d.zones,
  seams: d.SEAMS,
  LAYERS: d.LAYERS,
  MINE1: d.MINE1,
  ZONE_MULT: d.ZONE_MULT,
  ORE_HP_MULT: d.ORE_HP_MULT,
  ores: oreRows,
  MAXLVL: n("TOOL_MAX_LEVEL", 100),
  DMG_BASE: n("TOOL_DMG_BASE", 10),
  TIER_SPAN: n("TOOL_TIER_SPAN", 16),
  CLIMB_DMG: n("TOOL_CLIMB_DAMAGE", 3.9e8),
  ORE_REACH: n("ORE_REACH", 15),
  // The live divisor is a hardcoded 120 -- #ORES-1 from the 121-ore roster.
  TIER_DIV_LIVE: 120,
};

const BODY = read("tools/mine-map.body.html");
const html = BODY.replace("/*__MODEL__*/", JSON.stringify(MODEL));
fs.writeFileSync("tools/mine-map.html", html);
console.log("wrote tools/mine-map.html  (" +
  MODEL.sections.length + " sections, " + MODEL.zones.length + " zones, " +
  MODEL.ores.length + " ores, cap " + MODEL.MAXLVL + ")");
