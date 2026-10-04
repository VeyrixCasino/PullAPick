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
		blurb = "+55% Omni Blast · +90% Scrap", stats = { blastChance = 0.55, scrap = 0.90 } },

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
		blurb = "+75% Omni Blast · +250% Mine Speed", stats = { blastChance = 0.75, mineSpeed = 2.50 } },

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
		blurb = "+55% Omni Blast", stats = { blastChance = 0.55 } },

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
	YOUR FIRST CHARM IS NEVER A ROLL, whichever source it comes from.

	An ore case pays a charm a quarter of the time and a skin the rest
	(MineConfig.ORE_CASE_CHARM_SHARE). For a player who owns none, that is three
	cases in four spent on the half of the build they cannot use yet -- and the
	first charm is the one that teaches what a charm IS.

	So it is guaranteed until you own one, which is the same rule the zone grant
	already applied and the same reason. It lives here rather than in the case
	branch so the two sources cannot drift: one place decides what "your first
	one" means.

	`ownsAny` is whether the player holds any charm at all. Pass the real answer:
	a nil here hands out a free charm to somebody who already has a shelf of them.
]]
function MineCharms.caseCharmShare(ownsAny, share)
	if not ownsAny then
		return 1
	end
	return math.clamp(tonumber(share) or 0.25, 0, 1)
end

-- Does this player hold any charm? One reader, because "do I own one" is asked
-- by both grant paths and a count of zero must not read as ownership.
function MineCharms.ownsAnyCharm(p)
	if type(p) ~= "table" or type(p.charms) ~= "table" then
		return false
	end
	for id, n in pairs(p.charms) do
		-- A legacy `true` counts, and so does any positive tally; a zero left
		-- behind by a removal does not.
		if n == true or (tonumber(n) or 0) > 0 then
			if MineCharms.byId(id) then
				return true
			end
		end
	end
	return false
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
	{ id = "ramp", label = "Ramp", mult = 2.20 },
}

--[[
	THE RAMP. Builds while you keep mining, resets when you stop.

	Stacks come from BREAKING BLOCKS -- the thing a player does constantly -- and
	the payout is the budget times stacks/RAMP_MAX, so a ramp charm pays nothing
	cold and its full 2.20x only once you have been digging a while. It is the
	one shape that rewards a long uninterrupted session rather than a state you
	can set up and then sit in.

	WALL CLOCK, NOT os.clock(). The timestamp is persisted on the profile and
	read back after a rejoin, and os.clock() is process-relative -- the value
	saved by one server means nothing to the next. os.time() is comparable
	across both, so a stale stack correctly reads as expired instead of as
	freshly earned.
]]
MineCharms.RAMP_MAX = 60
MineCharms.RAMP_IDLE_SEC = 12

--[[
	How far up the ramp this player is, 0 to 1. READ ONLY -- it never mutates,
	because applyEquipped calls it and a boost calculation that changes state is
	a boost calculation that behaves differently depending on how often something
	happens to ask for it.

	Expiry is computed rather than stored: more than RAMP_IDLE_SEC since the last
	block and the ramp reads as cold, whether or not anything has got round to
	clearing it.
]]
function MineCharms.rampFraction(p)
	local ramp = type(p) == "table" and p.charmRamp or nil
	if type(ramp) ~= "table" then
		return 0
	end
	local n = math.max(0, math.floor(tonumber(ramp.n) or 0))
	if n <= 0 then
		return 0
	end
	local at = tonumber(ramp.at) or 0
	local now = os.time()
	-- A timestamp in the future is a clock that moved; treat it as cold rather
	-- than as an infinitely fresh stack.
	if at > now or (now - at) > MineCharms.RAMP_IDLE_SEC then
		return 0
	end
	return math.clamp(n / math.max(1, MineCharms.RAMP_MAX), 0, 1)
end

--[[
	One block broken. Call it on every break, equipped ramp charm or not: it is
	two field writes, and keeping the state coherent regardless means swapping
	onto a ramp charm does not inherit a stale ramp from whatever was on before.
]]
function MineCharms.bumpRamp(p)
	if type(p) ~= "table" then
		return
	end
	local now = os.time()
	local ramp = type(p.charmRamp) == "table" and p.charmRamp or nil
	local n = 0
	if ramp then
		local at = tonumber(ramp.at) or 0
		if at <= now and (now - at) <= MineCharms.RAMP_IDLE_SEC then
			n = math.max(0, math.floor(tonumber(ramp.n) or 0))
		end
	end
	p.charmRamp = { n = math.min(MineCharms.RAMP_MAX, n + 1), at = now }
end

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
	scrap = "Scrap", fossilFind = "Ore Finder", blastChance = "Omni Blast",
	luckyFind = "Lucky Find",
}

MineCharms.STAT_LABEL = STAT_LABEL

--[[
	TWO CHARMS PER ORE, 164 in all, and each ore's pair are different KINDS of
	thing rather than a weaker and a stronger copy.

	Variant 1 keeps the id `<ore>_charm` it has always had, so a save holding one
	still resolves. Variant 2 is `<ore>_charm_2`.

	WHY A PAIR AND NOT A LADDER. The two variants of one ore are guaranteed to
	differ in both SHAPE and primary STAT, so neither is an upgrade of the other
	-- picking between Stone Focus and Stone Twin is a question about your build,
	not about which number is larger. If they shared a shape and a stat the second
	would just be the first again at a different size, which is the ladder this
	whole design exists to avoid.

	THE NAME CARRIES THE SHAPE: "<Ore> <Word> Charm", where the word is the shape
	in charm language (Focus, Twin, Pact, Ward, Brink, Surge). Every one of the
	164 names is therefore distinct by construction, and a player can tell what a
	charm DOES from its name before reading the blurb.

	THE INDEXING, which is the whole trick:

	  slot k    = (tier - 1) * 2 + (variant - 1)     0..163, one per charm
	  shape     = k mod 6
	  stat      = (k + k/6) mod 8
	  condition = (k + k/48) mod 4

	Consecutive k differ by one, so an ore's two variants always land on
	different shapes and different stats -- that is where the pair guarantee
	comes from rather than from a check.

	Each divisor term breaks a lockstep. Without `k/6` the (shape, stat) pair
	would cycle every LCM(6,8) = 24; without `k/48` the condition would ride the
	same 48-slot cycle as (shape, stat) and the signature count would sit at 48.
	With both, 86 of the 96 possible (shape, stat, condition) signatures are
	used across the 164 charms -- verified by tools/verify/charms.js.
]]
-- The shape, in charm language. "Stone Condition Charm" reads like a bug report;
-- "Stone Ward Charm" reads like an item.
MineCharms.SHAPE_WORD = {
	focus = "Focus",
	pair = "Twin",
	pact = "Pact",
	condition = "Ward",
	threshold = "Brink",
	ramp = "Surge",
}

MineCharms.ORE_CHARM_VARIANTS = 2

--[[
	The charm id for an ore, by variant. One function, so the server and the UI
	cannot disagree about what an ore's charms are called.

	Variant 1 deliberately has NO suffix: that is the id that already exists in
	saves, and changing it would orphan every charm anyone owns.
]]
function MineCharms.oreCharmId(oreId, variant)
	local v = math.max(1, math.floor(tonumber(variant) or 1))
	local base = tostring(oreId or "") .. "_charm"
	if v <= 1 then
		return base
	end
	return base .. "_" .. v
end

do
	local C = require(script.Parent:WaitForChild("MineConfig"))
	local ores = C.ORES or {}
	local span = math.max(1, (C.ORE_COUNT or #ores) - 1)
	local lo, hi = MineCharms.ORE_CHARM_MIN, MineCharms.ORE_CHARM_MAX
	local shapes = MineCharms.SHAPES
	local variants = MineCharms.ORE_CHARM_VARIANTS
	local function pct(x)
		return math.floor(x * 100 + 1e-9)
	end
	for i, ore in ipairs(ores) do
		local tier = tonumber(ore.tier) or i
		local t = math.clamp((tier - 1) / span, 0, 1)
		for variant = 1, variants do
			-- One slot per charm across the whole roster. See the header.
			local k = (tier - 1) * variants + (variant - 1)
			local shape = shapes[(k % #shapes) + 1]
			local statStep = k + math.floor(k / #shapes)
			local primary = ORE_CHARM_STATS[(statStep % #ORE_CHARM_STATS) + 1]
			-- Budget, floored to a hundredth so the number read is the number
			-- applied. Both variants of an ore share the tier budget; only how
			-- it is SPENT differs.
			local budget = math.floor((lo + (hi - lo) * t) * shape.mult * 100 + 1e-9) / 100

			local stats, blurb, condition = {}, nil, nil

			if shape.id == "pair" then
				-- Six along, not adjacent: neighbours in the pool are
				-- near-synonyms (luck / chestLuck), and pairing those reads as
				-- one stat written twice.
				local second = ORE_CHARM_STATS[((statStep + 5) % #ORE_CHARM_STATS) + 1]
				local a = math.floor(budget * 0.60 * 100 + 1e-9) / 100
				local b2 = math.floor(budget * 0.40 * 100 + 1e-9) / 100
				stats[primary] = a
				stats[second] = b2
				blurb = string.format("+%d%% %s · +%d%% %s",
					pct(a), STAT_LABEL[primary] or primary,
					pct(b2), STAT_LABEL[second] or second)
			elseif shape.id == "pact" then
				local cost = ORE_CHARM_STATS[((statStep + 3) % #ORE_CHARM_STATS) + 1]
				local give = math.floor(budget * 100 + 1e-9) / 100
				--[[
					THE COST IS BOUNDED, and it has to be. It was a fraction of
					the BUDGET, which meant it scaled with the upside: -96% of a
					stat at tier 1 and -308% at tier 82. A multiplicative penalty
					past -100% is not a steep cost, it is a broken number -- the
					stat is gone at -100% and there is nothing left to take.

					A fraction of the STAT instead, -30% at tier 1 to -60% at the
					deepest: the cost still grows with the upside, stays readable,
					and can never erase a stat.
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
				-- A CONDITION takes a moderate window, a THRESHOLD a narrow one.
				-- That is what the threshold's larger budget buys: a window that
				-- is harder to sit inside, not a gate that opens once.
				local pool = (shape.id == "threshold") and THRESHOLDS or CONDITIONS
				-- The /48 term stops the condition riding the same cycle as
				-- (shape, stat); see the header.
				local cond = pool[((k + math.floor(k / 48)) % #pool) + 1]
				condition = cond.id
				stats[primary] = budget
				blurb = string.format("+%d%% %s %s",
					pct(budget), STAT_LABEL[primary] or primary, cond.blurb)
			elseif shape.id == "ramp" then
				-- Authored at FULL value; applyEquipped scales it by how far up
				-- the ramp the player is, so the number on the card is what it
				-- pays at the top rather than an average nobody ever sees.
				stats[primary] = budget
				blurb = string.format("+%d%% %s at full stacks · builds as you mine, resets if you stop",
					pct(budget), STAT_LABEL[primary] or primary)
			else
				stats[primary] = budget
				blurb = string.format("+%d%% %s", pct(budget), STAT_LABEL[primary] or primary)
			end

			local word = MineCharms.SHAPE_WORD[shape.id] or shape.label or "Charm"
			table.insert(LIST, {
				id = MineCharms.oreCharmId(ore.id, variant),
				name = string.format("%s %s Charm", ore.name or ore.id, word),
				source = "ore",
				oreId = ore.id,
				variant = variant,
				tier = tier,
				band = ore.band,
				-- Carried as well as the name so a reader can order or ink by
				-- rarity without a second lookup into the roster.
				bandIndex = ore.bandIndex,
				shape = shape.id,
				shapeLabel = shape.label,
				condition = condition,
				blurb = blurb,
				stats = stats,
			})
		end
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
		-- An ore has SEVERAL charms now, so this is a list per ore rather than a
		-- single entry. Keyed by variant so the order cannot depend on the order
		-- LIST happens to be walked in.
		local key = tostring(def.oreId)
		BY_ORE[key] = BY_ORE[key] or {}
		BY_ORE[key][math.max(1, math.floor(tonumber(def.variant) or 1))] = def
	end
end

function MineCharms.byId(id)
	return BY_ID[tostring(id or "")]
end

--[[
	The charms an ore pays. Every ore has MineCharms.ORE_CHARM_VARIANTS of them,
	and these are the only ways to ask: a caller that builds the id by hand goes
	quietly nil the day the suffix changes.

	`oreCharms` returns the whole list, variant-indexed. `oreCharm(id)` returns
	one -- variant 1 by default, so every existing caller keeps working and keeps
	meaning what it meant.
]]
--[[
	MERGING A CHARM INTO THE NEXT TIER.

	Three copies of an ore charm become one copy of the charm one ore tier
	deeper, same variant. Three because the card merge in the inventory is
	already "MERGE 3 -> UP" and a second merge arithmetic in the same game is a
	thing players have to learn twice.

	IT IS A TRADE, NOT AN UPGRADE, and that is the point rather than a
	compromise. A charm's shape and stat come from `k = (tier-1) * variants +
	(variant-1)` -- shape is `k % 6`, the stat walks a second cycle -- so the
	charm one tier up has a DIFFERENT shape and usually a different stat. You
	are converting duplicates into depth and variety, not into a bigger number.
	That is exactly what TODO 0.13 asks for: "later ones should be better, but
	never because the number is bigger".

	Only ore charms merge. The legacy 31 (zone grant, gem pack, limited) are
	deliberately left out -- §6.0 still has an open owner call on whether they
	are retired at all, and letting them feed a merge ladder would quietly make
	that decision.

	Returns the target id, the target def, and nil plus a reason when it cannot.
	The reason is a player-facing sentence, so the server and any UI say the same
	thing about why a merge is refused.
]]
MineCharms.MERGE_COST = 3

function MineCharms.mergeTarget(charmId)
	local def = MineCharms.byId(charmId)
	if not def then
		return nil, nil, "That charm is not in the game"
	end
	if def.source ~= "ore" then
		return nil, nil, "Only ore charms merge"
	end
	local C = require(script.Parent:WaitForChild("MineConfig"))
	local ores = C.ORES or {}
	local nextTier = (tonumber(def.tier) or 0) + 1
	-- ORES is ordered by tier and tier == index for all 82 rows, but read the
	-- row's own tier rather than trusting that: a roster edit that breaks the
	-- alignment should fail to find a target, not merge into the wrong charm.
	local target
	for i, ore in ipairs(ores) do
		if (tonumber(ore.tier) or i) == nextTier then
			target = ore
			break
		end
	end
	if not target then
		return nil, nil, "This is the deepest charm there is"
	end
	local id = MineCharms.oreCharmId(target.id, def.variant)
	local tdef = MineCharms.byId(id)
	if not tdef then
		return nil, nil, "That charm is not in the game"
	end
	return id, tdef, nil
end

function MineCharms.oreCharms(oreId)
	return BY_ORE[tostring(oreId or "")] or {}
end

function MineCharms.oreCharm(oreId, variant)
	local list = MineCharms.oreCharms(oreId)
	return list[math.max(1, math.floor(tonumber(variant) or 1))]
end

--[[
	One of an ore's charms, picked at random. This is what an ore case rolls.

	Uniform across the variants on purpose: they are different KINDS, not tiers,
	so weighting one would quietly make the other the consolation prize -- which
	is the ladder this design exists to avoid. Falls back to whatever the ore has
	if a variant is somehow missing, so a case can never pay nothing.
]]
function MineCharms.rollOreCharm(oreId, rng)
	local list = MineCharms.oreCharms(oreId)
	local pool = {}
	for _, def in pairs(list) do
		table.insert(pool, def)
	end
	if #pool == 0 then
		return nil
	end
	if #pool == 1 then
		return pool[1]
	end
	rng = rng or Random.new()
	return pool[rng:NextInteger(1, #pool)]
end

function MineCharms.zoneBandCharm(zoneId, band)
	return ZONE_BAND[tostring(zoneId or "") .. "|" .. tostring(band or "")]
end

function MineCharms.packPool()
	return PACK
end

local ADDITIVE = {
	echo = true, zap = true, blastRadius = true, autoMine = true, blastChance = true,
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
	--[[
		A RAMP charm's stats are authored at full value and scaled by how far up
		the ramp the player is. Cold, that is zero, and the charm pays nothing --
		which is the shape working, not a bug.
	]]
	local scale = 1
	if def.shape == "ramp" then
		scale = MineCharms.rampFraction(p)
		if scale <= 0 then
			return
		end
	end
	for stat, amount in pairs(def.stats) do
		amount = (tonumber(amount) or 0) * scale
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
	-- A ramp says where it is, because "builds as you mine" is not an answer to
	-- "what is it giving me right now".
	if def.shape == "ramp" and p ~= nil then
		line = line .. string.format("  ·  %d%% charged",
			math.floor(MineCharms.rampFraction(p) * 100 + 0.5))
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
