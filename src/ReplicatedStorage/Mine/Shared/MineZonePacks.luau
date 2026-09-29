--[[
	MineZonePacks — per-zone pack slots (5 card/currency + 3 fossil bands).

	Each permanent zone authors:
	  currency_common, currency_rare,
	  pack_common, pack_rare, pack_legendary,
	  fossil_pack (Surface), fossil_deeprock_pack, fossil_shadowzone_pack

	Pack display names are "{Zone} …". Fossil packs are Surface / Deeprock / Shadowzone.
]]

local MineZonePacks = {}

MineZonePacks.SLOTS = {
	"currency_common",
	"currency_rare",
	"pack_common",
	"pack_rare",
	"pack_legendary",
	"fossil_pack", -- Surface Fossil Pack (a)
	"fossil_deeprock_pack", -- Deeprock Fossil Pack (b)
	"fossil_shadowzone_pack", -- Shadowzone Fossil Pack (c)
}

MineZonePacks.SLOT_META = {
	currency_common = { kind = "currency", label = "Pouch", art = "currency_common" },
	currency_rare = { kind = "currency", label = "Strongbox Pouch", art = "currency_rare" },
	pack_common = { kind = "cards", label = "Pack", art = "pack_common" },
	pack_rare = { kind = "cards", label = "Rare Pack", art = "pack_rare" },
	pack_legendary = { kind = "cards", label = "Legendary Pack", art = "pack_legendary", weaponChance = true },
	fossil_pack = { kind = "fossil", label = "Surface Fossil Pack", art = "fossil_pack", pulls = 3, allowDupes = true, band = "shallow" },
	fossil_deeprock_pack = { kind = "fossil", label = "Deeprock Fossil Pack", art = "fossil_deep_pack", pulls = 3, allowDupes = true, band = "mid", deeprock = true },
	fossil_shadowzone_pack = { kind = "fossil", label = "Shadowzone Fossil Pack", art = "fossil_deep_pack", pulls = 3, allowDupes = true, band = "deep", shadowzone = true },
}

-- Legacy slot aliases (saves / old chest defs).
MineZonePacks.SLOT_ALIAS = {
	fossil_deep_pack = "fossil_deeprock_pack",
	fossil_abyss_pack = "fossil_shadowzone_pack",
}

MineZonePacks.ZONE_ORDER = {
	"meadow",
	"sunscar", -- Greyvein Quarry
	"mistreef",
	"arcwork",
	"bloodmoon",
	"eclipse",
	"riftmarch",
	"starfall",
	"mythral",
	"primordium",
}

MineZonePacks.ZONE_LABEL = {
	meadow = "Meadow",
	sunscar = "Greyvein",
	mistreef = "Mistreef",
	arcwork = "Arcwork",
	bloodmoon = "Bloodmoon",
	eclipse = "Eclipse",
	riftmarch = "Riftmarch",
	starfall = "Starfall",
	mythral = "Mythral",
	primordium = "Primordium",
	bigbang = "Horizon",
}

MineZonePacks.LIMITED_ZONE = "bigbang"

local function packId(zoneId, slot)
	slot = MineZonePacks.SLOT_ALIAS[slot] or slot
	return zoneId .. "_" .. slot
end

function MineZonePacks.id(zoneId, slot)
	return packId(zoneId, slot)
end

-- Depth-scaled card odds (same curve as MinePackConfig.depthCardOdds).
-- Zone index maps onto the meadow depth ladder so early zones stay cold on
-- Mythic/Divine/Exotic and late zones approach Mythic ~1/100, Exotic ~1/1000.
local function depthCardOdds(layer, maxLayers, heat)
	heat = math.max(0, tonumber(heat) or 0)
	maxLayers = math.max(2, math.floor(tonumber(maxLayers) or 2500))
	layer = math.clamp(math.floor(tonumber(layer) or 1), 1, maxLayers)
	local t = (layer - 1) / (maxLayers - 1)
	local u = t * t
	local exotic = 0.10 * u * (1 + 0.25 * heat)
	local divine = 0.33 * u * (1 + 0.20 * heat)
	local mythic = 1.00 * u * (1 + 0.15 * heat)
	local legendary = (0.12 + 7.5 * t) * (1 + 0.12 * heat)
	local epic = 1.8 + 14.0 * t
	local rare = 9.0 + 13.0 * t
	local uncommon = 28.0 - 8.0 * t
	local used = exotic + divine + mythic + legendary + epic + rare + uncommon
	local common = math.max(4, 100 - used)
	local total = common + uncommon + rare + epic + legendary + mythic + divine + exotic
	local scale = 100 / total
	return {
		Common = common * scale,
		Uncommon = uncommon * scale,
		Rare = rare * scale,
		Epic = epic * scale,
		Legendary = legendary * scale,
		Mythic = mythic * scale,
		Divine = divine * scale,
		Exotic = exotic * scale,
	}
end

local function cardOdds(zoneIndex, heat)
	heat = heat or 0
	local z = math.max(1, zoneIndex)
	local maxL = 2500
	local layer = math.floor(1 + ((z - 1) / 10) * (maxL - 1) + 0.5)
	return depthCardOdds(layer, maxL, heat)
end

local function fossilOdds(zoneIndex, band)
	local z = math.max(1, zoneIndex)
	local maxL = 2500
	local layer = math.floor(1 + ((z - 1) / 10) * (maxL - 1) + 0.5)
	if band == "deep" or band == "shadowzone" then
		layer = math.min(maxL, math.floor(layer * 0.55 + maxL * 0.45))
		return depthCardOdds(layer, maxL, 1.25)
	elseif band == "mid" or band == "deeprock" then
		layer = math.min(maxL, math.floor(layer * 0.75 + maxL * 0.25))
		return depthCardOdds(layer, maxL, 0.6)
	end
	return depthCardOdds(layer, maxL, 0)
end

function MineZonePacks.buildAll()
	local packs = {}
	local function addZone(zoneId, zoneIndex, limited)
		local label = MineZonePacks.ZONE_LABEL[zoneId] or zoneId
		local z = zoneIndex
		for _, slot in ipairs(MineZonePacks.SLOTS) do
			local meta = MineZonePacks.SLOT_META[slot]
			local id = packId(zoneId, slot)
			local row = {
				id = id,
				zoneId = zoneId,
				slot = slot,
				kind = meta.kind,
				name = label .. " " .. meta.label,
				zoneIndex = zoneIndex,
				limited = limited and true or false,
				artKey = meta.art,
				pulls = meta.pulls,
				allowDupes = meta.allowDupes,
				deep = meta.deep,
			}
			if meta.kind == "currency" then
				local mult = (slot == "currency_rare") and 2.4 or 1
				row.coins = {
					math.floor(18 * z * mult),
					math.floor(70 * z * mult),
				}
				row.gems = {
					math.max(1, math.floor(z * 0.8 * mult)),
					math.floor((2 + z * 2.2) * mult),
				}
			elseif meta.kind == "cards" then
				local heat = (slot == "pack_legendary") and 2 or (slot == "pack_rare") and 1 or 0
				row.cards = (slot == "pack_legendary") and 5 or (slot == "pack_rare") and 4 or 3
				row.odds = cardOdds(z, heat)
				if meta.weaponChance then
					row.weaponChance = 0.02 + 0.012 * (z - 1)
				end
			elseif meta.kind == "fossil" then
				row.pulls = 3
				row.allowDupes = true
				row.band = meta.band
				row.odds = fossilOdds(z, meta.band)
				row.name = label .. " " .. meta.label
			end
			packs[id] = row
		end
	end
	for i, zoneId in ipairs(MineZonePacks.ZONE_ORDER) do
		addZone(zoneId, i, false)
	end
	addZone(MineZonePacks.LIMITED_ZONE, 11, true)
	return packs
end

MineZonePacks.PACKS = MineZonePacks.buildAll()

--[[
	ORE PACKS -- one per ore, generated, never authored.

	Breaking an ore block gives its pack; opening the pack always gives ore.
	That is the whole contract. Ore cannot build a tool, only upgrade one, so
	this is the reliable half of the loot split and chests keep the rare half.

	121 rows kept in step with MineConfig.ORES by construction. Hand-writing
	them would guarantee the two drift the first time an ore is renamed.

	Yield falls as the ore gets harder: a common seam hands over a fistful, an
	endgame ore hands over one or two. Combined with how much rarer the block
	itself is, supply between the ends of the list differs by orders of
	magnitude, which is what lets upgrade costs climb the same way.
]]
-- Kept for callers that still read them. Yield itself comes from
-- MineConfig.ORE_YIELD_BANDS now, which is a bell rather than this ramp.
MineZonePacks.ORE_YIELD_LO = 1
MineZonePacks.ORE_YIELD_HI = 6

do
	local okC, C = pcall(function()
		return require(script.Parent:WaitForChild("MineConfig"))
	end)
	if okC and C and C.ORES then
		local n = #C.ORES
		for _, ore in ipairs(C.ORES) do
			-- Band table in MineConfig, not a ramp: yield peaks on Epic now,
			-- matching where the cost bell peaks.
			local lo, hi = C.oreYieldFor(ore.tier)
			MineZonePacks.PACKS[ore.packId] = {
				id = ore.packId,
				kind = "ore",
				oreId = ore.id,
				oreName = ore.name,
				name = ore.name .. " Ore Pack",
				tier = ore.tier,
				yield = { lo, hi },
				color = ore.color,
				-- PackFX.art(packId) builds shades from ore.color.
				artKey = ore.packId,
			}
		end
	end
end

function MineZonePacks.get(packId)
	local row = MineZonePacks.PACKS[packId]
	if row then
		return row
	end
	-- Ore packs may miss the boot-time pass if MineConfig was still loading.
	if type(packId) == "string" and string.sub(packId, -9) == "_ore_pack" then
		local okC, C = pcall(function()
			return require(script.Parent:WaitForChild("MineConfig"))
		end)
		if okC and C and C.ORES and not MineZonePacks._orePacksReady then
			local n = #C.ORES
			for _, ore in ipairs(C.ORES) do
				local pid = ore.packId or (ore.id .. "_ore_pack")
				if not MineZonePacks.PACKS[pid] then
					local lo, hi = C.oreYieldFor(ore.tier)
					MineZonePacks.PACKS[pid] = {
						id = pid,
						kind = "ore",
						oreId = ore.id,
						oreName = ore.name,
						name = ore.name .. " Ore Pack",
						tier = ore.tier,
						yield = { lo, hi },
						color = ore.color,
						artKey = pid,
					}
				end
			end
			MineZonePacks._orePacksReady = true
		end
		return MineZonePacks.PACKS[packId]
	end
	return nil
end

function MineZonePacks.forZone(zoneId)
	local list = {}
	for _, slot in ipairs(MineZonePacks.SLOTS) do
		local id = packId(zoneId, slot)
		list[slot] = MineZonePacks.PACKS[id]
	end
	return list
end

-- Rough EV proxy for balance checks (higher = better farm).
function MineZonePacks.slotEv(zoneId, slot)
	local p = MineZonePacks.PACKS[packId(zoneId, slot)]
	if not p then
		return 0
	end
	if p.kind == "currency" then
		local c = (p.coins[1] + p.coins[2]) * 0.5
		local g = (p.gems[1] + p.gems[2]) * 0.5
		return c + g * 40
	end
	if p.odds then
		local rank = {
			Common = 1, Uncommon = 2, Rare = 4, Epic = 8,
			Legendary = 16, Mythic = 32, Divine = 64, Exotic = 128,
		}
		local sum, w = 0, 0
		for id, wt in pairs(p.odds) do
			sum += (rank[id] or 1) * wt
			w += wt
		end
		return (w > 0 and sum / w or 0) * (p.cards or p.pulls or 1)
	end
	return 0
end

return MineZonePacks
