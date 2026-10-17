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
local OreIcons = require(shared:WaitForChild("MineOreIcons"))
local T = require(shared:WaitForChild("MineTheme"))
local UI = require(shared:WaitForChild("MineUI"))
local Icons = require(shared:WaitForChild("MineIcons"))
--[[
	The recipe detail shows the actual tool, turning, not a picture of one.
	ToolModelFactory lives at the ReplicatedStorage root rather than under
	Mine/Shared, and it is loaded with pcall because a ViewportFrame is a nicety
	-- if the factory is missing the panel must still open and still forge.
]]
local okFactory, Factory = pcall(function()
	return require(RS:WaitForChild("ToolModelFactory"))
end)
if not okFactory then
	Factory = nil
end

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
	EVERY RECIPE IN THE GAME, CRAFTABLE ONES FIRST.

	Owner, 2026-10-08: "SHOW ALL RECIPLES, the ones can you craft should
	automatically be at the top".

	discoveredOres above returns only what the player has seen, which is right
	for a rail you pick an ore out of and wrong for a catalogue: a grid that
	shows eleven squares tells a player the game has eleven tools in it.

	So this returns all 82, and carries `locked` for the ones not yet
	discovered. Rule 3 at the top of this file still holds -- an undiscovered
	ore must not leak its name, tier or colour -- so a locked square is drawn
	as a blank, and nothing on it is read from the ore row. Showing that a
	recipe EXISTS is not the same as showing what it is, and the count is the
	part the owner asked for.

	Sort is craftable, then owned, then everything else, each by tier. Craftable
	first is the ask and it is also the only ordering that answers the question
	a player opens this screen with. `tier` breaks ties so the order is stable
	across redraws -- a grid that reshuffles under the cursor while ore comes in
	is worse than one that is merely long.
]]
local function allRecipes(snapshot, familyId)
	local held = snapshot.ores or {}
	local seen = snapshot.oresSeen
	local out = {}
	for _, def in ipairs(C.ORES or {}) do
		local have = tonumber(held[def.id]) or 0
		local discovered
		if type(seen) == "table" then
			discovered = seen[def.id] and true or false
		else
			discovered = have > 0
		end
		local cost = C.toolCraftCost(def.tier, OreTools.typeMult(familyId, def.tier), familyId)
		out[#out + 1] = {
			id = def.id,
			def = def,
			tier = def.tier,
			name = def.name,
			have = have,
			cost = cost,
			locked = not discovered,
			afford = discovered and have >= cost,
		}
	end
	--[[
		Craftable first, then discovered, then locked -- and BEST FIRST inside
		each band.

		Owner, 2026-10-11: craftable recipes go "at the top, sorted from best to
		least", and the rest "sorted by descending rarity by default".

		The tie-break used to be ascending tier, which put the weakest thing a
		player could make at the very top of the screen. For an ore, tier IS the
		rarity ladder -- deeper ore is rarer and better -- so one comparison
		satisfies both halves of that sentence.

		Locked stays last and still leaks nothing: Rule 3 means a locked square
		is drawn blank, and ordering by tier does not name, colour or rank it on
		screen.
	]]
	table.sort(out, function(a, b)
		local ra = a.afford and 0 or (a.locked and 2 or 1)
		local rb = b.afford and 0 or (b.locked and 2 or 1)
		if ra ~= rb then
			return ra < rb
		end
		if a.tier ~= b.tier then
			return a.tier > b.tier
		end
		-- Stable across redraws: a grid that reshuffles under the cursor while
		-- ore comes in is worse than one that is merely long.
		return tostring(a.id) < tostring(b.id)
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
	--[[
		SCRAP ARMS BEFORE IT FIRES.

		Scrapping destroys a tool outright and there was no step between the
		click and the loss. That was survivable only while the button appeared
		to be paying for it; now that the quote is honest, the common case reads
		"+0 ore / +0 dust" and a single misclick on a 224px red button throws a
		tool away for literally nothing.

		Held by UID rather than by a flag, so arming one tool and then selecting
		a different one does not leave the second one armed.
	]]
	local scrapArmed = nil
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
		THE CRAFT PANE: A GRID OF RECIPES, NOT A RAIL AND A FORM.

		Owner, 2026-10-08, on the old craft screen: "rn so so shit and i fucking
		hate it .. make it like how the shop used to be, expect when you looking
		for something to craft theres a bunch of recipe squares (5 recipes per
		row, it should have the name icon what it needs)".

		CRAFT gets the whole panel instead of a 232px rail and a text form in the
		gutter beside it. The rail and the detail frame above are still used --
		by UPGRADE, which genuinely is a list of a few owned tools and a pile of
		numbers -- and are simply hidden while crafting.

		Two screens, one at a time, switched on selOreId:

		  nil -> THE GRID. Every recipe in the game as a square.
		  set -> THE RECIPE. The tool in 3D, its cost and what it does.

		Five per row comes from the CellSize scale: 0.2 of the pane width, so it
		stays five across at any window size rather than reflowing to four on a
		laptop and six on a monitor. The offset in the X term is the gutter, which
		is why it is negative.
	]]
	local craftPane = mk("Frame", {
		Name = "CraftPane",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(RAIL_X, 62),
		Size = UDim2.new(1, -RAIL_X - 14, 1, -72 - POUCH_H),
		Visible = false,
	}, root)

	--[[
		SEARCH, over a catalogue of 82 recipes per family.

		Owner, 2026-10-11: "Add search, sorting, and useful filters."

		RULE 3 DECIDES WHAT IT CAN MATCH. An undiscovered ore must not leak its
		name, tier or colour, so a locked square is drawn blank -- which means
		it cannot be searched either. Matching a query against a hidden name
		would tell a player exactly what they have not found yet: type "cobalt",
		watch one blank square survive the filter, and the name is leaked by
		position. So a query hides every locked row instead, and the count below
		says how many are still out there.
	]]
	local searchBox = mk("TextBox", {
		Name = "RecipeSearch",
		BackgroundColor3 = BG3,
		Size = UDim2.new(0.42, 0, 0, 30),
		Position = UDim2.fromOffset(0, 0),
		Font = FONT_M,
		TextSize = 13,
		TextColor3 = TEXT,
		PlaceholderText = "Search recipes...",
		PlaceholderColor3 = MUTED,
		Text = "",
		ClearTextOnFocus = false,
		Visible = false,
	}, craftPane)
	round(searchBox, 8)

	local searchNote = label(craftPane, "", 11, MUTED,
		UDim2.new(0.44, 10, 0, 8), UDim2.new(0.56, -10, 0, 18), FONT_M)
	searchNote.Visible = false

	local grid = mk("ScrollingFrame", {
		Name = "RecipeGrid",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 38),
		Size = UDim2.new(1, 0, 1, -38),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 5,
		Visible = false,
	}, craftPane)
	mk("UIGridLayout", {
		-- 124 -> 148: the card carries a rarity band, a 52px icon, a wrapped
		-- tool name at the 14px floor, the cost and the ore. At 124 the ore
		-- line fell off the bottom edge.
		CellSize = UDim2.new(0.2, -10, 0, 148),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
	}, grid)

	local recipeView = mk("Frame", {
		Name = "RecipeView",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
	}, craftPane)

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
			--[[
				The ore's own render, with its colour behind as the fallback.

				This was a 10px dot in `ore.color`, which told you an ore was
				greenish and nothing else -- and the roster has several greens.
				The art is unambiguous at a glance, which is the whole job of a
				strip you read while deciding what to forge.
			]]
			local dot = mk("Frame", {
				BackgroundColor3 = (typeof(r.ore.color) == "Color3") and r.ore.color or MUTED,
				Position = UDim2.fromOffset(5, 4),
				Size = UDim2.fromOffset(18, 18),
			}, chip)
			round(dot, 5)
			local dotArt = OreIcons.icon(r.ore.id)
			if dotArt then
				mk("ImageLabel", {
					BackgroundTransparency = 1,
					Image = dotArt,
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(1, 1),
				}, dot)
			end
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
		--[[
			THE PANE IS BIG. THIS USED ABOUT A FIFTH OF IT.

			Owner, 2026-10-12: "finish the forge ui". Everything this screen says
			was already right -- portrait, rarity, the gain before the price, an
			armed SCRAP -- and it was all crammed into a 340x200 corner of a pane
			roughly 900 tall, with the remaining four fifths dark and empty. It
			did not read as a simple screen, it read as an unfinished one.

			So the same content is laid out against the pane instead of against
			(0, 0): a hero band across the top, the numbers in a card that spans
			the width, the actions in a row of buttons big enough to hit on a
			phone, and the build at the bottom. Nothing below changes WHAT is
			said, only where it sits and how big it is.
		]]
		local PORTRAIT = 200
		local HERO_X = PORTRAIT + 36
		local PANE_W = math.max(360, host.AbsoluteSize.X)

		local orb = mk("Frame", {
			BackgroundColor3 = T.CARD_HI,
			Size = UDim2.fromOffset(PORTRAIT, PORTRAIT),
			Position = UDim2.fromOffset(0, 0),
		}, host)
		UI.round(orb, 999)
		UI.edge(orb, T.ACCENT, 3)
		-- The ore's own skin for a forged pickaxe. This is the hero portrait, so
		-- it is the one place a player studies the tool they are about to spend
		-- on -- showing the same generic pickaxe for all 82 tiers here was the
		-- worst of the places it showed.
		UI.icon(orb, Icons.forTool(tool) or IMG.merge, math.floor(PORTRAIT * 0.6),
			UDim2.fromOffset(math.floor(PORTRAIT * 0.2), math.floor(PORTRAIT * 0.2)))

		label(host, OreTools.toolName(tool), 34, TEXT, UDim2.fromOffset(HERO_X, 8),
			UDim2.new(1, -HERO_X, 0, 42), FONT)

		-- Rarity as a chip and the tier beside it, the way the reference reads
		-- them: what it is, then how deep it goes.
		local band = C.oreBandForTier and C.oreBandForTier(tool.tier) or nil
		if band then
			UI.pill(host, string.upper(band), T.ACCENT, UDim2.fromOffset(HERO_X, 56))
		end
		label(host, string.format("Tier %s", tostring(tool.tier or "?")), T.TEXT_BODY, T.GEM,
			UDim2.fromOffset(HERO_X + (band and 128 or 0), 56), UDim2.fromOffset(120, 28), FONT)

		label(host, string.format("level %d / %d", level, cap), T.TEXT_BODY,
			maxed and GOLD or MUTED, UDim2.fromOffset(HERO_X, 92), UDim2.new(1, -HERO_X, 0, 22))

		--[[
			Breaking power and reach, stated plainly, because they are the whole
			reason to forge a better tool and they are NOT the damage number
			above. Levelling moves damage and never moves reach.
		]]
		if C.toolBreakingPower and not coinTool then
			local bp = C.toolBreakingPower(tool)
			label(host, string.format("breaking power %d  \u{00B7}  reaches ore tier %d",
				bp, C.oreReachCap(bp)), T.TEXT_MIN, GOLD,
				UDim2.fromOffset(HERO_X, 122), UDim2.new(1, -HERO_X, 0, 20))
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
			local ore, dust = C.toolUpgradeCost(tool.tier, level, typeMult, tool.familyId)
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

		--[[
			THE PRICE GETS A CARD, SPANNING THE PANE.

			It was two bare lines floating beside the portrait at 14 and 13px.
			This is the number the whole screen is asking the player to agree
			to, so it sits on its own surface, at the type floors, across the
			full width -- which is also the space that was empty.
		]]
		local priceCard = mk("Frame", {
			BackgroundColor3 = T.CARD,
			Position = UDim2.fromOffset(0, PORTRAIT + 22),
			Size = UDim2.new(1, 0, 0, heldLine and 82 or 58),
		}, host)
		UI.round(priceCard, 12)
		UI.edge(priceCard, T.OUTLINE, T.STROKE_CHUNKY)
		label(priceCard, costLine, T.TEXT_BODY, (maxed and GOLD) or (canStep and GREEN) or MUTED,
			UDim2.fromOffset(16, 12), UDim2.new(1, -32, 0, 24), FONT)
		if heldLine then
			label(priceCard, heldLine, T.TEXT_MIN, MUTED,
				UDim2.fromOffset(16, 44), UDim2.new(1, -32, 0, 20))
		end

		-- Clear of the portrait AND the price card, so nothing overlaps.
		local y = PORTRAIT + 22 + (heldLine and 82 or 58) + 16
		--[[
			Buttons at 92x44 rather than 56x28. The old row was below every
			touch-target guidance there is, on a screen whose whole job is
			spending, and it had four fifths of a pane going spare.
		]]
		local BW, BH, BGAP = 92, 44, 10
		button(host, "+1", GREEN, UDim2.fromOffset(0, y), UDim2.fromOffset(BW, BH),
			canStep == true, function()
				if opts.onUpgrade then opts.onUpgrade(tool.uid, 1) end
			end)
		button(host, "+10", GREEN, UDim2.fromOffset(BW + BGAP, y), UDim2.fromOffset(BW, BH),
			canStep == true, function()
				if opts.onUpgrade then opts.onUpgrade(tool.uid, 10) end
			end)
		button(host, "MAX", GREEN, UDim2.fromOffset((BW + BGAP) * 2, y), UDim2.fromOffset(BW, BH),
			canStep == true, function()
				if opts.onUpgrade then opts.onUpgrade(tool.uid, cap) end
			end)

		-- Scrapping is always offered; it is the one action that works when the
		-- player cannot afford anything else.
		local typeMult = OreTools.typeMult(tool.familyId or selFamily, tool.tier)
		--[[
			PASS `base`. THIS BUTTON QUOTED A REFUND THE SERVER DOES NOT PAY.

			toolRecycle is (spent at `level`) - (spent at `baseLevel`), and
			baseLevel defaults to 1 when the argument is left off. This call left
			it off; the server passes the tool's real `base`. So the two sides
			computed different things from the same function, which is exactly
			what rule 1 at the top of this file exists to prevent -- and the rule
			held for the price, which IS shared, while the refund quietly did not.

			It is not a rounding difference. A newly forged tool INHERITS the
			highest level you own and is stamped base = inherited (see the craft
			verb), so once anything of yours is level 10 every tool you forge
			starts at level 10 with base 10. For that tool:

			  server : spent(10) - spent(10) = 0
			  panel  : spent(10) - spent(1)  = the entire climb

			The button therefore advertised a large ore and dust refund, the
			server paid nothing, and the tool was destroyed either way -- with no
			confirmation step in between, because the quote made it look free.

			Reading `base` the same way the server does, clamp and fallback
			included, so a row saved before `base` existed reads 1 on both sides.
		]]
		local recBase = math.clamp(math.floor(tonumber(tool.base) or 1), 1, level)
		local recOre, recDust = C.toolRecycle(tool.tier, level, typeMult, recBase)
		-- Equipping is what turns a forged tool into breaking power you actually
		-- carry, so it sits beside the levelling buttons rather than buried.
		local equipped = (snapshot.oreToolEquipped ~= nil and snapshot.oreToolEquipped == tool.uid)
		local y2 = y + BH + BGAP
		button(host, equipped and "EQUIPPED" or "EQUIP", GOLD,
			UDim2.fromOffset(0, y2), UDim2.fromOffset(150, BH), not equipped, function()
				if opts.onEquip then opts.onEquip(tool.uid) end
			end)

		local armed = (scrapArmed == tool.uid)
		button(host,
			armed and "DESTROY IT?  click again"
				or ("SCRAP  +" .. num(recOre) .. " ore / +" .. num(recDust) .. " dust"),
			RED, UDim2.fromOffset(160, y2), UDim2.fromOffset(300, BH), true, function()
				if armed then
					scrapArmed = nil
					if opts.onRecycle then
						opts.onRecycle(tool.uid)
					end
				else
					scrapArmed = tool.uid
					refresh()
				end
			end)
		if armed then
			-- Says what is actually lost, because the refund line above may
			-- legitimately read zero and "scrap for nothing" needs to be a
			-- decision rather than a surprise.
			label(host, recOre > 0
					and "the tool is gone; only levels you bought come back"
					or "this tool refunds NOTHING -- it was forged at its level",
				T.TEXT_MIN, RED, UDim2.fromOffset(160, y2 + BH + 6),
				UDim2.new(1, -160, 0, 20), FONT_M)
		end

		--[[
			THE SKIN AND THE ENCHANTS ON THIS TOOL.

			Both were invisible here, which made the Forge a panel about levelling
			a tool while saying nothing about the two things TODO 0.13 calls the
			build. You had to go to the Enchanter to find out whether the pick you
			were pouring ore into even had a skin on it.

			THE SKIN IS PER FAMILY, NOT PER TOOL: p.toolTempers is keyed
			"pickaxe" / "drill" / "explosive", so this shows what the FAMILY is
			wearing and says so. Enchants are per tool (tool.enchants, since runes
			were retired on 2026-10-12) and are applied at the Forge hub.

			It REPORTS and ROUTES rather than reimplementing. The Enchanter's
			Temper tab is several hundred lines and works;
			building a second copy here is how two screens start disagreeing
			about what is fitted. Whether those tabs should eventually live here
			instead is a design call, not a side effect of this panel.
		]]
		local fam = tostring(tool.familyId or selFamily or "pickaxe")
		-- The build gets its own card under the actions, which is where the rest
		-- of the pane's empty space was.
		local ySkin = y2 + BH + 36
		do
			-- Flush with the price card above it, not bled 14px past the pane on
			-- each side -- the right edge was running off the panel. And tall
			-- enough for the button and both lines.
			local buildCard = mk("Frame", {
				BackgroundColor3 = T.CARD,
				Position = UDim2.fromOffset(0, ySkin - 16),
				Size = UDim2.new(1, 0, 0, 112),
				ZIndex = 0,
			}, host)
			UI.round(buildCard, 12)
			UI.edge(buildCard, T.OUTLINE, T.STROKE_CHUNKY)
		end
		label(host, "ON THIS FAMILY", T.TEXT_MIN, MUTED, UDim2.fromOffset(16, ySkin),
			UDim2.new(1, -32, 0, 18), FONT)

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
		label(host, "skin   " .. skinLine, T.TEXT_MIN, skinInk, UDim2.fromOffset(16, ySkin + 26),
			UDim2.new(1, -120, 0, 16))

		local enchLine, enchInk = "none · enchant it at the FORGE", MUTED
		if type(tool.enchants) == "table" and next(tool.enchants) ~= nil then
			local okE, E = pcall(function()
				return require(shared:WaitForChild("MineEnchants"))
			end)
			local bits = {}
			for _, slotId in ipairs({ "damage", "utility", "special" }) do
				local e = tool.enchants[slotId]
				local def = okE and type(e) == "table" and E.get(e.id) or nil
				if def then
					table.insert(bits, def.name .. " " .. E.roman(e.level))
				end
			end
			if #bits > 0 then
				enchLine, enchInk = table.concat(bits, " · "), GOLD
			end
		end
		label(host, "enchants   " .. enchLine, T.TEXT_MIN, enchInk, UDim2.fromOffset(16, ySkin + 52),
			UDim2.new(1, -120, 0, 16))

		if opts.onOpenEnchanter then
			button(host, "FIT A SKIN", BG3, UDim2.new(1, -166, 0, ySkin + 18),
				UDim2.fromOffset(140, 30), true, function()
					opts.onOpenEnchanter("temper")
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
		-- `fam`, the same family typeMult just used. `row` carries an ORE, not a
		-- family, so reading row.familyId here would have passed nil and quoted
		-- the cheaper pre-hammer price while the server charged the real one.
		local cost = C.toolCraftCost(row.tier, typeMult, fam)
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
		ONE RECIPE SQUARE: icon, name, what it needs.

		A locked square reads nothing off the ore row -- no name, no tier, no
		colour -- because rule 3 at the top of this file says an undiscovered
		ore must not leak through a recipe. It still occupies its place in the
		grid, so the catalogue is honest about its own size.
	]]
	--[[
		THE RECIPE CARD.

		Owner, 2026-10-11: "Each recipe should be an item card with the icon and
		name of the tool being crafted", with "excellent item cards" and
		"distinct rarity treatments" -- and then, "forge needs all attention".

		Four things were wrong with the old square:

		1. It drew the ORE, not the tool. MineIcons carries ORE_PICK, ORE_DRILL
		   and ORE_BOMB -- 82 per-tier icons each, 246 in all, of the actual
		   forged tool -- and NOTHING in the game read one of them.
		2. It was built out of raw instances, so it had none of the house
		   chrome: no fat outline, no juice, no press.
		3. Text sat at 10-12px against floors of 14/16.
		4. The only state it showed was affordable-or-not. 82 recipes all look
		   the same weight, so nothing told you a deep one was worth wanting.

		THE ICON IS LAYERED, AND THAT IS DELIBERATE. 231 of those 246 ids do not
		currently serve -- they are real Image assets, creator iPressBars, all
		uploaded 2026-10-06, and only tiers 1/20/41/60/82 come back Success, the
		same stuck batch as the charm art. A failed ImageLabel draws nothing, so
		the ore icon goes UNDERNEATH and the tool icon on top: today the card
		shows the ore and reads correctly, and the moment moderation clears the
		tool art appears with no code change.
	]]
	local TOOL_SHEET = {
		pickaxe = Icons.ORE_PICK,
		drill = Icons.ORE_DRILL,
		explosive = Icons.ORE_BOMB,
	}
	--[[
		Five rarity bands across the 82 rungs, so depth reads as worth.
		Deliberately NOT shown on a locked card: a coloured stripe on an
		undiscovered square would leak its tier, which Rule 3 forbids just as
		much as leaking the name.
	]]
	-- Color3.fromRGB spelled out: this file has no C3 helper, and a missing
	-- local is a GLOBAL READ in Luau -- nil at runtime, clean at build time.
	local BANDS = {
		{ upto = 16, color = Color3.fromRGB(150, 156, 178) },
		{ upto = 33, color = Color3.fromRGB(112, 214, 140) },
		{ upto = 49, color = Color3.fromRGB(96, 176, 255) },
		{ upto = 66, color = Color3.fromRGB(186, 124, 255) },
		{ upto = 82, color = Color3.fromRGB(255, 194, 77) },
	}
	local function bandOf(tier)
		for _, b in ipairs(BANDS) do
			if (tonumber(tier) or 1) <= b.upto then
				return b.color
			end
		end
		return BANDS[#BANDS].color
	end

	local function recipeCell(host, r, order, onPick)
		--[[
			CELL OUTSIDE, BUTTON INSIDE, AND THAT SPLIT IS LOAD-BEARING.

			`juice` works by putting a UIScale on what you hand it. Hand it a
			UIGridLayout CELL and the cell scales inside a slot the layout has
			already sized -- the bug the skins wardrobe shipped, where a scaled
			tile left its own cell and rendered blank.

			So the thing the grid owns is a plain Frame of fixed size, and
			everything visible lives in a button filling it. The button carries
			the art, the press and the scale; the grid only ever sees the frame.
		]]
		local cell = mk("Frame", {
			BackgroundTransparency = 1,
			LayoutOrder = order,
		}, host)
		local b = mk("TextButton", {
			BackgroundColor3 = r.locked and BG3 or BG2,
			BackgroundTransparency = r.locked and 0.25 or 0,
			AutoButtonColor = false,
			Text = "",
			Size = UDim2.fromScale(1, 1),
		}, cell)
		round(b, 12)
		-- The kit's edge(), not a raw UIStroke: it falls back to T.EDGE and a
		-- 1px thickness if the theme keys are missing, which a direct
		-- `stroke.Color = T.OUTLINE` does not -- that throws on nil and takes
		-- the whole grid with it.
		local stroke = UI.edge(b, T.OUTLINE, T.STROKE_CHUNKY)

		if r.locked then
			-- Rule 3: nothing here is read from the ore row.
			label(b, "?", 34, MUTED, UDim2.fromOffset(0, 34), UDim2.new(1, 0, 0, 40),
				FONT, Enum.TextXAlignment.Center)
			label(b, "undiscovered", T.TEXT_MIN, MUTED, UDim2.fromOffset(0, 86),
				UDim2.new(1, 0, 0, 18), FONT_M, Enum.TextXAlignment.Center)
			return b
		end

		-- Rarity: a band across the top, and the same colour on the outline
		-- once you can actually forge it.
		local band = bandOf(r.tier)
		local stripe = mk("Frame", {
			Name = "Band", BackgroundColor3 = band, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 6), Position = UDim2.fromOffset(0, 0),
		}, b)
		round(stripe, 3)

		-- Icon: ore underneath, the forged tool over the top of it.
		local art = OreIcons.BY_ID and OreIcons.BY_ID[r.id]
		if art and art.icon then
			UI.icon(b, art.icon, 52, UDim2.new(0.5, -26, 0, 14))
		end
		local sheet = TOOL_SHEET[selFamily]
		local toolArt = sheet and sheet[tonumber(r.tier) or -1]
		if toolArt then
			UI.icon(b, toolArt, 52, UDim2.new(0.5, -26, 0, 14))
		end

		label(b, OreTools.name(r.def, selFamily), T.TEXT_MIN, TEXT,
			UDim2.fromOffset(6, 70), UDim2.new(1, -12, 0, 32),
			FONT, Enum.TextXAlignment.Center).TextWrapped = true

		-- What it NEEDS, which is the whole reason the square is readable at a
		-- glance: the amount, and whether you are there yet.
		local costLbl = label(b, string.format("%s / %s", num(r.have), num(r.cost)),
			T.TEXT_MIN, r.afford and GREEN or MUTED, UDim2.fromOffset(6, 104),
			UDim2.new(1, -12, 0, 18), FONT, Enum.TextXAlignment.Center)
		costLbl.Font = Enum.Font.GothamBlack

		label(b, r.name, T.TEXT_MIN - 1, MUTED, UDim2.fromOffset(6, 124),
			UDim2.new(1, -12, 0, 16), FONT_M, Enum.TextXAlignment.Center)

		if r.afford then
			stroke.Color = GREEN
			stroke.Thickness = T.STROKE_THICK or 4
			stroke.Transparency = 0
		end
		-- Everything pressable gets juice; the kit's own rule.
		UI.juice(b)
		b.MouseButton1Click:Connect(onPick)
		return b
	end

	local function drawGrid(snapshot)
		for _, d in ipairs(grid:GetChildren()) do
			if not d:IsA("UIGridLayout") then
				d:Destroy()
			end
		end
		local rows = allRecipes(snapshot, selFamily)
		local q = string.lower(searchBox.Text or "")
		local shown, hiddenLocked = 0, 0
		for _, r in ipairs(rows) do
			local keep = true
			if q ~= "" then
				if r.locked then
					-- Never matched by name: see the Rule 3 note on searchBox.
					keep = false
					hiddenLocked += 1
				else
					local nm = string.lower(tostring(OreTools.name(r.def, selFamily) or r.name or ""))
					keep = string.find(nm, q, 1, true) ~= nil
				end
			end
			if keep then
				shown += 1
				local r2 = r
				recipeCell(grid, r2, shown, function()
					selOreId = r2.id
					refresh()
				end)
			end
		end
		if q ~= "" then
			searchNote.Visible = true
			searchNote.Text = ("%d of %d  ·  %d undiscovered hidden")
				:format(shown, #rows, hiddenLocked)
		else
			searchNote.Visible = false
		end
	end

	--[[
		Typing redraws the grid and nothing else.

		Connected HERE, below drawGrid, and not up beside the TextBox: a local
		referenced above its declaration compiles to a GLOBAL READ in Luau, so
		the handler would have called nil on the first keystroke with no error
		at build time.

		drawGrid, not refresh: refresh rebuilds the rail, the modes and the
		pouch strip too, and doing all of that per character is how a search box
		ends up feeling broken on a phone.
	]]
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		if grid.Visible then
			drawGrid((opts.getSnap and opts.getSnap()) or {})
		end
	end)

	--[[
		THE RECIPE: the tool itself, then what it costs and what it does.

		"when you click a recipe it should bring you into a 3d view of the tool,
		with how much ore it takes, how much breaking power, how much damage."

		The model is built the same way the server builds the one that ends up
		in the player's hand -- ToolModelFactory.build with the ore's own look --
		so the preview is the tool, not an impression of it.

		No "about N blocks" line. The owner called it unprofessional and it is
		gone; the ore cost is the number, and the pouch strip along the bottom
		already says how close you are to it.
	]]
	local function drawRecipe(snapshot, r)
		for _, d in ipairs(recipeView:GetChildren()) do
			d:Destroy()
		end

		mk("TextButton", {
			BackgroundColor3 = BG3, AutoButtonColor = true, Text = "\u{2190}  ALL RECIPES",
			TextColor3 = TEXT, TextSize = 12, Font = FONT,
			Size = UDim2.fromOffset(140, 26), Position = UDim2.fromOffset(0, 0),
		}, recipeView).MouseButton1Click:Connect(function()
			selOreId = nil
			refresh()
		end)

		local stage = mk("Frame", {
			BackgroundColor3 = BG3,
			Position = UDim2.fromOffset(0, 36),
			Size = UDim2.new(0.46, -8, 1, -44),
		}, recipeView)
		round(stage, 10)

		--[[
			A LIVE STAGE, NOT A DARK RECTANGLE. Owner, 2026-10-08: "can we make
			the packground more active and shit".

			Two things, both cheap and both tinted by the ORE so the backdrop
			belongs to the tool standing on it rather than being generic chrome:

			  a gradient that slowly turns, so the light on the stage moves
			  motes that drift upward and recycle, so something is always moving

			Deliberately low contrast. This sits behind a rotating 3D model and
			under six lines of numbers; a background that competes with either
			is worse than a flat one. The gradient runs ore-colour to panel at
			0.55 transparency and the motes are 2-3px.

			Everything here is parented INSIDE the stage, so clearing
			recipeView on the next draw takes it all with it -- and the
			Heartbeat below stops itself the moment the stage leaves the tree,
			which is what keeps a tab change from leaking a connection per
			recipe viewed.
		]]
		local tint = (typeof(r.def and r.def.color) == "Color3") and r.def.color or GOLD
		local grad = mk("UIGradient", {
			Color = ColorSequence.new(tint, BG3),
			Transparency = NumberSequence.new(0.55),
			Rotation = 0,
		}, stage)

		local motes = {}
		for i = 1, 9 do
			local m = mk("Frame", {
				BackgroundColor3 = tint,
				BackgroundTransparency = 0.45 + (i % 3) * 0.15,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(2 + (i % 2), 2 + (i % 2)),
				Position = UDim2.fromScale(0.08 + (i * 0.1) % 0.86, (i * 0.11) % 1),
				ZIndex = 0,
			}, stage)
			round(m, 2)
			motes[i] = { f = m, speed = 0.02 + (i % 4) * 0.012, x = 0.08 + (i * 0.1) % 0.86 }
		end

		local t0 = 0
		local drift
		drift = game:GetService("RunService").Heartbeat:Connect(function(dt)
			if not stage.Parent then
				drift:Disconnect()
				return
			end
			t0 += dt
			grad.Rotation = (t0 * 8) % 360
			for i, mo in ipairs(motes) do
				local y = mo.f.Position.Y.Scale - mo.speed * dt
				if y < -0.05 then
					y = 1.05
				end
				-- a slow sideways sway, so they do not read as falling snow
				mo.f.Position = UDim2.fromScale(mo.x + math.sin(t0 * 0.6 + i) * 0.012, y)
			end
		end)

		if Factory and Factory.build then
			local vp = mk("ViewportFrame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}, stage)
			local okBuild, model = pcall(function()
				local look = Factory.oreLook and Factory.oreLook(r.def, C.ORE_COUNT or #C.ORES)
				local m = Factory.build(selFamily, r.tier, C.ORE_COUNT or #C.ORES, look)
				return m
			end)
			if okBuild and model then
				--[[
					A ViewportFrame renders neither lights nor particles, so the
					FX folder is dead weight in here -- and an unanchored part
					inside one falls. Strip and anchor before parenting.
				]]
				local fx = model:FindFirstChild("FX")
				if fx then
					fx:Destroy()
				end
				for _, d in ipairs(model:GetDescendants()) do
					if d:IsA("BasePart") then
						d.Anchored = true
					end
				end
				model.Parent = vp
				local cam = Instance.new("Camera")
				cam.Parent = vp
				vp.CurrentCamera = cam
				local cf, size = model:GetBoundingBox()
				local dist = math.max(size.Magnitude * 1.1, 3)
				cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(dist * 0.6, dist * 0.42, dist * 0.78),
					cf.Position)
				--[[
					TURN IT ABOUT WORLD Y, NOT ABOUT THE PIVOT'S OWN Y.

					This read `model:PivotTo(model:GetPivot() * CFrame.Angles(0,
					dt, 0))`, which spins about the PIVOT's local Y -- and the
					pivot here is not upright. build() sets PrimaryPart to the
					Handle, and the Handle is a cyl(), which bakes
					CFrame.Angles(0, 0, rad(90)) into the part so the Roblox
					cylinder (long on its own X) stands up. So the Handle's
					local Y points along world -X, and spinning about it
					tumbled the tool end over end -- which is why it was seen
					lying on its side with the head at the bottom.

					The MODEL is authored upright in world space already: the
					pommel sits at y = -1.8 and the head's eye at y = +1.26.
					Only the pivot's orientation is rotated. So the fix is to
					rotate about world Y through the model's centre and leave
					its orientation alone, rather than to re-orient anything.
				]]
				local cf0 = model:GetPivot()
				local centre = select(1, model:GetBoundingBox()).Position
				local angle = 0
				local spin
				spin = game:GetService("RunService").RenderStepped:Connect(function(dt)
					if not vp.Parent or not model.Parent then
						spin:Disconnect()
						return
					end
					angle += dt * 0.6
					local about = CFrame.new(centre) * CFrame.Angles(0, angle, 0) * CFrame.new(-centre)
					model:PivotTo(about * cf0)
				end)
			end
		end

		local info = mk("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.46, 12, 0, 36),
			Size = UDim2.new(0.54, -12, 1, -44),
		}, recipeView)

		label(info, OreTools.name(r.def, selFamily), 24, TEXT,
			UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 30), FONT)
		label(info, string.format("ore tier %d", r.tier), 12, MUTED,
			UDim2.fromOffset(0, 32), UDim2.new(1, 0, 0, 14))

		--[[
			The three numbers the owner asked for, each on its own line and each
			labelled, rather than packed into a sentence. Breaking power and
			damage come from the same functions the server uses, so the recipe
			cannot promise a tool the forge will not deliver.
		]]
		local stats = OreTools.frameStats(selFamily, r.tier) or {}
		local bp = C.toolBreakingPower and C.toolBreakingPower(r.tier) or 0
		local rate = tonumber(stats.rate) or 0
		local cells = tonumber(stats.cells) or 1
		--[[
			DAMAGE IS toolPower, NOT BREAKING POWER.

			This printed `bp * cells` under a DAMAGE label, which made a Stone
			pick read as "1 damage" -- the same as the free wooden one -- and
			that is not what it does. Breaking power is the GATE: which ore a
			tool is allowed to touch at all, and it is the ore's tier by
			definition, so tier 1 is 1. Damage is C.toolPower, which is
			TOOL_DMG_BASE x toolTierPower(tier) x typeMult x step^(level-1).

			A Stone pick is 10 and the wooden one is 1, so it is ten times the
			starter, not equal to it.

			Shown at the level this tool will ACTUALLY be forged at, not 1: the
			craft verb stamps a new tool with the highest level you already own
			(and bases it there). Quoting level 1 would understate every tool
			after the first by the whole climb.
		]]
		local forgeLevel = 1
		for _, t in ipairs(snapshot.oreTools or {}) do
			if type(t) == "table" then
				forgeLevel = math.max(forgeLevel, math.floor(tonumber(t.level) or 1))
			end
		end
		forgeLevel = math.clamp(forgeLevel, 1, tonumber(C.TOOL_MAX_LEVEL) or 30)
		local typeMult = OreTools.typeMult(selFamily, r.tier)
		local dmg = C.toolPower and C.toolPower(r.tier, forgeLevel, typeMult) or 0

		local function statLine(y, key, value, ink)
			label(info, key, 12, MUTED, UDim2.fromOffset(0, y), UDim2.new(0.42, 0, 0, 16), FONT_M)
			label(info, value, 15, ink or TEXT, UDim2.new(0.42, 0, 0, y - 2),
				UDim2.new(0.58, 0, 0, 18), FONT)
		end

		--[[
			THE COST READS AS A SENTENCE, WITH THE ORE IN IT.

			Owner, 2026-10-08: "can we make the crafting show ore icons, and
			make it more natural looking than 'have 56', and 'Costs 260'".

			Two labelled rows of "COSTS 270 Stone / YOU HAVE 65 Stone" made the
			player do the subtraction, repeated the ore's name twice, and named
			the ore in text when there is already a 512px render of it.

			One row instead: the ore's icon, then "65 / 270", then how much is
			still missing. The icon says WHICH ore, the fraction says where you
			are, and the shortfall says what to go and do -- which is the only
			thing a player actually wants off this screen.
		]]
		local art = OreIcons.BY_ID and OreIcons.BY_ID[r.id]
		if art and art.icon then
			UI.icon(info, art.icon, 34, UDim2.fromOffset(0, 56))
		end
		label(info, string.format("%s / %s", num(r.have), num(r.cost)), 20,
			r.afford and GREEN or TEXT, UDim2.fromOffset(42, 54),
			UDim2.new(1, -42, 0, 24), FONT)
		label(info, r.afford
				and ("enough " .. r.name .. " to forge it")
				or string.format("%s more %s needed", num(r.cost - r.have), r.name),
			12, r.afford and GREEN or MUTED, UDim2.fromOffset(42, 78),
			UDim2.new(1, -42, 0, 14), FONT_M)

		statLine(116, "DAMAGE", string.format("%s per hit%s", num(math.floor(dmg)),
			forgeLevel > 1 and (" at level " .. forgeLevel) or ""), GOLD)
		-- DPS, because that is what it is and what a player already calls it.
		statLine(140, "DPS", num(math.floor(dmg * rate * math.max(1, cells))), GOLD)
		statLine(164, "SWING RATE", string.format("%.1f / sec%s", rate,
			cells > 1 and string.format("  \u{00B7}  %d blocks", cells) or ""), TEXT)
		-- The gate, labelled as one. It is the ore's tier and says which ore
		-- the tool may touch -- not how hard it hits.
		statLine(188, "BREAKS UP TO", string.format("ore tier %d  (power %s)",
			C.oreReachCap and C.oreReachCap(bp) or r.tier, num(bp)), TEXT)

		local owned = ownedForOre(snapshot, selFamily, r.tier)
		button(info, r.afford and "FORGE" or "NEED ORE", GREEN,
			UDim2.fromOffset(0, 224), UDim2.fromOffset(170, 34), r.afford, function()
				if opts.onCraft then
					opts.onCraft(selFamily, "", r.id)
				end
			end)
		if owned then
			label(info, string.format("you already have one, at level %d",
				math.max(1, tonumber(owned.level) or 1)), 12, GOLD,
				UDim2.fromOffset(180, 232), UDim2.new(1, -180, 0, 16))
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
		--[[
			THE RAIL IS NAVIGATION AND FILTERS NOW, NOT MODES.

			Owner, 2026-10-11: the screen's bottom bar is "Crafting, Loadout,
			Upgrades", and tool-type filters go "on the left for Pickaxe, Drill,
			Explosive, Sledgehammer, and Jackhammer".

			CRAFT and UPGRADE are gone from here because they ARE two of those
			three tabs now; the host drives them through setMode. Keeping them
			would have put the same choice in two places, which is how two
			controls end up disagreeing about one piece of state.

			SHOP stays, moved to the top: the owner asked for "the existing Shop
			entry" to go "a sensible place in the navigation", and this rail IS
			the navigation. It is a route rather than a filter -- it opens
			another panel -- so it sits above the TOOL TYPE heading with the
			filters grouped under it, rather than reading as a sixth tool type.
		]]
		if opts.onCoinShop then
			-- A route, not a filter: it never reads as selected because the
			-- panel it opens is not this one.
			colButton("SHOP", 1, false, true, function()
				opts.onCoinShop()
			end)
		end
		--[[
			BACKPACKS NEEDS A DOOR, AND THIS IS IT.

			Backpacks used to be one of the bottom tabs. The owner's new bottom
			bar is Crafting / Loadout / Upgrades, so that button is gone -- and
			`backpack` is still a perfectly good shelf that `setTab` can show,
			which means losing the button loses the only way to reach it. That
			is precisely how the Secrets shelf spent its whole life unreachable.

			It sits beside SHOP because it is the same kind of thing: capacity
			you buy with coins, not a tool you forge and not a filter.
		]]
		if opts.onBackpacks then
			colButton("BACKPACKS", 2, false, true, function()
				opts.onBackpacks()
			end)
		end
		--[[
			MERGE IS A ROUTE, BECAUSE TOOLS DO NOT MERGE.

			The owner asked Upgrades to carry "the available item operations,
			such as merging and scrapping". Scrapping is right here -- the
			UPGRADE pane arms a SCRAP button and quotes the ore and dust back.
			Merging is not, and cannot be: an ore tool is levelled or scrapped,
			and the things that actually merge in this game are CARDS (three
			copies) and CHARMS (MineCharms.mergeTarget). There is no tool-merge
			verb on the server to call.

			So this opens the screen that really does it instead of growing a
			second copy of it here. A button that routes somewhere honest beats
			a button that implies a mechanic the game does not have.
		]]
		if opts.onMerge then
			colButton("MERGE", 3, false, true, function()
				opts.onMerge()
			end)
		end

		label(modeCol, "TOOL TYPE", 10, MUTED, nil, UDim2.new(1, 0, 0, 20), FONT).LayoutOrder = 4
		local order = 4
		for _, famId in ipairs(OreTools.FAMILY_ORDER or {}) do
			local defs = (Tools.TOOLS or {})[famId]
			local has = defs ~= nil and #defs > 0
			order += 1
			local id = famId
			--[[
				ALL FIVE SHOW, INCLUDING THE TWO WITH NOTHING IN THEM.

				This used to skip a family whose roster was empty, so the rail
				read "PICKAXES / DRILLS / EXPLOSIVES" and the owner's other two
				tool types were simply absent from the game's own menu. They are
				not absent by design: MineTools.TOOLS has 25 pickaxe frames, 16
				drill and 16 explosive, and NIL for hammer and jackhammer, while
				MineConfig already carries their craft multipliers (jackhammer
				1.25). The cost maths was written and the rosters never were, so
				the two halves have never met -- a recipe for a sledgehammer
				does not exist anywhere in the game today.

				Hiding that made it look intentional. Showing the filter with a
				(0) and no click says what is actually true: the type exists and
				has no recipes yet. The fix is a roster, which is content the
				owner has to sign off, not a UI change.
			]]
			colButton(string.upper(OreTools.familyNoun(id) .. "s") .. (has and "" or "  (0)"),
				order, has and selFamily == id, has, function()
					selFamily = id
					selUid = nil
					refresh()
				end)
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

		--[[
			CRAFT owns the whole panel; UPGRADE keeps the rail and detail pane.

			Visibility is set here rather than at each click so there is exactly
			one place that decides which of the two layouts is on screen. The
			rail is still FILLED below in craft mode -- it costs nothing while
			hidden and leaving the branch intact keeps upgrade's selection logic
			in one piece -- but nothing in craft reads it any more.
		]]
		local crafting = selMode ~= "upgrade"
		craftPane.Visible = crafting
		rail.Visible = not crafting
		detail.Visible = not crafting
		if crafting then
			local pick
			if selOreId then
				for _, r in ipairs(allRecipes(snapshot, selFamily)) do
					if r.id == selOreId then
						pick = r
						break
					end
				end
				-- A recipe that vanished (family switched under the selection)
				-- drops back to the grid rather than showing an empty stage.
				if not pick then
					selOreId = nil
				end
			end
			grid.Visible = pick == nil
			-- The search box belongs to the CATALOGUE, not to one recipe.
			searchBox.Visible = pick == nil
			recipeView.Visible = pick ~= nil
			if pick then
				searchNote.Visible = false
				drawRecipe(snapshot, pick)
			else
				drawGrid(snapshot)
			end
			return
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
						-- Walking away disarms. Coming back to a tool still
						-- primed to be destroyed is the kind of surprise this
						-- confirmation exists to remove.
						scrapArmed = nil
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
				local cost = C.toolCraftCost(o.tier, OreTools.typeMult(selFamily, o.tier), selFamily)
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
	--[[
		setMode lets the HOST drive craft-vs-upgrade.

		Owner, 2026-10-11: the screen's bottom bar is "Crafting, Loadout,
		Upgrades", so the choice that used to be two buttons on this rail is now
		two of the three tabs. `selMode` is a local in this closure, so without
		a setter the bottom bar could only fake it by clicking a button it does
		not own.

		Entering CRAFT clears selOreId for the same reason the rail's own CRAFT
		button does: the catalogue is what a player is coming back for, not the
		one recipe they opened several tabs ago.
	]]
	local function setMode(mode)
		local want = (mode == "upgrade") and "upgrade" or "craft"
		if selMode == want then
			return
		end
		selMode = want
		if want == "craft" then
			selOreId = nil
		end
		refresh()
	end
	return { refresh = refresh, root = root, setMode = setMode, getMode = function() return selMode end }
end

return MineForge
