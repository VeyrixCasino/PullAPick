-- MineRunesView: Enchanter UI — rune grid, fuse, sockets, scrolls.
local MineRunesView = {}

local RS = game:GetService("ReplicatedStorage")
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local Runes = require(shared:WaitForChild("MineRunes"))
local Stats = require(shared:WaitForChild("MineStats"))
local Icons = require(shared:WaitForChild("MineIcons"))
local Gear = require(shared:WaitForChild("MineGear"))

local T = require(game:GetService("ReplicatedStorage").Mine.Shared:WaitForChild("MineTheme"))
local INK = T.INK
local PANEL = T.PANEL
local CARD = T.CARD
local CARD_HI = T.CARD_HI
local TEXT = T.TEXT
local MUTED = T.MUTED
local GOLD = T.GOLD
local GEM = T.GEM
local CREDIT = T.CREDIT
local GREEN = T.GREEN
local RED = T.RED
local FONT = T.FONT
local FONT_M = T.FONT_M

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
	o.Parent = parent
	return o
end

local function round(inst, r)
	mk("UICorner", { CornerRadius = UDim.new(0, r or 10) }, inst)
	return inst
end

local function stroke(inst, thick, color, transparency)
	return mk("UIStroke", {
		Thickness = thick or 1,
		Color = color or T.LINE,
		Transparency = transparency or 0.4,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, inst)
end

local function money(n)
	-- Four significant figures, floored, same as every other wallet readout.
	local okAb, Ab = pcall(function()
		return require(script.Parent:WaitForChild("MineAbbrev"))
	end)
	if okAb and Ab and Ab.currency then
		return Ab.currency(n)
	end
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

local function statLabel(stat)
	local def = Stats.STATS[stat]
	return def and def.label or tostring(stat)
end

local function sockOf(snap, family)
	local raw = snap.toolSockets and snap.toolSockets[family]
	if type(raw) == "string" then
		return { main = raw, omni = nil, omniUnlocked = false }
	elseif type(raw) == "table" then
		return {
			main = raw.main,
			omni = raw.omni,
			omniUnlocked = raw.omniUnlocked and true or false,
		}
	end
	return { main = nil, omni = nil, omniUnlocked = false }
end

local function runeById(list, id)
	for _, r in ipairs(list or {}) do
		if r.id == id then
			return r
		end
	end
end

function MineRunesView.mount(parent, opts)
	opts = opts or {}
	local state = {
		gems = 0,
		credits = 0,
		scrolls = { white = 0, black = 0, omni = 0 },
		runes = {},
		gear = {},
		equippedGear = {},
		toolSockets = {},
		chestTools = {},
		cards = {},
		equipped = {},
		petSockets = {},
		fossilTools = {},
		tool = { family = "pickaxe" },
		runeRollPrice = Runes.ROLL_PRICE,
		gearRollPrice = 75,
	}
	local selected = {} -- up to 2 rune ids
	local selectedHats = {} -- up to 2 hat gear ids for merge
	local view = {}

	local root = mk("Frame", {
		Name = "RunesView",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 32,
	}, parent)

	-- Top bar
	local top = mk("Frame", {
		BackgroundColor3 = INK,
		BackgroundTransparency = 0.15,
		Size = UDim2.new(1, 0, 0, 56),
		ZIndex = 33,
	}, root)
	round(top, 12)

	--[[
		WHAT YOU HAVE.

		This was one run-on TextLabel -- "Gems 3.8M Credits 630 White 22 Black 5
		Omni 0" -- which is a sentence, not a wallet. Separate pills now, gems
		first and largest because gems are what a fuse actually costs.
	]]
	local walletChips = {}
	local function walletChip(id, label, colour, x, w)
		local box = mk("Frame", {
			BackgroundColor3 = T.CARD,
			Position = UDim2.fromOffset(x, 10),
			Size = UDim2.fromOffset(w, 40),
			ZIndex = 34,
		}, top)
		round(box, 10)
		stroke(box, 1, T.LINE, 0.55)
		mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT_M, TextSize = 11, TextColor3 = MUTED,
			Position = UDim2.fromOffset(9, 4), Size = UDim2.new(1, -18, 0, 13),
			TextXAlignment = Enum.TextXAlignment.Left, Text = label, ZIndex = 35,
		}, box)
		local val = mk("TextLabel", {
			BackgroundTransparency = 1, Font = FONT, TextSize = 16, TextColor3 = colour,
			Position = UDim2.fromOffset(9, 17), Size = UDim2.new(1, -18, 0, 19),
			TextXAlignment = Enum.TextXAlignment.Left, Text = "0", ZIndex = 35,
		}, box)
		walletChips[id] = val
		return val
	end
	walletChip("gems", "GEMS", GEM, 14, 118)
	walletChip("dust", "STARDUST", T.DUST, 140, 108)
	walletChip("credits", "CREDITS", CREDIT, 256, 96)
	walletChip("white", "WHITE", TEXT, 360, 74)
	walletChip("black", "BLACK", MUTED, 442, 74)
	walletChip("omni", "OMNI", GOLD, 524, 74)

	-- Opens on what you can act on, same rule as the merge screen.
	local runeFilter = "fuse"
	local runeShown = 40
	local RUNE_PAGE = 40
	local runeChips = nil

	local function actionBtn(text, x, color, fn)
		local b = mk("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, x, 0.5, 0),
			Size = UDim2.fromOffset(128, 36),
			BackgroundColor3 = color,
			Font = FONT,
			TextSize = 14,
			TextColor3 = Color3.fromRGB(20, 24, 32),
			Text = text,
			AutoButtonColor = true,
			ZIndex = 34,
		}, top)
		round(b, 10)
		b.MouseButton1Click:Connect(fn)
		return b
	end


	-- CAN FUSE / ALL, in the top bar.
	runeChips = {}
	for i, spec in ipairs({ { "fuse", "CAN FUSE", -150 }, { "all", "ALL", -14 } }) do
		local b = mk("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, spec[3], 0.5, 0),
			Size = UDim2.fromOffset(128, 36),
			BackgroundColor3 = T.CARD_HI,
			Font = FONT, TextSize = 14, TextColor3 = TEXT,
			Text = spec[2], AutoButtonColor = true, ZIndex = 34,
		}, top)
		round(b, 10)
		runeChips[spec[1]] = b
		b.MouseButton1Click:Connect(function()
			runeFilter = spec[1]
			runeShown = RUNE_PAGE
			view.paint()
		end)
	end

	-- Body split
	local body = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 64),
		Size = UDim2.new(1, 0, 1, -64),
		ZIndex = 32,
	}, root)

	local left = mk("ScrollingFrame", {
		Name = "RuneGrid",
		BackgroundColor3 = T.CARD_HI,
		BackgroundTransparency = 0.25,
		Size = UDim2.new(0.58, -6, 1, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		CanvasSize = UDim2.new(),
		BorderSizePixel = 0,
		ZIndex = 33,
	}, body)
	round(left, 14)
	local grid = mk("UIGridLayout", {
		CellSize = UDim2.fromOffset(168, 132),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, left)
	mk("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, left)

	local right = mk("Frame", {
		Name = "Detail",
		BackgroundColor3 = T.CARD_HI,
		BackgroundTransparency = 0.25,
		Position = UDim2.new(0.58, 6, 0, 0),
		Size = UDim2.new(0.42, -6, 1, 0),
		ZIndex = 33,
	}, body)
	round(right, 14)

	-- No rolling on this screen. Rolling is a thing you go somewhere to do;
	-- offering it inside the rune bench is the shop walking up to you.
	-- The server verbs (rollRune / rollGear, both with a bulk count) are
	-- still there and waiting for a home.
	local ROLLS_H = 0
	local detailScroll = mk("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 12 + ROLLS_H + 10),
		Size = UDim2.new(1, -24, 1, -24 - ROLLS_H - 10),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		BorderSizePixel = 0,
		ZIndex = 34,
	}, right)
	mk("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, detailScroll)

	local function clear(parent)
		for _, ch in ipairs(parent:GetChildren()) do
			if not ch:IsA("UIListLayout") and not ch:IsA("UIGridLayout") and not ch:IsA("UIPadding") then
				ch:Destroy()
			end
		end
	end

	local function isSelected(id)
		for _, sid in ipairs(selected) do
			if sid == id then
				return true
			end
		end
		return false
	end

	local function toggleSelect(id)
		for i, sid in ipairs(selected) do
			if sid == id then
				table.remove(selected, i)
				view.paint()
				return
			end
		end
		if #selected >= 2 then
			table.remove(selected, 1)
		end
		table.insert(selected, id)
		view.paint()
	end

	local function detailBtn(text, color, enabled, fn)
		local b = mk("TextButton", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = enabled and color or Color3.fromRGB(60, 64, 80),
			Font = FONT,
			TextSize = 15,
			TextColor3 = enabled and Color3.fromRGB(20, 24, 32) or MUTED,
			Text = text,
			AutoButtonColor = enabled,
			Active = enabled,
			ZIndex = 35,
		}, detailScroll)
		round(b, 10)
		if enabled then
			b.MouseButton1Click:Connect(fn)
		end
		return b
	end

	local function detailLabel(text, size, color)
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, size and 28 or 22),
			Font = size and FONT or FONT_M,
			TextSize = size or 14,
			TextColor3 = color or TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Text = text,
			ZIndex = 35,
			AutomaticSize = Enum.AutomaticSize.Y,
		}, detailScroll)
	end

	local function paintDetail()
		clear(detailScroll)
		local fam = (state.tool and state.tool.family) or "pickaxe"
		local sock = sockOf(state, fam)
		local scrolls = state.scrolls or {}

		detailLabel("TOOL SOCKETS · " .. string.upper(fam), 18, GOLD)
		local mainRune = runeById(state.runes, sock.main)
		local omniRune = runeById(state.runes, sock.omni)
		detailLabel(
			"Main: " .. (mainRune and Runes.describe(mainRune) or "empty"),
			nil,
			MUTED
		)
		detailLabel(
			"Omni: "
				.. (
					sock.omniUnlocked and (omniRune and Runes.describe(omniRune) or "empty")
					or "locked"
				),
			nil,
			MUTED
		)

		if sock.main then
			detailBtn("Black Scroll · unequip main (100% next)", CREDIT, (scrolls.black or 0) > 0, function()
				if opts.onBlackUnequip then
					opts.onBlackUnequip(fam, "main")
				end
			end)
			detailBtn("Destroy main socket (10g)", RED, true, function()
				if opts.onDestroySocket then
					opts.onDestroySocket(fam, "main")
				end
			end)
		end
		if sock.omni then
			detailBtn("Black Scroll · unequip omni", CREDIT, (scrolls.black or 0) > 0, function()
				if opts.onBlackUnequip then
					opts.onBlackUnequip(fam, "omni")
				end
			end)
		end
		if not sock.omniUnlocked then
			detailBtn("Apply Omniscroll · 2nd loadout", GREEN, (scrolls.omni or 0) > 0, function()
				if opts.onApplyOmni then
					opts.onApplyOmni(fam)
				end
			end)
		end

		detailLabel(" ", 10)
		if #selected == 0 then
			detailLabel("Click a rune to socket it or arm a White Scroll.\nClick any tile showing x2 or more to line up a fuse.", 16, MUTED)
			return
		end

		local a = runeById(state.runes, selected[1])
		if not a then
			selected = {}
			detailLabel("Selection cleared.", nil, MUTED)
			return
		end

		detailLabel(Runes.describe(a), 18, TEXT)
		if a.whiteArmed then
			detailLabel("WHITE ARMED — fail saves both", nil, GREEN)
		end
		if a.whiteUsed then
			detailLabel("WHITE USED — future fuses cost 5× gems", nil, RED)
		end

		detailBtn("Arm White Scroll", CREDIT, (scrolls.white or 0) > 0 and not a.whiteArmed, function()
			if opts.onArmWhite then
				opts.onArmWhite(a.id)
			end
		end)
		detailBtn("Socket → " .. fam .. " main", GREEN, true, function()
			if opts.onSocketTool then
				opts.onSocketTool(a.id, fam, "main")
			end
		end)
		if sock.omniUnlocked then
			detailBtn("Socket → " .. fam .. " omni", GREEN, true, function()
				if opts.onSocketTool then
					opts.onSocketTool(a.id, fam, "omni")
				end
			end)
		end
		-- socketPetRune needs a cardId. This used to send a rune and nothing else,
		-- so the server answered "Unknown pet" every single time and a pet rune
		-- could never actually be socketed. One button per pet on the team.
		if a.kind == "pet" and opts.onSocketPet then
			local byId = {}
			for _, c in ipairs(state.cards or {}) do
				byId[c.id] = c
			end
			local any = false
			for _, cardId in ipairs(state.equipped or {}) do
				local card = byId[cardId]
				if card then
					any = true
					local worn = (state.petSockets or {})[cardId]
					detailBtn("Socket -> " .. tostring(card.name)
						.. (worn and "  (replaces a rune)" or ""), GEM, true, function()
						opts.onSocketPet(a.id, cardId)
					end)
				end
			end
			if not any then
				detailLabel("Equip a pet first to socket this one.", nil, MUTED)
			end
		end

		-- Off-ladder tools. A flagship or a fossil tool holds one rune each, and
		-- the rune has to match the tool's family the same as anywhere else.
		for _, ct in ipairs(state.chestTools or {}) do
			if type(ct) == "table" and Runes.canSocketOnTool(a, ct.family) then
				local worn = ct.runeId and runeById(state.runes, ct.runeId)
				detailBtn("Socket → " .. tostring(ct.name)
					.. (worn and "  (replaces a rune)" or ""), GOLD, true, function()
					if opts.onSocketChestTool then
						opts.onSocketChestTool(a.id, ct.id)
					end
				end)
			end
		end
		for key, ft in pairs(state.fossilTools or {}) do
			if type(ft) == "table" and Runes.canSocketOnTool(a, ft.family) then
				local worn = ft.runeId and runeById(state.runes, ft.runeId)
				detailBtn("Socket → " .. tostring(ft.name)
					.. (worn and "  (replaces a rune)" or ""), GOLD, true, function()
					if opts.onSocketFossilTool then
						opts.onSocketFossilTool(a.id, ft.fossilId or key)
					end
				end)
			end
		end

		detailLabel("Fuse two of the same rune.", nil, MUTED)
		if #selected >= 2 then
			local b = runeById(state.runes, selected[2])
			if b then
				detailLabel(" ", 8)
				detailLabel("FUSE WITH", 16, GOLD)
				detailLabel(Runes.describe(b), 16, TEXT)
				local preview, err = Runes.fusePreview(a, b)
				if preview then
					-- The price, on its own line, signed, and red if you are
					-- short. "Cost 613 gems" buried in a sentence is how a
					-- player ends up not knowing what anything costs.
					local afford = (state.gems or 0) >= preview.cost
					detailLabel("- " .. money(preview.cost) .. " GEMS", 20,
						afford and GEM or RED)
					if not afford then
						detailLabel("You have " .. money(state.gems) .. ".", nil, RED)
					end
					detailLabel(
						string.format("%.0f%% chance  ->  T%d  +%.2f%%",
							(preview.success or 0) * 100,
							preview.tier or 1,
							(preview.pct or 0) * 100),
						nil, MUTED)
					detailLabel("A fail destroys both runes.", nil, RED)
					detailBtn("FUSE", GOLD, (state.gems or 0) >= preview.cost, function()
						if opts.onFuse then
							opts.onFuse(a.id, b.id)
						end
					end)
				else
					detailLabel(err or "Cannot fuse", nil, RED)
				end
			end
		end

		-- Hat merge: only path to multi-stat hats. Grey out faces; red-dot ready.
		detailLabel(" ", 8)
		detailLabel("MERGE HATS", 16, GOLD)
		detailLabel("Pick two hats. Faces cannot merge. Combines boosts into one piece.", nil, MUTED)
		do
			local hats = {}
			for _, piece in ipairs(state.gear or {}) do
				if Gear.isHatPiece and Gear.isHatPiece(piece) and not (Gear.isFacePiece and Gear.isFacePiece(piece)) then
					table.insert(hats, piece)
				end
			end
			table.sort(hats, function(a, b)
				return (Gear.RARITY_RANK[a.rarity] or 0) > (Gear.RARITY_RANK[b.rarity] or 0)
			end)
			if #hats < 2 then
				detailLabel(#hats == 0 and "No hats yet — open a Gear Case." or "Need two hats to merge.", nil, MUTED)
			else
				for _, piece in ipairs(hats) do
					local on = table.find(selectedHats, piece.id) ~= nil
					local can = true
					local boost = Gear.hatEffectLine and Gear.hatEffectLine(piece) or string.format("+%.0f%%", (piece.pct or 0) * 100)
					local row = mk("TextButton", {
						Size = UDim2.new(1, 0, 0, 44),
						BackgroundColor3 = on and GOLD or CARD_HI,
						BackgroundTransparency = can and 0 or 0.45,
						Text = "",
						AutoButtonColor = true,
						ZIndex = 35,
					}, detailScroll)
					round(row, 8)
					if can and not on then
						mk("Frame", {
							BackgroundColor3 = RED, BorderSizePixel = 0,
							AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 6),
							Size = UDim2.fromOffset(8, 8), ZIndex = 37,
						}, row)
					end
					local gImg = Gear.image and Gear.image(piece)
					if gImg then
						mk("ImageLabel", {
							BackgroundTransparency = 1, Image = gImg, ScaleType = Enum.ScaleType.Fit,
							Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(36, 36), ZIndex = 36,
						}, row)
					end
					mk("TextLabel", {
						BackgroundTransparency = 1, Font = FONT_M, TextSize = 13,
						TextColor3 = on and Color3.fromRGB(28, 22, 12) or TEXT,
						TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
						Text = string.format("%s  %s", tostring(piece.name or piece.setName or "Hat"), boost),
						Position = UDim2.fromOffset(gImg and 48 or 10, 0), Size = UDim2.new(1, -56, 1, 0), ZIndex = 36,
					}, row)
					row.MouseButton1Click:Connect(function()
						local idx = table.find(selectedHats, piece.id)
						if idx then
							table.remove(selectedHats, idx)
						elseif #selectedHats < 2 then
							table.insert(selectedHats, piece.id)
						else
							selectedHats[1] = selectedHats[2]
							selectedHats[2] = piece.id
						end
						paint()
					end)
				end
				if #selectedHats >= 2 and opts.onMergeHats then
					detailBtn("MERGE HATS", GOLD, true, function()
						opts.onMergeHats(selectedHats[1], selectedHats[2])
						selectedHats = {}
					end)
				end
			end
		end

		-- Compact gear
		detailLabel(" ", 8)
		detailLabel("GEAR", 16, GOLD)
		local gear = state.gear or {}
		if #gear == 0 then
			detailLabel("No gear yet", nil, MUTED)
		else
			local sel = selected[1] and runeById(state.runes, selected[1])
			for _, piece in ipairs(gear) do
				local eq = state.equippedGear and state.equippedGear[piece.slot] == piece.id
				local label = string.format(
					"%s%s %s %s +%.1f%%",
					eq and "[E] " or "",
					piece.rarity or "?",
					piece.setName or piece.setId or "?",
					Gear.SLOT_LABEL and Gear.SLOT_LABEL[piece.slot] or piece.slot or "",
					(piece.pct or 0) * 100
				)
				local row = mk("TextButton", {
					Size = UDim2.new(1, 0, 0, 48),
					BackgroundColor3 = eq and GOLD or CARD_HI,
					Text = "",
					AutoButtonColor = true,
					ZIndex = 35,
				}, detailScroll)
				round(row, 10)
				local gImg = Gear.image and Gear.image(piece)
				if gImg then
					mk("ImageLabel", {
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(8, 6),
						Size = UDim2.fromOffset(36, 36),
						Image = gImg,
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = 36,
					}, row)
				end
				mk("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(gImg and 52 or 12, 0),
					Size = UDim2.new(1, gImg and -60 or -24, 1, 0),
					Font = FONT,
					TextSize = 14,
					TextColor3 = eq and Color3.fromRGB(20, 24, 32) or TEXT,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = label,
					ZIndex = 36,
				}, row)
				row.MouseButton1Click:Connect(function()
					if opts.onEquipGear then opts.onEquipGear(piece.id) end
				end)
				local freeIdx
				for idx = 1, (piece.slotCount or 0) do
					if not (piece.sockets and piece.sockets[idx]) then
						freeIdx = idx
						break
					end
				end
				if sel and freeIdx and opts.onSocketGear then
					detailBtn("  └ Socket selected rune (slot " .. freeIdx .. ")", GREEN, true, function()
						opts.onSocketGear(piece.id, sel.id, freeIdx)
					end)
				end
			end
		end
	end

	--[[
		THE RUNE BENCH.

		It used to draw one card per loose rune in profile order: a hundred and
		twenty identical tiles, unsorted, unfiltered, with a T9 looking exactly
		like a T1. Nobody can find a fusable pair in that, which matters more
		than ever now that a fuse needs two of the SAME rune.

		So: identical runes are grouped and counted, the tile is coloured by
		tier, the list is best-first, and it opens on the groups you can
		actually fuse. Clicking a group of two or more selects BOTH at once, so
		one click arms a fuse instead of hunting for the partner.
	]]
	local TIER_COLOR = {
		Color3.fromRGB(150, 150, 158),  -- T1
		Color3.fromRGB(104, 214, 132),  -- T2
		Color3.fromRGB(96, 170, 255),   -- T3
		Color3.fromRGB(178, 122, 255),  -- T4
		Color3.fromRGB(255, 168, 72),   -- T5
		Color3.fromRGB(104, 226, 255),  -- T6
		Color3.fromRGB(255, 232, 140),  -- T7
		Color3.fromRGB(255, 96, 96),    -- T8+
	}
	local function tierColor(tier)
		return TIER_COLOR[math.clamp(math.floor(tonumber(tier) or 1), 1, #TIER_COLOR)]
	end

	local function runeGroups()
		local byKey, order = {}, {}
		for _, r in ipairs(state.runes or {}) do
			local tier = math.max(1, math.floor(tonumber(r.tier) or 1))
			local key = tostring(r.kind) .. "|" .. tier .. "|" .. tostring(r.stat)
			local g = byKey[key]
			if not g then
				g = { kind = r.kind, tier = tier, stat = r.stat, pct = r.pct or 0, ids = {}, n = 0 }
				byKey[key] = g
				order[#order + 1] = g
			end
			g.n += 1
			table.insert(g.ids, r.id)
			-- A migrated rune can sit off the tier ladder; show the best of the
			-- group so the number on the tile is never worse than what you own.
			if (r.pct or 0) > g.pct then
				g.pct = r.pct or 0
			end
		end
		-- Best first: tier, then percentage, then a stable name.
		table.sort(order, function(x, y)
			if x.tier ~= y.tier then
				return x.tier > y.tier
			end
			if x.pct ~= y.pct then
				return x.pct > y.pct
			end
			return tostring(x.stat) < tostring(y.stat)
		end)
		return order
	end

	local function paintGrid()
		clear(left)
		local groups = runeGroups()
		if #groups == 0 then
			mk("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -20, 0, 80),
				Font = FONT_M,
				TextSize = 16,
				TextColor3 = MUTED,
				Text = "No runes yet - roll one above.",
				ZIndex = 34,
			}, left)
			return
		end
		local pairable = 0
		for _, g in ipairs(groups) do
			if g.n >= 2 then
				pairable += 1
			end
		end
		local show = {}
		for _, g in ipairs(groups) do
			if runeFilter == "all" or g.n >= 2 then
				table.insert(show, g)
			end
		end
		if #show == 0 then
			mk("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -20, 0, 80),
				Font = FONT_M, TextSize = 16, TextColor3 = MUTED,
				Text = "Nothing to fuse yet - you need two of the same rune.",
				ZIndex = 34,
			}, left)
			return
		end
		local cap = math.min(#show, runeShown)
		for i = 1, cap do
			local g = show[i]
			local col = tierColor(g.tier)
			local on = isSelected(g.ids[1])
			local card = mk("TextButton", {
				BackgroundColor3 = on and CARD_HI or CARD,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = i,
				ZIndex = 34,
			}, left)
			round(card, 12)
			stroke(card, on and 3 or 2, on and GOLD or col, on and 0.05 or 0.35)

			-- Tier band: the one thing you should read from across the room.
			local band = mk("Frame", {
				BackgroundColor3 = col, BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 6), ZIndex = 35,
			}, card)
			round(band, 3)

			local iconId = Icons.resolve and Icons.resolve(g.stat) or g.stat
			local img = Icons.IMAGES and Icons.IMAGES[iconId]
			if img then
				mk("ImageLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(10, 14),
					Size = UDim2.fromOffset(32, 32),
					Image = img,
					ZIndex = 35,
				}, card)
			end
			mk("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(48, 14),
				Size = UDim2.new(1, -104, 0, 20),
				Font = FONT, TextSize = 14, TextColor3 = TEXT,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = statLabel(g.stat),
				ZIndex = 35,
			}, card)
			-- T5 in the corner, in its tier colour.
			mk("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -10, 0, 13),
				Size = UDim2.fromOffset(44, 22),
				Font = FONT, TextSize = 16, TextColor3 = col,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = "T" .. g.tier,
				ZIndex = 35,
			}, card)
			mk("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(10, 52),
				Size = UDim2.new(1, -20, 0, 22),
				Font = FONT, TextSize = 18, TextColor3 = GOLD,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = string.format("+%.2f%%", (g.pct or 0) * 100),
				ZIndex = 35,
			}, card)
			mk("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(10, 76),
				Size = UDim2.new(1, -70, 0, 18),
				Font = FONT_M, TextSize = 12, TextColor3 = MUTED,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = tostring(g.kind),
				ZIndex = 35,
			}, card)
			-- How many you hold. Two or more is a fuse.
			if g.n > 1 then
				local badge = mk("Frame", {
					BackgroundColor3 = col,
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(1, -10, 1, -10),
					Size = UDim2.fromOffset(46, 24),
					ZIndex = 36,
				}, card)
				round(badge, 12)
				mk("TextLabel", {
					BackgroundTransparency = 1, Font = FONT, TextSize = 14,
					TextColor3 = Color3.fromRGB(18, 20, 26),
					Size = UDim2.fromScale(1, 1), Text = "x" .. g.n, ZIndex = 37,
				}, badge)
			end

			card.MouseButton1Click:Connect(function()
				if g.n >= 2 then
					-- Arm the whole fuse in one click.
					selected = { g.ids[1], g.ids[2] }
					view.paint()
				else
					toggleSelect(g.ids[1])
				end
			end)
		end
		if cap < #show then
			local more = mk("TextButton", {
				BackgroundColor3 = T.CARD_HI, Text = "Show more",
				Font = FONT, TextSize = 14, TextColor3 = TEXT,
				LayoutOrder = cap + 1, ZIndex = 34,
			}, left)
			round(more, 12)
			more.MouseButton1Click:Connect(function()
				runeShown += RUNE_PAGE
				view.paint()
			end)
		end
		-- The chips live in the top bar; update their counts here where the
		-- numbers are already worked out.
		if runeChips then
			runeChips.fuse.Text = "CAN FUSE  " .. pairable
			runeChips.all.Text = "ALL  " .. #groups
			for id, b in pairs(runeChips) do
				local sel = (runeFilter == "all") == (id == "all")
				b.BackgroundColor3 = sel and GOLD or T.CARD_HI
				b.TextColor3 = sel and T.ON_GOLD or TEXT
			end
		end
	end

	function view.paint()
		local scrolls = state.scrolls or {}
		walletChips.gems.Text = money(state.gems)
		walletChips.dust.Text = money(state.dust or 0)
		walletChips.credits.Text = money(state.credits)
		walletChips.white.Text = tostring(scrolls.white or 0)
		walletChips.black.Text = tostring(scrolls.black or 0)
		walletChips.omni.Text = tostring(scrolls.omni or 0)
		-- drop stale selections
		local keep = {}
		for _, id in ipairs(selected) do
			if runeById(state.runes, id) then
				table.insert(keep, id)
			end
		end
		selected = keep
		paintGrid()
		paintDetail()
	end

	function view.setState(snap)
		if not snap then
			return
		end
		state.gems = snap.gems or 0
		state.dust = snap.dust or 0
		state.credits = snap.credits or 0
		state.scrolls = snap.scrolls or { white = 0, black = 0, omni = 0 }
		-- Socketed runes drop out of the bench: they cannot be fused or rolled
		-- into anything while they are fitted, so listing them is a dead end.
		state.allRunes = snap.runes or {}
		state.runes = Runes.looseRunes(snap)
		state.gear = snap.gear or {}
		state.equippedGear = snap.equippedGear or {}
		state.toolSockets = snap.toolSockets or {}
		-- Chest flagships and fossil tools each take one rune. The server has
		-- always supported it; there was simply nowhere to click.
		state.chestTools = snap.chestTools or {}
		state.cards = snap.cards or {}
		state.equipped = snap.equipped or {}
		state.petSockets = snap.petSockets or {}
		state.fossilTools = snap.fossilTools or {}
		state.tool = snap.tool or { family = "pickaxe" }
		state.runeRollPrice = snap.runeRollPrice or Runes.ROLL_PRICE
		state.gearRollPrice = snap.gearRollPrice or 75
		if root.Visible ~= false then
			view.paint()
		end
	end

	function view.destroy()
		root:Destroy()
	end

	view.root = root
	view.paint()
	return view
end

return MineRunesView
