-- MineClient: miner-sim HUD, HP hover, swing bar, left-center wallet.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared:WaitForChild("MineConfig"))

--[[
	Which build of src/ is this. First thing in the output window, every Play.

	Twice now a panel has been reported missing when it was in the repo and the
	Studio serving the place was running ReplicatedStorage from before it was
	written. The code was never the problem and the output window never said so.
	Now it does, before anything else has a chance to look broken.

	Guarded both ways: MineBuild going missing is itself the loudest possible
	staleness signal, so its absence warns rather than throwing and taking the
	HUD down with it.
]]
do
	local mb = shared:FindFirstChild("MineBuild")
	if mb then
		local okB, errB = pcall(function()
			require(mb).announce(shared)
		end)
		if not okB then
			warn("[MineBuild] announce failed: " .. tostring(errB))
		end
	else
		warn("[MineBuild] THIS STUDIO IS RUNNING OLDER CODE THAN src/: "
			.. "ReplicatedStorage.Mine.Shared.MineBuild does not exist, and it "
			.. "has been in the repo since the Forge shipped. Run git pull in "
			.. "the clone `rojo serve` is serving, reconnect the Rojo plugin, "
			.. "and Play again.")
	end
end
local Cards = require(shared:WaitForChild("MineCards"))
local Packs = require(shared:WaitForChild("MinePackConfig"))
-- The pets. 43 built species with variants, shinies and chroma -- the mine
-- client was ignoring all of it and drawing its own ball-with-ears instead.
local PetFactory = require(shared:WaitForChild("PetModelFactory"))
-- The pack-open ceremony, ported from TCG Life. Cards do not just appear.
local PackFX = require(shared:WaitForChild("MinePackFX"))
local GradeReveal = require(shared:WaitForChild("MineGradeReveal"))
local Audio = require(shared:WaitForChild("MineAudio"))
local net = RS:WaitForChild("Mine"):WaitForChild("Remotes"):WaitForChild("MineNet")

local snap, digging, hold, pets, aimed = nil, false, 0, {}, nil
local cardSort = "rarity"
local CARD_SORT_OK = {
	rarity = true, equipped = true, qty = true, boosts = true, recent = true,
	set = true, alpha = true, type = true, power = true, variant = true, role = true,
}
local cardSearch = ""

-- One palette, one type pair, shared with every view. See MineTheme for why.
local T = require(shared:WaitForChild("MineTheme"))
local Quests = require(shared:WaitForChild("MineQuests"))
local FONT = T.FONT
local FONT_M = T.FONT_M
local BG = T.PANEL
local BG2 = T.CARD
local GOLD = T.GOLD
local TEXT = T.TEXT
local MUTED = T.MUTED
-- Pickup popups match the wallet pills they fly into.
local COIN_POP = T.GOLD
local GEM_POP = T.GEM

local ICONS = {
	coin = "rbxassetid://102189900236414",
	gem = "rbxassetid://76026876336110",
	stardust = "rbxassetid://92999366083828",
	backpack = "rbxassetid://122765964538534",
	cart = "rbxassetid://91350236877416",
	card = "rbxassetid://116171966355625",
	merge = "rbxassetid://107421662141707",
	-- Pass dock art: reusing the merge arrows until dedicated art lands.
	pass = "rbxassetid://107421662141707",
	dust = "rbxassetid://82545245834050",
	zone = "rbxassetid://125496889420424",
	prestige = "rbxassetid://120888749281068",
	skills = "rbxassetid://77091684955325", -- Jobs dock: job_board_icon.png (transparent)
	enchanter = "rbxassetid://126681136084494", -- purple gold-star book cutout
	events = "rbxassetid://98706782511440", -- transparent party popper (no white plate)
}

local playerGui = player:WaitForChild("PlayerGui")
-- Soft restarts / Studio play-reloads used to stack a second MineUI on top of
-- the first, so dock badges (and anything else pinned to a corner) drew twice.
do
	local stale = playerGui:FindFirstChild("MineUI")
	if stale then
		stale:Destroy()
	end
end
local gui = Instance.new("ScreenGui")
gui.Name = "MineUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 80
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

--[[
	THE HOUSE STYLE, APPLIED TO EVERY PANEL IN THE GAME, FROM ONE LINE.

	Owner, 2026-10-05: "I WANT ALL UIS TO HAVE THAT STYLE".

	Every view in this game mounts into THIS ScreenGui, and each one builds its
	chrome with its own private mk() -- twenty-five of them, each with its own
	padding, radius and idea of whether a surface gets a stroke. MineUI.watch
	walks what they build and normalises the four things that carry the style:
	theme surface colours, one corner radius per size class, the lit hairline,
	and the theme type faces.

	It deliberately refuses to touch anything SATURATED, because a coloured fill
	is carrying meaning -- rarity, a currency, affordable versus blocked -- and
	repainting it would delete information rather than style it. Layout, size and
	position are never touched either; this is paint, not surgery.

	It WATCHES rather than runs once, because panels build lazily: a view creates
	its rows the first time it opens, long after this line runs.

	A panel that genuinely needs to look different sets the NoAdopt attribute on
	itself. That is the escape hatch, and it should stay rare -- "every screen
	invented its own" is the problem MineTheme and MineUI exist to end.
]]
do
	local okUI, UI = pcall(function()
		return require(shared:WaitForChild("MineUI"))
	end)
	if okUI and UI and UI.watch then
		pcall(UI.watch, gui)
	end
end
--[[
	Audio must never be able to stop the client.

	This is line 84 of a 10,000 line script: everything that draws a UI comes
	after it. An unguarded call here means one bad property on one sound
	effect -- which is exactly what happened -- reads to the player as the
	whole game failing to load. The next line was already pcall'd; this one
	was not.
]]
pcall(Audio.startBgm)
pcall(Audio.setZoneResolver, function()
	return snap and snap.zoneId or nil
end)

-- Desktop HUD uses fixed pixel sizes. On phones those dominate the screen;
-- scale the whole MineUI tree down. Trail dashes are world parts, unaffected.
local uiScale = Instance.new("UIScale")
uiScale.Name = "MineUiScale"
uiScale.Scale = 1
uiScale.Parent = gui

--[[
	IT ONLY EVER SCALED DOWN, AND ONLY ON TOUCH.

	Every panel in this game lays out in fixed pixels, so the HUD has one size
	it was drawn for -- roughly an 820px short side. Below that it dominates a
	phone, which is what the touch tiers below fix. ABOVE it, nothing happened:
	on a 2714 x 1026 desktop the scale stayed at 1 and a panel drawn for 820
	occupied two thirds of the height and a third of the width, which reads as a
	debug menu floating in a dark field. Owner, 2026-10-05, comparing the shop
	with a reference screen: "better scaling".

	So the desktop case scales UP toward the same apparent size, against the
	same 820 baseline the layouts were drawn against.

	Capped at 1.45 on purpose. Past that, fixed-width columns inside the panels
	start colliding with their own edges -- the cap is the honest limit of
	pixel layouts, and the real fix for the very largest displays is panels that
	lay out in scale rather than offset.
]]
	-- The baseline and the cap are INSIDE the function on purpose. This script
	-- sits on Luau's ceiling of 200 top-level locals, and hoisting these two out
	-- as constants put it over: the whole client failed to compile with "Out of
	-- local registers when trying to allocate layoutTopbar", so no MineUI
	-- ScreenGui was ever created and every panel in the game vanished at once.
	-- Two names cost the entire UI. Do not add top-level locals to this file.
--[[
	THE UI IS AUTHORED AT 1080p, AND NOTHING MAY GROW PAST THE SCREEN.

	Owner, 2026-10-06: "all the scaling is super fucked up... rescale to a
	comfortable scale".

	It was, and it was mine. The previous line was

	    scale = clamp(short / 820, 0.85, 1.45)

	where `short` is the SHORTER side of the viewport -- which on a landscape
	monitor is its height. So a 1920x1080 desktop scored 1080/820 = x1.32 and a
	1440p one hit the x1.45 cap: every panel in the game was a third larger than
	it was drawn. 820 was never a real baseline, it was a number that made a
	phone look right and quietly inflated everything else.

	Measured on the owner's window (2714x1026) at the old numbers, the group
	wheel came out 1476x1206 inside a 1026-tall viewport -- a panel taller than
	the screen it is drawn on.

	1080 is the real baseline: the tallest fixed panel is 964 and the chrome
	around it needs the rest, so the layout was authored for a 1080-tall screen.
	At 1080 the scale is exactly 1.

	THE FIT GUARD IS THE PART THAT MATTERS. Whatever the branches below decide,
	the tallest panel must still fit with a margin, so the last line clamps
	against the viewport rather than trusting the ladder. Height only: a panel
	wider than a phone is a RESPONSIVE problem for that panel to solve, and
	letting width drive this would crush the whole UI to a third of its size on
	a portrait screen to accommodate one wheel nobody has open.

	PANEL_H is checked by tools/verify/ui-scale.js against the real panels, so a
	panel that outgrows it fails there instead of overflowing in someone's game.
]]
local function refreshMineUiScale()
	local DESIGN, LO, HI, PANEL_H = 1080, 0.80, 1.25, 964
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local short = math.min(v.X, v.Y)
	local scale = 1
	if UIS.TouchEnabled then
		if short < 560 then
			scale = 0.78
		elseif short < 700 then
			scale = 0.88
		elseif short < 900 then
			scale = 0.95
		else
			scale = 1
		end
	else
		scale = math.clamp(short / DESIGN, LO, HI)
	end
	-- The tallest panel, plus a 6% margin, must fit the viewport height.
	local fit = (v.Y * 0.94) / PANEL_H
	uiScale.Scale = math.max(0.5, math.min(scale, fit))
end
refreshMineUiScale()

local function round(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = inst
end

local function stroke(inst, thick)
	local s = Instance.new("UIStroke")
	s.Thickness = thick or 1
	s.Color = GOLD
	s.Transparency = 0.35
	s.Parent = inst
	return s
end

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
	for k, v in pairs(props) do
		o[k] = v
	end
	o.Parent = parent
	return o
end

--[[
	SINGLE-USE HELPERS LIVE IN A TABLE, NOT IN LOCALS.

	Luau allows 200 local registers per function, and this script's top level
	counts as one. It reached about 207 and stopped compiling -- "Out of local
	registers when trying to allocate child" -- which kills the entire client:
	no HUD, no panels, no input. Every `function ClientFns.x` below is called
	from only one or two places. New helpers that are not hot go here too;
	the top level is full.
]]
local ClientFns = {}

-- The candy kit (MineUI), reachable from HUD code without a top-level local.
-- pcall'd like the watch above: a kit error must never kill the client. When
-- it is nil, every caller below falls back to the plain look.
do
	local ok, UI = pcall(function()
		return require(shared:WaitForChild("MineUI"))
	end)
	ClientFns.UI = ok and UI or nil
end

-- Dig deepest mirror (per zone + section). Mineshaft rides never write this.
ClientFns.depthLocal = { zones = {}, sections = {}, liveZoneBest = {}, liveSectionBest = {} }

function ClientFns.noteDepthFromSnapshot(payload)
	if type(payload) ~= "table" then return end
	local d = ClientFns.depthLocal
	if type(payload.deepest) == "table" then
		for zid, layer in pairs(payload.deepest) do
			zid = tostring(zid)
			layer = math.floor(tonumber(layer) or 0)
			if layer > (tonumber(d.zones[zid]) or 0) then d.zones[zid] = layer end
		end
	end
	if type(payload.deepestSection) == "table" then
		for zid, secs in pairs(payload.deepestSection) do
			if type(secs) == "table" then
				zid = tostring(zid)
				d.sections[zid] = d.sections[zid] or {}
				for sid, layer in pairs(secs) do
					sid = tostring(sid)
					layer = math.floor(tonumber(layer) or 0)
					if layer > (tonumber(d.sections[zid][sid]) or 0) then d.sections[zid][sid] = layer end
				end
			end
		end
	end
end

function ClientFns.noteDepthLive(payload)
	if type(payload) ~= "table" then return end
	local d = ClientFns.depthLocal
	local lp = game:GetService("Players").LocalPlayer
	if payload.reset then
		d.liveZoneBest = {}
		d.liveSectionBest = {}
		return
	end
	local zid = tostring(payload.zoneId or "")
	if zid == "" then return end
	if lp and payload.userId == lp.UserId then
		local myLayer = math.floor(tonumber(payload.playerZone) or tonumber(payload.layer) or 0)
		if myLayer > (tonumber(d.zones[zid]) or 0) then d.zones[zid] = myLayer end
		local sid = tostring(payload.sectionId or "")
		if sid ~= "" then
			d.sections[zid] = d.sections[zid] or {}
			local myS = math.floor(tonumber(payload.playerSection) or 0)
			if myS > (tonumber(d.sections[zid][sid]) or 0) then d.sections[zid][sid] = myS end
		end
	end
	if type(payload.zoneBest) == "table" then d.liveZoneBest[zid] = payload.zoneBest end
	if type(payload.sectionBest) == "table" then
		d.liveSectionBest[zid] = d.liveSectionBest[zid] or {}
		local ssid = tostring(payload.sectionBest.sectionId or payload.sectionId or "")
		if ssid ~= "" then d.liveSectionBest[zid][ssid] = payload.sectionBest end
	end
end

function ClientFns.hudIcon(parent, asset, pos, size)
	local wrap = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(8, 10, 14),
		BackgroundTransparency = 0.28,
		Position = pos or UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(size, size),
		BorderSizePixel = 0,
		ZIndex = 22,
		Active = false,
	}, parent)
	round(wrap, math.floor(size * 0.5))
	mk("ImageLabel", {
		BackgroundTransparency = 1,
		Image = asset,
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(0.92, 0.92),
		Position = UDim2.fromScale(0.04, 0.04),
		ZIndex = 23,
		Active = false,
	}, wrap)
	return wrap
end

-- Panel controllers. Declared up here because HUD pieces built further up the
-- file close over them: a local declared below its use site is a nil global to
-- that closure, and the call just silently does nothing.
local skillP, skillCtl, shopCtl, depthShopCtl, elevCtl, invCtl, portalFx, eventsCtl, forgeCtl, groupWheelCtl
local function persistCardSort(id)
	if type(id) ~= "string" or not CARD_SORT_OK[id] then
		return
	end
	cardSort = id
	net:FireServer("setSetting", { key = "cardSort", value = id })
	if invCtl and invCtl.setCardSort then
		invCtl.setCardSort(id)
	end
end
--[[
	The last skill state the server sent, and the function that pushes it into
	the wheel.

	The wheel used to be updated ONLY while it was already open:

	    if skillCtl and skillP and skillP.Visible and payload then

	so a rebirth granted its skill points, the snapshot carried them, and the
	closed wheel never heard about it. Opening it afterwards showed whatever it
	was last told -- which is why a rebirth looked like it awarded nothing.

	It cannot simply be applied on every snapshot either: setOpts calls
	view.refresh(), which redraws the entire wheel, and snapshots arrive up to
	ten times a second while mining. So the state is cached here and pushed in
	when the wheel is actually shown.
]]
local skillLatest, applySkills

-- True while a fullscreen screen is up. Anything that redraws HUD furniture on
-- a snapshot has to check this, or it will undo the hide on the very next tick.
local hudCovered = false
-- Skill wheel only: shop/blacksmith must leave quests trackable (buy-a-pickaxe).
local questsCovered = false

-- Top-left, clear of Roblox's own topbar. It used to sit at mid-Y, which is
-- nowhere any other game puts a wallet and, worse, put it straight through the
-- middle of the two fullscreen panels.
local wallet = mk("Frame", {
	Name = "Wallet",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.fromOffset(10, 72),
	Size = UDim2.fromOffset(400, 56),
	Active = false,
	ZIndex = 20,
}, gui)
local function layoutWallet()
	local k = math.max(0.05, uiScale.Scale)
	local inset = game:GetService("GuiService"):GetGuiInset()
	local top = math.max(56, math.floor((inset.Y + 28) / k))
	local room = gui.AbsoluteSize.X / k
	-- Wide enough for abbreviated big coins (e.g. 110.8M) without crushing the pill.
	local w = math.clamp(room - 16, 300, 600)
	wallet.Position = UDim2.fromOffset(10, top)
	wallet.Size = UDim2.fromOffset(w, 64)
end
layoutWallet()
uiScale:GetPropertyChangedSignal("Scale"):Connect(layoutWallet)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutWallet)
local camWallet = workspace.CurrentCamera
if camWallet then
	camWallet:GetPropertyChangedSignal("ViewportSize"):Connect(layoutWallet)
end
do
	local sh = mk("Frame", {
		Name = "WalletShadow",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.55,
		Position = UDim2.fromOffset(4, 7),
		Size = UDim2.fromScale(1, 1),
		Active = false,
		ZIndex = 18,
		BorderSizePixel = 0,
	}, wallet)
	round(sh, 24)
	-- Soft warm gold halo behind the rim (glow feel without Neon spam).
	local glow = mk("Frame", {
		Name = "WalletGlow",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(-3, -3),
		Size = UDim2.new(1, 6, 1, 6),
		Active = false,
		ZIndex = 19,
		BorderSizePixel = 0,
	}, wallet)
	round(glow, 26)
	local gs = stroke(glow, 5)
	gs.Color = T.ACCENT
	gs.Transparency = 0.7
end
--[[
	Candy pass (2026-10-08): the tray is the theme's deep indigo with a fat dark
	outline, and each currency is a bright candy pill of its own colour. Kids
	track their money before anything else, so the numbers are the biggest text
	on the HUD, and they pop every time they change.
]]
local tray = mk("Frame", {
	BackgroundColor3 = T.PANEL,
	BackgroundTransparency = 0.05,
	Size = UDim2.fromScale(1, 1),
	Active = false,
	ZIndex = 20,
	BorderSizePixel = 0,
}, wallet)
round(tray, 24)
do
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(T.CARD, T.INK)
	grad.Rotation = 90
	grad.Parent = tray
end
stroke(tray, T.STROKE_THICK)
local trayStroke = tray:FindFirstChildOfClass("UIStroke")
if trayStroke then
	trayStroke.Color = T.OUTLINE
	trayStroke.Transparency = 0
end
mk("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, tray)
mk("UIPadding", {
	PaddingLeft = UDim.new(0, 12),
	PaddingRight = UDim.new(0, 12),
	PaddingTop = UDim.new(0, 10),
	PaddingBottom = UDim.new(0, 10),
}, tray)

-- `candy` is a T.CANDY key: the pill's colour IS the currency's colour.
local function walletPill(asset, candy, width, clickable)
	local UI = ClientFns.UI
	local row
	if clickable then
		row = mk("TextButton", {
			AutoButtonColor = false,
			Active = true,
			BackgroundColor3 = Color3.fromRGB(18, 20, 28),
			BackgroundTransparency = 0.12,
			Text = "",
			Size = UDim2.new(0.25, -12, 0, 44),
			BorderSizePixel = 0,
			ZIndex = 21,
		}, tray)
	else
		row = mk("Frame", {
			BackgroundColor3 = Color3.fromRGB(18, 20, 28),
			BackgroundTransparency = 0.12,
			Size = UDim2.new(0.25, -12, 0, 44),
			BorderSizePixel = 0,
			Active = false,
			ZIndex = 21,
		}, tray)
	end
	round(row, 999)
	if UI then
		UI.candy(row, candy, 3)
		local g = row:FindFirstChild("Gloss")
		if g then g.ZIndex = 21 end
		if clickable then UI.juice(row) end
	else
		stroke(row, 1.6)
	end
	-- The icon is a medallion that hangs off the pill's left end, bigger than
	-- the pill, so the currency reads from across the room.
	local ic = ClientFns.hudIcon(row, asset, UDim2.fromOffset(-6, -4), 46)
	ic.BackgroundTransparency = 1
	local lab = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 21,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.fromOffset(42, 0),
		Size = UDim2.new(1, -48, 1, 0),
		Text = "0",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextScaled = false,
		ZIndex = 22,
		Active = false,
	}, row)
	if UI then
		UI.outlineText(lab, 2)
		UI.popNumber(lab)
	end
	return row, lab
end

local _, coinsL = walletPill(ICONS.coin, "gold", 118)
local _, gemsL = walletPill(ICONS.gem, "cyan", 96)
local _, dustL = walletPill(ICONS.stardust, "magenta", 88)
local bagBtn, bagCount = walletPill(ICONS.backpack, "orange", 96, true)
-- A bag reads as "how full am I", not as two numbers you have to divide. The
-- bar sits under the text and turns red the moment the bag stops accepting.
local bagFill
do
	local trackH = 6
	local track = mk("Frame", {
		Name = "BagTrack",
		BackgroundColor3 = T.OUTLINE,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 44, 1, -6),
		Size = UDim2.new(1, -54, 0, trackH),
		ZIndex = 22,
		Active = false,
	}, bagBtn)
	round(track, 3)
	bagFill = mk("Frame", {
		Name = "BagFill",
		BackgroundColor3 = Color3.fromRGB(96, 186, 120),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		ZIndex = 23,
		Active = false,
	}, track)
	round(bagFill, 3)
	-- The number moves up to make room for the bar.
	bagCount.Position = UDim2.fromOffset(42, -4)
	bagCount.TextSize = 17
end

local mineResetL = mk("TextLabel", {
	BackgroundTransparency = 0.05,
	BackgroundColor3 = T.PANEL,
	Font = FONT,
	TextSize = 15,
	TextColor3 = TEXT,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 70),
	Size = UDim2.fromOffset(140, 30),
	Text = "Mine 20:00",
	TextXAlignment = Enum.TextXAlignment.Center,
	-- Under the windows (ZIndex 30): at 40 it sat on top of the inventory's
	-- tabs and close button.
	ZIndex = 19,
}, gui)
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = mineResetL
	local s = Instance.new("UIStroke")
	s.Color = T.OUTLINE
	s.Thickness = 3
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = mineResetL
end
--[[
	First-session guide. Three lines, each cleared by doing the thing it asks.

	Top-centre because that is the only part of the HUD that is free: the wallet
	and zone line own the top-left, the mine timer the top-right, and the panels
	sit lower. It never covers anything a new player needs to click.
]]
local introBanner = mk("Frame", {
	Name = "Intro",
	Visible = false,
	BackgroundColor3 = BG,
	BackgroundTransparency = 0.06,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 70),
	Size = UDim2.fromOffset(520, 46),
	ZIndex = 26,
	Active = false,
}, gui)
round(introBanner, 16)
-- Candy pass: the guide is the one gold-rimmed thing on screen, so a new
-- player's eye lands on it first. Thick rim, lit fill, bigger words.
local introStroke = stroke(introBanner, 3.5)
introStroke.Transparency = 0
do
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(T.CARD_HI, T.PANEL)
	g.Rotation = 90
	g.Parent = introBanner
end
local introDot = mk("Frame", {
	BackgroundColor3 = GOLD,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, 0),
	Size = UDim2.fromOffset(10, 10),
	ZIndex = 27,
	Active = false,
}, introBanner)
round(introDot, 5)
local introL = mk("TextLabel", {
	BackgroundTransparency = 1,
	Font = FONT,
	TextSize = 18,
	TextColor3 = TEXT,
	Text = "",
	Position = UDim2.fromOffset(36, 0),
	Size = UDim2.new(1, -52, 1, 0),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Center,
	TextWrapped = true,
	ZIndex = 27,
	Active = false,
}, introBanner)
local introAckHint = mk("TextLabel", {
	BackgroundTransparency = 1,
	Font = FONT,
	TextSize = 13,
	TextColor3 = GOLD,
	Text = "",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -12, 1, -5),
	Size = UDim2.fromOffset(280, 16),
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 28,
	Active = false,
}, introBanner)
local introBarBack = mk("Frame", {
	Name = "TutBar",
	BackgroundColor3 = T.LINE,
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 36, 1, -8),
	Size = UDim2.new(1, -52, 0, 7),
	Visible = false,
	ZIndex = 28,
}, introBanner)
round(introBarBack, 3)
local introBarFill = mk("Frame", {
	Name = "Fill",
	BackgroundColor3 = GOLD,
	Size = UDim2.fromScale(0, 1),
	ZIndex = 29,
}, introBarBack)
round(introBarFill, 3)
local introClick = mk("TextButton", {
	BackgroundTransparency = 1,
	Text = "",
	Size = UDim2.fromScale(1, 1),
	ZIndex = 29,
	Active = false,
	AutoButtonColor = false,
}, introBanner)
introClick.MouseButton1Click:Connect(function()
	if introClick.Active then
		net:FireServer("introAck")
	end
end)

function ClientFns.fireworks()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	for n = 1, 6 do
		task.delay((n - 1) * 0.16, function()
			local origin = cam.CFrame.Position + cam.CFrame.LookVector * 26
				+ Vector3.new(math.random(-16, 16), math.random(8, 18), math.random(-8, 8))
			local burst = Instance.new("Part")
			burst.Name = "TutorialFirework"
			burst.Anchored = true
			burst.CanCollide = false
			burst.CanQuery = false
			burst.Size = Vector3.new(0.4, 0.4, 0.4)
			burst.Material = Enum.Material.Neon
			burst.Color = Color3.fromHSV(math.random(), 0.8, 1)
			burst.CFrame = CFrame.new(origin)
			burst.Parent = workspace
			local pe = Instance.new("ParticleEmitter")
			pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			pe.Rate = 0
			pe.Lifetime = NumberRange.new(0.55, 1.05)
			pe.Speed = NumberRange.new(16, 30)
			pe.SpreadAngle = Vector2.new(180, 180)
			pe.Color = ColorSequence.new(burst.Color, Color3.new(1, 1, 1))
			pe.LightEmission = 1
			pe.Size = NumberSequence.new(0.55, 0)
			pe.Parent = burst
			pe:Emit(36)
			task.delay(1.3, function()
				if burst.Parent then
					burst:Destroy()
				end
			end)
		end)
	end
end

-- A slow breath on the dot, so the line reads as live rather than as a label
-- someone forgot to delete.
--[[
	THE TRAIL TO THE PIT.

	Spawn is at z=8. The nearest breakable block is at z=150 -- 142 studs, against
	a 26 stud reach. So the first line of the tutorial ("hold the mouse on a
	rock") is a lie for the first several seconds of a new player's life, and
	this file's history records that exact situation reading as "mining is
	broken" twice.

	Wording the line better helped. It did not solve it: the player still has to
	guess WHICH WAY. There is a lobby path running down +Z that an experienced
	eye reads as a road and a new one reads as scenery.

	So: a run of lit dashes along that path, brightening in sequence toward the
	pit, and a beacon at the mouth tall enough to see from the spawn plate. The
	light moves the way you should walk, which is a thing people follow without
	being told to.

	Built on the CLIENT and parented to workspace, so these parts exist only for
	the player being guided -- a veteran never sees them, and no server
	replication is spent on a hint. They are destroyed the moment the intro
	leaves step 1, which is the moment the first block breaks.
]]
local pitTrail = { parts = {}, on = false, token = 0 }

function ClientFns.clearPitTrail()
	pitTrail.token += 1
	for _, p in ipairs(pitTrail.parts) do
		if p and p.Parent then
			p:Destroy()
		end
	end
	table.clear(pitTrail.parts)
	pitTrail.on = false
end

function ClientFns.buildPitTrail(destFn)
	if pitTrail.on then
		return
	end
	pitTrail.on = true
	pitTrail.token += 1
	local myToken = pitTrail.token

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude

	--[[
		Subtle gold crumbs toward the Dirt Meadow pit (intro step 1).
		Ground-laid dashes, not a white brick road.
	]]
	local function meadowDest()
		return ClientFns.pitWaypointPos()
	end

	-- destFn: a waypoint (ClientFns.setWaypoint); the pit rim otherwise.
	local destOf = destFn or meadowDest
	local DEST = destOf() or meadowDest()
	local WHITE = Color3.fromRGB(214, 176, 72)
	local onTouch = UIS.TouchEnabled
	-- Slim dashes. Mobile stays a touch thicker for readability, not huge.
	local DASH_LEN = onTouch and 2.4 or 2.0
	local GAP = onTouch and 3.2 or 2.8
	local STEP = DASH_LEN + GAP
	local DASH_COUNT = onTouch and 22 or 28
	local TICK = onTouch and 0.1 or 0.06
	local GROUND_LIFT = onTouch and 0.2 or 0.14
	local START_AHEAD = onTouch and 3.0 or 2.4
	local dashes = {}
	for _ = 1, DASH_COUNT do
		local dash = mk("Part", {
			Name = "PitTrailDash",
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			CastShadow = false,
			Material = Enum.Material.Neon,
			Color = WHITE,
			Transparency = 1,
			Size = onTouch and Vector3.new(0.28, 0.08, DASH_LEN) or Vector3.new(0.22, 0.07, DASH_LEN),
			CFrame = CFrame.new(0, -200, 0),
		}, workspace)
		table.insert(pitTrail.parts, dash)
		table.insert(dashes, dash)
	end

	local beacon = mk("Part", {
		Name = "PitTrailBeacon",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Material = Enum.Material.Neon,
		Color = WHITE,
		Transparency = 0.82,
		-- Shorter column on phones - a 42-stud neon tower blooms into a blob.
		Size = onTouch and Vector3.new(1.6, 16, 1.6) or Vector3.new(2.0, 28, 2.0),
		CFrame = CFrame.new(DEST.X, DEST.Y + (onTouch and 9 or 16), DEST.Z),
	}, workspace)
	table.insert(pitTrail.parts, beacon)

	local filter = {}
	local groundCache = {}
	local cacheFrame = 0

	task.spawn(function()
		local t = 0
		while pitTrail.token == myToken and pitTrail.on do
			t += TICK
			cacheFrame += 1
			DEST = destOf() or DEST
			local beaconLift = onTouch and 9 or 16
			if beacon.Parent then
				beacon.CFrame = CFrame.new(DEST.X, DEST.Y + beaconLift, DEST.Z)
			end

			local char = player.Character
			local root = char and (
				char:FindFirstChild("HumanoidRootPart")
					or char:FindFirstChild("UpperTorso")
					or char:FindFirstChild("Torso")
			)
			local start = root and root.Position or Vector3.new(0, 6, 8)
			local flatTo = Vector3.new(DEST.X - start.X, 0, DEST.Z - start.Z)
			local dist = flatTo.Magnitude
			local dir = dist > 0.05 and flatTo.Unit or Vector3.new(0, 0, 1)
			-- Start ahead of the body on the ground - never clipped through torso.
			local origin = Vector3.new(start.X, start.Y, start.Z) + dir * START_AHEAD

			table.clear(filter)
			if char then
				table.insert(filter, char)
			end
			for _, p in ipairs(pitTrail.parts) do
				table.insert(filter, p)
			end
			rp.FilterDescendantsInstances = filter

			local cycle = onTouch and 2.6 or 2.2
			local fill = math.clamp((t % cycle) / (cycle * 0.72), 0, 1)

			local half = DASH_LEN * 0.5
			local firstAlong = half
			local usable = math.max(0, dist - START_AHEAD)
			local visible = 0
			if usable > DASH_LEN + 2 then
				visible = math.clamp(
					math.floor((usable - firstAlong - half) / STEP) + 1,
					0,
					#dashes
				)
			end
			-- Refresh ground heights every other tick (mobile) / every tick (desktop).
			local refreshGround = (not onTouch) or (cacheFrame % 2 == 0)

			for i, dash in ipairs(dashes) do
				if dash.Parent then
					if i > visible then
						if dash.Transparency < 1 then
							dash.Transparency = 1
							dash.CFrame = CFrame.new(0, -200, 0)
						end
					else
						local along = firstAlong + (i - 1) * STEP
						local pos = origin + dir * along
						local groundY = groundCache[i]
						if refreshGround or not groundY then
							local hit = workspace:Raycast(
								Vector3.new(pos.X, 80, pos.Z), Vector3.new(0, -200, 0), rp
							)
							groundY = (hit and hit.Position.Y or DEST.Y) + GROUND_LIFT
							groundCache[i] = groundY
						end
						local at = Vector3.new(pos.X, groundY, pos.Z)
						dash.CFrame = CFrame.lookAt(at, at + dir)

						local u = along / math.max(usable, 1)
						local ahead = u - fill
						local lit
						if ahead <= 0 then
							lit = 0.9
						elseif ahead < 0.08 then
							lit = 1 - ahead / 0.08
						else
							lit = 0.15
						end
						-- Less transparency thrash on mobile (no per-dash sine).
						dash.Transparency = 0.48 + (1 - lit) * 0.38
					end
				end
			end
			if beacon.Parent then
				if dist < 22 then
					beacon.Transparency = 1
				else
					beacon.Transparency = onTouch
						and (0.78 - math.abs(math.sin(t * 0.7)) * 0.1)
						or (0.86 - math.abs(math.sin(t * 0.9)) * 0.16)
				end
			end
			task.wait(TICK)
		end
	end)
end

local introPulseTween
function ClientFns.introPulse()
	if introPulseTween then
		return
	end
	introPulseTween = TweenService:Create(
		introDot,
		TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ BackgroundTransparency = 0.65 }
	)
	introPulseTween:Play()
end

--[[
	Daily reward card.

	Shown on join when today's claim is outstanding, dismissible, and gone the
	moment it is claimed. Deliberately a card and not a modal: it does not eat
	input, so a player who wants to go straight to mining just walks off and
	closes it later.
]]
local dailyHud = {}
dailyHud.card = mk("Frame", {
	Name = "Daily",
	Visible = false,
	BackgroundColor3 = BG,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.46),
	Size = UDim2.fromOffset(420, 250),
	ZIndex = 25,
	Active = true,
}, gui)
round(dailyHud.card, 16)
do
	local s = stroke(dailyHud.card, 2)
	s.Transparency = 0.1
end
dailyHud.title = mk("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 22, TextColor3 = GOLD,
	Text = "DAILY REWARD", Position = UDim2.fromOffset(0, 18),
	Size = UDim2.new(1, 0, 0, 26), ZIndex = 26, Active = false,
}, dailyHud.card)
dailyHud.title.TextXAlignment = Enum.TextXAlignment.Center
dailyHud.day = mk("TextLabel", {
	BackgroundTransparency = 1, Font = FONT_M, TextSize = 13, TextColor3 = MUTED,
	Text = "", Position = UDim2.fromOffset(0, 46),
	Size = UDim2.new(1, 0, 0, 18), ZIndex = 26, Active = false,
}, dailyHud.card)
dailyHud.day.TextXAlignment = Enum.TextXAlignment.Center
dailyHud.prize = mk("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 24, TextColor3 = TEXT,
	Text = "", Position = UDim2.fromOffset(20, 96),
	Size = UDim2.new(1, -40, 0, 34), ZIndex = 26, Active = false,
}, dailyHud.card)
dailyHud.prize.TextXAlignment = Enum.TextXAlignment.Center
dailyHud.prize.TextScaled = false
dailyHud.streak = mk("TextLabel", {
	BackgroundTransparency = 1, Font = FONT_M, TextSize = 12, TextColor3 = MUTED,
	Text = "", Position = UDim2.fromOffset(0, 136),
	Size = UDim2.new(1, 0, 0, 16), ZIndex = 26, Active = false,
}, dailyHud.card)
dailyHud.streak.TextXAlignment = Enum.TextXAlignment.Center
dailyHud.claim = mk("TextButton", {
	AutoButtonColor = true, BackgroundColor3 = GOLD, Font = FONT, TextSize = 18,
	TextColor3 = T.ON_GOLD, Text = "CLAIM",
	Position = UDim2.fromOffset(24, 178), Size = UDim2.new(1, -48, 0, 44), ZIndex = 26,
}, dailyHud.card)
round(dailyHud.claim, 10)
dailyHud.close = mk("TextButton", {
	AutoButtonColor = true, BackgroundTransparency = 1, Font = FONT, TextSize = 18,
	TextColor3 = MUTED, Text = "X",
	Position = UDim2.new(1, -40, 0, 12), Size = UDim2.fromOffset(28, 28), ZIndex = 27,
}, dailyHud.card)

-- Dismissed for this session only; an unclaimed day comes back on the next join.
dailyHud.dismissed = false
dailyHud.close.MouseButton1Click:Connect(function()
	dailyHud.dismissed = true
	dailyHud.card.Visible = false
end)
dailyHud.claim.MouseButton1Click:Connect(function()
	dailyHud.claim.Active = false
	dailyHud.claim.Text = "..."
	dailyHud.dismissed = true
	dailyHud.card.Visible = false
	net:FireServer("claimDaily")
end)

-- Clicking the card's body (not CLAIM, not X) opens the Daily screen, so the
-- three quests behind it are one click away rather than undiscoverable.
dailyHud.open = mk("TextButton", {
	BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 0, 88),
	Position = UDim2.fromOffset(0, 0), ZIndex = 25,
}, dailyHud.card)
dailyHud.open.MouseButton1Click:Connect(function()
	if invCtl then
		dailyHud.card.Visible = false
		invCtl.open("daily", "daily")
	end
end)

function dailyHud.show(state)
	if questsCovered or type(state) ~= "table" or not state.ready or dailyHud.dismissed then
		dailyHud.card.Visible = false
		return
	end
	dailyHud.day.Text = "Day " .. tostring(state.day) .. " of " .. tostring(state.days)
	dailyHud.prize.Text = tostring(state.text)
	dailyHud.streak.Text = (state.streak or 0) > 0
		and (tostring(state.streak) .. " day streak - miss a day and it starts over")
		or "Come back tomorrow to build a streak"
	dailyHud.claim.Active = true
	dailyHud.claim.Text = "CLAIM"
	dailyHud.card.Visible = true
	ClientFns.paintDailyCalendar(state)
end

--[[
	Day-4 surprise: Like + Favorite → random 2★+ pack.
]]
local dailySurprise = {}
dailySurprise.liked = false
dailySurprise.favorited = false
dailySurprise.root = mk("Frame", {
	Name = "DailySurprise",
	Visible = false,
	BackgroundColor3 = BG,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.48),
	Size = UDim2.fromOffset(440, 280),
	ZIndex = 40,
	Active = true,
}, gui)
round(dailySurprise.root, 16)
stroke(dailySurprise.root, 2)
mk("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 22, TextColor3 = GOLD,
	Text = "SURPRISE PACK", Position = UDim2.fromOffset(0, 16),
	Size = UDim2.new(1, 0, 0, 28), ZIndex = 41,
}, dailySurprise.root).TextXAlignment = Enum.TextXAlignment.Center
mk("TextLabel", {
	BackgroundTransparency = 1, Font = FONT_M, TextSize = 14, TextColor3 = TEXT,
	Text = "Like & Favorite the game for a random 2★+ pack",
	Position = UDim2.fromOffset(20, 52), Size = UDim2.new(1, -40, 0, 40),
	TextWrapped = true, ZIndex = 41,
}, dailySurprise.root).TextXAlignment = Enum.TextXAlignment.Center
dailySurprise.status = mk("TextLabel", {
	BackgroundTransparency = 1, Font = FONT_M, TextSize = 13, TextColor3 = MUTED,
	Text = "Tap both below, then claim",
	Position = UDim2.fromOffset(20, 100), Size = UDim2.new(1, -40, 0, 20),
	ZIndex = 41,
}, dailySurprise.root)
dailySurprise.status.TextXAlignment = Enum.TextXAlignment.Center
dailySurprise.likeBtn = mk("TextButton", {
	AutoButtonColor = true, BackgroundColor3 = Color3.fromRGB(60, 140, 255),
	Font = FONT, TextSize = 16, TextColor3 = Color3.new(1, 1, 1), Text = "LIKE",
	Position = UDim2.fromOffset(24, 136), Size = UDim2.fromOffset(186, 44), ZIndex = 42,
}, dailySurprise.root)
round(dailySurprise.likeBtn, 10)
dailySurprise.favBtn = mk("TextButton", {
	AutoButtonColor = true, BackgroundColor3 = Color3.fromRGB(255, 170, 60),
	Font = FONT, TextSize = 16, TextColor3 = Color3.fromRGB(30, 20, 10), Text = "FAVORITE",
	Position = UDim2.fromOffset(230, 136), Size = UDim2.fromOffset(186, 44), ZIndex = 42,
}, dailySurprise.root)
round(dailySurprise.favBtn, 10)
dailySurprise.claimBtn = mk("TextButton", {
	AutoButtonColor = true, BackgroundColor3 = GOLD,
	Font = FONT, TextSize = 18, TextColor3 = T.ON_GOLD, Text = "CLAIM SURPRISE",
	Position = UDim2.fromOffset(24, 198), Size = UDim2.new(1, -48, 0, 48), ZIndex = 42,
}, dailySurprise.root)
round(dailySurprise.claimBtn, 10)
dailySurprise.close = mk("TextButton", {
	AutoButtonColor = true, BackgroundTransparency = 1, Font = FONT, TextSize = 18,
	TextColor3 = MUTED, Text = "X",
	Position = UDim2.new(1, -40, 0, 12), Size = UDim2.fromOffset(28, 28), ZIndex = 43,
}, dailySurprise.root)

local function refreshSurpriseClaim()
	local ready = dailySurprise.liked and dailySurprise.favorited
	dailySurprise.claimBtn.AutoButtonColor = ready
	dailySurprise.claimBtn.BackgroundColor3 = ready and GOLD or Color3.fromRGB(50, 50, 58)
	dailySurprise.claimBtn.TextColor3 = ready and (T.ON_GOLD or Color3.fromRGB(30, 20, 10)) or MUTED
	if ready then
		dailySurprise.status.Text = "Ready — claim your surprise pack"
		dailySurprise.status.TextColor3 = Color3.fromRGB(120, 255, 160)
	else
		local bits = {}
		if not dailySurprise.liked then bits[#bits + 1] = "Like" end
		if not dailySurprise.favorited then bits[#bits + 1] = "Favorite" end
		dailySurprise.status.Text = "Still need: " .. table.concat(bits, " + ")
		dailySurprise.status.TextColor3 = MUTED
	end
end

function dailySurprise.open()
	dailySurprise.liked = false
	dailySurprise.favorited = false
	dailySurprise.likeBtn.Text = "LIKE"
	dailySurprise.favBtn.Text = "FAVORITE"
	dailySurprise.claimBtn.Text = "CLAIM SURPRISE"
	dailySurprise.claimBtn.Active = true
	refreshSurpriseClaim()
	dailySurprise.root.Visible = true
end

function dailySurprise.closePanel()
	dailySurprise.root.Visible = false
end

dailySurprise.close.MouseButton1Click:Connect(dailySurprise.closePanel)
dailySurprise.likeBtn.MouseButton1Click:Connect(function()
	pcall(function()
		GuiService:OpenBrowserWindow("https://www.roblox.com/games/" .. tostring(game.PlaceId))
	end)
	dailySurprise.liked = true
	dailySurprise.likeBtn.Text = "LIKED ✓"
	refreshSurpriseClaim()
end)
dailySurprise.favBtn.MouseButton1Click:Connect(function()
	local ok = pcall(function()
		AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
	end)
	-- Prefer a real favorite when the API answers; otherwise honor the prompt.
	task.delay(0.4, function()
		local favOk, isFav = pcall(function()
			return AvatarEditorService:GetFavorite(game.PlaceId, Enum.AvatarItemType.Asset)
		end)
		if favOk and isFav == true then
			dailySurprise.favorited = true
		elseif ok then
			dailySurprise.favorited = true
		end
		if dailySurprise.favorited then
			dailySurprise.favBtn.Text = "FAVORITED ✓"
		end
		refreshSurpriseClaim()
	end)
end)
dailySurprise.claimBtn.MouseButton1Click:Connect(function()
	if not (dailySurprise.liked and dailySurprise.favorited) then
		dailySurprise.status.Text = "Like and Favorite first"
		dailySurprise.status.TextColor3 = Color3.fromRGB(255, 120, 120)
		return
	end
	dailySurprise.claimBtn.Active = false
	dailySurprise.claimBtn.Text = "..."
	net:FireServer("claimDailySurprise")
end)

--[[
	Quest tracker.

	Sits under the wallet, because the left column is where a player already
	looks for "how am I doing". One objective at a time and a bar: the whole
	point is that there is always a next thing and it is never more than a
	glance away. When it is finished the bar is replaced by the claim button,
	so "done" and "not done" cannot be confused at a distance.
]]
--[[
	ONE QUEST PANEL. Owner, 2026-10-08: "fix the quests and the ugly arrow to
	push the quests out of the way (make it all a part of the same exact ui)".

	The active quest and today's dailies used to be two separate cards, each
	with an "ear" tab hanging off its right edge that slid the pair off screen.
	Now there is one panel (QuestPanel) with one outline, one background and
	one header. The collapse button lives IN that header, and collapsing shrinks
	the panel into a small "QUESTS" pill in place. It no longer slides out of
	sight, so there is nothing hanging off its edge.

	questBox and the daily box are still their own frames, because everything
	that paints them works unchanged. They are just transparent now, and
	stacked inside the panel by ClientFns.layoutQuestPanel. The panel clips, so
	collapsing is only a size change.
]]
local questBox = mk("Frame", {
	Name = "Quest",
	Visible = false,
	BackgroundColor3 = T.PANEL,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.fromOffset(304, 126),
	ZIndex = 20,
	Active = false,
}, gui)
do
	local HEADER = 40
	ClientFns.QUEST_HEADER = HEADER
	local panel = mk("Frame", {
		Name = "QuestPanel",
		Visible = false,
		BackgroundColor3 = T.PANEL,
		BackgroundTransparency = 0.04,
		Position = UDim2.new(0, 16, 0, 300),
		Size = UDim2.fromOffset(304, HEADER),
		ClipsDescendants = true,
		ZIndex = 20,
		Active = false,
	}, gui)
	round(panel, 20)
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(T.CARD, T.INK)
	grad.Rotation = 90
	grad.Parent = panel
	local s = stroke(panel, T.STROKE_THICK)
	s.Color = T.OUTLINE
	s.Transparency = 0
	panel:SetAttribute("MineUIAdopted", true)
	-- The whole header is the toggle, so a thumb cannot miss it.
	local header = mk("TextButton", {
		Name = "Header", BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, HEADER), ZIndex = 24,
	}, panel)
	local title = mk("TextLabel", {
		Name = "Title", BackgroundTransparency = 1, Font = FONT, TextSize = 19, TextColor3 = GOLD,
		Text = "QUESTS", TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(16, 0), Size = UDim2.fromOffset(80, HEADER), ZIndex = 25, Active = false,
	}, panel)
	-- Green dot: something in here pays out right now. Pulses, open or shut.
	local dot = mk("Frame", {
		Name = "ClaimDot", BackgroundColor3 = T.GREEN, Visible = false,
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 96, 0, HEADER / 2),
		Size = UDim2.fromOffset(14, 14), ZIndex = 25, Active = false,
	}, panel)
	round(dot, 7)
	do
		local ds = stroke(dot, 2)
		ds.Color = T.OUTLINE
		ds.Transparency = 0
	end
	local toggle = mk("TextButton", {
		Name = "Toggle", AutoButtonColor = false, Text = "-", Font = FONT, TextSize = 24,
		TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = T.CARD_HI,
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0, HEADER / 2),
		Size = UDim2.fromOffset(30, 28), ZIndex = 26,
	}, panel)
	round(toggle, 9)
	if ClientFns.UI then
		ClientFns.UI.candy(toggle, "purple", 2.5)
		ClientFns.UI.outlineText(toggle, 1.5)
		ClientFns.UI.juice(toggle, 1.12)
	end
	-- A hairline under the header, so the open panel reads as title + body.
	mk("Frame", {
		Name = "HeaderRule", BackgroundColor3 = T.LINE, BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 0, HEADER - 1), Size = UDim2.new(1, -24, 0, 2),
		ZIndex = 21, Active = false,
	}, panel)
	header.MouseButton1Click:Connect(function()
		ClientFns.questDrawerToggle(true)
	end)
	toggle.MouseButton1Click:Connect(function()
		ClientFns.questDrawerToggle(true)
	end)
	questBox.Parent = panel
	questBox.Position = UDim2.fromOffset(0, HEADER)
	ClientFns.questPanel = panel
	ClientFns.questPanelParts = { title = title, dot = dot, toggle = toggle }
end
do
	mk("TextLabel", {
		Name = "RewardHint",
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 15,
		TextColor3 = GOLD,
		Text = "",
		Position = UDim2.fromOffset(18, 68),
		Size = UDim2.new(1, -36, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 21,
		Active = false,
	}, questBox)
	mk("TextLabel", {
		Name = "QuestTip",
		BackgroundTransparency = 1,
		Font = FONT_M,
		TextSize = 13,
		TextColor3 = T.MUTED,
		Text = "",
		Position = UDim2.fromOffset(18, 88),
		Size = UDim2.new(1, -36, 0, 32),
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 21,
		Active = false,
	}, questBox)
end
-- Bold objective + progress index; thick gold bar; muted-gold reward hint.
local questIdx = mk("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 14,
	TextColor3 = T.MUTED,
	Text = "", Position = UDim2.new(1, -78, 0, 11), Size = UDim2.fromOffset(66, 18),
	TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 21, Active = false,
}, questBox)
local questText = mk("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 20,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Text = "", Position = UDim2.fromOffset(18, 8), Size = UDim2.new(1, -100, 0, 26),
	TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21, Active = false,
}, questBox)
questText.TextTruncate = Enum.TextTruncate.AtEnd
-- A fat, outlined bar with a candy-green fill and a shine: a bar that looks
-- nearly full feels winnable, and that is what pulls the next swing.
local questTrack = mk("Frame", {
	BackgroundColor3 = T.LINE, BorderSizePixel = 0,
	Position = UDim2.fromOffset(18, 40), Size = UDim2.new(1, -96, 0, 20),
	ZIndex = 21, Active = false,
}, questBox)
round(questTrack, 10)
do
	local ts = stroke(questTrack, 2.5)
	ts.Color = T.OUTLINE
	ts.Transparency = 0
end
local questFill = mk("Frame", {
	BackgroundColor3 = T.GREEN, BorderSizePixel = 0,
	Size = UDim2.fromScale(0, 1), ZIndex = 22, Active = false,
}, questTrack)
round(questFill, 10)
if ClientFns.UI then
	ClientFns.UI.candy(questFill, "green", 0)
	local fs = questFill:FindFirstChildOfClass("UIStroke")
	if fs then fs.Enabled = false end
	local g = questFill:FindFirstChild("Gloss")
	if g then g.ZIndex = 23 end
end
-- Crisp progress count to the right of the bar.
local questProg = mk("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 17,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Text = "", Position = UDim2.new(1, -74, 0, 39), Size = UDim2.fromOffset(60, 22),
	TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 21, Active = false,
}, questBox)
if ClientFns.UI then
	ClientFns.UI.outlineText(questProg, 2)
	ClientFns.UI.popNumber(questProg, 1.12)
end
local questClaim = mk("TextButton", {
	Visible = false, AutoButtonColor = false, BackgroundColor3 = T.GREEN,
	Font = FONT, TextSize = 18, TextColor3 = Color3.fromRGB(255, 255, 255), Text = "CLAIM",
	Position = UDim2.fromOffset(18, 40), Size = UDim2.new(1, -36, 0, 38), ZIndex = 22,
}, questBox)
round(questClaim, 14)
if ClientFns.UI then
	ClientFns.UI.candy(questClaim, "green", 3)
	ClientFns.UI.outlineText(questClaim, 2)
	ClientFns.UI.juice(questClaim)
	-- The gloss is a child, so it would draw over the button's own Text. Push
	-- it under by giving it the button's ZIndex and keeping it faint.
	local g = questClaim:FindFirstChild("Gloss")
	if g then g.Visible = false end
end
questClaim.MouseButton1Click:Connect(function()
	questClaim.Active = false
	questClaim.Text = "..."
	net:FireServer("claimQuest")
end)

-- Phone HUD: quest tracker defaults to a tiny pill so it cannot cover dig /
-- dock / shop. Expand on tap. Major panels slide the quest drawers closed
-- (tabs stay on the left edge) instead of destroying the cards.
function ClientFns.questIsPhone()
	if not UIS.TouchEnabled then
		return false
	end
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
	return math.min(v.X, v.Y) < 700
end

-- The quest panel's open/collapsed state (active quest + daily quests).
-- preferred = user intent when no modal; peeking = temporary expand over a modal.
--[[
	OPEN OR COLLAPSED, NEVER SLID AWAY.

	This used to slide both cards off the left edge and leave an "ear" tab
	behind to pull them back. Owner, 2026-10-08: "fix the quests and the ugly
	arrow ... make it all a part of the same exact ui". Now the ears are gone.
	The state below drives one thing, the QuestPanel's size: full when open,
	a "QUESTS" pill when collapsed. The pill is the same frame and has the same
	header button, so the way back is always the thing you can see.

	A phone starts collapsed, so the panel stays off the thumbstick until it is
	asked for. A modal still collapses it (see the QUEST_HIDERS wiring) and the
	pill stays on top so the player can peek.
]]
function ClientFns.questDrawerEnsure()
	if ClientFns.questDrawerReady then
		return
	end
	if ClientFns.questDrawerPreferred == nil then
		ClientFns.questDrawerPreferred = not ClientFns.questIsPhone()
	end
	if ClientFns.questDrawerOpen == nil then
		ClientFns.questDrawerOpen = ClientFns.questDrawerPreferred
	end
	ClientFns.questDrawerPeeking = false
	ClientFns.questDrawerRestX = ClientFns.questDrawerRestX or 16
	ClientFns.questDrawerReady = true
end

function ClientFns.questDrawerToggle(fromUser)
	ClientFns.questDrawerEnsure()
	local want = not (ClientFns.questDrawerOpen == true)
	if fromUser then
		if questsCovered then
			ClientFns.questDrawerPeeking = want
		else
			ClientFns.questDrawerPreferred = want
			ClientFns.questDrawerPeeking = false
		end
	end
	ClientFns.setQuestDrawerOpen(want)
end

function ClientFns.syncQuestDrawer()
	ClientFns.questDrawerEnsure()
	local want
	if questsCovered then
		want = ClientFns.questDrawerPeeking == true
	else
		ClientFns.questDrawerPeeking = false
		want = ClientFns.questDrawerPreferred ~= false
	end
	ClientFns.setQuestDrawerOpen(want)
end

-- Header state: the toggle glyph, and the claim dot. Kept under its old name
-- because every paint path already calls it.
function ClientFns.refreshQuestDrawerTabs()
	ClientFns.questDrawerEnsure()
	local parts = ClientFns.questPanelParts
	if not parts then
		return
	end
	local open = ClientFns.questDrawerOpen ~= false
	parts.toggle.Text = open and "-" or "+"
	local claimable = ClientFns.dailyClaimable == true
		or (snap ~= nil and type(snap.quest) == "table" and snap.quest.ready == true and not snap.quest.done)
	if parts.dot.Visible ~= claimable then
		parts.dot.Visible = claimable
		if ClientFns.questDotPulseStop then
			ClientFns.questDotPulseStop()
			ClientFns.questDotPulseStop = nil
		end
		if claimable and ClientFns.UI then
			ClientFns.UI.pop(parts.dot, 1.6)
			ClientFns.questDotPulseStop = ClientFns.UI.pulse(parts.dot, 1.25, 0.8)
		end
	end
end

--[[
	Stack the quest card and the daily card inside the panel, and size the panel
	to them: full when open, a pill when collapsed. Runs on every paint (about
	ten a second while digging), so it only starts a tween when the target size
	actually changes.
]]
function ClientFns.layoutQuestPanel(instant)
	local panel = ClientFns.questPanel
	if not panel then
		return
	end
	ClientFns.questDrawerEnsure()
	local H = ClientFns.QUEST_HEADER or 40
	local d = ClientFns.dailyBox
	local qVis = questBox.Visible
	local dVis = d ~= nil and d.Visible
	local y = H
	local wide = 0
	if qVis then
		questBox.Position = UDim2.fromOffset(0, y)
		y += questBox.Size.Y.Offset
		wide = math.max(wide, questBox.Size.X.Offset)
	end
	if d then
		d.Position = UDim2.fromOffset(0, y)
		local rule = d:FindFirstChild("Divider")
		if rule then
			rule.Visible = qVis
		end
		if dVis then
			y += d.Size.Y.Offset
			wide = math.max(wide, d.Size.X.Offset)
		end
	end
	if wide < 80 then
		wide = ClientFns.questIsPhone() and 260 or 304
	end
	panel.Visible = qVis or dVis
	panel.Position = UDim2.new(0, ClientFns.questDrawerRestX or 16, 0, ClientFns.questPanelY or 300)
	local open = ClientFns.questDrawerOpen ~= false
	local goal = open and UDim2.fromOffset(wide, y + 6) or UDim2.fromOffset(150, H)
	if ClientFns.questPanelGoal ~= goal then
		ClientFns.questPanelGoal = goal
		local prev = ClientFns.questPanelTween
		if prev then
			pcall(function() prev:Cancel() end)
			ClientFns.questPanelTween = nil
		end
		if instant or not panel.Visible then
			panel.Size = goal
		else
			local tw = TweenService:Create(panel,
				TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = goal })
			ClientFns.questPanelTween = tw
			tw:Play()
		end
	end
	ClientFns.refreshQuestDrawerTabs()
end

function ClientFns.applyQuestDrawerPos(instant)
	ClientFns.layoutQuestPanel(instant)
end

function ClientFns.setQuestDrawerOpen(open, instant)
	ClientFns.questDrawerEnsure()
	open = open and true or false
	local changed = ClientFns.questDrawerOpen ~= open
	ClientFns.questDrawerOpen = open
	ClientFns.applyQuestDrawerPos(instant or not changed)
end

function ClientFns.ensureQuestChrome()
	if ClientFns.questChrome then
		return ClientFns.questChrome
	end
	if ClientFns.questFolded == nil then
		ClientFns.questFolded = ClientFns.questIsPhone()
	end
	local chrome = {}
	chrome.tap = mk("TextButton", {
		Name = "QuestPillTap",
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 28,
		Visible = false,
	}, questBox)
	chrome.label = mk("TextLabel", {
		Name = "QuestPillLabel",
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 220, 140),
		Text = "Quest",
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -28, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 29,
		Visible = false,
		Active = false,
	}, questBox)
	chrome.dot = mk("Frame", {
		Name = "QuestClaimDot",
		BackgroundColor3 = Color3.fromRGB(80, 220, 120),
		Size = UDim2.fromOffset(10, 10),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		ZIndex = 30,
		Visible = false,
		Active = false,
	}, questBox)
	round(chrome.dot, 5)
	chrome.collapse = mk("TextButton", {
		Name = "QuestCollapse",
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 18,
		TextColor3 = MUTED,
		Text = "-",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -4, 0, 2),
		Size = UDim2.fromOffset(28, 26),
		ZIndex = 28,
		Visible = false,
	}, questBox)
	chrome.tap.MouseButton1Click:Connect(function()
		if not ClientFns.questFolded then
			return
		end
		ClientFns.questFolded = false
		if snap then
			ClientFns.showQuest(snap.quest)
			pcall(ClientFns.paintDailyBox, snap.dailyQuests)
		end
	end)
	chrome.collapse.MouseButton1Click:Connect(function()
		ClientFns.questFolded = true
		if snap then
			ClientFns.showQuest(snap.quest)
			pcall(ClientFns.paintDailyBox, snap.dailyQuests)
		end
	end)
	ClientFns.questChrome = chrome
	ClientFns.questDrawerEnsure()
	return chrome
end

function ClientFns.showQuest(state)
	if type(state) ~= "table" or state.done then
		questBox.Visible = false
		ClientFns.placeDailyBox()
		ClientFns.refreshQuestDrawerTabs()
		return
	end
	local chrome = ClientFns.ensureQuestChrome()
	local phone = ClientFns.questIsPhone()
	if not phone then
		ClientFns.questFolded = false
	end
	-- The phone "Quest" pill is retired: collapsing is the QuestPanel's job now
	-- (one control for every device), so the card itself never folds.
	local folded = false
	questBox.Visible = true
	questBox.Active = false
	-- The QuestPanel around it does the clipping (that is how it collapses).
	questBox.ClipsDescendants = false
	-- "5 / 16" only; the word QUEST does not fit the compact row and the bar
	-- under a named objective already reads as a quest.
	questIdx.Text = tostring(state.index) .. " / " .. tostring(state.total)
	questText.Text = tostring(state.text)
	local goal = math.max(state.goal or 1, 1)
	local cur = math.clamp(state.current or 0, 0, goal)
	local rewardHint = questBox:FindFirstChild("RewardHint")
	local questTip = questBox:FindFirstChild("QuestTip")
	local accent = questBox:FindFirstChild("Accent")
	local tip = (type(state.tip) == "string" and state.tip ~= "") and state.tip or nil
	local claimable = state.ready == true or ClientFns.dailyClaimable == true
	if folded then
		questBox.Size = UDim2.fromOffset(112, 34)
		questIdx.Visible = false
		questText.Visible = false
		questTrack.Visible = false
		questProg.Visible = false
		questClaim.Visible = false
		if rewardHint then rewardHint.Visible = false end
		if questTip then questTip.Visible = false end
		if accent then accent.Visible = false end
		local sh = questBox:FindFirstChild("QuestShadow")
		local glow = questBox:FindFirstChild("QuestGlow")
		if sh then sh.Visible = false end
		if glow then glow.Visible = false end
		chrome.label.Visible = true
		chrome.label.Text = state.ready and "Claim!" or "Quest"
		chrome.tap.Visible = true
		chrome.collapse.Visible = false
		chrome.dot.Visible = claimable
		if ClientFns.dailyBox then
			ClientFns.dailyBox.Visible = false
		end
		ClientFns.placeDailyBox()
		ClientFns.syncQuestDrawer()
		return
	end
	chrome.label.Visible = false
	chrome.tap.Visible = false
	chrome.dot.Visible = false
	chrome.collapse.Visible = false
	questIdx.Visible = true
	questText.Visible = true
	local sh = questBox:FindFirstChild("QuestShadow")
	local glow = questBox:FindFirstChild("QuestGlow")
	if sh then sh.Visible = true end
	if glow then glow.Visible = true end
	if accent then accent.Visible = true end
	if questTip then
		questTip.Text = tip or ""
		questTip.Visible = tip ~= nil and not state.ready and not phone
	end
	local wide = phone and 260 or 304
	local tall = (tip and not state.ready and not phone) and 126 or 96
	questBox.Size = UDim2.fromOffset(wide, tall)
	if state.ready then
		questTrack.Visible = false
		questProg.Visible = false
		if rewardHint then
			rewardHint.Visible = false
		end
		local was = questClaim.Visible
		questClaim.Visible = true
		questClaim.Active = true
		questClaim.Text = "CLAIM  " .. tostring(state.reward) .. "!"
		questClaim.TextSize = (#tostring(state.reward) > 16) and 14 or 18
		-- Something to claim always throbs: it is the one thing on the HUD that
		-- pays out right now, so it should be the one thing that moves.
		if not was and ClientFns.UI then
			ClientFns.UI.pop(questClaim, 1.2)
			if ClientFns.questClaimPulseStop then ClientFns.questClaimPulseStop() end
			ClientFns.questClaimPulseStop = ClientFns.UI.pulse(questClaim, 1.06, 0.9)
		end
	else
		if ClientFns.questClaimPulseStop then
			ClientFns.questClaimPulseStop()
			ClientFns.questClaimPulseStop = nil
		end
		questClaim.Visible = false
		questTrack.Visible = true
		questProg.Visible = true
		questFill.Size = UDim2.fromScale(cur / goal, 1)
		questProg.Text = Quests.short(cur) .. "/" .. Quests.short(goal)
		if rewardHint then
			rewardHint.Visible = true
			rewardHint.Text = "Reward: " .. tostring(state.reward)
			rewardHint.TextColor3 = GOLD
		end
	end
	ClientFns.placeDailyBox()
	ClientFns.syncQuestDrawer()
end

--[[
	TODAY'S THREE, on the left under the quest card: each daily with its
	progress, its gems and a CLAIM button when it is done, and how long until
	they reset. Tap the header to fold it; on a short phone screen it starts
	folded so it stays off the thumbstick.
]]
function ClientFns.dailyBoxBuild()
	if ClientFns.dailyBox then
		return ClientFns.dailyBox
	end
	-- Lives inside the QuestPanel (see questBox): transparent, no chrome of its
	-- own, with a hairline on top dividing it from the active quest above.
	local box = mk("Frame", {
		Name = "DailyQuests", Visible = false, BackgroundColor3 = T.PANEL,
		BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.fromOffset(304, 178),
		ZIndex = 20, Active = false,
	}, ClientFns.questPanel or gui)
	box:SetAttribute("MineUIAdopted", true)
	mk("Frame", {
		Name = "Divider", BackgroundColor3 = T.LINE, BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -24, 0, 2),
		ZIndex = 21, Active = false,
	}, box)
	local header = mk("TextButton", {
		BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 34), ZIndex = 22,
	}, box)
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT, TextSize = 17, TextColor3 = T.GEM,
		Text = "DAILY QUESTS", TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(16, 7), Size = UDim2.new(0.5, 0, 0, 22), ZIndex = 22, Active = false,
	}, header)
	local info = mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT_M, TextSize = 13, TextColor3 = MUTED, Text = "",
		TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 10), Size = UDim2.new(0.55, 0, 0, 18), ZIndex = 22, Active = false,
	}, header)
	local rows = {}
	for i = 1, 3 do
		local r = mk("Frame", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 34 + (i - 1) * 46),
			Size = UDim2.new(1, -28, 0, 44), ZIndex = 21, Active = false,
		}, box)
		local text = mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 15, TextColor3 = TEXT, Text = "",
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			Size = UDim2.new(1, -74, 0, 20), ZIndex = 22, Active = false,
		}, r)
		local gems = mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = T.GEM, Text = "",
			TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 1), Size = UDim2.fromOffset(74, 18), ZIndex = 22, Active = false,
		}, r)
		local track = mk("Frame", {
			BackgroundColor3 = T.LINE, Position = UDim2.fromOffset(0, 24),
			Size = UDim2.new(1, -74, 0, 13), ZIndex = 22, Active = false,
		}, r)
		round(track, 7)
		do
			local ts = stroke(track, 2)
			ts.Color = T.OUTLINE
			ts.Transparency = 0
		end
		local fill = mk("Frame", {
			BackgroundColor3 = T.GEM, Size = UDim2.fromScale(0, 1), ZIndex = 23, Active = false,
		}, track)
		round(fill, 7)
		local count = mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = TEXT, Text = "",
			TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 21), Size = UDim2.fromOffset(68, 18), ZIndex = 22, Active = false,
		}, r)
		local claim = mk("TextButton", {
			Visible = false, AutoButtonColor = false, BackgroundColor3 = T.GREEN, Font = FONT, TextSize = 14,
			TextColor3 = Color3.fromRGB(255, 255, 255), Text = "CLAIM", AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 18), Size = UDim2.fromOffset(70, 26), ZIndex = 24,
		}, r)
		round(claim, 9)
		if ClientFns.UI then
			ClientFns.UI.candy(claim, "green", 2.5, false)
			ClientFns.UI.outlineText(claim, 1.5)
			ClientFns.UI.juice(claim)
		end
		claim.MouseButton1Click:Connect(function()
			if claim.Active then
				claim.Active = false
				claim.Text = "..."
				net:FireServer("claimDailyQuest", { index = i })
			end
		end)
		rows[i] = { frame = r, text = text, gems = gems, track = track, fill = fill, count = count, claim = claim }
	end
	-- Any touch device: start folded so daily rows never cover dig / dock.
	ClientFns.dailyFolded = UIS.TouchEnabled and true or false
	header.MouseButton1Click:Connect(function()
		ClientFns.dailyFolded = not ClientFns.dailyFolded
		ClientFns.paintDailyBox(snap and snap.dailyQuests)
	end)
	ClientFns.dailyBoxParts = { info = info, rows = rows }
	ClientFns.dailyBox = box
	ClientFns.questDrawerEnsure()
	return box
end

function ClientFns.paintDailyBox(list)
	local box = ClientFns.dailyBoxBuild()
	local parts = ClientFns.dailyBoxParts
	ClientFns.dailyClaimable = false
	if type(list) == "table" then
		for _, q in ipairs(list) do
			if q.ready and not q.claimed then
				ClientFns.dailyClaimable = true
				break
			end
		end
	end
	if type(list) ~= "table" or #list == 0 then
		box.Visible = false
		ClientFns.refreshQuestDrawerTabs()
		return
	end
	local done = 0
	for _, q in ipairs(list) do
		if q.claimed then
			done += 1
		end
	end
	local left = 86400 - (os.time() % 86400)
	parts.info.Text = string.format("%d/%d  |  resets %dh %02dm%s", done, #list,
		math.floor(left / 3600), math.floor(left % 3600 / 60), ClientFns.dailyFolded and "  +" or "")
	for i, r in ipairs(parts.rows) do
		local q = list[i]
		r.frame.Visible = (q ~= nil) and not ClientFns.dailyFolded
		if q then
			local goal = math.max(1, tonumber(q.goal) or 1)
			local cur = math.clamp(tonumber(q.current) or 0, 0, goal)
			r.text.Text = tostring(q.text)
			r.text.TextColor3 = q.claimed and MUTED or TEXT
			r.gems.Text = q.claimed and "DONE" or ("+" .. tostring(q.reward or ""))
			r.gems.TextColor3 = q.claimed and T.GREEN or T.GEM
			r.fill.Size = UDim2.fromScale(cur / goal, 1)
			r.fill.BackgroundColor3 = q.claimed and T.GREEN or T.GEM
			r.count.Text = Quests.short(cur) .. "/" .. Quests.short(goal)
			r.count.Visible = not q.ready
			r.claim.Visible = q.ready and not q.claimed
			if r.claim.Visible and r.claim.Text ~= "..." then
				r.claim.Active = true
				r.claim.Text = "CLAIM"
			elseif not r.claim.Visible then
				r.claim.Text = "CLAIM"
			end
		end
	end
	box.Size = UDim2.fromOffset((ClientFns.questIsPhone() and 260) or 304, ClientFns.dailyFolded and 34 or (34 + #list * 46 + 6))
	box.Visible = true
	box.ClipsDescendants = false
	ClientFns.placeDailyBox()
	ClientFns.syncQuestDrawer()
end

-- Right under the quest card, or in its place when the ladder is finished.
function ClientFns.placeDailyBox()
	-- Both cards live in the QuestPanel now; it stacks and sizes them.
	ClientFns.layoutQuestPanel()
end

--[[
	Depth, and the way out.

	Both live under the mine timer on the right, because "how deep am I" and
	"get me out of here" are the same thought. The surface button only exists
	while you are actually underground -- at the top it would be a button that
	does nothing, which is worse than no button.

	Depth is the deepest voxel this player actually BROKE in the zone (pets,
	blast, echo, zap included). Character Y used to drive the chip and always
	read one layer shallow because hip height sits above the floor.
]]
--[[
	WARNING: this script is at Luau's ceiling of 200 top-level locals. Anything
	new added out here has to be a FIELD on an existing table, not another
	`local`. One more loose local and the whole client fails to load.
]]
local depthHud = {}
depthHud.chip = mk("Frame", {
	Name = "Depth",
	Visible = false,
	BackgroundColor3 = BG,
	BackgroundTransparency = 0.06,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 104),
	Size = UDim2.fromOffset(140, 36),
	ZIndex = 20,
	Active = false,
}, gui)
round(depthHud.chip, 12)
do
	local s = stroke(depthHud.chip, 3)
	s.Color = T.OUTLINE
	s.Transparency = 0
end
depthHud.label = mk("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 18, TextColor3 = TEXT,
	Size = UDim2.fromScale(1, 1), Text = "0m", ZIndex = 21, Active = false,
}, depthHud.chip)
if ClientFns.UI then
	ClientFns.UI.outlineText(depthHud.label, 2)
end

--[[
	REBIRTH PROGRESS, ON SCREEN.

	The rebirth ladder only existed INSIDE the rebirth panel, so the single
	longest-running goal in the game was invisible unless you went looking for
	it. A run had no sense of "nearly there".

	Always on, under the depth chip, showing the bar for the very next rebirth
	only -- the panel still carries the five-deep ladder for anyone who opens
	it. Everything hangs off depthHud (a table) rather than new locals: this
	file is on the Luau 200 top-level register ceiling with zero headroom.
]]
depthHud.rb = mk("Frame", {
	Name = "RebirthProgress",
	Visible = false,
	BackgroundColor3 = BG,
	BackgroundTransparency = 0.06,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 146),
	Size = UDim2.fromOffset(140, 46),
	ZIndex = 20,
	Active = false,
}, gui)
round(depthHud.rb, 12)
do
	local s = stroke(depthHud.rb, 3)
	s.Color = T.OUTLINE
	s.Transparency = 0
end
depthHud.rbLabel = mk("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = GOLD,
	Position = UDim2.fromOffset(9, 4), Size = UDim2.new(1, -18, 0, 17),
	Text = "REBIRTH 1", TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 21, Active = false,
}, depthHud.rb)
depthHud.rbPct = mk("TextLabel", {
	BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = MUTED,
	Position = UDim2.fromOffset(9, 4), Size = UDim2.new(1, -18, 0, 17),
	Text = "0%", TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 21, Active = false,
}, depthHud.rb)
depthHud.rbTrack = mk("Frame", {
	BackgroundColor3 = T.LINE, BorderSizePixel = 0,
	Position = UDim2.fromOffset(9, 25), Size = UDim2.new(1, -18, 0, 13),
	ZIndex = 21, Active = false,
}, depthHud.rb)
round(depthHud.rbTrack, 7)
do
	local s = stroke(depthHud.rbTrack, 2)
	s.Color = T.OUTLINE
	s.Transparency = 0
end
depthHud.rbFill = mk("Frame", {
	BackgroundColor3 = GOLD, BorderSizePixel = 0,
	Size = UDim2.fromScale(0, 1), ZIndex = 22, Active = false,
}, depthHud.rbTrack)
round(depthHud.rbFill, 7)
if ClientFns.UI then
	ClientFns.UI.candyTint(depthHud.rbFill, 0)
	ClientFns.UI.outlineText(depthHud.rbLabel, 1.5)
	depthHud.rbLabel.TextColor3 = GOLD
end

--[[
	THE BIG BUTTON.

	Bottom centre, 280x68, because that is where a thumb is and this is the one
	control a player uses mid-dig. It carries whichever action is actually next:

	  carrying a haul   -> SELL      (VIP sells here; everyone else walks to the depot)
	  underground, empty -> TO SURFACE
	  otherwise          -> hidden

	One button, never two, and it never shows an action that would do nothing.
]]
depthHud.button = mk("TextButton", {
	Name = "BigAction",
	Visible = false,
	AutoButtonColor = false,
	BackgroundColor3 = GOLD,
	Font = FONT,
	TextSize = 24,
	TextColor3 = T.ON_GOLD,
	Text = "TO SURFACE",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -120),
	Size = UDim2.fromOffset(280, 68),
	ZIndex = 22,
}, gui)
round(depthHud.button, 20)
if ClientFns.UI then
	-- Candy tint: the hue stays in BackgroundColor3 (SELL green / SURFACE gold).
	ClientFns.UI.candyTint(depthHud.button, T.STROKE_THICK)
	ClientFns.UI.outlineText(depthHud.button, 2.5)
	ClientFns.UI.juice(depthHud.button)
end
depthHud.mode = "surface"
depthHud.button.MouseButton1Click:Connect(function()
	if depthHud.mode == "sell" then
		-- Server: VIP sells in place. Everyone else is walked to the depot.
		net:FireServer("sell")
	else
		net:FireServer("returnSurface")
	end
end)

-- Deepest broken layer in this zone. Never character Y.
function depthHud.inPit()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not snap then
		return false
	end
	local zone = C.zoneById(snap.zoneId) or C.ZONES[1]
	local origin = C.zoneOrigin(zone)
	if not origin then
		return false
	end
	return root.Position.Y < (origin.Y - 1)
end

function depthHud.depthOf()
	if not snap then
		return 0
	end
	local zid = tostring(snap.zoneId or "")
	local live = 0
	local d = ClientFns.depthLocal
	if d and d.zones then
		live = tonumber(d.zones[zid]) or 0
	end
	local saved = 0
	if type(snap.deepest) == "table" then
		saved = tonumber(snap.deepest[zid]) or tonumber(snap.deepest[snap.zoneId]) or 0
	end
	return math.max(0, math.floor(math.max(live, saved)))
end

local mineResetLeft = nil
local mineResetSec = C.MINE_RESET_SEC or 1200
local function fmtReset(sec)
	sec = math.max(0, math.floor(sec or 0))
	return string.format("Mine %d:%02d", math.floor(sec / 60), sec % 60)
end

local presL = mk("TextLabel", {
	BackgroundTransparency = 1,
	Font = FONT_M,
	TextSize = 13,
	TextColor3 = GOLD,
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.new(0, 22, 0, 68),
	Size = UDim2.fromOffset(196, 20),
	Text = "R0  Dirt Meadow",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextStrokeTransparency = 1,
	TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
	Active = false,
}, gui)

-- Candy pass: a chunky outlined bubble with bold text that pops in when shown.
local toast = mk("TextLabel", {
	Visible = false,
	BackgroundColor3 = BG,
	BackgroundTransparency = 0.04,
	Font = FONT,
	TextSize = 18,
	TextColor3 = TEXT,
	Position = UDim2.new(0.5, -190, 0, 20 + GuiService:GetGuiInset().Y),
	Size = UDim2.fromOffset(380, 44),
	TextWrapped = true,
	Text = "",
}, gui)
round(toast, 16)
do
	local s = stroke(toast, 3)
	s.Color = T.OUTLINE
	s.Transparency = 0
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(T.CARD_HI, T.PANEL)
	g.Rotation = 90
	g.Parent = toast
end

-- World Pulse banner (module - MineClient is at the Luau local register cap).
require(shared:WaitForChild("MineWorldPulseUI")).install(gui, GuiService, BG, FONT_M, TEXT, round, stroke)

-- Big numbers are the point; they just have to stay readable. Declared up
-- here because the merge panel and the popups all call it, and a local
-- declared further down is a nil global to everything above it.
-- Defined above haulPopup, which calls it. It used to sit below, so the
-- popup threw on its first line of text -- after the coin icon was already
-- on screen and before anything scheduled its cleanup. That is the coin
-- that sat in the middle of the screen and would not go away.
-- Big numbers are the point; they just have to stay readable.
local function shortNum(n)
	local ok, Ab = pcall(function()
		return require(game.ReplicatedStorage.Mine.Shared:WaitForChild("MineAbbrev"))
	end)
	-- currency, not format: four significant figures and floored, so a wallet
	-- never rounds up and tells a player they can afford something they cannot.
	if ok and Ab and Ab.currency then
		return Ab.currency(n)
	end
	return tostring(math.floor(tonumber(n) or 0))
end

-- Drill spin-up, along the bottom of the screen. A toast saying "Spinning up..."
-- told you nothing about how much longer, and it fired again on every reset.
local spinBar = mk("Frame", {
	Name = "SpinUp", Visible = false, AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -84), Size = UDim2.fromOffset(420, 16),
	BackgroundColor3 = T.LINE, ZIndex = 20,
}, gui)
round(spinBar, 9)
do
	local s = stroke(spinBar, 3)
	s.Color = T.OUTLINE
	s.Transparency = 0
	spinBar.Size = UDim2.fromOffset(420, 22)
end
local spinFill = mk("Frame", {
	Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD,
	ZIndex = 21,
}, spinBar)
round(spinFill, 9)
if ClientFns.UI then
	ClientFns.UI.candyTint(spinFill, 0)
end
local spinText = mk("TextLabel", {
	BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = FONT,
	TextSize = 15, TextColor3 = Color3.fromRGB(255, 255, 255),
	Text = "SPINNING UP", ZIndex = 22,
}, spinBar)
if ClientFns.UI then
	ClientFns.UI.outlineText(spinText, 2)
end

local spinUntil, spinFor = 0, 1
function ClientFns.showSpin(dur)
	spinFor = math.max(tonumber(dur) or 1, 0.05)
	spinUntil = os.clock() + spinFor
	spinBar.Visible = true
end

-- Last time the breaking-power refusal was shown, so a held swing cannot spam it.

local function showToast(t)
	toast.Text = t
	toast.Visible = true
	if ClientFns.UI then
		ClientFns.UI.pop(toast, 1.12)
	end
	task.delay(2.4, function()
		if toast.Text == t then
			toast.Visible = false
		end
	end)
end

require(shared.MineWorldPulseUI).setToast(showToast)
require(shared.MineWorldPulseUI).hookRender(RunService)

local function btn(parent, text, pos, size, fn)
	local b = mk("TextButton", {
		AutoButtonColor = true,
		Active = true,
		BackgroundColor3 = BG2,
		Font = FONT,
		TextColor3 = TEXT,
		TextSize = 14,
		Text = text,
		Position = pos,
		Size = size,
		ZIndex = (parent.ZIndex or 1) + 2,
	}, parent)
	round(b)
	stroke(b)
	if ClientFns.UI then
		ClientFns.UI.juice(b)
	end
	b.MouseButton1Click:Connect(fn)
	return b
end

-- Right-edge dock so it does not sit on Roblox's hotbar.
local dock = mk("Frame", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -18, 0.5, 0),
	Size = UDim2.fromOffset(72, 720),
}, gui)
mk("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	Padding = UDim.new(0, 6),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
}, dock)

local panels = {}
-- Every panel is authored as a percentage of the screen. That reads fine on a
-- laptop and turns into a 3,200px slab of empty background on a wide monitor:
-- a grid of 150px tiles floating in the middle of nothing, which is most of why
-- the UI looks unfinished. Scale still handles small screens; the cap stops a
-- window growing past the point where its own content can fill it.
local function capPanel(f, maxX, maxY)
	if not f then
		return
	end
	local c = f:FindFirstChildOfClass("UISizeConstraint")
	if not c then
		c = Instance.new("UISizeConstraint")
		c.Parent = f
	end
	c.MaxSize = Vector2.new(maxX or 1180, maxY or 820)
	-- Touch viewports are short: a 520x380 floor overflows a phone once the
	-- UIScale maths cancels out on Scale-sized panels. Let phones go smaller.
	c.MinSize = UIS.TouchEnabled and Vector2.new(320, 240) or Vector2.new(520, 380)
	return c
end

local function panel(name)
	local f = mk("Frame", {
		Name = name,
		Visible = false,
		Active = true,
		BackgroundColor3 = BG,
		BackgroundTransparency = 0.04,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.92, 0.88),
		ZIndex = 30,
		BorderSizePixel = 0,
	}, gui)
	round(f, 18)
	--[[
		Candy pass (2026-10-08): every window built here gets the same chunky
		chrome. A fat dark outline, a violet header band, a big outlined title,
		a big red close button, and a springy pop each time it opens.
	]]
	do
		local s = stroke(f, T.STROKE_THICK)
		s.Color = T.OUTLINE
		s.Transparency = 0
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Color = ColorSequence.new(T.CARD, T.INK)
		g.Parent = f
		-- The band is a rounded bar plus a square filler under its lower half,
		-- both with the same sideways gradient, so it reads as one shape with
		-- rounded top corners and a flat bottom.
		local function band(pos, size, r)
			local b = mk("Frame", {
				Name = "HeaderBand", BackgroundColor3 = Color3.new(1, 1, 1),
				Position = pos, Size = size, ZIndex = 30, Active = false,
			}, f)
			if r then
				round(b, r)
			end
			local bg = Instance.new("UIGradient")
			bg.Color = ColorSequence.new(T.ACCENT_DIM, T.CARD_HI)
			bg.Parent = b
			b:SetAttribute("MineUIAdopted", true)
		end
		band(UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 50), 18)
		band(UDim2.fromOffset(0, 25), UDim2.new(1, 0, 0, 25))
		f:GetPropertyChangedSignal("Visible"):Connect(function()
			if f.Visible and ClientFns.UI then
				ClientFns.UI.pop(f, 0.9)
			end
		end)
	end
	local titleL = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 26,
		Text = string.upper(name),
		Size = UDim2.new(1, -72, 0, 40),
		Position = UDim2.fromOffset(18, 5),
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 31,
		Active = false,
	}, f)
	if ClientFns.UI then
		ClientFns.UI.outlineText(titleL, 2.5)
	end
	do
		local close = mk("TextButton", {
			Name = "Close", AutoButtonColor = false, Text = "X", Font = FONT, TextSize = 24,
			TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = T.RED,
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 5),
			Size = UDim2.fromOffset(40, 40), ZIndex = 33,
		}, f)
		round(close, 12)
		if ClientFns.UI then
			ClientFns.UI.candy(close, "red", 3)
			ClientFns.UI.outlineText(close, 2)
			ClientFns.UI.juice(close, 1.12)
		end
		close.MouseButton1Click:Connect(function()
			f.Visible = false
		end)
	end
	local body = mk("ScrollingFrame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 52),
		Size = UDim2.new(1, -32, 1, -68),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 31,
	}, f)
	-- SortOrder must be explicit. Left at the default this sorted by NAME -
	-- Frames before TextButtons before TextLabels - which is why the Rebirth
	-- screen's section headers sank under its rows. LayoutOrder ties keep
	-- insertion order, so panels that never set it are unchanged.
	mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, body)
	panels[name] = f
	return f
end

local binderP = panel("Cards")
binderP.Size = UDim2.fromScale(0.94, 0.92)
binderP.Position = UDim2.fromScale(0.5, 0.56)
binderP.ClipsDescendants = false
binderP.Body.Position = UDim2.fromOffset(16, 112)
binderP.Body.Size = UDim2.new(1, -32, 1, -128)
local shopP = panel("Shop")
local bagP = panel("Backpack")
local mergeP = panel("Merge")
mergeP.Size = UDim2.fromScale(0.94, 0.92)
mergeP.Position = UDim2.fromScale(0.5, 0.56)
-- The pass signature fuse (Lunar + Eclipse) used to live here on the Merge
-- screen; that screen is retired, so the button rides the Pass header now
-- (MineInventoryView.renderPass, opts.onFusePassTools).
local dustP = panel("Dust")
do
	local title = dustP:FindFirstChildWhichIsA("TextLabel")
	if title then
		title.Text = "SCRAPPER"
	end
	-- Room at the bottom for the action bar, which sits outside the scroll so
	-- the totals stay on screen while you pick things.
	dustP.Body.Size = UDim2.new(1, -32, 1, -140)
end
-- What is currently ticked, and which tab is showing. One table rather than two
-- locals: this file is near the 200 top-level local ceiling.
local scrapUI = { sel = {}, tab = "cards" }
local enchantP = panel("Enchanter")
enchantP.Size = UDim2.fromScale(0.94, 0.92)
if enchantP.Body then
	enchantP.Body.Visible = false
end
local runesCtl
local tradeP = panel("Trade")
local zoneP = panel("Planets")
local presP = panel("Rebirth")
-- Forward-declared: dock buttons sit above the refresh bodies, and the PERF
-- snapshot path only redraws panels that are already Visible. Without these
-- upvalues the Zones / Rebirth docks opened empty shells - no Buy row at all.
local refreshZones, refreshPrestige

local RETIRED = { Cards = true, Backpack = true, Shop = true, Trade = true }
for name in pairs(RETIRED) do
	local f = panels[name]
	if f then
		f.Visible = false
		panels[name] = nil
	end
end

local SORTS = {
	{ id = "rarity", label = "Rarity" },
	{ id = "equipped", label = "Team" },
	{ id = "qty", label = "Qty" },
	{ id = "boosts", label = "Boosts" },
	{ id = "recent", label = "New" },
	{ id = "set", label = "Set" },
	{ id = "alpha", label = "A-Z" },
	{ id = "type", label = "Type" },
	{ id = "role", label = "Role" },
	{ id = "power", label = "Power" },
	{ id = "variant", label = "Var" },
}
-- A search box and ONE row of sort chips. Two rows of chips ate a third of the
-- panel and pushed the cards themselves off the bottom.
local searchBox = mk("TextBox", {
	Name = "Search",
	BackgroundColor3 = BG2,
	Position = UDim2.fromOffset(16, 46),
	Size = UDim2.new(1, -32, 0, 28),
	Font = FONT_M,
	TextSize = 14,
	TextColor3 = TEXT,
	PlaceholderText = "Search name, set, type, rarity...",
	PlaceholderColor3 = MUTED,
	Text = "",
	ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Left,
}, binderP)
round(searchBox, 8)
stroke(searchBox, 1)
do
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.Parent = searchBox
end

local sortBar = mk("Frame", {
	Name = "SortBar",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 80),
	Size = UDim2.new(1, -32, 0, 26),
}, binderP)
mk("UIGridLayout", {
	CellPadding = UDim2.fromOffset(4, 4),
	CellSize = UDim2.fromOffset(60, 26),
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Top,
}, sortBar)
local sortChips = {}
local refreshBinder
function ClientFns.paintSortChips()
	for id, chip in pairs(sortChips) do
		local on = id == cardSort
		chip.BackgroundColor3 = on and GOLD or BG2
		chip.TextColor3 = on and Color3.fromRGB(22, 18, 12) or TEXT
	end
end

local function hidePanels()
	for _, f in pairs(panels) do
		f.Visible = false
	end
	if invCtl then
		invCtl.close()
	end
	if forgeCtl then
		forgeCtl.close()
	end
	if eventsCtl then
		eventsCtl.close()
	end
	if groupWheelCtl then
		groupWheelCtl.close()
	end
	if shopCtl and shopCtl.close then
		shopCtl.close()
	end
	if depthShopCtl and depthShopCtl.close then
		depthShopCtl.close()
	end
	if elevCtl and elevCtl.close then
		elevCtl.close()
	end
	if depthHud.contractor and depthHud.contractor.root then
		depthHud.contractor.close()
	end
end

local function togglePanel(p)
	local on = not p.Visible
	hidePanels()
	p.Visible = on
end

local function dockBtn(asset, label, open, opts)
	opts = opts or {}
	-- Real square plate (56×56) + caption. UIAspectRatioConstraint stops stretch.
	local b = mk("TextButton", {
		AutoButtonColor = false,
		Active = true,
		BackgroundTransparency = 1,
		Text = "",
		Size = UDim2.fromOffset(72, 78),
	}, dock)
	local plate = mk("Frame", {
		Name = "Plate",
		BackgroundColor3 = Color3.fromRGB(16, 16, 18),
		BackgroundTransparency = opts.clearPlate and 1 or 0.08,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(56, 56),
		Active = false,
		ClipsDescendants = true,
	}, b)
	round(plate, 14)
	--[[
		Candy pass (2026-10-08): every dock button is its own colour, so a kid
		finds "the gold one" (Shop) or "the blue one" (Inventory) without reading.
		Colour is per caption; anything unlisted is violet.
	]]
	local candyKey = opts.candy or ({
		Shop = "gold", Inventory = "blue", Trade = "green", Pass = "purple",
		Enchanter = "magenta", Planets = "cyan", Events = "orange", Jobs = "red",
	})[label] or "purple"
	if ClientFns.UI and not opts.clearPlate then
		ClientFns.UI.candy(plate, candyKey, 3)
		ClientFns.UI.juice(b, 1.1)
	elseif not opts.clearPlate then
		stroke(plate, 1.5)
	end
	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = 1
	ar.DominantAxis = Enum.DominantAxis.Width
	ar.Parent = plate
	mk("ImageLabel", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = asset,
		ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(40, 40),
		Active = false,
	}, plate)
	local cap = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 15,
		TextColor3 = TEXT,
		Text = label,
		Position = UDim2.fromOffset(0, 56),
		Size = UDim2.new(1, 0, 0, 22),
		Active = false,
	}, b)
	if ClientFns.UI then
		ClientFns.UI.outlineText(cap, 2)
	end
	b.MouseButton1Click:Connect(open)
	return b, plate
end

--[[
	UPGRADES WAITING IN THE BAG (MineServer Dig.planUpgrades).

	A red count on the Inventory button whenever you own gear or pets that beat
	what you are wearing. That is all it does now: the EQUIP BEST button used to
	live out here on the dock, which told you something was waiting without
	telling you where. It is in the two places the decision actually happens --
	beside your pets in the Cards tab, and in the Equipment header, whose tab
	also carries a red dot while there is better gear in the bag.
]]
function ClientFns.upgradeNudge()
	-- Dock inventory count is owned by MineNotifs (NotifBadge). A second
	-- UpgradeBadge used to stack on top of it and cover the icon / neighbor.
	-- Scrub any leftovers from older sessions; packs + upgrades feed Notifs now.
	local btn = ClientFns.invDockBtn
	if not btn or not btn.Parent then
		btn = nil
		for _, b in ipairs(dock:GetChildren()) do
			local l = b:IsA("GuiButton") and b:FindFirstChildWhichIsA("TextLabel")
			if l and l.Text == "Inventory" then
				btn = b
				break
			end
		end
		ClientFns.invDockBtn = btn
	end
	if not btn then
		return
	end
	local function scrub(host)
		if not host then
			return
		end
		for _, c in ipairs(host:GetChildren()) do
			if c.Name == "EquipBestNudge" or c.Name == "UpgradeBadge" then
				c:Destroy()
			end
		end
	end
	scrub(btn)
	scrub(btn:FindFirstChild("Plate"))
	ClientFns.upgradeShown = 0
end

--[[
	WHERE A RUNE GOES, in one function, because two screens ask the question now:
	the Enchanter, and the Runes tab in your bag. Socketing is not a purchase, so
	it does not belong behind a walk to a machine -- buying still does.
]]
function ClientFns.socketRoute(item, runeId, index)
	if type(item) ~= "table" then
		return
	end
	if item.kind == "gear" then
		net:FireServer("socketGearRune", { gearId = item.id, runeId = runeId, index = index })
	elseif item.kind == "pet" then
		net:FireServer("socketPetRune", { cardId = item.id, runeId = runeId })
	elseif item.kind == "chest" then
		net:FireServer("socketToolRune", { runeId = runeId, chestId = item.id, family = item.family })
	elseif item.kind == "shop" then
		net:FireServer("socketToolRune", { runeId = runeId, shopToolId = item.id, family = item.family })
	else
		net:FireServer("socketToolRune", {
			runeId = runeId, family = item.family,
			slot = (index == 1) and "main" or "omni",
		})
	end
end

function ClientFns.onSurface()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
	return flat.Magnitude <= (C.CAMP_RADIUS or 52)
end

dockBtn(ICONS.cart, "Shop", function()
	-- Takes you TO the shop rather than opening one wherever you stand. The
	-- counter is the gate: you cannot browse tools from the bottom of a shaft,
	-- and getting there costs you your position in the mine.
	if shopCtl and shopCtl.root.Visible then
		shopCtl.close()
		return
	end
	hidePanels()
	net:FireServer("goTo", "shop")
end)
--[[
	THE DAILY WHEEL (owner, 2026-10-10: "we need that daily wheel working").
	A dock button, second from the top, because a daily reward nobody can find
	is not a daily reward. Its badge counts the free spins left (MineNotifs).
	The emoji stands in until the art pass draws a wheel icon.
]]
do
	local _, plate = dockBtn("", "Wheel", function()
		if not groupWheelCtl then
			return
		end
		if groupWheelCtl.isOpen and groupWheelCtl.isOpen() then
			groupWheelCtl.close()
			return
		end
		hidePanels()
		groupWheelCtl.open(snap and snap.groupWheel or nil)
	end, { candy = "gold" })
	mk("TextLabel", {
		Name = "WheelIcon",
		BackgroundTransparency = 1,
		Text = "🎡",
		TextSize = 30,
		Font = Enum.Font.GothamMedium,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(38, 38),
		Active = false,
	}, plate)
end
dockBtn(ICONS.card, "Inventory", function()
	-- Replaces the Binder button. The binder is still in there, as
	-- Inventory > Cards.
	if invCtl then
		if invCtl.root.Visible then
			invCtl.close()
		else
			hidePanels()
			-- Snapshots only used to refresh while open, so the first open
			-- showed an empty pet list until the next dig. Feed current snap.
			if snap then
				invCtl.setState(snap)
			end
			-- Opens on Equipment every time, whatever tab it was left on.
			invCtl.open("inventory", "tools")
		end
	end
end)
-- Trading. The picker opens from here; invites and the trade window itself
-- arrive as server events (tradeInvite / tradeSync) -- see ClientFns.tradeView.
dockBtn(ICONS.merge, "Trade", function()
	ClientFns.tradeView().openPicker()
end)
-- The battle pass earned the dock slot merge used to hold: merging lives in
-- Inventory > Cards now (three copies of a card show a MERGE button), while
-- the pass is a destination players check every session.
dockBtn(ICONS.pass, "Pass", function()
	if invCtl then
		if invCtl.root.Visible then
			invCtl.close()
		else
			hidePanels()
			if snap then
				invCtl.setState(snap)
			end
			invCtl.open("pass", "pass")
		end
	end
end)
dockBtn(ICONS.enchanter, "Enchanter", function()
	ClientFns.routePanel("enchanter", "runes")
end)
--[[
	Planets dock — cute globe emoji on the same plate as every other dock btn.
]]
do
	local _, plate = dockBtn("", "Planets", function()
		local on = not zoneP.Visible
		hidePanels()
		zoneP.Visible = on
		if on and refreshZones then
			refreshZones()
		end
	end)
	mk("TextLabel", {
		Name = "PlanetIcon",
		BackgroundTransparency = 1,
		Text = "🌍",
		TextSize = 28,
		Font = Enum.Font.GothamMedium,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(36, 36),
		Active = false,
	}, plate)
end
dockBtn(ICONS.events, "Events", function()
	if not eventsCtl then
		return
	end
	if eventsCtl.root.Visible then
		eventsCtl.close()
		return
	end
	hidePanels()
	if snap then
		eventsCtl.setState(snap)
	end
	eventsCtl.open()
end)
--[[
	EVENTS GETS THE SAME PLATE AS EVERY OTHER DOCK BUTTON.

	Owner, 2026-10-05: "can you remove the background to the event icon, and then
	put a ui button block under it, so it matches every other icon in the row".

	It used to pass clearPlate, which switched off the 56px plate AND its
	hairline, so Events was the one button in the column with nothing behind it --
	the art sat straight on the world. That was done because the popper asset had
	a plate baked into it, and two plates looked worse than none.

	Dropping clearPlate puts the standard block back. If the baked plate is still
	in the asset the art needs a transparent re-upload; the id lives in ICONS at
	the top of this file and nothing else has to change.
]]
dockBtn(ICONS.skills, "Jobs", function()
	if depthHud.contractor then
		if snap then
			depthHud.contractor.setState(snap)
		end
		if depthHud.contractor.root and depthHud.contractor.root.Visible then
			depthHud.contractor.close()
		else
			hidePanels()
			depthHud.contractor.open()
		end
	end
end)
--[[
	REBIRTH SITS IN THE TOPBAR, NOT IN THE DOCK.

	Owner, 2026-10-05: "rebirth is annoyinly inside of the invenotry and shop
	icom.. just put rebirth icon top left next to the roblox mute button".

	It was the ninth dock button, and the dock reflows into extra columns when
	nine 78px cells do not fit the screen height -- which is most screens. So
	Rebirth kept landing in a second column beside Shop and Inventory. Moving it
	out fixes the crowding at the source rather than re-tuning layoutDock: the
	dock is back to eight, which fits one column nearly everywhere.

	GuiService.TopbarInset is the supported way to find the strip Roblox's own
	buttons are NOT using. Min.X is where its left-hand cluster ends, so sitting
	just past that puts this next to the mute button at any topbar size, on any
	device, without guessing pixel offsets. It is wrapped and defaulted because
	the property is newer than some clients and reads as a zero Rect before the
	topbar has laid out -- 104 x 4 is where the cluster ends on a default topbar.
]]
do
	local btn = mk("TextButton", {
		Name = "RebirthTopbar",
		Text = "",
		AutoButtonColor = false,
		Active = true,
		BackgroundColor3 = Color3.fromRGB(12, 14, 20),
		BackgroundTransparency = 0.08,
		Position = UDim2.fromOffset(104, 4),
		Size = UDim2.fromOffset(36, 36),
		ZIndex = 30,
	}, gui)
	round(btn, 10)
	stroke(btn, 1.5)
	mk("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = ICONS.prestige,
		ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(26, 26),
		ZIndex = 31,
		Active = false,
	}, btn)
	btn.MouseButton1Click:Connect(function()
		local on = not presP.Visible
		hidePanels()
		presP.Visible = on
		if on and refreshPrestige then
			refreshPrestige()
		end
	end)

	function ClientFns.layoutRebirthTopbar()
		local x, y, h = 104, 4, 36
		local ok, inset = pcall(function()
			return GuiService.TopbarInset
		end)
		if ok and inset and inset.Width > 0 then
			x = inset.Min.X + 8
			y = inset.Min.Y + 2
			-- Fit the topbar's own height rather than overhanging it.
			h = math.clamp(inset.Height - 4, 24, 44)
		end
		-- uiScale stretches the whole tree, so the offsets have to be divided
		-- back out or the button drifts right as the scale grows.
		local k = math.max(0.05, uiScale.Scale)
		btn.Position = UDim2.fromOffset(x / k, y / k)
		btn.Size = UDim2.fromOffset(h / k, h / k)
	end
	ClientFns.layoutRebirthTopbar()
	uiScale:GetPropertyChangedSignal("Scale"):Connect(ClientFns.layoutRebirthTopbar)
	pcall(function()
		GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(ClientFns.layoutRebirthTopbar)
	end)
end
--[[
	Settings (sound, codes, invites, notifications) is a gear on the right end
	of the wallet, not a tenth dock button: a tenth button pushed the dock into
	an extra column on phones and into a second column at 1080p. There is no
	gear in the icon set, so it is drawn from frames -- four bars make eight
	teeth, a disc is the body.
]]
do
	local gear = mk("TextButton", {
		Name = "SettingsGear", Text = "", AutoButtonColor = false, Active = true,
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 10, 0.5, 0), Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = Color3.fromRGB(12, 14, 20), BackgroundTransparency = 0.08, ZIndex = 21,
	}, wallet)
	round(gear, 26)
	if ClientFns.UI then
		ClientFns.UI.candy(gear, "blue", 3, false)
		ClientFns.UI.juice(gear, 1.1)
	else
		stroke(gear, 1.5)
	end
	for i = 0, 3 do
		round(mk("Frame", {
			BackgroundColor3 = GOLD, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(7, 30), Rotation = i * 45, ZIndex = 22, Active = false,
		}, gear), 2)
	end
	round(mk("Frame", {
		BackgroundColor3 = GOLD, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(22, 22), ZIndex = 23, Active = false,
	}, gear), 11)
	round(mk("Frame", {
		BackgroundColor3 = T.OUTLINE, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(9, 9), ZIndex = 24, Active = false,
	}, gear), 5)
	gear.MouseButton1Click:Connect(function()
		ClientFns.settings().toggle()
	end)
end
-- Free gifts: a box under the gear, with the next gift's clock or OPEN!
do
	local btn = mk("TextButton", {
		Name = "GiftsButton", Text = "", AutoButtonColor = false, Active = true,
		Position = UDim2.new(1, 10, 1, 8), Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = Color3.fromRGB(12, 14, 20), BackgroundTransparency = 0.08, ZIndex = 21,
	}, wallet)
	round(btn, 14)
	if ClientFns.UI then
		ClientFns.UI.candy(btn, "purple", 3, false)
		ClientFns.UI.juice(btn, 1.1)
	else
		stroke(btn, 1.5)
	end
	local red = Color3.fromRGB(214, 70, 82)
	round(mk("Frame", {
		BackgroundColor3 = red, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.62, 0),
		Size = UDim2.fromOffset(26, 18), ZIndex = 22, Active = false,
	}, btn), 3)
	round(mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(236, 96, 108), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.4, 0),
		Size = UDim2.fromOffset(30, 7), ZIndex = 23, Active = false,
	}, btn), 2)
	mk("Frame", {
		BackgroundColor3 = GOLD, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.55, 0),
		Size = UDim2.fromOffset(5, 26), ZIndex = 24, Active = false,
	}, btn)
	for _, side in ipairs({ -1, 1 }) do
		round(mk("Frame", {
			BackgroundColor3 = GOLD, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, side * 5, 0.26, 0),
			Size = UDim2.fromOffset(9, 9), Rotation = 45, ZIndex = 24, Active = false,
		}, btn), 2)
	end
	local timeL = mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = TEXT, TextStrokeTransparency = 1,
		Text = "", Position = UDim2.new(0, -10, 1, 2), Size = UDim2.new(1, 20, 0, 18), ZIndex = 22, Active = false,
	}, btn)
	if ClientFns.UI then
		ClientFns.UI.outlineText(timeL, 2)
	end
	local badge = mk("TextLabel", {
		BackgroundColor3 = red, Font = FONT, TextSize = 14, TextColor3 = TEXT, Text = "", Visible = false,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -2, 0, 2), Size = UDim2.fromOffset(22, 22),
		ZIndex = 25, Active = false,
	}, btn)
	round(badge, 11)
	do
		local s = stroke(badge, 2)
		s.Color = T.OUTLINE
		s.Transparency = 0
	end
	btn.MouseButton1Click:Connect(function()
		ClientFns.giftsPanel().toggle()
	end)
	ClientFns.giftBtn = { btn = btn, timeL = timeL, badge = badge }
end
--[[
	The dock has to fit the screen it is on. Eight 78px buttons in a single
	column is taller than a phone held sideways, so Shop and Rebirth sat off the
	top and bottom of the screen where nobody could press them. When one column
	does not fit, the buttons shrink a little and flow into as many columns as
	it takes, growing in from the right edge, with the bottom kept clear of the
	touch jump button.
]]
function ClientFns.layoutDock()
	local k = math.max(0.05, uiScale.Scale)
	local screen = gui.AbsoluteSize / k
	if screen.Y < 10 then
		return
	end
	local buttons = {}
	for _, c in ipairs(dock:GetChildren()) do
		if c:IsA("GuiButton") and c.Visible then
			table.insert(buttons, c)
		end
	end
	local n = #buttons
	if n == 0 then
		return
	end
	-- Start under the mine timer (it sat on top of the Shop button) and stop
	-- short of Roblox's corner button, or of the jump button on a phone.
	local topRoom = (GuiService:GetGuiInset().Y + 8) / k
	if mineResetL.Visible then
		local under = (mineResetL.AbsolutePosition.Y + mineResetL.AbsoluteSize.Y - gui.AbsolutePosition.Y) / k
		topRoom = math.max(topRoom, under + 8)
	end
	local bottomRoom = UIS.TouchEnabled and 140 or 48
	local room = screen.Y - topRoom - bottomRoom
	local gap = 6
	local cellW, cellH, plateS, textS = 74, 80, 58, 15
	local rows, cols = n, 1
	if n * (cellH + gap) - gap > room then
		-- A little shorter still fits one column: just tighten the captions.
		local tight = math.floor((room + gap) / n) - gap
		if tight >= 66 then
			cellH, plateS, textS = tight, math.min(58, tight - 16), 14
		else
			-- Otherwise smaller cells, as many columns as it takes, in from the
			-- right edge.
			cellW, cellH, plateS, textS = 64, 68, 48, 13
			rows = math.clamp(math.floor((room + gap) / (cellH + gap)), 1, n)
			cols = math.ceil(n / rows)
			rows = math.ceil(n / cols) -- even columns rather than one full and one stub
		end
	end
	local grid = ClientFns.dockGrid
	if not grid then
		local list = dock:FindFirstChildOfClass("UIListLayout")
		if list then
			list:Destroy()
		end
		grid = Instance.new("UIGridLayout")
		grid.FillDirection = Enum.FillDirection.Vertical
		grid.StartCorner = Enum.StartCorner.TopRight
		grid.HorizontalAlignment = Enum.HorizontalAlignment.Right
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.Parent = dock
		ClientFns.dockGrid = grid
	end
	grid.CellSize = UDim2.fromOffset(cellW, cellH)
	grid.CellPadding = UDim2.fromOffset(gap, gap)
	grid.FillDirectionMaxCells = rows
	for i, btn in ipairs(buttons) do
		btn.LayoutOrder = i
		local plate = btn:FindFirstChild("Plate")
		if plate then
			plate.Size = UDim2.fromOffset(plateS, plateS)
			local icon = plate:FindFirstChildOfClass("ImageLabel")
			if icon then
				icon.Size = UDim2.fromOffset(plateS - 16, plateS - 16)
			end
		end
		-- UpgradeBadge retired (MineNotifs.NotifBadge owns dock counts). Scrub
		-- leftovers so a stale label never steals the caption slot on reflow.
		local stale = btn:FindFirstChild("UpgradeBadge")
		if stale then
			stale:Destroy()
		end
		local cap
		for _, c in ipairs(btn:GetChildren()) do
			if c:IsA("TextLabel") and c.Name ~= "UpgradeBadge" then
				cap = c
				break
			end
		end
		if cap then
			cap.Position = UDim2.fromOffset(0, plateS)
			cap.Size = UDim2.new(1, 0, 0, cellH - plateS)
			cap.TextSize = textS
		end
	end
	dock.AnchorPoint = Vector2.new(1, 0)
	dock.Size = UDim2.fromOffset(cols * cellW + (cols - 1) * gap, rows * cellH + (rows - 1) * gap)
	dock.Position = UDim2.new(1, -18, 0, topRoom + math.max(0, (room - (rows * (cellH + gap) - gap)) / 2))
end
mineResetL:GetPropertyChangedSignal("AbsolutePosition"):Connect(ClientFns.layoutDock)
mineResetL:GetPropertyChangedSignal("Visible"):Connect(ClientFns.layoutDock)
ClientFns.layoutDock()
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(ClientFns.layoutDock)
uiScale:GetPropertyChangedSignal("Scale"):Connect(ClientFns.layoutDock)
for _, b in ipairs(dock:GetChildren()) do
	if b:IsA("GuiButton") then
		b:GetPropertyChangedSignal("Visible"):Connect(ClientFns.layoutDock)
	end
end

--[[
	Where the tutorial line goes. Centred at the top it ran straight over the
	wallet on anything narrower than a big monitor, so it takes the gap between
	the wallet and the mine timer, and when that gap is too small (a phone) it
	drops to the bottom of the screen, just above the sell button. With no
	width it only answers how wide the banner may be where it will go.
]]
function ClientFns.introPlace(w)
	local k = math.max(0.05, uiScale.Scale)
	local screenW = gui.AbsoluteSize.X / k
	-- +58 for the settings gear riding the wallet's right end.
	local left = (wallet.AbsolutePosition.X + wallet.AbsoluteSize.X) / k + 12 + 58
	local right = screenW - 160
	local gap = right - left
	local atTop = gap >= 420
	local maxW = atTop and math.min(700, gap) or math.min(700, screenW - 40)
	if w then
		if atTop then
			introBanner.AnchorPoint = Vector2.new(0.5, 0)
			--[[
				Centred on the SCREEN. It used to centre in the gap between the
				wallet and the mine timer, and the wallet is several times wider
				than the timer, so the banner sat visibly right of centre. It only
				slides now when a centred banner would actually run over one of
				them, and then just far enough to clear it.
			]]
			local x = screenW / 2
			local lo, hi = left + w / 2, right - w / 2
			if x < lo or x > hi then
				x = (lo <= hi) and math.clamp(x, lo, hi) or (left + gap / 2)
				introBanner.Position = UDim2.new(0, x, 0, 70)
			else
				introBanner.Position = UDim2.new(0.5, 0, 0, 70)
			end
		else
			introBanner.AnchorPoint = Vector2.new(0.5, 1)
			introBanner.Position = UDim2.new(0.5, 0, 1, -136)
		end
	end
	return maxW
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	ClientFns.introPlace(introBanner.Size.X.Offset)
end)
uiScale:GetPropertyChangedSignal("Scale"):Connect(function()
	ClientFns.introPlace(introBanner.Size.X.Offset)
end)

bagBtn.MouseButton1Click:Connect(function()
	if invCtl then
		-- Always onto Equipment: that is what this button is for, whatever tab
		-- the window was last left on.
		invCtl.toggle("inventory", "tools")
	end
end)

local SkillView = require(shared:WaitForChild("MineSkillView"))
-- Portals are built dead by the server and lit by the client, so that only the
-- gates this player has earned glow and swirl. Without this every gateway was a
-- blank stone slab.
local PortalFX = require(shared:WaitForChild("MinePortalFX"))
local ZoneMapView = require(shared:WaitForChild("MineZoneMapView"))
portalFx = PortalFX.start(function() return snap end)

-- The tool and backpack shop. The old shopP was a stub list; this one shows the
-- real 3D model of every rung and mirrors the server's purchase rules exactly,
-- so it never offers a button that would be refused.
local ShopView = require(shared:WaitForChild("MineShopView"))
local DepthShopView = require(shared:WaitForChild("MineDepthShopView"))
local ForgeView = require(shared:WaitForChild("MineForgeView"))
local RunesView = require(shared:WaitForChild("MineRunesView"))
local RunesSockets = require(shared:WaitForChild("MineSocketsView"))
-- One window for packs, cards, the chest directory, the shop and passes:
-- sections down the left, tabs across the top. The card art comes from this
-- file's own paintCard, so there is exactly one card renderer in the game.
local paintCard -- defined below; the inventory window is mounted above it
-- Set while a pack reveal owns the screen. Assigned below.
local packRevealBusy = false
local packRevealBusyAt = 0
local PACK_REVEAL_WATCHDOG_SEC = 30
-- The reveal is its own ScreenGui above the inventory; see MinePackReveal.
-- Forward-declared because its options close over paintCard, defined lower.
local revealCtl
local function clearPackRevealBusy()
	packRevealBusy = false
	packRevealBusyAt = 0
	if invCtl then
		invCtl.setBusy(false)
	end
end
local function armPackRevealBusy()
	packRevealBusy = true
	packRevealBusyAt = os.clock()
	if invCtl then
		invCtl.setBusy(true)
	end
end
local InventoryView = require(shared:WaitForChild("MineInventoryView"))
invCtl = InventoryView.mount(gui, {
	-- One rung of the ITEM bag (+100 slots for gems). Not the backpack.
	onBuyItemSlots = function() net:FireServer("buy", "itemSlots") end,
	--[[
		Sign one charter level. Verbs.buyCharter has existed, complete and
		dispatched, with no caller -- four permanent gem upgrades the currency
		panel named to the player and nothing could buy. The verb takes a bare
		id, not a table.
	]]
	onBuyCharter = function(id) net:FireServer("buyCharter", tostring(id or "")) end,
	paintCard = function(parent, card, w) return paintCard(parent, card, w) end,
	petViewport = function(parent, card, pos, size)
		return ClientFns.petViewport(parent, card, pos, size)
	end,
	cardSort = cardSort,
	onCardSort = persistCardSort,
	--[[
		THE MENU STAYS OPEN.

		This used to call invCtl.close() before every open, so the reveal
		played over the world and dropped you at the HUD afterwards -- opening
		six packs meant re-opening the inventory six times. The reveal is its
		own ScreenGui at a higher DisplayOrder now, so it covers the menu and
		leaves it exactly where it was underneath.
	]]
	onOpenPack = function(index, uid)
		if packRevealBusy then
			return
		end
		armPackRevealBusy()
		-- `uid` is the one pack that was tapped. The index rides along only so
		-- an old client still opens something.
		net:FireServer("openAt", { uid = uid, index = index })
	end,
	-- Open several of one pack in a single request. The tiles offer 1 / 10 /
	-- the whole stack; the server clamps to what the player actually holds.
	onOpenMany = function(packId, count, uid)
		if packRevealBusy then
			return
		end
		-- Gear / Rune cases: never more than 3 at once.
		local pid = tostring(packId or "")
		if string.find(pid, "gear", 1, true) or string.find(pid, "rune", 1, true) then
			count = math.min(tonumber(count) or 1, 3)
		end
		armPackRevealBusy()
		net:FireServer("openMany", { packId = packId, count = count, uid = uid })
	end,
	-- Lucky blocks open on their own screen (MineGradeReveal.lucky), a tap at a
	-- time, with the paid grade-up on it.
	onOpenLucky = function(g)
		if packRevealBusy then
			return
		end
		ClientFns.luckyScreen().show(ClientFns.luckyStack(g))
	end,
	onOpenLuckyMany = function(g, count)
		if packRevealBusy then
			return
		end
		ClientFns.luckyScreen().openMany(ClientFns.luckyStack(g), count)
	end,
	onEquip = function(id) net:FireServer("equip", id) end,
	onUnequip = function(id) net:FireServer("unequip", id) end,
	-- Merge from the card tile: the client only names the card; the server
	-- re-counts the three copies and burns two of them itself.
	onMerge = function(id) net:FireServer("merge", { ids = { id } }) end,
	-- Gear tab. Tools and armour are the same question -- what am I taking down
	-- there -- so they get answered in one place.
	-- Fuse two matching pieces into the next grade. The client names two ids
	-- and nothing else; MineGear.canUpgrade decides on the server.
	onUpgradeGear = function(aId, bId)
		Audio.play("equip")
		net:FireServer("upgradeGear", { a = aId, b = bId })
	end,
	-- `slot` is the seat the player was looking at. The server honours it when it
	-- names a real seat and takes the first free one otherwise.
	onEquipGear = function(id, slot)
		Audio.play("equip")
		net:FireServer("equipGear", { gearId = id, slot = slot })
	end,
			onSocketGear = function(gearId, runeId, index)
				net:FireServer("socketGearRune", { gearId = gearId, runeId = runeId, index = index })
			end,
	onUnequipGear = function(slot, gearId)
		net:FireServer("unequipGear", { slot = slot, gearId = gearId })
	end,
	onEquipBest = function() net:FireServer("equipBest") end,
	onSocketAny = function(item, runeId, index) ClientFns.socketRoute(item, runeId, index) end,
	-- The plus tile at the end of your gear: walk to the machine, open summons.
	onGoEnchanter = function()
		net:FireServer("introPing", 30)
		if ClientFns.teleportToEnchanter then
			ClientFns.teleportToEnchanter()
		end
		ClientFns.routePanel("enchanter", "summon")
	end,
	onEquipCharm = function(id) net:FireServer("equipCharm", id) end,
	onUnequipCharm = function() net:FireServer("equipCharm", "") end,
	onBuyCharmsPack = function() net:FireServer("buyCharmsPack") end,
	--[[
		Buy ONE named charm with temper tokens. Verbs.buyCharm has been
		complete and dispatched with no caller -- 36 purchasable charms, F 15
		through SSS 2,500, a whole priced shelf that nothing could reach. The
		gem pack and the Robux charm were the only wired paths.

		Only the id and the count travel: the server looks the price up from
		the def itself, so a client cannot name its own.
	]]
	onBuyCharm = function(charmId, count)
		net:FireServer("buyCharm", { charmId = tostring(charmId or ""), count = count or 1 })
	end,
	onEquipVfx = function(kind, id) net:FireServer("equipVfx", { kind = kind, id = id }) end,
	onBuyVfx = function(id) net:FireServer("buyVfx", id) end,
	onBuyLuckyCharm = function() net:FireServer("buyLuckyCharm") end,
	onBuyProductCredits = function(key) net:FireServer("buyProductCredits", { key = key }) end,
	onBuyProductRobux = function(key)
		local prod = C.product and C.product(key)
		local pid = prod and tonumber(prod.productId) or 0
		if pid > 0 then
			MarketplaceService:PromptProductPurchase(player, pid)
		else
			showToast("Product ID not wired yet - paste from Dashboard")
		end
	end,
	onEquipTool = function(family, tier)
		Audio.play("equip")
		net:FireServer("equipTool", { family = family, tier = tier })
	end,
	onEquipChestTool = function(id) net:FireServer("equipChestTool", { id = id }) end,
	-- Inventory -> Equipment. The card has already made the player hold SELL
	-- for three seconds; the server re-checks everything regardless.
	onEquipShopTool = function(id)
		Audio.play("equip")
		net:FireServer("equipShopTool", { id = id })
	end,
	onSellTool = function(payload) net:FireServer("sellTool", payload) end,
	onScrapGear = function(id) net:FireServer("scrap", { kind = "gear", id = id }) end,
	-- Three charms into one a tier deeper. The server owns the cost and the
	-- target (MineCharms.MERGE_COST / mergeTarget); this only names the charm.
	onMergeCharm = function(id) net:FireServer("mergeCharm", { id = id }) end,
	--[[
		Bulk scrap goes out twice. The first call carries no confirm flag and is
		the ASK -- the server builds the plan and replies with `confirmScrap`,
		which opens the review screen on the server's own figures. The second
		carries confirm and performs it, all or nothing.
	]]
	onScrapMany = function(kind, ids, into, confirm)
		net:FireServer("scrapMany", {
			kind = kind or "gear",
			ids = ids,
			into = into,
			confirm = confirm and true or nil,
		})
	end,
	-- Shop -> Stardust. The server checks both stocks and the price.
	onBuyDustPack = function(id, qty) net:FireServer("buyDustPack", { id = id, qty = qty }) end,
	onBuyDustCase = function(id, qty) net:FireServer("buyDustCase", { id = id, qty = qty }) end,
	onDrinkPotion = function(id) net:FireServer("drinkPotion", { id = id }) end,
	onMergePotion = function(id) net:FireServer("mergePotion", { id = id }) end,
	onEquipBag = function(id) net:FireServer("equipBag", { id = id }) end,
	onShop = function()
		if shopCtl then
			invCtl.close()
			shopCtl.open()
		end
	end,
	onForge = function()
		if forgeCtl then
			invCtl.close()
			if snap then
				forgeCtl.setState(snap)
			end
			forgeCtl.open()
		end
	end,
	-- Battle pass. The server re-derives the tier and the reward from the
	-- profile, so this only names the row.
	onClaimPass = function(tier, track)
		local now = os.clock()
		if ClientFns._claimPassAt and (now - ClientFns._claimPassAt) < 0.75 then
			return
		end
		ClientFns._claimPassAt = now
		net:FireServer("claimPass", { tier = tier, track = track })
	end,
	onClaimDaily = function() net:FireServer("claimDaily") end,
	onDiscordRedeemCode = function(code) net:FireServer("discordLink", { code = code }) end,
	-- Battle Pass signature fuse: Lunar + Eclipse -> Lunar Eclipse.
	onFusePassTools = function() net:FireServer("fusePassTools") end,
	--[[
		Checkout. The cart sends only what it wants -- kind, id, whether it is
		the ten-pack -- and never a price. The server reprices the whole thing
		from its own tables, so a forged payload can ask for the wrong ITEMS but
		never for the wrong COST.
	]]
	onBuyCart = function(lines)
		net:FireServer("buyCart", { lines = lines })
	end,
	-- The server owns the seat count and the price; this only asks.
	onJoinVip = function()
		net:FireServer("joinVip")
	end,
	onBuyVipPass = function()
		local gpId = tonumber(C.VIP_GAMEPASS_ID) or 1977363670
		pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, gpId)
		end)
	end,
	onBuyFoundersRobux = function()
		local gpId = tonumber(C.FOUNDERS_GAMEPASS_ID) or 1982786367
		pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, gpId)
		end)
	end,
	onClaimDailyQuest = function(index) net:FireServer("claimDailyQuest", { index = index }) end,
	onClaimMilestone = function(id) net:FireServer("claimMilestone", { id = id }) end,
	onBuyPass = function()
		local bp = require(shared:WaitForChild("MineScrolls")).BATTLE_PASS
		local pid = bp and (tonumber(bp.productId) or 0) or 0
		if pid > 0 then
			MarketplaceService:PromptProductPurchase(player, pid)
		else
			showToast("The pass is not on sale yet")
		end
	end,
	onBuyPassCredits = function() net:FireServer("buyBattlePassCredits") end,
})

--[[
	The lucky block screen, built the first time a block is opened. While it is
	up it owns the screen the way a pack reveal does, so the inventory under it
	ignores a second tap.
]]
-- The spinning case (temperaments). Mounted on first use, like the lucky screen.
function ClientFns.caseScreen()
	if not ClientFns.caseCtl then
		ClientFns.caseCtl = GradeReveal.caseSpin(player:WaitForChild("PlayerGui"))
	end
	return ClientFns.caseCtl
end

function ClientFns.luckyScreen()
	if ClientFns.luckyCtl then
		return ClientFns.luckyCtl
	end
	local LuckyBlocks = require(shared:WaitForChild("MineLuckyBlocks"))
	ClientFns.luckyCtl = GradeReveal.lucky(player:WaitForChild("PlayerGui"), {
		-- The same layer as every other reveal (packs, the case reel). It was
		-- the module default, 95: bca50ca meant to move this screen to 120 but
		-- changed caseSpin instead.
		displayOrder = 120,
		shortNum = shortNum,
		gems = function()
			return (snap and snap.gems) or 0
		end,
		priceOf = function(block)
			return LuckyBlocks.nextGrade(block.startGrade) and LuckyBlocks.gradeUpPrice(block) or nil
		end,
		onOpen = function(block, count)
			net:FireServer("openLucky", { uid = block.uid, key = block.key, index = block.firstIndex, count = count })
		end,
		onGradeUp = function(block)
			net:FireServer("luckyGradeUp", { uid = block.uid, key = block.key, index = block.firstIndex })
		end,
		onBusy = function(flag)
			if flag then
				armPackRevealBusy()
			else
				clearPackRevealBusy()
				-- Closing a lucky reveal: refresh inventory/pass from the latest
				-- snapshot so CLAIMED tiles and bag counts catch up immediately.
				if invCtl and snap then
					invCtl.setState(snap)
				end
			end
		end,
	})
	return ClientFns.luckyCtl
end

--[[
	WHAT YOU BOUGHT, FLYING INTO YOUR BAG.

	A purchase used to be a toast at the edge of the screen. Now the thing
	itself appears in the middle -- the pack's own art, a pouch, a lucky cube --
	says what it is and how many, then flies into the Inventory button, which
	bumps as it lands. Fired for packs bought with credits (cartResult) or
	stardust, and for gem summons (purchaseFx). Several at once queue up a
	quarter-second apart instead of landing on top of each other.
]]
function ClientFns.flyToBag(info)
	if type(info) ~= "table" then
		return
	end
	local PackFX = require(shared:WaitForChild("MinePackFX"))
	local Icons = require(shared:WaitForChild("MineIcons"))
	local TS = game:GetService("TweenService")
	ClientFns.flyQueue = (ClientFns.flyQueue or 0) + 1
	local slot = ClientFns.flyQueue - 1
	task.delay(slot * 0.25, function()
		ClientFns.flyQueue = math.max(0, (ClientFns.flyQueue or 1) - 1)
		local k = math.max(0.05, uiScale.Scale)
		local screen = gui.AbsoluteSize / k
		local target
		for _, b in ipairs(dock:GetChildren()) do
			local l = b:IsA("GuiButton") and b:FindFirstChildWhichIsA("TextLabel")
			if l and l.Text == "Inventory" then
				target = b
			end
		end
		local start = Vector2.new(screen.X / 2, screen.Y * 0.42)
		local dest = target and ((target.AbsolutePosition + target.AbsoluteSize / 2 - gui.AbsolutePosition) / k)
			or Vector2.new(screen.X - 60, screen.Y / 2)

		local holder = mk("Frame", {
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(start.X, start.Y), Size = UDim2.fromOffset(120, 164), ZIndex = 300,
		}, gui)
		local sc = mk("UIScale", { Scale = 0.2 }, holder)
		local glow = mk("Frame", {
			BackgroundColor3 = GOLD, BackgroundTransparency = 0.6, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(176, 176), ZIndex = 300,
		}, holder)
		round(glow, 88)
		local art = mk("Frame", {
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(96, 128), ZIndex = 302,
		}, holder)
		if info.kind == "pack" and info.packId then
			pcall(PackFX.drawSealed, art, info.packId, 96, 128)
		else
			local img = Icons.image and Icons.image(tostring(info.icon or info.id or "pack"))
			if img then
				mk("ImageLabel", { BackgroundTransparency = 1, Image = img, ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(1, 1), ZIndex = 303 }, art)
			end
		end
		local count = math.max(1, math.floor(tonumber(info.count) or 1))
		local cap = mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 24, TextColor3 = GOLD,
			Text = ((count > 1) and (count .. "x  ") or "+1  ") .. tostring(info.name or "Item"),
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 4),
			Size = UDim2.fromOffset(420, 30), ZIndex = 304,
		}, holder)
		mk("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0), Transparency = 0.2 }, cap)
		local sub = mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT_M, TextSize = 14, TextColor3 = TEXT,
			Text = "added to your Inventory",
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 34),
			Size = UDim2.fromOffset(420, 18), ZIndex = 304,
		}, holder)
		mk("UIStroke", { Thickness = 1.5, Color = Color3.new(0, 0, 0), Transparency = 0.3 }, sub)

		TS:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		Audio.play("shop")
		task.wait(0.85)
		if not holder.Parent then
			return
		end
		cap.Visible, sub.Visible = false, false
		local fly = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TS:Create(holder, fly, { Position = UDim2.fromOffset(dest.X, dest.Y) }):Play()
		TS:Create(sc, fly, { Scale = 0.16 }):Play()
		TS:Create(glow, fly, { BackgroundTransparency = 1 }):Play()
		task.wait(0.55)
		holder:Destroy()
		if target then
			-- Through the kit's shared FxScale: the dock buttons already carry it
			-- (juice), and Roblox ignores a second UIScale on the same frame.
			if ClientFns.UI then
				ClientFns.UI.pop(target, 1.28)
			else
				local bump = target:FindFirstChild("FlyBump") or mk("UIScale", { Name = "FlyBump", Scale = 1 }, target)
				bump.Scale = 1.28
				TS:Create(bump, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			end
		end
		Audio.play("equip")
	end)
end

-- A server-wide line in chat (a coinflip result), as a system message.
function ClientFns.sysChat(payload)
	local body = type(payload) == "table" and tostring(payload.text or "") or tostring(payload or "")
	if body == "" then
		return
	end
	local hex = type(payload) == "table" and payload.color or "#FFCE5C"
	local safe = body:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	local shown = pcall(function()
		local channels = game:GetService("TextChatService"):FindFirstChild("TextChannels")
		local general = channels and channels:FindFirstChild("RBXGeneral")
		general:DisplaySystemMessage(string.format('<font color="%s">%s</font>', hex, safe))
	end)
	if not shown then
		pcall(function()
			game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
				Text = body,
				Color = Color3.fromHex(hex),
			})
		end)
	end
end

--[[
	WAYPOINTS. A tutorial step that happens at a station (sell pad, shop,
	Enchanter...) lays the same lit trail as step 1 from the player to it and
	hangs a marker over it with its name and distance, so "walk to the
	Enchanter" is something you follow rather than something you hunt for.
]]
ClientFns.STATION_LABEL = {
	sell = "SELL", shop = "BLACKSMITH", enchanter = "ENCHANTER", contractor = "JOBS",
	prestige = "REBIRTH", chest = "CHEST", mine = "MINE", pit = "MINE",
}

function ClientFns.pitWaypointPos()
	local biome = workspace:FindFirstChild("MineWorld")
		and workspace.MineWorld:FindFirstChild("Biome_meadow")
	if biome then
		local bestZ, best
		for _, c in ipairs(biome:GetChildren()) do
			if c.Name == "PitLip_meadow" and c:IsA("BasePart") then
				if not bestZ or c.Position.Z < bestZ then
					bestZ = c.Position.Z
					best = c.Position
				end
			end
		end
		if best then
			return Vector3.new(best.X, best.Y + 0.8, best.Z)
		end
	end
	return Vector3.new(0, 5.2, 148)
end

function ClientFns.chestWaypointPos()
	local CS = game:GetService("CollectionService")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local nearest, nearDist
	for _, part in ipairs(CS:GetTagged("MineVoxel")) do
		if part:IsA("BasePart") and part:GetAttribute("Kind") == "chest" and part.Parent then
			local layer = tonumber(part:GetAttribute("CY")) or 99
			local zoneId = part:GetAttribute("ZoneId")
			-- Prefer the stamped tutorial chest; else nearest shallow meadow chest.
			if part:GetAttribute("IntroChest") then
				return part.Position
			end
			if zoneId == "meadow" and layer <= 3 then
				local dist = root and (part.Position - root.Position).Magnitude or layer
				if not nearDist or dist < nearDist then
					nearDist = dist
					nearest = part.Position
				end
			end
		end
	end
	return nearest
end

function ClientFns.stationPos(id)
	if id == "chest" then
		return ClientFns.chestWaypointPos()
	end
	if id == "mine" or id == "pit" then
		return ClientFns.pitWaypointPos()
	end
	local world = workspace:FindFirstChild("MineWorld")
	if not world or not id then
		return nil
	end
	local function padIn(folder)
		local shop = folder and folder:FindFirstChild("Shop_" .. id)
		local pad = shop and shop:FindFirstChild("Pad_" .. id)
		local part = pad and (pad:FindFirstChild("Ring") or pad:FindFirstChild("Trigger"))
		return (part and part:IsA("BasePart")) and part.Position or nil
	end
	local zoneId = snap and snap.zoneId
	local biome = zoneId and world:FindFirstChild("Biome_" .. tostring(zoneId))
	local here = biome and padIn(biome:FindFirstChild("Outpost_" .. tostring(zoneId)))
	local lobby = padIn(world:FindFirstChild("Lobby"))
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if here and lobby and root then
		return ((here - root.Position).Magnitude <= (lobby - root.Position).Magnitude) and here or lobby
	end
	return here or lobby
end

function ClientFns.clearWaypointMarker()
	local w = ClientFns.waypointMarker
	ClientFns.waypointMarker = nil
	if w then
		w.alive = false
		if w.anchor then
			w.anchor:Destroy()
		end
	end
end

function ClientFns.setWaypoint(id)
	if id and ClientFns.waypointId == id and ClientFns.waypointMarker then
		return
	end
	ClientFns.waypointId = id
	ClientFns.clearWaypointMarker()
	ClientFns.clearPitTrail()
	if not id then
		return
	end
	ClientFns.buildPitTrail(function()
		local pos = ClientFns.stationPos(id)
		return pos and (pos + Vector3.new(0, 0.6, 0)) or nil
	end)
	local anchorPart = mk("Part", {
		Name = "WaypointAnchor", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2), CFrame = CFrame.new(0, -500, 0),
	}, workspace)
	local bb = mk("BillboardGui", {
		AlwaysOnTop = true, LightInfluence = 0, Size = UDim2.fromOffset(170, 92),
		StudsOffset = Vector3.new(0, 8, 0),
	}, anchorPart)
	local nameL = mk("TextLabel", {
		BackgroundColor3 = BG, BackgroundTransparency = 0.08, Font = FONT, TextSize = 18, TextColor3 = GOLD,
		Text = ClientFns.STATION_LABEL[id] or string.upper(tostring(id)), Size = UDim2.new(1, 0, 0, 30),
	}, bb)
	round(nameL, 10)
	stroke(nameL, 2)
	local distL = mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT, TextSize = 15, TextColor3 = TEXT, TextStrokeTransparency = 0.35,
		Text = "", Position = UDim2.fromOffset(0, 31), Size = UDim2.new(1, 0, 0, 18),
	}, bb)
	-- A V from two bars, bobbing toward the station.
	local chev = mk("Frame", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 54),
		Size = UDim2.fromOffset(40, 30),
	}, bb)
	for _, side in ipairs({ -1, 1 }) do
		round(mk("Frame", {
			BackgroundColor3 = GOLD, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, side * 8, 0.5, 0), Size = UDim2.fromOffset(24, 7), Rotation = side * -40,
		}, chev), 3)
	end
	local w = { alive = true, anchor = anchorPart }
	ClientFns.waypointMarker = w
	task.spawn(function()
		local t = 0
		while w.alive and anchorPart.Parent do
			local pos = ClientFns.stationPos(id)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if pos then
				anchorPart.CFrame = CFrame.new(pos)
				if root then
					distL.Text = string.format("%dm", math.floor((pos - root.Position).Magnitude / 5 + 0.5))
				end
				bb.Enabled = true
			elseif id == "chest" then
				-- Chest broken / gone - hide marker until the intro step advances.
				bb.Enabled = false
				distL.Text = ""
			end
			t += 0.05
			bb.StudsOffset = Vector3.new(0, 8 + math.sin(t * 4) * 0.6, 0)
			task.wait(0.05)
		end
	end)
end

function ClientFns.commas(n)
	local str = tostring(math.floor(tonumber(n) or 0))
	local out = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

--[[
	CHEST LOOT. One card listing everything a chest just gave -- each pack
	with its art, then gems, coins and stardust with their icons -- instead of
	a single line of toast. A new chest replaces the card and restarts it.
]]
function ClientFns.chestPopup(payload)
	if type(payload) ~= "table" then
		return
	end
	local card = ClientFns.chestCard
	if not card then
		card = mk("Frame", {
			Name = "ChestLoot", BackgroundColor3 = BG, BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.58, 0),
			Size = UDim2.fromOffset(290, 0), AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 70, Active = false, Visible = false,
		}, gui)
		-- No plate / border - just the loot rows.
		ClientFns.chestCardScale = mk("UIScale", {}, card)
		ClientFns.chestCard = card
	end
	for _, c in ipairs(card:GetChildren()) do
		if c:IsA("GuiObject") or c:IsA("UIListLayout") or c:IsA("UIPadding") then
			c:Destroy()
		end
	end
	-- Drop any leftover corner/stroke from older builds.
	for _, c in ipairs(card:GetChildren()) do
		if c:IsA("UICorner") or c:IsA("UIStroke") then
			c:Destroy()
		end
	end
	card.BackgroundTransparency = 1
	mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, card)
	mk("UIPadding", {
		PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
	}, card)
	local order = 0
	local function nextOrder()
		order += 1
		return order
	end
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT, TextSize = 18, TextColor3 = GOLD,
		Text = string.upper(tostring(payload.name or "Chest")) .. (payload.first and "  |  NEW!" or ""),
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		TextStrokeTransparency = 0.45, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = nextOrder(), ZIndex = 71, Active = false,
	}, card)
	local function row(drawIcon, text, color)
		local r = mk("Frame", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = nextOrder(), ZIndex = 71, Active = false,
		}, card)
		local host = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(34, 34), ZIndex = 72, Active = false }, r)
		drawIcon(host)
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 20, TextColor3 = color or TEXT,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = text,
			TextStrokeTransparency = 0.5, Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -44, 1, 0), ZIndex = 72, Active = false,
		}, r)
	end
	local function image(asset)
		return function(host)
			mk("ImageLabel", {
				BackgroundTransparency = 1, Image = asset or "", ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(1, 1), ZIndex = 73, Active = false,
			}, host)
		end
	end
	local counts, keys = {}, {}
	local ids = type(payload.packIds) == "table" and payload.packIds or {}
	for i, name in ipairs(type(payload.packs) == "table" and payload.packs or {}) do
		local key = tostring(ids[i] or name)
		if not counts[key] then
			counts[key] = { n = 0, name = tostring(name), id = ids[i] }
			table.insert(keys, key)
		end
		counts[key].n += 1
	end
	for _, key in ipairs(keys) do
		local c = counts[key]
		row(function(host)
			if c.id then
				pcall(PackFX.drawSealed, host, c.id, 25, 34)
				local mp = host:FindFirstChild("MiniPack")
				if mp then
					mp.AnchorPoint = Vector2.new(0.5, 0.5)
					mp.Position = UDim2.fromScale(0.5, 0.5)
				end
			else
				image(ICONS.card)(host)
			end
		end, string.format("+%d %s", c.n, c.name), TEXT)
	end
	if (tonumber(payload.gems) or 0) > 0 then
		row(image(ICONS.gem), "+" .. ClientFns.commas(payload.gems), T.GEM)
	end
	if (tonumber(payload.coins) or 0) > 0 then
		row(image(ICONS.coin), "+" .. ClientFns.commas(payload.coins), GOLD)
	end
	if (tonumber(payload.dust) or 0) > 0 then
		row(image(ICONS.stardust), "+" .. ClientFns.commas(payload.dust) .. " Stardust", T.DUST)
	end
	ClientFns.chestToken = (ClientFns.chestToken or 0) + 1
	local token = ClientFns.chestToken
	local sc = ClientFns.chestCardScale
	-- Soft entrance: slight ease, no Back punch.
	sc.Scale = 0.94
	card.Visible = true
	-- Owner, 2026-10-08: "less dopamine with the chests". So chests stay quiet,
	-- and only an S-rank (Ultra Rare) chest gets the small tier-1 pluck.
	if payload.rank == "S" then
		pcall(Audio.playWin, 1)
	end
	TweenService:Create(sc, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(2.1, function()
		if ClientFns.chestToken ~= token then
			return
		end
		local out = TweenService:Create(sc, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.96 })
		out:Play()
		-- Fade labels quickly, then hide.
		for _, d in ipairs(card:GetDescendants()) do
			if d:IsA("TextLabel") then
				TweenService:Create(d, TweenInfo.new(0.12), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			elseif d:IsA("ImageLabel") then
				TweenService:Create(d, TweenInfo.new(0.12), { ImageTransparency = 1 }):Play()
			end
		end
		out.Completed:Wait()
		if ClientFns.chestToken == token then
			card.Visible = false
		end
	end)
end

--[[
	CHEST GLOW. Soft PointLight on every chest (all rarities). Within ~2-3
	blocks (BLOCK=5 -> ~13 studs) a faint AlwaysOnTop Highlight peeks through
	nearby dirt. Scrubs old Claude ChestMark / floating mine-icon billboards.
]]
function ClientFns.chestBeacons()
	if ClientFns.chestBeaconsOn then
		return
	end
	ClientFns.chestBeaconsOn = true
	local CS = game:GetService("CollectionService")
	local chests = {}
	-- Soft PointLight only - no Highlight outlines. Warm enough to peek through
	-- ~2-4 dirt blocks when you are nearby; off when far so the mine stays dark.
	local NEAR = (C.BLOCK or 5) * 4
	local function consider(part)
		if part:IsA("BasePart") and part:GetAttribute("Kind") == "chest" then
			chests[part] = true
		end
	end
	for _, part in ipairs(CS:GetTagged("MineVoxel")) do
		consider(part)
	end
	CS:GetInstanceAddedSignal("MineVoxel"):Connect(consider)
	CS:GetInstanceRemovedSignal("MineVoxel"):Connect(function(part)
		chests[part] = nil
	end)
	-- Drop leftover Highlight pools / icon billboards from older builds.
	local cam = workspace.CurrentCamera
	for _, host in ipairs({ workspace, cam }) do
		if host then
			local leftover = host:FindFirstChild("ChestGlow")
			if leftover then
				leftover:Destroy()
			end
		end
	end
	local function scrubExtras(part)
		for _, d in ipairs(part:GetChildren()) do
			if d:IsA("BillboardGui") then
				d:Destroy()
			elseif d:IsA("Highlight") then
				-- No outlined chests - glow only.
				d:Destroy()
			end
		end
	end
	local function ensureAura(part)
		scrubExtras(part)
		local pl = part:FindFirstChild("ChestAura")
		if not pl then
			pl = Instance.new("PointLight")
			pl.Name = "ChestAura"
			pl.Color = Color3.fromRGB(255, 214, 120)
			pl.Shadows = false
			pl.Brightness = 0
			pl.Range = 10
			pl.Enabled = false
			pl.Parent = part
		end
		return pl
	end
	task.spawn(function()
		local t = 0
		while true do
			task.wait(0.22)
			t += 0.22
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local pulse = 0.04 + math.abs(math.sin(t * 1.6)) * 0.06
			for part in pairs(chests) do
				if part.Parent then
					local pl = ensureAura(part)
					local d = root and (part.Position - root.Position).Magnitude or 999
					if d < NEAR then
						-- Soft warm spill through a few dirt voxels - not a flood.
						pl.Enabled = true
						pl.Brightness = 0.45 + pulse
						pl.Range = 11
					else
						pl.Enabled = false
					end
				else
					chests[part] = nil
				end
			end
		end
	end)
end

--[[
	DAILY CALENDAR. The daily card shows the whole week -- what is behind
	every day, which are taken, and the day-seven jackpot -- instead of just
	today's prize.
]]
function ClientFns.paintDailyCalendar(state)
	local cal = type(state) == "table" and state.calendar
	if type(cal) ~= "table" or #cal == 0 then
		return
	end
	local card = dailyHud.card
	if not dailyHud.cal then
		card.Size = UDim2.fromOffset(640, 318)
		dailyHud.prize.Visible = false
		dailyHud.cal = mk("Frame", {
			Name = "Week", BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 72),
			Size = UDim2.new(1, -32, 0, 150), ZIndex = 26, Active = false,
		}, card)
		mk("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
		}, dailyHud.cal)
		dailyHud.streak.Position = UDim2.fromOffset(0, 228)
		dailyHud.claim.Position = UDim2.fromOffset(24, 252)
		dailyHud.claim.Size = UDim2.new(1, -48, 0, 46)
		dailyHud.open.Size = UDim2.new(1, 0, 0, 64)
	end
	for _, c in ipairs(dailyHud.cal:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for _, d in ipairs(cal) do
		local tile = mk("Frame", {
			BackgroundColor3 = d.jackpot and Color3.fromRGB(78, 60, 22) or T.CARD,
			BackgroundTransparency = d.claimed and 0.45 or 0,
			Size = UDim2.fromOffset(80, 150), LayoutOrder = d.day, ZIndex = 27, Active = false,
		}, dailyHud.cal)
		round(tile, 12)
		local st = stroke(tile, d.today and 3 or 1)
		st.Color = d.today and GOLD or (d.jackpot and GOLD or T.LINE)
		st.Transparency = d.today and 0 or 0.4
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 15,
			TextColor3 = d.today and GOLD or (d.claimed and MUTED or TEXT),
			Text = "DAY " .. d.day, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 18), ZIndex = 28,
		}, tile)
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT_M, TextSize = 12, TextWrapped = true,
			TextColor3 = d.claimed and MUTED or TEXT, TextYAlignment = Enum.TextYAlignment.Top,
			Text = table.concat(d.parts or {}, "\n"), Position = UDim2.fromOffset(4, 28),
			Size = UDim2.new(1, -8, 1, -52), ZIndex = 28,
		}, tile)
		local foot = d.claimed and "CLAIMED" or (d.today and "TODAY" or (d.jackpot and "JACKPOT" or ""))
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 12,
			TextColor3 = d.claimed and T.GREEN or GOLD, Text = foot,
			Position = UDim2.new(0, 0, 1, -22), Size = UDim2.new(1, 0, 0, 16), ZIndex = 28,
		}, tile)
	end
	local mult = tonumber(state.weekMult) or 1
	dailyHud.streak.Text = ((state.streak or 0) > 0
		and (tostring(state.streak) .. " day streak - miss a day and it starts over")
		or "Come back tomorrow to build a streak")
		.. (mult > 1 and ("  |  gems x" .. tostring(math.floor(mult * 100 + 0.5) / 100) .. " this week") or "")
end

--[[
	PLAYTIME GIFTS. The server counts minutes played today; the client runs
	the clock forward between snapshots so the countdown is smooth, and only
	resyncs when the two drift apart.
]]
function ClientFns.syncPlaytime(payload)
	local pt = payload and payload.playtime
	local day = math.floor((tonumber(payload and payload.serverTime) or os.time()) / 86400)
	local server = (type(pt) == "table" and pt.day == day) and (tonumber(pt.secs) or 0) or 0
	local got = (type(pt) == "table" and pt.day == day) and (pt.got or {}) or {}
	local base = ClientFns.ptBase
	local est = base and (base.secs + (os.clock() - base.at)) or nil
	if not base or base.day ~= day or math.abs(est - server) > 20 then
		ClientFns.ptBase = { secs = server, at = os.clock(), got = got, day = day }
	else
		base.got = got
	end
end

function ClientFns.playtimeNow()
	local base = ClientFns.ptBase
	if not base then
		return 0, {}
	end
	return base.secs + (os.clock() - base.at), base.got or {}
end

function ClientFns.giftClock(secs)
	secs = math.max(0, math.floor(secs))
	return string.format("%d:%02d", math.floor(secs / 60), secs % 60)
end

function ClientFns.giftsPanel()
	if ClientFns.giftsCtl then
		return ClientFns.giftsCtl
	end
	local ctl = {}
	local W, H = 600, 388
	local frame = mk("Frame", {
		Name = "GiftsPanel", Visible = false, Active = true, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H), BackgroundColor3 = T.PANEL, ZIndex = 60,
	}, gui)
	round(frame, 16)
	stroke(frame, 2)
	panels.gifts = frame
	local sc = mk("UIScale", {}, frame)
	local function fit()
		local screen = gui.AbsoluteSize / math.max(0.05, uiScale.Scale)
		sc.Scale = math.clamp(math.min((screen.X - 24) / W, (screen.Y - 24) / H), 0.4, 1)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT, TextSize = 24, TextColor3 = GOLD, Text = "FREE GIFTS",
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(22, 14), Size = UDim2.new(1, -80, 0, 30), ZIndex = 61,
	}, frame)
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT_M, TextSize = 13, TextColor3 = MUTED,
		Text = "They open as you play. A new row every day (UTC).",
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(22, 44), Size = UDim2.new(1, -80, 0, 18), ZIndex = 61,
	}, frame)
	local close = mk("TextButton", {
		Text = "X", Font = FONT, TextSize = 18, TextColor3 = TEXT, BackgroundColor3 = T.CARD,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.fromOffset(36, 36), ZIndex = 62,
	}, frame)
	round(close, 8)
	close.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)
	local grid = mk("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 76), Size = UDim2.new(1, -40, 1, -92), ZIndex = 61,
	}, frame)
	mk("UIGridLayout", {
		CellSize = UDim2.fromOffset(131, 142), CellPadding = UDim2.fromOffset(9, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	local tiles = {}
	local zone = (snap and snap.maxUnlockedZone) or 1
	for i, g in ipairs(Quests.PLAYTIME or {}) do
		local tile = mk("Frame", { BackgroundColor3 = T.CARD, LayoutOrder = i, ZIndex = 62 }, grid)
		round(tile, 12)
		local st = stroke(tile, 1)
		local head = mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 15, TextColor3 = TEXT,
			Text = g.min .. " MIN", Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 18), ZIndex = 63,
		}, tile)
		local body = mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT_M, TextSize = 13, TextWrapped = true, TextColor3 = TEXT,
			TextYAlignment = Enum.TextYAlignment.Top, Text = "",
			Position = UDim2.fromOffset(6, 30), Size = UDim2.new(1, -12, 0, 62), ZIndex = 63,
		}, tile)
		local btn = mk("TextButton", {
			Font = FONT, TextSize = 14, Text = "", AutoButtonColor = true,
			AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -16, 0, 32), ZIndex = 63,
		}, tile)
		round(btn, 8)
		btn.MouseButton1Click:Connect(function()
			local secs, got = ClientFns.playtimeNow()
			if not got[tostring(i)] and secs >= g.min * 60 then
				btn.Text = "..."
				net:FireServer("claimPlaytime", { index = i })
			end
		end)
		tiles[i] = { tile = tile, stroke = st, head = head, body = body, btn = btn }
	end
	function ctl.paint()
		zone = (snap and snap.maxUnlockedZone) or zone
		local secs, got = ClientFns.playtimeNow()
		for i, g in ipairs(Quests.PLAYTIME or {}) do
			local t = tiles[i]
			local gems = Quests.playtimeGems(g.reward, zone)
			t.body.Text = Quests.describe(g.reward, gems > 0 and gems or nil):gsub("  %+  ", "\n")
			local taken = got[tostring(i)] and true or false
			local ready = not taken and secs >= g.min * 60
			t.tile.BackgroundTransparency = taken and 0.45 or 0
			t.stroke.Color = ready and T.GREEN or GOLD
			t.stroke.Transparency = ready and 0 or 0.5
			t.btn.Active = ready
			t.btn.AutoButtonColor = ready
			if taken then
				t.btn.Text = "OPENED"
				t.btn.BackgroundColor3 = T.DEAD
				t.btn.TextColor3 = MUTED
			elseif ready then
				if t.btn.Text ~= "..." then
					t.btn.Text = "OPEN"
				end
				t.btn.BackgroundColor3 = T.GREEN
				t.btn.TextColor3 = Color3.fromRGB(14, 40, 20)
			else
				t.btn.Text = ClientFns.giftClock(g.min * 60 - secs)
				t.btn.BackgroundColor3 = T.INK
				t.btn.TextColor3 = MUTED
			end
		end
	end
	function ctl.toggle(force)
		if frame.Visible and not force then
			frame.Visible = false
			return
		end
		hidePanels()
		fit()
		ctl.paint()
		frame.Visible = true
	end
	ctl.frame = frame
	ClientFns.giftsCtl = ctl
	return ctl
end

-- The gift button's clock and badge, and the open panel, twice a second.
function ClientFns.giftsLoop()
	if ClientFns.giftsLoopOn then
		return
	end
	ClientFns.giftsLoopOn = true
	task.spawn(function()
		while true do
			task.wait(0.5)
			local b = ClientFns.giftBtn
			if b then
				local secs, got = ClientFns.playtimeNow()
				local ready, nextLeft = 0, nil
				for i, g in ipairs(Quests.PLAYTIME or {}) do
					if not got[tostring(i)] then
						if secs >= g.min * 60 then
							ready += 1
						elseif not nextLeft then
							nextLeft = g.min * 60 - secs
						end
					end
				end
				b.badge.Visible = ready > 0
				b.badge.Text = tostring(ready)
				if ready > 0 then
					b.timeL.Text = "OPEN!"
					b.timeL.TextColor3 = T.GREEN
				elseif nextLeft then
					b.timeL.Text = ClientFns.giftClock(nextLeft)
					b.timeL.TextColor3 = TEXT
				else
					b.timeL.Text = "DONE"
					b.timeL.TextColor3 = MUTED
				end
			end
			local ctl = ClientFns.giftsCtl
			if ctl and ctl.frame.Visible then
				ctl.paint()
			end
		end
	end)
end

function ClientFns.pulseGifts()
	local b = ClientFns.giftBtn
	if not b then
		return
	end
	if ClientFns.UI then
		-- Shared FxScale channel, so it stacks with the button's press squash.
		local stop = ClientFns.UI.pulse(b.btn, 1.25, 0.9)
		task.delay(0.9 * 4, stop)
		return
	end
	local sc = b.btn:FindFirstChildOfClass("UIScale") or mk("UIScale", {}, b.btn)
	local tw = TweenService:Create(sc, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 8, true), { Scale = 1.25 })
	tw:Play()
end

--[[
	SETTINGS: sound switches, promo codes, invite friends, notifications and
	(while it is on offer) the starter bundle. Built the first time it opens.
]]
function ClientFns.applyPetGlowToWorld()
	-- Off by default; Shiny pets always keep their glow.
	local settingOn = ClientFns.petGlowEnabled == true
	local function applyModel(m)
		if not m then
			return
		end
		local on = settingOn or m:GetAttribute("Shiny") == true
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("PointLight") then
				d.Enabled = on
			end
		end
	end
	for _, m in ipairs(pets) do
		applyModel(m)
	end
	local by = ClientFns._otherPetByUser
	if type(by) == "table" then
		for _, rec in pairs(by) do
			for _, m in pairs(rec.models or {}) do
				applyModel(m)
			end
		end
	end
end

function ClientFns.applySettings(settings)
	settings = type(settings) == "table" and settings or {}
	local sfx, amb = settings.sfx ~= false, settings.ambience ~= false
	local petGlow = settings.petGlow == true
	ClientFns.simpleAbbrev = settings.simpleAbbrev == true
	pcall(function()
		local Ab = require(game.ReplicatedStorage.Mine.Shared:WaitForChild("MineAbbrev"))
		if Ab and Ab.setSimple then
			Ab.setSimple(ClientFns.simpleAbbrev)
		end
	end)
	local sort = settings.cardSort
	if type(sort) == "string" and CARD_SORT_OK[sort] and sort ~= cardSort then
		cardSort = sort
		if invCtl and invCtl.setCardSort then
			invCtl.setCardSort(sort)
		end
		if ClientFns.paintSortChips then
			ClientFns.paintSortChips()
		end
	end
	local st = ClientFns.soundState
	if st and st.sfx == sfx and st.amb == amb and ClientFns.petGlowEnabled == petGlow then
		return
	end
	ClientFns.soundState = { sfx = sfx, amb = amb }
	ClientFns.petGlowEnabled = petGlow
	pcall(Audio.setSfxEnabled, sfx)
	pcall(Audio.setAmbienceEnabled, amb)
	ClientFns.applyPetGlowToWorld()
	if ClientFns.settingsCtl then
		ClientFns.settingsCtl.paint()
	end
end

function ClientFns.settings()
	if ClientFns.settingsCtl then
		return ClientFns.settingsCtl
	end
	local ctl = {}
	local W, H = 440, 564
	local frame = mk("Frame", {
		Name = "SettingsPanel", Visible = false, Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(W, H), BackgroundColor3 = T.PANEL, ZIndex = 60,
	}, gui)
	round(frame, 16)
	stroke(frame, 2)
	panels.settings = frame
	-- MineUI already carries a UIScale (MineUiScale), so fit in its units --
	-- measuring the raw viewport would shrink the panel twice on a phone.
	local sc = mk("UIScale", {}, frame)
	local function fit()
		local screen = gui.AbsoluteSize / math.max(0.05, uiScale.Scale)
		sc.Scale = math.clamp(math.min((screen.X - 24) / W, (screen.Y - 24) / frame.Size.Y.Offset), 0.4, 1)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	local function label(text, size, color, y, h, font)
		return mk("TextLabel", {
			BackgroundTransparency = 1, Text = text, TextSize = size, TextColor3 = color,
			Font = font or FONT_M, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			Position = UDim2.fromOffset(22, y), Size = UDim2.new(1, -44, 0, h or 20), ZIndex = 61,
		}, frame)
	end
	label("SETTINGS", 22, GOLD, 16, 28, FONT)
	local close = mk("TextButton", {
		Text = "X", Font = FONT, TextSize = 18, TextColor3 = TEXT, BackgroundColor3 = T.CARD,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.fromOffset(36, 36), ZIndex = 62,
	}, frame)
	round(close, 8)
	close.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)

	-- SOUND
	label("SOUND", 13, MUTED, 60, 18, FONT)
	local toggles = {}
	local function toggleRow(y, text, key)
		label(text, 16, TEXT, y + 8, 22)
		local b = mk("TextButton", {
			Font = FONT, TextSize = 15, AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -22, 0, y), Size = UDim2.fromOffset(84, 36), ZIndex = 62,
		}, frame)
		round(b, 18)
		toggles[key] = b
		b.MouseButton1Click:Connect(function()
			local st = ClientFns.soundState or { sfx = true, amb = true }
			local on = not (st[key] ~= false)
			st[key] = on
			ClientFns.soundState = st
			-- The next snapshot or two can still carry the old value: ignore
			-- them briefly so the switch does not flicker back.
			ClientFns.settingsLocalAt = os.clock()
			if key == "sfx" then
				pcall(Audio.setSfxEnabled, on)
			else
				pcall(Audio.setAmbienceEnabled, on)
			end
			net:FireServer("setSetting", { key = (key == "sfx") and "sfx" or "ambience", value = on })
			ctl.paint()
		end)
	end
	toggleRow(84, "Sound effects", "sfx")
	toggleRow(128, "Ambience", "amb")

	-- VISUALS
	label("VISUALS", 13, MUTED, 182, 18, FONT)
	label("Pet glow", 16, TEXT, 214, 22)
	local petGlowBtn = mk("TextButton", {
		Font = FONT, TextSize = 15, AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -22, 0, 206), Size = UDim2.fromOffset(84, 36), ZIndex = 62,
	}, frame)
	round(petGlowBtn, 18)
	petGlowBtn.MouseButton1Click:Connect(function()
		local on = not (ClientFns.petGlowEnabled == true)
		ClientFns.petGlowEnabled = on
		ClientFns.settingsLocalAt = os.clock()
		ClientFns.applyPetGlowToWorld()
		net:FireServer("setSetting", { key = "petGlow", value = on })
		ctl.paint()
	end)

	label("Simple abbrev", 16, TEXT, 252, 22)
	local simpleAbbrevBtn = mk("TextButton", {
		Font = FONT, TextSize = 15, AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -22, 0, 244), Size = UDim2.fromOffset(84, 36), ZIndex = 62,
	}, frame)
	round(simpleAbbrevBtn, 18)
	simpleAbbrevBtn.MouseButton1Click:Connect(function()
		local on = not (ClientFns.simpleAbbrev == true)
		ClientFns.simpleAbbrev = on
		ClientFns.settingsLocalAt = os.clock()
		pcall(function()
			local Ab = require(game.ReplicatedStorage.Mine.Shared:WaitForChild("MineAbbrev"))
			if Ab and Ab.setSimple then Ab.setSimple(on) end
		end)
		net:FireServer("setSetting", { key = "simpleAbbrev", value = on })
		ctl.paint()
	end)

	-- CODES
	label("CODES", 13, MUTED, 294, 18, FONT)
	local box = mk("TextBox", {
		Font = FONT, TextSize = 17, TextColor3 = TEXT, PlaceholderText = "Enter a code", PlaceholderColor3 = MUTED,
		Text = "", ClearTextOnFocus = false, BackgroundColor3 = T.INK, TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(22, 318), Size = UDim2.new(1, -170, 0, 38), ZIndex = 62,
	}, frame)
	round(box, 8)
	mk("UIPadding", { PaddingLeft = UDim.new(0, 10) }, box)
	local redeem = mk("TextButton", {
		Text = "REDEEM", Font = FONT, TextSize = 15, TextColor3 = T.ON_GOLD, BackgroundColor3 = GOLD,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -22, 0, 318), Size = UDim2.fromOffset(120, 38), ZIndex = 62,
	}, frame)
	round(redeem, 8)
	local codeStatus = label("", 13, MUTED, 360, 18)
	local function submit()
		local code = tostring(box.Text or ""):gsub("%s", "")
		if code == "" then
			return
		end
		codeStatus.Text = "Checking..."
		codeStatus.TextColor3 = MUTED
		net:FireServer("redeemCode", { code = code })
	end
	redeem.MouseButton1Click:Connect(submit)
	box.FocusLost:Connect(function(enter)
		if enter then
			submit()
		end
	end)
	function ctl.codeResult(payload)
		codeStatus.Text = tostring(type(payload) == "table" and payload.msg or "")
		codeStatus.TextColor3 = (type(payload) == "table" and payload.ok) and T.GREEN or T.RED
		if type(payload) == "table" and payload.ok then
			box.Text = ""
		end
	end

	-- FRIENDS
	label("FRIENDS", 13, MUTED, 356, 18, FONT)
	local invite = mk("TextButton", {
		Text = "INVITE FRIENDS", Font = FONT, TextSize = 16, TextColor3 = Color3.fromRGB(14, 40, 20),
		BackgroundColor3 = T.GREEN, Position = UDim2.fromOffset(22, 380), Size = UDim2.new(1, -44, 0, 40), ZIndex = 62,
	}, frame)
	round(invite, 8)
	label("A friend who joins from your invite gets a pack, and so do you.", 12, MUTED, 424, 18)
	invite.MouseButton1Click:Connect(function()
		local social = game:GetService("SocialService")
		local ok, can = pcall(function()
			return social:CanSendGameInviteAsync(player)
		end)
		if ok and can then
			pcall(function()
				social:PromptGameInvite(player)
			end)
		else
			showToast("Invites aren't available right now")
		end
	end)

	-- NOTIFICATIONS
	label("NOTIFICATIONS", 13, MUTED, 458, 18, FONT)
	local notify = mk("TextButton", {
		Text = "NOTIFY ME", Font = FONT, TextSize = 16, TextColor3 = TEXT, BackgroundColor3 = T.CARD,
		Position = UDim2.fromOffset(22, 482), Size = UDim2.new(1, -44, 0, 40), ZIndex = 62,
	}, frame)
	round(notify, 8)
	stroke(notify, 1)
	notify.MouseButton1Click:Connect(function()
		local ens = game:GetService("ExperienceNotificationService")
		local ok, can = pcall(function()
			return ens:CanPromptOptInAsync()
		end)
		if ok and can then
			pcall(function()
				ens:PromptOptIn()
			end)
		else
			showToast("Notifications are already on, or not available for you")
		end
	end)

	-- STARTER BUNDLE, while it is on offer
	local starter = mk("TextButton", {
		Text = "", Font = FONT, TextSize = 16, TextColor3 = T.ON_GOLD, BackgroundColor3 = GOLD,
		Position = UDim2.fromOffset(22, 536), Size = UDim2.new(1, -44, 0, 40), Visible = false, ZIndex = 62,
	}, frame)
	round(starter, 8)
	starter.MouseButton1Click:Connect(function()
		frame.Visible = false
		ClientFns.offerStarter(true)
	end)

	function ctl.paint()
		local st = ClientFns.soundState or { sfx = true, amb = true }
		for key, b in pairs(toggles) do
			local on = st[key] ~= false
			b.Text = on and "ON" or "OFF"
			b.BackgroundColor3 = on and T.GREEN or T.DEAD
			b.TextColor3 = on and Color3.fromRGB(14, 40, 20) or MUTED
		end
		do
			local on = ClientFns.petGlowEnabled == true
			petGlowBtn.Text = on and "ON" or "OFF"
			petGlowBtn.BackgroundColor3 = on and T.GREEN or T.DEAD
			petGlowBtn.TextColor3 = on and Color3.fromRGB(14, 40, 20) or MUTED
		end
		do
			local on = ClientFns.simpleAbbrev == true
			simpleAbbrevBtn.Text = on and "ON" or "OFF"
			simpleAbbrevBtn.BackgroundColor3 = on and T.GREEN or T.DEAD
			simpleAbbrevBtn.TextColor3 = on and Color3.fromRGB(14, 40, 20) or MUTED
		end
		local prod = C.product and C.product("starter_bundle")
		local can = prod and (tonumber(prod.productId) or 0) > 0 and not (snap and snap.starterBought)
			and player:GetAttribute("PolicyNoRandom") ~= true
		starter.Visible = can and true or false
		if can then
			starter.Text = "STARTER BUNDLE  |  R$" .. tostring(prod.robuxPrice or "")
		end
		frame.Size = UDim2.fromOffset(W, can and H or (H - 52))
		fit()
	end
	function ctl.toggle()
		if frame.Visible then
			frame.Visible = false
			return
		end
		hidePanels()
		ctl.paint()
		frame.Visible = true
	end
	ClientFns.settingsCtl = ctl
	return ctl
end

function ClientFns.codeResult(payload)
	ClientFns.settings().codeResult(payload)
	if type(payload) == "table" and payload.msg then
		showToast(payload.msg)
	end
end

--[[
	STARTER BUNDLE: a one-time offer, shown right after the first pack is
	opened (the server says when) and reachable from Settings after that.
	Never shown without a product id, once bought, or to a player whose rules
	restrict paid random items -- its packs are random.
]]
function ClientFns.offerStarter(force)
	local prod = C.product and C.product("starter_bundle")
	local pid = prod and tonumber(prod.productId) or 0
	if pid <= 0 or (snap and snap.starterBought) or player:GetAttribute("PolicyNoRandom") == true then
		return
	end
	if ClientFns.starterShown and not force then
		return
	end
	ClientFns.starterShown = true
	local old = gui:FindFirstChild("StarterOffer")
	if old then
		old:Destroy()
	end
	local W, H = 480, 340
	local frame = mk("Frame", {
		Name = "StarterOffer", Active = true, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H), BackgroundColor3 = T.PANEL, ZIndex = 90,
	}, gui)
	round(frame, 18)
	stroke(frame, 3).Transparency = 0
	local sc = mk("UIScale", {}, frame)
	do
		local screen = gui.AbsoluteSize / math.max(0.05, uiScale.Scale)
		sc.Scale = math.clamp(math.min((screen.X - 24) / W, (screen.Y - 24) / H), 0.4, 1)
	end
	mk("TextLabel", {
		BackgroundTransparency = 1, Text = "STARTER BUNDLE", Font = FONT, TextSize = 28, TextColor3 = GOLD,
		Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 34), ZIndex = 91,
	}, frame)
	mk("TextLabel", {
		BackgroundTransparency = 1, Text = "One time only, for new miners", Font = FONT_M, TextSize = 15,
		TextColor3 = MUTED, Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 0, 20), ZIndex = 91,
	}, frame)
	local row = mk("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 82), Size = UDim2.new(1, -40, 0, 132), ZIndex = 91,
	}, frame)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	for i, r in ipairs(prod.packs or {}) do
		local cell = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(96, 132), LayoutOrder = i, ZIndex = 91 }, row)
		local art = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(96, 110), ZIndex = 92 }, cell)
		pcall(PackFX.drawSealed, art, r.id, 84, 104)
		local drawn = art:FindFirstChild("MiniPack")
		if drawn then
			drawn.AnchorPoint = Vector2.new(0.5, 0.5)
			drawn.Position = UDim2.fromScale(0.5, 0.5)
		end
		mk("TextLabel", {
			BackgroundTransparency = 1, Text = "x" .. tostring(r.qty or 1), Font = FONT, TextSize = 18, TextColor3 = TEXT,
			Position = UDim2.fromOffset(0, 110), Size = UDim2.new(1, 0, 0, 22), ZIndex = 93,
		}, cell)
	end
	if (tonumber(prod.gems) or 0) > 0 then
		local cell = mk("Frame", { BackgroundColor3 = T.CARD, Size = UDim2.fromOffset(96, 110), LayoutOrder = 99, ZIndex = 91 }, row)
		round(cell, 12)
		mk("TextLabel", {
			BackgroundTransparency = 1, Text = "+" .. tostring(prod.gems) .. "\nGEMS", Font = FONT, TextSize = 20,
			TextColor3 = T.GEM, Size = UDim2.fromScale(1, 1), ZIndex = 92,
		}, cell)
	end
	local buy = mk("TextButton", {
		Text = "BUY  |  R$" .. tostring(prod.robuxPrice or ""), Font = FONT, TextSize = 20,
		TextColor3 = Color3.fromRGB(14, 40, 20), BackgroundColor3 = T.GREEN, AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 228), Size = UDim2.fromOffset(260, 50), ZIndex = 92,
	}, frame)
	round(buy, 12)
	local later = mk("TextButton", {
		Text = "Maybe later", Font = FONT_M, TextSize = 15, TextColor3 = MUTED, BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 288), Size = UDim2.fromOffset(200, 32), ZIndex = 92,
	}, frame)
	buy.MouseButton1Click:Connect(function()
		pcall(function()
			MarketplaceService:PromptProductPurchase(player, pid)
		end)
	end)
	later.MouseButton1Click:Connect(function()
		frame:Destroy()
	end)
	ClientFns.starterCtl = {
		close = function()
			if frame.Parent then
				frame:Destroy()
			end
		end,
	}
end

--[[
	OTHER PLAYERS' PETS. The server publishes each player's equipped pets as a
	small JSON attribute (PetsJSON); every client builds them from it and has
	them follow their owner, so a shiny or shadow pet is seen by everyone.
	To keep phones smooth only the six nearest players within 120 studs get
	their pets drawn (18 models at most); everyone else's are parked.
]]
function ClientFns.othersPets()
	if ClientFns.othersPetsOn then
		return
	end
	ClientFns.othersPetsOn = true
	local http = game:GetService("HttpService")
	local byUser = {}
	ClientFns._otherPetByUser = byUser
	local function clear(uid)
		local rec = byUser[uid]
		if rec then
			local st = ClientFns._petFollowState
			for _, m in pairs(rec.models) do
				if st then
					st[m] = nil
				end
				m:Destroy()
			end
		end
		byUser[uid] = nil
	end
	local function rebuild(other)
		if other == player then
			return
		end
		local json = other:GetAttribute("PetsJSON")
		local rec = byUser[other.UserId]
		if rec and rec.json == json then
			return
		end
		clear(other.UserId)
		rec = { json = json, models = {}, plr = other }
		byUser[other.UserId] = rec
		local ok, list = pcall(function()
			return http:JSONDecode(json or "[]")
		end)
		if not ok or type(list) ~= "table" then
			return
		end
		for i, c in ipairs(list) do
			if i > 3 then
				break
			end
			local okB, m = pcall(PetFactory.fromCard, {
				name = c.n, animal = c.a, typeId = c.t, variant = c.v, rarityId = c.r, species = c.sp,
				shiny = c.s == 1, shadow = c.d == 1,
			})
			if okB and m then
				for _, d in ipairs(m:GetDescendants()) do
					if d:IsA("BasePart") then
						d.CanCollide = false
						d.CanQuery = false
						d.CanTouch = false
					end
					if d:IsA("PointLight") then
						d.Enabled = ClientFns.petGlowEnabled == true or m:GetAttribute("Shiny") == true
					end
				end
				rec.models[i] = m
			end
		end
	end
	local function watch(other)
		if other == player then
			return
		end
		other:GetAttributeChangedSignal("PetsJSON"):Connect(function()
			rebuild(other)
		end)
		rebuild(other)
	end
	for _, o in ipairs(Players:GetPlayers()) do
		watch(o)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(o)
		clear(o.UserId)
	end)
	local allowed, pickedAt = {}, 0
	RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		if now - pickedAt > 0.5 then
			pickedAt = now
			local cam = workspace.CurrentCamera
			local camPos = cam and cam.CFrame.Position
			local near = {}
			for uid, rec in pairs(byUser) do
				local r = rec.plr.Character and rec.plr.Character:FindFirstChild("HumanoidRootPart")
				local d = r and camPos and (r.Position - camPos).Magnitude
				if d and d < 120 and next(rec.models) then
					near[#near + 1] = { uid = uid, d = d }
				end
			end
			table.sort(near, function(a, b)
				return a.d < b.d
			end)
			table.clear(allowed)
			for k = 1, math.min(6, #near) do
				allowed[near[k].uid] = true
			end
		end
		for uid, rec in pairs(byUser) do
			local root = allowed[uid] and rec.plr.Character and rec.plr.Character:FindFirstChild("HumanoidRootPart")
			for i, m in pairs(rec.models) do
				if root then
					if not m.Parent then
						m.Parent = workspace
						local st = ClientFns._petFollowState
						if st then
							st[m] = nil
						end
						-- Same centring as the follow step, or a pet pops in
						-- off-formation and then slides across to its place.
						local n = 0
						for _ in pairs(rec.models) do
							n += 1
						end
						m:PivotTo(root.CFrame
							* CFrame.new((i - (math.max(1, n) + 1) / 2) * 2.15, 0.04, 3.2))
					end
					local n = 0
					for _ in pairs(rec.models) do
						n += 1
					end
					ClientFns.stepPetFollow(m, root, i, now, dt, n)
					if m:GetAttribute("Variant") == "Rainbow" then
						PetFactory.animateChroma(m, now)
					end
				elseif m.Parent then
					local st = ClientFns._petFollowState
					if st then
						st[m] = nil
					end
					m.Parent = nil
				end
			end
		end
	end)
end

-- The trade screens (MineTradeView), mounted the first time they are needed.
function ClientFns.tradeView()
	if ClientFns.tradeCtl then
		return ClientFns.tradeCtl
	end
	ClientFns.tradeCtl = require(shared:WaitForChild("MineTradeView")).mount(gui, {
		net = net,
		getSnap = function()
			return snap
		end,
		paintCard = function(parent, card, w)
			return paintCard(parent, card, w)
		end,
	})
	return ClientFns.tradeCtl
end

-- A copy of one inventory stack, so the screen can change it freely.
function ClientFns.luckyStack(g)
	return {
		key = g.key,
		uid = g.uid,
		firstIndex = g.firstIndex,
		blockId = g.blockId,
		startGrade = g.startGrade or "F",
		bought = g.bought or 0,
		count = g.count or 1,
		luck = g.luck,
	}
end

-- Job Board UI (on depthHud to avoid another top-level local).
depthHud.contractor = require(shared:WaitForChild("MineContractor")).mount(gui, {
	onClaimContract = function(index)
		net:FireServer("claimContract", { index = index })
	end,
	-- The board carries every quest now, so it needs every claim verb.
	onClaimDailyQuest = function(index)
		net:FireServer("claimDailyQuest", { index = index })
	end,
	onClaimQuest = function()
		net:FireServer("claimQuest")
	end,
	onClaimMilestone = function(id)
		net:FireServer("claimMilestone", { id = id })
	end,
	onClaimDaily = function()
		net:FireServer("claimDaily")
	end,
})

local Scrolls = require(shared:WaitForChild("MineScrolls"))
shopCtl = ShopView.mount(gui, {
	--[[
		The Forge reports the skin and rune on the selected tool's family and
		sends you to the Enchanter to change either, rather than growing a second
		copy of those two screens. routePanel hides the shop on the way, so this
		is a jump and not an overlay.
	]]
	onOpenEnchanter = function(tab)
		if ClientFns.teleportToEnchanter then
			ClientFns.teleportToEnchanter()
		end
		ClientFns.routePanel("enchanter", tostring(tab or "sockets"))
	end,
	onBuyTool = function(family, tier, toolId)
		if toolId then
			net:FireServer("buyTool", { toolId = toolId, family = family, tier = tier })
		else
			net:FireServer("buyTool", { family = family, tier = tier })
		end
	end,
	onEquipShopTool = function(id) net:FireServer("equipShopTool", { id = id }) end,
	onEquipChestTool = function(id) net:FireServer("equipChestTool", { id = id }) end,
	-- The shop shows the family's temperament and can swap it for another you own.
	onFitTemper = function(payload) net:FireServer("equipTemper", payload) end,
	onBuyBackpack = function(tier)
		net:FireServer("buy", { what = "backpack", tier = tier })
	end,
	onBuyProductCredits = function(key) net:FireServer("buyProductCredits", { key = key }) end,
	onEquip = function(family, tier) net:FireServer("equipTool", { family = family, tier = tier }) end,
	onToast = function(msg) showToast(tostring(msg)) end,
	onBuyCreditPack = function(packId)
		local pack = Scrolls.packById(packId)
		local pid = pack and (tonumber(pack.productId) or 0) or 0
		if pid > 0 then
			MarketplaceService:PromptProductPurchase(player, pid)
		else
			net:FireServer("buyCreditPack", { packId = packId })
		end
	end,
	onBuyScroll = function(id, bundle)
		net:FireServer("buyScroll", { id = id, bundle = bundle and true or nil })
	end,
	--[[
		The blacksmith bench.

		Both verbs take a UID, never a row index: the list reorders whenever a
		tool is found or scrapped, and an index captured when the panel was drawn
		names a different tool by the time the button is pressed. Levels are a
		count, and the server clamps it to what is left below the cap.
	]]
	--[[
		The Forge. Three ids and nothing else: the server re-derives the recipe
		and the price from the roster and MineConfig, so a modified client can
		ask for a different tool but never for a different cost, and never for
		an ore it is not holding.
	]]
	-- Equip a forged ore tool, or unequip with no uid. The server re-gives the
	-- Tool instance and stamps its breaking power.
	onEquipOreTool = function(uid)
		net:FireServer("equipOreTool", { uid = uid })
	end,
	onCraftOreTool = function(familyId, typeId, oreId)
		net:FireServer("craftOreTool", { familyId = familyId, typeId = typeId, oreId = oreId })
	end,
	onUpgradeOreTool = function(uid, count)
		net:FireServer("upgradeOreTool", { uid = uid, count = count })
	end,
	onRecycleOreTool = function(uid)
		net:FireServer("recycleOreTool", { uid = uid })
	end,
	-- An empty uid unequips; the server treats re-sending the held uid the same
	-- way, so the button can be a straight toggle.
	onEquipOreTool = function(uid)
		net:FireServer("equipOreTool", { uid = uid or "" })
	end,

	--[[
		THE ORE POUCH. Selling ore is the game's only gem tap, so every one of
		these is server-authoritative: the client names what to do and never how
		much it is worth.

		Sell All goes out twice. The first call carries no confirm flag and is
		the ASK -- the server prices the sale and replies with `confirmSellAll`,
		which opens the dialog on the server's own figures. The second carries
		confirm and performs it.
	]]
	onUpgradeOrePouch = function()
		net:FireServer("upgradeOrePouch")
	end,
	onToggleOreLock = function(oreId)
		net:FireServer("toggleOreLock", { oreId = oreId })
	end,
	onSellOre = function(oreId, count)
		net:FireServer("sellOre", { oreId = oreId, count = count })
	end,
	onSellAllOres = function(confirm)
		net:FireServer("sellAllOres", { confirm = confirm and true or nil })
	end,
})

depthShopCtl = DepthShopView.mount(gui, {
	onBuy = function(row, desk)
		if type(row) == "table" then
			net:FireServer("buyDepthTool", {
				id = row.id,
				family = row.family,
				seam = row.seam,
				desk = row.desk,
				zoneId = row.zoneId,
			})
		else
			net:FireServer("buyDepthTool", { toolId = row, desk = desk })
		end
	end,
})

local elevFrame = Instance.new("Frame")
elevFrame.Name = "ElevatorPick"
elevFrame.Visible = false
elevFrame.AnchorPoint = Vector2.new(0.5, 0.5)
elevFrame.Position = UDim2.fromScale(0.5, 0.5)
elevFrame.Size = UDim2.fromOffset(320, 420)
elevFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
elevFrame.BorderSizePixel = 0
elevFrame.ZIndex = 90
elevFrame.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = elevFrame
end
local elevTitle = Instance.new("TextLabel")
elevTitle.BackgroundTransparency = 1
elevTitle.Size = UDim2.new(1, -24, 0, 36)
elevTitle.Position = UDim2.fromOffset(12, 10)
elevTitle.Font = Enum.Font.GothamBold
elevTitle.TextSize = 20
elevTitle.TextColor3 = Color3.fromRGB(240, 236, 220)
elevTitle.TextXAlignment = Enum.TextXAlignment.Left
elevTitle.Text = "Mineshaft"
elevTitle.ZIndex = 91
elevTitle.Parent = elevFrame
local elevClose = Instance.new("TextButton")
elevClose.Size = UDim2.fromOffset(36, 36)
elevClose.Position = UDim2.new(1, -44, 0, 8)
elevClose.BackgroundColor3 = Color3.fromRGB(50, 40, 40)
elevClose.Text = "X"
elevClose.TextColor3 = Color3.fromRGB(255, 200, 200)
elevClose.Font = Enum.Font.GothamBold
elevClose.TextSize = 18
elevClose.ZIndex = 92
elevClose.Parent = elevFrame
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = elevClose end
elevClose.MouseButton1Click:Connect(function() elevFrame.Visible = false end)
local elevScroll = Instance.new("ScrollingFrame")
elevScroll.Name = "Floors"
elevScroll.BackgroundTransparency = 1
elevScroll.Position = UDim2.fromOffset(12, 52)
elevScroll.Size = UDim2.new(1, -24, 1, -64)
elevScroll.ScrollBarThickness = 6
elevScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
elevScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
elevScroll.ZIndex = 91
elevScroll.Parent = elevFrame
do
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 8)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = elevScroll
end
elevCtl = {
	root = elevFrame,
	open = function(payload)
		payload = type(payload) == "table" and payload or {}
		local deepest = tonumber(payload.deepest) or 0
		local zoneId = tostring(payload.zoneId or "")
		local floors = payload.floors or { 0 }
		for _, ch in ipairs(elevScroll:GetChildren()) do
			if ch:IsA("TextButton") then ch:Destroy() end
		end
		for i, seam in ipairs(floors) do
			seam = tonumber(seam) or 0
			local unlocked = seam <= 0 or deepest >= seam
			local btn = Instance.new("TextButton")
			btn.Name = "Floor_" .. tostring(seam)
			btn.Size = UDim2.new(1, -4, 0, 40)
			btn.BackgroundColor3 = unlocked and Color3.fromRGB(48, 92, 58) or Color3.fromRGB(40, 40, 46)
			btn.TextColor3 = unlocked and Color3.fromRGB(230, 255, 230) or Color3.fromRGB(140, 140, 150)
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 16
			btn.AutoButtonColor = unlocked
			btn.LayoutOrder = i
			btn.ZIndex = 92
			btn.Text = (seam <= 0) and "Surface" or ("Depth " .. tostring(seam) .. (unlocked and "" or "  (locked)"))
			btn.Parent = elevScroll
			do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = btn end
			if unlocked then
				local sCopy, zCopy = seam, zoneId
				btn.MouseButton1Click:Connect(function()
					elevFrame.Visible = false
					net:FireServer("rideElevator", { seam = sCopy, zoneId = zCopy })
				end)
			end
		end
		hidePanels()
		elevFrame.Visible = true
	end,
	close = function()
		elevFrame.Visible = false
	end,
}

forgeCtl = ForgeView.mount(gui, {
	onRoll = function(id) net:FireServer("rollTemper", { id = id }) end,
	onRollFamily = function(family) net:FireServer("rollTemper", { family = family }) end,
	onEquip = function(id) net:FireServer("equipChestTool", { id = id }) end,
	-- The case is the way in: temper tokens from rebirth and salvaged forever tools.
	onOpenCase = function() net:FireServer("openTemperCase") end,
	onOpenCaseBundle = function() net:FireServer("openTemperCaseBundle") end,
	onFitTemper = function(payload) net:FireServer("equipTemper", payload) end,
	onScrapTemper = function(payload) net:FireServer("scrapTemper", payload) end,
})

--[[
	THE GAME'S OWN HOTBAR, in place of Roblox's.

	Owner, 2026-10-05: "remove the real pickaxe from my hotbar. and make a
	fake/custom hotbar, that allows me to equip and unequip as i please, without
	having that weird grey cube".

	The grey cube is the core Backpack UI drawing a Tool that has no TextureId.
	MineHotbar switches that UI off and draws the bar out of MineIcons instead,
	so the slots carry the same art as every other panel. Equip and unequip are
	one verb: equipOreTool already reads an empty uid as "put it away", so
	clicking the slot you are holding IS the unequip.
]]
do
	local okHB, HB = pcall(function()
		return require(shared:WaitForChild("MineHotbar"))
	end)
	if okHB and HB and HB.mount then
		local okM, ctl = pcall(HB.mount, gui, {
			getSnap = function()
				return snap or {}
			end,
			onEquip = function(uid)
				net:FireServer("equipOreTool", { uid = uid })
			end,
		})
		if okM then
			ClientFns.hotbarCtl = ctl
		end
	end
end

eventsCtl = require(shared:WaitForChild("MineEventsView")).mount(gui, {
	config = C,
	onClaim = function(zoneId)
		net:FireServer("buyZone", zoneId)
	end,
})

groupWheelCtl = require(shared:WaitForChild("MineGroupWheelView")).mount(gui, {
	net = net,
	getGroupId = function()
		return tonumber(C.GROUP_ID) or 0
	end,
})

-- mount() hands back a controller; the Frame is controller.root. Binding the
-- controller straight to skillP is what left the wheel permanently open.
skillCtl = SkillView.mount(gui, {
	FONT = FONT, FONT_M = FONT_M, BG = BG, BG2 = BG2, GOLD = GOLD, TEXT = TEXT, MUTED = MUTED,
	state = { levels = {}, tokens = 0, rebirth = 0, preset = 1 },
	inClouds = false,
	-- Where this character is standing, by the same rule the server enforces.
	inCloudsCheck = function() return C.playerInClouds(player) end,
	onBuy = function(id) net:FireServer("skillBuy", id) end,
	onPreset = function(i) net:FireServer("skillPreset", i) end,
	-- Buy the second preset slot, 25 skill points, in the Clouds.
	-- Verbs.skillBuySlot was complete and dispatched with no caller, so the
	-- padlock on that button was decorative.
	onBuyPresetSlot = function() net:FireServer("skillBuySlot") end,
	onReset = function() net:FireServer("skillReset") end,
	onSell = function() net:FireServer("skillSell") end,
	onBuyBack = function() net:FireServer("skillBuyBack") end,
	-- The wheel stays open on the way up, so you watch it unlock.
	onGoClouds = function() net:FireServer("goClouds") end,
	onAscend = function()
		if skillP then skillP.Visible = false end
		net:FireServer("returnSurface")
	end,
})
skillP = skillCtl.root
skillP.Visible = false
panels.Skills = skillP
-- Push the newest state in, then optionally show. Every path that opens the
-- wheel goes through this, so none of them can present a stale token count.
applySkills = function(show)
	if skillCtl and skillLatest then
		skillCtl.setOpts(skillLatest)
	end
	if show and skillP then
		skillP.Visible = true
	end
end

-- Cap every window now that they all exist. The wide ones earn more room:
-- a card grid and a shop carousel have something to put in it, a list of rows
-- does not.
local WIDE = { Cards = true, Merge = true, Inventory = true, ShopPanel = true,
	Enchanter = true }
for name, f in pairs(panels) do
	-- A full-screen overlay is not a window. The skill wheel is a radial menu
	-- drawn across the whole viewport with its own scrim; capping it to a
	-- dialog-sized box would fold the wheel in on itself.
	local fullscreen = f.Size.X.Scale >= 0.999 and f.Size.Y.Scale >= 0.999
	if fullscreen then
		-- leave it alone
	elseif WIDE[name] then
		capPanel(f, 1280, 860)
	else
		capPanel(f, 900, 720)
	end
end
-- Same rule as the loop: a controller root that is already full-bleed is not a
-- window and must not be boxed. The shop is deliberately fullscreen.
function ClientFns.capIfWindow(f, x, y)
	if not f then
		return
	end
	if f.Size.X.Scale >= 0.999 and f.Size.Y.Scale >= 0.999 then
		local existing = f:FindFirstChildOfClass("UISizeConstraint")
		if existing then
			existing:Destroy()
		end
		return
	end
	capPanel(f, x, y)
end
ClientFns.capIfWindow(invCtl and invCtl.root, 1280, 860)
ClientFns.capIfWindow(shopCtl and shopCtl.root, 1280, 860)

--[[
	The pack reveal. It lives in its own ScreenGui so it can cover the open
	inventory instead of replacing it, and so a tap during the ceremony means
	"faster" rather than "close" -- see MinePackReveal for the sequence.
]]
revealCtl = require(shared:WaitForChild("MinePackReveal")).mount(player:WaitForChild("PlayerGui"), {
	paintCard = function(parent, card, w) return paintCard(parent, card, w) end,
	-- Another run without leaving the reveal: the packs flow one into the next.
	onOpenMore = function(packId, count)
		-- Must name the stack. A nil/blank id would open whatever is cheapest
		-- in the bag and attribute the previous open-all count to it.
		if type(packId) ~= "string" or packId == "" or packId == "bulk_hits" then
			return
		end
		armPackRevealBusy()
		net:FireServer("openMany", { packId = packId, count = count })
	end,
	-- Out of packs is not a dead end. Straight to the shelf that sells them.
	onStore = function()
		if invCtl then
			invCtl.open("shop", "packs")
		end
	end,
	onDone = function()
		clearPackRevealBusy()
	end,
	-- An empty pack is a bug worth surfacing in the game's own voice, rather
	-- than leaving the player on a black scrim wondering what happened.
	onToast = function(text)
		showToast(tostring(text))
	end,
	--[[
		The reveal gets the whole screen.

		MineUI carries the wallet, the depth chip and the right-hand button
		rail, and all of it was drawing over the pack -- the rip looked like a
		busy screenshot instead of one object in frame. Disabling the ScreenGui
		hides the chrome without touching any of its state, so the inventory is
		still open, still on the same tab and still scrolled where it was when
		the reveal hands the screen back.
	]]
	onScreenOwned = function(owned)
		gui.Enabled = not owned
	end,
})
-- If a reveal dies without onDone (empty run race, error, desync), unlock after ~30s.
task.spawn(function()
	while true do
		task.wait(5)
		if packRevealBusy and packRevealBusyAt > 0 and (os.clock() - packRevealBusyAt) >= PACK_REVEAL_WATCHDOG_SEC then
			local stillBusy = revealCtl and revealCtl.isBusy and revealCtl.isBusy()
			if not stillBusy then
				clearPackRevealBusy()
			else
				-- Ceremony still running: slide the timer so a long open-all is not cut off.
				packRevealBusyAt = os.clock()
			end
		end
	end
end)

--[[
	A RARE FIND IS A PACK YOU DID NOT HAVE TO BUY.

	Chest tools, charms and the bonkers packs used to get a flat full-screen
	caption. They go through the same rip as a bought pack now: a meadow
	wrapper, the stack, the flip, the screen reacting in proportion to what it
	is. The difference is that the player never has to press anything. It plays
	itself, and tapping only makes it go faster (MinePackReveal `auto`).

	`oneIn` arrives only when the find is actually rare; the server works it out
	from the odds that rolled it. `oddsForm` (or the server's rarity) sets how
	loud the screen gets.
]]
function ClientFns.foundReveal(payload)
	if type(payload) ~= "table" or not revealCtl then
		return
	end
	pcall(Audio.playFound, payload.oneIn or payload.oddsForm)
	local kind = tostring(payload.kind or "tool")
	if kind == "pet" then
		-- A chase pet was already the last card of the pack it came out of.
		return
	end
	local oneIn = tonumber(payload.oneIn)
	local form = tonumber(payload.oddsForm) or oneIn
	local rarity = payload.rarityId
	if not rarity then
		rarity = (form and ((form >= 100000 and "Exotic") or (form >= 10000 and "Divine")
			or (form >= 1000 and "Mythic") or (form >= 150 and "Legendary")
			or (form >= 20 and "Epic") or "Rare")) or "Legendary"
	end
	--[[
		A FINISH IS A RARITY TOO.
	
		pullScore ranks off rarityId alone, so a NIGHTMARE Rare scored exactly
		the same HIT as a plain Rare -- and a nightmare is shiny x shadow x
		nightmare on top of the base drop, four orders of magnitude rarer. The
		one pull most worth celebrating was the one that celebrated least.
	
		Promote the grade it reports instead of touching pullScore, which packs
		and charms also run through.
	]]
	local FINISH_BUMP = { "Common", "Uncommon", "Rare", "Epic",
		"Legendary", "Mythic", "Divine", "Exotic" }
	do
		local step = (payload.nightmare and 3) or (payload.shadow and 2)
			or (payload.shiny and 1) or 0
		if step > 0 then
			local at = 0
			for n, nm in ipairs(FINISH_BUMP) do
				if nm == rarity then
					at = n
					break
				end
			end
			if at > 0 then
				rarity = FINISH_BUMP[math.min(#FINISH_BUMP, at + step)]
			end
		end
	end
	local item = {
		kind = (kind == "bundle") and "pack" or kind,
		name = tostring(payload.name or "???"),
		rarityId = rarity,
		baseName = payload.baseName,
		family = payload.family,
		power = payload.power,
		shiny = payload.shiny or nil,
		shadow = payload.shadow or nil,
		nightmare = payload.nightmare or nil,
		packId = payload.packId,
		charmId = payload.charmId,
		oneIn = oneIn,
		oddsForm = form,
		sub = payload.blurb,
	}
	local TITLE = { tool = "RARE FIND", charm = "CHARM", pack = "BONKERS PACK", bundle = "PROTOTYPE CRATE" }
	local wrapper = {
		-- Every find gets the good ceremony. A charm always played the legendary
		-- reveal; a TOOL only got it when `oneIn` happened to be set, so most tool
		-- finds fell back to the plain wrapper and landed with no weight at all.
		-- Rarity already shows in the card itself -- the animation is the moment.
		packId = "meadow_pack_legendary",
		name = tostring(payload.title or TITLE[kind] or "RARE FIND"),
		setName = (kind == "charm") and "Meadow  |  charm" or "Meadow  |  chest find",
		cards = { item },
	}
	task.spawn(function()
		-- A pack open in flight answers with its cards right behind this
		-- (open 10 rolls the tool before it sends the run): let them land
		-- first, so the find plays after the pack it came out of.
		local t0 = os.clock()
		while packRevealBusy and not (revealCtl.isBusy and revealCtl.isBusy()) and os.clock() - t0 < 1.5 do
			task.wait()
		end
		revealCtl.play({ wrapper }, { auto = true })
	end)
end

local hover = mk("BillboardGui", {
	Name = "BlockHover",
	AlwaysOnTop = true,
	Size = UDim2.fromOffset(200, 86),
	StudsOffset = Vector3.new(0, 3.4, 0),
	Enabled = false,
}, gui)
local hoverFrame = mk("Frame", { BackgroundColor3 = BG, BackgroundTransparency = 0.08, Size = UDim2.fromScale(1, 1) }, hover)
round(hoverFrame, 8)
stroke(hoverFrame)
local hoverName = mk("TextLabel", { BackgroundTransparency = 1, Font = FONT, TextSize = 16, TextColor3 = TEXT, Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 0, 22), Text = "Dirt" }, hoverFrame)
local hoverHp = mk("TextLabel", { BackgroundTransparency = 1, Font = FONT_M, TextSize = 13, TextColor3 = MUTED, Position = UDim2.fromOffset(8, 24), Size = UDim2.new(1, -16, 0, 16), Text = "HP 1/1" }, hoverFrame)
local hpTrack = mk("Frame", { BackgroundColor3 = BG2, Position = UDim2.fromOffset(8, 44), Size = UDim2.new(1, -16, 0, 8) }, hoverFrame)
round(hpTrack, 4)
local hpFill = mk("Frame", { BackgroundColor3 = Color3.fromRGB(90, 210, 120), Size = UDim2.fromScale(1, 1) }, hpTrack)
round(hpFill, 4)
local swingTrack = mk("Frame", { BackgroundColor3 = BG2, Position = UDim2.fromOffset(8, 58), Size = UDim2.new(1, -16, 0, 8) }, hoverFrame)
round(swingTrack, 4)
local swingFill = mk("Frame", { BackgroundColor3 = GOLD, Size = UDim2.fromScale(0, 1) }, swingTrack)
round(swingFill, 4)
mk("TextLabel", { BackgroundTransparency = 1, Font = FONT_M, TextSize = 10, TextColor3 = MUTED, Position = UDim2.fromOffset(8, 68), Size = UDim2.new(1, -16, 0, 14), Text = "Swing" }, hoverFrame)

function ClientFns.variantGrad(parent, variant)
	if variant == "Normal" or not parent then
		return
	end
	-- Golden / Prism / Rainbow: coloured card OUTLINE only (3D keeps original skin).
	if variant == "Golden" or variant == "Prism" or variant == "Rainbow" then
		local rim = parent:FindFirstChildOfClass("UIStroke")
		if not rim then
			rim = Instance.new("UIStroke")
			rim.Parent = parent
		end
		rim.Transparency = 0.05
		rim.Thickness = math.max(rim.Thickness, 2.5)
		for _, ch in ipairs(rim:GetChildren()) do
			if ch:IsA("UIGradient") then ch:Destroy() end
		end
		if variant == "Golden" then
			rim.Color = Color3.fromRGB(255, 196, 64)
		elseif variant == "Prism" then
			rim.Color = Color3.fromRGB(140, 210, 255)
		else
			rim.Color = Color3.fromRGB(255, 110, 200)
			local g = Instance.new("UIGradient")
			g.Rotation = 35
			g.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
				ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 255, 120)),
				ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 160, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 80, 255)),
			})
			g.Parent = rim
		end
		return
	end
	if variant == "Shiny" then
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255), Color3.fromRGB(255, 255, 255))
		g.Parent = parent
	end
end

--[[
	SHINY CARDS LOOK SHINY.

	Shiny used to be one line -- a pale blue-to-white UIGradient over the card
	body, the same weight of treatment every other variant gets, on the single
	property the game charges a rarity premium for. At a glance a shiny Common
	and a plain Common were the same card, which makes the whole shiny rate
	pointless: the player cannot tell it happened.

	Three things separate it now. A rainbow rim, a foil band that sweeps across
	the face, and a corner tag that names it. The sweep is what actually sells
	it -- a still image reads as someone's colour choice, motion reads as a
	finish on the card.

	The sweep is only started on big cards. A binder page can hold a hundred
	tiles and a hundred looping tweens to decorate thumbnails is not worth the
	frame; small cards keep the rim and the tag, which is enough to pick them
	out of a grid.
]]
local SHINY_SWEEP_MIN_W = 140

function ClientFns.shinyFoil(cardFrame, w, radius)
	-- The rim goes rainbow. paintCard already put a UIStroke on for rarity, so
	-- this recolours that rather than stacking a second outline on top.
	local rim = cardFrame:FindFirstChildOfClass("UIStroke")
	if rim then
		rim.Thickness = math.max(2, math.floor(w * 0.018))
		rim.Transparency = 0
		local rg = Instance.new("UIGradient")
		rg.Rotation = 30
		rg.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 150, 220)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(150, 220, 255)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(190, 255, 170)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 150)),
		})
		rg.Parent = rim
	end

	local sheen = mk("Frame", {
		Name = "ShinyFoil",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 8,
	}, cardFrame)
	round(sheen, radius)
	local g = Instance.new("UIGradient")
	g.Rotation = 24
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 230)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(190, 240, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 255, 195)),
	})
	-- Mostly invisible with one narrow bright band: that band is the highlight,
	-- and sweeping the offset is what drags it across the card.
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.38, 1),
		NumberSequenceKeypoint.new(0.5, 0.58),
		NumberSequenceKeypoint.new(0.62, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Offset = Vector2.new(-1.1, 0)
	g.Parent = sheen

	if w >= SHINY_SWEEP_MIN_W then
		task.spawn(function()
			while sheen.Parent do
				local tw = TweenService:Create(g,
					TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ Offset = Vector2.new(1.1, 0) })
				tw:Play()
				tw.Completed:Wait()
				if not sheen.Parent then
					return
				end
				task.wait(1.1)
				g.Offset = Vector2.new(-1.1, 0)
			end
		end)
	end

	-- And say it outright, because a finish you have to squint at is a finish
	-- half the players will never notice they own.
	local tagH = math.max(12, math.floor(w * 0.11))
	local tag = mk("Frame", {
		Name = "ShinyTag",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -math.floor(w * 0.05), 0, math.floor(w * 0.09)),
		Size = UDim2.fromOffset(math.floor(w * 0.34), tagH),
		ZIndex = 9,
	}, cardFrame)
	round(tag, math.floor(tagH / 2))
	local tg = Instance.new("UIGradient")
	tg.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 190, 235)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(175, 235, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 255, 185)),
	})
	tg.Parent = tag
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		Text = "SHINY",
		TextSize = math.max(8, math.floor(tagH * 0.66)),
		TextColor3 = Color3.fromRGB(26, 24, 34),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10,
	}, tag)
	return sheen
end

--[[
	SHADOW. One shiny in twenty comes out of the pack like this instead.

	The opposite treatment to the foil above: the card goes to near-black, the
	rim burns red, and the sweep is a dark ember rather than a rainbow. Same
	three cues -- rim, sweep, corner tag -- so it is unmistakable at a glance
	and in a grid of thumbnails.
]]
function ClientFns.shadowFoil(cardFrame, w, radius)
	local rim = cardFrame:FindFirstChildOfClass("UIStroke")
	if rim then
		rim.Thickness = math.max(2, math.floor(w * 0.02))
		rim.Transparency = 0
		local rg = Instance.new("UIGradient")
		rg.Rotation = 30
		rg.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 40, 40)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 60)),
		})
		rg.Parent = rim
	end

	local dark = mk("Frame", {
		Name = "ShadowWash",
		BackgroundColor3 = Color3.fromRGB(8, 6, 10),
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 7,
	}, cardFrame)
	round(dark, radius)

	local sheen = mk("Frame", {
		Name = "ShadowFoil",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 8,
	}, cardFrame)
	round(sheen, radius)
	local g = Instance.new("UIGradient")
	g.Rotation = 24
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 30, 30)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 10, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 40)),
	})
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 1),
		NumberSequenceKeypoint.new(0.5, 0.42),
		NumberSequenceKeypoint.new(0.6, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Offset = Vector2.new(-1.1, 0)
	g.Parent = sheen
	if w >= SHINY_SWEEP_MIN_W then
		task.spawn(function()
			while sheen.Parent do
				local tw = TweenService:Create(g,
					TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ Offset = Vector2.new(1.1, 0) })
				tw:Play()
				tw.Completed:Wait()
				if not sheen.Parent then
					return
				end
				task.wait(0.9)
				g.Offset = Vector2.new(-1.1, 0)
			end
		end)
	end

	local tagH = math.max(12, math.floor(w * 0.11))
	local tag = mk("Frame", {
		Name = "ShadowTag",
		BackgroundColor3 = Color3.fromRGB(16, 10, 12),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -math.floor(w * 0.05), 0, math.floor(w * 0.09)),
		Size = UDim2.fromOffset(math.floor(w * 0.38), tagH),
		ZIndex = 9,
	}, cardFrame)
	round(tag, math.floor(tagH / 2))
	local ts = Instance.new("UIStroke")
	ts.Color = Color3.fromRGB(255, 40, 40)
	ts.Thickness = 1.5
	ts.Parent = tag
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		Text = "SHADOW",
		TextSize = math.max(8, math.floor(tagH * 0.62)),
		TextColor3 = Color3.fromRGB(255, 70, 60),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10,
	}, tag)
	return sheen
end

local function limb(parent, size, color, cf, shape)
	local p = mk("Part", {
		Anchored = true,
		CanCollide = false,
		CastShadow = false,
		Material = Enum.Material.SmoothPlastic,
		Shape = shape or Enum.PartType.Block,
		Size = size,
		Color = color,
		CFrame = cf,
		TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth,
	}, parent)
	return p
end

-- One pet, built by the pet system. Every card name in every set resolves to a
-- real species -- `speciesFromName` reads "Prism Wyrm" as a wyrm -- so nothing
-- here has to guess, and a card's variant and rarity carry through to the model.
function ClientFns.buildPetModel(card)
	return PetFactory.fromCard(card)
end

--[[
	THE HAT, ON THE PET.

	A hat is a real catalog accessory, and the engine has to build it before it
	can be worn (PetModelFactory.wearHat yields the first time it sees a given
	id), so this spawns. Everything after the yield re-checks that the pet is
	still there -- pets are rebuilt whenever the team changes, and the model this
	was called for may be gone by the time the accessory arrives.

	If the engine will not hand over the accessory at all, the hat still shows:
	its catalog thumbnail floats at the pet's head instead of nothing happening.
]]
function ClientFns.petHatPiece(card)
	if not (snap and card) then
		return nil
	end
	--[[
		Pets wear no hats. Kept as a stub returning nil so an older view that
		still asks gets "nothing on this pet" rather than an error -- which is
		also the truth.
	]]
	local gearId = nil
	if not gearId then
		return nil
	end
	for _, g in ipairs(snap.gear or {}) do
		if g.id == gearId then
			return g
		end
	end
	return nil
end

--[[
	A proc's animation and sound (MineProcFx). Loaded on the first proc, and a
	module that fails to load costs the word on screen nothing.
]]
function ClientFns.procFx(text, pos)
	if ClientFns.procFxMod == nil then
		local ok, mod = pcall(function()
			return require(shared:WaitForChild("MineProcFx"))
		end)
		ClientFns.procFxMod = ok and mod or false
	end
	if ClientFns.procFxMod then
		ClientFns.procFxMod.play(text, pos)
	end
end

function ClientFns.dressPet(model, card, onDone)
	if not (model and card) then
		return
	end
	local piece = ClientFns.petHatPiece(card)
	local catalogId = piece and tonumber(piece.catalogId)
	if not catalogId then
		pcall(PetFactory.wearHat, model, nil)
		return
	end
	task.spawn(function()
		local ok, hat = pcall(PetFactory.wearHat, model, catalogId)
		if not model.Parent then
			return
		end
		if not (ok and hat) then
			-- Fallback: the thumbnail, at the head, so the hat is still ON the pet.
			local Hats = require(shared:WaitForChild("MineHats"))
			local url = Hats.thumb and Hats.thumb(catalogId)
			if url and not model:FindFirstChild("PetHatTag") then
				local anchor = PetFactory.hatAnchor(model)
				local tag = mk("BillboardGui", {
					Name = "PetHatTag", AlwaysOnTop = false, LightInfluence = 0,
					Size = UDim2.fromOffset(34, 34), StudsOffset = Vector3.new(0, anchor.Y + 0.3, 0),
					MaxDistance = 60, Adornee = model.PrimaryPart,
				}, model)
				mk("ImageLabel", {
					BackgroundTransparency = 1, Image = url, ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(1, 1),
				}, tag)
			end
		end
		if onDone then
			pcall(onDone)
		end
	end)
end

function ClientFns.petViewport(parent, card, pos, size)
	local vp = mk("ViewportFrame", {
		BackgroundColor3 = Color3.fromRGB(14, 14, 18),
		Position = pos,
		Size = size,
		Ambient = Color3.fromRGB(170, 170, 180),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(-0.4, -1, -0.5),
	}, parent)
	round(vp, 8)
	local world = Instance.new("WorldModel")
	world.Parent = vp
	local model = ClientFns.buildPetModel(card)
	-- Lights and particles never render inside a ViewportFrame; the geometry does.
	PetFactory.stripFX(model)
	model:PivotTo(CFrame.new())
	model.Parent = world
	local cam = Instance.new("Camera")
	cam.Parent = vp
	vp.CurrentCamera = cam

	-- Frame the pet against the window it is actually in. A fixed camera crops a
	-- ray and loses a crab in the middle distance, and fitting on height alone
	-- leaves a wide pet swimming in a wide window: solve both axes, take the
	-- further of the two. AbsoluteSize is zero until the layout runs, so re-fit
	-- when it lands.
	-- A narrow lens. At the default 70 degrees the near side of a pet standing two
	-- studs from the camera renders half again as big as its far side, so a fit
	-- solved at the centre plane still crops the face off. 25 degrees is a product
	-- shot: near enough to orthographic that the arithmetic below is true.
	cam.FieldOfView = 25
	local function fit()
		local centre, ext = model:GetBoundingBox()
		local w = math.max(vp.AbsoluteSize.X, 1)
		local h = math.max(vp.AbsoluteSize.Y, 1)
		local vFov = math.rad(cam.FieldOfView)
		local hFov = 2 * math.atan(math.tan(vFov * 0.5) * (w / h))
		local fill = 0.86
		local dv = (ext.Y / fill) * 0.5 / math.tan(vFov * 0.5)
		local dh = (math.max(ext.X, ext.Z) / fill) * 0.5 / math.tan(hFov * 0.5)
		-- Solved for the NEAR face, not the centre of the model: half the model
		-- stands in front of its own middle.
		local dist = math.max(dv, dh, 1.3) + math.max(ext.X, ext.Y, ext.Z) * 0.5
		local yaw, pitch = math.rad(26), math.rad(12)
		local dir = Vector3.new(
			math.sin(yaw) * math.cos(pitch),
			math.sin(pitch),
			math.cos(yaw) * math.cos(pitch))
		cam.CFrame = CFrame.lookAt(centre.Position + dir * dist, centre.Position)
	end
	fit()
	vp:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	-- Re-frame once the hat lands: it arrives after the first fit and is taller
	-- than the pet, so a frame solved without it crops the crown.
	ClientFns.dressPet(model, card, fit)
	return vp
end

function ClientFns.statChip(parent, key, amount, pos, width)
	local chip = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(18, 18, 22),
		BackgroundTransparency = 0.08,
		Position = pos,
		Size = UDim2.fromOffset(width or 118, 22),
	}, parent)
	round(chip, 8)
	local icon = mk("ImageLabel", {
		BackgroundTransparency = 1,
		Image = Cards.STAT_ICON[key] or ICONS.card,
		ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(3, 2),
		Size = UDim2.fromOffset(18, 18),
	}, chip)
	round(icon, 9)
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 12,
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(24, 0),
		Size = UDim2.new(1, -28, 1, 0),
		Text = string.format("%s +%d%%", Cards.STAT_LABEL[key] or key, math.floor((amount or 0) * 100 + 0.5)),
	}, chip)
	return chip
end

-- A card is a card: 2.5 wide by 3.5 tall, the shape of the ones you put in a
-- sleeve. Height is always derived from width, so no caller can ship a card that
-- is not card-shaped, and every band below is a fraction of the height so a
-- 108-wide binder tile and a 200-wide pack reveal lay out identically.
local CARD_RATIO = 3.5 / 2.5

--[[
	The face of a rune or a gear piece.

	Same silhouette as a card -- rarity banner, art well, name, stat line -- so
	a mixed reveal reads as one deck rather than as two systems bolted together.
	What changes is the art well, and every family has real art to put in it:
	gear has per-set, per-slot, per-rarity images; a rune borrows the icon of
	the stat it rolls.

	Gear, Runes and Icons are required here rather than at the top of the file
	because MineClient is close to Luau's 200 top-level local ceiling and
	require is cached -- the second call is a table lookup.
]]
function ClientFns.paintLoot(parent, item, w)
	local Gear = require(shared:WaitForChild("MineGear"))
	local Icons = require(shared:WaitForChild("MineIcons"))
	local Irid = require(shared:WaitForChild("MineIridescence"))
	w = w or 180
	local h = math.floor(w * CARD_RATIO + 0.5)
	local pad = math.max(6, math.floor(w * 0.05))
	local rareCol = Cards.RARITY_COLOR[item.rarityId] or TEXT
	local FAMILY = {
		gear = { tag = "GEAR", tint = Color3.fromRGB(86, 132, 190) },
		rune = { tag = "RUNE", tint = Color3.fromRGB(150, 104, 200) },
		gems = { tag = "GEMS", tint = Color3.fromRGB(90, 180, 255) },
		coins = { tag = "COINS", tint = Color3.fromRGB(240, 200, 90) },
		stardust = { tag = "STARDUST", tint = Color3.fromRGB(210, 160, 255) },
		dust = { tag = "STARDUST", tint = Color3.fromRGB(210, 160, 255) },
		tool = { tag = "TOOL", tint = Color3.fromRGB(214, 162, 72) },
		charm = { tag = "CHARM", tint = Color3.fromRGB(96, 200, 150) },
		pack = { tag = "PACK", tint = Color3.fromRGB(196, 120, 222) },
	}
	local fam = FAMILY[item.kind] or { tag = "ITEM", tint = Color3.fromRGB(120, 120, 130) }
	if item.kind == "tool" then
		fam = {
			tag = ({ pickaxe = "PICKAXE", drill = "DRILL", explosive = "EXPLOSIVE" })[item.family or ""] or "TOOL",
			tint = fam.tint,
		}
	end
	local isCurrency = item.kind == "gems" or item.kind == "coins"
		or item.kind == "stardust" or item.kind == "dust"

	local image
	if item.kind == "gear" and item.gear then
		image = Gear.image(item.gear)
	elseif item.kind == "rune" and item.rune then
		image = Icons.image(item.rune.stat)
	elseif item.kind == "gems" then
		image = Icons.image("gems")
	elseif item.kind == "coins" then
		image = Icons.image("coins")
	elseif item.kind == "stardust" or item.kind == "dust" then
		image = Icons.image("stardust")
	elseif item.kind == "pack" then
		image = require(shared:WaitForChild("MinePackFX")).art(item.packId).image
	elseif item.kind == "charm" then
		-- There is no charm art: the icon of the stat it moves most, in a ring.
		local def = require(shared:WaitForChild("MineCharms")).byId(item.charmId)
		local top, most = nil, -1
		for stat, v in pairs((def and def.stats) or {}) do
			if (tonumber(v) or 0) > most then
				top, most = stat, tonumber(v) or 0
			end
		end
		image = Icons.image(top or "luck")
	end

	local f = mk("Frame", {
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = Color3.fromRGB(20, 20, 24),
	}, parent)
	round(f, math.max(6, math.floor(w * 0.055)))
	local rim = Instance.new("UIStroke")
	rim.Thickness = 2
	rim.Color = rareCol
	rim.Transparency = 0.15
	rim.Parent = f

	local bannerH = math.floor(h * 0.085)
	local artY = bannerH + pad
	local artH = math.floor(h * 0.44)
	local nameY = artY + artH + math.floor(h * 0.014)
	local nameH = math.floor(h * 0.085)
	local pillH = math.floor(h * 0.062)
	local pillY = nameY + nameH
	local subY = pillY + pillH + math.floor(h * 0.02)

	local banner = mk("Frame", {
		BackgroundColor3 = rareCol,
		Size = UDim2.new(1, 0, 0, bannerH),
	}, f)
	round(banner, math.max(6, math.floor(w * 0.055)))
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = math.max(9, math.floor(h * 0.05)),
		TextColor3 = Color3.fromRGB(18, 18, 22),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, -pad * 2, 1, 0),
		Position = UDim2.fromOffset(pad, 0),
		Text = string.upper(Cards.RARITY_LABEL[item.rarityId] or item.rarityId or "") .. "  " .. fam.tag,
	}, banner)

	-- The art well is tinted by family, so the three read apart at a glance
	-- even when the rarity banner happens to match. Currency (gems / stardust
	-- / coins) is just the icon - no plate behind it.
	local well = mk("Frame", {
		BackgroundTransparency = isCurrency and 1 or 0,
		BackgroundColor3 = fam.tint:Lerp(Color3.fromRGB(12, 12, 16), 0.74),
		Position = UDim2.fromOffset(pad, artY),
		Size = UDim2.new(1, -pad * 2, 0, artH),
	}, f)
	if not isCurrency then
		round(well, math.max(4, math.floor(w * 0.04)))
	end
	if item.kind == "gear" and item.gear then
		Irid.badge(f, item.gear.rarity, {
			height = math.max(22, math.floor(h * 0.11)),
			position = UDim2.new(1, -pad, 0, artY + 4),
			anchor = Vector2.new(1, 0),
			z = 8,
		})
	end
	if item.kind == "tool" then
		ClientFns.toolViewport(well, item, (w - pad * 2) / math.max(1, artH))
	elseif item.kind == "charm" then
		local ring = mk("Frame", {
			BackgroundColor3 = fam.tint:Lerp(Color3.fromRGB(12, 12, 16), 0.55),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.78, 0.78),
		}, well)
		mk("UIAspectRatioConstraint", { AspectRatio = 1 }, ring)
		round(ring, 999)
		local rs = Instance.new("UIStroke")
		rs.Thickness = math.max(3, math.floor(w * 0.02))
		rs.Color = GOLD
		rs.Parent = ring
		if image then
			mk("ImageLabel", {
				BackgroundTransparency = 1,
				Image = image,
				ScaleType = Enum.ScaleType.Fit,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.6, 0.6),
			}, ring)
		end
	elseif image then
		mk("ImageLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = image,
			ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(isCurrency and 0.72 or 0.82, isCurrency and 0.72 or 0.82),
		}, well)
	elseif not isCurrency then
		-- No art for this one: a family-tinted lozenge rather than an empty
		-- hole, so the card still looks finished.
		local badge = mk("Frame", {
			BackgroundColor3 = fam.tint,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.42, 0.42),
			Rotation = 45,
		}, well)
		round(badge, math.max(6, math.floor(w * 0.06)))
	end

	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = math.max(11, math.floor(h * 0.062)),
		TextColor3 = TEXT,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(pad, nameY),
		Size = UDim2.new(1, -pad * 2, 0, nameH),
		Text = tostring(item.name or "Item"),
	}, f)

	local pillW = math.floor(w * 0.48)
	local pill = mk("Frame", {
		BackgroundColor3 = fam.tint,
		Position = UDim2.fromOffset(pad, pillY),
		Size = UDim2.fromOffset(pillW, pillH),
	}, f)
	round(pill, 8)
	local pillText = fam.tag
	if item.kind == "gear" and item.gear then
		pillText = (Gear.SLOT_LABEL[item.gear.slot] or item.gear.slot or "")
			.. "  " .. tostring(item.gear.rarity or "")
	elseif item.kind == "rune" and item.rune then
		pillText = tostring(item.rune.kind or "") .. "  T" .. tostring(item.rune.tier or 1)
	elseif isCurrency then
		pillText = fam.tag
	elseif item.kind == "tool" then
		pillText = (item.nightmare and "NIGHTMARE") or (item.shadow and "SHADOW") or (item.shiny and "SHINY") or fam.tag
	end
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = math.max(9, math.floor(h * 0.04)),
		TextColor3 = Color3.fromRGB(16, 16, 18),
		Size = UDim2.fromScale(1, 1),
		Text = pillText,
	}, pill)

	-- The right-hand number is the reason to want it: a percentage for gear
	-- and runes.
	local right = ""
	if item.kind == "gear" and item.gear then
		local slots = item.gear.slotCount or 0
		local socketText = slots .. ((slots == 1) and " socket" or " sockets")
		-- An amulet is a socket slot and pays no percentage at all. "+0.0%"
		-- on one reads as a piece that failed to roll rather than as the
		-- point of the slot.
		right = ((item.gear.pct or 0) > 0)
			and string.format("+%.1f%%  %s", (item.gear.pct or 0) * 100, socketText)
			or socketText
	elseif item.kind == "rune" and item.rune then
		right = string.format("+%.2f%%", (item.rune.pct or 0) * 100)
	elseif item.kind == "tool" and tonumber(item.power) then
		right = "power " .. ClientFns.commas(math.floor(tonumber(item.power)))
	elseif item.kind == "pack" and tonumber(item.stars) then
		-- A pack out of a pack case: its stars, the number that says how good.
		local n = tonumber(item.stars)
		right = string.rep("★", math.floor(n)) .. ((n % 1 >= 0.5) and "½" or "")
	end
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT_M,
		TextSize = math.max(9, math.floor(h * 0.04)),
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -pad - pillW, 0, pillY),
		Size = UDim2.fromOffset(pillW, pillH),
		Text = right,
	}, f)

	if h - subY - 4 >= 12 then
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Font = FONT_M,
			TextSize = math.max(9, math.floor(h * 0.038)),
			TextColor3 = MUTED,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Position = UDim2.fromOffset(pad, subY),
			Size = UDim2.new(1, -pad * 2, 0, h - subY - 4),
			Text = tostring(item.sub or ""),
		}, f)
	end
	return f
end

--[[
	A chest tool on a card: the real model, turning slowly in the art well.

	The same model the hand holds (ToolModelFactory.fromNamed, finish applied
	live), stood on its handle the way the shop does it, and framed by its own
	bounding sphere so a stubby bomb and a long lance both fill the well. A tool
	with no named model (a proto) gets its family's procedural build.
]]
function ClientFns.toolViewport(parent, item, aspect)
	local ok, err = pcall(function()
		local Factory = require(game:GetService("ReplicatedStorage"):WaitForChild("ToolModelFactory"))
		local fam = (item.family == "drill" or item.family == "explosive") and item.family or "pickaxe"
		local model = item.baseName and Factory.fromNamed and Factory.fromNamed(item.baseName, "Normal", fam) or nil
		if not model then
			model = Factory.build(fam, 12, 14)
		end
		local finish = (item.nightmare and "Nightmare") or (item.shadow and "Shadow") or (item.shiny and "Shiny") or nil
		if finish and Factory.applyFinish then
			pcall(Factory.applyFinish, model, finish)
		end
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
			elseif d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("BaseScript") then
				pcall(d.Destroy, d)
			end
		end
		-- Stand it on its handle (MineShopView.setModel): the shaft points up.
		model:PivotTo(CFrame.identity)
		local upright = CFrame.identity
		local handle = model:FindFirstChild("Handle", true)
		if handle and handle:IsA("BasePart") then
			local sz = handle.Size
			local axis = (sz.X >= sz.Y and sz.X >= sz.Z) and Vector3.xAxis
				or ((sz.Y >= sz.Z) and Vector3.yAxis or Vector3.zAxis)
			local shaft = handle.CFrame:VectorToWorldSpace(axis)
			if shaft.Magnitude > 1e-4 then
				shaft = shaft.Unit
				local cross = shaft:Cross(Vector3.yAxis)
				local dot = math.clamp(shaft:Dot(Vector3.yAxis), -1, 1)
				if cross.Magnitude > 1e-4 then
					upright = CFrame.fromAxisAngle(cross.Unit, math.acos(dot))
				elseif dot < 0 then
					upright = CFrame.Angles(math.pi, 0, 0)
				end
			end
		end
		model:PivotTo(upright)
		-- World-aligned box over the VISIBLE parts. GetBoundingBox measures
		-- along the PrimaryPart's own axes, which after standing the tool up are
		-- no longer the screen's -- and it counts the invisible grip handle.
		local lo = Vector3.new(math.huge, math.huge, math.huge)
		local hi = -lo
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d.Transparency < 1 then
				local half = d.Size * 0.5
				for _, c in ipairs({ -1, 1 }) do
					for _, e in ipairs({ -1, 1 }) do
						for _, k in ipairs({ -1, 1 }) do
							local pt = d.CFrame:PointToWorldSpace(Vector3.new(half.X * c, half.Y * e, half.Z * k))
							lo = lo:Min(pt)
							hi = hi:Max(pt)
						end
					end
				end
			end
		end
		if lo.X > hi.X then
			local box, ext = model:GetBoundingBox()
			lo, hi = box.Position - ext * 0.5, box.Position + ext * 0.5
		end
		local size = hi - lo
		model:TranslateBy(-(lo + hi) * 0.5)
		local vp = Instance.new("ViewportFrame")
		vp.Name = "ToolView"
		vp.BackgroundTransparency = 1
		vp.Size = UDim2.fromScale(1, 1)
		vp.Ambient = Color3.fromRGB(150, 140, 130)
		vp.LightColor = Color3.fromRGB(255, 240, 214)
		vp.LightDirection = Vector3.new(-0.45, -0.85, -0.55)
		vp.ZIndex = (parent.ZIndex or 1) + 1
		vp.Parent = parent
		local cam = Instance.new("Camera")
		cam.FieldOfView = 28
		cam.Parent = vp
		vp.CurrentCamera = cam
		model.Parent = vp
		-- Fit height and the widest the turn ever gets, against the well's own
		-- shape (passed in: the well has no AbsoluteSize yet when this runs).
		local tanV = math.tan(math.rad(cam.FieldOfView * 0.5))
		local halfW = math.max(0.25, math.sqrt(size.X * size.X + size.Z * size.Z) * 0.5)
		local distV = math.max(0.25, size.Y * 0.5) / tanV
		local distH = halfW / (tanV * math.max(0.5, tonumber(aspect) or 1.4))
		local dist = math.max(distV, distH) * 1.1 + halfW * 0.5
		local yaw = math.rad(25)
		local function place()
			local pos = CFrame.Angles(0, yaw, 0) * Vector3.new(0, dist * 0.1, dist)
			cam.CFrame = CFrame.lookAt(pos, Vector3.zero)
		end
		place()
		task.spawn(function()
			while vp.Parent do
				yaw += task.wait() * 0.7
				place()
			end
		end)
	end)
	if not ok then
		warn("[toolViewport] " .. tostring(err))
	end
end

paintCard = function(parent, card, w)
	-- One painter for everything the reveal and the binder can show. A rune or
	-- gear item carries `kind`; a card does not.
	if type(card) == "table" and card.kind and card.kind ~= "card" then
		return ClientFns.paintLoot(parent, card, w)
	end
	w = w or 180
	local h = math.floor(w * CARD_RATIO + 0.5)
	local pad = math.max(6, math.floor(w * 0.05))
	local typeCol = Cards.TYPE_COLOR[card.typeId] or Color3.fromRGB(48, 48, 54)
	local rareCol = Cards.RARITY_COLOR[card.rarityId] or TEXT
	local kit = Cards.getKit(card.setId, card.index)
	local pow = C.cardPower(card)
	local f = mk("Frame", {
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = Color3.fromRGB(20, 20, 24),
	}, parent)
	round(f, math.max(6, math.floor(w * 0.055)))
	local rim = Instance.new("UIStroke")
	rim.Thickness = 2
	rim.Color = rareCol
	rim.Transparency = 0.15
	rim.Parent = f
	ClientFns.variantGrad(f, card.variant or "Normal")
	-- Driven by the flag, not the variant name: a card can roll a finish AND a
	-- better variant (Golden, Prism), and it should still read as the finish.
	if card.shadow then
		ClientFns.shadowFoil(f, w, math.max(6, math.floor(w * 0.055)))
	elseif card.shiny then
		ClientFns.shinyFoil(f, w, math.max(6, math.floor(w * 0.055)))
	end

	local bannerH = math.floor(h * 0.085)
	local artY = bannerH + pad
	local artH = math.floor(h * 0.44)
	local nameY = artY + artH + math.floor(h * 0.014)
	local nameH = math.floor(h * 0.085)
	local pillH = math.floor(h * 0.062)
	local pillY = nameY + nameH
	local statY = pillY + pillH + math.floor(h * 0.02)

	local banner = mk("Frame", {
		BackgroundColor3 = rareCol,
		Size = UDim2.new(1, 0, 0, bannerH),
	}, f)
	round(banner, math.max(6, math.floor(w * 0.055)))
	--[[
		The banner names the FINISH as well as the rarity: "SHADOW LEGENDARY".
		A shadow is three times the card a normal one is (MineConfig.SHADOW_MULT)
		and one in twenty-five hundred outside the Shiny Pack -- the rarest thing
		most players will ever pull -- and the card used to say nothing about it.

		It has to SHRINK rather than truncate: on the smallest tile the banner is
		80px wide and "SHADOW LEGENDARY" wants 88, so a fixed size would clip the
		word that matters most. Note the order -- parenting a UITextSizeConstraint
		clears TextScaled, so the constraint goes on first and TextScaled last.
	]]
	local bannerSize = math.max(9, math.floor(h * 0.05))
	local bannerText = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = bannerSize,
		TextColor3 = Color3.fromRGB(18, 18, 22),
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(pad, 0),
		Size = UDim2.new(1, -pad * 2, 1, 0),
		Text = string.upper(((card.shadow and "Shadow ") or (card.shiny and "Shiny ") or "")
			.. (Cards.RARITY_LABEL[card.rarityId] or card.rarityId or "")),
	}, banner)
	mk("UITextSizeConstraint", { MaxTextSize = bannerSize, MinTextSize = 7 }, bannerText)
	bannerText.TextScaled = true
	ClientFns.petViewport(f, card, UDim2.fromOffset(pad, artY), UDim2.new(1, -pad * 2, 0, artH))
	local title = (Cards.displayName and Cards.displayName(card)) or card.animal or card.name or "Pet"
	local subtitle = Cards.subtitleName and Cards.subtitleName(card)
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = math.max(11, math.floor(h * 0.062)),
		TextColor3 = TEXT,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(pad, nameY),
		Size = UDim2.new(1, -pad * 2, 0, subtitle and math.floor(nameH * 0.62) or nameH),
		Text = title,
	}, f)
	if subtitle then
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Font = FONT_M,
			TextSize = math.max(8, math.floor(h * 0.032)),
			TextColor3 = Color3.fromRGB(170, 170, 180),
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(pad, nameY + math.floor(nameH * 0.58)),
			Size = UDim2.new(1, -pad * 2, 0, math.floor(nameH * 0.4)),
			Text = subtitle,
		}, f)
	end
	local pillW = math.floor(w * 0.48)
	local pill = mk("Frame", {
		BackgroundColor3 = typeCol,
		Position = UDim2.fromOffset(pad, pillY),
		Size = UDim2.fromOffset(pillW, pillH),
	}, f)
	round(pill, 8)
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = math.max(9, math.floor(h * 0.04)),
		TextColor3 = Color3.fromRGB(16, 16, 18),
		Size = UDim2.fromScale(1, 1),
		Text = (Cards.typeName and Cards.typeName(card.typeId) or card.typeId or "")
			.. "  " .. ((Cards.namedBoosts and Cards.namedBoosts(card)) and "Kit" or (kit and kit.roleName or "Unit")),
	}, pill)
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT_M,
		TextSize = math.max(9, math.floor(h * 0.04)),
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -pad - pillW, 0, pillY),
		Size = UDim2.fromOffset(pillW, pillH),
		Text = (card.variant or "Normal") .. "  P" .. tostring(card.powerLevel or 1),
	}, f)
	local _, boostLines = Cards.describe(card, pow)
	if type(boostLines) == "table" and #boostLines > 0 then
		local chipH = math.max(18, math.floor(h * 0.055))
		local gap = math.max(2, math.floor(h * 0.008))
		local maxChips = math.min(#boostLines, 6)
		for i = 1, maxChips do
			local line = boostLines[i]
			local y = statY + (i - 1) * (chipH + gap)
			if y + chipH > h - 4 then break end
			mk("TextLabel", {
				BackgroundTransparency = 0.35,
				BackgroundColor3 = Color3.fromRGB(28, 28, 34),
				Font = FONT_M,
				TextSize = math.max(8, math.floor(h * 0.034)),
				TextColor3 = TEXT,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.fromOffset(pad, y),
				Size = UDim2.new(1, -pad * 2, 0, chipH),
				Text = "  " .. tostring(line),
			}, f)
		end
	elseif kit then
		local chipW = w - pad * 2
		ClientFns.statChip(f, kit.primary, kit.primaryBase * pow, UDim2.fromOffset(pad, statY), chipW)
		ClientFns.statChip(f, kit.secondary, kit.secondaryBase * pow, UDim2.fromOffset(pad, statY + 25), chipW)
	end
	return f
end

local function clear(body)
	for _, c in ipairs(body:GetChildren()) do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
end

local function rowBtn(parent, text, fn)
	local b = mk("TextButton", {
		BackgroundColor3 = BG2,
		Size = UDim2.new(1, -8, 0, 42),
		Font = FONT_M,
		TextSize = 15,
		TextColor3 = TEXT,
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
	round(b, 6)
	stroke(b, 1)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.Parent = b
	b.MouseButton1Click:Connect(fn)
	-- Hand it back. Callers that want to set a LayoutOrder on the row were
	-- writing `local r = rowBtn(...)` and silently getting nil.
	return b
end

function ClientFns.sortedCards()
	local list = {}
	for i, card in ipairs(snap.cards or {}) do
		list[i] = card
	end
	local eqSet = {}
	for _, id in ipairs(snap.equipped or {}) do
		eqSet[id] = true
	end
	local qtyOf = {}
	for _, card in ipairs(list) do
		local k = tostring(card.cardKey) .. "|" .. tostring(card.rarityId) .. "|" .. tostring(card.variant or "Normal")
		qtyOf[k] = (qtyOf[k] or 0) + 1
	end
	table.sort(list, function(a, b)
		if cardSort == "equipped" then
			local ae, be = eqSet[a.id] and 1 or 0, eqSet[b.id] and 1 or 0
			if ae ~= be then
				return ae > be
			end
			local as = (Cards.boostScore and Cards.boostScore(a)) or 0
			local bs = (Cards.boostScore and Cards.boostScore(b)) or 0
			if as ~= bs then
				return as > bs
			end
		elseif cardSort == "rarity" then
			local ar = Cards.RARITY_RANK[a.rarityId] or 0
			local br = Cards.RARITY_RANK[b.rarityId] or 0
			if ar ~= br then
				return ar > br
			end
			local as = (Cards.boostScore and Cards.boostScore(a)) or 0
			local bs = (Cards.boostScore and Cards.boostScore(b)) or 0
			if as ~= bs then
				return as > bs
			end
		elseif cardSort == "recent" then
			local at, bt = a.createdAt or 0, b.createdAt or 0
			if at ~= bt then
				return at > bt
			end
		elseif cardSort == "set" then
			local as, bs = a.setName or a.setId or "", b.setName or b.setId or ""
			if as ~= bs then
				return as < bs
			end
			return (a.index or 0) < (b.index or 0)
		elseif cardSort == "alpha" then
			return (a.name or "") < (b.name or "")
		elseif cardSort == "type" then
			if (a.typeId or "") ~= (b.typeId or "") then
				return (a.typeId or "") < (b.typeId or "")
			end
		elseif cardSort == "role" then
			local ar = (Cards.getKit(a.setId, a.index) or {}).roleName or ""
			local br = (Cards.getKit(b.setId, b.index) or {}).roleName or ""
			if ar ~= br then
				return ar < br
			end
		elseif cardSort == "power" or cardSort == "boosts" then
			local as = (Cards.boostScore and Cards.boostScore(a)) or (a.powerLevel or 1)
			local bs = (Cards.boostScore and Cards.boostScore(b)) or (b.powerLevel or 1)
			if as ~= bs then
				return as > bs
			end
		elseif cardSort == "variant" then
			local av = (Cards.VARIANT_RANK[a.variant or "Normal"] or 0) + ((a.shadow and 10) or (a.shiny and 5) or 0)
			local bv = (Cards.VARIANT_RANK[b.variant or "Normal"] or 0) + ((b.shadow and 10) or (b.shiny and 5) or 0)
			if av ~= bv then
				return av > bv
			end
		elseif cardSort == "qty" then
			local ka = tostring(a.cardKey) .. "|" .. tostring(a.rarityId) .. "|" .. tostring(a.variant or "Normal")
			local kb = tostring(b.cardKey) .. "|" .. tostring(b.rarityId) .. "|" .. tostring(b.variant or "Normal")
			local ca, cb = qtyOf[ka] or 0, qtyOf[kb] or 0
			if ca ~= cb then
				return ca > cb
			end
		end
		return (a.name or "") < (b.name or "")
	end)
	return list
end

refreshBinder = function()
	clear(binderP.Body)
	if not snap then
		return
	end
	local b = snap.boosts or {}
	rowBtn(binderP.Body, string.format(
		"Team %d/%d    Dmg %d%%  Blast %d%%  Luck %d%%  Walk %d%%  Dirt %d%%  Bag +%d%%  Rare %d%%",
		#(snap.equipped or {}),
		snap.petSlotsEffective or snap.petSlots or 3,
		math.floor(((b.mineSpeed or 1) - 1) * 100 + 0.5),
		math.floor((b.blastChance or 0) * 100 + 0.5),
		math.floor(((b.luck or 1) - 1) * 100 + 0.5),
		math.floor(((b.walkSpeed or 1) - 1) * 100 + 0.5),
		math.floor(((b.dirtBreak or 1) - 1) * 100 + 0.5),
		math.floor(((b.backpack or 1) - 1) * 100 + 0.5),
		math.floor(((b.rareOre or 1) - 1) * 100 + 0.5)
	), function() end)

	-- The search runs over everything a player would think to type: the pet's
	-- name, its set, its type, its rarity, its variant.
	local q = string.lower(cardSearch or "")
	local list = {}
	for _, card in ipairs(ClientFns.sortedCards()) do
		if q == "" then
			table.insert(list, card)
		else
			local hay = string.lower(table.concat({
				card.name or "", card.setName or "", card.typeId or "",
				card.rarityId or "", card.variant or "",
			}, " "))
			if string.find(hay, q, 1, true) then
				table.insert(list, card)
			end
		end
	end
	if #list == 0 then
		rowBtn(binderP.Body, #(snap.cards or {}) == 0
			and "No cards yet - open packs from chests"
			or "Nothing matches that search", function() end)
		return
	end

	-- Cards, laid out as cards. This was a list of fat rows with a square window
	-- in the corner, which is not what a binder looks like.
	local CW = 132
	local CH = math.floor(CW * 3.5 / 2.5 + 0.5)
	local grid = mk("Frame", {
		Name = "Cards",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, binderP.Body)
	mk("UIGridLayout", {
		CellPadding = UDim2.fromOffset(8, 8),
		CellSize = UDim2.fromOffset(CW, CH),
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	for i, card in ipairs(list) do
		local eq = table.find(snap.equipped or {}, card.id)
		local slot = mk("TextButton", {
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = i,
			Size = UDim2.fromOffset(CW, CH),
		}, grid)
		paintCard(slot, card, CW)
		if eq then
			-- On the team gets a badge, not a different colour: the card's colour
			-- already means its rarity and cannot mean two things at once.
			local tag = mk("Frame", {
				BackgroundColor3 = Color3.fromRGB(74, 176, 106),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -7, 0, 7),
				Size = UDim2.fromOffset(48, 18),
				ZIndex = 6,
			}, slot)
			round(tag, 6)
			mk("TextLabel", {
				BackgroundTransparency = 1,
				Font = FONT,
				TextSize = 11,
				TextColor3 = Color3.fromRGB(10, 26, 16),
				Size = UDim2.fromScale(1, 1),
				Text = "TEAM",
				ZIndex = 7,
			}, tag)
		end
		slot.MouseButton1Click:Connect(function()
			local cardId = card.id or card.serial
			if not cardId then
				return
			end
			net:FireServer(eq and "unequip" or "equip", cardId)
		end)
	end
end

for i, s in ipairs(SORTS) do
	local chip = mk("TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = BG2,
		Font = FONT_M,
		TextSize = 12,
		TextColor3 = TEXT,
		Text = s.label,
		Size = UDim2.fromOffset(74, 26),
		LayoutOrder = i,
	}, sortBar)
	chip.TextSize = 11
	round(chip, 8)
	sortChips[s.id] = chip
	chip.MouseButton1Click:Connect(function()
		persistCardSort(s.id)
		ClientFns.paintSortChips()
		refreshBinder()
	end)
end
ClientFns.paintSortChips()
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	cardSearch = searchBox.Text
	refreshBinder()
end)

--[[
	What is actually in the bag.

	Dirt never appears in `backpack` -- only chests and crates do. It lives in
	haulMix, one record per seam it came out of (zone|kind|section|band), which
	is also exactly how the depot prices it. The bag listed `backpack` alone, so
	a bag carrying nine hundred slots of dirt rendered as "Empty".

	Every local here is function-scoped on purpose: this file sits on the Luau
	200 top-level register ceiling with zero headroom.
]]
--[[
	The bag's sell clocks tick themselves.

	snap() is called from 160 places and none of them is a timer, so a
	countdown drawn at paint time never moves. These redraw the two rows in
	place from a deadline. Both live on ClientFns: MineClient is at the 200
	top-level register ceiling with zero headroom.
]]
function ClientFns.sellClockText(kind, left, full)
	left = math.max(0, math.floor(tonumber(left) or 0))
	local mmss = string.format("%d:%02d", math.floor(left / 60), left % 60)
	if kind == "auto" then
		return string.format("Auto-sell in %s  -  %s", mmss,
			full and "bag is full, it will cash" or "only cashes when full")
	end
	return "Sell at the depot"
end

function ClientFns.sellClockLoop()
	if ClientFns.sellClockOn then
		return
	end
	ClientFns.sellClockOn = true
	task.spawn(function()
		while true do
			task.wait(0.5)
			local st = ClientFns.sellClock
			local b = st and st.sellBtn
			-- Parent goes nil the moment clear() wipes the panel, so a closed bag
			-- costs one table lookup and nothing else.
			if b and b.Parent then
				b.Text = ClientFns.sellClockText("vip", st.sellAt - os.clock())
			end
			b = st and st.autoBtn
			if b and b.Parent then
				local left = st.autoAt - os.clock()
				-- On a bag that is not full the server rolls the deadline forward
				-- without selling, and pushes no snapshot. Roll it here too, or the
				-- row sticks on 0:00 and looks broken.
				if left <= 0 and (st.autoSec or 0) > 0 then
					st.autoAt = os.clock() + st.autoSec
					left = st.autoSec
				end
				b.Text = ClientFns.sellClockText("auto", left, st.full)
			end
		end
	end)
end

local function refreshBag()
	clear(bagP.Body)
	if not snap then
		return
	end
	rowBtn(bagP.Body, string.format("%d / %d slots    %s", snap.load or 0, snap.cap or 12, snap.pickName or "Wood Pickaxe"), function() end)
	-- The sell button always routes to the depot; only auto-sell has a clock.
	ClientFns.sellClockLoop()
	local st = { full = (tonumber(snap.load) or 0) >= (tonumber(snap.cap) or math.huge) }
	ClientFns.sellClock = st
	rowBtn(bagP.Body, "Sell at the depot", function()
		net:FireServer("sell")
	end)
	if snap.autoSellSec then
		st.autoSec = tonumber(snap.autoSellSec)
		local left = tonumber(snap.autoSellLeft) or st.autoSec
		st.autoAt = os.clock() + left
		st.autoBtn = rowBtn(bagP.Body, ClientFns.sellClockText("auto", left, st.full), function() end)
	end
	rowBtn(bagP.Body, "Open a pack", function()
		net:FireServer("open")
	end)

	-- Dirt, by the seam it came from, richest pile first.
	local dirt = {}
	if type(snap.haulMix) == "table" then
		local okD, Depth = pcall(function() return require(shared:WaitForChild("MineDepth")) end)
		local secName = {}
		if okD and Depth then
			for _, sec in ipairs(Depth.SECTIONS or {}) do
				secName[tostring(sec.id)] = tostring(sec.name or sec.id)
			end
		end
		for _, rec in pairs(snap.haulMix) do
			if type(rec) == "table"
				and ((tonumber(rec.load) or 0) > 0 or (tonumber(rec.pay) or 0) > 0) then
				local nm = secName[tostring(rec.section)]
					or ((rec.section == "mixed") and "Mixed dirt")
					or tostring(rec.section or "Dirt")
				dirt[#dirt + 1] = {
					name = nm,
					band = tostring(rec.band or "?"),
					load = tonumber(rec.load) or 0,
					pay = tonumber(rec.pay) or 0,
					cur = (rec.currency == "space") and "space" or "coins",
				}
			end
		end
		table.sort(dirt, function(x, y)
			if x.pay ~= y.pay then
				return x.pay > y.pay
			end
			return x.name < y.name
		end)
	end

	local counts = {}
	local order = {}
	for _, item in ipairs(snap.backpack or {}) do
		local spec = C.BLOCKS[item.kind]
		local name = spec and spec.name or item.kind
		if not counts[name] then
			counts[name] = 0
			table.insert(order, name)
		end
		counts[name] += 1
	end

	if #order == 0 and #dirt == 0 then
		rowBtn(bagP.Body, "Empty", function() end)
		return
	end
	for _, d in ipairs(dirt) do
		rowBtn(bagP.Body, string.format("%s  -  %s    %s slots    %s %s",
			d.name, d.band, shortNum(d.load), shortNum(d.pay), d.cur), function() end)
	end
	for _, name in ipairs(order) do
		rowBtn(bagP.Body, name .. "    x" .. tostring(counts[name]), function() end)
	end
end

local function refreshShop()
	clear(shopP.Body)
	if not snap then
		return
	end
	if false then
		return
	end
	local pick, bag = C.PICKAXES[snap.pickaxeTier + 1], C.BACKPACKS[snap.backpackTier + 1]
	if pick then
		rowBtn(shopP.Body, "Pickaxe  " .. pick.name .. "   " .. pick.price .. " gems", function()
			net:FireServer("buy", "pickaxe")
		end)
	else
		rowBtn(shopP.Body, "Pickaxe maxed", function() end)
	end
	if bag then
		rowBtn(shopP.Body, "Bag  " .. bag.name .. "  " .. bag.slots .. "   " .. bag.price .. " gems", function()
			net:FireServer("buy", "backpack")
		end)
	else
		rowBtn(shopP.Body, "Bag maxed", function() end)
	end
	--[[
		No pet-slot row. Three seats is everybody's number now, so there is no
		fourth to sell -- and the row used to read the cap as a literal 8, which
		would have kept offering seats the server refuses.
	]]
	rowBtn(shopP.Body, "Crate   " .. C.CRATE_PRICE .. " gems", function()
		net:FireServer("buy", "crate")
	end)
end

--[[
	Merge. Three of the same card -- same card, same rarity, same variant -- become
	one of the next variant up, and stardust can stand in for the third.

	This was a flat list of every card you own with no grouping, so you had to
	count copies by eye and the two buttons at the bottom did not say what they
	would consume. It is grouped now: one tile per set of identical copies, with
	the count on it, ready ones first, and the reason printed on the ones that are
	not.
]]
function ClientFns.mergeGroups()
	local groups, order = {}, {}
	for _, card in ipairs(snap.cards or {}) do
		local variant = card.variant or "Normal"
		local key = tostring(card.cardKey) .. "|" .. tostring(card.rarityId) .. "|" .. variant
		local g = groups[key]
		if not g then
			g = { card = card, variant = variant, n = 0, ids = {} }
			groups[key] = g
			table.insert(order, g)
		end
		g.n += 1
		table.insert(g.ids, card.id)
	end
	for _, g in ipairs(order) do
		g.next = C.nextVariant(g.variant)
		g.dustCost = C.vipPrice(math.floor(80 * (C.RARITY_MULT[g.card.rarityId] or 1)), snap and snap.vip)
		if not g.next then
			g.state, g.why = "top", "Already " .. g.variant
		elseif g.n >= 3 then
			g.state, g.why = "ready", g.variant .. "  ->  " .. g.next
		elseif g.n == 2 then
			g.state, g.why = "dust", "2 of 3  -  " .. shortNum(g.dustCost) .. " stardust fills the third"
		else
			g.state, g.why = "short", "Need 3 of the same card, rarity and variant"
		end
	end
--[[
		BEST FIRST. Always.

		Rarity descending is the default order everywhere in this game and this
		screen was still sorting by state then by count, so a wall of Commons
		came before a ready Mythic. Rarity leads; actionable-ness only breaks
		ties within a rarity, and the variant (Rainbow over Shiny over Normal)
		breaks ties within that.
	]]
	local stateRank = { ready = 1, dust = 2, short = 3, top = 4 }
	local VARIANT_RANK = { Normal = 1, Shiny = 2, Rainbow = 3 }
	table.sort(order, function(x, y)
		local rx = Cards.RARITY_RANK[x.card.rarityId] or 0
		local ry = Cards.RARITY_RANK[y.card.rarityId] or 0
		if rx ~= ry then
			return rx > ry
		end
		local vx = VARIANT_RANK[x.variant] or 0
		local vy = VARIANT_RANK[y.variant] or 0
		if vx ~= vy then
			return vx > vy
		end
		if stateRank[x.state] ~= stateRank[y.state] then
			return stateRank[x.state] < stateRank[y.state]
		end
		if x.n ~= y.n then
			return x.n > y.n
		end
		return tostring(x.card.name) < tostring(y.card.name)
	end)
	return order
end

--[[
	Merge.

	Rebuilt for legibility. It used to draw the full card face for every group --
	banner, art, name, type pill, variant, two stat chips and a trait, 527 times
	over: 37,227 instances and 1,851 labels at nine and ten pixels. None of that
	detail helps the decision. You are picking which pet to merge, and the three
	copies are identical by definition, so their stats are noise.

	What is left is the pet, its name, its rarity and the count -- plus one big
	button that says what clicking will do. Nothing on this screen is under
	eleven pixels.

	The filter is the other half. Six hundred tiles is not a list anyone reads,
	so it opens on the ones you can act on and keeps everything else one click
	away, which is what the dimmed-not-hidden rule was actually asking for.
]]
local MERGE_W, MERGE_H = 168, 200
local mergeFilter = "todo"
local mergeShown = 60
local MERGE_PAGE = 60

function ClientFns.mergeTile(parent, g, order)
	local rareCol = Cards.RARITY_COLOR[g.card.rarityId] or TEXT
	local ready = g.state == "ready"
	local canAfford = (snap and (snap.dust or 0) or 0) >= (g.dustCost or 0)
	local assist = g.state == "dust" and canAfford
	-- Short by stardust reads as "not yet", not as an offer.
	local shortDust = g.state == "dust" and not canAfford
	local live = ready or assist

	local slot = mk("TextButton", {
		BackgroundColor3 = live and BG2 or Color3.fromRGB(34, 29, 26),
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
	}, parent)
	round(slot, 14)
	local rim = stroke(slot, live and 2 or 1)
	rim.Color = live and rareCol or T.LINE
	rim.Transparency = live and 0.1 or 0.6

	-- Rarity reads as a colour band before anyone reads a word.
	local band = mk("Frame", {
		BackgroundColor3 = rareCol,
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundTransparency = live and 0 or 0.5,
	}, slot)
	round(band, 3)

	ClientFns.petViewport(slot, g.card, UDim2.fromOffset(8, 16), UDim2.new(1, -16, 0, 98))

	-- The count is the number that decides everything, so it is the biggest.
	local pill = mk("Frame", {
		BackgroundColor3 = ready and Color3.fromRGB(74, 176, 106)
			or assist and GOLD
			or Color3.fromRGB(62, 54, 48),
		BackgroundTransparency = 0,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 14),
		Size = UDim2.fromOffset(52, 26),
		ZIndex = 6,
	}, slot)
	round(pill, 13)
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT, TextSize = 15,
		TextColor3 = live and Color3.fromRGB(14, 22, 16) or TEXT,
		Size = UDim2.fromScale(1, 1), Text = g.n .. "/3", ZIndex = 7,
	}, pill)

	local nameL = mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT, TextSize = 14,
		TextColor3 = live and TEXT or MUTED,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(8, 120), Size = UDim2.new(1, -16, 0, 20),
		Text = g.card.name or "Pet",
	}, slot)
	nameL.TextXAlignment = Enum.TextXAlignment.Center
	local rareL = mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT_M, TextSize = 11,
		TextColor3 = live and rareCol or MUTED,
		Position = UDim2.fromOffset(8, 140), Size = UDim2.new(1, -16, 0, 14),
		Text = string.upper(Cards.RARITY_LABEL[g.card.rarityId] or g.card.rarityId or "")
			.. "  -  " .. tostring(g.variant or g.card.variant or "Normal"),
	}, slot)
	rareL.TextXAlignment = Enum.TextXAlignment.Center

	-- One button, and it says what happens.
	local label, fillCol, textCol
	if ready then
		label, fillCol, textCol = "MERGE", Color3.fromRGB(74, 176, 106), Color3.fromRGB(12, 24, 16)
	elseif assist then
		label, fillCol, textCol = "USE " .. shortNum(g.dustCost) .. " DUST", GOLD, T.ON_GOLD
	elseif shortDust then
		label, fillCol, textCol = "NEED " .. shortNum(g.dustCost) .. " DUST",
			Color3.fromRGB(52, 46, 42), GOLD
	elseif g.state == "top" then
		label, fillCol, textCol = "MAXED", Color3.fromRGB(52, 46, 42), MUTED
	else
		label, fillCol, textCol = "NEED " .. (3 - g.n) .. " MORE", Color3.fromRGB(52, 46, 42), MUTED
	end
	local act = mk("TextButton", {
		AutoButtonColor = live, BackgroundColor3 = fillCol,
		Font = FONT, TextSize = 14, TextColor3 = textCol, Text = label,
		Position = UDim2.fromOffset(8, 160), Size = UDim2.new(1, -16, 0, 32),
		Active = true, ZIndex = 5,
	}, slot)
	round(act, 9)

	local function press()
		if ready then
			net:FireServer("merge", { ids = { g.ids[1] }, useDust = false })
		elseif assist then
			net:FireServer("merge", { ids = { g.ids[1] }, useDust = true })
		elseif shortDust then
			showToast("Scrap cards at the Scrapper for stardust - "
				.. shortNum(g.dustCost) .. " fills the third copy of " .. g.card.name)
		elseif g.state == "top" then
			showToast(g.card.name .. " is already " .. g.variant .. " - there is nothing above it")
		else
			showToast("You have " .. g.n .. " of " .. g.card.name
				.. ". Merging needs 3 of the same card, rarity and variant.")
		end
	end
	act.MouseButton1Click:Connect(press)
	slot.MouseButton1Click:Connect(press)
	return slot
end

local function refreshMerge()
	clear(mergeP.Body)
	if not snap then
		return
	end
	local groups = ClientFns.mergeGroups()
	local ready, assist = 0, 0
	for _, g in ipairs(groups) do
		if g.state == "ready" then
			ready += 1
		elseif g.state == "dust" then
			assist += 1
		end
	end

	if #groups == 0 then
		rowBtn(mergeP.Body, "No cards yet - open a pack.", function() end)
		return
	end

	-- FILTERS. Three chips, counts on them, so the screen says what it holds
	-- before you scroll it.
	local bar = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 44),
		LayoutOrder = 0,
	}, mergeP.Body)
	local chips = {
		{ id = "todo", label = "TO MERGE", n = ready + assist },
		{ id = "ready", label = "READY NOW", n = ready },
		{ id = "all", label = "EVERYTHING", n = #groups },
	}
	for i, c in ipairs(chips) do
		local on = mergeFilter == c.id
		local b = mk("TextButton", {
			AutoButtonColor = true,
			BackgroundColor3 = on and GOLD or BG2,
			Font = FONT, TextSize = 14,
			TextColor3 = on and T.ON_GOLD or TEXT,
			Text = c.label .. "  " .. c.n,
			Position = UDim2.fromOffset((i - 1) * 176, 4),
			Size = UDim2.fromOffset(168, 36),
		}, bar)
		round(b, 10)
		if not on then
			stroke(b, 1)
		end
		b.MouseButton1Click:Connect(function()
			mergeFilter = c.id
			mergeShown = MERGE_PAGE
			refreshMerge()
		end)
	end
	local dustChip = mk("Frame", {
		BackgroundColor3 = BG2,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 4),
		Size = UDim2.fromOffset(150, 36),
	}, bar)
	round(dustChip, 10)
	stroke(dustChip, 1)
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = T.DUST,
		Size = UDim2.fromScale(1, 1),
		Text = shortNum(snap.dust or 0) .. " STARDUST",
	}, dustChip)
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT_M, TextSize = 13, TextColor3 = MUTED,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(544, 4), Size = UDim2.new(1, -706, 0, 36),
		Text = "Three of the same card make one of the next variant.",
	}, bar)

	local show = {}
	for _, g in ipairs(groups) do
		if mergeFilter == "all"
			or (mergeFilter == "ready" and g.state == "ready")
			or (mergeFilter == "todo" and (g.state == "ready" or g.state == "dust")) then
			table.insert(show, g)
		end
	end
	if #show == 0 then
		rowBtn(mergeP.Body, mergeFilter == "ready"
			and "Nothing is ready to merge yet. Try TO MERGE or EVERYTHING."
			or "Nothing to merge yet - open more packs.", function() end)
		return
	end

	local grid = mk("Frame", {
		Name = "Groups",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
	}, mergeP.Body)
	mk("UIGridLayout", {
		CellPadding = UDim2.fromOffset(12, 12),
		CellSize = UDim2.fromOffset(MERGE_W, MERGE_H),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)

	-- A hard cap on what is drawn at once. Six hundred pet viewports is a
	-- visible hitch on a phone, and nobody reads past the first two rows.
	local cap = math.min(#show, mergeShown)
	for i = 1, cap do
		ClientFns.mergeTile(grid, show[i], i)
	end
	if cap < #show then
		local more = rowBtn(mergeP.Body, ("Show %d more  (%d of %d)")
			:format(math.min(MERGE_PAGE, #show - cap), cap, #show), function()
			mergeShown += MERGE_PAGE
			refreshMerge()
		end)
		if more then
			more.LayoutOrder = 2
		end
	end
end

--[[
	The Scrapper.

	It used to list only cards and only pay stardust, so a bad rune or a Common
	helmet had nowhere to go. Now everything you own that you do not want has an
	exit: cards pay stardust (or gems at a deliberately poor rate, because gems
	are the cross-run currency and this is an escape hatch, not an income), runes
	and gear pay gems.
]]
--[[
	COSTS AND PAYOUTS MUST NOT LOOK THE SAME.

	The old Scrapper drew three identical grey rows per card:

	    Power-up  Bolt Crab   25 stardust      <- SPENDS 25
	    Scrap     Bolt Crab   +16 stardust     <- PAYS 16
	    Scrap     Bolt Crab   +1 gems          <- PAYS 1

	Same font, same colour, same shape, one plus sign between them. With 527
	cards that is roughly 1,581 rows of it, and the honest question the player
	asked was "is it costing me dust or giving me dust?"

	Three things fix that. Spending and earning are on SEPARATE TABS, so the two
	can never sit next to each other. Payouts are green and prefixed +, costs
	are gold and prefixed -. And duplicates stack into one tile with a count,
	which is what turns a list of 527 rows into a screen you can read.

	Selection is multiple and the totals are live, because the actual job here
	is "dump forty things I do not want", and doing that one confirm at a time
	was the real cost of the old screen.
]]
local function refreshDust()
	clear(dustP.Body)
	local oldBar = dustP:FindFirstChild("ScrapBar")
	if oldBar then
		oldBar:Destroy()
	end
	if not snap then
		return
	end
	local Runes = require(shared:WaitForChild("MineRunes"))
	local Gear = require(shared:WaitForChild("MineGear"))

	local sel = scrapUI.sel
	local tab = scrapUI.tab

	-- A plain explanatory line. MineInventoryView has `note` for this; this file
	-- does not, and one shared helper is not worth hoisting for three callers.
	local function scrapNote(text, order)
		local f = mk("Frame", {
			BackgroundColor3 = BG2,
			Size = UDim2.new(1, -8, 0, 44),
			LayoutOrder = order or 3,
		}, dustP.Body)
		round(f, 8)
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Font = FONT_M,
			TextSize = 13,
			TextColor3 = MUTED,
			Text = text,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -24, 1, 0),
		}, f)
		return f
	end

	----------------------------------------------------------------------------
	-- What you are holding, and what it is worth.
	----------------------------------------------------------------------------
	local head = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 34),
		LayoutOrder = 0,
	}, dustP.Body)
	local function walletPill(text, colour, x)
		local pillF = mk("Frame", {
			BackgroundColor3 = BG2,
			Position = UDim2.fromOffset(x, 0),
			Size = UDim2.fromOffset(190, 30),
		}, head)
		round(pillF, 8)
		stroke(pillF, 1)
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Font = FONT,
			TextSize = 15,
			TextColor3 = colour,
			Text = text,
			Size = UDim2.fromScale(1, 1),
		}, pillF)
		return pillF
	end
	walletPill(shortNum(snap.dust or 0) .. " STARDUST", Color3.fromRGB(190, 150, 255), 0)
	walletPill(shortNum(snap.gems or 0) .. " GEMS", T.GEM, 198)

	----------------------------------------------------------------------------
	-- Tabs. Power-up is the only one that spends, and it lives alone.
	----------------------------------------------------------------------------
	local tabRow = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 34),
		LayoutOrder = 1,
	}, dustP.Body)
	local tabs = {
		{ "cards", "CARDS" }, { "packs", "PACKS" }, { "runes", "RUNES" }, { "gear", "GEAR" }, { "power", "POWER-UP" },
	}
	for ti, t in ipairs(tabs) do
		local on = (tab == t[1])
		local spend = (t[1] == "power")
		local b = mk("TextButton", {
			AutoButtonColor = true,
			BackgroundColor3 = on and (spend and GOLD or T.GREEN) or BG2,
			Font = FONT,
			TextSize = 14,
			TextColor3 = on and Color3.fromRGB(16, 20, 16) or (spend and GOLD or MUTED),
			Text = t[2],
			Position = UDim2.fromOffset((ti - 1) * 118, 0),
			Size = UDim2.fromOffset(112, 30),
		}, tabRow)
		round(b, 7)
		if spend and not on then
			stroke(b, 1, GOLD)
		end
		b.MouseButton1Click:Connect(function()
			scrapUI.tab = t[1]
			scrapUI.sel = {}
			refreshDust()
		end)
	end

	local grid = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
	}, dustP.Body)
	mk("UIGridLayout", {
		CellPadding = UDim2.fromOffset(8, 8),
		CellSize = UDim2.fromOffset(168, 104),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)

	-- One tile. `ids` is every copy this tile stands for, so ticking it ticks
	-- the whole stack of duplicates at once.
	local function tile(order, title, sub, payText, payColour, colour, ids, onClick)
		local picked = false
		for _, id in ipairs(ids) do
			if sel[id] then
				picked = true
				break
			end
		end
		local f = mk("Frame", { BackgroundColor3 = picked and T.BG3 or BG2, LayoutOrder = order }, grid)
		round(f, 8)
		stroke(f, picked and 2.5 or 1.5, picked and T.GREEN or colour)
		mk("Frame", { BackgroundColor3 = colour, Size = UDim2.new(1, 0, 0, 5) }, f)
		local nameL = mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = TEXT,
			Text = title, TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(10, 12), Size = UDim2.new(1, -20, 0, 18),
		}, f)
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT_M, TextSize = 12, TextColor3 = MUTED,
			Text = sub, TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(10, 32), Size = UDim2.new(1, -20, 0, 16),
		}, f)
		-- The number, in the colour of its direction. Green earns, gold spends.
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 16, TextColor3 = payColour,
			Text = payText, TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(10, 56), Size = UDim2.new(1, -20, 0, 20),
		}, f)
		if #ids > 1 then
			local badge = mk("Frame", {
				BackgroundColor3 = colour, AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -8, 0, 12), Size = UDim2.fromOffset(38, 20),
			}, f)
			round(badge, 10)
			mk("TextLabel", {
				BackgroundTransparency = 1, Font = FONT, TextSize = 12,
				TextColor3 = Color3.fromRGB(18, 16, 12), Text = "x" .. #ids,
				Size = UDim2.fromScale(1, 1),
			}, badge)
		end
		if picked then
			local tick = mk("Frame", {
				BackgroundColor3 = T.GREEN, AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -8, 1, -8), Size = UDim2.fromOffset(22, 22),
			}, f)
			round(tick, 11)
			mk("TextLabel", {
				BackgroundTransparency = 1, Font = FONT, TextSize = 14,
				TextColor3 = Color3.fromRGB(10, 26, 16), Text = "v", Size = UDim2.fromScale(1, 1),
			}, tick)
		end
		-- No text, but an unset TextSize defaults to 8 and every readability
		-- audit then counts one "unreadable label" per tile.
		local hit = mk("TextButton", {
			BackgroundTransparency = 1, Text = "", TextSize = 14, AutoButtonColor = false,
			Size = UDim2.fromScale(1, 1), ZIndex = 4,
		}, f)
		hit.MouseButton1Click:Connect(onClick)
		return f
	end

	local totalDust, totalGems, totalN = 0, 0, 0

	if tab == "cards" then
		-- Equipped pets are not scrap, so they are never offered.
		local worn = {}
		for _, id in ipairs(snap.equipped or {}) do
			worn[id] = true
		end
		local groups, order = {}, {}
		for _, card in ipairs(snap.cards or {}) do
			if not worn[card.id] then
				local key = tostring(card.name) .. "|" .. tostring(card.rarityId)
				local g = groups[key]
				if not g then
					g = { name = card.name, rarity = card.rarityId, ids = {},
						dust = C.vipPayout(C.salvageDust(card), snap and snap.vip) }
					groups[key] = g
					order[#order + 1] = g
				end
				table.insert(g.ids, card.id)
			end
		end
		-- Worst first: the whole point of this screen is clearing junk, so the
		-- junk is what it puts in front of you.
		table.sort(order, function(x, y)
			local rx = Cards.RARITY_RANK[x.rarity or ""] or 0
			local ry = Cards.RARITY_RANK[y.rarity or ""] or 0
			if rx ~= ry then
				return rx < ry
			end
			if #x.ids ~= #y.ids then
				return #x.ids > #y.ids
			end
			return tostring(x.name) < tostring(y.name)
		end)
		for i, g in ipairs(order) do
			local col = Cards.RARITY_COLOR[g.rarity or ""] or MUTED
			tile(i, tostring(g.name),
				(Cards.RARITY_LABEL[g.rarity or ""] or tostring(g.rarity)),
				"+" .. shortNum(g.dust) .. " each", T.GREEN, col, g.ids, function()
				local anyOn = false
				for _, id in ipairs(g.ids) do
					if sel[id] then anyOn = true break end
				end
				for _, id in ipairs(g.ids) do
					sel[id] = (not anyOn) or nil
				end
				refreshDust()
			end)
		end
		for _, g in ipairs(order) do
			for _, id in ipairs(g.ids) do
				if sel[id] then
					totalN += 1
					totalDust += g.dust
					totalGems += math.max(1, math.floor(g.dust / 10))
				end
			end
		end

	elseif tab == "packs" then
		local PacksMod = require(shared:WaitForChild("MinePackConfig"))
		--[==[
			Ore packs carry their ore's tier, and across a roster this size the name alone
			does not place one: "Magnetite Ore Pack" says nothing about whether
			that is an early find or a deep one. The tier does, so it rides on
			the subtitle where the generic "Unopened pack" used to sit.
		]==]
		local ZonePacks
		pcall(function()
			ZonePacks = require(shared:WaitForChild("MineZonePacks"))
		end)
		local function packSub(pk)
			local def = ZonePacks and ZonePacks.get and ZonePacks.get(pk.packId)
			if def and def.kind == "ore" and def.tier then
				return "Ore pack  |  tier " .. tostring(def.tier)
			end
			return "Unopened pack"
		end
		local list = {}
		for idx, pk in ipairs(snap.packs or {}) do
			local dust = 0
			if PacksMod.packScrapDust then
				if pk.packId then
					dust = PacksMod.packScrapDust(pk.packId)
				elseif pk.setId and PacksMod.PACK_BY_ID and PacksMod.PACK_BY_ID.loam_pack then
					dust = PacksMod.packScrapDust(PacksMod.PACK_BY_ID.loam_pack)
				end
			end
			if dust > 0 then
				dust = C.vipPayout(dust, snap and snap.vip)
			end
			if dust > 0 then
				table.insert(list, {
					idx = idx,
					name = pk.packName or pk.packId or pk.setId or ("Pack " .. idx),
					sub = packSub(pk),
					dust = dust,
					-- The pack's own id, so a bag that shifts before SCRAP is
					-- pressed still scraps the packs that were ticked.
					id = pk.uid or tostring(idx),
				})
			end
		end
		table.sort(list, function(a, b)
			if a.dust ~= b.dust then
				return a.dust < b.dust
			end
			return a.idx < b.idx
		end)
		for i, row in ipairs(list) do
			tile(i, tostring(row.name), tostring(row.sub or "Unopened pack"),
				"+" .. shortNum(row.dust) .. " stardust", T.GREEN, Color3.fromRGB(190, 150, 255), { row.id }, function()
				sel[row.id] = (not sel[row.id]) or nil
				refreshDust()
			end)
			if sel[row.id] then
				totalN += 1
				totalDust += row.dust
				totalGems += math.max(1, math.floor(row.dust / 10))
			end
		end
		if #list == 0 then
			scrapNote("No card packs to scrap. Currency / rune / gear packs stay sealed.")
		end

	elseif tab == "runes" then
		local runes = Runes.looseRunes(snap)
		for i, r in ipairs(runes) do
			local gems = Runes.scrapGems(r)
			tile(i, string.format("%s %s", tostring(r.kind), tostring(r.stat)),
				string.format("+%.1f%%   tier %s", (r.pct or 0) * 100, tostring(r.tier or 1)),
				"+" .. shortNum(gems) .. " gems", T.GEM, T.GEM, { r.id }, function()
				sel[r.id] = (not sel[r.id]) or nil
				refreshDust()
			end)
			if sel[r.id] then
				totalN += 1
				totalGems += gems
			end
		end
		if #runes == 0 then
			scrapNote("No loose runes. Socketed runes cannot be scrapped -- unsocket one first.")
		end

	elseif tab == "gear" then
		local worn = {}
		for _, id in pairs(snap.equippedGear or {}) do
			if id then worn[id] = true end
		end
		local list = {}
		for _, g in ipairs(snap.gear or {}) do
			if not worn[g.id] then table.insert(list, g) end
		end
		table.sort(list, function(x, y)
			local rx = Gear.RARITY_RANK and Gear.RARITY_RANK[x.rarity or ""] or 0
			local ry = Gear.RARITY_RANK and Gear.RARITY_RANK[y.rarity or ""] or 0
			return rx < ry
		end)
		for i, g in ipairs(list) do
			local gems = Gear.scrapGems(g)
			local col = (Gear.RARITY_COLOR and Gear.RARITY_COLOR[g.rarity or ""]) or MUTED
			tile(i, (Gear.RARITY_LABEL and Gear.RARITY_LABEL[g.rarity or ""]) or tostring(g.rarity),
				(Gear.SLOT_LABEL and Gear.SLOT_LABEL[g.slot]) or tostring(g.slot),
				"+" .. shortNum(gems) .. " gems", T.GEM, col, { g.id }, function()
				sel[g.id] = (not sel[g.id]) or nil
				refreshDust()
			end)
			if sel[g.id] then
				totalN += 1
				totalGems += gems
			end
		end
		if #list == 0 then
			scrapNote("No spare gear. Equipped pieces are not offered.")
		end

	else
		--[[
			POWER-UP SPENDS. It is on its own tab for exactly that reason: on the
			old screen it sat one row above "Scrap ... +16 stardust" in identical
			styling, and the minus sign was the only thing telling you which way
			the stardust was going.
		]]
		scrapNote("This tab SPENDS stardust to level a card. Everything else here earns it.", 0)
		local worn = {}
		for _, id in ipairs(snap.equipped or {}) do
			worn[id] = true
		end
		local shownAny = false
		for i, card in ipairs(snap.cards or {}) do
			local cost = C.vipPrice(C.powerDustCost(card.powerLevel or 1), snap and snap.vip)
			local afford = (snap.dust or 0) >= cost
			local col = Cards.RARITY_COLOR[card.rarityId or ""] or MUTED
			shownAny = true
			tile(i, tostring(card.name),
				string.format("level %d%s", card.powerLevel or 1, worn[card.id] and "  equipped" or ""),
				"-" .. shortNum(cost) .. " stardust", afford and GOLD or Color3.fromRGB(190, 80, 80),
				col, {}, function()
				if not afford then
					showToast("Not enough stardust")
					return
				end
				net:FireServer("power", card.id)
			end)
			if i >= 120 then
				break
			end
		end
		if not shownAny then
			scrapNote("No cards to power up.")
		end
	end

	----------------------------------------------------------------------------
	-- The action bar. Outside the scroll, so the totals never scroll away while
	-- you are still choosing.
	----------------------------------------------------------------------------
	if tab ~= "power" then
		local bar = mk("Frame", {
			Name = "ScrapBar",
			BackgroundColor3 = BG2,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -12),
			Size = UDim2.new(1, -32, 0, 68),
			ZIndex = 34,
		}, dustP)
		round(bar, 10)
		stroke(bar, 1.5, totalN > 0 and T.GREEN or Color3.fromRGB(58, 58, 68))
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 16,
			TextColor3 = totalN > 0 and TEXT or MUTED,
			Text = (totalN > 0) and (totalN .. " selected") or "Nothing selected",
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(16, 0), Size = UDim2.fromOffset(160, 68),
			ZIndex = 35,
		}, bar)

		local function actionBtn(text, colour, textCol, x, w, fn)
			local b = mk("TextButton", {
				AutoButtonColor = totalN > 0,
				BackgroundColor3 = (totalN > 0) and colour or Color3.fromRGB(54, 54, 62),
				Font = FONT, TextSize = 15,
				TextColor3 = (totalN > 0) and textCol or MUTED,
				Text = text,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -x, 0.5, 0),
				Size = UDim2.fromOffset(w, 44),
				ZIndex = 35,
			}, bar)
			round(b, 8)
			b.MouseButton1Click:Connect(function()
				if totalN == 0 then
					return
				end
				fn()
			end)
			return b
		end

		local kind = (tab == "cards") and "card"
			or (tab == "packs") and "pack"
			or (tab == "runes") and "rune"
			or "gear"
		local function fire(into)
			local ids = {}
			for id in pairs(sel) do
				table.insert(ids, id)
			end
			net:FireServer("scrapMany", { kind = kind, ids = ids, into = into })
			scrapUI.sel = {}
		end

		actionBtn("CLEAR", T.BG3, TEXT, 16, 96, function()
			scrapUI.sel = {}
			refreshDust()
		end)
		if tab == "cards" or tab == "packs" then
			actionBtn("SCRAP  +" .. shortNum(totalGems) .. " GEMS", T.GEM,
				Color3.fromRGB(10, 22, 30), 122, 210, function() fire("gems") end)
			actionBtn("SCRAP  +" .. shortNum(totalDust) .. " STARDUST",
				Color3.fromRGB(170, 130, 245), Color3.fromRGB(16, 12, 26), 340, 250,
				function() fire("dust") end)
		else
			actionBtn("SCRAP  +" .. shortNum(totalGems) .. " GEMS", T.GEM,
				Color3.fromRGB(10, 22, 30), 122, 230, function() fire("gems") end)
		end
	end
end

--[[
	The Fossil Bench panel stood here. It had already been reduced to a single
	"fossils are retired" notice, kept in case a stale waypoint still opened it.
	Nothing routes to it any more -- the plaza station is gone and the panel key
	is out of the router, which no-ops on a key it does not know -- so the panel
	is gone too rather than sitting unreachable with a fossil name on it.
]]
refreshZones = function()
	if not snap then
		return
	end
	local gems = math.floor(tonumber(snap.gems) or 0)
	local okMap, errMap = pcall(ZoneMapView.render, zoneP.Body, {
		snap = snap,
		selectedZoneId = snap.zoneId,
		onCamp = function()
			net:FireServer("camp")
		end,
		onEnter = function(zoneId)
			net:FireServer("enterZone", zoneId)
			zoneP.Visible = false
		end,
		onBuy = function(z)
			local cost = math.floor(tonumber(z.buyCost) or 0)
			local needR = tonumber(z.minRebirth) or 0
			if (tonumber(snap.prestige) or 0) < needR then
				showToast("Need Rebirth " .. tostring(needR) .. "+")
				return
			end
			if gems < cost then
				showToast(string.format("Need %s gems (you have %s)", tostring(cost), tostring(gems)))
				return
			end
			net:FireServer("buyZone", z.id)
		end,
	})
	if not okMap then
		warn("[Mine] Planet map failed: ", errMap)
		showToast("Planet map failed to load")
	end
end

--[[
	Rebirth asks first.

	It wipes the coin ladder, the zone you unlocked and everything you were
	holding, and it used to happen on a single click of a row in a list. This
	says what you keep and what you lose before it does that.
]]
local confirmMenu
function ClientFns.confirmRebirth()
	if confirmMenu and confirmMenu.Parent then
		confirmMenu.Visible = true
		return
	end
	local f = mk("Frame", {
		Name = "ConfirmRebirth", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.44), Size = UDim2.fromOffset(460, 280),
		BackgroundColor3 = Color3.fromRGB(46, 52, 78), ZIndex = 90,
	}, gui)
	confirmMenu = f
	round(f, 18)
	stroke(f, 2)
	mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 22),
		Size = UDim2.new(1, 0, 0, 32), Font = FONT, TextSize = 24,
		TextColor3 = Color3.fromRGB(255, 255, 255), TextStrokeTransparency = 1,
		Text = "Rebirth?", ZIndex = 91,
	}, f)
	mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 62),
		Size = UDim2.new(1, -48, 0, 100), Font = FONT_M, TextSize = 14,
		TextColor3 = Color3.fromRGB(212, 216, 232), TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = (function()
			local nextR = (snap and (snap.prestige or 0) or 0) + 1
			local Skills = require(shared:WaitForChild("MineSkillData"))
			local advice = (snap and snap.rebirthAdvice)
				or (Skills.rebirthAdvice and Skills.rebirthAdvice(snap and snap.coins, snap and snap.prestige))
			local minCoins = (advice and advice.minCoins)
				or (snap and snap.rebirthMinCoins)
				or (Skills.minRebirthCoins and Skills.minRebirthCoins(nextR))
				or 0
			local cost = (advice and advice.cost) or (snap and snap.rebirthCost) or 0
			local early = (snap and (snap.coins or 0) or 0) < minCoins
			return "You lose coins, the pick ladder, and mine depth.\n"
				.. "You keep gems, cards, runes, gear, skills, skins, charms and your ore pouch.\n\n"
				.. string.format("Fee %s  |  Minimum bank %s%s\n",
					shortNum(cost), shortNum(minCoins), early and "  |  early" or "")
				.. string.format("Rebirth %d grants %d skill points + %d temper tokens + %d gems.",
					nextR,
					(snap and snap.rebirthTokens) or (advice and advice.skillPoints) or 0,
					(snap and snap.rebirthTokenGrant) or (advice and advice.temperTokens) or 0,
					(advice and tonumber(advice.gems)) or 0)
		end)(),
		ZIndex = 91,
	}, f)
	local row = mk("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 176),
		Size = UDim2.new(1, -48, 0, 46), ZIndex = 91,
	}, f)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 12),
	}, row)
	local function choice(text, colour, dark, fn)
		local b = mk("TextButton", {
			AutoButtonColor = true, BackgroundColor3 = colour, Font = FONT, TextSize = 16,
			TextColor3 = dark and Color3.fromRGB(12, 24, 16) or Color3.fromRGB(238, 240, 248),
			Text = text, Size = UDim2.fromOffset(180, 42), ZIndex = 92,
		}, row)
		round(b, 9)
		b.MouseButton1Click:Connect(fn)
	end
	choice("Rebirth", Color3.fromRGB(96, 190, 104), true, function()
		f.Visible = false
		presP.Visible = false
		Audio.play("rebirth")
		net:FireServer("prestige")
	end)
	choice("Not yet", Color3.fromRGB(70, 74, 96), false, function()
		f.Visible = false
	end)
end

--[[
	"YOUR TOOL IS TOO WEAK TO DAMAGE THIS BLOCK"

	Breaking power is a wall, and a wall that does not explain itself reads as
	the game being broken -- you swing, the number never moves, nothing says
	why. So this has to be immediate and unmissable, and it has to name what
	would fix it.

	Sits bottom-centre above Roblox's hotbar, since this game has no custom one.
	One label, reused and re-shown rather than rebuilt: the server throttles to
	1.2s but a wall is something players hammer at, and churning a frame per
	swing during a dig loop drops frames.

	Sized in scale with a UISizeConstraint, per the mobile rule -- and lifted
	further up on touch, where Roblox's hotbar is taller and would cover it.
]]
function ClientFns.tooWeak(payload)
	local need = tonumber(type(payload) == "table" and payload.need) or 0
	local have = tonumber(type(payload) == "table" and payload.have) or 0
	local ore = type(payload) == "table" and payload.ore or nil
	local touch = UIS.TouchEnabled
	if not (ClientFns.weakLabel and ClientFns.weakLabel.Parent) then
		local f = mk("Frame", {
			Name = "TooWeak", AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, touch and -156 or -98),
			Size = UDim2.new(0.9, 0, 0, touch and 34 or 30),
			BackgroundColor3 = Color3.fromRGB(28, 10, 12),
			BackgroundTransparency = 0.25, ZIndex = 88, Visible = false,
		}, gui)
		mk("UISizeConstraint", { MinSize = Vector2.new(200, 26), MaxSize = Vector2.new(560, 40) }, f)
		round(f, 8)
		ClientFns.weakLabel = f
		ClientFns.weakText = mk("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0),
			Position = UDim2.fromOffset(8, 0),
			Font = FONT, TextSize = touch and 14 or 15,
			TextColor3 = Color3.fromRGB(255, 96, 96), TextStrokeTransparency = 0.4,
			TextTruncate = Enum.TextTruncate.AtEnd, Text = "", ZIndex = 89,
		}, f)
	end
	-- Name the ore when it is the ore that is blocking, not the depth. Telling
	-- someone "too weak" while they stand somewhere they can already mine is
	-- confusing unless it says which rock refused.
	local msg = "Your tool is too weak to damage this block"
	if ore and need > have then
		msg = ("%s needs breaking power %d — yours is %d"):format(tostring(ore), need, have)
	elseif need > have then
		msg = ("Too weak: this depth needs breaking power %d — yours is %d"):format(need, have)
	end
	ClientFns.weakText.Text = msg
	ClientFns.weakLabel.Visible = true
	-- Token so an earlier hide cannot cancel a later show.
	ClientFns.weakToken = (ClientFns.weakToken or 0) + 1
	local mine = ClientFns.weakToken
	task.delay(2.2, function()
		if ClientFns.weakToken == mine and ClientFns.weakLabel then
			ClientFns.weakLabel.Visible = false
		end
	end)
end

--[[
	THE SEAM GATE.

	Depth is bought, and this is where it is bought. It opens on the refusal
	itself rather than sitting in a menu, because the moment a player learns a
	seam exists is the moment their pickaxe stops working on it -- sending them
	to go find a shop would be teaching the rule twice.

	Built once and relabelled, not rebuilt: the server fires this on every swing
	into locked rock, and tearing down a frame ten times a second to draw the
	same thing with a different number in it is how a dig loop drops frames.
]]
-- Held on ClientFns, not as top-level locals: this script sits a handful of
-- registers under Luau's 200 top-level local ceiling, and going over fails to
-- compile the whole client rather than just this panel.
function ClientFns.confirmSeam(payload)
	if type(payload) ~= "table" then
		return
	end
	local seam = tonumber(payload.seam) or 0
	local price = tonumber(payload.price) or 0
	local coins = tonumber(payload.coins) or (snap and snap.coins) or 0
	local minutes = tonumber(payload.minutes) or 30
	--[[
		`price <= 0` used to bail here. Seams are free as of 2026-10-05, so that
		guard would have swallowed every seam panel in the game and recreated
		the exact "everyone stops at layer 500" blocker this chain was fixed
		for. Only a missing seam is a reason not to open.
	]]
	if seam <= 0 or price < 0 then
		return
	end
	-- Already deciding. Do not yank the panel out from under a click.
	if ClientFns.seamMenu and ClientFns.seamMenu.Parent and ClientFns.seamMenu.Visible then
		return
	end
	if not (ClientFns.seamMenu and ClientFns.seamMenu.Parent) then
		--[[
			MOBILE. Sized in SCALE with a UISizeConstraint, not in offsets.

			A fixed 460px frame is wider than the safe area on a phone, so it
			would have been clipped on exactly the devices most of this game's
			players are on. Scale width plus a Max of 460 keeps the desktop look
			and lets it shrink; the Min stops it collapsing to unreadable.

			The button row is anchored to the BOTTOM of the frame rather than at
			a fixed y, so a taller body on a narrow screen -- where the text
			wraps to more lines -- pushes nothing off the card.
		]]
		local touch = UIS.TouchEnabled
		local f = mk("Frame", {
			Name = "ConfirmSeam", AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.44),
			Size = UDim2.new(0.88, 0, 0, touch and 292 or 268),
			BackgroundColor3 = Color3.fromRGB(46, 52, 78), ZIndex = 90,
		}, gui)
		mk("UISizeConstraint", {
			MinSize = Vector2.new(288, 244), MaxSize = Vector2.new(460, 320),
		}, f)
		ClientFns.seamMenu = f
		round(f, 18)
		stroke(f, 2)
		ClientFns.seamTitle = mk("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 20),
			Size = UDim2.new(1, -24, 0, 34), Font = FONT, TextSize = touch and 21 or 24,
			TextColor3 = Color3.fromRGB(255, 255, 255), TextStrokeTransparency = 1,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = "", ZIndex = 91,
		}, f)
		ClientFns.seamBody = mk("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.new(0.06, 0, 0, 58),
			Size = UDim2.new(0.88, 0, 1, -128), Font = FONT_M, TextSize = touch and 13 or 14,
			TextColor3 = Color3.fromRGB(212, 216, 232), TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top, Text = "", ZIndex = 91,
		}, f)
		-- Anchored to the bottom edge, so wrapping never shoves the buttons off.
		local row = mk("Frame", {
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -18),
			Size = UDim2.new(0.88, 0, 0, touch and 48 or 44), ZIndex = 91,
		}, f)
		mk("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 10),
		}, row)
		-- Scale widths: the pair always fits, down to a 288px card.
		ClientFns.seamBuy = mk("TextButton", {
			AutoButtonColor = true, BackgroundColor3 = Color3.fromRGB(96, 190, 104),
			Font = FONT, TextSize = touch and 15 or 16, TextColor3 = Color3.fromRGB(12, 24, 16),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = "", Size = UDim2.new(0.58, -5, 1, 0), ZIndex = 92,
		}, row)
		round(ClientFns.seamBuy, 9)
		ClientFns.seamBuy.MouseButton1Click:Connect(function()
			-- The server re-prices and re-checks affordability; this only asks.
			if ClientFns.seamMenu then
				ClientFns.seamMenu.Visible = false
			end
			net:FireServer("buySeam", { seam = tonumber(ClientFns.seamMenu and ClientFns.seamMenu:GetAttribute("Seam")) or 0 })
		end)
		local back = mk("TextButton", {
			AutoButtonColor = true, BackgroundColor3 = Color3.fromRGB(70, 74, 96),
			Font = FONT, TextSize = touch and 15 or 16, TextColor3 = Color3.fromRGB(238, 240, 248),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = "Not yet", Size = UDim2.new(0.42, -5, 1, 0), ZIndex = 92,
		}, row)
		round(back, 9)
		back.MouseButton1Click:Connect(function()
			ClientFns.seamMenu.Visible = false
		end)
	end
	ClientFns.seamMenu:SetAttribute("Seam", seam)
	ClientFns.seamTitle.Text = string.format("Layer %d is sealed", seam)
	local short = shortNum and shortNum(price) or tostring(price)
	local free = price <= 0
	local afford = free or coins >= price
	if free then
		-- Free seams: the panel is the moment you break through, not a till.
		-- No price, no coin balance, no "come back when you can afford it".
		ClientFns.seamBody.Text = string.format(
			"The rock below layer %d is sealed. Break the seam and the mine keeps going.\n\nNo cost — just bring a tool strong enough for what is down there.",
			seam
		)
	else
		ClientFns.seamBody.Text = string.format(
			"Buy through the seam to mine below layer %d.\n\nCost %s coins — about %d minutes of mining at this depth.\nYou have %s.%s",
			seam, short, minutes, shortNum and shortNum(coins) or tostring(coins),
			afford and "" or "\n\nKeep mining above the seam and come back."
		)
	end
	ClientFns.seamBuy.Text = free and "Break the seam"
		or (afford and ("Open the seam — " .. short) or ("Need " .. short))
	ClientFns.seamBuy.BackgroundColor3 = afford and Color3.fromRGB(96, 190, 104) or Color3.fromRGB(88, 92, 112)
	ClientFns.seamBuy.TextColor3 = afford and Color3.fromRGB(12, 24, 16) or Color3.fromRGB(196, 200, 216)
	ClientFns.seamBuy.Active = afford
	ClientFns.seamBuy.AutoButtonColor = afford
	ClientFns.seamMenu.Visible = true
end

--[[
	THE WANDERING TRADER'S SHELF.

	Opened by the server firing "traderShop" when the stall prompt is used. The
	payload is the whole offer -- rotation, where, how long left, and the stock
	rows with their prices -- so this panel never computes a price or decides
	what is on sale. It cannot: MineTrader.stockFor is the authority and
	Verbs.buyTraderCase re-derives all of it anyway, so anything worked out here
	could only ever disagree.

	REBUILT EVERY OPEN rather than cached like the seam panel. A trader's shelf
	is 3-5 rows that change with the rotation and differ per outpost, so a cached
	frame would have to be diffed against a new shelf every time -- more code than
	just making five rows, and one more thing to get wrong when a row vanishes.

	The countdown is cosmetic. It ticks from `secondsLeft` so a player can see the
	roster is about to change, but nothing is gated on it here; if it runs out
	mid-purchase the server simply says there is no trader there.
]]
function ClientFns.showTraderShop(payload)
	if type(payload) ~= "table" or type(payload.stock) ~= "table" then
		return
	end
	if ClientFns.traderMenu and ClientFns.traderMenu.Parent then
		ClientFns.traderMenu:Destroy()
		ClientFns.traderMenu = nil
	end
	if ClientFns.traderTick then
		ClientFns.traderTick:Disconnect()
		ClientFns.traderTick = nil
	end
	local touch = UIS.TouchEnabled
	local stock = payload.stock
	local rows = math.max(1, #stock)
	-- Height follows the shelf: a 3-row trader should not open a 5-row card with
	-- a hole in it.
	local rowH = touch and 62 or 58
	local f = mk("Frame", {
		Name = "TraderShop", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.new(0.9, 0, 0, 132 + rows * (rowH + 8)),
		BackgroundColor3 = Color3.fromRGB(44, 40, 60), ZIndex = 90,
	}, gui)
	mk("UISizeConstraint", {
		MinSize = Vector2.new(300, 240), MaxSize = Vector2.new(520, 560),
	}, f)
	ClientFns.traderMenu = f
	round(f, 18)
	stroke(f, 2)

	mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 16),
		Size = UDim2.new(1, -24, 0, 30), Font = FONT, TextSize = touch and 20 or 23,
		TextColor3 = Color3.fromRGB(255, 226, 150), TextStrokeTransparency = 1,
		Text = "WANDERING TRADER", ZIndex = 91,
	}, f)
	local where = mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, -24, 0, 20), Font = FONT_M, TextSize = touch and 12 or 13,
		TextColor3 = Color3.fromRGB(198, 202, 220), TextStrokeTransparency = 1,
		Text = "", ZIndex = 91,
	}, f)

	local list = mk("Frame", {
		BackgroundTransparency = 1, Position = UDim2.new(0.05, 0, 0, 74),
		Size = UDim2.new(0.9, 0, 0, rows * (rowH + 8)), ZIndex = 91,
	}, f)
	mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local buys = {}
	for i, row in ipairs(stock) do
		local card = mk("Frame", {
			BackgroundColor3 = Color3.fromRGB(32, 30, 46), LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, rowH), ZIndex = 91,
		}, list)
		round(card, 10)
		mk("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 6),
			Size = UDim2.new(0.58, 0, 0, 20), Font = FONT, TextSize = touch and 14 or 15,
			TextColor3 = Color3.fromRGB(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, Text = tostring(row.name or row.caseId),
			ZIndex = 92,
		}, card)
		mk("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 26),
			Size = UDim2.new(0.58, 0, 0, rowH - 32), Font = FONT_M, TextSize = touch and 11 or 12,
			TextColor3 = Color3.fromRGB(186, 190, 210), TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
			Text = tostring(row.blurb or ""), ZIndex = 92,
		}, card)
		local price = math.max(0, math.floor(tonumber(row.tokens) or 0))
		local buy = mk("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.new(0, touch and 104 or 112, 0, touch and 40 or 38),
			BackgroundColor3 = Color3.fromRGB(96, 190, 104), Font = FONT,
			TextSize = touch and 13 or 14, TextColor3 = Color3.fromRGB(12, 24, 16),
			Text = price .. " tokens", ZIndex = 92,
		}, card)
		round(buy, 9)
		buys[#buys + 1] = { btn = buy, price = price }
		buy.MouseButton1Click:Connect(function()
			--[[
				Fire and close. The server re-checks that a trader is there, that
				this case is on its shelf, and what it costs -- so there is nothing
				useful to do here but ask, and leaving the panel open would invite
				a second click on a case already bought.
			]]
			net:FireServer("buyTraderCase", {
				zoneId = payload.zoneId, seam = payload.seam, caseId = row.caseId,
			})
			if ClientFns.traderMenu then
				ClientFns.traderMenu:Destroy()
				ClientFns.traderMenu = nil
			end
			if ClientFns.traderTick then
				ClientFns.traderTick:Disconnect()
				ClientFns.traderTick = nil
			end
		end)
	end

	local close = mk("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.new(0.5, 0, 0, touch and 40 or 36),
		BackgroundColor3 = Color3.fromRGB(70, 66, 92), Font = FONT,
		TextSize = touch and 14 or 15, TextColor3 = Color3.fromRGB(226, 228, 240),
		Text = "Close", ZIndex = 92,
	}, f)
	round(close, 9)
	close.MouseButton1Click:Connect(function()
		if ClientFns.traderMenu then
			ClientFns.traderMenu:Destroy()
			ClientFns.traderMenu = nil
		end
		if ClientFns.traderTick then
			ClientFns.traderTick:Disconnect()
			ClientFns.traderTick = nil
		end
	end)

	-- Header line and affordability, repainted on a tick so the countdown runs
	-- and a purchase elsewhere greys the buttons out.
	local left = math.max(0, math.floor(tonumber(payload.secondsLeft) or 0))
	local at = os.clock()
	local function repaint()
		local remain = math.max(0, left - math.floor(os.clock() - at))
		local have = tonumber(snap and snap.temperTokens) or 0
		where.Text = ("%s · depth %s · %d:%02d left · %d tokens"):format(
			tostring(payload.zoneId or "?"), tostring(payload.seam or 0),
			math.floor(remain / 60), remain % 60, have)
		for _, b in ipairs(buys) do
			local afford = have >= b.price
			b.btn.BackgroundColor3 = afford and Color3.fromRGB(96, 190, 104) or Color3.fromRGB(70, 74, 92)
			b.btn.TextColor3 = afford and Color3.fromRGB(12, 24, 16) or Color3.fromRGB(196, 200, 216)
			b.btn.Active = afford
			b.btn.AutoButtonColor = afford
		end
	end
	repaint()
	-- RunService, not RS: in this file `RS` is ReplicatedStorage.
	ClientFns.traderTick = RunService.Heartbeat:Connect(function()
		if not (ClientFns.traderMenu and ClientFns.traderMenu.Parent) then
			if ClientFns.traderTick then
				ClientFns.traderTick:Disconnect()
				ClientFns.traderTick = nil
			end
			return
		end
		-- Once a second is enough for a countdown and an affordability tint.
		if os.clock() - (ClientFns.traderPaintAt or 0) < 1 then
			return
		end
		ClientFns.traderPaintAt = os.clock()
		repaint()
	end)
end

--[[
	The Rebirth screen is ONE decision: "should I press the button yet?"
	Everything on it serves that question, in reading order: what rebirth is,
	how close your bank is (one bar, two marked lines), what stays vs what
	goes, what the next rank pays, then the button. Explicit LayoutOrder
	on every block - the old screen relied on insertion order and shuffled.
]]
refreshPrestige = function()
	clear(presP.Body)
	if not snap then
		return
	end
	local Skills = require(shared:WaitForChild("MineSkillData"))
	local rank = tonumber(snap.prestige or snap.rebirth) or 0
	local nextR = rank + 1
	local needCoins = tonumber(snap.rebirthCost) or Skills.rebirthCost(nextR)
	local grant = tonumber(snap.rebirthTokens) or Skills.tokensFor(nextR)
	local temperGrant = tonumber(snap.rebirthTokenGrant) or (Skills.rebirthTokens and Skills.rebirthTokens(nextR)) or 0
	local coins = math.floor(tonumber(snap.coins) or 0)
	local canAfford = coins >= needCoins
	local advice = snap.rebirthAdvice
	if type(advice) ~= "table" then
		advice = Skills.rebirthAdvice and Skills.rebirthAdvice(coins, rank) or nil
	end
	local minCoins = tonumber(snap.rebirthMinCoins)
		or (advice and advice.minCoins)
		or (Skills.minRebirthCoins and Skills.minRebirthCoins(nextR))
		or needCoins
	local atMin = coins >= minCoins
	local luckNow = C.prestigeLuck and C.prestigeLuck(rank) or (1 + 0.05 * rank)
	local luckNext = C.prestigeLuck and C.prestigeLuck(nextR) or (1 + 0.05 * nextR)

	local order = 0
	local function nextOrder()
		order += 1
		return order
	end

	-- 1. What rebirth IS, in one breath.
	local hero = mk("Frame", {
		BackgroundColor3 = BG2,
		Size = UDim2.new(1, -8, 0, 74),
		LayoutOrder = nextOrder(),
		ZIndex = 32,
	}, presP.Body)
	round(hero, 10)
	stroke(hero, 1.5, GOLD)
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT, TextSize = 24, TextColor3 = GOLD,
		Text = string.format("REBIRTH  R%d  ->  R%d", rank, nextR),
		Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 33,
	}, hero)
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT_M, TextSize = 14, TextColor3 = MUTED,
		Text = "Trade this run's coins for permanent power. The good stuff stays.",
		Position = UDim2.fromOffset(16, 42), Size = UDim2.new(1, -32, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 33,
	}, hero)

	-- 2. The one number that matters: your bank against the two lines.
	local bank = mk("Frame", {
		BackgroundColor3 = BG2,
		Size = UDim2.new(1, -8, 0, 100),
		LayoutOrder = nextOrder(),
		ZIndex = 32,
	}, presP.Body)
	round(bank, 10)
	stroke(bank, 1)
	local statusText, statusCol
	if atMin then
		statusText = "READY - you are past the smart minimum. Rebirth pays off now."
		statusCol = Color3.fromRGB(150, 230, 150)
	elseif canAfford then
		statusText = string.format("You CAN pay, but farming to %s first makes the next run stronger.", shortNum(minCoins))
		statusCol = Color3.fromRGB(235, 195, 120)
	else
		statusText = string.format("Keep digging and selling - the fee is %s coins.", shortNum(needCoins))
		statusCol = Color3.fromRGB(235, 165, 140)
	end
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT, TextSize = 16, TextColor3 = TEXT,
		Text = string.format("Your coins   %s", shortNum(coins)),
		Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 33,
	}, bank)
	local track = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(36, 34, 42),
		Position = UDim2.fromOffset(16, 38), Size = UDim2.new(1, -32, 0, 14),
		ZIndex = 33, BorderSizePixel = 0,
	}, bank)
	round(track, 7)
	local frac = math.clamp(coins / math.max(1, minCoins), 0, 1)
	if frac > 0 then
		local fill = mk("Frame", {
			BackgroundColor3 = atMin and Color3.fromRGB(110, 210, 120) or GOLD,
			Size = UDim2.new(frac, 0, 1, 0), ZIndex = 34, BorderSizePixel = 0,
		}, track)
		round(fill, 7)
	end
	-- The fee notch on the same bar, so "can pay" vs "should pay" is visible.
	local notchX = math.clamp(needCoins / math.max(1, minCoins), 0.02, 0.98)
	mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(240, 240, 245),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(notchX, 0, 0, -3), Size = UDim2.fromOffset(2, 20),
		ZIndex = 35, BorderSizePixel = 0,
	}, track)
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT_M, TextSize = 12, TextColor3 = MUTED,
		Text = "fee " .. shortNum(needCoins),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(notchX, 0, 0, 20), Size = UDim2.fromOffset(90, 14),
		ZIndex = 35,
	}, track)
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT_M, TextSize = 12,
		TextColor3 = atMin and Color3.fromRGB(150, 230, 150) or MUTED,
		Text = "ready " .. shortNum(minCoins),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 20), Size = UDim2.fromOffset(110, 14),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 35,
	}, track)
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT_M, TextSize = 13, TextColor3 = statusCol,
		Text = statusText, TextWrapped = true,
		Position = UDim2.fromOffset(16, 68), Size = UDim2.new(1, -32, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 33,
	}, bank)

	--[[
		THE LADDER.

		The panel only ever described the very next rebirth, so a run had no
		shape to it: you could not see that R+2 sits close behind R+1, or how
		far off R+5 really is. One row per upcoming rebirth, each with its own
		bar against its own "ready" line, so the whole climb is visible at once.
	]]
	local STEPS = 5
	local ladder = mk("Frame", {
		BackgroundColor3 = BG2,
		Size = UDim2.new(1, -8, 0, 34 + STEPS * 30),
		LayoutOrder = nextOrder(),
		ZIndex = 32,
	}, presP.Body)
	round(ladder, 10)
	stroke(ladder, 1)
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = GOLD,
		Text = "NEXT REBIRTHS", Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -24, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 33,
	}, ladder)
	for step = 0, STEPS - 1 do
		local rn = nextR + step
		local fee = Skills.rebirthCost and Skills.rebirthCost(rn) or 0
		local want = (Skills.minRebirthCoins and Skills.minRebirthCoins(rn)) or fee
		local y = 32 + step * 30
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT_M, TextSize = 13,
			TextColor3 = (step == 0) and GOLD or MUTED,
			Text = "R" .. tostring(rn), Position = UDim2.fromOffset(12, y),
			Size = UDim2.fromOffset(40, 18), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 33,
		}, ladder)
		local tr = mk("Frame", {
			BackgroundColor3 = Color3.fromRGB(36, 34, 42),
			Position = UDim2.fromOffset(54, y + 4), Size = UDim2.new(1, -176, 0, 10),
			ZIndex = 33, BorderSizePixel = 0,
		}, ladder)
		round(tr, 5)
		local f = math.clamp(coins / math.max(1, want), 0, 1)
		if f > 0 then
			local fl = mk("Frame", {
				BackgroundColor3 = (f >= 1) and Color3.fromRGB(110, 210, 120) or GOLD,
				Size = UDim2.new(f, 0, 1, 0), ZIndex = 34, BorderSizePixel = 0,
			}, tr)
			round(fl, 5)
		end
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT_M, TextSize = 12,
			TextColor3 = (f >= 1) and Color3.fromRGB(150, 230, 150) or MUTED,
			Text = (f >= 1) and ("READY  " .. shortNum(fee))
				or string.format("%d%%  %s", math.floor(f * 100), shortNum(want)),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, y), Size = UDim2.fromOffset(110, 18),
			TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 33,
		}, ladder)
	end

	-- 3. Keep / lose, side by side, skimmable.
	local duo = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 108),
		LayoutOrder = nextOrder(),
		ZIndex = 32,
	}, presP.Body)
	local function half(x, title, col, items)
		local card = mk("Frame", {
			BackgroundColor3 = BG2,
			Position = UDim2.new(x, x > 0 and 4 or 0, 0, 0),
			Size = UDim2.new(0.5, -4, 1, 0),
			ZIndex = 32,
		}, duo)
		round(card, 10)
		stroke(card, 1, col)
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = col,
			Text = title, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 18),
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 33,
		}, card)
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT_M, TextSize = 13, TextColor3 = TEXT,
			Text = items, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
			Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -24, 1, -38),
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 33,
		}, card)
	end
	half(0, "YOU KEEP", Color3.fromRGB(130, 215, 140),
		"Gems | cards | runes | gear\nSkills | skins | charms | ore pouch\nZones stay unlocked")
	half(0.5, "RESETS", Color3.fromRGB(235, 150, 130),
		"Coins | pickaxe ladder\nBackpack | mine depth\n(runes stay in their tool slots)")

	-- 4. What the next rank pays.
	local get = mk("Frame", {
		BackgroundColor3 = BG2,
		Size = UDim2.new(1, -8, 0, 66),
		LayoutOrder = nextOrder(),
		ZIndex = 32,
	}, presP.Body)
	round(get, 10)
	stroke(get, 1, GOLD)
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = GOLD,
		Text = string.format("R%d PAYS", nextR), Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -24, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 33,
	}, get)
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT_M, TextSize = 13, TextColor3 = TEXT,
		Text = string.format("+%d skill points   |   +%d temper tokens   |   +%d gems   |   Luck ×%.2f -> ×%.2f",
			grant, temperGrant,
			(advice and tonumber(advice.gems))
				or (Skills.rebirthGemReward and Skills.rebirthGemReward(nextR, snap.maxUnlockedZone)) or 0,
			luckNow, luckNext),
		TextWrapped = true,
		Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 33,
	}, get)

	-- 5. The button. One, big, honest about why it is or is not lit.
	local cta = mk("TextButton", {
		AutoButtonColor = canAfford,
		BackgroundColor3 = atMin and GOLD or (canAfford and Color3.fromRGB(180, 140, 70) or BG2),
		Font = FONT, TextSize = 18,
		TextColor3 = (atMin or canAfford) and Color3.fromRGB(22, 18, 12) or MUTED,
		Text = atMin and string.format("REBIRTH NOW  |  R%d", nextR)
			or (canAfford and string.format("EARLY REBIRTH  |  better at %s", shortNum(minCoins))
				or string.format("NEED %s COINS", shortNum(needCoins))),
		Size = UDim2.new(1, -8, 0, 52),
		LayoutOrder = nextOrder(),
		ZIndex = 32,
		Active = true,
	}, presP.Body)
	round(cta, 10)
	cta.MouseButton1Click:Connect(function()
		if not canAfford then
			showToast(string.format("Rebirth %d needs %s coins (smart minimum %s)",
				nextR, shortNum(needCoins), shortNum(minCoins)))
			return
		end
		ClientFns.confirmRebirth()
	end)

	-- 6. Related doors, small and out of the way.
	local have = math.max(1, tonumber(snap.maxUnlockedZone) or 1)
	local nxt = nil
	for i = have + 1, #C.ZONES do
		local z = C.ZONES[i]
		if z and not z.limited then
			nxt = z
			break
		end
	end
	local links = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 34),
		LayoutOrder = nextOrder(),
		ZIndex = 32,
	}, presP.Body)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, links)
	local function doorBtn(text, orderN, fn)
		local b = mk("TextButton", {
			AutoButtonColor = true, BackgroundColor3 = BG2, Font = FONT_M, TextSize = 13,
			TextColor3 = TEXT, Text = text,
			Size = UDim2.fromOffset(math.max(120, #text * 7 + 24), 34),
			LayoutOrder = orderN, ZIndex = 33,
		}, links)
		round(b, 8)
		stroke(b, 1)
		b.MouseButton1Click:Connect(fn)
	end
	doorBtn("Skill tree", 1, function()
		if skillP then
			if applySkills then
				applySkills(false)
			end
			togglePanel(skillP)
		end
	end)
	doorBtn("Events", 2, function()
		hidePanels()
		if eventsCtl then
			if snap then
				eventsCtl.setState(snap)
			end
			eventsCtl.open()
		end
	end)
	if nxt then
		local zcost = math.floor(tonumber(nxt.buyCost) or 0)
		local needRz = tonumber(nxt.minRebirth) or 0
		doorBtn(string.format("Buy %s | %s gems", nxt.name, tostring(zcost)), 3, function()
			if (tonumber(snap.prestige) or 0) < needRz then
				showToast("Need Rebirth " .. tostring(needRz) .. "+")
				return
			end
			if math.floor(tonumber(snap.gems) or 0) < zcost then
				showToast(string.format("Need %s gems", tostring(zcost)))
				return
			end
			net:FireServer("buyZone", nxt.id)
		end)
	end
end

--[[
	The Enchanter has two halves now.

	"Runes" is the roll/fuse bench it always was. "Sockets" is the part that was
	previously a list of buttons reading "Socket -> pickaxe main": pick the gear
	or tool, see its sockets laid out around it, pick a rune, click the socket.
]]
local socketsCtl, enchantTabs, traitCtl
--[[
	The Enchanter opens on ENCHANT now, not on the rune bench.

	Traits replaced runes as the thing you come here to do (TODO 0.17),
	so the bench being the landing tab would put the retiring system in front
	of the one that replaced it.
]]
local enchantTab = "trait"

--[[
	SUMMON -- its own tab.

	It was on the rune bench, which meant every time you went to fuse something
	the game put a purchase in front of you. Rolling is a thing you choose to
	go and do, so it gets its own tab and stays out of the way until you pick
	it. Both rune and gear rolls live here; there is nowhere else either of them
	belongs.

	One table because MineClient is a few locals off Luau's per-function cap.
]]
local rollsTab = {}

function rollsTab.build(parent)
	if rollsTab.root then
		return
	end
	-- BOTH required here. Neither is a top-level local in this file (the other
	-- users require them inside their own functions), so out here they are nil
	-- globals -- which is why Runes.ROLL_PRICE was indexing nil and this tab
	-- rendered with zero buttons.
	local Runes = require(shared:WaitForChild("MineRunes"))
	local Gear = require(shared:WaitForChild("MineGear"))
	local Icons = require(shared:WaitForChild("MineIcons"))
	rollsTab.root = mk("Frame", {
		Name = "Summon", Visible = false, BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 96), Size = UDim2.new(1, -24, 1, -108),
		ZIndex = 34,
	}, parent)
	rollsTab.have = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(4, 0), Size = UDim2.new(1, -8, 0, 24),
		ZIndex = 35,
	}, rollsTab.root)
	rollsTab.haveChip = nil
	rollsTab.buttons = {}
	-- The per-draw price chip on each card, repainted when the price moves
	-- (summons are a flat price at every depth: MineRunes.rollPriceFor).
	rollsTab.unitChips = {}

	--[[
		One row per thing you can summon: a picture of what comes out, its name,
		a line saying what it is, the price per draw, and the draw buttons.

		The picture matters. Three identical grey slabs of text is what this tab
		used to be, and a shop where every product looks the same is a list, not
		a shop.
	]]
	--[[
		Which wallet a row spends. Hats joined temperaments on rebirth TOKENS
		(TODO 6.2), and this was four separate `kind == "temper"` tests -- the
		chip, the button, the currency id and the affordability check. One
		predicate, so adding the next token row cannot leave one of them
		paying gems.
	]]
	-- On rollsTab, not a local of build(): rollsTab.paint calls it too, and as
	-- a local here it was a nil global there. So the Summon tab threw on every
	-- repaint (found by luau-analyze, 2026-10-08).
	function rollsTab.spendsTokens(kind)
		return kind == "temper" or kind == "gear"
	end
	local spendsTokens = rollsTab.spendsTokens

	local function row(title, sub, art, unit, y, tint, fire, counts, kind)
		counts = counts or { 1, 10, 100 }
		local card = mk("Frame", {
			-- Named for the tutorial hand.
			Name = "Row_" .. tostring(kind or title),
			BackgroundColor3 = BG2, Position = UDim2.fromOffset(0, y),
			Size = UDim2.new(1, 0, 0, 100), ZIndex = 35,
		}, rollsTab.root)
		round(card, 12)
		stroke(card, 2, tint, 0.5)
		-- A wash of the row's own colour behind the art, so the three rows read
		-- apart at a glance.
		local artBox = mk("Frame", {
			BackgroundColor3 = tint, BackgroundTransparency = 0.82, BorderSizePixel = 0,
			Position = UDim2.fromOffset(12, 14), Size = UDim2.fromOffset(72, 72), ZIndex = 36,
		}, card)
		round(artBox, 10)
		stroke(artBox, 1, tint, 0.45)
		if art then
			mk("ImageLabel", {
				BackgroundTransparency = 1, Image = art, ScaleType = Enum.ScaleType.Fit,
				Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(60, 60), ZIndex = 37,
			}, artBox)
		end
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 18, TextColor3 = TEXT,
			Position = UDim2.fromOffset(96, 10), Size = UDim2.fromOffset(280, 24),
			TextXAlignment = Enum.TextXAlignment.Left, Text = title, ZIndex = 36,
			-- "Summon a Rune" reads as an action; "Rune Roll" reads as a
			-- spreadsheet column.
		}, card)
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT_M, TextSize = 12, TextColor3 = MUTED,
			Position = UDim2.fromOffset(96, 32), Size = UDim2.fromOffset(300, 18),
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			Text = sub or "", ZIndex = 36,
		}, card)
		local unitHost = mk("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(96, 54), Size = UDim2.fromOffset(320, 20),
			ZIndex = 36,
		}, card)
		local unitLay = Instance.new("UIListLayout")
		unitLay.FillDirection = Enum.FillDirection.Horizontal
		unitLay.VerticalAlignment = Enum.VerticalAlignment.Center
		unitLay.Padding = UDim.new(0, 6)
		unitLay.SortOrder = Enum.SortOrder.LayoutOrder
		unitLay.Parent = unitHost
		local unitChip = Icons.priceChip(unitHost, spendsTokens(kind) and "tokens" or "gems", shortNum(unit), {
			iconSize = 16,
			textSize = 13,
			textColor = MUTED,
			font = FONT_M,
			zIndex = 36,
		})
		unitChip.LayoutOrder = 1
		rollsTab.unitChips[kind or title] = { host = unitHost, chip = unitChip, unit = unit, kind = kind }
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT_M, TextSize = 13, TextColor3 = MUTED,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 18),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = (#counts == 1) and "|  one draw" or "each",
			LayoutOrder = 2,
			ZIndex = 36,
		}, unitHost)
		local nCounts = #counts
		for i, n in ipairs(counts) do
			local b = mk("TextButton", {
				BackgroundColor3 = tint, Text = "", AutoButtonColor = true,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16 - (nCounts - i) * 128, 0.5, 0),
				Size = UDim2.fromOffset(120, 56), ZIndex = 36,
			}, card)
			round(b, 10)
			local xL = mk("TextLabel", {
				BackgroundTransparency = 1, Font = FONT, TextSize = 22,
				TextColor3 = Color3.fromRGB(18, 22, 28),
				Position = UDim2.fromOffset(10, 4), Size = UDim2.fromOffset(60, 26),
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = (nCounts == 1) and "Draw" or (n .. "x"), ZIndex = 37,
			}, b)
			local costHost = mk("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(10, 30), Size = UDim2.new(1, -20, 0, 18),
				ZIndex = 37,
			}, b)
			local currencyId = spendsTokens(kind) and "tokens" or "gems"
			Icons.priceChip(costHost, currencyId, shortNum(unit * n), {
				iconSize = 14,
				textSize = 14,
				textColor = Color3.fromRGB(26, 30, 38),
				font = FONT_M,
				zIndex = 37,
			})
			b.MouseButton1Click:Connect(function()
				fire(n)
			end)
			table.insert(rollsTab.buttons, { b = b, x = xL, n = n, unit = unit, tint = tint, kind = kind, costHost = costHost, currencyId = currencyId })
		end
	end

	local Hats = require(shared:WaitForChild("MineHats"))
	local Temper = require(shared:WaitForChild("MineTemper"))
	local function art(key, fallback)
		if Icons and Icons.image then
			local ok, img = pcall(Icons.image, key)
			if ok and img then
				return img
			end
		end
		return fallback
	end
	row("Rune Case", "Pet-boost runes only - T1 to T5. Fits pets, tools, or gear.",
		art("rune"), (snap and tonumber(snap.runeRollPrice)) or Runes.ROLL_PRICE, 24,
		Color3.fromRGB(96, 196, 128), function(n)
			net:FireServer("rollRune", { count = n or 1 })
		end, { 1, 10, 100 }, "rune")
	-- Crates land in the bag and open at your own pace, so a 100x buy is not
	-- 100 ceremonies -- same as runes. Priced in REBIRTH TOKENS now, not gems.
	row("Gear Case", "Hats and faces, worn by YOU. Graded F to SSS. Costs rebirth tokens.",
		art("gear", Hats.thumb and Hats.thumb(1016143686) or nil),
		(snap and tonumber(snap.gearRollPrice)) or Gear.ROLL_TOKEN_COST or 5, 136,
		Color3.fromRGB(168, 140, 255), function(n)
			net:FireServer("rollGear", { count = n or 1 })
		end, { 1, 10, 100 }, "gear")
	-- The case lives where the other draws live, not behind a rebirth wall.
	row(string.upper(tostring(Temper.CASE_NAME or "Temperament Case")),
		"Spins for one temperament, Common to Mythic. Fit it to any tool.",
		art("temper"), tonumber(Temper.CASE_PRICE_TOKENS) or 20, 248,
		Color3.fromRGB(255, 176, 92), function(n)
			net:FireServer("openTemperCase", { count = n or 1 })
		end, { 1, 10, 100 }, "temper")
end

function rollsTab.paint()
	if not rollsTab.root or not snap then
		return
	end
	local spendsTokens = rollsTab.spendsTokens
	-- Not a top-level local (see rollsTab.build); as a bare global it was nil,
	-- so this errored on its first line and the buttons never repainted.
	local Icons = require(shared:WaitForChild("MineIcons"))
	local haveGems = snap.gems or 0
	local haveTokens = tonumber(snap.temperTokens) or 0
	if rollsTab.haveChip then
		rollsTab.haveChip:Destroy()
		rollsTab.haveChip = nil
	end
	for _, c in ipairs(rollsTab.have:GetChildren()) do
		c:Destroy()
	end
	-- The header chip is the GEM purse (the rune row). The gear and temper rows
	-- price themselves in tokens and check haveTokens, via spendsTokens above.
	rollsTab.haveChip = Icons.priceChip(rollsTab.have, "gems", shortNum(haveGems), {
		iconSize = 18,
		textSize = 17,
		textColor = T.GEM,
		font = FONT,
		zIndex = 35,
	})
	-- Prices follow the snapshot: deeper zones, dearer summons.
	local function priceOf(kind)
		if kind == "gear" then
			return tonumber(snap.gearRollPrice)
		elseif kind == "rune" then
			return tonumber(snap.runeRollPrice)
		elseif kind == "temper" then
			-- The case is one flat price, wherever you are standing.
			return tonumber(snap.temperCasePrice)
				or tonumber(require(shared:WaitForChild("MineTemper")).CASE_PRICE_TOKENS)
		end
		return nil
	end
	local function currencyOf(kind)
		return spendsTokens(kind) and "tokens" or "gems"
	end
	for _, u in pairs(rollsTab.unitChips or {}) do
		local want = priceOf(u.kind)
		local currencyId = currencyOf(u.kind)
		if want and want ~= u.unit and u.host and u.host.Parent then
			u.unit = want
			if u.chip then
				u.chip:Destroy()
			end
			u.chip = Icons.priceChip(u.host, currencyId, shortNum(want), {
				iconSize = 16, textSize = 13, textColor = MUTED, font = FONT_M, zIndex = 36,
			})
			u.chip.LayoutOrder = 1
		end
	end
	for _, r in ipairs(rollsTab.buttons) do
		local want = priceOf(r.kind)
		local currencyId = r.currencyId or currencyOf(r.kind)
		if want and want ~= r.unit and r.costHost and r.costHost.Parent then
			r.unit = want
			for _, c in ipairs(r.costHost:GetChildren()) do
				c:Destroy()
			end
			Icons.priceChip(r.costHost, currencyId, shortNum(want * r.n), {
				iconSize = 14, textSize = 14, textColor = Color3.fromRGB(26, 30, 38), font = FONT_M, zIndex = 37,
			})
		end
	end
	for _, r in ipairs(rollsTab.buttons) do
		local total = r.unit * r.n
		-- The first gear roll is free (server: Verbs.rollGearBanner).
		local freeGear = snap.freeGear and r.unit == (tonumber(snap.gearRollPrice) or 5) and r.n == 1
		local tag = r.b:FindFirstChild("FreeTag")
		if freeGear and not tag then
			tag = mk("TextLabel", {
				Name = "FreeTag", BackgroundColor3 = T.GREEN, Font = FONT, TextSize = 13,
				TextColor3 = Color3.fromRGB(14, 40, 20), Text = "FREE", AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(48, 20), ZIndex = 40,
			}, r.b)
			round(tag, 6)
		end
		if tag then
			tag.Visible = freeGear and true or false
		end
		local purse = spendsTokens(r.kind) and haveTokens or haveGems
		local can = freeGear or purse >= total
		r.b.BackgroundColor3 = can and r.tint or Color3.fromRGB(58, 52, 48)
		r.b.AutoButtonColor = can
		r.b.Active = can
		r.x.TextColor3 = can and Color3.fromRGB(18, 22, 28) or MUTED
	end
end

--[[
	THE HAND

	A tutorial step that says "put a hat on a pet" is a sentence. A hand parked on
	the thing to tap is an instruction, and the difference is most of whether a
	new player ever finds the system at all.

	It is DRAWN, not an image: a ring around the target and an arrow bobbing into
	it, so there is no asset that can fail to load. And it re-finds its target
	every tick rather than remembering a position, because every panel in this
	game rebuilds its children on each snapshot -- a pointer holding an old
	instance ends up pointing at nothing, confidently.
]]
ClientFns.handTargets = {
	-- inventory
	equipmentTab = { find = function() return ClientFns.handFind(invCtl, { "Tab_tools" }) end },
	runesTab = { find = function() return ClientFns.handFind(invCtl, { "Tab_runes" }) end },
	cardsTab = { find = function() return ClientFns.handFind(invCtl, { "Tab_cards" }) end },
	petSeat = { find = function() return ClientFns.handFind(invCtl, { "Seat_pet1", "Seat_pet2", "Seat_pet3" }) end },
	faceSeat = { find = function() return ClientFns.handFind(invCtl, { "Seat_face" }) end },
	-- Three hat seats, any of which satisfies the tutorial's "put a hat on".
	hatSeat = { find = function() return ClientFns.handFind(invCtl, { "Seat_hat", "Seat_hat2", "Seat_hat3" }) end },
	-- enchanter
	caseRow = { find = function() return (enchantP and enchantP.Visible) and enchantP:FindFirstChild("Row_temper", true) or nil end },
	runeRow = { find = function() return (enchantP and enchantP.Visible) and enchantP:FindFirstChild("Row_rune", true) or nil end },
	gearRow = { find = function() return (enchantP and enchantP.Visible) and enchantP:FindFirstChild("Row_gear", true) or nil end },
	goEnchanter = { find = function() return ClientFns.handFind(invCtl, { "GoEnchanter" }) end },
}

function ClientFns.handFind(ctl, names)
	local root = ctl and ctl.root
	if not (root and root.Parent) then
		return nil
	end
	-- Prefer a laid-out AbsoluteSize over Visible: panel open + 0.35s delay can
	-- race so the seat exists but Visible/layout hasn't settled yet.
	for _, n in ipairs(names) do
		local hit = root:FindFirstChild(n, true)
		if hit and hit.AbsoluteSize.X > 4 then
			return hit
		end
	end
	for _, n in ipairs(names) do
		local hit = root:FindFirstChild(n, true)
		if hit then
			return hit
		end
	end
	return nil
end

function ClientFns.handClear()
	ClientFns.handKind = nil
	if ClientFns.handHost then
		ClientFns.handHost.Visible = false
	end
end

local function handBuild()
	if ClientFns.handHost then
		return
	end
	local host = mk("Frame", {
		Name = "TutorialHand", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 200, Active = false,
	}, gui)
	local ring = mk("Frame", {
		Name = "Ring", BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 201,
	}, host)
	round(ring, 12)
	local ringStroke = mk("UIStroke", {
		Thickness = 3, Color = Color3.fromRGB(255, 214, 92), Transparency = 0.1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, ring)
	-- The arrow: a rotated square reads as a point at this size and costs nothing.
	local arrow = mk("Frame", {
		Name = "Arrow", BackgroundColor3 = Color3.fromRGB(255, 214, 92), BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, Size = UDim2.fromOffset(22, 22), ZIndex = 202,
	}, host)
	local stem = mk("Frame", {
		Name = "Stem", BackgroundColor3 = Color3.fromRGB(255, 214, 92), BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(8, 26), ZIndex = 201,
	}, host)
	round(stem, 4)
	ClientFns.handHost = host
	ClientFns.handRing = ring
	ClientFns.handRingStroke = ringStroke
	ClientFns.handArrow = arrow
	ClientFns.handStem = stem
end

function ClientFns.handPoint(kind)
	if not kind then
		ClientFns.handClear()
		return
	end
	if not ClientFns.handTargets[kind] then
		return
	end
	handBuild()
	ClientFns.handKind = kind
	-- Bounded: a pointer that never leaves becomes furniture.
	ClientFns.handUntil = os.clock() + 90
	if ClientFns.handLoop then
		return
	end
	ClientFns.handLoop = true
	task.spawn(function()
		while true do
			task.wait(0.06)
			local kindNow = ClientFns.handKind
			local host = ClientFns.handHost
			if not (kindNow and host) then
				if host then
					host.Visible = false
				end
			elseif os.clock() > (ClientFns.handUntil or 0) then
				ClientFns.handClear()
			else
				local spec = ClientFns.handTargets[kindNow]
				local ok, target = pcall(spec.find)
				target = ok and target or nil
				if target and target.AbsoluteSize.X > 4 then
					-- Absolute* is screen pixels; UDim2 offsets are pre-UIScale.
					-- Same convert as flyToBag - without /k the ring drifts on phones
					-- (scale ~0.78) and desktop (scale 1.2-1.28).
					local k = math.max(0.05, uiScale.Scale)
					local origin = host.AbsolutePosition
					local pos = (target.AbsolutePosition - origin) / k
					local size = target.AbsoluteSize / k
					ClientFns.handRing.Position = UDim2.fromOffset(pos.X - 7, pos.Y - 7)
					ClientFns.handRing.Size = UDim2.fromOffset(size.X + 14, size.Y + 14)
					local bob = math.sin(os.clock() * 4.5) * 5
					local ax = pos.X + size.X * 0.5
					local ay = pos.Y + size.Y + 30 + bob
					ClientFns.handArrow.Position = UDim2.fromOffset(ax, ay)
					ClientFns.handStem.Position = UDim2.fromOffset(ax, ay + 6)
					local pulse = 0.1 + (math.sin(os.clock() * 4.5) + 1) * 0.2
					ClientFns.handRingStroke.Transparency = pulse
					host.Visible = true
				else
					host.Visible = false
				end
			end
		end
	end)
end

function ClientFns.teleportToEnchanter()
	local char = player.Character
	local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso"))
	if not hrp then
		return
	end
	local target
	local world = workspace:FindFirstChild("MineWorld")
	local root = world and (world:FindFirstChild("Lobby") or world)
	if root then
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("BasePart") and d:GetAttribute("Machine") == "enchanter" then
				target = d
				break
			end
		end
	end
	if not target then
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("BasePart") and d:GetAttribute("Machine") == "enchanter" then
				target = d
				break
			end
		end
	end
	local dest = target and (target.Position + target.CFrame.LookVector * 10 + Vector3.new(0, 4, 0)) or Vector3.new(-70, 10, -36)
	hrp.CFrame = CFrame.new(dest, (target and target.Position) or (dest + Vector3.new(0, 0, -1)))
end

function ClientFns.paintEnchantExtra()
	if not enchantP then
		return
	end
	local function pane(name)
		local f = enchantP:FindFirstChild(name)
		if f then
			return f
		end
		f = mk("ScrollingFrame", {
			Name = name, Visible = false, BackgroundTransparency = 1, BorderSizePixel = 0,
			Position = UDim2.fromOffset(12, 96), Size = UDim2.new(1, -24, 1, -108),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
			ScrollBarThickness = 5, ZIndex = 34,
		}, enchantP)
		mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, f)
		return f
	end
	local function clear(f)
		for _, c in ipairs(f:GetChildren()) do
			if not c:IsA("UIListLayout") then
				c:Destroy()
			end
		end
	end
	local sal, dust = pane("SalvagePane"), pane("DustPane")
	sal.Visible = enchantTab == "salvage"
	dust.Visible = enchantTab == "dust"
	if enchantTab == "salvage" and snap then
		clear(sal)
		local n = 0
		for _, c in ipairs(snap.cards or {}) do
			if n >= 12 then
				break
			end
			n += 1
			local id = c.id
			local row = mk("TextButton", {
				BackgroundColor3 = BG2, Text = "", AutoButtonColor = true,
				Size = UDim2.new(1, -8, 0, 36), LayoutOrder = n, ZIndex = 35,
			}, sal)
			round(row, 8)
			mk("TextLabel", {
				BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = TEXT,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = "Scrap  " .. tostring(c.name or c.cardKey or "Pet"),
				Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), ZIndex = 36,
			}, row)
			row.MouseButton1Click:Connect(function()
				if id then
					net:FireServer("salvage", id)
				end
			end)
		end
		if n == 0 then
			mk("TextLabel", {
				BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = TEXT,
				Text = "No pets to scrap.", Size = UDim2.new(1, 0, 0, 28), ZIndex = 35,
			}, sal)
		end
	elseif enchantTab == "dust" and snap then
		clear(dust)
		local shop = snap.dustShop
		local offers = shop and shop.offers or {}
		local ZP
		pcall(function()
			ZP = require(shared:WaitForChild("MineZonePacks"))
		end)
		local n = 0
		for _, offer in ipairs(offers) do
			n += 1
			local def = ZP and ZP.get and ZP.get(offer.id)
			local name = (def and def.name) or tostring(offer.id)
			-- One pack per ore on the roster: the tier is what places a pack.
			local tierBit = (def and def.kind == "ore" and def.tier)
				and ("  |  tier " .. tostring(def.tier)) or ""
			local row = mk("TextButton", {
				BackgroundColor3 = BG2, Text = "", AutoButtonColor = true,
				Size = UDim2.new(1, -8, 0, 36), LayoutOrder = n, ZIndex = 35,
			}, dust)
			round(row, 8)
			mk("TextLabel", {
				BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = TEXT,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = string.format("%s%s    %s dust", name, tierBit, tostring(offer.price or "?")),
				Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), ZIndex = 36,
			}, row)
			local oid = offer.id
			row.MouseButton1Click:Connect(function()
				net:FireServer("buyDustPack", { id = oid, qty = 1 })
			end)
		end
		if n == 0 then
			mk("TextLabel", {
				BackgroundTransparency = 1, Font = FONT, TextSize = 14, TextColor3 = TEXT,
				Text = "Nothing on the stardust shelf this rotation.", Size = UDim2.new(1, 0, 0, 28), ZIndex = 35,
			}, dust)
		end
	end
end

function ClientFns.showEnchantTab(id)
	enchantTab = id
	if runesCtl and runesCtl.root then
		runesCtl.root.Visible = (id == "runes")
		if id == "runes" then
			runesCtl.paint()
		end
	end
	if socketsCtl then
		socketsCtl.setVisible(id == "sockets")
	end
	if traitCtl then
		traitCtl.setVisible(id == "trait")
	end
	if rollsTab.root then
		rollsTab.root.Visible = (id == "summon")
		if id == "summon" then
			rollsTab.paint()
		end
	end
	if ClientFns.temperListCtl then
		ClientFns.temperListCtl.root.Visible = (id == "temper")
		if id == "temper" then
			-- No rebirth lock. The case is bought with gems, so this screen has
			-- something to do from the first hour -- which is the whole reason
			-- temperaments read as "they do not do anything".
			ClientFns.temperListCtl.paint()
		end
	end
	if enchantTabs then
		for tabId, btn in pairs(enchantTabs) do
			local on = tabId == id
			btn.BackgroundColor3 = on and GOLD or BG2
			btn.TextColor3 = on and Color3.fromRGB(28, 22, 12) or TEXT
		end
	end
	if ClientFns.paintEnchantExtra then
		ClientFns.paintEnchantExtra()
	end
end

local function refreshEnchanter()
	if not snap then return end
	if not traitCtl then
		--[[
			Guarded like the Forge's panels: a module missing from a build
			should cost this one tab, not the whole Enchanter. And LOUDLY --
			the silent version of this guard is what hid the Forge for a week.
		]]
		local okE, EnchantView = pcall(function()
			return require(shared:WaitForChild("MineTraitView", 5))
		end)
		if okE and EnchantView and EnchantView.mount then
			local okM, ctl = pcall(EnchantView.mount, enchantP, {
				getSnap = function()
					return snap or {}
				end,
				-- A uid and nothing else. The rarity, the trait and the
				-- level are all rolled on the server.
				onTrait = function(uid)
					net:FireServer("rollTrait", { uid = uid })
				end,
			})
			if okM then
				traitCtl = ctl
			else
				warn("[MineClient] NO TRAIT TAB: MineTraitView.mount threw: " .. tostring(ctl))
			end
		else
			warn("[MineClient] NO TRAIT TAB: ReplicatedStorage.Mine.Shared."
				.. "MineTraitView did not resolve (" .. tostring(EnchantView) .. ").")
		end
	end
	if not socketsCtl then
		socketsCtl = RunesSockets.mount(enchantP, {
			onSocket = ClientFns.socketRoute,
			--[[
				Buy a rune case. Verbs.buyPouch has been complete and
				dispatched with no caller, while this very panel told the
				player "No loose runes. Roll one, or open a Rune Case" --
				naming a shop that existed only on the server. Three SKUs at
				300 / 3,000 / 30,000 gems, and the only non-Robux path to
				scrolls.
			]]
			onBuyPouch = function(tier)
				net:FireServer("buyPouch", { tier = tier })
			end,
			-- A Set Crate is aimed at one of the seven rune sets. The view
			-- will not call this without a set picked, and the server refuses
			-- without one too, so neither side can spend 60,000 gems on a
			-- crate with no target.
			onBuyCrate = function(tier, setId)
				net:FireServer("buyCrate", { tier = tier, setId = tostring(setId or "") })
			end,
		})
		if socketsCtl.root then
			socketsCtl.root.Position = UDim2.fromOffset(12, 96)
			socketsCtl.root.Size = UDim2.new(1, -24, 1, -108)
		end
	end
	if not enchantTabs then
		enchantTabs = {}
		local strip = mk("Frame", {
			Name = "EnchantTabs", BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 52), Size = UDim2.new(1, -24, 0, 36), ZIndex = 40,
		}, enchantP)
		mk("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, strip)
		-- Trait leads: it is the prefix on your tool, and the reason to walk
		-- here at all. Merge/Sockets/Summon are the rune bench, which is being
		-- retired behind it.
		for i, t in ipairs({ { "trait", "Traits" }, { "runes", "Merge" }, { "sockets", "Sockets" }, { "summon", "Summon" }, { "temper", "Temper" }, { "salvage", "Salvage" }, { "dust", "Dust" } }) do
			local b = mk("TextButton", {
				AutoButtonColor = true, BackgroundColor3 = BG2, Font = FONT, TextSize = 13,
				TextColor3 = TEXT, Text = t[2], Size = UDim2.fromOffset(96, 36),
				LayoutOrder = i, ZIndex = 41,
			}, strip)
			round(b, 8)
			stroke(b, 1)
			enchantTabs[t[1]] = b
			b.MouseButton1Click:Connect(function()
				ClientFns.showEnchantTab(t[1])
			end)
		end
	end
	rollsTab.build(enchantP)
	rollsTab.paint()
	-- Repaint the trait tab on every open: the tool list, the prefixes and
	-- the gem count all move while the panel is shut.
	if traitCtl then
		traitCtl.setVisible(enchantTab == "trait")
	end
	socketsCtl.setState(snap)
	if not runesCtl then
		if enchantP.Body then
			enchantP.Body.Visible = false
		end
		for _, ch in ipairs(enchantP:GetChildren()) do
			if ch.Name == "RunesView" then ch:Destroy() end
		end
		runesCtl = RunesView.mount(enchantP, {
			--[[
				Bulk recycle, from the rune list. Same two-call path the inventory
				uses: this is the ASK, and the server's `confirmScrap` reply opens
				the review (which is drawn by the inventory view but parented to
				the screen, so it shows over the Enchanter).
			]]
			onScrapMany = function(kind, ids, into, confirm)
				net:FireServer("scrapMany", {
					kind = kind or "rune",
					ids = ids,
					into = into,
					confirm = confirm and true or nil,
				})
			end,
			onToast = function(msg) showToast(tostring(msg)) end,
			onRollRune = function(count) net:FireServer("rollRune", { count = count or 1 }) end,
			onRollGear = function(count) net:FireServer("rollGear", { count = count or 1 }) end,
			onFuse = function(a, b) net:FireServer("fuseRune", { a = a, b = b }) end,
			onMergeHats = function(a, b) net:FireServer("mergeHats", { a = a, b = b }) end,
			onArmWhite = function(id) net:FireServer("armWhiteScroll", { runeId = id }) end,
			onSocketTool = function(id, fam, slot) net:FireServer("socketToolRune", { runeId = id, family = fam, slot = slot }) end,
			onBlackUnequip = function(fam, slot) net:FireServer("blackUnequipToolRune", { family = fam, slot = slot }) end,
			onDestroySocket = function(fam, slot) net:FireServer("destroyToolRune", { family = fam, slot = slot }) end,
			onApplyOmni = function(fam) net:FireServer("applyOmniscroll", { family = fam }) end,
			onSocketPet = function(id, cardId)
				-- cardId was never sent, so the server always answered "Unknown pet".
				net:FireServer("socketPetRune", { runeId = id, cardId = cardId })
			end,
			-- Off-ladder tools. socketToolRune has always taken a chestId; the
			-- Enchanter just never offered them as targets.
			onSocketChestTool = function(runeId, chestId)
				net:FireServer("socketToolRune", { runeId = runeId, chestId = chestId })
			end,
			onEquipGear = function(id, slot) net:FireServer("equipGear", { gearId = id, slot = slot }) end,
		})
		if runesCtl.root then
			runesCtl.root.Position = UDim2.fromOffset(12, 96)
			runesCtl.root.Size = UDim2.new(1, -24, 1, -108)
		end
	end
	runesCtl.setState(snap)
	-- Temper tab: the Forge's own list, mounted bare, so a tool's temperament can
	-- be rolled here as well as at the Forge. Kept on ClientFns rather than in a
	-- new top-level local; this script's top level is at the register ceiling.
	if not ClientFns.temperListCtl then
		ClientFns.temperListCtl = ForgeView.mountList(enchantP, {
			position = UDim2.fromOffset(12, 96),
			size = UDim2.new(1, -24, 1, -108),
			onRoll = function(id) net:FireServer("rollTemper", { id = id }) end,
			onRollFamily = function(family) net:FireServer("rollTemper", { family = family }) end,
			onEquip = function(id) net:FireServer("equipChestTool", { id = id }) end,
			onOpenCase = function() net:FireServer("openTemperCase") end,
			onOpenCaseBundle = function() net:FireServer("openTemperCaseBundle") end,
			onFitTemper = function(payload) net:FireServer("equipTemper", payload) end,
			onScrapTemper = function(payload) net:FireServer("scrapTemper", payload) end,
		})
		ClientFns.temperListCtl.root.Visible = false
	end
	ClientFns.temperListCtl.setState(snap)
	ClientFns.showEnchantTab(enchantTab)
end

local lastPetEquipKey = ""

-- Light HUD only - called on every coalesced snapshot while digging.
local function refreshHud()
	if not snap then
		return
	end
	if snap.zoneId == "bigbang" then
		coinsL.Text = shortNum(snap.spaceCoins or 0) .. " sp"
	elseif (snap.spaceCoins or 0) > 0 then
		coinsL.Text = shortNum(snap.coins or 0) .. " | " .. shortNum(snap.spaceCoins or 0) .. " sp"
	else
		coinsL.Text = shortNum(snap.coins or 0)
	end
	if ClientFns.syncSpaceHelmets then
		ClientFns.syncSpaceHelmets()
	end
	gemsL.Text = shortNum(snap.gems or 0)
	dustL.Text = shortNum(snap.dust or 0)
	if snap.mineResetRemaining ~= nil and mineResetL then
		mineResetLeft = snap.mineResetRemaining
		mineResetSec = snap.mineResetSec or mineResetSec
		mineResetL.Text = fmtReset(mineResetLeft)
	end
	ClientFns.showQuest(snap.quest)
	dailyHud.show(snap.daily)
	local load, cap = snap.load or 0, math.max(snap.cap or 12, 1)
	-- Just the load. "73.7K / 3.3M" does not fit a 92px chip, and the bar under
	-- it already says how full the bag is -- which is the actual question.
	if snap.bagInfinite or snap.wormholeBag then
		cap = math.max(cap, load + 1)
	end
	bagCount.Text = (snap.bagInfinite or snap.wormholeBag) and "INF" or shortNum(load)
	if bagFill then
		bagFill.Size = UDim2.new((snap.bagInfinite or snap.wormholeBag) and 0 or math.clamp(load / cap, 0, 1), 0, 1, 0)
		bagFill.BackgroundColor3 = (load >= cap) and Color3.fromRGB(236, 108, 88)
			or Color3.fromRGB(96, 186, 120)
	end
	presL.Text = "R" .. tostring(snap.prestige) .. "  " .. C.zoneById(snap.zoneId).name
end

function refreshAll()
	refreshHud()
	if not snap then
		return
	end
	refreshBinder()
	refreshBag()
	refreshShop()
	refreshMerge()
	refreshDust()
	refreshZones()
	refreshPrestige()
	if refreshEnchanter then refreshEnchanter() end
end

function ClientFns.spaceBubble(host, scale)
	if not host or host:FindFirstChild("SpaceBubble") then
		return
	end
	local adornee = host:FindFirstChild("Head") or host.PrimaryPart or host:FindFirstChildWhichIsA("BasePart", true)
	if not adornee then
		return
	end
	scale = scale or 1
	local holder = Instance.new("Model")
	holder.Name = "SpaceBubble"
	local dome = Instance.new("Part")
	dome.Name = "Dome"
	dome.Shape = Enum.PartType.Ball
	dome.Size = Vector3.new(2.12, 2.06, 2.06) * scale
	dome.Material = Enum.Material.Glass
	dome.Color = Color3.fromRGB(210, 236, 255)
	dome.Transparency = 0.55
	dome.Reflectance = 0.25
	dome.CanCollide = false
	dome.CanQuery = false
	dome.CanTouch = false
	dome.CastShadow = false
	dome.Massless = true
	dome.CFrame = adornee.CFrame * CFrame.new(0, 0.2 * scale, 0.06)
	dome.Parent = holder
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.18 * scale, 1.94 * scale, 1.94 * scale)
	ring.Material = Enum.Material.Metal
	ring.Color = Color3.fromRGB(240, 206, 90)
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Massless = true
	ring.CFrame = dome.CFrame * CFrame.new(0, -0.78 * scale, 0) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = holder
	local followPivot = host:IsA("Model") and not host:FindFirstChildOfClass("Humanoid")
	dome.Anchored = followPivot
	ring.Anchored = followPivot
	if not followPivot then
		local w = Instance.new("WeldConstraint")
		w.Part0 = adornee
		w.Part1 = dome
		w.Parent = dome
		local w2 = Instance.new("WeldConstraint")
		w2.Part0 = dome
		w2.Part1 = ring
		w2.Parent = ring
	end
	holder.Parent = host
end

function ClientFns.clearSpaceBubble(host)
	if not host then
		return
	end
	local bubble = host:FindFirstChild("SpaceBubble")
	if bubble then
		bubble:Destroy()
	end
end

function ClientFns.syncSpaceHelmets()
	local char = player.Character
	local on = (snap and snap.zoneId == "bigbang") or (char and char:GetAttribute("SpaceSuit") == true)
	if on then
		ClientFns.spaceBubble(char, 1)
	else
		ClientFns.clearSpaceBubble(char)
	end
	for _, model in ipairs(ClientFns.petModels or {}) do
		if on then
			ClientFns.spaceBubble(model, 1)
		else
			ClientFns.clearSpaceBubble(model)
		end
	end
	local byUser = ClientFns._otherPetByUser
	if not byUser then
		return
	end
	for _, rec in pairs(byUser) do
		local other = rec.plr
		local suited = other and other.Character and other.Character:GetAttribute("SpaceSuit") == true
		if other and other.Character then
			if suited then
				ClientFns.spaceBubble(other.Character, 1)
			else
				ClientFns.clearSpaceBubble(other.Character)
			end
		end
		for _, model in pairs(rec.models or {}) do
			if suited then
				ClientFns.spaceBubble(model, 1)
			else
				ClientFns.clearSpaceBubble(model)
			end
		end
	end
end

function ClientFns.clearPets()
	local st = ClientFns._petFollowState
	for _, m in ipairs(pets) do
		if m then
			if st then
				st[m] = nil
			end
			m:Destroy()
		end
	end
	table.clear(pets)
end

--[[
	Trail behind the owner: smoothed formation, real spring, continuous gait.

	WHY IT LOOKED JOLTY, in the three places it actually came from:

	1. THE FORMATION BASIS SNAPPED. The whole formation was built off the
	   owner's instantaneous velocity direction, and `right` came off that same
	   vector. Strafe, or turn on the spot, and the direction flips in one
	   frame -- so every pet's target jumps sideways by the full width of its
	   lateral offset and the spring chases a step function. Smoothing the
	   POSITION after the fact cannot hide a target that teleports. The basis
	   is smoothed here instead, so the formation swings around the owner
	   instead of cutting to the new side.

	2. HARD THRESHOLDS AT speed > 1.15. Crossing it flipped the basis from
	   facing to velocity, the bob amplitude from 0.09 to 0.16 and the bob rate
	   from 1.9 to 4.1 -- all on the same frame. Starting and stopping popped
	   every time, and walking right at the threshold strobed. There is one
	   continuous `gait` value now, 0 at rest to 1 at a walk, and everything
	   that used to branch on speed reads it instead.

	3. THE SPRING HAD NO VELOCITY. `pos:Lerp(target, alpha)` always decays
	   toward the target and can never overshoot it, which is exactly what
	   "stiff" looks like: no wind-up, no follow-through, a dead stop the
	   instant the owner stops. This is a proper damped spring with its own
	   velocity, a little under critical (zeta below 1), so a pet leans into a
	   stop, drifts a hair past, and settles.

	The bob also advances by GAIT rather than wall-clock, so a pet at rest
	breathes slowly instead of bobbing at walking cadence, and the cadence
	cannot visibly change frequency mid-step.

	Framerate-independent throughout; snaps only after a big teleport gap.
]]
--[[
	The follow's tuning and its two bits of maths, in ONE table.

	One top-level local rather than seven, deliberately: this file sits inside
	Luau's 200-top-level-local ceiling and a tuning block is the last thing that
	should spend seven of them.
]]
local PF = {
	-- Seconds for the smoothed values to cover most of the way to a new reading.
	-- The basis is the slowest on purpose: its jumps are the ones that read worst.
	DIR_TAU = 0.18,
	SPEED_TAU = 0.12,
	ROLL_TAU = 0.12,
	-- Speeds between these two blend rest into walk. Everything that used to
	-- test `speed > 1.15` reads the blend instead.
	GAIT_LO = 0.8,
	GAIT_HI = 3.0,
	-- Spring: base rate, how much being left behind stiffens it, and the
	-- damping. zeta below 1 is the follow-through; at 1 it brakes dead.
	SPRING_HZ = 3.6,
	SPRING_HZ_CATCHUP = 2.6,
	SPRING_ZETA = 0.86,
}

-- Framerate-independent smoothing factor for a given time constant.
function PF.smooth(tau, dt)
	return 1 - math.exp(-dt / math.max(1e-4, tau))
end

-- 0 below lo, 1 above hi, eased in between. No corners, so nothing pops as a
-- value crosses it.
function PF.gait(x, lo, hi)
	local t = math.clamp((x - lo) / math.max(1e-4, hi - lo), 0, 1)
	return t * t * (3 - 2 * t)
end

--[[
	ONE STEP OF A DAMPED SPRING, SOLVED IMPLICITLY.

	Owner, 2026-10-05: pets "kinda just fly around the screen like crazy", on a
	session measured at 15 fps. Those are the same bug.

	The old step was EXPLICIT Euler:

	    accel = delta * omega^2 - vel * (2 * zeta * omega)
	    vel  += accel * dt
	    pos  += vel * dt

	which is only CONDITIONALLY stable -- it needs roughly omega * dt < 2, and
	past that each step amplifies the last instead of damping it. SPRING_HZ 3.6
	stiffens to 6.2 while catching up, so omega reaches 2*pi*6.2 = 39. At 60 fps
	omega*dt is 0.65 and fine. At the 0.05 dt clamp it is 1.95 -- right on the
	edge -- and the pet oscillates, overshoots further each frame, and flies.

	The feedback loop is the nasty part: a pet thrown far from its target raises
	`dist`, which raises hz, which raises omega, which makes the next step even
	less stable. Low framerate starts it and the catch-up term runs away with it.

	This is the EXACT solution of that equation over the frame, not an
	approximation of it. Backward Euler was the first fix and it is stable, but
	it is stable by adding numerical damping that grows with dt -- measured, a
	10-stud settle took 0.150s at 120 fps and 0.233s at 30 fps, so a pet behaved
	like a different pet on a slower machine.

	An underdamped spring has a closed form. Writing e = pos - target and
	wd = omega*sqrt(1 - zeta^2):

	    e(h) = exp(-zeta*omega*h) * (e0*cos(wd*h) + B*sin(wd*h))
	    B    = (v0 + zeta*omega*e0) / wd

	Both stable and framerate-independent, because exp(-zeta*omega*h) is below 1
	for every positive h -- there is no step size that can amplify anything -- and
	because h appears only as real elapsed time. 30 fps and 240 fps now trace the
	same curve. The cost is one exp and two trig calls per pet per frame.

	zeta is clamped under 1 because the formula divides by wd, which is zero at
	critical damping. Nothing here passes 1 -- SPRING_ZETA is 0.86, deliberately
	underdamped so a pet leans into a stop and drifts a hair past -- but the
	clamp means a future tweak degrades smoothly instead of returning NaN.

	Pure, and typed by nothing: it runs on Vector3 in the game and on plain
	numbers in tools/verify/pet-spring.js, which is how the claims above are
	checked rather than asserted.
]]
function PF.spring(pos, vel, target, h, hz, zeta)
	if h <= 0 then
		return pos, vel
	end
	local omega = 2 * math.pi * math.max(1e-4, hz)
	local z = math.clamp(zeta, 0, 0.9999)
	local wd = omega * math.sqrt(1 - z * z)
	local e0 = pos - target
	local decay = math.exp(-z * omega * h)
	local c, s = math.cos(wd * h), math.sin(wd * h)
	local b = (vel + e0 * (z * omega)) / wd
	local e1 = (e0 * c + b * s) * decay
	local v1 = (vel * c - (e0 * (omega * omega) + vel * (z * omega)) * (s / wd)) * decay
	return target + e1, v1
end

--[[
	`total` is how many pets are actually out, and it is why this takes it.

	The formation used to be hardcoded around slot 2 -- `(slot - 2) * 2.15` --
	which only centres when there are exactly three. With one pet out it walked
	2.15 studs to your LEFT and never behind you; with two, both sat off-centre.
	Owner, 2026-10-04: "make pets centre no matter how many are there."

	Centring on (total + 1) / 2 puts one pet directly behind you, two evenly
	either side, three in the old arrangement, and so on for any count without
	another magic number.
]]
function ClientFns.stepPetFollow(pet, root, slotIndex, now, dt, total)
	if not (pet and pet.Parent and root) then
		return
	end
	--[[
		The ceiling was 0.05, which is 20 fps. On the owner's 15 fps session the
		real frame was 0.067, so every step advanced the pets 75% of a frame:
		they fell behind real time, `dist` grew, the catch-up term stiffened the
		spring, and the explicit integrator went unstable -- the clamp was feeding
		the runaway it was meant to guard against.

		0.1 lets a slow frame be a slow frame. It is safe to raise only because
		PF.spring is stable at any dt; a genuine hitch longer than this is a
		teleport, and the `dist > 22` branch below catches that.
	]]
	dt = math.clamp(tonumber(dt) or (1 / 60), 0.001, 0.1)
	now = tonumber(now) or os.clock()
	ClientFns._petFollowState = ClientFns._petFollowState or {}
	local state = ClientFns._petFollowState[pet]
	local look0 = root.CFrame.LookVector
	local flat0 = Vector3.new(look0.X, 0, look0.Z)
	flat0 = (flat0.Magnitude > 0.05) and flat0.Unit or Vector3.new(0, 0, -1)
	if not state then
		local pivot = pet:GetPivot()
		local _, yaw0, _ = pivot:ToEulerAnglesYXZ()
		state = {
			pos = pivot.Position,
			-- The spring's own velocity. Without this there is no follow-through.
			vel = Vector3.zero,
			yaw = yaw0,
			-- Smoothed basis and speed, so neither can step.
			dir = flat0,
			speed = 0,
			-- Advanced by gait, not by the clock.
			bobPhase = (tonumber(slotIndex) or 1) * 1.7,
			roll = 0,
		}
		ClientFns._petFollowState[pet] = state
	end

	local vel = root.AssemblyLinearVelocity
	local flatVel = Vector3.new(vel.X, 0, vel.Z)
	local rawSpeed = flatVel.Magnitude

	-- Smoothed speed drives every threshold, so a jittery velocity reading
	-- cannot make the formation twitch.
	state.speed += (rawSpeed - state.speed) * PF.smooth(PF.SPEED_TAU, dt)
	local gait = PF.gait(state.speed, PF.GAIT_LO, PF.GAIT_HI)

	--[[
		The basis, eased. Where the owner is moving when they are moving, where
		they are facing when they are not, blended by the same gait -- so
		standing still and turning on the spot swings the formation around
		rather than snapping it to a new side.
	]]
	local moveDir = (rawSpeed > 0.05) and flatVel.Unit or flat0
	local wantDir = flat0:Lerp(moveDir, gait)
	if wantDir.Magnitude > 0.05 then
		wantDir = wantDir.Unit
		state.dir = state.dir:Lerp(wantDir, PF.smooth(PF.DIR_TAU, dt))
		if state.dir.Magnitude > 0.05 then
			state.dir = state.dir.Unit
		else
			state.dir = wantDir
		end
	end
	local dir = state.dir
	local right = Vector3.new(-dir.Z, 0, dir.X)

	local slot = tonumber(slotIndex) or 1
	-- Defaults to 3 so a caller that forgets keeps the old formation rather
	-- than collapsing every pet onto one spot.
	local n = math.max(1, math.floor(tonumber(total) or 3))
	local centre = (n + 1) / 2
	local lateral = (slot - centre) * 2.15
	local back = 3.15 + math.abs(slot - centre) * 0.18
	-- Trail farther when sprinting so they don't glue to your heels. Off the
	-- smoothed speed, so the spacing opens out instead of jumping.
	local trail = math.clamp(state.speed / 16, 0, 1.35)
	local target = root.Position - dir * (back + trail) + right * lateral
	target = Vector3.new(target.X, root.Position.Y + 0.04, target.Z)

	local delta = target - state.pos
	local dist = delta.Magnitude
	if dist > 22 then
		-- A teleport, not a walk. Nothing to animate through.
		state.pos = target
		state.vel = Vector3.zero
	else
		-- Stiffens with distance the way the old lerp did, so a pet left behind
		-- still hurries rather than drifting in forever. Safe to keep now that
		-- the integrator cannot be destabilised by a high omega -- see PF.spring.
		local hz = PF.SPRING_HZ + math.clamp(dist / 5, 0, 1) * PF.SPRING_HZ_CATCHUP
		state.pos, state.vel = PF.spring(state.pos, state.vel, target, dt, hz, PF.SPRING_ZETA)
	end

	--[[
		Face where you are GOING, which for a pet on a spring is its own
		velocity -- that is what makes a pet cut a corner nose-first instead of
		sliding through it sideways. Below walking pace its own velocity is
		noise, so it falls back to the formation basis.
	]]
	local travel = Vector3.new(state.vel.X, 0, state.vel.Z)
	local face = dir
	if travel.Magnitude > 0.35 then
		face = travel.Unit
	end
	local wantYaw = math.atan2(-face.X, -face.Z)
	local dy = (wantYaw - state.yaw + math.pi) % (math.pi * 2) - math.pi
	-- Turn faster when moving: a trotting pet whips its head round a corner, a
	-- standing one drifts to face you.
	local yawHz = 5.0 + gait * 6.0
	state.yaw += dy * (1 - math.exp(-yawHz * dt))

	--[[
		Bob by DISTANCE, not by the clock. A pet standing still breathes at the
		idle rate; a moving one steps at a cadence that rises with gait. Because
		the phase is integrated rather than read off `now`, the rate can change
		without the waveform jumping, which is what the old
		`sin(now * bobHz + phase)` did every time bobHz flipped.
	]]
	--[[
		SLOWER, AND IT CANNOT ALIAS.

		Owner, 2026-10-06: pets are "bobing up and down super fucking fast".

		Two causes, both mine. The rate was 1.9 Hz at rest rising to 4.1 Hz at a
		walk -- nearly four bobs a second, a twitch rather than a gait. And
		raising the dt clamp to 0.1 for the spring let one frame advance the
		phase by 4.1 * 0.1 * 2pi = 2.6 radians, past the half cycle at which a
		sine stops being sampled and starts being ALIASED: the pet then appears
		to jump at a frequency with no relation to the wave. At the 10 fps the
		owner was seeing, that is exactly what happened.

		0.55 Hz at rest to 1.65 Hz walking reads as breathing, then stepping.
		The per-frame cap is the belt: no frame may advance more than a quarter
		cycle, so a slow frame SLOWS the bob rather than scrambling it. Only this
		cosmetic wave is clamped -- the pet's position still tracks real time.
	]]
	local bobRate = 0.55 + gait * 1.1
	state.bobPhase += math.min(bobRate * dt * math.pi * 2, math.pi * 0.5)
	local bobAmp = 0.09 + gait * 0.07
	local bob = math.sin(state.bobPhase) * bobAmp

	-- Bank into the turn, eased. Reads as weight; a pet that changes heading
	-- with its body dead level is most of what "stiff" means.
	local wantRoll = math.clamp(-dy / math.max(1e-4, dt) * 0.012, -0.22, 0.22) * gait
	state.roll += (wantRoll - state.roll) * PF.smooth(PF.ROLL_TAU, dt)

	local lean = math.clamp(state.speed / 24, 0, 0.11)
	pet:PivotTo(CFrame.new(state.pos + Vector3.new(0, bob, 0))
		* CFrame.Angles(lean, state.yaw, state.roll))
end

function ClientFns.updatePets()
	ClientFns.clearPets()
	if not snap then
		return
	end
	for i, id in ipairs(snap.equipped) do
		for _, card in ipairs(snap.cards) do
			if card.id == id then
				local model = ClientFns.buildPetModel(card)
				model.Parent = workspace
				local tag = mk("BillboardGui", {
					Name = "PetTag",
					AlwaysOnTop = true,
					Size = UDim2.fromOffset(140, 36),
					StudsOffset = Vector3.new(0, 2.15, 0),
					MaxDistance = 40,
				}, model)
				mk("TextLabel", {
					BackgroundTransparency = 1,
					Font = FONT,
					TextSize = 14,
					TextColor3 = TEXT,
					TextStrokeTransparency = 1,
					Size = UDim2.new(1, 0, 0, 18),
					Text = card.name,
				}, tag)
				mk("TextLabel", {
					BackgroundTransparency = 1,
					Font = FONT_M,
					TextSize = 12,
					TextColor3 = Cards.RARITY_COLOR[card.rarityId] or GOLD,
					TextStrokeTransparency = 1,
					Position = UDim2.fromOffset(0, 16),
					Size = UDim2.new(1, 0, 0, 16),
					Text = Cards.RARITY_LABEL[card.rarityId] or card.rarityId,
				}, tag)
				pets[i] = model
				ClientFns.dressPet(model, card)
			end
		end
	end
	ClientFns.petModels = pets
	ClientFns.applyPetGlowToWorld()
	if ClientFns.syncSpaceHelmets then
		ClientFns.syncSpaceHelmets()
	end
end

RunService.RenderStepped:Connect(function(dt)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local now = os.clock()
	local petCount = #pets
	for i, pet in ipairs(pets) do
		if pet and pet.Parent then
			ClientFns.stepPetFollow(pet, root, i, now, dt, petCount)
			--[[
				Only a Rainbow pet has anything to cycle.

				animateChroma walks model:GetDescendants() -- a fresh table of ~25
				instances -- and asks every BasePart for a Chroma attribute. For a
				pet that is not Rainbow it finds nothing and sets nothing, every
				frame, forever. The other-players loop above already gates this on
				the Variant attribute; this one never did.

				Measured over 600 frames with three pets: 0.0076 ms ungated against
				0.0002 ms gated. Small either way -- this is not the lag the owner
				reported, and it is not being presented as the fix -- but it is
				free, and the two loops disagreeing was the actual bug.
			]]
			if pet:GetAttribute("Variant") == "Rainbow" then
				PetFactory.animateChroma(pet, now)
			end
		end
	end
end)

--[[
	The pointer, as a ray from the camera: the finger that started the dig on a
	touch screen, the mouse everywhere else (shift-lock and first person park
	the mouse in the middle of the screen, so they need nothing special).

	GetMouseLocation and ViewportPointToRay both count from the very top of the
	window, so nothing is subtracted. This used to take the top-bar inset off
	first, which put the aim 58 pixels above the cursor.
]]
function ClientFns.pointerRay(cam)
	local touch = ClientFns.digTouch
	if touch and touch.UserInputState ~= Enum.UserInputState.End then
		-- ViewportPointToRay, NOT ScreenPointToRay: touch.Position is already in
		-- inset-adjusted space, and ScreenPointToRay adds the inset again --
		-- which put the mobile aim a full inset below the finger.
		return cam:ViewportPointToRay(touch.Position.X, touch.Position.Y)
	end
	local loc = UIS:GetMouseLocation()
	return cam:ViewportPointToRay(loc.X, loc.Y)
end

--[[
	The block under the pointer, if it is within reach.

	The ray starts at the CAMERA and goes through the pointer, so what is under
	the cursor is what you hit; reach is then measured from the character, the
	same way the server measures it. It used to start at the character and run
	parallel to the camera ray: in third person that lands on a different block
	from the one under the cursor, and from inside a hole the block beside you
	filled so much of that fan that moving the mouse while holding never
	changed the target.

	Other players do not stop the pick, and neither does anything you can see
	through or walk through; solid scenery and terrain do, so nothing is mined
	through a wall.
]]
function ClientFns.aimedBlock()
	local cam = workspace.CurrentCamera
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	ClientFns.aimHit, ClientFns.aimNormal = nil, nil
	if not cam or not root then
		return
	end
	local range = (snap and snap.tool and tonumber(snap.tool.reach)) or 26
	local params = ClientFns.aimParams
	if not params then
		params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.IgnoreWater = true
		ClientFns.aimParams = params
	end
	local skip = { char }
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Character then
			table.insert(skip, other.Character)
		end
	end
	local fxFolder = ClientFns.fx and ClientFns.fx.folder
	if fxFolder then
		table.insert(skip, fxFolder)
	end
	params.FilterDescendantsInstances = skip
	local aim = ClientFns.pointerRay(cam)
	local origin = aim.Origin
	local dir = aim.Direction.Unit
	local left = (origin - root.Position).Magnitude + range + (C.BLOCK or 5)
	for _ = 1, 4 do
		if left <= 0 then
			return
		end
		local hit = workspace:Raycast(origin, dir * left, params)
		if not hit then
			return
		end
		local inst = hit.Instance
		local block = (inst.Name == "MineBlock" and inst) or inst:FindFirstAncestor("MineBlock")
		if block then
			if block:IsA("BasePart") and (root.Position - block.Position).Magnitude <= range then
				ClientFns.aimHit, ClientFns.aimNormal = hit.Position, hit.Normal
				return block
			end
			return
		end
		if inst ~= workspace.Terrain and (inst.Transparency >= 0.95 or not inst.CanCollide) then
			params:AddToFilter(inst)
			left -= (hit.Position - origin).Magnitude
			origin = hit.Position
		else
			return
		end
	end
end

-- Where the crosshair lands in the world, whether or not a block is there.
-- Charges need a POINT: they are lobbed at a spot, not clicked onto rock.
local function aimedPoint(range)
	local cam = workspace.CurrentCamera
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not cam or not root then
		return nil
	end
	local aim = ClientFns.pointerRay(cam)
	local dir = aim.Direction.Unit
	range = range or 26
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { player.Character }
	local hit = workspace:Raycast(root.Position, dir * range, params)
	if hit then
		return hit.Position
	end
	-- Nothing under the crosshair: throw as far as the tool reaches from the player.
	return root.Position + dir * range
end

function ClientFns.spark(pos, color)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = color or GOLD
	p.Size = Vector3.new(0.35, 0.35, 0.35)
	p.CFrame = CFrame.new(pos)
	p.Parent = workspace
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color or GOLD)
	e.Size = NumberSequence.new(0.35, 0)
	e.Lifetime = NumberRange.new(0.2, 0.4)
	e.Speed = NumberRange.new(6, 12)
	e.SpreadAngle = Vector2.new(40, 40)
	e.Rate = 0
	e.Parent = p
	e:Emit(14)
	Debris:AddItem(p, 0.5)
end

--[[
	Mining feedback. A swing throws chips off the face you struck, the block
	cracks as its HP goes, and a broken block comes apart in pieces of its own
	rock. This replaced a gold neon ball dropped in the middle of the block.

	All of it is local to this client and purely visual: the pieces are
	anchored, never collide and never take a raycast, so they cannot eat a
	click or shove a character.
]]
ClientFns.fx = { live = {}, pool = {}, cracked = {}, crackCount = 0 }
ClientFns.CRACK_PPS = 40
ClientFns.CRACK_MAX = 10
-- { face, outward normal in part space, canvas width axis, canvas height axis }
ClientFns.CRACK_FACES = {
	{ Enum.NormalId.Front, Vector3.new(0, 0, -1), "X", "Y" },
	{ Enum.NormalId.Back, Vector3.new(0, 0, 1), "X", "Y" },
	{ Enum.NormalId.Left, Vector3.new(-1, 0, 0), "Z", "Y" },
	{ Enum.NormalId.Right, Vector3.new(1, 0, 0), "Z", "Y" },
	{ Enum.NormalId.Top, Vector3.new(0, 1, 0), "X", "Z" },
	{ Enum.NormalId.Bottom, Vector3.new(0, -1, 0), "X", "Z" },
}

function ClientFns.fxFolder()
	local fx = ClientFns.fx
	if not (fx.folder and fx.folder.Parent) then
		local f = Instance.new("Folder")
		f.Name = "MineClientFx"
		f.Parent = workspace
		fx.folder = f
	end
	return fx.folder
end

function ClientFns.fxSkip(extra)
	local skip = { ClientFns.fxFolder() }
	if player.Character then
		table.insert(skip, player.Character)
	end
	if extra then
		table.insert(skip, extra)
	end
	return skip
end

-- What a block looks like, captured while it still exists: a break has to
-- know what it was breaking even when the part is already gone.
function ClientFns.lookOf(part, kind)
	if part and part.Parent and part:IsA("BasePart") then
		return { color = part.Color, material = part.Material, size = part.Size, cf = part.CFrame, reflect = part.Reflectance }
	end
	local spec = C.BLOCKS[kind or "dirt"] or C.BLOCKS.dirt
	local b = C.BLOCK or 5
	return { color = spec.color, material = spec.material, size = Vector3.new(b, b, b) }
end

-- The block whose centre is at `pos`, if this client still has it.
function ClientFns.blockAt(pos)
	local fx = ClientFns.fx
	local params = fx.overlap
	if not params then
		params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		fx.overlap = params
	end
	params.FilterDescendantsInstances = ClientFns.fxSkip()
	for _, part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(pos), Vector3.new(0.4, 0.4, 0.4), params)) do
		local block = (part.Name == "MineBlock" and part) or part:FindFirstAncestor("MineBlock")
		if block and block:IsA("BasePart") and (block.Position - pos).Magnitude < 0.75 then
			return block
		end
	end
end

-- Height of whatever is under `from`, for the pieces to land on.
function ClientFns.fxFloor(from, depth)
	local fx = ClientFns.fx
	local params = fx.down
	if not params then
		params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.IgnoreWater = true
		fx.down = params
	end
	params.FilterDescendantsInstances = ClientFns.fxSkip()
	local hit = workspace:Raycast(from, Vector3.new(0, -depth, 0), params)
	return hit and hit.Position.Y or (from.Y - depth)
end

function ClientFns.fxPiece(look, size)
	local fx = ClientFns.fx
	local p = table.remove(fx.pool)
	if not p then
		p = Instance.new("Part")
		p.Name = "Chip"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
	end
	p.Size = size
	p.Color = look.color
	p.Material = look.material
	p.Reflectance = look.reflect or 0
	p.Transparency = 0
	return p
end

function ClientFns.fxShade(color, r)
	local k = r:NextNumber(-0.2, 0.12)
	if k < 0 then
		return color:Lerp(Color3.new(0, 0, 0), -k)
	end
	return color:Lerp(Color3.new(1, 1, 1), k)
end

function ClientFns.fxRecycle(p)
	local fx = ClientFns.fx
	p.Parent = nil
	if #fx.pool < 150 then
		table.insert(fx.pool, p)
	else
		p:Destroy()
	end
end

--[[
	Every flying piece moves in one stepper: gravity, a bounce and a slide on
	whatever is below it, a tumble, and a shrink over the last of its life.
]]
function ClientFns.fxLaunch(p, at, vel, life, floorY)
	local fx = ClientFns.fx
	local r = fx.rng
	p.CFrame = CFrame.new(at) * CFrame.Angles(r:NextNumber(0, 6.283), r:NextNumber(0, 6.283), r:NextNumber(0, 6.283))
	p.Parent = ClientFns.fxFolder()
	table.insert(fx.live, {
		part = p, pos = at, vel = vel, age = 0, life = life, size = p.Size, floor = floorY, bounces = 0,
		spin = Vector3.new(r:NextNumber(-12, 12), r:NextNumber(-12, 12), r:NextNumber(-12, 12)),
	})
	if fx.stepper then
		return
	end
	fx.stepper = RunService.Heartbeat:Connect(function(dt)
		local list = fx.live
		local i = 1
		while i <= #list do
			local d = list[i]
			d.age += dt
			local part = d.part
			if d.age >= d.life or not part.Parent then
				ClientFns.fxRecycle(part)
				list[i] = list[#list]
				list[#list] = nil
			else
				d.vel -= Vector3.new(0, 70 * dt, 0)
				local pos = d.pos + d.vel * dt
				local half = d.size.Y * 0.4
				if d.floor and pos.Y - half < d.floor and d.vel.Y < 0 then
					pos = Vector3.new(pos.X, d.floor + half, pos.Z)
					d.bounces += 1
					if d.bounces == 1 then
						d.vel = Vector3.new(d.vel.X * 0.5, -d.vel.Y * 0.3, d.vel.Z * 0.5)
					else
						d.vel = Vector3.new(d.vel.X * 0.6, 0, d.vel.Z * 0.6)
					end
					d.spin *= 0.55
				end
				d.pos = pos
				local u = d.age / d.life
				if u > 0.6 then
					part.Size = d.size * math.max(0.05, 1 - (u - 0.6) / 0.4)
				end
				local s = d.spin * dt
				part.CFrame = CFrame.new(pos) * (part.CFrame - part.CFrame.Position) * CFrame.Angles(s.X, s.Y, s.Z)
				i += 1
			end
		end
	end)
end

function ClientFns.dustFx(at, color, count, scale)
	local fx = ClientFns.fx
	local anchor = fx.anchor
	if not (anchor and anchor.Parent) then
		anchor = Instance.new("Part")
		anchor.Name = "DustAnchor"
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(0.2, 0.2, 0.2)
		anchor.CFrame = CFrame.new()
		anchor.Parent = ClientFns.fxFolder()
		fx.anchor = anchor
	end
	local a = Instance.new("Attachment")
	a.Position = at
	a.Parent = anchor
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.35), color)
	e.LightInfluence = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6 * scale), NumberSequenceKeypoint.new(1, 2.4 * scale) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.45, 0.85)
	e.Speed = NumberRange.new(1.5, 5 * scale)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Drag = 4
	e.Acceleration = Vector3.new(0, 2, 0)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-50, 50)
	e.Rate = 0
	e.Parent = a
	e:Emit(count)
	Debris:AddItem(a, 1.1)
end

-- A swing: chips off the face you struck and a puff of its dust. `few` is a
-- cell someone else's blow reached (a blast, an echo, auto-mine).
function ClientFns.chipFx(block, at, normal, few)
	if not (block and block.Parent) then
		return
	end
	local fx = ClientFns.fx
	fx.rng = fx.rng or Random.new()
	local r = fx.rng
	local look = ClientFns.lookOf(block)
	normal = normal or Vector3.new(0, 1, 0)
	at = at or (block.Position + normal * (look.size.Y * 0.5))
	local busy = #fx.live
	local n = (busy > 220 and 0) or ((few or busy > 140) and 2) or r:NextInteger(4, 6)
	local floorY = ClientFns.fxFloor(at + normal * 0.5 + Vector3.new(0, 0.5, 0), 30)
	for _ = 1, n do
		local sz = r:NextNumber(0.22, 0.5)
		local p = ClientFns.fxPiece(look, Vector3.new(sz, sz * r:NextNumber(0.55, 1), sz * r:NextNumber(0.7, 1.1)))
		p.Color = ClientFns.fxShade(look.color, r)
		local spread = Vector3.new(r:NextNumber(-1, 1), r:NextNumber(-0.3, 1), r:NextNumber(-1, 1)) * r:NextNumber(3, 7)
		local vel = normal * r:NextNumber(6, 12) + spread + Vector3.new(0, r:NextNumber(5, 10), 0)
		ClientFns.fxLaunch(p, at + normal * 0.2, vel, r:NextNumber(0.45, 0.75), floorY)
	end
	ClientFns.dustFx(at + normal * 0.3, look.color, few and 1 or 3, 0.7)
end

--[[
	A block giving way: its eight corners and a scatter of shards, in its own
	rock, thrown out of the hole and dropped, with a burst of dust. Fewer
	pieces when a lot is already flying (a blast breaks many cells at once)
	or when it happens far from the camera.
]]
function ClientFns.shatterFx(pos, look)
	local fx = ClientFns.fx
	fx.rng = fx.rng or Random.new()
	local r = fx.rng
	local size = look.size or Vector3.new(5, 5, 5)
	local rot = look.cf and (look.cf - look.cf.Position) or CFrame.new()
	local busy = #fx.live
	local corners = (busy < 170 and 8) or (busy < 250 and 4) or 0
	local shards = (busy < 120 and r:NextInteger(5, 8)) or 0
	local cam = workspace.CurrentCamera
	if cam and (cam.CFrame.Position - pos).Magnitude > 90 then
		corners, shards = math.min(corners, 4), 0
	end
	local floorY = ClientFns.fxFloor(pos, 40)
	local order = { 0, 1, 2, 3, 4, 5, 6, 7 }
	for i = 8, 2, -1 do
		local j = r:NextInteger(1, i)
		order[i], order[j] = order[j], order[i]
	end
	local q = size * 0.25
	for k = 1, corners do
		local c = order[k]
		local sx = (c % 2 == 0) and -1 or 1
		local sy = (math.floor(c / 2) % 2 == 0) and -1 or 1
		local sz = (math.floor(c / 4) % 2 == 0) and -1 or 1
		local off = rot * Vector3.new(sx * q.X, sy * q.Y, sz * q.Z)
		local p = ClientFns.fxPiece(look, size * 0.5 * r:NextNumber(0.62, 0.85))
		local vel = off.Unit * r:NextNumber(5, 10) + Vector3.new(0, r:NextNumber(8, 15), 0)
		ClientFns.fxLaunch(p, pos + off, vel, r:NextNumber(0.8, 1.1), floorY)
	end
	for _ = 1, shards do
		local sz = r:NextNumber(0.3, 0.75)
		local p = ClientFns.fxPiece(look, Vector3.new(sz, sz * r:NextNumber(0.4, 0.9), sz * r:NextNumber(0.6, 1.3)))
		p.Color = ClientFns.fxShade(look.color, r)
		local dir = Vector3.new(r:NextNumber(-1, 1), r:NextNumber(0.1, 1), r:NextNumber(-1, 1)).Unit
		ClientFns.fxLaunch(p, pos + dir * 1.4, dir * r:NextNumber(11, 19) + Vector3.new(0, 4, 0), r:NextNumber(0.6, 0.95), floorY)
	end
	ClientFns.dustFx(pos, look.color, 10, 1.5)
end

--[[
	Cracks. A struck block grows a web of cracks on its open faces as its HP
	goes, redrawn from the HP attribute, so every blow -- yours, a blast's,
	auto-mine's -- moves it along. Only the last few blocks you touched keep a
	web, and only faces with no block against them get one.
]]
function ClientFns.crackPattern(seed, w, h)
	local r = Random.new(seed)
	local segs = {}
	local cx, cy = w * r:NextNumber(0.35, 0.65), h * r:NextNumber(0.35, 0.65)
	local arms = r:NextInteger(4, 6)
	local base = r:NextNumber(0, math.pi * 2)
	local reach = math.min(w, h)
	for a = 1, arms do
		local ang = base + (a / arms) * math.pi * 2 + r:NextNumber(-0.35, 0.35)
		local x, y = cx, cy
		for st = 1, r:NextInteger(3, 5) do
			ang += r:NextNumber(-0.5, 0.5)
			local len = reach * r:NextNumber(0.09, 0.16)
			local nx = math.clamp(x + math.cos(ang) * len, 2, w - 2)
			local ny = math.clamp(y + math.sin(ang) * len, 2, h - 2)
			table.insert(segs, { x, y, nx, ny, math.max(1.5, 4.6 - st * 0.8), st + r:NextNumber(0, 0.8) })
			if st >= 2 and r:NextNumber() < 0.5 then
				local ta = ang + (r:NextNumber() < 0.5 and -1 or 1) * r:NextNumber(0.6, 1.2)
				local tl = len * r:NextNumber(0.4, 0.7)
				table.insert(segs, {
					nx, ny,
					math.clamp(nx + math.cos(ta) * tl, 2, w - 2), math.clamp(ny + math.sin(ta) * tl, 2, h - 2),
					1.4, st + 0.9 + r:NextNumber(0, 0.8),
				})
			end
			x, y = nx, ny
			if x <= 2.5 or x >= w - 2.5 or y <= 2.5 or y >= h - 2.5 then
				break
			end
		end
	end
	table.sort(segs, function(p, q)
		return p[6] < q[6]
	end)
	return segs
end

function ClientFns.crackFace(part, idx, rec)
	local face = ClientFns.CRACK_FACES[idx]
	local pps = ClientFns.CRACK_PPS
	local w, h = part.Size[face[3]] * pps, part.Size[face[4]] * pps
	local sg = Instance.new("SurfaceGui")
	sg.Name = "MineCracks"
	sg.Face = face[1]
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = pps
	sg.LightInfluence = 1
	sg.MaxDistance = 140
	sg.ClipsDescendants = true
	local frames = {}
	for i, seg in ipairs(ClientFns.crackPattern(rec.seed + idx * 7919, w, h)) do
		local dx, dy = seg[3] - seg[1], seg[4] - seg[2]
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromOffset((seg[1] + seg[3]) * 0.5, (seg[2] + seg[4]) * 0.5)
		f.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + seg[5] * 0.5, seg[5])
		f.Rotation = math.deg(math.atan2(dy, dx))
		f.BorderSizePixel = 0
		f.BackgroundColor3 = rec.col
		f.BackgroundTransparency = 0.08
		f.Visible = false
		f.Parent = sg
		frames[i] = f
	end
	sg.Parent = part
	return { gui = sg, frames = frames }
end

function ClientFns.crackOpenFaces(part, rec)
	local step = C.BLOCK or 5
	for idx, face in ipairs(ClientFns.CRACK_FACES) do
		if not rec.faces[idx] then
			local out = part.CFrame:VectorToWorldSpace(face[2])
			if not ClientFns.blockAt(part.Position + out * step) then
				rec.faces[idx] = ClientFns.crackFace(part, idx, rec)
			end
		end
	end
end

function ClientFns.crackUpdate(part)
	local rec = ClientFns.fx.cracked[part]
	if not rec then
		return
	end
	if not part.Parent then
		ClientFns.crackDrop(part)
		return
	end
	local kind = part:GetAttribute("Kind") or "dirt"
	local scaled = C.blockHp(kind, part:GetAttribute("ZoneId"), part:GetAttribute("CY") or 1)
	local maxHp, hp
	if part:GetAttribute("Matter") == "space" then
		maxHp = tonumber(part:GetAttribute("SpaceMax")) or tonumber(part:GetAttribute("MaxHP")) or tonumber(scaled) or 1
		hp = tonumber(part:GetAttribute("SpaceHP")) or maxHp
	else
		maxHp = tonumber(part:GetAttribute("MaxHP")) or tonumber(scaled) or 1
		hp = tonumber(part:GetAttribute("HP")) or maxHp
	end
	local frac = math.clamp(1 - hp / math.max(1, maxHp), 0, 1)
	rec.t = os.clock()
	if frac > 0 then
		ClientFns.crackOpenFaces(part, rec)
	end
	for _, face in pairs(rec.faces) do
		local n = frac > 0 and math.max(3, math.ceil(#face.frames * frac ^ 0.85)) or 0
		for i, f in ipairs(face.frames) do
			f.Visible = i <= n
		end
	end
end

function ClientFns.crackDrop(part)
	local fx = ClientFns.fx
	local rec = fx.cracked[part]
	if not rec then
		return
	end
	fx.cracked[part] = nil
	fx.crackCount -= 1
	if rec.hpConn then
		rec.hpConn:Disconnect()
	end
	if rec.goneConn then
		rec.goneConn:Disconnect()
	end
	for _, face in pairs(rec.faces) do
		if face.gui then
			face.gui:Destroy()
		end
	end
end

function ClientFns.crackHit(part)
	if not (part and part.Parent and part:IsA("BasePart")) then
		return
	end
	local fx = ClientFns.fx
	if not fx.cracked[part] then
		if fx.crackCount >= ClientFns.CRACK_MAX then
			local oldest, when = nil, math.huge
			for p, rec in pairs(fx.cracked) do
				if rec.t < when then
					oldest, when = p, rec.t
				end
			end
			if oldest then
				ClientFns.crackDrop(oldest)
			end
		end
		local c = part.Color
		local lum = c.R * 0.2126 + c.G * 0.7152 + c.B * 0.0722
		local at = part.Position
		local rec = {
			t = os.clock(),
			faces = {},
			seed = (math.floor(at.X) * 73 + math.floor(at.Y) * 9151 + math.floor(at.Z) * 331) % 1000003,
			-- Dark rock shows pale fissures; everything else shows dark ones.
			col = lum < 0.22 and c:Lerp(Color3.new(1, 1, 1), 0.5) or c:Lerp(Color3.new(0, 0, 0), 0.78),
			look = ClientFns.lookOf(part),
		}
		fx.cracked[part] = rec
		fx.crackCount += 1
		rec.hpConn = part:GetAttributeChangedSignal("HP"):Connect(function()
			ClientFns.crackUpdate(part)
		end)
		rec.goneConn = part.AncestryChanged:Connect(function(_, parent)
			if not parent then
				ClientFns.crackDrop(part)
			end
		end)
	end
	ClientFns.crackUpdate(part)
end

-- The pick comes down on every swing: the rig's own tool-slash track, sped up
-- to fit inside one swing so a fast tool does not queue swings behind it.
function ClientFns.swingArm(need)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator or not char:FindFirstChildOfClass("Tool") then
		return
	end
	local fx = ClientFns.fx
	local track = fx.slashTrack
	if not track or fx.slashAnimator ~= animator then
		local animate = char:FindFirstChild("Animate")
		local src = animate and animate:FindFirstChild("toolslash")
		local asset = src and src:FindFirstChildOfClass("Animation")
		if not asset then
			return
		end
		local ok, loaded = pcall(function()
			return animator:LoadAnimation(asset)
		end)
		if not ok or not loaded then
			return
		end
		loaded.Priority = Enum.AnimationPriority.Action
		loaded.Looped = false
		fx.slashTrack, fx.slashAnimator, track = loaded, animator, loaded
	end
	local length = track.Length > 0 and track.Length or 0.6
	local speed = math.clamp(length / math.max(0.12, (need or 0.4) * 0.9), 1.1, 4)
	if track.IsPlaying then
		track.TimePosition = 0
		track:AdjustSpeed(speed)
	else
		track:Play(0.05, 0.9, speed)
	end
end

-- Standing still and digging, you turn to face the block you are working.
-- Walking keeps its own facing, and shift-lock / first person already face
-- the camera.
function ClientFns.faceTarget(target, dt)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Sit or hum.MoveDirection.Magnitude > 0.1 then
		return
	end
	if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
		return
	end
	local flat = (target.Position - root.Position) * Vector3.new(1, 0, 1)
	if flat.Magnitude < 1.5 then
		return
	end
	local want = math.atan2(-flat.X, -flat.Z)
	local _, have = root.CFrame:ToOrientation()
	local diff = (want - have + math.pi) % (2 * math.pi) - math.pi
	if math.abs(diff) < 0.03 then
		return
	end
	root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, have + diff * math.min(1, dt * 18), 0)
end

-- Your own swing, the moment it leaves: the arm, the chips, and the crack web
-- starts following this block's HP.
function ClientFns.swingFx(target, need)
	ClientFns.fx.lastSwung = target
	ClientFns.swingArm(need)
	ClientFns.chipFx(target, ClientFns.aimHit, ClientFns.aimNormal)
	ClientFns.crackHit(target)
	Audio.playDig(snap and snap.tool, target and target.Position)
end

--[[
	The server's word on a blow ("hit" carries the block centre and its HP
	after the blow). A block at 0 comes apart here; anything else cracks a
	little further, and cells a blast, an echo or auto-mine reached throw a
	few chips so the spread reads.
]]
function ClientFns.onHit(payload)
	local pos = payload.pos
	if typeof(pos) ~= "Vector3" then
		return
	end
	local fx = ClientFns.fx
	local part = ClientFns.blockAt(pos)
	if (tonumber(payload.hp) or 1) <= 0 then
		Audio.play("crunch", 1, nil, pos)
		local look
		if part then
			look = ClientFns.lookOf(part)
			ClientFns.crackDrop(part)
			-- Gone for this client now: the pieces should not appear inside a
			-- whole block for a network tick, and the pointer should move on.
			local hidden = { { part, part.Transparency } }
			for _, d in ipairs(part:GetDescendants()) do
				if d:IsA("BasePart") then
					table.insert(hidden, { d, d.Transparency })
				end
			end
			for _, pair in ipairs(hidden) do
				pair[1].Transparency = 1
			end
			part.CanQuery = false
			task.delay(2, function()
				-- The server always removes a broken block; if it did not, put it back.
				if part.Parent then
					for _, pair in ipairs(hidden) do
						pair[1].Transparency = pair[2]
					end
					part.CanQuery = true
				end
			end)
		else
			for p, rec in pairs(fx.cracked) do
				if rec.look and rec.look.cf and (rec.look.cf.Position - pos).Magnitude < 0.75 then
					look = rec.look
					ClientFns.crackDrop(p)
					break
				end
			end
		end
		ClientFns.shatterFx(pos, look or ClientFns.lookOf(nil, payload.kind))
		return
	end
	if part then
		ClientFns.crackHit(part)
		if part ~= fx.lastSwung then
			ClientFns.chipFx(part, nil, nil, true)
		end
	end
end

-- The haul popup: what you just earned, in white, with the coin and gem icons.
-- Every popup in the game used to carry a text stroke, which is where the white
-- outline round everything came from.

function ClientFns.haulPopup(coins, gems, space)
	coins = math.floor(tonumber(coins) or 0)
	gems = math.floor(tonumber(gems) or 0)
	space = math.floor(tonumber(space) or 0)
	if coins <= 0 and gems <= 0 and space <= 0 then
		return
	end
	pcall(Audio.playSell, coins, gems)

	-- Juicy centered sell burst: big +shortNum float matching loot FX.
	local row = mk("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.40, 0),
		Size = UDim2.fromOffset(420, 56),
		ZIndex = 70,
	}, gui)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 14),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)

	local function chunk(amount, icon, color, order)
		if amount <= 0 then
			return
		end
		local cell = mk("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 56),
			LayoutOrder = order,
			ZIndex = 70,
		}, row)
		mk("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
		}, cell)
		mk("ImageLabel", {
			BackgroundTransparency = 1,
			Image = icon,
			Size = UDim2.fromOffset(40, 40),
			ZIndex = 70,
		}, cell)
		mk("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 56),
			Font = FONT,
			TextSize = 42,
			TextColor3 = color,
			TextStrokeColor3 = Color3.fromRGB(12, 14, 20),
			TextStrokeTransparency = 0.35,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "+" .. shortNum(amount),
			ZIndex = 70,
		}, cell)
	end
	chunk(coins, ICONS.coin, COIN_POP, 1)
	chunk(gems, ICONS.gem, GEM_POP, 2)
	chunk(space, ICONS.coin, Color3.fromRGB(120, 210, 255), 3)

	local punch = TweenService:Create(row, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(460, 64),
	})
	punch:Play()
	task.delay(0.18, function()
		if not row.Parent then
			return
		end
		TweenService:Create(row, TweenInfo.new(0.95, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = row.Position + UDim2.fromOffset(0, -72),
		}):Play()
		for _, d in ipairs(row:GetDescendants()) do
			if d:IsA("TextLabel") then
				TweenService:Create(d, TweenInfo.new(0.95), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			elseif d:IsA("ImageLabel") then
				TweenService:Create(d, TweenInfo.new(0.95), { ImageTransparency = 1 }):Play()
			end
		end
	end)
	Debris:AddItem(row, 1.25)
end


-- The bag-full menu. Two ways out, both one click away, because the answer to
-- "you cannot carry any more" is always either sell it or carry more.
local bagMenu
function ClientFns.bagFullMenu()
	if bagMenu and bagMenu.Parent then
		bagMenu.Visible = true
		return
	end
	local f = mk("Frame", {
		Name = "BagFull", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(420, 190),
		BackgroundColor3 = Color3.fromRGB(46, 52, 78), ZIndex = 90,
	}, gui)
	round(f, 18)
	stroke(f, 2)
	mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 34), Font = FONT, TextSize = 26,
		TextColor3 = Color3.fromRGB(255, 255, 255), TextStrokeTransparency = 1,
		Text = "Your Backpack is full", ZIndex = 91,
	}, f)
	local row = mk("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 92),
		Size = UDim2.new(1, 0, 0, 62), ZIndex = 91,
	}, f)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 16),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, row)
	local function button(text, sub, colour, where, host)
		local b = mk("TextButton", {
			Size = UDim2.fromOffset(176, 58), BackgroundColor3 = colour,
			Text = "", AutoButtonColor = true, ZIndex = 91,
		}, host or row)
		round(b, 12)
		mk("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 8),
			Size = UDim2.new(1, 0, 0, 24), Font = FONT, TextSize = 20,
			TextColor3 = Color3.fromRGB(255, 255, 255), TextStrokeTransparency = 1,
			Text = text, ZIndex = 92,
		}, b)
		mk("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 30),
			Size = UDim2.new(1, 0, 0, 18), Font = FONT_M, TextSize = 12,
			TextColor3 = Color3.fromRGB(228, 234, 248), TextStrokeTransparency = 1,
			Text = sub, ZIndex = 92,
		}, b)
		b.MouseButton1Click:Connect(function()
			f.Visible = false
			if type(where) == "function" then
				where()
			else
				net:FireServer("bagGo", where)
			end
		end)
	end
	button("Sell", (snap and snap.vip) and "from anywhere (VIP)" or "to this mine's sell pad", Color3.fromRGB(56, 132, 86), "sell")
	button("Upgrade", "to the Blacksmith", Color3.fromRGB(70, 96, 166), "shop")
	--[[
		VIP sells from wherever it is standing, so for a VIP the sell never
		walks you out of the pit -- which left this menu with no way back up at
		all, the one thing a full bag actually needs.

		It goes on its own row UNDER the sell rather than beside it: the frame
		is 420 wide holding two 176-wide buttons and 16 of padding, and a third
		across does not fit.
	]]
	if snap and snap.vip then
		f.Size = UDim2.fromOffset(420, 262)
		local row2 = mk("Frame", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 160),
			Size = UDim2.new(1, 0, 0, 62), ZIndex = 91,
		}, f)
		mk("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 16),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}, row2)
		button("Return to surface", "you sell from down here (VIP)",
			Color3.fromRGB(96, 110, 150), function()
				net:FireServer("returnSurface")
			end, row2)
	end
	bagMenu = f
end

local function floatText(text, color, worldPos)
	pcall(Audio.playLoot)
	local label = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 22,
		TextColor3 = color or TEXT,
		TextStrokeTransparency = 1,
		Text = text,
		Size = UDim2.fromOffset(180, 36),
		AnchorPoint = Vector2.new(0.5, 0.5),
	}, gui)
	if worldPos then
		local cam = workspace.CurrentCamera
		local v, on = cam:WorldToViewportPoint(worldPos + Vector3.new(0, 2, 0))
		if on then
			label.Position = UDim2.fromOffset(v.X, v.Y)
		else
			label.Position = UDim2.new(0.5, 0, 0.42, 0)
		end
	else
		label.Position = UDim2.new(0.5, 0, 0.38, 0)
	end
	TweenService:Create(label, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = label.Position + UDim2.fromOffset(0, -48),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(label, 0.9)
end

UIS.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		-- input.Position is in the same inset-adjusted space as the GUI; the raw
		-- mouse location is not, and a touch has no mouse location at all.
		local loc = input.Position
		for _, obj in ipairs(player.PlayerGui:GetGuiObjectsAtPosition(loc.X, loc.Y)) do
			-- Only OUR buttons block a dig. Roblox's touch controls live in their
			-- own ScreenGui, and the default dynamic thumbstick covers the whole
			-- screen with a button -- counting that rejected every touch there was.
			if not obj:IsDescendantOf(player.PlayerGui) or obj:FindFirstAncestorOfClass("ScreenGui") ~= gui then
				continue
			end
			if obj:IsA("GuiButton") or obj:FindFirstAncestorWhichIsA("GuiButton") then
				return
			end
			if obj:IsDescendantOf(gui) and obj:IsA("GuiObject") and obj.Active then
				return
			end
		end
		digging = true
		hold = 0
		ClientFns.digTouch = (input.UserInputType == Enum.UserInputType.Touch) and input or nil
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		-- On a touch screen only the finger that started the dig ends it: a
		-- thumb coming off the move stick or the jump button is another touch.
		local held = ClientFns.digTouch
		if input.UserInputType == Enum.UserInputType.Touch and held and input ~= held then
			return
		end
		digging = false
		hold = 0
		ClientFns.digTouch = nil
		swingFill.Size = UDim2.fromScale(0, 1)
	end
end)

RunService.Heartbeat:Connect(function(dt)
	-- The bar lives and dies with the hold: letting go unwinds the drill, so
	-- the bar must not sit there pretending otherwise.
	if spinBar.Visible then
		local left = spinUntil - os.clock()
		if left <= 0 or not digging then
			spinBar.Visible = false
		else
			spinFill.Size = UDim2.fromScale(math.clamp(1 - left / spinFor, 0, 1), 1)
		end
	end
	do
		local free = not hudCovered
		local d = free and depthHud.depthOf() or 0
		local inPit = free and depthHud.inPit()
		local under = inPit and d > 0
		depthHud.chip.Visible = under
		do
			local now = os.clock()
			if (ClientFns.mineGuideAt or 0) + 0.4 <= now then
				ClientFns.mineGuideAt = now
				local wp = ClientFns.waypointId
				local tutorial = wp ~= nil and wp ~= "mine"
				if not tutorial then
					if inPit then
						if wp == "mine" then
							ClientFns.setWaypoint(nil)
						end
					elseif wp ~= "mine" then
						ClientFns.setWaypoint("mine")
					end
				end
			end
		end
		-- Next rebirth, always on. rebirthMinCoins is the bank the next one
		-- needs; the panel's ladder shows the four after it.
		do
			local want = tonumber(snap and snap.rebirthMinCoins) or 0
			local have = tonumber(snap and snap.coins) or 0
			if free and want > 0 then
				local f = math.clamp(have / want, 0, 1)
				depthHud.rb.Visible = true
				depthHud.rbLabel.Text = "REBIRTH " .. tostring((tonumber(snap.rebirth) or 0) + 1)
				depthHud.rbFill.Size = UDim2.fromScale(f, 1)
				depthHud.rbFill.BackgroundColor3 = (f >= 1)
					and Color3.fromRGB(110, 210, 120) or GOLD
				depthHud.rbPct.Text = (f >= 1) and "READY" or (math.floor(f * 100) .. "%")
				depthHud.rbPct.TextColor3 = (f >= 1)
					and Color3.fromRGB(150, 230, 150) or MUTED
				-- READY throbs, the same as every other thing that pays out now.
				local ready = f >= 1
				if ClientFns.UI and ready ~= (depthHud.rbReady == true) then
					depthHud.rbReady = ready
					if depthHud.rbPulseStop then
						depthHud.rbPulseStop()
						depthHud.rbPulseStop = nil
					end
					if ready then
						ClientFns.UI.pop(depthHud.rb, 1.15)
						depthHud.rbPulseStop = ClientFns.UI.pulse(depthHud.rb, 1.05, 1)
					end
				end
			else
				depthHud.rb.Visible = false
			end
		end
		if under then
			depthHud.label.Text = d .. "m down"
		end
		-- A haul outranks depth: if the bag has something in it, the next thing
		-- you want is to cash it, wherever you are standing.
		local load = (snap and snap.load) or 0
		if free and load > 0 then
			depthHud.mode = "sell"
			depthHud.button.Text = ((snap and snap.vip) and "SELL HERE  " or "SELL  ") .. shortNum(load)
			depthHud.button.BackgroundColor3 = Color3.fromRGB(96, 196, 128)
			depthHud.button.Visible = true
		elseif inPit then
			depthHud.mode = "surface"
			depthHud.button.Text = "TO SURFACE"
			depthHud.button.BackgroundColor3 = GOLD
			depthHud.button.Visible = true
		else
			depthHud.button.Visible = false
		end
	end
	if mineResetLeft ~= nil and mineResetL then
		mineResetLeft = math.max(0, mineResetLeft - dt)
		mineResetL.Text = fmtReset(mineResetLeft)
	end
	local target = ClientFns.aimedBlock()
	aimed = target
	if target and target.Parent then
		hover.Adornee = target
		hover.Enabled = true
		local kind = target:GetAttribute("Kind") or "dirt"
		local spec = C.BLOCKS[kind]
		local scaled = C.blockHp(kind, target:GetAttribute("ZoneId"), target:GetAttribute("CY") or 1)
		local hp, maxHp
		if target:GetAttribute("Matter") == "space" then
			maxHp = target:GetAttribute("SpaceMax") or target:GetAttribute("MaxHP") or scaled
			hp = target:GetAttribute("SpaceHP") or maxHp
		else
			hp = target:GetAttribute("HP") or scaled
			maxHp = target:GetAttribute("MaxHP") or scaled
		end
		local blockName = target:GetAttribute("BlockName") or (spec and spec.name) or "Block"
		local section = target:GetAttribute("SectionName")
		local layer = target:GetAttribute("CY")
		--[[
			An ore block carries a SectionName like every other block, so it used to
			fall into the section branch below and the card read "Clayfall | L312" --
			the one thing it could not tell you was which ore you were
			standing in front of. Ore is checked FIRST for that reason; the section
			is still on screen in the depth HUD, the ore's identity was nowhere.
		]]
		local oreName = target:GetAttribute("OreName")
		if kind == "ore" and oreName then
			local oreTier = tonumber(target:GetAttribute("OreTier"))
			hoverName.Text = oreTier
				and string.format("%s  |  tier %d", tostring(oreName), oreTier)
				or tostring(oreName)
		elseif section and target:GetAttribute("Kind") ~= "chest" then
			hoverName.Text = string.format("%s  |  L%d", section, layer or 1)
		elseif target:GetAttribute("Kind") == "chest" then
			local flavour = section and ("  |  " .. section) or ""
			hoverName.Text = blockName .. flavour
		else
			hoverName.Text = blockName
		end
		local packLine = ""
		if target:GetAttribute("Kind") == "chest" and Packs and Packs.CHEST_BY_ID then
			local def = Packs.CHEST_BY_ID[target:GetAttribute("ChestType")]
			if def and def.packs and #def.packs > 0 then
				local bits = {}
				for _, row in ipairs(def.packs) do
					local pname = (Packs.PACK_BY_ID[row.packId] and Packs.PACK_BY_ID[row.packId].name) or row.packId
					table.insert(bits, string.format("%s %.0f%%", pname, row.chance or 0))
				end
				packLine = "  |  " .. table.concat(bits, ", ")
			end
		end
		hoverHp.Text = string.format("HP  %d / %d%s", math.max(0, hp), maxHp, packLine)
		hpFill.Size = UDim2.fromScale(math.clamp(hp / math.max(1, maxHp), 0, 1), 1)
	else
		hover.Enabled = false
		hover.Adornee = nil
		swingFill.Size = UDim2.fromScale(0, 1)
	end
	if not digging then
		return
	end
	local tlNow = snap and snap.tool
	local isCharge = tlNow and tlNow.cooldown
	if not target and not isCharge then
		hold = 0
		return
	end
	if target and not isCharge then
		ClientFns.faceTarget(target, dt)
	end
	-- The bar is this tool's cadence, not a global constant. A 4.0/s drill and a
	-- 4.2s Cataclysm Charge are the same bar filling at wildly different speeds,
	-- which is the point: it tells you when you can act again.
	local tl = snap and snap.tool
	-- swingSec is a duration multiplier: 0.8 means each swing takes 80% as long.
	local swingSec = (snap and snap.boosts and snap.boosts.swingSec) or 1
	local need
	if tl and tl.cooldown then
		-- Short Fuse shortens the throw on the server (MineServer throwAt); pace
		-- the bar the same way, with a hair of slack so a jittery frame never
		-- throws a beat early and has the server drop it.
		local fuse = 1 + math.max(0, tonumber(snap and snap.boosts and snap.boosts.shortFuse) or 0)
		need = (tl.cooldown / fuse) * 1.03
	else
		need = (1 / math.max(0.05, (tl and tl.rate) or 2.5)) * swingSec
	end
	hold += dt
	swingFill.Size = UDim2.fromScale(math.clamp(hold / need, 0, 1), 1)
	if hold >= need then
		hold = 0
		if isCharge then
			-- A DIRECTION, not a destination. Where you point is the way you
			-- want it to go; where it ends up is up to the throw.
			local cam = workspace.CurrentCamera
			local ray = cam and ClientFns.pointerRay(cam)
			if ray then
				local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				Audio.play("explosive", 1, nil, hrp and hrp.Position)
				net:FireServer("throwAt", ray.Direction.Unit)
			end
		else
			ClientFns.swingFx(target, need)
			net:FireServer("swing", target)
		end
	end
end)

--[[
	Trading is OFF for launch. What used to live here opened a trade window on
	any left click that happened to land on another player -- the same click you
	mine with -- listed every card you own as a one-click "Offer", and sent the
	offer to the server the instant you touched a row. There was no confirmation
	and no two-sided view.

	The server half was worse: tradeAccept took the partner's id straight from
	the caller and only checked that BOTH players had an offer on file, never
	that the two offers pointed at each other. Anyone could park an empty offer,
	wait for a victim to make one with somebody else, and accept it themselves.

	Turning this back on needs a real handshake: a request the other player has
	to accept, both sides' offers shown side by side, both sides pressing ready,
	a lock-and-confirm step, and a server check that A's offer names B and B's
	names A. Until that exists the verbs are dead on the server too.
]]
local TRADING_ENABLED = false
if TRADING_ENABLED then
	-- (intentionally unreachable until the handshake above is built)
end

--[[
	"Open all" is gone.

	It walked the whole bag worst-pack-first, one server round trip per pack,
	and waited out each ceremony before asking for the next. Two things
	replaced it: the tiles now offer 1 / 10 / the whole stack for ONE kind of
	pack, and openMany does the run in a single request -- so the reveal never
	has to wait on the network between packs.
]]

--[[
	One route for every window the game can point at. The tutorial, the
	proximity prompts and the merge nudge all say "open X"; this is the one
	place that knows what X is and how to fill it before it shows.
]]
function ClientFns.pulsePanel(f)
	if not f then
		return
	end
	task.spawn(function()
		local s = Instance.new("UIStroke")
		s.Color = GOLD
		s.Thickness = 3
		s.Transparency = 0
		s.Parent = f
		for _ = 1, 3 do
			local tw = TweenService:Create(s, TweenInfo.new(0.55), { Transparency = 1 })
			tw:Play()
			tw.Completed:Wait()
			s.Transparency = 0
		end
		s:Destroy()
	end)
end

function ClientFns.pulseQuestClaim()
	-- Intro wants the CLAIM button seen; open the quest panel first.
	if ClientFns.questDrawerOpen == false then
		ClientFns.questDrawerPreferred = true
		pcall(ClientFns.syncQuestDrawer)
	end
	task.spawn(function()
		for _ = 1, 8 do
			if questClaim.Visible and ClientFns.UI then
				-- The candy claim colours itself with a gradient, so a colour
				-- flash would stain it. Pop it instead.
				ClientFns.UI.pop(questClaim, 1.15)
				task.wait(0.8)
			elseif questClaim.Visible then
				local tw = TweenService:Create(questClaim, TweenInfo.new(0.4), { BackgroundColor3 = Color3.fromRGB(255, 240, 170) })
				tw:Play()
				tw.Completed:Wait()
				local back = TweenService:Create(questClaim, TweenInfo.new(0.4), { BackgroundColor3 = GOLD })
				back:Play()
				back.Completed:Wait()
			else
				task.wait(0.8)
			end
		end
	end)
end

function ClientFns.routePanel(name, tab)
	name = tostring(name or "")
	if name == "depth_shop" then
		if depthShopCtl then
			hidePanels()
			depthShopCtl.open(type(tab) == "table" and tab or nil)
			ClientFns.pulsePanel(depthShopCtl.root)
		end
		return
	end
	if name == "inventory" then
		if invCtl then
			hidePanels()
			if snap then
				invCtl.setState(snap)
			end
			invCtl.open("inventory", tab or "tools")
			ClientFns.pulsePanel(invCtl.root)
		end
		return
	end
	if name == "merge" then
		-- The separate Merge screen is retired: merging lives on the card
		-- tiles, so anything that asks for "merge" lands on the cards tab.
		if invCtl then
			hidePanels()
			if snap then
				invCtl.setState(snap)
			end
			invCtl.open("inventory", "cards")
			ClientFns.pulsePanel(invCtl.root)
		end
		return
	end
	if name == "dust" then
		if ClientFns.teleportToEnchanter then ClientFns.teleportToEnchanter() end
		name, tab = "enchanter", "scrap"
	end
	if name == "summon" then
		name, tab = "enchanter", "summon"
	elseif name == "jobs" then
		name = "contractor"
	elseif name == "rebirth" then
		name = "prestige"
	end
	local map = {
		shop = { shopCtl and shopCtl.root or nil, function()
			if shopCtl then
				if snap then shopCtl.setState(snap) end
				shopCtl.open()
			end
		end },
		merge = { mergeP, refreshMerge },
		dust = { dustP, refreshDust },
		zones = { zoneP, refreshZones },
		prestige = { presP, refreshPrestige },
		events = { eventsCtl and eventsCtl.root or nil, function()
			if eventsCtl then
				if snap then
					eventsCtl.setState(snap)
				end
				eventsCtl.open()
			end
		end },
		skills = { skillP, function()
			if applySkills then
				applySkills(false)
			end
		end },
		enchanter = { enchantP, refreshEnchanter },
		contractor = { depthHud.contractor and depthHud.contractor.root or nil, function()
			if depthHud.contractor then
				if snap then
					depthHud.contractor.setState(snap)
				end
				depthHud.contractor.open()
			end
		end },
	}
	local entry = map[name]
	if entry and entry[1] then
		hidePanels()
		entry[1].Visible = true
		if entry[2] then
			entry[2]()
		end
		if name == "enchanter" and tab then
			ClientFns.showEnchantTab(tab)
		end
		ClientFns.pulsePanel(entry[1])
	end
end

function ClientFns.noteDiscoveries(payload)
	if type(payload) ~= "table" then
		return
	end
	local z = math.floor(tonumber(payload.maxUnlockedZone) or 1)
	local deep = payload.deepest
	if ClientFns._discZone == nil then
		ClientFns._discZone = z
		ClientFns._discDeep = (type(deep) == "table") and deep or {}
		ClientFns._discBang = payload.bigbangOwned and true or false
		return
	end
	local lines = {}
	if z > ClientFns._discZone then
		local ok, Cfg = pcall(function()
			return require(game.ReplicatedStorage.Mine.Shared:WaitForChild("MineConfig"))
		end)
		local zone = ok and Cfg and Cfg.ZONES and Cfg.ZONES[z]
		lines[#lines + 1] = "You Discovered Planet " .. ((zone and zone.name) or "Unknown") .. "!"
	end
	ClientFns._discZone = z
	if payload.bigbangOwned and not ClientFns._discBang then
		lines[#lines + 1] = "You Discovered Planet Event Horizon!"
	end
	ClientFns._discBang = payload.bigbangOwned and true or false
	if type(deep) == "table" then
		ClientFns._discDeep = ClientFns._discDeep or {}
		for zoneId, n in pairs(deep) do
			local now = math.floor(tonumber(n) or 0)
			local was = math.floor(tonumber(ClientFns._discDeep[zoneId]) or 0)
			for _, seam in ipairs({ 500, 1000, 1500, 2000 }) do
				if was < seam and now >= seam then
					lines[#lines + 1] = "You Discovered The " .. tostring(seam) .. " Depth Outpost!"
				end
			end
			ClientFns._discDeep[zoneId] = now
		end
	end
	if #lines > 0 then
		ClientFns.showDiscovery(table.concat(lines, "\n"))
	end
end

function ClientFns.showDiscovery(text)
	local who = game.Players.LocalPlayer
	local pg = who and who:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return
	end
	local gui = pg:FindFirstChild("DiscoveryBanner")
	if gui then
		gui:Destroy()
	end
	gui = Instance.new("ScreenGui")
	gui.Name = "DiscoveryBanner"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 95
	gui.Parent = pg

	local dim = Instance.new("Frame")
	dim.Name = "Dim"
	dim.BackgroundColor3 = Color3.fromRGB(8, 6, 4)
	dim.BackgroundTransparency = 0.55
	dim.BorderSizePixel = 0
	dim.Size = UDim2.fromScale(1, 1)
	dim.Parent = gui

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.4)
	card.Size = UDim2.new(0.72, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = Color3.fromRGB(42, 30, 20)
	card.BorderSizePixel = 0
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 200, 90)
	stroke.Thickness = 2.5
	stroke.Transparency = 0.15
	stroke.Parent = card
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 22)
	pad.PaddingBottom = UDim.new(0, 22)
	pad.PaddingLeft = UDim.new(0, 28)
	pad.PaddingRight = UDim.new(0, 28)
	pad.Parent = card
	local lay = Instance.new("UIListLayout")
	lay.FillDirection = Enum.FillDirection.Vertical
	lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lay.Padding = UDim.new(0, 8)
	lay.Parent = card

	local eyebrow = Instance.new("TextLabel")
	eyebrow.BackgroundTransparency = 1
	eyebrow.Size = UDim2.new(1, 0, 0, 22)
	eyebrow.Font = Enum.Font.GothamBold
	eyebrow.TextSize = 16
	eyebrow.TextColor3 = Color3.fromRGB(255, 210, 120)
	eyebrow.Text = "✧  OUTPOST DISCOVERED  ✧"
	eyebrow.Parent = card

	local lbl = Instance.new("TextLabel")
	lbl.Name = "Line"
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, 0, 0, 72)
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.TextWrapped = true
	lbl.TextColor3 = Color3.fromRGB(255, 244, 210)
	lbl.TextStrokeColor3 = Color3.fromRGB(20, 12, 8)
	lbl.TextStrokeTransparency = 0.4
	lbl.Text = tostring(text or "")
	lbl.Parent = card

	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Size = UDim2.new(1, 0, 0, 20)
	sub.Font = Enum.Font.GothamMedium
	sub.TextSize = 15
	sub.TextColor3 = Color3.fromRGB(210, 190, 160)
	sub.Text = "Shop | Sell | Mineshaft ready"
	sub.Parent = card

	card.Size = UDim2.new(0.2, 0, 0, 0)
	card.BackgroundTransparency = 1
	lbl.TextTransparency = 1
	eyebrow.TextTransparency = 1
	sub.TextTransparency = 1
	stroke.Transparency = 1
	local TweenService = game:GetService("TweenService")
	TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.72, 0, 0, 0),
		BackgroundTransparency = 0.05,
	}):Play()
	TweenService:Create(stroke, TweenInfo.new(0.35), { Transparency = 0.15 }):Play()
	TweenService:Create(lbl, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	TweenService:Create(eyebrow, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	TweenService:Create(sub, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()

	local token = (gui:GetAttribute("Tok") or 0) + 1
	gui:SetAttribute("Tok", token)
	task.delay(4.6, function()
		if not (gui.Parent and gui:GetAttribute("Tok") == token) then
			return
		end
		TweenService:Create(card, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(dim, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(lbl, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
		TweenService:Create(eyebrow, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
		TweenService:Create(sub, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.35), { Transparency = 1 }):Play()
		task.delay(0.45, function()
			if gui.Parent and gui:GetAttribute("Tok") == token then
				gui:Destroy()
			end
		end)
	end)
end

--[[
	A word on everybody's screen.

	Server-wide announcements had nowhere to land -- `toast` is a small corner
	chip that scrolls away, which is wrong for "server restarting in 2 minutes".
	This is a full-width band across the top third: unmissable, readable at a
	glance, and it leaves on its own so nobody has to dismiss it.
]]
function ClientFns.showBroadcast(payload)
	local text = (type(payload) == "table") and tostring(payload.text or "") or tostring(payload or "")
	if text == "" then
		return
	end
	local secs = (type(payload) == "table" and tonumber(payload.secs)) or 8
	local old = player.PlayerGui:FindFirstChild("MineBroadcast")
	if old then
		old:Destroy()
	end
	local bg = Instance.new("ScreenGui")
	bg.Name = "MineBroadcast"
	bg.ResetOnSpawn = false
	bg.IgnoreGuiInset = true
	bg.DisplayOrder = 200
	bg.Parent = player.PlayerGui
	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.new(0.5, 0, 0.06, 0)
	card.Size = UDim2.new(0.86, 0, 0, 84)
	card.BackgroundColor3 = Color3.fromRGB(16, 14, 22)
	card.BackgroundTransparency = 0.08
	card.BorderSizePixel = 0
	card.Parent = bg
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 14)
	cc.Parent = card
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(255, 214, 92)
	st.Thickness = 3
	st.Parent = card
	local cap = Instance.new("TextLabel")
	cap.BackgroundTransparency = 1
	cap.Position = UDim2.fromOffset(16, 8)
	cap.Size = UDim2.new(1, -32, 0, 16)
	cap.Font = Enum.Font.GothamBlack
	cap.TextSize = 13
	cap.TextColor3 = Color3.fromRGB(255, 214, 92)
	cap.TextXAlignment = Enum.TextXAlignment.Left
	cap.Text = tostring((type(payload) == "table" and payload.title) or "ANNOUNCEMENT")
	cap.Parent = card
	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(16, 26)
	body.Size = UDim2.new(1, -32, 0, 50)
	body.Font = Enum.Font.GothamBold
	body.TextColor3 = Color3.fromRGB(245, 245, 250)
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.Text = text
	body.Parent = card
	local con = Instance.new("UITextSizeConstraint")
	con.MinTextSize = 12
	con.MaxTextSize = 22
	con.Parent = body
	body.TextScaled = true
	task.delay(math.clamp(secs, 2, 60), function()
		if bg and bg.Parent then
			bg:Destroy()
		end
	end)
end


net.OnClientEvent:Connect(function(action, payload, extra)
	if action == "snapshot" then
		if ClientFns.noteDiscoveries then
			ClientFns.noteDiscoveries(payload)
		end
		if ClientFns.noteDepthFromSnapshot then
			ClientFns.noteDepthFromSnapshot(payload)
		end
		-- PERF: dig markDirty -> ~10 snapshots/sec. Do not rebuild pets/panels every time.
		snap = payload
		if not ClientFns.settingsLocalAt or os.clock() - ClientFns.settingsLocalAt > 2 then
			ClientFns.applySettings(payload and payload.settings)
		end
		if payload and payload.starterBought and ClientFns.starterCtl then
			ClientFns.starterCtl.close()
		end
		if not ClientFns.othersPetsOn then
			ClientFns.othersPets()
		end
		-- The hotbar is cheap to repaint -- eight slots, no layout -- so it can
		-- ride the snapshot directly rather than needing its own dirty flag.
		if ClientFns.hotbarCtl and ClientFns.hotbarCtl.refresh then
			pcall(ClientFns.hotbarCtl.refresh)
		end
		ClientFns.syncPlaytime(payload)
		pcall(ClientFns.paintDailyBox, payload and payload.dailyQuests)
		pcall(ClientFns.upgradeNudge)
		if not ClientFns.chestBeaconsOn then
			ClientFns.chestBeacons()
		end
		if not ClientFns.giftsLoopOn then
			ClientFns.giftsLoop()
		end
		if ClientFns.tradeCtl and ClientFns.tradeCtl.isOpen() then
			ClientFns.tradeCtl.refreshBag()
		end
		if payload and payload.worldEvent then
			require(shared.MineWorldPulseUI).apply(payload.worldEvent)
			require(shared.MineWorldPulseUI).refresh()
		end
		refreshHud()
		if portalFx and portalFx.refresh then portalFx.refresh() end
		-- Always stash snapshot on inv/shop controllers. setState only re-renders
		-- when visible, so this is cheap - and without it Inventory > Cards
		-- opens empty (no pets) until something else dirties the profile.
		if shopCtl then shopCtl.setState(payload) end
		if depthShopCtl and depthShopCtl.root and depthShopCtl.root.Visible then
			depthShopCtl.setState({
				coins = payload.coins,
				spaceCoins = payload.spaceCoins,
				deepest = payload.deepest,
				tools = nil,
			})
		end
		if forgeCtl then forgeCtl.setState(payload) end
		if invCtl then invCtl.setState(payload) end
		if eventsCtl then eventsCtl.setState(payload) end
		if depthHud.contractor then depthHud.contractor.setState(payload) end
		do
			local mergeReady = 0
			if payload and payload.cards then
				local groups = {}
				for _, card in ipairs(payload.cards) do
					local key = tostring(card.cardKey) .. "|" .. tostring(card.rarityId) .. "|" .. tostring(card.variant or "Normal")
					groups[key] = (groups[key] or 0) + 1
				end
				for _, n in pairs(groups) do
					if n >= 3 then mergeReady += 1 end
				end
			end
			require(shared:WaitForChild("MineNotifs")).apply(payload, {
				dock = dock,
				mergeReady = mergeReady,
				setRail = function(c)
					if invCtl and invCtl.setRailNotifs then
						invCtl.setRailNotifs(c)
					end
				end,
			})
			-- Keep the daily wheel panel current (spins left, countdown).
			if groupWheelCtl and type(payload.groupWheel) == "table" then
				groupWheelCtl.setPayload(payload.groupWheel)
			end
		end
		if payload then
			-- Always cache; only redraw if the wheel is actually on screen.
			skillLatest = {
				state = {
					levels = (payload.skills and payload.skills.levels) or {},
					tokens = (payload.skills and payload.skills.tokens) or 0,
					refund = (payload.skills and payload.skills.refund) or 0,
					rebirth = payload.rebirth or 0,
					preset = payload.skillSlot or 1,
				},
				inClouds = payload.inClouds == true,
				boughtSecond = payload.boughtSecond,
				temperTokens = payload.temperTokens or 0,
				skillBurned = payload.skillBurned or 0,
				sacrificeRate = payload.sacrificeRate,
				buybackCost = payload.buybackCost,
			}
			if skillCtl and skillP and skillP.Visible then
				skillCtl.setOpts(skillLatest)
			end
		end
		if binderP and binderP.Visible then refreshBinder() end
		if bagP and bagP.Visible then refreshBag() end
		if shopP and shopP.Visible then refreshShop() end
		if mergeP and mergeP.Visible then refreshMerge() end
		if dustP and dustP.Visible then refreshDust() end
		if zoneP and zoneP.Visible then refreshZones() end
		if presP and presP.Visible then refreshPrestige() end
		if runesCtl then
			runesCtl.setState(payload)
			-- The trait tab never repainted while the rune bench existed, so a
			-- roll (gems, the tool's new prefix) stayed stale until reopened.
			-- Rolls are rare, so repaint only when gems or the rack change.
			if traitCtl and enchantP and enchantP.Visible then
				local key = tostring(payload.gems) .. ":" .. tostring(payload.oreTools and #payload.oreTools)
				if key ~= ClientFns.traitPaintKey then
					ClientFns.traitPaintKey = key
					pcall(traitCtl.paint)
				end
			end
		elseif enchantP and enchantP.Visible and refreshEnchanter then
			refreshEnchanter()
		end
		local eq = payload.equipped or {}
		--[[
			Only the equipped list rides this key now. Pet hats used to ride it
			too, because putting one on a pet had to redress the pet standing in
			the world without the equipped list moving. Pets wear nothing, so the
			roster is the whole of what changes their appearance.
		]]
		local key = table.concat(eq, ",")
		if key ~= lastPetEquipKey then
			lastPetEquipKey = key
			ClientFns.updatePets()
		end
	elseif action == "throw" then
		-- This rig is constraint-based: it has BallSocketConstraints and
		-- AnimationConstraints and NOT A SINGLE Motor6D, so the joint-driving
		-- version moved nothing at all. Play the character's own tool-lunge
		-- track instead -- it ships with every rig and needs no upload.
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum:FindFirstChildOfClass("Animator")
		local animate = char and char:FindFirstChild("Animate")
		-- toolslash, not toollunge: lunge is a whole-body animation that steps the
		-- character back into the splits. Slash is the arm alone.
		local src = animate and animate:FindFirstChild("toolslash")
		local asset = src and src:FindFirstChildOfClass("Animation")
		if animator and asset then
			local a = Instance.new("Animation")
			a.AnimationId = asset.AnimationId
			local track = animator:LoadAnimation(a)
			track.Priority = Enum.AnimationPriority.Action
			-- Blended in at low weight: a nudge of the arm, not a full lunge.
			-- At weight 1 the whole body threw itself forward for what should
			-- read as a flick.
			track:Play(0.06, 0.8, 1)
			track:AdjustSpeed(1.7)
			task.delay(0.3, function()
				track:Stop(0.18)
				track:Destroy()
				a:Destroy()
			end)
		end
		if joint then
			local NAME = "MineThrow"
			pcall(function() RunService:UnbindFromRenderStep(NAME) end)
			local t0 = os.clock()
			RunService:BindToRenderStep(NAME, Enum.RenderPriority.Character.Value + 1, function()
				local u = (os.clock() - t0) / 0.34
				if u >= 1 or not joint.Parent then
					pcall(function() RunService:UnbindFromRenderStep(NAME) end)
					return
				end
				-- Wind up and release in one pass: sin peaks at the halfway
				-- point, so the arm goes back then snaps forward.
				joint.Transform = joint.Transform
					* CFrame.Angles(math.rad(-135 * math.sin(u * math.pi)), 0, 0)
			end)
		end
	elseif action == "haul" then
		-- no coin popup on block break
	elseif action == "sold" and payload then
		ClientFns.haulPopup(payload.coins or 0, payload.gems or 0, payload.space)
		if payload.haste then
			showToast("+8% mine speed for " .. tostring(payload.haste) .. "s")
		end
	elseif action == "bagFull" then
		ClientFns.bagFullMenu()
	elseif action == "chestOpened" and payload then
		local pos = payload.pos
		if (payload.coins or 0) > 0 then
			floatText("+" .. shortNum(payload.coins), COIN_POP, pos)
		end
		if (payload.gems or 0) > 0 then
			floatText("+" .. shortNum(payload.gems), GEM_POP, pos and (pos + Vector3.new(0, 1.1, 0)) or nil)
		end
		ClientFns.chestPopup(payload)
	elseif action == "mineReset" and payload then
		mineResetLeft = payload.remaining
		mineResetSec = payload.resetSec or mineResetSec
		if mineResetL then
			mineResetL.Text = fmtReset(mineResetLeft)
		end
	elseif action == "depthLive" then
		if ClientFns.noteDepthLive then
			ClientFns.noteDepthLive(payload)
		end
	elseif action == "seamGate" then
		ClientFns.confirmSeam(payload)
	elseif action == "traderShop" and payload then
		ClientFns.showTraderShop(payload)
	elseif action == "tooWeak" then
		--[[
			The breaking-power refusal. There were briefly two of these, from
			parallel work: a "weakTool" message handled inline here, and this one.
			ClientFns.tooWeak won because it says what you NEED against what you
			HAVE and names the ore, and because its server-side gate goes through
			Dig.Breaking.canBreak, which weighs block strength as well as ore
			tier. The inline branch and its server gate are both gone.
		]]
		ClientFns.tooWeak(payload)
	elseif action == "toast" then
		showToast(tostring(payload))
	elseif action == "openElevator" then
		if elevCtl and elevCtl.open then
			elevCtl.open(payload)
		end
	elseif action == "promptProduct" then
		local pid = tonumber(payload) or 0
		if pid > 0 then
			MarketplaceService:PromptProductPurchase(player, pid)
		else
			showToast("Product not configured yet")
		end
	elseif action == "afk" then
		if ClientFns.onAfkState then
			ClientFns.onAfkState(payload)
		end
	elseif action == "afkMine" then
		if ClientFns.onAfkMine then
			ClientFns.onAfkMine(payload)
		end
	elseif action == "worldEvent" then
		require(shared.MineWorldPulseUI).apply(payload)
		require(shared.MineWorldPulseUI).refresh()
	elseif action == "tutorialCelebrate" then
		if ClientFns.fireworks then
			ClientFns.fireworks()
		end
	elseif action == "intro" and payload then
		-- The server owns the step; the client draws it. Step 1 is walk-to-mine.
		-- After the tutorial, the MINE waypoint stays on for anyone on the lawn.
		if tonumber(payload.step) == 1 and not payload.done then
			ClientFns.setWaypoint("mine")
		elseif payload.waypoint and not payload.done then
			ClientFns.setWaypoint(payload.waypoint)
		elseif payload.done then
			ClientFns.setWaypoint("mine")
		else
			ClientFns.setWaypoint(nil)
			ClientFns.clearPitTrail()
		end
		if payload.done or not payload.text then
			introBanner.Visible = false
			introClick.Active = false
			introAckHint.Text = ""
			ClientFns.introRequire = nil
			if ClientFns.handClear then
				ClientFns.handClear()
			end
		else
			local text = tostring(payload.text)
			introL.Text = text
			introBanner.Visible = true
			local maxW = ClientFns.introPlace()
			local measured = TextService:GetTextSize(
				text, introL.TextSize, introL.Font, Vector2.new(maxW - 76, 400)
			)
			local h = math.clamp(measured.Y + 22, 46, 120)
			local w = math.clamp(measured.X + 76, 360, maxW)
			local stepOf = (tonumber(payload.pos) and tonumber(payload.total))
				and string.format("STEP %d/%d", payload.pos, payload.total) or ""
			if payload.ack then
				h = math.max(h, 64)
				local claim = (type(payload.claimLabel) == "string" and payload.claimLabel ~= "")
					and payload.claimLabel or "tap to continue"
				introAckHint.Text = claim .. (stepOf ~= "" and ("  |  " .. stepOf) or "")
				introClick.Active = true
			else
				h = math.max(h, 58)
				introAckHint.Text = stepOf
				introClick.Active = false
			end
			if type(payload.barLabel) == "string" and payload.barLabel ~= "" then
				introBarBack.Visible = true
				introBarFill.Size = UDim2.fromScale(math.clamp(tonumber(payload.progress) or 0, 0, 1), 1)
				introAckHint.Text = payload.barLabel
				h += 14
			else
				introBarBack.Visible = false
			end
			introBanner.Size = UDim2.fromOffset(w, h)
			ClientFns.introPlace(w)
			ClientFns.introPulse()
			--[[
				Force the step's own window open, once per step-change in this
				session, so the lesson is the thing on screen rather than a
				sentence about it. The FIRST payload after joining only records
				the step -- popping a panel over a returning player's spawn is
				noise, not teaching.
			]]
			local step = tonumber(payload.step) or 0
			if ClientFns.introStepSeen == nil then
				ClientFns.introStepSeen = step
			elseif step ~= ClientFns.introStepSeen then
				ClientFns.introStepSeen = step
				if payload.panel then
					ClientFns.routePanel(payload.panel, payload.tab)
				end
				if payload.highlight == "questClaim" then
					ClientFns.pulseQuestClaim()
				elseif payload.highlight == "gifts" then
					ClientFns.pulseGifts()
				elseif payload.highlight == "daily" and snap and snap.daily then
					dailyHud.dismissed = false
					dailyHud.show(snap.daily)
				elseif payload.highlight and ClientFns.handTargets[payload.highlight] then
					-- The hand: point at the exact thing this step wants tapped.
					-- Deferred, because the panel it lives in is opening on this
					-- same frame and has not drawn its children yet.
					task.delay(0.35, function()
						if ClientFns.introStepSeen == step then
							ClientFns.handPoint(payload.highlight)
						end
					end)
				else
					ClientFns.handClear()
				end
				if payload.requireAction then
					-- Soft lock (socket step): keep the bench on screen while
					-- the step wants a socket. Bounded -- two re-opens or 45
					-- seconds, whichever runs out first -- so it can never
					-- hold the screen hostage.
					ClientFns.introRequire = {
						expires = os.clock() + 45,
						reopens = 2,
						panel = payload.panel,
						tab = payload.tab,
					}
				else
					ClientFns.introRequire = nil
				end
			end
		end
	elseif action == "mergeReady" and payload then
		-- One-shot from the server: first natural three-of-a-kind. Route the
		-- player at the merge flow and let them decide.
		showToast(tostring(payload.text or "Merge ready - three of a kind."))
		ClientFns.routePanel("merge")
	elseif action == "spin" then
		ClientFns.showSpin(payload)
	elseif action == "hit" and payload then
		if payload.pos and payload.dmg then
			floatText("+" .. tostring(payload.dmg), Color3.fromRGB(190, 190, 195), payload.pos)
		end
		if payload.pos then
			ClientFns.onHit(payload)
		end
	elseif action == "foundTool" and payload then
		-- A rare find plays as a forced pack reveal; see ClientFns.foundReveal.
		ClientFns.foundReveal(payload)
	elseif action == "loot" and payload then
		floatText(payload.text or "+1", payload.color, payload.pos)
		-- Procs (BLAST, TIDAL WAVE, ZAP, RICOCHET, QUAKE) get an animation and a
		-- sound on top of the word: MineProcFx.
		ClientFns.procFx(payload.text, payload.pos)
	elseif action == "openPanel" then
		-- Only live screens are routable; ClientFns.routePanel (above the
		-- dispatcher) is the one map of what exists and how it fills itself.
		ClientFns.routePanel(payload, extra)
	elseif action == "adminBroadcast" then
		ClientFns.showBroadcast(payload)
	elseif action == "openGroupWheel" then
		hidePanels()
		if groupWheelCtl then
			groupWheelCtl.open(payload)
		end
	elseif action == "dailySurpriseOffer" then
		dailySurprise.open()
	elseif action == "dailySurpriseResult" then
		if type(payload) == "table" and payload.ok then
			dailySurprise.status.Text = "Got " .. tostring(payload.name or "pack") .. "!"
			dailySurprise.status.TextColor3 = Color3.fromRGB(120, 255, 160)
			dailySurprise.claimBtn.Text = "CLAIMED"
			task.delay(1.2, dailySurprise.closePanel)
		else
			dailySurprise.claimBtn.Active = true
			dailySurprise.claimBtn.Text = "CLAIM SURPRISE"
		end
	elseif action == "groupWheel" then
		if groupWheelCtl then
			groupWheelCtl.onResult(payload)
		end
	elseif action == "depthShop" then
		if depthShopCtl and type(payload) == "table" then
			hidePanels()
			depthShopCtl.open(payload)
			ClientFns.pulsePanel(depthShopCtl.root)
		end
	elseif action == "opened" then
		-- A single pack, from a chest break or one Open button. Same ceremony
		-- as a ten-pack run -- one pack is just a run of length one.
		local design = (typeof(extra) == "table") and extra or { name = tostring(extra or "Booster Pack") }
		design.cards = payload or {}
		-- Gear / Rune cases use the CSGO reel (not PackReveal / lucky-block).
		if design.kind == "gear" or design.kind == "rune" then
			Audio.play("open")
			local cards = design.cards or {}
			local n = math.min(#cards, 3)
			local function reelAround(item)
				local Temper = require(shared:WaitForChild("MineTemper"))
				local Hats = require(shared:WaitForChild("MineHats"))
				local Gear = require(shared:WaitForChild("MineGear"))
				local Icons = require(shared:WaitForChild("MineIcons"))
				local rng = Random.new()
				local reel, at = {}, Temper.CASE_WINNER_AT or 38
				local winR = item.rarityId or (item.gear and item.gear.rarity) or "Common"
				local hatPool = Hats.LIST or {}
				local function hatRow(h, rarity, name)
					local cat = h and tonumber(h.catalogId)
					return {
						id = (h and h.id) or "?",
						rarity = rarity,
						name = name or (h and h.name) or "...",
						kind = design.kind,
						catalogId = cat,
						icon = cat and string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", cat)
						or (Icons.image and Icons.image((h and h.id) or "")) or nil,
					}
				end
				for i = 1, Temper.CASE_REEL or 44 do
					if i == at then
						if design.kind == "gear" then
							local hatId = item.gear and (item.gear.hatId or item.gear.id)
							local hat
							for _, h in ipairs(hatPool) do
								if h.id == hatId then hat = h break end
							end
							local row = hatRow(hat or (item.gear and {
								id = hatId, name = item.name, catalogId = item.gear.catalogId,
							}), winR, item.name)
							if (not row.icon) and item.gear and Gear.image then
								row.icon = Gear.image(item.gear)
							end
							table.insert(reel, row)
						else
							local stat = item.rune and item.rune.stat
							table.insert(reel, {
								id = stat or (item.rune and item.rune.id) or item.name,
								rarity = winR,
								name = item.name,
								kind = design.kind,
								icon = (Icons.image and (Icons.image(stat) or Icons.image(item.name))) or nil,
							})
						end
					else
						local g = Temper.GRADE_ORDER[rng:NextInteger(1, #Temper.GRADE_ORDER)]
						if design.kind == "gear" and #hatPool > 0 then
							local h = hatPool[rng:NextInteger(1, #hatPool)]
							table.insert(reel, hatRow(h, g, h.name))
						else
							local kits = Temper.KITS or Temper.LIST or {}
							local kit = kits[rng:NextInteger(1, math.max(1, #kits))]
							local kid = (type(kit) == "table" and kit.id) or "?"
							local stat = type(kit) == "table" and type(kit.stats) == "table" and kit.stats[1]
							table.insert(reel, {
								id = kid, rarity = g, kind = design.kind,
								name = (type(kit) == "table" and kit.name) or "...",
								icon = Icons.image and (Icons.image(stat) or Icons.image(kid)) or nil,
							})
						end
					end
				end
				return {
					reel = reel, at = at,
					id = (item.gear and item.gear.id) or (item.rune and item.rune.id),
					name = item.name,
					rarity = winR,
					title = design.kind == "gear" and "Gear Case" or "Rune Case",
					kind = design.kind,
					sub = item.sub,
					icon = reel[at] and reel[at].icon,
					catalogId = reel[at] and reel[at].catalogId,
				}
			end
			local i = 1
			local function nextReel()
				if i > n then
					clearPackRevealBusy()
					return
				end
				local payload = reelAround(cards[i])
				i += 1
				ClientFns.caseScreen().play(payload, nextReel)
			end
			nextReel()
			return
		end
		-- How many more of this same pack are sitting in the bag, so the prompt
		-- can offer another without going back to the menu for it.
		-- Prefer the packId stamped on the design; never fall back to counting
		-- every pack (nil == nil would match the wrong stacks in Lua).
		local openedId = design.packId
		local left = 0
		if type(openedId) == "string" and openedId ~= "" then
			for _, pk in ipairs((snap and snap.packs) or {}) do
				if pk.packId == openedId then
					left += 1
				end
			end
		end
		if revealCtl then
			revealCtl.play({ design }, { packId = openedId, left = left, opened = 1 })
		else
			clearPackRevealBusy()
		end
	elseif action == "claimPassResult" then
		if invCtl and invCtl.notePassClaim then
			invCtl.notePassClaim(payload)
		end
	elseif action == "openedRun" then
		-- A whole run in one reply. The server has already removed the packs and
		-- says how many of that kind are left, so the prompt needs no round trip.
		local meta = (typeof(extra) == "table") and extra or {}
		if revealCtl then
			revealCtl.play(payload or {}, meta)
		else
			clearPackRevealBusy()
		end
	elseif action == "luckyBlockOpened" then
		-- Tap-through reveal; the loot is shown at the end of it.
		Audio.play("lucky")
		ClientFns.luckyScreen().opened(payload)
	elseif action == "confirmScrap" and payload then
		--[[
			The server priced a bulk scrap. Hand its figures to the inventory,
			which opens the review screen on them.

			Routed rather than computed here for the same reason Sell All is: a
			review built from a client-side estimate can quote a total the server
			then disagrees with, and the player has already approved it by then.
		]]
		if invCtl and invCtl.showScrapReview then
			pcall(invCtl.showScrapReview, payload)
		end
	elseif action == "confirmSellAll" and payload then
		--[[
			The server priced a Sell All ask. Hand its figures to the pouch panel,
			which opens the confirmation on them.

			Routed rather than handled here so the numbers a player agrees to are
			the server's own. A dialog built from a client-side estimate is a
			dialog that can quote a total the server then disagrees with.
		]]
		if shopCtl and shopCtl.showSellAllConfirm then
			pcall(shopCtl.showSellAllConfirm, payload)
		end
	elseif action == "temperCase" and payload then
		Audio.play("open")
		ClientFns.caseScreen().play(payload)
	elseif action == "traitRolled" and type(payload) == "table" then
		-- The Enchanter's trait roll: celebrated by the trait's real grade, so
		-- an SSS (1 in 1000) is a party and an F is a soft pop.
		pcall(function()
			local Celebrate = require(shared:WaitForChild("MineCelebrate"))
			local tier = Celebrate.fromGrade(payload.grade)
			Celebrate.burst(tier, { title = tier >= 2 and tostring(payload.label or "") or nil })
		end)
		if traitCtl and enchantP and enchantP.Visible then
			pcall(traitCtl.paint)
		end
	elseif action == "luckResult" and type(payload) == "table" then
		--[[
			Random outcomes that used to be a toast alone: rune fuses (a 50% flip)
			and temperament rolls (the F..SSS ladder). Celebrated by the REAL
			result. A failed fuse gets the small "no" sound, never a fanfare.
		]]
		pcall(function()
			if payload.ok == false then
				Audio.playWin(0)
				return
			end
			local Celebrate = require(shared:WaitForChild("MineCelebrate"))
			local tier
			if payload.grade then
				tier = Celebrate.fromGrade(payload.grade)
			else
				-- A fuse succeeded; each rune tier is one more flip on the last.
				local t = tonumber(payload.runeTier) or 2
				tier = (t >= 7 and 4) or (t >= 5 and 3) or (t >= 3 and 2) or 1
			end
			Celebrate.burst(tier, { title = (tier >= 2) and tostring(payload.title or "") or nil })
		end)
	elseif action == "luckyGraded" then
		ClientFns.luckyScreen().graded(payload)
	elseif action == "luckyGone" then
		ClientFns.luckyScreen().gone(payload)
	elseif action == "cartResult" then
		-- Only the server knows what the cart really cost, so the purchase
		-- sheet is settled from its reply rather than from anything the client
		-- worked out for itself.
		if invCtl and invCtl.cartResult then
			invCtl.cartResult(payload)
		end
		-- Everything that landed flies into the bag.
		if type(payload) == "table" and payload.ok then
			for _, it in ipairs(payload.items or {}) do
				ClientFns.flyToBag({
					kind = (it.kind == "pack") and "pack" or "icon",
					packId = it.id,
					icon = (it.kind == "lucky_block" and it.id) or (it.kind == "box" and "chest")
						or (it.kind == "scroll" and "white") or "pack",
					count = it.qty,
					name = it.name,
				})
			end
		end
	elseif action == "purchaseFx" then
		ClientFns.flyToBag(payload)
	elseif action == "tradeAsk" then
		showToast((payload.name or "Player") .. " wants to trade")
	elseif action == "tradeInvite" then
		ClientFns.tradeView().invite(payload)
	elseif action == "tradeSync" then
		ClientFns.tradeView().sync(payload)
	elseif action == "tradeClosed" then
		ClientFns.tradeView().closed(payload)
	elseif action == "tradeResult" then
		ClientFns.tradeView().result(payload)
	elseif action == "tradePeek" then
		ClientFns.tradeView().peek(payload)
	elseif action == "sysChat" then
		ClientFns.sysChat(payload)
	elseif action == "codeResult" then
		ClientFns.codeResult(payload)
	elseif action == "giftReady" then
		showToast("A free gift is ready! Tap the gift box under your wallet.")
		ClientFns.pulseGifts()
	elseif action == "offerStarter" then
		ClientFns.offerStarter(false)
	elseif action == "leaderboard" and type(payload) == "table" then
		local world = workspace:FindFirstChild("MineWorld")
		local lobby = world and world:FindFirstChild("Lobby")
		local boards = lobby and lobby:FindFirstChild("Leaderboards")
		if boards then
			for _, kind in ipairs({ "prestige", "gems", "dust" }) do
				local info = payload[kind] and payload[kind].you
				local col = boards:FindFirstChild("Col_" .. kind)
				local board = col and col:FindFirstChild("Board")
				local gui = board and board:FindFirstChild("BoardGui")
				local you = gui and gui:FindFirstChild("YouRow")
				if you and you:IsA("TextLabel") then
					local rankNum = info and info.rank
					local val = (info and info.value) or 0
					local rankTxt, rewardKey
					if rankNum then
						rankTxt = "#" .. tostring(rankNum)
						rewardKey = rankNum
					elseif val > 0 then
						rankTxt = "101-1000"
						rewardKey = "101-1000"
					else
						rankTxt = "Unranked"
						rewardKey = 0
					end
					local rewardTxt = "-"
					if rewardKey == "101-1000" then
						rewardTxt = "100 gems"
					elseif type(rewardKey) == "number" and rewardKey > 0 then
						if rewardKey == 1 then rewardTxt = "5,000 gems + Event pack"
						elseif rewardKey == 2 then rewardTxt = "2,500 gems + Legendary pack"
						elseif rewardKey == 3 then rewardTxt = "1,500 gems + Legendary pack"
						elseif rewardKey <= 10 then rewardTxt = "750 gems + Rare pack"
						elseif rewardKey <= 25 then rewardTxt = "400 gems"
						elseif rewardKey <= 50 then rewardTxt = "250 gems"
						elseif rewardKey <= 100 then rewardTxt = "150 gems"
						else rewardTxt = "100 gems" end
					end
					local disp = player.DisplayName
					if snap and snap.vip then
						disp = (C.VIP_NAME_PREFIX or "[VIP] ") .. disp
					end
					you.TextColor3 = Color3.fromRGB(255, 245, 210)
					you.Font = Enum.Font.GothamBold
					you.TextSize = 15
					you.Text = string.format("%s   %s   %s", disp, rankTxt, rewardTxt)
				end
			end
		end
	end
end)

-- Socket-step soft lock: if the bench is closed while the tutorial still
-- wants a socket, breathe it back open. Bounded by introRequire's budget.
task.spawn(function()
	while true do
		task.wait(2)
		local req = ClientFns.introRequire
		if req then
			if os.clock() > req.expires or req.reopens <= 0 then
				ClientFns.introRequire = nil
			elseif enchantP and not enchantP.Visible then
				req.reopens -= 1
				ClientFns.routePanel(req.panel or "enchanter", req.tab or "sockets")
			end
		end
	end
end)

task.defer(function()
	net:FireServer("leaderboardGet")
end)

task.defer(function()
	local afk = player.PlayerGui:FindFirstChild("TCGAfkUI")
	if afk then
		afk:Destroy()
	end
end)

task.spawn(function()
	local tcg = RS:FindFirstChild("TCG")
	local remotes = tcg and tcg:WaitForChild("Remotes", 8)
	local portalNotify = remotes and remotes:WaitForChild("PortalNotify", 8)
	if portalNotify then
		portalNotify.OnClientEvent:Connect(function(payload)
			local text = type(payload) == "table" and payload.text or tostring(payload)
			if text and text ~= "" then
				showToast(text)
			end
		end)
	end
end)

print("[Mine] client ready")

--[[
	The two fullscreen screens (the workshop and the skill wheel) fill the
	whole viewport, and the HUD used to sit on top of them -- the wallet landed
	in the middle of the wheel's "how it works" column. Anything that covers the
	screen hides the HUD; everything else leaves it alone, because a wallet
	beside a windowed panel is normal and useful.
]]
--[[
	Fullscreen chrome hiders. The skill wheel still owns the whole HUD.
	Major panels (inventory, shops, forge, ...) retract the left quest drawers
	to a thin tab strip so they never cover modal content - desktop and phone.
	Wrapped in ClientFns (not a top-level `do`) so its locals do not burn the
	main chunk's 200-register ceiling.
]]
function ClientFns.wireQuestHudHiders()
	local HUD_HIDERS = { ShopPanel = true, SkillWheel = true }
	-- Any of these open -> quest drawers auto-collapse (tabs remain for a peek).
	local QUEST_HIDERS = {
		SkillWheel = true,
		ShopPanel = true,
		Inventory = true,
		ForgePanel = true,
		EventsPanel = true,
		DepthShopPanel = true,
		GiftsPanel = true,
		SettingsPanel = true,
		TradeWindow = true,
		TradePicker = true,
		BagFull = true,
	}
	local QUEST_WATCH = {
		ShopPanel = true,
		SkillWheel = true,
		Inventory = true,
		ForgePanel = true,
		EventsPanel = true,
		DepthShopPanel = true,
		GiftsPanel = true,
		SettingsPanel = true,
		TradeWindow = true,
		TradePicker = true,
		BagFull = true,
	}
	local hidden = {}
	local function raiseQuests(onTop)
		local z = onTop and 85 or 20
		if questsCovered then
			-- Keep the collapsed QUESTS pill above the modal so the player can peek.
			z = 90
		end
		-- The QuestPanel is the top-level frame now; the two cards inside it
		-- only order among themselves.
		if ClientFns.questPanel then
			ClientFns.questPanel.ZIndex = z
		end
		if dailyHud and dailyHud.card then
			dailyHud.card.ZIndex = onTop and 86 or 25
		end
		ClientFns.refreshQuestDrawerTabs()
	end
	local function repaintQuests()
		if not snap then
			return
		end
		pcall(ClientFns.showQuest, snap.quest)
		pcall(ClientFns.paintDailyBox, snap.dailyQuests)
		if snap.daily then
			pcall(dailyHud.show, snap.daily)
		end
	end
	local function apply()
		local cover = false
		local hideQuests = false
		local shopOpen = false
		local phone = ClientFns.questIsPhone and ClientFns.questIsPhone()
		for name in pairs(HUD_HIDERS) do
			local f = gui:FindFirstChild(name)
			if f and f.Visible then
				cover = true
				if name == "ShopPanel" then
					shopOpen = true
				end
			end
		end
		for name in pairs(QUEST_HIDERS) do
			local f = gui:FindFirstChild(name)
			if f and f.Visible then
				hideQuests = true
				break
			end
		end
		local inv = gui:FindFirstChild("Inventory")
		local invOpen = inv and inv.Visible
		local stateKey = (cover and 1 or 0) + (hideQuests and 2 or 0) + (shopOpen and 4 or 0) + (invOpen and 8 or 0) + (phone and 16 or 0)
		if hidden.state == stateKey then
			return
		end
		hidden.state = stateKey
		hudCovered = cover
		local wasCovered = questsCovered
		questsCovered = hideQuests
		wallet.Visible = not cover
		presL.Visible = not cover
		dock.Visible = not cover
		if hideQuests then
			if phone then
				ClientFns.questFolded = true
			end
			-- Opening a modal always retracts; peek is opt-in via the tabs.
			if not wasCovered then
				ClientFns.questDrawerPeeking = false
			end
			dailyHud.card.Visible = false
			raiseQuests(true)
			repaintQuests()
			ClientFns.syncQuestDrawer()
		else
			raiseQuests((not phone) and (shopOpen or invOpen))
			repaintQuests()
			ClientFns.syncQuestDrawer()
		end
		if mineResetL then
			mineResetL.Visible = not cover
		end
	end
	local function watch(child)
		if QUEST_WATCH[child.Name] and child:IsA("GuiObject") then
			child:GetPropertyChangedSignal("Visible"):Connect(apply)
			apply()
		end
	end
	for _, child in ipairs(gui:GetChildren()) do
		watch(child)
	end
	gui.ChildAdded:Connect(watch)
	apply()
end
ClientFns.wireQuestHudHiders()

--[[
	Roblox's topbar is not the same height everywhere -- phones, tablets and the
	desktop client all differ, and on any of them GuiService:GetGuiInset()
	answers 0 until the CoreGui topbar has finished building. This client starts
	first, so reading the inset once at load put the wallet underneath Roblox's
	own buttons. Lay the top row out from a function and run it again whenever
	the inset or the window changes.
]]
local function layoutTopbar()
	local top = GuiService:GetGuiInset().Y
	if top <= 0 then
		top = 58
	end
	-- UIScale also shrinks Position offsets; divide so safe-area clearance stays.
	local s = uiScale.Scale
	if s < 0.05 then
		s = 1
	end
	presL.Position = UDim2.new(0, 22 / s, 0, (top + 10) / s)
	wallet.Position = UDim2.new(0, 16 / s, 0, (top + 34) / s)
	-- Wallet capsule is 64px (candy pass); sit the quest panel just under it.
	ClientFns.questDrawerRestX = 16 / s
	ClientFns.questPanelY = (top + 112) / s
	ClientFns.placeDailyBox()
	ClientFns.applyQuestDrawerPos(true)
	if mineResetL then
		mineResetL.Position = UDim2.new(1, -16 / s, 0, (top + 12) / s)
	end
end
layoutTopbar()
task.delay(1, layoutTopbar)
task.delay(4, layoutTopbar)
pcall(function()
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(layoutTopbar)
end)
-- Nested so `cam` / `lookAtFountainOnce` do not consume the main chunk's
-- 200 local registers ("Out of local registers when trying to allocate cam").
;(function()
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			refreshMineUiScale()
			layoutTopbar()
			ClientFns.introPlace(introBanner.Size.X.Offset)
		end)
	end

	local function lookAtFountainOnce(char)
		task.defer(function()
			task.wait(0.35)
			if not char or not char.Parent then
				return
			end
			local root = char:FindFirstChild("HumanoidRootPart")
			if not root then
				return
			end
			local world = workspace:FindFirstChild("MineWorld")
			local lobby = world and world:FindFirstChild("Lobby")
			local fountain = lobby and lobby:FindFirstChild("Fountain")
			local center = fountain and fountain:FindFirstChild("FountainCenter")
			if not center then
				return
			end
			if (root.Position - center.Position).Magnitude > 90 then
				return
			end
			local camera = workspace.CurrentCamera
			if not camera then
				return
			end
			local target = center.Position + Vector3.new(0, 2, 0)
			local from = root.Position + Vector3.new(0, 10, 0) - (target - root.Position).Unit * 14
			camera.CameraType = Enum.CameraType.Custom
			camera.CFrame = CFrame.lookAt(from, target)
		end)
	end

	if player.Character then
		lookAtFountainOnce(player.Character)
	end
	player.CharacterAdded:Connect(lookAtFountainOnce)
end)()

--------------------------------------------------------------------------------
-- AFK chill: idle -> park on chill pad facing the block; VirtualUser softens
-- Roblox idle kick; Wake button leaves. Walking snaps you back (does not wake).
--------------------------------------------------------------------------------
-- Its own function, not a `do` block: a do block's locals share the main
-- chunk's 200 registers, and this one tipped the file over the ceiling
-- ("Out of local registers ... ensureHud"). task.spawn runs it right here.
task.spawn(function()
	local IDLE_SEC = (C and C.AFK_IDLE_SEC) or (5 * 60)
	local lastInput = os.clock()
	local afkLocal = false
	local gui, statusL, wakeBtn
	local tipShown, sessionStart = false, os.clock()

	local function touch()
		lastInput = os.clock()
	end

	UIS.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			return
		end
		touch()
		-- While AFK: WASD / jump / stick wakes you where you stand.
		if afkLocal then
			local kc = input.KeyCode
			local moveKey = kc == Enum.KeyCode.W or kc == Enum.KeyCode.A or kc == Enum.KeyCode.S
				or kc == Enum.KeyCode.D or kc == Enum.KeyCode.Space
				or kc == Enum.KeyCode.Up or kc == Enum.KeyCode.Down
				or kc == Enum.KeyCode.Left or kc == Enum.KeyCode.Right
			local stick = input.UserInputType == Enum.UserInputType.Gamepad1
				and (kc == Enum.KeyCode.Thumbstick1 or kc == Enum.KeyCode.ButtonA)
			if moveKey or stick then
				net:FireServer("afkStop")
			end
		end
	end)
	UIS.InputChanged:Connect(function(input, gp)
		if gp then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.MouseWheel then
			-- Ignore look/scroll so camera drift does not cancel AFK entry timer.
			return
		end
		touch()
	end)

	-- Anti-idle-kick:
	-- VirtualUser is best-effort only (often blocked by LocalUser capability).
	-- The real keep-alive is a same-place teleport every AFK_REFRESH_SEC, plus an
	-- early client request once Roblox reports ~8 minutes of idle.
	local lastRefreshAsk = 0
	local function pokeIdle()
		pcall(function()
			local VirtualUser = game:GetService("VirtualUser")
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
			VirtualUser:Button1Down(Vector2.new())
			VirtualUser:Button1Up(Vector2.new())
		end)
	end
	pcall(function()
		player.Idled:Connect(function(idleTime)
			pokeIdle()
			if packRevealBusy then
				touch()
				return
			end
			if not afkLocal then
				if (tonumber(idleTime) or 0) >= 90 then
					net:FireServer("afkStart")
				end
				return
			end
			if (tonumber(idleTime) or 0) >= 8 * 60 and (os.clock() - lastRefreshAsk) > 90 then
				lastRefreshAsk = os.clock()
				net:FireServer("afkRefresh")
			end
		end)
	end)
	task.spawn(function()
		while true do
			task.wait(30)
			if afkLocal then
				pokeIdle()
			end
		end
	end)

	local function ensureHud()
		if gui and gui.Parent then
			return
		end
		gui = Instance.new("ScreenGui")
		gui.Name = "MineAfkUI"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 120
		gui.Enabled = false
		gui.Parent = player:WaitForChild("PlayerGui")
		local card = Instance.new("Frame")
		card.AnchorPoint = Vector2.new(0.5, 0)
		card.Position = UDim2.new(0.5, 0, 0, 14)
		card.Size = UDim2.fromOffset(360, 108)
		card.BackgroundColor3 = Color3.fromRGB(22, 28, 24)
		card.BorderSizePixel = 0
		card.Parent = gui
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 12)
		c.Parent = card
		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Position = UDim2.fromOffset(14, 10)
		title.Size = UDim2.new(1, -28, 0, 22)
		title.Font = Enum.Font.GothamBlack
		title.TextSize = 16
		title.TextColor3 = Color3.fromRGB(170, 255, 180)
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = "AFK CHILL"
		title.Parent = card
		statusL = Instance.new("TextLabel")
		statusL.BackgroundTransparency = 1
		statusL.Position = UDim2.fromOffset(14, 36)
		statusL.Size = UDim2.new(1, -28, 0, 34)
		statusL.Font = Enum.Font.Gotham
		statusL.TextSize = 13
		statusL.TextColor3 = Color3.fromRGB(210, 220, 215)
		statusL.TextXAlignment = Enum.TextXAlignment.Left
		statusL.TextWrapped = true
		statusL.Text = "Mining slowly..."
		statusL.Parent = card
		wakeBtn = Instance.new("TextButton")
		wakeBtn.AnchorPoint = Vector2.new(0.5, 1)
		wakeBtn.Position = UDim2.new(0.5, 0, 1, -10)
		wakeBtn.Size = UDim2.fromOffset(140, 28)
		wakeBtn.BackgroundColor3 = Color3.fromRGB(90, 200, 120)
		wakeBtn.Font = Enum.Font.GothamBold
		wakeBtn.TextSize = 14
		wakeBtn.TextColor3 = Color3.fromRGB(16, 22, 18)
		wakeBtn.Text = "Wake up"
		wakeBtn.Parent = card
		local wc = Instance.new("UICorner")
		wc.CornerRadius = UDim.new(0, 8)
		wc.Parent = wakeBtn
		wakeBtn.MouseButton1Click:Connect(function()
			touch()
			net:FireServer("afkStop")
		end)
	end

	ClientFns.onAfkState = function(payload)
		ensureHud()
		afkLocal = payload and payload.active and true or false
		gui.Enabled = afkLocal
		if afkLocal then
			tipShown = true
			local sec = math.floor(tonumber(payload.interval) or 30)
			statusL.Text = string.format(
				"~%ds / block | %d coins | packs scale with luck + chest luck",
				sec,
				tonumber(payload.coins) or 3
			)
		else
			touch()
		end
	end

	ClientFns.onAfkMine = function(payload)
		ensureHud()
		if not gui.Enabled then
			return
		end
		local sec = math.floor(tonumber(payload and payload.interval) or 30)
		local line = string.format("+%d coins | next ~%ds", tonumber(payload and payload.coins) or 3, sec)
		if payload and payload.pack then
			line = line .. " | PACK " .. tostring(payload.pack)
		end
		statusL.Text = line
	end

	-- once, early, while they are still here -- not after they have gone.
	-- Deliberately does not call busyOpening(): that local is declared below
	-- this one, so from in here the name would resolve to a nil global.
	local function showAfkTip()
		if tipShown then
			return
		end
		tipShown = true
		local tg = Instance.new("ScreenGui")
		tg.Name = "MineAfkTipUI"
		tg.ResetOnSpawn = false
		tg.IgnoreGuiInset = true
		tg.DisplayOrder = 119
		tg.Parent = player:WaitForChild("PlayerGui")
		local tc = Instance.new("TextButton")
		tc.AnchorPoint = Vector2.new(0.5, 0)
		tc.Position = UDim2.new(0.5, 0, 0, 14)
		tc.Size = UDim2.fromOffset(430, 94)
		tc.BackgroundColor3 = Color3.fromRGB(22, 28, 24)
		tc.BorderSizePixel = 0
		tc.AutoButtonColor = false
		tc.Text = ""
		tc.Parent = tg
		local tcc = Instance.new("UICorner")
		tcc.CornerRadius = UDim.new(0, 12)
		tcc.Parent = tc
		local ts = Instance.new("UIStroke")
		ts.Color = Color3.fromRGB(90, 200, 120)
		ts.Thickness = 2
		ts.Parent = tc
		local tt = Instance.new("TextLabel")
		tt.BackgroundTransparency = 1
		tt.Position = UDim2.fromOffset(14, 9)
		tt.Size = UDim2.new(1, -28, 0, 20)
		tt.Font = Enum.Font.GothamBlack
		tt.TextSize = 15
		tt.TextColor3 = Color3.fromRGB(170, 255, 180)
		tt.TextXAlignment = Enum.TextXAlignment.Left
		tt.Text = "YOU KEEP MINING WHILE AFK"
		tt.Parent = tc
		local tb = Instance.new("TextLabel")
		tb.BackgroundTransparency = 1
		tb.Position = UDim2.fromOffset(14, 32)
		tb.Size = UDim2.new(1, -28, 0, 48)
		tb.Font = Enum.Font.Gotham
		tb.TextSize = 13
		tb.TextColor3 = Color3.fromRGB(210, 220, 215)
		tb.TextXAlignment = Enum.TextXAlignment.Left
		tb.TextYAlignment = Enum.TextYAlignment.Top
		tb.TextWrapped = true
		tb.Text = "Stand still 5 minutes and you mine on your own -- coins and free packs"
			.. " keep rolling in while you are away. Leave the game open instead of"
			.. " closing it.  (tap to dismiss)"
		tb.Parent = tc
		local function closeTip()
			if tg and tg.Parent then
				tg:Destroy()
			end
		end
		tc.MouseButton1Click:Connect(closeTip)
		task.delay(11, closeTip)
	end


	-- Opening things is not idling. A pack ceremony or a lucky block runs for
	-- minutes of tapping with no keypress, and getting parked on the chill pad
	-- halfway through one is maddening.
	local function busyOpening()
		if packRevealBusy then
			return true
		end
		local lucky = ClientFns.luckyCtl
		return (lucky and lucky.isOpen and lucky.isOpen()) or false
	end

	task.spawn(function()
		while true do
			task.wait(1.25)
			if not tipShown and os.clock() - sessionStart >= 165 and not busyOpening() then
				showAfkTip()
			end
			if afkLocal then
				-- Stay AFK until Wake or actual movement (WASD / jump / stick).
			elseif busyOpening() then
				touch()
			elseif os.clock() - lastInput >= IDLE_SEC then
				net:FireServer("afkStart")
			end
		end
	end)
end)

--[[
	ORE FACES.

	The server stamps OreId on an ore block and stops there. The art is built
	here because an EditableImage does not replicate -- it has to exist where it
	is drawn -- and because the alternative, an uploaded image, cannot work at
	all on this place: the experience belongs to a group and anything the
	upload tooling produces belongs to a user, so Roblox loads nothing and says
	nothing.

	Everything below lives inside this one spawned function on purpose. This
	script is at the 200 top-level local ceiling, and a do-block shares that
	budget, so a plain block of locals here would break the whole client.
]]
task.spawn(function()
	--[[
		MineOreFace replaces MineOreArt here. The old path looked the ore up in
		Cfg.ORE_FACE -- an index into THIRTY hand-packed tiles shared across 82
		ores, so most ores wore someone else's face -- and hung six tiling
		Textures per block. The new one draws the ore's own colour and material
		and hangs Decals, which have no tiling to drift at block edges.

		MineOreArt is left in the tree: it still owns the packed-tile pipeline
		and nothing else was asked to change about it.
	]]
	local okArt, Art = pcall(function()
		return require(game:GetService("ReplicatedStorage")
			:WaitForChild("Mine"):WaitForChild("Shared"):WaitForChild("MineOreFace"))
	end)
	if not okArt or not Art then
		return
	end
	local okCfg, Cfg = pcall(function()
		return require(game:GetService("ReplicatedStorage")
			:WaitForChild("Mine"):WaitForChild("Shared"):WaitForChild("MineConfig"))
	end)
	if not okCfg or not Cfg or not Cfg.oreById then
		return
	end

	local function skin(part)
		if not part:IsA("BasePart") then
			return
		end
		local id = part:GetAttribute("OreId")
		if type(id) ~= "string" then
			return
		end
		-- The whole roster row, not an index: the face is drawn from the ore's
		-- own colour, met, rough and glow.
		local ore = Cfg.oreById(id)
		if not ore then
			return
		end
		pcall(function()
			Art.apply(part, ore)
		end)
	end

	-- blocks that already exist, then everything that streams in after
	local world = workspace:WaitForChild("MineWorld", 30)
	if not world then
		return
	end
	for _, d in ipairs(world:GetDescendants()) do
		skin(d)
	end
	world.DescendantAdded:Connect(function(d)
		-- the attribute is set after the part is parented, so wait a frame
		task.defer(skin, d)
	end)
end)
