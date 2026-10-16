--[[
	MineCelebrate -- one rarity-scaled celebration for every luck reveal.

	Owner, 2026-10-08: "do this to pack, cases, and any other luck style
	things.. easily navigable, and dopamine heavy", then "less dopamine with
	the chests, but HUGE with the ones that hit and give good shit", then "slot
	machine wins are fine, maybe even encouraged ... i just dont want alarms".

	So every reveal in the game -- packs, cases and grade reveals, lucky
	blocks, hat crates, trait rolls -- calls this with a TIER, and the payoff
	scales with it:

	  0 COMMON     a soft pop sound. No overlay at all; a dud is not a party.
	  1 NICE       sparkle burst + a friendly pluck.
	  2 GREAT      + confetti, light rays, edge glow, a "GREAT!" title, a sting.
	  3 EPIC       + white flash, a gentle shake, more confetti, a horn riff.
	  4 LEGENDARY  + rainbow title, double confetti, the big orchestral sting.

	HONEST BY CONSTRUCTION. The tier must come from the REAL result's rarity
	(the mappers below take the server's band/grade/rank/odds). Card packs and
	lucky blocks can be bought with credits (Robux) and the audience is kids,
	so this module never fakes a near-miss, never celebrates a dud, and the
	drum-roll lead-in (suspense) only plays when the result truly is epic+.

	NEVER IN THE WAY. The overlay sits above the reveals (DisplayOrder 130)
	but sinks no input, so the reveal's own buttons and its skip keep working
	underneath. cancel() kills it instantly when a reveal is skipped or closed.
	Roblox's Reduced Motion setting drops the shake and the spinning rays.

	Client-only. No image assets: rays, sparkles and confetti are Frames, so
	nothing here needs the owner's icon set.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local shared = script.Parent
local T = require(shared:WaitForChild("MineTheme"))
local okAudio, Audio = pcall(function()
	return require(shared:WaitForChild("MineAudio"))
end)
if not okAudio then
	Audio = nil
end

local MineCelebrate = {}

MineCelebrate.TIER = { COMMON = 0, NICE = 1, GREAT = 2, EPIC = 3, LEGENDARY = 4 }

local NAMES = { "NICE!", "GREAT!", "EPIC!!", "LEGENDARY!!!" }

-- Title gradient per tier (top, bottom). Legendary cycles a rainbow instead.
local TITLE_COLORS = {
	{ T.CANDY.green[1], T.CANDY.green[2] },
	{ T.CANDY.cyan[1], T.CANDY.cyan[2] },
	{ T.CANDY.magenta[1], T.CANDY.purple[2] },
	{ T.CANDY.gold[1], T.CANDY.orange[2] },
}

local CONFETTI = {
	T.CANDY.gold[1], T.CANDY.green[1], T.CANDY.cyan[1], T.CANDY.magenta[1],
	T.CANDY.orange[1], T.CANDY.blue[1], T.CANDY.red[1], Color3.new(1, 1, 1),
}

-- Seconds each tier holds before fading, and how much confetti it throws.
local HOLD = { 0.7, 1.3, 2.1, 3.2 }
local CONFETTI_COUNT = { 0, 34, 70, 130 }
local TITLE_SIZE = { 0, 64, 84, 104 }

-- ---------------------------------------------------------------- mappers --
-- Pack pull bands, as MinePackReveal / MinePackFX / MineAudio.playCard use.
local BAND = { DUD = 0, NICE = 1, HIT = 2, CHASE = 3, GOD = 4 }
function MineCelebrate.fromBand(band)
	return BAND[string.upper(tostring(band or ""))] or 0
end

-- Temper / skin grades. Weights (MineTemper): F 50%, D 27.6%, C 12.5%,
-- B 6.75%, A 2.5%, S 0.5%, SS 0.1%, SSS 0.02%.
local GRADE = { F = 0, D = 0, C = 1, B = 1, A = 2, S = 3, SS = 4, SSS = 4 }
function MineCelebrate.fromGrade(grade)
	return GRADE[string.upper(tostring(grade or ""))] or 0
end

-- Grade rank, 1..8 = F, D, C, B, A, S, SS, SSS. This is the scale
-- MineGradeReveal's case reel and lucky blocks pass to MineAudio.playLuckyWin.
-- It matches fromGrade exactly.
local RANK = { 0, 0, 1, 1, 2, 3, 4, 4 }
function MineCelebrate.fromRank(rank)
	local r = math.clamp(math.floor(tonumber(rank) or 1), 1, 8)
	return RANK[r]
end

-- Anything with odds: "1 in N".
function MineCelebrate.fromOneIn(n)
	n = tonumber(n) or 1
	if n >= 5000 then
		return 4
	elseif n >= 1000 then
		return 3
	elseif n >= 150 then
		return 2
	elseif n >= 25 then
		return 1
	end
	return 0
end

-- ---------------------------------------------------------------- overlay --
local overlayGui
local function overlay()
	if overlayGui and overlayGui.Parent then
		return overlayGui
	end
	local plr = Players.LocalPlayer
	local pg = plr and plr:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return nil
	end
	local g = Instance.new("ScreenGui")
	g.Name = "MineCelebrate"
	g.DisplayOrder = 130
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = pg
	overlayGui = g
	return g
end

local function reducedMotion()
	local ok, on = pcall(function()
		return GuiService.ReducedMotionEnabled
	end)
	return ok and on == true
end

local function frame(props, parent)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.Active = false
	for k, v in pairs(props) do
		f[k] = v
	end
	f.Parent = parent
	return f
end

local current -- { alive, root, tier }

function MineCelebrate.cancel()
	if current then
		current.alive = false
		if current.root then
			current.root:Destroy()
		end
		current = nil
	end
end

function MineCelebrate.isPlaying()
	return current ~= nil and current.alive == true
end

--[[
	Fire a celebration.
	  tier   0..4 (use a mapper above)
	  opts.title   override the title text, e.g. "SSS!" or "JACKPOT!"
	  opts.at      UDim2 centre of the burst (default a little above middle)
	  opts.sound   false to stay silent (the caller already played its own)
	  opts.confetti false when the reveal already throws its own confetti
	A smaller burst never interrupts a bigger one that is still running, so a
	x10 open that reveals a legendary then three commons keeps the legendary.
]]
function MineCelebrate.burst(tier, opts)
	opts = opts or {}
	tier = math.clamp(math.floor(tonumber(tier) or 0), 0, 4)
	if current and current.alive and current.tier > tier then
		return
	end
	if opts.sound ~= false and Audio and Audio.playWin then
		pcall(Audio.playWin, tier)
	end
	if tier <= 0 then
		return
	end
	local gui = overlay()
	if not gui then
		return
	end
	MineCelebrate.cancel()

	local calm = reducedMotion()
	local at = opts.at or UDim2.fromScale(0.5, 0.42)
	local cx, cy = at.X.Scale, at.Y.Scale
	local root = frame({
		Name = "Burst", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
	}, gui)
	local me = { alive = true, root = root, tier = tier }
	current = me

	local fades = {} -- { inst, prop, from }
	local function fadeLater(inst, prop)
		table.insert(fades, { inst, prop, inst[prop] })
	end

	-- WHITE FLASH (epic+): the "something big just happened" beat.
	if tier >= 3 then
		local flash = frame({
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = tier >= 4 and 0.15 or 0.35,
			Size = UDim2.fromScale(1, 1), ZIndex = 50,
		}, root)
		TweenService:Create(flash, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
	end

	-- EDGE GLOW (great+): the whole screen is rimmed in the tier colour.
	if tier >= 2 then
		local rim = frame({ BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, root)
		local s = Instance.new("UIStroke")
		s.Color = TITLE_COLORS[tier][1]
		s.Thickness = 10 + tier * 6
		s.Transparency = 0.35
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = rim
		fadeLater(s, "Transparency")
	end

	-- LIGHT RAYS (great+): a starburst behind the title. Each ray is a long
	-- bar through the centre, so 12 bars make 24 rays.
	local rays = {}
	if tier >= 2 then
		local len = 1800
		for i = 1, 12 do
			local r = frame({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = at,
				Size = UDim2.fromOffset(tier >= 4 and 90 or 60, len),
				BackgroundColor3 = TITLE_COLORS[tier][1],
				BackgroundTransparency = 0.55,
				Rotation = i * 15,
				ZIndex = 3,
			}, root)
			local g = Instance.new("UIGradient")
			g.Rotation = 90
			g.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.42, 0.55),
				NumberSequenceKeypoint.new(0.5, 0.2),
				NumberSequenceKeypoint.new(0.58, 0.55),
				NumberSequenceKeypoint.new(1, 1),
			})
			g.Parent = r
			fadeLater(r, "BackgroundTransparency")
			table.insert(rays, r)
		end
	end

	-- PARTICLES: sparkles (nice+) fly out and shrink; confetti (great+) is
	-- thrown up and falls. One RenderStepped loop moves them all.
	local parts = {}
	local function spawnPart(isConfetti)
		local size = isConfetti and math.random(9, 16) or math.random(8, 14)
		local p = frame({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = at,
			Size = UDim2.fromOffset(size, isConfetti and math.floor(size * 0.6) or size),
			BackgroundColor3 = isConfetti and CONFETTI[math.random(1, #CONFETTI)] or Color3.new(1, 1, 1),
			Rotation = math.random(0, 359),
			ZIndex = isConfetti and 8 or 9,
		}, root)
		if not isConfetti then
			p.Rotation = 45
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 2)
			c.Parent = p
		end
		local ang = math.random() * math.pi * 2
		local speed = isConfetti and (0.35 + math.random() * 0.55) or (0.25 + math.random() * 0.3)
		table.insert(parts, {
			inst = p,
			x = cx, y = cy,
			vx = math.cos(ang) * speed * 0.6,
			vy = isConfetti and (-0.6 - math.random() * 0.7) or math.sin(ang) * speed,
			spin = (math.random() - 0.5) * 720,
			confetti = isConfetti,
			life = isConfetti and (1.6 + math.random() * 1.4) or (0.5 + math.random() * 0.35),
			age = 0,
		})
	end
	for _ = 1, 8 + tier * 4 do
		spawnPart(false)
	end
	-- opts.confetti = false when the reveal throws its own (lucky blocks, cases).
	local ownConfetti = opts.confetti ~= false
	local confetti = (not ownConfetti and 0) or (calm and math.floor(CONFETTI_COUNT[tier] / 3)) or CONFETTI_COUNT[tier]
	for _ = 1, confetti do
		spawnPart(true)
	end
	if tier >= 4 and not calm and ownConfetti then
		-- A second wave half a second later: legendary keeps raining.
		task.delay(0.5, function()
			if me.alive then
				for _ = 1, 80 do
					spawnPart(true)
				end
			end
		end)
	end

	-- TITLE (great+, or whenever the caller names it).
	local title
	local titleGrad
	if tier >= 2 or opts.title then
		title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.AnchorPoint = Vector2.new(0.5, 0.5)
		title.Position = UDim2.fromScale(cx, math.max(0.12, cy - 0.16))
		title.Size = UDim2.fromOffset(900, 140)
		title.Font = T.FONT
		title.Text = opts.title or NAMES[tier]
		title.TextSize = math.max(TITLE_SIZE[tier], 48)
		title.TextColor3 = Color3.new(1, 1, 1)
		title.ZIndex = 20
		title.Active = false
		title.Parent = root
		local st = Instance.new("UIStroke")
		st.Color = T.OUTLINE
		st.Thickness = 3 + tier
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		st.Parent = title
		titleGrad = Instance.new("UIGradient")
		titleGrad.Rotation = 90
		titleGrad.Color = ColorSequence.new(TITLE_COLORS[tier][1], TITLE_COLORS[tier][2])
		titleGrad.Parent = title
		local sc = Instance.new("UIScale")
		sc.Scale = 0.2
		sc.Parent = title
		TweenService:Create(sc, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		fadeLater(title, "TextTransparency")
		fadeLater(st, "Transparency")
	end

	-- THE LOOP: particles, rays, shake, rainbow, then fade and clean up.
	local hold = HOLD[tier]
	local fadeT = 0.45
	local t = 0
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		if not me.alive or not root.Parent then
			conn:Disconnect()
			return
		end
		t += dt
		for i = #parts, 1, -1 do
			local p = parts[i]
			p.age += dt
			if p.age >= p.life then
				p.inst:Destroy()
				table.remove(parts, i)
			else
				if p.confetti then
					p.vy += 1.25 * dt -- gravity, in screen heights per second squared
					p.vx *= (1 - 0.6 * dt)
				else
					p.vx *= (1 - 3 * dt)
					p.vy *= (1 - 3 * dt)
				end
				p.x += p.vx * dt
				p.y += p.vy * dt
				p.inst.Position = UDim2.fromScale(p.x, p.y)
				p.inst.Rotation += p.spin * dt
				local k = p.age / p.life
				if not p.confetti then
					local s = 1 - k
					p.inst.Size = UDim2.fromOffset(math.max(1, 14 * s), math.max(1, 14 * s))
				end
				if k > 0.75 then
					p.inst.BackgroundTransparency = (k - 0.75) / 0.25
				end
			end
		end
		if not calm then
			for i, r in ipairs(rays) do
				r.Rotation = i * 15 + t * (tier >= 4 and 40 or 22)
			end
			-- A shake that decays fast: a thump, not a rattle.
			if tier >= 3 and t < 0.6 then
				local amp = (tier >= 4 and 14 or 8) * (1 - t / 0.6)
				root.Position = UDim2.fromOffset((math.random() - 0.5) * amp, (math.random() - 0.5) * amp)
			else
				root.Position = UDim2.fromOffset(0, 0)
			end
		end
		if tier >= 4 and titleGrad then
			-- Rainbow that scrolls through the letters.
			local h = (t * 0.35) % 1
			titleGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(h, 0.6, 1)),
				ColorSequenceKeypoint.new(0.5, Color3.fromHSV((h + 0.15) % 1, 0.75, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV((h + 0.3) % 1, 0.85, 1)),
			})
		end
		if t > hold then
			local k = math.clamp((t - hold) / fadeT, 0, 1)
			for _, f in ipairs(fades) do
				local inst, prop, from = f[1], f[2], f[3]
				if inst.Parent then
					inst[prop] = from + (1 - from) * k
				end
			end
			if k >= 1 and #parts == 0 then
				conn:Disconnect()
				if current == me then
					current = nil
				end
				me.alive = false
				root:Destroy()
			end
		end
	end)
	return me
end

--[[
	SUSPENSE: a short drum-roll and dim before an epic+ reveal. Calls `reveal`
	when done. For anything below epic it calls `reveal` at once: the roll is a
	true tell, never a tease. Returns a skip function that reveals immediately.
]]
function MineCelebrate.suspense(tier, reveal)
	tier = math.floor(tonumber(tier) or 0)
	local done = false
	local function go()
		if done then
			return
		end
		done = true
		pcall(reveal)
	end
	if tier < 3 then
		go()
		return go
	end
	if Audio and Audio.playSuspense then
		pcall(Audio.playSuspense)
	end
	local gui = overlay()
	if gui then
		local dim = frame({
			Name = "Suspense", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1), ZIndex = 1,
		}, gui)
		TweenService:Create(dim, TweenInfo.new(0.9, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.45 }):Play()
		task.delay(1.05, function()
			dim:Destroy()
		end)
	end
	task.delay(1.05, go)
	return go
end

--[[
	SKIP: "TAP TO SKIP" for any reveal. Puts a full-screen catcher BEHIND the
	reveal's own buttons (ZIndex 1, so a tap on OPEN AGAIN still hits OPEN
	AGAIN) and a small hint pill at the bottom. `onSkip` fires once per tap.
	Returns a cleanup function.
]]
function MineCelebrate.skipHint(parent, onSkip, text)
	if not parent then
		return function() end
	end
	local catcher = Instance.new("TextButton")
	catcher.Name = "SkipCatcher"
	catcher.BackgroundTransparency = 1
	catcher.Text = ""
	catcher.AutoButtonColor = false
	catcher.Size = UDim2.fromScale(1, 1)
	catcher.ZIndex = 1
	catcher:SetAttribute("NoClickSfx", true)
	catcher.Parent = parent
	local hint = Instance.new("TextLabel")
	hint.Name = "SkipHint"
	hint.AnchorPoint = Vector2.new(0.5, 1)
	hint.Position = UDim2.new(0.5, 0, 1, -24)
	hint.Size = UDim2.fromOffset(190, 36)
	hint.BackgroundColor3 = T.PANEL
	hint.BackgroundTransparency = 0.15
	hint.Font = T.FONT
	hint.TextSize = 17
	hint.TextColor3 = T.TEXT
	hint.Text = text or "TAP TO SKIP"
	hint.ZIndex = 200
	hint.Active = false
	hint.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = hint
	local s = Instance.new("UIStroke")
	s.Color = T.OUTLINE
	s.Thickness = 2.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = hint
	hint:SetAttribute("MineUIAdopted", true)
	local conn = catcher.MouseButton1Click:Connect(function()
		pcall(onSkip)
	end)
	return function()
		conn:Disconnect()
		catcher:Destroy()
		hint:Destroy()
	end
end

return MineCelebrate
