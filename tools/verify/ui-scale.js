// EVERY PANEL, ON EVERY DISPLAY WE ACTUALLY SHIP TO.
//
// Owner, 2026-10-06: "all the scaling is super fucked up... rescale to a
// comfortable scale, and recheck every ui in the game on every single display".
//
// The regression: refreshMineUiScale read `clamp(short / 820, 0.85, 1.45)`,
// where `short` is the SHORTER side of the viewport -- the HEIGHT on any
// landscape monitor. A 1080p desktop therefore scored x1.32 and a 1440p one hit
// the x1.45 cap, so every panel was a third larger than it was drawn. Measured
// live on a 2714x1026 window, the group wheel came out 1476x1206: a panel
// taller than the screen.
//
// A number like that is only wrong in context -- x1.32 looks harmless on its
// own. What makes it checkable is the pairing of a scale rule with the panels
// it has to accommodate, across the displays people really use. So this
// reimplements the shipped rule (parsed from the client, not restated) and
// sweeps it over the real panel sizes.
//
// PANEL SIZES come from a measured snapshot of the live tree, refreshed by the
// Studio probe in the header of ui-panels.json. They are design offsets, so
// they do not depend on whatever scale the measuring session happened to use.
//
// Run: node tools/verify/ui-scale.js
const fs = require("fs");
const path = require("path");
const { readSrc } = require("./_luau.js");

const ROOT = path.join(__dirname, "..", "..");
const CLIENT = readSrc(path.join(ROOT, "src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau"));
const PANELS = JSON.parse(fs.readFileSync(path.join(__dirname, "ui-panels.json"), "utf8"));

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

console.log("ui-scale: the shipped scale rule, swept over every panel and display");

// ---------------------------------------- parse the rule, don't restate it --
const fn = /local function refreshMineUiScale\(\)([\s\S]*?)\nend/.exec(CLIENT);
ok(!!fn, "refreshMineUiScale is findable");
if (!fn) process.exit(1);
const consts = /local DESIGN, LO, HI, PANEL_H = ([\d.]+), ([\d.]+), ([\d.]+), ([\d.]+)/.exec(fn[1]);
ok(!!consts, "its constants are declared on one line and readable");
if (!consts) process.exit(1);
const [DESIGN, LO, HI, PANEL_H] = consts.slice(1).map(Number);
const margin = Number((/\(v\.Y \* ([\d.]+)\) \/ PANEL_H/.exec(fn[1]) || [])[1]);
ok(!!margin, "the fit guard's margin is readable", margin ? `${margin}` : "not found");

console.log(`  rule: DESIGN ${DESIGN}, clamp [${LO}, ${HI}], tallest panel ${PANEL_H}, margin ${margin}`);

// The constants must still describe the real panels.
const tallest = PANELS.panels.reduce((a, p) => Math.max(a, p.h), 0);
ok(PANEL_H >= tallest, "PANEL_H covers the tallest real panel",
  `PANEL_H ${PANEL_H} vs tallest measured ${tallest}`);

// -------------------------------------------------- the shipped rule, in JS --
const scaleFor = (w, h, touch) => {
  const short = Math.min(w, h);
  let s;
  if (touch) s = short < 560 ? 0.78 : short < 700 ? 0.88 : short < 900 ? 0.95 : 1;
  else s = Math.min(HI, Math.max(LO, short / DESIGN));
  return Math.max(0.5, Math.min(s, (h * margin) / PANEL_H));
};

//[[ Real displays. The desktop set is the Steam/Roblox long tail; the phones
// are the common portrait sizes, where `short` is the WIDTH and the old rule
// was accidentally tuned. 2714x1026 is the owner's own window. ]]
const DISPLAYS = [
  { n: "1280x720 laptop", w: 1280, h: 720 },
  { n: "1366x768 laptop", w: 1366, h: 768 },
  { n: "1600x900", w: 1600, h: 900 },
  { n: "1920x1080", w: 1920, h: 1080 },
  { n: "2560x1440", w: 2560, h: 1440 },
  { n: "3840x2160 4K", w: 3840, h: 2160 },
  { n: "2714x1026 owner", w: 2714, h: 1026 },
  { n: "1024x768 4:3", w: 1024, h: 768 },
  { n: "iPhone portrait", w: 375, h: 812, touch: true },
  { n: "iPhone landscape", w: 812, h: 375, touch: true },
  { n: "iPad portrait", w: 768, h: 1024, touch: true },
  { n: "iPad landscape", w: 1024, h: 768, touch: true },
];

//[[ THE INVARIANT IS ABOUT THE RULE, NOT ABOUT EVERY PANEL EVERYWHERE.
//
// A global UIScale cannot rescue a panel that is taller than the screen at the
// smallest readable scale: on a 375-tall phone in landscape, fitting a 964px
// panel needs x0.366, which renders 12px body text at four pixels. That is a
// responsive problem for THAT PANEL -- a max height, or scrolling -- and the
// floor deliberately refuses to trade the whole UI's legibility for it.
//
// So displays split in two. Where the panel COULD fit at or above the floor,
// the rule must make it fit, and failing that is a scale bug. Where it could
// not fit even at the floor, the scale rule is not the thing at fault and the
// display is listed as outstanding panel work instead. Both are printed. ]]
const FLOOR = 0.5;
console.log("");
console.log("  display              scale   tallest panel on screen");
const scaleBugs = [];
const panelWork = [];
for (const d of DISPLAYS) {
  const s = scaleFor(d.w, d.h, d.touch);
  const ph = PANEL_H * s;
  const fixable = PANEL_H * FLOOR <= d.h;
  let flag = "";
  if (ph > d.h) {
    flag = fixable ? "  OVERFLOWS (scale bug)" : "  too tall for this screen at any readable scale";
    (fixable ? scaleBugs : panelWork).push(`${d.n} (${Math.round(ph)} in ${d.h})`);
  }
  console.log(`  ${d.n.padEnd(20)} ${s.toFixed(3)}   ${Math.round(ph)}px of ${d.h}${flag}`);
}
ok(scaleBugs.length === 0,
  "where a panel can fit, the scale rule makes it fit",
  scaleBugs.length ? scaleBugs.join(", ") : `${DISPLAYS.length} displays checked`);
if (panelWork.length) {
  console.log("");
  console.log("  OUTSTANDING, and not fixable by scaling -- these panels need a max");
  console.log("  height or scrolling before they are usable there:");
  for (const w of panelWork) console.log("    " + w);
}

// Comfort: a desktop at the authored resolution should be x1, not inflated.
ok(Math.abs(scaleFor(1920, 1080, false) - 1) < 0.001,
  "1080p desktop renders at exactly x1", scaleFor(1920, 1080, false).toFixed(3));
ok(scaleFor(2560, 1440, false) <= 1.3,
  "1440p is a mild bump, not a third bigger", scaleFor(2560, 1440, false).toFixed(3));
ok(scaleFor(1280, 720, false) >= 0.65,
  "a small laptop stays readable", scaleFor(1280, 720, false).toFixed(3));

// --------------------------------------- per-panel sweep, width included --
//[[ Width is deliberately NOT part of the scale rule -- see the comment on
// refreshMineUiScale -- so panels too wide for a phone are reported here as
// their own responsive problem rather than being allowed to shrink the whole
// UI. This is the list the owner asked for. ]]
console.log("");
const wide = [];
for (const d of DISPLAYS) {
  const s = scaleFor(d.w, d.h, d.touch);
  for (const p of PANELS.panels) {
    if (p.w * s > d.w) wide.push(`${p.n} on ${d.n}`);
  }
}
if (wide.length) {
  console.log("  panels wider than the screen (responsive issues, not scale):");
  for (const w of [...new Set(wide)]) console.log("    " + w);
} else {
  console.log("  no panel is wider than any checked display");
}

console.log("");
console.log(fails === 0 ? ">>> ui-scale OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
