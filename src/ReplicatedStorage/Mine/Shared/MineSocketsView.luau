--[[
	MineSocketsView: put a rune into a thing, in two clicks.

	The old flow was a list of buttons that said "Socket -> pickaxe main" and
	"Socket -> pickaxe omni" on whichever rune happened to be selected. You had
	to already know what a loadout socket was to understand it, and nothing on
	screen showed you what was currently in anything.

	This is the whole model laid out: pick the gear or tool on the left, see its
	sockets arranged around it in the middle, pick a rune from the tray, click
	the socket. Sockets the item does not have are drawn greyed rather than
	hidden, so "this helmet has two and that one has four" is a thing you can see
	instead of a thing you have to be told.
]]
local MineSocketsView = {}

local RS = game:GetService("ReplicatedStorage")
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local Runes = require(shared:WaitForChild("MineRunes"))
local Gear = require(shared:WaitForChild("MineGear"))
local Irid = require(shared:WaitForChild("MineIridescence"))
local Cards = require(shared:WaitForChild("MineCards"))
local Tools = require(shared:WaitForChild("MineTools"))

local T = require(game:GetService("ReplicatedStorage").Mine.Shared:WaitForChild("MineTheme"))
local FONT = T.FONT
local FONT_M = T.FONT_M
local BG = T.BG
local CARD = T.CARD
local CARD_HI = T.CARD_HI
local TEXT = T.TEXT
local MUTED = T.MUTED
local GOLD = T.GOLD
local GREEN = T.GREEN
local DEAD = T.DEAD

-- Five is the ceiling. Laid out as a star so the eye can count them without
-- reading a number, and so a four-socket item is visibly one short of full.
local STAR = {
	{ 0.50, 0.13 },
	{ 0.87, 0.40 },
	{ 0.73, 0.83 },
	{ 0.27, 0.83 },
	{ 0.13, 0.40 },
}
local MAX_SLOTS = #STAR

local function mk(class, props, parent)
	local o = Instance.new(class)
	if props and props.BorderSizePixel == nil and o:IsA("GuiObject") then
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
	return o
end

-- Returns the UIStroke, not the parent. Returning the parent meant callers
-- holding the "stroke" were really holding the button, and setting .Color on it
-- threw -- which took the whole view down at mount.
local function stroke(o, thick, colour, transparency)
	return mk("UIStroke", {
		Thickness = thick or 1,
		Color = colour or Color3.fromRGB(96, 78, 62),
		Transparency = transparency or 0.35,
	}, o)
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

local function statOf(rune)
	if not rune then
		return "empty"
	end
	return string.format("%s +%.1f%%", tostring(rune.stat), (rune.pct or 0) * 100)
end

--------------------------------------------------------------------------------

function MineSocketsView.mount(parent, opts)
	opts = opts or {}
	local state = {}
	local pickedItem = nil      -- { kind = "gear"|"tool", id = , family = }
	local pickedRune = nil      -- rune id
	local filterKind = "all"    -- all | tool | pet | gear
	local hintFlash = nil
	local render

	local root = mk("Frame", {
		Name = "SocketsView",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 32,
	}, parent)

	-- Coach strip: three obvious steps so nobody has to reverse-engineer the UI.
	local coach = mk("Frame", {
		Name = "Coach",
		BackgroundColor3 = CARD,
		BackgroundTransparency = 0.15,
		Size = UDim2.new(1, 0, 0, 36),
		ZIndex = 33,
	}, root)
	round(coach, 8)
	local coachLbl = label(coach, "1 · pick a thing    2 · pick a rune below    3 · tap an empty socket",
		14, TEXT, UDim2.fromOffset(12, 0), UDim2.new(1, -24, 1, 0), FONT_M, Enum.TextXAlignment.Left)
	coachLbl.ZIndex = 34

	-- Filter chips under the coach.
	local filterRow = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 42),
		Size = UDim2.new(0.28, 0, 0, 30),
		ZIndex = 33,
	}, root)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, filterRow)

	-- LEFT: what you own that can hold a rune.
	local listPane = mk("ScrollingFrame", {
		Name = "Items",
		BackgroundColor3 = BG,
		BackgroundTransparency = 0.25,
		Position = UDim2.new(0, 0, 0, 78),
		Size = UDim2.new(0.28, 0, 1, -210),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ZIndex = 33,
	}, root)
	round(listPane, 10)
	mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, listPane)
	mk("UIPadding", {
		PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
	}, listPane)

	-- CENTRE: the item and its sockets.
	local stage = mk("Frame", {
		Name = "Stage",
		BackgroundColor3 = BG,
		BackgroundTransparency = 0.25,
		Position = UDim2.new(0.30, 0, 0, 42),
		Size = UDim2.new(0.70, 0, 1, -174),
		ZIndex = 33,
	}, root)
	round(stage, 10)

	local stageName = label(stage, "Pick something on the left", 20, TEXT,
		UDim2.fromOffset(0, 14), UDim2.new(1, 0, 0, 26), FONT, Enum.TextXAlignment.Center)
	local stageSub = label(stage, "", 13, MUTED,
		UDim2.fromOffset(0, 42), UDim2.new(1, 0, 0, 18), FONT_M, Enum.TextXAlignment.Center)

	local ring = mk("Frame", {
		Name = "Ring",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.fromOffset(420, 300),
		ZIndex = 34,
	}, stage)

	local core = mk("Frame", {
		Name = "Core",
		BackgroundColor3 = CARD,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(132, 132),
		ZIndex = 35,
	}, ring)
	round(core, 18)
	local coreStroke = stroke(core, 2, GOLD, 0.4)
	local coreLbl = label(core, "", 14, TEXT, UDim2.fromOffset(6, 0),
		UDim2.new(1, -12, 1, 0), FONT, Enum.TextXAlignment.Center)
	coreLbl.TextWrapped = true

	local slotBtns = {}
	for i = 1, MAX_SLOTS do
		local b = mk("TextButton", {
			Name = "Slot" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(STAR[i][1], STAR[i][2]),
			Size = UDim2.fromOffset(112, 82),
			BackgroundColor3 = DEAD,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 36,
		}, ring)
		round(b, 12)
		local st = stroke(b, 2, DEAD, 0.2)
		local top = label(b, "", 12, MUTED, UDim2.fromOffset(0, 10),
			UDim2.new(1, 0, 0, 16), FONT, Enum.TextXAlignment.Center)
		local body = label(b, "", 12, MUTED, UDim2.fromOffset(4, 30),
			UDim2.new(1, -8, 0, 40), FONT_M, Enum.TextXAlignment.Center)
		body.TextWrapped = true
		slotBtns[i] = { button = b, stroke = st, top = top, body = body }
		b.MouseButton1Click:Connect(function()
			if not pickedItem then
				hintFlash = "Pick something on the left first"
				render()
				return
			end
			if not pickedRune then
				hintFlash = "Pick a rune from the tray below, then tap this socket"
				render()
				return
			end
			if opts.onSocket and pickedItem and pickedRune then
				opts.onSocket(pickedItem, pickedRune, i)
				pickedRune = nil
				hintFlash = nil
				render()
			end
		end)
	end

	-- BOTTOM: the runes you can spend (taller tray, easier to tap).
	local tray = mk("ScrollingFrame", {
		Name = "Tray",
		BackgroundColor3 = BG,
		BackgroundTransparency = 0.25,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 124),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 6,
		ZIndex = 33,
	}, root)
	round(tray, 10)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, tray)
	mk("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, tray)

	local function clear(x)
		for _, ch in ipairs(x:GetChildren()) do
			if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") and not ch:IsA("UICorner")
				and not ch:IsA("UIStroke") then
				ch:Destroy()
			end
		end
	end

	local FILTERS = {
		{ id = "all", label = "All" },
		{ id = "tool", label = "Tools" },
		{ id = "pet", label = "Pets" },
		{ id = "gear", label = "Hats" },
	}

	local function paintFilters()
		clear(filterRow)
		for i, f in ipairs(FILTERS) do
			local on = filterKind == f.id
			local b = mk("TextButton", {
				AutoButtonColor = true,
				BackgroundColor3 = on and GOLD or CARD,
				Font = FONT,
				TextSize = 13,
				TextColor3 = on and Color3.fromRGB(20, 18, 12) or TEXT,
				Text = f.label,
				Size = UDim2.fromOffset(54, 28),
				LayoutOrder = i,
				ZIndex = 34,
			}, filterRow)
			round(b, 7)
			b.MouseButton1Click:Connect(function()
				filterKind = f.id
				render()
			end)
		end
	end

	----------------------------------------------------------------------------

	-- Everything that can hold a rune, in one list.
	local function itemsOf()
		local out = {}
		-- A hat and a face hold exactly one rune each. This list used to declare
		-- every piece of gear socket-less, in red -- true once, and not for a
		-- long time.
		for _, g in ipairs(state.gear or {}) do
			local slot = Gear.migrateSlot(g.slot)
			table.insert(out, {
				kind = "gear", id = g.id, piece = g,
				name = (g.rarity or "") .. " " .. (g.name or g.setName or ""),
				sub = (slot == "face") and "your face" or "a hat",
				slots = math.max(1, tonumber(g.slotCount) or 1),
				filled = g.sockets or {},
				tint = (Gear.RARITY_COLOR and Gear.RARITY_COLOR[g.rarity]) or GOLD,
			})
		end
		-- Gear sorted by rarity, best first. A wall of Commons with the one Mythic
		-- buried in the middle is the same as having no list at all.
		table.sort(out, function(a, b)
			local ra = Gear.RARITY_RANK[a.piece and a.piece.rarity] or 0
			local rb = Gear.RARITY_RANK[b.piece and b.piece.rarity] or 0
			if ra ~= rb then
				return ra > rb
			end
			-- Then the ones with sockets to fill, then by name so it is stable.
			if (a.slots or 0) ~= (b.slots or 0) then
				return (a.slots or 0) > (b.slots or 0)
			end
			return tostring(a.name) < tostring(b.name)
		end)

		-- Tools go on top: they are the thing you are always holding.
		local tools = {}
		local ShopLadders = nil
		pcall(function()
			ShopLadders = require(shared:WaitForChild("MineShopLadders"))
		end)
		-- One rune per tool. Omni stays on family loadouts only when unlocked.
		for _, fam in ipairs({ "pickaxe", "drill", "explosive" }) do
			local owned = (state.tools or {})[fam] or 0
			if owned > 0 then
				local list = Tools.TOOLS[fam] or {}
				local tier = ((state.toolTier or {})[fam]) or owned
				local row = list[math.clamp(tier, 1, math.max(#list, 1))]
				local sock = (state.toolSockets or {})[fam]
				local main, omni
				if type(sock) == "string" then
					main = sock
				elseif type(sock) == "table" then
					main, omni = sock.main, sock.omni
				end
				local slots = 1
				if type(sock) == "table" and sock.omniUnlocked then
					slots = 2
				end
				table.insert(tools, {
					kind = "tool", id = fam, family = fam,
					name = (row and row.name) or fam,
					sub = fam .. "  ·  rung " .. tier,
					slots = slots,
					filled = { main, omni },
					tint = GOLD,
				})
			end
		end
		-- Every owned shop mesh tool gets its own single socket.
		local shopRunes = state.shopToolRunes or {}
		for id, owned in pairs(state.ownedShopTools or {}) do
			if owned then
				local row = ShopLadders and ShopLadders.byId and ShopLadders.byId(id)
				table.insert(tools, {
					kind = "shop", id = id,
					family = row and row.family or "pickaxe",
					name = (row and row.name) or tostring(id),
					sub = "shop tool  ·  1 rune",
					slots = 1,
					filled = { shopRunes[id] },
					tint = GOLD,
				})
			end
		end
		-- Rebirth takes shop tools back but their runes stay socketed, waiting
		-- for the tool to be bought again. Show them so the rune is not lost.
		for id, rid in pairs(state.shopToolRunes or {}) do
			if rid and not (state.ownedShopTools or {})[id] then
				local row = ShopLadders and ShopLadders.byId and ShopLadders.byId(id)
				table.insert(tools, {
					kind = "shop", id = id, family = row and row.family or "pickaxe",
					name = (row and row.name) or tostring(id), sub = "buy it again to use this rune",
					slots = 1, filled = { rid }, tint = MUTED,
				})
			end
		end
		-- Flagships and fossil tools take a rune each. They are the ones people
		-- most want to socket, and leaving them out of this list was the whole
		-- reason the old screen still needed its button soup.
		for _, ct in ipairs(state.chestTools or {}) do
			if type(ct) == "table" then
				table.insert(tools, {
					kind = "chest", id = ct.id, family = ct.family,
					name = tostring(ct.name), sub = "flagship  ·  " .. tostring(ct.family),
					slots = 1, filled = { ct.runeId }, tint = GOLD,
				})
			end
		end
		for key, ft in pairs(state.fossilTools or {}) do
			if type(ft) == "table" then
				table.insert(tools, {
					kind = "fossil", id = ft.fossilId or key, family = ft.family,
					name = tostring(ft.name), sub = "fossil tool  ·  " .. tostring(ft.family),
					slots = 1, filled = { ft.runeId }, tint = GOLD,
				})
			end
		end
		for i = #tools, 1, -1 do
			table.insert(out, 1, tools[i])
		end
		--[[
			PETS, AT THE TOP.

			One rune per pet, and the rune belongs to the CARD -- swap the pet's
			hat and the rune stays. Pets were not on this list at all, which left
			three of the six sockets in the game unreachable from the one screen
			named after sockets.

			Listed while a pet is on your team, or while it is holding a rune, so
			a rune is never stranded on a card you cannot find.
		]]
		local pets, onTeam = {}, {}
		for _, id in ipairs(state.equipped or {}) do
			onTeam[id] = true
		end
		for _, c in ipairs(state.cards or {}) do
			local rid = (state.petSockets or {})[c.id]
			if onTeam[c.id] or rid then
				table.insert(pets, {
					kind = "pet", id = c.id,
					name = tostring(c.name or c.setName or "Pet"),
					sub = onTeam[c.id] and "on your team" or "in the binder",
					slots = 1,
					filled = { rid },
					tint = (Cards.RARITY_COLOR and Cards.RARITY_COLOR[c.rarity]) or GREEN,
				})
			end
		end
		table.sort(pets, function(x, y)
			if onTeam[x.id] ~= onTeam[y.id] then
				return onTeam[x.id]
			end
			return tostring(x.name) < tostring(y.name)
		end)
		for i = #pets, 1, -1 do
			table.insert(out, 1, pets[i])
		end
		return out
	end

	local function runeById(id)
		for _, r in ipairs(state.runes or {}) do
			if r.id == id then
				return r
			end
		end
	end

	-- One definition, in MineRunes, shared with every other rune list.
	local function socketedIds()
		return Runes.socketedIds(state)
	end

	render = function()
		paintFilters()
		clear(listPane)
		clear(tray)

		local items = itemsOf()
		-- Soft filter so the left list is not a wall of every pet+tool+hat.
		if filterKind ~= "all" then
			local filtered = {}
			for _, it in ipairs(items) do
				local k = it.kind
				local pass = false
				if filterKind == "tool" then
					pass = k == "tool" or k == "shop" or k == "chest" or k == "fossil"
				elseif filterKind == "pet" then
					pass = k == "pet"
				elseif filterKind == "gear" then
					pass = k == "gear"
				end
				if pass then
					table.insert(filtered, it)
				end
			end
			items = filtered
		end
		-- Open on something. Landing on "Pick something on the left" with an
		-- empty star teaches nobody what the screen is for; landing on your best
		-- piece with its sockets drawn does.
		if not pickedItem and items[1] then
			pickedItem = { kind = items[1].kind, id = items[1].id, family = items[1].family }
		end
		-- If the filter hid the current pick, clear it so we re-open on visible.
		if pickedItem then
			local still = false
			for _, it in ipairs(items) do
				if it.kind == pickedItem.kind and it.id == pickedItem.id then
					still = true
					break
				end
			end
			if not still then
				pickedItem = items[1] and { kind = items[1].kind, id = items[1].id, family = items[1].family } or nil
			end
		end
		for i, it in ipairs(items) do
			local on = pickedItem and pickedItem.kind == it.kind and pickedItem.id == it.id
			local b = mk("TextButton", {
				BackgroundColor3 = on and CARD_HI or CARD,
				Size = UDim2.new(1, 0, 0, 56),
				Text = "",
				AutoButtonColor = true,
				LayoutOrder = i,
				ZIndex = 34,
			}, listPane)
			round(b, 8)
			local itemStroke = stroke(b, on and 2 or 1, it.tint, on and 0.1 or 0.5)
			if it.piece then
				Irid.badge(b, it.piece.rarity, { height = 18, z = 36 })
			end
			label(b, it.name, 14, it.tint or TEXT, UDim2.fromOffset(10, 6), UDim2.new(1, -36, 0, 18), FONT).ZIndex = 35
			if it.noRunes then
				label(b, "!", 22, Color3.fromRGB(255, 72, 72), UDim2.new(1, -28, 0, 4), UDim2.fromOffset(24, 24), FONT).ZIndex = 36
			end
			local n = 0
			for k = 1, it.slots do
				if it.filled[k] then
					n += 1
				end
			end
			local subText = it.noRunes and it.sub or string.format("%s   %d/%d runes", it.sub, n, it.slots)
			label(b, subText, 12, it.noRunes and Color3.fromRGB(255, 120, 120) or MUTED,
				UDim2.fromOffset(10, 28), UDim2.new(1, -20, 0, 16)).ZIndex = 35
			b.MouseButton1Click:Connect(function()
				pickedItem = { kind = it.kind, id = it.id, family = it.family }
				hintFlash = nil
				render()
			end)
		end
		if #items == 0 then
			label(listPane, "Nothing in this filter.", 13, MUTED, UDim2.fromOffset(4, 0),
				UDim2.new(1, -8, 0, 40))
		end

		-- The stage.
		local chosen
		for _, it in ipairs(items) do
			if pickedItem and it.kind == pickedItem.kind and it.id == pickedItem.id then
				chosen = it
			end
		end
		stageName.Text = chosen and chosen.name or "Pick something on the left"
		if hintFlash then
			stageSub.Text = hintFlash
			stageSub.TextColor3 = GOLD
		else
			stageSub.Text = (chosen and chosen.sub)
				or "Pick a pet, a hat or a tool -- any rune fits any of them."
			stageSub.TextColor3 = (chosen and chosen.noRunes) and Color3.fromRGB(255, 90, 90) or MUTED
		end
		-- Coach tracks where you are in the 3-click flow.
		if not pickedItem then
			coachLbl.Text = "1 · pick a thing on the left"
		elseif not pickedRune then
			coachLbl.Text = "2 · pick a rune from the tray below"
		else
			coachLbl.Text = "3 · tap an empty socket on the star"
		end
		coreLbl.Text = chosen and chosen.name or ""
		core.BackgroundColor3 = chosen and CARD or DEAD
		Irid.clear(core)
		coreStroke.Color = (chosen and chosen.tint) or GOLD
		coreStroke.Thickness = 2
		coreStroke.Transparency = 0.4
		if chosen and chosen.piece then
			Irid.badge(core, chosen.piece.rarity, { height = 28, position = UDim2.new(0.5, 0, 1, -6), anchor = Vector2.new(0.5, 1), z = 40 })
		end

		for i = 1, MAX_SLOTS do
			local s = slotBtns[i]
			local usable = chosen and i <= (chosen.slots or 0)
			local fillId = chosen and chosen.filled[i]
			local rune = fillId and runeById(fillId)
			if not usable then
				s.button.BackgroundColor3 = DEAD
				s.stroke.Color = DEAD
				s.stroke.Transparency = 0.55
				s.top.Text = "LOCKED"
				s.top.TextColor3 = Color3.fromRGB(96, 86, 78)
				s.body.Text = chosen and "this one has no slot here" or ""
				s.body.TextColor3 = Color3.fromRGB(96, 86, 78)
				s.button.AutoButtonColor = false
			elseif rune then
				s.button.BackgroundColor3 = Color3.fromRGB(46, 62, 48)
				s.stroke.Color = GREEN
				s.stroke.Transparency = 0.2
				s.top.Text = "SOCKET " .. i
				s.top.TextColor3 = GREEN
				s.body.Text = statOf(rune)
				s.body.TextColor3 = TEXT
				s.button.AutoButtonColor = false
			else
				local armed = pickedRune ~= nil
				s.button.BackgroundColor3 = armed and Color3.fromRGB(66, 56, 34) or CARD
				s.stroke.Color = armed and GOLD or MUTED
				s.stroke.Transparency = armed and 0.1 or 0.5
				s.top.Text = "SOCKET " .. i
				s.top.TextColor3 = armed and GOLD or MUTED
				s.body.Text = armed and "tap to fit" or "empty — pick a rune"
				s.body.TextColor3 = armed and GOLD or MUTED
				s.button.AutoButtonColor = armed
			end
		end

		-- The tray: only runes that are not already in something.
		local used = socketedIds()
		local free = {}
		for _, r in ipairs(state.runes or {}) do
			if not used[r.id] then
				table.insert(free, r)
			end
		end
		table.sort(free, function(a, b)
			local ta = math.floor(tonumber(a.tier) or 1)
			local tb = math.floor(tonumber(b.tier) or 1)
			if ta ~= tb then
				return ta > tb
			end
			return (a.pct or 0) > (b.pct or 0)
		end)
		for i, r in ipairs(free) do
			local on = pickedRune == r.id
			local b = mk("TextButton", {
				BackgroundColor3 = on and Color3.fromRGB(66, 56, 34) or CARD,
				Size = UDim2.fromOffset(168, 96),
				Text = "",
				AutoButtonColor = true,
				LayoutOrder = i,
				ZIndex = 34,
			}, tray)
			round(b, 8)
			stroke(b, on and 2 or 1, on and GOLD or MUTED, on and 0.1 or 0.5)
			label(b, statOf(r), 14, on and GOLD or TEXT, UDim2.fromOffset(8, 10),
				UDim2.new(1, -16, 0, 20), FONT).ZIndex = 35
			label(b, string.format("%s  ·  T%d", tostring(r.kind),
				math.max(1, math.floor(tonumber(r.tier) or 1))), 12, MUTED,
				UDim2.fromOffset(8, 36), UDim2.new(1, -16, 0, 16)).ZIndex = 35
			label(b, on and "picked — now tap a socket" or "tap to pick", 12, on and GOLD or MUTED,
				UDim2.fromOffset(8, 62), UDim2.new(1, -16, 0, 18)).ZIndex = 35
			b.MouseButton1Click:Connect(function()
				pickedRune = (pickedRune == r.id) and nil or r.id
				hintFlash = nil
				render()
			end)
		end
		if #free == 0 then
			label(tray, "No loose runes. Roll one, or open a Rune Case.", 13, MUTED,
				UDim2.fromOffset(0, 0), UDim2.fromOffset(360, 96))
		end
	end

	local view = {}
	view.root = root

	function view.setState(snap)
		if snap then
			state = snap
		end
		-- Instant refresh: re-paint even when the tab is off so the next open
		-- never shows a stale frame, and an open tab snaps immediately.
		render()
	end

	function view.setVisible(on)
		root.Visible = on and true or false
		if root.Visible then
			render()
		end
	end

	render()
	return view
end

return MineSocketsView
