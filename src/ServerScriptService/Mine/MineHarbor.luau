--[[
	MineHarbor: Mistreef Depths, built as a harbour.

	From Sunscar on, every island was the same square with the same two shops,
	arch, lamps and banners in a different colour. Mistreef breaks the pattern:
	the mine is sunk in a misty atoll lagoon behind a timber cofferdam, and the
	square is a wharf standing out over the water from a sandy cove.

	WorldBuilder still owns everything the server looks up by name. This module
	builds Outpost_<zone> with Shop_sell and Shop_shop through MineShopFronts, so
	each still has Pad_<id>/Ring and a Counter; WorldBuilder places the stand and
	the portals where every zone has them, which is on the wharf.

	Dressing is CanCollide/CanQuery/CanTouch false (`deco`), so nothing that hangs
	over the pit can swallow a mining click. Motion -- boats, buoys, kelp, gulls,
	the lighthouse beam -- is tagged here and played on the client by
	MineAmbience; the server never moves a part.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local MineConfig = require(ReplicatedStorage:WaitForChild("Mine"):WaitForChild("Shared"):WaitForChild("MineConfig"))

local Harbor = {}

local function C3(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local M = Enum.Material
local WET = C3(58, 50, 42) -- timber that lives below the tide line
local TIMBER = C3(116, 90, 64)
local DRIFT = C3(152, 144, 130) -- sun-bleached
local ROPE = C3(178, 148, 102)
local IRON = C3(60, 62, 68)
local BRASS = C3(186, 148, 72)
local ALGAE = C3(48, 80, 58)
local SALT = C3(200, 204, 192)
local RED = C3(160, 52, 44)
local WHITE = C3(234, 232, 224)
local LAMP = C3(255, 204, 138)
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local DECK = 1.4 -- deck top above GROUND: the height of every outpost square
local SEA = -2.5 -- water surface above GROUND

-- Per build: the kit WorldBuilder hands over, and the harbour's own frame.
-- HF's X is `side`, Y is up, Z is `back` (toward where you arrive), and its
-- origin is the pit centre at GROUND, so H(l, y, b) reads like buildOutpost's at().
local K, HF, G

local function setFrame(kit, origin, axis)
	K = kit
	G = kit.GROUND
	local side = Vector3.new(-axis.Z, 0, axis.X)
	HF = CFrame.fromMatrix(Vector3.new(origin.X, G, origin.Z), side, Vector3.yAxis, -axis)
end

local function H(l, y, b)
	return HF * CFrame.new(l, y, b)
end

local function HP(l, y, b)
	return (HF * CFrame.new(l, y, b)).Position
end

local function mk(props)
	local p
	if props.Class then
		p = Instance.new(props.Class)
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Size = props.Size
		p.CFrame = props.CFrame
		p.Color = props.Color or TIMBER
		p.Material = props.Material or M.SmoothPlastic
		p.Name = props.Name or props.Class
		p.Parent = props.Parent
	else
		p = K.part(props)
	end
	if props.deco then
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
	end
	if props.Reflectance then
		p.Reflectance = props.Reflectance
	end
	if props.shadow == false then
		p.CastShadow = false
	end
	return p
end

-- A cylinder from a to b. A cylinder Part's axis is its own X.
local function rod(parent, name, a, b, d, color, material, deco)
	local v = b - a
	local mid = (a + b) * 0.5
	local cf
	if math.abs(v.Unit.Y) > 0.999 then
		cf = CFrame.new(mid) * CFrame.Angles(0, 0, math.rad(90))
	else
		cf = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.rad(90), 0)
	end
	return mk({ Name = name, Parent = parent, Size = Vector3.new(v.Magnitude, d, d), CFrame = cf,
		Color = color, Material = material or M.Wood, Shape = Enum.PartType.Cylinder, deco = deco })
end

-- A square-section timber from a to b.
local function beam(parent, name, a, b, w, h, color, material, deco)
	local v = b - a
	local up = (math.abs(v.Unit.Y) > 0.999) and Vector3.xAxis or Vector3.yAxis
	return mk({ Name = name, Parent = parent, Size = Vector3.new(w, h, v.Magnitude),
		CFrame = CFrame.lookAt((a + b) * 0.5, b, up), Color = color, Material = material or M.Wood, deco = deco })
end

local function ball(parent, name, pos, d, color, material, deco)
	return mk({ Name = name, Parent = parent, Size = Vector3.new(d, d, d), CFrame = CFrame.new(pos),
		Color = color, Material = material or M.SmoothPlastic, Shape = Enum.PartType.Ball, deco = deco })
end

-- An ellipsoid: a block wearing a sphere mesh, which (unlike a Ball) stretches.
local function blob(parent, name, cf, size, color, material, deco)
	local p = mk({ Name = name, Parent = parent, Size = size, CFrame = cf, Color = color,
		Material = material or M.SmoothPlastic, deco = deco })
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

local function wedge(parent, name, cf, size, color, material, deco)
	return mk({ Class = "WedgePart", Name = name, Parent = parent, Size = size, CFrame = cf,
		Color = color, Material = material, deco = deco })
end

-- A rope that sags. Beam handles run along each attachment's X axis, so both
-- attachments point theirs straight down and the curve bellies under the line.
local function rope(host0, p0, host1, p1, sag, width, color)
	local down = Vector3.new(0, -1, 0)
	local a0 = Instance.new("Attachment")
	a0.Parent = host0
	a0.WorldCFrame = CFrame.fromMatrix(p0, down, Vector3.xAxis)
	local a1 = Instance.new("Attachment")
	a1.Parent = host1
	a1.WorldCFrame = CFrame.fromMatrix(p1, down, Vector3.xAxis)
	local b = Instance.new("Beam")
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.Width0 = width or 0.17
	b.Width1 = width or 0.17
	b.Color = ColorSequence.new(color or ROPE)
	b.LightInfluence = 1
	b.FaceCamera = true
	b.Segments = 14
	local s = (sag or 0) / 0.75 -- a cubic with both handles at depth s dips 0.75 s
	b.CurveSize0 = s
	b.CurveSize1 = -s
	b.Parent = host0
	return b
end

local function model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- Motion for MineAmbience. Models stream whole, or a boat arrives hull first.
local function tag(inst, name, attrs)
	for k, v in pairs(attrs or {}) do
		inst:SetAttribute(k, v)
	end
	if inst:IsA("Model") then
		inst.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end
	CollectionService:AddTag(inst, name)
	return inst
end

local function smoothstep(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

--------------------------------------------------------------------------------
-- THE LAGOON
--
-- One heightfield written straight into the voxels, not a pile of FillBalls:
-- a cove behind the wharf, dunes behind the cove, a lagoon floor that deepens
-- away from the platform, a low sand spit closing the atoll on the far side,
-- sea stacks, reef rocks, and the islet the lighthouse stands on.
--
-- Two measured facts drive the arithmetic:
--   * a SOLID voxel [y0, y0+4) at occupancy o draws its surface at y0 + 2 + 4o;
--   * a LIQUID voxel draws its surface at y0 + 4o, no offset.
-- Shorelines let one voxel hold sand at the bottom and water above it.
--------------------------------------------------------------------------------

local R_OUT = 372 -- the atoll's outer foot, in studs from the pit

-- Rock features in harbour coordinates. `base` is added to GROUND; `p` is the
-- falloff power: 2 is a rounded hill, 4 is a steep-sided stack.
local ROCKS = {
	-- the lighthouse islet, dead ahead past the pit
	{ l = -96, b = -240, r = 42, h = 26, base = -19, p = 2.2 },
	{ l = -60, b = -250, r = 22, h = 21, base = -19, p = 2.6 }, -- the keeper's shoulder
	-- sea stacks
	{ l = -232, b = -128, r = 12, h = 50, base = -21, p = 4 },
	{ l = -254, b = -90, r = 7, h = 30, base = -21, p = 4 },
	{ l = 198, b = -178, r = 11, h = 42, base = -21, p = 4 },
	{ l = 86, b = -272, r = 14, h = 56, base = -21, p = 4 },
	{ l = 112, b = -284, r = 7, h = 27, base = -21, p = 4 },
	{ l = 252, b = -34, r = 10, h = 36, base = -21, p = 4 },
	-- reef rocks that just break the surface
	{ l = -176, b = 36, r = 10, h = 12, base = -15, p = 2 },
	{ l = -194, b = 12, r = 7, h = 11, base = -15, p = 2 },
	{ l = 184, b = -44, r = 9, h = 12, base = -15, p = 2 },
	{ l = 150, b = -124, r = 8, h = 11, base = -15, p = 2 },
	{ l = -30, b = -214, r = 9, h = 12, base = -15, p = 2 },
}
Harbor.ROCKS = ROCKS

function Harbor.terrain(kit, terrain, zone, origin, axis)
	setFrame(kit, origin, axis)
	local seaY = G + SEA
	local Y0, Y1 = -40, 60
	local nY = (Y1 - Y0) // 4
	local pitHalf = MineConfig.GRID * MineConfig.BLOCK * 0.5 + 5
	local seed = (tonumber(zone.angle) or 0) * 0.731 + 17.3
	local sideV = Vector3.new(-axis.Z, 0, axis.X)
	local backV = -axis

	local function n2(x, z, f)
		return math.noise(x * f + seed, z * f + seed * 0.5)
	end

	-- Surface height (world y) and its material at harbour coordinates.
	local function column(l, b)
		local r = math.sqrt(l * l + b * b)
		local c = math.cos(math.atan2(l, b)) -- 1 behind the wharf, -1 past the pit
		local dunes = (1 + c) * 0.5
		local shore = 140 + 160 * ((1 - c) * 0.5) ^ 0.8 + 12 * n2(l, b, 1 / 80)
		local floor = G - 11 - 8 * smoothstep((r - 100) / 130) + 1.5 * n2(l, b, 1 / 31)
		local beach = G - 0.6
		local land = beach
			+ (6 + math.max(0, n2(l, b, 1 / 44)) * 7) * dunes * smoothstep((r - shore - 40) / 60)
		local h = floor + (land - floor) * smoothstep((r - shore + 30) / 45)
		local mat = M.Sand
		if h > seaY - 1.6 and h < seaY + 1.4 then
			mat = M.Ground -- wet sand where the water laps
		elseif h < seaY - 1 and n2(l, b, 1 / 23) > 0.3 then
			mat = M.Ground -- darker patches on the lagoon floor
		elseif h > G + 3 and n2(l + 50, b, 1 / 17) > 0.12 then
			mat = M.LeafyGrass -- marram on the dunes (no blades: not Grass)
		end
		for _, s in ipairs(ROCKS) do
			local d = math.sqrt((l - s.l) ^ 2 + (b - s.b) ^ 2) / s.r
			if d < 2.4 then
				local top = G + s.base + s.h * math.exp(-(d ^ s.p)) + 1.1 * n2(l, b, 1 / 7)
				if top > h then
					h = top
					mat = ((math.floor(top / 5) % 3) == 0) and M.Slate or M.Rock
				end
			end
		end
		h -= 70 * smoothstep((r - (R_OUT - 34)) / 34) -- the atoll's outer fall
		return h, mat, r, shore
	end

	terrain:FillBlock(CFrame.new(origin.X, 10, origin.Z), Vector3.new(R_OUT * 2 + 40, 110, R_OUT * 2 + 40), M.Air)
	local minX = math.floor((origin.X - R_OUT) / 4) * 4
	local minZ = math.floor((origin.Z - R_OUT) / 4) * 4
	local cells = math.ceil(R_OUT * 2 / 4) + 2
	local half = math.ceil(cells / 2)
	-- Four quarters, so no single write holds a million voxels in Lua tables.
	for qx = 0, 1 do
		for qz = 0, 1 do
			local cx0, cz0 = qx * half, qz * half
			local nx, nz = math.min(half, cells - cx0), math.min(half, cells - cz0)
			local mats, occ, liq = table.create(nx), table.create(nx), table.create(nx)
			for i = 1, nx do
				local mi, oi, li = table.create(nY), table.create(nY), table.create(nY)
				mats[i], occ[i], liq[i] = mi, oi, li
				for j = 1, nY do
					mi[j], oi[j], li[j] = table.create(nz), table.create(nz), table.create(nz)
				end
				local wx = minX + (cx0 + i - 1) * 4 + 2
				for k = 1, nz do
					local wz = minZ + (cz0 + k - 1) * 4 + 2
					local dx, dz = wx - origin.X, wz - origin.Z
					local l = dx * sideV.X + dz * sideV.Z
					local b = dx * backV.X + dz * backV.Z
					-- The shaft is carved exactly as on every other island.
					local inPit = math.abs(l) <= pitHalf and math.abs(b) <= pitHalf
					local h, mat, r, shore = column(l, b)
					-- Water stops at the beach. Past it, the outer slope would wear a
					-- sheet of sea draped over it.
					local wet = (not inPit) and r < shore + 20
					for j = 1, nY do
						local y0 = Y0 + (j - 1) * 4
						local o = 0
						if not inPit then
							o = math.clamp((h - 2 - y0) / 4, 0, 1)
						end
						local w = 0
						if wet then
							w = math.max(0, math.clamp((seaY - y0) / 4, 0, 1) - o)
						end
						mi[j][k] = (o > 0) and ((y0 + 4 < h - 7) and M.Rock or mat) or M.Air
						oi[j][k] = o
						li[j][k] = w
					end
				end
			end
			terrain:WriteVoxelChannels(
				Region3.new(Vector3.new(minX + cx0 * 4, Y0, minZ + cz0 * 4),
					Vector3.new(minX + (cx0 + nx) * 4, Y1, minZ + (cz0 + nz) * 4)),
				4, { SolidMaterial = mats, SolidOccupancy = occ, LiquidOccupancy = liq })
		end
	end

	-- Sand is shared with Sunscar. Out of the box it is near white under this
	-- sun, which read as snow on a beach and as salt flats in a desert.
	terrain:SetMaterialColor(M.Sand, C3(176, 150, 104))
	terrain:SetMaterialColor(M.Ground, C3(132, 116, 88))
	terrain.WaterColor = C3(30, 116, 126)
	terrain.WaterTransparency = 0.72
	terrain.WaterReflectance = 0.45
	terrain.WaterWaveSize = 0.12
	terrain.WaterWaveSpeed = 7
	Harbor._column = column
	return column
end

--------------------------------------------------------------------------------
-- TIMBER: the cofferdam holding the sea off the shaft, the boardwalk round it,
-- and the wharf where every other island has its square.
--------------------------------------------------------------------------------

local function piling(f, l, b, top, d, barnacles, rng)
	local p = rod(f, "Piling", HP(l, -16, b), HP(l, top, b), d, C3(86, 72, 58), M.Wood)
	rod(f, "Weed", HP(l, SEA - 1.3, b), HP(l, SEA + 0.6, b), d + 0.16, ALGAE, M.Slate, true)
	if barnacles then
		for _ = 1, 3 do
			local a = rng:NextNumber() * math.pi * 2
			ball(f, "Barnacle", HP(l + math.cos(a) * d * 0.5, SEA - 0.6 + rng:NextNumber() * 1.1, b + math.sin(a) * d * 0.5),
				0.34 + rng:NextNumber() * 0.2, C3(214, 210, 196), M.Slate, true)
		end
	end
	return p
end

local function cofferdam(f, hole)
	local outer = hole + 6
	local low = -21 -- down into the lagoon floor
	local wallH = DECK - low
	-- MineServer's shaft walls stop at GROUND - 2.05; the collar starts there, so
	-- from inside the pit the rock simply turns into timber at the top.
	local collarLow = -2.05
	local collarH = DECK - collarLow
	for _, s in ipairs({ 1, -1 }) do
		mk({ Name = "Cofferdam", Parent = f, Size = Vector3.new(outer * 2, wallH, 6),
			CFrame = H(0, low + wallH / 2, s * (hole + 3)), Color = WET, Material = M.WoodPlanks })
		mk({ Name = "Cofferdam", Parent = f, Size = Vector3.new(6, wallH, hole * 2),
			CFrame = H(s * (hole + 3), low + wallH / 2, 0), Color = WET, Material = M.WoodPlanks })
		mk({ Name = "Collar", Parent = f, Size = Vector3.new(hole * 2, collarH, 4),
			CFrame = H(0, collarLow + collarH / 2, s * (hole - 2)), Color = C3(88, 70, 54), Material = M.WoodPlanks })
		mk({ Name = "Collar", Parent = f, Size = Vector3.new(4, collarH, hole * 2 - 8),
			CFrame = H(s * (hole - 2), collarLow + collarH / 2, 0), Color = C3(88, 70, 54), Material = M.WoodPlanks })
		mk({ Name = "CapBeam", Parent = f, Size = Vector3.new((outer + 1) * 2, 0.7, 11),
			CFrame = H(0, DECK + 0.35, s * (hole + 1.5)), Color = C3(102, 82, 62), Material = M.Wood })
		mk({ Name = "CapBeam", Parent = f, Size = Vector3.new(11, 0.7, (hole - 4) * 2),
			CFrame = H(s * (hole + 1.5), DECK + 0.35, 0), Color = C3(102, 82, 62), Material = M.Wood })
		-- Weed at the waterline and a crust of salt where the tide tops out.
		mk({ Name = "Weed", Parent = f, Size = Vector3.new(outer * 2 + 0.3, 2.6, 0.3),
			CFrame = H(0, SEA, s * (outer + 0.15)), Color = ALGAE, Material = M.Slate, deco = true })
		mk({ Name = "Weed", Parent = f, Size = Vector3.new(0.3, 2.6, outer * 2),
			CFrame = H(s * (outer + 0.15), SEA, 0), Color = ALGAE, Material = M.Slate, deco = true })
		mk({ Name = "TideLine", Parent = f, Size = Vector3.new(outer * 2 + 0.2, 0.3, 0.22),
			CFrame = H(0, SEA + 1.55, s * (outer + 0.11)), Color = SALT, Material = M.Slate, deco = true })
		mk({ Name = "TideLine", Parent = f, Size = Vector3.new(0.22, 0.3, outer * 2),
			CFrame = H(s * (outer + 0.11), SEA + 1.55, 0), Color = SALT, Material = M.Slate, deco = true })
	end
	-- Iron bollards on the four corners of the cap.
	for _, c in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
		local l, b = c[1] * (hole + 2), c[2] * (hole + 2)
		rod(f, "Bollard", HP(l, DECK + 0.7, b), HP(l, DECK + 2.2, b), 1.3, IRON, M.Metal)
		ball(f, "BollardCap", HP(l, DECK + 2.25, b), 1.6, IRON, M.Metal, true)
	end
end

local function boardwalk(f, hole, rng)
	local w0, w1 = hole + 6, hole + 18
	local mid, width = (w0 + w1) / 2, w1 - w0
	local function strip(alongL, fixed, from, to, n)
		local len = (to - from) / n
		for i = 0, n - 1 do
			local c = from + len * (i + 0.5)
			local tone = C3(118, 92, 66):Lerp((rng:NextNumber() < 0.25) and C3(152, 124, 92) or C3(80, 66, 52),
				0.2 + rng:NextNumber() * 0.25)
			mk({ Name = "Boardwalk", Parent = f,
				Size = alongL and Vector3.new(len - 0.08, 0.8, width) or Vector3.new(width, 0.8, len - 0.08),
				CFrame = alongL and H(c, DECK - 0.4, fixed) or H(fixed, DECK - 0.4, c),
				Color = tone, Material = M.WoodPlanks })
		end
	end
	strip(true, -mid, -w1, w1, 12)
	strip(false, -mid, -w0, hole + 7, 10)
	strip(false, mid, -w0, hole + 7, 10)

	-- Pilings round the outside edge, every one a rail post, roped together.
	local edge = w1 - 0.7
	-- Evenly spaced down one side, across the far end and back up the other,
	-- corners included, so the rope never cuts a corner.
	local ring = {}
	local function run(a, b, n, skipFirst)
		for i = skipFirst and 1 or 0, n do
			table.insert(ring, a:Lerp(b, i / n))
		end
	end
	run(Vector2.new(edge, hole + 5), Vector2.new(edge, -edge), 10, false)
	run(Vector2.new(edge, -edge), Vector2.new(-edge, -edge), 11, true)
	run(Vector2.new(-edge, -edge), Vector2.new(-edge, hole + 5), 10, true)
	local last
	for i, pt in ipairs(ring) do
		local p = piling(f, pt.X, pt.Y, DECK + 3, 1.4, i % 3 == 0, rng)
		rod(f, "Lashing", HP(pt.X, DECK + 1.9, pt.Y), HP(pt.X, DECK + 2.3, pt.Y), 1.58, ROPE, M.Fabric, true)
		local top = HP(pt.X, DECK + 2.5, pt.Y)
		if last then
			rope(last.part, last.top, p, top, 0.55, 0.2)
		end
		last = { part = p, top = top }
	end
end

local function wharf(f, hole, rng)
	local near, far, halfW = hole + 7, hole + 106, 71
	local n = 30
	local depth = (far - near) / n
	mk({ Name = "SubDeck", Parent = f, Size = Vector3.new(halfW * 2 - 1, 0.4, far - near),
		CFrame = H(0, DECK - 1, (near + far) / 2), Color = C3(40, 34, 30), Material = M.Wood })
	for i = 0, n - 1 do
		local r = rng:NextNumber()
		local tone = C3(122, 96, 68)
		if r < 0.12 then
			tone = C3(154, 126, 92) -- replaced this year
		elseif r < 0.2 then
			tone = C3(80, 66, 52) -- tarred
		end
		tone = tone:Lerp(C3(96, 78, 58), rng:NextNumber() * 0.25)
		local jitter = (i % 2 == 0) and 0.7 or -0.5
		mk({ Name = "Board", Parent = f, Size = Vector3.new(halfW * 2 + math.abs(jitter), 0.8, depth - 0.07),
			CFrame = H(jitter * 0.5, DECK - 0.4, near + depth * (i + 0.5)), Color = tone, Material = M.WoodPlanks })
	end
	for _, s in ipairs({ -1, 1 }) do
		mk({ Name = "Fascia", Parent = f, Size = Vector3.new(0.7, 1.7, far - near),
			CFrame = H(s * (halfW + 0.45), DECK - 0.75, (near + far) / 2), Color = WET, Material = M.Wood })
		local i = 0
		for b = near + 3, far - 2, 11 do
			i += 1
			local tall = (i % 2 == 1)
			piling(f, s * (halfW + 0.2), b, tall and (DECK + 1.8) or (DECK - 0.9), 1.5, i % 3 == 0, rng)
			if tall then
				rod(f, "Lashing", HP(s * (halfW + 0.2), DECK + 0.9, b), HP(s * (halfW + 0.2), DECK + 1.3, b), 1.68, ROPE, M.Fabric, true)
			end
		end
		for k = 0, 3 do
			local b0 = near + 3 + k * 22
			beam(f, "Brace", HP(s * (halfW + 0.2), SEA + 1.6, b0), HP(s * (halfW + 0.2), SEA - 4.5, b0 + 11), 0.5, 0.8, WET, M.Wood, true)
		end
	end
	-- Old tyres for fenders.
	for _, t in ipairs({ { -1, 86 }, { -1, 101 }, { -1, 116 }, { 1, 94 }, { 1, 112 } }) do
		local l, b = t[1] * (halfW + 1.3), t[2]
		rod(f, "Fender", HP(l - 0.45, DECK - 1.5, b), HP(l + 0.45, DECK - 1.5, b), 2.9, C3(30, 30, 32), M.SmoothPlastic, true)
		rod(f, "FenderHole", HP(l - 0.47, DECK - 1.5, b), HP(l + 0.47, DECK - 1.5, b), 1.2, C3(12, 12, 14), M.SmoothPlastic, true)
		rod(f, "FenderRope", HP(l, DECK - 0.1, b), HP(t[1] * (halfW - 0.3), DECK + 0.05, b), 0.18, ROPE, M.Fabric, true)
	end
	-- Ladders out of the water, because people will fall in.
	for _, lad in ipairs({ { -1, 131 }, { 1, 141 } }) do
		local tr = Instance.new("TrussPart")
		tr.Name = "Ladder"
		tr.Anchored = true
		tr.Size = Vector3.new(2, 8, 2)
		tr.Style = Enum.Style.NoSupports
		tr.Material = M.Wood
		tr.Color = TIMBER
		tr.CFrame = H(lad[1] * (halfW + 1.6), DECK - 4.2, lad[2])
		tr.Parent = f
	end
	-- Two steps down to the sand, the full width of the wharf.
	for k, drop in ipairs({ 0.7, 1.4 }) do
		mk({ Name = "BeachStep", Parent = f, Size = Vector3.new(halfW * 2, 0.7, 2.6),
			CFrame = H(0, DECK - drop - 0.35, far + 1.3 + (k - 1) * 2.6), Color = C3(108, 86, 62), Material = M.WoodPlanks })
	end
	-- Cart rails from the cofferdam to the depot end, and a cart on them.
	local railL, railFar = -14, far - 8
	for _, g in ipairs({ -1.25, 1.25 }) do
		mk({ Name = "Rail", Parent = f, Size = Vector3.new(0.3, 0.35, railFar - near),
			CFrame = H(railL + g, DECK + 0.455, (near + railFar) / 2), Color = C3(92, 90, 94), Material = M.Metal,
			Reflectance = 0.15, deco = true })
	end
	for b = near + 1.5, railFar - 1, 4.5 do
		mk({ Name = "Sleeper", Parent = f, Size = Vector3.new(4, 0.28, 0.9), CFrame = H(railL, DECK + 0.14, b),
			Color = C3(70, 56, 44), Material = M.Wood, deco = true })
	end
	mk({ Name = "BufferStop", Parent = f, Size = Vector3.new(4.4, 1.3, 1.2), CFrame = H(railL, DECK + 0.65, railFar + 0.6),
		Color = C3(96, 76, 56), Material = M.Wood })
	mk({ Name = "BufferPaint", Parent = f, Size = Vector3.new(4.5, 0.35, 1.25), CFrame = H(railL, DECK + 0.95, railFar + 0.6),
		Color = C3(196, 60, 48), Material = M.SmoothPlastic, deco = true })
	local cb = far - 30
	local tub = mk({ Name = "OreCart", Parent = f, Size = Vector3.new(3.4, 2.1, 4.6), CFrame = H(railL, DECK + 1.9, cb),
		Color = C3(98, 76, 62), Material = M.CorrodedMetal })
	for _, w in ipairs({ { -1, -1.5 }, { 1, -1.5 }, { -1, 1.5 }, { 1, 1.5 } }) do
		rod(f, "CartWheel", HP(railL + w[1] * 1.25, DECK + 1.15, cb + w[2]), HP(railL + w[1] * 1.7, DECK + 1.15, cb + w[2]),
			1.1, IRON, M.Metal, true)
	end
	local ORE = { C3(120, 214, 232), C3(212, 238, 246), C3(64, 150, 176), C3(226, 196, 104), C3(92, 96, 104) }
	for k = 1, 6 do
		mk({ Name = "Ore", Parent = f, Size = Vector3.new(1.1 + rng:NextNumber() * 0.6, 0.9 + rng:NextNumber() * 0.5, 1.2),
			CFrame = H(railL - 0.8 + ((k - 1) % 3) * 0.8, DECK + 3.1 + rng:NextNumber() * 0.3, cb - 1.4 + ((k - 1) // 3) * 1.6 + rng:NextNumber() * 0.4)
				* CFrame.Angles(rng:NextNumber(), rng:NextNumber() * 3, rng:NextNumber()),
			Color = ORE[(k - 1) % #ORE + 1], Material = (k % 2 == 0) and M.Ice or M.Slate, deco = true })
	end
	return tub
end

--------------------------------------------------------------------------------
-- SMALL THINGS: the pieces that get reused -- lanterns, lifebuoys, gulls, fish,
-- starfish, chalk writing, cleats to tie a rope to.
--------------------------------------------------------------------------------

local AMB = Random.new(1) -- phases only; reseeded per build so it is stable

local function writeOn(p, text, opts)
	opts = opts or {}
	local gui = Instance.new("SurfaceGui")
	gui.Face = opts.face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = opts.pps or 36
	gui.LightInfluence = 1
	gui.MaxDistance = opts.maxDistance or 140
	gui.Parent = p
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.5, 0.5)
	t.Size = UDim2.fromScale(opts.w or 0.88, opts.h or 0.84)
	t.Font = opts.font or Enum.Font.PatrickHand
	t.TextColor3 = opts.color or C3(238, 236, 226)
	t.TextScaled = true
	t.TextWrapped = true
	t.TextXAlignment = opts.align or Enum.TextXAlignment.Center
	t.Text = text
	t.Parent = gui
	return gui
end

local function cleat(parent, pos)
	return rod(parent, "Cleat", pos - Vector3.new(0, 0.15, 0), pos + Vector3.new(0, 0.35, 0), 0.5, IRON, M.Metal, true)
end

-- A ship's lantern hanging from `hook`. It swings a little on the client.
local function lantern(parent, hook, range, bright)
	local m = model(parent, "Lantern")
	local d = Vector3.new(0, 1, 0)
	rod(m, "Bail", hook, hook - d * 0.65, 0.08, IRON, M.Metal, true)
	rod(m, "LanternCap", hook - d * 0.65, hook - d * 1.0, 0.95, IRON, M.Metal, true)
	local glass = rod(m, "LanternGlass", hook - d * 1.0, hook - d * 2.3, 0.8, C3(255, 236, 196), M.Glass, true)
	glass.Transparency = 0.4
	local flame = ball(m, "LanternFlame", hook - d * 1.65, 0.42, LAMP, M.Neon, true)
	rod(m, "LanternBase", hook - d * 2.3, hook - d * 2.55, 0.95, IRON, M.Metal, true)
	local pl = Instance.new("PointLight")
	pl.Color = LAMP
	pl.Range = range or 20
	pl.Brightness = bright or 1.3
	pl.Parent = flame
	m.WorldPivot = CFrame.new(hook)
	tag(m, "AmbSway", { SwayAmp = 3.5, SwaySpeed = 1.1 + AMB:NextNumber() * 0.5, Phase = AMB:NextNumber() * 6.28 })
	return m
end

-- Four red and four white bands, the way every lifebuoy is painted. The ring
-- lies in `cf`'s XY plane.
local function lifebuoy(parent, cf, r)
	r = r or 1.4
	local n = 12
	local chord = 2 * r * math.sin(math.pi / n) * 1.14
	for i = 0, n - 1 do
		mk({ Name = "Lifebuoy", Parent = parent, Size = Vector3.new(0.52, chord, 0.52),
			CFrame = cf * CFrame.Angles(0, 0, (i / n) * math.pi * 2) * CFrame.new(r, 0, 0),
			Color = ((i // 3) % 2 == 0) and C3(222, 70, 52) or WHITE, deco = true })
	end
end

local GULL_GREY = C3(162, 170, 180)
local function gull(parent, cf, flying)
	local m = model(parent, flying and "GullFlying" or "Gull")
	local body = blob(m, "Body", cf * CFrame.new(0, 0.55, 0), Vector3.new(0.8, 0.72, 1.8), WHITE, M.SmoothPlastic, true)
	ball(m, "Head", (cf * CFrame.new(0, 1.02, -0.9)).Position, 0.6, WHITE, M.SmoothPlastic, true)
	wedge(m, "Beak", cf * CFrame.new(0, 0.98, -1.38), Vector3.new(0.13, 0.15, 0.42), C3(236, 186, 58), M.SmoothPlastic, true)
	for _, s in ipairs({ -1, 1 }) do
		ball(m, "Eye", (cf * CFrame.new(s * 0.22, 1.1, -1.1)).Position, 0.11, C3(20, 20, 24), M.SmoothPlastic, true)
		if flying then
			mk({ Name = "Wing", Parent = m, Size = Vector3.new(2.3, 0.07, 0.8),
				CFrame = cf * CFrame.new(s * 1.45, 0.72, 0.05) * CFrame.Angles(0, 0, s * math.rad(14)), Color = GULL_GREY, deco = true })
			mk({ Name = "WingTip", Parent = m, Size = Vector3.new(0.9, 0.08, 0.62),
				CFrame = cf * CFrame.new(s * 3.0, 1.08, 0.12) * CFrame.Angles(0, 0, s * math.rad(-6)), Color = C3(34, 34, 38), deco = true })
		else
			mk({ Name = "Wing", Parent = m, Size = Vector3.new(0.08, 0.5, 1.45),
				CFrame = cf * CFrame.new(s * 0.41, 0.66, 0.2), Color = GULL_GREY, deco = true })
			rod(m, "Leg", (cf * CFrame.new(s * 0.18, 0.3, 0)).Position, (cf * CFrame.new(s * 0.18, 0, 0)).Position, 0.09, C3(226, 150, 62), M.SmoothPlastic, true)
		end
	end
	wedge(m, "Tail", cf * CFrame.new(0, 0.62, 1.1), Vector3.new(0.5, 0.12, 0.62), C3(44, 44, 48), M.SmoothPlastic, true)
	m.PrimaryPart = body
	return m
end

local function fish(parent, cf, color, len)
	len = len or 2.2
	local k = len / 2.2
	blob(parent, "Fish", cf, Vector3.new(0.42 * k, 0.62 * k, len), color, M.SmoothPlastic, true)
	wedge(parent, "FishTail", cf * CFrame.new(0, 0, len * 0.5 + 0.2 * k), Vector3.new(0.07, 0.75 * k, 0.55 * k),
		color:Lerp(C3(60, 64, 76), 0.3), M.SmoothPlastic, true)
	ball(parent, "FishEye", (cf * CFrame.new(0.19 * k, 0.1 * k, -len * 0.36)).Position, 0.12 * k, C3(20, 20, 24), M.SmoothPlastic, true)
end

-- Five tapering arms in `cf`'s XY plane, facing along its Z.
local function starfish(parent, cf, r, color)
	for i = 0, 4 do
		local a = (i / 5) * math.pi * 2
		local u = Vector3.new(math.cos(a), math.sin(a), 0)
		wedge(parent, "Starfish", cf * CFrame.fromMatrix(u * (r * 0.5), Vector3.zAxis, Vector3.new(-math.sin(a), math.cos(a), 0)),
			Vector3.new(0.16, r * 0.5, r), color, M.SmoothPlastic, true)
	end
	blob(parent, "Starfish", cf, Vector3.new(r * 0.55, r * 0.55, 0.24), color, M.SmoothPlastic, true)
end

-- A pitched roof: two panes, a ridge, and the triangles at each end stepped in.
local function gableRoof(f, cf, W, D, Hh, pitch, color, material, endColor, endMat)
	local half = W / 2 + 2.5
	local rad = math.rad(pitch)
	local rise = half * math.tan(rad)
	local len = half / math.cos(rad) + 0.4
	for _, s in ipairs({ -1, 1 }) do
		mk({ Name = "RoofPane", Parent = f, Size = Vector3.new(len, 0.55, D + 6),
			CFrame = cf * CFrame.new(s * half / 2, Hh + rise / 2, 0) * CFrame.Angles(0, 0, -s * rad),
			Color = color, Material = material })
	end
	mk({ Name = "Ridge", Parent = f, Size = Vector3.new(1.1, 0.7, D + 6.6), CFrame = cf * CFrame.new(0, Hh + rise + 0.2, 0),
		Color = C3(92, 74, 56), Material = M.Wood })
	for _, z in ipairs({ -1, 1 }) do
		for i = 0, 5 do
			local u = (i + 0.5) / 6
			mk({ Name = "GableEnd", Parent = f, Size = Vector3.new(W * (1 - u) + 0.6, rise / 6 + 0.12, 1),
				CFrame = cf * CFrame.new(0, Hh + rise * u, z * (D / 2)), Color = endColor, Material = endMat })
		end
	end
	return rise
end

--------------------------------------------------------------------------------
-- THE TWO SHOPS: a fish market that buys your haul, and a red chandlery that
-- sells the tools. Registered as MineShopFronts styles, so ShopFronts.build
-- still adds the NPC and the pad and names everything the way gotoStation
-- expects.
--------------------------------------------------------------------------------

local function buildFishMarket(kit, f, cf, pal, W, D, Hh, title)
	mk({ Name = "Floor", Parent = f, Size = Vector3.new(W + 6, 1.2, D + 6), CFrame = cf * CFrame.new(0, 0.6, 0),
		Color = C3(112, 90, 66), Material = M.WoodPlanks })
	mk({ Name = "FloorTrim", Parent = f, Size = Vector3.new(W + 6.8, 0.6, D + 6.8), CFrame = cf * CFrame.new(0, 0.3, 0),
		Color = WET, Material = M.Wood })
	local paint = C3(80, 122, 138)
	mk({ Name = "Back", Parent = f, Size = Vector3.new(W, Hh, 1.2), CFrame = cf * CFrame.new(0, Hh / 2, D / 2),
		Color = paint, Material = M.WoodPlanks })
	for _, s in ipairs({ -1, 1 }) do
		mk({ Name = "SideRail", Parent = f, Size = Vector3.new(1, 3.4, D), CFrame = cf * CFrame.new(s * W / 2, 2.9, 0),
			Color = paint, Material = M.WoodPlanks })
		for _, z in ipairs({ -D / 2, D / 2 - 0.6 }) do
			mk({ Name = "Post", Parent = f, Size = Vector3.new(1.3, Hh, 1.3), CFrame = cf * CFrame.new(s * W / 2, Hh / 2, z),
				Color = TIMBER, Material = M.Wood })
		end
		rod(f, "Lashing", (cf * CFrame.new(s * W / 2, 7.4, -D / 2)).Position, (cf * CFrame.new(s * W / 2, 8, -D / 2)).Position,
			1.55, ROPE, M.Fabric, true)
	end
	mk({ Name = "Lintel", Parent = f, Size = Vector3.new(W + 1.3, 1.2, 1.3), CFrame = cf * CFrame.new(0, Hh - 0.6, -D / 2),
		Color = TIMBER, Material = M.Wood })
	local rise = gableRoof(f, cf, W, D, Hh, 22, C3(86, 140, 128), M.CorrodedMetal, paint, M.WoodPlanks)

	-- The fish counter: painted boards, a bed of ice, the day's catch -- and, it
	-- being a mine, some of the day's ore on the ice beside it.
	local counterZ = -D / 2 + 3
	mk({ Name = "Counter", Parent = f, Size = Vector3.new(W - 8, 4.4, 3.2), CFrame = cf * CFrame.new(0, 2.2, counterZ),
		Color = C3(214, 210, 198), Material = M.WoodPlanks })
	mk({ Name = "IceBed", Parent = f, Size = Vector3.new(W - 7, 0.4, 3.8), CFrame = cf * CFrame.new(0, 4.6, counterZ),
		Color = C3(208, 232, 240), Material = M.Ice })
	for i, fx in ipairs({ -3.1, -1.1, 1.2, 3.3 }) do
		local col = ({ C3(176, 190, 202), C3(226, 150, 128), C3(176, 190, 202), C3(214, 176, 94) })[i]
		fish(f, cf * CFrame.new(fx, 5.02, counterZ + (i % 2 == 0 and 0.2 or -0.2)) * CFrame.Angles(0, math.rad(i * 7 - 14), math.rad(90)), col, 2.1)
	end
	for _, fx in ipairs({ -5.4, 5.4 }) do
		mk({ Name = "OreOnIce", Parent = f, Size = Vector3.new(0.9, 1.3, 0.9), CFrame = cf * CFrame.new(fx, 5.35, counterZ)
			* CFrame.Angles(math.rad(12), math.rad(fx * 9), math.rad(-10)), Color = C3(120, 214, 232), Material = M.Glass, deco = true })
	end
	-- A spring scale hanging from the lintel.
	local sx = W * 0.3
	rod(f, "ScaleChain", (cf * CFrame.new(sx, Hh - 1.2, -D / 2)).Position, (cf * CFrame.new(sx, Hh - 3.3, -D / 2)).Position, 0.1, IRON, M.Metal, true)
	rod(f, "ScaleDial", (cf * CFrame.new(sx, Hh - 4.0, -D / 2 - 0.2)).Position, (cf * CFrame.new(sx, Hh - 4.0, -D / 2 + 0.2)).Position,
		1.5, C3(236, 232, 220), M.SmoothPlastic, true)
	rod(f, "ScaleRim", (cf * CFrame.new(sx, Hh - 4.0, -D / 2 - 0.05)).Position, (cf * CFrame.new(sx, Hh - 4.0, -D / 2 + 0.25)).Position,
		1.7, BRASS, M.Metal, true)
	rod(f, "ScaleHook", (cf * CFrame.new(sx, Hh - 4.8, -D / 2)).Position, (cf * CFrame.new(sx, Hh - 5.6, -D / 2)).Position, 0.1, IRON, M.Metal, true)
	rod(f, "ScalePan", (cf * CFrame.new(sx, Hh - 5.6, -D / 2)).Position, (cf * CFrame.new(sx, Hh - 5.75, -D / 2)).Position, 2, BRASS, M.Metal, true)
	fish(f, cf * CFrame.new(sx, Hh - 5.25, -D / 2) * CFrame.Angles(0, math.rad(90), math.rad(90)), C3(176, 190, 202), 1.6)
	lantern(f, (cf * CFrame.new(-W * 0.18, Hh - 1.2, -D / 2)).Position, 22, 1.2)

	-- Name board on the front gable.
	local board = mk({ Name = "Sign", Parent = f, Size = Vector3.new(W - 6, 2.3, 0.3), CFrame = cf * CFrame.new(0, Hh + 1.6, -D / 2 - 0.66),
		Color = C3(28, 44, 58), Material = M.Wood })
	K.sign(board, string.upper(title or "Fish Market"), Enum.NormalId.Front)

	-- Chalkboard out front.
	local cb = cf * CFrame.new(W / 2 + 3.2, 0, -D / 2 - 4.2)
	for _, s in ipairs({ -1, 1 }) do
		beam(f, "ChalkLeg", (cb * CFrame.new(s * 1.2, 0, -0.5)).Position, (cb * CFrame.new(s * 1.2, 4.3, 0.3)).Position, 0.22, 0.22, TIMBER, M.Wood, true)
	end
	local chalk = mk({ Name = "Chalkboard", Parent = f, Size = Vector3.new(2.7, 3.3, 0.18),
		CFrame = cb * CFrame.new(0, 2.5, -0.02) * CFrame.Angles(math.rad(9), 0, 0), Color = C3(34, 42, 40), Material = M.Slate, deco = true })
	writeOn(chalk, "TODAY'S CATCH\nOre .......... fresh\nGems ....... fresher\nCards ...... ask Marlow\nKelp ......... free, please",
		{ align = Enum.TextXAlignment.Left, pps = 60, w = 0.9, h = 0.9 })

	-- Crates of ice and fish at the side, a net over the rail, a lifebuoy.
	for i, o in ipairs({ { -W / 2 - 2.6, 0.95, -D / 2 + 2.2 }, { -W / 2 - 2.5, 2.85, -D / 2 + 2.4 }, { -W / 2 - 2.8, 0.95, -D / 2 + 5.8 } }) do
		mk({ Name = "FishCrate", Parent = f, Size = Vector3.new(2.8, 1.9, 3.2), CFrame = cf * CFrame.new(o[1], o[2], o[3]) * CFrame.Angles(0, math.rad(i * 8), 0),
			Color = C3(128, 98, 66), Material = M.WoodPlanks })
	end
	mk({ Name = "CrateIce", Parent = f, Size = Vector3.new(2.5, 0.3, 2.9), CFrame = cf * CFrame.new(-W / 2 - 2.5, 3.9, -D / 2 + 2.4) * CFrame.Angles(0, math.rad(16), 0),
		Color = C3(214, 236, 244), Material = M.Ice, deco = true })
	wedge(f, "FishTail", cf * CFrame.new(-W / 2 - 2.2, 4.3, -D / 2 + 2.1) * CFrame.Angles(math.rad(-30), 0, 0), Vector3.new(0.07, 0.8, 0.6),
		C3(150, 162, 176), M.SmoothPlastic, true)
	local net = mk({ Name = "Net", Parent = f, Size = Vector3.new(0.12, 3.4, D - 2), CFrame = cf * CFrame.new(-W / 2 - 0.4, 3.2, 0) * CFrame.Angles(0, 0, math.rad(-9)),
		Color = C3(58, 74, 60), Material = M.Fabric, deco = true })
	net.Transparency = 0.3
	lifebuoy(f, cf * CFrame.new(W / 2 + 0.72, 6.4, -D / 2) * CFrame.Angles(0, math.rad(90), 0), 1.2)
	gull(f, cf * CFrame.new(W * 0.22, Hh + rise + 0.55, 1.2) * CFrame.Angles(0, math.rad(130), 0), false)
end

local function buildChandlery(kit, f, cf, pal, W, D, Hh, title)
	local red = C3(152, 50, 40)
	mk({ Name = "Floor", Parent = f, Size = Vector3.new(W + 6, 1.2, D + 6), CFrame = cf * CFrame.new(0, 0.6, 0),
		Color = C3(112, 90, 66), Material = M.WoodPlanks })
	mk({ Name = "FloorTrim", Parent = f, Size = Vector3.new(W + 6.8, 0.6, D + 6.8), CFrame = cf * CFrame.new(0, 0.3, 0),
		Color = WET, Material = M.Wood })
	mk({ Name = "Back", Parent = f, Size = Vector3.new(W, Hh, 1.2), CFrame = cf * CFrame.new(0, Hh / 2, D / 2), Color = red, Material = M.WoodPlanks })
	for _, s in ipairs({ -1, 1 }) do
		mk({ Name = "Side", Parent = f, Size = Vector3.new(1.2, Hh, D), CFrame = cf * CFrame.new(s * W / 2, Hh / 2, 0), Color = red, Material = M.WoodPlanks })
		mk({ Name = "FrontPier", Parent = f, Size = Vector3.new(3.2, Hh, 1.2), CFrame = cf * CFrame.new(s * (W / 2 - 1.6), Hh / 2, -D / 2),
			Color = red, Material = M.WoodPlanks })
		for _, z in ipairs({ -1, 1 }) do
			mk({ Name = "CornerBoard", Parent = f, Size = Vector3.new(0.55, Hh + 0.2, 0.55), CFrame = cf * CFrame.new(s * (W / 2 + 0.36), Hh / 2, z * (D / 2 + 0.36)),
				Color = WHITE, Material = M.Wood })
		end
		-- A four-pane window in each side wall.
		local wc = cf * CFrame.new(s * (W / 2 + 0.62), 6.6, 0)
		mk({ Name = "Window", Parent = f, Size = Vector3.new(0.14, 2.6, 3), CFrame = wc, Color = C3(36, 50, 60), Material = M.Glass, Reflectance = 0.25, deco = true })
		for _, y in ipairs({ -1.45, 1.45 }) do
			mk({ Name = "WindowFrame", Parent = f, Size = Vector3.new(0.3, 0.35, 3.7), CFrame = wc * CFrame.new(0, y, 0), Color = WHITE, Material = M.Wood, deco = true })
		end
		for _, z in ipairs({ -1.68, 1.68 }) do
			mk({ Name = "WindowFrame", Parent = f, Size = Vector3.new(0.3, 3.25, 0.35), CFrame = wc * CFrame.new(0, 0, z), Color = WHITE, Material = M.Wood, deco = true })
		end
		mk({ Name = "Mullion", Parent = f, Size = Vector3.new(0.26, 2.6, 0.2), CFrame = wc, Color = WHITE, Material = M.Wood, deco = true })
		mk({ Name = "Mullion", Parent = f, Size = Vector3.new(0.26, 0.2, 3), CFrame = wc, Color = WHITE, Material = M.Wood, deco = true })
		mk({ Name = "WindowBox", Parent = f, Size = Vector3.new(0.9, 0.7, 3.4), CFrame = wc * CFrame.new(s * 0.45, -1.95, 0), Color = C3(96, 70, 48), Material = M.Wood, deco = true })
		for k = -1, 1 do
			ball(f, "Flower", (wc * CFrame.new(s * 0.5, -1.35, k * 1.05)).Position, 0.55, ({ C3(236, 212, 92), C3(236, 120, 150), WHITE })[k + 2], M.SmoothPlastic, true)
		end
	end
	mk({ Name = "Lintel", Parent = f, Size = Vector3.new(W - 6.4, 2.6, 1.2), CFrame = cf * CFrame.new(0, Hh - 1.3, -D / 2), Color = red, Material = M.WoodPlanks })
	local rise = gableRoof(f, cf, W, D, Hh, 34, C3(50, 52, 58), M.Slate, red, M.WoodPlanks)
	-- White bargeboards up the front gable.
	for _, s in ipairs({ -1, 1 }) do
		local half = W / 2 + 2.5
		beam(f, "Bargeboard", (cf * CFrame.new(s * half, Hh - 0.1, -D / 2 - 3.1)).Position, (cf * CFrame.new(0, Hh + rise + 0.2, -D / 2 - 3.1)).Position,
			0.35, 0.8, WHITE, M.Wood, true)
	end
	-- Chimney with a thread of smoke.
	local chim = mk({ Name = "Chimney", Parent = f, Size = Vector3.new(2, 6, 2), CFrame = cf * CFrame.new(W * 0.24, Hh + rise * 0.55 + 1.6, D * 0.2),
		Color = C3(122, 72, 58), Material = M.Brick })
	mk({ Name = "ChimneyCap", Parent = f, Size = Vector3.new(2.6, 0.4, 2.6), CFrame = chim.CFrame * CFrame.new(0, 3.2, 0), Color = C3(60, 58, 58), Material = M.Slate, deco = true })
	local puff = Instance.new("ParticleEmitter")
	puff.Texture = SMOKE
	puff.Rate = 1.4
	puff.Lifetime = NumberRange.new(5, 7)
	puff.Speed = NumberRange.new(2, 3)
	puff.SpreadAngle = Vector2.new(8, 8)
	puff.Acceleration = Vector3.new(0.5, 0.7, 0.3)
	puff.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 6) })
	puff.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	puff.Color = ColorSequence.new(C3(150, 150, 150))
	puff.RotSpeed = NumberRange.new(-20, 20)
	puff.Rotation = NumberRange.new(0, 360)
	puff.Parent = chim

	local counterZ = -D / 2 + 3
	mk({ Name = "Counter", Parent = f, Size = Vector3.new(W - 8, 4.4, 3.2), CFrame = cf * CFrame.new(0, 2.2, counterZ), Color = TIMBER, Material = M.WoodPlanks })
	mk({ Name = "CounterTop", Parent = f, Size = Vector3.new(W - 6.4, 0.5, 4), CFrame = cf * CFrame.new(0, 4.65, counterZ), Color = C3(170, 136, 96), Material = M.Wood })
	-- A brass ship's bell on the counter and a coil of rope.
	blob(f, "CounterBell", cf * CFrame.new(-3.4, 5.4, counterZ), Vector3.new(0.9, 1, 0.9), BRASS, M.Metal, true)
	rod(f, "RopeCoil", (cf * CFrame.new(3.2, 4.9, counterZ)).Position, (cf * CFrame.new(3.2, 5.4, counterZ)).Position, 2, ROPE, M.Fabric, true)
	rod(f, "RopeCoilCore", (cf * CFrame.new(3.2, 4.92, counterZ)).Position, (cf * CFrame.new(3.2, 5.45, counterZ)).Position, 0.8, C3(70, 54, 40), M.Fabric, true)

	-- Tools on the back wall: crossed pickaxes, oars, rope on pegs.
	local wall = cf * CFrame.new(0, 0, D / 2 - 0.75)
	for _, s in ipairs({ -1, 1 }) do
		local h0 = wall * CFrame.new(-4 - s * 1.6, 5, 0)
		local h1 = wall * CFrame.new(-4 + s * 1.6, 9.4, 0)
		beam(f, "PickHandle", h0.Position, h1.Position, 0.3, 0.3, C3(150, 112, 70), M.Wood, true)
		mk({ Name = "PickHead", Parent = f, Size = Vector3.new(3.2, 0.42, 0.3), CFrame = CFrame.lookAt(h1.Position, h1.Position + (h1.Position - h0.Position))
			* CFrame.Angles(0, 0, 0), Color = IRON, Material = M.Metal, deco = true })
	end
	for k = 0, 2 do
		rod(f, "RopeHank", (wall * CFrame.new(2.2 + k * 1.9, 8.4, -0.1)).Position, (wall * CFrame.new(2.2 + k * 1.9, 8.4, -0.6)).Position, 1.5, ROPE, M.Fabric, true)
	end
	lantern(f, (cf * CFrame.new(0, Hh - 0.8, 0)).Position, 20, 1.1)

	-- A name board over the door.
	local board = mk({ Name = "Sign", Parent = f, Size = Vector3.new(W - 7.2, 2.1, 0.3), CFrame = cf * CFrame.new(0, Hh - 1.3, -D / 2 - 0.76),
		Color = C3(32, 56, 48), Material = M.Wood })
	K.sign(board, string.upper(title or "Chandlery"), Enum.NormalId.Front)

	-- An anchor leant by the door, lobster pots, a bench with a coil on it.
	local an = cf * CFrame.new(W / 2 + 2.8, 0, -D / 2 - 1.4) * CFrame.Angles(math.rad(-10), math.rad(20), 0)
	rod(f, "AnchorShank", (an * CFrame.new(0, 0.7, 0)).Position, (an * CFrame.new(0, 5.4, 0)).Position, 0.5, IRON, M.Metal, true)
	rod(f, "AnchorStock", (an * CFrame.new(0, 4.7, -2)).Position, (an * CFrame.new(0, 4.7, 2)).Position, 0.4, IRON, M.Metal, true)
	rod(f, "AnchorRing", (an * CFrame.new(-0.1, 5.8, 0)).Position, (an * CFrame.new(0.1, 5.8, 0)).Position, 1, IRON, M.Metal, true)
	for _, s in ipairs({ -1, 1 }) do
		beam(f, "AnchorArm", (an * CFrame.new(0, 0.8, 0)).Position, (an * CFrame.new(s * 1.8, 2.3, 0)).Position, 0.45, 0.45, IRON, M.Metal, true)
		wedge(f, "AnchorFluke", an * CFrame.new(s * 1.95, 2.5, 0) * CFrame.Angles(0, 0, s * math.rad(40)) * CFrame.Angles(math.rad(-90), 0, 0),
			Vector3.new(0.25, 1.1, 1.2), IRON, M.Metal, true)
	end
	for i, o in ipairs({ { -W / 2 - 2.6, 0.95 }, { -W / 2 - 2.5, 2.75 } }) do
		local pot = mk({ Name = "LobsterPot", Parent = f, Size = Vector3.new(2.6, 1.7, 3.4), CFrame = cf * CFrame.new(o[1], o[2], -D / 2 + 3 + i * 0.3)
			* CFrame.Angles(0, math.rad(i * 9), 0), Color = C3(52, 62, 56), Material = M.Fabric })
		mk({ Name = "PotBase", Parent = f, Size = Vector3.new(2.7, 0.3, 3.5), CFrame = pot.CFrame * CFrame.new(0, -0.8, 0), Color = TIMBER, Material = M.Wood, deco = true })
	end
	mk({ Name = "Bench", Parent = f, Size = Vector3.new(4, 0.35, 1.3), CFrame = cf * CFrame.new(-W / 2 + 1.5, 2.2, -D / 2 - 2.4), Color = C3(124, 96, 68), Material = M.Wood })
	for _, s in ipairs({ -1, 1 }) do
		mk({ Name = "BenchLeg", Parent = f, Size = Vector3.new(0.35, 1.8, 1.1), CFrame = cf * CFrame.new(-W / 2 + 1.5 + s * 1.6, 1.1, -D / 2 - 2.4), Color = C3(96, 74, 54), Material = M.Wood, deco = true })
	end
	gull(f, cf * CFrame.new(-W / 2 + 1.1, 2.37, -D / 2 - 2.4) * CFrame.Angles(0, math.rad(-60), 0), false)
end

local STYLES = { fishmarket = buildFishMarket, chandlery = buildChandlery }

-- Hats and a pipe. The NPC is WorldBuilder's; this only adds to its model.
local function dressNpc(shop, kind)
	local m
	for _, c in ipairs(shop:GetChildren()) do
		if c:IsA("Model") and c.Name:match("^NPC_") then
			m = c
			break
		end
	end
	local head = m and m:FindFirstChild("Head")
	if not head then
		return
	end
	local hc = head.CFrame
	if kind == "souwester" then
		local yellow = C3(236, 196, 56)
		rod(m, "HatBrim", (hc * CFrame.new(0, 0.92, 0.25)).Position, (hc * CFrame.new(0, 1.04, 0.25)).Position, 3.2, yellow, M.SmoothPlastic, true)
		blob(m, "HatCrown", hc * CFrame.new(0, 1.3, 0.1), Vector3.new(2.1, 1.2, 2.2), yellow, M.SmoothPlastic, true)
		blob(m, "Beard", hc * CFrame.new(0, -0.62, -0.78), Vector3.new(1.75, 1.15, 0.75), C3(222, 218, 208), M.SmoothPlastic, true)
	else
		blob(m, "Beanie", hc * CFrame.new(0, 0.92, 0), Vector3.new(2.2, 1.3, 2.2), C3(170, 46, 44), M.Fabric, true)
		ball(m, "PomPom", (hc * CFrame.new(0, 1.62, 0)).Position, 0.62, C3(236, 232, 220), M.Fabric, true)
		rod(m, "PipeStem", (hc * CFrame.new(0.4, -0.55, -0.98)).Position, (hc * CFrame.new(0.9, -0.72, -1.55)).Position, 0.13, C3(60, 40, 30), M.Wood, true)
		local bowl = rod(m, "PipeBowl", (hc * CFrame.new(0.98, -0.8, -1.6)).Position, (hc * CFrame.new(0.98, -0.42, -1.6)).Position, 0.38, C3(74, 50, 36), M.Wood, true)
		local wisp = Instance.new("ParticleEmitter")
		wisp.Texture = SMOKE
		wisp.Rate = 0.8
		wisp.Lifetime = NumberRange.new(2, 3)
		wisp.Speed = NumberRange.new(0.6, 1)
		wisp.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1.1) })
		wisp.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
		wisp.Color = ColorSequence.new(C3(210, 210, 210))
		wisp.Acceleration = Vector3.new(0, 0.4, 0)
		wisp.Parent = bowl
	end
end

local function shops(f, zone, hole)
	local ShopFronts = K.shopFronts
	for name, fn in pairs(STYLES) do
		ShopFronts.STYLES[name] = fn
	end
	local pal = { brick = C3(80, 122, 138), roof = C3(86, 140, 128), trim = TIMBER, accent = C3(52, 128, 150), mat = M.WoodPlanks }
	local shopB, shopL = hole + 40, 38
	for _, spec in ipairs({
		{ l = -shopL, style = "fishmarket", title = "Fish Market", verb = "SELL", npc = "Marlow", role = "Buys your haul", machine = "sell", hat = "souwester" },
		{ l = shopL, style = "chandlery", title = "Chandlery", verb = "SHOP", npc = "Old Pearl", role = "Tools and bags", machine = "shop", hat = "beanie" },
	}) do
		local pos = HP(spec.l, DECK, shopB)
		local cf = CFrame.lookAt(pos, HP(0, DECK, shopB))
		local shopPal = table.clone(pal)
		if spec.style == "chandlery" then
			shopPal.accent = C3(46, 70, 112)
		end
		local shop = ShopFronts.build(K, f, cf, {
			style = spec.style, title = spec.title, verb = spec.verb, npc = spec.npc,
			role = spec.role, machine = spec.machine, pal = shopPal, locked = false,
		}, K.SHOP_W, K.SHOP_D, K.SHOP_H)
		dressNpc(shop, spec.hat)
	end
end

--------------------------------------------------------------------------------
-- THE HARBOUR GATE: where every other island has a timber arch.
--------------------------------------------------------------------------------

local function harbourGate(f, zone, hole)
	local b = hole + 20
	local g = Instance.new("Folder")
	g.Name = "Gate"
	g.Parent = f
	local wood = C3(92, 76, 60)
	for _, s in ipairs({ -1, 1 }) do
		rod(g, "GatePile", HP(s * 11, DECK, b), HP(s * 11, DECK + 17.5, b), 2.3, wood, M.Wood)
		rod(g, "PileCap", HP(s * 11, DECK + 17.5, b), HP(s * 11, DECK + 17.9, b), 2.6, IRON, M.Metal, true)
		for _, y in ipairs({ 2.6, 9.6, 14.4 }) do
			rod(g, "Lashing", HP(s * 11, DECK + y, b), HP(s * 11, DECK + y + 0.55, b), 2.5, ROPE, M.Fabric, true)
		end
		lantern(g, HP(s * 13.8, DECK + 14.75, b), 20, 1.15)
	end
	beam(g, "GateBeam", HP(-14.6, DECK + 15.6, b), HP(14.6, DECK + 15.6, b), 1.9, 1.7, C3(104, 84, 62), M.Wood)
	local board = mk({ Name = "GateSign", Parent = g, Size = Vector3.new(19, 3.9, 0.45),
		CFrame = H(0, DECK + 11.9, b + 0.1) * CFrame.Angles(0, math.pi, 0), Color = C3(26, 50, 62), Material = M.Wood })
	K.sign(board, string.upper(zone.name or zone.id), Enum.NormalId.Front)
	for _, c in ipairs({ { -1, 1 }, { 1, 1 }, { -1, -1 }, { 1, -1 } }) do
		mk({ Name = "SignCorner", Parent = g, Size = Vector3.new(0.9, 0.9, 0.14),
			CFrame = H(c[1] * 9.15, DECK + 11.9 + c[2] * 1.6, b + 0.37), Color = BRASS, Material = M.Metal, deco = true })
	end
	for _, s in ipairs({ -1, 1 }) do
		rod(g, "Chain", HP(s * 8.4, DECK + 13.85, b + 0.1), HP(s * 8.4, DECK + 14.75, b + 0.1), 0.16, IRON, M.Metal, true)
	end
	-- A ship's wheel on top.
	local wc = H(0, DECK + 20.7, b)
	local n, r = 12, 3
	local chord = 2 * r * math.sin(math.pi / n) * 1.12
	for i = 0, n - 1 do
		mk({ Name = "WheelRim", Parent = g, Size = Vector3.new(0.5, chord, 0.55),
			CFrame = wc * CFrame.Angles(0, 0, (i / n) * math.pi * 2) * CFrame.new(r, 0, 0), Color = C3(122, 82, 50), Material = M.Wood, deco = true })
	end
	for k = 0, 3 do
		local a = (k / 4) * math.pi
		mk({ Name = "WheelSpoke", Parent = g, Size = Vector3.new(0.3, 8.6, 0.3), CFrame = wc * CFrame.Angles(0, 0, a),
			Color = C3(134, 92, 58), Material = M.Wood, deco = true })
		for _, s in ipairs({ -1, 1 }) do
			ball(g, "WheelHandle", (wc * CFrame.Angles(0, 0, a) * CFrame.new(0, s * 4.45, 0)).Position, 0.62, C3(134, 92, 58), M.Wood, true)
		end
	end
	rod(g, "WheelHub", (wc * CFrame.new(0, 0, -0.5)).Position, (wc * CFrame.new(0, 0, 0.5)).Position, 1.3, BRASS, M.Metal, true)
	beam(g, "WheelMount", HP(0, DECK + 16.4, b), HP(0, DECK + 20.2, b), 0.7, 0.7, C3(96, 76, 58), M.Wood, true)
	-- A lifebuoy on one pile, crossed oars on the other, a starfish that
	-- climbed up at high tide and stayed.
	lifebuoy(g, H(-11, DECK + 7.3, b + 1.6), 1.35)
	local backV = HF.ZVector
	for _, s in ipairs({ -1, 1 }) do
		local a = HP(11 - s * 2.6, DECK + 3.4, b + 1.5)
		local c = HP(11 + s * 2.6, DECK + 12.4, b + 1.5)
		rod(g, "Oar", a, c, 0.32, C3(172, 138, 98), M.Wood, true)
		local dv = (c - a).Unit
		mk({ Name = "OarBlade", Parent = g, Size = Vector3.new(0.95, 2.6, 0.14),
			CFrame = CFrame.fromMatrix(c + dv * 0.6, dv:Cross(backV).Unit, dv), Color = C3(40, 92, 118), Material = M.Wood, deco = true })
	end
	starfish(g, H(-11, DECK + 4.6, b + 1.2) * CFrame.Angles(0, 0, 0.4), 0.85, C3(230, 118, 52))
	gull(g, H(12.6, DECK + 16.45, b) * CFrame.Angles(0, math.rad(200), 0), false)
end

local function lanternPosts(f, hole)
	local g = Instance.new("Folder")
	g.Name = "Lanterns"
	g.Parent = f
	for _, b in ipairs({ hole + 14, hole + 64, hole + 98 }) do
		for _, s in ipairs({ -1, 1 }) do
			local l = s * 9
			beam(g, "LanternPost", HP(l, DECK, b), HP(l, DECK + 9.4, b), 0.95, 0.95, C3(98, 78, 58), M.Wood)
			beam(g, "LanternArm", HP(l, DECK + 8.9, b), HP(l - s * 2.7, DECK + 8.9, b), 0.45, 0.5, C3(98, 78, 58), M.Wood, true)
			beam(g, "LanternStrut", HP(l, DECK + 7.1, b), HP(l - s * 1.8, DECK + 8.7, b), 0.26, 0.26, IRON, M.Metal, true)
			rod(g, "Lashing", HP(l, DECK + 1.1, b), HP(l, DECK + 1.6, b), 1.25, ROPE, M.Fabric, true)
			lantern(g, HP(l - s * 2.35, DECK + 8.65, b), 24, 1.25)
		end
	end
end

local FLAGS = {
	{ C3(238, 196, 52), C3(34, 70, 150) }, { C3(214, 50, 44), WHITE }, { C3(34, 70, 150), WHITE },
	{ C3(238, 196, 52), C3(214, 50, 44) }, { WHITE, C3(214, 50, 44) }, { C3(30, 30, 34), C3(238, 196, 52) },
}
local function signalMast(f, l, b, rng)
	local g = Instance.new("Folder")
	g.Name = "SignalMast"
	g.Parent = f
	mk({ Name = "MastStep", Parent = g, Size = Vector3.new(2, 0.8, 2), CFrame = H(l, DECK + 0.4, b), Color = WET, Material = M.Wood })
	local mast = rod(g, "Mast", HP(l, DECK + 0.8, b), HP(l, DECK + 27, b), 0.75, C3(150, 124, 90), M.Wood)
	ball(g, "MastTruck", HP(l, DECK + 27.3, b), 1, BRASS, M.Metal, true)
	beam(g, "Yard", HP(l - 3.3, DECK + 21, b), HP(l + 3.3, DECK + 21, b), 0.35, 0.35, C3(150, 124, 90), M.Wood, true)
	for _, s in ipairs({ -1, 1 }) do
		local anchor = cleat(g, HP(l + s * 5, DECK + 0.1, b + 4))
		rope(mast, HP(l, DECK + 25.5, b), anchor, HP(l + s * 5, DECK + 0.4, b + 4), 0, 0.09, C3(120, 100, 76))
		local top = HP(l + s * 3.1, DECK + 21, b)
		local string = model(g, "FlagString")
		rod(string, "Halyard", top, top - Vector3.new(0, 7.6, 0), 0.06, C3(210, 204, 190), M.Fabric, true)
		for k = 0, 2 do
			local pair = FLAGS[rng:NextInteger(1, #FLAGS)]
			local y = DECK + 19.9 - k * 2.4
			mk({ Name = "Flag", Parent = string, Size = Vector3.new(0.08, 1.7, 2.2), CFrame = H(l + s * 3.1, y, b + 1.15),
				Color = pair[1], Material = M.Fabric, deco = true })
			mk({ Name = "FlagMark", Parent = string, Size = Vector3.new(0.14, 0.7, 1), CFrame = H(l + s * 3.1, y, b + 1.15),
				Color = pair[2], Material = M.Fabric, deco = true })
		end
		string.WorldPivot = CFrame.new(top)
		tag(string, "AmbSway", { SwayAmp = 6, SwaySpeed = 1.5 + AMB:NextNumber() * 0.5, Phase = AMB:NextNumber() * 6.28 })
	end
end

--------------------------------------------------------------------------------
-- WORKING BOATS AND THE CRANE
--------------------------------------------------------------------------------

local function solidNoQuery(p)
	p.CanQuery = false
	return p
end

-- A timber derrick on the wharf corner, its boom out over the pit and a
-- bucket of ore on the line. Nothing on it answers a raycast, so it can never
-- stand between a player and the block they are clicking.
local function crane(f, hole)
	local g = Instance.new("Folder")
	g.Name = "Crane"
	g.Parent = f
	local wood = C3(112, 88, 64)
	local ml, mb = -(hole + 11.5), hole + 11.5
	solidNoQuery(mk({ Name = "CraneFoot", Parent = g, Size = Vector3.new(3.4, 1.2, 3.4), CFrame = H(ml, DECK + 0.6, mb), Color = WET, Material = M.Wood }))
	local mast = solidNoQuery(beam(g, "CraneMast", HP(ml, DECK + 1.2, mb), HP(ml, DECK + 30, mb), 1.5, 1.5, wood, M.Wood))
	for _, foot in ipairs({ { ml, mb + 15 }, { ml + 12, mb + 12 } }) do
		solidNoQuery(beam(g, "StiffLeg", HP(ml, DECK + 25.5, mb), HP(foot[1], DECK + 0.3, foot[2]), 0.9, 0.9, wood, M.Wood))
		mk({ Name = "LegShoe", Parent = g, Size = Vector3.new(2, 0.6, 2), CFrame = H(foot[1], DECK + 0.3, foot[2]), Color = IRON, Material = M.Metal, deco = true })
	end
	local tip = HP(-26, DECK + 25, 26)
	beam(g, "CraneBoom", HP(ml + 0.6, DECK + 3.4, mb - 0.6), tip, 1.1, 1.1, wood, M.Wood, true)
	local sheave = rod(g, "Sheave", tip + HF.XVector * -0.4, tip + HF.XVector * 0.4, 1.4, IRON, M.Metal, true)
	rope(mast, HP(ml, DECK + 29.4, mb), sheave, tip + Vector3.new(0, 0.5, 0), 0.4, 0.14, C3(80, 70, 60))
	for _, s in ipairs({ { ml - 5, mb + 8 }, { ml + 3, mb + 14 } }) do
		local c = cleat(g, HP(s[1], DECK + 0.1, s[2]))
		rope(mast, HP(ml, DECK + 29.4, mb), c, HP(s[1], DECK + 0.4, s[2]), 0.3, 0.12, C3(80, 70, 60))
	end
	-- The bucket, on its own swing.
	local bucket = model(g, "Bucket")
	local bc = tip - Vector3.new(0, 12.5, 0)
	rod(bucket, "BucketBody", bc - Vector3.new(0, 1.3, 0), bc + Vector3.new(0, 1.3, 0), 2.8, C3(92, 80, 70), M.CorrodedMetal, true)
	rod(bucket, "BucketRim", bc + Vector3.new(0, 1.25, 0), bc + Vector3.new(0, 1.45, 0), 3, IRON, M.Metal, true)
	for k, o in ipairs({ { -0.5, 0.3 }, { 0.6, -0.2 }, { 0.1, 0.7 } }) do
		mk({ Name = "BucketOre", Parent = bucket, Size = Vector3.new(0.9, 0.8, 0.9), CFrame = CFrame.new(bc + Vector3.new(o[1], 1.55, o[2]))
			* CFrame.Angles(k, k * 2, k * 0.5), Color = ({ C3(120, 214, 232), C3(226, 196, 104), C3(92, 96, 104) })[k], Material = M.Slate, deco = true })
	end
	local bail = bc + Vector3.new(0, 3.2, 0)
	for _, s in ipairs({ -1, 1 }) do
		beam(bucket, "BucketBail", bc + HF.XVector * (s * 1.45) + Vector3.new(0, 1.3, 0), bail, 0.14, 0.14, IRON, M.Metal, true)
	end
	local ring = ball(bucket, "BucketShackle", bail, 0.4, IRON, M.Metal, true)
	rope(sheave, tip - Vector3.new(0, 0.6, 0), ring, bail, 0, 0.13, C3(80, 70, 60))
	bucket.WorldPivot = CFrame.new(tip)
	tag(bucket, "AmbSway", { SwayAmp = 2.2, SwaySpeed = 0.55, Phase = 0.8 })
	-- Winch and counterweight at the foot.
	local wc = H(ml + 3, DECK + 2, mb + 3)
	rod(g, "WinchDrum", (wc * CFrame.new(0, 0, -1.4)).Position, (wc * CFrame.new(0, 0, 1.4)).Position, 1.6, C3(120, 96, 70), M.Wood, true)
	for _, z in ipairs({ -1.6, 1.6 }) do
		mk({ Name = "WinchCheek", Parent = g, Size = Vector3.new(1.8, 2.6, 0.3), CFrame = wc * CFrame.new(0, -0.6, z), Color = IRON, Material = M.Metal, deco = true })
	end
	beam(g, "WinchCrank", (wc * CFrame.new(0, 0, 1.8)).Position, (wc * CFrame.new(0, 1.3, 1.8)).Position, 0.2, 0.2, IRON, M.Metal, true)
	rod(g, "CrankGrip", (wc * CFrame.new(0, 1.3, 1.8)).Position, (wc * CFrame.new(0, 1.3, 2.6)).Position, 0.3, C3(150, 112, 70), M.Wood, true)
	solidNoQuery(mk({ Name = "Counterweight", Parent = g, Size = Vector3.new(3, 2.4, 3), CFrame = H(ml - 2.6, DECK + 1.2, mb + 4.4), Color = C3(116, 92, 64), Material = M.WoodPlanks }))
	for k = 0, 2 do
		ball(g, "Ballast", HP(ml - 3.2 + k * 0.8, DECK + 2.7, mb + 4 + (k % 2) * 0.8), 1, C3(118, 118, 112), M.Slate, true)
	end
end

local function fender(parent, l, y, b, outward)
	rod(parent, "Fender", HP(l - 0.45, y, b), HP(l + 0.45, y, b), 2.9, C3(30, 30, 32), M.SmoothPlastic, true)
	rod(parent, "FenderHole", HP(l - 0.47, y, b), HP(l + 0.47, y, b), 1.2, C3(12, 12, 14), M.SmoothPlastic, true)
	rod(parent, "FenderRope", HP(l, y + 1.4, b), HP(l - outward * 1.6, DECK + 0.05, b), 0.16, ROPE, M.Fabric, true)
end

-- The ore barge, moored along the east boardwalk, with a chute from the pit.
local function barge(f, hole, rng)
	local g = Instance.new("Folder")
	g.Name = "Barge"
	g.Parent = f
	local bl = hole + 30.5
	local m = model(g, "OreBarge")
	local BF = H(bl, SEA, 0)
	local function at(x, y, z)
		return BF * CFrame.new(x, y, z)
	end
	local hull = mk({ Name = "Hull", Parent = m, Size = Vector3.new(20, 3.8, 48), CFrame = at(0, 0.2, 0), Color = C3(64, 78, 82), Material = M.Metal })
	writeOn(hull, "BARNACLE BETTY", { face = Enum.NormalId.Left, font = Enum.Font.PermanentMarker, color = C3(236, 232, 214), pps = 12, w = 0.42, h = 0.5 })
	mk({ Name = "BootTop", Parent = m, Size = Vector3.new(20.12, 0.5, 48.12), CFrame = at(0, 0.35, 0), Color = C3(124, 52, 42), deco = true })
	for _, s in ipairs({ -1, 1 }) do
		mk({ Name = "Gunwale", Parent = m, Size = Vector3.new(0.7, 0.9, 48), CFrame = at(s * 9.65, 2.55, 0), Color = C3(206, 166, 52), Material = M.Metal })
		mk({ Name = "Gunwale", Parent = m, Size = Vector3.new(18.6, 0.9, 0.7), CFrame = at(0, 2.55, s * 23.65), Color = C3(206, 166, 52), Material = M.Metal })
		rod(m, "Bitt", at(-8.4, 2.1, s * 20).Position, at(-8.4, 3.4, s * 20).Position, 0.9, IRON, M.Metal, true)
	end
	mk({ Name = "Hold", Parent = m, Size = Vector3.new(18.4, 0.2, 36), CFrame = at(0, 2.2, -4), Color = C3(40, 38, 36), Material = M.Metal, deco = true })
	local ORE = { C3(120, 214, 232), C3(208, 236, 244), C3(64, 150, 176), C3(226, 196, 104), C3(86, 90, 98) }
	for k = 1, 12 do
		local x, z = rng:NextNumber(-7, 7), rng:NextNumber(-19, 10)
		local mound = 1 - math.min(1, (math.abs(x) / 8 + math.abs(z + 4) / 16) * 0.8)
		mk({ Name = "Ore", Parent = m, Size = Vector3.new(rng:NextNumber(1.6, 3.2), rng:NextNumber(1.2, 2.4), rng:NextNumber(1.6, 3.2)),
			CFrame = at(x, 2.6 + mound * 2.2, z) * CFrame.Angles(rng:NextNumber() * 0.6, rng:NextNumber() * 3, rng:NextNumber() * 0.6),
			Color = ORE[rng:NextInteger(1, #ORE)], Material = (k % 3 == 0) and M.Ice or M.Slate, deco = true })
	end
	-- Wheelhouse aft.
	mk({ Name = "Wheelhouse", Parent = m, Size = Vector3.new(8, 5.4, 6), CFrame = at(0, 4.8, 19), Color = C3(214, 214, 206), Material = M.SmoothPlastic })
	mk({ Name = "WheelhouseRoof", Parent = m, Size = Vector3.new(9, 0.45, 7), CFrame = at(0, 7.72, 19), Color = C3(40, 60, 84), Material = M.Metal })
	mk({ Name = "Window", Parent = m, Size = Vector3.new(6.2, 1.5, 0.12), CFrame = at(0, 5.9, 15.94), Color = C3(34, 46, 56), Material = M.Glass, Reflectance = 0.3, deco = true })
	for _, s in ipairs({ -1, 1 }) do
		mk({ Name = "Window", Parent = m, Size = Vector3.new(0.12, 1.3, 3), CFrame = at(s * 4.06, 5.9, 19), Color = C3(34, 46, 56), Material = M.Glass, Reflectance = 0.3, deco = true })
	end
	rod(m, "StovePipe", at(2.6, 7.9, 20.6).Position, at(2.6, 10.4, 20.6).Position, 0.5, C3(40, 40, 42), M.Metal, true)
	lifebuoy(m, at(-4.12, 4.6, 19.4) * CFrame.Angles(0, math.rad(90), 0), 0.95)
	gull(m, at(-1.5, 7.95, 19.5) * CFrame.Angles(0, math.rad(40), 0), false)
	m.WorldPivot = BF
	tag(m, "AmbBob", { BobAmp = 0.12, BobSpeed = 0.7, Roll = 0.6, Pitch = 0.3, Phase = 1.9 })
	-- Moored to cleats on the boardwalk edge.
	for _, s in ipairs({ -1, 1 }) do
		local c = cleat(g, HP(hole + 17.6, DECK + 0.1, s * 26))
		rope(c, HP(hole + 17.6, DECK + 0.45, s * 26), m:FindFirstChild("Bitt") or hull, at(-8.4, 3.2, s * 20).Position, 0.9, 0.18)
	end
	for _, b in ipairs({ -14, 0, 14 }) do
		fender(g, hole + 19.2, DECK - 1.7, b, 1)
	end
	-- The chute: ore tipped at the rim slides down into the hold.
	local c0, c1 = HP(hole + 4.5, DECK + 9.2, -6), HP(bl - 4, DECK + 5.4, -6)
	beam(g, "ChuteFloor", c0, c1, 2.6, 0.3, C3(104, 84, 62), M.WoodPlanks, true)
	for _, s in ipairs({ -1, 1 }) do
		beam(g, "ChuteSide", c0 + HF.ZVector * (s * 1.35) + Vector3.new(0, 0.5, 0), c1 + HF.ZVector * (s * 1.35) + Vector3.new(0, 0.5, 0),
			0.25, 1, C3(92, 74, 56), M.WoodPlanks, true)
	end
	for _, z in ipairs({ -7.6, -4.4 }) do
		solidNoQuery(beam(g, "ChuteLeg", HP(hole + 13.5, DECK, z), HP(hole + 13.5, DECK + 7.3, -6), 0.6, 0.6, C3(96, 76, 58), M.Wood))
	end
	mk({ Name = "Hopper", Parent = g, Size = Vector3.new(3.6, 2, 3.6), CFrame = H(hole + 3.6, DECK + 10, -6), Color = C3(88, 72, 58), Material = M.WoodPlanks, deco = true })
	for k = 0, 1 do
		local p = c0:Lerp(c1, 0.35 + k * 0.3)
		mk({ Name = "SlidingOre", Parent = g, Size = Vector3.new(0.9, 0.8, 0.9), CFrame = CFrame.new(p + Vector3.new(0, 0.55, 0)) * CFrame.Angles(k, k * 2, 0.4),
			Color = ORE[k + 1], Material = M.Slate, deco = true })
	end
end

-- THE LUCKY PULL, a small fishing boat moored along the west side of the wharf.
local function fishingBoat(f, hole)
	local g = Instance.new("Folder")
	g.Name = "FishingBoat"
	g.Parent = f
	local m = model(g, "LuckyPull")
	local BF = H(-77.1, SEA, 101)
	local function at(x, y, z)
		return BF * CFrame.new(x, y, z)
	end
	local white = C3(232, 230, 222)
	local hull = mk({ Name = "Hull", Parent = m, Size = Vector3.new(9, 3.4, 20), CFrame = at(0, 0.5, 1), Color = white, Material = M.SmoothPlastic })
	writeOn(hull, "THE LUCKY PULL", { face = Enum.NormalId.Back, font = Enum.Font.PermanentMarker, color = C3(30, 52, 92), pps = 30, w = 0.9, h = 0.4 })
	for _, s in ipairs({ -1, 1 }) do
		wedge(m, "Bow", at(s * 2.25, 0.5, -12.5) * CFrame.Angles(0, 0, s * math.rad(-90)), Vector3.new(3.4, 4.5, 7), white, M.SmoothPlastic)
		mk({ Name = "Rail", Parent = m, Size = Vector3.new(0.35, 0.45, 20), CFrame = at(s * 4.4, 2.42, 1), Color = C3(122, 90, 60), Material = M.Wood, deco = true })
		beam(m, "BowRail", at(s * 4.4, 2.42, -9).Position, at(0, 2.42, -16).Position, 0.35, 0.45, C3(122, 90, 60), M.Wood, true)
		mk({ Name = "Window", Parent = m, Size = Vector3.new(0.12, 1.3, 2.8), CFrame = at(s * 2.66, 5.6, 7.5), Color = C3(34, 46, 56), Material = M.Glass, Reflectance = 0.3, deco = true })
	end
	mk({ Name = "BootTop", Parent = m, Size = Vector3.new(9.1, 0.55, 20.1), CFrame = at(0, -0.05, 1), Color = C3(120, 36, 32), deco = true })
	mk({ Name = "Sheer", Parent = m, Size = Vector3.new(9.1, 0.4, 20.1), CFrame = at(0, 1.7, 1), Color = C3(40, 84, 140), deco = true })
	mk({ Name = "Deck", Parent = m, Size = Vector3.new(8.4, 0.2, 19.4), CFrame = at(0, 2.3, 1), Color = C3(150, 120, 84), Material = M.WoodPlanks })
	mk({ Name = "Wheelhouse", Parent = m, Size = Vector3.new(5.2, 4.8, 5), CFrame = at(0, 4.7, 7.5), Color = white, Material = M.SmoothPlastic })
	mk({ Name = "WheelhouseRoof", Parent = m, Size = Vector3.new(6, 0.4, 6), CFrame = at(0, 7.3, 7.5), Color = C3(40, 60, 84), Material = M.Metal })
	mk({ Name = "Window", Parent = m, Size = Vector3.new(4.2, 1.5, 0.12), CFrame = at(0, 5.6, 4.94), Color = C3(34, 46, 56), Material = M.Glass, Reflectance = 0.3, deco = true })
	mk({ Name = "Door", Parent = m, Size = Vector3.new(1.6, 3.2, 0.12), CFrame = at(1.2, 3.9, 10.06), Color = C3(122, 90, 60), Material = M.Wood, deco = true })
	rod(m, "Mast", at(0, 2.4, -3).Position, at(0, 17.5, -3).Position, 0.45, C3(170, 140, 100), M.Wood, true)
	rod(m, "Boom", at(0, 6.2, -3.2).Position, at(0, 5.8, -13.5).Position, 0.3, C3(170, 140, 100), M.Wood, true)
	blob(m, "Sail", at(0, 6.75, -8.3), Vector3.new(0.9, 1, 10), C3(222, 212, 188), M.Fabric, true)
	wedge(m, "Pennant", at(0, 16.8, -1.9), Vector3.new(0.08, 1.1, 2.1), C3(214, 50, 44), M.Fabric, true)
	blob(m, "Nets", at(1.4, 2.9, -6.2), Vector3.new(3.6, 1.2, 3.2), C3(58, 70, 58), M.Fabric, true)
	for k = 0, 2 do
		ball(m, "NetFloat", at(0.4 + k * 0.9, 3.45, -6.8 + k * 0.6).Position, 0.7, C3(236, 120, 40), M.SmoothPlastic, true)
	end
	for _, z in ipairs({ -2, 4.5 }) do
		blob(m, "BoatFender", at(4.85, 1.4, z), Vector3.new(0.9, 1.7, 0.9), C3(236, 120, 40), M.SmoothPlastic, true)
	end
	lifebuoy(m, at(2.72, 4.7, 8.6) * CFrame.Angles(0, math.rad(90), 0), 0.9)
	m.WorldPivot = BF
	tag(m, "AmbBob", { BobAmp = 0.2, BobSpeed = 0.9, Roll = 1.4, Pitch = 0.5, Phase = 0.4 })
	for _, z in ipairs({ -8, 9.5 }) do
		local post = rod(m, "BoatBitt", at(3.6, 2.4, z).Position, at(3.6, 3.2, z).Position, 0.5, IRON, M.Metal, true)
		local c = cleat(g, HP(-70.4, DECK + 0.1, 101 + z * 1.4))
		rope(c, HP(-70.4, DECK + 0.45, 101 + z * 1.4), post, at(3.6, 3.1, z).Position, 0.8, 0.18)
	end
end

local function rowboat(parent, cf, color, name)
	local m = model(parent, name or "Rowboat")
	mk({ Name = "Bottom", Parent = m, Size = Vector3.new(3.4, 0.4, 7.2), CFrame = cf * CFrame.new(0, 0.2, 0.6), Color = color, Material = M.WoodPlanks })
	for _, s in ipairs({ -1, 1 }) do
		mk({ Name = "Side", Parent = m, Size = Vector3.new(0.3, 1.5, 7.2), CFrame = cf * CFrame.new(s * 1.7, 0.95, 0.6), Color = color, Material = M.WoodPlanks })
		mk({ Name = "Rim", Parent = m, Size = Vector3.new(0.42, 0.22, 7.3), CFrame = cf * CFrame.new(s * 1.7, 1.8, 0.6), Color = WHITE, Material = M.Wood, deco = true })
		wedge(m, "Bow", cf * CFrame.new(s * 0.85, 0.85, -4.2) * CFrame.Angles(0, 0, s * math.rad(-90)), Vector3.new(1.7, 1.7, 2.4), color, M.WoodPlanks)
	end
	mk({ Name = "Transom", Parent = m, Size = Vector3.new(3.4, 1.5, 0.3), CFrame = cf * CFrame.new(0, 0.95, 4.35), Color = color, Material = M.WoodPlanks })
	for _, z in ipairs({ -1.4, 1.8 }) do
		mk({ Name = "Thwart", Parent = m, Size = Vector3.new(3.1, 0.22, 0.9), CFrame = cf * CFrame.new(0, 1.25, z), Color = C3(150, 120, 86), Material = M.Wood, deco = true })
	end
	return m
end

local function buoy(parent, l, b, color, rng, perch)
	local m = model(parent, "Buoy")
	local base = HP(l, SEA, b)
	local up = Vector3.new(0, 1, 0)
	rod(m, "BuoyBody", base - up * 1.2, base + up * 1.8, 2.3, color, M.SmoothPlastic, true)
	rod(m, "BuoyBand", base + up * 0.7, base + up * 1.1, 2.36, WHITE, M.SmoothPlastic, true)
	ball(m, "BuoyTop", base + up * 1.95, 1.7, color, M.SmoothPlastic, true)
	if perch then
		gull(m, CFrame.new(base + up * 2.55) * CFrame.Angles(0, rng:NextNumber() * 6.28, 0), false)
	else
		rod(m, "BuoyMast", base + up * 2.5, base + up * 4.1, 0.22, IRON, M.Metal, true)
		local lamp = ball(m, "BuoyLamp", base + up * 4.35, 0.55, color:Lerp(WHITE, 0.3), M.Neon, true)
		local pl = Instance.new("PointLight")
		pl.Range = 12
		pl.Brightness = 1.2
		pl.Color = color
		pl.Parent = lamp
		tag(lamp, "AmbBlink", { Period = 3.2, Duty = 0.3, Phase = rng:NextNumber() * 3 })
	end
	m.WorldPivot = CFrame.new(base)
	tag(m, "AmbBob", { BobAmp = 0.35, BobSpeed = 1.2 + rng:NextNumber() * 0.4, Roll = 6, Pitch = 5, Phase = rng:NextNumber() * 6.28 })
	return m
end

local function smallCraft(f, hole, rng, groundAt)
	local g = Instance.new("Folder")
	g.Name = "SmallCraft"
	g.Parent = f
	-- A rowboat tied to the far boardwalk, oars shipped.
	local rb = rowboat(g, H(30, SEA - 0.5, -(hole + 22.8)) * CFrame.Angles(0, math.rad(90), 0), C3(86, 128, 110), "Rowboat")
	for _, s in ipairs({ -1, 1 }) do
		rod(rb, "Oar", (H(30, SEA + 1.45, -(hole + 22.8)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(s * 0.7, 0, -3)).Position,
			(H(30, SEA + 1.45, -(hole + 22.8)) * CFrame.Angles(0, math.rad(90), 0) * CFrame.new(s * 0.9, 0, 3.4)).Position, 0.22, C3(172, 138, 98), M.Wood, true)
	end
	rb.WorldPivot = H(30, SEA, -(hole + 22.8))
	tag(rb, "AmbBob", { BobAmp = 0.16, BobSpeed = 1.1, Roll = 3, Pitch = 1.2, Phase = 2.6 })
	local c = cleat(g, HP(25, DECK + 0.1, -(hole + 17.6)))
	rope(c, HP(25, DECK + 0.45, -(hole + 17.6)), rb:FindFirstChild("Rim") or rb:FindFirstChildWhichIsA("BasePart"), HP(26.6, SEA + 1.8, -(hole + 22.8)), 0.6, 0.15)
	-- Another one upturned on the sand, waiting for paint.
	-- Another hauled up on the sand, heeled over, oars left in it.
	local gy = groundAt(34, 176)
	local beachCf = H(34, gy + 0.15, 176) * CFrame.Angles(0, math.rad(25), math.rad(11))
	local up = rowboat(g, beachCf, C3(92, 144, 172), "BeachedBoat")
	for _, s in ipairs({ -1, 1 }) do
		rod(up, "Oar", (beachCf * CFrame.new(s * 0.6, 1.5, -2.8)).Position, (beachCf * CFrame.new(s * 1.1, 1.9, 3.6)).Position, 0.22, C3(172, 138, 98), M.Wood, true)
	end
	for _, d in ipairs(up:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = false
		end
	end
	-- Channel markers: red to port, green to starboard, yellow on the rocks.
	for _, bspec in ipairs({
		{ -34, -118, C3(206, 44, 40) }, { 34, -118, C3(40, 150, 70) },
		{ -44, -170, C3(206, 44, 40) }, { 44, -170, C3(40, 150, 70) },
		{ -150, 60, C3(236, 196, 40), true }, { 160, -60, C3(236, 196, 40), true },
	}) do
		buoy(g, bspec[1], bspec[2], bspec[3], rng, bspec[4])
	end
end

--------------------------------------------------------------------------------
-- OUT ON THE WATER AND ALONG THE SHORE
--------------------------------------------------------------------------------

local function lighthouse(f, groundAt)
	local g = Instance.new("Folder")
	g.Name = "Lighthouse"
	g.Parent = f
	local l, b = -96, -240
	local base = groundAt(l, b) - 0.6
	local function P(y)
		return HP(l, base + y, b)
	end
	local up = Vector3.new(0, 1, 0)
	local dark = C3(40, 42, 46)
	local red = C3(180, 46, 40)
	rod(g, "Plinth", P(-6), P(1.2), 16, C3(120, 118, 112), M.Cobblestone)
	rod(g, "PlinthCap", P(1.2), P(1.7), 16.8, C3(150, 146, 138), M.Slate)
	local segH = 6
	for i = 0, 5 do
		rod(g, "Tower", P(1.7 + i * segH), P(1.7 + (i + 1) * segH), 11 - i * 0.62, (i % 2 == 0) and WHITE or red, M.SmoothPlastic)
	end
	local topY = 1.7 + 6 * segH
	-- The door and its step face the harbour; three slit windows climb the tower.
	local toward = (HP(0, 0, 0) - HP(l, 0, b)).Unit
	local face = CFrame.lookAt(P(0), P(0) + toward)
	mk({ Name = "LighthouseDoor", Parent = g, Size = Vector3.new(2, 3.4, 0.3), CFrame = face * CFrame.new(0, 3.4, -5.4), Color = C3(60, 84, 110), Material = M.Wood })
	mk({ Name = "DoorStep", Parent = g, Size = Vector3.new(3.2, 0.6, 1.8), CFrame = face * CFrame.new(0, 1.55, -8.2), Color = C3(150, 146, 138), Material = M.Slate })
	for k, y in ipairs({ 13, 22, 30 }) do
		mk({ Name = "SlitWindow", Parent = g, Size = Vector3.new(0.7, 1.4, 0.3), CFrame = face * CFrame.new((k - 2) * 0.8, y, -(5.3 - y * 0.058)),
			Color = C3(30, 36, 44), Material = M.Glass, deco = true })
	end
	rod(g, "Gallery", P(topY), P(topY + 0.7), 13, dark, M.Metal)
	local n = 10
	for i = 0, n - 1 do
		local a0, a1 = (i / n) * math.pi * 2, ((i + 1) / n) * math.pi * 2
		local p0 = HP(l + math.cos(a0) * 6, base + topY + 0.7, b + math.sin(a0) * 6)
		local p1 = HP(l + math.cos(a1) * 6, base + topY + 0.7, b + math.sin(a1) * 6)
		rod(g, "RailPost", p0, p0 + up * 1.9, 0.18, dark, M.Metal, true)
		beam(g, "Rail", p0 + up * 1.9, p1 + up * 1.9, 0.16, 0.16, dark, M.Metal, true)
	end
	local lr = topY + 0.7
	local glass = rod(g, "LanternRoom", P(lr), P(lr + 5), 6.4, C3(220, 240, 250), M.Glass, true)
	glass.Transparency = 0.5
	for i = 0, 5 do
		local a = (i / 6) * math.pi * 2
		local p0 = HP(l + math.cos(a) * 3.2, base + lr, b + math.sin(a) * 3.2)
		rod(g, "Astragal", p0, p0 + up * 5, 0.2, dark, M.Metal, true)
	end
	rod(g, "LanternRoof", P(lr + 5), P(lr + 5.8), 7.6, red, M.Metal, true)
	rod(g, "LanternRoof", P(lr + 5.8), P(lr + 6.5), 5.4, red, M.Metal, true)
	rod(g, "LanternRoof", P(lr + 6.5), P(lr + 7.1), 3, red, M.Metal, true)
	ball(g, "Ventilator", P(lr + 7.6), 1.3, dark, M.Metal, true)
	rod(g, "Vane", P(lr + 8), P(lr + 10.6), 0.14, dark, M.Metal, true)
	wedge(g, "VaneArrow", CFrame.new(P(lr + 10)) * CFrame.Angles(0, 0.7, 0), Vector3.new(0.08, 0.6, 2.2), dark, M.Metal, true)
	gull(g, CFrame.new(HP(l + 6, base + topY + 2.7, b)) * CFrame.Angles(0, math.rad(80), 0), false)

	-- The light: a lamp and two fans of light, back to back, that the client turns.
	local head = model(g, "LampHead")
	local centre = P(lr + 2.4)
	local core = ball(head, "Lamp", centre, 2.3, C3(255, 246, 214), M.Neon, true)
	local pl = Instance.new("PointLight")
	pl.Range = 45
	pl.Brightness = 2.2
	pl.Color = C3(255, 238, 200)
	pl.Parent = core
	local spot = Instance.new("SpotLight")
	spot.Range = 60
	spot.Angle = 24
	spot.Brightness = 5
	spot.Color = C3(255, 238, 200)
	spot.Face = Enum.NormalId.Front
	spot.Parent = core
	for _, sgn in ipairs({ -1, 1 }) do
		local u = Vector3.new(0, 0, -1) * sgn
		for _, half in ipairs({ -1, 1 }) do
			local vY = Vector3.new(half, 0, 0)
			local fan = wedge(head, "LightFan", CFrame.fromMatrix(centre + u * 23 + vY * 3, vY:Cross(u), vY), Vector3.new(0.12, 6, 44),
				C3(255, 240, 206), M.Neon, true)
			fan.Transparency = 0.9
			fan.CastShadow = false
		end
	end
	head.WorldPivot = CFrame.new(centre)
	tag(head, "AmbSpin", { SpinSpeed = 38 })

	-- The keeper's cottage on the shoulder of the islet, laundry out.
	local cl, cb = -62, -247
	local cy = groundAt(cl, cb)
	local ccf = CFrame.lookAt(HP(cl, cy + 0.4, cb), HP(cl, cy + 0.4, cb) + toward)
	mk({ Name = "CottageFooting", Parent = g, Size = Vector3.new(10, 5, 8), CFrame = ccf * CFrame.new(0, -2.1, 0), Color = C3(124, 120, 112), Material = M.Cobblestone })
	mk({ Name = "Cottage", Parent = g, Size = Vector3.new(8.4, 5, 6.4), CFrame = ccf * CFrame.new(0, 2.9, 0), Color = WHITE, Material = M.SmoothPlastic })
	gableRoof(g, ccf * CFrame.new(0, 0.4, 0), 8.4, 6.4, 5, 32, red, M.SmoothPlastic, WHITE, M.SmoothPlastic)
	mk({ Name = "CottageDoor", Parent = g, Size = Vector3.new(1.6, 3, 0.2), CFrame = ccf * CFrame.new(-1.8, 1.9, -3.25), Color = C3(60, 84, 110), Material = M.Wood, deco = true })
	mk({ Name = "CottageWindow", Parent = g, Size = Vector3.new(1.6, 1.4, 0.2), CFrame = ccf * CFrame.new(1.9, 3.3, -3.25), Color = C3(255, 214, 150), Material = M.Neon, deco = true }).Transparency = 0.3
	local chim = mk({ Name = "CottageChimney", Parent = g, Size = Vector3.new(1.2, 3.4, 1.2), CFrame = ccf * CFrame.new(2.4, 8.6, 1.2), Color = C3(122, 72, 58), Material = M.Brick })
	local puff = Instance.new("ParticleEmitter")
	puff.Texture = SMOKE
	puff.Rate = 1
	puff.Lifetime = NumberRange.new(4, 6)
	puff.Speed = NumberRange.new(1.5, 2.5)
	puff.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 4.5) })
	puff.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	puff.Color = ColorSequence.new(C3(160, 160, 160))
	puff.Acceleration = Vector3.new(0.6, 0.6, 0.2)
	puff.Parent = chim
	local posts = {}
	for k, pt in ipairs({ { -70, -243 }, { -79, -236 } }) do
		local y = groundAt(pt[1], pt[2])
		posts[k] = rod(g, "LinePost", HP(pt[1], y - 0.6, pt[2]), HP(pt[1], y + 4.4, pt[2]), 0.3, TIMBER, M.Wood, true)
		posts[k .. "top"] = HP(pt[1], y + 4.2, pt[2])
	end
	rope(posts[1], posts["1top"], posts[2], posts["2top"], 0.45, 0.07, C3(220, 214, 200))
	for k, col in ipairs({ C3(60, 100, 170), WHITE, C3(214, 92, 70) }) do
		local p = posts["1top"]:Lerp(posts["2top"], k / 4) - Vector3.new(0, 0.35 + math.sin(k / 4 * math.pi) * 0.4, 0)
		local cloth = mk({ Name = "Laundry", Parent = g, Size = Vector3.new(1.4, 1.8, 0.08), CFrame = CFrame.lookAt(p, p + (posts["2top"] - posts["1top"]).Unit:Cross(up))
			* CFrame.new(0, -0.9, 0), Color = col, Material = M.Fabric, deco = true })
		tag(cloth, "AmbSway", { SwayAmp = 10, SwaySpeed = 1.8, Phase = k, Hinge = Vector3.new(0, 0.9, 0) })
	end
end

local function reefLife(f, rng, groundAt)
	local g = Instance.new("Folder")
	g.Name = "Reef"
	g.Parent = f
	local CORAL = { C3(236, 120, 96), C3(206, 92, 170), C3(120, 170, 222), C3(240, 196, 92) }
	local BRAIN = { C3(214, 178, 96), C3(196, 110, 134), C3(140, 168, 96) }
	for _, pt in ipairs({ { -110, -40 }, { -150, -150 }, { 40, -150 }, { 130, -90 }, { -120, 110 }, { 110, 100 } }) do
		local function spot()
			for _ = 1, 6 do
				local l, b = pt[1] + rng:NextNumber(-11, 11), pt[2] + rng:NextNumber(-11, 11)
				local y = groundAt(l, b)
				if y < SEA - 3 then
					return l, y, b
				end
			end
			return nil
		end
		for _ = 1, 2 do
			local l, y, b = spot()
			if l then
				local d = rng:NextNumber(2.2, 3.6)
				ball(g, "BrainCoral", HP(l, y + d * 0.18, b), d, BRAIN[rng:NextInteger(1, #BRAIN)], M.Pebble, true)
			end
		end
		for _ = 1, 2 do
			local l, y, b = spot()
			if l then
				local col = CORAL[rng:NextInteger(1, #CORAL)]
				local foot = HP(l, y - 0.2, b)
				for _ = 1, 3 do
					local dir = Vector3.new(rng:NextNumber(-0.6, 0.6), 1, rng:NextNumber(-0.6, 0.6)).Unit
					rod(g, "BranchCoral", foot, foot + dir * rng:NextNumber(2, 3.6), rng:NextNumber(0.35, 0.5), col, M.SmoothPlastic, true)
				end
			end
		end
		do
			local l, y, b = spot()
			if l then
				mk({ Name = "SeaFan", Parent = g, Size = Vector3.new(0.14, 3.2, 3.6), CFrame = CFrame.new(HP(l, y + 1.4, b)) * CFrame.Angles(0, rng:NextNumber() * 6.28, 0),
					Color = C3(132, 72, 156), Material = M.Fabric, deco = true })
			end
		end
		do
			local l, y, b = spot()
			if l then
				rod(g, "Anemone", HP(l, y - 0.2, b), HP(l, y + 0.7, b), 1.1, C3(120, 60, 80), M.SmoothPlastic, true)
				ball(g, "AnemoneTips", HP(l, y + 0.9, b), 1.3, C3(255, 150, 190), M.Neon, true).Transparency = 0.2
			end
		end
		for _ = 1, 3 do
			local l, y, b = spot()
			if l then
				local len = (SEA - 1.2) - y
				local kelp = mk({ Name = "Kelp", Parent = g, Size = Vector3.new(0.22, len, 1), CFrame = CFrame.new(HP(l, y + len / 2, b))
					* CFrame.Angles(0, rng:NextNumber() * 6.28, 0), Color = C3(74, 112, 52), Material = M.SmoothPlastic, deco = true })
				tag(kelp, "AmbSway", { SwayAmp = 6, SwaySpeed = 0.45 + rng:NextNumber() * 0.3, Phase = rng:NextNumber() * 6.28, Hinge = Vector3.new(0, -len / 2, 0) })
			end
		end
	end
end

local function skyGulls(f, rng)
	local g = Instance.new("Folder")
	g.Name = "Gulls"
	g.Parent = f
	for k, o in ipairs({ { 48, 38, 0.24 }, { 74, 46, -0.3 }, { 102, 54, 0.2 } }) do
		local centre = HP(rng:NextNumber(-20, 20), 0, rng:NextNumber(10, 60))
		local bird = gull(g, CFrame.new(centre + Vector3.new(o[1], G + o[2], 0)), true)
		tag(bird, "AmbOrbit", { Center = Vector3.new(centre.X, G + o[2], centre.Z), Radius = o[1], Speed = o[3], Phase = k * 2.1, Bank = 16 })
	end
end

local function crab(parent, l, b, groundAt, yaw)
	local y = groundAt(l, b)
	local cf = H(l, y, b) * CFrame.Angles(0, yaw, 0)
	local red = C3(200, 76, 54)
	blob(parent, "Crab", cf * CFrame.new(0, 0.3, 0), Vector3.new(1.3, 0.5, 1), red, M.SmoothPlastic, true)
	for _, s in ipairs({ -1, 1 }) do
		blob(parent, "CrabClaw", cf * CFrame.new(s * 0.78, 0.35, -0.72) * CFrame.Angles(0, s * 0.5, 0), Vector3.new(0.5, 0.34, 0.72), red, M.SmoothPlastic, true)
		rod(parent, "CrabStalk", (cf * CFrame.new(s * 0.2, 0.5, -0.38)).Position, (cf * CFrame.new(s * 0.25, 0.86, -0.44)).Position, 0.08, red, M.SmoothPlastic, true)
		ball(parent, "CrabEye", (cf * CFrame.new(s * 0.25, 0.9, -0.44)).Position, 0.15, C3(18, 18, 20), M.SmoothPlastic, true)
	end
end

local function beach(f, rng, groundAt)
	local g = Instance.new("Folder")
	g.Name = "Beach"
	g.Parent = f
	for _, d in ipairs({ { -50, 182, 7, 1.2 }, { 92, 190, 9, 1.4 }, { -118, 172, 6, 1 } }) do
		local yaw = rng:NextNumber() * math.pi
		local v = Vector3.new(math.cos(yaw), 0, math.sin(yaw)) * (d[3] / 2)
		local y = groundAt(d[1], d[2])
		solidNoQuery(rod(g, "Driftwood", HP(d[1], y + d[4] * 0.3, d[2]) - v, HP(d[1], y + d[4] * 0.36, d[2]) + v, d[4], DRIFT, M.Wood))
	end
	crab(g, 80, 150, groundAt, 0.4)
	crab(g, -86, 160, groundAt, 2.2)
	crab(g, 104, 166, groundAt, -1.1)
	for _ = 1, 7 do
		local l, b = rng:NextNumber(-110, 110), rng:NextNumber(162, 184)
		if math.abs(l) > 74 or b > 164 then
			wedge(g, "Shell", H(l, groundAt(l, b) + 0.08, b) * CFrame.Angles(0, rng:NextNumber() * 6.28, 0) * CFrame.Angles(math.rad(-90), 0, 0),
				Vector3.new(0.5, 0.45, 0.16), (rng:NextNumber() < 0.5) and C3(240, 214, 200) or C3(236, 176, 170), M.SmoothPlastic, true)
		end
	end
	-- A driftwood fire above the tideline, log seats round it.
	local fl, fb = -40, 178
	local fy = groundAt(fl, fb)
	for i = 0, 6 do
		local a = (i / 7) * math.pi * 2
		ball(g, "FireStone", HP(fl + math.cos(a) * 1.9, fy + 0.2, fb + math.sin(a) * 1.9), 0.9, C3(112, 110, 106), M.Slate, true)
	end
	for i = 0, 2 do
		local a = (i / 3) * math.pi
		local v = Vector3.new(math.cos(a), 0, math.sin(a)) * 1.3
		rod(g, "FireLog", HP(fl, fy + 0.35, fb) - v, HP(fl, fy + 0.55, fb) + v, 0.45, C3(70, 50, 36), M.Wood, true)
	end
	local ember = ball(g, "Embers", HP(fl, fy + 0.3, fb), 1.2, C3(255, 120, 40), M.Neon, true)
	ember.Transparency = 0.25
	local fire = Instance.new("Fire")
	fire.Size = 3
	fire.Heat = 7
	fire.Color = C3(255, 150, 60)
	fire.SecondaryColor = C3(255, 70, 20)
	fire.Parent = ember
	local glow = Instance.new("PointLight")
	glow.Range = 16
	glow.Brightness = 1.6
	glow.Color = C3(255, 150, 80)
	glow.Parent = ember
	for i = 0, 2 do
		local a = (i / 3) * math.pi * 2 + 0.5
		local c = HP(fl + math.cos(a) * 4.6, 0, fb + math.sin(a) * 4.6)
		local t = Vector3.new(-math.sin(a), 0, math.cos(a)) * 1.7
		local y = groundAt(fl + math.cos(a) * 4.6, fb + math.sin(a) * 4.6)
		solidNoQuery(rod(g, "LogSeat", Vector3.new(c.X, G + y + 0.45, c.Z) - t, Vector3.new(c.X, G + y + 0.45, c.Z) + t, 1.1, DRIFT, M.Wood))
	end
	local sy = groundAt(18, 172)
	rod(g, "SignPost", HP(18, sy - 0.6, 172), HP(18, sy + 4, 172), 0.3, TIMBER, M.Wood, true)
	local sgn = mk({ Name = "TideSign", Parent = g, Size = Vector3.new(3.4, 1.3, 0.2), CFrame = H(18, sy + 3.4, 171.8), Color = C3(228, 222, 204), Material = M.Wood, deco = true })
	writeOn(sgn, "MIND THE TIDE", { font = Enum.Font.PermanentMarker, color = C3(150, 40, 34), pps = 40 })
end

--------------------------------------------------------------------------------
-- ON THE WHARF: a bell, the harbour notices, a tide gauge, a place to fish
-- from, the ore company's crates, fish drying, benches that face the water.
--------------------------------------------------------------------------------

local function wharfProps(f, hole, rng)
	local g = Instance.new("Folder")
	g.Name = "WharfProps"
	g.Parent = f
	local post = C3(98, 78, 58)

	local bl, bb = 13.6, hole + 24.5
	solidNoQuery(beam(g, "BellPost", HP(bl, DECK, bb), HP(bl, DECK + 6.8, bb), 0.8, 0.8, post, M.Wood))
	beam(g, "BellArm", HP(bl, DECK + 6.4, bb), HP(bl - 2.1, DECK + 6.4, bb), 0.4, 0.45, post, M.Wood, true)
	blob(g, "HarbourBell", CFrame.new(HP(bl - 1.9, DECK + 5.3, bb)), Vector3.new(1.5, 1.8, 1.5), BRASS, M.Metal, true)
	rod(g, "BellRope", HP(bl - 1.9, DECK + 4.4, bb), HP(bl - 1.9, DECK + 2.6, bb), 0.12, ROPE, M.Fabric, true)

	local nl, nb = -20, hole + 81.5
	for _, z in ipairs({ -2.1, 2.1 }) do
		solidNoQuery(beam(g, "NoticePost", HP(nl, DECK, nb + z), HP(nl, DECK + 5.4, nb + z), 0.4, 0.4, post, M.Wood))
	end
	local board = mk({ Name = "NoticeBoard", Parent = g, Size = Vector3.new(4.6, 3.2, 0.25),
		CFrame = H(nl + 0.3, DECK + 3.4, nb) * CFrame.Angles(0, math.rad(-90), 0), Color = C3(122, 98, 72), Material = M.WoodPlanks })
	local paper = mk({ Name = "NoticePaper", Parent = g, Size = Vector3.new(4, 2.6, 0.05), CFrame = board.CFrame * CFrame.new(0, 0, -0.15),
		Color = C3(236, 228, 206), deco = true })
	writeOn(paper, "HARBOUR NOTICES\n- No swimming in the mine.\n- Gulls are not staff.\n- Please do not feed the gulls cards.\n-- Marlow, Harbourmaster",
		{ color = C3(44, 40, 34), align = Enum.TextXAlignment.Left, pps = 60, w = 0.9, h = 0.88 })
	mk({ Name = "NoticeRoof", Parent = g, Size = Vector3.new(1.1, 0.3, 5.4), CFrame = H(nl + 0.2, DECK + 5.55, nb), Color = C3(86, 140, 128), Material = M.CorrodedMetal, deco = true })
	gull(g, H(nl + 0.2, DECK + 5.7, nb + 1.2) * CFrame.Angles(0, 1.2, 0), false)

	local tl, tb = -73.8, hole + 22
	rod(g, "GaugePile", HP(tl, -16, tb), HP(tl, DECK + 5.5, tb), 1.1, C3(86, 72, 58), M.Wood, true)
	local gauge = mk({ Name = "TideGauge", Parent = g, Size = Vector3.new(1.3, 9, 0.2),
		CFrame = H(tl + 0.66, SEA + 3.5, tb) * CFrame.Angles(0, math.rad(-90), 0), Color = WHITE, deco = true })
	writeOn(gauge, "8\n7\n6\n5\n4\n3\n2\n1\n0", { font = Enum.Font.Bangers, color = C3(34, 34, 40), pps = 40, w = 0.7, h = 0.97 })
	for k = 0, 8, 2 do
		mk({ Name = "GaugeTick", Parent = g, Size = Vector3.new(0.55, 0.14, 0.06), CFrame = gauge.CFrame * CFrame.new(-0.32, -4 + k, -0.12),
			Color = C3(200, 50, 44), deco = true })
	end

	-- A stool, a bucket and a rod over the far rail. The stool is marked, so a
	-- fishing tool has somewhere to start.
	local fl, fb = -30, -(hole + 13)
	local stool = rod(g, "Stool", HP(fl, DECK + 1.7, fb), HP(fl, DECK + 2, fb), 1.4, C3(130, 100, 70), M.Wood)
	stool:SetAttribute("FishingSpot", true)
	for i = 0, 2 do
		local a = (i / 3) * math.pi * 2
		rod(g, "StoolLeg", HP(fl + math.cos(a) * 0.5, DECK, fb + math.sin(a) * 0.5), HP(fl + math.cos(a) * 0.35, DECK + 1.7, fb + math.sin(a) * 0.35),
			0.16, C3(110, 84, 60), M.Wood, true)
	end
	rod(g, "Bucket", HP(fl + 1.4, DECK, fb - 0.6), HP(fl + 1.4, DECK + 1.3, fb - 0.6), 1.2, C3(90, 110, 124), M.Metal, true)
	wedge(g, "FishTail", H(fl + 1.4, DECK + 1.62, fb - 0.6) * CFrame.Angles(math.rad(-90), 0.3, 0), Vector3.new(0.07, 0.7, 0.5), C3(176, 190, 202), M.SmoothPlastic, true)
	local tipP = HP(fl - 1.5, DECK + 7.2, fb - 8.5)
	local rodPart = rod(g, "FishingRod", HP(fl - 0.4, DECK + 1.2, fb - 0.2), tipP, 0.14, C3(60, 44, 32), M.Wood, true)
	local bobber = model(g, "Bobber")
	local bp = HP(fl - 2, SEA + 0.1, fb - 12.5)
	local top = ball(bobber, "BobberTop", bp + Vector3.new(0, 0.12, 0), 0.5, C3(214, 50, 44), M.SmoothPlastic, true)
	ball(bobber, "BobberBottom", bp - Vector3.new(0, 0.1, 0), 0.46, WHITE, M.SmoothPlastic, true)
	bobber.WorldPivot = CFrame.new(bp)
	tag(bobber, "AmbBob", { BobAmp = 0.12, BobSpeed = 1.6, Roll = 0, Pitch = 0, Phase = 0.5 })
	rope(rodPart, tipP, top, bp + Vector3.new(0, 0.3, 0), 1.2, 0.05, C3(230, 230, 230))

	for i, o in ipairs({ { 60, 114, 0 }, { 60.3, 114, 3.4 }, { 56, 113, 0 } }) do
		local c = mk({ Name = "OreCrate", Parent = g, Size = Vector3.new(4, 3.4, 4), CFrame = H(o[1], DECK + 1.7 + o[3], o[2]) * CFrame.Angles(0, math.rad(i * 11), 0),
			Color = C3(132, 100, 66), Material = M.WoodPlanks })
		if i == 1 then
			writeOn(c, "MISTREEF\nORE CO.", { face = Enum.NormalId.Left, font = Enum.Font.Bangers, color = C3(44, 36, 30), pps = 30 })
		end
	end
	for _, o in ipairs({ { 52, 121 }, { 54.8, 122.4 }, { 52.6, 124.6 } }) do
		local p0 = HP(o[1], DECK, o[2])
		solidNoQuery(rod(g, "Barrel", p0, p0 + Vector3.new(0, 3.2, 0), 2.4, C3(122, 88, 56), M.Wood))
		for _, y in ipairs({ 0.6, 2.6 }) do
			rod(g, "BarrelHoop", p0 + Vector3.new(0, y - 0.11, 0), p0 + Vector3.new(0, y + 0.11, 0), 2.5, IRON, M.Metal, true)
		end
	end

	local rl, rb = -60, 118
	for _, z in ipairs({ -2.6, 2.6 }) do
		solidNoQuery(rod(g, "RackPost", HP(rl, DECK, rb + z), HP(rl, DECK + 5.2, rb + z), 0.4, TIMBER, M.Wood))
	end
	rod(g, "RackBar", HP(rl, DECK + 5, rb - 3), HP(rl, DECK + 5, rb + 3), 0.3, TIMBER, M.Wood, true)
	for k = -2, 2 do
		local hang = HP(rl, DECK + 5, rb + k * 1.05)
		rod(g, "RackString", hang, hang - Vector3.new(0, 0.9, 0), 0.05, C3(210, 204, 190), M.Fabric, true)
		fish(g, CFrame.new(hang - Vector3.new(0, 2.1, 0)) * CFrame.Angles(math.rad(-90), rng:NextNumber() * 0.6, 0), C3(186, 170, 140), 1.9)
	end

	for _, benchB in ipairs({ 128, 146 }) do
		local bc = H(-66, DECK, benchB)
		solidNoQuery(mk({ Name = "Bench", Parent = g, Size = Vector3.new(1.5, 0.35, 5), CFrame = bc * CFrame.new(0, 2, 0), Color = C3(124, 96, 68), Material = M.Wood }))
		mk({ Name = "BenchBack", Parent = g, Size = Vector3.new(0.3, 1.6, 5), CFrame = bc * CFrame.new(0.75, 3, 0) * CFrame.Angles(0, 0, math.rad(-10)),
			Color = C3(124, 96, 68), Material = M.Wood, deco = true })
		for _, z in ipairs({ -2, 2 }) do
			mk({ Name = "BenchLeg", Parent = g, Size = Vector3.new(1.3, 1.85, 0.3), CFrame = bc * CFrame.new(0, 0.93, z), Color = C3(96, 74, 54), Material = M.Wood, deco = true })
		end
	end
end

local function mist(f, rng, groundAt, hole)
	local g = Instance.new("Folder")
	g.Name = "Mist"
	g.Parent = f
	local function source(pos, size)
		local p = mk({ Name = "MistSource", Parent = g, Size = size, CFrame = CFrame.new(pos), Color = WHITE, deco = true, shadow = false })
		p.Transparency = 1
		return p
	end
	local function fog(p, rate, life, size0, size1, alpha, speed, accel)
		local e = Instance.new("ParticleEmitter")
		e.Texture = SMOKE
		e.Shape = Enum.ParticleEmitterShape.Box
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		e.EmissionDirection = Enum.NormalId.Top
		e.Rate = rate
		e.Lifetime = NumberRange.new(life * 0.75, life * 1.25)
		e.Speed = NumberRange.new(speed * 0.5, speed)
		e.SpreadAngle = Vector2.new(60, 60)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size0), NumberSequenceKeypoint.new(1, size1) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, alpha),
			NumberSequenceKeypoint.new(0.7, math.min(1, alpha + 0.03)), NumberSequenceKeypoint.new(1, 1) })
		e.Color = ColorSequence.new(C3(210, 226, 228))
		e.LightInfluence = 0.7
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-6, 6)
		e.Drag = 0.3
		e.Acceleration = accel or Vector3.new(0.3, 0.04, 0.15)
		e.Parent = p
		return e
	end
	for i = 0, 11 do
		local a = (i / 12) * math.pi * 2 + rng:NextNumber() * 0.3
		local r = 150 + rng:NextNumber() * 110
		local l, b = math.sin(a) * r, math.cos(a) * r
		if groundAt(l, b) < SEA - 1 then
			fog(source(HP(l, SEA + 2, b), Vector3.new(70, 1, 70)), 0.8, 20, 16, 38, 0.86, 0.8)
		end
	end
	for _, sd in ipairs({ { 0, -(hole + 24), 150, 6 }, { -(hole + 24), -10, 6, 130 }, { hole + 45, -10, 6, 130 } }) do
		fog(source(HP(sd[1], SEA + 0.6, sd[2]), Vector3.new(sd[3], 1, sd[4])), 0.5, 12, 6, 16, 0.9, 0.6, Vector3.new(0, 0.15, 0))
	end
	for _, rk in ipairs(ROCKS) do
		if rk.h <= 12 then
			local p = source(HP(rk.l, SEA + 0.5, rk.b), Vector3.new(rk.r * 1.8, 0.5, rk.r * 1.8))
			local e = Instance.new("ParticleEmitter")
			e.Shape = Enum.ParticleEmitterShape.Box
			e.EmissionDirection = Enum.NormalId.Top
			e.Rate = 1.5
			e.Lifetime = NumberRange.new(0.6, 1.1)
			e.Speed = NumberRange.new(4, 8)
			e.SpreadAngle = Vector2.new(25, 25)
			e.Acceleration = Vector3.new(0, -22, 0)
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1.6) })
			e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
			e.Color = ColorSequence.new(WHITE)
			e.LightEmission = 0.3
			e.Parent = p
		end
	end
end

--------------------------------------------------------------------------------
-- ENTRY POINTS
--------------------------------------------------------------------------------

-- WorldBuilder's portal, weathered: planked steps, rope round the feet,
-- barnacles, weed off the lintel, a lantern on each side.
function Harbor.dressPortal(kit, pf, zone)
	K = kit
	local step = pf:FindFirstChild("Step")
	if not step then
		return
	end
	local cf = step.CFrame * CFrame.new(0, -0.5, 0)
	step.Material = M.WoodPlanks
	step.Color = C3(104, 84, 62)
	local base = pf:FindFirstChild("Base")
	if base then
		base.Material = M.WoodPlanks
		base.Color = C3(84, 68, 52)
	end
	local d = Instance.new("Folder")
	d.Name = "Dress"
	d.Parent = pf
	for _, s in ipairs({ -1, 1 }) do
		rod(d, "RopeWrap", (cf * CFrame.new(s * 9.6, 4.2, 0)).Position, (cf * CFrame.new(s * 9.6, 4.8, 0)).Position, 6.4, ROPE, M.Fabric, true)
		for k = 1, 4 do
			ball(d, "Barnacle", (cf * CFrame.new(s * 9.6 + (k - 2.5) * 1.1, 2.7 + (k % 2) * 0.5, -2.9)).Position, 0.45, C3(214, 210, 196), M.Slate, true)
		end
		beam(d, "LanternBracket", (cf * CFrame.new(s * 11.7, 17.5, 0)).Position, (cf * CFrame.new(s * 13.7, 17.5, 0)).Position, 0.3, 0.3, IRON, M.Metal, true)
		lantern(d, (cf * CFrame.new(s * 13.5, 17.3, 0)).Position, 18, 1)
	end
	for k = 0, 5 do
		local x = -10 + k * 4 + (k % 2) * 0.6
		local len = 1.8 + (k % 3) * 1.1
		local weed = mk({ Name = "Weed", Parent = d, Size = Vector3.new(0.5, len, 0.08), CFrame = cf * CFrame.new(x, 27.6 - len / 2, -2.6),
			Color = ALGAE:Lerp(C3(90, 130, 70), (k % 2) * 0.4), Material = M.Fabric, deco = true })
		tag(weed, "AmbSway", { SwayAmp = 5, SwaySpeed = 0.9, Phase = k, Hinge = Vector3.new(0, len / 2, 0) })
	end
	starfish(d, cf * CFrame.new(-9.6, 8.5, -2.16) * CFrame.Angles(0, math.pi, 0.5), 0.9, C3(230, 118, 52))
end

function Harbor.outpost(kit, parent, zone, origin, axis)
	setFrame(kit, origin, axis)
	AMB = Random.new(7)
	local rng = Random.new((tonumber(zone.angle) or 0) * 131 + 11)
	local hole = MineConfig.GRID * MineConfig.BLOCK * 0.5
	local column = Harbor._column
	local function groundAt(l, b)
		if column then
			return (column(l, b)) - G
		end
		return SEA - 10
	end
	local f = Instance.new("Folder")
	f.Name = "Outpost_" .. zone.id
	f:SetAttribute("ZoneId", zone.id)
	f.Parent = parent

	local timber = Instance.new("Folder")
	timber.Name = "Timber"
	timber.Parent = f
	cofferdam(timber, hole)
	boardwalk(timber, hole, rng)
	wharf(timber, hole, rng)
	shops(f, zone, hole)
	harbourGate(f, zone, hole)
	lanternPosts(f, hole)
	signalMast(f, hole + 13.5, hole + 11.5, rng)
	signalMast(f, -(hole + 13.5), hole + 102, rng)
	signalMast(f, hole + 13.5, hole + 102, rng)
	crane(f, hole)
	barge(f, hole, rng)
	fishingBoat(f, hole)
	smallCraft(f, hole, rng, groundAt)
	lighthouse(f, groundAt)
	reefLife(f, rng, groundAt)
	skyGulls(f, rng)
	beach(f, rng, groundAt)
	wharfProps(f, hole, rng)
	mist(f, rng, groundAt, hole)

	-- The client reads this for Mistreef's own sky: misty, sea-grey.
	local holder = Instance.new("Model")
	holder.Name = "Atmosphere"
	holder.Parent = f
	local marker = mk({ Name = "AmbZone", Parent = holder, Size = Vector3.new(1, 1, 1), CFrame = H(0, 30, 0), deco = true, shadow = false })
	marker.Transparency = 1
	for k, v in pairs({ Radius = 380, Fade = 160, Density = 0.42, Haze = 2.2, Glare = 0, Offset = 0.15,
		Color = C3(196, 214, 216), Decay = C3(98, 134, 142) }) do
		marker:SetAttribute(k, v)
	end
	CollectionService:AddTag(marker, "AmbZone")
	holder.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	return f
end

return Harbor
