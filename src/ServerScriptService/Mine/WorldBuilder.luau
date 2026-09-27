-- WorldBuilder: terrain biomes + stone camp. Leaves TCGAfkHub / city portal intact.
local MineConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Mine"):WaitForChild("Shared"):WaitForChild("MineConfig"))

local WorldBuilder = {}

local WOOD = Color3.fromRGB(118, 90, 62)
local STONE = Color3.fromRGB(92, 90, 84)
local DARK = Color3.fromRGB(48, 46, 42)
local CREAM = Color3.fromRGB(232, 224, 208)
-- Shared ground height for plates, props, terrain skirts, and stands.
local GROUND = 5

-- Two opaque faces at exactly the same height flicker against each other as the
-- camera moves. That is the twitchy look, and it is easy to author by accident
-- here: every path is laid at GROUND + 0.04 and every station beam sits at the
-- same beam height, so wherever two of them overlap in plan view their top faces
-- land on precisely the same plane and the renderer has no way to pick a winner.
--
-- Rather than hand-tune every prop, each new part checks the tops already
-- claimed at a footprint it overlaps and drops by a hair until it has that plane
-- to itself. Four thousandths of a stud is invisible; being coplanar is not.
local COPLANAR_EPS = 0.004
local usedTops = {}

local function claimTop(p)
	-- Axis-aligned boxes only. A rotated prop almost never lines up by accident,
	-- and its footprint is not the AABB this test assumes.
	if math.abs(p.CFrame.UpVector.Y) < 0.999 then
		return
	end
	for _ = 1, 12 do
		local pos, half = p.Position, p.Size * 0.5
		local key = string.format("%.3f", pos.Y + half.Y)
		local list = usedTops[key]
		local clash = false
		if list then
			for _, r in ipairs(list) do
				-- Touching edge to edge is fine; only genuine overlap fights.
				if math.abs(r.x - pos.X) < (r.sx + half.X) - 0.02
					and math.abs(r.z - pos.Z) < (r.sz + half.Z) - 0.02 then
					clash = true
					break
				end
			end
		end
		if not clash then
			list = list or {}
			usedTops[key] = list
			table.insert(list, { x = pos.X, z = pos.Z, sx = half.X, sz = half.Z })
			return
		end
		p.CFrame = p.CFrame - Vector3.new(0, COPLANAR_EPS, 0)
	end
end

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide ~= false
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or STONE
	p.Size = props.Size or Vector3.new(4, 4, 4)
	p.CFrame = props.CFrame or CFrame.new()
	p.Name = props.Name or "Part"
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = true
	p.Parent = props.Parent
	if props.Shape then p.Shape = props.Shape end
	if props.Transparency then p.Transparency = props.Transparency end
	claimTop(p)
	return p
end

local function prompt(adornee, action, object)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = object
	pr.HoldDuration = 0.15
	pr.MaxActivationDistance = 14
	pr.RequiresLineOfSight = false
	pr.Style = Enum.ProximityPromptStyle.Default
	pr.UIOffset = Vector2.new(0, 0)
	pr.Parent = adornee
	return pr
end

local function sign(adornee, text, face)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25
	gui.Parent = adornee
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.BuilderSansBold
	t.TextScaled = true
	t.TextColor3 = CREAM
	t.Text = text
	t.Parent = gui
end

local function applyLighting()
	-- Grass decoration renders as waist-high blades. The property is not on
	-- Terrain in every Studio build, and when it threw here it took the entire
	-- world build with it. Best effort only.
	pcall(function()
		(workspace.Terrain :: any).Decoration = false
	end)
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 14.5
	lighting.Brightness = 2.4
	lighting.Ambient = Color3.fromRGB(70, 70, 70)
	lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
	lighting.FogEnd = 100000
	lighting.FogStart = 0
	lighting.EnvironmentDiffuseScale = 1
	lighting.EnvironmentSpecularScale = 1
	lighting.GeographicLatitude = 0
	local atmo = lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmo.Parent = lighting
	atmo.Density = 0.3
	atmo.Offset = 0.25
	atmo.Color = Color3.fromRGB(199, 199, 199)
	atmo.Decay = Color3.fromRGB(106, 112, 125)
	atmo.Glare = 0
	atmo.Haze = 0
	local bloom = lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Parent = lighting
	bloom.Intensity = 0.6
	bloom.Threshold = 2.6
	bloom.Size = 24
	local rays = lighting:FindFirstChildOfClass("SunRaysEffect")
	if rays then rays.Intensity = 0.01 rays.Spread = 0.1 rays.Enabled = true end
	local dof = lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof then dof.Enabled = false end
	local blur = lighting:FindFirstChild("BL_Blur")
	if blur then blur.Enabled = false end
end

local function stall(parent, cf, machine)
	local body = part({ Name = "Machine_" .. machine.id, Parent = parent, Size = Vector3.new(8, 3.2, 5), CFrame = cf, Color = WOOD, Material = Enum.Material.WoodPlanks })
	body:SetAttribute("Machine", machine.id)
	part({ Name = "Roof", Parent = parent, Size = Vector3.new(9, 0.6, 6.2), CFrame = cf * CFrame.new(0, 2.6, 0), Color = Color3.fromRGB(86, 64, 44), Material = Enum.Material.Wood })
	part({ Name = "PostL", Parent = parent, Size = Vector3.new(0.6, 4.4, 0.6), CFrame = cf * CFrame.new(-3.4, 0.6, -2), Color = WOOD, Material = Enum.Material.Wood })
	part({ Name = "PostR", Parent = parent, Size = Vector3.new(0.6, 4.4, 0.6), CFrame = cf * CFrame.new(3.4, 0.6, -2), Color = WOOD, Material = Enum.Material.Wood })
	local plaque = part({ Name = "Plaque", Parent = parent, Size = Vector3.new(5.4, 1.1, 0.2), CFrame = cf * CFrame.new(0, 1.1, -2.6), Color = DARK, Material = Enum.Material.SmoothPlastic })
	sign(plaque, machine.name)
	prompt(body, "Use", machine.name)
	return body
end

local function shrine(parent)
	local cf = CFrame.new(0, 4, 22)
	part({ Name = "ShrineBase", Parent = parent, Size = Vector3.new(16, 1.2, 16), CFrame = cf * CFrame.new(0, -1.4, 0), Color = STONE, Material = Enum.Material.Cobblestone })
	part({ Name = "ShrineStep", Parent = parent, Size = Vector3.new(10, 1, 10), CFrame = cf * CFrame.new(0, -0.4, 0), Color = Color3.fromRGB(110, 108, 100), Material = Enum.Material.Slate })
	for i = 1, 4 do
		local a = math.rad(i * 90 + 45)
		part({ Name = "Pillar", Parent = parent, Size = Vector3.new(1.2, 8, 1.2), CFrame = cf * CFrame.new(math.sin(a) * 4.6, 3.2, math.cos(a) * 4.6), Color = STONE, Material = Enum.Material.Slate })
	end
	local crystal = part({ Name = "Machine_prestige", Parent = parent, Size = Vector3.new(2.4, 7, 2.4), CFrame = cf * CFrame.new(0, 3.6, 0) * CFrame.Angles(0, math.rad(45), 0), Color = Color3.fromRGB(186, 92, 168), Material = Enum.Material.Glass })
	crystal:SetAttribute("Machine", "prestige")
	part({ Name = "CrystalCap", Parent = parent, Size = Vector3.new(1.6, 1.6, 1.6), CFrame = cf * CFrame.new(0, 7.6, 0), Color = Color3.fromRGB(210, 140, 190), Material = Enum.Material.Glass, Shape = Enum.PartType.Ball })
	local plaque = part({ Name = "PrestigeSign", Parent = parent, Size = Vector3.new(8, 1.2, 0.2), CFrame = cf * CFrame.new(0, 1.2, -8.2), Color = DARK, Material = Enum.Material.SmoothPlastic })
	sign(plaque, "PRESTIGE  ·  keeps cards")
	prompt(crystal, "Prestige", "Reset pick and bag, keep cards")
end

local function arch(parent, pos, zone, silent)
	local look = Vector3.new(0, pos.Y, 0)
	local cf = CFrame.lookAt(pos, look)
	part({ Name = "PillarL", Parent = parent, Size = Vector3.new(1.6, 12, 1.6), CFrame = cf * CFrame.new(-4.2, 0, 0), Color = STONE, Material = Enum.Material.Slate })
	part({ Name = "PillarR", Parent = parent, Size = Vector3.new(1.6, 12, 1.6), CFrame = cf * CFrame.new(4.2, 0, 0), Color = STONE, Material = Enum.Material.Slate })
	local lintel = part({ Name = "Gate_" .. zone.id, Parent = parent, Size = Vector3.new(10.4, 1.8, 1.8), CFrame = cf * CFrame.new(0, 6.6, 0), Color = zone.color:Lerp(STONE, 0.55), Material = Enum.Material.Slate })
	lintel:SetAttribute("ZoneId", zone.id)
	lintel:SetAttribute("PrestigeReq", tonumber(zone.minRebirth or zone.prestige) or 0)
	sign(lintel, zone.name)
	-- Walk-to zones get no prompt. The mine is right there; you walk in.
	if not silent then
		prompt(lintel, "Enter", zone.name)
	end
	return lintel
end

local function tree(folder, pos, rng)
	-- pos is ground contact (Y = rim height). Trunk sits on the ground.
	local h = 7 + rng:NextNumber() * 5
	part({ Name = "Trunk", Parent = folder, Size = Vector3.new(1.2, h, 1.2),
		CFrame = CFrame.new(pos + Vector3.new(0, h * 0.5, 0)),
		Color = Color3.fromRGB(86, 64, 42), Material = Enum.Material.Wood })
	part({ Name = "Leaves", Parent = folder,
		Size = Vector3.new(6 + rng:NextNumber() * 3, 5, 6 + rng:NextNumber() * 3),
		CFrame = CFrame.new(pos + Vector3.new(0, h + 1.2, 0)),
		Color = Color3.fromRGB(62, 118, 58), Material = Enum.Material.Grass,
		Shape = Enum.PartType.Ball })
end

local function decorate(folder, zone, origin, dir)
	-- Theme sits AROUND the mine rim, never floating above the pit mouth.
	local rng = Random.new(zone.angle * 91 + 7)
	local kind = zone.decor or "trees"
	local rim = (tonumber(zone.island) or MineConfig.ISLAND or 80) + 10
	local count = (kind == "trees") and 22 or 16
	local flatDir = Vector3.new((dir and dir.X) or 0, 0, (dir and dir.Z) or 1)
	if flatDir.Magnitude < 0.01 then
		flatDir = Vector3.new(0, 0, 1)
	else
		flatDir = flatDir.Unit
	end
	local approachAng = math.atan2(-flatDir.X, -flatDir.Z)
	local halfWedge = math.rad(38)
	for i = 1, count do
		local a = (i / count) * math.pi * 2 + rng:NextNumber() * 0.2
		local angDiff = math.abs(((a - approachAng + math.pi) % (math.pi * 2)) - math.pi)
		if angDiff < halfWedge then
			continue
		end
		local d = rim + 8 + rng:NextNumber() * 24
		local pos = Vector3.new(origin.X + math.sin(a) * d, GROUND, origin.Z + math.cos(a) * d)
		if kind == "trees" then
			tree(folder, pos, rng)
		elseif kind == "spikes" then
			local rh = 4 + rng:NextNumber() * 7
			part({ Name = "Rock", Parent = folder,
				Size = Vector3.new(3 + rng:NextNumber() * 4, rh, 3 + rng:NextNumber() * 4),
				CFrame = CFrame.new(pos + Vector3.new(0, rh * 0.5, 0)) * CFrame.Angles(0, a, 0),
				Color = Color3.fromRGB(120, 128, 140), Material = Enum.Material.Rock })
		elseif kind == "pools" then
			part({ Name = "Ice", Parent = folder, Size = Vector3.new(6, 1.2, 7),
				CFrame = CFrame.new(pos + Vector3.new(0, 0.4, 0)),
				Color = Color3.fromRGB(190, 220, 230), Material = Enum.Material.Ice })
		elseif kind == "bolts" then
			local ch = 4 + rng:NextNumber() * 3
			part({ Name = "Crystal", Parent = folder, Size = Vector3.new(1.4, ch, 1.4),
				CFrame = CFrame.new(pos + Vector3.new(0, ch * 0.5, 0)),
				Color = Color3.fromRGB(236, 214, 120), Material = Enum.Material.Glass })
		elseif kind == "orbs" then
			part({ Name = "Menhir", Parent = folder, Size = Vector3.new(2.2, 8, 2.2),
				CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)),
				Color = Color3.fromRGB(54, 42, 62), Material = Enum.Material.Slate })
		else
			part({ Name = "Obelisk", Parent = folder, Size = Vector3.new(1.8, 10, 1.8),
				CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)),
				Color = Color3.fromRGB(28, 24, 32), Material = Enum.Material.Basalt })
		end
	end
end

--[[
	TERRAIN AROUND EACH MINE.

	The ground a player sees on every mine island, the hills beyond it, and --
	on the portal islands -- a terraced bowl so the place reads as a dig site.

	The rule that matters: TERRAIN TOPS OUT AT GROUND, EXACTLY. The version this
	replaced filled a disc whose top sat at GROUND + 1 and laid a raised band on
	top of that, and terrain works in 4-stud voxels, so every island ended up
	three studs deep in it. The plates you stand on, the rim of the pit and the
	shop decks were all underneath, and the shops stood in a trench cut through
	the fill with only their roofs showing.

	Materials come from the zone itself (MineConfig `ground` / `accent`) rather
	than from the decor kind, which had turned every island past the meadow the
	same grey rock. Anything that is not a terrain material -- Foil, Glass --
	falls back to one that is, because FillBlock simply refuses them.
]]
local TERRAIN_OK = {}
for _, m in ipairs({
	Enum.Material.Grass, Enum.Material.Sand, Enum.Material.Rock, Enum.Material.Slate,
	Enum.Material.Snow, Enum.Material.Mud, Enum.Material.Ground, Enum.Material.Sandstone,
	Enum.Material.Basalt, Enum.Material.Brick, Enum.Material.Cobblestone, Enum.Material.Concrete,
	Enum.Material.Glacier, Enum.Material.Ice, Enum.Material.LeafyGrass, Enum.Material.Limestone,
	Enum.Material.Pavement, Enum.Material.Salt, Enum.Material.WoodPlanks, Enum.Material.Asphalt,
	Enum.Material.CrackedLava,
}) do
	TERRAIN_OK[m] = true
end

local function terrainMat(m, fallback)
	return (m and TERRAIN_OK[m]) and m or fallback
end

local function themeRimTerrain(terrain, zone, origin, zoneIndex, dir, walkTo)
	local groundMat, wallMat
	if zoneIndex <= 1 then
		groundMat, wallMat = Enum.Material.Grass, Enum.Material.LeafyGrass
	else
		groundMat = terrainMat(zone.ground, Enum.Material.Rock)
		wallMat = terrainMat(zone.accent, Enum.Material.Rock)
		if wallMat == groundMat then
			wallMat = Enum.Material.Rock
		end
	end

	local flatDir = Vector3.new(dir.X, 0, dir.Z)
	flatDir = (flatDir.Magnitude < 0.01) and Vector3.new(0, 0, 1) or flatDir.Unit
	local approachAng = math.atan2(-flatDir.X, -flatDir.Z)
	local halfWedge = math.rad(38)
	local function inApproach(a)
		local d = math.abs(((a - approachAng + math.pi) % (math.pi * 2)) - math.pi)
		return d < halfWedge
	end

	local island = tonumber(zone.island) or MineConfig.ISLAND or 180
	local pitW = MineConfig.GRID * MineConfig.BLOCK
	local open = (zoneIndex <= 1) and 18 or (70 + zoneIndex * 8)
	local outerR = island + open + ((zoneIndex <= 1) and 14 or 110)
	local rng = Random.new((zone.angle or zoneIndex) * 53 + 11)

	--[[
		1. The ground, laid as a BLOCK.

		Two things about terrain decide this line, both measured:
		  * FillCylinder rounds to whole 4-stud voxels -- a disc told to stop at
		    GROUND comes back several studs higher, whatever fraction you give it.
		    FillBlock honours a fractional top.
		  * The surface you actually stand on and see sits TWO STUDS above the
		    filled top (half a voxel): fill to 3.0 and the ground is at 5.0.
		Missing both is what buried every island three studs deep, with the
		plates, the pit rim and the shop decks all underneath.

		So the fill stops at GROUND - 2.1: the real surface lands a tenth under
		GROUND, the plates you stand on sit on it without sharing its plane, and
		anything laid on the plates is actually visible.
	]]
	local SURFACE_LIFT = 2
	terrain:FillBlock(CFrame.new(origin.X, GROUND - 0.1 - SURFACE_LIFT - 8, origin.Z),
		Vector3.new(outerR * 2, 16, outerR * 2), groundMat)

	-- 2. The pit, carved SQUARE and deep. The stone lip laid in build() covers
	--    the seam at the top. Carved well below the ground slab so no rounded
	--    sliver of terrain is left sitting inside the shaft as a hidden floor.
	-- (The same half-voxel lift applies sideways: the real edge of a carve sits
	--  about two studs inside it, so this is cut wide enough that the true edge
	--  still falls under the lip rather than over the mouth.)
	terrain:FillBlock(CFrame.new(origin.X, GROUND + 5, origin.Z),
		Vector3.new(pitW + 10, 90, pitW + 10), Enum.Material.Air)

	if walkTo then
		-- The meadow is walked to from the lobby: rolling walls, approach open.
		for i = 1, 36 do
			local a = (i / 36) * math.pi * 2
			if not inApproach(a) then
				local d = island + open + 24 + rng:NextNumber() * 16
				local r = 16 + rng:NextNumber() * 12
				terrain:FillBall(Vector3.new(origin.X + math.sin(a) * d, GROUND + 2 - r * 0.2,
					origin.Z + math.cos(a) * d), r, wallMat)
			end
		end
	else
		--[[
			3. Portal islands: a terraced bowl -- three benches stepping up and away
			from the mine, the way a quarry is cut. Built as one drum with each step
			carved back out.

			Every cylinder here starts and stops on a voxel boundary at 8 or above,
			so none of them can touch the ground layer the block above just laid.
		]]
		local base = 8
		local r0 = math.max(island * 1.5, outerR - 110)
		local stepW, stepH = 30, 12
		terrain:FillCylinder(CFrame.new(origin.X, base + stepH * 1.5, origin.Z), stepH * 3, r0 + stepW * 3, wallMat)
		for k = 2, 0, -1 do
			local floorY = base + stepH * k
			local h = (base + stepH * 3 + 8) - floorY
			terrain:FillCylinder(CFrame.new(origin.X, floorY + h * 0.5, origin.Z), h, r0 + stepW * k, Enum.Material.Air)
		end
	end

	-- 4. Low mounds beyond the island edge, never across the approach. After the
	--    bowl, so carving the benches cannot shave their tops off.
	local hills = (zoneIndex <= 1) and 26 or 30
	for i = 1, hills do
		local a = (i / hills) * math.pi * 2 + rng:NextNumber() * 0.12
		if not inApproach(a) then
			local d = island + 22 + rng:NextNumber() * (open * 0.7)
			local r = 8 + rng:NextNumber() * 9
			terrain:FillBall(Vector3.new(origin.X + math.sin(a) * d, GROUND - r * 0.45,
				origin.Z + math.cos(a) * d), r, (i % 2 == 0) and wallMat or groundMat)
		end
	end
	return groundMat, wallMat
end


--------------------------------------------------------------------------------
-- THE LOBBY
--
-- Open grass with stone paths, not a plaza. A single circular slab reads as a
-- menu screen: everything the same distance out, the same colour, arranged by a
-- loop rather than by anybody. Buildings sit at uneven distances and bearings,
-- each with its own palette, joined by paths that show you where to go.
--
-- The starter mine is straight ahead through a deliberate gap in the buildings.
-- The other five mines are portals, each alone in its own clearing so they read
-- as places rather than a row of doors.
--------------------------------------------------------------------------------

-- Roughly double the old 8 x 3.2 x 5 market stall. Big enough to read as a
-- building from across the field, small enough that you stand AT it rather
-- than walking around inside it.
-- Ground level (also declared at top). Terrain fills top out HERE and buildings sit ON it.
-- GROUND = 5

local SHOP_W, SHOP_D, SHOP_H = 18, 13, 12

local TIMBER = Color3.fromRGB(104, 74, 48)
local SLATE = Color3.fromRGB(74, 78, 92)
local LAMP = Color3.fromRGB(255, 214, 150)
local PATH = Color3.fromRGB(146, 140, 128)

-- A stone path from a to b. Terrain rather than parts, so it beds into the
-- ground instead of floating on it.
-- A path drawn ON the deck. Terrain paths cut trenches through a flat plate.
local function pathBetween(parent, a, b, width)
	local flatA = Vector3.new(a.X, GROUND + 0.04, a.Z)
	local flatB = Vector3.new(b.X, GROUND + 0.04, b.Z)
	local delta = flatB - flatA
	local len = delta.Magnitude
	if len < 1 then
		return
	end
	local p = part({ Name = "Path", Parent = parent, Size = Vector3.new(width or 12, 0.4, len),
		CFrame = CFrame.lookAt(flatA + delta * 0.5, flatB),
		Color = Color3.fromRGB(142, 138, 128), Material = Enum.Material.Cobblestone })
	p.CanCollide = false
	return p
end

local function npc(parent, cf, skin, shirt, trousers, name, role)
	local m = Instance.new("Model")
	m.Name = "NPC_" .. name:gsub("%s", "")
	m.Parent = parent

	local torso = part({ Name = "Torso", Parent = m, Size = Vector3.new(2.6, 3.1, 1.4),
		CFrame = cf * CFrame.new(0, 4.1, 0), Color = shirt, Material = Enum.Material.Fabric })
	part({ Name = "Head", Parent = m, Size = Vector3.new(1.95, 1.95, 1.95),
		CFrame = cf * CFrame.new(0, 6.6, 0), Color = skin, Material = Enum.Material.SmoothPlastic })
	part({ Name = "ArmL", Parent = m, Size = Vector3.new(1.1, 2.9, 1.15),
		CFrame = cf * CFrame.new(-1.9, 4, 0), Color = shirt, Material = Enum.Material.Fabric })
	part({ Name = "ArmR", Parent = m, Size = Vector3.new(1.1, 2.9, 1.15),
		CFrame = cf * CFrame.new(1.9, 4, 0), Color = shirt, Material = Enum.Material.Fabric })
	part({ Name = "LegL", Parent = m, Size = Vector3.new(1.25, 2.6, 1.3),
		CFrame = cf * CFrame.new(-0.68, 1.3, 0), Color = trousers, Material = Enum.Material.Fabric })
	part({ Name = "LegR", Parent = m, Size = Vector3.new(1.25, 2.6, 1.3),
		CFrame = cf * CFrame.new(0.68, 1.3, 0), Color = trousers, Material = Enum.Material.Fabric })

	local bb = Instance.new("BillboardGui")
	bb.Name = "Tag"
	bb.Size = UDim2.fromOffset(240, 54)
	bb.StudsOffset = Vector3.new(0, 4.2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 100
	bb.Adornee = torso
	bb.Parent = torso
	local who = Instance.new("TextLabel")
	who.BackgroundTransparency = 1
	who.Size = UDim2.new(1, 0, 0, 28)
	who.Font = Enum.Font.BuilderSansBold
	who.TextSize = 22
	who.TextColor3 = Color3.fromRGB(255, 255, 255)
	who.TextStrokeTransparency = 0.3
	who.Text = name
	who.Parent = bb
	local what = Instance.new("TextLabel")
	what.BackgroundTransparency = 1
	what.Position = UDim2.fromOffset(0, 27)
	what.Size = UDim2.new(1, 0, 0, 22)
	what.Font = Enum.Font.BuilderSansMedium
	what.TextSize = 16
	what.TextColor3 = Color3.fromRGB(206, 214, 232)
	what.TextStrokeTransparency = 0.55
	what.Text = role
	what.Parent = bb

	m.PrimaryPart = torso
	return m
end

-- The pad you stand on. Ring stays green because green means "you can use
-- this"; the WORD is white, because a green word on a green ring on grass reads
-- as one glowing smear.
local function pad(parent, cf, label, promptText, machineId, locked)
	local f = Instance.new("Folder")
	f.Name = "Pad_" .. (machineId or label)
	f.Parent = parent
	local col = locked and Color3.fromRGB(128, 136, 152) or Color3.fromRGB(70, 255, 140)

	local ring = part({ Name = "Ring", Parent = f, Size = Vector3.new(0.4, 12, 12),
		CFrame = cf * CFrame.new(0, 0.28, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = col, Material = Enum.Material.Neon, Shape = Enum.PartType.Cylinder })
	ring.CanCollide = false
	-- No RingHole cover — neon ring stays fully visible.
	local glow = part({ Name = "Glow", Parent = f, Size = Vector3.new(0.3, 9.4, 9.4),
		CFrame = cf * CFrame.new(0, 0.34, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = col, Material = Enum.Material.Neon, Shape = Enum.PartType.Cylinder })
	glow.Transparency = 0.88
	glow.CanCollide = false

	local pl = Instance.new("PointLight")
	pl.Brightness = 1.4
	pl.Range = 20
	pl.Color = col
	pl.Parent = ring

	local anchorPart = part({ Name = "LabelAnchor", Parent = f, Size = Vector3.new(1, 1, 1),
		CFrame = cf * CFrame.new(0, 6, 0), Color = col, Material = Enum.Material.Neon })
	anchorPart.Transparency = 1
	anchorPart.CanCollide = false
	local bb = Instance.new("BillboardGui")
	bb.Name = "PadLabel"
	bb.Size = UDim2.fromOffset(300, 70)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 70
	bb.Adornee = anchorPart
	bb.Parent = anchorPart
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.BuilderSansBold
	t.TextSize = 44
	t.TextColor3 = Color3.fromRGB(255, 255, 255)
	t.TextStrokeTransparency = 0.15
	t.TextStrokeColor3 = Color3.fromRGB(8, 10, 14)
	t.Text = string.upper(label)
	t.Parent = bb

	local hit = part({ Name = "Trigger", Parent = f, Size = Vector3.new(12, 8, 12),
		CFrame = cf * CFrame.new(0, 4, 0), Color = col, Material = Enum.Material.Neon })
	hit.Transparency = 1
	hit.CanCollide = false
	hit:SetAttribute("Machine", machineId)
	if locked then
		hit:SetAttribute("Locked", true)
		prompt(hit, "Read", promptText .. " (soon)")
	else
		-- Say what the button does. Every stall said "Open", so the depot that
		-- cashes your haul and the blacksmith that SELLS you a bag were the same
		-- word one stud apart -- people stood on the depot pressing Open and
		-- concluded selling was broken.
		local act = "Open"
		if machineId == "sell" then
			act = "SELL ALL"
		elseif machineId == "shop" or machineId == "depth_shop" then
			act = "Shop"
		end
		prompt(hit, act, promptText)
	end
	return f
end

-- One building. `pal` gives it its own brick, roof and trim so the row does not
-- read as nine copies.
-- Each trade gets its own building. Colour alone never distinguished them.
local ShopFronts = require(script.Parent:FindFirstChild("MineShopFronts")
	or script:FindFirstChild("MineShopFronts"))
local SHOP_KIT = { part = part, sign = sign, npc = npc, pad = pad }

--[[
	Zones with a look of their own. A theme builds the terrain and the outpost
	in place of the shared ones; the stand, the portals and the shaft walls stay
	WorldBuilder's, so the server finds everything where it always has. A theme
	that fails to load, or fails while building, falls back to the standard
	island rather than leaving a zone with no shops.
]]
local THEME_KIT = { part = part, sign = sign, npc = npc, pad = pad, prompt = prompt, shopFronts = ShopFronts,
	GROUND = GROUND, SHOP_W = SHOP_W, SHOP_D = SHOP_D, SHOP_H = SHOP_H }
local THEMES = {}
for zoneId, moduleName in pairs({ mistreef = "MineHarbor", bloodmoon = "MineBloodLake", bigbang = "MineEventHorizon" }) do
	local mod = script.Parent:FindFirstChild(moduleName)
	if mod then
		local ok, theme = pcall(require, mod)
		if ok and type(theme) == "table" then
			THEMES[zoneId] = theme
		else
			warn("[Mine] " .. moduleName .. " did not load, " .. zoneId .. " gets the standard island: " .. tostring(theme))
		end
	end
end

local function shopFront(parent, cf, pal, title, npcName, role, verb, machineId, locked)
	local f = Instance.new("Folder")
	f.Name = "Shop_" .. (machineId or title:gsub("%s", ""))
	f.Parent = parent
	local W, D, H = SHOP_W, SHOP_D, SHOP_H

	part({ Name = "Floor", Parent = f, Size = Vector3.new(W + 6, 1.2, D + 6),
		CFrame = cf * CFrame.new(0, 0.6, 0), Color = SLATE, Material = Enum.Material.Slate })
	part({ Name = "Back", Parent = f, Size = Vector3.new(W, H, 1.4),
		CFrame = cf * CFrame.new(0, H / 2, D / 2), Color = pal.brick, Material = pal.mat })
	part({ Name = "SideL", Parent = f, Size = Vector3.new(1.4, H, D),
		CFrame = cf * CFrame.new(-W / 2, H / 2, 0), Color = pal.brick, Material = pal.mat })
	part({ Name = "SideR", Parent = f, Size = Vector3.new(1.4, H, D),
		CFrame = cf * CFrame.new(W / 2, H / 2, 0), Color = pal.brick, Material = pal.mat })
	part({ Name = "Roof", Parent = f, Size = Vector3.new(W + 8, 1.6, D + 8),
		CFrame = cf * CFrame.new(0, H + 0.8, 0), Color = pal.roof, Material = Enum.Material.Slate })
	part({ Name = "Cornice", Parent = f, Size = Vector3.new(W + 9, 1, D + 9),
		CFrame = cf * CFrame.new(0, H + 1.9, 0), Color = pal.trim, Material = Enum.Material.WoodPlanks })
	part({ Name = "Lintel", Parent = f, Size = Vector3.new(W + 3, 3, 2),
		CFrame = cf * CFrame.new(0, H - 2, -D / 2), Color = pal.trim, Material = Enum.Material.WoodPlanks })

	for i = 0, 7 do
		part({ Name = "Awn", Parent = f, Size = Vector3.new(W / 8 - 0.2, 0.5, 8),
			CFrame = cf * CFrame.new(-W / 2 + (W / 8) * (i + 0.5), H - 5, -D / 2 - 3.4)
				* CFrame.Angles(math.rad(-20), 0, 0),
			Color = (i % 2 == 0) and pal.accent or CREAM, Material = Enum.Material.Fabric })
	end

	part({ Name = "Counter", Parent = f, Size = Vector3.new(W - 8, 4.4, 3.2),
		CFrame = cf * CFrame.new(0, 2.2, -D / 2 + 3), Color = pal.trim, Material = Enum.Material.WoodPlanks })
	part({ Name = "CounterTop", Parent = f, Size = Vector3.new(W - 6, 0.6, 4.4),
		CFrame = cf * CFrame.new(0, 4.7, -D / 2 + 3), Color = CREAM, Material = Enum.Material.Wood })

	local board = part({ Name = "Sign", Parent = f, Size = Vector3.new(W - 5, 3.6, 0.4),
		CFrame = cf * CFrame.new(0, H - 2, -D / 2 - 1.1), Color = DARK, Material = Enum.Material.SmoothPlastic })
	sign(board, string.upper(title), Enum.NormalId.Front)

	local bulb = part({ Name = "Lamp", Parent = f, Size = Vector3.new(1.8, 0.7, 1.8),
		CFrame = cf * CFrame.new(0, H - 3.5, 2), Color = LAMP, Material = Enum.Material.Neon })
	local pl = Instance.new("PointLight")
	pl.Brightness = 2
	pl.Range = 38
	pl.Color = LAMP
	pl.Parent = bulb

	-- Face the pad (customer approach). Blind yaw-180 put Look·toPad at -1.
	local padOff = Vector3.new(0, 0.35, -D / 2 - 8)
	local npcOff = Vector3.new(0, 1.2, D / 2 - 6)
	local padWorld = (cf * CFrame.new(padOff)).Position
	local npcFeet = (cf * CFrame.new(npcOff)).Position
	npc(f, CFrame.lookAt(npcFeet, Vector3.new(padWorld.X, npcFeet.Y, padWorld.Z)),
		Color3.fromRGB(226, 186, 148), pal.accent, Color3.fromRGB(58, 56, 70), npcName, role)
	pad(f, cf * CFrame.new(padOff), verb, npcName .. "  -  " .. title, machineId, locked)
	return f
end

-- A portal standing alone in its own clearing, with a path leading to it.
-- A portal. Built DEAD: dark stone, no glow, no motion. The client lights it
-- and starts the swirl only once that player can actually walk through, so an
-- unreachable zone never advertises itself as open.
--
-- `facing` is what it looks toward, so the same function works in the lobby and
-- out on an island.
local function portal(parent, pos, zone, facing, label, destination)
	local f = Instance.new("Folder")
	f.Name = "Portal_" .. (destination or zone.id)
	f.Parent = parent
	local col = zone.color or Color3.fromRGB(140, 140, 160)
	local cf = CFrame.lookAt(pos, facing or Vector3.new(0, pos.Y, 0))
	local stone = Color3.fromRGB(96, 94, 104)

	-- Stepped base, so it stands on something rather than sprouting from a plate.
	part({ Name = "Step", Parent = f, Size = Vector3.new(34, 1, 26),
		CFrame = cf * CFrame.new(0, 0.5, 0), Color = Color3.fromRGB(150, 146, 138),
		Material = Enum.Material.Slate })
	part({ Name = "Base", Parent = f, Size = Vector3.new(28, 1.4, 20),
		CFrame = cf * CFrame.new(0, 1.7, 0), Color = Color3.fromRGB(126, 122, 116),
		Material = Enum.Material.Slate })

	-- Tapered jambs with a capital, rather than two bare posts.
	for _, s in ipairs({ -1, 1 }) do
		part({ Name = "Jamb", Parent = f, Size = Vector3.new(4.2, 24, 4.2),
			CFrame = cf * CFrame.new(s * 9.6, 14.4, 0), Color = stone, Material = Enum.Material.Rock })
		part({ Name = "Capital", Parent = f, Size = Vector3.new(5.6, 1.8, 5.6),
			CFrame = cf * CFrame.new(s * 9.6, 27.2, 0), Color = zone.dirt or stone, Material = Enum.Material.Rock })
		part({ Name = "Foot", Parent = f, Size = Vector3.new(5.6, 1.6, 5.6),
			CFrame = cf * CFrame.new(s * 9.6, 3.2, 0), Color = zone.dirt or stone, Material = Enum.Material.Rock })
	end
	part({ Name = "Lintel", Parent = f, Size = Vector3.new(25, 3.6, 5),
		CFrame = cf * CFrame.new(0, 29.4, 0), Color = stone, Material = Enum.Material.Rock })
	part({ Name = "Keystone", Parent = f, Size = Vector3.new(4.6, 5, 5.6),
		CFrame = cf * CFrame.new(0, 31.4, 0), Color = zone.dirt or stone, Material = Enum.Material.Rock })

	-- The gateway itself. Dark until lit.
	local veil = part({ Name = "Veil", Parent = f, Size = Vector3.new(15.4, 24, 0.6),
		CFrame = cf * CFrame.new(0, 15, 0), Color = Color3.fromRGB(18, 18, 24),
		Material = Enum.Material.SmoothPlastic })
	veil.Transparency = 0.15
	veil.CanCollide = false

	-- Spun by the client, and only when the portal is open.
	-- A cylinder's flat faces are on its own X, so both discs are turned 90
	-- degrees about Y to stand them up facing out of the doorway.
	local face = CFrame.Angles(0, math.rad(90), 0)
	-- The glow behind the arms. Dim on its own; the arms are the read.
	local swirl = part({ Name = "Swirl", Parent = f, Size = Vector3.new(0.3, 13.4, 13.4),
		CFrame = cf * CFrame.new(0, 15, -0.25) * face,
		Color = col, Material = Enum.Material.Neon, Shape = Enum.PartType.Cylinder })
	swirl.Transparency = 1
	swirl.CanCollide = false

	-- Three spiral arms, each a chain of tapering bars sweeping out from the
	-- middle. Spinning a plain disc is invisible; spinning these is not.
	local ARMS, LINKS = 3, 9
	for arm = 0, ARMS - 1 do
		for i = 0, LINKS - 1 do
			local u = i / (LINKS - 1)
			local rad = 1.1 + u * 5.6
			local ang = math.rad(arm * (360 / ARMS)) + u * math.rad(150)
			local seg = part({ Name = "Arm", Parent = f,
				Size = Vector3.new(0.22, 1.5 - u * 0.7, 0.5 - u * 0.22),
				CFrame = cf * CFrame.new(0, 15, -0.45)
					* CFrame.Angles(0, 0, ang)
					* CFrame.new(0, rad, 0)
					* CFrame.Angles(0, 0, math.rad(38)),
				Color = col:Lerp(Color3.new(1, 1, 1), u * 0.5),
				Material = Enum.Material.Neon })
			seg.Transparency = 1
			seg.CanCollide = false
			seg:SetAttribute("Radius", rad)
			seg:SetAttribute("Ang", ang)
		end
	end
	local ring = part({ Name = "Ring", Parent = f, Size = Vector3.new(0.45, 17.5, 17.5),
		CFrame = cf * CFrame.new(0, 15, -0.62) * face,
		Color = col, Material = Enum.Material.Neon, Shape = Enum.PartType.Cylinder })
	ring.Transparency = 1
	ring.CanCollide = false
	-- A darker disc behind the ring turns it into an annulus rather than a
	-- filled dot, and gives the swirl something to read against.
	local iris = part({ Name = "Iris", Parent = f, Size = Vector3.new(0.3, 15.2, 15.2),
		CFrame = cf * CFrame.new(0, 15, -0.12) * face,
		Color = Color3.fromRGB(16, 14, 24), Material = Enum.Material.SmoothPlastic,
		Shape = Enum.PartType.Cylinder })
	iris.Transparency = 1
	iris.CanCollide = false
	-- Shards the client orbits once the gate is lit.
	for i = 0, 5 do
		local sh = part({ Name = "Shard", Parent = f, Size = Vector3.new(0.5, 1.9, 0.5),
			CFrame = cf * CFrame.new(0, 15, -0.9) * CFrame.Angles(0, 0, math.rad(i * 60))
				* CFrame.new(0, 10.8, 0),
			Color = col, Material = Enum.Material.Neon })
		sh.Transparency = 1
		sh.CanCollide = false
		sh:SetAttribute("Phase", i / 6)
	end

	local gl = Instance.new("PointLight")
	gl.Brightness = 0
	gl.Range = 46
	gl.Color = col
	gl.Enabled = false
	gl.Parent = veil

	-- Above the keystone (top at 33.9); level with it, the keystone hid the middle of the name.
	local plaque = part({ Name = "Plaque", Parent = f, Size = Vector3.new(23, 3.6, 0.4),
		CFrame = cf * CFrame.new(0, 36.2, -0.4), Color = DARK, Material = Enum.Material.SmoothPlastic })
	sign(plaque, string.upper(label or zone.name or zone.id), Enum.NormalId.Front)
	-- Big always-on-top destination tag so the gate is readable from across the pit.
	do
		local tagHost = part({
			Name = "DestTag",
			Parent = f,
			Size = Vector3.new(4, 0.4, 0.4),
			CFrame = cf * CFrame.new(0, 42, 0),
			Color = col,
			Material = Enum.Material.Neon,
			Transparency = 1,
			CanCollide = false,
		})
		local bb = Instance.new("BillboardGui")
		bb.Name = "DestBillboard"
		bb.Size = UDim2.fromOffset(360, 90)
		bb.StudsOffset = Vector3.new(0, 0, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 420
		bb.Parent = tagHost
		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Size = UDim2.new(1, 0, 0.55, 0)
		title.Font = Enum.Font.GothamBlack
		title.TextSize = 32
		title.TextColor3 = col
		title.TextStrokeTransparency = 0.2
		title.TextStrokeColor3 = Color3.fromRGB(8, 10, 14)
		title.Text = string.upper(label or zone.name or zone.id)
		title.Parent = bb
		local sub = Instance.new("TextLabel")
		sub.BackgroundTransparency = 1
		sub.Position = UDim2.new(0, 0, 0.55, 0)
		sub.Size = UDim2.new(1, 0, 0.45, 0)
		sub.Font = Enum.Font.GothamBold
		sub.TextSize = 18
		sub.TextColor3 = Color3.fromRGB(236, 232, 224)
		sub.TextStrokeTransparency = 0.35
		sub.Text = (destination == "lobby") and "RETURN" or "NEXT ZONE"
		sub.Parent = bb
	end

	-- Event Horizon: a live countdown clock above the plaque so the limited
	-- window is readable from the lobby without opening a menu.
	if zone.limited then
		local clockHost = part({
			Name = "EventClock",
			Parent = f,
			Size = Vector3.new(14, 0.4, 0.4),
			CFrame = cf * CFrame.new(0, 40.2, -0.4),
			Color = Color3.fromRGB(12, 10, 18),
			Material = Enum.Material.SmoothPlastic,
			Transparency = 1,
			CanCollide = false,
		})
		clockHost:SetAttribute("EventClock", true)
		local bb = Instance.new("BillboardGui")
		bb.Name = "EventCountdown"
		bb.Size = UDim2.fromOffset(280, 72)
		bb.StudsOffset = Vector3.new(0, 0, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 220
		bb.Parent = clockHost
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.Size = UDim2.new(1, 0, 0, 22)
		title.Font = Enum.Font.GothamBlack
		title.TextSize = 16
		title.TextColor3 = Color3.fromRGB(180, 210, 255)
		title.Text = "EVENT ENDS IN"
		title.Parent = bb
		local timer = Instance.new("TextLabel")
		timer.Name = "Timer"
		timer.BackgroundTransparency = 1
		timer.Position = UDim2.fromOffset(0, 24)
		timer.Size = UDim2.new(1, 0, 0, 42)
		timer.Font = Enum.Font.GothamBlack
		timer.TextSize = 28
		timer.TextColor3 = Color3.fromRGB(255, 230, 140)
		timer.Text = "--:--:--"
		timer.Parent = bb
	end

	local trigger = part({ Name = "Trigger", Parent = f, Size = Vector3.new(15, 22, 6),
		CFrame = cf * CFrame.new(0, 14, 0), Color = col, Material = Enum.Material.Neon })
	trigger.Transparency = 1
	trigger.CanCollide = false
	if destination == "lobby" then
		trigger:SetAttribute("Destination", "lobby")
		prompt(trigger, "Enter", "Back to the Lobby")
	elseif destination == "clouds" then
		trigger:SetAttribute("Destination", "clouds")
		prompt(trigger, "Enter", label or "The Clouds")
	else
		trigger:SetAttribute("ZoneId", zone.id)
		trigger:SetAttribute("Destination", zone.id)
		local needR = tonumber(zone.minRebirth or zone.prestige) or 0
		local cost = math.floor(tonumber(zone.buyCost) or 0)
		trigger:SetAttribute("Prestige", needR)
		trigger:SetAttribute("BuyCost", cost)
		local label = zone.name or zone.id
		if cost > 0 then
			label = string.format("%s  ·  %s gems", label, tostring(cost))
		end
		if needR > 0 then
			label = label .. "  ·  R" .. needR .. "+"
		end
		prompt(trigger, "Buy / Enter", label)
	end
	f:SetAttribute("ZoneId", destination == "lobby" and "lobby" or zone.id)
	local folderNeed = destination == "lobby" and 0 or (tonumber(zone.minRebirth or zone.prestige) or 0)
	f:SetAttribute("Prestige", folderNeed)
	return f
end

-- A small outpost beside a mine: somewhere to sell your haul and buy the
-- next tool without portalling home. The lobby keeps the full set of
-- services; an island only needs the two you use mid-run.
-- Mid-run SELL / STORE kiosks beside each mine approach.
-- Portal behind, pit ahead; twin booths face INWARD to the path (not the pit).
-- Kit matches lobby craft (timber, pitched canopy, hung signs) at island scale.
--[[
	ZONE OUTPOSTS.

	Every mine island has a square between where you arrive and the pit: a
	Depot that buys your haul and a Blacksmith that sells tools, the same two
	buildings as in the lobby so a player knows them on sight, painted in the
	zone's own colours.

	What this replaced were two open booths on a narrow path, sunk in a trench
	cut through terrain that stood three studs over them -- from the arrival
	point you saw the back of a portal, and past it two roofs.

	gotoStation relies on the names here: Outpost_<zone>/Shop_sell and
	Shop_shop, each with a Pad_<id>/Ring and a Counter. ShopFronts.build names
	them all that way.
]]
local OUTPOST_WALL = {
	meadow = Enum.Material.Brick, sunscar = Enum.Material.Sandstone, mistreef = Enum.Material.Slate,
	arcwork = Enum.Material.Metal, bloodmoon = Enum.Material.Slate, eclipse = Enum.Material.Basalt,
	riftmarch = Enum.Material.Rock, starfall = Enum.Material.CorrodedMetal, mythral = Enum.Material.Limestone,
	primordium = Enum.Material.Basalt, bigbang = Enum.Material.Marble,
}
local OUTPOST_PAVE = {
	meadow = Enum.Material.Cobblestone, sunscar = Enum.Material.Sandstone, mistreef = Enum.Material.Slate,
	arcwork = Enum.Material.DiamondPlate, bloodmoon = Enum.Material.Slate, eclipse = Enum.Material.Basalt,
	riftmarch = Enum.Material.Cobblestone, starfall = Enum.Material.Asphalt, mythral = Enum.Material.Marble,
	primordium = Enum.Material.Basalt, bigbang = Enum.Material.Marble,
}

-- Keep a colour readable. Several zones are near-black by design (Eclipse,
-- Primordium), and a black roof on black basalt is not a building.
local function lifted(c, floorV)
	local h, s, v = c:ToHSV()
	return Color3.fromHSV(h, s, math.max(v, floorV))
end

local function outpostPalette(zone)
	local col = zone.color or Color3.fromRGB(170, 150, 120)
	local dirt = zone.dirt or Color3.fromRGB(120, 100, 80)
	return {
		brick = lifted(dirt:Lerp(Color3.fromRGB(214, 206, 190), 0.45), 0.55),
		roof = lifted(col:Lerp(Color3.fromRGB(24, 20, 26), 0.3), 0.4),
		trim = lifted(TIMBER:Lerp(dirt, 0.25), 0.3),
		accent = lifted(col, 0.72),
		mat = OUTPOST_WALL[zone.id] or Enum.Material.Brick,
	}
end

function WorldBuilder.buildOutpost(parent, zone, origin, dir)
	local f = Instance.new("Folder")
	f.Name = "Outpost_" .. zone.id
	f.Parent = parent
	f:SetAttribute("ZoneId", zone.id)

	local pitW = MineConfig.GRID * MineConfig.BLOCK
	local hole = pitW * 0.5
	local O = Vector3.new(origin.X, GROUND, origin.Z)
	local back = -dir
	local side = Vector3.new(-dir.Z, 0, dir.X)
	local pal = outpostPalette(zone)
	local pave = OUTPOST_PAVE[zone.id] or Enum.Material.Cobblestone
	local stone = (zone.dirt or STONE):Lerp(Color3.fromRGB(156, 150, 140), 0.62)
	--[[
		The square's surface, above GROUND. Raised well clear on purpose: smooth
		terrain DRAWS its surface a little above where it collides, and big flat
		terrain is drawn as big triangles, so a pavement laid a few tenths over
		the ground z-fights with it -- half the square vanished under the sand
		along a clean diagonal. A stone platform a stud and a half up has the
		plane to itself.
	]]
	local TOP = 1.4

	-- A point `b` studs back from the pit centre and `l` studs to the side.
	local function at(b, l, y)
		return O + back * b + side * l + Vector3.new(0, y or 0, 0)
	end
	-- A frame at `p` whose front faces `toward`.
	local function facing(p, toward)
		return CFrame.lookAt(p, p + toward)
	end

	-- The square.
	local near, far, width = hole + 6, hole + 106, 142
	local depth = far - near
	local mid = at((near + far) * 0.5, 0, 0)
	local squareCf = facing(mid, dir)
	part({ Name = "Square", Parent = f, Size = Vector3.new(width, TOP, depth),
		CFrame = squareCf * CFrame.new(0, TOP * 0.5, 0), Color = stone, Material = pave })
	part({ Name = "SquareEdge", Parent = f, Size = Vector3.new(width + 3, TOP * 0.6, depth + 3),
		CFrame = squareCf * CFrame.new(0, TOP * 0.3, 0), Color = pal.trim, Material = Enum.Material.Slate })
	-- The walk in: a cobbled strip from the back of the square to the pit lip.
	part({ Name = "Path", Parent = f, Size = Vector3.new(12, 0.14, depth),
		CFrame = squareCf * CFrame.new(0, TOP + 0.07, 0), Color = PATH, Material = Enum.Material.Cobblestone })

	-- Depot and Blacksmith, facing each other across the path.
	local shopB, shopL = hole + 40, 38
	for _, spec in ipairs({
		{ l = -shopL, style = "depot", title = "Depot", verb = "SELL", npc = "Hodge",
			role = "Buys your haul", machine = "sell" },
		{ l = shopL, style = "forge", title = "Blacksmith", verb = "SHOP", npc = "Nan",
			role = "Tools and bags", machine = "shop" },
	}) do
		local pos = at(shopB, spec.l, TOP)
		local cf = CFrame.lookAt(pos, at(shopB, 0, TOP))
		part({ Name = "Apron", Parent = f, Size = Vector3.new(0.3, 44, 44),
			CFrame = CFrame.new(pos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = stone:Lerp(Color3.fromRGB(255, 255, 255), 0.12), Material = Enum.Material.Slate,
			Shape = Enum.PartType.Cylinder }).CanCollide = false
		ShopFronts.build(SHOP_KIT, f, cf, {
			style = spec.style, title = spec.title, verb = spec.verb, npc = spec.npc,
			role = spec.role, machine = spec.machine, pal = pal, locked = false,
		}, SHOP_W, SHOP_D, SHOP_H)

		-- Crates and barrels on the outside of each yard.
		local outer = spec.l + (spec.l < 0 and -17 or 17)
		for i, o in ipairs({ { -7, 0 }, { -3.4, 1.4 }, { 7.5, -1 } }) do
			local p = at(shopB + o[1], outer + o[2], TOP)
			if i == 3 then
				part({ Name = "Barrel", Parent = f, Size = Vector3.new(3.4, 2.6, 2.6),
					CFrame = CFrame.new(p + Vector3.new(0, 1.7, 0)) * CFrame.Angles(0, 0, math.rad(90)),
					Color = Color3.fromRGB(122, 86, 52), Material = Enum.Material.Wood,
					Shape = Enum.PartType.Cylinder })
			else
				part({ Name = "Crate", Parent = f, Size = Vector3.new(3.6, 3.2, 3.6),
					CFrame = CFrame.new(p + Vector3.new(0, 1.6 + (i - 1) * 3.2, 0)) * CFrame.Angles(0, math.rad(i * 17), 0),
					Color = Color3.fromRGB(132, 98, 62), Material = Enum.Material.WoodPlanks })
			end
		end
	end

	-- Lamp posts down both sides of the path.
	for _, b in ipairs({ hole + 14, hole + 64, hole + 98 }) do
		for _, s in ipairs({ -1, 1 }) do
			local p = at(b, s * 9, TOP)
			part({ Name = "LampPost", Parent = f, Size = Vector3.new(0.8, 11, 0.8),
				CFrame = CFrame.new(p + Vector3.new(0, 5.5, 0)), Color = Color3.fromRGB(46, 44, 50),
				Material = Enum.Material.Metal })
			part({ Name = "LampFoot", Parent = f, Size = Vector3.new(1.8, 0.8, 1.8),
				CFrame = CFrame.new(p + Vector3.new(0, 0.4, 0)), Color = Color3.fromRGB(58, 56, 62),
				Material = Enum.Material.Metal })
			local glow = part({ Name = "LampGlow", Parent = f, Size = Vector3.new(1.5, 1.7, 1.5),
				CFrame = CFrame.new(p + Vector3.new(0, 11.6, 0)), Color = LAMP, Material = Enum.Material.Neon })
			part({ Name = "LampCap", Parent = f, Size = Vector3.new(2.2, 0.5, 2.2),
				CFrame = CFrame.new(p + Vector3.new(0, 12.7, 0)), Color = Color3.fromRGB(46, 44, 50),
				Material = Enum.Material.Metal })
			local light = Instance.new("PointLight")
			light.Brightness = 1.3
			light.Range = 28
			light.Color = LAMP
			light.Parent = glow
		end
	end

	-- The zone's name over the path, framing the pit as you walk toward it.
	local archB = hole + 20
	for _, s in ipairs({ -1, 1 }) do
		part({ Name = "ArchPost", Parent = f, Size = Vector3.new(1.8, 15, 1.8),
			CFrame = CFrame.new(at(archB, s * 10, TOP + 7.5)), Color = pal.trim, Material = Enum.Material.WoodPlanks })
		part({ Name = "ArchFoot", Parent = f, Size = Vector3.new(3, 1.2, 3),
			CFrame = CFrame.new(at(archB, s * 10, TOP + 0.6)), Color = stone, Material = pave })
	end
	part({ Name = "ArchBeam", Parent = f, Size = Vector3.new(24, 1.6, 2),
		CFrame = facing(at(archB, 0, TOP + 15.4), dir), Color = pal.trim, Material = Enum.Material.WoodPlanks })
	local board = part({ Name = "ArchSign", Parent = f, Size = Vector3.new(18, 3.6, 0.5),
		CFrame = facing(at(archB + 0.4, 0, TOP + 12.6), back), Color = Color3.fromRGB(34, 32, 38),
		Material = Enum.Material.SmoothPlastic })
	sign(board, string.upper(zone.name or zone.id), Enum.NormalId.Front)
	part({ Name = "ArchSignFrame", Parent = f, Size = Vector3.new(19, 4.4, 0.3),
		CFrame = facing(at(archB + 0.1, 0, TOP + 12.6), back), Color = pal.accent, Material = Enum.Material.SmoothPlastic })

	-- Banners in the zone colour at the four corners of the square.
	for _, c in ipairs({ { near + 4, -1 }, { near + 4, 1 }, { far - 4, -1 }, { far - 4, 1 } }) do
		local p = at(c[1], c[2] * (width * 0.5 - 4), TOP)
		part({ Name = "BannerPole", Parent = f, Size = Vector3.new(0.7, 20, 0.7),
			CFrame = CFrame.new(p + Vector3.new(0, 10, 0)), Color = Color3.fromRGB(52, 50, 56), Material = Enum.Material.Metal })
		part({ Name = "BannerTop", Parent = f, Size = Vector3.new(1.3, 1.3, 1.3),
			CFrame = CFrame.new(p + Vector3.new(0, 20.4, 0)), Color = pal.accent, Material = Enum.Material.Neon })
		part({ Name = "Banner", Parent = f, Size = Vector3.new(4.4, 10, 0.2),
			CFrame = facing(p + Vector3.new(0, 14, 0) + side * (c[2] * -2.4), dir),
			Color = pal.accent, Material = Enum.Material.Fabric }).CanCollide = false
	end

	return f
end


function WorldBuilder.buildLeaderboards(lobby)
	local folder = Instance.new("Folder")
	folder.Name = "Leaderboards"
	folder.Parent = lobby
	-- Fame Court on the +Z approach: prestige + stardust only.
	local cols = {
		{ id = "prestige", title = "Prestige Leaderboard", x = -36, z = 112 },
		{ id = "dust", title = "Stardust Leaderboard", x = 36, z = 112 },
	}
	for _, col in ipairs(cols) do
		local cfolder = Instance.new("Folder")
		cfolder.Name = "Col_" .. col.id
		cfolder.Parent = folder
		-- Board faces fountain so SurfaceGui Front is readable from plaza
		local boardPos = Vector3.new(col.x, GROUND + 14, col.z)
		local boardCF = CFrame.lookAt(boardPos, Vector3.new(0, boardPos.Y, 0))
		local board = Instance.new("Part")
		board.Name = "Board"
		board.Anchored = true
		board.Size = Vector3.new(28, 36, 1.2)
		board.CFrame = boardCF
		board.Color = Color3.fromRGB(28, 26, 32)
		board.Material = Enum.Material.SmoothPlastic
		board.Parent = cfolder
		board:SetAttribute("BoardKind", col.id)
		local sg = Instance.new("SurfaceGui")
		sg.Name = "BoardGui"
		sg.Face = Enum.NormalId.Front
		sg.CanvasSize = Vector2.new(420, 560)
		sg.LightInfluence = 0
		sg.Parent = board
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, -8, 0, 40)
		title.Position = UDim2.fromOffset(4, 6)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.FredokaOne
		title.TextSize = 36
		title.TextColor3 = Color3.fromRGB(255, 210, 90)
		title.Text = (col.id == "dust") and "STARDUST" or "PRESTIGE"
		title.Parent = sg
		local sub = Instance.new("TextLabel")
		sub.Name = "Zone"
		sub.Size = UDim2.new(1, -8, 0, 22)
		sub.Position = UDim2.fromOffset(4, 44)
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.GothamBold
		sub.TextSize = 16
		sub.TextColor3 = Color3.fromRGB(200, 196, 210)
		sub.Text = (col.id == "dust") and "all-time stardust" or "all-time prestige"
		sub.Parent = sg
		local list = Instance.new("ScrollingFrame")
		list.Name = "RankList"
		list.BackgroundTransparency = 1
		list.Position = UDim2.fromOffset(10, 72)
		list.Size = UDim2.new(1, -20, 1, -132)
		list.ScrollBarThickness = 6
		list.CanvasSize = UDim2.new()
		list.AutomaticCanvasSize = Enum.AutomaticSize.Y
		list.Parent = sg
		local lay = Instance.new("UIListLayout")
		lay.Padding = UDim.new(0, 2)
		-- By rank, not by name: "Rank_10" sorts before "Rank_4" by name.
		lay.SortOrder = Enum.SortOrder.LayoutOrder
		lay.Parent = list
		local you = Instance.new("TextLabel")
		you.Name = "YouRow"
		you.Size = UDim2.new(1, -16, 0, 48)
		you.Position = UDim2.new(0, 8, 1, -56)
		you.BackgroundColor3 = Color3.fromRGB(60, 52, 40)
		you.Font = Enum.Font.GothamMedium
		you.TextSize = 16
		you.TextColor3 = Color3.fromRGB(255, 230, 180)
		you.Text = "Your rank  —"
		you.TextXAlignment = Enum.TextXAlignment.Left
		you.Parent = sg
		local yc = Instance.new("UICorner")
		yc.CornerRadius = UDim.new(0, 8)
		yc.Parent = you
		local yp = Instance.new("UIPadding")
		yp.PaddingLeft = UDim.new(0, 12)
		yp.Parent = you
		-- Top three as avatar icons on the board itself: #2 left, #1 centre
		-- (bigger), #3 right. These replaced the stone pedestals, whose stand-in
		-- dummies were never swapped for real avatars. LeaderboardService
		-- paints Slot_1..Slot_3.
		local top = Instance.new("Frame")
		top.Name = "Top3"
		top.BackgroundTransparency = 1
		top.Position = UDim2.fromOffset(8, 52)
		top.Size = UDim2.new(1, -16, 0, 132)
		top.Parent = sg
		for _, slot in ipairs({
			{ rank = 2, x = 0.18, size = 64 },
			{ rank = 1, x = 0.5, size = 84 },
			{ rank = 3, x = 0.82, size = 64 },
		}) do
			local holder = Instance.new("Frame")
			holder.Name = "Slot_" .. slot.rank
			holder.BackgroundTransparency = 1
			holder.AnchorPoint = Vector2.new(0.5, 0)
			holder.Position = UDim2.new(slot.x, 0, 0, slot.rank == 1 and 0 or 14)
			holder.Size = UDim2.fromOffset(128, 132)
			holder.Parent = top
			local icon = Instance.new("ImageLabel")
			icon.Name = "Icon"
			icon.BackgroundColor3 = Color3.fromRGB(66, 62, 74)
			icon.AnchorPoint = Vector2.new(0.5, 0)
			icon.Position = UDim2.new(0.5, 0, 0, 0)
			icon.Size = UDim2.fromOffset(slot.size, slot.size)
			icon.Parent = holder
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = icon
			local ring = Instance.new("UIStroke")
			ring.Thickness = 3
			ring.Color = Color3.fromRGB(240, 210, 140)
			ring.Parent = icon
			local badge = Instance.new("TextLabel")
			badge.Name = "Badge"
			badge.BackgroundColor3 = Color3.fromRGB(34, 30, 40)
			badge.AnchorPoint = Vector2.new(0.5, 0.5)
			badge.Position = UDim2.new(0.5, 0, 0, slot.size - 2)
			badge.Size = UDim2.fromOffset(26, 22)
			badge.Font = Enum.Font.FredokaOne
			badge.TextSize = 16
			badge.TextColor3 = Color3.fromRGB(255, 230, 170)
			badge.Text = "#" .. slot.rank
			badge.Parent = holder
			local bc = Instance.new("UICorner")
			bc.CornerRadius = UDim.new(0, 8)
			bc.Parent = badge
			local nameL = Instance.new("TextLabel")
			nameL.Name = "Name"
			nameL.BackgroundTransparency = 1
			nameL.Position = UDim2.fromOffset(0, slot.size + 12)
			nameL.Size = UDim2.new(1, 0, 0, 18)
			nameL.Font = Enum.Font.GothamBold
			nameL.TextSize = 14
			nameL.TextColor3 = Color3.fromRGB(240, 236, 228)
			nameL.TextTruncate = Enum.TextTruncate.AtEnd
			nameL.Text = "—"
			nameL.Parent = holder
			local valL = Instance.new("TextLabel")
			valL.Name = "Value"
			valL.BackgroundTransparency = 1
			valL.Position = UDim2.fromOffset(0, slot.size + 30)
			valL.Size = UDim2.new(1, 0, 0, 16)
			valL.Font = Enum.Font.GothamBold
			valL.TextSize = 13
			valL.TextColor3 = Color3.fromRGB(240, 210, 140)
			valL.Text = ""
			valL.Parent = holder
		end
	end
	return folder
end

function WorldBuilder.buildLobby(world)
	local lobby = Instance.new("Folder")
	lobby.Name = "Lobby"
	lobby.Parent = world
	local terrain = workspace.Terrain

	-- FLAT platform, not terrain. FillCylinder makes a rounded mound, so every
	-- building ended up on its own hill with its floor sunk into the next one.
	-- A hub needs one plane you can read across at a glance.
	local deck = part({ Name = "Deck", Parent = lobby, Size = Vector3.new(2, 270, 270),
		CFrame = CFrame.new(0, GROUND - 1, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(104, 162, 90), Material = Enum.Material.Grass,
		Shape = Enum.PartType.Cylinder })
	deck.TopSurface = Enum.SurfaceType.Smooth
	part({ Name = "DeckRim", Parent = lobby, Size = Vector3.new(2.6, 282, 282),
		CFrame = CFrame.new(0, GROUND - 2.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(76, 118, 66), Material = Enum.Material.Slate,
		Shape = Enum.PartType.Cylinder })
	part({ Name = "Court", Parent = lobby, Size = Vector3.new(0.6, 96, 96),
		CFrame = CFrame.new(0, GROUND + 0.02, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(122, 119, 111), Material = Enum.Material.Cobblestone,
		Shape = Enum.PartType.Cylinder })
	-- No terrain mounds: they were the hills the shops sank into.

	-- A stone fountain at lobby center: spawn ring faces this, and the road
	-- out to Dirt Meadow leaves from the +Z side.
	local fountain = Instance.new("Folder")
	fountain.Name = "Fountain"
	fountain.Parent = lobby
	part({ Name = "BasinOuter", Parent = fountain, Size = Vector3.new(2.2, 22, 22),
		CFrame = CFrame.new(0, GROUND + 1.0, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(148, 144, 136), Material = Enum.Material.Slate,
		Shape = Enum.PartType.Cylinder })
	part({ Name = "BasinInner", Parent = fountain, Size = Vector3.new(1.6, 18, 18),
		CFrame = CFrame.new(0, GROUND + 1.35, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(126, 122, 116), Material = Enum.Material.Concrete,
		Shape = Enum.PartType.Cylinder })
	local water = part({ Name = "Water", Parent = fountain, Size = Vector3.new(0.8, 16.5, 16.5),
		CFrame = CFrame.new(0, GROUND + 1.7, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(92, 158, 210), Material = Enum.Material.Glass,
		Shape = Enum.PartType.Cylinder })
	water.Transparency = 0.35
	water.CanCollide = false
	part({ Name = "Plinth", Parent = fountain, Size = Vector3.new(5.5, 3.2, 5.5),
		CFrame = CFrame.new(0, GROUND + 2.8, 0), Color = Color3.fromRGB(138, 134, 126),
		Material = Enum.Material.Slate })
	part({ Name = "Column", Parent = fountain, Size = Vector3.new(2.4, 7.5, 2.4),
		CFrame = CFrame.new(0, GROUND + 7.0, 0), Color = Color3.fromRGB(160, 156, 148),
		Material = Enum.Material.Marble })
	part({ Name = "Bowl", Parent = fountain, Size = Vector3.new(1.2, 9, 9),
		CFrame = CFrame.new(0, GROUND + 10.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(150, 146, 138), Material = Enum.Material.Slate,
		Shape = Enum.PartType.Cylinder })
	local spout = part({ Name = "SpoutWater", Parent = fountain, Size = Vector3.new(3.2, 2.2, 2.2),
		CFrame = CFrame.new(0, GROUND + 12.4, 0), Color = Color3.fromRGB(110, 180, 230),
		Material = Enum.Material.Glass })
	spout.Transparency = 0.25
	spout.CanCollide = false
	local center = part({ Name = "FountainCenter", Parent = fountain, Size = Vector3.new(1, 1, 1),
		CFrame = CFrame.new(0, GROUND + 6, 0), Color = Color3.fromRGB(120, 180, 220),
		Material = Enum.Material.Neon })
	center.Transparency = 1
	center.CanCollide = false
	center:SetAttribute("Fountain", true)
	local fl = Instance.new("PointLight")
	fl.Brightness = 1.1
	fl.Range = 70
	fl.Color = Color3.fromRGB(170, 210, 255)
	fl.Parent = spout

	-- Four spawn pads around the fountain. Server picks one on join/respawn;
	-- each faces the fountain center.
	local spawns = Instance.new("Folder")
	spawns.Name = "Spawns"
	spawns.Parent = lobby
	local ring = MineConfig.SPAWN_RING or 22
	for i, ang in ipairs({ 45, 135, 225, 315 }) do
		local rad = math.rad(ang)
		local pos = Vector3.new(math.sin(rad) * ring, GROUND + 1.2, math.cos(rad) * ring)
		local look = Vector3.new(0, pos.Y, 0)
		local sp = Instance.new("SpawnLocation")
		sp.Name = "Spawn_" .. i
		sp.Size = Vector3.new(6, 1, 6)
		sp.CFrame = CFrame.lookAt(pos, look)
		sp.Anchored = true
		sp.CanCollide = false
		sp.Neutral = true
		sp.Duration = 0
		sp.Transparency = 1
		sp.Enabled = true
		sp.Parent = spawns
	end

	-- Flat lobby deck. Stalls sit in the gaps between far zone bearings.
	-- Dirt Meadow (walk-to) owns the +Z corridor from the fountain.
	-- PLACEMENT RULE: nothing may stand within ISLAND + margin of a zone
	-- origin. Far islands live thousands of studs out; only Meadow is a walk.
	local STATIONS = {
		{ x = 53, z = 63, style = "depot", title = "Depot", verb = "SELL", npc = "Marla",
		  role = "Sells your haul", machine = "sell",
		  pal = { brick = Color3.fromRGB(168, 116, 76), roof = Color3.fromRGB(138, 76, 52), trim = TIMBER, accent = Color3.fromRGB(255, 200, 84), mat = Enum.Material.Brick } },
		{ x = 76, z = 40, style = "forge", title = "Blacksmith", verb = "FORGE", npc = "Bruk",
		  role = "Picks, drills, bags", machine = "shop",
		  pal = { brick = Color3.fromRGB(96, 92, 96), roof = Color3.fromRGB(58, 56, 64), trim = Color3.fromRGB(84, 62, 42), accent = Color3.fromRGB(255, 146, 62), mat = Enum.Material.Brick } },
		{ x = -70, z = -46, style = "spire", title = "Enchanter", verb = "RUNES", npc = "Sable",
		  role = "Runes, scrap, stardust shop", machine = "enchanter", locked = false,
		  pal = { brick = Color3.fromRGB(74, 70, 106), roof = Color3.fromRGB(46, 42, 72), trim = Color3.fromRGB(102, 94, 138), accent = Color3.fromRGB(154, 144, 226), mat = Enum.Material.Slate } },
		-- Moved off the west wall. It sat 36 studs from the Enchanter while the
		-- east-south arc was empty for 105 degrees, so two stations crowded each
		-- other and half the ring had nothing on it.
		{ x = 66, z = -30, style = "board", title = "Fossil Bench", verb = "FOSSIL", npc = "Ossie",
		  role = "Assemble fossil tools", machine = "fossil", locked = false,
		  pal = { brick = Color3.fromRGB(168, 140, 96), roof = Color3.fromRGB(110, 88, 58), trim = TIMBER, accent = Color3.fromRGB(210, 180, 120), mat = Enum.Material.Sandstone } },
		-- Job Board / Contractor: rotating contracts (was "coming soon" lean-to).
		{ x = -48, z = 68, style = "board", title = "Job Board", verb = "JOBS", npc = "Pike",
		  role = "Daily contracts", machine = "contractor", locked = false,
		  pal = { brick = Color3.fromRGB(128, 108, 78), roof = Color3.fromRGB(88, 70, 48), trim = TIMBER, accent = Color3.fromRGB(240, 196, 96), mat = Enum.Material.WoodPlanks } },
		{ x = -84, z = 40, style = "rotunda", title = "Cloud Gate", verb = "REBIRTH", npc = "Auria",
		  role = "Rebirth and skills", machine = "prestige",
		  pal = { brick = Color3.fromRGB(214, 210, 222), roof = Color3.fromRGB(180, 150, 96), trim = Color3.fromRGB(198, 166, 106), accent = Color3.fromRGB(255, 206, 128), mat = Enum.Material.Marble } },
	}
	for _, s in ipairs(STATIONS) do
		local pos = Vector3.new(s.x, GROUND, s.z)
		pathBetween(lobby, Vector3.new(0, 0, 0), pos, 13)
		part({ Name = "Apron", Parent = lobby, Size = Vector3.new(0.5, 46, 46),
			CFrame = CFrame.new(s.x, GROUND + 0.03, s.z) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(106, 103, 96), Material = Enum.Material.Slate,
			Shape = Enum.PartType.Cylinder }).CanCollide = false
		ShopFronts.build(SHOP_KIT, lobby, CFrame.lookAt(pos, Vector3.new(0, pos.Y, 0)),
			s, SHOP_W, SHOP_D, SHOP_H)
	end

	-- No portals here. Each zone carries the doorway to the NEXT one, so you
	-- find them by playing rather than reading a row of five arches on the lawn.

	-- Road out toward Dirt Meadow (zone radius 420 on +Z).
	-- Fame Court: prestige + stardust. Pedestals face the fountain.
	WorldBuilder.buildLeaderboards(lobby)
	do
		local meadow = MineConfig.ZONES and MineConfig.ZONES[1]
		local origin = meadow and MineConfig.zoneOrigin(meadow) or Vector3.new(0, 4, 200)
		local pitW = (MineConfig.GRID or 21) * (MineConfig.BLOCK or 5)
		pathBetween(lobby, Vector3.new(0, 0, 0), Vector3.new(0, 0, origin.Z - pitW * 0.5), 18)
	end
	return lobby
end

-- The Clouds. Rebirth used to drop you back on the lobby deck, which made the
-- one moment the game asks you to stop and re-plan feel like a respawn. This is
-- somewhere else: a drift of cloud islands above the map, with the gate you came
-- through in the middle. You leave it by choosing to.
local CLOUD_Y = 420

local function buildClouds(parent)
	local f = Instance.new("Folder")
	f.Name = "Clouds"
	f.Parent = parent
	local WHITE = Color3.fromRGB(244, 246, 252)
	local SHADE = Color3.fromRGB(214, 222, 238)

	-- A main deck you land on, built from overlapping puffs so the rim is soft
	-- rather than a disc with an edge.
	local rng = Random.new(11)
	for i = 1, 26 do
		local a = (i / 26) * math.pi * 2
		local r = (i % 3 == 0) and 15 or 22
		local d = 8 + rng:NextNumber() * 5
		part({ Name = "Puff", Parent = f, Shape = Enum.PartType.Ball,
			Size = Vector3.new(d, d * 0.62, d),
			CFrame = CFrame.new(math.cos(a) * r, CLOUD_Y - 3 + rng:NextNumber() * 2, math.sin(a) * r),
			Color = (i % 4 == 0) and SHADE or WHITE, Material = Enum.Material.SmoothPlastic })
	end
	part({ Name = "Deck", Parent = f, Size = Vector3.new(54, 2, 54),
		CFrame = CFrame.new(0, CLOUD_Y - 1, 0), Color = WHITE,
		Material = Enum.Material.SmoothPlastic })

	-- Outlying islands, purely so the place has a horizon.
	for i = 1, 7 do
		local a = rng:NextNumber() * math.pi * 2
		local r = 70 + rng:NextNumber() * 90
		local d = 14 + rng:NextNumber() * 16
		part({ Name = "Isle", Parent = f, Shape = Enum.PartType.Ball,
			Size = Vector3.new(d, d * 0.5, d),
			CFrame = CFrame.new(math.cos(a) * r, CLOUD_Y - 20 + rng:NextNumber() * 46, math.sin(a) * r),
			Color = WHITE, Material = Enum.Material.SmoothPlastic }).CanCollide = false
	end

	-- The gate itself, so the space reads as the Cloud Gate's other side.
	for _, x in ipairs({ -7, 7 }) do
		part({ Name = "GatePost", Parent = f, Size = Vector3.new(1.6, 18, 1.6),
			CFrame = CFrame.new(x, CLOUD_Y + 9, -12), Color = Color3.fromRGB(226, 214, 176),
			Material = Enum.Material.Marble })
	end
	part({ Name = "GateArch", Parent = f, Size = Vector3.new(17, 1.8, 2.2),
		CFrame = CFrame.new(0, CLOUD_Y + 18, -12), Color = Color3.fromRGB(226, 214, 176),
		Material = Enum.Material.Marble })
	local glow = part({ Name = "GateLight", Parent = f, Size = Vector3.new(13, 15, 0.4),
		CFrame = CFrame.new(0, CLOUD_Y + 9, -12), Color = Color3.fromRGB(180, 214, 255),
		Material = Enum.Material.Neon })
	glow.Transparency = 0.55
	glow.CanCollide = false
	local pl = Instance.new("PointLight")
	pl.Brightness = 3
	pl.Range = 60
	pl.Color = Color3.fromRGB(200, 224, 255)
	pl.Parent = glow

	sign(part({ Name = "Plaque", Parent = f, Size = Vector3.new(14, 3, 0.4),
		CFrame = CFrame.new(0, CLOUD_Y + 22, -12), Color = Color3.fromRGB(58, 62, 88),
		Material = Enum.Material.SmoothPlastic }), "THE CLOUDS", Enum.NormalId.Front)
	return f
end

WorldBuilder.CLOUD_Y = CLOUD_Y

--[[
	Terrain.Decoration grows animated grass on the Grass material: waist-high
	blades that stab straight up through any paving laid on the meadow, and a
	script cannot switch it off (the pcall in applyLighting never lands). So
	under everything built at ground level the grass becomes LeafyGrass, which
	is the same green with no blades. Open meadow keeps its grass.

	Footprints go onto the 4-stud voxel grid, a couple of studs wider than the
	part so blades rooted at the edge lean over it instead of through it.
	Upright discs (the lobby deck, shop aprons) are marked as discs, so a round
	floor does not mow a square out of the field around it.
]]
local MOW_MARGIN = 2
local function mowUnder(terrain, ...)
	local rows = {}
	for i = 1, select("#", ...) do
		local folder = select(i, ...)
		for _, d in ipairs(folder and folder:GetDescendants() or {}) do
			if d:IsA("BasePart") and d.Transparency < 1 then
				local cf, h = d.CFrame, d.Size * 0.5
				local ext = Vector3.new(
					math.abs(cf.XVector.X) * h.X + math.abs(cf.YVector.X) * h.Y + math.abs(cf.ZVector.X) * h.Z,
					math.abs(cf.XVector.Y) * h.X + math.abs(cf.YVector.Y) * h.Y + math.abs(cf.ZVector.Y) * h.Z,
					math.abs(cf.XVector.Z) * h.X + math.abs(cf.YVector.Z) * h.Y + math.abs(cf.ZVector.Z) * h.Z)
				local p = cf.Position
				local top = p.Y + ext.Y
				-- Only things low enough for a blade to reach through. Walls and
				-- posts are solid all the way up, so grass inside them is hidden.
				if top >= GROUND - 1 and top <= GROUND + 4.5 then
					local disc = d:IsA("Part") and d.Shape == Enum.PartType.Cylinder and math.abs(cf.XVector.Y) > 0.9
					local reach = disc and (math.min(d.Size.Y, d.Size.Z) * 0.5 + MOW_MARGIN) or 0
					for cz = math.floor((p.Z - ext.Z - MOW_MARGIN) / 4), math.floor((p.Z + ext.Z + MOW_MARGIN) / 4) do
						local row = rows[cz] or {}
						rows[cz] = row
						for cx = math.floor((p.X - ext.X - MOW_MARGIN) / 4), math.floor((p.X + ext.X + MOW_MARGIN) / 4) do
							if disc then
								local nx = math.clamp(p.X, cx * 4, cx * 4 + 4) - p.X
								local nz = math.clamp(p.Z, cz * 4, cz * 4 + 4) - p.Z
								if nx * nx + nz * nz <= reach * reach then
									row[cx] = true
								end
							else
								row[cx] = true
							end
						end
					end
				end
			end
		end
	end
	-- One ReplaceMaterial per unbroken run of cells along each row.
	for cz, row in pairs(rows) do
		local xs = {}
		for cx in pairs(row) do
			xs[#xs + 1] = cx
		end
		table.sort(xs)
		local a = 1
		while a <= #xs do
			local b = a
			while b < #xs and xs[b + 1] == xs[b] + 1 do
				b += 1
			end
			terrain:ReplaceMaterial(Region3.new(Vector3.new(xs[a] * 4, -8, cz * 4), Vector3.new((xs[b] + 1) * 4, 32, (cz + 1) * 4)),
				4, Enum.Material.Grass, Enum.Material.LeafyGrass)
			a = b + 1
		end
	end
end

function WorldBuilder.build()
	local old = workspace:FindFirstChild("MineWorld")
	if old then old:Destroy() end
	table.clear(usedTops) -- world rebuilt, so the ledger starts clean
	local world = Instance.new("Folder")
	world.Name = "MineWorld"
	world.Parent = workspace
	buildClouds(world)

	local base = workspace:FindFirstChild("Baseplate")
	if base and base:IsA("BasePart") then
		base.Transparency = 1
		base.CanCollide = false
	end

	-- Lobby Spawns folder owns join/respawn. Disable any leftover workspace pad.
	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawn and spawn.Parent == workspace then
		spawn.Enabled = false
		spawn.Transparency = 1
		spawn.Duration = 0
	end

	applyLighting()

	local terrain = workspace.Terrain
	terrain:Clear()
	-- Lobby stays plate-based; each mine gets themed terrain walls around it.

	local camp = Instance.new("Folder")
	camp.Name = "Camp"
	camp.Parent = world

	part({ Name = "Plaza", Parent = camp, Size = Vector3.new(42, 1.2, 42), CFrame = CFrame.new(0, 3.4, 0), Color = Color3.fromRGB(128, 122, 112), Material = Enum.Material.Cobblestone })
	part({ Name = "PlazaRing", Parent = camp, Size = Vector3.new(48, 0.8, 48), CFrame = CFrame.new(0, 2.8, 0), Color = STONE, Material = Enum.Material.Slate })

	-- AFK chill: private elevated lounge (teleport-only). Sealed room so AFK
	-- miners are out of the lobby and not on display.
	do
		local chill = Instance.new("Folder")
		chill.Name = "AfkChill"
		chill.Parent = world
		local padPos = MineConfig.AFK_PAD or Vector3.new(-260, 72, -300)
		local y = padPos.Y
		local wallH = 14
		local floorSize = 22
		local thick = 1.2
		local wood = Color3.fromRGB(58, 44, 34)
		local stone = Color3.fromRGB(42, 46, 56)
		local moss = Color3.fromRGB(72, 88, 70)

		part({
			Name = "Deck",
			Parent = chill,
			Size = Vector3.new(floorSize, thick, floorSize),
			CFrame = CFrame.new(padPos.X, y, padPos.Z),
			Color = moss,
			Material = Enum.Material.Slate,
		})
		-- Four sealed walls (no doorway — only reachable via AFK teleport).
		part({
			Name = "WallN",
			Parent = chill,
			Size = Vector3.new(floorSize + thick * 2, wallH, thick),
			CFrame = CFrame.new(padPos.X, y + wallH * 0.5, padPos.Z - floorSize * 0.5),
			Color = stone,
			Material = Enum.Material.Rock,
		})
		part({
			Name = "WallS",
			Parent = chill,
			Size = Vector3.new(floorSize + thick * 2, wallH, thick),
			CFrame = CFrame.new(padPos.X, y + wallH * 0.5, padPos.Z + floorSize * 0.5),
			Color = stone,
			Material = Enum.Material.Rock,
		})
		part({
			Name = "WallW",
			Parent = chill,
			Size = Vector3.new(thick, wallH, floorSize),
			CFrame = CFrame.new(padPos.X - floorSize * 0.5, y + wallH * 0.5, padPos.Z),
			Color = stone,
			Material = Enum.Material.Rock,
		})
		part({
			Name = "WallE",
			Parent = chill,
			Size = Vector3.new(thick, wallH, floorSize),
			CFrame = CFrame.new(padPos.X + floorSize * 0.5, y + wallH * 0.5, padPos.Z),
			Color = stone,
			Material = Enum.Material.Rock,
		})
		part({
			Name = "Roof",
			Parent = chill,
			Size = Vector3.new(floorSize + thick * 2, thick, floorSize + thick * 2),
			CFrame = CFrame.new(padPos.X, y + wallH, padPos.Z),
			Color = wood,
			Material = Enum.Material.WoodPlanks,
		})
		-- Soft interior lamp (not a sky billboard).
		local lamp = part({
			Name = "Lamp",
			Parent = chill,
			Size = Vector3.new(2, 0.6, 2),
			CFrame = CFrame.new(padPos.X, y + wallH - 1.2, padPos.Z),
			Color = Color3.fromRGB(255, 220, 160),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		do
			local light = Instance.new("PointLight")
			light.Brightness = 1.2
			light.Range = 28
			light.Color = Color3.fromRGB(255, 230, 190)
			light.Parent = lamp
		end

		local spawn = part({
			Name = "Spawn",
			Parent = chill,
			Size = Vector3.new(4, 1, 4),
			CFrame = CFrame.new(padPos.X, y + 2.2, padPos.Z - 3),
			Transparency = 1,
			CanCollide = false,
		})
		spawn:SetAttribute("AfkPad", true)

		local blkSize = MineConfig.BLOCK or 4
		local blk = part({
			Name = "MineBlock",
			Parent = chill,
			Size = Vector3.new(blkSize, blkSize, blkSize),
			CFrame = CFrame.new(padPos.X, y + thick * 0.5 + blkSize * 0.5, padPos.Z + 4),
			Color = Color3.fromRGB(150, 110, 72),
			Material = Enum.Material.Ground,
		})
		blk:SetAttribute("AfkBlock", true)
		blk:SetAttribute("Kind", "dirt")
		blk:SetAttribute("HP", 30)
		blk:SetAttribute("MaxHP", 30)
		blk:SetAttribute("ZoneId", "meadow")
		local bb = Instance.new("BillboardGui")
		bb.Name = "AfkLabel"
		bb.Size = UDim2.fromOffset(140, 36)
		bb.StudsOffset = Vector3.new(0, blkSize * 0.65, 0)
		bb.AlwaysOnTop = false -- keep private; don't advertise across the map
		bb.MaxDistance = 40
		bb.Parent = blk
		local lab = Instance.new("TextLabel")
		lab.BackgroundTransparency = 1
		lab.Size = UDim2.fromScale(1, 1)
		lab.Font = Enum.Font.GothamBlack
		lab.TextSize = 15
		lab.TextColor3 = Color3.fromRGB(200, 255, 170)
		lab.Text = "CHILL BLOCK"
		lab.Parent = bb
	end

	-- Six market stalls became nine shopfronts with people and glowing pads.
	WorldBuilder.buildLobby(world)

	-- Event Horizon's door from the lobby, on the open west side of the deck.
	-- Free: enterZone claims the limited zone for anyone while the event runs,
	-- and MinePortalFX lights it for the same window.
	do
		local eh = MineConfig.zoneById and MineConfig.zoneById("bigbang")
		local lobbyFolder = world:FindFirstChild("Lobby")
		if eh and lobbyFolder then
			local door = portal(lobbyFolder, Vector3.new(-112, GROUND, 0), eh, Vector3.new(0, GROUND, 0), "Event Horizon")
			local trigger = door:FindFirstChild("Trigger")
			local pr = trigger and trigger:FindFirstChildOfClass("ProximityPrompt")
			if pr then
				pr.ObjectText = "Event Horizon  ·  free while the event runs"
			end
			if THEMES.bigbang and THEMES.bigbang.dressPortal then
				pcall(THEMES.bigbang.dressPortal, THEME_KIT, door, eh)
			end
		end
	end

	local gates = Instance.new("Folder")
	gates.Name = "Gates"
	gates.Parent = world
	local pits = Instance.new("Folder")
	pits.Name = "Pits"
	pits.Parent = world

	local pitW = MineConfig.GRID * MineConfig.BLOCK

	for zoneIndex, zone in ipairs(MineConfig.ZONES) do
		local origin = MineConfig.zoneOrigin(zone)
		local folder = Instance.new("Folder")
		folder.Name = "Biome_" .. zone.id
		folder.Parent = world

		local flat = Vector3.new(origin.X, 0, origin.Z)
		local theme = THEMES[zone.id]
		if theme then
			local tdir = flat.Magnitude > 1 and flat.Unit or Vector3.new(0, 0, 1)
			local taxis = (math.abs(tdir.X) > math.abs(tdir.Z))
				and Vector3.new(math.sign(tdir.X), 0, 0) or Vector3.new(0, 0, (tdir.Z < 0) and -1 or 1)
			local ok, err = pcall(function()
				theme.terrain(THEME_KIT, terrain, zone, origin, taxis)
				theme.outpost(THEME_KIT, folder, zone, origin, taxis)
			end)
			if not ok then
				warn("[Mine] " .. zone.id .. " theme failed, building the standard island: " .. tostring(err))
				for _, child in ipairs(folder:GetChildren()) do
					child:Destroy()
				end
				theme = nil
			end
		end
		-- Plastic plate, not terrain: four slabs forming a frame around the pit
		-- mouth. Terrain gave lumpy hills, buried blocks, and grass blades taller
		-- than the buildings.
		local ISL = tonumber(zone.island) or MineConfig.ISLAND
		local hole = pitW * 0.5
		local arm = (ISL - hole) * 0.5
		for _, s in ipairs(theme and {} or {
			{ Vector3.new(0, 0, hole + arm), Vector3.new(ISL * 2, 2, arm * 2) },
			{ Vector3.new(0, 0, -(hole + arm)), Vector3.new(ISL * 2, 2, arm * 2) },
			{ Vector3.new(hole + arm, 0, 0), Vector3.new(arm * 2, 2, hole * 2) },
			{ Vector3.new(-(hole + arm), 0, 0), Vector3.new(arm * 2, 2, hole * 2) },
		}) do
			local plate = part({ Name = "Ground_" .. zone.id, Parent = folder, Size = s[2],
				CFrame = CFrame.new(origin + s[1] + Vector3.new(0, 0, 0)),
				Color = zone.dirt or Color3.fromRGB(120, 170, 110),
				Material = (zoneIndex == 1 and Enum.Material.Grass) or (zone.ground or Enum.Material.Grass) })
			-- The terrain is the ground you see; this plate is the exact flat
			-- surface you stand on. Both visible, they share a plane and flicker.
			plate.Transparency = 1
			plate.CastShadow = false
		end
		-- A stone lip round the pit mouth. Terrain is carved just past the mouth
		-- and this covers the seam, so the mine's edge is a clean square rather
		-- than a line of 4-stud voxels.
		do
			local lipW = 6
			local lipCol = (zone.dirt or STONE):Lerp(Color3.fromRGB(62, 58, 56), 0.45)
			for _, l in ipairs(theme and {} or {
				{ Vector3.new(0, 0, hole + lipW / 2), Vector3.new(pitW + lipW * 2, 4.2, lipW) },
				{ Vector3.new(0, 0, -(hole + lipW / 2)), Vector3.new(pitW + lipW * 2, 4.2, lipW) },
				{ Vector3.new(hole + lipW / 2, 0, 0), Vector3.new(lipW, 4.2, pitW) },
				{ Vector3.new(-(hole + lipW / 2), 0, 0), Vector3.new(lipW, 4.2, pitW) },
			}) do
				-- Top at GROUND + 1.6: a hair over the outpost square, well clear of
				-- the drawn terrain surface for the same reason the square is raised.
				-- Bottom below the shaft walls' tops, so from inside the pit the lip
				-- hides the terrain cut behind it (a strip of grass inside a mine).
				part({ Name = "PitLip_" .. zone.id, Parent = folder, Size = l[2],
					CFrame = CFrame.new(origin.X + l[1].X, GROUND - 0.5, origin.Z + l[1].Z),
					Color = lipCol, Material = Enum.Material.Slate })
			end
		end

		-- Walk-to zones get a road and a gate. Portal islands do not: at 1,400
		-- studs out, a road from the lobby is a path to nowhere.
		-- Only Dirt Meadow stays a walk from the lobby; far islands are portals.
		local walkTo = flat.Magnitude < (MineConfig.WALK_TO_MAX or 800)
		if walkTo then
			local mid = flat * 0.52
			local pathCf = CFrame.lookAt(Vector3.new(mid.X, 0, mid.Z), Vector3.new(origin.X, 0, origin.Z))
			part({ Name = "Road_" .. zone.id, Parent = folder,
				-- Top at GROUND + 1.4, clear of the drawn terrain (it had been buried outright).
				Size = Vector3.new(16, 1, flat.Magnitude * 0.46), CFrame = pathCf * CFrame.new(0, GROUND + 0.9, 0),
				Color = Color3.fromRGB(142, 138, 128), Material = Enum.Material.Cobblestone })
			-- The lobby end starts on the deck, a stone step up from it. Ramp onto it.
			local ramp = Instance.new("WedgePart")
			ramp.Name = "RoadRamp_" .. zone.id
			ramp.Anchored = true
			ramp.Material = Enum.Material.Cobblestone
			ramp.Color = Color3.fromRGB(142, 138, 128)
			ramp.TopSurface = Enum.SurfaceType.Smooth
			ramp.BottomSurface = Enum.SurfaceType.Smooth
			ramp.Size = Vector3.new(16, 1.4, 10)
			-- A wedge is tall at its local +Z; turned round, that end meets the road.
			ramp.CFrame = pathCf * CFrame.new(0, GROUND + 0.7, flat.Magnitude * 0.23 + 5) * CFrame.Angles(0, math.pi, 0)
			ramp.Parent = folder
		end
		-- Terrain hills / mountain walls around the plate so it does not float in a void.
		local dir = flat.Magnitude > 1 and flat.Unit or Vector3.new(0, 0, 1)
		-- The outpost, stand and portals line up with the PIT, which is square
		-- to the world axes, so they use the axis nearest `dir`. Laid along the
		-- true bearing they sat at an angle to the pit edge on every island.
		local axis = (math.abs(dir.X) > math.abs(dir.Z))
			and Vector3.new(math.sign(dir.X), 0, 0) or Vector3.new(0, 0, (dir.Z < 0) and -1 or 1)
		local groundMat, wallMat
		if not theme then
			groundMat, wallMat = themeRimTerrain(terrain, zone, origin, zoneIndex, axis, walkTo)
			decorate(folder, zone, origin, axis)
			-- Depot, Blacksmith and the square they stand on.
			WorldBuilder.buildOutpost(folder, zone, origin, axis)
		end
		-- Portal behind the approach; spawn faces the mine straight ahead.
		-- Next-zone portal at the FAR rim (across the pit from camp), facing the
		-- digger — same side as the depth board, so "where to go next" is the
		-- thing you look at while you dig. Return-to-camp stays behind the square.
		local side = Vector3.new(-axis.Z, 0, axis.X)
		local square = Vector3.new(origin.X, GROUND + 1.4, origin.Z) -- on the outpost square
		local nextZone = MineConfig.ZONES[zoneIndex + 1]
		local builtPortals = {} -- for a theme to dress
		if nextZone then
			-- Depth board is ~40 wide on this same far rim. Sit the gate beside
			-- and a few steps behind it so the portal is not inside the board.
			local farPos = square + axis * (hole + 38) + side * 58
			local nextPortal = portal(folder, farPos, nextZone, square)
			table.insert(builtPortals, nextPortal)
		end
		if not walkTo then
			table.insert(builtPortals, portal(folder, square - axis * (hole + 90) - side * 44, zone, square, "Lobby", "lobby"))
		end
		-- Dress each portal for its DESTINATION, not the biome it sits in.
		for _, pf in ipairs(builtPortals) do
			local destId = pf.Name:match("^Portal_(.+)$")
			if destId and destId ~= "lobby" and destId ~= "clouds" then
				local destZone = MineConfig.zoneById and MineConfig.zoneById(destId)
				local destTheme = THEMES[destId]
				if destTheme and destTheme.dressPortal and destZone then
					local ok, err = pcall(destTheme.dressPortal, THEME_KIT, pf, destZone)
					if not ok then
						warn("[Mine] portal dressing failed on " .. tostring(destId) .. ": " .. tostring(err))
					end
				end
			end
		end
		if walkTo then
			local gatePos = Vector3.new(origin.X, 8, origin.Z) - dir * ((tonumber(zone.island) or MineConfig.ISLAND) - 8)
			arch(gates, gatePos, zone, true)
		end

		local stand = Instance.new("Part")
		stand.Name = "Stand_" .. zone.id
		stand.Anchored = true
		stand.Transparency = 1
		stand.CanCollide = false
		stand.Size = Vector3.new(4, 1, 4)
		-- On the pathway, looking straight at the pit mouth.
		stand.CFrame = CFrame.new(
			origin - axis * (hole + 48) + Vector3.new(0, GROUND + 3, 0),
			origin + Vector3.new(0, GROUND + 3, 0)
		)
		stand.Parent = pits
		stand:SetAttribute("ZoneId", zone.id)

		local shaftPad = (MineConfig.LAYER_WINDOW or 8) * MineConfig.BLOCK
		-- No PitFloor: falling below the generated shaft sends you to the surface
		-- (MineServer), instead of landing on a platform at max depth.

		-- Shaft walls line the INSIDE of the mouth. Centering them on the hole
		-- edge buried half their thickness in Ground_* rim plates and left
		-- coplanar vertical faces at the cut — brown rock flickering through tan
		-- dirt. Keep them fully inside; tops sit below the ground underside.
		-- MineServer.syncPitWalls grows height the same way as layers open.
		local wallH = shaftPad + 8
		local wallT = 4
		-- Ground plates are 2 studs thick, centered at origin.Y (= GROUND - 1).
		local wallTop = GROUND - 2.05
		local wallY = wallTop - wallH * 0.5
		local inset = (pitW - wallT) * 0.5
		local rock = (zone.dirt or Color3.fromRGB(96, 90, 84)):Lerp(Color3.fromRGB(24, 22, 26), 0.55)
		for _, w in ipairs({
			{ "N", Vector3.new(pitW, wallH, wallT), Vector3.new(0, 0, inset) },
			{ "S", Vector3.new(pitW, wallH, wallT), Vector3.new(0, 0, -inset) },
			{ "E", Vector3.new(wallT, wallH, pitW - wallT * 2), Vector3.new(inset, 0, 0) },
			{ "W", Vector3.new(wallT, wallH, pitW - wallT * 2), Vector3.new(-inset, 0, 0) },
		}) do
			part({ Name = "PitWall" .. w[1] .. "_" .. zone.id, Parent = pits, Size = w[2],
				CFrame = CFrame.new(origin.X + w[3].X, wallY, origin.Z + w[3].Z),
				Color = rock, Material = Enum.Material.Rock })
		end

		-- Last, once the square, road, lip and portals all exist to be mown under.
		if groundMat == Enum.Material.Grass or wallMat == Enum.Material.Grass then
			mowUnder(terrain, folder)
		end
	end

	-- Dirt Meadow's ground reaches in under the south edge of the lobby deck,
	-- where it drew through the deck and grew blades up out of it. The lobby is
	-- plate-based by design, so the deck gets its whole footprint back.
	local lobby = world:FindFirstChild("Lobby")
	local rim = lobby and lobby:FindFirstChild("DeckRim")
	if rim then
		terrain:FillCylinder(CFrame.new(rim.Position.X, GROUND, rim.Position.Z), 60,
			math.max(rim.Size.Y, rim.Size.Z) * 0.5, Enum.Material.Air)
	end
	mowUnder(terrain, lobby, world:FindFirstChild("Camp"), gates)

	print("[Mine] terrain biomes built")
	return world
end

return WorldBuilder
