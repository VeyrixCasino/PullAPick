--[[
	MineGroupWheelView -- limited-week group prize wheel UI.

	Top copy teases Galaxy + Spark = EXOTIC. Free spin for group members;
	Robux packs bank paid spins. Sale window matches season week 1 packages.
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
	local d = math.floor(sec / 86400)
	local h = math.floor((sec % 86400) / 3600)
	local m = math.floor((sec % 3600) / 60)
	local s = sec % 60
	if d > 0 then
		return string.format("%dd %dh", d, h)
	end
	if h > 0 then
		return string.format("%dh %dm", h, m)
	end
	if m > 0 then
		return string.format("%dm %ds", m, s)
	end
	return string.format("%ds", s)
end

function MineGroupWheelView.mount(gui, opts)
	opts = opts or {}
	local net = opts.net
	local player = Players.LocalPlayer
	local getGroupId = opts.getGroupId or function()
		return 0
	end
	local buyProduct = opts.buyProduct or function(key)
		local prod = C.product and C.product(key)
		local pid = prod and tonumber(prod.productId) or 0
		if pid > 0 then
			MarketplaceService:PromptProductPurchase(player, pid)
		else
			-- Studio / unwired: still useful copy.
		end
	end
	local ctl = {}
	local state = Wheel.payload(nil, os.time())
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
	round(root, T.RADIUS_LG)
	stroke(root, T.GOLD, 2)

	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = T.FONT,
		TextSize = 26,
		TextColor3 = T.GOLD,
		Text = "GROUP WHEEL",
		Position = UDim2.fromOffset(20, 10),
		Size = UDim2.new(1, -80, 0, 30),
		ZIndex = 91,
	}, root)

	local tagline = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(20, 38),
		Size = UDim2.new(1, -80, 0, 28),
		ZIndex = 91,
	}, root)
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = T.FONT,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(255, 245, 160),
		Text = "Galaxy",
		Size = UDim2.fromOffset(56, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 92,
	}, tagline)
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = T.FONT_M,
		TextSize = 15,
		TextColor3 = T.MUTED,
		Text = "+",
		Position = UDim2.fromOffset(58, 0),
		Size = UDim2.fromOffset(18, 28),
		ZIndex = 92,
	}, tagline)
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = T.FONT,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(85, 220, 255),
		Text = "Spark",
		Position = UDim2.fromOffset(76, 0),
		Size = UDim2.fromOffset(48, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 92,
	}, tagline)
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = T.FONT_M,
		TextSize = 15,
		TextColor3 = T.MUTED,
		Text = "=",
		Position = UDim2.fromOffset(126, 0),
		Size = UDim2.fromOffset(18, 28),
		ZIndex = 92,
	}, tagline)
	-- Blacked-out mystery Exotic pet + ?
	local mysteryPet = mk("Frame", {
		Name = "MysteryPet",
		BackgroundColor3 = Color3.fromRGB(12, 10, 16),
		Position = UDim2.fromOffset(148, 1),
		Size = UDim2.fromOffset(26, 26),
		ZIndex = 92,
	}, tagline)
	round(mysteryPet, 13)
	stroke(mysteryPet, Color3.fromRGB(255, 55, 55), 1)
	mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(8, 6, 10),
		AnchorPoint = Vector2.new(0.5, 0.55),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromOffset(14, 16),
		ZIndex = 93,
		BorderSizePixel = 0,
	}, mysteryPet)
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = T.FONT,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 80, 100),
		Text = "?",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 94,
	}, mysteryPet)
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = T.FONT,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 80, 100),
		Text = "EXOTIC",
		Position = UDim2.fromOffset(180, 0),
		Size = UDim2.fromOffset(120, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 92,
	}, tagline)

	local sub = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = T.FONT_M,
		TextSize = 13,
		TextColor3 = T.MUTED,
		Text = "1 week limited · free spin for group · Robux packs",
		Position = UDim2.fromOffset(20, 66),
		Size = UDim2.new(1, -40, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 91,
	}, root)

	local xbtn = mk("TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = T.INK,
		Text = "X",
		Font = T.FONT,
		TextSize = 18,
		TextColor3 = T.TEXT,
		Position = UDim2.new(1, -44, 0, 12),
		Size = UDim2.fromOffset(32, 32),
		ZIndex = 92,
	}, root)
	round(xbtn, 8)

	local wheelHost = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(70, 88),
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
	round(disc, 170)
	stroke(disc, T.GOLD, 3)

	local wedgeLabels = {}
	local function paintWedges()
		for _, c in ipairs(disc:GetChildren()) do
			if c:IsA("GuiObject") and c.Name ~= "UICorner" and c.Name ~= "UIStroke" then
				c:Destroy()
			end
		end
		wedgeLabels = {}
		local segs = state.segments or Wheel.SEGMENTS
		local n = #segs
		for i, seg in ipairs(segs) do
			local ang = ((i - 0.5) / n) * math.pi * 2 - math.pi / 2
			local r = 108
			local x = math.cos(ang) * r
			local y = math.sin(ang) * r
			local isMystery = seg.mystery == true or seg.id == "exotic" or seg.reward and seg.reward.petPool == "droppable_exotic"
			local chip = mk("Frame", {
				Name = "W" .. i,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, x, 0.5, y),
				Size = UDim2.fromOffset(88, 46),
				BackgroundColor3 = isMystery and Color3.fromRGB(14, 12, 18) or (seg.color or T.GOLD),
				Rotation = math.deg(ang) + 90,
				ZIndex = 93,
			}, disc)
			round(chip, 8)
			if isMystery then
				stroke(chip, Color3.fromRGB(255, 55, 55), 1)
				-- Blacked-out pet silhouette + ?
				local sil = mk("Frame", {
					BackgroundColor3 = Color3.fromRGB(6, 5, 8),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, -2),
					Size = UDim2.fromOffset(22, 24),
					Rotation = -(math.deg(ang) + 90),
					ZIndex = 94,
					BorderSizePixel = 0,
				}, chip)
				round(sil, 10)
				mk("TextLabel", {
					BackgroundTransparency = 1,
					Font = T.FONT,
					TextSize = 20,
					TextColor3 = Color3.fromRGB(255, 70, 90),
					Text = "?",
					Size = UDim2.fromScale(1, 1),
					Rotation = -(math.deg(ang) + 90),
					ZIndex = 95,
				}, chip)
			else
				mk("TextLabel", {
					BackgroundTransparency = 1,
					Font = T.FONT,
					TextSize = 10,
					TextColor3 = Color3.new(0.1, 0.08, 0.05),
					Text = tostring(seg.label or "?"),
					Size = UDim2.new(1, -4, 0, 16),
					Position = UDim2.fromOffset(2, 3),
					TextScaled = true,
					ZIndex = 94,
				}, chip)
				mk("TextLabel", {
					BackgroundTransparency = 1,
					Font = T.FONT_M,
					TextSize = 9,
					TextColor3 = Color3.fromRGB(40, 30, 20),
					Text = tostring(seg.sub or ""),
					Size = UDim2.new(1, -4, 0, 22),
					Position = UDim2.fromOffset(2, 20),
					TextWrapped = true,
					ZIndex = 94,
				}, chip)
			end
			wedgeLabels[i] = chip
		end
		local hub = mk("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(58, 58),
			BackgroundColor3 = T.GOLD,
			ZIndex = 95,
		}, disc)
		round(hub, 29)
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Font = T.FONT,
			TextSize = 14,
			TextColor3 = T.ON_GOLD or Color3.fromRGB(30, 20, 10),
			Text = "SPIN",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 96,
		}, hub)
	end

	mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = T.FONT,
		TextSize = 26,
		TextColor3 = T.GOLD,
		Text = "▼",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -2),
		Size = UDim2.fromOffset(40, 28),
		ZIndex = 97,
	}, wheelHost)

	local status = mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = T.FONT_M,
		TextSize = 14,
		TextColor3 = T.TEXT,
		Text = "",
		Position = UDim2.fromOffset(20, 472),
		Size = UDim2.new(1, -40, 0, 20),
		ZIndex = 91,
	}, root)

	local spinBtn = mk("TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = T.GOLD,
		Font = T.FONT,
		TextSize = 18,
		TextColor3 = T.ON_GOLD or Color3.fromRGB(30, 20, 10),
		Text = "SPIN FREE",
		Position = UDim2.fromOffset(20, 500),
		Size = UDim2.fromOffset(220, 40),
		ZIndex = 92,
	}, root)
	round(spinBtn, 10)

	local joinBtn = mk("TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = Color3.fromRGB(60, 140, 255),
		Font = T.FONT,
		TextSize = 15,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "JOIN GROUP",
		Position = UDim2.fromOffset(252, 500),
		Size = UDim2.fromOffset(120, 40),
		ZIndex = 92,
		Visible = false,
	}, root)
	round(joinBtn, 10)

	local buyRow = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(20, 548),
		Size = UDim2.new(1, -40, 0, 68),
		ZIndex = 91,
	}, root)

	local buyBtns = {}
	local prices = {
		{ key = "group_wheel_1", label = "1 SPIN\nR$20" },
		{ key = "group_wheel_5", label = "5 SPINS\nR$80" },
		{ key = "group_wheel_10", label = "10 SPINS\nR$150" },
	}
	for i, row in ipairs(prices) do
		local btn = mk("TextButton", {
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(40, 36, 52),
			Font = T.FONT,
			TextSize = 13,
			TextColor3 = T.GOLD,
			Text = row.label,
			Position = UDim2.fromOffset((i - 1) * 160, 0),
			Size = UDim2.fromOffset(150, 56),
			ZIndex = 92,
		}, buyRow)
		round(btn, 10)
		stroke(btn, T.GOLD, 1)
		btn.MouseButton1Click:Connect(function()
			if not state.live then
				status.Text = "Week is over — come back next season."
				return
			end
			local prod = C.product and C.product(row.key)
			local pid = prod and tonumber(prod.productId) or 0
			if pid <= 0 then
				status.Text = "Product ID not wired yet — paste from Dashboard."
				return
			end
			buyProduct(row.key)
		end)
		buyBtns[i] = btn
	end

	local function refreshChrome()
		paintWedges()
		local left = tonumber(state.saleLeft) or Wheel.saleLeft()
		if state.live then
			sub.Text = "Ends in " .. fmtWait(left) .. " · paid spins: " .. tostring(state.paid or 0)
		else
			sub.Text = "Week ended — spins banked still work if you have them"
		end
		local paid = tonumber(state.paid) or 0
		if not state.live and paid <= 0 then
			status.Text = "Group Wheel week is over."
			spinBtn.Text = "ENDED"
			spinBtn.BackgroundColor3 = T.INK
			spinBtn.AutoButtonColor = false
		elseif paid > 0 then
			status.Text = string.format("%d paid spin%s ready.", paid, paid == 1 and "" or "s")
			spinBtn.Text = "SPIN (" .. paid .. ")"
			spinBtn.BackgroundColor3 = T.GOLD
			spinBtn.AutoButtonColor = true
		elseif state.ready then
			status.Text = "Free spin ready — Galaxy · Spark · mystery Exotic"
			spinBtn.Text = "SPIN FREE"
			spinBtn.BackgroundColor3 = T.GOLD
			spinBtn.AutoButtonColor = true
		else
			status.Text = "Next free spin in " .. fmtWait(state.wait)
			spinBtn.Text = "ON COOLDOWN"
			spinBtn.BackgroundColor3 = T.INK
		end
	end

	local function openGroupPage(gid)
		gid = tonumber(gid) or tonumber(getGroupId()) or 0
		if gid <= 0 then
			status.Text = "Group ID not set — tell an admin."
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
		status.Text = "Won big — favorite the game so you don't lose it!"
	end

	function ctl.setPayload(payload)
		if type(payload) == "table" then
			state = payload
			if not state.segments then
				state.segments = Wheel.SEGMENTS
			end
		end
		refreshChrome()
	end

	function ctl.open(payload)
		ctl.setPayload(payload or Wheel.payload(nil, os.time()))
		joinBtn.Visible = false
		root.Visible = true
	end

	function ctl.close()
		root.Visible = false
		spinning = false
	end

	function ctl.onResult(msg)
		if type(msg) ~= "table" then
			return
		end
		if msg.payload then
			ctl.setPayload(msg.payload)
		end
		if msg.reason == "bought" then
			status.Text = "Spins added — hit SPIN."
			return
		end
		if msg.ok then
			spinning = true
			spinBtn.Text = "SPINNING..."
			local segs = state.segments or Wheel.SEGMENTS
			local n = math.max(1, #segs)
			local index = math.clamp(tonumber(msg.index) or 1, 1, n)
			local target = -((index - 0.5) / n) * 360
			local turns = 5 * 360 + target
			disc.Rotation = disc.Rotation % 360
			local tw = TweenService:Create(disc, TweenInfo.new(4.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Rotation = disc.Rotation + turns,
			})
			tw:Play()
			tw.Completed:Connect(function()
				spinning = false
				local line = table.concat(msg.lines or { msg.sub or msg.label }, " · ")
				status.Text = tostring(msg.label or "WIN") .. " — " .. line
				refreshChrome()
				if msg.promptFavorite then
					task.delay(0.6, promptFavorite)
				end
			end)
		elseif msg.reason == "group" then
			joinBtn.Visible = true
			status.Text = "Join the group for free, or buy spins below."
			openGroupPage(msg.groupId)
		elseif msg.reason == "cooldown" then
			status.Text = "Next free spin in " .. fmtWait(msg.wait)
		elseif msg.reason == "ended" then
			status.Text = "Group Wheel week is over."
		end
	end

	xbtn.MouseButton1Click:Connect(ctl.close)
	spinBtn.MouseButton1Click:Connect(function()
		if spinning then return end
		local paid = tonumber(state.paid) or 0
		if not state.live and paid <= 0 then
			status.Text = "Group Wheel week is over."
			return
		end
		if paid <= 0 and not state.ready then
			status.Text = "Next free spin in " .. fmtWait(state.wait)
			return
		end
		if net then
			net:FireServer("groupWheelSpin")
		end
	end)
	joinBtn.MouseButton1Click:Connect(function()
		openGroupPage(getGroupId())
	end)

	paintWedges()
	ctl.root = root
	return ctl
end

return MineGroupWheelView
