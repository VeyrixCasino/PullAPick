-- MineZoneMapView: swipeable planet map (UI only).
-- Horizontal strip, planets vertically centered, themed orbs, dotted routes.

local MineZoneMapView = {}

local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared:WaitForChild("MineConfig"))
local ZoneChests = require(shared:WaitForChild("MineZoneChests"))
local ZonePacks = require(shared:WaitForChild("MineZonePacks"))
local Tools = require(shared:WaitForChild("MineTools"))
local PetRoster = require(shared:WaitForChild("MinePetRoster"))
local PetBoosts = require(shared:WaitForChild("MinePetBoosts"))

local FONT = Enum.Font.GothamBold
local FONT_BLACK = Enum.Font.GothamBlack
local TEXT = Color3.fromRGB(236, 232, 224)
local MUTED = Color3.fromRGB(150, 148, 160)
local GOLD = Color3.fromRGB(255, 196, 64)
local SPACE = Color3.fromRGB(6, 8, 16)

local PLANET_SIZE = 128
local PLANET_GAP = 150
local STRIP_PAD = 100

local function mk(className, props, parent)
	local i = Instance.new(className)
	if props then
		for k, v in pairs(props) do i[k] = v end
	end
	i.Parent = parent
	return i
end

local function round(gui, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = gui
end

local function circle(gui)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = gui
end

local function pct(n)
	n = tonumber(n) or 0
	if n <= 0 then return "0%" end
	if n < 0.01 then return string.format("%.3f%%", n) end
	if n < 1 then return string.format("%.2f%%", n) end
	return string.format("%.1f%%", n)
end

local function chanceFromWeight(w, total)
	if not total or total <= 0 then return 0 end
	return (tonumber(w) or 0) / total * 100
end

local function zoneUnlocked(snap, index, zone)
	local have = math.max(1, tonumber(snap.maxUnlockedZone) or 1)
	if zone.limited then
		return snap.bigbangOwned == true or snap.limitedActive == true
	end
	return index <= have
end

local function foundChest(snap, chestId)
	-- Same ledger Collection → Chests uses: profile.found[chestId] > 0.
	if not snap or chestId == nil then return false end
	local f = snap.found or {}
	local id = tostring(chestId)
	local n = f[id] or f[chestId]
	if (tonumber(n) or 0) > 0 or n == true then
		return true
	end
	-- Bag still holding one counts as discovered (matches Collection "held").
	for _, item in ipairs(snap.backpack or {}) do
		if type(item) == "table" and (item.kind == "chest" or item.kind == "crate") then
			if tostring(item.chestId or item.id) == id then
				return true
			end
		end
	end
	return false
end

-- The pet's real kit. This read the old X bag directly, so it showed numbers
-- no pet had paid since the zone kits (2026-10-10).
local function boostFor(name)
	return PetBoosts.boostsFor and PetBoosts.boostsFor(name) or nil
end

local function formatBoosts(b)
	if type(b) ~= "table" then return "—" end
	local parts = {}
	for k, v in pairs(b) do
		if type(v) == "number" then
			table.insert(parts, string.format("%s +%d%%", tostring(k), math.floor(v * 100 + 0.5)))
		end
	end
	table.sort(parts)
	return #parts > 0 and table.concat(parts, " · ") or "—"
end

local function chestPoolOdds(zoneId)
	local pool = ZoneChests.POOLS and ZoneChests.POOLS[zoneId] or {}
	local total = 0
	for _, row in ipairs(pool) do total += (row.weight or row.w or 1) end
	local out = {}
	for _, row in ipairs(pool) do
		local id = row.chestId or row.id
		local def = ZoneChests.def and ZoneChests.def(id)
		table.insert(out, {
			id = id,
			name = (def and def.name) or id,
			chance = chanceFromWeight(row.weight or row.w or 1, total),
			def = def,
		})
	end
	return out
end

local function secretToolsForZone(zoneId)
	local out, seen = {}, {}
	for _, band in ipairs({ "a", "b", "c", "shallow", "mid", "deep" }) do
		local drops = (Tools.dropsForBand and Tools.dropsForBand(zoneId, band)) or {}
		for _, d in ipairs(drops) do
			if d and d.id and not seen[d.id] then
				seen[d.id] = true
				table.insert(out, d)
			end
		end
	end
	return out
end

local function packsForZone(zoneId)
	local out = {}
	for _, pk in pairs(ZonePacks.PACKS or {}) do
		if type(pk) == "table" and pk.zoneId == zoneId then
			table.insert(out, pk)
		end
	end
	table.sort(out, function(a, b)
		return tostring(a.slot or a.id) < tostring(b.slot or b.id)
	end)
	return out
end

local function petsSample()
	local byTier = {}
	for _, pet in ipairs(PetRoster.PETS or {}) do
		local t = pet.tier or "Common"
		byTier[t] = byTier[t] or {}
		if #byTier[t] < 2 then table.insert(byTier[t], pet) end
	end
	local out = {}
	for _, tier in ipairs(PetRoster.TIER_ORDER or {}) do
		for _, pet in ipairs(byTier[tier] or {}) do table.insert(out, pet) end
	end
	return out
end

-- Themed planet orb. No grey plate — just the sphere + thin select ring.
local function buildPlanet(parent, zone, unlocked, selected, size)
	size = size or PLANET_SIZE
	local col = zone.color or Color3.fromRGB(140, 140, 160)
	local dirt = zone.dirt or col:Lerp(Color3.new(0, 0, 0), 0.3)
	local lit = col:Lerp(Color3.new(1, 1, 1), 0.35)

	local wrap = mk("Frame", {
		Name = "Planet_" .. zone.id,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size + 8, size + 40),
	}, parent)

	-- Atmosphere halo (soft, no hard box)
	if unlocked then
		local atm = mk("Frame", {
			BackgroundColor3 = col,
			BackgroundTransparency = 0.78,
			Size = UDim2.fromOffset(size + 18, size + 18),
			Position = UDim2.fromOffset(-5, -5),
			ZIndex = 1,
		}, wrap)
		circle(atm)
	end

	local orb = mk("TextButton", {
		Name = "Orb",
		BackgroundColor3 = unlocked and dirt or Color3.fromRGB(22, 22, 28),
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(size, size),
		Position = UDim2.fromOffset(4, 4),
		ZIndex = 2,
	}, wrap)
	circle(orb)

	-- Continent / biome patches
	if unlocked then
		local p1 = mk("Frame", {
			BackgroundColor3 = col,
			BackgroundTransparency = 0.12,
			Size = UDim2.new(0.42, 0, 0.28, 0),
			Position = UDim2.new(0.12, 0, 0.22, 0),
			Rotation = -18,
			ZIndex = 3,
		}, orb)
		round(p1, 14)
		local p2 = mk("Frame", {
			BackgroundColor3 = col:Lerp(dirt, 0.4),
			BackgroundTransparency = 0.2,
			Size = UDim2.new(0.34, 0, 0.22, 0),
			Position = UDim2.new(0.48, 0, 0.52, 0),
			Rotation = 22,
			ZIndex = 3,
		}, orb)
		round(p2, 12)
		local p3 = mk("Frame", {
			BackgroundColor3 = lit,
			BackgroundTransparency = 0.55,
			Size = UDim2.new(0.26, 0, 0.16, 0),
			Position = UDim2.new(0.2, 0, 0.62, 0),
			ZIndex = 3,
		}, orb)
		round(p3, 10)
	end

	-- Specular highlight (sphere read)
	local spec = mk("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = unlocked and 0.72 or 0.9,
		Size = UDim2.new(0.38, 0, 0.22, 0),
		Position = UDim2.new(0.16, 0, 0.1, 0),
		ZIndex = 4,
	}, orb)
	circle(spec)

	-- Night side crescent
	local shade = mk("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = unlocked and 0.55 or 0.35,
		Size = UDim2.new(0.55, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		ZIndex = 5,
	}, orb)

	if not unlocked then
		local veil = mk("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.4,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 6,
		}, orb)
		circle(veil)
	end

	-- Select ring only (no permanent grey stroke)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "Ring"
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = GOLD
	stroke.Thickness = 3
	stroke.Transparency = selected and 0 or 1
	stroke.Parent = orb

	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT_BLACK,
		TextSize = 14,
		TextColor3 = unlocked and TEXT or MUTED,
		TextStrokeTransparency = 0.35,
		Text = unlocked and (zone.name or zone.id) or "???",
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 1, -24),
		ZIndex = 7,
	}, wrap)

	return wrap, orb, stroke
end

local function drawDots(parent, x0, x1, y, color)
	local dist = math.abs(x1 - x0)
	local n = math.max(5, math.floor(dist / 16))
	for i = 1, n do
		local t = i / (n + 1)
		local x = x0 + (x1 - x0) * t
		local d = mk("Frame", {
			Name = "Dot",
			BackgroundColor3 = color,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(5, 5),
			Position = UDim2.fromOffset(math.floor(x - 2.5), y - 2),
			ZIndex = 1,
		}, parent)
		circle(d)
	end
end

function MineZoneMapView.render(body, opts)
	opts = opts or {}
	local snap = opts.snap
	if not body or not snap then return end

	for _, ch in ipairs(body:GetChildren()) do
		ch:Destroy()
	end

	local function viewport()
		local w = body.AbsoluteSize.X
		local h = body.AbsoluteSize.Y
		if w < 80 then w = 640 end
		if h < 80 then h = 480 end
		return math.floor(w), math.floor(h)
	end
	local vw, vh = viewport()
	if body:IsA("ScrollingFrame") then
		body.ScrollingEnabled = false
		body.AutomaticCanvasSize = Enum.AutomaticSize.None
		body.CanvasSize = UDim2.fromOffset(vw, vh)
		body.ScrollBarThickness = 0
	end

	local root = mk("Frame", {
		Name = "PlanetMap",
		BackgroundColor3 = SPACE,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(vw, vh),
		ZIndex = 32,
	}, body)
	round(root, 12)

	local function fitRoot()
		local w, h = viewport()
		root.Size = UDim2.fromOffset(w, h)
		if body:IsA("ScrollingFrame") then
			body.CanvasSize = UDim2.fromOffset(w, h)
		end
	end
	body:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitRoot)
	task.defer(fitRoot)

	for i = 1, 48 do
		local s = mk("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.5 + (i % 5) * 0.08,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(2 + (i % 3), 2 + (i % 3)),
			Position = UDim2.new((i * 0.137) % 1, 0, (i * 0.221) % 1, 0),
			ZIndex = 32,
		}, root)
		circle(s)
	end

	-- Map strip = top 58%, planets VERTICALLY CENTERED inside it.
	local stripHScale = 0.58
	local strip = mk("ScrollingFrame", {
		Name = "PlanetStrip",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.new(1, 0, stripHScale, 0),
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = GOLD,
		ElasticBehavior = Enum.ElasticBehavior.Always,
		CanvasSize = UDim2.new(),
		ZIndex = 33,
		Active = true,
	}, root)

	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 12,
		TextColor3 = MUTED,
		Text = "←  swipe planets  →",
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.fromOffset(0, 6),
		ZIndex = 50,
	}, strip)

	local track = mk("Frame", {
		Name = "Track",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		ZIndex = 33,
	}, strip)

	local zones = C.ZONES or {}
	local selected = opts.selectedZoneId or (zones[1] and zones[1].id)
	local planetNodes = {}

	local totalW = STRIP_PAD * 2 + #zones * PLANET_SIZE + math.max(0, #zones - 1) * PLANET_GAP
	track.Size = UDim2.new(0, totalW, 1, 0)
	strip.CanvasSize = UDim2.fromOffset(totalW, 0)

	local routeLayer = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 33,
	}, track)

	-- Center line for dots: half of strip height (planets sit on this)
	local function dotY()
		return math.floor((strip.AbsoluteSize.Y > 0 and strip.AbsoluteSize.Y or vh * stripHScale) * 0.5)
	end

	for i, zone in ipairs(zones) do
		local cx = STRIP_PAD + (i - 1) * (PLANET_SIZE + PLANET_GAP) + PLANET_SIZE * 0.5
		local unlocked = zoneUnlocked(snap, i, zone)
		local wrap, orb, stroke = buildPlanet(track, zone, unlocked, selected == zone.id, PLANET_SIZE)
		wrap.AnchorPoint = Vector2.new(0.5, 0.5)
		-- Dead center of the strip
		wrap.Position = UDim2.new(0, cx, 0.5, 0)
		wrap.ZIndex = 35
		planetNodes[i] = { zone = zone, wrap = wrap, orb = orb, stroke = stroke, cx = cx, unlocked = unlocked }

		if i > 1 then
			local prev = planetNodes[i - 1]
			local col = (unlocked or prev.unlocked) and (zone.color or GOLD):Lerp(Color3.new(1, 1, 1), 0.25)
				or Color3.fromRGB(80, 80, 96)
			drawDots(routeLayer, prev.cx + PLANET_SIZE * 0.48, cx - PLANET_SIZE * 0.48, dotY(), col)
		end
	end

	-- Re-lay dots once AbsoluteSize is known so they sit on the planet midline
	task.defer(function()
		for _, ch in ipairs(routeLayer:GetChildren()) do ch:Destroy() end
		local y = dotY()
		for i = 2, #planetNodes do
			local prev, node = planetNodes[i - 1], planetNodes[i]
			local col = (node.unlocked or prev.unlocked) and (node.zone.color or GOLD):Lerp(Color3.new(1, 1, 1), 0.25)
				or Color3.fromRGB(80, 80, 96)
			drawDots(routeLayer, prev.cx + PLANET_SIZE * 0.48, node.cx - PLANET_SIZE * 0.48, y, col)
		end
	end)

	local card = mk("ScrollingFrame", {
		Name = "PlanetCard",
		BackgroundColor3 = Color3.fromRGB(14, 16, 24),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 10, stripHScale, 6),
		Size = UDim2.new(1, -20, 1 - stripHScale, -16),
		ScrollBarThickness = 5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 40,
	}, root)
	round(card, 12)
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(50, 54, 70)
	cardStroke.Thickness = 1
	cardStroke.Parent = card
	mk("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, card)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, card)

	local function setSelectedVisual(zoneId)
		for _, node in ipairs(planetNodes) do
			local on = node.zone.id == zoneId
			node.stroke.Transparency = on and 0 or 1
			node.stroke.Color = GOLD
			if on then
				TweenService:Create(node.wrap, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.fromOffset(PLANET_SIZE + 20, PLANET_SIZE + 52),
				}):Play()
			else
				node.wrap.Size = UDim2.fromOffset(PLANET_SIZE + 8, PLANET_SIZE + 40)
			end
		end
	end

	local function scrollToPlanet(index)
		local node = planetNodes[index]
		if not node then return end
		local viewW = strip.AbsoluteSize.X
		if viewW <= 0 then viewW = vw end
		local target = math.max(0, node.cx - viewW * 0.5)
		TweenService:Create(strip, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CanvasPosition = Vector2.new(target, 0),
		}):Play()
	end

	local function paintCard(zone)
		for _, ch in ipairs(card:GetChildren()) do
			if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
				ch:Destroy()
			end
		end
		if not zone then return end
		local zi = (C.zoneIndex and C.zoneIndex(zone.id)) or 1
		local unlocked = zoneUnlocked(snap, zi, zone)
		local deep = (snap.deepest and (snap.deepest[zone.id] or snap.deepest[tostring(zone.id)])) or 0
		local col = zone.color or GOLD
		local chestChance = (C.CHEST_CHANCE or 0.003) * 100

		local head = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 64), LayoutOrder = 1 }, card)
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT_BLACK, TextSize = 24,
			TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = col,
			Text = zone.name or zone.id, Size = UDim2.new(1, 0, 0, 30),
		}, head)
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = MUTED,
			Text = string.format("Depth %d / %d · R%d · block→chest %s%s",
				deep, C.LAYERS or 0, zone.minRebirth or zone.prestige or 0,
				pct(chestChance),
				unlocked and "" or " · locked"),
			Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 18),
		}, head)

		local actions = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), LayoutOrder = 2 }, card)
		mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, actions)
		local camp = mk("TextButton", {
			BackgroundColor3 = Color3.fromRGB(58, 56, 70), Font = FONT, TextSize = 14,
			TextColor3 = TEXT, Text = "Camp", Size = UDim2.fromOffset(84, 34), AutoButtonColor = true,
		}, actions)
		round(camp, 8)
		camp.MouseButton1Click:Connect(function()
			if opts.onCamp then opts.onCamp() end
		end)
		if unlocked then
			local go = mk("TextButton", {
				BackgroundColor3 = GOLD, Font = FONT_BLACK, TextSize = 14,
				TextColor3 = Color3.fromRGB(30, 24, 10), Text = "Travel",
				Size = UDim2.fromOffset(100, 34), AutoButtonColor = true,
			}, actions)
			round(go, 8)
			go.MouseButton1Click:Connect(function()
				if opts.onEnter then opts.onEnter(zone.id) end
			end)
		elseif (not zone.limited) and zi == (math.max(1, tonumber(snap.maxUnlockedZone) or 1) + 1) then
			local cost = math.floor(tonumber(zone.buyCost) or 0)
			local buy = mk("TextButton", {
				BackgroundColor3 = Color3.fromRGB(80, 160, 255), Font = FONT_BLACK, TextSize = 14,
				TextColor3 = TEXT, Text = "Buy " .. tostring(cost) .. "g",
				Size = UDim2.fromOffset(140, 34), AutoButtonColor = true,
			}, actions)
			round(buy, 8)
			buy.MouseButton1Click:Connect(function()
				if opts.onBuy then opts.onBuy(zone) end
			end)
		end

		local function section(title, order)
			mk("TextLabel", {
				BackgroundTransparency = 1, Font = FONT_BLACK, TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD,
				Text = title, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = order,
			}, card)
		end

		local function row(order, labelText, oddsText, blacked, detail)
			local btn = mk("TextButton", {
				BackgroundColor3 = blacked and Color3.fromRGB(14, 14, 18) or Color3.fromRGB(36, 38, 50),
				Font = FONT, TextSize = 12,
				TextColor3 = blacked and MUTED or TEXT,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = "  " .. (blacked and "???" or labelText) .. "   " .. (oddsText or ""),
				Size = UDim2.new(1, 0, 0, 32), LayoutOrder = order, AutoButtonColor = true,
			}, card)
			round(btn, 8)
			if detail then
				local open, detailFrame = false, nil
				btn.MouseButton1Click:Connect(function()
					open = not open
					if open then
						detailFrame = mk("TextLabel", {
							BackgroundColor3 = Color3.fromRGB(24, 24, 32),
							Font = FONT, TextSize = 11, TextColor3 = MUTED,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Top,
							TextWrapped = true, Text = detail,
							Size = UDim2.new(1, 0, 0, 0),
							AutomaticSize = Enum.AutomaticSize.Y,
							LayoutOrder = order + 0.5,
						}, card)
						round(detailFrame, 8)
						mk("UIPadding", {
							PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
							PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
						}, detailFrame)
					elseif detailFrame then
						detailFrame:Destroy()
						detailFrame = nil
					end
				end)
			end
		end

		-- EVERY chest this planet can roll: ZoneChests.collectionRows filtered by zone.
		local pool = ZoneChests.POOLS and ZoneChests.POOLS[zone.id] or {}
		local poolW, poolWeight = 0, {}
		for _, pr in ipairs(pool) do
			local id = pr.chestId or pr.id
			local w = pr.weight or pr.w or 1
			poolW += w
			poolWeight[id] = (poolWeight[id] or 0) + w
		end
		-- Section exclusive shares the roll pool as +1 weight next to vanity.
		local poolSlots = poolW + 1

		local allChests = {}
		for _, crow in ipairs(ZoneChests.collectionRows and ZoneChests.collectionRows() or {}) do
			local hit = false
			for _, z in ipairs(crow.zones or {}) do
				local zid = type(z) == "table" and z.zoneId or z
				if zid == zone.id then hit = true break end
			end
			if hit then
				table.insert(allChests, crow)
			end
		end
		table.sort(allChests, function(a, b)
			return tostring(a.name or a.id) < tostring(b.name or b.id)
		end)

		local foundN = 0
		for _, crow in ipairs(allChests) do
			if foundChest(snap, crow.id) then foundN += 1 end
		end

		section(string.format("Chests · Collection %d / %d · tap for odds", foundN, #allChests), 10)
		local order = 11
		for _, crow in ipairs(allChests) do
			local id = crow.id
			local def = ZoneChests.def and ZoneChests.def(id) or ZoneChests.DEFS and ZoneChests.DEFS[id]
			local seen = foundChest(snap, id)
			local isSec = type(id) == "string" and id:find("^sec_chest_") ~= nil
			local oddsLabel
			if poolWeight[id] then
				oddsLabel = pct(poolWeight[id] / poolSlots * 100) .. " of rolls"
			elseif isSec then
				oddsLabel = pct(1 / poolSlots * 100) .. " section"
			else
				oddsLabel = "zone loot"
			end
			local lines = {
				string.format("When a chest spawns on this planet (%s of blocks):", pct(chestChance)),
				string.format("This chest: %s", oddsLabel),
			}
			if def and type(def.packs) == "table" then
				table.insert(lines, "Pack / currency pulls:")
				for _, pk in ipairs(def.packs) do
					table.insert(lines, string.format("  %s  %s",
						seen and (pk.slot or "?") or "???",
						pct(tonumber(pk.chance) or 0)))
				end
			end
			if def and def.coins then
				table.insert(lines, string.format("Coins %s–%s", tostring(def.coins[1] or "?"), tostring(def.coins[2] or "?")))
			end
			if def and def.gems then
				table.insert(lines, string.format("Gems %s–%s", tostring(def.gems[1] or "?"), tostring(def.gems[2] or "?")))
			end
			row(order, crow.name or id, oddsLabel, not seen, table.concat(lines, "\n"))
			order += 1
		end

		-- The zone panel listed which fossils a zone could drop. Fossils are
		-- retired and both modules are deleted, so there is nothing to list.
	end

local function selectZone(zone, index)
		selected = zone.id
		if opts.onSelect then opts.onSelect(zone.id) end
		setSelectedVisual(zone.id)
		paintCard(zone)
		scrollToPlanet(index)
	end

	for i, node in ipairs(planetNodes) do
		node.orb.MouseButton1Click:Connect(function()
			selectZone(node.zone, i)
		end)
	end

	local startIndex = 1
	for i, z in ipairs(zones) do
		if z.id == selected then startIndex = i break end
	end
	selectZone(zones[startIndex] or zones[1], startIndex)
	task.defer(function()
		scrollToPlanet(startIndex)
	end)
end

return MineZoneMapView
