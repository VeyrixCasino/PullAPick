-- MineGear: 8-tier gear pieces, set identities, predetermined stats, permanent sockets.
local MineRunes = require(script.Parent:WaitForChild("MineRunes"))
local ToolGrades = require(script.Parent:WaitForChild("MineToolGrades"))

local MineGear = {}

MineGear.RARITIES = { "F", "D", "C", "B", "A", "S", "SS", "SSS" }
MineGear.SLOTS = { "head", "face", "amulet", "chestplate", "leggings", "boots" }
MineGear.SLOT_LABEL = {
	head = "Head", face = "Face", amulet = "Amulet",
	chestplate = "Chestplate", leggings = "Leggings", boots = "Boots",
}
MineGear.BASE_SET_WEIGHT = {
	head = 100, face = 75, amulet = 0, chestplate = 125, leggings = 100, boots = 75,
}
MineGear.SHEET = {
	head = {
		F = { slots = 0, mult = 0.00 }, D = { slots = 0, mult = 0.25 }, C = { slots = 0, mult = 0.50 },
		B = { slots = 1, mult = 0.50 }, A = { slots = 2, mult = 0.50 }, S = { slots = 3, mult = 0.50 },
		SS = { slots = 4, mult = 0.50 }, SSS = { slots = 5, mult = 0.50 },
	},
	face = {
		F = { slots = 0, mult = -0.75 }, D = { slots = 0, mult = -0.50 }, C = { slots = 0, mult = -0.25 },
		B = { slots = 0, mult = 0.00 }, A = { slots = 2, mult = 0.00 }, S = { slots = 2, mult = 0.25 },
		SS = { slots = 2, mult = 0.50 }, SSS = { slots = 2, mult = 0.75 },
	},
	--[[
		The amulet is the socket slot, not a stat slot: piecePct returns 0 for it
		by design and BASE_SET_WEIGHT counts it as 0 toward set completion, so
		`mult` below never reaches a number the player can see.

		Which left rarity doing NOTHING on an amulet -- an F and an SSS were both
		one socket and both zero percent, identical in every way a player can
		observe, and the only slot in the game where pulling the best rarity was
		worth exactly as much as the worst.

		Sockets carry it instead, topping out one below the head so head stays
		the premier socket piece and the amulet is the second one.
	]]
	amulet = {
		F = { slots = 1, mult = 0.50 }, D = { slots = 1, mult = 0.75 }, C = { slots = 2, mult = 1.00 },
		B = { slots = 2, mult = 1.50 }, A = { slots = 3, mult = 2.00 }, S = { slots = 3, mult = 3.00 },
		SS = { slots = 4, mult = 4.00 }, SSS = { slots = 4, mult = 5.00 },
	},
	chestplate = {
		F = { slots = 0, mult = -0.50 }, D = { slots = 0, mult = -0.25 }, C = { slots = 0, mult = 0.00 },
		B = { slots = 0, mult = 0.25 }, A = { slots = 1, mult = 0.50 }, S = { slots = 2, mult = 0.75 },
		SS = { slots = 2, mult = 1.50 }, SSS = { slots = 2, mult = 2.00 },
	},
	leggings = {
		F = { slots = 0, mult = -0.75 }, D = { slots = 0, mult = -0.50 }, C = { slots = 0, mult = -0.25 },
		B = { slots = 0, mult = 0.00 }, A = { slots = 2, mult = 0.00 }, S = { slots = 2, mult = 0.25 },
		SS = { slots = 2, mult = 0.50 }, SSS = { slots = 2, mult = 0.75 },
	},
	boots = {
		F = { slots = 0, mult = -0.75 }, D = { slots = 0, mult = -0.50 }, C = { slots = 0, mult = -0.25 },
		B = { slots = 0, mult = 0.00 }, A = { slots = 2, mult = 0.00 }, S = { slots = 2, mult = 0.25 },
		SS = { slots = 2, mult = 0.50 }, SSS = { slots = 2, mult = 0.75 },
	},
}
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
function MineGear.migrateSlot(slot)
	if slot == "gloves" then
		return "face"
	end
	return slot
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

function MineGear.shopName(piece)
	if type(piece) ~= "table" then
		return ""
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
	piece.name = MineGear.shopName(piece)
	return piece
end


local function round4(v) return math.floor(v * 10000 + 0.5) / 10000 end

function MineGear.sheet(slot, rarity)
	local row = MineGear.SHEET[slot]
	return row and row[rarity]
end

function MineGear.piecePct(setId, slot, rarity)
	if slot == "amulet" then return 0 end
	local set = MineGear.SETS_BY_ID[setId]
	local cell = MineGear.sheet(slot, rarity)
	if not (set and cell) then return 0 end
	local half = MineRunes.initialMaxFraction(set.stat) / 2
	return round4(half * (1 + cell.mult))
end

-- Clash Royale process from F (p=1/3). Returns grade, info (info for reveal animation).
function MineGear.rollRarity(rng)
	return ToolGrades.rollClash("F", rng)
end

function MineGear.makePiece(id, setId, slot, rarity)
	rarity = MineGear.migrateRarity(rarity)
	slot = MineGear.migrateSlot(slot)
	local set = MineGear.SETS_BY_ID[setId]
	local cell = MineGear.sheet(slot, rarity)
	if not (set and cell) then
		return nil
	end
	local sockets = {}
	for i = 1, (cell.slots or 0) do
		sockets[i] = nil
	end
	local piece = {
		id = id, setId = set.id, setName = set.name, stat = set.stat, slot = slot, rarity = rarity,
		mult = cell.mult or 0, slotCount = cell.slots or 0,
		pct = MineGear.piecePct(set.id, slot, rarity), sockets = sockets,
	}
	piece.name = MineGear.shopName(piece)
	return piece
end

function MineGear.rollPiece(id, rng)
	rng = rng or Random.new()
	local set = MineGear.SETS[rng:NextInteger(1, #MineGear.SETS)]
	local slot = MineGear.SLOTS[rng:NextInteger(1, #MineGear.SLOTS)]
	local rarity, info = MineGear.rollRarity(rng)
	local piece = MineGear.makePiece(id, set.id, slot, rarity)
	-- Second return is the CR step list for UI; not stored on the piece (save size).
	return piece, info
end

function MineGear.describe(piece)
	if not piece then return "Empty" end
	return string.format("%s %s  +%.1f%% %s  (%d slots)",
		piece.rarity, piece.name or MineGear.shopName(piece),
		(piece.pct or 0) * 100, piece.stat, piece.slotCount or 0)
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

function MineGear.applyEquipped(b, equipped, runeById)
	for _, piece in pairs(equipped or {}) do
		if piece then
			if piece.pct and piece.pct ~= 0 and piece.stat then
				MineRunes.applyFraction(b, piece.stat, piece.pct)
			end
			for _, runeId in ipairs(piece.sockets or {}) do
				local rune = runeById and runeById[runeId]
				if rune then MineRunes.applyRune(b, rune) end
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
				local ok = cell ~= nil and (slot ~= "amulet" or pct == 0)
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
	return MineGear.imageFor(piece.setId, piece.slot, piece.rarity)
end

return MineGear
