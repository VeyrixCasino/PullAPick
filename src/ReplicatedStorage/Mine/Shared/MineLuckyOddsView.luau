--[[
	MineLuckyOddsView -- the odds sheet for a lucky block.

	Lucky blocks are sold for credits, which are bought with Robux, and Roblox
	requires a paid random item to show its odds. Owner, 2026-10-08: "fix all".
	The packs had their inspector; the blocks showed nothing.

	Two screens open it: the credit shop (and the bag's ⓘ) in MineInventoryView,
	and the lucky screen itself in MineGradeReveal, where a paid Grade Up changes
	the start grade and so the odds. The lucky screen sits above the inventory
	(DisplayOrder 120), so the sheet draws into whatever parent it is handed
	rather than living inside one of them.

	Every number comes from MineLuckyBlocks.oddsSheet, which reads the same
	tables rollLoot rolls, computed exactly (tools/verify/lucky-odds.js proves
	the sheet against the real roll). Nothing is typed in by hand.
]]

local shared = script.Parent
local T = require(shared:WaitForChild("MineTheme"))
local LB = require(shared:WaitForChild("MineLuckyBlocks"))

local MineLuckyOddsView = {}

local function mk(class, props, parent)
	local o = Instance.new(class)
	if o:IsA("GuiObject") then
		o.BorderSizePixel = 0
	end
	for k, v in pairs(props) do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local function round(o, r)
	mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o)
end

local function label(parent, text, size, colour, pos, sz, font)
	return mk("TextLabel", {
		BackgroundTransparency = 1, Text = text, TextSize = size, TextColor3 = colour or T.TEXT,
		Font = font or T.FONT_M, Position = pos or UDim2.new(), Size = sz or UDim2.new(1, 0, 0, size + 6),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
end

local function pct(p)
	p = (p or 0) * 100
	if p >= 10 then
		return string.format("%.1f%%", p)
	elseif p >= 0.1 then
		return string.format("%.2f%%", p)
	end
	return string.format("%.3f%%", p)
end

local GRADE_COLOUR = nil
local function gradeColour(g)
	if GRADE_COLOUR == nil then
		local ok, Temper = pcall(function()
			return require(shared:WaitForChild("MineTemper"))
		end)
		GRADE_COLOUR = (ok and Temper and Temper.colorOf) or false
	end
	return GRADE_COLOUR and GRADE_COLOUR(g) or nil
end

--[[
	Draw the sheet into `parent` (a ScreenGui or a frame). Returns the frame;
	its CLOSE button destroys it, and `onClose` is called if given.
]]
function MineLuckyOddsView.show(parent, blockId, startGrade, opts)
	opts = opts or {}
	local def = LB.TYPES[blockId] or {}
	local col = def.color or T.GOLD
	local start = startGrade or "F"
	local sheet = LB.oddsSheet(blockId, start)
	local z = opts.zIndex or 60

	local f = mk("Frame", {
		Name = "LuckyOdds",
		BackgroundColor3 = T.PANEL,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(440, 620),
		ZIndex = z,
		Active = true,
	}, parent)
	round(f, 16)
	mk("UIStroke", { Color = col, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
	f:SetAttribute("MineUIAdopted", true)
	-- Never taller than the screen it is drawn on.
	mk("UISizeConstraint", { MaxSize = Vector2.new(440, 620), MinSize = Vector2.new(300, 360) }, f)

	local titleL = label(f, string.upper(tostring(def.name or "Lucky Block")) .. "  ODDS", 22, col,
		UDim2.fromOffset(16, 12), UDim2.new(1, -32, 0, 28), T.FONT)
	titleL.TextXAlignment = Enum.TextXAlignment.Center
	titleL.ZIndex = z + 2
	local subL = label(f, string.format("Starts at %s, climbs a grade at a time, stops after 3 misses", start),
		12, T.MUTED, UDim2.fromOffset(16, 42), UDim2.new(1, -32, 0, 18))
	subL.TextXAlignment = Enum.TextXAlignment.Center
	subL.ZIndex = z + 2

	local body = mk("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 68), Size = UDim2.new(1, -32, 1, -130),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 5, ZIndex = z + 2,
	}, f)
	mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, body)
	local order = 0
	local function header(text)
		order += 1
		local h = label(body, text, 13, T.MUTED, UDim2.new(), UDim2.new(1, 0, 0, 24), T.FONT)
		h.LayoutOrder = order
		h.ZIndex = z + 3
		h.TextYAlignment = Enum.TextYAlignment.Bottom
	end
	local function row(name, p, tint)
		order += 1
		local line = mk("Frame", {
			BackgroundColor3 = T.CARD, Size = UDim2.new(1, -6, 0, 26), LayoutOrder = order, ZIndex = z + 3,
		}, body)
		round(line, 6)
		mk("Frame", { BackgroundColor3 = tint or col, Size = UDim2.fromOffset(4, 26), ZIndex = z + 4 }, line)
		local nl = label(line, name, 13, tint or T.TEXT, UDim2.fromOffset(12, 0), UDim2.new(1, -100, 1, 0), T.FONT)
		nl.ZIndex = z + 4
		local pl = label(line, pct(p), 13, T.TEXT, UDim2.new(1, -88, 0, 0), UDim2.fromOffset(80, 26), T.FONT)
		pl.TextXAlignment = Enum.TextXAlignment.Right
		pl.ZIndex = z + 4
	end

	header("FINAL GRADE")
	for _, g in ipairs({ "F", "D", "C", "B", "A", "S", "SS", "SSS" }) do
		local p = sheet.grades[g] or 0
		if p > 0 then
			row("Grade " .. g, p, gradeColour(g))
		end
	end

	header("WHAT YOU GET (one of these per open)")
	local kinds = {}
	for k, p in pairs(sheet.kinds) do
		table.insert(kinds, { k = k, p = p })
	end
	table.sort(kinds, function(a, b)
		return a.p > b.p
	end)
	for _, e in ipairs(kinds) do
		row((LB.KIND_NAMES and LB.KIND_NAMES[e.k]) or e.k, e.p)
	end

	if next(sheet.pets) then
		header("PET TIER (chance per open)")
		local okC, Cards = pcall(function()
			return require(shared:WaitForChild("MineCards"))
		end)
		for _, tier in ipairs({ "Legendary", "Mythic", "Divine", "Exotic" }) do
			if sheet.pets[tier] then
				local tint = okC and Cards and Cards.RARITY_COLOR and Cards.RARITY_COLOR[tier] or nil
				row(tier .. " pet", sheet.pets[tier], tint)
			end
		end
	end

	order += 1
	local note = label(body, (sheet.bonusDust and "Every open also adds bonus stardust on top. " or "")
		.. "Better grades pay bigger amounts. Grade Up (gems) raises the start grade before you open.",
		12, T.MUTED, UDim2.new(), UDim2.new(1, -6, 0, 34))
	note.TextWrapped = true
	note.LayoutOrder = order
	note.ZIndex = z + 3

	local closeB = mk("TextButton", {
		AutoButtonColor = true, BackgroundColor3 = T.CARD, Font = T.FONT, TextSize = 16,
		TextColor3 = T.TEXT, Text = "CLOSE",
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(160, 40), ZIndex = z + 3,
	}, f)
	round(closeB, 10)
	closeB.MouseButton1Click:Connect(function()
		f:Destroy()
		if opts.onClose then
			pcall(opts.onClose)
		end
	end)
	return f
end

return MineLuckyOddsView
