-- MineSkillView: the rebirth skill wheel ("In the Clouds").
--
-- Layout is a ten-fold symmetric polar wheel. Every energy sits exactly 36
-- degrees from its neighbours, every wedge is mirror-symmetric about its own
-- centre line, and the five capstones sit on every other boundary so a five-fold
-- pattern nests inside the ten. Nothing here is eyeballed -- if a position looks
-- off, the angle table is wrong, not the nudge.
--
-- The panels are the same width on both sides on purpose: the wheel has to sit
-- on the screen's true centre line or the symmetry reads as a mistake.
local MineSkillView = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Data = require(script.Parent:WaitForChild("MineSkillData"))
local Stats = require(script.Parent:WaitForChild("MineStats"))

--------------------------------------------------------------------------------
-- TOKENS
--------------------------------------------------------------------------------

local WHEEL_IMAGE = "rbxassetid://111977486768840"

local T = require(game:GetService("ReplicatedStorage").Mine.Shared:WaitForChild("MineTheme"))
local FONT = T.FONT
local FONT_M = T.FONT_M
local FONT_R = T.FONT_M

local INK = Color3.fromRGB(6, 7, 14)
local PANEL = Color3.fromRGB(15, 17, 30)
local PANEL_HI = Color3.fromRGB(22, 25, 42)
local LINE = Color3.fromRGB(58, 66, 104)
local TEXT = T.TEXT
local MUTED = T.MUTED
local FAINT = T.FAINT
local GOLD = T.GOLD
local GOOD = T.GOOD
local BAD = T.BAD

local PANEL_W = 326 -- both sides, so the wheel lands on the true centre
local TOP_H = 62
local PAD = 14

local ROW_LABEL = {
	root = "Root", split = "Road", cross = "Cross", key = "Keystone",
	fuse = "Fusion", cap = "Capstone",
}

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function mk(class, props, parent)
	local o = Instance.new(class)
	-- Roblox defaults every GuiObject to a 1px border, and that border is drawn
	-- OUTSIDE the UICorner radius -- so on a rounded dark panel it shows up as a
	-- pale hairline poking out at every corner. That is the "white borders", and
	-- there was no way to switch it off because nothing ever set it. Off by
	-- default now; a caller that genuinely wants one still passes it explicitly.
	if props and props.BorderSizePixel == nil and o:IsA("GuiObject") then
		o.BorderSizePixel = 0
	end
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			o[k] = v
		end
	end
	o.Parent = parent
	return o
end

local function corner(inst, r)
	mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, inst)
	return inst
end

local function circle(inst)
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, inst)
	return inst
end

local function stroke(inst, thickness, color, transparency)
	return mk("UIStroke", {
		Thickness = thickness or 1,
		Color = color or LINE,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, inst)
end

local function pad(inst, p)
	mk("UIPadding", {
		PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p),
		PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p),
	}, inst)
	return inst
end

local function label(props, parent)
	local defaults = {
		BackgroundTransparency = 1,
		Font = FONT_R,
		TextSize = 13,
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		RichText = true,
	}
	for k, v in pairs(props or {}) do
		defaults[k] = v
	end
	return mk("TextLabel", defaults, parent)
end

local function mix(a, b, t)
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

-- 0 degrees is straight up, and angles run clockwise -- the same convention the
-- data table uses, so a node's `theta` is literally where it appears.
local function polar(radius, thetaDeg)
	local a = math.rad(thetaDeg)
	return math.sin(a) * radius, -math.cos(a) * radius
end

local function energyById(id)
	for _, e in ipairs(Data.ENERGIES) do
		if e.id == id then
			return e
		end
	end
	return Data.ENERGIES[1]
end

local function statLabel(stat)
	local def = Stats.STATS[stat]
	return def and def.label or stat
end

local function pct(v)
	local n = v * 100
	if math.abs(n) >= 100 then
		return string.format("%+.0f%%", n)
	end
	return string.format("%+.1f%%", n)
end

--------------------------------------------------------------------------------
-- MOUNT
--
-- `opts` carries the live state and the callbacks:
--   state          { levels = { [id] = level }, tokens, rebirth, preset }
--   presets        how many slots this player has
--   inClouds       is the character standing in the Clouds right now
--   inCloudsCheck  () -> bool, polled while the wheel is open (walking off
--                  the deck sends no snapshot)
--   temperTokens   tokens held;  sacrificeRate  tokens for selling one point
--   buybackCost    tokens to buy one back;  skillBurned  points currently sold
--   onBuy(id)      -> the server does the real check; this only asks
--   onPreset(i)
--   onReset()  onSell()  onBuyBack()  onGoClouds()  onAscend()
--------------------------------------------------------------------------------

function MineSkillView.mount(parent, opts)
	opts = opts or {}
	local state = opts.state or { levels = {}, tokens = 0, rebirth = 0, preset = 1 }
	state.levels = state.levels or {}

	local view = {}
	-- How far the host ScreenGui pokes up under the Roblox topbar. Measured
	-- rather than assumed, because it depends on whether the ScreenGui ignores
	-- the inset and on the device's topbar height.
	local inset = 0
	local nodeViews = {}
	local edgeViews = {}
	local selected = nil
	local hovered = nil

	local root = mk("Frame", {
		Name = "SkillWheel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = INK,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
	}, parent)

	-- A very soft vignette so the wheel art does not run flat into the panels.
	mk("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(18, 20, 38), Color3.fromRGB(4, 5, 11)),
		Rotation = 90,
	}, root)

	----------------------------------------------------------------- top bar
	local top = mk("Frame", {
		Size = UDim2.new(1, 0, 0, TOP_H),
		BackgroundColor3 = PANEL,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
	}, root)
	local topPad = mk("UIPadding", { PaddingTop = UDim.new(0, 0) }, top)
	mk("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = LINE,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
	}, top)

	local title = label({
		Position = UDim2.fromOffset(PAD + 6, 10),
		Size = UDim2.fromOffset(340, 22),
		Font = FONT,
		TextSize = 19,
		Text = "IN THE CLOUDS",
	}, top)
	local subtitle = label({
		Position = UDim2.fromOffset(PAD + 6, 32),
		Size = UDim2.fromOffset(420, 16),
		Font = FONT_R,
		TextSize = 12,
		TextColor3 = MUTED,
		Text = "Re-cut your tree freely until you drop back down.",
	}, top)

	-- Tokens, dead centre of the bar. The wheel's centre line runs through it.
	local tokenPill = corner(mk("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(206, 34),
		BackgroundColor3 = PANEL_HI,
	}, top), 17)
	stroke(tokenPill, 1, GOLD, 0.55)
	local tokenText = label({
		Size = UDim2.fromScale(1, 1),
		Font = FONT,
		TextSize = 15,
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "0 POINTS TO SPEND",
	}, tokenPill)

	-- Preset tabs, right side.
	local presetBar = mk("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -(PAD + 6), 0.5, 0),
		Size = UDim2.fromOffset(Data.PRESETS.max * 34 + (Data.PRESETS.max - 1) * 6, 30),
		BackgroundTransparency = 1,
	}, top)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, presetBar)

	local presetButtons = {}
	for i = 1, Data.PRESETS.max do
		local b = corner(mk("TextButton", {
			Size = UDim2.fromOffset(34, 30),
			BackgroundColor3 = PANEL_HI,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = i,
		}, presetBar), 8)
		stroke(b, 1, LINE, 0.3)
		local t = label({
			Size = UDim2.fromScale(1, 1),
			Font = FONT,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = tostring(i),
		}, b)
		presetButtons[i] = { button = b, text = t }
		b.MouseButton1Click:Connect(function()
			if opts.onPreset then
				opts.onPreset(i)
			end
		end)
	end

	--------------------------------------------------------------- left panel
	local left = mk("Frame", {
		Position = UDim2.fromOffset(0, TOP_H),
		Size = UDim2.new(0, PANEL_W, 1, -TOP_H),
		BackgroundColor3 = PANEL,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
	}, root)
	mk("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = LINE,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
	}, left)

	local leftScroll = mk("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = LINE,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, left)
	pad(leftScroll, PAD)
	mk("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, leftScroll)

	local function sectionTitle(text, order, parentFrame)
		return label({
			Size = UDim2.new(1, 0, 0, 17),
			Font = FONT,
			TextSize = 12,
			TextColor3 = FAINT,
			Text = text,
			LayoutOrder = order,
		}, parentFrame)
	end

	sectionTitle("YOUR BUILD", 1, leftScroll)

	-- Headline: points spent and what it is worth, in the same currency the pets
	-- are balanced in. This is the number that tells you the tree is doing
	-- something.
	local summary = corner(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 86),
		BackgroundColor3 = PANEL_HI,
		LayoutOrder = 2,
	}, leftScroll), 10)
	stroke(summary, 1, LINE, 0.45)
	pad(summary, 12)
	local summaryTop = label({
		Size = UDim2.new(1, 0, 0, 26),
		Font = FONT,
		TextSize = 22,
		TextColor3 = GOLD,
		Text = "0",
	}, summary)
	local summarySub = label({
		Position = UDim2.fromOffset(0, 29),
		Size = UDim2.new(1, 0, 0, 16),
		TextSize = 13,
		TextColor3 = MUTED,
		Text = "power points from skills",
	}, summary)
	local summaryFoot = label({
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 0, 16),
		TextSize = 12,
		TextColor3 = FAINT,
		Text = "0 nodes | 0 spent",
	}, summary)

	local nextCard = corner(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 76),
		BackgroundColor3 = Color3.fromRGB(38, 33, 22),
		LayoutOrder = 2.5,
	}, leftScroll), 10)
	stroke(nextCard, 1, GOLD, 0.72)
	pad(nextCard, 11)
	label({ Size = UDim2.new(1, 0, 0, 14), TextSize = 12, TextColor3 = FAINT, Text = "NEXT REBIRTH" }, nextCard)
	local nextCoins = label({
		Position = UDim2.fromOffset(0, 17), Size = UDim2.new(1, 0, 0, 20),
		Font = FONT, TextSize = 16, TextColor3 = GOLD, Text = "-",
	}, nextCard)
	local nextTokens = label({
		Position = UDim2.fromOffset(0, 39), Size = UDim2.new(1, 0, 0, 16),
		TextSize = 13, TextColor3 = MUTED, Text = "-",
	}, nextCard)

	--[[
		RESET AND SACRIFICE.

		Both change the tree, so both live in the Clouds with everything else
		that does. Both take two taps: a reset undoes a whole build in one click,
		and a sacrifice cannot be undone at all. The second tap has three seconds
		before the button quietly disarms.
	]]
	local armed = { reset = 0, sell = 0 }
	local function isArmed(key)
		return os.clock() < (armed[key] or 0)
	end
	local function arm(key)
		armed[key] = os.clock() + 3
		view.refresh()
		task.delay(3.05, function()
			if root.Parent then
				view.refresh()
			end
		end)
	end

	local resetBtn = corner(mk("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = PANEL_HI,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = 2.2,
	}, leftScroll), 9)
	stroke(resetBtn, 1, LINE, 0.35)
	local resetText = label({
		Size = UDim2.fromScale(1, 1),
		Font = FONT,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "RESET TREE",
	}, resetBtn)
	resetBtn.MouseButton1Click:Connect(function()
		if not opts.inClouds or (state.refund or 0) <= 0 and Data.ownedCount(state) == 0 then
			return
		end
		if isArmed("reset") then
			armed.reset = 0
			if opts.onReset then
				opts.onReset()
			end
			view.refresh()
		else
			arm("reset")
		end
	end)

	--[[
		TOKENS: sell a free skill point, or buy a sold one back, at one price.

		Selling takes two taps. Buying back takes one -- it only ever undoes a
		sale, and cannot take you above what your rebirths have given you.
	]]
	sectionTitle("TOKENS", 2.6, leftScroll)
	local sacCard = corner(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 134),
		BackgroundColor3 = Color3.fromRGB(34, 28, 20),
		LayoutOrder = 2.7,
	}, leftScroll), 10)
	stroke(sacCard, 1, GOLD, 0.62)
	pad(sacCard, 11)
	label({ Size = UDim2.new(0.5, 0, 0, 14), TextSize = 12, TextColor3 = FAINT, Text = "TOKENS" }, sacCard)
	local sacRate = label({
		Size = UDim2.new(1, 0, 0, 14), TextSize = 12, TextColor3 = FAINT,
		TextXAlignment = Enum.TextXAlignment.Right, Text = "",
	}, sacCard)
	local sacTokens = label({
		Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 26),
		Font = FONT, TextSize = 22, TextColor3 = GOLD, Text = "0",
	}, sacCard)
	local soldText = label({
		Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 18),
		TextSize = 12, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Right, Text = "",
	}, sacCard)
	label({
		Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 16),
		TextSize = 12, TextColor3 = FAINT,
		Text = "Temperament rolls spend tokens. Rolls are never refunded.",
	}, sacCard)

	local function tokenButton(xScale, xOffset, colour)
		local btn = corner(mk("TextButton", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(xScale, xOffset, 1, 0),
			Size = UDim2.new(0.5, -4, 0, 38),
			BackgroundColor3 = colour,
			Text = "",
			AutoButtonColor = false,
		}, sacCard), 9)
		local txt = label({
			Size = UDim2.fromScale(1, 1),
			Font = FONT,
			TextSize = 13,
			TextColor3 = INK,
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = "",
		}, btn)
		return btn, txt
	end
	local sellBtn, sellText = tokenButton(0, 0, BAD)
	local backBtn, backText = tokenButton(0.5, 4, GOOD)

	sellBtn.MouseButton1Click:Connect(function()
		if not opts.inClouds or (state.tokens or 0) < 1 then
			return
		end
		if isArmed("sell") then
			armed.sell = 0
			if opts.onSell then
				opts.onSell()
			end
			view.refresh()
		else
			arm("sell")
		end
	end)
	backBtn.MouseButton1Click:Connect(function()
		if not opts.inClouds or (opts.skillBurned or 0) < 1 then
			return
		end
		if opts.onBuyBack then
			opts.onBuyBack()
		end
	end)

	sectionTitle("ACTIVE BONUSES", 3, leftScroll)

	local statList = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 4,
	}, leftScroll)
	mk("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, statList)

	local emptyHint = label({
		Size = UDim2.new(1, 0, 0, 32),
		TextSize = 12,
		TextColor3 = FAINT,
		TextWrapped = true,
		Text = "Nothing yet. Pick a root on the wheel to start a road.",
		LayoutOrder = 1,
	}, statList)

	-- One row per stat: name, value, and a bar showing how much of the hard cap
	-- this build has taken. Seeing the bar fill is the point -- a flat "+3%" with
	-- no context is what made the old tree feel pathetic.
	local statRows = {}
	local function statRow(stat, order)
		local row = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundTransparency = 1,
			LayoutOrder = order,
		}, statList)
		local name = label({
			Size = UDim2.new(1, -74, 0, 14),
			TextSize = 12,
			TextColor3 = TEXT,
			Text = statLabel(stat),
		}, row)
		local val = label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(74, 14),
			Font = FONT,
			TextSize = 12,
			TextColor3 = GOOD,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = "+0%",
		}, row)
		local track = corner(mk("Frame", {
			Position = UDim2.fromOffset(0, 20),
			Size = UDim2.new(1, 0, 0, 6),
			BackgroundColor3 = Color3.fromRGB(30, 34, 54),
			BorderSizePixel = 0,
		}, row), 3)
		local fill = corner(mk("Frame", {
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = GOOD,
			BorderSizePixel = 0,
		}, track), 3)
		-- Where skills alone are allowed to stop. Everything past it belongs to
		-- pets and runes, and showing the notch stops the bar reading as broken
		-- when it parks at half.
		local notch = mk("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(Data.SKILL_CAP_SHARE, 0, 0, -2),
			Size = UDim2.fromOffset(1, 10),
			BackgroundColor3 = Color3.fromRGB(120, 132, 172),
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
		}, track)
		return { frame = row, name = name, val = val, fill = fill, notch = notch }
	end

	sectionTitle("HOW IT WORKS", 90, leftScroll)
	local helpCard = corner(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = PANEL_HI,
		BackgroundTransparency = 0.35,
		LayoutOrder = 91,
	}, leftScroll), 10)
	pad(helpCard, 11)
	label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 13,
		TextColor3 = MUTED,
		TextWrapped = true,
		Text = table.concat({
			"Start at a <b>root</b>. Every colour has one and they are cheap.",
			"Each root splits into <b>two roads</b>. Pick one and the other greys out.",
			"The <b>big node</b> at the end of a road is the prize.",
			"Every node you buy makes the next one cost more - so pick one colour and go deep.",
		}, "\n\n"),
	}, helpCard)

	-------------------------------------------------------------- right panel
	local right = mk("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, TOP_H),
		Size = UDim2.new(0, PANEL_W, 1, -TOP_H),
		BackgroundColor3 = PANEL,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
	}, root)
	mk("Frame", {
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = LINE,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
	}, right)

	local detail = mk("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = LINE,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, right)
	pad(detail, PAD)
	mk("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, detail)

	local dPlaceholder = label({
		Size = UDim2.new(1, 0, 0, 72),
		TextSize = 14,
		TextColor3 = MUTED,
		TextWrapped = true,
		Text = "Tap any dot on the wheel to see what it does and what it costs.",
		LayoutOrder = 1,
	}, detail)

	local dCard = corner(mk("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = PANEL_HI,
		LayoutOrder = 2,
		Visible = false,
	}, detail), 10)
	stroke(dCard, 1, LINE, 0.4)
	pad(dCard, 13)
	mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, dCard)

	local dBadge = corner(mk("Frame", {
		Size = UDim2.fromOffset(120, 20),
		BackgroundColor3 = PANEL,
		LayoutOrder = 1,
		AutomaticSize = Enum.AutomaticSize.X,
	}, dCard), 6)
	pad(dBadge, 5)
	local dBadgeText = label({
		Size = UDim2.fromOffset(0, 14),
		AutomaticSize = Enum.AutomaticSize.X,
		Font = FONT,
		TextSize = 12,
		Text = "FIRE - BLAST",
	}, dBadge)

	local dName = label({
		Size = UDim2.new(1, 0, 0, 22),
		Font = FONT,
		TextSize = 18,
		LayoutOrder = 2,
		Text = "-",
	}, dCard)

	local dRank = label({
		Size = UDim2.new(1, 0, 0, 15),
		TextSize = 12,
		TextColor3 = MUTED,
		LayoutOrder = 3,
		Text = "-",
	}, dCard)

	-- Level pips: at a glance, how far this node is ranked up.
	local dPips = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 8),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
	}, dCard)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, dPips)

	local dNext = label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 12,
		TextWrapped = true,
		LayoutOrder = 5,
		Text = "",
	}, dCard)

	local dNote = label({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 13,
		TextColor3 = MUTED,
		TextWrapped = true,
		LayoutOrder = 6,
		Text = "",
	}, dCard)

	local buyBtn = corner(mk("TextButton", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = GOLD,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = 7,
	}, dCard), 9)
	local buyText = label({
		Size = UDim2.fromScale(1, 1),
		Font = FONT,
		TextSize = 14,
		TextColor3 = INK,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "UNLOCK",
	}, buyBtn)

	------------------------------------------------------------------- wheel
	local stage = mk("Frame", {
		Position = UDim2.fromOffset(PANEL_W, TOP_H),
		Size = UDim2.new(1, -PANEL_W * 2, 1, -TOP_H),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
	}, root)

	local wheel = mk("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		-- 0.92 of the stage height: the outer labels ride at 0.95 of the radius,
		-- and this keeps them clear of the top bar and the two panels.
		Size = UDim2.fromScale(0.92, 0.92),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		ClipsDescendants = false,
	}, stage)
	mk("UIAspectRatioConstraint", { AspectRatio = 1 }, wheel)

	-- Masked to a circle. As a square at 1.02 scale it showed hard edges down
	-- both sides and spilled over the top bar.
	local art = circle(mk("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = WHEEL_IMAGE,
		ImageTransparency = 0.34,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 1,
	}, wheel))

	-- Faint guide rings, one per row radius. They do a lot of the work of making
	-- the layout read as deliberate rather than scattered.
	for _, row in ipairs({ "root", "split", "cross", "fuse", "key", "cap" }) do
		local r = Data.ROWS[row].rFrac
		local ring = circle(mk("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(r * 2, r * 2),
			BackgroundTransparency = 1,
			ZIndex = 2,
		}, wheel))
		stroke(ring, 1, Color3.fromRGB(120, 140, 200), 0.86)
	end

	local edgeLayer = mk("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ZIndex = 3,
	}, wheel)
	local nodeLayer = mk("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ZIndex = 5,
	}, wheel)
	local labelLayer = mk("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ZIndex = 4,
	}, wheel)

	-- Centre hub: rebirth number, and the one line telling you what to do next.
	local hub = circle(mk("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		-- Must stay INSIDE the root ring (rFrac 0.285) or it swallows the root
		-- nodes and their rank labels.
		Size = UDim2.fromScale(0.21, 0.21),
		BackgroundColor3 = Color3.fromRGB(10, 12, 22),
		BackgroundTransparency = 0.12,
		ZIndex = 6,
	}, wheel))
	stroke(hub, 1, Color3.fromRGB(120, 140, 200), 0.7)
	local hubTop = label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.26, 0),
		Size = UDim2.fromScale(0.9, 0.16),
		Font = FONT_M,
		TextSize = 12,
		TextColor3 = FAINT,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "REBIRTH",
		ZIndex = 7,
	}, hub)
	local hubNum = label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.42, 0),
		Size = UDim2.fromScale(0.9, 0.3),
		Font = FONT,
		TextSize = 30,
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "0",
		ZIndex = 7,
	}, hub)
	-- The coin target used to live here, but the hub has to stay inside the root
	-- ring, and two lines of numbers do not fit in that circle. It moved to the
	-- left panel where it can actually be read.

	-- Wedge labels sit outside the outermost ring, upright, so a casual player
	-- can tell which slice is which without clicking anything.
	for _, e in ipairs(Data.ENERGIES) do
		local holder = mk("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(96, 30),
			BackgroundTransparency = 1,
			ZIndex = 4,
		}, labelLayer)
		holder:SetAttribute("theta", e.deg)
		holder:SetAttribute("rFrac", 0.95)
		label({
			Size = UDim2.new(1, 0, 0, 14),
			Font = FONT,
			TextSize = 12,
			TextColor3 = e.color,
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = string.upper(e.name),
			ZIndex = 4,
		}, holder)
		label({
			Position = UDim2.fromOffset(0, 15),
			Size = UDim2.new(1, 0, 0, 15),
			TextSize = 12,
			TextColor3 = FAINT,
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = e.verb,
			ZIndex = 4,
		}, holder)
		table.insert(edgeViews, { labelHolder = holder })
	end

	local ascend = corner(mk("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.fromOffset(230, 46),
		BackgroundColor3 = GOLD,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 20,
	}, stage), 23)
	stroke(ascend, 2, Color3.fromRGB(255, 244, 214), 0.4)
	local ascendText = label({
		Size = UDim2.fromScale(1, 1),
		Font = FONT,
		TextSize = 15,
		TextColor3 = INK,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "ASCEND",
		ZIndex = 21,
	}, ascend)
	-- On its own plate. Bare text here lands on the wheel's bottom wedge label
	-- and the two read as one garbled line.
	local ascendHintPlate = corner(mk("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -74),
		Size = UDim2.fromOffset(400, 28),
		BackgroundColor3 = INK,
		BackgroundTransparency = 0.12,
		ZIndex = 19,
	}, stage), 14)
	stroke(ascendHintPlate, 1, LINE, 0.5)
	local ascendHint = label({
		Size = UDim2.fromScale(1, 1),
		TextSize = 13,
		TextColor3 = MUTED,
		TextXAlignment = Enum.TextXAlignment.Center,
		Text = "Your tree locks when you break your first block.",
		ZIndex = 20,
	}, ascendHintPlate)
	-- One button, both directions: down to the mine from the Clouds, up to the
	-- Clouds from anywhere else. Opening Skills in the mine and being told the
	-- tree only changes somewhere else, with no way to get there from the
	-- screen saying so, is the lockout this replaced.
	ascend.MouseButton1Click:Connect(function()
		if opts.inClouds then
			if opts.onAscend then
				opts.onAscend()
			end
		elseif opts.onGoClouds then
			opts.onGoClouds()
		end
	end)

	------------------------------------------------------------------ tooltip
	local tip = corner(mk("Frame", {
		Size = UDim2.fromOffset(250, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(10, 12, 22),
		Visible = false,
		ZIndex = 50,
	}, root), 9)
	stroke(tip, 1, Color3.fromRGB(120, 140, 200), 0.4)
	pad(tip, 10)
	mk("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, tip)
	local tipName = label({
		Size = UDim2.new(1, 0, 0, 16), Font = FONT, TextSize = 14, LayoutOrder = 1, ZIndex = 51, Text = "",
	}, tip)
	local tipRow = label({
		Size = UDim2.new(1, 0, 0, 15), TextSize = 12, TextColor3 = FAINT, LayoutOrder = 2, ZIndex = 51, Text = "",
	}, tip)
	local tipBody = label({
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 13, TextWrapped = true, LayoutOrder = 3, ZIndex = 51, Text = "",
	}, tip)
	local tipCost = label({
		Size = UDim2.new(1, 0, 0, 14), Font = FONT, TextSize = 12, TextColor3 = GOLD,
		LayoutOrder = 4, ZIndex = 51, Text = "",
	}, tip)
	for _, c in ipairs(tip:GetChildren()) do
		if c:IsA("TextLabel") then
			c.ZIndex = 51
		end
	end

	--------------------------------------------------------------- build nodes
	local function nodeState(node)
		local level = Data.levelOf(state, node.id)
		if level > 0 then
			return level >= node.maxLevel and "maxed" or "owned"
		end
		local why = Data.blockedBy(state, node.id)
		if why then
			return why == "prereq" and "locked" or "blocked"
		end
		return "available"
	end

	local function colorFor(node, st)
		local e = energyById(node.energyId)
		if st == "owned" or st == "maxed" then
			return e.color
		elseif st == "available" then
			return mix(e.color, Color3.fromRGB(20, 24, 40), 0.45)
		end
		return Color3.fromRGB(26, 29, 44)
	end

	for _, node in ipairs(Data.NODES) do
		local holder = mk("Frame", {
			-- Named after the node so the layout can be audited by id rather than
			-- guessed at from pixel sizes (several rows share a size).
			Name = node.id,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(node.size, node.size),
			BackgroundTransparency = 1,
			ZIndex = 5,
		}, nodeLayer)

		local glow = circle(mk("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1.55, 1.55),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			ZIndex = 5,
		}, holder))

		local dot = circle(mk("TextButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(30, 34, 52),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 6,
		}, holder))
		local dotStroke = stroke(dot, 2, LINE, 0.2)

		-- Keystones and capstones get an inner ring so the hierarchy is visible
		-- from across the screen rather than only in the tooltip.
		local inner
		if node.row == "key" or node.row == "cap" then
			inner = circle(mk("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.52, 0.52),
				BackgroundColor3 = INK,
				BackgroundTransparency = 0.25,
				ZIndex = 7,
			}, dot))
		end

		-- Rank text rides OUTWARD along the node's own spoke (positioned in
		-- relayout), so it never falls into the hub or onto a neighbour.
		local rankText = label({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(54, 15),
			Font = FONT,
			TextSize = 12,
			TextColor3 = MUTED,
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = "",
			ZIndex = 8,
		}, holder)

		local nv = {
			node = node, holder = holder, dot = dot, glow = glow,
			stroke = dotStroke, inner = inner, rankText = rankText,
		}
		nodeViews[node.id] = nv

		dot.MouseButton1Click:Connect(function()
			selected = node.id
			view.refresh()
		end)
		dot.MouseEnter:Connect(function()
			hovered = node.id
			view.showTip(node)
		end)
		dot.MouseLeave:Connect(function()
			if hovered == node.id then
				hovered = nil
				tip.Visible = false
			end
		end)
	end

	--------------------------------------------------------------- build edges
	for _, edge in ipairs(Data.EDGES) do
		-- Rivalries are drawn as a badge on the node, not as a line through the
		-- hub -- ten diameters crossing the centre turned the middle into mud.
		if edge.kind ~= "rival" then
			local line = mk("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = LINE,
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
				ZIndex = 3,
			}, edgeLayer)
			table.insert(edgeViews, { line = line, edge = edge })
		end
	end

	--------------------------------------------------------------------- layout
	-- Re-seat the chrome under the topbar. Cheap, and it has to re-run whenever
	-- the viewport changes because the inset can change with it.
	local function applyInset()
		local off = math.max(0, -root.AbsolutePosition.Y)
		if off == inset then
			return
		end
		inset = off
		top.Size = UDim2.new(1, 0, 0, TOP_H + off)
		topPad.PaddingTop = UDim.new(0, off)
		left.Position = UDim2.fromOffset(0, TOP_H + off)
		left.Size = UDim2.new(0, PANEL_W, 1, -(TOP_H + off))
		right.Position = UDim2.new(1, 0, 0, TOP_H + off)
		right.Size = UDim2.new(0, PANEL_W, 1, -(TOP_H + off))
		stage.Position = UDim2.fromOffset(PANEL_W, TOP_H + off)
		stage.Size = UDim2.new(1, -PANEL_W * 2, 1, -(TOP_H + off))
	end

	local function relayout()
		applyInset()
		local size = wheel.AbsoluteSize.X
		if size <= 0 then
			return
		end
		local radius = size * 0.5

		for _, nv in pairs(nodeViews) do
			local x, y = polar(nv.node.rFrac * radius, nv.node.theta)
			nv.holder.Position = UDim2.new(0.5, x, 0.5, y)
			local lx, ly = polar(nv.node.rFrac * radius + nv.node.size * 0.5 + 9, nv.node.theta)
			nv.rankText.Position = UDim2.new(0.5, lx - x, 0.5, ly - y)
		end
		for _, ev in ipairs(edgeViews) do
			if ev.labelHolder then
				local x, y = polar(ev.labelHolder:GetAttribute("rFrac") * radius, ev.labelHolder:GetAttribute("theta"))
				ev.labelHolder.Position = UDim2.new(0.5, x, 0.5, y)
			elseif ev.line then
				local a = nodeViews[ev.edge.from]
				local b = nodeViews[ev.edge.to]
				if a and b then
					local ax, ay = polar(a.node.rFrac * radius, a.node.theta)
					local bx, by = polar(b.node.rFrac * radius, b.node.theta)
					local dx, dy = bx - ax, by - ay
					local len = math.sqrt(dx * dx + dy * dy)
					ev.line.Size = UDim2.fromOffset(len, ev.edge.kind == "xor" and 1 or 2)
					ev.line.Position = UDim2.new(0.5, (ax + bx) * 0.5, 0.5, (ay + by) * 0.5)
					ev.line.Rotation = math.deg(math.atan2(dy, dx))
				end
			end
		end
	end
	wheel:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	root:GetPropertyChangedSignal("AbsolutePosition"):Connect(relayout)
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)

	--------------------------------------------------------------------- tooltip
	function view.showTip(node)
		local level = Data.levelOf(state, node.id)
		local e = energyById(node.energyId)
		tipName.Text = node.name
		tipName.TextColor3 = e.color
		tipRow.Text = string.format("%s  -  %s  -  Level %d / %d",
			string.upper(node.energy), ROW_LABEL[node.row] or node.row, level, node.maxLevel)

		local lines = {}
		if level > 0 then
			local now = Data.statsAt(node.id, level)
			local parts = {}
			for stat, amount in pairs(now) do
				table.insert(parts, string.format("%s %s", statLabel(stat), pct(amount)))
			end
			table.sort(parts)
			table.insert(lines, "<b>Now:</b> " .. table.concat(parts, ", "))
		end
		if level < node.maxLevel then
			local parts = {}
			for stat, amount in pairs(node.stats) do
				table.insert(parts, string.format("%s %s", statLabel(stat), pct(amount)))
			end
			table.sort(parts)
			table.insert(lines, "<b>Next rank:</b> " .. table.concat(parts, ", "))
		else
			table.insert(lines, "<b>Fully ranked.</b>")
		end
		tipBody.Text = table.concat(lines, "\n")

		local cost = Data.nextCost(node.id, level, state)
		if cost then
			local afford = cost <= (state.tokens or 0)
			tipCost.Text = string.format("%d SP%s", cost, afford and "" or "  (you have " .. tostring(state.tokens or 0) .. ")")
			tipCost.TextColor3 = afford and GOLD or BAD
		else
			tipCost.Text = ""
		end

		local abs = nodeViews[node.id].holder.AbsolutePosition
		local rootAbs = root.AbsolutePosition
		local x = abs.X - rootAbs.X + 26
		local y = abs.Y - rootAbs.Y - 10
		x = math.min(x, root.AbsoluteSize.X - 270)
		y = math.clamp(y, 8, math.max(8, root.AbsoluteSize.Y - 180))
		tip.Position = UDim2.fromOffset(x, y)
		tip.Visible = true
	end

	---------------------------------------------------------------- detail panel
	local function renderDetail()
		if not selected then
			dCard.Visible = false
			dPlaceholder.Visible = true
			return
		end
		dPlaceholder.Visible = false
		dCard.Visible = true

		local node = Data.node(selected)
		local level = Data.levelOf(state, selected)
		local e = energyById(node.energyId)

		dBadge.BackgroundColor3 = mix(e.color, INK, 0.72)
		dBadgeText.Text = string.format("%s  -  %s", string.upper(node.energy), string.upper(ROW_LABEL[node.row] or node.row))
		dBadgeText.TextColor3 = e.color
		dName.Text = node.name
		dName.TextColor3 = e.color
		dRank.Text = string.format("Level %d of %d   -   %d power points a rank", level, node.maxLevel, node.points)

		for _, c in ipairs(dPips:GetChildren()) do
			if c:IsA("Frame") then
				c:Destroy()
			end
		end
		for i = 1, node.maxLevel do
			local pip = corner(mk("Frame", {
				Size = UDim2.fromOffset(math.max(10, 160 / node.maxLevel), 8),
				BackgroundColor3 = i <= level and e.color or Color3.fromRGB(38, 42, 62),
				BorderSizePixel = 0,
				LayoutOrder = i,
			}, dPips), 4)
		end

		local body = {}
		if level > 0 then
			local parts = {}
			for stat, amount in pairs(Data.statsAt(selected, level)) do
				table.insert(parts, string.format("  %s  <font color=\"#74E2A0\">%s</font>", statLabel(stat), pct(amount)))
			end
			table.sort(parts)
			table.insert(body, "<b>Active now</b>\n" .. table.concat(parts, "\n"))
		end
		if level < node.maxLevel then
			local parts = {}
			for stat, amount in pairs(node.stats) do
				table.insert(parts, string.format("  %s  <font color=\"#FFD578\">%s</font>", statLabel(stat), pct(amount)))
			end
			table.sort(parts)
			table.insert(body, string.format("<b>Rank %d adds</b>\n%s", level + 1, table.concat(parts, "\n")))
		end
		dNext.Text = table.concat(body, "\n\n")

		-- Everything the player needs to know before committing: what it wants,
		-- what it will close off, and where it reaches.
		local notes = {}
		if #node.prereqs > 0 then
			local names = {}
			for _, p in ipairs(node.prereqs) do
				local pn = Data.node(p)
				table.insert(names, (pn and pn.name or p) .. (Data.levelOf(state, p) > 0 and " ✓" or ""))
			end
			table.insert(notes, string.format("Needs %s: %s",
				node.prereqMode == "or" and "either" or "all of", table.concat(names, ", ")))
		end
		if node.xorGroup then
			for _, other in ipairs(Data.NODES) do
				if other.xorGroup == node.xorGroup and other.id ~= node.id then
					table.insert(notes, string.format("Road choice: taking this closes <b>%s</b>. The wedge stays open either way.", other.name))
				end
			end
		end
		if node.rivalOf then
			local r = Data.node(node.rivalOf)
			table.insert(notes, string.format("Rival keystone: you may own this <b>or</b> %s, not both.", r and r.name or node.rivalOf))
		end
		if node.crossesInto then
			table.insert(notes, string.format("Reaches into <b>%s</b>.", node.crossesInto))
		end
		local why, other = Data.blockedBy(state, selected)
		if why == "road" then
			table.insert(notes, string.format("<font color=\"#EE6A76\">Locked: you took %s down this root.</font>", other and other.name or "the other road"))
		elseif why == "rival" then
			table.insert(notes, string.format("<font color=\"#EE6A76\">Locked: %s is its rival and you own it.</font>", other and other.name or "the rival"))
		elseif why == "prereq" then
			table.insert(notes, "<font color=\"#8B97BA\">Locked: buy what it needs first.</font>")
		end
		dNote.Text = table.concat(notes, "\n\n")

		local ok, reason, _, cost = Data.canBuy(state, selected)
		cost = cost or Data.nextCost(selected, level, state)
		if level >= node.maxLevel then
			buyBtn.BackgroundColor3 = Color3.fromRGB(40, 46, 68)
			buyText.TextColor3 = MUTED
			buyText.Text = "FULLY RANKED"
		elseif ok then
			buyBtn.BackgroundColor3 = GOLD
			buyText.TextColor3 = INK
			buyText.Text = string.format("%s  -  %d SP  (you have %d)", level > 0 and "RANK UP" or "UNLOCK",
				cost or 0, state.tokens or 0)
		elseif reason == "tokens" then
			buyBtn.BackgroundColor3 = Color3.fromRGB(46, 38, 40)
			buyText.TextColor3 = BAD
			buyText.Text = string.format("NEEDS %d SP", cost or 0)
		else
			buyBtn.BackgroundColor3 = Color3.fromRGB(34, 38, 56)
			buyText.TextColor3 = MUTED
			buyText.Text = "LOCKED"
		end
	end

	buyBtn.MouseButton1Click:Connect(function()
		if selected and opts.onBuy then
			opts.onBuy(selected)
		end
	end)

	------------------------------------------------------------------- refresh
	function view.refresh()
		-- Nodes
		for id, nv in pairs(nodeViews) do
			local st = nodeState(nv.node)
			local e = energyById(nv.node.energyId)
			local c = colorFor(nv.node, st)
			nv.dot.BackgroundColor3 = c

			if st == "maxed" then
				nv.stroke.Color = Color3.fromRGB(255, 255, 255)
				nv.stroke.Transparency = 0.1
				nv.glow.BackgroundTransparency = 0.82
				nv.glow.BackgroundColor3 = e.color
			elseif st == "owned" then
				nv.stroke.Color = e.color
				nv.stroke.Transparency = 0.05
				nv.glow.BackgroundTransparency = 0.9
				nv.glow.BackgroundColor3 = e.color
			elseif st == "available" then
				-- "Can I press this right now" is the signal a casual player
				-- actually needs, so affordability gets its own brightness.
				local cost = Data.nextCost(id, Data.levelOf(state, id), state) or math.huge
				if cost <= (state.tokens or 0) then
					nv.stroke.Color = e.color
					nv.stroke.Transparency = 0
					nv.glow.BackgroundColor3 = e.color
					nv.glow.BackgroundTransparency = 0.72
				else
					nv.stroke.Color = e.color
					nv.stroke.Transparency = 0.62
					nv.glow.BackgroundTransparency = 1
				end
			else
				nv.stroke.Color = Color3.fromRGB(52, 58, 82)
				nv.stroke.Transparency = 0.4
				nv.glow.BackgroundTransparency = 1
			end
			if id == selected then
				nv.stroke.Color = Color3.fromRGB(255, 255, 255)
				nv.stroke.Transparency = 0
				nv.stroke.Thickness = 3
			else
				nv.stroke.Thickness = 2
			end

			local lvl = Data.levelOf(state, id)
			nv.rankText.Text = lvl > 0 and string.format("%d/%d", lvl, nv.node.maxLevel) or ""
			nv.rankText.TextColor3 = lvl >= nv.node.maxLevel and GOLD or MUTED
			if nv.inner then
				nv.inner.BackgroundTransparency = lvl > 0 and 0.55 or 0.25
			end
		end

		-- Edges light up once both ends are owned.
		for _, ev in ipairs(edgeViews) do
			if ev.line then
				local a = Data.levelOf(state, ev.edge.from) > 0
				local b = Data.levelOf(state, ev.edge.to) > 0
				local e = energyById((Data.node(ev.edge.from) or {}).energyId or "fire")
				if ev.edge.kind == "xor" then
					ev.line.BackgroundColor3 = (a or b) and BAD or LINE
					ev.line.BackgroundTransparency = (a or b) and 0.55 or 0.88
				elseif a and b then
					ev.line.BackgroundColor3 = e.color
					ev.line.BackgroundTransparency = 0.15
				elseif a then
					ev.line.BackgroundColor3 = mix(e.color, LINE, 0.5)
					ev.line.BackgroundTransparency = 0.45
				else
					ev.line.BackgroundColor3 = LINE
					ev.line.BackgroundTransparency = 0.72
				end
			end
		end

		-- Left panel totals
		local totals = Data.totalStats(state, Stats)
		local value = Stats.valueOf(totals)
		local owned = Data.ownedCount(state)
		local spent = Data.totalSpent(state)
		summaryTop.Text = string.format("%d", math.floor(value + 0.5))
		summaryFoot.Text = string.format("%d node%s  |  %d SP spent  |  prices x%.2f",
			owned, owned == 1 and "" or "s", spent, Data.inflation(state))

		local any = false
		local order = 0
		for _, stat in ipairs(Stats.STAT_ORDER) do
			local amount = totals[stat]
			if amount and amount > 0 then
				any = true
				order += 1
				if not statRows[stat] then
					statRows[stat] = statRow(stat, order)
				end
				local r = statRows[stat]
				r.frame.LayoutOrder = order
				r.frame.Visible = true
				r.val.Text = pct(amount)
				local def = Stats.STATS[stat]
				local frac = amount / (amount + 1)
				r.fill.Size = UDim2.fromScale(frac, 1)
				r.fill.BackgroundColor3 = frac >= Data.SKILL_CAP_SHARE - 0.001 and GOLD or GOOD
				r.val.TextColor3 = frac >= Data.SKILL_CAP_SHARE - 0.001 and GOLD or GOOD
			elseif statRows[stat] then
				statRows[stat].frame.Visible = false
			end
		end
		emptyHint.Visible = not any

		-- Top bar
		tokenText.Text = string.format("%d POINT%s TO SPEND", state.tokens or 0, (state.tokens or 0) == 1 and "" or "S")
		hubNum.Text = tostring(state.rebirth or 0)
		local rc = Data.rebirthCost((state.rebirth or 0) + 1)
		local money
		if rc >= 1e9 then
			money = string.format("%.2fB", rc / 1e9)
		elseif rc >= 1e6 then
			money = string.format("%.1fM", rc / 1e6)
		else
			money = string.format("%d", rc)
		end
		nextCoins.Text = money .. " coins"
		local grant = Data.tokensFor((state.rebirth or 0) + 1)
		nextTokens.Text = string.format("+%d skill point%s   +%d tokens", grant, grant == 1 and "" or "s",
			Data.rebirthTokens((state.rebirth or 0) + 1))

		local slots = Data.presetsAvailable(opts.boughtSecond)
		for i, pb in ipairs(presetButtons) do
			local unlocked = i <= slots
			pb.button.BackgroundColor3 = (i == state.preset) and GOLD or PANEL_HI
			pb.text.TextColor3 = (i == state.preset) and INK or (unlocked and TEXT or FAINT)
			pb.text.Text = unlocked and tostring(i) or "🔒"
		end

		local inClouds = Data.canEdit(opts.inClouds)
		title.Text = inClouds and "IN THE CLOUDS" or "SKILL TREE"
		subtitle.Text = inClouds
			and "Spend, reset and sacrifice skill points here."
			or "Your tree only changes in the Clouds."
		subtitle.TextColor3 = MUTED
		ascendText.Text = inClouds and "BACK TO THE MINE" or "GO TO THE CLOUDS"
		ascendHint.Text = inClouds
			and "Leave the Clouds and your tree locks until you come back up."
			or "Free, any time. Coming back down puts you at the top of your zone."

		-- Reset. The number is the server's own figure, not one worked out
		-- from levels here: node prices inflate with breadth, so levels alone
		-- cannot say what was paid.
		local refund = state.refund or 0
		local canReset = inClouds and (refund > 0 or Data.ownedCount(state) > 0)
		local resetArmed = canReset and isArmed("reset")
		resetBtn.BackgroundColor3 = resetArmed and BAD or PANEL_HI
		resetText.TextColor3 = resetArmed and INK or (canReset and TEXT or FAINT)
		if not inClouds then
			resetText.Text = "RESET TREE  -  in the Clouds"
		elseif not canReset then
			resetText.Text = "RESET TREE  -  nothing spent"
		elseif resetArmed then
			resetText.Text = string.format("TAP AGAIN: REFUND %d SP", refund)
		else
			resetText.Text = string.format("RESET TREE  -  refund %d SP", refund)
		end

		-- Tokens. Prices come from the snapshot, which reads them off the same
		-- constants the server charges, so the buttons cannot disagree with it.
		local rate = tonumber(opts.sacrificeRate) or Data.UNUSED_SKILL_POINT_SELL or 30
		local backCost = tonumber(opts.buybackCost) or Data.BUYBACK_TOKENS or rate
		local held = tonumber(opts.temperTokens) or 0
		local free = state.tokens or 0
		local sold = tonumber(opts.skillBurned) or 0
		sacTokens.Text = tostring(held)
		sacRate.Text = string.format("1 skill point = %d tokens", rate)
		soldText.Text = sold > 0 and string.format("%d point%s sold", sold, sold == 1 and "" or "s") or ""

		local canSell = inClouds and free >= 1
		local sellArmed = canSell and isArmed("sell")
		sellBtn.BackgroundColor3 = sellArmed and GOLD or (canSell and BAD or PANEL_HI)
		sellText.TextColor3 = canSell and INK or FAINT
		if not inClouds then
			sellText.Text = "IN THE CLOUDS"
		elseif free < 1 then
			sellText.Text = "NO FREE POINTS"
		elseif sellArmed then
			sellText.Text = string.format("TAP AGAIN +%d", rate)
		else
			sellText.Text = string.format("SELL 1  +%d", rate)
		end

		local canBack = inClouds and sold >= 1 and held >= backCost
		backBtn.BackgroundColor3 = canBack and GOOD or PANEL_HI
		backText.TextColor3 = canBack and INK or FAINT
		if not inClouds then
			backText.Text = "IN THE CLOUDS"
		elseif sold < 1 then
			backText.Text = "NOTHING SOLD"
		elseif held < backCost then
			backText.Text = string.format("NEED %d", backCost)
		else
			backText.Text = string.format("BUY BACK  -%d", backCost)
		end

		renderDetail()
		relayout()
	end

	-- Everything from the snapshot arrives here: the tree itself, and the flags
	-- around it (where you are standing, the second preset, tokens held).
	function view.setOpts(newOpts)
		for k, val in pairs(newOpts or {}) do
			if k == "state" and type(val) == "table" then
				--[[
					The wheel draws from `state`, captured once at mount -- not
					from opts.state. Copying it onto opts like every other key
					meant the wheel never saw a single snapshot: it sat at
					"0 POINTS TO SPEND" for the whole session, every node dim and
					unaffordable, and a purchase the server accepted never showed
					as owned. That is what "skill points don't work" was.
				]]
				state = val
				state.levels = state.levels or {}
			else
				opts[k] = val
			end
		end
		view.refresh()
	end

	function view.setState(newState)
		state = newState
		state.levels = state.levels or {}
		view.refresh()
	end

	view.root = root
	view.state = function()
		return state
	end
	view.select = function(id)
		selected = id
		view.refresh()
	end

	-- Walking off the deck, jumping to the lobby or being teleported away sends
	-- no snapshot, so while the wheel is on screen it asks where you are. One
	-- distance check, and only while visible.
	if opts.inCloudsCheck then
		task.spawn(function()
			while root.Parent do
				if root.Visible then
					local ok, now = pcall(opts.inCloudsCheck)
					now = ok and now == true
					if now ~= (opts.inClouds == true) then
						opts.inClouds = now
						view.refresh()
					end
				end
				task.wait(0.4)
			end
		end)
	end

	task.defer(function()
		relayout()
		view.refresh()
	end)
	return view
end

return MineSkillView
