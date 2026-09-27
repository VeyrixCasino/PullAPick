--[[
	MineDepthShopView: depth-plaza tool desk as a carousel (like MineShopView).
	Opened from pads with Machine=depth_shop + DepthShop=deeprock|shadowzone.
	Each desk has its own theme — Deeprock = cave ember, Shadowzone = void purple.
]]
local MineDepthShopView = {}

local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local Tools = require(shared:WaitForChild("MineTools"))
local Icons = require(shared:WaitForChild("MineIcons"))
local Cards = require(shared:WaitForChild("MineCards"))
local ShopBgArt = require(shared:WaitForChild("MineShopBackgrounds"))

local FONT = Enum.Font.GothamBold
local FONT_M = Enum.Font.GothamMedium

local THEMES = {
	deeprock = {
		label = "Deeprock Trader",
		blurb = "Torchlight · basalt · iron veins",
		scrim = 0.22,
		ink = Color3.fromRGB(18, 12, 8),
		panel = Color3.fromRGB(42, 30, 22),
		card = Color3.fromRGB(62, 46, 34),
		cardHi = Color3.fromRGB(88, 64, 44),
		stage = Color3.fromRGB(28, 20, 14),
		text = Color3.fromRGB(248, 234, 214),
		muted = Color3.fromRGB(168, 144, 118),
		accent = Color3.fromRGB(232, 156, 72),
		stroke = Color3.fromRGB(170, 112, 58),
		gradA = Color3.fromRGB(72, 42, 24),
		gradB = Color3.fromRGB(28, 18, 12),
		buy = Color3.fromRGB(232, 156, 72),
		buyText = Color3.fromRGB(28, 16, 8),
		owned = Color3.fromRGB(36, 28, 22),
	},
	shadowzone = {
		label = "Shadowzone Trader",
		blurb = "No torch reaches here",
		scrim = 0.1,
		ink = Color3.fromRGB(4, 2, 10),
		panel = Color3.fromRGB(14, 10, 24),
		card = Color3.fromRGB(26, 18, 40),
		cardHi = Color3.fromRGB(40, 26, 58),
		stage = Color3.fromRGB(10, 6, 18),
		text = Color3.fromRGB(220, 210, 240),
		muted = Color3.fromRGB(120, 104, 148),
		accent = Color3.fromRGB(168, 92, 240),
		stroke = Color3.fromRGB(90, 40, 140),
		gradA = Color3.fromRGB(48, 20, 78),
		gradB = Color3.fromRGB(8, 4, 16),
		buy = Color3.fromRGB(168, 92, 240),
		buyText = Color3.fromRGB(250, 240, 255),
		owned = Color3.fromRGB(12, 8, 18),
	},
}
THEMES.mid = THEMES.deeprock
THEMES.b = THEMES.deeprock
THEMES.deep = THEMES.shadowzone
THEMES.c = THEMES.shadowzone
THEMES.surface_band = {
	label = "Surface Band Desk",
	blurb = "Shallow stock · this island only",
	scrim = 0.35,
	ink = Color3.fromRGB(16, 20, 30),
	panel = Color3.fromRGB(34, 40, 56),
	card = Color3.fromRGB(50, 58, 80),
	cardHi = Color3.fromRGB(66, 76, 104),
	stage = Color3.fromRGB(24, 28, 40),
	text = Color3.fromRGB(240, 244, 252),
	muted = Color3.fromRGB(160, 170, 192),
	accent = Color3.fromRGB(255, 206, 92),
	stroke = Color3.fromRGB(180, 150, 70),
	gradA = Color3.fromRGB(48, 56, 78),
	gradB = Color3.fromRGB(22, 26, 38),
	buy = Color3.fromRGB(255, 206, 92),
	buyText = Color3.fromRGB(28, 22, 10),
	owned = Color3.fromRGB(20, 24, 34),
}
THEMES.shallow = THEMES.surface_band
THEMES.a = THEMES.surface_band
THEMES.surface = THEMES.surface_band

local function themeFor(desk)
	return THEMES[tostring(desk or "deeprock")] or THEMES.deeprock
end

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	if parent then o.Parent = parent end
	return o
end

local function round(o, r)
	mk("UICorner", { CornerRadius = UDim.new(0, r or 12) }, o)
	return o
end

local function stroke(o, thick, colour, transparency)
	return mk("UIStroke", {
		Thickness = thick or 1,
		Color = colour or Color3.fromRGB(120, 100, 70),
		Transparency = transparency or 0.35,
	}, o)
end

local function fmtCoins(n)
	local ok, Ab = pcall(function()
		return require(shared:WaitForChild("MineAbbrev"))
	end)
	if ok and Ab and Ab.format then
		return Ab.format(n)
	end
	return tostring(math.floor(tonumber(n) or 0))
end

local function rarityInk(tool)
	local rar = tool and (tool.rarity
		or (Tools.rarityForPower and Tools.rarityForPower(tool.power))
		or (tool.tier and Tools.rarityForTier and Tools.rarityForTier(
			tool.tier, #((Tools.TOOLS and Tools.TOOLS[tool.family or ""]) or {})
		)))
	if not rar then return nil, nil end
	local ink = (Cards.RARITY_COLOR and Cards.RARITY_COLOR[rar]) or Color3.fromRGB(170, 170, 170)
	return rar, ink
end

local function resolveCatalog(catalog, ownedTools, backpackTier)
	ownedTools = type(ownedTools) == "table" and ownedTools or {}
	backpackTier = math.floor(tonumber(backpackTier) or 0)
	local out = {}
	for _, entry in ipairs(catalog or {}) do
		if type(entry) == "table" and entry.id then
			local fam = entry.family
			local tier = entry.tier
			if fam == "backpack" and tier then
				entry.owned = backpackTier >= tier
				entry.role = entry.role or "Bag"
				entry.power = entry.slots or entry.power
			elseif fam and tier then
				entry.owned = (tonumber(ownedTools[fam]) or 0) >= tier
			end
			table.insert(out, entry)
		else
			local tid = tostring(entry)
			for fam, list in pairs(Tools.TOOLS or {}) do
				for ti, row in ipairs(list) do
					if row.id == tid then
						table.insert(out, {
							id = tid, name = row.name, family = fam, tier = ti,
							power = row.power, price = row.price,
							owned = (tonumber(ownedTools[fam]) or 0) >= ti,
						})
						break
					end
				end
			end
		end
	end
	return out
end

function MineDepthShopView.mount(parent, opts)
	opts = opts or {}
	local state = {
		desk = "deeprock", seam = 500, zoneId = nil,
		coins = 0, gems = 0, tools = {}, backpackTier = 1,
	}
	local index = 1
	local view = {}

	local root = mk("Frame", {
		Name = "DepthShopPanel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 40,
	}, parent)
	local shopBg = mk("ImageLabel", {
		Name = "ShopBg",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Crop,
		Image = "",
		ZIndex = 40,
	}, root)
	mk("Frame", {
		Name = "Veil",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		ZIndex = 40,
	}, root)
	mk("TextButton", {
		Name = "ScrimClose", Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, Text = "", ZIndex = 40,
	}, root).MouseButton1Click:Connect(function()
		view.close()
	end)

	local shell = mk("Frame", {
		Name = "Shell",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(720, 560),
		BackgroundColor3 = THEMES.deeprock.panel,
		ZIndex = 41,
	}, root)
	round(shell, 20)
	do
		local fit = Instance.new("UIScale")
		fit.Name = "FitScale"
		fit.Parent = shell
		local function applyFit()
			local host = shell.Parent
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
			local sy = (avail.Y * 0.90) / (560 * A)
			fit.Scale = math.clamp(math.min(sx, sy), 0.32, 1)
		end
		applyFit()
		task.defer(applyFit)
		if shell.Parent and shell.Parent:IsA("GuiObject") then
			shell.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyFit)
		end
		local cam = workspace.CurrentCamera
		if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(applyFit) end
	end
	local shellStroke = stroke(shell, 2, THEMES.deeprock.stroke, 0.25)
	local shellGrad = mk("UIGradient", {
		Color = ColorSequence.new(THEMES.deeprock.gradA, THEMES.deeprock.gradB),
		Rotation = 110,
	}, shell)

	-- Soft vignette / themed wash behind the stage.
	local wash = mk("Frame", {
		Name = "Wash", BackgroundTransparency = 0.55,
		BackgroundColor3 = THEMES.deeprock.accent,
		Size = UDim2.fromScale(1, 1), ZIndex = 41,
	}, shell)
	round(wash, 20)
	mk("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(0.45, 0.75),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rotation = 90,
	}, wash)

	local header = mk("Frame", {
		Name = "Header", Size = UDim2.new(1, 0, 0, 78),
		BackgroundColor3 = THEMES.deeprock.ink, BackgroundTransparency = 0.15, ZIndex = 42,
	}, shell)
	round(header, 20)
	mk("Frame", {
		Position = UDim2.new(0, 0, 1, -18), Size = UDim2.new(1, 0, 0, 18),
		BackgroundColor3 = THEMES.deeprock.ink, BackgroundTransparency = 0.15,
		BorderSizePixel = 0, ZIndex = 42,
	}, header)

	local title = mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 12),
		Size = UDim2.new(1, -180, 0, 30), Font = FONT, TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEMES.deeprock.accent, Text = "Deeprock Trader", ZIndex = 43,
	}, header)
	local sub = mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 42),
		Size = UDim2.new(1, -180, 0, 22), Font = FONT_M, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEMES.deeprock.muted, Text = "", ZIndex = 43,
	}, header)

	local coinChip = mk("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -64, 0, 18),
		Size = UDim2.fromOffset(150, 40), BackgroundColor3 = Color3.fromRGB(20, 14, 10),
		BackgroundTransparency = 0.1, ZIndex = 43,
	}, header)
	round(coinChip, 12)
	stroke(coinChip, 1.5, THEMES.deeprock.accent, 0.45)
	local coinsL = mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -20, 1, 0), Font = FONT, TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEMES.deeprock.text, Text = "0", ZIndex = 44,
	}, coinChip)

	local closeBtn = mk("TextButton", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 18),
		Size = UDim2.fromOffset(46, 46), BackgroundColor3 = Color3.fromRGB(70, 36, 36),
		Font = FONT, TextSize = 20, TextColor3 = Color3.fromRGB(255, 190, 190),
		Text = "X", AutoButtonColor = true, ZIndex = 44,
	}, header)
	round(closeBtn, 12)
	closeBtn.MouseButton1Click:Connect(function() view.close() end)

	local function arrow(dir)
		local b = mk("TextButton", {
			Name = "Arrow" .. (dir < 0 and "L" or "R"),
			AnchorPoint = Vector2.new(dir < 0 and 0 or 1, 0.5),
			Position = dir < 0 and UDim2.new(0, 18, 0, 300) or UDim2.new(1, -18, 0, 300),
			Size = UDim2.fromOffset(54, 84), BackgroundColor3 = THEMES.deeprock.card,
			Text = dir < 0 and "<" or ">", Font = FONT, TextSize = 34,
			TextColor3 = THEMES.deeprock.text, AutoButtonColor = false, ZIndex = 45,
		}, shell)
		round(b, 14)
		local st = stroke(b, 2, THEMES.deeprock.stroke, 0.4)
		b.MouseButton1Click:Connect(function()
			view.step(dir)
		end)
		return b, st
	end
	local leftBtn, leftStroke = arrow(-1)
	local rightBtn, rightStroke = arrow(1)

	local stage = mk("Frame", {
		Name = "Stage", Position = UDim2.fromOffset(86, 104),
		Size = UDim2.fromOffset(548, 390), BackgroundColor3 = THEMES.deeprock.card, ZIndex = 42,
	}, shell)
	round(stage, 18)
	local stageStroke = stroke(stage, 2, THEMES.deeprock.accent, 0.35)

	local preview = mk("Frame", {
		Name = "Preview", Position = UDim2.fromOffset(20, 20),
		Size = UDim2.new(1, -40, 0, 200), BackgroundColor3 = THEMES.deeprock.stage, ZIndex = 43,
	}, stage)
	round(preview, 14)
	stroke(preview, 1, THEMES.deeprock.stroke, 0.55)
	local previewGrad = mk("UIGradient", {
		Color = ColorSequence.new(THEMES.deeprock.gradA, THEMES.deeprock.gradB),
		Rotation = 125,
	}, preview)

	local icon = mk("ImageLabel", {
		Name = "Icon", BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(140, 140), ScaleType = Enum.ScaleType.Fit,
		Image = "", ZIndex = 44,
	}, preview)

	local tierChip = mk("TextLabel", {
		Position = UDim2.fromOffset(28, 28), Size = UDim2.fromOffset(56, 26),
		BackgroundColor3 = THEMES.deeprock.accent, Font = FONT, TextSize = 14,
		TextColor3 = THEMES.deeprock.buyText, Text = "#1", ZIndex = 45,
	}, stage)
	round(tierChip, 9)

	local rarityChip = mk("TextLabel", {
		Position = UDim2.fromOffset(92, 28), Size = UDim2.fromOffset(110, 26),
		BackgroundColor3 = Color3.fromRGB(40, 44, 56), Font = FONT, TextSize = 13,
		TextColor3 = Color3.fromRGB(240, 244, 252), Text = "", Visible = false, ZIndex = 45,
	}, stage)
	round(rarityChip, 9)

	local flag = mk("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -28, 0, 28),
		Size = UDim2.fromOffset(96, 26), BackgroundColor3 = THEMES.deeprock.accent,
		Font = FONT, TextSize = 13, TextColor3 = THEMES.deeprock.buyText,
		Text = "", Visible = false, ZIndex = 45,
	}, stage)
	round(flag, 9)

	local nameLbl = mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 236),
		Size = UDim2.new(1, -40, 0, 34), Font = FONT, TextSize = 26,
		TextColor3 = THEMES.deeprock.text, Text = "", ZIndex = 44,
	}, stage)

	local blurbLbl = mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 272),
		Size = UDim2.new(1, -40, 0, 22), Font = FONT_M, TextSize = 14,
		TextColor3 = THEMES.deeprock.muted, Text = "", ZIndex = 44,
	}, stage)

	local action = mk("TextButton", {
		Name = "Action", AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 318), Size = UDim2.fromOffset(280, 48),
		BackgroundColor3 = THEMES.deeprock.buy, Text = "", AutoButtonColor = true, ZIndex = 44,
	}, stage)
	round(action, 14)
	local actionLbl = mk("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
		Font = FONT, TextSize = 18, TextColor3 = THEMES.deeprock.buyText,
		Text = "", ZIndex = 45,
	}, action)

	action.MouseButton1Click:Connect(function()
		local tools = state.tools or {}
		local row = tools[index]
		if not row or row.owned then return end
		if opts.onBuy then
			opts.onBuy({
				id = row.id,
				family = row.family,
				seam = state.seam,
				desk = state.desk,
				zoneId = state.zoneId,
			}, state.desk)
		end
	end)

	local counter = mk("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.fromOffset(220, 22), BackgroundTransparency = 1,
		Font = FONT, TextSize = 15, TextColor3 = THEMES.deeprock.muted,
		Text = "", ZIndex = 43,
	}, shell)

	local function applyTheme(th)
		root.BackgroundTransparency = th.scrim
		shell.BackgroundColor3 = th.panel
		shellStroke.Color = th.stroke
		shellGrad.Color = ColorSequence.new(th.gradA, th.gradB)
		wash.BackgroundColor3 = th.accent
		header.BackgroundColor3 = th.ink
		title.TextColor3 = th.accent
		sub.TextColor3 = th.muted
		coinsL.TextColor3 = th.text
		stage.BackgroundColor3 = th.card
		stageStroke.Color = th.accent
		preview.BackgroundColor3 = th.stage
		previewGrad.Color = ColorSequence.new(th.gradA, th.gradB)
		nameLbl.TextColor3 = th.text
		blurbLbl.TextColor3 = th.muted
		counter.TextColor3 = th.muted
		leftBtn.BackgroundColor3 = th.card
		rightBtn.BackgroundColor3 = th.card
		leftBtn.TextColor3 = th.text
		rightBtn.TextColor3 = th.text
		leftStroke.Color = th.stroke
		rightStroke.Color = th.stroke
		tierChip.BackgroundColor3 = th.accent
		tierChip.TextColor3 = th.buyText
	end

	local function paint()
		local th = themeFor(state.desk)
		applyTheme(th)
		title.Text = th.label
		sub.Text = string.format("%s · seam %s", th.blurb, tostring(state.seam or "?"))
		if state.zoneId == "bigbang" then
			coinsL.Text = fmtCoins(state.spaceCoins or 0) .. " space"
		else
			coinsL.Text = fmtCoins(state.coins) .. " coins"
		end

		local tools = state.tools or {}
		if #tools == 0 then
			nameLbl.Text = "Empty desk"
			blurbLbl.Text = "Nothing in stock here yet"
			icon.Image = ""
			actionLbl.Text = "Closed"
			action.BackgroundColor3 = th.owned
			actionLbl.TextColor3 = th.muted
			counter.Text = "0 / 0"
			flag.Visible = false
			rarityChip.Visible = false
			return
		end
		index = ((index - 1) % #tools) + 1
		local row = tools[index]
		local rar, rarCol = rarityInk(row)
		local price = tonumber(row.price)
		if not price or price <= 0 then
			price = math.floor((tonumber(row.power) or 1) * 800)
		end

		tierChip.Text = "#" .. tostring(index)
		if rar then
			rarityChip.Visible = true
			rarityChip.Text = tostring(rar)
			rarityChip.BackgroundColor3 = rarCol or th.accent
			rarityChip.TextColor3 = Color3.fromRGB(18, 16, 12)
		else
			rarityChip.Visible = false
		end

		if state.eventTools and row.id and state.eventTools[row.id] then
			row.owned = true
		end
		flag.Visible = row.owned == true
		if row.owned then
			flag.Text = "OWNED"
			flag.BackgroundColor3 = Color3.fromRGB(44, 92, 66)
			flag.TextColor3 = Color3.fromRGB(150, 230, 170)
		end

		local url = Icons.image(row.id)
			or Icons.image(row.family)
			or Icons.image((row.family == "backpack") and "backpack" or "pickaxe")
		icon.Image = url or ""
		icon.ImageColor3 = Color3.new(1, 1, 1)

		nameLbl.Text = tostring(row.name or row.id)
		blurbLbl.Text = string.format("%s · %s",
			tostring(row.role or row.family or "?"),
			(row.family == "backpack" or row.slots)
				and ("cap " .. tostring(row.slots or row.power or "?"))
				or ("power " .. tostring(row.power or "?")))

		local needD = 0
		if false and needD > (tonumber(state.deepest) or 0) then
			action.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
			actionLbl.TextColor3 = Color3.fromRGB(255, 196, 120)
			actionLbl.TextWrapped = true
			actionLbl.TextScaled = true
			actionLbl.Text = "Reach depth " .. tostring(needD) .. " to unlock these shop options."
			action.AutoButtonColor = false
		elseif row.owned then
			action.BackgroundColor3 = th.owned
			actionLbl.TextColor3 = th.muted
			actionLbl.Text = "Owned"
			action.AutoButtonColor = false
		else
			local spacePay = row.currency == "space" or row.eventOnly
			local purse = spacePay and (state.spaceCoins or 0) or (state.coins or 0)
			local unit = spacePay and " space" or ""
			local can = purse >= price
			action.BackgroundColor3 = can and th.buy or Color3.fromRGB(70, 48, 40)
			actionLbl.TextColor3 = can and th.buyText or th.muted
			actionLbl.Text = can and ("Buy  " .. fmtCoins(price) .. unit) or ("Need  " .. fmtCoins(price) .. unit)
			action.AutoButtonColor = can
		end

		counter.Text = string.format("%d / %d", index, #tools)

		-- Soft punch when paging.
		local scale = stage:FindFirstChildOfClass("UIScale") or mk("UIScale", { Scale = 1 }, stage)
		scale.Scale = 0.97
		TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()
	end

	function view.step(dir)
		local n = #(state.tools or {})
		if n <= 0 then return end
		index = ((index - 1 + (dir or 1)) % n) + 1
		paint()
	end

	function view.setState(payload)
		if type(payload) ~= "table" then return end
		if payload.desk then state.desk = payload.desk end
		if payload.seam then state.seam = payload.seam end
		if payload.zoneId ~= nil then state.zoneId = payload.zoneId end
		if payload.zoneId ~= nil then state.zoneId = payload.zoneId end
		if payload.deepest ~= nil then
			local z = state.zoneId
			if type(payload.deepest) == "table" then
				state.deepest = tonumber(z and payload.deepest[z]) or 0
			else
				state.deepest = tonumber(payload.deepest) or 0
			end
		end
		if payload.spaceCoins ~= nil then state.spaceCoins = payload.spaceCoins end
		if payload.eventTools ~= nil then state.eventTools = payload.eventTools end
		if payload.coins ~= nil then state.coins = payload.coins end
		if payload.gems ~= nil then state.gems = payload.gems end
		if payload.backpackTier ~= nil then state.backpackTier = payload.backpackTier end
		if payload.catalog then
			state.tools = resolveCatalog(payload.catalog, payload.ownedTools, payload.backpackTier or state.backpackTier)
			index = 1
		elseif payload.tools then
			state.tools = resolveCatalog(payload.tools, payload.ownedTools, payload.backpackTier or state.backpackTier)
			index = 1
		end
		if root.Visible then paint() end
	end

	function view.open(payload)
		if payload then view.setState(payload) end
		ShopBgArt.apply(shopBg, state.zoneId or "meadow", state.seam or 0)
		root.Visible = true
		paint()
	end

	function view.close()
		root.Visible = false
	end

	-- Keyboard arrows while open.
	UIS.InputBegan:Connect(function(input, gp)
		if gp or not root.Visible then return end
		if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.A then
			view.step(-1)
		elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
			view.step(1)
		end
	end)

	view.root = root
	return view
end

return MineDepthShopView
