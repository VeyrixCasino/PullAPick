--[[
	MineSetChests -- three named chests for each of the 19 pack sets.

	Owner, 2026-10-19: "Each of the 19 pack sets gets 3 named chests of its own
	(a low, a mid and a high rank) paying that set's packs, where that set's pets
	live." Names are proposed for the owner to approve.

	WHERE A SET'S PETS LIVE. Nothing in the set data ties a set to a zone (the
	sets were "not tied to a zone", docs/PETS-AND-SETS.md). What it does say is
	how strong each set's pets are: set 1 at zone 1's level, each set 5% above
	the one before (MineSetPets.setMult), exactly as each zone's pot is 5% above
	the zone before. So a set lives where the game is at its power: Pebblebound
	in Dirt Meadow, then two sets a zone in the owner's order, the first from a
	zone's top and the second from layer 250 down. That keeps a strong set's
	packs out of the early zones. PROPOSED (2026-10-19).

	HOW THEY SPAWN (MineZoneChests.spawnTable). A block rolls its RANK first. When
	the rank is one a set chest has (low D, mid B, high S) and a set lives at that
	depth, SHARE of those chests are the set's instead of the zone's. The rank
	split is untouched, so the total chest rate and everything a rank pays (coins,
	gems, cases, skins, books) are untouched: only the zone's card packs become
	one of the set's packs.

	Ids are data (`<setkey>_chest_low|mid|high`): never rename one.
]]
local M = {}

-- PROPOSED (2026-10-19). The three ranks, and the chance a chest of that rank
-- is a set chest where a set lives (split between the sets living there).
M.TIERS = { "low", "mid", "high" }
M.RANK = { low = "D", mid = "B", high = "S" }
M.SHARE = 0.2

--[[
	PROPOSED (2026-10-19). The one set pack a set chest pays, by star grade
	(MineSetPacks: 1 = ★ .. 6 = ★★★★★), as { stars, weight }.

	A set pack is worth far more than the zone pack it replaces near a zone's
	top (zone packs get better with depth; set packs do not), so the stars are
	held down: with these, chests pay at most about a quarter more in cards
	than they did near a zone's top, and the same from layer 1,000 down
	(tools/verify/economy-gems.js prints it). A ★★★★-★★★★★ high chest would
	add about half again; that is a question for the owner.
]]
M.PACK_STARS = {
	low = { { 1, 100 } },
	mid = { { 3, 100 } },
	high = { { 4, 70 }, { 5, 30 } },
}

-- PROPOSED (2026-10-19): the 57 names, themed to each set; the homes (above).
M.SETS = {
	{ key = "pebblebound", zoneId = "meadow", from = 1,
		low = "Pebble Pouch", mid = "Geode Crate", high = "Earthheart Coffer" },
	{ key = "sugar_rush", zoneId = "sunscar", from = 1,
		low = "Gumdrop Tin", mid = "Lollipop Locker", high = "Candy Castle Chest" },
	{ key = "mosswood", zoneId = "sunscar", from = 250,
		low = "Mossy Stump Box", mid = "Fern Hollow Chest", high = "Heartwood Hoard" },
	{ key = "lost_and_found", zoneId = "mistreef", from = 1,
		low = "Lost Luggage", mid = "Map Maker's Trunk", high = "Forgotten Treasure Chest" },
	{ key = "starfront", zoneId = "mistreef", from = 250,
		low = "Supply Pod", mid = "Cargo Capsule", high = "Starship Vault" },
	{ key = "arcade_legends", zoneId = "arcwork", from = 1,
		low = "Token Tub", mid = "Prize Crane Box", high = "High Score Safe" },
	{ key = "crystal_hollow", zoneId = "arcwork", from = 250,
		low = "Quartz Crate", mid = "Amethyst Coffer", high = "Prismatic Geode Vault" },
	{ key = "shoguns_oath", zoneId = "bloodmoon", from = 1,
		low = "Bamboo Box", mid = "Lacquer Chest", high = "Gold-Leaf Treasury" },
	{ key = "royal_reserve", zoneId = "bloodmoon", from = 250,
		low = "Velvet Purse", mid = "Crown Jewel Case", high = "Sovereign's Vault" },
	{ key = "crimson_eclipse", zoneId = "eclipse", from = 1,
		low = "Red Moon Box", mid = "Midnight Reliquary", high = "Eclipse Crown Coffer" },
	{ key = "holo_havoc", zoneId = "eclipse", from = 250,
		low = "Foil Tin", mid = "Chrome Locker", high = "Hyperholo Vault" },
	{ key = "rainbow_road", zoneId = "riftmarch", from = 1,
		low = "Pastel Pail", mid = "Prism Trunk", high = "Celestial Rainbow Chest" },
	{ key = "infernal_reign", zoneId = "riftmarch", from = 250,
		low = "Cinder Crate", mid = "Obsidian Strongbox", high = "Magma Citadel Vault" },
	{ key = "atlantis_rising", zoneId = "starfall", from = 1,
		low = "Tidepool Clam", mid = "Coral Coffer", high = "Sunken City Vault" },
	{ key = "divine_relics", zoneId = "starfall", from = 250,
		low = "Idol Box", mid = "Sacred Ark", high = "Pantheon Reliquary" },
	{ key = "dragonfall", zoneId = "mythral", from = 1,
		low = "Hatchling Nest", mid = "Drakefire Coffer", high = "Great Wyrm Hoard" },
	{ key = "eternal_roots", zoneId = "mythral", from = 250,
		low = "Root Knot Box", mid = "Spring Hollow Chest", high = "World Root Vault" },
	{ key = "mythic_menagerie", zoneId = "primordium", from = 1,
		low = "Egg Basket", mid = "Beast Den Crate", high = "Titan's Nest" },
	{ key = "chaos_theory", zoneId = "primordium", from = 250,
		low = "Glitch Box", mid = "Paradox Cube", high = "Fractured Reality Vault" },
}

function M.chestId(setKey, tier)
	return tostring(setKey) .. "_chest_" .. tostring(tier)
end

M.BY_KEY = {}
M.BY_ID = {} -- chest id -> { set, tier, rank, name }
for _, set in ipairs(M.SETS) do
	M.BY_KEY[set.key] = set
	for _, tier in ipairs(M.TIERS) do
		local id = M.chestId(set.key, tier)
		M.BY_ID[id] = { set = set, setKey = set.key, tier = tier, rank = M.RANK[tier], name = set[tier], id = id }
	end
end

-- The sets living at (zone, layer), in the owner's order.
function M.livingAt(zoneId, layer)
	local out = {}
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	for _, set in ipairs(M.SETS) do
		if set.zoneId == zoneId and layer >= (set.from or 1) then
			table.insert(out, set)
		end
	end
	return out
end

-- The tier a rank's set chest is ("low"/"mid"/"high"), or nil.
function M.tierForRank(rank)
	for _, tier in ipairs(M.TIERS) do
		if M.RANK[tier] == rank then
			return tier
		end
	end
	return nil
end

-- The set pack ids a set chest of `tier` can pay, with weights.
function M.packOdds(setKey, tier)
	local rows, total = {}, 0
	for _, r in ipairs(M.PACK_STARS[tier] or {}) do
		total += r[2]
	end
	for _, r in ipairs(M.PACK_STARS[tier] or {}) do
		table.insert(rows, { packId = tostring(setKey) .. "_pack_" .. r[1], stars = r[1], p = (total > 0) and (r[2] / total) or 0 })
	end
	return rows
end

function M.rollPack(setKey, tier, rng)
	local rows = M.packOdds(setKey, tier)
	local u = (rng and rng:NextNumber()) or math.random()
	for _, r in ipairs(rows) do
		u -= r.p
		if u <= 0 then
			return r.packId
		end
	end
	return rows[#rows] and rows[#rows].packId or nil
end

return M
