--[[
	MineFishingView -- the fishing screen and the cast / reel minigame (TODO A3).

	The rules are MineFishing, the fight is MineFishingFight (the SAME code the
	server replays), the verbs are MineFishingService. This draws, takes input
	and reports.

	FOR KIDS, NOT READERS. Owner, 2026-10-11: "we got to work to get this to
	keep KIDS attention.. not a grown man who knows how to read fluent
	english" -- ages 10-14+, and "icons + big numbers, 1-3 words", "a pointing
	hand", "more reward juice", "info hidden behind a (?) button". So:
	  * every number wears an icon (🐛 bait, 🎟 tokens, 💰 coins, ⚡ reel,
	    💪 line, 🍀 luck) and no main screen carries a sentence;
	  * the sentences live behind (?), one short line each;
	  * a 👆 bounces on CAST until your first cast;
	  * in the fight the REEL button IS the instruction: it turns green
	    ("REEL!"), yellow ("EASY") or red ("LET GO!") with the fish;
	  * a perfect cast sparkles, and a catch celebrates by its real rarity
	    (MineCelebrate; a ★ minnow gets a pop, a ★★★★★ gets the works).

	THE SCREEN (from a spot's Fish prompt): FISH (cast, rod, bait for tokens),
	TACKLE (rods: buy, equip, level, prestige), ODDS (this spot's catch table),
	COOLER (your fish cards).

	THE MINIGAME: cast (stop the bar in the gold) -> wait -> reel (hold REEL or
	F; the client runs MineFishingFight at 30 ticks a second and records only
	when REEL went down and up, which the server replays) -> catch (cards, worst
	to best, one tap each).

	mount(gui, opts) -> controller { onMessage(data), close(), isOpen(), root }
	  opts.send(action, payload)   fire a "fish..." verb to the server
]]
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local shared = game:GetService("ReplicatedStorage"):WaitForChild("Mine"):WaitForChild("Shared")
local T = require(shared:WaitForChild("MineTheme"))
local M = require(shared:WaitForChild("MineFishing"))
local Fight = require(shared:WaitForChild("MineFishingFight"))

local function optional(name)
	local ok, mod = pcall(function()
		return require(shared:WaitForChild(name, 5))
	end)
	return ok and mod or nil
end
local UI = optional("MineUI")
local Celebrate = optional("MineCelebrate")
local Audio = optional("MineAudio")

local View = {}

-- The fish's colour, what the REEL button says, and its colour then.
local COLOUR = {
	green = { col = Color3.fromRGB(96, 226, 120), word = "REEL!", btn = Color3.fromRGB(40, 190, 90) },
	yellow = { col = Color3.fromRGB(255, 206, 70), word = "EASY...", btn = Color3.fromRGB(230, 160, 20) },
	red = { col = Color3.fromRGB(255, 76, 76), word = "LET GO!", btn = Color3.fromRGB(220, 50, 70) },
}

-- What (?) says. One short line each (owner: short sentences are fine in popups).
local HELP = {
	"🐛  Bait: 15 a day. You get it by staying in the game, from daily quests, or with 🎟 tokens.",
	"✨  Stop the bar in the GOLD for a perfect cast. Perfect = more 🍀 luck.",
	"🐟  GREEN: hold REEL.   YELLOW: easy.   RED: LET GO (or tap).",
	"💥  Too much tension snaps the line. Past 100 m the fish can escape.",
	"🎣  Better rods: ⚡ reel faster, 💪 hold more, 🍀 find rarer fish. Every 10 levels needs 🎟.",
	"📦  Every fish you land goes in your COOLER.",
}

-- Every list here shows things in the order they were made (LayoutOrder),
-- never alphabetically by instance name.
local made = 0
local function mk(class, props, parent)
	local i = Instance.new(class)
	if i:IsA("GuiObject") then
		made += 1
		i.LayoutOrder = made
	end
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

local function stroke(o, col, th)
	return mk("UIStroke", { Color = col or T.LINE, Thickness = th or T.STROKE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end

local function label(parent, text, size, color, props)
	local l = mk("TextLabel", {
		BackgroundTransparency = 1,
		Text = text or "",
		TextSize = size or 16,
		TextColor3 = color or T.TEXT,
		Font = T.FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, (size or 16) + 6),
	}, parent)
	for k, v in pairs(props or {}) do
		l[k] = v
	end
	return l
end

-- A chunky button: candy outline, juice on hover and press (candy-style rules).
local function button(parent, text, size, pos, color)
	local b = mk("TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = color or T.ACCENT,
		Text = text,
		TextColor3 = T.ON_CANDY,
		TextSize = 20,
		Font = T.FONT,
		TextStrokeColor3 = T.OUTLINE,
		TextStrokeTransparency = 0.35,
		Size = size,
		Position = pos or UDim2.new(),
	}, parent)
	round(b, 14)
	stroke(b, T.OUTLINE, T.STROKE_CHUNKY or 3)
	if UI and UI.juice then
		pcall(UI.juice, b)
	end
	return b
end

-- A stat chip: an icon and a number, nothing else.
local chipN = 0
local function chip(parent, text, color, width)
	chipN += 1
	local c = mk("Frame", { BackgroundColor3 = T.INK, Size = UDim2.fromOffset(width or 96, 34), ZIndex = 43, LayoutOrder = chipN }, parent)
	round(c, 17)
	stroke(c, color or T.LINE, 2)
	label(c, text, 18, color or T.TEXT, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 44 })
	return c
end

local function short(n)
	n = tonumber(n) or 0
	local units = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, u in ipairs(units) do
		if n >= u[1] then
			local v = n / u[1]
			return (v >= 100 and string.format("%d", math.floor(v)) or (string.format("%.1f", v):gsub("%.0$", ""))) .. u[2]
		end
	end
	return tostring(math.floor(n))
end

local function clockText(secs)
	secs = math.max(0, math.floor(tonumber(secs) or 0))
	return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

-- A catch's celebration tier from its grade (1..9): ★ to ★★½ just pop.
local function tierOf(grade)
	grade = tonumber(grade) or 1
	if grade >= 9 then
		return 4
	elseif grade >= 8 then
		return 3
	elseif grade >= 7 then
		return 2
	elseif grade >= 5 then
		return 1
	end
	return 0
end

function View.mount(gui, opts)
	opts = opts or {}
	local send = opts.send or function() end
	local ctl = {}
	local data -- the last "state" from the server
	local tab = "fish"
	local stage = nil -- nil | "cast" | "wait" | "fight" | "catch"

	-- ------------------------------------------------------------ screen --
	local root = mk("Frame", {
		Name = "Fishing", Visible = false, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(660, 470),
		BackgroundColor3 = T.PANEL, ZIndex = 40,
	}, gui)
	round(root, 18)
	stroke(root, T.EDGE, T.STROKE_THICK or 4)
	root:SetAttribute("MineUIAdopted", true)
	local scale = mk("UIScale", {}, root)
	local function fit()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		scale.Scale = math.clamp(math.min(vp.X / 700, vp.Y / 520), 0.55, 1.15)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end

	local title = label(root, "🎣 FISHING", 30, T.GOLD, { Position = UDim2.fromOffset(22, 12), Size = UDim2.new(1, -150, 0, 34), ZIndex = 41 })
	-- The bait line: three chips, no words.
	local chips = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(22, 48), Size = UDim2.new(1, -44, 0, 34), ZIndex = 41 }, root)
	mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, chips)
	local baitChip = chip(chips, "🐛 0", T.GREEN, 92)
	local dayChip = chip(chips, "📅 0/15", T.MUTED, 110)
	local afkChip = chip(chips, "💤 8:00", T.MUTED, 104)
	local tokenChip = chip(chips, "🎟 0", T.GOLD, 104)
	local close = button(root, "X", UDim2.fromOffset(42, 42), UDim2.new(1, -56, 0, 12), T.CANDY.red[2])
	close.Name = "Close"
	close.ZIndex = 42
	local helpBtn = button(root, "?", UDim2.fromOffset(42, 42), UDim2.new(1, -106, 0, 12), T.CANDY.blue[2])
	helpBtn.Name = "Help"
	helpBtn.ZIndex = 42

	-- Tabs.
	local tabs = {}
	local tabBar = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 92), Size = UDim2.new(1, -40, 0, 40), ZIndex = 41 }, root)
	mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, tabBar)
	local pages = {}
	for i, t in ipairs({ { "fish", "🎣 FISH" }, { "tackle", "🛠 RODS" }, { "odds", "🍀 ODDS" }, { "cooler", "📦 COOLER" } }) do
		local b = button(tabBar, t[2], UDim2.fromOffset(148, 38), nil, T.CARD)
		b.LayoutOrder = i
		b.Name = "Tab_" .. t[1]
		b.TextSize = 18
		b.ZIndex = 42
		tabs[t[1]] = b
		pages[t[1]] = mk("ScrollingFrame", {
			Name = "Page_" .. t[1], BackgroundTransparency = 1, Visible = false, Position = UDim2.fromOffset(20, 142),
			Size = UDim2.new(1, -40, 1, -156), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 6, BorderSizePixel = 0, ZIndex = 41,
		}, root)
	end

	-- (?) -- the explanations, one tap away and never on the main screen.
	local help = mk("Frame", { Name = "HelpCard", Visible = false, BackgroundColor3 = T.INK, Position = UDim2.fromOffset(20, 92),
		Size = UDim2.new(1, -40, 1, -106), ZIndex = 60 }, root)
	round(help, 14)
	stroke(help, T.CANDY.blue[2], 3)
	mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }, help)
	mk("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18), PaddingTop = UDim.new(0, 16) }, help)
	for _, line in ipairs(HELP) do
		label(help, line, 18, T.TEXT, { TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 22), ZIndex = 61 })
	end
	helpBtn.MouseButton1Click:Connect(function()
		help.Visible = not help.Visible
	end)

	local function clear(page)
		for _, c in ipairs(page:GetChildren()) do
			if not c:IsA("UIListLayout") and not c:IsA("UIGridLayout") then
				c:Destroy()
			end
		end
	end

	local function rodDef(id)
		return M.rod(id) or M.rod(M.STARTER_ROD)
	end

	local function statChips(parent, stats, x, y)
		local row = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(x, y), Size = UDim2.new(1, -x, 0, 34), ZIndex = 43 }, parent)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, row)
		chip(row, string.format("⚡ %.1f", stats.reel), T.CANDY.cyan[1], 86)
		chip(row, string.format("💪 x%.2f", stats.line), T.CANDY.orange[1], 100)
		chip(row, string.format("🍀 x%.2f", stats.luck), T.GREEN, 100)
		if (stats.bait or 1) > 1 then
			chip(row, "🐛 x" .. stats.bait, T.CANDY.magenta[1], 76)
		end
		return row
	end

	-- A 👆 that bounces under something until it is no longer needed.
	local function pointAt(target)
		local hand = label(target.Parent, "👆", 40, T.TEXT, {
			Name = "PointHand", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(50, 50),
			TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 50,
			Position = UDim2.new(target.Position.X.Scale, target.Position.X.Offset + target.Size.X.Offset * 0.5,
				target.Position.Y.Scale, target.Position.Y.Offset + target.Size.Y.Offset + 2),
		})
		local up = hand.Position
		local down = up + UDim2.fromOffset(0, 10)
		task.spawn(function()
			while hand.Parent do
				TweenService:Create(hand, TweenInfo.new(0.35, Enum.EasingStyle.Sine), { Position = down }):Play()
				task.wait(0.35)
				if not hand.Parent then
					break
				end
				TweenService:Create(hand, TweenInfo.new(0.35, Enum.EasingStyle.Sine), { Position = up }):Play()
				task.wait(0.35)
			end
		end)
		return hand
	end

	-- FISH
	local function paintFish()
		local page = pages.fish
		clear(page)
		local st = data.state or {}
		local rodId = st.rod or M.STARTER_ROD
		local r = rodDef(rodId)
		local stats = data.rodStats or M.rodStats(rodId, st.rodLevel)
		local card = mk("Frame", { BackgroundColor3 = T.CARD, Size = UDim2.new(1, -8, 0, 96), ZIndex = 42 }, page)
		round(card, 14)
		stroke(card, T.LINE, 2)
		label(card, "🎣 " .. r.name, 24, T.TEXT, { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(0.7, 0, 0, 28), ZIndex = 43 })
		chip(card, "Lv " .. (st.rodLevel or 0), T.GOLD, 80).Position = UDim2.new(1, -96, 0, 10)
		statChips(card, stats, 16, 50)
		local need = stats.bait or 1
		local can = (st.bait or 0) >= need
		local cast = button(page, can and "CAST" or ("🐛 " .. (st.bait or 0)), UDim2.fromOffset(280, 70),
			UDim2.new(0.5, -140, 0, 108), can and T.CANDY.gold[2] or T.DEAD)
		cast.Name = "Cast"
		cast.TextSize = 34
		cast.ZIndex = 43
		if can and UI and UI.pulse then
			pcall(UI.pulse, cast, 1.05, 1.1)
		end
		if can and (tonumber(st.casts) or 0) == 0 then
			pointAt(cast)
		end
		cast.MouseButton1Click:Connect(function()
			if can and not stage then
				send("fishStart", { spotId = data.spotId })
			end
		end)
		-- Bait for tokens: two buttons that say only what you get and what it costs.
		local row = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 236), Size = UDim2.new(1, 0, 0, 48), ZIndex = 42 }, page)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 12) }, row)
		for _, n in ipairs({ 1, 5 }) do
			local cost = n * M.TOKEN_PRICE
			local afford = (data.tokens or 0) >= cost
			local b = button(row, "🐛 +" .. n .. "   🎟 " .. cost, UDim2.fromOffset(190, 46), nil, afford and T.CANDY.cyan[2] or T.DEAD)
			b.TextSize = 18
			b.ZIndex = 43
			b.MouseButton1Click:Connect(function()
				send("fishBuyBait", { n = n, spotId = data.spotId })
			end)
		end
	end

	-- TACKLE
	local function paintTackle()
		local page = pages.tackle
		clear(page)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, page)
		local st = data.state or {}
		for _, row in ipairs(data.rods or {}) do
			local r = rodDef(row.id)
			local equipped = st.rod == row.id
			local card = mk("Frame", { BackgroundColor3 = equipped and T.CARD_HI or T.CARD, Size = UDim2.new(1, -10, 0, 92), ZIndex = 42 }, page)
			round(card, 12)
			stroke(card, equipped and T.GOLD or T.LINE, equipped and 3 or 1)
			label(card, (equipped and "✅ " or "") .. r.name .. (row.owned and ("   Lv " .. row.level .. "/" .. row.cap) or ""), 20, T.TEXT,
				{ Position = UDim2.fromOffset(14, 8), Size = UDim2.new(0.62, 0, 0, 26), ZIndex = 43 })
			statChips(card, row.stats, 14, 46).Size = UDim2.new(0.62, -14, 0, 34)
			local function act(text, color, verb, enabled)
				local b = button(card, text, UDim2.fromOffset(190, 44), UDim2.new(1, -202, 0.5, -22), enabled and color or T.DEAD)
				b.TextSize = 18
				b.ZIndex = 43
				b.MouseButton1Click:Connect(function()
					send(verb, { rodId = row.id, spotId = data.spotId })
				end)
				return b
			end
			if not row.owned then
				act("BUY  💰 " .. short(row.price), T.CANDY.gold[2], "fishBuyRod", (data.coins or 0) >= row.price)
			elseif row.prestigeCost then
				act("⭐ 🎟 " .. short(row.prestigeCost), T.CANDY.magenta[2], "fishPrestigeRod", (data.tokens or 0) >= row.prestigeCost)
			elseif row.nextCost then
				act("⬆ 💰 " .. short(row.nextCost), T.CANDY.green[2], "fishUpgradeRod", (data.coins or 0) >= row.nextCost)
			else
				act("MAX", T.DEAD, "fishUpgradeRod", false).Active = false
			end
			if row.owned and not equipped then
				local e = button(card, "USE", UDim2.fromOffset(74, 36), UDim2.new(1, -286, 0.5, -18), T.CANDY.purple[2])
				e.TextSize = 16
				e.ZIndex = 43
				e.MouseButton1Click:Connect(function()
					send("fishEquipRod", { rodId = row.id, spotId = data.spotId })
				end)
			end
		end
	end

	-- ODDS
	local function paintOdds()
		local page = pages.odds
		clear(page)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, page)
		local top = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -10, 0, 36), ZIndex = 42 }, page)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, top)
		chip(top, string.format("🍀 x%.2f", data.luck or 1), T.GREEN, 110)
		chip(top, string.format("✨ x%.1f", M.CAST.luck.perfect), T.GOLD, 96)
		for _, row in ipairs(data.odds or {}) do
			local f = M.fish(row.id)
			if f then
				local known = data.cooler and data.cooler[f.id] ~= nil
				local line = mk("Frame", { BackgroundColor3 = T.CARD, Size = UDim2.new(1, -10, 0, 32), ZIndex = 42 }, page)
				round(line, 8)
				local col = M.GRADE_COLOR[f.grade]
				label(line, M.GRADE_TEXT[f.grade], 18, col, { Position = UDim2.fromOffset(10, 4), Size = UDim2.fromOffset(120, 24), ZIndex = 43 })
				label(line, (known and "✅ " or "") .. f.name, 18, T.TEXT, { Position = UDim2.fromOffset(134, 4), Size = UDim2.new(0.5, 0, 0, 24), ZIndex = 43 })
				local pct = row.p * 100
				local txt = (pct >= 1) and string.format("%.1f%%", pct) or string.format("1 in %s", short(math.floor(1 / math.max(row.p, 1e-9) + 0.5)))
				label(line, txt, 18, T.GOLD, { Position = UDim2.new(1, -150, 0, 4), Size = UDim2.fromOffset(140, 24),
					TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 43 })
			end
		end
	end

	-- COOLER
	local function fishCard(parent, f, row, extra)
		local col = M.GRADE_COLOR[f.grade]
		local known = row ~= nil
		local c = mk("Frame", { BackgroundColor3 = known and T.CARD or T.DEAD, ZIndex = 42 }, parent)
		round(c, 12)
		stroke(c, known and col or T.LINE, known and 3 or 1)
		local band = mk("Frame", { BackgroundColor3 = known and col or T.LINE, Size = UDim2.new(1, 0, 0, 8), ZIndex = 43 }, c)
		round(band, 6)
		label(c, known and "🐟" or "❓", 36, T.TEXT, { Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, 0, 0, 42),
			TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 43 })
		label(c, known and f.name or "???", 16, T.TEXT, { Position = UDim2.fromOffset(6, 56), Size = UDim2.new(1, -12, 0, 20),
			TextXAlignment = Enum.TextXAlignment.Center, TextScaled = true, ZIndex = 43 })
		label(c, M.GRADE_TEXT[f.grade], 16, col, { Position = UDim2.fromOffset(0, 78), Size = UDim2.new(1, 0, 0, 20),
			TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 43 })
		local foot = extra or (known and string.format("x%d   ⚖ %.2f kg", row.n or 0, row.best or 0) or "")
		label(c, foot, 15, T.MUTED, { Position = UDim2.fromOffset(4, 100), Size = UDim2.new(1, -8, 0, 18),
			TextXAlignment = Enum.TextXAlignment.Center, TextScaled = true, ZIndex = 43 })
		return c
	end

	local function paintCooler()
		local page = pages.cooler
		clear(page)
		mk("UIGridLayout", { CellSize = UDim2.fromOffset(140, 124), CellPadding = UDim2.fromOffset(8, 8) }, page)
		local zoneId = data.spot and data.spot.zoneId or "sunscar"
		for _, f in ipairs(M.FISH[zoneId] or {}) do
			fishCard(page, f, data.cooler and data.cooler[f.id])
		end
	end

	-- The chips, with the AFK countdown ticking between states.
	function ctl.paintSub()
		local st = (data and data.state) or {}
		local left = (tonumber(st.afkNext) or 0) - (os.clock() - ((data and data.at) or os.clock()))
		local full = (st.baitGot or 0) >= (st.cap or M.BAIT_DAY_CAP)
		baitChip:FindFirstChildOfClass("TextLabel").Text = "🐛 " .. (st.bait or 0)
		dayChip:FindFirstChildOfClass("TextLabel").Text = "📅 " .. (st.baitGot or 0) .. "/" .. (st.cap or M.BAIT_DAY_CAP)
		afkChip:FindFirstChildOfClass("TextLabel").Text = full and "💤 ✅" or ("💤 " .. clockText(math.max(0, left)))
		tokenChip:FindFirstChildOfClass("TextLabel").Text = "🎟 " .. short(data and data.tokens or 0)
	end
	task.spawn(function()
		while root.Parent do
			task.wait(1)
			if root.Visible and data then
				pcall(ctl.paintSub)
			end
		end
	end)

	local function paint()
		if not data then
			return
		end
		title.Text = "🎣 " .. string.upper((data.spot and data.spot.name) or "Fishing")
		ctl.paintSub()
		for id, b in pairs(tabs) do
			b.BackgroundColor3 = (id == tab) and T.ACCENT or T.CARD
			pages[id].Visible = (id == tab)
		end
		if tab == "fish" then
			paintFish()
		elseif tab == "tackle" then
			paintTackle()
		elseif tab == "odds" then
			paintOdds()
		else
			paintCooler()
		end
	end

	for id, b in pairs(tabs) do
		b.MouseButton1Click:Connect(function()
			tab = id
			help.Visible = false
			paint()
		end)
	end

	-- --------------------------------------------------------- minigame --
	--[[
		PLAYING THE FISH, IN THE POND. Owner, 2026-10-11: "Instead of making the
		fish a icon on a gui, make it look like your fishing in a pond, and
		theres a marker tracking it, with the distance, and make it so therews
		just a button in the bottom center of the screen thats says Reel, and
		have the tension car a half circle around the bar", "make the icon have
		a little fish icon with a distance marker", and no "reel now"
		instructions except the first time.

		So the minigame is mostly in the WORLD (all of it client-side, nobody
		else sees it):
		  * a rod at your side and a LINE (a Beam) from its tip to the water,
		    slack when the tension is low and pulled straight as it climbs;
		  * the cast throws a BOBBER out along an arc;
		  * on the bite, a splash, and the bobber becomes the FISH MARKER: a
		    🐟 bubble in the fish's colour with the distance under it, swimming
		    the pond -- out toward the far rim as it gets away, darting side to
		    side, harder when it runs;
		and on screen only ONE button, bottom centre -- Cast, then Reel -- with a
		half-circle gauge round it: the power while casting (the gold is the
		sweet spot), the tension while reeling (the creeping floor in dark red).
	]]
	local Players = game:GetService("Players")
	local CollectionService = game:GetService("CollectionService")

	local reelRoot = mk("Frame", {
		Name = "FishingHud", Visible = false, AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(340, 200), ZIndex = 45,
	}, gui)
	reelRoot:SetAttribute("MineUIAdopted", true)
	local hud = reelRoot -- the controller's isOpen() and the AFK guard read this
	local hudScale = mk("UIScale", {}, reelRoot)
	local function fitHud()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		hudScale.Scale = math.clamp(math.min(vp.X / 700, vp.Y / 640), 0.7, 1.15)
	end
	fitHud()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitHud)
	end

	-- The half-circle gauge: SEGS little bars standing on an arc round the button.
	local SEGS, R, CX, CY = 26, 132, 170, 168
	local segs = {}
	for i = 1, SEGS do
		local th = math.pi - (i - 0.5) / SEGS * math.pi
		local seg = mk("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = T.INK, BorderSizePixel = 0,
			Position = UDim2.fromOffset(CX + R * math.cos(th), CY - R * math.sin(th)),
			Size = UDim2.fromOffset(22, 12), Rotation = 90 - math.deg(th), ZIndex = 46,
		}, reelRoot)
		round(seg, 4)
		stroke(seg, T.OUTLINE, 2)
		segs[i] = seg
	end
	local gaugeBox = { pos = reelRoot.Position }

	local action = button(reelRoot, "Cast", UDim2.fromOffset(210, 78), UDim2.fromOffset(CX - 105, CY - 46), T.CANDY.gold[2])
	action.Name = "Action"
	action.TextSize = 36
	action.ZIndex = 47
	local quit = button(reelRoot, "✖", UDim2.fromOffset(40, 40), UDim2.fromOffset(CX + 120, CY - 6), T.CARD)
	quit.Name = "GiveUp"
	quit.TextSize = 16
	quit.ZIndex = 47
	-- First time only: one short line above the gauge.
	local hint = label(reelRoot, "", 20, T.TEXT, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(CX, CY - R - 18),
		Size = UDim2.fromOffset(460, 26), TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.3,
		TextStrokeColor3 = T.OUTLINE, ZIndex = 46 })

	-- Big words in the middle of the screen: FISH ON!, LANDED!, SNAP!
	local headline = label(gui, "", 54, T.GOLD, { Name = "FishingWord", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromOffset(700, 70), TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.15, TextStrokeColor3 = T.OUTLINE, Visible = false, ZIndex = 60 })
	local headScale = mk("UIScale", {}, headline)
	local function shout(text, color, hold)
		headline.Text = text
		headline.TextColor3 = color or T.GOLD
		headline.Visible = true
		headScale.Scale = 0.4
		TweenService:Create(headScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		local mine = text
		if hold then
			task.delay(hold, function()
				if headline.Text == mine then
					headline.Visible = false
				end
			end)
		end
	end

	-- Paint the gauge: `value` lit (green -> gold -> red along the arc), `floor`
	-- dark red underneath, or for the cast, the sweet zone and the needle.
	local function paintGauge(value, floor, cast)
		for i, seg in ipairs(segs) do
			local a = (i - 0.5) / SEGS
			if cast then
				local off = math.abs(a - M.CAST.sweet)
				local base = (off <= M.CAST.perfect + 0.02) and T.GOLD or ((off <= M.CAST.good) and T.CANDY.green[2] or T.INK)
				local here = math.abs(a - value) <= 0.5 / SEGS + 0.001
				seg.BackgroundColor3 = here and Color3.new(1, 1, 1) or base
				seg.BackgroundTransparency = here and 0 or ((base == T.INK) and 0.2 or 0.35)
				seg.Size = here and UDim2.fromOffset(26, 18) or UDim2.fromOffset(22, 12)
			else
				local lit = a <= value
				local col = (a < 0.5) and T.GREEN:Lerp(T.GOLD, a / 0.5) or T.GOLD:Lerp(T.RED, (a - 0.5) / 0.5)
				if lit then
					seg.BackgroundColor3 = col
					seg.BackgroundTransparency = 0
				elseif a <= floor then
					seg.BackgroundColor3 = Color3.fromRGB(110, 24, 34)
					seg.BackgroundTransparency = 0
				else
					seg.BackgroundColor3 = T.INK
					seg.BackgroundTransparency = 0.2
				end
				seg.Size = UDim2.fromOffset(22, 12)
			end
		end
		-- Close to snapping, the whole gauge shakes.
		if not cast and value > 0.82 then
			local j = (value - 0.82) * 30
			reelRoot.Position = gaugeBox.pos + UDim2.fromOffset((math.random() - 0.5) * j, (math.random() - 0.5) * j)
		else
			reelRoot.Position = gaugeBox.pos
		end
	end

	-- ------------------------------------------------- the pond, in 3D --
	local fx = {} -- rod, line, bobber, marker ... for this cast; cleared after
	local pond -- { water, dock, fwd, right, half, halfW, surface }

	local function findPond(spotId)
		for _, d in ipairs(CollectionService:GetTagged("MineFishSpot")) do
			if d:GetAttribute("SpotId") == spotId then
				local water = d.Parent and d.Parent:FindFirstChild("PondWater")
				if water then
					--[[
						YOUR END OF THE POOL IS THE TIP OF THE DOCK, not the rim behind it.
						The Sunscar pond is 32 studs long and its pier runs 10 into it, so
						counting from the rim put the first third of every fight under the
						planks, with the fish marker hidden (seen in Studio, 2026-10-12).
					]]
					local fwd = water.CFrame.LookVector
					local half = water.Size.Z * 0.5
					local tip = -half
					for _, part in ipairs(d.Parent:GetChildren()) do
						if part:IsA("BasePart") and (part == d or part.Name:find("^Pier")) then
							local cf = part.CFrame
							local reach = 0.5 * (math.abs(fwd:Dot(cf.RightVector)) * part.Size.X
								+ math.abs(fwd:Dot(cf.UpVector)) * part.Size.Y
								+ math.abs(fwd:Dot(cf.LookVector)) * part.Size.Z)
							tip = math.max(tip, (part.Position - water.Position):Dot(fwd) + reach)
						end
					end
					return {
						water = water, dock = d,
						fwd = fwd, right = water.CFrame.RightVector,
						half = half, halfW = water.Size.X * 0.5,
						start = math.clamp(tip + 1.5, -half + 2, half - 8),
						surface = water.Position.Y + water.Size.Y * 0.5,
					}
				end
			end
		end
		return nil
	end

	-- Where `dist` metres puts the fish: 0 just past the end of the dock, 100 m
	-- (where it can slip the hook) at the far rim; `side` -1..1 across it.
	local function pondPoint(dist, side)
		local t = math.clamp((tonumber(dist) or 0) / Fight.ESCAPE_AT, 0, 1)
		local start = pond.start or (-pond.half + 2)
		local along = start + (pond.half - 2 - start) * t
		local p = pond.water.Position + pond.fwd * along + pond.right * (side * (pond.halfW - 2.5))
		return Vector3.new(p.X, pond.surface + 0.15, p.Z)
	end

	local function clearFx()
		for _, inst in pairs(fx) do
			if typeof(inst) == "Instance" then
				inst:Destroy()
			end
		end
		fx = {}
	end

	local function splash(at, color, big)
		local ring = mk("Part", {
			Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
			Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Color = color or Color3.new(1, 1, 1),
			Size = Vector3.new(0.12, 1, 1), Transparency = 0.25,
			CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90)),
		}, workspace)
		local grow = big and 9 or 5
		TweenService:Create(ring, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
			Size = Vector3.new(0.12, grow, grow), Transparency = 1,
		}):Play()
		task.delay(0.65, function()
			ring:Destroy()
		end)
	end

	-- The rod at your right hand, the line from its tip, the bobber.
	local function rigFx()
		clearFx()
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (hrp and pond) then
			return
		end
		if hum then
			pcall(function()
				hum:UnequipTools()
			end)
		end
		local grip = Vector3.new(1.1, 0.2, -0.9)
		local dir = Vector3.new(0, math.sin(math.rad(38)), -math.cos(math.rad(38)))
		local rod = mk("Part", {
			Name = "FishingRod", Size = Vector3.new(0.18, 0.18, 7), Color = Color3.fromRGB(122, 84, 50),
			Material = Enum.Material.Wood, CanCollide = false, CanQuery = false, CanTouch = false, Massless = true,
		}, workspace)
		local reelKnob = mk("Part", {
			Name = "Reel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, 0.6, 0.6),
			Color = Color3.fromRGB(60, 60, 70), Material = Enum.Material.Metal,
			CanCollide = false, CanQuery = false, CanTouch = false, Massless = true,
		}, rod)
		local w = mk("Weld", { Part0 = hrp, Part1 = rod, C0 = CFrame.lookAt(grip + dir * 3.5, grip + dir * 4.5) }, rod)
		mk("Weld", { Part0 = rod, Part1 = reelKnob, C0 = CFrame.new(0.25, -0.1, 2.4) }, reelKnob)
		local tip = mk("Attachment", { Name = "Tip", Position = Vector3.new(0, 0, -3.5) }, rod)
		tip.Axis = Vector3.new(0, -1, 0)
		local bob = mk("Part", {
			Name = "Bobber", Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 0.7, 0.7), Anchored = true,
			Color = Color3.fromRGB(235, 60, 60), Material = Enum.Material.SmoothPlastic,
			CanCollide = false, CanQuery = false, CanTouch = false, CFrame = CFrame.new(tip.WorldPosition),
		}, workspace)
		local bobAt = mk("Attachment", { Name = "Line" }, bob)
		local line = mk("Beam", {
			Attachment0 = tip, Attachment1 = bobAt, Width0 = 0.06, Width1 = 0.06, FaceCamera = true, Segments = 24,
			Color = ColorSequence.new(Color3.fromRGB(240, 240, 240)), Transparency = NumberSequence.new(0.1),
			CurveSize0 = 2.5, CurveSize1 = 0,
		}, rod)
		fx.rod, fx.bob, fx.line, fx.weld = rod, bob, line, w
	end

	-- The fish marker: a 🐟 bubble in the fish's colour, the distance under it.
	local function rigMarker()
		if not fx.bob then
			return
		end
		local bb = mk("BillboardGui", {
			Name = "FishMarker", Size = UDim2.fromOffset(84, 78), StudsOffset = Vector3.new(0, 2.6, 0),
			AlwaysOnTop = true, LightInfluence = 0, MaxDistance = 300,
		}, fx.bob)
		local bubble = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.fromOffset(50, 50), BackgroundColor3 = COLOUR.green.col }, bb)
		round(bubble, 25)
		stroke(bubble, T.OUTLINE, 3)
		label(bubble, "🐟", 30, T.TEXT, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
		local dist = label(bb, "", 20, T.TEXT, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.fromOffset(84, 24), TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.2,
			TextStrokeColor3 = T.OUTLINE })
		fx.bubble, fx.distLabel = bubble, dist
		-- The bobber is under now; the bubble and the splashes show the fish.
		fx.bob.Transparency = 1
	end

	-- State of the running minigame.
	local castT0, castTick = 0, 0
	local fight, toggles, reelDown, lastReeling, acc
	local heartbeat
	local catchQueue, catchIndex = nil, 0
	local catchHolder
	local firstTime = false
	local wiggle, wiggleT = 0, 0

	local function stopLoop()
		if heartbeat then
			heartbeat:Disconnect()
			heartbeat = nil
		end
	end

	local function clearCatch()
		if catchHolder then
			catchHolder:Destroy()
			catchHolder = nil
		end
	end

	--[[
		The tutorial's hint card (MineUI.Intro) sits bottom-centre, right over the
		cast gauge and REEL (seen in Studio, 2026-10-12). It is tucked away while
		you fish and comes back after.
	]]
	local tuckedIntro
	local function tuckIntro(on)
		local intro = gui:FindFirstChild("Intro")
		if on then
			if intro and intro:IsA("GuiObject") and intro.Visible then
				tuckedIntro = intro
				intro.Visible = false
			end
		elseif tuckedIntro then
			if tuckedIntro.Parent then
				tuckedIntro.Visible = true
			end
			tuckedIntro = nil
		end
	end

	local function endMinigame()
		stopLoop()
		stage = nil
		tuckIntro(false)
		reelRoot.Visible = false
		headline.Visible = false
		reelDown = false
		clearCatch()
		clearFx()
		if data then
			root.Visible = true
			paint()
		end
	end

	local function startCast()
		clearCatch()
		catchQueue, catchIndex = nil, 0
		fitHud()
		pond = data and findPond(data.spotId) or nil
		rigFx()
		firstTime = data and data.state and (tonumber(data.state.casts) or 0) == 0 or false
		stage = "cast"
		root.Visible = false
		tuckIntro(true)
		reelRoot.Visible = true
		headline.Visible = false
		hint.Text = firstTime and "Tap CAST when the white mark is in the GOLD ✨" or ""
		action.Text = "Cast"
		action.BackgroundColor3 = T.CANDY.gold[2]
		action.Visible = true
		quit.Visible = true
		castT0 = os.clock()
		stopLoop()
		heartbeat = RunService.Heartbeat:Connect(function()
			castTick = math.floor((os.clock() - castT0) * Fight.HZ)
			paintGauge(M.castBar(castTick), 0, true)
			if castTick > M.CAST.maxTicks then
				endMinigame()
			end
		end)
	end

	local function releaseCast()
		if stage ~= "cast" then
			return
		end
		stopLoop()
		stage = "wait"
		local q = M.castQuality(castTick)
		local power = M.castBar(castTick)
		action.Visible = false
		hint.Text = ""
		if q == "perfect" then
			shout("PERFECT! ✨", T.GOLD, 1.2)
			if Celebrate then
				pcall(Celebrate.burst, 1)
			end
		elseif q == "good" then
			shout("GOOD!", T.GREEN, 1)
		end
		send("fishCast", { tick = castTick })
		-- The bobber flies out along an arc and lands; further for more power.
		if fx.bob and pond and fx.rod then
			local from = fx.rod.Tip.WorldPosition
			local landDist = 20 + 60 * power
			local to = pondPoint(landDist, (math.random() - 0.5) * 0.6)
			local t0 = os.clock()
			heartbeat = RunService.Heartbeat:Connect(function()
				local a = math.clamp((os.clock() - t0) / 0.7, 0, 1)
				local p = from:Lerp(to, a) + Vector3.new(0, math.sin(a * math.pi) * 6, 0)
				if a >= 1 then
					stopLoop()
					splash(to, Color3.new(1, 1, 1), false)
					fx.restAt = to
					-- Bob gently until the bite.
					local b0 = os.clock()
					heartbeat = RunService.Heartbeat:Connect(function()
						if fx.bob then
							fx.bob.CFrame = CFrame.new(to + Vector3.new(0, math.sin((os.clock() - b0) * 4) * 0.12, 0))
						end
					end)
				end
				if fx.bob then
					fx.bob.CFrame = CFrame.new(p)
				end
			end)
		end
	end

	local function paintFight(dt)
		local s = fight
		local c = COLOUR[s.colour] or COLOUR.green
		paintGauge(math.clamp(s.tension, 0, 1), math.clamp(s.floor, 0, 1), false)
		action.BackgroundColor3 = reelDown and T.CANDY.green[1] or T.CANDY.green[2]
		-- The fish swims the pond: further out as it gets away, side to side,
		-- harder and faster when it runs.
		if fx.bob and pond then
			local speed = (s.colour == "red" and 3.4) or (s.colour == "yellow" and 2.0) or 0.9
			wiggleT += (dt or Fight.DT) * speed
			local reach = (s.colour == "red" and 0.95) or (s.colour == "yellow" and 0.65) or 0.35
			wiggle += ((math.sin(wiggleT) * reach) - wiggle) * math.min(1, (dt or Fight.DT) * 4)
			fx.bob.CFrame = CFrame.new(pondPoint(s.dist, wiggle))
			if s.colour == "red" and math.random() < 0.06 then
				splash(fx.bob.Position, c.col, false)
			end
		end
		if fx.bubble then
			fx.bubble.BackgroundColor3 = c.col
			fx.distLabel.Text = string.format("%d m", math.floor(s.dist + 0.5))
			fx.distLabel.TextColor3 = (s.dist > Fight.ESCAPE_AT * 0.85) and T.RED or T.TEXT
		end
		-- The line: slack when easy, straight as the tension climbs; it reddens near the snap.
		if fx.line then
			fx.line.CurveSize0 = 2.5 * (1 - math.clamp(s.tension, 0, 1))
			local hot = math.clamp((s.tension - 0.6) / 0.4, 0, 1)
			fx.line.Color = ColorSequence.new(Color3.fromRGB(240, 240, 240):Lerp(Color3.fromRGB(255, 70, 70), hot))
		end
	end

	local function finishFight(result)
		stopLoop()
		stage = "catch"
		action.Visible = false
		quit.Visible = false
		hint.Text = ""
		paintGauge(0, 0, false)
		if result == "caught" then
			shout("LANDED! 🎉", T.GREEN)
			-- Drag the marker in to the dock.
			if fx.bob and pond then
				TweenService:Create(fx.bob, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
					CFrame = CFrame.new(pondPoint(0, 0) + Vector3.new(0, 1.5, 0)),
				}):Play()
				splash(pondPoint(0, 0), T.GREEN, true)
			end
		elseif result == "snapped" then
			shout("SNAP! 💥", T.RED, 2)
			if fx.line then
				fx.line.Enabled = false
			end
			if Audio and Audio.play then
				pcall(Audio.play, "thud")
			end
		else
			shout("GOT AWAY 💨", T.MUTED, 2)
			if fx.bob and pond then
				local away = fx.bob.Position + pond.fwd * 6
				TweenService:Create(fx.bob, TweenInfo.new(0.6), { CFrame = CFrame.new(away) }):Play()
				splash(fx.bob.Position, T.MUTED, true)
			end
		end
		send("fishReel", { toggles = toggles, ticks = fight.tick })
	end

	local function startFight(f)
		clearCatch()
		stage = "fight"
		shout((f.count or 1) > 1 and ("FISH ON! x" .. f.count) or "FISH ON!", T.GOLD, 1.1)
		hint.Text = firstTime and "Hold REEL to pull. RED = it's running: tap, or let go!" or ""
		action.Text = "Reel"
		action.Visible = true
		quit.Visible = true
		if fx.restAt then
			splash(fx.restAt, Color3.new(1, 1, 1), true)
		end
		if Audio and Audio.playLoot then
			pcall(Audio.playLoot)
		end
		rigMarker()
		fight = Fight.new(f.fight)
		toggles, reelDown, lastReeling, acc = {}, false, false, 0
		wiggle, wiggleT = 0, math.random() * 6
		paintFight(0)
		stopLoop()
		heartbeat = RunService.Heartbeat:Connect(function(dt)
			acc += math.min(dt, 0.25)
			while acc >= Fight.DT and stage == "fight" do
				acc -= Fight.DT
				if reelDown ~= lastReeling then
					table.insert(toggles, fight.tick + 1)
					lastReeling = reelDown
				end
				local r = Fight.step(fight, reelDown)
				if r then
					paintFight(dt)
					finishFight(r)
					return
				end
			end
			paintFight(dt)
		end)
	end

	local function showNextCatch()
		catchIndex += 1
		local c = catchQueue and catchQueue[catchIndex]
		clearCatch()
		if not c then
			endMinigame()
			return
		end
		local f = M.fish(c.id)
		if not f then
			showNextCatch()
			return
		end
		headline.Visible = false
		catchHolder = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42),
			Size = UDim2.fromOffset(220, 188), ZIndex = 58 }, gui)
		local card = fishCard(catchHolder, f, { n = 1, best = c.kg },
			string.format("⚖ %.2f kg%s", c.kg, c.new and "   NEW!" or (c.record and "   RECORD!" or "")))
		card.Size = UDim2.fromScale(1, 1)
		for _, d in ipairs(card:GetDescendants()) do
			if d:IsA("GuiObject") then
				d.ZIndex += 16
			end
			if d:IsA("TextLabel") then
				d.TextSize = math.floor(d.TextSize * 1.4)
			end
		end
		card.ZIndex = 58
		local sc = mk("UIScale", { Scale = 0.4 }, card)
		TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		local name = mk("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -8),
			Size = UDim2.fromOffset(500, 40), Font = T.FONT, TextSize = 34, TextColor3 = M.GRADE_COLOR[f.grade],
			TextStrokeTransparency = 0.15, TextStrokeColor3 = T.OUTLINE, Text = M.GRADE_TEXT[f.grade], ZIndex = 59 }, catchHolder)
		local _ = name
		hint.Text = (#catchQueue > 1) and (catchIndex .. " / " .. #catchQueue) or ""
		action.Text = (catchIndex < #catchQueue) and "Next ▶" or "OK ✔"
		action.BackgroundColor3 = T.CANDY.green[2]
		action.Visible = true
		-- Reward juice by the REAL rarity: a minnow pops, a ★★★★★ gets the works.
		local tier = tierOf(f.grade)
		if Celebrate and tier > 0 then
			pcall(Celebrate.burst, tier)
		elseif Audio and Audio.playLoot then
			pcall(Audio.playLoot)
		end
	end

	-- Input: the one button does what the stage needs.
	action.MouseButton1Down:Connect(function()
		if stage == "fight" then
			reelDown = true
		end
	end)
	action.MouseButton1Up:Connect(function()
		reelDown = false
	end)
	action.MouseLeave:Connect(function()
		reelDown = false
	end)
	action.MouseButton1Click:Connect(function()
		if stage == "cast" then
			releaseCast()
		elseif stage == "catch" and catchQueue then
			showNextCatch()
		end
	end)
	UIS.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.F and not processed then
			if stage == "fight" then
				reelDown = true
			elseif stage == "cast" then
				releaseCast()
			end
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.F then
			reelDown = false
		end
	end)
	quit.MouseButton1Click:Connect(function()
		if stage == "fight" or stage == "wait" then
			send("fishGiveUp", {})
		end
		endMinigame()
	end)

	local function closeAll()
		if stage == "fight" or stage == "wait" then
			send("fishGiveUp", {})
		end
		stopLoop()
		stage = nil
		tuckIntro(false)
		help.Visible = false
		reelRoot.Visible = false
		headline.Visible = false
		clearCatch()
		clearFx()
		root.Visible = false
	end
	close.MouseButton1Click:Connect(closeAll)

	-- -------------------------------------------------------- messages --
	function ctl.onMessage(msg)
		if type(msg) ~= "table" then
			return
		end
		if msg.kind == "state" then
			local before = data and data.state and data.state.bait
			data = msg
			data.at = os.clock()
			if not stage then
				root.Visible = true
			end
			paint()
			if before and data.state and (data.state.bait or 0) > before and UI and UI.popNumber then
				pcall(UI.popNumber, baitChip:FindFirstChildOfClass("TextLabel"))
			end
		elseif msg.kind == "cast" then
			startCast()
		elseif msg.kind == "bite" then
			if data and data.state then
				data.state.bait = msg.bait
				data.state.casts = (tonumber(data.state.casts) or 0) + 1
			end
			local myStage = stage
			task.delay(math.max(0, tonumber(msg.bite) or 1), function()
				if stage == "wait" and myStage == "wait" then
					startFight(msg)
				end
			end)
		elseif msg.kind == "result" then
			if data then
				data.state = msg.state or data.state
			end
			if msg.result == "caught" and type(msg.catches) == "table" and #msg.catches > 0 then
				catchQueue, catchIndex = msg.catches, 0
				if data and data.cooler then
					for _, c in ipairs(msg.catches) do
						local row = data.cooler[c.id] or { n = 0, best = 0 }
						row.n = (row.n or 0) + 1
						row.best = math.max(row.best or 0, c.kg or 0)
						data.cooler[c.id] = row
					end
				end
				-- Let LANDED! and the drag-in play first.
				task.delay(0.9, function()
					if stage == "catch" and catchIndex == 0 then
						showNextCatch()
					end
				end)
			else
				if msg.result == "caught" then
					headline.Text = "Hmm, try again"
				end
				if (msg.count or 1) > 1 then
					hint.Text = "All " .. msg.count .. " got away"
				end
				action.Text = "OK"
				action.BackgroundColor3 = T.CANDY.purple[2]
				action.Visible = true
				catchQueue, catchIndex = {}, 0
				stage = "catch"
			end
		end
	end

	function ctl.isOpen()
		return root.Visible or hud.Visible
	end

	ctl.close = closeAll
	ctl.root = root
	return ctl
end

return View
