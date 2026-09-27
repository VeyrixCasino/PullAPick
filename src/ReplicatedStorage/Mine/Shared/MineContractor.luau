--[[
	MineContractor -- the Job Board: EVERY quest in one place.

	Opened from the world Job Board pad (machine = "contractor") and the Jobs
	dock button. Shows the daily login, the quest-ladder rung, the day's three
	quests, the three contracts, and any milestones that are ready — and every
	row says what it feeds the battle pass, off the same MineScrolls table the
	server grants from.

	Claims: opts.onClaimContract(i), onClaimDailyQuest(i), onClaimQuest(),
	onClaimMilestone(id), onClaimDaily(). State comes from the snapshot.
]]

local MineContractor = {}

local Scrolls = require(game:GetService("ReplicatedStorage").Mine.Shared:WaitForChild("MineScrolls"))

local T = require(game:GetService("ReplicatedStorage").Mine.Shared:WaitForChild("MineTheme"))
local FONT = T.FONT
local FONT_M = T.FONT_M
local BG = T.BG
local BG2 = T.BG2
local TEXT = T.TEXT
local MUTED = T.MUTED
local GOLD = T.GOLD
local GREEN = T.GREEN

local function mk(class, props, parent)
	local o = Instance.new(class)
	if props and props.BorderSizePixel == nil and o:IsA("GuiObject") then
		props.BorderSizePixel = 0
	end
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local function round(o, r)
	local u = Instance.new("UICorner")
	u.CornerRadius = UDim.new(0, r or 8)
	u.Parent = o
end

local function stroke(o, t, col)
	local s = Instance.new("UIStroke")
	s.Thickness = t or 1
	s.Color = col or Color3.fromRGB(70, 70, 84)
	s.Transparency = 0.35
	s.Parent = o
end

function MineContractor.mount(parent, opts)
	opts = opts or {}
	local state = { contracts = {} }
	local ctl = {}

	local root = mk("Frame", {
		Name = "Contractor",
		Visible = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		-- Scale-based so phones get a board that fits; the constraint stops it
		-- ballooning on desktop.
		Size = UDim2.fromScale(0.52, 0.82),
		BackgroundColor3 = BG,
		ZIndex = 40,
	}, parent)
	round(root, 14)
	stroke(root, 1.5)
	mk("UISizeConstraint", {
		MaxSize = Vector2.new(640, 660),
		MinSize = Vector2.new(320, 300),
	}, root)

	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT, TextSize = 22, TextColor3 = TEXT,
		Text = "JOB BOARD", Position = UDim2.fromOffset(20, 14),
		Size = UDim2.new(1, -80, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 41,
	}, root)
	mk("TextLabel", {
		BackgroundTransparency = 1, Font = FONT_M, TextSize = 13, TextColor3 = MUTED,
		Text = "Every quest in one place. Claims also feed the Battle Pass — each row says how much.",
		Position = UDim2.fromOffset(20, 42), Size = UDim2.new(1, -40, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 41,
	}, root)

	local close = mk("TextButton", {
		AutoButtonColor = true, BackgroundColor3 = BG2, Font = FONT, TextSize = 18,
		TextColor3 = TEXT, Text = "X", Position = UDim2.new(1, -48, 0, 12),
		Size = UDim2.fromOffset(36, 32), ZIndex = 41,
	}, root)
	round(close, 8)
	close.MouseButton1Click:Connect(function()
		root.Visible = false
	end)

	local body = mk("ScrollingFrame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 72),
		Size = UDim2.new(1, -32, 1, -88), CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ZIndex = 41,
	}, root)
	mk("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, body)

	local function clear()
		for _, c in ipairs(body:GetChildren()) do
			if not c:IsA("UIListLayout") then
				c:Destroy()
			end
		end
	end

	local XP = Scrolls.PASS_XP_AWARD or { quest = 50, daily = 75, contract = 100, milestone = 60 }

	local function sectionHdr(text, order)
		local h = mk("Frame", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20),
			LayoutOrder = order, ZIndex = 42,
		}, body)
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 13, TextColor3 = GOLD,
			Text = string.upper(text), Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
		}, h)
	end

	-- One shape for every kind of quest: name, bar, payout, pass XP, button.
	local function questRow(order, q, xp, onClaim)
		local row = mk("Frame", {
			BackgroundColor3 = BG2, Size = UDim2.new(1, 0, 0, 84),
			LayoutOrder = order, ZIndex = 42,
		}, body)
		round(row, 10)
		stroke(row, 1, q.ready and GOLD or nil)
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 15,
			TextColor3 = q.claimed and MUTED or TEXT,
			Text = tostring(q.text), Position = UDim2.fromOffset(14, 8),
			Size = UDim2.new(1, -160, 0, 20), TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 43,
		}, row)
		local goal = math.max(1, tonumber(q.goal) or 1)
		local cur = math.clamp(tonumber(q.current) or 0, 0, goal)
		local track = mk("Frame", {
			BackgroundColor3 = Color3.fromRGB(30, 28, 36),
			Position = UDim2.fromOffset(14, 34), Size = UDim2.new(1, -174, 0, 10),
			ZIndex = 43,
		}, row)
		round(track, 5)
		if cur > 0 then
			local fill = mk("Frame", {
				BackgroundColor3 = q.ready and GREEN or GOLD,
				Size = UDim2.new(cur / goal, 0, 1, 0), ZIndex = 44,
			}, track)
			round(fill, 5)
		end
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT_M, TextSize = 12, TextColor3 = MUTED,
			Text = string.format("%s / %s", tostring(cur), tostring(goal)),
			Position = UDim2.fromOffset(14, 46), Size = UDim2.fromOffset(140, 16),
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
		}, row)
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT_M, TextSize = 12, TextColor3 = GOLD,
			Text = tostring(q.reward or ""), Position = UDim2.fromOffset(14, 62),
			Size = UDim2.new(1, -300, 0, 16), TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 43,
		}, row)
		if (tonumber(xp) or 0) > 0 then
			-- The pass chip: what this claim feeds the Battle Pass. Same table
			-- the server grants from, so this cannot over- or under-promise.
			local chip = mk("Frame", {
				BackgroundColor3 = Color3.fromRGB(56, 44, 88),
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -146, 1, -8), Size = UDim2.fromOffset(104, 18),
				ZIndex = 43,
			}, row)
			round(chip, 9)
			mk("TextLabel", {
				BackgroundTransparency = 1, Font = FONT, TextSize = 11,
				TextColor3 = Color3.fromRGB(198, 178, 255),
				Text = "+" .. tostring(xp) .. " PASS XP", Size = UDim2.fromScale(1, 1),
				TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 44,
			}, chip)
		end
		local b = mk("TextButton", {
			AutoButtonColor = q.ready and true or false,
			BackgroundColor3 = q.claimed and BG or (q.ready and GREEN or BG),
			Font = FONT, TextSize = 14,
			TextColor3 = q.ready and Color3.fromRGB(10, 26, 16) or MUTED,
			Text = q.claimed and "Claimed" or (q.ready and "CLAIM" or "In progress"),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(120, 40),
			Active = q.ready and true or false, ZIndex = 43,
		}, row)
		round(b, 8)
		if q.ready and onClaim then
			b.MouseButton1Click:Connect(onClaim)
		end
	end

	local function paint()
		clear()
		local order = 0
		local function nextOrder()
			order += 1
			return order
		end

		-- The daily login streak: the cheapest claim in the game goes first.
		local d = state.daily
		if type(d) == "table" then
			sectionHdr("Daily login", nextOrder())
			questRow(nextOrder(), {
				text = d.ready and ("Day " .. tostring(d.day or 1) .. " login reward is ready")
					or ("Come back tomorrow — streak " .. tostring(d.streak or 0)),
				current = d.ready and 1 or 0,
				goal = 1,
				ready = d.ready and true or false,
				claimed = not d.ready,
				reward = tostring(d.text or ""),
			}, 0, function()
				if opts.onClaimDaily then
					opts.onClaimDaily()
				end
			end)
		end

		-- The quest ladder rung the HUD card tracks.
		local q = state.quest
		if type(q) == "table" and not q.done then
			sectionHdr(string.format("Quest %s / %s", tostring(q.index or 1), tostring(q.total or "?")), nextOrder())
			questRow(nextOrder(), q, XP.quest, function()
				if opts.onClaimQuest then
					opts.onClaimQuest()
				end
			end)
		end

		-- The day's three quests.
		local dailies = state.dailyQuests or {}
		if #dailies > 0 then
			sectionHdr("Daily quests — reset each UTC day", nextOrder())
			for i, row in ipairs(dailies) do
				questRow(nextOrder(), row, XP.daily, function()
					if opts.onClaimDailyQuest then
						opts.onClaimDailyQuest(i)
					end
				end)
			end
		end

		-- The board's three contracts.
		local list = state.contracts or {}
		if #list > 0 then
			sectionHdr("Contracts — bigger jobs, bigger gems", nextOrder())
			for i, row in ipairs(list) do
				questRow(nextOrder(), row, XP.contract, function()
					if opts.onClaimContract then
						opts.onClaimContract(i)
					end
				end)
			end
		end

		-- Milestones are lifetime; only the ones worth acting on take space here.
		local shownMs = 0
		for _, m in ipairs(state.milestones or {}) do
			if m.ready then
				if shownMs == 0 then
					sectionHdr("Milestones ready", nextOrder())
				end
				shownMs += 1
				questRow(nextOrder(), m, XP.milestone, function()
					if opts.onClaimMilestone then
						opts.onClaimMilestone(m.id)
					end
				end)
			end
		end

		if order == 0 then
			mk("TextLabel", {
				BackgroundTransparency = 1, Font = FONT_M, TextSize = 15, TextColor3 = MUTED,
				Text = "Nothing posted yet.", Size = UDim2.new(1, 0, 0, 40),
				LayoutOrder = 1, ZIndex = 42,
			}, body)
		end
	end

	function ctl.setState(snap)
		if type(snap) == "table" then
			state.contracts = snap.contracts or {}
			state.dailyQuests = snap.dailyQuests or {}
			state.quest = snap.quest
			state.daily = snap.daily
			state.milestones = snap.milestones or {}
		end
		if root.Visible then
			paint()
		end
	end

	function ctl.open()
		root.Visible = true
		paint()
	end

	function ctl.close()
		root.Visible = false
	end

	ctl.root = root
	return ctl
end

return MineContractor
