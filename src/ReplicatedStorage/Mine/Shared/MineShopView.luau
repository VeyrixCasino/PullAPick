-- MineShopView: the tool and backpack shop, as a carousel.
--
-- One tool on screen at a time, big, with arrows to page through the ladder --
-- the Treasure Hunt Simulator shape. A grid of twenty-five small cards made
-- every rung look the same and forced the player to hunt for the one they could
-- actually afford; a carousel gives each tool the whole stage and makes the
-- ladder feel like a ladder.
--
-- It is also far cheaper: one ViewportFrame that swaps its model, instead of
-- twenty-five spinning at once.
--
-- Purchase rules mirror the server exactly, so the UI never offers a button the
-- server will refuse:
--   * tools cost COINS and are bought one rung at a time, in order
--   * backpacks cost COINS (rungs 1-29); the final rung is Robux-only
local MineShopView = {}

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local Tools = require(shared:WaitForChild("MineTools"))
local C = require(shared:WaitForChild("MineConfig"))
local Factory = require(RS:WaitForChild("ToolModelFactory"))
local ShopLadders = require(shared:WaitForChild("MineShopLadders"))
local Icons = require(shared:WaitForChild("MineIcons"))
local Cards = require(shared:WaitForChild("MineCards"))

--------------------------------------------------------------------------------
-- PALETTE
--------------------------------------------------------------------------------

local T = require(game:GetService("ReplicatedStorage").Mine.Shared:WaitForChild("MineTheme"))
local Audio = require(game:GetService("ReplicatedStorage").Mine.Shared:WaitForChild("MineAudio"))
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

local FAMILY_TINT = {
	pickaxe = Color3.fromRGB(226, 186, 128),
	drill = Color3.fromRGB(255, 168, 92),
	explosive = Color3.fromRGB(255, 130, 118),
	backpack = Color3.fromRGB(168, 224, 132),
	secrets = Color3.fromRGB(240, 240, 245),
}

local function toolRarityOf(row, family, index, total)
	if type(row) ~= "table" then
		return nil
	end
	if row.rarity then
		return row.rarity
	end
	if Tools.rarityForTier then
		return Tools.rarityForTier(index or row.tier or 1, total or 8)
	end
	if Tools.rarityForPower then
		return Tools.rarityForPower(row.power or row.slots)
	end
	return nil
end

local function rarityColor(rar)
	if not rar then
		return nil
	end
	return (Cards.RARITY_COLOR and Cards.RARITY_COLOR[rar]) or nil
end

--[[
	The Forge leads. Crafting a tool out of ore is the main line of progression,
	so it is the tab the shop opens on; the coin-shop families that follow are
	the second line. The coin shop may be removed outright later -- until that
	call is made it stays reachable, just no longer first.
]]
local TABS = {
	{ id = "bench", label = "Forge", blurb = "Forge a tool from ore, then level it. The wooden pickaxe levels on coins." },
	{ id = "pickaxe", label = "Pickaxes", blurb = "Aim, swing, break. One block at a time." },
	{ id = "drill", label = "Drills", blurb = "Hold to mine. Wide clears area, narrow melts rock." },
	{ id = "explosive", label = "Explosives", blurb = "Throw and clear a pattern. Extra bombs split the power." },
	{ id = "backpack", label = "Backpacks", blurb = "Haul capacity. Coins for most rungs; the top pack is Robux." },
	--[[
		Secrets was wired everywhere and never given a button.

		FAMILY_TINT carries a secrets colour, rows() returns secretRankList() for
		it, paint() branches on it and the tab counter prints "have/total" for
		it -- but no commit in this file's history ever put it in TABS, so the
		forever tools could not be reached from the shop at all.
	]]
	{ id = "secrets", label = "Secrets", blurb = "Forever tools. Pulled from chests, never sold on a shelf." },
}

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

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

-- 1,240,000 reads as nothing at a glance; 1.24M reads as a number you can
-- compare. Big prices are the whole progression curve here.
local function money(n)
	local ok, Ab = pcall(function()
		return require(shared:WaitForChild("MineAbbrev"))
	end)
	if ok and Ab and Ab.currency then
		return Ab.currency(n)
	end
	return tostring(math.floor(tonumber(n) or 0))
end

local function commas(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

--------------------------------------------------------------------------------
-- STAT LINES
--
-- What each family's numbers actually mean, in the player's language. Shape and
-- bomb count decide a purchase now, so they are shown, not buried.
--------------------------------------------------------------------------------

local function statLines(family, row)
	local out = {}
	if family == "backpack" then
		local capText = row.infinite and "Infinite" or commas(row.slots)
		table.insert(out, { "Capacity", capText })
		return out
	end
	table.insert(out, { "Power", commas(row.power) })
	if family == "drill" then
		-- Footprint and travel are the trade: a 3x3 clears nine cells but each
		-- one is softer than a 1x1's single cell.
		table.insert(out, { "Bore", string.format("%dx%d %s", row.width or 1, row.width or 1,
			(row.shape == "dir") and "aim" or "down") })
		table.insert(out, { "Rate", string.format("%.1f/s", row.rate or 1) })
		table.insert(out, { "Cells", commas(Tools.cellsOf(row)) })
	elseif family == "explosive" then
		local shape = row.pattern or "sphere"
		if (row.bombs or 1) > 1 then
			table.insert(out, { "Bombs", string.format("%d x %s", row.bombs, shape) })
		else
			table.insert(out, { "Blast", shape })
		end
		table.insert(out, { "Cells", commas(Tools.cellsOf(row)) })
		table.insert(out, { "Cooldown", string.format("%.1fs", row.cooldown or 1) })
	else
		table.insert(out, { "Swings/sec", string.format("%.1f", row.rate or 1) })
		local reach = Tools.reachOf and Tools.reachOf(row) or nil
		if reach then
			table.insert(out, { "Reach", tostring(math.floor(reach)) .. " studs" })
		end
	end
	return out
end

--------------------------------------------------------------------------------
-- MOUNT
--------------------------------------------------------------------------------

--[[
	Build the shop. `opts` carries the callbacks:
		onBuyTool(family)   -- buy the next rung in a tool family
		onBuyBackpack()     -- buy the next backpack
		onBuyCreditPack(packId)
		onBuyScroll(id, bundle)
		onEquip(family)     -- hold a family you already own
		onClose()
	Returns a controller: .root, .setState(snapshot), .open(tab), .close().
]]
function MineShopView.mount(parent, opts)
	opts = opts or {}
	local state = { coins = 0, gems = 0, credits = 0, dust = 0, tokens = 0, ores = {}, oresSeen = {}, oreTools = {}, scrolls = {}, tools = {}, backpackTier = 1, family = "pickaxe", creditPacks = {}, scrollShop = {}, chestTools = {}, chestTool = nil, maxUnlockedZone = 1, zoneIndex = 1, ownedShopTools = {}, shopToolId = nil }
	-- Opens on the Forge, not on a shelf of coin-bought picks.
	local activeTab = "bench"
	local index = 1
	state.tempers, state.toolTempers = {}, {}
	local view = {}
	local CARD_HOME = UDim2.new(0.5, 0, 0, 104)

	local root = mk("Frame", {
		Name = "ShopPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(6, 8, 14),
		BackgroundTransparency = 0.15,
		Visible = false,
		ZIndex = 80,
		BorderSizePixel = 0,
	}, parent)
	--[[
		THE BACKDROP IS DRAWN, NOT PHOTOGRAPHED.

		What used to be here was `shopBg`: an OPAQUE ImageLabel at ZIndex 80
		holding a zone painting. This ScreenGui runs ZIndexBehavior.Sibling, so
		among root's children that plate drew over every sibling beneath it --
		the 3D stage at 2, the tab strip at 41 and the temperament picker at 70.
		One plate is why the shop showed a background and nothing else, and why
		the sort options disappeared along with the tools.

		Three cheap layers replace it, none above ZIndex 3, so the stage and
		every control are unambiguously in front:

		  1. a vertical gradient, cold night at the top falling into forge
		     ember at the bottom, so the room has a floor without a floor being
		     modelled;
		  2. a soft warm disc low and centred, where the plinth stands, so the
		     tool reads as lit by the hearth rather than pasted on a gradient;
		  3. a vignette that pulls the corners down and puts the eye on the
		     pedestal.

		No image means nothing to load, nothing to own, and no zone whose
		painting is missing.
	]]
	local backdrop = mk("Frame", {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(20, 22, 34),
		ZIndex = 1,
		BorderSizePixel = 0,
	}, root)
	mk("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(9, 11, 20)),
			ColorSequenceKeypoint.new(0.42, Color3.fromRGB(24, 23, 33)),
			ColorSequenceKeypoint.new(0.76, Color3.fromRGB(56, 36, 29)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(88, 50, 27)),
		}),
		Rotation = 90,
	}, backdrop)

	local glow = mk("Frame", {
		Name = "ForgeGlow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.76),
		Size = UDim2.fromScale(0.92, 0.66),
		BackgroundColor3 = Color3.fromRGB(255, 152, 64),
		BackgroundTransparency = 0.8,
		ZIndex = 2,
		BorderSizePixel = 0,
	}, root)
	mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, glow)
	mk("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.55, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rotation = 90,
	}, glow)

	local vignette = mk("Frame", {
		Name = "Vignette",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(4, 5, 10),
		BackgroundTransparency = 0.5,
		ZIndex = 3,
		BorderSizePixel = 0,
	}, root)
	mk("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.45, 0.95),
			NumberSequenceKeypoint.new(1, 0.1),
		}),
		Rotation = 90,
	}, vignette)

	----------------------------------------------------------------------------
	-- HEADER
	----------------------------------------------------------------------------

	local header = mk("Frame", {
		-- 64 -> 78: the title sat 11px off the top edge, crowding it. The extra
		-- height is what the logo moves down into rather than overlapping the
		-- blurb underneath it.
		Name = "Header", Size = UDim2.new(1, 0, 0, 78),
		BackgroundColor3 = Color3.fromRGB(8, 10, 16), BackgroundTransparency = 0.35, ZIndex = 90,
		BorderSizePixel = 0,
	}, root)
	mk("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0.55),
		}),
		Rotation = 90,
	}, header)

	mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(26, 22),
		Size = UDim2.fromOffset(340, 30), Font = FONT, TextSize = 26, TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "BLACKSMITH", ZIndex = 86,
	}, header)
	local sub = mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(26, 50),
		Size = UDim2.fromOffset(560, 20), Font = FONT_M, TextSize = 14, TextColor3 = MUTED,
		TextXAlignment = Enum.TextXAlignment.Left, Text = TABS[1].blurb, ZIndex = 83,
	}, header)

	--[[
		THE WALLET SHOWS WHAT THIS BUILDING SPENDS.

		Three chips, and two of the currencies the blacksmith actually takes
		were not among them: stardust pays for tool levels and temperament
		tokens pay for rolls, so a player had to leave the shop to find out
		whether they could afford what was in front of them.

		The old chips were pinned at hard-coded offsets (-74, -228, -382). Two
		more at that pitch would run under the BLACKSMITH title, so the row is a
		right-aligned UIListLayout instead: chips place themselves, the row grows
		leftward, and a sixth currency later costs no arithmetic.

		The tinted circle is gone. Every one of these has real art in MineIcons
		-- the same source Icons.priceChip already draws from everywhere else in
		the game -- so a coloured dot here was the odd one out.
	]]
	local DUST_TINT = Color3.fromRGB(178, 150, 255)
	local TOKEN_TINT = Color3.fromRGB(255, 178, 94)

	local wallet = mk("Frame", {
		Name = "Wallet",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -84, 0, 19),
		Size = UDim2.fromOffset(716, 40),
		BackgroundTransparency = 1,
		ZIndex = 86,
	}, header)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, wallet)

	local function chip(order, tint, iconId, name)
		local f = mk("Frame", {
			Name = name,
			Size = UDim2.fromOffset(132, 40),
			BackgroundColor3 = Color3.fromRGB(32, 37, 56),
			BackgroundTransparency = 0.05,
			LayoutOrder = order,
			ZIndex = 86,
			BorderSizePixel = 0,
		}, wallet)
		round(f, 12)
		stroke(f, 1.5, tint, 0.45)
		-- Icons.draw returns a holder whose ZIndex defaults low; the chip is at
		-- 86, so anything inside it has to be raised or the art hides behind the
		-- chip's own fill.
		local ok, holder = pcall(function()
			return Icons.icon(f, iconId, UDim2.fromOffset(26, 26), UDim2.fromOffset(7, 7))
		end)
		if ok and holder then
			holder.ZIndex = 87
			for _, d in ipairs(holder:GetDescendants()) do
				if d:IsA("GuiObject") then
					d.ZIndex = 87
				end
			end
		else
			-- No art for this id: fall back to the old dot rather than a blank.
			local dot = mk("Frame", {
				Position = UDim2.fromOffset(9, 11), Size = UDim2.fromOffset(18, 18),
				BackgroundColor3 = tint, ZIndex = 87, BorderSizePixel = 0,
			}, f)
			round(dot, 9)
		end
		return mk("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(40, 0),
			Size = UDim2.new(1, -48, 1, 0), Font = FONT, TextSize = 16, TextColor3 = TEXT,
			TextXAlignment = Enum.TextXAlignment.Left, Text = "0", ZIndex = 87,
		}, f)
	end
	local coinLbl = chip(1, GOLD, "coins", "Coins")
	local gemLbl = chip(2, GEM, "gems", "Gems")
	local dustLbl = chip(3, DUST_TINT, "dust", "Stardust")
	local tokenLbl = chip(4, TOKEN_TINT, "tokens", "Tokens")
	local creditLbl = chip(5, CREDIT, "credits", "Credits")

	--[[
		LEAVING HAS TO WORK ON A PHONE.
	
		This button sat at ZIndex 55 among siblings at 83 and 84 -- ordered
		behind the title and the three currency chips. It only works at all
		because it happens not to overlap them at desktop width; the moment the
		header reflows narrower, a chip slides over the X and the only way out
		of the shop is gone. Above everything in the header now.
	
		Also sized for a thumb: 40px shrinks to ~31 under the phone UIScale,
		well under the ~44px a touch target needs.
	]]
	local close = mk("TextButton", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 12),
		Size = UDim2.fromOffset(52, 52), BackgroundColor3 = Color3.fromRGB(70, 42, 54),
		Font = FONT, TextSize = 26, TextColor3 = Color3.fromRGB(255, 190, 190),
		Text = "X", AutoButtonColor = true, ZIndex = 95,
	}, header)
	round(close, 12)
	stroke(close, 1.5, RED, 0.5)

	----------------------------------------------------------------------------
	-- TAB STRIP
	----------------------------------------------------------------------------

	local strip = mk("Frame", {
		Name = "Tabs", Position = UDim2.fromOffset(0, 98), Size = UDim2.new(1, 0, 0, 44),
		-- Was 41: under the old ZIndex-80 plate, so the whole browse row was
		-- painted over. Above the stage now, where a tab strip belongs.
		BackgroundTransparency = 1, ZIndex = 84,
	}, root)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
	}, strip)

	local tabBtns = {}
	for i, tab in ipairs(TABS) do
		local tint = FAMILY_TINT[tab.id]
		local b = mk("TextButton", {
			-- 168 -> 150: six tabs at the old width are 1058px before the
			-- UIScale a phone applies, which runs the row off both edges.
			Name = "Tab_" .. tab.id, Size = UDim2.fromOffset(150, 44),
			BackgroundColor3 = CARD, Text = "", AutoButtonColor = false,
			LayoutOrder = i, ZIndex = 83,
		}, strip)
		round(b, 12)
		local st = stroke(b, 2, tint, 0.55)
		local lbl = mk("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0),
			Size = UDim2.new(1, -76, 1, 0), Font = FONT, TextSize = 16, TextColor3 = TEXT,
			TextXAlignment = Enum.TextXAlignment.Left, Text = tab.label, ZIndex = 84,
		}, b)
		local count = mk("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(52, 22), BackgroundColor3 = Color3.fromRGB(44, 33, 26),
			BackgroundTransparency = 0.2, Font = FONT_M, TextSize = 12, TextColor3 = MUTED,
			Text = "", ZIndex = 84,
		}, b)
		round(count, 8)
		tabBtns[tab.id] = { button = b, stroke = st, label = lbl, count = count, tint = tint, blurb = tab.blurb }
		b.MouseButton1Click:Connect(function()
			view.setTab(tab.id)
		end)
	end

	----------------------------------------------------------------------------
	-- THE FORGE
	--
	-- MineForge draws every tool in the game down a rail on the left and, on the
	-- right, either the CRAFT recipe list (unowned: pick a discovered ore) or the
	-- UPGRADE panel (owned: level, price, +1 / +10 / MAX, SCRAP). It supersedes
	-- MineBenchView, which only ever showed tools you already had and so could
	-- not tell a player what to build next.
	--
	-- It hangs off the shop root at 86 -- above the stage, below the header --
	-- and only the Upgrade tab shows it.
	--
	-- Required through pcall: if the module is missing from a build, the tab
	-- goes quiet instead of taking the whole shop down with it.
	----------------------------------------------------------------------------
	local okBench, Bench = pcall(function()
		return require(shared:WaitForChild("MineForge", 5))
	end)
	local benchPanel, benchCtl
	if okBench and Bench and Bench.mount then
		benchPanel = mk("Frame", {
			Name = "BenchPanel",
			Visible = false,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 156),
			Size = UDim2.new(0.86, 0, 1, -236),
			BackgroundTransparency = 1,
			ZIndex = 86,
		}, root)
		local okMount, ctl = pcall(Bench.mount, benchPanel, {
			-- The bench reads the same state the rest of the shop does, so a
			-- price it quotes cannot drift from the wallet shown above it.
			getSnap = function()
				return {
					oreTools = state.oreTools or {},
					ores = state.ores or {},
					oresSeen = state.oresSeen,
					-- Which ore tool is in the player's hands, so the Forge can
					-- mark it rather than offering to equip what is already held.
					oreToolUid = state.oreToolUid,
					dust = state.dust or 0,
					-- The Forge quotes coins for the wooden pickaxe and shows a
					-- wallet strip, so it needs both currencies, not just dust.
					coins = state.coins or 0,
					gems = state.gems or 0,
				}
			end,
			-- Out of the Forge and down to the second line.
			onCoinShop = function()
				view.setTab("pickaxe")
			end,
			onEquip = function(uid)
				if opts.onEquipOreTool then
					opts.onEquipOreTool(uid)
				end
			end,
			onCraft = function(familyId, typeId, oreId)
				if opts.onCraftOreTool then
					opts.onCraftOreTool(familyId, typeId, oreId)
				end
			end,
			onUpgrade = function(uid, n)
				if opts.onUpgradeOreTool then
					opts.onUpgradeOreTool(uid, n)
				end
			end,
			onRecycle = function(uid)
				if opts.onRecycleOreTool then
					opts.onRecycleOreTool(uid)
				end
			end,
		})
		benchCtl = okMount and ctl or nil
	end

	----------------------------------------------------------------------------
	-- TEMPERAMENT
	--
	-- A temperament rides the tool FAMILY, not the rung, so it belongs on the tab
	-- rather than on one card: whichever pickaxe you buy, this is the pickaxe's
	-- temperament. The bar says which one is fitted and opens a picker of the
	-- ones you own -- which is the "select what skin you want on it" half of the
	-- shop. Cases are opened at the Enchanter; this only moves what you have.
	----------------------------------------------------------------------------
	local Temper = require(shared:WaitForChild("MineTemper"))
	local FAMILY_TABS = { pickaxe = true, drill = true, explosive = true }

	local temperBar = mk("TextButton", {
		Name = "TemperBar", AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 712), Size = UDim2.fromOffset(680, 54),
		BackgroundColor3 = CARD, Text = "", AutoButtonColor = true, ZIndex = 85,
	}, root)
	round(temperBar, 12)
	local temperStroke = stroke(temperBar, 2, GOLD, 0.45)
	local temperDot = mk("Frame", {
		Position = UDim2.fromOffset(14, 13), Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 86,
	}, temperBar)
	round(temperDot, 8)
	local temperLbl = mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(54, 7),
		Size = UDim2.new(1, -200, 0, 22), Font = FONT, TextSize = 15, TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "", ZIndex = 86,
	}, temperBar)
	local temperSub = mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(54, 29),
		Size = UDim2.new(1, -200, 0, 18), Font = FONT_M, TextSize = 12, TextColor3 = MUTED,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "", ZIndex = 86,
	}, temperBar)
	local temperCta = mk("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(126, 32), BackgroundColor3 = GOLD, Font = FONT, TextSize = 13,
		TextColor3 = INK, Text = "CHANGE", ZIndex = 86,
	}, temperBar)
	round(temperCta, 8)

	local picker = mk("Frame", {
		Name = "TemperPicker", Visible = false, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(580, 440),
		-- Was 70, i.e. behind the old plate: a modal nothing could see. It has
		-- to outrank the header (90) and the temperament bar (85) it opens from.
		BackgroundColor3 = INK, ZIndex = 92,
	}, root)
	round(picker, 16)
	stroke(picker, 2, GOLD, 0.2)
	local pickTitle = mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 14), Size = UDim2.new(1, -80, 0, 26),
		Font = FONT, TextSize = 18, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "FIT A TEMPERAMENT", ZIndex = 71,
	}, picker)
	local pickClose = mk("TextButton", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 12),
		Size = UDim2.fromOffset(46, 46), BackgroundColor3 = Color3.fromRGB(70, 42, 54),
		Font = FONT, TextSize = 18, TextColor3 = Color3.fromRGB(255, 190, 190), Text = "X",
		AutoButtonColor = true, ZIndex = 72,
	}, picker)
	round(pickClose, 10)
	local pickList = mk("ScrollingFrame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 52),
		Size = UDim2.new(1, -32, 1, -68), CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ZIndex = 71,
	}, picker)
	mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, pickList)

	local function paintPicker()
		for _, ch in ipairs(pickList:GetChildren()) do
			if ch:IsA("GuiObject") then
				ch:Destroy()
			end
		end
		pickTitle.Text = "FIT A TEMPERAMENT  --  " .. string.upper(activeTab)
		local rows2 = {}
		for id, row in pairs(state.tempers or {}) do
			if Temper.kit(id) then
				table.insert(rows2, { id = id, rarity = row.rarity, n = tonumber(row.n) or 1 })
			end
		end
		if #rows2 == 0 then
			mk("TextLabel", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 60), Font = FONT_M, TextSize = 14,
				TextColor3 = MUTED, TextWrapped = true, ZIndex = 72,
				Text = "You do not own any temperaments yet. Open a Temperament Case at the Enchanter.",
			}, pickList)
			return
		end
		local rank = {}
		for i, g in ipairs(Temper.GRADE_ORDER) do
			rank[g] = i
		end
		table.sort(rows2, function(x, y)
			local rx, ry = rank[Temper.normalizeRarity(x.rarity)] or 0, rank[Temper.normalizeRarity(y.rarity)] or 0
			if rx ~= ry then
				return rx > ry
			end
			return tostring(x.id) < tostring(y.id)
		end)
		local fittedId = (state.toolTempers[activeTab] or {}).temperId
		for i, entry in ipairs(rows2) do
			local kit = Temper.kit(entry.id)
			local grade = Temper.normalizeRarity(entry.rarity)
			local tint = Temper.colorOf(grade)
			local fitted = fittedId == entry.id
			local b = mk("TextButton", {
				Size = UDim2.new(1, -6, 0, 64), BackgroundColor3 = fitted and Color3.fromRGB(52, 46, 26) or CARD,
				Text = "", AutoButtonColor = not fitted, LayoutOrder = i, ZIndex = 72,
			}, pickList)
			round(b, 10)
			stroke(b, fitted and 2 or 1, tint, fitted and 0.1 or 0.45)
			mk("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -130, 0, 20),
				Font = FONT, TextSize = 15, TextColor3 = tint, TextXAlignment = Enum.TextXAlignment.Left,
				Text = Temper.wordOf(grade) .. "  " .. tostring(kit.name) .. ((entry.n > 1) and ("   x" .. entry.n) or ""),
				ZIndex = 73,
			}, b)
			local bits = {}
			for _, line in ipairs(Temper.describe(entry.id, grade) or {}) do
				table.insert(bits, line.label .. " " .. line.text)
			end
			mk("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 30), Size = UDim2.new(1, -130, 0, 28),
				Font = FONT_M, TextSize = 12, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true, Text = table.concat(bits, "   "), ZIndex = 73,
			}, b)
			mk("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(96, 30), BackgroundColor3 = fitted and Color3.fromRGB(84, 70, 34) or GREEN,
				Font = FONT, TextSize = 12, TextColor3 = fitted and GOLD or Color3.fromRGB(16, 40, 24),
				Text = fitted and "FITTED" or "FIT", ZIndex = 73,
			}, b)
			if not fitted then
				b.MouseButton1Click:Connect(function()
					if opts.onFitTemper then
						opts.onFitTemper({ id = entry.id, family = activeTab })
					end
					picker.Visible = false
				end)
			end
		end
	end

	temperBar.MouseButton1Click:Connect(function()
		picker.Visible = true
		paintPicker()
	end)
	pickClose.MouseButton1Click:Connect(function()
		picker.Visible = false
	end)

	local function paintTemper()
		local on = FAMILY_TABS[activeTab] == true
		temperBar.Visible = on
		if not on then
			picker.Visible = false
			return
		end
		local tt = (state.toolTempers or {})[activeTab] or {}
		local kit = tt.temperId and Temper.kit(tt.temperId) or nil
		local grade = Temper.normalizeRarity(tt.temperRarity or (kit and kit.rarity))
		local tint = kit and Temper.colorOf(grade) or MUTED
		temperDot.BackgroundColor3 = tint
		temperStroke.Color = tint
		temperLbl.TextColor3 = kit and tint or TEXT
		temperLbl.Text = kit and (string.upper(Temper.wordOf(grade)) .. "  " .. tostring(kit.name))
			or "NO TEMPERAMENT FITTED"
		if kit then
			local bits = {}
			for _, line in ipairs(Temper.describe(tt.temperId, grade) or {}) do
				table.insert(bits, line.label .. " " .. line.text)
			end
			temperSub.Text = table.concat(bits, "   ")
		else
			temperSub.Text = "Open a Temperament Case at the Enchanter, then fit it here."
		end
		local owned = 0
		for _ in pairs(state.tempers or {}) do
			owned += 1
		end
		temperCta.Text = (owned > 0) and "CHANGE" or "NONE YET"
		temperCta.BackgroundColor3 = (owned > 0) and GOLD or Color3.fromRGB(70, 58, 62)
		temperCta.TextColor3 = (owned > 0) and INK or MUTED
		if picker.Visible then
			paintPicker()
		end
	end

	----------------------------------------------------------------------------
	-- STAGE: one big card, an arrow either side.
	----------------------------------------------------------------------------

	local function arrow(dir)
		local b = mk("TextButton", {
			Name = "Arrow" .. (dir < 0 and "L" or "R"),
			AnchorPoint = Vector2.new(dir < 0 and 0 or 1, 0.5),
			Position = dir < 0 and UDim2.new(0, 22, 0, 343) or UDim2.new(1, -22, 0, 343),
			Size = UDim2.fromOffset(62, 92), BackgroundColor3 = CARD,
			Text = dir < 0 and "<" or ">", Font = FONT, TextSize = 38, TextColor3 = TEXT,
			AutoButtonColor = false, ZIndex = 85,
		}, root)
		round(b, 16)
		local st = stroke(b, 2, T.LINE, 0.45)
		b.MouseEnter:Connect(function()
			if b.Active then b.BackgroundColor3 = CARD_HI; st.Transparency = 0.1 end
		end)
		b.MouseLeave:Connect(function()
			b.BackgroundColor3 = CARD; st.Transparency = 0.45
		end)
		b.MouseButton1Click:Connect(function()
			view.step(dir)
		end)
		return b, st
	end
	local leftBtn, leftStroke = arrow(-1)
	local rightBtn, rightStroke = arrow(1)

	local card = mk("Frame", {
		Name = "Stage",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.fromScale(0.88, 0.7),
		BackgroundTransparency = 1,
		ZIndex = 83,
		BorderSizePixel = 0,
	}, root)
	local cardStroke = nil -- no card chrome; theme bg + pedestal carry the look

	--[[
		THE STAGE IS THE SCREEN.

		This used to be a 1 x 0.62 box inside `card` with a solid backdrop, so
		the shop read as a window with a picture in it. It is the bottom layer of
		the whole panel now: edge to edge, no backdrop, no chrome, parented to
		`root` rather than `card` so the card's own bounds cannot clip it.

		Everything else in the shop draws on top. ZIndex 2 leaves room for a
		backdrop beneath if one is ever wanted, and every control already sits in
		the 80s and above.
	]]
	local vp = mk("ViewportFrame", {
		Name = "Preview",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(170, 178, 198),
		LightColor = Color3.fromRGB(255, 248, 230),
		LightDirection = Vector3.new(-0.4, -1, -0.55),
		-- Above the three backdrop layers (1-3), below every control (41+).
		-- This was 2, i.e. under the old background plate, which is what made
		-- the tools invisible.
		ZIndex = 5,
		BorderSizePixel = 0,
	}, root)
	local cam = mk("Camera", { FieldOfView = 40 }, vp)
	vp.CurrentCamera = cam

	local tierChip = mk("TextLabel", {
		Position = UDim2.fromOffset(28, 28), Size = UDim2.fromOffset(52, 26),
		BackgroundColor3 = FAMILY_TINT.pickaxe, Font = FONT, TextSize = 15,
		TextColor3 = Color3.fromRGB(24, 28, 40), Text = "T1", ZIndex = 86,
	}, card)
	round(tierChip, 9)

	local rarityChip = mk("TextLabel", {
		Position = UDim2.fromOffset(88, 28), Size = UDim2.fromOffset(110, 26),
		BackgroundColor3 = Color3.fromRGB(40, 44, 56), Font = FONT, TextSize = 13,
		TextColor3 = Color3.fromRGB(240, 244, 252), Text = "", Visible = false, ZIndex = 86,
	}, card)
	round(rarityChip, 9)

	local toolIcon = mk("ImageLabel", {
		Name = "ToolIcon",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(28, 200),
		Size = UDim2.fromOffset(64, 64),
		ScaleType = Enum.ScaleType.Fit,
		Image = "",
		Visible = false,
		ZIndex = 87,
	}, card)

	local flag = mk("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -28, 0, 28),
		Size = UDim2.fromOffset(96, 26), BackgroundColor3 = GOLD, Font = FONT, TextSize = 13,
		TextColor3 = Color3.fromRGB(40, 32, 10), Text = "", Visible = false, ZIndex = 86,
	}, card)
	round(flag, 9)

	local nameLbl = mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 234),
		Size = UDim2.new(1, 0, 0, 34), Font = FONT, TextSize = 28, TextColor3 = TEXT,
		Text = "", ZIndex = 85,
	}, card)

	local secretTag = mk("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 266),
		Size = UDim2.new(1, 0, 0, 22), Font = FONT, TextSize = 16,
		TextColor3 = Color3.fromRGB(0, 0, 0), Text = "Secret", Visible = false, ZIndex = 86,
	}, card)
	mk("UIStroke", {
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 2.2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
	}, secretTag)

	-- Stats as a row of pills: wide card, so horizontal reads better than a list.
	local statRow = mk("Frame", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 292),
		Size = UDim2.fromOffset(840, 58), ZIndex = 85,
	}, card)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
	}, statRow)

	local action = mk("TextButton", {
		Name = "Action", AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 342), Size = UDim2.fromOffset(340, 50),
		BackgroundColor3 = GREEN, Text = "", AutoButtonColor = true, ZIndex = 85,
	}, card)
	round(action, 14)
	local actionLbl = mk("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = FONT, TextSize = 19,
		TextColor3 = Color3.fromRGB(16, 40, 24), Text = "", ZIndex = 86,
	}, action)

	----------------------------------------------------------------------------
	-- FOOTER: where you are in the ladder.
	----------------------------------------------------------------------------

	local creditsStage = mk("ScrollingFrame", {
		Name = "SecretsStage",
		Position = UDim2.fromOffset(40, 80),
		Size = UDim2.new(1, -80, 1, -160),
		BackgroundTransparency = 1,
		ScrollBarThickness = 8, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false, ZIndex = 83,
	}, root)
	mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, creditsStage)
	mk("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8) }, creditsStage)

	local counter = mk("TextLabel", {
		Name = "Counter", AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 660), Size = UDim2.fromOffset(240, 24),
		BackgroundTransparency = 1, Font = FONT, TextSize = 16, TextColor3 = MUTED,
		Text = "", ZIndex = 83,
	}, root)

	local track = mk("Frame", {
		Name = "Track", AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 690), Size = UDim2.fromOffset(680, 6),
		BackgroundColor3 = Color3.fromRGB(52, 40, 32), ZIndex = 83,
	}, root)
	round(track, 3)
	local fill = mk("Frame", {
		Size = UDim2.fromScale(0, 1), BackgroundColor3 = FAMILY_TINT.pickaxe,
		BorderSizePixel = 0, ZIndex = 84,
	}, track)
	round(fill, 3)

	----------------------------------------------------------------------------
	-- FULLSCREEN LAYOUT
	--
	-- Everything above is authored at fixed pixel offsets against a ~1080-wide
	-- panel, which on a wide monitor left the shop as a small window with the
	-- item stranded in the middle of it. This is one pass that re-lays the same
	-- objects for a full-bleed screen; paint() only ever sets text and colour,
	-- so nothing here fights it.
	--
	-- The shape follows the brief: the item fills the screen, its stats sit
	-- directly above the buy button, and the category picker moves out of the
	-- way to the bottom right.
	----------------------------------------------------------------------------

	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Size = UDim2.fromScale(1, 1)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.BackgroundTransparency = 0.12
	local rootCorner = root:FindFirstChildOfClass("UICorner")
	if rootCorner then
		rootCorner.CornerRadius = UDim.new(0, 0)
	end

	header.Size = UDim2.new(1, 0, 0, 84)

	-- The stage: one big card, centred, with the model taking most of it.
	-- Full-screen stage: tool on a pedestal, stats/price/buy under it. No card box.
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	CARD_HOME = UDim2.fromScale(0.5, 0.46)
	card.Position = CARD_HOME
	card.Size = UDim2.fromScale(0.9, 0.78)
	card.BackgroundTransparency = 1


	tierChip.Position = UDim2.fromOffset(8, 8)
	rarityChip.Position = UDim2.fromOffset(68, 8)
	flag.Position = UDim2.new(1, -8, 0, 8)
	toolIcon.Visible = false

	nameLbl.Position = UDim2.new(0, 0, 0.64, 0)
	nameLbl.Size = UDim2.new(1, 0, 0, 40)
	nameLbl.TextSize = 36
	nameLbl.TextStrokeTransparency = 0.55
	secretTag.Position = UDim2.new(0, 0, 0.64, 36)

	local priceLbl = mk("TextLabel", {
		Name = "Price", BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0.72, 0), Size = UDim2.new(1, 0, 0, 28),
		Font = FONT, TextSize = 22, TextColor3 = GOLD, Text = "", ZIndex = 85,
		TextStrokeTransparency = 0.6,
	}, card)

	statRow.Position = UDim2.new(0.08, 0, 0.78, 0)
	statRow.Size = UDim2.new(0.84, 0, 0, 52)

	action.AnchorPoint = Vector2.new(0.5, 0)
	action.Position = UDim2.new(0.5, 0, 0.88, 0)
	action.Size = UDim2.fromOffset(360, 54)
	actionLbl.TextSize = 20

	leftBtn.AnchorPoint = Vector2.new(0, 0.5)
	leftBtn.Position = UDim2.new(0, 28, 0.45, 0)
	leftBtn.Size = UDim2.fromOffset(64, 110)
	leftBtn.BackgroundTransparency = 0.25
	rightBtn.AnchorPoint = Vector2.new(1, 0.5)
	rightBtn.Position = UDim2.new(1, -28, 0.45, 0)
	rightBtn.Size = UDim2.fromOffset(64, 110)
	rightBtn.BackgroundTransparency = 0.25

	counter.AnchorPoint = Vector2.new(0.5, 1)
	counter.Position = UDim2.new(0.5, 0, 1, -18)
	track.AnchorPoint = Vector2.new(0.5, 1)
	track.Position = UDim2.new(0.5, 0, 1, -10)
	track.Size = UDim2.new(0.28, 0, 0, 5)

	strip.AnchorPoint = Vector2.new(0.5, 1)
	strip.Position = UDim2.new(0.5, 0, 1, -44)
	strip.Size = UDim2.fromOffset(920, 48)
	local stripLayout = strip:FindFirstChildOfClass("UIListLayout")
	if stripLayout then
		stripLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	end
	for _, entry in pairs(tabBtns) do
		entry.button.Size = UDim2.fromOffset(164, 52)
	end

	creditsStage.AnchorPoint = Vector2.new(0.5, 0)
	creditsStage.Position = UDim2.new(0.5, 0, 0, 104)
	creditsStage.Name = "SecretsStage"
	creditsStage.Size = UDim2.new(0.72, 0, 0.72, 0)
	--[[
		THE STAGE HAS TO STAY A STAGE.

		The viewport was sized 1 x 0.62 of a card that is itself 0.9 x 0.78 of
		the screen, with nothing holding its shape. On a wide, short window --
		2000x740 is an ordinary one -- that works out to roughly 1800x360: a 5:1
		letterbox, in which the tool renders as a speck in the middle of a
		pedestal running the entire width. That is the "cooked" look.

		Roblox camera FOV is VERTICAL, so clamping the frame's ratio crops the
		dead space off the sides and leaves the tool rendering at exactly the
		size it did before. Centred, so it reads as an item on a plinth.
	]]
	--[[
		THE STAGE IS A PREVIEW AGAIN.
	
		This block used to reparent the ViewportFrame onto `root` at full
		screen with a transparent background, which made the 3D plinth the
		shop's backdrop. Two problems with that: it replaced the themed
		background the shop was designed around, and a ViewportFrame costs
		render time in proportion to its area -- at full screen it redraws the
		stage model over every pixel, every frame, which is what made the shop
		crawl.
	
		The PANEL is still the whole screen. Only the preview went back to
		being a preview: it keeps the size, colour and ZIndex it is built with
		above (inside `card`, 1 x 0.72, ZIndex 84).
	]]

	--[[
		The temperament bar is the one thing this pass missed. It sat on `root`
		at a flat 712px from the top, authored against the old ~1080-tall panel,
		so where it landed depended entirely on the window: over the tool on a
		short screen, adrift in the middle of nothing on a tall one.

		Pinned to the stage instead, on the viewport's bottom edge, so it reads
		as a ribbon across the plinth and sits in the same place at every size.
	]]
	temperBar.Parent = card
	temperBar.AnchorPoint = Vector2.new(0.5, 1)
	temperBar.Position = UDim2.new(0.5, 0, 0.62, 0)
	temperBar.Size = UDim2.fromOffset(560, 52)
	----------------------------------------------------------------------------
	-- FIT TO THE WINDOW
	--
	-- Nothing above this clamps to anything. There is no UISizeConstraint, no
	-- UIScale and no ViewportSize handler in this file, so the layout only ever
	-- held together near the size it was authored at:
	--
	--   * a 920-wide tab strip ran off both edges of a 1024 screen
	--   * a 560-wide temperament bar did the same on anything under ~600
	--   * the 580x440 picker did not fit a phone in either direction
	--   * the stage was centred at 0.46 of the SCREEN, so its top edge (0.07 of
	--     the height = 52px on a 740-tall window) slid under the 84px header,
	--     taking the tier and rarity chips under it with it
	--
	-- One pass, re-run whenever the viewport changes. Scale rather than reflow:
	-- a UIScale takes the widget and everything in it down together, which keeps
	-- the proportions the art was drawn to instead of inventing a second layout
	-- for small screens.
	----------------------------------------------------------------------------
	local fit = {
		strip = mk("UIScale", { Scale = 1 }, strip),
		bar = mk("UIScale", { Scale = 1 }, temperBar),
		pick = mk("UIScale", { Scale = 1 }, picker),
	}

	local function refit()
		local cam = workspace.CurrentCamera
		local size = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
		local W = math.max(320, size.X)
		local H = math.max(240, size.Y)
		-- Short windows get slimmer furniture, or the stage has nowhere to live.
		local headH = (H < 560) and 58 or 84
		local botH = (H < 560) and 74 or 104

		header.Size = UDim2.new(1, 0, 0, headH)

		-- The stage lives strictly between the header and the bottom bar.
		card.AnchorPoint = Vector2.new(0.5, 0)
		card.Size = UDim2.new(0.94, 0, 0, math.max(160, H - headH - botH - 16))
		CARD_HOME = UDim2.new(0.5, 0, 0, headH + 8)
		card.Position = CARD_HOME

		-- The tab strip holds #TABS fixed-width buttons; it needs room for all.
		local need = #TABS * 164 + math.max(0, #TABS - 1) * 10
		fit.strip.Scale = math.clamp((W - 40) / math.max(1, need), 0.3, 1)
		fit.bar.Scale = math.clamp((W - 40) / 560, 0.55, 1)
		fit.pick.Scale = math.clamp(math.min((W - 40) / 580, (H - 40) / 440), 0.45, 1)

		-- Arrows hug the edges, proportionally, instead of a flat 28px.
		local pad = math.clamp(math.floor(W * 0.014), 8, 28)
		leftBtn.Position = UDim2.new(0, pad, 0.45, 0)
		rightBtn.Position = UDim2.new(1, -pad, 0.45, 0)
		local arrowH = math.clamp(math.floor(H * 0.15), 64, 110)
		leftBtn.Size = UDim2.fromOffset(math.clamp(math.floor(W * 0.035), 38, 64), arrowH)
		rightBtn.Size = leftBtn.Size

		-- Type that reads at both ends: 36 on a desktop, not 36 on a phone.
		nameLbl.TextSize = math.clamp(math.floor(H * 0.05), 17, 36)
		actionLbl.TextSize = math.clamp(math.floor(H * 0.028), 13, 20)

		--[[
			The lower half is stacked bottom-up in PIXELS.

			It used to sit at scale positions -- name 0.64, price 0.72, stats
			0.78, buy 0.88 of the card -- while every row kept a fixed pixel
			height. So the gaps shrank with the window and the rows did not: at
			800x600 the stats row landed 24px below a 28px price, and on a phone
			in landscape the buy button ran off the bottom of the card entirely.

			Measured from the bottom, with real heights and a real gap, the stack
			cannot collide at any size. Whatever is left over above it is the
			stage, which is why the viewport is sized here rather than at 0.62.
		]]
		local nameH = math.clamp(math.floor(H * 0.055), 22, 40)
		local priceH = math.clamp(math.floor(H * 0.038), 18, 28)
		local statH = math.clamp(math.floor(H * 0.072), 34, 52)
		local actH = math.clamp(math.floor(H * 0.075), 38, 54)
		local gap = math.clamp(math.floor(H * 0.012), 4, 10)
		local CH = card.Size.Y.Offset

		action.AnchorPoint = Vector2.new(0.5, 0)
		action.Size = UDim2.fromOffset(math.clamp(math.floor(W * 0.28), 190, 360), actH)
		local y = CH - actH
		action.Position = UDim2.new(0.5, 0, 0, y)

		y -= gap + statH
		statRow.Position = UDim2.new(0.08, 0, 0, y)
		statRow.Size = UDim2.new(0.84, 0, 0, statH)

		y -= gap + priceH
		priceLbl.Position = UDim2.new(0, 0, 0, y)
		priceLbl.Size = UDim2.new(1, 0, 0, priceH)
		priceLbl.TextSize = math.clamp(math.floor(priceH * 0.8), 12, 22)

		y -= gap + nameH
		nameLbl.Position = UDim2.new(0, 0, 0, y)
		nameLbl.Size = UDim2.new(1, 0, 0, nameH)
		secretTag.Position = UDim2.new(0, 0, 0, y + nameH)

		-- The viewport is the window now, so nothing here sizes it. The ribbon
		-- just sits above the name, wherever the stack put it.
		temperBar.Position = UDim2.new(0.5, 0, 0, math.max(52, y - gap))
	end

	refit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
	end

	----------------------------------------------------------------------------
	-- PREVIEW
	----------------------------------------------------------------------------

	----------------------------------------------------------------------------
	-- THE STAGE
	--
	-- A ViewportFrame with nothing in it but the model renders as a tool floating
	-- in flat colour, which is what made this look wrong. This is a room: a back
	-- wall, a floor catching the light, and a plinth the tool actually stands on.
	-- Built once at mount; setModel only ever swaps the model.
	----------------------------------------------------------------------------
	local function buildStage()
		-- Pedestal only — no workshop room. Clear ViewportFrame shows the shop
		-- background art around the tool so themes can breathe.
		local stage = Instance.new("Model")
		stage.Name = "Stage"
		local function slab(size, cf, colour, material)
			local p2 = Instance.new("Part")
			p2.Anchored = true
			p2.CanCollide = false
			p2.CanQuery = false
			p2.Size = size
			p2.CFrame = cf
			p2.Color = colour
			p2.Material = material or Enum.Material.SmoothPlastic
			p2.TopSurface = Enum.SurfaceType.Smooth
			p2.BottomSurface = Enum.SurfaceType.Smooth
			p2.Parent = stage
			return p2
		end
		local SOOT = Color3.fromRGB(42, 36, 34)
		local STONE = Color3.fromRGB(72, 66, 60)
		local METAL = Color3.fromRGB(92, 88, 82)
		-- Stepped plinth
		local base = slab(Vector3.new(18, 1.4, 18),
			CFrame.new(0, -13.1, 0) * CFrame.Angles(0, math.rad(45), 0),
			SOOT, Enum.Material.Slate)
		base.Name = "PlinthBase"
		local mid = slab(Vector3.new(13.5, 1.1, 13.5),
			CFrame.new(0, -12.0, 0) * CFrame.Angles(0, math.rad(45), 0),
			STONE, Enum.Material.Slate)
		mid.Name = "PlinthMid"
		local cap = slab(Vector3.new(10.5, 0.75, 10.5),
			CFrame.new(0, -11.15, 0) * CFrame.Angles(0, math.rad(45), 0),
			METAL, Enum.Material.Metal)
		cap.Name = "PlinthCap"
		cap.Reflectance = 0.04
		--[[
			No ground slab.

			At 36 studs it fitted inside the old letterbox, but full screen its
			rim crosses the frame as a hard horizon line -- a floating slab edge
			with nothing under it. Growing it only moves the edge further out;
			at some aspect ratio it always reappears. The plinth alone reads as
			an object on a surface, so the slab goes.
		]]
		return stage
	end
	local stage = buildStage()
	stage.Parent = vp
	-- Warmer key light and a lifted ambient, or the room reads as a black box.
	vp.Ambient = Color3.fromRGB(142, 122, 100)
	vp.LightColor = Color3.fromRGB(255, 232, 196)
	vp.LightDirection = Vector3.new(-0.45, -0.8, -0.5)
	-- No backdrop, ever. The shop's own background art is what sits behind the
	-- pedestal; painting a colour here is what produced the dark rectangle.
	vp.BackgroundTransparency = 1

	-- Drag to spin. A shop that shows one fixed angle hides half of what you are
	-- buying, and these models are asymmetric.
	local userYaw, dragging, lastX, grabbed = 0, false, 0, false
	vp.Active = true
	vp.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging, lastX, grabbed = true, input.Position.X, true
		end
	end)
	vp.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			userYaw += (input.Position.X - lastX) * 0.011
			lastX = input.Position.X
		end
	end)
	local function release(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end
	vp.InputEnded:Connect(release)

	-- Each family is authored along a different axis, so one camera angle cannot
	-- flatter all of them: at yaw 0 you look down a drill's own barrel.
	-- Models are stood upright and centred now, so the per-family yaw that used
	-- to compensate for authored axes is gone. What is left is framing: a slight
	-- three-quarter turn, and a near-level eye so the plinth reads as a surface
	-- rather than as the subject of the shot.
	local HERO = {
		pickaxe = { yaw = math.rad(26), pitch = math.rad(-4) },
		explosive = { yaw = math.rad(26), pitch = math.rad(-4) },
		drill = { yaw = math.rad(26), pitch = math.rad(-4) },
		backpack = { yaw = math.rad(22), pitch = math.rad(-3) },
		secrets = { yaw = math.rad(26), pitch = math.rad(-4) },
	}

	local rows -- forward-declared: setModel below calls it, definition is further down
	local shown, sway = nil, 0

	--[[
		FRAMING.

		Two jobs, both driven off the real pixel shape rather than constants.

		Distance: a ViewportFrame's FieldOfView is VERTICAL, so on a portrait
		phone the horizontal angle is much narrower and a box fitted to the
		vertical FOV runs off the sides. Horizontal FOV is
		2*atan(tan(v/2) * aspect); fitting against the SMALLER of the two means a
		narrow screen zooms out instead of cropping the tool.

		Height: the tool must not sit behind the name, price, stats or BUY. The
		free band is measured from the real AbsolutePosition of the header and of
		the topmost thing in the bottom stack, and the camera target is nudged so
		the pedestal lands in the middle of THAT, not the middle of the screen.
	]]
	local FIT_MARGIN = 1.15
	local aimOffsetY = 0

	local function frameStage()
		local px = vp.AbsoluteSize
		if px.X < 2 or px.Y < 2 then
			return
		end
		local aspect = px.X / math.max(1, px.Y)
		local vFov = math.rad(cam.FieldOfView)
		local hFov = 2 * math.atan(math.tan(vFov * 0.5) * aspect)
		local fov = math.min(vFov, hFov)

		local radius = (shown and shown:GetAttribute("Radius")) or 12
		local dist = radius / math.max(0.05, math.sin(fov * 0.5)) * FIT_MARGIN
		if shown then
			shown:SetAttribute("Dist", dist)
		end

		-- The band the stage may actually use, in pixels down the panel.
		local top = header.AbsoluteSize.Y
		local bottomY = px.Y
		for _, gui in ipairs({ nameLbl, priceLbl, statRow, action, temperBar }) do
			if gui and gui.Visible and gui.AbsoluteSize.Y > 0 then
				local y = gui.AbsolutePosition.Y - vp.AbsolutePosition.Y
				if y > top and y < bottomY then
					bottomY = y
				end
			end
		end
		local bandMid = (top + bottomY) * 0.5
		local screenMid = px.Y * 0.5
		-- Pixels off centre -> world units at the subject's distance.
		local worldPerPx = (2 * dist * math.tan(vFov * 0.5)) / math.max(1, px.Y)
		aimOffsetY = (screenMid - bandMid) * worldPerPx
	end

	vp:GetPropertyChangedSignal("AbsoluteSize"):Connect(frameStage)
	local function setModel(family, tier, count, locked, toolId)
		if shown then
			shown:Destroy()
			shown = nil
		end
		local model
		local shopRow = toolId and ShopLadders.byId and ShopLadders.byId(toolId)
		local meshName = shopRow and shopRow.name
		local zoneIndex = tonumber(shopRow and shopRow.zoneIndex) or 1
		-- Match ToolModels_50 by shop name (Bronzewedge = leaf pick, etc.).
		-- Skip a few early authored meshes that look wrong; those stay procedural.
		local SKIP_NAMED = { Sodpick = true }
		local allowNamed = (not locked) and meshName and meshName ~= "UNNAMED"
			and not SKIP_NAMED[meshName] and Factory.fromNamed
		if allowNamed then
			local namedModel = Factory.fromNamed(meshName, "Normal", family)
			if namedModel then
				model = namedModel
			end
		end
		if (not locked) and (not model) then
			local previewRoot = RS:WaitForChild("Mine"):FindFirstChild("ToolPreviews")
			local preview = toolId and previewRoot and previewRoot:FindFirstChild(tostring(toolId))
			if preview then
				model = preview:Clone()
				if model:IsA("Model") then
					local handle = model:FindFirstChild("Handle", true)
					if handle and handle:IsA("BasePart") then
						model.PrimaryPart = handle
					elseif not model.PrimaryPart then
						local part = model:FindFirstChildWhichIsA("BasePart", true)
						if part then model.PrimaryPart = part end
					end
				end
			end
		end
		if locked then
			-- Identical early silhouette for every locked card — no unique HQ shape leak.
			if family == "backpack" and Factory.backpack then
				model = Factory.backpack(2, count)
			else
				local fam = (family == "secrets") and "pickaxe" or family
				model = Factory.build(fam, 2, math.max(count or 14, 14))
			end
		elseif not model and family == "backpack" then
			local bagRow = nil
			pcall(function() bagRow = rows()[tier] end)
			model = Factory.backpack(tier, count, bagRow)
		elseif not model and family == "secrets" then
			local row = rows()[tier]
			local fam = (row and row.family) or "pickaxe"
			local powerTier = math.clamp(math.floor(1 + math.log10(math.max(10, (row and row.power) or 1)) * 4), 1, 14)
			model = Factory.build(fam, powerTier, 14)
		elseif not model then
			model = Factory.build(family, tier, count)
		end
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				if locked then
					d.Color = Color3.fromRGB(8, 8, 10)
					d.Material = Enum.Material.SmoothPlastic
					d.Reflectance = 0
					d.Transparency = 0
				end
			elseif d:IsA("WeldConstraint") then
				d:Destroy()
			elseif locked and (d:IsA("Decal") or d:IsA("Texture")) then
				d:Destroy()
			elseif locked and (d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight")) then
				d.Enabled = false
			end
		end
		-- Stand it up. Each family is authored along a different axis -- a pick
		-- along one, a drill down another -- so laying them all at identity is
		-- what had tools floating sideways. Rotate whichever axis is longest to
		-- vertical and every one of them stands on the plinth the same way.
		model:PivotTo(CFrame.identity)

		-- Stand it on its HANDLE, not on its longest side.
		--
		-- Rotating whichever axis is longest to vertical works right up until the
		-- head outgrows the haft -- from T17 the pick heads are wider than the
		-- shaft is long, so "longest axis" picked the head and laid the tool flat.
		-- Every model the factory builds names its grip "Handle", and the handle's
		-- own long axis is the shaft, which is the thing that should point up.
		local upright = CFrame.identity
		local handle = model:FindFirstChild("Handle", true)
		if handle and handle:IsA("BasePart") then
			local s = handle.Size
			local localAxis
			if s.X >= s.Y and s.X >= s.Z then
				localAxis = Vector3.xAxis
			elseif s.Y >= s.Z then
				localAxis = Vector3.yAxis
			else
				localAxis = Vector3.zAxis
			end
			local shaft = handle.CFrame:VectorToWorldSpace(localAxis)
			if shaft.Magnitude > 1e-4 then
				shaft = shaft.Unit
				local axis = shaft:Cross(Vector3.yAxis)
				local dot = math.clamp(shaft:Dot(Vector3.yAxis), -1, 1)
				if axis.Magnitude > 1e-4 then
					upright = CFrame.fromAxisAngle(axis.Unit, math.acos(dot))
				elseif dot < 0 then
					-- Pointing straight down: flip it.
					upright = CFrame.Angles(math.pi, 0, 0)
				end
			end
		else
			-- No handle (backpacks): fall back to the longest side.
			local _, raw = model:GetBoundingBox()
			if raw.X >= raw.Y and raw.X >= raw.Z then
				upright = CFrame.Angles(0, 0, math.rad(90))
			elseif raw.Z >= raw.Y and raw.Z >= raw.X then
				upright = CFrame.Angles(math.rad(90), 0, 0)
			end
		end
		model:PivotTo(upright)

		-- Sit it on the plinth rather than through it.
		local centre, size = model:GetBoundingBox()
		model:TranslateBy(-centre.Position + Vector3.new(0, size.Y * 0.5 - 10.75, 0))
		model.Parent = vp
		shown = model

		centre, size = model:GetBoundingBox()

		-- The plinth follows the tool. A fixed 16-stud block dwarfed a 4-stud
		-- pick and read as the subject of the shot.
		local foot = math.max(size.X, size.Z)
		local basePart = stage:FindFirstChild("PlinthBase")
		local capPart = stage:FindFirstChild("PlinthCap")
		if basePart then
			basePart.Size = Vector3.new(foot * 1.9 + 1.2, 1.6, foot * 1.9 + 1.2)
		end
		if capPart then
			capPart.Size = Vector3.new(foot * 1.45 + 0.8, 0.9, foot * 1.45 + 0.8)
		end

		-- Present the broad face. Standing a pick upright leaves its head wide in
		-- one horizontal axis and thin in the other; the camera should sit on the
		-- thin side so you are looking at the face, not the edge.
		do
			local lo = Vector3.new(math.huge, math.huge, math.huge)
			local hi = -lo
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") then
					for sx = -1, 1, 2 do
						for sy = -1, 1, 2 do
							for sz = -1, 1, 2 do
								local corner = (d.CFrame * CFrame.new(
									d.Size.X * 0.5 * sx, d.Size.Y * 0.5 * sy, d.Size.Z * 0.5 * sz)).Position
								lo = Vector3.new(math.min(lo.X, corner.X), math.min(lo.Y, corner.Y), math.min(lo.Z, corner.Z))
								hi = Vector3.new(math.max(hi.X, corner.X), math.max(hi.Y, corner.Y), math.max(hi.Z, corner.Z))
							end
						end
					end
				end
			end
			local world = hi - lo
			shown:SetAttribute("FaceYaw", (world.X >= world.Z) and 0 or math.rad(90))
		end

		--[[
			RADIUS IS MEASURED FROM WHERE THE CAMERA ACTUALLY LOOKS.

			Distance is fitted against a bounding SPHERE rather than the longest
			side, because the camera orbits: a pick that fits the frame face-on
			swings wider when you drag it side-on, and fitting the longest edge
			alone crops it mid-turn.

			The sphere has to be centred on the point the camera orbits, and it
			was not. The camera aims at `centre` -- the TOOL's box centre, about
			y = -9.7, because the tool stands on the plinth -- but the radius was
			sqrt(9^2 + 14^2) = 16.64, a sphere about the WORLD ORIGIN. Measuring
			the subject from one point and orbiting about another overstates the
			fit: everything that must be in frame is within ~8 studs of the aim
			point, so the camera sat at 56 studs instead of 27 and framed a
			33-stud-wide view around a 4-stud pickaxe. The tool was rendering --
			it was a speck on a big empty plinth.

			The union of the plinth and the tool, measured corner by corner from
			the aim point. No magic constants, so a taller plinth or a longer
			tool reframes itself.
		]]
		local aim = centre.Position
		local function reachFrom(boxCF, boxSize)
			local h = boxSize * 0.5
			local worst = 0
			for _, sx in ipairs({ -1, 1 }) do
				for _, sy in ipairs({ -1, 1 }) do
					for _, sz in ipairs({ -1, 1 }) do
						local corner = (boxCF * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
						worst = math.max(worst, (corner - aim).Magnitude)
					end
				end
			end
			return worst
		end
		--[[
			The plinth is ROUND, so its box corners are a lie.

			A 13.5-stud disc has a bounding box whose corners reach
			sqrt(6.75^2 + 6.75^2) = 9.55 studs out, where the disc itself never
			passes 6.75. Walking those corners inflated the radius by root two in
			the horizontal plane -- 10.45 against a true 7.98 -- and the camera
			backed up to make room for air that is not there.

			Measured as the cylinder it is: the horizontal reach is the disc
			radius, and only the vertical extremes vary.
		]]
		local function reachFromCylinder(boxCF, boxSize)
			local h = boxSize * 0.5
			local hr = math.max(h.X, h.Z)
			local worst = 0
			for _, sy in ipairs({ -1, 1 }) do
				local dy = (boxCF * CFrame.new(0, h.Y * sy, 0)).Position.Y - aim.Y
				local dxz = (Vector3.new(boxCF.Position.X, aim.Y, boxCF.Position.Z)
					- Vector3.new(aim.X, aim.Y, aim.Z)).Magnitude
				worst = math.max(worst, math.sqrt((dxz + hr) ^ 2 + dy * dy))
			end
			return worst
		end

		local radius = reachFrom(centre, size)
		if stage then
			local okBox, scf, ssz = pcall(function()
				return stage:GetBoundingBox()
			end)
			-- pcall returns (ok, cf, size); a Model with no parts throws.
			if okBox and scf and ssz then
				radius = math.max(radius, reachFromCylinder(scf, ssz))
			end
		end
		-- Floor it so a tiny tool on an empty stage cannot put the camera inside
		-- the plinth it is standing on.
		radius = math.max(radius, 4)
		shown:SetAttribute("Radius", radius)
		--[[
			A DISTANCE THAT IS ALWAYS SET.

			frameStage() does the real fitting, but it returns early while the
			panel has no pixels -- and on the frame the shop opens,
			vp.AbsoluteSize is (0, 0). Dist was written ONLY in there, so the
			render loop fell through to `or 6`: six studs from the middle of a
			plinth eighteen across, which is a camera inside the pedestal.

			Seeded from the radius alone here, so the first frame already looks
			at the tool from outside it and frameStage only ever refines this.
		]]
		shown:SetAttribute("Dist",
			radius / math.max(0.05, math.sin(math.rad(cam.FieldOfView) * 0.5)) * FIT_MARGIN)
		shown:SetAttribute("Cx", centre.Position.X)
		shown:SetAttribute("Cy", centre.Position.Y)
		shown:SetAttribute("Cz", centre.Position.Z)
		frameStage()
	end

	RunService.RenderStepped:Connect(function(dt)
		if not root.Visible or not shown or not shown.Parent then
			return
		end
		sway += dt
		local hero = HERO[activeTab] or HERO.pickaxe
		-- Idle drift until you grab it; after that the angle is yours.
		local drift = grabbed and 0 or math.sin(sway * 0.6) * 0.30
		local a = (shown:GetAttribute("FaceYaw") or 0) + hero.yaw + userYaw + drift
		local centre = Vector3.new(shown:GetAttribute("Cx") or 0,
			shown:GetAttribute("Cy") or 0, shown:GetAttribute("Cz") or 0)
		-- aimOffsetY slides the subject down the frame so it sits in the gap
		-- between the header and the name/stats/BUY stack, not the screen middle.
		cam.CFrame = CFrame.new(centre + Vector3.new(0, aimOffsetY, 0))
			* CFrame.Angles(0, a, 0) * CFrame.Angles(hero.pitch, 0, 0)
			* CFrame.new(0, 0, shown:GetAttribute("Dist") or 6)
	end)

	----------------------------------------------------------------------------
	-- STATE
	----------------------------------------------------------------------------

	local function ownedSecretIds()
		local have = {}
		for _, row in ipairs(state.chestTools or {}) do
			local id = (type(row) == "table") and row.id or row
			if type(id) == "string" then
				have[id] = true
			end
		end
		return have
	end

	local function secretRankList()
		local list = {}
		for _, t in ipairs(Tools.CHEST_TOOLS or {}) do
			table.insert(list, t)
		end
		table.sort(list, function(a, b)
			local ba = Tools.budget(a)
			local bb = Tools.budget(b)
			if ba == bb then
				return (a.name or a.id or "") < (b.name or b.id or "")
			end
			return ba < bb
		end)
		return list
	end

	function rows()
		-- The bench is a list, not a shelf: no rungs to step through.
		if activeTab == "bench" then
			return {}
		end
		if activeTab == "backpack" then
			local Bags = require(shared:WaitForChild("MineBags"))
			if Bags.shopRows then
				return Bags.shopRows(state.maxUnlockedZone or state.zoneIndex or 1, "shallow")
			end
			return C.BACKPACKS
		end
		if activeTab == "secrets" then
			return secretRankList()
		end
		if state.zoneId == "bigbang" then
			local okH, Horizon = pcall(function()
				return require(shared:WaitForChild("MineHorizonTools"))
			end)
			if okH and Horizon and Horizon.shopRows then
				return Horizon.shopRows(activeTab)
			end
		end
		-- Surface ladder filtered to the active family tab.
		local all = ShopLadders.surfaceCatalog()
		local out = {}
		for _, row in ipairs(all) do
			if (row.family or "pickaxe") == activeTab then
				table.insert(out, row)
			end
		end
		return out
	end

	local function ownedShopSet()
		local set = state.ownedShopTools or {}
		if set[1] ~= nil or next(set) == nil then
			-- array form from snap → map
			local map = {}
			if type(set) == "table" then
				for k, v in pairs(set) do
					if type(k) == "string" and v then map[k] = true
					elseif type(v) == "string" then map[v] = true
					end
				end
			end
			return map
		end
		return set
	end

	local function ownedCount()
		if activeTab == "backpack" then
			return state.backpackTier or 1
		end
		if activeTab == "secrets" then
			return 0
		end
		local n = 0
		local owned = ownedShopSet()
		for _, row in ipairs(rows()) do
			if owned[row.id] then n += 1 end
		end
		return n
	end

	--[[
		What this rung is to the player right now.

		"held" you are swinging it · "owned" bought · "buy" the next rung and
		affordable · "short" the next rung, not affordable · "locked" further up.
	]]
	local function statusOf(i)
		if activeTab == "secrets" then
			local row = rows()[i]
			if row and ownedSecretIds()[row.id] then
				if state.chestTool == row.id then
					return "held"
				end
				return "owned"
			end
			return "locked"
		end
		local row = rows()[i]
		if not row then
			return "locked"
		end
		if row.eventOnly then
			local ownedEv = state.eventTools and state.eventTools[row.id]
			if ownedEv then
				return (state.eventToolId == row.id) and "held" or "owned"
			end
			local price = row.price or 0
			if price <= 0 then
				return "buy"
			end
			return ((state.spaceCoins or 0) >= price) and "buy" or "short"
		end
		if activeTab == "backpack" then
			local owned = ownedCount()
			local tier = math.floor(tonumber(row.tier) or i)
			if tier <= owned then
				return "owned"
			end
			local needZone = math.floor(tonumber(row.minZone) or 1)
			if needZone > (state.maxUnlockedZone or 1) then
				return "zone"
			end
			if row.robux then
				return "buy"
			end
			local price = row.price or 0
			return ((state.coins or 0) >= price) and "buy" or "short"
		end
		-- Surface shop ladder (all zones visible).
		local needZone = math.floor(tonumber(row.zoneIndex) or 1)
		if needZone > (state.maxUnlockedZone or 1) then
			return "zone"
		end
		local owned = ownedShopSet()
		if owned[row.id] then
			if state.shopToolId == row.id then
				return "held"
			end
			return "owned"
		end
		local price = row.price or 0
		return ((state.coins or 0) >= price) and "buy" or "short"
	end

	local function paint()
		creditLbl.Text = money(state.credits or 0)
		coinLbl.Text = money(state.coins or 0)
		gemLbl.Text = money(state.gems or 0)
		dustLbl.Text = money(state.dust or 0)
		tokenLbl.Text = money(state.tokens or 0)

		for id, t in pairs(tabBtns) do
			local on = (id == activeTab)
			t.button.BackgroundColor3 = on and CARD_HI or CARD
			t.stroke.Transparency = on and 0.05 or 0.6
			t.label.TextColor3 = on and TEXT or MUTED
			if id == "bench" then
				-- How many tools there are to work on, not a have/total: every
				-- ore tool you own is levellable, so a denominator is noise.
				t.count.Text = tostring(#(state.oreTools or {}))
			elseif id == "secrets" then
				local have = 0
				local total = #(Tools.CHEST_TOOLS or {})
				local owned = {}
				for _, row in ipairs(state.chestTools or {}) do
					local sid = (type(row) == "table") and row.id or row
					if type(sid) == "string" then owned[sid] = true end
				end
				for _, t in ipairs(Tools.CHEST_TOOLS or {}) do
					if owned[t.id] then have += 1 end
				end
				t.count.Text = string.format("%d/%d", have, total)
			else
				-- BACKPACKS carries fossil, Robux and event bags that are not on
				-- the coin shelf, so #BACKPACKS read "60/112" against a shelf of
				-- 93. Count the rungs a player can actually buy, on both sides.
				local bagTotal, bagHave = 0, 0
				do
					local okB, Bags = pcall(function()
						return require(shared:WaitForChild("MineBags"))
					end)
					local tier = math.floor(tonumber(state.backpackTier) or 1)
					if okB and Bags and Bags.sellable then
						for bi, br in ipairs(Bags.LIST or {}) do
							if Bags.sellable(br) then
								bagTotal += 1
								if bi <= tier then bagHave += 1 end
							end
						end
					else
						bagTotal, bagHave = #C.BACKPACKS, tier
					end
				end
				local total = (id == "backpack") and bagTotal
					or (id == "secrets") and #(Tools.CHEST_TOOLS or {})
					or #ShopLadders.surfaceCatalog()
				local have = (id == "backpack") and bagHave
					or (id == "secrets") and 0
					or ownedCount()
				t.count.Text = string.format("%d/%d", have, total)
			end
			t.count.TextColor3 = on and t.tint or MUTED
			if on then sub.Text = t.blurb end
		end

		paintTemper()
		--[[
			The bench replaces the stage rather than sitting beside it.

			Everything the carousel owns -- the card, both arrows, the counter,
			the track, the temperament bar and the 3D preview itself -- is about
			ONE tool you are choosing between rungs. The bench is a list of tools
			you already own, so leaving the pedestal running behind it would show
			a tool that has nothing to do with the rows.
		]]
		--[[
			The Forge is the tab the shop opens on, so a missing panel is no
			longer a tab you simply do not click -- it would be a blank screen
			on open for every player. If the module failed to require, fall back
			to the first coin-shop family instead.
		]]
		if activeTab == "bench" and not benchPanel then
			activeTab = "pickaxe"
		end
		if activeTab == "bench" then
			creditsStage.Visible = false
			card.Visible = false
			leftBtn.Visible = false
			rightBtn.Visible = false
			counter.Visible = false
			track.Visible = false
			temperBar.Visible = false
			vp.Visible = false
			if benchPanel then
				benchPanel.Visible = true
			end
			if benchCtl and benchCtl.refresh then
				pcall(benchCtl.refresh)
			end
			return
		end
		if benchPanel then
			benchPanel.Visible = false
		end
		vp.Visible = true

		local isSecrets = activeTab == "secrets"
		creditsStage.Visible = false
		card.Visible = true
		leftBtn.Visible = true
		rightBtn.Visible = true
		counter.Visible = true
		track.Visible = true

		local list = rows()
		if #list == 0 then
			return
		end
		index = math.clamp(index, 1, #list)
		local row = list[index]
		local status = statusOf(index)
		local tint = FAMILY_TINT[(isSecrets and row.family) or row.family or activeTab] or GOLD
		local currency = "coins"
		if activeTab == "backpack" and row.robux then
			currency = "Robux"
		elseif row.eventOnly or row.currency == "space" then
			currency = "space"
		end

		local blackout = (status == "locked" or status == "zone")
		local modelFamily = (not isSecrets and row.family) or activeTab
		local lookTier = index
		if row.power then
			lookTier = math.clamp(math.floor(1 + math.log10(math.max(10, row.power)) * 4), 1, math.max(14, #list))
		end
		setModel(modelFamily, lookTier, math.max(#list, 14), blackout, row.id)
		vp.ImageTransparency = blackout and 0.35 or 0

		tierChip.Text = "#" .. tostring(row.shopTier or index)
		-- Coin ladder / backpacks: family tint only. Secrets keep rarity chrome.
		local rar = (isSecrets and not blackout) and toolRarityOf(row, modelFamily, index, #list) or nil
		local rarInk = rarityColor(rar)
		local strokeInk = rarInk or tint
		tierChip.BackgroundColor3 = isSecrets and Color3.fromRGB(20, 20, 24) or (status == "zone" and Color3.fromRGB(20, 20, 24) or tint)
		-- cardStroke removed (no card chrome)
		if rar and not blackout then
			rarityChip.Visible = true
			rarityChip.Text = rar
			rarityChip.BackgroundColor3 = rarInk or tint
			rarityChip.TextColor3 = Color3.fromRGB(18, 20, 28)
		else
			rarityChip.Visible = false
		end
		do
			local iconUrl = Icons.image(row.id)
				or Icons.image(row.family or modelFamily)
				or Icons.image(activeTab)
				or Icons.image("pickaxe")
			if iconUrl then
				toolIcon.Image = iconUrl
				toolIcon.Visible = true
				toolIcon.ImageColor3 = blackout and Color3.fromRGB(28, 28, 34) or Color3.new(1, 1, 1)
				toolIcon.ImageTransparency = blackout and 0.2 or 0
			else
				toolIcon.Visible = false
			end
		end

		flag.Visible = (status == "held" or status == "owned")
		if status == "held" then
			flag.Text = "EQUIPPED"
			flag.BackgroundColor3 = GOLD
			flag.TextColor3 = Color3.fromRGB(40, 32, 10)
		elseif status == "owned" then
			flag.Text = isSecrets and "FOUND" or "OWNED"
			flag.BackgroundColor3 = Color3.fromRGB(44, 92, 66)
			flag.TextColor3 = GREEN
		end

		if blackout then
			nameLbl.Text = "???"
			nameLbl.TextTransparency = 0
			nameLbl.TextColor3 = Color3.fromRGB(40, 40, 48)
		else
			nameLbl.Text = row.name
			nameLbl.TextTransparency = 0
			nameLbl.TextColor3 = TEXT
		end
		secretTag.Visible = isSecrets
		secretTag.TextTransparency = (isSecrets and status == "locked") and 0.25 or 0

		for _, c in ipairs(statRow:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local statFamily = isSecrets and (row.family or "pickaxe") or (row.family or activeTab)
		local lines = (status == "zone") and {}
			or (isSecrets and status == "locked") and { { "Rank", "#" .. index }, { "Rarity", "Secret" } }
			or statLines(statFamily, row)
		-- Every shop tool has its own rune slot. Rebirth takes the tool back but
		-- not the rune, which waits in the slot until the tool is bought again.
		if not isSecrets and activeTab ~= "backpack" and status ~= "zone" then
			local rid = (state.shopToolRunes or {})[row.id]
			local rune
			for _, r in ipairs(state.runes or {}) do
				if r.id == rid then
					rune = r
					break
				end
			end
			local owned = status == "owned" or status == "held"
			local label = "RUNE SLOT"
			if rune then
				local okS, Stats = pcall(require, shared:WaitForChild("MineStats"))
				local def = okS and Stats.STATS and Stats.STATS[rune.stat]
				label = owned and ("RUNE · " .. tostring(def and def.label or rune.stat))
					or ("WAITING · " .. tostring(def and def.label or rune.stat))
			end
			table.insert(lines, {
				label,
				rune and string.format("+%.1f%%", (rune.pct or 0) * 100) or "Empty",
				rune and GREEN or MUTED,
			})
		end
		for i, sl in ipairs(lines) do
			local pill = mk("Frame", {
				Size = UDim2.fromOffset(158, 54), BackgroundColor3 = Color3.fromRGB(58, 44, 35),
				BackgroundTransparency = 0.15, LayoutOrder = i, ZIndex = 86,
			}, statRow)
			round(pill, 12)
			mk("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 7),
				Size = UDim2.new(1, 0, 0, 16), Font = FONT_M, TextSize = 12, TextColor3 = MUTED,
				Text = sl[1], ZIndex = 87,
			}, pill)
			mk("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 24),
				Size = UDim2.new(1, 0, 0, 24), Font = FONT, TextSize = 18,
				TextColor3 = sl[3] or ((status == "locked") and MUTED or tint),
				Text = sl[2], ZIndex = 87,
			}, pill)
		end

		local price = row.price or 0
		if row.robux then
			price = row.robuxPrice or 0
		end
		-- The number you scan for. OWNED items have no price to show.
		if status == "buy" or status == "short" then
			priceLbl.Text = (row.robux and commas(price) or money(price)) .. " " .. (row.robux and "Robux" or currency)
			priceLbl.TextColor3 = (status == "short") and Color3.fromRGB(255, 150, 150) or GOLD
		else
			priceLbl.Text = ""
		end
		if status == "buy" then
			action.BackgroundColor3 = GREEN
			actionLbl.TextColor3 = Color3.fromRGB(16, 40, 24)
			if row.robux then
				actionLbl.Text = "BUY   " .. commas(price) .. " Robux"
			else
				actionLbl.Text = "BUY   " .. money(price) .. " " .. currency
			end
			action.Active = true
			action.AutoButtonColor = true
		elseif status == "short" then
			action.BackgroundColor3 = Color3.fromRGB(96, 58, 64)
			actionLbl.TextColor3 = Color3.fromRGB(255, 190, 190)
			actionLbl.Text = "NEED " .. money(price) .. " " .. currency
			action.Active = false
			action.AutoButtonColor = false
		elseif status == "owned" then
			action.BackgroundColor3 = (activeTab == "backpack" or activeTab == "secrets") and T.CARD_HI or CARD_HI
			actionLbl.TextColor3 = TEXT
			if activeTab == "secrets" then
				actionLbl.Text = "EQUIP"
				action.Active = true
			elseif activeTab == "backpack" then
				actionLbl.Text = "OWNED"
				action.Active = false
			else
				actionLbl.Text = "EQUIP"
				action.Active = true
			end
			action.AutoButtonColor = action.Active
		elseif status == "held" then
			action.BackgroundColor3 = Color3.fromRGB(84, 70, 34)
			actionLbl.TextColor3 = GOLD
			actionLbl.Text = "EQUIPPED"
			action.Active = false
			action.AutoButtonColor = false
		elseif status == "locked" then
			action.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
			actionLbl.TextColor3 = Color3.fromRGB(120, 120, 130)
			actionLbl.Text = "LOCKED"
			action.Active = false
			action.AutoButtonColor = false
		elseif status == "zone" then
			local needZone
			if activeTab == "backpack" then
				needZone = math.floor(tonumber(row and row.minZone) or 1)
			else
				needZone = math.floor(tonumber(row and row.zoneIndex) or 1)
			end
			local zone = C.ZONES[needZone]
			action.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
			actionLbl.TextColor3 = Color3.fromRGB(255, 196, 120)
			actionLbl.Text = "Unlock " .. (zone and zone.name or ("Zone " .. needZone))
			action.Active = false
			action.AutoButtonColor = false
		end
		-- There is deliberately no LOCKED state. statusOf returns only
		-- owned/held/buy/short: every rung is buyable in any order if you can
		-- afford it, and "short" already says what it costs.

		counter.Text = string.format("%d  of  %d", index, #list)
		fill.BackgroundColor3 = tint
		TweenService:Create(fill, TweenInfo.new(0.18), {
			Size = UDim2.fromScale(index / #list, 1),
		}):Play()

		-- Arrows dim at the ends rather than vanishing, so the row does not jump.
		-- Wrap-around: arrows always active.
		leftBtn.Active = #list > 1
		rightBtn.Active = #list > 1
		leftBtn.TextTransparency = 0
		rightBtn.TextTransparency = 0
		leftStroke.Transparency = 0.45
		rightStroke.Transparency = 0.45
	end

	----------------------------------------------------------------------------
	-- CONTROLLER
	----------------------------------------------------------------------------

	function view.step(dir)
		local list = rows()
		if #list == 0 then
			return
		end
		local next = index + dir
		if next < 1 then
			next = #list
		elseif next > #list then
			next = 1
		end
		index = next
		paint()
		-- A short nudge so paging reads as movement, not a redraw. Relative to
		-- wherever the layout put the card -- this used to snap back to a
		-- hardcoded (104, 138) from the old windowed layout, which against a
		-- centre anchor threw the whole card off the left of the screen.
		-- Keep the stage (and background) planted; nudge only the tool name.
		local home = CARD_HOME
		card.Position = home
		nameLbl.TextTransparency = 0.55
		TweenService:Create(nameLbl, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0,
		}):Play()
	end

	function view.setTab(id)
		activeTab = id
		local count = #rows()
		if activeTab == "backpack" or activeTab == "secrets" then
			index = (count > 0) and math.clamp(ownedCount() + 1, 1, count) or 1
		else
			local zi = state.zoneIndex or state.maxUnlockedZone or 1
			index = 1
			if count > 0 then index = math.clamp(index, 1, count) end
		end
		paint()
	end

	function view.setState(snapshot)
		if not snapshot then
			return
		end
		state.coins = snapshot.coins or 0
		state.gems = snapshot.gems or 0
		state.dust = snapshot.dust or 0
		-- Temperament tokens ride in the skills payload, not at the top level
		-- (MineServer builds them as skillEarned + skillBought - burned - spent).
		state.tokens = snapshot.tokens
			or (snapshot.skills and snapshot.skills.tokens)
			or 0
		state.tools = snapshot.tools or {}
		-- Banked ore and the ore tools themselves: the bench prices every row
		-- against these two.
		state.ores = snapshot.ores or {}
		-- The Forge lists one recipe per ore ever held, not per ore banked, so
		-- spending your last unit of something does not delete its recipe.
		state.oresSeen = snapshot.oresSeen or {}
		state.oreToolUid = snapshot.oreToolUid
		state.oreTools = snapshot.oreTools or {}
		state.backpackTier = snapshot.backpackTier or 1
		state.family = snapshot.tool and snapshot.tool.family or nil
		state.credits = snapshot.credits or 0
		state.scrolls = snapshot.scrolls or {}
		state.creditPacks = snapshot.creditPacks or {}
		state.scrollShop = snapshot.scrollShop or {}
		state.chestTools = snapshot.chestTools or {}
		state.chestTool = snapshot.chestTool
		state.zoneId = snapshot.zoneId
		state.deepest = snapshot.deepest or {}
		state.spaceCoins = snapshot.spaceCoins or 0
		state.eventTools = snapshot.eventTools or {}
		state.eventToolId = snapshot.eventToolId
		state.maxUnlockedZone = snapshot.maxUnlockedZone or 1
		state.zoneIndex = snapshot.zoneIndex
			or (C.zoneIndex and snapshot.zoneId and C.zoneIndex(snapshot.zoneId))
			or state.maxUnlockedZone
			or 1
		state.ownedShopTools = snapshot.ownedShopTools or {}
		state.shopToolRunes = snapshot.shopToolRunes or {}
		state.runes = snapshot.runes or {}
		state.shopToolId = snapshot.shopToolId or (snapshot.tool and snapshot.tool.id)
		state.tempers = snapshot.tempers or {}
		state.toolTempers = snapshot.toolTempers or {}
		if root.Visible then
			paint()
		end
	end

	function view.open(tab)
		Audio.play("shop")
		activeTab = (tab and tabBtns[tab]) and tab or activeTab
		local count = #rows()
		if activeTab == "backpack" or activeTab == "secrets" then
			index = (count > 0) and math.clamp(ownedCount() + 1, 1, count) or 1
		else
			local zi = state.zoneIndex or state.maxUnlockedZone or 1
			index = ShopLadders.firstSurfaceIndexForZone(zi)
			if count > 0 then index = math.clamp(index, 1, count) else index = 1 end
		end
		paint()
		root.Visible = true
		root.AnchorPoint = Vector2.new(0.5, 0.5)
		root.Position = UDim2.fromScale(0.5, 0.5)
		root.Size = UDim2.fromScale(1, 1)
		local sg = root.Parent
		if sg and sg:IsA("ScreenGui") then
			sg.DisplayOrder = math.max(sg.DisplayOrder or 0, 120)
		end
	end

	function view.close()
		root.Visible = false
		if shown then
			shown:Destroy()
			shown = nil
		end
	end

	action.MouseButton1Click:Connect(function()
		if not action.Active then
			return
		end
		local status = statusOf(index)
		if status == "buy" then
			if activeTab == "backpack" then
				local row = rows()[index]
				if row and row.robux then
					local pid = tonumber(row.productId) or 0
					if pid <= 0 then
						if opts.onBuyProductCredits then
							opts.onBuyProductCredits(row.productKey or "patron_rig")
						elseif opts.onToast then
							opts.onToast("Buy Founders Rig with credits in the Shop")
						end
						return
					end
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, pid)
					return
				end
				if opts.onBuyBackpack then opts.onBuyBackpack((row and row.tier) or index) end
			else
				local row = rows()[index]
				if opts.onBuyTool then
					if row and row.id then
						opts.onBuyTool(row.family or activeTab, row.slot or index, row.id)
					else
						opts.onBuyTool(activeTab, index)
					end
				end
			end
		elseif (status == "owned" or status == "held") and activeTab ~= "backpack" and activeTab ~= "secrets" then
			local row = rows()[index]
			if row and row.id and opts.onEquipShopTool then
				opts.onEquipShopTool(row.id)
			elseif row and opts.onEquip then
				opts.onEquip(row.family or activeTab, row.slot or index)
			end
		elseif (status == "owned" or status == "held") and activeTab == "secrets" then
			local row = rows()[index]
			if row and opts.onEquipChestTool then opts.onEquipChestTool(row.id) end
		elseif (status == "owned" or status == "held") and activeTab ~= "backpack" then
			-- Equip the rung on screen, not just the family. The shop shows one
			-- specific tool; pressing EQUIP on it should hand you that tool.
			if opts.onEquip then opts.onEquip(activeTab, index) end
		end
	end)

	close.MouseButton1Click:Connect(function()
		view.close()
		if opts.onClose then opts.onClose() end
	end)

	-- Arrow keys page too. A carousel you can only click is a carousel people
	-- stop using after the third tool.
	UIS.InputBegan:Connect(function(input, gp)
		if gp or not root.Visible then
			return
		end
		if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.A then
			view.step(-1)
		elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
			view.step(1)
		end
	end)

	root:GetPropertyChangedSignal("Visible"):Connect(function()
		if root.Visible then
			paint()
		elseif shown then
			shown:Destroy()
			shown = nil
		end
	end)

	view.root = root
	view.tabs = tabBtns
	return view
end

return MineShopView
