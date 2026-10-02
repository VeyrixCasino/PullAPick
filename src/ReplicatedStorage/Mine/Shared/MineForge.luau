--[[
	MineForge: the Forge panel. Build a tool out of ore, then level it.

	Layout is a vertical rail of EVERY tool down the left-hand side and a detail
	pane on the right. The rail is the whole catalogue, not just what you own,
	because the point of a forge is seeing what you could make next -- a list of
	only-owned tools tells a player nothing about where they are going.

	Two modes in the detail pane, never both:

	  owned  -> UPGRADE. Level, next step's price, +1 / +10 / MAX, and SCRAP.
	  unowned -> CRAFT. Pick an ore you have discovered, see the amount, forge.

	Three rules this file does not get to bend:

	1. Pricing is never computed here. MineConfig owns toolCraftCost,
	   toolUpgradeCost, woodPickCoinCost and toolRecycle, so the panel and the
	   server cannot quote different numbers. A panel that does its own maths
	   eventually disagrees with the server, and the player believes the panel.

	2. Every button sends a UID, never a row index. The rail reorders whenever a
	   tool is crafted or scrapped, and an index captured at draw time names a
	   different tool by the time it is clicked. Packs already fell in this hole.

	3. Undiscovered ores are not drawn. An ore the player has never seen must not
	   leak its name, tier or colour through a recipe row.

	The wooden pickaxe is the one tool that levels on coins (MineConfig.isCoinTool).
	It is the free starter, and charging ore for the tool whose job is to get you
	your first ore would be a deadlock.
]]
local MineForge = {}

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
local RED = T.RED or Color3.fromRGB(190, 92, 92)
local FONT = Enum.Font.GothamBold
local FONT_M = Enum.Font.Gotham

local RAIL_W = 232

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

local function label(parent, str, size, color, pos, sz, font, align)
	return mk("TextLabel", {
		BackgroundTransparency = 1,
		Text = str or "",
		TextSize = size or 13,
		TextColor3 = color or TEXT,
		Font = font or FONT_M,
		Position = pos or UDim2.fromOffset(0, 0),
		Size = sz or UDim2.new(1, 0, 0, (size or 13) + 4),
		TextXAlignment = align or Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent)
end

-- Same abbreviation the bench uses, so a cost reads identically in both panels.
local function num(n)
	n = tonumber(n) or 0
	if n < 1000 then
		return tostring(math.floor(n))
	elseif n < 1e6 then
		return string.format("%.1fK", n / 1e3)
	elseif n < 1e9 then
		return string.format("%.1fM", n / 1e6)
	elseif n < 1e12 then
		return string.format("%.1fB", n / 1e9)
	end
	return string.format("%.2e", n)
end

-- Mirrors oreToolTypeMult on the server; both read MineTools.RARITY_RANK, so a
-- rarer frame costs the same extra in the panel as it does in the verb.
local function typeMultOf(familyId, typeId)
	local fam = Tools.TOOLS and Tools.TOOLS[familyId or "pickaxe"]
	if fam then
		for _, td in ipairs(fam) do
			if td.id == typeId then
				local r = Tools.normalizeToolRarity and Tools.normalizeToolRarity(td.rarity)
				return (Tools.RARITY_RANK and Tools.RARITY_RANK[r or td.rarity]) or 1, td
			end
		end
	end
	return 1, nil
end

--[[
	Which ores the player may forge with.

	"Discovered" is whatever the snapshot can prove. A server that sends an
	explicit seen-set wins; otherwise an ore counts as discovered once the
	player is holding some, which is strictly safe -- it can under-report, never
	over-report, and under-reporting only hides a recipe the player could not
	afford to run anyway.
]]
local function discoveredOres(snapshot)
	local out = {}
	local seen = snapshot.oresSeen
	local held = snapshot.ores or {}
	if type(seen) == "table" then
		for id, flag in pairs(seen) do
			if flag then
				out[#out + 1] = { id = id, have = tonumber(held[id]) or 0 }
			end
		end
	else
		for id, n in pairs(held) do
			if (tonumber(n) or 0) > 0 then
				out[#out + 1] = { id = id, have = tonumber(n) or 0 }
			end
		end
	end
	for _, row in ipairs(out) do
		local def = C.oreById and C.oreById(row.id)
		row.def = def
		row.tier = (def and tonumber(def.tier)) or 0
		row.name = (def and def.name) or row.id
	end
	table.sort(out, function(a, b)
		return a.tier > b.tier
	end)
	return out
end

-- The owned ore tool for a catalogue entry, if the player has one. Deepest
-- investment wins when several exist, which is the one the player means.
local function ownedFor(snapshot, familyId, typeId)
	local best
	for _, t in ipairs(snapshot.oreTools or {}) do
		if type(t) == "table" and t.uid and t.typeId == typeId
			and (t.familyId or "pickaxe") == familyId then
			if not best or (tonumber(t.level) or 1) > (tonumber(best.level) or 1) then
				best = t
			end
		end
	end
	return best
end

--[[
	mount(parent, opts)

	opts.getSnap()                       -> the latest server snapshot
	opts.onCraft(familyId, typeId, oreId)-> fire craftOreTool
	opts.onUpgrade(uid, count)           -> fire upgradeOreTool
	opts.onRecycle(uid)                  -> fire recycleOreTool

	Returns { refresh = function(), root = Frame } so the caller redraws when a
	snapshot lands instead of this file polling for one.
]]
function MineForge.mount(parent, opts)
	opts = opts or {}

	-- No backdrop. The panel floats over the 3D stage behind it, same as the
	-- shop; a filled rectangle here just puts a box back on the screen.
	local root = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, parent)

	label(root, "FORGE", 13, MUTED, UDim2.fromOffset(14, 10),
		UDim2.new(0, RAIL_W, 0, 16), FONT)
	local wallet = label(root, "", 12, MUTED, UDim2.new(0, RAIL_W + 24, 0, 10),
		UDim2.new(1, -RAIL_W - 38, 0, 16), FONT_M, Enum.TextXAlignment.Right)

	-- Left rail: every tool in the game, grouped by family.
	local rail = mk("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 34),
		Size = UDim2.new(0, RAIL_W, 1, -44),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
	}, root)
	mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, rail)

	local detail = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(RAIL_W + 24, 34),
		Size = UDim2.new(1, -RAIL_W - 38, 1, -44),
	}, root)

	-- Selection is held by identity, not by row index, so a redraw that
	-- reorders or regrows the rail keeps the player on the same tool.
	local selFamily, selType = "pickaxe", nil
	local selOre = nil
	-- CRAFT or UPGRADE, picked by the player rather than inferred from
	-- ownership. Inferring it meant the craft recipes simply did not exist for
	-- any tool you already owned, with nothing on screen to say so -- the panel
	-- looked like it had no crafting at all.
	local selMode = nil
	local refresh

	local function button(host, text, colour, pos, size, enabled, onClick)
		local b = mk("TextButton", {
			BackgroundColor3 = enabled and colour or BG3,
			AutoButtonColor = enabled,
			Text = text,
			Font = FONT,
			TextSize = 13,
			TextColor3 = enabled and Color3.new(1, 1, 1) or MUTED,
			Position = pos,
			Size = size,
			Active = enabled,
		}, host)
		round(b, 6)
		if enabled then
			b.MouseButton1Click:Connect(onClick)
		end
		return b
	end

	----------------------------------------------------------------- detail --

	local function drawUpgrade(host, snapshot, def, tool)
		local level = math.max(1, tonumber(tool.level) or 1)
		local coinTool = C.isCoinTool and C.isCoinTool(tool)
		local cap = coinTool and C.WOOD_PICK_MAX_LEVEL or C.TOOL_MAX_LEVEL
		local maxed = level >= cap

		label(host, def.name, 19, TEXT, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 22), FONT)
		label(host, string.format("level %d / %d", level, cap), 13,
			maxed and GOLD or MUTED, UDim2.fromOffset(0, 26), UDim2.new(1, 0, 0, 16))

		local canStep, costLine, heldLine
		if maxed then
			costLine = "Fully levelled"
		elseif coinTool then
			-- The starter. Coins only, never ore, never stardust.
			local coins = C.woodPickCoinCost(level)
			local have = tonumber(snapshot.coins) or 0
			canStep = coins ~= nil and have >= coins
			costLine = num(coins or 0) .. " coins"
			heldLine = "held  " .. num(have) .. " coins"
		else
			local typeMult = typeMultOf(selFamily, def.id)
			local ore, dust = C.toolUpgradeCost(tool.tier, level, typeMult)
			-- C.ORES[tool.tier] is what the server's _oreToolCost uses. Resolve
			-- it the same way or the panel quotes a different ore than the verb
			-- charges.
			local oreDef = C.ORES and C.ORES[tonumber(tool.tier) or 1]
			local oreId = oreDef and oreDef.id
			local haveOre = (oreId and tonumber((snapshot.ores or {})[oreId])) or 0
			local haveDust = tonumber(snapshot.dust) or 0
			canStep = ore ~= nil and haveOre >= ore and haveDust >= dust
			costLine = string.format("%s %s  \u{00B7}  %s dust",
				num(ore or 0), (oreDef and oreDef.name) or "ore", num(dust or 0))
			heldLine = string.format("held  %s  \u{00B7}  %s", num(haveOre), num(haveDust))
		end

		label(host, costLine, 14, (maxed and GOLD) or (canStep and GREEN) or MUTED,
			UDim2.fromOffset(0, 54), UDim2.new(1, 0, 0, 18))
		if heldLine then
			label(host, heldLine, 12, MUTED, UDim2.fromOffset(0, 74), UDim2.new(1, 0, 0, 14))
		end

		local y = 102
		button(host, "+1", GREEN, UDim2.fromOffset(0, y), UDim2.fromOffset(56, 28),
			canStep == true, function()
				if opts.onUpgrade then opts.onUpgrade(tool.uid, 1) end
			end)
		button(host, "+10", GREEN, UDim2.fromOffset(62, y), UDim2.fromOffset(56, 28),
			canStep == true, function()
				if opts.onUpgrade then opts.onUpgrade(tool.uid, 10) end
			end)
		button(host, "MAX", GREEN, UDim2.fromOffset(124, y), UDim2.fromOffset(56, 28),
			canStep == true, function()
				if opts.onUpgrade then opts.onUpgrade(tool.uid, cap) end
			end)

		-- Scrapping is always offered; it is the one action that works when the
		-- player cannot afford anything else.
		local typeMult = typeMultOf(selFamily, def.id)
		local recOre, recDust = C.toolRecycle(tool.tier, level, typeMult)
		button(host, "SCRAP  +" .. num(recOre) .. " ore / +" .. num(recDust) .. " dust",
			RED, UDim2.fromOffset(0, y + 38), UDim2.fromOffset(240, 26), true, function()
				if opts.onRecycle then opts.onRecycle(tool.uid) end
			end)
	end

	local function drawCraft(host, snapshot, def)
		label(host, def.name, 19, TEXT, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 22), FONT)
		-- Neutral wording on purpose: this pane is also reached from the CRAFT
		-- tab on a tool you already own, to forge another from a deeper ore.
		label(host, "Pick an ore to forge it from.", 13, MUTED,
			UDim2.fromOffset(0, 26), UDim2.new(1, 0, 0, 16))

		local ores = discoveredOres(snapshot)
		if #ores == 0 then
			label(host, "No ore discovered yet. Mine some first.", 13, MUTED,
				UDim2.fromOffset(0, 56), UDim2.new(1, 0, 0, 18))
			return
		end

		local typeMult = typeMultOf(selFamily, def.id)
		local list = mk("ScrollingFrame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 54),
			Size = UDim2.new(1, 0, 1, -54),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 4,
		}, host)
		mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)

		for i, ore in ipairs(ores) do
			local cost = C.toolCraftCost(ore.tier, typeMult)
			local afford = ore.have >= cost
			local picked = (selOre == ore.id)

			local rowF = mk("Frame", {
				BackgroundColor3 = picked and BG2 or BG3,
				Size = UDim2.new(1, -6, 0, 50),
				LayoutOrder = i,
			}, list)
			round(rowF, 8)

			label(rowF, string.format("%s  \u{00B7}  tier %d", ore.name, ore.tier), 14, TEXT,
				UDim2.fromOffset(10, 8), UDim2.new(1, -140, 0, 16), FONT)
			label(rowF, string.format("%s %s   (held %s)", num(cost), ore.name, num(ore.have)),
				12, afford and GREEN or MUTED,
				UDim2.fromOffset(10, 28), UDim2.new(1, -140, 0, 14))

			button(rowF, afford and "FORGE" or "NEED ORE", GREEN,
				UDim2.new(1, -124, 0, 12), UDim2.fromOffset(112, 26), afford, function()
					selOre = ore.id
					if opts.onCraft then opts.onCraft(selFamily, def.id, ore.id) end
				end)
		end
	end

	local function drawDetail(snapshot)
		for _, d in ipairs(detail:GetChildren()) do
			if not d:IsA("UIListLayout") then
				d:Destroy()
			end
		end
		local _, def = typeMultOf(selFamily, selType)
		if not def then
			label(detail, "Pick a tool on the left.", 13, MUTED,
				UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 18))
			return
		end
		local tool = ownedFor(snapshot, selFamily, def.id)

		-- Default to UPGRADE once you own one, CRAFT otherwise, but always let
		-- the player switch: owning one Halite Trueheart is no reason to hide
		-- the recipe for forging another out of a deeper ore.
		local mode = selMode or (tool and "upgrade" or "craft")
		if mode == "upgrade" and not tool then
			mode = "craft"
		end

		local tabs = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 30),
		}, detail)
		local function tab(text, id, x, enabled)
			local on = (mode == id)
			local b = mk("TextButton", {
				BackgroundColor3 = on and GOLD or BG3,
				AutoButtonColor = enabled,
				Text = text,
				Font = FONT,
				TextSize = 12,
				TextColor3 = on and Color3.fromRGB(26, 24, 20)
					or (enabled and TEXT or MUTED),
				Position = UDim2.fromOffset(x, 0),
				Size = UDim2.fromOffset(96, 26),
				Active = enabled,
			}, tabs)
			round(b, 6)
			if enabled then
				b.MouseButton1Click:Connect(function()
					selMode = id
					refresh()
				end)
			end
			return b
		end
		tab("CRAFT", "craft", 0, true)
		tab("UPGRADE", "upgrade", 102, tool ~= nil)

		-- Everything below the tab strip draws into its own host, so the two
		-- panes do not have to know the strip is above them.
		local host = mk("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 36),
			Size = UDim2.new(1, 0, 1, -36),
		}, detail)
		if mode == "upgrade" and tool then
			drawUpgrade(host, snapshot, def, tool)
		else
			drawCraft(host, snapshot, def)
		end
	end

	------------------------------------------------------------------- rail --

	refresh = function()
		for _, d in ipairs(rail:GetChildren()) do
			if not d:IsA("UIListLayout") then
				d:Destroy()
			end
		end
		local snapshot = (opts.getSnap and opts.getSnap()) or {}
		wallet.Text = string.format("%s coins  \u{00B7}  %s gems  \u{00B7}  %s dust",
			num(snapshot.coins), num(snapshot.gems), num(snapshot.dust))

		local order = 0
		for _, fam in ipairs(Tools.FAMILIES or {}) do
			local defs = (Tools.TOOLS or {})[fam.id]
			-- A family with no roster yet (weapons are flagged planned) would
			-- otherwise draw a header over nothing.
			if defs and #defs > 0 then
				order += 1
				label(rail, string.upper(fam.name or fam.id), 11, MUTED, nil,
					UDim2.new(1, -6, 0, 18), FONT).LayoutOrder = order

				for _, def in ipairs(defs) do
					order += 1
					local tool = ownedFor(snapshot, fam.id, def.id)
					local picked = (selFamily == fam.id and selType == def.id)
					if selType == nil then
						selFamily, selType, picked = fam.id, def.id, true
					end

					local b = mk("TextButton", {
						BackgroundColor3 = picked and BG2 or BG3,
						AutoButtonColor = true,
						Text = "",
						Size = UDim2.new(1, -6, 0, 38),
						LayoutOrder = order,
					}, rail)
					round(b, 6)

					label(b, def.name, 13, tool and TEXT or MUTED,
						UDim2.fromOffset(10, 5), UDim2.new(1, -20, 0, 15), FONT)
					label(b, tool
							and ("level " .. tostring(tool.level or 1))
							or "not forged",
						11, tool and GREEN or MUTED,
						UDim2.fromOffset(10, 21), UDim2.new(1, -20, 0, 12))

					b.MouseButton1Click:Connect(function()
						selFamily, selType, selOre = fam.id, def.id, nil
						selMode = nil
						refresh()
					end)
				end
			end
		end

		drawDetail(snapshot)
	end

	refresh()
	return { refresh = refresh, root = root }
end

return MineForge
