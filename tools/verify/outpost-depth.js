// Outposts must look deeper the deeper they are.
//
// Owner, 2026-10-05: "do each outpost from 1-10 look deeper and deeper". They
// did not -- seam 500, 2500 and 5000 were byte-identical, because every outpost
// is the same surface template cloned to a different Y and every colour in
// MineDepthPlazas was a constant. docs/OPEN.md item 6 had asked for
// "underground-themed, deeper and darker at every seam" since it was written.
//
// This guards the WIRING, not the palette. The palette is a feel decision and
// belongs to the owner; what must not happen again is the colours quietly going
// back to constants, which is the state this started in and the state nothing
// would have noticed.
//
// Run: node tools/verify/outpost-depth.js
const path = require("path");
const { readSrc } = require("./_luau.js");
const ROOT = path.join(__dirname, "..", "..");
const src = readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineDepthPlazas.luau"));

let fails = 0, checks = 0;
const ok = (c, msg, detail) => {
  checks++;
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

console.log("outpost-depth: the look must vary with seam, not sit on constants");

ok(/local function depthLook\(seam\)/.test(src),
  "depthLook(seam) exists");
ok(/local function tintOutpostLights\(folder, look\)/.test(src),
  "tintOutpostLights exists to reach the surface clone's own lights");

// The walls and the bay deck must take their colour from the look, not a literal.
const wallFn = (src.match(/local function wallOutpost\([\s\S]*?\n^end$/m) || [""])[0];
ok(/local look = depthLook\(seam\)/.test(wallFn),
  "wallOutpost asks depthLook for its palette");
ok(/local col = look\.wall/.test(wallFn),
  "wall colour comes from the look",
  /Color3\.fromRGB\(48, 42, 36\)/.test(wallFn) ? "still has the old constant" : "");
ok(/deck\.Color = look\.deck/.test(wallFn),
  "bay deck colour comes from the look");

// wallOutpost must actually receive a seam at every call site, or depthLook
// silently falls back to the shallowest look everywhere.
const calls = [...src.matchAll(/wallOutpost\(([^)]*)\)/g)]
  .map((m) => m[1].trim())
  .filter((a) => !a.startsWith("folder, zone, seam") || true);
const bad = calls.filter((a) => a !== "folder, zone, seam" && !/^\w+, zone, seam$/.test(a));
ok(bad.length === 0,
  "every wallOutpost call passes a seam",
  bad.length === 0 ? calls.length + " call sites" : "missing seam: " + bad.join(" | "));

// And the lights have to be tinted wherever the walls are built.
const tintCalls = (src.match(/tintOutpostLights\(/g) || []).length - 1; // minus the definition
ok(tintCalls >= 2,
  "lights are tinted at every build path",
  tintCalls + " call sites, " + (calls.length) + " wallOutpost sites");

// Monotonicity: the mapping has to be built from a clamped 0..1 of the seam, so
// a deeper outpost can never come out brighter than a shallower one.
ok(/math\.clamp\(\(\(tonumber\(seam\)[\s\S]{0,80}?\/ span, 0, 1\)/.test(src),
  "the look is driven by a clamped 0..1 across the ladder",
  "an unclamped or non-monotone input is how a deep outpost ends up brighter");

// The light dimming must bottom out -- an outpost is somewhere you read prices.
const floorMatch = src.match(/lightMul = mix\(1,\s*([\d.]+)\)/);
const lightFloor = floorMatch ? Number(floorMatch[1]) : 0;
ok(lightFloor >= 0.4,
  "light dimming bottoms out above 40%",
  "bottoms at " + (lightFloor * 100).toFixed(0) + "% -- atmosphere stops where usability starts");

// Neon is wayfinding and must stay out of it.
ok(!/look\.\w*\s*.{0,40}Neon/i.test(src) && !/Neon[\s\S]{0,60}look\./.test(src),
  "neon is left alone",
  "the cyan ring and signage are how a player finds the elevator");

// LAYOUT_VER has to move, or no existing outpost ever re-dresses.
const ver = Number((src.match(/^local LAYOUT_VER = (\d+)/m) || [, 0])[1]);
ok(ver >= 7, "LAYOUT_VER is bumped so built outposts re-dress", "LAYOUT_VER = " + ver);

console.log(fails === 0 ? ">>> outpost-depth: all " + checks + " checks passed"
  : ">>> outpost-depth: " + fails + " of " + checks + " FAILED");
process.exit(fails === 0 ? 0 : 1);
