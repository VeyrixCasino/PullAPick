--[[
	MineEnchants: one enchantment, worn on the tool, read in its name.

	Owner, 2026-10-04: "replace runes with enchantments. Pretty much just walk
	to the enchanter and its a prefix too your tool (Sharp Stone Pickaxe, Lucky
	Stone Drill)" -- and, immediately after, "and gear aswell".

	So this replaces TWO systems, not one:

	  RUNES  roll, fuse, socket; kept in p.runes, socketed per tool FAMILY in
	         p.toolSockets and per pet in p.petSockets.
	  GEAR   hats and faces, kept in p.gear, worn in p.equippedGear across
	         three hat slots and one face, each rolling its own stat.

	Between them that is ~2,000 lines of data modules, three screens, five save
	fields and a stacking rule (each pet x its rune x (its hat + your hat), all
	of it x your face) that nothing on screen ever explained. Full SSS gear was
	+1225% on its own -- the single largest multiplier in the game, which is the
	opposite of TODO 0.13 saying charms and skins are the build.

	An enchantment is the whole thing instead:

	  * ONE per tool. Not a stack, not a slot system. The prefix is one word,
	    so the tool wears one.
	  * It rides the TOOL (by uid), not the family. "Sharp Stone Pickaxe" names
	    a specific pickaxe, which is the point of a prefix.
	  * You get it at the Enchanter. Walk there, enchant, done.

	MAGNITUDES ARE DERIVED, NOT INVENTED. Every stat already carries a
	`weight` in MineStats -- what one point of it is worth -- tuned over the
	life of this project. Per level is BUDGET / weight, so a cheap stat gives
	more per level than an expensive one without anyone hand-maintaining a
	second opinion about what a stat is worth. The clamp keeps the two cheapest
	(walkSpeed 0.2, backpack 0.5) from running away.
]]
local MineEnchants = {}

local RS = game:GetService("ReplicatedStorage")
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local Stats = require(shared:WaitForChild("MineStats"))

MineEnchants.MAX_LEVEL = 10

--[[
	The one knob. Per level is BUDGET / weight, clamped.

	At 0.12 a mineSpeed enchant (weight 1.0) reaches +120% at level 10, a blast
	chance enchant (4.0) reaches +30%, and blast radius (6.0) reaches +20%.
	Raise this and every enchantment moves together, in the proportions the
	stat weights already agreed on.
]]
MineEnchants.BUDGET = 0.12
MineEnchants.PER_MIN = 0.02
MineEnchants.PER_MAX = 0.20

--[[
	The roster: a prefix word per stat.

	The word IS the identity -- it is what the player reads on their tool -- so
	no two share one. `id` is save data and is never renamed; the prefix is
	display and may be.
]]
MineEnchants.LIST = {
	{ id = "sharp",       prefix = "Sharp",       stat = "mineSpeed" },
	{ id = "swift",       prefix = "Swift",       stat = "swingRate" },
	{ id = "reaching",    prefix = "Reaching",    stat = "reach" },
	{ id = "wide",        prefix = "Wide",        stat = "blastRadius" },
	{ id = "blasting",    prefix = "Blasting",    stat = "oreYield" },
	{ id = "violent",     prefix = "Violent",     stat = "procPower" },
	{ id = "shocking",    prefix = "Shocking",    stat = "zap" },
	{ id = "rumbling",    prefix = "Rumbling",    stat = "earthquake" },
	{ id = "bouncing",    prefix = "Bouncing",    stat = "ricochet" },
	{ id = "golden",      prefix = "Golden",      stat = "coinBonus" },
	{ id = "gleaming",    prefix = "Gleaming",    stat = "gemFind" },
	{ id = "rich",        prefix = "Rich",        stat = "rareOre" },
	{ id = "lucky",       prefix = "Lucky",       stat = "luck" },
	{ id = "prospecting", prefix = "Prospecting", stat = "oreLuck" },
	{ id = "fated",       prefix = "Fated",       stat = "packLuck" },
	{ id = "prying",      prefix = "Prying",      stat = "chestLuck" },
	{ id = "seeking",     prefix = "Seeking",     stat = "fossilFind" },
	{ id = "charmed",     prefix = "Charmed",     stat = "luckyFind" },
	{ id = "grinding",    prefix = "Grinding",    stat = "pulverize" },
	{ id = "salvaging",   prefix = "Salvaging",   stat = "scrap" },
	{ id = "cooled",      prefix = "Cooled",      stat = "coolant" },
	{ id = "hasty",       prefix = "Hasty",       stat = "shortFuse" },
	{ id = "deep",        prefix = "Deep",        stat = "backpack" },
	{ id = "fleet",       prefix = "Fleet",       stat = "walkSpeed" },
	{ id = "churning",    prefix = "Churning",    stat = "dirtBreak" },
}

local BY_ID, BY_STAT = {}, {}
for _, e in ipairs(MineEnchants.LIST) do
	BY_ID[e.id] = e
	BY_STAT[e.stat] = e
end
MineEnchants.BY_ID = BY_ID
MineEnchants.BY_STAT = BY_STAT

function MineEnchants.byId(id)
	return BY_ID[tostring(id or "")]
end

function MineEnchants.forStat(stat)
	return BY_STAT[tostring(stat or "")]
end

-- What one level of this enchantment is worth, off the stat's own weight.
function MineEnchants.perLevel(id)
	local def = MineEnchants.byId(id)
	if not def then
		return 0
	end
	local st = (Stats.STATS or {})[def.stat]
	local weight = math.max(0.05, tonumber(st and st.weight) or 1)
	return math.clamp(MineEnchants.BUDGET / weight,
		MineEnchants.PER_MIN, MineEnchants.PER_MAX)
end

function MineEnchants.clampLevel(level)
	return math.clamp(math.floor(tonumber(level) or 1), 1, MineEnchants.MAX_LEVEL)
end

-- The magnitude at a level. Linear: level 3 is worth exactly three level 1s,
-- so "what does one more level buy me" has one answer at every rung.
function MineEnchants.amount(id, level)
	return MineEnchants.perLevel(id) * MineEnchants.clampLevel(level)
end

--[[
	WHAT IT COSTS, IN GEMS.

	Gems, because that is what the rune bench charged and ore is already the
	Forge's currency -- an enchantment should not compete with levelling the
	tool it sits on for the same pile.

	`gemCost(level)` is the price of the step that REACHES that level, so
	reaching level 1 (a fresh enchantment) is GEM_BASE and nothing is free. nil
	above the cap, the same contract MineConfig.toolUpgradeCost uses, so a
	caller cannot charge for a level that does not exist.
]]
MineEnchants.GEM_BASE = 150
MineEnchants.GEM_GROW = 1.75

function MineEnchants.gemCost(level)
	local L = math.floor(tonumber(level) or 1)
	if L < 1 or L > MineEnchants.MAX_LEVEL then
		return nil
	end
	return math.ceil(MineEnchants.GEM_BASE * (MineEnchants.GEM_GROW ^ (L - 1)))
end

-- Everything poured into an enchantment at `level`, for what a re-roll throws
-- away. Geometric so it stays exact rather than drifting the way a loop would.
function MineEnchants.gemSpent(level)
	local L = MineEnchants.clampLevel(level)
	local g = MineEnchants.GEM_GROW
	return math.ceil(MineEnchants.GEM_BASE * ((g ^ L) - 1) / (g - 1))
end

--[[
	THE PREFIX.

	Just the word. The level is shown beside the name rather than inside it:
	the owner wrote "Sharp Stone Pickaxe", not "Sharp III Stone Pickaxe", and a
	numeral in the middle of a name is what made the old rune labels unreadable.
]]
function MineEnchants.prefix(ench)
	if type(ench) ~= "table" then
		return nil
	end
	local def = MineEnchants.byId(ench.id)
	return def and def.prefix or nil
end

-- "Sharp Stone Pickaxe" out of "Stone Pickaxe". No enchantment, no change.
function MineEnchants.decorate(name, ench)
	local p = MineEnchants.prefix(ench)
	if not p then
		return name
	end
	return p .. " " .. tostring(name)
end

--[[
	Fold an enchantment into a boost table.

	Additive stats take the amount straight; multiplier stats take 1 + amount,
	which is the same contract MineCards uses. Reading ADDITIVE_STATS off
	MineCards rather than keeping a second list is deliberate: the two drifting
	apart would silently pay a chance stat as a multiplier.
]]
function MineEnchants.apply(boosts, ench, additiveStats)
	if type(boosts) ~= "table" or type(ench) ~= "table" then
		return boosts
	end
	local def = MineEnchants.byId(ench.id)
	if not def then
		return boosts
	end
	local amount = MineEnchants.amount(ench.id, ench.level)
	if amount <= 0 then
		return boosts
	end
	local key = def.stat
	local additive = additiveStats and additiveStats[key]
	if additive then
		boosts[key] = (tonumber(boosts[key]) or 0) + amount
	else
		boosts[key] = (tonumber(boosts[key]) or 1) * (1 + amount)
	end
	return boosts
end

--[[
	MIGRATION, so nobody opens the game to an empty tool.

	A rune and a gear piece both reduce to "a stat and how much of it", which is
	exactly what an enchantment is. The level is whatever level of the matching
	enchantment is worth the same -- rounded UP, so a conversion never takes
	power away, and clamped to the cap.

	Returns nil for anything carrying a stat no enchantment covers, which the
	caller should refund rather than silently drop.
]]
function MineEnchants.fromStatAmount(stat, amount)
	local def = MineEnchants.forStat(stat)
	if not def then
		return nil
	end
	local per = MineEnchants.perLevel(def.id)
	if per <= 0 then
		return nil
	end
	local level = MineEnchants.clampLevel(math.ceil((tonumber(amount) or 0) / per))
	return { id = def.id, level = level }
end

-- The strongest enchantment a pile of old pieces is worth. Runes and gear both
-- arrive as rows with a stat and a fraction; the best single one wins, because
-- a tool wears exactly one.
function MineEnchants.bestOf(rows)
	local best, bestAmount
	for _, row in ipairs(rows or {}) do
		if type(row) == "table" then
			local stat = row.stat
			local amount = tonumber(row.pct) or tonumber(row.amount) or tonumber(row.value) or 0
			local ench = stat and MineEnchants.fromStatAmount(stat, amount)
			if ench then
				local worth = MineEnchants.amount(ench.id, ench.level)
				if not bestAmount or worth > bestAmount then
					best, bestAmount = ench, worth
				end
			end
		end
	end
	return best
end

return MineEnchants
