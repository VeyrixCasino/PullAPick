// Pull the real depth model out of MineDepth + MineConfig for the map page.
//
// Every figure here is parsed from source, not restated from a doc: the docs in
// this repo have been wrong about the roster size, the seam blocker and the
// layer ceiling, so nothing is trusted that cannot be read out of the code.
const fs = require("fs");
const path = require("path");
const read = (p) => fs.readFileSync(p, "utf8").split("\r\n").join("\n");

const SHARED = "src/ReplicatedStorage/Mine/Shared";
const depth = read(path.join(SHARED, "MineDepth.luau"));
const cfg = read(path.join(SHARED, "MineConfig.luau"));

// ---- sections: the real block-HP staircase -------------------------------
const secBlock = depth.match(/MineDepth\.SECTIONS\s*=\s*\{[\s\S]*?\n\}/)[0];
const secRe = /\{ id = "([a-z0-9_]+)", name = "([^"]+)", layers = \{ (\d+), (\d+) \}, dirtHp = (\d+), band = "([a-z]+)" \}/g;
const sections = [];
let m;
while ((m = secRe.exec(secBlock))) {
  sections.push({ id: m[1], name: m[2], from: +m[3], to: +m[4], dirtHp: +m[5], band: m[6] });
}

// ---- zones ----------------------------------------------------------------
// Zone rows are multi-line with comment blocks between the fields, so a
// single-line `{ id = .., name = .. }` pattern matches none of the eleven. Take
// the table as a slice and pair each id with the next name within 200 chars.
const zStart = cfg.indexOf("MineConfig.ZONES = {");
const zoneBlock = cfg.slice(zStart, cfg.indexOf("\n}\n", zStart));
const zoneRe = /\bid\s*=\s*"([a-z]+)"[\s\S]{0,200}?\bname\s*=\s*"([^"]+)"/g;
const zones = [];
while ((m = zoneRe.exec(zoneBlock))) zones.push({ id: m[1], name: m[2] });

// ---- constants ------------------------------------------------------------
const last = (re) => { let v = null, x; const g = new RegExp(re, "g");
  while ((x = g.exec(cfg))) v = x[1]; return v; };
const LAYERS = Number(last("MineConfig\\.LAYERS\\s*=\\s*(\\d+)"));
const MINE1 = Number(last("MineConfig\\.MINE1_LAYERS\\s*=\\s*(\\d+)"));
const ZONE_MULT = Number((depth.match(/MineDepth\.ZONE_HP_MULT\s*=\s*([\d.]+)/) || [])[1]);

// THE CURVE THE GAME ACTUALLY USES.
//
// SECTIONS above is labelled "the real block-HP staircase" and it is not. It is
// a stale table from an older curve, carrying an obsolete x2 and a rounding
// snap: it puts Finalite at 1,639,071,525,950 where MineDepth.dirtHp gives
// 7,520 for the same layer. MineDepth.dirtHp does not read SECTIONS at all --
//
//   dirtHp(zone, layer) = (HP_BASE + HP_PER_LAYER * layer) * ZONE_HP_MULT^(zone-1)
//
// so anything that charts HP off SECTIONS is charting a curve the game retired.
// SECTIONS stays in the payload because the map uses its NAMES for the depth
// ribbon, which are still correct; its dirtHp must not be used for arithmetic.
const HP_BASE = Number((depth.match(/MineDepth\.HP_BASE\s*=\s*([\d.]+)/) || [])[1]);
const HP_PER_LAYER = Number((depth.match(/MineDepth\.HP_PER_LAYER\s*=\s*([\d.]+)/) || [])[1]);
const SEAMS = (depth.match(/MineDepth\.SEAMS\s*=\s*\{([^}]*)\}/) || [])[1]
  .split(",").map((s) => Number(s.trim())).filter(Boolean);
const ORE_HP_MULT = Number((cfg.match(/MineConfig\.ORE_HP_MULT\s*=\s*([\d.]+)/) || [])[1]);
const ORE_CHANCE = (cfg.match(/MineConfig\.ORE_CHANCE\s*=\s*([^\n]+)/) || [])[1].trim();

const deepest = sections.length ? sections[sections.length - 1].to : 0;

console.log("sections parsed : " + sections.length + "  covering layers 1-" + deepest);
console.log("zones           : " + zones.length);
console.log("LAYERS (live)   : " + LAYERS + "    MINE1_LAYERS: " + MINE1);
console.log("ZONE_HP_MULT    : x" + ZONE_MULT + " per zone");
console.log("ORE_HP_MULT     : x" + ORE_HP_MULT + "   ORE_CHANCE: " + ORE_CHANCE);
console.log("seams           : " + SEAMS.join(", "));
console.log("");
const reachable = SEAMS.filter((s) => s <= LAYERS);
const beyond = SEAMS.filter((s) => s > LAYERS);
console.log("seams at or above the layer ceiling : " + reachable.join(", "));
console.log("seams BELOW it, unreachable         : " + (beyond.join(", ") || "none"));
console.log("");
console.log("layer    section            band       dirt HP        ore HP");
for (const s of sections.filter((_, i) => i % 12 === 0 || _.to === deepest)) {
  console.log(
    String(s.from).padEnd(9) + s.name.slice(0, 17).padEnd(19) + s.band.padEnd(11) +
    s.dirtHp.toLocaleString("en-US").padStart(14) +
    (s.dirtHp * ORE_HP_MULT).toLocaleString("en-US").padStart(14));
}

fs.mkdirSync("build", { recursive: true });
fs.writeFileSync("build/depth-sheet.json", JSON.stringify(
  { sections, zones, LAYERS, MINE1, ZONE_MULT, SEAMS, ORE_HP_MULT, deepest,
    HP_BASE, HP_PER_LAYER }, null, 1));
console.log("\nwrote build/depth-sheet.json");
