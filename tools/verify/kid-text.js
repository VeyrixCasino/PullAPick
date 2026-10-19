// THE KID-FRIENDLY TOASTS (owner, 2026-10-12, resumed 2026-10-19: "icons with
// big numbers, 1-3 words").
//
// Runs the real MineKidText.toast in Luau on toasts the server really sends,
// and checks the client runs every toast through it.
//
//   node tools/verify/kid-text.js
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");

const ROOT = path.resolve(__dirname, "../..");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8").replace(/\r\n/g, "\n");
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

if (!Luau.ready) { console.log(Luau.missing("luau") + "; skipping"); process.exit(1); }

const CASES = [
  ["Quest done - 800 Coins", "✅ Quest done!  💰 800"],
  ["Quest done - 60 Gems  +  Unlocks Bronzewedge", "✅ Quest done!  💎 60  +  🔓 Bronzewedge"],
  ["Unlock this zone first", "Unlock this zone first"],
  ["Milestone - 1,000 Gems", "🏆 Milestone!  💎 1,000"],
  ["Gift: 25 Stardust", "🎁 ✨ 25"],
  ["Scrapped pack for 50 gems", "Scrapped pack for 💎 50"],
  ["Tutorial clear — 1,000 gems and 3 legendary packs", "Tutorial clear — 💎 1,000 and 3 legendary packs"],
  ["Charms Pack costs 500 gems (you have 200)", "Charms Pack costs 💎 500 (you have 200)"],
  ["You earned 12.5K coins", "You earned 💰 12.5K"],
  ["10 Credits added", "💵 10 added"],
  // Left alone: no amount right before the word, or a longer word.
  ["Open the Gem Shop", "Open the Gem Shop"],
  ["3 Gemfinder books", "3 Gemfinder books"],
  ["Nothing to sell", "Nothing to sell"],
];

const mod = read("src/ReplicatedStorage/Mine/Shared/MineKidText.luau");
const lua = (s) => '"' + s.replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';
const harness = `
local K = (function()
${mod}
end)()
${CASES.map(([a], i) => `print("C${i}|" .. K.toast(${lua(a)}))`).join("\n")}
`;
const script = path.join(ROOT, ".luau-bin/kid-text-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(Luau.LUAU, [script], { encoding: "utf8" }); }
catch (e) { process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || ""); fail++; }
const lines = out.split(/\r?\n/);
CASES.forEach(([a, want], i) => {
  const got = (lines.find((l) => l.startsWith(`C${i}|`)) || "").slice(`C${i}|`.length);
  check(got === want, `"${a}"  ->  "${got}"` + (got === want ? "" : `  (want "${want}")`));
});

const cl = read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau");
const show = (cl.match(/local function showToast\(t\)[\s\S]*?\nend\n/) || [""])[0];
check(/MineKidText/.test(show) && /t = ClientFns\.KidText\.toast\(t\)/.test(show) && show.indexOf("KidText.toast") < show.indexOf("toast.Text = t"),
  "the client runs every toast through MineKidText before showing it");

console.log("");
console.log(fail > 0 ? `>>> kid-text: ${fail} FAILED` : ">>> kid-text: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
