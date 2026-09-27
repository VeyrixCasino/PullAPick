--[[
	MineBloodLake: Bloodmoon Hollow as an island in a lake of blood, sunk in a
	caldera under a blood moon.

	The lake is real terrain water. Water colour is one setting for the whole
	world, so the red is MineAmbience's doing: this zone's sky marker carries
	WaterColor and friends, and a client standing here sees blood while a
	client in Mistreef sees the sea.

	Same contract as every theme: Outpost_<zone> with Shop_sell and Shop_shop
	built through MineShopFronts, stand and portals placed by WorldBuilder.
]]
local ThemeKit = require(script.Parent:WaitForChild("MineThemeKit"))
local C3, smooth = ThemeKit.C3, ThemeKit.smoothstep
local M = Enum.Material

local Blood = {}

local DECK = 1.4
local SEA = -2.5
local STONE = C3(64, 56, 68)
local DARKSTONE = C3(38, 34, 42)
local IRON = C3(34, 32, 36)
local EMBER = C3(255, 66, 50)
local CANDLE = C3(232, 222, 196)
local FLAME = C3(255, 170, 90)
local BLOOD = C3(110, 10, 18)

local T

local function kp(t, v)
	return NumberSequenceKeypoint.new(t, v)
end

-- Islets in zone coordinates: a ruined chapel, a gallows rock, and the ledge
-- the waterfall comes down beside.
local ISLETS = {
	{ l = -168, b = -118, r = 34, h = 5.5 },
	{ l = 176, b = 30, r = 24, h = 4.5 },
	{ l = 30, b = -236, r = 26, h = 3 },
}
Blood.ISLETS = ISLETS

function Blood.terrain(kit, terrain, zone, origin, axis)
	T = ThemeKit.new(kit, origin, axis)
	local G, hole = T.G, T.hole
	local seaY = G + SEA
	local seed = (tonumber(zone.angle) or 0) * 0.53 + 9.7
	local function n2(x, z, f)
		return math.noise(x * f + seed, z * f + seed * 0.3)
	end
	local function baseSample(l, b)
		local r = math.sqrt(l * l + b * b)
		local a = math.atan2(l, b)
		local floor = G - 13 + 2 * n2(l, b, 1 / 37)
		-- The island: the pit, a ring round it and the plaza behind.
		local dx = math.max(math.abs(l) - 72, 0)
		local dz = math.max(b - 162, -74 - b, 0)
		local island = 1 - smooth((math.sqrt(dx * dx + dz * dz) - 4) / 30)
		local top = G + 1.3
		local h = floor + (top - floor) * island
		local mat = (island > 0.8) and M.Slate or M.Mud
		for _, s in ipairs(ISLETS) do
			local d = math.sqrt((l - s.l) ^ 2 + (b - s.b) ^ 2) / s.r
			if d < 1.6 then
				local ih = floor + (G + s.h - floor) * (1 - smooth((d - 0.55) / 0.6)) + n2(l, b, 1 / 9)
				if ih > h then
					h, mat = ih, (d < 0.7) and M.Slate or M.Mud
				end
			end
		end
		-- The caldera wall: cliffs, a ragged rim, lava in the cracks.
		local wallR = 268 + 26 * n2(math.sin(a) * 3, math.cos(a) * 3, 1) + 10 * n2(l, b, 1 / 23)
		local rise = smooth((r - wallR) / 36)
		if rise > 0 then
			local cliff = floor + rise * (62 + 26 * n2(l, b, 1 / 60) + 8 * math.abs(n2(l, b, 1 / 11)))
			if cliff > h then
				h = cliff
				local vein = math.abs(n2(l + 40, b, 1 / 14))
				mat = (vein < 0.05 and rise < 0.9) and M.CrackedLava or ((math.floor(h / 6) % 2 == 0) and M.Basalt or M.Rock)
			end
		end
		if r > 356 then
			h = h - (r - 356) * 3
		end
		-- Under the flagstones the rock steps down out of sight.
		if math.abs(l) <= 72 and b >= hole + 5 and b <= hole + 108 then
			h = G - 2.5
		end
		return h, mat, (r < wallR + 30) and seaY or nil
	end
	-- The falls come down a sheer notch in the caldera wall: walk out along the
	-- falls line until the rock stands tall, keep it full height behind that
	-- line, and cut a gorge in front of it down to the lake floor.
	local fl = 30
	local fb = -250
	while fb > -380 and baseSample(fl, fb) < G + 48 do
		fb -= 2
	end
	local ftop = baseSample(fl, fb)
	Blood.FALLS = { l = fl, b = fb + 3, top = ftop - G }
	local function sample(l, b)
		local h, mat, wet = baseSample(l, b)
		local across = math.abs(l - fl)
		if across < 10 and b > fb - 8 and b < fb + 44 then
			if b <= fb + 1 then
				h = math.max(h, ftop)
			elseif across < 7 then
				h = math.min(h, G - 13)
			end
		end
		return h, mat, wet
	end
	T.fill = M.Basalt
	T.writeTerrain(terrain, 372, -40, 104, sample)
	Blood._sample = sample
end

local function groundAt(l, b)
	local h = Blood._sample and Blood._sample(l, b)
	return h and (h - T.G) or 1.3
end

--------------------------------------------------------------------------------
-- SMALL THINGS
--------------------------------------------------------------------------------

local function candles(parent, pos, count, rng)
	for i = 1, count do
		local a = (i / count) * math.pi * 2 + rng:NextNumber()
		local rr = (i == 1) and 0 or (0.45 + rng:NextNumber() * 0.5)
		local ht = 0.5 + rng:NextNumber() * 1.1
		local base = pos + Vector3.new(math.cos(a) * rr, 0, math.sin(a) * rr)
		T.rod(parent, "Candle", base, base + Vector3.new(0, ht, 0), 0.32, CANDLE, M.SmoothPlastic, true)
		local flame = T.ball(parent, "Flame", base + Vector3.new(0, ht + 0.16, 0), 0.24, FLAME, M.Neon, true)
		if i == 1 then
			T.light(flame, "PointLight", { Color = FLAME, Range = 9, Brightness = 1.2 })
		end
	end
end

local function raven(parent, cf, flying)
	local m = T.model(parent, flying and "RavenFlying" or "Raven")
	local black = C3(22, 20, 26)
	local body = T.blob(m, "Body", cf * CFrame.new(0, 0.55, 0), Vector3.new(0.8, 0.75, 1.9), black, M.SmoothPlastic, true)
	T.ball(m, "Head", (cf * CFrame.new(0, 1.05, -0.9)).Position, 0.62, black, M.SmoothPlastic, true)
	T.wedge(m, "Beak", cf * CFrame.new(0, 1.0, -1.4), Vector3.new(0.15, 0.18, 0.5), C3(50, 48, 54), M.SmoothPlastic, true)
	for _, s in ipairs({ -1, 1 }) do
		T.ball(m, "Eye", (cf * CFrame.new(s * 0.22, 1.12, -1.1)).Position, 0.12, EMBER, M.Neon, true)
		if flying then
			T.mk({ Name = "Wing", Parent = m, Size = Vector3.new(2.6, 0.08, 0.9), CFrame = cf * CFrame.new(s * 1.6, 0.75, 0.05) * CFrame.Angles(0, 0, s * math.rad(10)), Color = black, deco = true })
		else
			T.mk({ Name = "Wing", Parent = m, Size = Vector3.new(0.08, 0.55, 1.5), CFrame = cf * CFrame.new(s * 0.41, 0.66, 0.2), Color = black, deco = true })
		end
	end
	T.wedge(m, "Tail", cf * CFrame.new(0, 0.6, 1.15), Vector3.new(0.55, 0.12, 0.8), black, M.SmoothPlastic, true)
	m.PrimaryPart = body
	return m
end

local function deadTree(parent, l, b, rng, withCage)
	local y = groundAt(l, b)
	local base = T.HP(l, y - 0.5, b)
	local bark = C3(30, 24, 28)
	local h = 11 + rng:NextNumber() * 7
	local lean = Vector3.new(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5))
	local top = base + Vector3.new(0, h, 0) + lean
	T.rod(parent, "DeadTrunk", base, top, 1.3, bark, M.Wood)
	local cageArm
	for k = 1, 4 do
		local from = base:Lerp(top, 0.45 + k * 0.12)
		local a = k * 2.1 + rng:NextNumber()
		local len = 3 + rng:NextNumber() * 4
		local to = from + Vector3.new(math.cos(a) * len, 1.5 + rng:NextNumber() * 2.5, math.sin(a) * len)
		T.rod(parent, "DeadBranch", from, to, 0.45, bark, M.Wood, true)
		local twig = to + Vector3.new(math.cos(a + 0.8) * 1.6, 1.2, math.sin(a + 0.8) * 1.6)
		T.rod(parent, "DeadTwig", to, twig, 0.22, bark, M.Wood, true)
		if k == 2 then
			cageArm = to
		end
	end
	if withCage and cageArm then
		local cage = T.model(parent, "Cage")
		local hang = cageArm - Vector3.new(0, 3.2, 0)
		T.rod(cage, "Chain", cageArm, hang + Vector3.new(0, 1.2, 0), 0.12, IRON, M.Metal, true)
		for i = 0, 5 do
			local a = (i / 6) * math.pi * 2
			local p = hang + Vector3.new(math.cos(a) * 0.9, 0, math.sin(a) * 0.9)
			T.rod(cage, "CageBar", p - Vector3.new(0, 1.3, 0), p + Vector3.new(0, 1.1, 0), 0.1, IRON, M.Metal, true)
		end
		T.rod(cage, "CageRim", hang + Vector3.new(0, 1.1, 0), hang + Vector3.new(0, 1.3, 0), 2.1, IRON, M.Metal, true)
		T.rod(cage, "CageFloor", hang - Vector3.new(0, 1.3, 0), hang - Vector3.new(0, 1.45, 0), 2.1, IRON, M.Metal, true)
		cage.WorldPivot = CFrame.new(cageArm)
		T.tag(cage, "AmbSway", { SwayAmp = 4, SwaySpeed = 0.7, Phase = rng:NextNumber() * 6 })
	end
	if rng:NextNumber() < 0.6 then
		raven(parent, CFrame.new(top + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, rng:NextNumber() * 6, 0), false)
	end
end

local function gravestone(parent, l, b, rng)
	local y = groundAt(l, b)
	local cf = T.H(l, y, b) * CFrame.Angles(math.rad(rng:NextNumber(-9, 9)), rng:NextNumber(-0.5, 0.5), math.rad(rng:NextNumber(-7, 7)))
	local w, ht = 2.2 + rng:NextNumber() * 0.8, 2.6 + rng:NextNumber()
	local col = C3(92, 88, 96):Lerp(C3(60, 58, 66), rng:NextNumber())
	T.mk({ Name = "Gravestone", Parent = parent, Size = Vector3.new(w, ht, 0.6), CFrame = cf * CFrame.new(0, ht / 2 - 0.4, 0), Color = col, Material = M.Slate, noQuery = true })
	T.rod(parent, "GravestoneTop", (cf * CFrame.new(0, ht - 0.4, -0.3)).Position, (cf * CFrame.new(0, ht - 0.4, 0.3)).Position, w, col, M.Slate, true)
end

--------------------------------------------------------------------------------
-- THE ISLAND: flagstones, a red runner up the middle, a stone coping round the
-- pit with iron spikes and candles.
--------------------------------------------------------------------------------

local function plaza(f, rng)
	local g = T.folder(f, "Plaza")
	local hole = T.hole
	local near, far, halfW = hole + 6, hole + 106, 71
	local cols, rows = 8, 6
	local pw, pd = halfW * 2 / cols, (far - near) / rows
	for i = 0, cols - 1 do
		for j = 0, rows - 1 do
			T.mk({ Name = "Flagstone", Parent = g, Size = Vector3.new(pw - 0.22, 1.2, pd - 0.22), CFrame = T.H(-halfW + pw * (i + 0.5), DECK - 0.6, near + pd * (j + 0.5)),
				Color = STONE:Lerp(DARKSTONE, rng:NextNumber() * 0.6), Material = M.Slate })
		end
	end
	T.mk({ Name = "Grout", Parent = g, Size = Vector3.new(halfW * 2 + 1.5, 1.4, far - near + 1.5), CFrame = T.H(0, DECK - 1, (near + far) / 2 + 0.2), Color = C3(20, 16, 20), Material = M.Slate })
	T.mk({ Name = "Runner", Parent = g, Size = Vector3.new(9, 0.12, far - near - 4), CFrame = T.H(0, DECK + 0.06, (near + far) / 2 + 2), Color = BLOOD, Material = M.Fabric, deco = true })
	for _, s in ipairs({ -1, 1 }) do
		T.mk({ Name = "RunnerHem", Parent = g, Size = Vector3.new(0.5, 0.14, far - near - 4), CFrame = T.H(s * 4.7, DECK + 0.07, (near + far) / 2 + 2), Color = C3(170, 130, 60), Material = M.Fabric, deco = true })
	end
end

local function coping(f, rng)
	local g = T.folder(f, "Coping")
	local hole = T.hole
	local low, top = -2.6, DECK + 0.3
	local hgt = top - low
	for _, s in ipairs({ 1, -1 }) do
		T.mk({ Name = "Coping", Parent = g, Size = Vector3.new(hole * 2 + 12, hgt, 6), CFrame = T.H(0, low + hgt / 2, s * (hole + 3)), Color = DARKSTONE, Material = M.Slate })
		T.mk({ Name = "Coping", Parent = g, Size = Vector3.new(6, hgt, hole * 2), CFrame = T.H(s * (hole + 3), low + hgt / 2, 0), Color = DARKSTONE, Material = M.Slate })
	end
	-- Iron spikes along the inner edge, every few studs, facing into the dark.
	for k = -5, 5 do
		for _, spot in ipairs({ { k * 10, hole + 0.6 }, { k * 10, -(hole + 0.6) }, { hole + 0.6, k * 10 }, { -(hole + 0.6), k * 10 } }) do
			local p = T.HP(spot[1], top, spot[2])
			T.wedge(g, "Spike", CFrame.new(p + Vector3.new(0, 0.9, 0)) * CFrame.Angles(math.rad(-90), 0, 0), Vector3.new(0.35, 0.35, 1.8), IRON, M.Metal, true)
		end
	end
	for _, c in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
		local p = T.HP(c[1] * (hole + 3), top, c[2] * (hole + 3))
		T.mk({ Name = "Plinth", Parent = g, Size = Vector3.new(3.2, 1.4, 3.2), CFrame = CFrame.new(p + Vector3.new(0, 0.7, 0)), Color = STONE, Material = M.Slate, noQuery = true })
		candles(g, p + Vector3.new(0, 1.4, 0), 5, rng)
	end
end

--------------------------------------------------------------------------------
-- THE TWO SHOPS: a reliquary that buys your haul and a forge that sells tools.
--------------------------------------------------------------------------------

local function gothicShell(f, cf, W, D, Hh, wall, roof)
	T.mk({ Name = "Floor", Parent = f, Size = Vector3.new(W + 6, 1.2, D + 6), CFrame = cf * CFrame.new(0, 0.6, 0), Color = DARKSTONE, Material = M.Slate })
	T.mk({ Name = "Back", Parent = f, Size = Vector3.new(W, Hh, 1.4), CFrame = cf * CFrame.new(0, Hh / 2, D / 2), Color = wall, Material = M.Slate })
	for _, s in ipairs({ -1, 1 }) do
		T.mk({ Name = "Side", Parent = f, Size = Vector3.new(1.4, Hh, D), CFrame = cf * CFrame.new(s * W / 2, Hh / 2, 0), Color = wall, Material = M.Slate })
		T.mk({ Name = "Buttress", Parent = f, Size = Vector3.new(1.6, Hh * 0.8, 2.2), CFrame = cf * CFrame.new(s * (W / 2 + 0.9), Hh * 0.4, -D / 2 + 1), Color = DARKSTONE, Material = M.Slate })
		T.mk({ Name = "FrontPier", Parent = f, Size = Vector3.new(2.6, Hh, 1.4), CFrame = cf * CFrame.new(s * (W / 2 - 1.3), Hh / 2, -D / 2), Color = wall, Material = M.Slate })
		-- A lancet window of red glass in each side wall.
		T.mk({ Name = "Lancet", Parent = f, Size = Vector3.new(0.2, 4.2, 1.6), CFrame = cf * CFrame.new(s * (W / 2 + 0.72), Hh * 0.55, 0), Color = C3(170, 20, 36), Material = M.Neon, Transparency = 0.25, deco = true })
	end
	-- Steep roof and a stepped gable.
	local half = W / 2 + 1.5
	local rad = math.rad(56)
	local rise = half * math.tan(rad)
	for _, s in ipairs({ -1, 1 }) do
		T.mk({ Name = "RoofPane", Parent = f, Size = Vector3.new(half / math.cos(rad) + 0.4, 0.7, D + 3), CFrame = cf * CFrame.new(s * half / 2, Hh + rise / 2, 0) * CFrame.Angles(0, 0, -s * rad),
			Color = roof, Material = M.Slate })
	end
	for _, z in ipairs({ -1, 1 }) do
		for i = 0, 7 do
			local u = (i + 0.5) / 8
			T.mk({ Name = "GableEnd", Parent = f, Size = Vector3.new(W * (1 - u) + 0.8, rise / 8 + 0.1, 1.2), CFrame = cf * CFrame.new(0, Hh + rise * u, z * D / 2), Color = wall, Material = M.Slate })
		end
	end
	T.mk({ Name = "Lintel", Parent = f, Size = Vector3.new(W - 5.2, 2.2, 1.4), CFrame = cf * CFrame.new(0, Hh - 1.1, -D / 2), Color = wall, Material = M.Slate })
	return rise
end

local function buildReliquary(kit, f, cf, pal, W, D, Hh, title)
	local wall = C3(70, 62, 76)
	local rise = gothicShell(f, cf, W, D, Hh, wall, C3(30, 26, 34))
	-- The rose window, burning red over the door.
	local rose = cf * CFrame.new(0, Hh + rise * 0.35, -D / 2 - 0.7) * CFrame.Angles(0, math.rad(90), 0)
	T.mk({ Name = "RoseFrame", Parent = f, Size = Vector3.new(0.5, 5.6, 5.6), CFrame = rose, Color = DARKSTONE, Material = M.Slate, Shape = Enum.PartType.Cylinder })
	T.mk({ Name = "RoseGlass", Parent = f, Size = Vector3.new(0.6, 4.4, 4.4), CFrame = rose, Color = C3(200, 24, 44), Material = M.Neon, Shape = Enum.PartType.Cylinder, deco = true })
	for k = 0, 3 do
		T.mk({ Name = "RoseTracery", Parent = f, Size = Vector3.new(0.7, 4.4, 0.3), CFrame = cf * CFrame.new(0, Hh + rise * 0.35, -D / 2 - 0.75) * CFrame.Angles(0, 0, k * math.pi / 4),
			Color = DARKSTONE, Material = M.Slate, deco = true })
	end
	-- A bell turret with a spire.
	local tc = cf * CFrame.new(0, Hh + rise, D / 2 - 2)
	T.mk({ Name = "Turret", Parent = f, Size = Vector3.new(3, 4, 3), CFrame = tc * CFrame.new(0, 1.5, 0), Color = wall, Material = M.Slate })
	for i = 0, 3 do
		T.wedge(f, "Spire", tc * CFrame.new(0, 5.5, 0) * CFrame.Angles(0, i * math.pi / 2, 0) * CFrame.new(0, 0, -0.8), Vector3.new(3.2, 5, 1.6), C3(30, 26, 34), M.Slate)
	end
	T.ball(f, "Finial", (tc * CFrame.new(0, 8.3, 0)).Position, 0.7, C3(170, 130, 60), M.Metal, true)
	-- An altar counter with candles, a chalice and jars of something that glows.
	local cz = -D / 2 + 3
	T.mk({ Name = "Counter", Parent = f, Size = Vector3.new(W - 8, 4.4, 3.2), CFrame = cf * CFrame.new(0, 2.2, cz), Color = C3(88, 80, 92), Material = M.Marble })
	T.mk({ Name = "AltarCloth", Parent = f, Size = Vector3.new(W - 7.6, 0.2, 3.6), CFrame = cf * CFrame.new(0, 4.5, cz), Color = BLOOD, Material = M.Fabric, deco = true })
	candles(f, (cf * CFrame.new(-3.8, 4.6, cz)).Position, 4, Random.new(4))
	candles(f, (cf * CFrame.new(3.8, 4.6, cz)).Position, 3, Random.new(5))
	local chalice = (cf * CFrame.new(0, 4.6, cz)).Position
	T.rod(f, "ChaliceStem", chalice, chalice + Vector3.new(0, 0.9, 0), 0.25, C3(190, 150, 70), M.Metal, true)
	T.rod(f, "ChaliceCup", chalice + Vector3.new(0, 0.9, 0), chalice + Vector3.new(0, 1.5, 0), 0.8, C3(190, 150, 70), M.Metal, true)
	T.rod(f, "ChaliceBlood", chalice + Vector3.new(0, 1.5, 0), chalice + Vector3.new(0, 1.55, 0), 0.62, EMBER, M.Neon, true)
	for k, x in ipairs({ -1.6, 1.6 }) do
		local jar = (cf * CFrame.new(x, 4.6, cz + 0.9)).Position
		T.rod(f, "RelicJar", jar, jar + Vector3.new(0, 1.2, 0), 0.8, C3(210, 220, 230), M.Glass, true).Transparency = 0.4
		T.ball(f, "Relic", jar + Vector3.new(0, 0.55, 0), 0.5, (k == 1) and C3(120, 214, 232) or C3(226, 196, 104), M.Neon, true)
	end
	local board = T.mk({ Name = "Sign", Parent = f, Size = Vector3.new(W - 6, 2, 0.3), CFrame = cf * CFrame.new(0, Hh - 1.1, -D / 2 - 0.86), Color = C3(26, 20, 28), Material = M.Wood })
	T.kit.sign(board, string.upper(title or "Reliquary"), Enum.NormalId.Front)
end

local function buildBloodforge(kit, f, cf, pal, W, D, Hh, title)
	local wall = C3(52, 44, 50)
	gothicShell(f, cf, W, D, Hh, wall, C3(24, 20, 24))
	-- The hearth: a mouth of red light at the back, and a chimney breathing embers.
	local hearth = cf * CFrame.new(0, 0, D / 2 - 1.6)
	T.mk({ Name = "Hearth", Parent = f, Size = Vector3.new(7, 4.6, 2), CFrame = hearth * CFrame.new(0, 3.5, 0), Color = DARKSTONE, Material = M.Brick })
	local glow = T.mk({ Name = "HearthFire", Parent = f, Size = Vector3.new(5, 2.4, 0.4), CFrame = hearth * CFrame.new(0, 2.6, -1.05), Color = EMBER, Material = M.Neon, deco = true })
	T.light(glow, "PointLight", { Color = EMBER, Range = 22, Brightness = 2.4 })
	local fire = Instance.new("Fire")
	fire.Size = 4
	fire.Heat = 6
	fire.Color = C3(255, 70, 40)
	fire.SecondaryColor = C3(120, 10, 10)
	fire.Parent = glow
	local chim = T.mk({ Name = "Chimney", Parent = f, Size = Vector3.new(3.2, 12, 3.2), CFrame = cf * CFrame.new(0, Hh + 5, D / 2 - 1.6), Color = DARKSTONE, Material = M.Brick })
	T.emitter(chim, { Texture = "rbxasset://textures/particles/sparkles_main.dds", Rate = 6, Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(5, 9),
		SpreadAngle = Vector2.new(15, 15), EmissionDirection = Enum.NormalId.Top, LightEmission = 1, Color = ColorSequence.new(C3(255, 120, 60), C3(255, 40, 30)),
		Size = NumberSequence.new({ kp(0, 0.5), kp(1, 0.1) }), Acceleration = Vector3.new(0.6, 1, 0) })
	-- Anvil, a trough of red quench, chains on the wall.
	local anvil = cf * CFrame.new(W / 2 + 3, 0, -D / 2 + 1)
	T.mk({ Name = "AnvilBlock", Parent = f, Size = Vector3.new(1.8, 2.2, 1.8), CFrame = anvil * CFrame.new(0, 1.1, 0), Color = C3(60, 42, 30), Material = M.Wood })
	T.mk({ Name = "Anvil", Parent = f, Size = Vector3.new(1.4, 1, 3), CFrame = anvil * CFrame.new(0, 2.7, 0), Color = IRON, Material = M.Metal })
	T.wedge(f, "AnvilHorn", anvil * CFrame.new(0, 2.85, -2.2) * CFrame.Angles(0, math.pi, 0), Vector3.new(1, 0.7, 1.4), IRON, M.Metal, true)
	T.mk({ Name = "Trough", Parent = f, Size = Vector3.new(2.4, 1.8, 4.6), CFrame = cf * CFrame.new(-W / 2 - 2.8, 0.9, -D / 2 + 2), Color = DARKSTONE, Material = M.Slate })
	T.mk({ Name = "Quench", Parent = f, Size = Vector3.new(2, 0.2, 4.2), CFrame = cf * CFrame.new(-W / 2 - 2.8, 1.72, -D / 2 + 2), Color = BLOOD, Material = M.Neon, Transparency = 0.2, deco = true })
	for k = 0, 2 do
		local top = (cf * CFrame.new(-4 + k * 1.2, Hh - 1.5, D / 2 - 0.8)).Position
		T.rod(f, "Chain", top, top - Vector3.new(0, 3 + k * 0.7, 0), 0.2, IRON, M.Metal, true)
	end
	local cz = -D / 2 + 3
	T.mk({ Name = "Counter", Parent = f, Size = Vector3.new(W - 8, 4.4, 3.2), CFrame = cf * CFrame.new(0, 2.2, cz), Color = C3(44, 36, 40), Material = M.Slate })
	T.mk({ Name = "CounterTop", Parent = f, Size = Vector3.new(W - 6.4, 0.5, 4), CFrame = cf * CFrame.new(0, 4.65, cz), Color = IRON, Material = M.Metal })
	local board = T.mk({ Name = "Sign", Parent = f, Size = Vector3.new(W - 6, 2, 0.3), CFrame = cf * CFrame.new(0, Hh - 1.1, -D / 2 - 0.86), Color = C3(26, 20, 28), Material = M.Wood })
	T.kit.sign(board, string.upper(title or "Bloodforge"), Enum.NormalId.Front)
end

local function dressNpc(shop, kind)
	for _, c in ipairs(shop:GetChildren()) do
		if c:IsA("Model") and c.Name:match("^NPC_") then
			local head = c:FindFirstChild("Head")
			if head then
				local hc = head.CFrame
				if kind == "hood" then
					T.blob(c, "Hood", hc * CFrame.new(0, 0.35, 0.25), Vector3.new(2.6, 2.7, 2.7), C3(40, 24, 44), M.Fabric, true)
					for _, s in ipairs({ -1, 1 }) do
						T.ball(c, "GlowEye", (hc * CFrame.new(s * 0.42, 0.1, -1.0)).Position, 0.26, EMBER, M.Neon, true)
					end
				else
					T.blob(c, "Helm", hc * CFrame.new(0, 0.55, 0), Vector3.new(2.25, 1.5, 2.25), IRON, M.Metal, true)
					T.blob(c, "Beard", hc * CFrame.new(0, -0.7, -0.75), Vector3.new(1.8, 1.3, 0.8), C3(60, 30, 26), M.SmoothPlastic, true)
				end
			end
		end
	end
end

local function shops(f)
	local ShopFronts = T.kit.shopFronts
	ShopFronts.STYLES.reliquary = buildReliquary
	ShopFronts.STYLES.bloodforge = buildBloodforge
	local shopB, shopL = T.hole + 40, 38
	for _, spec in ipairs({
		{ l = -shopL, style = "reliquary", title = "Reliquary", verb = "SELL", npc = "Vesper", role = "Buys your haul", machine = "sell", dress = "hood" },
		{ l = shopL, style = "bloodforge", title = "Bloodforge", verb = "SHOP", npc = "Grimm", role = "Tools and bags", machine = "shop", dress = "helm" },
	}) do
		local pos = T.HP(spec.l, DECK, shopB)
		local cf = CFrame.lookAt(pos, T.HP(0, DECK, shopB))
		local shop = ShopFronts.build(T.kit, f, cf, {
			style = spec.style, title = spec.title, verb = spec.verb, npc = spec.npc, role = spec.role, machine = spec.machine,
			pal = { brick = STONE, roof = DARKSTONE, trim = DARKSTONE, accent = C3(90, 20, 34), mat = M.Slate }, locked = false,
		}, T.kit.SHOP_W, T.kit.SHOP_D, T.kit.SHOP_H)
		dressNpc(shop, spec.dress)
	end
end

--------------------------------------------------------------------------------
-- THE GATE, THE LAMPS, THE DEAD
--------------------------------------------------------------------------------

local function redLantern(parent, hook)
	local m = T.model(parent, "RedLantern")
	local d = Vector3.new(0, 1, 0)
	T.rod(m, "Bail", hook, hook - d * 0.6, 0.08, IRON, M.Metal, true)
	T.rod(m, "LanternCap", hook - d * 0.6, hook - d * 0.95, 0.9, IRON, M.Metal, true)
	T.rod(m, "LanternGlass", hook - d * 0.95, hook - d * 2.2, 0.75, C3(200, 40, 40), M.Glass, true).Transparency = 0.35
	local flame = T.ball(m, "LanternFlame", hook - d * 1.55, 0.4, EMBER, M.Neon, true)
	T.light(flame, "PointLight", { Color = EMBER, Range = 20, Brightness = 1.4 })
	T.rod(m, "LanternBase", hook - d * 2.2, hook - d * 2.45, 0.9, IRON, M.Metal, true)
	m.WorldPivot = CFrame.new(hook)
	T.tag(m, "AmbSway", { SwayAmp = 3, SwaySpeed = 0.9 + (hook.X % 1) * 0.4, Phase = hook.Z % 6 })
	return m
end

local function gate(f, zone)
	local g = T.folder(f, "Gate")
	local b = T.hole + 20
	for _, s in ipairs({ -1, 1 }) do
		T.mk({ Name = "GatePillar", Parent = g, Size = Vector3.new(2.8, 15, 2.8), CFrame = T.H(s * 11, DECK + 7.5, b), Color = STONE, Material = M.Slate })
		T.mk({ Name = "PillarBand", Parent = g, Size = Vector3.new(3.2, 0.8, 3.2), CFrame = T.H(s * 11, DECK + 12, b), Color = DARKSTONE, Material = M.Slate })
		for i = 0, 3 do
			T.wedge(g, "PillarCap", T.H(s * 11, DECK + 16.2, b) * CFrame.Angles(0, i * math.pi / 2, 0) * CFrame.new(0, 0, -0.75), Vector3.new(3, 2.4, 1.5), DARKSTONE, M.Slate)
		end
		T.ball(g, "PillarOrb", T.HP(s * 11, DECK + 17.8, b), 1.1, EMBER, M.Neon, true)
		-- The iron arch, rising from each pillar and meeting in a point.
		local last = T.HP(s * 10, DECK + 13, b)
		for k = 1, 5 do
			local u = k / 5
			local p = T.HP(s * 10 * math.cos(u * math.pi / 2), DECK + 13 + 9 * math.sin(u * math.pi / 2) ^ 0.8, b)
			T.beam(g, "ArchIron", last, p, 0.5, 0.5, IRON, M.Metal, true)
			last = p
		end
		redLantern(g, T.HP(s * 9.2, DECK + 11.4, b - 0.2))
	end
	local board = T.mk({ Name = "GateSign", Parent = g, Size = Vector3.new(17, 3.2, 0.4), CFrame = T.H(0, DECK + 16.2, b) * CFrame.Angles(0, math.pi, 0), Color = C3(26, 18, 22), Material = M.Wood })
	T.kit.sign(board, string.upper(zone.name or zone.id), Enum.NormalId.Front)
	T.mk({ Name = "SignRim", Parent = g, Size = Vector3.new(17.6, 3.8, 0.3), CFrame = T.H(0, DECK + 16.2, b - 0.12) * CFrame.Angles(0, math.pi, 0), Color = BLOOD, Material = M.Slate })
	for _, s in ipairs({ -1, 1 }) do
		T.rod(g, "SignChain", T.HP(s * 7.5, DECK + 17.8, b), T.HP(s * 6.2, DECK + 20.6, b), 0.14, IRON, M.Metal, true)
	end
	raven(g, T.H(0, DECK + 22.1, b) * CFrame.Angles(0, math.pi * 0.8, 0), false)
end

local function lamps(f)
	local g = T.folder(f, "Lamps")
	for _, b in ipairs({ T.hole + 14, T.hole + 64, T.hole + 98 }) do
		for _, s in ipairs({ -1, 1 }) do
			local p = T.HP(s * 9, DECK, b)
			T.rod(g, "LampPost", p, p + Vector3.new(0, 9.5, 0), 0.55, IRON, M.Metal)
			T.beam(g, "LampArm", p + Vector3.new(0, 9.2, 0), T.HP(s * 6.3, DECK + 9.2, b), 0.3, 0.35, IRON, M.Metal, true)
			T.ball(g, "LampFinial", p + Vector3.new(0, 9.8, 0), 0.6, IRON, M.Metal, true)
			redLantern(g, T.HP(s * 6.6, DECK + 9, b))
		end
	end
end

local function islandProps(f, rng)
	local g = T.folder(f, "Island")
	for i, spot in ipairs({ { -84, -58 }, { 86, -52 }, { -88, 18 }, { 90, 24 }, { -86, 150 }, { 88, 160 } }) do
		deadTree(g, spot[1], spot[2], rng, i == 2 or i == 5)
	end
	for k = 0, 9 do
		local side = (k % 2 == 0) and -1 or 1
		gravestone(g, side * (80 + rng:NextNumber() * 6), T.hole + 22 + k * 9 + rng:NextNumber() * 3, rng)
	end
	for _, spot in ipairs({ { -60, T.hole + 104 }, { 60, T.hole + 104 }, { -16, T.hole + 26 }, { 16, T.hole + 26 } }) do
		candles(g, T.HP(spot[1], DECK, spot[2]), 6, rng)
	end
end

local function islets(f, rng)
	local g = T.folder(f, "Islets")
	-- The ruined chapel.
	local c = ISLETS[1]
	local cy = groundAt(c.l, c.b)
	local cf = T.H(c.l, cy, c.b) * CFrame.Angles(0, math.rad(20), 0)
	T.mk({ Name = "ChapelFloor", Parent = g, Size = Vector3.new(20, 1.4, 28), CFrame = cf * CFrame.new(0, -0.3, 0), Color = DARKSTONE, Material = M.Slate })
	for k, w in ipairs({ { -9.3, 0, 1.4, 11, 12 }, { -9.3, 9, 1.4, 5, 9 }, { 9.3, -6, 1.4, 7, 14 }, { 9.3, 8, 1.4, 12, 10 }, { 0, 13.3, 18, 13, 1.4 } }) do
		T.mk({ Name = "ChapelWall", Parent = g, Size = Vector3.new(w[3], w[4], w[5]), CFrame = cf * CFrame.new(w[1], w[4] / 2, w[2]), Color = STONE:Lerp(DARKSTONE, k * 0.12), Material = M.Slate })
	end
	T.mk({ Name = "ChapelWindow", Parent = g, Size = Vector3.new(3, 5.6, 1.6), CFrame = cf * CFrame.new(0, 7.5, 13.3), Color = C3(170, 20, 36), Material = M.Neon, Transparency = 0.3, deco = true })
	for i = 1, 4 do
		T.mk({ Name = "FallenStone", Parent = g, Size = Vector3.new(2 + rng:NextNumber() * 2, 1.4 + rng:NextNumber(), 2 + rng:NextNumber() * 3),
			CFrame = cf * CFrame.new(rng:NextNumber(-7, 7), 0.8, rng:NextNumber(-12, 4)) * CFrame.Angles(rng:NextNumber(), rng:NextNumber() * 3, rng:NextNumber()),
			Color = STONE, Material = M.Slate, noQuery = true })
	end
	for _, z in ipairs({ -4, 1 }) do
		T.mk({ Name = "Pew", Parent = g, Size = Vector3.new(9, 0.4, 1.6), CFrame = cf * CFrame.new(0, 1.9, z) * CFrame.Angles(0, 0, math.rad(z * 1.5)), Color = C3(54, 36, 30), Material = M.Wood })
	end
	T.mk({ Name = "Altar", Parent = g, Size = Vector3.new(5, 3, 2.4), CFrame = cf * CFrame.new(0, 1.5, 10), Color = C3(88, 80, 92), Material = M.Marble })
	candles(g, (cf * CFrame.new(-1.5, 3, 10)).Position, 5, rng)
	raven(g, cf * CFrame.new(9.3, 12.1, 8) * CFrame.Angles(0, 2.2, 0), false)
	-- The gallows rock: a cage, a lamp and a warning.
	local q = ISLETS[2]
	local qy = groundAt(q.l, q.b)
	local qp = T.HP(q.l, qy, q.b)
	T.rod(g, "GibbetPost", qp, qp + Vector3.new(0, 12, 0), 1, C3(40, 30, 28), M.Wood)
	T.beam(g, "GibbetArm", qp + Vector3.new(0, 11.4, 0), qp + T.side * 5 + Vector3.new(0, 11.4, 0), 0.7, 0.8, C3(40, 30, 28), M.Wood)
	T.beam(g, "GibbetBrace", qp + Vector3.new(0, 8.4, 0), qp + T.side * 2.6 + Vector3.new(0, 11.2, 0), 0.4, 0.4, C3(40, 30, 28), M.Wood, true)
	local cage = T.model(g, "Cage")
	local hang = qp + T.side * 4.6 + Vector3.new(0, 7.2, 0)
	T.rod(cage, "Chain", hang + Vector3.new(0, 4, 0), hang + Vector3.new(0, 1.4, 0), 0.12, IRON, M.Metal, true)
	for i = 0, 5 do
		local a = (i / 6) * math.pi * 2
		local p = hang + Vector3.new(math.cos(a) * 1.1, 0, math.sin(a) * 1.1)
		T.rod(cage, "CageBar", p - Vector3.new(0, 1.6, 0), p + Vector3.new(0, 1.4, 0), 0.12, IRON, M.Metal, true)
	end
	T.rod(cage, "CageRim", hang + Vector3.new(0, 1.4, 0), hang + Vector3.new(0, 1.6, 0), 2.5, IRON, M.Metal, true)
	T.rod(cage, "CageFloor", hang - Vector3.new(0, 1.6, 0), hang - Vector3.new(0, 1.8, 0), 2.5, IRON, M.Metal, true)
	cage.WorldPivot = CFrame.new(hang + Vector3.new(0, 4, 0))
	T.tag(cage, "AmbSway", { SwayAmp = 5, SwaySpeed = 0.6, Phase = 1 })
	local warn = T.mk({ Name = "WarningBoard", Parent = g, Size = Vector3.new(3.4, 1.6, 0.25), CFrame = CFrame.lookAt(qp + Vector3.new(-2.5, 2.6, 0), T.HP(0, qy + 2.6, 0)), Color = C3(70, 56, 44), Material = M.Wood, noQuery = true })
	T.writeOn(warn, "TURN BACK", { font = Enum.Font.Creepster, color = C3(170, 20, 30), pps = 40 })
	redLantern(g, qp + T.side * 1.2 + Vector3.new(0, 10.6, 0))
	raven(g, CFrame.new(qp + Vector3.new(0, 12.1, 0)) * CFrame.Angles(0, 1, 0), false)
end

--------------------------------------------------------------------------------
-- THE SKY AND THE LAKE: the blood moon, the falls, bubbles, mist and ravens.
--------------------------------------------------------------------------------

local function bloodMoon(f)
	local m = T.model(f, "BloodMoon")
	local centre = T.HP(-260, 400, -900)
	local R = 120
	local toward = (T.HP(0, 20, 0) - centre).Unit
	local face = CFrame.lookAt(centre, centre + toward)
	local body = T.ball(m, "Moon", centre, R * 2, C3(150, 16, 26), M.Neon, true)
	body.CastShadow = false
	for i, c in ipairs({ { 0.35, 0.2, 0.22 }, { -0.3, -0.25, 0.16 }, { 0.05, -0.45, 0.12 }, { -0.4, 0.35, 0.1 } }) do
		T.blob(m, "Mare", face * CFrame.new(c[1] * R, c[2] * R, -R * 0.93) * CFrame.Angles(0, 0, i), Vector3.new(R * c[3] * 2, R * c[3] * 1.6, R * 0.2),
			C3(120, 16, 24), M.Neon, true).CastShadow = false
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "MoonGlow"
	bb.Size = UDim2.fromScale(R * 4.2, R * 4.2)
	bb.LightInfluence = 0
	bb.Brightness = 1.5
	bb.Adornee = body
	bb.Parent = body
	for k = 0, 5 do
		local fr = Instance.new("Frame")
		fr.AnchorPoint = Vector2.new(0.5, 0.5)
		fr.Position = UDim2.fromScale(0.5, 0.5)
		fr.Size = UDim2.fromScale(1 - k * 0.09, 1 - k * 0.09)
		fr.BackgroundColor3 = C3(200, 30, 40)
		fr.BackgroundTransparency = 0.96 - k * 0.012
		fr.BorderSizePixel = 0
		fr.ZIndex = k
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = fr
		fr.Parent = bb
	end
	m.WorldPivot = CFrame.new(centre)
	m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
end

local function waterfall(f)
	local g = T.folder(f, "Falls")
	local F = Blood.FALLS
	if not F then
		return
	end
	local height = F.top - SEA
	for i, sheet in ipairs({ { 11, 1.4, C3(110, 10, 18), 0.08 }, { 7, 1, C3(165, 24, 34), 0.28 } }) do
		T.mk({ Name = "FallSheet", Parent = g, Size = Vector3.new(sheet[1], height, sheet[2]), CFrame = T.H(F.l, SEA + height / 2, F.b + 1 + (i - 1) * 0.8),
			Color = sheet[3], Material = M.Neon, Transparency = sheet[4], deco = true, shadow = false })
	end
	local lip = T.source(g, "FallLip", T.HP(F.l, F.top + 0.5, F.b + 1.5), Vector3.new(10, 1, 2))
	T.emitter(lip, { Shape = Enum.ParticleEmitterShape.Box, EmissionDirection = Enum.NormalId.Bottom, Rate = 30, Lifetime = NumberRange.new(1.4, 2),
		Speed = NumberRange.new(14, 22), Acceleration = Vector3.new(0, -30, 0), Size = NumberSequence.new({ kp(0, 1.2), kp(1, 2.8) }),
		Transparency = NumberSequence.new({ kp(0, 0.2), kp(1, 0.8) }), Color = ColorSequence.new(C3(150, 20, 30)), Texture = "rbxasset://textures/particles/sparkles_main.dds" })
	local foot = T.source(g, "FallFoot", T.HP(F.l, SEA + 0.4, F.b + 5), Vector3.new(12, 1, 6))
	T.emitter(foot, { Shape = Enum.ParticleEmitterShape.Box, EmissionDirection = Enum.NormalId.Top, Rate = 8, Lifetime = NumberRange.new(2, 3),
		Speed = NumberRange.new(3, 7), SpreadAngle = Vector2.new(60, 60), Size = NumberSequence.new({ kp(0, 4), kp(1, 13) }),
		Transparency = NumberSequence.new({ kp(0, 0.55), kp(1, 1) }), Color = ColorSequence.new(C3(150, 40, 50)), Texture = "rbxasset://textures/particles/smoke_main.dds" })
	T.mk({ Name = "Foam", Parent = g, Size = Vector3.new(0.3, 16, 16), CFrame = T.H(F.l, SEA + 0.12, F.b + 7) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C3(170, 40, 52), Material = M.Neon, Shape = Enum.PartType.Cylinder, Transparency = 0.55, deco = true, shadow = false })
end

local function lakeLife(f, rng)
	local g = T.folder(f, "Lake")
	for _ = 1, 10 do
		local a, r = rng:NextNumber() * math.pi * 2, 120 + rng:NextNumber() * 120
		local l, b = math.cos(a) * r, math.sin(a) * r
		if groundAt(l, b) < SEA - 2 then
			local src = T.source(g, "Bubbles", T.HP(l, SEA + 0.2, b), Vector3.new(6, 0.5, 6))
			T.emitter(src, { Shape = Enum.ParticleEmitterShape.Box, EmissionDirection = Enum.NormalId.Top, Rate = 2.5, Lifetime = NumberRange.new(0.6, 1),
				Speed = NumberRange.new(1.5, 3), SpreadAngle = Vector2.new(25, 25), Size = NumberSequence.new({ kp(0, 0.8), kp(1, 2.2) }),
				Transparency = NumberSequence.new({ kp(0, 0.2), kp(1, 1) }), Color = ColorSequence.new(C3(150, 20, 30)), LightEmission = 0.1,
				Texture = "rbxasset://textures/particles/sparkles_main.dds" })
		end
	end
	for i = 0, 9 do
		local a = (i / 10) * math.pi * 2 + rng:NextNumber() * 0.3
		local r = 130 + rng:NextNumber() * 100
		local l, b = math.cos(a) * r, math.sin(a) * r
		if groundAt(l, b) < SEA - 1 then
			local src = T.source(g, "RedMist", T.HP(l, SEA + 2, b), Vector3.new(60, 1, 60))
			T.emitter(src, { Texture = "rbxasset://textures/particles/smoke_main.dds", Shape = Enum.ParticleEmitterShape.Box, EmissionDirection = Enum.NormalId.Top,
				Rate = 0.8, Lifetime = NumberRange.new(15, 24), Speed = NumberRange.new(0.4, 0.9), SpreadAngle = Vector2.new(60, 60),
				Size = NumberSequence.new({ kp(0, 16), kp(1, 36) }), Transparency = NumberSequence.new({ kp(0, 1), kp(0.25, 0.86), kp(0.7, 0.89), kp(1, 1) }),
				Color = ColorSequence.new(C3(150, 70, 80)), LightInfluence = 0.7, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-5, 5), Drag = 0.3 })
		end
	end
	for k, o in ipairs({ { 54, 36, 0.28 }, { 86, 44, -0.22 }, { 118, 52, 0.18 }, { 70, 60, -0.3 } }) do
		local centre = T.HP(0, 0, 40)
		local bird = raven(g, CFrame.new(centre + Vector3.new(o[1], T.G + o[2], 0)), true)
		T.tag(bird, "AmbOrbit", { Center = Vector3.new(centre.X, T.G + o[2], centre.Z), Radius = o[1], Speed = o[3], Phase = k * 1.7, Bank = 18 })
	end
end

--------------------------------------------------------------------------------
-- ENTRY POINTS
--------------------------------------------------------------------------------

function Blood.dressPortal(kit, pf, zone)
	local step = pf:FindFirstChild("Step")
	if not step then
		return
	end
	local look = Vector3.new(step.CFrame.LookVector.X, 0, step.CFrame.LookVector.Z)
	if look.Magnitude < 0.05 then
		look = Vector3.zAxis
	else
		look = look.Unit
	end
	T = T or ThemeKit.new(kit, step.Position, look)
	for _, d in ipairs(pf:GetChildren()) do
		if d:IsA("BasePart") then
			if d.Name == "Step" or d.Name == "Base" then
				d.Material, d.Color = M.Slate, DARKSTONE
			elseif d.Name == "Jamb" or d.Name == "Lintel" then
				d.Material, d.Color = M.Slate, STONE
			elseif d.Name == "Capital" or d.Name == "Foot" or d.Name == "Keystone" then
				d.Material, d.Color = M.Slate, C3(90, 20, 34)
			end
		end
	end
	local cf = step.CFrame * CFrame.new(0, -0.5, 0)
	local dress = Instance.new("Folder")
	dress.Name = "Dress"
	dress.Parent = pf
	local rng = Random.new(8)
	for _, s in ipairs({ -1, 1 }) do
		candles(dress, (cf * CFrame.new(s * 12, 2.4, -8.5)).Position, 5, rng)
		T.beam(dress, "LanternBracket", (cf * CFrame.new(s * 11.7, 18, 0)).Position, (cf * CFrame.new(s * 13.7, 18, 0)).Position, 0.3, 0.3, IRON, M.Metal, true)
		redLantern(dress, (cf * CFrame.new(s * 13.5, 17.8, 0)).Position)
	end
	for k = -1, 1 do
		T.wedge(dress, "LintelSpike", cf * CFrame.new(k * 7, 32.6, 0) * CFrame.Angles(math.rad(-90), 0, 0), Vector3.new(0.6, 0.6, 2.6), IRON, M.Metal, true)
	end
end

function Blood.outpost(kit, parent, zone, origin, axis)
	T = T or ThemeKit.new(kit, origin, axis)
	local rng = Random.new(13)
	local f = Instance.new("Folder")
	f.Name = "Outpost_" .. zone.id
	f:SetAttribute("ZoneId", zone.id)
	f.Parent = parent
	plaza(f, rng)
	coping(f, rng)
	shops(f)
	gate(f, zone)
	lamps(f)
	islandProps(f, rng)
	islets(f, rng)
	bloodMoon(f)
	waterfall(f)
	lakeLife(f, rng)
	T.skyMarker(f, {
		Radius = 420, Fade = 240,
		ClockTime = 0.4, Brightness = 1.7, OutdoorAmbient = C3(132, 76, 86), Ambient = C3(66, 36, 46), ExposureCompensation = 0.3,
		Density = 0.26, Haze = 0.55, Glare = 0.15, Offset = 0.1, Color = C3(150, 64, 74), Decay = C3(76, 22, 32),
		WaterColor = C3(84, 6, 14), WaterTransparency = 0.03, WaterReflectance = 0.35, WaterWaveSize = 0.05, WaterWaveSpeed = 2.5,
		MoonAngularSize = 0,
	})
	return f
end

return Blood
