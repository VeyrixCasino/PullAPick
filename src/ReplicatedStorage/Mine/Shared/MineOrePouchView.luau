--[[
	MineOrePouchView: the ore pouch panel. What you are carrying, what it is
	worth, and what you are willing to part with.

	One list, four controls. The list is every ore you hold; the controls are a
	FILTER top-right, a SORT beside it, a LOCK per row, and SELL ALL across the
	bottom.

	Rules this file does not get to bend:

	1. NO PRICING HERE. MineOrePouch owns gemValue, stackValue, capacity and
	   upgradeCost, and the server quotes from the same functions. A panel that
	   does its own arithmetic eventually disagrees with the server, and the
	   player believes the panel.

	2. SELL ALL ASKS FIRST, and the numbers it asks with come from the SERVER.
	   The panel does not price its own confirmation: it sends the verb without
	   `confirm`, the server prices the sale and sends the figures back, and the
	   dialog shows those. So the number a player agrees to is the number they
	   are paid, by construction rather than by the two sides agreeing to round
	   the same way.

	3. ROWS ARE KEYED BY ORE ID, never by position. The list reorders on every
	   sort, filter and sale, and an index captured at draw time names a
	   different ore by the time it is tapped.

	DEFAULT SORT IS DESCENDING RARITY, because the pouch is read top-down when
	deciding what to sell: the valuable rows are the decision and the common ones
	are noise. Within a band it falls back to depth, then name, so the order is
	stable -- a list that reshuffles between frames is unreadable however it is
	sorted.

	SELL UP TO (owner, 2026-10-19; wiki/open-questions.md §0e). SELL ALL has a
	ceiling picker: Common / +Uncommon / +Rare / +Epic / +Legendary /
	Everything (MineOrePouch.SELL_UP_TO and SELL_UP_TO_LABEL). The pick rides
	`sellAllOres { upTo }`, which is how the server remembers it
	(p.settings.oreSellUpTo, read back as `sellUpTo`); it still asks first with
	the server's numbers, and a locked ore is never sold.

	CANDY ORES (same day). The Candy Crypt's candy ores take pouch room, so they
	are shown, in their own Halloween section below the ores: each with a tick
	box, and SELL TICKED FOR CANDY, which asks the server
	(`cryptSellCandyOres`), shows the server's figures
	(`cryptSellCandyConfirm`) and only then sells (`confirm = true`). A LOCKED
	candy ore cannot be ticked and is never sent, so it is never sold.

	PROPOSED (2026-10-19): SELL UP TO as one chip that cycles on each tap (a
	row of six chips cost a phone's ore list most of its height), its place
	beside SELL ALL, and the candy section's layout and wording.
]]
local MineOrePouchView = {}

local RS = game:GetService("ReplicatedStorage")
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared:WaitForChild("MineConfig"))
local OreIcons = require(shared:WaitForChild("MineOreIcons"))
local Pouch = require(shared:WaitForChild("MineOrePouch"))
local Abbrev = require(shared:WaitForChild("MineAbbrev"))
local T = require(shared:WaitForChild("MineTheme"))
local UI = require(shared:WaitForChild("MineUI"))
-- The candy section wears the Candy Crypt's theme: candy ores belong to it.
local HALLOWEEN = T.EVENT_THEMES and T.EVENT_THEMES.halloween or T.LIFTED

local BG = T.BG or Color3.fromRGB(22, 22, 28)
local BG2 = T.BG2
local BG3 = T.BG3
local TEXT = T.TEXT
local MUTED = T.MUTED
local GOLD = T.GOLD
local GREEN = T.GREEN
local GEM = T.GEM or Color3.fromRGB(120, 200, 255)
local RED = T.RED or Color3.fromRGB(190, 92, 92)
local FONT = Enum.Font.GothamBold
local FONT_M = Enum.Font.Gotham

local ROW_H = 46
local HEAD_H = 92
local FOOT_H = 58

-- Band ink. Local because there is no central table for ore bands, and a
-- hard-coded colour in eight places is how they drift apart.
local BAND_INK = {
	Common = Color3.fromRGB(176, 176, 184),
	Uncommon = Color3.fromRGB(124, 206, 124),
	Rare = Color3.fromRGB(104, 168, 255),
	Epic = Color3.fromRGB(190, 130, 255),
	Legendary = Color3.fromRGB(255, 190, 86),
	Mythic = Color3.fromRGB(255, 124, 160),
	Divine = Color3.fromRGB(150, 255, 236),
	Exotic = Color3.fromRGB(255, 108, 96),
}

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

-- Two decimals at most, floored, suffixed the whole way up. The same
-- function the server quotes with, so a price reads identically on both sides.
local function num(n)
	return Abbrev.currency(n)
end

--[[
	The filter cycles rather than opening a menu: All, then each band that the
	player actually HOLDS something of, then back to All.

	Bands you hold nothing of are skipped, because a filter that can land on an
	empty list is a filter that looks broken. With one tap per step and at most
	nine stops it is faster than a dropdown and needs no dismiss gesture.
]]
local function filterCycle(ores)
	local steps = { "" }
	local has = {}
	for id, n in pairs(ores or {}) do
		if (tonumber(n) or 0) > 0 then
			local ore = C.oreById(id)
			if ore and ore.band then
				has[ore.band] = true
			end
		end
	end
	for _, band in ipairs(C.ORE_BAND_ORDER or {}) do
		if has[band] then
			table.insert(steps, band)
		end
	end
	return steps
end

function MineOrePouchView.mount(parent, opts)
	opts = opts or {}

	local root = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, parent)

	-- View state. Outside render() so a snapshot arriving mid-decision does not
	-- throw the player back to the default sort.
	--   upTo     the SELL UP TO pick made on this screen; nil reads the server's
	--            remembered one (snapshot `sellUpTo`), so a snapshot never
	--            undoes a pick the player just made
	--   ticked   candy ores ticked for sale, by ore id
	--   confirm  the open dialog: { kind = "gems" | "candy", info, ids }
	local ui = {
		sort = "rarity",
		band = "",
		confirm = nil,
		upTo = nil,
		ticked = {},
		candyAsk = nil,
	}

	local function snap()
		return (opts.getSnap and opts.getSnap()) or {}
	end

	--------------------------------------------------------------------------
	-- HEADER: the pouch itself, how full it is, and the next rung.
	--------------------------------------------------------------------------
	local head = round(mk("Frame", {
		BackgroundColor3 = BG2,
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.new(1, -24, 0, HEAD_H),
	}, root), 10)

	local pouchName = label(head, "", 15, GOLD, UDim2.fromOffset(14, 10),
		UDim2.new(0.5, -20, 0, 18), FONT)
	local fillText = label(head, "", 12, MUTED, UDim2.fromOffset(14, 32),
		UDim2.new(0.5, -20, 0, 15))

	-- The fill bar. A number alone does not answer "am I about to start losing
	-- ore"; a bar does, at a glance, which is the question this panel is for.
	local barBack = round(mk("Frame", {
		BackgroundColor3 = BG3,
		Position = UDim2.fromOffset(14, 54),
		Size = UDim2.new(0.5, -20, 0, 10),
	}, head), 5)
	local barFill = round(mk("Frame", {
		BackgroundColor3 = GREEN,
		Size = UDim2.fromScale(0, 1),
	}, barBack), 5)

	local upgradeBtn = round(mk("TextButton", {
		BackgroundColor3 = BG3,
		AutoButtonColor = true,
		Text = "",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 44),
		Size = UDim2.fromOffset(196, 36),
	}, head), 8)
	local upgradeTop = label(upgradeBtn, "", 12, TEXT, UDim2.fromOffset(10, 4),
		UDim2.new(1, -20, 0, 15), FONT)
	local upgradeSub = label(upgradeBtn, "", 11, MUTED, UDim2.fromOffset(10, 19),
		UDim2.new(1, -20, 0, 13))
	upgradeBtn.MouseButton1Click:Connect(function()
		if opts.onUpgradePouch then
			opts.onUpgradePouch()
		end
	end)

	--------------------------------------------------------------------------
	-- FILTER, top-right, with SORT beside it.
	--------------------------------------------------------------------------
	local filterBtn = round(mk("TextButton", {
		BackgroundColor3 = BG3,
		AutoButtonColor = true,
		Text = "",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 8),
		Size = UDim2.fromOffset(120, 28),
		ZIndex = 2,
	}, head), 8)
	local filterLbl = label(filterBtn, "", 12, TEXT, UDim2.fromOffset(0, 0),
		UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center)

	local sortBtn = round(mk("TextButton", {
		BackgroundColor3 = BG3,
		AutoButtonColor = true,
		Text = "",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -142, 0, 8),
		Size = UDim2.fromOffset(120, 28),
		ZIndex = 2,
	}, head), 8)
	local sortLbl = label(sortBtn, "", 12, TEXT, UDim2.fromOffset(0, 0),
		UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center)

	--------------------------------------------------------------------------
	-- THE LIST.
	--------------------------------------------------------------------------
	local list = mk("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, HEAD_H + 18),
		Size = UDim2.new(1, -24, 1, -(HEAD_H + 18 + FOOT_H + 16)),
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, root)
	mk("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)

	--------------------------------------------------------------------------
	-- SELL ALL, across the bottom, with SELL UP TO beside it.
	--------------------------------------------------------------------------
	local sellAll = round(mk("TextButton", {
		BackgroundColor3 = Color3.fromRGB(44, 34, 34),
		AutoButtonColor = true,
		Text = "",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -10),
		Size = UDim2.new(0.64, -18, 0, FOOT_H - 12),
	}, root), 10)
	local sellAllTop = label(sellAll, "SELL ALL", 14, RED, UDim2.fromOffset(0, 6),
		UDim2.fromScale(1, 0), FONT, Enum.TextXAlignment.Center)
	sellAllTop.Size = UDim2.new(1, 0, 0, 17)
	local sellAllSub = label(sellAll, "", 11, MUTED, UDim2.fromOffset(6, 24),
		UDim2.new(1, -12, 0, 14), FONT_M, Enum.TextXAlignment.Center)

	--[[
		SELL UP TO: the ceiling SELL ALL stops at, one of MineOrePouch.SELL_UP_TO,
		captioned by SELL_UP_TO_LABEL. A chip that CYCLES on each tap, like this
		panel's filter and sort: on a phone the pouch is under 300 px tall, and a
		row of six chips would have cost the ore list most of its height.
	]]
	local upToBtn = round(mk("TextButton", {
		Name = "SellUpTo",
		BackgroundColor3 = BG3,
		AutoButtonColor = true,
		Text = "",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -10),
		Size = UDim2.new(0.36, -6, 0, FOOT_H - 12),
	}, root), 10)
	label(upToBtn, "SELL UP TO", 11, MUTED, UDim2.fromOffset(0, 5),
		UDim2.new(1, 0, 0, 14), FONT, Enum.TextXAlignment.Center)
	local upToVal = label(upToBtn, "", 15, GOLD, UDim2.fromOffset(4, 21),
		UDim2.new(1, -8, 0, 19), FONT, Enum.TextXAlignment.Center)
	local render

	-- The ceiling in force: the pick made here, else the one the server keeps.
	local function upToNow(s)
		local u = ui.upTo or (s and s.sellUpTo) or "Everything"
		return Pouch.validSellUpTo(u) and u or "Everything"
	end

	upToBtn.MouseButton1Click:Connect(function()
		local order = Pouch.SELL_UP_TO
		local at = table.find(order, upToNow(snap())) or #order
		ui.upTo = order[(at % #order) + 1]
		render()
	end)

	--------------------------------------------------------------------------
	-- THE CONFIRMATION. Built once, shown on demand, for both sales: SELL ALL
	-- (gems) and SELL TICKED FOR CANDY. Every figure in it is the server's.
	--
	-- It covers the panel on purpose: these are the irreversible buttons here,
	-- and a dialog that leaves the list tappable behind it invites the second
	-- tap that the first one was supposed to stop.
	--------------------------------------------------------------------------
	local veil = mk("TextButton", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 40,
	}, root)
	local box = round(mk("Frame", {
		BackgroundColor3 = BG,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(380, 250),
		ZIndex = 41,
	}, veil), 12)
	local boxEdge = mk("UIStroke", { Color = RED, Thickness = 1, Transparency = 0.4 }, box)
	local confirmTitle = label(box, "SELL ALL ORE?", 15, RED, UDim2.fromOffset(16, 14),
		UDim2.new(1, -32, 0, 18), FONT)
	local confirmBody = label(box, "", 12, TEXT, UDim2.fromOffset(16, 40),
		UDim2.new(1, -32, 0, 136))
	confirmBody.TextWrapped = true
	confirmBody.TextYAlignment = Enum.TextYAlignment.Top
	confirmBody.TextTruncate = Enum.TextTruncate.None

	local noBtn = round(mk("TextButton", {
		BackgroundColor3 = BG3, AutoButtonColor = true, Text = "KEEP IT",
		TextColor3 = TEXT, TextSize = 13, Font = FONT,
		Position = UDim2.new(0, 16, 1, -52),
		Size = UDim2.new(0.5, -22, 0, 36),
		ZIndex = 42,
	}, box), 8)
	local yesBtn = round(mk("TextButton", {
		BackgroundColor3 = Color3.fromRGB(96, 42, 42), AutoButtonColor = true,
		Text = "SELL IT ALL", TextColor3 = TEXT, TextSize = 13, Font = FONT,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 1, -52),
		Size = UDim2.new(0.5, -22, 0, 36),
		ZIndex = 42,
	}, box), 8)

	local function closeConfirm()
		ui.confirm = nil
		veil.Visible = false
	end

	veil.MouseButton1Click:Connect(closeConfirm)
	noBtn.MouseButton1Click:Connect(closeConfirm)
	yesBtn.MouseButton1Click:Connect(function()
		local c = ui.confirm
		closeConfirm()
		if not c then
			return
		end
		if c.kind == "candy" then
			-- The same ores the server priced, with confirm. Locked ones were
			-- never in the list (they cannot be ticked), so none is sold.
			if opts.onSellCandy and type(c.ids) == "table" and #c.ids > 0 then
				opts.onSellCandy(c.ids, true)
			end
			ui.ticked = {}
			ui.candyAsk = nil
		elseif opts.onSellAll then
			-- With confirm and the same ceiling. The server re-prices from the
			-- same plan function, so a sale that grew between the ask and the
			-- answer pays the new total rather than the quoted one.
			local info = c.info or {}
			opts.onSellAll(true, info.upTo or upToNow(nil))
		end
	end)

	--------------------------------------------------------------------------
	local rows = {}

	local function rowFor(r)
		local row = rows[r.id]
		if not row then
			local btn = round(mk("Frame", {
				BackgroundColor3 = BG2,
				Size = UDim2.new(1, 0, 0, ROW_H),
			}, list), 8)
			--[[
				THE ORE'S OWN ART, NOT A COLOURED SQUARE.

				Owner, 2026-10-06, on the two ore images per ore: "dont use those,
				only use the cases". So the row carries the CASE render.

				The frame stays underneath as the fallback tint: an ore with no
				uploaded art, or art still clearing moderation, shows the colour
				square this row used to be rather than a blank hole.
			]]
			local swatch = round(mk("Frame", {
				BackgroundColor3 = Color3.fromRGB(120, 120, 120),
				Position = UDim2.fromOffset(10, 11),
				Size = UDim2.fromOffset(24, 24),
			}, btn), 6)
			local swatchArt = mk("ImageLabel", {
				BackgroundTransparency = 1,
				Image = "",
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(1, 1),
			}, swatch)
			local name = label(btn, "", 13, TEXT, UDim2.fromOffset(44, 6),
				UDim2.new(0.42, -44, 0, 16), FONT)
			local sub = label(btn, "", 11, MUTED, UDim2.fromOffset(44, 24),
				UDim2.new(0.42, -44, 0, 14))
			local amount = label(btn, "", 13, TEXT, UDim2.new(0.42, 0, 0, 6),
				UDim2.new(0.18, 0, 0, 16), FONT, Enum.TextXAlignment.Right)
			local worth = label(btn, "", 11, GEM, UDim2.new(0.42, 0, 0, 24),
				UDim2.new(0.18, 0, 0, 14), FONT_M, Enum.TextXAlignment.Right)
			local lockBtn = round(mk("TextButton", {
				BackgroundColor3 = BG3, AutoButtonColor = true, Text = "",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -104, 0.5, 0),
				Size = UDim2.fromOffset(86, 30),
			}, btn), 7)
			local lockLbl = label(lockBtn, "", 11, MUTED, UDim2.fromOffset(0, 0),
				UDim2.fromScale(1, 1), FONT, Enum.TextXAlignment.Center)
			local sellBtn = round(mk("TextButton", {
				BackgroundColor3 = BG3, AutoButtonColor = true, Text = "SELL",
				TextColor3 = GEM, TextSize = 12, Font = FONT,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(88, 30),
			}, btn), 7)
			row = {
				frame = btn, swatch = swatch, swatchArt = swatchArt, name = name, sub = sub,
				amount = amount, worth = worth,
				lockBtn = lockBtn, lockLbl = lockLbl, sellBtn = sellBtn,
			}
			-- Captured by ORE ID, not by index: the list reorders on every sort,
			-- filter and sale, and an index would name a different ore by the
			-- time it is tapped.
			local id = r.id
			lockBtn.MouseButton1Click:Connect(function()
				if opts.onToggleLock then
					opts.onToggleLock(id)
				end
			end)
			sellBtn.MouseButton1Click:Connect(function()
				if opts.onSellOre then
					opts.onSellOre(id)
				end
			end)
			rows[r.id] = row
		end
		return row
	end

	--------------------------------------------------------------------------
	-- CANDY ORES: their own section at the foot of the list, in the Candy
	-- Crypt's Halloween theme (they belong to the event). Built once, rows
	-- keyed by ore id like the ore rows, hidden rather than destroyed.
	--------------------------------------------------------------------------
	local function keep(inst)
		inst:SetAttribute("MineUIAdopted", true)
		return inst
	end

	local candyHead = UI.themeCard(list, HALLOWEEN, UDim2.new(1, 0, 0, 58), nil, "SHELL_HI")
	candyHead.Name = "CandyHead"
	candyHead.LayoutOrder = 10000
	candyHead.Visible = false
	local candyTitle = UI.themeText(candyHead, "🍬 CANDY ORES", 16, HALLOWEEN, "TEXT")
	candyTitle.Position = UDim2.fromOffset(12, 6)
	candyTitle.Size = UDim2.new(1, -24, 0, 22)
	local candyHint = UI.themeText(candyHead, "Tick them to sell for candy. Locked ones are never sold.",
		14, HALLOWEEN, "MUTED", T.FONT_M)
	candyHint.Position = UDim2.fromOffset(12, 30)
	candyHint.Size = UDim2.new(1, -24, 0, 20)
	candyHint.TextTruncate = Enum.TextTruncate.AtEnd

	local candyFoot = keep(mk("Frame", {
		Name = "CandyFoot",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 58),
		LayoutOrder = 20000,
		Visible = false,
	}, list))
	local candySell, candySellL = UI.themeButton(candyFoot, "SELL TICKED FOR CANDY", UDim2.new(1, -8, 0, 52),
		UDim2.fromOffset(4, 3), HALLOWEEN, "off")
	candySellL.TextSize = 17
	local candyJob = "off"

	local candyRows = {}
	local function candyRowFor(r)
		local row = candyRows[r.id]
		if row then
			return row
		end
		local f = keep(round(mk("Frame", { Size = UDim2.new(1, 0, 0, ROW_H) }, list), 8))
		UI.tint(f, HALLOWEEN, "SHELL")
		UI.themeStroke(f, HALLOWEEN, "EDGE", 1.5)
		local tick = keep(round(mk("TextButton", {
			Name = "Tick",
			AutoButtonColor = false,
			Text = "",
			Font = FONT,
			TextSize = 18,
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.fromOffset(30, 30),
		}, f), 8))
		UI.tint(tick, HALLOWEEN, "FACE", "ON_FACE")
		UI.themeStroke(tick, HALLOWEEN, "OUTLINE", 2)
		local swatch = keep(round(mk("Frame", {
			Position = UDim2.fromOffset(46, 11),
			Size = UDim2.fromOffset(24, 24),
		}, f), 6))
		local name = UI.themeText(f, "", 13, HALLOWEEN, "TEXT")
		name.Position = UDim2.fromOffset(78, 6)
		name.Size = UDim2.new(0.42, -78, 0, 16)
		name.TextTruncate = Enum.TextTruncate.AtEnd
		local sub = UI.themeText(f, "", 11, HALLOWEEN, "MUTED", FONT_M)
		sub.Position = UDim2.fromOffset(78, 24)
		sub.Size = UDim2.new(0.42, -78, 0, 14)
		sub.TextTruncate = Enum.TextTruncate.AtEnd
		local amount = UI.themeText(f, "", 13, HALLOWEEN, "TEXT")
		amount.Position = UDim2.new(0.42, 0, 0, 6)
		amount.Size = UDim2.new(0.18, 0, 0, 16)
		amount.TextXAlignment = Enum.TextXAlignment.Right
		local worth = UI.themeText(f, "", 11, HALLOWEEN, "ACCENT", FONT_M)
		worth.Position = UDim2.new(0.42, 0, 0, 24)
		worth.Size = UDim2.new(0.18, 0, 0, 14)
		worth.TextXAlignment = Enum.TextXAlignment.Right
		local lockBtn = keep(round(mk("TextButton", {
			AutoButtonColor = true, Text = "",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(96, 30),
		}, f), 7))
		UI.tint(lockBtn, HALLOWEEN, "SHELL_HI")
		local lockLbl = UI.themeText(lockBtn, "", 11, HALLOWEEN, "MUTED")
		lockLbl.TextXAlignment = Enum.TextXAlignment.Center
		lockLbl.Size = UDim2.fromScale(1, 1)
		row = { frame = f, tick = tick, swatch = swatch, name = name, sub = sub, amount = amount, worth = worth, lockLbl = lockLbl }
		-- By ORE ID, as above.
		local id = r.id
		tick.MouseButton1Click:Connect(function()
			if row.locked then
				return
			end
			ui.ticked[id] = (not ui.ticked[id]) or nil
			render()
		end)
		lockBtn.MouseButton1Click:Connect(function()
			if opts.onToggleLock then
				opts.onToggleLock(id)
			end
		end)
		candyRows[id] = row
		return row
	end

	-- The candy ores to sell: ticked, held and NOT locked, in ladder order.
	local function tickedIds(candy)
		local ids = {}
		for _, r in ipairs(candy) do
			if ui.ticked[r.id] and not r.locked and r.n > 0 then
				table.insert(ids, r.id)
			end
		end
		return ids
	end

	candySell.MouseButton1Click:Connect(function()
		local s = snap()
		local candy = {}
		for _, r in ipairs(Pouch.rows(s.ores or {}, s.oreLocks or {}, { includeCandy = true, sort = "tier" })) do
			if r.candy then
				table.insert(candy, r)
			end
		end
		local ids = tickedIds(candy)
		if #ids == 0 or not opts.onSellCandy then
			return
		end
		-- The ASK: the server prices it and answers with cryptSellCandyConfirm.
		ui.candyAsk = ids
		opts.onSellCandy(ids, false)
	end)

	function render()
		local s = snap()
		local pouch = s.orePouch or {}
		local ores = s.ores or {}
		local locks = s.oreLocks or {}

		--------------------------------------------------------------------
		-- Header.
		--------------------------------------------------------------------
		local cap = math.max(1, tonumber(pouch.cap) or Pouch.capacity(s.orePouchTier))
		local held = math.max(0, tonumber(pouch.held) or Pouch.held(ores))
		pouchName.Text = tostring(pouch.name or "Ore Pouch")
		fillText.Text = string.format("%s / %s ore", num(held), num(cap))
		local frac = math.clamp(held / cap, 0, 1)
		barFill.Size = UDim2.fromScale(frac, 1)
		-- Amber past three quarters, red when full: the bar is here to warn, and
		-- a green bar at 99% does not.
		barFill.BackgroundColor3 = (frac >= 1 and RED)
			or (frac >= 0.75 and GOLD)
			or GREEN

		local cost = pouch.upgradeCost
		if cost then
			local gems = tonumber(s.gems) or 0
			upgradeTop.Text = "UPGRADE  " .. num(cost) .. " gems"
			upgradeSub.Text = string.format("%s · holds %s",
				tostring(pouch.nextName or "Next pouch"), num(pouch.nextCap or cap))
			local afford = gems >= cost
			upgradeTop.TextColor3 = afford and GEM or MUTED
			upgradeBtn.BackgroundColor3 = afford and Color3.fromRGB(34, 46, 58) or BG3
		else
			upgradeTop.Text = "BIGGEST POUCH"
			upgradeTop.TextColor3 = GOLD
			upgradeSub.Text = "nothing left to upgrade"
			upgradeBtn.BackgroundColor3 = BG3
		end

		--------------------------------------------------------------------
		-- Filter and sort.
		--------------------------------------------------------------------
		local steps = filterCycle(ores)
		-- A band you have emptied since choosing it drops out of the cycle, so
		-- fall back to All rather than showing a list that cannot have rows.
		local found = false
		for _, b in ipairs(steps) do
			if b == ui.band then
				found = true
				break
			end
		end
		if not found then
			ui.band = ""
		end
		filterLbl.Text = (ui.band == "") and "ALL ORES" or string.upper(ui.band)
		filterLbl.TextColor3 = (ui.band == "") and TEXT or (BAND_INK[ui.band] or TEXT)
		sortLbl.Text = "SORT: " .. string.upper(Pouch.sortLabel(ui.sort))

		--------------------------------------------------------------------
		-- Rows.
		--------------------------------------------------------------------
		local wanted = Pouch.rows(ores, locks, { sort = ui.sort, band = ui.band })
		local live = {}
		for i, r in ipairs(wanted) do
			live[r.id] = true
			local row = rowFor(r)
			local ore = C.oreById(r.id)
			row.frame.LayoutOrder = i
			row.frame.Visible = true
			row.swatch.BackgroundColor3 = (ore and ore.color) or Color3.fromRGB(120, 120, 120)
			-- The ore's own render. The colour square stays behind it as the
			-- fallback, so an ore with no art still reads as itself.
			local art = ore and OreIcons.icon(ore.id)
			row.swatchArt.Image = art or ""
			row.swatchArt.BackgroundTransparency = 1
			row.name.Text = r.name
			row.name.TextColor3 = BAND_INK[r.band or ""] or TEXT
			row.sub.Text = string.format("%s · tier %d · %s gems each",
				tostring(r.band or "?"), r.tier, num(r.unit))
			row.amount.Text = num(r.n)
			row.worth.Text = num(r.value) .. " gems"
			row.lockLbl.Text = r.locked and "LOCKED" or "LOCK"
			row.lockLbl.TextColor3 = r.locked and GOLD or MUTED
			row.lockBtn.BackgroundColor3 = r.locked and Color3.fromRGB(52, 44, 24) or BG3
		end
		-- Rows for ore no longer held are hidden, not destroyed: the panel is
		-- re-rendered on every snapshot and rebuilding 82 frames ten times a
		-- second is how a panel starts dropping frames while digging.
		for id, row in pairs(rows) do
			if not live[id] then
				row.frame.Visible = false
			end
		end

		--------------------------------------------------------------------
		-- Candy ores, in their own section. Values are MineOrePouch's (the
		-- same MineConfig.candyOreValue the server sells at); the sale's
		-- figures come back from the server before anything is sold.
		--------------------------------------------------------------------
		local candy = {}
		for _, r in ipairs(Pouch.rows(ores, locks, { includeCandy = true, sort = ui.sort })) do
			if r.candy then
				table.insert(candy, r)
			end
		end
		local liveCandy = {}
		for i, r in ipairs(candy) do
			liveCandy[r.id] = true
			local row = candyRowFor(r)
			local def = C.candyOreById and C.candyOreById(r.id)
			row.locked = r.locked
			if r.locked then
				-- A locked candy ore is never sold: it cannot stay ticked.
				ui.ticked[r.id] = nil
			end
			row.frame.LayoutOrder = 10000 + i
			row.frame.Visible = true
			row.swatch.BackgroundColor3 = (def and def.color) or HALLOWEEN.ACCENT
			row.tick.Text = r.locked and "🔒" or (ui.ticked[r.id] and "✓" or "")
			row.name.Text = r.name
			row.sub.Text = string.format("%s · %s candy each", tostring(r.band or "?"), num(r.candyUnit or 0))
			row.amount.Text = num(r.n)
			row.worth.Text = num(r.candyValue or 0) .. " candy"
			row.lockLbl.Text = r.locked and "LOCKED" or "LOCK"
		end
		for id, row in pairs(candyRows) do
			if not liveCandy[id] then
				row.frame.Visible = false
				ui.ticked[id] = nil
			end
		end
		candyHead.Visible = #candy > 0
		candyFoot.Visible = #candy > 0
		local ids = tickedIds(candy)
		local pick = 0
		for _, r in ipairs(candy) do
			if ui.ticked[r.id] and not r.locked then
				pick += r.candyValue or 0
			end
		end
		local job = (#ids > 0) and "primary" or "off"
		candySellL.Text = (#ids > 0) and string.format("SELL %d TICKED · about %s candy", #ids, num(pick))
			or "TICK CANDY ORES TO SELL THEM FOR CANDY"
		if job ~= candyJob then
			candyJob = job
			UI.setJob(candySell, HALLOWEEN, job)
		end

		--------------------------------------------------------------------
		-- Sell up to.
		--------------------------------------------------------------------
		local upTo = upToNow(s)
		upToVal.Text = string.upper(Pouch.SELL_UP_TO_LABEL[upTo] or upTo) .. "  ▶"
		upToVal.TextColor3 = (upTo == "Everything") and TEXT or GOLD

		--------------------------------------------------------------------
		-- Sell All. Priced here only as a PREVIEW of what it would take; the
		-- figure that governs comes back from the server.
		--------------------------------------------------------------------
		local plan = Pouch.sellAllPlan(ores, locks, upTo)
		local lockedN = 0
		for _ in pairs(locks) do
			lockedN += 1
		end
		local ceiling = (upTo == "Everything") and "" or ("   ·   up to " .. (Pouch.SELL_UP_TO_LABEL[upTo] or upTo))
		if plan.units <= 0 then
			sellAllSub.Text = (((plan.aboveUnits or 0) > 0) and ("nothing at or below " .. (Pouch.SELL_UP_TO_LABEL[upTo] or upTo)))
				or ((lockedN > 0) and "everything you hold is locked")
				or (((plan.candyUnits or 0) > 0) and "only candy ores: they sell for candy, below")
				or "pouch is empty"
			sellAll.BackgroundColor3 = BG2
			sellAllTop.TextColor3 = MUTED
		else
			sellAllSub.Text = string.format("%s ore → about %s gems%s%s",
				num(plan.units), num(plan.gems), ceiling,
				(lockedN > 0) and ("   ·   " .. lockedN .. " locked, kept") or "")
			sellAll.BackgroundColor3 = Color3.fromRGB(44, 34, 34)
			sellAllTop.TextColor3 = RED
		end

		local c = ui.confirm
		if c and c.kind == "candy" then
			local info = c.info or {}
			local lines = {}
			for i, r in ipairs(type(info.rows) == "table" and info.rows or {}) do
				if i > 4 then
					table.insert(lines, string.format("...and %d more", #info.rows - 4))
					break
				end
				table.insert(lines, string.format("%s %s  →  %s candy", num(r.n or 0), tostring(r.name or r.id), num(r.candy or 0)))
			end
			confirmTitle.Text = "SELL CANDY ORE FOR CANDY?"
			confirmTitle.TextColor3 = HALLOWEEN.ACCENT
			boxEdge.Color = HALLOWEEN.ACCENT
			confirmBody.Text = string.format("%s candy ore for %s candy.\n%s%s\n\nThis cannot be undone.",
				num(info.units or 0), num(info.candy or 0), table.concat(lines, "\n"),
				((tonumber(info.lockedSkipped) or 0) > 0)
					and ("\n" .. math.floor(info.lockedSkipped) .. " locked kept, as always.") or "")
			yesBtn.Text = "SELL FOR CANDY"
			yesBtn.BackgroundColor3 = Color3.fromRGB(150, 72, 18)
			veil.Visible = true
		elseif c then
			local info = c.info or {}
			local cap = info.upTo and info.upTo ~= "Everything"
				and ("Only " .. (Pouch.SELL_UP_TO_LABEL[info.upTo] or info.upTo) .. " and below.\n") or ""
			confirmTitle.Text = "SELL ALL ORE?"
			confirmTitle.TextColor3 = RED
			boxEdge.Color = RED
			confirmBody.Text = string.format(
				"%s ore from %d of your rows, for %s gems.\n%s\n%s%s\n\nThis cannot be undone.",
				num(info.units or 0), math.floor(tonumber(info.rows) or 0), num(info.gems or 0), cap,
				((tonumber(info.locked) or 0) > 0)
					and (math.floor(info.locked) .. " locked ore kept, as always.")
					or "Nothing is locked, so everything goes.",
				((tonumber(info.candyUnits) or 0) > 0)
					and ("\nYour " .. num(info.candyUnits) .. " candy ore stay: they sell for candy.") or "")
			yesBtn.Text = "SELL IT ALL"
			yesBtn.BackgroundColor3 = Color3.fromRGB(96, 42, 42)
			veil.Visible = true
		else
			veil.Visible = false
		end
	end

	filterBtn.MouseButton1Click:Connect(function()
		local steps = filterCycle(snap().ores or {})
		local at = 1
		for i, b in ipairs(steps) do
			if b == ui.band then
				at = i
				break
			end
		end
		ui.band = steps[(at % #steps) + 1] or ""
		render()
	end)

	sortBtn.MouseButton1Click:Connect(function()
		local order = Pouch.SORTS
		local at = 1
		for i, k in ipairs(order) do
			if k == ui.sort then
				at = i
				break
			end
		end
		ui.sort = order[(at % #order) + 1] or "rarity"
		render()
	end)

	sellAll.MouseButton1Click:Connect(function()
		if opts.onSellAll then
			-- No confirm flag: this is the ASK, with the ceiling (which is also
			-- how the server remembers it). The server prices it and sends the
			-- figures back through showConfirm.
			opts.onSellAll(false, upToNow(snap()))
		end
	end)

	local ctl = {}

	function ctl.refresh()
		render()
	end

	-- The host forwards the server's `confirmSellAll` here.
	function ctl.showConfirm(info)
		ui.confirm = {
			kind = "gems",
			info = (type(info) == "table") and info or { units = 0, gems = 0, rows = 0 },
		}
		render()
	end

	-- ...and the server's `cryptSellCandyConfirm` here: the dialog shows its
	-- figures, and YES resends the ores that were asked about with confirm.
	function ctl.showCandyConfirm(info)
		ui.confirm = {
			kind = "candy",
			info = (type(info) == "table") and info or { units = 0, candy = 0, rows = {} },
			ids = ui.candyAsk or {},
		}
		render()
	end

	function ctl.destroy()
		root:Destroy()
	end

	render()
	return ctl
end

return MineOrePouchView
