-- MineDigAuth: dig lead + anti-teleport / anti-skip for Mine For Cards.
-- NEVER derive deepest from Y. deepest only updates via creditDeepest after canDig.
-- Unauthorized depth (exploit TP / freefall skip) snaps back to allowed layer or surface.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local shared = game:GetService("ReplicatedStorage"):WaitForChild("Mine"):WaitForChild("Shared")
local Depth = require(shared:WaitForChild("MineDepth"))
local C = require(shared:WaitForChild("MineConfig"))

local MineDigAuth = {}

local trustUntil = {}
local recent = {}
local lastTrusted = {}
local watching = {}
local strike = {}

local TRUST_SEC = 3.5
local ADJ_SEC = 2.0
local CHECK_SEC = 0.15
local MAX_STEP = 70
local STRIKE_SNAP = 2
local POS_SLACK = 1
-- Co-op / shared shafts: a real dig at this column within this window counts as a hole.
local DIG_HOLE_SEC = 20 * 60

local dugColumns = {} -- [zoneId:cx:cz] = { maxLayer, t }

function MineDigAuth.allowTp(p, sec)
	local uid = type(p) == "table" and (p._userId or p.userId) or tonumber(p)
	if not uid then
		return
	end
	trustUntil[uid] = os.clock() + (tonumber(sec) or TRUST_SEC)
end

function MineDigAuth.allowTpUser(userId, sec)
	userId = tonumber(userId)
	if not userId then
		return
	end
	trustUntil[userId] = os.clock() + (tonumber(sec) or TRUST_SEC)
end

local function deepestOf(p, zoneId)
	if type(p) ~= "table" or type(p.deepest) ~= "table" then
		return 0
	end
	zoneId = tostring(zoneId)
	return tonumber(p.deepest[zoneId]) or tonumber(p.deepest[tonumber(zoneId)]) or 0
end

local function unlockedForLayer(p, layer, zoneId)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	p.depthUnlock = p.depthUnlock or {}
	local zi = 1
	if zoneId and C.zoneIndex then
		zi = C.zoneIndex(zoneId) or 1
	elseif p.zoneId and C.zoneIndex then
		zi = C.zoneIndex(p.zoneId) or 1
	end
	zi = math.max(1, math.floor(tonumber(zi) or 1))
	local need = Depth.rebirthForLayer and Depth.rebirthForLayer(layer, zi) or 0
	if need > 0 and not (Depth.meetsRebirth and Depth.meetsRebirth(p, need)) then
		return false, "need_rebirth", need, zi
	end
	-- THE DEPTH GATE. Every other entitlement check in this file funnels through
	-- here -- canDigLayer, maxAllowedLayer, maxStandLayer, canAccessSeam and
	-- grantDepthPass -- so the gate is stated once rather than in six places.
	--
	-- It has to be here and not in canDigLayer alone: grantDepthPass would
	-- otherwise hand out a permanent pass for a seam the player never bought,
	-- and that pass outlives the refusal.
	local gate = Depth.gateForLayer and Depth.gateForLayer(layer)
	if gate and Depth.ownsSeam and not Depth.ownsSeam(p, gate, zi) then
		return false, "need_seam", gate, zi
	end
	return true, nil
end

function MineDigAuth.maxAllowedLayer(p, zoneId)
	if type(p) ~= "table" or not zoneId then
		return 0
	end
	zoneId = tostring(zoneId)
	local deepest = deepestOf(p, zoneId)
	-- Spawned window, not a 4-layer leash: pets/blast/echo/zap that actually
	-- break a voxel in the generated band count toward deepest.
	local lead = math.max(tonumber(C.LAYER_WINDOW) or 0, tonumber(Depth.DIG_LEAD) or 0, 8)
	local maxL = deepest + lead
	-- Walk down from maxL until rebirth band allows (exploit cannot sit past locked band).
	while maxL > deepest do
		local ok = unlockedForLayer(p, maxL, zoneId)
		if ok then
			break
		end
		maxL -= 1
	end
	return math.max(0, maxL)
end

function MineDigAuth.maxStandLayer(p, zoneId)
	if type(p) ~= "table" or not zoneId then
		return 0
	end
	zoneId = tostring(zoneId)
	local deepest = deepestOf(p, zoneId)
	local maxL = deepest + POS_SLACK
	while maxL > deepest do
		local ok = unlockedForLayer(p, math.max(1, maxL), zoneId)
		if ok then
			break
		end
		maxL -= 1
	end
	return math.max(0, maxL)
end

function MineDigAuth.bestUnlockedSeam(p, zoneId)
	if type(p) ~= "table" or not zoneId then
		return 0
	end
	zoneId = tostring(zoneId)
	local deepest = deepestOf(p, zoneId)
	local best = 0
	for _, seam in ipairs(Depth.SEAMS or {}) do
		seam = tonumber(seam) or 0
		if deepest >= seam then
			local ok = unlockedForLayer(p, seam, zoneId)
			if ok then
				best = seam
			end
		end
	end
	return best
end

function MineDigAuth.canAccessSeam(p, zoneId, seam)
	if type(p) ~= "table" then
		return false, "no_profile"
	end
	zoneId = tostring(zoneId or p.zoneId or "")
	seam = math.floor(tonumber(seam) or 0)
	if seam <= 0 then
		return true, nil
	end
	if zoneId == "" then
		return false, "no_zone"
	end
	local deepest = deepestOf(p, zoneId)
	if deepest < seam then
		return false, "need_depth", seam
	end
	local okBand, why, need, zi = unlockedForLayer(p, seam, zoneId)
	if not okBand then
		return false, why or "need_rebirth", need, zi
	end
	return true, nil
end

function MineDigAuth.clampDesk(p, zoneId, requestedDesk)
	local bestSeam = MineDigAuth.bestUnlockedSeam(p, zoneId)
	local okShop, Shop = pcall(function()
		return require(shared:WaitForChild("MineDepthShop"))
	end)
	local req = tostring(requestedDesk or "")
	local reqSeam = nil
	if okShop and Shop and Shop.deskSeam and req ~= "" and req ~= "surface" then
		reqSeam = tonumber(Shop.deskSeam(req))
	end
	if reqSeam and reqSeam > 0 then
		local ok = MineDigAuth.canAccessSeam(p, zoneId, reqSeam)
		if ok then
			return req, reqSeam
		end
	elseif req == "surface" or req == "" then
		return "surface", nil
	end
	if bestSeam <= 0 then
		return "surface", nil
	end
	local desk = (Depth.bandUnlockKey and Depth.bandUnlockKey(bestSeam)) or ("outpost_" .. tostring(bestSeam))
	if okShop and Shop and Shop.deskFromDepth then
		desk = Shop.deskFromDepth(bestSeam) or desk
	end
	return desk, bestSeam
end

function MineDigAuth.layerFromY(posY, zone)
	if not zone then
		return 0
	end
	local origin = C.zoneOrigin and C.zoneOrigin(zone)
	if not origin then
		return 0
	end
	local size = C.BLOCK or 5
	local layer = math.floor((origin.Y - posY) / size + 0.15)
	return math.max(0, layer)
end

--[[
	THE DEPTH PASS

	`deepest` records where a player has physically dug down to. It is a
	breadcrumb, not an entitlement -- and it is the only thing that decides
	whether a layer may be mined or generated.

	That breaks the moment someone arrives at depth WITHOUT walking: an outpost
	elevator, a plaza ride, an admin teleport, a fall down an open shaft. The
	zone will not generate around them (ensureZone only builds to deepest + a
	window) and every swing is refused as "too_deep", which reads as the zone
	never loading in.

	So: check entitlement once, properly, and then stop asking. The rebirth /
	band gate in unlockedForLayer is the real gate and it is untouched -- this
	only stops `deepest` vetoing somewhere the player is already allowed to be.
	Granted passes persist on the profile, so it is asked once per depth, ever.
]]
function MineDigAuth.grantDepthPass(p, zoneId, layer)
	if type(p) ~= "table" or not zoneId then
		return false
	end
	zoneId = tostring(zoneId)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	-- 1. The rebirth / band gate. Authoritative, never cached past this point.
	local ok = unlockedForLayer(p, layer, zoneId)
	if not ok then
		return false
	end
	-- 2. And they must ACTUALLY BE THERE.
	--
	-- Without this the pass is a skeleton key: rebirthForLayer returns 0 for
	-- every layer of zone 1, so the band gate alone would let a brand new
	-- profile mine layer 4999 from the surface and depth progression would
	-- simply stop existing. Arriving is the thing being trusted here -- and
	-- arriving is already policed by the stand limit and the sanctioned-teleport
	-- window -- so the pass only ratifies a position the player already holds.
	local plr = p._userId and Players:GetPlayerByUserId(p._userId)
	local root = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local zone = C.zoneById and C.zoneById(zoneId)
	if not zone then
		return false
	end
	local standing = MineDigAuth.layerFromY(root.Position.Y, zone)
	local reach = math.max(tonumber(C.LAYER_WINDOW) or 0, tonumber(Depth.DIG_LEAD) or 0, 8)
	if math.abs(layer - standing) > reach then
		return false
	end
	p.depthPass = (type(p.depthPass) == "table") and p.depthPass or {}
	local had = tonumber(p.depthPass[zoneId]) or 0
	if layer > had then
		p.depthPass[zoneId] = layer
	end
	return true
end

function MineDigAuth.depthPassOf(p, zoneId)
	if type(p) ~= "table" or not zoneId then
		return 0
	end
	local t = p.depthPass
	if type(t) ~= "table" then
		return 0
	end
	return tonumber(t[tostring(zoneId)]) or 0
end


function MineDigAuth.canDigLayer(p, zoneId, layer)
	if type(p) ~= "table" or not zoneId then
		return false, "no_profile"
	end
	zoneId = tostring(zoneId)
	p._userId = p._userId or p.userId
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	if Depth.isAirGap and Depth.isAirGap(layer) then
		return false, "air_gap"
	end
	local okBand, whyBand = unlockedForLayer(p, layer, zoneId)
	if not okBand then
		return false, whyBand or "locked_band"
	end
	local deepest = deepestOf(p, zoneId)
	local lead = math.max(tonumber(C.LAYER_WINDOW) or 0, tonumber(Depth.DIG_LEAD) or 0, 8)
	if layer <= deepest + lead then
		return true, nil
	end
	local uid = p._userId
	local rec = uid and recent[uid]
	if rec and tostring(rec.zoneId) == zoneId and (os.clock() - (rec.t or 0)) <= ADJ_SEC then
		if math.abs(layer - (rec.layer or 0)) <= 1 then
			return true, nil
		end
	end
	-- Standing somewhere they never dug down to. unlockedForLayer above has
	-- already cleared the rebirth band for this layer, so the only objection
	-- left is the breadcrumb. Clear it once and keep it.
	if layer <= MineDigAuth.depthPassOf(p, zoneId) + lead then
		return true, nil
	end
	if MineDigAuth.grantDepthPass(p, zoneId, layer) then
		return true, nil
	end
	-- Depth no longer refuses a swing either. With the watcher gone there is
	-- nothing keeping a player off a layer, so refusing to let them MINE it
	-- would only mean standing in rock that will not break.
	return true, nil
end

--[[
	WHETHER A DUG LAYER MAY ADVANCE YOUR RECORDED DEPTH.

	Owner, 2026-10-06: the chunk gate is "to ensure hackers dont break one block
	in every chunk and unlock the depth points".

	THIS IS NOT canDigLayer, and the difference is the whole point. canDigLayer
	ends in an unconditional `return true`, deliberately: refusing to let someone
	MINE a block only means they stand in rock that will not break, which is a
	bad experience and stops no exploit, because the exploit is not about
	breaking blocks -- it is about the DEPTH NUMBER that breaking one awards.

	So mining stays permissive and crediting gets strict. Two rules, both on the
	server, both cheap:

	  STEP. A credit may advance depth by at most DIG_LEAD layers past what you
	  have already reached. Without this, breaking a single block at layer 5000
	  credits depth 5000 outright -- which is what the code does today, because
	  every check in canDigLayer sits above a `return true` that always runs.

	  CHUNK. Layer L sits in chunk ceil(L / DIG_CHUNK_LAYERS). You may not credit
	  inside a chunk until you have reached the FLOOR of the one above it, which
	  is the owner's rule stated directly: get to the bottom of chunk one before
	  chunk two counts for anything.

	The step rule alone would stop the jump; the chunk rule is what stops the
	patient version of the same trick, where someone advances DIG_LEAD at a time
	and still skips most of the mine. Together the floor of every chunk has to be
	genuinely touched.

	`reached` counts a depth PASS as well as blocks dug, so riding an elevator or
	a depth plaza is not punished -- those grant the pass precisely so the player
	is allowed to be down there.
]]
function MineDigAuth.canCreditDepth(p, zoneId, layer)
	if type(p) ~= "table" or not zoneId then
		return false, "no_profile"
	end
	zoneId = tostring(zoneId)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	local reached = math.max(deepestOf(p, zoneId), MineDigAuth.depthPassOf(p, zoneId))
	if layer <= reached then
		-- Re-digging ground already reached credits nothing new, and must never
		-- be refused: it is the most normal thing a player does.
		return true, nil
	end
	local lead = math.max(1, tonumber(Depth.DIG_LEAD) or 8)
	if layer > reached + lead then
		return false, "too_deep", reached + lead
	end
	local chunk = math.max(1, math.floor(tonumber(C.DIG_CHUNK_LAYERS) or 50))
	local floorAbove = (math.ceil(layer / chunk) - 1) * chunk
	if reached < floorAbove then
		return false, "chunk_locked", floorAbove
	end
	return true, nil
end

function MineDigAuth.noteDig(p, zoneId, layer, cx, cz)
	if type(p) ~= "table" or not zoneId then
		return
	end
	zoneId = tostring(zoneId)
	layer = math.floor(tonumber(layer) or 1)
	local uid = p._userId
	if uid then
		recent[uid] = {
			zoneId = zoneId,
			layer = layer,
			cx = tonumber(cx),
			cz = tonumber(cz),
			t = os.clock(),
		}
	end
	cx, cz = tonumber(cx), tonumber(cz)
	if cx == nil or cz == nil then
		return
	end
	cx, cz = math.floor(cx), math.floor(cz)
	local key = zoneId .. ":" .. cx .. ":" .. cz
	local e = dugColumns[key]
	local now = os.clock()
	if e then
		e.maxLayer = math.max(tonumber(e.maxLayer) or 0, layer)
		e.t = now
	else
		dugColumns[key] = { maxLayer = layer, t = now }
	end
end

function MineDigAuth.worldToCell(pos, zone)
	if not pos or not zone then
		return nil, nil
	end
	local origin = C.zoneOrigin and C.zoneOrigin(zone)
	if not origin then
		return nil, nil
	end
	local size = C.BLOCK or 5
	local off = ((C.GRID or 21) - 1) * 0.5
	local cx = math.floor((pos.X - origin.X) / size + off + 0.5)
	local cz = math.floor((pos.Z - origin.Z) / size + off + 0.5)
	return cx, cz
end

-- True if someone dug this column (or neighbor) deep enough within DIG_HOLE_SEC.
--[[
	HOW DEEP THE MINE IS, SERVER-WIDE, RIGHT NOW.

	`deepest` is per player: it answers "how far has THIS person dug". That is
	the wrong question for a shared mine. If anyone on this server has sunk a
	shaft to 2,500 in the last twenty minutes then the shaft is there, the rock
	around it is real, and everyone standing in it should be able to mine and
	have the world load around them.

	dugColumns already records maxLayer per column with a 20 minute life
	(DIG_HOLE_SEC); nothing ever read it as a single figure. This is that
	figure. Cached for a couple of seconds because it is asked on every
	generation pass and the table is one entry per column ever dug.
]]
local serverDepthCache = {}
function MineDigAuth.serverDepth(zoneId)
	zoneId = tostring(zoneId or "")
	if zoneId == "" then
		return 0
	end
	local now = os.clock()
	local hit = serverDepthCache[zoneId]
	if hit and (now - hit.t) < 2 then
		return hit.v
	end
	local best = 0
	local prefix = zoneId .. ":"
	for key, e in pairs(dugColumns) do
		if (now - ((e and e.t) or 0)) > DIG_HOLE_SEC then
			-- Expired anyway; drop it so this table cannot grow forever.
			dugColumns[key] = nil
		elseif string.sub(key, 1, #prefix) == prefix then
			local m = tonumber(e.maxLayer) or 0
			if m > best then
				best = m
			end
		end
	end
	serverDepthCache[zoneId] = { v = best, t = now }
	return best
end


function MineDigAuth.holeProvenAt(zoneId, cx, cz, layer)
	zoneId = tostring(zoneId or "")
	cx, cz = tonumber(cx), tonumber(cz)
	layer = math.floor(tonumber(layer) or 0)
	if zoneId == "" or cx == nil or cz == nil then
		return false
	end
	local now = os.clock()
	local need = math.max(0, layer - 2)
	for dx = -1, 1 do
		for dz = -1, 1 do
			local e = dugColumns[zoneId .. ":" .. (cx + dx) .. ":" .. (cz + dz)]
			if e and (now - (e.t or 0)) <= DIG_HOLE_SEC then
				if (tonumber(e.maxLayer) or 0) >= need then
					return true
				end
			end
		end
	end
	return false
end

function MineDigAuth.creditDeepest(p, zoneId, layer)
	if type(p) ~= "table" or not zoneId then
		return false
	end
	zoneId = tostring(zoneId)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	p.deepest = p.deepest or {}
	p.depthUnlock = p.depthUnlock or {}
	local prev = deepestOf(p, zoneId)
	local dug = layer
	if dug <= prev then
		return false
	end
	-- Broken-block CY is deepest. Only reject a skip past the spawned window
	-- (fake layer); pet/blast/echo extra cells in that band count.
	local lead = math.max(tonumber(C.LAYER_WINDOW) or 0, tonumber(Depth.DIG_LEAD) or 0, 8)
	-- The skip clamp used to be measured against this player's own progress,
	-- so dropping into a shaft somebody else sank and mining at the bottom of
	-- it credited nothing -- you could work at 2,500 forever and still be
	-- recorded at 30. Measured against the mine instead.
	local floorHere = math.max(prev, MineDigAuth.serverDepth(zoneId))
	if prev > 0 and dug > floorHere + lead then
		return false
	end
	local gap = Depth.AIR_GAP or 5
	for _, seam in ipairs(Depth.SEAMS or { 500, 1500 }) do
		local gapStart = seam - gap + 1
		if dug >= (gapStart - 1) and dug <= seam then
			layer = math.max(layer, seam)
			local key = Depth.bandUnlockKey and Depth.bandUnlockKey(seam)
			if key == "mid" or key == "deep" then
				p.depthUnlock[key] = true
			end
		end
	end
	p.deepest[zoneId] = layer
	local asNum = tonumber(zoneId)
	if asNum ~= nil and p.deepest[asNum] ~= nil then
		p.deepest[asNum] = nil
	end
	if prev < 500 and layer >= 500 then
		p.depthUnlock.mid = true
	end
	if prev < 1500 and layer >= 1500 then
		p.depthUnlock.deep = true
	end
	return true
end

local function inPitOrPlaza(pos, zone)
	if not zone or not pos then
		return false
	end
	local origin = C.zoneOrigin and C.zoneOrigin(zone) or Vector3.zero
	local pitW = (C.GRID or 21) * (C.BLOCK or 5)
	local half = pitW * 0.5 + 36
	local dx = math.abs(pos.X - origin.X)
	local dz = math.abs(pos.Z - origin.Z)
	if dx > half or dz > half then
		return false
	end
	local top = origin.Y + 40
	local bottom = origin.Y - ((C.MINE1_LAYERS or 5000) + 800) * (C.BLOCK or 5)
	return pos.Y <= top and pos.Y >= bottom
end

local function cfAtLayer(zone, layer, xz)
	local origin = C.zoneOrigin(zone)
	local size = C.BLOCK or 5
	layer = math.max(0, math.floor(tonumber(layer) or 0))
	local y = origin.Y - layer * size + 4
	local x = (xz and xz.X) or origin.X
	local z = (xz and xz.Z) or origin.Z
	return CFrame.new(x, y, z)
end

--[[
	POSITION WATCHER -- EJECTION REMOVED.

	This used to run every heartbeat while a player was underground and yank
	anyone standing past maxStandLayer back up, or to the zone surface. Two
	problems made that unusable:

	  * maxStandLayer is built on `deepest`, a record of where you have DUG. Any
	    legitimate arrival -- outpost elevator, plaza ride, teleport, falling
	    down a shaft -- is instantly "too deep", so it ejected players out of
	    places they were entitled to be, repeatedly.

	  * when p.zoneId was stale, `zone` came out nil and the fallback was
	    surfaceCf(C.ZONES[1]) -- so it did not just eject you, it dropped you in
	    a DIFFERENT ZONE, which then had nothing generated around it.

	Removed at the owner's instruction: cheating gets handled by hand instead.
	The connection is kept purely so the per-player tables still get cleaned up
	when someone leaves, otherwise they would grow for the life of the server.
]]
function MineDigAuth.watchPlayer(plr, getProfile, tpFn, surfaceCfFn)
	if not plr or watching[plr.UserId] then
		return
	end
	watching[plr.UserId] = true
	strike[plr.UserId] = 0
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if plr.Parent then
			return
		end
		if conn then
			conn:Disconnect()
		end
		watching[plr.UserId] = nil
		trustUntil[plr.UserId] = nil
		recent[plr.UserId] = nil
		lastTrusted[plr.UserId] = nil
		strike[plr.UserId] = nil
	end)
end

Players.PlayerRemoving:Connect(function(plr)
	watching[plr.UserId] = nil
	trustUntil[plr.UserId] = nil
	recent[plr.UserId] = nil
	lastTrusted[plr.UserId] = nil
	strike[plr.UserId] = nil
end)

return MineDigAuth
