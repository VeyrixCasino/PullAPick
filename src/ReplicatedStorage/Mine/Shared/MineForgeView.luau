--[[
	MineForgeView: temperaments for tools.

	Icon-first Enchanter Temper tab (and standalone Forge panel). Kids read
	pictures: tool seats, rarity tiles, token chips. Same callbacks as before.
]]
local MineForgeView = {}

local RS = game:GetService("ReplicatedStorage")
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local Temper = require(shared:WaitForChild("MineTemper"))
local Tools = require(shared:WaitForChild("MineTools"))
local T = require(shared:WaitForChild("MineTheme"))
local Icons = require(shared:WaitForChild("MineIcons"))

local BG = T.BG
local BG2 = T.BG2
local BG3 = T.BG3
local TEXT = T.TEXT
local MUTED = T.MUTED
local GOLD = T.GOLD
local GREEN = T.GREEN
local RED = T.RED or Color3.fromRGB(255, 122, 122)
local INK = T.INK
local FONT = T.FONT
local FONT_M = T.FONT_M

local FAMILIES = {
	{ id = "pickaxe", label = "Pick", icon = "pickaxe" },
	{ id = "drill", label = "Drill", icon = "drill" },
	{ id = "explosive", label = "Bomb", icon = "explosive" },
}

local STAT_SHORT = {
	mineSpeed = "Speed",
	swingRate = "Swing",
	dirtBreak = "Dirt",
	blastRadius = "Blast",
	blastChance = "Ore",
	coinBonus = "Coins",
	autoMine = "Auto",
	echo = "Echo",
	zap = "Zap",
}

local function mk(class, props, parent)
	local o = Instance.new(class)
	if o:IsA("GuiObject") then
		o.BorderSizePixel = 0
	end
	for k, v in pairs(props) do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local function round(inst, r)
	mk("UICorner", { CornerRadius = UDim.new(0, r or 10) }, inst)
	return inst
end

local function stroke(inst, thick, color, transparency)
	return mk("UIStroke", {
		Thickness = thick or 1,
		Color = color or Color3.fromRGB(120, 134, 178),
		Transparency = transparency or 0.4,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, inst)
end

local function label(parent, str, size, color, pos, sz, font, align)
	return mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = font or FONT_M,
		TextSize = size or 13,
		TextColor3 = color or TEXT,
		Text = str or "",
		Position = pos or UDim2.new(),
		Size = sz or UDim2.fromScale(1, 1),
		TextXAlignment = align or Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = (parent.ZIndex or 1) + 1,
	}, parent)
end

local function iconImage(parent, id, size, pos)
	local host = mk("Frame", {
		BackgroundTransparency = 1,
		Size = size or UDim2.fromOffset(36, 36),
		Position = pos or UDim2.new(),
		ZIndex = (parent.ZIndex or 1) + 1,
	}, parent)
	if Icons.draw then
		pcall(Icons.draw, host, id, 1)
	elseif Icons.image then
		local img = Icons.image(id)
		if img then
			mk("ImageLabel", {
				BackgroundTransparency = 1,
				Image = img,
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(1, 1),
				ZIndex = host.ZIndex + 1,
			}, host)
		end
	end
	return host
end

local function shortBoosts(temperId, rarity)
	local bits = {}
	for _, line in ipairs(Temper.describe(temperId, rarity) or {}) do
		local name = STAT_SHORT[line.stat] or line.label or "?"
		bits[#bits + 1] = name .. " " .. tostring(line.text or "")
		if #bits >= 2 then
			break
		end
	end
	return table.concat(bits, "  ·  ")
end

function MineForgeView.mountList(parent, opts)
	opts = opts or {}
	local state = {
		tools = {}, toolTempers = {}, toolFamily = "pickaxe", shopInHand = true,
		chestTools = {}, chestTool = nil, tokens = 0, rollCost = nil,
		tempers = {}, gems = 0, casePrice = nil,
	}
	local selectedId = nil
	local lastKey

	local list = mk("ScrollingFrame", {
		Name = "TemperList",
		BackgroundTransparency = 1,
		Position = opts.position or UDim2.fromOffset(0, 0),
		Size = opts.size or UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ZIndex = 41,
	}, parent)
	mk("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	mk("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 2),
	}, list)

	local function sectionTitle(order, title, sub)
		local f = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, sub and 40 or 24),
			LayoutOrder = order,
			ZIndex = 42,
		}, list)
		label(f, title, 15, GOLD, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 0, 20), FONT)
		if sub then
			label(f, sub, 12, MUTED, UDim2.fromOffset(4, 20), UDim2.new(1, -8, 0, 16))
		end
		return f
	end

	local paint

	local function caseBanner(order)
		local price = tonumber(state.casePrice) or Temper.CASE_PRICE_TOKENS or 20
		local tokens = tonumber(state.tokens) or 0
		local can = tokens >= price
		local owned = 0
		for _ in pairs(state.tempers or {}) do
			owned += 1
		end

		local c = round(mk("Frame", {
			Size = UDim2.new(1, -4, 0, 108),
			BackgroundColor3 = BG2,
			LayoutOrder = order,
			ZIndex = 42,
		}, list), 14)
		stroke(c, 2, GOLD, 0.25)

		local art = round(mk("Frame", {
			BackgroundColor3 = BG3,
			Position = UDim2.fromOffset(12, 12),
			Size = UDim2.fromOffset(84, 84),
			ZIndex = 43,
		}, c), 12)
		stroke(art, 2, GOLD, 0.35)
		iconImage(art, "case", UDim2.fromOffset(64, 64), UDim2.fromOffset(10, 10))

		label(c, string.upper(tostring(Temper.CASE_NAME or "CASE")), 18, GOLD,
			UDim2.fromOffset(110, 14), UDim2.new(1, -300, 0, 24), FONT)
		label(c, "Open for a random temper  ·  keep it  ·  move it anytime"
			.. (owned > 0 and ("  ·  you have " .. owned) or ""),
			12, MUTED, UDim2.fromOffset(110, 40), UDim2.new(1, -300, 0, 36))

		local open = round(mk("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 14),
			Size = UDim2.fromOffset(168, 44),
			BackgroundColor3 = can and GOLD or Color3.fromRGB(70, 58, 62),
			Text = "",
			AutoButtonColor = can,
			ZIndex = 44,
		}, c), 10)
		iconImage(open, "tokens", UDim2.fromOffset(22, 22), UDim2.fromOffset(12, 11))
		label(open, can and ("OPEN  " .. price) or ("NEED  " .. price), 14,
			can and INK or RED, UDim2.fromOffset(40, 0), UDim2.new(1, -48, 1, 0), FONT)
		if can then
			open.MouseButton1Click:Connect(function()
				if opts.onOpenCase then
					opts.onOpenCase()
				end
			end)
		end

		local bundleN = tonumber(Temper.CASE_BUNDLE_COUNT) or 3
		local bundlePrice = tonumber(Temper.CASE_BUNDLE_TOKENS) or 50
		local canBundle = tokens >= bundlePrice
		local bb = round(mk("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 64),
			Size = UDim2.fromOffset(168, 32),
			BackgroundColor3 = canBundle and Color3.fromRGB(170, 110, 230) or Color3.fromRGB(70, 58, 62),
			Text = "",
			AutoButtonColor = canBundle,
			ZIndex = 44,
		}, c), 8)
		iconImage(bb, "tokens", UDim2.fromOffset(18, 18), UDim2.fromOffset(10, 7))
		label(bb, canBundle and (bundleN .. "×  " .. bundlePrice) or ("NEED  " .. bundlePrice), 12,
			canBundle and INK or RED, UDim2.fromOffset(34, 0), UDim2.new(1, -42, 1, 0), FONT)
		if canBundle then
			bb.MouseButton1Click:Connect(function()
				if opts.onOpenCaseBundle then
					opts.onOpenCaseBundle()
				end
			end)
		end
	end

	local function toolSeats(order)
		local wrap = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 118),
			LayoutOrder = order,
			ZIndex = 42,
		}, list)
		mk("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 10),
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, wrap)

		for i, fam in ipairs(FAMILIES) do
			local tier = tonumber(state.tools[fam.id]) or 0
			local locked = tier < 1
			local tt = state.toolTempers[fam.id] or {}
			local kit = tt.temperId and Temper.kit(tt.temperId) or nil
			local grade = Temper.normalizeRarity and Temper.normalizeRarity(tt.temperRarity or (kit and kit.rarity))
				or tt.temperRarity
			local tint = (not locked and grade and Temper.colorOf and Temper.colorOf(grade))
				or (locked and Color3.fromRGB(60, 54, 50) or Color3.fromRGB(100, 90, 80))
			local rungs = Tools.TOOLS and Tools.TOOLS[fam.id]
			local rung = rungs and rungs[tier]
			local inHand = state.shopInHand and state.toolFamily == fam.id

			local seat = round(mk("TextButton", {
				Size = UDim2.fromOffset(168, 112),
				BackgroundColor3 = locked and BG3 or BG2,
				Text = "",
				AutoButtonColor = not locked,
				LayoutOrder = i,
				ZIndex = 43,
			}, wrap), 12)
			stroke(seat, inHand and 2 or 1.5, inHand and GOLD or tint, inHand and 0.1 or 0.35)

			local thumb = round(mk("Frame", {
				BackgroundColor3 = locked and Color3.fromRGB(28, 24, 22) or tint:Lerp(BG3, 0.55),
				Position = UDim2.fromOffset(12, 12),
				Size = UDim2.fromOffset(56, 56),
				ZIndex = 44,
			}, seat), 10)
			if not locked then
				iconImage(thumb, fam.icon, UDim2.fromOffset(44, 44), UDim2.fromOffset(6, 6))
			else
				label(thumb, "?", 28, MUTED, UDim2.new(), UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center)
			end
			if grade and not locked then
				local chip = round(mk("Frame", {
					BackgroundColor3 = INK,
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(1, -2, 1, -2),
					Size = UDim2.fromOffset(20, 20),
					ZIndex = 46,
				}, thumb), 6)
				stroke(chip, 1, tint, 0.2)
				label(chip, tostring(grade), 11, tint, UDim2.new(), UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center)
			end

			label(seat, fam.label, 14, locked and MUTED or TEXT,
				UDim2.fromOffset(78, 14), UDim2.new(1, -88, 0, 20), FONT)
			local sub = locked and "buy at shop"
				or (kit and ((Temper.wordOf and Temper.wordOf(grade)) or grade or "") .. " " .. kit.name)
				or "empty"
			label(seat, sub, 11, locked and MUTED or tint,
				UDim2.fromOffset(78, 36), UDim2.new(1, -88, 0, 32))
			if not locked and rung then
				label(seat, rung.name or ("T" .. tier), 11, MUTED,
					UDim2.fromOffset(12, 78), UDim2.new(1, -24, 0, 24))
			end

			if not locked then
				seat.MouseButton1Click:Connect(function()
					if selectedId and opts.onFitTemper then
						opts.onFitTemper({ id = selectedId, family = fam.id })
					end
				end)
			end
		end
	end

	local function actionBar(order)
		if not selectedId or not Temper.kit(selectedId) then
			return
		end
		local entry = state.tempers[selectedId]
		if not entry then
			return
		end
		local kit = Temper.kit(selectedId)
		local grade = Temper.normalizeRarity(entry.rarity)
		local tint = Temper.colorOf(grade)
		local scrapPay = Temper.scrapTokens(grade)

		local bar = round(mk("Frame", {
			Size = UDim2.new(1, -4, 0, 64),
			BackgroundColor3 = BG2,
			LayoutOrder = order,
			ZIndex = 42,
		}, list), 12)
		stroke(bar, 2, tint, 0.3)

		label(bar, "SELECTED", 10, GOLD, UDim2.fromOffset(14, 6), UDim2.fromOffset(80, 14), FONT)
		label(bar, (Temper.wordOf(grade) or "") .. "  " .. kit.name, 15, tint,
			UDim2.fromOffset(14, 22), UDim2.new(0.45, -20, 0, 28), FONT)

		local scrap = round(mk("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(92, 40),
			BackgroundColor3 = Color3.fromRGB(140, 52, 52),
			Text = "",
			AutoButtonColor = true,
			ZIndex = 44,
		}, bar), 9)
		iconImage(scrap, "tokens", UDim2.fromOffset(18, 18), UDim2.fromOffset(8, 11))
		label(scrap, "+" .. tostring(scrapPay), 13, Color3.fromRGB(255, 220, 220),
			UDim2.fromOffset(30, 0), UDim2.new(1, -36, 1, 0), FONT)
		scrap.MouseButton1Click:Connect(function()
			if opts.onScrapTemper then
				opts.onScrapTemper({ id = selectedId })
			end
		end)

		local x = -112
		for i = #FAMILIES, 1, -1 do
			local fam = FAMILIES[i]
			local owns = (tonumber(state.tools[fam.id]) or 0) > 0
			local fitted = (state.toolTempers[fam.id] or {}).temperId == selectedId
			local b = round(mk("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, x, 0.5, 0),
				Size = UDim2.fromOffset(48, 40),
				BackgroundColor3 = fitted and Color3.fromRGB(84, 70, 34) or (owns and GREEN or BG3),
				Text = "",
				AutoButtonColor = owns and not fitted,
				ZIndex = 44,
			}, bar), 9)
			iconImage(b, fam.icon, UDim2.fromOffset(28, 28), UDim2.fromOffset(10, 6))
			if owns and not fitted then
				b.MouseButton1Click:Connect(function()
					if opts.onFitTemper then
						opts.onFitTemper({ id = selectedId, family = fam.id })
					end
				end)
			end
			x -= 54
		end
		label(bar, "tap a tool", 11, MUTED,
			UDim2.new(1, x - 70, 0.5, -8), UDim2.fromOffset(70, 16), nil, Enum.TextXAlignment.Right)
	end

	local function paintTemperGrid(order)
		local rows = {}
		for id, row in pairs(state.tempers or {}) do
			if Temper.kit(id) then
				rows[#rows + 1] = { id = id, rarity = row.rarity, n = tonumber(row.n) or 1 }
			end
		end
		if #rows == 0 then
			local empty = round(mk("Frame", {
				Size = UDim2.new(1, -4, 0, 72),
				BackgroundColor3 = BG3,
				LayoutOrder = order,
				ZIndex = 42,
			}, list), 12)
			label(empty, "Open a case to get your first temper", 14, MUTED,
				UDim2.fromOffset(16, 0), UDim2.new(1, -32, 1, 0), FONT_M, Enum.TextXAlignment.Center)
			return
		end

		local rank = {}
		for i, g in ipairs(Temper.GRADE_ORDER or {}) do
			rank[g] = i
		end
		table.sort(rows, function(x, y)
			local rx = rank[Temper.normalizeRarity(x.rarity)] or 0
			local ry = rank[Temper.normalizeRarity(y.rarity)] or 0
			if rx ~= ry then
				return rx > ry
			end
			return tostring(x.id) < tostring(y.id)
		end)

		local grid = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = order,
			ZIndex = 42,
		}, list)
		mk("UIGridLayout", {
			CellPadding = UDim2.fromOffset(8, 8),
			CellSize = UDim2.fromOffset(148, 168),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, grid)

		for i, entry in ipairs(rows) do
			local kit = Temper.kit(entry.id)
			local grade = Temper.normalizeRarity(entry.rarity)
			local tint = Temper.colorOf(grade)
			local selected = selectedId == entry.id
			local tile = round(mk("TextButton", {
				BackgroundColor3 = BG2,
				Text = "",
				AutoButtonColor = true,
				LayoutOrder = i,
				ZIndex = 43,
			}, grid), 12)
			stroke(tile, selected and 2.5 or 1.5, selected and GOLD or tint, selected and 0.05 or 0.35)

			mk("Frame", {
				BackgroundColor3 = tint,
				Size = UDim2.new(1, 0, 0, 6),
				ZIndex = 44,
			}, tile)

			local art = round(mk("Frame", {
				BackgroundColor3 = tint:Lerp(BG3, 0.62),
				Position = UDim2.fromOffset(14, 16),
				Size = UDim2.fromOffset(72, 72),
				ZIndex = 44,
			}, tile), 12)
			stroke(art, 1, tint, 0.25)
			label(art, string.upper(string.sub(tostring(kit.name or "?"), 1, 1)), 36, tint,
				UDim2.new(), UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center)
			local letter = round(mk("Frame", {
				BackgroundColor3 = INK,
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -3, 1, -3),
				Size = UDim2.fromOffset(22, 22),
				ZIndex = 46,
			}, art), 6)
			stroke(letter, 1, tint, 0.15)
			label(letter, tostring(grade or "?"), 12, tint, UDim2.new(), UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center)

			if entry.n > 1 then
				local count = round(mk("Frame", {
					BackgroundColor3 = GOLD,
					Position = UDim2.fromOffset(96, 16),
					Size = UDim2.fromOffset(40, 22),
					ZIndex = 45,
				}, tile), 7)
				label(count, "x" .. entry.n, 12, INK, UDim2.new(), UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center)
			end

			label(tile, tostring(kit.name), 14, tint,
				UDim2.fromOffset(12, 96), UDim2.new(1, -24, 0, 20), FONT)
			label(tile, shortBoosts(entry.id, grade), 11, MUTED,
				UDim2.fromOffset(12, 118), UDim2.new(1, -24, 0, 36))

			local id = entry.id
			tile.MouseButton1Click:Connect(function()
				selectedId = (selectedId == id) and nil or id
				lastKey = nil
				paint(true)
			end)
		end
	end

	local function flagshipRow(order)
		local flagships = state.chestTools or {}
		if #flagships == 0 then
			return
		end
		sectionTitle(order, "FLAGSHIPS", "Chest tools keep their temper forever")
		order += 1
		local grid = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = order,
			ZIndex = 42,
		}, list)
		mk("UIGridLayout", {
			CellPadding = UDim2.fromOffset(8, 8),
			CellSize = UDim2.fromOffset(200, 96),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, grid)

		local cost = state.rollCost or Temper.rollCost(0)
		local tokens = state.tokens or 0
		local n = 0
		for _, ft in ipairs(flagships) do
			if type(ft) == "table" then
				n += 1
				local def = Tools.chestTool(ft.defId or ft.id)
				local equipped = state.chestTool == ft.id
				local kit = ft.temperId and Temper.kit(ft.temperId) or nil
				local grade = Temper.normalizeRarity(ft.temperRarity or (kit and kit.rarity))
				local tint = (grade and Temper.colorOf(grade)) or MUTED
				local name = ((ft.nightmare and "Nightmare ") or (ft.shadow and "Shadow ") or (ft.shiny and "Shiny ") or "")
					.. (ft.name or (def and def.name) or "Flagship")

				local tile = round(mk("Frame", {
					BackgroundColor3 = BG2,
					LayoutOrder = n,
					ZIndex = 43,
				}, grid), 12)
				stroke(tile, equipped and 2 or 1, equipped and GREEN or tint, 0.3)

				local thumb = round(mk("Frame", {
					BackgroundColor3 = tint:Lerp(BG3, 0.55),
					Position = UDim2.fromOffset(10, 12),
					Size = UDim2.fromOffset(56, 56),
					ZIndex = 44,
				}, tile), 10)
				iconImage(thumb, "pickaxe", UDim2.fromOffset(42, 42), UDim2.fromOffset(7, 7))

				label(tile, name, 13, TEXT, UDim2.fromOffset(76, 10), UDim2.new(1, -86, 0, 18), FONT)
				label(tile, kit and ((Temper.wordOf(grade) or "") .. " " .. kit.name) or "no temper",
					11, kit and tint or MUTED, UDim2.fromOffset(76, 30), UDim2.new(1, -86, 0, 16))

				local can = tokens >= cost
				local roll = round(mk("TextButton", {
					Position = UDim2.fromOffset(76, 52),
					Size = UDim2.fromOffset(110, 28),
					BackgroundColor3 = can and GOLD or Color3.fromRGB(70, 58, 62),
					Text = "",
					AutoButtonColor = can,
					ZIndex = 45,
				}, tile), 8)
				iconImage(roll, "tokens", UDim2.fromOffset(16, 16), UDim2.fromOffset(6, 6))
				label(roll, can and tostring(cost) or ("NEED " .. cost), 12,
					can and INK or RED, UDim2.fromOffset(26, 0), UDim2.new(1, -30, 1, 0), FONT)
				local ftId = ft.id
				if can then
					roll.MouseButton1Click:Connect(function()
						if opts.onRoll then
							opts.onRoll(ftId)
						end
					end)
				end
			end
		end
	end

	local function key()
		local parts = {
			tostring(state.tokens), tostring(state.rollCost), tostring(state.chestTool),
			tostring(state.toolFamily), tostring(state.shopInHand), tostring(selectedId),
		}
		for _, fam in ipairs(FAMILIES) do
			local tt = state.toolTempers[fam.id] or {}
			parts[#parts + 1] = fam.id .. (state.tools[fam.id] or 0) .. tostring(tt.temperId) .. tostring(tt.temperRarity)
		end
		for _, ft in ipairs(state.chestTools) do
			if type(ft) == "table" then
				parts[#parts + 1] = tostring(ft.id) .. tostring(ft.temperId) .. tostring(ft.temperRarity)
			end
		end
		local owned = {}
		for id, row in pairs(state.tempers or {}) do
			owned[#owned + 1] = id .. tostring(row.rarity) .. tostring(row.n)
		end
		table.sort(owned)
		parts[#parts + 1] = table.concat(owned, ",")
		parts[#parts + 1] = tostring(state.gems) .. "/" .. tostring(state.casePrice)
		return table.concat(parts, "|")
	end

	paint = function(force)
		local k = key()
		if not force and k == lastKey then
			return
		end
		lastKey = k
		for _, ch in ipairs(list:GetChildren()) do
			if ch:IsA("GuiObject") then
				ch:Destroy()
			end
		end
		local tokens = state.tokens or 0
		if opts.onTokens then
			opts.onTokens(tokens)
		end
		if selectedId and not (state.tempers and state.tempers[selectedId]) then
			selectedId = nil
		end

		caseBanner(0)
		sectionTitle(1, "YOUR TOOLS", selectedId and "tap a seat to fit the selected temper" or "tap a temper below, then a tool")
		toolSeats(2)
		if selectedId then
			actionBar(3)
		end
		sectionTitle(4, "YOUR TEMPERS", "tap one to select")
		paintTemperGrid(5)
		flagshipRow(6)
	end

	local ctl = { root = list }
	function ctl.setState(snap)
		if not snap then
			return
		end
		state.tools = snap.tools or {}
		state.toolTempers = snap.toolTempers or {}
		local inHand = snap.tool or {}
		state.toolFamily = inHand.family or "pickaxe"
		state.shopInHand = (tonumber(inHand.tier) or 0) > 0
		state.chestTools = snap.chestTools or snap.foreverTools or {}
		state.chestTool = snap.chestTool or snap.equippedForeverId
		state.tokens = tonumber(snap.temperTokens) or 0
		state.rollCost = snap.rollCost
		state.tempers = snap.tempers or {}
		state.gems = tonumber(snap.gems) or 0
		state.casePrice = tonumber(snap.temperCasePrice)
	end
	function ctl.paint(force)
		paint(force)
	end
	function ctl.paintLocked(msg)
		for _, ch in ipairs(list:GetChildren()) do
			if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
				ch:Destroy()
			end
		end
		local note = label(list, tostring(msg or "Temper unlocks at Rebirth 1"), 18, GOLD,
			UDim2.fromOffset(12, 40), UDim2.new(1, -24, 0, 80), FONT, Enum.TextXAlignment.Center)
		note.TextWrapped = true
		note.LayoutOrder = 1
		local sub = label(list, "Rebirth once to unlock the Temperament Case.", 14, MUTED,
			UDim2.fromOffset(12, 0), UDim2.new(1, -24, 0, 48), FONT_M, Enum.TextXAlignment.Center)
		sub.TextWrapped = true
		sub.LayoutOrder = 2
	end
	return ctl
end

function MineForgeView.mount(parent, opts)
	opts = opts or {}
	local view = {}

	local root = round(mk("Frame", {
		Name = "ForgePanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(720, 580),
		BackgroundColor3 = BG,
		Visible = false,
		ZIndex = 40,
	}, parent), 18)
	stroke(root, 2, GOLD, 0.45)
	do
		local fit = Instance.new("UIScale")
		fit.Name = "FitScale"
		fit.Parent = root
		local function applyFit()
			local host = root.Parent
			if not host then return end
			local avail = host.AbsoluteSize
			if avail.X < 20 or avail.Y < 20 then return end
			local A = 1
			local p = host
			while p do
				local u = p:FindFirstChildOfClass("UIScale")
				if u and u ~= fit then A *= math.max(0.05, u.Scale) end
				if p:IsA("ScreenGui") then break end
				p = p.Parent
			end
			local sx = (avail.X * 0.96) / (720 * A)
			local sy = (avail.Y * 0.90) / (580 * A)
			fit.Scale = math.clamp(math.min(sx, sy), 0.32, 2.2)
		end
		applyFit()
		task.defer(applyFit)
		if root.Parent and root.Parent:IsA("GuiObject") then
			root.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyFit)
		end
		local cam = workspace.CurrentCamera
		if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(applyFit) end
	end

	label(root, "FORGE", 24, TEXT, UDim2.fromOffset(22, 12), UDim2.fromOffset(400, 28), FONT)
	label(root, "Open a case, then fit tempers onto your tools.", 13, MUTED,
		UDim2.fromOffset(22, 40), UDim2.fromOffset(520, 18))
	local tokenLbl = label(root, "0 tokens", 16, GOLD,
		UDim2.new(1, -56, 0, 16), UDim2.fromOffset(220, 24), FONT, Enum.TextXAlignment.Right)
	tokenLbl.AnchorPoint = Vector2.new(1, 0)

	local close = round(mk("TextButton", {
		Position = UDim2.new(1, -44, 0, 12),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = INK,
		Font = FONT, TextSize = 16, TextColor3 = TEXT, Text = "X",
		ZIndex = 42,
	}, root), 8)
	close.MouseButton1Click:Connect(function()
		root.Visible = false
		if opts.onClose then
			opts.onClose()
		end
	end)

	local listCtl = MineForgeView.mountList(root, {
		position = UDim2.fromOffset(16, 70),
		size = UDim2.new(1, -32, 1, -86),
		onRoll = opts.onRoll,
		onRollFamily = opts.onRollFamily,
		onEquip = opts.onEquip,
		onOpenCase = opts.onOpenCase,
		onOpenCaseBundle = opts.onOpenCaseBundle,
		onFitTemper = opts.onFitTemper,
		onScrapTemper = opts.onScrapTemper,
		onTokens = function(tokens)
			tokenLbl.Text = string.format("%d token%s", tokens, tokens == 1 and "" or "s")
		end,
	})

	function view.setState(snap)
		listCtl.setState(snap)
		if root.Visible then
			listCtl.paint()
		end
	end

	function view.open()
		listCtl.paint(true)
		root.Visible = true
	end

	function view.close()
		root.Visible = false
	end

	root:GetPropertyChangedSignal("Visible"):Connect(function()
		if root.Visible then
			listCtl.paint(true)
		end
	end)

	view.root = root
	return view
end

return MineForgeView
