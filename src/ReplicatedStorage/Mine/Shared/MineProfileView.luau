--[[
	MineProfileView -- in-game player profile (friend / trade / coinflip / inventory).
]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local T = require(RS.Mine.Shared:WaitForChild("MineTheme"))

local MineProfileView = {}

local function mk(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props or {}) do i[k] = v end
	if parent then i.Parent = parent end
	return i
end

local function round(f, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = f
end

function MineProfileView.mount(gui, opts)
	opts = opts or {}
	local net = opts.net
	local onTrade = opts.onTrade
	local onCoinflip = opts.onCoinflip
	local onMessage = opts.onMessage

	local root = mk("Frame", {
		Name = "PlayerProfile",
		Visible = false,
		Active = true,
		BackgroundColor3 = T.PANEL,
		BackgroundTransparency = 0.04,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(520, 560),
		ZIndex = 70,
		BorderSizePixel = 0,
	}, gui)
	round(root, 12)
	mk("UIStroke", { Color = T.STROKE or Color3.fromRGB(70, 66, 60), Thickness = 1 }, root)

	local title = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = T.FONT,
		TextSize = 22,
		Text = "PROFILE",
		TextColor3 = T.TEXT,
		Size = UDim2.new(1, -56, 0, 36),
		Position = UDim2.fromOffset(18, 10),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 71,
	}, root)

	local close = mk("TextButton", {
		Text = "X", Font = T.FONT, TextSize = 18, TextColor3 = T.TEXT,
		BackgroundColor3 = T.CARD, Size = UDim2.fromOffset(46, 46),
		Position = UDim2.new(1, -48, 0, 10), ZIndex = 71, BorderSizePixel = 0,
	}, root)
	round(close, 8)
	close.MouseButton1Click:Connect(function() root.Visible = false end)

	local head = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 52),
		Size = UDim2.new(1, -36, 0, 88),
		ZIndex = 71,
	}, root)

	local avatar = mk("ImageLabel", {
		Name = "Avatar",
		BackgroundColor3 = T.CARD,
		Size = UDim2.fromOffset(72, 72),
		Position = UDim2.fromOffset(0, 8),
		ZIndex = 71,
	}, head)
	round(avatar, 36)

	local nameL = mk("TextLabel", {
		Name = "Name",
		BackgroundTransparency = 1,
		Font = T.FONT,
		TextSize = 20,
		TextColor3 = T.TEXT,
		Text = "",
		Position = UDim2.fromOffset(88, 10),
		Size = UDim2.new(1, -88, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 71,
	}, head)

	local statsL = mk("TextLabel", {
		Name = "Stats",
		BackgroundTransparency = 1,
		Font = T.FONT_M,
		TextSize = 14,
		TextColor3 = T.MUTED,
		Text = "",
		Position = UDim2.fromOffset(88, 40),
		Size = UDim2.new(1, -88, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 71,
	}, head)

	local actions = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 148),
		Size = UDim2.new(1, -36, 0, 40),
		ZIndex = 71,
	}, root)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
	}, actions)

	local function actionBtn(text, color)
		local b = mk("TextButton", {
			Text = text, Font = T.FONT_M, TextSize = 13, TextColor3 = Color3.fromRGB(22, 18, 12),
			BackgroundColor3 = color or T.GOLD, Size = UDim2.fromOffset(96, 36),
			ZIndex = 72, BorderSizePixel = 0, AutoButtonColor = true,
		}, actions)
		round(b, 8)
		return b
	end

	local friendBtn = actionBtn("Add Friend")
	local msgBtn = actionBtn("Message", Color3.fromRGB(180, 190, 210))
	local tradeBtn = actionBtn("Trade")
	local flipBtn = actionBtn("Coinflip", Color3.fromRGB(220, 170, 90))

	local invTitle = mk("TextLabel", {
		BackgroundTransparency = 1, Font = T.FONT, TextSize = 16, TextColor3 = T.TEXT,
		Text = "BEST PETS", Position = UDim2.fromOffset(18, 200),
		Size = UDim2.new(1, -36, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 71,
	}, root)

	local body = mk("ScrollingFrame", {
		Name = "InvBody",
		BackgroundColor3 = T.CARD,
		BackgroundTransparency = 0.3,
		Position = UDim2.fromOffset(18, 228),
		Size = UDim2.new(1, -36, 1, -248),
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		ZIndex = 71,
	}, root)
	round(body, 8)
	mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, body)
	mk("UIPadding", {
		PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
	}, body)

	local state = nil

	local function clearBody()
		for _, c in ipairs(body:GetChildren()) do
			if c:IsA("GuiObject") then c:Destroy() end
		end
	end

	local function row(text)
		local l = mk("TextLabel", {
			BackgroundColor3 = T.PANEL,
			BackgroundTransparency = 0.4,
			Size = UDim2.new(1, -4, 0, 28),
			Font = T.FONT_M, TextSize = 13, TextColor3 = T.TEXT,
			Text = text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 72,
			BorderSizePixel = 0,
		}, body)
		round(l, 6)
		local p = Instance.new("UIPadding")
		p.PaddingLeft = UDim.new(0, 10)
		p.Parent = l
	end

	local ctl = {}

	function ctl.open(profile)
		state = profile
		if not profile then return end
		title.Text = "PROFILE"
		nameL.Text = profile.name or ("User " .. tostring(profile.userId))
		statsL.Text = string.format("R%d   ·   %s gems   ·   %s stardust\n%d cards   ·   %d packs%s",
			profile.prestige or 0,
			tostring(profile.gems or 0),
			tostring(profile.dust or 0),
			profile.cardCount or 0,
			profile.packCount or 0,
			profile.online and "   ·   Online" or "   ·   Offline")
		avatar.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", profile.userId or 0)
		clearBody()
		row(string.format("— Packs (%d) —", #(profile.packs or {})))
		for _, pk in ipairs(profile.packs or {}) do
			row(pk.packName or pk.packId or "Pack")
		end
		row(string.format("— Best pets (%d) —", #(profile.cards or {})))
		for i, c in ipairs(profile.cards or {}) do
			if i > 40 then
				row("… +" .. tostring(#(profile.cards) - 40) .. " more")
				break
			end
			row(string.format("%s  |  %s%s%s  P%d", c.name or "?", (c.shadow and "Shadow ") or (c.shiny and "Shiny ") or "", (c.variant and c.variant ~= "Normal") and (c.variant .. " ") or "", c.rarityId or "?", c.powerLevel or 1))
		end
		local me = Players.LocalPlayer.UserId
		friendBtn.Visible = profile.userId ~= me
		msgBtn.Visible = profile.userId ~= me
		tradeBtn.Visible = profile.userId ~= me and profile.online
		flipBtn.Visible = profile.userId ~= me and profile.online
		root.Visible = true
	end

	function ctl.close()
		root.Visible = false
	end

	function ctl.isOpen()
		return root.Visible
	end

	friendBtn.MouseButton1Click:Connect(function()
		if state and net then net:FireServer("friendRequest", state.userId) end
	end)
	msgBtn.MouseButton1Click:Connect(function()
		if state and onMessage then onMessage(state.userId, state.name) end
	end)
	tradeBtn.MouseButton1Click:Connect(function()
		if state and onTrade then onTrade(state.userId) end
	end)
	flipBtn.MouseButton1Click:Connect(function()
		if state and onCoinflip then onCoinflip(state.userId) end
	end)

	return ctl
end

return MineProfileView