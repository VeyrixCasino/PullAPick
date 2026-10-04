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
	--[[
		BLAST RADIUS IS CUBIC, AND WAS PRICED LINEAR. Owner, 2026-10-04:
		"balance fire.. rn fire is just way to over powered".

		MinePatterns builds the pattern with `sphere(out, cx, cy, cz, radius)`
		where `radius = tool.radius * (1 + blastRadius)`. A sphere's cell count
		goes as r^3, so +50% radius is about 3.4x the blocks destroyed, not
		1.5x. Every system that spends a MineStats budget -- the skill tree,
		enchantments, gear, runes -- divides by this weight, so at 6.0 they were
		all handing out roughly THREE TIMES the power they thought they were.

		18.0 is 6.0 x 3: the derivative of r^3 at the margin. One number, and
		the tree, the enchanter and the gear roller all correct together.

		Fire is the wedge that felt it, because blastRadius is its primary and
		nine nodes grant it -- and it got worse the moment the missing
		sk.blastRadius line was restored and those nodes started paying at all.
	]]
	blastRadius = { label = "Blast Radius",  weight = 18.0, unit = "%", desc = "Tool pattern size. A sphere, so +50% radius is ~3.4x the blocks." },
	oreYield    = { label = "Blast Chance",  weight = 4.0, unit = "%", desc = "CHANCE the aimed block's death also hits 6 neighbours. How hard it hits is Proc Power. Chests stay centre-only." },
	coinBonus   = { label = "Coin Bonus",    weight = 0.8, unit = "%", desc = "Coins from selling." },
	gemFind     = { label = "Gem Find",      weight = 1.8, unit = "%", desc = "Gems dropped by ore." },
	luck        = { label = "Luck",          weight = 2, unit = "%", desc = "Pack yield and tool finds; mined packs show a luck badge." },
	chestLuck   = { label = "Chest Luck",    weight = 2.2, unit = "%", desc = "Higher chance of packs, tools, and other rare chest drops." },
	rareOre     = { label = "Rare Ore",      weight = 1.8, unit = "%", desc = "Weighting toward deeper, richer ore." },
	--[[
		RETIRED, 2026-10-04. Owner: "Can we remove backpack and walkspeed as
		boost".

		Same treatment echo and autoMine got: the entry STAYS so an old save,
		an old kit and the two server reads still resolve, and it leaves
		STAT_ORDER so no screen lists it and no pool rolls it. Deleting the key
		outright would break `boosts(p).backpack` and `boosts(p).walkSpeed`,
		which are live reads -- they now simply never move off 1.

		Carry capacity was always two systems arguing anyway: this stat, and
		the purchased backpack ladder plus the ore pouch tier. The ladder wins.
	]]
	backpack    = { label = "Backpack",      weight = 0.5, unit = "%", desc = "Retired: capacity comes from the backpack ladder and the ore pouch.", legacy = true },
	walkSpeed   = { label = "Walk Speed",    weight = 0.2, unit = "%", desc = "Retired: no longer rollable or granted.", legacy = true },
	dirtBreak   = { label = "Dirt Break",    weight = 1.0, unit = "%", desc = "Extra dig damage through blocks." },
	-- LEGACY, like autoMine below: barred as a buff and paid out as Swing Rate
	-- at ECHO_TO_SWING. The entry stays so an old kit or save still resolves a
	-- weight; it is out of STAT_ORDER so no screen lists it.
	echo        = { label = "Echo Strike",   weight = 1.5, unit = "%", desc = "Legacy: paid out as Swing Rate.", legacy = true },
	zap         = { label = "Zap Chance",    weight = 2.5, unit = "%", desc = "CHANCE a dig chains to nearby blocks, up to 6 hops. How hard each hop lands is Proc Power." },
	-- LEGACY. Auto Mine was replaced by Gem Find: anything still carrying this
	-- key is converted at AUTO_MINE_TO_GEM before it is paid or printed (see
	-- MineStats.withoutAutoMine, MineTemper.magnitudes, MineServer.boosts). The
	-- entry stays so old saves and old kits still resolve a weight; it is out of
	-- STAT_ORDER so no screen lists it. Auto-mining itself is now a purchased
	-- licence (p.autoMineLicense), not a stat anybody rolls.
	autoMine    = { label = "Gem Find",      weight = 2.5, unit = "%", desc = "Legacy: paid out as Gem Find.", legacy = true },
	luckyFind   = { label = "Lucky Block find", weight = 3.5, unit = "%", desc = "Extra chance to grant a pit cube on destroy. Pets only — never a gem rune." },
	-- Fossils are gone; ore replaced them. The key stays fossilFind so nothing
	-- that writes it has to be rewritten, but it is the Ore Finder now.
	fossilFind  = { label = "Ore Finder",       weight = 1.5, unit = "%", desc = "Multiplies how much ore a pack pays. Stamped on the pack when you mine it. Does not change which ore you get." },
	pulverize   = { label = "Pulverizer",       weight = 4.0, unit = "%", desc = "Chance to drop 1 stardust when dirt/ore dies. Not chests or cubes." },
	scrap       = { label = "Scrap",            weight = 1.2, unit = "%", desc = "Extra stardust when a chest dies. Not the Scrapper. Pets only." },
	coolant     = { label = "Coolant",          weight = 2.5, unit = "%", desc = "Drill spin-up. turn / (1 + coolant). Apex stays 0. Rune only." },
	shortFuse   = { label = "Short Fuse",       weight = 2.2, unit = "%", desc = "Bomb cooldown / (1 + p), and extra mineSpeed on explosives. Rune only." },
	-- The two new build boosts. Priced near zap (2.5) because they are the
	-- same shape of thing -- a chance to reach a block you did not swing at --
	-- and neither multiplies the hit itself.
	--[[
		THE THREE LUCKS (TODO 6.2 "Split the hat luck boost").

		Generic `luck` was doing three unrelated jobs at once, which is why the
		owner asked for it split. Read off its four call sites in MineServer:

		  * it scaled ORE_CASE_CHANCE on an ore break          -> ore luck
		  * it decided IF a chest spawned, and with chestLuck
		    WHICH one                                          -> chest luck
		  * it was stamped onto pack rows as row.luck, which
		    later siphons that pack's card odds                -> pack luck

		`luck` KEEPS all three, as the shared base, so every existing source --
		prestige, VIP, the event pass, skills, runes, the Umbra gear set -- goes
		on working exactly as it did. These two multiply on top of it for one
		channel each, so a hat can be about ore cases without also being about
		chests. Chest luck needs no new stat: `luck` x `chestLuck` was already
		that channel.
	]]
	oreLuck     = { label = "Ore Luck",         weight = 2.4, unit = "%", desc = "Chance an ore block drops its ORE CASE. Does not touch chests or packs." },
	packLuck    = { label = "Pack Luck",        weight = 2.4, unit = "%", desc = "Siphons a pack's card odds toward the chase when it is opened. Stamped on the pack when you get it." },
	earthquake  = { label = "Earthquake Chance", weight = 2.6, unit = "%", desc = "CHANCE a block starts shaking and bleeds damage every second for 5s. Does not stack; 5 blocks at once." },
	ricochet    = { label = "Ricochet Chance",  weight = 2.4, unit = "%", desc = "CHANCE breaking a block jumps the hit to one block beside it. Once only, and it chains no further." },
	--[[
		PROC DAMAGE, and the only stat that moves it.

		Owner, 2026-10-03: "Just make damage and chance 2 different stats."
		Every proc used to land a FULL swing, so its chance stat bought both
		how often it fired and how hard. Now each proc has a share of a swing
		(MineConfig.PROC_SHARE) and this scales all four together.

		Weighted 3.0 -- above any single proc chance, below Blast's 4.0. It is
		worth more than one chance stat because it multiplies all of them, and
		less than Blast because it does nothing at all on a build with no proc
		chance to scale.
	]]
	procPower   = { label = "Proc Power",       weight = 3.0, unit = "%", desc = "How hard Blast, Zap, Earthquake and Ricochet hit. Does nothing without a proc chance to scale." },
}

MineStats.STAT_ORDER = {
	"mineSpeed", "swingRate", "reach", "blastRadius", "zap",
	"oreYield", "rareOre", "gemFind", "coinBonus",
	"luck", "oreLuck", "chestLuck", "packLuck", "luckyFind", "fossilFind", "pulverize", "scrap",
	"earthquake", "ricochet", "procPower",
	-- backpack and walkSpeed retired 2026-10-04; see their entries above.
	"coolant", "shortFuse", "dirtBreak",
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

--[[
	ECHO IS BARRED AS A BUFF (TODO 6.2), and pays out as Swing Rate.

	A swing that happens twice multiplies every damage source at once, which is
	the build collapse the boost guardrails exist to prevent -- so nothing mints
	it any more: the Void gear set rolls Gem Find, NO_ROLL_STATS blocks it on
	runes, and the Demolition rune set's slot 2 is Short Fuse.

	What it does NOT do is delete it from the fourteen temperament kits that
	carry it, five of which are NAMED for it. Renaming shipped content is the
	owner's call, not a side effect of a balance rule, so echo is RETIRED the
	way autoMine was: converted at a budget-preserving rate wherever it is paid,
	entry kept so old saves still resolve a weight, and out of STAT_ORDER so no
	screen lists it.

	Swing Rate is the honest destination -- "your swing happens twice" and
	"you swing faster" are the same fantasy, and it is the only tempo stat that
	is not itself a damage multiplier. 1.5 points per +1% against Swing Rate's
	1.4, so a kit keeps the budget it was priced with.
]]
MineStats.ECHO_TO_SWING = 1.5 / 1.4

-- Folds BOTH retired stats. The name is kept because every caller uses it and
-- the job is the same: hand back a kit with nothing legacy left in it, so a
-- card prints exactly what the server will pay.
function MineStats.withoutAutoMine(kit)
	if type(kit) ~= "table" then
		return kit
	end
	local auto = tonumber(kit.autoMine) or 0
	local ech = tonumber(kit.echo) or 0
	if auto == 0 and ech == 0 then
		return kit
	end
	local copy = table.clone(kit)
	if auto ~= 0 then
		copy.autoMine = nil
		copy.gemFind = (tonumber(copy.gemFind) or 0) + auto * MineStats.AUTO_MINE_TO_GEM
	end
	if ech ~= 0 then
		copy.echo = nil
		copy.swingRate = (tonumber(copy.swingRate) or 0) + ech * MineStats.ECHO_TO_SWING
	end
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
