--!strict
-- AFK-only Progression shim: reads/writes idleDay+idleTicks via UpdateAsync so
-- the shared TCGProgression_v1 profile is never wiped.
local DataStoreService = game:GetService('DataStoreService')
local Progression = {}
local recordByUser = {}
local dataStore = nil
pcall(function() dataStore = DataStoreService:GetDataStore('TCGProgression_v1') end)
local function userIdOf(playerOrId)
	if typeof(playerOrId) == 'Instance' then return playerOrId.UserId end
	return tonumber(playerOrId)
end
local function blank()
	return { idleDay = '', idleTicks = 0 }
end
function Progression.ensure(playerOrId)
	local userId = userIdOf(playerOrId)
	if not userId then return nil end
	if not recordByUser[userId] then recordByUser[userId] = blank() end
	return recordByUser[userId]
end
function Progression.get(playerOrId)
	return Progression.ensure(playerOrId) or blank()
end
function Progression.claimIdleTick(player, maxTicksPerDay)
	local record = Progression.ensure(player)
	if not record then return false end
	local today = os.date('!%Y-%m-%d')
	if record.idleDay ~= today then
		record.idleDay = today
		record.idleTicks = 0
	end
	if record.idleTicks >= maxTicksPerDay then return false end
	record.idleTicks += 1
	return true
end
function Progression.idleBudget(playerOrId, maxTicksPerDay)
	local record = Progression.get(playerOrId)
	local today = os.date('!%Y-%m-%d')
	local used = (record.idleDay == today) and (record.idleTicks or 0) or 0
	return used, math.max(0, maxTicksPerDay - used)
end
function Progression.loadAsync(player)
	local record = Progression.ensure(player)
	if not record or not dataStore then return end
	local ok, saved = pcall(function() return dataStore:GetAsync(tostring(player.UserId)) end)
	if ok and type(saved) == 'table' then
		record.idleDay = tostring(saved.idleDay or '')
		record.idleTicks = math.max(0, math.floor(tonumber(saved.idleTicks) or 0))
	end
end
function Progression.saveAsync(playerOrId)
	local userId = userIdOf(playerOrId)
	if not userId or not dataStore then return end
	local record = recordByUser[userId]
	if not record then return end
	pcall(function()
		dataStore:UpdateAsync(tostring(userId), function(old)
			local out = type(old) == 'table' and old or {}
			out.idleDay = record.idleDay
			out.idleTicks = record.idleTicks
			return out
		end)
	end)
end
function Progression.release(playerOrId)
	local userId = userIdOf(playerOrId)
	if userId then recordByUser[userId] = nil end
end
return Progression
