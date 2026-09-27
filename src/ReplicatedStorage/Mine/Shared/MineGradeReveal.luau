--[[
	MineGradeReveal — Clash Royale chest-style F→SSS step animation.

	Plays a server-authored `info` from MineToolGrades.rollClash:
	  info.steps = { { ok = bool, grade = string }, ... }
	  info.start, info.final, info.upgrades, info.misses

	Does NOT re-roll. Final grade is whatever the server already decided.

	Used by gear summon / Gear Crate opens (via MinePackReveal). Same API is
	the hook for future lucky-block items: GradeReveal.play(parent, info, opts).
]]

local MineGradeReveal = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local shared = game:GetService("ReplicatedStorage"):WaitForChild("Mine"):WaitForChild("Shared")
local Gear = require(shared:WaitForChild("MineGear"))
local Irid = require(shared:WaitForChild("MineIridescence"))
local Temper = require(shared:WaitForChild("MineTemper"))
-- Loot art, pack art and the SFX hooks. Soft: a missing one costs icons or
-- sound, never the reveal.
local Icons, PackFX, Audio
do
	local function soft(name)
		local inst = shared:FindFirstChild(name)
		if not inst then
			return nil
		end
		local ok, mod = pcall(require, inst)
		return ok and mod or nil
	end
	Icons, PackFX, Audio = soft("MineIcons"), soft("MinePackFX"), soft("MineAudio")
end

local FONT = Enum.Font.FredokaOne
local FONT_M = Enum.Font.BuilderSansBold

local STEP_OK = 0.42
local STEP_MISS = 0.36
local FREEZE = 0.55
local RUSH_OK = 0.12
local RUSH_MISS = 0.10
local RUSH_FREEZE = 0.18

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

local function colourFor(grade)
	return (Gear.RARITY_COLOR and Gear.RARITY_COLOR[grade]) or Color3.fromRGB(220, 220, 230)
end

local function waitBeat(sec, shouldSkip)
	local t0 = os.clock()
	while os.clock() - t0 < sec do
		if shouldSkip and shouldSkip() then
			return true
		end
		task.wait()
	end
	return false
end

--[[
	opts:
	  rush = bool                 shorter timings
	  shouldSkip = () -> bool     mash / tap to rush remaining steps
	  zIndex = number
	  onDone = function()
]]
function MineGradeReveal.play(parent, info, opts)
	opts = opts or {}
	if not parent or type(info) ~= "table" then
		if opts.onDone then
			opts.onDone()
		end
		return
	end

	local steps = info.steps or {}
	local start = info.start or "F"
	local final = info.final or start
	local rush = opts.rush == true
	local z = opts.zIndex or 40

	local root = mk("Frame", {
		Name = "GradeReveal",
		BackgroundColor3 = Color3.fromRGB(6, 8, 12),
		BackgroundTransparency = 0.28,
		Size = UDim2.fromScale(1, 1),
		ZIndex = z,
	}, parent)

	local letter = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		Text = start,
		TextScaled = true,
		TextColor3 = colourFor(start),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.fromOffset(220, 160),
		ZIndex = z + 2,
	}, root)
	mk("UITextSizeConstraint", { MaxTextSize = 140 }, letter)
	local stroke = mk("UIStroke", {
		Thickness = 4,
		Color = Color3.new(1, 1, 1),
		Transparency = 0.25,
	}, letter)

	local status = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT_M,
		Text = "ROLLING",
		TextSize = 22,
		TextColor3 = Color3.fromRGB(200, 206, 220),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.46, 90),
		Size = UDim2.fromOffset(320, 28),
		ZIndex = z + 2,
	}, root)

	local missRow = mk("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.46, 128),
		Size = UDim2.fromOffset(120, 18),
		ZIndex = z + 2,
	}, root)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 10),
	}, missRow)
	local missDots = {}
	for i = 1, 3 do
		missDots[i] = mk("Frame", {
			BackgroundColor3 = Color3.fromRGB(70, 74, 88),
			Size = UDim2.fromOffset(14, 14),
			ZIndex = z + 3,
		}, missRow)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, missDots[i])
	end

	local scale = mk("UIScale", { Scale = 0.7 }, letter)
	TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	local missed = 0
	local function paintLetter(grade, flashOk)
		letter.Text = grade
		letter.TextColor3 = colourFor(grade)
		if Irid.isMark and Irid.isMark(grade) then
			-- Soft iridescence wash on the stroke for S+
			pcall(function()
				Irid.clear(letter)
			end)
		end
		local pop = TweenService:Create(
			scale,
			TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = flashOk and 1.18 or 0.92 }
		)
		pop:Play()
		pop.Completed:Wait()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
	end

	local function flashMiss()
		missed += 1
		local dot = missDots[missed]
		if dot then
			dot.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
		end
		local x = mk("TextLabel", {
			BackgroundTransparency = 1,
			Font = FONT,
			Text = "X",
			TextSize = 72,
			TextColor3 = Color3.fromRGB(255, 96, 96),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.46),
			Size = UDim2.fromOffset(100, 100),
			ZIndex = z + 5,
			Rotation = -12,
		}, root)
		local xs = mk("UIScale", { Scale = 0.4 }, x)
		TweenService:Create(xs, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = 1.15 }):Play()
		task.delay(rush and 0.08 or 0.22, function()
			if x.Parent then
				TweenService:Create(x, TweenInfo.new(0.12), { TextTransparency = 1 }):Play()
				task.delay(0.14, function()
					x:Destroy()
				end)
			end
		end)
		status.Text = "MISS  " .. missed .. " / 3"
		status.TextColor3 = Color3.fromRGB(255, 140, 140)
	end

	local function flashUpgrade(grade)
		status.Text = "UPGRADE"
		status.TextColor3 = Color3.fromRGB(120, 255, 170)
		local glow = mk("Frame", {
			BackgroundColor3 = colourFor(grade),
			BackgroundTransparency = 0.55,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.46),
			Size = UDim2.fromOffset(260, 200),
			ZIndex = z + 1,
		}, root)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, glow)
		TweenService:Create(glow, TweenInfo.new(0.28), {
			Size = UDim2.fromOffset(420, 320),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(0.3, function()
			if glow.Parent then
				glow:Destroy()
			end
		end)
		paintLetter(grade, true)
	end

	-- Initial beat on start letter.
	waitBeat(rush and 0.08 or 0.2, opts.shouldSkip)

	for _, step in ipairs(steps) do
		local skipped = opts.shouldSkip and opts.shouldSkip()
		if skipped then
			rush = true
		end
		if step.ok then
			flashUpgrade(step.grade or final)
			waitBeat(rush and RUSH_OK or STEP_OK, opts.shouldSkip)
		else
			flashMiss()
			paintLetter(step.grade or letter.Text, false)
			waitBeat(rush and RUSH_MISS or STEP_MISS, opts.shouldSkip)
		end
	end

	-- Freeze on final (authoritative).
	letter.Text = final
	letter.TextColor3 = colourFor(final)
	status.Text = "LOCKED  " .. tostring(final)
	status.TextColor3 = colourFor(final)
	TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1.12 }):Play()
	waitBeat(rush and RUSH_FREEZE or FREEZE, opts.shouldSkip)

	TweenService:Create(root, TweenInfo.new(0.18), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(letter, TweenInfo.new(0.18), { TextTransparency = 1 }):Play()
	TweenService:Create(status, TweenInfo.new(0.18), { TextTransparency = 1 }):Play()
	task.wait(0.18)
	if root.Parent then
		root:Destroy()
	end
	if opts.onDone then
		opts.onDone()
	end
end

--------------------------------------------------------------------------------
-- LUCKY BLOCKS
--------------------------------------------------------------------------------
--[[
	The lucky block screen, Clash Royale chest style.

	The block turns in the middle of the screen at its grade, the background in
	that grade's colour. Tap to open: the server rolls the whole climb at once
	(MineToolGrades.rollClash, a flat 1 in 3 per step) and every tap after that
	plays one step of it. An upgrade spins the block and the background turns
	to the new grade; a tap that does not climb just uses up one of three
	taps (a pip goes out). When the taps run out, or it reaches SSS, the
	block opens and shows what was inside.

	Before the first tap the player can pay gems to raise the grade. The server
	prices that and answers; this only draws. Nothing here ever rolls.

	opts:
	  onOpen(block, count)   ask the server to open `count` of this stack
	  onGradeUp(block)       ask the server for one paid grade
	  priceOf(block)         gems for the next paid grade, nil at the top
	  gems()                 the player's gems right now
	  shortNum(n)            number formatter
	  onBusy(flag)           true while the screen is up
	block (one stack from the inventory):
	  key, firstIndex, blockId, startGrade, bought, count
]]
local RunService = game:GetService("RunService")

local LUCKY_ART = {
	lucky_block = { body = Color3.fromRGB(255, 196, 64), edge = Color3.fromRGB(206, 134, 26), mark = Color3.fromRGB(255, 248, 222) },
	super_lucky_block = { body = Color3.fromRGB(70, 150, 255), edge = Color3.fromRGB(30, 86, 196), mark = Color3.fromRGB(220, 244, 255) },
	godly_lucky_block = { body = Color3.fromRGB(222, 50, 66), edge = Color3.fromRGB(134, 20, 36), mark = Color3.fromRGB(255, 228, 232) },
}
local LUCKY_NAMES = {
	lucky_block = "Lucky Block",
	super_lucky_block = "Diamond Lucky Block",
	godly_lucky_block = "Mythic Lucky Block",
}
-- The mark on every face, one little cube per X.
local QMARK = { ".XXX.", "X...X", "....X", "...X.", "..X..", ".....", "..X.." }

local function luckyModel(blockId)
	local art = LUCKY_ART[blockId] or LUCKY_ART.lucky_block
	local model = Instance.new("Model")
	model.Name = "LuckyBlock"
	local S = 4
	local function part(size, cf, color)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Material = Enum.Material.SmoothPlastic
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Parent = model
		return p
	end
	model.PrimaryPart = part(Vector3.new(S, S, S), CFrame.new(), art.body)
	-- A darker bevel down every edge.
	local e, off = 0.36, S / 2 - 0.16
	for _, a in ipairs({ -1, 1 }) do
		for _, b in ipairs({ -1, 1 }) do
			part(Vector3.new(S + 0.04, e, e), CFrame.new(0, a * off, b * off), art.edge)
			part(Vector3.new(e, S + 0.04, e), CFrame.new(a * off, 0, b * off), art.edge)
			part(Vector3.new(e, e, S + 0.04), CFrame.new(a * off, b * off, 0), art.edge)
		end
	end
	-- Each face frame looks outward; its right is the viewer's left, so the
	-- columns run the other way to keep the mark the right way round.
	local px = 0.42
	for _, fd in ipairs({
		{ Vector3.new(0, 0, -1), Vector3.yAxis },
		{ Vector3.new(0, 0, 1), Vector3.yAxis },
		{ Vector3.new(1, 0, 0), Vector3.yAxis },
		{ Vector3.new(-1, 0, 0), Vector3.yAxis },
		{ Vector3.new(0, 1, 0), Vector3.new(0, 0, -1) },
		{ Vector3.new(0, -1, 0), Vector3.new(0, 0, 1) },
	}) do
		local n = fd[1]
		local face = CFrame.lookAt(n * (S / 2), n * (S / 2 + 1), fd[2])
		for row, line in ipairs(QMARK) do
			for col = 1, #line do
				if line:sub(col, col) == "X" then
					part(Vector3.new(px, px, 0.12), face * CFrame.new(-(col - 3) * px, (4 - row) * px, -0.03), art.mark)
				end
			end
		end
	end
	return model
end

function MineGradeReveal.lucky(parent, opts)
	opts = opts or {}
	local fmt = opts.shortNum or tostring
	local ctl = {}

	local sg = Instance.new("ScreenGui")
	sg.Name = "LuckyReveal"
	sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false
	sg.DisplayOrder = opts.displayOrder or 95
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Enabled = false
	sg.Parent = parent

	local CENTRE = UDim2.fromScale(0.5, 0.4)
	local bg = mk("Frame", { BackgroundColor3 = Color3.fromRGB(24, 24, 28), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 1 }, sg)

	-- Light rays turning behind the block; they speed up when it climbs.
	local rays = mk("Frame", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = CENTRE,
		Size = UDim2.fromScale(1, 1), ZIndex = 2,
	}, sg)
	mk("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }, rays)
	local rayBars = {}
	for i = 1, 9 do
		local bar = mk("Frame", {
			BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.8,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.07, 1.6), Rotation = i * 20, ZIndex = 2,
		}, rays)
		mk("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1),
			}),
		}, bar)
		rayBars[i] = bar
	end
	local glows = {}
	for i, spec in ipairs({ { 0.66, 0.8 }, { 0.5, 0.66 }, { 0.34, 0.5 } }) do
		local d = mk("Frame", {
			BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = spec[2],
			AnchorPoint = Vector2.new(0.5, 0.5), Position = CENTRE, Size = UDim2.fromScale(1, spec[1]), ZIndex = 3,
		}, sg)
		mk("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, d)
		mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, d)
		glows[i] = d
	end

	local vf = mk("ViewportFrame", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = CENTRE,
		Size = UDim2.fromScale(1, 0.5), ZIndex = 5,
		Ambient = Color3.fromRGB(196, 196, 196), LightColor = Color3.new(1, 1, 1), LightDirection = Vector3.new(-1, -2, 1.4),
	}, sg)
	mk("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, vf)
	local cam = Instance.new("Camera")
	cam.FieldOfView = 34
	cam.Parent = vf
	vf.CurrentCamera = cam

	local function text(props, maxSize)
		props.BackgroundTransparency = 1
		props.Font = props.Font or FONT
		props.TextScaled = true
		props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
		props.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
		local host = props.Parent or sg
		props.Parent = nil
		local t = mk("TextLabel", props, host)
		mk("UITextSizeConstraint", { MaxTextSize = maxSize }, t)
		return t
	end
	local title = text({ Text = "", Position = UDim2.fromScale(0.5, 0.075), Size = UDim2.fromScale(0.7, 0.07), ZIndex = 8 }, 40)
	mk("UIStroke", { Thickness = 2, Transparency = 0.3 }, title)
	local letter = text({ Text = "F", Position = UDim2.fromScale(0.5, 0.7), Size = UDim2.fromScale(0.3, 0.11), ZIndex = 8 }, 96)
	local letterStroke = mk("UIStroke", { Thickness = 3, Transparency = 0.15 }, letter)
	local letterScale = mk("UIScale", { Scale = 1 }, letter)

	local pipRow = mk("Frame", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.78), Size = UDim2.fromScale(0.3, 0.034), ZIndex = 8,
	}, sg)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12),
		HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
	}, pipRow)
	local pips, pipScales = {}, {}
	for i = 1, 3 do
		local pip = mk("Frame", { BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(60, 62, 72), Size = UDim2.fromScale(1, 1), ZIndex = 9 }, pipRow)
		mk("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, pip)
		mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, pip)
		mk("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.5 }, pip)
		pips[i] = pip
		pipScales[i] = mk("UIScale", { Scale = 1 }, pip)
	end
	local status = text({ Text = "", Position = UDim2.fromScale(0.5, 0.835), Size = UDim2.fromScale(0.7, 0.05), ZIndex = 8 }, 30)
	mk("UIStroke", { Thickness = 2, Transparency = 0.35 }, status)

	-- A tap anywhere is a tap on the block; the buttons sit above this.
	local tap = mk("TextButton", { BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1), ZIndex = 6 }, sg)

	local function button(label, color, pos)
		local btn = mk("TextButton", {
			BackgroundColor3 = color, BorderSizePixel = 0, AutoButtonColor = true, Font = FONT, Text = label,
			TextScaled = true, TextColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = pos,
			Size = UDim2.fromScale(0.28, 0.075), ZIndex = 10,
		}, sg)
		mk("UICorner", { CornerRadius = UDim.new(0.25, 0) }, btn)
		mk("UIStroke", { Thickness = 2, Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, btn)
		mk("UITextSizeConstraint", { MaxTextSize = 22 }, btn)
		mk("UISizeConstraint", { MinSize = Vector2.new(150, 38), MaxSize = Vector2.new(330, 58) }, btn)
		mk("UIPadding", {
			PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
		}, btn)
		return btn
	end
	-- Clear of Roblox's own bottom bar.
	local gradeBtn = button("GRADE UP", Color3.fromRGB(64, 120, 220), UDim2.fromScale(0.5, 0.9))
	local skipBtn = button("SKIP", Color3.fromRGB(70, 74, 88), UDim2.fromScale(0.5, 0.9))
	local closeBtn = mk("TextButton", {
		BackgroundColor3 = Color3.fromRGB(30, 30, 36), BackgroundTransparency = 0.2, BorderSizePixel = 0,
		Font = FONT, Text = "X", TextScaled = true, TextColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 16), Size = UDim2.fromOffset(44, 44), ZIndex = 12,
	}, sg)
	mk("UICorner", { CornerRadius = UDim.new(0.3, 0) }, closeBtn)
	mk("UIPadding", {
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
	}, closeBtn)

	local flash = mk("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 15 }, sg)

	-- What was inside, as icons rather than a sentence.
	local card = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(22, 22, 28), BackgroundTransparency = 0.04, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.54, 0.7),
		ZIndex = 20, Visible = false,
	}, sg)
	mk("UICorner", { CornerRadius = UDim.new(0, 18) }, card)
	local cardStroke = mk("UIStroke", { Thickness = 3, Color = Color3.new(1, 1, 1) }, card)
	mk("UISizeConstraint", { MinSize = Vector2.new(320, 280), MaxSize = Vector2.new(620, 520) }, card)
	local cardScale = mk("UIScale", { Scale = 1 }, card)
	local cardTitle = text({ Parent = card, Text = "", Position = UDim2.fromScale(0.5, 0.09), Size = UDim2.fromScale(0.9, 0.1), ZIndex = 21 }, 26)
	local cardGrade = text({ Parent = card, Text = "", Position = UDim2.fromScale(0.5, 0.235), Size = UDim2.fromScale(0.5, 0.16), ZIndex = 21 }, 64)
	mk("UIStroke", { Thickness = 3, Transparency = 0.2 }, cardGrade)
	--[[
		EVERYTHING YOU GOT, NOT THE FIRST TWO.

		This was a plain Frame at 34% of the card's height holding full-width
		rows 34-56px tall, so a block that paid out four things showed two and
		clipped the rest -- and on an open-all that is most of what you opened.
		Scrolls now, and takes more of the card.
	]]
	local lootBox = mk("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromScale(0.88, 0.44), ZIndex = 21,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 5, ScrollingDirection = Enum.ScrollingDirection.Y,


	}, card)
	mk("UIListLayout", {
		Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
	}, lootBox)
	local collectBtn = mk("TextButton", {
		BackgroundColor3 = Color3.fromRGB(70, 196, 110), BorderSizePixel = 0, AutoButtonColor = true, Font = FONT,
		Text = "COLLECT", TextScaled = true, TextColor3 = Color3.fromRGB(10, 30, 16),
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.86), Size = UDim2.fromScale(0.5, 0.12), ZIndex = 22,
	}, card)
	mk("UICorner", { CornerRadius = UDim.new(0.3, 0) }, collectBtn)
	mk("UITextSizeConstraint", { MaxTextSize = 24 }, collectBtn)
	mk("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, collectBtn)

	local model
	local anim = { yaw = 0, zoom = 1, raySpin = 14, shake = 0 }
	local st = { mode = "closed", queue = {}, step = 0, grade = "F", misses = 0 }
	local conn

	local function sfx(name)
		if name == "lucky" and Audio and Audio.playLuckyOpen then
			pcall(Audio.playLuckyOpen)
			return
		end
		if Audio and Audio.play then
			pcall(Audio.play, name)
		end
	end

	local function say(msg, color)
		status.Text = msg or ""
		status.TextColor3 = color or Color3.new(1, 1, 1)
	end

	-- The pips are taps LEFT, not strikes: all three lit when a block
	-- arrives, and one goes out for each tap that does not grade it up.
	local function setPips(used)
		for i, pip in ipairs(pips) do
			local lit = i <= (#pips - used)
			pip.BackgroundColor3 = lit and Color3.fromRGB(255, 226, 150) or Color3.fromRGB(60, 62, 72)
		end
	end

	local function paintTier(grade, instant)
		local c = colourFor(grade)
		st.irid = Irid.isMark and Irid.isMark(grade) or false
		local info = TweenInfo.new(instant and 0 or 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(bg, info, { BackgroundColor3 = c:Lerp(Color3.new(0, 0, 0), 0.62) }):Play()
		for _, g in ipairs(glows) do
			TweenService:Create(g, info, { BackgroundColor3 = c }):Play()
		end
		for _, r in ipairs(rayBars) do
			TweenService:Create(r, info, { BackgroundColor3 = c:Lerp(Color3.new(1, 1, 1), 0.35) }):Play()
		end
		letter.Text = grade
		letter.TextColor3 = c
		cardStroke.Color = c
	end

	-- Bits of light thrown out of the middle.
	local function sparks(count, spread, colour)
		for i = 1, count do
			local ang = (i / count) * math.pi * 2 + math.random() * 0.4
			local spark = mk("Frame", {
				BackgroundColor3 = colour, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = CENTRE,
				Size = UDim2.fromScale(0.018, 0.018), Rotation = math.deg(ang), ZIndex = 14,
			}, sg)
			mk("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, spark)
			mk("UICorner", { CornerRadius = UDim.new(0.3, 0) }, spark)
			local r = spread * (0.7 + math.random() * 0.6)
			TweenService:Create(spark, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(0.5 + math.cos(ang) * r * 0.6, 0.4 + math.sin(ang) * r),
				BackgroundTransparency = 1,
				Rotation = math.deg(ang) + 120,
			}):Play()
			task.delay(0.75, function()
				spark:Destroy()
			end)
		end
	end

	-- Paper for the good ones.
	local function confetti(colour)
		for i = 1, 56 do
			local x = math.random()
			local bit = mk("Frame", {
				BackgroundColor3 = (i % 3 == 0) and Color3.new(1, 1, 1) or colour, BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, -0.05),
				Size = UDim2.fromOffset(8, 14), Rotation = math.random(0, 180), ZIndex = 16,
			}, sg)
			local fall = 1.1 + math.random() * 0.8
			TweenService:Create(bit, TweenInfo.new(fall, Enum.EasingStyle.Linear), {
				Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.12, 1.1),
				Rotation = bit.Rotation + math.random(180, 720),
				BackgroundTransparency = 0.25,
			}):Play()
			task.delay(fall + 0.1, function()
				bit:Destroy()
			end)
		end
	end

	local function popLetter(big)
		letterScale.Scale = big and 1.9 or 1.5
		letterStroke.Thickness = 7
		TweenService:Create(letterScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		TweenService:Create(letterStroke, TweenInfo.new(0.4), { Thickness = 3 }):Play()
	end

	local function setModel(blockId)
		if model then
			model:Destroy()
		end
		model = luckyModel(blockId)
		model.Parent = vf
	end

	local function setTitle(blockId, count)
		local name = LUCKY_NAMES[blockId] or "Lucky Block"
		title.Text = (count and count > 1) and (name .. "  x" .. count) or name
	end

	local function frame(dt)
		local now = os.clock()
		anim.yaw += dt * 0.8
		local spin = 0
		if anim.spinAt then
			local u = (now - anim.spinAt) / 0.6
			if u >= 1 then
				anim.spinAt = nil
			else
				spin = (1 - (1 - u) ^ 3) * math.pi * 2 * (anim.spinTurns or 1)
			end
		end
		local punch = 0
		if anim.punchAt then
			local u = (now - anim.punchAt) / 0.45
			if u >= 1 then
				anim.punchAt = nil
			else
				punch = math.sin(u * math.pi) * (anim.punch or 0.15)
			end
		end
		local shake = 0
		if anim.shakeAt then
			local u = (now - anim.shakeAt) / 0.32
			if u >= 1 then
				anim.shakeAt = nil
			else
				shake = math.sin(u * math.pi * 6) * 0.1 * (1 - u)
			end
		end
		if model then
			model:PivotTo(CFrame.new(0, math.sin(now * 2.2) * 0.12, 0)
				* CFrame.Angles(-0.3 + shake, 0, shake * 0.6) * CFrame.Angles(0, anim.yaw + spin, 0))
		end
		local dist = 13 * (1 - punch) * anim.zoom
		cam.CFrame = CFrame.lookAt(Vector3.new(0, 1.4, -dist), Vector3.zero)
		-- The rays run faster for a moment after every climb.
		anim.raySpin += (14 - anim.raySpin) * math.min(1, dt * 1.4)
		rays.Rotation = (rays.Rotation + dt * anim.raySpin) % 360
		if st.irid and Irid.STOPS then
			local stops = Irid.STOPS
			local k = (now * 0.35) % 1 * #stops
			local i = math.floor(k)
			local c = stops[i + 1]:Lerp(stops[(i + 1) % #stops + 1], k - i)
			for _, g in ipairs(glows) do
				g.BackgroundColor3 = c
			end
			letter.TextColor3 = c
		end
	end

	local function openScreen()
		if sg.Enabled then
			return
		end
		sg.Enabled = true
		anim.zoom = 1
		if opts.onBusy then
			opts.onBusy(true)
		end
		conn = game:GetService("RunService").RenderStepped:Connect(frame)
	end

	function ctl.close()
		sg.Enabled = false
		st.mode = "closed"
		st.queue = {}
		st.payload = nil
		st.gradeBusy = false
		card.Visible = false
		if conn then
			conn:Disconnect()
			conn = nil
		end
		if model then
			model:Destroy()
			model = nil
		end
		if opts.onBusy then
			opts.onBusy(false)
		end
	end

	function ctl.isOpen()
		return sg.Enabled
	end

	local function refreshGradeBtn()
		local blk = st.block
		local price = (st.mode == "ready" and blk and opts.priceOf) and opts.priceOf(blk) or nil
		gradeBtn.Visible = price ~= nil
		if price then
			local afford = ((opts.gems and opts.gems()) or 0) >= price
			gradeBtn.Text = "GRADE UP  " .. fmt(price) .. " GEMS"
			gradeBtn.BackgroundColor3 = afford and Color3.fromRGB(64, 120, 220) or Color3.fromRGB(70, 74, 88)
		end
		--[[
			No walking out mid-run.

			ctl.close() empties st.queue, so the X silently threw away every block
			still waiting to be revealed. The loot itself was safe -- the server
			granted it when it opened -- but you never got to see what you pulled,
			which on a fifteen block run is the entire point of opening them.

			Gated on the QUEUE rather than the mode: once nothing is pending you
			can always leave from any state, so this can never strand anybody.
		]]
		closeBtn.Visible = #st.queue == 0
	end

	function ctl.show(block)
		st.block = block
		st.payload = nil
		st.mode = "ready"
		st.grade = block.startGrade or "F"
		st.misses = 0
		st.gradeBusy = false
		setModel(block.blockId)
		paintTier(st.grade, true)
		setPips(0)
		setTitle(block.blockId, block.count)
		say("TAP THE BLOCK TO OPEN")
		skipBtn.Visible = false
		card.Visible = false
		openScreen()
		refreshGradeBtn()
	end

	local function beginReveal(payload)
		st.payload = payload
		st.mode = "reveal"
		st.step = 0
		st.grade = payload.startGrade or (payload.info and payload.info.start) or "F"
		st.misses = 0
		setModel(payload.blockId)
		paintTier(st.grade, true)
		setPips(0)
		setTitle(payload.blockId, nil)
		card.Visible = false
		gradeBtn.Visible = false
		skipBtn.Visible = true
		skipBtn.Text = (#st.queue > 0) and ("SKIP ALL  (" .. (#st.queue + 1) .. ")") or "SKIP"
		local steps = payload.info and payload.info.steps or {}
		say((#steps == 0) and "TAP TO OPEN" or "TAP!")
		openScreen()
	end

	--[[
		One row per thing you got: the pack's own art, or the icon for gems,
		stardust, a tool or a scroll. They land one after another rather than
		all at once, which is the half second the whole screen is for.
	]]
	local function lootRows(loot, lootText)
		local rows = {}
		local function pretty(id)
			local s2 = tostring(id or ""):gsub("_", " ")
			return (s2:gsub("^%l", string.upper))
		end
		if type(loot) == "table" then
			if loot.packId then
				local qty = math.max(1, math.floor(tonumber(loot.packQty) or 1))
				table.insert(rows, { icon = "pack", packId = loot.packId, text = (qty > 1 and (qty .. "x  ") or "") .. pretty(loot.packId) })
			end
			if loot.gems then
				table.insert(rows, { icon = "gems", text = fmt(loot.gems) .. "  Gems" })
			end
			if loot.dust then
				table.insert(rows, { icon = "stardust", text = fmt(loot.dust) .. "  Stardust" })
			end
			if loot.toolId then
				table.insert(rows, { icon = loot.toolFamily or "pickaxe", text = pretty(loot.toolId) })
			end
			if type(loot.scrolls) == "table" then
				for id, qty in pairs(loot.scrolls) do
					table.insert(rows, { icon = id, text = qty .. "x  " .. pretty(id) .. " scroll" })
				end
			end
			if loot.temperTokens then
				table.insert(rows, { icon = "tokens", text = fmt(loot.temperTokens) .. "  Temper tokens" })
			end
		end
		if #rows == 0 then
			table.insert(rows, { icon = "chest", text = tostring(lootText or "--") })
		end
		return rows
	end

	local function fillLoot(loot, lootText)
		for _, ch in ipairs(lootBox:GetChildren()) do
			if not ch:IsA("UIListLayout") then
				ch:Destroy()
			end
		end
		local rows = lootRows(loot, lootText)
		for i, row in ipairs(rows) do
			local line = mk("Frame", {
				BackgroundColor3 = Color3.fromRGB(34, 34, 42), BorderSizePixel = 0,
			-- Flat 48: the box scrolls now, so rows no longer shrink to try to
			-- fit a fixed height -- which is what made a four-drop block unreadable.
				Size = UDim2.new(1, 0, 0, 48), LayoutOrder = i, ZIndex = 22,
			}, lootBox)
			mk("UICorner", { CornerRadius = UDim.new(0, 10) }, line)
			local scale = mk("UIScale", { Scale = 0.6 }, line)
			local art = mk("Frame", {
				BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0),
				Size = UDim2.new(0, 40, 0.86, 0), ZIndex = 23,
			}, line)
			mk("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, art)
			if row.packId and PackFX and PackFX.drawSealed then
				pcall(PackFX.drawSealed, art, row.packId, 36, 46)
			elseif Icons and Icons.draw then
				pcall(Icons.draw, art, row.icon, 1)
			end
			local lbl = mk("TextLabel", {
				BackgroundTransparency = 1, Font = FONT, Text = row.text, TextScaled = true,
				TextColor3 = Color3.fromRGB(240, 242, 250), TextXAlignment = Enum.TextXAlignment.Left,
				AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 56, 0.5, 0), Size = UDim2.new(1, -66, 0.62, 0), ZIndex = 23,
			}, line)
			mk("UITextSizeConstraint", { MaxTextSize = 22 }, lbl)
			task.delay(0.08 * i, function()
				if line.Parent then
					TweenService:Create(scale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
					sfx("lucky")
				end
			end)
		end
	end

	local function showCard(titleText, grade, loot, lootText)
		cardTitle.Text = titleText
		cardGrade.Text = grade or ""
		cardGrade.TextColor3 = colourFor(grade or "F")
		fillLoot(loot, lootText)
		card.Visible = true
		cardScale.Scale = 0.75
		TweenService:Create(cardScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		say("TAP ANYWHERE TO CONTINUE")
		if model then
			model:Destroy()
			model = nil
		end
	end

	local function burst()
		anim.punchAt, anim.punch = os.clock(), 0.4
		anim.raySpin = 220
		flash.BackgroundTransparency = 0.05
		TweenService:Create(flash, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
		local c = colourFor(st.grade):Lerp(Color3.new(1, 1, 1), 0.4)
		sparks(24, 0.34, c)
		sfx("pack")
		local rank = 0
		for i, g in ipairs({ "F", "D", "C", "B", "A", "S", "SS", "SSS" }) do
			if g == st.grade then
				rank = i
			end
		end
		if rank >= 5 then
			confetti(c)
			if rank >= 6 then
				confetti(c:Lerp(Color3.new(1, 1, 1), 0.35))
				confetti(Color3.fromRGB(255, 206, 92))
			end
			if rank >= 7 then
				for _ = 1, 28 do
					sparks(8, 0.4, c)
				end
			end
		end
	end

	local function finish()
		local p = st.payload
		if not p or st.mode == "loot" then
			return
		end
		st.mode = "loot"
		skipBtn.Visible = false
		burst()
		task.delay(0.35, function()
			if st.payload ~= p or not sg.Enabled then
				return
			end
			showCard((LUCKY_NAMES[p.blockId] or "Lucky Block") .. "  opened", st.grade, p.loot, p.lootText)
		end)
	end

	local function playStep()
		local p = st.payload
		local steps = p.info and p.info.steps or {}
		st.step += 1
		local s2 = steps[st.step]
		if not s2 then
			finish()
			return
		end
		if s2.ok then
			st.grade = s2.grade or st.grade
			paintTier(st.grade, false)
			anim.spinAt, anim.spinTurns = os.clock(), 1.5
			anim.punchAt, anim.punch = os.clock(), 0.26
			anim.raySpin = 150
			popLetter(true)
			flash.BackgroundTransparency = 0.55
			TweenService:Create(flash, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
			sparks(14, 0.24, colourFor(st.grade):Lerp(Color3.new(1, 1, 1), 0.4))
			sfx("lucky")
			say("GRADE UP!", colourFor(st.grade))
		else
			-- Not a hit -- and not a failure either. The tap is spent, one pip
			-- goes out, and the block gives the same small bounce any tap gets.
			-- No shake and no red: nothing went wrong, it just did not climb.
			st.misses += 1
			setPips(st.misses)
			anim.punchAt, anim.punch = os.clock(), 0.08
			say("TAP!")
		end
		if st.step >= #steps then
			st.mode = "opening"
			task.delay(0.75, function()
				if st.payload == p and st.mode == "opening" then
					finish()
				end
			end)
		end
	end

	tap.MouseButton1Click:Connect(function()
		if st.mode == "ready" then
			st.mode = "waiting"
			gradeBtn.Visible = false
			say("OPENING...")
			anim.punchAt, anim.punch = os.clock(), 0.1
			sfx("lucky")
			local token = {}
			st.waitToken = token
			task.delay(6, function()
				if st.mode == "waiting" and st.waitToken == token then
					st.mode = "ready"
					say("No answer yet - tap again", Color3.fromRGB(255, 150, 150))
					refreshGradeBtn()
				end
			end)
			if opts.onOpen then
				opts.onOpen(st.block, 1)
			end
		elseif st.mode == "reveal" then
			playStep()
		elseif st.mode == "opening" then
			-- Impatient tap during the beat before it bursts.
			finish()
		elseif st.mode == "loot" then
			ctl.collect()
		end
	end)

	skipBtn.MouseButton1Click:Connect(function()
		if st.mode ~= "reveal" and st.mode ~= "opening" then
			return
		end
		if #st.queue > 0 then
			-- A whole run at once, on one card.
			local all = { st.payload }
			for _, q in ipairs(st.queue) do
				table.insert(all, q)
			end
			st.queue = {}
			local best, bestRank = "F", 0
			local totals = { gems = 0, dust = 0, packs = 0 }
			for _, q in ipairs(all) do
				local g = (q.info and q.info.final) or q.startGrade or "F"
				for i, x in ipairs({ "F", "D", "C", "B", "A", "S", "SS", "SSS" }) do
					if x == g and i > bestRank then
						best, bestRank = g, i
					end
				end
				local loot = q.loot or {}
				totals.gems += tonumber(loot.gems) or 0
				totals.dust += tonumber(loot.dust) or 0
				totals.packs += (loot.packId and math.max(1, math.floor(tonumber(loot.packQty) or 1)) or 0)
			end
			st.grade = best
			st.mode = "loot"
			skipBtn.Visible = false
			paintTier(best, false)
			burst()
			local rows = {}
			if totals.packs > 0 then
				rows.packId = nil
			end
			showCard(#all .. " lucky blocks opened", best, {
				gems = totals.gems > 0 and totals.gems or nil,
				dust = totals.dust > 0 and totals.dust or nil,
			}, totals.packs > 0 and (totals.packs .. " packs") or nil)
			return
		end
		local steps = st.payload.info and st.payload.info.steps or {}
		for i = st.step + 1, #steps do
			local s2 = steps[i]
			if s2.ok then
				st.grade = s2.grade or st.grade
			else
				st.misses += 1
			end
		end
		st.step = #steps
		setPips(st.misses)
		paintTier(st.grade, false)
		anim.spinAt, anim.spinTurns = os.clock(), 1
		finish()
	end)

	-- Collecting is a tap anywhere, not a trip to the button: a stack of ten is
	-- meant to be spammed from one spot.
	local function collect()
		if st.mode ~= "loot" then
			return
		end
		card.Visible = false
		st.payload = nil
		local nextOne = table.remove(st.queue, 1)
		if nextOne then
			beginReveal(nextOne)
			return
		end
		local blk = st.block
		if blk and st.fromStack and (blk.count or 1) > 1 then
			blk.count -= 1
			blk.firstIndex = nil
			ctl.show(blk)
			return
		end
		ctl.close()
	end
	ctl.collect = collect
	collectBtn.MouseButton1Click:Connect(collect)

	gradeBtn.MouseButton1Click:Connect(function()
		if st.mode ~= "ready" or st.gradeBusy or not st.block then
			return
		end
		local price = opts.priceOf and opts.priceOf(st.block)
		if not price then
			return
		end
		if ((opts.gems and opts.gems()) or 0) < price then
			say("You need " .. fmt(price) .. " gems", Color3.fromRGB(255, 150, 150))
			return
		end
		st.gradeBusy = true
		say("...")
		if opts.onGradeUp then
			opts.onGradeUp(st.block)
		end
	end)

	closeBtn.MouseButton1Click:Connect(ctl.close)

	function ctl.opened(payload)
		if type(payload) ~= "table" then
			return
		end
		if st.mode == "waiting" then
			st.fromStack = true
			beginReveal(payload)
		elseif st.mode == "manyWait" then
			st.fromStack = false
			beginReveal(payload)
		elseif st.mode == "reveal" or st.mode == "opening" or st.mode == "loot" then
			table.insert(st.queue, payload)
			if st.mode == "reveal" then
				skipBtn.Text = "SKIP ALL  (" .. (#st.queue + 1) .. ")"
			end
		else
			st.block = nil
			st.fromStack = false
			beginReveal(payload)
		end
	end

	function ctl.openMany(block, count)
		ctl.show(block)
		st.mode = "manyWait"
		gradeBtn.Visible = false
		say("OPENING " .. count .. "...")
		if opts.onOpen then
			opts.onOpen(block, count)
		end
	end

	function ctl.graded(payload)
		st.gradeBusy = false
		if type(payload) ~= "table" or not st.block or st.mode ~= "ready" then
			return
		end
		if not payload.ok then
			say(tostring(payload.reason or "Could not grade it up"), Color3.fromRGB(255, 150, 150))
			refreshGradeBtn()
			return
		end
		local blk = st.block
		blk.key = payload.key
		-- Grading changes the stack key, so the id is the only handle that
		-- still points at the block the gems were spent on.
		blk.uid = payload.uid or blk.uid
		blk.firstIndex = payload.index
		blk.startGrade = payload.grade
		blk.bought = payload.bought
		blk.count = 1
		st.grade = payload.grade
		paintTier(st.grade, false)
		anim.spinAt, anim.spinTurns = os.clock(), 1.5
		anim.punchAt, anim.punch = os.clock(), 0.26
		anim.raySpin = 150
		popLetter(true)
		sparks(14, 0.24, colourFor(st.grade):Lerp(Color3.new(1, 1, 1), 0.4))
		sfx("lucky")
		setTitle(blk.blockId, 1)
		say("GRADE UP!", colourFor(st.grade))
		refreshGradeBtn()
	end

	function ctl.gone()
		if st.mode == "waiting" or st.mode == "manyWait" then
			say("That block is gone", Color3.fromRGB(255, 150, 150))
			task.delay(1.2, ctl.close)
		end
	end

	return ctl
end

--------------------------------------------------------------------------------
-- A CASE THAT SPINS
--
-- A reel of tiles slides right to left and eases to a stop with the winner under
-- the centre marker. Temperaments come out of this.
--
-- The winner is NOT decided here. The server rolls it, builds the reel around it
-- (MineTemper.caseReel) and sends both, so nothing this animation does can
-- change what came out -- including the skip, which only ends the tween early.
--
--   local ctl = MineGradeReveal.caseSpin(playerGui)
--   ctl.play({ reel = {{id=,rarity=}...}, at = 38, id = , rarity = }, onDone)
--
-- It lives in this module rather than its own because Studio will not let a new
-- script be parented into Mine.Shared (sandbox capabilities), and a case is a
-- reveal, which is what this module is for.
--------------------------------------------------------------------------------
local TILE_W, TILE_GAP, SPIN_TIME = 132, 8, 5.4

function MineGradeReveal.caseSpin(parent)
	local INK = Color3.fromRGB(24, 26, 38)
	local CARD = Color3.fromRGB(46, 50, 68)
	local CARD_HI = Color3.fromRGB(58, 66, 96)
	local TEXT = Color3.fromRGB(244, 246, 252)
	local MUTED = Color3.fromRGB(168, 176, 198)
	local GOLD = Color3.fromRGB(255, 206, 92)

	local function round(o, r)
		mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o)
		return o
	end
	local function stroke(o, thick, colour, transparency)
		return mk("UIStroke", {
			Thickness = thick or 1,
			Color = colour or Color3.fromRGB(120, 134, 178),
			Transparency = transparency or 0.35,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, o)
	end
	local function say(host, text, size, colour, pos, sz, font, align, wrap)
		return mk("TextLabel", {
			BackgroundTransparency = 1,
			Font = font or FONT_M,
			Text = text,
			TextSize = size,
			TextColor3 = colour or TEXT,
			TextXAlignment = align or Enum.TextXAlignment.Center,
			TextWrapped = wrap and true or false,
			TextTruncate = wrap and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
			Position = pos or UDim2.new(),
			Size = sz or UDim2.new(1, 0, 0, size + 4),
			ZIndex = (host.ZIndex or 1) + 2,
		}, host)
	end

	local ctl = {}
	local playing, tween, finishNow = false, nil, nil

	-- Must be a ScreenGui under PlayerGui — a bare Frame never draws.
	local host = parent
	if host and not host:IsA("LayerCollector") then
		local sg = Instance.new("ScreenGui")
		sg.Name = "CaseSpinGui"
		sg.IgnoreGuiInset = true
		sg.ResetOnSpawn = false
		sg.DisplayOrder = 110
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.Enabled = false
		sg.Parent = host
		host = sg
	end

	local screen = mk("Frame", {
		Name = "CaseSpin", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.3,
		BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 120,
	}, host)
	-- Anywhere on the scrim ends the spin; a second tap closes the window, so
	-- spam-clicking through a case can never cost you the result.
	local skip = mk("TextButton", {
		BackgroundTransparency = 1, Text = "", BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1), ZIndex = 121,
	}, screen)

	local box = mk("Frame", {
		BackgroundColor3 = INK, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(760, 330), ZIndex = 122,
	}, screen)
	round(box, 16)
	local boxStroke = stroke(box, 2, GOLD, 0.2)
	-- Fit the fixed 760x330 box to phones: scale down, never up.
	local fit = mk("UIScale", { Name = "FitScale", Scale = 1 }, box)
	local function applyFit()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local s = math.min(1, (vp.X * 0.96) / 760, (vp.Y * 0.90) / 330)
		fit.Scale = math.max(0.45, s)
	end
	applyFit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyFit)
	end

	local title = say(box, "TEMPERAMENT CASE", 18, GOLD, UDim2.fromOffset(0, 16), UDim2.new(1, 0, 0, 22), FONT)
	local sub = say(box, "opening...", 13, MUTED, UDim2.fromOffset(0, 42), UDim2.new(1, 0, 0, 18))

	local track = mk("Frame", {
		BackgroundColor3 = CARD, BorderSizePixel = 0, ClipsDescendants = true,
		Position = UDim2.fromOffset(18, 76), Size = UDim2.new(1, -36, 0, 150), ZIndex = 123,
	}, box)
	round(track, 12)
	stroke(track, 1, nil, 0.5)

	local reel = mk("Frame", {
		BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 0), Size = UDim2.new(0, 0, 1, 0), ZIndex = 124,
	}, track)

	-- The tile under this line is the one you won.
	mk("Frame", { BackgroundColor3 = GOLD, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0, 3, 1, 0), ZIndex = 130 }, track)
	mk("Frame", { BackgroundColor3 = GOLD, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(15, 7), ZIndex = 131 }, track)
	mk("Frame", { BackgroundColor3 = GOLD, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(15, 7), ZIndex = 131 }, track)

	local resultName = say(box, "", 20, TEXT, UDim2.fromOffset(18, 236), UDim2.new(1, -36, 0, 24), FONT)
	local resultSub = say(box, "", 13, MUTED, UDim2.fromOffset(18, 262), UDim2.new(1, -36, 0, 18))

	local closeBtn = mk("TextButton", {
		AutoButtonColor = true, BackgroundColor3 = CARD_HI, Text = "CLOSE", BorderSizePixel = 0,
		Font = FONT_M, TextSize = 14, TextColor3 = TEXT, AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.fromOffset(150, 32), Visible = false, ZIndex = 124,
	}, box)
	round(closeBtn, 8)

	-- Tile art: grade wash + big icon (temperament / gear / hat) with the name
	-- tucked under so the icon is what you read first.
	local tiles = {}
	local function tile(i, row)
		local grade = Temper.normalizeRarity(row.rarity) or "F"
		local ink = Temper.colorOf(grade)
		local t = mk("Frame", {
			BackgroundColor3 = CARD_HI, BorderSizePixel = 0,
			Position = UDim2.fromOffset((i - 1) * (TILE_W + TILE_GAP) + TILE_GAP, 10),
			Size = UDim2.fromOffset(TILE_W, 130), ZIndex = 125,
		}, reel)
		round(t, 10)
		local tStroke = stroke(t, 2, ink, 0.15)
		mk("UIScale", { Name = "Pop", Scale = 1 }, t)
		tiles[i] = { frame = t, stroke = tStroke, ink = ink, grade = grade }
		local wash = mk("Frame", {
			BackgroundColor3 = ink, BackgroundTransparency = 0.72, BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 44), ZIndex = 126,
		}, t)
		round(wash, 10)
		local kit = Temper.kit(row.id)
		local labelName = tostring(row.name or (kit and kit.name) or row.id)
		say(t, string.upper(Temper.wordOf(grade)), 10, ink, UDim2.fromOffset(6, 4), UDim2.new(1, -12, 0, 12), FONT)
		local iconUrl = (kit and kit.icon) or row.icon
		if (not iconUrl or iconUrl == "") and Icons and Icons.image then
			pcall(function()
				iconUrl = Icons.image(row.id) or Icons.image(row.stat)
				if (not iconUrl or iconUrl == "") then
					local stat = kit and type(kit.stats) == "table" and kit.stats[1]
					if stat then
						iconUrl = Icons.image(stat)
					end
				end
			end)
		end
		if (not iconUrl or iconUrl == "") and row.catalogId and tonumber(row.catalogId) then
			iconUrl = string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", tonumber(row.catalogId))
		end
		if (not iconUrl or iconUrl == "") and row.id and row.id ~= "?" then
			pcall(function()
				local Hats = require(shared:WaitForChild("MineHats"))
				for _, h in ipairs(Hats.LIST or {}) do
					if h.id == row.id and h.catalogId then
						iconUrl = string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", tonumber(h.catalogId))
						if not row.name then
							labelName = tostring(h.name)
						end
						break
					end
				end
			end)
		end
		if iconUrl and iconUrl ~= "" then
			mk("ImageLabel", {
				BackgroundTransparency = 1, Image = iconUrl, ScaleType = Enum.ScaleType.Fit,
				AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12),
				Size = UDim2.fromOffset(84, 84), ZIndex = 127,
			}, t)
			say(t, labelName, 11, TEXT, UDim2.fromOffset(4, 100),
				UDim2.new(1, -8, 0, 26), FONT, Enum.TextXAlignment.Center, true)
		else
			say(t, labelName, 15, TEXT, UDim2.fromOffset(8, 40),
				UDim2.new(1, -16, 0, 50), FONT, Enum.TextXAlignment.Center, true)
		end
		return t
	end

	--[[
		Where the reel must sit for tile `at` to be under the marker. The jitter is
		a fraction of a tile, because a case that stops dead centre every single
		time looks scripted -- which is the one thing this must not look like.
	]]
	local function trackWidth()
		local w = track.AbsoluteSize.X
		if w < 1 then
			-- Layout has not resolved yet; box is fixed 760 wide with 18px pads.
			w = 724
		end
		return w
	end

	local function restFor(at, jitter)
		local centre = (at - 1) * (TILE_W + TILE_GAP) + TILE_GAP + TILE_W / 2
		return -(centre - trackWidth() / 2) + jitter
	end

	local function setGuiOn(on)
		if host:IsA("ScreenGui") then
			host.Enabled = on
		end
		screen.Visible = on
	end

	function ctl.play(payload, onDone)
		if type(payload) ~= "table" or type(payload.reel) ~= "table" then
			return
		end
		if playing and finishNow then
			finishNow()
		end
		playing = true
		for _, ch in ipairs(reel:GetChildren()) do
			ch:Destroy()
		end
		table.clear(tiles)
		boxStroke.Color = GOLD
		boxStroke.Thickness = 2
		boxStroke.Transparency = 0.2
		local rows = payload.reel
		local at = math.clamp(math.floor(tonumber(payload.at) or #rows), 1, math.max(1, #rows))
		for i, row in ipairs(rows) do
			if type(row) == "table" then
				tile(i, row)
			end
		end
		reel.Size = UDim2.new(0, #rows * (TILE_W + TILE_GAP) + TILE_GAP, 1, 0)

		local kit = Temper.kit(payload.id)
		local grade = Temper.normalizeRarity(payload.rarity)
		title.Text = string.upper(tostring(payload.title or Temper.CASE_NAME or "Temperament Case"))
		sub.Text = "opening..."
		resultName.Text = ""
		resultSub.Text = ""
		closeBtn.Visible = false
		setGuiOn(true)
		-- One frame so AbsoluteSize is real before we aim the marker.
		task.defer(function()
			if not playing then
				return
			end
			reel.Position = UDim2.fromOffset(math.floor(trackWidth() / 2), 0)
			local jitter = (math.random() - 0.5) * (TILE_W * 0.55)
			local rest = restFor(at, jitter)
			if Audio and Audio.play then
				pcall(Audio.play, "spin")
			end

			-- Winner rank, known up front (server rolled it) so the tension can
			-- build BEFORE the stop: riser + gold stroke pulse on big pulls.
			local winRank = 0
			for gi, g in ipairs({ "F", "D", "C", "B", "A", "S", "SS", "SSS" }) do
				if g == grade then winRank = gi end
			end
			local startedAt = os.clock()
			local riserPlayed = false

			-- REEL TICKS. Each tile crossing the marker clicks; pitch climbs as the
			-- reel slows so the last few clicks feel like a held breath. The tile
			-- under the marker swells, the rest sit flat.
			local lastUnder = nil
			local tickConn
			local function underMarker()
				local x = -reel.Position.X.Offset + trackWidth() / 2
				return math.floor((x - TILE_GAP) / (TILE_W + TILE_GAP)) + 1
			end
			tickConn = RunService.RenderStepped:Connect(function()
				if not playing then return end
				local idx = underMarker()
				local elapsed = os.clock() - startedAt
				local frac = math.clamp(elapsed / SPIN_TIME, 0, 1)
				if idx ~= lastUnder then
					if lastUnder and tiles[lastUnder] and tiles[lastUnder].frame.Parent then
						TweenService:Create(tiles[lastUnder].frame.Pop, TweenInfo.new(0.12), { Scale = 1 }):Play()
					end
					if tiles[idx] and tiles[idx].frame.Parent then
						TweenService:Create(tiles[idx].frame.Pop, TweenInfo.new(0.08), { Scale = 1.07 }):Play()
					end
					lastUnder = idx
					if Audio and Audio.play then
						pcall(Audio.play, "tick", 0.8 + frac * 0.5, 0.85 + frac * 0.6)
					end
				end
				if winRank >= 5 and not riserPlayed and frac >= 0.62 then
					riserPlayed = true
					if Audio and Audio.play then pcall(Audio.play, "riser") end
					local ink = Temper.colorOf(grade)
					TweenService:Create(boxStroke, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 6, true), {
						Color = ink:Lerp(Color3.new(1, 1, 1), 0.3), Thickness = 5, Transparency = 0,
					}):Play()
				end
			end)

			local done = false
			local function finish()
				if done then
					return
				end
				done = true
				playing = false
				if tickConn then tickConn:Disconnect() tickConn = nil end
				if tween then
					tween:Cancel()
					tween = nil
				end
				reel.Position = UDim2.fromOffset(rest, 0)
				-- Winner swells and glows; losers fall back and dim.
				for i, tl in pairs(tiles) do
					if tl.frame.Parent then
						if i == at then
							tl.frame.ZIndex = 129
							for _, d in ipairs(tl.frame:GetDescendants()) do
								if d:IsA("GuiObject") then d.ZIndex += 4 end
							end
							tl.frame.Pop.Scale = 1.28
							TweenService:Create(tl.frame.Pop, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.14 }):Play()
							tl.stroke.Transparency = 0
							tl.stroke.Thickness = 4
							TweenService:Create(tl.stroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
								Color = tl.ink:Lerp(Color3.new(1, 1, 1), 0.5),
							}):Play()
						else
							TweenService:Create(tl.frame.Pop, TweenInfo.new(0.25), { Scale = 0.94 }):Play()
							TweenService:Create(tl.frame, TweenInfo.new(0.35), { BackgroundTransparency = 0.45 }):Play()
							TweenService:Create(tl.stroke, TweenInfo.new(0.35), { Transparency = 0.7 }):Play()
						end
					end
				end
				if Audio and Audio.play then pcall(Audio.play, "thud") end
				sub.Text = payload.dupe and "another copy -- your collection keeps the better grade"
					or "yours to fit on any tool"
				resultName.Text = string.upper(tostring(payload.word or Temper.wordOf(grade)))
					.. "   " .. tostring((kit and kit.name) or payload.id or "")
				resultName.TextColor3 = Temper.colorOf(grade)
				local bits = {}
				for _, line in ipairs(Temper.describe(payload.id, grade) or {}) do
					table.insert(bits, tostring(line.label) .. " " .. tostring(line.text))
				end
				resultSub.Text = (#bits > 0) and table.concat(bits, "    ") or ""
				-- Result line punches in.
				do
					local rp = resultName:FindFirstChild("Pop") or mk("UIScale", { Name = "Pop" }, resultName)
					rp.Scale = 1.5
					resultName.TextTransparency = 1
					TweenService:Create(rp, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
					TweenService:Create(resultName, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
				end
				closeBtn.Visible = true
				-- Big hits get a real celebration — flash, confetti, punch, sfx.
				do
					local rank = 0
					for i, g in ipairs({ "F", "D", "C", "B", "A", "S", "SS", "SSS" }) do
						if g == grade then
							rank = i
						end
					end
					local ink = Temper.colorOf(grade)
					if rank >= 5 then
						if Audio and Audio.play then pcall(Audio.play, "flash") end
						-- Screen shake: the box rattles, harder for higher grades.
						task.spawn(function()
							local amp = (rank >= 7) and 14 or (rank >= 6 and 10 or 6)
							local t0 = os.clock()
							while os.clock() - t0 < 0.45 and box.Parent do
								local k = 1 - (os.clock() - t0) / 0.45
								box.Position = UDim2.new(0.5, (math.random() - 0.5) * 2 * amp * k, 0.5, (math.random() - 0.5) * 2 * amp * k)
								RunService.RenderStepped:Wait()
							end
							box.Position = UDim2.fromScale(0.5, 0.5)
						end)
						local flash = mk("Frame", {
							BackgroundColor3 = ink:Lerp(Color3.new(1, 1, 1), 0.45),
							BackgroundTransparency = 0.08, BorderSizePixel = 0,
							Size = UDim2.fromScale(1, 1), ZIndex = 200,
						}, screen)
						TweenService:Create(flash, TweenInfo.new(1.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							BackgroundTransparency = 1,
						}):Play()
						task.delay(1.1, function()
							if flash.Parent then flash:Destroy() end
						end)
						-- Gold ring burst around the box.
						for ring = 1, (rank >= 6 and 3 or 2) do
							local halo = mk("Frame", {
								BackgroundTransparency = 1, BorderSizePixel = 0,
								AnchorPoint = Vector2.new(0.5, 0.5),
								Position = UDim2.fromScale(0.5, 0.5),
								Size = UDim2.fromOffset(40, 40), ZIndex = 199,
							}, screen)
							local st = mk("UIStroke", {
								Thickness = 4, Color = ink:Lerp(Color3.new(1, 1, 1), 0.25),
								Transparency = 0.1,
							}, halo)
							round(halo, 20)
							local delay = (ring - 1) * 0.12
							task.delay(delay, function()
								TweenService:Create(halo, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
									Size = UDim2.fromOffset(520 + ring * 80, 280 + ring * 40),
								}):Play()
								TweenService:Create(st, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
									Transparency = 1, Thickness = 1,
								}):Play()
								task.delay(0.75, function()
									if halo.Parent then halo:Destroy() end
								end)
							end)
						end
						local nBits = (rank >= 7) and 110 or (rank >= 6 and 78 or 52)
						for i = 1, nBits do
							local x = math.random()
							local bit = mk("Frame", {
								BackgroundColor3 = (i % 3 == 0) and Color3.new(1, 1, 1)
									or (i % 5 == 0) and GOLD or ink,
								BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
								Position = UDim2.fromScale(x, -0.06),
								Size = UDim2.fromOffset(rank >= 6 and 12 or 8, rank >= 6 and 18 or 13),
								Rotation = math.random(0, 180), ZIndex = 201,
							}, screen)
							local fall = 1.05 + math.random() * 1.05
							TweenService:Create(bit, TweenInfo.new(fall, Enum.EasingStyle.Linear), {
								Position = UDim2.fromScale(x + (math.random() - 0.5) * 0.22, 1.14),
								Rotation = bit.Rotation + math.random(220, 900),
								BackgroundTransparency = 0.15,
							}):Play()
							task.delay(fall + 0.1, function()
								if bit.Parent then bit:Destroy() end
							end)
						end
						local punch = mk("UIScale", { Scale = 1 }, box)
						punch.Scale = (rank >= 7) and 1.22 or (rank >= 6 and 1.14 or 1.1)
						TweenService:Create(punch, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
							Scale = 1,
						}):Play()
						if Audio and Audio.playLuckyWin then
							pcall(Audio.playLuckyWin, rank)
						elseif Audio and Audio.play then
							pcall(Audio.play, rank >= 6 and "jackpot" or "reveal")
						end
					elseif Audio and Audio.play then
						pcall(Audio.play, "reveal")
					end
				end
				if onDone then
					task.defer(onDone, payload)
				end
			end
			finishNow = finish

			tween = TweenService:Create(reel,
				TweenInfo.new(SPIN_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Position = UDim2.fromOffset(rest, 0) })
			tween:Play()
			tween.Completed:Connect(finish)
		end)
	end

	function ctl.close()
		setGuiOn(false)
		playing = false
		boxStroke.Color = GOLD
		boxStroke.Thickness = 2
		boxStroke.Transparency = 0.2
		box.Position = UDim2.fromScale(0.5, 0.5)
	end

	closeBtn.MouseButton1Click:Connect(ctl.close)
	skip.MouseButton1Click:Connect(function()
		if playing and finishNow then
			finishNow()
		else
			ctl.close()
		end
	end)

	ctl.root = screen
	return ctl
end

return MineGradeReveal