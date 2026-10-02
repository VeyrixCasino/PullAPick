--[[
	MineInventoryView -- one window for everything you own and everything you are
	still collecting.

	Sections run down the left, tabs run across the top, which is the shape every
	player already knows from every other game with an inventory in it:

		Inventory   Equipment / Packs / Cards / Potions / VFX
		Collection  Chests / Packs / Cards / Equipment / Runes
		Shop        Home / Build Box / Limited / Packs / Credits / VIP
		Pass

	The card art is not drawn here. The caller passes in its own `paintCard`, so
	there is exactly one card renderer in the game and this window cannot drift
	away from the one the pack reveal uses.
]]
local MineInventoryView = {}

local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared:WaitForChild("MineConfig"))
local Cards = require(shared:WaitForChild("MineCards"))
-- Same art the opening ceremony wears, so the tile and the wrapper match.
local PackFX = require(shared:WaitForChild("MinePackFX"))
local Gear = require(shared:WaitForChild("MineGear"))
local Irid = require(shared:WaitForChild("MineIridescence"))
-- Pack definitions, prices and odds. 21 call sites depend on this; it went
-- missing during an edit and the module still loaded cleanly, because a nil
-- upvalue only errors when something indexes it -- which here is mount(), not
-- the module body. A require check alone will not catch that class of break.
local Packs = require(shared:WaitForChild("MinePackConfig"))
local Tools = require(shared:WaitForChild("MineTools"))
local Icons = require(shared:WaitForChild("MineIcons"))
local ToolIcons = require(shared:WaitForChild("MineToolIcons"))
local NG = nil
pcall(function()
	NG = require(RS:WaitForChild("Mine"):WaitForChild("NewGear"):WaitForChild("Catalog"))
end)
local Factory = nil
pcall(function()
	Factory = require(RS:WaitForChild("ToolModelFactory"))
end)
local RotatingOffers = nil
pcall(function()
	RotatingOffers = require(shared:WaitForChild("MineRotatingOffers"))
end)

local T = require(game:GetService("ReplicatedStorage").Mine.Shared:WaitForChild("MineTheme"))
local Scrolls = require(game:GetService("ReplicatedStorage").Mine.Shared:WaitForChild("MineScrolls"))
local FONT = T.FONT
local FONT_M = T.FONT_M
local BG = T.BG
local BG2 = T.BG2
local BG3 = T.BG3
local TEXT = T.TEXT
local MUTED = T.MUTED
local GOLD = T.GOLD
local GEM = T.GEM
local GREEN = T.GREEN

local SECTIONS = {
	-- Equipment first: it is what the Inventory button is for. Gear, Charms and
	-- Runes had tabs here once; gear and charms are slots on the Equipment
	-- screen now, and runes belong to the Enchanter (Collection -> Runes still
	-- lists every one you own).
	{ id = "inventory", label = "Inventory", tabs = {
		{ id = "tools", label = "Equipment" },
		-- Socketing is not a purchase, so it does not belong behind a walk to the
		-- Enchanter. Buying runes and gear still does, and that half stays there.
		{ id = "runes", label = "Runes" },
		{ id = "packs", label = "Packs" },
		{ id = "cards", label = "Cards" },
		{ id = "potions", label = "Potions" },
		{ id = "vfx", label = "VFX" },
	} },
	{ id = "collection", label = "Collection", tabs = {
		{ id = "chests", label = "Chests" },
		{ id = "packs", label = "Packs" },
		{ id = "cards", label = "Cards" },
		{ id = "equipment", label = "Equipment" },
		{ id = "hats", label = "Hats" },
		{ id = "faces", label = "Faces" },
		{ id = "runes", label = "Runes" },
	} },
	{ id = "shop", label = "Shop", tabs = {
		{ id = "home", label = "Home" },
		{ id = "box", label = "Build Box" },
		{ id = "limited", label = "Limited" },
		{ id = "packs", label = "Packs" },
		{ id = "dust", label = "Stardust" },
		{ id = "currencies", label = "Credits" },
		{ id = "vip", label = "VIP" },
	} },
	{ id = "pass", label = "Pass", tabs = {
		{ id = "pass", label = "Pass" },
	} },
	{ id = "daily", label = "Daily", tabs = {
		{ id = "daily", label = "Daily" },
	} },
	{ id = "account", label = "Account", tabs = {
		{ id = "account", label = "Account" },
	} },
}

-- Sorting the cards. One row of chips, the same eight the binder had, because a
-- collection you cannot order is a pile.
local SORTS = {
	{ id = "rarity", label = "Rarity" },
	{ id = "equipped", label = "Team" },
	{ id = "qty", label = "Qty" },
	{ id = "boosts", label = "Boosts" },
	{ id = "recent", label = "New" },
	{ id = "set", label = "Set" },
	{ id = "alpha", label = "A-Z" },
	{ id = "type", label = "Type" },
	{ id = "power", label = "Power" },
	{ id = "variant", label = "Var" },
}

-- Cards tab: which team seat EQUIP fills next. Kept out of mount() so a
-- snapshot cannot throw you back to seat 1 mid-click.
local cardPetSeat = 1

--[[
	Grids centre their tiles unless a caller says otherwise. Left-aligned rows
	sat in the top-left of a very wide window with a screen of empty brown to
	the right of them; the shop is a shelf, and a shelf is centred.
]]
local function mk(class, props, parent)
	local o = Instance.new(class)
	-- Roblox defaults every GuiObject to a 1px border, and that border is drawn
	-- OUTSIDE the UICorner radius -- so on a rounded dark panel it shows up as a
	-- pale hairline poking out at every corner. That is the "white borders", and
	-- there was no way to switch it off because nothing ever set it. Off by
	-- default now; a caller that genuinely wants one still passes it explicitly.
	if props and props.BorderSizePixel == nil and o:IsA("GuiObject") then
		o.BorderSizePixel = 0
	end
	for k, v in pairs(props) do
		o[k] = v
	end
	if class == "UIGridLayout" and props.HorizontalAlignment == nil then
		o.HorizontalAlignment = Enum.HorizontalAlignment.Center
	end
	o.Parent = parent
	return o
end

local function round(o, r)
	local u = Instance.new("UICorner")
	u.CornerRadius = UDim.new(0, r or 8)
	u.Parent = o
	return u
end

local function stroke(o, t, col)
	local s = Instance.new("UIStroke")
	s.Thickness = t or 1
	s.Color = col or Color3.fromRGB(70, 70, 84)
	s.Transparency = 0.35
	s.Parent = o
	return s
end

local function shortNum(n)
	n = math.floor(tonumber(n) or 0)
	if n < 1000 then
		return tostring(n)
	end
	for _, u in ipairs({ { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
		if n >= u[1] then
			local v = n / u[1]
			return string.format(v >= 100 and "%.0f%s" or "%.1f%s", v, u[2])
		end
	end
	return tostring(n)
end

-- Prefix + currency icon + amount on a button (BUY / ADD / CONFIRM).
local function paintCostButton(btn, prefix, amount, currencyId, textColor)
	btn.Text = ""
	for _, c in ipairs(btn:GetChildren()) do
		if c.Name == "CostPrefix" or c.Name == "PriceChip" then
			c:Destroy()
		end
	end
	local col = textColor or btn.TextColor3
	mk("TextLabel", {
		Name = "CostPrefix",
		BackgroundTransparency = 1,
		Font = btn.Font,
		TextSize = btn.TextSize,
		TextColor3 = col,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = prefix or "",
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(0.5, -4, 1, 0),
		ZIndex = (btn.ZIndex or 1) + 1,
	}, btn)
	if amount ~= nil then
		Icons.priceChip(btn, currencyId or "credits", shortNum(amount), {
			position = UDim2.new(1, -8, 0.5, 0),
			anchor = Vector2.new(1, 0.5),
			iconSize = math.max(14, math.floor((btn.TextSize or 14) + 2)),
			textSize = btn.TextSize,
			textColor = col,
			font = btn.Font,
			zIndex = (btn.ZIndex or 1) + 1,
		})
	end
end

-- A percentage the way a player writes it: 4%, 0.8%, 0.05%.
local function pct(x)
	x = tonumber(x) or 0
	if x >= 10 then
		return string.format("%d%%", math.floor(x + 0.5))
	elseif x >= 1 then
		return string.format("%.1f%%", x)
	end
	return (string.format("%.2f%%", x):gsub("0+%%$", "%%"):gsub("%.%%", "%%"))
end

local function label(parent, text, size, colour, pos, sz, font, align)
	return mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = font or FONT_M,
		TextSize = size or 14,
		TextColor3 = colour or TEXT,
		Text = text,
		Position = pos or UDim2.fromOffset(0, 0),
		Size = sz or UDim2.new(1, 0, 0, size or 14),
		TextXAlignment = align or Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent)
end

-- A full-width card of content. Everything in the body is one of these.
local function panelRow(parent, height, order)
	local f = mk("Frame", {
		BackgroundColor3 = BG2,
		Size = UDim2.new(1, -6, 0, height),
		LayoutOrder = order or 1,
	}, parent)
	round(f, 8)
	stroke(f, 1)
	return f
end

local function note(parent, text, order)
	local f = panelRow(parent, 46, order)
	label(f, text, 14, MUTED, UDim2.fromOffset(14, 0), UDim2.new(1, -28, 1, 0))
	return f
end

-- `eq` is the equipped lookup; ties always fall back to the name so the order
-- is stable and a card does not jump around between renders.
--[[
	A strip of tabs or chips that fits any screen. Fixed-width buttons in a
	plain Frame ran off the end: eight 112px inventory tabs are wider than the
	content area on a laptop, never mind a phone, and the last ones were simply
	cut off. A strip is a sideways ScrollingFrame whose buttons are as wide as
	their labels; if they still do not fit, the row scrolls (drag it on a
	phone, wheel or bar on a desktop) instead of hiding anything.
]]
local function stripOf(parent, name, padding)
	local s = mk("ScrollingFrame", {
		Name = name,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 4,
		ScrollBarImageTransparency = 0.35,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		Active = true,
	}, parent)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, padding or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	}, s)
	return s
end

--[[
	Five stars filled to a fraction, centred on `parent`.

	Two rows of the same glyphs, grey under gold, with the gold row clipped to
	the rating -- so three and a half stars is exactly three and a half rather
	than a rounded three. Ratings come from MinePackConfig.packStars /
	MineLuckyBlocks.blockStars.
]]
local function starRow(parent, rating, yOffset, textSize)
	textSize = textSize or 14
	local width = math.floor(textSize * 5.1)
	local holder = mk("Frame", {
		Name = "Stars",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, yOffset),
		Size = UDim2.fromOffset(width, textSize + 2),
		ZIndex = 6,
	}, parent)
	local function glyphs(colour, z)
		return mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, Text = "★★★★★", TextSize = textSize,
			TextColor3 = colour, TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromOffset(width, textSize + 2), ZIndex = z,
		}, nil)
	end
	local back = glyphs(Color3.fromRGB(72, 72, 84), 6)
	back.Parent = holder
	local fill = math.clamp((tonumber(rating) or 0) / 5, 0, 1)
	if fill > 0 then
		local clip = mk("Frame", {
			BackgroundTransparency = 1, ClipsDescendants = true,
			Size = UDim2.fromOffset(math.floor(width * fill + 0.5), textSize + 2), ZIndex = 7,
		}, holder)
		local front = glyphs(GOLD, 7)
		front.Parent = clip
	end
	return holder
end

-- As wide as its label plus padding, and never narrower than `minWidth`.
local function fitButton(b, pad, minWidth)
	b.AutomaticSize = Enum.AutomaticSize.X
	mk("UIPadding", { PaddingLeft = UDim.new(0, pad), PaddingRight = UDim.new(0, pad) }, b)
	mk("UISizeConstraint", { MinSize = Vector2.new(minWidth, 0) }, b)
	return b
end

local function cardLess(a, b, mode, eq, indexOf, qtyOf)
	local function boostOf(card)
		if Cards.boostScore then
			return Cards.boostScore(card)
		end
		return (C.cardPower and C.cardPower(card)) or 0
	end
	local function finishOf(card)
		local v = (Cards.VARIANT_RANK and Cards.VARIANT_RANK[card.variant or "Normal"]) or 0
		v += (card.shadow and 10) or (card.shiny and 5) or 0
		return v
	end
	if mode == "equipped" then
		local ea, eb = eq[a.id] and 1 or 0, eq[b.id] and 1 or 0
		if ea ~= eb then
			return ea > eb
		end
		local sa, sb = boostOf(a), boostOf(b)
		if sa ~= sb then
			return sa > sb
		end
	elseif mode == "rarity" then
		local ra = (Cards.RARITY_RANK and Cards.RARITY_RANK[a.rarityId]) or 0
		local rb = (Cards.RARITY_RANK and Cards.RARITY_RANK[b.rarityId]) or 0
		if ra ~= rb then
			return ra > rb
		end
		local sa, sb = boostOf(a), boostOf(b)
		if sa ~= sb then
			return sa > sb
		end
	elseif mode == "recent" then
		-- Later in the list means more recently minted.
		return (indexOf[a] or 0) > (indexOf[b] or 0)
	elseif mode == "set" then
		local sa, sb = tostring(a.setName or a.setId or ""), tostring(b.setName or b.setId or "")
		if sa ~= sb then
			return sa < sb
		end
		if (a.index or 0) ~= (b.index or 0) then
			return (a.index or 0) < (b.index or 0)
		end
	elseif mode == "type" then
		local ta, tb = tostring(a.typeId or ""), tostring(b.typeId or "")
		if ta ~= tb then
			return ta < tb
		end
	elseif mode == "power" or mode == "boosts" then
		local sa, sb = boostOf(a), boostOf(b)
		if sa ~= sb then
			return sa > sb
		end
	elseif mode == "variant" then
		local va, vb = finishOf(a), finishOf(b)
		if va ~= vb then
			return va > vb
		end
	elseif mode == "qty" then
		local ka = tostring(a.cardKey) .. "|" .. tostring(a.rarityId) .. "|" .. tostring(a.variant or "Normal")
		local kb = tostring(b.cardKey) .. "|" .. tostring(b.rarityId) .. "|" .. tostring(b.variant or "Normal")
		local ca = (qtyOf and qtyOf[ka]) or 0
		local cb = (qtyOf and qtyOf[kb]) or 0
		if ca ~= cb then
			return ca > cb
		end
	end
	return tostring(a.name or "") < tostring(b.name or "")
end

local function toolGradeOf(item)
	if not item then
		return nil
	end
	local r = item.rarity or (item.def and item.def.rarity)
	if r and Cards.RARITY_COLOR and Cards.RARITY_COLOR[r] then
		return r
	end
	if r and Gear.RARITY_COLOR and Gear.RARITY_COLOR[r] then
		return r
	end
	local def = item.def
	local drop = def and def.drop
	if drop and Tools.chestRarityFromDrop then
		return Tools.chestRarityFromDrop(drop)
	end
	local power = def and def.power
	if Tools.rarityForPower then
		return Tools.rarityForPower(power)
	end
	return r
end

-- Prepared tool models, keyed name|finish|family|tier. See paintToolViewport.
local TOOL_MODEL_CACHE = {}
--[[
	The cache holds more than the prewarm will ever put in it, on purpose.

	/admin alltools can hand a profile 1,624 tools. With a 220 ceiling and a
	prewarm that walked every one of them, the cache would fill, flush, refill
	and flush again for the whole session -- every flush throwing away work that
	was about to be used. The warm pass stops at PREWARM_MAX and the cache holds
	comfortably more, so it fills once and stays filled.
]]
local TOOL_CACHE_MAX = 320
local TOOL_PREWARM_MAX = 240
local TOOL_MODEL_CACHE_N = 0
local preparedToolModel

preparedToolModel = function(name, finish, family, tier)
	local key = table.concat({ name, finish, family, tostring(tier) }, "|")
	local model
	local master = TOOL_MODEL_CACHE[key]
	if master then
		model = master:Clone()
	else
		if Factory.fromNamed and name ~= "" and name ~= "UNNAMED" then
			local ok, m = pcall(Factory.fromNamed, name, finish, family)
			if ok then
				model = m
			end
			if not model and finish ~= "Normal" then
				ok, m = pcall(Factory.fromNamed, name, "Normal", family)
				if ok then
					model = m
				end
			end
		end
		if not model and Factory.build then
			local ok, m = pcall(Factory.build, family, math.max(1, tier))
			if ok then
				model = m
			end
		end
		if not model then
			return false
		end
		if finish ~= "Normal" and Factory.applyFinish then
			pcall(Factory.applyFinish, model, finish)
		end
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("PackageLink") or d:IsA("ParticleEmitter") or d:IsA("Beam")
				or d:IsA("Trail") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Light") then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
				d.CastShadow = false
			end
		end
		model:PivotTo(CFrame.identity)
		local handle = model:FindFirstChild("Handle", true)
		if handle and handle:IsA("BasePart") then
			local s = handle.Size
			local localAxis = (s.X >= s.Y and s.X >= s.Z and Vector3.xAxis)
				or (s.Y >= s.Z and Vector3.yAxis)
				or Vector3.zAxis
			local shaft = handle.CFrame:VectorToWorldSpace(localAxis)
			if shaft.Magnitude > 1e-4 then
				shaft = shaft.Unit
				local axis = shaft:Cross(Vector3.yAxis)
				local dot = math.clamp(shaft:Dot(Vector3.yAxis), -1, 1)
				if axis.Magnitude > 1e-4 then
					model:PivotTo(CFrame.fromAxisAngle(axis.Unit, math.acos(dot)))
				elseif dot < 0 then
					model:PivotTo(CFrame.Angles(math.pi, 0, 0))
				end
			end
		end
		-- The master never enters the tree; every tile gets a clone of it.
		TOOL_MODEL_CACHE[key] = model
		TOOL_MODEL_CACHE_N += 1
		if TOOL_MODEL_CACHE_N > TOOL_CACHE_MAX then
			for k, v in pairs(TOOL_MODEL_CACHE) do
				v:Destroy()
				TOOL_MODEL_CACHE[k] = nil
			end
			TOOL_MODEL_CACHE_N = 0
		end
		model = model:Clone()
	end
	return model
end

--[[
	WARM THE TOOL CACHE AT LOAD.

	The cache makes every render after the first one cheap, but the FIRST open
	still paid the full build for each distinct tool -- and that is the open
	that matters, because it is the one a new player does.

	So warm it while they are still walking to the pit: one tool per frame on
	Heartbeat, never in a block. The point is to remove a hitch, not to move it
	to startup. Runs once per session, off the first snapshot that arrives.
]]
local warmedTools = false
local function prewarmTools(s)
	if warmedTools or type(s) ~= "table" then
		return
	end
	warmedTools = true
	task.spawn(function()
		local RunService = game:GetService("RunService")
		local seen, built = {}, 0
		for _, row in ipairs(s.chestTools or {}) do
			if built >= TOOL_PREWARM_MAX then
				break
			end
			if type(row) == "table" and type(row.name) == "string" and row.name ~= "" then
				local finish = (row.nightmare and "Nightmare")
					or (row.shadow and "Shadow")
					or (row.shiny and "Shiny")
					or "Normal"
				local fam = row.family or "pickaxe"
				local key = row.name .. "|" .. finish .. "|" .. fam
				if not seen[key] then
					seen[key] = true
					built += 1
					local ok, m = pcall(preparedToolModel, row.name, finish, fam, 1)
					if ok and typeof(m) == "Instance" then
						m:Destroy()
					end
					RunService.Heartbeat:Wait()
				end
			end
		end
	end)
end

local function paintToolViewport(box, item, z)
	if not Factory or not item then
		return false
	end
	local family = item.family or (item.def and item.def.family) or "pickaxe"
	if family ~= "drill" and family ~= "explosive" then
		family = "pickaxe"
	end
	local owned = item.owned
	local finish = "Normal"
	if type(owned) == "table" then
		if owned.nightmare then
			finish = "Nightmare"
		elseif owned.shadow then
			finish = "Shadow"
		elseif owned.shiny then
			finish = "Shiny"
		end
	end
	local name = tostring((item.def and item.def.name) or item.name or "")
	name = string.gsub(name, "^Nightmare ", "")
	name = string.gsub(name, "^Shadow ", "")
	name = string.gsub(name, "^Shiny ", "")
	--[[
		A PREPARED MODEL IS BUILT ONCE AND CLONED.

		Everything from the build down to the upright pivot is deterministic for
		a given (name, finish, family, tier): the same inputs produce the same
		model every time. The inventory was paying for all of it PER TILE on
		every render -- and fromNamed alone runs a clone, a PackageLink rehome,
		a fit, a raycast pose and a weld pass. Measured: 1.14 ms a tile, 55 ms
		for a 48-tile page, scaling with how many tools you own.

		Build once, keep the master out of the tree, hand out clones: 0.12 ms a
		tile, about nine times cheaper.
	]]
	local tier = tonumber(item.tier) or tonumber(item.def and item.def.tier) or 1
	local model = preparedToolModel(name, finish, family, tier)
	if not model then
		return false
	end

	local vp = Instance.new("ViewportFrame")
	vp.Name = "ToolPreview"
	vp.BackgroundTransparency = 1
	vp.BorderSizePixel = 0
	vp.Size = UDim2.fromScale(0.74, 0.74)
	vp.Position = UDim2.fromScale(0.5, 0.52)
	vp.AnchorPoint = Vector2.new(0.5, 0.5)
	vp.Ambient = Color3.fromRGB(168, 174, 196)
	vp.LightColor = Color3.fromRGB(255, 248, 232)
	vp.LightDirection = Vector3.new(-0.45, -1, -0.55)
	vp.ZIndex = z + 1
	vp.Parent = box

	local cam = Instance.new("Camera")
	cam.FieldOfView = 36
	cam.Parent = vp
	vp.CurrentCamera = cam

	model.Parent = vp
	local centre, sz = model:GetBoundingBox()
	local reach = math.max(sz.X, sz.Y, sz.Z, 0.5)
	cam.CFrame = CFrame.new(centre.Position - Vector3.new(0, sz.Y * 0.02, 0))
		* CFrame.Angles(0, math.rad(28), 0)
		* CFrame.Angles(math.rad(-8), 0, 0)
		* CFrame.new(0, 0, reach * 2.55 + 1.25)
	return true
end

--------------------------------------------------------------------------------

-- Claimed rungs live outside `state`. setState used to replace the whole
-- snapshot, and boolean claim maps often arrived empty over the wire, so a
-- CLAIM button popped back onto a tile the server already paid. Union with
-- the server list; never forget a rung this session unless the season rolls.
local passClaimMem = { season = "", free = {}, prem = {} }

local function passClaimBag(isPrem)
	return isPrem and passClaimMem.prem or passClaimMem.free
end

local function passClaimed(isPrem, n)
	local bag = passClaimBag(isPrem)
	return (bag[n] or bag[tostring(n)]) and true or false
end

local function rememberPassClaim(isPrem, n, on)
	n = math.floor(tonumber(n) or 0)
	if n < 1 then
		return
	end
	local bag = passClaimBag(isPrem)
	if on == false then
		bag[n] = nil
		bag[tostring(n)] = nil
	else
		bag[n] = true
		bag[tostring(n)] = true
	end
end

local function ingestPassClaims(bp)
	if type(bp) ~= "table" then
		return
	end
	local season = tostring(bp.season or "")
	if season ~= "" and passClaimMem.season ~= "" and season ~= passClaimMem.season then
		passClaimMem.free, passClaimMem.prem = {}, {}
	end
	if season ~= "" then
		passClaimMem.season = season
	end
	local function eat(list, map, isPrem)
		if type(list) == "table" then
			for _, n in ipairs(list) do
				rememberPassClaim(isPrem, n, true)
			end
		end
		if type(map) == "table" then
			for k, v in pairs(map) do
				if v then
					rememberPassClaim(isPrem, k, true)
				end
			end
		end
	end
	eat(bp.freeClaimed, bp.free, false)
	eat(bp.premClaimed, bp.prem, true)
end

function MineInventoryView.mount(parent, opts)
	opts = opts or {}
	local state = {}
	local claimPassAt = 0
	-- Keep the pass rail where the player left it across snapshot re-renders.
	-- Claiming a lucky-block tier used to rebuild the rail and jump the camera
	-- back to "current tier", so the CLAIMED tile looked like it never updated.
	local passScrollX = nil
	local passScrollPrimed = false
	local section, activeTab = "inventory", "tools"
	local tabFor = { inventory = "tools", collection = "chests", shop = "home", pass = "pass", daily = "daily", account = "account" }
	local search = ""
	local newGearGrade = nil -- Collection Hats/Faces chip; nil = all grades
	local phoneLayout = false
	local passTimerGen = 0
	local function gridCell(w, h)
		if phoneLayout then
			local nw = math.clamp(math.floor(w * 0.72), 88, 112)
			local nh = math.max(64, math.floor(h * nw / math.max(1, w)))
			return UDim2.fromOffset(nw, nh)
		end
		return UDim2.fromOffset(w, h)
	end
	-- Rarity first. Opening your cards to a list ordered by what is on your team
	-- tells you what you already knew; ordered by rarity it tells you what you got.
	local SORT_OK = {
		rarity = true, equipped = true, qty = true, boosts = true, recent = true,
		set = true, alpha = true, type = true, power = true, variant = true, role = true,
	}
	local cardSort = (type(opts.cardSort) == "string" and SORT_OK[opts.cardSort] and opts.cardSort) or "rarity"
	local render

	local root = mk("Frame", {
		Name = "Inventory",
		Visible = false,
		Active = true,
		BackgroundColor3 = BG,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.98, 0.96),
		ZIndex = 30,
		BorderSizePixel = 0,
	}, parent)
	round(root, 12)
	stroke(root, 1.5)
	-- A window wider than its own content is just a brown field with a grid in
	-- the corner. Cap it and let the anchor keep it centred.
	mk("UISizeConstraint", { MaxSize = Vector2.new(1500, 1000) }, root)

	local titleLbl = label(root, "INVENTORY", 22, TEXT, UDim2.fromOffset(20, 12), UDim2.new(1, -80, 0, 32), FONT)
	local closeBtn = mk("TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = BG2,
		Font = FONT,
		TextSize = 18,
		TextColor3 = TEXT,
		Text = "X",
		Position = UDim2.new(1, -50, 0, 12),
		Size = UDim2.fromOffset(46, 46),
	}, root)
	round(closeBtn, 8)

	-- The rail. Sections down the left.
	local rail = mk("Frame", {
		Name = "Rail",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 56),
		Size = UDim2.new(0, 150, 1, -72),
	}, root)
	mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, rail)

	local railBtns = {}
	for i, sec in ipairs(SECTIONS) do
		local b = mk("TextButton", {
			AutoButtonColor = true,
			BackgroundColor3 = BG2,
			Font = FONT,
			TextSize = 16,
			TextColor3 = TEXT,
			Text = sec.label,
			Size = UDim2.new(1, 0, 0, 46),
			LayoutOrder = i,
		}, rail)
		round(b, 8)
		stroke(b, 1)
		railBtns[sec.id] = b
		b.MouseButton1Click:Connect(function()
			section = sec.id
			activeTab = tabFor[sec.id] or sec.tabs[1].id
			render()
		end)
	end

	--[[
		ITEM BAG READOUT, bottom of the rail.

		The backpack number on the HUD is dirt. This is the other bag -- the
		shelf this whole screen is a view of -- and until now nothing anywhere
		told you it had a ceiling at all.

		Parented to `root` rather than `rail`: the rail is a UIListLayout and
		this has to sit at the bottom of the column, not after the last button.
	]]
	local slotsBox = {}
	do
		local box = mk("Frame", {
			Name = "ItemSlots",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 16, 1, -12),
			Size = UDim2.fromOffset(150, 58),
		}, root)
		slotsBox.num = label(box, "0/500", 19, TEXT,
			UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 22), FONT)
		slotsBox.cap = label(box, "itemslots", 11, MUTED,
			UDim2.fromOffset(0, 22), UDim2.new(1, 0, 0, 14), FONT_M)
		-- The price line is what makes the rung findable at all. Without it the
		-- upgrade exists only for someone who thought to tap a readout.
		slotsBox.buy = label(box, "", 11, GEM,
			UDim2.fromOffset(0, 38), UDim2.new(1, 0, 0, 14), FONT_M)
		-- Added last so it sits over the three labels and takes the click.
		slotsBox.hit = mk("TextButton", {
			Name = "Buy",
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.fromScale(1, 1),
		}, box)
		slotsBox.hit.MouseButton1Click:Connect(function()
			if opts.onBuyItemSlots then
				opts.onBuyItemSlots()
			end
		end)
	end

	-- The tab strip. Tabs across the top of the content; it scrolls sideways
	-- when they do not all fit (see stripOf).
	local tabBar = stripOf(root, "Tabs", 6)
	tabBar.Position = UDim2.fromOffset(182, 56)
	tabBar.Size = UDim2.new(1, -198, 0, 34)

	local searchBox = mk("TextBox", {
		Name = "Search",
		BackgroundColor3 = BG2,
		Position = UDim2.fromOffset(182, 92),
		Size = UDim2.new(1, -198, 0, 26),
		Font = FONT_M,
		TextSize = 13,
		TextColor3 = TEXT,
		PlaceholderText = "Search...",
		PlaceholderColor3 = MUTED,
		Text = "",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, root)
	round(searchBox, 6)
	stroke(searchBox, 1)
	mk("UIPadding", { PaddingLeft = UDim.new(0, 10) }, searchBox)

	-- One row, never two: two rows of chips ate a third of the window.
	local sortBar = stripOf(root, "SortBar", 4)
	sortBar.Position = UDim2.fromOffset(182, 126)
	sortBar.Size = UDim2.new(1, -198, 0, 30)
	local sortChips = {}
	for i, s in ipairs(SORTS) do
		local b = mk("TextButton", {
			AutoButtonColor = true,
			BackgroundColor3 = BG3,
			Font = FONT,
			TextSize = 12,
			TextColor3 = MUTED,
			Text = s.label,
			Size = UDim2.fromOffset(0, 26),
			LayoutOrder = i,
		}, sortBar)
		round(b, 6)
		stroke(b, 1)
		fitButton(b, 10, 36)
		sortChips[s.id] = b
		b.MouseButton1Click:Connect(function()
			cardSort = s.id
			if opts.onCardSort then
				opts.onCardSort(s.id)
			end
			render()
		end)
	end

	local body = mk("ScrollingFrame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(182, 126),
		Size = UDim2.new(1, -198, 1, -142),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 6,
		BorderSizePixel = 0,
		Active = true,
	}, root)
	mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, body)

	--[[
		Fit the window to the screen it is on. The offsets here are in MineUI's
		own units, and MineUI carries a UIScale, so the room is measured the same
		way (raw pixels divided back out). A narrow screen gets a slimmer rail, a
		short one a tighter header; changing mode re-renders so the body moves
		with it.
	]]
	local L = { x = 182, w = 198, top = 56, mode = "" }
	local function applyLayout()
		local sg = root:FindFirstAncestorOfClass("ScreenGui")
		local ui = sg and sg:FindFirstChildOfClass("UIScale")
		local k = (ui and ui.Scale > 0.05) and ui.Scale or 1
		local room = root.AbsoluteSize / k
		if room.X < 10 then
			return false
		end
		local phone = room.X < 560
		phoneLayout = phone
		local narrow, short = room.X < 900, room.Y < 560
		local mode = (phone and "p" or narrow and "n" or "w") .. (short and "s" or "t")
		if mode == L.mode then
			return false
		end
		L.mode = mode
		local railW = phone and 76 or (narrow and 108 or 150)
		L.top = short and 46 or 56
		L.x = 16 + railW + 16
		L.w = L.x + 16
		titleLbl.TextSize = short and 18 or 22
		titleLbl.Position = UDim2.fromOffset(20, short and 8 or 12)
		closeBtn.Position = UDim2.new(1, -50, 0, short and 7 or 12)
		rail.Position = UDim2.fromOffset(16, L.top)
		rail.Size = UDim2.new(0, railW, 1, -(L.top + 16))
		for _, b in pairs(railBtns) do
			b.Size = UDim2.new(1, 0, 0, short and 36 or 46)
			b.TextSize = phone and 11 or (narrow and 14 or 16)
		end
		tabBar.Position = UDim2.fromOffset(L.x, L.top)
		tabBar.Size = UDim2.new(1, -L.w, 0, 34)
		searchBox.Size = UDim2.new(1, -L.w, 0, 26)
		sortBar.Size = UDim2.new(1, -L.w, 0, 30)
		return true
	end
	applyLayout()
	local function relayout()
		if applyLayout() and root.Visible and render then
			render()
		end
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	-- MineUI's UIScale changes the room without changing the frame's pixels.
	local layer = root:FindFirstAncestorOfClass("ScreenGui")
	local uiScale = layer and layer:FindFirstChildOfClass("UIScale")
	if uiScale then
		uiScale:GetPropertyChangedSignal("Scale"):Connect(relayout)
	end

	local function clear(x)
		for _, ch in ipairs(x:GetChildren()) do
			if not ch:IsA("UIListLayout") and not ch:IsA("UIGridLayout") and not ch:IsA("UIPadding") then
				ch:Destroy()
			end
		end
	end

	local function matches(text)
		if search == "" then
			return true
		end
		return string.find(string.lower(tostring(text)), search, 1, true) ~= nil
	end
	----------------------------------------------------------------------------
	-- INVENTORY
	----------------------------------------------------------------------------
	--[[
		THE PACK INSPECTOR.

		A sealed pack used to be a tile with a name on it. The player had no way
		to know what was in it, how many cards it paid, or that shiny was even a
		thing -- so every pack looked like every other pack and none of them
		felt worth holding.

		The odds shown here are read from MineCards.slotOdds, which is the same
		function the server rolls from. Printing a separately maintained table
		would eventually print a lie.

		Both framings of every number, because they answer different questions:
		a percentage is how good this pack is, "1 in N" is how long you will be
		waiting. 0.015% means nothing to most people; "1 in 6,667" lands.
	]]
	local function commas(n)
		local s = tostring(math.floor(n))
		local k
		repeat
			s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		until k == 0
		return s
	end

	local function oneIn(pct)
		if pct <= 0 then
			return "never"
		end
		local n = 100 / pct
		if n < 1.5 then
			return "almost every card"
		end
		return "1 in " .. commas(n + 0.5)
	end

	--[[
		THE CART.

		Held out here rather than inside renderShop, because every tab switch,
		search keystroke and snapshot rebuilds the body from scratch -- a cart
		parented to it would be thrown away by the act of browsing, which is the
		one thing a cart must never do.

		Lines are { kind, id, bundle, qty }. No prices: the server recomputes
		every one of them at checkout from its own tables, and this only ever
		sends what the player asked for.
	]]
	local cart = {}
	local cartP, cartPill, buySheet
	--[[
		FEATURED SKUs.

		Which pack the hero is currently showing, kept out here on purpose: the
		body is rebuilt on every render, and a rotator that restarts from the
		first slide every time the player types in the search box or a snapshot
		lands is a rotator that never reaches slide three.

		The pool is hand-picked rather than derived. These are the five packs
		worth leading with -- the two warehouse shapes, the shiny one, the one
		guaranteed good card, and the prestige pack -- which is a merchandising
		decision, not something the odds tables can answer.
	]]
	-- Hand-picked: which packs are worth leading with is a merchandising call,
	-- not something the odds tables can answer. One of the three new families
	-- rides along so they are discoverable without hunting the grid for them.
	local FEATURED = { "hopper_pack", "magma_pack", "shiny_pack", "apex_pack", "heirloom_pack" }
	local heroAt = 1
	local heroToken = 0
	-- Custom booster box: up to 10 pack picks (always available).
	local boxPicks = {}

	local function cartKey(kind, id, bundle)
		return tostring(kind) .. "|" .. tostring(id) .. "|" .. (bundle and "10" or "1")
	end

	-- Price a line the same way the server will, so the sheet and the charge
	-- agree. If these ever disagree the server wins and the player sees a
	-- number change at the last second, which is exactly how you lose trust.
	local function linePrice(line)
		if line.kind == "pack" then
			return line.bundle and (Packs.bundlePrice(line.id) or 0) or (Packs.priceOf(line.id) or 0)
		end
		if line.kind == "lucky_block" then
			local LB = nil
			pcall(function() LB = require(shared:WaitForChild("MineLuckyBlocks")) end)
			if not LB then return 0 end
			if line.bundle and LB.BUNDLE_10 and LB.BUNDLE_10.id == line.id then
				return LB.BUNDLE_10.credits or 0
			end
			return (LB.shopPrice and LB.shopPrice(line.id)) or 0
		end
		if line.kind == "box" then
			local sum = 0
			for _, pid in ipairs(line.packs or {}) do
				sum += Packs.priceOf(pid) or 0
			end
			return math.floor(sum * 0.88 + 0.5)
		end
		local shop = state.scrollShop or {}
		local item = shop[line.id]
		if not item then
			return 0
		end
		if line.bundle then
			return item.bundlePrice or ((item.price or 0) * (item.bundleQty or 1))
		end
		return item.price or 0
	end

	local function cartSubtotal()
		local n, sum = 0, 0
		for _, line in ipairs(cart) do
			n += line.qty
			sum += linePrice(line) * line.qty
		end
		return sum, n
	end

	local function isMember()
		local mem = state.vipMembership
		if mem == nil then
			mem = state.vip
		end
		return (type(mem) == "table" and mem.since ~= nil) or false
	end

	local function hasVipPass()
		return state.vip == true
	end

	local function vipCreditPrice(amount)
		if C and C.vipPrice then
			return C.vipPrice(amount, hasVipPass())
		end
		amount = math.floor(tonumber(amount) or 0)
		if amount <= 0 then return 0 end
		if not hasVipPass() then return amount end
		return math.max(1, math.floor(amount * 0.9))
	end

	--[[
		Mirrored from MinePackConfig so one edit moves both, and passed the same
		membership flag the server will use. If these ever disagree the server
		wins and the player watches the price change at the last second, which is
		exactly how a storefront loses trust.
	]]
	local function cartPayable()
		local sub = cartSubtotal()
		local pay = (Packs.creditPrice and Packs.creditPrice(sub, isMember()))
			or math.floor(sub * (isMember() and 0.8 or 0.9))
		return vipCreditPrice(pay), sub
	end

	local refreshCart

	local function cartAdd(kind, id, bundle, qty, packs)
		if kind == "box" and type(packs) == "table" then
			table.insert(cart, { kind = "box", id = "custom", bundle = false, qty = qty or 1, packs = packs })
			refreshCart()
			return
		end
		local key = cartKey(kind, id, bundle)
		for _, line in ipairs(cart) do
			if cartKey(line.kind, line.id, line.bundle) == key then
				line.qty = math.min(25, line.qty + (qty or 1))
				refreshCart()
				return
			end
		end
		table.insert(cart, { kind = kind, id = id, bundle = bundle or false, qty = qty or 1 })
		refreshCart()
	end

	local inspectP
	--[[
		`g` is a tile group: { packId, tierName, setName, cards, firstIndex,
		count }. The dex builds the same shape for packs the player has never
		seen, with count 0 and no firstIndex -- which is how one inspector
		serves both "the pack in my bag" and "the pack I am reading about".
	]]
	local function showPackInspect(g)
		if inspectP then
			inspectP:Destroy()
		end
		local packDef = Packs.PACK_BY_ID and Packs.PACK_BY_ID[g.packId] or nil
		do
			local ZonePacks = require(shared:WaitForChild("MineZonePacks"))
			packDef = packDef or (g.packId and ZonePacks.get(g.packId))
		end
		local set = Cards.SETS[g.setId]
		local tier = (set and set.tier) or "T1"
		--[[
			The pack's own odds if it has them, the set-tier table only as a
			fallback. Prefer oddsFor so map-shaped zone odds become rows, and
			so dug packs with a layer show the depth curve they actually roll.
		]]
		local oddsOpts = nil
		if g.layer and Packs.depthCardOdds then
			local maxL = C.LAYERS or 50
			if g.zoneId == "meadow" or (tonumber(g.layer) or 0) > (C.LAYERS or 50) then
				maxL = 2500
			elseif g.zoneId and C.zoneLayers then
				maxL = C.zoneLayers(g.zoneId)
			elseif g.packId and Packs.PACK_BY_ID and Packs.PACK_BY_ID[g.packId] then
				maxL = 2500
			end
			local heat = 0
			local pid = tostring(g.packId or "")
			if string.find(pid, "legendary", 1, true) or string.find(pid, "apex", 1, true) then
				heat = 2
			elseif string.find(pid, "_rare", 1, true) then
				heat = 1
			end
			oddsOpts = { layer = g.layer, maxLayers = maxL, heat = heat }
		end
		local odds = (Packs.oddsFor and Packs.oddsFor(g.packId, oddsOpts))
			or (packDef and Packs.oddsRowsFrom and Packs.oddsRowsFrom(packDef.odds))
			or (Cards.slotOdds and Cards.slotOdds(tier))
			or {}
		local shiny = (packDef and tonumber(packDef.shiny)) or Packs.SHINY_CHANCE or 0
		local tierCol = PackFX.art(g.packId).accent

		inspectP = mk("Frame", {
			Name = "PackInspect",
			BackgroundColor3 = BG,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(420, 640),
			ZIndex = 60,
		}, root)
		round(inspectP, 12)
		stroke(inspectP, 2, tierCol)

		local cap = mk("Frame", {
			BackgroundColor3 = tierCol,
			Size = UDim2.new(1, 0, 0, 6),
			ZIndex = 61,
		}, inspectP)
		round(cap, 3)

		local art = mk("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 20),
			Size = UDim2.fromOffset(74, 102),
			ZIndex = 62,
		}, inspectP)
		PackFX.drawSealed(art, g.packId, 74, 102)

		local nameL = label(inspectP, g.tierName, 22, TEXT, UDim2.fromOffset(12, 130),
			UDim2.new(1, -24, 0, 26), FONT)
		nameL.TextXAlignment = Enum.TextXAlignment.Center
		nameL.ZIndex = 62
		local setL = label(inspectP, g.setName, 14, MUTED, UDim2.fromOffset(12, 156),
			UDim2.new(1, -24, 0, 20))
		setL.TextXAlignment = Enum.TextXAlignment.Center
		setL.ZIndex = 62

		local unit = Packs.unitWord and Packs.unitWord(g.packId, g.cards) or "cards"
		local isCurrencyPack = packDef and packDef.kind == "currency"
		local cardsL = label(inspectP, (g.cards > 0)
			and (g.cards .. " " .. unit .. " -- every one rolls the odds below")
			or (isCurrencyPack and "Currency pouch -- opens into the rewards below")
			or "",
			13, tierCol, UDim2.fromOffset(12, 180), UDim2.new(1, -24, 0, 18), FONT)
		cardsL.TextXAlignment = Enum.TextXAlignment.Center
		cardsL.ZIndex = 62

		local y = 232
		if isCurrencyPack then
			local hdrC = label(inspectP, "REWARDS", 13, MUTED, UDim2.fromOffset(18, 210),
				UDim2.new(1, -36, 0, 18), FONT)
			hdrC.TextXAlignment = Enum.TextXAlignment.Left
			hdrC.ZIndex = 62
			local function currencyRewardRow(iconId, text, col)
				local line = mk("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(18, y),
					Size = UDim2.new(1, -36, 0, 32),
					ZIndex = 62,
				}, inspectP)
				local host = mk("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(28, 28),
					Position = UDim2.fromOffset(0, 2),
					ZIndex = 63,
				}, line)
				if Icons and Icons.draw then
					pcall(Icons.draw, host, iconId, 1)
				elseif Icons and Icons.image then
					mk("ImageLabel", {
						BackgroundTransparency = 1, BorderSizePixel = 0,
						Image = Icons.image(iconId) or "", ScaleType = Enum.ScaleType.Fit,
						Size = UDim2.fromScale(1, 1), ZIndex = 64,
					}, host)
				end
				local tl = label(line, text, 14, col or TEXT,
					UDim2.fromOffset(36, 0), UDim2.new(1, -36, 1, 0), FONT)
				tl.TextXAlignment = Enum.TextXAlignment.Left
				tl.ZIndex = 63
				y += 36
			end
			local c = packDef.coins or { 0, 0 }
			local gm = packDef.gems or { 0, 0 }
			local d = packDef.dust or packDef.stardust
			if c[2] and c[2] > 0 then
				currencyRewardRow("coins", string.format("%s–%s coins", shortNum(c[1]), shortNum(c[2])), GOLD)
			end
			if gm[2] and gm[2] > 0 then
				currencyRewardRow("gems", string.format("%s–%s gems", shortNum(gm[1]), shortNum(gm[2])), Color3.fromRGB(90, 180, 255))
			end
			if type(d) == "table" and (d[2] or 0) > 0 then
				currencyRewardRow("stardust", string.format("%s–%s stardust", shortNum(d[1]), shortNum(d[2])), Color3.fromRGB(210, 160, 255))
			end
			if type(packDef.loot) == "table" then
				for _, row in ipairs(packDef.loot) do
					if row.kind == "gems" then
						currencyRewardRow("gems", string.format("%s–%s gems (%.0f%%)", shortNum(row.min), shortNum(row.max), row.weight or 0), Color3.fromRGB(90, 180, 255))
					elseif row.kind == "stardust" or row.kind == "dust" then
						currencyRewardRow("stardust", string.format("%s–%s stardust (%.0f%%)", shortNum(row.min), shortNum(row.max), row.weight or 0), Color3.fromRGB(210, 160, 255))
					end
				end
			end
		else
			local hdr = label(inspectP, "ODDS PER "
				.. string.upper(Packs.unitWord and Packs.unitWord(g.packId, 1) or "card"), 13, MUTED, UDim2.fromOffset(18, 210),
				UDim2.new(1, -36, 0, 18), FONT)
			hdr.TextXAlignment = Enum.TextXAlignment.Left
			hdr.ZIndex = 62
			for _, row in ipairs(odds) do
				local col = Cards.RARITY_COLOR[row.rarity] or MUTED
				local line = mk("Frame", {
					BackgroundColor3 = BG2,
					Position = UDim2.fromOffset(18, y),
					Size = UDim2.new(1, -36, 0, 26),
					ZIndex = 62,
				}, inspectP)
				round(line, 6)
				mk("Frame", {
					BackgroundColor3 = col,
					BorderSizePixel = 0,
					Position = UDim2.fromOffset(0, 0),
					Size = UDim2.fromOffset(4, 26),
					ZIndex = 63,
				}, line)
				local rl = label(line, Cards.RARITY_LABEL[row.rarity] or row.rarity, 13, col,
					UDim2.fromOffset(12, 0), UDim2.fromOffset(120, 26))
				rl.TextXAlignment = Enum.TextXAlignment.Left
				rl.ZIndex = 63
				local pl = label(line, string.format("%.2f%%", row.weight), 13, TEXT,
					UDim2.fromOffset(132, 0), UDim2.fromOffset(74, 26), FONT)
				pl.TextXAlignment = Enum.TextXAlignment.Right
				pl.ZIndex = 63
				local oneInPct = row.weight
				local chase = row.rarity == "Legendary" or row.rarity == "Mythic"
					or row.rarity == "Divine" or row.rarity == "Exotic"
				if chase and Cards.indicesOfRarity then
					local setId = g.setId
					if (not setId or setId == "") and g.zoneId and C.zoneById then
						local z = C.zoneById(g.zoneId)
						setId = z and z.sets and z.sets[1]
					end
					local n = #(Cards.indicesOfRarity(setId, row.rarity) or {})
					if n > 0 then
						oneInPct = row.weight / n
					end
				end
				local nl = label(line, oneIn(oneInPct), 12, MUTED,
					UDim2.new(1, -140, 0, 0), UDim2.fromOffset(128, 26))
				nl.TextXAlignment = Enum.TextXAlignment.Right
				nl.ZIndex = 63
				y += 30
			end
		end

		-- Shiny gets its own band. It is not a rarity rung -- any card in the
		-- pack can come out shiny on top of whatever it rolled.
		--
		-- Card packs only. A rune or a gear piece has no finish to roll, and
		-- printing "SHINY 0.00%" on one reads as a rate you could improve
		-- rather than as a thing that does not exist.
		-- Skipped, not emptied: everything below is positioned off shinyH, so
		-- the history row and the OPEN button close the gap instead of leaving
		-- a hole where the band would have been.
		local shinyH = 0
		if not isCurrencyPack and ((not Packs.hasShiny) or Packs.hasShiny(g.packId)) then
			shinyH = 44
			local sh = mk("Frame", {
				BackgroundColor3 = BG2,
				Position = UDim2.fromOffset(18, y + 8),
				Size = UDim2.new(1, -36, 0, 34),
				ZIndex = 62,
			}, inspectP)
			round(sh, 8)
			stroke(sh, 1.5, Color3.fromRGB(190, 235, 255))
			local shl = label(sh, "SHINY", 14, Color3.fromRGB(190, 235, 255),
				UDim2.fromOffset(12, 0), UDim2.fromOffset(90, 34), FONT)
			shl.TextXAlignment = Enum.TextXAlignment.Left
			shl.ZIndex = 63
			local shp = label(sh, string.format("%.2f%%", shiny), 14, TEXT,
				UDim2.fromOffset(104, 0), UDim2.fromOffset(74, 34), FONT)
			shp.TextXAlignment = Enum.TextXAlignment.Right
			shp.ZIndex = 63
			local shn = label(sh, oneIn(shiny), 12, MUTED,
				UDim2.new(1, -150, 0, 0), UDim2.fromOffset(138, 34))
			shn.TextXAlignment = Enum.TextXAlignment.Right
			shn.ZIndex = 63
		end

		--[[
			YOUR OWN HISTORY WITH THIS PACK.

			Odds tell you what the pack is; these tell you what it has been for
			YOU, which is the half that makes a number feel like yours. Found is
			derived rather than stored -- a pack can only be acquired or opened,
			so everything you ever found is what you have opened plus what is
			still sitting in the bag.
		]]
		local opened = tonumber((state.packsOpened or {})[g.packId]) or 0
		local held = g.count or 0
		local lifetime = tonumber((state.stats or {}).packs) or 0
		local statsY = y + 8 + shinyH
		local stats = mk("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(18, statsY),
			Size = UDim2.new(1, -36, 0, 46),
			ZIndex = 62,
		}, inspectP)
		local cols = {
			{ "FOUND", opened + held },
			{ "OPENED", opened },
			{ "IN BAG", held },
		}
		for ci, col in ipairs(cols) do
			local cw = 1 / #cols
			local box = mk("Frame", {
				BackgroundColor3 = BG2,
				Position = UDim2.new((ci - 1) * cw, 3, 0, 0),
				Size = UDim2.new(cw, -6, 1, 0),
				ZIndex = 62,
			}, stats)
			round(box, 6)
			local v = label(box, commas(col[2]), 18, TEXT, UDim2.fromOffset(0, 4),
				UDim2.new(1, 0, 0, 22), FONT)
			v.ZIndex = 63
			local k = label(box, col[1], 11, MUTED, UDim2.fromOffset(0, 26), UDim2.new(1, 0, 0, 16))
			k.ZIndex = 63
		end
		local life = label(inspectP, commas(lifetime) .. " packs opened all-time", 12, MUTED,
			UDim2.fromOffset(18, statsY + 50), UDim2.new(1, -36, 0, 16))
		life.ZIndex = 62

		-- Only offer to open it if there is one to open. In the dex there is
		-- usually not, and a dead button is worse than no button.
		local openB
		if held > 0 and g.firstIndex then
			openB = mk("TextButton", {
				AutoButtonColor = true,
				BackgroundColor3 = GREEN,
				Font = FONT,
				TextSize = 16,
				TextColor3 = Color3.fromRGB(10, 26, 16),
				Text = "OPEN",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, -76, 1, -16),
				Size = UDim2.fromOffset(140, 38),
				ZIndex = 63,
			}, inspectP)
			round(openB, 8)
			openB.MouseButton1Click:Connect(function()
				inspectP:Destroy()
				inspectP = nil
				if not state.busy and opts.onOpenPack then
					opts.onOpenPack(g.firstIndex, g.uid)
				end
			end)
		end
		local closeB = mk("TextButton", {
			AutoButtonColor = true,
			BackgroundColor3 = BG2,
			Font = FONT,
			TextSize = 16,
			TextColor3 = TEXT,
			Text = "CLOSE",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, openB and 76 or 0, 1, -16),
			Size = UDim2.fromOffset(140, 38),
			ZIndex = 63,
		}, inspectP)
		round(closeB, 8)
		closeB.MouseButton1Click:Connect(function()
			inspectP:Destroy()
			inspectP = nil
		end)
	end

	--[[
		The circled i.

		The tile is already clickable anywhere, but a thing that is clickable
		and does not look clickable gets clicked by nobody. This is the visible
		promise that there is something to read -- the affordance, not the
		mechanism.

		Solid black badge + white i (top-right) so it reads on dark brown tiles.
		~40px hit target for thumbs.
	]]
	local function infoBadge(parent, g)
		local pad = 8
		local size = 28
		local b = mk("TextButton", {
			Name = "Info",
			BackgroundTransparency = 1,
			AutoButtonColor = true,
			Text = "",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -pad, 0, pad),
			Size = UDim2.fromOffset(size, size),
			ZIndex = 7,
		}, parent)

		-- Prefer uploaded PNG when MineIcons.info is set; else draw the badge.
		local Icons = nil
		pcall(function()
			Icons = require(shared:WaitForChild("MineIcons"))
		end)
		local asset = Icons and Icons.image and Icons.image("info")
		if type(asset) == "string" and asset ~= "" then
			local img = mk("ImageLabel", {
				Name = "InfoArt",
				BackgroundTransparency = 1,
				Image = asset,
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 8,
			}, b)
			img.Active = false
		else
			-- Match authored info_badge: sky-blue disc, dark outline, white i.
			local disc = mk("Frame", {
				Name = "Disc",
				BackgroundColor3 = Color3.fromRGB(94, 184, 232),
				Size = UDim2.fromScale(1, 1),
				ZIndex = 8,
			}, b)
			round(disc, size / 2)
			local st = stroke(disc, 2, Color3.fromRGB(28, 24, 48))
			if st then st.Transparency = 0 end
			local hi = mk("Frame", {
				Name = "Highlight",
				BackgroundColor3 = Color3.fromRGB(220, 240, 255),
				BackgroundTransparency = 0.55,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 3),
				Size = UDim2.new(0.55, 0, 0, 3),
				ZIndex = 9,
			}, disc)
			round(hi, 2)
			local stem = mk("Frame", {
				Name = "Stem",
				BackgroundColor3 = Color3.fromRGB(244, 247, 251),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -5),
				Size = UDim2.fromOffset(5, 11),
				ZIndex = 10,
			}, disc)
			round(stem, 3)
			stroke(stem, 1.25, Color3.fromRGB(28, 24, 48))
			local dot = mk("Frame", {
				Name = "Dot",
				BackgroundColor3 = Color3.fromRGB(244, 247, 251),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 5),
				Size = UDim2.fromOffset(5, 5),
				ZIndex = 10,
			}, disc)
			round(dot, 3)
			stroke(dot, 1.25, Color3.fromRGB(28, 24, 48))
		end

		b.MouseButton1Click:Connect(function()
			showPackInspect(g)
		end)
		return b
	end

	--[[
		THE PACK DEX.

		Every pack in the game, whether or not the player has one, sorted by the
		same silent tier the bag uses. Packs are not sold anywhere, so before
		this there was no screen that answered "what packs exist and which is
		worth chasing" -- you found out by opening one.

		Unowned packs are drawn dimmed rather than hidden: a list with holes in
		it is a list you want to fill.
	]]
	local function renderPackDex()
		local held = {}
		for _, pk in ipairs(state.packs or {}) do
			held[tostring(pk.packId)] = (held[tostring(pk.packId)] or 0) + 1
		end
		local ZonePacks = require(shared:WaitForChild("MineZonePacks"))
		local rows = {}
		-- Zone 5+2 grid first (artKey / zone / slot).
		for _, zoneId in ipairs(ZonePacks.ZONE_ORDER or {}) do
			for _, slot in ipairs(ZonePacks.SLOTS or {}) do
				local def = ZonePacks.PACKS[ZonePacks.id(zoneId, slot)]
				if def then table.insert(rows, def) end
			end
		end
		local lim = ZonePacks.LIMITED_ZONE
		if lim then
			for _, slot in ipairs(ZonePacks.SLOTS or {}) do
				local def = ZonePacks.PACKS[ZonePacks.id(lim, slot)]
				if def then table.insert(rows, def) end
			end
		end
		-- Legacy shop SKUs if any remain.
		for _, def in ipairs(Packs.PACKS or {}) do
			if not (def.id and ZonePacks.PACKS[def.id]) then
				table.insert(rows, def)
			end
		end

		note(body, "Zone packs (5 + fossil + deep) with art keys. Tap one to read odds / currency bands.", 0)

		local grid = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -6, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 1,
		}, body)
		mk("UIGridLayout", {
			CellPadding = UDim2.fromOffset(8, 8),
			CellSize = UDim2.fromOffset(158, 188),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, grid)

		local shown = 0
		for i, def in ipairs(rows) do
			if matches(def.name or def.id) then
				shown += 1
				local count = held[tostring(def.id)] or 0
				local opened = tonumber((state.packsOpened or {})[def.id]) or 0
				local seen = (count + opened) > 0
				local artId = def.artKey or def.id
				local tierCol = PackFX.art(artId).accent
				local tile = mk("Frame", { BackgroundColor3 = BG2, LayoutOrder = i }, grid)
				round(tile, 8)
				stroke(tile, 1.5, seen and tierCol or Color3.fromRGB(58, 58, 68))
				local cap2 = mk("Frame", {
					BackgroundColor3 = seen and tierCol or Color3.fromRGB(58, 58, 68),
					Size = UDim2.new(1, 0, 0, 6),
				}, tile)
				round(cap2, 3)
				local artHost = mk("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 12),
					Size = UDim2.fromOffset(68, 92),
					ZIndex = 3,
				}, tile)
				PackFX.drawSealed(artHost, artId, 68, 92)
				if not seen then
					-- Soft veil only — heavy BG2 overlay was burying Face art.
					mk("Frame", {
						BackgroundColor3 = Color3.fromRGB(12, 12, 16),
						BackgroundTransparency = 0.62,
						BorderSizePixel = 0,
						Size = UDim2.fromScale(1, 1),
						ZIndex = 6,
					}, artHost)
				end
				local nameL = label(tile, def.name or def.id, 15, seen and TEXT or MUTED,
					UDim2.fromOffset(8, 110), UDim2.new(1, -16, 0, 20), FONT)
				nameL.TextXAlignment = Enum.TextXAlignment.Center
				nameL.TextTruncate = Enum.TextTruncate.AtEnd
				local sub = "Not found yet"
				if seen then
					if def.kind == "currency" then
						local c = def.coins or { 0, 0 }
						local g = def.gems or { 0, 0 }
						sub = string.format("%s-%s coins  %s-%s gems", tostring(c[1]), tostring(c[2]), tostring(g[1]), tostring(g[2]))
					elseif def.kind == "fossil" then
						sub = (def.pulls or 3) .. " equipment" .. (def.deep and " (deep)" or "")
					else
						sub = (def.cards or 0) .. " " .. (Packs.unitWord and Packs.unitWord(def.id, def.cards) or "cards")
					end
					if def.zoneId then
						sub = (def.zoneId == "sunscar" and "Greyvein" or def.zoneId) .. " · " .. sub
					end
				end
				local subL = label(tile, sub, 12, seen and tierCol or Color3.fromRGB(96, 96, 108),
					UDim2.fromOffset(8, 132), UDim2.new(1, -16, 0, 16), FONT)
				subL.TextXAlignment = Enum.TextXAlignment.Center
				local foundL = label(tile, seen and ("found " .. commas(count + opened)) or "",
					12, MUTED, UDim2.fromOffset(8, 152), UDim2.new(1, -16, 0, 16))
				foundL.TextXAlignment = Enum.TextXAlignment.Center

				local g = {
					packId = def.id,
					tierName = def.name or def.id,
					setName = "",
					cards = def.cards or 0,
					count = count,
					firstIndex = nil,
				}
				-- The dex has no set of its own, so borrow the set of one the
				-- player actually holds; failing that, the starting set.
				for _, pk in ipairs(state.packs or {}) do
					if pk.packId == def.id and pk.setId then
						g.setId = pk.setId
						g.setName = (Cards.SETS[pk.setId] and Cards.SETS[pk.setId].displayName) or pk.setId
						break
					end
				end
				if not g.setId then
					g.setId = "dragons_dawn"
					g.setName = (Cards.SETS.dragons_dawn and Cards.SETS.dragons_dawn.displayName) or ""
				end
				for _, pk in ipairs(state.packs or {}) do
					if pk.packId == def.id then
						g.firstIndex = nil
						break
					end
				end
				local hit = mk("TextButton", {
					BackgroundTransparency = 1,
					Text = "",
					TextSize = 14,
					AutoButtonColor = false,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 5,
				}, tile)
				hit.MouseButton1Click:Connect(function()
					showPackInspect(g)
				end)
				infoBadge(tile, g)
			end
		end
		if shown == 0 then
			grid:Destroy()
			note(body, "Nothing matches that search.")
		end
	end

	local function renderPacks()
		local packs = state.packs or {}
		if #packs == 0 then
			note(body, "No packs yet. They come out of chests -- the rarer the chest, the better the odds.")
			return
		end
		--[[
			There is no "Open all" button up here any more.

			One corner button that empties the entire bag is the wrong shape
			for this: it opens packs you did not mean to spend, worst-first
			across every kind at once, and there is nothing to say what it is
			about to do. The choice belongs on the stack you are looking at --
			open one of THESE, ten of THESE, or the lot -- which is what the
			tiles below offer.
		]]

		-- Stack duplicates. A full account carries six hundred and some packs and
		-- the old grid drew one tile each -- six hundred near-identical cards,
		-- six hundred green buttons, and the four thousand instances behind them.
		-- Nobody reads that; they scroll past it looking for the good one. A
		-- stack is one tile with a count, and the rarest stack sits first.
		local LuckyBlocks = require(shared:WaitForChild("MineLuckyBlocks"))
		local GRADE_RANK = { F = 1, D = 2, C = 3, B = 4, A = 5, S = 6, SS = 7, SSS = 8 }
		local groups, order = {}, {}
		for i, pk in ipairs(packs) do
			local isBlock = pk.kind == "lucky_block" or (pk.blockId ~= nil)
			local tierName = pk.packName or C.PACK_TIERS[pk.tier or 1] or "Pack"
			local set = Cards.SETS[pk.setId]
			local setName = (set and set.displayName) or tostring(pk.setId or "Unknown set")
			local luckMult = tonumber(pk.luck) or 1
			local luckPct = (luckMult > 1) and math.floor((luckMult - 1) * 100 + 0.5) or 0
			local key
			if isBlock then
				-- The same key the server opens by (MineLuckyBlocks.stackKey).
				key = LuckyBlocks.stackKey(pk)
				setName = "Grade " .. tostring(pk.startGrade or "F")
			else
				-- Same pack + same luck stacks; set/zone is ignored so a Clay
				-- pack from Bloodmoon and one from Universal share a tile.
				-- Different luck stays split (+69% vs +52%).
				key = tostring(pk.packId) .. "|luck:" .. tostring(luckPct)
			end
			local g = groups[key]
			if not g then
				g = {
					packId = pk.packId, tierName = tierName, setName = setName,
					setId = pk.setId, layer = pk.layer, zoneId = pk.zoneId,
					kind = isBlock and "lucky_block" or "pack",
					blockId = pk.blockId or (isBlock and pk.packId) or nil,
					startGrade = pk.startGrade,
					key = key,
					bought = pk.bought,
					-- Silent tier: derived from the pack's own odds, so a new
					-- pack sorts correctly without anyone ranking it by hand.
					rank = isBlock and 50 or (Packs.packTier and Packs.packTier(pk.packId) or 0),
					cards = Packs.packCards and Packs.packCards(pk.packId) or 0,
					count = 0, firstIndex = i,
					-- A tile is a stack, but opening is always one pack. The
					-- server stamps every pack with its own id; keeping the
					-- whole list lets the tile name exactly which one it spends
					-- and survive the bag shifting under it.
					uid = pk.uid, uids = {},
					luck = luckMult, luckPct = luckPct,
					setNames = {},
				}
				groups[key] = g
				order[#order + 1] = g
			end
			g.count += 1
			g.uids[#g.uids + 1] = pk.uid
			g.uid = g.uid or pk.uid
			if not isBlock then
				g.setNames[setName] = true
				local unique, only = 0, nil
				for name in pairs(g.setNames) do
					unique += 1
					only = name
				end
				g.setName = (unique == 1) and only or "Various"
			end
		end
		-- Worst first, then alphabetical. You work up through the junk; your
		-- best pack should be the last thing you spend, not the first thing the
		-- list hands you.
		table.sort(order, function(x, y)
			-- Lucky blocks go first, best grade first: they are what you came to
			-- open, and they were getting lost at the bottom of the bag.
			local xb, yb = x.kind == "lucky_block", y.kind == "lucky_block"
			if xb ~= yb then
				return xb
			end
			if xb then
				local xr, yr = GRADE_RANK[x.startGrade or "F"] or 1, GRADE_RANK[y.startGrade or "F"] or 1
				if xr ~= yr then
					return xr > yr
				end
				return tostring(x.key) < tostring(y.key)
			end
			if x.rank ~= y.rank then
				return x.rank < y.rank
			end
			if x.tierName ~= y.tierName then
				return x.tierName < y.tierName
			end
			return x.setName < y.setName
		end)

		local grid = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -6, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 1,
		}, body)
		mk("UIGridLayout", {
			CellPadding = UDim2.fromOffset(8, 8),
			CellSize = UDim2.fromOffset(152, 226),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, grid)
		local shown = 0
		for i, g in ipairs(order) do
			if matches(g.tierName .. " " .. g.setName) then
				shown += 1
				local tile = mk("Frame", { BackgroundColor3 = BG2, LayoutOrder = i }, grid)
				round(tile, 8)
				-- Packs use pack art accent. Lucky blocks use start-grade colour
				-- (F grey / D uncommon / C rare / B epic / A legendary / S+).
				local tierCol
				if g.kind == "lucky_block" then
					local grade = tostring(g.startGrade or "F")
					tierCol = (Gear.RARITY_COLOR and Gear.RARITY_COLOR[grade])
						or Color3.fromRGB(170, 170, 170)
				else
					tierCol = PackFX.art(g.packId).accent
				end
				stroke(tile, 1.5, tierCol)
				local cap = mk("Frame", { BackgroundColor3 = tierCol, Size = UDim2.new(1, 0, 0, 6) }, tile)
				round(cap, 3)
				local artHost = mk("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 16),
					Size = UDim2.fromOffset(54, 74),
					ZIndex = 3,
				}, tile)
				if g.kind == "lucky_block" then
					local LBmod = nil
					pcall(function()
						LBmod = require(shared:WaitForChild("MineLuckyBlocks"))
					end)
					local def = LBmod and LBmod.def(g.blockId or g.packId)
					local cube = mk("Frame", {
						BackgroundColor3 = (def and def.color) or tierCol,
						Size = UDim2.fromScale(1, 1),
						ZIndex = 3,
					}, artHost)
					round(cube, 10)
					stroke(cube, 2, tierCol)
					if def and def.icon and def.icon ~= "rbxassetid://0" then
						mk("ImageLabel", {
							BackgroundTransparency = 1,
							Image = def.icon,
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromScale(0.78, 0.78),
							ScaleType = Enum.ScaleType.Fit,
							ZIndex = 4,
						}, artHost)
					end
					local gradeL = mk("TextLabel", {
						BackgroundTransparency = 1,
						Font = FONT,
						Text = tostring(g.startGrade or "F"),
						TextSize = 18,
						TextColor3 = tierCol,
						AnchorPoint = Vector2.new(0.5, 1),
						Position = UDim2.new(0.5, 0, 1, 2),
						Size = UDim2.new(1, 0, 0, 18),
						ZIndex = 5,
					}, artHost)
					if LBmod and LBmod.blockStars then
						starRow(tile, LBmod.blockStars(g.blockId or g.packId, g.startGrade), 86, 13)
					end
				else
					PackFX.drawSealed(artHost, g.packId, 54, 74)
				end
				local peek = mk("TextButton", {
					BackgroundTransparency = 1,
					Text = "",
					TextSize = 14,
					AutoButtonColor = false,
					Position = UDim2.fromOffset(0, 8),
					Size = UDim2.new(1, 0, 0, 146),
					ZIndex = 5,
				}, tile)
				peek.MouseButton1Click:Connect(function()
					if g.kind == "lucky_block" then
						-- No odds sheet for a block: the art opens its tap screen.
						if not state.busy and opts.onOpenLucky then
							opts.onOpenLucky(g)
						end
						return
					end
					showPackInspect(g)
				end)
				infoBadge(tile, g)
				if (g.luckPct or 0) > 0 then
					local luckBadge = mk("Frame", {
						BackgroundColor3 = Color3.fromRGB(36, 120, 72),
						AnchorPoint = Vector2.new(0, 0),
						Position = UDim2.fromOffset(8, 12),
						Size = UDim2.fromOffset(78, 22),
						ZIndex = 6,
					}, tile)
					round(luckBadge, 6)
					local luckL = label(luckBadge,
						string.format("+%d%% LUCK", g.luckPct),
						11, Color3.fromRGB(230, 255, 236),
						UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), FONT)
					luckL.TextXAlignment = Enum.TextXAlignment.Center
					luckL.ZIndex = 7
				end
				local nameL = label(tile, g.tierName, 15, TEXT, UDim2.fromOffset(8, 98),
					UDim2.new(1, -16, 0, 20), FONT)
				nameL.TextXAlignment = Enum.TextXAlignment.Center
				nameL.TextTruncate = Enum.TextTruncate.AtEnd
				local setL = label(tile, g.setName, 12, MUTED, UDim2.fromOffset(8, 118),
					UDim2.new(1, -16, 0, 18))
				setL.TextXAlignment = Enum.TextXAlignment.Center
				setL.TextTruncate = Enum.TextTruncate.AtEnd
				if g.count > 1 then
					-- Quantity sits top-left (packs + lucky blocks share this tile).
					-- Stack under the luck chip when both are present.
					local qtyY = ((g.luckPct or 0) > 0) and 38 or 12
					local badge = mk("Frame", {
						BackgroundColor3 = tierCol,
						AnchorPoint = Vector2.new(0, 0),
						Position = UDim2.fromOffset(8, qtyY),
						Size = UDim2.fromOffset(42, 22),
						ZIndex = 6,
					}, tile)
					round(badge, 11)
					label(badge, "x" .. g.count, 13, Color3.fromRGB(18, 14, 10),
						UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), FONT).TextXAlignment =
						Enum.TextXAlignment.Center
				end
				-- How many cards you get. It was never stated anywhere, and the
				-- packs do not all pay the same: 1, 3, 6 and 8 all exist.
				local cardsL = label(tile, (g.cards > 0)
					and (g.cards .. " " .. (Packs.unitWord and Packs.unitWord(g.packId, g.cards) or "cards")) or "",
					12, tierCol, UDim2.fromOffset(8, 136), UDim2.new(1, -16, 0, 16), FONT)
				cardsL.TextXAlignment = Enum.TextXAlignment.Center

				--[[
					OPEN ONE, TEN, OR THE STACK.

					"Open all" used to live in the corner and empty the whole
					bag. The decision actually belongs to the stack you are
					looking at, so it lives here: the big button opens one, and
					the thin row under it offers ten and the lot.

					Ten is only offered when there ARE ten. Asking for ten off a
					stack of six still pays six -- the server clamps to what you
					hold -- but a button that says x10 above a stack of six is a
					button that lies, so below ten the row collapses to a single
					honest "ALL n".
				]]
				local function fire(count)
					if state.busy then
						return
					end
					-- Lucky blocks open on their own tap-through screen.
					if g.kind == "lucky_block" then
						if count == 1 then
							if opts.onOpenLucky then
								opts.onOpenLucky(g)
							end
						elseif opts.onOpenLuckyMany then
							opts.onOpenLuckyMany(g, count)
						end
						return
					end
					if count == 1 then
						if opts.onOpenPack then
							-- The stack is a display grouping; the server still
							-- opens one specific pack, so name it by its own id.
							opts.onOpenPack(g.firstIndex, g.uid)
						end
					elseif opts.onOpenMany then
						opts.onOpenMany(g.packId, count, g.uid)
					end
				end

				local open = mk("TextButton", {
					AutoButtonColor = true,
					BackgroundColor3 = GREEN,
					Font = FONT,
					TextSize = 16,
					TextColor3 = Color3.fromRGB(10, 26, 16),
					Text = "OPEN",
					Position = UDim2.fromOffset(10, 156),
					Size = UDim2.new(1, -20, 0, 32),
				}, tile)
				round(open, 7)
				open.MouseButton1Click:Connect(function()
					fire(1)
				end)

				if g.count > 1 then
					local row = mk("Frame", {
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(10, 192),
						Size = UDim2.new(1, -20, 0, 26),
					}, tile)
					local function chip(text, count, x, w)
						local b = mk("TextButton", {
							AutoButtonColor = true,
							BackgroundColor3 = BG,
							Font = FONT,
							TextSize = 13,
							TextColor3 = tierCol,
							Text = text,
							Position = UDim2.fromOffset(x, 0),
							Size = UDim2.fromOffset(w, 26),
						}, row)
						round(b, 6)
						stroke(b, 1, tierCol)
						b.MouseButton1Click:Connect(function()
							fire(count)
						end)
						return b
					end
					if g.count >= 10 then
						chip("x10", 10, 0, 64)
						chip("ALL " .. g.count, g.count, 68, 64)
					else
						chip("ALL " .. g.count, g.count, 0, 132)
					end
				end
			end
		end
		if shown == 0 then
			grid:Destroy()
			note(body, "Nothing matches that search.")
		end
	end
	local function renderOwnedCards()
		local cards = state.cards or {}
		if #cards == 0 then
			note(body, "No cards yet. Open a pack.")
			return
		end
		local eq = {}
		for _, id in ipairs(state.equipped or {}) do
			eq[id] = true
		end
		--[[
			EQUIP BEST, here with the pets. It was a button on the dock, which is
			a strange place for it -- the dock is how you open things, not how you
			pick your team.
		]]
		do
			local better = tonumber((state.upgrades or {}).pets) or 0
			local row = panelRow(body, 46, 0)
			label(row, better > 0
				and ("You own " .. better .. (better == 1 and " stronger pet" or " stronger pets") .. " than the ones you are running")
				or "Your strongest pets are already out", 13, better > 0 and GOLD or MUTED,
				UDim2.fromOffset(14, 0), UDim2.new(1, -170, 1, 0))
			local b = mk("TextButton", {
				AutoButtonColor = better > 0, BackgroundColor3 = better > 0 and GREEN or BG3,
				Text = better > 0 and "EQUIP BEST" or "ALL SET", Font = FONT, TextSize = 14,
				TextColor3 = better > 0 and Color3.fromRGB(16, 38, 20) or MUTED,
				Size = UDim2.fromOffset(132, 32), Position = UDim2.new(1, -146, 0.5, -16),
			}, row)
			round(b, 8)
			if better > 0 then
				b.MouseButton1Click:Connect(function()
					if opts.onEquipBest then opts.onEquipBest() end
				end)
			end
		end
		--[[
			MERGE LIVES HERE NOW. The separate Merge screen is gone; three
			identical copies (same card, rarity, variant) show a MERGE button on
			their tiles. The server re-counts the copies and burns two, so this
			button only ever NAMES a card — it cannot lie about what is owned.
		]]
		local mergeCount = {}
		for _, card in ipairs(cards) do
			local key = tostring(card.cardKey) .. "|" .. tostring(card.rarityId) .. "|" .. tostring(card.variant or "Normal")
			mergeCount[key] = (mergeCount[key] or 0) + 1
		end
		-- Mint order is the tiebreak for "New", so it has to be captured before the
		-- list is reordered.
		local indexOf, list = {}, {}
		for i, card in ipairs(cards) do
			indexOf[card] = i
			list[i] = card
		end
		table.sort(list, function(a, b)
			return cardLess(a, b, cardSort, eq, indexOf, mergeCount)
		end)
		local wrap = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -6, 0, 456),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, body)
		local grid = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -124, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, wrap)
		local CW = 128
		local CH = math.floor(CW * 3.5 / 2.5 + 0.5)
		mk("UIGridLayout", {
			CellPadding = UDim2.fromOffset(8, 8),
			CellSize = UDim2.fromOffset(CW, CH),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, grid)
		local shown = 0
		for i, card in ipairs(list) do
			if matches(table.concat({ card.name or "", card.setName or "", card.typeId or "",
				card.rarityId or "", card.variant or "" }, " ")) then
				shown += 1
				local slot = mk("TextButton", {
					BackgroundTransparency = 1,
					AutoButtonColor = false,
					Text = "",
					LayoutOrder = i,
				}, grid)
				if opts.paintCard then
					opts.paintCard(slot, card, CW)
				end
				local onTeam = eq[card.id] or eq[card.serial]
				if onTeam then
					local tag = mk("Frame", {
						BackgroundColor3 = GREEN,
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.new(1, -7, 0, 7),
						Size = UDim2.fromOffset(48, 18),
						ZIndex = 6,
					}, slot)
					round(tag, 6)
					label(tag, "TEAM", 11, Color3.fromRGB(10, 26, 16), UDim2.fromOffset(0, 0),
						UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center).ZIndex = 7
				end
				local mkey = tostring(card.cardKey) .. "|" .. tostring(card.rarityId) .. "|" .. tostring(card.variant or "Normal")
				if (mergeCount[mkey] or 0) >= 3 then
					local mb = mk("TextButton", {
						AutoButtonColor = true,
						BackgroundColor3 = GOLD,
						Font = FONT,
						TextSize = 12,
						TextColor3 = Color3.fromRGB(24, 20, 12),
						Text = "MERGE 3 → UP",
						AnchorPoint = Vector2.new(0.5, 1),
						Position = UDim2.new(0.5, 0, 1, -6),
						Size = UDim2.fromOffset(CW - 20, 24),
						ZIndex = 8,
					}, slot)
					round(mb, 7)
					mb.MouseButton1Click:Connect(function()
						if opts.onMerge then
							opts.onMerge(card.id or card.serial)
						end
					end)
				end
				slot.MouseButton1Click:Connect(function()
					local cardId = card.id or card.serial
					if not cardId then
						return
					end
					if onTeam then
						if opts.onUnequip then opts.onUnequip(cardId) end
					else
						if opts.onEquip then
							opts.onEquip({ id = cardId, slot = cardPetSeat })
						end
						local cap = math.max(3, math.floor(tonumber(state.petSlotsEffective or state.petSlots) or 3))
						local n = math.max(4, cap)
						local nxt = cardPetSeat % n + 1
						local guard = 0
						while nxt > cap and guard < n do
							nxt = nxt % n + 1
							guard += 1
					end
						cardPetSeat = nxt
						render()
					end
				end)
			end
		end
		if shown == 0 then
			grid:Destroy()
			note(body, "Nothing matches that search.")
		end
		do
			local petCap = math.max(3, math.floor(tonumber(state.petSlotsEffective or state.petSlots) or 3))
			if cardPetSeat > petCap then
				cardPetSeat = 1
			end
			local rail = mk("Frame", {
				Name = "TeamRail",
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.fromOffset(116, 456),
			}, wrap)
			label(rail, "TEAM", 11, GOLD, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 16), FONT, Enum.TextXAlignment.Center)
			for i = 1, 4 do
				local locked = i > petCap
				local petId = (state.equipped or {})[i]
				local pet = nil
				if petId then
					for _, c in ipairs(state.cards or {}) do
						if c.id == petId then pet = c break end
					end
				end
				local chosen = (not locked) and cardPetSeat == i
				local box = mk("TextButton", {
					AutoButtonColor = true, Text = "",
					BackgroundColor3 = chosen and BG3 or (locked and Color3.fromRGB(18, 18, 24) or BG2),
					Position = UDim2.fromOffset(0, 18 + (i - 1) * 108),
					Size = UDim2.fromOffset(116, 104),
				}, rail)
				round(box, 8)
				stroke(box, chosen and 2 or 1, chosen and GOLD or nil)
				label(box, locked and ("PET " .. i .. " VIP") or ("PET " .. i), 10,
					chosen and GOLD or MUTED, UDim2.fromOffset(4, 4), UDim2.new(1, -8, 0, 14), FONT, Enum.TextXAlignment.Center)
				if pet and opts.petViewport then
					pcall(opts.petViewport, box, pet, UDim2.fromOffset(18, 20), UDim2.fromOffset(80, 62))
					for _, ch in ipairs(box:GetChildren()) do
						if ch:IsA("ViewportFrame") then
							ch.BackgroundTransparency = 1
						end
					end
				elseif locked then
					label(box, "VIP", 16, MUTED, UDim2.fromOffset(0, 36), UDim2.new(1, 0, 0, 24), FONT, Enum.TextXAlignment.Center)
				else
					label(box, "+", 22, Color3.fromRGB(88, 88, 98), UDim2.fromOffset(0, 32), UDim2.new(1, 0, 0, 28), FONT, Enum.TextXAlignment.Center)
				end
				label(box, pet and tostring(pet.name or "Pet") or (locked and "GET VIP" or "empty"), 11,
					pet and TEXT or MUTED, UDim2.fromOffset(4, 84), UDim2.new(1, -8, 0, 16), FONT, Enum.TextXAlignment.Center)
				box.MouseButton1Click:Connect(function()
					if locked then
						if opts.onBuyVipPass then opts.onBuyVipPass() end
						return
					end
					cardPetSeat = i
					render()
				end)
			end
		end
	end
	-- running right now rather than an empty grid with a coming-soon label on it.
	local BOOST_LABEL = {
		mineSpeed = "Damage", oreYield = "Blast", luck = "Luck", walkSpeed = "Walk speed",
		dirtBreak = "Dirt Break", backpack = "Backpack", rareOre = "Rare find",
		coinBonus = "Coins", gemFind = "Gems", chestLuck = "Chest luck",
	swingRate = "Swing rate", blastRadius = "Blast radius", autoMine = "Gem Find",
		echo = "Echo", zap = "Zap", luckyFind = "Lucky Block find",
		fossilFind = "Fossil Finder", pulverize = "Pulverizer",
		scrap = "Scrap", coolant = "Coolant", shortFuse = "Short Fuse", reach = "Reach",
	}
	----------------------------------------------------------------------------
	-- EQUIPMENT: the character screen (Inventory -> Equipment) and the helpers
	-- it shares. Gear and charms are slots on it; they had tabs of their own
	-- once. Collection -> Equipment is the full dex.
	----------------------------------------------------------------------------

	local function sectionHeader(text, order)
		local h = mk("Frame", { BackgroundTransparency = 1,
			Size = UDim2.new(1, -6, 0, 24), LayoutOrder = order }, body)
		label(h, string.upper(text), 13, MUTED, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0), FONT)
		return h
	end

		-- Letter grades (F..SSS) for gear; found tools carry card-style names
		-- (Common..Exotic), so fall through to the card colours for those.
		local function gradeInk(rarity)
			return (rarity and (Gear.RARITY_COLOR[rarity] or (Cards.RARITY_COLOR and Cards.RARITY_COLOR[rarity])))
				or MUTED
		end
		-- MineIridescence now only draws the S / SS / SSS mark and leaves the
		-- tile its own colours; `apply` no longer exists, and calling it was
		-- erroring every render that reached a graded piece.
		local function paintGrade(host, rarity, st)
			if Irid.apply then
				Irid.apply(host, rarity, { stroke = st })
			elseif Irid.badge then
				Irid.badge(host, rarity, { height = 22 })
			end
			return gradeInk(rarity)
		end

		-- What is fitted, in words. "+2 slots" tells you the piece could hold runes;
	-- it does not tell you whether it does, which is the thing you want to know
	-- while deciding what to wear.
	local function runeSummary(sockets, slots)
		local Runes = require(shared:WaitForChild("MineRunes"))
		local byId = {}
		for _, r in ipairs(state.runes or {}) do
			byId[r.id] = r
		end
		local bits = {}
		for i = 1, (slots or 0) do
			local id = sockets and sockets[i]
			local rune = id and byId[id]
			if rune then
				bits[#bits + 1] = string.format("%s +%.0f%%", tostring(rune.stat), (rune.pct or 0) * 100)
			end
		end
		if #bits == 0 then
			return (slots or 0) > 0 and ((slots or 0) .. " empty socket" .. ((slots == 1) and "" or "s")) or "no sockets"
		end
		return table.concat(bits, "   ")
	end

	--[[
		THE CHARACTER SCREEN  (Inventory -> Equipment)

		Eight slots around you, you in the middle of them. Four down the left --
		head, chestplate, leggings, boots -- and four down the right -- face,
		amulet, charm, tool. That is the whole layout, and it is the one every
		player has already used in some other game, which is the point.

		The eight are not one system underneath. Six are gear pieces out of the
		Enchanter, one is a charm, one is a tool -- and a tool is itself four
		different things depending on where it came from (a coin rung, a depth
		desk rung, a chest drop, a fossil you assembled). Every one of those has
		its own equip verb on the server already. Rather than unify them, which
		would mean rewriting four working systems, this screen puts them behind
		one shape: `item`. Pick a slot, see what fits it, tap one, read the card.

		Selecting a slot is a filter, not a mode. The list under the paperdoll is
		everything that goes in the selected slot; under that is the rest of the
		bag, so you can still see what you own without hunting through slots.
	]]
--[[
		The wearers, not the slots.

		Gear is a hat and a face now, and a hat goes on a PET -- so what this
		screen lists is everyone who can wear something: you, your face, and
		your three pets. pet1..pet3 are not gear slots, they are seats: all
		three take hats, and which pet is in a seat is whichever pet you are
		running in that slot.
	]]
	--[[
		THE SEATS. Three hats, a face, a charm, a tool, a backpack.

		The right-hand column used to be "Pet 1 Hat" through "Pet 4 Hat" -- a hat
		seat per pet, with the fourth locked behind VIP. Pets wear no hats now and
		there is no fourth pet, so that whole column is gone and the hat seats it
		was competing with moved to the left where the rest of your own gear is.

		Nothing here is locked any more. That mattered: advanceSlot and several
		readers walk this list looking for `locked`, and a list with none means
		every seat is reachable by every player.
	]]
	local function EQUIP_SLOTS()
		local slots = {}
		for i, slot in ipairs(Gear.HAT_SLOTS or { "hat" }) do
			table.insert(slots, {
				id = slot,
				label = (i == 1) and "Your Hat" or ("Your Hat " .. i),
				side = "L",
				hat = i,
			})
		end
		table.insert(slots, { id = "face", label = "Your Face", side = "L" })
		table.insert(slots, { id = "charm", label = "Charm", side = "R" })
		table.insert(slots, { id = "tool", label = "Tool", side = "R" })
		table.insert(slots, { id = "backpack", label = "Backpack", side = "R" })
		return slots
	end
	-- Which slot is being filled, and the open item card. Outside render() so a
	-- snapshot arriving mid-decision does not throw you back to the tool slot.
	local eq = { slot = "hat", card = nil, sellMode = false, sellSelect = {} }

	function eq.advanceSlot()
		local slots = EQUIP_SLOTS()
		local idx = 0
		for i, s in ipairs(slots) do
			if s.id == eq.slot then
				idx = i
				break
			end
		end
		for i = idx + 1, #slots do
			if not slots[i].locked then
				eq.slot = slots[i].id
				return
			end
		end
		for i = 1, math.max(1, idx) do
			if not slots[i].locked then
				eq.slot = slots[i].id
				return
			end
		end
	end


	local function cardNamed(cardId)
		for _, c in ipairs(state.cards or {}) do
			if c.id == cardId then
				return c
			end
		end
		return nil
	end

	-- Where a piece is right now, in words, so the list can say "on Aurora"
	-- instead of quietly showing the same hat as available in four places.
	local function gearWearer(gearId)
		local g = state.equippedGear or {}
		for i, slot in ipairs(Gear.HAT_SLOTS or { "hat" }) do
			if g[slot] == gearId then
				-- Name the seat, not just "your head": with three of them, "it is
				-- already on" is not an answer to "where is it".
				return "in hat seat " .. i
			end
		end
		if g.face == gearId then
			return "on your face"
		end
		return nil
	end

	-- What a tool actually does, in the four numbers a player compares. Reach is
	-- in here because it is the stat nobody expects to differ and always does.
	local function toolStats(def)
		local rows = {}
		local fam = Tools.family(def.family or "pickaxe")
		table.insert(rows, { "Type", (fam and fam.name and fam.name:gsub("s$", "")) or "Pickaxe" })
		table.insert(rows, { "Damage", commas(math.floor(tonumber(def.power) or 0)) .. " per hit" })
		if def.cooldown then
			table.insert(rows, { "Cooldown", string.format("%.1fs", def.cooldown) })
		else
			table.insert(rows, { "Speed", string.format("%.1f / sec", tonumber(def.rate) or 0) })
		end
		local pattern
		if def.family == "drill" then
			local w = tonumber(def.width) or 1
			pattern = w .. "x" .. w .. " " .. ((def.axis == "down") and "down" or "forward")
		elseif def.family == "explosive" then
			pattern = commas(Tools.cellsOf(def)) .. " cells"
			if (tonumber(def.bombs) or 1) > 1 then
				pattern = pattern .. " · " .. def.bombs .. " charges"
			end
		else
			pattern = "single block"
		end
		table.insert(rows, { "Pattern", pattern })
		table.insert(rows, { "Reach", math.floor(Tools.reachOf(def)) .. " studs" })
		if def.turn and def.turn > 0 then
			table.insert(rows, { "Turn", string.format("%.2fs spin-up", def.turn) })
		end
		if def.special then
			table.insert(rows, { "Special", tostring(def.special) })
		end
		return rows
	end

	--[[
		Everything you own that could go in `slotId`, as one shape.

		`sell` is the payout quoted straight off MineTools, the same call the
		server makes when it pays -- so the number on the confirm screen is the
		number that lands, not a second estimate that can drift away from it.
	]]
	local function equipItems(slotId)
		local out = {}
		if slotId == "tool" then
			local famOrder = { "pickaxe", "drill", "explosive" }
			-- Exactly one tool source is active (matches server equippedTool):
			-- chest > fossil > shop > ladder. Stale dual flags must not paint
			-- two tiles EQUIPPED.
			local eqSrc, eqId
			if state.chestTool then
				eqSrc, eqId = "forever", state.chestTool
			elseif state.fossilTool then
				eqSrc, eqId = "fossil", state.fossilTool
			elseif state.shopToolId then
				eqSrc, eqId = "shop", state.shopToolId
			elseif state.tool and state.tool.id then
				eqSrc, eqId = "ladder", state.tool.id
			end
			-- 1. Coin ladder. Owning tier N means owning 1..N, so only the top
			--    rung can be sold -- there is no taking one out of the middle.
			for _, famId in ipairs(famOrder) do
				local ownedTier = tonumber((state.tools or {})[famId]) or 0
				for tier = ownedTier, 1, -1 do
					local def = (Tools.TOOLS[famId] or {})[tier]
					if def then
						local top = (tier == ownedTier)
						local coins = top and Tools.ladderSellValue(def) or 0
						table.insert(out, {
							key = "ladder|" .. famId .. "|" .. tier,
							name = def.name, sub = "Coin shop · tier " .. tier .. " · untradable",
							rarity = (Tools.rarityForPower and Tools.rarityForPower(def.power)) or nil, icon = Icons.image(def.id) or nil, id = def.id, def = def, slot = "tool",
							source = "ladder", family = famId, tier = tier,
							lowerRung = not top,
							equipped = eqSrc == "ladder" and eqId == def.id,
							sell = (coins > 0) and { coins = coins } or nil,
							why = (coins <= 0) and (top and "The starter tool stays with you"
								or "Only the top rung of a ladder can be sold") or nil,
						})
					end
				end
			end
			-- 2. Depth-desk rungs. Bought with coins too, but each one is its
			--    own purchase rather than a rung, so any of them can go.
			do
				local okL, Ladders = pcall(function()
					return require(shared:WaitForChild("MineShopLadders"))
				end)
				if okL and Ladders then
					for id in pairs(state.ownedShopTools or {}) do
						local row = Ladders.byId and Ladders.byId(id)
						if row then
							table.insert(out, {
								key = "shop|" .. id,
								name = row.name, sub = (row.blurb or "Depth shop") .. " · untradable",
								rarity = (Tools.rarityForPower and Tools.rarityForPower(row.power)) or nil, icon = Icons.image(id) or nil,
								def = row, slot = "tool", source = "shop", id = id, family = row.family,
								equipped = eqSrc == "shop" and eqId == id,
								sell = { coins = Tools.ladderSellValue(row) },
							})
						end
					end
				end
			end
			-- 3 and 4. Forever tools: nothing on a shelf refunds these, so they
			--    pay in stardust and temper tokens instead of coins.
			for _, row in ipairs(state.chestTools or {}) do
				local def = Tools.chestTool(row.id)
				if def then
					local dust, tokens = Tools.foreverSellValue(def, row)
					table.insert(out, {
						key = "forever|" .. tostring(row.id),
						name = (row.nightmare and "Nightmare " or row.shadow and "Shadow " or row.shiny and "Shiny " or "") .. (def.name or row.id),
						sub = tostring(def.rarity or "Found") .. " · chest",
						rarity = def.rarity or (Tools.chestRarityFromDrop and def.drop and Tools.chestRarityFromDrop(def.drop)) or (Tools.rarityForPower and Tools.rarityForPower(def.power)), icon = Icons.image(row.id) or nil, def = def, owned = row, slot = "tool",
						source = "forever", id = row.id,
						equipped = eqSrc == "forever" and eqId == row.id,
						sockets = row.sockets, runeId = row.runeId,
						sell = { dust = dust, tokens = tokens },
						why = row.runeId and "Unsocket its rune first" or nil,
					})
				end
			end
			for key, row in pairs(state.fossilTools or {}) do
				if type(row) == "table" then
					local dust, tokens = Tools.foreverSellValue(row, row)
					table.insert(out, {
						key = "fossil|" .. tostring(key),
						name = row.name or tostring(key), sub = "Assembled fossil",
						rarity = row.rarity or (Tools.rarityForPower and Tools.rarityForPower(row.power)), icon = Icons.image(key) or nil, def = row, owned = row, slot = "tool",
						source = "fossil", id = key,
						equipped = eqSrc == "fossil" and eqId == key,
						runeId = row.runeId,
						sell = { dust = dust, tokens = tokens },
						why = row.runeId and "Unsocket its rune first" or nil,
					})
				end
			end
		elseif slotId == "backpack" then
			local packs = C.BACKPACKS or {}
			local have = math.clamp(math.floor(tonumber(state.backpackTier) or 1), 1, math.max(1, #packs))
			local def = packs[have]
			if def then
				local cap = def.infinite and "Infinite dirt" or (tostring(def.slots or 0) .. " dirt")
				table.insert(out, {
					key = "backpack|" .. tostring(have),
					name = def.name or ("Backpack " .. have),
					sub = cap .. " - shop",
					source = "backpack",
					id = have,
					equipped = true,
					why = "Capacity from the backpack shop",
				})
			end
		elseif slotId == "charm" then
			local Charms = require(shared:WaitForChild("MineCharms"))
			for _, def in ipairs(Charms.LIST or {}) do
				if (state.charms or {})[def.id] then
					table.insert(out, {
						key = "charm|" .. def.id,
						name = def.name, sub = def.blurb or def.source or "Charm",
						def = def, slot = "charm", source = "charm", id = def.id,
						equipped = state.equippedCharm == def.id,
						why = "Charms are kept, not sold",
					})
				end
			end
		else
			do
			--[[
				A hat seat lists every hat you own; the face seat every face.

				There is no locked seat and no pet seat any more, so the branch
				that put up a "Fourth pet seat -- VIP unlocks one more team pet"
				card is gone with them.
			]]
			local isHatSeat = table.find(Gear.HAT_SLOTS or { "hat" }, slotId) ~= nil
			local gearSlot = slotId
			local wornId = (state.equippedGear or {})[gearSlot]
			for _, g in ipairs(state.gear or {}) do
				local match = (isHatSeat and Gear.isHatPiece(g))
					or (gearSlot == "face" and Gear.isFacePiece(g))
					or ((not isHatSeat) and gearSlot ~= "face" and Gear.migrateSlot(g.slot) == gearSlot)
				if match then
					-- A piece is equipped in THIS seat only. A hat in seat 1 must
					-- not light up as EQUIPPED while you are looking at seat 2 --
					-- gearWearer says where it actually is instead.
					local on = wornId == g.id
					local sub = (Gear.hatEffectLine and Gear.hatEffectLine(g))
						or ("+" .. math.floor((tonumber(g.pct) or 0) * 100 + 0.5) .. "% " .. eq.statLabel(g.stat))
					if gearSlot == "face" and sub ~= "" then
						sub = sub .. "  ·  scales hats"
					end
					local elsewhere = (not on) and gearWearer(g.id) or nil
					if elsewhere then
						sub = sub .. "  (" .. elsewhere .. ")"
					end
					table.insert(out, {
						key = "gear|" .. tostring(g.id) .. "|" .. tostring(slotId),
						name = (g.rarity or "") .. " " .. (g.name or g.setName or ""),
						sub = sub,
						rarity = g.rarity, def = g, slot = slotId, source = "gear", id = g.id,
						equipped = on,
						sockets = g.sockets, slotCount = g.slotCount,
						icon = (g.catalogId and NG and NG.icon(g.catalogId))
							or (Gear.image and Gear.image(g)) or nil,
						sell = { gems = Gear.scrapGems(g) },
						why = on and "Take it off first" or (elsewhere and ("Worn " .. elsewhere) or nil),
					})
				end
			end
			table.sort(out, function(a, b)
				local ra = Gear.RARITY_RANK[a.rarity] or 0
				local rb = Gear.RARITY_RANK[b.rarity] or 0
				if ra ~= rb then
					return ra > rb
				end
				return tostring(a.name) < tostring(b.name)
			end)
			end
		end
		return out
	end

	-- The piece currently in a slot, or nil.
	local function equippedIn(slotId)
		local petItem
		for _, it in ipairs(equipItems(slotId)) do
			if it.equipped then
				if it.source == "pet" then
					petItem = it
				else
					return it
				end
			end
		end
		return petItem
	end

	-- (These hang off `eq` rather than being locals of their own: mount() is a
	-- long function and Luau caps it at 200 locals.)

	--[[
		The grade letter for anything on this screen. Gear carries F..SSS itself;
		found tools carry the card ladder's names, which map onto the same
		letters (MineTemper.LEGACY_RARITY: Common = F ... Exotic = SSS). Coin
		rungs and charms have no grade, so they get no letter.
	]]
	-- Stat names as players read them, straight off MineStats so this screen and
	-- the card faces cannot disagree.
	function eq.statLabel(stat)
		if not eq._stats then
			local ok, S = pcall(require, shared:WaitForChild("MineStats"))
			eq._stats = (ok and S and S.STATS) or {}
		end
		local def = eq._stats[stat]
		return (def and def.label) or tostring(stat or "?")
	end

	-- Compact dig-kit line for equipment seats: "Pet: +40% luck · +22% bag"
	local PET_KIT_SHORT = {
		mineSpeed = "dmg", oreYield = "blast", luck = "luck", walkSpeed = "walk",
		dirtBreak = "dirt", backpack = "bag", rareOre = "rare", coinBonus = "coins",
		gemFind = "gems", chestLuck = "chest", swingRate = "swing", blastRadius = "boom",
		echo = "echo", zap = "zap", autoMine = "gems", luckyFind = "lucky",
		fossilFind = "fossil", pulverize = "pulverize",
	}
	local PET_KIT_ADD = {
		echo = true, zap = true, blastRadius = true, autoMine = true, oreYield = true,
		luckyFind = true, fossilFind = true, pulverize = true, scrap = true,
		coolant = true, shortFuse = true, reach = true,
	}
	function eq.petKitLine(card)
		if not card then
			return nil
		end
		local b = Cards.emptyBoosts()
		local nEq = math.max(1, #(state.equipped or {}))
		pcall(Cards.applyKit, b, card, 1, nEq)
		pcall(Cards.foldSwingRate, b)
		local e = Cards.emptyBoosts()
		local rows = {}
		for k, v in pairs(b) do
			local e0 = e[k]
			if type(v) == "number" and type(e0) == "number" and v ~= e0 then
				local amt, stat = nil, k
				if PET_KIT_ADD[k] then
					amt = v - e0
				elseif k == "swingSec" then
					amt = e0 / math.max(0.01, v) - 1
					stat = "swingRate"
				elseif e0 ~= 0 then
					amt = v / e0 - 1
				end
				if amt and math.abs(amt) >= 0.005 then
					table.insert(rows, { stat = stat, amt = amt })
				end
			end
		end
		if #rows == 0 then
			local named = Cards.namedBoosts and Cards.namedBoosts(card)
			if named then
				local okS, Stats = pcall(function()
					return require(shared:WaitForChild("MineStats"))
				end)
				if okS and Stats and Stats.withoutAutoMine then
					named = Stats.withoutAutoMine(named)
				end
				for stat, amount in pairs(named) do
					if type(amount) == "number" and math.abs(amount) >= 0.005 then
						table.insert(rows, { stat = stat, amt = amount })
					end
				end
			elseif card.setId and card.index then
				local kit = Cards.getKit(card.setId, card.index)
				if kit and kit.primary then
					table.insert(rows, { stat = kit.primary, amt = kit.primaryBase or 0 })
					if kit.secondary then
						table.insert(rows, { stat = kit.secondary, amt = kit.secondaryBase or 0 })
					end
				end
			end
		end
		if #rows == 0 then
			return nil
		end
		table.sort(rows, function(a, b)
			return math.abs(a.amt) > math.abs(b.amt)
		end)
		local bits = {}
		for i = 1, math.min(3, #rows) do
			local r = rows[i]
			local pct = math.floor(r.amt * 100 + (r.amt >= 0 and 0.5 or -0.5))
			local lab = PET_KIT_SHORT[r.stat] or tostring(r.stat)
			table.insert(bits, string.format("%+d%% %s", pct, lab))
		end
		return "Pet: " .. table.concat(bits, " · ")
	end

	function eq.letterOf(item)
		local r = item and item.rarity
		if not r then
			return nil
		end
		if Gear.RARITY_RANK[r] then
			return r
		end
		local Temper = require(shared:WaitForChild("MineTemper"))
		return Temper.LEGACY_RARITY and Temper.LEGACY_RARITY[r] or nil
	end

	-- How good a thing is, on a scale that only means anything inside one slot.
	-- Gear: grade, then sockets, then its bonus. Tools: MineTools.budget, the
	-- game's own measure, with a shiny or shadow finish counted. Charms: the
	-- sum of their stat multipliers.
--[[
		The rune pane is the Enchanter's own sockets screen, mounted here once.

		It hangs off `root` rather than `body` because body is cleared and
		rebuilt on every render, which would destroy it mid-decision -- and it is
		mounted lazily so a player who never opens the tab never pays for it.
	]]
	function eq.socketsPane()
		if eq.socketsBroken then
			return nil
		end
		if not eq.sockets then
			local ok, SV = pcall(require, shared:WaitForChild("MineSocketsView"))
			if not (ok and type(SV) == "table" and SV.mount) then
				eq.socketsBroken = true
				return nil
			end
			local ok2, view = pcall(SV.mount, root, {
				onSocket = function(item, runeId, index)
					if opts.onSocketAny then
						opts.onSocketAny(item, runeId, index)
					end
				end,
			})
			if not (ok2 and type(view) == "table") then
				eq.socketsBroken = true
				return nil
			end
			eq.sockets = view
		end
		return eq.sockets
	end

	function eq.strength(item)
		if not item then
			return nil
		end
		if item.source == "gear" then
			local g = item.def
			if Gear.powerScore then
				return Gear.powerScore(g)
			end
			return (Gear.RARITY_RANK[g.rarity] or 0) * 1000 + (g.slotCount or 0) * 10 + (g.pct or 0)
		elseif item.slot == "tool" then
			local o = item.owned
			local finish = (o and o.nightmare and (C.NIGHTMARE_MULT or 4.5))
				or (o and o.shadow and (C.SHADOW_MULT or C.SHADOW_TOOL_MULT or 2))
				or (o and o.shiny and (C.SHINY_MULT or 1.5)) or 1
			return Tools.budget(item.def) * finish
		elseif item.source == "charm" then
			local sum = 0
			for _, v in pairs(item.def.stats or {}) do
				sum += tonumber(v) or 0
			end
			return sum
		end
		return nil
	end

	-- Would wearing this beat what is in its slot now? An empty slot is beaten
	-- by anything that actually adds something -- a face piece at F is -75% and
	-- is worse than wearing nothing, so that one does not get the arrow.
	function eq.isUpgrade(item, worn)
		if not item or item.equipped then
			return false
		end
		local mine = eq.strength(item)
		if mine == nil then
			return false
		end
		if not worn then
			if item.source == "gear" then
				return (item.def.pct or 0) > 0 or (item.def.slotCount or 0) > 0
			end
			return true
		end
		local theirs = eq.strength(worn)
		return theirs ~= nil and mine > theirs
	end

	--[[
		An item's picture: art in the middle, grade letter in the bottom-right
		corner, and a green arrow in the top-left when it beats what you are
		wearing. One drawing for the paperdoll, the slot list and the backpack,
		so the three can never disagree about what a thing is. `item` nil draws
		an empty slot.
	]]
	function eq.thumb(parent, item, size, pos, upgrade)
		local locked = item and (item.locked or item.discovered == false)
		local rarity = (not locked) and item and item.rarity or nil
		if item and not locked and item.slot == "tool" then
			rarity = toolGradeOf(item)
		end
		local ink = locked and Color3.fromRGB(36, 36, 44)
			or (rarity and gradeInk(rarity))
			or Color3.fromRGB(88, 88, 98)
		local bg = locked and Color3.fromRGB(18, 18, 24) or BG3
		if rarity and not locked then
			bg = gradeInk(rarity):Lerp(Color3.fromRGB(16, 14, 20), 0.62)
		end
		local box = mk("Frame", {
			BackgroundColor3 = bg,
			Position = pos or UDim2.new(),
			Size = UDim2.fromOffset(size, size),
			ZIndex = (parent.ZIndex or 1) + 1,
		}, parent)
		round(box, 8)
		if item then
			stroke(box, (not locked and rarity) and 2 or 1, ink)
		end
		local z = box.ZIndex
		local painted = false
		-- Collection / equipment: prefer the captured 2D tool cutouts.
		if item and item.slot == "tool" then
			local imgLbl = mk("ImageLabel", {
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(0.84, 0.84),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ZIndex = z + 1,
				ImageColor3 = locked and Color3.fromRGB(28, 28, 34) or Color3.new(1, 1, 1),
				ImageTransparency = locked and 0.15 or 0,
			}, box)
			local nm = (item.def and item.def.name) or item.name
			local last = type(nm) == "string" and string.match(nm, "([^%s]+)$") or nil
			local tryNames = {
				item.def and item.def.modelName,
				item.modelName,
				item.def and item.def.name,
				(item.name ~= "???" and item.name) or nil,
				last,
				item.def and item.def.id,
				item.id,
			}
			for _, n in ipairs(tryNames) do
				if type(n) == "string" and n ~= "" and ToolIcons.apply(imgLbl, n) then
					painted = true
					break
				end
			end
			if not painted then
				imgLbl:Destroy()
			end
		end
		if item and item.slot == "tool" and not locked and not painted then
			painted = paintToolViewport(box, item, z)
		end
		local img = item and item.icon
		if (not painted) and item and not img and item.slot == "tool" and Icons.image then
			img = Icons.image(tostring(item.id or ""))
				or Icons.image(item.family)
				or Icons.image((item.def and (item.def.id or item.def.family)) or "pickaxe")
				or Icons.image("pickaxe")
		end
		if (not painted) and (not img) and item and item.source == "gear" and NG then
			local cid = item.def and item.def.catalogId
			if cid then
				img = NG.icon(cid)
			end
		end
		if (not painted) and img then
			mk("ImageLabel", {
				BackgroundTransparency = 1, Image = img, ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(0.84, 0.84), Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z + 1,
				ImageColor3 = locked and Color3.fromRGB(28, 28, 34) or Color3.new(1, 1, 1),
				ImageTransparency = locked and 0.15 or 0,
			}, box)
			painted = true
		end
		--[[
			Equipment seats want the pet itself, not a scaled-down card
			(banner, F chip, name). The collection still uses paintCard.
		]]
		if (not painted) and item and not img and not locked then
			local card = item.card or (item.source == "pet" and cardNamed(item.id)) or nil
			local petIcon = item.source == "pet" or item.petSeat ~= nil
			if type(card) == "table" and petIcon and opts.petViewport then
				box.ClipsDescendants = true
				local ok = pcall(opts.petViewport, box, card,
					UDim2.fromScale(0.08, 0.08), UDim2.fromScale(0.84, 0.84))
				if ok then
					painted = true
					for _, ch in ipairs(box:GetChildren()) do
						if ch:IsA("ViewportFrame") then
							ch.BackgroundTransparency = 1
						end
					end
				end
			elseif type(card) == "table" and opts.paintCard then
				box.ClipsDescendants = true
				local ok, made = pcall(opts.paintCard, box, card, size)
				if ok then
					painted = true
					if typeof(made) == "Instance" and made:IsA("GuiObject") then
						local cw, ch = made.Size.X.Offset, made.Size.Y.Offset
						if cw > 0 and ch > 0 then
							mk("UIScale", { Scale = math.min(size / cw, size / ch) }, made)
						end
						made.AnchorPoint = Vector2.new(0.5, 0.5)
						made.Position = UDim2.fromScale(0.5, 0.5)
						made.ZIndex = z + 1
					end
				end
			end
		end
		if not painted then
			local glyph = locked and "?" or (item and "" or "+")
			if glyph ~= "" then
				local g = label(box, glyph, math.floor(size * 0.4),
					item and ink or Color3.fromRGB(88, 88, 98),
					UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center)
				g.ZIndex = z + 1
			end
		end

		local letter = (not locked) and item and item.source ~= "pet" and eq.letterOf(item) or nil
		if letter then
			local h = math.max(16, math.floor(size * 0.28))
			if Irid.isMark and Irid.isMark(letter) and Irid.badge then
				-- S / SS / SSS wear the game's iridescent mark.
				Irid.badge(box, letter, { height = h, anchor = Vector2.new(1, 1),
					position = UDim2.new(1, -3, 1, -3), z = z + 3 })
			else
				local chip = mk("Frame", {
					BackgroundColor3 = Color3.fromRGB(16, 18, 24), BackgroundTransparency = 0.05,
					AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -3, 1, -3),
					Size = UDim2.fromOffset(h, h), ZIndex = z + 3,
				}, box)
				round(chip, math.floor(h * 0.3))
				stroke(chip, 1, gradeInk(letter))
				local t = label(chip, letter, math.floor(h * 0.78), gradeInk(letter),
					UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center)
				t.ZIndex = z + 4
			end
		end

		if upgrade then
			local a = math.max(16, math.floor(size * 0.28))
			local chip = mk("Frame", {
				BackgroundColor3 = GREEN, Position = UDim2.fromOffset(3, 3),
				Size = UDim2.fromOffset(a, a), ZIndex = z + 3,
			}, box)
			round(chip, math.floor(a / 2))
			-- U+2B06 renders in FredokaOne; U+23F6 and U+279C do not (tofu).
			local t = label(chip, "⬆", math.floor(a * 0.78), Color3.fromRGB(14, 42, 20),
				UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center)
			t.ZIndex = z + 4
		end
		return box
	end

	--[[
		A ring that fills as you hold. 48 segments, because a swept arc in Roblox
		means either an image nobody has drawn yet or two clipped half-discs
		whose maths goes wrong at exactly 50%; 48 little rotated bars are
		obviously correct and read as a dial from across the room.
	]]
	local function holdRing(parent, size, colour)
		local ring = mk("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(size, size),
			ZIndex = 78,
		}, parent)
		local segs, n = {}, 48
		for i = 1, n do
			local ang = math.rad((i - 1) * 360 / n)
			local r = size / 2 - 5
			local bar = mk("Frame", {
				BackgroundColor3 = colour,
				BackgroundTransparency = 0.82,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, math.sin(ang) * r, 0.5, -math.cos(ang) * r),
				Size = UDim2.fromOffset(4, 9),
				Rotation = math.deg(ang),
				ZIndex = 79,
			}, ring)
			round(bar, 2)
			segs[i] = bar
		end
		local api = {}
		function api.set(p)
			local lit = math.floor(math.clamp(p, 0, 1) * n + 0.0001)
			for i, bar in ipairs(segs) do
				bar.BackgroundTransparency = (i <= lit) and 0 or 0.82
			end
		end
		api.set(0)
		api.frame = ring
		return api
	end

	--[[
		THE ITEM CARD.

		Name across the top, art top-left, what it does to the right of the art,
		what is fitted to it in the middle, and the two things you can do with it
		along the bottom: keep it or let it go.

		SELL does not sell. It turns the footer into the payout and a confirm you
		have to HOLD for three seconds. Everything on this screen is permanent
		and some of it is one-of-a-kind, so the last action is deliberately the
		slowest one on it -- a tap cannot do it and a mis-tap cannot start it.
	]]
	local function showItemCard(item)
		if eq.card then
			eq.card:Destroy()
			eq.card = nil
		end
		local ink = item.rarity and gradeInk(item.rarity) or GOLD
		local card = mk("Frame", {
			Name = "ItemCard",
			BackgroundColor3 = BG,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(560, 470),
			ZIndex = 72,
		}, root)
		eq.card = card
		eq.cardKey, eq.cardMode = item.key, "choice"
		round(card, 14)
		local cs = stroke(card, 2, ink)
		if item.rarity then
			paintGrade(card, item.rarity, cs)
		end
		-- Laid out at one size and scaled to the window, so a phone gets the
		-- same card smaller rather than a card with its bottom cut off.
		local fit = mk("UIScale", {}, card)
		local function refit()
			local room = root.AbsoluteSize
			local sg = root:FindFirstAncestorOfClass("ScreenGui")
			local ui = sg and sg:FindFirstChildOfClass("UIScale")
			local k = (ui and ui.Scale > 0.05) and ui.Scale or 1
			fit.Scale = math.min(1, (room.X / k - 24) / 560, (room.Y / k - 24) / 470)
		end
		refit()
		root:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)

		local titleLbl = label(card, string.upper(tostring(item.name or "")), 20, ink,
			UDim2.fromOffset(20, 14), UDim2.new(1, -40, 0, 28), FONT, Enum.TextXAlignment.Center)
		-- A long name used to clip mid-word. Shrink it to fit instead of cutting it.
		-- Constraint first, TextScaled last -- parenting the constraint clears the flag.
		mk("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = 20 }, titleLbl)
		titleLbl.TextScaled = true
		-- Hats: lead with the effect so the card answers "what does this do?"
		-- before anything else. Faces keep the short team line.
		local subText = tostring(item.sub or "")
		if item.source == "gear" and item.def and not (Gear.isFacePiece and Gear.isFacePiece(item.def))
			and Gear.migrateSlot(item.def.slot) ~= "face" then
			subText = Gear.hatEffectLine and Gear.hatEffectLine(item.def) or subText
		end
		local subLbl = label(card, subText, 13, (item.source == "gear" and item.def and Gear.migrateSlot(item.def.slot) ~= "face") and GOLD or MUTED,
			UDim2.fromOffset(20, 44), UDim2.new(1, -40, 0, 30), nil, Enum.TextXAlignment.Center)
		subLbl.TextWrapped = true
		subLbl.TextYAlignment = Enum.TextYAlignment.Top

		-- Art, upper left: same 3D/rarity thumb as the grid so they cannot drift.
		eq.thumb(card, item, 132, UDim2.fromOffset(22, 76), false)

		-- Stats, to the right of the art.
		local rows = {}
		if item.source == "gear" then
			local g = item.def
			local isFace = Gear.isFacePiece and Gear.isFacePiece(g)
				or Gear.migrateSlot(g.slot) == "face"
			local boostLines = Gear.boostTextLines and Gear.boostTextLines(g) or {}
			rows = {
				{ "Slot", isFace and "Face" or "Hat" },
				{ "Set", tostring(g.setName or g.setId or "-") },
				{ "Grade", tostring(g.rarity or "-") },
			}
			for i, line in ipairs(boostLines) do
				table.insert(rows, { i == 1 and "Boost" or "", line })
			end
			if isFace then
				table.insert(rows, { "Note", "Multiplies matching hat %s" })
			end
			table.insert(rows, { "Sockets", tostring(g.slotCount or 0) })
		elseif item.source == "charm" then
			rows = { { "Type", "Charm" }, { "Effect", tostring(item.def.blurb or item.def.source or "-") } }
		else
			rows = toolStats(item.def)
		end
		local statHost = mk("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(168, 76),
			Size = UDim2.new(1, -190, 0, 132),
			ZIndex = 73,
		}, card)
		for i, r in ipairs(rows) do
			local y = (i - 1) * 22
			if y <= 110 then
				label(statHost, tostring(r[1]), 12, MUTED, UDim2.fromOffset(0, y), UDim2.fromOffset(86, 20))
				label(statHost, tostring(r[2]), 14, TEXT, UDim2.fromOffset(90, y),
					UDim2.new(1, -90, 0, 20), FONT)
			end
		end

		-- What is fitted to it, across the middle.
		local fitted = mk("Frame", {
			BackgroundColor3 = BG2,
			Position = UDim2.fromOffset(22, 216),
			Size = UDim2.new(1, -44, 0, 80),
			ZIndex = 73,
		}, card)
		round(fitted, 10)
		stroke(fitted, 1)
		label(fitted, "RUNES", 10, MUTED, UDim2.fromOffset(14, 6), UDim2.new(1, -28, 0, 12), FONT)
		local fitText
		if item.source == "gear" then
			fitText = runeSummary(item.def.sockets, item.def.slotCount)
		elseif item.runeId then
			local nameOf
			for _, r in ipairs(state.runes or {}) do
				if r.id == item.runeId then
					nameOf = string.format("%s +%.0f%%", tostring(r.stat), (r.pct or 0) * 100)
				end
			end
			fitText = nameOf or "one rune fitted"
		elseif item.source == "charm" then
			fitText = "Charms do not take runes"
		elseif item.source == "ladder" or item.source == "shop" then
			-- Coin tools share one socket per family: whatever rune is in the
			-- pickaxe socket is in every pickaxe rung.
			local sock = (state.toolSockets or {})[item.family or (item.def and item.def.family) or ""]
			local bits = {}
			if type(sock) == "table" then
				for _, key in ipairs({ "main", "omni" }) do
					local rid = sock[key]
					for _, r in ipairs(state.runes or {}) do
						if rid and r.id == rid then
							table.insert(bits, string.format("%s %s +%.0f%%", key == "omni" and "Omni" or "Main",
								tostring(r.stat), (r.pct or 0) * 100))
						end
					end
				end
			end
			fitText = (#bits > 0) and table.concat(bits, "   ")
				or "No rune in this family's socket · fit one at the Enchanter"
		else
			fitText = "No rune fitted · socket it at the Enchanter"
		end
		label(fitted, fitText, 13, GEM, UDim2.fromOffset(14, 19), UDim2.new(1, -28, 0, 18))

		-- Temperament. Only ever there because tokens were spent on it (see
		-- Verbs.rollTemper); a coin rung shares its family's, a found tool has
		-- its own, and nothing else takes one.
		do
			local Temper = require(shared:WaitForChild("MineTemper"))
			local src
			if item.source == "forever" then
				src = item.owned
			elseif item.source == "ladder" or item.source == "shop" then
				src = (state.toolTempers or {})[item.family or (item.def and item.def.family) or ""]
			end
			local temperText, temperInk = "", MUTED
			if item.source == "gear" or item.source == "charm" then
				temperText = "Only tools take a temperament"
			elseif item.source == "fossil" then
				temperText = "Fossil tools do not take a temperament"
			else
				local picks = {}
				if type(src) == "table" then
					if type(src.tempers) == "table" and #src.tempers > 0 then
						for _, t in ipairs(src.tempers) do
							table.insert(picks, t)
						end
					elseif src.temperId then
						table.insert(picks, { id = src.temperId, rarity = src.temperRarity })
					end
				end
				local bits = {}
				for _, t in ipairs(picks) do
					local kit = Temper.kit(t.id or t.temperId)
					if kit then
						local r = Temper.normalizeRarity(t.rarity or t.temperRarity or kit.rarity)
						table.insert(bits, tostring(r) .. " " .. kit.name)
						temperInk = Temper.RARITY_COLOR[r] or GOLD
					end
				end
				temperText = (#bits > 0) and table.concat(bits, "   ")
					or ("Untempered · roll one at the Forge for " .. tostring(state.rollCost or 10) .. " tokens")
			end
			label(fitted, "TEMPERAMENT", 10, MUTED, UDim2.fromOffset(14, 42), UDim2.new(1, -28, 0, 12), FONT)
			label(fitted, temperText, 13, temperInk, UDim2.fromOffset(14, 55), UDim2.new(1, -28, 0, 18))
		end

		-- The footer swaps between "what now" and "are you sure".
		local footer = mk("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(22, 302),
			Size = UDim2.new(1, -44, 0, 148),
			ZIndex = 73,
		}, card)

		local function closeCard()
			if eq.card then
				eq.card:Destroy()
				eq.card = nil
			end
		end

		local function equipIt()
			if item.source == "ladder" then
				if opts.onEquipTool then opts.onEquipTool(item.family, item.tier) end
			elseif item.source == "shop" then
				if opts.onEquipShopTool then opts.onEquipShopTool(item.id) end
			elseif item.source == "forever" then
				if opts.onEquipChestTool then opts.onEquipChestTool(item.id) end
			elseif item.source == "fossil" then
				if opts.onEquipFossilTool then opts.onEquipFossilTool(item.id) end
			elseif item.source == "gear" then
				--[[
					The seat the player is looking at is the seat the hat goes in.
					`item.slot` carries it, so tapping a hat while on seat 2 fills
					seat 2 rather than whichever one happened to be free.

					A hat already in another seat moves: the server clears its old
					seat, because one owned piece is only ever in one place.
				]]
				if item.equipped then
					if opts.onUnequipGear then opts.onUnequipGear(item.slot, item.id) end
				elseif opts.onEquipGear then
					opts.onEquipGear(item.id, item.slot)
				end
			elseif item.source == "charm" then
				if item.equipped then
					if opts.onUnequipCharm then opts.onUnequipCharm() end
				elseif opts.onEquipCharm then
					opts.onEquipCharm(item.id)
				end
			elseif item.source == "pet" then
				if item.equipped then
					if opts.onUnequip then opts.onUnequip(item.id) end
				elseif opts.onEquip then
					opts.onEquip({ id = item.id, slot = item.petSeat })
				end
			elseif item.source == "vipSeat" then
				if opts.onBuyVipPass then opts.onBuyVipPass() end
			end
			local takingOff = item.equipped and (item.source == "gear" or item.source == "charm"
				or item.source == "pet")
			if item.source ~= "vipSeat" and item.source ~= "backpack" and not takingOff then
				eq.advanceSlot()
			end
			closeCard()
		end

		local function sellIt()
			if item.source == "gear" then
				if opts.onScrapGear then opts.onScrapGear(item.id) end
			elseif opts.onSellTool then
				opts.onSellTool({
					source = item.source, family = item.family,
					id = item.id, key = item.id,
				})
			end
			closeCard()
		end

		-- The payout in words, so the confirm screen says what lands.
		local function payoutText()
			local s = item.sell
			if not s then
				return "Nothing"
			end
			local bits = {}
			if s.coins then table.insert(bits, commas(s.coins) .. " coins") end
			if s.dust then table.insert(bits, commas(s.dust) .. " stardust") end
			if s.tokens and s.tokens > 0 then
				table.insert(bits, s.tokens .. " temper token" .. (s.tokens == 1 and "" or "s"))
			end
			if s.gems then table.insert(bits, commas(s.gems) .. " gems") end
			return (#bits > 0) and table.concat(bits, "   +   ") or "Nothing"
		end

		local showChoice, showConfirm

		function showChoice()
			eq.cardMode = "choice"
			clear(footer)
			-- Gear and charms come off; a tool only ever gets swapped for
			-- another, because a player with nothing in hand cannot mine.
			local canTakeOff = item.source == "gear" or item.source == "charm" or item.source == "pet"
			local inert = item.equipped and not canTakeOff
			local eqB = mk("TextButton", {
				AutoButtonColor = not inert, BackgroundColor3 = item.equipped and BG3 or GREEN,
				Text = inert and "EQUIPPED" or (item.equipped and "UNEQUIP" or (item.source == "vipSeat" and "GET VIP" or "EQUIP")),
				Font = FONT, TextSize = 16,
				TextColor3 = inert and GREEN or (item.equipped and TEXT or Color3.fromRGB(16, 38, 20)),
				Position = UDim2.fromOffset(0, 66), Size = UDim2.new(0.48, -6, 0, 46),
				ZIndex = 74,
			}, footer)
			round(eqB, 10)
			if not inert then
				eqB.MouseButton1Click:Connect(equipIt)
			end

			local canSell = item.sell ~= nil and not item.why
			local sellB = mk("TextButton", {
				AutoButtonColor = canSell,
				BackgroundColor3 = canSell and Color3.fromRGB(150, 58, 58) or BG3,
				Text = canSell and "SELL" or "CAN'T SELL", Font = FONT, TextSize = 16,
				TextColor3 = canSell and Color3.fromRGB(255, 226, 226) or MUTED,
				Position = UDim2.new(0.52, 6, 0, 66), Size = UDim2.new(0.48, -6, 0, 46),
				ZIndex = 74,
			}, footer)
			round(sellB, 10)
			if canSell then
				label(footer, "Sells for " .. payoutText(), 13, GOLD,
					UDim2.fromOffset(0, 40), UDim2.new(1, 0, 0, 20), nil, Enum.TextXAlignment.Center)
				sellB.MouseButton1Click:Connect(showConfirm)
			else
				label(footer, tostring(item.why or "This one stays in the bag"), 13, MUTED,
					UDim2.fromOffset(0, 40), UDim2.new(1, 0, 0, 20), nil, Enum.TextXAlignment.Center)
			end

			local closeB = mk("TextButton", {
				AutoButtonColor = true, BackgroundColor3 = BG2, Text = "CLOSE",
				Font = FONT, TextSize = 14, TextColor3 = TEXT,
				Position = UDim2.fromOffset(0, 118), Size = UDim2.new(1, 0, 0, 30),
				ZIndex = 74,
			}, footer)
			round(closeB, 8)
			closeB.MouseButton1Click:Connect(closeCard)
		end

		function showConfirm()
			eq.cardMode = "confirm"
			clear(footer)
			local foreverPay = item.sell and item.sell.dust and item.sell.tokens
				and (item.source == "forever" or item.source == "fossil")
			if foreverPay then
				label(footer, "PICK ONE — FULL VALUE", 11, MUTED, UDim2.fromOffset(0, 0),
					UDim2.new(1, 0, 0, 14), FONT, Enum.TextXAlignment.Center)
				label(footer, "This cannot be undone.", 12, Color3.fromRGB(255, 150, 150),
					UDim2.fromOffset(0, 18), UDim2.new(1, 0, 0, 16), nil, Enum.TextXAlignment.Center)
				local back = mk("TextButton", {
					AutoButtonColor = true, BackgroundColor3 = BG2, Text = "CANCEL",
					Font = FONT, TextSize = 14, TextColor3 = TEXT,
					Position = UDim2.fromOffset(0, 118), Size = UDim2.new(1, 0, 0, 30),
					ZIndex = 74,
				}, footer)
				round(back, 8)
				back.MouseButton1Click:Connect(showChoice)
				local function sellAs(pay)
					if opts.onSellTool then
						opts.onSellTool({
							source = item.source, family = item.family,
							id = item.id, key = item.id, pay = pay,
						})
					end
					closeCard()
				end
				local dustB = mk("TextButton", {
					AutoButtonColor = true, BackgroundColor3 = Color3.fromRGB(120, 72, 180),
					Text = commas(item.sell.dust) .. " STARDUST", Font = FONT, TextSize = 15,
					TextColor3 = Color3.fromRGB(250, 240, 255),
					Position = UDim2.fromOffset(0, 42), Size = UDim2.new(0.48, -6, 0, 68),
					ZIndex = 74,
				}, footer)
				round(dustB, 10)
				dustB.MouseButton1Click:Connect(function() sellAs("dust") end)
				local tokB = mk("TextButton", {
					AutoButtonColor = true, BackgroundColor3 = Color3.fromRGB(150, 58, 58),
					Text = commas(item.sell.tokens) .. " TOKENS", Font = FONT, TextSize = 15,
					TextColor3 = Color3.fromRGB(255, 226, 226),
					Position = UDim2.new(0.52, 6, 0, 42), Size = UDim2.new(0.48, -6, 0, 68),
					ZIndex = 74,
				}, footer)
				round(tokB, 10)
				tokB.MouseButton1Click:Connect(function() sellAs("tokens") end)
				return
			end
			label(footer, "YOU WILL RECEIVE", 11, MUTED, UDim2.fromOffset(0, 0),
				UDim2.new(1, 0, 0, 14), FONT, Enum.TextXAlignment.Center)
			label(footer, payoutText(), 18, GOLD, UDim2.fromOffset(0, 16),
				UDim2.new(1, 0, 0, 24), FONT, Enum.TextXAlignment.Center)
			label(footer, "This cannot be undone.", 12, Color3.fromRGB(255, 150, 150),
				UDim2.fromOffset(0, 42), UDim2.new(1, 0, 0, 16), nil, Enum.TextXAlignment.Center)

			local back = mk("TextButton", {
				AutoButtonColor = true, BackgroundColor3 = BG2, Text = "CANCEL",
				Font = FONT, TextSize = 15, TextColor3 = TEXT,
				Position = UDim2.fromOffset(0, 66), Size = UDim2.new(0.46, -6, 0, 76),
				ZIndex = 74,
			}, footer)
			round(back, 10)
			back.MouseButton1Click:Connect(showChoice)

			local hold = mk("TextButton", {
				AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(120, 42, 42),
				Text = "", Position = UDim2.new(0.54, 6, 0, 66),
				Size = UDim2.new(0.46, -6, 0, 76), ZIndex = 74,
			}, footer)
			round(hold, 10)
			stroke(hold, 1, Color3.fromRGB(255, 120, 120))
			-- The button says what it DOES. It used to say HOLD, and HOLD sitting
			-- next to CANCEL reads as "hold on to it" -- the exact opposite of
			-- pressing it. The action is the big word; how to do it is the small
			-- print under it.
			local ring = holdRing(hold, 58, Color3.fromRGB(255, 190, 190))
			ring.frame.Position = UDim2.new(0, 42, 0.5, 0)
			local capt = label(hold, "SELL", 22, Color3.fromRGB(255, 236, 236),
				UDim2.fromOffset(80, 12), UDim2.new(1, -88, 0, 28), FONT)
			capt.ZIndex = 80
			local hint = label(hold, "press and hold 3s", 11, Color3.fromRGB(255, 190, 190),
				UDim2.fromOffset(80, 42), UDim2.new(1, -88, 0, 16))
			hint.ZIndex = 80

			-- Three seconds, and it has to be three seconds of YOUR finger. Let
			-- go and it goes back to zero rather than pausing, so a slip never
			-- gets banked toward the sale.
			local HOLD = 3
			local RunService = game:GetService("RunService")
			local UIS = game:GetService("UserInputService")
			local held, conn, holdInput = nil, nil, nil
			local function stop()
				held, holdInput = nil, nil
				if conn then
					conn:Disconnect()
					conn = nil
				end
				ring.set(0)
				capt.Text = "SELL"
				hint.Text = "press and hold 3s"
			end
			-- MouseButton1Up is not guaranteed: Roblox drops it when the GUI under
			-- the pointer changes mid-press, and a missed release here would let
			-- the timer run out on its own. So every frame asks the press itself
			-- whether it is still down, and a finger that has lifted stops the
			-- clock whatever events did or did not arrive.
			local function stillDown()
				if not holdInput then
					return false
				end
				local st = holdInput.UserInputState
				if st == Enum.UserInputState.End or st == Enum.UserInputState.Cancel then
					return false
				end
				if holdInput.UserInputType == Enum.UserInputType.MouseButton1 then
					return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
				end
				return true
			end
			hold.InputBegan:Connect(function(input)
				local kind = input.UserInputType
				if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
					return
				end
				if conn then return end
				holdInput = input
				held = os.clock()
				conn = RunService.RenderStepped:Connect(function()
					if not held or not hold.Parent or not stillDown() then
						stop()
						return
					end
					local p = (os.clock() - held) / HOLD
					ring.set(p)
					capt.Text = (p >= 1) and "SOLD" or "SELL"
					hint.Text = (p >= 1) and "" or string.format("keep holding  %.1fs", HOLD * (1 - math.min(p, 1)))
					if p >= 1 then
						stop()
						sellIt()
					end
				end)
			end)
			hold.MouseButton1Up:Connect(stop)
			hold.MouseLeave:Connect(stop)
		end

		showChoice()
	end

	--[[
		You, in a viewport, holding what you are actually holding.

		This is a clone of the live character, so the tool in its hand is the
		real Tool instance the server handed you -- equip a different pickaxe and
		the next snapshot rebuilds this and the model in the preview changes with
		it. Gear has icons but no world models yet, so armour shows on the slot
		tiles rather than being invented on the body here; the day gear gets
		models they will already be on this clone for free.
	]]
	local function characterView(parent)
		local vp = mk("ViewportFrame", {
			BackgroundColor3 = BG3,
			BackgroundTransparency = 0.25,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 12,
		}, parent)
		round(vp, 12)
		local char = LocalPlayer and LocalPlayer.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then
			label(vp, "your character", 13, MUTED, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1),
				nil, Enum.TextXAlignment.Center)
			return vp
		end
		--[[
			Cloning a whole avatar is the heaviest thing on this screen, and a
			snapshot lands every few seconds while you mine. The clone is kept
			between renders (see the render wrapper below, which lifts it out
			before the body is cleared) and only rebuilt when the character or
			the tool in its hands is a different instance.
		]]
		local held = char:FindFirstChildOfClass("Tool")
		local clone = eq.clone
		if not (clone and eq.cloneOf == char and eq.cloneHeld == held) then
			if clone then
				clone:Destroy()
			end
			eq.clone, eq.cloneOf, eq.cloneHeld = nil, nil, nil
			local wasArchivable = char.Archivable
			char.Archivable = true
			local ok, made = pcall(function()
				return char:Clone()
			end)
			char.Archivable = wasArchivable
			if not ok or not made then
				label(vp, "your character", 13, MUTED, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1),
					nil, Enum.TextXAlignment.Center)
				return vp
			end
			-- A viewport runs nothing, but a cloned character still carries
			-- scripts, sounds and emitters that have no business being here.
			for _, d in ipairs(made:GetDescendants()) do
				if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ParticleEmitter")
					or d:IsA("BillboardGui") or d:IsA("SurfaceGui") or d:IsA("Fire") or d:IsA("Smoke") then
					d:Destroy()
				end
			end
			local hum = made:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			end
			clone = made
			eq.clone, eq.cloneOf, eq.cloneHeld = made, char, held
		end
		clone.Parent = vp

		local cam = Instance.new("Camera")
		cam.Parent = vp
		vp.CurrentCamera = cam
		-- Frame the BODY, not the bounding box: a long pickaxe handle doubles
		-- the box and shrank you to a figure in the middle of an empty frame.
		-- The tool is allowed to reach out of shot; that reads as "holding it".
		local lo, hi
		for _, part in ipairs(clone:GetDescendants()) do
			if part:IsA("BasePart") and part.Transparency < 1 and not part:FindFirstAncestorOfClass("Tool") then
				local half = part.Size / 2
				local p = part.Position
				lo = lo and lo:Min(p - half) or (p - half)
				hi = hi and hi:Max(p + half) or (p + half)
			end
		end
		local cf = clone:GetBoundingBox()
		local centre = (lo and hi) and (lo + hi) / 2 or cf.Position
		local height = (lo and hi) and (hi.Y - lo.Y) or 5.5
		local rootPart = clone:FindFirstChild("HumanoidRootPart")
		local face = (rootPart and rootPart.CFrame) or cf
		cam.FieldOfView = 40
		local dist = math.max(4, height * 1.75)
		local lift = Vector3.new(0, height * 0.06, 0)
		cam.CFrame = CFrame.lookAt(centre + face.LookVector * dist + lift, centre)
		-- A slow sway, so the back of the kit shows without dragging anything.
		local t0 = os.clock()
		local conn
		conn = game:GetService("RunService").RenderStepped:Connect(function()
			if not vp.Parent then
				conn:Disconnect()
				return
			end
			local ang = math.sin((os.clock() - t0) * 0.5) * 0.55
			local dir = (face.LookVector * math.cos(ang)) + (face.RightVector * math.sin(ang))
			cam.CFrame = CFrame.lookAt(centre + dir * dist + lift, centre)
		end)
		return vp
	end

	--[[
		INVENTORY -> EQUIPMENT.

		Tapping a slot does not equip anything; it decides what the list below is
		about. Tapping something in the list opens its card, and the card is
		where equipping and selling live, because both of those want the stats in
		front of you when you commit.
	]]
	local function renderOwnedTools()
		local narrow
		do
			local sg = root:FindFirstAncestorOfClass("ScreenGui")
			local ui = sg and sg:FindFirstChildOfClass("UIScale")
			local k = (ui and ui.Scale > 0.05) and ui.Scale or 1
			narrow = (body.AbsoluteSize.X / k) < 640
		end

		local head = panelRow(body, 46, 1)
		label(head, "EQUIPMENT", 15, TEXT, UDim2.fromOffset(14, 0), UDim2.new(0.28, 0, 1, 0), FONT)
		-- Quicksell: pick bag pieces, then hold SELL 3s to scrap them all.
		local nSel = 0
		for _ in pairs(eq.sellSelect or {}) do
			nSel += 1
		end
		do
			local modeB = mk("TextButton", {
				AutoButtonColor = true,
				BackgroundColor3 = eq.sellMode and Color3.fromRGB(150, 58, 58) or BG3,
				Text = eq.sellMode and ("SELL MODE  " .. nSel) or "QUICKSELL",
				Font = FONT, TextSize = 12,
				TextColor3 = eq.sellMode and Color3.fromRGB(255, 226, 226) or TEXT,
				Size = UDim2.fromOffset(118, 28), Position = UDim2.new(1, -270, 0.5, -14),
			}, head)
			round(modeB, 8)
			modeB.MouseButton1Click:Connect(function()
				eq.sellMode = not eq.sellMode
				if not eq.sellMode then
					eq.sellSelect = {}
				end
				render()
			end)
			local sellB = mk("TextButton", {
				AutoButtonColor = false,
				BackgroundColor3 = (eq.sellMode and nSel > 0) and Color3.fromRGB(150, 58, 58) or BG3,
				Text = (eq.sellMode and nSel > 0) and "HOLD SELL" or "SELL",
				Font = FONT, TextSize = 12,
				TextColor3 = (eq.sellMode and nSel > 0) and Color3.fromRGB(255, 226, 226) or MUTED,
				Size = UDim2.fromOffset(96, 28), Position = UDim2.new(1, -146, 0.5, -14),
			}, head)
			round(sellB, 8)
			local holdBar = mk("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 190, 90), BorderSizePixel = 0,
				Size = UDim2.new(0, 0, 0, 3), Position = UDim2.new(0, 4, 1, -5), ZIndex = 5,
			}, sellB)
			local holding, holdToken = false, 0
			local function stopHold()
				holding = false
				holdToken += 1
				holdBar.Size = UDim2.new(0, 0, 0, 3)
				sellB.Text = (eq.sellMode and nSel > 0) and "HOLD SELL" or "SELL"
			end
			local function startHold()
				if not eq.sellMode or nSel <= 0 then
					return
				end
				holding = true
				holdToken += 1
				local my = holdToken
				local t0 = os.clock()
				task.spawn(function()
					while holding and my == holdToken do
						local u = math.clamp((os.clock() - t0) / 3, 0, 1)
						holdBar.Size = UDim2.new(u, -8, 0, 3)
						sellB.Text = string.format("HOLD %.1fs", 3 - u * 3)
						if u >= 1 then
							local ids = {}
							for id in pairs(eq.sellSelect) do
								table.insert(ids, id)
							end
							eq.sellSelect = {}
							eq.sellMode = false
							stopHold()
							if opts.onScrapMany then
								opts.onScrapMany("gear", ids)
							elseif opts.onScrapGear then
								for _, id in ipairs(ids) do
									opts.onScrapGear(id)
								end
							end
							render()
							return
						end
						task.wait(0.05)
					end
				end)
			end
			sellB.MouseButton1Down:Connect(startHold)
			sellB.MouseButton1Up:Connect(stopHold)
			sellB.MouseLeave:Connect(stopHold)
		end
		do
			local better = tonumber((state.upgrades or {}).gear) or 0
			if better > 0 and not eq.sellMode then
				local b = mk("TextButton", {
					AutoButtonColor = true, BackgroundColor3 = GREEN, Text = "EQUIP BEST",
					Font = FONT, TextSize = 13, TextColor3 = Color3.fromRGB(16, 38, 20),
					Size = UDim2.fromOffset(110, 28), Position = UDim2.fromOffset(120, 9),
				}, head)
				round(b, 8)
				b.MouseButton1Click:Connect(function()
					if opts.onEquipBest then opts.onEquipBest() end
				end)
			elseif not eq.sellMode then
				label(head, "tap a seat, then tap what goes in it", 11, MUTED,
					UDim2.fromOffset(120, 0), UDim2.new(0.4, 0, 1, 0))
			elseif nSel > 0 then
				label(head, "hold SELL 3s to scrap selected", 11, GOLD,
					UDim2.fromOffset(120, 0), UDim2.new(0.35, 0, 1, 0))
			else
				label(head, "tap unequipped gear to select", 11, MUTED,
					UDim2.fromOffset(120, 0), UDim2.new(0.35, 0, 1, 0))
			end
		end

		-- The paperdoll: three hat seats + face L, you, charm/tool/pack R. (It was
		-- four pet-hat seats on the right, the fourth VIP-gated; pets wear no
		-- hats now and there is no fourth pet.)
		-- cellH is the mobile grid's cell, and it has to match slotTile's own
		-- height (100) or UIGridLayout clips the tile it is drawing: the grid
		-- sizes the child, tileH does not. It was 62 against an 84 tile and is
		-- now matched outright, so both layouts agree on one row height.
		local viewH, cellH, gap = 72, 100, 4
		local nL, nR = 0, 0
		for _, s in ipairs(EQUIP_SLOTS()) do
			if s.side == "R" then
				nR += 1
			else
				nL += 1
			end
		end
		local gridRows = math.ceil((nL + nR) / 2)
		local gridH = gridRows * cellH + math.max(0, gridRows - 1) * gap
		local dollH = narrow and (8 + viewH + 6 + gridH + 8) or math.max(32 + nL * 108, 32 + nR * 108)
		local doll = mk("Frame", {
			BackgroundColor3 = BG2, Size = UDim2.new(1, -6, 0, dollH), LayoutOrder = 2,
		}, body)
		round(doll, 12)
		stroke(doll, 1)

		local colW = narrow and 0 or 168
		local function slotTile(slot, x, y, w, parent, order)
			local worn = equippedIn(slot.id)
			local chosen = (eq.slot == slot.id)
			local seatLabel = slot.label
			local tileH = 100
			local tile = mk("TextButton", {
				-- Named so the tutorial hand can point at this seat.
				Name = "Seat_" .. tostring(slot.id),
				BackgroundColor3 = chosen and BG3 or BG,
				AutoButtonColor = true, Text = "",
				Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, tileH),
				LayoutOrder = order or 0,
				ZIndex = 13,
			}, parent or doll)
			round(tile, 10)
			stroke(tile, chosen and 2 or 1, chosen and GOLD
				or (worn and worn.rarity and gradeInk(worn.rarity)) or nil)
			--[[
				ONE ICON SIZE, CENTRED, AND NOTHING TRUNCATED.

				Three things were wrong here and they compounded:

				  * the icon was pinned at y=8 in an 84-tall tile, so anything
				    shorter than the row sat in a pocket of empty space;
				  * the name got a single 20px line with no wrapping, so
				    "SS Redcap of the Vault" became "SS Red...";
				  * and the buff line did `gsub("\n", " . ")`, which took the
				    item's buffs and the pet's buffs and MASHED them onto one
				    row -- which then truncated too. That is the "words morph
				    together" you were looking at.

				Now: one icon size per side, vertically centred; the name wraps
				to two lines instead of clipping; and every buff gets its OWN
				row, so a pet buff and a hat buff can never share a line.
			]]
			local iconPx = narrow and 36 or 60
			eq.thumb(tile, worn, iconPx, UDim2.fromOffset(8, math.floor((tileH - iconPx) / 2)), false)
			-- Hat seats read in gem ink so the three of them group visually
			-- against the single face / charm / tool / backpack seats.
			label(tile, string.upper(seatLabel), 11, chosen and GOLD or (slot.hat and GEM or MUTED),
				UDim2.fromOffset(76, 7), UDim2.new(1, -84, 0, 13), FONT)
			local nameLbl = label(tile, (worn and tostring(worn.name)) or "empty", 13,
				worn and ((worn.rarity and gradeInk(worn.rarity)) or TEXT) or Color3.fromRGB(96, 96, 108),
				UDim2.fromOffset(76, 21), UDim2.new(1, -84, 0, 30), FONT)
			nameLbl.TextWrapped = true
			mk("UITextSizeConstraint", { MinTextSize = 11, MaxTextSize = 13 }, nameLbl)
			nameLbl.TextScaled = true
			nameLbl.TextYAlignment = Enum.TextYAlignment.Top
			-- Buffs, one per row. The item's own lines first, the pet's under
			-- them; newlines are kept rather than flattened.
			local buffs = {}
			if worn and worn.sub then
				for piece in tostring(worn.sub):gmatch("[^\n]+") do
					piece = piece:match("^%s*(.-)%s*$")
					if piece ~= "" then
						buffs[#buffs + 1] = piece
					end
				end
			end
			-- Buffs used to carry a "Pet: <name>" line here, because the seat
			-- belonged to a pet. A hat seat is yours; what is in it is the
			-- whole story.
			for k = 1, math.min(2, #buffs) do
				local bl = label(tile, buffs[k], 11, MUTED,
					UDim2.fromOffset(76, 53 + (k - 1) * 15), UDim2.new(1, -84, 0, 14))
				bl.TextTruncate = Enum.TextTruncate.AtEnd
			end
			tile.MouseButton1Click:Connect(function()
				eq.slot = slot.id
				render()
			end)
			return tile, tileH
		end

		local vpHost
		if narrow then
			vpHost = mk("Frame", { BackgroundTransparency = 1,
				Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, viewH), ZIndex = 12 }, doll)
			local grid = mk("Frame", { BackgroundTransparency = 1,
				Position = UDim2.fromOffset(8, 8 + viewH + 6), Size = UDim2.new(1, -16, 0, gridH), ZIndex = 13 }, doll)
			mk("UIGridLayout", { CellPadding = UDim2.fromOffset(gap, gap),
				CellSize = UDim2.new(0.5, -gap, 0, cellH), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
			local l, r = 0, 0
			for _, slot in ipairs(EQUIP_SLOTS()) do
				-- Interleave L,R,L,R so the grid reads as the two columns.
				local order
				if slot.side == "L" then
					l += 1
					order = l * 2 - 1
				else
					r += 1
					order = r * 2
				end
				slotTile(slot, 0, 0, 0, grid, order)
			end
		else
			local ly = 14
			local ry = 14
			for _, slot in ipairs(EQUIP_SLOTS()) do
				if slot.side == "L" then
					local _, th = slotTile(slot, 14, ly, colW)
					ly += (th or 84) + 8
				end
			end
			for _, slot in ipairs(EQUIP_SLOTS()) do
				if slot.side == "R" then
					local t, th = slotTile(slot, 0, ry, colW)
					t.AnchorPoint = Vector2.new(1, 0)
					t.Position = UDim2.new(1, -14, 0, ry)
					ry += (th or 84) + 8
				end
			end
			vpHost = mk("Frame", { BackgroundTransparency = 1,
				Position = UDim2.fromOffset(colW + 28, 14),
				Size = UDim2.new(1, -(colW + ((nR > 0) and colW or 0) + 42), 1, -28), ZIndex = 12 }, doll)
		end
		characterView(vpHost)

		--[[
			THE STACKING ORDER, in the player's own numbers.

			Hats ADD a static +% on their set stat. Your Hat applies to every pet.
			Face multiplies matching hat %s, then that adds to each pet's base.
		]]
		do
			local byId = {}
			for _, g in ipairs(state.gear or {}) do
				if g.id then
					byId[g.id] = g
				end
			end
			local eqg = state.equippedGear or {}
			local mine = byId[eqg.hat or ""]
			local face = byId[eqg.face or ""]
			local myPct = math.floor(((mine and mine.pct) or 0) * 100 + 0.5)
			local facePct = math.floor(((face and face.pct) or 0) * 100 + 0.5)
			local myStat = mine and eq.statLabel(mine.stat) or nil
			-- How many of your three hat seats are filled, and how many pets they
			-- are multiplying. Every hat applies to every pet, so these are two
			-- independent counts rather than a pairing.
			local hats, seats = 0, #(state.equipped or {})
			for _, s in ipairs(Gear.HAT_SLOTS or { "hat" }) do
				if byId[eqg[s] or ""] then
					hats += 1
				end
			end
			local row = panelRow(body, 58, 2.5)
			label(row, "HOW IT STACKS", 11, GOLD, UDim2.fromOffset(14, 6),
				UDim2.new(1, -28, 0, 14), FONT)
			local line = "pets + hats  ·  Face scales hat %s only"
			if myPct > 0 and myStat then
				line = line .. string.format("  ·  Your Hat +%d%% %s", myPct, myStat)
			end
			if facePct > 0 then
				line = line .. string.format("  ·  Face +%d%%", facePct)
			end
			label(row, line, 12, TEXT, UDim2.fromOffset(14, 22), UDim2.new(1, -28, 0, 16))
			label(row, (hats .. " of " .. #(Gear.HAT_SLOTS or { "hat" }) .. " hat seats filled"
				.. ", on " .. math.max(0, seats) .. (seats == 1 and " pet" or " pets"))
				.. "   ·   e.g. pet +100% + hat +20% × Face +200% → +160%"
				.. (face and "" or "   ·   no face yet"),
				11, MUTED, UDim2.fromOffset(14, 38), UDim2.new(1, -28, 0, 14))
		end

		-- What fits the chosen slot.
		local slotDef
		for _, s in ipairs(EQUIP_SLOTS()) do
			if s.id == eq.slot then slotDef = s end
		end
		local items = equipItems(eq.slot)
		local wornHere = equippedIn(eq.slot)
		do
			sectionHeader((slotDef and slotDef.label or "Slot") .. "  ·  " .. #items .. " owned", 3)
		end
		if #items == 0 then
			note(body, "Nothing for this seat yet — the + below goes shopping.", 4)
		else
			local grid = mk("Frame", { BackgroundTransparency = 1,
				Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 4 }, body)
			mk("UIGridLayout", { CellPadding = UDim2.fromOffset(8, 8),
				CellSize = UDim2.fromOffset(204, 96), SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Left }, grid)
			local shown = 0
			for i, item in ipairs(items) do
				if matches(tostring(item.name) .. " " .. tostring(item.sub or "")) then
					shown += 1
					local ink = (item.rarity and gradeInk(item.rarity)) or TEXT
					local tile = mk("TextButton", { BackgroundColor3 = BG2, Text = "",
						AutoButtonColor = true, LayoutOrder = i }, grid)
					round(tile, 10)
					stroke(tile, item.equipped and 2 or 1, item.equipped and GREEN or ink)
					-- Same rhythm as the seat tiles: icon centred against the row,
					-- a name that WRAPS instead of clipping at ~10 characters,
					-- and one buff per line -- `sub` carries newlines and they
					-- must not be crushed onto a single row.
					eq.thumb(tile, item, 72, UDim2.fromOffset(12, 12), eq.isUpgrade(item, wornHere))
					local nameLbl = label(tile, tostring(item.name), 13, ink,
						UDim2.fromOffset(94, 10), UDim2.new(1, -104, 0, 28), FONT)
					nameLbl.TextWrapped = true
					mk("UITextSizeConstraint", { MinTextSize = 10, MaxTextSize = 13 }, nameLbl)
					nameLbl.TextScaled = true
					nameLbl.TextYAlignment = Enum.TextYAlignment.Top
					local rows = {}
					for piece in tostring(item.sub or ""):gmatch("[^\n]+") do
						piece = piece:match("^%s*(.-)%s*$")
						if piece ~= "" then
							rows[#rows + 1] = piece
						end
					end
					for k = 1, math.min(2, #rows) do
						local rl = label(tile, rows[k], 11, MUTED,
							UDim2.fromOffset(94, 40 + (k - 1) * 15), UDim2.new(1, -104, 0, 14))
						rl.TextTruncate = Enum.TextTruncate.AtEnd
					end
					local foot = item.sell and (item.sell.coins and (commas(item.sell.coins) .. " coins")
						or item.sell.dust and (commas(item.sell.dust) .. " stardust")
						or item.sell.gems and (commas(item.sell.gems) .. " gems")) or ""
					label(tile, item.equipped and "EQUIPPED" or foot, 11,
						item.equipped and GREEN or GOLD, UDim2.fromOffset(94, 66),
						UDim2.new(1, -104, 0, 16), FONT)
					tile.MouseButton1Click:Connect(function()
						showItemCard(item)
					end)
				end
			end
			if shown == 0 then
				note(body, "Nothing here matches that search.", 5)
			end
		end

		--[[
			The last tile is a plus and nothing else. "I need another one of
			these" is the thought you have while looking at the ones you own, so
			the door to the Enchanter is standing right there at the end of the
			row: it walks you to the machine and opens the summon banner.
		]]
		if eq.slot ~= "tool" and eq.slot ~= "charm" then
			local moreGrid = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 6 }, body)
			mk("UIGridLayout", { CellPadding = UDim2.fromOffset(8, 8),
				CellSize = UDim2.fromOffset(204, 96), SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Left }, moreGrid)
			local plus = mk("TextButton", { Name = "GoEnchanter", BackgroundColor3 = BG2, Text = "", AutoButtonColor = true }, moreGrid)
			round(plus, 10)
			stroke(plus, 1, GEM)
			label(plus, "+", 44, GEM, UDim2.fromOffset(12, 8), UDim2.fromOffset(72, 76), FONT, Enum.TextXAlignment.Center)
			label(plus, "MORE HATS & RUNES", 13, TEXT, UDim2.fromOffset(94, 24), UDim2.new(1, -104, 0, 18), FONT)
			label(plus, "takes you to the Enchanter", 11, MUTED, UDim2.fromOffset(94, 46), UDim2.new(1, -104, 0, 16))
			plus.MouseButton1Click:Connect(function()
				if opts.onGoEnchanter then opts.onGoEnchanter() end
			end)
		end

		-- Charms are bought here now that they have no tab of their own.
		if eq.slot == "charm" then
			local Charms = require(shared:WaitForChild("MineCharms"))
			local packRow = panelRow(body, 56, 6)
			label(packRow, "Charms Pack", 14, TEXT, UDim2.fromOffset(14, 8), UDim2.new(0.6, 0, 0, 20), FONT)
			label(packRow, (Charms.PACK_PRICE_GEMS or 2500) .. " gems · random pack charm",
				12, MUTED, UDim2.fromOffset(14, 30), UDim2.new(0.6, 0, 0, 18))
			local pbtn = mk("TextButton", {
				Text = "BUY PACK", Font = FONT, TextSize = 13,
				TextColor3 = Color3.fromRGB(20, 28, 40), BackgroundColor3 = GEM,
				Size = UDim2.fromOffset(110, 36), Position = UDim2.new(1, -124, 0.5, -18),
				AutoButtonColor = true,
			}, packRow)
			round(pbtn, 8)
			pbtn.MouseButton1Click:Connect(function()
				if opts.onBuyCharmsPack then opts.onBuyCharmsPack() end
			end)

			-- Lucky Charm: 1:1 credits/Robux face; credits preferred (bulk pack deal).
			local luckyOwned = (state.charms or {}).lucky_charm == true
			local saleOpen = (not C.limitedSaleOpen) or C.limitedSaleOpen()
			local prod = C.product and C.product("lucky_charm")
			local face = (prod and (tonumber(prod.creditsPrice) or tonumber(prod.robuxPrice))) or 199
			local luckRow = panelRow(body, 56, 7)
			label(luckRow, "Lucky Charm", 14, GOLD, UDim2.fromOffset(14, 8), UDim2.new(0.45, 0, 0, 20), FONT)
			label(luckRow, luckyOwned and "Owned — equip it above"
				or (saleOpen and (face .. " credits = R$ " .. face) or "Goes on sale at launch 00:00"),
				12, MUTED, UDim2.fromOffset(14, 30), UDim2.new(0.45, 0, 0, 18))
			local lbtn = mk("TextButton", {
				Text = luckyOwned and "OWNED" or (saleOpen and (face .. " CR") or "SOON"),
				Font = FONT, TextSize = 13, TextColor3 = Color3.fromRGB(20, 28, 40),
				BackgroundColor3 = luckyOwned and Color3.fromRGB(90, 100, 120) or (saleOpen and (T.CREDIT or GOLD) or MUTED),
				Size = UDim2.fromOffset(100, 36), Position = UDim2.new(1, -114, 0.5, -18),
				AutoButtonColor = (not luckyOwned) and saleOpen,
			}, luckRow)
			round(lbtn, 8)
			if (not luckyOwned) and saleOpen then
				lbtn.MouseButton1Click:Connect(function()
					if opts.onBuyProductCredits then
						opts.onBuyProductCredits("lucky_charm")
					elseif opts.onBuyLuckyCharm then
						opts.onBuyLuckyCharm()
					end
				end)
			end
		end

		--[[
			The backpack: everything else you own. Name over the picture and the
			grade in the picture's corner -- the picture already says what the
			thing is for, so the slot is not written out. Anything that would
			beat what you are wearing gets the green arrow and moves to the
			front, so the upgrades are the first thing you see.
		]]
		sectionHeader("Backpack", 8)
		local bag = {}
		-- Unequipped overflow from every slot (including the selected one).
		-- Skipping eq.slot hid spare tools whenever Tool was selected, which
		-- made BACKPACK look empty while duplicates still showed EQUIPPED.
		for si, slot in ipairs(EQUIP_SLOTS()) do
			local worn = equippedIn(slot.id)
			for _, item in ipairs(equipItems(slot.id)) do
				if not item.equipped and not item.lowerRung and matches(tostring(item.name)) then
					table.insert(bag, { item = item, up = eq.isUpgrade(item, worn), si = si, n = #bag + 1 })
				end
			end
		end
		table.sort(bag, function(x, y)
			if x.up ~= y.up then
				return x.up
			end
			if x.si ~= y.si then
				return x.si < y.si
			end
			return x.n < y.n
		end)
		if #bag == 0 then
			note(body, "Backpack empty — unequipped gear and spare tools show up here.", 9)
		else
			local bagRow = mk("Frame", { BackgroundTransparency = 1,
				Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 9 }, body)
			mk("UIGridLayout", { CellPadding = UDim2.fromOffset(8, 8),
				CellSize = UDim2.fromOffset(108, 140), SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Left }, bagRow)
			for order, entry in ipairs(bag) do
				local item = entry.item
				local ink = (item.rarity and gradeInk(item.rarity)) or TEXT
				local canSell = eq.sellMode and item.source == "gear" and item.id
					and not item.equipped and not item.why
				local picked = canSell and eq.sellSelect[item.id] or false
				local tile = mk("TextButton", {
					BackgroundColor3 = picked and Color3.fromRGB(72, 36, 36) or BG2, Text = "",
					AutoButtonColor = true, LayoutOrder = order,
				}, bagRow)
				round(tile, 8)
				stroke(tile, picked and 2 or 1, picked and Color3.fromRGB(255, 120, 100) or ink)
				local nameLbl = label(tile, tostring(item.name), 12, ink, UDim2.fromOffset(6, 4),
					UDim2.new(1, -12, 0, 28), FONT, Enum.TextXAlignment.Center)
				nameLbl.TextWrapped = true
				mk("UITextSizeConstraint", { MinTextSize = 9, MaxTextSize = 12 }, nameLbl)
				nameLbl.TextScaled = true
				nameLbl.TextYAlignment = Enum.TextYAlignment.Top
				eq.thumb(tile, item, 88, UDim2.new(0.5, -44, 0, 36), entry.up)
				if picked then
					label(tile, "✓", 18, Color3.fromRGB(255, 200, 160),
						UDim2.new(1, -28, 0, 4), UDim2.fromOffset(22, 22), FONT)
				end
				tile.MouseButton1Click:Connect(function()
					if eq.sellMode then
						if not canSell then
							return
						end
						if eq.sellSelect[item.id] then
							eq.sellSelect[item.id] = nil
						else
							eq.sellSelect[item.id] = true
						end
						render()
						return
					end
					showItemCard(item)
				end)
			end
		end

		-- A card left open across a snapshot would describe the old state (it
		-- said EQUIPPED on a pickaxe you had just swapped out). Rebuild it from
		-- the fresh item -- unless a sale is being held, which a rebuild would
		-- silently reset -- and close it if the item is gone.
		if eq.card and eq.card.Parent and eq.cardKey and eq.cardMode ~= "confirm" then
			local fresh
			for _, sl in ipairs(EQUIP_SLOTS()) do
				for _, it in ipairs(equipItems(sl.id)) do
					if it.key == eq.cardKey then
						fresh = it
					end
				end
			end
			if fresh then
				showItemCard(fresh)
			else
				eq.card:Destroy()
				eq.card = nil
			end
		end
	end

	-- Collection -> Equipment: what exists, not what you have. Gear sets down
	-- the page, tool families across the top, both straight off their tables so
	-- the dex cannot fall behind the game.
	local function renderNewGear(kind)
		local isFace = kind == "faces"
		local title = isFace and "Your faces" or "Your hats"
		sectionHeader(title, 1)
		-- Three hat seats: show what is in each one.
		if not isFace then
			local eq = state.equippedGear or {}
			local byId = {}
			for _, g in ipairs(state.gear or {}) do
				if g.id then byId[g.id] = g end
			end
			local names = {}
			for _, slot in ipairs(Gear.HAT_SLOTS or { "hat" }) do
				local piece = byId[eq[slot] or ""]
				table.insert(names, (piece and (piece.name or piece.setName)) or "—")
			end
			sectionHeader("Wearing: " .. table.concat(names, "  +  "), 2)
		end
		--------------------------------------------------------------------
		-- UPGRADE. Two matching pieces fuse into one of the next grade.
		--
		-- MineGear.upgradePairs decides what is offerable and Verbs.upgradeGear
		-- re-checks with the same MineGear.canUpgrade, so this list can never
		-- put up a pair the server then refuses. Worn pieces are excluded by that
		-- function, not by anything here.
		--------------------------------------------------------------------
		if Gear.upgradePairs then
			local used = {}
			for _, id in pairs(state.equippedGear or {}) do
				if id then used[id] = true end
			end
			local pool = {}
			for _, g in ipairs(state.gear or {}) do
				if isFace and Gear.isFacePiece(g) or ((not isFace) and Gear.isHatPiece(g)) then
					table.insert(pool, g)
				end
			end
			local ready = Gear.upgradePairs(pool, used)
			if #ready > 0 then
				sectionHeader(string.format("Upgrade  (%d ready)", #ready), 3)
				local ups = mk("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -6, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = 4,
				}, body)
				mk("UIGridLayout", {
					CellPadding = UDim2.fromOffset(8, 8),
					CellSize = UDim2.fromOffset(232, 96),
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
				}, ups)
				for pi, pair in ipairs(ready) do
					if pi > 12 then
						break
					end
					local tint = Gear.RARITY_COLOR[pair.to] or MUTED
					local row = mk("Frame", { BackgroundColor3 = BG2, LayoutOrder = pi }, ups)
					round(row, 8)
					stroke(row, 1, tint)
					for k, piece in ipairs({ pair.a, pair.b }) do
						local well = mk("Frame", {
							BackgroundColor3 = BG3,
							Position = UDim2.fromOffset(8 + (k - 1) * 52, 8),
							Size = UDim2.fromOffset(46, 46),
						}, row)
						round(well, 6)
						local img = Gear.image and Gear.image(piece)
						if (not img) and piece.catalogId and NG then
							img = NG.icon(piece.catalogId)
						end
						if img then
							mk("ImageLabel", {
								BackgroundTransparency = 1,
								Image = img,
								ScaleType = Enum.ScaleType.Fit,
								Size = UDim2.fromScale(1, 1),
							}, well)
						end
					end
					label(row, tostring(pair.from) .. "  +  " .. tostring(pair.from), 12, MUTED,
						UDim2.fromOffset(8, 58), UDim2.fromOffset(104, 16), FONT)
					label(row, "\u{2192}  " .. tostring(pair.to), 22, tint,
						UDim2.fromOffset(116, 8), UDim2.fromOffset(108, 44), FONT)
					local go = mk("TextButton", {
						AutoButtonColor = true,
						BackgroundColor3 = GREEN,
						Font = FONT,
						TextSize = 13,
						TextColor3 = Color3.fromRGB(10, 26, 16),
						Text = "FUSE",
						Position = UDim2.fromOffset(116, 58),
						Size = UDim2.fromOffset(108, 28),
					}, row)
					round(go, 6)
					go.MouseButton1Click:Connect(function()
						if opts.onUpgradeGear then
							opts.onUpgradeGear(pair.a.id, pair.b.id)
						end
					end)
				end
			end
		end
		local grid = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -6, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 5,
		}, body)
		mk("UIGridLayout", {
			CellPadding = UDim2.fromOffset(8, 8),
			CellSize = UDim2.fromOffset(150, 170),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
		}, grid)
		local shown = 0
		local eq = state.equippedGear or {}
		for i, g in ipairs(state.gear or {}) do
			local ok = isFace and Gear.isFacePiece(g) or ((not isFace) and Gear.isHatPiece(g))
			if ok and matches(tostring(g.name or "") .. " " .. tostring(g.rarity or "")) then
				shown += 1
				local col = Gear.RARITY_COLOR[g.rarity] or MUTED
				local on = (eq.face == g.id)
				for _, slot in ipairs(Gear.HAT_SLOTS or { "hat" }) do
					on = on or (eq[slot] == g.id)
				end
				local tile = mk("Frame", { BackgroundColor3 = on and CARD_HI or BG2, LayoutOrder = i }, grid)
				round(tile, 8)
				stroke(tile, on and 2 or 1, on and GREEN or col)
				local well = mk("Frame", {
					BackgroundColor3 = BG3,
					Position = UDim2.fromOffset(8, 8),
					Size = UDim2.new(1, -16, 0, 90),
				}, tile)
				round(well, 6)
				local img = (g.catalogId and NG and NG.icon(g.catalogId))
					or (Gear.image and Gear.image(g))
				if img then
					mk("ImageLabel", {
						BackgroundTransparency = 1,
						Image = img,
						ScaleType = Enum.ScaleType.Fit,
						Size = UDim2.fromScale(1, 1),
					}, well)
				end
				do
					local chip = mk("Frame", {
						BackgroundColor3 = Color3.fromRGB(16, 18, 24),
						Position = UDim2.fromOffset(4, 4),
						Size = UDim2.fromOffset(22, 22),
						ZIndex = 4,
					}, well)
					round(chip, 6)
					stroke(chip, 1, col)
					label(chip, tostring(g.rarity or "?"), 11, col,
						UDim2.new(), UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center)
				end
				label(tile, tostring(g.rarity or "") .. " " .. tostring(g.name or g.setName or "Hat"), 12, TEXT,
					UDim2.fromOffset(8, 102), UDim2.new(1, -16, 0, 28), FONT)
				local btn = mk("TextButton", {
					AutoButtonColor = true,
					BackgroundColor3 = on and DEAD or GREEN,
					Font = FONT,
					TextSize = 13,
					TextColor3 = on and TEXT or Color3.fromRGB(10, 26, 16),
					Text = on and "UNEQUIP" or "EQUIP",
					Position = UDim2.fromOffset(8, 134),
					Size = UDim2.new(1, -16, 0, 28),
				}, tile)
				round(btn, 6)
				btn.MouseButton1Click:Connect(function()
					if on then
						if opts.onUnequipGear then opts.onUnequipGear(isFace and "face" or "hat", g.id) end
					elseif opts.onEquipGear then
						opts.onEquipGear(g.id)
					end
				end)
			end
		end
		if shown == 0 then
			sectionHeader(isFace and "No faces owned yet." or "No hats owned yet.", 6)
		end

		if not NG then
			return
		end
		sectionHeader("Limiteds", 7)
		local chipRow = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -6, 0, 32),
			LayoutOrder = 8,
		}, body)
		mk("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, chipRow)
		local function gradeChip(order, id, text, col)
			local on = (id == nil and newGearGrade == nil) or (id ~= nil and newGearGrade == id)
			local b = mk("TextButton", {
				AutoButtonColor = true,
				BackgroundColor3 = on and col or BG2,
				Font = FONT,
				TextSize = 13,
				TextColor3 = on and Color3.fromRGB(16, 16, 18) or col,
				Text = text,
				Size = UDim2.fromOffset(id == nil and 44 or 40, 28),
				LayoutOrder = order,
			}, chipRow)
			round(b, 7)
			if not on then stroke(b, 1, col) end
			b.MouseButton1Click:Connect(function()
				newGearGrade = id
				render()
			end)
		end
		gradeChip(0, nil, "ALL", MUTED)
		for i, g in ipairs(NG.GRADES) do
			gradeChip(i, g, g, Gear.RARITY_COLOR[g] or MUTED)
		end
		local rows = NG.byGrade(kind, newGearGrade)
		local grid = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -6, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 7,
		}, body)
		local CW = 136
		local CH = 188
		mk("UIGridLayout", {
			CellPadding = UDim2.fromOffset(8, 8),
			CellSize = UDim2.fromOffset(CW, CH),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
		}, grid)
		local shown = 0
		for i, row in ipairs(rows) do
			local hay = tostring(row.n) .. " " .. tostring(row.g) .. " " .. tostring(row.id)
			if matches(hay) then
				shown += 1
				local col = Gear.RARITY_COLOR[row.g] or MUTED
				local tile = mk("Frame", { BackgroundColor3 = BG2, LayoutOrder = i }, grid)
				round(tile, 8)
				stroke(tile, 1.5, col)
				local banner = mk("Frame", {
					BackgroundColor3 = col,
					Size = UDim2.new(1, 0, 0, 20),
				}, tile)
				label(banner, row.g .. "  " .. (isFace and "FACE" or "HAT"), 11,
					Color3.fromRGB(18, 18, 22), UDim2.fromOffset(8, 0), UDim2.new(1, -12, 1, 0), FONT)
				local well = mk("Frame", {
					BackgroundColor3 = BG3,
					Position = UDim2.fromOffset(8, 26),
					Size = UDim2.new(1, -16, 0, 108),
				}, tile)
				round(well, 6)
				mk("ImageLabel", {
					BackgroundTransparency = 1,
					Image = NG.icon(row.id),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(0.9, 0.9),
				}, well)
				do
					local chip = mk("Frame", {
						BackgroundColor3 = Color3.fromRGB(16, 18, 24),
						Position = UDim2.fromOffset(4, 4),
						Size = UDim2.fromOffset(22, 22),
						ZIndex = 4,
					}, well)
					round(chip, 6)
					stroke(chip, 1, col)
					label(chip, tostring(row.g), 11, col,
						UDim2.new(), UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center)
				end
				label(tile, row.n, 13, TEXT, UDim2.fromOffset(8, 138),
					UDim2.new(1, -16, 0, 22), FONT)
				label(tile, shortNum(row.r) .. " RAP", 12, GOLD, UDim2.fromOffset(8, 160),
					UDim2.new(1, -16, 0, 18), FONT_M)
			end
		end
		if shown == 0 then
			sectionHeader("No limiteds match.", 8)
		end
	end

	local function renderEquipmentDex()
		local layoutOrder = 0
		local function nextOrder()
			layoutOrder += 1
			return layoutOrder
		end

		-- Every coin-ladder rung as an icon tile. Owned = lit; not yet bought = blacked out.
		for _, fam in ipairs(Tools.FAMILIES) do
			if not fam.planned then
				local list = Tools.TOOLS[fam.id] or {}
				local ownedTier = tonumber((state.tools or {})[fam.id]) or 0
				sectionHeader(fam.name .. "  ·  " .. ownedTier .. " / " .. #list, nextOrder())
				local grid = mk("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -6, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = nextOrder(),
				}, body)
				mk("UIGridLayout", {
					CellPadding = UDim2.fromOffset(8, 8),
					CellSize = UDim2.fromOffset(100, 118),
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
				}, grid)
				for tier, def in ipairs(list) do
					if matches(tostring(def.name) .. " " .. tostring(def.id)) then
						local owned = ownedTier >= tier
						local icon = Icons.image(def.id) or Icons.image(fam.id) or Icons.image("pickaxe")
						local item = {
							name = owned and def.name or "???",
							id = def.id, family = fam.id, tier = tier, def = def,
							slot = "tool", source = "ladder", icon = icon,
							rarity = nil, locked = not owned, discovered = owned,
						}
						local tile = mk("Frame", { BackgroundColor3 = BG2, LayoutOrder = tier }, grid)
						round(tile, 8)
						stroke(tile, 1, owned and Color3.fromRGB(88, 88, 98) or Color3.fromRGB(28, 28, 34))
						eq.thumb(tile, item, 72, UDim2.new(0.5, -36, 0, 8), false)
						local nm = label(tile, owned and tostring(def.name) or "???", 11,
							owned and TEXT or Color3.fromRGB(72, 72, 84),
							UDim2.fromOffset(4, 86), UDim2.new(1, -8, 0, 28),
							FONT, Enum.TextXAlignment.Center)
						nm.TextWrapped = true
						nm.TextYAlignment = Enum.TextYAlignment.Top
					end
				end
			end
		end

		-- Forever / chest tools: authored rarity when found, blacked out until discovered.
		do
			local have = {}
			for _, row in ipairs(state.chestTools or {}) do
				local id = (type(row) == "table") and row.id or row
				if type(id) == "string" then have[id] = row end
			end
			local list = Tools.CHEST_TOOLS or {}
			local found = 0
			for _, def in ipairs(list) do
				if have[def.id] then found += 1 end
			end
			sectionHeader("Found tools  ·  " .. found .. " / " .. #list, nextOrder())
			local grid = mk("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -6, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = nextOrder(),
			}, body)
			mk("UIGridLayout", {
				CellPadding = UDim2.fromOffset(8, 8),
				CellSize = UDim2.fromOffset(100, 118),
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
			}, grid)
			for i, def in ipairs(list) do
				if matches(tostring(def.name) .. " " .. tostring(def.id) .. " " .. tostring(def.rarity or "")) then
					local owned = have[def.id] ~= nil
					local icon = Icons.image(def.id)
						or Icons.image(def.family)
						or Icons.image("pickaxe")
					local item = {
						name = owned and def.name or "???",
						id = def.id, def = def, slot = "tool", source = "forever",
						icon = icon, rarity = owned and def.rarity or nil,
						locked = not owned, discovered = owned,
					}
					local ink = (owned and def.rarity and gradeInk(def.rarity)) or Color3.fromRGB(28, 28, 34)
					local tile = mk("Frame", { BackgroundColor3 = BG2, LayoutOrder = i }, grid)
					round(tile, 8)
					stroke(tile, owned and 2 or 1, ink)
					eq.thumb(tile, item, 72, UDim2.new(0.5, -36, 0, 8), false)
					local nm = label(tile, owned and tostring(def.name) or "???", 11,
						owned and ink or Color3.fromRGB(72, 72, 84),
						UDim2.fromOffset(4, 86), UDim2.new(1, -8, 0, 28),
						FONT, Enum.TextXAlignment.Center)
					nm.TextWrapped = true
					nm.TextYAlignment = Enum.TextYAlignment.Top
				end
			end
		end

		sectionHeader("Gear sets", nextOrder())
		local owned = {}
		for _, g in ipairs(state.gear or {}) do
			owned[g.setId or ""] = (owned[g.setId or ""] or 0) + 1
		end
		local setRow = mk("Frame", { BackgroundTransparency = 1,
			Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = nextOrder() }, body)
		mk("UIGridLayout", { CellPadding = UDim2.fromOffset(8, 8),
			CellSize = UDim2.fromOffset(176, 78), SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Left }, setRow)
		for i, set in ipairs(Gear.SETS) do
			if matches(set.name .. " " .. (set.fantasy or "") .. " " .. (set.stat or "")) then
				local have = owned[set.id] or 0
				local tile = mk("Frame", { BackgroundColor3 = BG2, LayoutOrder = i }, setRow)
				round(tile, 8)
				stroke(tile, 1)
				label(tile, set.name, 14, have > 0 and TEXT or MUTED,
					UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 18), FONT)
				label(tile, tostring(set.fantasy or set.stat), 11, MUTED,
					UDim2.fromOffset(12, 28), UDim2.new(1, -24, 0, 16))
				label(tile, have .. " / " .. #Gear.SLOTS .. " pieces", 12,
					have >= #Gear.SLOTS and GREEN or GOLD, UDim2.fromOffset(12, 50),
					UDim2.new(1, -24, 0, 16), FONT)
			end
		end
	end

	local function renderPotions()
		local pot = state.potions or { bag = {}, active = {} }
		local order = 0
		if type(pot.active) == "table" and #pot.active > 0 then
			note(body, "Highest % on a stat ticks first. Same % adds duration.  3 of a kind + stardust merges one tier up.", 0)
			for _, row in ipairs(pot.active) do
				order += 1
				local rf = panelRow(body, 40, order)
				local pct = math.floor((tonumber(row.add) or 0) * 100 + 0.5)
				local tag = row.live and "LIVE" or "queued"
				label(rf, string.format("%s  +%d%%  %s  %ds", tostring(row.name or "?"), pct, tag, math.floor(tonumber(row.remaining) or 0)),
					14, TEXT, UDim2.fromOffset(14, 0), UDim2.new(1, -28, 1, 0), FONT)
			end
		end
		for _, row in ipairs(pot.bag or {}) do
			order += 1
			local canMerge = row.mergeTo and (tonumber(row.qty) or 0) >= 3
			local rf = panelRow(body, 52, order)
			label(rf, string.format("%s  x%d", tostring(row.name or row.id), tonumber(row.qty) or 0),
				15, TEXT, UDim2.fromOffset(14, 6), UDim2.new(1, canMerge and -250 or -150, 0, 22), FONT)
			label(rf, tostring(row.blurb or ""), 12, MUTED, UDim2.fromOffset(14, 28), UDim2.new(1, canMerge and -250 or -150, 0, 16))
			if canMerge then
				local mb = mk("TextButton", {
					AutoButtonColor = true, BackgroundColor3 = (T.DUST or GOLD), Font = FONT, TextSize = 13,
					TextColor3 = Color3.fromRGB(26, 20, 40),
					Text = "3 + " .. tostring(row.mergeCost or 15) .. " DUST",
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -112, 0.5, 0),
					Size = UDim2.fromOffset(118, 32),
				}, rf)
				round(mb, 8)
				mb.MouseButton1Click:Connect(function()
					if opts.onMergePotion then opts.onMergePotion(row.id) end
				end)
			end
			local btn = mk("TextButton", {
				AutoButtonColor = true, BackgroundColor3 = GOLD, Font = FONT, TextSize = 14,
				TextColor3 = Color3.fromRGB(26, 20, 40), Text = "DRINK",
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(90, 32),
			}, rf)
			round(btn, 8)
			btn.MouseButton1Click:Connect(function()
				if opts.onDrinkPotion then opts.onDrinkPotion(row.id) end
			end)
		end
		local b = state.boosts or {}
		local keys = {}
		for k in pairs(BOOST_LABEL) do
			table.insert(keys, k)
		end
		table.sort(keys)
		local any = false
		local ADDITIVE_SHOW = { echo = true, zap = true, blastRadius = true, autoMine = true, oreYield = true, luckyFind = true, fossilFind = true, pulverize = true, scrap = true, coolant = true, shortFuse = true, reach = true }
		for _, k in ipairs(keys) do
			local v = tonumber(b[k])
			local pct = nil
			if v and matches(BOOST_LABEL[k]) then
				if ADDITIVE_SHOW[k] then
					if math.abs(v) > 0.0001 then
						pct = math.floor(v * 100 + 0.5)
					end
				elseif math.abs(v - 1) > 0.0001 then
					pct = math.floor((v - 1) * 100 + 0.5)
				end
			end
			if pct then
				any = true
				order += 1
				-- Where it comes from: each pet by name, runes, skills, gear...
				-- (server: Dig.boostSources). "Blast +12%" used to be a number
				-- with no way to tell which pet was giving it.
				local src = (state.boostSources or {})[k]
				local parts = {}
				if type(src) == "table" then
					local list = table.clone(src)
					table.sort(list, function(a, c)
						return math.abs(a.a or 0) > math.abs(c.a or 0)
					end)
					for i2, e in ipairs(list) do
						if i2 > 4 then
							parts[#parts + 1] = "+" .. (#list - 4) .. " more"
							break
						end
						parts[#parts + 1] = string.format("%s +%d%%", tostring(e.n), math.floor((e.a or 0) * 100 + 0.5))
					end
				end
				local tall = #parts > 0
				local row = panelRow(body, tall and 58 or 40, order)
				label(row, BOOST_LABEL[k], 15, TEXT, UDim2.fromOffset(14, tall and 6 or 0),
					UDim2.new(0.6, 0, 0, tall and 24 or 40), FONT)
				label(row, string.format("+%d%%", pct), 15, GREEN,
					UDim2.new(1, -110, 0, tall and 6 or 0), UDim2.fromOffset(96, tall and 24 or 40), FONT, Enum.TextXAlignment.Right)
				if tall then
					local from = label(row, "from " .. table.concat(parts, "  ·  "), 12, MUTED,
						UDim2.fromOffset(14, 31), UDim2.new(1, -28, 0, 20))
					from.TextTruncate = Enum.TextTruncate.AtEnd
				end
			end
		end
		if not any then
			note(body, "No boosts running. Cards on your team are what raise these.")
		end
		note(body, "Live totals from everything you are running. The small line under each says where it comes from.", 99)
	end

	-- The Runes tab used to list MineConfig.RELICS, which are not runes -- they
	-- are flat-stat relics, and every one of them read "Not found yet" forever.
	-- It shows the seven rune sets and how far along each one you are, which is
	-- the thing a collection tab is for.
	-- One equipped identity. Not a rune socket — equip/unequip freely, never destroyed.
		local function renderVfx()
			local Vfx = require(shared:WaitForChild("MineVfx"))
			local owned = state.vfx or {}
			local eq = Vfx.normalize(state.equippedVfx)
			local head = panelRow(body, 48, 0)
			label(head, "VFX", 16, TEXT, UDim2.fromOffset(14, 4), UDim2.new(0.55, 0, 0, 22), FONT)
			label(head, "Nameplate · trail · shovel · tag", 12, MUTED,
				UDim2.fromOffset(14, 26), UDim2.new(1, -28, 0, 16))
			local order = 1
			local shown = 0
			for _, kindRow in ipairs(Vfx.KINDS or {}) do
				order += 1
				sectionHeader(kindRow.label, order)
				for _, def in ipairs(Vfx.CATALOG or {}) do
					if def.kind == kindRow.id and (owned[def.id] or (def.priceCredits or 0) == 0) then
						if matches(def.name .. " " .. kindRow.label) then
							shown += 1
							order += 1
							local wearing = eq[def.kind] == def.id
							local row = panelRow(body, 56, order)
							label(row, def.name, 15, wearing and GOLD or TEXT,
								UDim2.fromOffset(14, 8), UDim2.new(1, -140, 0, 22), FONT)
							label(row, kindRow.label .. (def.limited and " · limited" or ""),
								12, MUTED, UDim2.fromOffset(14, 30), UDim2.new(1, -140, 0, 18))
							local btn = mk("TextButton", {
								Text = wearing and "EQUIPPED" or "EQUIP",
								Font = FONT,
								TextSize = 13,
								TextColor3 = wearing and Color3.fromRGB(40, 30, 20) or Color3.fromRGB(20, 40, 24),
								BackgroundColor3 = wearing and Color3.fromRGB(255, 196, 120) or GREEN,
								Size = UDim2.fromOffset(110, 36),
								Position = UDim2.new(1, -124, 0.5, -18),
								AutoButtonColor = not wearing,
							}, row)
							round(btn, 8)
							if not wearing then
								btn.MouseButton1Click:Connect(function()
									if opts.onEquipVfx then opts.onEquipVfx(def.kind, def.id) end
								end)
							end
						end
					end
				end
			end
			if shown == 0 then
				note(body, "No vanity owned yet. Free defaults unlock on join — buy limited VFX in Shop → VFX.")
			end
		end

		local function renderRunes()
		local Runes = require(shared:WaitForChild("MineRunes"))
		local owned = state.runes or {}

		-- Distinct slots held per set, whether socketed or in the bag.
		local held = {}
		for _, r in ipairs(owned) do
			if type(r) == "table" and r.setId and r.slot then
				held[r.setId] = held[r.setId] or {}
				held[r.setId][r.slot] = (held[r.setId][r.slot] or 0) + 1
			end
		end

		local loose = 0
		for _, r in ipairs(owned) do
			if type(r) == "table" and not r.setId then
				loose += 1
			end
		end

		local head = panelRow(body, 40, 0)
		label(head, "Rune sets", 15, TEXT, UDim2.fromOffset(14, 0), UDim2.new(0.6, 0, 1, 0), FONT)
		label(head, #owned .. " runes held", 14, GOLD, UDim2.new(1, -160, 0, 0),
			UDim2.fromOffset(146, 40), FONT, Enum.TextXAlignment.Right)

		for i, set in ipairs(Runes.SETS) do
			if matches(set.name .. " " .. table.concat(set.slots, " ")) then
				local mine = held[set.id] or {}
				local have = 0
				for slot = 1, #set.slots do
					if mine[slot] then
						have += 1
					end
				end
				local complete = have >= #set.slots
				local row = panelRow(body, 78, i)
				label(row, set.name, 15, complete and GOLD or TEXT, UDim2.fromOffset(14, 6),
					UDim2.new(1, -140, 0, 20), FONT)
				label(row, have .. " / " .. #set.slots, 14, complete and GOLD or MUTED,
					UDim2.new(1, -120, 0, 6), UDim2.fromOffset(106, 20), FONT, Enum.TextXAlignment.Right)
				-- Which of the three you are missing, by name, because "2/3" does
				-- not tell you what to go and buy a crate for.
				local bits = {}
				for slot, stat in ipairs(set.slots) do
					local n = mine[slot] or 0
					local tag = (slot == 3) and " (chase)" or ""
					bits[#bits + 1] = string.format("%s%s %s", stat, tag, n > 0 and ("x" .. n) or "--")
				end
				label(row, table.concat(bits, "    "), 12, MUTED, UDim2.fromOffset(14, 30),
					UDim2.new(1, -28, 0, 18))
				label(row, complete
						and ("Set bonus active: +" .. math.floor(Runes.SET_BONUS_PCT * 100) .. "% " .. set.bonus .. " when all three are socketed")
						or ("Completes to: +" .. math.floor(Runes.SET_BONUS_PCT * 100) .. "% " .. set.bonus),
					12, complete and GREEN or GEM, UDim2.fromOffset(14, 50), UDim2.new(1, -28, 0, 18))
			end
		end

		if loose > 0 then
			note(body, loose .. " older runes belong to no set. They still work; they just cannot complete one.", 99)
		end
	end
	----------------------------------------------------------------------------
	-- COLLECTION
	----------------------------------------------------------------------------
	-- The chest directory. Once you have cracked one, it tells you exactly what it
	-- pays -- the same numbers the server rolls against, read out of the same table,
	-- so this cannot quietly start lying to the player.
	local function renderChestDex()
		local ZoneChests = require(shared:WaitForChild("MineZoneChests"))
		local Ranks = require(shared:WaitForChild("MineChestRanks"))
		local ZonePacks = require(shared:WaitForChild("MineZonePacks"))
		local Icons = require(shared:WaitForChild("MineIcons"))
		local rows = ZoneChests.collectionRows and ZoneChests.collectionRows() or {}
		local found = state.found or {}
		local function foundCount(id)
			if id == nil then return 0 end
			local n = found[id] or found[tostring(id)]
			if n == true then return 1 end
			return tonumber(n) or 0
		end
		local total, seen = #rows, 0
		for _, def in ipairs(rows) do
			if foundCount(def.id) > 0 then
				seen += 1
			end
		end
		local head = panelRow(body, 40, 0)
		label(head, "Chests found", 15, TEXT, UDim2.fromOffset(14, 0), UDim2.new(0.6, 0, 1, 0), FONT)
		label(head, seen .. " / " .. total, 15, GOLD, UDim2.new(1, -120, 0, 0),
			UDim2.fromOffset(106, 40), FONT, Enum.TextXAlignment.Right)

		--[[
			TILES, NOT ROWS. The chest directory reads like the pack dex now:
			a grid of art tiles per zone, dimmed until found, with the payout
			bands on the face once you have cracked one. Same cell size and
			same dim-veil rules as the packs tab, so Collection feels like one
			screen rather than three different lists.
		]]
		local byZone = {}
		for _, def in ipairs(rows) do
			local zid = (def.zones[1] and def.zones[1].zoneId) or "meadow"
			byZone[zid] = byZone[zid] or {}
			table.insert(byZone[zid], def)
		end
		local order = 0
		local zoneOrder = {}
		for _, zid in ipairs(ZonePacks.ZONE_ORDER or {}) do
			table.insert(zoneOrder, zid)
		end
		table.insert(zoneOrder, ZonePacks.LIMITED_ZONE or "bigbang")
		for _, zid in ipairs(zoneOrder) do
			local inZone = byZone[zid]
			if inZone and #inZone > 0 then
				local zoneName = (ZonePacks.ZONE_LABEL and ZonePacks.ZONE_LABEL[zid]) or zid
				for _, z in ipairs(C.ZONES or {}) do
					if z.id == zid then zoneName = z.name or zoneName break end
				end
				order += 1
				local hdr = mk("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -6, 0, 26),
					LayoutOrder = order,
				}, body)
				label(hdr, string.upper(zoneName), 13, MUTED, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0), FONT)
				order += 1
				local grid = mk("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -6, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = order,
				}, body)
				mk("UIGridLayout", {
					CellPadding = UDim2.fromOffset(8, 8),
					CellSize = UDim2.fromOffset(158, 188),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}, grid)
				local anyInZone = false
				for ti, def in ipairs(inZone) do
					local count = foundCount(def.id)
					local has = count > 0
					local rankBits = {}
					for _, zr in ipairs(def.zones or {}) do
						local rlab = (Ranks.LABEL and Ranks.LABEL[zr.rank]) or zr.rank
						table.insert(rankBits, string.format("%s:%s", zr.zoneId, rlab))
					end
					if matches(def.name .. " " .. zoneName .. " " .. table.concat(rankBits, " ")) then
						anyInZone = true
						local tile = mk("Frame", { BackgroundColor3 = BG2, LayoutOrder = ti }, grid)
						round(tile, 8)
						stroke(tile, 1.5, has and GOLD or Color3.fromRGB(58, 58, 68))
						local cap2 = mk("Frame", {
							BackgroundColor3 = has and GOLD or Color3.fromRGB(58, 58, 68),
							Size = UDim2.new(1, 0, 0, 6),
						}, tile)
						round(cap2, 3)
						local img = Icons.image(def.id)
						if img then
							local host = mk("Frame", {
								BackgroundTransparency = 1,
								AnchorPoint = Vector2.new(0.5, 0),
								Position = UDim2.new(0.5, 0, 0, 14),
								Size = UDim2.fromOffset(72, 72),
								ZIndex = 3,
							}, tile)
							local pic = Instance.new("ImageLabel")
							pic.BackgroundTransparency = 1
							pic.BorderSizePixel = 0
							pic.Image = img
							pic.Size = UDim2.fromScale(1, 1)
							pic.ScaleType = Enum.ScaleType.Fit
							pic.ImageTransparency = has and 0 or 0.5
							pic.ZIndex = 4
							pic.Parent = host
						end
						local nameL = label(tile, def.name, 13, has and TEXT or Color3.fromRGB(120, 120, 132),
							UDim2.fromOffset(8, 90), UDim2.new(1, -16, 0, 32), FONT, Enum.TextXAlignment.Center)
						nameL.TextWrapped = true
						nameL.TextTruncate = Enum.TextTruncate.AtEnd
						if has then
							label(tile, "FOUND x" .. count, 11, GREEN,
								UDim2.fromOffset(8, 124), UDim2.new(1, -16, 0, 14), FONT, Enum.TextXAlignment.Center)
							local payL = label(tile, string.format("%s-%s coins · %s-%s gems",
								shortNum(def.coins[1]), shortNum(def.coins[2]),
								shortNum(def.gems[1]), shortNum(def.gems[2])),
								10, GOLD, UDim2.fromOffset(8, 140), UDim2.new(1, -16, 0, 26), nil, Enum.TextXAlignment.Center)
							payL.TextWrapped = true
							payL.TextTruncate = Enum.TextTruncate.None
							local pbits = {}
							for _, pk in ipairs(def.packs or {}) do
								table.insert(pbits, tostring(pk.chance) .. "% " .. tostring(pk.slot))
							end
							if #pbits > 0 then
								label(tile, table.concat(pbits, "  "), 9, GEM,
									UDim2.fromOffset(8, 168), UDim2.new(1, -16, 0, 14), nil, Enum.TextXAlignment.Center)
							end
						else
							label(tile, "Not found yet", 11, Color3.fromRGB(96, 96, 108),
								UDim2.fromOffset(8, 130), UDim2.new(1, -16, 0, 16), FONT_M, Enum.TextXAlignment.Center)
						end
					end
				end
				if not anyInZone then
					hdr:Destroy()
					grid:Destroy()
				end
			end
		end
	end

	local function renderCardDex()
		local owned = {}
		for _, card in ipairs(state.cards or {}) do
			local set = owned[card.setId]
			if not set then
				set = {}
				owned[card.setId] = set
			end
			set[card.index or card.cardKey or 0] = true
		end
		local ids = {}
		for id in pairs(Cards.SETS) do
			table.insert(ids, id)
		end
		table.sort(ids)
		local order = 0
		for _, id in ipairs(ids) do
			local set = Cards.SETS[id]
			local name = set.displayName or id
			if matches(name .. " " .. tostring(set.theme or "")) then
				order += 1
				local have = 0
				for _ in pairs(owned[id] or {}) do
					have += 1
				end
				local cap = set.cardCount or 0
				local row = panelRow(body, 52, order)
				label(row, name, 15, have > 0 and TEXT or MUTED, UDim2.fromOffset(14, 6),
					UDim2.new(1, -140, 0, 20), FONT)
				label(row, have .. " / " .. cap, 14, have >= cap and GOLD or MUTED,
					UDim2.new(1, -120, 0, 6), UDim2.fromOffset(106, 20), FONT, Enum.TextXAlignment.Right)
				-- A bar, because "31 / 98" is a number and a bar is a feeling.
				local track = mk("Frame", {
					BackgroundColor3 = BG3,
					Position = UDim2.fromOffset(14, 32),
					Size = UDim2.new(1, -28, 0, 8),
				}, row)
				round(track, 4)
				local fillPct = cap > 0 and math.clamp(have / cap, 0, 1) or 0
				local fill = mk("Frame", {
					BackgroundColor3 = have >= cap and GOLD or GREEN,
					Size = UDim2.fromScale(fillPct, 1),
				}, track)
				round(fill, 4)
			end
		end
	end

	----------------------------------------------------------------------------
	-- SHOP and PASS
	----------------------------------------------------------------------------
	local function bigButton(text, sub, colour, order, fn)
		local row = panelRow(body, 56, order)
		row.BackgroundColor3 = colour or BG2
		label(row, text, 16, TEXT, UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 22), FONT)
		label(row, sub, 12, Color3.fromRGB(220, 224, 236), UDim2.fromOffset(14, 30), UDim2.new(1, -28, 0, 18))
		local hit = mk("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 3,
		}, row)
		hit.MouseButton1Click:Connect(fn)
		return row
	end

	----------------------------------------------------------------------------
	-- CHECKOUT
	----------------------------------------------------------------------------

	--[[
		The purchase sheet.

		Deliberately slow enough to be read. A purchase that completes in one
		frame gives the player nothing to trust -- they cannot tell whether it
		worked, and the only feedback is a number quietly changing somewhere
		else. A spinner, then a bar that fills, then a check, is the shape
		people already know from every storefront they have ever used.

		It is a lie in the sense that the server has usually already answered by
		the time the bar starts. It is not a lie about the OUTCOME: the bar only
		runs once the reply is in, and a failure shakes and says why.
	]]
	local function showPurchaseSheet(title, onSettled)
		if buySheet then
			buySheet:Destroy()
		end
		buySheet = mk("Frame", {
			Name = "BuySheet",
			BackgroundColor3 = BG,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(380, 280),
			ZIndex = 80,
		}, root)
		round(buySheet, 14)
		stroke(buySheet, 2, T.CREDIT or GOLD)

		local glyph = mk("Frame", {
			BackgroundColor3 = T.CREDIT or GOLD,
			BackgroundTransparency = 0.15,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 22),
			Size = UDim2.fromOffset(54, 54),
			ZIndex = 81,
		}, buySheet)
		round(glyph, 27)

		local titleL = label(buySheet, title, 17, TEXT, UDim2.fromOffset(16, 88),
			UDim2.new(1, -32, 0, 22), FONT)
		titleL.ZIndex = 81
		local waitingCopy = (title == "Pending") and "Pending" or "Confirming with Credits"
		local subL = label(buySheet, waitingCopy, 13, MUTED,
			UDim2.fromOffset(16, 112), UDim2.new(1, -32, 0, 18))
		subL.ZIndex = 81

		-- A real bar, not a picture of one.
		local track = mk("Frame", {
			BackgroundColor3 = BG3,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 146),
			Size = UDim2.fromOffset(280, 10),
			ZIndex = 81,
		}, buySheet)
		round(track, 5)
		local fill = mk("Frame", {
			BackgroundColor3 = T.CREDIT or GOLD,
			Size = UDim2.fromScale(0, 1),
			ZIndex = 82,
		}, track)
		round(fill, 5)

		return {
			-- Indeterminate: sweeps while we are still waiting on the server.
			sweep = function()
				task.spawn(function()
					local at = 0
					while buySheet and buySheet.Parent and at < 1 do
						at += 0.06
						fill.Size = UDim2.fromScale(math.min(at, 0.72), 1)
						task.wait(0.03)
					end
				end)
			end,
			settle = function(okFlag, message)
				if not buySheet or not buySheet.Parent then
					return
				end
				TweenService:Create(fill, TweenInfo.new(0.28), { Size = UDim2.fromScale(1, 1) }):Play()
				task.wait(0.3)
				glyph.BackgroundColor3 = okFlag and GREEN or (T.RED or Color3.fromRGB(255, 120, 120))
				local failTitle = (message == "Payment canceled") and "Payment canceled" or "Could not complete"
				titleL.Text = okFlag and "Purchased" or failTitle
				subL.Text = (not okFlag and message == "Payment canceled") and "No Robux was charged." or (message or "")
				subL.TextColor3 = okFlag and MUTED or (T.RED or MUTED)
				if not okFlag then
					-- A shake, because a red word alone is easy to miss.
					local home = buySheet.Position
					for i = 1, 6 do
						if not buySheet or not buySheet.Parent then
							return
						end
						buySheet.Position = home + UDim2.fromOffset((i % 2 == 0) and 8 or -8, 0)
						task.wait(0.03)
					end
					buySheet.Position = home
				end
				task.delay(okFlag and 0.9 or 1.6, function()
					if buySheet then
						buySheet:Destroy()
						buySheet = nil
					end
					if onSettled then
						onSettled(okFlag)
					end
				end)
			end,
		}
	end

	local pending

	local function doCheckout()
		local pay, sub = cartPayable()
		if #cart == 0 then
			return
		end
		if (state.credits or 0) < pay then
			local sheet = showPurchaseSheet("Checkout")
			sheet.sweep()
			task.spawn(function()
				task.wait(0.25)
				sheet.settle(false, "You have " .. shortNum(state.credits or 0) .. " credits, this costs " .. pay)
			end)
			return
		end
		local sheet = showPurchaseSheet("Checkout")
		sheet.sweep()
		pending = sheet
		local lines = {}
		for _, line in ipairs(cart) do
			table.insert(lines, {
				kind = line.kind, id = line.id, bundle = line.bundle, qty = line.qty,
				packs = line.packs,
			})
		end
		if opts.onBuyCart then
			opts.onBuyCart(lines)
		end
		-- If the server never answers, do not strand the sheet on screen.
		task.delay(6, function()
			if pending == sheet then
				pending = nil
				sheet.settle(false, "No reply from the server")
			end
		end)
	end

	--[[
		Called from MineClient when the server answers. Kept on the control
		surface rather than guessed at here, because only the server knows what
		the cart actually cost.
	]]
	function MineInventoryView._settleCart(okFlag, message, clearIt)
		if clearIt then
			cart = {}
		end
		local sheet = pending
		pending = nil
		if sheet then
			sheet.settle(okFlag, message)
		end
		refreshCart()
	end

	--[[
		The cart sheet: line items, qty steppers, remove, and the two numbers
		that matter -- subtotal, and what Credits actually pays.
	]]
	local function showCart()
		if cartP then
			cartP:Destroy()
			cartP = nil
		end
		cartP = mk("Frame", {
			Name = "Cart",
			BackgroundColor3 = BG,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -16, 0, 56),
			Size = UDim2.fromOffset(380, 460),
			ZIndex = 70,
		}, root)
		round(cartP, 12)
		stroke(cartP, 2, T.CREDIT or GOLD)

		local hdr = label(cartP, "CART", 18, TEXT, UDim2.fromOffset(16, 12),
			UDim2.new(1, -60, 0, 24), FONT)
		hdr.TextXAlignment = Enum.TextXAlignment.Left
		hdr.ZIndex = 71
		local closeB = mk("TextButton", {
			AutoButtonColor = true, BackgroundColor3 = BG2, Font = FONT, TextSize = 16,
			TextColor3 = TEXT, Text = "X",
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12),
			Size = UDim2.fromOffset(46, 46), ZIndex = 71,
		}, cartP)
		round(closeB, 8)
		closeB.MouseButton1Click:Connect(function()
			cartP:Destroy()
			cartP = nil
		end)

		local list = mk("ScrollingFrame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 50),
			Size = UDim2.new(1, -24, 1, -170),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 5,
			BorderSizePixel = 0,
			ZIndex = 71,
		}, cartP)
		mk("UIListLayout", { Padding = UDim.new(0, 6) }, list)

		if #cart == 0 then
			local e = label(list, "Nothing in the cart yet.", 13, MUTED,
				UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 40))
			e.ZIndex = 72
		end

		for idx, line in ipairs(cart) do
			local row = mk("Frame", {
				BackgroundColor3 = BG2, Size = UDim2.new(1, -4, 0, 56), LayoutOrder = idx, ZIndex = 72,
			}, list)
			round(row, 8)
			local name
			if line.kind == "pack" then
				local def = Packs.PACK_BY_ID[line.id]
				name = ((def and def.name) or line.id) .. (line.bundle and "  10x" or "")
			elseif line.kind == "lucky_block" then
				local LB = nil
				pcall(function() LB = require(shared:WaitForChild("MineLuckyBlocks")) end)
				local def = LB and LB.TYPES and LB.TYPES[line.id]
				local labelName = (def and def.name) or line.id
				if line.bundle and LB and LB.BUNDLE_10 then
					labelName = LB.BUNDLE_10.label or ("10x " .. labelName)
				end
				name = labelName
			elseif line.kind == "box" then
				name = "Custom Box  " .. tostring(#(line.packs or {})) .. " packs"
			else
				local item = (state.scrollShop or {})[line.id]
				name = ((item and item.name) or line.id) .. (line.bundle and "  5x" or "")
			end
			local nl = label(row, name, 14, TEXT, UDim2.fromOffset(10, 6), UDim2.new(1, -110, 0, 18), FONT)
			nl.TextXAlignment = Enum.TextXAlignment.Left
			nl.ZIndex = 73
			local plHost = mk("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(10, 28),
				Size = UDim2.new(1, -110, 0, 18),
				ZIndex = 73,
			}, row)
			Icons.priceChip(plHost, "credits", shortNum(linePrice(line) * line.qty), {
				iconSize = 14,
				textSize = 13,
				textColor = T.CREDIT or GOLD,
				font = FONT,
				zIndex = 73,
			})

			local function stepper(text, dx, fn)
				local b = mk("TextButton", {
					AutoButtonColor = true, BackgroundColor3 = BG3, Font = FONT, TextSize = 16,
					TextColor3 = TEXT, Text = text,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, dx, 0.5, 0), Size = UDim2.fromOffset(26, 26), ZIndex = 73,
				}, row)
				round(b, 6)
				b.MouseButton1Click:Connect(fn)
			end
			stepper("-", -66, function()
				line.qty -= 1
				if line.qty <= 0 then
					table.remove(cart, idx)
				end
				showCart()
				refreshCart()
			end)
			local q = label(row, "x" .. line.qty, 14, TEXT, UDim2.new(1, -64, 0, 0),
				UDim2.fromOffset(28, 56), FONT)
			q.ZIndex = 73
			stepper("+", -8, function()
				line.qty = math.min(25, line.qty + 1)
				showCart()
				refreshCart()
			end)
		end

		local pay, sub = cartPayable()
		local subL = label(cartP, "Subtotal   " .. shortNum(sub), 13, MUTED,
			UDim2.fromOffset(16, 0), UDim2.new(1, -32, 0, 18))
		subL.Position = UDim2.new(0, 16, 1, -112)
		subL.TextXAlignment = Enum.TextXAlignment.Left
		subL.ZIndex = 71
		local rate = math.floor(((Packs.discountFor and Packs.discountFor(isMember())) or 0.1) * 100 + 0.5)
		local discL = label(cartP, "Credits pay  -" .. rate .. "%   " .. shortNum(pay)
			.. (isMember() and "   (member)" or ""), 15,
			T.CREDIT or GOLD, UDim2.fromOffset(16, 0), UDim2.new(1, -32, 0, 20), FONT)
		discL.Position = UDim2.new(0, 16, 1, -92)
		discL.TextXAlignment = Enum.TextXAlignment.Left
		discL.ZIndex = 71

		local canPay = (state.credits or 0) >= pay and #cart > 0
		local confirm = mk("TextButton", {
			AutoButtonColor = true,
			BackgroundColor3 = canPay and (T.CREDIT or GOLD) or Color3.fromRGB(255, 168, 72),
			Font = FONT, TextSize = 16,
			TextColor3 = canPay and Color3.fromRGB(26, 20, 40) or Color3.fromRGB(28, 18, 8),
			Text = "",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -14),
			Size = UDim2.new(1, -32, 0, 44),
			ZIndex = 71,
		}, cartP)
		round(confirm, 10)
		if canPay then
			paintCostButton(confirm, "CONFIRM", pay, "credits", Color3.fromRGB(26, 20, 40))
		else
			confirm.Text = "GET CREDITS"
		end
		confirm.MouseButton1Click:Connect(function()
			if not canPay then
				if cartP then cartP:Destroy() cartP = nil end
				section = "shop"
				activeTab = "currencies"
				render()
				return
			end
			cartP:Destroy()
			cartP = nil
			doCheckout()
		end)
	end

	-- The floating pill. Always reachable, never in the way.
	refreshCart = function()
		local pay, n = cartPayable()
		local _, count = cartSubtotal()
		if cartPill then
			cartPill:Destroy()
			cartPill = nil
		end
		if count <= 0 then
			if cartP then
				cartP:Destroy()
				cartP = nil
			end
			return
		end
		cartPill = mk("TextButton", {
			Name = "CartPill",
			AutoButtonColor = true,
			BackgroundColor3 = T.CREDIT or GOLD,
			Font = FONT, TextSize = 15,
			TextColor3 = Color3.fromRGB(26, 20, 40),
			Text = "",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -16, 0, 14),
			Size = UDim2.fromOffset(210, 34),
			ZIndex = 75,
		}, root)
		round(cartPill, 17)
		paintCostButton(cartPill, "CART  " .. count, pay, "credits", Color3.fromRGB(26, 20, 40))
		cartPill.MouseButton1Click:Connect(showCart)
		if cartP then
			showCart()
		end
	end

	local function renderShop()
		if activeTab == "home" then
			--[[
				THE STOREFRONT.

				This was a list of seven text rows -- no art, no prices, half the
				window empty -- which read like a settings menu. Now: one hero for
				today's rotating offers, then big doors with real art, each a
				single tap from the thing it sells.
			]]
			local AMBER = Color3.fromRGB(255, 176, 64)
			local TEAL = Color3.fromRGB(48, 190, 170)
			local kScale = 1
			do
				local sg = root:FindFirstAncestorOfClass("ScreenGui")
				local ui = sg and sg:FindFirstChildOfClass("UIScale")
				kScale = (ui and ui.Scale > 0.05) and ui.Scale or 1
			end
			local wide = (body.AbsoluteSize.X / kScale) >= 700

			-- Three real packs to show off: the dearest card packs on the shelf.
			local showcase = {}
			do
				local rows = {}
				for _, def in ipairs(Packs.PACKS or {}) do
					if Packs.priceOf(def.id) and (not Packs.packKind or Packs.packKind(def.id) == "card") then
						table.insert(rows, def.id)
					end
				end
				table.sort(rows, function(x, y) return (Packs.priceOf(x) or 0) > (Packs.priceOf(y) or 0) end)
				for i = 1, math.min(3, #rows) do
					showcase[i] = rows[i]
				end
			end
			local function packFan(host, ids, w, h)
				-- Overlapped, not rotated: a rotated frame escapes the scroll clip.
				for i, pid in ipairs(ids) do
					local slot = mk("Frame", {
						BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.5, (i - 2) * math.floor(w * 0.55), 0.5, (i == 2) and -4 or 6),
						Size = UDim2.fromOffset(w, h), ZIndex = (i == 2) and 6 or 5,
					}, host)
					pcall(PackFX.drawSealed, slot, pid, w, h)
				end
			end
			local function iconArt(host, key, size, dx, dy, z)
				local img = Icons.image and Icons.image(key)
				if img then
					mk("ImageLabel", {
						BackgroundTransparency = 1, Image = img, ScaleType = Enum.ScaleType.Fit,
						AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, dx or 0, 0.5, dy or 0),
						Size = UDim2.fromOffset(size, size), ZIndex = z or 5,
					}, host)
				end
			end

			-- HERO
			local hero = mk("TextButton", {
				AutoButtonColor = false, Text = "", BackgroundColor3 = Color3.new(1, 1, 1),
				Size = UDim2.new(1, -6, 0, 170), LayoutOrder = 0, ClipsDescendants = true,
			}, body)
			round(hero, 14)
			stroke(hero, 2, AMBER)
			mk("UIGradient", { Rotation = 15, Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 42, 82)),
				ColorSequenceKeypoint.new(0.6, Color3.fromRGB(48, 26, 70)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 30, 40)),
			}) }, hero)
			local heroArt = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(22, 14),
				Size = UDim2.fromOffset(190, 142), ZIndex = 4 }, hero)
			packFan(heroArt, showcase, 74, 102)
			local tx = wide and 230 or 20
			local chip = mk("Frame", { BackgroundColor3 = AMBER, Position = UDim2.fromOffset(tx, 22),
				Size = UDim2.fromOffset(118, 22), ZIndex = 5 }, hero)
			round(chip, 11)
			label(chip, "LIMITED TODAY", 12, Color3.fromRGB(34, 20, 6), UDim2.fromScale(0, 0), UDim2.fromScale(1, 1),
				FONT, Enum.TextXAlignment.Center).ZIndex = 6
			label(hero, (RotatingOffers and RotatingOffers.headline()) or "Lucky Block Week · Pot of Gold · Founders Bag",
				wide and 24 or 18, TEXT, UDim2.fromOffset(tx, 52), UDim2.new(1, -(tx + 190), 0, 32), FONT).ZIndex = 5
			local secs = 86400 - (os.time() % 86400)
			label(hero, string.format("New offers in %dh %02dm", secs // 3600, (secs % 3600) // 60),
				14, Color3.fromRGB(200, 196, 230), UDim2.fromOffset(tx, 90), UDim2.new(1, -(tx + 190), 0, 20)).ZIndex = 5
			local goLtd = mk("TextButton", {
				AutoButtonColor = true, BackgroundColor3 = AMBER, Font = FONT, TextSize = 17,
				TextColor3 = Color3.fromRGB(34, 20, 6), Text = "SEE OFFERS",
				AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20),
				Size = UDim2.fromOffset(160, 48), ZIndex = 6,
			}, hero)
			round(goLtd, 12)
			local function toLimited()
				activeTab = "limited"
				render()
			end
			goLtd.MouseButton1Click:Connect(toLimited)
			hero.MouseButton1Click:Connect(toLimited)

			-- DOORS
			local grid = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 }, body)
			mk("UIGridLayout", {
				CellPadding = UDim2.fromOffset(10, 10),
				CellSize = wide and UDim2.new(0.5, -5, 0, 128) or UDim2.new(1, 0, 0, 116),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, grid)
			local doors = {
				{ tab = "packs", title = "Card Packs", sub = "Singles and 10× warehouse boxes", cta = "BROWSE", col = T.CREDIT or GOLD, packs = true },
				{ tab = "dust", title = "Stardust Shop", sub = "New packs every 6 hours · limited stock", cta = "SHOP", col = T.DUST or GEM, icons = { "stardust" } },
				{ tab = "limited", title = "Lucky Blocks", sub = "Tap to open · grade them up for bigger loot", cta = "SEE", col = Color3.fromRGB(255, 200, 70), icons = { "lucky_block", "super_lucky_block", "godly_lucky_block" } },
				{ tab = "box", title = "Build a Box", sub = "Any 10 packs you like · 12% off", cta = "BUILD", col = TEAL, icons = { "chest" } },
				{ tab = "currencies", title = "Credits", sub = "Top up once, spend anywhere in the shop", cta = "TOP UP", col = GREEN, icons = { "credit_crate" } },
				{ tab = "vip", title = "VIP & Founders", sub = "Remote sell, AFK earnings, Founders bag", cta = "VIEW", col = AMBER, icons = { "logo" } },
				{ tools = true, title = "Tools & Backpacks", sub = "The blacksmith's counter", cta = "OPEN", col = T.GOLD or GOLD, icons = { "pickaxe", "backpack" } },
			}
			for i, d in ipairs(doors) do
				if matches(d.title .. " " .. d.sub) then
					local tile = mk("TextButton", { AutoButtonColor = true, Text = "", BackgroundColor3 = Color3.new(1, 1, 1),
						LayoutOrder = i }, grid)
					round(tile, 12)
					stroke(tile, 2, d.col)
					mk("UIGradient", { Rotation = 0, Color = ColorSequence.new(d.col:Lerp(BG2, 0.72), BG2) }, tile)
					local art = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 10),
						Size = UDim2.new(0, 108, 1, -20), ZIndex = 4 }, tile)
					if d.packs then
						packFan(art, showcase, 46, 64)
					elseif d.icons and #d.icons > 1 then
						for j, key in ipairs(d.icons) do
							iconArt(art, key, 56, (j - (#d.icons + 1) / 2) * 30, (j % 2 == 0) and -8 or 6, 4 + j)
						end
					elseif d.icons then
						iconArt(art, d.icons[1], 84, 0, 0, 5)
					end
					label(tile, d.title, 20, TEXT, UDim2.fromOffset(128, 16), UDim2.new(1, -140, 0, 26), FONT).ZIndex = 5
					local sub = label(tile, d.sub, 13, MUTED, UDim2.fromOffset(128, 44), UDim2.new(1, -140, 0, 34))
					sub.ZIndex = 5
					sub.TextWrapped = true
					sub.TextTruncate = Enum.TextTruncate.None
					local cta = mk("Frame", { BackgroundColor3 = d.col, AnchorPoint = Vector2.new(1, 1),
						Position = UDim2.new(1, -12, 1, -12), Size = UDim2.fromOffset(96, 32), ZIndex = 5 }, tile)
					round(cta, 10)
					label(cta, d.cta, 14, Color3.fromRGB(24, 18, 12), UDim2.fromScale(0, 0), UDim2.fromScale(1, 1),
						FONT, Enum.TextXAlignment.Center).ZIndex = 6
					tile.MouseButton1Click:Connect(function()
						if d.tools then
							if opts.onShop then opts.onShop() end
						else
							activeTab = d.tab
							render()
						end
					end)
				end
			end

		elseif activeTab == "dust" then
			--[[
				THE STARDUST SHOP. Eight packs a rotation, a new shelf every six
				hours. Two stocks per pack: yours (1-2) and the whole world's
				(shared by every server). Both are the server's numbers.
			]]
			local shop = state.dustShop or { offers = {} }
			local DUSTC = T.DUST or GEM
			local head = mk("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(1, -6, 0, 84), LayoutOrder = 0 }, body)
			round(head, 12)
			stroke(head, 2, DUSTC)
			mk("UIGradient", { Rotation = 0, Color = ColorSequence.new(DUSTC:Lerp(BG2, 0.7), BG2) }, head)
			local dimg = Icons.image and Icons.image("stardust")
			if dimg then
				mk("ImageLabel", { BackgroundTransparency = 1, Image = dimg, ScaleType = Enum.ScaleType.Fit,
					Position = UDim2.fromOffset(14, 12), Size = UDim2.fromOffset(60, 60), ZIndex = 4 }, head)
			end
			label(head, "STARDUST SHOP", 22, TEXT, UDim2.fromOffset(86, 12), UDim2.new(1, -300, 0, 28), FONT).ZIndex = 4
			local left = math.max(0, (tonumber(shop.endsAt) or os.time()) - os.time())
			label(head, string.format("New shelf in %dh %02dm  ·  packs + potions  ·  limited stock", left // 3600, (left % 3600) // 60),
				13, MUTED, UDim2.fromOffset(86, 44), UDim2.new(1, -300, 0, 20)).ZIndex = 4
			local bal = mk("Frame", { BackgroundColor3 = BG3, AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(190, 44), ZIndex = 4 }, head)
			round(bal, 10)
			label(bal, "YOU HAVE", 10, MUTED, UDim2.fromOffset(12, 4), UDim2.new(1, -24, 0, 14), FONT).ZIndex = 5
			label(bal, shortNum(state.dust or 0) .. " stardust", 17, DUSTC, UDim2.fromOffset(12, 18),
				UDim2.new(1, -24, 0, 22), FONT).ZIndex = 5

			if #(shop.offers or {}) == 0 then
				note(body, "The shelf is being restocked -- check back in a moment.", 1)
			else
				local grid = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 }, body)
				mk("UIGridLayout", { CellPadding = UDim2.fromOffset(10, 10), CellSize = UDim2.fromOffset(176, 262),
					SortOrder = Enum.SortOrder.LayoutOrder }, grid)
				for i, o in ipairs(shop.offers) do
					local isPot = (o.kind == "potion")
					local def = (not isPot) and Packs.PACK_BY_ID and Packs.PACK_BY_ID[o.id]
					local name = o.name or (def and def.name) or tostring(o.id)
					if matches(name) then
						local accent = (not isPot) and PackFX.art(o.id).accent or DUSTC
						local worldOut = (tonumber(o.globalLeft) or 0) <= 0
						local mineOut = (tonumber(o.youLeft) or 0) <= 0
						local tile = mk("Frame", { BackgroundColor3 = BG2, LayoutOrder = i }, grid)
						round(tile, 12)
						stroke(tile, 2, (worldOut or mineOut) and Color3.fromRGB(90, 80, 72) or accent)
						local artHost = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0),
							Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(64, 88), ZIndex = 3 }, tile)
						if isPot then
							label(artHost, "POT", 18, DUSTC, UDim2.fromOffset(0, 30), UDim2.new(1, 0, 0, 28), FONT, Enum.TextXAlignment.Center).ZIndex = 4
						else
							pcall(PackFX.drawSealed, artHost, o.id, 64, 88)
						end
						starRow(tile, o.stars or (Packs.packStars and Packs.packStars(o.id)) or 3, 102, 12)
						label(tile, name, 14, TEXT, UDim2.fromOffset(6, 118), UDim2.new(1, -12, 0, 18), FONT,
							Enum.TextXAlignment.Center)
						local sub = isPot and "potion" or ((Packs.packCards and Packs.packCards(o.id) or 0) .. " cards")
						label(tile, sub, 12, MUTED, UDim2.fromOffset(6, 136), UDim2.new(1, -12, 0, 16), nil,
							Enum.TextXAlignment.Center)
						label(tile, string.format("You: %d / %d left", o.youLeft or 0, o.youMax or 0), 12,
							mineOut and (T.RED or MUTED) or MUTED, UDim2.fromOffset(6, 156), UDim2.new(1, -12, 0, 16), nil,
							Enum.TextXAlignment.Center)
						label(tile, worldOut and "SOLD OUT WORLDWIDE" or (commas(o.globalLeft) .. " left worldwide"), 12,
							worldOut and (T.RED or MUTED) or DUSTC, UDim2.fromOffset(6, 174), UDim2.new(1, -12, 0, 16), FONT,
							Enum.TextXAlignment.Center)
						local function buyBtn(qty, y)
							local can = not worldOut and (o.youLeft or 0) >= qty and (o.globalLeft or 0) >= qty
								and (state.dust or 0) >= (o.price or 0) * qty
							local btn = mk("TextButton", {
								AutoButtonColor = can,
								BackgroundColor3 = can and DUSTC or BG3,
								Font = FONT, TextSize = 14,
								TextColor3 = can and Color3.fromRGB(30, 16, 44) or MUTED,
								Text = string.format("BUY %d  ·  %s", qty, shortNum((o.price or 0) * qty)),
								Position = UDim2.fromOffset(10, y), Size = UDim2.new(1, -20, 0, 30),
							}, tile)
							round(btn, 8)
							if can then
								btn.MouseButton1Click:Connect(function()
									if opts.onBuyDustPack then
										opts.onBuyDustPack(o.id, qty)
									end
								end)
							end
						end
						buyBtn(1, 194)
						buyBtn(5, 228)
					end
				end
			end
		elseif activeTab == "box" then
			note(body, "Build your own booster box — choose up to 10 packs. 12% off the singles list.", 0)
			local filled = #boxPicks
			local slotBar = panelRow(body, 44, 1)
			label(slotBar, "BOX  " .. filled .. " / 10", 16, TEXT, UDim2.fromOffset(14, 10), UDim2.new(0.5, 0, 0, 24), FONT)
			local clearB = mk("TextButton", {
				AutoButtonColor = true, BackgroundColor3 = BG3, Font = FONT, TextSize = 13,
				TextColor3 = MUTED, Text = "CLEAR",
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(72, 28),
			}, slotBar)
			round(clearB, 7)
			clearB.MouseButton1Click:Connect(function()
				boxPicks = {}
				render()
			end)

			local sub = 0
			for _, pid in ipairs(boxPicks) do
				sub += Packs.priceOf(pid) or 0
			end
			local boxPay = math.floor(sub * 0.88 + 0.5)
			local payRow = panelRow(body, 56, 2)
			label(payRow, filled == 0 and "Add packs below" or ("List " .. shortNum(sub) .. "  →  box " .. shortNum(boxPay)),
				14, T.CREDIT or GOLD, UDim2.fromOffset(14, 8), UDim2.new(1, -160, 0, 20), FONT)
			label(payRow, "save " .. math.max(0, sub - boxPay) .. " credits", 12, GREEN,
				UDim2.fromOffset(14, 30), UDim2.new(1, -160, 0, 16))
			local addBox = mk("TextButton", {
				AutoButtonColor = true,
				BackgroundColor3 = (#boxPicks > 0) and (T.CREDIT or GOLD) or BG3,
				Font = FONT, TextSize = 14,
				TextColor3 = (#boxPicks > 0) and Color3.fromRGB(26, 20, 40) or MUTED,
				Text = "ADD BOX",
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(110, 36),
			}, payRow)
			round(addBox, 8)
			addBox.MouseButton1Click:Connect(function()
				if #boxPicks == 0 then return end
				local copy = {}
				for _, pid in ipairs(boxPicks) do
					table.insert(copy, pid)
				end
				cartAdd("box", "custom", false, 1, copy)
				boxPicks = {}
				if opts.onToast then opts.onToast("Box added to cart (12% off)") end
				render()
			end)

			local grid = mk("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -6, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 3,
			}, body)
			mk("UIGridLayout", {
				CellPadding = UDim2.fromOffset(8, 8),
				CellSize = UDim2.fromOffset(156, 168),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, grid)
			-- Card packs only, same as the Packs tab: a booster box of rune
			-- pouches is not a booster box.
			local rows = {}
			for _, def in ipairs(Packs.PACKS or {}) do
				if Packs.priceOf(def.id) and (not Packs.packKind or Packs.packKind(def.id) == "card") then
					table.insert(rows, def)
				end
			end
			table.sort(rows, function(a, b)
				return (Packs.priceOf(a.id) or 0) < (Packs.priceOf(b.id) or 0)
			end)
			for i, def in ipairs(rows) do
				if matches(def.name or def.id) then
					local unit = Packs.priceOf(def.id)
					local tierCol = PackFX.art(def.id).accent
					local tile = mk("Frame", { BackgroundColor3 = BG2, LayoutOrder = i }, grid)
					round(tile, 8)
					stroke(tile, 1.5, tierCol)
					local artHost = mk("Frame", {
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.new(0.5, 0, 0, 8),
						Size = UDim2.fromOffset(44, 60), ZIndex = 3,
					}, tile)
					PackFX.drawSealed(artHost, def.id, 44, 60)
					starRow(tile, Packs.packStars and Packs.packStars(def.id) or 3, 72, 12)
					label(tile, def.name or def.id, 13, TEXT, UDim2.fromOffset(6, 88), UDim2.new(1, -12, 0, 18), FONT).TextXAlignment = Enum.TextXAlignment.Center
					local add = mk("TextButton", {
						AutoButtonColor = true, BackgroundColor3 = BG3,
						Font = FONT, TextSize = 13, TextColor3 = TEXT,
						Text = shortNum(unit) .. "  +",
						Position = UDim2.fromOffset(10, 118), Size = UDim2.new(1, -20, 0, 32),
					}, tile)
					round(add, 7)
					stroke(add, 1, tierCol)
					add.MouseButton1Click:Connect(function()
						if #boxPicks >= 10 then
							if opts.onToast then opts.onToast("Box is full (10)") end
							return
						end
						table.insert(boxPicks, def.id)
						render()
					end)
				end
			end

		elseif activeTab == "limited" then
			local AMBER = Color3.fromRGB(255, 176, 64)
			local LuckyBlocks = nil
			pcall(function() LuckyBlocks = require(shared:WaitForChild("MineLuckyBlocks")) end)
			note(body, "Same face in credits or Robux. Bigger credit packs add bonus credits — that is the deal.", 0)

			-- Scheduled deals. Two or three live. The OP ones say they never return.
			local order = 0
			if RotatingOffers then
				local live = RotatingOffers.active()
				sectionHeader("LIMITED DEALS  —  " .. tostring(#live) .. " UP  ·  " .. tostring(RotatingOffers.dayKey()), order)
				for _, offer in ipairs(live) do
					order += 1
					local face = tonumber(offer.credits) or 0
					local tall = offer.neverReturns and 112 or 86
					local row = panelRow(body, tall, order)
					local edge = offer.neverReturns and Color3.fromRGB(255, 72, 96) or AMBER
					stroke(row, offer.neverReturns and 2 or 1.5, edge)
					local tx = 14
					if offer.icon and Icons and Icons.image and Icons.image(offer.icon) then
						iconArt(row, offer.icon, 48, 12, 12, 4)
						tx = 70
					end
					label(row, offer.title or offer.id, 16, GOLD, UDim2.fromOffset(tx, 8), UDim2.new(1, -(tx + 120), 0, 22), FONT)
					local sub = label(row, offer.blurb or "", 12, MUTED, UDim2.fromOffset(tx, 32), UDim2.new(1, -(tx + 120), 0, offer.neverReturns and 52 or 28))
					sub.TextWrapped = true
					local left = math.max(0, (tonumber(offer.ends) or 0) - os.time())
					local when = string.format("ends %dd %dh", math.floor(left / 86400), math.floor((left % 86400) / 3600))
					if offer.max then
						when ..= "  ·  max " .. tostring(offer.max)
					end
					if offer.neverReturns then
						when = "LIMITED TIME · NEVER COMING BACK  ·  " .. when
					end
					label(row, when, 11, offer.neverReturns and Color3.fromRGB(255, 140, 150) or MUTED,
						UDim2.fromOffset(tx, tall - 22), UDim2.new(1, -(tx + 120), 0, 16))
					local buyCr = mk("TextButton", {
						AutoButtonColor = true,
						BackgroundColor3 = T.CREDIT or GOLD,
						Font = FONT, TextSize = 13,
						TextColor3 = Color3.fromRGB(26, 20, 40),
						Text = tostring(face) .. " CR",
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(100, 32),
					}, row)
					round(buyCr, 8)
					buyCr.MouseButton1Click:Connect(function()
						if opts.onBuyProductCredits then
							opts.onBuyProductCredits(offer.key or offer.id)
						elseif opts.onToast then
							opts.onToast("Credits buy not wired")
						end
					end)
				end
			end

			-- 10× lucky blocks LTO
			if LuckyBlocks and LuckyBlocks.BUNDLE_10 then
				order += 1
				local b = LuckyBlocks.BUNDLE_10
				local row = panelRow(body, 72, order)
				stroke(row, 2, Color3.fromRGB(255, 196, 64))
				label(row, b.label or "10× Lucky Blocks", 16, Color3.fromRGB(255, 196, 64),
					UDim2.fromOffset(14, 10), UDim2.new(1, -160, 0, 22), FONT)
				label(row, b.blurb or "", 12, MUTED, UDim2.fromOffset(14, 36), UDim2.new(1, -160, 0, 24))
				local buy = mk("TextButton", {
					AutoButtonColor = true, BackgroundColor3 = T.CREDIT or GOLD,
					Font = FONT, TextSize = 13, TextColor3 = Color3.fromRGB(26, 20, 40),
					Text = "",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(120, 36),
				}, row)
				round(buy, 8)
				paintCostButton(buy, "ADD", b.credits, "credits", Color3.fromRGB(26, 20, 40))
				buy.MouseButton1Click:Connect(function()
					cartAdd("lucky_block", b.id, true, 1)
				end)
			end

			order += 1
			sectionHeader("LUCKY CUBES  —  pay with Credits", order)
			for _, rowDef in ipairs((LuckyBlocks and LuckyBlocks.SHOP) or {}) do
				order += 1
				local def = LuckyBlocks.TYPES[rowDef.id]
				local row = panelRow(body, 68, order)
				local col = (def and def.color) or GOLD
				stroke(row, 1.5, col)
				local title = rowDef.label or (def and def.name) or rowDef.id
				label(row, title, 15, col, UDim2.fromOffset(14, 10), UDim2.new(1, -160, 0, 22), FONT)
				label(row, rowDef.blurb or (def and def.blurb) or "", 12, MUTED,
					UDim2.fromOffset(14, 36), UDim2.new(1, -160, 0, 22))
				if LuckyBlocks.blockStars then
					local stars = starRow(row, LuckyBlocks.blockStars(rowDef.id, "F"), 8, 13)
					stars.AnchorPoint = Vector2.new(1, 0)
					stars.Position = UDim2.new(1, -140, 0, 24)
				end
				local buy = mk("TextButton", {
					AutoButtonColor = true, BackgroundColor3 = BG3,
					Font = FONT, TextSize = 13, TextColor3 = TEXT, Text = "",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(110, 34),
				}, row)
				round(buy, 7)
				stroke(buy, 1, col)
				paintCostButton(buy, "ADD", rowDef.credits, "credits", TEXT)
				buy.MouseButton1Click:Connect(function()
					cartAdd("lucky_block", rowDef.id, false, 1)
				end)
			end

		elseif activeTab == "packs" then
			--[[
				PACKS ARE SOLD NOW.

				This tab used to open with "Packs are not sold" and then list
				tier names with no price and nothing to press. A store whose
				first line tells you it has nothing for you is worse than no
				store.

				The ten-pack leads. Selling singles at full price and calling it
				a shop is how you end up with a storefront nobody opens twice --
				the warehouse pack is the reason to come back.
			]]
			--[[
				THE HERO.

				One featured bundle at a time, rotating every seven seconds.
				Seven is deliberate: long enough to read the pack, the price and
				the saving without feeling parked, short enough that a player who
				looks away and back sees something new.

				The loop is tied to the frame's lifetime rather than to a stored
				handle -- when a render throws the body away the frame loses its
				parent and the task exits on its next tick. `heroToken` kills any
				older loop immediately, so two renders in quick succession cannot
				leave two rotators fighting over the same frame.
			]]
			do
				local hero = mk("Frame", {
					Name = "Hero",
					BackgroundColor3 = BG2,
					Size = UDim2.new(1, -6, 0, 132),
					LayoutOrder = 0,
				}, body)
				round(hero, 10)

				local artHost = mk("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(18, 16),
					Size = UDim2.fromOffset(72, 100),
					ZIndex = 3,
				}, hero)

				local kicker = label(hero, "FEATURED", 11, MUTED,
					UDim2.fromOffset(108, 16), UDim2.new(1, -260, 0, 14), FONT)
				kicker.TextXAlignment = Enum.TextXAlignment.Left
				local nameL = label(hero, "", 22, TEXT,
					UDim2.fromOffset(108, 32), UDim2.new(1, -260, 0, 26), FONT)
				nameL.TextXAlignment = Enum.TextXAlignment.Left
				local blurbL = label(hero, "", 13, MUTED,
					UDim2.fromOffset(108, 60), UDim2.new(1, -260, 0, 18))
				blurbL.TextXAlignment = Enum.TextXAlignment.Left
				local saveL = label(hero, "", 13, GREEN,
					UDim2.fromOffset(108, 82), UDim2.new(1, -260, 0, 18), FONT)
				saveL.TextXAlignment = Enum.TextXAlignment.Left

				local cta = mk("TextButton", {
					AutoButtonColor = true,
					BackgroundColor3 = T.CREDIT or GOLD,
					Font = FONT, TextSize = 16,
					TextColor3 = Color3.fromRGB(26, 20, 40),
					Text = "",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -18, 0.5, 0),
					Size = UDim2.fromOffset(190, 46),
					ZIndex = 3,
				}, hero)
				round(cta, 10)

				local dots = mk("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(1, -18, 1, -10),
					Size = UDim2.fromOffset(#FEATURED * 14, 8),
					ZIndex = 3,
				}, hero)

				local current
				local function paintHero()
					local id = FEATURED[heroAt] or FEATURED[1]
					current = id
					local def = Packs.PACK_BY_ID[id]
					local unit = Packs.priceOf(id)
					local bundle = Packs.bundlePrice(id)
					if not def or not unit then
						hero.Visible = false
						return
					end
					hero.Visible = true
					for _, c in ipairs(artHost:GetChildren()) do
						c:Destroy()
					end
					PackFX.drawSealed(artHost, id, 72, 100)
					local accent = PackFX.art(id).accent
					stroke(hero, 2, accent)
					nameL.Text = (def.name or id) .. "   10x"
					nameL.TextColor3 = accent
					local heroStars = (Packs.starLabel and Packs.starLabel(id)) or "3★"
					-- Shiny is a card finish, so the second half of this line is only
					-- true for card packs. A gear bundle says what it actually is.
					local heroUnit = Packs.unitWord and Packs.unitWord(id, (def.cards or 0) * 10) or "cards"
					blurbL.Text = heroStars .. "   ·   " .. ((def.cards or 0) * 10) .. " " .. heroUnit
						.. ((Packs.hasShiny and not Packs.hasShiny(id))
							and ""
							or ("  --  " .. (def.shiny or 0) .. "% shiny per card"))
					saveL.Text = "save " .. (unit * 10 - bundle) .. " credits on the list price"
					paintCostButton(cta, "ADD 10x", bundle, "credits", Color3.fromRGB(26, 20, 40))
					for _, c in ipairs(dots:GetChildren()) do
						c:Destroy()
					end
					for i = 1, #FEATURED do
						local d = mk("Frame", {
							BackgroundColor3 = (i == heroAt) and accent or BG3,
							Position = UDim2.fromOffset((i - 1) * 14, 0),
							Size = UDim2.fromOffset(8, 8),
							ZIndex = 4,
						}, dots)
						round(d, 4)
					end
				end

				cta.MouseButton1Click:Connect(function()
					if current then
						cartAdd("pack", current, true, 1)
					end
				end)

				paintHero()
				heroToken += 1
				local myToken = heroToken
				task.spawn(function()
					while true do
						task.wait(7)
						if not hero.Parent or heroToken ~= myToken then
							return
						end
						heroAt = (heroAt % #FEATURED) + 1
						paintHero()
					end
				end)
			end

			note(body, "Warehouse packs  --  pay with Credits, 10% off at checkout.", 1)

			local grid = mk("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -6, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 2,
			}, body)
			mk("UIGridLayout", {
				CellPadding = UDim2.fromOffset(8, 8),
				CellSize = UDim2.fromOffset(176, 250),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, grid)

			-- Card packs only. Rune pouches and gear crates are rolled at the
			-- Enchanter, and listing them here sold the same thing twice in two
			-- different currencies.
			local rows = {}
			for _, def in ipairs(Packs.PACKS or {}) do
				if Packs.priceOf(def.id) and (not Packs.packKind or Packs.packKind(def.id) == "card") then
					table.insert(rows, def)
				end
			end
			-- Cheapest first: a price list that opens on the 220-credit pack
			-- reads as expensive, the same list opening on 35 reads as generous.
			table.sort(rows, function(x, y)
				local px, py = Packs.priceOf(x.id), Packs.priceOf(y.id)
				if px ~= py then
					return px < py
				end
				return tostring(x.name) < tostring(y.name)
			end)

			for i, def in ipairs(rows) do
				if matches(def.name or def.id) then
					local unit = Packs.priceOf(def.id)
					local bundle = Packs.bundlePrice(def.id)
					local tierCol = PackFX.art(def.id).accent
					local tile = mk("Frame", { BackgroundColor3 = BG2, LayoutOrder = i }, grid)
					round(tile, 8)
					stroke(tile, 1.5, tierCol)
					local cap2 = mk("Frame", { BackgroundColor3 = tierCol, Size = UDim2.new(1, 0, 0, 6) }, tile)
					round(cap2, 3)
					local artHost = mk("Frame", {
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.new(0.5, 0, 0, 14),
						Size = UDim2.fromOffset(54, 74),
						ZIndex = 3,
					}, tile)
					PackFX.drawSealed(artHost, def.id, 54, 74)

					starRow(tile, Packs.packStars and Packs.packStars(def.id) or 3, 88, 14)

					local nameL = label(tile, def.name or def.id, 15, TEXT,
						UDim2.fromOffset(8, 104), UDim2.new(1, -16, 0, 20), FONT)
					nameL.TextXAlignment = Enum.TextXAlignment.Center
					nameL.TextTruncate = Enum.TextTruncate.AtEnd
					local cardsL = label(tile, ((def.cards or 0) .. " "
			.. (Packs.unitWord and Packs.unitWord(def.id, def.cards) or "cards")),
						12, tierCol, UDim2.fromOffset(8, 124), UDim2.new(1, -16, 0, 16), FONT)
					cardsL.TextXAlignment = Enum.TextXAlignment.Center

					infoBadge(tile, {
						packId = def.id, tierName = def.name or def.id, setName = "",
						cards = def.cards or 0, count = 0, firstIndex = nil,
						setId = "dragons_dawn",
					})

					local one = mk("TextButton", {
						AutoButtonColor = true, BackgroundColor3 = BG3,
						Font = FONT, TextSize = 14, TextColor3 = TEXT,
						Text = "",
						Position = UDim2.fromOffset(10, 148), Size = UDim2.new(1, -20, 0, 34),
					}, tile)
					round(one, 7)
					stroke(one, 1, tierCol)
					paintCostButton(one, "BUY 1", unit, "credits", TEXT)
					one.MouseButton1Click:Connect(function()
						cartAdd("pack", def.id, false, 1)
					end)

					local ten = mk("TextButton", {
						AutoButtonColor = true, BackgroundColor3 = T.CREDIT or GOLD,
						Font = FONT, TextSize = 14, TextColor3 = Color3.fromRGB(26, 20, 40),
						Text = "",
						Position = UDim2.fromOffset(10, 186), Size = UDim2.new(1, -20, 0, 34),
					}, tile)
					round(ten, 7)
					paintCostButton(ten, "10x", bundle, "credits", Color3.fromRGB(26, 20, 40))
					ten.MouseButton1Click:Connect(function()
						cartAdd("pack", def.id, true, 1)
					end)
					-- Say what the bundle saves, in the only unit that matters.
					local saveL = label(tile, "save " .. (unit * 10 - bundle) .. " credits", 11,
						GREEN, UDim2.fromOffset(8, 222), UDim2.new(1, -16, 0, 14))
					saveL.TextXAlignment = Enum.TextXAlignment.Center
				end
			end

		elseif activeTab == "currencies" then
			note(body, "Credits = Robux face on passes. Bigger packs add bonus credits — buy bulk, then spend.", 0)

			--[[
				Robux buys Credits here and nothing else. Packs are bought with
				Credits, one step removed from real money -- see "Item I: odds
				disclosure" in TODO.md for why that separation is load-bearing
				and what would change if a random item were ever priced in Robux.
			]]
			local order = 1
			local Scrolls = require(shared:WaitForChild("MineScrolls"))
			for _, packDef in ipairs(state.creditPacks or {}) do
				order += 1
				local row = panelRow(body, 72, order)
				-- Dev-product style cap: round icon badge per SKU
				local cap = mk("Frame", {
					BackgroundColor3 = Color3.fromRGB(28, 34, 48),
					Size = UDim2.fromOffset(56, 56),
					Position = UDim2.fromOffset(8, 8),
				}, row)
				round(cap, 28)
				local iconId = (Scrolls.creditPackIcon and Scrolls.creditPackIcon(packDef))
					or packDef.iconImage
					or ""
				if iconId ~= "" then
					mk("ImageLabel", {
						BackgroundTransparency = 1,
						Image = iconId,
						Size = UDim2.fromOffset(44, 44),
						Position = UDim2.fromOffset(6, 6),
						ScaleType = Enum.ScaleType.Fit,
					}, cap)
				end
				label(row, (packDef.label or packDef.id) .. "   " .. shortNum(packDef.credits or 0) .. " credits",
					15, T.CREDIT or GOLD, UDim2.fromOffset(74, 12), UDim2.new(1, -200, 0, 22), FONT)
				if packDef.tag then
					label(row, packDef.tag, 12, GREEN, UDim2.fromOffset(74, 38), UDim2.new(1, -200, 0, 16))
				end
				local buy = mk("TextButton", {
					AutoButtonColor = true, BackgroundColor3 = GREEN,
					Font = FONT, TextSize = 14, TextColor3 = Color3.fromRGB(10, 26, 16),
					Text = "R$ " .. tostring(packDef.robux or "?"),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(110, 34),
				}, row)
				round(buy, 7)
				buy.MouseButton1Click:Connect(function()
					local pid = tonumber(packDef.productId)
					local creditsAmt = tonumber(packDef.credits) or 0
					local robuxAmt = tonumber(packDef.robux) or 0
					if not pid or pid <= 0 then
						if opts.onToast then
							opts.onToast("Credit product not wired yet")
						end
						return
					end
					-- Immediate amount popup, then Robux prompt only after confirm.
					local sheet = showPurchaseSheet(
						string.format("%s credits", shortNum(creditsAmt))
					)
					if buySheet then
						buySheet.Size = UDim2.fromOffset(400, 300)
					end
					for _, ch in ipairs(buySheet and buySheet:GetDescendants() or {}) do
						if ch:IsA("TextLabel") and (ch.Text == "Confirming with Credits" or ch.Text == "Pending") then
							ch.Text = string.format("R$ %d  →  %s credits", robuxAmt, shortNum(creditsAmt))
						end
						-- Hide progress until they confirm.
						if ch:IsA("Frame") and ch.Parent and ch.Parent.Name == "BuySheet"
							and ch.Size.Y.Offset == 10 then
							ch.Visible = false
						end
					end
					local confirm = mk("TextButton", {
						AutoButtonColor = true,
						BackgroundColor3 = GREEN,
						Font = FONT,
						TextSize = 16,
						TextColor3 = Color3.fromRGB(10, 26, 16),
						Text = "BUY WITH ROBUX",
						Active = true,
						AnchorPoint = Vector2.new(0.5, 1),
						Position = UDim2.new(0.5, 0, 1, -52),
						Size = UDim2.fromOffset(240, 44),
						ZIndex = 90,
					}, buySheet)
					round(confirm, 10)
					local cancel = mk("TextButton", {
						AutoButtonColor = true,
						BackgroundColor3 = BG3,
						Font = FONT,
						TextSize = 14,
						TextColor3 = MUTED,
						Text = "Cancel",
						Active = true,
						AnchorPoint = Vector2.new(0.5, 1),
						Position = UDim2.new(0.5, 0, 1, -12),
						Size = UDim2.fromOffset(120, 28),
						ZIndex = 90,
					}, buySheet)
					round(cancel, 8)
					cancel.MouseButton1Click:Connect(function()
						if buySheet then buySheet:Destroy() buySheet = nil end
						pending = nil
					end)
					confirm.MouseButton1Click:Connect(function()
						confirm.Visible = false
						cancel.Visible = false
						for _, ch in ipairs(buySheet and buySheet:GetDescendants() or {}) do
							if ch:IsA("TextLabel") and string.find(ch.Text, "→", 1, true) then
								ch.Text = "Pending"
							end
							if ch:IsA("Frame") and ch.Size.Y.Offset == 10 then
								ch.Visible = true
							end
						end
						sheet.sweep()
						pending = sheet
						local conn
						conn = MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
							if userId ~= LocalPlayer.UserId then return end
							if tonumber(productId) ~= pid then return end
							if conn then conn:Disconnect() end
							if pending ~= sheet then return end
							if isPurchased then
								task.delay(8, function()
									if pending == sheet then
										sheet.settle(true, shortNum(creditsAmt) .. " credits on the way")
										pending = nil
									end
								end)
							else
								sheet.settle(false, "Payment canceled")
								pending = nil
							end
						end)
						local okPrompt = pcall(function()
							MarketplaceService:PromptProductPurchase(LocalPlayer, pid)
						end)
						if not okPrompt then
							sheet.settle(false, "Could not open Robux prompt")
							pending = nil
						end
					end)
				end)
			end

			order += 1
			sectionHeader("SCROLLS  --  paid in Credits", order)
			for id, item in pairs(state.scrollShop or {}) do
				order += 1
				local row = panelRow(body, 62, order)
				label(row, item.name or id, 15, TEXT, UDim2.fromOffset(14, 8),
					UDim2.new(1, -240, 0, 20), FONT)
				local blurb = label(row, item.blurb or "", 11, MUTED,
					UDim2.fromOffset(14, 30), UDim2.new(1, -240, 0, 26))
				blurb.TextWrapped = true
				local addOne = mk("TextButton", {
					AutoButtonColor = true, BackgroundColor3 = BG3,
					Font = FONT, TextSize = 13, TextColor3 = TEXT,
					Text = "",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(110, 32),
				}, row)
				round(addOne, 7)
				stroke(addOne, 1, T.CREDIT or GOLD)
				paintCostButton(addOne, "ADD", vipCreditPrice(item.price), "credits", TEXT)
				addOne.MouseButton1Click:Connect(function()
					cartAdd("scroll", id, false, 1)
				end)
				if item.bundleQty then
					local addBundle = mk("TextButton", {
						AutoButtonColor = true, BackgroundColor3 = T.CREDIT or GOLD,
						Font = FONT, TextSize = 13, TextColor3 = Color3.fromRGB(26, 20, 40),
						Text = "",
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, -130, 0.5, 0), Size = UDim2.fromOffset(110, 32),
					}, row)
					round(addBundle, 7)
					paintCostButton(addBundle, item.bundleQty .. "x", vipCreditPrice(item.bundlePrice or item.price * item.bundleQty), "credits", Color3.fromRGB(26, 20, 40))
					addBundle.MouseButton1Click:Connect(function()
						cartAdd("scroll", id, true, 1)
					end)
				end
			end

			order += 1
			sectionHeader("EARNED IN THE MINE", order)
			order += 1
			local row = panelRow(body, 52, order)
			label(row, "Coins", 15, GOLD, UDim2.fromOffset(14, 6), UDim2.new(1, -28, 0, 20), FONT)
			label(row, shortNum(state.coins or 0) .. " held  --  mining and selling", 12, MUTED,
				UDim2.fromOffset(14, 28), UDim2.new(1, -28, 0, 18))
			order += 1
			local row2 = panelRow(body, 52, order)
			label(row2, "Gems", 15, GEM, UDim2.fromOffset(14, 6), UDim2.new(1, -28, 0, 20), FONT)
			label(row2, shortNum(state.gems or 0) .. " held  --  chests, and the charter spends them", 12, MUTED,
				UDim2.fromOffset(14, 28), UDim2.new(1, -28, 0, 18))
		else
			-- VIP tab (default when activeTab is vip / unknown shop tab)
			if activeTab == "vfx" then
				local Vfx = require(shared:WaitForChild("MineVfx"))
				note(body, "Limited vanity — nameplates, dig trails, shovel FX, and tags. Equip in Inventory → VFX.", 0)
				local owned = state.vfx or {}
				local order = 1
				for _, def in ipairs(Vfx.CATALOG or {}) do
					if matches(def.name .. " " .. tostring(def.kind)) then
						order += 1
						local row = panelRow(body, 64, order)
						local price = tonumber(def.priceCredits) or 0
						local have = owned[def.id] == true or price == 0
						label(row, def.name, 15, TEXT, UDim2.fromOffset(14, 8), UDim2.new(1, -140, 0, 22), FONT)
						label(row, (def.kind or "") .. (def.limited and " · limited" or (price == 0 and " · free" or "")),
							12, MUTED, UDim2.fromOffset(14, 32), UDim2.new(1, -140, 0, 18))
						local btn = mk("TextButton", {
							Text = have and "OWNED" or (price .. " CR"),
							Font = FONT,
							TextSize = 13,
							TextColor3 = Color3.fromRGB(20, 28, 40),
							BackgroundColor3 = have and Color3.fromRGB(90, 100, 120) or (T.CREDIT or GOLD),
							Size = UDim2.fromOffset(110, 36),
							Position = UDim2.new(1, -124, 0.5, -18),
							AutoButtonColor = not have and price > 0,
						}, row)
						round(btn, 8)
						if (not have) and price > 0 then
							btn.MouseButton1Click:Connect(function()
								if opts.onBuyVfx then opts.onBuyVfx(def.id) end
							end)
						end
					end
				end
			else
			local vipOwned = hasVipPass()
			do
				local card = panelRow(body, 120, 0)
				label(card, vipOwned and "VIP  -  OWNED" or "VIP PASS",
					18, vipOwned and GREEN or GOLD, UDim2.fromOffset(16, 10), UDim2.new(1, -40, 0, 24), FONT)
				-- No "extra pet seat": three is everybody's number now, so VIP does
				-- not add one and must not say it does.
				label(card, "Remote sell (75s)  |  +50% AFK coins  |  1 AFK gem/tick  |  [VIP] name",
					12, MUTED, UDim2.fromOffset(16, 38), UDim2.new(1, -40, 0, 36))
				if not vipOwned then
					local buy = mk("TextButton", {
						AutoButtonColor = true, BackgroundColor3 = GOLD, Font = FONT, TextSize = 14,
						TextColor3 = Color3.fromRGB(26, 20, 40), Text = "BUY VIP",
						AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -14),
						Size = UDim2.fromOffset(120, 36), ZIndex = 3,
					}, card)
					round(buy, 10)
					buy.MouseButton1Click:Connect(function()
						if opts.onBuyVipPass then opts.onBuyVipPass() end
					end)
				end
			end
			--[[
				FOUNDERS PACK.

				1000 credits / R$999. Vault is 1200 cr for R$749 — buy Vault, spend
				1000 here, keep ~200 credits of buying power.
			]]
			local member = isMember()
			local seats = tonumber(state.vipSeats) or 0
			local seatsTotal = tonumber(state.vipSeatsTotal) or 500
			local price = vipCreditPrice(tonumber(state.vipPrice) or tonumber(C.FOUNDERS_CREDITS) or 799)
			local robuxFace = tonumber(state.vipRobux) or tonumber(Packs.VIP_ROBUX) or tonumber(C.FOUNDERS_ROBUX) or 799

			local card = mk("Frame", {
				BackgroundColor3 = BG2,
				Size = UDim2.new(1, -6, 0, 168),
				LayoutOrder = 0,
			}, body)
			round(card, 12)
			stroke(card, 2, member and GOLD or (T.CREDIT or GOLD))
			local stripe = mk("Frame", {
				BackgroundColor3 = member and GOLD or (T.CREDIT or GOLD),
				Size = UDim2.new(1, 0, 0, 8),
			}, card)
			round(stripe, 4)
			local titleL = label(card, "FOUNDERS PACK", 22, TEXT,
				UDim2.fromOffset(20, 20), UDim2.new(1, -40, 0, 26), FONT)
			titleL.TextXAlignment = Enum.TextXAlignment.Left
			local stateL = label(card, member and "ACTIVE"
				or (price .. " credits  ·  R$ " .. robuxFace .. "  —  Vault leaves ~401 cr after this"),
				12, member and GREEN or MUTED,
				UDim2.fromOffset(20, 48), UDim2.new(1, -40, 0, 18), FONT)
			stateL.TextXAlignment = Enum.TextXAlignment.Left

			local track = mk("Frame", {
				BackgroundColor3 = BG3,
				Position = UDim2.fromOffset(20, 74),
				Size = UDim2.new(1, -40, 0, 10),
			}, card)
			round(track, 5)
			local frac = (seatsTotal > 0) and math.clamp(seats / seatsTotal, 0, 1) or 0
			local fill = mk("Frame", {
				BackgroundColor3 = (frac < 0.2) and (T.RED or GOLD) or GREEN,
				Size = UDim2.fromScale(frac, 1),
			}, track)
			round(fill, 5)
			local seatL = label(card, seats .. " / " .. seatsTotal .. " seats left on this server",
				12, MUTED, UDim2.fromOffset(20, 90), UDim2.new(1, -40, 0, 16))
			seatL.TextXAlignment = Enum.TextXAlignment.Left

			if not member then
				local canCr = seats > 0 and (state.credits or 0) >= price
				local joinCr = mk("TextButton", {
					AutoButtonColor = canCr,
					BackgroundColor3 = canCr and (T.CREDIT or GOLD) or BG3,
					Font = FONT, TextSize = 14,
					TextColor3 = canCr and Color3.fromRGB(26, 20, 40) or MUTED,
					Text = (seats <= 0) and "NO SEATS"
						or (((state.credits or 0) < price) and ("NEED " .. price .. " CR")
						or (price .. " CREDITS")),
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(1, -20, 1, -14),
					Size = UDim2.fromOffset(150, 40),
					ZIndex = 3,
				}, card)
				round(joinCr, 10)
				joinCr.MouseButton1Click:Connect(function()
					if canCr and opts.onJoinVip then opts.onJoinVip() end
					end)
				local joinRx = mk("TextButton", {
					AutoButtonColor = seats > 0,
					BackgroundColor3 = (seats > 0) and GOLD or BG3,
					Font = FONT, TextSize = 14,
					TextColor3 = (seats > 0) and Color3.fromRGB(26, 20, 40) or MUTED,
					Text = (seats <= 0) and "NO SEATS" or ("R$ " .. robuxFace),
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(1, -178, 1, -14),
					Size = UDim2.fromOffset(120, 40),
					ZIndex = 3,
				}, card)
				round(joinRx, 10)
				joinRx.MouseButton1Click:Connect(function()
					if seats <= 0 then return end
					if opts.onBuyFoundersRobux then
						opts.onBuyFoundersRobux()
					end
				end)
			end

			sectionHeader("WHAT IT GRANTS", 1)
			local grants = {
				{ "+5% Luck, always on",
				  "Stated. Packs, chests, and finds lean a little luckier." },
				{ "A White Scroll the moment you join",
				  "Arms a rune before a fuse -- on a fail, both runes survive." },
				{ "Founder Tag",
				  "Trumps [VIP] on your name. Switch either tag off in VFX." },
				{ "Founders Bag",
				  "Infinite haul. Equip it below if you also own Wormhole." },
			}
			for i, g in ipairs(grants) do
				local row = panelRow(body, 58, i + 1)
				label(row, g[1], 15, member and GOLD or TEXT,
					UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 20), FONT)
				label(row, g[2], 12, MUTED, UDim2.fromOffset(14, 30), UDim2.new(1, -28, 0, 18))
				end
			-- Bag equip lives on the paperdoll Bag seat, not in the shop list.
			end
		end
	end

	--[[
		Today: the streak reward, then the three repeatable quests.

		Both reset on the same UTC boundary as each other, which is why they
		share a screen -- "what is there to do today" is one question.
	]]
	local function renderDaily()
		local d = state.daily
		local qs = state.dailyQuests

		-- The streak reward.
		local head = panelRow(body, 88, 0)
		head.BackgroundColor3 = BG3
		label(head, "DAILY REWARD", 17, GOLD, UDim2.fromOffset(16, 12),
			UDim2.new(1, -180, 0, 22), FONT)
		if type(d) == "table" then
			label(head, "Day " .. tostring(d.day) .. " of " .. tostring(d.days)
				.. ((d.streak or 0) > 0 and ("   -   " .. d.streak .. " day streak") or ""),
				12, MUTED, UDim2.fromOffset(16, 36), UDim2.new(1, -180, 0, 16))
			label(head, tostring(d.text), 15, TEXT, UDim2.fromOffset(16, 56),
				UDim2.new(1, -180, 0, 20), FONT)
			local b = mk("TextButton", {
				AutoButtonColor = d.ready,
				BackgroundColor3 = d.ready and GOLD or BG,
				Font = FONT, TextSize = 14,
				TextColor3 = d.ready and T.ON_GOLD or MUTED,
				Text = d.ready and "CLAIM" or "Claimed today",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0.5, 0),
				Size = UDim2.fromOffset(150, 36),
				Active = d.ready,
			}, head)
			round(b, 8)
			if not d.ready then
				stroke(b, 1, T.LINE)
			end
			b.MouseButton1Click:Connect(function()
				if d.ready and opts.onClaimDaily then
					opts.onClaimDaily()
				end
			end)
		else
			label(head, "Loading.", 13, MUTED, UDim2.fromOffset(16, 40), UDim2.new(1, -32, 0, 18))
		end

		note(body, "TODAY'S QUESTS  -  they reset with the reward above", 1)

		if type(qs) ~= "table" or #qs == 0 then
			note(body, "No quests today.", 2)
		else
		for i, q in ipairs(qs) do
			local row = panelRow(body, 62, i + 1)
			if q.ready then
				stroke(row, 1.5, GOLD)
			end
			label(row, tostring(q.text), 15, q.claimed and MUTED or TEXT,
				UDim2.fromOffset(16, 10), UDim2.new(1, -200, 0, 20), FONT)
			-- Bar and counter, so "nearly there" is visible without arithmetic.
			local goal = math.max(q.goal or 1, 1)
			local cur = math.clamp(q.current or 0, 0, goal)
			local track = mk("Frame", {
				BackgroundColor3 = BG, BorderSizePixel = 0,
				Position = UDim2.fromOffset(16, 36), Size = UDim2.new(1, -210, 0, 10),
			}, row)
			round(track, 5)
			local fill = mk("Frame", {
				BackgroundColor3 = q.claimed and MUTED or GOLD, BorderSizePixel = 0,
				Size = UDim2.fromScale(cur / goal, 1),
			}, track)
			round(fill, 5)
			label(row, shortNum(cur) .. " / " .. shortNum(goal) .. "      " .. tostring(q.reward),
				11, MUTED, UDim2.fromOffset(16, 46), UDim2.new(1, -210, 0, 14))
			local b = mk("TextButton", {
				AutoButtonColor = q.ready,
				BackgroundColor3 = q.ready and GOLD or BG,
				Font = FONT, TextSize = 14,
				TextColor3 = q.ready and T.ON_GOLD or MUTED,
				Text = q.claimed and "Claimed" or (q.ready and "CLAIM" or "In progress"),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0.5, 0),
				Size = UDim2.fromOffset(150, 36),
				Active = q.ready,
			}, row)
			round(b, 8)
			if not q.ready then
				stroke(b, 1, q.claimed and GREEN or T.LINE)
			end
			b.MouseButton1Click:Connect(function()
				if q.ready and opts.onClaimDailyQuest then
					opts.onClaimDailyQuest(i)
				end
			end)
		end
		end

		-- Lifetime milestones (claimable anytime, not chain-gated).
		local ms = state.milestones
		if type(ms) == "table" and #ms > 0 then
			note(body, "MILESTONES  -  lifetime, claim when ready", 50)
			for i, m in ipairs(ms) do
				local row = panelRow(body, 56, 50 + i)
				if m.ready then
					stroke(row, 1.5, GOLD)
				end
				label(row, tostring(m.text), 14, m.claimed and MUTED or TEXT,
					UDim2.fromOffset(16, 8), UDim2.new(1, -180, 0, 18), FONT)
				label(row, shortNum(m.current or 0) .. " / " .. shortNum(m.goal or 0)
					.. "      " .. tostring(m.reward),
					11, MUTED, UDim2.fromOffset(16, 30), UDim2.new(1, -180, 0, 14))
				local b = mk("TextButton", {
					AutoButtonColor = m.ready,
					BackgroundColor3 = m.ready and GOLD or BG,
					Font = FONT, TextSize = 13,
					TextColor3 = m.ready and T.ON_GOLD or MUTED,
					Text = m.claimed and "Claimed" or (m.ready and "CLAIM" or "..."),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -16, 0.5, 0),
					Size = UDim2.fromOffset(120, 32),
					Active = m.ready,
				}, row)
				round(b, 8)
				if m.ready then
					b.MouseButton1Click:Connect(function()
						if opts.onClaimMilestone then
							opts.onClaimMilestone(m.id)
						end
					end)
				end
			end
		end
	end

	--[[
		The battle pass.

		Every number on this screen comes off the snapshot, which the server
		derives from stored XP -- the client never decides what tier you are or
		what you may claim. Claiming names a row and a track and nothing else.
	]]
	local function renderPass()
		local pass = state.pass
		if type(pass) ~= "table" then
			note(body, "The pass is loading.", 1)
			return
		end
		local tiers = pass.tiers or Scrolls.PASS_TIERS or 100
		local tier = math.clamp(pass.tier or 0, 0, tiers)
		local owned = pass.owned and true or false
		local LuckyBlocks = nil
		pcall(function() LuckyBlocks = require(shared:WaitForChild("MineLuckyBlocks")) end)

		-- Header: title row, live season clock row, progress row, (buy row).
		local HEAD_H = owned and 128 or 168
		local head = panelRow(body, HEAD_H, 0)
		head.BackgroundColor3 = BG3
		label(head, "BATTLE PASS", 20, GOLD, UDim2.fromOffset(16, 10),
			UDim2.new(1, -220, 0, 24), FONT)
		label(head, owned and "Premium unlocked" or "Free track  ·  claim Lunar at tier 1",
			12, owned and GREEN or MUTED, UDim2.fromOffset(16, 34), UDim2.new(1, -220, 0, 16))

		-- SEASON CLOCK. Big, centered, ticking every second off server time.
		local clockRow = mk("Frame", {
			Name = "SeasonClock",
			BackgroundColor3 = BG,
			Position = UDim2.fromOffset(16, 56),
			Size = UDim2.new(1, -32, 0, 34),
		}, head)
		round(clockRow, 10)
		stroke(clockRow, 1, GOLD, 0.55)
		label(clockRow, "SEASON ENDS IN", 10, MUTED, UDim2.fromOffset(12, 3),
			UDim2.new(1, -24, 0, 12), FONT, Enum.TextXAlignment.Center)
		local timerLbl = label(clockRow, Scrolls.formatPassClock(workspace:GetServerTimeNow()), 17, GOLD,
			UDim2.fromOffset(12, 13), UDim2.new(1, -24, 0, 20), FONT, Enum.TextXAlignment.Center)
		local endLbl = label(clockRow, "Oct 31 · 11:59 PM ET", 10, MUTED,
			UDim2.new(1, -150, 0, 11), UDim2.fromOffset(140, 14), nil, Enum.TextXAlignment.Right)
		endLbl.TextTransparency = 0.25
		passTimerGen = (passTimerGen or 0) + 1
		local timerGen = passTimerGen
		task.spawn(function()
			local pulse = false
			while timerGen == passTimerGen and timerLbl.Parent do
				local now = workspace:GetServerTimeNow()
				timerLbl.Text = Scrolls.formatPassClock(now)
				local left = Scrolls.passSecondsLeft(now)
				if left <= 0 then
					endLbl.Text = "Next season is live"
				elseif left < 86400 then
					-- Final day: pulse red so nobody misses the deadline.
					pulse = not pulse
					timerLbl.TextColor3 = pulse and Color3.fromRGB(255, 96, 96) or GOLD
				end
				task.wait(1)
			end
		end)

		local capped = (pass.dailyLeft or 0) <= 0
		local atEnd = tier >= tiers
		local bar = mk("Frame", {
			BackgroundColor3 = BG,
			Position = UDim2.fromOffset(16, 98),
			Size = UDim2.new(1, -32, 0, 12),
		}, head)
		round(bar, 6)
		local frac = atEnd and 1 or math.clamp((pass.intoTier or 0) / math.max(pass.perTier or 1, 1), 0, 1)
		local fill = mk("Frame", {
			BackgroundColor3 = capped and MUTED or GOLD,
			Size = UDim2.fromScale(frac, 1),
		}, bar)
		round(fill, 6)
		label(head, atEnd and ("Tier " .. tiers .. "  ·  season complete")
				or ("Tier " .. tier .. "   " .. (pass.intoTier or 0) .. " / " .. (pass.perTier or 0)
					.. " to " .. (tier + 1)),
			12, TEXT, UDim2.fromOffset(16, 112), UDim2.new(0.55, -16, 0, 16))
		label(head, (pass.dailyFromQuests and "Pass XP from quests")
				or (capped and "Daily cap — more tomorrow")
				or ((pass.dailyLeft or 0) .. " / " .. (pass.dailyCap or 0) .. " XP today"),
			11, (pass.dailyFromQuests and MUTED) or (capped and GOLD or MUTED), UDim2.new(0.55, 0, 0, 112), UDim2.new(0.45, -16, 0, 16),
			nil, Enum.TextXAlignment.Right)

		if not owned then
			local face = tonumber(Scrolls.BATTLE_PASS.credits) or tonumber(Scrolls.BATTLE_PASS.robux) or 399
			local buyCr = mk("TextButton", {
				AutoButtonColor = true,
				BackgroundColor3 = T.CREDIT or GOLD,
				Font = FONT,
				TextSize = 14,
				TextColor3 = Color3.fromRGB(26, 20, 40),
				Text = face .. " credits",
				Position = UDim2.fromOffset(16, 132),
				Size = UDim2.new(0.5, -22, 0, 28),
			}, head)
			round(buyCr, 8)
			buyCr.MouseButton1Click:Connect(function()
				if opts.onBuyPassCredits then opts.onBuyPassCredits() end
			end)
			local buyRx = mk("TextButton", {
				AutoButtonColor = true,
				BackgroundColor3 = GOLD,
				Font = FONT,
				TextSize = 14,
				TextColor3 = T.ON_GOLD or Color3.fromRGB(26, 20, 40),
				Text = "R$ " .. face,
				Position = UDim2.new(0.5, 6, 0, 132),
				Size = UDim2.new(0.5, -22, 0, 28),
			}, head)
			round(buyRx, 8)
			buyRx.MouseButton1Click:Connect(function()
				if opts.onBuyPass then opts.onBuyPass() end
			end)
		end

		-- The pass signature fuse (Lunar + Eclipse → Lunar Eclipse) used to hide
		-- on the retired Merge screen; it belongs to the pass itself.
		if opts.onFusePassTools then
			local fuse = mk("TextButton", {
				AutoButtonColor = true,
				BackgroundColor3 = BG,
				Font = FONT,
				TextSize = 13,
				TextColor3 = GOLD,
				Text = "Fuse Lunar + Eclipse",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -12, 0, 12),
				Size = UDim2.fromOffset(180, 30),
				ZIndex = 3,
			}, head)
			round(fuse, 8)
			stroke(fuse, 1, GOLD)
			fuse.MouseButton1Click:Connect(function()
				opts.onFusePassTools()
			end)
		end

		local ICON_COL = {
			lucky_block = Color3.fromRGB(255, 196, 64),
			super_lucky_block = Color3.fromRGB(64, 148, 255),
			godly_lucky_block = Color3.fromRGB(220, 48, 64),
			lunar_pick = Color3.fromRGB(200, 220, 255),
			bp_eclipse = Color3.fromRGB(160, 80, 255),
			lunar_eclipse = Color3.fromRGB(255, 180, 80),
			credits = Color3.fromRGB(80, 220, 140),
			gems = Color3.fromRGB(90, 180, 255),
			stardust = Color3.fromRGB(255, 160, 220),
			scroll = Color3.fromRGB(240, 230, 180),
			white = Color3.fromRGB(240, 230, 180),
			black = Color3.fromRGB(90, 36, 48),
			omni = Color3.fromRGB(232, 197, 106),
			battlepass = Color3.fromRGB(255, 214, 90),
		}

		local function rewardIcon(reward)
			if type(reward) ~= "table" then return "gift", MUTED end
			local id = reward.icon
			if not id and reward.toolId then id = reward.toolId end
			if not id and reward.luckyBlocks and reward.luckyBlocks[1] then id = reward.luckyBlocks[1].id end
			if not id and reward.credits then id = "credits" end
			if not id and reward.gems then id = "gems" end
			if not id and reward.dust then id = "stardust" end
			if not id and reward.scrolls then
				if reward.scrolls.omni then id = "omni"
				elseif reward.scrolls.black then id = "black"
				elseif reward.scrolls.white then id = "white"
				else
					for sid in pairs(reward.scrolls) do
						id = sid
						break
					end
				end
			end
			id = id or "gift"
			local col = ICON_COL[id] or GOLD
			if LuckyBlocks and LuckyBlocks.TYPES[id] then
				col = LuckyBlocks.TYPES[id].color or col
			end
			return id, col
		end

		local function shortIconLabel(id)
			if id == "lucky_block" then return "LB" end
			if id == "super_lucky_block" then return "SLB" end
			if id == "godly_lucky_block" then return "GLB" end
			if id == "lunar_pick" then return "LUN" end
			if id == "bp_eclipse" then return "ECL" end
			if id == "lunar_eclipse" then return "LE" end
			if id == "credits" then return "CR" end
			if id == "gems" then return "GEM" end
			if id == "stardust" then return "DST" end
			if id == "scroll" then return "SCR" end
			return "?"
		end

		--[[
			THE SHOWCASE RAIL.

			Two rows, one column per tier: free above, premium below, the tier
			number on a chip between them and a gold line that fills as the
			season advances. Tiles are built around ONE BIG ICON — the reward
			is the art, words come second. Rungs where the free track pays
			nothing (see MineScrolls FREE TRACK CADENCE) draw as dim slots so
			the columns stay aligned and premium visibly out-earns free.
		]]
		local DARK = Color3.fromRGB(13, 12, 18)
		local DARK2 = Color3.fromRGB(24, 22, 32)
		local TILE_W, TILE_H = 118, 152
		local COL_W = TILE_W + 14
		local FREE_Y = 12
		local MID_Y = FREE_Y + TILE_H + 8
		local MID_H = 40
		local PREM_Y = MID_Y + MID_H
		local railHost = mk("Frame", {
			BackgroundColor3 = DARK,
			Size = UDim2.new(1, -6, 0, PREM_Y + TILE_H + 16),
			LayoutOrder = 2,
		}, body)
		round(railHost, 12)
		local scroll = mk("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.fromOffset(tiers * COL_W + 32, 0),
			ScrollBarThickness = 8,
			ScrollingDirection = Enum.ScrollingDirection.X,
			AutomaticCanvasSize = Enum.AutomaticSize.None,
		}, railHost)

		-- Fixed row tags on the rail itself, so they read even mid-scroll.
		local function rowTag(text, y, col)
			local tag = mk("Frame", {
				BackgroundColor3 = DARK,
				BackgroundTransparency = 0.2,
				Position = UDim2.fromOffset(6, y),
				Size = UDim2.fromOffset(78, 20),
				ZIndex = 6,
			}, railHost)
			round(tag, 6)
			label(tag, text, 11, col, UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center).ZIndex = 7
		end
		rowTag("FREE", FREE_Y + 4, MUTED)
		rowTag("PREMIUM", PREM_Y + 4, owned and GOLD or MUTED)

		-- The season line: a track through the middle that fills to your tier.
		local line = mk("Frame", {
			BackgroundColor3 = DARK2,
			Position = UDim2.fromOffset(16, MID_Y + math.floor(MID_H / 2) - 2),
			Size = UDim2.fromOffset(tiers * COL_W, 4),
		}, scroll)
		round(line, 2)
		if tier > 0 then
			local lf = mk("Frame", {
				BackgroundColor3 = GOLD,
				Size = UDim2.new(0, math.clamp(tier, 0, tiers) * COL_W, 1, 0),
			}, line)
			round(lf, 2)
		end

		for n = 1, tiers do
			local x = 16 + (n - 1) * COL_W
			local reachedN = tier >= n
			local chip = mk("Frame", {
				BackgroundColor3 = reachedN and GOLD or DARK2,
				Position = UDim2.fromOffset(x + math.floor(TILE_W / 2) - 21, MID_Y + math.floor((MID_H - 24) / 2)),
				Size = UDim2.fromOffset(42, 24),
				ZIndex = 3,
			}, scroll)
			round(chip, 12)
			label(chip, tostring(n), 13, reachedN and Color3.fromRGB(24, 20, 12) or MUTED,
				UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center).ZIndex = 4
		end

		local function tile(n, reward, y, isPrem)
			local x = 16 + (n - 1) * COL_W
			if type(reward) ~= "table" then
				-- Free pays nothing on this rung. A dim slot keeps the column
				-- readable and quietly advertises the row below it.
				local slot = mk("Frame", {
					BackgroundColor3 = DARK2,
					BackgroundTransparency = 0.62,
					Position = UDim2.fromOffset(x, y),
					Size = UDim2.fromOffset(TILE_W, TILE_H),
				}, scroll)
				round(slot, 12)
				label(slot, "—", 16, MUTED, UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center)
				return
			end
			local reached = tier >= n
			local ledger = isPrem and (pass.prem or {}) or (pass.free or {})
			local claimed = passClaimed(isPrem, n)
				or ((ledger[n] or ledger[tostring(n)]) and true or false)
			local allowed = reached and not claimed and ((not isPrem) or owned)
			local iconId, col = rewardIcon(reward)
			local btn = mk("TextButton", {
				AutoButtonColor = allowed,
				BackgroundColor3 = DARK2,
				Text = "",
				Position = UDim2.fromOffset(x, y),
				Size = UDim2.fromOffset(TILE_W, TILE_H),
				Active = true,
			}, scroll)
			round(btn, 12)
			stroke(btn, allowed and 2.5 or 1.5,
				allowed and GREEN or ((n % 10 == 0) and GOLD or (reached and col or T.LINE)))

			-- ONE BIG ICON. The reward is the art.
			local plate = mk("Frame", {
				BackgroundColor3 = col:Lerp(DARK, 0.7),
				Position = UDim2.fromOffset(8, 8),
				Size = UDim2.fromOffset(TILE_W - 16, TILE_W - 16),
			}, btn)
			round(plate, 10)
			local imgId = Icons.image(iconId)
			if not imgId and LuckyBlocks and LuckyBlocks.TYPES[iconId] then
				local lb = LuckyBlocks.TYPES[iconId].icon
				if type(lb) == "string" and lb ~= "rbxassetid://0" then
					imgId = lb
				end
			end
			if type(imgId) == "string" and imgId ~= "rbxassetid://0" and #imgId > 14 then
				mk("ImageLabel", {
					BackgroundTransparency = 1,
					Image = imgId,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(0.88, 0.88),
					ScaleType = Enum.ScaleType.Fit,
				}, plate)
			else
				label(plate, shortIconLabel(iconId), 26, col,
					UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center)
			end

			local what = label(btn, Scrolls.describeReward(reward), 10, reached and TEXT or MUTED,
				UDim2.fromOffset(6, TILE_W - 4), UDim2.fromOffset(TILE_W - 12, 24), nil, Enum.TextXAlignment.Center)
			what.TextWrapped = true
			what.TextTruncate = Enum.TextTruncate.None

			-- Status strip along the bottom: the tile answers "can I press it".
			local strip = mk("Frame", {
				BackgroundColor3 = allowed and GREEN or DARK,
				BackgroundTransparency = allowed and 0 or 0.25,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 6, 1, -6),
				Size = UDim2.new(1, -12, 0, 22),
				ZIndex = 4,
			}, btn)
			round(strip, 8)
			local status = claimed and "CLAIMED" or (allowed and "CLAIM" or (isPrem and not owned and "LOCKED" or ("TIER " .. n)))
			label(strip, status, 12, allowed and Color3.fromRGB(12, 24, 16) or (claimed and GREEN or MUTED),
				UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center).ZIndex = 5

			if claimed then
				mk("Frame", {
					BackgroundColor3 = DARK,
					BackgroundTransparency = 0.5,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 3,
				}, btn)
			elseif isPrem and not owned then
				mk("Frame", {
					BackgroundColor3 = Color3.fromRGB(8, 8, 12),
					BackgroundTransparency = 0.45,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 3,
				}, btn)
			end

			btn.MouseButton1Click:Connect(function()
				if not allowed or not opts.onClaimPass then
					return
				end
				local now = os.clock()
				if (now - claimPassAt) < 0.75 then
					return
				end
				claimPassAt = now
				-- Sticky CLAIMED lives in passClaimMem so a later snapshot cannot
				-- pop CLAIM back onto a rung we already tapped this session.
				rememberPassClaim(isPrem, n, true)
				if type(state.pass) == "table" then
					local ledger = isPrem and (state.pass.prem or {}) or (state.pass.free or {})
					if isPrem then
						state.pass.prem = ledger
					else
						state.pass.free = ledger
					end
					ledger[n] = true
					ledger[tostring(n)] = true
				end
				opts.onClaimPass(n, isPrem and "premium" or "free")
				render()
			end)
		end

		for n = 1, tiers do
			local row = Scrolls.PASS_TRACK[n]
			if row then
				tile(n, row.free, FREE_Y, false)
				tile(n, row.premium, PREM_Y, true)
			end
		end

		-- Remember where they were scrolling. Only auto-jump to the current
		-- tier the first time the pass opens this session — never after a claim.
		scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			passScrollX = scroll.CanvasPosition.X
		end)
		task.defer(function()
			if not scroll.Parent then
				return
			end
			if passScrollX ~= nil then
				scroll.CanvasPosition = Vector2.new(passScrollX, 0)
			elseif not passScrollPrimed then
				local target = math.max(0, (math.max(tier, 1) - 2) * COL_W)
				scroll.CanvasPosition = Vector2.new(target, 0)
				passScrollX = target
			end
			passScrollPrimed = true
		end)
	end

	----------------------------------------------------------------------------
	local function renderAccount()
		-- Discord is an off-platform link: only shown where Roblox allows it
		-- for this player (the server sets PolicyDiscord on join).
		if game:GetService("Players").LocalPlayer:GetAttribute("PolicyDiscord") ~= true then
			local plain = panelRow(body, 80, 0)
			plain.BackgroundColor3 = BG3
			label(plain, "ACCOUNT", 17, GOLD, UDim2.fromOffset(16, 12), UDim2.new(1, -32, 0, 22), FONT)
			label(plain, "Nothing to link here.", 13, MUTED, UDim2.fromOffset(16, 42), UDim2.new(1, -32, 0, 20))
			return
		end
		local linked = state.discordLinked == true
		local bonusClaimed = state.discordBonusClaimed == true
		local discordId = tostring(state.discordId or "")
		local masked = ""
		if #discordId >= 4 then
			masked = string.rep("•", math.max(0, #discordId - 4)) .. string.sub(discordId, -4)
		elseif #discordId > 0 then
			masked = discordId
		end

		local head = panelRow(body, linked and 110 or 150, 0)
		head.BackgroundColor3 = BG3
		label(head, "ACCOUNT", 17, GOLD, UDim2.fromOffset(16, 12),
			UDim2.new(1, -32, 0, 22), FONT)

		if linked then
			label(head, "Discord connected" .. (masked ~= "" and ("  ·  " .. masked) or ""),
				14, TEXT, UDim2.fromOffset(16, 42), UDim2.new(1, -32, 0, 20), FONT)
			local bonusNote = bonusClaimed
				and "Link bonus claimed · player markets & remote trading unlocked"
				or "Markets unlocked · link bonus pending"
			label(head, bonusNote, 12, MUTED, UDim2.fromOffset(16, 68),
				UDim2.new(1, -32, 0, 28))
		else
			local blurb = label(head,
				"Connect Discord for 5,000 gems — plus player markets and remote trading.",
				14, TEXT, UDim2.fromOffset(16, 42), UDim2.new(1, -32, 0, 40), FONT)
			blurb.TextWrapped = true
			label(head, "In Discord type !link, then paste the code below.",
				12, MUTED, UDim2.fromOffset(16, 90), UDim2.new(1, -32, 0, 40))

			local row = panelRow(body, 72, 1)
			local box = mk("TextBox", {
				BackgroundColor3 = BG,
				Font = FONT,
				TextSize = 18,
				TextColor3 = TEXT,
				PlaceholderText = "CODE",
				PlaceholderColor3 = MUTED,
				Text = "",
				ClearTextOnFocus = false,
				Position = UDim2.fromOffset(14, 18),
				Size = UDim2.new(1, -160, 0, 36),
			}, row)
			round(box, 8)
			stroke(box, 1)

			local go = mk("TextButton", {
				AutoButtonColor = true,
				BackgroundColor3 = GOLD,
				Font = FONT,
				TextSize = 14,
				TextColor3 = Color3.fromRGB(24, 20, 12),
				Text = "Confirm",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(120, 36),
			}, row)
			round(go, 8)

			local function submit()
				local code = tostring(box.Text or ""):gsub("%s", "")
				if code == "" then
					return
				end
				if opts.onDiscordRedeemCode then
					opts.onDiscordRedeemCode(code)
				end
				box.Text = ""
			end
			go.MouseButton1Click:Connect(submit)
			box.FocusLost:Connect(function(enter)
				if enter then
					submit()
				end
			end)
		end
	end
	----------------------------------------------------------------------------
	local function sectionDef(id)
		for _, s in ipairs(SECTIONS) do
			if s.id == id then
				return s
			end
		end
		return SECTIONS[1]
	end

	render = function()
		local sec = sectionDef(section)
		titleLbl.Text = string.upper(sec.label)
		for id, b in pairs(railBtns) do
			local on = id == section
			b.BackgroundColor3 = on and GOLD or BG2
			b.TextColor3 = on and Color3.fromRGB(24, 20, 12) or TEXT
		end

		clear(tabBar)
		for i, t in ipairs(sec.tabs) do
			local on = t.id == activeTab
			local b = mk("TextButton", {
				-- Named so the tutorial hand can find this exact tab.
				Name = "Tab_" .. tostring(t.id),
				AutoButtonColor = true,
				BackgroundColor3 = on and Color3.fromRGB(58, 58, 70) or BG3,
				Font = FONT,
				TextSize = 14,
				TextColor3 = on and TEXT or MUTED,
				Text = t.label,
				Size = UDim2.fromOffset(0, 30),
				LayoutOrder = i,
			}, tabBar)
			round(b, 7)
			stroke(b, 1)
			fitButton(b, 14, 44)
			-- A red dot on Equipment while there is better gear in the bag. The
			-- dock used to carry this badge, which told you something was waiting
			-- without telling you where.
			if section == "inventory" and t.id == "tools"
				and (tonumber((state.upgrades or {}).gear) or 0) > 0 then
				local dot = mk("Frame", {
					BackgroundColor3 = Color3.fromRGB(235, 70, 70), BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -3, 0, 3),
					Size = UDim2.fromOffset(8, 8), ZIndex = (b.ZIndex or 1) + 2,
				}, b)
				round(dot, 4)
			end
			-- Pack count so unopened packs are obvious without opening the tab.
			if section == "inventory" and t.id == "packs" then
				local nPacks = #(state.packs or {})
				if nPacks > 0 then
					local badge = mk("TextLabel", {
						Name = "PackBadge",
						BackgroundColor3 = Color3.fromRGB(235, 70, 70),
						BorderSizePixel = 0,
						Font = FONT,
						TextSize = 11,
						TextColor3 = Color3.new(1, 1, 1),
						Text = tostring(math.min(nPacks, 99)),
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.new(1, -2, 0, 2),
						Size = UDim2.fromOffset(nPacks >= 10 and 20 or 16, 16),
						ZIndex = (b.ZIndex or 1) + 2,
					}, b)
					round(badge, 8)
				end
			end
			b.MouseButton1Click:Connect(function()
				activeTab = t.id
				tabFor[section] = t.id
				render()
			end)
		end
		-- A single-tab section does not need a strip above it.
		local multi = #sec.tabs > 1
		tabBar.Visible = multi

		-- Search only where there is a list long enough to need it.
		local searchable = (section == "inventory" and activeTab ~= "potions")
			or (section == "collection")
		searchBox.Visible = searchable
		if not searchable and search ~= "" then
			search = ""
			searchBox.Text = ""
		end
		-- Sorting is for the cards you own. The dex is already ordered by set.
		local sortable = section == "inventory" and activeTab == "cards"
		sortBar.Visible = sortable
		for id, chip in pairs(sortChips) do
			local on = id == cardSort
			chip.BackgroundColor3 = on and GOLD or BG3
			chip.TextColor3 = on and Color3.fromRGB(24, 20, 12) or MUTED
		end
		local tabsH = multi and 38 or 0
		local searchH = searchable and 34 or 0
		local sortH = sortable and 34 or 0
		local top = tabsH + searchH + sortH
		searchBox.Position = UDim2.fromOffset(L.x, L.top + tabsH)
		sortBar.Position = UDim2.fromOffset(L.x, L.top + tabsH + searchH)
		body.Position = UDim2.fromOffset(L.x, L.top + top)
		body.Size = UDim2.new(1, -L.w, 1, -(L.top + 16 + top))
		do
			local on = section == "inventory" and activeTab == "runes"
			local sv = on and eq.socketsPane() or eq.sockets
			if sv then
				if sv.root then
					sv.root.Position = UDim2.fromOffset(L.x, L.top + top)
					sv.root.Size = UDim2.new(1, -L.w, 1, -(L.top + 16 + top))
					sv.root.ZIndex = 40
				end
				sv.setState(state)
				sv.setVisible(on)
			end
			body.Visible = not on
		end

		clear(body)
		body.CanvasPosition = Vector2.zero
		if section == "inventory" then
			if activeTab == "packs" then
				renderPacks()
			elseif activeTab == "cards" then
				renderOwnedCards()
			elseif activeTab == "potions" then
				renderPotions()
			elseif activeTab == "vfx" then
				renderVfx()
			elseif activeTab == "runes" then
				-- The sockets pane is drawn over the body (see above).
			else
				-- Equipment, and anything still named after a retired tab.
				renderOwnedTools()
			end
		elseif section == "collection" then
			if activeTab == "chests" then
				renderChestDex()
			elseif activeTab == "packs" then
				renderPackDex()
			elseif activeTab == "cards" then
				renderCardDex()
			elseif activeTab == "equipment" then
				renderEquipmentDex()
			elseif activeTab == "hats" then
				renderNewGear("hats")
			elseif activeTab == "faces" then
				renderNewGear("faces")
			else
				renderRunes()
			end
		elseif section == "shop" then
			renderShop()
		elseif section == "daily" then
			renderDaily()
		elseif section == "account" then
			renderAccount()
		else
			renderPass()
		end
	end

	-- The cart pill lives on `root`, not `body`, but it still has to be
	-- re-evaluated whenever the screen changes -- a tab switch that leaves a
	-- stale total on the pill is the fastest way to lose a sale.
	do
		local baseRender = render
		render = function()
			baseRender()
			refreshCart()
		end
	end

	--[[
		The equipment screen keeps two things on `root`/in memory across renders:
		the character clone and the open item card. Every render clears the
		body, which would destroy the clone with it, so it is lifted out first;
		and a card left open over some other tab would be answering for a
		screen nobody is looking at, so it closes when you leave.
	]]
	do
		local baseRender = render
		render = function()
			if eq.clone then
				if not pcall(function()
					eq.clone.Parent = nil
				end) then
					eq.clone, eq.cloneOf, eq.cloneHeld = nil, nil, nil
				end
			end
			if eq.card and not (section == "inventory" and activeTab == "tools") then
				eq.card:Destroy()
				eq.card = nil
			end
			baseRender()
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		search = string.lower(searchBox.Text)
		render()
	end)

	--[[
		The readout rides render() like the cart pill above: every path that
		changes the screen already goes through it, including setState.
	]]
	do
		local baseRender = render
		render = function()
			baseRender()
			local used = tonumber(state.itemSlotsUsed)
			local cap = tonumber(state.itemSlotCap)
			if used and cap and cap > 0 then
				slotsBox.num.Text = string.format("%d/%d", used, cap)
				-- Amber before it bites, so a full shelf is never a surprise.
				slotsBox.num.TextColor3 = (used >= cap * 0.9) and GOLD or TEXT
				slotsBox.cap.Text = (used >= cap) and "itemslots  -  FULL" or "itemslots"
				local price = tonumber(state.itemSlotPrice)
				slotsBox.buy.Text = price and string.format("+100  %s gems", shortNum(price)) or ""
				slotsBox.hit.Active = price ~= nil
			else
				-- Server has not sent the numbers yet; show nothing rather than a lie.
				slotsBox.num.Text = ""
				slotsBox.cap.Text = ""
				slotsBox.buy.Text = ""
				slotsBox.hit.Active = false
			end
		end
	end

	local ctl = {}
	ctl.root = root

	-- The reveal owns the screen while it plays. setState replaces the whole
	-- state from the snapshot, so the flag lives outside it and is re-applied.
	local busy = false

	--[[
		The server has answered a checkout. Only it knows what the cart actually
		cost, so the sheet is settled from its reply rather than from anything
		guessed here.
	]]
	function ctl.cartResult(payload)
		payload = (type(payload) == "table") and payload or {}
		local okFlag = payload.ok and true or false
		local msg
		if okFlag then
			local n = 0
			for _, it in ipairs(payload.items or {}) do
				n += (it.qty or 0)
			end
			msg = string.format("%d items  --  %s credits, saved %s",
				n, shortNum(payload.pay or 0), shortNum(payload.saved or 0))
		else
			msg = tostring(payload.reason or "Purchase failed")
		end
		MineInventoryView._settleCart(okFlag, msg, okFlag)
	end

	function ctl.setBusy(flag)
		busy = flag and true or false
		state.busy = busy
		if root.Visible then
			render()
		end
	end
	function ctl.setCardSort(id)
		if type(id) == "string" and SORT_OK[id] then
			cardSort = id
			if root.Visible then
				render()
			end
		end
	end

	function ctl.setRailNotifs(counts)
		counts = counts or {}
		local Notifs = require(shared:WaitForChild("MineNotifs"))
		Notifs.set(railBtns.pass, counts.pass)
		Notifs.set(railBtns.daily, (counts.daily or 0) + (counts.milestone or 0))
	end

	function ctl.setState(s)
		if s then
			state = s
			ingestPassClaims(s.pass)
			-- Build the player's tool models in the background now, so the
			-- first bag open is already clones rather than 200 ms of building.
			prewarmTools(s)
		end
		state.busy = busy
		if root.Visible then
			render()
		end
	end

	function ctl.notePassClaim(payload)
		if type(payload) ~= "table" then
			return
		end
		local n = tonumber(payload.tier)
		if not n then
			return
		end
		local isPrem = payload.track == "premium"
		rememberPassClaim(isPrem, n, payload.ok ~= false)
		if root.Visible then
			render()
		end
	end

	function ctl.open(sec, t)
		if sec then
			section = sec
			activeTab = t or tabFor[sec] or sectionDef(sec).tabs[1].id
			-- Gear, Runes and Charms no longer have Inventory tabs; an old
			-- tutorial step or toast that names one gets Equipment.
			if sec == "inventory" and (activeTab == "gear" or activeTab == "charms") then
				activeTab = "tools"
			end
		end
		root.Visible = true
		render()
	end

	function ctl.close()
		root.Visible = false
	end

	function ctl.toggle(sec, t)
		if root.Visible then
			ctl.close()
		else
			ctl.open(sec, t)
		end
	end

	closeBtn.MouseButton1Click:Connect(function()
		ctl.close()
		if opts.onClose then
			opts.onClose()
		end
	end)

	render()
	return ctl
end

return MineInventoryView
