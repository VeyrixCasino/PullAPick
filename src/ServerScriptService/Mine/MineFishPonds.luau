--[[
	MineFishPonds -- builds a fishing spot (TODO A3): a stone-rimmed pool, a
	plank pier, and the DOCK at the pier's end that MineFishingService checks
	your distance from. The dock carries:
	  tag MineFishSpot, attributes SpotId and Machine = "fish", and the
	  ProximityPrompt that MineServer's bindPrompt routes to Verbs.Fish.prompt.

	Used by WorldBuilder (the surface pond on a zone's outpost square) and by
	MineDepthPlazas (the station bays of the 1,000 and 3,000 outposts). The
	spots themselves are listed in MineFishing.SPOTS.

	build(parent, spot, cf, size, look)
	  cf    the pool's centre at FLOOR level; its LookVector points from the
	        pier out over the water (the way you face when you fish)
	  size  Vector2: X across, Y along the look (pier to far rim)
	  look  optional { rim = Color3, water = Color3, deep = Color3, light = bool }
]]
local CollectionService = game:GetService("CollectionService")

local P = {}
P.TAG = "MineFishSpot"

local function part(parent, name, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props or {}) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

function P.build(parent, spot, cf, size, look)
	look = look or {}
	local f = Instance.new("Model")
	f.Name = "FishSpot_" .. spot.id
	f.Parent = parent
	local w, d = size.X, size.Y
	local rimH, rimT = 2.2, 2
	local rim = look.rim or Color3.fromRGB(128, 124, 116)
	local water = look.water or Color3.fromRGB(52, 118, 136)
	local deep = look.deep or Color3.fromRGB(22, 44, 52)
	local wood = Color3.fromRGB(120, 86, 54)

	-- The pool: a dark bed, the water a little under the rim, four rim walls.
	part(f, "PondBed", Vector3.new(w, 0.4, d), cf * CFrame.new(0, 0.2, 0), deep, Enum.Material.Slate)
	part(f, "PondWater", Vector3.new(w, 1, d), cf * CFrame.new(0, rimH - 0.9, 0), water, Enum.Material.Glass,
		{ Transparency = 0.22, Reflectance = 0.18, CanCollide = false, CastShadow = false })
	for _, side in ipairs({
		{ "RimFar", Vector3.new(w + rimT * 2, rimH, rimT), CFrame.new(0, rimH * 0.5, -(d + rimT) * 0.5) },
		{ "RimNear", Vector3.new(w + rimT * 2, rimH, rimT), CFrame.new(0, rimH * 0.5, (d + rimT) * 0.5) },
		{ "RimLeft", Vector3.new(rimT, rimH, d), CFrame.new(-(w + rimT) * 0.5, rimH * 0.5, 0) },
		{ "RimRight", Vector3.new(rimT, rimH, d), CFrame.new((w + rimT) * 0.5, rimH * 0.5, 0) },
	}) do
		part(f, side[1], side[2], cf * side[3], rim, Enum.Material.Cobblestone)
	end
	-- A few stones in the water so it reads as a quarry cut, not a bath.
	local rng = Random.new(#spot.id * 131 + 7)
	for i = 1, 4 do
		local s = 1.6 + rng:NextNumber() * 2.2
		part(f, "Stone", Vector3.new(s, s * 0.8, s * 1.1),
			cf * CFrame.new((rng:NextNumber() - 0.5) * (w - 6), rimH - 1.1, -(rng:NextNumber() * 0.6 + 0.1) * d * 0.5)
				* CFrame.Angles(0, rng:NextNumber() * 6, 0.3),
			rim:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.Rock)
	end

	-- The pier: from outside the near rim, a third of the way over the water.
	local pierLen = math.max(8, d * 0.35) + rimT + 3
	local pierZ = d * 0.5 + rimT + 3 - pierLen * 0.5
	part(f, "Pier", Vector3.new(4.5, 0.6, pierLen), cf * CFrame.new(0, rimH + 0.3, pierZ), wood, Enum.Material.WoodPlanks)
	for _, x in ipairs({ -1.9, 1.9 }) do
		part(f, "PierPost", Vector3.new(0.6, rimH + 1.6, 0.6),
			cf * CFrame.new(x, (rimH + 1.6) * 0.5, pierZ - pierLen * 0.5 + 0.4), wood:Lerp(Color3.new(0, 0, 0), 0.2),
			Enum.Material.Wood)
	end
	-- Steps up onto the pier from the floor.
	part(f, "PierStep", Vector3.new(4.5, rimH * 0.5, 2), cf * CFrame.new(0, rimH * 0.25, d * 0.5 + rimT + 4),
		wood, Enum.Material.WoodPlanks)

	-- THE DOCK: the spot the server measures from, and the prompt.
	local dockZ = pierZ - pierLen * 0.5 + 1.2
	local dock = part(f, "Dock", Vector3.new(2, 0.3, 2), cf * CFrame.new(0, rimH + 0.75, dockZ),
		Color3.fromRGB(196, 160, 96), Enum.Material.WoodPlanks, { CanCollide = false })
	dock:SetAttribute("SpotId", spot.id)
	dock:SetAttribute("Machine", "fish")
	CollectionService:AddTag(dock, P.TAG)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = "Fish"
	pr.ObjectText = spot.name
	pr.HoldDuration = 0.15
	pr.MaxActivationDistance = 16
	pr.RequiresLineOfSight = false
	pr.Parent = dock

	-- The sign, at the foot of the pier.
	local post = part(f, "SignPost", Vector3.new(0.6, 7, 0.6), cf * CFrame.new(4, 3.5, d * 0.5 + rimT + 3),
		wood, Enum.Material.Wood)
	local board = part(f, "Sign", Vector3.new(6.5, 2.4, 0.3), cf * CFrame.new(4, 6.2, d * 0.5 + rimT + 3.3),
		Color3.fromRGB(46, 36, 28), Enum.Material.Wood)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = board
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.BuilderSansBold
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 232, 190)
	t.Text = "🎣 " .. string.upper(spot.name)
	t.Parent = gui
	if look.light then
		local glow = Instance.new("PointLight")
		glow.Range = 22
		glow.Brightness = 1.2
		glow.Color = Color3.fromRGB(150, 220, 255)
		glow.Parent = post
	end
	return f, dock
end

return P
