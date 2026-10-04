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
-- The skins ladder. Enchantments ride it rather than inventing a second
-- one, because the owner asked for "the same rarity as rune/temperment/skins".
local Temper = require(shared:WaitForChild("MineTemper"))

--[[
	FIVE LEVELS, ROMAN, EQUAL CHANCE.

	Owner, 2026-10-04: "make it random 1-5 to determine level (1 in 25k for
	exotic V)" -- then corrected to "exotic should be 1 in 1000, exotic V 1 in
	5000". 1/1000 x 1/5 = 1/5000, so the level roll is uniform over five.
]]
MineEnchants.MAX_LEVEL = 5
MineEnchants.ROMAN = { "I", "II", "III", "IV", "V" }

--[[
	RARITY: the skins ladder, condensed so a tier's V-chance IS the skins
	table's own chance for that tier.

	Owner: "look at the drop tables of skins, and try to condense it so the
	rarity is the chance to get a the V level, for all the rarest ones (over
	1-200)".

	MineTemper.RARITY_WEIGHTS (skins) out of 10,000: F 5000, D 2763, C 1250,
	B 675, A 250, S 50, SS 10, SSS 2 -- so skins SS is 1/1000 and skins SSS is
	1/5000. The weights below put enchant SS at exactly 1/200 and enchant SSS
	at 1/1000, which means:

	    enchant SS  -> V at 1/1000   = the skins table's SS
	    enchant SSS -> V at 1/5000   = the skins table's SSS

	Both tiers at or rarer than 1/200 -- the boundary the owner named -- have a
	V-chance that lands exactly on the skins ladder. That is the whole rule, and
	tools/verify/enchants.js asserts it against MineTemper rather than against a
	number copied into a comment.
]]
MineEnchants.RARITY_ORDER = { "F", "D", "C", "B", "A", "S", "SS", "SSS" }
MineEnchants.RARITY_WEIGHTS = {
	F = 4200, D = 2700, C = 1600, B = 900, A = 400, S = 140, SS = 50, SSS = 10,
}
MineEnchants.RARITY_TOTAL = 10000

-- The display names. "Exotic" is the one the owner says out loud; the letters
-- are what the save and every other ladder in the game use.
MineEnchants.RARITY_NAME = {
	F = "Common", D = "Uncommon", C = "Rare", B = "Epic",
	A = "Legendary", S = "Mythic", SS = "Divine", SSS = "Exotic",
}

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
	Rarity scales the magnitude, on the two ladders MineTemper already keeps.

	A CHANCE stat takes the gentle one. Blasting at Divine on the ordinary
	ladder would be +75 percentage points of blast chance at V, which is not a
	proc any more, it is a certainty. PROC_RARITY_MULT exists for exactly this
	and skins already use it the same way.
]]
MineEnchants.CHANCE_STATS = {
	blastChance = true, zap = true, earthquake = true, ricochet = true,
	luckyFind = true, pulverize = true,
}

--[[
	The roster: a prefix word per stat.

	The word IS the identity -- it is what the player reads on their tool -- so
	no two share one. `id` is save data and is never renamed; the prefix is
	display and may be.
]]
--[[
	The roster: a prefix word per stat, and a RARITY per enchantment.

	Owner: "Make each enchantment have its own rarity". So the rarity is a
	property of the enchantment, not of the roll -- Wide is always Exotic, Sharp
	is always Common -- and the roll picks a tier by weight and then an
	enchantment uniformly inside it.

	Which enchantment sits where is read off the stat's own MineStats weight:
	the most expensive stats in the game are the rarest prefixes. Nobody
	hand-ranked them twice.

	`id` is save data and is never renamed; `prefix` is display and may be.
]]
MineEnchants.LIST = {
	-- Exotic, 1/1000. The single most expensive stat in MineStats (6.0).
	{ id = "wide",        prefix = "Wide",        stat = "blastRadius", rarity = "SSS" },

	-- Divine, 1/200.
	{ id = "blasting",    prefix = "Blasting",    stat = "blastChance",    rarity = "SS" },
	{ id = "grinding",    prefix = "Grinding",    stat = "pulverize",   rarity = "SS" },

	-- Mythic.
	{ id = "charmed",     prefix = "Charmed",     stat = "luckyFind",   rarity = "S" },
	{ id = "violent",     prefix = "Violent",     stat = "procPower",   rarity = "S" },
	{ id = "rumbling",    prefix = "Rumbling",    stat = "earthquake",  rarity = "S" },

	-- Legendary.
	{ id = "shocking",    prefix = "Shocking",    stat = "zap",         rarity = "A" },
	{ id = "cooled",      prefix = "Cooled",      stat = "coolant",     rarity = "A" },
	{ id = "bouncing",    prefix = "Bouncing",    stat = "ricochet",    rarity = "A" },

	-- Epic.
	{ id = "prospecting", prefix = "Prospecting", stat = "oreLuck",     rarity = "B" },
	{ id = "fated",       prefix = "Fated",       stat = "packLuck",    rarity = "B" },
	{ id = "hasty",       prefix = "Hasty",       stat = "shortFuse",   rarity = "B" },
	{ id = "prying",      prefix = "Prying",      stat = "chestLuck",   rarity = "B" },

	-- Rare.
	{ id = "lucky",       prefix = "Lucky",       stat = "luck",        rarity = "C" },
	{ id = "gleaming",    prefix = "Gleaming",    stat = "gemFind",     rarity = "C" },
	{ id = "rich",        prefix = "Rich",        stat = "rareOre",     rarity = "C" },

	-- Uncommon.
	{ id = "seeking",     prefix = "Seeking",     stat = "fossilFind",  rarity = "D" },
	{ id = "swift",       prefix = "Swift",       stat = "swingRate",   rarity = "D" },
	{ id = "reaching",    prefix = "Reaching",    stat = "reach",       rarity = "D" },
	{ id = "salvaging",   prefix = "Salvaging",   stat = "scrap",       rarity = "D" },

	-- Common. "Sharp Stone Pickaxe" is the owner's own example, and it is the
	-- one every player will see first.
	{ id = "sharp",       prefix = "Sharp",       stat = "mineSpeed",   rarity = "F" },
	{ id = "churning",    prefix = "Churning",    stat = "dirtBreak",   rarity = "F" },
	{ id = "golden",      prefix = "Golden",      stat = "coinBonus",   rarity = "F" },
	--[[
		Deep (backpack) and Fleet (walkSpeed) retired 2026-10-04 with the stats
		themselves. An enchantment whose stat no longer moves is a dead prefix.

		They were NOT replaced. Every remaining live stat already has exactly
		one enchantment, so inventing two more would mean two prefixes sharing
		a stat -- and the check forbids that for good reason: two differently
		named tools would read identically. Common is simply three now.
	]]
}



local BY_ID, BY_STAT, BY_RARITY = {}, {}, {}
for _, e in ipairs(MineEnchants.LIST) do
	BY_ID[e.id] = e
	BY_STAT[e.stat] = e
	BY_RARITY[e.rarity] = BY_RARITY[e.rarity] or {}
	table.insert(BY_RARITY[e.rarity], e)
end
MineEnchants.BY_ID = BY_ID
MineEnchants.BY_STAT = BY_STAT
MineEnchants.BY_RARITY = BY_RARITY

function MineEnchants.rarityOf(id)
	local def = BY_ID[tostring(id or "")]
	return def and def.rarity or nil
end

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

--[[
	The rarity multiplier for an enchantment, off MineTemper's own ladders.

	Chance stats take PROC_RARITY_MULT (F 0.30 -> SSS 1.30); everything else
	takes RARITY_MULT (F 0.45 -> SSS 7.50). Reading them from MineTemper rather
	than copying the numbers means a skins rebalance moves enchantments with it.
]]
function MineEnchants.rarityMult(id)
	local def = MineEnchants.byId(id)
	if not def then
		return 0
	end
	local ladder = MineEnchants.CHANCE_STATS[def.stat]
		and Temper.PROC_RARITY_MULT or Temper.RARITY_MULT
	return tonumber(ladder and ladder[def.rarity]) or 1
end

-- The magnitude at a level. Linear in level -- level 3 is worth exactly three
-- level 1s, so "what does one more level buy me" has one answer at every rung
-- -- and scaled once by the enchantment's rarity.
function MineEnchants.amount(id, level)
	return MineEnchants.perLevel(id)
		* MineEnchants.clampLevel(level)
		* MineEnchants.rarityMult(id)
end

--[[
	WHAT IT COSTS: ONE FLAT PRICE, FOREVER.

	Owner, 2026-10-04: "Make enchantment price stay the game with rebirths
	(broke players arent going to try to get exotic V, endgame players will.)"

	So this is a CONSTANT. It does not read prestige, rebirth count, zone or
	tool tier, and tools/verify/enchants.js asserts the verb never touches any
	of them. The sink is self-regulating without a curve: a new player rolls it
	once or twice and moves on, and the player chasing Exotic V at 1 in 5,000
	spends five thousand of these, which is the whole point.

	Gems, because ore is already the Forge's currency and an enchantment should
	not compete with levelling the tool it sits on for the same pile.
]]
MineEnchants.ROLL_PRICE = 500

--[[
	ROLL ONE.

	Tier by weight, then an enchantment uniformly inside that tier, then a level
	uniformly over five. Three independent draws, so the odds of any exact
	result are the product -- which is what makes "Exotic V is 1 in 5,000" a
	fact about this function rather than a claim in a comment.

	Takes an rng so the server can seed it and a test can replay it.
]]
function MineEnchants.rollRarity(rng)
	local roll = (rng and rng:NextInteger(1, MineEnchants.RARITY_TOTAL))
		or math.random(1, MineEnchants.RARITY_TOTAL)
	local acc = 0
	for _, grade in ipairs(MineEnchants.RARITY_ORDER) do
		acc += (tonumber(MineEnchants.RARITY_WEIGHTS[grade]) or 0)
		if roll <= acc then
			return grade
		end
	end
	-- Only reachable if the weights stop summing to RARITY_TOTAL, which the
	-- check forbids. Falling back to the commonest tier beats returning nil.
	return MineEnchants.RARITY_ORDER[1]
end

function MineEnchants.roll(rng)
	local grade = MineEnchants.rollRarity(rng)
	local pool = MineEnchants.BY_RARITY[grade]
	if not pool or #pool == 0 then
		return nil
	end
	local pick = pool[(rng and rng:NextInteger(1, #pool)) or math.random(1, #pool)]
	local level = (rng and rng:NextInteger(1, MineEnchants.MAX_LEVEL))
		or math.random(1, MineEnchants.MAX_LEVEL)
	return { id = pick.id, level = level }
end

--[[
	One in how many.

	`odds(id)` is the chance of rolling that enchantment at any level;
	`odds(id, level)` is the chance of that exact result. With Wide alone at
	Exotic, odds("wide") is 1 in 1,000 and odds("wide", 5) is 1 in 5,000 --
	the owner's two numbers, derived rather than asserted.
]]
function MineEnchants.odds(id, level)
	local def = MineEnchants.byId(id)
	if not def then
		return nil
	end
	local weight = tonumber(MineEnchants.RARITY_WEIGHTS[def.rarity]) or 0
	if weight <= 0 then
		return nil
	end
	local pool = #(MineEnchants.BY_RARITY[def.rarity] or {})
	local p = (weight / MineEnchants.RARITY_TOTAL) / math.max(1, pool)
	if level ~= nil then
		p /= MineEnchants.MAX_LEVEL
	end
	return 1 / p
end

-- "Exotic Wide V", for a tooltip. The TOOL's name is just the prefix; this is
-- the full description for a panel that has room for it.
function MineEnchants.label(ench)
	local def = type(ench) == "table" and MineEnchants.byId(ench.id) or nil
	if not def then
		return "Unenchanted"
	end
	local lv = MineEnchants.clampLevel(ench.level)
	return string.format("%s %s %s",
		MineEnchants.RARITY_NAME[def.rarity] or def.rarity,
		def.prefix,
		MineEnchants.ROMAN[lv] or tostring(lv))
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
