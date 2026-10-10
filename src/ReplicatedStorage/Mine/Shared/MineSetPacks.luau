--[[
	MineSetPacks -- the 19 sets' packs and the pack cases.

	Owner, 2026-10-10 (docs/PETS-AND-SETS.md):
	  * each set has six packs, ★ to ★★★★★, named by the owner (MineSetPets);
	    "some packs are genuinely awesome, and other packs are mediocre at best";
	  * a set pack draws ONLY that set's pets ("make some packs draw certain cards");
	  * PACK CASES hold 3-5 packs of one known star grade, from any set, top grades
	    rarer; they drop from chests, sit on the wheel, and are sold for stardust
	    (inside the stardust shop) at about 60-70% RTP;
	  * zone packs carry no stars.

	EVERY NUMBER HERE IS PROPOSED until the owner approves it.

	Ids are data: a set pack is "<setkey>_pack_<1..6>", a case "case_<1..6>".

	A set pack is a card pack like any other (kind "cards": god packs, the pull
	odds and the pack inspector all read it). `setKey` is what tells openPack
	to draw from the set's own named pets. MinePackConfig registers every set
	pack in PACK_BY_ID, but not in PACKS, so nothing that walks the universal
	list starts selling them.
]]
local M = {}

local Sets = require(script.Parent:WaitForChild("MineSetPets"))

M.TIERS = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic" }

-- The six star grades, ★ .. ★★★★★ (the owner's columns).
M.STARS = { 1, 1.5, 2, 3, 4, 5 }

-- PROPOSED. Cards in one pack, by star grade.
M.CARDS = { 3, 3, 4, 4, 5, 5 }

-- PROPOSED. Rarity odds (%) of each card, by star grade. Every row sums to 100.
-- ★ is a Common bag with a long shot; ★★★★★ never shows a Common and pays a
-- real Mythic / Divine / Exotic chance.
M.ODDS = {
	{ Common = 72, Uncommon = 21, Rare = 5.5, Epic = 1.2, Legendary = 0.25, Mythic = 0.04, Divine = 0.008, Exotic = 0.002 },
	{ Common = 62, Uncommon = 26, Rare = 9, Epic = 2.3, Legendary = 0.55, Mythic = 0.12, Divine = 0.024, Exotic = 0.006 },
	{ Common = 50, Uncommon = 30, Rare = 14, Epic = 4.6, Legendary = 1.1, Mythic = 0.24, Divine = 0.05, Exotic = 0.01 },
	{ Common = 30, Uncommon = 32, Rare = 23, Epic = 10, Legendary = 3.8, Mythic = 0.9, Divine = 0.24, Exotic = 0.06 },
	{ Common = 12, Uncommon = 26, Rare = 30, Epic = 19, Legendary = 9, Mythic = 2.8, Divine = 0.9, Exotic = 0.3 },
	{ Common = 0, Uncommon = 12, Rare = 28, Epic = 28, Legendary = 18, Mythic = 8.5, Divine = 4, Exotic = 1.5 },
}

-- PROPOSED. How likely each set is to fill a case slot, by its grade (per set):
-- "any set, top grades rarer" (owner).
M.GRADE_WEIGHT = { F = 10, D = 9, C = 8, B = 6, A = 4, S = 2.5, SS = 1.2, SSS = 0.5 }

-- PROPOSED. Packs in one case: 3, 4 or 5.
M.CASE_SIZE = { { n = 3, weight = 50 }, { n = 4, weight = 35 }, { n = 5, weight = 15 } }

-- PROPOSED. Stardust shop price = expected stardust value of what is inside / RTP.
M.CASE_RTP = 0.65

M.STAR_TEXT = { "★", "★½", "★★", "★★★", "★★★★", "★★★★★" }

-- The rarity colour a star grade borrows on the reveal and the tiles.
M.STAR_TIER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

--[[
	PROPOSED. A chest's chance to also drop a pack case, by the chest's rank
	(MineZoneChests: F..S; meadow and Event Horizon chests are "native"), and
	the star grade of that case. Better chests drop cases more often and of
	higher stars; a five-star case stays rare everywhere.
]]
M.CHEST_CASE_CHANCE = { F = 0.005, D = 0.01, C = 0.02, native = 0.02, B = 0.035, A = 0.06, S = 0.10 }
M.CHEST_CASE_STARS = {
	F = { 45, 28, 17, 7, 2.5, 0.5 },
	D = { 45, 28, 17, 7, 2.5, 0.5 },
	C = { 40, 27, 18, 10, 4, 1 },
	native = { 40, 27, 18, 10, 4, 1 },
	B = { 32, 26, 20, 13, 7, 2 },
	A = { 24, 22, 22, 17, 11, 4 },
	S = { 15, 18, 22, 22, 16, 7 },
}

function M.packId(setKey, n)
	return setKey .. "_pack_" .. n
end

function M.caseId(n)
	return "case_" .. n
end

--[[
	Pack definitions, built from the sets, in the shape MinePackConfig.PACK_BY_ID
	rows use (id, name, cards, odds, stars) plus `setKey`, which is what tells
	openPack to draw from the set's own pets.
]]
M.PACKS = {}
M.PACK_BY_ID = {}
for _, set in ipairs(Sets.SETS) do
	for n = 1, 6 do
		local def = {
			id = M.packId(set.KEY, n),
			name = (set.PACKS and set.PACKS[n]) or (set.NAME .. " " .. M.STAR_TEXT[n]),
			kind = "cards",
			setPack = true,
			setKey = set.KEY,
			setName = set.NAME,
			grade = set.GRADE,
			starLevel = n,
			stars = M.STARS[n],
			cards = M.CARDS[n],
			odds = M.ODDS[n],
		}
		table.insert(M.PACKS, def)
		M.PACK_BY_ID[def.id] = def
	end
end

M.CASES = {}
M.CASE_BY_ID = {}
for n = 1, 6 do
	local def = {
		id = M.caseId(n),
		name = M.STAR_TEXT[n] .. " Pack Case",
		kind = "set_case",
		starLevel = n,
		stars = M.STARS[n],
		blurb = "3-5 random " .. M.STAR_TEXT[n] .. " packs from any set",
	}
	table.insert(M.CASES, def)
	M.CASE_BY_ID[def.id] = def
end

local function weighted(rows, rng, weightOf)
	local total = 0
	for _, row in ipairs(rows) do
		total += math.max(0, weightOf(row))
	end
	if total <= 0 then
		return rows[1]
	end
	local roll = (rng and rng:NextNumber() or math.random()) * total
	for _, row in ipairs(rows) do
		roll -= math.max(0, weightOf(row))
		if roll <= 0 then
			return row
		end
	end
	return rows[#rows]
end

-- A card's rarity in a set pack.
function M.rollTier(starLevel, rng)
	local odds = M.ODDS[starLevel] or M.ODDS[1]
	local rows = {}
	for _, t in ipairs(M.TIERS) do
		table.insert(rows, { tier = t, w = odds[t] or 0 })
	end
	return weighted(rows, rng, function(r)
		return r.w
	end).tier
end

-- One named pet of `tier` from a list of roster pets (falls back a tier down
-- when the list has none of that tier, which never happens with the owner's
-- counts). Never a holiday pet: those come only from a holiday pack.
-- Returns the pet and how many pets it was chosen from (the pull odds need it).
-- Zone packs use this too, on a zone's pot (MinePetRoster.BY_ZONE).
function M.pickPet(pets, tier, rng)
	local idx = table.find(M.TIERS, tier) or 1
	for t = idx, 1, -1 do
		local pool = {}
		for _, pet in ipairs(pets or {}) do
			if pet.tier == M.TIERS[t] and not pet.holiday then
				table.insert(pool, pet)
			end
		end
		if #pool > 0 then
			return pool[(rng and rng:NextInteger(1, #pool)) or math.random(1, #pool)], #pool
		end
	end
	return nil
end

-- The set filling one case slot: any set, top grades rarer.
function M.rollCaseSet(rng)
	local set = weighted(Sets.SETS, rng, function(s)
		return M.GRADE_WEIGHT[s.GRADE] or 1
	end)
	return set and set.KEY
end

-- What a case holds: { packId, ... } of its star grade.
function M.rollCase(starLevel, rng)
	local size = weighted(M.CASE_SIZE, rng, function(r)
		return r.weight
	end).n
	local out = {}
	for _ = 1, size do
		local key = M.rollCaseSet(rng)
		if key then
			table.insert(out, M.packId(key, starLevel))
		end
	end
	return out
end

-- A chest's pack case, if it drops one: a case id, or nil.
function M.rollChestCase(rank, rng)
	local key = M.CHEST_CASE_CHANCE[rank or ""] and rank or "C"
	if (rng and rng:NextNumber() or math.random()) >= M.CHEST_CASE_CHANCE[key] then
		return nil
	end
	local rows = {}
	for n, w in ipairs(M.CHEST_CASE_STARS[key]) do
		table.insert(rows, { n = n, w = w })
	end
	return M.caseId(weighted(rows, rng, function(r)
		return r.w
	end).n)
end

-- For the inspector: how likely one slot of a case is to come from a set of
-- each grade, best grade last. { { grade, pct, sets }, ... }
function M.caseGradeOdds()
	local byGrade, total = {}, 0
	for _, set in ipairs(Sets.SETS) do
		local w = M.GRADE_WEIGHT[set.GRADE] or 1
		total += w
		byGrade[set.GRADE] = byGrade[set.GRADE] or { grade = set.GRADE, pct = 0, sets = 0 }
		byGrade[set.GRADE].pct += w
		byGrade[set.GRADE].sets += 1
	end
	local out = {}
	for _, g in ipairs({ "F", "D", "C", "B", "A", "S", "SS", "SSS" }) do
		local row = byGrade[g]
		if row then
			row.pct = (total > 0) and (row.pct / total * 100) or 0
			table.insert(out, row)
		end
	end
	return out
end

-- Expected stardust value of one set pack of a star grade, given each tier's
-- stardust value (MinePackConfig.RECYCLE_STARDUST).
function M.expectedPackDust(starLevel, dustOfTier)
	local odds = M.ODDS[starLevel] or M.ODDS[1]
	local per = 0
	for _, t in ipairs(M.TIERS) do
		per += (odds[t] or 0) / 100 * (tonumber(dustOfTier[t]) or 0)
	end
	return per * (M.CARDS[starLevel] or 3)
end

-- The card a pack mints for one named pet (the same shape the wheel and the
-- lucky blocks mint). `setKey` is the pet's home: its set's key for a set pet,
-- its zone's id for a zone pet; cardKey is "<home>:<name>", so every copy of a
-- pet from a pack shares one key and merges.
function M.petCard(pet, setKey, setName)
	return {
		setId = setKey,
		index = 1,
		cardKey = setKey .. ":" .. pet.name,
		name = pet.name,
		rarityId = pet.tier,
		typeId = "Crystal",
		animal = pet.animal,
		kind = "Unit",
		setName = setName,
	}
end

-- A case's stardust price at M.CASE_RTP.
function M.casePrice(starLevel, dustOfTier)
	local avgSize = 0
	local total = 0
	for _, r in ipairs(M.CASE_SIZE) do
		avgSize += r.n * r.weight
		total += r.weight
	end
	avgSize /= math.max(1, total)
	local ev = M.expectedPackDust(starLevel, dustOfTier) * avgSize
	return math.max(25, math.floor(ev / M.CASE_RTP / 5 + 0.5) * 5)
end

return M
