--[[
	MineAmbience: the small motions that make a place feel lived in.

	The server builds everything still and tags what should move; this script
	moves it on this client only. Nothing replicates, and nothing a player
	stands on is ever moved.

	  AmbBob    boats, buoys, a bobber   BobAmp, BobSpeed, Roll, Pitch, Phase
	  AmbSway   lanterns, flags, weed    SwayAmp, SwaySpeed, Phase, Hinge
	  AmbSpin   the lighthouse lamp      SpinSpeed (degrees per second)
	  AmbOrbit  gulls overhead           Center, Radius, Speed, Phase, Bank
	  AmbBlink  buoy lights              Period, Duty, Phase
	  AmbZone   a zone's own sky         Radius, Fade, and any of CHANNELS

	Everything moves from the pose the server left it in: a model about its
	pivot, a part about its Hinge (object space, default its top face). Things
	further than NEAR from the camera are left alone.
]]
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local NEAR = 450

local function num(inst, key, default)
	local v = inst:GetAttribute(key)
	return type(v) == "number" and v or default
end

local function poseOf(inst)
	if inst:IsA("Model") then
		return inst:GetPivot()
	elseif inst:IsA("BasePart") then
		return inst.CFrame
	end
	return nil
end

local function setPose(inst, cf)
	if inst:IsA("Model") then
		inst:PivotTo(cf)
	else
		inst.CFrame = cf
	end
end

local READERS = {
	AmbBob = function(inst, m)
		m.amp = num(inst, "BobAmp", 0.2)
		m.speed = num(inst, "BobSpeed", 1)
		m.roll = math.rad(num(inst, "Roll", 0))
		m.pitch = math.rad(num(inst, "Pitch", 0))
	end,
	AmbSway = function(inst, m)
		m.amp = math.rad(num(inst, "SwayAmp", 4))
		m.speed = num(inst, "SwaySpeed", 1)
		local hinge = inst:GetAttribute("Hinge")
		if typeof(hinge) ~= "Vector3" then
			hinge = inst:IsA("BasePart") and Vector3.new(0, inst.Size.Y / 2, 0) or Vector3.zero
		end
		m.hinge = CFrame.new(hinge)
		m.unhinge = CFrame.new(-hinge)
	end,
	AmbSpin = function(inst, m)
		m.speed = math.rad(num(inst, "SpinSpeed", 30))
	end,
	AmbOrbit = function(inst, m)
		local c = inst:GetAttribute("Center")
		m.center = typeof(c) == "Vector3" and c or m.base.Position
		m.radius = num(inst, "Radius", 40)
		m.speed = num(inst, "Speed", 0.3)
		m.bank = math.rad(num(inst, "Bank", 15))
	end,
	AmbBlink = function(inst, m)
		m.period = math.max(0.2, num(inst, "Period", 3))
		m.duty = num(inst, "Duty", 0.3)
		m.light = inst:FindFirstChildWhichIsA("Light")
	end,
}

local movers = {}

for kind in pairs(READERS) do
	local function add(inst)
		local base = poseOf(inst)
		if not base then
			return
		end
		local m = { kind = kind, base = base, phase = num(inst, "Phase", 0) }
		READERS[kind](inst, m)
		movers[inst] = m
	end
	for _, inst in ipairs(CollectionService:GetTagged(kind)) do
		add(inst)
	end
	CollectionService:GetInstanceAddedSignal(kind):Connect(add)
	CollectionService:GetInstanceRemovedSignal(kind):Connect(function(inst)
		movers[inst] = nil
	end)
end

local function step(inst, m, clock, eye)
	local kind = m.kind
	if kind == "AmbOrbit" then
		if (m.center - eye).Magnitude > NEAR + m.radius then
			return
		end
		local dirSign = (m.speed >= 0) and 1 or -1
		local a = m.phase + clock * m.speed
		local pos = m.center + Vector3.new(math.cos(a) * m.radius, math.sin(clock * 0.6 + m.phase) * 1.5, math.sin(a) * m.radius)
		local heading = Vector3.new(-math.sin(a), 0, math.cos(a)) * dirSign
		setPose(inst, CFrame.lookAt(pos, pos + heading) * CFrame.Angles(0, 0, -m.bank * dirSign))
		return
	end
	if (m.base.Position - eye).Magnitude > NEAR then
		return
	end
	if kind == "AmbBob" then
		local t = clock * m.speed + m.phase
		setPose(inst, m.base * CFrame.new(0, math.sin(t) * m.amp, 0)
			* CFrame.Angles(math.sin(t * 0.83 + 1.1) * m.pitch, 0, math.sin(t * 0.91) * m.roll))
	elseif kind == "AmbSway" then
		local t = clock * m.speed + m.phase
		setPose(inst, m.base * m.hinge * CFrame.Angles(math.sin(t) * m.amp, 0, math.sin(t * 0.77 + 0.9) * m.amp * 0.6) * m.unhinge)
	elseif kind == "AmbSpin" then
		setPose(inst, m.base * CFrame.Angles(0, clock * m.speed + m.phase, 0))
	elseif kind == "AmbBlink" then
		local on = ((clock + m.phase) % m.period) < m.period * m.duty
		if on ~= m.lit then
			m.lit = on
			inst.Transparency = on and 0 or 0.75
			if m.light then
				m.light.Enabled = on
			end
		end
	end
end

--------------------------------------------------------------------------------
-- A zone's own sky. Each AmbZone marker names the channels it changes; inside
-- its Radius they are fully the zone's, across Fade they ease back to whatever
-- the world had. If something else changes a channel while we are in charge,
-- that becomes the new "whatever the world had".
--------------------------------------------------------------------------------

local CHANNELS = {
	{ "atmo", "Density" }, { "atmo", "Haze" }, { "atmo", "Glare" }, { "atmo", "Offset" },
	{ "atmo", "Color" }, { "atmo", "Decay" },
	{ "terrain", "WaterColor" }, { "terrain", "WaterTransparency" }, { "terrain", "WaterReflectance" },
	{ "terrain", "WaterWaveSize" }, { "terrain", "WaterWaveSpeed" },
	{ "lighting", "ClockTime" }, { "lighting", "Brightness" }, { "lighting", "OutdoorAmbient" },
	{ "lighting", "Ambient" }, { "lighting", "ExposureCompensation" },
	{ "sky", "MoonAngularSize" }, { "sky", "StarCount" },
}

local function host(which)
	if which == "atmo" then
		return Lighting:FindFirstChildOfClass("Atmosphere")
	elseif which == "terrain" then
		return workspace.Terrain
	elseif which == "sky" then
		return Lighting:FindFirstChildOfClass("Sky")
	end
	return Lighting
end

local baseline, written = {}, {}
local starShell

local function syncStarShell(on, eye)
	if not on then
		if starShell then
			starShell:Destroy()
			starShell = nil
		end
		return
	end
	if not starShell then
		local model = Instance.new("Model")
		model.Name = "LocalStarShell"
		local rng = Random.new(11)
		for _ = 1, 200 do
			local p = Instance.new("Part")
			p.Name = "Star"
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Material = Enum.Material.Neon
			p.Color = Color3.fromRGB(236, 240, 255)
			local s = 0.12 + rng:NextNumber() * 0.2
			p.Size = Vector3.new(s, s, s)
			local dir = Vector3.new(rng:NextNumber() - 0.5, rng:NextNumber() * 0.5 + 0.15, rng:NextNumber() - 0.5)
			if dir.Magnitude < 0.001 then
				dir = Vector3.new(0, 1, 0)
			end
			dir = dir.Unit
			p.CFrame = CFrame.new(dir * (90 + rng:NextNumber() * 160))
			p.Parent = model
		end
		model.Parent = workspace
		starShell = model
	end
	if starShell and eye then
		starShell:PivotTo(CFrame.new(eye))
	end
end

local function blend(a, b, w)
	if typeof(a) == "Color3" then
		return a:Lerp(b, w)
	end
	return a + (b - a) * w
end

local function updateSky(eye)
	local best, weight = nil, 0
	for _, p in ipairs(CollectionService:GetTagged("AmbZone")) do
		if p:IsA("BasePart") then
			local fade = math.max(1, num(p, "Fade", 100))
			local flat = Vector3.new(eye.X - p.Position.X, 0, eye.Z - p.Position.Z).Magnitude
			local k = math.clamp((flat - num(p, "Radius", 300)) / fade, 0, 1)
			local w = 1 - k * k * (3 - 2 * k)
			if w > weight then
				best, weight = p, w
			end
		end
	end
	for i, ch in ipairs(CHANNELS) do
		local obj = host(ch[1])
		if obj then
			local prop = ch[2]
			local current = obj[prop]
			if written[i] == nil or current ~= written[i] then
				baseline[i] = current -- first look, or someone else changed it
			end
			local target = best and best:GetAttribute(prop)
			local want = baseline[i]
			if target ~= nil and typeof(target) == typeof(want) and weight > 0 then
				want = blend(baseline[i], target, weight)
			end
			if want ~= current then
				obj[prop] = want
			end
			written[i] = obj[prop]
		end
	end
	local inHorizon = false
	if best and weight > 0 then
		local node = best
		while node and node ~= workspace do
			if node:GetAttribute("ZoneId") == "bigbang" then
				inHorizon = true
				break
			end
			node = node.Parent
		end
	end
	syncStarShell(inHorizon, eye)
end

--------------------------------------------------------------------------------
-- EVENT HORIZON'S BLACK HOLE (AmbBlackHole), and the screens that count down to
-- it (AmbCountdown). The cycle is read off server time, so every client -- and
-- MineServer, which remakes the mine at the same instant -- agrees on it:
--
--   0 - 6 s          reforming out of nothing after the blast
--   6 s - collapse   swelling, the disk turning faster as it grows
--   last `Collapse`  shuddering, spinning up, then falling in on itself
--   next cycle       the blast: a nova, a shockwave, a white-out, a shake
--------------------------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local function smooth(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local holes, screens = {}, {}

local REFORM = 6
local WHITE_HOT = Color3.fromRGB(214, 232, 255)
local AMBER = Color3.fromRGB(255, 176, 70)

-- Screen effects for the collapse and the blast. Our own instances, so nothing
-- the zone sky blends (updateSky) is ever touched.
local grade, blur, bloom
local function fx()
	if not (grade and grade.Parent) then
		grade = Instance.new("ColorCorrectionEffect")
		grade.Name = "HorizonGrade"
		grade.Parent = Lighting
	end
	if not (blur and blur.Parent) then
		blur = Instance.new("BlurEffect")
		blur.Name = "HorizonBlur"
		blur.Size = 0
		blur.Parent = Lighting
	end
	if not (bloom and bloom.Parent) then
		bloom = Instance.new("BloomEffect")
		bloom.Name = "HorizonBloom"
		bloom.Intensity = 0
		bloom.Size = 48
		bloom.Threshold = 0.85
		bloom.Parent = Lighting
	end
end

local flashGui
local function whiteOut(hold, fade)
	local player = Players.LocalPlayer
	local pg = player and player:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return
	end
	if not (flashGui and flashGui.Parent) then
		flashGui = Instance.new("ScreenGui")
		flashGui.Name = "HorizonFlash"
		flashGui.IgnoreGuiInset = true
		flashGui.ResetOnSpawn = false
		flashGui.DisplayOrder = 1000
		local fr = Instance.new("Frame")
		fr.Name = "White"
		fr.Size = UDim2.fromScale(1, 1)
		fr.BackgroundColor3 = Color3.new(1, 1, 1)
		fr.BackgroundTransparency = 1
		fr.BorderSizePixel = 0
		fr.Parent = flashGui
		flashGui.Parent = pg
	end
	local fr = flashGui.White
	TweenService:Create(fr, TweenInfo.new(0.05, Enum.EasingStyle.Linear), { BackgroundTransparency = 0 }):Play()
	task.delay(0.05 + hold, function()
		TweenService:Create(fr, TweenInfo.new(fade, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
	end)
end

-- One shake for the whole client: the steady tremor while it comes apart, or
-- the blast decaying, whichever is bigger right now.
local collapseShake, blastUntil, blastDur, blastAmp = 0, 0, 1, 0
RunService:BindToRenderStep("MineAmbienceShake", Enum.RenderPriority.Camera.Value + 1, function()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local left = blastUntil - os.clock()
	local amp = math.max(collapseShake, (left > 0) and blastAmp * (left / blastDur) ^ 1.5 or 0)
	if amp > 0.001 then
		cam.CFrame = cam.CFrame * CFrame.new((math.random() - 0.5) * amp, (math.random() - 0.5) * amp, 0)
			* CFrame.Angles(0, 0, (math.random() - 0.5) * amp * 0.035)
	end
end)

local function addHole(m)
	local core = m:FindFirstChild("Singularity")
	local disk = m:FindFirstChild("Disk")
	if not (core and disk) then
		return
	end
	local R = num(m, "Radius", 64)
	local h = {
		pivot = m:GetPivot(), diskPivot = disk:GetPivot(), spin = 0, scale = -1, core = core,
		cycle = num(m, "Cycle", 1200), radius = R, flashRadius = num(m, "FlashRadius", 2600),
		collapse = num(m, "Collapse", 14), implode = num(m, "Implode", 1), minScale = num(m, "MinScale", 0.2),
		burst = core:FindFirstChild("Burst"), parts = {}, guis = {}, frames = {}, jets = {},
		novae = {}, waves = {}, emitters = {},
	}
	local nova, shock = m:FindFirstChild("Nova"), m:FindFirstChild("Shockwave")
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d ~= nova and d ~= shock then
			local inDisk = d:IsDescendantOf(disk)
			local rel = (inDisk and h.diskPivot or h.pivot):ToObjectSpace(d.CFrame)
			table.insert(h.parts, { part = d, pos = rel.Position, rot = rel.Rotation, size = d.Size, disk = inDisk,
				color = d.Color, transparency = d.Transparency, glow = d.Material == Enum.Material.Neon })
		elseif d:IsA("BillboardGui") then
			table.insert(h.guis, { gui = d, size = d.Size })
		elseif d:IsA("Frame") then
			table.insert(h.frames, { frame = d, color = d.BackgroundColor3, transparency = d.BackgroundTransparency })
		elseif d:IsA("ParticleEmitter") and d.Name ~= "Burst" then
			table.insert(h.emitters, { emitter = d, speed = d.Speed, rate = d.Rate, size = d.Size, disk = d:IsDescendantOf(disk) })
		end
	end
	-- The blast is layered: a white flash sphere, a pale blue shell a beat behind
	-- it, and three shock rings in different planes. Extra copies live only on
	-- this client.
	if nova then
		table.insert(h.novae, { part = nova, max = 2040, dur = 2.2, delay = 0 })
		local shell = nova:Clone()
		shell.Name = "NovaShell"
		shell.Color = Color3.fromRGB(214, 226, 255)
		shell.Parent = m
		table.insert(h.novae, { part = shell, max = 1750, dur = 3.4, delay = 0.22 })
	end
	if shock then
		table.insert(h.waves, { part = shock, max = 2000, dur = 1.5, delay = 0.03 })
		for i, turn in ipairs({ CFrame.Angles(math.rad(70), 0, 0), CFrame.Angles(0, math.rad(60), math.rad(55)) }) do
			local ring = shock:Clone()
			ring.Name = "ShockwaveEcho"
			ring.CFrame = shock.CFrame * turn
			ring.Color = (i == 1) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(196, 210, 255)
			ring.Parent = m
			table.insert(h.waves, { part = ring, max = 1900 - i * 150, dur = 1.9 + i * 0.6, delay = 0.12 * i })
		end
	end
	holes[m] = h
end

-- Lightning crawling over it while it tears itself apart.
local function arcsFor(h)
	if h.arcs then
		return h.arcs
	end
	h.arcs = {}
	for i = 1, 12 do
		local a0 = Instance.new("Attachment")
		a0.Parent = h.core
		local a1 = Instance.new("Attachment")
		a1.Parent = h.core
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1 = a0, a1
		beam.LightEmission, beam.LightInfluence = 1, 0
		beam.FaceCamera = true
		beam.Segments = 10
		beam.Color = ColorSequence.new(Color3.fromRGB(180, 214, 255), Color3.new(1, 1, 1))
		beam.Enabled = false
		beam.Parent = h.core
		h.arcs[i] = { a0 = a0, a1 = a1, beam = beam }
	end
	return h.arcs
end

local function randomUnit()
	local v = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)
	return v.Magnitude > 1e-3 and v.Unit or Vector3.yAxis
end

local function explode(h, near)
	local R = h.radius
	if h.burst then
		h.burst:Emit(near and 700 or 220)
	end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 4.6 do
			local el = os.clock() - t0
			for _, n in ipairs(h.novae) do
				if el >= n.delay then
					local u = math.clamp((el - n.delay) / n.dur, 0, 1)
					n.part.Size = Vector3.one * math.min(2040, R * 0.2 + n.max * (1 - (1 - u) ^ 3))
					n.part.Transparency = u ^ 0.55
				end
			end
			for _, w in ipairs(h.waves) do
				if el >= w.delay then
					local u = math.clamp((el - w.delay) / w.dur, 0, 1)
					local d = math.min(2040, R * 2 + w.max * (1 - (1 - u) ^ 2))
					w.part.Size = Vector3.new(0.8, d, d)
					w.part.Transparency = 0.05 + 0.95 * u
				end
			end
			RunService.RenderStepped:Wait()
		end
		for _, n in ipairs(h.novae) do
			n.part.Transparency = 1
		end
		for _, w in ipairs(h.waves) do
			w.part.Transparency = 1
		end
	end)
	if near then
		whiteOut(0.6, 3)
		blastUntil, blastDur, blastAmp = os.clock() + 3.4, 3.4, 3.6
		fx()
		grade.Brightness, grade.Saturation, grade.Contrast, grade.TintColor = 1.3, -1, 0.45, Color3.fromRGB(240, 246, 255)
		TweenService:Create(grade, TweenInfo.new(4.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Brightness = 0, Saturation = 0, Contrast = 0, TintColor = Color3.new(1, 1, 1) }):Play()
		blur.Size = 28
		TweenService:Create(blur, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = 0 }):Play()
		bloom.Intensity = 3
		TweenService:Create(bloom, TweenInfo.new(3.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Intensity = 0 }):Play()
		h.gradeFreeAt = os.clock() + 4.6
	end
end

local function stepHole(h, eye, dt)
	local now = workspace:GetServerTimeNow()
	local k = math.floor(now / h.cycle)
	local t = now - k * h.cycle
	local far = (h.pivot.Position - eye).Magnitude
	local near = far <= h.flashRadius
	if h.lastCycle and k ~= h.lastCycle and far < 9000 then
		explode(h, near)
	end
	h.lastCycle = k
	if far > 9000 then
		return
	end
	local collapseAt = h.cycle - h.collapse
	local implodeAt = h.cycle - h.implode
	local s, spin, heat, quake, imploding = 1, 1, 0, 0, false
	if t < REFORM then
		local u = t / REFORM
		s, spin = h.minScale * smooth(u), 4 - 3 * u
	elseif t < collapseAt then
		local u = (t - REFORM) / (collapseAt - REFORM)
		s, spin = h.minScale + (1 - h.minScale) * u ^ 1.6, 1 + u * 0.8
	elseif t < implodeAt then
		-- Coming apart: shuddering harder every second, spinning up, burning white.
		local u = (t - collapseAt) / (implodeAt - collapseAt)
		s = 1 + (0.02 + 0.08 * u * u) * math.sin(t * (30 + 90 * u)) + (math.random() - 0.5) * 0.04 * u
		spin, heat, quake = 2 + 60 * u * u, u, 0.05 + 1.2 * u * u
	else
		-- One last breath, then it falls all the way in, inside a second.
		local u = math.clamp((t - implodeAt) / h.implode, 0, 1)
		if u < 0.12 then
			s = 1 + 0.08 * (u / 0.12)
		else
			s = 1.08 * (1 - ((u - 0.12) / 0.88) ^ 1.8)
		end
		spin, heat, quake, imploding = 80 + 400 * u, 1, 1.6 + 1.8 * u, true
	end
	s = math.clamp(s, 0.002, 1.1)
	-- While it implodes the disk trails the core in, a ring of fire spiralling
	-- down after it.
	local sd = imploding and math.min(1.1, s ^ 0.5) or s
	h.spin += dt * math.rad(10) * spin
	local diskFrame = h.diskPivot * CFrame.Angles(0, h.spin, 0)
	if heat > 0 then
		-- The disk tumbles as it tears loose, worst in the last second.
		local wobble = (imploding and 0.35 or 0.08 * heat)
		diskFrame = h.diskPivot * CFrame.Angles(math.sin(t * 13) * wobble, h.spin, math.cos(t * 11) * wobble)
	end
	for _, p in ipairs(h.parts) do
		local sc = p.disk and sd or s
		p.part.CFrame = (p.disk and diskFrame or h.pivot) * (CFrame.new(p.pos * sc) * p.rot)
		p.part.Size = p.size * sc
		if p.glow and (heat > 0 or p.heated) then
			p.heated = heat > 0
			p.part.Color = p.color:Lerp(WHITE_HOT, heat * (imploding and 0.9 or 0.55))
			p.part.Transparency = p.transparency * (1 - heat * 0.6)
		end
	end
	if math.abs(s - h.scale) > 0.002 or heat > 0 or h.guisHot then
		h.scale = s
		for _, g in ipairs(h.guis) do
			g.gui.Size = UDim2.fromScale(g.size.X.Scale * s * (1 + heat * 0.15), g.size.Y.Scale * s * (1 + heat * 0.15))
		end
		h.guisHot = heat > 0
		for _, f in ipairs(h.frames) do
			if f.color ~= Color3.new(0, 0, 0) then
				f.frame.BackgroundColor3 = f.color:Lerp(WHITE_HOT, heat * 0.6)
				f.frame.BackgroundTransparency = f.transparency * (1 - heat * (imploding and 0.4 or 0.15))
			end
		end
		-- Every stream shrinks with the hole and races as it comes apart: the disk
		-- inflow follows the disk's scale, the infall from all round the core's.
		for _, e in ipairs(h.emitters) do
			local sc = e.disk and sd or s
			local k = 1 + heat * 1.5
			e.emitter.Speed = NumberRange.new(e.speed.Min * sc * k, e.speed.Max * sc * k)
			e.emitter.Rate = e.rate * (1 + heat * (e.disk and 6 or 3))
			local kps = {}
			for i, p in ipairs(e.size.Keypoints) do
				kps[i] = NumberSequenceKeypoint.new(p.Time, p.Value * sc, p.Envelope * sc)
			end
			e.emitter.Size = NumberSequence.new(kps)
		end
	end
	-- Lightning, re-struck every twentieth of a second.
	if heat > 0.08 then
		h.arcTimer = (h.arcTimer or 0) + dt
		if h.arcTimer > 0.05 then
			h.arcTimer = 0
			local R = h.radius * s
			for _, arc in ipairs(arcsFor(h)) do
				local on = math.random() < heat * 0.85
				arc.beam.Enabled = on
				if on then
					local from = randomUnit() * R * 1.02
					arc.a0.Position = from
					arc.a1.Position = from.Unit * R * (1.25 + math.random() * 1.3) + randomUnit() * R * 0.35
					arc.beam.Width0 = R * (0.012 + math.random() * 0.025)
					arc.beam.Width1 = arc.beam.Width0 * 0.25
					arc.beam.CurveSize0 = (math.random() - 0.5) * R * 0.8
					arc.beam.CurveSize1 = (math.random() - 0.5) * R * 0.8
					arc.beam.Transparency = NumberSequence.new(math.random() * 0.35)
				end
			end
		end
	elseif h.arcs and h.arcsLit ~= false then
		for _, arc in ipairs(h.arcs) do
			arc.beam.Enabled = false
		end
	end
	h.arcsLit = heat > 0.08
	-- The world darkens and bruises as the light is dragged in.
	if near then
		collapseShake = quake
		if heat > 0 and os.clock() > (h.gradeFreeAt or 0) then
			fx()
			grade.TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(216, 228, 255), heat * 0.65)
			grade.Saturation = heat * 0.35 - (imploding and 0.5 or 0)
			grade.Contrast = heat * 0.4
			grade.Brightness = -heat * 0.14 - (imploding and 0.3 or 0)
			h.graded = true
		elseif h.graded and os.clock() > (h.gradeFreeAt or 0) then
			h.graded = false
			grade.TintColor, grade.Saturation, grade.Contrast, grade.Brightness = Color3.new(1, 1, 1), 0, 0, 0
		end
	elseif h.wasNear then
		collapseShake = 0
	end
	h.wasNear = near
end

local function stepScreen(part)
	local gui = part:FindFirstChildOfClass("SurfaceGui")
	local label = gui and gui:FindFirstChild("Text")
	if not label then
		return
	end
	local cycle = num(part, "Cycle", 1200)
	local t = workspace:GetServerTimeNow() % cycle
	if t < REFORM then
		label.Text = "SINGULARITY REFORMING"
		label.TextColor3 = AMBER
	elseif t >= cycle - 14 then
		local flip = math.floor(t * 2) % 2 == 0
		label.Text = flip and "COLLAPSE IMMINENT" or "EVACUATE THE SHAFT"
		label.TextColor3 = flip and Color3.fromRGB(255, 70, 60) or AMBER
	else
		local left = math.floor(cycle - t) -- rounded the way the HUD's "Mine m:ss" is
		label.Text = string.format("COLLAPSE IN %02d:%02d", left // 60, left % 60)
		label.TextColor3 = AMBER
	end
end

for tagName, list in pairs({ AmbBlackHole = holes, AmbCountdown = screens }) do
	local function add(inst)
		if tagName == "AmbBlackHole" then
			if inst:IsA("Model") then
				addHole(inst)
			end
		elseif inst:IsA("BasePart") then
			screens[inst] = true
		end
	end
	for _, inst in ipairs(CollectionService:GetTagged(tagName)) do
		add(inst)
	end
	CollectionService:GetInstanceAddedSignal(tagName):Connect(add)
	CollectionService:GetInstanceRemovedSignal(tagName):Connect(function(inst)
		list[inst] = nil
	end)
end

local screenTimer = 0
local clock, skyTimer = 0, 0
RunService.RenderStepped:Connect(function(dt)
	clock += dt
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local eye = cam.CFrame.Position
	if starShell then
		starShell:PivotTo(CFrame.new(eye))
	end
	for inst, m in pairs(movers) do
		if inst.Parent == nil then
			movers[inst] = nil
		else
			step(inst, m, clock, eye)
		end
	end
	skyTimer += dt
	if skyTimer >= 0.2 then
		skyTimer = 0
		updateSky(eye)
	end
	for m, h in pairs(holes) do
		if m.Parent == nil then
			holes[m] = nil
		else
			stepHole(h, eye, dt)
		end
	end
	screenTimer += dt
	if screenTimer >= 0.25 then
		screenTimer = 0
		for part in pairs(screens) do
			if part.Parent == nil then
				screens[part] = nil
			else
				stepScreen(part)
			end
		end
	end
end)
