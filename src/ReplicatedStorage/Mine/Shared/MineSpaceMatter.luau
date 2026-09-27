-- Which health pool a swing may spend.
-- Event Horizon rock is SpaceHP. Meadow dirt is HP.
-- A meadow tool cannot spend SpaceHP. An event tool cannot spend HP.
-- A prototype can spend either pool, and it hits softer in space.

local MineSpaceMatter = {}

local WEAK = "weak"
local HEAVY = "heavy"

function MineSpaceMatter.classOf(tool)
	if type(tool) ~= "table" then
		return "normal"
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
	MineSpaceMatter.ensure(part)
	local class = MineSpaceMatter.classOf(tool)
	local space = MineSpaceMatter.isSpace(part)
	local attr
	if class == "event" then
		attr = space and "SpaceHP" or nil
	elseif class == "prototype" then
		attr = space and "SpaceHP" or "HP"
	else
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

return MineSpaceMatter
