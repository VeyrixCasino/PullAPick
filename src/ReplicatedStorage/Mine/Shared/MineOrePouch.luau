--[[
	MineOrePouch -- where ore lives, what it is worth, and what it costs to
	carry more of it.

	THE POUCH IS THE ONE THING THAT SURVIVES A REBIRTH. Coins go, levels go,
	the mine resets; the pouch and everything in it do not. That is the whole
	point of it: it is the bridge across a rebirth, so a run spent deep is not
	erased by the button that makes the next run faster.

	ORE SELLS FOR GEMS. Not coins. Gems buy zones, runes and the pouch's own
	upgrades, so selling ore is the only tap and those three are the sinks. One
	tap, three sinks, all priced in the same currency -- which is the only
	arrangement where a player can reason about whether digging is worth it.

	WHAT IS A DIAL AND WHAT IS NOT
	------------------------------
	Capacity and the gem price of each rung are authored numbers below.

	The gem VALUE of an ore is derived, and its magnitude is a PLACEHOLDER
	pending the owner's figures -- flagged here rather than buried, because the
	balance of this one function decides whether every gem sink in the game is
	reachable or trivial.

	The SHAPE is a decision: value tracks the WORK an ore costs -- the HP of the
	rock it calls home over how many units that rock yields -- so deeper always
	pays better per unit. That part is not a guess.

	The MAGNITUDE is one number, ORE_GEM_SPREAD: how much more the deepest ore is
	worth than the shallowest. 10^6 for now. The exponent that gets there is
	solved from it rather than set by hand, because a hand-set exponent silently
	stopped meaning anything the first time the ore model changed under it.
]]
local MineOrePouch = {}

local C = require(script.Parent:WaitForChild("MineConfig"))

--[[
	THE RUNGS. Capacity is the TOTAL units the pouch holds across every ore, not
	per ore -- a cap per ore would mean the pouch is really 82 pouches and a
	player would never feel it fill.

	CAPACITY is authored. PRICE IS NOT, and that is the important part.

	Priced as a flat table, these rungs were wrong by eight orders of magnitude.
	Gem income rides gemValue, which runs from 6 gems a unit at tier 1 to about
	1.9 billion at tier 82 -- a 3x10^8 spread, because the rock an ore comes out
	of gets 6x harder every zone. Capacity only grows 512x across the same
	ladder. So any fixed price is either unaffordable on rung one or pocket
	change by rung five, and the flat table I first wrote here was both: its top
	rung cost 520,000 gems, which a single tier-30 ore unit more than covers.

	Each rung therefore costs a fixed SHARE OF A FULL POUCH, sold at the ore you
	are plausibly mining when you reach it. One dial, RUNG_COST_SHARE, and every
	rung costs the same amount of mining time no matter where the value curve
	ends up. Change ORE_GEM_SPREAD and the prices follow on their own.
]]
MineOrePouch.TIERS = {
	{ cap = 2000, name = "Canvas Pouch" },
	{ cap = 4000, name = "Leather Pouch" },
	{ cap = 8000, name = "Reinforced Pouch" },
	{ cap = 16000, name = "Miner's Satchel" },
	{ cap = 32000, name = "Deep Satchel" },
	{ cap = 64000, name = "Banded Haversack" },
	{ cap = 128000, name = "Rift Haversack" },
	{ cap = 256000, name = "Voidweave Pack" },
	{ cap = 512000, name = "Starbound Pack" },
	{ cap = 1024000, name = "Bottomless Pouch" },
}

MineOrePouch.MAX_TIER = #MineOrePouch.TIERS

-- Three quarters of a full pouch. Under 1 so a rung is always worth less than
-- the capacity it buys; near 1 so it is never an afterthought.
MineOrePouch.RUNG_COST_SHARE = 0.75

--[[
	THE DIAL IS A SPREAD, NOT AN EXPONENT.

	It was an exponent on the work term, and that broke the moment the ore model
	changed underneath it. The exponent was tuned at 0.5 against a roster whose
	depth coordinate plateaued around 21.8, giving a tier-1-to-tier-82 spread of
	about 3x10^8. On the roster that shipped -- where the coordinate runs linearly
	to 32.1 -- the same 0.5 gives 5.9x10^12, four thousand times wider, for a
	number nobody changed.

	So the knob is the thing a person can actually answer: how much more is the
	deepest ore worth than the shallowest? The exponent is solved from it, which
	means the curve holds its shape across any future change to the ore model.

	10^4, SIGNED OFF. docs/PROPOSAL.md §0 line 16, approved by the owner
	2026-10-05 and law under TODO §0.34. It was 10^6, which the comment here
	called a placeholder and OPEN.md recorded as deferred -- that deferral is
	older than the sign-off.

	1e6 did not merely run hot, it ended the gem economy at the top of the
	roster: an Oganesson was worth 5,099,169 gems, so ONE BLOCK of it bought
	the 2,500,000-gem Gem Vault TWICE OVER. That is the real reason every flat
	gem price in the game "gets outrun" -- not that the prices are low, but
	that the faucet above them is unbounded.

	                 tier 1   tier 41     tier 82
	    1e6 (was)         5     2,697   5,099,169
	    1e4 (now)         4       279      42,727

	These are MEASURED off the live modules, not the round numbers the
	proposal estimated (3 / ~300 / 30,000). The proposal's figures were close
	enough to make the decision with and are wrong enough to mislead anyone
	pricing a sink against them, so the measured ones are what is written here.

	At 1e4 the derived sinks read sanely, which is the test: the Gem Vault is
	58 Oganesson, all ten zone portals are 50, a T6 rune fuse is 0.6, and the
	t82 charm merge is 1,142 -- an endgame number that is meant to look like
	one.

	WHAT THIS DID NOT FIX, and it is the open half: the change moved the
	FAUCET down 119x and left the FLOOR PRICES alone. Every flat gem price --
	trait roll 500, pack crate 200, backpack rung 1 at 100, rune re-socket 10,
	rune banner 25 -- was pocket change at 1e6 and is still pocket change at
	1e4. The sinks that track the curve (ore pouch, charm merge) corrected
	themselves; the authored ones cannot and need their own pass.

	The exponent below is SOLVED from this number rather than tuned beside it,
	so the curve keeps its shape -- only its magnitude moves.
]]
MineOrePouch.ORE_GEM_SPREAD = 1e4
-- Scales the whole curve at once without changing its shape. A tier-1 ore is
-- worth about ORE_GEM_BASE gems, and everything else follows from there.
MineOrePouch.ORE_GEM_BASE = 3

--[[
	The exponent that turns the work ratio across the roster into ORE_GEM_SPREAD.

	Solved once and cached: work(top)^k / work(1)^k = spread, so
	k = log(spread) / log(work(top) / work(1)).
]]
function MineOrePouch.gemCompress()
	if MineOrePouch._compress then
		return MineOrePouch._compress
	end
	local ores = C.ORES or {}
	local first, last = ores[1], ores[#ores]
	local k = 0.5
	if first and last then
		local w1 = MineOrePouch.workOf(first)
		local wN = MineOrePouch.workOf(last)
		if w1 > 0 and wN > w1 then
			k = math.log(MineOrePouch.ORE_GEM_SPREAD) / math.log(wN / w1)
		end
	end
	MineOrePouch._compress = k
	return k
end

--[[
	The ore a player is plausibly mining when they reach a rung: the rungs are
	spread evenly across the 82-ore ladder. Rung 1 is tier 1, the top rung is the
	deepest ore, and the rest fall in between.

	This is what ties the price of a rung to the depth it is for. It does not
	have to be exact -- being within a few tiers is the difference between a rung
	costing half a pouch and two pouches, not the difference between affordable
	and absurd.
]]
function MineOrePouch.rungOre(n)
	local t = math.clamp(math.floor(tonumber(n) or 1), 1, #MineOrePouch.TIERS)
	local count = math.max(1, tonumber(C.ORE_COUNT) or 82)
	local span = math.max(1, #MineOrePouch.TIERS - 1)
	local tier = math.clamp(math.floor(1 + (t - 1) / span * (count - 1) + 0.5), 1, count)
	return (C.ORES or {})[tier], tier
end

function MineOrePouch.tier(n)
	local t = math.clamp(math.floor(tonumber(n) or 1), 1, MineOrePouch.MAX_TIER)
	return MineOrePouch.TIERS[t], t
end

-- How much the pouch holds at a tier. Total across every ore.
function MineOrePouch.capacity(n)
	local def = MineOrePouch.tier(n)
	return math.max(1, math.floor(tonumber(def and def.cap) or 1))
end

--[[
	Gems for the step from `n` to `n + 1`. nil at the top rung, so a caller
	cannot charge for a rung that does not exist.

	A share of what the pouch you already have holds, valued at the ore for the
	rung you are leaving. Derived rather than authored -- see THE RUNGS above for
	why a flat number cannot work here.
]]
function MineOrePouch.upgradeCost(n)
	local _, t = MineOrePouch.tier(n)
	if t >= MineOrePouch.MAX_TIER then
		return nil
	end
	local ore = MineOrePouch.rungOre(t)
	local perUnit = MineOrePouch.gemValue(ore)
	local cost = MineOrePouch.capacity(t) * perUnit * MineOrePouch.RUNG_COST_SHARE
	-- Floored, like every price: never quote less than is charged.
	return math.max(1, math.floor(cost))
end

--[[
	What one unit of an ore sells for, in gems. Always at least 1: an ore worth
	nothing is an ore a player resents carrying.

	Floored, like every other currency readout -- a player is never told they
	will get more than they get.
]]
function MineOrePouch.gemValue(ore)
	if type(ore) == "string" then
		ore = C.oreById(ore)
	end
	if type(ore) ~= "table" then
		return 1
	end
	local v = MineOrePouch.ORE_GEM_BASE
		* (MineOrePouch.workOf(ore) ^ MineOrePouch.gemCompress())
	return math.max(1, math.floor(v))
end

--[[
	What one unit of an ore COSTS a player, in rock HP.

	The HP of the home rock over how many units that rock yields. Split out
	because gemValue and gemCompress both need it and neither should re-derive it.

	Yield comes from MineConfig.oreYieldFor, the band table whose bell peaks on
	Epic. NOT from `ore.yield`: the roster rows do not carry one, and
	MineZonePacks would hand back its generic default for every ore,
	which would make all 82 of them cost the same.

	homeHp is 20 * 6^d, derived in MineConfig from the ore's depth coordinate
	with the same 20 and 6 that ORE_DMAX is defined with, so the two cannot
	drift apart.
]]
function MineOrePouch.workOf(ore)
	if type(ore) == "string" then
		ore = C.oreById(ore)
	end
	if type(ore) ~= "table" then
		return 1
	end
	local lo, hi = C.oreYieldFor(ore.tier)
	local yield = math.max(1, ((tonumber(lo) or 1) + (tonumber(hi) or 1)) / 2)
	return math.max(1, (tonumber(ore.homeHp) or 20) / yield)
end

-- What a whole stack is worth. Separate so the UI and the server cannot round
-- differently: both multiply the floored unit value.
function MineOrePouch.stackValue(ore, count)
	local n = math.max(0, math.floor(tonumber(count) or 0))
	if n == 0 then
		return 0
	end
	return MineOrePouch.gemValue(ore) * n
end

-- Everything in the pouch, summed. The number capacity is measured against.
function MineOrePouch.held(ores)
	local total = 0
	for _, n in pairs(ores or {}) do
		total += math.max(0, math.floor(tonumber(n) or 0))
	end
	return total
end

-- Room left. Never negative, so a caller can add it without clamping again.
function MineOrePouch.room(ores, tierN)
	return math.max(0, MineOrePouch.capacity(tierN) - MineOrePouch.held(ores))
end

--[[
	DESCENDING RARITY IS THE DEFAULT SORT, and it is the default because the
	pouch is read top-down when deciding what to sell: the valuable rows are the
	decision and the common ones are noise.

	Ties break on tier and then on name, so the order is stable -- a list that
	reshuffles between frames is unreadable however it is sorted.
]]
MineOrePouch.SORTS = { "rarity", "tier", "amount", "value", "name" }

function MineOrePouch.sortLabel(key)
	if key == "tier" then
		return "Depth"
	elseif key == "amount" then
		return "Amount"
	elseif key == "value" then
		return "Value"
	elseif key == "name" then
		return "Name"
	end
	return "Rarity"
end

--[[
	Rows for the pouch screen, sorted and filtered.

	`ores` is the id -> count map. `opts.sort` is one of SORTS, `opts.band`
	filters to one rarity band, and `opts.hideEmpty` drops rows at zero (on by
	default: a pouch listing all 82 ores, most of them empty, is a wall).
]]
function MineOrePouch.rows(ores, locks, opts)
	opts = opts or {}
	local out = {}
	local hideEmpty = opts.hideEmpty ~= false
	for _, ore in ipairs(C.ORES or {}) do
		local n = math.max(0, math.floor(tonumber((ores or {})[ore.id]) or 0))
		local bandOk = (not opts.band) or opts.band == "" or ore.band == opts.band
		if bandOk and ((not hideEmpty) or n > 0) then
			local unit = MineOrePouch.gemValue(ore)
			table.insert(out, {
				id = ore.id,
				name = ore.name or ore.id,
				tier = tonumber(ore.tier) or 1,
				band = ore.band,
				bandIndex = tonumber(ore.bandIndex) or 1,
				n = n,
				unit = unit,
				value = unit * n,
				locked = (locks or {})[ore.id] and true or false,
			})
		end
	end
	local key = tostring(opts.sort or "rarity")
	table.sort(out, function(a, b)
		if key == "amount" and a.n ~= b.n then
			return a.n > b.n
		elseif key == "value" and a.value ~= b.value then
			return a.value > b.value
		elseif key == "name" and a.name ~= b.name then
			return a.name < b.name
		elseif key == "tier" and a.tier ~= b.tier then
			return a.tier > b.tier
		elseif key == "rarity" and a.bandIndex ~= b.bandIndex then
			return a.bandIndex > b.bandIndex
		end
		-- Stable tail, whatever the primary key was.
		if a.tier ~= b.tier then
			return a.tier > b.tier
		end
		return a.name < b.name
	end)
	return out
end

--[[
	What SELL ALL would take and pay. Reads only -- the server calls this to
	build the confirmation and then again to apply it, so the number a player
	agreed to is the number computed from the same rule.

	A LOCKED ORE IS NEVER SOLD. That is the lock's whole job, and it is why Sell
	All can sit behind one confirmation instead of a prompt per row: the ores a
	player would hate to lose are the ones they locked, and the button cannot
	touch them.
]]
function MineOrePouch.sellAllPlan(ores, locks)
	local gems, units, rows = 0, 0, {}
	for id, raw in pairs(ores or {}) do
		local n = math.max(0, math.floor(tonumber(raw) or 0))
		if n > 0 and not (locks or {})[id] then
			local ore = C.oreById(id)
			local got = MineOrePouch.stackValue(ore, n)
			gems += got
			units += n
			table.insert(rows, { id = id, n = n, gems = got })
		end
	end
	return { gems = gems, units = units, rows = rows }
end

return MineOrePouch
