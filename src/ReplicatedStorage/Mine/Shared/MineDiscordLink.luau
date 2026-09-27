-- MineDiscordLink: Discord !link code → Account tab redeem → link + gem bonus
local DataStoreService = game:GetService("DataStoreService")
-- Studio gets its own copies (like every other store, see MineConfig.storeName)
-- so testing never writes to the live link claims.
local SUFFIX = game:GetService("RunService"):IsStudio() and "_Studio" or ""
local PENDING = "Mine_v1_discord_pending" .. SUFFIX
local CLAIMS = "Mine_v1_discord_claims" .. SUFFIX
local LINKS = "Mine_v1_discord_links" .. SUFFIX
local MineDiscordLink = {}

local function pendingStore() return DataStoreService:GetDataStore(PENDING) end
local function claimsStore() return DataStoreService:GetDataStore(CLAIMS) end
local function linksStore() return DataStoreService:GetDataStore(LINKS) end

function MineDiscordLink.normalizeCode(raw)
	return string.upper((tostring(raw or ""):gsub("%s", "")))
end

function MineDiscordLink.getByRoblox(userId)
	local id = tonumber(userId)
	if not id then
		return nil
	end
	local ok, data = pcall(function()
		return linksStore():GetAsync("r_" .. id)
	end)
	if ok and type(data) == "table" and data.discordId ~= nil then
		return data
	end
	return nil
end

function MineDiscordLink.redeem(plr, rawCode)
	if typeof(plr) ~= "Instance" or not plr:IsA("Player") then
		return false, "bad player"
	end
	local code = MineDiscordLink.normalizeCode(rawCode)
	if #code < 4 or #code > 12 then
		return false, "Invalid code"
	end
	local okGet, data = pcall(function()
		return pendingStore():GetAsync(code)
	end)
	if not okGet then
		return false, "DataStore busy — try again"
	end
	if type(data) ~= "table" or data.discordId == nil then
		if type(data) == "table" and data.fromGame then
			return false, "That code is for Discord — type !link " .. code .. " there"
		end
		local okClaim = pcall(function()
			claimsStore():SetAsync(code, {
				robloxUserId = plr.UserId,
				at = DateTime.now().UnixTimestampMillis,
			})
		end)
		if not okClaim then
			return false, "Could not save claim — try again"
		end
		return true, "Code accepted! Wait in Discord — it should say Linked."
	end
	if type(data.expiresAt) == "number" and data.expiresAt < DateTime.now().UnixTimestampMillis then
		pcall(function()
			pendingStore():RemoveAsync(code)
		end)
		return false, "Code expired — run !link again in Discord"
	end
	local discordId = tostring(data.discordId)
	local row = {
		discordId = discordId,
		discordTag = data.discordTag,
		robloxUserId = plr.UserId,
		linkedAt = os.time(),
	}
	local okSet = pcall(function()
		linksStore():SetAsync("d_" .. discordId, row)
		linksStore():SetAsync("r_" .. plr.UserId, row)
		pendingStore():RemoveAsync(code)
	end)
	if not okSet then
		return false, "Failed to save link — try again"
	end
	return true, "Linked to Discord!", discordId
end

--------------------------------------------------------------------------------
-- FLAGS FOR MANUAL REVIEW
--
-- Not an auto-ban and not an auto-kick: the depth watcher that used to eject
-- people was removed because it threw far more honest players out of places
-- they had earned than it ever caught cheats. This just writes a row the
-- Discord bot can read, so a human can look and decide.
--
-- A DataStore rather than a webhook because that is the channel this game
-- already has -- the bot polls Mine_v1_discord_* today, so it needs no HTTP
-- allowlist and no proxy.
--
-- Rate limited per player: a flood of rows is a worse signal than one row, and
-- DataStore write budget is shared with the thing that actually matters (saves).
--------------------------------------------------------------------------------
local FLAGS = "Mine_v1_flags" .. SUFFIX
local function flagsStore() return DataStoreService:GetDataStore(FLAGS) end
local lastFlagAt = {}
local FLAG_COOLDOWN = 60

function MineDiscordLink.flag(kind, userId, name, detail)
	local uid = tonumber(userId) or 0
	local now = os.clock()
	if (lastFlagAt[uid] or -1e9) > (now - FLAG_COOLDOWN) then
		return false
	end
	lastFlagAt[uid] = now
	local row = {
		kind = tostring(kind or "unknown"),
		userId = uid,
		name = tostring(name or "?"),
		detail = detail,
		at = os.time(),
		place = game.PlaceId,
		jobId = game.JobId,
	}
	task.spawn(function()
		pcall(function()
			flagsStore():SetAsync(string.format("%d_%d", row.at, uid), row)
		end)
	end)
	return true
end


return MineDiscordLink
