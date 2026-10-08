-- MineEventsView: Events tab — live limited event, banner, ticking countdown.

local RunService = game:GetService("RunService")

local MineEventsView = {}

local FONT = Enum.Font.GothamBold
local FONT_M = Enum.Font.GothamMedium
local FONT_S = Enum.Font.Gotham
local PANEL = Color3.fromRGB(22, 24, 32)
local BG2 = Color3.fromRGB(32, 36, 48)
local TEXT = Color3.fromRGB(235, 238, 245)
local MUTED = Color3.fromRGB(150, 158, 175)
local ACCENT = Color3.fromRGB(200, 220, 255)
local CTA = Color3.fromRGB(70, 140, 255)
local OWNED = Color3.fromRGB(70, 180, 120)
local PASS_ACCENT = Color3.fromRGB(120, 180, 255)

local function mk(className, props, parent)
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			inst[k] = v
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function round(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = inst
	return c
end

local function stroke(inst, t)
	local s = Instance.new("UIStroke")
	s.Thickness = t or 1
	s.Color = Color3.fromRGB(55, 60, 78)
	s.Parent = inst
	return s
end

-- Cartoon banner: moon planet + black hole with white event-horizon ring.
-- Used when bannerImage is empty, or under an optional uploaded image.
local function paintCartoonBanner(parent)
	local stage = mk("Frame", {
		Name = "CartoonBanner",
		BackgroundColor3 = Color3.fromRGB(12, 14, 28),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
	}, parent)
	round(stage, 14)

	-- soft nebula blobs
	local nebA = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(48, 36, 90),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(220, 120),
		Position = UDim2.new(0.55, 0, 0.1, 0),
		ZIndex = 2,
	}, stage)
	round(nebA, 60)

	local neb = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(36, 60, 110),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(180, 100),
		Position = UDim2.new(0.08, 0, 0.55, 0),
		ZIndex = 2,
	}, stage)
	round(neb, 50)

	-- stars
	for i = 1, 18 do
		local x = (i * 37) % 97
		local y = (i * 53) % 89
		mk("Frame", {
			BackgroundColor3 = Color3.fromRGB(230, 235, 255),
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(2 + (i % 3), 2 + (i % 3)),
			Position = UDim2.new(x / 100, 0, y / 100, 0),
			ZIndex = 3,
		}, stage)
	end

	-- black hole (upper right)
	local holeWrap = mk("Frame", {
		Name = "BlackHole",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(150, 150),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.72, 0, 0.38, 0),
		ZIndex = 4,
	}, stage)
	local ring = mk("Frame", {
		Name = "HorizonRing",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 4,
	}, holeWrap)
	round(ring, 999)
	local hole = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.82, 0.82),
		ZIndex = 5,
	}, holeWrap)
	round(hole, 999)
	-- thin accretion hint
	local disk = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(160, 140, 255),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1.35, 0, 0.22, 0),
		Rotation = -18,
		ZIndex = 3,
	}, holeWrap)
	round(disk, 40)

	-- moon planet (lower left)
	local moon = mk("Frame", {
		Name = "Moon",
		BackgroundColor3 = Color3.fromRGB(178, 186, 198),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(210, 210),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.22, 0, 1.05, 0),
		ZIndex = 6,
	}, stage)
	round(moon, 999)
	local function crater(ox, oy, s, t)
		local c = mk("Frame", {
			BackgroundColor3 = Color3.fromRGB(148, 156, 170),
			BackgroundTransparency = t or 0.15,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(s, s),
			Position = UDim2.new(ox, 0, oy, 0),
			ZIndex = 7,
		}, moon)
		round(c, 999)
	end
	crater(0.18, 0.22, 28)
	crater(0.55, 0.18, 18)
	crater(0.4, 0.45, 36, 0.25)
	crater(0.7, 0.4, 14)

	-- little cartoon miner on the moon, looking at the hole
	local miner = mk("Frame", {
		Name = "Miner",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(44, 58),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.42, 0, 0.12, 0),
		ZIndex = 8,
	}, moon)
	local head = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 220, 180),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.fromOffset(13, 0),
		ZIndex = 9,
	}, miner)
	round(head, 999)
	local helm = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(90, 100, 120),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(22, 10),
		Position = UDim2.fromOffset(11, -2),
		ZIndex = 10,
	}, miner)
	round(helm, 4)
	local body = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(70, 130, 200),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(20, 22),
		Position = UDim2.fromOffset(12, 18),
		ZIndex = 9,
	}, miner)
	round(body, 4)
	local legs = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(50, 55, 70),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(18, 14),
		Position = UDim2.fromOffset(13, 40),
		ZIndex = 9,
	}, miner)
	round(legs, 3)

	return stage
end

function MineEventsView.mount(parent, opts)
	opts = opts or {}
	local C = opts.config
	assert(C, "MineEventsView needs opts.config")

	local state = {
		bigbangOwned = false,
		limitedActive = false,
		eventPass = nil,
	}
	local tickConn = nil
	local passOpen = false

	local root = mk("Frame", {
		Name = "EventsPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.92, 0.88),
		BackgroundColor3 = PANEL,
		BackgroundTransparency = 0.04,
		Visible = false,
		ZIndex = 40,
		BorderSizePixel = 0,
	}, parent)
	round(root, 12)
	stroke(root, 1.5)
	do
		local cap = Instance.new("UISizeConstraint")
		cap.MaxSize = Vector2.new(1180, 820)
		cap.MinSize = Vector2.new(520, 380)
		cap.Parent = root
	end

	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 22,
		Text = "EVENTS",
		Size = UDim2.new(1, -72, 0, 36),
		Position = UDim2.fromOffset(18, 10),
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 41,
	}, root)

	local closeBtn = mk("TextButton", {
		Text = "X",
		Font = FONT,
		TextSize = 18,
		TextColor3 = TEXT,
		BackgroundColor3 = BG2,
		Size = UDim2.fromOffset(46, 46),
		Position = UDim2.new(1, -48, 0, 10),
		ZIndex = 42,
		AutoButtonColor = true,
	}, root)
	round(closeBtn, 8)

	local body = mk("ScrollingFrame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 52),
		Size = UDim2.new(1, -32, 1, -68),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		BorderSizePixel = 0,
		ZIndex = 41,
	}, root)
	mk("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, body)

	local card = mk("Frame", {
		Name = "EventCard",
		BackgroundColor3 = BG2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 440),
		LayoutOrder = 1,
		ZIndex = 42,
	}, body)
	round(card, 14)
	stroke(card, 1)

	local bannerHost = mk("Frame", {
		Name = "Banner",
		BackgroundColor3 = Color3.fromRGB(10, 12, 22),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.new(1, -24, 0, 200),
		Position = UDim2.fromOffset(12, 12),
		ZIndex = 43,
	}, card)
	round(bannerHost, 12)
	paintCartoonBanner(bannerHost)

	local bannerImg = mk("ImageLabel", {
		Name = "BannerImage",
		BackgroundTransparency = 1,
		Image = "",
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 50,
	}, bannerHost)

	local title = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 26,
		Text = "Event Horizon",
		TextColor3 = ACCENT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(16, 224),
		Size = UDim2.new(1, -32, 0, 32),
		ZIndex = 44,
	}, card)

	local timerLbl = mk("TextLabel", {
		Name = "Timer",
		BackgroundTransparency = 1,
		Font = FONT_M,
		TextSize = 16,
		Text = "",
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(16, 256),
		Size = UDim2.new(1, -32, 0, 24),
		ZIndex = 44,
	}, card)

	local blurb = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT_S,
		TextSize = 15,
		Text = "",
		TextColor3 = MUTED,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(16, 286),
		Size = UDim2.new(1, -32, 0, 56),
		ZIndex = 44,
	}, card)

	local cta = mk("TextButton", {
		Name = "Claim",
		Font = FONT,
		TextSize = 16,
		Text = "Claim",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = CTA,
		AutoButtonColor = true,
		Position = UDim2.fromOffset(16, 354),
		Size = UDim2.new(0.48, -20, 0, 44),
		ZIndex = 45,
	}, card)
	round(cta, 10)

	local detailsBtn = mk("TextButton", {
		Name = "Details",
		Font = FONT,
		TextSize = 16,
		Text = "Event Pass",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Color3.fromRGB(55, 70, 110),
		AutoButtonColor = true,
		Position = UDim2.new(0.52, 4, 0, 354),
		Size = UDim2.new(0.48, -20, 0, 44),
		ZIndex = 45,
		Visible = false,
	}, card)
	round(detailsBtn, 10)

	local empty = mk("TextLabel", {
		Name = "Empty",
		BackgroundTransparency = 1,
		Font = FONT_M,
		TextSize = 16,
		Text = "No event right now.",
		TextColor3 = MUTED,
		Visible = false,
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = 2,
		ZIndex = 42,
	}, body)

	-- Pass overlay
	local passLayer = mk("Frame", {
		Name = "PassLayer",
		BackgroundColor3 = Color3.fromRGB(8, 10, 16),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 60,
	}, root)

	local passPanel = mk("Frame", {
		Name = "PassPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.94, 0, 0.92, 0),
		BackgroundColor3 = PANEL,
		BorderSizePixel = 0,
		ZIndex = 61,
	}, passLayer)
	round(passPanel, 12)
	stroke(passPanel, 1.5)

	local passTitle = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 20,
		Text = "Event Pass",
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(18, 10),
		Size = UDim2.new(1, -100, 0, 32),
		ZIndex = 62,
	}, passPanel)

	local passBack = mk("TextButton", {
		Text = "Back",
		Font = FONT_M,
		TextSize = 14,
		TextColor3 = TEXT,
		BackgroundColor3 = BG2,
		Size = UDim2.fromOffset(72, 32),
		Position = UDim2.new(1, -88, 0, 10),
		ZIndex = 63,
		AutoButtonColor = true,
	}, passPanel)
	round(passBack, 8)

	local passScroll = mk("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 50),
		Size = UDim2.new(1, -28, 1, -64),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		BorderSizePixel = 0,
		ZIndex = 62,
	}, passPanel)
	mk("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, passScroll)

	local passBlurb = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT_S,
		TextSize = 14,
		Text = "",
		TextColor3 = MUTED,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = 1,
		ZIndex = 63,
	}, passScroll)

	local tierCard = mk("Frame", {
		BackgroundColor3 = BG2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 88),
		LayoutOrder = 2,
		ZIndex = 63,
	}, passScroll)
	round(tierCard, 10)
	stroke(tierCard, 1)

	local tierName = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 18,
		Text = "Tier",
		TextColor3 = PASS_ACCENT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 24),
		ZIndex = 64,
	}, tierCard)

	local tierTip = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT_S,
		TextSize = 13,
		Text = "",
		TextColor3 = MUTED,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(14, 34),
		Size = UDim2.new(1, -28, 0, 18),
		ZIndex = 64,
	}, tierCard)

	local xpTrack = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(20, 22, 30),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(14, 60),
		Size = UDim2.new(1, -28, 0, 14),
		ZIndex = 64,
	}, tierCard)
	round(xpTrack, 7)

	local xpFill = mk("Frame", {
		BackgroundColor3 = PASS_ACCENT,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		ZIndex = 65,
	}, xpTrack)
	round(xpFill, 7)

	local xpLbl = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT_M,
		TextSize = 11,
		Text = "0 XP",
		TextColor3 = TEXT,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 66,
	}, xpTrack)

	local questCard = mk("Frame", {
		BackgroundColor3 = BG2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 110),
		LayoutOrder = 3,
		ZIndex = 63,
	}, passScroll)
	round(questCard, 10)
	stroke(questCard, 1)

	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT_M,
		TextSize = 12,
		Text = "EVENT QUEST  ·  XP ONLY",
		TextColor3 = PASS_ACCENT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -28, 0, 16),
		ZIndex = 64,
	}, questCard)

	local questText = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 15,
		Text = "",
		TextColor3 = TEXT,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(14, 28),
		Size = UDim2.new(1, -28, 0, 40),
		ZIndex = 64,
	}, questCard)

	local questProg = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT_M,
		TextSize = 13,
		Text = "",
		TextColor3 = MUTED,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(14, 72),
		Size = UDim2.new(1, -28, 0, 20),
		ZIndex = 64,
	}, questCard)

	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT_M,
		TextSize = 13,
		Text = "Pass tiers",
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = 4,
		ZIndex = 63,
	}, passScroll)

	local tiersHost = mk("Frame", {
		Name = "TiersHost",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 10),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 5,
		ZIndex = 63,
	}, passScroll)
	mk("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tiersHost)

	local function clearTiers()
		for _, ch in ipairs(tiersHost:GetChildren()) do
			if ch:IsA("Frame") then
				ch:Destroy()
			end
		end
	end

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
			clearTiers()
			return
		end

		passTitle.Text = ep.name or "Event Pass"
		passBlurb.Text = (ep.blurb or "") .. "  Quests only count inside the event mine. Rewards are event bonuses — never coins, gems, or packs."

		local tier = ep.tier
		tierName.Text = (tier and tier.name) or "Horizon Scout"
		tierTip.Text = (tier and tier.tip) or ""

		local xp = tonumber(ep.xp) or 0
		local nextT = ep.nextTier
		local curXp = (tier and tonumber(tier.xp)) or 0
		local nextXp = nextT and tonumber(nextT.xp) or nil
		local frac = 1
		if nextXp and nextXp > curXp then
			frac = math.clamp((xp - curXp) / (nextXp - curXp), 0, 1)
			xpLbl.Text = string.format("%d / %d XP", xp, nextXp)
		else
			xpLbl.Text = string.format("%d XP  ·  MAX", xp)
		end
		xpFill.Size = UDim2.new(frac, 0, 1, 0)

		local q = ep.quest
		if q then
			questText.Text = q.text or ""
			questProg.Text = string.format(
				"%d / %d   ·   Reward: %d event XP only",
				tonumber(q.progress) or 0,
				tonumber(q.goal) or 0,
				tonumber(q.xp) or 0
			)
		else
			questText.Text = "All event quests cleared."
			questProg.Text = string.format("Quest %d / %d", tonumber(ep.questTotal) or 0, tonumber(ep.questTotal) or 0)
		end

		clearTiers()
		local tiers = ep.tiers or {}
		local ti = tonumber(ep.tierIndex) or 1
		for i, t in ipairs(tiers) do
			local row = mk("Frame", {
				BackgroundColor3 = (i == ti) and Color3.fromRGB(40, 52, 78) or Color3.fromRGB(28, 32, 44),
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 48),
				LayoutOrder = i,
				ZIndex = 64,
			}, tiersHost)
			round(row, 8)
			mk("TextLabel", {
				BackgroundTransparency = 1,
				Font = FONT_M,
				TextSize = 14,
				Text = string.format("%s  ·  %d XP", t.name or ("Tier " .. i), tonumber(t.xp) or 0),
				TextColor3 = (i <= ti) and TEXT or MUTED,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(12, 4),
				Size = UDim2.new(1, -24, 0, 20),
				ZIndex = 65,
			}, row)
			mk("TextLabel", {
				BackgroundTransparency = 1,
				Font = FONT_S,
				TextSize = 12,
				Text = t.tip or "",
				TextColor3 = MUTED,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromOffset(12, 24),
				Size = UDim2.new(1, -24, 0, 18),
				ZIndex = 65,
			}, row)
		end
	end

	local function openPass()
		passOpen = true
		passLayer.Visible = true
		paintPass()
		if opts.onOpenPass then
			opts.onOpenPass()
		end
	end

	local function closePass()
		passOpen = false
		passLayer.Visible = false
	end

	local function currentEvent()
		local list = C.EVENTS or {}
		for _, ev in ipairs(list) do
			return ev
		end
		return nil
	end

	--[[
		BEFORE LAUNCH THE CLOCK TICKS; AFTER IT, IT COUNTS THE REAL EVENT.

		Owner, 2026-10-07: "i want the timer to not actually start until i say
		launch, and rather just keep ticking down".

		Those are two different clocks and this is where they meet.
		limitedCountdown now runs on the season clock, which does not move until
		the owner launches -- correct, but it means a pre-launch screen would
		show a FROZEN "47d 0h" sitting there, which reads as a broken timer
		rather than a game that has not started.

		So while unlaunched the label shows MineLaunch.teaserLeft(), which is
		driven by real os.time() and falls second by second. It is cosmetic by
		design: it counts toward nothing, nothing watches it, and it rolls over
		and starts again. Its whole job is to be alive on screen.

		The moment the switch is thrown teaserLeft returns nil and this falls
		through to the real event countdown, so the handover needs no state of
		its own.
	]]
	local okLaunch, Launch = pcall(function()
		return require(game:GetService("ReplicatedStorage").Mine.Shared:WaitForChild("MineLaunch"))
	end)

	local function hms(secs)
		local d = math.floor(secs / 86400)
		local h = math.floor((secs % 86400) / 3600)
		local m = math.floor((secs % 3600) / 60)
		local s = math.floor(secs % 60)
		if d >= 1 then
			return string.format("%dd %dh", d, h)
		end
		if h >= 1 then
			return string.format("%dh %dm", h, m)
		end
		return string.format("%dm %02ds", m, s)
	end

	local function formatLeft()
		if okLaunch and Launch and Launch.teaserLeft then
			local teaser = Launch.teaserLeft()
			if teaser then
				return hms(teaser), true
			end
		end
		if C.limitedCountdown then
			return C.limitedCountdown(), false
		end
		return nil, false
	end

	local function paint()
		local ev = currentEvent()
		if not ev then
			card.Visible = false
			empty.Visible = true
			empty.Text = "No event right now."
			detailsBtn.Visible = false
			closePass()
			return
		end

		card.Visible = true
		title.Text = ev.name or "Event"
		blurb.Text = ev.blurb or ""

		local img = ev.bannerImage
		if type(img) == "string" and img ~= "" and not string.find(img, "REPLACE", 1, true) then
			bannerImg.Image = img
			bannerImg.Visible = true
		else
			bannerImg.Visible = false
		end

		local owned = state.bigbangOwned == true
		local active = state.limitedActive == true
		if C.limitedActive then
			active = C.limitedActive()
		end
		local left, teasing = formatLeft()

		detailsBtn.Visible = true

		if owned then
			timerLbl.Text = (active and left and left ~= "closed")
				and ("Yours to keep  \u{00B7}  event " .. (teasing and "starts in " or "closes in ") .. left)
				or "Yours to keep"
			cta.Text = "Owned — enter from Zones"
			cta.BackgroundColor3 = OWNED
			cta.Active = false
			empty.Visible = false
		elseif active and left ~= "closed" then
			-- Pre-launch the number is the teaser, so it must not say "closes":
			-- nothing is closing, the season has not begun.
			timerLbl.Text = left and ((teasing and "Starts in " or "Closes in ") .. left) or "Live now"
			cta.Text = "Claim Event Horizon  ·  FREE"
			cta.BackgroundColor3 = CTA
			cta.Active = true
			empty.Visible = false
		else
			timerLbl.Text = "Event ended"
			cta.Text = "Event ended"
			cta.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
			cta.Active = false
			empty.Visible = true
			empty.Text = "No event right now. Last up: " .. (ev.name or "Event Horizon") .. "."
			detailsBtn.Visible = state.eventPass ~= nil
		end

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
		snap = snap or {}
		state.bigbangOwned = snap.bigbangOwned and true or false
		state.limitedActive = snap.limitedActive and true or false
		state.eventPass = snap.eventPass
		if root.Visible then
			paint()
		end
	end

	function view.open()
		root.Visible = true
		closePass()
		paint()
		startTick()
	end

	function view.close()
		closePass()
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

	closeBtn.MouseButton1Click:Connect(function()
		view.close()
	end)

	passBack.MouseButton1Click:Connect(function()
		closePass()
	end)

	detailsBtn.MouseButton1Click:Connect(function()
		openPass()
	end)

	cta.MouseButton1Click:Connect(function()
		if not cta.Active then
			return
		end
		local ev = currentEvent()
		local zoneId = ev and ev.zoneId or "bigbang"
		if opts.onClaim then
			opts.onClaim(zoneId)
		end
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
	paint()
	return view
end

return MineEventsView
