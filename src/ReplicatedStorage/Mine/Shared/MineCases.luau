--[[
	MineCases -- PACK CASES. A case holds PACKS, never cards: open one and its
	packs land in your bag, to be opened like any other pack.

	Owner, 2026-10-10: "Should have 2 types of cases.. Cases for a set
	(determines what exact packs and how many [3 min]{stardust})), and cases
	that is a complete wild draw (such as chest cases, random packs, random set)".

	  WILD CASES  "case_<1..6>", one per star grade (MineSetPacks.STARS):
	              3-5 random packs of that grade from ANY set, top-graded sets
	              rarer (MineSetPacks.CASE_SIZE, GRADE_WEIGHT). Chests drop
	              them, the daily wheel pays them, the credit shop sells them,
	              and so does the stardust shop.
	  SET CASES   "<setKey>_case_<starter|collector|vault>", three per set,
	              exact contents, sold for stardust:
	                Starter    ★ + ★½ + ★★
	                Collector  ★★ + ★★★ + ★★★ + ★★★★
	                Vault      ★★★★ + ★★★★ + ★★★★★

	EVERY NUMBER HERE IS PROPOSED until the owner approves it: the case
	contents, the stars a set case shows, the chest luck cap, the featured set
	packs and every price (wiki: systems/pack-cases, "the pricing pass").

	Ids are data: a case sits in a save as a bag row in p.packs.

	MinePackConfig registers every case in PACK_BY_ID (kind "pack_case"), so the
	bag tile, the stars, the sort and the shops read a case like a pack.
	Opening one never reaches openPack: MineServer hands any case to
	MineCases.open first, the way it hands lucky blocks to openLuckyBlock.

	Nothing here requires MinePackConfig at load: MinePackConfig requires this
	module, and a require loop never returns. The prices read it lazily.
]]
local M = {}

local SetPets = require(script.Parent:WaitForChild("MineSetPets"))
local SetPacks = require(script.Parent:WaitForChild("MineSetPacks"))
local Art = require(script.Parent:WaitForChild("MinePackArt"))

M.KIND = "pack_case"

--[[
	The 19 sets in the owner's order: { key, name, grade, index }. From the set
	pets when they are loaded, else from the pack-art list, which carries the
	same names and grades (tools/pack-sprites/sets.js).
]]
M.SETS = {}
M.SET_BY_KEY = {}
do
	if #(SetPets.SETS or {}) > 0 then
		for i, s in ipairs(SetPets.SETS) do
			table.insert(M.SETS, { key = s.KEY, name = s.NAME, grade = s.GRADE, index = s.INDEX or i })
		end
	else
		for i, key in ipairs(Art.ORDER or {}) do
			local a = Art.SETS[key]
			table.insert(M.SETS, { key = key, name = a.name, grade = a.grade, index = a.index or i })
		end
	end
	for _, s in ipairs(M.SETS) do
		M.SET_BY_KEY[s.key] = s
	end
end

-- PROPOSED. The three set cases, by the star grade (1..6) of each pack inside.
M.SET_CASES = {
	{ key = "starter", name = "Starter Case", levels = { 1, 2, 3 } },
	{ key = "collector", name = "Collector Case", levels = { 3, 4, 4, 5 } },
	{ key = "vault", name = "Vault", levels = { 5, 5, 6 } },
}

--[[
	PROPOSED. A chest's chance of a case is MineSetPacks.CHEST_CASE_CHANCE by
	the chest's rank, times the chest luck, but never more than this many
	times the base chance.
]]
M.CHEST_LUCK_CAP = 3

-- PROPOSED. Wild cases from this star grade up announce themselves when a
-- chest drops one (a popup, not just a line on the chest card).
M.CHEST_POPUP_LEVEL = 5

function M.wildId(level)
	return "case_" .. level
end

function M.setCaseId(setKey, kind)
	return setKey .. "_case_" .. kind
end

M.CASES = {}
M.BY_ID = {}

local function add(def)
	def.kind = M.KIND
	table.insert(M.CASES, def)
	M.BY_ID[def.id] = def
end

for n = 1, #SetPacks.STARS do
	add({
		id = M.wildId(n),
		name = SetPacks.STAR_TEXT[n] .. " Wild Case",
		caseType = "wild",
		starLevel = n,
		stars = SetPacks.STARS[n],
		cards = 0,
		blurb = "3-5 random " .. SetPacks.STAR_TEXT[n] .. " packs from any set",
	})
end

for _, set in ipairs(M.SETS) do
	for _, kind in ipairs(M.SET_CASES) do
		local packs, top = {}, 1
		for _, level in ipairs(kind.levels) do
			table.insert(packs, SetPacks.packId(set.key, level))
			top = math.max(top, level)
		end
		add({
			id = M.setCaseId(set.key, kind.key),
			name = set.name .. " " .. kind.name,
			caseType = "set",
			caseKind = kind.key,
			setKey = set.key,
			setName = set.name,
			grade = set.grade,
			-- PROPOSED: a set case shows the stars of the best pack in it.
			starLevel = top,
			stars = SetPacks.STARS[top],
			packs = packs,
			cards = #packs,
			blurb = #packs .. " " .. set.name .. " packs",
		})
	end
end

function M.get(id)
	return M.BY_ID[tostring(id or "")]
end

function M.isCase(id)
	return M.get(id) ~= nil
end

-- The star grade (1..6) of a set pack id, and its set key.
function M.parsePack(packId)
	local key, level = string.match(tostring(packId or ""), "^(.-)_pack_(%d)$")
	level = tonumber(level)
	if not (key and M.SET_BY_KEY[key] and level and SetPacks.STARS[level]) then
		return nil
	end
	return key, level
end

function M.packName(packId)
	local def = SetPacks.PACK_BY_ID and SetPacks.PACK_BY_ID[packId]
	if def and def.name then
		return def.name
	end
	local key, level = M.parsePack(packId)
	if not key then
		return tostring(packId)
	end
	return M.SET_BY_KEY[key].name .. " " .. SetPacks.STAR_TEXT[level]
end

-- The rarity colour a case or a set pack borrows on reveals and popups.
function M.rarityOf(id)
	local def = M.get(id)
	local level = (def and def.starLevel) or select(2, M.parsePack(id)) or 1
	return SetPacks.STAR_TIER[level] or "Common"
end

-- "3 packs", "3-5 packs": what a case tile says it holds.
function M.countText(id)
	local def = M.get(id)
	if not def then
		return ""
	end
	if def.caseType == "set" then
		return #def.packs .. " packs"
	end
	local lo, hi = math.huge, 0
	for _, r in ipairs(SetPacks.CASE_SIZE) do
		lo, hi = math.min(lo, r.n), math.max(hi, r.n)
	end
	return lo .. "-" .. hi .. " packs"
end

-- ------------------------------------------------------------- rolling --

local function weighted(rows, rng, weightOf)
	local total = 0
	for _, row in ipairs(rows) do
		total += math.max(0, weightOf(row))
	end
	if total <= 0 then
		return rows[1]
	end
	local roll = (rng and rng:NextNumber() or math.random()) * total
	for _, row in ipairs(rows) do
		roll -= math.max(0, weightOf(row))
		if roll <= 0 then
			return row
		end
	end
	return rows[#rows]
end

-- The set filling one wild slot: any set, top grades rarer.
function M.rollWildSet(rng)
	local set = weighted(M.SETS, rng, function(s)
		return SetPacks.GRADE_WEIGHT[s.grade] or 1
	end)
	return set and set.key
end

-- What a case holds, as set pack ids. A set case always holds the same.
function M.contents(id, rng)
	local def = M.get(id)
	if not def then
		return {}
	end
	if def.caseType == "set" then
		return table.clone(def.packs)
	end
	local size = weighted(SetPacks.CASE_SIZE, rng, function(r)
		return r.weight
	end).n
	local out = {}
	for _ = 1, size do
		local key = M.rollWildSet(rng)
		if key then
			table.insert(out, SetPacks.packId(key, def.starLevel))
		end
	end
	return out
end

-- -------------------------------------------------------------- the bag --

-- A case as a bag row. `setId` is the case's set, or "wild": never a random
-- old card set, which the bag tile would print as the case's set.
function M.bagRow(id)
	local def = M.get(id)
	if not def then
		return nil
	end
	return {
		packId = def.id,
		packName = def.name,
		kind = M.KIND,
		setId = def.setKey or "wild",
	}
end

-- A set pack as a bag row, the shape Verbs.grantPacks writes.
function M.packRow(packId)
	local key = M.parsePack(packId)
	return {
		packId = packId,
		packName = M.packName(packId),
		setId = key,
	}
end

--[[
	OPEN ONE CASE. The caller has already taken `pk` out of the bag. Its packs
	go into p.packs, and this returns what the reveal shows: one loot row per
	pack (MineClient paints kind "pack" with the pack's own art) and the
	design the reveal tears open.

	A case that came out of a lucky chest carries that chest's pack luck
	(MineServer openChestBlock), and so does every pack inside it.
]]
function M.open(p, pk, rng)
	local def = M.get(pk and pk.packId)
	if not def then
		return nil
	end
	rng = rng or Random.new()
	p.packs = p.packs or {}
	local luck = tonumber(pk.luck)
	local loot = {}
	for _, packId in ipairs(M.contents(def.id, rng)) do
		local row = M.packRow(packId)
		if luck and luck > 1 then
			row.luck = luck
		end
		table.insert(p.packs, row)
		local key, level = M.parsePack(packId)
		local set = key and M.SET_BY_KEY[key]
		table.insert(loot, {
			kind = "pack",
			packId = packId,
			name = row.packName,
			rarityId = SetPacks.STAR_TIER[level or 1] or "Common",
			setName = set and set.name or nil,
			stars = level and SetPacks.STARS[level] or nil,
			-- The reveal card's small print: the set and its grade.
			sub = set and (set.name .. "  ·  grade " .. tostring(set.grade)) or nil,
		})
	end
	p.packsOpened = p.packsOpened or {}
	p.packsOpened[def.id] = (tonumber(p.packsOpened[def.id]) or 0) + 1
	local design = {
		packId = def.id,
		name = def.name,
		setName = def.setName or "Any set",
		kind = M.KIND,
	}
	return loot, design
end

--[[
	A chest's case, if it drops one: a bag row, or nil. `rank` is the chest's
	(MineZoneChests: F..S, or "native" for the meadow and Event Horizon).
]]
function M.rollChestCase(rank, rng, chestLuck)
	rng = rng or Random.new()
	local key = SetPacks.CHEST_CASE_CHANCE[rank or ""] and rank or "C"
	local luck = math.clamp(tonumber(chestLuck) or 1, 1, M.CHEST_LUCK_CAP)
	if rng:NextNumber() >= SetPacks.CHEST_CASE_CHANCE[key] * luck then
		return nil
	end
	local rows = {}
	for n, w in ipairs(SetPacks.CHEST_CASE_STARS[key]) do
		table.insert(rows, { n = n, w = w })
	end
	local level = weighted(rows, rng, function(r)
		return r.w
	end).n
	return M.bagRow(M.wildId(level))
end

-- -------------------------------------------------------------- prices --

--[[
	PROPOSED. A set's pets are 5% stronger for every set before it (owner,
	MineSetPets.setMult), so a pack from set N is valued 1.05^(N-1) of the same
	pack from Pebblebound. Without this a Chaos Theory Vault would cost what a
	Pebblebound Vault does, and nobody would buy the Pebblebound one.
]]
M.SET_VALUE_STEP = 1.05

function M.setValue(setKey)
	local set = M.SET_BY_KEY[setKey]
	return M.SET_VALUE_STEP ^ (((set and set.index) or 1) - 1)
end

-- The average value of a wild slot, over the grade-weighted set draw.
function M.wildValue()
	local sum, total = 0, 0
	for _, s in ipairs(M.SETS) do
		local w = SetPacks.GRADE_WEIGHT[s.grade] or 1
		sum += w * M.setValue(s.key)
		total += w
	end
	return (total > 0) and (sum / total) or 1
end

local function dustOfTier()
	local Packs = require(script.Parent:WaitForChild("MinePackConfig"))
	return Packs.RECYCLE_STARDUST or {}
end

local function avgCaseSize()
	local sum, total = 0, 0
	for _, r in ipairs(SetPacks.CASE_SIZE) do
		sum += r.n * r.weight
		total += r.weight
	end
	return (total > 0) and (sum / total) or 3
end

--[[
	What a case, or a set pack, is expected to scrap for in stardust: each
	pack's expected card value (MineSetPacks.expectedPackDust over
	MinePackConfig.RECYCLE_STARDUST), times its set's value.
]]
function M.expectedDust(id)
	local dust = dustOfTier()
	local def = M.get(id)
	if def and def.caseType == "set" then
		local ev = 0
		for _, packId in ipairs(def.packs) do
			local _, level = M.parsePack(packId)
			ev += SetPacks.expectedPackDust(level, dust)
		end
		return ev * M.setValue(def.setKey)
	elseif def then
		return SetPacks.expectedPackDust(def.starLevel, dust) * avgCaseSize() * M.wildValue()
	end
	local key, level = M.parsePack(id)
	if key then
		return SetPacks.expectedPackDust(level, dust) * M.setValue(key)
	end
	return 0
end

-- PROPOSED. Stardust price = expected value / MineSetPacks.CASE_RTP (0.65),
-- to the nearest 5.
function M.dustPrice(id)
	if not M.get(id) then
		return nil
	end
	local ev = M.expectedDust(id) / (SetPacks.CASE_RTP or 0.65)
	return math.max(25, math.floor(ev / 5 + 0.5) * 5)
end

--[[
	PROPOSED. Credit price from the same curve the credit shop's packs sit on
	today: credits = 12 x (expected stardust / 250) ^ 0.45. Fitted 2026-10-10
	to the old shelf: Hopper 12 credits at ~250 expected stardust, Heirloom 55
	at ~6,900, Shiny 95 at ~24,000. Value rises faster than price, as it did
	there: a better pack is a better deal.
]]
M.CREDIT_CURVE = { base = 12, at = 250, power = 0.45 }

local function creditsFor(ev)
	local c = M.CREDIT_CURVE
	return math.max(5, math.floor(c.base * (math.max(0, ev) / c.at) ^ c.power + 0.5))
end

-- --------------------------------------------------------------- shops --

-- PROPOSED. The set packs the credit shop features each UTC day: four sets,
-- one pack each, at these star grades.
M.FEATURED_LEVELS = { 4, 5, 5, 6 }

function M.dayIndex(now)
	return math.floor((tonumber(now) or os.time()) / 86400)
end

-- Today's featured set packs. The same on every server and every client.
function M.featuredSetPacks(day)
	day = tonumber(day) or M.dayIndex()
	local rng = Random.new(day * 7919 + 17)
	local keys = {}
	for _, s in ipairs(M.SETS) do
		table.insert(keys, s.key)
	end
	local out = {}
	for _, level in ipairs(M.FEATURED_LEVELS) do
		if #keys == 0 then
			break
		end
		local key = table.remove(keys, rng:NextInteger(1, #keys))
		local id = SetPacks.packId(key, level)
		-- Only a pack the game can open: set packs exist once the set pets do.
		if SetPacks.PACK_BY_ID and SetPacks.PACK_BY_ID[id] then
			table.insert(out, id)
		end
	end
	return out
end

-- What the credit shop sells: the wild cases, then today's featured set packs.
function M.creditShelf(day)
	local out = {}
	for n = 1, #SetPacks.STARS do
		table.insert(out, M.wildId(n))
	end
	for _, id in ipairs(M.featuredSetPacks(day)) do
		table.insert(out, id)
	end
	return out
end

-- The credit price of anything on today's credit shelf, else nil. The server
-- prices a cart line with this, so an item off the shelf cannot be bought.
function M.creditPrice(id, day)
	id = tostring(id or "")
	local listed = false
	for _, row in ipairs(M.creditShelf(day)) do
		if row == id then
			listed = true
			break
		end
	end
	if not listed then
		return nil
	end
	return creditsFor(M.expectedDust(id))
end

-- What the stardust shop's cases tab sells: the wild cases, then each set's
-- three cases in the owner's order.
function M.dustShelf()
	local out = {}
	for _, def in ipairs(M.CASES) do
		table.insert(out, def.id)
	end
	return out
end

return M
