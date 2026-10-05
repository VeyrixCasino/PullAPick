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

--[[
	FIVE SLOTS, AND ONLY THE ONES IN USE.

	Owner, 2026-10-05: "make the hotbar only scale to how many tools are
	currently active. (MAX 5 [slot one is for tools{vip you CAN have 2 tools, but
	you only need one} slots 2-5 is for other shit like potions and or whatever
	else we decide to add{maybe a fish rod, stupid stuff like that}])".

	So the bar is not a fixed rack of eight empties. Slot 1 is the TOOL slot --
	two of them for VIP, who may carry a second -- and the rest are for
	consumables and whatever else lands later. The strip measures itself to the
	slots actually in use, so a player holding one pickaxe sees one slot, not one
	pickaxe and seven grey holes.

	A minimum of one slot is kept even when nothing is equipped. A bar that
	vanishes entirely reads as a bug, and the empty slot is where the tool goes
	back to.
]]
local SLOT = 68
local MAX_SLOTS = 5
local TOOL_SLOTS = 1
local TOOL_SLOTS_VIP = 2
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

	--[[
		ZIndex 12, not 60.

		Owner: "make it so the shop ui goes over the hotbar". The ScreenGui runs
		ZIndexBehavior.Sibling, so what covers what among top-level frames is
		decided by their own ZIndex -- the hotbar at 60 was winning against the
		shop at 80's CHILDREN but fighting the panels it should sit under. At 12
		it stays above the world and below every panel (quests are 20, the shop
		is 80), which is where a hotbar belongs: always there, never in the way.
	]]
	local root = UI.new("Frame", {
		Name = "Hotbar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(SLOT + 24, SLOT + 20),
		BackgroundTransparency = 1,
		ZIndex = 12,
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
	for i = 1, MAX_SLOTS do
		local b = UI.new("TextButton", {
			Name = "Slot" .. i,
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = T.CARD,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(SLOT, SLOT),
			LayoutOrder = i,
			Visible = i == 1,
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
		local held = snap.oreToolEquipped
		--[[
			WHAT GOES IN SLOT ONE.

			The tool slot shows what you are HOLDING, not the whole rack -- the
			rack is the bench's job, and a hotbar that lists every tool you own
			is the Roblox backpack again with different paint. VIP gets a second
			tool slot; everyone else needs exactly one.

			Slots past the tool slots are reserved for consumables and the rest
			of what lands later. They stay hidden until something fills them,
			which is what makes the bar measure itself.
		]]
		local isVip = snap.vip == true or snap.isVip == true or snap.gamepassVip == true
		local toolSlots = isVip and TOOL_SLOTS_VIP or TOOL_SLOTS
		local tools = {}
		local all = snap.oreTools or {}
		-- the held tool first, so it always occupies slot one
		for _, t in ipairs(all) do
			if held and t.uid == held then
				table.insert(tools, t)
			end
		end
		if isVip then
			for _, t in ipairs(all) do
				if #tools < toolSlots and (not held or t.uid ~= held) then
					table.insert(tools, t)
				end
			end
		end

		local used = 0
		for i = 1, MAX_SLOTS do
			local s = slots[i]
			local t = (i <= toolSlots) and tools[i] or nil
			s.uid = t and t.uid or nil
			-- A slot shows if it holds something, or if it is the first tool
			-- slot, which is where a tool returns to when you put it away.
			local show = (t ~= nil) or (i == 1)
			s.btn.Visible = show
			if show then
				used = i
			end
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

		-- The strip measures itself to the slots in use, so one tool is one
		-- slot wide rather than one tool and four grey holes.
		used = math.clamp(used, 1, MAX_SLOTS)
		root.Size = UDim2.fromOffset(SLOT * used + 10 * (used - 1) + 24, SLOT + 20)
	end

	for i = 1, MAX_SLOTS do
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
