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
	The cost multiplier a frame carries.

	Both MineForge and MineServer had their own copy of this, with a comment on
	each saying it mirrored the other. Two copies of one rule is one rule and
	one bug waiting; this is the copy.
]]
function MineOreTools.typeMult(familyId, typeId)
	for _, td in ipairs((Tools.TOOLS or {})[tostring(familyId or "pickaxe")] or {}) do
		if td.id == typeId then
			local r = Tools.normalizeToolRarity and Tools.normalizeToolRarity(td.rarity)
			return (Tools.RARITY_RANK and Tools.RARITY_RANK[r or td.rarity]) or 1
		end
	end
	return 1
end

-- The ore a forged row is made of. `tier` is the ore's tier and always has
-- been; this is the one place that turns it back into a row.
function MineOreTools.oreOf(tool)
	if type(tool) ~= "table" then
		return nil
	end
	return (C.ORES or {})[math.floor(tonumber(tool.tier) or 0)]
end

-- "Stone Pickaxe". The whole point of the module.
function MineOreTools.name(oreDef, familyId)
	local ore = (type(oreDef) == "table" and (oreDef.name or oreDef.id)) or "Unknown"
	return tostring(ore) .. " " .. MineOreTools.familyNoun(familyId)
end

-- The same, from a forged row.
function MineOreTools.toolName(tool)
	if type(tool) ~= "table" then
		return "Unknown Tool"
	end
	return MineOreTools.name(MineOreTools.oreOf(tool), tool.familyId)
end

return MineOreTools
