local shared = script.Parent
local Depth = require(shared:WaitForChild("MineDepth"))

local MineShopEconomy = {}

MineShopEconomy.BAG_HAULS_MIN = 3
MineShopEconomy.BAG_HAULS_MAX = 400
-- Tools cost more hauls than bags, and rung curve stretches zone-1 pick prices.
MineShopEconomy.TOOL_HAUL_MULT = 3.5
MineShopEconomy.TOOL_RUNG_CURVE = 1.72

MineShopEconomy.COMFORT = { shallow = 8, mid = 4, deep = 2, kilo = 3, abyss = 2 }
MineShopEconomy.BAND_FLOOR_HP = { shallow = 15, mid = 45000, deep = 2625000, kilo = 350000, abyss = 20000000 }

-- Combat power vs shop price: picks hit ~25% softer; prices still use raw power.
MineShopEconomy.PICK_COMBAT_MULT = 0.75
-- Kept at 1. Early-zone chest tools were the overpowered ones.
-- This dial only softens 500/1500 shop damage in later zones if it is below 1.
MineShopEconomy.DESK_ZONE_FALLOFF = 1

local DESK_SEAM = {
	surface = false, surface_band = false, shallow = false, a = false,
	mid = 500, deeprock = 500, b = 500, thousand = 1000, kilo = 1000,
	deep = 1500, shadowzone = 1500, c = 1500, twothou = 2000, abyss = 2000,
}
local DESK_BAND = {
	surface = "shallow", surface_band = "shallow", shallow = "shallow", a = "shallow",
	mid = "mid", deeprock = "mid", b = "mid", thousand = "kilo", kilo = "kilo",
	deep = "deep", shadowzone = "deep", c = "deep", twothou = "abyss", abyss = "abyss",
}
local BAND_DESK = { shallow = "surface", mid = "deeprock", deep = "shadowzone" }

function MineShopEconomy.normalizeBand(band)
	band = tostring(band or "shallow")
	if band == "surface" or band == "a" then return "shallow" end
	if band == "deeprock" or band == "b" then return "mid" end
	if band == "shadowzone" or band == "c" then return "deep" end
	return band
end

function MineShopEconomy.comfort(band)
	return MineShopEconomy.COMFORT[MineShopEconomy.normalizeBand(band)] or 8
end

function MineShopEconomy.deskBand(desk)
	return DESK_BAND[tostring(desk or "surface")] or "shallow"
end

function MineShopEconomy.sellMult(zoneIndex, desk)
	zoneIndex = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	local seam = DESK_SEAM[tostring(desk or "surface")]
	if seam == false or seam == nil then return 1 end
	return Depth.depthSellMult(zoneIndex, seam)
end

function MineShopEconomy.bagHaulsToOwn(zoneIndex)
	zoneIndex = math.clamp(math.floor(tonumber(zoneIndex) or 1), 1, 10)
	local t = (zoneIndex - 1) / 9
	return MineShopEconomy.BAG_HAULS_MIN * ((MineShopEconomy.BAG_HAULS_MAX / MineShopEconomy.BAG_HAULS_MIN) ^ t)
end

function MineShopEconomy.toolHaulsToOwn(zoneIndex)
	return MineShopEconomy.bagHaulsToOwn(zoneIndex) * MineShopEconomy.TOOL_HAUL_MULT
end

function MineShopEconomy.toolPowerRaw(zoneIndex, band, rung)
	zoneIndex = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	band = MineShopEconomy.normalizeBand(band)
	rung = math.max(1, math.floor(tonumber(rung) or 1))
	-- Wider rung spread: early picks stay soft, late rungs jump hard.
	-- Zone 1 shallow uses a softer floor so pets+charm+gear cannot cruise to ~300.
	local rungMult = 0.50 + (rung - 1) * 0.40
	local floorHp = MineShopEconomy.BAND_FLOOR_HP[band] or 15
	if zoneIndex <= 1 and band == "shallow" then
		floorHp = math.max(6, math.floor(floorHp * 0.55 + 0.5))
	end
	local power = math.max(2, math.floor(floorHp * Depth.zoneMult(zoneIndex) * rungMult + 0.5))
	if zoneIndex > 1 and (band == "mid" or band == "deep") then
		local falloff = MineShopEconomy.DESK_ZONE_FALLOFF or 0.60
		power = math.max(2, math.floor(power * (falloff ^ (zoneIndex - 1)) + 0.5))
	end
	return power
end

function MineShopEconomy.toolPower(zoneIndex, band, rung, family)
	local raw = MineShopEconomy.toolPowerRaw(zoneIndex, band, rung)
	if family == "pickaxe" then
		local mult = MineShopEconomy.PICK_COMBAT_MULT or 0.75
		return math.max(1, math.floor(raw * mult + 0.5))
	end
	return raw
end

function MineShopEconomy.bagSlotsForPower(power, band)
	power = math.max(1, tonumber(power) or 1)
	return math.max(1, math.floor(power * MineShopEconomy.comfort(band) + 0.5))
end

function MineShopEconomy.haulValue(slots, zoneIndex, band)
	slots = math.max(1, math.floor(tonumber(slots) or 1))
	band = MineShopEconomy.normalizeBand(band or "shallow")
	local desk = BAND_DESK[band] or "surface"
	return slots * MineShopEconomy.sellMult(zoneIndex, desk)
end

function MineShopEconomy.bagPrice(slots, zoneIndex, band)
	zoneIndex = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	band = MineShopEconomy.normalizeBand(band or "shallow")
	local haul = MineShopEconomy.haulValue(slots, zoneIndex, band)
	return math.max(0, math.floor(haul * MineShopEconomy.bagHaulsToOwn(zoneIndex) + 0.5))
end

function MineShopEconomy.toolPrice(zoneIndex, desk, power, band, rung)
	band = MineShopEconomy.normalizeBand(band or MineShopEconomy.deskBand(desk))
	power = math.max(1, tonumber(power) or 1)
	rung = math.max(1, math.floor(tonumber(rung) or 1))
	local slots = MineShopEconomy.bagSlotsForPower(power, band)
	local mult = MineShopEconomy.sellMult(zoneIndex, desk)
	local haul = slots * mult
	local base = haul * MineShopEconomy.toolHaulsToOwn(zoneIndex)
	local curve = (MineShopEconomy.TOOL_RUNG_CURVE or 1.55) ^ (rung - 1)
	local deskName = tostring(desk or "surface")
	local deskBoost = 1
	if deskName == "surface_band" or deskName == "a" or deskName == "shallow" then
		deskBoost = 4.2
	elseif deskName == "deeprock" or deskName == "mid" or deskName == "b" then
		deskBoost = 11
	elseif deskName == "shadowzone" or deskName == "deep" or deskName == "c" then
		deskBoost = 22
	end
	return math.max(0, math.floor(base * curve * deskBoost + 0.5))
end

function MineShopEconomy.sellMultTable()
	local rows = {}
	for zi = 1, 10 do
		rows[#rows + 1] = {
			zone = zi, surface = 1,
			deeprock = MineShopEconomy.sellMult(zi, "deeprock"),
			shadowzone = MineShopEconomy.sellMult(zi, "shadowzone"),
			bagHauls = MineShopEconomy.bagHaulsToOwn(zi),
			toolHauls = MineShopEconomy.toolHaulsToOwn(zi),
		}
	end
	return rows
end

return MineShopEconomy
