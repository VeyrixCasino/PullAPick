--[[
	MineSocialView -- friends, DMs, global chat, groups.
]]
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local T = require(RS.Mine.Shared:WaitForChild("MineTheme"))

local MineSocialView = {}

local function mk(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props or {}) do i[k] = v end
	if parent then i.Parent = parent end
	return i
end

local function round(f, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = f
end

function MineSocialView.mount(gui, opts)
	opts = opts or {}
	local net = opts.net
	local onOpenProfile = opts.onOpenProfile

	local root = mk("Frame", {
		Name = "SocialView",
		Visible = false,
		Active = true,
		BackgroundColor3 = T.PANEL,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(640, 520),
		ZIndex = 68,
		BorderSizePixel = 0,
	}, gui)
	round(root, 12)

	mk("TextLabel", {
		BackgroundTransparency = 1, Font = T.FONT, TextSize = 22, TextColor3 = T.TEXT,
		Text = "SOCIAL", Size = UDim2.new(1, -56, 0, 36), Position = UDim2.fromOffset(18, 10),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 69,
	}, root)
	local close = mk("TextButton", {
		Text = "X", Font = T.FONT, TextSize = 18, TextColor3 = T.TEXT,
		BackgroundColor3 = T.CARD, Size = UDim2.fromOffset(46, 46),
		Position = UDim2.new(1, -48, 0, 10), ZIndex = 69, BorderSizePixel = 0,
	}, root)
	round(close, 8)
	close.MouseButton1Click:Connect(function() root.Visible = false end)

	local tabs = mk("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 48),
		Size = UDim2.new(1, -32, 0, 32), ZIndex = 69,
	}, root)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, tabs)

	local pages = {}
	local current = "friends"

	local function makePage(name)
		local p = mk("Frame", {
			Name = name, Visible = false, BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 88), Size = UDim2.new(1, -32, 1, -160),
			ZIndex = 69,
		}, root)
		pages[name] = p
		return p
	end

	local friendsPage = makePage("friends")
	local chatPage = makePage("global")
	local dmPage = makePage("dm")
	local groupsPage = makePage("groups")

	local function tabBtn(id, label)
		local b = mk("TextButton", {
			Text = label, Font = T.FONT_M, TextSize = 13, TextColor3 = T.TEXT,
			BackgroundColor3 = T.CARD, Size = UDim2.fromOffset(100, 30),
			ZIndex = 70, BorderSizePixel = 0,
		}, tabs)
		round(b, 6)
		b.MouseButton1Click:Connect(function()
			current = id
			for name, page in pairs(pages) do
				page.Visible = name == id
			end
			for _, c in ipairs(tabs:GetChildren()) do
				if c:IsA("TextButton") then
					c.BackgroundColor3 = T.CARD
					c.TextColor3 = T.TEXT
				end
			end
			b.BackgroundColor3 = T.GOLD
			b.TextColor3 = Color3.fromRGB(22, 18, 12)
			if id == "groups" and net then net:FireServer("socialListGroups") end
		end)
		return b
	end

	local tFriends = tabBtn("friends", "Friends")
	tabBtn("global", "Global")
	tabBtn("dm", "Messages")
	tabBtn("groups", "Groups")
	tFriends.BackgroundColor3 = T.GOLD
	tFriends.TextColor3 = Color3.fromRGB(22, 18, 12)
	friendsPage.Visible = true

	-- Friends list
	local friendList = mk("ScrollingFrame", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0, ZIndex = 70,
	}, friendsPage)
	mk("UIListLayout", { Padding = UDim.new(0, 4) }, friendList)

	-- Global chat
	local globalLog = mk("ScrollingFrame", {
		BackgroundColor3 = T.CARD, BackgroundTransparency = 0.35,
		Size = UDim2.new(1, 0, 1, -40), ScrollBarThickness = 5,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0, ZIndex = 70,
	}, chatPage)
	round(globalLog, 8)
	mk("UIListLayout", { Padding = UDim.new(0, 3), VerticalAlignment = Enum.VerticalAlignment.Bottom }, globalLog)
	local globalBox = mk("TextBox", {
		PlaceholderText = "Say something…", Font = T.FONT_M, TextSize = 14,
		TextColor3 = T.TEXT, PlaceholderColor3 = T.MUTED, Text = "",
		BackgroundColor3 = T.CARD, Size = UDim2.new(1, -80, 0, 32),
		Position = UDim2.new(0, 0, 1, -32), ClearTextOnFocus = false, ZIndex = 70,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, chatPage)
	round(globalBox, 6)
	local globalSend = mk("TextButton", {
		Text = "Send", Font = T.FONT_M, TextSize = 13, TextColor3 = Color3.fromRGB(22, 18, 12),
		BackgroundColor3 = T.GOLD, Size = UDim2.fromOffset(72, 32),
		Position = UDim2.new(1, -72, 1, -32), ZIndex = 70, BorderSizePixel = 0,
	}, chatPage)
	round(globalSend, 6)

	-- DM
	local dmOther = nil
	local dmTitle = mk("TextLabel", {
		BackgroundTransparency = 1, Font = T.FONT_M, TextSize = 14, TextColor3 = T.MUTED,
		Text = "Open a friend to message", Size = UDim2.new(1, 0, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 70,
	}, dmPage)
	local dmLog = mk("ScrollingFrame", {
		BackgroundColor3 = T.CARD, BackgroundTransparency = 0.35,
		Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 1, -68),
		ScrollBarThickness = 5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0, ZIndex = 70,
	}, dmPage)
	round(dmLog, 8)
	mk("UIListLayout", { Padding = UDim.new(0, 3) }, dmLog)
	local dmBox = mk("TextBox", {
		PlaceholderText = "Direct message…", Font = T.FONT_M, TextSize = 14,
		TextColor3 = T.TEXT, PlaceholderColor3 = T.MUTED, Text = "",
		BackgroundColor3 = T.CARD, Size = UDim2.new(1, -80, 0, 32),
		Position = UDim2.new(0, 0, 1, -32), ClearTextOnFocus = false, ZIndex = 70,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, dmPage)
	round(dmBox, 6)
	local dmSend = mk("TextButton", {
		Text = "Send", Font = T.FONT_M, TextSize = 13, TextColor3 = Color3.fromRGB(22, 18, 12),
		BackgroundColor3 = T.GOLD, Size = UDim2.fromOffset(72, 32),
		Position = UDim2.new(1, -72, 1, -32), ZIndex = 70, BorderSizePixel = 0,
	}, dmPage)
	round(dmSend, 6)

	-- Groups
	local groupList = mk("ScrollingFrame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -40),
		ScrollBarThickness = 5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0, ZIndex = 70,
	}, groupsPage)
	mk("UIListLayout", { Padding = UDim.new(0, 4) }, groupList)
	local createTrade = mk("TextButton", {
		Text = "Create Trade Group", Font = T.FONT_M, TextSize = 13,
		TextColor3 = Color3.fromRGB(22, 18, 12), BackgroundColor3 = T.GOLD,
		Size = UDim2.new(0.48, -4, 0, 32), Position = UDim2.new(0, 0, 1, -32),
		ZIndex = 70, BorderSizePixel = 0,
	}, groupsPage)
	round(createTrade, 6)
	local createGen = mk("TextButton", {
		Text = "Create General Group", Font = T.FONT_M, TextSize = 13,
		TextColor3 = T.TEXT, BackgroundColor3 = T.CARD,
		Size = UDim2.new(0.48, -4, 0, 32), Position = UDim2.new(0.52, 0, 1, -32),
		ZIndex = 70, BorderSizePixel = 0,
	}, groupsPage)
	round(createGen, 6)

	local function chatLine(parent, name, text)
		local l = mk("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, Font = T.FONT_M, TextSize = 13,
			TextColor3 = T.TEXT, Text = string.format("[%s] %s", name or "?", text or ""),
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 71,
		}, parent)
	end

	local function clear(parent)
		for _, c in ipairs(parent:GetChildren()) do
			if c:IsA("GuiObject") then c:Destroy() end
		end
	end

	local ctl = {}

	function ctl.open()
		root.Visible = true
		if net then net:FireServer("socialListFriends") end
	end
	function ctl.close()
		root.Visible = false
	end
	function ctl.toggle()
		if root.Visible then ctl.close() else ctl.open() end
	end
	function ctl.isOpen()
		return root.Visible
	end

	function ctl.setFriends(payload)
		clear(friendList)
		if not payload then return end
		if payload.incoming and #payload.incoming > 0 then
			local hdr = mk("TextLabel", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22),
				Font = T.FONT, TextSize = 13, TextColor3 = T.GOLD, Text = "REQUESTS",
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 71,
			}, friendList)
			for _, uid in ipairs(payload.incoming) do
				local row = mk("Frame", {
					BackgroundColor3 = T.CARD, Size = UDim2.new(1, -4, 0, 40),
					ZIndex = 71, BorderSizePixel = 0,
				}, friendList)
				round(row, 6)
				mk("TextLabel", {
					BackgroundTransparency = 1, Text = "User " .. tostring(uid),
					Font = T.FONT_M, TextSize = 13, TextColor3 = T.TEXT,
					Size = UDim2.new(1, -160, 1, 0), Position = UDim2.fromOffset(10, 0),
					TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 72,
				}, row)
				local acc = mk("TextButton", {
					Text = "Accept", Font = T.FONT_M, TextSize = 12,
					TextColor3 = Color3.fromRGB(22, 18, 12), BackgroundColor3 = T.GOLD,
					Size = UDim2.fromOffset(70, 28), Position = UDim2.new(1, -150, 0.5, -14),
					ZIndex = 72, BorderSizePixel = 0,
				}, row)
				round(acc, 6)
				acc.MouseButton1Click:Connect(function()
					net:FireServer("friendAccept", uid)
				end)
				local dec = mk("TextButton", {
					Text = "Decline", Font = T.FONT_M, TextSize = 12, TextColor3 = T.TEXT,
					BackgroundColor3 = T.PANEL, Size = UDim2.fromOffset(70, 28),
					Position = UDim2.new(1, -74, 0.5, -14), ZIndex = 72, BorderSizePixel = 0,
				}, row)
				round(dec, 6)
				dec.MouseButton1Click:Connect(function()
					net:FireServer("friendDecline", uid)
				end)
			end
		end
		for _, f in ipairs(payload.friends or {}) do
			local row = mk("TextButton", {
				Text = "", BackgroundColor3 = T.CARD, Size = UDim2.new(1, -4, 0, 44),
				ZIndex = 71, BorderSizePixel = 0, AutoButtonColor = true,
			}, friendList)
			round(row, 6)
			mk("TextLabel", {
				BackgroundTransparency = 1,
				Text = string.format("%s  %s", f.name or "?", f.online and "●" or "○"),
				Font = T.FONT_M, TextSize = 14, TextColor3 = T.TEXT,
				Size = UDim2.new(1, -100, 1, 0), Position = UDim2.fromOffset(12, 0),
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 72,
			}, row)
			local msg = mk("TextButton", {
				Text = "Msg", Font = T.FONT_M, TextSize = 12, TextColor3 = T.TEXT,
				BackgroundColor3 = T.PANEL, Size = UDim2.fromOffset(44, 28),
				Position = UDim2.new(1, -96, 0.5, -14), ZIndex = 72, BorderSizePixel = 0,
			}, row)
			round(msg, 6)
			local prof = mk("TextButton", {
				Text = "Profile", Font = T.FONT_M, TextSize = 12,
				TextColor3 = Color3.fromRGB(22, 18, 12), BackgroundColor3 = T.GOLD,
				Size = UDim2.fromOffset(56, 28), Position = UDim2.new(1, -48, 0.5, -14),
				ZIndex = 72, BorderSizePixel = 0,
			}, row)
			round(prof, 6)
			msg.MouseButton1Click:Connect(function()
				dmOther = f.userId
				dmTitle.Text = "Chat with " .. (f.name or "?")
				current = "dm"
				for name, page in pairs(pages) do page.Visible = name == "dm" end
				net:FireServer("socialGetDM", f.userId)
			end)
			prof.MouseButton1Click:Connect(function()
				if onOpenProfile then onOpenProfile(f.userId) end
			end)
			row.MouseButton1Click:Connect(function()
				if onOpenProfile then onOpenProfile(f.userId) end
			end)
		end
	end

	function ctl.openDM(userId, name)
		dmOther = userId
		dmTitle.Text = "Chat with " .. (name or ("User " .. tostring(userId)))
		root.Visible = true
		current = "dm"
		for n, page in pairs(pages) do page.Visible = n == "dm" end
		if net then net:FireServer("socialGetDM", userId) end
	end

	function ctl.onMsg(payload)
		if not payload or not payload.msg then return end
		local m = payload.msg
		if payload.kind == "global" then
			chatLine(globalLog, m.name, m.text)
		elseif payload.kind == "dm" then
			if dmOther and (m.from == dmOther or m.to == dmOther or m.from == Players.LocalPlayer.UserId) then
				chatLine(dmLog, m.name, m.text)
			end
		elseif payload.kind == "group" then
			chatLine(globalLog, (m.name or "?") .. " @" .. (payload.groupId or ""):sub(1, 6), m.text)
		end
	end

	function ctl.setThread(payload)
		clear(dmLog)
		for _, m in ipairs((payload and payload.messages) or {}) do
			chatLine(dmLog, m.name, m.text)
		end
	end

	function ctl.setGroups(groups)
		clear(groupList)
		for _, g in ipairs(groups or {}) do
			local row = mk("Frame", {
				BackgroundColor3 = T.CARD, Size = UDim2.new(1, -4, 0, 48),
				ZIndex = 71, BorderSizePixel = 0,
			}, groupList)
			round(row, 6)
			mk("TextLabel", {
				BackgroundTransparency = 1,
				Text = string.format("%s  (%s)", g.name or "Group", g.kind or "general"),
				Font = T.FONT_M, TextSize = 14, TextColor3 = T.TEXT,
				Size = UDim2.new(1, -120, 1, 0), Position = UDim2.fromOffset(12, 0),
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 72,
			}, row)
			local leave = mk("TextButton", {
				Text = "Leave", Font = T.FONT_M, TextSize = 12, TextColor3 = T.TEXT,
				BackgroundColor3 = T.PANEL, Size = UDim2.fromOffset(56, 28),
				Position = UDim2.new(1, -64, 0.5, -14), ZIndex = 72, BorderSizePixel = 0,
			}, row)
			round(leave, 6)
			leave.MouseButton1Click:Connect(function()
				net:FireServer("socialLeaveGroup", g.id)
			end)
		end
	end

	globalSend.MouseButton1Click:Connect(function()
		local t = globalBox.Text
		globalBox.Text = ""
		if net and t ~= "" then net:FireServer("socialGlobal", t) end
	end)
	dmSend.MouseButton1Click:Connect(function()
		if not dmOther then return end
		local t = dmBox.Text
		dmBox.Text = ""
		if net and t ~= "" then net:FireServer("socialDM", { to = dmOther, text = t }) end
	end)
	createTrade.MouseButton1Click:Connect(function()
		net:FireServer("socialCreateGroup", { name = "Trade Lounge", kind = "trade" })
	end)
	createGen.MouseButton1Click:Connect(function()
		net:FireServer("socialCreateGroup", { name = "Hangout", kind = "general" })
	end)

	return ctl
end

return MineSocialView