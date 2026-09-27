--[[
	MineEventHorizon: Event Horizon as a research station on a rock adrift in
	space, with a black hole hanging past the far rim.

	The hole keeps a clock every server and client share
	(workspace:GetServerTimeNow): for MineConfig.MINE_RESET_SEC it swells, then it
	collapses and goes off. MineServer remakes this mine at that instant, and
	MineAmbience plays the swelling, the collapse, the blast and the white-out
	on every client close enough to see it. The server builds it once and never
	moves it.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MineConfig = require(ReplicatedStorage:WaitForChild("Mine"):WaitForChild("Shared"):WaitForChild("MineConfig"))
local ThemeKit = require(script.Parent:WaitForChild("MineThemeKit"))

local C3, smooth = ThemeKit.C3, ThemeKit.smoothstep
local M = Enum.Material

local EH = {}

local DECK = 1.4
local STEEL = C3(158, 166, 180)
local DARK = C3(52, 56, 68)
local CYAN = C3(90, 220, 255)
local VIOLET = C3(172, 116, 255)
local AMBER = C3(255, 176, 70)
local CYCLE = MineConfig.MINE_RESET_SEC or 1200 -- it collapses when the mines reset

-- Where the hole hangs, in zone coordinates, and its radius at full size. It is
-- huge, so it hangs far out: at full size the disk still stops well short of
-- the station. (Parts cap at 2048 studs; the widest band here is about 1820.)
EH.HOLE_AT = { l = 60, y = 340, b = -1180 }
EH.HOLE_RADIUS = 276

local T -- the ThemeKit for the build in progress

local function kp(t, v)
	return NumberSequenceKeypoint.new(t, v)
end

local CRATERS = { { -110, 20, 26, 5 }, { 128, -70, 34, 7 }, { -60, -160, 22, 4 }, { 96, 150, 18, 4 } }

function EH.terrain(kit, terrain, zone, origin, axis)
	T = ThemeKit.new(kit, origin, axis)
	local G = T.G
	local hole = T.hole
	local seed = (tonumber(zone.angle) or 0) * 0.37 + 5.1
	local function n2(x, z, f)
		return math.noise(x * f + seed, z * f - seed)
	end
	-- Flat at deck height round the station and the pit, crags and craters
	-- further out, a ragged edge, and an underside: it is floating.
	local function sample(l, b)
		local r = math.sqrt(l * l + b * b)
		local edge = 222 + 36 * n2(l, b, 1 / 90) + 12 * n2(l, b, 1 / 29)
		if r > edge then
			return nil
		end
		local wild = smooth((r - 158) / 46)
		local ridge = math.abs(n2(l, b, 1 / 47))
		local h = G + 1.3 + wild * (3 + 10 * (1 - ridge) ^ 4 + 3 * n2(l, b, 1 / 13))
		for _, c in ipairs(CRATERS) do
			local d = math.sqrt((l - c[1]) ^ 2 + (b - c[2]) ^ 2) / c[3]
			if d < 1.35 then
				h += c[4] * (0.6 * smooth((d - 0.75) / 0.3) * (1 - smooth((d - 1.05) / 0.3)) - (1 - smooth(d)))
			end
		end
		h -= 16 * smooth((r - (edge - 22)) / 22)
		-- Under the station deck the rock steps down out of sight.
		if math.abs(l) <= 72 and b >= hole + 5 and b <= hole + 108 then
			h = G - 2.5
		end
		local mat = M.Basalt
		if wild > 0.25 and ridge < 0.06 then
			mat = M.Glacier -- seams of ice in the crags
		elseif n2(l + 90, b, 1 / 19) > 0.35 then
			mat = M.Slate
		end
		local deep = G - 16 - 78 * math.sqrt(math.max(0, 1 - (r / edge) ^ 2)) + 8 * n2(l, b, 1 / 40)
		return h, mat, nil, deep
	end
	T.fill = M.Basalt
	T.writeTerrain(terrain, 272, -104, 64, sample)
	-- Rocks adrift round it.
	local rng = Random.new(77)
	for i = 1, 15 do
		local a = rng:NextNumber() * math.pi * 2
		local rr = 290 + rng:NextNumber() * 170
		local centre = T.HP(math.cos(a) * rr, 20 + rng:NextNumber() * 110, math.sin(a) * rr)
		local size = 7 + rng:NextNumber() * 17
		terrain:FillBall(centre, size, M.Basalt)
		terrain:FillBall(centre + Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.5, 0.5), rng:NextNumber(-1, 1)) * size * 0.7,
			size * 0.6, (i % 3 == 0) and M.Slate or M.Basalt)
		if i % 4 == 0 then
			terrain:FillBall(centre + Vector3.new(0, size * 0.55, 0), size * 0.32, M.Glacier)
		end
	end
	EH._sample = sample
end

--------------------------------------------------------------------------------
-- THE STATION
--------------------------------------------------------------------------------

local function groundAt(l, b)
	local h = EH._sample and EH._sample(l, b)
	return h and (h - T.G) or 1.3
end

local function deck(f, rng)
	local g = T.folder(f, "Deck")
	local hole = T.hole
	local near, far, halfW = hole + 6, hole + 106, 71
	local cols, rows = 6, 5
	local pw, pd = halfW * 2 / cols, (far - near) / rows
	for i = 0, cols - 1 do
		for j = 0, rows - 1 do
			T.mk({ Name = "DeckPanel", Parent = g, Size = Vector3.new(pw - 0.14, 1, pd - 0.14),
				CFrame = T.H(-halfW + pw * (i + 0.5), DECK - 0.5, near + pd * (j + 0.5)),
				Color = STEEL:Lerp(DARK, 0.3 + rng:NextNumber() * 0.14), Material = M.DiamondPlate })
		end
	end
	T.mk({ Name = "DeckFrame", Parent = g, Size = Vector3.new(halfW * 2 + 2, 1.4, far - near + 1), CFrame = T.H(0, DECK - 1, (near + far) / 2 + 0.5),
		Color = DARK, Material = M.Metal })
	for _, s in ipairs({ -1, 1 }) do
		T.mk({ Name = "EdgeLight", Parent = g, Size = Vector3.new(0.5, 0.3, far - near + 1), CFrame = T.H(s * (halfW + 0.5), DECK - 0.2, (near + far) / 2 + 0.5),
			Color = CYAN, Material = M.Neon, deco = true })
		T.mk({ Name = "PathLight", Parent = g, Size = Vector3.new(0.3, 0.1, far - near - 6), CFrame = T.H(s * 6.5, DECK + 0.05, (near + far) / 2 + 3),
			Color = CYAN, Material = M.Neon, deco = true })
	end
	T.mk({ Name = "EdgeLight", Parent = g, Size = Vector3.new(halfW * 2 + 2, 0.3, 0.5), CFrame = T.H(0, DECK - 0.2, far + 0.5), Color = CYAN, Material = M.Neon, deco = true })
	-- Hazard striping where the deck meets the pit collar.
	T.mk({ Name = "Hazard", Parent = g, Size = Vector3.new(halfW * 2, 0.1, 2.2), CFrame = T.H(0, DECK + 0.05, near + 1.1), Color = C3(236, 190, 40), Material = M.SmoothPlastic, deco = true })
	for k = 0, 23 do
		T.mk({ Name = "HazardStripe", Parent = g, Size = Vector3.new(1.3, 0.14, 2.9),
			CFrame = T.H(-halfW + 3 + k * 5.8, DECK + 0.07, near + 1.1) * CFrame.Angles(0, math.rad(45), 0), Color = C3(26, 26, 30), deco = true })
	end
end

local function collar(f)
	local g = T.folder(f, "Collar")
	local hole = T.hole
	local low, top = -2.6, DECK + 0.2
	local hgt = top - low
	for _, s in ipairs({ 1, -1 }) do
		T.mk({ Name = "Collar", Parent = g, Size = Vector3.new(hole * 2 + 12, hgt, 6), CFrame = T.H(0, low + hgt / 2, s * (hole + 3)), Color = DARK, Material = M.Metal })
		T.mk({ Name = "Collar", Parent = g, Size = Vector3.new(6, hgt, hole * 2), CFrame = T.H(s * (hole + 3), low + hgt / 2, 0), Color = DARK, Material = M.Metal })
		T.mk({ Name = "CollarGlow", Parent = g, Size = Vector3.new(hole * 2 + 0.6, 0.35, 0.35), CFrame = T.H(0, top - 0.1, s * (hole + 0.15)), Color = CYAN, Material = M.Neon, deco = true })
		T.mk({ Name = "CollarGlow", Parent = g, Size = Vector3.new(0.35, 0.35, hole * 2), CFrame = T.H(s * (hole + 0.15), top - 0.1, 0), Color = CYAN, Material = M.Neon, deco = true })
	end
	for _, c in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
		local p = T.HP(c[1] * (hole + 4.5), top, c[2] * (hole + 4.5))
		T.rod(g, "BeaconBase", p, p + Vector3.new(0, 0.8, 0), 1.6, DARK, M.Metal, true)
		local lamp = T.rod(g, "Beacon", p + Vector3.new(0, 0.8, 0), p + Vector3.new(0, 1.6, 0), 1.1, C3(255, 60, 50), M.Neon, true)
		T.light(lamp, "PointLight", { Color = C3(255, 60, 50), Range = 14, Brightness = 1.5 })
		T.tag(lamp, "AmbBlink", { Period = 1.6, Duty = 0.45, Phase = (c[1] + c[2] * 0.5 + 2) * 0.4 })
	end
end

-- A station module: plinth, steel walls, portholes, a canopy, a glowing door
-- frame and a counter. Each trade adds its own kit around it.
local function stationModule(f, cf, W, D, Hh, accent, title)
	T.mk({ Name = "Floor", Parent = f, Size = Vector3.new(W + 6, 1.2, D + 6), CFrame = cf * CFrame.new(0, 0.6, 0), Color = DARK, Material = M.DiamondPlate })
	T.mk({ Name = "FloorGlow", Parent = f, Size = Vector3.new(W + 6.4, 0.3, D + 6.4), CFrame = cf * CFrame.new(0, 0.2, 0), Color = accent, Material = M.Neon, deco = true })
	T.mk({ Name = "Back", Parent = f, Size = Vector3.new(W, Hh, 1.2), CFrame = cf * CFrame.new(0, Hh / 2, D / 2), Color = STEEL, Material = M.Metal })
	for _, s in ipairs({ -1, 1 }) do
		T.mk({ Name = "Side", Parent = f, Size = Vector3.new(1.2, Hh, D), CFrame = cf * CFrame.new(s * W / 2, Hh / 2, 0), Color = STEEL, Material = M.Metal })
		T.mk({ Name = "Band", Parent = f, Size = Vector3.new(1.3, 0.45, D + 0.1), CFrame = cf * CFrame.new(s * W / 2, Hh * 0.28, 0), Color = accent, Material = M.Neon, deco = true })
		local ph = cf * CFrame.new(s * (W / 2 + 0.6), Hh * 0.62, 0)
		T.rod(f, "Porthole", ph.Position, (ph * CFrame.new(s * 0.2, 0, 0)).Position, 3.2, DARK, M.Metal, true)
		T.rod(f, "PortholeGlass", (ph * CFrame.new(s * 0.22, 0, 0)).Position, (ph * CFrame.new(s * 0.3, 0, 0)).Position, 2.3, accent, M.Neon, true).Transparency = 0.35
		T.mk({ Name = "DoorFrame", Parent = f, Size = Vector3.new(0.4, Hh, 0.4), CFrame = cf * CFrame.new(s * (W / 2 - 0.2), Hh / 2, -D / 2 - 0.1), Color = accent, Material = M.Neon, deco = true })
	end
	T.mk({ Name = "DoorFrame", Parent = f, Size = Vector3.new(W, 0.4, 0.4), CFrame = cf * CFrame.new(0, Hh - 0.2, -D / 2 - 0.1), Color = accent, Material = M.Neon, deco = true })
	T.mk({ Name = "Roof", Parent = f, Size = Vector3.new(W + 3, 1.2, D + 3), CFrame = cf * CFrame.new(0, Hh + 0.6, 0.5), Color = DARK, Material = M.Metal })
	T.wedge(f, "Canopy", cf * CFrame.new(0, Hh + 0.6, -D / 2 - 1.5), Vector3.new(W + 3, 1.2, 4), DARK, M.Metal)
	T.mk({ Name = "Counter", Parent = f, Size = Vector3.new(W - 8, 4.4, 3.2), CFrame = cf * CFrame.new(0, 2.2, -D / 2 + 3), Color = DARK, Material = M.Metal })
	T.mk({ Name = "CounterTop", Parent = f, Size = Vector3.new(W - 6.4, 0.4, 4), CFrame = cf * CFrame.new(0, 4.6, -D / 2 + 3), Color = accent, Material = M.Neon, Transparency = 0.25 })
	local sign = T.mk({ Name = "Sign", Parent = f, Size = Vector3.new(W - 3, 2.6, 0.3), CFrame = cf * CFrame.new(0, Hh + 2.5, -D / 2 + 1), Color = DARK, Material = M.Metal })
	T.writeOn(sign, string.upper(title), { color = accent, glow = 2, pps = 30 })
	local mast = T.rod(f, "Antenna", (cf * CFrame.new(W / 2 - 1.5, Hh + 1.2, D / 2 - 1)).Position, (cf * CFrame.new(W / 2 - 1.5, Hh + 8, D / 2 - 1)).Position, 0.25, STEEL, M.Metal, true)
	local tip = T.ball(f, "AntennaTip", (cf * CFrame.new(W / 2 - 1.5, Hh + 8.3, D / 2 - 1)).Position, 0.7, C3(255, 60, 50), M.Neon, true)
	T.tag(tip, "AmbBlink", { Period = 2.2, Duty = 0.2, Phase = cf.Position.X % 2 })
	return mast
end

local function buildSalvageBay(kit, f, cf, pal, W, D, Hh, title)
	stationModule(f, cf, W, D, Hh, AMBER, title or "Salvage Bay")
	-- Cargo containers and a crane arm over them.
	for i, o in ipairs({ { -W / 2 - 3.2, 1.9, -1 }, { -W / 2 - 3.2, 1.9, 4.6 }, { -W / 2 - 3.1, 5.3, 1.8 } }) do
		local box = T.mk({ Name = "Container", Parent = f, Size = Vector3.new(4.2, 3.4, 5.2), CFrame = cf * CFrame.new(o[1], o[2], o[3]) * CFrame.Angles(0, math.rad(i * 4), 0),
			Color = ({ C3(196, 92, 44), C3(58, 104, 150), C3(200, 200, 204) })[i], Material = M.CorrodedMetal })
		T.mk({ Name = "ContainerStripe", Parent = f, Size = Vector3.new(4.3, 0.5, 5.3), CFrame = box.CFrame * CFrame.new(0, 1, 0), Color = C3(236, 190, 40), deco = true })
	end
	local arm0 = (cf * CFrame.new(W / 2 + 2.5, 0, D / 2 - 1)).Position
	T.rod(f, "CranePost", arm0, arm0 + Vector3.new(0, 13, 0), 0.9, DARK, M.Metal)
	T.beam(f, "CraneArm", arm0 + Vector3.new(0, 12.6, 0), (cf * CFrame.new(-W / 2 - 3, 12.6, 2)).Position, 0.7, 0.9, C3(236, 190, 40), M.Metal, true)
	local hook = (cf * CFrame.new(-W / 2 - 2, 12.2, 2)).Position
	T.rod(f, "CraneCable", hook, hook - Vector3.new(0, 3.2, 0), 0.08, DARK, M.Metal, true)
	T.mk({ Name = "CraneHook", Parent = f, Size = Vector3.new(0.8, 0.9, 0.4), CFrame = CFrame.new(hook - Vector3.new(0, 3.6, 0)), Color = DARK, Material = M.Metal, deco = true })
	-- A maintenance drone that never quite lands.
	local drone = T.model(f, "Drone")
	local dc = cf * CFrame.new(W / 2 + 3, 7.5, -D / 2 - 4)
	T.blob(drone, "DroneBody", dc, Vector3.new(1.8, 0.9, 1.8), STEEL, M.Metal, true)
	T.ball(drone, "DroneEye", (dc * CFrame.new(0, -0.1, -0.85)).Position, 0.5, AMBER, M.Neon, true)
	for _, o in ipairs({ { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
		local rp = (dc * CFrame.new(o[1] * 1.3, 0.2, o[2] * 1.3)).Position
		T.rod(drone, "Rotor", rp, rp + Vector3.new(0, 0.08, 0), 1.3, CYAN, M.Neon, true).Transparency = 0.4
	end
	drone.WorldPivot = dc
	T.tag(drone, "AmbBob", { BobAmp = 0.5, BobSpeed = 1.3, Roll = 5, Pitch = 4, Phase = 0.7 })
end

local function buildSupplyPod(kit, f, cf, pal, W, D, Hh, title)
	stationModule(f, cf, W, D, Hh, CYAN, title or "Supply Pod")
	-- A greenhouse dome and a rack of gas bottles beside it.
	local domeAt = cf * CFrame.new(-W / 2 - 5, 0, 1)
	T.rod(f, "DomeRing", (domeAt * CFrame.new(0, 0, 0)).Position, (domeAt * CFrame.new(0, 0.6, 0)).Position, 8.6, DARK, M.Metal)
	local dome = T.ball(f, "Dome", (domeAt * CFrame.new(0, 0.4, 0)).Position, 8, C3(200, 236, 255), M.Glass)
	dome.Transparency = 0.55
	for k = 0, 3 do
		local a = k * 1.7
		T.ball(f, "Plant", (domeAt * CFrame.new(math.cos(a) * 1.6, 1.2 + (k % 2) * 0.4, math.sin(a) * 1.6)).Position, 1.6 + (k % 2) * 0.5,
			C3(88, 150, 70):Lerp(C3(120, 190, 90), k / 3), M.LeafyGrass, true)
	end
	T.light((T.ball(f, "GrowLamp", (domeAt * CFrame.new(0, 3.1, 0)).Position, 0.6, VIOLET, M.Neon, true)), "PointLight", { Color = VIOLET, Range = 10, Brightness = 1.2 })
	for k = 0, 2 do
		local base = (cf * CFrame.new(W / 2 + 2.2, 0, -D / 2 + 1.5 + k * 1.9)).Position
		T.rod(f, "GasBottle", base, base + Vector3.new(0, 3.4, 0), 1.3, ({ C3(46, 120, 190), C3(236, 236, 236), C3(46, 120, 190) })[k + 1], M.Metal, true)
		T.ball(f, "BottleCap", base + Vector3.new(0, 3.5, 0), 1, DARK, M.Metal, true)
	end
end

local function helmet(shop, visor)
	for _, c in ipairs(shop:GetChildren()) do
		if c:IsA("Model") and c.Name:match("^NPC_") then
			local head = c:FindFirstChild("Head")
			if head then
				local glass = T.ball(c, "Helmet", head.Position + Vector3.new(0, 0.1, 0), 3, C3(210, 236, 255), M.Glass, true)
				glass.Transparency = 0.62
				T.rod(c, "HelmetRing", head.Position - Vector3.new(0, 1.1, 0), head.Position - Vector3.new(0, 0.8, 0), 2.6, STEEL, M.Metal, true)
				T.ball(c, "Visor", (head.CFrame * CFrame.new(0, 0.3, -1.25)).Position, 0.5, visor, M.Neon, true)
			end
		end
	end
end

local function shops(f)
	local ShopFronts = T.kit.shopFronts
	ShopFronts.STYLES.salvagebay = buildSalvageBay
	ShopFronts.STYLES.supplypod = buildSupplyPod
	local shopB, shopL = T.hole + 40, 38
	for _, spec in ipairs({
		{ l = -shopL, style = "salvagebay", title = "Salvage Bay", verb = "SELL", npc = "Orla", role = "Buys your haul", machine = "sell", accent = AMBER },
		{ l = shopL, style = "supplypod", title = "Supply Pod", verb = "SHOP", npc = "Dex", role = "Tools and bags", machine = "shop", accent = CYAN },
	}) do
		local pos = T.HP(spec.l, DECK, shopB)
		local cf = CFrame.lookAt(pos, T.HP(0, DECK, shopB))
		local shop = ShopFronts.build(T.kit, f, cf, {
			style = spec.style, title = spec.title, verb = spec.verb, npc = spec.npc, role = spec.role, machine = spec.machine,
			pal = { brick = STEEL, roof = DARK, trim = DARK, accent = C3(236, 236, 240), mat = M.Metal }, locked = false,
		}, T.kit.SHOP_W, T.kit.SHOP_D, T.kit.SHOP_H)
		helmet(shop, spec.accent)
	end
end

local function ringGate(f, zone)
	local g = T.folder(f, "Gate")
	local b = T.hole + 20
	local centre = T.H(0, DECK + 11, b)
	local R, n = 10.5, 22
	local chord = 2 * R * math.sin(math.pi / n) * 1.12
	for i = 0, n - 1 do
		local a = (i / n) * math.pi * 2
		if math.sin(a) > -0.7 then
			T.mk({ Name = "GateRing", Parent = g, Size = Vector3.new(1.8, chord, 2), CFrame = centre * CFrame.Angles(0, 0, a) * CFrame.new(R, 0, 0), Color = DARK, Material = M.Metal, noQuery = true })
			T.mk({ Name = "GateGlow", Parent = g, Size = Vector3.new(0.35, chord, 1.1), CFrame = centre * CFrame.Angles(0, 0, a) * CFrame.new(R - 1.05, 0, 0), Color = CYAN, Material = M.Neon, deco = true })
		end
	end
	for _, s in ipairs({ -1, 1 }) do
		T.mk({ Name = "GateFoot", Parent = g, Size = Vector3.new(4, 2.4, 4), CFrame = T.H(s * 7.6, DECK + 1.2, b), Color = DARK, Material = M.Metal, noQuery = true })
	end
	local holo = T.mk({ Name = "Hologram", Parent = g, Size = Vector3.new(22, 3.4, 0.1), CFrame = T.H(0, DECK + 24.5, b) * CFrame.Angles(0, math.pi, 0), Transparency = 1, deco = true, shadow = false })
	T.writeOn(holo, string.upper(zone.name or "Event Horizon"), { color = CYAN, glow = 3, pps = 24, maxDistance = 400 })
	T.mk({ Name = "Projector", Parent = g, Size = Vector3.new(14, 0.3, 0.6), CFrame = T.H(0, DECK + 22.2, b), Color = CYAN, Material = M.Neon, deco = true })
	T.tag(holo, "AmbBob", { BobAmp = 0.25, BobSpeed = 0.9, Roll = 0, Pitch = 0, Phase = 0 })
end

local function pylons(f)
	local g = T.folder(f, "Pylons")
	for _, b in ipairs({ T.hole + 14, T.hole + 64, T.hole + 98 }) do
		for _, s in ipairs({ -1, 1 }) do
			local p = T.HP(s * 9, DECK, b)
			T.rod(g, "Pylon", p, p + Vector3.new(0, 7.4, 0), 0.7, DARK, M.Metal)
			local cap = T.rod(g, "PylonLight", p + Vector3.new(0, 7.4, 0), p + Vector3.new(0, 9.6, 0), 0.95, CYAN, M.Neon, true)
			T.light(cap, "PointLight", { Color = CYAN, Range = 22, Brightness = 1.3 })
		end
	end
end

-- Two screens by the gate that count down to the collapse. MineAmbience
-- writes the text; the server only says how long a cycle is.
local function countdownScreens(f)
	local g = T.folder(f, "Countdown")
	for _, s in ipairs({ -1, 1 }) do
		local p = T.HP(s * 20, DECK, T.hole + 23)
		T.rod(g, "ScreenPost", p, p + Vector3.new(0, 6, 0), 0.6, DARK, M.Metal)
		local screen = T.mk({ Name = "Screen", Parent = g, Size = Vector3.new(8, 3.6, 0.4), CFrame = T.H(s * 20, DECK + 7.6, T.hole + 23) * CFrame.Angles(0, math.pi, 0),
			Color = C3(10, 12, 20), Material = M.SmoothPlastic })
		local _, label = T.writeOn(screen, "COLLAPSE IN --:--", { color = AMBER, glow = 2.5, pps = 40, font = Enum.Font.Code, maxDistance = 220 })
		T.tag(screen, "AmbCountdown", { Cycle = CYCLE })
	end
end

local function asteroidDressing(f, rng)
	local g = T.folder(f, "Asteroid")
	-- Radar dishes that sweep the sky.
	for _, o in ipairs({ { -128, -40 }, { 132, 40 } }) do
		local y = groundAt(o[1], o[2])
		local base = T.HP(o[1], y, o[2])
		T.rod(g, "DishPost", base - Vector3.new(0, 1, 0), base + Vector3.new(0, 7, 0), 1.2, DARK, M.Metal)
		local head = T.model(g, "DishHead")
		local hc = CFrame.new(base + Vector3.new(0, 7.5, 0))
		T.blob(head, "Dish", hc * CFrame.new(0, 2.2, -1) * CFrame.Angles(math.rad(-40), 0, 0), Vector3.new(9, 1.4, 9), STEEL, M.Metal, true)
		T.rod(head, "DishFeed", (hc * CFrame.new(0, 2.4, -1.2)).Position, (hc * CFrame.new(0, 5.4, -4.4)).Position, 0.25, DARK, M.Metal, true)
		T.ball(head, "DishTip", (hc * CFrame.new(0, 5.5, -4.5)).Position, 0.6, C3(255, 60, 50), M.Neon, true)
		head.WorldPivot = hc
		T.tag(head, "AmbSpin", { SpinSpeed = 12 + rng:NextNumber() * 6 })
	end
	-- Crystal clusters glowing in the crags.
	for i = 1, 7 do
		local a = (i / 7) * math.pi * 2 + rng:NextNumber() * 0.4
		local r = 118 + rng:NextNumber() * 62
		local l, b = math.cos(a) * r, math.sin(a) * r
		if not (math.abs(l) <= 80 and b > T.hole) then
			local y = groundAt(l, b)
			local col = (i % 2 == 0) and VIOLET or CYAN
			for k = 1, 4 do
				local ht = 3 + rng:NextNumber() * 6
				T.mk({ Name = "Crystal", Parent = g, Size = Vector3.new(1.2 + rng:NextNumber(), ht, 1.2 + rng:NextNumber()),
					CFrame = T.H(l + rng:NextNumber(-2, 2), y + ht * 0.35, b + rng:NextNumber(-2, 2)) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber() * 3, rng:NextNumber(-0.5, 0.5)),
					Color = col, Material = (k == 1) and M.Neon or M.Glass, Transparency = (k == 1) and 0.15 or 0.25, deco = true })
			end
			T.light(T.source(g, "CrystalLight", T.HP(l, y + 3, b)), "PointLight", { Color = col, Range = 18, Brightness = 1.4 })
		end
	end
	-- Debris hanging in the dark.
	for i = 1, 9 do
		local a = rng:NextNumber() * math.pi * 2
		local r = 150 + rng:NextNumber() * 110
		local rock = T.blob(g, "Debris", T.H(math.cos(a) * r, 16 + rng:NextNumber() * 40, math.sin(a) * r) * CFrame.Angles(rng:NextNumber(), rng:NextNumber(), rng:NextNumber()),
			Vector3.new(2 + rng:NextNumber() * 5, 1.6 + rng:NextNumber() * 3, 2 + rng:NextNumber() * 5), C3(64, 62, 66), M.Basalt, true)
		T.tag(rock, "AmbBob", { BobAmp = 1.2, BobSpeed = 0.3 + rng:NextNumber() * 0.3, Roll = 10, Pitch = 8, Phase = rng:NextNumber() * 6 })
	end
end

--------------------------------------------------------------------------------
-- THE BLACK HOLE
--------------------------------------------------------------------------------

local function blackHole(f)
	local R = EH.HOLE_RADIUS
	local m = T.model(f, "BlackHole")
	local centre = T.HP(EH.HOLE_AT.l, EH.HOLE_AT.y, EH.HOLE_AT.b)
	-- Almost edge-on from the station, the way Gargantua is drawn: the disk is a
	-- thin bright line across the shadow, and the light from its far side is
	-- bent up over the top and down under the bottom into a ring. Rolled a
	-- touch so it does not sit dead level on the horizon.
	local tilt = CFrame.lookAt(centre, T.HP(0, 0, 0)) * CFrame.Angles(0, 0, math.rad(-9)) * CFrame.Angles(math.rad(4.5), 0, 0)
	-- Neon, so the sky never shows in it as a highlight: black is black.
	local core = T.ball(m, "Singularity", centre, R * 2, C3(0, 0, 0), M.Neon, true)
	core.CastShadow = false

	-- The billboard always faces whoever is looking, which is what lensed light
	-- does. Discs stacked from the outside in: a soft glow, the lensed ring
	-- (lifted, so it is thicker over the top where the far side of the disk is
	-- bent up and over), a dark gap, the photon ring, and the shadow on top. A
	-- billboard draws over the sphere behind it, so the shadow has to be part of
	-- the stack rather than the part.
	local HALO = R * 2.6
	local bb = Instance.new("BillboardGui")
	bb.Name = "Halo"
	bb.Size = UDim2.fromScale(HALO * 2, HALO * 2)
	bb.LightInfluence = 0
	bb.Brightness = 2.4
	bb.Adornee = core
	bb.Parent = core
	local z = 0
	local function disc(radius, color, transparency, lift, fade)
		z += 1
		local fr = Instance.new("Frame")
		fr.AnchorPoint = Vector2.new(0.5, 0.5)
		fr.Position = UDim2.fromScale(0.5, 0.5 - (lift or 0) / (HALO * 2))
		fr.Size = UDim2.fromScale(radius / HALO, radius / HALO)
		fr.BackgroundColor3 = color
		fr.BackgroundTransparency = transparency
		fr.BorderSizePixel = 0
		fr.ZIndex = z
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = fr
		if fade then
			-- Brightest over the top, dimmer underneath.
			local g = Instance.new("UIGradient")
			g.Rotation = 90
			g.Transparency = NumberSequence.new({ kp(0, 0), kp(0.55, 0.1), kp(1, fade) })
			g.Parent = fr
		end
		fr.Parent = bb
		return fr
	end
	for k = 0, 11 do
		local u = k / 11
		disc(HALO * (1 - u * 0.38), C3(120, 132, 170):Lerp(C3(236, 242, 255), u), 0.975 - u * 0.06)
	end
	disc(R * 2.15, C3(255, 255, 255), 0.86, R * 0.26) -- bloom round the lensed ring
	disc(R * 1.9, C3(250, 252, 255), 0.12, R * 0.26, 0.55) -- the lensed ring
	disc(R * 1.7, C3(214, 222, 240), 0.6, R * 0.2) -- its soft inner edge
	disc(R * 1.52, C3(0, 0, 0), 0.03, R * 0.12) -- the dark gap
	disc(R * 1.17, C3(255, 255, 255), 0.55) -- photon ring glow
	disc(R * 1.09, C3(255, 255, 255), 0.02) -- photon ring
	disc(R * 1.005, C3(0, 0, 0), 0) -- the shadow

	local disk = T.model(m, "Disk")
	-- Flat bands, dimmest and widest outside, white-hot at the inner edge. The
	-- thicknesses differ so no two faces share a plane. (3.6 R is about as wide
	-- as a part may be.)
	for _, band in ipairs({
		{ 3.6, C3(150, 160, 188), 0.74, 0.4 },
		{ 3.0, C3(202, 210, 230), 0.52, 0.8 },
		{ 2.35, C3(236, 240, 252), 0.3, 1.2 },
		{ 1.6, C3(255, 255, 255), 0.08, 1.6 },
	}) do
		T.mk({ Name = "DiskBand", Parent = disk, Size = Vector3.new(band[4], R * band[1] * 2, R * band[1] * 2), CFrame = tilt * CFrame.Angles(0, 0, math.rad(90)),
			Color = band[2], Material = M.Neon, Shape = Enum.PartType.Cylinder, Transparency = band[3], deco = true, shadow = false })
	end
	-- The grain of the disk: bright streaks running round it, above and below.
	local rng = Random.new(3)
	for i = 1, 46 do
		local a = rng:NextNumber() * math.pi * 2
		local r = R * (1.5 + rng:NextNumber() * 2.0)
		local len = R * (0.25 + rng:NextNumber() * 0.6) * (r / (R * 2))
		local side = (i % 2 == 0) and 1 or -1
		T.mk({ Name = "Streak", Parent = disk, Size = Vector3.new(len, 0.4, R * (0.012 + rng:NextNumber() * 0.03)),
			CFrame = tilt * CFrame.new(math.cos(a) * r, side * (1.1 + (i % 3) * 0.15), math.sin(a) * r) * CFrame.Angles(0, -a - math.pi / 2, 0),
			Color = C3(240, 244, 255), Material = M.Neon, Transparency = 0.2 + rng:NextNumber() * 0.5, deco = true, shadow = false })
	end
	-- Matter spiralling in along the disk. Locked to the part, so as the disk
	-- turns the streaks turn with it on their way down.
	local inflow = T.mk({ Name = "Inflow", Parent = disk, Size = Vector3.new(R * 6.6, 1, R * 6.6), CFrame = tilt, Transparency = 1, deco = true, shadow = false })
	-- A cylinder, not a disc: a disc throws along its normal (straight out of
	-- the disk), a cylinder in toward its axis. Spawned on the rim. A negative
	-- squash stretches a velocity-aligned sprite along its path.
	T.emitter(inflow, {
		Name = "Inflow",
		Shape = Enum.ParticleEmitterShape.Cylinder, ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		Rate = 150, Lifetime = NumberRange.new(2.3, 2.8), Speed = NumberRange.new(R * 1.0, R * 1.15), LockedToPart = true,
		Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = NumberSequence.new({ kp(0, -1), kp(1, -1.8) }),
		LightEmission = 1, LightInfluence = 0, Size = NumberSequence.new({ kp(0, R * 0.1), kp(1, R * 0.045) }),
		Transparency = NumberSequence.new({ kp(0, 1), kp(0.12, 0.2), kp(0.85, 0.1), kp(1, 1) }),
		Color = ColorSequence.new(C3(190, 205, 255), C3(255, 255, 255)), Texture = "rbxasset://textures/particles/sparkles_main.dds",
	})
	disk.WorldPivot = tilt
	-- Everything round it falling in: streaks from every side, spent just as
	-- they reach the shadow.
	local infall = T.ball(m, "Infall", centre, R * 7, C3(0, 0, 0), M.SmoothPlastic, true)
	infall.Transparency = 1
	infall.CastShadow = false
	T.emitter(infall, {
		Name = "Infall",
		Shape = Enum.ParticleEmitterShape.Sphere, ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		Rate = 200, Lifetime = NumberRange.new(1.6, 2), Speed = NumberRange.new(R * 1.2, R * 1.5),
		Orientation = Enum.ParticleOrientation.VelocityParallel, Squash = NumberSequence.new({ kp(0, -1.2), kp(1, -2) }),
		LightEmission = 1, LightInfluence = 0, Size = NumberSequence.new({ kp(0, R * 0.06), kp(0.7, R * 0.08), kp(1, R * 0.04) }),
		Transparency = NumberSequence.new({ kp(0, 1), kp(0.2, 0.1), kp(0.85, 0.05), kp(1, 1) }),
		Color = ColorSequence.new(C3(215, 225, 255), C3(255, 255, 255)), Texture = "rbxasset://textures/particles/sparkles_main.dds",
	})
	-- Used only when it goes off.
	T.ball(m, "Nova", centre, 1, C3(246, 250, 255), M.Neon, true).Transparency = 1
	T.mk({ Name = "Shockwave", Parent = m, Size = Vector3.new(0.6, 1, 1), CFrame = tilt * CFrame.Angles(0, 0, math.rad(90)), Color = C3(226, 236, 255), Material = M.Neon,
		Shape = Enum.PartType.Cylinder, Transparency = 1, deco = true, shadow = false })
	T.emitter(core, {
		Name = "Burst", Enabled = false, Rate = 0, Lifetime = NumberRange.new(2.2, 4), Speed = NumberRange.new(R * 2, R * 5), SpreadAngle = Vector2.new(180, 180),
		LightEmission = 1, LightInfluence = 0, Size = NumberSequence.new({ kp(0, R * 0.14), kp(1, R * 0.03) }), Transparency = NumberSequence.new({ kp(0, 0), kp(1, 1) }),
		Color = ColorSequence.new(C3(255, 255, 255), C3(200, 216, 255)), Texture = "rbxasset://textures/particles/sparkles_main.dds", Drag = 1.2,
	})
	m.WorldPivot = CFrame.new(centre)
	-- Collapse: seconds of it coming apart at the end of the cycle. Implode: the
	-- last of those, in which it falls all the way in. MinScale: how small it
	-- is when it has just re-formed.
	T.tag(m, "AmbBlackHole", { Cycle = CYCLE, Radius = R, FlashRadius = 2600, Collapse = 14, Implode = 1, MinScale = 0.2 })
	m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	return m
end

--------------------------------------------------------------------------------
-- ENTRY POINTS
--------------------------------------------------------------------------------

function EH.dressPortal(kit, pf, zone)
	local step = pf:FindFirstChild("Step")
	if not step then
		return
	end
	step.Material = M.DiamondPlate
	step.Color = DARK
	local base = pf:FindFirstChild("Base")
	if base then
		base.Material = M.Metal
		base.Color = STEEL:Lerp(DARK, 0.5)
	end
	for _, d in ipairs(pf:GetChildren()) do
		if d:IsA("BasePart") and (d.Name == "Jamb" or d.Name == "Lintel") then
			d.Material = M.Metal
			d.Color = STEEL:Lerp(DARK, 0.35)
		elseif d:IsA("BasePart") and (d.Name == "Capital" or d.Name == "Foot" or d.Name == "Keystone") then
			d.Material = M.Metal
			d.Color = DARK
		end
	end
	local cf = step.CFrame * CFrame.new(0, -0.5, 0)
	local dress = Instance.new("Folder")
	dress.Name = "Dress"
	dress.Parent = pf
	for _, s in ipairs({ -1, 1 }) do
		local strip = Instance.new("Part")
		strip.Name = "JambGlow"
		strip.Anchored = true
		strip.CanCollide = false
		strip.CanQuery = false
		strip.CanTouch = false
		strip.Material = M.Neon
		strip.Color = CYAN
		strip.Size = Vector3.new(0.35, 22, 0.35)
		strip.CFrame = cf * CFrame.new(s * 7.35, 14.4, -2.2)
		strip.Parent = dress
	end
end

function EH.outpost(kit, parent, zone, origin, axis)
	T = T or ThemeKit.new(kit, origin, axis)
	local rng = Random.new(29)
	local f = Instance.new("Folder")
	f.Name = "Outpost_" .. zone.id
	f:SetAttribute("ZoneId", zone.id)
	f.Parent = parent
	deck(f, rng)
	collar(f)
	shops(f)
	ringGate(f, zone)
	pylons(f)
	countdownScreens(f)
	asteroidDressing(f, rng)
	blackHole(f)
	T.skyMarker(f, {
		Radius = 520, Fade = 320,
		ClockTime = 23, Brightness = 1.8, OutdoorAmbient = C3(138, 136, 176), Ambient = C3(70, 68, 96), ExposureCompensation = 0.45,
		Density = 0.02, Haze = 0, Glare = 0, Offset = 0, Color = C3(70, 80, 120), Decay = C3(24, 24, 44),
		MoonAngularSize = 0, StarCount = 5000,
	})
	return f
end

-- Per character. workspace.Gravity stays as it is.
function EH.setLowGravity(plr, on)
	if not plr then
		return
	end
	local char = plr.Character
	if not char then
		return
	end
	char:SetAttribute("SpaceSuit", on and true or false)
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or not root then
		return
	end
	local lift = root:FindFirstChild("SpaceLift")
	if not on then
		if lift then
			lift:Destroy()
		end
		local att = root:FindFirstChild("SpaceLiftAtt")
		if att then
			att:Destroy()
		end
		if hum:GetAttribute("SpaceJump") then
			hum.JumpHeight = tonumber(hum:GetAttribute("SpaceJumpSaved")) or 7.2
			hum:SetAttribute("SpaceJump", nil)
			hum:SetAttribute("SpaceJumpSaved", nil)
		end
		return
	end
	if not hum:GetAttribute("SpaceJump") then
		hum:SetAttribute("SpaceJumpSaved", hum.JumpHeight)
		hum:SetAttribute("SpaceJump", true)
	end
	local saved = tonumber(hum:GetAttribute("SpaceJumpSaved")) or 7.2
	hum.JumpHeight = saved * 3
	if not lift then
		local att = Instance.new("Attachment")
		att.Name = "SpaceLiftAtt"
		att.Parent = root
		lift = Instance.new("VectorForce")
		lift.Name = "SpaceLift"
		lift.Attachment0 = att
		lift.RelativeTo = Enum.ActuatorRelativeTo.World
		lift.Parent = root
	end
	local function pushLift()
		if not lift.Parent or not root.Parent then
			return
		end
		local massNow = root.AssemblyMass
		if massNow < 0.1 then
			massNow = 12
		end
		lift.Force = Vector3.new(0, massNow * workspace.Gravity * 0.5, 0)
	end
	pushLift()
	task.defer(pushLift)
end

return EH
