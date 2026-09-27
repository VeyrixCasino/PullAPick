-- Live deepest trackers for the current mine cycle (resets with regen / explicit reset).
-- DIG ONLY — never call from mineshaft / elevator / ride.
-- Per zone overall + per MineDepth section within that zone.

local Players = game:GetService("Players")

local shared = game:GetService("ReplicatedStorage"):WaitForChild("Mine"):WaitForChild("Shared")
local Depth = require(shared:WaitForChild("MineDepth"))

local MineDepthLive = {}

-- [zoneId] = { userId, name, layer, t }
local zoneBest = {}
-- [zoneId][sectionId] = { userId, name, layer, sectionName, t }
local sectionBest = {}
-- [userId] = { [zoneId] = layer }
local playerZone = {}
-- [userId] = { [zoneId] = { [sectionId] = layer } }
local playerSection = {}

local netRef = nil

function MineDepthLive.bindNet(net)
	netRef = net
end

function MineDepthLive.reset()
	table.clear(zoneBest)
	table.clear(sectionBest)
	table.clear(playerZone)
	table.clear(playerSection)
	if netRef then
		pcall(function()
			netRef:FireAllClients("depthLive", { reset = true, at = os.clock() })
		end)
	end
end

local function sectionMeta(layer)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	local s = Depth.sectionFor and Depth.sectionFor(layer)
	if s then
		return tostring(s.id or s.name), tostring(s.name or s.id), s
	end
	local n = (Depth.sectionNumber and Depth.sectionNumber(layer)) or 1
	return "section_" .. tostring(n), "Section " .. tostring(n), nil
end

local function broadcast(payload)
	if not netRef then
		return
	end
	pcall(function()
		netRef:FireAllClients("depthLive", payload)
	end)
end

-- source must be "dig". Rejects mineshaft / elevator / ride / nil.
function MineDepthLive.noteDigCredit(plr, zoneId, layer, source)
	if source ~= "dig" then
		return false, "not_dig"
	end
	if not plr then
		return false, "no_player"
	end
	zoneId = tostring(zoneId or "")
	layer = math.floor(tonumber(layer) or 0)
	if zoneId == "" or layer <= 0 then
		return false, "bad_args"
	end

	local uid = plr.UserId
	local name = plr.DisplayName or plr.Name
	local now = os.clock()
	local sid, sname = sectionMeta(layer)

	playerZone[uid] = playerZone[uid] or {}
	local prevZ = tonumber(playerZone[uid][zoneId]) or 0
	-- Server verify: new deepest is at most the spawned window ahead of last credited break.
	local lead = math.max(tonumber(Depth.DIG_LEAD) or 0, 8)
	if layer > prevZ + lead and prevZ > 0 then
		return false, "skip"
	end
	local zoneImproved = layer > prevZ
	if zoneImproved then
		playerZone[uid][zoneId] = layer
	end

	playerSection[uid] = playerSection[uid] or {}
	playerSection[uid][zoneId] = playerSection[uid][zoneId] or {}
	local prevS = tonumber(playerSection[uid][zoneId][sid]) or 0
	local sectionImproved = layer > prevS
	if sectionImproved then
		playerSection[uid][zoneId][sid] = layer
	end

	local becameZoneBest = false
	local becameSectionBest = false

	if zoneImproved then
		local cur = zoneBest[zoneId]
		if not cur or layer > (tonumber(cur.layer) or 0) then
			zoneBest[zoneId] = { userId = uid, name = name, layer = layer, t = now }
			becameZoneBest = true
		end
	end

	if sectionImproved then
		sectionBest[zoneId] = sectionBest[zoneId] or {}
		local curS = sectionBest[zoneId][sid]
		if not curS or layer > (tonumber(curS.layer) or 0) then
			sectionBest[zoneId][sid] = {
				userId = uid,
				name = name,
				layer = layer,
				sectionId = sid,
				sectionName = sname,
				t = now,
			}
			becameSectionBest = true
		end
	end

	if zoneImproved or sectionImproved then
		broadcast({
			reset = false,
			zoneId = zoneId,
			layer = layer,
			userId = uid,
			name = name,
			sectionId = sid,
			sectionName = sname,
			zoneBest = becameZoneBest and zoneBest[zoneId] or nil,
			sectionBest = becameSectionBest and sectionBest[zoneId][sid] or nil,
			playerZone = playerZone[uid][zoneId],
			playerSection = playerSection[uid][zoneId][sid],
			at = now,
		})
	end

	return true, {
		zoneImproved = zoneImproved,
		sectionImproved = sectionImproved,
		becameZoneBest = becameZoneBest,
		becameSectionBest = becameSectionBest,
		sectionId = sid,
	}
end

function MineDepthLive.snapshotForClient(userId)
	userId = tonumber(userId)
	return {
		myZone = userId and playerZone[userId] or {},
		mySection = userId and playerSection[userId] or {},
		zoneBest = zoneBest,
		-- sections can be large; send only current bests map
		sectionBest = sectionBest,
	}
end

function MineDepthLive.getZoneBest(zoneId)
	return zoneBest[tostring(zoneId or "")]
end

function MineDepthLive.getSectionBest(zoneId, sectionId)
	local z = sectionBest[tostring(zoneId or "")]
	return z and z[tostring(sectionId or "")]
end

-- Top-N for a zone from live playerZone map (current server cycle).
function MineDepthLive.getZoneTop(zoneId, n)
	zoneId = tostring(zoneId or "")
	n = math.clamp(math.floor(tonumber(n) or 10), 1, 50)
	local rows = {}
	for userId, zones in pairs(playerZone) do
		local layer = tonumber(zones[zoneId]) or 0
		if layer > 0 then
			local plr = Players:GetPlayerByUserId(userId)
			table.insert(rows, {
				userId = userId,
				name = plr and (plr.DisplayName or plr.Name) or ("User " .. tostring(userId)),
				value = layer,
				layer = layer,
			})
		end
	end
	table.sort(rows, function(a, b)
		if a.layer == b.layer then
			return a.userId < b.userId
		end
		return a.layer > b.layer
	end)
	while #rows > n do
		table.remove(rows)
	end
	return rows
end

function MineDepthLive.getSectionTop(zoneId, sectionId, n)
	zoneId = tostring(zoneId or "")
	sectionId = tostring(sectionId or "")
	n = math.clamp(math.floor(tonumber(n) or 10), 1, 50)
	local rows = {}
	for userId, zones in pairs(playerSection) do
		local z = zones[zoneId]
		local layer = z and tonumber(z[sectionId]) or 0
		if layer > 0 then
			local plr = Players:GetPlayerByUserId(userId)
			table.insert(rows, {
				userId = userId,
				name = plr and (plr.DisplayName or plr.Name) or ("User " .. tostring(userId)),
				value = layer,
				layer = layer,
				sectionId = sectionId,
			})
		end
	end
	table.sort(rows, function(a, b)
		return a.layer > b.layer
	end)
	while #rows > n do
		table.remove(rows)
	end
	return rows
end

-- Apply profile deepestSection after a verified dig credit.
function MineDepthLive.writeProfile(p, zoneId, layer)
	if type(p) ~= "table" then
		return
	end
	zoneId = tostring(zoneId or "")
	layer = math.floor(tonumber(layer) or 0)
	if zoneId == "" or layer <= 0 then
		return
	end
	local sid = sectionMeta(layer)
	p.deepestSection = type(p.deepestSection) == "table" and p.deepestSection or {}
	p.deepestSection[zoneId] = type(p.deepestSection[zoneId]) == "table" and p.deepestSection[zoneId] or {}
	local prev = tonumber(p.deepestSection[zoneId][sid]) or 0
	if layer > prev then
		p.deepestSection[zoneId][sid] = layer
	end
end

return MineDepthLive
