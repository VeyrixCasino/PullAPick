// The TODAY checklist (TODO A2; owner, 2026-10-10): MineToday.rows, run in luau.
//
//   1. a fresh day: what is claimable reads READY, in the right words
//   2. a finished day: nothing ready, everything says when it comes back
//   3. the events: Event Horizon from the snapshot, the Candy Crypt's window
//   4. the panel is wired: MineClient builds, lays out and opens the rows
//
//   node tools/verify/today.js
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
const mod = read("src/ReplicatedStorage/Mine/Shared/MineToday.luau");
const harness = `
local T = (function()
${mod}
end)()
local function byId(rows)
	local m = {}
	for _, r in ipairs(rows) do m[r.id] = r end
	return m
end
local gifts = { { min = 2 }, { min = 5 }, { min = 10 } }
local now = 86400 * 20000 + 3600 -- 01:00 UTC
-- 1. A fresh day.
local a = byId(T.rows({
	daily = { ready = true },
	dailyQuests = { { ready = true }, { ready = false }, { ready = false } },
	groupWheel = { freeLeft = 1 },
	contracts = { { ready = false }, { ready = false }, { ready = false } },
	pass = { tier = 3, freeClaimed = { 1 }, premClaimed = {}, owned = false, tiers = 100 },
	limitedActive = true,
	eventPass = { quest = { progress = 50, goal = 100 }, questIndex = 4, questTotal = 10 },
}, now, { giftSecs = 130, giftsGot = {}, gifts = gifts, crypt = { active = false, countdown = "6d 5h" } }))
local function line(r) return r.id .. "=" .. r.text .. (r.ready and "!" or "") .. (r.done and "~" or "") .. (r.live and "*" or "") end
print("A " .. line(a.daily) .. " " .. line(a.quests) .. " " .. line(a.gifts) .. " " .. line(a.wheel) .. " " .. line(a.jobs) .. " " .. line(a.pass) .. " " .. line(a.eventpass) .. " " .. line(a.bigbang) .. " " .. line(a.hallow))
print("READY " .. T.readyCount(T.rows({
	daily = { ready = true }, dailyQuests = { { ready = true } }, groupWheel = { freeLeft = 1 },
	pass = { tier = 3, freeClaimed = { 1 }, premClaimed = {}, owned = false },
}, now, { giftSecs = 130, giftsGot = {}, gifts = gifts })))
-- 2. A finished day.
local b = byId(T.rows({
	daily = { ready = false },
	dailyQuests = { { claimed = true }, { claimed = true }, { claimed = true } },
	groupWheel = { freeLeft = 0 },
	contracts = { { claimed = true }, { claimed = true }, { claimed = true } },
	pass = { tier = 2, freeClaimed = { 1, 2 }, premClaimed = { 1, 2 }, owned = true, tiers = 100 },
	limitedActive = false,
}, now, { giftSecs = 9999, giftsGot = { ["1"] = true, ["2"] = true, ["3"] = true }, gifts = gifts, crypt = { active = true, countdown = "12d 3h" } }))
print("B " .. line(b.daily) .. " " .. line(b.quests) .. " " .. line(b.gifts) .. " " .. line(b.wheel) .. " " .. line(b.jobs) .. " " .. line(b.pass) .. " " .. line(b.eventpass) .. " " .. line(b.bigbang) .. " " .. line(b.hallow))
print("ROWS " .. #T.rows({}, now, {}) .. " ORDER " .. #T.ORDER)
local function ids(list) local t = {} for _, r in ipairs(list) do table.insert(t, r.id) end return table.concat(t, ",") end
print("ACTIVEA " .. ids(T.active(T.rows({
	daily = { ready = true }, dailyQuests = { { ready = true } }, groupWheel = { freeLeft = 1 },
	contracts = { { ready = false } }, pass = { tier = 3, freeClaimed = { 1 }, premClaimed = {}, owned = false },
	limitedActive = true, eventPass = { quest = { progress = 1, goal = 9 }, questIndex = 1, questTotal = 10 },
}, now, { giftSecs = 130, giftsGot = {}, gifts = gifts, crypt = { active = false, countdown = "6d" } }))))
print("ACTIVEB " .. ids(T.active(T.rows({ daily = { ready = false }, groupWheel = { freeLeft = 0 }, limitedActive = false },
	now, { giftSecs = 0, giftsGot = {}, gifts = {}, crypt = { active = true, countdown = "9d" } }))))
print("ACTIVEC " .. ids(T.active(T.rows({ daily = { ready = false }, groupWheel = { freeLeft = 0 }, limitedActive = false },
	now, { giftSecs = 0, giftsGot = {}, gifts = {}, crypt = { active = false, countdown = "closed" } }))))
`;
const script = path.join(ROOT, ".luau-bin/today-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(Luau.LUAU, [script], { encoding: "utf8" }); }
catch (e) { process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || ""); fail++; }
const get = (tag) => (out.split(/\r?\n/).find((l) => l.startsWith(tag + " ")) || "").slice(tag.length + 1).trim();
const A = get("A"), Bl = get("B");

// 1. fresh day
check(/daily=CLAIM!!/.test(A) && /quests=1 to claim!/.test(A) && /gifts=OPEN!!/.test(A) && /wheel=1 free spin!/.test(A),
  "a fresh day: the reward, a done quest, an opened gift and a free spin read READY");
check(/jobs=0\/3 done /.test(A) && /pass=2 rewards!/.test(A), "contracts in progress show their count; two unclaimed pass tiers read READY");
check(get("READY") === "5", "readyCount counts the claimable rows (reward, quest, gift, spin, pass: 5)");
// 2. finished day
check(/daily=in 23h 00m~/.test(Bl) && /quests=done  ·  new in 23h 00m~/.test(Bl) && /gifts=done  ·  new in 23h 00m~/.test(Bl)
  && /wheel=free spin in 23h 00m~/.test(Bl) && /jobs=done  ·  new in 23h 00m~/.test(Bl),
  "a finished day: every daily says when it comes back (UTC midnight)");
check(/pass=tier 2\/100 /.test(Bl) && !/!/.test(Bl.replace(/OPEN!/g, "")), "a fully claimed pass shows its tier, and nothing reads READY");
// 3. events
check(/eventpass=quest 4\/10  ·  50%/.test(A) && /bigbang=OPEN\*/.test(A) && /hallow=opens in 6d 5h/.test(A),
  "events open: event quest progress, Event Horizon OPEN, the Crypt counts down to opening");
check(/eventpass=event closed~/.test(Bl) && /bigbang=closed~/.test(Bl) && /hallow=OPEN  ·  12d 3h left\*/.test(Bl),
  "events closed / open the other way round");
check(get("ROWS") === "9 ORDER 9", "an empty snapshot still yields all nine rows");

check(get("ACTIVEA") === "daily,gifts,wheel,pass,bigbang", "only active rows show: ready ones and open events; no daily quests or event quests (owner: just put active ones)");
check(get("ACTIVEB") === "hallow" && get("ACTIVEC") === "", "a finished day shows only an open event mine, and nothing at all when none is open");

// 4. wiring
const cl = read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau");
check(/function ClientFns\.paintTodayBox\(/.test(cl) && /function ClientFns\.todayOpen\(/.test(cl) && /MineToday/.test(cl),
  "MineClient paints the TODAY box and routes its taps");
const layout = (cl.match(/function ClientFns\.layoutQuestPanel[\s\S]*?\nend\n/) || [""])[0];
check(/todayBox/.test(layout) && layout.indexOf("todayBox") < layout.indexOf("questBox.Position"),
  "the TODAY box is stacked first in the Quests panel, above the active quest");
const dot = (cl.match(/function ClientFns\.refreshQuestDrawerTabs[\s\S]*?\nend\n/) || [""])[0];
check(/todayReady/.test(dot), "the panel's green dot also lights for a ready TODAY row");

console.log("");
console.log(fail > 0 ? `>>> today: ${fail} FAILED` : ">>> today: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
