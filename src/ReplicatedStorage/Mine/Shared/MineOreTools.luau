--[[
	MineOreTools: a forged tool IS its ore.

	Owner, 2026-10-03, on seeing the Forge for the first time:

	  "everything in forge should be called {ore} {tool}"
	  "i want crafting to be sorted by the actual ore"
	  "i dont want different tools to cost different ores. If i want to upgrade
	   my stone pick, it should cost stone, at an increasing amount each time."

	The data model was already most of the way there and the PANEL was the liar.
	A forged row is { uid, typeId, familyId, tier, level } and `tier` is the
	ORE's tier -- the server sets `tier = oreDef.tier` on craft, and upgrading
	charges `C.ORES[tool.tier]`, the tool's own ore, growing by TOOL_ORE_GROW
	each level. That part was right.

	What was wrong: the Forge listed TOOL TYPES down its rail, under the coin
	shop's invented names -- "Chipped Crown", "Widow's Notch", "Brightfracture"
	-- and then asked you to pick any ore at all to forge one out of. So the
	thing you selected had no ore in its name, and the same name could be made
	of forty different ores at forty different prices. Hence "none of this makes
	sense".

	This module makes the ore the identity and the frame a consequence:

	  name        {Ore} {Noun}  --  "Stone Pickaxe", "Clay Drill"
	  frame       derived from the ore's tier, never chosen
	  cost        that ore, and only that ore

	THE FRAME IS DERIVED, NOT PICKED. 82 ore tiers are mapped proportionally
	onto a family's priced rungs, the same way ToolModelFactory.oreLook spreads
	silhouette across the roster. Deterministic and pure, so the panel quoting a
	price and the verb charging it reach the same answer without passing a
	typeId between them -- which also means a modified client cannot ask for a
	deep ore in a cheap frame.

	The free starter is excluded: `wood_pick` is priced 0 because it is GIVEN,
	and the craft verb refuses it by id. Filtering on `price > 0` keeps it, and
	anything else unpriced, out of the pool by construction rather than by a
	second list that can drift.
]]
local MineOreTools = {}

local RS = game:GetService("ReplicatedStorage")
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared:WaitForChild("MineConfig"))
local Tools = require(shared:WaitForChild("MineTools"))
-- The trait prefix. Loaded here so every caller that names a tool
-- gets the prefix for free rather than remembering to add it.
local Traits = require(shared:WaitForChild("MineTraits"))

-- What one of these is called. Singular, because it names one tool.
MineOreTools.NOUN = {
	pickaxe = "Pickaxe",
	drill = "Drill",
	explosive = "Explosive",
	weapon = "Weapon",
}

-- The families a player can actually forge in, in rail order.
MineOreTools.FAMILY_ORDER = { "pickaxe", "drill", "explosive" }

function MineOreTools.familyNoun(familyId)
	local id = tostring(familyId or "pickaxe")
	return MineOreTools.NOUN[id] or (id:sub(1, 1):upper() .. id:sub(2))
end

--[[
	The forgeable frames of a family, cheapest rung first.

	Cached per family: this is read once per rail row per redraw, and the rail
	redraws on every snapshot.
]]
local frameCache = {}
function MineOreTools.frames(familyId)
	local id = tostring(familyId or "pickaxe")
	if frameCache[id] then
		return frameCache[id]
	end
	local out = {}
	for _, td in ipairs((Tools.TOOLS or {})[id] or {}) do
		-- Priced rungs only. price == 0 is the given starter; no price at all
		-- is a chest flagship, which is found and never forged.
		if (tonumber(td.price) or 0) > 0 then
			out[#out + 1] = td
		end
	end
	table.sort(out, function(a, b)
		return (tonumber(a.tier) or 0) < (tonumber(b.tier) or 0)
	end)
	frameCache[id] = out
	return out
end

--[[
	Which frame an ore of this tier wears.

	Proportional, not nearest: there are 82 ore tiers and ~24 rungs, so
	"nearest" would park every ore past tier 24 on the top rung and make the
	whole back half of the roster look identical. Spreading them keeps the
	silhouette moving all the way down, which is the same choice oreLook makes.
]]
function MineOreTools.frameForTier(familyId, oreTier)
	local defs = MineOreTools.frames(familyId)
	local n = #defs
	if n == 0 then
		return nil
	end
	local span = math.max(1, (tonumber(C.ORE_COUNT) or 82) - 1)
	local t = math.clamp((math.floor(tonumber(oreTier) or 1) - 1) / span, 0, 1)
	local idx = math.clamp(math.floor(t * (n - 1) + 0.5) + 1, 1, n)
	return defs[idx]
end

-- The frame a forged row is wearing. Reads the row's stored typeId when it has
-- one -- rows forged before the frame was derived keep theirs -- and otherwise
-- derives it, so an old save never draws a blank.
function MineOreTools.frameOf(tool)
	if type(tool) ~= "table" then
		return nil
	end
	local fam = tostring(tool.familyId or "pickaxe")
	if tool.typeId then
		for _, td in ipairs((Tools.TOOLS or {})[fam] or {}) do
			if td.id == tool.typeId then
				return td
			end
		end
	end
	return MineOreTools.frameForTier(fam, tool.tier)
end

--[[
	THE COST MULTIPLIER, AS A FUNCTION OF THE ORE AND NOTHING ELSE.

	Owner, 2026-10-06: "delete all tools in the game besides for chest
	tools... and ore tools". The priced roster is gone, and this used to read
	it: it found the frame an ore wore, took that frame's rarity, and returned
	its rank.

	But frameForTier is deterministic in ore tier, so this was ALREADY a pure
	function of tier -- it just reached through a table to compute it. Measured
	across all 82 tiers before the roster was removed, it is a clean step
	function, and the steps are baked here exactly as they were:

	    pickaxe   1-6=1 7-16=2 17-27=3 28-37=4 38-48=5 49-59=6 60-69=7 70-82=8
	    drill     1-9=1 10-19=2 20-30=3 31-41=4 42-52=5 53-63=6 64-73=7 74-82=8
	    explosive (same as drill)

	They differ because a family's rungs were spread across the roster and the
	families had different rung counts -- 24 for pickaxes, 16 for the others.

	WHY NOT THE ORE'S RARITY BAND, which was the obvious replacement: measured,
	it drops the roster mean from 4.80 to 3.38 and cuts some tiers to a third,
	with nothing going up. That is a 30% cut to forge costs nobody asked for.
	Baking the real curve removes the dependency and changes no number at all.
]]
MineOreTools.TYPE_MULT_STEPS = {
	pickaxe = { 6, 16, 27, 37, 48, 59, 69, 82 },
	drill = { 9, 19, 30, 41, 52, 63, 73, 82 },
	explosive = { 9, 19, 30, 41, 52, 63, 73, 82 },
}

function MineOreTools.typeMult(familyId, oreTier)
	local steps = MineOreTools.TYPE_MULT_STEPS[tostring(familyId or "pickaxe")]
		or MineOreTools.TYPE_MULT_STEPS.pickaxe
	local t = math.max(1, math.floor(tonumber(oreTier) or 1))
	for i, upTo in ipairs(steps) do
		if t <= upTo then
			return i
		end
	end
	return #steps
end

-- The ore a forged row is made of. `tier` is the ore's tier and always has
-- been; this is the one place that turns it back into a row.
function MineOreTools.oreOf(tool)
	if type(tool) ~= "table" then
		return nil
	end
	return (C.ORES or {})[math.floor(tonumber(tool.tier) or 0)]
end

--[[
	"Stone Pickaxe", or "Sharp Stone Pickaxe" with an trait on it.

	The prefix is part of the name and not a decoration added by whichever
	screen remembered to: owner, 2026-10-04, "its a prefix too your tool
	(Sharp Stone Pickaxe, Lucky Stone Drill)". Every caller that names a tool
	goes through here, so there is nowhere for an unprefixed name to leak out.
]]
function MineOreTools.name(oreDef, familyId, trait)
	local ore = (type(oreDef) == "table" and (oreDef.name or oreDef.id)) or "Unknown"
	return Traits.decorate(tostring(ore) .. " " .. MineOreTools.familyNoun(familyId), trait)
end

-- The same, from a forged row. The row carries its own trait, so a tool
-- cannot be named without it.
function MineOreTools.toolName(tool)
	if type(tool) ~= "table" then
		return "Unknown Tool"
	end
	return MineOreTools.name(MineOreTools.oreOf(tool), tool.familyId, tool.trait)
end

return MineOreTools
