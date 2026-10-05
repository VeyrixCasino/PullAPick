-- MineDepthPlazas: seam outposts + mineshaft elevators.
-- LayoutVer 4: shaft opposite next-zone portal; surface-clone outposts; cage elevators.

local CollectionService = game:GetService("CollectionService")

local shared = game:GetService("ReplicatedStorage"):WaitForChild("Mine"):WaitForChild("Shared")
local Depth = require(shared:WaitForChild("MineDepth"))
local C = require(shared:WaitForChild("MineConfig"))

local MineDepthPlazas = {}

-- 6: station bay behind every outpost, and the ladder is every 500 again.
-- 7: outposts darken and warm with depth (depthLook).
local LAYOUT_VER = 7
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

-- Zone axes match WorldBuilder: dir = lobby→pit, back = toward plaza, side = left of dir.
-- Next-zone portal sits at +side*(hole+16). Mineshaft always on the opposite side.
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
	-- Opposite side from where the next-zone portal was / is.
	local at = origin - side * (hole + 16)
	return at.X, at.Z, origin, side, hole
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

-- One landing: wooden cage elevator that reads as a mine shaft lift.
local function buildCageAt(folder, x, y, z, towardPit, zoneId, seam)
	local look = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(towardPit.X, y, towardPit.Z))
	local cage = Instance.new("Model")
	cage.Name = "Cage_" .. tostring(seam)
	cage.Parent = folder

	-- Deck
	timber(cage, "Deck", Vector3.new(7.2, 0.7, 7.2), look * CFrame.new(0, 0, 0), Color3.fromRGB(92, 68, 44))
	-- Corner posts
	for _, o in ipairs({
		Vector3.new(-3.1, 4, -3.1),
		Vector3.new(3.1, 4, -3.1),
		Vector3.new(-3.1, 4, 3.1),
		Vector3.new(3.1, 4, 3.1),
	}) do
		timber(cage, "Post", Vector3.new(0.7, 8.2, 0.7), look * CFrame.new(o), Color3.fromRGB(62, 44, 28))
	end
	-- Crossbeams / roof frame
	timber(cage, "BeamN", Vector3.new(7.2, 0.55, 0.55), look * CFrame.new(0, 8.1, -3.1))
	timber(cage, "BeamS", Vector3.new(7.2, 0.55, 0.55), look * CFrame.new(0, 8.1, 3.1))
	timber(cage, "BeamE", Vector3.new(0.55, 0.55, 7.2), look * CFrame.new(3.1, 8.1, 0))
	timber(cage, "BeamW", Vector3.new(0.55, 0.55, 7.2), look * CFrame.new(-3.1, 8.1, 0))
	-- Headframe A-frame above
	timber(cage, "HeadL", Vector3.new(0.7, 6, 0.7), look * CFrame.new(-2.2, 11.2, 0) * CFrame.Angles(0, 0, math.rad(18)))
	timber(cage, "HeadR", Vector3.new(0.7, 6, 0.7), look * CFrame.new(2.2, 11.2, 0) * CFrame.Angles(0, 0, math.rad(-18)))
	timber(cage, "HeadTop", Vector3.new(5.2, 0.6, 0.6), look * CFrame.new(0, 14.2, 0))
	-- Winch drum
	local drum = Instance.new("Part")
	drum.Name = "Winch"
	drum.Anchored = true
	drum.CanCollide = false
	drum.Shape = Enum.PartType.Cylinder
	drum.Size = Vector3.new(1.4, 2.4, 2.4)
	drum.CFrame = look * CFrame.new(0, 13.4, 0) * CFrame.Angles(0, 0, math.rad(90))
	drum.Material = Enum.Material.Metal
	drum.Color = Color3.fromRGB(72, 74, 82)
	drum.Parent = cage
	-- Guide cables (visual)
	for _, ox in ipairs({ -1.2, 1.2 }) do
		local cable = Instance.new("Part")
		cable.Name = "Cable"
		cable.Anchored = true
		cable.CanCollide = false
		cable.Size = Vector3.new(0.12, 12, 0.12)
		cable.CFrame = look * CFrame.new(ox, 7.5, 0)
		cable.Material = Enum.Material.Metal
		cable.Color = Color3.fromRGB(40, 42, 48)
		cable.Parent = cage
	end
	-- Railings
	for _, sideZ in ipairs({ -3.2, 3.2 }) do
		timber(cage, "Rail", Vector3.new(6.4, 0.35, 0.35), look * CFrame.new(0, 2.2, sideZ), Color3.fromRGB(54, 48, 42))
	end
	for _, sideX in ipairs({ -3.2, 3.2 }) do
		timber(cage, "Rail", Vector3.new(0.35, 0.35, 6.4), look * CFrame.new(sideX, 2.2, 0), Color3.fromRGB(54, 48, 42))
	end
	-- Lantern
	local lamp = Instance.new("Part")
	lamp.Name = "Lantern"
	lamp.Anchored = true
	lamp.CanCollide = false
	lamp.Size = Vector3.new(1, 1.2, 1)
	lamp.CFrame = look * CFrame.new(0, 5.6, -2.6)
	lamp.Material = Enum.Material.Glass
	lamp.Color = Color3.fromRGB(255, 176, 72)
	lamp.Transparency = 0.2
	lamp.Parent = cage
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 168, 70)
	light.Range = 18
	light.Brightness = 1.4
	light.Parent = lamp

	-- Interactive pad (invisible volume) + cyan ring
	local pad = makePad(folder, "Floor_" .. tostring(seam), Vector3.new(6.5, 1.2, 6.5), look * CFrame.new(0, 0.9, 0), {
		Machine = "elevator",
		ZoneId = zoneId,
		Seam = seam,
	})
	pad.Transparency = 1
	pad.CanCollide = false
	local prompt = addPrompt(pad, "Choose outpost")
	prompt.ObjectText = "Mineshaft"
	cyanRing(cage, look * CFrame.new(0, 0.45, 0), 3.4)

	-- Sign
	local sign = Instance.new("Part")
	sign.Name = "ShaftSign"
	sign.Anchored = true
	sign.CanCollide = false
	sign.Size = Vector3.new(5.5, 1.6, 0.3)
	sign.CFrame = look * CFrame.new(0, 9.4, -3.5)
	sign.Material = Enum.Material.Wood
	sign.Color = Color3.fromRGB(48, 34, 22)
	sign.Parent = cage
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(160, 40)
	bb.StudsOffset = Vector3.new(0, 0.2, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 100
	bb.Parent = sign
	local tl = Instance.new("TextLabel")
	tl.BackgroundTransparency = 1
	tl.Size = UDim2.fromScale(1, 1)
	tl.Font = Enum.Font.GothamBlack
	tl.TextScaled = true
	tl.TextColor3 = Color3.fromRGB(255, 220, 150)
	tl.Text = seam <= 0 and "SURFACE SHAFT" or (tostring(seam) .. "m SHAFT")
	tl.Parent = bb
end

local function buildElevator(zone)
	local world = workspace:FindFirstChild("MineWorld")
	local pits = world and world:FindFirstChild("Pits")
	if not pits or not zone or not zone.id then
		return
	end
	local name = "Mineshaft_" .. zone.id
	local existing = pits:FindFirstChild(name)
	if existing then
		if existing:GetAttribute("LayoutVer") == LAYOUT_VER then
			return
		end
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder:SetAttribute("LayoutVer", LAYOUT_VER)
	folder:SetAttribute("ZoneId", zone.id)
	folder.Parent = pits

	local x, z, origin = shaftXZ(zone)
	local size = C.BLOCK or 5
	local top = origin.Y + 2
	local bot = origin.Y - 5000 * size

	-- Continuous timber guide column down the shaft (segmented for streaming).
	local yCursor = top
	while yCursor > bot + 8 do
		local h = math.min(1800, yCursor - bot)
		timber(folder, "Guide", Vector3.new(2.4, h, 2.4), CFrame.new(x, yCursor - h * 0.5, z), Color3.fromRGB(58, 42, 28))
		yCursor -= h
	end

	local floors = { 0 }
	for _, seam in ipairs(Depth.SEAMS or {}) do
		if seam ~= (Depth.COMING_SOON_SEAM or 2500) or true then
			table.insert(floors, seam)
		end
	end
	for _, seam in ipairs(floors) do
		local y = (seam <= 0) and (origin.Y + 1.2) or (seamY(zone, seam) + 1.2)
		buildCageAt(folder, x, y, z, origin, zone.id, seam)
		-- Plank bridge from shaft toward pit lip
		local span = math.max(6, (Vector3.new(origin.X, 0, origin.Z) - Vector3.new(x, 0, z)).Magnitude - 4)
		local look = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(origin.X, y, origin.Z))
		timber(folder, "Plank_" .. tostring(seam), Vector3.new(4, 0.7, span), look * CFrame.new(0, 0, span * 0.5), Color3.fromRGB(88, 64, 40))
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
	local deepest = 0
	if type(p.deepest) == "table" then
		deepest = tonumber(p.deepest[tostring(z.id)]) or tonumber(p.deepest[z.id]) or 0
	end
	if seam > 0 and deepest < seam then
		if net then
			net:FireClient(plr, "toast", "Reach depth " .. tostring(seam) .. " to ride to this outpost.")
		end
		return
	end
	local zi = (C.zoneIndex and C.zoneIndex(z.id)) or 1
	if seam > 0 and Depth.rebirthForSeam then
		local need = Depth.rebirthForSeam(seam, zi)
		if need > 0 and not (Depth.meetsRebirth and Depth.meetsRebirth(p, need)) then
			if net then
				net:FireClient(plr, "toast", Depth.rebirthToast and Depth.rebirthToast(need, zi, seam) or ("Need rebirth " .. tostring(need)))
			end
			return
		end
	end
	-- Only open / load the outpost after unlock checks pass.
	if seam > 0 then
		pcall(function()
			MineDepthPlazas.tryOpenSeam(z.id, seam)
		end)
	end
	pcall(function()
		local Auth = require(script.Parent:WaitForChild("MineDigAuth"))
		Auth.allowTpUser(plr.UserId, 5)
	end)
	local origin = C.zoneOrigin(z)
	local x, zz = shaftXZ(z)
	local y = (seam <= 0) and (origin.Y + 5) or (seamY(z, seam) + 5)
	-- Prefer landing on the dressed outpost square (walled area), not empty shaft air.
	if seam > 0 then
		local world = workspace:FindFirstChild("MineWorld")
		local pits = world and world:FindFirstChild("Pits")
		local plaza = pits and pits:FindFirstChild("DepthPlaza_" .. z.id .. "_" .. tostring(seam))
		local square = plaza and plaza:FindFirstChild("SurfaceClone") and plaza.SurfaceClone:FindFirstChild("Square")
		if square and square:IsA("BasePart") then
			x, y, zz = square.Position.X, square.Position.Y + 6, square.Position.Z
		end
	end
	local look = CFrame.lookAt(Vector3.new(x, y, zz), Vector3.new(origin.X, y, origin.Z))
	tp(plr, look * CFrame.new(0, 0, -4))
	if seam > 0 and ensureZone then
		ensureZone(z, seam + (C.LAYER_WINDOW or 8))
	end
	if snapFn then
		snapFn(plr)
	end
end

-- Clone the surface outpost (shop / sell / square / path / lamps) down to this seam.
local function dressOutpostFromSurface(folder, zone, seam, desk)
	local old = folder:FindFirstChild("SurfaceClone")
	if old then
		old:Destroy()
	end
	-- Clear legacy dressing pieces
	for _, n in ipairs({
		"Deck", "SquareEdge", "ShopFloor", "SellFloor", "RimN", "RimS", "RimE", "RimW",
		"ShopNPC", "SellNPC", "OutpostSign", "Lantern",
	}) do
		local c = folder:FindFirstChild(n)
		if c then
			c:Destroy()
		end
	end
	for _, c in ipairs(folder:GetChildren()) do
		if c.Name == "Lantern" then
			c:Destroy()
		end
	end

	local template = outpostTemplate(zone.id)
	local origin = C.zoneOrigin(zone)
	local ySeam = seamY(zone, seam)
	if template then
		local square = template:FindFirstChild("Square")
		local ySurf = (square and square:IsA("BasePart") and square.Position.Y) or (origin.Y + 1.4)
		local dy = (ySeam + 0.2) - ySurf
		local clone = template:Clone()
		clone.Name = "SurfaceClone"
		for _, d in ipairs(clone:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CFrame = d.CFrame + Vector3.new(0, dy, 0)
			elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
				if d:IsA("BillboardGui") then
					d.MaxDistance = math.min(d.MaxDistance > 0 and d.MaxDistance or 100, 100)
				end
				-- keep
			end
		end
		-- Depth boards on surface clone not needed
		local db = clone:FindFirstChild("DepthBoard")
		if db then
			db:Destroy()
		end
		-- Retarget machine pads
		local shop = clone:FindFirstChild("Shop_shop")
		local sell = clone:FindFirstChild("Shop_sell")
		if shop then
			local trig = shop:FindFirstChild("Trigger", true)
			if trig then
				trig:SetAttribute("Machine", "depth_shop")
				trig:SetAttribute("DepthShop", desk)
				trig:SetAttribute("Seam", seam)
				trig:SetAttribute("ZoneId", zone.id)
			end
		end
		if sell then
			local trig = sell:FindFirstChild("Trigger", true)
			if trig then
				trig:SetAttribute("Machine", "sell")
				trig:SetAttribute("SellDesk", desk)
				trig:SetAttribute("ZoneId", zone.id)
			end
		end
		clone.Parent = folder
	end

	-- Invisible compatibility volumes (also used if clone missing)
	local _, dir, side, back, hole = zoneAxes(zone)
	local size = C.BLOCK or 5
	local shopB, shopL = hole + 40, 38
	local function at(b, l, y)
		return origin + back * b + side * l + Vector3.new(0, y - origin.Y, 0)
	end
	local y = ySeam
	local sellPos = at(shopB, -shopL, y + 3)
	local shopPos = at(shopB, shopL, y + 3)
	local sell = folder:FindFirstChild("sell_depth")
	if sell and sell:IsA("BasePart") then
		sell.Size = Vector3.new(size * 3.2, size * 2.2, size * 3.2)
		sell.CFrame = CFrame.new(sellPos)
		sell.Transparency = 1
		sell.CanCollide = false
		sell:SetAttribute("Machine", "sell")
		sell:SetAttribute("SellDesk", desk)
		sell:SetAttribute("Seam", seam)
		sell:SetAttribute("ZoneId", zone.id)
	end
	local shop = folder:FindFirstChild("shop_depth")
	if shop and shop:IsA("BasePart") then
		shop.Size = Vector3.new(size * 3.2, size * 2.2, size * 3.2)
		shop.CFrame = CFrame.new(shopPos)
		shop.Transparency = 1
		shop.CanCollide = false
		shop:SetAttribute("Machine", "depth_shop")
		shop:SetAttribute("DepthShop", desk)
		shop:SetAttribute("Seam", seam)
		shop:SetAttribute("ZoneId", zone.id)
	end
	-- Return / continue pads near shaft side
	local sx, sz = shaftXZ(zone)
	local ret = folder:FindFirstChild("return_surface")
	if ret and ret:IsA("BasePart") then
		ret.CFrame = CFrame.new(sx, y + 1.2, sz) * CFrame.new(0, 0, 8)
		ret.Transparency = 1
		ret.CanCollide = false
	end
	local shaftPad = folder:FindFirstChild("mineshaft")
	if shaftPad and shaftPad:IsA("BasePart") then
		shaftPad.CFrame = CFrame.new(sx, y + 1.2, sz)
		shaftPad.Transparency = 1
		shaftPad.CanCollide = false
		shaftPad:SetAttribute("Machine", "mineshaft")
		shaftPad:SetAttribute("ZoneId", zone.id)
		shaftPad:SetAttribute("Seam", seam)
	end

	-- Outpost name billboard
	if not folder:FindFirstChild("OutpostSign") then
		local sign = Instance.new("Part")
		sign.Name = "OutpostSign"
		sign.Anchored = true
		sign.CanCollide = false
		sign.Size = Vector3.new(14, 4.5, 0.5)
		sign.CFrame = CFrame.new(at(hole + 70, 0, y + 10))
		sign.Material = Enum.Material.Wood
		sign.Color = Color3.fromRGB(58, 42, 26)
		sign.Parent = folder
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(360, 100)
		bb.StudsOffset = Vector3.new(0, 1, 0)
		bb.MaxDistance = 100
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
end

-- Seal the depth outpost in a rock shell so exploit TPs into open air don't "load" free mine.
--[[
	THE STATION BAY.

	Owner, 2026-10-05: outposts want "extra space behind it for another station
	incase we use it for something special (High teir enchanters, pack recyclers
	shit like that idk)".

	So the room is built deeper than it needs to be and the extra depth is left
	EMPTY, with a floor and a sign and nothing else. It is one room rather than
	an alcove behind a doorway: a walled-off annexe reads as a locked area a
	player should be trying to get into, and this is not content yet.

	Which way is "behind": zoneAxes already defines `back` as pointing at the
	world origin, and the elevator shaft sits on the `side` axis, so the back is
	the one wall nothing else is using. The walls here are world-axis aligned, so
	the bay extends along whichever world axis `back` leans hardest on.

	BAY_DEPTH is the only dial. It buys floor, not features -- when a station
	does land here it needs no change to this function, only something parented
	into the StationBay folder.
]]
local BAY_DEPTH = 28

--[[
	DEEPER OUTPOSTS LOOK DEEPER.

	Owner, 2026-10-05: "do each outpost from 1-10 look deeper and deeper".
	Measured before answering: they did not. Seam 500, 2500 and 5000 were
	byte-identical -- same eleven PointLights, same twenty-one neon parts, same
	wall colour -- because every outpost is the same surface template cloned to a
	different Y and every colour in this file is a constant. docs/OPEN.md item 6
	has asked for "underground-themed, deeper and darker at every seam" the whole
	time.

	One function drives it, from a single 0..1 across the reachable ladder, so
	the progression cannot drift between the pieces that use it:

	  WALLS AND FLOOR darken toward rock. The top outpost keeps today's colour so
	  nothing regresses; only the deeper ones move.

	  LIGHT dims and warms. 500 is lantern-lit and legible; 5000 is a hole with
	  embers in it. Dimming bottoms out at 55% rather than going dark -- an
	  outpost is somewhere you read prices and press buttons, so atmosphere stops
	  where usability starts.

	Deliberately NOT touched: neon. The cyan ring and the signage are wayfinding,
	and a player who cannot find the elevator at 5000 is not being immersed, they
	are lost.
]]
local function depthLook(seam)
	local first = (Depth.SEAMS and Depth.SEAMS[1]) or 500
	local floor = tonumber(C.LAYERS) or 5000
	local span = math.max(1, floor - first)
	local t = math.clamp(((tonumber(seam) or first) - first) / span, 0, 1)
	-- ease toward the deep end so the first few steps are not all the change
	local e = t * t * (3 - 2 * t)
	local function mix(a, b)
		return a + (b - a) * e
	end
	return {
		t = t,
		wall = Color3.fromRGB(
			math.floor(mix(48, 20)), math.floor(mix(42, 18)), math.floor(mix(36, 17))),
		deck = Color3.fromRGB(
			math.floor(mix(58, 26)), math.floor(mix(52, 23)), math.floor(mix(45, 21))),
		lightMul = mix(1, 0.55),
		rangeMul = mix(1, 0.82),
		-- daylight-ish lantern at the top, ember at the bottom
		lightTint = Color3.fromRGB(
			255, math.floor(mix(244, 186)), math.floor(mix(224, 128))),
	}
end

--[[
	Push the look onto whatever the surface clone brought with it.

	The lights are not ours -- they arrive inside SurfaceClone -- so this walks
	them after dressing rather than trying to build them. Multiplicative against
	each light's own authored values, so a lamp that was always dim stays
	relatively dim instead of every light collapsing onto one number.
]]
local function tintOutpostLights(folder, look)
	local clone = folder and folder:FindFirstChild("SurfaceClone")
	if not (clone and look) then
		return 0
	end
	local n = 0
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
			local baseB = d:GetAttribute("BaseBrightness")
			local baseR = d:GetAttribute("BaseRange")
			if not baseB then
				baseB = d.Brightness
				d:SetAttribute("BaseBrightness", baseB)
			end
			if not baseR then
				baseR = d.Range
				d:SetAttribute("BaseRange", baseR)
			end
			d.Brightness = baseB * look.lightMul
			d.Range = baseR * look.rangeMul
			d.Color = look.lightTint
			n += 1
		end
	end
	return n
end

local function wallOutpost(folder, zone, seam)
	if not folder then
		return
	end
	local old = folder:FindFirstChild("OutpostWalls")
	if old then
		old:Destroy()
	end
	local oldBay = folder:FindFirstChild("StationBay")
	if oldBay then
		oldBay:Destroy()
	end
	local clone = folder:FindFirstChild("SurfaceClone")
	local square = clone and clone:FindFirstChild("Square")
	if not (square and square:IsA("BasePart")) then
		return
	end
	local walls = Instance.new("Folder")
	walls.Name = "OutpostWalls"
	walls.Parent = folder

	-- Which world axis the bay grows along, and which way down it.
	local bx, bz = 0, 1
	if zone then
		local _o, _d, _s, back = zoneAxes(zone)
		if math.abs(back.X) >= math.abs(back.Z) then
			bx, bz = (back.X >= 0 and 1 or -1), 0
		else
			bx, bz = 0, (back.Z >= 0 and 1 or -1)
		end
	end

	local cx, cy, cz = square.Position.X, square.Position.Y, square.Position.Z
	local sx = square.Size.X + 20
	local sz = square.Size.Z + 20
	-- Grow the room along the back axis and push its centre half that far the
	-- same way, so every extra stud lands BEHIND the shop rather than around it.
	if bx ~= 0 then
		sx += BAY_DEPTH
		cx += bx * BAY_DEPTH * 0.5
	else
		sz += BAY_DEPTH
		cz += bz * BAY_DEPTH * 0.5
	end
	local wallH = 32
	local thick = 4
	local floorY = cy - square.Size.Y * 0.5
	local midY = floorY + wallH * 0.5
	local look = depthLook(seam)
	local col = look.wall
	local function wall(name, size, cf)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = true
		p.CanQuery = true
		p.Material = Enum.Material.Slate
		p.Color = col
		p.Size = size
		p.CFrame = cf
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = walls
		return p
	end
	wall("WallN", Vector3.new(sx + thick * 2, wallH, thick), CFrame.new(cx, midY, cz + sz * 0.5))
	wall("WallS", Vector3.new(sx + thick * 2, wallH, thick), CFrame.new(cx, midY, cz - sz * 0.5))
	wall("WallE", Vector3.new(thick, wallH, sz), CFrame.new(cx + sx * 0.5, midY, cz))
	wall("WallW", Vector3.new(thick, wallH, sz), CFrame.new(cx - sx * 0.5, midY, cz))
	wall("Ceiling", Vector3.new(sx + thick * 2, thick, sz + thick * 2), CFrame.new(cx, floorY + wallH, cz))
	-- Floor plate under square so you never drop through streaming gaps.
	wall("Floor", Vector3.new(sx, thick, sz), CFrame.new(cx, floorY - thick * 0.5, cz))

	--[[
		The reserved floor itself: a deck the player can stand on, a sign saying
		what it is for, and nothing else. Parented to StationBay rather than
		OutpostWalls so that dropping a station in later means adding a child
		here, not editing this function.
	]]
	local bay = Instance.new("Folder")
	bay.Name = "StationBay"
	bay.Parent = folder
	-- Centre of the extra depth, measured from the ORIGINAL square outward.
	local halfOld = (bx ~= 0) and (square.Size.X + 20) * 0.5 or (square.Size.Z + 20) * 0.5
	local bayMid = halfOld + BAY_DEPTH * 0.5
	local bcx = square.Position.X + (bx ~= 0 and bx * bayMid or 0)
	local bcz = square.Position.Z + (bx == 0 and bz * bayMid or 0)
	local bayW = (bx ~= 0) and sz or sx

	local deck = Instance.new("Part")
	deck.Name = "BayDeck"
	deck.Anchored = true
	deck.CanCollide = true
	deck.Material = Enum.Material.Slate
	deck.Color = look.deck
	deck.Size = Vector3.new(
		(bx ~= 0) and BAY_DEPTH - 4 or bayW - 8,
		1,
		(bx ~= 0) and bayW - 8 or BAY_DEPTH - 4)
	deck.CFrame = CFrame.new(bcx, floorY + 0.5, bcz)
	deck.TopSurface = Enum.SurfaceType.Smooth
	deck.BottomSurface = Enum.SurfaceType.Smooth
	deck.Parent = bay

	local sign = Instance.new("Part")
	sign.Name = "BaySign"
	sign.Anchored = true
	sign.CanCollide = false
	sign.Material = Enum.Material.Metal
	sign.Color = Color3.fromRGB(38, 34, 30)
	sign.Size = Vector3.new(
		(bx ~= 0) and 0.4 or 10,
		3,
		(bx ~= 0) and 10 or 0.4)
	-- Flat against the far wall, facing back into the room.
	local wallIn = bayMid + BAY_DEPTH * 0.5 - 2
	sign.CFrame = CFrame.new(
		square.Position.X + (bx ~= 0 and bx * wallIn or 0),
		floorY + 5,
		square.Position.Z + (bx == 0 and bz * wallIn or 0))
	sign.Parent = bay

	local sg = Instance.new("SurfaceGui")
	sg.Face = (bx ~= 0) and (bx > 0 and Enum.NormalId.Left or Enum.NormalId.Right)
		or (bz > 0 and Enum.NormalId.Front or Enum.NormalId.Back)
	sg.AlwaysOnTop = false
	sg.PixelsPerStud = 40
	sg.Parent = sign
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextScaled = true
	lbl.TextColor3 = Color3.fromRGB(150, 140, 125)
	lbl.Text = "RESERVED"
	lbl.Parent = sg
end

function buildDeck(zone, seam, desk)
	local world = workspace:FindFirstChild("MineWorld")
	local pits = world and world:FindFirstChild("Pits")
	if not pits then
		return nil
	end
	local name = "DepthPlaza_" .. zone.id .. "_" .. tostring(seam)
	local existing = pits:FindFirstChild(name)
	if existing then
		if existing:GetAttribute("LayoutVer") ~= LAYOUT_VER then
			existing:Destroy()
			existing = nil
		else
			dressOutpostFromSurface(existing, zone, seam, desk)
			wallOutpost(existing, zone, seam)
			tintOutpostLights(existing, depthLook(seam))
			return existing
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder:SetAttribute("ZoneId", zone.id)
	folder:SetAttribute("Seam", seam)
	folder:SetAttribute("LayoutVer", LAYOUT_VER)
	folder.Parent = pits
	local origin = C.zoneOrigin(zone)
	local y = seamY(zone, seam)
	local size = C.BLOCK or 5
	local offset = size * 2.5

	local sell = makePad(folder, "sell_depth", Vector3.new(size * 3.2, size * 2.2, size * 3.2),
		CFrame.new(origin.X - offset, y + size, origin.Z - offset), {
			Machine = "sell",
			SellDesk = desk,
			Seam = seam,
			ZoneId = zone.id,
		})
	sell.Transparency = 1
	sell.CanCollide = false
	addPrompt(sell, "Sell (depth)")

	local shop = makePad(folder, "shop_depth", Vector3.new(size * 3.2, size * 2.2, size * 3.2),
		CFrame.new(origin.X + offset, y + size, origin.Z - offset), {
			Machine = "depth_shop",
			DepthShop = desk,
			Seam = seam,
			ZoneId = zone.id,
		})
	shop.Transparency = 1
	shop.CanCollide = false
	addPrompt(shop, "Depth shop")

	local ret = makePad(folder, "return_surface", Vector3.new(size * 2.2, 1.2, size * 2.2),
		CFrame.new(origin.X - offset, y + 1.1, origin.Z + offset), {
			Destination = "surface",
			ZoneId = zone.id,
		})
	ret.Transparency = 1
	ret.CanCollide = false
	addPrompt(ret, "Return to surface")

	local shaft = makePad(folder, "mineshaft", Vector3.new(size * 2.2, 1.2, size * 2.2),
		CFrame.new(origin.X + offset, y + 1.1, origin.Z + offset), {
			Machine = "mineshaft",
			ZoneId = zone.id,
			Seam = seam,
		})
	shaft.Transparency = 1
	shaft.CanCollide = false
	addPrompt(shaft, "Continue down")

	do
		local _o, _d, _s, back, hole = zoneAxes(zone)
		local boardCf = CFrame.lookAt(
			origin + back * (hole + 88) + Vector3.new(0, y - origin.Y + 8, 0),
			origin + Vector3.new(0, y - origin.Y + 8, 0)
		)
		stubBoard(folder, boardCf, "The " .. tostring(seam) .. " Depth Outpost", zone.id)
	end

	dressOutpostFromSurface(folder, zone, seam, desk)
	wallOutpost(folder, zone, seam)
	tintOutpostLights(folder, depthLook(seam))
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
	gui.MaxDistance = 100
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

function MineDepthPlazas.openAllForPreview()
	for _, zone in ipairs(C.ZONES or {}) do
		pcall(buildElevator, zone)
		for _, seam in ipairs(Depth.SEAMS or {}) do
			local desk = Depth.bandUnlockKey(seam)
			if desk and desk ~= "soon" then
				pcall(buildDeck, zone, seam, desk)
			elseif seam == (Depth.COMING_SOON_SEAM or 2500) then
				-- Still build a real plaza for preview when desk is soon
				pcall(buildDeck, zone, seam, "shadowzone")
			end
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
	if desk == "soon" then
		buildComingSoon(zone, seam)
	else
		buildDeck(zone, seam, desk)
	end
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

function MineDepthPlazas.onDepthCredit(zoneId, deepest)
	MineDepthPlazas.onLayerBroken(zoneId, deepest)
end

return MineDepthPlazas
