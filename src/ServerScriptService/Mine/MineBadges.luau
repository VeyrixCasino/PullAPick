--!strict
--[[
	MineBadges — server-only Roblox badge awards for MINE FOR CARDS.

	IDs discovered from https://badges.roblox.com/v1/universes/<gameId>/badges
	(universe 10765866098). If an ID is wrong/disabled, set it to 0 here after
	pasting from Creator Dashboard → Associated Items → Badges.

	Award conditions:
	- welcome: first successful profile join / session boot
	- fresh_bread: first successful sell (Roblox desc: "Complete you first sale")
	- first_dig: first block broken (stats.blocks >= 1)
	- pack_opener: first pack opened (stats.packs >= 1)
	- meadow_bound: enter Dirt Meadow digsite via enterZone("meadow")
	- zone_hopper: unlock 2nd zone (maxUnlockedZone >= 2)
	- blockbuster_i..iv: lifetime blocks >= 1k / 10k / 100k / 1M
]]

local BadgeService = game:GetService("BadgeService")

local MineBadges = {}

MineBadges.BADGE_IDS = {
	welcome = 2358614802907428,
	fresh_bread = 1896674328937498,
	first_dig = 1485835106156132,
	pack_opener = 575458373985355,
	meadow_bound = 2758104675212090,
	zone_hopper = 4149260071771410,
	blockbuster_i = 3179766981301838,
	blockbuster_ii = 1597082949403951,
	blockbuster_iii = 1070751738888047,
	blockbuster_iv = 2361272966281073,
}

local BLOCKBUSTER = {
	{ key = "blockbuster_i", n = 1000 },
	{ key = "blockbuster_ii", n = 10000 },
	{ key = "blockbuster_iii", n = 100000 },
	{ key = "blockbuster_iv", n = 1000000 },
}

local busy: { [string]: boolean } = {}
-- Once we know a player already has (or we successfully awarded) a badge this
-- session, never touch BadgeService again for that key. Without this, every
-- dig re-fires AwardBadge and Studio floods "We already gave out badgeId=".
local owned: { [string]: boolean } = {}

function MineBadges.tryAward(plr: Player, key: string)
	local id = MineBadges.BADGE_IDS[key]
	if type(id) ~= "number" or id <= 0 then
		return
	end
	if not plr or plr.UserId <= 0 then
		return
	end
	local gate = tostring(plr.UserId) .. ":" .. key
	if owned[gate] or busy[gate] then
		return
	end
	busy[gate] = true
	task.spawn(function()
		local okHas, has = pcall(function()
			return BadgeService:UserHasBadgeAsync(plr.UserId, id)
		end)
		if okHas and has then
			owned[gate] = true
			busy[gate] = nil
			return
		end
		-- If ownership check failed, do NOT spam AwardBadge — wait and retry later.
		if not okHas then
			busy[gate] = nil
			return
		end
		local ok, err = pcall(function()
			BadgeService:AwardBadge(plr.UserId, id)
		end)
		-- Treat success OR "already owned" engine noise as done forever this session.
		owned[gate] = true
		if not ok then
			local msg = tostring(err)
			if not string.find(string.lower(msg), "already", 1, true) then
				warn("[MineBadges] AwardBadge failed", key, id, err)
				owned[gate] = nil
			end
		end
		busy[gate] = nil
	end)
end

function MineBadges.onWelcome(plr: Player)
	MineBadges.tryAward(plr, "welcome")
end

function MineBadges.onStat(plr: Player, p: any, stat: string)
	if not plr or type(p) ~= "table" then
		return
	end
	local n = tonumber(p.stats and p.stats[stat]) or 0
	if stat == "blocks" then
		if n >= 1 then
			MineBadges.tryAward(plr, "first_dig")
		end
		for _, row in ipairs(BLOCKBUSTER) do
			if n >= row.n then
				MineBadges.tryAward(plr, row.key)
			end
		end
	elseif stat == "sells" then
		if n >= 1 then
			MineBadges.tryAward(plr, "fresh_bread")
		end
	elseif stat == "packs" then
		if n >= 1 then
			MineBadges.tryAward(plr, "pack_opener")
		end
	end
end

function MineBadges.onEnterZone(plr: Player, zoneId: string)
	if zoneId == "meadow" then
		MineBadges.tryAward(plr, "meadow_bound")
	end
end

function MineBadges.onZoneUnlocked(plr: Player, maxUnlockedZone: number)
	if (tonumber(maxUnlockedZone) or 1) >= 2 then
		MineBadges.tryAward(plr, "zone_hopper")
	end
end

-- Catch-up for players who already met thresholds before badges shipped.
-- Meadow Bound is enter-digsite only (not lobby join).
function MineBadges.reconcile(plr: Player, p: any)
	if not plr or type(p) ~= "table" then
		return
	end
	MineBadges.onWelcome(plr)
	local s = p.stats or {}
	local blocks = tonumber(s.blocks) or 0
	if blocks >= 1 then
		MineBadges.tryAward(plr, "first_dig")
	end
	for _, row in ipairs(BLOCKBUSTER) do
		if blocks >= row.n then
			MineBadges.tryAward(plr, row.key)
		end
	end
	if (tonumber(s.sells) or 0) >= 1 then
		MineBadges.tryAward(plr, "fresh_bread")
	end
	if (tonumber(s.packs) or 0) >= 1 then
		MineBadges.tryAward(plr, "pack_opener")
	end
	MineBadges.onZoneUnlocked(plr, tonumber(p.maxUnlockedZone) or 1)
end

return MineBadges
