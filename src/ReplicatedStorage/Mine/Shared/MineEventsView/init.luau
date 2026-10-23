--[[
	MineEventsView -- the Events tab: every live event, each in its own theme.

	Owner, 2026-10-19 (wiki/open-questions.md §0e):
	  * BOTH EVENTS. The tab showed the first event with an open window, and
	    Event Horizon is open all season, so the Candy Crypt never had a
	    screen. A switcher now shows every event whose window is open, and the
	    tab opens on the event whose zone you are standing in, else the Crypt
	    while it is open (MineEventTabs, pure, run by tools/verify/crypt-ui.js).
	  * EACH CARD ITS OWN CLAIM. Its own flag (crypt.owned for the Crypt,
	    bigbangOwned for Event Horizon), its own button ("Claim Candy Crypt ·
	    FREE" / "Claim Event Horizon · FREE" -> buyZone with ITS zone), and
	    "Owned — enter from Planets", which opens Planets.
	  * AN (i) ON EACH CARD with the event's notice -- the same words the
	    first-entry pop-up shows (MineEventTabs.notice).
	  * THE EVENT THEMES (MineTheme.EVENT_THEMES): the Crypt's card is
	    Halloween, Event Horizon's dark universe, and the panel around them
	    takes the theme of whichever is up (MineUI.applyTheme).

	The Crypt's own body (its candy, the rule, Trick-or-Treat) is MineCryptView.
	Its tools and charms screens wait for the Crypt's next API (owner's scope
	change, 2026-10-19). Event Horizon keeps its banner and its Event Pass.

	The view owns no rules: it renders the snapshot it is handed and reports
	taps through opts (the host fires the remotes):
	  config, onClaim(zoneId), onPlanets(), onTrickOrTreat(), onOpenPass()

	PROPOSED (2026-10-19): the layout, the pills (badge + name, 222 px), the
	window line's local date ("ddd, MMM D, h:mm A"), and opening on the event
	you stand in, else the Crypt.
]]
local RunService = game:GetService("RunService")

local MineEventsView = {}

local shared = script.Parent
local T = require(shared:WaitForChild("MineTheme"))
local UI = require(shared:WaitForChild("MineUI"))
local Tabs = require(shared:WaitForChild("MineEventTabs"))

local function keep(inst)
	inst:SetAttribute("MineUIAdopted", true)
	return inst
end

local function frame(parent, props)
	local f = UI.new("Frame", props, parent)
	f.BorderSizePixel = 0
	return keep(f)
end

local function rules()
	local ok, R = pcall(function()
		return require(shared:WaitForChild("MineCryptRules"))
	end)
	return ok and R or nil
end

-- Cartoon banner: moon planet + black hole with white event-horizon ring.
-- Used when bannerImage is empty, or under an optional uploaded image. It is
-- art, so every piece is stamped: the kit's adopt pass would outline the moon
-- and hairline the stars.
local function paintCartoonBanner(parent)
	local function mk(className, props, p)
		local inst = Instance.new(className)
		for k, v in pairs(props or {}) do
			inst[k] = v
		end
		if inst:IsA("GuiObject") then
			keep(inst)
		end
		inst.Parent = p
		return inst
	end
	local function round(inst, r)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, r or 10)
		c.Parent = inst
	end
	local stage = mk("Frame", {
		Name = "CartoonBanner", BackgroundColor3 = Color3.fromRGB(12, 14, 28), BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1), ZIndex = 1,
	}, parent)
	round(stage, 14)
	local nebA = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(48, 36, 90), BackgroundTransparency = 0.55, BorderSizePixel = 0,
		Size = UDim2.fromOffset(220, 120), Position = UDim2.new(0.55, 0, 0.1, 0), ZIndex = 2,
	}, stage)
	round(nebA, 60)
	local neb = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(36, 60, 110), BackgroundTransparency = 0.6, BorderSizePixel = 0,
		Size = UDim2.fromOffset(180, 100), Position = UDim2.new(0.08, 0, 0.55, 0), ZIndex = 2,
	}, stage)
	round(neb, 50)
	for i = 1, 18 do
		local x = (i * 37) % 97
		local y = (i * 53) % 89
		mk("Frame", {
			BackgroundColor3 = Color3.fromRGB(230, 235, 255), BorderSizePixel = 0,
			Size = UDim2.fromOffset(2 + (i % 3), 2 + (i % 3)), Position = UDim2.new(x / 100, 0, y / 100, 0), ZIndex = 3,
		}, stage)
	end
	local holeWrap = mk("Frame", {
		Name = "BlackHole", BackgroundTransparency = 1, Size = UDim2.fromOffset(150, 150),
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.72, 0, 0.38, 0), ZIndex = 4,
	}, stage)
	local ring = mk("Frame", {
		Name = "HorizonRing", BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1), ZIndex = 4,
	}, holeWrap)
	round(ring, 999)
	local hole = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.82, 0.82), ZIndex = 5,
	}, holeWrap)
	round(hole, 999)
	local disk = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(160, 140, 255), BackgroundTransparency = 0.35, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1.35, 0, 0.22, 0),
		Rotation = -18, ZIndex = 3,
	}, holeWrap)
	round(disk, 40)
	local moon = mk("Frame", {
		Name = "Moon", BackgroundColor3 = Color3.fromRGB(178, 186, 198), BorderSizePixel = 0,
		Size = UDim2.fromOffset(210, 210), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.22, 0, 1.05, 0), ZIndex = 6,
	}, stage)
	round(moon, 999)
	for _, c in ipairs({ { 0.18, 0.22, 28 }, { 0.55, 0.18, 18 }, { 0.4, 0.45, 36, 0.25 }, { 0.7, 0.4, 14 } }) do
		local crater = mk("Frame", {
			BackgroundColor3 = Color3.fromRGB(148, 156, 170), BackgroundTransparency = c[4] or 0.15, BorderSizePixel = 0,
			Size = UDim2.fromOffset(c[3], c[3]), Position = UDim2.new(c[1], 0, c[2], 0), ZIndex = 7,
		}, moon)
		round(crater, 999)
	end
	local miner = mk("Frame", {
		Name = "Miner", BackgroundTransparency = 1, Size = UDim2.fromOffset(44, 58),
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.42, 0, 0.12, 0), ZIndex = 8,
	}, moon)
	for _, part in ipairs({
		{ Color3.fromRGB(255, 220, 180), 18, 18, 13, 0, 9, 999 },
		{ Color3.fromRGB(90, 100, 120), 22, 10, 11, -2, 10, 4 },
		{ Color3.fromRGB(70, 130, 200), 20, 22, 12, 18, 9, 4 },
		{ Color3.fromRGB(50, 55, 70), 18, 14, 13, 40, 9, 3 },
	}) do
		local f = mk("Frame", {
			BackgroundColor3 = part[1], BorderSizePixel = 0, Size = UDim2.fromOffset(part[2], part[3]),
			Position = UDim2.fromOffset(part[4], part[5]), ZIndex = part[6],
		}, miner)
		round(f, part[7])
	end
	return stage
end

--[[
	BEFORE LAUNCH THE CLOCK TICKS; AFTER IT, IT COUNTS THE REAL EVENT (owner,
	2026-10-07: "i want the timer to not actually start until i say launch,
	and rather just keep ticking down"). Event Horizon's window runs on the
	season clock, which does not move until launch, so before launch its line
	shows MineLaunch.teaserLeft() -- real time, falling second by second,
	counting toward nothing -- and after launch the real countdown. The Crypt
	is on real calendar dates and counts its own window (MineEventTabs).
]]
local okLaunch, Launch = pcall(function()
	return require(shared:WaitForChild("MineLaunch"))
end)

local function horizonLeft(C)
	if okLaunch and Launch and Launch.teaserLeft then
		local teaser = Launch.teaserLeft()
		if teaser then
			return Tabs.clock(teaser), true
		end
	end
	if C.limitedCountdown then
		return C.limitedCountdown("bigbang"), false
	end
	return nil, false
end

local function serverNow()
	local ok, t = pcall(function()
		return workspace:GetServerTimeNow()
	end)
	return (ok and tonumber(t)) or os.time()
end

function MineEventsView.mount(parent, opts)
	opts = opts or {}
	local C = opts.config
	assert(C, "MineEventsView needs opts.config")

	local okCV, CryptView = pcall(function()
		return require(shared:WaitForChild("MineCryptView"))
	end)
	if not okCV then
		warn("[MineEventsView] no Crypt card: MineCryptView did not load (" .. tostring(CryptView) .. ")")
		CryptView = nil
	end

	local state = {}
	local tickConn = nil
	local passOpen = false
	local selectedId = nil
	local shownKey = nil
	local currentTheme = nil

	-- ------------------------------------------------------------ the panel --
	local root = UI.themePanel(parent, "universe", UDim2.fromScale(0.92, 0.88), UDim2.fromScale(0.5, 0.52))
	root.Name = "EventsPanel"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Visible = false
	root.ZIndex = 40
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(1180, 820), MinSize = Vector2.new(520, 380) }, root)

	local title = UI.themeText(root, "EVENTS", 26, nil, "TEXT")
	title.Position = UDim2.fromOffset(20, 14)
	title.Size = UDim2.new(1, -100, 0, 34)
	title.ZIndex = 41

	local closeBtn = UI.button(root, "X", UDim2.fromOffset(48, 48), UDim2.new(1, -60, 0, 10), false, "red")
	closeBtn.Name = "Close"
	closeBtn.ZIndex = 45

	-- One pill per event that is up; the one showing is lit in its own theme.
	local switch = frame(root, {
		Name = "Switch", BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 62),
		Size = UDim2.new(1, -32, 0, 50), ZIndex = 41,
	})
	UI.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center,
	}, switch)

	local body = UI.new("ScrollingFrame", {
		Name = "Body", BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = UDim2.fromOffset(16, 120), Size = UDim2.new(1, -32, 1, -134),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollBarThickness = 6, ZIndex = 41,
	}, root)
	keep(body)
	UI.new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, body)

	local empty = UI.themeText(body, "No event right now.", 18, nil, "MUTED", T.FONT_M)
	empty.Size = UDim2.new(1, 0, 0, 40)
	empty.LayoutOrder = 99
	empty.Visible = false

	-- ------------------------------------------------------------- the cards --
	-- A card per event zone. Each wears its OWN theme (ThemeLock), whatever the
	-- panel around it wears.
	local cards = {}
	-- Forward-declared: every card's (i) opens it, and the cards are built
	-- above it (a local used above its declaration is a nil global).
	local showInfo

	local function newCard(zoneId, order)
		local theme = T.themeFor(zoneId)
		local card = UI.themeCard(body, theme, UDim2.new(1, -10, 0, 0))
		card.Name = "EventCard_" .. tostring(zoneId)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.LayoutOrder = order
		card.Visible = false
		card:SetAttribute("ThemeLock", true)
		UI.new("UIPadding", {
			PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 14),
			PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
		}, card)
		UI.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, card)
		local c = { card = card, theme = theme, zoneId = zoneId }
		cards[zoneId] = c
		return c
	end

	-- The head every event's card has: title, (i), its window, its claim.
	local function head(c, titleText, order)
		local h = frame(c.card, {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order,
		})
		UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, h)
		local top = frame(h, { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 1 })
		local t = UI.themeText(top, titleText, 26, c.theme, "TEXT")
		t.Size = UDim2.new(1, -60, 1, 0)
		t.TextTruncate = Enum.TextTruncate.AtEnd
		local info, infoL = UI.themeButton(top, "i", UDim2.fromOffset(44, 44), UDim2.new(1, -46, 0, 0), c.theme, "secondary")
		info.Name = "Info"
		infoL.TextSize = 22
		local timer = UI.themeText(h, "", 16, c.theme, "GLOW", T.FONT_M)
		timer.Size = UDim2.new(1, 0, 0, 22)
		timer.LayoutOrder = 2
		timer.TextTruncate = Enum.TextTruncate.AtEnd
		local cta, ctaL = UI.themeButton(h, "", UDim2.new(1, 0, 0, 56), nil, c.theme, "go")
		cta.Name = "Claim"
		cta.LayoutOrder = 3
		ctaL.TextSize = 20
		c.title, c.info, c.timer, c.cta, c.ctaL = t, info, timer, cta, ctaL
		info.MouseButton1Click:Connect(function()
			showInfo(c)
		end)
		-- Claims THIS card's zone; owned, it opens Planets; ended, nothing.
		cta.MouseButton1Click:Connect(function()
			if c.claims then
				if opts.onClaim then
					opts.onClaim(c.zoneId)
				end
			elseif c.job == "secondary" and opts.onPlanets then
				opts.onPlanets(c.zoneId)
			end
		end)
		return h
	end

	-- Event Horizon: its banner, its blurb, its Event Pass.
	local eh = newCard("bigbang", 1)
	do
		local bannerHost = frame(eh.card, {
			Name = "Banner", BackgroundColor3 = Color3.fromRGB(10, 12, 22), ClipsDescendants = true,
			Size = UDim2.new(1, 0, 0, 200), LayoutOrder = 0,
		})
		UI.round(bannerHost, 12)
		paintCartoonBanner(bannerHost)
		eh.bannerImg = keep(UI.new("ImageLabel", {
			Name = "BannerImage", BackgroundTransparency = 1, Image = "", ScaleType = Enum.ScaleType.Crop,
			Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 50,
		}, bannerHost))
		head(eh, "🌌 EVENT HORIZON", 1)
		eh.blurb = UI.themeText(eh.card, "", 16, eh.theme, "MUTED", T.FONT_M)
		eh.blurb.TextWrapped = true
		eh.blurb.Size = UDim2.new(1, 0, 0, 0)
		eh.blurb.AutomaticSize = Enum.AutomaticSize.Y
		eh.blurb.LayoutOrder = 2
		local pass, passL = UI.themeButton(eh.card, "EVENT PASS", UDim2.new(1, 0, 0, 50), nil, eh.theme, "secondary")
		pass.Name = "EventPass"
		pass.LayoutOrder = 3
		passL.TextSize = 19
		eh.pass = pass
	end

	-- The Candy Crypt: its head here, everything else MineCryptView.
	local crypt = newCard("hallow", 2)
	head(crypt, "🎃 CANDY CRYPT", 1)
	local cryptHost = frame(crypt.card, {
		Name = "CryptHost", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2,
	})
	local cryptCtl = nil
	if CryptView then
		local okM, ctl = pcall(CryptView.mount, cryptHost, {
			overlay = root,
			onTrickOrTreat = function()
				if opts.onTrickOrTreat then
					opts.onTrickOrTreat()
				end
			end,
		})
		if okM then
			cryptCtl = ctl
		else
			warn("[MineEventsView] the Crypt card failed to mount: " .. tostring(ctl))
		end
	end

	-- An event added to MineConfig.EVENTS later gets a plain card: its head.
	local function cardFor(ev)
		local zid = ev and ev.zoneId
		if not zid then
			return nil
		end
		local c = cards[zid]
		if not c then
			c = newCard(zid, 10 + #(C.EVENTS or {}))
			head(c, string.upper(tostring(ev.name or "Event")), 1)
		end
		return c
	end

	-- ------------------------------------------------------- the (i) sheet --
	local infoVeil = UI.new("TextButton", {
		Name = "InfoVeil", Text = "", AutoButtonColor = false, BorderSizePixel = 0,
		BackgroundColor3 = T.INK, BackgroundTransparency = 0.35, Size = UDim2.fromScale(1, 1),
		Visible = false, ZIndex = 70,
	}, root)
	UI.tint(infoVeil, nil, "INK")
	infoVeil:SetAttribute("NoClickSfx", true)
	local infoBox = UI.themePanel(infoVeil, nil, UDim2.new(0.84, 0, 0, 300), UDim2.fromScale(0.5, 0.5))
	infoBox.AnchorPoint = Vector2.new(0.5, 0.5)
	infoBox.ZIndex = 71
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(560, 320) }, infoBox)
	local infoTitle = UI.themeText(infoBox, "", 24, nil, "GLOW")
	infoTitle.TextXAlignment = Enum.TextXAlignment.Center
	infoTitle.Position = UDim2.fromOffset(20, 18)
	infoTitle.Size = UDim2.new(1, -40, 0, 32)
	infoTitle.TextWrapped = true
	infoTitle.ZIndex = 72
	local infoText = UI.themeText(infoBox, "", 18, nil, "TEXT", T.FONT_M)
	infoText.TextXAlignment = Enum.TextXAlignment.Center
	infoText.TextYAlignment = Enum.TextYAlignment.Top
	infoText.TextWrapped = true
	infoText.Position = UDim2.fromOffset(24, 60)
	infoText.Size = UDim2.new(1, -48, 1, -140)
	infoText.ZIndex = 72
	local infoOk, infoOkL = UI.themeButton(infoBox, "OK", UDim2.fromOffset(180, 52), UDim2.new(0.5, -90, 1, -70), nil, "go")
	infoOk.ZIndex = 73
	infoOkL.ZIndex = 74

	function showInfo(c)
		if not (c and c.ev) then
			return
		end
		local n = Tabs.notice(c.ev, rules())
		UI.applyTheme(infoVeil, c.theme)
		infoTitle.Text = n.title
		infoText.Text = n.text
		infoVeil.Visible = true
	end
	local function hideInfo()
		infoVeil.Visible = false
	end
	infoVeil.MouseButton1Click:Connect(hideInfo)
	infoOk.MouseButton1Click:Connect(hideInfo)

	-- ------------------------------------------------------ the Event Pass --
	-- Event Horizon's pass, in its theme. Shown over the panel.
	local passTheme = T.EVENT_THEMES.universe
	local passLayer = UI.new("Frame", {
		Name = "PassLayer", BorderSizePixel = 0, BackgroundColor3 = passTheme.INK, BackgroundTransparency = 0.25,
		Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 60,
	}, root)
	keep(passLayer)
	passLayer:SetAttribute("ThemeLock", true)
	local passPanel = UI.themePanel(passLayer, passTheme, UDim2.fromScale(0.94, 0.92), UDim2.fromScale(0.5, 0.5))
	passPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	passPanel.ZIndex = 61
	local passTitle = UI.themeText(passPanel, "Event Pass", 22, passTheme, "TEXT")
	passTitle.Position = UDim2.fromOffset(18, 12)
	passTitle.Size = UDim2.new(1, -120, 0, 32)
	local passBack, passBackL = UI.themeButton(passPanel, "BACK", UDim2.fromOffset(96, 40),
		UDim2.new(1, -110, 0, 10), passTheme, "secondary")
	passBackL.TextSize = 16
	local passScroll = UI.new("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(14, 58),
		Size = UDim2.new(1, -28, 1, -72), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(), ScrollBarThickness = 6, ZIndex = 62,
	}, passPanel)
	keep(passScroll)
	UI.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, passScroll)
	local passBlurb = UI.themeText(passScroll, "", 15, passTheme, "MUTED", T.FONT_M)
	passBlurb.TextWrapped = true
	passBlurb.Size = UDim2.new(1, -8, 0, 0)
	passBlurb.AutomaticSize = Enum.AutomaticSize.Y
	passBlurb.LayoutOrder = 1

	local tierCard = UI.themeCard(passScroll, passTheme, UDim2.new(1, -8, 0, 96))
	tierCard.LayoutOrder = 2
	local tierName = UI.themeText(tierCard, "Tier", 20, passTheme, "ACCENT")
	tierName.Position = UDim2.fromOffset(14, 8)
	tierName.Size = UDim2.new(1, -28, 0, 26)
	local tierTip = UI.themeText(tierCard, "", 14, passTheme, "MUTED", T.FONT_M)
	tierTip.Position = UDim2.fromOffset(14, 36)
	tierTip.Size = UDim2.new(1, -28, 0, 20)
	tierTip.TextTruncate = Enum.TextTruncate.AtEnd
	local xpTrack = frame(tierCard, {
		Position = UDim2.fromOffset(14, 62), Size = UDim2.new(1, -28, 0, 20),
	})
	UI.tint(xpTrack, passTheme, "INK")
	UI.round(xpTrack, 10)
	local xpFill = frame(xpTrack, { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = passTheme.ACCENT })
	UI.tint(xpFill, passTheme, "ACCENT")
	UI.round(xpFill, 10)
	local xpLbl = UI.themeText(xpTrack, "0 XP", 14, passTheme, "TEXT")
	xpLbl.TextXAlignment = Enum.TextXAlignment.Center
	xpLbl.Size = UDim2.fromScale(1, 1)
	UI.outlineText(xpLbl, 1.5)

	local questCard = UI.themeCard(passScroll, passTheme, UDim2.new(1, -8, 0, 116))
	questCard.LayoutOrder = 3
	local qHead = UI.themeText(questCard, "EVENT QUEST  \u{00B7}  XP ONLY", 14, passTheme, "ACCENT")
	qHead.Position = UDim2.fromOffset(14, 8)
	qHead.Size = UDim2.new(1, -28, 0, 18)
	local questText = UI.themeText(questCard, "", 16, passTheme, "TEXT")
	questText.TextWrapped = true
	questText.TextYAlignment = Enum.TextYAlignment.Top
	questText.Position = UDim2.fromOffset(14, 30)
	questText.Size = UDim2.new(1, -28, 0, 44)
	local questProg = UI.themeText(questCard, "", 14, passTheme, "MUTED", T.FONT_M)
	questProg.Position = UDim2.fromOffset(14, 82)
	questProg.Size = UDim2.new(1, -28, 0, 20)

	local tiersHead = UI.themeText(passScroll, "PASS TIERS", 16, passTheme, "TEXT")
	tiersHead.Size = UDim2.new(1, -8, 0, 24)
	tiersHead.LayoutOrder = 4
	local tiersHost = frame(passScroll, {
		Name = "TiersHost", BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 10),
		AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 5,
	})
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tiersHost)

	local passSig = nil
	local function paintPass()
		local ep = state.eventPass
		if not ep then
			passTitle.Text = "Event Pass"
			passBlurb.Text = "Join the event to unlock the pass."
			tierName.Text = "—"
			tierTip.Text = ""
			xpFill.Size = UDim2.new(0, 0, 1, 0)
			xpLbl.Text = "0 XP"
			questText.Text = "No active event quest."
			questProg.Text = ""
			return
		end
		passTitle.Text = tostring(ep.name or "Event Pass")
		passBlurb.Text = tostring(ep.blurb or "") .. "  Quests only count inside the event mine. Rewards are event bonuses — never coins, gems, or packs."
		local tier = ep.tier
		tierName.Text = (tier and tier.name) or "Horizon Scout"
		tierTip.Text = (tier and tier.tip) or ""
		local xp = tonumber(ep.xp) or 0
		local curXp = (tier and tonumber(tier.xp)) or 0
		local nextXp = ep.nextTier and tonumber(ep.nextTier.xp) or nil
		local frac = 1
		if nextXp and nextXp > curXp then
			frac = math.clamp((xp - curXp) / (nextXp - curXp), 0, 1)
			xpLbl.Text = string.format("%d / %d XP", xp, nextXp)
		else
			xpLbl.Text = string.format("%d XP  \u{00B7}  MAX", xp)
		end
		xpFill.Size = UDim2.new(frac, 0, 1, 0)
		local q = ep.quest
		if q then
			questText.Text = tostring(q.text or "")
			questProg.Text = string.format("%d / %d   \u{00B7}   Reward: %d event XP only",
				tonumber(q.progress) or 0, tonumber(q.goal) or 0, tonumber(q.xp) or 0)
		else
			questText.Text = "All event quests cleared."
			questProg.Text = string.format("Quest %d / %d", tonumber(ep.questTotal) or 0, tonumber(ep.questTotal) or 0)
		end
		-- The tier rows are rebuilt only when they change, not on every snapshot.
		local ti = tonumber(ep.tierIndex) or 1
		local sig = tostring(ti) .. "|" .. tostring(#(ep.tiers or {}))
		if sig == passSig then
			return
		end
		passSig = sig
		for _, ch in ipairs(tiersHost:GetChildren()) do
			if ch:IsA("GuiObject") then
				ch:Destroy()
			end
		end
		for i, t in ipairs(ep.tiers or {}) do
			local row = UI.themeCard(tiersHost, passTheme, UDim2.new(1, 0, 0, 54), nil, (i == ti) and "SHELL_HI" or "SHELL")
			row.LayoutOrder = i
			local n = UI.themeText(row, string.format("%s  \u{00B7}  %d XP", t.name or ("Tier " .. i), tonumber(t.xp) or 0),
				15, passTheme, (i <= ti) and "TEXT" or "MUTED", T.FONT_M)
			n.Position = UDim2.fromOffset(12, 6)
			n.Size = UDim2.new(1, -24, 0, 22)
			local tip = UI.themeText(row, tostring(t.tip or ""), 14, passTheme, "MUTED", T.FONT_M)
			tip.Position = UDim2.fromOffset(12, 28)
			tip.Size = UDim2.new(1, -24, 0, 20)
			tip.TextTruncate = Enum.TextTruncate.AtEnd
		end
	end

	local function openPass()
		passOpen = true
		passLayer.Visible = true
		passSig = nil
		paintPass()
		if opts.onOpenPass then
			opts.onOpenPass()
		end
	end
	local function closePass()
		passOpen = false
		passLayer.Visible = false
	end
	passBack.MouseButton1Click:Connect(closePass)
	eh.pass.MouseButton1Click:Connect(openPass)

	-- ----------------------------------------------------------- painting --
	local pills = {}
	-- Forward-declared: a pill's click repaints, and the pills are built
	-- above paint (a local used above its declaration is a nil global).
	local paint

	local function rebuildPills(list)
		for _, p in pairs(pills) do
			p.btn:Destroy()
		end
		pills = {}
		for i, row in ipairs(list) do
			local ev = row.ev
			local th = T.themeFor(ev.zoneId)
			local caption = ((th.BADGE or "") ~= "" and (th.BADGE .. " ") or "") .. tostring(ev.name or ev.id)
			local btn, lbl = UI.themeButton(switch, caption, UDim2.fromOffset(222, 46), nil, th, "secondary")
			btn.Name = "Pill_" .. tostring(ev.id)
			btn.LayoutOrder = i
			btn:SetAttribute("ThemeLock", true)
			lbl.TextSize = 18
			local id = ev.id
			btn.MouseButton1Click:Connect(function()
				selectedId = id
				hideInfo()
				closePass()
				paint()
			end)
			pills[id] = { btn = btn, theme = th, job = "secondary" }
		end
	end

	local function paintCard(c, row)
		local ev = row.ev
		c.ev = ev
		local text, claims = Tabs.claim(ev, state, row.open)
		c.ctaL.Text = text
		c.claims = claims
		local job = (claims and "go") or (row.owned and "secondary") or "off"
		if c.job ~= job then
			c.job = job
			UI.setJob(c.cta, c.theme, job)
		end
		-- A free claim is a thing to collect: it moves (house style rule 8).
		if claims and not c.stopPulse then
			c.stopPulse = UI.pulse(c.cta, 1.06, 0.9)
		elseif not claims and c.stopPulse then
			c.stopPulse()
			c.stopPulse = nil
		end
		if ev.zoneId == "hallow" then
			local line, at = Tabs.cryptWindowLine(state, serverNow())
			local date = (at and not Tabs.hasEnded(ev, state)) and Tabs.localDate(at) or ""
			c.timer.Text = (date ~= "") and (line .. "  \u{00B7}  " .. (row.open and "ends " or "") .. date) or line
			if cryptCtl then
				cryptCtl.setState(state)
			end
		else
			local left, teasing = horizonLeft(C)
			if not row.open or left == "closed" then
				c.timer.Text = "Event ended"
			elseif left then
				c.timer.Text = (teasing and "Starts in " or "Closes in ") .. left
					.. (row.owned and "  \u{00B7}  yours to keep" or "")
			else
				c.timer.Text = row.owned and "Yours to keep" or "Live now"
			end
			if c.blurb then
				c.blurb.Text = tostring(ev.blurb or "")
			end
			if c.bannerImg then
				local img = ev.bannerImage
				local ok = type(img) == "string" and img ~= "" and not string.find(img, "REPLACE", 1, true)
				c.bannerImg.Image = ok and img or ""
				c.bannerImg.Visible = ok and true or false
			end
			if c.pass then
				c.pass.Visible = state.eventPass ~= nil
			end
		end
	end

	function paint()
		local list = Tabs.shown(C, state)
		local ids = {}
		for _, row in ipairs(list) do
			table.insert(ids, tostring(row.ev.id))
		end
		local key = table.concat(ids, "|")
		if key ~= shownKey then
			shownKey = key
			rebuildPills(list)
		end
		local row = selectedId and Tabs.find(list, selectedId) or nil
		if not row then
			selectedId = nil
			row = Tabs.find(list, Tabs.defaultId(list, state))
		end
		switch.Visible = #list > 0
		empty.Visible = row == nil
		for id, p in pairs(pills) do
			local job = (row and row.ev.id == id) and "primary" or "secondary"
			if p.job ~= job then
				p.job = job
				UI.setJob(p.btn, p.theme, job)
			end
		end
		local shownCard = row and cardFor(row.ev) or nil
		for _, c in pairs(cards) do
			c.card.Visible = c == shownCard
		end
		local theme = T.themeFor(row and row.ev.zoneId or nil)
		if currentTheme ~= theme.NAME then
			currentTheme = theme.NAME
			UI.applyTheme(root, theme)
		end
		if not row then
			closePass()
			return
		end
		paintCard(shownCard, row)
		if passOpen then
			paintPass()
		end
	end

	local function stopTick()
		if tickConn then
			tickConn:Disconnect()
			tickConn = nil
		end
	end

	local function startTick()
		stopTick()
		local acc = 0
		tickConn = RunService.Heartbeat:Connect(function(dt)
			if not root.Visible then
				return
			end
			acc += dt
			if acc < 1 then
				return
			end
			acc = 0
			paint()
		end)
	end

	local view = {}

	function view.setState(snap)
		state = type(snap) == "table" and snap or {}
		if root.Visible then
			paint()
		end
	end

	-- Opens on the default event (MineEventTabs.defaultId), every time.
	function view.open()
		selectedId = nil
		root.Visible = true
		hideInfo()
		closePass()
		paint()
		startTick()
	end

	function view.close()
		closePass()
		hideInfo()
		root.Visible = false
		stopTick()
	end

	function view.toggle()
		if root.Visible then
			view.close()
		else
			view.open()
		end
	end

	-- A Trick-or-Treat case answered (trickOrTreatOpened).
	function view.onCaseOpened(payload)
		if cryptCtl and cryptCtl.onCaseOpened then
			cryptCtl.onCaseOpened(payload)
		end
	end

	closeBtn.MouseButton1Click:Connect(function()
		view.close()
	end)

	root:GetPropertyChangedSignal("Visible"):Connect(function()
		if root.Visible then
			paint()
			startTick()
		else
			closePass()
			stopTick()
		end
	end)

	view.root = root
	view.cards = cards
	paint()
	return view
end

return MineEventsView
