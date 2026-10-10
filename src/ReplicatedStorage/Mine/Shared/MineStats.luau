-- MineStats: what a stat is worth.
--
-- Every stat carries a weight in points per +1%, so "is this worth the same as
-- that?" has a numeric answer. Runes, gear, traits, the skill tree and the pet
-- kits (tools/gen/zone-pets.js -> MineZonePets) all price with these weights.
--
-- The old pet-kit generator that lived here (TYPE_KITS, TIER_BUDGET, the X / Y
-- SET_PROFILE, kitFor, audit) was removed on 2026-10-10: nothing called it, and
-- pet kits now come from the approved ladder in MineZonePets.
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
		traits, gear, runes -- divides by this weight, so at 6.0 they were
		all handing out roughly THREE TIMES the power they thought they were.

		18.0 is 6.0 x 3: the derivative of r^3 at the margin. One number, and
		the tree, the enchanter and the gear roller all correct together.

		Fire is the wedge that felt it, because blastRadius is its primary and
		nine nodes grant it -- and it got worse the moment the missing
		sk.blastRadius line was restored and those nodes started paying at all.
	]]
	blastRadius = { label = "Blast Radius",  weight = 18.0, unit = "%", desc = "Tool pattern size. A sphere, so +50% radius is ~3.4x the blocks." },
	blastChance    = { label = "Blast Chance",  weight = 4.0, unit = "%", desc = "CHANCE the aimed block's death also hits 6 neighbours. How hard it hits is Proc Power. Chests stay centre-only." },
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
	--[[
		ORE HAUL -- the one stat that multiplies ore OUT OF A BLOCK.

		Owner, 2026-10-06: "REMEMBER ESPICALLY ENDGAME ENCHANTS BUFF THAT SO KEEP
		IT HIGH". Measured in docs/ore-yield-and-vein-balance.md: nothing did.
		The drop was math.random(lo, hi) straight off oreYieldFor with no boost,
		enchant, luck or finder applied anywhere, so an Exotic tool cost ~12
		MILLION blocks broken and no gear could move that number.

		A NEW KEY, NOT fossilFind, deliberately. fossilFind is already spent
		twice: it is the `rareOre` shift inside oreWeights, which decides WHICH
		ore a block becomes, and it multiplies what a legacy pack pays. Hanging
		quantity on it a third time would mean one stat silently doing quality
		and quantity at once -- which is exactly what the comment at the drop
		site refuses, and it is right to.

		So Ore Finder stays a QUALITY stat (better ore), and Ore Haul is the
		QUANTITY one (more of it). Two stats, two jobs, both legible on a
		tooltip.

		Weighted 1.0 rather than near zap's 2.5: it multiplies a payout that
		already happens on every ore block, which is the shape of thing that
		compounds hardest. The cap in MineConfig.ORE_HAUL_CAP is what actually
		holds it; the weight only prices it on a roll.
	]]
	oreHaul     = { label = "Ore Haul",         weight = 1.0, unit = "%", desc = "Multiplies how much ore a block drops. Does not change which ore you get." },
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
	"blastChance", "rareOre", "gemFind", "coinBonus",
	"luck", "oreLuck", "chestLuck", "packLuck", "luckyFind", "fossilFind", "oreHaul", "pulverize", "scrap",
	"earthquake", "ricochet", "procPower",
	-- backpack and walkSpeed retired 2026-10-04; see their entries above.
	"coolant", "shortFuse", "dirtBreak",
}

--[[
	RENAMED KEYS, and how a save written before the rename still reads.

	`oreYield` -> `blastChance`, 2026-10-04. Owner: "rename it". The key was
	named for ore QUANTITY and had meant blast CHANCE for a long time, so every
	reader had to know that. 403 occurrences moved.

	NOT renamed: MineConfig.oreYieldFor, which really is the ore-quantity band
	table. Two different things finally have two different names.

	A stat key is stored on a saved rune (`rune.stat`) and on a saved gear piece
	(`piece.stat`, and every row of `piece.stats`), so those are migrated
	through MineStats.canonStat in their normalize() functions on load. Anything
	else holding one is a static definition and was renamed with the code.
]]
MineStats.LEGACY_STAT = {
	oreYield = "blastChance",
}

function MineStats.canonStat(stat)
	if type(stat) ~= "string" then
		return stat
	end
	return MineStats.LEGACY_STAT[stat] or stat
end

MineStats.RUNE_ONLY = {
	blastRadius = true, reach = true, coolant = true, shortFuse = true,
}

MineStats.PET_ONLY = {
	mineSpeed = true, luckyFind = true, scrap = true,
}

-- What a kit is worth in points (weight x percent). Negative amounts count against it.
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

return MineStats
