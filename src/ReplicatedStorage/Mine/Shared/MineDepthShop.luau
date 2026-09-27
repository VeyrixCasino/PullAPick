-- MineDepthShop: depth-plaza sell mult + shop ladder catalogs.
-- Desks pull from MineShopLadders (3 tools each). Surface shop uses surface desk list.
-- See handoff/launch/TOOL_AND_BAG_COUNTS.md

local shared = script.Parent
local Depth = require(shared:WaitForChild("MineDepth"))
local Tools = require(shared:WaitForChild("MineTools"))

local MineDepthShop = {}

MineDepthShop.DEPTH_SELL_FRAC = Depth.DEPTH_SELL_FRAC or 0.78

local DESK_SEAM = {
	-- false = surface pad: no depth sell haircut (1:1 HP→coins).
	-- Was `1`, which is truthy, so every meadow sell ate DEPTH_SELL_FRAC (0.78).
	surface = false, shallow = false, surface_band = false, a = false,
	mid = 500, deeprock = 500, b = 500, thousand = 1000,
	deep = 1500, shadowzone = 1500, c = 1500, twothou = 2000,
	outpost_2500 = 2500, outpost_3000 = 3000, outpost_3500 = 3500,
	outpost_4000 = 4000, outpost_4500 = 4500, outpost_5000 = 5000,
}

local DESK_TO_LADDER = {
	surface = "surface",
	shallow = "surface_band", surface_band = "surface_band", a = "surface_band",
	mid = "deeprock", deeprock = "deeprock", b = "deeprock", thousand = "thousand",
	deep = "shadowzone", shadowzone = "shadowzone", c = "shadowzone", twothou = "twothou",
}

function MineDepthShop.deskSeam(desk)
	desk = tostring(desk or "")
	if DESK_SEAM[desk] ~= nil then
		return DESK_SEAM[desk]
	end
	local n = tonumber(string.match(desk, "^outpost_(%d+)$"))
	if n then return n end
	return nil
end

function MineDepthShop.deskFromDepth(depth)
	depth = math.max(0, math.floor(tonumber(depth) or 0))
	if depth < 8 then
		return "surface"
	end
	-- Start at surface. Never default to seam 500 for shallow digs.
	local pick = nil
	for _, seam in ipairs(Depth.SEAMS or {}) do
		if depth >= seam then
			pick = seam
		end
	end
	if not pick then
		return "surface"
	end
	if pick >= 2500 then
		return "outpost_" .. tostring(pick)
	end
	if pick >= 2000 then
		return "twothou"
	end
	if pick >= 1500 then
		return "shadowzone"
	end
	if pick >= 1000 then
		return "thousand"
	end
	return "deeprock"
end

function MineDepthShop.deskBand(desk)
	local d = tostring(desk or "")
	local seam = MineDepthShop.deskSeam(d) or 0
	if type(seam) == "number" and seam > 2500 then return "deep" end
	if d == "deeprock" or d == "mid" or d == "b" or d == "thousand" then return "mid" end
	if d == "shadowzone" or d == "deep" or d == "c" or d == "twothou" or string.find(d, "outpost_", 1, true) then return "deep" end
	return "shallow"
end

local ROLE = {
	pickaxe = "Pickaxe", drill = "Drill", explosive = "Explosive", backpack = "Bag",
}

function MineDepthShop.priceOf(tool)
	if type(tool) ~= "table" then return 0 end
	if tool.eventOnly or tool.currency == "space" then
		return math.max(0, math.floor(tonumber(tool.price) or 0))
	end
	local priced = tonumber(tool.price)
	if priced and priced > 0 then return math.floor(priced) end
	return math.floor(math.max(1, tonumber(tool.power) or 1) * 800)
end

local function loadLadders()
	local ok, L = pcall(function()
		return require(shared:WaitForChild("MineShopLadders"))
	end)
	return ok and L or nil
end

function MineDepthShop.resolve(id)
	id = tostring(id or "")
	if id == "" then return nil end
	local bagTier = string.match(id, "^bag_(%d+)$")
	if bagTier then
		local okBags, Bags = pcall(function()
			return require(shared:WaitForChild("MineBags"))
		end)
		local row = okBags and Bags and Bags.byTier(tonumber(bagTier))
		if row then
			return {
				id = id, name = row.name, price = row.price,
				slots = row.slots, power = row.slots,
			}, "backpack", tonumber(bagTier)
		end
	end
	local L = loadLadders()
	if L and L.byId then
		local t = L.byId(id)
		if t then return t, t.family, t.slot end
	end
	for family, list in pairs(Tools.TOOLS or {}) do
		for tier, t in ipairs(list) do
			if t.id == id then return t, family, tier end
		end
	end
	return nil
end

local function rowFrom(tool, family, tier)
	if not tool then return nil end
	return {
		id = tool.id,
		family = family or tool.family,
		tier = tier or tool.slot or tool.tier,
		name = tool.name or tool.id,
		role = ROLE[family or tool.family] or (family or tool.family),
		power = tool.power or 0,
		price = MineDepthShop.priceOf(tool),
		currency = tool.currency,
		eventOnly = tool.eventOnly,
		band = tool.band,
		minDepth = tool.minDepth or 0,
		desk = tool.desk,
		zoneId = tool.zoneId,
	}
end

-- Depth-plaza catalogs: THIS zone + THIS desk only.
-- Never inherit other zones' depth purchase options.
function MineDepthShop.catalog(zoneIndex, seam, desk)
	zoneIndex = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	desk = tostring(desk or "")
	if desk == "" then
		local s = tonumber(seam) or 500
		desk = (s >= 2500) and ("outpost_" .. tostring(s - (s % 500))) or (s >= 2000) and "twothou" or (s >= 1500) and "shadowzone" or (s >= 1000) and "thousand" or (s >= 500) and "deeprock" or "surface_band"
	end
	local deskSeam = MineDepthShop.deskSeam(desk) or tonumber(seam) or 0
	if type(deskSeam) == "number" and deskSeam > 2500 then
		-- Outposts past 2500: sell/elevator only — no shop tools shown.
		return {}
	end
	local Cfg = require(shared:WaitForChild("MineConfig"))
	local zoneRow = Cfg.ZONES and Cfg.ZONES[zoneIndex]
	if zoneRow and zoneRow.id == "bigbang" then
		local rows, seen = {}, {}
		local okH, Horizon = pcall(function()
			return require(shared:WaitForChild("MineHorizonTools"))
		end)
		local band = MineDepthShop.deskBand(desk)
		if okH and Horizon and Horizon.forBand then
			for _, t in ipairs(Horizon.forBand(band)) do
				if t.id and not seen[t.id] then
					seen[t.id] = true
					table.insert(rows, rowFrom(t, t.family, t.tier))
				end
			end
		end
		local okBags, Bags = pcall(function()
			return require(shared:WaitForChild("MineBags"))
		end)
		if okBags and Bags and Bags.shopRows then
			for _, b in ipairs(Bags.shopRows(zoneIndex, band)) do
				if b and not seen[b.id] then
					seen[b.id] = true
					table.insert(rows, b)
				end
			end
		end
		return rows
	end
	local L = loadLadders()
	local zoneId = (L and L.ZONE_ORDER and L.ZONE_ORDER[zoneIndex]) or "meadow"
	desk = tostring(desk or "")
	if desk == "" then
		local s = tonumber(seam) or 500
		desk = (s >= 2000) and "twothou" or (s >= 1500) and "shadowzone" or (s >= 1000) and "thousand" or (s >= 500) and "deeprock" or "surface_band"
	end
	local ladderDesk = DESK_TO_LADDER[desk] or desk
	local rows = {}
	local seen = {}
	if L and L.forDesk then
		for _, t in ipairs(L.forDesk(zoneId, ladderDesk)) do
			if not seen[t.id] then
				seen[t.id] = true
				table.insert(rows, rowFrom(t, t.family, t.slot))
			end
		end
	end
	-- Bags for this band
	local band = MineDepthShop.deskBand(desk)
	local okBags, Bags = pcall(function()
		return require(shared:WaitForChild("MineBags"))
	end)
	if okBags and Bags and Bags.shopRows then
		for _, b in ipairs(Bags.shopRows(zoneIndex, band)) do
			if b and not seen[b.id] then
				seen[b.id] = true
				table.insert(rows, b)
			end
		end
	end
	return rows
end

function MineDepthShop.catalogHas(zoneIndex, seam, id, desk)
	id = tostring(id or "")
	for _, row in ipairs(MineDepthShop.catalog(zoneIndex, seam, desk)) do
		if row.id == id then return row end
	end
	return nil
end

function MineDepthShop.sellPayout(haulCoins, zoneIndex, seam)
	haulCoins = math.max(0, math.floor(tonumber(haulCoins) or 0))
	return math.floor(haulCoins * Depth.depthSellMult(zoneIndex, seam))
end

return MineDepthShop
