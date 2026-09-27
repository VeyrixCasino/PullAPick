-- MineDepthPlazas: open seam decks at 500/1500; Coming Soon stub at 2500.

local CollectionService = game:GetService("CollectionService")

local shared = game:GetService("ReplicatedStorage"):WaitForChild("Mine"):WaitForChild("Shared")
local Depth = require(shared:WaitForChild("MineDepth"))
local C = require(shared:WaitForChild("MineConfig"))

local MineDepthPlazas = {}

local opened = {}
local boardsStarted = false
local surfaceDone = false

local function leaderboards()
	local ok, mod = pcall(function()
		return require(script.Parent:WaitForChild("LeaderboardService"))
	end)
	return ok and mod or nil
end

local function zoneFolder(zoneId)
	local world = workspace:FindFirstChild("MineWorld")
	return world and world:FindFirstChild("Biome_" .. tostring(zoneId))
end

local function outpostTemplate(zoneId)
	local biome = zoneFolder(zoneId)
	return biome and biome:FindFirstChild("Outpost_" .. tostring(zoneId))
end

local function seamY(zone, seam)
	local origin = C.zoneOrigin(zone)
	local size = C.BLOCK or 5
	return origin.Y - seam * size - size * 0.25
end

local function makePad(parent, name, size, cf, attrs)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Material = Enum.Material.Slate
	p.Color = Color3.fromRGB(70, 78, 92)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if attrs then
		for k, v in pairs(attrs) do
			p:SetAttribute(k, v)
		end
	end
	p.Parent = parent
	return p
end

local function addPrompt(part, text)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = text or "Use"
	prompt.ObjectText = part.Name
	prompt.MaxActivationDistance = 14
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

local function stubBoard(parent, cf, title, zoneId)
	local board = Instance.new("Part")
	board.Name = "DepthBoard"
	board.Anchored = true
	board.Size = Vector3.new(8, 5, 0.4)
	board.CFrame = cf
	board.Color = Color3.fromRGB(40, 44, 54)
	board.Material = Enum.Material.SmoothPlastic
	board.CanCollide = false
	if zoneId then
		board:SetAttribute("ZoneId", zoneId)
	end
	board.Parent = parent
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = board
	local titleL = Instance.new("TextLabel")
	titleL.Name = "Title"
	titleL.Size = UDim2.new(1, -8, 0, 36)
	titleL.Position = UDim2.fromOffset(4, 4)
	titleL.BackgroundTransparency = 1
	titleL.Text = title or "Depth Leaders"
	titleL.TextColor3 = Color3.fromRGB(230, 230, 240)
	titleL.TextScaled = true
	titleL.Font = Enum.Font.GothamBold
	titleL.Parent = gui
	local list = Instance.new("Frame")
	list.Name = "RankList"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromOffset(4, 44)
	list.Size = UDim2.new(1, -8, 1, -52)
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	local lb = leaderboards()
	if lb and lb.attachDepthBoard and zoneId then
		lb.attachDepthBoard(board, zoneId)
	end
	return board
end

local LAYOUT_VER = 4

local function zoneAxes(zone)
	local origin = C.zoneOrigin(zone)
	local flat = Vector3.new(origin.X, 0, origin.Z)
	local dir = flat.Magnitude > 1 and flat.Unit or Vector3.new(0, 0, 1)
	local side = Vector3.new(-dir.Z, 0, dir.X)
	local back = -dir
	local hole = ((C.GRID or 6) * (C.BLOCK or 5)) * 0.5
	return origin, dir, side, back, hole
end

local function shaftXZ(zone)
	local origin, _dir, side, _back, hole = zoneAxes(zone)
	local at = origin - side * (hole + 16)
	return at.X, at.Z, origin, side, hole
end

local function timber(parent, name, size, cf, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Material = Enum.Material.WoodPlanks
	p.Color = color or Color3.fromRGB(78, 54, 34)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function cyanRing(parent, cf, radius)
	local ring = Instance.new("Part")
	ring.Name = "ElevatorRing"
	ring.Anchored = true
	ring.CanCollide = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.35, radius * 2, radius * 2)
	ring.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(80, 230, 255)
	ring.Transparency = 0.15
	ring.Parent = parent
	return ring
end

local function lantern(parent, cf)
	local lamp = Instance.new("Part")
	lamp.Name = "Lantern"
	lamp.Anchored = true
	lamp.CanCollide = false
	lamp.Size = Vector3.new(1.1, 1.5, 1.1)
	lamp.CFrame = cf
	lamp.Material = Enum.Material.Glass
	lamp.Color = Color3.fromRGB(255, 176, 72)
	lamp.Transparency = 0.2
	lamp.Parent = parent
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 168, 70)
	light.Range = 16
	light.Brightness = 1.3
	light.Parent = lamp
end

local function stallNpc(parent, name, title, cf, shirt)
	if parent:FindFirstChild(name) then return end
	local model = Instance.new("Model")
	model.Name = name
	local function limb(limbName, sz, offset, col)
		local p = Instance.new("Part")
		p.Name = limbName
		p.Anchored = true
		p.CanCollide = false
		p.Size = sz
		p.CFrame = cf * CFrame.new(offset)
		p.Color = col
		p.Material = Enum.Material.SmoothPlastic
		p.Parent = model
		return p
	end
	limb("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 1.2, 0), shirt)
	local head = limb("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 2.8, 0), Color3.fromRGB(255, 214, 180))
	limb("LegL", Vector3.new(0.55, 1.5, 0.55), Vector3.new(-0.4, -0.4, 0), Color3.fromRGB(42, 44, 56))
	limb("LegR", Vector3.new(0.55, 1.5, 0.55), Vector3.new(0.4, -0.4, 0), Color3.fromRGB(42, 44, 56))
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(140, 28)
	bb.StudsOffset = Vector3.new(0, 1.6, 0)
	bb.AlwaysOnTop = true
	bb.Parent = head
	local tl = Instance.new("TextLabel")
	tl.BackgroundTransparency = 1
	tl.Size = UDim2.fromScale(1, 1)
	tl.Font = Enum.Font.GothamBold
	tl.TextSize = 16
	tl.TextColor3 = Color3.new(1, 1, 1)
	tl.Text = title
	tl.Parent = bb
	model.Parent = parent
end

local function dressOutpost(folder, zone, seam)
	if folder:FindFirstChild("OutpostSign") then
		return
	end
	local origin = C.zoneOrigin(zone)
	local y = seamY(zone, seam)
	local size = C.BLOCK or 5
	local grid = C.GRID or 6
	local half = (grid * size) * 0.5
	local thick = size * 2
	local hole = grid * size
	local deck = folder:FindFirstChild("Deck")
	if deck then deck:Destroy() end
	local edge = folder:FindFirstChild("SquareEdge")
	if edge then edge:Destroy() end
	local span = hole + thick * 2
	makePad(folder, "RimN", Vector3.new(span, size * 0.35, thick), CFrame.new(origin.X, y, origin.Z - half - thick * 0.5), { ZoneId = zone.id, Seam = seam })
	makePad(folder, "RimS", Vector3.new(span, size * 0.35, thick), CFrame.new(origin.X, y, origin.Z + half + thick * 0.5), { ZoneId = zone.id, Seam = seam })
	makePad(folder, "RimW", Vector3.new(thick, size * 0.35, hole), CFrame.new(origin.X - half - thick * 0.5, y, origin.Z), { ZoneId = zone.id, Seam = seam })
	makePad(folder, "RimE", Vector3.new(thick, size * 0.35, hole), CFrame.new(origin.X + half + thick * 0.5, y, origin.Z), { ZoneId = zone.id, Seam = seam })
	local shopAt = CFrame.new(origin.X, y, origin.Z - half - thick - 2)
	local sellAt = CFrame.new(origin.X, y, origin.Z + half + thick + 2)
	makePad(folder, "ShopFloor", Vector3.new(12, 1, 10), shopAt, { ZoneId = zone.id, Seam = seam })
	makePad(folder, "SellFloor", Vector3.new(12, 1, 10), sellAt, { ZoneId = zone.id, Seam = seam })
	local shop = folder:FindFirstChild("shop_depth")
	if shop and shop:IsA("BasePart") then
		shop.CFrame = shopAt * CFrame.new(0, 3, 0)
		shop.Size = Vector3.new(10, 6, 8)
	end
	local sell = folder:FindFirstChild("sell_depth")
	if sell and sell:IsA("BasePart") then
		sell.CFrame = sellAt * CFrame.new(0, 3, 0)
		sell.Size = Vector3.new(10, 6, 8)
	end
	stallNpc(folder, "ShopNPC", "Shop", shopAt * CFrame.new(-3.2, 0.5, 0), Color3.fromRGB(64, 96, 150))
	stallNpc(folder, "SellNPC", "Sell", sellAt * CFrame.new(3.2, 0.5, 0), Color3.fromRGB(150, 96, 54))
	lantern(folder, shopAt * CFrame.new(-5, 4, 0))
	lantern(folder, shopAt * CFrame.new(5, 4, 0))
	lantern(folder, sellAt * CFrame.new(-5, 4, 0))
	lantern(folder, sellAt * CFrame.new(5, 4, 0))
	local sign = Instance.new("Part")
	sign.Name = "OutpostSign"
	sign.Anchored = true
	sign.CanCollide = false
	sign.Size = Vector3.new(12, 4, 0.5)
	sign.CFrame = CFrame.new(origin.X + half + thick + 3, y + 7, origin.Z)
	sign.Material = Enum.Material.Wood
	sign.Color = Color3.fromRGB(58, 42, 26)
	sign.Parent = folder
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(320, 90)
	bb.StudsOffset = Vector3.new(0, 1, 0)
	bb.Parent = sign
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 220, 150)
	label.Text = (zone.name or zone.id) .. "\nThe " .. tostring(seam) .. " Depth Outpost"
	label.Parent = bb
end

local function buildElevator(zone)
	local world = workspace:FindFirstChild("MineWorld")
	local pits = world and world:FindFirstChild("Pits")
	if not pits or not zone or not zone.id then
		return
	end
	local name = "Mineshaft_" .. zone.id
	if pits:FindFirstChild(name) then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = pits
	local origin = C.zoneOrigin(zone)
	local size = C.BLOCK or 5
	local grid = C.GRID or 6
	local half = (grid * size) * 0.5
	local x = origin.X - (half + size * 3)
	local z = origin.Z
	local top = origin.Y + 2
	local bot = origin.Y - 5000 * size
	local yCursor = top
	while yCursor > bot + 8 do
		local h = math.min(1800, yCursor - bot)
		local beam = Instance.new("Part")
		beam.Name = "Shaft"
		beam.Anchored = true
		beam.CanCollide = false
		beam.Material = Enum.Material.WoodPlanks
		beam.Color = Color3.fromRGB(62, 46, 30)
		beam.Size = Vector3.new(3.2, h, 3.2)
		beam.CFrame = CFrame.new(x, yCursor - h * 0.5, z)
		beam.Parent = folder
		yCursor -= h
	end
	local floors = { 0 }
	for _, seam in ipairs(Depth.SEAMS or {}) do
		table.insert(floors, seam)
	end
	for _, seam in ipairs(floors) do
		local y = (seam <= 0) and (origin.Y + 1) or (seamY(zone, seam) + 1)
		local pad = makePad(folder, "Floor_" .. tostring(seam), Vector3.new(7, 1, 7), CFrame.new(x, y, z), {
			Machine = "elevator",
			ZoneId = zone.id,
			Seam = seam,
		})
		local prompt = addPrompt(pad, "Choose outpost")
		prompt.ObjectText = "Mineshaft"
		local lip = origin.X - half
		local span = math.max(4, lip - x)
		makePad(folder, "Plank_" .. tostring(seam), Vector3.new(span, 1, 4), CFrame.new(x + span * 0.5, y, z), {
			ZoneId = zone.id,
			Seam = seam,
		})
		lantern(folder, CFrame.new(x + 2.4, y + 3.4, z))
	end
end

function MineDepthPlazas.ride(plr, parent, p, tp, ensureZone, net, snapFn, seamOverride)
	if not plr or not p or not tp then
		return
	end
	local seam = tonumber(seamOverride)
	if seam == nil and parent then
		seam = tonumber(parent:GetAttribute("Seam")) or 0
	else
		seam = seam or 0
	end
	local zoneId = (parent and parent:GetAttribute("ZoneId")) or p.zoneId
	local z = C.zoneById and C.zoneById(zoneId)
	if not z then
		return
	end
	local deepest = (p.deepest and p.deepest[z.id]) or 0
	if seam > 0 and deepest < seam then
		if net then
			net:FireClient(plr, "toast", "Reach depth " .. tostring(seam) .. " to ride to this outpost.")
		end
		return
	end
	local origin = C.zoneOrigin(z)
	local size = C.BLOCK or 5
	local grid = C.GRID or 6
	local x = origin.X - (((grid * size) * 0.5) + size * 3)
	local y = (seam <= 0) and (origin.Y + 5) or (seamY(z, seam) + 5)
	tp(plr, CFrame.new(x, y, origin.Z + 3))
	if seam > 0 and ensureZone then
		ensureZone(z, seam + (C.LAYER_WINDOW or 8))
	end
	if snapFn then
		snapFn(plr)
	end
end

function buildDeck(zone, seam, desk)
	local world = workspace:FindFirstChild("MineWorld")
	local pits = world and world:FindFirstChild("Pits")
	if not pits then
		return nil
	end
	local name = "DepthPlaza_" .. zone.id .. "_" .. tostring(seam)
	if pits:FindFirstChild(name) then
		local existing = pits[name]
		-- Old plazas shipped a 1.2-stud sell slab that players stood next to
		-- on the deck without ever triggering. Grow the volume in place.
		local sell = existing:FindFirstChild("sell_depth")
		if sell and sell:IsA("BasePart") then
			local size = C.BLOCK or 5
			local origin = C.zoneOrigin(zone)
			local y = seamY(zone, seam)
			local offset = size * 2.5
			sell.Size = Vector3.new(size * 3.2, size * 1.6, size * 3.2)
			sell.CFrame = CFrame.new(origin.X - offset, y + size * 0.9, origin.Z - offset)
			sell.Transparency = 1
			sell.CanCollide = false
			sell:SetAttribute("Machine", "sell")
			sell:SetAttribute("SellDesk", desk)
			sell:SetAttribute("ZoneId", zone.id)
		end
		dressOutpost(existing, zone, seam)
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder:SetAttribute("ZoneId", zone.id)
	folder:SetAttribute("Seam", seam)
	folder.Parent = pits
	local origin = C.zoneOrigin(zone)
	local y = seamY(zone, seam)
	local size = C.BLOCK or 5
	local deckW = size * 11
	local outpost = outpostTemplate(zone.id)
	local square = outpost and outpost:FindFirstChild("Square")
	local edge = outpost and outpost:FindFirstChild("SquareEdge")
	if square and square:IsA("BasePart") then
		local clone = square:Clone()
		clone.Name = "Deck"
		clone.Anchored = true
		clone.CFrame = CFrame.new(origin.X, y, origin.Z)
		clone.Parent = folder
		if edge and edge:IsA("BasePart") then
			local e2 = edge:Clone()
			e2.Anchored = true
			e2.CFrame = CFrame.new(origin.X, y + 0.2, origin.Z)
			e2.Parent = folder
		end
	else
		makePad(folder, "Deck", Vector3.new(deckW, size * 0.4, deckW), CFrame.new(origin.X, y, origin.Z), {
			ZoneId = zone.id,
			Seam = seam,
		})
	end
	local deskKey = desk
	local offset = size * 2.5
	-- Match surface depot Trigger size (tall volume). A 1.2-stud slab was easy
	-- to miss while standing on the deck, so the pad never fired and dirt stayed.
	local sell = makePad(folder, "sell_depth", Vector3.new(size * 3.2, size * 1.6, size * 3.2),
		CFrame.new(origin.X - offset, y + size * 0.9, origin.Z - offset), {
			Machine = "sell",
			SellDesk = deskKey,
			ZoneId = zone.id,
		})
	-- Invisible volume so the deck art stays clean; detection is by bounds.
	sell.Transparency = 1
	sell.CanCollide = false
	addPrompt(sell, "Sell (depth)")
	local shop = makePad(folder, "shop_depth", Vector3.new(size * 2.2, 1.2, size * 2.2),
		CFrame.new(origin.X + offset, y + 1.1, origin.Z - offset), {
			Machine = "depth_shop",
			DepthShop = deskKey,
			Seam = seam,
			ZoneId = zone.id,
		})
	addPrompt(shop, (desk == "shadowzone" or desk == "deep") and "Shadowzone shop · rebirth" or "Deeprock shop · rebirth")
	local ret = makePad(folder, "return_surface", Vector3.new(size * 2.2, 1.2, size * 2.2),
		CFrame.new(origin.X - offset, y + 1.1, origin.Z + offset), {
			Destination = "surface",
			ZoneId = zone.id,
		})
	addPrompt(ret, "Return to surface")
	local shaft = makePad(folder, "mineshaft", Vector3.new(size * 2.2, 1.2, size * 2.2),
		CFrame.new(origin.X + offset, y + 1.1, origin.Z + offset), {
			Machine = "mineshaft",
			ZoneId = zone.id,
			Seam = seam,
		})
	addPrompt(shaft, "Continue down")
	stubBoard(
		folder,
		CFrame.new(origin.X, y + 4, origin.Z + deckW * 0.42),
		"The " .. tostring(seam) .. " Depth Outpost",
		zone.id
	)
	dressOutpost(folder, zone, seam)
	CollectionService:AddTag(folder, "MineDepthPlaza")
	return folder
end

local function soonLabelText(n, need)
	need = need or Depth.COMING_SOON_PLAYERS or 50
	n = math.max(0, math.floor(tonumber(n) or 0))
	if n >= need then
		return "Depth 2500 ready — see next update"
	end
	return string.format("Unlocked soon — %d/%d explorers", n, need)
end

local function buildComingSoon(zone, seam)
	local world = workspace:FindFirstChild("MineWorld")
	local pits = world and world:FindFirstChild("Pits")
	if not pits then
		return nil
	end
	local name = "DepthSoon_" .. zone.id .. "_" .. tostring(seam)
	if pits:FindFirstChild(name) then
		return pits[name]
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder:SetAttribute("ZoneId", zone.id)
	folder:SetAttribute("Seam", seam)
	folder.Parent = pits
	local origin = C.zoneOrigin(zone)
	local y = seamY(zone, seam)
	local part = Instance.new("Part")
	part.Name = "ComingSoon"
	part.Anchored = true
	part.Size = Vector3.new(10, 6, 1)
	part.CFrame = CFrame.new(origin.X, y + 4, origin.Z)
	part.Color = Color3.fromRGB(36, 32, 48)
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = folder
	local gui = Instance.new("BillboardGui")
	gui.Name = "SoonGui"
	gui.Size = UDim2.fromOffset(260, 70)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Coming Soon"
	label.TextColor3 = Color3.fromRGB(255, 220, 140)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	local lb = leaderboards()
	local need = Depth.COMING_SOON_PLAYERS or 50
	local n = 0
	if lb and lb.countDepthAtLeast then
		n = lb.countDepthAtLeast(zone.id, seam) or 0
	end
	label.Text = soonLabelText(n, need)
	folder:SetAttribute("SoonReady", n >= need)
	folder:SetAttribute("SoonCount", n)
	return folder
end

function MineDepthPlazas.refreshComingSoon()
	local world = workspace:FindFirstChild("MineWorld")
	local pits = world and world:FindFirstChild("Pits")
	if not pits then
		return
	end
	local lb = leaderboards()
	local need = Depth.COMING_SOON_PLAYERS or 50
	local seam = Depth.COMING_SOON_SEAM or 2500
	for _, folder in ipairs(pits:GetChildren()) do
		if folder.Name:match("^DepthSoon_") then
			local zoneId = folder:GetAttribute("ZoneId") or folder.Name:match("^DepthSoon_(.-)_")
			local part = folder:FindFirstChild("ComingSoon")
			local gui = part and part:FindFirstChild("SoonGui")
			local label = gui and gui:FindFirstChild("Label")
			local n = 0
			if lb and lb.countDepthAtLeast and zoneId then
				n = lb.countDepthAtLeast(zoneId, seam) or 0
			end
			if label then
				label.Text = soonLabelText(n, need)
			end
			folder:SetAttribute("SoonReady", n >= need)
			folder:SetAttribute("SoonCount", n)
		end
	end
end

function MineDepthPlazas.refreshBoards()
	local lb = leaderboards()
	if lb and lb.refreshDepthBoards then
		lb.refreshDepthBoards()
	end
	MineDepthPlazas.refreshComingSoon()
end

function MineDepthPlazas.ensureSurfaceBoards()
	if surfaceDone then
		return
	end
	surfaceDone = true
	for _, zone in ipairs(C.ZONES or {}) do
		local outpost = outpostTemplate(zone.id)
		if outpost and not outpost:FindFirstChild("DepthBoard") then
			local square = outpost:FindFirstChild("Square")
			local apron = outpost:FindFirstChild("Apron")
			local cf
			if apron and apron:IsA("BasePart") then
				cf = apron.CFrame * CFrame.new(0, 2, -0.6)
			elseif square and square:IsA("BasePart") then
				cf = square.CFrame * CFrame.new(square.Size.X * 0.42, 6, 0)
			else
				local origin = C.zoneOrigin(zone)
				cf = CFrame.new(origin.X + 40, origin.Y + 8, origin.Z)
			end
			stubBoard(outpost, cf, "Depth — " .. tostring(zone.name or zone.id), zone.id)
		end
	end
end

function MineDepthPlazas.start()
	if boardsStarted then
		return
	end
	boardsStarted = true
	task.defer(function()
		MineDepthPlazas.ensureSurfaceBoards()
		for _, zone in ipairs(C.ZONES or {}) do
			pcall(buildElevator, zone)
		end
		MineDepthPlazas.refreshBoards()
		-- Repair sell volumes on plazas that were built before the tall trigger.
		local world = workspace:FindFirstChild("MineWorld")
		local pits = world and world:FindFirstChild("Pits")
		if pits then
			for _, folder in ipairs(pits:GetChildren()) do
				local zoneId, seam = string.match(folder.Name, "^DepthPlaza_(.-)_(%d+)$")
				if zoneId and seam then
					local zone = C.zoneById and C.zoneById(zoneId)
					local desk = Depth.bandUnlockKey(tonumber(seam))
					if zone and desk then
						pcall(buildDeck, zone, tonumber(seam), desk)
					end
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(60)
			pcall(MineDepthPlazas.refreshBoards)
		end
	end)
end

function MineDepthPlazas.tryOpenSeam(zoneId, seam)
	zoneId = tostring(zoneId or "")
	seam = tonumber(seam)
	if zoneId == "" or not seam then
		return false
	end
	opened[zoneId] = opened[zoneId] or {}
	if opened[zoneId][seam] then
		return true
	end
	local zone = C.zoneById and C.zoneById(zoneId)
	if not zone then
		return false
	end
	MineDepthPlazas.ensureSurfaceBoards()
	local desk = Depth.bandUnlockKey(seam)
	if not desk then
		return false
	end
	pcall(buildElevator, zone)
	buildDeck(zone, seam, desk)
	opened[zoneId][seam] = true
	MineDepthPlazas.start()
	return true
end

function MineDepthPlazas.onLayerBroken(zoneId, layer)
	layer = math.floor(tonumber(layer) or 0)
	local gap = Depth.AIR_GAP or 5
	for _, seam in ipairs(Depth.SEAMS or { 500, 1500, 2500 }) do
		if layer >= (seam - gap) and layer <= seam then
			MineDepthPlazas.tryOpenSeam(zoneId, seam)
		end
	end
end

-- Alias used by MineServer finishBreak.
function MineDepthPlazas.onDepthCredit(zoneId, deepest)
	MineDepthPlazas.onLayerBroken(zoneId, deepest)
end

return MineDepthPlazas
