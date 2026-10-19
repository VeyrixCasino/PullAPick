--[[
	MineCryptIcons -- the Candy Crypt's icon ids: the sixteen candy ores, the
	sixteen Halloween tools and the eight Crypt chests (owner, 2026-10-19: "get
	cursor to get images for everything with canva").

	FILLED BY A CURSOR JOB: tools/cursor/tasks/crypt-icons.md makes the images in
	Canva, uploads them and writes their ids into the three maps below. Until
	then the maps are empty, every lookup answers "", and the screens draw their
	fallback (a coloured tile).

	SHARED stays false until the owner has shared every upload with the group
	experience in the Creator Hub: an image uploaded as a person and not shared
	draws nothing in the group place (wiki/code/assets-and-uploads.md), so
	while it is false every lookup answers "" whatever the maps hold. The owner
	flips it, the way MineIcons.NEW_TOOL_ICONS_SHARED was flipped.

	Read through MineCryptRules (tool rows, candy-ore rows, chest odds rows carry
	`icon`), so a screen never needs to know this module exists.
]]
local MineCryptIcons = {}

MineCryptIcons.SHARED = false

-- [candyOreId] = "rbxassetid://<id>", e.g. candy_corn, jawbreaker (MineConfig.CANDY_ORES).
MineCryptIcons.ORES = {}
-- [toolId] = "rbxassetid://<id>", e.g. hallow_candy_corn_pick (MineCandyTools.TOOLS).
MineCryptIcons.TOOLS = {}
-- [rankKey] = "rbxassetid://<id>", "F" .. "SSS" (MineCryptChests.RANKS).
MineCryptIcons.CHESTS = {}

local function pick(map, key)
	if not MineCryptIcons.SHARED then
		return ""
	end
	local v = map[tostring(key or "")]
	return (type(v) == "string") and v or ""
end

function MineCryptIcons.ore(oreId)
	return pick(MineCryptIcons.ORES, oreId)
end

function MineCryptIcons.tool(toolId)
	return pick(MineCryptIcons.TOOLS, toolId)
end

function MineCryptIcons.chest(rankKey)
	return pick(MineCryptIcons.CHESTS, rankKey)
end

return MineCryptIcons
