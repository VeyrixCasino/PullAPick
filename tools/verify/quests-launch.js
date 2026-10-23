// QUEST COPY AND DAILIES THAT MATCH THE GAME (launch audit S40, owner 2026-10-19).
//
//   * The daily "Rebirth once" was the whole of tier B, so it was handed to new
//     players on day one. Before the first rebirth tier B is "Sell 10 hauls"
//     (MineQuests.DAILY_NO_REBIRTH). Runs the REAL MineQuests.rollDaily in luau.
//   * Four tips described a game that is gone: "more slots unlock" (three seats
//     for everyone), "Coins buy tools" (tools are forged, bags cost gems),
//     "Prestige yield +15%/rank" (deleted), "AFK chill pad" (AFK pays where you
//     stand). Each rewritten tip is checked against the config value it quotes,
//     so the tip fails here the day the number moves.
//
//   node tools/verify/quests-launch.js
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");

const ROOT = path.resolve(__dirname, "../..");
const SH = "src/ReplicatedStorage/Mine/Shared/";
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const code = (s) => s.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

if (!Luau.ready) { console.log(Luau.missing("luau") + "; skipping"); process.exit(1); }

const questsSrc = read(SH + "MineQuests.luau");
const harness = `
-- Random as Roblox has it, enough for rollDaily: a seeded LCG.
Random = { new = function(seed)
	local s = math.floor(tonumber(seed) or 0) % 2147483647
	if s <= 0 then s = s + 2147483646 end
	return { NextInteger = function(_, a, b)
		s = (s * 48271) % 2147483647
		return a + (s % (b - a + 1))
	end }
end }
local script = { Parent = { WaitForChild = function() return {} end } }
local Q = (function()
${questsSrc}
end)()
local withRebirth, noRebirth, legacy, total = 0, 0, 0, 0
local subId = Q.DAILY_NO_REBIRTH and Q.DAILY_NO_REBIRTH.id
local tierB0 = {}
for day = 20000, 20060 do
	for uid = 1, 40 do
		total += 1
		for _, row in ipairs(Q.rollDaily(day, uid * 7919, { prestige = 0 })) do
			if row.stat == "rebirth" then noRebirth += 1 end
		end
		local b = Q.rollDaily(day, uid * 7919, { prestige = 0 })[2]
		tierB0[b and b.id or "nil"] = true
		for _, row in ipairs(Q.rollDaily(day, uid * 7919, { prestige = 1 })) do
			if row.stat == "rebirth" then withRebirth += 1 end
		end
		for _, row in ipairs(Q.rollDaily(day, uid * 7919)) do
			if row.stat == "rebirth" then legacy += 1 end
		end
	end
end
local tierBIds = {}
for id in pairs(tierB0) do table.insert(tierBIds, id) end
table.sort(tierBIds)
print("ROLL|" .. total .. "|" .. noRebirth .. "|" .. withRebirth .. "|" .. legacy .. "|" .. table.concat(tierBIds, ","))
local sub = subId and Q.dailyById(subId)
print("SUB|" .. tostring(subId) .. "|" .. tostring(sub and sub.stat) .. "|" .. tostring(sub and sub.goal) .. "|" .. tostring(sub and sub.gems))
local reb = Q.dailyById("d_rebirth_1")
print("REB|" .. tostring(reb and reb.gems))
-- Same day, same player: the third tier must not move because tier B was swapped.
local a, b = Q.rollDaily(20123, 555, { prestige = 0 }), Q.rollDaily(20123, 555, { prestige = 3 })
print("TIERC|" .. tostring(a[3].id == b[3].id) .. "|" .. tostring(a[1].id == b[1].id))
for _, q in ipairs(Q.CHAIN) do
	if q.id == "cards10" or q.id == "sell5" or q.id == "cards250" or q.id == "mine75k" then
		print("TIP|" .. q.id .. "|" .. q.tip)
	end
end
`;
const script = path.join(ROOT, ".luau-bin/quests-launch-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(Luau.LUAU, [script], { encoding: "utf8" }); }
catch (e) { process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || ""); fail++; }
const lines = out.split(/\r?\n/);
const get = (tag) => (lines.find((l) => l.startsWith(tag + "|")) || "").split("|").slice(1);

// 1. The daily.
const roll = get("ROLL");
const total = +roll[0];
check(total >= 1000, `rolled ${total} player-days`);
check(+roll[1] === 0, `before the first rebirth no daily asks for a rebirth (${roll[1]} of ${total} did)`);
check(roll[4] === "d_sells_10", `...tier B is the substitute every time (${roll[4]})`);
check(+roll[2] === total && +roll[3] === total, `after a rebirth, and for a caller with no opts, "Rebirth once" stays (${roll[2]}, ${roll[3]} of ${total})`);
const sub = get("SUB");
check(sub[0] === "d_sells_10" && sub[1] === "sells" && +sub[2] > 0 && +sub[3] === +get("REB")[0],
  `the substitute is in the claim pool, counts sells, and pays what tier B paid (${sub.join(", ")})`);
const tierC = get("TIERC");
check(tierC[0] === "true" && tierC[1] === "true", "...and swapping tier B moves no other tier's roll");
const sv = code(read("src/ServerScriptService/Mine/MineServer.server.luau"));
check(/Quests\.rollDaily\(today, userId, \{ prestige = p\.prestige \}\)/.test(sv), "the server rolls with the player's rebirth count");
const bumps = new Set([...sv.matchAll(/bumpStat\(plr, p, "(\w+)"\)/g)].map((m) => m[1]));
check(bumps.has("sells"), "...and \"sells\" is a counter bumpStat moves, so the daily can finish");

// 2. The tips, against the numbers they quote.
const tips = Object.fromEntries(lines.filter((l) => l.startsWith("TIP|")).map((l) => { const [, id, tip] = l.split("|"); return [id, tip]; }));
const cfg = read(SH + "MineConfig.luau");
const all = Object.values(tips).join(" ");
check(Object.keys(tips).length === 4, "found the four tips");
check(!/more slots unlock|coins buy tools|prestige yield|chill pad/i.test(all), "no tip promises more pet slots, coin-bought tools, prestige yield or a chill pad");
check(/MineConfig\.MAX_PET_SLOTS = 3\b/.test(cfg) && /\bthree pets\b/i.test(tips.cards10 || ""),
  `cards10 says three pets, and MAX_PET_SLOTS is 3 ("${tips.cards10}")`);
const bagGems = /p\.gems -= bagGems/.test(sv);
const rebirthCoins = /Rebirth %d needs %s coins/.test(sv);
check(bagGems && rebirthCoins && /coins pay for rebirth/i.test(tips.sell5 || "") && /gems buy[^.]*bags/i.test(tips.sell5 || ""),
  `sell5: coins pay for rebirth, gems buy bags (bags cost gems; rebirth costs coins) ("${tips.sell5}")`);
check(/return 1 \+ 0\.05 \* \(prestige or 0\)/.test(cfg) && !/function MineConfig\.prestigeYield/.test(cfg) && /\+5% luck/.test(tips.cards250 || ""),
  `cards250: +5% luck a rebirth, and prestigeYield is gone ("${tips.cards250}")`);
check(/MineConfig\.AFK_IDLE_SEC = 2 \* 60\b/.test(cfg) && /\b2 minutes\b/.test(tips.mine75k || ""),
  `mine75k: AFK after 2 idle minutes, as AFK_IDLE_SEC says ("${tips.mine75k}")`);

console.log("");
console.log(fail > 0 ? `>>> quests-launch: ${fail} FAILED` : ">>> quests-launch: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
