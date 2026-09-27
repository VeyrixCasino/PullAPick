-- MineGear: 8-tier gear pieces, set identities, predetermined stats, permanent sockets.
local MineRunes = require(script.Parent:WaitForChild("MineRunes"))
local ToolGrades = require(script.Parent:WaitForChild("MineToolGrades"))

local MineGear = {}

MineGear.RARITIES = { "F", "D", "C", "B", "A", "S", "SS", "SSS" }
--------------------------------------------------------------------------------
-- WHAT GEAR IS
--
-- Gear is a HAT and a FACE. Helmet / chestplate / leggings / boots are gone --
-- four slots on a character the camera barely looks at, that nobody equipped.
--
--   HAT   goes on a PET (or on you). It multiplies that pet's EXISTING boost
--         of the hat's set stat — it does not add a flat boost. Your own hat
--         does the same for every pet's matching-stat line.
--   FACE  is the only piece that is yours and not a pet's, so it is the broad
--         one: it multiplies your whole team at once, and its tailored half
--         lands on whatever your team already leans on hardest.
--
-- Both are real Roblox catalog items (MineHats), graded F..SSS off their RAP.
--
-- ONE rune socket per piece, never more. Three pets + your hat + your face +
-- your tool is six runes in the entire game, which is exactly why a rune is
-- allowed to be worth something (see MineRunes.SOCKET_GAIN).
--
-- Old saves lose nothing: every retired slot folds into "hat" and is re-priced
-- off the live sheet, so a Bedrock Plate becomes a Bedrock hat of the same
-- grade, sockets and all.
--------------------------------------------------------------------------------
MineGear.SLOTS = { "hat", "face" }
MineGear.SLOT_LABEL = { hat = "Hat", face = "Face" }
MineGear.SLOT_BLURB = {
	hat = "Wear it, or put it on a pet. Your own hat is added to every pet.",
	face = "Yours alone. Multiplies your whole team.",
}
MineGear.PET_SLOT = "hat"
MineGear.SOCKETS_PER_PIECE = 1
-- Retired slots, kept so old saves and old shop rows still resolve.
MineGear.LEGACY_SLOTS = {
	head = true, amulet = true, chestplate = true, leggings = true, boots = true, gloves = true,
}
MineGear.BASE_SET_WEIGHT = { hat = 100, face = 100 }
-- Four hats are wearable at once (three pets and you) against one face, so hats
-- are the common drop and a face is the one you go hunting for.
MineGear.SLOT_ODDS = { hat = 78, face = 22 }

--[[
	What a piece is worth, by grade.

	`pct` is a MULTIPLIER on what the wearer already gives, not a stat of its
	own: a B hat on a pet is that pet's entire kit again at +30%, and double that
	on the hat's own stat. The old sheet paid half of one rune's opening roll
	into a single stat, which is how four pieces of gear ended up worth less
	than one pet.
]]
MineGear.SHEET = {
	hat = {
		F = { slots = 1, pct = 0.25 }, D = { slots = 1, pct = 0.40 }, C = { slots = 1, pct = 0.55 },
		B = { slots = 1, pct = 0.75 }, A = { slots = 1, pct = 1.05 }, S = { slots = 1, pct = 1.45 },
		SS = { slots = 1, pct = 1.90 }, SSS = { slots = 1, pct = 2.50 },
	},
	face = {
		F = { slots = 1, pct = 0.15 }, D = { slots = 1, pct = 0.25 }, C = { slots = 1, pct = 0.35 },
		B = { slots = 1, pct = 0.50 }, A = { slots = 1, pct = 0.70 }, S = { slots = 1, pct = 1.00 },
		SS = { slots = 1, pct = 1.30 }, SSS = { slots = 1, pct = 1.75 },
	},
}

--[[
	The catalog behind a piece. Loaded defensively for the same reason the icon
	table is: a missing module should cost you thumbnails, not the whole game.
]]
local Hats
do
	local mod = script.Parent:FindFirstChild("MineHats")
	if mod then
		local ok, loaded = pcall(require, mod)
		if ok and type(loaded) == "table" then
			Hats = loaded
		else
			warn("[MineGear] MineHats failed to load; gear will roll without catalog items. " .. tostring(loaded))
		end
	end
end
MineGear.Hats = Hats

function MineGear.catalogFor(slot, rarity, setId, rng)
	if not (Hats and Hats.rollFor) then
		return nil
	end
	local ok, row = pcall(Hats.rollFor, slot, rarity, setId, rng)
	return ok and row or nil
end

-- Faces only exist at some grades (MineHats.nearestFaceGrade). Snap the roll to
-- a grade that has one, so the piece and its label always agree.
function MineGear.snapGrade(slot, grade)
	grade = MineGear.migrateRarity(grade)
	if MineGear.migrateSlot(slot) ~= "face" then
		return grade
	end
	if not (Hats and Hats.nearestFaceGrade) then
		return grade
	end
	local ok, snapped = pcall(Hats.nearestFaceGrade, grade)
	return (ok and snapped) or grade
end

function MineGear.rollSlot(rng)
	rng = rng or Random.new()
	local total = 0
	for _, slot in ipairs(MineGear.SLOTS) do
		total += MineGear.SLOT_ODDS[slot] or 0
	end
	local n, acc = rng:NextNumber() * total, 0
	for _, slot in ipairs(MineGear.SLOTS) do
		acc += MineGear.SLOT_ODDS[slot] or 0
		if n <= acc then
			return slot
		end
	end
	return "hat"
end

MineGear.SETS = {
	{ id = "inferno", name = "Inferno", stat = "blastRadius", fantasy = "Fire / blast" },
	{ id = "glacier", name = "Glacier", stat = "swingRate", fantasy = "Frost tempo" },
	{ id = "tide", name = "Tide", stat = "backpack", fantasy = "Water haul" },
	{ id = "canopy", name = "Canopy", stat = "oreYield", fantasy = "Grass harvest" },
	{ id = "bedrock", name = "Bedrock", stat = "dirtBreak", fantasy = "Ground excavate" },
	{ id = "foundry", name = "Foundry", stat = "coinBonus", fantasy = "Metal refine" },
	{ id = "storm", name = "Storm", stat = "zap", fantasy = "Electric chain zap" },
	{ id = "prism", name = "Prism", stat = "rareOre", fantasy = "Crystal prospect" },
	{ id = "umbra", name = "Umbra", stat = "luck", fantasy = "Shadow fortune" },
	{ id = "void", name = "Void", stat = "echo", fantasy = "Space echo" },
}
MineGear.SETS_BY_ID = {}
for _, s in ipairs(MineGear.SETS) do MineGear.SETS_BY_ID[s.id] = s end
-- Legacy weighted table (docs only). Live gear rarity uses ToolGrades.rollClash.
MineGear.RARITY_WEIGHTS = ToolGrades.FINAL_ODDS_FROM_F
MineGear.ROLL_PRICE = 75
-- Scaled like MineRunes.rollPriceFor (three rune summons a gear draw).
function MineGear.rollPriceFor(zone)
	local z = math.max(1, math.floor(tonumber(zone) or 1))
	if z <= 1 then
		return MineGear.ROLL_PRICE
	end
	return math.floor(MineGear.ROLL_PRICE * 5.2 * 1.4 ^ (z - 2) / 5 + 0.5) * 5
end
--------------------------------------------------------------------------------
-- RARITY NAMES
--
-- Gear grades are letters: F D C B A S SS SSS, worst to best. They used to be
-- the card words (Common .. Exotic) and were coloured by borrowing
-- MineCards.RARITY_COLOR, which meant gear and cards could never be renamed
-- independently. Gear owns its own three tables now; the colour ramp is the
-- same one it always had, so nothing about how a piece looks has changed.
--------------------------------------------------------------------------------
MineGear.RARITY_LABEL = {}
MineGear.RARITY_RANK = {}
for i, r in ipairs(MineGear.RARITIES) do
	MineGear.RARITY_LABEL[r] = r
	MineGear.RARITY_RANK[r] = i
end

MineGear.RARITY_COLOR = {
	F = Color3.fromRGB(170, 170, 170),
	D = Color3.fromRGB(85, 255, 127),
	C = Color3.fromRGB(85, 170, 255),
	B = Color3.fromRGB(170, 85, 255),
	A = Color3.fromRGB(255, 170, 0),
	S = Color3.fromRGB(85, 220, 255),
	SS = Color3.fromRGB(255, 245, 160),
	SSS = Color3.fromRGB(255, 55, 55),
}

-- Letter grade -> print rarity. The card chrome (banner, rim, wash) reads this
-- ladder, not the S/SS/SSS mark. Those three share one badge instead.
MineGear.PRINT_OF = {
	F = "Common", D = "Uncommon", C = "Rare", B = "Epic",
	A = "Legendary", S = "Mythic", SS = "Divine", SSS = "Exotic",
}

function MineGear.printRarity(rarity)
	rarity = MineGear.migrateRarity(rarity)
	return MineGear.PRINT_OF[rarity] or rarity
end

-- Saved pieces still carry the old words.
MineGear.OLD_RARITY = {
	Common = "F", Uncommon = "D", Rare = "C", Epic = "B",
	Legendary = "A", Mythic = "S", Divine = "SS", Exotic = "SSS",
}

function MineGear.migrateRarity(rarity)
	return MineGear.OLD_RARITY[rarity] or rarity
end

-- Safe on every piece on every load.
-- Safe on every piece on every load. The face is the face (gloves became the
-- face long ago); everything else -- head, amulet, chestplate, leggings, boots
-- -- is a hat now.
function MineGear.migrateSlot(slot)
	if slot == "face" or slot == "gloves" then
		return "face"
	end
	return "hat"
end

-- True catalog hats/faces only. Legacy armour (amulet/chest/…) normalizes to
-- slot "hat" for stats, but must NOT flood the Hats bag four times.
function MineGear.isFacePiece(g)
	if type(g) ~= "table" then
		return false
	end
	if g.kind == "Face" then
		return true
	end
	local s = tostring(g.slot or "")
	return s == "face" or s == "gloves"
end

function MineGear.isHatPiece(g)
	if type(g) ~= "table" then
		return false
	end
	if MineGear.isFacePiece(g) then
		return false
	end
	if g.kind == "Hat" then
		return true
	end
	-- Real drops carry a catalog id / hatId. Migrated plates do not.
	if g.catalogId or g.hatId then
		return true
	end
	return false
end

-- Limited shop display names (set × slot). Not random fantasy rolls.
MineGear.LIMITED_NAME = {
	inferno = { head = "Ember Crown", face = "Ember Visage", amulet = "Ember Seal", chestplate = "Ember Plate", leggings = "Ember Greaves", boots = "Ember Treads" },
	glacier = { head = "Rime Crown", face = "Rime Visage", amulet = "Rime Seal", chestplate = "Rime Plate", leggings = "Rime Greaves", boots = "Rime Treads" },
	tide = { head = "Tide Crown", face = "Tide Visage", amulet = "Tide Seal", chestplate = "Tide Plate", leggings = "Tide Greaves", boots = "Tide Treads" },
	canopy = { head = "Canopy Crown", face = "Canopy Visage", amulet = "Canopy Seal", chestplate = "Canopy Plate", leggings = "Canopy Greaves", boots = "Canopy Treads" },
	bedrock = { head = "Bedrock Crown", face = "Bedrock Visage", amulet = "Bedrock Seal", chestplate = "Bedrock Plate", leggings = "Bedrock Greaves", boots = "Bedrock Treads" },
	foundry = { head = "Foundry Crown", face = "Foundry Visage", amulet = "Foundry Seal", chestplate = "Foundry Plate", leggings = "Foundry Greaves", boots = "Foundry Treads" },
	storm = { head = "Storm Crown", face = "Storm Visage", amulet = "Storm Seal", chestplate = "Storm Plate", leggings = "Storm Greaves", boots = "Storm Treads" },
	prism = { head = "Prism Crown", face = "Prism Visage", amulet = "Prism Seal", chestplate = "Prism Plate", leggings = "Prism Greaves", boots = "Prism Treads" },
	umbra = { head = "Umbra Crown", face = "Umbra Visage", amulet = "Umbra Seal", chestplate = "Umbra Plate", leggings = "Umbra Greaves", boots = "Umbra Treads" },
	void = { head = "Void Crown", face = "Void Visage", amulet = "Void Seal", chestplate = "Void Plate", leggings = "Void Greaves", boots = "Void Treads" },
}

-- The old head names read fine on a hat.
for _, row in pairs(MineGear.LIMITED_NAME) do
	row.hat = row.hat or row.head
end

function MineGear.shopName(piece)
	if type(piece) ~= "table" then
		return ""
	end
	-- A real hat has a real name. "Dominus Astra" beats "Void Crown".
	if type(piece.itemName) == "string" and piece.itemName ~= "" then
		return piece.itemName
	end
	local row = MineGear.LIMITED_NAME[piece.setId]
	local n = row and row[MineGear.migrateSlot(piece.slot)]
	if n then
		return n
	end
	return string.format("%s %s", tostring(piece.setName or piece.setId or ""), MineGear.SLOT_LABEL[MineGear.migrateSlot(piece.slot)] or tostring(piece.slot or ""))
end

function MineGear.normalize(piece)
	if type(piece) ~= "table" then
		return piece
	end
	piece.rarity = MineGear.migrateRarity(piece.rarity)
	piece.slot = MineGear.migrateSlot(piece.slot)
	-- Admin-forged customs (id prefix "adm_" / adminForged flag) keep their
	-- authored piece.stats / pct. Do NOT re-price them off the live sheet.
	local isAdminForge = piece.adminForged == true
		or (type(piece.id) == "string" and string.sub(piece.id, 1, 4) == "adm_")
	if not isAdminForge then
		-- Retired slots carried the old half-a-rune percentages and up to five
		-- sockets. Re-price every piece off the live sheet, so a migrated
		-- chestplate IS a hat: worth exactly what a hat of its grade is worth.
		local cell = MineGear.sheet(piece.slot, piece.rarity)
		if cell then
			piece.pct = MineGear.piecePct(piece.setId, piece.slot, piece.rarity)
			piece.mult = cell.mult or piece.mult or 0
			piece.slotCount = cell.slots or 1
		end
	else
		piece.adminForged = true
		piece.slotCount = piece.slotCount or 1
		piece.mult = piece.mult or 0
	end
	-- A piece that came from a five-socket slot may hold more runes than one
	-- socket allows. They stay. Dropping a rune on load is not a migration.
	piece.sockets = piece.sockets or {}
	piece.name = MineGear.shopName(piece)
	return piece
end


local function round4(v) return math.floor(v * 10000 + 0.5) / 10000 end

function MineGear.sheet(slot, rarity)
	local row = MineGear.SHEET[slot]
	return row and row[rarity]
end

function MineGear.piecePct(setId, slot, rarity)
	local cell = MineGear.sheet(MineGear.migrateSlot(slot), MineGear.migrateRarity(rarity))
	if not cell then
		return 0
	end
	if cell.pct then
		return round4(cell.pct)
	end
	-- Legacy rows (none ship any more) kept the old half-a-rune shape.
	local set = MineGear.SETS_BY_ID[setId]
	if not set then
		return 0
	end
	return round4(MineRunes.initialMaxFraction(set.stat) / 2 * (1 + (cell.mult or 0)))
end

--[[
	A worn HAT, as numbers: (all, stat, spec).

	Hats never add a flat boost. They only multiply the pet's existing boost of
	`stat` by (1 + spec). `all` is always 0 for hats so other stats are untouched.
	Faces use faceMult instead (team-wide after pets are summed).
]]
--[[
	Hat/face lines on a piece. Merged pieces may carry several; rolled pieces
	always have exactly one (set stat + sheet pct).
]]
function MineGear.boostLines(piece)
	if type(piece) ~= "table" then
		return {}
	end
	if type(piece.stats) == "table" and #piece.stats > 0 then
		local out = {}
		for _, row in ipairs(piece.stats) do
			if type(row) == "table" and row.stat and tonumber(row.pct) then
				table.insert(out, { stat = row.stat, pct = tonumber(row.pct) or 0 })
			end
		end
		if #out > 0 then
			return out
		end
	end
	if piece.stat then
		return { { stat = piece.stat, pct = tonumber(piece.pct) or 0 } }
	end
	return {}
end

function MineGear.pctOnStat(piece, stat)
	local sum = 0
	for _, line in ipairs(MineGear.boostLines(piece)) do
		if line.stat == stat then
			sum += line.pct
		end
	end
	return sum
end

function MineGear.wearMult(piece)
	if type(piece) ~= "table" then
		return 0, nil, 0
	end
	local lines = MineGear.boostLines(piece)
	local primary = lines[1]
	if not primary then
		return 0, nil, 0
	end
	if MineGear.migrateSlot(piece.slot) == "face" then
		return primary.pct, primary.stat, 0
	end
	return 0, primary.stat, primary.pct
end

MineGear.FACE_TAILOR_SHARE = 0

function MineGear.faceMult(_piece)
	return 0, 0
end

function MineGear.tailorStat(_delta)
	return nil
end

--[[
	STACKING:
	1) Hats give static +% on set stat(s). Your Hat/Hat2 apply to every pet.
	2) Face multiplies those hat %s on matching stats.
	3) Per pet: petBase*(1+rune) + hatPts*(1+facePct). Sum pets.
]]
function MineGear.stackPets(pets, playerHat, face, playerHat2)
	local total = {}
	local faceByStat = {}
	for _, line in ipairs(MineGear.boostLines(face)) do
		faceByStat[line.stat] = (faceByStat[line.stat] or 0) + line.pct
	end
	for _, row in ipairs(pets or {}) do
		local runeAll = MineRunes.wearBroad(row.rune)
		local seen = {}
		local function touch(stat)
			if stat then seen[stat] = true end
		end
		for stat in pairs(row.delta or {}) do touch(stat) end
		for _, line in ipairs(MineGear.boostLines(row.hat)) do touch(line.stat) end
		for _, line in ipairs(MineGear.boostLines(playerHat)) do touch(line.stat) end
		for _, line in ipairs(MineGear.boostLines(playerHat2)) do touch(line.stat) end
		for stat in pairs(seen) do
			local amount = tonumber((row.delta or {})[stat]) or 0
			local base = amount * (1 + runeAll)
			local hatPts = MineGear.pctOnStat(row.hat, stat)
				+ MineGear.pctOnStat(playerHat, stat)
				+ MineGear.pctOnStat(playerHat2, stat)
			local effectiveHat = hatPts * (1 + (faceByStat[stat] or 0))
			local contrib = base + effectiveHat
			if contrib ~= 0 then
				total[stat] = (total[stat] or 0) + contrib
			end
		end
	end
	local tailor = nil
	for stat in pairs(faceByStat) do
		tailor = stat
		break
	end
	return total, tailor
end

function MineGear.rollRarity(rng)
	rng = rng or Random.new()
	local Temper = require(script.Parent:WaitForChild("MineTemper"))
	local weights = Temper.RARITY_WEIGHTS
	local order = Temper.GRADE_ORDER or { "F", "D", "C", "B", "A", "S", "SS", "SSS" }
	local total = 0
	for _, g in ipairs(order) do
		total += math.max(0, tonumber(weights[g]) or 0)
	end
	if total <= 0 then
		return "F"
	end
	local roll = rng:NextNumber() * total
	local acc = 0
	for _, g in ipairs(order) do
		acc += math.max(0, tonumber(weights[g]) or 0)
		if roll <= acc then
			return g
		end
	end
	return "F"
end

function MineGear.makePiece(id, setId, slot, rarity, catalog)
	rarity = MineGear.migrateRarity(rarity)
	slot = MineGear.migrateSlot(slot)
	local set = MineGear.SETS_BY_ID[setId]
	local cell = MineGear.sheet(slot, rarity)
	if not (set and cell) then
		return nil
	end
	local piece = {
		id = id, setId = set.id, setName = set.name, stat = set.stat, slot = slot, rarity = rarity,
		mult = cell.mult or 0, slotCount = cell.slots or 1,
		pct = MineGear.piecePct(set.id, slot, rarity), sockets = {},
	}
	if type(catalog) == "table" then
		piece.hatId = catalog.id
		piece.catalogId = catalog.catalogId
		piece.rap = catalog.rap
		piece.itemName = catalog.name
		piece.kind = catalog.kind
	end
	piece.name = MineGear.shopName(piece)
	return piece
end

function MineGear.rollPiece(id, rng)
	rng = rng or Random.new()
	local slot = MineGear.rollSlot(rng)
	local rarity, info = MineGear.rollRarity(rng)
	rarity = MineGear.snapGrade(slot, rarity)
	-- The catalog item picks the set, not the other way round, so the hat you
	-- see and the buff it carries tell the same story.
	local catalog = MineGear.catalogFor(slot, rarity, nil, rng)
	local setId = (catalog and catalog.setId) or MineGear.SETS[rng:NextInteger(1, #MineGear.SETS)].id
	local piece = MineGear.makePiece(id, setId, slot, rarity, catalog)
	return piece, info
end

function MineGear.statLabel(stat)
	local ok, Stats = pcall(require, script.Parent:FindFirstChild("MineStats"))
	if ok and Stats and Stats.STATS and Stats.STATS[stat] then
		return Stats.STATS[stat].label or tostring(stat)
	end
	return tostring(stat or "?")
end

-- Glanceable lines for tiles/cards: "+120% Dirt Break" (one per boost line).
function MineGear.boostTextLines(piece)
	local out = {}
	for _, line in ipairs(MineGear.boostLines(piece)) do
		local pct = math.floor((tonumber(line.pct) or 0) * 100 + 0.5)
		table.insert(out, string.format("+%d%% %s", pct, MineGear.statLabel(line.stat)))
	end
	return out
end

function MineGear.hatEffectLine(piece)
	local lines = MineGear.boostTextLines(piece)
	if #lines == 0 then
		return ""
	end
	return table.concat(lines, "\n")
end

function MineGear.hatMeansLine(piece)
	if MineGear.migrateSlot(piece and piece.slot) == "face" then
		return "Face multiplies matching hat %s on every pet (not a personal flat boost)."
	end
	return "Static hat % on pets. Your Hat applies to every pet; Face scales hat %s."
end

function MineGear.describe(piece)
	if not piece then return "Empty" end
	local name = piece.name or MineGear.shopName(piece)
	local boost = MineGear.hatEffectLine(piece)
	if MineGear.migrateSlot(piece.slot) == "face" then
		return string.format("%s %s  Face %s", piece.rarity, name, boost)
	end
	return string.format("%s %s  %s", piece.rarity, name, boost)
end

function MineGear.setCompletionScore(equipped)
	local scores = {}
	for _, piece in pairs(equipped or {}) do
		if piece and piece.setId then
			local w = MineGear.BASE_SET_WEIGHT[piece.slot] or 0
			scores[piece.setId] = (scores[piece.setId] or 0) + w
		end
	end
	local bestId, best = nil, 0
	for id, sc in pairs(scores) do
		if sc > best then best, bestId = sc, id end
	end
	return bestId, best, scores
end

--[[
	The pieces YOU wear, which means their runes -- a rune's own stat has always
	landed on you and still does. What is deliberately NOT here any more is the
	piece percentage: a hat multiplies the pet wearing it and a face multiplies
	the team, and both of those happen in stackPets. Pouring them in here as
	flat stats is what made gear invisible.

	`ipairs` was also wrong: a piece whose first socket is empty holds its runes
	at index 2 and up, and ipairs stops at the hole.
]]
function MineGear.applyEquipped(b, equipped, runeById)
	for _, piece in pairs(equipped or {}) do
		if piece then
			for _, runeId in pairs(piece.sockets or {}) do
				local rune = runeById and runeById[runeId]
				if rune then
					MineRunes.applyRune(b, rune, MineRunes.SOCKET_GAIN)
				end
			end
		end
	end
end

function MineGear.audit()
	local rows, fails = {}, 0
	for _, set in ipairs(MineGear.SETS) do
		for _, slot in ipairs(MineGear.SLOTS) do
			for _, rarity in ipairs(MineGear.RARITIES) do
				local cell = MineGear.sheet(slot, rarity)
				local pct = MineGear.piecePct(set.id, slot, rarity)
				local ok = cell ~= nil and pct > 0 and (cell.slots or 0) == 1
				if not ok then fails += 1 end
				table.insert(rows, { set = set.id, slot = slot, rarity = rarity, slots = cell and cell.slots, mult = cell and cell.mult, pct = pct, ok = ok })
			end
		end
	end
	return rows, fails
end

-- What the Scrapper pays for a gear piece. Rarity carries most of it; empty
-- rune slots are worth something because a socket is the scarce part.
function MineGear.scrapGems(piece)
	if type(piece) ~= "table" then
		return 0
	end
	local rank = 1
	for i, r in ipairs(MineGear.RARITIES) do
		if r == piece.rarity then
			rank = i
			break
		end
	end
	local base = 15 * rank + 20 * (piece.slotCount or 0)
	return math.max(1, math.floor(base * (1 + (piece.pct or 0) * 8) * MineGear.SCRAP_RATE + 0.5))
end

--[[
	About a third of what the gem banner charges for a piece.

	It was 89%: a 75-gem roll scrapped for 67 on average, so rolling gear and
	scrapping the misses cost next to nothing -- and gear packs, which pay three
	and five pieces for credits, turned credits straight into gems at up to 1.6
	per credit. Scrap is the consolation for a bad roll, not a refund of it.
]]
MineGear.SCRAP_RATE = 0.35

--[[
	Gear icons live in MineGearIcons (split tables = Luau register-safe).

	Loaded defensively on purpose. A bare
	`require(script.Parent:WaitForChild("MineGearIcons"))` yields FOREVER if
	that module is absent, which means MineGear never finishes loading, which
	means MineServer:32 dies, which means MineNet is never created and the whole
	game is down -- from one missing icon table. Missing or broken icons should
	cost you icons, nothing else.
]]
MineGear.ICONS = {}
do
	local inst = script.Parent:FindFirstChild("MineGearIcons")
	if inst then
		local ok, loaded = pcall(require, inst)
		if ok and type(loaded) == "table" then
			MineGear.ICONS = loaded
		else
			warn("[MineGear] MineGearIcons failed to load; gear will show no icons. " .. tostring(loaded))
		end
	else
		warn("[MineGear] MineGearIcons is missing; gear will show no icons.")
	end
end

MineGear.ICON_BAND = {
	F = "fa", D = "fa", C = "fa", B = "fa", A = "fa",
	S = "sss", SS = "sss", SSS = "sss",
}

function MineGear.imageFor(setId, slot, rarity)
	rarity = MineGear.migrateRarity(rarity)
	local band = MineGear.ICON_BAND[rarity] or "fa"
	local setIcons = MineGear.ICONS[setId]
	local bandIcons = setIcons and setIcons[band]
	return bandIcons and bandIcons[slot] or nil
end

function MineGear.image(piece)
	if type(piece) ~= "table" then
		return nil
	end
	-- A real hat shows the real hat.
	if Hats and Hats.image then
		local ok, url = pcall(Hats.image, piece)
		if ok and url then
			return url
		end
	end
	return MineGear.imageFor(piece.setId, piece.slot, piece.rarity)
end

--[[
	Merge two hat pieces into one multi-stat hat. Face pieces cannot merge.
	Only path to multi-stat hats. Same-stat lines sum; rarity keeps the higher.
]]
function MineGear.mergeHats(a, b, newId)
	local function hatish(g)
		if MineGear.isFacePiece(g) then
			return false
		end
		return MineGear.isHatPiece(g) or MineGear.migrateSlot(g and g.slot) == "hat"
	end
	if not (hatish(a) and hatish(b)) then
		return nil, "Only hats merge"
	end
	local order = { "F", "D", "C", "B", "A", "S", "SS", "SSS" }
	local function rank(r)
		return table.find(order, MineGear.migrateRarity(r)) or 1
	end
	local primary = rank(a.rarity) >= rank(b.rarity) and a or b
	local secondary = primary == a and b or a
	local stats = {}
	local function addLines(piece)
		for _, line in ipairs(MineGear.boostLines(piece)) do
			local found
			for _, row in ipairs(stats) do
				if row.stat == line.stat then
					row.pct += line.pct
					found = true
					break
				end
			end
			if not found then
				table.insert(stats, { stat = line.stat, pct = line.pct })
			end
		end
	end
	addLines(a)
	addLines(b)
	if #stats == 0 then
		return nil, "Nothing to merge"
	end
	return {
		id = newId or primary.id,
		setId = primary.setId,
		setName = primary.setName,
		stat = stats[1].stat,
		pct = stats[1].pct,
		stats = stats,
		slot = "hat",
		rarity = MineGear.migrateRarity(primary.rarity),
		mult = primary.mult or 0,
		slotCount = math.max(tonumber(primary.slotCount) or 1, tonumber(secondary.slotCount) or 1),
		sockets = {},
		hatId = primary.hatId or secondary.hatId,
		catalogId = primary.catalogId or secondary.catalogId,
		name = primary.name or secondary.name,
		merged = true,
	}
end

return MineGear
