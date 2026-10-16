// Fishing (TODO A3): the rules, the fight's replay, and the wiring.
//
//   1. the fight replays: a bot plays it, the server's replay of its presses
//      gets the same result on the same tick; a forged log does not land it
//   2. the odds: a 5-star is about 1 in 2,000 casts, luck lifts the top
//   3. rods: x1.6 a level, a prestige every 10, 50 levels
//   4. the cast bar: the sweet spot is PERFECT, the ends are not
//   5. the tuned difficulty row matches docs/FISHING-TUNING.md
//   6. wiring: server verbs, rebirth keep, quest bait, spots in the world,
//      the client screen
//
//   node tools/verify/fishing.js
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
const SH = "src/ReplicatedStorage/Mine/Shared/";
const fightSrc = read(SH + "MineFishingFight.luau");
const fishSrc = read(SH + "MineFishing.luau");

const harness = `
Color3 = { fromRGB = function(r, g, b) return { r, g, b } end }
Random = {}
Random.__index = Random
function Random.new(seed) return setmetatable({ s = (seed or 48611) % 2147483647 }, Random) end
function Random:NextNumber() self.s = (self.s * 48271) % 2147483647 return self.s / 2147483647 end
function Random:NextInteger(a, b) return a + math.floor(self:NextNumber() * (b - a + 1)) end
local F = (function()
${fightSrc}
end)()
local M = (function()
${fishSrc}
end)()

-- 1. A simple bot plays; record presses exactly as MineFishingView does.
local function play(params)
	local s = F.new(params)
	local toggles, last = {}, false
	while true do
		local thr = (s.colour == "green" and 0.85) or (s.colour == "yellow" and 0.6) or 0.25
		local reel = s.tension < thr
		if reel ~= last then table.insert(toggles, s.tick + 1) last = reel end
		local r = F.step(s, reel)
		if r then return r, s.tick, toggles end
	end
end
local same, landed, total = 0, 0, 0
local forged = 0
for i = 1, 60 do
	local params = { seed = 1000 + i * 37, fish = F.fishFromDifficulty(M.DIFFICULTY[1 + (i % 9)]), rod = { reel = 4.8, line = 1.25 }, size = (i % 7) / 7 }
	local r, tick, toggles = play(params)
	local r2, tick2 = F.replay(params, toggles, tick)
	total += 1
	if r == r2 and tick == tick2 then same += 1 end
	if r == "caught" then
		landed += 1
		-- Forge: hold the reel for the whole fight (no let-go); or claim fewer ticks.
		-- (Holding REEL throughout is fair play on an easy fish, so only the
		-- hard ones are expected to snap or slip under it.)
		local r3 = (1 + (i % 9) >= 6) and F.replay(params, { 1 }, tick) or "skip"
		local r4 = F.replay(params, toggles, math.max(1, tick - 30))
		if r3 ~= "caught" and r4 ~= "caught" then forged += 1 end
	end
end
print("REPLAY " .. same .. " " .. total .. " " .. landed .. " " .. forged)
print("BAD " .. tostring(F.replay({ seed = 1, fish = F.fishFromDifficulty(0.1), rod = { reel = 4, line = 1 } }, { 5, 3 }, 100))
	.. " " .. tostring(F.replay({ seed = 1, fish = F.fishFromDifficulty(0.1), rod = { reel = 4, line = 1 } }, {}, 0)))

-- 2. Odds.
local function topShare(luck)
	local p = 0
	for _, r in ipairs(M.catchOdds("sunscar", luck)) do if r.fish.grade == 9 then p += r.p end end
	return p
end
print(string.format("ODDS %.6f %.6f %.6f", topShare(1), topShare(2), topShare(6)))
local sum = 0
for _, r in ipairs(M.catchOdds("sunscar", 3)) do sum += r.p end
print(string.format("SUM %.6f", sum))
local rng = Random.new(5)
local n9, big = 0, 0
for i = 1, 200000 do
	local f = M.rollFish("sunscar", 1, rng)
	if M.fish(f.id).grade == 9 then n9 += 1 end
	if f.size > 0.25 then big += 1 end
end
print("ROLL " .. n9 .. " " .. big)

-- 3. Rods.
print(string.format("ROD %d %d %d %d %d %s %s", M.levelCost("twig_rod", 0), M.levelCost("twig_rod", 1), M.levelCap(0), M.levelCap(4),
	M.levelCap(9), tostring(M.prestigeCost(0)), tostring(M.prestigeCost(4))))
local a, b = M.rodStats("quarry_rod", 0), M.rodStats("quarry_rod", 50)
print(string.format("STATS %.3f %.3f %.3f %d", b.reel / a.reel, b.line / a.line, b.luck / a.luck, M.rodStats("trawler_rod", 0).bait))

-- 4. Cast.
local sweet = nil
for t = 0, 60 do if M.castQuality(t) == "perfect" then sweet = t break end end
print("CAST " .. tostring(sweet) .. " " .. M.castQuality(0) .. " " .. M.castQuality(24))
print("DIFF " .. table.concat(M.DIFFICULTY, ","))
local ids, dup = {}, 0
for _, list in pairs(M.FISH) do for _, f in ipairs(list) do if ids[f.id] then dup += 1 end ids[f.id] = true end end
local orphan = 0
for _, s in ipairs(M.SPOTS) do if not M.FISH[s.zoneId] then orphan += 1 end end
print("DATA " .. #M.FISH.sunscar .. " " .. dup .. " " .. orphan .. " " .. #M.SPOTS)
`;
const script = path.join(ROOT, ".luau-bin/fishing-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(Luau.LUAU, [script], { encoding: "utf8" }); }
catch (e) { process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || ""); fail++; }
const get = (tag) => (out.split(/\r?\n/).find((l) => l.startsWith(tag + " ")) || "").slice(tag.length + 1).trim();

// 1
const [same, total, landed, forged] = get("REPLAY").split(" ").map(Number);
check(same === total && total === 60, `every fight replays to the same result on the same tick (${same}/${total})`);
check(landed > 10 && forged === landed, `a forged log never lands a fish: claiming a second less, or holding REEL throughout on a 3.5-star or better (${forged}/${landed})`);
check(get("BAD") === "nil nil", "a malformed log (presses out of order, no ticks) is refused");
// 2
const [p1, p2, p6] = get("ODDS").split(" ").map(Number);
check(Math.abs(1 / p1 - 2000) < 60, `a 5-star fish is 1 in ${Math.round(1 / p1)} casts at luck 1 (owner: "make rare fish actually rare")`);
check(p2 > p1 * 1.75 && p6 > p2 * 2, "luck lifts the 5-star (x2 luck: x1.8, after the commoner grades rise a little too)");
check(Math.abs(Number(get("SUM")) - 1) < 1e-6, "the catch table sums to 1");
const [n9, big] = get("ROLL").split(" ").map(Number);
check(n9 > 40 && n9 < 170, `rolling 200,000 casts lands about 100 five-stars (${n9})`);
check(big > 90000 && big < 110000, `half the catches are in the bottom quarter of their size range (${big} of 200,000 above it)`);
// 3
const rod = get("ROD").split(" ");
check(rod[0] === "400" && rod[1] === "640", "a level costs x1.6 the last (400, 640 coins on the Twig Rod)");
check(rod[2] === "10" && rod[3] === "50" && rod[4] === "50", "10 levels per prestige, 50 at most");
check(rod[5] === "100" && rod[6] === "nil", "the first prestige is 100 tokens, and there is none after the fourth");
const st = get("STATS").split(" ").map(Number);
check(st[0] === 2 && st[1] === 2.25 && Math.abs(st[2] - 1.75) < 1e-9 && st[3] === 5, "level 50 doubles reel, x2.25 line, x1.75 luck; the Trawler casts 5 bait");
// 4
const cast = get("CAST").split(" ");
check(cast[0] !== "nil" && cast[1] === "ok" && cast[2] !== "perfect", "the cast bar has a PERFECT spot, and its ends are not it");
// 5
const tuning = fs.existsSync(path.join(ROOT, "docs/FISHING-TUNING.md")) ? read("docs/FISHING-TUNING.md") : "";
const tuned = (tuning.match(/`\{ ([\d., ]+) \}`/) || [])[1];
const diff = get("DIFF");
check(tuned && tuned.split(",").map((x) => Number(x.trim())).join(",") === diff.split(",").map(Number).join(","),
  "MineFishing.DIFFICULTY is the learning machine's row (docs/FISHING-TUNING.md)");
const data = get("DATA").split(" ").map(Number);
check(data[0] === 12 && data[1] === 0 && data[2] === 0 && data[3] === 3, "Greyvein has 12 fish, ids unique; 3 spots (the pond, 1,000 and 3,000)");

// 6 wiring
const server = read("src/ServerScriptService/Mine/MineServer.server.luau");
check(/string\.sub\(action, 1, 4\) == "fish" then\s*\n\s*Verbs\.Fish\.dispatch\(plr, action, payload\)/.test(server), "MineServer hands every \"fish\" action to the service");
check(/machine == "fish" then\s*\n\s*Verbs\.Fish\.prompt\(plr, parent\)/.test(server), "a spot's prompt opens fishing");
check(/Verbs\.KEEP_ON_REBIRTH = \{[\s\S]*?"fishing",[\s\S]*?\n\}/.test(server), "fishing is kept through rebirth (owner: rod levels stay)");
const claim = (server.match(/function Verbs\.claimDailyQuest[\s\S]*?\nend\n/) || [""])[0];
check(/Verbs\.Fish\.questBait\(plr, p\)/.test(claim), "a claimed daily quest pays bait");
const svc = read("src/ServerScriptService/Mine/MineFishingService.luau");
check(/Fight\.replay\(pend\.params, toggles, ticks\)/.test(svc) && /result == "caught"/.test(svc), "the service lands a fish only on a replayed catch");
check(/gainBait\(f, 1\)/.test(svc) && /M\.baitRoom/.test(svc), "AFK bait counts toward the daily cap");
check(/FishPonds\.build/.test(read("src/ServerScriptService/Mine/WorldBuilder.luau")) && /FishPonds\.build/.test(read("src/ServerScriptService/Mine/MineDepthPlazas.luau")),
  "the surface pond and the outpost pools are built");
const ponds = read("src/ServerScriptService/Mine/MineFishPonds.luau");
check(/AddTag\(dock, P\.TAG\)/.test(ponds) && /SetAttribute\("Machine", "fish"\)/.test(ponds) && /S\.TAG = "MineFishSpot"/.test(svc) && /P\.TAG = "MineFishSpot"/.test(ponds),
  "the dock is tagged the way the service looks it up");
const client = read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau");
check(/action == "fishing" then/.test(client) && /MineFishingView/.test(client), "the client opens the fishing screen");
const view = read(SH + "MineFishingView.luau");
check(/table\.insert\(toggles, fight\.tick \+ 1\)/.test(view) && /Fight\.step\(fight, reelDown\)/.test(view), "the client records presses on the tick the replay applies them");

console.log("");
console.log(fail > 0 ? `>>> fishing: ${fail} FAILED` : ">>> fishing: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
