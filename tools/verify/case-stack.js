// EVERY CASE OPENS UP TO FIVE AT A TIME, AS STACKED SPINS.
//
// Owner, 2026-10-19 (wiki open-questions, "Candy Crypt v2"): "make every case in
// the game be able to spin up to 5 slot spins at a time (one on top of
// another)". The pieces, each pinned here:
//
//   * MineCaseStack: the 1-5 rule (clamp), all-or-nothing pricing (charge), the
//     stop order (stopAt), the rounds of five (rounds), what counts as a case
//     (isCase). RUN against the real MineCases and MinePackConfig.
//   * The server opens N in one request: the bag's openMany clamps a case run to
//     five; the Temperament Case (Verbs.openTemperStack) and the traders' cases
//     (buyTraderCase) charge all or nothing, roll every case before a token
//     moves and send every reel ("caseSpins"). openTemperStack is RUN, sliced
//     out of MineServer, on the real MineTemper.
//   * A trader case spins: MineTrader.caseReel / reelRow are RUN.
//   * The case screen plays a run in stacked rounds (ctl.playRun's `stack`,
//     ctl.playStack): the run logic is lifted out of MineGradeReveal and RUN.
//     The stacked tiles never scale (MineUI's text rule), and the results grid
//     after a stack holds still.
//   * Every door has the picker: the bag's case tiles, the Enchanter's
//     Temperament Case, the trader's shelf.
//
// Fails on 3863d14 (no MineCaseStack, no stacked reels, no picker).
//
//   node tools/verify/case-stack.js
"use strict";
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");
const Shared = require("./_shared");

const ROOT = path.resolve(__dirname, "../..");
const SH = "src/ReplicatedStorage/Mine/Shared/";
const read = (p) => (fs.existsSync(path.join(ROOT, p)) ? Luau.readSrc(path.join(ROOT, p)) : "");
const code = (s) => s.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
let fail = 0;
const check = (ok, msg, detail) => {
  console.log((ok ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!ok) fail++;
};
const between = (s, a, b, from) => {
  const i = s.indexOf(a, from || 0);
  const j = i < 0 ? -1 : s.indexOf(b, i + a.length);
  return (i < 0 || j < 0) ? "" : s.slice(i, j + b.length);
};
console.log("case-stack: every case opens 1-5 at a time, paid all or nothing, spinning stacked");

const STACK = read(SH + "MineCaseStack.luau");
const SRV_RAW = read("src/ServerScriptService/Mine/MineServer.server.luau");
const SRV = code(SRV_RAW);
const CLIENT = code(read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau"));
const GRADE_RAW = read(SH + "MineGradeReveal.luau");
const GRADE = code(GRADE_RAW);
const INV = code(read(SH + "MineInventoryView.luau"));
const REVEAL = code(read(SH + "MinePackReveal.luau"));
const TRADER = read(SH + "MineTrader.luau");

// ------------------------------------------------------------- the rule --
check(STACK.length > 0, "MineCaseStack exists");
check(/MineCaseStack\.MAX = 5\b/.test(STACK), "at most five at a time (owner: \"up to 5\")");

// --------------------------------------------------------------- server --
const openMany = between(SRV, "local function openMany(plr, payload)", "\nend\n");
check(openMany.length > 500, "found openMany");
check(/CaseStack\.isCase\(packId\)/.test(openMany) && /want = math\.min\(want, CaseStack\.MAX\)/.test(openMany)
  && !/want = math\.min\(want, 3\)/.test(openMany),
  "the bag opens a case run of at most five in one request (gear cases are no longer held to three)");
const oreCase = between(SRV, 'elseif zdef.kind == "ore_case" then', 'elseif zdef.kind == "ore" then');
check(/if collect then[\s\S]*?reel = spin,/.test(oreCase) && /net:FireClient\(plr, "temperCase", spin\)/.test(oreCase),
  "an ore case's skin spins in a run too: the collected design carries the same reel as a lone open");
const temperCase = between(SRV, "function Verbs.openTemperCase(plr, payload)", "\nend\n");
check(/if want <= require\(shared:WaitForChild\("MineCaseStack"\)\)\.MAX then\s*Verbs\.openTemperStack\(plr, p, want, price\)/.test(temperCase),
  "the Temperament Case sends 1-5 to Verbs.openTemperStack (10x and 100x keep the best-of reel)");
const stackVerb = between(SRV_RAW, "function Verbs.openTemperStack(plr, p, n, price)", "\nend\n");
const stackCode = code(stackVerb);
check(stackVerb.length > 800, "found Verbs.openTemperStack");
const chargeAt = stackCode.indexOf("CaseStack.charge(p.temperTokens, price, n)");
const rollAt = stackCode.indexOf("Temper.rollTemperament(rng)");
const debitAt = stackCode.indexOf("p.temperTokens = (tonumber(p.temperTokens) or 0) - total");
check(chargeAt > -1 && rollAt > chargeAt && debitAt > rollAt,
  "...asks for the whole price first, rolls every case, and only then takes the tokens");
check(/net:FireClient\(plr, "caseSpins", \{ list = spins \}\)/.test(stackCode) && /net:FireClient\(plr, "temperCase", spins\[1\]\)/.test(stackCode),
  "...and sends every reel (\"caseSpins\"); one case keeps the single reel (\"temperCase\")");
const bundle = between(SRV, "function Verbs.openTemperCaseBundle(plr)", "\nend\n");
check(/net:FireClient\(plr, "caseSpins", \{ list = spins \}\)/.test(bundle) && !/bundle = n,/.test(bundle),
  "the 3-case bundle spins all three, stacked (it showed the best on one reel)");
const trader = between(SRV, "function Verbs.buyTraderCase(plr, payload)", "\nend\n");
const tCharge = trader.indexOf("CaseStack.charge(p.temperTokens, price, n)");
const tRoll = trader.indexOf("Dig.Trader.rollCase(row.caseId, rng)");
const tDebit = trader.indexOf("p.temperTokens = (tonumber(p.temperTokens) or 0) - total");
check(/local n = CaseStack\.clamp\(payload\.count\)/.test(trader) && tCharge > -1 && tRoll > tCharge && tDebit > tRoll,
  "a trader opens 1-5 of a case: the whole price asked first, every case rolled, then charged");
check(/Dig\.Trader\.reelRow\(reward, made, rng\)/.test(trader) && /Dig\.Trader\.caseReel\(row\.caseId, win, rng\)/.test(trader)
  && /net:FireClient\(plr, "caseSpins", \{ list = spins \}\)/.test(trader),
  "...and every trader case spins on a reel built around what it granted");
check(/function Verbs\.grantTraderReward\(p, reward, rng\)/.test(SRV), "the trader's grants live in Verbs.grantTraderReward");

// --------------------------------------------------------------- client --
const onOpenMany = between(CLIENT, "onOpenMany = function(packId, count, uid)", "\n\tend,");
check(/CaseStack\.isCase\(packId\)/.test(onOpenMany) && /count = CaseStack\.clamp\(count\)/.test(onOpenMany)
  && !/math\.min\(tonumber\(count\) or 1, 3\)/.test(onOpenMany),
  "the client asks for at most five of a case (not three of a gear case)");
const playCase = between(CLIENT, "function ClientFns.playCaseReels(designs, done)", "\nend\n");
check(/stack = require\(shared:WaitForChild\("MineCaseStack"\)\)\.MAX/.test(playCase) && /ClientFns\.gearReels\(d\)/.test(playCase),
  "a case run plays stacked, five at a time, a gear case's items included");
const gearReels = between(CLIENT, "function ClientFns.gearReels(design)", "\nend\n");
check(/Gear\.rollRarity and Gear\.rollRarity\(rng\)/.test(gearReels) && /Gear\.catalogFor\("hat", g, nil, rng\)/.test(gearReels),
  "a gear reel's other tiles are drawn the way the case draws (no flood of fake SSS near-misses)");
const opened = between(CLIENT, 'elseif action == "openedRun" then', 'elseif action == "luckyBlockOpened" then');
check(/type\(d\.reel\) == "table" or d\.kind == "gear"/.test(opened), "a run's gear cases spin with its other cases");
check(/elseif action == "caseSpins" and type\(payload\) == "table" and type\(payload\.list\) == "table" then\s*ClientFns\.caseScreen\(\)\.playRun\(payload\.list, \{\s*stack = require\(shared:WaitForChild\("MineCaseStack"\)\)\.MAX/.test(CLIENT),
  "\"caseSpins\" plays every reel the server sent, stacked");
check(/"picker", "temper"\)/.test(CLIENT) && /function rollsTab\.casePicker\(card, unit, tint, fire, kind\)/.test(CLIENT)
  && /CaseStack\.picker\(card, \{/.test(CLIENT) && /fire\(entry\.n\)/.test(CLIENT),
  "the Enchanter's Temperament Case has a 1-5 picker and one SPIN button");
const shop = between(CLIENT, "function ClientFns.showTraderShop(payload)", "\nend\n");
check(/CaseStack\.picker\(pickRow, \{/.test(shop) && /count = picker\.get\(\),/.test(shop)
  && /local afford = have >= b\.price \* n/.test(shop),
  "the trader's shelf has a 1-5 picker; a buy sends the count and shows the price times it");
const packs = between(INV, "local function renderPacks()", "local function renderOwnedCards()");
check(/CaseStack\.isCase\(g\.packId\)/.test(packs) && /CaseStack\.picker\(tile, \{/.test(packs)
  && /fire\(isCase and CaseStack\.recall\(pickKey, g\.count\) or 1\)/.test(packs),
  "a case stack in the bag has a 1-5 picker, and OPEN opens that many");
check(/local cap = \(okS and CaseStack and CaseStack\.isCase\(packId\)\) and CaseStack\.MAX or 10/.test(REVEAL),
  "the pack reveal never offers ten of a case it would only open five of");

// ---------------------------------------------------------- the reveal --
const caseSpin = between(GRADE, "function MineGradeReveal.caseSpin(parent, opts)", "\nreturn MineGradeReveal");
check(/function ctl\.playStack\(list, playOpts\)/.test(caseSpin), "the case screen spins a stack (ctl.playStack)");
// The stack's own code: its tiles, tracks and stop (up to the single reel's
// ctl.play, which is S31's), and ctl.playStack itself.
const stackSection = between(GRADE_RAW, "THE STACK, SPINNING.", "function ctl.play(payload, onDone, playOpts)")
  + between(GRADE_RAW, "function ctl.playStack(list, playOpts)", "function ctl.playRun(list, runOpts)");
const stackCodeOnly = code(stackSection);
check(stackSection.length > 3000 && !/UIScale/.test(stackCodeOnly),
  "no stacked tile or track rides a scale animation (text never does; MineUI's rule)");
check(/calmGrid = true\s*showSummary\(me\.list\)/.test(stackCodeOnly) && /if not calmGrid then\s*local punch = mk\("UIScale"/.test(caseSpin),
  "the results grid after a stack holds still (no punch)");
check(/dur = \(CS and CS\.stopAt\(i\)\)/.test(stackCodeOnly), "each reel stops at MineCaseStack.stopAt(i): in turn, top to bottom");

// ------------------------------------------------------------- run it --
if (!Luau.ready) {
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(1);
}
if (!STACK) {
  console.log(`>>> ${fail} FAILED (no MineCaseStack to run)`);
  process.exit(1);
}
function runLuau(src) {
  const tmp = path.join(os.tmpdir(), "mfc-case-stack-" + process.pid + "-" + Math.random().toString(36).slice(2) + ".luau");
  fs.writeFileSync(tmp, src);
  let out = "";
  try { out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8", maxBuffer: 1 << 26 }); } catch (e) {
    out = String(e.stdout || "") + String(e.stderr || "");
    console.log(out.split("\n").slice(-8).map((l) => "        " + l).join("\n"));
  }
  fs.unlinkSync(tmp);
  return out.replace(/\t/g, " ");
}
const lineOf = (out, k) => { const m = out.match(new RegExp("^" + k + " (.*)$", "m")); return m ? m[1] : ""; };

// 1. The rules, on the real MineCases and MinePackConfig.
const names = ["MineCaseStack", "MineCases", "MinePackConfig", "MineSetPets", "MineSetPacks", "MinePackArt",
  "MineZonePacks", "Mine1PacksData", "Mine1ChestsData", "MineTemper", "MineStats"];
const rules = Shared.prelude(ROOT, names, ["SetPets"]) + `
local CS = require(SHARED:FindFirstChild("MineCaseStack"))
print("CLAMP " .. table.concat({ CS.clamp(9), CS.clamp(0), CS.clamp(nil), CS.clamp(3.7), CS.clamp(5, 2), CS.clamp(4, 9) }, ","))
local a, need = CS.charge(99, 20, 5)
print("CHARGE " .. tostring(CS.charge(100, 20, 5)) .. "," .. tostring(a) .. "," .. tostring(need) .. "," .. tostring(CS.charge(0, 0, 3)))
local up = true
for i = 2, CS.MAX do if CS.stopAt(i) <= CS.stopAt(i - 1) then up = false end end
print("STOP " .. tostring(up) .. "," .. tostring(CS.stopAt(1) == CS.SPIN) .. "," .. tostring(CS.stopAt(CS.MAX) <= 8))
local list = {}
for i = 1, 12 do list[i] = i end
local sizes = {}
for _, r in ipairs(CS.rounds(list, CS.MAX)) do table.insert(sizes, #r) end
print("ROUNDS " .. table.concat(sizes, ","))
local function yes(id, kind) return CS.isCase(id, kind) and "Y" or "n" end
print("CASES " .. yes("case_6") .. yes("case_3_4") .. yes("pebblebound_case_starter") .. yes("copper_ore_case")
	.. yes("gear_pack") .. yes("gear_case_pack") .. yes("gear_vault_pack") .. yes("anything", "gear"))
print("NOTCASES " .. yes("pebblebound_pack_3") .. yes("meadow_pack_legendary") .. yes("lucky_block") .. yes("heirloom_pack"))
CS.remember("bag:case_6", 4)
print("RECALL " .. CS.recall("bag:case_6") .. "," .. CS.recall("bag:case_6", 2) .. "," .. CS.recall("never"))
`;
const rulesOut = runLuau(rules);
check(lineOf(rulesOut, "CLAMP") === "5,1,1,3,2,4", "clamp keeps a request to 1-5, and to what the stack holds", lineOf(rulesOut, "CLAMP"));
check(lineOf(rulesOut, "CHARGE") === "100,nil,100,0", "charge is all or nothing: 99 tokens buy no part of five 20-token cases", lineOf(rulesOut, "CHARGE"));
check(lineOf(rulesOut, "STOP") === "true,true,true", "the reels stop in turn, top first, all within eight seconds");
check(lineOf(rulesOut, "ROUNDS") === "5,5,2", "twelve reels play in rounds of 5, 5 and 2", lineOf(rulesOut, "ROUNDS"));
check(lineOf(rulesOut, "CASES") === "YYYYYYYY", "wild, set, ore (skin) and gear cases are cases", lineOf(rulesOut, "CASES"));
check(lineOf(rulesOut, "NOTCASES") === "nnnn", "packs, zone packs and lucky blocks are not", lineOf(rulesOut, "NOTCASES"));
check(lineOf(rulesOut, "RECALL") === "4,2,1", "a stack's pick is remembered, and never more than it holds", lineOf(rulesOut, "RECALL"));

// 2. Verbs.openTemperStack, sliced out of MineServer, on the real MineTemper.
const temperRun = Shared.prelude(ROOT, ["MineCaseStack", "MineTemper", "MineStats"], []) + `
setmetatable(SHARED, { __index = function(t, k) return t.FindFirstChild(t, k) end })
local shared = SHARED
local fired = {}
local net = { FireClient = function(_, plr, action, payload) table.insert(fired, { action = action, payload = payload }) end }
local function introAdvance() end
local function introSend() end
local function markDirty() end
local function snap() end
local Verbs = {}
${stackVerb}
local function count(action)
	local n, last = 0, nil
	for _, f in ipairs(fired) do if f.action == action then n += 1 last = f.payload end end
	return n, last
end
local p = { temperTokens = 99 }
Verbs.openTemperStack({}, p, 5, 20)
local kits = 0
for _ in pairs(p.tempers or {}) do kits += 1 end
print("SHORT " .. p.temperTokens .. "," .. kits .. "," .. count("caseSpins") .. "," .. count("toast"))
fired = {}
p = { temperTokens = 100 }
Verbs.openTemperStack({}, p, 5, 20)
local n, spins = count("caseSpins")
local copies, honest = 0, 0
for _, row in pairs(p.tempers or {}) do copies += row.n end
for _, s in ipairs((spins and spins.list) or {}) do
	if s.reel and #s.reel == 44 and s.at == 38 and s.reel[s.at].id == s.id and p.tempers[s.id] then honest += 1 end
end
print("FIVE " .. p.temperTokens .. "," .. n .. "," .. #((spins and spins.list) or {}) .. "," .. copies .. "," .. honest)
fired = {}
p = { temperTokens = 25 }
Verbs.openTemperStack({}, p, 1, 20)
print("ONE " .. p.temperTokens .. "," .. count("temperCase") .. "," .. count("caseSpins"))
fired = {}
p = { temperTokens = 1000 }
Verbs.openTemperStack({}, p, 9, 20)
print("CAP " .. p.temperTokens .. "," .. #((select(2, count("caseSpins")) or {}).list or {}))
`;
const tOut = runLuau(temperRun);
check(lineOf(tOut, "SHORT") === "99,0,0,1", "99 tokens for five cases: nothing rolled, nothing charged, one toast", lineOf(tOut, "SHORT"));
check(lineOf(tOut, "FIVE") === "0,1,5,5,5", "100 tokens: five cases charged, five granted, five reels each stopping on its own winner", lineOf(tOut, "FIVE"));
check(lineOf(tOut, "ONE") === "5,1,0", "one case is the single reel, at the single price", lineOf(tOut, "ONE"));
check(lineOf(tOut, "CAP") === "900,5", "nine asked opens five (and charges five)", lineOf(tOut, "CAP"));

// 3. A trader case's reel, on MineTrader with the real MineTemper.
const traderRun = Shared.prelude(ROOT, ["MineTrader", "MineTemper", "MineStats"], []) + `
SOURCES["Shared/MineCharms"] = function()
	local defs = { c1 = { id = "c1", name = "Pebble Charm", rarity = "C", art = "rbxassetid://1" }, s1 = { id = "s1", name = "Star Charm", rarity = "S" } }
	local i = 0
	return {
		rollChestCharm = function() i += 1 return (i % 7 == 0) and defs.s1 or defs.c1 end,
		byId = function(id) return defs[id] end,
		chestCharmOdds = function() return {} end,
	}
end
SOURCES["Shared/MineConfig"] = function()
	local ores = {}
	local bands = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic" }
	for t = 1, 82 do ores[t] = { id = "ore" .. t, name = "Ore" .. t, tier = t, band = bands[math.min(8, 1 + math.floor((t - 1) / 11))] } end
	return { ORES = ores }
end
SOURCES["Shared/MineIcons"] = function() return { forTool = function(t) return "icon:" .. t.familyId .. ":" .. t.tier end } end
SOURCES["Shared/MineGear"] = function()
	return { catalogFor = function(slot, g) return { id = "hat_" .. g, name = "Hat " .. g, catalogId = 100 } end }
end
local Trader = require(SHARED:FindFirstChild("MineTrader"))
local rng = Random.new(7)
local GR = { F = true, D = true, C = true, B = true, A = true, S = true, SS = true, SSS = true }
local function reelOk(caseId, win)
	local rows, at = Trader.caseReel(caseId, win, rng)
	local graded, inBand = 0, 0
	for _, r in ipairs(rows) do
		if GR[r.rarity] then graded += 1 end
		local t = tonumber(string.match(tostring(r.name), "^Ore(%d+) "))
		if t and t >= 1 and t <= 20 then inBand += 1 end
	end
	return rows, at, graded, inBand
end
local reward = Trader.rollCase("case_rough", rng)
local win = Trader.reelRow(reward, nil, rng)
local rows, at, graded, inBand = reelOk("case_rough", win)
print("TOOL " .. #rows .. "," .. at .. "," .. tostring(rows[at] == win) .. "," .. graded .. "," .. inBand .. "," .. tostring(rows[at].icon ~= nil))
local hat = { id = "abc", hatId = "redcap", itemName = "Redcap", catalogId = 4242 }
local hrows, hat_at = Trader.caseReel("case_hats", Trader.reelRow({ kind = "hat", rarity = "SS" }, hat, rng), rng)
print("HAT " .. hrows[hat_at].catalogId .. "," .. hrows[hat_at].rarity .. "," .. hrows[hat_at].name .. "," .. hrows[1].name)
local crow = Trader.reelRow({ kind = "charm", charmId = "c1", name = "Pebble Charm", rarity = "C" }, nil, rng)
local crows = Trader.caseReel("case_charm", crow, rng)
print("CHARM " .. crows[38].name .. "," .. crows[38].rarity .. "," .. tostring(crows[38].icon) .. "," .. #crows)
`;
const trOut = runLuau(traderRun);
check(lineOf(trOut, "TOOL") === "44,38,true,44,44,true",
  "a tool case's reel: 44 graded tiles, its winner at 38, every tile a tool from the case's own band", lineOf(trOut, "TOOL"));
check(/^4242,SS,Redcap,Hat (F|D|C|B|A|S|SS|SSS)$/.test(lineOf(trOut, "HAT")),
  "a hat case's winning tile is the very hat granted; the others are catalog hats of a rolled grade", lineOf(trOut, "HAT"));
check(/^Pebble Charm,C,rbxassetid:\/\/1,44$/.test(lineOf(trOut, "CHARM")), "a charm case's reel is charms, its winner the charm granted", lineOf(trOut, "CHARM"));

// 4. The case screen's run logic, lifted out and run: rounds of five.
const playRun = between(GRADE_RAW, "\tfunction ctl.playRun(list, runOpts)", "\n\tend\n");
const closeFn = between(GRADE_RAW, "\tfunction ctl.close()", "\n\tend\n", GRADE_RAW.indexOf("\tfunction ctl.playRun("));
const skipAll = between(GRADE_RAW, "\tskipAllBtn.MouseButton1Click:Connect(function()", "\n\tend)\n");
const refresh = between(GRADE_RAW, "\tlocal function refreshSkipAll()", "\n\tend\n");
check(playRun.length > 500 && closeFn.length > 200 && skipAll.length > 300 && refresh.length > 100,
  "lifted playRun, close, SKIP ALL and its counter");
const runTest = `
task = { defer = function(f, ...) f(...) end }
UDim2 = { fromScale = function() return {} end, fromOffset = function() return {} end }
local ctl = {}
local closeHooks, run, shown = {}, nil, nil
local playing, finishNow = false, nil
local log, summaryOf, stopped = {}, nil, 0
local summary, track, sub, boxStroke, box = { Visible = false }, {}, {}, {}, {}
local stackHost, calmGrid = {}, false
local function stopStack() end
local function setBoxHeight() end
local MUTED, GOLD = "muted", "gold"
local skipAllBtn = { MouseButton1Click = {}, Visible = false, Text = "" }
local skipAllFn
function skipAllBtn.MouseButton1Click:Connect(f) skipAllFn = f end
local function clearCelebration() end
local function setGuiOn() end
local function showSummary(all) summaryOf = all end
${refresh}
-- Stand-ins for the two players, doing what the real ones do with the run:
-- hook the close, show the payload(s), recount SKIP ALL.
function ctl.play(payload, onDone, playOpts)
	if playOpts and playOpts.onClosed then table.insert(closeHooks, playOpts.onClosed) end
	shown = payload
	table.insert(log, "1")
	playing = true
	finishNow = function(silent) playing = false if silent then stopped += 1 end end
	refreshSkipAll()
end
function ctl.playStack(list, playOpts)
	if playOpts and playOpts.onClosed then table.insert(closeHooks, playOpts.onClosed) end
	shown = list
	table.insert(log, tostring(#list))
	playing = true
	finishNow = function(silent) playing = false if silent then stopped += 1 end end
	refreshSkipAll()
end
${playRun}
${closeFn}
${skipAll}
local function r(id) return { id = id, reel = {}, at = 1, rarity = "B" } end
local list = {}
for i = 1, 12 do list[i] = r("c" .. i) end
local done, each = 0, 0
ctl.playRun(list, { stack = 5, onDone = function() done += 1 end, onEach = function() each += 1 end })
print("FIRST " .. table.concat(log, ",") .. " " .. skipAllBtn.Text .. " " .. tostring(skipAllBtn.Visible))
ctl.close()
print("SECOND " .. table.concat(log, ",") .. " " .. skipAllBtn.Text)
ctl.close()
ctl.close()
print("END " .. table.concat(log, ",") .. " " .. done .. " " .. each)
log, done = {}, 0
ctl.playRun(list, { stack = 5, onDone = function() done += 1 end })
skipAllFn()
local seen, dupes = {}, 0
for _, p in ipairs(summaryOf or {}) do if seen[p] then dupes += 1 end seen[p] = true end
print("SKIP " .. table.concat(log, ",") .. " " .. #(summaryOf or {}) .. " " .. dupes .. " " .. stopped)
ctl.close()
print("SKIPCLOSE " .. table.concat(log, ",") .. " " .. done)
log = {}
ctl.playRun({ r("a"), r("b") }, { stack = 5 })
print("ONEROUND " .. table.concat(log, ",") .. " " .. tostring(skipAllBtn.Visible))
`;
const runOut = runLuau(runTest);
check(lineOf(runOut, "FIRST") === "5 SKIP ALL  (12) true", "a run of twelve starts with five stacked reels; SKIP ALL counts all twelve", lineOf(runOut, "FIRST"));
check(lineOf(runOut, "SECOND") === "5,5 SKIP ALL  (7)", "closing the results starts the next five", lineOf(runOut, "SECOND"));
check(lineOf(runOut, "END") === "5,5,2 1 3", "then the last two; the run ends once, onEach once a round", lineOf(runOut, "END"));
check(lineOf(runOut, "SKIP") === "5 12 0 1", "SKIP ALL during the first round stops it silently and grids all twelve, once each", lineOf(runOut, "SKIP"));
check(lineOf(runOut, "SKIPCLOSE") === "5 1", "closing that grid ends the run; nothing more spins", lineOf(runOut, "SKIPCLOSE"));
check(lineOf(runOut, "ONEROUND") === "2 false", "two cases are one stacked round, with no SKIP ALL (nothing is left to skip)", lineOf(runOut, "ONEROUND"));

console.log(fail === 0 ? ">>> case-stack OK" : `>>> ${fail} FAILED`);
process.exit(fail === 0 ? 0 : 1);
