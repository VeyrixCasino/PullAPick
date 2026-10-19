-- Which health pool a swing may spend.
-- Event Horizon rock is SpaceHP. Meadow dirt is HP.
-- A meadow tool cannot spend SpaceHP. An event tool cannot spend HP.
-- A prototype can spend either pool, and it hits softer in space.
--
-- EVENT-TOOLS-ONLY MINES (owner, 2026-10-19: "Normal tools do not work in
-- events"). A zone row with `eventToolsOnly` (the Candy Crypt) takes damage
-- only from a SEASONAL row built for that mine -- MineCryptRules.eventRow
-- stamps `eventMine` with the zone id -- and such a row spends nothing
-- anywhere else. This is the one place both damage paths (swingBlock's
-- applyDmg and swingNeighbour, so procs and charges too) agree on it, so the
-- rule holds even if a stale tool reaches a block. Event Horizon is not
-- flagged and its two pools are unchanged.

local MineSpaceMatter = {}

local WEAK = "weak"
local HEAVY = "heavy"
-- A normal (or Event Horizon) tool on an event-tools-only block.
local EVENT_ONLY = "eventonly"
-- An event mine's own tool on a block outside that mine.
local EVENT_TOOL = "eventtool"

-- What the swing says for each refusal. "weak" / "heavy" are the lines the
-- server has always used; the two event-only ones are new.
MineSpaceMatter.TOAST = {
	weak = "Too weak out here.",
	heavy = "Too heavy in this gravity.",
	eventonly = "Only event tools work here.",
	eventtool = "That event tool only works in its event.",
}

-- The zone ids whose rows say eventToolsOnly, read lazily off MineConfig (it
-- does not require this module, so there is no cycle) and cached.
local eventOnlyZones = nil
local function eventOnlyZoneOf(part)
	if not part then
		return nil
	end
	if eventOnlyZones == nil then
		eventOnlyZones = {}
		local ok, C = pcall(function()
			return require(script.Parent:WaitForChild("MineConfig"))
		end)
		if ok and type(C) == "table" then
			for _, z in ipairs(C.ZONES or {}) do
				if z.eventToolsOnly then
					eventOnlyZones[z.id] = true
				end
			end
		end
	end
	local zid = part:GetAttribute("ZoneId")
	if zid ~= nil and eventOnlyZones[zid] then
		return zid
	end
	return nil
end
MineSpaceMatter.eventOnlyZoneOf = eventOnlyZoneOf

function MineSpaceMatter.classOf(tool)
	if type(tool) ~= "table" then
		return "normal"
	end
	-- A row built to be swung INSIDE an event-tools-only mine.
	if tool.eventMine ~= nil then
		return "seasonal"
	end
	if tool.eventOnly == true or tool.zoneId == "bigbang" then
		return "event"
	end
	local special = tostring(tool.special or "")
	local id = tostring(tool.id or "")
	if special == "prototype_bag" or string.sub(id, 1, 9) == "proto_bag" then
		return "normal"
	end
	if special == "prototype" or special == "prototype_expl" or string.sub(id, 1, 6) == "proto_" then
		return "prototype"
	end
	return "normal"
end

-- The event-only rule, alone: nil when the tool may spend this block's rock,
-- else the refusal. Checked before the space-matter rule.
local function eventOnlyRefusal(tool, part)
	local only = eventOnlyZoneOf(part)
	local mine = type(tool) == "table" and tool.eventMine or nil
	if only then
		if mine ~= only then
			return EVENT_ONLY
		end
		return nil
	end
	if mine ~= nil then
		return EVENT_TOOL
	end
	return nil
end
MineSpaceMatter.eventOnlyRefusal = eventOnlyRefusal

function MineSpaceMatter.ensure(part)
	if not part or part:GetAttribute("ZoneId") ~= "bigbang" then
		return
	end
	if part:GetAttribute("Matter") == "space" and part:GetAttribute("SpaceMax") ~= nil then
		return
	end
	local maxHp = tonumber(part:GetAttribute("MaxHP")) or tonumber(part:GetAttribute("HP")) or 1
	local hp = tonumber(part:GetAttribute("SpaceHP")) or tonumber(part:GetAttribute("HP")) or maxHp
	part:SetAttribute("Matter", "space")
	part:SetAttribute("SpaceMax", maxHp)
	part:SetAttribute("SpaceHP", hp)
end

function MineSpaceMatter.isSpace(part)
	return part ~= nil and part:GetAttribute("Matter") == "space"
end

function MineSpaceMatter.reject(tool, part)
	local why = eventOnlyRefusal(tool, part)
	if why then
		return why
	end
	MineSpaceMatter.ensure(part)
	local space = MineSpaceMatter.isSpace(part)
	local class = MineSpaceMatter.classOf(tool)
	if class == "event" and not space then
		return HEAVY
	end
	if class == "normal" and space then
		return WEAK
	end
	return nil
end

function MineSpaceMatter.scaledDamage(tool, part, dmg)
	dmg = math.max(0, tonumber(dmg) or 0)
	if MineSpaceMatter.classOf(tool) ~= "prototype" or not MineSpaceMatter.isSpace(part) then
		return dmg
	end
	local main = math.max(1, tonumber(tool.power) or 1)
	local spacePower = tonumber(tool.spacePower) or math.max(1, math.floor(main / 4))
	return math.max(1, math.floor(dmg * (spacePower / main)))
end

-- Writes the pool this tool is allowed to spend. Does not pay or break the block.
function MineSpaceMatter.chip(part, tool, dmg)
	local refused = eventOnlyRefusal(tool, part)
	if refused then
		return { ok = false, why = refused }
	end
	MineSpaceMatter.ensure(part)
	local class = MineSpaceMatter.classOf(tool)
	local space = MineSpaceMatter.isSpace(part)
	local attr
	if class == "event" then
		attr = space and "SpaceHP" or nil
	elseif class == "prototype" then
		attr = space and "SpaceHP" or "HP"
	else
		-- "normal", and "seasonal" on its own mine's (ordinary) rock.
		attr = space and nil or "HP"
	end
	if not attr then
		return { ok = false, why = (class == "event") and HEAVY or WEAK }
	end
	local amount = MineSpaceMatter.scaledDamage(tool, part, dmg)
	local maxAttr = (attr == "SpaceHP") and "SpaceMax" or "MaxHP"
	local maxHp = tonumber(part:GetAttribute(maxAttr)) or tonumber(part:GetAttribute("MaxHP")) or 1
	local before = tonumber(part:GetAttribute(attr))
	if before == nil then
		before = maxHp
	end
	local landed = math.min(amount, math.max(0, before))
	local after = before - amount
	part:SetAttribute(attr, after)
	if attr == "SpaceHP" then
		part:SetAttribute("HP", after)
		part:SetAttribute("MaxHP", maxHp)
	end
	return {
		ok = true,
		attr = attr,
		before = before,
		after = after,
		landed = landed,
		max = maxHp,
		broke = after <= 0,
	}
end

MineSpaceMatter.WEAK = WEAK
MineSpaceMatter.HEAVY = HEAVY
MineSpaceMatter.EVENT_ONLY = EVENT_ONLY
MineSpaceMatter.EVENT_TOOL = EVENT_TOOL

return MineSpaceMatter
