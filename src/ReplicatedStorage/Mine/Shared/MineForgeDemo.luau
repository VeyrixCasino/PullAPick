--[[
	MineForgeDemo -- a DEMO Forge, in two looks, for the owner to judge.

	Owner, 2026-10-11: "im tired of the shitty pitch black background with a
	couple shitty buttons ... i want to gasp with excitment next time i open the
	fuckin forge gui", then: make demos "that pop up by some buttons on the
	screen and just make sure it all works good and i can scroll through it",
	"do 1 molten forge and 1 candy uis". If one is good it gets wired in for
	real; until then the live Forge (MineForge, inside the Blacksmith) is left
	alone, and this runs beside it.

	THE LAYOUT (from the Canva mockup "Mine For Cards FORGE menu"):
	  top     the title, your 💰 coins, 💎 gems, ✨ stardust, X
	  tabs    CRAFT / UPGRADE / RECYCLE
	  left    the five families (pickaxe, hammer, drill, jackhammer, explosive)
	  centre  an anvil on a glowing pedestal, the selected tool SPINNING in 3D
	          above it (ToolModelFactory), its name, rarity badge, stats, the
	          cost, and one big action button
	  right   a scrolling grid of cards in rarity colours; locked ones are a
	          "?" (an undiscovered ore never leaks its name -- MineForge rule 3)

	IT ALL WORKS: the same verbs and the same prices as the live Forge
	(craftOreTool / upgradeOreTool / equipOreTool / recycleOreTool;
	MineConfig.toolCraftCost / toolUpgradeCost / toolRecycle), read off the same
	snapshot. Recycling asks twice.

	THEMES: "molten" (dark stone and iron, lava glow, rising embers) and
	"candy" (indigo with bright candy colours and twinkling sparkles).

	mount(gui, opts) -> { open(), close(), isOpen(), refresh(), root }
	  opts.theme      "molten" | "candy"
	  opts.getSnap()  the latest snapshot
	  opts.send(verb, payload)
]]
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared:WaitForChild("MineConfig"))
local OreTools = require(shared:WaitForChild("MineOreTools"))
local OreIcons = require(shared:WaitForChild("MineOreIcons"))
local Cards = require(shared:WaitForChild("MineCards"))

local okCel, Celebrate = pcall(function()
	return require(shared:WaitForChild("MineCelebrate", 5))
end)
if not okCel then
	Celebrate = nil
end

local okFactory, Factory = pcall(function()
	return require(RS:WaitForChild("ToolModelFactory", 10))
end)
if not okFactory then
	Factory = nil
end

local Demo = {}

local FONT = Enum.Font.FredokaOne
local FONT_B = Enum.Font.GothamBlack
local FONT_M = Enum.Font.GothamBold

-- ---------------------------------------------------------------- themes --
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

Demo.THEMES = {
	molten = {
		name = "molten",
		title = "FORGE",
		bg = { rgb(34, 20, 14), rgb(14, 8, 6) },
		floorGlow = rgb(255, 96, 20),
		panel = rgb(38, 32, 30),
		panel2 = rgb(56, 46, 42),
		edge = rgb(255, 128, 40),
		outline = rgb(12, 6, 4),
		text = rgb(255, 244, 230),
		muted = rgb(214, 170, 140),
		titleGrad = { rgb(255, 238, 140), rgb(255, 120, 20) },
		action = { rgb(255, 196, 70), rgb(230, 70, 20) },
		tabOn = { rgb(255, 170, 60), rgb(220, 70, 20) },
		tabOff = rgb(60, 50, 46),
		chip = rgb(24, 18, 16),
		fx = "embers",
		famColors = {
			pickaxe = rgb(255, 150, 60), hammer = rgb(230, 90, 50), drill = rgb(255, 200, 80),
			jackhammer = rgb(200, 120, 90), explosive = rgb(255, 80, 60),
		},
		anvil = rgb(46, 44, 50),
		pedestal = rgb(70, 30, 18),
	},
	candy = {
		name = "candy",
		title = "FORGE",
		bg = { rgb(78, 42, 170), rgb(28, 16, 74) },
		floorGlow = rgb(255, 120, 230),
		panel = rgb(52, 34, 128),
		panel2 = rgb(74, 52, 168),
		edge = rgb(255, 214, 90),
		outline = rgb(20, 12, 44),
		text = rgb(255, 255, 255),
		muted = rgb(200, 190, 255),
		titleGrad = { rgb(255, 236, 120), rgb(255, 150, 40) },
		action = { rgb(255, 226, 110), rgb(255, 150, 30) },
		tabOn = { rgb(255, 130, 235), rgb(180, 60, 220) },
		tabOff = rgb(70, 50, 150),
		chip = rgb(30, 20, 80),
		fx = "sparkles",
		famColors = {
			pickaxe = rgb(120, 235, 255), hammer = rgb(255, 130, 235), drill = rgb(140, 245, 110),
			jackhammer = rgb(255, 190, 110), explosive = rgb(255, 130, 130),
		},
		anvil = rgb(120, 110, 200),
		pedestal = rgb(255, 120, 220),
	},
}

local FAMILY_ICON = { pickaxe = "⛏", hammer = "🔨", drill = "🌀", jackhammer = "⚙", explosive = "💣" }
local FAMILY_NAME = { pickaxe = "Pickaxes", hammer = "Hammers", drill = "Drills", jackhammer = "Jackhammers", explosive = "Explosives" }

-- ---------------------------------------------------------------- helpers --
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
	mk("UICorner", { CornerRadius = UDim.new(0, r or 12) }, o)
	return o
end

local function stroke(o, color, th, transparency)
	return mk("UIStroke", { Color = color, Thickness = th or 3, Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end

local function grad(o, a, b, rot)
	return mk("UIGradient", { Color = ColorSequence.new(a, b), Rotation = rot or 90 }, o)
end

local function text(parent, str, size, color, props)
	local l = mk("TextLabel", {
		BackgroundTransparency = 1, Text = str or "", TextSize = size or 18, TextColor3 = color or Color3.new(1, 1, 1),
		Font = FONT, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center,
	}, parent)
	for k, v in pairs(props or {}) do
		l[k] = v
	end
	return l
end

-- Outlined text: a dark stroke so white reads on any colour.
local function ink(label, color, th)
	mk("UIStroke", { Color = color, Thickness = th or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, label)
	return label
end

local function short(n)
	n = tonumber(n) or 0
	for _, u in ipairs({ { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
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

--[[
	A PILL BUTTON. The gradient sits on a Fill frame under the label, never on
	the button: a UIGradient on a TextButton tints its TEXT too, which is why the
	first draft's white "UPGRADE" read as dark grey.
]]
local juice
local function pill(parent, label, a, b, size, outline, z, textSize, radius)
	z = z or 75
	local btn = mk("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = size, ZIndex = z }, parent)
	local fill = mk("Frame", { Name = "Fill", BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1), ZIndex = z }, btn)
	round(fill, radius or 18)
	local g = grad(fill, a, b, 90)
	stroke(fill, outline, 3)
	-- a soft shine across the top half
	local shine = mk("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.82, Position = UDim2.fromOffset(6, 4),
		Size = UDim2.new(1, -12, 0.42, 0), ZIndex = z }, fill)
	round(shine, (radius or 18) - 4)
	local l = text(btn, label, textSize or 26, Color3.new(1, 1, 1), { ZIndex = z + 1 })
	ink(l, outline, 2)
	juice(btn)
	return btn, l, g
end

-- Juicy press: grow on hover, squash on press.
function juice(btn)
	local sc = mk("UIScale", {}, btn)
	local function to(v, t)
		TweenService:Create(sc, TweenInfo.new(t or 0.12, Enum.EasingStyle.Back), { Scale = v }):Play()
	end
	btn.MouseEnter:Connect(function()
		to(1.06)
	end)
	btn.MouseLeave:Connect(function()
		to(1)
	end)
	btn.MouseButton1Down:Connect(function()
		to(0.92, 0.06)
	end)
	btn.MouseButton1Up:Connect(function()
		to(1.06)
	end)
	return sc
end

-- -------------------------------------------------------------- the data --
-- The same reading of the snapshot as the live Forge (MineForge allRecipes / ownedOf).
local function recipes(snap, fam)
	local held, seen = snap.ores or {}, snap.oresSeen
	local out = {}
	for _, def in ipairs(C.ORES or {}) do
		local have = tonumber(held[def.id]) or 0
		local discovered = (type(seen) == "table") and (seen[def.id] and true or false) or have > 0
		local cost = C.toolCraftCost(def.tier, OreTools.typeMult(fam, def.tier), fam)
		table.insert(out, { id = def.id, def = def, tier = def.tier, name = def.name, have = have, cost = cost,
			locked = not discovered, afford = discovered and have >= cost })
	end
	table.sort(out, function(a, b)
		local ra = a.afford and 0 or (a.locked and 2 or 1)
		local rb = b.afford and 0 or (b.locked and 2 or 1)
		if ra ~= rb then
			return ra < rb
		end
		if a.tier ~= b.tier then
			return a.tier > b.tier
		end
		return tostring(a.id) < tostring(b.id)
	end)
	return out
end

local function owned(snap, fam)
	local out = {}
	for _, t in ipairs(snap.oreTools or {}) do
		if type(t) == "table" and t.uid and (t.familyId or "pickaxe") == fam then
			table.insert(out, t)
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

local function oreOfTier(tier)
	for _, def in ipairs(C.ORES or {}) do
		if def.tier == tier then
			return def
		end
	end
	return nil
end

local function toolTitle(fam, def)
	local ok, name = pcall(OreTools.name, def, fam)
	return ok and name or ((def and def.name or "?") .. " " .. (FAMILY_NAME[fam] or fam))
end

-- ================================================================== mount ==
function Demo.mount(gui, opts)
	opts = opts or {}
	local th = Demo.THEMES[opts.theme or "molten"] or Demo.THEMES.molten
	local send = opts.send or function() end
	local getSnap = opts.getSnap or function()
		return nil
	end
	local ctl = {}
	local tab, fam = "craft", "pickaxe"
	local selected -- a recipe row (craft) or an owned tool (upgrade / recycle)
	local confirmRecycle = nil

	local root = mk("Frame", {
		Name = "ForgeDemo_" .. th.name, Visible = false, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(1120, 650),
		BackgroundColor3 = Color3.new(1, 1, 1), ClipsDescendants = true, ZIndex = 70,
	}, gui)
	root:SetAttribute("MineUIAdopted", true)
	round(root, 26)
	grad(root, th.bg[1], th.bg[2], 90)
	stroke(root, th.edge, 4)
	local scale = mk("UIScale", {}, root)
	local function fit()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		scale.Scale = math.clamp(math.min((vp.X - 40) / 1120, (vp.Y - 40) / 650), 0.45, 1.25)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end

	-- A glow along the floor of the window (lava for molten, bubblegum for candy).
	local floor = mk("Frame", { BackgroundColor3 = th.floorGlow, AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 220), ZIndex = 70 }, root)
	mk("UIGradient", { Rotation = 270, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) }) }, floor)

	-- FX: rising embers, or twinkling sparkles.
	local fxLayer = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 71 }, root)
	local motes = {}
	for i = 1, 34 do
		local m = mk("Frame", {
			BackgroundColor3 = (th.fx == "embers") and rgb(255, 140 + math.random(0, 80), 40) or Color3.new(1, 1, 1),
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(math.random(3, 7), math.random(3, 7)),
			Position = UDim2.fromScale(math.random(), math.random()), ZIndex = 71,
		}, fxLayer)
		round(m, 4)
		if th.fx == "sparkles" then
			m.Rotation = 45
		end
		motes[i] = { f = m, x = math.random(), y = math.random(), v = 0.03 + math.random() * 0.08, ph = math.random() * 6 }
	end

	-- -------------------------------------------------------- top bar --
	local title = text(root, "🔨 " .. th.title, 58, Color3.new(1, 1, 1), { Font = FONT, Position = UDim2.fromOffset(28, 10),
		Size = UDim2.fromOffset(330, 70), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 74 })
	grad(title, th.titleGrad[1], th.titleGrad[2], 90)
	ink(title, th.outline, 4)

	local chips = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(380, 20), Size = UDim2.fromOffset(640, 50), ZIndex = 74 }, root)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, chips)
	local function chip(order, icon)
		local c = mk("Frame", { BackgroundColor3 = th.chip, Size = UDim2.fromOffset(170, 48), LayoutOrder = order, ZIndex = 74 }, chips)
		round(c, 24)
		stroke(c, th.edge, 3)
		text(c, icon, 26, Color3.new(1, 1, 1), { Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(40, 48), ZIndex = 75 })
		local v = text(c, "0", 24, th.text, { Position = UDim2.fromOffset(48, 0), Size = UDim2.new(1, -60, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 75 })
		ink(v, th.outline, 2)
		return v
	end
	local coinsV, gemsV, dustV = chip(1, "💰"), chip(2, "💎"), chip(3, "✨")

	local closeBtn = mk("TextButton", { Text = "X", Font = FONT, TextSize = 30, TextColor3 = Color3.new(1, 1, 1),
		BackgroundColor3 = rgb(230, 60, 80), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 18),
		Size = UDim2.fromOffset(54, 54), ZIndex = 76, AutoButtonColor = false }, root)
	round(closeBtn, 27)
	stroke(closeBtn, th.outline, 3)
	juice(closeBtn)

	-- ----------------------------------------------------------- tabs --
	local tabs = {}
	local tabRow = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(196, 88), Size = UDim2.fromOffset(700, 56), ZIndex = 74 }, root)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, tabRow)
	for i, t in ipairs({ { "craft", "🔥 CRAFT" }, { "upgrade", "⬆ UPGRADE" }, { "recycle", "♻ RECYCLE" } }) do
		local b, _, g = pill(tabRow, t[2], th.tabOff, th.tabOff, UDim2.fromOffset(220, 54), th.outline, 75, 26)
		b.LayoutOrder = i
		tabs[t[1]] = { btn = b, grad = g }
	end

	-- ------------------------------------------------------- families --
	local famBtns = {}
	local famCol = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(22, 160), Size = UDim2.fromOffset(160, 470), ZIndex = 74 }, root)
	mk("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, famCol)
	for i, f in ipairs(OreTools.FAMILY_ORDER or { "pickaxe", "hammer", "drill", "jackhammer", "explosive" }) do
		local col = th.famColors[f] or th.edge
		local b = mk("TextButton", { Text = "", BackgroundColor3 = th.panel, Size = UDim2.fromOffset(160, 82), LayoutOrder = i,
			ZIndex = 75, AutoButtonColor = false }, famCol)
		round(b, 18)
		local s = stroke(b, col, 3)
		text(b, FAMILY_ICON[f] or "⛏", 34, Color3.new(1, 1, 1), { Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 44), ZIndex = 76 })
		local l = text(b, FAMILY_NAME[f] or f, 18, th.text, { Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 0, 26), ZIndex = 76 })
		ink(l, th.outline, 2)
		juice(b)
		famBtns[f] = { btn = b, stroke = s, col = col }
	end

	-- --------------------------------------------------------- stage --
	local stage = mk("Frame", { BackgroundColor3 = th.panel, BackgroundTransparency = 0.25, Position = UDim2.fromOffset(198, 160),
		Size = UDim2.fromOffset(450, 470), ZIndex = 72 }, root)
	round(stage, 22)
	stroke(stage, th.edge, 3, 0.35)
	-- The glow behind the tool: light rays turning slowly, under soft rings
	-- (Roblox has no radial gradient, so the falloff is four circles).
	local rays = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(225, 140),
		Size = UDim2.fromOffset(10, 10), ZIndex = 72 }, stage)
	for i = 1, 8 do
		local ray = mk("Frame", { BackgroundColor3 = th.edge, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(26, 380), Rotation = i * 22.5, ZIndex = 72 }, rays)
		mk("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.72), NumberSequenceKeypoint.new(1, 1) }) }, ray)
	end
	local halo = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(225, 140),
		Size = UDim2.fromOffset(250, 250), ZIndex = 72 }, stage)
	for i, ring in ipairs({ { 1, 0.86 }, { 0.78, 0.76 }, { 0.56, 0.64 }, { 0.34, 0.5 } }) do
		local c = mk("Frame", { BackgroundColor3 = th.floorGlow:Lerp(Color3.new(1, 1, 1), (i - 1) * 0.12), BackgroundTransparency = ring[2],
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(ring[1], ring[1]), ZIndex = 72 }, halo)
		round(c, 999)
	end
	-- the pedestal and the anvil, drawn
	local pedestal = mk("Frame", { BackgroundColor3 = th.pedestal, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(225, 252),
		Size = UDim2.fromOffset(220, 22), ZIndex = 73 }, stage)
	round(pedestal, 11)
	stroke(pedestal, th.outline, 3)
	local anvilTop = mk("Frame", { BackgroundColor3 = th.anvil, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromOffset(225, 254),
		Size = UDim2.fromOffset(170, 26), ZIndex = 74 }, stage)
	round(anvilTop, 8)
	stroke(anvilTop, th.outline, 3)
	local vp = mk("ViewportFrame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(225, 136),
		Size = UDim2.fromOffset(320, 270), ZIndex = 75, LightColor = Color3.new(1, 1, 1), Ambient = rgb(170, 160, 150) }, stage)
	local nameL = text(stage, "", 30, th.text, { Position = UDim2.fromOffset(10, 280), Size = UDim2.new(1, -20, 0, 36), TextScaled = true, ZIndex = 75 })
	ink(nameL, th.outline, 3)
	local badge = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(225, 320), Size = UDim2.fromOffset(150, 30), ZIndex = 75 }, stage)
	round(badge, 15)
	stroke(badge, th.outline, 2)
	local badgeL = text(badge, "", 18, Color3.new(1, 1, 1), { ZIndex = 76 })
	ink(badgeL, th.outline, 2)
	local statsL = text(stage, "", 20, th.muted, { Position = UDim2.fromOffset(10, 354), Size = UDim2.new(1, -20, 0, 24), ZIndex = 75 })
	local costRow = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 380), Size = UDim2.new(1, -20, 0, 26), ZIndex = 75 }, stage)
	local costL = text(costRow, "", 20, th.text, { ZIndex = 76 })
	ink(costL, th.outline, 2)
	local actionRow = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(15, 410), Size = UDim2.fromOffset(420, 52), ZIndex = 75 }, stage)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, actionRow)
	local emptyL = text(stage, "", 24, th.muted, { Position = UDim2.fromOffset(20, 180), Size = UDim2.new(1, -40, 0, 80),
		TextWrapped = true, ZIndex = 76 })

	-- ---------------------------------------------------------- grid --
	local gridBox = mk("Frame", { BackgroundColor3 = th.panel, BackgroundTransparency = 0.25, Position = UDim2.fromOffset(662, 160),
		Size = UDim2.fromOffset(436, 470), ZIndex = 72 }, root)
	round(gridBox, 22)
	stroke(gridBox, th.edge, 3, 0.35)
	local grid = mk("ScrollingFrame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -14, 1, -20),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 10,
		ScrollBarImageColor3 = th.edge, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 73 }, gridBox)
	mk("UIGridLayout", { CellSize = UDim2.fromOffset(126, 150), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
	mk("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingBottom = UDim.new(0, 10) }, grid)

	-- ------------------------------------------------------- painting --
	local spin
	local function showModel(fam_, tier, def)
		if spin then
			spin:Disconnect()
			spin = nil
		end
		vp:ClearAllChildren()
		if not (Factory and Factory.build and def) then
			return
		end
		local ok, model = pcall(function()
			local look = Factory.oreLook and Factory.oreLook(def, C.ORE_COUNT or #C.ORES)
			return Factory.build(fam_, tier, C.ORE_COUNT or #C.ORES, look)
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
		local cf, size = model:GetBoundingBox()
		local dist = math.max(size.Magnitude * 0.78, 2.5)
		cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(dist * 0.55, dist * 0.3, dist * 0.8), cf.Position)
		-- Turn about world Y through the centre (see MineForge: the pivot is not upright).
		local cf0 = model:GetPivot()
		local centre = cf.Position
		local angle, t = 0, 0
		spin = RunService.RenderStepped:Connect(function(dt)
			if not vp.Parent or not model.Parent or not root.Visible then
				return
			end
			angle += dt * 0.9
			t += dt
			local bob = math.sin(t * 2) * 0.12
			local about = CFrame.new(centre + Vector3.new(0, bob, 0)) * CFrame.Angles(0, angle, 0) * CFrame.new(-centre)
			model:PivotTo(about * cf0)
		end)
	end

	local function actionButton(label_, colors, enabled, onClick, width)
		local a, c = colors[1], colors[2]
		if not enabled then
			a, c = rgb(90, 86, 96), rgb(60, 56, 66)
		end
		local b, l = pill(actionRow, label_, a, c, UDim2.fromOffset(width or 260, 52), th.outline, 77, 26)
		if not enabled then
			l.TextColor3 = rgb(200, 196, 206)
		end
		if enabled and (width or 260) >= 200 then
			-- a shine sweeps across the big button now and then
			local fill = b:FindFirstChild("Fill")
			if fill then
				fill.ClipsDescendants = true
				local sweep = mk("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55, AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(-0.3, 0, 0.5, 0), Size = UDim2.new(0, 34, 2, 0), Rotation = 20, ZIndex = fill.ZIndex }, fill)
				task.spawn(function()
					while sweep.Parent do
						sweep.Position = UDim2.new(-0.3, 0, 0.5, 0)
						TweenService:Create(sweep, TweenInfo.new(0.7, Enum.EasingStyle.Quad), { Position = UDim2.new(1.3, 0, 0.5, 0) }):Play()
						task.wait(2.2)
					end
				end)
			end
		end
		if enabled then
			-- what pays out always moves
			local sc = b:FindFirstChildOfClass("UIScale")
			task.spawn(function()
				while b.Parent and sc do
					TweenService:Create(sc, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { Scale = 1.04 }):Play()
					task.wait(0.6)
					if not b.Parent then
						break
					end
					TweenService:Create(sc, TweenInfo.new(0.6, Enum.EasingStyle.Sine), { Scale = 1 }):Play()
					task.wait(0.6)
				end
			end)
			b.MouseButton1Click:Connect(onClick)
		end
		return b
	end

	local function paintStage()
		for _, c in ipairs(actionRow:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local snap = getSnap() or {}
		emptyL.Text = ""
		if not selected then
			showModel(nil)
			nameL.Text, badgeL.Text, statsL.Text, costL.Text = "", "", "", ""
			badge.Visible = false
			emptyL.Text = (tab == "craft") and "Pick a recipe →" or "No " .. string.lower(FAMILY_NAME[fam] or fam) .. " yet.\nCraft one first! 🔥"
			return
		end
		badge.Visible = true
		if tab == "craft" then
			local r = selected
			local band, col = rarityOf(r.tier)
			if r.locked then
				showModel(nil)
				nameL.Text = "???"
				badgeL.Text = "LOCKED"
				badge.BackgroundColor3 = rgb(70, 70, 80)
				statsL.Text = "Find this ore to unlock it"
				costL.Text = ""
				return
			end
			showModel(fam, r.tier, r.def)
			nameL.Text = toolTitle(fam, r.def)
			badgeL.Text = string.upper(band)
			badge.BackgroundColor3 = col
			local dmg = C.toolPower(r.tier, 1, OreTools.typeMult(fam, r.tier))
			statsL.Text = string.format("⚔ %s  ·  Lv 1 → %d", short(dmg), C.TOOL_MAX_LEVEL or 30)
			costL.Text = string.format("🪨 %s / %s %s", short(r.have), short(r.cost), r.name)
			costL.TextColor3 = r.afford and rgb(140, 255, 150) or rgb(255, 150, 150)
			local frame = OreTools.frameForTier and OreTools.frameForTier(fam, r.tier)
			actionButton(r.afford and "🔥 FORGE!" or "NEED ORE", th.action, r.afford, function()
				ctl._markCraft(r.tier)
				send("craftOreTool", { familyId = fam, typeId = frame and frame.id or "", oreId = r.id })
			end, 300)
		else
			local tool = selected
			local tier = tonumber(tool.tier) or 1
			local level = tonumber(tool.level) or 1
			local def = oreOfTier(tier)
			local band, col = rarityOf(tier)
			local mult = OreTools.typeMult(fam, tier)
			showModel(fam, tier, def)
			local okN, nm = false, nil
			if OreTools.toolName then
				okN, nm = pcall(OreTools.toolName, tool)
			end
			nameL.Text = (okN and type(nm) == "string" and nm ~= "") and nm or toolTitle(fam, def)
			badgeL.Text = string.upper(band) .. "  ·  Lv " .. level
			badge.BackgroundColor3 = col
			statsL.Text = string.format("⚔ %s", short(C.toolPower(tier, level, mult)))
			local equipped = snap.oreToolEquipped == tool.uid
			if tab == "upgrade" then
				local ore, dust = C.toolUpgradeCost(tier, level, mult, fam)
				if not ore then
					costL.Text = "⭐ MAX LEVEL"
					costL.TextColor3 = th.text
				else
					local have = def and tonumber((snap.ores or {})[def.id]) or 0
					local dustHave = tonumber(snap.dust) or 0
					local ok = have >= ore and dustHave >= (dust or 0)
					costL.Text = string.format("🪨 %s/%s   ✨ %s/%s", short(have), short(ore), short(dustHave), short(dust or 0))
					costL.TextColor3 = ok and rgb(140, 255, 150) or rgb(255, 150, 150)
					actionButton("⬆ +1", th.action, ok, function()
						send("upgradeOreTool", { uid = tool.uid, count = 1 })
					end, 120)
					actionButton("+10", th.action, ok, function()
						send("upgradeOreTool", { uid = tool.uid, count = 10 })
					end, 110)
				end
				actionButton(equipped and "✅ HELD" or "EQUIP", th.tabOn, not equipped, function()
					send("equipOreTool", { uid = tool.uid })
				end, 140)
			else
				local ore, dust = C.toolRecycle(tier, level, mult, 1)
				costL.Text = string.format("Get back: 🪨 %s  ✨ %s", short(ore), short(dust))
				costL.TextColor3 = th.text
				local sure = confirmRecycle == tool.uid
				actionButton(sure and "SURE? TAP AGAIN" or "♻ RECYCLE", { rgb(255, 120, 120), rgb(200, 40, 60) }, not equipped, function()
					if confirmRecycle == tool.uid then
						confirmRecycle = nil
						selected = nil
						send("recycleOreTool", { uid = tool.uid })
					else
						confirmRecycle = tool.uid
						paintStage()
					end
				end, 320)
				if equipped then
					statsL.Text ..= "   ·   held (can't recycle)"
				end
			end
		end
	end

	local function card(order, opts2)
		local b = mk("TextButton", { Text = "", BackgroundColor3 = opts2.locked and rgb(40, 38, 48) or th.panel2, LayoutOrder = order,
			ZIndex = 74, AutoButtonColor = false }, grid)
		round(b, 16)
		local s = stroke(b, opts2.locked and rgb(80, 78, 90) or opts2.col, opts2.selected and 5 or 3)
		if opts2.glow and not opts2.locked then
			grad(b, th.panel2:Lerp(opts2.col, 0.35), th.panel2, 90)
		end
		if not opts2.locked then
			-- the ore itself: a cut gem in its own colour, with a shine
			local nug = mk("Frame", { BackgroundColor3 = opts2.oreColor or opts2.col, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(63, 44), Size = UDim2.fromOffset(44, 44), Rotation = 45, ZIndex = 75 }, b)
			round(nug, 10)
			stroke(nug, th.outline, 3)
			mk("UIGradient", { Rotation = 45, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(110, 110, 110)) }, nug)
			local sh = mk("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.35, Position = UDim2.fromOffset(8, 8),
				Size = UDim2.fromOffset(12, 6), ZIndex = 76 }, nug)
			round(sh, 3)
		end
		local icon = opts2.icon and mk("ImageLabel", { BackgroundTransparency = 1, Image = opts2.icon, AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromOffset(63, 10), Size = UDim2.fromOffset(64, 64), ZIndex = 75 }, b)
		if opts2.locked then
			text(b, "❓", 44, Color3.new(1, 1, 1), { Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 64), ZIndex = 75 })
		end
		local _ = icon
		if not opts2.locked then
			local swatch = mk("Frame", { BackgroundColor3 = opts2.oreColor or opts2.col, Position = UDim2.fromOffset(10, 10),
				Size = UDim2.fromOffset(14, 14), ZIndex = 76 }, b)
			round(swatch, 7)
			stroke(swatch, th.outline, 2)
		end
		local n = text(b, opts2.locked and "???" or opts2.name, 16, th.text, { Position = UDim2.fromOffset(6, 78), Size = UDim2.new(1, -12, 0, 20),
			TextScaled = true, ZIndex = 75 })
		ink(n, th.outline, 2)
		local foot = text(b, opts2.foot or "", 16, opts2.footColor or th.muted, { Position = UDim2.fromOffset(4, 102), Size = UDim2.new(1, -8, 0, 20),
			TextScaled = true, ZIndex = 75 })
		ink(foot, th.outline, 1.5)
		if opts2.ready then
			local dot = mk("Frame", { BackgroundColor3 = rgb(110, 255, 140), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8),
				Size = UDim2.fromOffset(16, 16), ZIndex = 77 }, b)
			round(dot, 8)
			stroke(dot, th.outline, 2)
		end
		juice(b)
		local _ = s
		b.MouseButton1Click:Connect(opts2.onClick)
		return b
	end

	local function paintGrid()
		for _, c in ipairs(grid:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local snap = getSnap() or {}
		if tab == "craft" then
			local list = recipes(snap, fam)
			if selected and selected.id then
				for _, r in ipairs(list) do
					if r.id == selected.id then
						selected = r
					end
				end
			elseif not selected then
				selected = list[1]
			end
			for i, r in ipairs(list) do
				local band, col = rarityOf(r.tier)
				local _ = band
				card(i, {
					locked = r.locked, col = col, glow = true, name = r.name,
					icon = (not r.locked) and OreIcons.icon(r.id) or nil, oreColor = r.def.color,
					foot = r.locked and "" or (short(r.have) .. "/" .. short(r.cost)),
					footColor = r.afford and rgb(140, 255, 150) or nil,
					ready = r.afford, selected = selected and selected.id == r.id,
					onClick = function()
						selected = r
						paintGrid()
						paintStage()
					end,
				})
			end
		else
			local list = owned(snap, fam)
			if selected and selected.uid then
				local still
				for _, t in ipairs(list) do
					if t.uid == selected.uid then
						still = t
					end
				end
				selected = still
			end
			if not selected then
				selected = list[1]
			end
			for i, t in ipairs(list) do
				local tier = tonumber(t.tier) or 1
				local _, col = rarityOf(tier)
				local def = oreOfTier(tier)
				card(i, {
					col = col, glow = true, name = def and def.name or "?", icon = def and OreIcons.icon(def.id) or nil,
					oreColor = def and def.color, foot = "Lv " .. (tonumber(t.level) or 1) .. ((snap.oreToolEquipped == t.uid) and "  ✅" or ""),
					selected = selected and selected.uid == t.uid,
					onClick = function()
						selected = t
						confirmRecycle = nil
						paintGrid()
						paintStage()
					end,
				})
			end
		end
	end

	local function paintChrome()
		local snap = getSnap() or {}
		coinsV.Text = short(snap.coins)
		gemsV.Text = short(snap.gems)
		dustV.Text = short(snap.dust)
		for id, t in pairs(tabs) do
			local on = id == tab
			t.grad.Color = on and ColorSequence.new(th.tabOn[1], th.tabOn[2]) or ColorSequence.new(th.tabOff, th.tabOff)
		end
		for f, b in pairs(famBtns) do
			local on = f == fam
			b.btn.BackgroundColor3 = on and th.panel2:Lerp(b.col, 0.45) or th.panel
			b.stroke.Thickness = on and 5 or 3
		end
	end

	-- A new tool landing (after FORGE!) celebrates by its rarity.
	local lastCount, pendingCraft = nil, nil
	local BAND_TIER = { Common = 0, Uncommon = 1, Rare = 1, Epic = 2, Legendary = 3, Mythic = 3, Divine = 4, Exotic = 4 }
	local function celebrateNew()
		local snap = getSnap() or {}
		local n = #(snap.oreTools or {})
		if lastCount and n > lastCount and pendingCraft then
			local band = rarityOf(pendingCraft)
			if Celebrate and Celebrate.burst then
				pcall(Celebrate.burst, math.max(1, BAND_TIER[band] or 1))
			end
			pendingCraft = nil
		end
		lastCount = n
	end
	ctl._markCraft = function(tier)
		pendingCraft = tier
	end

	function ctl.refresh()
		if not root.Visible then
			return
		end
		celebrateNew()
		paintChrome()
		paintGrid()
		paintStage()
	end

	for id, t in pairs(tabs) do
		t.btn.MouseButton1Click:Connect(function()
			if tab ~= id then
				tab = id
				selected = nil
				confirmRecycle = nil
				ctl.refresh()
			end
		end)
	end
	for f, b in pairs(famBtns) do
		b.btn.MouseButton1Click:Connect(function()
			if fam ~= f then
				fam = f
				selected = nil
				confirmRecycle = nil
				ctl.refresh()
			end
		end)
	end

	-- --------------------------------------------------------- motion --
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
				if th.fx == "embers" then
					m.y -= m.v * dt
					if m.y < -0.03 then
						m.y, m.x = 1.03, math.random()
					end
					m.f.Position = UDim2.fromScale(m.x + math.sin(t0 * 1.3 + m.ph) * 0.01, m.y)
					m.f.BackgroundTransparency = 0.15 + 0.6 * (1 - m.y)
				else
					local tw = (math.sin(t0 * 3 + m.ph) + 1) * 0.5
					m.f.BackgroundTransparency = 0.1 + 0.85 * (1 - tw)
					m.f.Size = UDim2.fromOffset(3 + tw * 6, 3 + tw * 6)
				end
			end
			-- the halo breathes, the rays turn
			halo.Size = UDim2.fromOffset(250 + math.sin(t0 * 2) * 20, 250 + math.sin(t0 * 2) * 20)
			rays.Rotation = (t0 * 12) % 360
		end)
	end

	function ctl.open()
		root.Visible = true
		fit()
		root.Size = UDim2.fromOffset(1120, 650)
		scale.Scale = scale.Scale * 0.85
		TweenService:Create(scale, TweenInfo.new(0.28, Enum.EasingStyle.Back), { Scale = scale.Scale / 0.85 }):Play()
		startFx()
		ctl.refresh()
	end

	function ctl.close()
		root.Visible = false
		if spin then
			spin:Disconnect()
			spin = nil
		end
	end

	function ctl.isOpen()
		return root.Visible
	end

	closeBtn.MouseButton1Click:Connect(ctl.close)
	ctl.root = root
	return ctl
end

return Demo
