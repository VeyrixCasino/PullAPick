// THE CANDY CRYPT v2 (owner, 2026-10-19; wiki/open-questions.md "Candy Crypt
// v2, and the main-game changes it brings"), server and shared half.
//
// Runs the REAL shared modules -- MineConfig, MineCandyTools, MineCryptChests,
// MineTrickOrTreat, MineCryptRules, MineCharms, MineToolSkins, MineSkins,
// MineOrePouch, MineSpaceMatter, MineBreaking, MineOreTools and the rest of
// their require tree -- and the real server module MineCrypt, in luau, on the
// Crypt harness (tools/verify/_crypt.js). Nothing is re-derived in JS.
//
// What it pins, in the build spec's order:
//   1 candy only     no normal ore spawns in the Crypt; every other block is
//                    candy; the 20-minute reset and zone 3 -> 10 rock stay
//   2 candy ores     sixteen, two per rarity; a fixed drop per ore; the odds
//                    shift every ten layers and the Exotic pair stays capped
//   3 candy          flat per ore, the same at every depth, about a quarter
//                    of the block's ore-drop value; sold from the Halloween
//                    inventory
//   4 chests         eight ranks, rarer rarer and more common deeper; packs,
//                    flat candy, the rank's charm at 0.5% x Chest Luck, books
//   5 Trick-or-Treat pets and skins only; the 50/50; one push
//   6 tools          crafted from candy ores, never dropped; prestige 1-10;
//                    damage at every prestige; the cap of ten; scrap pays half
//                    in candy; each tool's Halloween-skin factor; the top tool
//                    at prestige 10 is the best normal tool at the top level
//   7 inventory      the Halloween inventory, its own team and charm slot,
//                    what counts in the Crypt, and the event-end move
//   8 trading        tradeLocked, and TradeService asking it
//   9 v1 retired     merge, chest/case tools, the six crafted charms
//   + the MineServer hooks the build spec names
//
// Needs the luau binary (bash tools/verify/syntax.sh fetches it).
//
//   node tools/verify/crypt.js
//   node tools/verify/crypt.js --root <path to another checkout>   (proves it bites)
"use strict";
const fs = require("fs");
const path = require("path");
const H = require("./_crypt");
const Luau = H.Luau;

const argRoot = (() => {
  const i = process.argv.indexOf("--root");
  return i > 0 && process.argv[i + 1] ? path.resolve(process.argv[i + 1]) : null;
})();
const ROOT = argRoot || H.ROOT;
const SH = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared");
const SV = path.join(ROOT, "src/ServerScriptService/Mine");
const read = (p) => (fs.existsSync(p) ? Luau.readSrc(p) : "");

let fail = 0;
const check = (ok, msg, detail) => {
  console.log((ok ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!ok) fail++;
};
const strip = (s) => s.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");

console.log("crypt: the Candy Crypt v2 -- candy, ores, chests, case, tools, Halloween inventory, trading"
  + (argRoot ? `   (root ${argRoot})` : ""));

// ------------------------------------------------------------ static wiring --
const srv = strip(read(path.join(SV, "MineServer.server.luau")));
const bodyOf = (src, name) => {
  const lines = src.split("\n");
  const re = new RegExp("^(local )?function " + name.replace(/\./g, "\\.") + "\\s*\\(");
  const i = lines.findIndex((l) => re.test(l));
  if (i < 0) return "";
  for (let j = i + 1; j < lines.length; j++) if (lines[j] === "end") return lines.slice(i, j + 1).join("\n");
  return "";
};
{
  const bz = bodyOf(srv, "buyZone");
  check(/C\.limitedActive\(zone\.id\)/.test(bz) && /zone\.ownedFlag/.test(bz) && /Verbs\.Crypt\.onClaim\(/.test(bz),
    "buyZone claims the Crypt on its own window and flag, and hands over the starter pick");
  const ez = bodyOf(srv, "enterZone");
  check(/Dig\.Crypt\.onClaim\(/.test(ez) && /Dig\.Crypt\.onEnterZone\(/.test(ez),
    "enterZone grants the starter on a free claim and re-gives the hands on entry");
  const th = bodyOf(srv, "Dig.toolInHand");
  const ehAt = th.indexOf('p.zoneId == "bigbang"');
  const crAt = th.indexOf("Dig.Crypt.heldTool(p)");
  check(ehAt > -1 && crAt > ehAt, "the held tool swaps in the Halloween tool, after Event Horizon's own branch");
  check(/Dig\.wearSkin\(p, row, fam\)/.test(bodyOf(srv, "equippedTool")),
    "equippedTool wears the skin on whatever is held (the Halloween factor rides MineToolSkins.wear)");
  for (const fn of ["swingBlock", "swingNeighbour"]) {
    check(/if zone and zone\.noStrengthGate then\s+okBreak = true/.test(bodyOf(srv, fn)),
      fn + " honours the zone's noStrengthGate (the Crypt's HP is its gate)");
  }
  check(/zoneId == "hallow" and Dig\.Crypt[\s\S]{0,80}Dig\.Crypt\.haulPoints\(/.test(bodyOf(srv, "payDamage")),
    "payDamage pays the Crypt's haul on the old low curve");
  const fb = bodyOf(srv, "finishBreak");
  const candyAt = fb.indexOf("Dig.Crypt.onBlockBroken(");
  const oreAt = fb.indexOf('if kind == "ore" then');
  check(candyAt > -1 && oreAt > candyAt, "a candy block pays OUTSIDE the ore branch (any kind of block)");
  check(/GetAttribute\("ZoneId"\) == "hallow"[\s\S]{0,60}Dig\.Crypt\.openChest\(/.test(bodyOf(srv, "openChestBlock")),
    "a Crypt chest opens through MineCrypt");
  const sv = bodyOf(srv, "spawnVoxel");
  check(/part:SetAttribute\("Candy", C\.candyFor\(cdef, y\)\)/.test(sv) && /C\.CANDY_ORE_SHARE/.test(sv)
    && /Dig\.Crypt\.chestSpawnDef\(y\)/.test(sv),
    "spawnVoxel banks the flat candy (MineConfig.candyFor), reads CANDY_ORE_SHARE, and asks MineCrypt which chest");
  check(/string\.sub\(action, 1, 5\) == "crypt"[\s\S]{0,120}Verbs\.Crypt\.dispatch\(/.test(srv),
    "every \"crypt*\" action dispatches to MineCrypt");
  check(/crypt = Dig\.Crypt and Dig\.Crypt\.snapState\(p\)/.test(srv), "the snapshot carries the crypt block");
  check(/Verbs\.Crypt\.buyTrickOrTreat\(plr\)/.test(bodyOf(srv, "Verbs.buyTrickOrTreat")),
    "the Trick-or-Treat verb is served by MineCrypt");
  // 7: what counts where you stand.
  check(/Dig\.Crypt and Dig\.Crypt\.petTeam\(p\)/.test(bodyOf(srv, "Dig.petRows")),
    "the pets boosts() stacks are MineCrypt.petTeam's (only Halloween pets count in the Crypt)");
  const bo = bodyOf(srv, "boosts");
  check(/local n = #\(\(Dig\.Crypt and Dig\.Crypt\.petTeam\(p\)\) or p\.equipped or \{\}\)/.test(bo),
    "...and so is the team size boosts() hands to each pet");
  check(/worn = Dig\.Crypt\.charmFor\(p\)[\s\S]{0,80}Charms\.applyEquipped\(b, worn, p\)/.test(bo)
    && !/Charms\.applyEquipped\(b, p\.equippedCharm, p\)/.test(bo),
    "the charm boosts() applies is MineCrypt.charmFor's (a Halloween charm in the Crypt)");
  check(/Dig\.Crypt\.mainTeamRefuses\(p, id\)/.test(bodyOf(srv, "equip")),
    "the main team's equip refuses a Halloween pet while the event runs");
  check(/grantPet = function\(plr, p, pet, setKey\)[\s\S]{0,400}mint\(SetPacks\.petCard\(pet, setKey, setName\), plr\.UserId\)/.test(srv),
    "MineCrypt is handed the real pet mint (a Trick-or-Treat pet is a registered card)");
  const keep = (srv.match(/Verbs\.KEEP_ON_REBIRTH = \{[\s\S]*?\n\}/) || [""])[0];
  check(/"halloween"/.test(keep) && !/"cryptTools"/.test(keep), "a rebirth keeps the Halloween inventory (and no v1 field)");
}
{
  // 8: TradeService asks MineCrypt at offer, peek and commit.
  const ts = strip(read(path.join(SV, "TradeService.luau")));
  const setOffer = ts.slice(ts.indexOf("function TradeService.setOffer"), ts.indexOf("function TradeService.setMode"));
  const peek = ts.slice(ts.indexOf("function TradeService.peek"), ts.indexOf("local function removeRows"));
  const gather = bodyOf(ts, "gather");
  check(/cryptMod\.tradeLocked/.test(ts) && /FindFirstChild\("MineCrypt"\)/.test(ts),
    "TradeService looks MineCrypt.tradeLocked up (lazily; a missing module locks nothing)");
  check(/tradeLocked\(p, "cards", c\)/.test(setOffer) && /tradeLocked\(p, "packs", pk\)/.test(setOffer),
    "an offer drops locked cards and packs");
  check(/tradeLocked\(p, "cards", c\)/.test(peek), "browsing the other bag does not show their locked pets");
  check(/tradeLocked\(p, "cards", c\)/.test(gather), "and the commit asks again (the event can start mid-trade)");
}
{
  // 9: v1 retired in the source.
  const charms = strip(read(path.join(SH, "MineCharms.luau")));
  check(!/function MineCharms\.candyCharms/.test(charms) && !/function MineCharms\.recipeFor/.test(charms)
    && !/MineCharms\.CANDY_CHARMS = \{/.test(charms) && /MineCharms\.RETIRED_CANDY_CHARMS = \{/.test(charms),
    "the six crafted candy charms are gone from MineCharms (their ids listed for the load clean-up)");
  const crypt = strip(read(path.join(SV, "MineCrypt.luau")));
  check(!/VERBS\.cryptMerge/.test(crypt) && !/VERBS\.cryptCraftCharm/.test(crypt),
    "no merge verb and no charm crafting");
  const tools = strip(read(path.join(SH, "MineCandyTools.luau")));
  check(tools.length > 0 && !/rollChestTool|rollCaseTool|CHEST_TOOL_CHANCE/.test(tools),
    "Halloween tools never drop: no chest or case tool roll is left");
}

if (!Luau.ready) {
  console.log("  " + Luau.missing("luau") + "; skipping the luau half");
  console.log(fail === 0 ? ">>> crypt OK (static only)" : `>>> crypt: ${fail} FAILED`);
  process.exit(fail === 0 ? 0 : 1);
}

// --------------------------------------------------------------- the luau half --
const body = `
local fails = 0
local function check(cond, name, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail ~= nil and ("   " .. tostring(detail)) or ""))
	if not cond then fails += 1 end
end
local function near(a, b, tol) return math.abs(a - b) <= tol end
local function try(label, fn)
	local ok, err = pcall(fn)
	if not ok then check(false, label .. " ran to the end", tostring(err)) end
end

local C = require("MineConfig")
local Depth = require("MineDepth")
local Breaking = require("MineBreaking")
local OreTools = require("MineOreTools")
local Tools = require("MineCandyTools")
local Chests = require("MineCryptChests")
local TT = require("MineTrickOrTreat")
local Charms = require("MineCharms")
local Pouch = require("MineOrePouch")
local Matter = require("MineSpaceMatter")
local Skins = require("MineSkins")
local ToolSkins = require("MineToolSkins")
local E = require("MineEnchants")
local R = require("MineCryptRules")
local S = require("MineCrypt")
local N = C.CANDY_DEPTH_LAYERS
local CO = C.CANDY_ORES

-- The window, moved by hand: LIMITED_WINDOWS.hallow is read on every call.
local realWindow = C.LIMITED_WINDOWS.hallow
local now = os.time()
local function duringEvent() C.LIMITED_WINDOWS.hallow = { opensUnix = now - 86400, closesUnix = now + 86400 } end
local function afterEvent() C.LIMITED_WINDOWS.hallow = { opensUnix = now - 2 * 86400, closesUnix = now - 60 } end
duringEvent()

-- ------------------------------------------------------------ 1. candy only --
print("")
print(" 1. candy blocks only")
local crypt = C.zoneById("hallow")
check(crypt and crypt.candyOnly == true and crypt.eventToolsOnly and crypt.noStrengthGate and C.isCandyOnly("hallow")
	and not C.isCandyOnly("meadow"), "the Crypt's row says candyOnly (and still event tools only, no strength gate)")
check(C.CANDY_ORE_SHARE == 1, "every Crypt block that is not a chest is a candy block (CANDY_ORE_SHARE 1)")
do
	local crypts, meadow = 0, 0
	for l = 1, N, 3 do
		for x = 0, 2 do
			for z = 0, 2 do
				if C.veinOreAt("hallow", x, l, z, 1) then crypts += 1 end
				if C.oreIdentity("hallow", l, Random.new(l * 31 + x), 1) then crypts += 1 end
				if C.rollOre("hallow", l, Random.new(l * 7 + z), 1) then crypts += 1 end
			end
		end
	end
	for l = 1, 400 do
		for x = 0, 20, 4 do
			if C.veinOreAt("meadow", x, l, x, 1) then meadow += 1 end
		end
	end
	check(crypts == 0, "no normal ore spawns in the Crypt (veinOreAt, oreIdentity, rollOre)", crypts)
	check(meadow > 0, "...while the meadow still has its ore", meadow)
end
check(C.cryptRockHp(1) == Depth.dirtHp(3, 1) and C.cryptRockHp(N) == Depth.dirtHp(10, 1),
	"the rock is still zone 3 at the top and zone 10 at the bottom", C.cryptRockHp(N))
check(C.MINE_RESET_SEC == 1200, "the 20-minute reset is unchanged", C.MINE_RESET_SEC)

-- ------------------------------------------------------------ 2/3. candy ores --
print("")
print(" 2-3. sixteen candy ores: two per rarity, a fixed drop, flat candy, shifting odds")
check(#CO == 16, "sixteen candy ores", #CO)
do
	local bands, rising, quarter, fixed, flat = {}, true, true, true, true
	local worst = 0
	for i, o in ipairs(CO) do
		bands[o.band] = (bands[o.band] or 0) + 1
		local dv = o.drop * o.value
		if i > 1 and dv <= CO[i - 1].drop * CO[i - 1].value then rising = false end
		-- "about a quarter" of the ore-drop value, rounded to whole candy.
		if not (o.candy >= 1 and math.abs(o.candy - 0.25 * dv) <= 0.5) then quarter = false end
		worst = math.max(worst, math.abs(o.candy - 0.25 * dv) / math.max(1, dv))
		for _, l in ipairs({ 1, 11, 47, 88, 120, 160, 400 }) do
			if C.candyDropFor(o) ~= o.drop then fixed = false end
			if C.candyFor(o, l) ~= o.candy then flat = false end
		end
	end
	local two = true
	for _, b in ipairs(C.CANDY_BANDS) do
		if bands[b] ~= 2 then two = false end
	end
	check(two and CO[1].band == "Common" and CO[16].band == "Exotic", "two to each rarity, Common to Exotic, by value")
	check(rising, "every rarer ore's block is worth more than the one before it (drop x value)")
	check(fixed, "each ore drops the same number of items at every depth")
	check(flat, "each ore's block pays the same candy at every depth")
	check(quarter, "...about a quarter of its ore-drop value", string.format("worst %.3f", worst))
	check(C.candyOreValue("stone") == 0 and R.candyOreValue("not_a_candy") == 0 and C.candyOreValue("jawbreaker") == CO[16].value,
		"only candy ores sell for candy, at their own value")
end
do
	local sums, capOk, shifts, holds, equalIn = true, true, true, true, true
	local prev = nil
	for s = 1, 14 do
		local w = C.candyRarityOdds(s)
		local t = 0
		for _, v in ipairs(w) do t += v end
		if not near(t, 1, 1e-9) then sums = false end
		if w[8] > C.CANDY_ECONOMY.EXOTIC_CAP + 1e-12 then capOk = false end
		if prev and s <= C.CANDY_ECONOMY.SECTIONS then
			if not (w[1] < prev[1] and w[8] > prev[8]) then shifts = false end
		elseif prev then
			for k = 1, 8 do if w[k] ~= prev[k] then holds = false end end
		end
		for k = 2, 8 do if w[k] >= w[k - 1] then capOk = false end end
		prev = w
	end
	for s = 1, 12 do
		local a = C.candyOreOdds((s - 1) * 10 + 1)
		local b = C.candyOreOdds(s * 10)
		for i = 1, 16 do if a[i] ~= b[i] then equalIn = false end end
	end
	check(sums, "each section's odds sum to 1")
	check(shifts and equalIn, "every ten layers the odds shift toward the rarer ores (and hold within a section)")
	check(holds, "past section " .. C.CANDY_ECONOMY.SECTIONS .. " (the bottom) they hold")
	check(capOk, "the rarest stay rare: Exotic never over " .. (C.CANDY_ECONOMY.EXOTIC_CAP * 100) .. "%, every rarity rarer than the one below",
		string.format("bottom Exotic %.4f", C.candyRarityOdds(12)[8]))
	-- The cap holds whatever the ratios are set to: at a 0.95 ratio an uncapped
	-- Exotic would be 10%; capped it is the cap, the rest scaled to fill.
	local cap = C.CANDY_ECONOMY.EXOTIC_CAP
	local hot = C.capRatioWeights(8, 0.95, cap)
	local t, order = 0, true
	for k, v in ipairs(hot) do
		t += v
		if k > 1 and k < 8 and v >= hot[k - 1] then order = false end
	end
	check(near(hot[8], cap, 1e-12) and near(t, 1, 1e-9) and order,
		"the cap holds at any ratio (0.95: Exotic " .. string.format("%.2f%%", hot[8] * 100) .. ", still summing to 1)")
end
do
	-- 200,000 real rolls at the bottom section land on the odds.
	local odds = C.candyOreOdds(115)
	local got = {}
	local rng = Random.new(1031)
	local n = 200000
	for _ = 1, n do
		local o = C.candyOreAt(115, rng, N)
		got[o.rank] = (got[o.rank] or 0) + 1
	end
	local worst = 0
	for i = 1, 16 do
		worst = math.max(worst, math.abs((got[i] or 0) / n - odds[i]))
	end
	check(worst < 0.004, "200,000 candyOreAt rolls at layer 115 land on the section's odds", string.format("worst %.4f", worst))
end

-- ------------------------------------------------------------ the server, set up --
local sent = {}
local function lastSent(name)
	for i = #sent, 1, -1 do if sent[i].name == name then return sent[i].payload end end
	return nil
end
local net = { FireClient = function(_, plr, name, payload) table.insert(sent, { name = name, payload = payload }) end }
local cardN = 0
local function grantPet(plr, q, pet, setKey)
	cardN += 1
	local c = { id = "card" .. cardN, serial = "S" .. cardN, name = pet.name, setId = setKey,
		cardKey = setKey .. ":" .. pet.name, rarityId = pet.tier }
	q.cards = q.cards or {}
	table.insert(q.cards, c)
	return c
end
local plr = { UserId = 7 }
local p = { ores = {}, oreLocks = {}, charms = {}, cards = {}, equipped = {}, candy = 0, backpackTier = 1,
	orePouchTier = 10, hallowOwned = false, petSlots = 3 }
local profiles = { [7] = p }
local given = 0
S.init({
	profiles = profiles, net = net, noTick = true,
	snap = function() end, markDirty = function() end,
	givePickaxe = function() given += 1 end,
	bumpStat = function() end, chestXp = function() end,
	grantPet = grantPet,
})
local function part(zoneId, extra)
	local attrs = { ZoneId = zoneId, HP = 100, MaxHP = 100 }
	for k, v in pairs(extra or {}) do attrs[k] = v end
	return { attrs = attrs, Position = Vector3.new(0, 0, 0), Color = Color3.fromRGB(1, 2, 3),
		GetAttribute = function(self, k) return self.attrs[k] end,
		SetAttribute = function(self, k, v) self.attrs[k] = v end }
end

-- ------------------------------------------------------------ 6. tools --
print("")
print(" 6. Halloween tools: crafted, prestiged, capped, scrapped, skinned, and the top tool's match")
local all = Tools.all()
check(#all == 16, "sixteen Halloween tools, one per candy ore", #all)
do
	local ids, ores, fams, okRow = {}, {}, {}, true
	for _, t in ipairs(all) do
		if ids[t.id] or ores[t.oreId] or not C.candyOreById(t.oreId) or t.power ~= nil or t.price ~= nil then okRow = false end
		ids[t.id], ores[t.oreId] = true, true
		fams[t.family] = (fams[t.family] or 0) + 1
		if t.craft ~= Tools.CRAFT_BY_BAND[t.band] or t.band ~= C.candyOreById(t.oreId).band then okRow = false end
		if not (t.cryptTool and t.eventOnly == false and string.sub(t.id, 1, 7) == "hallow_") then okRow = false end
		if t.family == "explosive" and not (t.cooldown and t.pattern) then okRow = false end
		if t.family == "drill" and not (t.shape == "dir" and t.width) then okRow = false end
	end
	check(okRow, "each is crafted from its own ore, at its rarity's cost, and is a real tool of its family")
	check(fams.pickaxe == 4 and fams.hammer == 4 and fams.drill == 4 and fams.explosive == 4,
		"four families, four tools each")
	check(Tools.STARTER_ID == all[1].id and all[1].family == "pickaxe" and all[1].oreId == "candy_corn",
		"the starter is the Candy Corn Pick")
end
do
	local climbs, prestigeClimbs, ladderOk, pickHits = true, true, true, true
	for i, t in ipairs(all) do
		if i > 1 then
			local prev = all[i - 1]
			if Tools.basePower(t) / OreTools.familyPower(t.family) <= Tools.basePower(prev) / OreTools.familyPower(prev.family) then
				climbs = false
			end
		end
		local hits = C.cryptRockHp(t.tuneLayer) / (Tools.cryptPower(t, 0, 0) / OreTools.familyPower(t.family))
		if math.abs(hits - Tools.PICK_HITS) > 0.05 then pickHits = false end
		local lad = R.prestigeLadder(t, 0)
		if #lad ~= 11 or lad[1].prestige ~= 0 or lad[11].prestige ~= 10 or lad[1].cost ~= nil then ladderOk = false end
		for k = 2, 11 do
			if lad[k].crypt <= lad[k - 1].crypt or lad[k].world <= lad[k - 1].world then prestigeClimbs = false end
			if lad[k].cost ~= Tools.prestigeCost(t, k - 1) or lad[k].cost <= (lad[k - 1].cost or 0) then ladderOk = false end
		end
	end
	check(climbs, "each tool up the ladder hits harder (family aside)")
	check(pickHits, "a tool takes " .. Tools.PICK_HITS .. " pick-hits at its own layer at prestige 0 (tuned to the Crypt's rock)")
	check(prestigeClimbs, "every prestige hits harder, in the Crypt and in the main world")
	check(ladderOk, "prestigeLadder gives P0..P10 with each step's rising cost")
	check(Tools.prestigeCost(all[1], 11) == nil and Tools.prestigeCost(all[1], 0) == nil, "there is no prestige 11 (or 0)")
end
do
	-- The owner: "I want the top tool at prestige to be ~the same as top tool, at top level".
	local top = all[#all]
	local best = OreTools.hitPower({ familyId = top.family, tier = #C.ORES, level = C.TOOL_MAX_LEVEL }, 1)
	check(Tools.worldPower(top, 10, 0) == best, "the top tool at prestige 10 hits like the best normal " .. top.family
		.. " at the top level (ore " .. #C.ORES .. ", level " .. C.TOOL_MAX_LEVEL .. ")", best)
	local weaker = true
	for _, t in ipairs(all) do
		local fBest = OreTools.hitPower({ familyId = t.family, tier = #C.ORES, level = C.TOOL_MAX_LEVEL }, 1)
		for k = 0, 10 do
			if not (t == top and k == 10) and Tools.worldPower(t, k, 0) >= fBest then weaker = false end
		end
	end
	check(weaker, "every other tool and prestige is weaker than the best normal tool of its family")
	local lagging, n = true, 0
	for _, t in ipairs(all) do
		if t ~= top then
			-- On rock of the same hardness, a fresh (prestige 0) tool takes more
			-- hits out there than in the Crypt.
			n += 1
			if Tools.worldPower(t, 0, 0) >= Tools.cryptPower(t, 0, 0) then lagging = false end
		end
	end
	check(lagging and n == 15, "at prestige 0 every tool but the top hits softer out there than in the Crypt")
	local _, lv0 = Tools.worldEquivalent(top, 0)
	local _, lv10 = Tools.worldEquivalent(top, 10)
	check(lv0 == 1 and lv10 == C.TOOL_MAX_LEVEL, "prestige walks the main-world level from 1 to the cap")
end
do
	-- The Halloween-skin factor: "always multiplier to the full multiplier".
	local hs, other
	for _, s in ipairs(Skins.LIST) do
		if s.set == "halloween" and s.tier == "S" and not hs then hs = s end
		if s.set ~= "halloween" and s.tier == "S" and not s.pass and not other then other = s end
	end
	local def = all[1]
	local row = R.eventRow(def, { uid = "u1", prestige = 0 }, "hallow", 0)
	local worn = ToolSkins.wear(row, hs)
	check(worn.power == math.max(1, math.floor(row.power * Skins.BASE.S * def.skinFactor)),
		"a Halloween skin on a Halloween tool: its whole multiplier x the tool's own factor", worn.power)
	check(ToolSkins.wear(row, other).power == math.max(1, math.floor(row.power * Skins.BASE.S)),
		"any other skin on it is unchanged")
	local forged = { id = "oretool_x", family = "pickaxe", power = 1000 }
	check(ToolSkins.wear(forged, hs).power == math.floor(1000 * Skins.BASE.S), "a Halloween skin on a normal tool is unchanged")
	local differ = true
	for i = 2, #all do
		if all[i].skinFactor == all[i - 1].skinFactor or not (all[i].skinFactor > 1) then differ = false end
	end
	check(differ, "each tool has its own factor (no two neighbours alike, all above x1)")
	check(R.worldRow(def, { uid = "u1", prestige = 3 }, 0).halloweenSkinFactor == def.skinFactor,
		"the factor rides the main-world row too")
end

-- ------------------------------------------------------------ claim, the starter, the swap --
print("")
print(" 6b. the claim, the starter pick and the swap rule")
S.normalize(p)
check(#p.halloween.tools == 0, "no claim, no tool")
p.hallowOwned = true
S.onClaim(plr, p, crypt)
check(#p.halloween.tools == 1 and p.halloween.tools[1].id == Tools.STARTER_ID and p.halloween.tool == p.halloween.tools[1].uid,
	"claiming the Crypt hands over the Candy Corn Pick, in hand")
S.onClaim(plr, p, crypt)
check(#p.halloween.tools == 1, "a second claim does not hand over a second one")
do
	local q = { hallowOwned = true }
	S.normalize(q)
	check(#q.halloween.tools == 1, "a save with the claim and no tool gets the starter back on load")
end
p.zoneId = "hallow"
local row = S.heldTool(p)
check(row and row.eventMine == "hallow" and row.cryptTool and row.power == Tools.cryptPower(all[1], 0, 0),
	"in the Crypt the player holds their Halloween tool, at its Crypt power", row and row.power)
p.zoneId = "meadow"
check(S.heldTool(p) == nil, "outside the Crypt during the event a Halloween tool is not held")
S.dispatch(plr, "cryptEquip", { world = true })
check(p.cryptToolWorld == nil and lastSent("toast") == R.WORLD_LOCKED_TEXT, "holding one out here is refused during the event")
check(R.heldRow({ halloween = { tools = {} }, zoneId = "hallow" }, "hallow") == R.NONE_ROW, "no Halloween tool in the Crypt is empty hands")
local normalTool = { id = "oretool_x", name = "Stone Pickaxe", power = 10, oreTier = 1 }
p.zoneId = "hallow"
local cryptRow = S.heldTool(p)
check(Matter.reject(cryptRow, part("hallow")) == nil and Matter.reject(normalTool, part("hallow")) == Matter.EVENT_ONLY
	and Matter.reject(cryptRow, part("meadow")) == Matter.EVENT_TOOL, "only Halloween tools spend Crypt rock, and they spend no other")

-- ------------------------------------------------------------ 7. the Halloween inventory --
print("")
print(" 7. the Halloween inventory: candy blocks, the store, the team, the charm slot")
p.candy = 0
local taffy = C.candyOreById("taffy")
local blk = part("hallow", { Candy = C.candyFor(taffy, 33), CandyOre = "taffy" })
check(S.onBlockBroken(plr, p, blk, "dirt", 33, { candyFind = 1 }), "a candy block pays")
check(p.candy == taffy.candy and p.halloween.ores.taffy == taffy.drop and p.ores.taffy == nil,
	"its flat candy, and its fixed drop into the HALLOWEEN inventory (not the main pouch)",
	p.candy .. " candy, " .. tostring(p.halloween.ores.taffy) .. " taffy")
check(p.oresSeen == nil and p.halloween.seen.taffy == true, "a candy ore stays out of oresSeen (the Forge's ore rail)")
p.candy = 0
S.onBlockBroken(plr, p, blk, "dirt", 33, { candyFind = 1.56 })
check(p.candy == math.floor(taffy.candy * 1.56) and p.halloween.ores.taffy == 2 * taffy.drop,
	"Candy Find multiplies the candy, never the ore")
check(Pouch.held({ stone = 5, taffy = 999 }) == 5, "candy ores never take main-pouch room")
do
	-- Selling candy ores, from the Halloween inventory.
	p.halloween.ores = { taffy = 5, jawbreaker = 2 }
	p.oreLocks = { jawbreaker = true }
	p.candy = 0
	S.dispatch(plr, "cryptSellCandyOres", { all = true })
	local ask = lastSent("cryptSellCandyConfirm")
	check(ask and ask.units == 5 and ask.lockedSkipped == 1 and p.halloween.ores.taffy == 5, "the bulk sell asks first, and skips a locked candy ore")
	S.dispatch(plr, "cryptSellCandyOres", { all = true, confirm = true })
	check(p.halloween.ores.taffy == nil and p.candy == 5 * taffy.value, "confirmed, it sells from the Halloween inventory at the ore's value")
	p.ores.stone = 10
	S.dispatch(plr, "cryptSellCandyOres", { oreIds = { "jawbreaker", "stone" }, confirm = true })
	check(p.halloween.ores.jawbreaker == nil and p.ores.stone == 10, "a ticked ore sells even if locked; a normal ore never sells for candy")
	p.oreLocks = {}
end
do
	-- Halloween pets and their own team.
	local hp = grantPet(plr, p, { name = "Spice", tier = "Common" }, "halloween_2026")
	local hp2 = grantPet(plr, p, { name = "Bogle", tier = "Uncommon" }, "halloween_2026")
	local normal = { id = "norm1", serial = "N1", name = "Breezy", setId = "meadow", cardKey = "meadow:Breezy", rarityId = "Rare" }
	table.insert(p.cards, normal)
	check(R.isHalloweenItem("pet", hp) and not R.isHalloweenItem("pet", normal), "a Halloween 2026 pet is a Halloween item; a meadow pet is not")
	check(S.mainTeamRefuses(p, hp.id) and not S.mainTeamRefuses(p, normal.id), "the main team refuses a Halloween pet while the event runs")
	S.dispatch(plr, "cryptTeam", { ids = { hp.id, normal.id, hp.id, hp2.id, "nope" } })
	check(#p.halloween.team == 2 and p.halloween.team[1] == hp.id and p.halloween.team[2] == hp2.id,
		"cryptTeam keeps only owned Halloween pets, once each")
	p.equipped = { normal.id, hp.id }
	p.zoneId = "hallow"
	local t = S.petTeam(p)
	check(#t == 2 and t[1] == hp.id, "in the Crypt only the Halloween team counts")
	p.zoneId = "meadow"
	t = S.petTeam(p)
	check(#t == 1 and t[1] == normal.id, "outside it, the main team counts without Halloween pets (they are in the Halloween inventory)")
	local ids = {}
	for i = 1, 10 do table.insert(ids, grantPet(plr, p, { name = "P" .. i, tier = "Common" }, "halloween_2026").id) end
	S.dispatch(plr, "cryptTeam", { ids = ids })
	check(#p.halloween.team == R.teamCap(p), "the Halloween team has the main team's seats", #p.halloween.team)
	S.dispatch(plr, "cryptTeam", { ids = { hp.id } })
end
do
	-- The Halloween charm slot. A stand-in for the chest charms' module (another
	-- agent's): every rank names one of the graded charms.
	local graded = Charms.GRADED
	Charms.cryptChestCharm = function(rankKey)
		local r = Chests.rank(rankKey)
		return r and graded[r.index] and graded[r.index].id or nil
	end
	local hc = Charms.cryptChestCharm("F")
	check(R.isHalloweenItem("charm", hc) and not R.isHalloweenItem("charm", graded[20].id),
		"a Crypt chest's charm is a Halloween charm; any other is not")
	p.charms[hc] = 1
	p.equippedCharm = graded[20].id
	p.charms[graded[20].id] = 1
	S.dispatch(plr, "cryptCharm", { charmId = graded[20].id })
	check(p.halloween.charm == nil, "only a Halloween charm goes in the Halloween slot")
	S.dispatch(plr, "cryptCharm", { charmId = hc })
	check(p.halloween.charm == hc, "a Halloween charm you own does")
	p.zoneId = "hallow"
	check(S.charmFor(p) == hc, "in the Crypt the Halloween charm counts (not the main one)")
	p.zoneId = "meadow"
	check(S.charmFor(p) == graded[20].id, "outside it, the main charm")
	p.equippedCharm = hc
	check(S.charmFor(p) == nil, "a Halloween charm in the main slot counts nowhere while the event runs")
	p.equippedCharm = graded[20].id
end

-- ------------------------------------------------------------ 6c. craft, prestige, scrap --
print("")
print(" 6c. craft, prestige, scrap")
do
	local mallet = Tools.forOre("gumdrop")
	p.halloween.ores.gumdrop = mallet.craft - 1
	S.dispatch(plr, "cryptCraft", { toolId = mallet.id })
	check(#p.halloween.tools == 1, "one ore short crafts nothing")
	p.halloween.ores.gumdrop = mallet.craft + 5000
	S.dispatch(plr, "cryptCraft", { toolId = mallet.id })
	local e = p.halloween.tools[2]
	check(e and e.id == mallet.id and e.prestige == 0 and p.halloween.ores.gumdrop == 5000 and e.spent.gumdrop == mallet.craft,
		"crafting spends the ore from the Halloween inventory and records what it cost")
	local before = p.halloween.ores.gumdrop
	S.dispatch(plr, "cryptPrestige", { uid = e.uid })
	check(e.prestige == 1 and p.halloween.ores.gumdrop == before - Tools.prestigeCost(mallet, 1),
		"prestige 1 is paid in more of that ore", Tools.prestigeCost(mallet, 1))
	for _ = 2, 12 do S.dispatch(plr, "cryptPrestige", { uid = e.uid }) end
	check(e.prestige == 10 and e.spent.gumdrop == Tools.totalSpent(mallet, 10), "it goes to prestige 10 and no further",
		e.spent.gumdrop)
	p.candy = 0
	S.dispatch(plr, "cryptScrap", { uid = e.uid })
	local ask = lastSent("cryptScrapConfirm")
	local want = math.floor(Tools.totalSpent(mallet, 10) * C.candyOreValue("gumdrop") * 0.5)
	check(ask and ask.candy == want and #p.halloween.tools == 2, "scrapping asks first, quoting half the candy value of every ore spent", ask and ask.candy)
	S.dispatch(plr, "cryptScrap", { uid = e.uid, confirm = true })
	check(#p.halloween.tools == 1 and p.candy == want and p.halloween.ores.gumdrop == before - (Tools.totalSpent(mallet, 10) - mallet.craft),
		"confirmed: the tool goes, the candy comes, and no ore comes back")
	S.dispatch(plr, "cryptScrap", { uid = p.halloween.tools[1].uid, confirm = true })
	check(#p.halloween.tools == 1, "the last Halloween tool cannot be scrapped (it is how you dig)")
	-- The cap.
	p.halloween.ores.candy_corn = 100000
	for _ = 1, 12 do S.dispatch(plr, "cryptCraft", { toolId = Tools.STARTER_ID }) end
	check(#p.halloween.tools == Tools.CAP, "at most ten Halloween tools", #p.halloween.tools)
	check(string.find(lastSent("toast") or "", "scrap one", 1, true) ~= nil, "the eleventh craft is refused until you scrap one")
	local plan, why = R.craftPlan(p, Tools.STARTER_ID)
	check(plan == nil and why ~= nil, "craftPlan says why (the Forge shows it)")
end

-- ------------------------------------------------------------ 4. chests --
print("")
print(" 4. Crypt chests: eight ranks")
do
	check(#Chests.RANKS == 8 and Chests.RANKS[1].key == "F" and Chests.RANKS[8].key == "SSS", "eight ranks, F to SSS")
	local names, okPay = {}, true
	for i, r in ipairs(Chests.RANKS) do
		if names[r.name] or r.name == "" then okPay = false end
		names[r.name] = true
		if i > 1 then
			local q = Chests.RANKS[i - 1]
			if r.candy <= q.candy or r.packs < q.packs or r.luck < q.luck or (r.packs == q.packs and r.luck == q.luck) then okPay = false end
		end
		if Chests.rankOfId(Chests.spawnDef(r).id) ~= r then okPay = false end
	end
	check(okPay, "each has its own name, and a rarer rank pays more candy and more or luckier Halloween packs")
	local rarer, deeper, capOk, sums = true, true, true, true
	local prev
	for s = 1, 12 do
		local w = Chests.rankOdds(s)
		local t = 0
		for i, v in ipairs(w) do
			t += v
			if i > 1 and v >= w[i - 1] then rarer = false end
		end
		if not near(t, 1, 1e-9) then sums = false end
		if w[8] > Chests.SSS_CAP + 1e-12 then capOk = false end
		if prev then
			-- C and up only: D, the second-commonest, peaks near the bottom as
			-- the shares move on to the rarer ranks.
			for i = 3, 8 do if w[i] < prev[i] - 1e-12 then deeper = false end end
			if w[1] >= prev[1] then deeper = false end
		end
		prev = w
	end
	check(sums and rarer and capOk, "in every section a rarer rank is rarer, and SSS stays under its cap")
	check(deeper, "deeper sections make every rank from C up more common, and the plain F rarer")
	local n, top, bottom = 40000, 0, 0
	local rng = Random.new(77)
	for _ = 1, n do
		if Chests.rollRank(5, rng).index >= 4 then top += 1 end
		if Chests.rollRank(115, rng).index >= 4 then bottom += 1 end
	end
	check(bottom > 2 * top, "40,000 rolls: B or better is far more common at the bottom", top .. " vs " .. bottom)
	check(near(Chests.charmChance(1), 0.005, 1e-12) and near(Chests.charmChance(3), 0.015, 1e-12), "the charm: 0.5% flat, raised by Chest Luck")
end
do
	-- Open one, with the other agents' two hooks standing in.
	E.rollHalloweenBook = function(rankIndex, rng) return (rankIndex >= 6) and "sugar_rush" or nil end
	local okCharm = Chests.CHARM_CHANCE
	Chests.CHARM_CHANCE = 1
	local p2 = { ores = {}, charms = {}, cards = {}, equipped = {}, candy = 0, backpackTier = 1, hallowOwned = true, packs = {} }
	profiles[8] = p2
	S.normalize(p2)
	local sPart = part("hallow", { CY = 7, ChestType = "crypt_chest_s" })
	S.openChest({ UserId = 8 }, p2, sPart, { chestLuck = 1 })
	local opened = lastSent("chestOpened")
	local s = Chests.rank("S")
	check(opened and opened.kind == "crypt" and opened.rank == "S" and opened.candy == s.candy and p2.candy == s.candy,
		"a chest pays its rank's flat candy (the rank stamped on the block, even at layer 7)")
	check(#p2.packs == s.packs and p2.packs[1].packId == "halloween_2026" and p2.packs[1].luck == s.luck
		and #opened.packs == s.packs and opened.packIds[1] == "halloween_2026", "...its Halloween packs, at its pack luck")
	local hc = Charms.cryptChestCharm("S")
	check(opened.charm and opened.charm.id == hc and p2.charms[hc] == 1 and p2.halloween.charm == hc,
		"...the rank's own Halloween charm (MineCharms.cryptChestCharm), worn in the Halloween slot")
	check(opened.book and opened.book.id == "sugar_rush" and p2.enchantBooks[E.bookKey("sugar_rush", 1)] == 1,
		"...and a Halloween book when MineEnchants.rollHalloweenBook gives one")
	local deep = part("hallow", { CY = 118, ChestType = "crypt_chest_s" })
	local c0 = p2.candy
	S.openChest({ UserId = 8 }, p2, deep, { chestLuck = 1 })
	check(p2.candy - c0 == s.candy, "the same rank pays the same candy at layer 118 (not depth-scaled)")
	Chests.CHARM_CHANCE = okCharm
	E.rollHalloweenBook = nil
	local def = S.chestSpawnDef(100, Random.new(3))
	check(def.crypt and def.rank and Chests.rankOfId(def.id) and C.CHEST_LOOK[def.kind] ~= nil,
		"a spawning chest names its rank and borrows an existing chest look")
	check(opened.coins == 0 and opened.gems == 0, "no coins and no gems")
end

-- ------------------------------------------------------------ 5. Trick-or-Treat --
print("")
print(" 5. Trick-or-Treat: pets and skins only, then 50/50")
do
	check(TT.TREAT_CHANCE == 0.5 and TT.KIND_WEIGHTS.pet and TT.KIND_WEIGHTS.skin and TT.WEIGHTS == nil,
		"two prize kinds (no tools, candy, hats, packs or bucket), and a 50/50")
	local sheet = R.caseOdds()
	local sum, keep, okRows = 0, 0, true
	for _, r in ipairs(sheet.rows) do
		sum += r.pct
		keep += r.keepPct
		if not near(r.petPct + r.skinPct, r.pct, 1e-9) or r.pets < 1 or r.skins < 1 then okRows = false end
	end
	check(near(sum, 100, 1e-9) and near(keep, 50, 1e-9) and okRows and sheet.price == TT.PRICE,
		"the odds sheet sums to 100 (50 kept), and every rarity has a pet and a skin to win")
	local n = 100000
	local treat, kinds, shape = 0, { pet = 0, skin = 0 }, true
	local rng = Random.new(2026)
	for _ = 1, n do
		local roll = TT.roll(rng)
		if roll.outcome == "treat" then treat += 1 end
		kinds[roll.kind] += 1
		local prize = R.casePrize(roll, rng)
		if not prize then shape = false
		elseif prize.kind == "pet" and not (prize.pet and prize.pet.holiday == "halloween") then shape = false
		elseif prize.kind == "skin" and not (prize.skin and prize.skin.set == "halloween") then shape = false end
	end
	check(shape, "every prize is a Halloween pet or a Halloween skin")
	check(near(treat / n, 0.5, 0.006), "100,000 opens: half TREAT, half TRICK", string.format("%.3f", treat / n))
	check(near(kinds.pet / n, TT.KIND_WEIGHTS.pet / (TT.KIND_WEIGHTS.pet + TT.KIND_WEIGHTS.skin), 0.006),
		"...and the pet / skin split lands on its weights")
end
do
	local opens = 30
	p.candy = opens * TT.PRICE
	p.zoneId = "hallow"
	local cards0 = #p.cards
	sent = {}
	for _ = 1, opens do S.buyTrickOrTreat(plr) end
	check(p.candy == 0, "a case costs its price in candy, and there is no candy back", TT.PRICE)
	local treats, tricks, okPush, okGive, petTreats = 0, 0, true, true, 0
	for _, s in ipairs(sent) do
		if s.name == "trickOrTreatOpened" then
			local o = s.payload
			if not (o.rarityIndex and o.rarity and o.reward and o.reward.name and (o.outcome == "treat" or o.outcome == "trick")) then okPush = false end
			if o.outcome == "treat" then
				treats += 1
				if o.kind == "pet" then
					petTreats += 1
					if not (o.reward.cardId and R.cardById(p, o.reward.cardId)) then okGive = false end
				elseif not (o.reward.skinId and p.skins[o.reward.skinId]) then
					okGive = false
				end
			else
				tricks += 1
				if o.reward.cardId or o.reward.dupeDust then okGive = false end
			end
		end
	end
	check(okPush, "one push carries the rarity, the reward and the outcome")
	check(okGive and treats > 0 and tricks > 0 and #p.cards - cards0 == petTreats,
		"a TREAT gives the prize; a TRICK gives nothing", treats .. " treats, " .. tricks .. " tricks")
	afterEvent()
	p.candy = TT.PRICE
	S.buyTrickOrTreat(plr)
	check(p.candy == TT.PRICE, "closed, the case is not sold")
	duringEvent()
end

-- ------------------------------------------------------------ 8. trading --
print("")
print(" 8. trading: Halloween items are locked while the event runs")
do
	local hp = p.cards[1]
	local normal
	for _, c in ipairs(p.cards) do if c.setId == "meadow" then normal = c end end
	check(S.tradeLocked(p, "cards", hp.serial) and S.tradeLocked(p, "cards", hp) and not S.tradeLocked(p, "cards", normal),
		"a Halloween pet is locked (by serial or card); a normal pet is not")
	check(S.tradeLocked(p, "tool", Tools.STARTER_ID) and S.tradeLocked(p, "ore", "taffy") and S.tradeLocked(p, "charm", Charms.cryptChestCharm("F")),
		"Halloween tools, candy ores and Halloween charms are locked")
	check(not S.tradeLocked(p, "ore", "stone") and not S.tradeLocked(p, "packs", { packId = "halloween_2026" }),
		"a normal ore and a pack are not")
end

-- ------------------------------------------------------------ 7b. the event ends --
print("")
print(" 7b. when the event ends, the Halloween inventory moves into the main one")
do
	p.halloween.ores = { taffy = 7, jawbreaker = 1 }
	p.ores = { stone = 3, taffy = 2 }
	local hc = p.halloween.charm
	p.equippedCharm = nil
	afterEvent()
	check(not R.separate(p), "after the window closes the Halloween inventory is no longer its own")
	local moved = S.tick()
	check(moved >= 1 and p.halloween.moved == true, "the tick moves everyone online", moved)
	check(p.ores.taffy == 9 and p.ores.jawbreaker == 1 and next(p.halloween.ores) == nil,
		"candy ores land in the main pouch (and still take no room there)")
	check(#p.halloween.team == 0 and p.halloween.charm == nil and p.equippedCharm == hc,
		"the Halloween team is cleared and the worn Halloween charm takes the empty main slot")
	check(#p.halloween.tools == Tools.CAP, "the tools stay yours")
	local again = S.moveToMain(p)
	local again2 = S.tick()
	check(not again and again2 == 0 and p.ores.taffy == 9, "the move is idempotent (load, tick, again)")
	check(not S.tradeLocked(p, "cards", p.cards[1]) and not S.tradeLocked(p, "ore", "taffy"), "and Halloween items trade again")
	check(not S.mainTeamRefuses(p, p.cards[1].id), "Halloween pets may join the main team")
	-- The tools out here, and prestige, after the event.
	p.zoneId = "meadow"
	S.dispatch(plr, "cryptEquip", { world = true })
	local w = S.heldTool(p)
	local held = R.equippedEntry(p)
	local hdef = Tools.byId(held.id)
	local tier = Tools.worldEquivalent(hdef, held.prestige)
	check(p.cryptToolWorld == true and w and w.world and w.power == Tools.worldPower(hdef, held.prestige, R.eventDigOf(p))
		and w.breakingPower == Breaking.oreStrength(tier, #C.ORES), "a Halloween tool works in the main world, with its ore's breaking power")
	check(Matter.reject(w, part("meadow")) == nil and Matter.reject(w, part("hallow")) == Matter.EVENT_ONLY,
		"the world row spends main-world rock, never the Crypt's")
	p.ores.candy_corn = 100000
	local e = held
	local k0 = e.prestige
	S.dispatch(plr, "cryptPrestige", { uid = e.uid })
	check(e.prestige == k0 + 1, "prestige keeps working after the event (paid from the main pouch now)")
	local nTools = #p.halloween.tools
	S.dispatch(plr, "cryptScrap", { uid = p.halloween.tools[2].uid, confirm = true })
	S.dispatch(plr, "cryptCraft", { toolId = Tools.STARTER_ID })
	check(#p.halloween.tools == nTools - 1, "crafting a new one waits for the next event (CRAFT_AFTER_EVENT false)")
	p.zoneId = "bigbang"
	check(S.heldTool(p) == nil, "Event Horizon keeps its own tools")
	do
		table.insert(C.ZONES, { id = "test_event", name = "Test Event", limited = true, eventToolsOnly = true })
		local erow = R.heldRow(p, "test_event")
		check(erow and erow.eventMine == "test_event", "after the Crypt, its tools work in a later event mine")
		table.remove(C.ZONES)
	end
	-- A save loaded after the event moves on load.
	local q = { hallowOwned = true, ores = {}, halloween = { tools = {}, ores = { gumdrop = 4 }, team = { "x" } } }
	S.normalize(q)
	check(q.ores.gumdrop == 4 and q.halloween.moved and #q.halloween.team == 0, "a save loaded after the event is moved on load")
	duringEvent()
	p.cryptToolWorld = nil
end

-- ------------------------------------------------------------ 9. v1 retired --
print("")
print(" 9. the first design's pieces are retired, and test saves still load")
do
	local hits = 0
	for id in pairs(Charms.RETIRED_CANDY_CHARMS) do
		if Charms.byId(id) then hits += 1 end
	end
	check(hits == 0 and Charms.candyCharms == nil and Charms.recipeFor == nil, "the six crafted charms are gone")
	local q = {
		hallowOwned = true,
		cryptTools = { ["candy_corn_pickaxe|Golden"] = 3 }, cryptToolEquipped = "candy_corn_pickaxe|Golden",
		candySeen = { taffy = true },
		charms = { hallow_kernel = 2, [Charms.GRADED[1].id] = 1 }, equippedCharm = "hallow_kernel",
		ores = { taffy = 6, stone = 2 },
	}
	local ok = pcall(S.normalize, q)
	check(ok, "a v1 test save loads without an error")
	check(q.cryptTools == nil and q.cryptToolEquipped == nil and q.candySeen == nil and q.halloween.seen.taffy,
		"its v1 tool stacks are dropped (and what it had seen is kept)")
	check(q.charms.hallow_kernel == nil and q.equippedCharm == nil and q.charms[Charms.GRADED[1].id] == 1,
		"its crafted candy charms are retired, and come off the slot; other charms stay")
	check(q.ores.taffy == nil and q.halloween.ores.taffy == 6 and q.ores.stone == 2,
		"its candy ores move from the pouch into the Halloween inventory")
	check(#q.halloween.tools == 1 and q.halloween.tools[1].id == Tools.STARTER_ID, "and the claim gets the Candy Corn Pick")
	check(S.VERBS.cryptMerge == nil and S.VERBS.cryptCraftCharm == nil and Tools.rollChestTool == nil and Tools.rollCaseTool == nil,
		"no merge, no charm crafting, no tool from a chest or a case")
end

-- ------------------------------------------------------------ the snapshot --
print("")
print(" the snapshot and the contract")
do
	-- A fresh save, during the event (the one above has already been moved).
	local q = { hallowOwned = true, ores = {}, charms = {}, cards = {}, equipped = {}, candy = 50, petSlots = 3 }
	profiles[9] = q
	S.normalize(q)
	q.halloween.ores.taffy = 1000
	S.dispatch({ UserId = 9 }, "cryptCraft", { toolId = Tools.forOre("taffy").id })
	local st = R.stateFor(q)
	local inv = S.inventoryOf(q)
	check(st and st.zoneId == "hallow" and st.inventory and #st.recipes == 16 and #st.candyOres == 16 and st.casePrice == TT.PRICE
		and st.window and st.window.closesAt and st.candy == 50, "the crypt block carries the inventory, the sixteen recipes, the candy ores and the price")
	local okRows = #inv.tools == 2
	for _, t in ipairs(inv.tools) do
		if not (t.uid and t.name and t.prestige and t.power and t.worldPower and t.worldTier and t.worldLevel
			and t.ladder == nil and #R.prestigeLadder(R.toolDef(t.id), 0) == 11 and t.scrapCandy and t.skinFactor and t.family) then
			okRows = false
		end
	end
	check(okRows and inv.tools[1].id == Tools.forOre("taffy").id and inv.toolCap == 10 and inv.separate == true and inv.teamCap >= 1
		and #inv.ores == 16, "each tool row carries uid, prestige, both powers, the world equivalent, scrap value and factor (its ladder is prestigeLadder's); best first")
	-- Icons (MineCryptIcons, filled by tools/cursor/tasks/crypt-icons.md).
	local Icons = require("MineCryptIcons")
	Icons.TOOLS[Tools.STARTER_ID] = "rbxassetid://123"
	Icons.ORES.taffy = "rbxassetid://456"
	local hidden = R.icon("tool", Tools.STARTER_ID) == "" and R.candyOreRows({}, {}, {})[6].icon == ""
	Icons.SHARED = true
	local starterRow
	for _, t in ipairs(S.inventoryOf(q).tools) do if t.id == Tools.STARTER_ID then starterRow = t end end
	check(hidden and starterRow and starterRow.icon == "rbxassetid://123" and R.candyOreRows({}, {}, {})[6].icon == "rbxassetid://456"
		and R.chestOdds(5, 1).ranks[1].icon == "", "icon ids show only once the owner has shared them (MineCryptIcons.SHARED)")
	Icons.SHARED = false
	check(R.isHalloweenItem("tool", Tools.STARTER_ID) and R.isHalloweenItem("ore", "jawbreaker") and R.isHalloweenItem("pack", "halloween_2026")
		and R.isHalloweenItem("skin", "candy_corn") and not R.isHalloweenItem("tool", "oretool_x") and not R.isHalloweenItem("ore", "stone"),
		"isHalloweenItem answers for tools, ores, packs and skins")
	check(R.NOTICE.text == "Only event tools work here. Tools you find are yours to keep: when the event ends they work in the main world too (weaker).",
		"the pop-up still says exactly the owner's line")
end

C.LIMITED_WINDOWS.hallow = realWindow
print("RESULT " .. fails)
`;

let out = "";
try {
  out = H.run("crypt", H.source(body, { root: argRoot }));
} catch (e) {
  out = (e.stdout || "").toString();
  process.stdout.write(out);
  process.stderr.write((e.stderr || "").toString().split("\n").slice(0, 8).join("\n") + "\n");
  console.log("  FAIL  the luau half did not run to the end");
  fail++;
  out = "";
}
process.stdout.write(out.split("\n").filter((l) => !/^RESULT /.test(l)).join("\n"));
const m = out.match(/^RESULT (\d+)/m);
if (!m) {
  if (out) console.log("  FAIL  the luau half printed no RESULT line");
  fail++;
} else {
  fail += Number(m[1]);
}
console.log(fail === 0 ? ">>> crypt OK" : `>>> crypt: ${fail} FAILED`);
process.exit(fail === 0 ? 0 : 1);
