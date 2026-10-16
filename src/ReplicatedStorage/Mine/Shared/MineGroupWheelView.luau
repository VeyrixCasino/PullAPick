--[[
	MineGroupWheelView -- the DAILY WHEEL panel.

	Owner, 2026-10-10 (docs/TODO.md NOW, A1): one free spin a day for everyone,
	+1 for group members, streak bonuses, odds printed. The rules live in
	MineGroupWheel (shared); this only draws them and reports the SPIN press.

	Follows wiki/code/candy-style.md: chunky, odds on every slice, the win
	celebrated by its REAL rarity through MineCelebrate, and never a "spend
	Robux" prompt in a region where paid random items are restricted.
]]

local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local shared = game:GetService("ReplicatedStorage"):WaitForChild("Mine"):WaitForChild("Shared")
local T = require(shared:WaitForChild("MineTheme"))
local C = require(shared:WaitForChild("MineConfig"))
local Wheel = require(shared:WaitForChild("MineGroupWheel"))

local MineGroupWheelView = {}

local function mk(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props or {}) do
		i[k] = v
	end
	if parent then i.Parent = parent end
	return i
end

local function round(o, r)
	mk("UICorner", { CornerRadius = UDim.new(0, r or T.RADIUS) }, o)
	return o
end

local function stroke(o, col, th)
	return mk("UIStroke", { Color = col or T.LINE, Thickness = th or T.STROKE }, o)
end

local function fmtWait(sec)
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	local h = math.floor(sec / 3600)
	local m = math.floor((sec % 3600) / 60)
	local s = sec % 60
	if h > 0 then
		return string.format("%dh %dm", h, m)
	end
	if m > 0 then
		return string.format("%dm %ds", m, s)
	end
	return string.format("%ds", s)
end

local function kit()
	local ok, UI = pcall(function()
		return require(shared:WaitForChild("MineUI"))
	end)
	return ok and UI or nil
end

function MineGroupWheelView.mount(gui, opts)
	opts = opts or {}
	local net = opts.net
	local player = Players.LocalPlayer
	local getGroupId = opts.getGroupId or function()
		return tonumber(C.GROUP_ID) or 0
	end
	local function productId(key)
		local prod = C.product and C.product(key)
		return prod and tonumber(prod.productId) or 0
	end
	local buyProduct = opts.buyProduct or function(key)
		local pid = productId(key)
		if pid > 0 then
			MarketplaceService:PromptProductPurchase(player, pid)
		end
	end
	local ctl = {}
	local state = { freeLeft = 0, freeTotal = Wheel.FREE_PER_DAY, paid = 0, resetIn = Wheel.resetIn(), segments = Wheel.SEGMENTS }
	-- When the state arrived, so the countdown can tick between snapshots.
	local stateAt = os.clock()
	local spinning = false

	local root = mk("Frame", {
		Name = "GroupWheelPanel",
		Visible = false,
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(520, 640),
		BackgroundColor3 = T.PANEL,
		ZIndex = 90,
	}, gui)
	round(root, T.RADIUS_LG + 4)
	stroke(root, T.OUTLINE, T.STROKE_THICK)

	local titleL = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = T.FONT,
		TextSize = 32,
		TextColor3 = T.GOLD,
		Text = "DAILY WHEEL",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(22, 12),
		Size = UDim2.new(1, -90, 0, 36),
		ZIndex = 91,
	}, root)

	local sub = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = T.FONT,
		TextSize = 17,
		TextColor3 = T.TEXT,
		Text = "",
		Position = UDim2.fromOffset(22, 52),
		Size = UDim2.new(1, -44, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 91,
	}, root)
	local how = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = T.FONT_M,
		TextSize = 14,
		TextColor3 = T.MUTED,
		Text = string.format("1 free spin every day  ·  +%d for group members  ·  +%d every %d-day login streak",
			Wheel.GROUP_BONUS, Wheel.STREAK_BONUS, Wheel.STREAK_EVERY),
		Position = UDim2.fromOffset(22, 76),
		Size = UDim2.new(1, -44, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 91,
	}, root)

	local xbtn = mk("TextButton", {
		Name = "Close",
		AutoButtonColor = false,
		BackgroundColor3 = T.RED,
		Text = "X",
		Font = T.FONT,
		TextSize = 22,
		TextColor3 = Color3.new(1, 1, 1),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(42, 42),
		ZIndex = 92,
	}, root)
	round(xbtn, 12)

	local wheelHost = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(70, 104),
		Size = UDim2.fromOffset(380, 380),
		ZIndex = 91,
	}, root)

	local disc = mk("Frame", {
		Name = "Disc",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(340, 340),
		BackgroundColor3 = T.INK,
		ZIndex = 92,
	}, wheelHost)
	-- Scale corner: the disc is resized by refit and must stay a circle.
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, disc)
	local wheelPx = 340
	stroke(disc, T.OUTLINE, 5)

	local function paintWedges()
		for _, c in ipairs(disc:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local segs = state.segments or Wheel.SEGMENTS
		local n = #segs
		for i, seg in ipairs(segs) do
			-- A segment runs OUTWARD: width is the arc it owns, height is the
			-- band from hub to rim, rotated so the text reads along the spoke.
			local ang = ((i - 0.5) / n) * math.pi * 2 - math.pi / 2
			local R = wheelPx * 0.5
			local rOut = R - math.max(6, R * 0.05)
			local rIn = math.max(24, R * 0.32)
			local r = (rIn + rOut) * 0.5
			local arcW = math.max(18, math.floor((2 * math.pi * r) / n) - 2)
			local bandH = rOut - rIn
			local isMystery = seg.mystery == true
			local chip = mk("Frame", {
				Name = "W" .. i,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, math.cos(ang) * r, 0.5, math.sin(ang) * r),
				Size = UDim2.fromOffset(arcW, bandH),
				BackgroundColor3 = isMystery and Color3.fromRGB(14, 12, 18) or (seg.color or T.GOLD),
				Rotation = math.deg(ang) + 90,
				ZIndex = 93,
			}, disc)
			round(chip, 8)
			stroke(chip, seg.hype and Color3.new(1, 1, 1) or T.OUTLINE, seg.hype and 2.5 or 1.5)
			-- The chip's top is the rim. Its outer half is narrower than its arc,
			-- so nothing overlaps it; toward the hub the neighbours overlap. So
			-- the name and the odds live in the outer half, and the flavour
			-- line (least important) below them.
			local nameLbl = mk("TextLabel", {
				BackgroundTransparency = 1,
				Font = T.FONT,
				TextColor3 = isMystery and Color3.fromRGB(255, 80, 100) or Color3.new(0.1, 0.08, 0.05),
				Text = isMystery and "?" or tostring(seg.label or "?"),
				Size = UDim2.new(1, -6, 0, math.floor(bandH * 0.32)),
				Position = UDim2.fromOffset(3, 5),
				TextWrapped = true,
				TextScaled = true,
				ZIndex = 94,
			}, chip)
			mk("UITextSizeConstraint", { MaxTextSize = isMystery and 26 or 16, MinTextSize = 7 }, nameLbl)
			-- The odds, on every slice, from the weights the server rolls: a dark
			-- pill so they read on every slice colour.
			local pillH = math.max(13, math.floor(bandH * 0.13))
			local pill = mk("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 7 + math.floor(bandH * 0.32)),
				Size = UDim2.new(1, -8, 0, pillH),
				BackgroundColor3 = Color3.fromRGB(20, 12, 44),
				BackgroundTransparency = 0.15,
				ZIndex = 95,
			}, chip)
			round(pill, pillH)
			local oddsLbl = mk("TextLabel", {
				BackgroundTransparency = 1,
				Font = T.FONT,
				TextColor3 = isMystery and Color3.fromRGB(255, 120, 140) or Color3.new(1, 1, 1),
				Text = Wheel.oddsText(seg),
				Size = UDim2.new(1, -4, 1, -2),
				Position = UDim2.fromOffset(2, 1),
				TextScaled = true,
				ZIndex = 96,
			}, pill)
			mk("UITextSizeConstraint", { MaxTextSize = 13, MinTextSize = 6 }, oddsLbl)
			if not isMystery then
				local subLbl = mk("TextLabel", {
					BackgroundTransparency = 1,
					Font = T.FONT_M,
					TextColor3 = Color3.fromRGB(40, 30, 20),
					Text = tostring(seg.sub or ""),
					Size = UDim2.new(1, -6, 0, math.floor(bandH * 0.22)),
					Position = UDim2.fromOffset(3, 9 + math.floor(bandH * 0.32) + pillH),
					TextWrapped = true,
					TextScaled = true,
					ZIndex = 94,
				}, chip)
				mk("UITextSizeConstraint", { MaxTextSize = 12, MinTextSize = 6 }, subLbl)
			end
		end
		local hub = mk("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(math.floor(wheelPx * 0.30), math.floor(wheelPx * 0.30)),
			BackgroundColor3 = T.GOLD,
			ZIndex = 95,
		}, disc)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, hub)
		stroke(hub, T.OUTLINE, 4)
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Font = T.FONT,
			TextSize = 22,
			TextColor3 = T.ON_GOLD or Color3.fromRGB(30, 20, 10),
			Text = "SPIN",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 96,
		}, hub)
	end

	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = T.FONT,
		TextSize = 34,
		TextColor3 = T.GOLD,
		Text = "▼",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -8),
		Size = UDim2.fromOffset(44, 34),
		ZIndex = 97,
	}, wheelHost)

	local status = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = T.FONT,
		TextSize = 18,
		TextColor3 = T.TEXT,
		Text = "",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -122),
		Size = UDim2.new(1, -40, 0, 24),
		ZIndex = 91,
	}, root)

	local spinBtn = mk("TextButton", {
		Name = "Spin",
		AutoButtonColor = false,
		BackgroundColor3 = T.GOLD,
		Font = T.FONT,
		TextSize = 24,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "SPIN FREE",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, -70, 1, -64),
		Size = UDim2.fromOffset(260, 52),
		ZIndex = 92,
	}, root)
	round(spinBtn, 16)

	local joinBtn = mk("TextButton", {
		Name = "Join",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(60, 140, 255),
		Font = T.FONT,
		TextSize = 15,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "JOIN GROUP\n+1 SPIN A DAY",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 150, 1, -64),
		Size = UDim2.fromOffset(160, 52),
		ZIndex = 92,
		Visible = false,
	}, root)
	round(joinBtn, 16)

	-- Paid spins. Shown only when the product is real AND the player's region
	-- allows paid random items; otherwise the row is simply not there.
	local buyRow = mk("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.fromOffset(480, 44),
		ZIndex = 91,
		Visible = false,
	}, root)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 10),
	}, buyRow)
	local anyProduct = false
	for _, key in ipairs(Wheel.PRODUCT_KEYS) do
		local prod = C.product and C.product(key) or {}
		if productId(key) > 0 then
			anyProduct = true
			local btn = mk("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = T.CARD_HI,
				Font = T.FONT,
				TextSize = 15,
				TextColor3 = T.GOLD,
				Text = string.format("%d SPIN%s  R$%d", tonumber(prod.spins) or 1,
					(tonumber(prod.spins) or 1) == 1 and "" or "S", tonumber(prod.robuxPrice) or 0),
				Size = UDim2.fromOffset(150, 40),
				ZIndex = 92,
			}, buyRow)
			round(btn, 12)
			btn.MouseButton1Click:Connect(function()
				if player:GetAttribute("PolicyNoRandom") == true then
					return
				end
				buyProduct(key)
			end)
		end
	end

	local function refreshChrome()
		paintWedges()
		local free = tonumber(state.freeLeft) or 0
		local paid = tonumber(state.paid) or 0
		local wait = math.max(0, (tonumber(state.resetIn) or 0) - (os.clock() - stateAt))
		local bits = { string.format("Free spins today: %d / %d", free, tonumber(state.freeTotal) or 1) }
		if paid > 0 then
			bits[#bits + 1] = string.format("Bought: %d", paid)
		end
		if state.streakDay then
			bits[#bits + 1] = "Streak bonus today!"
		end
		sub.Text = table.concat(bits, "   ·   ")
		joinBtn.Visible = state.member ~= true
		buyRow.Visible = anyProduct and player:GetAttribute("PolicyNoRandom") ~= true
		if spinning then
			return
		end
		if free > 0 then
			spinBtn.Text = free > 1 and string.format("SPIN FREE (%d)", free) or "SPIN FREE"
			spinBtn.BackgroundColor3 = T.GOLD
			status.Text = state.member and "Spin it!" or "Spin it! Group members get a 2nd spin every day."
		elseif paid > 0 and player:GetAttribute("PolicyNoRandom") ~= true then
			spinBtn.Text = string.format("SPIN (%d)", paid)
			spinBtn.BackgroundColor3 = T.GOLD
			status.Text = "Free spins used. Spinning a bought one."
		else
			spinBtn.Text = "BACK IN " .. fmtWait(wait)
			spinBtn.BackgroundColor3 = T.DEAD
			status.Text = "You've spun today. New free spins at midnight (UTC)."
		end
	end

	local function openGroupPage(gid)
		gid = tonumber(gid) or tonumber(getGroupId()) or 0
		if gid <= 0 then
			return
		end
		pcall(function()
			GuiService:OpenBrowserWindow("https://www.roblox.com/groups/" .. tostring(gid))
		end)
	end

	local function promptFavorite()
		pcall(function()
			local AES = game:GetService("AvatarEditorService")
			AES:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
		end)
	end

	function ctl.setPayload(payload)
		if type(payload) == "table" then
			for k, v in pairs(payload) do
				state[k] = v
			end
			state.segments = state.segments or Wheel.SEGMENTS
			stateAt = os.clock()
		end
		if root.Visible then
			refreshChrome()
		end
	end

	function ctl.open(payload)
		ctl.setPayload(payload)
		root.Visible = true
		refreshChrome()
	end

	function ctl.close()
		root.Visible = false
	end

	function ctl.isOpen()
		return root.Visible
	end

	function ctl.onResult(msg)
		if type(msg) ~= "table" then
			return
		end
		if msg.payload then
			ctl.setPayload(msg.payload)
		end
		if msg.reason == "bought" then
			status.Text = "Spins added! Hit SPIN."
			refreshChrome()
			return
		end
		if not msg.ok then
			spinning = false
			refreshChrome()
			if msg.reason == "region" then
				status.Text = "Bought spins aren't available in your region."
			end
			return
		end
		spinning = true
		spinBtn.Text = "SPINNING..."
		local segs = state.segments or Wheel.SEGMENTS
		local n = math.max(1, #segs)
		local index = math.clamp(tonumber(msg.index) or 1, 1, n)
		--[[
			Land on the slice the SERVER rolled, every time. The target is an
			ABSOLUTE angle: slice i sits under the top pointer when the disc's
			rotation is -((i - 0.5) / n) * 360 (mod 360). It used to add the
			target to whatever angle the last spin stopped at, so every spin
			after the first landed on the wrong slice.
		]]
		local target = (-((index - 0.5) / n) * 360) % 360
		local from = disc.Rotation
		local base = from - (from % 360)
		local goal = base + 5 * 360 + target
		if goal - from < 4 * 360 then
			goal += 360
		end
		local tw = TweenService:Create(disc, TweenInfo.new(4.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Rotation = goal,
		})
		tw:Play()
		tw.Completed:Connect(function()
			spinning = false
			local line = table.concat(msg.lines or { msg.sub or msg.label }, "  ·  ")
			-- The celebration is sized by the slice's REAL odds; a chase slice
			-- is always at least a GREAT (candy-style rule 10).
			pcall(function()
				local Celebrate = require(shared:WaitForChild("MineCelebrate"))
				local tier = Celebrate.fromOneIn(msg.oneIn)
				if msg.hype then
					tier = math.max(tier, 2)
				end
				Celebrate.burst(tier, { title = tier >= 2 and tostring(msg.label or "") or nil })
			end)
			refreshChrome()
			status.Text = tostring(msg.label or "WIN") .. "!  " .. line
			if msg.promptFavorite then
				task.delay(1.2, promptFavorite)
			end
		end)
	end

	xbtn.MouseButton1Click:Connect(ctl.close)
	spinBtn.MouseButton1Click:Connect(function()
		if spinning then
			return
		end
		local free = tonumber(state.freeLeft) or 0
		local paid = tonumber(state.paid) or 0
		if free <= 0 and (paid <= 0 or player:GetAttribute("PolicyNoRandom") == true) then
			return
		end
		spinning = true
		spinBtn.Text = "SPINNING..."
		if net then
			net:FireServer("groupWheelSpin")
		end
		-- If the server refuses or the reply is lost, never strand the button.
		task.delay(8, function()
			if spinning and spinBtn.Text == "SPINNING..." then
				spinning = false
				refreshChrome()
			end
		end)
	end)
	joinBtn.MouseButton1Click:Connect(function()
		openGroupPage(getGroupId())
	end)

	-- Candy: the kit's shapes and juice on the panel's own buttons.
	do
		local UI = kit()
		if UI then
			UI.candy(spinBtn, "gold", 3)
			UI.outlineText(spinBtn, 2.5)
			UI.juice(spinBtn)
			UI.candy(joinBtn, "blue", 3)
			UI.outlineText(joinBtn, 1.5)
			UI.juice(joinBtn)
			UI.candy(xbtn, "red", 3)
			UI.outlineText(xbtn, 2)
			UI.juice(xbtn, 1.12)
			UI.outlineText(titleL, 3)
			titleL.TextColor3 = T.GOLD
		end
	end

	-- The countdown on the button ticks while the panel is open.
	task.spawn(function()
		while root.Parent do
			if root.Visible and not spinning and (tonumber(state.freeLeft) or 0) <= 0 then
				refreshChrome()
			end
			task.wait(1)
		end
	end)

	--[[
		THE WHEEL IS THE SCREEN. The panel takes the window and the disc takes
		everything between the header and the buttons; the wedge geometry reads
		wheelPx, so a resize is a repaint.
	]]
	local function refit()
		local cam = workspace.CurrentCamera
		local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
		local W = math.max(320, vp.X)
		local H = math.max(240, vp.Y)
		local pw = math.clamp(math.floor(W * 0.92), 320, 1180)
		local ph = math.clamp(math.floor(H * 0.94), 300, 980)
		root.Size = UDim2.fromOffset(pw, ph)
		local topPad, botPad = 110, 160
		local d = math.max(200, math.min(pw - 48, ph - topPad - botPad))
		wheelHost.AnchorPoint = Vector2.new(0.5, 0)
		wheelHost.Position = UDim2.new(0.5, 0, 0, topPad)
		wheelHost.Size = UDim2.fromOffset(d, d)
		disc.Size = UDim2.fromOffset(d, d)
		wheelPx = d
		paintWedges()
	end

	refit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
	end

	--[[
		THE WORLD WHEEL'S IDLE SPIN, ON THIS CLIENT.

		The server builds the wheel and never moves it (GroupWheelService). Here
		it turns about its pivot's up axis, which the server set to the axle.
		Under StreamingEnabled the wheel can arrive in pieces, and it can leave
		and come back, so the pose is recorded only once all PartCount parts
		are present, and recorded again whenever a new copy of the wheel
		arrives. A wheel far from the camera is left alone.
	]]
	do
		local RunService = game:GetService("RunService")
		local current, base, t0 = nil, nil, os.clock()
		local function complete(m)
			local want = tonumber(m:GetAttribute("PartCount")) or 0
			local n = 0
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("BasePart") then
					n += 1
				end
			end
			return n >= want
		end
		local nextLook = 0
		RunService.RenderStepped:Connect(function()
			if not (current and current.Parent) then
				current, base = nil, nil
				local now = os.clock()
				if now < nextLook then
					return
				end
				nextLook = now + 0.5
				local world = workspace:FindFirstChild("MineWorld")
				local lobby = world and world:FindFirstChild("Lobby")
				local folder = lobby and lobby:FindFirstChild("GroupWheel")
				local m = folder and folder:FindFirstChild("Wheel")
				if m and m:IsA("Model") and complete(m) then
					current, base = m, m:GetPivot()
				end
				return
			end
			local cam = workspace.CurrentCamera
			if cam and (cam.CFrame.Position - base.Position).Magnitude > 450 then
				return
			end
			local speed = math.rad(tonumber(current:GetAttribute("SpinSpeed")) or 16)
			current:PivotTo(base * CFrame.Angles(0, (os.clock() - t0) * speed, 0))
		end)
	end

	ctl.root = root
	return ctl
end

return MineGroupWheelView
