// TWO QUEST FIXES (2026-10-19, the Candy Crypt v2 round's small calls).
//
//   * Chain rung `forge1` ("Forge a tool out of ore") asked again what rung 3
//     (`pick2`, "Forge your first tool", launch audit M1) already teaches. It
//     teaches the Forge's other half now: "Level up a tool once at the Forge",
//     counted the way the other stats are (p.stats.upgrades, which the Forge's
//     level-up bumps; MineServer questValue). Same id, same reward.
//   * Milestones that count what you HOLD (#p.cards, #p.gear) or this RUN's depth
//     (depth resets on rebirth) said "Lifetime:". They say "Own N" and "in one
//     run" now; the true lifetime counters keep "Lifetime:".
//
// Runs the real MineQuests; the server half is read statically.
// Fails on 3863d14.
//
//   node tools/verify/quests-honest.js
"use strict";
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");

const ROOT = path.resolve(__dirname, "../..");
const SH = "src/ReplicatedStorage/Mine/Shared/";
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const code = (s) => s.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
let fail = 0;
const check = (ok, msg, detail) => {
  console.log((ok ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!ok) fail++;
};
const between = (s, a, b) => {
  const i = s.indexOf(a);
  const j = i < 0 ? -1 : s.indexOf(b, i + a.length);
  return (i < 0 || j < 0) ? "" : s.slice(i, j + b.length);
};
console.log("quests-honest: forge1 levels a tool up; milestones say what they count");

const SRV = code(read("src/ServerScriptService/Mine/MineServer.server.luau"));
const qv = between(SRV, "local function questValue(p, stat)", "\nend\n");
check(/elseif stat == "upgrades" then\s*return tonumber\(s\.upgrades\) or 0/.test(qv),
  "questValue counts \"upgrades\" from p.stats, like blocks and sells");
const up = between(SRV, "function Verbs.upgradeOreTool(plr, payload)", "\nend\n");
const coin = between(SRV, "function Verbs._upgradeCoinTool(", "\nend\n");
check(/tool\.level = level \+ steps[\s\S]*?bumpStat\(plr, p, "upgrades"\)/.test(up) && /bumpStat\(plr, p, "upgrades"\)/.test(coin),
  "every level-up the Forge sells bumps it (ore tools, and the wooden pick's coin levels)");
const INV = code(read(SH + "MineInventoryView.luau"));
check(/note\(body, "MILESTONES  -  claim when ready", 50\)/.test(INV) && !/MILESTONES  -  lifetime/.test(INV),
  "the milestones' header no longer calls every row lifetime");

if (!Luau.ready) {
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(1);
}
const harness = `
Random = { new = function() return { NextInteger = function(_, a) return a end } end }
local script = { Parent = { WaitForChild = function() return {} end } }
local Q = (function()
${read(SH + "MineQuests.luau")}
end)()
for i, q in ipairs(Q.CHAIN) do
	if q.id == "forge1" or q.id == "pick2" then
		print("RUNG " .. q.id .. "|" .. i .. "|" .. q.stat .. "|" .. q.goal .. "|" .. tostring(q.absolute) .. "|" .. q.text .. "|" .. tostring(q.reward and q.reward.gems))
	end
end
for _, m in ipairs(Q.MILESTONES) do
	print("MS " .. m.id .. "|" .. m.stat .. "|" .. m.text)
end
`;
const tmp = path.join(os.tmpdir(), "mfc-quests-honest-" + process.pid + ".luau");
fs.writeFileSync(tmp, harness);
let out = "";
try { out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" }); } catch (e) {
  out = String(e.stdout || "") + String(e.stderr || "");
  console.log(out.split("\n").slice(-6).map((l) => "        " + l).join("\n"));
}
fs.unlinkSync(tmp);
const rung = (id) => (out.match(new RegExp("^RUNG " + id + "\\|(.*)$", "m")) || [])[1] || "";
const forge = rung("forge1").split("|"), pick = rung("pick2").split("|");
check(forge[1] === "upgrades" && forge[2] === "1" && forge[4] === "Level up a tool once at the Forge",
  "forge1 is \"Level up a tool once at the Forge\", one level-up", rung("forge1"));
check(forge[5] === "60", "...with its reward unchanged (60 gems)", forge[5]);
check(pick[1] === "oretools" && pick[1] !== forge[1] && +pick[0] < +forge[0],
  "...and no longer repeats rung 3 (pick2 forges the first tool, earlier)", rung("pick2"));
const ms = [...out.matchAll(/^MS ([^|]+)\|([^|]+)\|(.*)$/gm)].map((m) => ({ id: m[1], stat: m[2], text: m[3].trim() }));
check(ms.length >= 15, "read the milestones", String(ms.length));
const held = ms.filter((m) => m.stat === "cards" || m.stat === "gear");
const depth = ms.filter((m) => m.stat === "depth");
const life = ms.filter((m) => ["blocks", "packs", "merges"].includes(m.stat));
check(held.length >= 3 && held.every((m) => /^Own [\d,]+ (cards|gear pieces)$/.test(m.text)),
  "the card and gear milestones say \"Own N\" (they count what you hold)", held.map((m) => m.text).join(" / "));
check(depth.length >= 2 && depth.every((m) => /^Reach depth [\d,]+ in one run$/.test(m.text)),
  "the depth milestones say \"in one run\" (depth resets on rebirth)", depth.map((m) => m.text).join(" / "));
check(life.length >= 8 && life.every((m) => /^Lifetime: /.test(m.text)),
  "blocks, packs and merges are lifetime counters and still say so");

console.log(fail === 0 ? ">>> quests-honest OK" : `>>> ${fail} FAILED`);
process.exit(fail === 0 ? 0 : 1);
