--[[
	BREAKING POWER. A wall, not a stat.

	Two numbers that have nothing to do with each other:

	  * DAMAGE decides how FAST a block dies.
	  * BREAKING POWER decides WHETHER it can be damaged at all.

	If blockStrength > tool.breakingPower the tool does ZERO damage. Not reduced
	-- zero. A tool with 1,000 damage cannot scratch a block one point of
	strength above it. That is the point: progression cannot be ground past.

	BREAKING POWER IS NOT UPGRADEABLE. Only damage is. Breaking power is a
	property of the ore a tool was forged from, so the only way past a wall is
	to go and make a better tool.

	WHY THIS SHAPE, when every previous gate in this game failed.

	Every earlier attempt gated with a MULTIPLICATIVE term on an axis nothing
	else gated, which is how a Meadow player ended up out-damaging their zone's
	best shop tool by 561x. Multiplicative terms compound. A wall cannot: it is
	a step gate on a bounded ladder, so the worst case is that a player is
	stopped, never that they run away.

	It also takes the gating job off ore RARITY. Rarity was carrying it badly --
	ORE_DMAX is calibrated to an HP curve that no longer exists -- and rarity is
	a terrible gate anyway, because it is pure luck and therefore feels unearned
	however long it took. A wall is legible: you can see exactly what you need.

	THE LADDER, and why it closes rather than loops.

	    toolBreakingPower(made from ore of tier T) == oreStrength(T)

	So a tool forged from ore X can break anything ore X is found in. Reaching
	tier T ore requires a tool of tier >= T's strength, which requires having
	already found tier T-ish ore. Each rung needs the one below it, so it is a
	ladder. It is NOT the ore-tool bootstrap loop that broke this game before,
	because that loop had the reward raising the RATE at which it was acquired;
	this only ever unlocks the next step, and never speeds up the current one.
]]

local MineBreaking = {}

-- One rung per this many layers. Halved from 100: depth eats rungs twice as
-- fast, so any given tool reaches half as deep as it used to.
MineBreaking.LAYERS_PER_RUNG = 50

--[[
	ORE STRENGTH IS A POWER CURVE, NOT A LINE.

	Linear mapping made a tier-10 tool reach layer 1,300, which is absurd -- a
	tenth of the way up the roster should not open an eighth of the mine. The
	curve puts the payoff at the top: the first half of the roster barely moves
	the wall, and the last quarter carries almost all of it.

	A POWER curve on a BOUNDED index, deliberately, not a true exponential.
	The standing instruction here is "never use exponents again", and it is
	right: base^tier would make tier 82 astronomically strong and every tier
	below it worthless, which is the same mistake as the 500x ore-power spread
	that stopped builds mattering. tier is bounded at 82, so t^POW cannot run
	away, and the shape is what was actually wanted.

	POW is the single dial. Raise it to make low tiers weaker still.

	1.0, DOWN FROM 2.0, alongside the ZONE_STEP change below.

	Quadratic made the bottom half of the roster worth almost nothing: tier 20
	landed at 13 of a 209 scale, so the first seventeen ores could not clear even
	the opening 500 layers and the whole gate was carried by the top third.

	Linear spreads 82 tiers evenly across the scale, which is what makes "about
	seven tiers per zone" FALL OUT of 82 tiers over 11 zones instead of having to
	be tuned in. With ZONE_STEP at 100 the two together give a ladder where
	finishing a zone and entering the next are the same tier, at every boundary.

	Raising it again re-weights the gate toward the top of the roster and will
	re-break that continuity -- tools/zone-gate-fix.js models both dials and
	prints the boundary table.
]]
MineBreaking.ORE_POW = 1.0

--[[
	ZONE COSTS A RUNG. Anchored on one requirement: a Stone pickaxe must be
	completely unusable by zone 3.

	Stone is BP 2, so zone 3's surface must need at least 3 while zone 2's still
	needs at most 2. That pins the step to exactly 1 -- there is no other
	integer that satisfies both.

	The consequence is deliberate and worth stating: entering a zone now needs
	a TOOL, not just the coins for it. Zone purchase stops being a pure coin
	gate. That is the point -- it stops a player buying their way sideways past
	the forge -- but it does mean zone price and tool progression have to stay
	in step, or someone owns a zone they cannot swing in.
]]
--[[
	ORE REACH. Owner's rule: "A tool forged from ore tier T reaches T + 15
	tiers of ore."

	This lived only in MineConfig (ORE_REACH, canBreakOre, oreReachCap), which
	is what the Forge UI reads -- so the UI promised +15 and the live gate below
	gave +0, because blockStrength asked oreStrength for the ore's OWN tier.
	Wired into the gate 2026-10-05.

	It is duplicated from MineConfig.ORE_REACH rather than required, because
	this module has no requires and is pure arithmetic on its own dials. The
	two are asserted equal by tools/verify/breaking.js -- if you change one,
	that check fails until you change the other.
]]
MineBreaking.ORE_REACH = 15

--[[
	ZONE_STEP: 100, UP FROM 1.

	Owner, 2026-10-05: "breaking power should make you need to get a new pick
	from next zone to come back to 501-1000 depth, and so on".

	At 1 the zone was not a gate at all. A full 5000-layer mine is worth +99
	rungs (one per LAYERS_PER_RUNG), so stepping to the next zone cost ONE rung
	while MineDepth multiplied block HP by ZONE_HP_MULT = 5. Measured end to end
	(tools/depth-gate.js): at layer 2500, zone 1 demanded ore tier 41 and zone 11
	demanded tier 44 -- three tiers for 9.77 MILLION times the HP. Clear layer
	2500 in the first mine and you could BREAK layer 2500 in Event Horizon.

	It also ate the roster. Reaching the bottom of zone 1 needed tier 57 of 82 --
	an ore whose own home is zone 8 -- leaving zones 2 through 11 to share three
	tiers between them. One zone spent 70% of the ladder and ten zones spent
	almost none.

	100 is LAYERS / LAYERS_PER_RUNG: a zone is now worth exactly one mine's
	depth. Finishing a zone and entering the next then cost the same, so the
	ladder is continuous instead of front-loaded -- finish zone N at tier X and
	enter zone N+1 at tier X, at all ten boundaries, about seven tiers a zone.

	Event Horizon is outside ZONES (which counts the ten normal mines) and lands
	on top of it: MAX is 1 + 9*100 + 199 = 1100, and zone 11's floor computes to
	1 + 10*100 + 99 = 1100 exactly. The deepest block in the game demands the top
	ore, by construction rather than by tuning.
]]
MineBreaking.ZONE_STEP = 100

--[[
	WHICH ZONE_STEP, AND THE TENSION IN IT.

	The owner's two statements on this do not agree, and the disagreement is
	worth recording rather than silently resolving:

	  to another agent: "unlocking zone 3 is like zone 1 3 down (1000), zone 2
	  1 down (500) ... zone 10 would be 9 down" -- that is ZONE_STEP 10, a zone
	  worth 500 layers.

	  to this one: "breaking power should make you need to get a new pick from
	  next zone to come back to 501-1000 depth, and so on" -- read as each zone
	  being worth a whole mine, which is ZONE_STEP 100.

	Shown both ladders measured side by side, the owner chose 100 (2026-10-05).
	The deciding figure was what zone 1 costs: at 10 it still swallows tiers
	1-49, 60% of the roster, and the finish/enter boundary jumps 33 tiers; at
	100 zone 1 is tiers 1-9 and every boundary is continuous.

	If the 500-layer mapping is the one that matters more, this is the single
	line to change back, and tools/zone-gate-fix.js prints both tables.
]]

--[[
	THE SAME RULE, TIGHTER IN THE ZONE YOU ARE STANDING IN.

	Owner, 2026-10-05: "maybe just make the ore requirement elevated until they
	go to next zone".

	So reach is not one number, it is two. In the zone you are currently
	working, ore is asked for nearly straight -- you have to forge up to meet
	it. Once you have unlocked the zone ABOVE it, that zone's ore drops to the
	full reach and you can mop up everything you outgrew.

	WHY THIS IS NOT ZERO, which is the thing to know before anyone "tightens"
	it further: reach is load-bearing for progression, not generosity. A tier-T
	tool has breaking power oreStrength(T), so with reach 0 it breaks ore up to
	tier T and no further -- and the ore you need to forge T+1 is tier T+1.
	Measured against this exact curve, reach 0 deadlocks at TIER 4: a tier-4
	tool can never break anything above tier 4, forever.

	Headroom each setting actually buys, measured, at tiers 20 / 50 / 80:

	    reach  0   0 / 0 / 0      deadlocks at tier 4
	    reach  3   3 / 3 / 2
	    reach  5   5 / 5 / 2      <- ORE_REACH_HOME
	    reach 15  15 / 15 / 2     <- ORE_REACH, zones you have cleared

	The taper to 2 at tier 80 is the ORE_POW curve steepening, not a cap: near
	the top, one tier is worth ~5 rungs, so even a generous reach buys little.
	That is the intended shape -- the last stretch is meant to be forged.
]]
MineBreaking.ORE_REACH_HOME = 5

--[[
	Which reach applies. `maxUnlockedZone` is the player's progress; nil means
	"caller does not know", and that takes the full reach so nothing that has
	not been taught about zones silently gets harder.
]]
function MineBreaking.reachFor(zoneIndex, maxUnlockedZone)
	local unlocked = tonumber(maxUnlockedZone)
	if unlocked == nil then
		return MineBreaking.ORE_REACH
	end
	local zi = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	if math.floor(unlocked) > zi then
		return MineBreaking.ORE_REACH
	end
	return MineBreaking.ORE_REACH_HOME
end

MineBreaking.ZONES = 10
--[[
	5000, DOWN FROM 10000 -- the LIVE floor.

	MineConfig assigns LAYERS twice and the second one, 5000, is what the module
	exports; MINE1_LAYERS still says 10000 and the seams past 5000 sit below the
	floor unreachable. This constant was reading the 10000 and it is used for
	exactly one thing: deriving MAX. So MAX was 100 rungs taller than anything a
	player can ever break, and the top of the ore ladder pointed at layers that do
	not exist.

	At 5000 the ladder TERMINATES where the game does. MAX becomes
	1 + 9*100 + 99 = 1000, and zone 10 layer 5000 computes to exactly 1000 -- so
	the deepest normal block demands precisely the top ore, tier 82, with nothing
	wasted above it and nothing unreachable below.

	EVENT HORIZON IS NOT ON THIS LADDER. Owner, 2026-10-05: "horizon is
	different... doesnt use normal tools". Zone 11 has its own progression, so
	the ore ladder is calibrated to the ten normal mines and zone 11's computed
	strength simply clamps at MAX. If the seams past 5000 are ever opened, this
	is the line to move with them.
]]
MineBreaking.MAX_LAYER = 5000

-- Derived, not hardcoded: the top of the ladder is exactly what the deepest
-- layer of the last zone demands, so the best ore tool reaches the mine floor
-- and nothing above it is unreachable or wasted.
MineBreaking.MAX = 1
	+ (MineBreaking.ZONES - 1) * MineBreaking.ZONE_STEP
	+ math.floor((MineBreaking.MAX_LAYER - 1) / MineBreaking.LAYERS_PER_RUNG)

-- Shop picks are the bottom of the ladder. Five rungs, and deliberately only
-- enough to reach the first few hundred layers: the shop takes you sideways,
-- forged tools take you down.
MineBreaking.SHOP_POWER = { 1, 2, 3, 4, 5 }

local function clampInt(n, lo, hi)
	n = math.floor(tonumber(n) or lo)
	return math.clamp(n, lo, hi)
end

-- Strength of plain rock at a place. Steps once per zone and once per
-- LAYERS_PER_RUNG layers, so depth and breadth each cost rungs.
--
-- Zone is ADDED, not multiplied. A multiplied zone term would make zone 10's
-- surface need ~10x zone 1's, so a tool good enough for the last zone would
-- trivialise every layer of the first; adding keeps one shared ladder where
-- every rung means the same thing wherever you are standing.
function MineBreaking.layerStrength(zoneIndex, layer)
	zoneIndex = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	local rung = 1
		+ (zoneIndex - 1) * MineBreaking.ZONE_STEP
		+ math.floor((layer - 1) / MineBreaking.LAYERS_PER_RUNG)
	return clampInt(rung, 1, MineBreaking.MAX)
end

-- Strength of an ore, from its tier. Tier 1 -> 1, tier 82 -> MAX, with the
-- ORE_POW curve between so the top of the roster carries the progression.
-- Both ends are exact by construction, so the best ore always reaches the mine
-- floor and the worst always clears the surface.
function MineBreaking.oreStrength(tier, oreCount)
	tier = math.max(1, math.floor(tonumber(tier) or 1))
	oreCount = math.max(2, math.floor(tonumber(oreCount) or 82))
	local span = (tier - 1) / (oreCount - 1)
	local curved = span ^ MineBreaking.ORE_POW
	return clampInt(1 + math.floor(curved * (MineBreaking.MAX - 1) + 0.5), 1, MineBreaking.MAX)
end

--[[
	What this block needs.

	An ore block takes the HARDER of its depth and its ore, never the sum. Sums
	stack two gates into one wall and make the ladder impossible to reason
	about; a max means an ore is exactly as hard as the harder of "where it is"
	and "what it is".
]]
function MineBreaking.blockStrength(zoneIndex, layer, oreTier, oreCount, maxUnlockedZone)
	local byLayer = MineBreaking.layerStrength(zoneIndex, layer)
	if oreTier == nil then
		return byLayer
	end
	-- Reach, applied where the refusal actually happens: an ore is asked for as
	-- if it sat `reach` tiers lower, so a tier-T tool clears ore up to tier
	-- T + reach -- ORE_REACH_HOME in the zone you are standing in, the full
	-- ORE_REACH once you have unlocked the one above.
	--
	-- Depth is untouched: byLayer still gates how deep the rock YIELDS, which is
	-- the half that must not be loosened. Nothing here gates movement -- a player
	-- may walk to any depth, and failing this check means the swing lands for
	-- zero on that block, not that they are kept out.
	local reach = math.max(0,
		math.floor(MineBreaking.reachFor(zoneIndex, maxUnlockedZone)))
	local asked = math.max(1, (tonumber(oreTier) or 1) - reach)
	return math.max(byLayer, MineBreaking.oreStrength(asked, oreCount))
end

--[[
	What this tool has.

	Order matters. An explicit stamped value wins, because a forged tool records
	its breaking power at craft time and must never silently re-derive if the
	roster moves underneath it -- that is how a player's tool would change in
	their hands. Only fall back to deriving for shop picks and legacy rows.
]]
function MineBreaking.toolBreakingPower(tool, oreCount)
	if type(tool) ~= "table" then
		return MineBreaking.SHOP_POWER[1]
	end
	local stamped = tonumber(tool.breakingPower or tool.bp)
	if stamped then
		return clampInt(stamped, 1, MineBreaking.MAX)
	end
	-- Forged from ore: the tool is as strong as the ore it is made of.
	local oreTier = tonumber(tool.oreTier or tool.tier)
	if tool.oreId or tool.ore then
		return MineBreaking.oreStrength(oreTier or 1, oreCount)
	end
	-- Shop pick: rung along the fixed ladder. `id` doubles as the rung.
	local rung = clampInt(tonumber(tool.rung or tool.id) or 1, 1, #MineBreaking.SHOP_POWER)
	return MineBreaking.SHOP_POWER[rung]
end

MineBreaking.TOO_WEAK = "Your tool is too weak to damage this block"

--[[
	The check itself. Returns (allowed, need, have).

	Callers must treat `false` as ZERO damage, not reduced damage. A partial
	chip would let a player grind through a wall given enough swings, which is
	the entire thing this exists to prevent.
]]
function MineBreaking.canBreak(tool, zoneIndex, layer, oreTier, oreCount, maxUnlockedZone)
	local need = MineBreaking.blockStrength(zoneIndex, layer, oreTier, oreCount, maxUnlockedZone)
	local have = MineBreaking.toolBreakingPower(tool, oreCount)
	return have >= need, need, have
end

return MineBreaking
