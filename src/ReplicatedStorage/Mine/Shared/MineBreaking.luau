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

-- 100 rungs across the whole game. Small integers so the number on a tool and
-- the number on a block can be compared by eye, and so "too weak" is legible.
MineBreaking.MAX = 100

-- One rung per this many layers. 10,000 layers / 100 = rung per 100 layers.
MineBreaking.LAYERS_PER_RUNG = 100

-- Shop picks are the bottom of the ladder. Five rungs, and deliberately only
-- enough to reach the first few hundred layers: the shop takes you sideways,
-- forged tools take you down.
MineBreaking.SHOP_POWER = { 1, 2, 3, 4, 5 }

local function clampInt(n, lo, hi)
	n = math.floor(tonumber(n) or lo)
	return math.clamp(n, lo, hi)
end

-- Strength of plain rock at a depth. Steps every LAYERS_PER_RUNG layers.
--
-- Deliberately NOT zone-scaled. Zone difficulty already lives in block HP
-- (x5 per zone); adding it here too would mean a zone-10 surface block was
-- unbreakable by a tool that clears a zone-1 surface block, which would make
-- buying a zone a wall rather than a choice.
function MineBreaking.layerStrength(layer)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	local rung = 1 + math.floor((layer - 1) / MineBreaking.LAYERS_PER_RUNG)
	return clampInt(rung, 1, MineBreaking.MAX)
end

-- Strength of an ore, from its tier. Tier 1 -> 1, tier 82 -> MAX, linear
-- between, so the roster spreads evenly across the ladder.
function MineBreaking.oreStrength(tier, oreCount)
	tier = math.max(1, math.floor(tonumber(tier) or 1))
	oreCount = math.max(2, math.floor(tonumber(oreCount) or 82))
	local span = (tier - 1) / (oreCount - 1)
	return clampInt(1 + math.floor(span * (MineBreaking.MAX - 1) + 0.5), 1, MineBreaking.MAX)
end

--[[
	What this block needs.

	An ore block takes the HARDER of its depth and its ore, never the sum. Sums
	stack two gates into one wall and make the ladder impossible to reason
	about; a max means an ore is exactly as hard as the harder of "where it is"
	and "what it is".
]]
function MineBreaking.blockStrength(zoneIndex, layer, oreTier, oreCount)
	local byLayer = MineBreaking.layerStrength(layer)
	if oreTier == nil then
		return byLayer
	end
	return math.max(byLayer, MineBreaking.oreStrength(oreTier, oreCount))
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
function MineBreaking.canBreak(tool, zoneIndex, layer, oreTier, oreCount)
	local need = MineBreaking.blockStrength(zoneIndex, layer, oreTier, oreCount)
	local have = MineBreaking.toolBreakingPower(tool, oreCount)
	return have >= need, need, have
end

return MineBreaking
