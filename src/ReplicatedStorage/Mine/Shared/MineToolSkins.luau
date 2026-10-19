--[[
	MineToolSkins -- which skin a tool is wearing, and what it does to it.

	Owner, 2026-10-19 (the launch-audit build spec): "one wardrobe everywhere"
	-- event tools wear the same skins -- and "make skins work, all of it".

	A skin is worn per tool FAMILY (p.skinEquipped[family] = skin id) and it
	dresses EVERY tool of that family: forged, event (Event Horizon, the Candy
	Crypt), chest finds. That was already the owner's rule ("Skins work on every
	tool in the class", Verbs.equipSkin), but the code resolved a skin three
	ways: the damage and the kit stats read the FORGED tool's uid and nothing
	else, while the look read the family of whatever was in hand. So an event
	tool could wear a skin's look and get none of its power.

	This module is the one place that turns "this tool" into "this skin", so
	the damage, the kit stats and the look are resolved by the same rule.

	THE CONTRACT FOR A TOOL RECORD: a table with `family` (every tool def --
	event, chest, shop, candy) or `familyId` (a forged row). Nothing else is
	read. Give any new tool a family and it can wear the wardrobe.

	Pure: no Instances, no services. Read by the server (equippedTool through
	Dig.wearSkin, boosts, givePickaxe, equipSkin, the ore case) and by the
	screens (MineSkinsView, MineForgeHub).
]]
local MineToolSkins = {}

local Skins = require(script.Parent:WaitForChild("MineSkins"))
local Stats = require(script.Parent:WaitForChild("MineStats"))

--[[
	The tool classes a skin can be worn on. The server refuses any other family
	name, so a crafted request cannot grow p.skinEquipped with junk keys. A new
	tool class (the planned weapon) joins here when it ships.
]]
MineToolSkins.FAMILIES = { "pickaxe", "hammer", "drill", "jackhammer", "explosive" }
local IS_FAMILY = {}
for _, f in ipairs(MineToolSkins.FAMILIES) do
	IS_FAMILY[f] = true
end

-- What a family is called on a screen, singular.
MineToolSkins.FAMILY_NAME = {
	pickaxe = "Pickaxe", hammer = "Hammer", drill = "Drill",
	jackhammer = "Jackhammer", explosive = "Explosive",
}

-- The honest label for a skin on a family that has no skin form yet: the skin
-- changes the tool's numbers, not how it looks (owner: "make skins work").
MineToolSkins.STATS_ONLY = "stats only"

function MineToolSkins.isFamily(fam)
	return type(fam) == "string" and IS_FAMILY[fam] == true
end

--[[
	The family a tool record belongs to. Accepts a record (`family`, or a forged
	row's `familyId`) or a bare family name; `fallback` covers a record that
	carries neither.
]]
function MineToolSkins.familyOf(tool, fallback)
	local f
	if type(tool) == "table" then
		f = tool.family or tool.familyId
	elseif type(tool) == "string" then
		f = tool
	end
	if type(f) == "string" and f ~= "" then
		return f
	end
	return fallback
end

--[[
	The skin worn on this tool's family, or nil. `skinEquipped` is the
	profile's map (p.skinEquipped, or the snapshot's copy of it).

	Returns the MineSkins def and the family it was looked up under.
]]
function MineToolSkins.skinFor(skinEquipped, tool, fallback)
	local fam = MineToolSkins.familyOf(tool, fallback)
	if not fam or type(skinEquipped) ~= "table" then
		return nil, fam
	end
	local id = skinEquipped[fam]
	if id == nil or id == "" then
		return nil, fam
	end
	return Skins.byId(id), fam
end

-- The damage multiplier a skin puts under the tool's own power (MineSkins.BASE
-- by grade, x1.15 at F to x5.5 at SSS). 1 for no skin.
function MineToolSkins.mult(skin)
	return tonumber(Skins.baseOf(skin)) or 1
end

-- A power number with the skin under it, rounded the way the server rounds.
function MineToolSkins.applyPower(power, mult)
	local p = tonumber(power)
	if not p or p <= 0 then
		return power
	end
	return math.max(1, math.floor(p * (tonumber(mult) or 1)))
end

--[[
	THE HELD TOOL, WEARING ITS SKIN.

	Returns a COPY with the skin's base under every power the tool carries, and
	the skin stamped on it (`skinId`, `skinMult`) so the kit stats and the look
	read the very skin the damage used. Never mutates the def it was handed:
	event and chest tools are shared tables out of their modules.

	A row that already carries `skinId` is returned as it is, so a caller that
	built the skin into its own power (the forged path, MineOreTools.hitPower)
	is never multiplied twice. A row marked `none` (bare hands) wears nothing.
]]
function MineToolSkins.wear(tool, skin)
	if type(tool) ~= "table" or type(skin) ~= "table" or tool.none or tool.skinId ~= nil then
		return tool
	end
	local m = MineToolSkins.mult(skin)
	local t = table.clone(tool)
	t.power = MineToolSkins.applyPower(t.power, m)
	if t.spacePower ~= nil then
		t.spacePower = MineToolSkins.applyPower(t.spacePower, m)
	end
	if t.jackpotPower ~= nil then
		t.jackpotPower = MineToolSkins.applyPower(t.jackpotPower, m)
	end
	t.skinId = skin.id
	t.skinMult = m
	return t
end

-- Every family wearing this skin, in rail order. One skin can dress several.
function MineToolSkins.wornOn(skinEquipped, skinId)
	local out = {}
	if type(skinEquipped) ~= "table" or skinId == nil then
		return out
	end
	for _, f in ipairs(MineToolSkins.FAMILIES) do
		if skinEquipped[f] == skinId then
			table.insert(out, f)
		end
	end
	return out
end

--[[
	WHAT A SKIN DOES, IN WORDS A PLAYER READS.

	multText: "x3", "x1.15" -- the damage multiplier, trimmed.
	kitLines: MineStats.describe on the kit, so a skin prints its stats exactly
	          the way a pet or a hat prints the same stat.
	kitText:  "+45.4% Pack Luck  ·  +30.3% Chest Luck  ·  +1 more", capped at
	          `maxStats` kit lines.
	powerLine: "x3 damage", then kitText.
]]
function MineToolSkins.multText(skin)
	local m = MineToolSkins.mult(skin)
	local s = string.format("%.2f", m):gsub("0+$", ""):gsub("%.$", "")
	return "x" .. s
end

-- Biggest stat first, so a tile with room for one line shows the skin's
-- headline; MineStats' display order breaks ties.
function MineToolSkins.kitLines(skin)
	if type(skin) ~= "table" then
		return {}
	end
	local kit = Stats.withoutAutoMine(skin.kit or {})
	local lines = Stats.describe(kit)
	local rank = {}
	for i, l in ipairs(lines) do
		rank[l] = i
	end
	table.sort(lines, function(a, b)
		local x, y = math.abs(tonumber(kit[a.stat]) or 0), math.abs(tonumber(kit[b.stat]) or 0)
		if x ~= y then
			return x > y
		end
		return rank[a] < rank[b]
	end)
	return lines
end

function MineToolSkins.kitText(skin, maxStats, sep)
	local bits = {}
	local lines = MineToolSkins.kitLines(skin)
	local cap = tonumber(maxStats) or #lines
	for i, l in ipairs(lines) do
		if i > cap then
			table.insert(bits, "+" .. (#lines - cap) .. " more")
			break
		end
		table.insert(bits, l.text .. " " .. l.label)
	end
	return table.concat(bits, sep or "  ·  ")
end

function MineToolSkins.powerLine(skin, maxStats, sep)
	if type(skin) ~= "table" then
		return ""
	end
	sep = sep or "  ·  "
	local kit = MineToolSkins.kitText(skin, maxStats, sep)
	return MineToolSkins.multText(skin) .. " damage" .. ((kit ~= "") and (sep .. kit) or "")
end

--[[
	A SKIN CASE'S REEL. The winner is decided before the reel exists and the
	reel is built around it (the MineTemper.caseReel contract), so the spin is
	cosmetic. Same length, same stop and the same common-leaning filler odds as
	a temper case; the tiles are skins, never a pass skin (MineSkins.isPass).

	`rng` needs NextNumber and NextInteger (a Random). Returns reel, at.
]]
function MineToolSkins.caseReel(rng, winner)
	local Temper = require(script.Parent:WaitForChild("MineTemper"))
	local size = tonumber(Temper.CASE_REEL) or 44
	local at = tonumber(Temper.CASE_WINNER_AT) or 38
	local weights = Temper.CASE_FILLER_WEIGHTS or { F = 1 }
	local order = Skins.TIERS or { "F" }
	local pools = {}
	for _, s in ipairs(Skins.LIST or {}) do
		if not Skins.isPass(s) then
			pools[s.tier] = pools[s.tier] or {}
			table.insert(pools[s.tier], s)
		end
	end
	local function tile(s)
		local first = Stats.describe(s.kit or {})[1]
		return { id = s.id, name = s.name, rarity = s.tier, stat = first and first.stat or nil }
	end
	local function fillerGrade()
		local total = 0
		for _, g in ipairs(order) do
			if pools[g] then
				total += tonumber(weights[g]) or 0
			end
		end
		local n, acc = rng:NextNumber() * total, 0
		for _, g in ipairs(order) do
			if pools[g] then
				acc += tonumber(weights[g]) or 0
				if n <= acc then
					return g
				end
			end
		end
		return "F"
	end
	local reel = {}
	for i = 1, size do
		if i == at and type(winner) == "table" then
			table.insert(reel, tile(winner))
		else
			local pool = pools[fillerGrade()] or pools.F
			if pool and #pool > 0 then
				table.insert(reel, tile(pool[rng:NextInteger(1, #pool)]))
			elseif type(winner) == "table" then
				table.insert(reel, tile(winner))
			end
		end
	end
	return reel, at
end

return MineToolSkins
