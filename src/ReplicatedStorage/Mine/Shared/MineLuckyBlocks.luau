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
		blurb = "Golden cube. A mystery case, a skin case, or gems and stardust.",
		color = Color3.fromRGB(255, 196, 64),
		icon = "rbxassetid://86826521518359",
		model = "rbxassetid://0", -- PLACEHOLDER 3D
	},
	super_lucky_block = {
		id = "super_lucky_block",
		name = "Diamond Lucky Block",
		blurb = "Blue cube. 2-star mystery cases and up, and deeper skin cases.",
		color = Color3.fromRGB(64, 148, 255),
		icon = "rbxassetid://130589291505484",
		model = "rbxassetid://0",
	},
	godly_lucky_block = {
		id = "godly_lucky_block",
		name = "Godly Lucky Block",
		blurb = "Red crystal. 3-star mystery cases and up, the deepest skin cases, and stardust on every open.",
		color = Color3.fromRGB(220, 48, 64),
		icon = "rbxassetid://75196830544563",
		model = "rbxassetid://0",
	},
}

MineLuckyBlocks.START_GRADES = { "F", "D", "C", "B", "A" }

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
	{ id = "lucky_block", credits = 45, blurb = "Golden cube · mystery & skin cases" },
	{ id = "super_lucky_block", credits = 120, blurb = "Diamond cube · 2★+ mystery cases" },
	{ id = "godly_lucky_block", credits = 280, label = "Godly Lucky Block",
		blurb = "Red crystal · 3★+ mystery cases" },
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
	GRADE-UPS ARE OFF. Owner, 2026-10-10: "Remove grade-ups" -- paying gems to
	raise a block's grade before opening it (MineServer Verbs.luckyGradeUp).
	gradeUpPrice answers nil while GRADE_UP_ON is false, which hides the button
	(MineGradeReveal shows it only when there is a price) and makes the server
	refuse. Blocks that already bought levels keep them; the levels still split
	the stack (stackKey).

	When it was on, the first level on a block cost GRADE_UP_BASE and each
	further level GRADE_UP_GROWTH times the one before: 25K, 125K, 625K, ...
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

MineLuckyBlocks.GRADE_UP_ON = false
MineLuckyBlocks.GRADE_UP_BASE = 25000
MineLuckyBlocks.GRADE_UP_GROWTH = 5

function MineLuckyBlocks.nextGrade(grade)
	return Grades.ORDER[Grades.rankOf(grade or "F") + 1]
end

function MineLuckyBlocks.gradeUpPrice(entry)
	if not MineLuckyBlocks.GRADE_UP_ON then
		return nil
	end
	local bought = math.max(0, math.floor(tonumber(entry and entry.bought) or 0))
	return MineLuckyBlocks.GRADE_UP_BASE * MineLuckyBlocks.GRADE_UP_GROWTH ^ bought
end

--[[
	THE LOOT TABLES, AS DATA.

	Owner, 2026-10-10: lucky blocks were "hella boring, and not worth shit".
	Redone to the owner's answers:
	  * gems and stardust stay, as FIXED amounts ("not scaled.. good way to
	    break economy"), and stay small: they are the filler;
	  * the prizes are cases: "it should give cases/packs to give you pets,
	    skins and charms" -- a MYSTERY CASE (MineCases wild case: one spin, 3
	    of a set pack, which is where pets come from) or a SKIN CASE (an ore
	    case: a skin, or that ore's charm);
	  * a better block, and a better final grade, pays a better case. No % luck.
	The old pickaxes (tools are forged now), scrolls, direct pet rolls and zone
	packs are gone. Every number below is PROPOSED.

	They are data so the odds sheet (oddsSheet, shown before you buy) reads the
	SAME rows the server rolls: lucky blocks are sold for credits, and a paid
	random item must show its odds. tools/verify/lucky-odds.js checks the two
	agree.

	Rows are { weight, kind }. Keys are a grade band -- low (F, D), mid (C, B),
	high (A, S), top (SS, SSS) -- or an exact grade where it has its own row.
]]
MineLuckyBlocks.KIND_TABLES = {
	lucky_block = {
		low = { { 40, "mystery" }, { 10, "skincase" }, { 25, "gems" }, { 25, "dust" } },
		mid = { { 45, "mystery" }, { 15, "skincase" }, { 20, "gems" }, { 20, "dust" } },
		high = { { 50, "mystery" }, { 20, "skincase" }, { 15, "gems" }, { 15, "dust" } },
		top = { { 55, "mystery" }, { 25, "skincase" }, { 10, "gems" }, { 10, "dust" } },
	},
	super_lucky_block = {
		low = { { 50, "mystery" }, { 15, "skincase" }, { 18, "gems" }, { 17, "dust" } },
		mid = { { 52, "mystery" }, { 20, "skincase" }, { 14, "gems" }, { 14, "dust" } },
		high = { { 55, "mystery" }, { 25, "skincase" }, { 10, "gems" }, { 10, "dust" } },
		top = { { 58, "mystery" }, { 28, "skincase" }, { 7, "gems" }, { 7, "dust" } },
	},
	godly_lucky_block = {
		low = { { 55, "mystery" }, { 20, "skincase" }, { 13, "gems" }, { 12, "dust" } },
		mid = { { 57, "mystery" }, { 25, "skincase" }, { 9, "gems" }, { 9, "dust" } },
		high = { { 60, "mystery" }, { 28, "skincase" }, { 6, "gems" }, { 6, "dust" } },
		top = { { 60, "mystery" }, { 32, "skincase" }, { 4, "gems" }, { 4, "dust" } },
	},
}

-- Which kind rows a block rolls at a final grade. An unknown block id rolls the
-- godly rows.
function MineLuckyBlocks.kindTable(blockId, finalGrade)
	local t = MineLuckyBlocks.KIND_TABLES[blockId] or MineLuckyBlocks.KIND_TABLES.godly_lucky_block
	return t[finalGrade or "F"] or t[bandOf(finalGrade)]
end

--[[
	PROPOSED. The mystery case a block pays, by its final grade: a MineCases
	wild case id (case_1 is 1 star ... case_6 is 5 stars, case_3_4 is 2.5).
	A Godly SSS pays two.
]]
MineLuckyBlocks.MYSTERY_CASE = {
	lucky_block = { F = "case_1", D = "case_1", C = "case_2", B = "case_3", A = "case_3_4", S = "case_4", SS = "case_4_5", SSS = "case_5" },
	super_lucky_block = { F = "case_3", D = "case_3", C = "case_3_4", B = "case_4", A = "case_4_5", S = "case_5", SS = "case_5_6", SSS = "case_6" },
	godly_lucky_block = { F = "case_4", D = "case_4", C = "case_4_5", B = "case_5", A = "case_5", S = "case_5_6", SS = "case_6", SSS = "case_6" },
}
MineLuckyBlocks.MYSTERY_QTY = { godly_lucky_block = { SSS = 2 } }

--[[
	PROPOSED. The skin case a block pays: an ore case (`<ore>_ore_case`, a skin
	or that ore's charm) for an ore in this tier range, picked by the server
	(MineConfig.ORES). Deeper ore, better charm. { lo, hi } by band.
]]
MineLuckyBlocks.SKIN_CASE_TIERS = {
	lucky_block = { low = { 1, 10 }, mid = { 8, 20 }, high = { 15, 30 }, top = { 25, 40 } },
	super_lucky_block = { low = { 15, 30 }, mid = { 25, 40 }, high = { 35, 55 }, top = { 45, 65 } },
	godly_lucky_block = { low = { 35, 55 }, mid = { 45, 65 }, high = { 55, 75 }, top = { 65, 82 } },
}

--[[
	Fixed gem and stardust amounts, { lo, hi } by band (SSS has its own row
	where it pays more). Not scaled to the player: the owner's call.
]]
MineLuckyBlocks.GEMS = {
	lucky_block = { low = { 120, 320 }, mid = { 320, 800 }, high = { 700, 1600 }, top = { 1200, 2600 }, SSS = { 1800, 3800 } },
	super_lucky_block = { low = { 800, 1920 }, mid = { 1760, 4160 }, high = { 3600, 8000 }, top = { 7200, 14400 }, SSS = { 9600, 18000 } },
	godly_lucky_block = { low = { 4200, 9600 }, mid = { 5600, 12800 }, high = { 12800, 28800 }, top = { 25600, 56000 } },
}
MineLuckyBlocks.DUST = {
	lucky_block = { low = { 60, 140 }, mid = { 180, 400 }, high = { 400, 900 }, top = { 700, 1600 }, SSS = { 1100, 2400 } },
	super_lucky_block = { low = { 480, 1040 }, mid = { 960, 2080 }, high = { 1920, 4160 }, top = { 3200, 6800 }, SSS = { 4500, 9500 } },
	godly_lucky_block = { low = { 2100, 4800 }, mid = { 2800, 6400 }, high = { 7200, 16000 }, top = { 9600, 22400 } },
}

local function amountRange(tbl, blockId, finalGrade)
	local t = tbl[blockId] or tbl.lucky_block
	return t[finalGrade or "F"] or t[bandOf(finalGrade)]
end

-- No pet tiers any more: pets come out of the mystery cases' packs. Kept as an
-- empty table so the odds sheet's pet section has nothing to draw.
MineLuckyBlocks.PET_TABLES = { default = {} }

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
	Everything a player should see before buying: the final-grade odds and the
	chance of each kind of reward. Both come from the tables rollLoot uses.
]]
function MineLuckyBlocks.oddsSheet(blockId, startGrade)
	local grades = MineLuckyBlocks.gradeOdds(startGrade)
	local kinds = {}
	for grade, pg in pairs(grades) do
		if pg > 0 then
			local rows = MineLuckyBlocks.kindTable(blockId, grade)
			local total = 0
			for _, r in ipairs(rows) do
				total += r[1]
			end
			for _, r in ipairs(rows) do
				kinds[r[2]] = (kinds[r[2]] or 0) + pg * r[1] / total
			end
		end
	end
	return {
		grades = grades,
		kinds = kinds,
		pets = {},
		-- Godly blocks add a stardust kicker on EVERY open, on top of the roll.
		bonusDust = blockId == "godly_lucky_block",
	}
end

MineLuckyBlocks.KIND_NAMES = {
	mystery = "A mystery case (spin for 3 packs)",
	skincase = "A skin case (a skin, or a charm)",
	gems = "Gems",
	dust = "Stardust",
}

function MineLuckyBlocks.rollLoot(blockId, finalGrade, rng)
	rng = rng or Random.new()
	local def = MineLuckyBlocks.TYPES[blockId] or MineLuckyBlocks.TYPES.lucky_block
	local band = bandOf(finalGrade)
	local kind = weighted(rng, MineLuckyBlocks.kindTable(blockId, finalGrade))
	local key = MineLuckyBlocks.KIND_TABLES[blockId] and blockId or "godly_lucky_block"

	local out = { blockId = blockId, blockName = def.name, finalGrade = finalGrade, kind = kind }

	if kind == "mystery" then
		local cases = MineLuckyBlocks.MYSTERY_CASE[key]
		out.caseId = cases[finalGrade or "F"] or cases.F
		local qty = MineLuckyBlocks.MYSTERY_QTY[key]
		out.caseQty = (qty and qty[finalGrade or ""]) or 1
	elseif kind == "skincase" then
		out.skinCaseTiers = MineLuckyBlocks.SKIN_CASE_TIERS[key][band]
	elseif kind == "gems" then
		local r = amountRange(MineLuckyBlocks.GEMS, key, finalGrade)
		out.gems = rangeAmount(rng, r[1], r[2])
	elseif kind == "dust" then
		local r = amountRange(MineLuckyBlocks.DUST, key, finalGrade)
		out.dust = rangeAmount(rng, r[1], r[2])
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
	if loot.caseId then
		local q = math.max(1, math.floor(tonumber(loot.caseQty) or 1))
		parts[#parts + 1] = (q > 1 and (q .. "× ") or "") .. tostring(loot.caseName or loot.caseId)
	end
	if loot.oreCaseName then
		parts[#parts + 1] = tostring(loot.oreCaseName)
	end
	if loot.gems then
		parts[#parts + 1] = loot.gems .. " Gems"
	end
	if loot.dust then
		parts[#parts + 1] = loot.dust .. " Stardust"
	end
	if #parts == 0 then
		return loot.kind or "--"
	end
	return table.concat(parts, " + ")
end

return MineLuckyBlocks
