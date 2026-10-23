// F TO SSS CHESTS, EACH WITH ITS OWN NAME (owner, 2026-10-19).
//
// "lets go f-sss chests", "same system as packs"; "8 chest tiers" in the main
// game with "the same loot overall, split by tier" (rarer tiers rarer, more
// often deeper, paying more); "all separate names", the rank shown as a badge;
// and "each of the 19 pack sets gets 3 named chests of its own (a low, a mid
// and a high rank) paying that set's packs, where that set's pets live".
//
// Runs the real MineChestRanks, MineZoneChests and MineSetChests (with the real
// MineConfig, MineCases, MineEnchants and the 19 sets) in luau:
//   1. the ladder: eight ranks, rarer is rarer, deeper lifts the rare ones most
//   2. every chest: one rank, its own name; every zone has every rank
//   3. the spawn table: sums to 1; the set chests take a share of their rank's
//      chests without touching the rank split or the chest count; a set chest
//      only where its set lives, from its layer, at its own rank
//   4. what a rank pays climbs with the rank: gems, coins, packs, cases, skin
//      cases, books, XP
//   5. the 57 set chests: 19 sets x low D / mid B / high S, real set packs
//   6. the draw (rollSpawn, rollCurrency, rollPackDrops) matches the tables
//   7. wiring: the server opens the block's own chest by its rank, the badge
//      reaches the block, the hover, the chest card, the lid and the dex
// (The loot totals against 3863d14 are tools/verify/economy-gems.js.)
//
//   node tools/verify/chest-ranks.js
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");
const Shared = require("./_shared");
const Stubs = require("./_stubs");

const ROOT = path.resolve(process.argv[2] || path.join(__dirname, "../.."));
let fail = 0;
const check = (ok, msg, detail) => {
  console.log((ok ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!ok) fail++;
};
if (!Luau.ready) {
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(1);
}
const SH = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared");
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const mods = Stubs.ECONOMY_MODULES.filter((m) => fs.existsSync(path.join(SH, m + ".luau")));

const test = `
local function R(n) return require(SHARED:FindFirstChild(n)) end
local ok, err = pcall(function()
local C = R("MineConfig")
local Ranks = R("MineChestRanks")
local ZC = R("MineZoneChests")
local SC = R("MineSetChests")
local Cases = R("MineCases")
local E = R("MineEnchants")
local SetPacks = R("MineSetPacks")
local SetPets = R("MineSetPets")
local function out(tag, ...) print(tag .. " " .. table.concat({ ... }, " ")) end
local LAD = { "F", "D", "C", "B", "A", "S", "SS", "SSS" }

-- 1. the ladder
out("LADDER", table.concat(Ranks.LADDER or {}, ","))
local top, floor = Ranks.odds(1), Ranks.odds(3)
local sumT, sumF, rarer, lift = 0, 0, true, true
for i, r in ipairs(LAD) do
	sumT += top[r]; sumF += floor[r]
	if i > 1 and not (Ranks.WEIGHT[r] < Ranks.WEIGHT[LAD[i - 1]]) then rarer = false end
	if i > 1 and not ((Ranks.LIFT[r] or 0) >= (Ranks.LIFT[LAD[i - 1]] or 0)) then lift = false end
end
out("ODDS", string.format("%.9f %.9f %s %s", sumT, sumF, tostring(rarer), tostring(lift)))
out("SHARES", string.format("F %.4f>%.4f SSS %.5f<%.5f S %.4f A %.4f", top.F, floor.F, top.SSS, floor.SSS, floor.S, floor.A))
out("LABELS", tostring(Ranks.LABEL.F), tostring(Ranks.LABEL.SSS), tostring(Ranks.badge("S")))

-- 2. chests
local zones = { "meadow", "sunscar", "mistreef", "arcwork", "bloodmoon", "eclipse", "riftmarch", "starfall", "mythral", "primordium", "bigbang" }
local names, dupName, badRank, missing, n = {}, 0, 0, {}, 0
for id, d in pairs(ZC.DEFS) do
	n += 1
	if not Ranks.valid(d.rank) then badRank += 1 print("BADRANK " .. tostring(id)) end
	if names[d.name] then dupName += 1 print("DUPNAME " .. d.name) end
	names[d.name] = true
end
for _, z in ipairs(zones) do
	local have = {}
	for _, row in ipairs(ZC.POOLS[z] or {}) do have[row.rank] = true end
	for _, r in ipairs(LAD) do if not have[r] then table.insert(missing, z .. ":" .. r) end end
end
out("CHESTS", n, dupName, badRank, #missing > 0 and table.concat(missing, ",") or "none")

-- 3. spawn tables
local worstSum, worstSplit, setOutOfPlace, setWrongRank = 0, 0, 0, 0
local seenSet = {}
for _, z in ipairs(zones) do
	for _, L in ipairs({ 1, 100, 249, 250, 1000, 5000 }) do
		local better = C.chestRankLuck(z, L)
		local rows = ZC.spawnTable(z, L, C.zoneIndex(z), better)
		local s, split = 0, {}
		for _, row in ipairs(rows) do
			s += row.p
			if not row.def.shiny then split[row.rank] = (split[row.rank] or 0) + row.p end
			if row.def.setKey then
				seenSet[row.def.id] = true
				local set = SC.BY_KEY[row.def.setKey]
				if set.zoneId ~= z or L < (set.from or 1) then setOutOfPlace += 1 end
				if row.def.rank ~= SC.RANK[row.def.setTier] or row.rank ~= row.def.rank then setWrongRank += 1 end
			end
		end
		worstSum = math.max(worstSum, math.abs(s - 1))
		local odds = Ranks.odds(better)
		local shiny = (z == "bigbang") and 0 or ZC.shinyChance(C.zoneIndex(z), L)
		for _, r in ipairs(LAD) do
			worstSplit = math.max(worstSplit, math.abs((split[r] or 0) - odds[r] * (1 - shiny)))
		end
	end
end
local nSeen = 0
for _ in pairs(seenSet) do nSeen += 1 end
out("SPAWN", string.format("%.2e %.2e", worstSum, worstSplit), setOutOfPlace, setWrongRank, nSeen)

-- 4. pays more by rank
local function caseValue(rank)
	local v = 0
	for _, r in ipairs(Cases.chestCaseOdds(rank)) do v += r.p * Cases.expectedDust(r.def.id) end
	return v
end
local function skinValue(rank)
	local v, IDX = 0, { F = 1, D = 2, C = 3, B = 4, A = 5, S = 6, SS = 7, SSS = 8 }
	for _, r in ipairs(C.skinCaseTierOdds(rank)) do v += r.p * IDX[r.tier] end
	return v
end
local function packScore(def, z)
	local W = { pack_common = 1, pack_rare = 4, pack_legendary = 16, currency_common = 1, currency_rare = 3 }
	local s = 0
	for _, pk in ipairs(ZC.payout(def, z, 500).packs) do s += (pk.chance / 100) * (W[pk.slot] or 0) end
	return s
end
local notMono = {}
for _, z in ipairs(zones) do
	local byRank = {}
	for _, row in ipairs(ZC.POOLS[z]) do byRank[row.rank] = byRank[row.rank] or ZC.DEFS[row.chestId] end
	for i = 2, #LAD do
		local a, b = byRank[LAD[i - 1]], byRank[LAD[i]]
		local pa, pb = ZC.payout(a, z, 500), ZC.payout(b, z, 500)
		local function m(x) return (x[1] + x[2]) / 2 end
		if not (m(pb.coins) > m(pa.coins)) then table.insert(notMono, z .. " coins " .. LAD[i]) end
		if ZC.GEM_BASE[z] > 0 and not (m(pb.gems) > m(pa.gems)) then table.insert(notMono, z .. " gems " .. LAD[i]) end
		if not (packScore(b, z) > packScore(a, z)) then table.insert(notMono, z .. " packs " .. LAD[i]) end
	end
end
for i = 2, #LAD do
	local a, b = LAD[i - 1], LAD[i]
	if not (caseValue(b) >= caseValue(a)) then table.insert(notMono, "case " .. b) end
	if not (skinValue(b) >= skinValue(a)) then table.insert(notMono, "skin " .. b) end
	if not ((E.CHEST_BUNDLE[b] or E.CHEST_BUNDLE_BASE) >= (E.CHEST_BUNDLE[a] or E.CHEST_BUNDLE_BASE)) then table.insert(notMono, "books " .. b) end
	if not ((E.XP_CHEST_RANK[b] or 1) > (E.XP_CHEST_RANK[a] or 1)) then table.insert(notMono, "xp " .. b) end
end
out("MONO", #notMono > 0 and table.concat(notMono, ",") or "none")
out("SSSCASE", string.format("%.1f %.1f", caseValue("SSS"), caseValue("F")))

-- 5. the 57 set chests
local setN, setDup, badPack, badSet, homes = 0, 0, 0, 0, {}
local setNames = {}
for _, set in ipairs(SC.SETS) do
	if not SetPets.BY_KEY[set.key] then badSet += 1 print("NOSET " .. set.key) end
	if not ZC.POOLS[set.zoneId] then badSet += 1 end
	homes[set.zoneId] = (homes[set.zoneId] or 0) + 1
	for _, tier in ipairs(SC.TIERS) do
		local d = ZC.DEFS[SC.chestId(set.key, tier)]
		if d then
			setN += 1
			if setNames[d.name] then setDup += 1 end
			setNames[d.name] = true
			for _, r in ipairs(SC.packOdds(set.key, tier)) do
				if not (SetPacks.PACK_BY_ID and SetPacks.PACK_BY_ID[r.packId]) then badPack += 1 print("NOPACK " .. r.packId) end
			end
		end
	end
end
local homeLine = {}
for _, z in ipairs(zones) do table.insert(homeLine, z .. "=" .. tostring(homes[z] or 0)) end
out("SETS", #SC.SETS, setN, setDup, badPack, badSet, SC.RANK.low, SC.RANK.mid, SC.RANK.high)
out("HOMES", table.concat(homeLine, ","))

-- 6. the draw matches the tables
do
	local rng = Random.new(5)
	local z, L = "sunscar", 300
	local rows = ZC.spawnTable(z, L, C.zoneIndex(z), C.chestRankLuck(z, L))
	local want, got, N = {}, {}, 200000
	for _, row in ipairs(rows) do want[row.def.id] = (want[row.def.id] or 0) + row.p end
	local realNew = Random.new
	Random.new = function() return rng end
	for _ = 1, N do
		local d = ZC.rollSpawn(z, L, C.zoneIndex(z), C.chestRankLuck(z, L))
		got[d.id] = (got[d.id] or 0) + 1
	end
	Random.new = realNew
	local worst = 0
	for id, p in pairs(want) do worst = math.max(worst, math.abs((got[id] or 0) / N - p)) end
	out("DRAW", string.format("%.4f", worst))
	-- currency and packs stay inside the payout's bands; a set chest pays its set pack
	local inBand, setPack = true, true
	for _, row in ipairs(rows) do
		local pay = ZC.payout(row.def, z, L)
		for _ = 1, 30 do
			local c, g = ZC.rollCurrency(row.def, rng, L, z)
			if c < math.max(1, pay.coins[1]) or c > math.max(1, pay.coins[2]) or g < pay.gems[1] or g > pay.gems[2] then inBand = false end
			if row.def.setKey then
				local ids = ZC.rollPackDrops(z, row.def, rng, L)
				local found = false
				for _, id in ipairs(ids) do
					if string.sub(id, 1, #row.def.setKey + 6) == row.def.setKey .. "_pack_" then found = true end
				end
				if not found then setPack = false end
			end
		end
	end
	out("BANDS", tostring(inBand), tostring(setPack))
	local old = ZC.roll(z, rng, { layer = L, zoneIndex = C.zoneIndex(z), better = C.chestRankLuck(z, L) })
	out("FALLBACK", tostring(old and old.def and old.def.rank == old.rank and Ranks.valid(old.rank)))
end
end)
if not ok then print("ERROR " .. tostring(err)) end
`;

const lua = Shared.prelude(ROOT, mods, ["SetPets", "HolidayPets"]) + Stubs.ROBLOX + test;
const tmp = path.join(require("os").tmpdir(), `mfc-chest-ranks-${process.pid}.luau`);
fs.writeFileSync(tmp, lua);
let outText = "";
try {
  outText = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8", maxBuffer: 1 << 26 });
} catch (e) {
  outText = String(e.stdout || "") + String(e.stderr || "");
}
try { fs.unlinkSync(tmp); } catch (e) { /* gone */ }
const get = (tag) => {
  const m = outText.match(new RegExp("^" + tag + " (.*)$", "m"));
  return m ? m[1] : "";
};
const err = get("ERROR");
check(!err && outText.includes("LADDER"), "the real modules load and run", err || "");

// 1
check(get("LADDER") === "F,D,C,B,A,S,SS,SSS", "eight ranks, F to SSS", get("LADDER"));
const [sumT, sumF, rarer, lift] = get("ODDS").split(" ");
check(Math.abs(Number(sumT) - 1) < 1e-6 && Math.abs(Number(sumF) - 1) < 1e-6, "the rank odds sum to 1 at a zone's top and floor");
check(rarer === "true", "every rank is rarer than the one below it");
check(lift === "true", "depth lifts a rarer rank at least as hard as the one below it");
const sh = get("SHARES").match(/F ([\d.]+)>([\d.]+) SSS ([\d.]+)<([\d.]+) S ([\d.]+) A ([\d.]+)/);
check(sh && Number(sh[2]) < Number(sh[1]) && Number(sh[4]) > Number(sh[3]) * 3,
  "deeper: fewer Common chests, and Exotic over 3x as common at a zone's floor", get("SHARES"));
check(sh && Math.abs(Number(sh[5]) - 0.022) < 0.005 && Math.abs(Number(sh[6]) - 0.049) < 0.01,
  "the floor's S and A shares stay near the old ladder's (2.2%, 4.9%)", sh ? `S ${sh[5]} A ${sh[6]}` : "");
check(get("LABELS") === "Common Exotic S · Mythic", "the badge words are the packs' and charms' (Common .. Exotic)", get("LABELS"));

// 2
const ch = get("CHESTS").split(" ");
check(Number(ch[0]) >= 80 + 57, `every chest is defined (${ch[0]}: 11 zones' own, the Shiny Chest and the 57 set chests)`);
check(ch[1] === "0", "every chest has its own name", `${ch[1]} shared`);
check(ch[2] === "0", "every chest has one rank, F..SSS", `${ch[2]} without`);
check(ch[3] === "none", "every zone has a chest of every rank", ch[3]);

// 3
const sp = get("SPAWN").split(" ");
check(Number(sp[0]) < 1e-9, "the spawn table sums to 1 at every sampled depth", sp[0]);
check(Number(sp[1]) < 1e-9, "the set chests leave the rank split exactly as MineChestRanks.odds says", sp[1]);
check(sp[2] === "0", "a set chest spawns only in its set's zone, from its set's layer", `${sp[2]} out of place`);
check(sp[3] === "0", "a set chest spawns only at its own rank (low D, mid B, high S)", `${sp[3]} wrong`);
check(Number(sp[4]) === 57, "all 57 set chests can spawn somewhere", sp[4]);

// 4
check(get("MONO") === "none", "a rarer rank pays more: gems, coins, packs, cases, skin cases, books and XP", get("MONO"));

// 5
const st = get("SETS").split(" ");
check(st[0] === "19" && st[1] === "57", "19 sets, 3 chests each", `${st[0]} sets, ${st[1]} chests`);
check(st[2] === "0", "the 57 set chests have 57 names", `${st[2]} shared`);
check(st[3] === "0", "every set chest pays real packs of its own set", `${st[3]} missing`);
check(st[4] === "0", "every set is a real set, living in a real zone", `${st[4]} bad`);
check(st[5] === "D" && st[6] === "B" && st[7] === "S", "a low, a mid and a high rank", st.slice(5).join(" "));
const homes = Object.fromEntries(get("HOMES").split(",").map((kv) => kv.split("=")));
check(homes.meadow === "1" && ["sunscar", "mistreef", "arcwork", "bloodmoon", "eclipse", "riftmarch", "starfall", "mythral", "primordium"].every((z) => homes[z] === "2") && homes.bigbang === "0",
  "the sets live where the game is at their power: Pebblebound in the Meadow, then two a zone", get("HOMES"));

// 6
check(Number(get("DRAW")) < 0.005, "rollSpawn draws the spawn table (200,000 chests)", `worst gap ${get("DRAW")}`);
check(get("BANDS") === "true true", "coins and gems land inside the rank's bands, and a set chest pays its set's pack", get("BANDS"));
check(get("FALLBACK") === "true", "an old block's unknown chest rolls a ranked chest of its zone");

// 7 wiring
const strip = (s) => s.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
const SRV = strip(read("src/ServerScriptService/Mine/MineServer.server.luau"));
const open = (SRV.match(/local function openChestBlock\([\s\S]*?\nend\n/) || [""])[0];
check(open.length > 1000, "openChestBlock was found");
check(/local rank = def and def\.rank/.test(open) && !/exclusiveFor/.test(open),
  "the block's own chest pays, by its own rank (no more section-chest override)");
check(/ZoneChests\.rollCurrency\(def, rng, layer, zone\.id\)/.test(open) && /ZoneChests\.rollPackDrops\(zone\.id, def, rng, layer\)/.test(open),
  "coins, gems and packs are rolled for the chest's layer");
check(/packRow\(packId\)/.test(open), "a set chest's set pack goes in the bag as a set pack row");
check(/SetAttribute\("ChestRank", chestDef\.rank\)/.test(SRV), "the rank is stamped on the block");
check(/rank = rank,/.test(open), "chestOpened tells the client the rank");
const CLI = strip(read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau"));
check(/GetAttribute\("ChestRank"\)/.test(CLI) && /payload\.rank == "SSS"/.test(CLI) && /"  ·  " \.\. payload\.rank/.test(CLI),
  "the badge shows on the hover line and the chest card, and S+ plays the pluck");
check(/GetAttribute\("ChestRank"\)/.test(read("src/ReplicatedStorage/Mine/Shared/MineChestModel.luau")),
  "the lid wears the badge (MineChestModel)");
check(/Ranks\.COLOR\[def\.rank\]/.test(read("src/ReplicatedStorage/Mine/Shared/MineInventoryView.luau")),
  "the chest dex shows each chest's badge");
const CFG = read("src/ReplicatedStorage/Mine/Shared/MineConfig.luau");
check(/MineConfig\.CHEST_CHANCE = 0\.003\b/.test(CFG), "the chest count is unchanged (CHEST_CHANCE 0.003)");
const cases = read("src/ReplicatedStorage/Mine/Shared/MineCases.luau");
const ench = read("src/ReplicatedStorage/Mine/Shared/MineEnchants.luau");
check(/CHEST_RANK_SHIFT = \{[^}]*SSS = /.test(cases) && /CHEST_SKIN_RANK_SHIFT = \{[^}]*SSS = /.test(CFG)
  && /XP_CHEST_RANK = \{[^}]*SSS = /.test(ench) && /CHEST_BUNDLE = \{[^}]*SSS = /.test(ench) && /BOOK_RANK_LEVEL = \{[\s\S]*?SSS = /.test(ench),
  "every rank-keyed table reaches SS and SSS (cases, skin cases, XP, books)");

console.log("");
console.log(fail > 0 ? `>>> chest-ranks: ${fail} FAILED` : ">>> chest-ranks: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
