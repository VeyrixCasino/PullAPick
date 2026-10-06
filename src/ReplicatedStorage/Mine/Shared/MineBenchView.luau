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

--[[
	The level cap, with a floor under it.

	Every row compares its level against C.TOOL_MAX_LEVEL. When that arrived nil
	-- which a stale module cache is enough to cause -- the comparison threw on
	the first row and the panel drew nothing at all, which reads exactly like
	"you own no tools". A wrong cap costs one wrong number; a nil one cost the
	whole bench.
]]
local function levelCap(C)
	return tonumber(C.TOOL_MAX_LEVEL) or 1000
end

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

--[[
	A finish goes in FRONT of the name, the way the game says it everywhere
	else: "Shadow Obsidian Pickaxe". It is the first thing you want to see in a
	list of twenty tools, and putting it after the name buries it past the
	truncation on a narrow panel.
]]
-- Multipliers come from MineConfig, never a copy: a hardcoded 3 here would go
-- on saying 3 the day the constant moves, and the panel would quietly lie.
local FINISHES = {
	Nightmare = { tint = Color3.fromRGB(150, 60, 220), key = "NIGHTMARE_MULT", fallback = 4.5 },
	Shadow = { tint = Color3.fromRGB(196, 30, 58), key = "SHADOW_MULT", fallback = 3 },
	Shiny = { tint = Color3.fromRGB(236, 240, 255), key = "SHINY_MULT", fallback = 1.5 },
}
local function finishMult(def)
	return tonumber(C[def.key]) or def.fallback
end

local function finishOf(tool)
	if tool.nightmare then
		return "Nightmare"
	elseif tool.shadow then
		return "Shadow"
	elseif tool.shiny then
		return "Shiny"
	end
	return nil
end

local function toolTitle(tool, def)
	local ore = C.ORES and C.ORES[tonumber(tool.tier) or 1]
	local oreName = (ore and ore.name) or ("Tier " .. tostring(tool.tier))
	local typeName = (def and def.name) or tostring(tool.typeId or "Tool")
	local fin = finishOf(tool)
	local name = oreName .. " " .. typeName
	return (fin and (fin .. " " .. name)) or name, ore, fin
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

	local function button(parent, text, colour, x, w, enabled, onClick, yRow)
		local b = mk("TextButton", {
			BackgroundColor3 = enabled and colour or BG3,
			AutoButtonColor = enabled,
			Text = text, Font = FONT, TextSize = 13,
			TextColor3 = enabled and Color3.new(1, 1, 1) or MUTED,
			Position = UDim2.new(1, x, 0, yRow or 44), Size = UDim2.fromOffset(w, 26),
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
		local title, oreDef, fin = toolTitle(tool, def)
		local oreId = oreDef and oreDef.id
		local haveOre = (snapshot.ores and oreId and tonumber(snapshot.ores[oreId])) or 0
		local haveDust = tonumber(snapshot.dust) or 0

		local cap = levelCap(C)
		local maxed = level >= cap
		-- Pricing lives in MineConfig and is never recomputed here, but a build
		-- without it must still list what you own rather than blank the panel.
		local costOre, costDust
		if C.toolUpgradeCost then
			costOre, costDust = C.toolUpgradeCost(tool.tier, level, typeMult)
		end
		local canOne = (not maxed) and costOre and haveOre >= costOre and haveDust >= costDust

		local f = mk("Frame", {
			BackgroundColor3 = BG3, BorderSizePixel = 0,
			--[[
				78 -> 104.

				SCRAP was 160px wide from x = -168, which is exactly where MAX,
				+10 and +1 sit. As later siblings they drew on top of it, so the
				only way to scrap a tool was covered by the buttons that level
				it. Levelling keeps line one; EQUIP and SCRAP get line two.
			]]
			Size = UDim2.new(1, 0, 0, 104), LayoutOrder = order,
		}, scroll)
		round(f, 8)

		local finDef = fin and FINISHES[fin]
		label(f, title, 15, (finDef and finDef.tint) or TEXT,
			UDim2.fromOffset(12, 8), UDim2.new(1, -250, 0, 18), FONT)
		local lvlLine = string.format("level %d / %d", level, cap)
		if finDef then
			-- What the finish is actually worth, next to the level, because
			-- "Shadow" on its own does not say whether that is 1.5x or 3x.
			lvlLine = lvlLine .. string.format("   \u{00B7}   %s  %gx damage", fin, finishMult(finDef))
		end
		label(f, lvlLine, 12,
			maxed and GOLD or MUTED, UDim2.fromOffset(12, 28), UDim2.new(1, -250, 0, 14))

		if maxed then
			label(f, "Fully levelled", 12, GOLD, UDim2.fromOffset(12, 48),
				UDim2.new(1, -250, 0, 14))
		else
			--[[
				Show what it costs AND what you hold, because "needs 4.2K Halite"
				is only useful next to "you have 900". A row that just says the
				price makes the player go and count.
			]]
			local okOre = haveOre >= (costOre or 0)
			local okDust = haveDust >= (costDust or 0)
			--[[
				WHAT THE LEVEL BUYS, IN FRONT OF WHAT IT COSTS.

				Owner, 2026-10-05: "something i could advertise when people
				crafting a new tool by each level UP%X". A price with no gain
				beside it is a bill; the gain is the reason to pay it, so it
				leads the line.

				Derived from C.TOOL_DMG_STEP, never written out. That constant is
				perLevel(TOOL_CLIMB_DAMAGE) and so moves with TOOL_MAX_LEVEL --
				at the current cap of 30 it reads +22%, and if the cap moves this
				line follows it instead of advertising a number the game stopped
				applying. Pricing is already never computed in this file; the
				same rule holds for the damage it quotes.
			]]
			local gain = ""
			local step = tonumber(C.TOOL_DMG_STEP)
			if step and step > 1 then
				gain = string.format("+%d%% damage  \u{00B7}  ",
					math.floor((step - 1) * 100 + 0.5))
			end
			local line = gain .. string.format("%s %s  \u{00B7}  %s dust",
				num(costOre or 0), (oreDef and oreDef.name) or "ore", num(costDust or 0))
			label(f, line, 12, (okOre and okDust) and GREEN or MUTED,
				UDim2.fromOffset(12, 48), UDim2.new(1, -250, 0, 14))
			label(f, string.format("held  %s  \u{00B7}  %s", num(haveOre), num(haveDust)),
				11, MUTED, UDim2.fromOffset(12, 62), UDim2.new(1, -250, 0, 12))
		end

		-- scrap is always available; levelling only when it would succeed
		local recOre, recDust = 0, 0
		if C.toolRecycle then
			recOre, recDust = C.toolRecycle(tool.tier, level, typeMult)
		end
		local scrapText = (recOre > 0 or recDust > 0)
			and ("SCRAP  +" .. num(recOre) .. " / +" .. num(recDust))
			or "SCRAP"
		--[[
			EQUIP is the point of the bench.

			It toggles: pressing the tool you are holding puts it away and hands
			back the ladder pickaxe, so a player is never stuck holding
			something they would rather not.
		]]
		local held = snapshot.oreToolEquipped == tool.uid
		button(f, held and "EQUIPPED" or "EQUIP",
			held and GOLD or Color3.fromRGB(64, 104, 168), -240, 68, true, function()
				if opts.onEquip then opts.onEquip(tool.uid) end
			end, 74)
		-- SCRAP keeps the refund figures, so it keeps its full width; EQUIP
		-- sits to its left and the text column gives up the room.
		button(f, scrapText, Color3.fromRGB(150, 70, 70), -166, 158, true, function()
			if opts.onRecycle then opts.onRecycle(tool.uid) end
		end, 74)
		button(f, "MAX", GREEN, -168, 48, canOne, function()
			if opts.onUpgrade then opts.onUpgrade(tool.uid, cap) end
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
		local heldUid = snapshot.oreToolEquipped
		table.sort(sorted, function(a, b)
			-- What you are holding goes first: it is what you came to work on.
			if (a.uid == heldUid) ~= (b.uid == heldUid) then
				return a.uid == heldUid
			end
			-- Shadow above Shiny above plain, then level, then tier: a finish
			-- is worth more than a few levels and should not be buried.
			local function rank(t)
				return (t.nightmare and 3) or (t.shadow and 2) or (t.shiny and 1) or 0
			end
			local ra, rb = rank(a), rank(b)
			if ra ~= rb then
				return ra > rb
			end
			local la, lb = tonumber(a.level) or 1, tonumber(b.level) or 1
			if la ~= lb then
				return la > lb
			end
			return (tonumber(a.tier) or 0) > (tonumber(b.tier) or 0)
		end)
		--[[
			One row per tool, each in its own pcall.

			row() reads pricing out of MineConfig and rarity out of MineTools,
			and a single bad tool -- an unknown typeId, a tier past the end of
			the ore roster -- used to take every other row down with it. A tool
			that cannot be priced is worth reporting, not worth hiding the nine
			tools above it.
		]]
		local broke = 0
		for i, tool in ipairs(sorted) do
			if type(tool) == "table" and tool.uid then
				local ok, err = pcall(row, tool, snapshot, i)
				if not ok then
					broke += 1
					warn("[MineBenchView] row " .. i .. " (" .. tostring(tool.uid) .. "): " .. tostring(err))
				end
			end
		end
		if broke > 0 then
			sub.Text = sub.Text .. "  \u{00B7}  " .. broke .. " could not be priced"
		end
	end

	refresh()
	return { refresh = refresh, root = root }
end

return MineBenchView
