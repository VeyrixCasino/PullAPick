--[[
	MineBenchView: the blacksmith's ore-tool bench.

	One row per ore tool you own, each showing what the next level costs and
	what scrapping it returns. Levelling is paid in the tool's OWN ore plus
	stardust, so a row is only actionable when you are holding the right rock.

	Every button sends a UID, never a row index. The list reorders whenever a
	tool is found or scrapped, and an index captured when the panel was drawn
	names a different tool by the time the button is pressed -- the same trap
	packs already fell into.

	Pricing is never computed here. MineConfig owns it (toolUpgradeCost,
	toolSpent, toolRecycle) so the panel and the server cannot disagree about
	what something costs; a panel that quotes its own number will eventually
	quote a different one.
]]
local MineBenchView = {}

local RS = game:GetService("ReplicatedStorage")
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared:WaitForChild("MineConfig"))
local Tools = require(shared:WaitForChild("MineTools"))
local T = require(shared:WaitForChild("MineTheme"))

local BG2 = T.BG2
local BG3 = T.BG3
local TEXT = T.TEXT
local MUTED = T.MUTED
local GOLD = T.GOLD
local GREEN = T.GREEN
local FONT = Enum.Font.GothamBold
local FONT_M = Enum.Font.Gotham

local function mk(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props or {}) do
		i[k] = v
	end
	i.Parent = parent
	return i
end
local function round(inst, r)
	mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, inst)
end
local function label(parent, str, size, color, pos, sz, font, align)
	return mk("TextLabel", {
		BackgroundTransparency = 1, Text = str, TextSize = size,
		TextColor3 = color or TEXT, Font = font or FONT_M,
		Position = pos or UDim2.fromOffset(0, 0),
		Size = sz or UDim2.new(1, 0, 0, size + 4),
		TextXAlignment = align or Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent)
end

-- Through the one currency formatter: floored, four significant figures,
-- suffixed the whole way. Its own version rounded ("%.1fK" on 1.99M reads
-- 2.0M), which a PRICE must never do, and ran out of suffixes past a trillion.
local function num(n)
	return require(shared:WaitForChild("MineAbbrev")).currency(n)
end

-- The tool's type rarity is what makes a frame dearer to level. Mirrors
-- oreToolTypeMult on the server; both read MineTools.RARITY_RANK.
local function typeMultOf(tool)
	local fam = Tools.TOOLS and Tools.TOOLS[tool.familyId or "pickaxe"]
	if fam then
		for _, td in ipairs(fam) do
			if td.id == tool.typeId then
				local r = Tools.normalizeToolRarity and Tools.normalizeToolRarity(td.rarity)
				return (Tools.RARITY_RANK and Tools.RARITY_RANK[r or td.rarity]) or 1, td
			end
		end
	end
	return 1, nil
end

local function toolTitle(tool, def)
	local ore = C.ORES and C.ORES[tonumber(tool.tier) or 1]
	local oreName = (ore and ore.name) or ("Tier " .. tostring(tool.tier))
	local typeName = (def and def.name) or tostring(tool.typeId or "Tool")
	return oreName .. " " .. typeName, ore
end

--[[
	mount(parent, opts)

	opts.getSnap()            -> the latest server snapshot
	opts.onUpgrade(uid, n)    -> fire upgradeOreTool
	opts.onRecycle(uid)       -> fire recycleOreTool

	Returns { refresh = function() }, so the caller can redraw when a new
	snapshot lands rather than this file polling for one.
]]
function MineBenchView.mount(parent, opts)
	opts = opts or {}

	-- No backdrop. The panel floats over whatever is behind it, same as the
	-- shop stage; a filled rectangle here just puts a box back on the screen.
	local root = mk("Frame", {
		BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, parent)

	label(root, "BENCH", 13, MUTED, UDim2.fromOffset(14, 10),
		UDim2.new(1, -28, 0, 16), FONT)
	local sub = label(root, "", 12, MUTED, UDim2.fromOffset(14, 28),
		UDim2.new(1, -28, 0, 14), FONT_M)

	local scroll = mk("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = UDim2.fromOffset(10, 50),
		Size = UDim2.new(1, -20, 1, -60),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
	}, root)
	mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

	local empty = label(scroll, "No ore tools yet. Find one in the mine.", 13, MUTED,
		nil, UDim2.new(1, 0, 0, 40), FONT_M, Enum.TextXAlignment.Center)
	empty.Visible = false

	local function button(parent, text, colour, x, w, enabled, onClick)
		local b = mk("TextButton", {
			BackgroundColor3 = enabled and colour or BG3,
			AutoButtonColor = enabled,
			Text = text, Font = FONT, TextSize = 13,
			TextColor3 = enabled and Color3.new(1, 1, 1) or MUTED,
			Position = UDim2.new(1, x, 0, 44), Size = UDim2.fromOffset(w, 26),
			BorderSizePixel = 0, Active = enabled,
		}, parent)
		round(b, 6)
		if enabled then
			b.MouseButton1Click:Connect(onClick)
		end
		return b
	end

	local function row(tool, snapshot, order)
		local typeMult, def = typeMultOf(tool)
		local level = math.max(1, tonumber(tool.level) or 1)
		local title, oreDef = toolTitle(tool, def)
		local oreId = oreDef and oreDef.id
		local haveOre = (snapshot.ores and oreId and tonumber(snapshot.ores[oreId])) or 0
		local haveDust = tonumber(snapshot.dust) or 0

		local maxed = level >= C.TOOL_MAX_LEVEL
		local costOre, costDust = C.toolUpgradeCost(tool.tier, level, typeMult)
		local canOne = (not maxed) and costOre and haveOre >= costOre and haveDust >= costDust

		local f = mk("Frame", {
			BackgroundColor3 = BG3, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 78), LayoutOrder = order,
		}, scroll)
		round(f, 8)

		label(f, title, 15, TEXT, UDim2.fromOffset(12, 8), UDim2.new(1, -180, 0, 18), FONT)
		label(f, string.format("level %d / %d", level, C.TOOL_MAX_LEVEL), 12,
			maxed and GOLD or MUTED, UDim2.fromOffset(12, 28), UDim2.new(1, -180, 0, 14))

		if maxed then
			label(f, "Fully levelled", 12, GOLD, UDim2.fromOffset(12, 48),
				UDim2.new(1, -180, 0, 14))
		else
			--[[
				Show what it costs AND what you hold, because "needs 4.2K Halite"
				is only useful next to "you have 900". A row that just says the
				price makes the player go and count.
			]]
			local okOre = haveOre >= (costOre or 0)
			local okDust = haveDust >= (costDust or 0)
			local line = string.format("%s %s  \u{00B7}  %s dust",
				num(costOre or 0), (oreDef and oreDef.name) or "ore", num(costDust or 0))
			label(f, line, 12, (okOre and okDust) and GREEN or MUTED,
				UDim2.fromOffset(12, 48), UDim2.new(1, -180, 0, 14))
			label(f, string.format("held  %s  \u{00B7}  %s", num(haveOre), num(haveDust)),
				11, MUTED, UDim2.fromOffset(12, 62), UDim2.new(1, -180, 0, 12))
		end

		-- scrap is always available; levelling only when it would succeed
		local recOre, recDust = C.toolRecycle(tool.tier, level, typeMult)
		local scrapText = (recOre > 0 or recDust > 0)
			and ("SCRAP  +" .. num(recOre) .. " / +" .. num(recDust))
			or "SCRAP"
		button(f, scrapText, Color3.fromRGB(150, 70, 70), -168, 160, true, function()
			if opts.onRecycle then opts.onRecycle(tool.uid) end
		end)
		button(f, "MAX", GREEN, -168, 48, canOne, function()
			if opts.onUpgrade then opts.onUpgrade(tool.uid, C.TOOL_MAX_LEVEL) end
		end)
		button(f, "+10", GREEN, -116, 48, canOne, function()
			if opts.onUpgrade then opts.onUpgrade(tool.uid, 10) end
		end)
		button(f, "+1", GREEN, -64, 48, canOne, function()
			if opts.onUpgrade then opts.onUpgrade(tool.uid, 1) end
		end)
	end

	local function refresh()
		for _, d in ipairs(scroll:GetChildren()) do
			if d:IsA("Frame") then
				d:Destroy()
			end
		end
		local snapshot = (opts.getSnap and opts.getSnap()) or {}
		local list = snapshot.oreTools or {}
		empty.Visible = #list == 0
		sub.Text = (#list == 0) and "nothing to work on"
			or (#list .. (#list == 1 and " tool" or " tools"))
		-- deepest investment first: the tool you care about is the one you fed
		local sorted = table.clone(list)
		table.sort(sorted, function(a, b)
			local la, lb = tonumber(a.level) or 1, tonumber(b.level) or 1
			if la ~= lb then
				return la > lb
			end
			return (tonumber(a.tier) or 0) > (tonumber(b.tier) or 0)
		end)
		for i, tool in ipairs(sorted) do
			if type(tool) == "table" and tool.uid then
				row(tool, snapshot, i)
			end
		end
	end

	refresh()
	return { refresh = refresh, root = root }
end

return MineBenchView
