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
-- A forged tool IS its ore: the name, the frame and the price all come
-- from one place so the panel and the craft verb cannot disagree.
local OreTools = require(shared:WaitForChild("MineOreTools"))
local T = require(shared:WaitForChild("MineTheme"))
local UI = require(shared:WaitForChild("MineUI"))
local Icons = require(shared:WaitForChild("MineIcons"))

local BG2 = T.BG2
local BG3 = T.BG3
local TEXT = T.TEXT
local MUTED = T.MUTED
local GOLD = T.GOLD
local GREEN = T.GREEN
local RED = T.RED or Color3.fromRGB(190, 92, 92)
--[[
	The faces come from MineTheme now. They were Gotham, hardcoded here, which
	is the "every view invents its own" problem in one line -- the panel next to
	this one used a different pair and the game read as two games.
]]
local FONT = T.FONT
local FONT_M = T.FONT_M
local IMG = Icons.IMAGES or {}

local RAIL_W = 232
--[[
	The mode rail down the far left. The owner drew a box in this gutter and
	wrote "all tabs should be there (crafting, upgrade, shop, shit like that)";
	it was empty, and the three modes were scattered -- craft and upgrade buried
	at the top of the detail pane where they read as a property of the selected
	tool, and the coin shop a small grey button in the opposite corner.
]]
local TAB_W = 104
local RAIL_X = TAB_W + 20
-- Height of the ore strip along the bottom. The detail pane gives this up.
local POUCH_H = 64

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

--[[
	Every number this panel shows, through the one currency formatter.

	It formatted its own before: "%.1fK" and friends, which ROUND -- so a quoted
	price could read lower than what is charged, which a price must never do --
	showed two or three significant figures where the rule is four, and ran out
	of suffixes past a trillion. MineAbbrev.currency floors, shows four, and is
	what the server quotes with, so a cost reads identically on both sides.
]]
local function num(n)
	return require(shared:WaitForChild("MineAbbrev")).currency(n)
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

--[[
	The owned tool for an ore, if the player has one.

	Keyed on the ORE now, not on a frame id. One ore, one tool: that is the
	whole rule the owner asked for, and matching on typeId was what let the
	same name exist at forty different prices.

	Deepest investment wins when several exist, which is the one the player
	means.
]]
local function ownedForOre(snapshot, familyId, oreTier)
	local want = math.floor(tonumber(oreTier) or 0)
	local best
	for _, t in ipairs(snapshot.oreTools or {}) do
		if type(t) == "table" and t.uid
			and (t.familyId or "pickaxe") == familyId
			and math.floor(tonumber(t.tier) or -1) == want then
			if not best or (tonumber(t.level) or 1) > (tonumber(best.level) or 1) then
				best = t
			end
		end
	end
	return best
end

-- Every forged tool of a family, deepest ore first: the UPGRADE rail.
local function ownedOf(snapshot, familyId)
	local out = {}
	for _, t in ipairs(snapshot.oreTools or {}) do
		if type(t) == "table" and t.uid and (t.familyId or "pickaxe") == familyId then
			out[#out + 1] = t
		end
	end
	table.sort(out, function(a, b)
		local at, bt = tonumber(a.tier) or 0, tonumber(b.tier) or 0
		if at ~= bt then
			return at > bt
		end
		return tostring(a.uid) < tostring(b.uid)
	end)
	return out
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

	--[[
		STATE, AND IT IS DECLARED UP HERE ON PURPOSE.

		The mode buttons below close over `refresh`, and a Luau local referenced
		above its declaration compiles as a GLOBAL read -- nil at call time, so
		every tab would do nothing and say nothing. That trap has already cost
		this project two bugs. Declare first, assign later.

		Selection is held by identity -- an ore id, a tool uid -- never by row
		index, because the rail reorders the moment anything is forged.
	]]
	local selFamily = "pickaxe"
	local selMode = "craft"
	local selOreId = nil
	local selUid = nil
	local refresh

	--[[
		THE TITLE.

		This was "FORGE" at 13px in MUTED -- the same size as a caption, in the
		colour reserved for text you are not meant to read. The reference puts a
		34px gold word and its mark at the top of the panel, and a title that
		small is most of why the live screen read as a debug menu beside it.
	]]
	UI.icon(root, IMG.logo, 38, UDim2.fromOffset(RAIL_X + 2, 10))
	label(root, "FORGE", 30, GOLD, UDim2.fromOffset(RAIL_X + 46, 8),
		UDim2.fromOffset(240, 40), FONT)

	--[[
		THE MODE RAIL, down the far left.

		CRAFT, UPGRADE and the coin SHOP are the three things a player comes
		here to do, and all three used to be somewhere else. The family picker
		rides underneath it: an ore makes a pickaxe, a drill or an explosive,
		so the family is a mode of this panel too, not a header in the list.

		SHOP is a ROUTE, not a pane. It hands off to the host and the Forge
		never learns the coin shop exists, because requiring MineShopView from
		inside a panel MineShopView mounts would be a cycle.
	]]
	local modeCol = mk("Frame", {
		Name = "ModeRail",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 34),
		Size = UDim2.new(0, TAB_W, 1, -44),
	}, root)
	mk("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, modeCol)

	local wallet = label(root, "", 12, MUTED, UDim2.new(0, RAIL_X + RAIL_W + 24, 0, 10),
		UDim2.new(1, -RAIL_X - RAIL_W - 38, 0, 16), FONT_M, Enum.TextXAlignment.Right)

	-- The catalogue. What it lists depends on the mode: every ore you have
	-- discovered in CRAFT, every tool you have forged in UPGRADE.
	local rail = mk("ScrollingFrame", {
		BackgroundTransparency = 1,
		-- y=62 clears the title band. The title was a 13px caption sharing this
		-- row; at 30px it needs the strip to itself or it lands on the list.
		Position = UDim2.fromOffset(RAIL_X, 62),
		Size = UDim2.new(0, RAIL_W, 1, -72),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
	}, root)
	mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, rail)

	local detail = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(RAIL_X + RAIL_W + 24, 62),
		Size = UDim2.new(1, -RAIL_X - RAIL_W - 38, 1, -72 - POUCH_H),
	}, root)

	--[[
		THE ORE POUCH, along the bottom.

		The Forge had a wallet strip -- coins, gems, dust -- and the detail pane
		quotes the ore cost of whatever is SELECTED. Neither answers the question
		you actually have while browsing a rail of a hundred recipes: what ore do
		I have? You had to tap through tools one at a time to find out, or leave
		the Forge for the pouch panel and come back.

		So: every ore you hold, rarest first, with how much. Plus the fill against
		capacity, because "I have 400 Cobalt" and "my pouch is full and every ore
		I break is being thrown away" are different problems and the second is
		urgent.

		A strip rather than a panel because it is reference, not somewhere to
		act: nothing in it is clickable, and the detail pane keeps the room.
	]]
	local pouchRow = mk("Frame", {
		Name = "PouchStrip",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, RAIL_X + RAIL_W + 24, 1, -10),
		Size = UDim2.new(1, -RAIL_X - RAIL_W - 38, 0, POUCH_H),
	}, root)
	local pouchHead = label(pouchRow, "ORE POUCH", 11, MUTED, UDim2.fromOffset(0, 0),
		UDim2.new(1, 0, 0, 14), FONT)
	local pouchScroll = mk("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 18),
		Size = UDim2.new(1, 0, 0, POUCH_H - 20),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 3,
	}, pouchRow)
	mk("UIListLayout", {
		Padding = UDim.new(0, 6),
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, pouchScroll)

	--[[
		Redrawn on every refresh, like the rail. The pouch changes with every
		block broken, so a strip built once would be lying within seconds.
	]]
	local function paintPouch(snapshot, cash)
		for _, d in ipairs(pouchScroll:GetChildren()) do
			if not d:IsA("UIListLayout") then
				d:Destroy()
			end
		end
		local ores = snapshot.ores or {}
		-- Rarest first: the order the pouch panel opens on, because the valuable
		-- rows are the decision and the common ones are noise.
		local rows = {}
		for _, ore in ipairs(C.ORES or {}) do
			local n = math.floor(tonumber(ores[ore.id]) or 0)
			if n > 0 then
				table.insert(rows, { ore = ore, n = n })
			end
		end
		table.sort(rows, function(a, b)
			return (tonumber(a.ore.tier) or 0) > (tonumber(b.ore.tier) or 0)
		end)

		local held, cap = 0, nil
		for _, r in ipairs(rows) do
			held += r.n
		end
		local okP, Pouch = pcall(function()
			return require(shared:WaitForChild("MineOrePouch"))
		end)
		if okP and Pouch and Pouch.capacity then
			local tier = math.max(1, math.floor(tonumber(snapshot.orePouchTier) or 1))
			cap = Pouch.capacity(tier)
			if Pouch.held then
				held = Pouch.held(ores)
			end
		end
		if cap and cap > 0 then
			local full = held >= cap
			pouchHead.Text = string.format("ORE POUCH   %s / %s%s",
				cash(held), cash(cap), full and "   FULL" or "")
			pouchHead.TextColor3 = full and RED or MUTED
		else
			pouchHead.Text = "ORE POUCH"
			pouchHead.TextColor3 = MUTED
		end

		if #rows == 0 then
			local empty = label(pouchScroll, "nothing in the pouch yet - break some ore",
				12, MUTED, UDim2.fromOffset(0, 0), UDim2.fromOffset(320, 26), FONT_M)
			empty.LayoutOrder = 1
			return
		end
		for i, r in ipairs(rows) do
			local chip = mk("Frame", {
				BackgroundColor3 = BG2,
				Size = UDim2.fromOffset(132, 26),
				LayoutOrder = i,
			}, pouchScroll)
			round(chip, 6)
			-- A dot in the ore's own colour, so the strip and the ore itself
			-- agree about what it looks like without naming it twice.
			local dot = mk("Frame", {
				BackgroundColor3 = (typeof(r.ore.color) == "Color3") and r.ore.color or MUTED,
				Position = UDim2.fromOffset(7, 8),
				Size = UDim2.fromOffset(10, 10),
			}, chip)
			round(dot, 5)
			label(chip, tostring(r.ore.name or r.ore.id), 11, TEXT,
				UDim2.fromOffset(22, 0), UDim2.new(1, -70, 1, 0), FONT_M)
			label(chip, cash(r.n), 11, GOLD, UDim2.new(1, -48, 0, 0),
				UDim2.fromOffset(42, 26), FONT, Enum.TextXAlignment.Right)
		end
	end

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

	local function drawUpgrade(host, snapshot, tool)
		local level = math.max(1, tonumber(tool.level) or 1)
		local coinTool = C.isCoinTool and C.isCoinTool(tool)
		local cap = coinTool and C.WOOD_PICK_MAX_LEVEL or C.TOOL_MAX_LEVEL
		local maxed = level >= cap

		--[[
			THE HERO BLOCK.

			This was a 19px name over a 13px level line, flush against the left
			edge of the pane, with the rest of the tool's identity spread out
			underneath as more 12px lines. Owner, 2026-10-05, comparing it with
			the reference: "still extremely far off".

			The reference leads with a large circular PORTRAIT of the tool, then
			the name at roughly thirty, then rarity and tier as chips. That
			portrait is most of the difference: the live panel showed no picture
			of the thing you were about to spend on.

			Everything below is positioned off HERO_X, so the text column starts
			clear of the portrait rather than being hand-offset in ten places.
		]]
		local PORTRAIT = 150
		local HERO_X = PORTRAIT + 28

		local orb = mk("Frame", {
			BackgroundColor3 = T.CARD_HI,
			Size = UDim2.fromOffset(PORTRAIT, PORTRAIT),
			Position = UDim2.fromOffset(0, 0),
		}, host)
		UI.round(orb, 999)
		UI.edge(orb, T.ACCENT, 2)
		-- The ore's own skin for a forged pickaxe. This is the hero portrait, so
		-- it is the one place a player studies the tool they are about to spend
		-- on -- showing the same generic pickaxe for all 82 tiers here was the
		-- worst of the places it showed.
		UI.icon(orb, Icons.forTool(tool) or IMG.merge, math.floor(PORTRAIT * 0.6),
			UDim2.fromOffset(math.floor(PORTRAIT * 0.2), math.floor(PORTRAIT * 0.2)))

		label(host, OreTools.toolName(tool), 28, TEXT, UDim2.fromOffset(HERO_X, 0),
			UDim2.new(1, -HERO_X, 0, 34), FONT)

		-- Rarity as a chip and the tier beside it, the way the reference reads
		-- them: what it is, then how deep it goes.
		local band = C.oreBandForTier and C.oreBandForTier(tool.tier) or nil
		if band then
			UI.pill(host, string.upper(band), T.ACCENT, UDim2.fromOffset(HERO_X, 38))
		end
		label(host, string.format("Tier %s", tostring(tool.tier or "?")), 15, T.GEM,
			UDim2.fromOffset(HERO_X + (band and 118 or 0), 38), UDim2.fromOffset(110, 26), FONT)

		label(host, string.format("level %d / %d", level, cap), 14,
			maxed and GOLD or MUTED, UDim2.fromOffset(HERO_X, 68), UDim2.new(1, -HERO_X, 0, 18))

		--[[
			Breaking power and reach, stated plainly, because they are the whole
			reason to forge a better tool and they are NOT the damage number
			above. Levelling moves damage and never moves reach.
		]]
		if C.toolBreakingPower and not coinTool then
			local bp = C.toolBreakingPower(tool)
			label(host, string.format("breaking power %d  \u{00B7}  reaches ore tier %d",
				bp, C.oreReachCap(bp)), 12, GOLD,
				UDim2.fromOffset(HERO_X, 92), UDim2.new(1, -HERO_X, 0, 16))
		end

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
			local typeMult = OreTools.typeMult(tool.familyId or selFamily, tool.tier)
			local ore, dust = C.toolUpgradeCost(tool.tier, level, typeMult)
			-- C.ORES[tool.tier] is what the server's _oreToolCost uses. Resolve
			-- it the same way or the panel quotes a different ore than the verb
			-- charges.
			local oreDef = C.ORES and C.ORES[tonumber(tool.tier) or 1]
			local oreId = oreDef and oreDef.id
			local haveOre = (oreId and tonumber((snapshot.ores or {})[oreId])) or 0
			local haveDust = tonumber(snapshot.dust) or 0
			canStep = ore ~= nil and haveOre >= ore and haveDust >= dust
			--[[
				WHAT THE LEVEL BUYS, LEADING WHAT IT COSTS.

				Owner, 2026-10-05: "something i could advertise when people
				crafting a new tool by each level UP%X". This is the panel that
				builds a tool and then levels it, so it is the place the number
				has to appear. A price on its own is a bill; the gain in front of
				it is the reason to pay.

				Read off C.TOOL_DMG_STEP rather than written out. That is
				perLevel(TOOL_CLIMB_DAMAGE), so it tracks TOOL_MAX_LEVEL -- +22%
				at the current cap of 30 -- and a cap change moves this line with
				it instead of leaving the forge advertising a number the game no
				longer applies. Same rule this panel already follows for price.
			]]
			local gain = ""
			local step = tonumber(C.TOOL_DMG_STEP)
			if step and step > 1 then
				gain = string.format("+%d%% damage  \u{00B7}  ",
					math.floor((step - 1) * 100 + 0.5))
			end
			costLine = gain .. string.format("%s %s  \u{00B7}  %s dust",
				num(ore or 0), (oreDef and oreDef.name) or "ore", num(dust or 0))
			heldLine = string.format("held  %s  \u{00B7}  %s", num(haveOre), num(haveDust))
		end

		label(host, costLine, 14, (maxed and GOLD) or (canStep and GREEN) or MUTED,
			UDim2.fromOffset(HERO_X, 114), UDim2.new(1, -HERO_X, 0, 20))
		if heldLine then
			label(host, heldLine, 13, MUTED, UDim2.fromOffset(HERO_X, 136), UDim2.new(1, -HERO_X, 0, 16))
		end

		-- Clear of the 150px portrait, so nothing sits on top of it.
		local y = 172
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
		local typeMult = OreTools.typeMult(tool.familyId or selFamily, tool.tier)
		local recOre, recDust = C.toolRecycle(tool.tier, level, typeMult)
		-- Equipping is what turns a forged tool into breaking power you actually
		-- carry, so it sits beside the levelling buttons rather than buried.
		local equipped = (snapshot.oreToolEquipped ~= nil and snapshot.oreToolEquipped == tool.uid)
		button(host, equipped and "EQUIPPED" or "EQUIP", GOLD,
			UDim2.fromOffset(0, y + 38), UDim2.fromOffset(110, 26), not equipped, function()
				if opts.onEquip then opts.onEquip(tool.uid) end
			end)

		button(host, "SCRAP  +" .. num(recOre) .. " ore / +" .. num(recDust) .. " dust",
			RED, UDim2.fromOffset(116, y + 38), UDim2.fromOffset(224, 26), true, function()
				if opts.onRecycle then opts.onRecycle(tool.uid) end
			end)

		--[[
			THE SKIN AND THE RUNE ON THIS TOOL.

			Both were invisible here, which made the Forge a panel about levelling
			a tool while saying nothing about the two things TODO 0.13 calls the
			build. You had to go to the Enchanter to find out whether the pick you
			were pouring ore into even had a skin on it.

			BOTH ARE PER FAMILY, NOT PER TOOL, and that is the fact a reader needs:
			p.toolSockets and p.toolTempers are keyed "pickaxe" / "drill" /
			"explosive". A forged tool row carries only uid, typeId, familyId,
			tier and level -- it cannot hold a rune or a temperament of its own.
			So this shows what the FAMILY is wearing, which is what this tool
			swings with, and says so rather than implying the fit is per-tool.

			It REPORTS and ROUTES rather than reimplementing. The Enchanter's
			Temper and Sockets tabs are several hundred lines each and work;
			building a second copy here is how two screens start disagreeing
			about what is fitted. Whether those tabs should eventually live here
			instead is a design call, not a side effect of this panel.
		]]
		local fam = tostring(tool.familyId or selFamily or "pickaxe")
		local ySkin = y + 76
		label(host, "ON THIS FAMILY", 11, MUTED, UDim2.fromOffset(0, ySkin),
			UDim2.new(1, 0, 0, 14), FONT)

		local tt = (snapshot.toolTempers or {})[fam] or {}
		local skinLine, skinInk = "no skin fitted", MUTED
		if tt.temperId then
			local okT, Temper = pcall(function()
				return require(shared:WaitForChild("MineTemper"))
			end)
			local kit = okT and Temper and Temper.kit and Temper.kit(tt.temperId) or nil
			skinLine = string.format("%s%s", tostring((kit and kit.name) or tt.temperId),
				tt.temperRarity and ("  " .. tostring(tt.temperRarity)) or "")
			skinInk = GOLD
		end
		label(host, "skin   " .. skinLine, 12, skinInk, UDim2.fromOffset(0, ySkin + 16),
			UDim2.new(1, -120, 0, 16))

		local socket = (snapshot.toolSockets or {})[fam]
		local runeId = (type(socket) == "table") and (socket.main or socket.omni) or socket
		local runeLine, runeInk = "no rune socketed", MUTED
		if runeId then
			local okR, Runes = pcall(function()
				return require(shared:WaitForChild("MineRunes"))
			end)
			local r
			for _, row in ipairs(snapshot.runes or {}) do
				if row.id == runeId then
					r = row
					break
				end
			end
			if okR and Runes and Runes.describe and r then
				runeLine = tostring(Runes.describe(r))
			else
				-- The rune is socketed but not in the loose list, which is exactly
				-- what being socketed means. Say that rather than "none".
				runeLine = "one socketed"
			end
			runeInk = GOLD
		end
		label(host, "rune   " .. runeLine, 12, runeInk, UDim2.fromOffset(0, ySkin + 34),
			UDim2.new(1, -120, 0, 16))

		if opts.onOpenEnchanter then
			button(host, "FIT A SKIN", BG3, UDim2.new(1, -118, 0, ySkin + 14),
				UDim2.fromOffset(112, 24), true, function()
					opts.onOpenEnchanter("temper")
				end)
			button(host, "SOCKET A RUNE", BG3, UDim2.new(1, -118, 0, ySkin + 42),
				UDim2.fromOffset(112, 24), true, function()
					opts.onOpenEnchanter("sockets")
				end)
		end
	end

	--[[
		CRAFT: one ore, one tool, and no frame to pick.

		This pane used to show a tool type and then a list of EVERY discovered
		ore you could forge it out of -- so "Wooden Pickaxe" quoted 500 Clay,
		and the same name could be made of forty ores at forty prices. The ore
		is the tool now: you pick the ore on the rail, and the frame it wears
		comes from MineOreTools.frameForTier, which the craft verb re-derives
		rather than trusting what this pane sends.
	]]
	local function drawCraft(host, snapshot, row)
		if not row then
			label(host, "Pick an ore on the left.", 13, MUTED,
				UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 18))
			return
		end
		local fam = selFamily
		-- The multiplier is the ore's, not a frame's. See MineOreTools.typeMult:
		-- it was always a function of tier, and the frame lookup it reached
		-- through is gone with the priced roster.
		local typeMult = OreTools.typeMult(fam, row.tier)
		local cost = C.toolCraftCost(row.tier, typeMult)
		local afford = (row.have or 0) >= cost

		label(host, OreTools.name(row.def, fam), 19, TEXT,
			UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 22), FONT)
		-- The frame is named but never offered: it is a consequence of the ore,
		-- and saying so beats letting it look like a hidden choice.
		label(host, string.format("ore tier %d  \u{00B7}  %s frame", row.tier,
			tostring((frame and frame.name) or "default")), 13, MUTED,
			UDim2.fromOffset(0, 26), UDim2.new(1, 0, 0, 16))

		if C.toolBreakingPower then
			local bp = C.toolBreakingPower(row.tier)
			label(host, string.format("breaking power %d  \u{00B7}  reaches ore tier %d",
				bp, C.oreReachCap(bp)), 12, GOLD,
				UDim2.fromOffset(0, 46), UDim2.new(1, 0, 0, 14))
		end

		label(host, string.format("%s %s", num(cost), row.name), 15,
			afford and GREEN or MUTED, UDim2.fromOffset(0, 68), UDim2.new(1, 0, 0, 18))
		--[[
			...and what that is in BLOCKS, which is the thing a player can
			actually weigh. The ore number alone is unreadable across the
			roster: a craft costs 965 Epic ore but only 200 Exotic, purely
			because Exotic drops three a block and Epic drops thirteen. In
			blocks they are 71 and 66 -- almost the same errand, which is the
			truth the raw number hides.
		]]
		label(host, string.format("held  %s %s   \u{00B7}   about %d blocks",
			num(row.have or 0), row.name,
			math.max(1, math.floor((C.craftBlocks and C.craftBlocks(row.tier) or 0) + 0.5))),
			12, MUTED, UDim2.fromOffset(0, 88), UDim2.new(1, 0, 0, 14))

		button(host, afford and "FORGE" or "NEED ORE", GREEN,
			UDim2.fromOffset(0, 114), UDim2.fromOffset(150, 30), afford, function()
				if opts.onCraft then
					opts.onCraft(fam, frame and frame.id or "", row.id)
				end
			end)

		-- Forging a second one is allowed -- the rack holds 200 -- but saying
		-- you already have one stops an accidental duplicate costing an ore
		-- bank the player was saving.
		local owned = ownedForOre(snapshot, fam, row.tier)
		if owned then
			label(host, string.format("you already have one, at level %d",
				math.max(1, tonumber(owned.level) or 1)), 12, GOLD,
				UDim2.fromOffset(160, 120), UDim2.new(1, -160, 0, 16))
		end
	end

	--[[
		The detail pane no longer carries a tab strip of its own. CRAFT and
		UPGRADE are modes of the whole panel now and live on the left rail, so
		what is drawn here follows the mode rather than being inferred from
		whether the selected row happens to be owned.
	]]
	local function drawDetail(snapshot)
		for _, d in ipairs(detail:GetChildren()) do
			if not d:IsA("UIListLayout") then
				d:Destroy()
			end
		end
		local host = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, detail)

		if selMode == "upgrade" then
			local tool
			for _, t in ipairs(ownedOf(snapshot, selFamily)) do
				if t.uid == selUid then
					tool = t
					break
				end
			end
			if not tool then
				label(host, "Pick a forged tool on the left.", 13, MUTED,
					UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 18))
				return
			end
			drawUpgrade(host, snapshot, tool)
			return
		end

		local row
		for _, o in ipairs(discoveredOres(snapshot)) do
			if o.id == selOreId then
				row = o
				break
			end
		end
		drawCraft(host, snapshot, row)
	end

	------------------------------------------------------------- mode  rail --

	--[[
		The left column: the three modes, then the three families.

		Rebuilt on every refresh like everything else here. It is nine small
		buttons; keeping them live and mutating their colours would save
		nothing and give the panel a second source of truth about what is
		selected.
	]]
	local function colButton(text, order, on, enabled, onClick)
		local b = mk("TextButton", {
			BackgroundColor3 = on and GOLD or BG3,
			AutoButtonColor = enabled,
			Text = text,
			Font = FONT,
			TextSize = 12,
			TextColor3 = on and Color3.fromRGB(26, 24, 20) or (enabled and TEXT or MUTED),
			Size = UDim2.new(1, 0, 0, 30),
			LayoutOrder = order,
			Active = enabled,
		}, modeCol)
		round(b, 6)
		if enabled then
			b.MouseButton1Click:Connect(onClick)
		end
		return b
	end

	local function paintModes()
		for _, d in ipairs(modeCol:GetChildren()) do
			if not d:IsA("UIListLayout") then
				d:Destroy()
			end
		end
		colButton("CRAFT", 1, selMode == "craft", true, function()
			selMode = "craft"
			refresh()
		end)
		colButton("UPGRADE", 2, selMode == "upgrade", true, function()
			selMode = "upgrade"
			refresh()
		end)
		if opts.onCoinShop then
			-- A route, not a mode: it never reads as selected because the panel
			-- it opens is not this one.
			colButton("SHOP", 3, false, true, function()
				opts.onCoinShop()
			end)
		end

		label(modeCol, "FAMILY", 10, MUTED, nil, UDim2.new(1, 0, 0, 20), FONT).LayoutOrder = 4
		local order = 4
		for _, famId in ipairs(OreTools.FAMILY_ORDER or {}) do
			local defs = (Tools.TOOLS or {})[famId]
			-- A family with no roster yet (weapons are flagged planned) would
			-- otherwise be a button that selects nothing.
			if defs and #defs > 0 then
				order += 1
				local id = famId
				colButton(string.upper(OreTools.familyNoun(id) .. "s"), order,
					selFamily == id, true, function()
						selFamily = id
						selUid = nil
						refresh()
					end)
			end
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
		-- Wallet uses the shared currency readout, not the local num(), so the
		-- Forge cannot disagree with the shop about what a player holds.
		local okAb, Ab = pcall(function()
			return require(shared:WaitForChild("MineAbbrev"))
		end)
		local cash = (okAb and Ab and Ab.currency) or num
		wallet.Text = string.format("%s coins  \u{00B7}  %s gems  \u{00B7}  %s dust",
			cash(snapshot.coins), cash(snapshot.gems), cash(snapshot.dust))
		paintPouch(snapshot, cash)
		paintModes()

		local function row(order, title, sub, titleInk, subInk, picked, onClick)
			local b = mk("TextButton", {
				BackgroundColor3 = picked and BG2 or BG3,
				AutoButtonColor = true,
				Text = "",
				Size = UDim2.new(1, -6, 0, 38),
				LayoutOrder = order,
			}, rail)
			round(b, 6)
			label(b, title, 13, titleInk, UDim2.fromOffset(10, 5),
				UDim2.new(1, -20, 0, 15), FONT)
			label(b, sub, 11, subInk, UDim2.fromOffset(10, 21), UDim2.new(1, -20, 0, 12))
			b.MouseButton1Click:Connect(onClick)
			return b
		end

		if selMode == "upgrade" then
			------------------------------------------------ what you have --
			local mine = ownedOf(snapshot, selFamily)
			if #mine == 0 then
				label(rail, "Nothing forged in this family yet.", 12, MUTED, nil,
					UDim2.new(1, -6, 0, 32), FONT_M).LayoutOrder = 1
			end
			-- Keep the player on the same tool across a redraw; fall back to
			-- the deepest one when the selection is gone (scrapped, usually).
			local still = false
			for _, t in ipairs(mine) do
				if t.uid == selUid then
					still = true
					break
				end
			end
			if not still then
				selUid = mine[1] and mine[1].uid or nil
			end
			for i, t in ipairs(mine) do
				local equipped = snapshot.oreToolEquipped ~= nil
					and snapshot.oreToolEquipped == t.uid
				row(i, OreTools.toolName(t),
					string.format("level %d%s", math.max(1, tonumber(t.level) or 1),
						equipped and "   \u{00B7}   equipped" or ""),
					TEXT, equipped and GOLD or GREEN, selUid == t.uid, function()
						selUid = t.uid
						refresh()
					end)
			end
		else
			--------------------------------------------- what you can make --
			--[[
				Sorted by the ore, deepest first -- the owner's ask, and the
				same order the pouch strip below uses, so the two halves of the
				screen agree about what "top of the list" means.
			]]
			local ores = discoveredOres(snapshot)
			if #ores == 0 then
				label(rail, "No ore discovered yet. Mine some first.", 12, MUTED, nil,
					UDim2.new(1, -6, 0, 32), FONT_M).LayoutOrder = 1
			end
			local still = false
			for _, o in ipairs(ores) do
				if o.id == selOreId then
					still = true
					break
				end
			end
			if not still then
				selOreId = ores[1] and ores[1].id or nil
			end
			for i, o in ipairs(ores) do
				local cost = C.toolCraftCost(o.tier, OreTools.typeMult(selFamily, o.tier))
				local owned = ownedForOre(snapshot, selFamily, o.tier)
				local afford = (o.have or 0) >= cost
				row(i, OreTools.name(o.def, selFamily),
					owned
						and string.format("forged  \u{00B7}  level %d",
							math.max(1, tonumber(owned.level) or 1))
						or string.format("%s %s   (held %s)", num(cost), o.name, num(o.have or 0)),
					owned and TEXT or (afford and TEXT or MUTED),
					owned and GOLD or (afford and GREEN or MUTED),
					selOreId == o.id, function()
						selOreId = o.id
						refresh()
					end)
			end
		end

		drawDetail(snapshot)
	end

	refresh()
	return { refresh = refresh, root = root }
end

return MineForge
