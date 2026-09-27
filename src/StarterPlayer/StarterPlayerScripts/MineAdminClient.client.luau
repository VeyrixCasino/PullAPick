--[[
	MineAdminClient — cosmetic admin panel only.

	Shows UI ONLY after server fires AdminReady(true) or AdminInvoke("isAdmin").
	All grants go through AdminInvoke; the server re-checks UserId allowlist.
	Non-admins never see the UI. Opening/firing remotes without allowlist fails.

	Open: F8, or the small corner button (admins only).
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local ToolIcons = require(shared:WaitForChild("MineToolIcons"))
local remotes = RS:WaitForChild("Mine"):WaitForChild("Remotes")
local readyEv = remotes:WaitForChild("AdminReady")
local invokeFn = remotes:WaitForChild("AdminInvoke")
local notifyEv = remotes:FindFirstChild("AdminNotify") or remotes:WaitForChild("AdminNotify", 8)

if notifyEv then
	notifyEv.OnClientEvent:Connect(function(msg)
		warn("[Admin] " .. tostring(msg))
	end)
end

local T = require(shared:WaitForChild("MineTheme"))
local Packs = require(shared:WaitForChild("MinePackConfig"))
local ZonePacks = nil
do
	local zp = shared:FindFirstChild("MineZonePacks")
	if zp then
		local ok, mod = pcall(require, zp)
		if ok then ZonePacks = mod end
	end
end

local GOLD = T.GOLD
local PANEL = T.PANEL
local CARD = T.CARD
local TEXT = T.TEXT
local MUTED = T.MUTED
local FONT = T.FONT
local FONT_M = T.FONT_M
local GEM = T.GEM
local BAD = T.BAD
local GOOD = T.GOOD

local authorized = false
local catalog = nil
local gui, panel, statusLbl
local open = false
local rebuildCosmeticsGrid = nil

local function round(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = inst
end

local function stroke(inst, color, thick, trans)
	local s = Instance.new("UIStroke")
	s.Color = color or GOLD
	s.Thickness = thick or 1.2
	s.Transparency = trans or 0.35
	s.Parent = inst
	return s
end

local function label(parent, text, size, color, bold)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = bold and FONT or FONT_M
	l.TextSize = size or 14
	l.TextColor3 = color or TEXT
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text or ""
	l.Size = UDim2.new(1, 0, 0, size and (size + 6) or 20)
	l.Parent = parent
	return l
end

local function mkBtn(parent, text, color, order)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.BackgroundColor3 = color or CARD
	b.TextColor3 = T.ON_GOLD or Color3.fromRGB(38, 28, 12)
	b.Font = FONT_M
	b.TextSize = 14
	b.Text = text
	b.Size = UDim2.new(0, 88, 0, 32)
	b.LayoutOrder = order or 0
	b.Parent = parent
	round(b, 8)
	stroke(b, GOLD, 1, 0.45)
	return b
end

local function mkInput(parent, placeholder, order)
	local box = Instance.new("TextBox")
	box.BackgroundColor3 = Color3.fromRGB(26, 21, 18)
	box.TextColor3 = TEXT
	box.PlaceholderColor3 = MUTED
	box.PlaceholderText = placeholder or ""
	box.Text = ""
	box.ClearTextOnFocus = false
	box.Font = FONT_M
	box.TextSize = 14
	box.Size = UDim2.new(1, 0, 0, 30)
	box.LayoutOrder = order or 0
	box.Parent = parent
	round(box, 8)
	stroke(box, GOLD, 1, 0.55)
	return box
end

local function packIdList()
	local ids = {}
	local seen = {}
	if ZonePacks and ZonePacks.PACKS then
		for id in pairs(ZonePacks.PACKS) do
			if type(id) == "string" and not seen[id] then
				seen[id] = true
				table.insert(ids, id)
			end
		end
	end
	if Packs and Packs.PACKS then
		for id in pairs(Packs.PACKS) do
			if type(id) == "string" and not seen[id] then
				seen[id] = true
				table.insert(ids, id)
			end
		end
	end
	table.sort(ids)
	-- Lucky blocks first ("id:grade"); MineAdmin grants them as blocks.
	for i, id in ipairs({ "lucky_block:F", "lucky_block:B", "super_lucky_block:C", "godly_lucky_block:A" }) do
		table.insert(ids, i, id)
	end
	return ids
end

-- Compact cycling dropdown (TextButton) — no free-typed pack ids.
local function mkDropdown(parent, options, order, placeholder)
	local opts = options or {}
	local idx = 1
	local btn = Instance.new("TextButton")
	btn.AutoButtonColor = true
	btn.BackgroundColor3 = Color3.fromRGB(26, 21, 18)
	btn.TextColor3 = TEXT
	btn.Font = FONT_M
	btn.TextSize = 13
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.LayoutOrder = order or 0
	btn.Parent = parent
	round(btn, 8)
	stroke(btn, GOLD, 1, 0.55)
	local function sync()
		if #opts == 0 then
			btn.Text = "  " .. (placeholder or "(none)")
			btn:SetAttribute("Value", "")
			return
		end
		idx = ((idx - 1) % #opts) + 1
		local v = opts[idx]
		btn.Text = string.format("  %s   (%d/%d)", v, idx, #opts)
		btn:SetAttribute("Value", v)
	end
	btn.MouseButton1Click:Connect(function()
		if #opts == 0 then return end
		idx += 1
		sync()
	end)
	btn.MouseButton2Click:Connect(function()
		if #opts == 0 then return end
		idx -= 1
		sync()
	end)
	sync()
	-- NOTE: you cannot define methods on a Roblox Instance (`function btn:X`
	-- errors with "X is not a valid member of TextButton" and killed this whole
	-- UI at build time). The selected value rides the "Value" attribute; read
	-- it with GetAttribute at the call site.
	return btn
end

local function setStatus(msg, ok)
	if not statusLbl then
		return
	end
	statusLbl.Text = msg or ""
	statusLbl.TextColor3 = ok == false and BAD or (ok and GOOD or MUTED)
end

local function invoke(action, payload)
	local ok, result = pcall(function()
		return invokeFn:InvokeServer(action, payload)
	end)
	if not ok then
		return { ok = false, err = tostring(result) }
	end
	return result or { ok = false, err = "nil" }
end

local function buildUi()
	if gui then
		return
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "MineAdminUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 120
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	local entry = Instance.new("TextButton")
	entry.Name = "AdminEntry"
	entry.AnchorPoint = Vector2.new(1, 1)
	entry.Position = UDim2.new(1, -12, 1, -150)
	entry.Size = UDim2.fromOffset(44, 44)
	entry.BackgroundColor3 = PANEL
	entry.BackgroundTransparency = 0.15
	entry.Text = "A"
	entry.TextColor3 = GOLD
	entry.Font = FONT
	entry.TextSize = 18
	entry.Parent = gui
	round(entry, 12)
	stroke(entry, GOLD, 1.4, 0.25)

	panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0.94, 0, 0.86, 0)
	local adminCap = Instance.new("UISizeConstraint")
	adminCap.MaxSize = Vector2.new(420, 900)
	adminCap.Parent = panel
	panel.BackgroundColor3 = PANEL
	panel.BackgroundTransparency = 0.08
	panel.Visible = false
	panel.Parent = gui
	round(panel, 14)
	stroke(panel, GOLD, 1.6, 0.2)

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 44, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 22, 18)),
	})
	grad.Rotation = 90
	grad.Parent = panel

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Body"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = GOLD
	scroll.Parent = panel

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = scroll

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = scroll

	local title = label(scroll, "MINE FOR CARDS · ADMIN", 20, GOLD, true)
	title.LayoutOrder = 1
	title.TextXAlignment = Enum.TextXAlignment.Center

	local sub = label(scroll, "Server grants only · F8 to toggle", 12, MUTED, false)
	sub.LayoutOrder = 2
	sub.TextXAlignment = Enum.TextXAlignment.Center

	statusLbl = label(scroll, "Ready", 12, MUTED, false)
	statusLbl.LayoutOrder = 3
	statusLbl.TextXAlignment = Enum.TextXAlignment.Center

	local function section(name, order)
		local f = Instance.new("Frame")
		f.BackgroundColor3 = CARD
		f.BackgroundTransparency = 0.2
		f.Size = UDim2.new(1, 0, 0, 0)
		f.AutomaticSize = Enum.AutomaticSize.Y
		f.LayoutOrder = order
		f.Parent = scroll
		round(f, 10)
		stroke(f, GOLD, 1, 0.6)
		local p2 = Instance.new("UIPadding")
		p2.PaddingTop = UDim.new(0, 8)
		p2.PaddingBottom = UDim.new(0, 8)
		p2.PaddingLeft = UDim.new(0, 8)
		p2.PaddingRight = UDim.new(0, 8)
		p2.Parent = f
		local l = Instance.new("UIListLayout")
		l.Padding = UDim.new(0, 4)
		l.SortOrder = Enum.SortOrder.LayoutOrder
		l.Parent = f
		label(f, name, 13, GOLD, true).LayoutOrder = 0
		return f
	end

	-- Currencies
	local curSec = section("Currencies", 10)
	local coinBox = mkInput(curSec, "Coins (+/-)", 1)
	local gemBox = mkInput(curSec, "Gems (+/-)", 2)
	local dustBox = mkInput(curSec, "Dust (+/-)", 3)
	local creditBox = mkInput(curSec, "Credits (+/-)", 4)
	local skillBox = mkInput(curSec, "Skill points (+/-)", 5)
	local temperBox = mkInput(curSec, "Temper tokens (+/-)", 6)

	local curRow = Instance.new("Frame")
	curRow.BackgroundTransparency = 1
	curRow.Size = UDim2.new(1, 0, 0, 34)
	curRow.LayoutOrder = 20
	curRow.Parent = curSec
	local curLay = Instance.new("UIListLayout")
	curLay.FillDirection = Enum.FillDirection.Horizontal
	curLay.HorizontalAlignment = Enum.HorizontalAlignment.Right
	curLay.Padding = UDim.new(0, 6)
	curLay.Parent = curRow
	local grantCur = mkBtn(curRow, "Grant $", GOLD, 1)

	-- Packs
	local packSec = section("Packs", 20)
	local packBox = mkDropdown(packSec, packIdList(), 1, "pick a pack")
	local qtyBox = mkInput(packSec, "qty (1-50)", 2)
	qtyBox.Text = "1"

	local packHint = label(packSec, "Click to cycle packs (right-click = previous)", 11, MUTED, false)
	packHint.LayoutOrder = 3
	packHint.TextWrapped = true
	packHint.AutomaticSize = Enum.AutomaticSize.Y

	local packRow = Instance.new("Frame")
	packRow.BackgroundTransparency = 1
	packRow.Size = UDim2.new(1, 0, 0, 34)
	packRow.LayoutOrder = 20
	packRow.Parent = packSec
	local packLay = Instance.new("UIListLayout")
	packLay.FillDirection = Enum.FillDirection.Horizontal
	packLay.HorizontalAlignment = Enum.HorizontalAlignment.Right
	packLay.Padding = UDim.new(0, 6)
	packLay.Parent = packRow
	local grantPack = mkBtn(packRow, "Grant pack", GOLD, 1)

	-- Progression
	local progSec = section("Progression", 30)
	local zoneBox = mkInput(progSec, "maxUnlockedZone (set)", 1)
	local prestBox = mkInput(progSec, "prestige / rebirths (set)", 2)
	local toolBox = mkInput(progSec, "tool family (pickaxe/drill/explosive)", 3)
	local toolTierBox = mkInput(progSec, "tool tier", 4)
	toolTierBox.Text = "1"

	local progRow = Instance.new("Frame")
	progRow.BackgroundTransparency = 1
	progRow.Size = UDim2.new(1, 0, 0, 34)
	progRow.LayoutOrder = 20
	progRow.Parent = progSec
	local progLay = Instance.new("UIListLayout")
	progLay.FillDirection = Enum.FillDirection.Horizontal
	progLay.HorizontalAlignment = Enum.HorizontalAlignment.Right
	progLay.Padding = UDim.new(0, 6)
	progLay.Parent = progRow
	local grantProg = mkBtn(progRow, "Apply", GOLD, 1)

		-- Cosmetics / give-any browser
	panel.Size = UDim2.new(0, 520, 0.88, 0)

	local cosSec = section("Give cosmetics", 40)
	local cosHint = label(cosSec, "Tap an icon to grant it to yourself. Cycle sort + tabs.", 11, MUTED, false)
	cosHint.LayoutOrder = 1
	cosHint.TextWrapped = true
	cosHint.AutomaticSize = Enum.AutomaticSize.Y

	local tabRow = Instance.new("Frame")
	tabRow.BackgroundTransparency = 1
	tabRow.Size = UDim2.new(1, 0, 0, 32)
	tabRow.LayoutOrder = 2
	tabRow.Parent = cosSec
	local tabLay = Instance.new("UIListLayout")
	tabLay.FillDirection = Enum.FillDirection.Horizontal
	tabLay.Padding = UDim.new(0, 4)
	tabLay.Parent = tabRow

	local sortRow = Instance.new("Frame")
	sortRow.BackgroundTransparency = 1
	sortRow.Size = UDim2.new(1, 0, 0, 30)
	sortRow.LayoutOrder = 3
	sortRow.Parent = cosSec
	local sortLay = Instance.new("UIListLayout")
	sortLay.FillDirection = Enum.FillDirection.Horizontal
	sortLay.Padding = UDim.new(0, 6)
	sortLay.Parent = sortRow
	local sortLbl = label(sortRow, "Sort:", 12, MUTED, false)
	sortLbl.Size = UDim2.new(0, 40, 0, 28)
	local sortBox = mkDropdown(sortRow, { "name", "rap", "rarity", "grade", "family" }, 1, "sort")
	sortBox.Size = UDim2.new(1, -48, 0, 28)

	local gridHost = Instance.new("ScrollingFrame")
	gridHost.Name = "CosmeticsGrid"
	gridHost.BackgroundColor3 = Color3.fromRGB(20, 16, 14)
	gridHost.BackgroundTransparency = 0.25
	gridHost.BorderSizePixel = 0
	gridHost.Size = UDim2.new(1, 0, 0, 220)
	gridHost.CanvasSize = UDim2.new(0, 0, 0, 0)
	gridHost.AutomaticCanvasSize = Enum.AutomaticSize.Y
	gridHost.ScrollBarThickness = 4
	gridHost.ScrollBarImageColor3 = GOLD
	gridHost.LayoutOrder = 4
	gridHost.Parent = cosSec
	round(gridHost, 8)
	local gridPad = Instance.new("UIPadding")
	gridPad.PaddingTop = UDim.new(0, 6)
	gridPad.PaddingBottom = UDim.new(0, 6)
	gridPad.PaddingLeft = UDim.new(0, 6)
	gridPad.PaddingRight = UDim.new(0, 6)
	gridPad.Parent = gridHost
	local gridLay = Instance.new("UIGridLayout")
	gridLay.CellSize = UDim2.fromOffset(72, 88)
	gridLay.CellPadding = UDim2.fromOffset(6, 6)
	gridLay.SortOrder = Enum.SortOrder.LayoutOrder
	gridLay.Parent = gridHost

	local cosTab = "hats"
	local tabBtns = {}
	local RARITY_RANK = {
		Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
		Legendary = 5, Mythic = 6, Divine = 7, Exotic = 8,
		F = 1, D = 2, C = 3, B = 4, A = 5, S = 6, SS = 7, SSS = 8,
	}

	local function thumbFor(row, kind)
		if kind == "hats" or kind == "faces" then
			local id = tonumber(row.catalogId)
			if id then
				return string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", id)
			end
		end
		return ""
	end

	local function sortedRows(kind)
		local srcList = {}
		if not catalog then return srcList end
		if kind == "hats" then srcList = catalog.hats or {}
		elseif kind == "faces" then srcList = catalog.faces or {}
		elseif kind == "tools" then srcList = catalog.tools or {}
		elseif kind == "tempers" then srcList = catalog.tempers or {}
		end
		local copy = {}
		for i, row in ipairs(srcList) do copy[i] = row end
		local mode = tostring(sortBox:GetAttribute("Value") or "name")
		table.sort(copy, function(a, b)
			if mode == "rap" then
				return (tonumber(a.rap) or 0) > (tonumber(b.rap) or 0)
			elseif mode == "rarity" or mode == "grade" then
				local ra = RARITY_RANK[a.rarity or a.grade] or 0
				local rb = RARITY_RANK[b.rarity or b.grade] or 0
				if ra ~= rb then return ra > rb end
			elseif mode == "family" then
				local fa = tostring(a.family or a.setId or "")
				local fb = tostring(b.family or b.setId or "")
				if fa ~= fb then return fa < fb end
			end
			return tostring(a.name or a.id) < tostring(b.name or b.id)
		end)
		return copy
	end

	local function grantRow(kind, row)
		local payload = {}
		if kind == "hats" then
			payload.gearHatId = row.id
		elseif kind == "faces" then
			payload.gearFaceId = row.id
		elseif kind == "tempers" then
			payload.temperId = row.id
			payload.temperRarity = row.rarity
		elseif kind == "tools" then
			payload.namedToolId = row.id
			payload.namedToolFamily = row.family
			payload.namedToolTier = row.tier or 1
		end
		local res = invoke("grant", payload)
		if res.ok then
			setStatus("Granted " .. tostring(row.name or row.id), true)
		else
			setStatus("Fail: " .. tostring(res.err), false)
		end
	end

	local function rebuildGrid()
		for _, ch in ipairs(gridHost:GetChildren()) do
			if ch:IsA("GuiButton") then ch:Destroy() end
		end
		local rows = sortedRows(cosTab)
		for i, row in ipairs(rows) do
			local card = Instance.new("TextButton")
			card.Name = tostring(row.id)
			card.BackgroundColor3 = CARD
			card.BackgroundTransparency = 0.15
			card.Text = ""
			card.AutoButtonColor = true
			card.LayoutOrder = i
			card.Parent = gridHost
			round(card, 8)
			stroke(card, GOLD, 1, 0.55)

			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.Size = UDim2.new(1, -8, 0, 52)
			img.Position = UDim2.new(0, 4, 0, 4)
			img.ScaleType = Enum.ScaleType.Fit
			img.Image = thumbFor(row, cosTab)
			img.Parent = card
			local hasIcon = img.Image ~= ""
			if cosTab == "tools" then
				hasIcon = ToolIcons.apply(img, tostring(row.name or ""))
					or ToolIcons.apply(img, tostring(row.id or ""))
			end
			if not hasIcon then
				local letter = Instance.new("TextLabel")
				letter.BackgroundTransparency = 1
				letter.Size = UDim2.fromScale(1, 1)
				letter.Font = FONT
				letter.TextSize = 22
				letter.TextColor3 = GOLD
				letter.Text = string.upper(string.sub(tostring(row.name or row.id or "?"), 1, 1))
				letter.Parent = img
			end

			local name = Instance.new("TextLabel")
			name.BackgroundTransparency = 1
			name.Position = UDim2.new(0, 2, 0, 56)
			name.Size = UDim2.new(1, -4, 0, 28)
			name.Font = FONT_M
			name.TextSize = 10
			name.TextColor3 = TEXT
			name.TextWrapped = true
			name.TextTruncate = Enum.TextTruncate.AtEnd
			name.Text = tostring(row.name or row.id)
			name.Parent = card

			card.MouseButton1Click:Connect(function()
				grantRow(cosTab, row)
			end)
		end
	end

	local function setTab(name)
		cosTab = name
		for id, btn in pairs(tabBtns) do
			btn.BackgroundColor3 = (id == name) and GOLD or CARD
			btn.TextColor3 = (id == name) and (T.ON_GOLD or Color3.fromRGB(38, 28, 12)) or TEXT
		end
		rebuildGrid()
	end

	for i, name in ipairs({ "hats", "faces", "tools", "tempers" }) do
		local b = mkBtn(tabRow, name, CARD, i)
		b.Size = UDim2.new(0, 78, 0, 28)
		b.TextColor3 = TEXT
		tabBtns[name] = b
		b.MouseButton1Click:Connect(function()
			setTab(name)
		end)
	end
	sortBox.MouseButton1Click:Connect(function()
		task.defer(rebuildGrid)
	end)
	sortBox.MouseButton2Click:Connect(function()
		task.defer(rebuildGrid)
	end)

	task.defer(function()
		if not catalog then
			local res = invoke("catalog", {})
			if res.ok then catalog = res end
		end
		setTab("hats")
	end)

	rebuildCosmeticsGrid = rebuildGrid

	-- Unlock every zone + depth outpost for preview travel.
	local unlockSec = section("Unlock all zones & depths", 49)
	local unlockHint = label(unlockSec, "Sets maxUnlockedZone, bigbangOwned, deepest=5000 per zone, builds all outposts.", 11, MUTED, false)
	unlockHint.LayoutOrder = 1
	unlockHint.TextWrapped = true
	unlockHint.AutomaticSize = Enum.AutomaticSize.Y
	local unlockRow = Instance.new("Frame")
	unlockRow.BackgroundTransparency = 1
	unlockRow.Size = UDim2.new(1, 0, 0, 34)
	unlockRow.LayoutOrder = 2
	unlockRow.Parent = unlockSec
	local unlockLay = Instance.new("UIListLayout")
	unlockLay.FillDirection = Enum.FillDirection.Horizontal
	unlockLay.HorizontalAlignment = Enum.HorizontalAlignment.Right
	unlockLay.Parent = unlockRow
	local unlockBtn = mkBtn(unlockRow, "Unlock all", GOLD, 1)
	unlockBtn.MouseButton1Click:Connect(function()
		local res = invoke("unlockAllZonesDepths", {})
		if res and res.ok then
			setStatus("Unlocked " .. tostring(res.zones or "?") .. " zones · depths 5000", true)
		else
			setStatus(tostring(res and res.err or "unlock failed"), false)
		end
	end)

	-- Forge custom Roblox-catalog gear into inventory (tradeable copies).
	local forgeSec = section("Forge custom item", 50)
	local forgeHint = label(forgeSec, "Asset id + stats + copies → your bag (adm_ ids). Stats: luck:150,dirtBreak:80 (+%).", 11, MUTED, false)
	forgeHint.LayoutOrder = 1
	forgeHint.TextWrapped = true
	forgeHint.AutomaticSize = Enum.AutomaticSize.Y
	local forgeAsset = mkInput(forgeSec, "Roblox asset / catalog id", 2)
	local forgeName = mkInput(forgeSec, "Display name (optional)", 3)
	local forgeSlot = mkDropdown(forgeSec, { "hat", "face" }, 4, "slot")
	local forgeRarity = mkDropdown(forgeSec, { "SSS", "SS", "S", "A", "B", "C", "D", "F" }, 5, "grade")
	local forgeStats = mkInput(forgeSec, "stats e.g. luck:150,dirtBreak:80", 6)
	local forgeAmt = mkInput(forgeSec, "amount (1-25)", 7)
	forgeAmt.Text = "1"
	local forgeTarget = mkInput(forgeSec, "target UserId (blank = you)", 8)
	local forgeRow = Instance.new("Frame")
	forgeRow.BackgroundTransparency = 1
	forgeRow.Size = UDim2.new(1, 0, 0, 34)
	forgeRow.LayoutOrder = 20
	forgeRow.Parent = forgeSec
	local forgeLay = Instance.new("UIListLayout")
	forgeLay.FillDirection = Enum.FillDirection.Horizontal
	forgeLay.HorizontalAlignment = Enum.HorizontalAlignment.Right
	forgeLay.Padding = UDim.new(0, 6)
	forgeLay.Parent = forgeRow
	local forgeBtn = mkBtn(forgeRow, "Forge copies", GOLD, 1)

	forgeBtn.MouseButton1Click:Connect(function()
		local assetId = tonumber((forgeAsset.Text or ""):gsub("%s+", ""))
		if not assetId or assetId <= 0 then
			setStatus("Need a Roblox asset id", false)
			return
		end
		local statsText = tostring(forgeStats.Text or "")
		if statsText == "" then
			setStatus("Need stats (e.g. luck:100)", false)
			return
		end
		local amt = tonumber(string.gsub(forgeAmt.Text or "", "%s+", ""))
		local payload = {
			robloxAssetId = assetId,
			itemName = tostring(forgeName.Text or ""),
			slot = tostring(forgeSlot:GetAttribute("Value") or "hat"),
			rarity = tostring(forgeRarity:GetAttribute("Value") or "SSS"),
			stats = statsText,
			amount = amt or 1,
		}
		local tid = tonumber(string.gsub(forgeTarget.Text or "", "%s+", ""))
		if tid then payload.targetUserId = tid end
		local res = invoke("forgeItem", payload)
		if res.ok then
			setStatus(string.format("Forged x%d · %s", tonumber(res.amount) or 1, tostring(res.creationId or "")), true)
		else
			setStatus("Fail: " .. tostring(res.err), false)
		end
	end)

	local resetSec = section("Reset save", 51)
	local resetHint = label(resetSec, "Wipes YOUR profile. Type RESET, then confirm. You will be kicked.", 11, MUTED, false)
	resetHint.LayoutOrder = 1
	resetHint.TextWrapped = true
	resetHint.AutomaticSize = Enum.AutomaticSize.Y
	local resetBox = mkInput(resetSec, "type RESET", 2)
	local resetRow = Instance.new("Frame")
	resetRow.BackgroundTransparency = 1
	resetRow.Size = UDim2.new(1, 0, 0, 34)
	resetRow.LayoutOrder = 3
	resetRow.Parent = resetSec
	local resetLay = Instance.new("UIListLayout")
	resetLay.FillDirection = Enum.FillDirection.Horizontal
	resetLay.HorizontalAlignment = Enum.HorizontalAlignment.Right
	resetLay.Parent = resetRow
	local resetBtn = mkBtn(resetRow, "Reset save", BAD, 1)
	resetBtn.TextColor3 = Color3.new(1, 1, 1)
	resetBtn.MouseButton1Click:Connect(function()
		if tostring(resetBox.Text or "") ~= "RESET" then
			setStatus("Type RESET to confirm", false)
			return
		end
		local res = invoke("resetSave", { confirm = "RESET" })
		if res and res.ok then
			setStatus("Save wiped. Rejoin.", true)
		else
			setStatus(tostring(res and res.err or "reset failed"), false)
		end
	end)

-- Footer actions
	local foot = Instance.new("Frame")
	foot.BackgroundTransparency = 1
	foot.Size = UDim2.new(1, 0, 0, 36)
	foot.LayoutOrder = 90
	foot.Parent = scroll
	local footLay = Instance.new("UIListLayout")
	footLay.FillDirection = Enum.FillDirection.Horizontal
	footLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
	footLay.Padding = UDim.new(0, 8)
	footLay.Parent = foot
	local refreshBtn = mkBtn(foot, "Refresh profile", CARD, 1)
	refreshBtn.TextColor3 = TEXT
	local closeBtn = mkBtn(foot, "Close", CARD, 2)
	closeBtn.TextColor3 = TEXT

	local function toggle(force)
		if force ~= nil then
			open = force
		else
			open = not open
		end
		panel.Visible = open
	end

	entry.MouseButton1Click:Connect(function()
		toggle()
	end)
	closeBtn.MouseButton1Click:Connect(function()
		toggle(false)
	end)

	local function numOrNil(box)
		local t = string.gsub(box.Text or "", "%s+", "")
		if t == "" then
			return nil
		end
		return tonumber(t)
	end

	grantCur.MouseButton1Click:Connect(function()
		local payload = {
			coins = numOrNil(coinBox),
			gems = numOrNil(gemBox),
			dust = numOrNil(dustBox),
			credits = numOrNil(creditBox),
			skillPoints = numOrNil(skillBox),
			temperTokens = numOrNil(temperBox),
		}
		local res = invoke("grant", payload)
		if res.ok then
			setStatus("Granted currencies", true)
		else
			setStatus("Fail: " .. tostring(res.err), false)
		end
	end)

	grantPack.MouseButton1Click:Connect(function()
		local id = tostring(packBox:GetAttribute("Value") or "")
		if id == "" then
			setStatus("Pick a pack from the dropdown", false)
			return
		end
		local res = invoke("grant", { packId = id, packQty = numOrNil(qtyBox) or 1 })
		if res.ok then
			setStatus("Granted " .. id .. " x" .. tostring(res.changed and res.changed.packQty or 1), true)
		else
			setStatus("Fail: " .. tostring(res.err), false)
		end
	end)

	grantProg.MouseButton1Click:Connect(function()
		local payload = {
			maxUnlockedZone = numOrNil(zoneBox),
			prestige = numOrNil(prestBox),
		}
		local fam = string.gsub(toolBox.Text or "", "%s+", "")
		if fam ~= "" then
			payload.tool = fam
			payload.toolTier = numOrNil(toolTierBox) or 1
		end
		local res = invoke("grant", payload)
		if res.ok then
			setStatus("Applied progression", true)
		else
			setStatus("Fail: " .. tostring(res.err), false)
		end
	end)

	refreshBtn.MouseButton1Click:Connect(function()
		local res = invoke("refresh", {})
		if res.ok then
			setStatus("Profile refreshed", true)
		else
			setStatus("Fail: " .. tostring(res.err), false)
		end
	end)

	-- Pack hint from shared catalog (cosmetic; server still validates)
	local names = {}
	for i, row in ipairs(Packs.PACKS or {}) do
		if i <= 12 then
			table.insert(names, row.id)
		end
	end
	packHint.Text = "Examples: " .. table.concat(names, ", ") .. (Packs.PACKS and #Packs.PACKS > 12 and "…" or "")

	UIS.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.KeyCode == Enum.KeyCode.F8 and authorized then
			toggle()
		end
	end)

	gui:SetAttribute("Built", true)
end

local function authorize(isAdmin)
	authorized = isAdmin == true
	if not authorized then
		if gui then
			gui:Destroy()
			gui = nil
			panel = nil
			statusLbl = nil
		end
		return
	end
	buildUi()
	-- Prefetch catalog from server (allowlisted)
	task.spawn(function()
		local res = invoke("catalog", {})
		if res.ok then
			catalog = res
			if rebuildCosmeticsGrid then
				rebuildCosmeticsGrid()
			end
		end
	end)
end

readyEv.OnClientEvent:Connect(function(isAdmin)
	authorize(isAdmin)
end)

-- Fallback ask once if AdminReady fired before this script connected.
task.defer(function()
	task.wait(1.25)
	if authorized or gui then
		return
	end
	local res = invoke("isAdmin", {})
	authorize(res and res.ok and res.admin == true)
end)
