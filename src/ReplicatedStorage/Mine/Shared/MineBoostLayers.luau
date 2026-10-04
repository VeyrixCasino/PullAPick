--[[
	MineBoostLayers: two layers, and the second one multiplies the first.

	Owner, 2026-10-04:

	  "skills+skins+tools+traits are the very bottom skills (all
	   multipliers go ontop of that, as if it was default), equipment+pets are
	   #2 [if skin has +50% damage, and pet says +100% damage, and the tools
	   base is 100, then it turns to 300, rather than 250 (if it was all the
	   same)]"

	THE WORKED EXAMPLE, which is the whole specification:

	    tool base                100
	    skin        +50%   (layer 1)
	    pet        +100%   (layer 2)

	    all additive, one pile:  100 x (1 + 0.5 + 1.0)   = 250   <- rejected
	    two layers:              100 x (1 + 0.5) x (1 + 1.0) = 300   <- this

	So: everything inside a layer ADDS, and the layers MULTIPLY. Layer 1 is the
	new "default" that layer 2 is applied on top of, which is what "as if it was
	default" means.

	  LAYER 1, the base      skills, skins (temperaments), tools, traits
	  LAYER 2, on top        equipment, pets

	WHY THIS MATTERS, beyond the arithmetic: in one pile, the marginal value of
	a pet depends on how good your skin is -- +100% is worth less the more you
	already have, because it is diluted by the same denominator. In two layers a
	pet is always worth exactly double, whatever the skin does. Each layer is
	worth building independently, which is the thing a single pile cannot do.

	WHAT IS NOT IN EITHER LAYER, on purpose: prestige, VIP and the event pass
	still apply the way they always have, outside both. The owner named four
	sources and two, and those three were in neither list; moving them without
	being asked would silently rebalance the rebirth curve. Flagged in
	docs/BLOCKED.md rather than guessed.

	CHANCE STATS ARE NOT LAYERED. Blast chance, Zap, Earthquake, Ricochet and
	Proc Power are additive fractions, not multipliers -- "1 + x" on a chance is
	meaningless and two layers of it is twice as meaningless. They sum, exactly
	as they do today. MineCards.ADDITIVE_STATS is the list, and this module
	never second-guesses it.
]]
local MineBoostLayers = {}

-- Who is in which layer. Names, not modules: this is the design statement, and
-- the server maps its own sources onto it.
MineBoostLayers.LAYER1 = { "skills", "skins", "tools", "traits" }
MineBoostLayers.LAYER2 = { "equipment", "pets" }

MineBoostLayers.TIER_OF = {
	skills = 1, skins = 1, tools = 1, traits = 1,
	equipment = 2, pets = 2,
}

--[[
	A fresh pair of accumulators. Each is stat -> additive fraction; 0.5 means
	"+50% from this layer", and a stat nobody touched is simply absent.
]]
function MineBoostLayers.new()
	return {}, {}
end

-- Add into a layer. Nil-safe and additive, because within a layer everything
-- adds -- that is the half of the rule this function exists to enforce.
function MineBoostLayers.add(acc, stat, amount)
	if type(acc) ~= "table" or not stat then
		return acc
	end
	local n = tonumber(amount)
	if not n or n == 0 then
		return acc
	end
	acc[stat] = (tonumber(acc[stat]) or 0) + n
	return acc
end

-- The rule, in one line, for one stat.
function MineBoostLayers.combineOne(base, t1, t2)
	return (tonumber(base) or 1)
		* (1 + (tonumber(t1) or 0))
		* (1 + (tonumber(t2) or 0))
end

--[[
	Fold both layers into a boost table.

	`skip` is the additive-stat set (MineCards.ADDITIVE_STATS). A stat in it is
	summed straight into the table instead of being layered, because it is a
	chance and not a multiplier.

	Multiplier stats sit at 1 when they give nothing, so a stat the boost table
	has never heard of starts at 1 rather than 0 -- starting at 0 would zero out
	every stat the first layer happened to touch.
]]
function MineBoostLayers.apply(boosts, t1, t2, skip)
	if type(boosts) ~= "table" then
		return boosts
	end
	t1, t2, skip = t1 or {}, t2 or {}, skip or {}
	local touched = {}
	for stat in pairs(t1) do touched[stat] = true end
	for stat in pairs(t2) do touched[stat] = true end
	for stat in pairs(touched) do
		if skip[stat] then
			boosts[stat] = (tonumber(boosts[stat]) or 0)
				+ (tonumber(t1[stat]) or 0) + (tonumber(t2[stat]) or 0)
		else
			boosts[stat] = MineBoostLayers.combineOne(boosts[stat], t1[stat], t2[stat])
		end
	end
	return boosts
end

return MineBoostLayers
