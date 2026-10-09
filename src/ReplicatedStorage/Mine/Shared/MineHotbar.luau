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
--[[
	SLOT IS SQUARE AND THE BAR IS EXACTLY ITS SLOTS.

	Owner, 2026-10-05: "the block above looks super big and messy and
	unnessacry, not to mention its a rectangle".

	It was a rectangle because the root was SLOT + 24 wide by SLOT + 20 tall --
	padding for a wrapper panel that no longer exists. With the wrapper gone the
	root measures exactly the slots and the gaps between them, so one slot is
	one square and nothing is padded around it.

	MineClient's UIScale handles device size, so these stay in design pixels.
]]
-- 60 -> 68 in the candy pass (2026-10-08): a bigger, chunkier target.
local SLOT = 68
local GAP = 10
local MAX_SLOTS = 5
local TOOL_SLOTS = 1
local TOOL_SLOTS_VIP = 2
local IMG = Icons.IMAGES or {}

function MineHotbar.mount(parent, opts)
	opts = opts or {}
	local getSnap = opts.getSnap or function() return {} end
	local onEquip = opts.onEquip or function() end

	--[[
		THE BASE PICKAXE, and how we know whether it is in your hands.

		A Roblox Tool is "equipped" by living in the Character and "put away" by
		living in the Backpack -- that IS the state, so it is read rather than
		tracked. Nothing here mirrors it into a variable that could drift.

		BASE_UID cannot collide with a real tool uid: those are server-generated
		strings and this one starts with a NUL.
	]]
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	local BASE_UID = "\0base"

	local function baseTool()
		local ch = player and player.Character
		local t = ch and ch:FindFirstChildOfClass("Tool")
		if t then
			return t, true
		end
		local bp = player and player:FindFirstChildOfClass("Backpack")
		t = bp and bp:FindFirstChildOfClass("Tool")
		return t, false
	end

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
		Size = UDim2.fromOffset(SLOT, SLOT),
		BackgroundTransparency = 1,
		ZIndex = 12,
	}, parent)

	--[[
		ONE FRAME PER SLOT, NOT A PANEL CONTAINING A FRAME.

		The first pass wrapped the slots in a Strip panel, so a single slot drew
		as a rounded panel with a rounded button inside it -- two edges, two
		radii, 92 x 88, and the owner read it exactly right: "looks super big and
		messy and unnessacry, not to mention its a rectangle".

		The slots sit straight in the root now. Each one is a SQUARE button with
		an inner fill, because the inner block is what the owner asked to carry
		the equipped state: "if you click it to equip it highlights the inner
		block, and when you go to unequip it it stops highlighting".
	]]
	local row = UI.new("Frame", {
		Name = "Row",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 12,
	}, root)
	UI.flow(row, false, GAP)

	local slots = {}
	for i = 1, MAX_SLOTS do
		local b = UI.new("TextButton", {
			Name = "Slot" .. i,
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = T.PANEL,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(SLOT, SLOT),
			LayoutOrder = i,
			Visible = i == 1,
			ZIndex = 12,
		}, row)
		UI.round(b, T.RADIUS_LG)
		local edge = UI.edge(b, T.OUTLINE, T.STROKE_CHUNKY)
		edge.Transparency = 0
		UI.juice(b, 1.08)

		-- The inner block. This is what lights up, so the slot keeps its own
		-- outline and the state lands inside it rather than on the border.
		-- candyTint shades it and adds the gloss; its hue is set per refresh.
		local inner = UI.new("Frame", {
			Name = "Inner",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -10, 1, -10),
			BackgroundColor3 = T.CARD,
			BorderSizePixel = 0,
			ZIndex = 13,
		}, b)
		UI.round(inner, T.RADIUS)
		UI.candyTint(inner, 0)

		-- Anchored rather than offset, so the icon stays centred whatever SLOT
		-- is and however MineClient's UIScale stretches it. Sat at 0.44 to
		-- leave the bottom strip for the key number.
		local img = UI.icon(inner, "", math.floor(SLOT * 0.56))
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.Position = UDim2.fromScale(0.5, 0.44)
		img.ZIndex = 14
		local key = UI.text(inner, tostring(i), 14, T.TEXT, T.FONT)
		key.AnchorPoint = Vector2.new(0.5, 1)
		key.Position = UDim2.new(0.5, 0, 1, 0)
		key.Size = UDim2.new(1, 0, 0, 16)
		key.TextXAlignment = Enum.TextXAlignment.Center
		key.ZIndex = 14
		UI.outlineText(key, 1.5)
		slots[i] = { btn = b, edge = edge, inner = inner, img = img, key = key, uid = nil }
	end

	local function refresh()
		local snap = getSnap() or {}
		local held = snap.oreToolEquipped
		--[[
			WHAT GOES IN SLOT ONE.

			YOUR TOOL SITS THERE WHETHER OR NOT IT IS EQUIPPED.

			The first pass only filled the slot with what you were HOLDING, so
			putting a tool away emptied the bar and left you nothing to click to
			get it back. Owner, 2026-10-05: "put your tool in there by default,
			and if you click it to equip it highlights the inner block, and when
			you go to unequip it it stops highlighting".

			So the slot is a PLACE, not a readout. It shows your best tool, held
			or not; the highlight is what tells you it is equipped. VIP gets a
			second slot; everyone else needs exactly one.

			Slots past the tool slots are reserved for consumables and the rest
			of what lands later. They stay hidden until something fills them,
			which is what makes the bar measure itself.
		]]
		local isVip = snap.vip == true or snap.isVip == true or snap.gamepassVip == true
		local toolSlots = isVip and TOOL_SLOTS_VIP or TOOL_SLOTS
		local tools = {}
		local all = snap.oreTools or {}
		-- Held first, so the tool you are carrying keeps slot one and does not
		-- jump along the bar as the rack changes under it.
		for _, t in ipairs(all) do
			if held and t.uid == held then
				table.insert(tools, t)
			end
		end
		-- Then fill the remaining tool slots from the rack, best tier first, so
		-- an unequipped player still has something to click.
		local rest = {}
		for _, t in ipairs(all) do
			if not held or t.uid ~= held then
				table.insert(rest, t)
			end
		end
		table.sort(rest, function(a, b)
			local at, bt = tonumber(a.tier) or 0, tonumber(b.tier) or 0
			if at ~= bt then
				return at > bt
			end
			return (tonumber(a.level) or 0) > (tonumber(b.level) or 0)
		end)
		for _, t in ipairs(rest) do
			if #tools >= toolSlots then
				break
			end
			table.insert(tools, t)
		end

		--[[
			THE BASE PICKAXE COUNTS AS YOUR TOOL.

			Measured in a live session: the slot was empty, because the profile owns
			no FORGED tool yet and `tools` is built from snap.oreTools. The player
			was holding a pickaxe the whole time -- the ladder pickaxe the server
			hands out when no ore tool is equipped -- and the bar showed nothing.

			That is the same bug the owner reported from the other direction, and
			the same fix: the slot is a PLACE. If you are carrying a pickaxe, the
			pickaxe is in the bar, forged or not. Every new player starts here, so
			this is what the hotbar looks like for most of them.
		]]
		if #tools == 0 then
			local base = baseTool()
			if base then
				table.insert(tools, { uid = BASE_UID, familyId = "pickaxe", name = base.Name })
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
				-- The ore's own skin for a forged pickaxe, the family icon for
				-- anything else. Icons.forTool owns that rule so the bar, the
				-- Forge and the inventory cannot disagree about one tool.
				if t.uid == BASE_UID then
					s.img.Image = Icons.ORE_PICK_STARTER or IMG.pickaxe or ""
				else
					s.img.Image = Icons.forTool(t) or ""
				end
				s.img.ImageTransparency = 0
				--[[
					THE INNER BLOCK CARRIES THE EQUIPPED STATE.

					Owner: "if you click it to equip it highlights the inner
					block, and when you go to unequip it it stops highlighting".

					So the fill that changes is the Inner frame, not the slot.
					The slot's own edge picks up the accent with it -- Roblox's
					hotbar marks the held slot with a white outline, which is the
					one piece of its chrome worth keeping and the easiest thing
					to restate in the house style.
				]]
				local on
				if t.uid == BASE_UID then
					local _, worn = baseTool()
					on = worn
				else
					on = (held ~= nil and t.uid == held)
				end
				-- Candy pass: the held slot is bright violet with a fat gold rim,
				-- and it pops the moment it lights so equipping feels like a click.
				s.inner.BackgroundColor3 = on and T.ACCENT or T.CARD
				s.inner.BackgroundTransparency = 0
				s.btn.BackgroundTransparency = 0.1
				s.edge.Color = on and T.GOLD or T.OUTLINE
				s.edge.Thickness = on and T.STROKE_THICK or T.STROKE_CHUNKY
				s.key.TextColor3 = on and T.TEXT or T.MUTED
				if on and not s.on then
					UI.pop(s.btn, 1.15)
				end
				s.on = on
				if t.uid == BASE_UID then
					s.btn.Name = tostring(t.name or "Pickaxe")
				else
					local okName, nm = pcall(OreTools.toolName, t)
					s.btn.Name = okName and tostring(nm) or ("Slot" .. i)
				end
			else
				-- Every property the filled branch sets is reset here. The first
				-- pass faded an empty slot's button and never restored it, so a
				-- slot that had once been empty stayed faded after it filled.
				s.img.Image = ""
				s.inner.BackgroundColor3 = T.CARD
				s.inner.BackgroundTransparency = 0.5
				s.btn.BackgroundTransparency = 0.35
				s.edge.Color = T.OUTLINE
				s.edge.Thickness = T.STROKE_CHUNKY
				s.key.TextColor3 = T.MUTED
				s.on = false
			end
		end

		-- The bar measures itself to the slots in use, so one tool is one
		-- square rather than one tool and four grey holes.
		used = math.clamp(used, 1, MAX_SLOTS)
		root.Size = UDim2.fromOffset(SLOT * used + GAP * (used - 1), SLOT)
	end

	for i = 1, MAX_SLOTS do
		local s = slots[i]
		s.btn.MouseButton1Click:Connect(function()
			if not s.uid then
				return
			end
			if s.uid == BASE_UID then
				-- The base pickaxe is a plain Tool, so equipping it is the
				-- Humanoid's job rather than the server's. EquipTool and
				-- UnequipTools both replicate from the owning client.
				local tool, worn = baseTool()
				local ch = player and player.Character
				local hum = ch and ch:FindFirstChildOfClass("Humanoid")
				if not (tool and hum) then
					return
				end
				if worn then
					hum:UnequipTools()
				else
					hum:EquipTool(tool)
				end
				task.defer(refresh)
				return
			end
			local snap = getSnap() or {}
			-- Clicking what you already hold puts it away. equipOreTool reads an
			-- empty uid as unequip, so this needs no second verb.
			onEquip(snap.oreToolEquipped == s.uid and "" or s.uid)
		end)
	end

	--[[
		The highlight follows the real tool, and the real tool moves without a
		snapshot: respawning, dying, or the server handing the ladder pickaxe back
		after an ore tool is put away. Watching the Character for Tool children is
		watching the state itself.
	]]
	local function watchCharacter(ch)
		if not ch then
			return
		end
		ch.ChildAdded:Connect(function(c)
			if c:IsA("Tool") then
				task.defer(refresh)
			end
		end)
		ch.ChildRemoved:Connect(function(c)
			if c:IsA("Tool") then
				task.defer(refresh)
			end
		end)
		task.defer(refresh)
	end
	if player then
		watchCharacter(player.Character)
		player.CharacterAdded:Connect(watchCharacter)
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
