-- MineRunes: gem-rolled typed runes, fuse math, socket rules.
-- Balance contract lives here so pets/skills/gear share one language (MineStats %).
local MineStats = require(script.Parent:WaitForChild("MineStats"))

local MineRunes = {}

MineRunes.ROLL_PRICE = 25
--[[
	A gentle climb with the deepest zone owned, and no cliff anywhere in it.

	This has now been all three ways. It started at ROLL_PRICE * 5.2 * 1.4^(z-2)
	-- 25 in Meadow, 130 in Greyvein, ~1,920 in Primordium -- which tracked
	MineZoneChests GEM PACING exactly, since chest gems also climb x1.4 a zone.
	That is what made it feel punishing: a summon cost the same ~9% of a chest at
	every depth and never once got cheaper, and the x5.2 step out of Meadow was a
	wall. Flat was the other extreme: by Primordium one chest bought 843 summons
	and gear stopped being a sink at all.

	1.2^(z-1) is about x5.2 across the whole ten-zone run instead of x77, so
	Primordium still costs more than Meadow but chest income (x188 over the same
	run) outgrows it by a wide margin -- going deeper genuinely buys you rolls.
	Rounded to fives so prices read like prices.
]]
function MineRunes.rollPriceFor(zone)
	local z = math.max(1, math.floor(tonumber(zone) or 1))
	return math.floor(MineRunes.ROLL_PRICE * 1.2 ^ (z - 1) / 5 + 0.5) * 5
end
MineRunes.RESOCKET_PRICE = 10
-- Fusion is exponential on purpose and has no ceiling: each tier is exactly
-- double the last, so T20 is not twice T10, it is orders past it. The gem cost
-- is exponential too (see fuseGemCost, 50 * 3.5^(tier-1)), and it climbs
-- faster than the payout, so anyone standing on a deep rune has genuinely paid
-- for it. There is no cap to remove -- fusing two T5s makes a T6.
MineRunes.MAX_FUSE_LEVEL = 99
MineRunes.GEAR_MAX_FUSE_LEVEL = 99 -- gear can take deep fused runes
MineRunes.HEADROOM_SHARE = 0.30

MineRunes.INITIAL_MAX_PCT = {
	blastRadius = 1.5,
	echo = 2.5,
	zap = 2.0,
	autoMine = 3.0,
	chestLuck = 3.5,
	rareOre = 4.5,
	gemFind = 5.0,
	luck = 5.0,
	swingRate = 5.0,
	walkSpeed = 5.0,
	oreYield = 7.0,
	mineSpeed = 8.0,
	coinBonus = 10.0,
	backpack = 10.0,
	dirtBreak = 10.0,
	fossilFind = 5.0,
	pulverize = 3.0,
	reach = 5.0,
	coolant = 3.0,
	shortFuse = 3.0,
}

MineRunes.WHITE_COST_MULT = 5

--[[
	floor(50 * 3.5^(tier - 1)) on the SHARED tier of the two runes, min 50.

	Charging the tier rather than levelA+levelB matters: tier is what doubles
	the payout, so this is the only exponent that races it. T1 50, T2 175,
	T3 612, T4 2,143, T5 7,502, T6 26,257.
]]
function MineRunes.fuseGemCost(tier, whiteUsed)
	local t = math.max(1, math.floor(tonumber(tier) or 1))
	local base = math.floor(MineRunes.FUSE_BASE_COST
		* (MineRunes.FUSE_COST_GROWTH ^ (t - 1)) + 0.5)
	if whiteUsed then
		base *= MineRunes.WHITE_COST_MULT
	end
	return math.max(MineRunes.FUSE_BASE_COST, base)
end

--[[
	FUSE SUCCESS IS A FLAT, INDEPENDENT 50%.

	Every attempt is its own coin flip. There is deliberately no pity, no soft
	pity, no fail counter, no streak memory, no per-rune stored chance and no
	way to force a win. Ten failures in a row does not improve the eleventh
	attempt, and it must never be made to.

	Do not add any of that back. (Roblox paid-random-item compliance.)
]]
MineRunes.FUSE_SUCCESS = 0.50

-- Gem cost is charged on the runes' shared TIER, not on fuse level, so the
-- brake tracks the thing that actually doubles.
MineRunes.FUSE_BASE_COST = 50
MineRunes.FUSE_COST_GROWTH = 3.5

MineRunes.DROP_TABLE = {
	{ kind = "pet", weight = 40 },
	{ kind = "pickaxe", weight = 22 },
	{ kind = "explosive", weight = 16 },
	{ kind = "drill", weight = 17 },
	-- ranged family was cut from tools; do not roll runes for it
	{ kind = "gear", weight = 5 },
}

-- Lucky Find, Mine Speed, and Scrap never gem-roll.
-- Stick jobs never roll on pet runes.
-- autoMine joins them: the stat was replaced by Gem Find, so rolling one would
-- mint a rune that prints one thing and pays another.
MineRunes.NO_ROLL_STATS = { luckyFind = true, mineSpeed = true, scrap = true, autoMine = true }

MineRunes.FAMILY_STATS = {
	pet = {
		"swingRate", "echo", "zap",
		"oreYield", "rareOre", "gemFind", "coinBonus",
		"luck", "chestLuck", "fossilFind", "pulverize", "backpack", "walkSpeed", "dirtBreak",
	},
	pickaxe = { "reach", "blastRadius", "dirtBreak", "oreYield", "echo", "backpack" },
	explosive = { "shortFuse", "blastRadius", "dirtBreak", "oreYield" },
	drill = { "coolant", "reach", "swingRate", "dirtBreak", "oreYield" },
}

-- Old saves may still hold kind="ranged" runes from before the cut.
function MineRunes.migrateKind(kind)
	if kind == "ranged" then
		return "pickaxe"
	end
	return kind
end

local function clamp(n, a, b)
	return math.max(a, math.min(b, n))
end

local function round4(v)
	return math.floor(v * 10000 + 0.5) / 10000
end

function MineRunes.initialMaxFraction(stat)
	local pct = MineRunes.INITIAL_MAX_PCT[stat]
	if not pct then return 0 end
	return pct / 100
end

--------------------------------------------------------------------------------
-- TIERS
--
-- A rune's roll is no longer a random number inside a band. It has a TIER, and
-- the tier alone decides the percentage: T1 is the floor the old draw could
-- produce, and every tier after it doubles.
--
--   pct(tier) = TIER1_PCT[stat] * 2^(tier - 1)
--
-- T1 -> T5 covers 1x to 16x, and nothing stops it there: fusing two T5s makes
-- a T6, and the doubling continues. Because pct is a pure function of
-- (stat, tier), two runes of the same stat and tier are identical, which is
-- what makes "same tier" a sane fuse requirement and makes the fuse result
-- exactly predictable.
--
-- TIER1_PCT is the source of truth for rune power. INITIAL_MAX_PCT below is
-- kept because MineGear.piecePct scales gear off it -- it is the gear yardstick
-- now, not a rune draw band.
--------------------------------------------------------------------------------
MineRunes.TIER1_PCT = {
	blastRadius = 1.20,
	echo = 2.00,
	zap = 1.60,
	autoMine = 2.50,
	chestLuck = 4.00,
	rareOre = 4.00,
	gemFind = 5.00,
	luck = 5.00,
	swingRate = 6.00,
	-- T5 walk used to cap ~32% and felt dead; T1 10% → T5 160%.
	walkSpeed = 10.00,
	oreYield = 5.00,
	backpack = 8.00,
	coinBonus = 8.00,
	dirtBreak = 8.00,
	fossilFind = 4.00,
	pulverize = 2.50,
	reach = 4.00,
	coolant = 2.00,
	shortFuse = 1.60,
	-- mineSpeed, luckyFind, scrap: pets only, never TIER1.
}

MineRunes.MAX_DROP_TIER = 5
--[[
	Tier odds come off the shared case ladder -- the same F..SSS weights that
	decide a temperament's grade and a gear piece's letter
	(MineTemper.RARITY_WEIGHTS). A rune drop stops at five tiers, so the draw
	uses the first five rungs renormalised: T5 sits on A, and Mythic and above
	stay unreachable on a drop exactly as they always have been.

	This was a hand-written flat 30/25/20/15/10, which made a T5 a 1-in-10 drop
	while an A-grade hat out of the very same crate was 1 in 40. One ladder now,
	so "rare" means the same thing in all three systems.

	Still no luck stat, no pity, no "you are due a good one".
]]
-- Fallback only, used if the shared ladder cannot be read.
MineRunes.TIER_WEIGHTS = { 30, 25, 20, 15, 10 }

function MineRunes.tierWeights()
	-- FindFirstChild, never WaitForChild: a missing module must cost us the
	-- shared ladder, not hang MineRunes and take the game down with it.
	local inst = script.Parent:FindFirstChild("MineTemper")
	if not inst then
		return MineRunes.TIER_WEIGHTS
	end
	local ok, Temper = pcall(require, inst)
	if not ok or type(Temper) ~= "table" or type(Temper.RARITY_WEIGHTS) ~= "table" then
		return MineRunes.TIER_WEIGHTS
	end
	local order = Temper.GRADE_ORDER or { "F", "D", "C", "B", "A", "S", "SS", "SSS" }
	local out = {}
	for tier = 1, MineRunes.MAX_DROP_TIER do
		local w = tonumber(Temper.RARITY_WEIGHTS[order[tier]])
		if not w or w <= 0 then
			return MineRunes.TIER_WEIGHTS
		end
		out[tier] = w
	end
	return out
end

function MineRunes.pctForTier(stat, tier)
	local base = MineRunes.TIER1_PCT[stat]
	if not base then
		return 0
	end
	local t = math.max(1, math.floor(tonumber(tier) or 1))
	return round4(base / 100 * (2 ^ (t - 1)))
end

function MineRunes.rollTier(rng)
	rng = rng or Random.new()
	local weights = MineRunes.tierWeights()
	local total = 0
	for _, w in ipairs(weights) do
		total += w
	end
	if total <= 0 then
		return 1
	end
	local r = rng:NextNumber() * total
	local acc = 0
	for tier, w in ipairs(weights) do
		acc += w
		if r <= acc then
			return tier
		end
	end
	return 1
end

-- For saves written before tiers existed: read the tier back out of the stored
-- percentage. Never rewrites pct -- an old rune keeps the exact number it had
-- and simply gains the nearest tier label, rounded DOWN so nobody is promoted
-- into a higher fuse bracket by a migration.
function MineRunes.tierFromPct(stat, pct)
	local base = MineRunes.TIER1_PCT[stat]
	if not base or base <= 0 then
		return 1
	end
	local ratio = ((tonumber(pct) or 0) * 100) / base
	if ratio < 1 then
		return 1
	end
	return math.max(1, math.floor(math.log(ratio, 2)) + 1)
end

-- Fill in anything a rune is missing. Safe to call on every rune on every load.
function MineRunes.normalize(rune)
	if type(rune) ~= "table" then
		return rune
	end
	rune.kind = MineRunes.migrateKind(rune.kind)
	--[[
		An Auto Mine rune becomes the Gem Find rune it was already paying out as.
		The percentage is scaled by the same ratio the boost table uses, so the
		rune is worth exactly what it was worth yesterday -- only now it says so.
	]]
	if rune.stat == "autoMine" then
		rune.stat = "gemFind"
		rune.pct = (tonumber(rune.pct) or 0) * ((MineStats and MineStats.AUTO_MINE_TO_GEM) or (2.5 / 1.8))
		rune.tier = nil
	end
	if not tonumber(rune.tier) then
		rune.tier = MineRunes.tierFromPct(rune.stat, rune.pct)
	end
	rune.tier = math.max(1, math.floor(tonumber(rune.tier) or 1))
	-- Per-rune fuse chances are gone; the flat 50% replaced them.
	rune.nextSuccess = nil
	return rune
end

function MineRunes.tierLabel(rune)
	return "T" .. tostring(math.max(1, math.floor(tonumber(rune and rune.tier) or 1)))
end

function MineRunes.pointsOf(stat, fraction)
	local def = MineStats.STATS[stat]
	if not def then return 0 end
	return (fraction or 0) * 100 * def.weight
end

function MineRunes.rollDropKind(rng)
	rng = rng or Random.new()
	local total = 0
	for _, row in ipairs(MineRunes.DROP_TABLE) do total += row.weight end
	local r = rng:NextNumber() * total
	local acc = 0
	for _, row in ipairs(MineRunes.DROP_TABLE) do
		acc += row.weight
		if r <= acc then return row.kind end
	end
	return "pet"
end

function MineRunes.rollPool(kind)
	local src = MineRunes.FAMILY_STATS[kind] or MineStats.STAT_ORDER
	local pool = {}
	for _, stat in ipairs(src) do
		if not MineRunes.NO_ROLL_STATS[stat] and MineRunes.TIER1_PCT[stat] then
			table.insert(pool, stat)
		end
	end
	return pool
end

function MineRunes.rollStatForKind(kind, rng)
	rng = rng or Random.new()
	local pool = MineRunes.rollPool(kind)
	if #pool == 0 then
		return "mineSpeed"
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- rollPct and rollSuccessChance are gone. A rune's percentage comes from its
-- tier (pctForTier) and its fuse chance is the flat FUSE_SUCCESS, so there is
-- nothing per-rune left to roll. `forceTop` in particular was a way to make a
-- fuse succeed on demand and must not come back.

function MineRunes.newRune(kind, id, rng)
	rng = rng or Random.new()
	kind = MineRunes.migrateKind(kind)
	assert(kind ~= "gear", "use MineGear.rollPiece for gear drops")
	local stat = MineRunes.rollStatForKind(kind, rng)
	local tier = MineRunes.rollTier(rng)
	return {
		id = id, kind = kind, stat = stat, tier = tier,
		pct = MineRunes.pctForTier(stat, tier), level = 0,
	}
end

function MineRunes.describe(rune)
	if not rune then return "Empty" end
	local stat = rune.stat
	local pct = rune.pct or 0
	if stat == "autoMine" then
		stat = "gemFind"
		pct = pct * (MineStats.AUTO_MINE_TO_GEM or (2.5 / 1.8))
	end
	local def = MineStats.STATS[stat]
	local label = def and def.label or stat
	-- Tier is the identity now, so it leads. The fuse chance is not shown per
	-- rune because it is the same flat number for every rune in the game.
	return string.format("%s %s  T%d  +%.2f%%",
		rune.kind, label, math.max(1, math.floor(tonumber(rune.tier) or 1)),
		pct * 100)
end

--[[
	What a fuse would produce.

	Requires the SAME KIND, the SAME TIER and the SAME STAT.

	That is the whole point of tiers: because pct is a pure function of
	(stat, tier), two runes that match on all three are literally the same
	item, so a fuse has exactly one possible outcome -- the next tier of that
	stat -- and the screen can state it without hedging.

	Mixing two different stats used to be allowed and produced a primary stat
	plus a weaker secondary. That is gone: it is what made a fused rune's value
	unpredictable, which is the problem tiers exist to solve. Old runes that
	already carry a secondaryStat keep working (applyRune still reads it); no
	new fuse can create one.

	Success is MineRunes.FUSE_SUCCESS, flat, every time, for everyone.
]]
function MineRunes.fusePreview(a, b)
	if not a or not b then return nil, "Need two runes" end
	if a.kind ~= b.kind then return nil, "Both runes must be the same kind" end
	local tierA = math.max(1, math.floor(tonumber(a.tier) or MineRunes.tierFromPct(a.stat, a.pct)))
	local tierB = math.max(1, math.floor(tonumber(b.tier) or MineRunes.tierFromPct(b.stat, b.pct)))
	if tierA ~= tierB then
		return nil, string.format("Both runes must be the same tier (T%d and T%d)", tierA, tierB)
	end
	local level = math.max(a.level or 0, b.level or 0)
	if level >= MineRunes.MAX_FUSE_LEVEL then return nil, "Already at fuse cap" end
	if a.stat ~= b.stat then
		local da = MineStats.STATS[a.stat]
		local db = MineStats.STATS[b.stat]
		return nil, string.format("Both runes must be the same stat (%s and %s)",
			(da and da.label) or a.stat, (db and db.label) or b.stat)
	end
	local tier = tierA
	local cost = MineRunes.fuseGemCost(tier, (a.whiteUsed or b.whiteUsed) and true or nil)
	local success = MineRunes.FUSE_SUCCESS
	return {
		cost = cost, success = success, kind = a.kind, stat = a.stat,
		tier = tier + 1,
		-- Exactly double. Identical to pctForTier(stat, tier + 1) for any rune
		-- that was itself rolled on the ladder.
		pct = round4((a.pct or 0) * 2),
		level = level + 1, sameStat = true,
	}
end

function MineRunes.canSocketOnTool(rune, _family)
	-- Any rune can ride any tool. Kind is flavour for rolling/fusing, not a socket gate.
	return rune ~= nil
end

function MineRunes.canSocketOnPet(rune)
	-- Any rune goes on a pet, the same as on a tool. Kind is flavour for rolling
	-- and fusing, not a socket gate -- and with only six sockets in the game, a
	-- rune you cannot place is a rune you did not win.
	return rune ~= nil
end

function MineRunes.canSocketOnGear(rune)
	-- Gear sockets take any rune, like tools do. They used to refuse every rune,
	-- which left sockets on gear -- and the amulet, which is ONLY sockets --
	-- worth nothing at all.
	return rune ~= nil
end

function MineRunes.applyFraction(b, stat, pct)
	if not b or not stat or not pct or pct == 0 then return end
	if stat == "echo" then b.echo = (b.echo or 0) + pct
	elseif stat == "zap" then b.zap = (b.zap or 0) + pct
	elseif stat == "oreYield" then b.oreYield = (b.oreYield or 0) + pct
	elseif stat == "luckyFind" then b.luckyFind = (b.luckyFind or 0) + pct
	elseif stat == "fossilFind" then b.fossilFind = (b.fossilFind or 0) + pct
	elseif stat == "pulverize" then b.pulverize = (b.pulverize or 0) + pct
	elseif stat == "scrap" then b.scrap = (b.scrap or 0) + pct
	elseif stat == "coolant" then b.coolant = (b.coolant or 0) + pct
	elseif stat == "shortFuse" then b.shortFuse = (b.shortFuse or 0) + pct
	elseif stat == "reach" then b.reach = (b.reach or 0) + pct
	elseif stat == "blastRadius" then b.blastRadius = (b.blastRadius or 0) + pct
	elseif stat == "autoMine" then
		local extra = pct * (MineStats.AUTO_MINE_TO_GEM or (2.5 / 1.8))
		b.gemFind = (b.gemFind or 1) * (1 + extra)
	elseif stat == "swingRate" then b.swingSec = (b.swingSec or 1) / (1 + pct)
	elseif stat == "coinBonus" or stat == "gemFind" or stat == "chestLuck" then b[stat] = (b[stat] or 1) * (1 + pct)
	else b[stat] = (b[stat] or 1) * (1 + pct) end
end

--[[
	SIX SOCKETS

	A loadout holds six runes and no more: one per pet, one in your hat, one in
	your face, one in your tool. Gear used to carry up to five sockets on a
	single head piece, so a rune was a rounding error you owned twenty of.

	A socketed rune is therefore worth more in two directions at once:

	  SOCKET_GAIN  its own stat lands harder (the specific half)
	  WEAR_BROAD   and it lifts EVERYTHING its wearer gives (the broad half)

	The broad half is applied by whoever owns the stacking order -- pets get it
	through MineGear.stackPets -- because a multiplier on the wearer is not a
	stat and cannot be poured into the shared boost table.
]]
MineRunes.SOCKET_GAIN = 1.5
MineRunes.WEAR_BROAD = 0.45

function MineRunes.wearBroad(rune)
	if type(rune) ~= "table" then
		return 0
	end
	return (tonumber(rune.pct) or 0) * MineRunes.WEAR_BROAD
end

function MineRunes.applyRune(b, rune, gain)
	if not rune then return end
	gain = tonumber(gain) or 1
	if MineStats.PET_ONLY and MineStats.PET_ONLY[rune.stat] then return end
	MineRunes.applyFraction(b, rune.stat, (rune.pct or 0) * gain)
	if rune.secondaryStat and rune.secondaryPct then
		if not (MineStats.PET_ONLY and MineStats.PET_ONLY[rune.secondaryStat]) then
			MineRunes.applyFraction(b, rune.secondaryStat, rune.secondaryPct * gain)
		end
	end
end

function MineRunes.clampBoosts(b)
	if not b then return b end
	for stat, _ in pairs(MineStats.STATS) do
		if stat == "echo" or stat == "zap" or stat == "autoMine" or stat == "oreYield"
			or stat == "luckyFind" or stat == "fossilFind" or stat == "pulverize"
			or stat == "blastRadius" or stat == "scrap" or stat == "coolant"
			or stat == "shortFuse" or stat == "reach" then
			b[stat] = math.max(0, b[stat] or 0)
		elseif stat == "swingRate" then
			b.swingSec = math.max(0.05, b.swingSec or 1)
		else
			local mult = b[stat]
			if type(mult) == "number" then
				b[stat] = math.max(0.05, mult)
			end
		end
	end
	return b
end

function MineRunes.audit()
	local rows = {}
	for _, stat in ipairs(MineStats.STAT_ORDER) do
		local init = MineRunes.INITIAL_MAX_PCT[stat]
		table.insert(rows, { stat = stat, initial = init, soft = init and init * MineRunes.SOFT_FUSE_MULT or nil, ok = init ~= nil and init <= 10 })
	end
	return rows
end


--------------------------------------------------------------------------------
-- FUSION CEILING
--
-- Fusing same-stat runes used to be `a.pct + b.pct * 0.70`, which compounds by
-- about 1.7x per level and never stops: L8 was x6.6, L10 x17, L12 x47, and the
-- cap is level 99. A rune was worth more than the entire rest of the game.
--
-- The draw is unchanged, so early fuses feel exactly as they did. What changes
-- is that the curve now bends toward a ceiling instead of through it. The
-- ceiling is a multiple of the stat's own opening roll, so the ordering between
-- stats survives: a blast-radius rune stays modest, a backpack rune gets fat.
--------------------------------------------------------------------------------
MineRunes.FUSE_CEILING_MULT = 70

function MineRunes.fuseCeiling(stat)
	return MineRunes.initialMaxFraction(stat) * MineRunes.FUSE_CEILING_MULT
end

-- Diminishing returns that can approach the ceiling but never reach it. Below
-- about a third of the ceiling this is within a few percent of the old sum, so
-- nothing about the early game moves.
function MineRunes.softCap(stat, raw)
	local ceiling = MineRunes.fuseCeiling(stat)
	if ceiling <= 0 then
		return raw
	end
	return ceiling * (1 - math.exp(-(raw or 0) / ceiling))
end

--------------------------------------------------------------------------------
-- SETS
--
-- Seven sets of three. A rune that belongs to a set carries setId and slot;
-- runes rolled the old way carry neither and still work exactly as before.
--
-- Slot 3 is the chase in every set -- one in ten -- so "I need the third one"
-- is the thing you go shopping for, and the crates below let you shop for it.
--------------------------------------------------------------------------------
MineRunes.SET_BONUS_PCT = 0.50
MineRunes.SLOT_WEIGHT = { 60, 30, 10 }

MineRunes.SETS = {
	{ id = "prospector", name = "Prospector's Eye", bonus = "chestLuck",
		slots = { "luck", "chestLuck", "rareOre" } },
	{ id = "quarry", name = "Quarryman", bonus = "mineSpeed",
		slots = { "mineSpeed", "dirtBreak", "swingRate" } },
	{ id = "longhaul", name = "Longhauler", bonus = "backpack",
		slots = { "backpack", "walkSpeed", "oreYield" } },
	{ id = "coinwright", name = "Coinwright", bonus = "coinBonus",
		slots = { "coinBonus", "gemFind", "luck" } },
	{ id = "demolition", name = "Demolition", bonus = "blastRadius",
		slots = { "blastRadius", "echo", "mineSpeed" } },
	{ id = "deepdriver", name = "Deepdriver", bonus = "swingRate",
		slots = { "swingRate", "gemFind", "mineSpeed" } },
	{ id = "lapidary", name = "Lapidary", bonus = "gemFind",
		slots = { "gemFind", "rareOre", "chestLuck" } },
}

MineRunes.SET_BY_ID = {}
for _, s in ipairs(MineRunes.SETS) do
	MineRunes.SET_BY_ID[s.id] = s
end

function MineRunes.set(setId)
	return MineRunes.SET_BY_ID[setId or ""]
end

local function weightedSlot(rng)
	local total = 0
	for _, w in ipairs(MineRunes.SLOT_WEIGHT) do
		total += w
	end
	local r = (rng or Random.new()):NextNumber() * total
	local acc = 0
	for i, w in ipairs(MineRunes.SLOT_WEIGHT) do
		acc += w
		if r <= acc then
			return i
		end
	end
	return 1
end

MineRunes.rollSlot = weightedSlot

--[[
	A set rune. `kind` still decides which tool it can socket into; the set only
	decides the stat and the badge, so a set rune is not a second kind of item
	to plumb through everything that already handles runes.
]]
function MineRunes.newSetRune(setId, slot, kind, id, rng)
	rng = rng or Random.new()
	local set = MineRunes.set(setId)
	if not set then
		return MineRunes.newRune(kind or "pet", id, rng)
	end
	slot = math.clamp(slot or weightedSlot(rng), 1, #set.slots)
	local stat = set.slots[slot]
	local tier = MineRunes.rollTier(rng)
	local r = {
		id = id,
		kind = MineRunes.migrateKind(kind or "pet"),
		stat = stat,
		tier = tier,
		pct = MineRunes.pctForTier(stat, tier),
		level = 0,
		setId = set.id,
		slot = slot,
	}
	return r
end

--[[
	Which sets a list of SOCKETED runes completes. Returns a map of
	setId -> { have = n, need = 3, complete = bool }, counting distinct slots so
	three copies of slot 1 is not a set.
]]
function MineRunes.setProgress(socketed)
	local out = {}
	for _, r in ipairs(socketed or {}) do
		if type(r) == "table" and r.setId and r.slot then
			local set = MineRunes.set(r.setId)
			if set then
				local row = out[r.setId]
				if not row then
					row = { have = 0, need = #set.slots, complete = false, slots = {} }
					out[r.setId] = row
				end
				local slot = r.slot == "autoMine" and "gemFind" or r.slot
				if not row.slots[slot] then
					row.slots[slot] = true
					row.have += 1
				end
			end
		end
	end
	for id, row in pairs(out) do
		row.complete = row.have >= row.need
	end
	return out
end

--[[
	Apply the completion bonus for every set the player is wearing in full.
	Only the set's own bonus stat moves -- a full Longhauler makes you carry
	more, it does not make you swing faster.
]]
function MineRunes.applySetBonuses(b, socketed)
	local progress = MineRunes.setProgress(socketed)
	local applied = {}
	for setId, row in pairs(progress) do
		if row.complete then
			local set = MineRunes.set(setId)
			if set and set.bonus then
				MineRunes.applyFraction(b, set.bonus, MineRunes.SET_BONUS_PCT)
				table.insert(applied, setId)
			end
		end
	end
	return applied
end

--------------------------------------------------------------------------------
-- POUCHES and CRATES
--
-- A pouch is a blind pull from every set. A crate is aimed at one set, costs a
-- lot more, and is how you finish the set you are three-quarters of the way
-- through. Tier gaps are deliberately an order of magnitude: the point of tier 3
-- is that it is a decision, not a habit.
--
-- Both beat fusing gem-for-gem on raw stat gained, which is the intent -- fusion
-- buys you LEVEL, and level is the thing pouches cannot give you.
--------------------------------------------------------------------------------
MineRunes.POUCHES = {
	{ tier = 1, id = "pouch1", name = "Rune Case", gems = 300, runes = 1,
		guaranteedSlot = nil, scrollChance = { white = 0.10 } },
	{ tier = 2, id = "pouch2", name = "Heavy Rune Case", gems = 3000, runes = 3,
		guaranteedSlot = nil, scrolls = { white = 1 }, scrollChance = { black = 0.25 } },
	{ tier = 3, id = "pouch3", name = "Sealed Rune Case", gems = 30000, runes = 6,
		guaranteedSlot = 3, scrolls = { white = 2, black = 1 }, scrollChance = { omni = 0.15 } },
}

MineRunes.CRATES = {
	{ tier = 1, id = "crate1", name = "Set Crate", gems = 1200, runes = 1, guaranteedSlot = nil },
	{ tier = 2, id = "crate2", name = "Banded Set Crate", gems = 9000, runes = 3,
		guaranteedSlot = nil, scrolls = { white = 1 } },
	{ tier = 3, id = "crate3", name = "Vaulted Set Crate", gems = 60000, runes = 4,
		guaranteedSlot = 3, scrolls = { white = 2, black = 1, omni = 1 } },
}

local function findTier(list, tier)
	for _, row in ipairs(list) do
		if row.tier == tier or row.id == tier then
			return row
		end
	end
	return nil
end

function MineRunes.pouch(tier)
	return findTier(MineRunes.POUCHES, tier)
end

function MineRunes.crate(tier)
	return findTier(MineRunes.CRATES, tier)
end

--[[
	Open one. `setId` is nil for a pouch (any set) and required for a crate.
	`mintId` is a function returning a fresh 16-hex instance id, so this module
	stays out of the business of generating them.
]]
function MineRunes.openBox(spec, setId, mintId, rng)
	rng = rng or Random.new()
	local out = { runes = {}, scrolls = { white = 0, black = 0, omni = 0 } }
	if not spec then
		return out
	end
	for i = 1, (spec.runes or 1) do
		local sid = setId
		if not sid then
			sid = MineRunes.SETS[rng:NextInteger(1, #MineRunes.SETS)].id
		end
		-- The guarantee lands on the last pull, so the box builds to it.
		local slot = nil
		if spec.guaranteedSlot and i == spec.runes then
			slot = spec.guaranteedSlot
		end
		local kind = MineRunes.rollDropKind(rng)
		if kind == "gear" then
			kind = "pet"
		end
		table.insert(out.runes, MineRunes.newSetRune(sid, slot, kind, mintId(), rng))
	end
	for id, n in pairs(spec.scrolls or {}) do
		out.scrolls[id] = (out.scrolls[id] or 0) + n
	end
	for id, chance in pairs(spec.scrollChance or {}) do
		if rng:NextNumber() < chance then
			out.scrolls[id] = (out.scrolls[id] or 0) + 1
		end
	end
	return out
end

-- What the Scrapper pays for a rune. Level is worth more than roll, because
-- level is the part you cannot buy back out of a pouch.
function MineRunes.scrapGems(rune)
	if type(rune) ~= "table" then
		return 0
	end
	local base = 12 + 10 * (rune.level or 0)
	return math.max(1, math.floor(base * (1 + (rune.pct or 0)) * MineRunes.SCRAP_RATE + 0.5))
end

-- About a third of the 25-gem rune banner, the same share gear scraps at. Rune
-- packs pay up to six runes for credits; scrap should not be the reason to buy.
MineRunes.SCRAP_RATE = 0.6

--------------------------------------------------------------------------------
-- WHAT IS ALREADY IN SOMETHING
--
-- This mirrors MineServer.runeBusy, and it lives here so there is ONE definition
-- for every screen that lists runes. Each view having its own copy is how the
-- sockets tray ended up offering runes the server then refused -- it had missed
-- chest and fossil tools.
--
-- Takes a snapshot (or a profile: the field names are the same).
--------------------------------------------------------------------------------
function MineRunes.socketedIds(snap)
	local used = {}
	if type(snap) ~= "table" then
		return used
	end
	for _, g in ipairs(snap.gear or {}) do
		for _, id in pairs(g.sockets or {}) do
			used[id] = true
		end
	end
	for _, sock in pairs(snap.toolSockets or {}) do
		if type(sock) == "string" then
			used[sock] = true
		elseif type(sock) == "table" then
			if sock.main then used[sock.main] = true end
			if sock.omni then used[sock.omni] = true end
		end
	end
	for _, id in pairs(snap.petSockets or {}) do
		used[id] = true
	end
	for _, ft in pairs(snap.fossilTools or {}) do
		if type(ft) == "table" and ft.runeId then
			used[ft.runeId] = true
		end
	end
	for _, ct in ipairs(snap.chestTools or {}) do
		if type(ct) == "table" and ct.runeId then
			used[ct.runeId] = true
		end
	end
	for _, id in pairs(snap.shopToolRunes or {}) do
		used[id] = true
	end
	return used
end

-- The runes you can still do something with. A socketed rune cannot be fused,
-- scrapped or socketed again, so it has no business in a list of runes you are
-- choosing from.
function MineRunes.looseRunes(snap)
	local used = MineRunes.socketedIds(snap)
	local out = {}
	for _, r in ipairs((snap and snap.runes) or {}) do
		if not used[r.id] then
			table.insert(out, r)
		end
	end
	return out
end
return MineRunes
