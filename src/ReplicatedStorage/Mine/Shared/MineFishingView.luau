--[[
	MineFishingView -- the fishing screen and the cast / reel minigame (TODO A3).

	The rules are MineFishing, the fight is MineFishingFight (the SAME code the
	server replays), the verbs are MineFishingService. This draws, takes input
	and reports:

	  THE SCREEN (opened from a spot's Fish prompt): bait and where it comes
	  from, four tabs --
	    FISH    the CAST button, your rod, bait for tokens
	    TACKLE  the rods: buy (coins), equip, level (coins), prestige (tokens)
	    ODDS    this spot's catch table at your luck (owner: odds shown)
	    COOLER  your fish cards, this zone's twelve, best size each

	  THE MINIGAME:
	    cast   a power bar sweeps; stop it on the sweet spot. Good and perfect
	           casts are luck (owner).
	    wait   the bobber sits until the bite.
	    reel   hold REEL (button, or F). The fish is GREEN, YELLOW or RED; the
	           tension bar has a floor that creeps up if you hold it high; past
	           100 m it can slip the hook. The client runs MineFishingFight at
	           30 ticks a second and records only when REEL went down and up;
	           the server replays that to decide.
	    catch  the cards, worst to best, one tap each (owner: "least to best").

	mount(gui, opts) -> controller { onMessage(data), close(), isOpen() }
	  opts.send(action, payload)   fire a "fish..." verb to the server
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local shared = game:GetService("ReplicatedStorage"):WaitForChild("Mine"):WaitForChild("Shared")
local T = require(shared:WaitForChild("MineTheme"))
local M = require(shared:WaitForChild("MineFishing"))
local Fight = require(shared:WaitForChild("MineFishingFight"))

local View = {}

local COLOUR = {
	green = { col = Color3.fromRGB(96, 226, 120), word = "TIRED  ·  REEL!" },
	yellow = { col = Color3.fromRGB(255, 206, 70), word = "FIGHTING  ·  CAREFUL" },
	red = { col = Color3.fromRGB(255, 76, 76), word = "RUNNING  ·  TAP OR LET GO" },
}

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

local function button(parent, text, size, pos, color)
	local b = mk("TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = color or T.ACCENT,
		Text = text,
		TextColor3 = T.ON_CANDY,
		TextSize = 18,
		Font = T.FONT,
		Size = size,
		Position = pos or UDim2.new(),
	}, parent)
	round(b, 12)
	stroke(b, T.OUTLINE, 2)
	return b
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
	if secs >= 60 then
		return string.format("%dm %02ds", math.floor(secs / 60), secs % 60)
	end
	return secs .. "s"
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
	stroke(root, T.EDGE, 3)
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

	local title = label(root, "🎣 FISHING", 28, T.GOLD, { Position = UDim2.fromOffset(22, 14), Size = UDim2.new(1, -80, 0, 32), ZIndex = 41 })
	local sub = label(root, "", 15, T.MUTED, { Position = UDim2.fromOffset(24, 48), Size = UDim2.new(1, -48, 0, 20), ZIndex = 41 })
	local close = button(root, "X", UDim2.fromOffset(40, 40), UDim2.new(1, -54, 0, 14), T.CANDY.red[2])
	close.Name = "Close"
	close.ZIndex = 42

	-- Tabs.
	local tabs = {}
	local tabBar = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 76), Size = UDim2.new(1, -40, 0, 38), ZIndex = 41 }, root)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, tabBar)
	local pages = {}
	for _, t in ipairs({ { "fish", "FISH" }, { "tackle", "TACKLE" }, { "odds", "ODDS" }, { "cooler", "COOLER" } }) do
		local b = button(tabBar, t[2], UDim2.fromOffset(140, 36), nil, T.CARD)
		b.Name = "Tab_" .. t[1]
		b.ZIndex = 42
		tabs[t[1]] = b
		pages[t[1]] = mk("ScrollingFrame", {
			Name = "Page_" .. t[1], BackgroundTransparency = 1, Visible = false, Position = UDim2.fromOffset(20, 124),
			Size = UDim2.new(1, -40, 1, -140), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 6, BorderSizePixel = 0, ZIndex = 41,
		}, root)
	end

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

	-- FISH
	local function paintFish()
		local page = pages.fish
		clear(page)
		local st = data.state or {}
		local rodId = st.rod or M.STARTER_ROD
		local r = rodDef(rodId)
		local stats = data.rodStats or M.rodStats(rodId, st.rodLevel)
		local card = mk("Frame", { BackgroundColor3 = T.CARD, Size = UDim2.new(1, -8, 0, 120), ZIndex = 42 }, page)
		round(card, 14)
		stroke(card, T.LINE)
		label(card, r.name .. "  ·  level " .. (st.rodLevel or 0), 22, T.TEXT, { Position = UDim2.fromOffset(16, 12), ZIndex = 43 })
		label(card, string.format("Reel %.1f m/s   ·   Line x%.2f   ·   Luck x%.2f%s", stats.reel, stats.line, stats.luck,
			(stats.bait or 1) > 1 and ("   ·   " .. stats.bait .. " bait a cast") or ""), 15, T.MUTED,
			{ Position = UDim2.fromOffset(16, 44), ZIndex = 43 })
		label(card, string.format("This spot: luck x%.2f in total. Perfect cast x%.1f, good x%.1f.", data.luck or 1,
			M.CAST.luck.perfect, M.CAST.luck.good), 15, T.MUTED, { Position = UDim2.fromOffset(16, 70), ZIndex = 43 })
		local need = stats.bait or 1
		local cast = button(page, (st.bait or 0) >= need and "CAST" or "NO BAIT", UDim2.fromOffset(260, 64),
			UDim2.fromOffset(0, 134), (st.bait or 0) >= need and T.CANDY.gold[2] or T.DEAD)
		cast.Name = "Cast"
		cast.TextSize = 30
		cast.ZIndex = 43
		cast.Position = UDim2.new(0.5, -130, 0, 134)
		cast.MouseButton1Click:Connect(function()
			if (st.bait or 0) >= need and not stage then
				send("fishStart", { spotId = data.spotId })
			end
		end)
		local buyRow = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 214), Size = UDim2.new(1, 0, 0, 44), ZIndex = 42 }, page)
		label(buyRow, string.format("Bait for tokens: %d each (you have %s)", M.TOKEN_PRICE, short(data.tokens)), 15, T.MUTED,
			{ Position = UDim2.fromOffset(4, 10), Size = UDim2.new(0.55, 0, 0, 22), ZIndex = 43 })
		for i, n in ipairs({ 1, 5 }) do
			local b = button(buyRow, "+" .. n .. "  (" .. n * M.TOKEN_PRICE .. ")", UDim2.fromOffset(120, 40),
				UDim2.new(1, -250 + (i - 1) * 128, 0, 0), T.CANDY.cyan[2])
			b.TextSize = 16
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
		mk("UIListLayout", { Padding = UDim.new(0, 8) }, page)
		local st = data.state or {}
		for _, row in ipairs(data.rods or {}) do
			local r = rodDef(row.id)
			local equipped = st.rod == row.id
			local card = mk("Frame", { BackgroundColor3 = equipped and T.CARD_HI or T.CARD, Size = UDim2.new(1, -10, 0, 88), ZIndex = 42 }, page)
			round(card, 12)
			stroke(card, equipped and T.GOLD or T.LINE, equipped and 2 or 1)
			label(card, r.name .. (row.owned and ("  ·  L" .. row.level .. "/" .. row.cap) or ""), 19, T.TEXT,
				{ Position = UDim2.fromOffset(14, 8), Size = UDim2.new(0.6, 0, 0, 24), ZIndex = 43 })
			label(card, r.blurb or "", 14, T.MUTED, { Position = UDim2.fromOffset(14, 34), Size = UDim2.new(0.6, 0, 0, 18), ZIndex = 43 })
			label(card, string.format("Reel %.1f · Line x%.2f · Luck x%.2f%s", row.stats.reel, row.stats.line, row.stats.luck,
				r.bait > 1 and (" · " .. r.bait .. " bait") or ""), 14, T.FAINT,
				{ Position = UDim2.fromOffset(14, 58), Size = UDim2.new(0.6, 0, 0, 18), ZIndex = 43 })
			local function act(text, color, verb)
				local b = button(card, text, UDim2.fromOffset(200, 40), UDim2.new(1, -212, 0.5, -20), color)
				b.TextSize = 16
				b.ZIndex = 43
				b.MouseButton1Click:Connect(function()
					send(verb, { rodId = row.id, spotId = data.spotId })
				end)
				return b
			end
			if not row.owned then
				act("BUY  " .. short(row.price) .. " coins", ((data.coins or 0) >= row.price) and T.CANDY.gold[2] or T.DEAD, "fishBuyRod")
			elseif row.prestigeCost then
				act("PRESTIGE  " .. short(row.prestigeCost) .. " tokens", T.CANDY.magenta[2], "fishPrestigeRod")
			elseif row.nextCost then
				act("LEVEL UP  " .. short(row.nextCost) .. " coins", ((data.coins or 0) >= row.nextCost) and T.CANDY.green[2] or T.DEAD, "fishUpgradeRod")
			else
				local b = act("MAX", T.DEAD, "fishUpgradeRod")
				b.Active = false
			end
			if row.owned and not equipped then
				local e = button(card, "EQUIP", UDim2.fromOffset(90, 30), UDim2.new(1, -310, 0.5, -15), T.CANDY.purple[2])
				e.TextSize = 14
				e.ZIndex = 43
				e.MouseButton1Click:Connect(function()
					send("fishEquipRod", { rodId = row.id, spotId = data.spotId })
				end)
			end
		end
		label(page, string.format("Levels cost coins (x%.1f each). Every %d levels the rod needs a prestige, paid in tokens. Rods and levels stay through rebirth.",
			M.LEVEL_COST_GROW, M.PRESTIGE_EVERY), 14, T.MUTED, { TextWrapped = true, Size = UDim2.new(1, -10, 0, 40), ZIndex = 42 })
	end

	-- ODDS
	local function paintOdds()
		local page = pages.odds
		clear(page)
		mk("UIListLayout", { Padding = UDim.new(0, 4) }, page)
		label(page, string.format("What bites here, at your luck (x%.2f). A perfect cast is x%.1f on top.", data.luck or 1, M.CAST.luck.perfect),
			15, T.MUTED, { Size = UDim2.new(1, -10, 0, 22), ZIndex = 42 })
		for _, row in ipairs(data.odds or {}) do
			local f = M.fish(row.id)
			if f then
				local line = mk("Frame", { BackgroundColor3 = T.CARD, Size = UDim2.new(1, -10, 0, 30), ZIndex = 42 }, page)
				round(line, 8)
				local col = M.GRADE_COLOR[f.grade]
				label(line, M.GRADE_TEXT[f.grade], 16, col, { Position = UDim2.fromOffset(10, 4), Size = UDim2.fromOffset(110, 22), ZIndex = 43 })
				label(line, f.name, 16, T.TEXT, { Position = UDim2.fromOffset(124, 4), Size = UDim2.new(0.5, 0, 0, 22), ZIndex = 43 })
				local pct = row.p * 100
				local txt = (pct >= 1) and string.format("%.1f%%", pct) or string.format("1 in %s", short(math.floor(1 / math.max(row.p, 1e-9) + 0.5)))
				label(line, txt, 16, T.GOLD, { Position = UDim2.new(1, -150, 0, 4), Size = UDim2.fromOffset(140, 22),
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
		stroke(c, known and col or T.LINE, known and 2 or 1)
		local band = mk("Frame", { BackgroundColor3 = known and col or T.LINE, Size = UDim2.new(1, 0, 0, 8), ZIndex = 43 }, c)
		round(band, 6)
		label(c, known and "🐟" or "?", 34, T.TEXT, { Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 40),
			TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 43 })
		label(c, known and f.name or "???", 15, T.TEXT, { Position = UDim2.fromOffset(6, 58), Size = UDim2.new(1, -12, 0, 20),
			TextXAlignment = Enum.TextXAlignment.Center, TextScaled = true, ZIndex = 43 })
		label(c, M.GRADE_TEXT[f.grade], 14, col, { Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 18),
			TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 43 })
		local foot = extra or (known and string.format("x%d  ·  best %.2f kg", row.n or 0, row.best or 0) or "not caught yet")
		label(c, foot, 13, T.MUTED, { Position = UDim2.fromOffset(4, 100), Size = UDim2.new(1, -8, 0, 18),
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

	-- The bait line, with the AFK countdown ticking between states.
	function ctl.paintSub()
		local st = (data and data.state) or {}
		local left = (tonumber(st.afkNext) or 0) - (os.clock() - ((data and data.at) or os.clock()))
		local full = (st.baitGot or 0) >= (st.cap or M.BAIT_DAY_CAP)
		sub.Text = string.format("Bait %d   ·   today %d/%d   ·   %s   ·   quests +%d each",
			st.bait or 0, st.baitGot or 0, st.cap or M.BAIT_DAY_CAP,
			full and "daily cap reached" or ("next AFK bait in " .. clockText(math.max(0, left))), M.QUEST_BAIT)
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
			paint()
		end)
	end

	-- --------------------------------------------------------- minigame --
	local hud = mk("Frame", {
		Name = "FishingHud", Visible = false, AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -130), Size = UDim2.fromOffset(560, 250),
		BackgroundColor3 = T.PANEL, BackgroundTransparency = 0.08, ZIndex = 45,
	}, gui)
	round(hud, 18)
	stroke(hud, T.EDGE, 3)
	hud:SetAttribute("MineUIAdopted", true)
	local hudScale = mk("UIScale", {}, hud)
	local function fitHud()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		hudScale.Scale = math.clamp(math.min(vp.X / 600, vp.Y / 560), 0.55, 1.1)
	end
	fitHud()
	-- The camera's viewport is 1x1 while the client boots, so fit again when it settles.
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitHud)
	end
	local headline = label(hud, "", 26, T.GOLD, { Position = UDim2.fromOffset(20, 10), Size = UDim2.new(1, -40, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 46 })
	local hint = label(hud, "", 15, T.MUTED, { Position = UDim2.fromOffset(20, 42), Size = UDim2.new(1, -40, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 46 })

	-- A horizontal bar: track, fill, and markers.
	local function bar(y, h)
		local track = mk("Frame", { BackgroundColor3 = T.INK, Position = UDim2.fromOffset(30, y), Size = UDim2.new(1, -60, 0, h), ZIndex = 46 }, hud)
		round(track, 8)
		stroke(track, T.LINE)
		local fill = mk("Frame", { BackgroundColor3 = T.GREEN, Size = UDim2.fromScale(0, 1), ZIndex = 47 }, track)
		round(fill, 8)
		return track, fill
	end

	-- Cast bar: the good and perfect zones, and the sweeping needle.
	local castTrack = bar(80, 34)
	local good = mk("Frame", { BackgroundColor3 = T.CANDY.green[2], BackgroundTransparency = 0.45, ZIndex = 47,
		Position = UDim2.fromScale(M.CAST.sweet - M.CAST.good, 0), Size = UDim2.fromScale(M.CAST.good * 2, 1) }, castTrack)
	local perfect = mk("Frame", { BackgroundColor3 = T.GOLD, ZIndex = 48,
		Position = UDim2.fromScale(M.CAST.sweet - M.CAST.perfect, 0), Size = UDim2.fromScale(M.CAST.perfect * 2, 1) }, castTrack)
	local needle = mk("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 49,
		Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0, 6, 1, 10) }, castTrack)
	round(needle, 3)
	local _ = good and perfect

	-- Fight bars: distance (the 100 m line marked) and tension (the floor marked).
	local distTrack, distFill = bar(84, 22)
	local line100 = mk("Frame", { BackgroundColor3 = T.RED, Position = UDim2.fromScale(Fight.ESCAPE_AT / Fight.MAX_DIST, 0),
		Size = UDim2.new(0, 3, 1, 0), ZIndex = 48 }, distTrack)
	local distText = label(hud, "", 15, T.TEXT, { Position = UDim2.fromOffset(30, 62), Size = UDim2.fromOffset(240, 20), ZIndex = 46 })
	local tensTrack, tensFill = bar(132, 26)
	local floorMark = mk("Frame", { BackgroundColor3 = T.RED, BackgroundTransparency = 0.35, Size = UDim2.fromScale(0, 1), ZIndex = 48 }, tensTrack)
	local tensText = label(hud, "TENSION", 15, T.TEXT, { Position = UDim2.fromOffset(30, 110), Size = UDim2.fromOffset(240, 20), ZIndex = 46 })
	local fishLamp = mk("Frame", { BackgroundColor3 = COLOUR.green.col, AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -30, 0, 58), Size = UDim2.fromOffset(250, 24), ZIndex = 46 }, hud)
	round(fishLamp, 12)
	local fishWord = label(fishLamp, "", 15, T.INK, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 47 })
	local _2 = line100

	local action = button(hud, "CAST", UDim2.fromOffset(240, 58), UDim2.new(0.5, -120, 1, -72), T.CANDY.gold[2])
	action.Name = "Action"
	action.TextSize = 28
	action.ZIndex = 47
	local quit = button(hud, "GIVE UP", UDim2.fromOffset(110, 34), UDim2.new(1, -126, 1, -52), T.CARD)
	quit.Name = "GiveUp"
	quit.TextSize = 14
	quit.ZIndex = 47

	local function showParts(which)
		castTrack.Visible = which == "cast"
		for _, o in ipairs({ distTrack, tensTrack, distText, tensText, fishLamp }) do
			o.Visible = which == "fight"
		end
	end

	-- State of the running minigame.
	local castT0, castTick = 0, 0
	local fight, toggles, reelDown, lastReeling, acc
	local heartbeat
	local catchQueue, catchIndex = nil, 0
	local catchHolder

	local function stopLoop()
		if heartbeat then
			heartbeat:Disconnect()
			heartbeat = nil
		end
	end

	local function endMinigame()
		stopLoop()
		stage = nil
		hud.Visible = false
		reelDown = false
		if catchHolder then
			catchHolder:Destroy()
			catchHolder = nil
		end
		if data then
			root.Visible = true
			paint()
		end
	end

	local function startCast()
		-- A new cast starts clean: no card left over from the last catch.
		if catchHolder then
			catchHolder:Destroy()
			catchHolder = nil
		end
		catchQueue, catchIndex = nil, 0
		headline.TextColor3 = T.GOLD
		fitHud()
		stage = "cast"
		root.Visible = false
		hud.Visible = true
		showParts("cast")
		headline.Text = "CAST!"
		hint.Text = "Stop the bar in the gold for a PERFECT cast (more luck)"
		action.Text = "CAST"
		action.Visible = true
		castT0 = os.clock()
		stopLoop()
		heartbeat = RunService.Heartbeat:Connect(function()
			castTick = math.floor((os.clock() - castT0) * Fight.HZ)
			needle.Position = UDim2.fromScale(M.castBar(castTick), 0.5)
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
		headline.Text = (q == "perfect" and "PERFECT CAST!") or (q == "good" and "GOOD CAST") or "Cast"
		hint.Text = "Waiting for a bite ..."
		action.Visible = false
		send("fishCast", { tick = castTick })
	end

	local function paintFight()
		local s = fight
		local c = COLOUR[s.colour] or COLOUR.green
		distFill.Size = UDim2.fromScale(math.clamp(s.dist / Fight.MAX_DIST, 0, 1), 1)
		distFill.BackgroundColor3 = (s.dist > Fight.ESCAPE_AT) and T.RED or T.CANDY.cyan[2]
		distText.Text = string.format("%.1f m%s", s.dist, (s.dist > Fight.ESCAPE_AT) and "  ·  SLIPPING!" or "")
		tensFill.Size = UDim2.fromScale(math.clamp(s.tension, 0, 1), 1)
		tensFill.BackgroundColor3 = (s.tension > 0.8) and T.RED or ((s.tension > 0.55) and T.GOLD or T.GREEN)
		floorMark.Size = UDim2.fromScale(math.clamp(s.floor, 0, 1), 1)
		tensText.Text = string.format("TENSION %d%%%s", math.floor(s.tension * 100), (s.floor > 0.05) and string.format("  ·  floor %d%%", math.floor(s.floor * 100)) or "")
		fishLamp.BackgroundColor3 = c.col
		fishWord.Text = c.word
		action.BackgroundColor3 = reelDown and T.CANDY.green[1] or T.CANDY.green[2]
	end

	local function finishFight(result)
		stopLoop()
		stage = "catch"
		action.Visible = false
		quit.Visible = false
		if result == "caught" then
			headline.Text = "LANDED!"
			hint.Text = "..."
		elseif result == "snapped" then
			headline.Text = "SNAP! The line broke"
			hint.Text = "Too much tension. Let go on red."
		else
			headline.Text = "It got away"
			hint.Text = "Keep it under 100 m."
		end
		send("fishReel", { toggles = toggles, ticks = fight.tick })
	end

	local function startFight(f)
		if catchHolder then
			catchHolder:Destroy()
			catchHolder = nil
		end
		headline.TextColor3 = T.GOLD
		stage = "fight"
		showParts("fight")
		headline.Text = (f.count or 1) > 1 and ("FISH ON!  x" .. f.count) or "FISH ON!"
		hint.Text = "Hold REEL (or F). Green: reel. Yellow: careful. Red: tap or let go."
		action.Text = "REEL"
		action.Visible = true
		quit.Visible = true
		fight = Fight.new(f.fight)
		toggles, reelDown, lastReeling, acc = {}, false, false, 0
		paintFight()
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
					paintFight()
					finishFight(r)
					return
				end
			end
			paintFight()
		end)
	end

	local function showNextCatch()
		catchIndex += 1
		local c = catchQueue and catchQueue[catchIndex]
		if catchHolder then
			catchHolder:Destroy()
			catchHolder = nil
		end
		if not c then
			endMinigame()
			return
		end
		local f = M.fish(c.id)
		if not f then
			showNextCatch()
			return
		end
		catchHolder = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 66),
			Size = UDim2.fromOffset(150, 128), ZIndex = 48 }, hud)
		local card = fishCard(catchHolder, f, { n = 1, best = c.kg },
			string.format("%.2f kg%s", c.kg, c.new and "  ·  NEW!" or (c.record and "  ·  RECORD!" or "")))
		card.Size = UDim2.fromScale(1, 1)
		for _, d in ipairs(card:GetDescendants()) do
			if d:IsA("GuiObject") then
				d.ZIndex += 6
			end
		end
		card.ZIndex = 48
		local sc = mk("UIScale", { Scale = 0.4 }, card)
		TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		headline.Text = M.GRADE_TEXT[f.grade] .. "  " .. f.name
		headline.TextColor3 = M.GRADE_COLOR[f.grade]
		hint.Text = (#catchQueue > 1) and string.format("%d of %d  ·  tap to continue", catchIndex, #catchQueue) or "Tap to continue"
		action.Text = (catchIndex < #catchQueue) and "NEXT" or "DONE"
		action.Visible = true
	end

	-- Input: the action button does what the stage needs.
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
		if stage == "fight" then
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
		hud.Visible = false
		root.Visible = false
	end
	close.MouseButton1Click:Connect(closeAll)

	-- -------------------------------------------------------- messages --
	function ctl.onMessage(msg)
		if type(msg) ~= "table" then
			return
		end
		if msg.kind == "state" then
			data = msg
			data.at = os.clock()
			if not stage then
				root.Visible = true
			end
			paint()
		elseif msg.kind == "cast" then
			startCast()
		elseif msg.kind == "bite" then
			if data and data.state then
				data.state.bait = msg.bait
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
			headline.TextColor3 = T.GOLD
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
				showNextCatch()
			else
				if msg.result == "caught" then
					headline.Text = "The server did not see that catch"
				end
				hint.Text = (msg.count or 1) > 1 and ("All " .. msg.count .. " got away.") or hint.Text
				action.Text = "OK"
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
