--[[
	MineTradeView -- trading (and coinflipping) with another player in the server.

	Pieces:
	  picker   everyone else in this server, each with a TRADE button
	  invite   "X wants to trade" -- ACCEPT / DECLINE, with the time left
	  window   the other player's avatar down the left, their offer beside it,
	           yours on the right, and a bag strip underneath: your items to
	           offer, or theirs to point at
	  flip     the coin, when a coinflip lands

	Talking without typing: tap any of THEIR items -- on the table or in their
	bag -- to mark it WANT (green), then NO (red), then clear. Type a number in
	the "ask" box on one of their currencies to say how much you want. They see
	all of it on their side; none of it changes the deal.

	The server owns every rule (TradeService): what can be offered, the two
	accepts, the countdown, and the commit. This only asks and draws, and what it
	draws for both offers is always the server's cleaned copy.
]]
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local T = require(shared:WaitForChild("MineTheme"))
local Gear = require(shared:WaitForChild("MineGear"))
local Cards = require(shared:WaitForChild("MineCards"))
local PackFX = require(shared:WaitForChild("MinePackFX"))
local okLucky, LuckyBlocks = pcall(function()
	return require(shared:WaitForChild("MineLuckyBlocks"))
end)
if not okLucky then
	LuckyBlocks = nil
end

local okAudio, Audio = pcall(function()
	return require(shared:WaitForChild("MineAudio"))
end)
if not okAudio then
	Audio = nil
end

local MineTradeView = {}
local LP = Players.LocalPlayer

local WANT_INK = Color3.fromRGB(88, 214, 120)
local NO_INK = Color3.fromRGB(235, 84, 84)
local FLIP_INK = Color3.fromRGB(235, 70, 96)

local function mk(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props or {}) do
		i[k] = v
	end
	if parent then
		i.Parent = parent
	end
	return i
end

local function round(o, r)
	mk("UICorner", { CornerRadius = UDim.new(0, r or T.RADIUS) }, o)
	return o
end

local function stroke(o, col, th, tr)
	return mk("UIStroke", { Color = col or T.LINE, Thickness = th or T.STROKE, Transparency = tr or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end

local function text(parent, props)
	local l = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = props.Font or T.FONT_M,
		TextSize = props.TextSize or 14,
		TextColor3 = props.TextColor3 or T.TEXT,
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = props.Text or "",
		Position = props.Position or UDim2.new(),
		Size = props.Size or UDim2.new(1, 0, 0, 20),
		ZIndex = props.ZIndex or 2,
	}, parent)
	return l
end

local function button(parent, label, colour, ink, pos, size)
	local b = mk("TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = colour or T.CARD,
		Text = label,
		Font = T.FONT,
		TextSize = 16,
		TextColor3 = ink or T.TEXT,
		Position = pos or UDim2.new(),
		Size = size or UDim2.fromOffset(120, 40),
		ZIndex = 3,
	}, parent)
	round(b, T.RADIUS_SM)
	return b
end

local function commas(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

local function digits(s)
	return math.floor(tonumber((tostring(s or ""):gsub("[^%d]", ""))) or 0)
end

-- A window laid out at one size and scaled to whatever screen it is on.
local function fitTo(gui, frame, w, h)
	local sc = mk("UIScale", {}, frame)
	local function refit()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local ui = gui:FindFirstChildOfClass("UIScale")
		local k = (ui and ui.Scale > 0.05) and ui.Scale or 1
		sc.Scale = math.min(1, (vp.X / k - 20) / w, (vp.Y / k - 20) / h)
	end
	refit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
	end
	local ui = gui:FindFirstChildOfClass("UIScale")
	if ui then
		ui:GetPropertyChangedSignal("Scale"):Connect(refit)
	end
end

local function rarityInk(row, kind)
	if kind == "gear" then
		return Gear.RARITY_COLOR[row.rarity] or T.MUTED
	end
	if kind == "runes" then
		local tierInk = { T.MUTED, T.GREEN, T.GEM, T.DUST, T.GOLD }
		return tierInk[math.clamp(tonumber(row.tier) or 1, 1, 5)]
	end
	if kind == "cards" then
		return (Cards.RARITY_COLOR and Cards.RARITY_COLOR[row.rarityId or ""]) or T.MUTED
	end
	return T.GOLD
end

local KINDS = { "cards", "packs", "runes", "gear", "potions" }
local KIND_LABEL = { cards = "Cards", packs = "Packs", runes = "Runes", gear = "Gear", potions = "Potions" }

-- There was a sixth tab, "fossils", reading p.fossilPieces. Fossils are retired
-- (§0.12) and every piece was cashed out, so the tab is gone with the kind.
local function bagSource(snap, bagKind)
	return snap[bagKind] or {}
end
local CURRENCIES = {
	{ key = "gems", label = "GEMS", ink = T.GEM, field = "gems" },
	{ key = "dust", label = "STARDUST", ink = T.DUST, field = "dust" },
	{ key = "tokens", label = "TOKENS", ink = T.GOLD, field = "temperTokens" },
}

local function idOf(kind, row)
	if kind == "cards" then return row.serial or row.id end
	if kind == "packs" then return row.uid end
	return row.id
end

local function markKey(kind, row)
	local id = idOf(kind, row)
	return id and (kind .. ":" .. tostring(id)) or nil
end

local function nextMark(m)
	if m == nil then return "want" end
	if m == "want" then return "no" end
	return nil
end

-- Same stacking keys inventory uses for packs so Greyvein×6 is one tile,
-- while every offer still names real pack uids / card serials / gear ids.
local function stackKey(kind, row)
	if type(row) ~= "table" then
		return tostring(row)
	end
	if kind == "packs" then
		local isBlock = row.kind == "lucky_block" or row.blockId ~= nil
		if isBlock and LuckyBlocks and LuckyBlocks.stackKey then
			return "pack:" .. tostring(LuckyBlocks.stackKey(row))
		end
		local luckMult = tonumber(row.luck) or 1
		local luckPct = (luckMult > 1) and math.floor((luckMult - 1) * 100 + 0.5) or 0
		return "pack:" .. tostring(row.packId or row.blockId or "?") .. "|luck:" .. tostring(luckPct)
	end
	if kind == "cards" then
		return "card:" .. tostring(row.cardKey or row.name or "?")
			.. "|" .. tostring(row.rarityId or "")
			.. "|" .. tostring(row.variant or "Normal")
	end
	if kind == "runes" then
		return "rune:" .. tostring(row.stat or "?")
			.. "|" .. tostring(row.tier or 1)
			.. "|" .. tostring(row.pct or 0)
	end
	if kind == "gear" then
		return "gear:" .. tostring(row.catalogId or row.setName or row.name or "?")
			.. "|" .. tostring(row.rarity or "")
			.. "|" .. tostring(row.slot or "")
	end
	return kind .. ":" .. tostring(idOf(kind, row))
end

local GEAR_RANK = { F = 1, D = 2, C = 3, B = 4, A = 5, S = 6, SS = 7, SSS = 8 }

local function rarityRank(kind, row)
	if kind == "cards" then
		return (Cards.RARITY_RANK and Cards.RARITY_RANK[row.rarityId or ""]) or 0
	end
	if kind == "gear" then
		return GEAR_RANK[row.rarity or ""] or 0
	end
	if kind == "runes" then
		return tonumber(row.tier) or 0
	end
	if kind == "packs" then
		if row.kind == "lucky_block" or row.blockId then
			return (GEAR_RANK[row.startGrade or "F"] or 0) + 50
		end
		return tonumber(row.tier) or 0
	end
	return 0
end

local function groupStacks(kind, rows)
	local groups, order = {}, {}
	for _, row in ipairs(rows or {}) do
		if type(row) == "table" then
			local key = stackKey(kind, row)
			local g = groups[key]
			if not g then
				g = {}
				for k, v in pairs(row) do
					g[k] = v
				end
				g._stackKey = key
				g.count = 0
				g.ids = {}
				g.members = {}
				groups[key] = g
				order[#order + 1] = g
			end
			g.count += 1
			g.members[#g.members + 1] = row
			local id = idOf(kind, row)
			if id ~= nil then
				g.ids[#g.ids + 1] = id
				-- Keep a live uid/serial on the stack so offers never lose identity.
				if kind == "packs" then
					g.uid = g.uid or id
				elseif kind == "cards" then
					g.serial = g.serial or id
				else
					g.id = g.id or id
				end
			end
		end
	end
	table.sort(order, function(a, b)
		local ra, rb = rarityRank(kind, a), rarityRank(kind, b)
		if ra ~= rb then
			return ra > rb
		end
		local na = tostring(a.name or a.packName or a.packId or a.stat or a.setName or "")
		local nb = tostring(b.name or b.packName or b.packId or b.stat or b.setName or "")
		return na < nb
	end)
	return order
end

local function cardStatLines(row)
	if type(row) ~= "table" or type(Cards.describe) ~= "function" then
		return {}
	end
	local ok, _kit, lines = pcall(Cards.describe, row)
	if ok and type(lines) == "table" then
		return lines
	end
	-- Some callers only ever used the second return; tolerate a single table.
	if ok and type(_kit) == "table" and type(_kit[1]) == "string" then
		return _kit
	end
	return {}
end

local function cardStatLine(row)
	local lines = cardStatLines(row)
	return lines[1] and tostring(lines[1]) or nil
end

function MineTradeView.mount(gui, opts)
	opts = opts or {}
	local net = opts.net
	local getSnap = opts.getSnap or function() return nil end
	local ctl = {}

	----------------------------------------------------------------------------
	-- PICKER
	----------------------------------------------------------------------------
	local picker = mk("Frame", {
		Name = "TradePicker", Visible = false, Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(440, 480), BackgroundColor3 = T.PANEL, ZIndex = 80,
	}, gui)
	round(picker, T.RADIUS_LG)
	stroke(picker, T.LINE, 2)
	fitTo(gui, picker, 440, 480)
	text(picker, { Text = "TRADE", Font = T.FONT, TextSize = 24, Position = UDim2.fromOffset(20, 14),
		Size = UDim2.new(1, -80, 0, 30), ZIndex = 81 })
	text(picker, { Text = "Pick someone in this server to trade or coinflip with.", TextColor3 = T.MUTED,
		Position = UDim2.fromOffset(20, 44), Size = UDim2.new(1, -40, 0, 18), ZIndex = 81 })
	local pickClose = button(picker, "X", T.CARD, T.TEXT, UDim2.new(1, -52, 0, 12), UDim2.fromOffset(40, 40))
	pickClose.ZIndex = 82
	local list = mk("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6,
		Position = UDim2.fromOffset(16, 76), Size = UDim2.new(1, -32, 1, -92),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 81,
	}, picker)
	mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local function paintPicker()
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("GuiObject") then c:Destroy() end
		end
		-- Roblox's rules for this player (set by the server on join).
		if LP:GetAttribute("PolicyNoTrade") == true then
			local note = mk("Frame", { BackgroundColor3 = T.CARD, Size = UDim2.new(1, -6, 0, 64), ZIndex = 82 }, list)
			round(note)
			text(note, { Text = "Trading isn't available in your region.", TextColor3 = T.MUTED,
				TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 83 })
			return
		end
		local others = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP then table.insert(others, p) end
		end
		table.sort(others, function(x, y) return x.DisplayName:lower() < y.DisplayName:lower() end)
		if #others == 0 then
			local empty = mk("Frame", { BackgroundColor3 = T.CARD, Size = UDim2.new(1, -6, 0, 64), ZIndex = 82 }, list)
			round(empty)
			text(empty, { Text = "Nobody else is in this server yet.", TextColor3 = T.MUTED,
				TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 83 })
			return
		end
		for i, p in ipairs(others) do
			local row = mk("Frame", { BackgroundColor3 = T.CARD, Size = UDim2.new(1, -6, 0, 64), LayoutOrder = i, ZIndex = 82 }, list)
			round(row)
			local face = mk("ImageLabel", { BackgroundColor3 = T.INK, Position = UDim2.fromOffset(10, 8),
				Size = UDim2.fromOffset(48, 48), ZIndex = 83 }, row)
			round(face, 24)
			task.spawn(function()
				local ok, img = pcall(function()
					return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
				end)
				if ok and face.Parent then face.Image = img end
			end)
			text(row, { Text = p.DisplayName, Font = T.FONT, TextSize = 17, Position = UDim2.fromOffset(70, 12),
				Size = UDim2.new(1, -200, 0, 22), ZIndex = 83 })
			text(row, { Text = "@" .. p.Name, TextColor3 = T.FAINT, TextSize = 13, Position = UDim2.fromOffset(70, 34),
				Size = UDim2.new(1, -200, 0, 18), ZIndex = 83 })
			local go = button(row, "TRADE", T.GREEN, Color3.fromRGB(14, 40, 20), UDim2.new(1, -118, 0.5, -18), UDim2.fromOffset(106, 36))
			go.ZIndex = 84
			go.MouseButton1Click:Connect(function()
				net:FireServer("tradeAsk", { to = p.UserId })
				picker.Visible = false
			end)
		end
	end
	pickClose.MouseButton1Click:Connect(function()
		picker.Visible = false
	end)
	Players.PlayerAdded:Connect(function()
		if picker.Visible then paintPicker() end
	end)
	Players.PlayerRemoving:Connect(function()
		task.defer(function()
			if picker.Visible then paintPicker() end
		end)
	end)

	----------------------------------------------------------------------------
	-- INVITE
	----------------------------------------------------------------------------
	local invite = mk("Frame", {
		Name = "TradeInvite", Visible = false, Active = true,
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 120),
		Size = UDim2.fromOffset(440, 128), BackgroundColor3 = T.PANEL, ZIndex = 90,
	}, gui)
	round(invite, T.RADIUS_LG)
	stroke(invite, T.GOLD, 2)
	local invWho = text(invite, { Text = "", Font = T.FONT, TextSize = 20, Position = UDim2.fromOffset(18, 14),
		Size = UDim2.new(1, -36, 0, 26), ZIndex = 91 })
	text(invite, { Text = "wants to trade with you", TextColor3 = T.MUTED, Position = UDim2.fromOffset(18, 40),
		Size = UDim2.new(1, -36, 0, 18), ZIndex = 91 })
	local yes = button(invite, "ACCEPT", T.GREEN, Color3.fromRGB(14, 40, 20), UDim2.fromOffset(18, 70), UDim2.new(0.5, -24, 0, 40))
	local no = button(invite, "DECLINE", T.CARD, T.TEXT, UDim2.new(0.5, 6, 0, 70), UDim2.new(0.5, -24, 0, 40))
	yes.ZIndex, no.ZIndex = 92, 92
	local timeBar = mk("Frame", { BackgroundColor3 = T.GOLD, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 14, 1, -6), Size = UDim2.new(1, -28, 0, 3), ZIndex = 92 }, invite)
	local inviteToken = nil
	local function answer(ok)
		inviteToken = nil
		invite.Visible = false
		net:FireServer("tradeRespond", { accept = ok })
	end
	yes.MouseButton1Click:Connect(function() answer(true) end)
	no.MouseButton1Click:Connect(function() answer(false) end)

	function ctl.invite(payload)
		if type(payload) ~= "table" then return end
		local token = {}
		inviteToken = token
		invWho.Text = tostring(payload.name or "Someone")
		invite.Visible = true
		local ttl = tonumber(payload.ttl) or 30
		local t0 = os.clock()
		task.spawn(function()
			while inviteToken == token and invite.Visible do
				local left = 1 - (os.clock() - t0) / ttl
				if left <= 0 then
					inviteToken = nil
					invite.Visible = false
					break
				end
				timeBar.Size = UDim2.new(left, -28 * left, 0, 3)
				task.wait(0.05)
			end
		end)
	end

	----------------------------------------------------------------------------
	-- THE TRADE WINDOW
	----------------------------------------------------------------------------
	local W, H = 1180, 680
	local win = mk("Frame", {
		Name = "TradeWindow", Visible = false, Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(W, H), BackgroundColor3 = T.PANEL, ZIndex = 80,
	}, gui)
	round(win, T.RADIUS_LG)
	local winStroke = stroke(win, T.GOLD, 2)
	fitTo(gui, win, W, H)
	local title = text(win, { Text = "TRADE", Font = T.FONT, TextSize = 24, Position = UDim2.fromOffset(22, 14),
		Size = UDim2.new(1, -330, 0, 30), ZIndex = 81 })
	local modeChip = mk("TextLabel", { BackgroundColor3 = T.GOLD, Text = "TRADE", Font = T.FONT, TextSize = 15,
		TextColor3 = T.ON_GOLD, Position = UDim2.new(1, -262, 0, 16), Size = UDim2.fromOffset(196, 28), ZIndex = 82 }, win)
	round(modeChip, 14)
	local winClose = button(win, "X", T.CARD, T.TEXT, UDim2.new(1, -54, 0, 12), UDim2.fromOffset(40, 40))
	winClose.ZIndex = 82

	-- The other player, down the left.
	local who = mk("Frame", { BackgroundColor3 = T.INK, Position = UDim2.fromOffset(16, 60),
		Size = UDim2.fromOffset(244, 372), ZIndex = 81 }, win)
	round(who)
	local whoStroke = stroke(who, T.LINE, 2)
	local avatar = mk("ImageLabel", { BackgroundColor3 = T.CARD, Image = "", ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(228, 252), ZIndex = 82 }, who)
	round(avatar, T.RADIUS_SM)
	local whoName = text(who, { Text = "", Font = T.FONT, TextSize = 21, TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(8, 264), Size = UDim2.new(1, -16, 0, 26), ZIndex = 82 })
	local whoUser = text(who, { Text = "", TextColor3 = T.FAINT, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(8, 289), Size = UDim2.new(1, -16, 0, 18), ZIndex = 82 })
	local whoState = mk("TextLabel", { BackgroundColor3 = T.CARD, Text = "", Font = T.FONT, TextSize = 14,
		TextColor3 = T.MUTED, Position = UDim2.fromOffset(28, 314), Size = UDim2.new(1, -56, 0, 26), ZIndex = 82 }, who)
	round(whoState, 13)
	local whoAsks = text(who, { Text = "", TextColor3 = T.GOLD, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(8, 344), Size = UDim2.new(1, -16, 0, 18), ZIndex = 82 })
	local avatarFor = nil

	-- One offer panel: header, currencies, items, value.
	local function panel(x, w)
		local col = mk("Frame", { BackgroundColor3 = T.INK, Position = UDim2.fromOffset(x, 60),
			Size = UDim2.fromOffset(w, 372), ZIndex = 81 }, win)
		round(col)
		local st = stroke(col, T.LINE, 2)
		local head = text(col, { Text = "", Font = T.FONT, TextSize = 16, Position = UDim2.fromOffset(14, 8),
			Size = UDim2.new(1, -150, 0, 22), ZIndex = 82 })
		local chip = mk("TextLabel", { BackgroundColor3 = T.CARD, Text = "", Font = T.FONT, TextSize = 13,
			TextColor3 = T.MUTED, Position = UDim2.new(1, -132, 0, 8), Size = UDim2.fromOffset(120, 22),
			Visible = false, ZIndex = 82 }, col)
		round(chip, 11)
		local marks = text(col, { Text = "", TextColor3 = T.FAINT, TextSize = 12, Position = UDim2.fromOffset(14, 30),
			Size = UDim2.new(1, -28, 0, 16), ZIndex = 82 })
		local pills = {}
		local pw = math.floor((w - 28 - 12) / 3)
		for i, c in ipairs(CURRENCIES) do
			local pill = mk("Frame", { BackgroundColor3 = T.CARD, Position = UDim2.fromOffset(14 + (i - 1) * (pw + 6), 50),
				Size = UDim2.fromOffset(pw, 54), ZIndex = 82 }, col)
			round(pill, T.RADIUS_SM)
			local pst = stroke(pill, T.LINE, 1.5)
			text(pill, { Text = c.label, Font = T.FONT, TextSize = 11, TextColor3 = c.ink,
				Position = UDim2.fromOffset(8, 3), Size = UDim2.new(1, -16, 0, 14), ZIndex = 83 })
			pills[c.key] = { frame = pill, stroke = pst, spec = c }
		end
		local grid = mk("ScrollingFrame", {
			BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5,
			Position = UDim2.fromOffset(10, 112), Size = UDim2.new(1, -20, 0, 226),
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 82,
		}, col)
		mk("UIGridLayout", { CellSize = UDim2.fromOffset(76, 104), CellPadding = UDim2.fromOffset(6, 6),
			SortOrder = Enum.SortOrder.LayoutOrder }, grid)
		local value = text(col, { Text = "", TextColor3 = T.DUST, TextSize = 13,
			Position = UDim2.new(0, 14, 1, -28), Size = UDim2.new(1, -28, 0, 20), ZIndex = 82 })
		return { frame = col, stroke = st, head = head, chip = chip, marks = marks, pills = pills, grid = grid, value = value }
	end
	local theirCol = panel(268, 450)
	local mineCol = panel(726, 438)

	-- Your amounts: a box in each of your pills, plus what they asked for.
	local myBoxes, theirAskOnMine = {}, {}
	for _, c in ipairs(CURRENCIES) do
		local pill = mineCol.pills[c.key].frame
		local box = mk("TextBox", {
			BackgroundColor3 = T.INK, Text = "0", PlaceholderText = "0", ClearTextOnFocus = true,
			Font = T.FONT, TextSize = 16, TextColor3 = c.ink, TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(6, 18), Size = UDim2.new(1, -12, 0, 20), ZIndex = 84,
		}, pill)
		round(box, 6)
		mk("UIPadding", { PaddingLeft = UDim.new(0, 5) }, box)
		myBoxes[c.key] = box
		theirAskOnMine[c.key] = text(pill, { Text = "", Font = T.FONT_B, TextSize = 11, TextColor3 = T.GOLD,
			Position = UDim2.fromOffset(8, 38), Size = UDim2.new(1, -16, 0, 14), ZIndex = 84 })
	end
	-- Their amounts, plus a box where you say how much you want.
	local theirAmount, myAskBoxes = {}, {}
	for _, c in ipairs(CURRENCIES) do
		local pill = theirCol.pills[c.key].frame
		theirAmount[c.key] = text(pill, { Text = "0", Font = T.FONT, TextSize = 17, TextColor3 = c.ink,
			Position = UDim2.fromOffset(8, 17), Size = UDim2.new(1, -16, 0, 20), ZIndex = 84 })
		local ask = mk("TextBox", {
			BackgroundTransparency = 1, Text = "", PlaceholderText = "tap to ask...", ClearTextOnFocus = true,
			PlaceholderColor3 = T.FAINT, Font = T.FONT_B, TextSize = 11, TextColor3 = T.GOLD,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(8, 37), Size = UDim2.new(1, -16, 0, 15), ZIndex = 84,
		}, pill)
		myAskBoxes[c.key] = ask
	end

	-- The bag strip: your items to offer, or theirs to point at.
	local bag = mk("Frame", { BackgroundColor3 = T.CARD, Position = UDim2.fromOffset(16, 424),
		Size = UDim2.new(1, -32, 0, 190), ZIndex = 81 }, win)
	round(bag)
	-- YOURS on the left, THEIRS on the right — same kind tabs both sides.
	local bagSide = "mine" -- "mine" | "theirs"
	local bagKind = "cards"
	local tabBtns = { mine = {}, theirs = {} }
	local inspectFocus = nil -- stack key last opened in the inspector
	local inspectP = nil

	text(bag, {
		Text = "YOURS", Font = T.FONT, TextSize = 12, TextColor3 = T.FAINT,
		Position = UDim2.fromOffset(12, 2), Size = UDim2.fromOffset(60, 14), ZIndex = 83,
	})
	text(bag, {
		Text = "THEIRS", Font = T.FONT, TextSize = 12, TextColor3 = T.FAINT,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -220, 0, 2), Size = UDim2.fromOffset(208, 14), ZIndex = 83,
	})
	for i, id in ipairs(KINDS) do
		local b = button(bag, KIND_LABEL[id], T.INK, T.TEXT,
			UDim2.fromOffset(12 + (i - 1) * 66, 16), UDim2.fromOffset(62, 28))
		b.TextSize = 12
		b.ZIndex = 83
		tabBtns.mine[id] = b
	end
	for i, id in ipairs(KINDS) do
		local b = button(bag, KIND_LABEL[id], T.INK, T.TEXT,
			UDim2.new(1, -12 - (#KINDS - i) * 66, 0, 16), UDim2.fromOffset(62, 28))
		b.TextSize = 12
		b.ZIndex = 83
		tabBtns.theirs[id] = b
	end
	local bagHint = text(bag, { Text = "", TextColor3 = T.FAINT, TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(330, 18), Size = UDim2.fromOffset(300, 24), ZIndex = 83 })
	local bagGrid = mk("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5,
		ScrollingDirection = Enum.ScrollingDirection.X,
		Position = UDim2.fromOffset(10, 50), Size = UDim2.new(1, -20, 1, -56),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ZIndex = 82,
	}, bag)
	mk("UIGridLayout", { CellSize = UDim2.fromOffset(84, 118), CellPadding = UDim2.fromOffset(6, 6),
		FillDirection = Enum.FillDirection.Vertical, FillDirectionMaxCells = 1,
		SortOrder = Enum.SortOrder.LayoutOrder }, bagGrid)

	-- Footer: what is going on, then the three buttons.
	local status = text(win, { Text = "", Font = T.FONT, TextSize = 15, TextColor3 = T.MUTED,
		Position = UDim2.new(0, 22, 1, -58), Size = UDim2.new(1, -500, 0, 46), ZIndex = 81 })
	status.TextWrapped = true
	status.TextTruncate = Enum.TextTruncate.None
	local cancelBtn = button(win, "CANCEL", T.CARD, T.TEXT, UDim2.new(1, -470, 1, -60), UDim2.fromOffset(120, 46))
	local modeBtn = button(win, "COINFLIP", T.CARD, FLIP_INK, UDim2.new(1, -342, 1, -60), UDim2.fromOffset(160, 46))
	local mainBtn = button(win, "ACCEPT", T.GREEN, Color3.fromRGB(14, 40, 20), UDim2.new(1, -174, 1, -60), UDim2.fromOffset(158, 46))
	cancelBtn.ZIndex, modeBtn.ZIndex, mainBtn.ZIndex = 83, 83, 83

	----------------------------------------------------------------------------
	-- State
	----------------------------------------------------------------------------
	local session = nil -- the last sync, exactly as the server sent it
	local mine = { gems = 0, dust = 0, tokens = 0, cards = {}, packs = {}, runes = {}, gear = {}, potions = {} } -- ids
	local confirmUntil = 0
	local peek = nil -- the other bag, when asked for
	local noteUntil, noteText = 0, nil

	local function meA()
		return session and session.a == LP.UserId
	end
	local function S(field)
		-- session[field .. "A"] or ["B"] for me, and for them
		if not session then return nil, nil end
		if meA() then
			return session[field .. "A"], session[field .. "B"]
		end
		return session[field .. "B"], session[field .. "A"]
	end
	local function themId()
		return session and (meA() and session.b or session.a)
	end

	local function offered(kind, id)
		for _, x in ipairs(mine[kind]) do
			if x == id then return true end
		end
		return false
	end

	local function push()
		net:FireServer("tradeOffer", mine)
	end

	local function setMark(key, mark)
		if key then
			net:FireServer("tradeMark", { key = key, mark = mark or false })
		end
	end

	local function closeInspect()
		if inspectP then
			inspectP.Visible = false
		end
		inspectFocus = nil
	end

	local function showInspect(kind, row)
		if type(row) ~= "table" then
			return
		end
		local key = row._stackKey or stackKey(kind, row)
		inspectFocus = key
		if inspectP then
			inspectP:Destroy()
		end
		inspectP = mk("Frame", {
			Name = "TradeInspect", BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1), ZIndex = 120, Active = true,
		}, win)
		inspectP.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				closeInspect()
			end
		end)
		local panel = mk("Frame", {
			BackgroundColor3 = T.PANEL, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(420, 460), ZIndex = 121,
			Active = true,
		}, inspectP)
		round(panel, T.RADIUS_LG)
		stroke(panel, T.LINE, 2)
		-- Swallow clicks so backdrop-close does not fire when tapping the panel.
		panel.InputBegan:Connect(function() end)
		local title = tostring(row.name or row.packName or row.setName or row.stat or KIND_LABEL[kind] or "Item")
		if kind == "packs" then
			title = tostring(row.packName or row.packId or "Pack"):gsub("_", " ")
		end
		text(panel, {
			Text = title, Font = T.FONT, TextSize = 22,
			Position = UDim2.fromOffset(18, 14), Size = UDim2.new(1, -70, 0, 28), ZIndex = 122,
		})
		local sub = tostring(row.rarityId or row.rarity or ("T" .. tostring(row.tier or "")) or "")
		if (tonumber(row.count) or 1) > 1 then
			sub = sub .. ((sub ~= "" and "  ·  " or "") .. "×" .. tostring(row.count))
		end
		text(panel, {
			Text = sub, Font = T.FONT_M, TextSize = 14, TextColor3 = rarityInk(row, kind),
			Position = UDim2.fromOffset(18, 44), Size = UDim2.new(1, -36, 0, 20), ZIndex = 122,
		})
		local xbtn = button(panel, "X", T.INK, T.TEXT, UDim2.new(1, -44, 0, 12), UDim2.fromOffset(32, 32))
		xbtn.ZIndex = 123
		xbtn.MouseButton1Click:Connect(closeInspect)
		local art = mk("Frame", {
			BackgroundColor3 = T.INK, Position = UDim2.fromOffset(18, 74),
			Size = UDim2.fromOffset(160, 200), ZIndex = 122, ClipsDescendants = true,
		}, panel)
		round(art, T.RADIUS_SM)
		if kind == "cards" then
			pcall(function()
				if opts.paintCard then opts.paintCard(art, row, 150) end
			end)
		elseif kind == "packs" then
			local host = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 20),
				Size = UDim2.fromOffset(100, 140), ZIndex = 123 }, art)
			pcall(PackFX.drawSealed, host, row.packId or row.blockId, 90, 120)
		elseif kind == "gear" then
			local img = Gear.image and Gear.image(row)
			if img then
				mk("ImageLabel", { BackgroundTransparency = 1, Image = img, ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(1, 1), ZIndex = 123 }, art)
			end
		else
			text(art, {
				Text = "◆", Font = T.FONT, TextSize = 64, TextColor3 = rarityInk(row, kind),
				TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 123,
			})
		end
		local lines = {}
		if kind == "cards" then
			lines = cardStatLines(row)
		elseif kind == "runes" then
			lines = {
				string.format("Tier %s", tostring(row.tier or 1)),
				string.format("%s  +%.0f%%", tostring(row.stat or "?"), (tonumber(row.pct) or 0) * 100),
			}
		elseif kind == "gear" then
			lines = {
				tostring(row.rarity or ""),
				tostring(row.setName or row.name or "Gear"),
				tostring(row.slot or ""),
			}
		elseif kind == "packs" then
			lines = {
				tostring(row.packId or ""),
				(tonumber(row.count) or 1) > 1 and ("Stack ×" .. tostring(row.count)) or "1 pack",
				"Each pack keeps its own uid when offered",
			}
		end
		local y = 74
		for i, line in ipairs(lines) do
			if i > 10 then break end
			text(panel, {
				Text = tostring(line), Font = T.FONT_M, TextSize = 16, TextColor3 = T.TEXT,
				Position = UDim2.fromOffset(196, y), Size = UDim2.new(1, -214, 0, 24), ZIndex = 122,
			}).TextWrapped = true
			y += 28
		end
		text(panel, {
			Text = "Tap again to " .. (bagSide == "theirs" and "mark WANT / NO" or "add or take back"),
			Font = T.FONT_M, TextSize = 13, TextColor3 = T.FAINT,
			Position = UDim2.fromOffset(18, 420), Size = UDim2.new(1, -36, 0, 24), ZIndex = 122,
		})
	end

	-- First click inspects; second click on the same stack runs the trade action.
	local function withInspect(kind, row, action)
		return function()
			local key = row._stackKey or stackKey(kind, row)
			if inspectFocus ~= key then
				showInspect(kind, row)
				return
			end
			closeInspect()
			if action then
				action()
			end
		end
	end

	local function offeredCount(kind, ids)
		local n = 0
		for _, id in ipairs(ids or {}) do
			if offered(kind, id) then
				n += 1
			end
		end
		return n
	end

	local function toggleStackOffer(kind, ids)
		local free, taken = {}, {}
		for _, id in ipairs(ids or {}) do
			if offered(kind, id) then
				taken[#taken + 1] = id
			else
				free[#free + 1] = id
			end
		end
		if #free > 0 then
			local total = #mine.cards + #mine.packs + #mine.runes + #mine.gear + #(mine.potions or {})
			if total >= ((session and session.maxItems) or 16) then
				return
			end
			table.insert(mine[kind], free[1])
		elseif #taken > 0 then
			local id = taken[#taken]
			for i, x in ipairs(mine[kind]) do
				if x == id then
					table.remove(mine[kind], i)
					break
				end
			end
		end
		push()
	end

	local function markStack(kind, members, myMarks)
		local first = members and members[1]
		if not first then
			return
		end
		local next = nextMark(myMarks[markKey(kind, first)])
		for _, row in ipairs(members) do
			local key = markKey(kind, row)
			if key then
				setMark(key, next)
				myMarks[key] = next
			end
		end
	end

	local function stackMarkState(kind, members, marks)
		local want, nope = false, false
		for _, row in ipairs(members or {}) do
			local m = marks[markKey(kind, row)]
			if m == "want" then want = true end
			if m == "no" then nope = true end
		end
		if want then return "want" end
		if nope then return "no" end
		return nil
	end

	-- WANT / NO chip in a tile's corner.
	local function markChip(parent, mark, mineSide)
		if mark ~= "want" and mark ~= "no" then return end
		local chip = mk("TextLabel", {
			BackgroundColor3 = mark == "want" and WANT_INK or NO_INK, Text = mark == "want" and "WANT" or "NO",
			Font = T.FONT, TextSize = 11, TextColor3 = Color3.new(1, 1, 1),
			Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(mark == "want" and 40 or 26, 16), ZIndex = 90,
		}, parent)
		round(chip, 8)
		if mineSide then
			-- On your own items the chip is THEIR request: say so.
			chip.Text = mark == "want" and "THEY WANT" or "THEY: NO"
			chip.Size = UDim2.fromOffset(mark == "want" and 64 or 56, 16)
		end
	end

	-- One item, drawn the same wherever it appears.
		local function tile(parent, kind, row, order, onClick, dimReason, picked, mark, mineSide)
		local ink = rarityInk(row, kind)
		local b = mk("TextButton", { AutoButtonColor = onClick ~= nil, BackgroundColor3 = T.INK, Text = "",
			LayoutOrder = order, ZIndex = 84 }, parent)
		round(b, T.RADIUS_SM)
		local edge = (mark == "want" and WANT_INK) or (mark == "no" and NO_INK) or (picked and T.GREEN) or ink
		stroke(b, edge, (mark or picked) and 3 or 1.5)
		if kind == "cards" then
			local host = mk("Frame", { BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, -28), ZIndex = 85, ClipsDescendants = true }, b)
			local drawn = opts.paintCard and pcall(opts.paintCard, host, row, 80)
			if not drawn then
				text(host, { Text = tostring(row.name or "Card"), Font = T.FONT, TextSize = 13, TextColor3 = ink,
					TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(3, 24),
					Size = UDim2.new(1, -6, 0, 36), ZIndex = 86 }).TextWrapped = true
			end
			-- Bigger, clearer kit line under the art (paintCard's footer is too small here).
			local strip = mk("Frame", {
				BackgroundColor3 = Color3.fromRGB(12, 14, 20), BackgroundTransparency = 0.15,
				BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -28),
				Size = UDim2.new(1, 0, 0, 28), ZIndex = 90,
			}, b)
			local stat = cardStatLine(row) or tostring(row.rarityId or "")
			text(strip, {
				Text = stat, Font = T.FONT, TextSize = 12, TextColor3 = Color3.fromRGB(255, 236, 180),
				TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd,
				Size = UDim2.fromScale(1, 1), ZIndex = 91,
			}).TextWrapped = true
		elseif kind == "packs" then
			local art = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 6),
				Size = UDim2.fromOffset(60, 64), ZIndex = 85 }, b)
			pcall(PackFX.drawSealed, art, row.packId or row.blockId, 50, 62)
			text(b, { Text = tostring(row.packName or row.packId or "Pack"):gsub("_", " "), TextSize = 12,
				Font = T.FONT, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(3, 78),
				Size = UDim2.new(1, -6, 0, 32), ZIndex = 86 }).TextWrapped = true
		elseif kind == "gear" then
			local img = Gear.image and Gear.image(row)
			if img then
				mk("ImageLabel", { BackgroundTransparency = 1, Image = img, ScaleType = Enum.ScaleType.Fit,
					Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(60, 60), ZIndex = 85 }, b)
			end
			text(b, { Text = tostring(row.rarity or ""), Font = T.FONT, TextSize = 16, TextColor3 = ink,
				TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromOffset(4, 50),
				Size = UDim2.new(1, -8, 0, 18), ZIndex = 86 })
			text(b, { Text = tostring(row.setName or row.name or "Gear"), TextSize = 12, Font = T.FONT,
				TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(3, 78),
				Size = UDim2.new(1, -6, 0, 32), ZIndex = 86 }).TextWrapped = true
		else -- rune
			text(b, { Text = "◆", Font = T.FONT, TextSize = 34, TextColor3 = ink,
				TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 8),
				Size = UDim2.new(1, 0, 0, 40), ZIndex = 85 })
			text(b, { Text = "T" .. tostring(row.tier or 1), Font = T.FONT, TextSize = 16, TextColor3 = ink,
				TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 48),
				Size = UDim2.new(1, 0, 0, 20), ZIndex = 85 })
			text(b, { Text = string.format("%s +%.0f%%", tostring(row.stat or "?"), (tonumber(row.pct) or 0) * 100),
				TextSize = 13, Font = T.FONT, TextColor3 = Color3.fromRGB(255, 236, 180),
				TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(3, 78),
				Size = UDim2.new(1, -6, 0, 32), ZIndex = 86 }).TextWrapped = true
		end
		-- Stack count (and offered fraction when putting your pile up).
		local n = tonumber(row.count) or 1
		local offeredN = tonumber(row.offeredN) or 0
		if n > 1 or offeredN > 0 then
			local label = (offeredN > 0 and n > 1) and string.format("%d/%d", offeredN, n)
				or (n > 1 and ("×" .. tostring(n)))
				or tostring(offeredN)
			local badge = mk("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(226, 58, 58), BorderSizePixel = 0,
				Font = T.FONT, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), Text = label,
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -3, 0, 3),
				Size = UDim2.fromOffset(math.max(22, #label * 8), 18), ZIndex = 95,
			}, b)
			round(badge, 9)
		end
		markChip(b, mark, mineSide)
		if dimReason then
			local veil = mk("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35,
				Size = UDim2.fromScale(1, 1), ZIndex = 88 }, b)
			round(veil, T.RADIUS_SM)
			text(veil, { Text = dimReason, Font = T.FONT, TextSize = 12, TextColor3 = T.TEXT,
				TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 89 })
		end
		if onClick then
			b.MouseButton1Click:Connect(onClick)
		end
		return b
	end

	local function clearGrid(g)
		for _, c in ipairs(g:GetChildren()) do
			if c:IsA("GuiObject") then c:Destroy() end
		end
	end

	-- Runes fitted anywhere cannot be traded; the server refuses them too.
	local function socketedRunes(snap)
		local busy = {}
		for _, sock in pairs(snap.toolSockets or {}) do
			if type(sock) == "table" then
				if sock.main then busy[sock.main] = true end
				if sock.omni then busy[sock.omni] = true end
			end
		end
		for _, g in ipairs(snap.gear or {}) do
			for _, id in pairs(g.sockets or {}) do busy[id] = true end
		end
		for _, ct in ipairs(snap.chestTools or {}) do
			if type(ct) == "table" and ct.runeId then busy[ct.runeId] = true end
		end
		for _, id in pairs(snap.petSockets or {}) do busy[id] = true end
		return busy
	end

	local function countMarks(marks)
		local want, nope = 0, 0
		for _, m in pairs(marks or {}) do
			if m == "want" then want += 1 elseif m == "no" then nope += 1 end
		end
		return want, nope
	end

	local function paintOffers()
		local myView, theirView = S("offer")
		local myMarks, theirMarks = S("marks")
		myMarks, theirMarks = myMarks or {}, theirMarks or {}
		-- Theirs: tap to inspect / mark (stacked).
		clearGrid(theirCol.grid)
		local order = 0
		for _, kind in ipairs(KINDS) do
			for _, stack in ipairs(groupStacks(kind, (theirView or {})[kind] or {})) do
				order += 1
				local mark = stackMarkState(kind, stack.members, myMarks)
				tile(theirCol.grid, kind, stack, order, withInspect(kind, stack, function()
					markStack(kind, stack.members, myMarks)
					paintOffers()
				end), nil, false, mark, false)
			end
		end
		-- Yours: tap to inspect / take back one from the stack.
		clearGrid(mineCol.grid)
		order = 0
		for _, kind in ipairs(KINDS) do
			for _, stack in ipairs(groupStacks(kind, (myView or {})[kind] or {})) do
				order += 1
				local mark = stackMarkState(kind, stack.members, theirMarks)
				tile(mineCol.grid, kind, stack, order, withInspect(kind, stack, function()
					local ids = stack.ids
					local id = ids[#ids]
					if not id then return end
					for i, x in ipairs(mine[kind]) do
						if x == id then table.remove(mine[kind], i) break end
					end
					push()
				end), nil, false, mark, true)
			end
		end
		for _, c in ipairs(CURRENCIES) do
			theirAmount[c.key].Text = commas((theirView or {})[c.key] or 0)
		end
		local w1, n1 = countMarks(myMarks)
		local w2, n2 = countMarks(theirMarks)
		theirCol.marks.Text = (w1 + n1 > 0) and string.format("You marked %d WANT · %d NO", w1, n1) or "Tap their items to mark WANT / NO"
		mineCol.marks.Text = (w2 + n2 > 0) and string.format("They marked %d WANT · %d NO on your things", w2, n2) or "Tap your items here to take them back"
		local myVal, theirVal = S("value")
		local myTok = (myView or {}).tokens or 0
		local theirTok = (theirView or {}).tokens or 0
		theirCol.value.Text = "≈ " .. commas(theirVal) .. " stardust value" .. (theirTok > 0 and ("  +  " .. commas(theirTok) .. " tokens") or "")
		mineCol.value.Text = "≈ " .. commas(myVal) .. " stardust value" .. (myTok > 0 and ("  +  " .. commas(myTok) .. " tokens") or "")
	end

	local function paintAsks()
		local myAsks, theirAsks = S("asks")
		myAsks, theirAsks = myAsks or {}, theirAsks or {}
		local parts = {}
		for _, c in ipairs(CURRENCIES) do
			local theirs = tonumber(theirAsks[c.key]) or 0
			theirAskOnMine[c.key].Text = theirs > 0 and ("they ask " .. commas(theirs)) or ""
			mineCol.pills[c.key].stroke.Color = theirs > 0 and T.GOLD or T.LINE
			if theirs > 0 then
				table.insert(parts, commas(theirs) .. " " .. c.label:lower())
			end
			local mineAsk = tonumber(myAsks[c.key]) or 0
			local box = myAskBoxes[c.key]
			if not box:IsFocused() then
				box.Text = mineAsk > 0 and ("you ask " .. commas(mineAsk)) or ""
			end
			theirCol.pills[c.key].stroke.Color = mineAsk > 0 and T.GOLD or T.LINE
		end
		whoAsks.Text = #parts > 0 and ("Asking for " .. table.concat(parts, ", ")) or ""
	end

	local function paintBag()
		clearGrid(bagGrid)
		for side, btns in pairs(tabBtns) do
			for id, b in pairs(btns) do
				local on = bagSide == side and bagKind == id
				local accent = (side == "theirs") and WANT_INK or T.GOLD
				b.BackgroundColor3 = on and accent or T.INK
				b.TextColor3 = on and T.ON_GOLD or T.TEXT
			end
		end
		local order = 0
		if bagSide == "theirs" then
			bagHint.Text = "1st tap inspect · 2nd tap WANT / NO"
			local myMarks = S("marks") or {}
			if not peek then
				text(bagGrid, { Text = "Looking in their bag...", TextColor3 = T.FAINT, ZIndex = 84 }).Size = UDim2.fromOffset(220, 30)
				return
			end
			local stacks = groupStacks(bagKind, peek[bagKind] or {})
			for _, stack in ipairs(stacks) do
				order += 1
				local members = stack.members
				local mark = stackMarkState(bagKind, members, myMarks)
				tile(bagGrid, bagKind, stack, order, withInspect(bagKind, stack, function()
					markStack(bagKind, members, myMarks)
					paintBag()
				end), nil, false, mark, false)
			end
		else
			bagHint.Text = "1st tap inspect · 2nd tap offer / take back"
			local snap = getSnap()
			if not snap then return end
			local _, theirMarks = S("marks")
			theirMarks = theirMarks or {}
			local busy = (bagKind == "runes") and socketedRunes(snap) or {}
			local raw = {}
			if bagKind == "potions" then
				for _, row in ipairs((snap.potions and snap.potions.bag) or {}) do
					for _ = 1, math.max(1, math.floor(tonumber(row.qty) or 1)) do
						raw[#raw + 1] = { id = row.id, name = row.name, tier = row.tier, blurb = row.blurb }
					end
				end
			else
			for _, row in ipairs(bagSource(snap, bagKind)) do
				if type(row) == "table" then
					local id = idOf(bagKind, row)
					local blocked = false
					if bagKind == "runes" and busy[id] then blocked = true end
					if bagKind == "gear" and (snap.equippedGear or {})[row.slot] == id then blocked = true end
					if not blocked then
						raw[#raw + 1] = row
					end
				end
			end
			end
			-- Worn / socketed stay visible as single dimmed tiles (not mixed into stacks).
			local blockedRows = {}
			for _, row in ipairs(bagSource(snap, bagKind)) do
				if type(row) == "table" then
					local id = idOf(bagKind, row)
					if bagKind == "runes" and busy[id] then
						blockedRows[#blockedRows + 1] = { row = row, why = "SOCKETED" }
					elseif bagKind == "gear" and (snap.equippedGear or {})[row.slot] == id then
						blockedRows[#blockedRows + 1] = { row = row, why = "WORN" }
					end
				end
			end
			local stacks = groupStacks(bagKind, raw)
			for _, stack in ipairs(stacks) do
				order += 1
				local ids = stack.ids
				local why
				if bagKind == "cards" then
					local anyOk = false
					for _, id in ipairs(ids) do
						if type(id) == "string" and #id == 19 and id:match("^%x+$") then
							anyOk = true
							break
						end
					end
					if not anyOk then why = "CAN'T TRADE" end
				end
				stack.offeredN = offeredCount(bagKind, ids)
				local picked = stack.offeredN > 0
				local mark = stackMarkState(bagKind, stack.members, theirMarks)
				tile(bagGrid, bagKind, stack, order, (not why and #ids > 0) and withInspect(bagKind, stack, function()
					toggleStackOffer(bagKind, ids)
					paintBag()
				end) or withInspect(bagKind, stack, nil), why, picked, mark, true)
			end
			for _, item in ipairs(blockedRows) do
				order += 1
				item.row.count = 1
				tile(bagGrid, bagKind, item.row, order, withInspect(bagKind, item.row, nil), item.why, false, nil, true)
			end
		end
		if order == 0 then
			text(bagGrid, { Text = "Nothing here", TextColor3 = T.FAINT, ZIndex = 84 }).Size = UDim2.fromOffset(160, 30)
		end
	end
	for side, btns in pairs(tabBtns) do
		for id, b in pairs(btns) do
			b.MouseButton1Click:Connect(function()
				bagSide = side
				bagKind = id
				closeInspect()
				if side == "theirs" then
					net:FireServer("tradePeek")
				end
				paintBag()
			end)
		end
	end

	for _, c in ipairs(CURRENCIES) do
		local box = myBoxes[c.key]
		box.FocusLost:Connect(function()
			local snap = getSnap()
			local have = math.floor(tonumber(snap and snap[c.field]) or 0)
			local n = math.clamp(digits(box.Text), 0, math.max(0, have))
			box.Text = commas(n)
			mine[c.key] = n
			push()
		end)
		local ask = myAskBoxes[c.key]
		ask.Focused:Connect(function()
			ask.Text = ""
		end)
		ask.FocusLost:Connect(function()
			net:FireServer("tradeWant", { [c.key] = digits(ask.Text) })
		end)
	end

	local function stage()
		return session and session.stage or "draft"
	end

	local function paintStatus()
		if not session then return end
		local st = stage()
		local flip = session.mode == "coinflip"
		local myAccept, theirAccept = S("accept")
		local myConfirm, theirConfirm = S("confirm")
		local them = meA() and session.nameB or session.nameA
		local left = math.max(0, confirmUntil - os.clock())

		-- The other player's chip, under their avatar and on their panel.
		local theirState = (st == "confirm" and theirConfirm and "CONFIRMED") or (theirAccept and "ACCEPTED") or "DECIDING..."
		whoState.Text = theirState
		whoState.BackgroundColor3 = (theirAccept or theirConfirm) and T.GREEN or T.CARD
		whoState.TextColor3 = (theirAccept or theirConfirm) and Color3.fromRGB(14, 40, 20) or T.MUTED
		whoStroke.Color = (theirAccept or theirConfirm) and T.GREEN or T.LINE
		theirCol.chip.Visible = theirAccept or theirConfirm
		theirCol.chip.Text = theirState
		theirCol.chip.BackgroundColor3 = T.GREEN
		theirCol.chip.TextColor3 = Color3.fromRGB(14, 40, 20)
		mineCol.chip.Visible = myAccept or myConfirm
		mineCol.chip.Text = (st == "confirm" and myConfirm and "CONFIRMED") or "ACCEPTED"
		mineCol.chip.BackgroundColor3 = T.GREEN
		mineCol.chip.TextColor3 = Color3.fromRGB(14, 40, 20)
		theirCol.stroke.Color = (theirAccept or theirConfirm) and T.GREEN or T.LINE
		mineCol.stroke.Color = (myAccept or myConfirm) and T.GREEN or T.LINE

		-- Mode.
		modeChip.Text = flip and "COINFLIP · WINNER TAKES ALL" or "TRADE"
		modeChip.BackgroundColor3 = flip and FLIP_INK or T.GOLD
		modeChip.TextColor3 = flip and Color3.new(1, 1, 1) or T.ON_GOLD
		modeChip.TextSize = flip and 12 or 15
		winStroke.Color = flip and FLIP_INK or T.GOLD
		title.Text = (flip and "COINFLIP WITH " or "TRADING WITH ") .. string.upper(tostring(them))

		-- Buttons.
		if st == "confirm" then
			modeBtn.Visible = true
			modeBtn.Text = "BACK"
			modeBtn.TextColor3 = T.TEXT
		else
			modeBtn.Visible = session.coinflipEnabled ~= false
			modeBtn.Text = flip and "MAKE IT A TRADE" or "COINFLIP"
			modeBtn.TextColor3 = flip and T.GOLD or FLIP_INK
			modeBtn.TextSize = flip and 13 or 16
		end
		local canMain
		if st == "committing" then
			mainBtn.Text = flip and "FLIPPING..." or "TRADING..."
			canMain = false
		elseif st == "confirm" then
			if myConfirm then
				mainBtn.Text = "CONFIRMED"
				canMain = false
			elseif left > 0 then
				mainBtn.Text = "CONFIRM  " .. math.ceil(left)
				canMain = false
			else
				mainBtn.Text = "CONFIRM"
				canMain = true
			end
		else
			mainBtn.Text = myAccept and "ACCEPTED" or "ACCEPT"
			canMain = true
		end
		local lit = canMain and not (st == "draft" and myAccept)
		mainBtn.AutoButtonColor = canMain
		mainBtn.BackgroundColor3 = lit and (flip and FLIP_INK or T.GREEN) or ((st == "draft" and myAccept) and T.CARD_HI or T.DEAD)
		mainBtn.TextColor3 = lit and (flip and Color3.new(1, 1, 1) or Color3.fromRGB(14, 40, 20)) or ((st == "draft" and myAccept) and T.GREEN or T.FAINT)

		-- Status line.
		local prefix = flip and "COINFLIP: " or ""
		local msg, ink
		if noteText and os.clock() < noteUntil then
			msg, ink = noteText, T.GOLD
		elseif st == "committing" then
			msg, ink = flip and "Flipping the coin..." or "Completing the trade...", T.GOLD
		elseif st == "confirm" then
			if left > 0 then
				msg, ink = "Both accepted. Last look -- CONFIRM unlocks in " .. math.ceil(left) .. "...", T.GOLD
			elseif myConfirm then
				msg, ink = "Waiting for " .. them .. " to confirm.", T.MUTED
			else
				msg, ink = prefix .. "Press CONFIRM to " .. (flip and "flip." or "trade."), flip and FLIP_INK or T.GREEN
			end
		elseif myAccept and not theirAccept then
			msg, ink = "Waiting for " .. them .. " to accept.", T.MUTED
		elseif theirAccept and not myAccept then
			msg, ink = them .. " accepted. Check the deal, then ACCEPT.", T.GREEN
		elseif flip then
			msg, ink = "COINFLIP: 50/50 -- the winner takes BOTH offers. Both must put something up.", FLIP_INK
		else
			msg, ink = "Put up what you'll give. Tap their items to say WANT or NO; type in an ask box to ask for currency.", T.MUTED
		end
		status.Text = msg
		status.TextColor3 = ink
	end

	local function paintWho()
		local them = themId()
		if not them then return end
		whoName.Text = tostring(meA() and session.nameB or session.nameA)
		local user = meA() and session.userB or session.userA
		whoUser.Text = (user and user ~= "") and ("@" .. user) or ""
		if avatarFor ~= them then
			avatarFor = them
			avatar.Image = ""
			task.spawn(function()
				local ok, img = pcall(function()
					return Players:GetUserThumbnailAsync(them, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size420x420)
				end)
				if ok and avatarFor == them then
					avatar.Image = img
				end
			end)
		end
	end

	local function paintAll()
		if not session then return end
		theirCol.head.Text = string.upper(tostring(meA() and session.nameB or session.nameA)) .. "'S OFFER"
		mineCol.head.Text = "YOUR OFFER"
		paintWho()
		paintOffers()
		paintAsks()
		paintBag()
		paintStatus()
	end

	-- Ticks the countdown on the button while it runs.
	RunService.Heartbeat:Connect(function()
		if win.Visible and session and (stage() == "confirm" or os.clock() < noteUntil + 0.2) then
			paintStatus()
		end
	end)

	mainBtn.MouseButton1Click:Connect(function()
		if not session then return end
		local st = stage()
		if st == "confirm" then
			if os.clock() >= confirmUntil then
				net:FireServer("tradeConfirm")
			end
		elseif st == "draft" then
			net:FireServer("tradeAccept")
		end
	end)
	modeBtn.MouseButton1Click:Connect(function()
		if not session then return end
		if stage() == "confirm" then
			net:FireServer("tradeBack")
		elseif stage() == "draft" then
			net:FireServer("tradeMode", { mode = session.mode == "coinflip" and "trade" or "coinflip" })
		end
	end)
	local function cancel()
		net:FireServer("tradeCancel")
		win.Visible = false
		session = nil
	end
	cancelBtn.MouseButton1Click:Connect(cancel)
	winClose.MouseButton1Click:Connect(cancel)

	----------------------------------------------------------------------------
	-- THE COIN
	----------------------------------------------------------------------------
	local flipLayer = mk("Frame", { Name = "CoinflipResult", Visible = false, Active = true,
		BackgroundColor3 = Color3.fromRGB(8, 6, 10), BackgroundTransparency = 0.25,
		Size = UDim2.fromScale(1, 1), ZIndex = 120 }, gui)
	local coin = mk("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(220, 220), BackgroundColor3 = T.GOLD, ScaleType = Enum.ScaleType.Crop, ZIndex = 121 }, flipLayer)
	round(coin, 110)
	local coinRim = stroke(coin, Color3.fromRGB(255, 236, 170), 8)
	local flipHead = text(flipLayer, { Text = "", Font = T.FONT, TextSize = 44, TextColor3 = T.GOLD,
		TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 0, 0.42, 130), Size = UDim2.new(1, 0, 0, 52), ZIndex = 121 })
	local flipSub = text(flipLayer, { Text = "", TextSize = 18, TextColor3 = T.MUTED,
		TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 0, 0.42, 184), Size = UDim2.new(1, 0, 0, 24), ZIndex = 121 })
	local flipToken = nil
	flipLayer.InputBegan:Connect(function(input)
		if flipHead.Text ~= "" and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			flipToken = nil
			flipLayer.Visible = false
		end
	end)

	local function headshot(userId, cb)
		task.spawn(function()
			local ok, img = pcall(function()
				return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
			end)
			cb(ok and img or "")
		end)
	end

	local function playFlip(result)
		local token = {}
		flipToken = token
		flipHead.Text = ""
		flipSub.Text = ""
		coin.Image = ""
		flipLayer.Visible = true
		local faces = { [result.winner] = "", [result.loser] = "" }
		headshot(result.winner, function(img) faces[result.winner] = img end)
		headshot(result.loser, function(img) faces[result.loser] = img end)
		task.spawn(function()
			-- Spin: squash the coin to nothing and swap faces, slower each turn,
			-- and land on the winner.
			local flips = 14
			for i = 1, flips do
				if flipToken ~= token then return end
				local dur = 0.035 + (i / flips) ^ 2 * 0.16
				local showWinner = (flips - i) % 2 == 0
				TweenService:Create(coin, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
					{ Size = UDim2.fromOffset(6, 220) }):Play()
				task.wait(dur)
				coin.Image = faces[showWinner and result.winner or result.loser] or ""
				coin.BackgroundColor3 = showWinner and T.GOLD or Color3.fromRGB(190, 190, 200)
				TweenService:Create(coin, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{ Size = UDim2.fromOffset(220, 220) }):Play()
				task.wait(dur)
			end
			if flipToken ~= token then return end
			local won = result.winner == LP.UserId
			coin.Image = faces[result.winner] or ""
			coinRim.Color = won and T.GOLD or FLIP_INK
			flipHead.Text = won and "YOU WON THE FLIP!" or (result.winner == nil and "" or (string.upper(tostring(result.winnerName)) .. " WINS"))
			flipHead.TextColor3 = won and T.GOLD or FLIP_INK
			flipSub.Text = won and ("Everything on the table is yours. Tough luck, " .. tostring(result.loserName) .. ".")
				or ("Better luck next time. Tap to close.")
			if Audio and Audio.play then
				pcall(Audio.play, won and "lucky" or "equip")
			end
			task.wait(6)
			if flipToken == token then
				flipLayer.Visible = false
			end
		end)
	end

	----------------------------------------------------------------------------
	-- Server events
	----------------------------------------------------------------------------
	function ctl.sync(payload)
		if type(payload) ~= "table" then return end
		local fresh = (not session) or session.id ~= payload.id
		session = payload
		if fresh then
			bagSide = "mine"
			bagKind = "cards"
			peek = nil
			avatarFor = nil
		end
		-- Your offer is whatever the server kept: rebuild the ids from it.
		local view = S("offer") or {}
		mine = { gems = 0, dust = 0, tokens = 0, cards = {}, packs = {}, runes = {}, gear = {}, potions = {} }
		for _, c in ipairs(CURRENCIES) do
			mine[c.key] = tonumber(view[c.key]) or 0
			local box = myBoxes[c.key]
			if not box:IsFocused() then
				box.Text = commas(mine[c.key])
			end
		end
		for _, kind in ipairs(KINDS) do
			for _, row in ipairs(view[kind] or {}) do
				table.insert(mine[kind], idOf(kind, row))
			end
		end
		confirmUntil = os.clock() + (tonumber(payload.confirmIn) or 0)
		if type(payload.note) == "string" and payload.note ~= "" then
			noteText, noteUntil = payload.note, os.clock() + 4
		end
		invite.Visible = false
		picker.Visible = false
		win.Visible = true
		paintAll()
	end

	function ctl.peek(payload)
		if type(payload) ~= "table" or not session then return end
		if payload.owner ~= themId() then return end
		peek = payload
		if win.Visible and bagSide == "theirs" then
			paintBag()
		end
	end

	function ctl.closed(msg)
		session = nil
		peek = nil
		win.Visible = false
	end

	function ctl.result(payload)
		session = nil
		peek = nil
		win.Visible = false
		if type(payload) == "table" and payload.coinflip then
			playFlip(payload)
		end
	end

	-- Your own inventory changed (a snapshot) while trading: repaint the bag.
	function ctl.refreshBag()
		if win.Visible and bagSide ~= "theirs" then
			paintBag()
		end
	end

	-- The dock button.
	function ctl.openPicker()
		if session and win.Visible then
			return
		end
		if picker.Visible then
			picker.Visible = false
			return
		end
		paintPicker()
		picker.Visible = true
	end

	function ctl.isOpen()
		return win.Visible or picker.Visible
	end

	return ctl
end

return MineTradeView
