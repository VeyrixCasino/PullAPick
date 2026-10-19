--[[
	MineForgeHub -- THE FORGE: one hub for crafting, your loadout and upgrades.

	Owner, 2026-10-11: "I FUCKING LOVE FORGE A.. WIDE SCREEN, NOT ENOUGH ROOM,
	AND TOO BIG BUTTONSA THO", "STICK WITH PROMPT A'S DESGIN", and the features
	of the long inventory brief (wiki systems/enchants, code/client-and-ui):

	  CRAFTING  every real recipe (each ore x each tool class), craftable first
	            and best first, then the rest by rarity; search, rarity /
	            class / craftable filters, sort by rarity, cost or name, reset,
	            active-filter count, empty states. A class rail on the left
	            (All, Pickaxes, Sledgehammers, Drills, Jackhammers, Explosives).
	            A detail panel: the tool turning in 3D, its rarity, class,
	            damage, the ore it costs (held / needed), and CRAFT.
	  LOADOUT   every tool you own: sort and filter; inspect one (3D, rarity,
	            class, level, damage, skin, its three enchant slots); EQUIP /
	            UNEQUIP, change SKIN, jump to LEVEL UP or ENCHANT with the tool
	            kept selected.
	  UPGRADES  pick a tool, then an operation: LEVEL (before -> after damage,
	            the cost, +1 / +10), ENCHANT (the three slots, a book picker
	            with the effect now and with that book, apply / replace /
	            remove), SCRAP (what you get back, asks twice). And BOOKS: your
	            enchant books, merge three into one a level up.

	THE DESIGN is Forge A (MineForgeDemo "molten"): dark stone and iron, a lava
	glow along the floor, rising embers, light rays behind the tool. Wider than
	the demo (it uses most of the screen) and with smaller buttons, as asked.

	EVERYTHING IS REAL. The live verbs (craftOreTool, upgradeOreTool,
	equipOreTool, recycleOreTool, equipSkin, enchApply, enchRemove, enchMerge),
	the live prices (MineConfig), the live enchant rules (MineEnchants), read
	off the snapshot. Every action button locks until the next snapshot (or 2
	seconds), so a double tap never sends twice. Destructive ones ask twice.

	The root is named "ForgeHub" and lives in the main HUD ScreenGui, so
	MineClient's HUD hiders treat it like the Blacksmith: the right-hand dock
	and the wallet hide while it is open (owner: "AS PER USUAL").

	mount(gui, opts) -> { open(tab, uid), close(), isOpen(), refresh(), root }
	  opts.getSnap()  the latest snapshot
	  opts.send(verb, payload)
	  opts.isStudio   shows a Studio-only "test books" button
]]
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared:WaitForChild("MineConfig"))
local OreTools = require(shared:WaitForChild("MineOreTools"))
local OreIcons = require(shared:WaitForChild("MineOreIcons"))
local Cards = require(shared:WaitForChild("MineCards"))
local E = require(shared:WaitForChild("MineEnchants"))

local function optional(name, parent)
	local ok, mod = pcall(function()
		return require((parent or shared):WaitForChild(name, 8))
	end)
	return ok and mod or nil
end
local Factory = optional("ToolModelFactory", RS)
local Celebrate = optional("MineCelebrate")
local Skins = optional("MineSkins")
-- Which skin a tool wears, by the server's own rule (MineToolSkins.skinFor).
local ToolSkins = optional("MineToolSkins")

local Hub = {}

-- ------------------------------------------------------------- theme --
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local TH = {
	bg = { rgb(34, 20, 14), rgb(14, 8, 6) },
	floorGlow = rgb(255, 96, 20),
	panel = rgb(38, 32, 30),
	panel2 = rgb(56, 46, 42),
	edge = rgb(255, 128, 40),
	outline = rgb(12, 6, 4),
	text = rgb(255, 244, 230),
	muted = rgb(214, 170, 140),
	faint = rgb(150, 120, 100),
	titleGrad = { rgb(255, 238, 140), rgb(255, 120, 20) },
	action = { rgb(255, 196, 70), rgb(230, 70, 20) },
	good = { rgb(140, 245, 110), rgb(40, 170, 80) },
	danger = { rgb(255, 120, 120), rgb(200, 40, 60) },
	cool = { rgb(140, 200, 255), rgb(60, 110, 230) },
	magic = { rgb(210, 150, 255), rgb(130, 60, 220) },
	off = { rgb(90, 80, 76), rgb(60, 52, 50) },
	tabOn = { rgb(255, 170, 60), rgb(220, 70, 20) },
	tabOff = rgb(60, 50, 46),
	chip = rgb(24, 18, 16),
	ok = rgb(140, 255, 150),
	bad = rgb(255, 150, 150),
	anvil = rgb(46, 44, 50),
	pedestal = rgb(70, 30, 18),
}
local FONT = Enum.Font.FredokaOne
local FONT_B = Enum.Font.GothamBold

local FAMILY_ICON = { pickaxe = "⛏", hammer = "🔨", drill = "🌀", jackhammer = "⚙", explosive = "💣" }
local FAMILY_NAME = E.FAMILY_NAME
local FAMILIES = OreTools.FAMILY_ORDER or E.FAMILIES
local BANDS = C.ORE_BAND_ORDER or { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic" }
local BAND_RANK = {}
for i, b in ipairs(BANDS) do
	BAND_RANK[b] = i
end

-- ----------------------------------------------------------- helpers --
local function mk(class, props, parent)
	local i = Instance.new(class)
	if i:IsA("GuiObject") then
		i.BorderSizePixel = 0
	end
	for k, v in pairs(props or {}) do
		i[k] = v
	end
	if parent then
		i.Parent = parent
	end
	return i
end

local function round(o, r)
	mk("UICorner", { CornerRadius = UDim.new(0, r or 10) }, o)
	return o
end

local function stroke(o, color, th, transparency)
	return mk("UIStroke", { Color = color, Thickness = th or 2, Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end

local function grad(o, a, b, rot)
	return mk("UIGradient", { Color = ColorSequence.new(a, b), Rotation = rot or 90 }, o)
end

local function text(parent, str, size, color, props)
	local l = mk("TextLabel", {
		BackgroundTransparency = 1, Text = str or "", TextSize = size or 16, TextColor3 = color or TH.text,
		Font = FONT, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center,
	}, parent)
	for k, v in pairs(props or {}) do
		l[k] = v
	end
	return l
end

local function ink(label, th)
	mk("UIStroke", { Color = TH.outline, Thickness = th or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, label)
	return label
end

local function juice(btn)
	local sc = mk("UIScale", {}, btn)
	local function to(v, t)
		TweenService:Create(sc, TweenInfo.new(t or 0.1, Enum.EasingStyle.Back), { Scale = v }):Play()
	end
	btn.MouseEnter:Connect(function()
		to(1.04)
	end)
	btn.MouseLeave:Connect(function()
		to(1)
	end)
	btn.MouseButton1Down:Connect(function()
		to(0.94, 0.05)
	end)
	btn.MouseButton1Up:Connect(function()
		to(1.04)
	end)
	return sc
end

-- A pill button. The gradient lives on a Fill under the label (a UIGradient
-- on a TextButton would tint its text too).
local function pill(parent, label, colors, size, textSize, z)
	z = z or 80
	local btn = mk("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = size, ZIndex = z }, parent)
	local fill = mk("Frame", { Name = "Fill", BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1), ZIndex = z, ClipsDescendants = true }, btn)
	round(fill, 12)
	local g = grad(fill, colors[1], colors[2], 90)
	stroke(fill, TH.outline, 2)
	local shine = mk("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85, Position = UDim2.fromOffset(4, 3),
		Size = UDim2.new(1, -8, 0.42, 0), ZIndex = z }, fill)
	round(shine, 8)
	local l = text(btn, label, textSize or 18, Color3.new(1, 1, 1), { ZIndex = z + 1 })
	ink(l, 1.5)
	juice(btn)
	return btn, l, g, fill
end

local function short(n)
	n = tonumber(n) or 0
	for _, u in ipairs({ { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
		if n >= u[1] then
			local v = n / u[1]
			return (v >= 100 and tostring(math.floor(v)) or (string.format("%.1f", v):gsub("%.0$", ""))) .. u[2]
		end
	end
	return tostring(math.floor(n))
end

local function rarityOf(tier)
	local band = (C.oreBandForTier and C.oreBandForTier(tier)) or "Common"
	return band, (Cards.RARITY_COLOR and Cards.RARITY_COLOR[band]) or rgb(200, 200, 200)
end

local ORE_BY_TIER = {}
for _, def in ipairs(C.ORES or {}) do
	ORE_BY_TIER[def.tier] = ORE_BY_TIER[def.tier] or def
end

local function toolName(fam, def)
	local ok, name = pcall(OreTools.name, def, fam)
	return (ok and type(name) == "string" and name ~= "") and name or ((def and def.name or "?") .. " " .. (FAMILY_NAME[fam] or fam))
end

local function ownedName(tool)
	local okN, nm = false, nil
	if OreTools.toolName then
		okN, nm = pcall(OreTools.toolName, tool)
	end
	if okN and type(nm) == "string" and nm ~= "" then
		return nm
	end
	return toolName(tool.familyId or "pickaxe", ORE_BY_TIER[tonumber(tool.tier) or 1])
end

--[[
	THE SKIN A FAMILY IS WEARING, and its damage multiplier. A skin is worn per
	tool family and dresses every tool of it, so a new craft wears it too.
]]
local function wornSkin(snap, fam)
	if not ToolSkins then
		return nil, 1
	end
	local worn = ToolSkins.skinFor(snap and snap.skinEquipped, fam)
	return worn, ToolSkins.mult(worn)
end

-- "stats only" when this family has no skin form for the skin's set yet: the
-- skin changes the tool's numbers, not its look (owner: say so honestly).
local function looksLabel(fam, skin)
	if not skin then
		return ""
	end
	local looks = Factory and Factory.hasSkinForm and Factory.hasSkinForm(fam, skin.set)
	return looks and "" or ("  ·  " .. ((ToolSkins and ToolSkins.STATS_ONLY) or "stats only"))
end

--[[
	WHAT A CARD SAYS A TOOL DOES (launch audit S11). MineOreTools.cardStats is
	the server's own swing maths -- hitPower (ore, level, family, the worn skin,
	the finish) and the frame -- so the number on a card is the number the hand
	lands. `row` is a forged row, or a recipe shaped like one.
]]
local function cardOf(snap, row)
	-- "pickaxe" for a row with no family: the server's equippedTool reads it so.
	local _, mult = wornSkin(snap, row.familyId or "pickaxe")
	return OreTools.cardStats(row, mult)
end

local function perSecText(n)
	n = tonumber(n) or 0
	return (n >= 10 and tostring(math.floor(n + 0.5)) or (string.format("%.1f", n):gsub("%.0$", ""))) .. " hits/s"
end

-- ------------------------------------------------------------ data --
-- Every real recipe (each discovered ore x each class), as the live Forge reads them.
local function allRecipes(snap)
	local held, seen = snap.ores or {}, snap.oresSeen
	local out = {}
	for _, fam in ipairs(FAMILIES) do
		for _, def in ipairs(C.ORES or {}) do
			local have = tonumber(held[def.id]) or 0
			local discovered = (type(seen) == "table") and (seen[def.id] and true or false) or have > 0
			-- The craft verb charges exactly this (MineOreTools.craftCost; S9).
			local cost = OreTools.craftCost(fam, def.tier)
			local band = rarityOf(def.tier)
			table.insert(out, {
				key = fam .. ":" .. def.id, fam = fam, id = def.id, def = def, tier = def.tier, name = toolName(fam, def),
				oreName = def.name, have = have, cost = cost, locked = not discovered, afford = discovered and have >= cost,
				band = band, rank = BAND_RANK[band] or 1,
			})
		end
	end
	return out
end

local function ownedTools(snap)
	local out = {}
	for _, t in ipairs(snap.oreTools or {}) do
		if type(t) == "table" and t.uid then
			local fam = t.familyId or "pickaxe"
			local tier = tonumber(t.tier) or 1
			local band = rarityOf(tier)
			table.insert(out, { tool = t, uid = t.uid, fam = fam, tier = tier, level = tonumber(t.level) or 1, band = band,
				rank = BAND_RANK[band] or 1, name = ownedName(t), equipped = snap.oreToolEquipped == t.uid,
				def = ORE_BY_TIER[tier] })
		end
	end
	return out
end

-- =============================================================== mount ==
function Hub.mount(gui, opts)
	opts = opts or {}
	local send = opts.send or function() end
	local getSnap = opts.getSnap or function()
		return nil
	end
	local ctl = {}
	local state = {
		tab = "craft",
		-- crafting
		cFam = "all", cSearch = "", cRarity = nil, cCraftable = false, cSort = "rarity", cShow = 60, cSel = nil,
		-- loadout
		lFam = "all", lEquipped = false, lSort = "rarity", lSel = nil,
		-- upgrades
		uSel = nil, uOp = "level", uSlot = nil, uConfirm = nil,
	}
	local busyUntil = 0
	local function act(verb, payload)
		if os.clock() < busyUntil then
			return false
		end
		busyUntil = os.clock() + 2
		send(verb, payload)
		return true
	end

	-- --------------------------------------------------------- the frame --
	local root = mk("Frame", {
		Name = "ForgeHub", Visible = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1500, 820), BackgroundColor3 = Color3.new(1, 1, 1), ClipsDescendants = true, ZIndex = 70,
	}, gui)
	root:SetAttribute("MineUIAdopted", true)
	round(root, 22)
	grad(root, TH.bg[1], TH.bg[2], 90)
	stroke(root, TH.edge, 3)
	local scale = mk("UIScale", {}, root)
	local function fit()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		-- Wide: most of the screen, whatever its shape (owner: "WIDE SCREEN").
		scale.Scale = math.clamp(math.min(vp.X * 0.96 / 1500, vp.Y * 0.92 / 820), 0.4, 1.3)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
	local floor = mk("Frame", { BackgroundColor3 = TH.floorGlow, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 240), ZIndex = 70 }, root)
	mk("UIGradient", { Rotation = 270, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) }) }, floor)
	local fxLayer = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 71 }, root)
	local motes = {}
	for i = 1, 40 do
		local m = mk("Frame", { BackgroundColor3 = rgb(255, 140 + math.random(0, 80), 40), AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(math.random(2, 6), math.random(2, 6)), Position = UDim2.fromScale(math.random(), math.random()), ZIndex = 71 }, fxLayer)
		round(m, 3)
		motes[i] = { f = m, x = math.random(), y = math.random(), v = 0.02 + math.random() * 0.06, ph = math.random() * 6 }
	end

	-- --------------------------------------------------------- header --
	local title = text(root, "🔨 FORGE", 44, Color3.new(1, 1, 1), { Position = UDim2.fromOffset(24, 8), Size = UDim2.fromOffset(250, 56),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 74 })
	grad(title, TH.titleGrad[1], TH.titleGrad[2], 90)
	ink(title, 3)
	-- The player level and its XP bar.
	local lvBox = mk("Frame", { BackgroundColor3 = TH.chip, Position = UDim2.fromOffset(270, 16), Size = UDim2.fromOffset(250, 40), ZIndex = 74 }, root)
	round(lvBox, 20)
	stroke(lvBox, TH.edge, 2)
	local lvL = text(lvBox, "LV 1", 20, TH.text, { Position = UDim2.fromOffset(10, 0), Size = UDim2.fromOffset(64, 40), ZIndex = 75 })
	ink(lvL)
	local xpTrack = mk("Frame", { BackgroundColor3 = rgb(40, 30, 26), Position = UDim2.fromOffset(78, 12), Size = UDim2.fromOffset(160, 16), ZIndex = 75 }, lvBox)
	round(xpTrack, 8)
	local xpFill = mk("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(0, 1), ZIndex = 76 }, xpTrack)
	round(xpFill, 8)
	grad(xpFill, rgb(255, 230, 120), rgb(255, 140, 30), 0)
	local xpL = text(xpTrack, "", 12, TH.text, { ZIndex = 77, Font = FONT_B })
	ink(xpL, 1)

	local chips = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(560, 16), Size = UDim2.fromOffset(860, 40), ZIndex = 74 }, root)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, chips)
	local function chip(order, icon)
		local c = mk("Frame", { BackgroundColor3 = TH.chip, Size = UDim2.fromOffset(140, 40), LayoutOrder = order, ZIndex = 74 }, chips)
		round(c, 20)
		stroke(c, TH.edge, 2)
		text(c, icon, 20, Color3.new(1, 1, 1), { Position = UDim2.fromOffset(6, 0), Size = UDim2.fromOffset(32, 40), ZIndex = 75 })
		local v = text(c, "0", 19, TH.text, { Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -46, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 75 })
		ink(v)
		return v
	end
	local coinsV, gemsV, dustV = chip(2, "💰"), chip(3, "💎"), chip(4, "✨")
	--[[
		ONE FORGE (launch audit S13; owner, 2026-10-19). The old shop now shows
		only Bags, the one shelf the Forge has no tab for, and its Crafting /
		Loadout / Upgrades tabs open this hub. The COIN SHOP button is gone: it
		opened a pickaxe shelf where every BUY is refused (tools are forged).
	]]
	if opts.onShop then
		local bagsBtn = pill(chips, "🎒 BAGS", TH.cool, UDim2.fromOffset(120, 40), 16, 75)
		bagsBtn.LayoutOrder = -1
		bagsBtn.MouseButton1Click:Connect(function()
			ctl.close()
			opts.onShop("backpack")
		end)
		--[[
			EXCEPT IN EVENT HORIZON. Standing in the event, the old shop's tool
			shelf is the Event Horizon tool shelf (space coins; MineShopView rows
			reads zoneId), and the Supply Pod opens this hub -- so COIN SHOP was
			the one door to the event's tools. That door stays, named for what it
			sells, and only while you are in the event (paintChrome).
		]]
		local eventBtn = pill(chips, "🚀 EVENT TOOLS", TH.magic, UDim2.fromOffset(170, 40), 16, 75)
		eventBtn.LayoutOrder = 0
		eventBtn.Visible = false
		ctl._eventToolsBtn = eventBtn
		eventBtn.MouseButton1Click:Connect(function()
			ctl.close()
			opts.onShop("pickaxe")
		end)
	end
	local studioBtn
	if opts.isStudio then
		studioBtn = pill(chips, "🧪 TEST BOOKS", TH.magic, UDim2.fromOffset(150, 40), 15, 75)
		studioBtn.LayoutOrder = 1
		studioBtn.MouseButton1Click:Connect(function()
			act("enchDebugGrant", {})
		end)
	end
	local closeBtn = mk("TextButton", { Text = "X", Font = FONT, TextSize = 24, TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = rgb(230, 60, 80), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 14),
		Size = UDim2.fromOffset(44, 44), ZIndex = 76, AutoButtonColor = false }, root)
	round(closeBtn, 22)
	stroke(closeBtn, TH.outline, 2)
	juice(closeBtn)

	-- The three tabs, centred.
	local tabs = {}
	local tabRow = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 68),
		Size = UDim2.fromOffset(600, 42), ZIndex = 74 }, root)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, tabRow)
	for i, t in ipairs({ { "craft", "🔥 CRAFTING" }, { "loadout", "🎒 LOADOUT" }, { "upgrades", "⬆ UPGRADES" } }) do
		local b, _, g = pill(tabRow, t[2], { TH.tabOff, TH.tabOff }, UDim2.fromOffset(190, 42), 19, 75)
		b.LayoutOrder = i
		tabs[t[1]] = { btn = b, grad = g }
	end

	-- The body, and one page per tab.
	local body = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 120), Size = UDim2.new(1, -32, 1, -136), ZIndex = 72 }, root)
	local pages = {}
	for _, id in ipairs({ "craft", "loadout", "upgrades" }) do
		pages[id] = mk("Frame", { Name = "Page_" .. id, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 72 }, body)
	end

	local function panel(parent, pos, size)
		local f = mk("Frame", { BackgroundColor3 = TH.panel, BackgroundTransparency = 0.2, Position = pos, Size = size, ZIndex = 72 }, parent)
		round(f, 18)
		stroke(f, TH.edge, 2, 0.4)
		return f
	end

	local function clearKids(f)
		for _, c in ipairs(f:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
	end

	local function scroller(parent, pos, size, cell, pad)
		local sf = mk("ScrollingFrame", { BackgroundTransparency = 1, Position = pos, Size = size, CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 8, ScrollBarImageColor3 = TH.edge,
			ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 73 }, parent)
		if cell then
			mk("UIGridLayout", { CellSize = cell, CellPadding = pad or UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
		else
			mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
		end
		mk("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10) }, sf)
		return sf
	end

	-- A 3D stage: rays, rings, a pedestal and anvil, the tool turning above it.
	local stages = {}
	local function makeStage(parent, pos, size)
		local st = mk("Frame", { BackgroundTransparency = 1, Position = pos, Size = size, ZIndex = 73 }, parent)
		local cx, cy = size.X.Offset * 0.5, size.Y.Offset * 0.46
		local rays = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy),
			Size = UDim2.fromOffset(10, 10), ZIndex = 73 }, st)
		for i = 1, 8 do
			local ray = mk("Frame", { BackgroundColor3 = TH.edge, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(22, size.Y.Offset * 1.1), Rotation = i * 22.5, ZIndex = 73 }, rays)
			mk("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.74), NumberSequenceKeypoint.new(1, 1) }) }, ray)
		end
		local halo = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy),
			Size = UDim2.fromOffset(size.Y.Offset * 0.8, size.Y.Offset * 0.8), ZIndex = 73 }, st)
		for i, ring in ipairs({ { 1, 0.86 }, { 0.78, 0.76 }, { 0.56, 0.64 }, { 0.34, 0.5 } }) do
			local c = mk("Frame", { BackgroundColor3 = TH.floorGlow:Lerp(Color3.new(1, 1, 1), (i - 1) * 0.12), BackgroundTransparency = ring[2],
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(ring[1], ring[1]), ZIndex = 73 }, halo)
			round(c, 999)
		end
		local ped = mk("Frame", { BackgroundColor3 = TH.pedestal, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(cx, size.Y.Offset * 0.82),
			Size = UDim2.fromOffset(size.X.Offset * 0.55, 16), ZIndex = 74 }, st)
		round(ped, 8)
		stroke(ped, TH.outline, 2)
		local anv = mk("Frame", { BackgroundColor3 = TH.anvil, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(cx, size.Y.Offset * 0.82 + 2),
			Size = UDim2.fromOffset(size.X.Offset * 0.42, 20), ZIndex = 75 }, st)
		round(anv, 6)
		stroke(anv, TH.outline, 2)
		local vp = mk("ViewportFrame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy),
			Size = UDim2.fromOffset(size.X.Offset * 0.9, size.Y.Offset * 0.86), ZIndex = 76, LightColor = Color3.new(1, 1, 1),
			Ambient = rgb(170, 160, 150) }, st)
		local s = { frame = st, rays = rays, halo = halo, vp = vp, haloBase = size.Y.Offset * 0.8 }
		-- Forget stages that were rebuilt away, so the motion loop stays small.
		local live = {}
		for _, old in ipairs(stages) do
			if old.frame.Parent then
				table.insert(live, old)
			end
		end
		stages = live
		table.insert(stages, s)
		local spin
		-- A rebuilt page destroys its stage: stop that stage's spin with it.
		st.Destroying:Connect(function()
			if spin then
				spin:Disconnect()
				spin = nil
			end
		end)
		function s.show(fam, tier, def, skin)
			if spin then
				spin:Disconnect()
				spin = nil
			end
			vp:ClearAllChildren()
			if not (Factory and Factory.build and def and fam) then
				return
			end
			local ok, model = pcall(function()
				local look = Factory.oreLook and Factory.oreLook(def, C.ORE_COUNT or #C.ORES)
				-- A tool you own wears its family's skin here the way it does in
				-- your hand (buildSkinned is nil for a family with no form yet).
				if skin and Factory.buildSkinned then
					local skinned = Factory.buildSkinned(fam, skin, look)
					if skinned then
						return skinned
					end
				end
				return Factory.build(fam, tier, C.ORE_COUNT or #C.ORES, look)
			end)
			if not (ok and model) then
				return
			end
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
			local cf, sz = model:GetBoundingBox()
			local dist = math.max(sz.Magnitude * 0.8, 2.5)
			cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(dist * 0.55, dist * 0.3, dist * 0.8), cf.Position)
			local cf0, centre, angle, t = model:GetPivot(), cf.Position, 0, 0
			spin = RunService.RenderStepped:Connect(function(dt)
				if not root.Visible or not model.Parent then
					return
				end
				angle += dt * 0.9
				t += dt
				local about = CFrame.new(centre + Vector3.new(0, math.sin(t * 2) * 0.1, 0)) * CFrame.Angles(0, angle, 0) * CFrame.new(-centre)
				model:PivotTo(about * cf0)
			end)
		end
		return s
	end

	-- A tool / recipe card.
	local function toolCard(parent, o)
		local b = mk("TextButton", { Text = "", BackgroundColor3 = o.locked and rgb(40, 38, 44) or TH.panel2, LayoutOrder = o.order or 0,
			ZIndex = 74, AutoButtonColor = false }, parent)
		round(b, 12)
		stroke(b, o.locked and rgb(80, 78, 86) or (o.ready and TH.ok or o.col), o.selected and 4 or 2)
		if not o.locked then
			grad(b, TH.panel2:Lerp(o.col, 0.3), TH.panel2, 90)
			local nug = mk("Frame", { BackgroundColor3 = o.oreColor or o.col, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0, 40), Size = UDim2.fromOffset(36, 36), Rotation = 45, ZIndex = 75 }, b)
			round(nug, 8)
			stroke(nug, TH.outline, 2)
			mk("UIGradient", { Rotation = 45, Color = ColorSequence.new(Color3.new(1, 1, 1), rgb(110, 110, 110)) }, nug)
			if o.icon then
				mk("ImageLabel", { BackgroundTransparency = 1, Image = o.icon, AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0, 40), Size = UDim2.fromOffset(52, 52), ZIndex = 76 }, b)
			end
			text(b, FAMILY_ICON[o.fam] or "⛏", 15, Color3.new(1, 1, 1), { Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(22, 22), ZIndex = 77 })
		else
			text(b, "❓", 34, Color3.new(1, 1, 1), { Position = UDim2.new(0, 0, 0, 16), Size = UDim2.new(1, 0, 0, 48), ZIndex = 75 })
		end
		local n = text(b, o.locked and "???" or o.name, 14, TH.text, { Position = UDim2.fromOffset(4, 72), Size = UDim2.new(1, -8, 0, 32),
			TextWrapped = true, TextScaled = true, ZIndex = 76 })
		ink(n, 1)
		if not o.locked then
			text(b, string.upper(o.band or ""), 11, o.col, { Position = UDim2.fromOffset(0, 104), Size = UDim2.new(1, 0, 0, 14), Font = FONT_B, ZIndex = 76 })
		end
		local foot = text(b, o.foot or "", 13, o.footColor or TH.muted, { Position = UDim2.fromOffset(4, 120), Size = UDim2.new(1, -8, 0, 16),
			TextScaled = true, Font = FONT_B, ZIndex = 76 })
		ink(foot, 1)
		-- Never colour alone (brief): a ready card also says so.
		if o.ready then
			local tag = mk("Frame", { BackgroundColor3 = rgb(60, 200, 90), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 4),
				Size = UDim2.fromOffset(54, 18), ZIndex = 78 }, b)
			round(tag, 9)
			stroke(tag, TH.outline, 1.5)
			text(tag, "CRAFT", 11, Color3.new(1, 1, 1), { Font = FONT_B, ZIndex = 79 })
		end
		if o.badge then
			local tag = mk("Frame", { BackgroundColor3 = o.badgeColor or TH.edge, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 4),
				Size = UDim2.fromOffset(o.badgeW or 54, 18), ZIndex = 78 }, b)
			round(tag, 9)
			stroke(tag, TH.outline, 1.5)
			text(tag, o.badge, 11, Color3.new(1, 1, 1), { Font = FONT_B, ZIndex = 79 })
		end
		if o.dots then
			for i, on in ipairs(o.dots) do
				local d = mk("Frame", { BackgroundColor3 = on and E.SLOTS[i].color or rgb(60, 54, 52), Position = UDim2.fromOffset(6 + (i - 1) * 14, 138),
					Size = UDim2.fromOffset(10, 10), ZIndex = 77 }, b)
				round(d, 5)
				stroke(d, TH.outline, 1)
			end
		end
		juice(b)
		b.MouseButton1Click:Connect(o.onClick)
		return b
	end

	-- A small toggle chip for filter rows.
	local function chipBtn(parent, label, on, onClick, width, color)
		local b, l = pill(parent, label, on and (color or TH.tabOn) or TH.off, UDim2.fromOffset(width or 80, 30), 13, 76)
		b.MouseButton1Click:Connect(onClick)
		return b, l
	end

	-- ========================================================== CRAFTING ==
	local cp = pages.craft
	local cRail = panel(cp, UDim2.fromOffset(0, 0), UDim2.new(0, 170, 1, 0))
	mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, cRail)
	mk("UIPadding", { PaddingTop = UDim.new(0, 10) }, cRail)
	local cMid = panel(cp, UDim2.fromOffset(180, 0), UDim2.new(1, -620, 1, 0))
	local cDetail = panel(cp, UDim2.new(1, -430, 0, 0), UDim2.new(0, 430, 1, 0))
	-- toolbar
	local search = mk("TextBox", { BackgroundColor3 = TH.chip, PlaceholderText = "🔍 Search", PlaceholderColor3 = TH.faint, Text = "",
		TextColor3 = TH.text, Font = FONT_B, TextSize = 16, Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(220, 32),
		ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 75 }, cMid)
	round(search, 10)
	stroke(search, TH.edge, 2, 0.3)
	mk("UIPadding", { PaddingLeft = UDim.new(0, 10) }, search)
	local cBar = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(242, 10), Size = UDim2.new(1, -254, 0, 32), ZIndex = 75 }, cMid)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center }, cBar)
	local cRarityRow = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -24, 0, 30), ZIndex = 75 }, cMid)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, cRarityRow)
	local cInfo = text(cMid, "", 14, TH.muted, { Position = UDim2.fromOffset(14, 82), Size = UDim2.new(1, -28, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left, Font = FONT_B, ZIndex = 75 })
	local cGrid = scroller(cMid, UDim2.fromOffset(8, 104), UDim2.new(1, -16, 1, -112), UDim2.fromOffset(134, 156), UDim2.fromOffset(8, 8))
	local cStage = makeStage(cDetail, UDim2.fromOffset(10, 6), UDim2.fromOffset(410, 300))
	local cName = text(cDetail, "", 26, TH.text, { Position = UDim2.fromOffset(10, 304), Size = UDim2.new(1, -20, 0, 32), TextScaled = true, ZIndex = 76 })
	ink(cName, 2)
	local cBadge = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 340), Size = UDim2.fromOffset(220, 26), ZIndex = 76 }, cDetail)
	round(cBadge, 13)
	stroke(cBadge, TH.outline, 2)
	local cBadgeL = text(cBadge, "", 15, Color3.new(1, 1, 1), { Font = FONT_B, ZIndex = 77 })
	ink(cBadgeL, 1)
	-- Two lines: what one hit does and how often, then the area and how it is used.
	local cStats = text(cDetail, "", 17, TH.muted, { Position = UDim2.fromOffset(10, 372), Size = UDim2.new(1, -20, 0, 46),
		TextWrapped = true, ZIndex = 76 })
	local cReq = mk("Frame", { BackgroundColor3 = TH.chip, Position = UDim2.fromOffset(20, 424), Size = UDim2.new(1, -40, 0, 70), ZIndex = 76 }, cDetail)
	round(cReq, 12)
	stroke(cReq, TH.edge, 1.5, 0.4)
	local cReqIcon = mk("Frame", { BackgroundColor3 = TH.edge, Position = UDim2.fromOffset(16, 17), Size = UDim2.fromOffset(36, 36), Rotation = 45, ZIndex = 77 }, cReq)
	round(cReqIcon, 8)
	stroke(cReqIcon, TH.outline, 2)
	local cReqL = text(cReq, "", 17, TH.text, { Position = UDim2.fromOffset(66, 8), Size = UDim2.new(1, -76, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 77 })
	ink(cReqL, 1)
	local cReqTrack = mk("Frame", { BackgroundColor3 = rgb(40, 30, 26), Position = UDim2.fromOffset(66, 40), Size = UDim2.new(1, -82, 0, 14), ZIndex = 77 }, cReq)
	round(cReqTrack, 7)
	local cReqFill = mk("Frame", { BackgroundColor3 = TH.ok, Size = UDim2.fromScale(0, 1), ZIndex = 78 }, cReqTrack)
	round(cReqFill, 7)
	local cAction = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 508), Size = UDim2.new(1, -40, 0, 48), ZIndex = 76 }, cDetail)
	local cHint = text(cDetail, "", 14, TH.muted, { Position = UDim2.fromOffset(20, 562), Size = UDim2.new(1, -40, 0, 40), TextWrapped = true,
		Font = FONT_B, ZIndex = 76 })

	local cRailBtns = {}
	for i, f in ipairs({ "all", table.unpack(FAMILIES) }) do
		local label = (f == "all") and "📚 All" or ((FAMILY_ICON[f] or "") .. " " .. (FAMILY_NAME[f] or f))
		local b, l, g = pill(cRail, label, TH.off, UDim2.fromOffset(150, 46), 15, 76)
		b.LayoutOrder = i
		cRailBtns[f] = { btn = b, grad = g }
		b.MouseButton1Click:Connect(function()
			state.cFam = f
			state.cShow = 60
			ctl.paintCraft(true)
		end)
	end

	local searchDebounce = 0
	search:GetPropertyChangedSignal("Text"):Connect(function()
		searchDebounce += 1
		local mine = searchDebounce
		task.delay(0.15, function()
			if mine == searchDebounce then
				state.cSearch = string.lower(search.Text or "")
				state.cShow = 60
				ctl.paintCraft(true)
			end
		end)
	end)

	local function paintCraftDetail()
		clearKids(cAction)
		local r = state.cSel
		if not r then
			cStage.show(nil)
			cName.Text, cBadgeL.Text, cStats.Text, cReqL.Text, cHint.Text = "", "", "", "", "Pick a recipe"
			cBadge.Visible, cReq.Visible = false, false
			return
		end
		cBadge.Visible, cReq.Visible = true, true
		if r.locked then
			cStage.show(nil)
			cName.Text = "???"
			cBadgeL.Text = "LOCKED"
			cBadge.BackgroundColor3 = rgb(70, 70, 80)
			cStats.Text = FAMILY_NAME[r.fam] or r.fam
			cReqL.Text = "Find this ore to unlock it"
			cReqFill.Size = UDim2.fromScale(0, 1)
			cReqIcon.BackgroundColor3 = rgb(70, 70, 80)
			cHint.Text = ""
			return
		end
		local _, col = rarityOf(r.tier)
		cStage.show(r.fam, r.tier, r.def)
		cName.Text = r.name
		cBadgeL.Text = string.upper(r.band) .. "  ·  " .. string.upper(FAMILY_NAME[r.fam] or r.fam)
		cBadge.BackgroundColor3 = col
		--[[
			THE TRUTH ABOUT THE TOOL YOU ARE ABOUT TO MAKE (launch audit S11).
			It arrives at your best level (the craft verb inherits it through the
			same MineOreTools.inheritedLevel) and wears its family's skin, so the
			hit is the one it will land the moment it is forged.
		]]
		local snapC = getSnap() or {}
		local lvNew = OreTools.inheritedLevel(snapC.oreTools)
		local card = cardOf(snapC, { familyId = r.fam, tier = r.tier, level = lvNew })
		local worn = wornSkin(snapC, r.fam)
		cStats.Text = string.format("⚔ %s per hit  ·  %s  ·  starts Lv %d\n🧱 %s  ·  ✋ %s%s",
			short(card.hit), perSecText(card.perSec), lvNew, card.area, card.use,
			worn and ("  ·  🎨 " .. ToolSkins.multText(worn)) or "")
		cReqIcon.BackgroundColor3 = r.def.color or col
		cReqL.Text = string.format("%s / %s  %s", short(r.have), short(r.cost), r.oreName)
		cReqL.TextColor3 = r.afford and TH.ok or TH.bad
		cReqFill.Size = UDim2.fromScale(math.clamp(r.have / math.max(1, r.cost), 0, 1), 1)
		cReqFill.BackgroundColor3 = r.afford and TH.ok or TH.edge
		local frame = OreTools.frameForTier and OreTools.frameForTier(r.fam, r.tier)
		local b = pill(cAction, r.afford and "🔥 CRAFT" or ("NEED " .. short(r.cost - r.have) .. " MORE"), r.afford and TH.action or TH.off,
			UDim2.new(1, 0, 1, 0), 22, 78)
		cHint.Text = r.afford and "" or ("Mine more " .. r.oreName)
		if r.afford then
			b.MouseButton1Click:Connect(function()
				if act("craftOreTool", { familyId = r.fam, typeId = frame and frame.id or "", oreId = r.id }) then
					ctl._pendingCraft = r.tier
					cHint.Text = "Forging..."
				end
			end)
		end
	end

	function ctl.paintCraft(rebuild)
		local snap = getSnap() or {}
		for f, b in pairs(cRailBtns) do
			local on = f == state.cFam
			b.grad.Color = on and ColorSequence.new(TH.tabOn[1], TH.tabOn[2]) or ColorSequence.new(TH.off[1], TH.off[2])
		end
		-- toolbar chips
		clearKids(cBar)
		clearKids(cRarityRow)
		local sortNames = { rarity = "Rarity", cost = "Cost", name = "Name" }
		local sb = chipBtn(cBar, "↕ " .. sortNames[state.cSort], true, function()
			state.cSort = (state.cSort == "rarity" and "cost") or (state.cSort == "cost" and "name") or "rarity"
			ctl.paintCraft(true)
		end, 110, TH.cool)
		sb.LayoutOrder = 1
		local cb = chipBtn(cBar, state.cCraftable and "✅ Craftable" or "Craftable", state.cCraftable, function()
			state.cCraftable = not state.cCraftable
			state.cShow = 60
			ctl.paintCraft(true)
		end, 110, TH.good)
		cb.LayoutOrder = 2
		local active = (state.cSearch ~= "" and 1 or 0) + (state.cRarity and 1 or 0) + (state.cCraftable and 1 or 0) + (state.cFam ~= "all" and 1 or 0)
		local rb = chipBtn(cBar, active > 0 and ("✖ Reset (" .. active .. ")") or "Reset", active > 0, function()
			state.cSearch, state.cRarity, state.cCraftable, state.cFam, state.cShow = "", nil, false, "all", 60
			search.Text = ""
			ctl.paintCraft(true)
		end, 110, TH.danger)
		rb.LayoutOrder = 3
		local allB = chipBtn(cRarityRow, "All", state.cRarity == nil, function()
			state.cRarity = nil
			ctl.paintCraft(true)
		end, 50)
		allB.LayoutOrder = 0
		for i, band in ipairs(BANDS) do
			local col = Cards.RARITY_COLOR[band] or TH.edge
			local b = chipBtn(cRarityRow, band, state.cRarity == band, function()
				state.cRarity = (state.cRarity == band) and nil or band
				state.cShow = 60
				ctl.paintCraft(true)
			end, 84, { col:Lerp(Color3.new(1, 1, 1), 0.2), col:Lerp(Color3.new(0, 0, 0), 0.25) })
			b.LayoutOrder = i
		end
		-- the list
		local list = {}
		for _, r in ipairs(allRecipes(snap)) do
			if (state.cFam == "all" or r.fam == state.cFam)
				and (state.cRarity == nil or (r.band == state.cRarity and not r.locked))
				and (not state.cCraftable or r.afford)
				and (state.cSearch == "" or (not r.locked and (string.find(string.lower(r.name), state.cSearch, 1, true)
					or string.find(string.lower(r.oreName), state.cSearch, 1, true)))) then
				table.insert(list, r)
			end
		end
		table.sort(list, function(a, b)
			-- Craftable first, best first (owner); then the rest; locked last.
			local ga = a.afford and 0 or (a.locked and 2 or 1)
			local gb = b.afford and 0 or (b.locked and 2 or 1)
			if ga ~= gb then
				return ga < gb
			end
			if state.cSort == "name" then
				if a.name ~= b.name then
					return a.name < b.name
				end
			elseif state.cSort == "cost" then
				if a.cost ~= b.cost then
					return a.cost < b.cost
				end
			end
			if a.tier ~= b.tier then
				return a.tier > b.tier
			end
			return a.key < b.key
		end)
		local nReady = 0
		for _, r in ipairs(list) do
			if r.afford then
				nReady += 1
			end
		end
		cInfo.Text = string.format("%d recipes   ·   ✅ %d you can craft now", #list, nReady)
		if state.cSel then
			local still
			for _, r in ipairs(list) do
				if r.key == state.cSel.key then
					still = r
				end
			end
			state.cSel = still
		end
		state.cSel = state.cSel or list[1]
		if rebuild ~= false then
			clearKids(cGrid)
			if #list == 0 then
				text(cGrid, "No recipes match.  Try ✖ Reset.", 20, TH.muted, { Size = UDim2.fromOffset(600, 60), ZIndex = 75 })
			end
			for i = 1, math.min(#list, state.cShow) do
				local r = list[i]
				local _, col = rarityOf(r.tier)
				toolCard(cGrid, {
					order = i, locked = r.locked, col = col, fam = r.fam, name = r.name, band = r.band,
					icon = (not r.locked) and OreIcons.icon(r.id) or nil, oreColor = r.def.color,
					foot = r.locked and "" or (short(r.have) .. " / " .. short(r.cost)),
					footColor = r.afford and TH.ok or nil, ready = r.afford, selected = state.cSel and state.cSel.key == r.key,
					onClick = function()
						state.cSel = r
						ctl.paintCraft(true)
					end,
				})
			end
			if #list > state.cShow then
				local more = pill(cGrid, "SHOW " .. math.min(60, #list - state.cShow) .. " MORE", TH.cool, UDim2.fromOffset(134, 156), 16, 76)
				more.LayoutOrder = state.cShow + 1
				more.MouseButton1Click:Connect(function()
					state.cShow += 60
					ctl.paintCraft(true)
				end)
			end
		end
		paintCraftDetail()
	end

	-- =========================================================== LOADOUT ==
	local lp = pages.loadout
	local lMid = panel(lp, UDim2.fromOffset(0, 0), UDim2.new(1, -440, 1, 0))
	local lDetail = panel(lp, UDim2.new(1, -430, 0, 0), UDim2.new(0, 430, 1, 0))
	local lBar = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 0, 30), ZIndex = 75 }, lMid)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, lBar)
	local lInfo = text(lMid, "", 14, TH.muted, { Position = UDim2.fromOffset(14, 44), Size = UDim2.new(1, -28, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left, Font = FONT_B, ZIndex = 75 })
	local lGrid = scroller(lMid, UDim2.fromOffset(8, 66), UDim2.new(1, -16, 1, -74), UDim2.fromOffset(134, 156), UDim2.fromOffset(8, 8))
	local lStage = makeStage(lDetail, UDim2.fromOffset(10, 6), UDim2.fromOffset(410, 260))
	local lName = text(lDetail, "", 24, TH.text, { Position = UDim2.fromOffset(10, 262), Size = UDim2.new(1, -20, 0, 30), TextScaled = true, ZIndex = 76 })
	ink(lName, 2)
	local lBadge = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 294), Size = UDim2.fromOffset(260, 24), ZIndex = 76 }, lDetail)
	round(lBadge, 12)
	stroke(lBadge, TH.outline, 2)
	local lBadgeL = text(lBadge, "", 14, Color3.new(1, 1, 1), { Font = FONT_B, ZIndex = 77 })
	ink(lBadgeL, 1)
	-- Three lines: the hit and its rate, the area and use, then the skin.
	local lStats = text(lDetail, "", 16, TH.text, { Position = UDim2.fromOffset(16, 324), Size = UDim2.new(1, -32, 0, 66), TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 76 })
	local lSlots = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 394), Size = UDim2.new(1, -32, 0, 112), ZIndex = 76 }, lDetail)
	mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, lSlots)
	local lActions = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 514), Size = UDim2.new(1, -32, 0, 92), ZIndex = 76 }, lDetail)
	mk("UIGridLayout", { CellSize = UDim2.fromOffset(193, 40), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, lActions)
	local lSkinBox = mk("Frame", { Name = "SkinPicker", Visible = false, BackgroundColor3 = TH.chip, Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -20, 1, -20), ZIndex = 90 }, lDetail)
	round(lSkinBox, 14)
	stroke(lSkinBox, TH.edge, 2)

	local function slotLine(parent, slotDef, e, playerLevel, order)
		local row = mk("Frame", { BackgroundColor3 = TH.chip, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = order, ZIndex = 77 }, parent)
		round(row, 10)
		stroke(row, slotDef.color, 1.5, 0.3)
		text(row, slotDef.icon, 16, Color3.new(1, 1, 1), { Position = UDim2.fromOffset(6, 0), Size = UDim2.fromOffset(26, 34), ZIndex = 78 })
		local locked = not E.slotUnlocked(slotDef.id, playerLevel)
		local def = e and E.get(e.id)
		local str
		if locked then
			str = "🔒 " .. slotDef.name .. " · level " .. slotDef.unlockLevel
		elseif def then
			str = def.icon .. " " .. def.name .. " " .. E.roman(e.level) .. "  ·  " .. E.describe(def, e.level)
		else
			str = slotDef.name .. " · empty"
		end
		local l = text(row, str, 14, locked and TH.faint or (def and TH.text or TH.muted), { Position = UDim2.fromOffset(34, 0),
			Size = UDim2.new(1, -40, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 78 })
		ink(l, 1)
		return row
	end

	local function openSkinPicker(o)
		clearKids(lSkinBox)
		lSkinBox.Visible = true
		local snap = getSnap() or {}
		local owned = snap.skins or {}
		local wearingDef = wornSkin(snap, o.fam)
		local wearing = wearingDef and wearingDef.id
		text(lSkinBox, "🎨 SKINS · " .. string.upper(FAMILY_NAME[o.fam] or o.fam), 20, TH.text, { Position = UDim2.fromOffset(14, 8),
			Size = UDim2.new(1, -70, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 91 })
		local x = pill(lSkinBox, "X", TH.danger, UDim2.fromOffset(34, 30), 16, 92)
		x.Position = UDim2.new(1, -44, 0, 8)
		x.MouseButton1Click:Connect(function()
			lSkinBox.Visible = false
		end)
		local list = scroller(lSkinBox, UDim2.fromOffset(8, 44), UDim2.new(1, -16, 1, -52), nil)
		list.ZIndex = 91
		local any = false
		if wearing then
			local b = pill(list, "Take off the skin", TH.off, UDim2.new(1, -8, 0, 34), 15, 93)
			b.LayoutOrder = 0
			b.MouseButton1Click:Connect(function()
				act("equipSkin", { id = "", family = o.fam })
			end)
		end
		--[[
			Each skin says what it does to THIS tool (owner, 2026-10-19: show the
			skin's power): its damage multiplier and its kit, and "stats only"
			while this family has no skin form for its set.
		]]
		for i, s in ipairs((Skins and Skins.LIST) or {}) do
			if owned[s.id] then
				any = true
				local on = wearing == s.id
				local b = pill(list, "", on and TH.good or TH.cool, UDim2.new(1, -8, 0, 54), 15, 93)
				b.LayoutOrder = i
				local top = text(b, (on and "✅ " or "") .. s.name .. "  ·  " .. s.tier
					.. (ToolSkins and ("  ·  " .. ToolSkins.multText(s) .. " damage") or ""), 16, Color3.new(1, 1, 1),
					{ Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -24, 0, 24), TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 94 })
				ink(top, 1.5)
				local kit = text(b, (ToolSkins and ToolSkins.kitText(s, 3) or "") .. looksLabel(o.fam, s), 13, Color3.new(1, 1, 1),
					{ Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 0, 20), TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd, Font = FONT_B, ZIndex = 94 })
				ink(kit, 1)
				b.MouseButton1Click:Connect(function()
					if not on then
						act("equipSkin", { id = s.id, family = o.fam })
					end
				end)
			end
		end
		if not any then
			text(list, "No skins yet. Chests and ore cases drop them.", 16, TH.muted, { Size = UDim2.new(1, 0, 0, 40), TextWrapped = true, ZIndex = 93 })
		end
	end

	local function paintLoadoutDetail(snap)
		clearKids(lSlots)
		clearKids(lActions)
		local o = state.lSel
		if not o then
			lStage.show(nil)
			lName.Text, lBadgeL.Text = "", ""
			lBadge.Visible = false
			lStats.Text = "No tools yet. Craft one in 🔥 CRAFTING."
			return
		end
		lBadge.Visible = true
		local _, col = rarityOf(o.tier)
		local skinDef = wornSkin(snap, o.fam)
		lStage.show(o.fam, o.tier, o.def, skinDef)
		lName.Text = o.name
		lBadgeL.Text = string.upper(o.band) .. "  ·  " .. string.upper(FAMILY_NAME[o.fam] or o.fam) .. "  ·  LV " .. o.level
		lBadge.BackgroundColor3 = col
		-- What this tool lands in your hand: the server's own swing maths (S11).
		-- The level is on the badge above, so these lines stay one line each.
		local card = cardOf(snap, o.tool)
		lStats.Text = string.format("⚔ %s per hit  ·  %s%s\n🧱 %s  ·  ✋ %s\n🎨 %s",
			short(card.hit), perSecText(card.perSec), o.equipped and "  ·  ✅ IN HAND" or "",
			card.area, card.use,
			skinDef and (skinDef.name .. " " .. ToolSkins.multText(skinDef) .. looksLabel(o.fam, skinDef)) or "No skin")
		local enchants = type(o.tool.enchants) == "table" and o.tool.enchants or {}
		local lvl = snap.enchants and snap.enchants.level or 1
		for i, sd in ipairs(E.SLOTS) do
			slotLine(lSlots, sd, enchants[sd.id], lvl, i)
		end
		local function actionBtn(order, label, colors, fn)
			local b = pill(lActions, label, colors, UDim2.fromOffset(193, 40), 16, 78)
			b.LayoutOrder = order
			b.MouseButton1Click:Connect(fn)
		end
		if o.equipped then
			actionBtn(1, "PUT AWAY", TH.off, function()
				act("equipOreTool", { uid = "" })
			end)
		else
			actionBtn(1, "✋ EQUIP", TH.good, function()
				act("equipOreTool", { uid = o.uid })
			end)
		end
		actionBtn(2, "🎨 SKIN", TH.cool, function()
			openSkinPicker(o)
		end)
		actionBtn(3, "⬆ LEVEL UP", TH.action, function()
			ctl.open("upgrades", o.uid, "level")
		end)
		actionBtn(4, "✨ ENCHANT", TH.magic, function()
			ctl.open("upgrades", o.uid, "enchant")
		end)
	end

	function ctl.paintLoadout()
		local snap = getSnap() or {}
		lSkinBox.Visible = lSkinBox.Visible and state.lSel ~= nil
		clearKids(lBar)
		local function famChip(order, f, label)
			local b = chipBtn(lBar, label, state.lFam == f, function()
				state.lFam = f
				ctl.paintLoadout()
			end, 112)
			b.LayoutOrder = order
		end
		famChip(1, "all", "All")
		for i, f in ipairs(FAMILIES) do
			famChip(i + 1, f, (FAMILY_ICON[f] or "") .. " " .. (FAMILY_NAME[f] or f))
		end
		local eq = chipBtn(lBar, state.lEquipped and "✅ In hand" or "In hand", state.lEquipped, function()
			state.lEquipped = not state.lEquipped
			ctl.paintLoadout()
		end, 96, TH.good)
		eq.LayoutOrder = 20
		local sortNames = { rarity = "Rarity", level = "Level", name = "Name" }
		local so = chipBtn(lBar, "↕ " .. sortNames[state.lSort], true, function()
			state.lSort = (state.lSort == "rarity" and "level") or (state.lSort == "level" and "name") or "rarity"
			ctl.paintLoadout()
		end, 96, TH.cool)
		so.LayoutOrder = 21
		local list = {}
		local all = ownedTools(snap)
		for _, o in ipairs(all) do
			if (state.lFam == "all" or o.fam == state.lFam) and (not state.lEquipped or o.equipped) then
				table.insert(list, o)
			end
		end
		table.sort(list, function(a, b)
			if a.equipped ~= b.equipped then
				return a.equipped
			end
			if state.lSort == "level" and a.level ~= b.level then
				return a.level > b.level
			elseif state.lSort == "name" and a.name ~= b.name then
				return a.name < b.name
			end
			if a.tier ~= b.tier then
				return a.tier > b.tier
			end
			return tostring(a.uid) < tostring(b.uid)
		end)
		lInfo.Text = string.format("%d tools   ·   %d shown", #all, #list)
		if state.lSel then
			local still
			for _, o in ipairs(all) do
				if o.uid == state.lSel.uid then
					still = o
				end
			end
			state.lSel = still
		end
		state.lSel = state.lSel or list[1]
		clearKids(lGrid)
		if #list == 0 then
			text(lGrid, #all == 0 and "No tools yet. Craft one in 🔥 CRAFTING." or "Nothing matches.", 20, TH.muted, { Size = UDim2.fromOffset(600, 60), ZIndex = 75 })
		end
		for i, o in ipairs(list) do
			local _, col = rarityOf(o.tier)
			local en = type(o.tool.enchants) == "table" and o.tool.enchants or {}
			toolCard(lGrid, {
				order = i, col = col, fam = o.fam, name = o.name, band = o.band, icon = o.def and OreIcons.icon(o.def.id) or nil,
				oreColor = o.def and o.def.color, foot = "Lv " .. o.level, selected = state.lSel and state.lSel.uid == o.uid,
				badge = o.equipped and "IN HAND" or nil, badgeColor = rgb(60, 200, 90), badgeW = 62,
				dots = { en.damage ~= nil, en.utility ~= nil, en.special ~= nil },
				onClick = function()
					state.lSel = o
					lSkinBox.Visible = false
					ctl.paintLoadout()
				end,
			})
		end
		paintLoadoutDetail(snap)
	end

	-- ========================================================== UPGRADES ==
	local up = pages.upgrades
	local uList = panel(up, UDim2.fromOffset(0, 0), UDim2.new(0, 330, 1, 0))
	local uMain = panel(up, UDim2.fromOffset(340, 0), UDim2.new(1, -340, 1, 0))
	local uListTitle = text(uList, "YOUR TOOLS", 16, TH.muted, { Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Left, Font = FONT_B, ZIndex = 75 })
	local _ = uListTitle
	local booksBtn = pill(uList, "📖 MY BOOKS", TH.magic, UDim2.fromOffset(130, 30), 14, 76)
	booksBtn.Position = UDim2.new(1, -142, 0, 6)
	local uScroll = scroller(uList, UDim2.fromOffset(8, 42), UDim2.new(1, -16, 1, -50), nil)
	local uOps = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 0, 38), ZIndex = 75 }, uMain)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, uOps)
	local uWork = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 58), Size = UDim2.new(1, -32, 1, -70), ZIndex = 75 }, uMain)

	local function selectedTool(snap)
		if not state.uSel then
			return nil
		end
		for _, o in ipairs(ownedTools(snap)) do
			if o.uid == state.uSel then
				return o
			end
		end
		return nil
	end

	local function paintLevel(snap, o)
		local stg = makeStage(uWork, UDim2.fromOffset(0, 0), UDim2.fromOffset(360, 300))
		stg.show(o.fam, o.tier, o.def, (wornSkin(snap, o.fam)))
		local mult = OreTools.typeMult(o.fam, o.tier)
		local info = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(380, 10), Size = UDim2.new(1, -390, 1, -20), ZIndex = 76 }, uWork)
		local n = text(info, o.name, 26, TH.text, { Size = UDim2.new(1, 0, 0, 34), TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, ZIndex = 77 })
		ink(n, 2)
		local lv, cap = o.level, C.TOOL_MAX_LEVEL or 30
		-- Per hit, as the hand lands it (family, skin and finish in): S11.
		local now = cardOf(snap, o.tool).hit
		if lv >= cap then
			text(info, "⭐ MAX LEVEL " .. cap .. "   ·   ⚔ " .. short(now) .. " per hit", 22, TH.text, { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 0, 30),
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 77 })
			return
		end
		local upRow = table.clone(o.tool)
		upRow.level = lv + 1
		local nxt = cardOf(snap, upRow).hit
		local cmp = text(info, string.format("LV %d  →  %d", lv, lv + 1), 30, TH.text, { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 36),
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 77 })
		ink(cmp, 2)
		text(info, string.format("⚔ %s  →  %s   (+%s)", short(now), short(nxt), short(nxt - now)), 20, TH.ok, { Position = UDim2.fromOffset(0, 88),
			Size = UDim2.new(1, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 77 })
		local coinTool = C.isCoinTool and C.isCoinTool(o.tool)
		local ok1, costLine
		if coinTool then
			local coins = C.woodPickCoinCost and C.woodPickCoinCost(lv) or nil
			ok1 = coins ~= nil and (tonumber(snap.coins) or 0) >= coins
			costLine = coins and ("💰 " .. short(snap.coins) .. " / " .. short(coins)) or "MAX"
		else
			local ore, dust = C.toolUpgradeCost(o.tier, lv, mult, o.fam)
			local have = o.def and tonumber((snap.ores or {})[o.def.id]) or 0
			local dHave = tonumber(snap.dust) or 0
			ok1 = ore ~= nil and have >= ore and dHave >= (dust or 0)
			costLine = string.format("🪨 %s / %s %s     ✨ %s / %s", short(have), short(ore or 0), o.def and o.def.name or "", short(dHave), short(dust or 0))
		end
		local cl = text(info, costLine, 18, ok1 and TH.ok or TH.bad, { Position = UDim2.fromOffset(0, 124), Size = UDim2.new(1, 0, 0, 24),
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 77 })
		ink(cl, 1)
		local row = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 164), Size = UDim2.new(1, 0, 0, 46), ZIndex = 77 }, info)
		mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, row)
		local b1 = pill(row, ok1 and "⬆ +1 LEVEL" or "NEED MORE", ok1 and TH.action or TH.off, UDim2.fromOffset(200, 46), 20, 78)
		if ok1 then
			b1.MouseButton1Click:Connect(function()
				act("upgradeOreTool", { uid = o.uid, count = 1 })
			end)
		end
		if not coinTool then
			local b10 = pill(row, "+10", ok1 and TH.action or TH.off, UDim2.fromOffset(110, 46), 20, 78)
			if ok1 then
				b10.MouseButton1Click:Connect(function()
					act("upgradeOreTool", { uid = o.uid, count = 10 })
				end)
			end
		end
		text(info, "+10 levels as many as you can pay for, up to 10.", 14, TH.muted, { Position = UDim2.fromOffset(0, 216), Size = UDim2.new(1, 0, 0, 20),
			TextXAlignment = Enum.TextXAlignment.Left, Font = FONT_B, ZIndex = 77 })
	end

	local function bookCard(parent, def, level, count, ctx)
		local col = E.RARITY_COLOR[def.rarity] or TH.edge
		local b = mk("TextButton", { Text = "", BackgroundColor3 = TH.panel2, Size = UDim2.new(1, -8, 0, 62), AutoButtonColor = false,
			LayoutOrder = ctx.order or 0, ZIndex = 78 }, parent)
		round(b, 10)
		stroke(b, ctx.ok and col or rgb(80, 76, 80), ctx.ok and 2 or 1)
		text(b, def.icon, 26, Color3.new(1, 1, 1), { Position = UDim2.fromOffset(6, 0), Size = UDim2.fromOffset(40, 62), ZIndex = 79 })
		local nm = text(b, def.name .. " " .. E.roman(level) .. (count and ("   x" .. count) or ""), 17, ctx.ok and TH.text or TH.faint,
			{ Position = UDim2.fromOffset(50, 4), Size = UDim2.new(1, -160, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 79 })
		ink(nm, 1)
		text(b, ctx.line or E.describe(def, level), 14, ctx.ok and TH.muted or TH.faint, { Position = UDim2.fromOffset(50, 30),
			Size = UDim2.new(1, -160, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Font = FONT_B, ZIndex = 79 })
		if ctx.button then
			local a = pill(b, ctx.button, ctx.ok and (ctx.colors or TH.magic) or TH.off, UDim2.fromOffset(100, 34), 15, 80)
			a.Position = UDim2.new(1, -108, 0.5, -17)
			if ctx.ok and ctx.onClick then
				a.MouseButton1Click:Connect(ctx.onClick)
			end
		elseif ctx.tag then
			local t = text(b, ctx.tag, 13, TH.faint, { Position = UDim2.new(1, -112, 0, 0), Size = UDim2.fromOffset(104, 62), Font = FONT_B, ZIndex = 79 })
			local _2 = t
		end
		return b
	end

	local function paintEnchant(snap, o)
		local lvl = snap.enchants and snap.enchants.level or 1
		local books = snap.enchants and snap.enchants.books or {}
		local en = type(o.tool.enchants) == "table" and o.tool.enchants or {}
		-- The three slots, side by side.
		local slots = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 170), ZIndex = 76 }, uWork)
		mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center }, slots)
		for i, sd in ipairs(E.SLOTS) do
			local locked = not E.slotUnlocked(sd.id, lvl)
			local e = en[sd.id]
			local def = e and E.get(e.id)
			local on = state.uSlot == sd.id
			local card = mk("TextButton", { Text = "", BackgroundColor3 = locked and rgb(36, 32, 34) or TH.panel2, Size = UDim2.fromOffset(300, 170),
				LayoutOrder = i, AutoButtonColor = false, ZIndex = 77 }, slots)
			round(card, 16)
			stroke(card, sd.color, on and 4 or 2, locked and 0.6 or 0)
			if not locked then
				grad(card, TH.panel2:Lerp(sd.color, 0.25), TH.panel2, 90)
			end
			local hd = text(card, sd.icon .. "  " .. string.upper(sd.name), 22, locked and TH.faint or sd.color, { Position = UDim2.fromOffset(0, 8),
				Size = UDim2.new(1, 0, 0, 28), ZIndex = 78 })
			ink(hd, 1.5)
			text(card, sd.purpose, 14, TH.muted, { Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 18), Font = FONT_B, ZIndex = 78 })
			local body2
			if locked then
				body2 = "🔒 Unlocks at LEVEL " .. sd.unlockLevel
			elseif def then
				body2 = def.icon .. " " .. def.name .. " " .. E.roman(e.level) .. "\n" .. E.describe(def, e.level)
			else
				body2 = "Empty — tap to add a book"
			end
			local bl = text(card, body2, 18, locked and TH.faint or TH.text, { Position = UDim2.fromOffset(10, 62), Size = UDim2.new(1, -20, 0, 60),
				TextWrapped = true, ZIndex = 78 })
			ink(bl, 1)
			if def and not locked then
				local rm = pill(card, "REMOVE", TH.off, UDim2.fromOffset(110, 30), 14, 79)
				rm.Position = UDim2.new(0.5, -55, 1, -40)
				rm.MouseButton1Click:Connect(function()
					act("enchRemove", { uid = o.uid, slot = sd.id })
				end)
			end
			juice(card)
			card.MouseButton1Click:Connect(function()
				if not locked then
					state.uSlot = sd.id
					ctl.paintUpgrades()
				end
			end)
		end
		-- The book picker for the chosen slot.
		local slotId = state.uSlot or "damage"
		local sd = E.SLOT_BY_ID[slotId]
		local hdr = text(uWork, "📖 " .. string.upper(sd.name) .. " BOOKS", 18, sd.color, { Position = UDim2.fromOffset(0, 180), Size = UDim2.new(1, 0, 0, 24),
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 76 })
		ink(hdr, 1)
		local picker = scroller(uWork, UDim2.fromOffset(0, 208), UDim2.new(1, 0, 1, -208), nil)
		local cur = en[slotId]
		local rows = {}
		for key, n in pairs(books) do
			local id, level = E.parseBookKey(key)
			local def = id and E.get(id)
			if def and def.slot == slotId and (tonumber(n) or 0) > 0 then
				table.insert(rows, { def = def, level = level, n = n })
			end
		end
		-- Every enchant for the slot, so a player sees what exists, owned or not.
		local ownedIds = {}
		for _, r in ipairs(rows) do
			ownedIds[r.def.id] = true
		end
		table.sort(rows, function(a, b)
			if a.def.live ~= b.def.live then
				return a.def.live
			end
			if a.level ~= b.level then
				return a.level > b.level
			end
			return a.def.name < b.def.name
		end)
		local order = 0
		for _, r in ipairs(rows) do
			order += 1
			local ok, why = E.compatible(r.def, o.fam)
			local slotLocked = not E.slotUnlocked(slotId, lvl)
			local line = E.describe(r.def, r.level)
			if cur and E.get(cur.id) then
				line = "now: " .. E.get(cur.id).name .. " " .. E.roman(cur.level) .. " " .. E.describe(E.get(cur.id), cur.level) .. "   →   " .. line
			end
			bookCard(picker, r.def, r.level, r.n, {
				order = order, ok = ok and not slotLocked, line = ok and line or (why or "Can't go on this tool"),
				button = (cur and "REPLACE") or "APPLY",
				onClick = function()
					act("enchApply", { uid = o.uid, slot = slotId, id = r.def.id, level = r.level })
				end,
			})
		end
		for _, def in ipairs(E.LIST) do
			if def.slot == slotId and not ownedIds[def.id] then
				order += 1
				bookCard(picker, def, 1, nil, { order = order, ok = false, line = def.blurb .. (def.live and "" or "  ·  COMING SOON"),
					tag = def.live and "NOT OWNED" or "SOON" })
			end
		end
	end

	local function paintScrap(snap, o)
		local stg = makeStage(uWork, UDim2.fromOffset(0, 0), UDim2.fromOffset(360, 300))
		stg.show(o.fam, o.tier, o.def, (wornSkin(snap, o.fam)))
		local info = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(380, 10), Size = UDim2.new(1, -390, 1, -20), ZIndex = 76 }, uWork)
		local n = text(info, o.name, 26, TH.text, { Size = UDim2.new(1, 0, 0, 34), TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, ZIndex = 77 })
		ink(n, 2)
		--[[
			What the server's recycleOreTool pays, by its own call (launch audit
			S10). This quoted base level 1, so a tool forged at your best level --
			which refunds only the levels it bought, often none -- showed a whole
			climb coming back.
		]]
		local ore, dust = OreTools.recycleRefund(o.tool)
		local en = type(o.tool.enchants) == "table" and o.tool.enchants or {}
		local back = { string.format("🪨 %s %s", short(ore), o.def and o.def.name or "ore"), string.format("✨ %s stardust", short(dust)) }
		for _, e in pairs(en) do
			local def = E.get(e.id)
			if def then
				table.insert(back, "📖 " .. def.name .. " " .. E.roman(e.level) .. " (back to your books)")
			end
		end
		text(info, "YOU GET BACK", 16, TH.muted, { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Left,
			Font = FONT_B, ZIndex = 77 })
		text(info, table.concat(back, "\n"), 18, TH.text, { Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 0, 100), TextYAlignment = Enum.TextYAlignment.Top,
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 77 })
		text(info, "⚠ The tool is gone for good.", 16, TH.bad, { Position = UDim2.fromOffset(0, 176), Size = UDim2.new(1, 0, 0, 22),
			TextXAlignment = Enum.TextXAlignment.Left, Font = FONT_B, ZIndex = 77 })
		if o.equipped then
			text(info, "It's in your hand — put it away first (🎒 LOADOUT).", 16, TH.muted, { Position = UDim2.fromOffset(0, 206), Size = UDim2.new(1, 0, 0, 22),
				TextXAlignment = Enum.TextXAlignment.Left, Font = FONT_B, ZIndex = 77 })
			return
		end
		local sure = state.uConfirm == o.uid
		local b = pill(info, sure and "TAP AGAIN TO SCRAP" or "♻ SCRAP", TH.danger, UDim2.fromOffset(280, 46), 20, 78)
		b.Position = UDim2.fromOffset(0, 210)
		b.MouseButton1Click:Connect(function()
			if state.uConfirm == o.uid then
				state.uConfirm = nil
				if act("recycleOreTool", { uid = o.uid }) then
					state.uSel = nil
				end
			else
				state.uConfirm = o.uid
				ctl.paintUpgrades()
				task.delay(4, function()
					if state.uConfirm == o.uid then
						state.uConfirm = nil
						ctl.paintUpgrades()
					end
				end)
			end
		end)
	end

	local function paintBooks(snap)
		local books = snap.enchants and snap.enchants.books or {}
		-- THE BOOK SHOP: gems buy a bundle (owner chose "Gems buy book bundles").
		local en = snap.enchants or {}
		local price = tonumber(en.bundlePrice) or E.bundlePrice(1)
		local size = tonumber(en.bundleSize) or E.SHOP_BUNDLE
		local canBuy = (tonumber(snap.gems) or 0) >= price
		local shop = mk("Frame", { BackgroundColor3 = TH.panel2, Size = UDim2.new(1, -8, 0, 64), ZIndex = 76 }, uWork)
		round(shop, 12)
		stroke(shop, TH.magic[1], 2)
		text(shop, "📚", 30, Color3.new(1, 1, 1), { Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(48, 64), ZIndex = 77 })
		local st = text(shop, "BOOK BUNDLE   ·   " .. size .. " random books", 19, TH.text, { Position = UDim2.fromOffset(62, 6),
			Size = UDim2.new(1, -340, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 77 })
		ink(st, 1)
		text(shop, "Chests and lucky blocks drop bundles too.", 14, TH.muted, { Position = UDim2.fromOffset(62, 34),
			Size = UDim2.new(1, -340, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, Font = FONT_B, ZIndex = 77 })
		local buy = pill(shop, "💎 " .. short(price), canBuy and TH.good or TH.off, UDim2.fromOffset(170, 44), 18, 78)
		buy.Position = UDim2.new(1, -180, 0.5, -22)
		buy.MouseButton1Click:Connect(function()
			if canBuy then
				act("enchBuyBundle", {})
			end
		end)
		--[[
			ODDS BEFORE YOU BUY (owner, 2026-10-19, launch audit M3): the bundle is
			random books for gems, and gems trace back to Robux. Each book is drawn
			on its own at level I; every chance is MineEnchants.bookOdds, the
			weights rollBundle rolls with.
		]]
		local oddsB = pill(shop, "ODDS", TH.cool, UDim2.fromOffset(84, 44), 16, 78)
		oddsB.Position = UDim2.new(1, -274, 0.5, -22)
		oddsB.MouseButton1Click:Connect(function()
			if state.oddsSheet and state.oddsSheet.Parent then
				state.oddsSheet:Destroy()
			end
			local okV, View = pcall(function()
				return require(shared:WaitForChild("MineLuckyOddsView"))
			end)
			if not (okV and View) then
				return
			end
			local rows = {}
			for _, b in ipairs(E.bookOdds()) do
				table.insert(rows, {
					name = tostring(b.name) .. " I  ·  " .. tostring(b.rarity), p = b.p,
					tint = Cards.RARITY_COLOR and Cards.RARITY_COLOR[b.rarity] or nil,
				})
			end
			table.sort(rows, function(a, b)
				if a.p ~= b.p then
					return a.p > b.p
				end
				return a.name < b.name
			end)
			state.oddsSheet = View.sheet(root, {
				title = "BOOK BUNDLE  ODDS",
				sub = size .. " books, each drawn on its own, always level I",
				color = TH.magic[1],
				sections = { { header = "EACH BOOK IS ONE OF THESE", rows = rows } },
				note = "A bundle can repeat a book. Merge " .. E.MERGE_COST .. " of the same book for the next level.",
			}, {
				zIndex = 90,
				onClose = function()
					state.oddsSheet = nil
				end,
			})
		end)
		local hdr = text(uWork, "📖 MY BOOKS   ·   merge " .. E.MERGE_COST .. " of the same book for +1 level", 18, TH.text, { Position = UDim2.fromOffset(0, 72),
			Size = UDim2.new(1, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 76 })
		ink(hdr, 1)
		local sc = scroller(uWork, UDim2.fromOffset(0, 104), UDim2.new(1, 0, 1, -104), nil)
		local rows = {}
		for key, n in pairs(books) do
			local id, level = E.parseBookKey(key)
			if id and (tonumber(n) or 0) > 0 then
				table.insert(rows, { def = E.get(id), level = level, n = tonumber(n) })
			end
		end
		table.sort(rows, function(a, b)
			if a.def.slot ~= b.def.slot then
				return E.SLOT_BY_ID[a.def.slot].index < E.SLOT_BY_ID[b.def.slot].index
			end
			if a.def.name ~= b.def.name then
				return a.def.name < b.def.name
			end
			return a.level < b.level
		end)
		if #rows == 0 then
			text(sc, "No books yet. Buy a bundle above, or find one in a chest or a lucky block.", 18, TH.muted, { Size = UDim2.new(1, 0, 0, 40), ZIndex = 77 })
		end
		for i, r in ipairs(rows) do
			local canMerge = r.n >= E.MERGE_COST and r.level < E.MAX_LEVEL
			bookCard(sc, r.def, r.level, r.n, {
				order = i, ok = true, line = E.SLOT_BY_ID[r.def.slot].name .. "  ·  " .. E.describe(r.def, r.level)
					.. (r.def.live and "" or "  ·  SOON"),
				button = (r.level >= E.MAX_LEVEL) and nil or ("MERGE " .. E.MERGE_COST .. "→" .. E.roman(r.level + 1)),
				colors = canMerge and TH.good or TH.off,
				onClick = canMerge and function()
					act("enchMerge", { id = r.def.id, level = r.level })
				end or nil,
			})
		end
	end

	function ctl.paintUpgrades()
		local snap = getSnap() or {}
		clearKids(uScroll)
		local tools = ownedTools(snap)
		table.sort(tools, function(a, b)
			if a.equipped ~= b.equipped then
				return a.equipped
			end
			if a.tier ~= b.tier then
				return a.tier > b.tier
			end
			return tostring(a.uid) < tostring(b.uid)
		end)
		if not state.uSel and tools[1] and state.uOp ~= "books" then
			state.uSel = tools[1].uid
		end
		for i, o in ipairs(tools) do
			local _, col = rarityOf(o.tier)
			local on = state.uSel == o.uid and state.uOp ~= "books"
			local row = mk("TextButton", { Text = "", BackgroundColor3 = on and TH.panel2:Lerp(col, 0.3) or TH.panel2, Size = UDim2.new(1, -8, 0, 44),
				LayoutOrder = i, AutoButtonColor = false, ZIndex = 76 }, uScroll)
			round(row, 10)
			stroke(row, col, on and 3 or 1.5)
			text(row, FAMILY_ICON[o.fam] or "⛏", 18, Color3.new(1, 1, 1), { Position = UDim2.fromOffset(6, 0), Size = UDim2.fromOffset(28, 44), ZIndex = 77 })
			local nm = text(row, o.name, 15, TH.text, { Position = UDim2.fromOffset(36, 2), Size = UDim2.new(1, -110, 0, 22),
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 77 })
			ink(nm, 1)
			text(row, string.upper(o.band), 11, col, { Position = UDim2.fromOffset(36, 24), Size = UDim2.new(1, -110, 0, 16),
				TextXAlignment = Enum.TextXAlignment.Left, Font = FONT_B, ZIndex = 77 })
			text(row, "Lv " .. o.level .. (o.equipped and " ✅" or ""), 14, TH.muted, { Position = UDim2.new(1, -74, 0, 0), Size = UDim2.fromOffset(68, 44), Font = FONT_B, ZIndex = 77 })
			row.MouseButton1Click:Connect(function()
				state.uSel = o.uid
				state.uConfirm = nil
				if state.uOp == "books" then
					state.uOp = "level"
				end
				ctl.paintUpgrades()
			end)
		end
		if #tools == 0 then
			text(uScroll, "No tools yet.", 16, TH.muted, { Size = UDim2.new(1, 0, 0, 40), ZIndex = 77 })
		end
		-- operations
		clearKids(uOps)
		clearKids(uWork)
		for i, op in ipairs({ { "level", "⬆ LEVEL" }, { "enchant", "✨ ENCHANT" }, { "scrap", "♻ SCRAP" } }) do
			local b, _, g = pill(uOps, op[2], state.uOp == op[1] and TH.tabOn or TH.off, UDim2.fromOffset(150, 38), 17, 76)
			b.LayoutOrder = i
			local _2 = g
			b.MouseButton1Click:Connect(function()
				state.uOp = op[1]
				state.uConfirm = nil
				ctl.paintUpgrades()
			end)
		end
		if state.uOp == "books" then
			paintBooks(snap)
			return
		end
		local o = selectedTool(snap)
		if not o then
			text(uWork, "Pick a tool on the left.", 22, TH.muted, { Size = UDim2.new(1, 0, 0, 60), ZIndex = 76 })
			return
		end
		if state.uOp == "enchant" then
			paintEnchant(snap, o)
		elseif state.uOp == "scrap" then
			paintScrap(snap, o)
		else
			paintLevel(snap, o)
		end
	end
	booksBtn.MouseButton1Click:Connect(function()
		state.uOp = "books"
		ctl.paintUpgrades()
	end)

	-- ============================================================ chrome ==
	local lastToolCount
	local BAND_TIER = { Common = 0, Uncommon = 1, Rare = 1, Epic = 2, Legendary = 3, Mythic = 3, Divine = 4, Exotic = 4 }
	local function paintChrome()
		local snap = getSnap() or {}
		coinsV.Text = short(snap.coins)
		gemsV.Text = short(snap.gems)
		dustV.Text = short(snap.dust)
		if ctl._eventToolsBtn then
			ctl._eventToolsBtn.Visible = snap.zoneId == "bigbang"
		end
		local en = snap.enchants or {}
		lvL.Text = "LV " .. tostring(en.level or 1)
		local frac = math.clamp((tonumber(en.xp) or 0) / math.max(1, tonumber(en.next) or 1), 0, 1)
		xpFill.Size = UDim2.fromScale(frac, 1)
		xpL.Text = short(en.xp) .. " / " .. short(en.next) .. " XP"
		for id, t in pairs(tabs) do
			t.grad.Color = (id == state.tab) and ColorSequence.new(TH.tabOn[1], TH.tabOn[2]) or ColorSequence.new(TH.tabOff, TH.tabOff)
			pages[id].Visible = (id == state.tab)
		end
		-- A new tool landing after CRAFT celebrates by its rarity.
		local n = #(snap.oreTools or {})
		if lastToolCount and n > lastToolCount and ctl._pendingCraft then
			local band = rarityOf(ctl._pendingCraft)
			if Celebrate and Celebrate.burst then
				pcall(Celebrate.burst, math.max(1, BAND_TIER[band] or 1))
			end
			ctl._pendingCraft = nil
		end
		lastToolCount = n
	end

	--[[
		A BUNDLE OPENS ON SCREEN: the books you just got, big, then tap to go on.
		Only while the Forge is open (a chest's bundle toasts in the mine).
	]]
	function ctl.showBundle(books)
		if not root.Visible or type(books) ~= "table" or #books == 0 then
			return
		end
		local old = root:FindFirstChild("BundleReveal")
		if old then
			old:Destroy()
		end
		local veil = mk("TextButton", { Name = "BundleReveal", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.3, Size = UDim2.fromScale(1, 1), ZIndex = 120 }, root)
		local h = 130 + 64 * #books
		local card = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(560, h),
			BackgroundColor3 = TH.panel, ZIndex = 121 }, veil)
		round(card, 18)
		stroke(card, TH.magic[1], 3)
		local title = text(card, "📖 BOOK BUNDLE!", 32, TH.text, { Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 44), ZIndex = 122 })
		ink(title, 2)
		local best = 1
		for i, bk in ipairs(books) do
			local def = E.get(bk.id)
			if def then
				local col = E.RARITY_COLOR[def.rarity] or TH.edge
				best = math.max(best, table.find(E.RARITIES, def.rarity) or 1)
				local row = mk("Frame", { BackgroundColor3 = TH.panel2, Position = UDim2.fromOffset(20, 60 + (i - 1) * 64),
					Size = UDim2.new(1, -40, 0, 56), ZIndex = 122 }, card)
				round(row, 10)
				stroke(row, col, 2)
				text(row, def.icon, 26, Color3.new(1, 1, 1), { Position = UDim2.fromOffset(6, 0), Size = UDim2.fromOffset(44, 56), ZIndex = 123 })
				local nm = text(row, def.name .. " " .. E.roman(bk.level), 20, col, { Position = UDim2.fromOffset(56, 2), Size = UDim2.new(1, -66, 0, 28),
					TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 123 })
				ink(nm, 1)
				text(row, E.SLOT_BY_ID[def.slot].name .. "  ·  " .. E.describe(def, bk.level), 14, TH.muted, { Position = UDim2.fromOffset(56, 30),
					Size = UDim2.new(1, -66, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Font = FONT_B, ZIndex = 123 })
			end
		end
		text(card, "TAP TO KEEP GOING", 16, TH.faint, { Position = UDim2.new(0, 0, 1, -40), Size = UDim2.new(1, 0, 0, 30), Font = FONT_B, ZIndex = 122 })
		if Celebrate and Celebrate.burst then
			pcall(Celebrate.burst, math.clamp(best - 1, 1, 4))
		end
		veil.MouseButton1Click:Connect(function()
			veil:Destroy()
		end)
		task.delay(8, function()
			if veil.Parent then
				veil:Destroy()
			end
		end)
	end

	--[[
		WHAT A SNAPSHOT REPAINTS. Snapshots land up to ten times a second while
		anything digs, and refresh() clears and rebuilds every card, model stage
		and button on the page. At that rate the Forge never settled: a hovered
		card snapped back and re-grew, and its TextScaled name re-fit each time,
		which read as the font sizes flickering (owner, 2026-10-17). So a
		snapshot repaints only when something the Forge shows has changed, and
		at most about once a second -- except while an action waits on its
		answer, which repaints at once so its button unlocks.
	]]
	local lastSig, lastPaint, trailing = nil, 0, false
	local function signature()
		local snap = getSnap() or {}
		local ok, s = pcall(HttpService.JSONEncode, HttpService, {
			coins = snap.coins, gems = snap.gems, dust = snap.dust,
			ores = snap.ores, oresSeen = snap.oresSeen,
			oreTools = snap.oreTools, oreToolEquipped = snap.oreToolEquipped,
			enchants = snap.enchants, skins = snap.skins, skinEquipped = snap.skinEquipped,
		})
		return ok and s or nil
	end

	function ctl.refresh()
		busyUntil = 0
		if not root.Visible then
			return
		end
		lastSig, lastPaint = signature(), os.clock()
		paintChrome()
		if state.tab == "craft" then
			ctl.paintCraft(true)
		elseif state.tab == "loadout" then
			ctl.paintLoadout()
		else
			ctl.paintUpgrades()
		end
	end

	-- The snapshot's way in (MineForgeHub.client); see WHAT A SNAPSHOT REPAINTS.
	function ctl.onSnapshot()
		if not root.Visible then
			return
		end
		if busyUntil > 0 then
			ctl.refresh()
			return
		end
		local sig = signature()
		if sig and sig == lastSig then
			return
		end
		local wait = 1 - (os.clock() - lastPaint)
		if wait <= 0 then
			ctl.refresh()
		elseif not trailing then
			trailing = true
			task.delay(wait, function()
				trailing = false
				ctl.onSnapshot()
			end)
		end
	end

	for id, t in pairs(tabs) do
		t.btn.MouseButton1Click:Connect(function()
			if state.tab ~= id then
				state.tab = id
				ctl.refresh()
			end
		end)
	end

	-- ------------------------------------------------------------ motion --
	local fxConn
	local function startFx()
		if fxConn then
			return
		end
		local t0 = 0
		fxConn = RunService.RenderStepped:Connect(function(dt)
			if not root.Visible then
				return
			end
			t0 += dt
			for _, m in ipairs(motes) do
				m.y -= m.v * dt
				if m.y < -0.03 then
					m.y, m.x = 1.03, math.random()
				end
				m.f.Position = UDim2.fromScale(m.x + math.sin(t0 * 1.3 + m.ph) * 0.01, m.y)
				m.f.BackgroundTransparency = 0.15 + 0.6 * (1 - m.y)
			end
			for _, s in ipairs(stages) do
				if s.frame.Parent and s.frame.Visible then
					local hb = s.haloBase + math.sin(t0 * 2) * s.haloBase * 0.06
					s.halo.Size = UDim2.fromOffset(hb, hb)
					s.rays.Rotation = (t0 * 12) % 360
				end
			end
		end)
	end

	-- open(tab, uid, op): a tab, and optionally a tool to land on (Loadout's
	-- LEVEL UP / ENCHANT keep the tool selected) and an Upgrades operation.
	function ctl.open(tab, uid, op)
		if tab then
			state.tab = tab
		end
		if uid then
			state.uSel = uid
		end
		if op then
			state.uOp = op
		end
		local first = not root.Visible
		root.Visible = true
		fit()
		if first then
			local s0 = scale.Scale
			scale.Scale = s0 * 0.9
			TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = s0 }):Play()
		end
		startFx()
		ctl.refresh()
	end

	function ctl.close()
		root.Visible = false
		-- prune dead stages (each page rebuilds its own)
		local live = {}
		for _, s in ipairs(stages) do
			if s.frame.Parent then
				table.insert(live, s)
			end
		end
		stages = live
	end

	function ctl.isOpen()
		return root.Visible
	end

	closeBtn.MouseButton1Click:Connect(ctl.close)
	ctl.root = root
	return ctl
end

return Hub
