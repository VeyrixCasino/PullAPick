--[[
	MineLoadoutView -- the LOADOUT tab of the Blacksmith screen.

	Owner, 2026-10-11: "Show all owned tools and gear, plus sections for gems
	and traits. Make equipped items easy to recognize. Selecting an item should
	open a polished inspection area showing its icon or preview, name, rarity,
	stats, and relevant actions."

	THE COMPOSITION IS THE POINT, and it is the same one the Crafting tab uses:

	    sections (left)  |  a generous grid (middle)  |  inspection (right)

	Crafting puts tool-type filters in that left column and recipes in the grid;
	Loadout puts the four things you own there. A player who learns one tab can
	read the other, which is worth more than two layouts each optimal alone.

	"GEMS" ARE RUNES. The game's word for the socketable stones is rune --
	MineRunes, the Enchanter, `snapshot.runes` -- and the owner's word is gems.
	The owner's word wins on the button because that is what they will look for,
	and the code keeps saying runes because that is what every other file calls
	them. The mapping lives here, in one function, rather than being renamed
	through the codebase on the strength of one sentence.

	RARITY COLOUR IS MineGear.RARITY_COLOR, for the reason MineSkinsView gives:
	MineTheme.CANDY keys each carry a meaning (gold is coins, cyan is gems) and
	an eight-rung rarity ladder would eat most of them. Rarity rides a BADGE and
	an outline, never the card fill, so recolouring cannot fight `adoptOne`.

	THIS VIEW OWNS NO TRUTH. Everything is read from the snapshot the host hands
	it, and equipping asks the server and waits for the next snapshot, because
	the server is where ownership is checked.
]]
local MineLoadoutView = {}

local RS = game:GetService("ReplicatedStorage")
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")

local UI = require(shared:WaitForChild("MineUI"))
local T = require(shared:WaitForChild("MineTheme"))
local Gear = require(shared:WaitForChild("MineGear"))

-- Optional dependencies. A missing icon pack must cost a picture, never the
-- whole tab, so each is probed rather than required at the top.
local function soft(name)
	local ok, mod = pcall(function()
		return require(shared:WaitForChild(name, 5))
	end)
	return ok and mod or nil
end
local Icons = soft("MineIcons")
local GearIcons = soft("MineGearIcons")
local Traits = soft("MineTraits")
local Runes = soft("MineRunes")

local RARITY_COLOR = Gear.RARITY_COLOR or {}
local RARITY_RANK = Gear.RARITY_RANK or {}

local SECTIONS = {
	{ key = "tools", label = "Tools", blurb = "Every tool you have forged." },
	{ key = "gear", label = "Gear", blurb = "Worn pieces and the ones on the bench." },
	{ key = "gems", label = "Gems", blurb = "Stones you can socket into gear." },
	{ key = "traits", label = "Traits", blurb = "What your worn gear is giving you." },
}

--------------------------------------------------------------------------------
-- READING THE SNAPSHOT
--
-- One function per section, each returning the SAME row shape, so the grid and
-- the inspection pane never have to care which section they are drawing:
--
--   { key, name, rarity, equipped, icon, stats = {{label, value}, ...},
--     action = { label, run } | nil, sub }
--------------------------------------------------------------------------------

local function num(n)
	n = tonumber(n) or 0
	if n >= 1000000 then
		return string.format("%.2fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.2fK", n / 1000)
	end
	return tostring(math.floor(n))
end

local function pct(x)
	return string.format("%.2f%%", (tonumber(x) or 0) * 100)
end

--[[
	The tool a player is actually holding.

	The field is `oreToolEquipped`, which is what the SERVER sets in
	Verbs.equipOreTool and what MineForge and MineBenchView already read. It is
	named here rather than guessed: the first draft of this file looked for
	`equippedToolUid` / `equippedTool` / `heldUid`, none of which exist anywhere
	in the snapshot, so every tile would have drawn un-equipped and nothing
	would have errored.
]]
local function heldUid(snap)
	return snap.oreToolEquipped
end

local function toolRows(snap, opts)
	local held = heldUid(snap)
	local out = {}
	for _, t in ipairs(snap.oreTools or {}) do
		if type(t) == "table" and t.uid then
			local fam = tostring(t.familyId or "pickaxe")
			local lvl = tonumber(t.level) or 1
			local isHeld = (held ~= nil and tostring(t.uid) == tostring(held))
				or (held == nil and t.equipped == true)
			out[#out + 1] = {
				key = "tool|" .. tostring(t.uid),
				name = t.name or (fam:sub(1, 1):upper() .. fam:sub(2)),
				sub = ("%s  ·  tier %d"):format(fam, math.floor(tonumber(t.tier) or 0)),
				rarity = t.rarity,
				equipped = isHeld,
				iconKey = { t.typeId, t.id, fam, "pickaxe" },
				sortA = math.floor(tonumber(t.tier) or 0),
				sortB = lvl,
				stats = {
					{ "Level", tostring(lvl) },
					{ "Tier", tostring(math.floor(tonumber(t.tier) or 0)) },
					{ "Type", fam },
				},
				action = (not isHeld) and opts.onEquipTool and {
					label = "EQUIP",
					run = function() opts.onEquipTool(t.uid) end,
				} or nil,
			}
		end
	end
	table.sort(out, function(a, b)
		if a.equipped ~= b.equipped then return a.equipped end
		if a.sortA ~= b.sortA then return a.sortA > b.sortA end
		return a.sortB > b.sortB
	end)
	return out
end

local function gearRows(snap, opts)
	local worn = snap.equippedGear or {}
	local wornIds = {}
	for slot, id in pairs(worn) do
		if id ~= nil then wornIds[tostring(id)] = tostring(slot) end
	end
	local out = {}
	for _, g in ipairs(snap.gear or {}) do
		if type(g) == "table" then
			local id = tostring(g.id or g.uid or "")
			local rarity = Gear.migrateRarity and Gear.migrateRarity(g.rarity) or g.rarity
			local slot = Gear.migrateSlot and Gear.migrateSlot(g.slot) or g.slot
			--[[
				The namer is MineGear.shopName. Not `label`, which does not
				exist -- the first draft called that, the `and` short-circuited
				to nil and every piece fell back to "Gear g1". The Studio shot
				is what caught it; the guard made it look deliberate.
			]]
			local okLabel, labelled = pcall(function()
				return Gear.shopName and Gear.shopName(g) or nil
			end)
			local stats = {
				{ "Slot", tostring((Gear.SLOT_LABEL or {})[slot] or slot or "?") },
				{ "Rarity", tostring(rarity or "?") },
			}
			if tonumber(g.pct) then
				stats[#stats + 1] = { "Power", pct(g.pct) }
			end
			if tonumber(g.slotCount) then
				stats[#stats + 1] = { "Sockets", tostring(math.floor(g.slotCount)) }
			end
			out[#out + 1] = {
				key = "gear|" .. id,
				name = (okLabel and labelled) or g.name or ("Gear " .. id),
				sub = tostring(g.setName or g.setId or slot or ""),
				rarity = rarity,
				equipped = wornIds[id] ~= nil,
				iconKey = { g.catalogId, g.id, slot },
				gearPiece = g,
				sortA = RARITY_RANK[rarity] or 0,
				sortB = tonumber(g.pct) or 0,
				stats = stats,
				action = (wornIds[id] == nil)
					and opts.onEquipGear and {
						label = "EQUIP",
						run = function() opts.onEquipGear(g.id or g.uid, slot) end,
					}
					or (opts.onUnequipGear and {
						label = "UNEQUIP",
						run = function() opts.onUnequipGear(slot, g.id or g.uid) end,
					}) or nil,
			}
		end
	end
	table.sort(out, function(a, b)
		if a.equipped ~= b.equipped then return a.equipped end
		if a.sortA ~= b.sortA then return a.sortA > b.sortA end
		return a.sortB > b.sortB
	end)
	return out
end

-- GEMS. `snapshot.runes` is the list; a socketed one carries the piece it sits
-- in, which is the one fact that makes this list readable at a glance.
local function gemRows(snap, _opts)
	local out = {}
	for _, r in ipairs(snap.runes or {}) do
		if type(r) == "table" then
			local id = tostring(r.id or r.uid or "")
			local tier = math.floor(tonumber(r.tier) or 0)
			local stat = tostring(r.stat or r.kind or "?")
			local socketed = r.socketedIn ~= nil or r.gearId ~= nil or r.equipped == true
			local stats = {
				{ "Stat", stat },
				{ "Tier", tostring(tier) },
			}
			if tonumber(r.pct) then
				stats[#stats + 1] = { "Bonus", pct(r.pct) }
			elseif Runes and Runes.pctForTier then
				local okP, v = pcall(Runes.pctForTier, stat, tier)
				if okP and tonumber(v) then
					stats[#stats + 1] = { "Bonus", pct(v) }
				end
			end
			out[#out + 1] = {
				key = "gem|" .. id,
				name = r.name or (stat:sub(1, 1):upper() .. stat:sub(2) .. " Gem"),
				sub = socketed and "socketed" or "loose",
				rarity = r.rarity,
				equipped = socketed,
				iconKey = { "gems" },
				sortA = tier,
				sortB = tonumber(r.pct) or 0,
				stats = stats,
			}
		end
	end
	table.sort(out, function(a, b)
		if a.equipped ~= b.equipped then return a.equipped end
		if a.sortA ~= b.sortA then return a.sortA > b.sortA end
		return tostring(a.name) < tostring(b.name)
	end)
	return out
end

--[[
	TRAITS ARE DERIVED, NOT OWNED.

	There is no `snapshot.traits` list: a trait is something a worn gear piece
	GIVES you, so the honest list is "what my gear is granting right now",
	totalled per trait rather than repeated once per piece. A player reading
	this wants the total -- two pieces each giving the same trait is one line
	with the sum, not two lines they have to add up.
]]
local function traitRows(snap, _opts)
	local worn = snap.equippedGear or {}
	local wornIds = {}
	for _, id in pairs(worn) do
		if id ~= nil then wornIds[tostring(id)] = true end
	end
	local acc, order = {}, {}
	for _, g in ipairs(snap.gear or {}) do
		if type(g) == "table" and wornIds[tostring(g.id or g.uid or "")] then
			for _, tr in ipairs(g.traits or {}) do
				local id = type(tr) == "table" and tostring(tr.id or tr.stat or "?") or tostring(tr)
				local amount = (type(tr) == "table" and tonumber(tr.pct or tr.amount)) or 0
				if not acc[id] then
					acc[id] = { amount = 0, count = 0, rarity = type(tr) == "table" and tr.rarity or nil }
					order[#order + 1] = id
				end
				acc[id].amount += amount
				acc[id].count += 1
			end
		end
	end
	local out = {}
	for _, id in ipairs(order) do
		local a = acc[id]
		local nm = id
		if Traits and Traits.byId then
			local okT, def = pcall(Traits.byId, id)
			if okT and type(def) == "table" and def.name then
				nm = def.name
			end
		end
		local rarity = a.rarity
		if not rarity and Traits and Traits.rarityOf then
			local okR, r = pcall(Traits.rarityOf, id)
			if okR then rarity = r end
		end
		out[#out + 1] = {
			key = "trait|" .. id,
			name = nm,
			sub = a.count > 1 and (a.count .. " pieces") or "1 piece",
			rarity = rarity,
			equipped = true,
			iconKey = { "skills" },
			sortA = RARITY_RANK[rarity] or 0,
			sortB = a.amount,
			stats = {
				{ "Total", a.amount > 0 and pct(a.amount) or "--" },
				{ "From", a.count .. (a.count == 1 and " piece" or " pieces") },
			},
		}
	end
	table.sort(out, function(a, b)
		if a.sortA ~= b.sortA then return a.sortA > b.sortA end
		return a.sortB > b.sortB
	end)
	return out
end

local BUILDERS = {
	tools = toolRows,
	gear = gearRows,
	gems = gemRows,
	traits = traitRows,
}

--------------------------------------------------------------------------------
-- DRAWING
--------------------------------------------------------------------------------

local function resolveIcon(keys)
	if not (Icons and Icons.image) then
		return nil
	end
	for _, k in ipairs(keys or {}) do
		if type(k) == "string" and k ~= "" then
			local ok, img = pcall(Icons.image, k)
			if ok and type(img) == "string" and img ~= "" then
				return img
			end
		end
	end
	return nil
end

local function gearIcon(piece)
	if not (GearIcons and piece) then
		return nil
	end
	local cid = piece.catalogId
	if not cid then
		return nil
	end
	local ok, img = pcall(function()
		return GearIcons.icon and GearIcons.icon(cid) or nil
	end)
	return ok and img or nil
end

function MineLoadoutView.mount(parent, opts)
	opts = opts or {}
	local state = { section = "tools", search = "", selected = nil, rows = {} }

	local root = UI.new("Frame", {
		Name = "LoadoutPanel",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 86,
	}, parent)

	-- Three columns. Scale widths so the composition survives a phone, with the
	-- inspection pane given real room: it is the thing the owner asked to let
	-- selected items "stand out".
	local NAV_W = 0.18
	local INSPECT_W = 0.28

	local nav = UI.new("Frame", {
		Name = "Sections",
		BackgroundTransparency = 1,
		Size = UDim2.new(NAV_W, -8, 1, 0),
		ZIndex = 86,
	}, root)
	UI.new("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, nav)

	local mid = UI.new("Frame", {
		Name = "Collection",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(NAV_W, 0),
		Size = UDim2.new(1 - NAV_W - INSPECT_W, -8, 1, 0),
		ZIndex = 86,
	}, root)

	-- Search. Few words, big enough to read, and it filters as you type.
	local search = UI.new("TextBox", {
		Name = "Search",
		BackgroundColor3 = T.INK,
		Size = UDim2.new(1, 0, 0, 34),
		Font = T.FONT_M,
		TextSize = T.TEXT_MIN or 14,
		TextColor3 = T.TEXT,
		PlaceholderText = "Search...",
		PlaceholderColor3 = T.FAINT,
		Text = "",
		ClearTextOnFocus = false,
		ZIndex = 87,
	}, mid)
	UI.round(search, 10)
	UI.edge(search, T.OUTLINE, T.STROKE_CHUNKY)

	local grid = UI.new("ScrollingFrame", {
		Name = "Grid",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 42),
		Size = UDim2.new(1, 0, 1, -42),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 5,
		ZIndex = 86,
	}, mid)
	local gridLayout = UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(136, 150),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)

	local empty = UI.muted(mid, "", T.TEXT_BODY or 16)
	empty.Position = UDim2.fromOffset(0, 70)
	empty.Size = UDim2.new(1, 0, 0, 40)
	empty.TextXAlignment = Enum.TextXAlignment.Left
	empty.Visible = false
	empty.ZIndex = 87

	----------------------------------------------------------------- inspect --
	local inspect = UI.card(root, UDim2.new(INSPECT_W, 0, 1, 0),
		UDim2.new(1 - INSPECT_W, 0, 0, 0))
	inspect.Name = "Inspect"
	inspect.ZIndex = 86
	UI.edge(inspect, T.OUTLINE, T.STROKE_THICK)

	local preview = UI.new("Frame", {
		Name = "Preview",
		BackgroundColor3 = T.INK,
		Position = UDim2.fromOffset(14, 14),
		Size = UDim2.new(1, -28, 0, 132),
		ZIndex = 87,
	}, inspect)
	UI.round(preview, 12)
	UI.edge(preview, T.OUTLINE, T.STROKE_CHUNKY)

	local previewImg = UI.new("ImageLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.78, 0.78),
		ScaleType = Enum.ScaleType.Fit,
		Image = "",
		ZIndex = 88,
	}, preview)
	local previewGlyph = UI.text(preview, "", 44)
	previewGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
	previewGlyph.Position = UDim2.fromScale(0.5, 0.5)
	previewGlyph.Size = UDim2.fromScale(1, 1)
	previewGlyph.ZIndex = 88

	local iName = UI.text(inspect, "", T.TEXT_BODY or 16)
	iName.Position = UDim2.fromOffset(14, 154)
	iName.Size = UDim2.new(1, -28, 0, 44)
	iName.TextXAlignment = Enum.TextXAlignment.Left
	iName.TextYAlignment = Enum.TextYAlignment.Top
	iName.TextWrapped = true
	iName.Font = Enum.Font.GothamBlack
	iName.ZIndex = 87
	UI.outlineText(iName)

	local iRarity = UI.new("Frame", {
		BackgroundColor3 = RARITY_COLOR.F or T.DEAD,
		Position = UDim2.fromOffset(14, 198),
		Size = UDim2.fromOffset(74, 24),
		ZIndex = 87,
	}, inspect)
	UI.round(iRarity, 8)
	UI.edge(iRarity, T.OUTLINE, T.STROKE_CHUNKY)
	local iRarityLbl = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBlack,
		TextSize = T.TEXT_MIN or 14,
		Text = "",
		TextColor3 = Color3.fromRGB(20, 12, 44),
		ZIndex = 88,
	}, iRarity)

	local statList = UI.new("Frame", {
		Name = "Stats",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 232),
		Size = UDim2.new(1, -28, 1, -300),
		ZIndex = 87,
	}, inspect)
	UI.new("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, statList)

	-- MineUI.button already juices what it returns; juicing again would register
	-- a second channel on the shared FxScale and the two would multiply.
	local actionBtn, actionLbl = UI.button(inspect, "", UDim2.new(1, -28, 0, 44),
		UDim2.new(0, 14, 1, -58), true, "green")
	actionBtn.ZIndex = 88
	actionBtn.Visible = false
	local actionRun

	local hint = UI.muted(inspect, "Tap anything to inspect it.", T.TEXT_MIN or 14)
	hint.Position = UDim2.fromOffset(14, 14)
	hint.Size = UDim2.new(1, -28, 0, 60)
	hint.TextWrapped = true
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.TextYAlignment = Enum.TextYAlignment.Top
	hint.ZIndex = 89

	local function showInspect(row)
		local has = type(row) == "table"
		hint.Visible = not has
		preview.Visible = has
		iName.Visible = has
		iRarity.Visible = has
		statList.Visible = has
		for _, c in ipairs(statList:GetChildren()) do
			if not c:IsA("UIListLayout") then
				c:Destroy()
			end
		end
		if not has then
			actionBtn.Visible = false
			actionRun = nil
			return
		end

		local img = gearIcon(row.gearPiece) or resolveIcon(row.iconKey)
		previewImg.Image = img or ""
		previewImg.Visible = img ~= nil
		previewGlyph.Visible = img == nil
		previewGlyph.Text = img == nil and string.sub(tostring(row.name), 1, 1):upper() or ""

		iName.Text = tostring(row.name)
		local rar = tostring(row.rarity or "")
		iRarity.Visible = rar ~= ""
		iRarity.BackgroundColor3 = RARITY_COLOR[rar] or RARITY_COLOR.F or T.DEAD
		iRarityLbl.Text = rar

		for i, pair in ipairs(row.stats or {}) do
			local line = UI.new("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 22),
				LayoutOrder = i,
				ZIndex = 87,
			}, statList)
			local k = UI.muted(line, tostring(pair[1]), T.TEXT_MIN or 14)
			k.Size = UDim2.new(0.5, 0, 1, 0)
			k.TextXAlignment = Enum.TextXAlignment.Left
			k.ZIndex = 88
			local v = UI.text(line, tostring(pair[2]), T.TEXT_MIN or 14)
			v.Position = UDim2.fromScale(0.5, 0)
			v.Size = UDim2.new(0.5, 0, 1, 0)
			v.TextXAlignment = Enum.TextXAlignment.Right
			v.Font = Enum.Font.GothamBlack
			v.ZIndex = 88
		end

		if row.action and type(row.action.run) == "function" then
			actionBtn.Visible = true
			actionRun = row.action.run
			if actionLbl then
				actionLbl.Text = tostring(row.action.label or "USE")
			end
		else
			actionBtn.Visible = false
			actionRun = nil
		end
	end

	actionBtn.MouseButton1Click:Connect(function()
		-- The server decides; the view waits for the next snapshot.
		if actionRun then
			actionRun()
		end
	end)

	------------------------------------------------------------------- grid --
	local function matches(row)
		local q = state.search
		if q == "" then
			return true
		end
		local hay = string.lower(tostring(row.name) .. " " .. tostring(row.sub or "")
			.. " " .. tostring(row.rarity or ""))
		return string.find(hay, q, 1, true) ~= nil
	end

	local function drawGrid()
		for _, c in ipairs(grid:GetChildren()) do
			if not c:IsA("UIGridLayout") then
				c:Destroy()
			end
		end
		local shown = 0
		for i, row in ipairs(state.rows) do
			if matches(row) then
				shown += 1
				local tile = UI.card(grid, UDim2.fromOffset(136, 150))
				tile.LayoutOrder = i
				tile.ZIndex = 87

				--[[
					EQUIPPED READS AS A GREEN OUTLINE AND A CHIP.

					Not a pulse: "what pays out always moves" is about claimable
					things, and something already worn is a state rather than a
					reward waiting to be taken. Pulsing a UIGridLayout cell also
					scales the tile out of its own cell -- the bug the skins
					wardrobe hit and the Studio shot caught.
				]]
				local st = tile:FindFirstChildOfClass("UIStroke")
				if st then
					st.Color = row.equipped and T.GREEN or T.OUTLINE
					st.Thickness = row.equipped and T.STROKE_THICK or T.STROKE_CHUNKY
				end

				local shot = UI.new("Frame", {
					BackgroundColor3 = T.INK,
					Position = UDim2.fromOffset(10, 10),
					Size = UDim2.fromOffset(116, 72),
					ZIndex = 88,
				}, tile)
				UI.round(shot, 8)
				local img = gearIcon(row.gearPiece) or resolveIcon(row.iconKey)
				if img then
					UI.new("ImageLabel", {
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.82, 0.82),
						ScaleType = Enum.ScaleType.Fit,
						Image = img,
						ZIndex = 89,
					}, shot)
				else
					local g = UI.text(shot, string.sub(tostring(row.name), 1, 1):upper(), 28)
					g.Size = UDim2.fromScale(1, 1)
					g.ZIndex = 89
				end

				-- Rarity on a badge, never on the card fill.
				local rar = tostring(row.rarity or "")
				if rar ~= "" then
					local badge = UI.new("Frame", {
						BackgroundColor3 = RARITY_COLOR[rar] or RARITY_COLOR.F or T.DEAD,
						Position = UDim2.fromOffset(92, 14),
						Size = UDim2.fromOffset(30, 20),
						ZIndex = 90,
					}, tile)
					UI.round(badge, 6)
					UI.edge(badge, T.OUTLINE, 2)
					UI.new("TextLabel", {
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 1),
						Font = Enum.Font.GothamBlack,
						TextSize = T.TEXT_MIN or 14,
						Text = rar,
						TextColor3 = Color3.fromRGB(20, 12, 44),
						ZIndex = 91,
					}, badge)
				end

				local nm = UI.text(tile, tostring(row.name), T.TEXT_MIN or 14)
				nm.Position = UDim2.fromOffset(10, 88)
				nm.Size = UDim2.fromOffset(116, 34)
				nm.TextXAlignment = Enum.TextXAlignment.Left
				nm.TextYAlignment = Enum.TextYAlignment.Top
				nm.TextWrapped = true
				nm.ZIndex = 88
				UI.outlineText(nm)

				local sub = UI.muted(tile, row.equipped and "EQUIPPED" or tostring(row.sub or ""),
					T.TEXT_MIN or 14)
				sub.Position = UDim2.fromOffset(10, 124)
				sub.Size = UDim2.fromOffset(116, 18)
				sub.TextXAlignment = Enum.TextXAlignment.Left
				sub.TextColor3 = row.equipped and T.GREEN or sub.TextColor3
				sub.ZIndex = 88

				local btn = UI.new("TextButton", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Text = "",
					ZIndex = 92,
				}, tile)
				UI.juice(btn)
				btn.MouseButton1Click:Connect(function()
					state.selected = row.key
					showInspect(row)
				end)
			end
		end

		empty.Visible = shown == 0
		if shown == 0 then
			local sec
			for _, s in ipairs(SECTIONS) do
				if s.key == state.section then sec = s end
			end
			empty.Text = (state.search ~= "")
				and ("Nothing in " .. string.lower(sec and sec.label or "here") .. " matches that.")
				or ("Nothing here yet. " .. (sec and sec.blurb or ""))
		end
	end

	local function rebuild()
		local snap = (opts.getSnap and opts.getSnap()) or {}
		local build = BUILDERS[state.section] or toolRows
		local okB, rows = pcall(build, snap, opts)
		if not okB then
			warn("[MineLoadoutView] " .. tostring(state.section) .. " failed: " .. tostring(rows))
			rows = {}
		end
		state.rows = rows
		-- Keep the selection across a refresh when the item is still there, so
		-- a snapshot landing mid-inspection does not close the pane.
		local keep
		for _, r in ipairs(rows) do
			if r.key == state.selected then keep = r end
		end
		if not keep then
			state.selected = nil
		end
		drawGrid()
		showInspect(keep)
	end

	-------------------------------------------------------------------- nav --
	local navBtns = {}
	--[[
		The gold outline marks the live section, and it is painted from
		`state.section` rather than from whichever button was clicked.

		Those are the same thing when a player taps, and NOT the same thing when
		the host calls setSection -- which is how the Studio shot caught the
		first version sitting on "Gear" with "Tools" still outlined. One painter,
		driven by the state, cannot drift from it.
	]]
	local function paintNav()
		for key, b in pairs(navBtns) do
			local s = b:FindFirstChildOfClass("UIStroke")
			if s then
				s.Color = (key == state.section) and T.GOLD or T.OUTLINE
				s.Thickness = (key == state.section) and T.STROKE_THICK or T.STROKE_CHUNKY
			end
		end
	end
	for i, sec in ipairs(SECTIONS) do
		-- UI.button juices it already; a second call would double the scale.
		local b = UI.button(nav, sec.label, UDim2.new(1, 0, 0, 42), nil,
			sec.key == state.section, "blue")
		b.LayoutOrder = i
		b.ZIndex = 87
		navBtns[sec.key] = b
		b.MouseButton1Click:Connect(function()
			state.section = sec.key
			state.selected = nil
			paintNav()
			rebuild()
		end)
	end
	paintNav()

	search:GetPropertyChangedSignal("Text"):Connect(function()
		state.search = string.lower(search.Text or "")
		drawGrid()
	end)

	--[[
		RESPONSIVE. Below roughly a phone's width three columns stop being three
		columns -- the grid ends up two cells wide with an inspection pane too
		narrow to read -- so the nav collapses to a strip and the cells shrink.
		Driven off the panel's own AbsoluteSize rather than the viewport, since
		the host scales this panel.
	]]
	local function relayout()
		local w = root.AbsoluteSize.X
		if w <= 0 then
			return
		end
		local tight = w < 620
		gridLayout.CellSize = tight and UDim2.fromOffset(104, 132) or UDim2.fromOffset(136, 150)
		local navW = tight and 0.22 or NAV_W
		local insW = tight and 0.30 or INSPECT_W
		nav.Size = UDim2.new(navW, -8, 1, 0)
		mid.Position = UDim2.fromScale(navW, 0)
		mid.Size = UDim2.new(1 - navW - insW, -8, 1, 0)
		inspect.Position = UDim2.new(1 - insW, 0, 0, 0)
		inspect.Size = UDim2.new(insW, 0, 1, 0)
	end
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	relayout()

	local ctl = { root = root }

	function ctl.refresh()
		rebuild()
		relayout()
	end

	function ctl.setSection(key)
		if BUILDERS[key] then
			state.section = key
			state.selected = nil
			paintNav()
			rebuild()
		end
	end

	showInspect(nil)
	rebuild()
	return ctl
end

return MineLoadoutView
