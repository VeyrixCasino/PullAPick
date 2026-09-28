-- MineStats: what a stat is worth, what each type specialises in, and the
-- budget a pet of a given tier is allowed to spend.
--
-- The point of this file is that "is this pet balanced?" has a NUMERIC answer.
-- Every stat carries a weight in points per +1%, every tier has a point budget,
-- and a kit is legal when its total lands inside the budget's tolerance. Run
-- MineStats.audit() to check the whole table at once.
local MineStats = {}

--------------------------------------------------------------------------------
-- STATS
--
-- `weight` is points per +1%. Stats that compound with others, or that create
-- resources rather than speed them up, cost more.
-- No magnitude caps. Isolate printers by who can wear the stat, not by
-- clamping the stack. Tool-family jobs are runes. All-tool jobs are pets.
--------------------------------------------------------------------------------

MineStats.STATS = {
	mineSpeed   = { label = "Mine Speed",    weight = 1.0, unit = "%", desc = "Damage on every tool (pick, drill, bomb). Pets only — never a gem rune. Short Fuse rune adds more on explosives." },
	swingRate   = { label = "Swing Rate",    weight = 1.4, unit = "%", desc = "Swings per second." },
	reach       = { label = "Reach",         weight = 1.4, unit = "%", desc = "Pick/drill aim distance. 26 × (1 + reach). Rune only." },
	blastRadius = { label = "Blast Radius",  weight = 6.0, unit = "%", desc = "Tool pattern size. Rune only — pets never wear this." },
	oreYield    = { label = "Blast",         weight = 4.0, unit = "%", desc = "Destroy-proc: chance the aimed block's death also hits 6 neighbors. Chests stay centre-only." },
	coinBonus   = { label = "Coin Bonus",    weight = 0.8, unit = "%", desc = "Coins from selling." },
	gemFind     = { label = "Gem Find",      weight = 1.8, unit = "%", desc = "Gems dropped by ore." },
	luck        = { label = "Luck",          weight = 2, unit = "%", desc = "Pack yield and tool finds; mined packs show a luck badge." },
	chestLuck   = { label = "Chest Luck",    weight = 2.2, unit = "%", desc = "Higher chance of packs, tools, and other rare chest drops." },
	rareOre     = { label = "Rare Ore",      weight = 1.8, unit = "%", desc = "Weighting toward deeper, richer ore." },
	backpack    = { label = "Backpack",      weight = 0.5, unit = "%", desc = "Carry capacity." },
	walkSpeed   = { label = "Walk Speed",    weight = 0.2, unit = "%", desc = "Movement speed." },
	dirtBreak   = { label = "Dirt Break",    weight = 1.0, unit = "%", desc = "Extra dig damage through blocks." },
	echo        = { label = "Echo Strike",   weight = 1.5, unit = "%", desc = "Chance a swing fires twice." },
	zap         = { label = "Zap",           weight = 2.5, unit = "%", desc = "Chance dig hits chain to nearby blocks; chance and damage fall off each hop." },
	-- LEGACY. Auto Mine was replaced by Gem Find: anything still carrying this
	-- key is converted at AUTO_MINE_TO_GEM before it is paid or printed (see
	-- MineStats.withoutAutoMine, MineTemper.magnitudes, MineServer.boosts). The
	-- entry stays so old saves and old kits still resolve a weight; it is out of
	-- STAT_ORDER so no screen lists it. Auto-mining itself is now a purchased
	-- licence (p.autoMineLicense), not a stat anybody rolls.
	autoMine    = { label = "Gem Find",      weight = 2.5, unit = "%", desc = "Legacy: paid out as Gem Find.", legacy = true },
	luckyFind   = { label = "Lucky Block find", weight = 3.5, unit = "%", desc = "Extra chance to grant a pit cube on destroy. Pets only — never a gem rune." },
	fossilFind  = { label = "Fossil Finder",    weight = 1.5, unit = "%", desc = "Multiplies fossil fragment yield. Does not change pack rarity." },
	pulverize   = { label = "Pulverizer",       weight = 4.0, unit = "%", desc = "Chance to drop 1 stardust when dirt/ore dies. Not chests, fossils, or cubes." },
	scrap       = { label = "Scrap",            weight = 1.2, unit = "%", desc = "Extra stardust when a chest dies. Not the Scrapper. Pets only." },
	coolant     = { label = "Coolant",          weight = 2.5, unit = "%", desc = "Drill spin-up. turn / (1 + coolant). Apex stays 0. Rune only." },
	shortFuse   = { label = "Short Fuse",       weight = 2.2, unit = "%", desc = "Bomb cooldown / (1 + p), and extra mineSpeed on explosives. Rune only." },
}

MineStats.STAT_ORDER = {
	"mineSpeed", "swingRate", "reach", "blastRadius", "echo", "zap",
	"oreYield", "rareOre", "gemFind", "coinBonus",
	"luck", "chestLuck", "luckyFind", "fossilFind", "pulverize", "scrap",
	"coolant", "shortFuse", "backpack", "walkSpeed", "dirtBreak",
}

MineStats.RUNE_ONLY = {
	blastRadius = true, reach = true, coolant = true, shortFuse = true,
}

MineStats.PET_ONLY = {
	mineSpeed = true, luckyFind = true, scrap = true,
}

--------------------------------------------------------------------------------
-- TYPE SPECIALISATION
--
-- Each type owns a VERB, not just a number. A pet's kit spends its budget
-- mostly on its type's primary, some on the secondary, and a little wherever.
-- This is what makes "I need a Shadow pet for chest runs" a real sentence.
--------------------------------------------------------------------------------

MineStats.TYPE_KITS = {
	Fire     = { verb = "Strike",    primary = "mineSpeed",  secondary = "dirtBreak",  tertiary = "swingRate" },
	Frost    = { verb = "Tempo",     primary = "swingRate",  secondary = "mineSpeed",  tertiary = "dirtBreak" },
	Water    = { verb = "Pulverize", primary = "pulverize",  secondary = "backpack",   tertiary = "walkSpeed" },
	Grass    = { verb = "Harvest",   primary = "fossilFind", secondary = "backpack",   tertiary = "dirtBreak" },
	Ground   = { verb = "Excavate",  primary = "dirtBreak",  secondary = "mineSpeed",  tertiary = "backpack" },
	Metal    = { verb = "Scrap",     primary = "scrap",      secondary = "mineSpeed",  tertiary = "backpack" },
	Electric = { verb = "Zap",       primary = "zap",        secondary = "swingRate",  tertiary = "mineSpeed" },
	Crystal  = { verb = "Prospect",  primary = "gemFind",    secondary = "luck",       tertiary = "chestLuck" },
	Shadow   = { verb = "Fortune",   primary = "luck",       secondary = "chestLuck",  tertiary = "backpack" },
	Space    = { verb = "Find",      primary = "luckyFind",  secondary = "rareOre",       tertiary = "luck" },
}

-- Cleared: no type/family marketing blurbs on pets (wild claims like instant-break).
MineStats.TYPE_BLURB = {}

--------------------------------------------------------------------------------
-- BUDGETS
--
-- Point pool a pet of each tier may spend. X and Y spend the SAME budget in
-- different shapes: X concentrates it and takes a drawback, Y spreads it flat.
--------------------------------------------------------------------------------

MineStats.TIER_BUDGET = {
	Common = 25, Uncommon = 48, Rare = 60, Epic = 90,
	Legendary = 125, Mythic = 190, Divine = 275, Exotic = 380,
}

-- X and Y must be worth the SAME. X spends 1.15x its budget and hands 0.15x
-- back as a penalty, netting 1.00 -- identical to Y. An earlier version used
-- 1.35/0.15, which quietly made every X pet 20% stronger than its Y counterpart.
MineStats.SET_PROFILE = {
	-- Internal kit-shape only. No player-facing "family" flavour copy.
	X = { stats = 2, concentration = 1.15, drawback = 0.15 },
	Y = { stats = 4, concentration = 1.00, drawback = 0.00 },
}

-- Filler and penalty stats are drawn from here, skipping anything the type
-- already uses -- otherwise a penalty can land on the type's own primary and
-- cancel it out. That is what broke Water, whose primary IS backpack.
MineStats.NEUTRAL_STATS = { "backpack", "walkSpeed", "coinBonus", "mineSpeed" }

MineStats.TOLERANCE = 0.05 -- a kit may land within +/-5% of its budget

--------------------------------------------------------------------------------
-- KIT GENERATION
--
-- Produces a legal default kit for a (type, tier, set). Hand-authored per-pet
-- boosts replace these; this is the shape they should be checked against.
--------------------------------------------------------------------------------

local function round(v, dp)
	local m = 10 ^ (dp or 2)
	return math.floor(v * m + 0.5) / m
end

function MineStats.kitFor(typeName, tier, setKey)
	local kit = MineStats.TYPE_KITS[typeName]
	local budget = MineStats.TIER_BUDGET[tier]
	local profile = MineStats.SET_PROFILE[setKey] or MineStats.SET_PROFILE.Y
	if not (kit and budget) then
		return {}
	end

	-- Stats this type owns; nothing else may land on them.
	local owned = { [kit.primary] = true, [kit.secondary] = true, [kit.tertiary] = true }
	local function freeStat()
		for _, s in ipairs(MineStats.NEUTRAL_STATS) do
			if not owned[s] then
				return s
			end
		end
		return nil
	end

	-- X pours its budget into two stats and hands some back as a penalty;
	-- Y spreads the same points across four with no downside. Both net 1.00x.
	local spend = budget * profile.concentration
	local slots
	if profile.stats == 2 then
		slots = { { kit.primary, 0.68 }, { kit.secondary, 0.32 } }
	else
		local filler = freeStat()
		owned[filler] = true
		slots = { { kit.primary, 0.42 }, { kit.secondary, 0.26 }, { kit.tertiary, 0.20 }, { filler, 0.12 } }
	end

	local out = {}
	for _, row in ipairs(slots) do
		local stat, share = row[1], row[2]
		local def = MineStats.STATS[stat]
		if def then
			out[stat] = round((spend * share) / def.weight / 100, 4)
		end
	end
	if profile.drawback > 0 then
		local penaltyStat = freeStat()
		local def = penaltyStat and MineStats.STATS[penaltyStat]
		if def then
			out[penaltyStat] = round(-(budget * profile.drawback) / def.weight / 100, 4)
		end
	end
	return out
end

-- What a kit is actually worth, in budget points. Penalties count against it.
function MineStats.valueOf(kit)
	local total = 0
	for stat, amount in pairs(kit or {}) do
		local def = MineStats.STATS[stat]
		if def then
			total += amount * 100 * def.weight
		end
	end
	return total
end

-- Auto Mine is 2.5 points per +1%. Gem Find is 1.6. Same budget, higher percent.
MineStats.AUTO_MINE_TO_GEM = 2.5 / 1.8

function MineStats.withoutAutoMine(kit)
	if type(kit) ~= "table" then
		return kit
	end
	local auto = tonumber(kit.autoMine) or 0
	if auto == 0 then
		return kit
	end
	local copy = table.clone(kit)
	copy.autoMine = nil
	copy.gemFind = (tonumber(copy.gemFind) or 0) + auto * MineStats.AUTO_MINE_TO_GEM
	return copy
end

-- Every stat a kit sets, in display order, formatted for a card.
function MineStats.describe(kit)
	kit = MineStats.withoutAutoMine(kit)
	local lines = {}
	for _, stat in ipairs(MineStats.STAT_ORDER) do
		local amount = kit and kit[stat]
		if amount and amount ~= 0 then
			local def = MineStats.STATS[stat]
			table.insert(lines, {
				stat = stat,
				label = def.label,
				text = string.format("%s%.1f%%", amount > 0 and "+" or "", amount * 100),
				positive = amount > 0,
			})
		end
	end
	return lines
end

--------------------------------------------------------------------------------
-- AUDIT
--
-- Checks every (type, tier, set) kit lands inside tolerance, and reports which
-- stat each type actually leans on. Returns a plain report table.
--------------------------------------------------------------------------------

function MineStats.audit()
	local rows, fails = {}, 0
	for typeName in pairs(MineStats.TYPE_KITS) do
		for tier, budget in pairs(MineStats.TIER_BUDGET) do
			for _, setKey in ipairs({ "X", "Y" }) do
				local kit = MineStats.kitFor(typeName, tier, setKey)
				local value = MineStats.valueOf(kit)
				-- Both sets net 1.00x budget, so the target is simply the budget.
				local profile = MineStats.SET_PROFILE[setKey]
				local target = budget * (profile.concentration - profile.drawback)
				local drift = target > 0 and (value - target) / target or 0
				local ok = math.abs(drift) <= MineStats.TOLERANCE
				if not ok then
					fails += 1
				end
				table.insert(rows, {
					type = typeName, tier = tier, set = setKey,
					value = value, target = target, drift = drift, ok = ok,
				})
			end
		end
	end
	return rows, fails
end

return MineStats
