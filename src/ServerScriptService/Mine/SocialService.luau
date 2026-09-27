--[[
	SocialService -- custom friends, DMs, global chat, group discussions.
	Cross-server via MessagingService + DataStores.
]]
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local SocialService = {}

-- "_Studio" in Studio, so test friends and DMs never reach real players.
local STORE_SUFFIX = game:GetService("RunService"):IsStudio() and "_Studio" or ""
local friendsStore = DataStoreService:GetDataStore("Mine_v1_friends" .. STORE_SUFFIX)
local inboxStore = DataStoreService:GetDataStore("Mine_v1_inbox" .. STORE_SUFFIX)
local groupsStore = DataStoreService:GetDataStore("Mine_v1_groups" .. STORE_SUFFIX)
local userGroupsStore = DataStoreService:GetDataStore("Mine_v1_user_groups" .. STORE_SUFFIX)

local friendsCache = {} -- [userId] = { friends={}, incoming={}, outgoing={} }
local rateGlobal = {} -- [userId] = lastClock
local netRef

local function blankFriends()
	return { friends = {}, incoming = {}, outgoing = {} }
end

local function loadFriends(userId)
	if friendsCache[userId] then return friendsCache[userId] end
	local ok, data = pcall(function()
		return friendsStore:GetAsync(tostring(userId))
	end)
	local f = (ok and type(data) == "table") and data or blankFriends()
	f.friends = f.friends or {}
	f.incoming = f.incoming or {}
	f.outgoing = f.outgoing or {}
	friendsCache[userId] = f
	return f
end

local function saveFriends(userId)
	local f = friendsCache[userId]
	if not f then return end
	pcall(function()
		friendsStore:SetAsync(tostring(userId), f)
	end)
end

local function toast(plr, msg)
	if netRef and plr then
		netRef:FireClient(plr, "toast", msg)
	end
end

-- VIP gamepass name tag (Humanoid.DisplayName / NamePrefix attribute).
local function taggedName(plr)
	if not plr then
		return "Player"
	end
	local prefix = tostring(plr:GetAttribute("NamePrefix") or "")
	return prefix .. plr.DisplayName
end

local function pushFriends(userId)
	local plr = Players:GetPlayerByUserId(userId)
	if not plr or not netRef then return end
	local f = loadFriends(userId)
	local list = {}
	for uidStr in pairs(f.friends) do
		local uid = tonumber(uidStr)
		if uid then
			local onlinePlr = Players:GetPlayerByUserId(uid)
			local online = onlinePlr ~= nil
			local name = online and taggedName(onlinePlr) or ("User " .. uidStr)
			if not online then
				pcall(function()
					name = Players:GetNameFromUserIdAsync(uid)
				end)
			end
			table.insert(list, { userId = uid, name = name, online = online })
		end
	end
	local incoming = {}
	for uidStr in pairs(f.incoming) do
		table.insert(incoming, tonumber(uidStr))
	end
	netRef:FireClient(plr, "socialFriends", {
		friends = list,
		incoming = incoming,
		outgoing = f.outgoing,
	})
end

local function publish(topic, payload)
	pcall(function()
		MessagingService:PublishAsync(topic, payload)
	end)
end

local function filterText(fromPlr, text)
	text = tostring(text or ""):sub(1, 200)
	if text == "" then return nil end
	local ok, filtered = pcall(function()
		return TextService:FilterStringAsync(text, fromPlr.UserId):GetNonChatStringForBroadcastAsync()
	end)
	if ok and filtered then return filtered end
	return text
end

function SocialService.friendRequest(fromPlr, toUserId)
	toUserId = tonumber(toUserId)
	if not toUserId or toUserId == fromPlr.UserId then return end
	local a = loadFriends(fromPlr.UserId)
	local b = loadFriends(toUserId)
	local aks, bks = tostring(fromPlr.UserId), tostring(toUserId)
	if a.friends[bks] then
		toast(fromPlr, "Already friends")
		return
	end
	a.outgoing[bks] = true
	b.incoming[aks] = true
	saveFriends(fromPlr.UserId)
	saveFriends(toUserId)
	pushFriends(fromPlr.UserId)
	pushFriends(toUserId)
	local toPlr = Players:GetPlayerByUserId(toUserId)
	if toPlr then
		toast(toPlr, taggedName(fromPlr) .. " sent a friend request")
	else
		publish("MineFriends", { kind = "request", from = fromPlr.UserId, to = toUserId, name = taggedName(fromPlr) })
	end
	toast(fromPlr, "Friend request sent")
end

function SocialService.friendAccept(plr, fromUserId)
	fromUserId = tonumber(fromUserId)
	if not fromUserId then return end
	local a = loadFriends(plr.UserId)
	local b = loadFriends(fromUserId)
	local aks, bks = tostring(plr.UserId), tostring(fromUserId)
	if not a.incoming[bks] then
		toast(plr, "No request from that player")
		return
	end
	a.incoming[bks] = nil
	a.friends[bks] = true
	b.outgoing[aks] = nil
	b.friends[aks] = true
	saveFriends(plr.UserId)
	saveFriends(fromUserId)
	pushFriends(plr.UserId)
	pushFriends(fromUserId)
	toast(plr, "Friend added")
	local other = Players:GetPlayerByUserId(fromUserId)
	if other then toast(other, taggedName(plr) .. " accepted your friend request") end
	publish("MineFriends", { kind = "accept", from = plr.UserId, to = fromUserId, name = taggedName(plr) })
end

function SocialService.friendDecline(plr, fromUserId)
	fromUserId = tonumber(fromUserId)
	if not fromUserId then return end
	local a = loadFriends(plr.UserId)
	local b = loadFriends(fromUserId)
	local aks, bks = tostring(plr.UserId), tostring(fromUserId)
	a.incoming[bks] = nil
	b.outgoing[aks] = nil
	saveFriends(plr.UserId)
	saveFriends(fromUserId)
	pushFriends(plr.UserId)
end

function SocialService.friendRemove(plr, otherId)
	otherId = tonumber(otherId)
	if not otherId then return end
	local a = loadFriends(plr.UserId)
	local b = loadFriends(otherId)
	local aks, bks = tostring(plr.UserId), tostring(otherId)
	a.friends[bks] = nil
	b.friends[aks] = nil
	saveFriends(plr.UserId)
	saveFriends(otherId)
	pushFriends(plr.UserId)
	pushFriends(otherId)
	toast(plr, "Friend removed")
end

local function threadKey(a, b)
	local x, y = math.min(a, b), math.max(a, b)
	return string.format("%d_%d", x, y)
end

local function areFriends(a, b)
	local f = loadFriends(a)
	return f.friends[tostring(b)] == true
end

function SocialService.sendDM(fromPlr, toUserId, text)
	toUserId = tonumber(toUserId)
	if not toUserId then return end
	if not areFriends(fromPlr.UserId, toUserId) then
		toast(fromPlr, "Friends only")
		return
	end
	local filtered = filterText(fromPlr, text)
	if not filtered then return end
	local key = threadKey(fromPlr.UserId, toUserId)
	local msg = {
		from = fromPlr.UserId,
		to = toUserId,
		name = taggedName(fromPlr),
		text = filtered,
		at = os.time(),
	}
	pcall(function()
		inboxStore:UpdateAsync(key, function(old)
			old = type(old) == "table" and old or { messages = {} }
			old.messages = old.messages or {}
			table.insert(old.messages, msg)
			while #old.messages > 100 do
				table.remove(old.messages, 1)
			end
			return old
		end)
	end)
	local payload = { kind = "dm", msg = msg, thread = key }
	local toPlr = Players:GetPlayerByUserId(toUserId)
	if netRef then
		netRef:FireClient(fromPlr, "socialMsg", payload)
		if toPlr then netRef:FireClient(toPlr, "socialMsg", payload) end
	end
	if not toPlr then
		publish("MineDM", payload)
	end
end

function SocialService.getDM(plr, otherId)
	otherId = tonumber(otherId)
	if not otherId or not areFriends(plr.UserId, otherId) then return end
	local key = threadKey(plr.UserId, otherId)
	local ok, data = pcall(function()
		return inboxStore:GetAsync(key)
	end)
	local messages = (ok and data and data.messages) or {}
	if netRef then
		netRef:FireClient(plr, "socialThread", { thread = key, otherId = otherId, messages = messages })
	end
end

function SocialService.globalChat(fromPlr, text)
	local now = os.clock()
	if rateGlobal[fromPlr.UserId] and (now - rateGlobal[fromPlr.UserId]) < 2 then
		toast(fromPlr, "Slow down")
		return
	end
	rateGlobal[fromPlr.UserId] = now
	local filtered = filterText(fromPlr, text)
	if not filtered then return end
	local payload = {
		kind = "global",
		msg = {
			from = fromPlr.UserId,
			name = taggedName(fromPlr),
			text = filtered,
			at = os.time(),
		},
	}
	publish("MineGlobal", payload)
	-- Local echo to this server
	if netRef then
		for _, p in ipairs(Players:GetPlayers()) do
			netRef:FireClient(p, "socialMsg", payload)
		end
	end
end

local function loadGroup(groupId)
	local ok, data = pcall(function()
		return groupsStore:GetAsync(groupId)
	end)
	return (ok and type(data) == "table") and data or nil
end

local function saveGroup(g)
	pcall(function()
		groupsStore:SetAsync(g.id, g)
	end)
end

function SocialService.createGroup(plr, name, kind)
	name = tostring(name or ""):sub(1, 32)
	if name == "" then name = "Group" end
	kind = (kind == "trade") and "trade" or "general"
	local id = HttpService:GenerateGUID(false)
	local g = {
		id = id,
		name = name,
		kind = kind,
		owner = plr.UserId,
		members = { [tostring(plr.UserId)] = true },
	}
	saveGroup(g)
	pcall(function()
		userGroupsStore:UpdateAsync(tostring(plr.UserId), function(old)
			old = type(old) == "table" and old or {}
			old[id] = true
			return old
		end)
	end)
	if netRef then
		netRef:FireClient(plr, "socialGroup", { action = "created", group = g })
	end
	toast(plr, "Group created: " .. name)
	return g
end

function SocialService.inviteGroup(plr, groupId, toUserId)
	toUserId = tonumber(toUserId)
	local g = loadGroup(groupId)
	if not g or not g.members[tostring(plr.UserId)] then
		toast(plr, "Not in that group")
		return
	end
	if not toUserId then return end
	g.members[tostring(toUserId)] = true
	saveGroup(g)
	pcall(function()
		userGroupsStore:UpdateAsync(tostring(toUserId), function(old)
			old = type(old) == "table" and old or {}
			old[groupId] = true
			return old
		end)
	end)
	local toPlr = Players:GetPlayerByUserId(toUserId)
	if toPlr and netRef then
		netRef:FireClient(toPlr, "socialGroup", { action = "invited", group = g })
		toast(toPlr, taggedName(plr) .. " added you to " .. g.name)
	end
	toast(plr, "Invited")
end

function SocialService.leaveGroup(plr, groupId)
	local g = loadGroup(groupId)
	if not g then return end
	g.members[tostring(plr.UserId)] = nil
	saveGroup(g)
	pcall(function()
		userGroupsStore:UpdateAsync(tostring(plr.UserId), function(old)
			old = type(old) == "table" and old or {}
			old[groupId] = nil
			return old
		end)
	end)
	if netRef then
		netRef:FireClient(plr, "socialGroup", { action = "left", groupId = groupId })
	end
end

function SocialService.groupMessage(plr, groupId, text)
	local g = loadGroup(groupId)
	if not g or not g.members[tostring(plr.UserId)] then
		toast(plr, "Not in that group")
		return
	end
	local filtered = filterText(plr, text)
	if not filtered then return end
	local msg = {
		from = plr.UserId,
		name = taggedName(plr),
		text = filtered,
		at = os.time(),
		groupId = groupId,
	}
	local payload = { kind = "group", groupId = groupId, msg = msg }
	publish("MineGroup", payload)
	if netRef then
		for uidStr in pairs(g.members) do
			local p = Players:GetPlayerByUserId(tonumber(uidStr))
			if p then netRef:FireClient(p, "socialMsg", payload) end
		end
	end
end

function SocialService.listGroups(plr)
	local ok, map = pcall(function()
		return userGroupsStore:GetAsync(tostring(plr.UserId))
	end)
	local groups = {}
	if ok and type(map) == "table" then
		for gid in pairs(map) do
			local g = loadGroup(gid)
			if g then table.insert(groups, g) end
		end
	end
	if netRef then
		netRef:FireClient(plr, "socialGroups", groups)
	end
end

function SocialService.publicProfile(profiles, targetUserId)
	targetUserId = tonumber(targetUserId)
	local p = targetUserId and profiles[targetUserId]
	local plr = targetUserId and Players:GetPlayerByUserId(targetUserId)
	if not p then
		return nil
	end
	local cards = {}
	do
		local shared = game.ReplicatedStorage:FindFirstChild("Mine") and game.ReplicatedStorage.Mine:FindFirstChild("Shared")
		local Cards = shared and shared:FindFirstChild("MineCards") and require(shared.MineCards)
		local list = {}
		for _, c in ipairs(p.cards or {}) do
			table.insert(list, c)
		end
		table.sort(list, function(a, b)
			local sa = (Cards and Cards.boostScore and Cards.boostScore(a)) or 0
			local sb = (Cards and Cards.boostScore and Cards.boostScore(b)) or 0
			if sa ~= sb then
				return sa > sb
			end
			return tostring(a.name or "") < tostring(b.name or "")
		end)
		for i, c in ipairs(list) do
			if i > 40 then
				break
			end
			table.insert(cards, {
				id = c.serial or c.id,
				name = c.name,
				rarityId = c.rarityId,
				variant = c.variant,
				powerLevel = c.powerLevel,
				setId = c.setId,
				shiny = c.shiny and true or nil,
				shadow = c.shadow and true or nil,
			})
		end
	end
	local packs = {}
	for _, pk in ipairs(p.packs or {}) do
		table.insert(packs, {
			packId = pk.packId,
			packName = pk.packName or pk.packId,
			kind = pk.kind,
		})
	end
	return {
		userId = targetUserId,
		name = plr and taggedName(plr) or ("User " .. tostring(targetUserId)),
		online = plr ~= nil,
		prestige = p.prestige or 0,
		gems = p.gems or 0,
		dust = p.dust or 0,
		cardCount = #(p.cards or {}),
		packCount = #(p.packs or {}),
		equipped = p.equipped or {},
		cards = cards,
		packs = packs,
	}
end

function SocialService.onPlayerJoin(plr)
	loadFriends(plr.UserId)
	pushFriends(plr.UserId)
	SocialService.listGroups(plr)
end

function SocialService.onPlayerLeave(userId)
	friendsCache[userId] = nil
	rateGlobal[userId] = nil
end

function SocialService.start(net)
	netRef = net
	local function handleFriend(data)
		local d = data.Data
		if type(d) ~= "table" then return end
		if d.kind == "request" and d.to then
			local plr = Players:GetPlayerByUserId(d.to)
			if plr then
				loadFriends(d.to) -- refresh
				pushFriends(d.to)
				toast(plr, (d.name or "Someone") .. " sent a friend request")
			end
		elseif d.kind == "accept" and d.to then
			local plr = Players:GetPlayerByUserId(d.to)
			if plr then
				pushFriends(d.to)
				toast(plr, (d.name or "Someone") .. " accepted your friend request")
			end
		end
	end
	local function relay(data)
		local d = data.Data
		if type(d) ~= "table" or not netRef then return end
		if d.kind == "dm" and d.msg then
			local to = d.msg.to
			local from = d.msg.from
			for _, uid in ipairs({ to, from }) do
				local plr = Players:GetPlayerByUserId(uid)
				if plr then netRef:FireClient(plr, "socialMsg", d) end
			end
		elseif d.kind == "global" then
			for _, plr in ipairs(Players:GetPlayers()) do
				netRef:FireClient(plr, "socialMsg", d)
			end
		elseif d.kind == "group" and d.groupId then
			local g = loadGroup(d.groupId)
			if g then
				for uidStr in pairs(g.members) do
					local plr = Players:GetPlayerByUserId(tonumber(uidStr))
					if plr then netRef:FireClient(plr, "socialMsg", d) end
				end
			end
		end
	end
	pcall(function() MessagingService:SubscribeAsync("MineFriends", handleFriend) end)
	pcall(function() MessagingService:SubscribeAsync("MineDM", relay) end)
	pcall(function() MessagingService:SubscribeAsync("MineGlobal", relay) end)
	pcall(function() MessagingService:SubscribeAsync("MineGroup", relay) end)
end

return SocialService