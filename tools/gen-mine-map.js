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

// ---- the per-band damage step, and where the bands cut --------------------
// Parsed, not restated: TOOL_BAND_DMG and ORE_YIELD_BANDS are the game's own
// tables and a second copy here is a copy that will eventually be wrong.
const bandBlock = cfg.match(/MineConfig\.TOOL_BAND_DMG\s*=\s*\{([\s\S]*?)\n\}/);
const bandDmg = {};
if (bandBlock) {
  for (const m of bandBlock[1].matchAll(/(\w+)\s*=\s*([\d.]+)/g)) bandDmg[m[1]] = Number(m[2]);
}
const bandOrder = (cfg.match(/MineConfig\.ORE_BAND_ORDER\s*=\s*\{([^}]*)\}/) || [, ""])[1]
  .split(",").map((s) => s.trim().replace(/"/g, "")).filter(Boolean);
const bandCuts = [...(cfg.match(/MineConfig\.ORE_YIELD_BANDS\s*=\s*\{([\s\S]*?)\n\}/) || [, ""])[1]
  .matchAll(/upTo\s*=\s*(\d+)/g)].map((m) => Number(m[1]));

// ---- the breaking dials, straight off MineBreaking ------------------------
// Parsed rather than restated: these decide which BLOCKS refuse a swing, and a second
// copy of them here is a copy that will disagree with the game.
const brkSrc = read("src/ReplicatedStorage/Mine/Shared/MineBreaking.luau");
const bnum = (k, dflt) => {
  const m = brkSrc.match(new RegExp("MineBreaking\\." + k + "\\s*=\\s*([\\d.]+)"));
  return m ? Number(m[1]) : dflt;
};
const brk = {
  LAYERS_PER_RUNG: bnum("LAYERS_PER_RUNG", 50),
  ZONE_STEP: bnum("ZONE_STEP", 100),
  ZONES: bnum("ZONES", 10),
  MAX_LAYER: bnum("MAX_LAYER", 5000),
  ORE_POW: bnum("ORE_POW", 1.0),
  ORE_REACH: bnum("ORE_REACH", 15),
};
brk.MAX = 1 + (brk.ZONES - 1) * brk.ZONE_STEP
  + Math.floor((brk.MAX_LAYER - 1) / brk.LAYERS_PER_RUNG);

// ---- the ore spawn dials --------------------------------------------------
const cnum = (k, dflt) => {
  const g = new RegExp("MineConfig\\." + k + "\\s*=\\s*(-?[0-9.eE+-]+)", "g");
  let v = null, m;
  while ((m = g.exec(cfg))) v = Number(m[1]);
  return v === null ? dflt : v;
};
// ORE_DMAX exactly as MineConfig derives it: off Depth.SECTIONS' LAST row,
// which is written in scientific notation, so the capture has to allow it --
// a (\d+) here silently reads `9.30735e+18` as 9.
const depSrc = read("src/ReplicatedStorage/Mine/Shared/MineDepth.luau");
const secHp = [...depSrc.matchAll(/dirtHp = ([0-9.eE+-]+)/g)].map((m) => Number(m[1]));
const topSecHp = secHp.length ? Math.max(...secHp) : 9.30735e18;
const oreDmax = Math.log((topSecHp * 2 * Math.pow(6, 9)) / 20) / Math.log(6);

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
  TIER_SPAN: n("TOOL_TIER_SPAN", 10),
  CLIMB_DMG: n("TOOL_CLIMB_DAMAGE", 350),
  ORE_REACH: n("ORE_REACH", 15),
  // Was a hardcoded 120 here to mirror a hardcoded 120 in toolTierPower --
  // #ORES-1 from the 121-ore roster. Both are fixed; this reads the roster so
  // the map cannot drift from the game the way upgrade-calculator.html did.
  TIER_DIV_LIVE: oreRows.length - 1,
  // Per-band damage step, parsed from TOOL_BAND_DMG rather than restated, and
  // the band cutoffs from ORE_YIELD_BANDS so the map grades ore the way the
  // game does.
  BAND_DMG: bandDmg,
  BAND_CUTS: bandCuts,
  BAND_ORDER: bandOrder,
  // The LIVE HP curve. The map used to read SECTIONS[].dirtHp, which is a
  // retired table -- see the note in depth-sheet-data.js.
  HP_BASE: d.HP_BASE,
  HP_PER_LAYER: d.HP_PER_LAYER,
  // The BREAKING dials, so the page can run the real gate instead of only the
  // ORE_REACH half of it. The verdict used to say "reaches the ore at this
  // depth" off reach alone, which told a tier-1 pick it could mine tier-16 ore
  // at layer 992 -- rock that deep takes zero from a tier-1 swing.
  BRK: brk,
  // The ORE SPAWN curve, so the page can say which ore is actually at a spot
  // instead of guessing from the layer. It was using
  // round(layer / LAYERS * #ores), which ignores the zone entirely -- so it
  // claimed tier-70 ore at layer 4249 in Dirt Meadow and in zone 6 alike, when
  // the real peak in Dirt Meadow is tier 1. Zone is most of the answer: ore
  // difficulty is log(dirtHp/20)/log(6) and dirtHp carries ZONE_HP_MULT^(z-1).
  ORE: {
    DMAX: oreDmax,
    X0: cnum("ORE_X0", -4.2),
    K: cnum("ORE_K", 0.45),
    S: cnum("ORE_S", 4.0),
    W: cnum("ORE_W", 3.0),
    FLOOR: cnum("ORE_MIN_SHARE", 0),
  },
};

const BODY = read("tools/mine-map.body.html");
const html = BODY.replace("/*__MODEL__*/", JSON.stringify(MODEL));

// --check
//
// A generated page that nobody regenerates is worse than no page: it keeps
// answering, in the game's own voice, with the old game's numbers.
//
// This is not hypothetical. TOOL_TIER_SPAN went 16 -> 10 -> 7 on 2026-10-05 and
// the map was regenerated after the first move and not the second, so it spent
// the afternoon showing span 10 -- a tier-30 pick at 6,109 damage where the
// game said 892. The page looked perfectly healthy and every figure on it was
// wrong. Same class as upgrade-calculator.html sitting on 121 ores.
//
// So: --check regenerates into memory and diffs. It does not write.
if (process.argv.includes("--check")) {
  const current = fs.existsSync("tools/mine-map.html") ? read("tools/mine-map.html") : "";
  if (current !== html) {
    console.error("FAIL tools/mine-map.html is stale -- MineConfig/MineDepth have moved" +
      " since it was generated (span " + MODEL.TIER_SPAN + ", climb " + MODEL.CLIMB_DMG +
      ", " + MODEL.ores.length + " ores, cap " + MODEL.MAXLVL + ")." +
      "\n     Run: node tools/depth-sheet-data.js  then  node tools/gen-mine-map.js");
    process.exit(1);
  }
  console.log("ok  mine-map.html matches MineConfig: span " + MODEL.TIER_SPAN +
    ", climb " + MODEL.CLIMB_DMG + ", " + MODEL.ores.length + " ores, cap " + MODEL.MAXLVL);
  process.exit(0);
}

fs.writeFileSync("tools/mine-map.html", html);
console.log("wrote tools/mine-map.html  (" +
  MODEL.sections.length + " sections, " + MODEL.zones.length + " zones, " +
  MODEL.ores.length + " ores, cap " + MODEL.MAXLVL + ")");
