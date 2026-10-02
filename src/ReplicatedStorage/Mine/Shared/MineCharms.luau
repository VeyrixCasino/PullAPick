-- MineCharms: one-equip chase identities.
-- Zone grants: every second (odd) island × three depth bands.
-- Pack: 15 gem/Robux pool. Lucky Charm is reserved limited (not in pack).

local MineCharms = {}
-- Numbers follow handoff/launch/CHARMS.md ("one slot = chase": a shallow charm is
-- +100-140%, mid +170-230%, deep +250-320%). A morning retune had cut the five dig
-- charms to +18-90%; the user asked for them back (2026-09-19).

function MineCharms.bandForLayer(layer)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	if layer <= 500 then
		return "shallow"
	elseif layer <= 1500 then
		return "mid"
	end
	return "deep"
end

MineCharms.CHARM_ZONES = {
	meadow = true,
	mistreef = true,
	bloodmoon = true,
	riftmarch = true,
	mythral = true,
}

local LIST = {
	{ id = "sod", name = "Sod Charm", source = "zone", zoneId = "meadow", band = "shallow",
		blurb = "+110% Mine Speed", stats = { mineSpeed = 1.10 } },
	{ id = "rootstride", name = "Rootstride Charm", source = "zone", zoneId = "meadow", band = "mid",
		blurb = "+180% Mine Speed · +60% Backpack", stats = { mineSpeed = 1.80, backpack = 0.60 } },
	{ id = "thornvault", name = "Thornvault Charm", source = "zone", zoneId = "meadow", band = "deep",
		blurb = "+260% Dirt Break · +40% Pulverizer", stats = { dirtBreak = 2.60, pulverize = 0.40 } },

	{ id = "brine", name = "Brine Charm", source = "zone", zoneId = "mistreef", band = "shallow",
		blurb = "+130% Gem Find", stats = { gemFind = 1.30 } },
	{ id = "tideglass", name = "Tideglass Charm", source = "zone", zoneId = "mistreef", band = "mid",
		blurb = "+200% Mine Speed · +40% Swing Rate", stats = { mineSpeed = 2.00, swingRate = 0.40 } },
	{ id = "abyss_latch", name = "Abyss Latch", source = "zone", zoneId = "mistreef", band = "deep",
		blurb = "+55% Omni Blast · +90% Scrap", stats = { oreYield = 0.55, scrap = 0.90 } },

	{ id = "emberseal", name = "Emberseal Charm", source = "zone", zoneId = "bloodmoon", band = "shallow",
		blurb = "+140% Dirt Break", stats = { dirtBreak = 1.40 } },
	{ id = "veilspike", name = "Veilspike Charm", source = "zone", zoneId = "bloodmoon", band = "mid",
		blurb = "+210% Mine Speed · +50% Luck", stats = { mineSpeed = 2.10, luck = 0.50 } },
	{ id = "crimson_crown", name = "Crimson Crown", source = "zone", zoneId = "bloodmoon", band = "deep",
		blurb = "+280% Coin Bonus · +70% Chest Luck", stats = { coinBonus = 2.80, chestLuck = 0.70 } },

	{ id = "fracture_pin", name = "Fracture Pin", source = "zone", zoneId = "riftmarch", band = "shallow",
		blurb = "+140% Mine Speed · +50% Dirt Break", stats = { mineSpeed = 1.40, dirtBreak = 0.50 } },
	{ id = "scarpsign", name = "Scarpsign Charm", source = "zone", zoneId = "riftmarch", band = "mid",
		blurb = "+70% Pulverizer · +80% Fossil Finder", stats = { pulverize = 0.70, fossilFind = 0.80 } },
	{ id = "gatebreaker", name = "Gatebreaker Charm", source = "zone", zoneId = "riftmarch", band = "deep",
		blurb = "+300% Mine Speed · +40% Swing Rate", stats = { mineSpeed = 3.00, swingRate = 0.40 } },

	{ id = "prism_nail", name = "Prism Nail", source = "zone", zoneId = "mythral", band = "shallow",
		blurb = "+120% Luck · +80% Gem Find", stats = { luck = 1.20, gemFind = 0.80 } },
	{ id = "catacomb_key", name = "Catacomb Key", source = "zone", zoneId = "mythral", band = "mid",
		blurb = "+100% Chest Luck · +100% Scrap", stats = { chestLuck = 1.00, scrap = 1.00 } },
	{ id = "aether_seal", name = "Aether Seal", source = "zone", zoneId = "mythral", band = "deep",
		blurb = "+75% Omni Blast · +250% Mine Speed", stats = { oreYield = 0.75, mineSpeed = 2.50 } },

	{ id = "jackhammer", name = "Jackhammer", source = "pack",
		blurb = "+160% Dirt Break · +50% Swing Rate", stats = { dirtBreak = 1.60, swingRate = 0.50 } },
	{ id = "midas_touch", name = "Midas Touch", source = "pack",
		blurb = "+200% Coin Bonus", stats = { coinBonus = 2.00 } },
	{ id = "piggybank", name = "Piggybank", source = "pack",
		blurb = "+170% sell payout", stats = { coinBonus = 1.70 } },
	{ id = "cartwright", name = "Cartwright", source = "pack",
		blurb = "+180% Backpack", stats = { backpack = 1.80 } },
	{ id = "night_shift", name = "Night Shift", source = "pack",
		blurb = "+120% Chest Luck", stats = { chestLuck = 1.20 } },
	{ id = "seer", name = "Seer", source = "pack",
		blurb = "+130% Luck", stats = { luck = 1.30 } },
	{ id = "smelter", name = "Smelter", source = "pack",
		blurb = "+65% Pulverizer", stats = { pulverize = 0.65 } },
	{ id = "prospector", name = "Prospector", source = "pack",
		blurb = "+200% Gem Find", stats = { gemFind = 2.00 } },
	{ id = "spindle", name = "Spindle", source = "pack",
		blurb = "+100% Swing Rate", stats = { swingRate = 1.00 } },
	{ id = "striker", name = "Striker", source = "pack",
		blurb = "+230% Mine Speed", stats = { mineSpeed = 2.30 } },
	{ id = "chainlink", name = "Chainlink", source = "pack",
		blurb = "+60% Zap", stats = { zap = 0.60 } },
	{ id = "yardarm", name = "Yardarm", source = "pack",
		blurb = "+100% Fossil Finder", stats = { fossilFind = 1.00 } },
	{ id = "scrappers_sign", name = "Scrapper's Sign", source = "pack",
		blurb = "+120% Scrap", stats = { scrap = 1.20 } },
	{ id = "cubit_pin", name = "Cubit Pin", source = "pack",
		blurb = "+50% Lucky Find", stats = { luckyFind = 0.50 } },
	{ id = "canopy", name = "Canopy", source = "pack",
		blurb = "+55% Omni Blast", stats = { oreYield = 0.55 } },

	--[[
		Pot of Gold carries EVERY kind of luck.

		It was one stat -- pack luck -- on an item sold as the luck item. Chest
		odds, ore quality, ore quantity, gems and lucky blocks are all separate
		stats and it touched none of them.

		`luck` stays at 2. It is advertised at 200% on a limited item people
		paid for, and dropping it to 1.00 to make the row tidy would be a nerf
		to something already bought. Everything else lands at a full 100%.
	]]
	{ id = "lucky_charm", name = "Pot of Gold", source = "limited",
		blurb = "200% Luck + 100% of every other luck. LIMITED TIME. NEVER COMING BACK.",
		stats = {
			luck = 2,            -- packs / cards
			chestLuck = 1.00,    -- chests
			rareOre = 1.00,      -- ore quality
			fossilFind = 1.00,   -- ore quantity (the ore finder)
			gemFind = 1.00,      -- gems
			luckyFind = 1.00,    -- lucky blocks
		} },
}

--[[
	A ZONE CHARM IS A FIND, NOT A DOOR PRIZE.

	It used to be handed over the first time you broke a block in the right
	band -- a 100% drop in every zone, which made five of the strongest items in
	the game a formality you walked into.

	It is a roll per qualifying block now. The exception is your FIRST charm:
	somebody who owns none gets the next one outright, because the early game is
	built around wearing one (the Sod Charm is most of why the second pickaxe
	one-shots dirt) and a new player should never be gated behind a 1-in-220 on
	their way to it.
]]
-- A roll PER BLOCK. 0.01% flat, set directly by the owner.
-- (1 in 220 before, which was a charm every twenty-odd seconds.)
MineCharms.ZONE_DROP_ONE_IN = 10000

function MineCharms.zoneDropChance(ownsAny)
	if not ownsAny then
		return 1
	end
	return 1 / math.max(1, MineCharms.ZONE_DROP_ONE_IN)
end


--[[
	ONE CHARM PER ORE, ALL 82 -- AND NOT A LADDER OF ONE NUMBER.

	Charms are one of the two things a build is made of (the other is skins), so
	the roster has to cover the roster: every ore that can drop a case needs a
	charm behind it, or a case rolls a charm and finds nothing there.

	They are GENERATED rather than authored. 82 hand-written rows is 82 chances
	to leave one out, and the roster has been renumbered before -- it silently
	mis-pointed the tool ladder once already. Deriving them makes "one per ore" a
	property of the code instead of something to remember.

	WHAT THIS REPLACED, AND WHY
	---------------------------
	The first cut gave every charm one stat and one magnitude, ramped +100% at
	tier 1 to +320% at tier 82. That is the thing a charm must never be: tier 82
	strictly beat tier 41 of the same stat, so there was exactly one best charm
	per stat and 81 obsolete ones. "Higher number, better charm" is not a build.

	Later charms ARE better here -- budget still rises with tier. What changed is
	that budget is no longer always spent the same way, so a charm has a SHAPE as
	well as a size, and a shallow charm of the right shape beats a deep one of
	the wrong shape for a given build.

	THE FIVE SHAPES
	---------------
	Each spends the same tier budget differently. The multiplier on budget is the
	price of reliability -- a charm that asks for a condition, or takes something
	away, is allowed to pay more:

	  FOCUS      1.00x budget, one stat, always on.  The benchmark.
	  PAIR       1.15x split 60/40 over two stats.   Flexible, lower ceiling.
	  PACT       1.75x on one stat, MINUS ~0.55x on  Biggest always-on number
	             another.                            in the game, and it costs.
	  CONDITION  2.00x, but only while a condition    Build-defining when your
	             holds.                               build already holds it.
	  THRESHOLD  2.40x, and NOTHING until a gate is   Dead weight until it is
	             met.                                 not. Then enormous.

	A RAMP shape -- grows while something persists, resets when it breaks -- is
	the obvious sixth and is deliberately absent: it needs a counter on the
	profile and event hooks to feed it, which is plumbing rather than a table.
	See docs/TODO.md.

	WHY CONDITIONS CAN BE READ AT ALL
	---------------------------------
	`boosts(p)` is recomputed on every swing rather than cached, so a condition
	may read live state. Every condition here reads the PROFILE and nothing else,
	which is what keeps this honest: the server owns all of it, there is no new
	plumbing, and the same function serves the UI preview and the live boost.

	One condition, `skinned`, asks whether a skin is equipped. That is on purpose.
	Charms and skins are the two halves of a build, and a charm that pays more
	when the other half is present is the cheapest way to make them feel like
	halves of one thing rather than two parallel stat sources.

	NOT IN ANY POOL: echo (barred as a buff), zap and blastRadius (both pending a
	nerf). A generated table is the last place a stat under review should quietly
	pick up 82 new sources.
]]
-- Multiplicative stats. The budget is expressed as "+N% of what you had", which
-- only means one thing for these; the additive stats are fractions and are
-- handled separately where they appear.
local ORE_CHARM_STATS = {
	"mineSpeed", "dirtBreak", "coinBonus", "gemFind",
	"luck", "chestLuck", "backpack", "swingRate",
}

MineCharms.ORE_CHARM_MIN = 1.00
MineCharms.ORE_CHARM_MAX = 3.20

-- A PACT's cost, as a fraction of the stat it takes from. Bounded well under 1:
-- at -100% the stat is gone, and a cost that can erase a stat is not a trade.
local PACT_COST_MIN = 0.30
local PACT_COST_MAX = 0.60

-- Budget multiplier per shape. See the header for why they differ.
MineCharms.SHAPES = {
	{ id = "focus", label = "Focus", mult = 1.00 },
	{ id = "pair", label = "Pair", mult = 1.15 },
	{ id = "pact", label = "Pact", mult = 1.75 },
	{ id = "condition", label = "Condition", mult = 2.00 },
	{ id = "threshold", label = "Threshold", mult = 2.40 },
}

--[[
	THE CONDITIONS. Each is a pure function of the profile, and each is
	REVOCABLE -- that is the part that took two attempts.

	The first set included "you have dug past 400m in this zone" and "you have
	rebirthed at least once". Both read a high-water mark, so both are PERMANENT
	once passed: a 2.0x or 2.4x budget that never switches off again is not a
	conditional charm, it is a strictly better charm with a sentence attached.
	Progress is what TIER already encodes; a condition has to be something you
	can lose, or it is not paying for the extra budget.

	So every condition below is a state the player moves in and out of while
	playing, and each one costs something real to hold:

	  pouch fullness   tension with selling -- hold the state or bank the haul,
	                   not both
	  pet count        tension with the pet pillar: a seat, or all of them, empty
	  skin / no skin   tension with the other half of the build
	  home zone        tension with where you want to be standing

	A backpack-fullness condition was tried and dropped: `p.backpack` is the
	bag-ownership TABLE, not a capacity, and the real capacity comes from a server
	local the shared module cannot reach. Both pack conditions would have silently
	never fired. Everything above reads state that the profile and the snapshot
	carry identically, which is what lets one function serve the live boost and
	the UI preview.

	CONDITION charms (2.00x) take the moderate windows. THRESHOLD charms (2.40x)
	take the NARROW ones -- a 90% pouch, a single pet, no skin at all -- so the
	larger budget is paid for with a window that is harder to sit inside, rather
	than with a gate that opens once.

	`test` returns true when the charm is paying. `blurb` says what the player has
	to do in the fewest words that are still unambiguous, because a conditional
	charm nobody can read is worse than no charm.
]]
local function pouchFrac(p)
	local okP, Pouch = pcall(function()
		return require(script.Parent:WaitForChild("MineOrePouch"))
	end)
	if not (okP and Pouch) then
		return 0
	end
	local cap = math.max(1, Pouch.capacity(p and p.orePouchTier))
	return math.clamp(Pouch.held(p and p.ores) / cap, 0, 1)
end

--[[
	The zone an ore calls home, by tier, spread evenly across the ladder.

	This is what the `homeZone` condition reads. It is derived rather than
	authored so it cannot fall out of step with the roster, and it only has to be
	approximately right: being a zone out changes which charm suits which trip,
	not whether the game works.
]]
local function homeZoneIndexFor(tier)
	local C = require(script.Parent:WaitForChild("MineConfig"))
	local zones = math.max(1, #(C.ZONES or {}))
	local count = math.max(1, tonumber(C.ORE_COUNT) or 82)
	local t = math.clamp(math.floor(tonumber(tier) or 1), 1, count)
	return math.clamp(math.ceil(t / count * zones), 1, zones)
end

local function wearingSkin(p)
	if type(p) ~= "table" then
		return false
	end
	-- Any of the places a skin can live: the tool family's, a chest tool's, or
	-- the legacy single field.
	for _, t in pairs(p.toolTempers or {}) do
		if t ~= nil and t ~= "" then
			return true
		end
	end
	for _, ct in ipairs(p.chestTools or {}) do
		if type(ct) == "table" and (ct.temperId or (ct.tempers and ct.tempers[1])) then
			return true
		end
	end
	return false
end

-- MODERATE windows, for CONDITION charms.
local CONDITIONS = {
	{
		id = "skinned",
		blurb = "while a SKIN is equipped",
		test = function(p) return wearingSkin(p) end,
	},
	{
		--[[
			Strongest in its own ore's home zone.

			Revocable by walking, which is the point: it makes a charm a reason to
			be somewhere rather than a number you set once. `def` is passed so the
			condition can read the charm's own tier -- it is the only one that
			needs to know which charm is asking.
		]]
		id = "homeZone",
		blurb = "while you are in its ore's home zone",
		test = function(p, def)
			if type(p) ~= "table" or type(def) ~= "table" then
				return false
			end
			local C = require(script.Parent:WaitForChild("MineConfig"))
			local here = C.zoneIndex and C.zoneIndex(p.zoneId) or 1
			return here == homeZoneIndexFor(def.tier)
		end,
	},
	{
		id = "hoard",
		blurb = "while your ore pouch is over half full",
		test = function(p) return pouchFrac(p) > 0.5 end,
	},
	{
		id = "lean",
		blurb = "while you have 2 pets out or fewer",
		test = function(p)
			return type(p) == "table" and #(p.equipped or {}) <= 2
		end,
	},
}

-- NARROW windows, for THRESHOLD charms. Same kinds of state, harder to hold.
local THRESHOLDS = {
	{
		id = "brimming",
		blurb = "while your ore pouch is over 90% full",
		test = function(p) return pouchFrac(p) > 0.9 end,
	},
	{
		-- The whole pet pillar, given up. The narrowest window there is, and the
		-- largest payoff for sitting inside it.
		id = "noPets",
		blurb = "while you have NO pets out",
		test = function(p)
			return type(p) == "table" and #(p.equipped or {}) == 0
		end,
	},
	{
		id = "soloPet",
		blurb = "while exactly ONE pet is out",
		test = function(p)
			return type(p) == "table" and #(p.equipped or {}) == 1
		end,
	},
	{
		id = "bare",
		blurb = "while NO skin is equipped",
		test = function(p) return not wearingSkin(p) end,
	},
}

MineCharms.CONDITIONS = {}
for _, cond in ipairs(CONDITIONS) do
	MineCharms.CONDITIONS[cond.id] = cond
end
for _, cond in ipairs(THRESHOLDS) do
	MineCharms.CONDITIONS[cond.id] = cond
end

-- Is this charm paying right now? True for anything unconditional, so a caller
-- can ask without checking the shape first.
function MineCharms.conditionMet(def, p)
	if type(def) ~= "table" or not def.condition then
		return true
	end
	local cond = MineCharms.CONDITIONS[def.condition]
	if not cond then
		return true
	end
	local ok, res = pcall(cond.test, p, def)
	return ok and res == true
end

local STAT_LABEL = {
	mineSpeed = "Mine Speed", dirtBreak = "Dirt Break", coinBonus = "Coin Bonus",
	gemFind = "Gem Find", luck = "Luck", chestLuck = "Chest Luck",
	backpack = "Backpack", swingRate = "Swing Rate", pulverize = "Pulverizer",
	scrap = "Scrap", fossilFind = "Ore Finder", oreYield = "Omni Blast",
	luckyFind = "Lucky Find",
}

MineCharms.STAT_LABEL = STAT_LABEL

-- The charm id for an ore id. One function, so the server and the UI cannot
-- disagree about what an ore's charm is called.
function MineCharms.oreCharmId(oreId)
	return tostring(oreId or "") .. "_charm"
end

do
	local C = require(script.Parent:WaitForChild("MineConfig"))
	local ores = C.ORES or {}
	local span = math.max(1, (C.ORE_COUNT or #ores) - 1)
	local lo, hi = MineCharms.ORE_CHARM_MIN, MineCharms.ORE_CHARM_MAX
	local shapes = MineCharms.SHAPES
	local function pct(x)
		return math.floor(x * 100 + 1e-9)
	end
	for i, ore in ipairs(ores) do
		local tier = tonumber(ore.tier) or i
		local t = math.clamp((tier - 1) / span, 0, 1)
		--[[
			Shape and stat advance on DIFFERENT strides -- 5 shapes against 8
			stats -- so the pair only repeats every 40 ores. Walking them in step
			would have given every Focus charm the same stat.
		]]
		local shape = shapes[((tier - 1) % #shapes) + 1]
		local primary = ORE_CHARM_STATS[((tier - 1) % #ORE_CHARM_STATS) + 1]
		-- Budget, floored to a hundredth so the number read is the number applied.
		local budget = math.floor((lo + (hi - lo) * t) * shape.mult * 100 + 1e-9) / 100

		local stats, blurb, condition = {}, nil, nil

		if shape.id == "pair" then
			-- The second stat is six along, not adjacent: neighbours in the pool
			-- are near-synonyms (luck / chestLuck), and pairing those reads as one
			-- stat written twice.
			local second = ORE_CHARM_STATS[((tier + 5) % #ORE_CHARM_STATS) + 1]
			local a = math.floor(budget * 0.60 * 100 + 1e-9) / 100
			local b2 = math.floor(budget * 0.40 * 100 + 1e-9) / 100
			stats[primary] = a
			stats[second] = b2
			blurb = string.format("+%d%% %s · +%d%% %s",
				pct(a), STAT_LABEL[primary] or primary,
				pct(b2), STAT_LABEL[second] or second)
		elseif shape.id == "pact" then
			local cost = ORE_CHARM_STATS[((tier + 3) % #ORE_CHARM_STATS) + 1]
			local give = math.floor(budget * 100 + 1e-9) / 100
			--[[
				THE COST IS BOUNDED, and it has to be.

				It was a fraction of the BUDGET, which meant it scaled with the
				upside: -96% of a stat at tier 1 and -308% at tier 82. A
				multiplicative penalty past -100% is not a steep cost, it is a
				broken number -- the stat is gone at -100% and nothing is left to
				take after that.

				It is a fraction of the STAT instead, from -30% at tier 1 to -60%
				at the deepest. So the cost still grows as the upside does, stays
				a number a player can read, and can never erase a stat outright.
			]]
			local take = math.min(PACT_COST_MAX,
				PACT_COST_MIN + (PACT_COST_MAX - PACT_COST_MIN) * t)
			take = math.floor(take * 100 + 1e-9) / 100
			stats[primary] = give
			stats[cost] = -take
			blurb = string.format("+%d%% %s · −%d%% %s",
				pct(give), STAT_LABEL[primary] or primary,
				pct(take), STAT_LABEL[cost] or cost)
		elseif shape.id == "condition" or shape.id == "threshold" then
			-- A CONDITION takes a moderate window, a THRESHOLD a narrow one. That
			-- is what the threshold's larger budget buys: a window that is harder
			-- to sit inside, rather than a gate that opens once and stays open.
			local pool = (shape.id == "threshold") and THRESHOLDS or CONDITIONS
			local cond = pool[((tier - 1) % #pool) + 1]
			condition = cond.id
			stats[primary] = budget
			blurb = string.format("+%d%% %s %s",
				pct(budget), STAT_LABEL[primary] or primary, cond.blurb)
		else
			stats[primary] = budget
			blurb = string.format("+%d%% %s", pct(budget), STAT_LABEL[primary] or primary)
		end

		table.insert(LIST, {
			id = MineCharms.oreCharmId(ore.id),
			name = (ore.name or ore.id) .. " Charm",
			source = "ore",
			oreId = ore.id,
			tier = tier,
			band = ore.band,
			shape = shape.id,
			shapeLabel = shape.label,
			condition = condition,
			blurb = blurb,
			stats = stats,
		})
	end
end

MineCharms.LIST = LIST
MineCharms.PACK_PRICE_GEMS = 2500

local BY_ID = {}
local ZONE_BAND = {}
local PACK = {}
local BY_ORE = {}
for _, def in ipairs(LIST) do
	BY_ID[def.id] = def
	if def.source == "zone" and def.zoneId and def.band then
		ZONE_BAND[def.zoneId .. "|" .. def.band] = def
	elseif def.source == "pack" then
		table.insert(PACK, def)
	elseif def.source == "ore" and def.oreId then
		BY_ORE[tostring(def.oreId)] = def
	end
end

function MineCharms.byId(id)
	return BY_ID[tostring(id or "")]
end

--[[
	The charm an ore pays, by ore id.

	Every ore has one, and this is the only way to ask for it: a caller that
	builds the id by hand would go quietly nil the day the suffix changes.
]]
function MineCharms.oreCharm(oreId)
	return BY_ORE[tostring(oreId or "")]
end

function MineCharms.zoneBandCharm(zoneId, band)
	return ZONE_BAND[tostring(zoneId or "") .. "|" .. tostring(band or "")]
end

function MineCharms.packPool()
	return PACK
end

local ADDITIVE = {
	echo = true, zap = true, blastRadius = true, autoMine = true, oreYield = true,
	luckyFind = true, fossilFind = true, pulverize = true, scrap = true,
	coolant = true, shortFuse = true, reach = true,
}

--[[
	Apply the equipped charm.

	`p` is the profile, and it is what makes a CONDITION charm possible: the
	condition is a pure function of the profile, and boosts() is recomputed every
	swing rather than cached, so the charm turns on and off live. Passing no
	profile applies only the unconditional charms -- which is the right answer for
	a caller that has no player, and never silently grants a conditional bonus.

	A NEGATIVE amount is a real reduction, not a floor at zero. That is the whole
	point of a PACT charm: the biggest always-on number in the game, paid for with
	something. Clamping it away here would make pacts free, so the clamp is only
	the one that keeps a multiplicative stat from going negative outright
	(0.05 floor) -- a stat at or below zero stops being a multiplier and starts
	being a bug.
]]
function MineCharms.applyEquipped(b, charmId, p)
	local def = MineCharms.byId(charmId)
	if not def or not b or type(def.stats) ~= "table" then
		return
	end
	-- A conditional charm pays nothing while its condition is unmet.
	if def.condition and not MineCharms.conditionMet(def, p) then
		return
	end
	for stat, amount in pairs(def.stats) do
		amount = tonumber(amount) or 0
		if amount == 0 then
			-- skip
		elseif stat == "swingRate" then
			-- A negative here LENGTHENS the swing, which is the intended cost.
			b.swingSec = (b.swingSec or 1) / math.max(0.05, 1 + amount)
		elseif ADDITIVE[stat] then
			b[stat] = math.max(0, (b[stat] or 0) + amount)
		else
			b[stat] = math.max(0.05, (b[stat] or 1) + amount)
		end
	end
end

--[[
	The charm's line, with its shape and whether it is live.

	`p` is optional. With it, a conditional charm says whether it is paying right
	now, because "+240% Mine Speed while a SKIN is equipped" and the same charm
	doing nothing look identical otherwise, and that is the single most confusing
	thing a conditional bonus can do.
]]
function MineCharms.describe(def, p)
	if not def then
		return ""
	end
	local line = def.blurb or def.name or ""
	if def.shapeLabel then
		line = line .. "  ·  " .. def.shapeLabel
	end
	if def.condition and p ~= nil then
		line = line .. (MineCharms.conditionMet(def, p) and "  ·  ACTIVE" or "  ·  inactive")
	end
	return line
end

function MineCharms.rollPack(ownedSet, rng)
	rng = rng or Random.new()
	local pool = {}
	for _, def in ipairs(PACK) do
		if not (ownedSet and ownedSet[def.id]) then
			table.insert(pool, def)
		end
	end
	if #pool == 0 then
		return nil
	end
	return pool[rng:NextInteger(1, #pool)]
end

return MineCharms
