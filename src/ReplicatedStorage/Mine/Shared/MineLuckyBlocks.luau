-- MineLuckyBlocks: battle-pass lucky blocks (inventory like packs).
-- Stack key: blockId|startGrade|luckPct. Open → rollClash → loot by type×finalGrade.
--
--[[ ART_PROMPTS (for art agent — replace PLACEHOLDER rbxassetids when ready)
A. Inventory / pass icons (square 1:1, readable at 64px, pure black bg, no text):
  - lucky_block: golden cube, Mine For Cards pack-icon language, bold silhouette
  - super_lucky_block: blue cube, same language
  - godly_lucky_block: red crystalline block, same language
B. 3D openable models: handheld/world prop per variant; on open + each CR grade-up
  step play full 360° yaw spin; miss = short shake; final = hold + bloom.
  Wire timing to MineGradeReveal steps.
C. Pass tools: lunar_pick (pale moon metal pick), bp_eclipse (dark sunburst explosive/
  pick), lunar_eclipse (fused moon-in-eclipse silhouette).
]]

local MineLuckyBlocks = {}

local Grades = require(script.Parent:WaitForChild("MineToolGrades"))

MineLuckyBlocks.TYPES = {
	lucky_block = {
		id = "lucky_block",
		name = "Lucky Block",
		blurb = "Golden cube. One nice drop — meadow packs, not a lottery.",
		color = Color3.fromRGB(255, 196, 64),
		icon = "rbxassetid://86826521518359",
		model = "rbxassetid://0", -- PLACEHOLDER 3D
	},
	super_lucky_block = {
		id = "super_lucky_block",
		name = "Diamond Lucky Block",
		blurb = "Blue cube. Fatter packs and real tools. Never a pouch.",
		color = Color3.fromRGB(64, 148, 255),
		icon = "rbxassetid://130589291505484",
		model = "rbxassetid://0",
	},
	godly_lucky_block = {
		id = "godly_lucky_block",
		name = "Godly Lucky Block",
		blurb = "Red crystal. Multi-pack lottery, T18–21, Omni, dust kicker on every open.",
		color = Color3.fromRGB(220, 48, 64),
		icon = "rbxassetid://75196830544563",
		model = "rbxassetid://0",
	},
}

MineLuckyBlocks.START_GRADES = { "F", "D", "C", "B", "A" }

local ZONE_LOW = { "meadow", "sunscar", "mistreef" }
local ZONE_MID = { "arcwork", "bloodmoon", "eclipse" }
local ZONE_HIGH = { "riftmarch", "starfall", "mythral" }
local ZONE_TOP = { "primordium", "bigbang" }

local function pick(list, rng)
	return list[rng:NextInteger(1, #list)]
end

local function packId(zone, slot)
	return zone .. "_" .. slot
end

local function bandOf(grade)
	local g = grade or "F"
	if g == "F" or g == "D" then
		return "low"
	end
	if g == "C" or g == "B" then
		return "mid"
	end
	if g == "A" or g == "S" then
		return "high"
	end
	return "top"
end

local function rangeAmount(rng, lo, hi)
	return rng:NextInteger(lo, hi)
end

local function weighted(rng, rows)
	local total = 0
	for _, row in ipairs(rows) do
		total += row[1]
	end
	local roll = rng:NextNumber() * total
	local acc = 0
	for _, row in ipairs(rows) do
		acc += row[1]
		if roll <= acc then
			return row[2]
		end
	end
	return rows[#rows][2]
end

MineLuckyBlocks.PIT_WEIGHTS = {
	{ 80, "lucky_block" },
	{ 15, "super_lucky_block" },
	{ 5, "godly_lucky_block" },
}

function MineLuckyBlocks.rollPitId(rng)
	rng = rng or Random.new()
	return weighted(rng, MineLuckyBlocks.PIT_WEIGHTS)
end

--[[
	Blocks found in the pit sometimes come already graded. A flat roll for each
	find; nothing carries over from one find to the next.
]]
MineLuckyBlocks.PRESET_WEIGHTS = {
	{ 70, "F" },
	{ 18, "D" },
	{ 8, "C" },
	{ 3, "B" },
	{ 1, "A" },
}

function MineLuckyBlocks.rollPresetGrade(rng)
	return weighted(rng or Random.new(), MineLuckyBlocks.PRESET_WEIGHTS)
end

function MineLuckyBlocks.def(id)
	return MineLuckyBlocks.TYPES[id]
end

--[[
	Shop SKUs (credits). Impulse ladder — lucky blocks are the dopamine aisle,
	not a second whale gate next to packs.
]]
MineLuckyBlocks.SHOP = {
	{ id = "lucky_block", credits = 45, blurb = "Golden cube · meadow packs & gems" },
	{ id = "super_lucky_block", credits = 120, blurb = "Diamond cube · fatter packs & tools" },
	{ id = "godly_lucky_block", credits = 280, label = "Godly Lucky Block",
		blurb = "Red crystal · multi-pack lottery" },
}
MineLuckyBlocks.BUNDLE_10 = {
	id = "lucky_block", qty = 10, credits = 350, label = "10× Lucky Blocks",
	blurb = "Limited aisle staple · save 100 credits vs singles",
}

--[[
	How good a block is, out of five, on the same scale the packs print
	(MinePackConfig.packStars). The type sets the band -- what its loot table
	can pay at all -- and the grade it starts on moves it, because a B start is
	three rungs of head start on the climb.
]]
MineLuckyBlocks.TYPE_STARS = {
	lucky_block = 2.5,
	super_lucky_block = 3.5,
	godly_lucky_block = 4.5,
}

function MineLuckyBlocks.blockStars(blockId, startGrade)
	local base = MineLuckyBlocks.TYPE_STARS[tostring(blockId or "")] or 2.5
	local stars = base + (Grades.rankOf(startGrade or "F") - 1) * 0.25
	return math.clamp(math.floor(stars * 2 + 0.5) / 2, 0.5, 5)
end

function MineLuckyBlocks.shopPrice(id)
	for _, row in ipairs(MineLuckyBlocks.SHOP) do
		if row.id == id then
			return row.credits
		end
	end
	return nil
end

function MineLuckyBlocks.isLuckyBlock(entry)
	return type(entry) == "table" and entry.kind == "lucky_block"
end

function MineLuckyBlocks.stackKey(entry)
	local luckMult = tonumber(entry and entry.luck) or 1
	local luckPct = (luckMult > 1) and math.floor((luckMult - 1) * 100 + 0.5) or 0
	local start = tostring(entry.startGrade or "F")
	local key = tostring(entry.blockId or entry.packId) .. "|" .. start .. "|" .. tostring(luckPct)
	-- Levels already bought change what the next one costs, so they split the stack.
	local bought = math.floor(tonumber(entry.bought) or 0)
	if bought > 0 then
		key ..= "|b" .. bought
	end
	return key
end

function MineLuckyBlocks.makeEntry(blockId, startGrade, luck)
	local def = MineLuckyBlocks.TYPES[blockId]
	assert(def, "unknown lucky block " .. tostring(blockId))
	return {
		kind = "lucky_block",
		blockId = blockId,
		packId = blockId,
		packName = def.name,
		startGrade = startGrade or "F",
		luck = luck or 1,
		setId = "lucky_block",
	}
end

function MineLuckyBlocks.grant(p, blockId, startGrade, qty, luck)
	p.packs = p.packs or {}
	qty = math.max(1, math.floor(tonumber(qty) or 1))
	for _ = 1, qty do
		table.insert(p.packs, MineLuckyBlocks.makeEntry(blockId, startGrade, luck))
	end
end

--[[
	Paying gems to raise a block's grade before it is opened (MineServer
	Verbs.luckyGradeUp). The first level bought on a block costs
	GRADE_UP_BASE whatever grade it starts at -- B to A costs the same as F
	to D -- and each further level on the same block costs GRADE_UP_GROWTH
	times the one before it: 25K, 125K, 625K, ...
]]
--[[
	The climb a lucky block rolls (MineToolGrades.rollClash takes this as its
	ladder). The first two steps are near coin flips so almost every block moves
	at least once and the tap-through is worth watching; it tightens after that.

	Chances by the rank you are on: F 1/2, D 1/2, C 1/3, B 1/4, A/S/SS 2/7.
	Three misses still stop it, and the odds were solved to leave SSS where the
	flat 1-in-3 ladder had it (about 0.85%). What changes is the middle:

	        flat 1/3            this ladder
	  F     29.6%                12.5%
	  D     29.6%                18.8%
	  C     19.8%                31.0%
	  B     11.0%                23.0%
	  A      5.5%                 8.8%
	  S      2.5%                 3.7%
	  SS     1.1%                 1.4%
	  SSS    0.85%                0.85%
]]
MineLuckyBlocks.UPGRADE_P = { 1 / 2, 1 / 2, 1 / 3, 1 / 4, 2 / 7, 2 / 7, 2 / 7 }

MineLuckyBlocks.GRADE_UP_BASE = 25000
MineLuckyBlocks.GRADE_UP_GROWTH = 5

function MineLuckyBlocks.nextGrade(grade)
	return Grades.ORDER[Grades.rankOf(grade or "F") + 1]
end

function MineLuckyBlocks.gradeUpPrice(entry)
	local bought = math.max(0, math.floor(tonumber(entry and entry.bought) or 0))
	return MineLuckyBlocks.GRADE_UP_BASE * MineLuckyBlocks.GRADE_UP_GROWTH ^ bought
end

local function softToolId(rng, loTier, hiTier)
	local byTier = {
		[1] = "wood_pick", [2] = "stone_pick", [3] = "flint_pick",
		[4] = "copper_pick", [5] = "bronze_pick", [6] = "iron_pick",
		[7] = "hardened_pick", [8] = "steel_pick",
		[12] = "quartz_pick", [13] = "amethyst_pick", [14] = "emerald_pick",
		[15] = "sapphire_pick", [16] = "ruby_pick", [17] = "diamond_pick",
		[18] = "prismatic_pick", [19] = "meteorite_pick", [20] = "voidsteel_pick",
		[21] = "starforged_pick",
	}
	local tiers = {}
	for t = loTier, hiTier do
		if byTier[t] then table.insert(tiers, t) end
	end
	if #tiers == 0 then return "iron_pick" end
	return byTier[tiers[rng:NextInteger(1, #tiers)]]
end

--[[
	THE LOOT TABLES, AS DATA.

	These were written inline in rollLoot. They are data now so the odds sheet
	(oddsSheet, shown before you buy) reads the SAME rows the server rolls.
	Lucky blocks are sold for credits, which are bought with Robux, and Roblox
	requires paid random items to show their odds. A copy of these numbers in a
	UI file would drift the day someone rebalances. One table cannot.

	Rows are { weight, kind }. Keys are a grade band -- low (F, D), mid (C, B),
	high (A, S), top (SS, SSS) -- or an exact grade where that grade has its own
	row. An exact grade wins over its band (kindTable). The numbers are
	unchanged from the inline version: tools/verify/lucky-odds.js holds them.
]]
MineLuckyBlocks.KIND_TABLES = {
	lucky_block = {
		low = { { 70, "pack" }, { 20, "gems" }, { 10, "dust" } },
		mid = { { 62, "pack" }, { 23, "gems" }, { 15, "dust" } },
		high = { { 52, "pack" }, { 24, "gems" }, { 19, "dust" }, { 5, "tool" } },
		top = { { 48, "pack" }, { 22, "gems" }, { 20, "dust" }, { 10, "tool" }, { 2, "pet" } },
	},
	super_lucky_block = {
		low = { { 48, "pack" }, { 18, "gems" }, { 18, "dust" }, { 16, "tool" } },
		mid = { { 42, "pack" }, { 16, "gems" }, { 16, "dust" }, { 22, "tool" }, { 4, "scroll_white" } },
		high = { { 36, "pack" }, { 14, "gems" }, { 16, "dust" }, { 26, "tool" }, { 8, "scroll_white" }, { 2, "pet" } },
		SSS = { { 30, "pack" }, { 12, "gems" }, { 14, "dust" }, { 28, "tool" }, { 8, "scroll_black" }, { 8, "scroll_white" }, { 4, "pet" } },
		top = { { 32, "pack" }, { 14, "gems" }, { 16, "dust" }, { 28, "tool" }, { 10, "scroll_white" } },
	},
	godly_lucky_block = {
		low = { { 40, "pack" }, { 12, "gems" }, { 14, "dust" }, { 30, "tool" }, { 4, "scroll_omni" } },
		mid = { { 36, "pack" }, { 10, "gems" }, { 12, "dust" }, { 36, "tool" }, { 6, "scroll_omni" } },
		high = { { 32, "pack" }, { 8, "gems" }, { 12, "dust" }, { 36, "tool" }, { 12, "scroll_omni" }, { 3, "pet" } },
		SS = { { 26, "pack" }, { 8, "gems" }, { 16, "dust" }, { 40, "tool" }, { 10, "scroll_omni" }, { 5, "pet" } },
		top = { { 22, "pack" }, { 8, "gems" }, { 18, "chase" }, { 40, "tool" }, { 12, "scroll_omni" }, { 8, "pet" } },
	},
}

-- Which kind rows a block rolls at a final grade. An unknown block id rolls the
-- godly rows, as the inline version did (its `else` branch).
function MineLuckyBlocks.kindTable(blockId, finalGrade)
	local t = MineLuckyBlocks.KIND_TABLES[blockId] or MineLuckyBlocks.KIND_TABLES.godly_lucky_block
	return t[finalGrade or "F"] or t[bandOf(finalGrade)]
end

-- The pet tier, once a block has rolled "pet". Legendary is the floor.
MineLuckyBlocks.PET_TABLES = {
	SSS = { { 600, "Legendary" }, { 300, "Mythic" }, { 80, "Divine" }, { 20, "Exotic" } },
	SS = { { 720, "Legendary" }, { 230, "Mythic" }, { 45, "Divine" }, { 5, "Exotic" } },
	S = { { 840, "Legendary" }, { 150, "Mythic" }, { 10, "Divine" } },
	-- A and below: a Legendary is already the exception here.
	default = { { 920, "Legendary" }, { 80, "Mythic" } },
}

function MineLuckyBlocks.petTable(finalGrade)
	return MineLuckyBlocks.PET_TABLES[finalGrade or ""] or MineLuckyBlocks.PET_TABLES.default
end

--[[
	EXACT final-grade odds for a block starting at `startGrade`.

	The same process MineToolGrades.rollClash runs on the server with
	UPGRADE_P: each step climbs one rank with that rank's chance, a miss counts,
	MISS_LIMIT misses or the top rank ends it. That is a small tree, so it is
	walked exactly rather than simulated. Returns { [grade] = probability }.
]]
function MineLuckyBlocks.gradeOdds(startGrade)
	local order = Grades.ORDER
	local maxRank = #order
	local missLimit = Grades.MISS_LIMIT or 3
	local out = {}
	for _, g in ipairs(order) do
		out[g] = 0
	end
	local function walk(rank, misses, prob)
		if rank >= maxRank or misses >= missLimit then
			out[order[rank]] += prob
			return
		end
		local p = Grades.upgradeChance(rank, MineLuckyBlocks.UPGRADE_P)
		walk(rank + 1, misses, prob * p)
		walk(rank, misses + 1, prob * (1 - p))
	end
	walk(math.clamp(Grades.rankOf(startGrade or "F"), 1, maxRank), 0, 1)
	return out
end

--[[
	Everything a player should see before buying: the final-grade odds, the
	chance of each kind of reward, and the pet tier odds. All three come from
	the tables rollLoot uses. "chase" is paid out as stardust (rollLoot rewrites
	it), so it is counted as stardust here.
]]
function MineLuckyBlocks.oddsSheet(blockId, startGrade)
	local grades = MineLuckyBlocks.gradeOdds(startGrade)
	local kinds, pets = {}, {}
	for grade, pg in pairs(grades) do
		if pg > 0 then
			local rows = MineLuckyBlocks.kindTable(blockId, grade)
			local total = 0
			for _, r in ipairs(rows) do
				total += r[1]
			end
			for _, r in ipairs(rows) do
				local kind = (r[2] == "chase") and "dust" or r[2]
				local share = pg * r[1] / total
				kinds[kind] = (kinds[kind] or 0) + share
				if kind == "pet" then
					local pt = MineLuckyBlocks.petTable(grade)
					local ptot = 0
					for _, x in ipairs(pt) do
						ptot += x[1]
					end
					for _, x in ipairs(pt) do
						pets[x[2]] = (pets[x[2]] or 0) + share * x[1] / ptot
					end
				end
			end
		end
	end
	return {
		grades = grades,
		kinds = kinds,
		pets = pets,
		-- Godly blocks add a stardust kicker on EVERY open, on top of the roll.
		bonusDust = blockId == "godly_lucky_block",
	}
end

MineLuckyBlocks.KIND_NAMES = {
	pack = "Card packs",
	gems = "Gems",
	dust = "Stardust",
	tool = "A pickaxe",
	pet = "A pet (Legendary or better)",
	scroll_white = "White scroll",
	scroll_black = "Black scroll",
	scroll_omni = "Omni scroll",
}

function MineLuckyBlocks.rollLoot(blockId, finalGrade, rng)
	rng = rng or Random.new()
	local def = MineLuckyBlocks.TYPES[blockId] or MineLuckyBlocks.TYPES.lucky_block
	local band = bandOf(finalGrade)
	local kind = weighted(rng, MineLuckyBlocks.kindTable(blockId, finalGrade))

	local out = { blockId = blockId, blockName = def.name, finalGrade = finalGrade, kind = kind }

	if kind == "pack" then
		local zones, slot, qty
		if blockId == "lucky_block" then
			if band == "low" then
				zones, slot = ZONE_LOW, (rng:NextNumber() < 0.9) and "pack_common" or "currency_common"
				qty = 1
			elseif band == "mid" then
				zones, slot = ZONE_MID, (rng:NextNumber() < 0.55) and "pack_common" or "pack_rare"
				qty = 1
			elseif band == "high" then
				zones, slot = ZONE_HIGH, (rng:NextNumber() < 0.55) and "pack_rare" or "pack_common"
				qty = 2
			elseif finalGrade == "SSS" then
				zones, slot = ZONE_HIGH, (rng:NextNumber() < 0.7) and "pack_legendary" or "pack_rare"
				qty = 3
			else
				zones, slot = ZONE_HIGH, (rng:NextNumber() < 0.55) and "pack_rare" or "pack_legendary"
				qty = 2
			end
		elseif blockId == "super_lucky_block" then
			if band == "low" then
				zones, slot = ZONE_MID, (rng:NextNumber() < 0.65) and "pack_rare" or "pack_common"
				qty = 2
			elseif band == "mid" then
				zones, slot = ZONE_HIGH, (rng:NextNumber() < 0.55) and "pack_rare" or "pack_legendary"
				qty = 2
			elseif band == "high" then
				zones, slot = ZONE_TOP, (rng:NextNumber() < 0.55) and "pack_legendary" or "pack_rare"
				qty = 3
			else
				zones, slot, qty = ZONE_TOP, "pack_legendary", 3
			end
		else
			if band == "low" then
				zones, slot = ZONE_HIGH, (rng:NextNumber() < 0.55) and "pack_legendary" or "pack_rare"
				qty = 2
			elseif band == "mid" then
				zones, slot = ZONE_HIGH, (rng:NextNumber() < 0.7) and "pack_legendary" or "pack_rare"
				qty = 3
			elseif band == "high" then
				zones, slot, qty = ZONE_TOP, "pack_legendary", 4
			else
				zones, slot, qty = ZONE_TOP, "pack_legendary", 5
			end
		end
		out.packId = packId(pick(zones, rng), slot)
		out.packQty = qty
	elseif kind == "gems" then
		local lo, hi
		if blockId == "lucky_block" then
			if band == "low" then lo, hi = 120, 320
			elseif band == "mid" then lo, hi = 320, 800
			elseif band == "high" then lo, hi = 700, 1600
			elseif finalGrade == "SSS" then lo, hi = 1800, 3800
			else lo, hi = 1200, 2600 end
		elseif blockId == "super_lucky_block" then
			if band == "low" then lo, hi = 800, 1920
			elseif band == "mid" then lo, hi = 1760, 4160
			elseif band == "high" then lo, hi = 3600, 8000
			elseif finalGrade == "SSS" then lo, hi = 9600, 18000
			else lo, hi = 7200, 14400 end
		else
			if band == "low" then lo, hi = 4200, 9600
			elseif band == "mid" then lo, hi = 5600, 12800
			elseif band == "high" then lo, hi = 12800, 28800
			else lo, hi = 25600, 56000 end
		end
		out.gems = rangeAmount(rng, lo, hi)
	elseif kind == "dust" then
		local lo, hi
		if blockId == "lucky_block" then
			if band == "low" then lo, hi = 60, 140
			elseif band == "mid" then lo, hi = 180, 400
			elseif band == "high" then lo, hi = 400, 900
			elseif finalGrade == "SSS" then lo, hi = 1100, 2400
			else lo, hi = 700, 1600 end
		elseif blockId == "super_lucky_block" then
			if band == "low" then lo, hi = 480, 1040
			elseif band == "mid" then lo, hi = 960, 2080
			elseif band == "high" then lo, hi = 1920, 4160
			elseif finalGrade == "SSS" then lo, hi = 4500, 9500
			else lo, hi = 3200, 6800 end
		else
			if band == "low" then lo, hi = 2100, 4800
			elseif band == "mid" then lo, hi = 2800, 6400
			elseif band == "high" then lo, hi = 7200, 16000
			else lo, hi = 9600, 22400 end
		end
		out.dust = rangeAmount(rng, lo, hi)
	elseif kind == "tool" then
		local lo, hi
		if blockId == "lucky_block" then
			if finalGrade == "SSS" then lo, hi = 6, 8
			elseif band == "top" then lo, hi = 4, 8
			else lo, hi = 1, 4 end
		elseif blockId == "super_lucky_block" then
			if band == "low" then lo, hi = 8, 12
			elseif band == "mid" then lo, hi = 12, 16
			elseif band == "high" then lo, hi = 14, 18
			else lo, hi = 16, 19 end
		else
			if band == "low" then lo, hi = 18, 19
			elseif band == "mid" then lo, hi = 18, 20
			else lo, hi = 19, 21 end
		end
		out.toolId = softToolId(rng, lo, hi)
		out.toolFamily = "pickaxe"
	elseif kind == "pet" then
		--[[
			A PET, AND ONLY A GOOD ONE.

			Lucky blocks paid packs, gems, dust, tools and scrolls -- never a pet,
			which is the thing the game is actually about. Added at the top bands
			only and at small weight, so it stays an event rather than a drip.

			Legendary is the FLOOR. A Common pet out of a Godly block would read
			as a miss, and the roster carries 118 pets at Legendary or better, so
			there is plenty of room up here.
		]]
		--[[
			TIER FOLLOWS THE GRADE.

			A flat table meant an F block and an SSS block paid the same pet, which
			makes grading up pointless on the one drop people care about most.

			Divine and Exotic are deliberately tiny everywhere -- Exotic does not
			exist at all below SS. Legendary is the bread and butter; Mythic is the
			good day. The ceiling opens up as the grade climbs.
		]]
		out.petTier = weighted(rng, MineLuckyBlocks.petTable(finalGrade))
	elseif kind == "scroll_white" then
		out.scrolls = { white = 1 }
	elseif kind == "scroll_black" then
		out.scrolls = { black = 1 }
	elseif kind == "scroll_omni" then
		out.scrolls = { omni = 1 }
	elseif kind == "chase" then
		out.kind = "dust"
		out.dust = rangeAmount(rng, 14400, 32000)
	end

	if blockId == "godly_lucky_block" then
		local lo, hi
		if band == "low" then
			lo, hi = 360, 960
		elseif band == "mid" then
			lo, hi = 480, 1280
		elseif band == "high" then
			lo, hi = 1440, 3200
		elseif finalGrade == "SS" then
			lo, hi = 2800, 6400
		else
			lo, hi = 4800, 11200
		end
		out.dust = (out.dust or 0) + rangeAmount(rng, lo, hi)
	end

	return out
end

function MineLuckyBlocks.describeLoot(loot)
	if type(loot) ~= "table" then
		return "--"
	end
	local parts = {}
	if loot.packId then
		local q = math.max(1, math.floor(tonumber(loot.packQty) or 1))
		local name = tostring(loot.packId):gsub("_", " ")
		parts[#parts + 1] = (q > 1 and (q .. "× ") or "") .. "Pack: " .. name
	end
	if loot.gems then
		parts[#parts + 1] = loot.gems .. " Gems"
	end
	if loot.dust then
		parts[#parts + 1] = loot.dust .. " Stardust"
	end
	if loot.toolId then
		parts[#parts + 1] = "Tool: " .. tostring(loot.toolId):gsub("_", " ")
	end
	if type(loot.scrolls) == "table" then
		local s = {}
		for id, qty in pairs(loot.scrolls) do
			s[#s + 1] = id .. " x" .. qty
		end
		table.sort(s)
		if #s > 0 then
			parts[#parts + 1] = table.concat(s, ", ")
		end
	end
	if loot.petTier then
		parts[#parts + 1] = tostring(loot.petTier) .. " Pet"
	end
	if loot.temperTokens then
		parts[#parts + 1] = loot.temperTokens .. " Temper Tokens"
	end
	if #parts == 0 then
		return loot.kind or "--"
	end
	return table.concat(parts, " + ")
end

return MineLuckyBlocks
