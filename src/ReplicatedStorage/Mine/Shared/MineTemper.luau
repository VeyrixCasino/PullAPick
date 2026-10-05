-- MineTemper: forever-tool Temperaments. One wallet with rebirth skill tokens.
--
-- A forever tool does not level. It rolls a kit from this catalog. Grade
-- picks the bucket, then a kit is drawn uniformly inside that bucket.
-- Magnitude is grade multiplier * slot base, then MineStats caps still win.
local MineTemper = {}

local Stats = require(script.Parent:WaitForChild("MineStats"))

MineTemper.LEGACY_RARITY = {
	Common = "F",
	Uncommon = "D",
	Rare = "C",
	Epic = "B",
	Legendary = "A",
	Mythic = "S",
	Divine = "SS",
	Exotic = "SSS",
}

MineTemper.GRADE_ORDER = { "F", "D", "C", "B", "A", "S", "SS", "SSS" }
MineTemper.RARITY_ORDER = MineTemper.GRADE_ORDER

function MineTemper.normalizeRarity(rarity)
	if rarity == nil then
		return nil
	end
	return MineTemper.LEGACY_RARITY[rarity] or rarity
end

MineTemper.RARITY_WEIGHTS = {
	F = 5000, D = 2763, C = 1250, B = 675,
	A = 250, S = 50, SS = 10, SSS = 2,
}

MineTemper.RARITY_MULT = {
	F = 0.45, D = 0.70, C = 1.05, B = 1.55,
	A = 2.30, S = 3.40, SS = 5.00, SSS = 7.50,
}
-- Echo/Zap/Blast/Auto-Mine/OreYield are chances: keep them a proc, not a lock-on.
MineTemper.PROC_RARITY_MULT = {
	F = 0.30, D = 0.40, C = 0.52, B = 0.65,
	A = 0.80, S = 0.95, SS = 1.12, SSS = 1.30,
}

MineTemper.RARITY_COLOR = {
	F = Color3.fromRGB(170, 176, 188),
	D = Color3.fromRGB(151, 106, 72),
	C = Color3.fromRGB(112, 226, 148),
	B = Color3.fromRGB(96, 164, 255),
	A = Color3.fromRGB(196, 120, 255),
	S = Color3.fromRGB(255, 206, 92),
	SS = Color3.fromRGB(255, 132, 214),
	SSS = Color3.fromRGB(96, 248, 255),
}

-- SSS bases after x5, then multiplied by grade. echo/zap/autoMine/blastRadius/
-- blastChance (Blast %) use the abs primary-style numbers from the lock, scaled by slot share.
MineTemper.BASE = { primary = 1.00, secondary = 0.60, tertiary = 0.35 }
MineTemper.ABS_PRIMARY = { echo = 0.35, zap = 0.25, autoMine = 0.50, blastRadius = 0.50, blastChance = 0.50 }

MineTemper.POOL_COUNTS = {
	F = 7, D = 9, C = 9, B = 24,
	A = 18, S = 14, SS = 12, SSS = 7,
}

MineTemper.STARTER_RARITIES = { F = true, D = true, C = true }

local SLOT_SHARE = { MineTemper.BASE.primary, MineTemper.BASE.secondary, MineTemper.BASE.tertiary, MineTemper.BASE.tertiary }

local function kit(id, name, rarity, stats, penalty)
	rarity = MineTemper.normalizeRarity(rarity)
	local iconStat = type(stats) == "table" and stats[1] or nil
	local icon
	pcall(function()
		local Icons = require(script.Parent:WaitForChild("MineIcons"))
		icon = iconStat and Icons.image and Icons.image(iconStat) or nil
	end)
	return { id = id, name = name, rarity = rarity, stats = stats, penalty = penalty, icon = icon }
end

MineTemper.KITS = {
	-- F (7) - singles
	kit("damage", "Damage", "F", { "mineSpeed" }),
	kit("swing", "Swing Rate", "F", { "swingRate" }),
	kit("break_speed", "Break Speed", "F", { "dirtBreak" }),
	kit("coins", "Coins", "F", { "coinBonus" }),
	kit("gems", "Gems", "F", { "gemFind" }),
	kit("ore", "Blast", "F", { "blastChance" }),
	kit("luck", "Luck", "F", { "luck" }),

	-- D (9) - duals
	kit("dig_pace", "Dig Pace", "D", { "mineSpeed", "swingRate" }),
	kit("clear_lane", "Clear Lane", "D", { "dirtBreak", "swingRate" }),
	kit("paydirt", "Paydirt", "D", { "blastChance", "coinBonus" }),
	kit("facet", "Facet", "D", { "gemFind", "rareOre" }),
	kit("fortune", "Fortune", "D", { "luck", "chestLuck" }),
	kit("hauler", "Hauler", "D", { "backpack", "walkSpeed" }),
	kit("striker", "Striker", "D", { "mineSpeed", "echo" }),
	kit("powder", "Powder", "D", { "blastRadius", "swingRate" }),
	kit("broker", "Broker", "D", { "coinBonus", "backpack" }),

	-- C (9)
	kit("brutal", "Brutal", "C", { "mineSpeed", "swingRate", "dirtBreak" }),
	kit("excavator", "Excavator", "C", { "dirtBreak", "swingRate", "mineSpeed" }),
	kit("lode", "Lode", "C", { "blastChance", "rareOre", "gemFind" }),
	kit("vault", "Vault", "C", { "coinBonus", "backpack", "blastChance" }),
	kit("hex", "Hex", "C", { "luck", "chestLuck", "rareOre" }),
	kit("crater", "Crater", "C", { "blastRadius", "mineSpeed" }),
	kit("specter", "Specter", "C", { "autoMine", "echo" }),
	kit("glass", "Glass", "C", { "mineSpeed", "swingRate" }, "backpack"),
	kit("strip", "Strip", "C", { "dirtBreak", "blastRadius", "swingRate" }),

	-- B (24)
	kit("contractor", "Contractor", "B", { "mineSpeed", "swingRate", "coinBonus" }),
	kit("strip_pay", "Strip Pay", "B", { "dirtBreak", "swingRate", "coinBonus" }),
	kit("gem_arm", "Gem Arm", "B", { "mineSpeed", "gemFind", "rareOre" }),
	kit("clearcut", "Clearcut", "B", { "dirtBreak", "mineSpeed", "swingRate" }),
	kit("treasury", "Treasury", "B", { "coinBonus", "backpack", "gemFind" }),
	kit("prospect", "Prospect", "B", { "gemFind", "rareOre", "dirtBreak" }),
	kit("siege", "Siege", "B", { "blastRadius", "dirtBreak", "mineSpeed" }),
	kit("phantom", "Phantom", "B", { "autoMine", "echo", "swingRate" }),
	kit("oracle", "Oracle", "B", { "luck", "chestLuck", "rareOre" }),
	kit("caravan", "Caravan", "B", { "backpack", "walkSpeed", "coinBonus" }),
	kit("nova", "Nova", "B", { "blastRadius", "swingRate", "mineSpeed" }),
	kit("aurora", "Aurora", "B", { "gemFind", "echo", "luck" }),
	kit("tycoon", "Tycoon", "B", { "coinBonus", "backpack", "blastChance" }),
	kit("motherlode", "Motherlode", "B", { "blastChance", "rareOre", "gemFind" }),
	kit("razorfuse", "Razorfuse", "B", { "swingRate", "echo", "mineSpeed" }),
	kit("blackcat", "Black Cat", "B", { "chestLuck", "luck", "gemFind" }),
	kit("drone_crew", "Drone Crew", "B", { "autoMine", "swingRate", "dirtBreak" }),
	kit("pay_swing", "Pay Swing", "B", { "coinBonus", "swingRate", "mineSpeed" }),
	kit("gem_strip", "Gem Strip", "B", { "gemFind", "dirtBreak", "swingRate" }),
	kit("omen_dig", "Omen Dig", "B", { "luck", "mineSpeed", "rareOre" }),
	kit("blast_purse", "Blast Purse", "B", { "blastRadius", "coinBonus", "swingRate" }),
	kit("echo_ore", "Echo Ore", "B", { "echo", "blastChance", "mineSpeed" }),
	kit("haul_gem", "Haul Gem", "B", { "backpack", "gemFind", "walkSpeed" }),
	kit("deep_assay", "Deep Assay", "B", { "rareOre", "blastChance", "mineSpeed" }),

	-- A (18)
	kit("executioner", "Executioner", "A", { "mineSpeed", "swingRate", "dirtBreak" }),
	kit("minted", "Minted", "A", { "coinBonus", "backpack", "mineSpeed" }),
	kit("crown_facet", "Crown Facet", "A", { "gemFind", "rareOre", "mineSpeed" }),
	kit("eraser", "Eraser", "A", { "dirtBreak", "swingRate", "blastRadius" }),
	kit("war_chest", "War Chest", "A", { "coinBonus", "chestLuck", "backpack" }),
	kit("double_dip", "Double Dip", "A", { "coinBonus", "gemFind", "swingRate" }),
	kit("tectonic", "Tectonic", "A", { "mineSpeed", "blastRadius", "dirtBreak" }),
	kit("relicmap", "Relic Map", "A", { "chestLuck", "luck", "rareOre" }),
	kit("singularity", "Singularity", "A", { "echo", "autoMine", "mineSpeed" }),
	kit("horizon", "Horizon", "A", { "blastRadius", "swingRate", "walkSpeed" }),
	kit("leviathan", "Leviathan", "A", { "backpack", "blastChance", "coinBonus" }),
	kit("wildcard", "Wildcard", "A", { "luck", "gemFind", "swingRate" }),
	kit("blood_contract", "Blood Contract", "A", { "mineSpeed", "coinBonus", "echo" }),
	kit("crystal_siege", "Crystal Siege", "A", { "blastRadius", "gemFind", "rareOre" }),
	kit("freight_king", "Freight King", "A", { "backpack", "walkSpeed", "dirtBreak", "coinBonus" }),
	kit("pace_empire", "Pace Empire", "A", { "swingRate", "coinBonus", "gemFind" }),
	kit("vein_blitz", "Vein Blitz", "A", { "blastChance", "swingRate", "mineSpeed" }),
	kit("omen_echo", "Omen Echo", "A", { "luck", "echo", "chestLuck" }),

	-- S (14)
	kit("worldnail", "Worldnail", "S", { "mineSpeed", "swingRate", "dirtBreak", "echo" }),
	kit("empire", "Empire", "S", { "coinBonus", "backpack", "mineSpeed", "luck" }),
	kit("astral_cut", "Astral Cut", "S", { "gemFind", "rareOre", "blastChance", "mineSpeed" }),
	kit("redline", "Redline", "S", { "dirtBreak", "swingRate", "mineSpeed", "coinBonus" }),
	kit("mantle", "Mantle", "S", { "mineSpeed", "dirtBreak", "blastRadius" }),
	kit("omenlord", "Omenlord", "S", { "chestLuck", "luck", "echo" }),
	kit("cataclysm", "Cataclysm", "S", { "blastRadius", "mineSpeed", "dirtBreak" }),
	kit("echoqueen", "Echo Queen", "S", { "echo", "autoMine", "swingRate" }),
	kit("gilded", "Gilded", "S", { "coinBonus", "chestLuck", "luck" }),
	kit("crownore", "Crown Ore", "S", { "blastChance", "rareOre", "gemFind" }),
	kit("war_contractor", "War Contractor", "S", { "mineSpeed", "coinBonus", "swingRate", "dirtBreak" }),
	kit("gilded_bore", "Gilded Bore", "S", { "dirtBreak", "coinBonus", "gemFind", "backpack" }),
	kit("blood_facet", "Blood Facet", "S", { "mineSpeed", "gemFind", "swingRate", "rareOre" }),
	kit("strip_tycoon", "Strip Tycoon", "S", { "dirtBreak", "coinBonus", "backpack", "blastChance" }),

	-- SS (12)
	kit("godnail", "Godnail", "SS", { "mineSpeed", "swingRate", "dirtBreak", "gemFind" }),
	kit("godmarket", "Godmarket", "SS", { "coinBonus", "backpack", "mineSpeed", "gemFind" }),
	kit("godfacet", "Godfacet", "SS", { "gemFind", "rareOre", "mineSpeed", "dirtBreak" }),
	kit("godstrip", "Godstrip", "SS", { "dirtBreak", "swingRate", "coinBonus", "blastRadius" }),
	kit("fateforge", "Fateforge", "SS", { "chestLuck", "luck", "coinBonus", "gemFind" }),
	kit("eternalecho", "Eternal Echo", "SS", { "echo", "autoMine", "swingRate", "mineSpeed" }),
	kit("astralvein", "Astral Vein", "SS", { "blastChance", "rareOre", "gemFind", "luck" }),
	kit("worldsplit_t", "Worldsplit Temper", "SS", { "mineSpeed", "swingRate", "dirtBreak", "blastRadius" }),
	kit("throne_dig", "Throne Dig", "SS", { "mineSpeed", "coinBonus", "swingRate", "dirtBreak" }),
	kit("throne_shine", "Throne Shine", "SS", { "mineSpeed", "gemFind", "dirtBreak", "swingRate" }),
	kit("throne_purse", "Throne Purse", "SS", { "coinBonus", "gemFind", "backpack", "mineSpeed" }),
	kit("throne_pace", "Throne Pace", "SS", { "swingRate", "coinBonus", "gemFind", "dirtBreak" }),

	-- SSS (7)
	kit("absolute_dig", "Absolute Dig", "SSS", { "mineSpeed", "swingRate", "dirtBreak", "blastRadius" }),
	kit("absolute_fortune", "Absolute Fortune", "SSS", { "luck", "chestLuck", "rareOre", "gemFind" }),
	kit("absolute_yield", "Absolute Yield", "SSS", { "blastChance", "rareOre", "coinBonus", "backpack" }),
	kit("absolute_pulse", "Absolute Pulse", "SSS", { "echo", "autoMine", "swingRate", "walkSpeed" }),
	kit("absolute_payroll", "Absolute Payroll", "SSS", { "mineSpeed", "coinBonus", "swingRate", "dirtBreak" }),
	kit("absolute_treasury", "Absolute Treasury", "SSS", { "gemFind", "coinBonus", "mineSpeed", "rareOre" }),
	kit("absolute_siege", "Absolute Siege", "SSS", { "blastRadius", "dirtBreak", "mineSpeed", "swingRate" }),
}

local byId, byRarity = {}, {}
for _, rarity in ipairs(MineTemper.RARITY_ORDER) do
	byRarity[rarity] = {}
end
for _, row in ipairs(MineTemper.KITS) do
	row.rarity = MineTemper.normalizeRarity(row.rarity)
	byId[row.id] = row
	table.insert(byRarity[row.rarity], row)
end
MineTemper.BY_ID = byId
MineTemper.BY_RARITY = byRarity

function MineTemper.kit(id)
	return byId[id]
end

-- Tokens per roll: flat, from MineSkillData.TEMPER_ROLL_COST. The rolls-so-far
-- argument is ignored on purpose -- the old min(8, 1 + floor(rolls / 2)) curve
-- is not the economy. Required here rather than at the top so neither module
-- depends on the other's load order.
function MineTemper.rollCost(_temperRolls)
	local ok, Skills = pcall(require, script.Parent:WaitForChild("MineSkillData"))
	return (ok and Skills and Skills.TEMPER_ROLL_COST) or 10
end

local function rollRarity(rng, starter)
	local total = 0
	for _, rarity in ipairs(MineTemper.RARITY_ORDER) do
		if not starter or MineTemper.STARTER_RARITIES[rarity] then
			total += MineTemper.RARITY_WEIGHTS[rarity]
		end
	end
	local n = rng:NextNumber() * total
	local acc = 0
	for _, rarity in ipairs(MineTemper.RARITY_ORDER) do
		if not starter or MineTemper.STARTER_RARITIES[rarity] then
			acc += MineTemper.RARITY_WEIGHTS[rarity]
			if n <= acc then
				return rarity
			end
		end
	end
	return starter and "C" or "SSS"
end

function MineTemper.rollTemperament(rng, opts)
	rng = rng or Random.new()
	opts = opts or {}
	local rarity = MineTemper.normalizeRarity(rollRarity(rng, opts.starter and true or false))
	local bucket = byRarity[rarity]
	local pick = bucket and bucket[rng:NextInteger(1, #bucket)] or nil
	return pick, rarity
end

local function slotAmount(stat, slotIndex, rarity)
	rarity = MineTemper.normalizeRarity(rarity) or "F"
	local share = SLOT_SHARE[slotIndex] or MineTemper.BASE.tertiary
	local abs = MineTemper.ABS_PRIMARY[stat]
	local mult = abs
		and (MineTemper.PROC_RARITY_MULT[rarity] or MineTemper.PROC_RARITY_MULT.F)
		or (MineTemper.RARITY_MULT[rarity] or MineTemper.RARITY_MULT.F)
	if abs then
		return abs * (share / MineTemper.BASE.primary) * mult
	end
	return share * mult
end

-- { [stat] = fraction }  0.30 = +30%. Penalty stats are negative.
function MineTemper.magnitudes(kitOrId, rarity)
	local kit = type(kitOrId) == "table" and kitOrId or byId[kitOrId]
	if not kit then
		return {}
	end
	rarity = MineTemper.normalizeRarity(rarity or kit.rarity)
	local out = {}
	for i, stat in ipairs(kit.stats or {}) do
		if stat then
			out[stat] = (out[stat] or 0) + slotAmount(stat, i, rarity)
		end
	end
	if kit.penalty then
		local amount = slotAmount(kit.penalty, 3, rarity)
		out[kit.penalty] = (out[kit.penalty] or 0) - amount
	end
	--[[
		AUTO MINE IS GONE. Every source of it pays out as Gem Find instead
		(MineStats.AUTO_MINE_TO_GEM, folded for real in MineServer.boosts), so
		fold it HERE as well or the card advertises a stat the game no longer
		has: four kits were printing "Auto Mine +40%" for a gem-find payout, and
		the stat's own description still promised the pet mines on its own.
	]]
	local auto = out.autoMine
	if auto and auto ~= 0 then
		out.autoMine = nil
		local ratio = (Stats and Stats.AUTO_MINE_TO_GEM) or (2.5 / 1.8)
		out.gemFind = (out.gemFind or 0) + auto * ratio
	end
	return out
end

function MineTemper.describe(kitOrId, rarity)
	local kit = type(kitOrId) == "table" and kitOrId or byId[kitOrId]
	if not kit then
		return {}
	end
	rarity = MineTemper.normalizeRarity(rarity or kit.rarity)
	local mag = MineTemper.magnitudes(kit, rarity)
	local lines = {}
	for _, stat in ipairs(Stats.STAT_ORDER) do
		local amount = mag[stat]
		if amount and amount ~= 0 then
			local def = Stats.STATS[stat]
			table.insert(lines, {
				stat = stat,
				label = def and def.label or stat,
				text = string.format("%s%.1f%%", amount > 0 and "+" or "", amount * 100),
				positive = amount > 0,
			})
		end
	end
	return lines
end

-- Apply onto a live boosts table. Caps are the caller's job (Runes.clampBoosts).
function MineTemper.applyTemper(boosts, foreverTool)
	if not (boosts and foreverTool) then
		return boosts
	end
	local function applyOne(temperId, temperRarity)
		if not temperId then return end
		local kit = byId[temperId]
		if not kit then return end
		local rarity = MineTemper.normalizeRarity(temperRarity or kit.rarity)
		local mag = MineTemper.magnitudes(kit, rarity)
		for stat, amount in pairs(mag) do
			if stat == "swingRate" then
				boosts.swingSec = (boosts.swingSec or 1) / (1 + amount)
			elseif stat == "echo" or stat == "zap" or stat == "autoMine" or stat == "blastRadius" or stat == "blastChance" then
				boosts[stat] = (boosts[stat] or 0) + amount
			else
				boosts[stat] = (boosts[stat] or 1) * (1 + amount)
			end
		end
	end
	--[[
		BOTH SLOTS, INCLUDING A SPARSE ONE.

		A flagship carries two temperaments and they stack. The catch is that
		slot 2 can be filled while slot 1 is empty -- fit one, move it, fit
		another -- and `{[2] = temper}` has a LENGTH OF ZERO in Luau, so both
		`#tempers > 0` and ipairs walk none of it. The tool then fell through to
		the legacy single field and the player lost a temperament they had
		fitted and paid for.

		Walk the slot COUNT instead of the array length, and only fall back to
		the legacy field when no slot held anything.
	]]
	local slots = foreverTool.tempers
	local applied = false
	if type(slots) == "table" then
		local n = math.max(#slots, MineTemper.slotCount(foreverTool, nil))
		for i = 1, n do
			local slot = slots[i]
			if type(slot) == "table" then
				applyOne(slot.id or slot.temperId, slot.rarity or slot.temperRarity)
				applied = true
			end
		end
	end
	if not applied then
		applyOne(foreverTool.temperId, foreverTool.temperRarity)
	end
	return boosts
end

function MineTemper.slotCount(foreverTool, def)
	local n = (def and def.temperSlots) or (foreverTool and foreverTool.temperSlots) or 1
	return math.clamp(math.floor(tonumber(n) or 1), 1, 2)
end

--------------------------------------------------------------------------------
-- WORDS, NOT LETTERS
--
-- Three systems, three scales, so you always know what you are looking at:
-- gear is graded F..SSS, pets run Common..Mythic, and a temperament reads as a
-- word like the pets it sits beside in the boost list.
--
-- The letters stay as the internal grade, because every magnitude, pool and
-- weight in this file is keyed by them -- and the top three letters all read
-- "Mythic": which Mythic you pulled is the kit's name (Godnail, Absolute Dig),
-- exactly as a Mythic pet's power is its print rather than its word.
--------------------------------------------------------------------------------
MineTemper.WORD_OF = {
	F = "Common", D = "Uncommon", C = "Rare", B = "Epic",
	A = "Legendary", S = "Mythic", SS = "Mythic", SSS = "Mythic",
}
MineTemper.WORD_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

function MineTemper.wordOf(rarity)
	local g = MineTemper.normalizeRarity(rarity)
	return MineTemper.WORD_OF[g] or "Common"
end

-- The grade's own colour, looked up by word for callers that only have the word.
MineTemper.WORD_COLOR = {
	Common = MineTemper.RARITY_COLOR.F,
	Uncommon = MineTemper.RARITY_COLOR.D,
	Rare = MineTemper.RARITY_COLOR.C,
	Epic = MineTemper.RARITY_COLOR.B,
	Legendary = MineTemper.RARITY_COLOR.A,
	Mythic = MineTemper.RARITY_COLOR.S,
}

function MineTemper.colorOf(rarity)
	local g = MineTemper.normalizeRarity(rarity)
	return MineTemper.RARITY_COLOR[g] or MineTemper.RARITY_COLOR.F
end

-- Higher of two grades, for a collection that keeps the best copy.
function MineTemper.betterGrade(a, b)
	local ra, rb = 0, 0
	for i, g in ipairs(MineTemper.GRADE_ORDER) do
		if g == MineTemper.normalizeRarity(a) then ra = i end
		if g == MineTemper.normalizeRarity(b) then rb = i end
	end
	return (rb > ra) and MineTemper.normalizeRarity(b) or MineTemper.normalizeRarity(a)
end

--------------------------------------------------------------------------------
-- THE CASE
--
-- A temperament is not a pack, it is a CASE: you buy it, it spins, it stops on
-- one, and the one it stopped on is yours to keep and to put on any tool.
--
-- The spin is cosmetic. The winner is decided on the server before the reel
-- exists and the reel is built AROUND it, so nothing the client does to the
-- animation can change what was won.
--------------------------------------------------------------------------------
MineTemper.CASE_PRICE_TOKENS = 20
MineTemper.CASE_BUNDLE_COUNT = 3
MineTemper.CASE_BUNDLE_TOKENS = 50 -- post-rebirth deal: 3 for 50 (vs 60 singles)
-- Kept as an alias so old UI reads that still ask for gems get a clear zero.
MineTemper.CASE_PRICE_GEMS = 0
MineTemper.CASE_NAME = "Temperament Case"
MineTemper.CASE_REEL = 44
MineTemper.CASE_WINNER_AT = 38
-- Scrap tokens by grade. Case = 20 tokens; target ~65% RTP.
-- Common→Epic stay at your anchors (1/2/5/20); Legendary+ carry the rest.
-- Mythic's three numbers are S / SS / SSS (same word family, three grades).
MineTemper.SCRAP_TOKENS = {
	F = 1, D = 2, C = 5, B = 20,
	A = 177, S = 555, SS = 1515, SSS = 6312,
}
function MineTemper.scrapTokens(rarity)
	local g = MineTemper.normalizeRarity(rarity) or "F"
	return MineTemper.SCRAP_TOKENS[g] or 1
end
-- Fillers lean common the way a case reel does, so the stop reads as a result
-- rather than as one more tile going past.
MineTemper.CASE_FILLER_WEIGHTS = { F = 4200, D = 2600, C = 1500, B = 900, A = 400, S = 90, SS = 20, SSS = 4 }

function MineTemper.caseReel(rng, winnerKit, winnerRarity)
	rng = rng or Random.new()
	local function fillerGrade()
		local total = 0
		for _, g in ipairs(MineTemper.GRADE_ORDER) do
			total += MineTemper.CASE_FILLER_WEIGHTS[g] or 0
		end
		local n, acc = rng:NextNumber() * total, 0
		for _, g in ipairs(MineTemper.GRADE_ORDER) do
			acc += MineTemper.CASE_FILLER_WEIGHTS[g] or 0
			if n <= acc then
				return g
			end
		end
		return "F"
	end
	local reel = {}
	local function pack(kit, rarity)
		local row = {
			id = kit.id,
			rarity = rarity,
			name = kit.name,
		}
		-- Icon resolved on the client (MineIcons / kit.stats); stamp stats[1] so
		-- the reel tile can look it up without re-requiring the kit table.
		if type(kit.stats) == "table" and kit.stats[1] then
			row.stat = kit.stats[1]
		end
		return row
	end
	for i = 1, MineTemper.CASE_REEL do
		if i == MineTemper.CASE_WINNER_AT and winnerKit then
			table.insert(reel, pack(winnerKit, MineTemper.normalizeRarity(winnerRarity or winnerKit.rarity)))
		else
			local g = fillerGrade()
			local bucket = byRarity[g]
			local pick = (bucket and #bucket > 0) and bucket[rng:NextInteger(1, #bucket)] or nil
			table.insert(reel, pick and pack(pick, g) or pack({ id = "damage", name = "Damage", stats = { "mineSpeed" } }, "F"))
		end
	end
	return reel, MineTemper.CASE_WINNER_AT
end

function MineTemper.audit()
	local counts, fails = {}, 0
	for _, rarity in ipairs(MineTemper.RARITY_ORDER) do
		counts[rarity] = #(byRarity[rarity] or {})
		if counts[rarity] ~= MineTemper.POOL_COUNTS[rarity] then
			fails += 1
		end
	end
	if #MineTemper.KITS ~= 100 then
		fails += 1
	end
	local seen = {}
	for _, row in ipairs(MineTemper.KITS) do
		row.rarity = MineTemper.normalizeRarity(row.rarity)
		if seen[row.id] then
			fails += 1
		end
		seen[row.id] = true
		if not byRarity[row.rarity] then
			fails += 1
		end
		for _, stat in ipairs(row.stats or {}) do
			if not Stats.STATS[stat] then
				fails += 1
			end
		end
		if row.penalty and not Stats.STATS[row.penalty] then
			fails += 1
		end
	end
	return { counts = counts, kits = #MineTemper.KITS, fails = fails }
end

return MineTemper
