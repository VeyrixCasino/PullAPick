--[[
	MineFishing -- fishing's rules and data (TODO A3). Pure: no services, no
	profile writes, so the server, the client and tools/verify/fishing.js all
	read the same numbers. The fight itself is MineFishingFight; the verbs are
	ServerScriptService/Mine/MineFishingService.

	THE OWNER'S CALLS (2026-10-10/11; wiki systems/fishing):
	  * The first spot is in ZONE 2 (Greyvein Quarry, id sunscar), on the
	    surface. Every zone gets "a couple underground fishing areas ... (at
	    outposts)": the station bays of the 1,000 and 3,000 outposts, deeper
	    ones luckier. Each zone has its own fish.
	  * RODS cost coins. Upgrading one "gets retarded expensive super fast"
	    (x1.6 a level, 50 levels), and "every 10 levels you have to prestige
	    with tokens, to unlock the next 10 levels" -- tokens are TEMPER tokens
	    (owner: "IF I EVER SAY TOKENS I MEAN TEMPER TOKENS"). Rod levels stay
	    through rebirth. Four rods; the top one casts 5 bait at once: ONE fight
	    against the best fish, win all five or lose all five, and the catch is
	    shown worst to best.
	  * BAIT is not bought with coins: it is AFK'd for (1 per 8 minutes
	    online), paid by daily quests (+2 each) or bought with tokens (10
	    each), and all of it counts toward 15 a day.
	  * CAST then REEL, both minigames: a good or perfect cast is a luck bonus;
	    the reel is MineFishingFight. No skipping.
	  * A catch is a FISH CARD in your COOLER, the fish inventory, opened at
	    any fishing spot. Selling pays coins (PROPOSED grade x size formula);
	    trading waits. Catch of the day is one global target fish per UTC day.
	  * ALBUM = cooler known fish (row kept after sell at n=0). One set per
	    zone (12 fish). Completing a zone's album grants PROPOSED permanent
	    fishing luck at that zone's spots (see albumLuck). Trading waits.
	  * "make rare fish actually rare": a 5-star fish is 1 in 2,000 casts
	    before luck.
]]
local M = {}

-- Stable zone order for catch-of-day seeding (matches MineZonePets / ladders).
M.ZONE_ORDER = {
	"meadow", "sunscar", "mistreef", "arcwork", "bloodmoon",
	"eclipse", "riftmarch", "starfall", "mythral", "primordium",
}

-- ------------------------------------------------------------ grades --

-- Stars, 1 to 5 in half steps (TODO §0: every grade in stars, nine of them).
M.GRADES = { 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5 }
M.GRADE_TEXT = { "★", "★½", "★★", "★★½", "★★★", "★★★½", "★★★★", "★★★★½", "★★★★★" }
M.GRADE_COLOR = {
	Color3.fromRGB(176, 178, 186), -- 1
	Color3.fromRGB(150, 205, 160), -- 1.5
	Color3.fromRGB(96, 214, 120), -- 2
	Color3.fromRGB(70, 200, 210), -- 2.5
	Color3.fromRGB(84, 150, 255), -- 3
	Color3.fromRGB(170, 110, 255), -- 3.5
	Color3.fromRGB(255, 164, 60), -- 4
	Color3.fromRGB(255, 110, 190), -- 4.5
	Color3.fromRGB(255, 70, 70), -- 5
}

--[[
	How often each grade bites, before luck: weights, out of 9,995. A 5-star
	fish is 1 in 2,000 casts; 4.5 is 1 in 333; 4 is 1 in 111. Luck lifts a
	grade by luck ^ ((grade - 1) / 8): a 5-star by the whole of it, a 1-star
	not at all, so luck never makes the common fish rarer by more than the
	renormalising.
]]
M.GRADE_WEIGHT = { 4500, 2500, 1400, 800, 450, 220, 90, 30, 5 }

--[[
	How hard each grade fights: MineFishingFight.fishFromDifficulty's number.
	TUNED, not guessed (owner: "test with a little shitty learning machine, and
	figure out whats the brink of possibility, and tone down from there").
	tools/sim/fishing-tune.js trains a bot and finds the BRINK -- the hardest
	fish a perfect-reflex bot lands half the time -- then the 5-star sits a
	notch under it and the rest step down. Its last report is in
	docs/FISHING-TUNING.md; rerun it after touching the fight.
]]
M.DIFFICULTY = { 0.150, 0.192, 0.246, 0.314, 0.402, 0.514, 0.658, 0.842, 1.077 }

--[[
	Later zones' fish fight harder; the zone's rods are levelled to match.
	PROPOSED: 1.05 ^ (zoneIndex - 2), so Greyvein (zone 2) stays 1 and meadow
	is a touch easier. Event Horizon (bigbang) has no fish list yet.
]]
M.ZONE_DIFFICULTY = {
	meadow = 0.95,
	sunscar = 1,
	mistreef = 1.05,
	arcwork = 1.10,
	bloodmoon = 1.16,
	eclipse = 1.22,
	riftmarch = 1.28,
	starfall = 1.34,
	mythral = 1.41,
	primordium = 1.48,
}

-- ------------------------------------------------------------- fish --

--[[
	Each zone's own fish (owner: "Make each zone have different fish").
	`grade` indexes GRADES; `kg` is the size range, most catches near the low
	end. Ids are save data: the cooler is keyed by them.

	Shape mirrors Greyvein: 12 fish, grades 1,1,2,2,3,3,4,5,6,7,8,9 (★ through
	★★★★★ in half steps, two each of the three commonest). Names PROPOSED.
	Every permanent zone gets outpost spots at 1,000 / 3,000 once listed here;
	only Greyvein also has a surface pond.
]]
M.FISH = {
	-- Dirt Meadow (zone 1): grassy puddles and soft dirt seeps.
	meadow = {
		{ id = "puddle_minnow", name = "Puddle Minnow", grade = 1, kg = { 0.05, 0.2 } },
		{ id = "sod_guppy", name = "Sod Guppy", grade = 1, kg = { 0.03, 0.15 } },
		{ id = "clover_perch", name = "Clover Perch", grade = 2, kg = { 0.2, 0.8 } },
		{ id = "worm_loach", name = "Worm Loach", grade = 2, kg = { 0.1, 0.5 } },
		{ id = "meadow_bass", name = "Meadow Bass", grade = 3, kg = { 0.6, 2.5 } },
		{ id = "daisy_trout", name = "Daisy Trout", grade = 3, kg = { 0.5, 2.2 } },
		{ id = "root_pike", name = "Root Pike", grade = 4, kg = { 1.5, 6 } },
		{ id = "burrow_catfish", name = "Burrow Catfish", grade = 5, kg = { 2, 12 } },
		{ id = "haystack_carp", name = "Haystack Carp", grade = 6, kg = { 3, 15 } },
		{ id = "dirtvein_eel", name = "Dirtvein Eel", grade = 7, kg = { 4, 20 } },
		{ id = "giant_toadfish", name = "Giant Toadfish", grade = 8, kg = { 20, 90 } },
		{ id = "sunny_koi", name = "Sunny Koi", grade = 9, kg = { 40, 160 } },
	},
	-- Greyvein Quarry (zone 2 / sunscar): stone and grit.
	sunscar = {
		{ id = "gravel_minnow", name = "Gravel Minnow", grade = 1, kg = { 0.05, 0.2 } },
		{ id = "slate_guppy", name = "Slate Guppy", grade = 1, kg = { 0.03, 0.15 } },
		{ id = "grit_perch", name = "Grit Perch", grade = 2, kg = { 0.2, 0.8 } },
		{ id = "pebble_loach", name = "Pebble Loach", grade = 2, kg = { 0.1, 0.5 } },
		{ id = "quarry_bass", name = "Quarry Bass", grade = 3, kg = { 0.6, 2.5 } },
		{ id = "flint_trout", name = "Flint Trout", grade = 3, kg = { 0.5, 2.2 } },
		{ id = "shale_pike", name = "Shale Pike", grade = 4, kg = { 1.5, 6 } },
		{ id = "chisel_catfish", name = "Chisel Catfish", grade = 5, kg = { 2, 12 } },
		{ id = "granite_carp", name = "Granite Carp", grade = 6, kg = { 3, 15 } },
		{ id = "greyvein_eel", name = "Greyvein Eel", grade = 7, kg = { 4, 20 } },
		{ id = "bedrock_sturgeon", name = "Bedrock Sturgeon", grade = 8, kg = { 20, 90 } },
		{ id = "monolith_koi", name = "Monolith Koi", grade = 9, kg = { 40, 160 } },
	},
	-- Mistreef Depths: fog, moss and canopy drip.
	mistreef = {
		{ id = "fog_minnow", name = "Fog Minnow", grade = 1, kg = { 0.05, 0.2 } },
		{ id = "moss_guppy", name = "Moss Guppy", grade = 1, kg = { 0.03, 0.15 } },
		{ id = "fern_perch", name = "Fern Perch", grade = 2, kg = { 0.2, 0.8 } },
		{ id = "dew_loach", name = "Dew Loach", grade = 2, kg = { 0.1, 0.5 } },
		{ id = "mist_bass", name = "Mist Bass", grade = 3, kg = { 0.6, 2.5 } },
		{ id = "canopy_trout", name = "Canopy Trout", grade = 3, kg = { 0.5, 2.2 } },
		{ id = "vine_pike", name = "Vine Pike", grade = 4, kg = { 1.5, 6 } },
		{ id = "spore_catfish", name = "Spore Catfish", grade = 5, kg = { 2, 12 } },
		{ id = "grove_carp", name = "Grove Carp", grade = 6, kg = { 3, 15 } },
		{ id = "mistveil_eel", name = "Mistveil Eel", grade = 7, kg = { 4, 20 } },
		{ id = "ancient_root_sturgeon", name = "Ancient Root Sturgeon", grade = 8, kg = { 20, 90 } },
		{ id = "ghostleaf_koi", name = "Ghostleaf Koi", grade = 9, kg = { 40, 160 } },
	},
	-- Arcwork Veins: copper, cogs and soft sparks.
	arcwork = {
		{ id = "spark_minnow", name = "Spark Minnow", grade = 1, kg = { 0.05, 0.2 } },
		{ id = "copper_guppy", name = "Copper Guppy", grade = 1, kg = { 0.03, 0.15 } },
		{ id = "cog_perch", name = "Cog Perch", grade = 2, kg = { 0.2, 0.8 } },
		{ id = "wire_loach", name = "Wire Loach", grade = 2, kg = { 0.1, 0.5 } },
		{ id = "arc_bass", name = "Arc Bass", grade = 3, kg = { 0.6, 2.5 } },
		{ id = "bronze_trout", name = "Bronze Trout", grade = 3, kg = { 0.5, 2.2 } },
		{ id = "gear_pike", name = "Gear Pike", grade = 4, kg = { 1.5, 6 } },
		{ id = "flux_catfish", name = "Flux Catfish", grade = 5, kg = { 2, 12 } },
		{ id = "dynamo_carp", name = "Dynamo Carp", grade = 6, kg = { 3, 15 } },
		{ id = "voltcoil_eel", name = "Voltcoil Eel", grade = 7, kg = { 4, 20 } },
		{ id = "forge_sturgeon", name = "Forge Sturgeon", grade = 8, kg = { 20, 90 } },
		{ id = "clockwork_koi", name = "Clockwork Koi", grade = 9, kg = { 40, 160 } },
	},
	-- Bloodmoon Hollow: soft crimson night (kid-friendly spooky).
	bloodmoon = {
		{ id = "ember_minnow", name = "Ember Minnow", grade = 1, kg = { 0.05, 0.2 } },
		{ id = "ruby_guppy", name = "Ruby Guppy", grade = 1, kg = { 0.03, 0.15 } },
		{ id = "hollow_perch", name = "Hollow Perch", grade = 2, kg = { 0.2, 0.8 } },
		{ id = "dusk_loach", name = "Dusk Loach", grade = 2, kg = { 0.1, 0.5 } },
		{ id = "crimson_bass", name = "Crimson Bass", grade = 3, kg = { 0.6, 2.5 } },
		{ id = "moonlit_trout", name = "Moonlit Trout", grade = 3, kg = { 0.5, 2.2 } },
		{ id = "scarlet_pike", name = "Scarlet Pike", grade = 4, kg = { 1.5, 6 } },
		{ id = "lantern_catfish", name = "Lantern Catfish", grade = 5, kg = { 2, 12 } },
		{ id = "bloodmoon_carp", name = "Bloodmoon Carp", grade = 6, kg = { 3, 15 } },
		{ id = "nightglow_eel", name = "Nightglow Eel", grade = 7, kg = { 4, 20 } },
		{ id = "hollow_sturgeon", name = "Hollow Sturgeon", grade = 8, kg = { 20, 90 } },
		{ id = "harvest_koi", name = "Harvest Koi", grade = 9, kg = { 40, 160 } },
	},
	-- Eclipse Core: shade, halo and night sky.
	eclipse = {
		{ id = "shade_minnow", name = "Shade Minnow", grade = 1, kg = { 0.05, 0.2 } },
		{ id = "umbra_guppy", name = "Umbra Guppy", grade = 1, kg = { 0.03, 0.15 } },
		{ id = "night_perch", name = "Night Perch", grade = 2, kg = { 0.2, 0.8 } },
		{ id = "halo_loach", name = "Halo Loach", grade = 2, kg = { 0.1, 0.5 } },
		{ id = "eclipse_bass", name = "Eclipse Bass", grade = 3, kg = { 0.6, 2.5 } },
		{ id = "corona_trout", name = "Corona Trout", grade = 3, kg = { 0.5, 2.2 } },
		{ id = "shadow_pike", name = "Shadow Pike", grade = 4, kg = { 1.5, 6 } },
		{ id = "voidfin_catfish", name = "Voidfin Catfish", grade = 5, kg = { 2, 12 } },
		{ id = "penumbra_carp", name = "Penumbra Carp", grade = 6, kg = { 3, 15 } },
		{ id = "darkring_eel", name = "Darkring Eel", grade = 7, kg = { 4, 20 } },
		{ id = "totality_sturgeon", name = "Totality Sturgeon", grade = 8, kg = { 20, 90 } },
		{ id = "solarveil_koi", name = "Solarveil Koi", grade = 9, kg = { 40, 160 } },
	},
	-- Riftmarch Scarps: cracks, cliffs and windy rifts.
	riftmarch = {
		{ id = "crack_minnow", name = "Crack Minnow", grade = 1, kg = { 0.05, 0.2 } },
		{ id = "cliff_guppy", name = "Cliff Guppy", grade = 1, kg = { 0.03, 0.15 } },
		{ id = "scarp_perch", name = "Scarp Perch", grade = 2, kg = { 0.2, 0.8 } },
		{ id = "fault_loach", name = "Fault Loach", grade = 2, kg = { 0.1, 0.5 } },
		{ id = "rift_bass", name = "Rift Bass", grade = 3, kg = { 0.6, 2.5 } },
		{ id = "march_trout", name = "March Trout", grade = 3, kg = { 0.5, 2.2 } },
		{ id = "crevasse_pike", name = "Crevasse Pike", grade = 4, kg = { 1.5, 6 } },
		{ id = "shatter_catfish", name = "Shatter Catfish", grade = 5, kg = { 2, 12 } },
		{ id = "ridge_carp", name = "Ridge Carp", grade = 6, kg = { 3, 15 } },
		{ id = "riftwind_eel", name = "Riftwind Eel", grade = 7, kg = { 4, 20 } },
		{ id = "chasm_sturgeon", name = "Chasm Sturgeon", grade = 8, kg = { 20, 90 } },
		{ id = "scarline_koi", name = "Scarline Koi", grade = 9, kg = { 40, 160 } },
	},
	-- Starfall Barrens: glitter, comets and night dust.
	starfall = {
		{ id = "twinkle_minnow", name = "Twinkle Minnow", grade = 1, kg = { 0.05, 0.2 } },
		{ id = "comet_guppy", name = "Comet Guppy", grade = 1, kg = { 0.03, 0.15 } },
		{ id = "stardust_perch", name = "Stardust Perch", grade = 2, kg = { 0.2, 0.8 } },
		{ id = "meteor_loach", name = "Meteor Loach", grade = 2, kg = { 0.1, 0.5 } },
		{ id = "starfall_bass", name = "Starfall Bass", grade = 3, kg = { 0.6, 2.5 } },
		{ id = "nebula_trout", name = "Nebula Trout", grade = 3, kg = { 0.5, 2.2 } },
		{ id = "orbit_pike", name = "Orbit Pike", grade = 4, kg = { 1.5, 6 } },
		{ id = "nova_catfish", name = "Nova Catfish", grade = 5, kg = { 2, 12 } },
		{ id = "galaxy_carp", name = "Galaxy Carp", grade = 6, kg = { 3, 15 } },
		{ id = "skystream_eel", name = "Skystream Eel", grade = 7, kg = { 4, 20 } },
		{ id = "asteroid_sturgeon", name = "Asteroid Sturgeon", grade = 8, kg = { 20, 90 } },
		{ id = "constellation_koi", name = "Constellation Koi", grade = 9, kg = { 40, 160 } },
	},
	-- Mythral Catacombs: crystal vaults and quiet relics.
	mythral = {
		{ id = "crystal_minnow", name = "Crystal Minnow", grade = 1, kg = { 0.05, 0.2 } },
		{ id = "shard_guppy", name = "Shard Guppy", grade = 1, kg = { 0.03, 0.15 } },
		{ id = "vault_perch", name = "Vault Perch", grade = 2, kg = { 0.2, 0.8 } },
		{ id = "rune_loach", name = "Rune Loach", grade = 2, kg = { 0.1, 0.5 } },
		{ id = "mythral_bass", name = "Mythral Bass", grade = 3, kg = { 0.6, 2.5 } },
		{ id = "catacomb_trout", name = "Catacomb Trout", grade = 3, kg = { 0.5, 2.2 } },
		{ id = "relic_pike", name = "Relic Pike", grade = 4, kg = { 1.5, 6 } },
		{ id = "gleam_catfish", name = "Gleam Catfish", grade = 5, kg = { 2, 12 } },
		{ id = "spire_carp", name = "Spire Carp", grade = 6, kg = { 3, 15 } },
		{ id = "mythvein_eel", name = "Mythvein Eel", grade = 7, kg = { 4, 20 } },
		{ id = "tomb_sturgeon", name = "Tomb Sturgeon", grade = 8, kg = { 20, 90 } },
		{ id = "crownlight_koi", name = "Crownlight Koi", grade = 9, kg = { 40, 160 } },
	},
	-- Primordium Heart: warm origin waters.
	primordium = {
		{ id = "emberdust_minnow", name = "Emberdust Minnow", grade = 1, kg = { 0.05, 0.2 } },
		{ id = "primordial_guppy", name = "Primordial Guppy", grade = 1, kg = { 0.03, 0.15 } },
		{ id = "magma_perch", name = "Magma Perch", grade = 2, kg = { 0.2, 0.8 } },
		{ id = "core_loach", name = "Core Loach", grade = 2, kg = { 0.1, 0.5 } },
		{ id = "heartfire_bass", name = "Heartfire Bass", grade = 3, kg = { 0.6, 2.5 } },
		{ id = "origin_trout", name = "Origin Trout", grade = 3, kg = { 0.5, 2.2 } },
		{ id = "lava_pike", name = "Lava Pike", grade = 4, kg = { 1.5, 6 } },
		{ id = "ashen_catfish", name = "Ashen Catfish", grade = 5, kg = { 2, 12 } },
		{ id = "crucible_carp", name = "Crucible Carp", grade = 6, kg = { 3, 15 } },
		{ id = "primordium_eel", name = "Primordium Eel", grade = 7, kg = { 4, 20 } },
		{ id = "worldheart_sturgeon", name = "Worldheart Sturgeon", grade = 8, kg = { 20, 90 } },
		{ id = "firstflame_koi", name = "Firstflame Koi", grade = 9, kg = { 40, 160 } },
	},
}

M.FISH_BY_ID = {}
for zoneId, list in pairs(M.FISH) do
	for _, f in ipairs(list) do
		f.zoneId = zoneId
		M.FISH_BY_ID[f.id] = f
	end
end

function M.fish(id)
	return M.FISH_BY_ID[id]
end

-- ------------------------------------------------------------ spots --

--[[
	Where you can fish. The surface pond is built by WorldBuilder; the
	underground ones sit in the station bay of their seam's outpost
	(MineDepthPlazas). `luck` multiplies the catch luck: deeper is better.
]]
M.OUTPOST_SEAMS = { 1000, 3000 }
M.OUTPOST_LUCK = { [1000] = 1.25, [3000] = 1.6 }
M.SPOT_RADIUS = 40 -- studs from the spot's dock the server accepts a cast

M.SPOTS = {}
M.SPOT_BY_ID = {}
local function addSpot(spot)
	table.insert(M.SPOTS, spot)
	M.SPOT_BY_ID[spot.id] = spot
end
addSpot({ id = "sunscar_pond", zoneId = "sunscar", kind = "surface", name = "Quarry Pool", luck = 1 })
for zoneId in pairs(M.FISH) do
	for _, seam in ipairs(M.OUTPOST_SEAMS) do
		addSpot({
			id = zoneId .. "_" .. seam,
			zoneId = zoneId,
			kind = "outpost",
			seam = seam,
			name = (seam == 1000) and "Seep Pool" or "Deep Sump",
			luck = M.OUTPOST_LUCK[seam] or 1,
		})
	end
end

function M.spot(id)
	return M.SPOT_BY_ID[id]
end

-- ------------------------------------------------------------- rods --

--[[
	Four rods, bought with coins. `reel` is metres a second on a green fish,
	`line` divides the tension a reel adds, `luck` multiplies the catch luck,
	`bait` is how many bait one cast spends (and how many fish bite).

	Levels: each adds to the rod's own numbers (LEVEL_GAIN, of its base), and
	costs levelBase x LEVEL_COST_GROW ^ level coins. Every PRESTIGE_EVERY
	levels the rod stops until you pay PRESTIGE_TOKENS temper tokens.
	PROPOSED prices (owner chose the shape: 4 rods, 50 levels, x1.6).
]]
M.RODS = {
	{ id = "twig_rod", name = "Twig Rod", price = 0, bait = 1, reel = 6, line = 1, luck = 1, levelBase = 400,
		blurb = "Everyone's first rod. Free." },
	{ id = "quarry_rod", name = "Quarry Rod", price = 60000, bait = 1, reel = 7.2, line = 1.25, luck = 1.12,
		levelBase = 6000, blurb = "Stiffer line, faster reel." },
	{ id = "deepline_rod", name = "Deepline Rod", price = 4000000, bait = 1, reel = 8.4, line = 1.55, luck = 1.25,
		levelBase = 300000, blurb = "Built for the long fights." },
	{ id = "trawler_rod", name = "Trawler Rod", price = 300000000, bait = 5, reel = 9, line = 1.8, luck = 1.35,
		levelBase = 20000000, blurb = "Casts 5 bait at once. One fight for all five: land it or lose them all." },
}
M.ROD_BY_ID = {}
for i, r in ipairs(M.RODS) do
	r.index = i
	M.ROD_BY_ID[r.id] = r
end
M.STARTER_ROD = "twig_rod"

M.LEVEL_MAX = 50
M.LEVEL_COST_GROW = 1.6
M.LEVEL_GAIN = { reel = 0.02, line = 0.025, luck = 0.015 }
M.PRESTIGE_EVERY = 10
M.PRESTIGE_TOKENS = { 100, 300, 1000, 3000 }

function M.rod(id)
	return M.ROD_BY_ID[id]
end

-- A rod's numbers at a level.
function M.rodStats(id, level)
	local r = M.ROD_BY_ID[id] or M.ROD_BY_ID[M.STARTER_ROD]
	level = math.clamp(math.floor(tonumber(level) or 0), 0, M.LEVEL_MAX)
	return {
		reel = r.reel * (1 + M.LEVEL_GAIN.reel * level),
		line = r.line * (1 + M.LEVEL_GAIN.line * level),
		luck = r.luck * (1 + M.LEVEL_GAIN.luck * level),
		bait = r.bait,
	}
end

-- Coins to go from `level` to level + 1.
function M.levelCost(id, level)
	local r = M.ROD_BY_ID[id]
	if not r then
		return math.huge
	end
	return math.floor(r.levelBase * M.LEVEL_COST_GROW ^ math.max(0, level) + 0.5)
end

-- The highest level a rod can reach with `gates` prestiges paid.
function M.levelCap(gates)
	return math.min(M.LEVEL_MAX, M.PRESTIGE_EVERY * (math.max(0, math.floor(tonumber(gates) or 0)) + 1))
end

-- Tokens for the next prestige, or nil when there is none left.
function M.prestigeCost(gates)
	return M.PRESTIGE_TOKENS[math.max(0, math.floor(tonumber(gates) or 0)) + 1]
end

-- ------------------------------------------------------------- bait --

M.BAIT_DAY_CAP = 15
M.AFK_SECS_PER_BAIT = 8 * 60
M.QUEST_BAIT = 2
M.TOKEN_PRICE = 10 -- temper tokens a bait

-- How many more bait can be gained today.
function M.baitRoom(gotToday)
	return math.max(0, M.BAIT_DAY_CAP - math.floor(tonumber(gotToday) or 0))
end

-- ------------------------------------------------------------- cast --

--[[
	THE CAST. A power bar sweeps up and down (PERIOD seconds for the round
	trip); stop it on the sweet spot. Owner: "we will have a good and perfect
	cast luck bonus". The bar is a pure function of the tick, so the server
	works out the quality from the tick the client stopped on.
]]
M.CAST = {
	period = 1.6,
	sweet = 0.85,
	perfect = 0.035,
	good = 0.11,
	luck = { perfect = 1.5, good = 1.2, ok = 1 },
	maxTicks = 30 * 20, -- 20 seconds to make up your mind
}

-- Where the bar is (0..1) on `tick` (30 a second).
function M.castBar(tick)
	local hz = 30
	local phase = ((tonumber(tick) or 0) / (M.CAST.period * hz)) % 1
	return (phase < 0.5) and (phase * 2) or (2 - phase * 2)
end

function M.castQuality(tick)
	local off = math.abs(M.castBar(tick) - M.CAST.sweet)
	if off <= M.CAST.perfect then
		return "perfect"
	elseif off <= M.CAST.good then
		return "good"
	end
	return "ok"
end

-- Seconds between the cast landing and the bite.
M.BITE = { 1.2, 3.5 }

-- ------------------------------------------------------------ catch --

-- The catch table at a luck: { { fish, p } ... } in grade order, p sums to 1.
function M.catchOdds(zoneId, luck)
	local list = M.FISH[zoneId] or {}
	luck = math.max(1, tonumber(luck) or 1)
	local perGrade = {}
	for _, f in ipairs(list) do
		perGrade[f.grade] = (perGrade[f.grade] or 0) + 1
	end
	local rows, total = {}, 0
	for _, f in ipairs(list) do
		local w = (M.GRADE_WEIGHT[f.grade] or 0) / perGrade[f.grade] * luck ^ ((f.grade - 1) / 8)
		total += w
		table.insert(rows, { fish = f, p = w })
	end
	for _, r in ipairs(rows) do
		r.p = (total > 0) and (r.p / total) or 0
	end
	return rows
end

--[[
	One fish: { id, kg, size }. `size` is 0..1 within its kind and is what
	makes a big one fight harder (MineFishingFight.spiritOf). It is a uniform
	roll SQUARED, so most catches are small: half of them sit in the bottom
	quarter of the range.
]]
function M.rollFish(zoneId, luck, rng)
	rng = rng or Random.new()
	local u = rng:NextNumber()
	local pick
	for _, r in ipairs(M.catchOdds(zoneId, luck)) do
		u -= r.p
		pick = r.fish
		if u <= 0 then
			break
		end
	end
	if not pick then
		return nil
	end
	local lo, hi = pick.kg[1], pick.kg[2]
	local s = rng:NextNumber()
	local size = s * s
	local kg = lo + (hi - lo) * size
	return { id = pick.id, kg = math.floor(kg * 100 + 0.5) / 100, size = math.floor(size * 1000 + 0.5) / 1000 }
end

-- How hard a fish of this grade fights in this zone.
function M.difficulty(zoneId, grade)
	return (M.DIFFICULTY[grade] or M.DIFFICULTY[1]) * (M.ZONE_DIFFICULTY[zoneId] or 1)
end

-- Sort a catch worst to best (owner: "it goes from least to best").
function M.sortCatch(list)
	table.sort(list, function(a, b)
		local fa, fb = M.FISH_BY_ID[a.id], M.FISH_BY_ID[b.id]
		local ga, gb = fa and fa.grade or 0, fb and fb.grade or 0
		if ga ~= gb then
			return ga < gb
		end
		return (a.kg or 0) < (b.kg or 0)
	end)
	return list
end

-- -------------------------------------------------------------- sell --

--[[
	PROPOSED coin prices from the cooler. Coins only (not gems); no trading yet.
	Formula: BASE * GROW^(gradeIndex-1) * (0.55 + size). The cooler only keeps
	n and best kg, so sells use TYPICAL_SIZE (median of the squared size roll).
]]
M.SELL_BASE = 120
M.SELL_GROW = 2.8
M.SELL_TYPICAL_SIZE = 0.25

function M.sellCoins(fishId, size)
	local f = M.FISH_BY_ID[fishId]
	if not f then
		return 0
	end
	size = math.clamp(tonumber(size) or M.SELL_TYPICAL_SIZE, 0, 1)
	local g = math.max(1, math.floor(tonumber(f.grade) or 1))
	return math.max(1, math.floor(M.SELL_BASE * (M.SELL_GROW ^ (g - 1)) * (0.55 + size) + 0.5))
end

-- What SELL ALL would pay: { units, coins, kinds }.
function M.sellPlan(cooler)
	local units, coins, kinds = 0, 0, 0
	for id, row in pairs(type(cooler) == "table" and cooler or {}) do
		local n = math.max(0, math.floor(tonumber(row and row.n) or 0))
		if n > 0 and M.FISH_BY_ID[id] then
			kinds += 1
			units += n
			coins += M.sellCoins(id) * n
		end
	end
	return { units = units, coins = coins, kinds = kinds }
end

-- ------------------------------------------------------------- album --

--[[
	PROPOSED album set bonuses (first cut, 2026-10-13). Soft-cap later if needed.

	Album = cooler known: a cooler[fishId] row means ever caught (n may be 0
	after sell). One set per zone (12 fish). Bonuses apply only at that zone's
	spots; completing other zones does not stack onto this spot.

	  * 12/12 complete → ×(1 + ALBUM_COMPLETE_LUCK)  (= +5% PROPOSED)
	  * 3/12 milestone → ×(1 + ALBUM_MILESTONE_LUCK) (= +2% PROPOSED)
	  * Complete replaces the milestone (does not stack 2%+5%).

	Cast luck is rod × spot × album × cast quality. Apply albumLuck in the
	same place cast luck is computed (MineFishingService.fishCast / fullState).
]]
M.ALBUM_SIZE = 12
M.ALBUM_MILESTONE = 3 -- PROPOSED: partial set bonus threshold
M.ALBUM_MILESTONE_LUCK = 0.02 -- PROPOSED +2% at 3-of-12
M.ALBUM_COMPLETE_LUCK = 0.05 -- PROPOSED +5% at 12-of-12

function M.albumKnown(cooler, fishId)
	return type(cooler) == "table" and type(cooler[fishId]) == "table"
end

function M.albumKnownCount(cooler, zoneId)
	local n = 0
	for _, f in ipairs(M.FISH[zoneId] or {}) do
		if M.albumKnown(cooler, f.id) then
			n += 1
		end
	end
	return n
end

-- Multiplier for casts at spots in this zone (1 = no bonus).
function M.albumLuck(cooler, zoneId)
	local known = M.albumKnownCount(cooler, zoneId)
	if known >= M.ALBUM_SIZE then
		return 1 + M.ALBUM_COMPLETE_LUCK
	elseif known >= M.ALBUM_MILESTONE then
		return 1 + M.ALBUM_MILESTONE_LUCK
	end
	return 1
end

-- { zoneId, known, total, luck, complete, milestone } for cooler / FISH UI.
function M.albumProgress(cooler, zoneId)
	local list = M.FISH[zoneId] or {}
	local known = M.albumKnownCount(cooler, zoneId)
	local total = (#list > 0) and #list or M.ALBUM_SIZE
	local luck = M.albumLuck(cooler, zoneId)
	return {
		zoneId = zoneId,
		known = known,
		total = total,
		luck = luck,
		complete = known >= M.ALBUM_SIZE,
		milestone = known >= M.ALBUM_MILESTONE and known < M.ALBUM_SIZE,
	}
end

-- ---------------------------------------------------- catch of the day --

--[[
	One global target fish species per UTC day (floor(os.time()/86400)), seeded
	so every server and the client agree. Reward is coins only (PROPOSED).
]]
M.CATCH_OF_DAY_BASE = 2500

function M.utcDay(t)
	return math.floor((tonumber(t) or 0) / 86400)
end

function M.catchOfDay(day)
	day = math.floor(tonumber(day) or 0)
	local ids = {}
	for _, zoneId in ipairs(M.ZONE_ORDER) do
		for _, f in ipairs(M.FISH[zoneId] or {}) do
			table.insert(ids, f.id)
		end
	end
	if #ids == 0 then
		return nil
	end
	local s = (day * 1103515245 + 12345) % 2147483647
	if s < 0 then
		s = -s
	end
	return M.FISH_BY_ID[ids[(s % #ids) + 1]]
end

function M.catchOfDayReward(fishId)
	local f = M.FISH_BY_ID[fishId]
	local g = math.max(1, math.floor(tonumber(f and f.grade) or 1))
	return math.max(1, math.floor(M.CATCH_OF_DAY_BASE * (M.SELL_GROW ^ (g - 1)) * 0.5 + 0.5))
end

return M
