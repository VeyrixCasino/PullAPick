-- MineShopFronts: a different building for every trade.
--
-- Every station used to be the same box -- floor, back wall, two sides, a flat
-- roof and a striped awning -- recoloured seven ways. That is why the lobby read
-- as a row of market stalls with nothing to tell them apart: colour is the
-- weakest possible signal, and at any distance they were identical.
--
-- Each trade now gets its own silhouette, so you can tell the forge from the
-- scrapyard from across the plaza without reading a sign:
--
--   forge    a stone hearth under a tall smoking chimney, anvil out front
--   depot    an open timber yard with a balance scale and stacked ore crates
--   arcane   a round tower with a dome and a crucible floating between pillars
--   works    a corrugated industrial shed fed by a hopper and pipework
--   spire    a narrow tower with a spiked roof and standing runestones
--   board    an open lean-to built around a notice board
--   rotunda  a marble ring of columns, open to the sky
--
-- The kit is passed in rather than required, because WorldBuilder owns `part`,
-- `sign`, `npc` and `pad` as locals and they are the pieces that must stay
-- consistent with the rest of the world.
local MineShopFronts = {}

local function C3(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local DARK = C3(32, 30, 38)
local CREAM = C3(236, 228, 210)
local STONE = C3(120, 116, 110)
local IRON = C3(78, 80, 88)
local TIMBER = C3(112, 82, 52)

--------------------------------------------------------------------------------
-- Shared pieces. Every trade gets a floor, a counter, a sign, a light, an NPC
-- and a pad; what differs is the building around them.
--------------------------------------------------------------------------------

local function base(kit, f, cf, pal, W, D)
	kit.part({ Name = "Floor", Parent = f, Size = Vector3.new(W + 6, 1.2, D + 6),
		CFrame = cf * CFrame.new(0, 0.6, 0), Color = C3(96, 92, 88), Material = Enum.Material.Slate })
	kit.part({ Name = "FloorTrim", Parent = f, Size = Vector3.new(W + 7.4, 0.5, D + 7.4),
		CFrame = cf * CFrame.new(0, 0.25, 0), Color = pal.trim, Material = Enum.Material.Slate })
end

local function counter(kit, f, cf, pal, W, D, top)
	kit.part({ Name = "Counter", Parent = f, Size = Vector3.new(W - 8, 4.4, 3.2),
		CFrame = cf * CFrame.new(0, 2.2, -D / 2 + 3), Color = pal.trim,
		Material = Enum.Material.WoodPlanks })
	kit.part({ Name = "CounterTop", Parent = f, Size = Vector3.new(W - 6, 0.6, 4.4),
		CFrame = cf * CFrame.new(0, 4.7, -D / 2 + 3), Color = top or CREAM,
		Material = Enum.Material.Wood })
end

local function signboard(kit, f, cf, pal, title, W, y, z, hangFrom)
	-- Hung from a bracket that visibly reaches the building. Free-floating
	-- boards were the other thing that made the stalls look unfinished.
	hangFrom = hangFrom or (y + 4)
	local board = kit.part({ Name = "Sign", Parent = f, Size = Vector3.new(W - 8, 2.9, 0.5),
		CFrame = cf * CFrame.new(0, y, z), Color = DARK, Material = Enum.Material.SmoothPlastic })
	kit.sign(board, string.upper(title), Enum.NormalId.Front)
	kit.part({ Name = "SignFrame", Parent = f, Size = Vector3.new(W - 7, 3.7, 0.3),
		CFrame = cf * CFrame.new(0, y, z + 0.25), Color = pal.trim,
		Material = Enum.Material.WoodPlanks })
	-- Beam back to the wall, plus two hangers down to the board.
	kit.part({ Name = "SignBeam", Parent = f, Size = Vector3.new(W - 7, 0.7, 0.7),
		CFrame = cf * CFrame.new(0, hangFrom, z), Color = IRON, Material = Enum.Material.Metal })
	for _, s in ipairs({ -1, 1 }) do
		kit.part({ Name = "SignIron", Parent = f,
			Size = Vector3.new(0.3, math.max(0.6, hangFrom - y - 1.5), 0.3),
			CFrame = cf * CFrame.new(s * (W - 9) * 0.5, (y + hangFrom) / 2 + 0.75, z),
			Color = IRON, Material = Enum.Material.Metal })
		kit.part({ Name = "SignStay", Parent = f, Size = Vector3.new(0.45, 0.45, math.abs(z) * 0.8),
			CFrame = cf * CFrame.new(s * (W - 9) * 0.5, hangFrom, z * 0.5),
			Color = IRON, Material = Enum.Material.Metal })
	end
	return board
end

local function lamp(kit, f, cf, pal, pos, colour, range)
	local bulb = kit.part({ Name = "Lamp", Parent = f, Size = Vector3.new(1.4, 0.7, 1.4),
		CFrame = cf * pos, Color = colour or C3(255, 226, 158), Material = Enum.Material.Neon })
	local pl = Instance.new("PointLight")
	pl.Brightness = 1.6
	pl.Range = range or 34
	pl.Color = colour or C3(255, 226, 158)
	pl.Parent = bulb
	return bulb
end

-- A pitched roof, built from two slabs leaning against each other. Flat roofs
-- are exactly what made the old stalls interchangeable.
local function gable(kit, f, cf, pal, W, D, H, pitch)
	pitch = pitch or 26
	-- Solved rather than eyeballed: each pane spans from the eave at
	-- (+/-half, H) to the ridge at (0, H + rise), so the two meet at the top
	-- instead of drifting apart with a gap down the middle.
	local half = W / 2 + 3
	local rad = math.rad(pitch)
	local rise = half * math.tan(rad)
	local len = half / math.cos(rad)
	for _, s in ipairs({ -1, 1 }) do
		kit.part({ Name = "RoofPane", Parent = f, Size = Vector3.new(len, 0.9, D + 7),
			CFrame = cf * CFrame.new(s * half / 2, H + rise / 2, 0)
				* CFrame.Angles(0, 0, -s * rad),
			Color = pal.roof, Material = Enum.Material.Slate })
		-- Gable end, closing the triangle so you cannot see into the loft.
		for i = 0, 4 do
			local u = (i + 0.5) / 5
			kit.part({ Name = "GableEnd", Parent = f,
				Size = Vector3.new(W * (1 - u) + 1, rise / 5 + 0.2, 1.2),
				CFrame = cf * CFrame.new(0, H + rise * u, s * (D / 2 + 3)),
				Color = pal.brick, Material = pal.mat })
		end
	end
	kit.part({ Name = "Ridge", Parent = f, Size = Vector3.new(2, 1, D + 8),
		CFrame = cf * CFrame.new(0, H + rise + 0.3, 0), Color = pal.trim,
		Material = Enum.Material.WoodPlanks })
	-- Eave boards, so the roof lands on something.
	for _, s in ipairs({ -1, 1 }) do
		kit.part({ Name = "Eave", Parent = f, Size = Vector3.new(1.4, 1.2, D + 8),
			CFrame = cf * CFrame.new(s * half, H - 0.2, 0), Color = pal.trim,
			Material = Enum.Material.WoodPlanks })
	end
	return rise
end

local function walls(kit, f, cf, pal, W, D, H, openFront)
	kit.part({ Name = "Back", Parent = f, Size = Vector3.new(W, H, 1.4),
		CFrame = cf * CFrame.new(0, H / 2, D / 2), Color = pal.brick, Material = pal.mat })
	kit.part({ Name = "SideL", Parent = f, Size = Vector3.new(1.4, H, D),
		CFrame = cf * CFrame.new(-W / 2, H / 2, 0), Color = pal.brick, Material = pal.mat })
	kit.part({ Name = "SideR", Parent = f, Size = Vector3.new(1.4, H, D),
		CFrame = cf * CFrame.new(W / 2, H / 2, 0), Color = pal.brick, Material = pal.mat })
	if not openFront then
		kit.part({ Name = "Lintel", Parent = f, Size = Vector3.new(W + 2, 2.6, 1.6),
			CFrame = cf * CFrame.new(0, H - 1.4, -D / 2), Color = pal.trim,
			Material = Enum.Material.WoodPlanks })
	end
end

local function posts(kit, f, cf, pal, W, D, H, colour, mat)
	for _, x in ipairs({ -W / 2, W / 2 }) do
		kit.part({ Name = "Post", Parent = f, Size = Vector3.new(1.5, H, 1.5),
			CFrame = cf * CFrame.new(x, H / 2, -D / 2),
			Color = colour or TIMBER, Material = mat or Enum.Material.Wood })
	end
end

--------------------------------------------------------------------------------
-- FORGE  (blacksmith)
--
-- The one building in the lobby that should look like work happens in it.
--------------------------------------------------------------------------------

local function buildForge(kit, f, cf, pal, W, D, H, title)
	base(kit, f, cf, pal, W, D)
	walls(kit, f, cf, pal, W, D, H, true)
	gable(kit, f, cf, pal, W, D, H, 30)
	posts(kit, f, cf, pal, W, D, H, IRON, Enum.Material.Metal)

	-- Chimney: the silhouette that says "forge" from anywhere in the plaza.
	local chim = cf * CFrame.new(W * 0.34, 0, D * 0.3)
	kit.part({ Name = "Chimney", Parent = f, Size = Vector3.new(5.2, H + 13, 5.2),
		CFrame = chim * CFrame.new(0, (H + 13) / 2, 0), Color = C3(104, 98, 92),
		Material = Enum.Material.Brick })
	kit.part({ Name = "ChimneyCap", Parent = f, Size = Vector3.new(6.4, 1.2, 6.4),
		CFrame = chim * CFrame.new(0, H + 13.4, 0), Color = IRON, Material = Enum.Material.Metal })
	for i = 0, 3 do
		kit.part({ Name = "CapLeg", Parent = f, Size = Vector3.new(0.5, 1.6, 0.5),
			CFrame = chim * CFrame.new(0, H + 12.4, 0) * CFrame.Angles(0, math.rad(i * 90 + 45), 0)
				* CFrame.new(2.4, 0, 0), Color = IRON, Material = Enum.Material.Metal })
	end
	-- Smoke.
	local smokePart = kit.part({ Name = "SmokeVent", Parent = f, Size = Vector3.new(1, 1, 1),
		CFrame = chim * CFrame.new(0, H + 13.6, 0), Color = C3(60, 58, 58),
		Material = Enum.Material.SmoothPlastic })
	smokePart.Transparency = 1
	local smoke = Instance.new("Smoke")
	smoke.Size = 7
	smoke.RiseVelocity = 6
	smoke.Opacity = 0.28
	smoke.Color = C3(96, 92, 90)
	smoke.Parent = smokePart

	-- The hearth itself: a glowing mouth in the back wall.
	local hearth = cf * CFrame.new(-W * 0.2, 0, D * 0.28)
	kit.part({ Name = "Hearth", Parent = f, Size = Vector3.new(7.5, 5.5, 4),
		CFrame = hearth * CFrame.new(0, 2.75, 0), Color = C3(84, 78, 74),
		Material = Enum.Material.Brick })
	kit.part({ Name = "HearthHood", Parent = f, Size = Vector3.new(8.4, 1.4, 4.8),
		CFrame = hearth * CFrame.new(0, 6, 0), Color = IRON, Material = Enum.Material.Metal })
	local coals = kit.part({ Name = "Coals", Parent = f, Size = Vector3.new(5.2, 2.4, 0.6),
		CFrame = hearth * CFrame.new(0, 2.6, -2.1), Color = C3(255, 132, 44),
		Material = Enum.Material.Neon })
	local fl = Instance.new("PointLight")
	fl.Brightness = 3
	fl.Range = 30
	fl.Color = C3(255, 148, 60)
	fl.Parent = coals
	local fire = Instance.new("Fire")
	fire.Heat = 6
	fire.Size = 5
	fire.Color = C3(255, 170, 70)
	fire.SecondaryColor = C3(180, 60, 20)
	fire.Parent = coals

	-- Anvil on a stump, out front where you can see it.
	local anvilAt = cf * CFrame.new(-W * 0.3, 1.2, -D / 2 + 1.5)
	kit.part({ Name = "Stump", Parent = f, Size = Vector3.new(3.2, 2.6, 3.2),
		CFrame = anvilAt * CFrame.new(0, 1.3, 0), Color = C3(96, 68, 44),
		Material = Enum.Material.Wood })
	kit.part({ Name = "AnvilBody", Parent = f, Size = Vector3.new(4.4, 1.5, 2.2),
		CFrame = anvilAt * CFrame.new(0, 3.3, 0), Color = C3(58, 60, 68),
		Material = Enum.Material.Metal })
	kit.part({ Name = "AnvilWaist", Parent = f, Size = Vector3.new(1.8, 1.1, 1.8),
		CFrame = anvilAt * CFrame.new(0, 2.4, 0), Color = C3(58, 60, 68),
		Material = Enum.Material.Metal })
	kit.part({ Name = "AnvilHorn", Parent = f, Size = Vector3.new(2, 0.9, 1.1),
		CFrame = anvilAt * CFrame.new(-2.8, 3.3, 0) * CFrame.Angles(0, 0, math.rad(-6)),
		Color = C3(66, 68, 76), Material = Enum.Material.Metal })

	-- Quench trough and a rack of finished work.
	kit.part({ Name = "Trough", Parent = f, Size = Vector3.new(5, 2, 2.6),
		CFrame = cf * CFrame.new(W * 0.3, 2, -D / 2 + 2), Color = C3(88, 62, 40),
		Material = Enum.Material.Wood })
	kit.part({ Name = "Water", Parent = f, Size = Vector3.new(4.4, 0.3, 2.1),
		CFrame = cf * CFrame.new(W * 0.3, 2.9, -D / 2 + 2), Color = C3(84, 132, 150),
		Material = Enum.Material.Glass })

	local rackAt = cf * CFrame.new(-W * 0.42, 0, D * 0.05)
	kit.part({ Name = "Rack", Parent = f, Size = Vector3.new(0.6, 7, 6),
		CFrame = rackAt * CFrame.new(0, 3.5, 0), Color = TIMBER, Material = Enum.Material.Wood })
	for i = 0, 2 do
		kit.part({ Name = "RackTool", Parent = f, Size = Vector3.new(0.4, 4.2, 0.4),
			CFrame = rackAt * CFrame.new(0.6, 4.2, -2 + i * 2) * CFrame.Angles(math.rad(8 * i - 8), 0, 0),
			Color = C3(150, 152, 158), Material = Enum.Material.Metal })
	end

	counter(kit, f, cf, pal, W, D, C3(196, 176, 150))
	signboard(kit, f, cf, pal, title or "Blacksmith", W, H + 2.2, -D / 2 - 2.6, H + 6.2)
	lamp(kit, f, cf, pal, CFrame.new(0, H - 2, -1), C3(255, 190, 120), 32)
end

--------------------------------------------------------------------------------
-- DEPOT  (ore buyer)
--------------------------------------------------------------------------------

local function buildDepot(kit, f, cf, pal, W, D, H, title)
	base(kit, f, cf, pal, W, D)
	-- Open on three sides: a yard, not a shop.
	kit.part({ Name = "Back", Parent = f, Size = Vector3.new(W, H, 1.4),
		CFrame = cf * CFrame.new(0, H / 2, D / 2), Color = pal.brick, Material = pal.mat })
	posts(kit, f, cf, pal, W, D, H)
	for _, x in ipairs({ -W / 2, W / 2 }) do
		kit.part({ Name = "Post", Parent = f, Size = Vector3.new(1.5, H, 1.5),
			CFrame = cf * CFrame.new(x, H / 2, D / 2 - 2), Color = TIMBER, Material = Enum.Material.Wood })
	end
	-- Flat tarp roof slung between the posts.
	kit.part({ Name = "Tarp", Parent = f, Size = Vector3.new(W + 7, 0.6, D + 7),
		CFrame = cf * CFrame.new(0, H + 0.6, 0) * CFrame.Angles(math.rad(-5), 0, 0),
		Color = pal.roof, Material = Enum.Material.Fabric })
	for i = 0, 5 do
		kit.part({ Name = "TarpRib", Parent = f, Size = Vector3.new(0.5, 0.5, D + 7),
			CFrame = cf * CFrame.new(-W / 2 + (W / 5) * i, H + 1, 0) * CFrame.Angles(math.rad(-5), 0, 0),
			Color = TIMBER, Material = Enum.Material.Wood })
	end

	-- A big balance scale: the thing that says "we weigh your haul".
	local scaleAt = cf * CFrame.new(W * 0.3, 0, -D / 2 + 3)
	kit.part({ Name = "ScaleMast", Parent = f, Size = Vector3.new(0.9, 9, 0.9),
		CFrame = scaleAt * CFrame.new(0, 4.5, 0), Color = IRON, Material = Enum.Material.Metal })
	kit.part({ Name = "ScaleBeam", Parent = f, Size = Vector3.new(9, 0.6, 0.6),
		CFrame = scaleAt * CFrame.new(0, 8.6, 0) * CFrame.Angles(0, 0, math.rad(-7)),
		Color = IRON, Material = Enum.Material.Metal })
	for _, s in ipairs({ -1, 1 }) do
		local drop = s < 0 and 1.4 or -1.4
		kit.part({ Name = "ScaleChain", Parent = f, Size = Vector3.new(0.2, 2.4, 0.2),
			CFrame = scaleAt * CFrame.new(s * 4.2, 7.3 + drop * 0.5, 0),
			Color = IRON, Material = Enum.Material.Metal })
		kit.part({ Name = "ScalePan", Parent = f, Size = Vector3.new(3.4, 0.4, 3.4),
			CFrame = scaleAt * CFrame.new(s * 4.2, 6 + drop, 0),
			Color = C3(196, 158, 92), Material = Enum.Material.Metal })
	end

	-- Stacked crates and a spill of ore.
	local ORE = { C3(196, 112, 54), C3(150, 152, 158), C3(120, 200, 235), C3(226, 190, 90) }
	for i, o in ipairs({ { -0.36, 0, 2 }, { -0.26, 2.6, 1.6 }, { -0.42, 5.2, 2.4 } }) do
		kit.part({ Name = "Crate", Parent = f, Size = Vector3.new(4, 2.6, 4),
			CFrame = cf * CFrame.new(W * o[1], 2.5 + o[2], D * 0.12 + o[3])
				* CFrame.Angles(0, math.rad(i * 13), 0),
			Color = C3(126, 92, 58), Material = Enum.Material.WoodPlanks })
		local chunk = kit.part({ Name = "Ore", Parent = f, Size = Vector3.new(1.5, 1.5, 1.5),
			CFrame = cf * CFrame.new(W * o[1] + 0.6, 4.4 + o[2], D * 0.12 + o[3])
				* CFrame.Angles(math.rad(20), math.rad(i * 40), math.rad(15)),
			Color = ORE[(i - 1) % #ORE + 1], Material = Enum.Material.Slate })
		chunk.Reflectance = 0.1
	end

	counter(kit, f, cf, pal, W, D, C3(214, 190, 152))
	signboard(kit, f, cf, pal, title or "Depot", W, H + 2.4, -D / 2 - 2.6, H + 5.4)
	lamp(kit, f, cf, pal, CFrame.new(-W * 0.3, H - 1.5, -1), C3(255, 216, 150), 32)
end

--------------------------------------------------------------------------------
-- ARCANE  (fusery)
--------------------------------------------------------------------------------

local function buildArcane(kit, f, cf, pal, W, D, H, title)
	base(kit, f, cf, pal, W, D)
	-- A round tower: no straight walls anywhere.
	local drum = kit.part({ Name = "Drum", Parent = f, Size = Vector3.new(H, W + 2, W + 2),
		CFrame = cf * CFrame.new(0, H / 2 + 0.6, 1.5) * CFrame.Angles(0, 0, math.rad(90)),
		Color = pal.brick, Material = pal.mat })
	drum.Shape = Enum.PartType.Cylinder
	for i = 0, 7 do
		kit.part({ Name = "Rib", Parent = f, Size = Vector3.new(0.8, H, 0.8),
			CFrame = cf * CFrame.new(0, H / 2 + 0.6, 1.5) * CFrame.Angles(0, math.rad(i * 45), 0)
				* CFrame.new(0, 0, (W + 2) / 2), Color = pal.trim, Material = Enum.Material.Slate })
	end
	-- Dome.
	for i = 0, 3 do
		local u = i / 4
		local d = kit.part({ Name = "Dome", Parent = f,
			Size = Vector3.new(1.6, (W + 2) * (1 - u * 0.55), (W + 2) * (1 - u * 0.55)),
			CFrame = cf * CFrame.new(0, H + 1.2 + i * 1.5, 1.5) * CFrame.Angles(0, 0, math.rad(90)),
			Color = pal.roof, Material = Enum.Material.Slate })
		d.Shape = Enum.PartType.Cylinder
	end
	local finial = kit.part({ Name = "Finial", Parent = f, Size = Vector3.new(2.4, 2.4, 2.4),
		CFrame = cf * CFrame.new(0, H + 8, 1.5), Color = pal.accent, Material = Enum.Material.Neon })
	finial.Shape = Enum.PartType.Ball
	local fpl = Instance.new("PointLight")
	fpl.Brightness = 2
	fpl.Range = 40
	fpl.Color = pal.accent
	fpl.Parent = finial

	-- Three pedestals and a crucible: the fusion, made literal.
	for i = 0, 2 do
		local at = cf * CFrame.new(0, 0, -D * 0.18) * CFrame.Angles(0, math.rad(i * 120 + 180), 0)
			* CFrame.new(0, 0, 5.2)
		kit.part({ Name = "Pedestal", Parent = f, Size = Vector3.new(1.8, 4.2, 1.8),
			CFrame = at * CFrame.new(0, 2.1, 0), Color = pal.trim, Material = Enum.Material.Slate })
		local shard = kit.part({ Name = "Shard", Parent = f, Size = Vector3.new(1.1, 2.2, 1.1),
			CFrame = at * CFrame.new(0, 5.2, 0) * CFrame.Angles(0, math.rad(i * 30), math.rad(12)),
			Color = pal.accent, Material = Enum.Material.Neon })
		shard.Transparency = 0.15
	end
	local cru = kit.part({ Name = "Crucible", Parent = f, Size = Vector3.new(3.4, 3.4, 3.4),
		CFrame = cf * CFrame.new(0, 7.5, -D * 0.18), Color = pal.accent, Material = Enum.Material.Neon })
	cru.Shape = Enum.PartType.Ball
	cru.Transparency = 0.25
	for i = 0, 1 do
		local ring = kit.part({ Name = "Halo", Parent = f, Size = Vector3.new(0.35, 6.4, 6.4),
			CFrame = cf * CFrame.new(0, 7.5, -D * 0.18)
				* CFrame.Angles(math.rad(i * 62 - 31), 0, math.rad(90)),
			Color = pal.trim, Material = Enum.Material.Neon })
		ring.Shape = Enum.PartType.Cylinder
		ring.Transparency = 0.3
	end

	counter(kit, f, cf, pal, W, D, C3(206, 190, 226))
	signboard(kit, f, cf, pal, title or "Fusery", W, H + 2.6, -D / 2 - 2.4, H + 6)
	lamp(kit, f, cf, pal, CFrame.new(0, H - 3, -2), pal.accent, 30)
end

--------------------------------------------------------------------------------
-- WORKS  (scrapper)
--------------------------------------------------------------------------------

local function buildWorks(kit, f, cf, pal, W, D, H, title)
	base(kit, f, cf, pal, W, D)
	walls(kit, f, cf, pal, W, D, H, true)
	posts(kit, f, cf, pal, W, D, H, IRON, Enum.Material.Metal)
	-- Corrugated single-pitch roof.
	kit.part({ Name = "Roof", Parent = f, Size = Vector3.new(W + 8, 0.8, D + 8),
		CFrame = cf * CFrame.new(0, H + 1.6, 0) * CFrame.Angles(math.rad(-12), 0, 0),
		Color = pal.roof, Material = Enum.Material.CorrodedMetal })
	for i = 0, 9 do
		kit.part({ Name = "Corrugate", Parent = f, Size = Vector3.new(0.5, 0.5, D + 8),
			CFrame = cf * CFrame.new(-W / 2 - 3 + ((W + 7) / 9) * i, H + 2.1, 0)
				* CFrame.Angles(math.rad(-12), 0, 0),
			Color = pal.trim, Material = Enum.Material.CorrodedMetal })
	end

	-- Hopper: a funnel on legs, feeding a bin. Unmistakably a machine.
	local hopAt = cf * CFrame.new(W * 0.28, 0, D * 0.2)
	for i = 0, 3 do
		local u = i / 4
		kit.part({ Name = "Hopper", Parent = f,
			Size = Vector3.new(6.5 - u * 4.4, 1.6, 6.5 - u * 4.4),
			CFrame = hopAt * CFrame.new(0, 11 - i * 1.6, 0),
			Color = pal.brick:Lerp(DARK, u * 0.3), Material = Enum.Material.DiamondPlate })
	end
	kit.part({ Name = "Spout", Parent = f, Size = Vector3.new(1.8, 3, 1.8),
		CFrame = hopAt * CFrame.new(0, 3.6, 0), Color = IRON, Material = Enum.Material.Metal })
	for _, s in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			kit.part({ Name = "HopperLeg", Parent = f, Size = Vector3.new(0.6, 9, 0.6),
				CFrame = hopAt * CFrame.new(s * 2.6, 5.5, z * 2.6)
					* CFrame.Angles(z * math.rad(4), 0, -s * math.rad(4)),
				Color = IRON, Material = Enum.Material.Metal })
		end
	end
	local bin = kit.part({ Name = "Bin", Parent = f, Size = Vector3.new(5, 3.4, 5),
		CFrame = hopAt * CFrame.new(0, 1.7, 0), Color = C3(70, 74, 80),
		Material = Enum.Material.DiamondPlate })
	local dust = kit.part({ Name = "Dust", Parent = f, Size = Vector3.new(4.2, 0.4, 4.2),
		CFrame = hopAt * CFrame.new(0, 3.3, 0), Color = pal.accent, Material = Enum.Material.Neon })
	local dl = Instance.new("PointLight")
	dl.Brightness = 1.6
	dl.Range = 24
	dl.Color = pal.accent
	dl.Parent = dust
	bin.Reflectance = 0.05

	-- Pipework along the back wall.
	for i = 0, 2 do
		local pipe = kit.part({ Name = "Pipe", Parent = f, Size = Vector3.new(W * 0.7, 1, 1),
			CFrame = cf * CFrame.new(-W * 0.1, 4 + i * 3, D / 2 - 1.6)
				* CFrame.Angles(0, 0, math.rad(90)),
			Color = i % 2 == 0 and C3(120, 96, 72) or IRON, Material = Enum.Material.Metal })
		pipe.Shape = Enum.PartType.Cylinder
	end

	counter(kit, f, cf, pal, W, D, C3(186, 196, 172))
	signboard(kit, f, cf, pal, title or "Scrapper", W, H + 2.4, -D / 2 - 2.6, H + 5.6)
	lamp(kit, f, cf, pal, CFrame.new(-W * 0.28, H - 2, -1), pal.accent, 28)
end

--------------------------------------------------------------------------------
-- SPIRE  (enchanter)
--------------------------------------------------------------------------------

local function buildSpire(kit, f, cf, pal, W, D, H, title)
	base(kit, f, cf, pal, W, D)
	local TW = W * 0.62
	kit.part({ Name = "Tower", Parent = f, Size = Vector3.new(TW, H + 10, TW),
		CFrame = cf * CFrame.new(0, (H + 10) / 2, D * 0.18), Color = pal.brick, Material = pal.mat })
	for i = 0, 2 do
		kit.part({ Name = "Band", Parent = f, Size = Vector3.new(TW + 1.2, 0.8, TW + 1.2),
			CFrame = cf * CFrame.new(0, 5 + i * 6, D * 0.18), Color = pal.trim,
			Material = Enum.Material.Slate })
	end
	-- Spiked roof.
	for i = 0, 5 do
		local u = i / 6
		kit.part({ Name = "Spike", Parent = f,
			Size = Vector3.new(TW * (1 - u * 0.85), 1.7, TW * (1 - u * 0.85)),
			CFrame = cf * CFrame.new(0, H + 10.6 + i * 1.6, D * 0.18) * CFrame.Angles(0, math.rad(u * 30), 0),
			Color = pal.roof, Material = Enum.Material.Slate })
	end
	local tip = kit.part({ Name = "Tip", Parent = f, Size = Vector3.new(1.1, 3.4, 1.1),
		CFrame = cf * CFrame.new(0, H + 21, D * 0.18), Color = pal.accent, Material = Enum.Material.Neon })
	tip.Reflectance = 0.2

	-- Standing runestones out front.
	for i = -1, 1, 2 do
		local at = cf * CFrame.new(i * W * 0.34, 0, -D / 2 + 2)
		kit.part({ Name = "Runestone", Parent = f, Size = Vector3.new(2.4, 7, 1.6),
			CFrame = at * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, math.rad(i * 12), math.rad(i * 3)),
			Color = C3(98, 94, 112), Material = Enum.Material.Rock })
		local glyph = kit.part({ Name = "Glyph", Parent = f, Size = Vector3.new(1.2, 1.2, 0.2),
			CFrame = at * CFrame.new(0, 4.6, -0.9) * CFrame.Angles(0, math.rad(i * 12), math.rad(45)),
			Color = pal.accent, Material = Enum.Material.Neon })
		glyph.Transparency = 0.1
	end

	counter(kit, f, cf, pal, W, D, C3(178, 172, 208))
	signboard(kit, f, cf, pal, title or "Enchanter", W, H + 2.2, -D / 2 - 2.4, H + 5.4)
	lamp(kit, f, cf, pal, CFrame.new(0, H - 3, -1.5), pal.accent, 28)
end

--------------------------------------------------------------------------------
-- BOARD  (job board)
--------------------------------------------------------------------------------

local function buildBoard(kit, f, cf, pal, W, D, H, title)
	base(kit, f, cf, pal, W, D)
	-- A lean-to, not a shop: two posts and a sloping shingle roof.
	posts(kit, f, cf, pal, W, D, H)
	for _, x in ipairs({ -W / 2, W / 2 }) do
		kit.part({ Name = "PostBack", Parent = f, Size = Vector3.new(1.5, H + 4, 1.5),
			CFrame = cf * CFrame.new(x, (H + 4) / 2, D / 2), Color = TIMBER, Material = Enum.Material.Wood })
	end
	kit.part({ Name = "Roof", Parent = f, Size = Vector3.new(W + 6, 0.9, D + 6),
		CFrame = cf * CFrame.new(0, H + 2.4, 0.5) * CFrame.Angles(math.rad(-16), 0, 0),
		Color = pal.roof, Material = Enum.Material.WoodPlanks })

	-- The board itself, with notices pinned to it.
	local boardAt = cf * CFrame.new(0, 0, D * 0.22)
	kit.part({ Name = "Board", Parent = f, Size = Vector3.new(W - 2, H - 1, 0.8),
		CFrame = boardAt * CFrame.new(0, (H - 1) / 2 + 1, 0), Color = C3(94, 68, 44),
		Material = Enum.Material.WoodPlanks })
	kit.part({ Name = "BoardFrame", Parent = f, Size = Vector3.new(W, H + 0.6, 0.5),
		CFrame = boardAt * CFrame.new(0, (H - 1) / 2 + 1, 0.3), Color = pal.trim,
		Material = Enum.Material.Wood })
	local rng = Random.new(7)
	for i = 1, 7 do
		local note = kit.part({ Name = "Notice", Parent = f,
			Size = Vector3.new(2 + rng:NextNumber() * 0.9, 2.6 + rng:NextNumber(), 0.16),
			CFrame = boardAt * CFrame.new(
				-W * 0.34 + rng:NextNumber() * W * 0.68,
				2.6 + rng:NextNumber() * (H - 4),
				-0.5) * CFrame.Angles(0, 0, math.rad(rng:NextNumber() * 16 - 8)),
			Color = i % 3 == 0 and C3(226, 208, 160) or CREAM, Material = Enum.Material.SmoothPlastic })
		note.Reflectance = 0
	end

	counter(kit, f, cf, pal, W, D, C3(214, 196, 154))
	signboard(kit, f, cf, pal, title or "Job Board", W, H + 3, -D / 2 - 2.4, H + 6)
	lamp(kit, f, cf, pal, CFrame.new(0, H + 0.5, -2), C3(255, 224, 170), 26)
end

--------------------------------------------------------------------------------
-- ROTUNDA  (cloud gate)
--------------------------------------------------------------------------------

local function buildRotunda(kit, f, cf, pal, W, D, H, title)
	base(kit, f, cf, pal, W, D)
	local R = W * 0.52
	for i = 0, 7 do
		local at = cf * CFrame.new(0, 0, 1) * CFrame.Angles(0, math.rad(i * 45 + 22.5), 0)
			* CFrame.new(0, 0, R)
		local col = kit.part({ Name = "Column", Parent = f, Size = Vector3.new(H, 2, 2),
			CFrame = at * CFrame.new(0, H / 2 + 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = pal.brick, Material = pal.mat })
		col.Shape = Enum.PartType.Cylinder
		kit.part({ Name = "Capital", Parent = f, Size = Vector3.new(2.8, 1, 2.8),
			CFrame = at * CFrame.new(0, H + 1.1, 0), Color = pal.trim, Material = Enum.Material.Marble })
		kit.part({ Name = "Plinth", Parent = f, Size = Vector3.new(2.8, 1, 2.8),
			CFrame = at * CFrame.new(0, 1.1, 0), Color = pal.trim, Material = Enum.Material.Marble })
	end
	-- Architrave ring on top of the columns.
	for i = 0, 15 do
		kit.part({ Name = "Architrave", Parent = f, Size = Vector3.new(R * 0.85, 1.4, 2.4),
			CFrame = cf * CFrame.new(0, H + 2.2, 1) * CFrame.Angles(0, math.rad(i * 22.5 + 11.25), 0)
				* CFrame.new(0, 0, R), Color = pal.roof, Material = Enum.Material.Marble })
	end
	-- The gate disc, floating in the middle of the ring.
	local disc = kit.part({ Name = "Gate", Parent = f, Size = Vector3.new(0.6, R * 1.1, R * 1.1),
		CFrame = cf * CFrame.new(0, 5.5, 1) * CFrame.Angles(math.rad(90), 0, math.rad(90)),
		Color = pal.accent, Material = Enum.Material.Neon })
	disc.Shape = Enum.PartType.Cylinder
	disc.Transparency = 0.42
	local gl = Instance.new("PointLight")
	gl.Brightness = 2.4
	gl.Range = 46
	gl.Color = pal.accent
	gl.Parent = disc
	for i = 0, 5 do
		local cloud = kit.part({ Name = "Cloud", Parent = f,
			Size = Vector3.new(4.5 - i * 0.3, 1.6, 3.4),
			CFrame = cf * CFrame.new(0, 8 + (i % 3) * 2.2, 1)
				* CFrame.Angles(0, math.rad(i * 60), 0) * CFrame.new(0, 0, R * 0.55),
			Color = CREAM, Material = Enum.Material.SmoothPlastic })
		cloud.Transparency = 0.25
	end

	counter(kit, f, cf, pal, W, D, CREAM)
	signboard(kit, f, cf, pal, title or "Cloud Gate", W, H + 3.4, -D / 2 - 2.4, H + 6.6)
end

--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------

local BUILDERS = {
	forge = buildForge,
	depot = buildDepot,
	arcane = buildArcane,
	works = buildWorks,
	spire = buildSpire,
	board = buildBoard,
	rotunda = buildRotunda,
}

--[[
	Build one station.

	`kit` supplies WorldBuilder's own helpers: part, sign, npc, pad.
	`spec` is the STATIONS row: style, title, npc, role, verb, machine, locked, pal.
]]
function MineShopFronts.build(kit, parent, cf, spec, W, D, H)
	local f = Instance.new("Folder")
	f.Name = "Shop_" .. (spec.machine or spec.title:gsub("%s", ""))
	f.Parent = parent

	local builder = BUILDERS[spec.style] or buildDepot
	-- The style draws the building; the SPEC names it. A style used by a station
	-- it was not designed for used to keep its own sign, which is how a bench
	-- once ended up standing under a board reading JOB BOARD.
	builder(kit, f, cf, spec.pal, W, D, H, spec.title)

	-- Face the pad (customer approach). Blind yaw-180 put Look·toPad at -1.
	local padOff = Vector3.new(0, 0.35, -D / 2 - 8)
	local npcOff = Vector3.new(0, 1.2, D / 2 - 6)
	local padWorld = (cf * CFrame.new(padOff)).Position
	local npcFeet = (cf * CFrame.new(npcOff)).Position
	kit.npc(f, CFrame.lookAt(npcFeet, Vector3.new(padWorld.X, npcFeet.Y, padWorld.Z)),
		Color3.fromRGB(226, 186, 148), spec.pal.accent, Color3.fromRGB(58, 56, 70),
		spec.npc, spec.role)
	kit.pad(f, cf * CFrame.new(padOff), spec.verb,
		spec.npc .. "  -  " .. spec.title, spec.machine, spec.locked)
	return f
end

MineShopFronts.STYLES = BUILDERS

return MineShopFronts
