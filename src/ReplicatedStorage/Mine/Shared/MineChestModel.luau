--[[
	MineChestModel: the chest you actually see in the shaft.

	A chest used to be a coloured cube, which meant the only thing telling you a
	Ledger Vault from a Topsoil Chest was its tint -- and at shaft distance, in
	shadow, that is nothing at all. This builds a real chest into the block: a
	planked body, a ribbed barrel lid, iron straps, a lock plate and feet.

	The MineBlock keeps being the thing you hit. Every piece here is CanQuery
	false so it cannot steal the aim raycast, and CanCollide false so it cannot
	push the player around. The block itself just goes invisible behind it, and
	because the pieces are its children they die with it when it breaks.
]]
local MineChestModel = {}

local function C3(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Five kinds, five reads. Wood carries the tier, metal carries the promise.
MineChestModel.PALETTE = {
	native   = { wood = C3(118, 84, 52),  dark = C3(78, 54, 34),  metal = C3(126, 128, 134), glow = nil },
	broad    = { wood = C3(96, 66, 44),   dark = C3(62, 42, 28),  metal = C3(168, 124, 66), glow = nil },
	currency = { wood = C3(150, 118, 76), dark = C3(104, 80, 50), metal = C3(226, 184, 84), glow = C3(255, 214, 90) },
	item     = { wood = C3(74, 62, 74),   dark = C3(48, 40, 50),  metal = C3(196, 202, 216), glow = C3(150, 190, 255) },
	chase    = { wood = C3(46, 36, 42),   dark = C3(28, 22, 28),  metal = C3(255, 206, 92),  glow = C3(255, 170, 60) },
}

function MineChestModel.palette(kind)
	return MineChestModel.PALETTE[kind or "native"] or MineChestModel.PALETTE.native
end

local function piece(parent, cf, size, colour, material)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false      -- the block underneath stays the aim target
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material or Enum.Material.Wood
	p.Parent = parent
	return p
end

--[[
	Build the chest into `part`, a MineBlock. `kind` picks the palette.
	`scale` is the cell size in studs, so this works if the voxel size changes.
]]
function MineChestModel.build(part, kind, scale)
	scale = (scale or part.Size.X) / 5      -- authored against a 5-stud cell
	local pal = MineChestModel.palette(kind)
	local base = part.CFrame
	local function at(x, y, z, rx)
		local cf = base * CFrame.new(x * scale, y * scale, z * scale)
		return rx and (cf * CFrame.Angles(rx, 0, 0)) or cf
	end
	local function sz(x, y, z)
		return Vector3.new(x, y, z) * scale
	end

	-- The block stops being the thing you look at, but stays the thing you hit.
	part.Transparency = 1

	-- Body: a slab, then two plank grooves cut into it by dark inlays.
	local body = piece(part, at(0, -0.85, 0), sz(3.7, 1.7, 2.7), pal.wood)
	for _, x in ipairs({ -1.05, 0, 1.05 }) do
		piece(part, at(x, -0.85, 1.36), sz(0.12, 1.7, 0.06), pal.dark)
		piece(part, at(x, -0.85, -1.36), sz(0.12, 1.7, 0.06), pal.dark)
	end

	-- Lid: five ribs swung through a quarter turn so the top reads as a barrel
	-- rather than a second box.
	for i = 0, 4 do
		local a = math.rad(-54 + i * 27)
		local r = 0.95
		piece(part,
			at(0, 0.05 + math.cos(a) * r, math.sin(a) * r, a),
			sz(3.7, 0.42, 0.44), (i % 2 == 0) and pal.wood or pal.dark)
	end

	-- Iron straps over body and lid, and a rim where the two meet.
	for _, x in ipairs({ -1.3, 1.3 }) do
		piece(part, at(x, -0.85, 0), sz(0.22, 1.8, 2.78), pal.metal, Enum.Material.Metal)
		piece(part, at(x, 0.62, 0), sz(0.22, 0.9, 2.2), pal.metal, Enum.Material.Metal)
	end
	piece(part, at(0, 0.02, 0), sz(3.84, 0.22, 2.84), pal.metal, Enum.Material.Metal)

	-- Lock plate on the front, and the keyhole.
	piece(part, at(0, -0.2, 1.42), sz(0.7, 0.8, 0.16), pal.metal, Enum.Material.Metal)
	piece(part, at(0, -0.28, 1.5), sz(0.16, 0.3, 0.1), pal.dark, Enum.Material.Metal)

	-- Feet, so it sits on the rock instead of floating in it.
	for _, x in ipairs({ -1.45, 1.45 }) do
		for _, z in ipairs({ -1.05, 1.05 }) do
			piece(part, at(x, -1.78, z), sz(0.4, 0.3, 0.4), pal.dark)
		end
	end

	-- The good ones announce themselves. A light, not a glow part, so it reads
	-- in a dark shaft without adding faces.
	if pal.glow then
		local l = Instance.new("PointLight")
		l.Color = pal.glow
		l.Brightness = 1.6
		l.Range = 10
		l.Shadows = false
		l.Parent = part
	end

	-- Section number on the lid: big lowercase roman, tiny arabic under it.
	local roman = part:GetAttribute("SectionRoman")
	local arabic = part:GetAttribute("SectionArabic")
	if roman then
		local face = piece(part, at(0, 0.72, 0.15), sz(2.2, 0.08, 1.4), pal.dark, Enum.Material.SmoothPlastic)
		local sg = Instance.new("SurfaceGui")
		sg.Name = "SectionStamp"
		sg.Face = Enum.NormalId.Top
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 80
		sg.LightInfluence = 0.2
		sg.Parent = face
		local big = Instance.new("TextLabel")
		big.BackgroundTransparency = 1
		big.Font = Enum.Font.GothamBlack
		big.Text = tostring(roman) .. "."
		big.TextColor3 = pal.metal
		big.TextScaled = true
		big.Size = UDim2.new(1, 0, 0.72, 0)
		big.Position = UDim2.fromScale(0, 0)
		big.Parent = sg
		local tiny = Instance.new("TextLabel")
		tiny.BackgroundTransparency = 1
		tiny.Font = Enum.Font.Gotham
		tiny.Text = tostring(arabic or "")
		tiny.TextColor3 = pal.metal
		tiny.TextTransparency = 0.15
		tiny.TextScaled = true
		tiny.Size = UDim2.new(1, 0, 0.28, 0)
		tiny.Position = UDim2.fromScale(0, 0.72)
		tiny.Parent = sg
		local front = Instance.new("SurfaceGui")
		front.Name = "SectionStampFront"
		front.Face = Enum.NormalId.Front
		front.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		front.PixelsPerStud = 50
		front.LightInfluence = 0.25
		front.Parent = body
		local fBig = Instance.new("TextLabel")
		fBig.BackgroundTransparency = 1
		fBig.Font = Enum.Font.GothamBlack
		fBig.Text = tostring(roman) .. "."
		fBig.TextColor3 = Color3.new(1, 1, 1)
		fBig.TextScaled = true
		fBig.Size = UDim2.new(1, 0, 0.7, 0)
		fBig.Parent = front
		local fTiny = Instance.new("TextLabel")
		fTiny.BackgroundTransparency = 1
		fTiny.Font = Enum.Font.Gotham
		fTiny.Text = tostring(arabic or "")
		fTiny.TextColor3 = Color3.fromRGB(230, 230, 230)
		fTiny.TextScaled = true
		fTiny.Size = UDim2.new(1, 0, 0.3, 0)
		fTiny.Position = UDim2.fromScale(0, 0.7)
		fTiny.Parent = front
	end

	-- 2D chest cutout on the front so each identity reads at shaft distance.
	local chestId = part:GetAttribute("ChestType")
	if chestId and body then
		local ok, Icons = pcall(function()
			return require(game:GetService("ReplicatedStorage").Mine.Shared:WaitForChild("MineIcons"))
		end)
		local img = ok and Icons.image(chestId)
		if img then
			local sg = Instance.new("SurfaceGui")
			sg.Name = "ChestArt"
			sg.Face = Enum.NormalId.Front
			sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			sg.PixelsPerStud = 50
			sg.LightInfluence = 0.35
			sg.Parent = body
			local il = Instance.new("ImageLabel")
			il.BackgroundTransparency = 1
			il.BorderSizePixel = 0
			il.Image = img
			il.Size = UDim2.fromScale(1, 1)
			il.ScaleType = Enum.ScaleType.Fit
			il.Parent = sg
		end
	end
	return part
end

return MineChestModel
