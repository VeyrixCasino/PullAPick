--[[
	LeaderboardService -- global OrderedDataStore boards + lobby pedestals.
	Stats: prestige, dust (stardust value).
]]
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local shared = game:GetService("ReplicatedStorage"):WaitForChild("Mine"):WaitForChild("Shared")
local MineConfig = require(shared:WaitForChild("MineConfig"))

local LeaderboardService = {}

-- Public boards skip these UserIds (writes, reads, and painted rows).
local BANNED_USER_IDS = {
	[465369561] = true, -- livinghell07
}

function LeaderboardService.isBanned(userId)
	local n = tonumber(userId)
	return n ~= nil and BANNED_USER_IDS[n] == true
end

-- "_Studio" in Studio: test sessions must never reach the live boards.
local STORE_SUFFIX = game:GetService("RunService"):IsStudio() and "_Studio" or ""

-- DataStore reachability, probed ONCE.
--
-- With "Enable Studio Access to API Services" off, every DataStore call throws
-- StudioAccessToApisNotAllowed. This service makes ~50 of them at boot (one
-- RemoveAsync + one GetSortedAsync per board, x12 depth zones, plus the roster
-- scan), so the output window filled with the same error 50 times and buried
-- real warnings -- including, for a while, an actual startup race.
--
-- The probe is a cheap read against a throwaway key. It is NOT "am I in Studio":
-- a Studio session WITH API access enabled probes fine and behaves exactly as
-- live, so enabling the toggle needs no code change. On a live server the probe
-- succeeds and nothing here changes.
local dsOk = nil
local function dataStoresUsable()
	if dsOk == nil then
		local ok = pcall(function()
			DataStoreService:GetDataStore("Mine_v1_probe" .. STORE_SUFFIX):GetAsync("_probe")
		end)
		dsOk = ok
		if not ok then
			-- One line instead of fifty. Says what is off and how to turn it on.
			warn("[Leaderboard] DataStores unreachable -- boards and backfill are "
				.. "skipped this session. In Studio: Game Settings > Security > "
				.. "Enable Studio Access to API Services.")
		end
	end
	return dsOk
end
LeaderboardService.dataStoresUsable = dataStoresUsable
local STORES = {
	prestige = "Mine_v1_lb_prestige" .. STORE_SUFFIX,
	gems = "Mine_v1_lb_gems" .. STORE_SUFFIX,
	dust = "Mine_v1_lb_stardust_value" .. STORE_SUFFIX,
}
local ROSTER_STORE = "Mine_v1_lb_roster" .. STORE_SUFFIX
local META_STORE = "Mine_v1_lb_meta" .. STORE_SUFFIX
local BACKFILL_FLAG = "backfill_v1" -- version bump to re-run
local BACKFILL_DELAY = 3
local BACKFILL_WRITE_PAUSE = 0.15
local LIST_PAGE_SIZE = 100

local KINDS = { "prestige", "gems", "dust" }

local ordered = {}
local cache = { prestige = {}, gems = {}, dust = {} } -- { {userId, value, name}, ... }
local lastPush = {}
-- What each player's boards last received, so an autosave where nothing
-- changed writes NOTHING. The 45s autosave used to push five SetAsyncs per
-- player per tick regardless — that is the DataStore queue warning spam.
local lastSent = {}
local rosterSent = {}
local THROTTLE = 120
local REFRESH = 60
local rosterStore
local metaStore

local function store(kind)
	if not ordered[kind] then
		ordered[kind] = DataStoreService:GetOrderedDataStore(STORES[kind])
	end
	return ordered[kind]
end

local function getRoster()
	if not rosterStore then
		rosterStore = DataStoreService:GetDataStore(ROSTER_STORE)
	end
	return rosterStore
end

local function getMeta()
	if not metaStore then
		metaStore = DataStoreService:GetDataStore(META_STORE)
	end
	return metaStore
end

local function keyOf(userId)
	-- Must match Creator Dashboard key template: Player_{UserId}
	return "Player_" .. tostring(userId)
end

local TradeValue = require(shared:WaitForChild("MineTradeValue"))

-- Wallet dust + recycle value of cards/packs/runes/gear (= inventory net worth).
function LeaderboardService.profileStardustValue(p)
	if type(p) ~= "table" then return 0 end
	local offer = {
		dust = tonumber(p.dust) or 0,
		gems = 0,
		coins = 0,
		cardIds = {},
		packs = {},
		runes = p.runes or {},
		gear = p.gear or {},
		tools = {},
	}
	local byId = {}
	for _, c in ipairs(p.cards or {}) do
		local id = c.serial or c.id
		if id then
			table.insert(offer.cardIds, id)
			byId[id] = c
		end
	end
	for _, pk in ipairs(p.packs or {}) do
		table.insert(offer.packs, pk)
	end
	return TradeValue.total(offer, function(id)
		return byId[id]
	end)
end

function LeaderboardService.recordRoster(userId)
	userId = tonumber(userId)
	if not userId or userId <= 0 or LeaderboardService.isBanned(userId) then
		return
	end
	-- The roster is "has this player ever been here" with a last-seen stamp.
	-- Once per server session per player is plenty; every autosave was noise.
	if rosterSent[userId] then
		return
	end
	rosterSent[userId] = true
	task.spawn(function()
		local ok = pcall(function()
			getRoster():SetAsync(keyOf(userId), os.time())
		end)
		if not ok then
			rosterSent[userId] = nil
		end
	end)
end

--[[
	ORDERED-STORE BUDGET.

	GetSortedAsync has its own small budget: 5 + 2 per player per minute for the
	whole server. The depth boards alone -- eleven zones read every minute by
	refreshDepthBoards, and again by the depth plazas' "coming soon" count --
	spent several times that, and the output filled with "DataStore request was
	added to queue". Every read now asks the budget first and, when it is low,
	serves the last good answer instead of joining the queue.
]]
local function budgetLeft(requestType, reserve)
	local ok, left = pcall(function()
		return DataStoreService:GetRequestBudgetForRequestType(requestType)
	end)
	return (not ok) or ((tonumber(left) or 0) > (reserve or 0))
end
LeaderboardService.budgetLeft = budgetLeft

-- Per-zone deepest OrderedDataStore. Minimal write from creditDeepest.
local depthOrdered = {}
local depthLast = {} -- [userId] = { [zoneId] = value }

--[[
	A depth record only ever goes UP, and is written at most every 30 seconds
	per player. It used to SetAsync on every new layer -- a fast digger is a
	write every couple of seconds, well past the ordered-store budget -- and a
	rebirth (which resets p.deepest) wrote the smaller number over the record.
	Now it queues the best seen and flushDepth writes it with UpdateAsync,
	keeping whichever is larger.
]]
local depthPending = {} -- [userId] = { [zoneId] = best seen, not yet written }
-- Live session depths: merged into board rows so your own meter climbs
-- even while OrderedDataStore / cache lag.
local depthLive = {} -- [userId] = { [zoneId] = deepest }

function LeaderboardService.queueDepth(userId, zoneId, deepest)
	userId = tonumber(userId)
	zoneId = tostring(zoneId or "")
	deepest = math.max(0, math.floor(tonumber(deepest) or 0))
	if not userId or userId <= 0 or zoneId == "" or deepest <= 0 then
		return
	end
	if LeaderboardService.isBanned(userId) then
		return
	end
	depthLive[userId] = depthLive[userId] or {}
	if (depthLive[userId][zoneId] or 0) < deepest then
		depthLive[userId][zoneId] = deepest
	end
	local last = depthLast[userId] and depthLast[userId][zoneId]
	if last and deepest <= last then
		return
	end
	depthPending[userId] = depthPending[userId] or {}
	if (depthPending[userId][zoneId] or 0) < deepest then
		depthPending[userId][zoneId] = deepest
	end
end

function LeaderboardService.flushDepth(onlyUserId)
	-- Keep the queue intact when DataStores are unreachable: enabling API access
	-- mid-session (or shipping to live) then flushes it rather than losing it.
	if not dataStoresUsable() then
		return
	end
	for userId, zones in pairs(depthPending) do
		if LeaderboardService.isBanned(userId) then
			depthPending[userId] = nil
		elseif not onlyUserId or onlyUserId == userId then
			depthPending[userId] = nil
			for zoneId, value in pairs(zones) do
				local storeRef = DataStoreService:GetOrderedDataStore("Mine_v1_lb_depth_" .. zoneId .. STORE_SUFFIX)
				depthOrdered[zoneId] = depthOrdered[zoneId] or storeRef
				local ok, err = pcall(function()
					depthOrdered[zoneId]:UpdateAsync(keyOf(userId), function(old)
						old = tonumber(old) or 0
						if value <= old then
							return nil
						end
						return value
					end)
				end)
				if ok then
					depthLast[userId] = depthLast[userId] or {}
					depthLast[userId][zoneId] = math.max(depthLast[userId][zoneId] or 0, value)
					-- Fresh write: drop the sorted cache so the next paint re-reads.
					depthCache[zoneId] = nil
				else
					warn("[Leaderboard] depth update failed: ", err)
					depthPending[userId] = depthPending[userId] or {}
					depthPending[userId][zoneId] = math.max(depthPending[userId][zoneId] or 0, value)
				end
			end
		end
	end
end

local depthCache = {} -- [zoneId] = { at=, rows= }
local depthBoardParts = {} -- weak-ish list of { part=, zoneId= }
-- Five minutes: a depth board does not need to be fresher, and every zone's
-- board, plaza count and deep board read from this one cache.
local DEPTH_CACHE_TTL = 20
local depthNames = {} -- [userId] = display name, shared by every depth read

local function depthStore(zoneId)
	zoneId = tostring(zoneId or "")
	if zoneId == "" then
		return nil
	end
	if not depthOrdered[zoneId] then
		depthOrdered[zoneId] = DataStoreService:GetOrderedDataStore("Mine_v1_lb_depth_" .. zoneId .. STORE_SUFFIX)
	end
	return depthOrdered[zoneId]
end

function LeaderboardService.getDepthTop(zoneId, n)
	zoneId = tostring(zoneId or "")
	n = math.clamp(math.floor(tonumber(n) or 10), 1, 100)
	if zoneId == "" then
		return {}
	end
	-- No DataStores: hand back whatever is cached (usually nothing) so the boards
	-- still paint as empty instead of firing one refused GetSortedAsync per zone,
	-- per refresh tick, for the life of the session.
	if not dataStoresUsable() then
		local c = depthCache[zoneId]
		return (c and c.rows) or {}
	end
	local cached = depthCache[zoneId]
	local fresh = cached and cached.rows and (os.clock() - (cached.at or 0)) < DEPTH_CACHE_TTL
	local list = nil
	-- Stale beats empty: with the budget low, keep painting the last answer.
	if (cached and cached.rows) and (fresh or not budgetLeft(Enum.DataStoreRequestType.GetSortedAsync, 2)) then
		list = cached.rows
	elseif not budgetLeft(Enum.DataStoreRequestType.GetSortedAsync, 0) then
		list = (cached and cached.rows) or {}
	else
		local storeRef = depthStore(zoneId)
		if not storeRef then
			list = (cached and cached.rows) or {}
		else
			list = {}
			local function depthName(userId)
				local plr = Players:GetPlayerByUserId(userId)
				if plr then
					return plr.DisplayName
				end
				if depthNames[userId] then
					return depthNames[userId]
				end
				local ok, name = pcall(function()
					return Players:GetNameFromUserIdAsync(userId)
				end)
				if ok and name then
					depthNames[userId] = name
				end
				return (ok and name) or ("User " .. tostring(userId))
			end
			-- Always the whole top 100: it is one request either way, and the plaza
			-- count (countDepthAtLeast) reads these same rows.
			local ok, pages = pcall(function()
				return storeRef:GetSortedAsync(false, 100)
			end)
			if ok and pages then
				local shown = 0
				for _, entry in ipairs(pages:GetCurrentPage()) do
					local key = tostring(entry.key or "")
					local uid = tonumber(key:match("(%d+)$")) or tonumber(key)
					if uid and not LeaderboardService.isBanned(uid) then
						shown += 1
						table.insert(list, {
							rank = shown,
							userId = uid,
							value = entry.value,
							-- Names only for the rows a board shows.
							name = (shown <= 10) and depthName(uid) or nil,
						})
					end
				end
				depthCache[zoneId] = { at = os.clock(), rows = list }
			elseif cached and cached.rows then
				list = cached.rows
			end
		end
	end
	list = list or {}
	-- Merge online session depths (higher wins) so the board climbs with you.
	local byUid = {}
	for _, row in ipairs(list) do
		if row.userId then
			byUid[row.userId] = {
				userId = row.userId,
				value = tonumber(row.value) or 0,
				name = row.name,
			}
		end
	end
	local function liveName(userId)
		local plr = Players:GetPlayerByUserId(userId)
		if plr then
			return plr.DisplayName
		end
		return depthNames[userId] or ("User " .. tostring(userId))
	end
	for uid, zones in pairs(depthLive) do
		if LeaderboardService.isBanned(uid) then
			continue
		end
		local live = zones and zones[zoneId]
		if live and live > 0 then
			local cur = byUid[uid]
			if not cur or live > (cur.value or 0) then
				byUid[uid] = {
					userId = uid,
					value = live,
					name = liveName(uid),
				}
			elseif cur and not cur.name then
				cur.name = liveName(uid)
			end
		end
	end
	local merged = {}
	for _, row in pairs(byUid) do
		table.insert(merged, row)
	end
	table.sort(merged, function(a, b)
		if (a.value or 0) == (b.value or 0) then
			return (a.userId or 0) < (b.userId or 0)
		end
		return (a.value or 0) > (b.value or 0)
	end)
	for i, row in ipairs(merged) do
		row.rank = i
		if i <= 10 and not row.name then
			row.name = liveName(row.userId)
		end
	end
	local out = {}
	for i = 1, math.min(n, #merged) do
		out[i] = merged[i]
	end
	return out
end

-- Count unique keys with depth >= minDepth (for Coming Soon 50-player gate).
function LeaderboardService.countDepthAtLeast(zoneId, minDepth)
	zoneId = tostring(zoneId or "")
	minDepth = math.max(1, math.floor(tonumber(minDepth) or 2500))
	if zoneId == "" then
		return 0
	end
	-- The same cached top 100 the boards paint from. The plaza only asks "are
	-- fifty players this deep yet", which the top 100 answers without paging.
	local count = 0
	for _, row in ipairs(LeaderboardService.getDepthTop(zoneId, 100)) do
		if (tonumber(row.value) or 0) >= minDepth then
			count += 1
		else
			break
		end
	end
	return count
end

local function paintDepthBoard(part, zoneId)
	if not part or not part.Parent then
		return
	end
	local gui = part:FindFirstChild("BoardGui")
	local list = gui and gui:FindFirstChild("RankList")
	local title = gui and gui:FindFirstChild("Title")
	if not list then
		return
	end
	local zone = MineConfig.zoneById and MineConfig.zoneById(zoneId)
	local zoneName = (zone and zone.name) or tostring(zoneId)
	if title and title:IsA("TextLabel") then
		title.Text = "Live Depth — " .. zoneName
	end
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	-- Prefer live dig cycle tops (per zone); falls back through getDepthTop merge.
	local rows = nil
	pcall(function()
		local Live = require(script.Parent:WaitForChild("MineDepthLive"))
		rows = Live.getZoneTop(zoneId, 10)
	end)
	if not rows or #rows == 0 then
		rows = LeaderboardService.getDepthTop(zoneId, 10)
	end
	for i = 1, 10 do
		local row = rows[i]
		local frame = Instance.new("TextLabel")
		frame.Name = "Rank_" .. tostring(i)
		frame.Size = UDim2.new(1, 0, 0, 18)
		frame.BackgroundTransparency = 1
		frame.Font = Enum.Font.GothamMedium
		frame.TextSize = 14
		frame.TextColor3 = Color3.fromRGB(230, 230, 240)
		frame.TextXAlignment = Enum.TextXAlignment.Left
		frame.LayoutOrder = i
		if row then
			frame.Text = string.format("#%d  %s  ·  %s", i, tostring(row.name or "—"), tostring(row.layer or row.value or 0))
		else
			frame.Text = string.format("#%d  —", i)
		end
		frame.Parent = list
	end
	-- Section leaders (current live bests for this zone).
	pcall(function()
		local Live = require(script.Parent:WaitForChild("MineDepthLive"))
		local snap = Live.snapshotForClient(nil)
		local secs = snap and snap.sectionBest and snap.sectionBest[tostring(zoneId)]
		if not secs then
			return
		end
		local order = 20
		local hdr = Instance.new("TextLabel")
		hdr.Name = "SectionHdr"
		hdr.Size = UDim2.new(1, 0, 0, 16)
		hdr.BackgroundTransparency = 1
		hdr.Font = Enum.Font.GothamBold
		hdr.TextSize = 12
		hdr.TextColor3 = Color3.fromRGB(255, 210, 120)
		hdr.TextXAlignment = Enum.TextXAlignment.Left
		hdr.Text = "Sections (dig only)"
		hdr.LayoutOrder = order
		hdr.Parent = list
		local rowsS = {}
		for _, rec in pairs(secs) do
			table.insert(rowsS, rec)
		end
		table.sort(rowsS, function(a, b)
			return (tonumber(a.layer) or 0) > (tonumber(b.layer) or 0)
		end)
		for i, rec in ipairs(rowsS) do
			if i > 8 then break end
			order += 1
			local frame = Instance.new("TextLabel")
			frame.Name = "Sec_" .. tostring(i)
			frame.Size = UDim2.new(1, 0, 0, 15)
			frame.BackgroundTransparency = 1
			frame.Font = Enum.Font.Gotham
			frame.TextSize = 12
			frame.TextColor3 = Color3.fromRGB(200, 205, 220)
			frame.TextXAlignment = Enum.TextXAlignment.Left
			frame.LayoutOrder = order
			frame.Text = string.format("%s · %s · %d", tostring(rec.sectionName or rec.sectionId), tostring(rec.name or "—"), tonumber(rec.layer) or 0)
			frame.Parent = list
		end
	end)
	part:SetAttribute("UpdatedAt", os.time())
end

function LeaderboardService.attachDepthBoard(part, zoneId)
	if not part or not part:IsA("BasePart") then
		return
	end
	zoneId = tostring(zoneId or part:GetAttribute("ZoneId") or "")
	if zoneId == "" then
		return
	end
	part:SetAttribute("ZoneId", zoneId)
	table.insert(depthBoardParts, { part = part, zoneId = zoneId })
	task.spawn(function()
		paintDepthBoard(part, zoneId)
	end)
end

function LeaderboardService.refreshDepthBoards()
	-- Drop dead refs, then repaint.
	local alive = {}
	for _, entry in ipairs(depthBoardParts) do
		if entry.part and entry.part.Parent then
			table.insert(alive, entry)
			pcall(paintDepthBoard, entry.part, entry.zoneId)
		end
	end
	depthBoardParts = alive
	-- Also discover any DepthBoard parts not yet attached.
	local world = workspace:FindFirstChild("MineWorld")
	if not world then
		return
	end
	for _, inst in ipairs(world:GetDescendants()) do
		if inst.Name == "DepthBoard" and inst:IsA("BasePart") then
			local zid = tostring(inst:GetAttribute("ZoneId") or "")
			if zid ~= "" then
				local known = false
				for _, e in ipairs(depthBoardParts) do
					if e.part == inst then
						known = true
						break
					end
				end
				if not known then
					LeaderboardService.attachDepthBoard(inst, zid)
				end
			end
		end
	end
end

function LeaderboardService.queueUpdate(userId, prestige, gems, dustValue)
	if LeaderboardService.isBanned(userId) then
		return
	end
	local now = os.clock()
	local prev = lastPush[userId]
	if prev and (now - prev) < THROTTLE then
		return
	end
	lastPush[userId] = now
	LeaderboardService.recordRoster(userId)
	local want = {
		prestige = math.max(0, math.floor(tonumber(prestige) or 0)),
		gems = math.max(0, math.floor(tonumber(gems) or 0)),
		dust = math.max(0, math.floor(tonumber(dustValue) or 0)),
	}
	local sent = lastSent[userId]
	if not sent then
		sent = {}
		lastSent[userId] = sent
	end
	task.spawn(function()
		if not dataStoresUsable() then
			return
		end
		-- Only the boards whose number actually moved get a write.
		for _, kind in ipairs(KINDS) do
			if sent[kind] ~= want[kind] then
				local ok, err = pcall(function()
					store(kind):SetAsync(keyOf(userId), want[kind])
				end)
				if ok then
					sent[kind] = want[kind]
				else
					warn("[Leaderboard] update failed: ", err)
				end
			end
		end
	end)
end

local function pushScores(userId, prestige, gems, dustValue)
	if LeaderboardService.isBanned(userId) then
		return
	end
	store("prestige"):SetAsync(keyOf(userId), math.max(0, math.floor(tonumber(prestige) or 0)))
	store("gems"):SetAsync(keyOf(userId), math.max(0, math.floor(tonumber(gems) or 0)))
	store("dust"):SetAsync(keyOf(userId), math.max(0, math.floor(tonumber(dustValue) or 0)))
	pcall(function()
		getRoster():SetAsync(keyOf(userId), os.time())
	end)
end

local function keyNameOf(entry)
	local ok, kn = pcall(function()
		return entry.KeyName
	end)
	if ok and type(kn) == "string" and kn ~= "" then
		return kn
	end
	if type(entry) == "string" then
		return entry
	end
	return tostring(entry)
end

local function collectUserIdsFromListKeys(profileStore)
	local ids = {}
	local seen = {}
	local ok, pagesOrErr = pcall(function()
		return profileStore:ListKeysAsync("u_", LIST_PAGE_SIZE)
	end)
	if not ok or not pagesOrErr then
		warn("[Leaderboard] ListKeysAsync failed: ", pagesOrErr)
		return ids, false
	end
	local pages = pagesOrErr
	while true do
		for _, entry in ipairs(pages:GetCurrentPage()) do
			local key = keyNameOf(entry)
			local uid = tonumber(tostring(key):match("^u_(%d+)$"))
			if uid and not seen[uid] then
				seen[uid] = true
				table.insert(ids, uid)
			end
		end
		if pages.IsFinished then
			break
		end
		local advOk, advErr = pcall(function()
			pages:AdvanceToNextPageAsync()
		end)
		if not advOk then
			warn("[Leaderboard] ListKeys page advance failed: ", advErr)
			break
		end
		task.wait(0.1)
	end
	return ids, true
end

local function collectUserIdsFromRoster()
	local ids = {}
	local seen = {}
	local ok, pagesOrErr = pcall(function()
		return getRoster():ListKeysAsync("", LIST_PAGE_SIZE)
	end)
	if not ok or not pagesOrErr then
		return ids
	end
	local pages = pagesOrErr
	while true do
		for _, entry in ipairs(pages:GetCurrentPage()) do
			local key = keyNameOf(entry)
			local uid = tonumber(tostring(key))
			if uid and not seen[uid] then
				seen[uid] = true
				table.insert(ids, uid)
			end
		end
		if pages.IsFinished then
			break
		end
		local advOk = pcall(function()
			pages:AdvanceToNextPageAsync()
		end)
		if not advOk then
			break
		end
		task.wait(0.1)
	end
	return ids
end

--[[
	One-shot backfill: Mine_v1 profile keys -> prestige/dust OrderedDataStores.
	Gems board intentionally omitted.
]]
function LeaderboardService.backfillFromAllProfiles()
	-- Without this the scan reports "no profile keys found", which reads as an
	-- empty datastore rather than a refused request. Two misleading warnings.
	if not dataStoresUsable() then
		return { scanned = 0, written = 0, failed = 0, listOk = false, skipped = true }
	end
	local profileName = MineConfig.DATASTORE or "Mine_v1"
	local profileStore = DataStoreService:GetDataStore(profileName)
	local ids, listOk = collectUserIdsFromListKeys(profileStore)
	if not listOk or #ids == 0 then
		local rosterIds = collectUserIdsFromRoster()
		local merged = {}
		local seen = {}
		for _, uid in ipairs(ids) do
			seen[uid] = true
			table.insert(merged, uid)
		end
		for _, uid in ipairs(rosterIds) do
			if not seen[uid] then
				seen[uid] = true
				table.insert(merged, uid)
			end
		end
		ids = merged
		if #ids == 0 then
			warn("[Leaderboard] backfill: no profile keys found")
			return { scanned = 0, written = 0, failed = 0, listOk = listOk }
		end
		print("[Leaderboard] backfill: using roster fallback, ids=", #ids)
	end

	local scanned, written, failed = 0, 0, 0
	print("[Leaderboard] backfill start: keys=", #ids)
	for _, uid in ipairs(ids) do
		scanned += 1
		local ok, profileOrErr = pcall(function()
			return profileStore:GetAsync("u_" .. uid)
		end)
		if ok and type(profileOrErr) == "table" then
			local prestige = profileOrErr.prestige or 0
			local gems = profileOrErr.gems or 0
			local dustValue = LeaderboardService.profileStardustValue(profileOrErr)
			local wOk, wErr = pcall(pushScores, uid, prestige, gems, dustValue)
			if wOk then
				written += 1
			else
				failed += 1
				warn("[Leaderboard] backfill write failed", uid, wErr)
			end
		else
			failed += 1
		end
		if scanned % 25 == 0 then
			print(string.format("[Leaderboard] backfill progress scanned=%d written=%d failed=%d", scanned, written, failed))
		end
		task.wait(BACKFILL_WRITE_PAUSE)
	end
	print(string.format("[Leaderboard] backfill done scanned=%d written=%d failed=%d", scanned, written, failed))
	return { scanned = scanned, written = written, failed = failed, listOk = listOk }
end

function LeaderboardService.maybeBackfillOnce()
	-- Guarded before the flag read: GetAsync on the meta store is itself one of
	-- the refused calls, and its pcall would swallow the cause silently.
	if not dataStoresUsable() then
		return nil
	end
	local already = false
	pcall(function()
		already = getMeta():GetAsync(BACKFILL_FLAG) == true
	end)
	if already then
		print("[Leaderboard] backfill skipped (flag ", BACKFILL_FLAG, ")")
		return nil
	end
	local result = LeaderboardService.backfillFromAllProfiles()
	pcall(function()
		getMeta():SetAsync(BACKFILL_FLAG, true)
	end)
	return result
end

local nameCache = {}
local function displayName(userId)
	local plr = Players:GetPlayerByUserId(userId)
	if plr then
		local prefix = tostring(plr:GetAttribute("NamePrefix") or "")
		local name = prefix .. plr.DisplayName
		nameCache[userId] = name
		return name
	end
	if nameCache[userId] then return nameCache[userId] end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nameCache[userId] = (ok and name) or ("User " .. tostring(userId))
	return nameCache[userId]
end

local function fetchTop(kind, n)
	n = n or 100
	if cache[kind] and #cache[kind] > 0 and not budgetLeft(Enum.DataStoreRequestType.GetSortedAsync, 2) then
		return cache[kind]
	end
	local list = {}
	local ok, pages = pcall(function()
		return store(kind):GetSortedAsync(false, math.min(100, n))
	end)
	if not ok or not pages then
		return cache[kind] or {}
	end
	local page = pages:GetCurrentPage()
	local shown = 0
	for _, entry in ipairs(page) do
		local key = tostring(entry.key or "")
		local uid = tonumber(key:match("Player_(%d+)") or key)
		if uid and not LeaderboardService.isBanned(uid) then
			shown += 1
			table.insert(list, {
				rank = shown,
				userId = uid,
				value = entry.value,
				name = displayName(uid),
			})
		end
	end
	cache[kind] = list
	return list
end

function LeaderboardService.getRank(kind, userId)
	if LeaderboardService.isBanned(userId) then
		return nil, 0
	end
	local list = cache[kind] or {}
	for _, row in ipairs(list) do
		if row.userId == userId then
			return row.rank, row.value
		end
	end
	-- Not in top 100: GetAsync for the value only -- at most once every five
	-- minutes per player per board, and never into a low GetAsync budget
	-- (that budget is shared with loading and saving profiles).
	LeaderboardService._rankCache = LeaderboardService._rankCache or {}
	local key = kind .. ":" .. tostring(userId)
	local hit = LeaderboardService._rankCache[key]
	if hit and (os.clock() - hit.at) < 300 then
		return nil, hit.value
	end
	if not budgetLeft(Enum.DataStoreRequestType.GetAsync, 30) then
		return nil, (hit and hit.value) or 0
	end
	local ok, val = pcall(function()
		return store(kind):GetAsync(keyOf(userId))
	end)
	local value = (ok and val) or (hit and hit.value) or 0
	LeaderboardService._rankCache[key] = { at = os.clock(), value = value }
	return nil, value
end

function LeaderboardService.payloadFor(userId)
	local boards = {}
	for _, kind in ipairs(KINDS) do
		local rows = cache[kind] or {}
		local myRank, myVal = LeaderboardService.getRank(kind, userId)
		boards[kind] = {
			rows = rows,
			you = { rank = myRank, value = myVal or 0 },
		}
	end
	return boards
end

local function findBoardFolder()
	local world = workspace:FindFirstChild("MineWorld")
	local lobby = world and world:FindFirstChild("Lobby")
	return lobby and lobby:FindFirstChild("Leaderboards")
end

local ROW_RANK_COLOR = {
	[1] = Color3.fromRGB(255, 210, 70),
	[2] = Color3.fromRGB(205, 214, 226),
	[3] = Color3.fromRGB(214, 142, 82),
}

local LOBBY_FACE = {
	prestige = { title = "PRESTIGE", sub = "all-time prestige" },
	dust = { title = "STARDUST", sub = "all-time stardust" },
}

-- Event season placement rewards (display on board; payout is separate).
function LeaderboardService.rewardForRank(rank)
	if rank == "101-1000" or rank == "101+" then
		return "100 gems"
	end
	rank = tonumber(rank) or 0
	if rank <= 0 then
		return "—"
	end
	if rank == 1 then
		return "5,000 gems + Event pack"
	end
	if rank == 2 then
		return "2,500 gems + Legendary pack"
	end
	if rank == 3 then
		return "1,500 gems + Legendary pack"
	end
	if rank <= 10 then
		return "750 gems + Rare pack"
	end
	if rank <= 25 then
		return "400 gems"
	end
	if rank <= 50 then
		return "250 gems"
	end
	if rank <= 100 then
		return "150 gems"
	end
	return "100 gems"
end

local function hideBigHeads(folder)
	if not folder then
		return
	end
	for _, kind in ipairs(KINDS) do
		local col = folder:FindFirstChild("Col_" .. kind)
		if not col then
			continue
		end
		for i = 1, 3 do
			local ped = col:FindFirstChild("Pedestal_" .. i)
			if not ped then
				continue
			end
			local av = ped:FindFirstChild("Avatar")
			if av then
				av:Destroy()
			end
			for _, d in ipairs(ped:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Transparency = 1
					d.CanCollide = false
					d.CanQuery = false
				elseif d:IsA("Decal") or d:IsA("Texture") then
					d.Transparency = 1
				elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
					d.Enabled = false
				end
			end
		end
		local board = col:FindFirstChild("Board")
		local gui = board and board:FindFirstChild("BoardGui")
		local podium = gui and gui:FindFirstChild("Top3")
		if podium then
			podium.Visible = false
		end
	end
end

local function formatValue(v)
	local n = tonumber(v) or 0
	if n >= 1e9 then
		return string.format("%.2fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.2fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(math.floor(n))
end

local function headshot(userId)
	return "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=150&h=150"
end

local function paintRankRow(list, row)
	local rank = tonumber(row.rank) or 0
	local top = rank >= 1 and rank <= 3
	local cell = Instance.new("Frame")
	cell.Name = "Rank_" .. tostring(rank)
	cell.LayoutOrder = rank
	cell.Size = UDim2.new(1, 0, 0, 34)
	cell.BackgroundColor3 = top and Color3.fromRGB(52, 44, 34) or Color3.fromRGB(40, 38, 46)
	cell.Parent = list
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 8)
	cc.Parent = cell

	local rankL = Instance.new("TextLabel")
	rankL.Name = "Rank"
	rankL.BackgroundTransparency = 1
	rankL.Size = UDim2.new(0, 44, 1, 0)
	rankL.Position = UDim2.fromOffset(6, 0)
	rankL.Font = Enum.Font.FredokaOne
	rankL.TextSize = (row.rankLabel and #tostring(row.rankLabel) > 2) and 12 or 20
	rankL.TextColor3 = ROW_RANK_COLOR[rank] or Color3.fromRGB(170, 166, 178)
	rankL.Text = tostring(row.rankLabel or rank)
	rankL.Parent = cell

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundColor3 = Color3.fromRGB(70, 66, 78)
	icon.Size = UDim2.fromOffset(24, 24)
	icon.Position = UDim2.new(0, 50, 0.5, -12)
	icon.Image = (row.userId and headshot(row.userId)) or ""
	icon.Parent = cell
	local ic = Instance.new("UICorner")
	ic.CornerRadius = UDim.new(1, 0)
	ic.Parent = icon
	if top then
		local ring = Instance.new("UIStroke")
		ring.Color = ROW_RANK_COLOR[rank]
		ring.Thickness = 2
		ring.Parent = icon
	end

	local nameL = Instance.new("TextLabel")
	nameL.Name = "Name"
	nameL.BackgroundTransparency = 1
	nameL.Position = UDim2.fromOffset(80, 0)
	nameL.Size = UDim2.new(1, -168, 1, 0)
	nameL.Font = Enum.Font.GothamBold
	nameL.TextSize = 15
	nameL.TextXAlignment = Enum.TextXAlignment.Left
	nameL.TextTruncate = Enum.TextTruncate.AtEnd
	nameL.TextColor3 = Color3.fromRGB(236, 232, 224)
	nameL.Text = tostring(row.name or "—")
	nameL.Parent = cell

	local valL = Instance.new("TextLabel")
	valL.Name = "Value"
	valL.BackgroundTransparency = 1
	valL.AnchorPoint = Vector2.new(1, 0)
	valL.Position = UDim2.new(1, -8, 0, 0)
	valL.Size = UDim2.new(0, 80, 1, 0)
	valL.Font = Enum.Font.FredokaOne
	valL.TextSize = row.valueText and 12 or 16
	valL.TextXAlignment = Enum.TextXAlignment.Right
	valL.TextColor3 = Color3.fromRGB(255, 210, 120)
	if row.valueText then
		valL.Text = row.valueText
	elseif row.hideValue then
		valL.Text = ""
	else
		valL.Text = formatValue(row.value)
	end
	valL.Parent = cell
end

local function paintTailRow(list)
	paintRankRow(list, {
		rank = 101,
		rankLabel = "101+",
		name = "Everyone else",
		valueText = "100 gems",
	})
end

local function dressLobbyBoard(col, kind)
	local board = col and col:FindFirstChild("Board")
	if not (board and board:IsA("BasePart")) then
		return
	end
	board.Color = Color3.fromRGB(28, 26, 32)
	board.Material = Enum.Material.SmoothPlastic
	local face = LOBBY_FACE[kind] or { title = string.upper(tostring(kind)), sub = "" }
	local gui = board:FindFirstChild("BoardGui")
	if gui and gui:IsA("SurfaceGui") then
		gui.LightInfluence = 0
		local title = gui:FindFirstChild("Title")
		if not title then
			for _, ch in ipairs(gui:GetChildren()) do
				if ch:IsA("TextLabel") and ch.Name ~= "YouRow" and ch.Name ~= "Zone" then
					title = ch
					break
				end
			end
		end
		if title then
			title.Name = "Title"
			title.BackgroundTransparency = 1
			title.Size = UDim2.new(1, -8, 0, 40)
			title.Position = UDim2.fromOffset(4, 6)
			title.Font = Enum.Font.FredokaOne
			title.TextSize = 36
			title.TextColor3 = Color3.fromRGB(255, 210, 90)
			title.Text = face.title
		end
		local sub = gui:FindFirstChild("Zone")
		if not sub then
			sub = Instance.new("TextLabel")
			sub.Name = "Zone"
			sub.BackgroundTransparency = 1
			sub.Parent = gui
		end
		sub.Size = UDim2.new(1, -8, 0, 22)
		sub.Position = UDim2.fromOffset(4, 44)
		sub.Font = Enum.Font.GothamBold
		sub.TextSize = 16
		sub.TextColor3 = Color3.fromRGB(200, 196, 210)
		sub.Text = face.sub
		local list = gui:FindFirstChild("RankList")
		if list then
			list.Position = UDim2.fromOffset(10, 72)
			list.Size = UDim2.new(1, -20, 1, -132)
			local lay = list:FindFirstChildOfClass("UIListLayout")
			if lay then
				lay.Padding = UDim.new(0, 3)
			end
		end
		local top = gui:FindFirstChild("Top3")
		if top then
			top.Visible = false
		end
	end
	if col:FindFirstChild("Header") then
		return
	end
	local look = board.CFrame
	local W, H = board.Size.X, board.Size.Y
	local function piece(name, size, offset, color, material)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = size
		p.CFrame = look * CFrame.new(offset)
		p.Color = color
		p.Material = material or Enum.Material.Wood
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = col
		return p
	end
	local postH = H + 6
	for _, side in ipairs({ -1, 1 }) do
		piece("Post", Vector3.new(1.4, postH, 1.4),
			Vector3.new(side * (W / 2 + 0.55), -(postH - H) / 2, 0.55),
			Color3.fromRGB(70, 52, 38))
		local lamp = piece("Lamp", Vector3.new(1.1, 1.1, 1.1),
			Vector3.new(side * (W / 2 + 0.55), H / 2 + 1.1, 0),
			Color3.fromRGB(255, 214, 120), Enum.Material.Neon)
		lamp.CanCollide = false
		local light = Instance.new("PointLight")
		light.Range = 16
		light.Brightness = 1.3
		light.Color = Color3.fromRGB(255, 214, 140)
		light.Parent = lamp
	end
	piece("Header", Vector3.new(W + 2.8, 1.2, 1.5),
		Vector3.new(0, H / 2 + 0.45, 0.35),
		Color3.fromRGB(96, 70, 44))
end

function paintBoardLists(folder)
	if not folder then
		return
	end
	hideBigHeads(folder)
	for _, kind in ipairs(KINDS) do
		local col = folder:FindFirstChild("Col_" .. kind)
		dressLobbyBoard(col, kind)
		local board = col and col:FindFirstChild("Board")
		local gui = board and board:FindFirstChild("BoardGui")
		local list = gui and gui:FindFirstChild("RankList")
		if not list then
			continue
		end
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		local rows = cache[kind] or {}
		local n = math.min(100, #rows)
		local lay = list:FindFirstChildOfClass("UIListLayout")
		if lay then
			lay.SortOrder = Enum.SortOrder.LayoutOrder
		end
		-- Full 1–100 list (no podium skip). Rewards drawn on each row.
		for i = 1, n do
			local row = rows[i]
			row.reward = LeaderboardService.rewardForRank(row.rank or i)
			paintRankRow(list, row)
		end
		paintTailRow(list)
		local you = gui and gui:FindFirstChild("YouRow")
		if you and you:IsA("TextLabel") then
			you.TextColor3 = Color3.fromRGB(255, 245, 210)
			you.Font = Enum.Font.GothamBold
			you.TextSize = 15
		end
	end
end



-- Three avatar icons in gold, silver and bronze rings (Top3 is built by
-- WorldBuilder.buildLeaderboards; slots are named Slot_1..Slot_3).
local RANK_COLOR = {
	[1] = Color3.fromRGB(255, 210, 70),
	[2] = Color3.fromRGB(205, 214, 226),
	[3] = Color3.fromRGB(214, 142, 82),
}
function LeaderboardService.paintPodium(podium, rows)
	for rank = 1, 3 do
		local slot = podium:FindFirstChild("Slot_" .. rank)
		if slot then
			local row = rows[rank]
			local icon = slot:FindFirstChild("Icon")
			local nameL = slot:FindFirstChild("Name")
			local valL = slot:FindFirstChild("Value")
			if icon then
				icon.Image = row and row.userId and headshot(row.userId) or ""
				local ring = icon:FindFirstChildOfClass("UIStroke")
				if ring then
					ring.Color = RANK_COLOR[rank]
				end
			end
			if nameL then
				nameL.Text = row and tostring(row.name or "—") or "—"
			end
			if valL then
				valL.Text = row and formatValue(row.value) or ""
			end
		end
	end
end

local function mountAvatar(ped, userId, faceToward)
	local old = ped:FindFirstChild("Avatar")
	if old then old:Destroy() end
	if not userId or userId <= 0 then return end
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromUserIdAsync(userId)
	end)
	if not ok or not model then
		warn("[Leaderboard] avatar failed: ", userId, model)
		return
	end
	model.Name = "Avatar"
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.Massless = true
		elseif d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		hum.JumpHeight = 0
		hum.AutoRotate = false
		pcall(function()
			hum:ChangeState(Enum.HumanoidStateType.Physics)
		end)
	end
	local plate = ped:FindFirstChild("Plate")
	if not plate then
		model:Destroy()
		return
	end
	model.Parent = ped
	local bboxCF, bboxSize = model:GetBoundingBox()
	local standY = plate.Position.Y + plate.Size.Y * 0.5 + bboxSize.Y * 0.5
	local pos = Vector3.new(plate.Position.X, standY, plate.Position.Z)
	local look = faceToward or Vector3.new(0, pos.Y, 0)
	model:PivotTo(CFrame.lookAt(pos, Vector3.new(look.X, pos.Y, look.Z)))
	-- Keep nameplate above the full character
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	local labelHost = ped:FindFirstChild("NameplateHost", true)
	if labelHost and root then
		labelHost.Parent = root
		labelHost.StudsOffset = Vector3.new(0, bboxSize.Y * 0.55, 0)
	end
end

local function applyPedestal(folder, kind, rows)
	if not folder then return end
	local col = folder:FindFirstChild("Col_" .. kind)
	if not col then return end
	for i = 1, 3 do
		local ped = col:FindFirstChild("Pedestal_" .. i)
		if not ped then continue end
		local row = rows[i]
		local newId = row and row.userId or 0
		local prevId = tonumber(ped:GetAttribute("UserId")) or 0
		ped:SetAttribute("UserId", newId)
		ped:SetAttribute("Value", row and row.value or 0)
		ped:SetAttribute("PlayerName", row and row.name or "—")
		ped:SetAttribute("Rank", i)
		local label = ped:FindFirstChild("Nameplate", true)
		if label and label:IsA("TextLabel") then
			if row then
				label.Text = string.format("#%d  %s\n%s", i, row.name, tostring(row.value))
			else
				label.Text = string.format("#%d  —", i)
			end
		end
		if newId ~= prevId then
			task.spawn(function()
				mountAvatar(ped, newId, Vector3.new(0, 0, 0))
			end)
		end
	end
end

--[[
	DEEPEST MINERS. One big board at the far end of every mine -- across the
	pit from the camp, so it is the thing you look at while you dig -- with
	the top ten all-time depths for that mine and their avatars.
]]
local deepBoards = {} -- { { part =, zoneId = } }

local function deepFarPoint(zone)
	local origin = MineConfig.zoneOrigin(zone)
	local world = workspace:FindFirstChild("MineWorld")
	local pits = world and world:FindFirstChild("Pits")
	-- The camp side is where Stand_<zone> sits; the far end is opposite it.
	local stand = pits and pits:FindFirstChild("Stand_" .. zone.id)
	local toward = stand and (stand.Position - origin) or (Vector3.zero - origin)
	toward = Vector3.new(toward.X, 0, toward.Z)
	local axis
	if math.abs(toward.X) > math.abs(toward.Z) then
		axis = Vector3.new(toward.X > 0 and 1 or -1, 0, 0)
	else
		axis = Vector3.new(0, 0, toward.Z > 0 and 1 or -1)
	end
	local half = (MineConfig.GRID or 21) * (MineConfig.BLOCK or 5) * 0.5
	return origin, -axis, half
end

local function buildDeepBoard(zone)
	local world = workspace:FindFirstChild("MineWorld")
	local pits = world and world:FindFirstChild("Pits")
	if not pits then
		return nil
	end
	local existing = pits:FindFirstChild("DeepBoard_" .. zone.id)
	if existing then
		local board = existing:FindFirstChild("Board")
		if board and board:IsA("BasePart") then
			local known = false
			for _, e in ipairs(deepBoards) do
				if e.part == board then
					known = true
					break
				end
			end
			if not known then
				table.insert(deepBoards, { part = board, zoneId = tostring(zone.id) })
			end
			return board
		end
		return nil
	end
	local origin, far, half = deepFarPoint(zone)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { pits:FindFirstChild("Vox_" .. zone.id) }
	-- Stand on something solid: step in from 18 studs past the rim until the
	-- ground is not water (Mistreef's far side is sea past the pier).
	local spot, ground
	for _, out in ipairs({ 18, 15, 12, 9, 6 }) do
		local at = origin + far * (half + out)
		local hit = workspace:Raycast(Vector3.new(at.X, origin.Y + 120, at.Z), Vector3.new(0, -260, 0), params)
		local wet = hit and hit.Instance == workspace.Terrain and hit.Material == Enum.Material.Water
		if hit and not wet and hit.Position.Y > origin.Y - 12 then
			spot, ground = at, hit.Position.Y
			break
		end
	end
	if not spot then
		spot = origin + far * (half + 18)
		ground = origin.Y + 1
	end
	local model = Instance.new("Model")
	model.Name = "DeepBoard_" .. zone.id
	-- Big enough to read from the camp side of the pit.
	local W, H = 40, 26
	local centre = Vector3.new(spot.X, ground + 7 + H / 2, spot.Z)
	local look = CFrame.lookAt(centre, Vector3.new(origin.X, centre.Y, origin.Z))
	local function piece(name, size, cf, color, material)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material or Enum.Material.Wood
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	local postH = 7 + H + 2
	for _, side in ipairs({ -1, 1 }) do
		piece("Post", Vector3.new(1.6, postH, 1.6),
			look * CFrame.new(side * (W / 2 + 0.6), -H / 2 - 7 + postH / 2, 0.4),
			Color3.fromRGB(70, 52, 38))
		local lamp = piece("Lamp", Vector3.new(1.2, 1.2, 1.2),
			look * CFrame.new(side * (W / 2 + 0.6), H / 2 + 2.6, 0), Color3.fromRGB(255, 214, 120), Enum.Material.Neon)
		lamp.CanCollide = false
		local light = Instance.new("PointLight")
		light.Range = 22
		light.Brightness = 1.6
		light.Color = Color3.fromRGB(255, 214, 140)
		light.Parent = lamp
	end
	piece("Header", Vector3.new(W + 3.6, 1.4, 1.8), look * CFrame.new(0, H / 2 + 0.7, 0.2), Color3.fromRGB(96, 70, 44))
	local board = piece("Board", Vector3.new(W, H, 0.8), look, Color3.fromRGB(28, 26, 32), Enum.Material.SmoothPlastic)
	board:SetAttribute("ZoneId", zone.id)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui.Parent = board
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 60)
	title.Position = UDim2.fromOffset(0, 10)
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 50
	title.TextColor3 = Color3.fromRGB(255, 210, 90)
	title.Text = "DEEPEST MINERS"
	title.Parent = gui
	local sub = Instance.new("TextLabel")
	sub.Name = "Zone"
	sub.BackgroundTransparency = 1
	sub.Size = UDim2.new(1, 0, 0, 28)
	sub.Position = UDim2.fromOffset(0, 66)
	sub.Font = Enum.Font.GothamBold
	sub.TextSize = 24
	sub.TextColor3 = Color3.fromRGB(200, 196, 210)
	sub.Text = tostring(zone.name or zone.id) .. "  ·  all-time depth"
	sub.Parent = gui
	local list = Instance.new("Frame")
	list.Name = "RankList"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromOffset(30, 104)
	list.Size = UDim2.new(1, -60, 1, -114)
	list.Parent = gui
	local grid = Instance.new("UIListLayout")
	grid.Padding = UDim.new(0, 3)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = list
	model.Parent = pits
	table.insert(deepBoards, { part = board, zoneId = tostring(zone.id) })
	return board
end

local function paintDeepBoard(part, zoneId)
	if not part or not part.Parent then
		return
	end
	local gui = part:FindFirstChild("BoardGui")
	local list = gui and gui:FindFirstChild("RankList")
	if not list then
		-- BoardGui may live on the Board part or (legacy) on the model.
		gui = part.Parent and part.Parent:FindFirstChild("BoardGui")
		list = gui and gui:FindFirstChild("RankList")
	end
	if not list then
		return
	end
	local rows = LeaderboardService.getDepthTop(zoneId, 10)
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for i = 1, 10 do
		local row = rows[i]
		local cell = Instance.new("Frame")
		cell.Name = "Rank_" .. i
		cell.LayoutOrder = i
		cell.Size = UDim2.new(1, 0, 0, 34)
		cell.BackgroundColor3 = (i <= 3) and Color3.fromRGB(52, 44, 34) or Color3.fromRGB(40, 38, 46)
		cell.Parent = list
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 10)
		cc.Parent = cell
		local rankL = Instance.new("TextLabel")
		rankL.BackgroundTransparency = 1
		rankL.Size = UDim2.new(0, 50, 1, 0)
		rankL.Font = Enum.Font.FredokaOne
		rankL.TextSize = 26
		rankL.TextColor3 = RANK_COLOR[i] or Color3.fromRGB(170, 166, 178)
		rankL.Text = tostring(i)
		rankL.Parent = cell
		local icon = Instance.new("ImageLabel")
		icon.BackgroundColor3 = Color3.fromRGB(70, 66, 78)
		icon.Size = UDim2.fromOffset(28, 28)
		icon.Position = UDim2.new(0, 48, 0.5, -14)
		icon.Image = row and row.userId and headshot(row.userId) or ""
		icon.Parent = cell
		local ic = Instance.new("UICorner")
		ic.CornerRadius = UDim.new(1, 0)
		ic.Parent = icon
		if RANK_COLOR[i] then
			local ring = Instance.new("UIStroke")
			ring.Color = RANK_COLOR[i]
			ring.Thickness = 2
			ring.Parent = icon
		end
		local nameL = Instance.new("TextLabel")
		nameL.BackgroundTransparency = 1
		nameL.Position = UDim2.fromOffset(88, 0)
		nameL.Size = UDim2.new(1, -250, 1, 0)
		nameL.Font = Enum.Font.GothamBold
		nameL.TextSize = 22
		nameL.TextXAlignment = Enum.TextXAlignment.Left
		nameL.TextTruncate = Enum.TextTruncate.AtEnd
		nameL.TextColor3 = Color3.fromRGB(236, 232, 224)
		nameL.Text = row and tostring(row.name or "—") or "—"
		nameL.Parent = cell
		local valL = Instance.new("TextLabel")
		valL.BackgroundTransparency = 1
		valL.AnchorPoint = Vector2.new(1, 0)
		valL.Position = UDim2.new(1, -14, 0, 0)
		valL.Size = UDim2.new(0, 150, 1, 0)
		valL.Font = Enum.Font.FredokaOne
		valL.TextSize = 24
		valL.TextXAlignment = Enum.TextXAlignment.Right
		valL.TextColor3 = Color3.fromRGB(255, 210, 120)
		local depth = tostring(math.floor(tonumber(row and row.value) or 0)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
		valL.Text = row and (depth .. "m") or ""
		valL.Parent = cell
	end
	part:SetAttribute("UpdatedAt", os.time())
end

function LeaderboardService.buildDeepBoards()
	local world = workspace:FindFirstChild("MineWorld") or workspace:WaitForChild("MineWorld", 30)
	if not world then
		warn("[Leaderboard] buildDeepBoards: MineWorld missing")
		return
	end
	local pits = world:FindFirstChild("Pits") or world:WaitForChild("Pits", 10)
	if not pits then
		warn("[Leaderboard] buildDeepBoards: Pits missing")
		return
	end
	for _, zone in ipairs(MineConfig.ZONES or {}) do
		local ok, err = pcall(buildDeepBoard, zone)
		if not ok then
			warn("[Leaderboard] deep board " .. tostring(zone.id) .. ": " .. tostring(err))
		end
	end
end

-- One board per call, round robin: ten boards every minute would spend the
-- whole GetSortedAsync budget (5 + 2 per player per minute) on its own.
local deepNext = 0
local function rediscoverDeepBoards()
	local world = workspace:FindFirstChild("MineWorld")
	local pits = world and world:FindFirstChild("Pits")
	if not pits then
		return
	end
	for _, zone in ipairs(MineConfig.ZONES or {}) do
		local model = pits:FindFirstChild("DeepBoard_" .. zone.id)
		local board = model and model:FindFirstChild("Board")
		if board and board:IsA("BasePart") then
			local known = false
			for _, e in ipairs(deepBoards) do
				if e.part == board then
					known = true
					break
				end
			end
			if not known then
				table.insert(deepBoards, { part = board, zoneId = tostring(zone.id) })
			end
		end
	end
end

function LeaderboardService.paintNextDeepBoard()
	if #deepBoards == 0 then
		rediscoverDeepBoards()
		if #deepBoards == 0 then
			pcall(LeaderboardService.buildDeepBoards)
		end
	end
	if #deepBoards == 0 then
		return
	end
	deepNext = (deepNext % #deepBoards) + 1
	local entry = deepBoards[deepNext]
	if entry and entry.part and entry.part.Parent then
		pcall(paintDeepBoard, entry.part, entry.zoneId)
	end
end

function LeaderboardService.paintDeepBoardForZone(zoneId)
	zoneId = tostring(zoneId or "")
	if zoneId == "" then
		return
	end
	if #deepBoards == 0 then
		rediscoverDeepBoards()
		if #deepBoards == 0 then
			pcall(LeaderboardService.buildDeepBoards)
		end
	end
	for _, entry in ipairs(deepBoards) do
		if entry.zoneId == zoneId and entry.part and entry.part.Parent then
			pcall(paintDeepBoard, entry.part, entry.zoneId)
			return
		end
	end
end

-- Flush this player's pending depth write, then paint that zone's board now.
function LeaderboardService.flushAndPaintDepth(userId, zoneId)
	zoneId = tostring(zoneId or "")
	pcall(LeaderboardService.flushDepth, userId)
	if zoneId ~= "" then
		depthCache[zoneId] = nil
		pcall(LeaderboardService.paintDeepBoardForZone, zoneId)
	end
end

function LeaderboardService.refresh()
	for _, kind in ipairs(KINDS) do
		fetchTop(kind, 100)
	end
	local folder = findBoardFolder()
	if folder then
		paintBoardLists(folder)
		-- Pedestals deferred; RankList SurfaceGui is the live board.
		folder:SetAttribute("UpdatedAt", os.time())
	end
	pcall(LeaderboardService.refreshDepthBoards)
	pcall(function()
		local plazas = script.Parent:FindFirstChild("MineDepthPlazas")
		if plazas then
			local mod = require(plazas)
			if mod.refreshComingSoon then
				mod.refreshComingSoon()
			end
		end
	end)
end

function LeaderboardService.broadcast(net)
	LeaderboardService.refresh()
	for _, plr in ipairs(Players:GetPlayers()) do
		net:FireClient(plr, "leaderboard", LeaderboardService.payloadFor(plr.UserId))
	end
end

function LeaderboardService.purgeBanned()
	-- 16 RemoveAsyncs per banned id (3 boards + roster + 12 depth zones) fired at
	-- boot -- the first block of refused calls in the log. The purge only matters
	-- against stores that exist, so skipping it when they are unreachable loses
	-- nothing: it runs again next boot.
	if not dataStoresUsable() then
		return
	end
	for uid in pairs(BANNED_USER_IDS) do
		local key = keyOf(uid)
		for _, kind in ipairs(KINDS) do
			pcall(function()
				store(kind):RemoveAsync(key)
			end)
		end
		pcall(function()
			getRoster():RemoveAsync(key)
		end)
		for _, z in ipairs(MineConfig.ZONES or {}) do
			pcall(function()
				DataStoreService:GetOrderedDataStore("Mine_v1_lb_depth_" .. z.id .. STORE_SUFFIX):RemoveAsync(key)
			end)
		end
	end
end

function LeaderboardService.start(net)
	task.spawn(function()
		pcall(LeaderboardService.purgeBanned)
	end)
	pcall(function()
		local Live = require(script.Parent:WaitForChild("MineDepthLive"))
		Live.bindNet(net)
	end)
	task.spawn(function()
		pcall(LeaderboardService.buildDeepBoards)
		while true do
			pcall(LeaderboardService.paintNextDeepBoard)
			task.wait(20)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(30)
			pcall(LeaderboardService.flushDepth)
		end
	end)
	task.spawn(function()
		task.wait(BACKFILL_DELAY)
		local okBf, bfErr = pcall(function()
			LeaderboardService.maybeBackfillOnce()
		end)
		if not okBf then
			warn("[Leaderboard] backfill error: ", bfErr)
		end
		-- Refresh rankings after backfill (board UI owned elsewhere).
		while true do
			local ok, err = pcall(function()
				LeaderboardService.broadcast(net)
			end)
			if not ok then warn("[Leaderboard] refresh: ", err) end
			task.wait(REFRESH)
		end
	end)
	Players.PlayerRemoving:Connect(function(plr)
		lastPush[plr.UserId] = nil
		if LeaderboardService._rankCache then
			for _, kind in ipairs(KINDS) do
				LeaderboardService._rankCache[kind .. ":" .. tostring(plr.UserId)] = nil
			end
		end
		task.spawn(function()
			pcall(LeaderboardService.flushDepth, plr.UserId)
		end)
	end)
	game:BindToClose(function()
		pcall(LeaderboardService.flushDepth)
	end)
end

return LeaderboardService