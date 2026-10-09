--[[
	MineTraitView: the Enchanter's Trait tab.

	Owner, 2026-10-04: "replace runes with traits. Pretty much just walk
	to the enchanter and its a prefix too your tool (Sharp Stone Pickaxe, Lucky
	Stone Drill)".

	So this is the whole feature's front door, and it is deliberately small:
	pick one of your forged tools on the left, see what it is wearing, pay a
	flat price, roll. No fusing, no sockets, no inventory of loose traits
	to manage -- an trait only ever exists ON a tool.

	Two things it refuses to do:

	1. QUOTE ITS OWN ODDS OR PRICES. Every number on screen comes from
	   MineTraits -- the odds come out of `odds()`, which derives them from
	   the weight table, so the screen cannot drift from the roll the way a
	   hand-written "1 in 1000" in a label would.

	2. DECIDE ANYTHING. It sends a uid. The rarity, the trait and the
	   level are rolled server-side, and the panel only redraws what comes back
	   in the next snapshot.

	A roll REPLACES what is there, so the confirm line says what would be lost.
	That is the one piece of friction worth keeping: the gamble is the feature,
	but silently eating an Exotic V is not.
]]
local MineTraitView = {}

local RS = game:GetService("ReplicatedStorage")
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local Traits = require(shared:WaitForChild("MineTraits"))
local OreTools = require(shared:WaitForChild("MineOreTools"))
local Stats = require(shared:WaitForChild("MineStats"))
local Temper = require(shared:WaitForChild("MineTemper"))
local T = require(shared:WaitForChild("MineTheme"))

local BG2 = T.BG2
local BG3 = T.BG3
local TEXT = T.TEXT
local MUTED = T.MUTED
local GOLD = T.GOLD
local GREEN = T.GREEN
local FONT = T.FONT
local FONT_M = T.FONT_M
local RAIL_W = 236

local function mk(class, props, parent)
	local i = Instance.new(class)
	if i:IsA("GuiObject") then
		i.BorderSizePixel = 0
	end
	for k, v in pairs(props or {}) do
		i[k] = v
	end
	i.Parent = parent
	return i
end

local function round(inst, r)
	mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, inst)
	return inst
end

local function label(parent, str, size, colour, pos, sz, font, z)
	return mk("TextLabel", {
		BackgroundTransparency = 1, Text = str or "", TextSize = size or 13,
		TextColor3 = colour or TEXT, Font = font or FONT_M,
		Position = pos or UDim2.fromOffset(0, 0),
		Size = sz or UDim2.new(1, 0, 0, (size or 13) + 4),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = z or 36,
	}, parent)
end

-- The rarity's own colour, off MineTemper's ladder, so an Exotic trait
-- reads the same cyan an Exotic skin does.
local function rarityColour(rarity)
	return (Temper.RARITY_COLOR and Temper.RARITY_COLOR[rarity]) or MUTED
end

-- "1 in 5,000". Grouped, because 1 in 5000 and 1 in 500 are one glance apart.
local function oneIn(n)
	if not n then
		return "?"
	end
	local s = string.format("%d", math.floor(n + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return "1 in " .. out
end

--[[
	mount(parent, opts)

	opts.getSnap()        -> the latest server snapshot
	opts.onRollTrait(uid) -> fire rollTrait

	Returns { setVisible, paint, root } to match how the Enchanter's other
	tabs are driven.
]]
function MineTraitView.mount(parent, opts)
	opts = opts or {}
	local selUid = nil

	local root = mk("Frame", {
		Name = "Enchant", Visible = false, BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 96), Size = UDim2.new(1, -24, 1, -108),
		ZIndex = 34,
	}, parent)

	local rail = mk("ScrollingFrame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(0, RAIL_W, 1, 0), CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ZIndex = 35,
	}, root)
	mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, rail)

	local detail = mk("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(RAIL_W + 18, 0),
		Size = UDim2.new(1, -RAIL_W - 18, 1, 0), ZIndex = 35,
	}, root)

	local paint

	local function drawDetail(snapshot, tool)
		for _, d in ipairs(detail:GetChildren()) do
			d:Destroy()
		end
		if not tool then
			label(detail, "Forge a tool first, then bring it here.", 14, MUTED,
				UDim2.fromOffset(0, 4), UDim2.new(1, 0, 0, 20))
			return
		end

		label(detail, OreTools.toolName(tool), 22, TEXT, UDim2.fromOffset(0, 0),
			UDim2.new(1, 0, 0, 26), FONT)

		local cur = type(tool.trait) == "table" and tool.trait or nil
		local def = cur and Traits.byId(cur.id) or nil
		if def then
			label(detail, Traits.label(cur), 15, rarityColour(def.rarity),
				UDim2.fromOffset(0, 30), UDim2.new(1, 0, 0, 18), FONT)
			local st = (Stats.STATS or {})[def.stat]
			label(detail, string.format("+%.1f%%  %s", Traits.amount(cur.id, cur.level) * 100,
				(st and st.label) or def.stat), 13, GOLD,
				UDim2.fromOffset(0, 50), UDim2.new(1, 0, 0, 16))
			label(detail, oneIn(Traits.odds(cur.id, cur.level)) .. " to roll this exact result",
				12, MUTED, UDim2.fromOffset(0, 68), UDim2.new(1, 0, 0, 16))
		else
			label(detail, "No trait", 15, MUTED, UDim2.fromOffset(0, 30),
				UDim2.new(1, 0, 0, 18), FONT)
		end

		--[[
			THE ODDS, from MineTraits.odds rather than a written-down table.

			Worth the room: this is a 1-in-1000 chase, and a gacha that does not
			show its rates is the kind players stop trusting.
		]]
		local y = 98
		label(detail, "WHAT A ROLL CAN GIVE", 11, MUTED, UDim2.fromOffset(0, y),
			UDim2.new(1, 0, 0, 14), FONT)
		y += 18
		for _, grade in ipairs(Traits.RARITY_ORDER) do
			local pool = Traits.BY_RARITY[grade] or {}
			if #pool > 0 then
				local chance = Traits.RARITY_TOTAL / (Traits.RARITY_WEIGHTS[grade] or 1)
				local names = {}
				for _, e in ipairs(pool) do
					names[#names + 1] = e.prefix
				end
				local rowF = mk("Frame", {
					BackgroundColor3 = BG3, BackgroundTransparency = 0.45,
					Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, -8, 0, 22),
					ZIndex = 35,
				}, detail)
				round(rowF, 5)
				label(rowF, Traits.RARITY_NAME[grade] or grade, 12, rarityColour(grade),
					UDim2.fromOffset(8, 0), UDim2.fromOffset(78, 22), FONT)
				label(rowF, oneIn(chance), 11, MUTED, UDim2.fromOffset(90, 0),
					UDim2.fromOffset(72, 22))
				label(rowF, table.concat(names, " \u{00B7} "), 11, TEXT,
					UDim2.fromOffset(166, 0), UDim2.new(1, -174, 0, 22))
				y += 25
			end
		end

		label(detail, "Level I-V is an even roll, so the best of any tier is five times rarer.",
			11, MUTED, UDim2.fromOffset(0, y + 2), UDim2.new(1, -8, 0, 16))
		y += 24

		local price = Traits.ROLL_PRICE
		local gems = math.floor(tonumber(snapshot.gems) or 0)
		local afford = gems >= price
		local btn = mk("TextButton", {
			BackgroundColor3 = afford and GREEN or BG3, AutoButtonColor = afford,
			Font = FONT, TextSize = 15, TextColor3 = afford and Color3.new(1, 1, 1) or MUTED,
			Text = string.format("ROLL TRAIT   %d gems", price),
			Position = UDim2.fromOffset(0, y + 6), Size = UDim2.fromOffset(210, 36),
			Active = afford, ZIndex = 36,
		}, detail)
		round(btn, 8)
		if afford then
			btn.MouseButton1Click:Connect(function()
				-- It checked onTrait and then called onRollTrait, which nothing
				-- passes, so the roll never fired. MineClient passes onTrait.
				local fn = opts.onTrait or opts.onRollTrait
				if fn then
					local idle = btn.Text
					btn.Active = false
					btn.Text = "ROLLING..."
					fn(tool.uid)
					-- A refused roll sends only a toast and no repaint; never leave
					-- the button stuck.
					task.delay(3, function()
						if btn.Parent and btn.Text == "ROLLING..." then
							btn.Active = true
							btn.Text = idle
						end
					end)
				end
			end)
		end
		-- The one piece of friction worth keeping.
		label(detail, cur
				and ("Replaces " .. Traits.label(cur) .. ". There is no undo.")
				or ("You hold " .. tostring(gems) .. " gems."),
			11, cur and GOLD or MUTED,
			UDim2.fromOffset(220, y + 16), UDim2.new(1, -228, 0, 18))
	end

	paint = function()
		for _, d in ipairs(rail:GetChildren()) do
			if not d:IsA("UIListLayout") then
				d:Destroy()
			end
		end
		local snapshot = (opts.getSnap and opts.getSnap()) or {}
		local tools = {}
		for _, t in ipairs(snapshot.oreTools or {}) do
			if type(t) == "table" and t.uid then
				tools[#tools + 1] = t
			end
		end
		table.sort(tools, function(a, b)
			local at, bt = tonumber(a.tier) or 0, tonumber(b.tier) or 0
			if at ~= bt then
				return at > bt
			end
			return tostring(a.uid) < tostring(b.uid)
		end)

		if #tools == 0 then
			label(rail, "No forged tools yet.", 12, MUTED, nil,
				UDim2.new(1, -6, 0, 30)).LayoutOrder = 1
		end
		-- Keep the player on the same tool across a redraw; fall back to the
		-- deepest when the selection is gone (scrapped, usually).
		local still = false
		for _, t in ipairs(tools) do
			if t.uid == selUid then
				still = true
				break
			end
		end
		if not still then
			selUid = tools[1] and tools[1].uid or nil
		end

		local chosen
		for i, t in ipairs(tools) do
			if t.uid == selUid then
				chosen = t
			end
			local cur = type(t.trait) == "table" and t.trait or nil
			local def = cur and Traits.byId(cur.id) or nil
			local b = mk("TextButton", {
				BackgroundColor3 = (t.uid == selUid) and BG2 or BG3, AutoButtonColor = true,
				Text = "", Size = UDim2.new(1, -6, 0, 40), LayoutOrder = i, ZIndex = 36,
			}, rail)
			round(b, 6)
			label(b, OreTools.toolName(t), 13, TEXT, UDim2.fromOffset(10, 5),
				UDim2.new(1, -20, 0, 15), FONT, 37)
			label(b, def and Traits.label(cur) or "no trait", 11,
				def and rarityColour(def.rarity) or MUTED,
				UDim2.fromOffset(10, 22), UDim2.new(1, -20, 0, 13), nil, 37)
			b.MouseButton1Click:Connect(function()
				selUid = t.uid
				paint()
			end)
		end

		drawDetail(snapshot, chosen)
	end

	return {
		root = root,
		paint = paint,
		setVisible = function(on)
			root.Visible = on and true or false
			if on then
				paint()
			end
		end,
	}
end

return MineTraitView
