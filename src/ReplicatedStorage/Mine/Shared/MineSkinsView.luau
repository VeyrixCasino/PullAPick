--[[
	MineSkinsView -- the skin wardrobe. 225 skins, 9 sets, F to SSS.

	Built to wiki/code/candy-style.md: MineUI constructors only, fat outline,
	text at the floors, juice on anything pressable, collapses in place.

	TIER COLOUR IS MineGear.RARITY_COLOR, not a MineTheme.CANDY key.

	The style page is explicit that each CANDY key carries a meaning -- gold is
	coins, cyan is gems, magenta is stardust -- and that a saturated fill must
	not be repainted. An eight-rung tier ladder would have eaten most of those
	meanings, so the ladder uses the grade ramp the rest of the game already
	reads for gear and tempers. A skin's F badge is the same grey as a gear F.

	Tier rides a BADGE, never the tile fill, for the same reason: the tile is a
	surface the kit owns and recolouring it would fight `adoptOne`.

	State comes from the snapshot -- `skins`, `skinEquipped`, `skinNotice`. The
	view owns no truth: equipping asks the server and waits for the next snap,
	because the server is where ownership is checked.
]]
local MineSkinsView = {}

local UI = require(script.Parent:WaitForChild("MineUI"))
local T = require(script.Parent:WaitForChild("MineTheme"))
local Skins = require(script.Parent:WaitForChild("MineSkins"))
local Gear = require(script.Parent:WaitForChild("MineGear"))

local TIER_COLOR = Gear.RARITY_COLOR
local ALL = "all"

-- Sets, in roster order, plus an "all" first.
local function setTabs()
	local tabs = { { key = ALL, name = "All" } }
	for _, s in ipairs(Skins.SETS or {}) do
		table.insert(tabs, { key = s.key, name = s.name })
	end
	return tabs
end

--[[
	Display name for a set key. MineSkins.LIST rows carry `set` (the key) and
	NOT a display name -- the names live on MineSkins.SETS.

	This exists because the first version read `s.setName`, which is nil on
	every row, inside `have and s.setName or "locked"`. A nil middle operand
	makes the whole `and` nil and the `or` takes over, so EVERY tile read
	"locked" including the 48 that were owned. The Studio shot is what caught
	it; the code looked right.
]]
local SET_NAME = {}
for _, s in ipairs(Skins.SETS or {}) do
	SET_NAME[s.key] = s.name
end

local function tierBadge(parent, tier)
	local b = UI.new("Frame", {
		BackgroundColor3 = TIER_COLOR[tier] or TIER_COLOR.F,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(44, 24),
		Position = UDim2.new(1, -50, 0, 6),
		ZIndex = 6,
	}, parent)
	UI.round(b, 8)
	UI.edge(b, T.OUTLINE, T.STROKE_CHUNKY)
	local l = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBlack,
		-- The tier IS the number here, so it gets the big type.
		TextSize = T.TEXT_BODY,
		Text = tier,
		TextColor3 = Color3.fromRGB(20, 12, 44),
		ZIndex = 7,
	}, b)
	return b, l
end

function MineSkinsView.mount(gui, opts)
	opts = opts or {}
	local state = { skins = {}, equipped = {}, filter = ALL, family = nil }

	local root = UI.panel(gui, UDim2.fromOffset(720, 460), UDim2.fromScale(0.5, 0.5))
	root.Name = "SkinsPanel"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Visible = false
	root.ZIndex = 40
	UI.edge(root, T.OUTLINE, T.STROKE_THICK)

	local title = UI.title(root, "SKINS", T.TEXT_TITLE)
	title.Position = UDim2.fromOffset(18, 12)
	title.Size = UDim2.fromOffset(240, 32)
	title.TextXAlignment = Enum.TextXAlignment.Left
	UI.outlineText(title)

	-- Owned count: the number is the biggest thing on the header.
	local countLbl = UI.text(root, "0 / 225", T.TEXT_TITLE)
	countLbl.Position = UDim2.new(1, -210, 0, 12)
	countLbl.Size = UDim2.fromOffset(150, 32)
	countLbl.TextXAlignment = Enum.TextXAlignment.Right
	countLbl.Font = Enum.Font.GothamBlack
	UI.outlineText(countLbl)

	local close = UI.button(root, "X", UDim2.fromOffset(44, 40), UDim2.new(1, -56, 0, 8), false, "red")
	UI.juice(close)

	-- Set tabs, scrolled sideways so nine fit without shrinking the type.
	local tabBar = UI.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -36, 0, 42),
		Position = UDim2.fromOffset(18, 54),
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ZIndex = 41,
	}, root)
	UI.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabBar)

	local grid = UI.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -36, 1, -164),
		Position = UDim2.fromOffset(18, 104),
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 41,
	}, root)
	UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(160, 84),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)

	-- The footer says what equipping will do, because a skin goes on a FAMILY
	-- and the player is holding one tool. Saying so beats a surprise.
	local foot = UI.muted(root, "", T.TEXT_BODY)
	foot.Position = UDim2.new(0, 18, 1, -48)
	foot.Size = UDim2.new(1, -36, 0, 32)
	foot.TextXAlignment = Enum.TextXAlignment.Left

	local tiles = {}

	local function redraw()
		local owned, total = 0, #(Skins.LIST or {})
		for _ in pairs(state.skins) do owned += 1 end
		UI.popNumber(countLbl)
		countLbl.Text = ("%d / %d"):format(owned, total)

		local fam = state.family
		foot.Text = fam
			and ("Equipping dresses your %s. One skin per tool class."):format(fam)
			or "Hold a tool to equip a skin on its class."

		for _, t in ipairs(tiles) do
			local s = t.skin
			local show = (state.filter == ALL) or (s.set == state.filter)
			t.frame.Visible = show
			if show then
				local have = state.skins[s.id] == true
				local on = fam and state.equipped[fam] == s.id
				t.name.TextTransparency = have and 0 or 0.45
				t.frame.BackgroundTransparency = have and 0 or 0.35
				t.badge.BackgroundTransparency = have and 0 or 0.45
				-- Written out rather than chained through and/or: that chain is
				-- what produced "locked" on every owned tile.
				if on then
					t.sub.Text = "EQUIPPED"
				elseif have then
					t.sub.Text = SET_NAME[s.set] or s.set
				else
					t.sub.Text = "locked"
				end
				t.sub.TextColor3 = on and Color3.fromRGB(120, 255, 170) or t.subColor
				--[[
					The equipped tile is marked by its OUTLINE, not by motion.

					"What pays out always moves" is about CLAIMABLES. A skin you
					are already wearing is a state, not a reward waiting to be
					taken, so pulsing it says the wrong thing -- and pulsing a
					UIGridLayout cell scaled the tile out of its own cell and
					left it blank on screen, which the Studio shot caught.
				]]
				if t.stroke then
					t.stroke.Color = on and Color3.fromRGB(120, 255, 170) or T.OUTLINE
					t.stroke.Thickness = on and T.STROKE_THICK or T.STROKE_CHUNKY
				end
			end
		end
	end

	for i, s in ipairs(Skins.LIST or {}) do
		local f = UI.card(grid, UDim2.fromOffset(160, 84))
		f.LayoutOrder = i
		local btn = UI.new("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			ZIndex = 8,
		}, f)
		UI.juice(btn)

		local nameLbl = UI.text(f, s.name, T.TEXT_BODY)
		nameLbl.Position = UDim2.fromOffset(10, 8)
		nameLbl.Size = UDim2.fromOffset(100, 40)
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextYAlignment = Enum.TextYAlignment.Top
		nameLbl.TextWrapped = true
		UI.outlineText(nameLbl)

		local sub = UI.muted(f, s.set, T.TEXT_MIN)
		sub.Position = UDim2.new(0, 10, 1, -26)
		sub.Size = UDim2.new(1, -20, 0, 18)
		sub.TextXAlignment = Enum.TextXAlignment.Left

		local badge = tierBadge(f, s.tier)

		btn.MouseButton1Click:Connect(function()
			if not state.skins[s.id] then
				return
			end
			if opts.onEquipSkin then
				-- The server decides; the view waits for the next snapshot.
				opts.onEquipSkin(s.id, state.family)
			end
		end)

		table.insert(tiles, {
			skin = s, frame = f, name = nameLbl, sub = sub, badge = badge,
			subColor = sub.TextColor3,
			-- MineUI.card already put a stroke on; reuse it rather than adding
			-- a second one on top of the kit's.
			stroke = f:FindFirstChildOfClass("UIStroke"),
		})
	end

	for _, tab in ipairs(setTabs()) do
		local b = UI.button(tabBar, tab.name, UDim2.fromOffset(math.max(84, #tab.name * 11 + 28), 34),
			nil, tab.key == ALL, "blue")
		UI.juice(b)
		b.MouseButton1Click:Connect(function()
			state.filter = tab.key
			redraw()
		end)
	end

	local ctl = { root = root }

	function ctl.setState(snap)
		if type(snap) ~= "table" then
			return
		end
		state.skins = snap.skins or {}
		state.equipped = snap.skinEquipped or {}
		state.family = snap.heldFamily or state.family
		redraw()
	end

	function ctl.setFamily(fam)
		state.family = fam
		redraw()
	end

	function ctl.open()
		root.Visible = true
		-- One UIScale per instance: pop is a channel on the shared FxScale.
		UI.pop(root, 0.9)
		redraw()
	end

	function ctl.close()
		root.Visible = false
	end

	function ctl.toggle()
		if root.Visible then ctl.close() else ctl.open() end
	end

	close.MouseButton1Click:Connect(ctl.close)
	return ctl
end

return MineSkinsView
