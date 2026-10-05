--[[
	MinePackReveal -- the pack rip.

	ONE PACK. ONE STAGE. ONE STACK. ONE CLICK = ONE CARD.

	The old reveal laid every card into a 760px horizontal row. Eight 200px
	cards do not fit in 760px, so half of a Chrome pack was off-screen and read
	as "the cards didn't load". There was no stack, no click, no tension, and a
	Common got exactly the same polite fade as a Divine. It also closed the
	inventory and auto-dismissed on a timer, so the pack could end while you
	were still looking at it.

	What replaces it: a sealed pack big enough to be the whole frame, a tear,
	then a STACK of card backs one in front of another. Each tap pulls the top
	card -- the previous one flies to the tray, the new one lifts and turns
	over, and the screen reacts in proportion to how good it actually is.

	THE PLAYER OWNS THE TEMPO.

	Every beat is an offer, never a jail. A tap during any animation commits it
	immediately and moves on. Mash and a six-card pack is gone in two seconds;
	sit still and nothing advances without you. Tension beats before a good card
	are cancelled by the next tap. There is no timer that closes a pack with
	cards still face-down.

	THE SERVER ALREADY ROLLED THE TRUTH.

	This is a director, not a dealer. It presents the `made` array exactly as it
	arrived -- already sorted worst-to-best by MineServer.openPack, so the climb
	is real. It never re-rolls, never invents a card, never changes a rarity.
]]

local MinePackReveal = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local shared = game:GetService("ReplicatedStorage").Mine.Shared
local T = require(shared:WaitForChild("MineTheme"))
local Audio = require(shared:WaitForChild("MineAudio"))
local PackFX = require(shared:WaitForChild("MinePackFX"))
local Cards = require(shared:WaitForChild("MineCards"))
-- The F..SSS climb. Gear ships its ladder on the item and this plays it.
local GradeReveal = require(shared:WaitForChild("MineGradeReveal"))

local FONT = T.FONT
local FONT_M = T.FONT_M
local BG2 = T.BG2
local TEXT = T.TEXT
local MUTED = T.MUTED
local GOLD = T.GOLD
local GREEN = T.GREEN

-- How long a beat lasts when the player is savouring vs mashing. Rush timings
-- are short enough to be input-limited: the ceiling is how fast you can click.
local SAVOR = { lift = 0.20, flip = 0.20, out = 0.26, tension = 0.30 }
local RUSH  = { lift = 0.07, flip = 0.08, out = 0.10, tension = 0.00 }
-- Two taps closer together than this and the player is mashing, not reading.
local RUSH_WINDOW = 0.35

-- Size of a card in the recap strip along the bottom.
local RECAP_W = 84
local RECAP_H = math.floor(RECAP_W * 1.4)

--[[
	The one beat the player does NOT own.

	Everything else in this file is skippable on purpose, but a hit that can be
	clicked past before it has drawn is a hit the player never saw -- they mash,
	the Legendary flashes for one frame, and the best moment in the pack is
	gone. So a good card gets a fixed look, scaled to how good it is: a Rare
	barely pauses, an Exotic gets three quarters of a second.

	Commons and Uncommons get nothing at all, which is what makes this read as
	"stop, look at that" rather than as lag.

	The window is only half the protection. The other half is that any taps that
	land DURING it are thrown away -- see where this is used. Without that the
	hold is pointless: the player mashes, the wait runs, and the queued tap
	fires the instant it ends, clearing the card they never got to see.
]]
local HOLD_BY_RANK = {
	[3] = 0.10, -- Rare
	[4] = 0.15, -- Epic
	[5] = 0.25, -- Legendary
	[6] = 0.50, -- Mythic
	[7] = 0.60, -- Divine
	[8] = 0.75, -- Exotic
}
-- A big variant on a small card is still a moment: a Rainbow Common is not a
-- Common. Whichever of the two says "look longer" wins.
local HOLD_BY_BAND = { CHASE = 0.25, GOD = 0.50 }

local function holdFor(card, band)
	local rank = (Cards.RARITY_RANK and Cards.RARITY_RANK[(card and card.rarityId) or ""]) or 0
	return math.max(HOLD_BY_RANK[rank] or 0, HOLD_BY_BAND[band] or 0)
end

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		o[k] = v
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function round(o, r)
	mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o)
	return o
end

local function stroke(o, t, col, trans)
	return mk("UIStroke", {
		Thickness = t or 1,
		Color = col or GOLD,
		Transparency = trans or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, o)
end

local function label(parent, text, size, colour, pos, sz, font)
	return mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = font or FONT_M,
		Text = text,
		TextSize = size,
		TextColor3 = colour or TEXT,
		Position = pos or UDim2.fromOffset(0, 0),
		Size = sz or UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 12,
	}, parent)
end

local function rarityColour(card)
	local c = card and Cards.RARITY_COLOR and Cards.RARITY_COLOR[card.rarityId or ""]
	return c or MUTED
end

--[[
	FORCED REVEALS (`meta.auto`).

	A chest find -- a tool, a charm, a bonkers pack -- is a pack the player did
	not have to buy, and it plays like one: rip, stack, flip. The difference is
	that nobody has to press anything. Each beat waits this long for a tap and
	then goes on by itself; tapping only ever makes it go faster, so a masher
	is through it in a second and a player who looks away still sees it land.
]]
local AUTO_PULL = 0.55
local AUTO_LOOK = 2.4
local AUTO_LOOK_RARE = 3.6

-- What a rarity is usually worth in odds (Loam's own table), for loot that
-- carries no odds of its own -- gear, runes, packs from old saves --
-- so one sort can rank everything by the same measure.
local RANK_ODDS = { 2.9, 3.9, 6.4, 14.5, 36, 175, 950, 3800 }
local function pullKey(card)
	local f = tonumber(card and card.oddsForm)
	if f then
		return f
	end
	local r = (Cards.RARITY_RANK and Cards.RARITY_RANK[(card and card.rarityId) or ""]) or 1
	return RANK_ODDS[math.clamp(r, 1, #RANK_ODDS)]
end

local function commas(n)
	local s = tostring(math.floor((tonumber(n) or 0) + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return out
end

--[[
	THE "1 IN X" RIBBON.

	Only on a pull rare enough to brag about. The server decides that: it sends
	`oneIn` only past the line, worked out from the odds that actually rolled
	the card, so the number is true for that exact card, in that exact form,
	from that exact pack (see MinePackConfig.pullOdds / MineTools.exactOneIn).

	It is parented to the face, so it goes down into the recap strip with the
	card. The digits land one at a time -- a number like this should be read,
	not glanced at.
]]
local function oddsRibbon(face, oneIn, col, w, h)
	local rib = mk("Frame", {
		Name = "OddsRibbon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 1, -math.floor(h * 0.02)),
		Size = UDim2.fromOffset(math.floor(w * 0.9), math.max(28, math.floor(h * 0.1))),
		BackgroundColor3 = Color3.fromRGB(18, 13, 6),
		BorderSizePixel = 0,
		ZIndex = 60,
	}, face)
	round(rib, 999)
	stroke(rib, 3, (col or GOLD):Lerp(GOLD, 0.45), 0)
	mk("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(92, 66, 20), Color3.fromRGB(24, 17, 7)),
	}, rib)
	local txt = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.fromRGB(255, 228, 124),
		Text = "1 IN",
		Size = UDim2.new(1, -20, 1, -8),
		Position = UDim2.fromOffset(10, 4),
		ZIndex = 61,
	}, rib)
	txt.TextScaled = true
	local punch = mk("UIScale", { Scale = 0.4 }, rib)
	TweenService:Create(punch, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local full = commas(oneIn)
	task.spawn(function()
		task.wait(0.12)
		local shown = ""
		for k = 1, #full do
			if not rib.Parent then
				return
			end
			local ch = full:sub(k, k)
			shown ..= ch
			txt.Text = "1 IN " .. shown
			if ch ~= "," then
				punch.Scale = 1.1
				TweenService:Create(punch, TweenInfo.new(0.08), { Scale = 1 }):Play()
				task.wait(0.055)
			end
		end
	end)
	return rib
end
--[[
	Mount once, at startup. `opts`:
	  paintCard(parent, card, width) -> Frame   the game's one card renderer
	  onOpenMore(packId, count)                 player asked for another run
	  onStore()                                 no packs left, send them to buy
	  onDone()                                  the reveal closed; unlock the menu
	  onToast(text)                             surface a problem in the game's own toast
	  onScreenOwned(flag)                       reveal is taking / releasing the screen
]]
function MinePackReveal.mount(playerGui, opts)
	opts = opts or {}

	local screen = mk("ScreenGui", {
		Name = "PackReveal",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		-- Above the inventory (80). The inventory stays open underneath: the
		-- reveal is a layer over the menu, not a replacement for it.
		DisplayOrder = 120,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Enabled = false,
	}, playerGui)

	--[[
		Phones. The ceremony is laid out in pixels (card widths, the tray, the
		bottom bands), and this ScreenGui lives outside MineUI, so the HUD's
		UIScale never reaches it. Same tiers as MineClient.refreshMineUiScale;
		Scale-sized things (scrim, stage) render identically under a UIScale,
		so only the fixed-pixel parts shrink.
	]]
	local revealScale = mk("UIScale", { Name = "RevealScale", Scale = 1 }, screen)
	do
		local UIS = game:GetService("UserInputService")
		local function refreshScale()
			local cam = workspace.CurrentCamera
			local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
			local short = math.min(v.X, v.Y)
			local s = 1
			if UIS.TouchEnabled then
				if short < 560 then
					s = 0.82
				elseif short < 700 then
					s = 0.88
				elseif short < 900 then
					s = 0.92
				else
					s = 1
				end
			elseif short < 700 then
				s = math.clamp(short / 800, 0.7, 1)
			end
			revealScale.Scale = s
		end
		refreshScale()
		local cam = workspace.CurrentCamera
		if cam then
			cam:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
		end
	end

	local scrim = mk("Frame", {
		Name = "Scrim",
		BackgroundColor3 = Color3.fromRGB(8, 8, 10),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
	}, screen)

	-- The whole screen advances. No pixel-hunting a card corner -- that is the
	-- only thing that works on a phone, and it is what makes mashing possible.
	local capture = mk("TextButton", {
		Name = "Tap",
		BackgroundTransparency = 1,
		Text = "",
		TextSize = 14,
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
	}, screen)

	-- Stage holds the pack and the stack, and is what gets shaken. FX go in
	-- their own full-screen host so a flash never moves with the shake.
	local stage = mk("Frame", {
		Name = "Stage",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromScale(1, 0.82),
		ZIndex = 4,
	}, screen)
	local fxHost = mk("Frame", {
		Name = "FX",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 30,
	}, screen)

	local titleL = label(screen, "", 30, GOLD, UDim2.new(0, 0, 0, 62), UDim2.new(1, 0, 0, 38), FONT)
	titleL.ZIndex = 20
	--[[
		THE BIG MOMENT. A chase or god pull used to fire a separate full-screen
		"you found something crazy" overlay after the pack; it lives on the
		stage now, over the card that earned it, punching in as the card lands.
	]]
	local crazyL = mk("TextLabel", {
		Name = "Crazy",
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "",
		TextColor3 = GOLD,
		TextStrokeTransparency = 0.15,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 30),
		Size = UDim2.new(0.86, 0, 0, 50),
		Visible = false,
		ZIndex = 46,
	}, screen)
	crazyL.TextScaled = true
	local crazyScale = mk("UIScale", { Scale = 1 }, crazyL)
	-- Confetti rain across the whole screen. GOD pulls get a lot of it.
	local function confettiRain(col, n)
		for i = 1, n do
			local x = math.random()
			local bit = mk("Frame", {
				BackgroundColor3 = (i % 3 == 0) and Color3.new(1, 1, 1) or (i % 5 == 0) and GOLD or col,
				BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(x, -0.06),
				Size = UDim2.fromOffset(math.random(7, 12), math.random(12, 18)),
				Rotation = math.random(0, 180), ZIndex = 47,
			}, screen)
			local fall = 1.1 + math.random() * 1.2
			TweenService:Create(bit, TweenInfo.new(fall, Enum.EasingStyle.Linear), {
				Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.25, 1.15),
				Rotation = bit.Rotation + math.random(240, 900),
				BackgroundTransparency = 0.2,
			}):Play()
			task.delay(fall + 0.1, function()
				if bit.Parent then bit:Destroy() end
			end)
		end
	end

	local function showCrazy(col, band)
		confettiRain(col, (band == "GOD") and 120 or 60)
		if Audio.playCard then
			-- Extra sting on the crazy banner (flip already fired).
			if band == "GOD" then
				Audio.play("pack_burst", 0.9)
				Audio.play("pack_sparkle", 0.8, 1.2, nil, true)
			else
				Audio.play("rare", 0.85)
			end
		end
		crazyL.Text = (band == "GOD") and "YOU FOUND SOMETHING CRAZY" or "CRAZY PULL!"
		crazyL.TextColor3 = (band == "GOD") and Color3.new(1, 1, 1):Lerp(col, 0.3) or GOLD
		crazyL.TextStrokeColor3 = col:Lerp(Color3.new(0, 0, 0), 0.55)
		crazyL.Visible = true
		crazyScale.Scale = 0.25
		TweenService:Create(crazyScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		if band == "GOD" then
			task.delay(0.32, function()
				if crazyL.Visible then
					crazyScale.Scale = 1.12
					TweenService:Create(crazyScale, TweenInfo.new(0.18), { Scale = 1 }):Play()
				end
			end)
		end
	end
	local function hideCrazy()
		crazyL.Visible = false
	end
	local subL = label(screen, "", 15, MUTED, UDim2.new(0, 0, 0, 100), UDim2.new(1, 0, 0, 22))
	subL.ZIndex = 20
	-- Bottom of the screen, read upward: prompt (-106..-30), hint, counter,
	-- then the tray. Each band clears the one below it -- the first pass had
	-- the hint printing behind the button row.
	local recapL = label(screen, "", 13, MUTED, UDim2.new(0, 0, 1, -330), UDim2.new(1, 0, 0, 18), FONT)
	recapL.ZIndex = 20
	recapL.Visible = false
	local counterL = label(screen, "", 15, MUTED, UDim2.new(0, 0, 1, -164), UDim2.new(1, 0, 0, 20))
	counterL.ZIndex = 20
	local hintL = label(screen, "", 16, TEXT, UDim2.new(0, 0, 1, -138), UDim2.new(1, 0, 0, 24))
	hintL.ZIndex = 20

	-- Set by SKIP ALL. awaitTap honours it, so a run in flight races to the end
	-- instead of being torn down mid-tween.
	local skipAll = false
	--[[
		SKIP ALL -- the lucky-block bargain.

		Open-all used to decide for you: first it forced eight taps, then it
		skipped everything. Neither is right. Tap through them if you want to
		see them land; press this and the run flies to the end. Either way it
		finishes on the full grid, so nothing is ever hidden from you.
	]]
	local skipBtn = mk("TextButton", {
		Name = "SkipAll",
		Visible = false,
		AutoButtonColor = true,
		BackgroundColor3 = Color3.fromRGB(70, 74, 88),
		BorderSizePixel = 0,
		Font = FONT,
		TextSize = 20,
		TextColor3 = Color3.fromRGB(240, 242, 250),
		Text = "SKIP ALL",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -76),
		Size = UDim2.fromOffset(240, 52),
		ZIndex = 30,
	}, screen)
	mk("UICorner", { CornerRadius = UDim.new(0, 12) }, skipBtn)
	skipBtn.MouseButton1Click:Connect(function()
		skipAll = true
		rush = true
	end)

	-- Cards already pulled, laid along the bottom so the pack reads as progress.
	local tray = mk("Frame", {
		Name = "Tray",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -196),
		Size = UDim2.fromOffset(1180, 124),
		ZIndex = 8,
	}, screen)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tray)

	--[[
		EVERY HIT, NOT A SAMPLE.

		Open-all first showed the best twelve and counted the rest. In a game
		about collecting, hiding what you just pulled is the one thing the
		screen must not do -- "37 more in your bag" is a receipt, not a reveal.

		So: a scrolling grid that holds all of them. Faces are painted a few per
		frame rather than all at once, because paintCard can build a
		ViewportFrame each and doing ninety in one frame is a visible hitch. The
		slots all exist immediately, so the count is honest from the first
		frame and the art fills in behind it.
	]]
	local hitsHost = mk("ScrollingFrame", {
		Name = "Hits",
		Visible = false,
		Active = true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 140),
		Size = UDim2.new(1, -120, 1, -320),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 9,
	}, screen)
	mk("UIGridLayout", {
		CellSize = UDim2.fromOffset(RECAP_W, RECAP_H),
		CellPadding = UDim2.fromOffset(10, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, hitsHost)
	mk("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, hitsHost)

	local prompt = mk("Frame", {
		Name = "Prompt",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 60),
		Size = UDim2.fromOffset(660, 76),
		Visible = false,
		ZIndex = 25,
	}, screen)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
	}, prompt)

	----------------------------------------------------------------------------
	-- Tap plumbing.
	--
	-- One tap does one thing: if something is animating it finishes it,
	-- otherwise it advances. Mashing therefore races the reveal forward at one
	-- step per tap rather than queueing clicks that keep firing afterwards.
	----------------------------------------------------------------------------
	local pending = false
	local busy = false
	local lastTap = 0
	local rush = false
	-- A recap card blown back up in the middle (see focusRecap), or nil.
	local focus = nil
	-- The run on stage is a forced one (a chest find): it plays itself and a
	-- tap only makes it go faster. See AUTO_PULL.
	local auto = false
	-- Runs waiting for the stage, whether one is playing, and the prompt the
	-- screen settles on once the queue is empty (see ctl.play).
	local queue = {}
	local playing = false
	local settleMeta = nil

	local function tap()
		-- While a pulled card is up for a look, a tap (or Space) puts it back.
		-- It must never also buy the next pack underneath it.
		if focus then
			focus.close()
			return
		end
		local now = os.clock()
		-- Two taps inside the window means the player is mashing. Rush mode
		-- shortens every tween and mutes the low-tier flashes so a masher is
		-- not strobed; it decays as soon as they slow down.
		rush = (now - lastTap) < RUSH_WINDOW
		lastTap = now
		pending = true
	end
	capture.MouseButton1Click:Connect(tap)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not screen.Enabled then
			return
		end
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return then
			tap()
		end
	end)

	local function timings()
		return rush and RUSH or SAVOR
	end

	local function takeTap()
		if pending then
			pending = false
			return true
		end
		return false
	end

	-- Wait for a tap. `maxWait` is only ever a backstop against a lost input --
	-- it is deliberately long, because an auto-advance that beats the player to
	-- the card is the exact thing this rebuild exists to remove.
	local function awaitTap(maxWait)
		local t = 0
		while true do
			if skipAll then
				return true
			end
			if takeTap() then
				return true
			end
			t += task.wait()
			if maxWait and t >= maxWait then
				return false
			end
		end
	end

	-- A tween a tap can cut short. Cancelling leaves the property part-way, so
	-- the goal is written directly instead -- "faster" has to land in the same
	-- place as "wait", or mashing would desync the layout.
	local function anim(obj, time, style, dir, goal)
		if not obj or not obj.Parent then
			return true
		end
		if time <= 0 then
			for k, v in pairs(goal) do
				obj[k] = v
			end
			return false
		end
		local tw = TweenService:Create(obj,
			TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
		tw:Play()
		local elapsed = 0
		while elapsed < time do
			elapsed += task.wait()
			if not obj.Parent then
				return true
			end
			if pending then
				-- Do NOT consume the tap here: finishing this tween and taking
				-- the next step are one action from the player's point of view.
				tw:Cancel()
				for k, v in pairs(goal) do
					obj[k] = v
				end
				return true
			end
		end
		return false
	end

	----------------------------------------------------------------------------
	-- Card faces.
	--
	-- P0: a face is NEVER mounted at zero size. paintCard puts a ViewportFrame
	-- inside, and a viewport fits its camera off AbsoluteSize -- at zero it
	-- clamps to 1x1 and can come back blank. So the face is always built at its
	-- final pixel size and hidden with a UIScale, which does not change
	-- AbsoluteSize until it animates.
	----------------------------------------------------------------------------
	--[[
		Solve for HEIGHT, not width.

		The first pass sized off width and capped it at 320px, which on a tall
		screen produced a 448px card -- smaller than the 600px pack it had just
		torn out of. A pack that shrinks into its own contents kills the moment,
		so the card is sized as a share of the screen first and only narrowed
		afterwards if a portrait phone cannot fit it.
	]]
	local function cardSize()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local s = math.max(0.45, revealScale.Scale)
		local h = math.clamp(math.floor((vp.Y * 0.46) / s), 220, 620)
		local w = math.floor(h / 1.4)
		w = math.min(w, math.floor((vp.X * 0.78) / s))
		return w, math.floor(w * 1.4)
	end

	-- If the renderer throws or the model comes back degenerate, the player
	-- still gets a card -- rarity-coloured, named, and obviously deliberate.
	-- A blank hole in a pack reads as a bug; this reads as art pending.
	local function fallbackFace(parent, card, w, h)
		local col = rarityColour(card)
		local f = mk("Frame", {
			Name = "FallbackFace",
			BackgroundColor3 = BG2,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(w, h),
			ZIndex = 14,
		}, parent)
		round(f, 12)
		stroke(f, 3, col, 0.1)
		local badge = mk("Frame", {
			BackgroundColor3 = col,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.42),
			Size = UDim2.fromOffset(math.floor(w * 0.45), math.floor(w * 0.45)),
			Rotation = 45,
			ZIndex = 15,
		}, f)
		round(badge, 14)
		local nm = label(f, tostring(card and card.name or "Unknown"), 17, TEXT,
			UDim2.new(0, 6, 0.68, 0), UDim2.new(1, -12, 0, 24), FONT)
		nm.ZIndex = 16
		local rr = label(f, string.upper(tostring(card and card.rarityId or "")), 13, col,
			UDim2.new(0, 6, 0.78, 0), UDim2.new(1, -12, 0, 18))
		rr.ZIndex = 16
		local note = label(f, "ART MISSING", 11, MUTED, UDim2.new(0, 6, 0.86, 0), UDim2.new(1, -12, 0, 16))
		note.ZIndex = 16
		return f
	end

	local function buildFace(parent, card, w, h)
		local ok, painted = pcall(function()
			return opts.paintCard and opts.paintCard(parent, card, w) or nil
		end)
		if ok and typeof(painted) == "Instance" and painted:IsA("GuiObject") then
			painted.AnchorPoint = Vector2.new(0.5, 0.5)
			painted.Position = UDim2.fromScale(0.5, 0.5)
			return painted
		end
		if not ok then
			warn("[PackReveal] paintCard failed for " .. tostring(card and card.name) .. ": " .. tostring(painted))
		end
		return fallbackFace(parent, card, w, h)
	end

	local function trayChip(card)
		local col = rarityColour(card)
		local chip = mk("Frame", {
			BackgroundColor3 = BG2,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(64, 90),
			ZIndex = 9,
		}, tray)
		round(chip, 8)
		stroke(chip, 2, col, 0.2)
		mk("Frame", {
			BackgroundColor3 = col,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 7),
			ZIndex = 10,
		}, chip)
		local nm = label(chip, tostring(card and card.name or ""), 12, TEXT,
			UDim2.fromOffset(3, 16), UDim2.new(1, -6, 1, -20))
		nm.TextWrapped = true
		nm.ZIndex = 10
		local sc = mk("UIScale", { Scale = 0.2 }, chip)
		TweenService:Create(sc, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		return chip
	end

	--[[
		Clear the CONTENTS, keep the layout.

		This tested for UIListLayout by name, so it swept away every other
		layout component too -- the hits grid's UIGridLayout and UIPadding went
		with the cards on the first clear, and every pull after that piled up in
		one corner. Anything that is not a GuiObject is scaffolding (layouts,
		padding, constraints, aspect ratios) and stays.
	]]
	local function clear(host)
		for _, c in ipairs(host:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
	end

	--[[
		A PULLED CARD, BACK UP IN THE MIDDLE.

		Every card in the "YOU PULLED" strip is the real card face, only scaled
		down (see THE CARD GOES TO THE RECAP), so picking one up lifts that same
		face out of the strip and lets its scale return to 1 -- nothing is rebuilt,
		no ViewportFrame is made twice. A tap anywhere puts it back where it was.
	]]
	local focusHost = mk("TextButton", {
		Name = "Focus",
		BackgroundColor3 = Color3.fromRGB(4, 4, 6),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 60,
	}, screen)
	local focusHint = label(focusHost, "TAP TO PUT IT BACK", 15, MUTED, UDim2.new(0, 0, 1, -60), UDim2.new(1, 0, 0, 22))
	focusHint.ZIndex = 61

	local function focusRecap(slot)
		local face = slot and slot:FindFirstChild("Card")
		if focus or not face then
			return
		end
		local shrink = face:FindFirstChildOfClass("UIScale")
		local small = shrink and shrink.Scale or 1
		local grow
		face.Parent = focusHost
		face.AnchorPoint = Vector2.new(0.5, 0.5)
		face.Position = UDim2.fromScale(0.5, 0.47)
		-- The hint sits just under the card, clear of the button row.
		focusHint.Position = UDim2.new(0, 0, 0.47, math.floor(face.Size.Y.Offset / 2) + 14)
		if shrink then
			grow = TweenService:Create(shrink,
				TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
			grow:Play()
		end
		focusHost.Visible = true
		focus = {}
		function focus.close()
			focus = nil
			focusHost.Visible = false
			-- Stop the grow first, or it keeps writing Scale after the card is
			-- back in the strip and the strip card swells to full size.
			if grow then
				grow:Cancel()
			end
			if face.Parent ~= focusHost then
				return
			end
			if slot.Parent then
				face.Parent = slot
				face.Position = UDim2.fromScale(0.5, 0.5)
				if shrink then
					shrink.Scale = small
				end
			else
				face:Destroy()
			end
		end
	end
	focusHost.MouseButton1Click:Connect(function()
		if focus then
			focus.close()
		end
	end)

	----------------------------------------------------------------------------
	-- ONE PACK.
	--
	-- Returns true if it ran, false if the pack was empty and the caller should
	-- bail out instead of sitting on a black stage.
	----------------------------------------------------------------------------
	local function playPack(pack, indexInRun, runLength)
		-- Tear / rise already played in MinePackFX.playPackCeremony.
		Audio.play("pack_sparkle", 0.7)
		local cards = pack.cards or {}
		local art = PackFX.art(pack.packId)
		clear(stage)
		clear(fxHost)
		if focus then
			focus.close()
		end
		clear(tray)
		clear(hitsHost)
		hitsHost.Visible = false
		recapL.Visible = false

		titleL.Text = string.upper(tostring(pack.name or "Booster Pack"))
		titleL.TextColor3 = art.accent or GOLD
		subL.Text = (runLength > 1)
			and string.format("%s   --   pack %d of %d", tostring(pack.setName or ""), indexInRun, runLength)
			or tostring(pack.setName or "")
		counterL.Text = ""

		-- P0: an empty payload is a bug, not a ceremony. Say so and get out
		-- rather than leaving the player staring at a scrim.
		if #cards == 0 then
			hintL.Text = ""
			if opts.onToast then
				opts.onToast("Pack was empty -- tell us")
			end
			return false
		end

		------------------------------------------------------------------------
		-- 0. BUILD THE FACES NOW, WHILE THE TEAR IS PLAYING.
		--
		-- A card face is a ViewportFrame with a pet model inside it, and
		-- building that model is the expensive part of this entire screen.
		-- Doing it at flip time meant the card turned over and the art landed a
		-- beat later -- which is the exact moment the player is looking
		-- hardest. Art that arrives late makes even good effects read as
		-- broken, so no amount of FX polish fixes it; the build has to move.
		--
		-- The tear is ~1.7s of tweening that needs almost no CPU. The faces are
		-- built into a hidden bin across those frames, one per frame so nothing
		-- hitches, and the flip then only has to reparent something that
		-- already exists and is already laid out.
		------------------------------------------------------------------------
		local w, h = cardSize()
		local faceBin = mk("Frame", {
			Name = "FaceBin",
			BackgroundTransparency = 1,
			Visible = false,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(w, h),
			ZIndex = 2,
		}, stage)
		local faces = {}
		local facesBuilt = 0
		task.spawn(function()
			for i, card in ipairs(cards) do
				if not faceBin.Parent then
					return
				end
				local holder = mk("Frame", {
					Name = "Face" .. i,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(w, h),
					ZIndex = 18,
				}, faceBin)
				buildFace(holder, card, w, h)
				faces[i] = holder
				facesBuilt += 1
				task.wait()
			end
		end)

		------------------------------------------------------------------------
		-- 1. THE TEAR. Big pack, and the first tap skips straight to the stack.
		------------------------------------------------------------------------
		--[[
			The pack has to OWN the frame.

			playPackOpen draws at a fixed 280x400, which is a sensible number on
			a 720p window and a postage stamp on a big one -- the first beat of
			the ceremony was reading as a small object floating in a lot of
			empty screen. Rather than hardcode a second set of sizes inside the
			FX module, the whole ceremony is scaled here to a share of the
			viewport height, anchored centre so it grows about its own middle.
		]]
		local ceremonyHost = mk("Frame", {
			Name = "Ceremony",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 5,
		}, stage)
		do
			local cam = workspace.CurrentCamera
			local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
			-- 400 is playPackOpen's own pack height; solve for a pack that is
			-- a little over half the screen, and never wider than it fits.
			local byHeight = (vp.Y * 0.56) / 400
			local byWidth = (vp.X * 0.42) / 280
			mk("UIScale", { Scale = math.clamp(math.min(byHeight, byWidth), 0.65, 2.6) }, ceremonyHost)
		end
		hintL.Text = auto and "TAP TO SKIP" or "TAP TO RIP"
		local torn = false
		local thread = task.spawn(function()
			pcall(PackFX.playPackOpen, ceremonyHost, {
				packId = pack.packId,
				name = pack.name,
				setName = pack.setName,
				crestImage = pack.crestImage,
			})
			torn = true
		end)
		while not torn do
			if takeTap() then
				pcall(task.cancel, thread)
				break
			end
			task.wait()
		end
		-- Finally-style: the ceremony host goes whether it finished, was
		-- skipped, or threw. The stack is never blocked by the tear.
		ceremonyHost:Destroy()

		------------------------------------------------------------------------
		-- 2. THE STACK. Cards one in front of another, deepest first so the
		--    top card owns the highest ZIndex.
		------------------------------------------------------------------------
		local stackHost = mk("Frame", {
			Name = "Stack",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(w, h),
			ZIndex = 6,
		}, stage)

		--[[
			Depth has to be obvious or it is not depth.

			The first pass offset each card behind the top by 13px and 4%, which
			at a glance was one brown slab with a rounded corner -- no sense that
			there was anything underneath. Bigger steps, a real tilt, and each
			card behind darkened toward black so the stack has shading rather
			than being the same colour repeated.
		]]
		--[[
			A CARD BACK, NOT A COLOURED SLAB.

			The first version filled the whole card with the pack's primary
			colour and put one rotated square in the middle of it. Blown up to
			half the screen that is a wall of flat green with a green diamond
			on it -- no depth, no detail, and the diamond barely reads against
			its own background.

			What makes a card back look like a card back is layering: a dark
			ground so the accent has something to sit against, a gradient so it
			is not one flat fill, a border inset from the edge, and a centred
			emblem that is small relative to the card rather than filling it.
		]]
		local backs = {}
		local base = art.primary or BG2
		local ground = base:Lerp(Color3.new(0, 0, 0), 0.62)
		local accent = art.accent or GOLD
		for i = #cards, 1, -1 do
			local depth = math.min(i - 1, 4)
			local z = 6 + (#cards - i)
			local back = mk("Frame", {
				Name = "Back" .. i,
				BackgroundColor3 = ground:Lerp(Color3.new(0, 0, 0), depth * 0.14),
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				-- Flat stack: depth via Y offset + scale only (no diagonal lean).
				Position = UDim2.new(0.5, 0, 0.5, depth * 14),
				Size = UDim2.fromOffset(w, h),
				Rotation = 0,
				ZIndex = z,
			}, stackHost)
			round(back, 16)
			mk("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(base:Lerp(Color3.new(1, 1, 1), 0.08), ground),
			}, back)
			stroke(back, 3, accent:Lerp(ground, depth / 5), 0.08 + depth * 0.16)
			mk("UIScale", { Scale = 1 - depth * 0.07 }, back)
			backs[i] = back

			-- Only the top card earns the detail; the rest are edges.
			if depth == 0 then
				local inset = mk("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(1, -28, 1, -28),
					ZIndex = z + 1,
				}, back)
				round(inset, 12)
				stroke(inset, 2, accent, 0.55)

				local ringW = math.floor(w * 0.40)
				local ring = mk("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.47),
					Size = UDim2.fromOffset(ringW, ringW),
					ZIndex = z + 2,
				}, back)
				round(ring, 999)
				stroke(ring, 3, accent, 0.22)

				local diaW = math.floor(w * 0.19)
				local dia = mk("Frame", {
					BackgroundColor3 = accent,
					BackgroundTransparency = 0.18,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.47),
					Size = UDim2.fromOffset(diaW, diaW),
					Rotation = 45,
					ZIndex = z + 3,
				}, back)
				round(dia, 6)

				-- Corner pips: cheap, and they stop the border reading as a
				-- plain rectangle.
				for _, corner in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
					local pip = mk("Frame", {
						BackgroundColor3 = accent,
						BackgroundTransparency = 0.45,
						BorderSizePixel = 0,
						AnchorPoint = Vector2.new(corner[1], corner[2]),
						Position = UDim2.fromScale(corner[1], corner[2]),
						Size = UDim2.fromOffset(10, 10),
						Rotation = 45,
						ZIndex = z + 2,
					}, inset)
				end

				-- A soft diagonal sheen, so the ground is not dead flat.
				local sheen = mk("Frame", {
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					Size = UDim2.fromScale(1, 1),
					ZIndex = z + 1,
				}, back)
				round(sheen, 16)
				mk("UIGradient", {
					Rotation = 32,
					Color = ColorSequence.new(Color3.new(1, 1, 1)),
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(0.42, 1),
						NumberSequenceKeypoint.new(0.5, 0.88),
						NumberSequenceKeypoint.new(0.58, 1),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}, sheen)
			end
		end

		------------------------------------------------------------------------
		-- 3. THE PULL.
		--
		-- TWO TAPS PER CARD. The first pushes the card up out of the stack and
		-- turns it over; the second clears it away and settles the next one to
		-- the top.
		--
		-- Bundling both into one tap meant the click that revealed a card was
		-- also the click that destroyed the previous one -- so the card you had
		-- just pulled vanished at the exact moment you decided to look at it.
		------------------------------------------------------------------------
		for i, card in ipairs(cards) do
			counterL.Text = i .. " / " .. #cards
			hintL.Text = auto and "TAP TO SKIP" or "TAP TO PULL"

			--------------------------------------------------------------------
			-- BEAT ZERO -- the grade climb, for anything that has one.
			--
			-- Gear rolls its grade as a Clash Royale ladder on the server
			-- (MineToolGrades.rollClash) and ships the step list on the item as
			-- `gradeRoll`. The animation for it has sat in MineGradeReveal this
			-- whole time and NOTHING EVER CALLED IT, so a hat crate opened with
			-- the same flat flip as a card pack and the climb -- the entire
			-- reason a hat's grade is exciting -- was invisible.
			--
			-- Tapping rushes it, like every other beat on this screen.
			--------------------------------------------------------------------
			if type(card.gradeRoll) == "table" then
				local okGrade, gradeErr = pcall(GradeReveal.play, stage, card.gradeRoll, {
					rush = rush or auto,
					shouldSkip = function()
						return rush
					end,
					zIndex = 60,
				})
				if not okGrade then
					warn("[PackReveal] grade reveal " .. tostring(gradeErr))
				end
			end

			--------------------------------------------------------------------
			-- BEAT ONE -- push it up, turn it over.
			--------------------------------------------------------------------
			awaitTap(auto and AUTO_PULL or nil)

			-- Gear flips exactly like a card. It used to stop first for a
			-- Clash-Royale "GRADE ROLL" climb before every piece, which turned a
			-- five-piece vault into five cutscenes. The letter was decided on the
			-- server either way; the face shows it.

			local t = timings()
			local back = backs[i]
			local grade, band = PackFX.pullScore(card, Cards)
			local col = rarityColour(card)

			-- TENSION is an OFFER. Rush mode sets t.tension to zero, and a tap
			-- mid-pulse cuts it short through anim() -- never a cutscene.
			if t.tension > 0 and (band == "HIT" or band == "CHASE" or band == "GOD") then
				local pulse = back and back:FindFirstChildOfClass("UIScale")
				if pulse then
					local hold = (band == "GOD") and t.tension * 2 or t.tension
					if band ~= "HIT" then
						Audio.play("riser")
					end
					-- The back glows the rarity colour while it shivers.
					local bs = back:FindFirstChildOfClass("UIStroke")
					if bs then
						TweenService:Create(bs, TweenInfo.new(hold * 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 1, true), {
							Color = col, Transparency = 0, Thickness = 6,
						}):Play()
					end
					anim(pulse, hold, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, { Scale = 1.07 })
				end
			end

			-- Lift the back out of the stack, then turn it over.
			if back and back.Parent then
				anim(back, t.lift, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
					Position = UDim2.new(0.5, 0, 0.5, -26),
				})
				anim(back, t.flip * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {
					Size = UDim2.fromOffset(math.floor(w * 0.08), h),
					Rotation = 0,
				})
				back:Destroy()
			end

			-- The face was built during the tear. All that happens here is a
			-- reparent: no model construction, no camera fit, no waiting a
			-- frame for layout -- it is already sized and already solved, so it
			-- is on screen the instant the back comes off.
			local centre = faces[i]
			if not centre or not centre.Parent then
				-- Only if the prebuild has not reached this card yet, which can
				-- only happen on a pack ripped faster than its own tear.
				centre = mk("Frame", {
					Name = "Centre",
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(w, h),
					ZIndex = 18,
				}, stackHost)
				buildFace(centre, card, w, h)
			end
			centre.Name = "Centre"
			centre.Parent = stackHost
			centre.Position = UDim2.new(0.5, 0, 0.5, -26)
			centre.Visible = true
			centre.ZIndex = 18
			local cs = centre:FindFirstChildOfClass("UIScale") or mk("UIScale", {}, centre)
			cs.Scale = 0.86
			if Audio.playCard then
				Audio.playCard(band)
			else
				Audio.play("flip")
				if band == "GOD" then
					Audio.play("jackpot")
					Audio.play("flash")
				elseif band == "CHASE" then
					Audio.play("rare")
					Audio.play("reveal")
				elseif band == "HIT" then
					Audio.play("reveal")
				elseif band == "NICE" then
					Audio.play("thud", 0.6)
				end
			end
			anim(cs, t.flip, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
			if tonumber(card.oneIn) and not centre:FindFirstChild("OddsRibbon") then
				oddsRibbon(centre, tonumber(card.oneIn), col, w, h)
			end

			-- And the screen reacts in proportion to what it actually is.
			-- Mashing mutes the small stuff so nobody gets strobed for commons.
			local quiet = rush and (band == "DUD" or band == "NICE")
			if not quiet then
				PackFX.playPullHit(fxHost, band, col, stage)
			end
			if band == "GOD" or band == "CHASE" then
				titleL.Text = string.upper(tostring(card.name or ""))
				titleL.TextColor3 = col
				-- Legendary and up, or anything the odds call a god pull.
				local rank = (Cards.RARITY_RANK and Cards.RARITY_RANK[card.rarityId or ""]) or 1
				if band == "GOD" or rank >= 5 then
					showCrazy(col, band)
				end
				-- GOD tints the whole scrim toward the rarity for a beat.
				if band == "GOD" then
					scrim.BackgroundColor3 = col:Lerp(Color3.fromRGB(8, 8, 10), 0.72)
					task.delay(0.35, function()
						TweenService:Create(scrim, TweenInfo.new(0.4), {
							BackgroundColor3 = Color3.fromRGB(8, 8, 10),
						}):Play()
					end)
				end
			end
			--[[
				THE PROTECTED WINDOW.

				A plain wait, not anim(), because anim() is interruptible and
				this one beat is deliberately not. Then every tap banked during
				it is thrown away.

				That second line is the part that actually does the work. The
				flag is sticky, so without clearing it a player mashing through
				a pack banks a tap during the hold and it fires the instant the
				wait ends -- the Exotic gets cleared by a click aimed at the
				card before it. Dropping those taps means the next beat needs a
				fresh, deliberate one.
			]]
			local hold = holdFor(card, band)
			if hold > 0 then
				task.wait(hold)
				pending = false
			end

			--------------------------------------------------------------------
			-- BEAT TWO -- clear it, and settle the stack behind it.
			--------------------------------------------------------------------
			if auto then
				hintL.Text = "TAP TO SKIP"
				awaitTap(tonumber(card.oneIn) and AUTO_LOOK_RARE or AUTO_LOOK)
			else
				hintL.Text = (i < #cards) and "TAP TO DRAW NEXT" or "TAP TO FINISH"
				awaitTap()
			end
			hideCrazy()
			t = timings()
			if centre and centre.Parent then
				anim(centre, t.out, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {
					Position = UDim2.new(0.5, 0, 1.35, 0),
					Rotation = 12,
				})
				--[[
					THE CARD GOES TO THE RECAP, IT IS NOT THROWN AWAY.

					This used to Destroy the face and drop a chip with the card's
					name into the tray, which meant the end of a pack was a list
					of words -- you could not see what you had pulled without
					going to the binder.

					The face is already built and already laid out, so moving it
					costs nothing: reparent it into a recap slot and scale it
					down. Rebuilding eight ViewportFrames at the end of a pack
					would hitch on the exact frame the player is trying to read.
				]]
				local slot = mk("Frame", {
					Name = "Recap" .. i,
					BackgroundTransparency = 1,
					LayoutOrder = i,
					Size = UDim2.fromOffset(RECAP_W, RECAP_H),
					ZIndex = 9,
					ClipsDescendants = false,
				}, tray)
				--[[
					Kill the in-flight out-tween so it cannot overwrite Position
					and Rotation after we flatten the card into the strip.

					The old line built a NEW empty tween and cancelled that — a
					no-op — so the out-tween (Position 1.35 / Rotation 12) kept
					writing for a frame or two after the reparent, and every card
					in the recap tray sat low and slanted. Playing a zero-length
					tween ON THE SAME PROPERTIES takes them over (Roblox cancels
					the older tween per property) and completes instantly.
				]]
				pcall(function()
					TweenService:Create(centre, TweenInfo.new(0), {
						Position = UDim2.fromScale(0.5, 0.5),
						Rotation = 0,
					}):Play()
				end)
				for _, d in ipairs(centre:GetDescendants()) do
					if d:IsA("UIScale") then
						d:Destroy()
					end
				end
				local oldScale = centre:FindFirstChildOfClass("UIScale")
				if oldScale then
					oldScale:Destroy()
				end
				centre.Parent = slot
				centre.Name = "Card"
				centre.AnchorPoint = Vector2.new(0.5, 0.5)
				centre.Position = UDim2.fromScale(0.5, 0.5)
				centre.Rotation = 0
				centre.Size = UDim2.fromOffset(w, h)
				local shrink = mk("UIScale", { Scale = RECAP_W / math.max(1, w) }, centre)
				-- A small pop as it lands, so the strip visibly grows.
				local pop = mk("UIScale", { Scale = 0.5 }, slot)
				TweenService:Create(pop, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
				-- A rarity edge, because at this size the card art alone does
				-- not say how good it was.
				local edge = mk("Frame", {
					BackgroundColor3 = rarityColour(card),
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 1, 0),
					Size = UDim2.new(1, -6, 0, 4),
					ZIndex = 12,
				}, slot)
				round(edge, 2)
				-- Belt and braces: one frame later, re-assert the flattened pose
				-- in case anything else was still animating this card.
				task.defer(function()
					if centre and centre.Parent == slot then
						centre.Position = UDim2.fromScale(0.5, 0.5)
						centre.Rotation = 0
					end
				end)
			end

			-- Everything still in the stack shuffles up one place. Without this
			-- the remaining cards stay pinned at their original depth and the
			-- pile visibly fails to shrink as it empties.
			for j = i + 1, #cards do
				local b = backs[j]
				if b and b.Parent then
					local d = math.min(j - i - 1, 4)
					local sc = b:FindFirstChildOfClass("UIScale")
					local step = TweenInfo.new(0.16, Enum.EasingStyle.Quad)
					-- Flat stack: no diagonal lean. Depth is scale + slight Y only.
					TweenService:Create(b, step, {
						Position = UDim2.new(0.5, 0, 0.5, d * 10),
						Rotation = 0,
					}):Play()
					if sc then
						TweenService:Create(sc, step, { Scale = 1 - d * 0.065 }):Play()
					end
				end
			end
			hintL.Text = ""
		end

		hintL.Text = ""
		counterL.Text = ""
		return true
	end

	----------------------------------------------------------------------------
	-- The prompt: the run ends with another run one tap away, not a closed menu.
	----------------------------------------------------------------------------
	local function button(text, colour, textColour, fn)
		local b = mk("TextButton", {
			AutoButtonColor = true,
			BackgroundColor3 = colour,
			Font = FONT,
			TextSize = 17,
			TextColor3 = textColour,
			Text = text,
			Size = UDim2.fromOffset(math.max(150, #text * 11 + 40), 48),
			ZIndex = 26,
		}, prompt)
		round(b, 10)
		b.MouseButton1Click:Connect(fn)
		return b
	end

	local finish
	-- Bumped every time the prompt is replaced or the reveal closes. The
	-- keep-tapping waiter below captures it and refuses to act if it has moved.
	local promptGen = 0

	--[[
		TAP ANYWHERE TO CLOSE. Owner, 2026-10-04: "PACKS MAKE YOU SAY DONE
		RATHER THAN AUTOMATICALLY CLOSING OUT AFTER YOU CLICK ANYWHERE ON THE
		SCREEN".

		A full-screen button behind the prompt row. ZIndex 24 against the
		prompt's 25, so OPEN ANOTHER and GET MORE PACKS still take the tap that
		lands on them -- this only catches the ones that miss, which is most of
		them.

		Built HERE and not beside the prompt frame itself, because `finish` is a
		local declared on the line above. A closure written further up the file
		would compile as a global read and be nil when tapped, which is the trap
		this project has already paid for twice.
	]]
	local dismiss = mk("TextButton", {
		Name = "TapAnywhere",
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 24,
	}, screen)
	dismiss.MouseButton1Click:Connect(function()
		if finish then
			finish()
		end
	end)
	-- The prompt is the only thing that turns this on, so it can never eat a
	-- tap during the reveal itself.
	prompt:GetPropertyChangedSignal("Visible"):Connect(function()
		dismiss.Visible = prompt.Visible
	end)

	local function showPrompt(meta)
		promptGen += 1
		local gen = promptGen
		for _, c in ipairs(prompt:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local packId = meta and meta.packId or nil
		local left = tonumber(meta and meta.left) or 0
		local titleOverride = (meta and (meta.title or meta.name)) or nil
		-- Forced rare finds (chest tools / charms) pass their own title; real packs stay PACK CLEARED.
		local isForcedFind = packId == "meadow_pack_legendary" or packId == "meadow_pack_rare"
			or (type(titleOverride) == "string" and (
				titleOverride == "RARE FIND" or titleOverride == "CHARM"
				or titleOverride == "BONKERS PACK" or titleOverride == "PROTOTYPE CRATE"
			))
		titleL.Text = (isForcedFind and type(titleOverride) == "string" and titleOverride ~= "") and titleOverride or "PACK CLEARED"
		titleL.TextColor3 = GOLD

		-- Pin the pack this prompt is for. Continue-open must not drift onto
		-- whatever stack was tapped next from the bag underneath.
		local function askMore(count)
			if type(packId) ~= "string" or packId == "" or packId == "bulk_hits" then
				return
			end
			-- Kill the tap-for-another waiter and hide the sheet before the
			-- next run lands, so a mash cannot double-fire or swap packs.
			promptGen += 1
			prompt.Visible = false
			hintL.Text = ""
			if opts.onOpenMore then
				opts.onOpenMore(packId, count)
			end
		end

		if left > 0 then
			button("OPEN ANOTHER", GREEN, Color3.fromRGB(10, 26, 16), function()
				askMore(1)
			end)
			if left > 1 then
				local many = math.min(left, 10)
				button("OPEN " .. many .. "x", GOLD, Color3.fromRGB(28, 20, 8), function()
					askMore(many)
				end)
			end
			subL.Text = left .. " left"
		else
			-- Out of this pack. Not a dead end -- the obvious next step.
			button("GET MORE PACKS", GOLD, Color3.fromRGB(28, 20, 8), function()
				finish()
				if opts.onStore then
					opts.onStore()
				end
			end)
			subL.Text = "None left"
		end
		-- Kept as a visible affordance: tapping anywhere works, but a player
		-- who is looking for a button should find one.
		button("DONE", BG2, TEXT, function()
			finish()
		end)

		local pulled = 0
		for _, c in ipairs(tray:GetChildren()) do
			if c:IsA("Frame") then
				pulled += 1
			end
		end
		if pulled > 0 then
			recapL.Text = "YOU PULLED"
			recapL.Visible = true
		end
		-- Any card in the strip can be picked back up for a proper look. Only
		-- once the pack is done: mid-pack, a tap near the strip has to keep
		-- drawing cards for someone mashing through it.
		for _, c in ipairs(tray:GetChildren()) do
			if c:IsA("Frame") and c:FindFirstChild("Card") and not c:FindFirstChild("Pick") then
				local pick = mk("TextButton", {
					Name = "Pick",
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 30,
				}, c)
				pick.MouseButton1Click:Connect(function()
					focusRecap(c)
				end)
			end
		end

		prompt.Visible = true
		prompt.Position = UDim2.new(0.5, 0, 1, 60)
		TweenService:Create(prompt, TweenInfo.new(0.22, Enum.EasingStyle.Back), {
			Position = UDim2.new(0.5, 0, 1, -30),
		}):Play()

		--[[
			KEEP TAPPING AND THE NEXT PACK JUST ARRIVES.

			The buttons are still there for a deliberate choice -- ten at once,
			the shop, or stopping -- but reaching for one breaks the rhythm of a
			player who is mashing through a stack. A tap anywhere that is not a
			button opens the next pack of the same kind, so the loop never makes
			you move the mouse to continue doing the thing you were doing.

			The buttons sit above this in ZIndex, so pressing DONE presses DONE;
			only the empty screen feeds you another.
		]]
		if left > 0 then
			hintL.Text = "TAP FOR ANOTHER"
			-- Same reasoning as the protected window: a tap banked while the
			-- last card was being looked at must not silently buy the next
			-- pack. The waiter below wants a fresh one.
			pending = false
			task.spawn(function()
				-- Stand down the moment the prompt is replaced (a chest find
				-- queued behind this pack, say) rather than eat the first tap
				-- meant for whatever took the stage.
				while gen == promptGen and screen.Enabled do
					if takeTap() then
						break
					end
					task.wait()
				end
				-- A stale waiter: the prompt was replaced, or the reveal closed
				-- while this was waiting.
				if gen ~= promptGen or not screen.Enabled or not prompt.Visible then
					return
				end
				askMore(1)
			end)
		end
	end

	finish = function()
		promptGen += 1
		prompt.Visible = false
		settleMeta = nil
		hideCrazy()
		-- Clearing the stage destroys the ViewportFrames and the WorldModels
		-- inside them. Leaving those parented is how a reveal leaks.
		clear(stage)
		clear(fxHost)
		if focus then
			focus.close()
		end
		clear(tray)
		clear(hitsHost)
		hitsHost.Visible = false
		titleL.Text = ""
		subL.Text = ""
		hintL.Text = ""
		counterL.Text = ""
		recapL.Visible = false
		scrim.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
		TweenService:Create(scrim, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
		local closing = promptGen
		task.delay(0.18, function()
			-- A run that started inside the fade owns the screen now.
			if promptGen == closing and not playing then
				screen.Enabled = false
			end
		end)
		if opts.onScreenOwned then
			pcall(opts.onScreenOwned, false)
		end
		busy = false
		-- The caller locked its Open buttons when the run started and has no
		-- other way to know the ceremony is over.
		if opts.onDone then
			task.spawn(opts.onDone)
		end
	end

	local ctl = {}

	function ctl.isBusy()
		return busy
	end

	-- Same as tapping the screen. Exists because Studio automation cannot
	-- deliver a synthetic click to a game GUI, so this is the only way to drive
	-- the ceremony end to end in a test. Harmless in play: it does exactly what
	-- a real tap does, and nothing calls it.
	function ctl.tap()
		tap()
	end

	--[[
		Bulk open (x10 / ALL): flash commons→rares on a timer, then stack
		Epic+ hits for tap-through like a normal pack.
	]]
	local function cardRank(card)
		return (Cards.RARITY_RANK and Cards.RARITY_RANK[(card and card.rarityId) or ""]) or 1
	end

	--[[
		WHAT EARNS A TAP ON OPEN ALL.

		The single-pack ceremony is the good part and stays exactly as it is.
		Open-all was the problem, and this is why: a "hit" was Epic+ OR anything
		carrying a "1 in X" -- and the server stamps oneIn on a great many pulls,
		so a fifty-pack run could hand you thirty-odd cards to tap through one at
		a time. Open-all was just running the single-pack ceremony thirty times.

		Legendary and better earns a tap outright. A oneIn only earns one past
		BULK_ONE_IN, which is the same 1-in-150 line MineServer already uses for
		"actually rare". Everything else lands in the bag exactly as before --
		the server granted it long ago; this screen only decides what you LOOK at.
	]]
	local BULK_MIN_RANK = 5 -- Legendary and better
	local BULK_ONE_IN = 150
	local BULK_TAP_MAX = 8 -- the most taps an open-all will ever ask of you

	local function isBulkHit(card)
		if cardRank(card) >= BULK_MIN_RANK then
			return true
		end
		local one = tonumber(card and card.oneIn)
		return one ~= nil and one >= BULK_ONE_IN
	end

	local function bulkAutoHold(card)
		local rank = cardRank(card)
		local fancy = (card and (card.shiny or card.shadow)) or ((card and card.variant or "Normal") ~= "Normal")
		if rank <= 1 then
			return fancy and 0.10 or 0.07
		elseif rank == 2 then
			return fancy and 0.13 or 0.11
		elseif rank == 3 then
			return 0.15 -- all rares
		end
		return 0.12
	end

	local function paintBulkFlash(host, card, w, h)
		clear(host)
		local col = rarityColour(card)
		local frame = mk("Frame", {
			Name = "BulkFlash",
			BackgroundColor3 = col:Lerp(Color3.fromRGB(12, 12, 16), 0.55),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 18,
		}, host)
		round(frame, 12)
		stroke(frame, 2, col)
		local nm = tostring(card and card.name or "?")
		local rar = tostring(card and (card.rarityId or card.rarity) or "")
		if card and card.shadow then
			rar = "Shadow " .. rar
		elseif card and card.shiny then
			rar = "Shiny " .. rar
		end
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 22,
			TextColor3 = Color3.fromRGB(245, 245, 250),
			Text = nm,
			TextWrapped = true,
			Size = UDim2.new(1, -20, 0, 70),
			Position = UDim2.new(0, 10, 0.38, 0),
			ZIndex = 19,
		}, frame)
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			TextSize = 14,
			TextColor3 = col,
			Text = string.upper(rar),
			Size = UDim2.new(1, -20, 0, 24),
			Position = UDim2.new(0, 10, 0.62, 0),
			ZIndex = 19,
		}, frame)
	end

	local function playBulk(run)
		local filler, hits = {}, {}
		local opened = 0
		for _, pack in ipairs(run) do
			if not pack.luckyBlock then
				opened += 1
				for _, card in ipairs(pack.cards or {}) do
					if isBulkHit(card) then
						table.insert(hits, card)
					else
						table.insert(filler, card)
					end
				end
			end
		end
		if opened == 0 and #filler == 0 and #hits == 0 then
			return false
		end

		clear(stage)
		clear(fxHost)
		if focus then
			focus.close()
		end
		clear(tray)
		clear(hitsHost)
		hitsHost.Visible = false
		recapL.Visible = false
		titleL.Text = "OPEN ALL"
		titleL.TextColor3 = GOLD
		subL.Text = string.format("%d packs  ·  %d cards  ·  %d hits", opened, #filler + #hits, #hits)
		hintL.Text = "AUTO"
		counterL.Text = ""
		rush = true
		-- Open-all is instant: skip the filler slideshow. Epic+ hits still
		-- get the normal tap-through so the pulls that matter stay visible.
		counterL.Text = (#filler > 0) and (tostring(#filler) .. " cleared") or ""
		hintL.Text = (#hits > 0) and (#hits .. " hits") or ""

		-- Best last across the whole run, by what the odds say it is.
		-- Celebration order first (the rarity ladder), then the true odds.
		local ORDER = PackFX.BAND_ORDER or {}
		local bandOf = {}
		for _, c in ipairs(hits) do
			local _, band = PackFX.pullScore(c, Cards)
			bandOf[c] = ORDER[band] or 1
		end
		table.sort(hits, function(x, y)
			if bandOf[x] ~= bandOf[y] then
				return bandOf[x] < bandOf[y]
			end
			local kx, ky = pullKey(x), pullKey(y)
			if kx ~= ky then
				return kx < ky
			end
			return tostring(x.name or "") < tostring(y.name or "")
		end)
		if #hits > 0 then
			rush = false
			pending = false
			skipAll = false
			titleL.Text = "YOUR HITS"
			subL.Text = string.format("%d hits  -  tap through, or skip", #hits)
			hintL.Text = ""
			counterL.Text = (#filler > 0) and (tostring(#filler) .. " cleared") or ""
			-- Tap through them one at a time; SKIP ALL races to the end.
			skipBtn.Text = string.format("SKIP ALL  (%d)", #hits)
			skipBtn.Visible = #hits > 1
			pcall(playPack, {
				cards = hits,
				name = "Hits",
				setName = string.format("%d from open-all", #hits),
				packId = "bulk_hits",
			}, 1, 1)
			skipBtn.Visible = false
			skipAll = false
			--[[
				AND IT ALWAYS ENDS ON THE FULL GRID.

				Whether they tapped every card or skipped the lot, the run finishes
				showing every hit at once. This is a collection game -- the one
				thing the screen must never do is hide what you just pulled.
			]]
			titleL.Text = "YOUR HITS"
			subL.Text = string.format("%d hits  -  all yours", #hits)
			hitsHost.CanvasPosition = Vector2.new(0, 0)
			hitsHost.Visible = true
			local slots = {}
			for i = #hits, 1, -1 do
				local slot = mk("Frame", {
					Name = "Hit" .. i,
					BackgroundTransparency = 1,
					LayoutOrder = #hits - i + 1,
					Size = UDim2.fromOffset(RECAP_W, RECAP_H),
					ZIndex = 9,
				}, hitsHost)
				slots[#slots + 1] = { slot = slot, card = hits[i] }
			end
			task.spawn(function()
				for i, row in ipairs(slots) do
					if not row.slot.Parent then
						return
					end
					pcall(buildFace, row.slot, row.card, RECAP_W, RECAP_H)
					if i % 6 == 0 then
						task.wait()
					end
				end
			end)
			return true
		end

		hintL.Text = ""
		counterL.Text = ""
		return true
	end

	--[[
		Play a run. `run` is an array of pack payloads; `meta` carries what is
		left of that pack so the prompt can offer another without a round trip.

		Re-entrant on purpose: OPEN ANOTHER calls back into here with the next
		run while the screen is still up, so packs flow one into the next with
		no menu in between.
	]]
	--[[
		QUEUED, BECAUSE TWO THINGS CAN ARRIVE AT ONCE.

		A chest pack can hand out a tool in the same breath as its cards, and the
		tool is its own forced reveal. Two runs playing into one stage at once
		would tear each other's cards up, so a run that arrives while another is
		on stage waits its turn. Forced runs end with no prompt; the screen
		settles on the last ordinary run's prompt, or closes if there was none.
	]]
	function ctl.play(run, meta)
		if type(run) ~= "table" or #run == 0 then
			if playing then
				-- Something is already on stage; it unlocks the menu itself.
				return
			end
			if screen.Enabled then
				-- Asked for another and got nothing: settle back where we were
				-- instead of sitting on a bare scrim.
				if settleMeta then
					showPrompt(settleMeta)
				else
					finish()
				end
				return
			end
			-- Empty/invalid run must still unlock the inventory. Callers set
			-- packRevealBusy / setBusy(true) before FireServer; without onDone
			-- those flags stay stuck and packs can never open again.
			busy = false
			if opts.onDone then
				task.spawn(opts.onDone)
			end
			return
		end
		table.insert(queue, { run = run, meta = (type(meta) == "table") and meta or {} })
		if playing then
			return
		end
		playing = true
		busy = true
		promptGen += 1
		prompt.Visible = false
		pending = false
		rush = false
		local wasUp = screen.Enabled
		screen.Enabled = true
		-- Take the screen. The HUD rail and the wallet sat on top of the pack
		-- and turned the reveal into a busy screenshot; the inventory keeps its
		-- state underneath and comes back untouched when this releases.
		if opts.onScreenOwned then
			pcall(opts.onScreenOwned, true)
		end
		-- Fade in only when arriving. A run that follows another on a screen
		-- that is already up (OPEN ANOTHER, a chest find after its pack) keeps
		-- the scrim, instead of flashing the world through for a frame.
		if not wasUp then
			scrim.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
			scrim.BackgroundTransparency = 1
		end
		-- Always re-aim it: a run that lands inside the close's fade-out has to
		-- take over that tween, or it plays on a see-through scrim.
		TweenService:Create(scrim, TweenInfo.new(0.18), { BackgroundTransparency = 0.08 }):Play()
		task.spawn(function()
			while #queue > 0 do
				local job = table.remove(queue, 1)
				auto = job.meta.auto and true or false
				pending = false
				rush = false
				-- A new player-asked run owns the settle prompt. Drop the previous
				-- stack's left-count so opening pack B after open-all of A cannot
				-- re-offer "open Ax" under B's name.
				if not auto then
					settleMeta = nil
				end
				-- Always know which pack this run belongs to. open-all hits use a
			-- synthetic packId; continue-open must use the real stack id from
			-- meta or from the payloads themselves — never the previous run.
				local meta = job.meta
				if type(meta) ~= "table" then
					meta = {}
					job.meta = meta
				end
				local pinned = meta.packId
				if type(pinned) ~= "string" or pinned == "" or pinned == "bulk_hits" then
					pinned = nil
					for _, pack in ipairs(job.run) do
						local id = pack and pack.packId
						if type(id) == "string" and id ~= "" and id ~= "bulk_hits" and not pack.luckyBlock then
							pinned = id
							break
						end
					end
					meta.packId = pinned
				end
				local ranAny = false
				if #job.run > 1 then
					local ok, res = pcall(playBulk, job.run)
					if not ok then
						warn("[PackReveal] bulk " .. tostring(res))
					else
						ranAny = res and true or false
					end
				else
					for i, pack in ipairs(job.run) do
						local ok, res = pcall(playPack, pack, i, #job.run)
						if not ok then
							warn("[PackReveal] " .. tostring(res))
							break
						end
						ranAny = ranAny or res
					end
				end
				if ranAny and not auto then
					settleMeta = meta
				end
			end
			auto = false
			playing = false
			if settleMeta then
				showPrompt(settleMeta)
			else
				-- Nothing was openable, or only forced reveals ran. Do not park
				-- on a black screen.
				finish()
			end
		end)
	end

	return ctl
end

return MinePackReveal
