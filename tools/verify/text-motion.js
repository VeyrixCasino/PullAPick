// TEXT NEVER RIDES A SCALE ANIMATION (owner, 2026-10-14 and 2026-10-17:
// "the font sizes flicker").
//
// Roblox draws text at whole font sizes, so a UIScale easing over a label
// steps it a pixel at a time instead of growing it. A looping pulse or a pop
// that restarts on every number change turns that stepping into a constant
// flicker. The kit (MineUI) is where every pulse and number pop comes from, so
// this pins the kit's rules in place:
//
//   1. pulse() sends anything that carries text to the ring pulse, which
//      scales a text-free ring and never the thing itself
//   2. popNumber() lights an outline; it never pops a size
//   3. carriesText is declared before both (Luau locals are positional)
//   4. the Forge repaints on a snapshot only on a real change, at most about
//      once a second, instead of rebuilding every card ten times a second
//
//   node tools/verify/text-motion.js
"use strict";
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "../..");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8").replace(/\r\n/g, "\n");
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };
const body = (src, head, endMark = "\nend\n") => {
  const i = src.indexOf(head);
  if (i < 0) return "";
  const j = src.indexOf(endMark, i);
  return src.slice(i, j < 0 ? undefined : j);
};

const ui = read("src/ReplicatedStorage/Mine/Shared/MineUI.luau");
const pulse = body(ui, "function MineUI.pulse(");
const pop = body(ui, "function MineUI.popNumber(");
const ringAt = ui.indexOf("local function ringPulse(");
const ring = ringAt < 0 ? "" : ui.slice(ringAt, ui.indexOf("function MineUI.pulse(", ringAt));

// 1. pulse
const gate = pulse.indexOf("if carriesText(inst) then");
check(gate > 0 && gate < pulse.indexOf('channel(inst, "pulse")') && /return ringPulse\(inst, amount, period\)/.test(pulse),
  "pulse() hands anything with text to the ring pulse before it touches the scale channel");
check(ring !== "" && !/channel\(/.test(ring) && /Name = "PulseRing"/.test(ring) && /UIScale", \{ Scale = 1 \}, ring\)/.test(ring),
  "the ring pulse scales its own text-free ring, never the pulsed instance");
check(/UIGridStyleLayout/.test(ring), "a pulsed parent with a layout gets an outline glow, not a ring that would join the layout");

// 2. popNumber
check(pop !== "" && !/MineUI\.pop\(/.test(pop) && !/channel\(/.test(pop) && /UIStroke/.test(pop),
  "popNumber() lights the label's outline and never pops its size");

// 3. order
const decl = ui.indexOf("local function carriesText(");
check(decl > 0 && decl < ui.indexOf("function MineUI.popNumber(") && decl < ringAt && ringAt < ui.indexOf("function MineUI.pulse("),
  "carriesText and ringPulse are declared above popNumber and pulse");

// 4. the Forge
const hub = read("src/ReplicatedStorage/Mine/Shared/MineForgeHub.luau");
const onSnap = body(hub, "\tfunction ctl.onSnapshot(", "\n\tend\n");
const hubClient = read("src/StarterPlayer/StarterPlayerScripts/MineForgeHub.client.luau");
check(/sig == lastSig/.test(onSnap) && /1 - \(os\.clock\(\) - lastPaint\)/.test(onSnap) && /busyUntil > 0/.test(onSnap),
  "the Forge's onSnapshot skips unchanged snapshots, waits about a second between repaints, and repaints at once for a pending action");
check(/lastSig, lastPaint = signature\(\), os\.clock\(\)/.test(body(hub, "\tfunction ctl.refresh(", "\n\tend\n")),
  "every Forge repaint records what it painted");
check(/hub\.onSnapshot/.test(hubClient) && !/pcall\(hub\.refresh\)/.test(hubClient),
  "MineForgeHub.client sends snapshots through onSnapshot, not straight to refresh");

console.log("");
console.log(fail > 0 ? `>>> text-motion: ${fail} FAILED` : ">>> text-motion: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
