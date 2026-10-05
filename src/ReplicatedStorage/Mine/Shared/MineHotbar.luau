--[[
	MineHotbar -- the game's own hotbar, in place of Roblox's.

	Owner, 2026-10-05: "remove the real pickaxe from my hotbar. and make a
	fake/custom hotbar, that allows me to equip and unequip as i please, without
	having that weird grey cube".

	THE GREY CUBE is Roblox's default Backpack UI drawing a Tool that has no
	TextureId. The forged tools are Models with a Handle and no icon asset, so
	the core hotbar falls back to a grey box -- there is no TextureId to set that
	would look right either, because the art this game actually has is the
	MineIcons set, which the core UI cannot be told to use.

	So the core Backpack is switched OFF and this draws the bar instead, out of
	MineUI and MineIcons. Same art as every other panel, and the equipped slot
	lights with the theme accent rather than Roblox's white outline.

	EQUIP AND UNEQUIP AS YOU PLEASE. The server's equipOreTool already treats an
	empty uid as "put it away" -- it clears p.oreToolEquipped and hands back the
	ladder pickaxe -- so clicking the slot you are already holding unequips it.
	Nothing new was needed server-side for that.

	This owns NO state. It renders whatever getSnap() returns and reports clicks
	back through onEquip; the server decides what is held, exactly as the bench
	and the forge do.
]]

local shared = script.Parent
local T = require(shared:WaitForChild("MineTheme"))
local UI = require(shared:WaitForChild("MineUI"))
local Icons = require(shared:WaitForChild("MineIcons"))
local OreTools = require(shared:WaitForChild("MineOreTools"))

local MineHotbar = {}

local SLOT = 68
local SLOTS = 8
local IMG = Icons.IMAGES or {}

function MineHotbar.mount(parent, opts)
	opts = opts or {}
	local getSnap = opts.getSnap or function() return {} end
	local onEquip = opts.onEquip or function() end

	--[[
		Roblox's hotbar goes away here rather than in MineClient, so the module
		that replaces it is the module that disables it. SetCoreGuiEnabled can
		throw before the CoreGui has loaded, which is why it is wrapped and
		retried on the next frame rather than assumed.
	]]
	local StarterGui = game:GetService("StarterGui")
	task.spawn(function()
		for _ = 1, 10 do
			local ok = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			end)
			if ok then
				break
			end
			task.wait(0.25)
		end
	end)

	local root = UI.new("Frame", {
		Name = "Hotbar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(SLOT * SLOTS + 10 * (SLOTS - 1) + 24, SLOT + 20),
		BackgroundTransparency = 1,
		ZIndex = 60,
	}, parent)

	local strip = UI.new("Frame", {
		Name = "Strip",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = T.PANEL,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		ZIndex = 60,
	}, root)
	UI.round(strip, T.RADIUS_LG)
	UI.edge(strip, T.EDGE)
	UI.lit(strip, 0.06)

	local row = UI.new("Frame", {
		Name = "Row",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -24, 0, SLOT),
		BackgroundTransparency = 1,
		ZIndex = 61,
	}, strip)
	UI.flow(row, false, 10)

	local slots = {}
	for i = 1, SLOTS do
		local b = UI.new("TextButton", {
			Name = "Slot" .. i,
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = T.CARD,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(SLOT, SLOT),
			LayoutOrder = i,
			ZIndex = 62,
		}, row)
		UI.round(b, T.RADIUS)
		local edge = UI.edge(b, T.LINE)
		local img = UI.icon(b, "", 40, UDim2.fromOffset(14, 10))
		img.ZIndex = 63
		local key = UI.text(b, tostring(i), 12, T.FAINT, T.FONT_M)
		key.Position = UDim2.new(0, 0, 1, -16)
		key.Size = UDim2.new(1, 0, 0, 14)
		key.TextXAlignment = Enum.TextXAlignment.Center
		key.ZIndex = 63
		slots[i] = { btn = b, edge = edge, img = img, key = key, uid = nil }
	end

	local function refresh()
		local snap = getSnap() or {}
		local tools = snap.oreTools or {}
		local held = snap.oreToolEquipped
		for i = 1, SLOTS do
			local s = slots[i]
			local t = tools[i]
			s.uid = t and t.uid or nil
			if t then
				local fam = tostring(t.familyId or "pickaxe")
				s.img.Image = IMG[fam] or IMG.pickaxe or ""
				s.img.ImageTransparency = 0
				local on = (held ~= nil and t.uid == held)
				-- The equipped slot lights in the theme accent. Roblox's own
				-- hotbar marks the held slot with a white outline, which is the
				-- one piece of its chrome worth keeping and the easiest to
				-- restate in the house style.
				s.btn.BackgroundColor3 = on and T.CARD_HI or T.CARD
				s.edge.Color = on and T.ACCENT or T.LINE
				s.edge.Thickness = on and 2 or 1
				s.key.TextColor3 = on and T.ACCENT or T.FAINT
				local okName, nm = pcall(OreTools.toolName, t)
				s.btn.Name = okName and tostring(nm) or ("Slot" .. i)
			else
				s.img.Image = ""
				s.btn.BackgroundColor3 = T.CARD
				s.btn.BackgroundTransparency = 0.45
				s.edge.Color = T.LINE
				s.edge.Thickness = 1
				s.key.TextColor3 = T.FAINT
			end
		end
	end

	for i = 1, SLOTS do
		local s = slots[i]
		s.btn.MouseButton1Click:Connect(function()
			if not s.uid then
				return
			end
			local snap = getSnap() or {}
			-- Clicking what you already hold puts it away. equipOreTool reads an
			-- empty uid as unequip, so this needs no second verb.
			onEquip(snap.oreToolEquipped == s.uid and "" or s.uid)
		end)
	end

	refresh()
	return {
		refresh = refresh,
		root = root,
		setVisible = function(v)
			root.Visible = v and true or false
		end,
	}
end

return MineHotbar
