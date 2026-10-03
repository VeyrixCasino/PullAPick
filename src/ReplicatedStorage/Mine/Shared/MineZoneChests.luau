--[[
	MineZoneChests — per-zone chest pools with overlap + S/A/B/C/D/F ranks.

	DEFS: fixed gem/coin ranges (no zone scaling at payout time).
	POOLS[zoneId]: { { chestId, rank }, ... } — same chestId may appear in
	multiple zones (overlap). Age on permanent zone unlock; inject next S.
]]

local MineChestRanks = require(script.Parent:WaitForChild("MineChestRanks"))
local MineZonePacks = require(script.Parent:WaitForChild("MineZonePacks"))

local MineZoneChests = {}

local function def(id, name, coins, gems, packs)
	return {
		id = id,
		name = name,
		coins = coins,
		gems = gems,
		packs = packs,
	}
end

local function packs(...)
	local out = {}
	for i = 1, select("#", ...), 2 do
		local slot, chance = select(i, ...)
		table.insert(out, { slot = slot, chance = chance })
	end
	return out
end

-- Fixed payouts — human bands, no runtime zone/depth multipliers.
MineZoneChests.DEFS = {
	-- Not in any pool. rollSpawn grants it under a hard cap.
	shiny_chest = def("shiny_chest", "Shiny Chest", { 800, 2400 }, { 12, 40 }, packs("pack_legendary", 40, "currency_rare", 80)),
	-- Meadow
	meadow_topsoil = def("meadow_topsoil", "Topsoil Cache", { 6, 22 }, { 1, 3 },
		packs("pack_common", 70, "currency_common", 40)),
	meadow_rootbox = def("meadow_rootbox", "Rootbox", { 10, 35 }, { 1, 4 },
		packs("pack_common", 55, "pack_rare", 25)),
	meadow_loam_vault = def("meadow_loam_vault", "Loam Vault", { 20, 60 }, { 2, 6 },
		packs("pack_rare", 45, "currency_rare", 30)),
	meadow_sunrise = def("meadow_sunrise", "Sunrise Strongbox", { 40, 100 }, { 3, 8 },
		packs("pack_legendary", 35, "pack_rare", 20)),
	meadow_sod_crate = def("meadow_sod_crate", "Sod Crate", { 8, 28 }, { 1, 3 },
		packs("currency_common", 60, "pack_common", 35)),
	meadow_briar = def("meadow_briar", "Briar Chest", { 14, 44 }, { 1, 5 },
		packs("pack_common", 50, "pack_rare", 20)),
	meadow_hillock = def("meadow_hillock", "Hillock Cache", { 18, 55 }, { 2, 5 },
		packs("pack_common", 35, "currency_common", 40)),
	meadow_age_s1 = def("meadow_age_s1", "Dewvault", { 55, 130 }, { 4, 10 },
		packs("pack_legendary", 40, "currency_rare", 35)),
	meadow_age_s2 = def("meadow_age_s2", "Canopy Coffer", { 70, 160 }, { 5, 12 },
		packs("pack_legendary", 45, "pack_rare", 28)),

	-- Seam / overlap
	seam_cobble = def("seam_cobble", "Cobble Seam Chest", { 15, 50 }, { 2, 5 },
		packs("pack_common", 50, "pack_rare", 25)),
	seam_slate = def("seam_slate", "Slate Seam Chest", { 30, 90 }, { 3, 8 },
		packs("pack_rare", 45, "pack_common", 30)),
	seam_mist = def("seam_mist", "Mist Seam Chest", { 45, 130 }, { 4, 11 },
		packs("pack_rare", 50, "currency_rare", 30)),
	seam_spark = def("seam_spark", "Spark Seam Chest", { 60, 170 }, { 5, 14 },
		packs("pack_legendary", 35, "pack_rare", 40)),
	seam_crimson = def("seam_crimson", "Crimson Seam Chest", { 80, 220 }, { 6, 16 },
		packs("pack_legendary", 40, "pack_rare", 25)),
	seam_shadow = def("seam_shadow", "Shadow Seam Chest", { 100, 280 }, { 8, 20 },
		packs("pack_legendary", 42, "currency_rare", 35)),
	seam_rift = def("seam_rift", "Rift Seam Chest", { 130, 340 }, { 10, 24 },
		packs("pack_legendary", 45, "pack_rare", 30)),
	seam_star = def("seam_star", "Star Seam Chest", { 160, 400 }, { 12, 28 },
		packs("pack_legendary", 48, "pack_rare", 40)),
	seam_myth = def("seam_myth", "Myth Seam Chest", { 200, 480 }, { 14, 32 },
		packs("pack_legendary", 50, "pack_rare", 32)),
	seam_prime = def("seam_prime", "Prime Seam Chest", { 240, 560 }, { 16, 36 },
		packs("pack_legendary", 52, "currency_rare", 40)),

	-- Greyvein (sunscar)
	greyvein_flagstone = def("greyvein_flagstone", "Flagstone Chest", { 25, 80 }, { 3, 7 },
		packs("pack_common", 65, "currency_common", 35)),
	greyvein_shale = def("greyvein_shale", "Shale Coffer", { 40, 120 }, { 4, 10 },
		packs("pack_rare", 50, "pack_common", 30)),
	greyvein_granite = def("greyvein_granite", "Granite Vault", { 80, 200 }, { 6, 14 },
		packs("pack_legendary", 40, "pack_rare", 22, "currency_rare", 25)),
	greyvein_quarry = def("greyvein_quarry", "Quarry Cache", { 28, 90 }, { 3, 8 },
		packs("pack_common", 55, "pack_rare", 28)),
	greyvein_chisel = def("greyvein_chisel", "Chisel Box", { 35, 110 }, { 3, 9 },
		packs("currency_common", 50, "pack_rare", 30)),
	greyvein_bedrock = def("greyvein_bedrock", "Bedrock Strongbox", { 55, 150 }, { 5, 12 },
		packs("pack_rare", 48, "currency_rare", 28)),
	greyvein_age_s1 = def("greyvein_age_s1", "Keystone Vault", { 95, 240 }, { 7, 16 },
		packs("pack_legendary", 42, "pack_rare", 26)),
	greyvein_age_s2 = def("greyvein_age_s2", "Slate Crown", { 120, 280 }, { 8, 18 },
		packs("pack_legendary", 48, "currency_rare", 32)),

	-- Mistreef
	mist_tide = def("mist_tide", "Tide Chest", { 35, 110 }, { 4, 9 },
		packs("pack_common", 60, "currency_common", 40)),
	mist_kelp = def("mist_kelp", "Kelp Coffer", { 50, 140 }, { 5, 11 },
		packs("pack_rare", 48, "pack_common", 32)),
	mist_reef = def("mist_reef", "Reef Vault", { 90, 230 }, { 7, 15 },
		packs("pack_legendary", 38, "pack_rare", 24)),
	mist_brine = def("mist_brine", "Brine Cache", { 40, 120 }, { 4, 10 },
		packs("currency_common", 55, "pack_common", 40)),
	mist_coral = def("mist_coral", "Coral Box", { 60, 160 }, { 5, 12 },
		packs("pack_rare", 45, "currency_rare", 28)),
	mist_age_s1 = def("mist_age_s1", "Abyss Pearl", { 130, 300 }, { 9, 18 },
		packs("pack_legendary", 44, "pack_rare", 28)),
	mist_age_s2 = def("mist_age_s2", "Undertow Vault", { 150, 340 }, { 10, 20 },
		packs("pack_legendary", 50, "currency_rare", 30)),

	-- Arcwork
	arc_coil = def("arc_coil", "Coil Chest", { 50, 150 }, { 5, 12 },
		packs("pack_common", 58, "currency_common", 42)),
	arc_spark = def("arc_spark", "Spark Coffer", { 70, 190 }, { 6, 14 },
		packs("pack_rare", 50, "pack_common", 30)),
	arc_core = def("arc_core", "Core Vault", { 120, 300 }, { 9, 18 },
		packs("pack_legendary", 40, "pack_rare", 25)),
	arc_wire = def("arc_wire", "Wire Box", { 55, 160 }, { 5, 13 },
		packs("currency_common", 50, "pack_common", 45)),
	arc_flux = def("arc_flux", "Flux Cache", { 85, 220 }, { 7, 15 },
		packs("pack_rare", 48, "currency_rare", 30)),
	arc_age_s1 = def("arc_age_s1", "Dynamo Vault", { 160, 380 }, { 11, 22 },
		packs("pack_legendary", 46, "pack_rare", 30)),
	arc_age_s2 = def("arc_age_s2", "Circuit Crown", { 180, 420 }, { 12, 24 },
		packs("pack_legendary", 52, "currency_rare", 32)),

	-- Bloodmoon
	blood_ember = def("blood_ember", "Ember Chest", { 70, 200 }, { 6, 14 },
		packs("pack_common", 55, "currency_common", 40)),
	blood_fang = def("blood_fang", "Fang Coffer", { 95, 250 }, { 8, 16 },
		packs("pack_rare", 50, "pack_common", 32)),
	blood_lunar = def("blood_lunar", "Lunar Vault", { 150, 360 }, { 11, 20 },
		packs("pack_legendary", 42, "pack_rare", 26)),
	blood_ash = def("blood_ash", "Ash Cache", { 75, 210 }, { 7, 15 },
		packs("currency_common", 48, "pack_common", 42)),
	blood_veil = def("blood_veil", "Veil Box", { 110, 280 }, { 9, 17 },
		packs("pack_rare", 48, "currency_rare", 30)),
	blood_age_s1 = def("blood_age_s1", "Crimson Reliquary", { 200, 460 }, { 13, 26 },
		packs("pack_legendary", 48, "pack_rare", 30)),
	blood_age_s2 = def("blood_age_s2", "Eclipse Scar", { 230, 520 }, { 14, 28 },
		packs("pack_legendary", 54, "currency_rare", 34)),

	-- Eclipse
	ecl_umbral = def("ecl_umbral", "Umbral Chest", { 90, 250 }, { 8, 16 },
		packs("pack_common", 52, "currency_common", 40)),
	ecl_void = def("ecl_void", "Void Coffer", { 120, 310 }, { 10, 19 },
		packs("pack_rare", 50, "pack_common", 34)),
	ecl_nocturne = def("ecl_nocturne", "Nocturne Vault", { 190, 440 }, { 13, 24 },
		packs("pack_legendary", 44, "pack_rare", 28)),
	ecl_shade = def("ecl_shade", "Shade Cache", { 100, 270 }, { 9, 17 },
		packs("currency_common", 48, "pack_common", 40)),
	ecl_penumbra = def("ecl_penumbra", "Penumbra Box", { 140, 340 }, { 11, 20 },
		packs("pack_rare", 48, "currency_rare", 32)),
	ecl_age_s1 = def("ecl_age_s1", "Black Sun Vault", { 250, 560 }, { 15, 30 },
		packs("pack_legendary", 50, "pack_rare", 32)),
	ecl_age_s2 = def("ecl_age_s2", "Totality Crown", { 280, 620 }, { 16, 32 },
		packs("pack_legendary", 55, "currency_rare", 36)),

	-- Riftmarch
	rift_tear = def("rift_tear", "Tear Chest", { 110, 300 }, { 10, 18 },
		packs("pack_common", 50, "currency_common", 40)),
	rift_scar = def("rift_scar", "Scar Coffer", { 150, 380 }, { 12, 22 },
		packs("pack_rare", 50, "pack_common", 34)),
	rift_gate = def("rift_gate", "Gate Vault", { 230, 520 }, { 15, 28 },
		packs("pack_legendary", 46, "pack_rare", 30)),
	rift_fracture = def("rift_fracture", "Fracture Cache", { 120, 320 }, { 11, 20 },
		packs("currency_common", 48, "pack_common", 40)),
	rift_warp = def("rift_warp", "Warp Box", { 170, 420 }, { 13, 24 },
		packs("pack_rare", 48, "currency_rare", 32)),
	rift_age_s1 = def("rift_age_s1", "Breach Reliquary", { 300, 680 }, { 18, 34 },
		packs("pack_legendary", 52, "pack_rare", 34)),
	rift_age_s2 = def("rift_age_s2", "March Crown", { 340, 740 }, { 20, 36 },
		packs("pack_legendary", 56, "currency_rare", 38)),

	-- Starfall
	star_dust = def("star_dust", "Stardust Chest", { 140, 360 }, { 12, 22 },
		packs("pack_common", 50, "currency_common", 42)),
	star_comet = def("star_comet", "Comet Coffer", { 180, 440 }, { 14, 26 },
		packs("pack_rare", 50, "pack_common", 35)),
	star_nova = def("star_nova", "Nova Vault", { 280, 620 }, { 18, 32 },
		packs("pack_legendary", 48, "pack_rare", 32)),
	star_orbit = def("star_orbit", "Orbit Cache", { 150, 380 }, { 13, 24 },
		packs("currency_common", 48, "pack_common", 40)),
	star_meteor = def("star_meteor", "Meteor Box", { 210, 500 }, { 15, 28 },
		packs("pack_rare", 48, "currency_rare", 34)),
	star_age_s1 = def("star_age_s1", "Constellation Vault", { 360, 800 }, { 22, 40 },
		packs("pack_legendary", 54, "pack_rare", 36)),
	star_age_s2 = def("star_age_s2", "Aurora Crown", { 400, 880 }, { 24, 42 },
		packs("pack_legendary", 58, "currency_rare", 40)),

	-- Mythral
	myth_shard = def("myth_shard", "Shard Chest", { 170, 420 }, { 14, 26 },
		packs("pack_common", 48, "currency_common", 42)),
	myth_lattice = def("myth_lattice", "Lattice Coffer", { 220, 520 }, { 16, 30 },
		packs("pack_rare", 50, "pack_common", 36)),
	myth_prism = def("myth_prism", "Prism Vault", { 340, 740 }, { 22, 36 },
		packs("pack_legendary", 50, "pack_rare", 34)),
	myth_gleam = def("myth_gleam", "Gleam Cache", { 180, 450 }, { 15, 28 },
		packs("currency_common", 48, "pack_common", 40)),
	myth_aether = def("myth_aether", "Aether Box", { 260, 600 }, { 18, 32 },
		packs("pack_rare", 48, "currency_rare", 36)),
	myth_age_s1 = def("myth_age_s1", "Mythforge Vault", { 440, 960 }, { 26, 46 },
		packs("pack_legendary", 56, "pack_rare", 38)),
	myth_age_s2 = def("myth_age_s2", "Crystal Crown", { 480, 1040 }, { 28, 48 },
		packs("pack_legendary", 60, "currency_rare", 42)),

	-- Primordium
	prime_seed = def("prime_seed", "Seed Chest", { 210, 500 }, { 16, 30 },
		packs("pack_common", 48, "currency_common", 42)),
	prime_bone = def("prime_bone", "Bone Coffer", { 270, 620 }, { 19, 34 },
		packs("pack_rare", 50, "pack_common", 38)),
	prime_heart = def("prime_heart", "Heart Vault", { 400, 880 }, { 26, 42 },
		packs("pack_legendary", 52, "pack_rare", 36)),
	prime_ash = def("prime_ash", "Primordial Ash", { 230, 540 }, { 17, 32 },
		packs("currency_common", 48, "pack_common", 40)),
	prime_ember = def("prime_ember", "World Ember", { 320, 720 }, { 22, 38 },
		packs("pack_rare", 48, "currency_rare", 38)),
	prime_age_s1 = def("prime_age_s1", "Origin Reliquary", { 520, 1120 }, { 30, 52 },
		packs("pack_legendary", 58, "pack_rare", 40)),
	prime_age_s2 = def("prime_age_s2", "First Crown", { 580, 1240 }, { 32, 56 },
		packs("pack_legendary", 62, "currency_rare", 44)),

	-- Event Horizon (limited) — card/currency only.
	hz_event = def("hz_event", "Event Cache", { 300, 700 }, { 20, 40 },
		packs("pack_common", 55, "currency_common", 45)),
	hz_singularity = def("hz_singularity", "Singularity Coffer", { 400, 900 }, { 26, 48 },
		packs("pack_rare", 58, "pack_common", 40)),
	hz_horizon = def("hz_horizon", "Horizon Vault", { 600, 1400 }, { 34, 60 },
		packs("pack_legendary", 60, "pack_rare", 40)),
	hz_pulse = def("hz_pulse", "Pulse Box", { 350, 800 }, { 22, 44 },
		packs("currency_rare", 40, "pack_rare", 45)),
	hz_collapse = def("hz_collapse", "Collapse Chest", { 500, 1100 }, { 30, 52 },
		packs("pack_legendary", 55, "currency_rare", 40)),
}

--[[
	Initial pools (~12–16 identities). Neighbor overlap via seam_* and shared defs.
	S_QUEUE injects a new S on each age-up.
]]
--[[
	GEM PACING (re-cut 2026-09-19 for launch). Chests are the main gem source
	and pay a smooth ~1.3k gems in Greyvein, rising x1.4 a zone (to ~19k in
	Primordium). With chests at MineConfig.CHEST_CHANCE and the zone prices in
	MineConfig.ZONES, a typical player (simulated from the live shop, bag, HP,
	chest, quest, gift and daily tables) spends 15 / 30 / 45 / 60 / 75 / 90 /
	105 / 120 / 150 minutes in each zone before the next one: about 11.5 hours
	from a fresh save to Primordium. Meadow chests stay gem-free (its currency
	packs pay a little); the tutorial pays Greyvein's portal.

	Applied to each chest's own range by its home zone, so the collection
	screen and the payout read the same numbers. Seam chests belong to the
	zone where they show up most.
]]
MineZoneChests.GEM_MULT = {
	meadow = 1, sunscar = 250, mistreef = 270, arcwork = 285, bloodmoon = 345,
	eclipse = 395, riftmarch = 465, starfall = 550, mythral = 660, primordium = 820,
}
local GEM_HOME_PREFIX = {
	meadow = "meadow", greyvein = "sunscar", mist = "mistreef", arc = "arcwork", blood = "bloodmoon",
	ecl = "eclipse", rift = "riftmarch", star = "starfall", myth = "mythral", prime = "primordium",
}
local GEM_HOME_SEAM = {
	seam_cobble = "sunscar", seam_slate = "mistreef", seam_mist = "arcwork", seam_spark = "bloodmoon",
	seam_crimson = "eclipse", seam_shadow = "riftmarch", seam_rift = "starfall", seam_star = "mythral",
	seam_myth = "primordium", seam_prime = "primordium",
}
for id, d in pairs(MineZoneChests.DEFS) do
	local home = GEM_HOME_SEAM[id] or GEM_HOME_PREFIX[string.match(id, "^(%a+)_") or ""]
	local m = home and MineZoneChests.GEM_MULT[home] or 1
	if m ~= 1 and type(d.gems) == "table" then
		d.baseGems = { d.gems[1], d.gems[2] }
		d.gems = { math.floor(d.gems[1] * m + 0.5), math.floor(d.gems[2] * m + 0.5) }
	end
end

MineZoneChests.POOLS = {
	meadow = {
		{ chestId = "meadow_topsoil", rank = "C" },
		{ chestId = "meadow_rootbox", rank = "C" },
		{ chestId = "meadow_sod_crate", rank = "C" },
		{ chestId = "meadow_briar", rank = "B" },
		{ chestId = "meadow_hillock", rank = "B" },
		{ chestId = "meadow_loam_vault", rank = "A" },
		{ chestId = "meadow_sunrise", rank = "S" },
		{ chestId = "seam_cobble", rank = "A" },
	},
	sunscar = {
		{ chestId = "greyvein_flagstone", rank = "C" },
		{ chestId = "greyvein_quarry", rank = "C" },
		{ chestId = "greyvein_chisel", rank = "C" },
		{ chestId = "greyvein_shale", rank = "B" },
		{ chestId = "greyvein_bedrock", rank = "B" },
		{ chestId = "greyvein_granite", rank = "S" },
		{ chestId = "seam_cobble", rank = "B" },
		{ chestId = "seam_slate", rank = "A" },
		{ chestId = "meadow_loam_vault", rank = "D" },
	},
	mistreef = {
		{ chestId = "mist_tide", rank = "C" },
		{ chestId = "mist_brine", rank = "C" },
		{ chestId = "mist_kelp", rank = "B" },
		{ chestId = "mist_coral", rank = "B" },
		{ chestId = "mist_reef", rank = "S" },
		{ chestId = "seam_slate", rank = "B" },
		{ chestId = "seam_mist", rank = "A" },
		{ chestId = "greyvein_shale", rank = "D" },
	},
	arcwork = {
		{ chestId = "arc_coil", rank = "C" },
		{ chestId = "arc_wire", rank = "C" },
		{ chestId = "arc_spark", rank = "B" },
		{ chestId = "arc_flux", rank = "B" },
		{ chestId = "arc_core", rank = "S" },
		{ chestId = "seam_mist", rank = "B" },
		{ chestId = "seam_spark", rank = "A" },
		{ chestId = "mist_kelp", rank = "D" },
	},
	bloodmoon = {
		{ chestId = "blood_ember", rank = "C" },
		{ chestId = "blood_ash", rank = "C" },
		{ chestId = "blood_fang", rank = "B" },
		{ chestId = "blood_veil", rank = "B" },
		{ chestId = "blood_lunar", rank = "S" },
		{ chestId = "seam_spark", rank = "B" },
		{ chestId = "seam_crimson", rank = "A" },
		{ chestId = "arc_spark", rank = "D" },
	},
	eclipse = {
		{ chestId = "ecl_umbral", rank = "C" },
		{ chestId = "ecl_shade", rank = "C" },
		{ chestId = "ecl_void", rank = "B" },
		{ chestId = "ecl_penumbra", rank = "B" },
		{ chestId = "ecl_nocturne", rank = "S" },
		{ chestId = "seam_crimson", rank = "B" },
		{ chestId = "seam_shadow", rank = "A" },
		{ chestId = "blood_fang", rank = "D" },
	},
	riftmarch = {
		{ chestId = "rift_tear", rank = "C" },
		{ chestId = "rift_fracture", rank = "C" },
		{ chestId = "rift_scar", rank = "B" },
		{ chestId = "rift_warp", rank = "B" },
		{ chestId = "rift_gate", rank = "S" },
		{ chestId = "seam_shadow", rank = "B" },
		{ chestId = "seam_rift", rank = "A" },
		{ chestId = "ecl_void", rank = "D" },
	},
	starfall = {
		{ chestId = "star_dust", rank = "C" },
		{ chestId = "star_orbit", rank = "C" },
		{ chestId = "star_comet", rank = "B" },
		{ chestId = "star_meteor", rank = "B" },
		{ chestId = "star_nova", rank = "S" },
		{ chestId = "seam_rift", rank = "B" },
		{ chestId = "seam_star", rank = "A" },
		{ chestId = "rift_scar", rank = "D" },
	},
	mythral = {
		{ chestId = "myth_shard", rank = "C" },
		{ chestId = "myth_gleam", rank = "C" },
		{ chestId = "myth_lattice", rank = "B" },
		{ chestId = "myth_aether", rank = "B" },
		{ chestId = "myth_prism", rank = "S" },
		{ chestId = "seam_star", rank = "B" },
		{ chestId = "seam_myth", rank = "A" },
		{ chestId = "star_comet", rank = "D" },
	},
	primordium = {
		{ chestId = "prime_seed", rank = "C" },
		{ chestId = "prime_ash", rank = "C" },
		{ chestId = "prime_bone", rank = "B" },
		{ chestId = "prime_ember", rank = "B" },
		{ chestId = "prime_heart", rank = "S" },
		{ chestId = "seam_myth", rank = "B" },
		{ chestId = "seam_prime", rank = "A" },
		{ chestId = "myth_lattice", rank = "D" },
	},
	bigbang = {
		{ chestId = "hz_event", rank = "C" },
		{ chestId = "hz_pulse", rank = "C" },
		{ chestId = "hz_singularity", rank = "B" },
		{ chestId = "hz_collapse", rank = "A" },
		{ chestId = "hz_horizon", rank = "S" },
	},
}

-- New S chests introduced when a zone ages (FIFO).
MineZoneChests.S_QUEUE = {
	meadow = { "meadow_age_s1", "meadow_age_s2" },
	sunscar = { "greyvein_age_s1", "greyvein_age_s2" },
	mistreef = { "mist_age_s1", "mist_age_s2" },
	arcwork = { "arc_age_s1", "arc_age_s2" },
	bloodmoon = { "blood_age_s1", "blood_age_s2" },
	eclipse = { "ecl_age_s1", "ecl_age_s2" },
	riftmarch = { "rift_age_s1", "rift_age_s2" },
	starfall = { "star_age_s1", "star_age_s2" },
	mythral = { "myth_age_s1", "myth_age_s2" },
	primordium = { "prime_age_s1", "prime_age_s2" },
}

function MineZoneChests.def(chestId)
	return MineZoneChests.DEFS[chestId]
end

function MineZoneChests.pool(zoneId)
	return MineZoneChests.POOLS[zoneId]
end

-- One chest identity per section (Meadow 100, Event Horizon 2). Shared body,
-- stamped number. Always coins; packs are independent extra rolls.
local exclusiveCache = {}

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
		packList = packs("pack_common", 50, "pack_rare", 16, "pack_legendary", 4, "currency_common", 35, "currency_rare", 12)
	else
		-- Packs are chase from chests — coins default. Soft packs rare; legendaries brutal.
		packList = packs("currency_common", 72, "pack_common", 18, "pack_rare", 6, "pack_legendary", 1, "currency_rare", 3)
	end
	local def = {
		id = prefix .. n,
		name = stamp.label .. " " .. ((sec and sec.name) or "Chest"),
		kind = "native",
		-- First 100 layers of Meadow: 3-6 clods' worth, so a chest moves the
		-- first purchases along instead of paying a single swing.
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
	MineZoneChests.DEFS[def.id] = def
	return def
end

function MineZoneChests.ageZone(zoneId)
	local pool = MineZoneChests.POOLS[zoneId]
	if not pool then
		return
	end
	pool = MineChestRanks.agePool(pool)
	local q = MineZoneChests.S_QUEUE[zoneId]
	if q and #q > 0 then
		local nextId = table.remove(q, 1)
		if MineZoneChests.DEFS[nextId] then
			table.insert(pool, { chestId = nextId, rank = "S" })
		end
	end
	MineZoneChests.POOLS[zoneId] = pool
end

function MineZoneChests.onPermanentZoneUnlocked(unlockedZoneId)
	if unlockedZoneId == MineZonePacks.LIMITED_ZONE then
		return
	end
	local order = MineZonePacks.ZONE_ORDER
	local unlockedIndex = nil
	for i, id in ipairs(order) do
		if id == unlockedZoneId then
			unlockedIndex = i
			break
		end
	end
	if not unlockedIndex or unlockedIndex <= 1 then
		return
	end
	for i = 1, unlockedIndex - 1 do
		MineZoneChests.ageZone(order[i])
	end
end

function MineZoneChests.rollSpawn(zoneId, layer, zoneIndex)
	local rng = Random.new()
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	zoneIndex = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	local chestDef
	-- Almost half the wall is the wider chest catalog (every mine-1 chest
	-- whose depth band covers this layer). The rest is this planet's pool
	-- plus the section chest. Lookingglass never comes from that catalog.
	local okP, Packs = pcall(function()
		return require(script.Parent:WaitForChild("MinePackConfig"))
	end)
	if okP and Packs and Packs.rollChestAt then
		-- Zone 1 top layers: other (catalog) chests only very rarely.
		-- Deeper / other planets keep a wider mix.
		local mix = 0.45
		if zoneIndex <= 1 then
			mix = (layer <= 120) and 0.025 or 0.12
		end
		if rng:NextNumber() < mix then
			chestDef = Packs.rollChestAt(1, layer, rng, 1)
			if chestDef and chestDef.id == "m1_lookingglass" then
				chestDef = nil
			end
		end
	end
	if not chestDef then
		local pick = MineZoneChests.roll(zoneId, rng, { luck = 1, layer = layer })
		chestDef = pick and pick.def or nil
	end
	local chance = 0
	if zoneIndex <= 1 then
		if layer >= 2500 then
			chance = 1 / 8000
		end
	else
		local t = math.clamp((zoneIndex - 1) / 9, 0, 1)
		chance = (1 / 2500) * (1 - t) + 0.008 * t
	end
	if chance > 0 and rng:NextNumber() < chance then
		local shiny = MineZoneChests.DEFS.shiny_chest
		if shiny then
			shiny.kind = "chase"
			chestDef = shiny
		end
	end
	return chestDef
end

function MineZoneChests.roll(zoneId, rng, opts)
	opts = opts or {}
	local pool = MineZoneChests.POOLS[zoneId]
	-- Meadow (and EH) keep vanity pool chests at EVERY depth (a/b/c),
	-- and also weight in the section-native exclusive for this layer.
	local rollPool = pool
	if opts.layer then
		local def = MineZoneChests.exclusiveFor(zoneId, opts.layer)
		if def then
			rollPool = {}
			for _, row in ipairs(pool or {}) do
				table.insert(rollPool, row)
			end
			-- Section native is common filler alongside meadow vanity C chests.
			table.insert(rollPool, { chestId = def.id, rank = "C", def = def })
		end
	end
	local pick = MineChestRanks.roll(rollPool, rng, opts)
	if not pick then
		return nil
	end
	local chestDef = pick.def or MineZoneChests.DEFS[pick.chestId]
	if not chestDef then
		return nil
	end
	return {
		chestId = pick.chestId,
		rank = pick.rank,
		def = chestDef,
	}
end

function MineZoneChests.rollPackDrops(zoneId, chestDef, rng)
	rng = rng or Random.new()
	local out = {}
	for _, entry in ipairs(chestDef.packs or {}) do
		if rng:NextNumber() * 100 <= (entry.chance or 0) then
			table.insert(out, MineZonePacks.id(zoneId, entry.slot))
		end
	end
	return out
end

-- Fixed gem/coin roll from def ranges only (no zone/layer scaling).
function MineZoneChests.rollCurrency(chestDef, rng)
	rng = rng or Random.new()
	local function band(pair)
		local lo = math.floor(tonumber(pair and pair[1]) or 0)
		local hi = math.floor(tonumber(pair and pair[2]) or lo)
		if hi < lo then
			hi = lo
		end
		if hi <= lo then
			return math.max(0, lo)
		end
		return rng:NextInteger(lo, hi)
	end
	local coins = band(chestDef.coins)
	local gems = band(chestDef.gems)
	if (chestDef.exclusive or chestDef.eh) and coins < 1 then
		coins = 1
	end
	return coins, gems
end

-- Collection rows: every def with zones/ranks it currently sits in.
function MineZoneChests.collectionRows()
	local byId = {}
	for zoneId, pool in pairs(MineZoneChests.POOLS) do
		if zoneId ~= "bigbang" then
			for _, row in ipairs(pool) do
				local d = MineZoneChests.DEFS[row.chestId]
				if d then
					local entry = byId[row.chestId]
					if not entry then
						entry = {
							id = d.id,
							name = d.name,
							coins = d.coins,
							gems = d.gems,
							packs = d.packs,
							sectionN = d.sectionN,
							zones = {},
						}
						byId[row.chestId] = entry
					end
					table.insert(entry.zones, { zoneId = zoneId, rank = row.rank })
				end
			end
		end
	end
	local C = require(script.Parent:WaitForChild("MineConfig"))
	for _, sec in ipairs(C.SECTIONS or {}) do
		local layer = sec.layers and sec.layers[1] or 1
		local d = MineZoneChests.exclusiveFor("meadow", layer)
		if d and not byId[d.id] then
			byId[d.id] = {
				id = d.id,
				name = d.name,
				coins = d.coins,
				gems = d.gems,
				packs = d.packs,
				sectionN = d.sectionN,
				zones = { { zoneId = "meadow", rank = "native" } },
			}
		end
	end
	for _, layer in ipairs({ 1, 26 }) do
		local d = MineZoneChests.exclusiveFor("bigbang", layer)
		if d and not byId[d.id] then
			byId[d.id] = {
				id = d.id,
				name = d.name,
				coins = d.coins,
				gems = d.gems,
				packs = d.packs,
				sectionN = d.sectionN,
				zones = { { zoneId = "bigbang", rank = "native" } },
			}
		end
	end
	local list = {}
	for _, row in pairs(byId) do
		table.insert(list, row)
	end
	table.sort(list, function(a, b)
		local na, nb = tonumber(a.sectionN) or 0, tonumber(b.sectionN) or 0
		if na ~= nb and (na > 0 or nb > 0) then
			if na == 0 then
				return false
			end
			if nb == 0 then
				return true
			end
			return na < nb
		end
		return a.name < b.name
	end)
	return list
end

return MineZoneChests
