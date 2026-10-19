--[[
	MineZoneChests -- every chest in the main game, its rank, and what it pays.

	THE RULE (owner, 2026-10-19): chests are F to SSS, "same system as packs";
	8 tiers with "the same loot overall, split by tier" (rarer tiers rarer, more
	often deeper, paying more); "all separate names", the rank shown as a badge;
	and each of the 19 pack sets gets three named chests of its own
	(MineSetChests).

	HOW A CHEST IS CHOSEN (spawnTable / rollSpawn). A block that is a chest
	rolls its RANK first, from MineChestRanks.odds(depth luck). Then which chest
	of that rank: one of the zone's chests of that rank, or, where a pack set
	lives, sometimes that set's chest of the rank (MineSetChests.SHARE). The
	Shiny Chest stays a chase of its own, rolled before the rank.

	WHAT A CHEST PAYS (payout). Everything is a function of the rank and the
	zone, so the badge tells the truth:
	  gems   GEM_BASE[zone] x PAY[rank]       (Dirt Meadow and Event Horizon: none)
	  coins  (flat + perHp x rock HP) x PAY[rank], so coins grow with depth
	  packs  PACK_BASE[zone][slot] x PACK_MULT[slot][rank]; a set chest pays one
	         of its set's packs instead of the zone's card packs
	  and, by rank, in their own modules: the pack case (MineCases.CHEST_RANK_SHIFT),
	  the skin case (MineConfig.CHEST_SKIN_RANK_SHIFT), the book bundle and the
	  player XP (MineEnchants.CHEST_BUNDLE, BOOK_RANK_LEVEL, XP_CHEST_RANK).

	"THE SAME LOOT OVERALL". The bases are fitted to what a chest paid on
	average at 3863d14 (2026-10-19), at every depth of every zone, so the total
	is unchanged and only its split between ranks is new.
	tools/verify/economy-gems.js re-measures it from these tables against that
	baseline: gems within 5% at every depth, everything else within 20%.

	WHAT CHANGED (2026-10-19). Ranks were per zone and aged (a zone unlock moved
	every earlier zone's pool down a rank); a chest could show one name and pay
	another (Dirt Meadow and Event Horizon always paid their section chest, and
	the 80-chest Mine 1 catalog re-rolled from the zone pool on open). Now the
	chest on the block is the chest you open, its rank is fixed, and the
	section chests and the catalog no longer spawn (their data stays for saves
	and old docs).

	Every number below is PROPOSED (2026-10-19).
]]

local MineChestRanks = require(script.Parent:WaitForChild("MineChestRanks"))
local MineZonePacks = require(script.Parent:WaitForChild("MineZonePacks"))
local MineSetChests = require(script.Parent:WaitForChild("MineSetChests"))

local MineZoneChests = {}

local LADDER = MineChestRanks.LADDER

--[[
	PROPOSED. What a rank pays, as a multiple of its zone's base. A Common (F)
	chest pays about half an average one, an Exotic (SSS) ten times.
]]
MineZoneChests.PAY = { F = 0.55, D = 0.85, C = 1.2, B = 1.7, A = 2.4, S = 3.5, SS = 5.5, SSS = 9.0 }

--[[
	PROPOSED. Each zone's gem base, fitted so an average chest at every depth
	pays what it paid on 3863d14 (within 4%: Greyvein about 1.1k, Primordium
	about 16k). Dirt Meadow and Event Horizon chests pay no gems, as before
	(Meadow "stays gem-free"; its currency pouches pay a little).
]]
MineZoneChests.GEM_BASE = {
	meadow = 0, sunscar = 1140, mistreef = 1530, arcwork = 2080, bloodmoon = 2980,
	eclipse = 4090, riftmarch = 5720, starfall = 8030, mythral = 11220,
	primordium = 15790, bigbang = 0,
}

--[[
	PROPOSED. Coins: flat + perHp x the rock's HP at the chest's layer
	(MineConfig.dirtHp), times PAY. Fitted the same way. Dirt Meadow and Event
	Horizon chests paid 1.5 x the rock's HP on average (x3 in the Meadow's first
	50 layers, so a new player's first chests move them along) and still do.
]]
MineZoneChests.COIN_BASE = {
	meadow = { flat = 0, perHp = nil }, -- perHp derived below from NATIVE_COIN_HP
	sunscar = { flat = 64, perHp = 0.215 },
	mistreef = { flat = 78, perHp = 0.255 },
	arcwork = { flat = 104, perHp = 0.25 },
	bloodmoon = { flat = 136, perHp = 0.25 },
	eclipse = { flat = 172, perHp = 0.245 },
	riftmarch = { flat = 206, perHp = 0.245 },
	starfall = { flat = 248, perHp = 0.24 },
	mythral = { flat = 290, perHp = 0.24 },
	primordium = { flat = 346, perHp = 0.24 },
	bigbang = { flat = 0, perHp = nil },
}
MineZoneChests.NATIVE_COIN_HP = 1.5
MineZoneChests.MEADOW_EARLY_LAYERS = 50
MineZoneChests.MEADOW_EARLY_COIN_MULT = 3

--[[
	PROPOSED. Zone packs: a chest of rank r rolls each slot at
	PACK_BASE[zone][slot] x PACK_MULT[slot][r] (a chance; over 1 pays one for
	sure and rolls the rest). Better ranks swap Packs and Pouches for Rare and
	Legendary Packs and Strongbox Pouches. The bases are fitted to 3863d14.
]]
MineZoneChests.PACK_MULT = {
	pack_common = { F = 1.05, D = 1.0, C = 0.85, B = 0.7, A = 0.55, S = 0.45, SS = 0.35, SSS = 0.25 },
	pack_rare = { F = 0.2, D = 0.5, C = 1.0, B = 1.8, A = 2.6, S = 3.2, SS = 3.8, SSS = 4.4 },
	pack_legendary = { F = 0.05, D = 0.2, C = 0.6, B = 1.4, A = 3, S = 6, SS = 11, SSS = 18 },
	currency_common = { F = 1.1, D = 1.0, C = 0.85, B = 0.65, A = 0.5, S = 0.4, SS = 0.3, SSS = 0.2 },
	currency_rare = { F = 0.2, D = 0.5, C = 1.0, B = 1.8, A = 2.8, S = 4, SS = 6, SSS = 9 },
}
MineZoneChests.PACK_SLOTS = { "pack_common", "pack_rare", "pack_legendary", "currency_common", "currency_rare" }
MineZoneChests.PACK_BASE = {
	meadow = { pack_common = 0.186, pack_rare = 0.101, pack_legendary = 0.024, currency_common = 0.731, currency_rare = 0.049 },
	sunscar = { pack_common = 0.320, pack_rare = 0.348, pack_legendary = 0.013, currency_common = 0.277, currency_rare = 0.064 },
	mistreef = { pack_common = 0.336, pack_rare = 0.264, pack_legendary = 0.015, currency_common = 0.356, currency_rare = 0.056 },
	arcwork = { pack_common = 0.314, pack_rare = 0.267, pack_legendary = 0.038, currency_common = 0.349, currency_rare = 0.076 },
	bloodmoon = { pack_common = 0.301, pack_rare = 0.249, pack_legendary = 0.088, currency_common = 0.340, currency_rare = 0.045 },
	eclipse = { pack_common = 0.294, pack_rare = 0.219, pack_legendary = 0.097, currency_common = 0.340, currency_rare = 0.065 },
	riftmarch = { pack_common = 0.291, pack_rare = 0.205, pack_legendary = 0.101, currency_common = 0.340, currency_rare = 0.086 },
	starfall = { pack_common = 0.292, pack_rare = 0.244, pack_legendary = 0.107, currency_common = 0.344, currency_rare = 0.051 },
	mythral = { pack_common = 0.289, pack_rare = 0.250, pack_legendary = 0.111, currency_common = 0.345, currency_rare = 0.055 },
	primordium = { pack_common = 0.291, pack_rare = 0.225, pack_legendary = 0.115, currency_common = 0.344, currency_rare = 0.076 },
	bigbang = { pack_common = 0.518, pack_rare = 0.269, pack_legendary = 0.095, currency_common = 0.355, currency_rare = 0.195 },
}

--[[
	THE CHESTS, one rank each. The zones' own chests kept their ids and names;
	the seam chests now belong to the zone whose gems they always paid
	(MineZoneChests used to share them between neighbours), and the two chests
	each zone held back for aging (S_QUEUE) are its Divine and Exotic now. Event
	Horizon had five and needed eight: Nebula Locker, Quasar Reliquary and
	Big Bang Crown are PROPOSED names.
]]
MineZoneChests.ZONE_CHESTS = {
	meadow = {
		{ "meadow_topsoil", "Topsoil Cache", "F" }, { "meadow_sod_crate", "Sod Crate", "F" },
		{ "meadow_rootbox", "Rootbox", "D" }, { "meadow_briar", "Briar Chest", "C" },
		{ "meadow_hillock", "Hillock Cache", "B" }, { "meadow_loam_vault", "Loam Vault", "A" },
		{ "meadow_sunrise", "Sunrise Strongbox", "S" }, { "meadow_age_s1", "Dewvault", "SS" },
		{ "meadow_age_s2", "Canopy Coffer", "SSS" },
	},
	sunscar = {
		{ "greyvein_flagstone", "Flagstone Chest", "F" }, { "seam_cobble", "Cobble Seam Chest", "F" },
		{ "greyvein_quarry", "Quarry Cache", "D" }, { "greyvein_chisel", "Chisel Box", "C" },
		{ "greyvein_shale", "Shale Coffer", "B" }, { "greyvein_bedrock", "Bedrock Strongbox", "A" },
		{ "greyvein_granite", "Granite Vault", "S" }, { "greyvein_age_s1", "Keystone Vault", "SS" },
		{ "greyvein_age_s2", "Slate Crown", "SSS" },
	},
	mistreef = {
		{ "mist_tide", "Tide Chest", "F" }, { "mist_brine", "Brine Cache", "D" },
		{ "seam_slate", "Slate Seam Chest", "C" }, { "mist_kelp", "Kelp Coffer", "B" },
		{ "mist_coral", "Coral Box", "A" }, { "mist_reef", "Reef Vault", "S" },
		{ "mist_age_s1", "Abyss Pearl", "SS" }, { "mist_age_s2", "Undertow Vault", "SSS" },
	},
	arcwork = {
		{ "arc_coil", "Coil Chest", "F" }, { "arc_wire", "Wire Box", "D" },
		{ "seam_mist", "Mist Seam Chest", "C" }, { "arc_spark", "Spark Coffer", "B" },
		{ "arc_flux", "Flux Cache", "A" }, { "arc_core", "Core Vault", "S" },
		{ "arc_age_s1", "Dynamo Vault", "SS" }, { "arc_age_s2", "Circuit Crown", "SSS" },
	},
	bloodmoon = {
		{ "blood_ember", "Ember Chest", "F" }, { "blood_ash", "Ash Cache", "D" },
		{ "seam_spark", "Spark Seam Chest", "C" }, { "blood_fang", "Fang Coffer", "B" },
		{ "blood_veil", "Veil Box", "A" }, { "blood_lunar", "Lunar Vault", "S" },
		{ "blood_age_s1", "Crimson Reliquary", "SS" }, { "blood_age_s2", "Eclipse Scar", "SSS" },
	},
	eclipse = {
		{ "ecl_umbral", "Umbral Chest", "F" }, { "ecl_shade", "Shade Cache", "D" },
		{ "seam_crimson", "Crimson Seam Chest", "C" }, { "ecl_void", "Void Coffer", "B" },
		{ "ecl_penumbra", "Penumbra Box", "A" }, { "ecl_nocturne", "Nocturne Vault", "S" },
		{ "ecl_age_s1", "Black Sun Vault", "SS" }, { "ecl_age_s2", "Totality Crown", "SSS" },
	},
	riftmarch = {
		{ "rift_tear", "Tear Chest", "F" }, { "rift_fracture", "Fracture Cache", "D" },
		{ "seam_shadow", "Shadow Seam Chest", "C" }, { "rift_scar", "Scar Coffer", "B" },
		{ "rift_warp", "Warp Box", "A" }, { "rift_gate", "Gate Vault", "S" },
		{ "rift_age_s1", "Breach Reliquary", "SS" }, { "rift_age_s2", "March Crown", "SSS" },
	},
	starfall = {
		{ "star_dust", "Stardust Chest", "F" }, { "star_orbit", "Orbit Cache", "D" },
		{ "seam_rift", "Rift Seam Chest", "C" }, { "star_comet", "Comet Coffer", "B" },
		{ "star_meteor", "Meteor Box", "A" }, { "star_nova", "Nova Vault", "S" },
		{ "star_age_s1", "Constellation Vault", "SS" }, { "star_age_s2", "Aurora Crown", "SSS" },
	},
	mythral = {
		{ "myth_shard", "Shard Chest", "F" }, { "myth_gleam", "Gleam Cache", "D" },
		{ "seam_star", "Star Seam Chest", "C" }, { "myth_lattice", "Lattice Coffer", "B" },
		{ "myth_aether", "Aether Box", "A" }, { "myth_prism", "Prism Vault", "S" },
		{ "myth_age_s1", "Mythforge Vault", "SS" }, { "myth_age_s2", "Crystal Crown", "SSS" },
	},
	primordium = {
		{ "prime_seed", "Seed Chest", "F" }, { "seam_myth", "Myth Seam Chest", "F" },
		{ "prime_ash", "Primordial Ash", "D" }, { "seam_prime", "Prime Seam Chest", "C" },
		{ "prime_bone", "Bone Coffer", "B" }, { "prime_ember", "World Ember", "A" },
		{ "prime_heart", "Heart Vault", "S" }, { "prime_age_s1", "Origin Reliquary", "SS" },
		{ "prime_age_s2", "First Crown", "SSS" },
	},
	bigbang = {
		{ "hz_event", "Event Cache", "F" }, { "hz_pulse", "Pulse Box", "D" },
		{ "hz_singularity", "Singularity Coffer", "C" }, { "hz_nebula", "Nebula Locker", "B" },
		{ "hz_collapse", "Collapse Chest", "A" }, { "hz_horizon", "Horizon Vault", "S" },
		{ "hz_quasar", "Quasar Reliquary", "SS" }, { "hz_bigbang", "Big Bang Crown", "SSS" },
	},
}

-- The look (MineChestModel palette) a rank wears, so a better chest reads as one.
MineZoneChests.RANK_KIND = {
	F = "native", D = "native", C = "broad", B = "broad",
	A = "item", S = "item", SS = "chase", SSS = "chase",
}

--[[
	The Shiny Chest: a chase of its own, rolled before the rank (as it always
	was: zone 1 from layer 2,500 at 1 in 8,000, zones 2-10 from 1 in 2,500 to
	0.8%). It wears the Mythic (S) badge and pays as its zone's S chest.
]]
MineZoneChests.SHINY_ID = "shiny_chest"
MineZoneChests.SHINY_RANK = "S"

local ZONE_OF_SEAM = {}
MineZoneChests.DEFS = {}
MineZoneChests.POOLS = {}
-- Kept for old callers: nothing ages any more, so nothing is queued.
MineZoneChests.S_QUEUE = {}

-- E[PAY] at a zone's top, which the native coin rule divides by so the old
-- 1.5 x HP average still holds across the ranks.
local function payAtTop()
	local odds = MineChestRanks.odds(1)
	local e = 0
	for _, r in ipairs(LADDER) do
		e += odds[r] * (MineZoneChests.PAY[r] or 1)
	end
	return e
end
local NATIVE_PER_HP = MineZoneChests.NATIVE_COIN_HP / payAtTop()
for _, zid in ipairs({ "meadow", "bigbang" }) do
	MineZoneChests.COIN_BASE[zid].perHp = NATIVE_PER_HP
end

local function chestDef(id, name, rank, zoneId)
	return {
		id = id,
		name = name,
		rank = rank,
		zoneId = zoneId,
		kind = MineZoneChests.RANK_KIND[rank] or "native",
	}
end

for zoneId, list in pairs(MineZoneChests.ZONE_CHESTS) do
	local pool = {}
	local perRank = {}
	for _, row in ipairs(list) do
		perRank[row[3]] = (perRank[row[3]] or 0) + 1
	end
	local top = MineChestRanks.odds(1)
	for _, row in ipairs(list) do
		local id, name, rank = row[1], row[2], row[3]
		MineZoneChests.DEFS[id] = chestDef(id, name, rank, zoneId)
		ZONE_OF_SEAM[id] = zoneId
		-- `weight` is this chest's share of the zone's chests at its top, for
		-- the zone map (MineZoneMapView reads it).
		table.insert(pool, { chestId = id, rank = rank, weight = (top[rank] or 0) / math.max(1, perRank[rank]) })
	end
	MineZoneChests.POOLS[zoneId] = pool
end

do
	local d = chestDef(MineZoneChests.SHINY_ID, "Shiny Chest", MineZoneChests.SHINY_RANK, nil)
	d.kind = "chase"
	d.shiny = true
	MineZoneChests.DEFS[d.id] = d
end

for id, row in pairs(MineSetChests.BY_ID) do
	local d = chestDef(id, row.name, row.rank, row.set.zoneId)
	d.setKey = row.setKey
	d.setTier = row.tier
	MineZoneChests.DEFS[id] = d
end

--[[
	FOR SCREENS ONLY: each chest also carries what it pays at its zone's top
	(coins, gems, packs with printable `slot` names), so the screens that read
	a def's bands (the zone map, the chest dex) keep working. payout() is what
	pays; rollCurrency and rollPackDrops never read these.
]]
local function stampDisplay(d)
	local pay = MineZoneChests.payout(d, d.zoneId, 1)
	d.coins, d.gems = pay.coins, pay.gems
	d.packs = {}
	for _, pk in ipairs(pay.packs) do
		table.insert(d.packs, { slot = MineZoneChests.packLabel(pk), chance = pk.chance })
	end
end

function MineZoneChests.def(chestId)
	local d = MineZoneChests.DEFS[chestId]
	if d and d.rank and not d.coins then
		stampDisplay(d)
	end
	return d
end

function MineZoneChests.pool(zoneId)
	return MineZoneChests.POOLS[zoneId]
end

-- A chest's rank, or nil for an id that is not a chest.
function MineZoneChests.rankOf(chestId)
	local d = MineZoneChests.DEFS[chestId]
	return d and d.rank or nil
end

local function zoneOr(zoneId)
	if MineZoneChests.POOLS[zoneId] then
		return zoneId
	end
	return "meadow"
end

-- The Shiny Chest's chance on a block of (zone, layer).
function MineZoneChests.shinyChance(zoneIndex, layer)
	zoneIndex = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	if zoneIndex <= 1 then
		return (layer >= 2500) and (1 / 8000) or 0
	end
	local t = math.clamp((zoneIndex - 1) / 9, 0, 1)
	return (1 / 2500) * (1 - t) + 0.008 * t
end

--[[
	THE SPAWN TABLE: every chest a chest block at (zone, layer) can be, with its
	exact chance. rollSpawn draws from it, the economy check sums over it, and a
	screen can print it. `better` is the depth luck (MineConfig.chestRankLuck),
	`zoneIndex` the zone's place in MineConfig.ZONES (for the Shiny Chest).
	{ { def, rank, p }, ... }, p summing to 1.
]]
function MineZoneChests.spawnTable(zoneId, layer, zoneIndex, better)
	zoneId = zoneOr(zoneId)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	local odds = MineChestRanks.odds(better)
	local shiny = (zoneId == "bigbang") and 0 or MineZoneChests.shinyChance(zoneIndex, layer)
	local living = MineSetChests.livingAt(zoneId, layer)
	local rows = {}
	local byRank = {}
	for _, row in ipairs(MineZoneChests.POOLS[zoneId]) do
		byRank[row.rank] = byRank[row.rank] or {}
		table.insert(byRank[row.rank], MineZoneChests.DEFS[row.chestId])
	end
	for _, rank in ipairs(LADDER) do
		local p = (odds[rank] or 0) * (1 - shiny)
		local tier = MineSetChests.tierForRank(rank)
		local setShare = (tier and #living > 0) and MineSetChests.SHARE or 0
		local zoneDefs = byRank[rank] or {}
		if #zoneDefs == 0 then
			-- A zone with no chest of this rank pays a set chest when one
			-- lives here, else its nearest rank down.
			setShare = (setShare > 0) and 1 or 0
		end
		if setShare > 0 then
			for _, set in ipairs(living) do
				local d = MineZoneChests.DEFS[MineSetChests.chestId(set.key, tier)]
				table.insert(rows, { def = d, rank = rank, p = p * setShare / #living })
			end
		end
		local left = p * (1 - setShare)
		if left > 0 then
			if #zoneDefs == 0 then
				for i = MineChestRanks.index(rank) - 1, 1, -1 do
					zoneDefs = byRank[LADDER[i]] or {}
					if #zoneDefs > 0 then
						break
					end
				end
			end
			for _, d in ipairs(zoneDefs) do
				table.insert(rows, { def = d, rank = d.rank, p = left / #zoneDefs })
			end
		end
	end
	if shiny > 0 then
		table.insert(rows, { def = MineZoneChests.DEFS[MineZoneChests.SHINY_ID], rank = MineZoneChests.SHINY_RANK, p = shiny })
	end
	return rows
end

-- One chest for a chest block: rank first, then which chest (see the header).
function MineZoneChests.rollSpawn(zoneId, layer, zoneIndex, better)
	local rng = Random.new()
	local rows = MineZoneChests.spawnTable(zoneId, layer, zoneIndex, better)
	local u = rng:NextNumber()
	for _, row in ipairs(rows) do
		u -= row.p
		if u <= 0 then
			return row.def
		end
	end
	return rows[1] and rows[1].def or nil
end

--[[
	The open-time fallback for a block whose chest id is not known (a block
	spawned before 2026-10-19 carrying a Mine 1 catalog or section chest id).
	Rolls from the same table as a fresh block: { chestId, rank, def }.
	opts: { layer, better, zoneIndex }.
]]
function MineZoneChests.roll(zoneId, rng, opts)
	opts = opts or {}
	rng = rng or Random.new()
	local rows = MineZoneChests.spawnTable(zoneId, opts.layer, opts.zoneIndex, opts.better)
	local u = rng:NextNumber()
	for _, row in ipairs(rows) do
		u -= row.p
		if u <= 0 then
			return { chestId = row.def.id, rank = row.def.rank, def = row.def }
		end
	end
	local d = rows[1] and rows[1].def
	return d and { chestId = d.id, rank = d.rank, def = d } or nil
end

-- The zone whose bases a chest pays from: its own, else where it was opened.
local function payZone(def, zoneId)
	local z = (def and def.zoneId) or zoneId
	if not MineZoneChests.GEM_BASE[z] then
		z = zoneOr(zoneId)
	end
	return z
end

local function hpAt(layer)
	local okC, C = pcall(function()
		return require(script.Parent:WaitForChild("MineConfig"))
	end)
	if okC and C and C.dirtHp then
		return math.max(1, tonumber(C.dirtHp(layer)) or 1)
	end
	return 20 + 1.5 * layer
end

--[[
	WHAT A CHEST PAYS at `layer`, opened in `zoneId` (a chest pays its own
	zone's bases; the Shiny Chest pays where it is opened):
	  { coins = { lo, hi }, gems = { lo, hi }, packs = { { slot | packIds, chance } } }
	`chance` is a percent and may pass 100 (over 100 pays one for sure).
	A set chest's card pack is its set's: { set = key, tier = tier, chance = 100 }.
]]
MineZoneChests.GEM_SPREAD = 0.2
MineZoneChests.COIN_SPREAD = 0.3

function MineZoneChests.payout(def, zoneId, layer)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	local z = payZone(def, zoneId)
	local rank = (def and def.rank) or "F"
	local pay = MineZoneChests.PAY[rank] or 1
	local gemMean = (MineZoneChests.GEM_BASE[z] or 0) * pay
	local cb = MineZoneChests.COIN_BASE[z] or MineZoneChests.COIN_BASE.meadow
	local coinMean = ((cb.flat or 0) + (cb.perHp or 0) * hpAt(layer)) * pay
	if z == "meadow" and layer <= MineZoneChests.MEADOW_EARLY_LAYERS then
		coinMean *= MineZoneChests.MEADOW_EARLY_COIN_MULT
	end
	local function band(mean, spread)
		if mean <= 0 then
			return { 0, 0 }
		end
		local lo = math.max(0, math.floor(mean * (1 - spread) + 0.5))
		local hi = math.max(lo, math.floor(mean * (1 + spread) + 0.5))
		return { lo, hi }
	end
	local packs = {}
	local bases = MineZoneChests.PACK_BASE[z] or MineZoneChests.PACK_BASE.meadow
	for _, slot in ipairs(MineZoneChests.PACK_SLOTS) do
		local isCard = string.sub(slot, 1, 5) == "pack_"
		if not (def and def.setKey and isCard) then
			local c = (bases[slot] or 0) * ((MineZoneChests.PACK_MULT[slot] or {})[rank] or 0) * 100
			if c > 0 then
				table.insert(packs, { slot = slot, chance = math.floor(c * 10 + 0.5) / 10 })
			end
		end
	end
	if def and def.setKey then
		table.insert(packs, 1, { set = def.setKey, tier = def.setTier, chance = 100 })
	end
	return {
		coins = band(coinMean, MineZoneChests.COIN_SPREAD),
		gems = band(gemMean, MineZoneChests.GEM_SPREAD),
		packs = packs,
		rank = rank,
		zoneId = z,
	}
end

--[[
	Coins and gems for one chest, from payout's bands. `layer` and `zoneId`
	are where it was opened; an old caller passing neither gets a chest at a
	zone's top. A def that predates the ranks (the section chests, the catalog)
	keeps its own bands.
]]
function MineZoneChests.rollCurrency(chestDef, rng, layer, zoneId)
	rng = rng or Random.new()
	local coinsBand, gemsBand
	if chestDef and chestDef.rank and MineChestRanks.valid(chestDef.rank) then
		local pay = MineZoneChests.payout(chestDef, zoneId, layer or 1)
		coinsBand, gemsBand = pay.coins, pay.gems
	else
		coinsBand, gemsBand = chestDef and chestDef.coins, chestDef and chestDef.gems
	end
	local function roll(pair)
		local lo = math.floor(tonumber(pair and pair[1]) or 0)
		local hi = math.floor(tonumber(pair and pair[2]) or lo)
		if hi <= lo then
			return math.max(0, lo)
		end
		return rng:NextInteger(lo, hi)
	end
	local coins = roll(coinsBand)
	local gems = roll(gemsBand)
	if coins < 1 then
		coins = 1
	end
	return coins, gems
end

--[[
	The packs one chest pays: zone pack ids (MineZonePacks.id), and for a set
	chest one of its set's packs ("<set>_pack_<n>"). Each entry is its own
	roll; a chance over 100 pays floor(chance/100) for sure and rolls the rest.
]]
function MineZoneChests.rollPackDrops(zoneId, chestDef, rng, layer)
	rng = rng or Random.new()
	local out = {}
	local list
	if chestDef and chestDef.rank and MineChestRanks.valid(chestDef.rank) then
		list = MineZoneChests.payout(chestDef, zoneId, layer or 1).packs
	else
		list = (chestDef and chestDef.packs) or {}
	end
	for _, entry in ipairs(list) do
		local chance = tonumber(entry.chance) or 0
		local n = math.floor(chance / 100)
		if rng:NextNumber() * 100 < (chance - n * 100) then
			n += 1
		end
		for _ = 1, n do
			if entry.set then
				local id = MineSetChests.rollPack(entry.set, entry.tier, rng)
				if id then
					table.insert(out, id)
				end
			elseif entry.slot then
				table.insert(out, MineZonePacks.id(zoneId, entry.slot))
			end
		end
	end
	return out
end

-- Kept for old callers: ranks are fixed now, so nothing ages.
function MineZoneChests.ageZone(_zoneId) end

function MineZoneChests.onPermanentZoneUnlocked(_unlockedZoneId) end

-- One chest identity per section (Meadow 100, Event Horizon 2). LEGACY since
-- 2026-10-19: section chests no longer spawn or pay (a block's own chest pays
-- now). Kept so an old id still names something.
local exclusiveCache = {}

local function legacyPacks(...)
	local out = {}
	for i = 1, select("#", ...), 2 do
		local slot, chance = select(i, ...)
		table.insert(out, { slot = slot, chance = chance })
	end
	return out
end

function MineZoneChests.exclusiveFor(zoneId, layer)
	local C = require(script.Parent:WaitForChild("MineConfig"))
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	local n = C.sectionNumber and C.sectionNumber(layer) or (math.floor((layer - 1) / 25) + 1)
	local key = tostring(zoneId) .. ":" .. tostring(n)
	if exclusiveCache[key] then
		return exclusiveCache[key]
	end
	local stamp = C.sectionStamp and C.sectionStamp(layer) or { n = n, roman = tostring(n), label = tostring(n) .. ".", arabic = tostring(n) }
	local hp = math.max(1, math.floor((C.dirtHp and C.dirtHp(layer)) or 10))
	local sec
	if zoneId == "bigbang" and C.zoneSectionFor then
		sec = C.zoneSectionFor(zoneId, layer)
	elseif C.sectionFor then
		sec = C.sectionFor(layer)
	end
	local isEH = zoneId == "bigbang"
	local prefix = isEH and "eh_chest_" or "sec_chest_"
	local packList
	if isEH then
		packList = legacyPacks("pack_common", 50, "pack_rare", 16, "pack_legendary", 4, "currency_common", 35, "currency_rare", 12)
	else
		packList = legacyPacks("currency_common", 72, "pack_common", 18, "pack_rare", 6, "pack_legendary", 1, "currency_rare", 3)
	end
	local def = {
		id = prefix .. n,
		name = stamp.label .. " " .. ((sec and sec.name) or "Chest"),
		kind = "native",
		coins = (zoneId == "meadow" and n <= 2) and { hp * 3, hp * 6 } or { hp, math.max(hp, math.floor(hp * 2)) },
		gems = { 0, 0 },
		packs = packList,
		sectionN = n,
		roman = stamp.roman,
		arabic = stamp.arabic,
		exclusive = true,
		eh = isEH,
		zoneId = zoneId,
	}
	exclusiveCache[key] = def
	return def
end

-- How a pack line reads on a screen: "Rare Pack", or a set chest's set pack.
function MineZoneChests.packLabel(entry)
	if type(entry) ~= "table" then
		return "?"
	end
	if entry.set then
		local okS, SetPacks = pcall(function()
			return require(script.Parent:WaitForChild("MineSetPacks"))
		end)
		local name = tostring(entry.set)
		local stars = {}
		if okS and SetPacks then
			local okP, SetPets = pcall(function()
				return require(script.Parent:WaitForChild("MineSetPets"))
			end)
			local set = okP and SetPets and SetPets.BY_KEY and SetPets.BY_KEY[entry.set]
			name = (set and set.NAME) or name
			for _, r in ipairs(MineSetChests.PACK_STARS[entry.tier] or {}) do
				table.insert(stars, (SetPacks.STAR_TEXT and SetPacks.STAR_TEXT[r[1]]) or tostring(r[1]))
			end
		end
		return name .. " " .. table.concat(stars, " or ") .. " pack"
	end
	local meta = MineZonePacks.SLOT_META and MineZonePacks.SLOT_META[entry.slot]
	return (meta and meta.label) or tostring(entry.slot or "?")
end

--[[
	Collection rows: every chest, with its rank, the zone it lives in and what
	it pays at that zone's top (coins grow with depth; the rest does not).
	`packs` rows carry `slot` as their printed name, for the screens that print
	it.
]]
function MineZoneChests.collectionRows()
	local list = {}
	local function add(d, zoneId)
		local pay = MineZoneChests.payout(d, zoneId, 1)
		local packs = {}
		for _, pk in ipairs(pay.packs) do
			table.insert(packs, { slot = MineZoneChests.packLabel(pk), chance = pk.chance })
		end
		table.insert(list, {
			id = d.id,
			name = d.name,
			rank = d.rank,
			coins = pay.coins,
			gems = pay.gems,
			packs = packs,
			setKey = d.setKey,
			setTier = d.setTier,
			zones = { { zoneId = zoneId, rank = d.rank } },
		})
	end
	for zoneId, pool in pairs(MineZoneChests.POOLS) do
		for _, row in ipairs(pool) do
			add(MineZoneChests.DEFS[row.chestId], zoneId)
		end
	end
	for _, set in ipairs(MineSetChests.SETS) do
		for _, tier in ipairs(MineSetChests.TIERS) do
			add(MineZoneChests.DEFS[MineSetChests.chestId(set.key, tier)], set.zoneId)
		end
	end
	table.sort(list, function(a, b)
		local ra, rb = MineChestRanks.index(a.rank), MineChestRanks.index(b.rank)
		if ra ~= rb then
			return ra < rb
		end
		return a.name < b.name
	end)
	return list
end

return MineZoneChests
