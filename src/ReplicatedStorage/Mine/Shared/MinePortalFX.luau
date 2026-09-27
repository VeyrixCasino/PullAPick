-- MinePortalFX: brings the portals to life on the client.
--
-- The server builds every portal dead -- swirl, ring, iris and shards all at
-- Transparency 1 with the light disabled -- and waits for a client to light the
-- ones this player has actually earned. That client half did not exist, which is
-- why every gateway in the game was a blank stone slab.
--
-- A closed gate stays closed-looking: dark veil, no glow, no motion. Nothing
-- swirls until the portal is lit, so the animation reads as "this one is open"
-- rather than as decoration.
local MinePortalFX = {}

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local RS = game:GetService("ReplicatedStorage")
local C = require(RS:WaitForChild("Mine"):WaitForChild("Shared"):WaitForChild("MineConfig"))

local FADE = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Where a zone sits in the ladder, so "unlocked" can be compared against the
-- snapshot's maxUnlockedZone.
local zoneIndex = {}
do
	local zones = C.ZONES or {}
	for i, z in ipairs(zones) do
		zoneIndex[z.id] = i
	end
end

local function collect(folder)
	local p = {
		folder = folder,
		veil = folder:FindFirstChild("Veil"),
		swirl = folder:FindFirstChild("Swirl"),
		ring = folder:FindFirstChild("Ring"),
		iris = folder:FindFirstChild("Iris"),
		shards = {},
		arms = {},
		open = nil, -- nil so the first evaluation always applies a state
	}
	-- Shards orbit the doorway's centre, not their own position, so recover
	-- that hub by undoing the placement the builder applied.
	local RADIUS = 10.8
	for _, d in ipairs(folder:GetChildren()) do
		if d.Name == "Shard" and d:IsA("BasePart") then
			local phase = d:GetAttribute("Phase") or 0
			local hub = d.CFrame * CFrame.new(0, -RADIUS, 0)
				* CFrame.Angles(0, 0, -phase * math.pi * 2)
			table.insert(p.shards, { part = d, hub = hub, phase = phase, radius = RADIUS })
		elseif d.Name == "Arm" and d:IsA("BasePart") then
			-- Each arm segment carries the polar coordinates it was placed at,
			-- so the whole spiral can be turned as one rigid body.
			local rad = d:GetAttribute("Radius") or 0
			local ang = d:GetAttribute("Ang") or 0
			local hub = d.CFrame
				* CFrame.Angles(0, 0, -math.rad(38))
				* CFrame.new(0, -rad, 0)
				* CFrame.Angles(0, 0, -ang)
			table.insert(p.arms, { part = d, hub = hub, radius = rad, ang = ang })
		end
	end
	p.light = p.veil and p.veil:FindFirstChildOfClass("PointLight") or nil
	-- WorldBuilder stamps ZoneId/Prestige on the veil part, not the folder.
	local attrHost = p.veil or folder
	p.zoneId = folder:GetAttribute("ZoneId")
		or (attrHost and attrHost:GetAttribute("ZoneId"))
		or (folder.Name and folder.Name:match("^Portal_(.+)$"))
	p.prestige = folder:GetAttribute("Prestige")
		or (attrHost and attrHost:GetAttribute("Prestige"))
		or 0
	-- Live Event Horizon countdown (WorldBuilder stamps EventClock; if the
	-- world is stale we still bind any Timer we find under the portal).
	local clockHost = folder:FindFirstChild("EventClock")
	local bb = clockHost and clockHost:FindFirstChild("EventCountdown")
	p.timerLabel = bb and bb:FindFirstChild("Timer")
	-- The swirl spins about the doorway's own forward axis; cache the still
	-- pose so each frame is an offset from it rather than an accumulating drift.
	if p.swirl then
		p.swirlBase = p.swirl.CFrame
	end
	if p.ring then
		p.ringBase = p.ring.CFrame
	end
	return p
end

--[[
	THE DRESSING (client-only parts, 2026-09-19).

	Players could not find the portals. Lit, the server's "Ring" is a filled
	neon disc in FRONT of the spiral arms: a flat coloured dot that hides the
	one thing that moves, and spinning a symmetric disc shows no motion at all.
	Closed, a gate was a dark slab between dark pillars.

	So each portal gets, locally for this player:
	  a real ring (segments round the doorway) -- dark stone while locked,
	    burning in the zone's colour once open;
	  a bigger four-arm vortex in front of everything, spinning;
	  a particle swirl pulled into the eye (locked to a spinning hub, so the
	    particles spiral rather than just fall inward);
	  a light column into the sky over an open gate, readable from anywhere;
	  a floating name tag: the zone, and "LOCKED -- 11,500 gems" until it opens.
	The server's own flat ring and small arms are kept hidden.
]]
-- Radius 7.1: the doorway is 15 studs between the jambs, so the ring sits
-- inside it instead of vanishing behind the stone at both sides.
local RING_SEGS, RING_R = 28, 7.1
local ARMS, LINKS = 4, 11
local LOCKED_STONE = Color3.fromRGB(74, 72, 84)

local function localPart(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function commas(n)
	local str = tostring(math.floor(tonumber(n) or 0))
	local out = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

local function dress(p)
	if not p.swirlBase or p.folder:FindFirstChild("ClientDress") then
		return
	end
	local zone = C.zoneById and C.zoneById(p.zoneId)
	local col = (zone and zone.color) or (p.swirl and p.swirl.Color) or Color3.fromRGB(150, 140, 255)
	if p.zoneId == "lobby" then
		col = Color3.fromRGB(120, 200, 255)
	end
	-- Some zones are grey or near-black by design; a glow in those reads as a
	-- white smear. Keep the hue, force some colour and full brightness.
	do
		local h, sat, v = col:ToHSV()
		col = Color3.fromHSV(h, math.max(sat, 0.55), math.max(v, 0.95))
	end
	p.col = col
	local folder = Instance.new("Folder")
	folder.Name = "ClientDress"
	folder.Parent = p.folder
	p.dress = folder
	-- The doorway centre, -Z facing out of the gate (undo the disc's stand-up turn).
	local centre = p.swirlBase * CFrame.Angles(0, -math.rad(90), 0) * CFrame.new(0, 0, 0.25)
	p.centre = centre

	p.ringSegs = {}
	local segLen = (2 * math.pi * RING_R / RING_SEGS) * 1.12
	for k = 0, RING_SEGS - 1 do
		local a = k * (2 * math.pi / RING_SEGS)
		table.insert(p.ringSegs, localPart(folder, {
			Name = "RingSeg",
			Size = Vector3.new(segLen, 1.15, 0.9),
			CFrame = centre * CFrame.Angles(0, 0, a) * CFrame.new(0, RING_R, -0.8),
			Color = LOCKED_STONE,
			Material = Enum.Material.Slate,
		}))
	end

	p.vortex = {}
	for arm = 0, ARMS - 1 do
		for i = 0, LINKS - 1 do
			local u = i / (LINKS - 1)
			local rad = 1.1 + u * 5.4
			local ang = arm * (2 * math.pi / ARMS) + u * math.rad(160)
			local seg = localPart(folder, {
				Name = "VortexArm",
				Size = Vector3.new(0.34, 2.4 - u * 1.1, 0.6),
				Color = Color3.new(1, 1, 1):Lerp(col, 0.25 + u * 0.75),
				Material = Enum.Material.Neon,
				Transparency = 1,
			})
			seg.CFrame = centre * CFrame.Angles(0, 0, ang) * CFrame.new(0, rad, -0.62) * CFrame.Angles(0, 0, math.rad(40))
			table.insert(p.vortex, { part = seg, rad = rad, ang = ang })
		end
	end
	p.eye = localPart(folder, {
		Name = "Eye",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 3.2, 3.2),
		CFrame = centre * CFrame.new(0, 0, -0.55) * CFrame.Angles(0, math.rad(90), 0),
		Color = Color3.new(1, 1, 1):Lerp(col, 0.2),
		Material = Enum.Material.Neon,
		Transparency = 1,
	})

	-- The particle hub turns with the vortex; LockedToPart makes the swirl.
	p.hub = localPart(folder, {
		Name = "Hub",
		Size = Vector3.new(0.4, 13, 13),
		CFrame = p.swirlBase,
		Transparency = 1,
	})
	local em = Instance.new("ParticleEmitter")
	em.Name = "Swirl"
	em.Shape = Enum.ParticleEmitterShape.Sphere
	em.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	em.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
	em.LockedToPart = true
	em.Rate = 36
	em.Lifetime = NumberRange.new(1.1, 1.7)
	em.Speed = NumberRange.new(4, 6.5)
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(1, 0.08),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9),
		NumberSequenceKeypoint.new(0.25, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Color = ColorSequence.new(col, Color3.new(1, 1, 1))
	em.LightEmission = 1
	em.Enabled = false
	em.Parent = p.hub
	p.emitter = em

	-- The column over an open gate: the thing you can see from across the map.
	local top = centre * CFrame.new(0, 19, 0)
	p.beam = localPart(folder, {
		Name = "SkyBeam",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(150, 2.6, 2.6),
		CFrame = CFrame.new(top.Position + Vector3.new(0, 75, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = col,
		Material = Enum.Material.Neon,
		Transparency = 1,
	})

	-- Name tag. The plaque only reads from straight ahead; this reads from
	-- anywhere you can see the gate.
	local tagHost = localPart(folder, {
		Name = "TagHost",
		Size = Vector3.new(0.2, 0.2, 0.2),
		CFrame = centre * CFrame.new(0, 31, 0),
		Transparency = 1,
	})
	local bb = Instance.new("BillboardGui")
	bb.Name = "PortalTag"
	bb.Size = UDim2.fromOffset(300, 70)
	bb.AlwaysOnTop = false
	bb.LightInfluence = 0
	bb.MaxDistance = 420
	bb.Parent = tagHost
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 38)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeTransparency = 0.25
	title.Text = string.upper(p.zoneId == "lobby" and "Lobby" or ((zone and zone.name) or tostring(p.zoneId)))
	title.Parent = bb
	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.fromOffset(0, 38)
	sub.Size = UDim2.new(1, 0, 0, 28)
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.TextStrokeTransparency = 0.35
	sub.Text = ""
	sub.Parent = bb
	p.tagTitle = title
	p.tagSub = sub
	p.zone = zone

	-- Keep the server's flat ring and small arms out of the way for good.
	if p.ring then
		p.ring.LocalTransparencyModifier = 1
	end
	for _, s in ipairs(p.arms) do
		s.part.LocalTransparencyModifier = 1
	end
end

--[[
	Start the driver. `getSnapshot` returns the latest server snapshot (or nil
	before the first one arrives).
]]
function MinePortalFX.start(getSnapshot)
	local portals = {}

	local function scan()
		local seen = {}
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("Folder") and d.Name:match("^Portal_") then
				seen[d] = true
				if not portals[d] then
					local p = collect(d)
					pcall(dress, p)
					portals[d] = p
				end
			end
		end
		for f in pairs(portals) do
			if not seen[f] or not f.Parent then
				portals[f] = nil
			end
		end
	end

	local function isOpen(p)
		if p.zoneId == "lobby" then
			return true -- the way home is always lit
		end
		local snapshot = getSnapshot()
		if not snapshot then
			return false
		end
		local idx = zoneIndex[p.zoneId]
		if not idx then
			return false
		end
		local zone = C.zoneById(p.zoneId)
		if zone and zone.limited then
			if snapshot.bigbangOwned then
				return true
			end
			return snapshot.limitedActive == true
		end
		-- Owned islands light regardless of rebirth. minRebirth gates buyZone,
		-- not travel — a stale Prestige=1 attr used to keep Sunscar dark after buy.
		local have = math.max(1, tonumber(snapshot.maxUnlockedZone) or 1)
		return have >= idx
	end

	-- The tag's second line: what it costs, or that it is open. Refreshed on
	-- every pass (gems and rebirth move), not only when the state flips.
	local function tag(p, open)
		if not p.tagSub then
			return
		end
		if p.zoneId == "lobby" then
			p.tagSub.Text = "BACK TO THE LOBBY"
			p.tagSub.TextColor3 = Color3.fromRGB(170, 220, 255)
			return
		end
		if open then
			p.tagSub.Text = "OPEN  ·  WALK IN"
			p.tagSub.TextColor3 = Color3.fromRGB(150, 255, 170)
			return
		end
		local snapshot = getSnapshot()
		local zone = p.zone
		local cost = math.floor(tonumber(zone and zone.buyCost) or 0)
		local needR = math.floor(tonumber(zone and zone.minRebirth) or 0)
		local haveR = math.floor(tonumber(snapshot and (snapshot.prestige or snapshot.rebirth)) or 0)
		local parts = { "LOCKED" }
		if cost > 0 then
			table.insert(parts, commas(cost) .. " gems")
		end
		if needR > haveR then
			table.insert(parts, "Rebirth " .. needR .. "+")
		end
		if zone and zone.limited then
			parts = { "EVENT CLOSED" }
		end
		p.tagSub.Text = table.concat(parts, "  ·  ")
		p.tagSub.TextColor3 = Color3.fromRGB(255, 196, 120)
	end

	local function dressState(p, open)
		if not p.dress then
			return
		end
		for _, seg in ipairs(p.ringSegs or {}) do
			seg.Material = open and Enum.Material.Neon or Enum.Material.Slate
			seg.Color = open and p.col or LOCKED_STONE
		end
		for _, v in ipairs(p.vortex or {}) do
			TweenService:Create(v.part, FADE, { Transparency = open and 0.05 or 1 }):Play()
		end
		if p.eye then
			TweenService:Create(p.eye, FADE, { Transparency = open and 0.1 or 1 }):Play()
		end
		if p.emitter then
			p.emitter.Enabled = open
		end
		if p.beam then
			TweenService:Create(p.beam, FADE, { Transparency = open and 0.62 or 1 }):Play()
		end
		if p.tagTitle then
			p.tagTitle.TextColor3 = open and Color3.new(1, 1, 1):Lerp(p.col, 0.35) or Color3.fromRGB(190, 186, 196)
		end
	end

	local function apply(p, open)
		tag(p, open)
		if p.open == open then
			return
		end
		p.open = open
		dressState(p, open)
		local function fade(part, to)
			if part then
				TweenService:Create(part, FADE, { Transparency = to }):Play()
			end
		end
		if open then
			-- A lit gate: the veil clears to a window, the disc lights, and the
			-- spiral arms burn brighter than it so the turn is legible.
			--
			-- The iris stays hidden while open. It is a dark backdrop, and a
			-- dark backdrop either sits in front of the arms and greys them out
			-- or behind the glow and does nothing; neither earns its place.
			fade(p.veil, 0.72)
			fade(p.iris, 1)
			-- The flat disc hid the arms; the dressing's segmented ring replaces it.
			fade(p.ring, p.dress and 1 or 0.05)
			fade(p.swirl, p.dress and 0.55 or 0.35)
			for _, s in ipairs(p.arms) do
				fade(s.part, p.dress and 1 or 0.08)
			end
			for _, s in ipairs(p.shards) do
				fade(s.part, 0.25)
			end
			if p.light then
				p.light.Enabled = true
				p.light.Range = math.max(p.light.Range, 60)
				TweenService:Create(p.light, FADE, { Brightness = 3 }):Play()
			end
		else
			fade(p.veil, 0.15)
			fade(p.iris, 1)
			fade(p.ring, 1)
			fade(p.swirl, 1)
			for _, s in ipairs(p.arms) do
				fade(s.part, 1)
			end
			for _, s in ipairs(p.shards) do
				fade(s.part, 1)
			end
			if p.light then
				TweenService:Create(p.light, FADE, { Brightness = 0 }):Play()
				task.delay(0.6, function()
					if p.open == false and p.light then
						p.light.Enabled = false
					end
				end)
			end
		end
	end

	scan()
	task.spawn(function()
		while true do
			task.wait(2)
			scan()
			for _, p in pairs(portals) do
				apply(p, isOpen(p))
			end
		end
	end)

	local t = 0
	local lastClockSec = -1
	RunService.RenderStepped:Connect(function(dt)
		t += dt
		local nowSec = math.floor(workspace:GetServerTimeNow())
		local tickClock = nowSec ~= lastClockSec
		if tickClock then
			lastClockSec = nowSec
		end
		for _, p in pairs(portals) do
			if tickClock and p.timerLabel then
				local clock = C.limitedClock and C.limitedClock(nowSec)
				if clock then
					p.timerLabel.Text = clock
					if clock == "CLOSED" then
						p.timerLabel.TextColor3 = Color3.fromRGB(200, 90, 90)
					else
						p.timerLabel.TextColor3 = Color3.fromRGB(255, 230, 140)
					end
				end
			end
			-- Only a lit gate moves. This is the whole point: motion means open.
			-- Far gates skip the per-frame work; their light column still shows.
			local cam = workspace.CurrentCamera
			local near = not (cam and p.centre) or (cam.CFrame.Position - p.centre.Position).Magnitude < 260
			if p.open and near and p.vortex then
				local parts, cfs = {}, {}
				local spin = t * 1.25
				for _, v in ipairs(p.vortex) do
					table.insert(parts, v.part)
					table.insert(cfs, p.centre * CFrame.Angles(0, 0, v.ang + spin)
						* CFrame.new(0, v.rad, -0.62) * CFrame.Angles(0, 0, math.rad(40)))
				end
				workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
				if p.hub then
					p.hub.CFrame = p.swirlBase * CFrame.Angles(t * 2.4, 0, 0)
				end
				if p.beam then
					p.beam.Transparency = 0.6 + math.sin(t * 2.1) * 0.08
				end
				local pulse = 0.5 + 0.5 * math.sin(t * 3)
				for k, seg in ipairs(p.ringSegs or {}) do
					if (k % 5) == (math.floor(t * 6) % 5) then
						seg.Color = p.col:Lerp(Color3.new(1, 1, 1), 0.45 * pulse)
					else
						seg.Color = p.col
					end
				end
			end
			if p.open and near then
				-- The glow disc is symmetric, so turning it shows nothing; the
				-- arms are what carries the motion.
				for _, s in ipairs(p.dress and {} or p.arms) do
					s.part.CFrame = s.hub
						* CFrame.Angles(0, 0, s.ang + t * 1.1)
						* CFrame.new(0, s.radius, 0)
						* CFrame.Angles(0, 0, math.rad(38))
				end
				if p.ring and p.ringBase and not p.dress then
					p.ring.CFrame = p.ringBase * CFrame.Angles(-t * 0.45, 0, 0)
				end
				for _, s in ipairs(p.shards) do
					local a = s.phase * math.pi * 2 + t * 0.8
					-- Orbit the doorway centre in its own plane, bobbing in and
					-- out a little and tumbling as they go.
					s.part.CFrame = s.hub
						* CFrame.Angles(0, 0, a)
						* CFrame.new(0, s.radius + math.sin(a * 2) * 0.55, 0)
						* CFrame.Angles(a * 1.6, 0, 0)
				end
			end
		end
	end)

	return {
		refresh = function()
			for _, p in pairs(portals) do
				apply(p, isOpen(p))
			end
		end,
		count = function()
			local n, open = 0, 0
			for _, p in pairs(portals) do
				n += 1
				if p.open then
					open += 1
				end
			end
			return n, open
		end,
	}
end

return MinePortalFX
