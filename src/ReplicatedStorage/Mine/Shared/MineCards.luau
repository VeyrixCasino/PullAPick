-- MineCards: Season 1 sets + filler/hit odds. Does not retune rarity tables.
local MineCards = {}

MineCards.FILLER = {
	{ rarity = "Common", weight = 82 },
	{ rarity = "Uncommon", weight = 17 },
	{ rarity = "Rare", weight = 1 },
}

-- Eight rungs: Common, Uncommon, Rare, Epic, Legendary, Mythic, Divine, Exotic
-- -- the same ladder MinePackConfig.TIERS and MinePetRoster.TIER_ORDER already
-- used. The cards were on a seven-rung TCG-style ladder instead, which is why a
-- pack rolled "Epic" and the card table had never heard of it.
--
-- The old top weight splits into Divine and Exotic so the ladder gains a rung
-- without every HIT row below being retyped.
local function hit(c, u, r, epic, legendary, mythic, top)
	return {
		{ rarity = "Common", weight = c },
		{ rarity = "Uncommon", weight = u },
		{ rarity = "Rare", weight = r },
		{ rarity = "Epic", weight = epic },
		{ rarity = "Legendary", weight = legendary },
		{ rarity = "Mythic", weight = mythic },
		{ rarity = "Divine", weight = top * 0.7 },
		{ rarity = "Exotic", weight = top * 0.3 },
	}
end

MineCards.HIT = {
	T1 = hit(34, 38, 19, 6, 2.20, 0.65, 0.15),
	T2 = hit(34, 38, 19, 6, 2.50, 0.40, 0.10),
	T3 = hit(32, 37, 19, 7, 4.00, 0.70, 0.30),
	T4 = hit(31, 36, 19, 8, 5.00, 0.70, 0.30),
	T5 = hit(31, 35, 19, 9, 5.30, 0.65, 0.05),
	T6 = hit(32, 37, 20, 5.5, 4.50, 0.80, 0.20),
	T7 = hit(33, 38, 19, 5, 4.30, 0.60, 0.10),
	T8 = hit(37, 39, 16, 4.5, 2.70, 0.70, 0.10),
	T9 = hit(43, 41, 11, 3, 1.40, 0.50, 0.10),
}

local function set(id, displayName, tier, theme, cardCount, secretCount)
	return {
		id = id,
		displayName = displayName,
		tier = tier,
		theme = theme,
		cardCount = cardCount,
		secretCount = secretCount,
	}
end

MineCards.SETS = {
	dragons_dawn = set("dragons_dawn", "Meadow", "T1", "Fire", 88, 3),
	grass_glimmer = set("grass_glimmer", "Meadow", "T1", "Earth", 90, 3),
	prism_meadow = set("prism_meadow", "Meadow", "T1", "Crystal", 92, 2),
	iron_empire = set("iron_empire", "Greyvein", "T2", "Metal", 89, 3),
	fire_sunscar = set("fire_sunscar", "Greyvein", "T2", "Fire", 91, 3),
	cinder_vault = set("cinder_vault", "Greyvein", "T2", "Fire", 87, 2),
	water_mistreef = set("water_mistreef", "Mistreef", "T3", "Water", 90, 3),
	rock_verdantthrone = set("rock_verdantthrone", "Mistreef", "T3", "Rock", 88, 3),
	deepwave_surge = set("deepwave_surge", "Mistreef", "T3", "Water", 93, 2),
	electric_arcwork = set("electric_arcwork", "Arcwork", "T4", "Electric", 90, 3),
	crystal_astralbloom = set("crystal_astralbloom", "Arcwork", "T4", "Crystal", 94, 3),
	nova_circuit = set("nova_circuit", "Arcwork", "T4", "Electric", 86, 2),
	metal_steelforge = set("metal_steelforge", "Bloodmoon", "T5", "Metal", 91, 3),
	shadow_bloodmoon = set("shadow_bloodmoon", "Bloodmoon", "T5", "Shadow", 89, 3),
	obsidian_hollow = set("obsidian_hollow", "Bloodmoon", "T5", "Shadow", 85, 2),
	stormreach = set("stormreach", "Bloodmoon", "T6", "Electric", 90, 3),
	crystal_sanctum = set("crystal_sanctum", "Eclipse", "T6", "Crystal", 95, 3),
	void_parallax = set("void_parallax", "Eclipse", "T6", "Shadow", 82, 2),
	aurora_crown = set("aurora_crown", "Eclipse", "T7", "Crystal", 98, 4),
	solaris_relic = set("solaris_relic", "Universal", "T7", "Fire", 96, 3),
	nebula_vault = set("nebula_vault", "Eclipse", "T8", "Crystal", 100, 4),
	chronicle_prime = set("chronicle_prime", "Universal", "T8", "Metal", 102, 3),
	eclipse_ascendant = set("eclipse_ascendant", "Eclipse", "T9", "Shadow", 105, 5),
	le_phoenix_veil = set("le_phoenix_veil", "Universal", "T7", "Fire", 78, 2),
	le_radiant_archive = set("le_radiant_archive", "Universal", "T7", "Crystal", 82, 3),
	le_golden_hour = set("le_golden_hour", "Universal", "T7", "Fire", 88, 2),
	-- Event Horizon limited sets (packs from the event mine).
	genesis_spark = set("genesis_spark", "Horizon", "T9", "Crystal", 96, 4),
	first_light = set("first_light", "Horizon", "T9", "Fire", 96, 4),
	proto_ore = set("proto_ore", "Horizon", "T9", "Metal", 96, 4),

	--[[
		Zones 7 to 10.

		These twelve ids were named on the zones in MineConfig and never defined
		here, so MineConfig.setForLayer handed every chest in Riftmarch,
		Starfall, Mythral and Primordium a set that did not exist -- getCard
		returned nil for every index and those packs opened with nothing in
		them. Four late zones of the progression, paying empty packs.

		Cards are procedural from (setId, index), so a row here is the whole set.
		T9 because it is the last row in HIT; each zone takes three different
		themes, like the six before it.
	]]
	rift_chorus = set("rift_chorus", "Riftmarch", "T9", "Rock", 100, 4),
	scar_legion = set("scar_legion", "Riftmarch", "T9", "Metal", 98, 4),
	faultline_opera = set("faultline_opera", "Riftmarch", "T9", "Earth", 102, 4),
	starfall_siege = set("starfall_siege", "Starfall", "T9", "Fire", 102, 4),
	void_meteor = set("void_meteor", "Starfall", "T9", "Shadow", 100, 5),
	astral_drysea = set("astral_drysea", "Starfall", "T9", "Crystal", 104, 4),
	mythral_choir = set("mythral_choir", "Mythral", "T9", "Crystal", 104, 5),
	catacomb_kings = set("catacomb_kings", "Mythral", "T9", "Shadow", 102, 5),
	silver_afterlife = set("silver_afterlife", "Mythral", "T9", "Metal", 106, 4),
	first_flame = set("first_flame", "Primordium", "T9", "Fire", 106, 5),
	heartblood = set("heartblood", "Primordium", "T9", "Water", 104, 5),
	end_of_ore = set("end_of_ore", "Primordium", "T9", "Metal", 108, 5),
}

local THEME_TYPES = {
	Fire = { "Fire", "Earth", "Shadow", "Crystal" },
	Earth = { "Earth", "Water", "Rock", "Fire" },
	Crystal = { "Crystal", "Shadow", "Electric", "Water" },
	Metal = { "Metal", "Rock", "Electric", "Fire" },
	Water = { "Water", "Crystal", "Earth", "Electric" },
	Rock = { "Rock", "Metal", "Earth", "Fire" },
	Electric = { "Electric", "Metal", "Crystal", "Fire" },
	Shadow = { "Shadow", "Crystal", "Fire", "Metal" },
}

MineCards.STAT_LABEL = {
	mineSpeed = "Damage",
	swingRate = "Swing rate",
	oreYield = "Blast",
	luck = "Luck",
	walkSpeed = "Walk speed",
	dirtBreak = "Dirt break",
	backpack = "Backpack",
	rareOre = "Rare ore",
	coinBonus = "Coins",
	gemFind = "Gems",
	chestLuck = "Chest luck",
	blastRadius = "Blast radius",
	autoMine = "Gem Find",
	echo = "Echo",
	zap = "Zap",
	luckyFind = "Lucky Block find",
	fossilFind = "Ore Finder",
	pulverize = "Pulverizer",
	scrap = "Scrap",
	coolant = "Coolant",
	shortFuse = "Short Fuse",
	reach = "Reach",
	blastRadius = "Blast radius",
}

MineCards.RARITY_RANK = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Mythic = 6,
	Divine = 7,
	Exotic = 8,
	-- Legacy ids from the seven-rung ladder. Kept so a card minted before the
	-- change still sorts and colours instead of falling to the bottom.
	HoloRare = 4,
	UltraRare = 5,
	HyperRare = 6,
	SecretRare = 8,
}

MineCards.RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic" }
MineCards.RARITY_ALIAS = {
	HoloRare = "Epic",
	UltraRare = "Legendary",
	HyperRare = "Mythic",
	SecretRare = "Exotic",
}

function MineCards.rarityName(id)
	return MineCards.RARITY_ALIAS[id] or id
end

MineCards.VARIANT_RANK = {
	Normal = 1,
	Shiny = 2,
	Golden = 3,
	Prism = 4,
	Rainbow = 5,
}

MineCards.RARITY_LABEL = {
	Common = "Common",
	Uncommon = "Uncommon",
	Rare = "Rare",
	Epic = "Epic",
	Legendary = "Legendary",
	Mythic = "Mythic",
	Divine = "Divine",
	Exotic = "Exotic",
	HoloRare = "Epic",
	UltraRare = "Legendary",
	HyperRare = "Mythic",
	SecretRare = "Exotic",
}

MineCards.STAT_ICON = {
	mineSpeed = "rbxassetid://77002713804879",
	swingRate = "rbxassetid://77002713804879",
	oreYield = "rbxassetid://86399574737815",
	luck = "rbxassetid://139097260161094",
	walkSpeed = "rbxassetid://76003180742188",
	dirtBreak = "rbxassetid://87394125218094",
	backpack = "rbxassetid://128710304092705",
	rareOre = "rbxassetid://138872018183448",
	coinBonus = "rbxassetid://86399574737815",
	gemFind = "rbxassetid://138872018183448",
	chestLuck = "rbxassetid://134681067199107",
	blastRadius = "rbxassetid://93749473690241",
	autoMine = "rbxassetid://75531475218305",
	echo = "rbxassetid://93749473690241",
	zap = "rbxassetid://93749473690241",
}

-- A role is what a card DOES, and between them they have to cover every stat
-- the game reads. These eight covered seven; the six below give the other six a
-- home, so nothing in MineStats.STATS is unreachable from a card.
local ROLES = {
	{ id = "striker", name = "Striker", p = "mineSpeed", s = "dirtBreak" },
	{ id = "hauler", name = "Hauler", p = "backpack", s = "coinBonus" },
	{ id = "seer", name = "Seer", p = "luck", s = "rareOre" },
	{ id = "smelter", name = "Smelter", p = "oreYield", s = "mineSpeed" },
	{ id = "courier", name = "Courier", p = "walkSpeed", s = "swingRate" },
	{ id = "burrower", name = "Burrower", p = "dirtBreak", s = "mineSpeed" },
	{ id = "prospector", name = "Prospector", p = "rareOre", s = "luck" },
	{ id = "titan", name = "Titan", p = "oreYield", s = "backpack" },
	{ id = "broker", name = "Broker", p = "coinBonus", s = "oreYield" },
	{ id = "assayer", name = "Assayer", p = "gemFind", s = "luck" },
	{ id = "keyfinder", name = "Keyfinder", p = "chestLuck", s = "luck" },
	{ id = "quickhand", name = "Quickhand", p = "swingRate", s = "mineSpeed" },
	{ id = "blaster", name = "Blaster", p = "blastRadius", s = "mineSpeed" },
	{ id = "zapper", name = "Zapper", p = "zap", s = "swingRate" },
	{ id = "tender", name = "Paydirt", p = "gemFind", s = "walkSpeed" },
}

-- Each type leans toward three roles, and the preferred list is what a card
-- actually rolls 72% of the time -- the uniform fallback clusters, so a role
-- that appears in no type's list is close to unreachable. That is why Broker and
-- Assayer had to be named here and not just added to ROLES.
local TYPE_ROLES = {
	Fire = { "striker", "blaster", "burrower" },
	Earth = { "burrower", "hauler", "titan" },
	Water = { "hauler", "courier", "assayer" },
	Rock = { "titan", "smelter", "broker" },
	Metal = { "smelter", "broker", "striker" },
	Electric = { "zapper", "quickhand", "courier" },
	Crystal = { "seer", "assayer", "prospector" },
	Shadow = { "keyfinder", "tender", "seer" },
}

--------------------------------------------------------------------------------
-- FAMILIES (a pet's type)
--
-- A family is a real boost, not flavour text. The old family table spoke the
-- game's first vocabulary -- Echo was the lightning stat back then, and Zap,
-- the stat that actually chains between blocks, did not exist yet. These read
-- off the CURRENT stat list.
--
-- Every number here is flat: what the card says is what the card does, on a
-- Common and on a Rainbow alike. The pet's own kit is the part that scales with
-- card power, so a better print is still a better pet -- but a new pet always
-- lands as a felt step up, which is the thing that went missing.
--------------------------------------------------------------------------------
local FAMILY = {
	Fire     = { name = "Forge Heart",  desc = "+22% Damage · +10% Dirt Break",   stats = { mineSpeed = 0.22, dirtBreak = 0.10 } },
	Earth    = { name = "Deep Roots",   desc = "+34% Dirt Break · +12% Backpack", stats = { dirtBreak = 0.34, backpack = 0.12 } },
	Water    = { name = "Undertow",     desc = "+8% Pulverizer · +20% Backpack",  stats = { pulverize = 0.08, backpack = 0.20 } },
	Rock     = { name = "Quarry Born",  desc = "+10% Blast · +18% Coin Bonus",    stats = { oreYield = 0.10, coinBonus = 0.18 } },
	Metal    = { name = "Forge Tempo",  desc = "+12% Swing Rate · +14% Damage",   stats = { swingRate = 0.12, mineSpeed = 0.14 } },
	Electric = { name = "Live Wire",    desc = "+9% Zap · +12% Swing Rate",       stats = { zap = 0.09, swingRate = 0.12 } },
	Crystal  = { name = "Facet Eye",    desc = "+28% Gem Find · +16% Luck",       stats = { gemFind = 0.28, luck = 0.16 } },
	Shadow   = { name = "Night Ledger", desc = "+24% Chest Luck · +18% Luck",     stats = { chestLuck = 0.24, luck = 0.18 } },
}

--------------------------------------------------------------------------------
-- TRAITS (one per print, stable forever)
--
-- Back as percentages. Dirt King used to break any dirt in one swing whatever
-- its HP, which defied the depth curve the whole game is paced against -- it is
-- a Dirt Break number now. Echo Strike is worth a slot again because Echo
-- itself changed: it strikes a DIFFERENT block and rerolls that block's procs,
-- and it can never proc itself (see Dig.procsAt in MineServer).
--
-- ORDER IS LOAD-BEARING. The trait is picked by hash off the print's index, so
-- reordering this list hands every pet in the game a different trait.
--------------------------------------------------------------------------------
local TRAITS = {
	{ id = "echoStrike", name = "Echo Strike", desc = "+10% Echo (a second block, its own procs)", stats = { echo = 0.10 } },
	{ id = "swiftPick", name = "Swift Pick", desc = "+18% Swing Rate", stats = { swingRate = 0.18 } },
	{ id = "packLord", name = "Pack Lord", desc = "+35% Backpack", stats = { backpack = 0.35 } },
	{ id = "dirtKing", name = "Dirt King", desc = "+45% Dirt Break", stats = { dirtBreak = 0.45 } },
	{ id = "fortune", name = "Fortune", desc = "+30% Luck", stats = { luck = 0.30 } },
	{ id = "afterimage", name = "Afterimage", desc = "+22% Walk Speed", stats = { walkSpeed = 0.22 } },
	{ id = "loneWolf", name = "Lone Wolf", desc = "+50% Damage while this is your only pet", solo = true, stats = { mineSpeed = 0.50 } },
	{ id = "squadBond", name = "Squad Bond", desc = "+9% Damage, Dirt Break, Luck, Blast and Rare Ore per other pet", squad = true,
		stats = { mineSpeed = 0.09, dirtBreak = 0.09, luck = 0.09, oreYield = 0.09, rareOre = 0.09 } },
	{ id = "veinSense", name = "Vein Sense", desc = "+28% Rare Ore", stats = { rareOre = 0.28 } },
	{ id = "heavyYield", name = "Heavy Yield", desc = "+12% Blast · -6% Walk Speed", stats = { oreYield = 0.12, walkSpeed = -0.06 } },
	{ id = "cartPush", name = "Cart Push", desc = "+18% Walk Speed · +16% Backpack", stats = { walkSpeed = 0.18, backpack = 0.16 } },
	{ id = "emberTempo", name = "Ember Tempo", desc = "+25% Damage · +12% Dirt Break", stats = { mineSpeed = 0.25, dirtBreak = 0.12 } },
}

local TRAIT_BY_ID = {}
for _, t in ipairs(TRAITS) do
	TRAIT_BY_ID[t.id] = t
end
MineCards.FAMILY = FAMILY
MineCards.TRAITS = TRAITS

local ROLE_BY_ID = {}
for _, role in ipairs(ROLES) do
	ROLE_BY_ID[role.id] = role
end

local PREFIX = {
	"Ember", "Storm", "Grove", "Prism", "Iron", "Tide", "Shade", "Bolt",
	"Moss", "Cinder", "Pearl", "Quartz", "Rivet", "Dawn", "Dusk", "Nova",
}
local SPECIES = {
	"Fox", "Drake", "Toad", "Stag", "Moth", "Crab", "Hawk", "Serpent",
	"Beetle", "Otter", "Golem", "Owl", "Ray", "Hound", "Sprite", "Wyrm",
}

local RARITY_THRESHOLDS = {
	{ pct = 0.52, id = "Common" },
	{ pct = 0.76, id = "Uncommon" },
	{ pct = 0.885, id = "Rare" },
	{ pct = 0.945, id = "Epic" },
	{ pct = 0.975, id = "Legendary" },
	{ pct = 0.992, id = "Mythic" },
}

local function hash01(a)
	local x = math.floor(a * 9973) % 100000
	return (x % 10000) / 10000
end

local function pick(list, seed)
	return list[math.floor(hash01(seed) * #list) + 1]
end

local function rarityFromIndex(index, cardCount, isSecret)
	-- The secret slots past the printed count are the Exotics.
	if isSecret then
		return "Exotic"
	end
	local pct = index / cardCount
	for _, row in ipairs(RARITY_THRESHOLDS) do
		if pct <= row.pct then
			return row.id
		end
	end
	return "Divine"
end

function MineCards.getSet(setId)
	return MineCards.SETS[setId]
end

function MineCards.typeOf(setId, index)
	local def = MineCards.SETS[setId]
	if not def then
		return "Crystal"
	end
	local isSecret = index > def.cardCount
	local rarityId = rarityFromIndex(index, def.cardCount, isSecret)
	local types = THEME_TYPES[def.theme] or THEME_TYPES.Crystal
	local typeId = types[(index % #types) + 1]
	if rarityId == "Mythic" or rarityId == "Divine" or rarityId == "Exotic" then
		typeId = def.theme
	end
	return typeId
end

function MineCards.getKit(setId, index)
	local typeId = MineCards.typeOf(setId, index)
	local seed = index * 131 + #setId * 17
	local prefer = TYPE_ROLES[typeId] or TYPE_ROLES.Crystal
	local role
	if hash01(seed + 3) < 0.72 then
		role = ROLE_BY_ID[prefer[math.floor(hash01(seed + 1) * #prefer) + 1]]
	end
	role = role or ROLES[math.floor(hash01(seed + 2) * #ROLES) + 1]
	local primaryBase = 0.08 + hash01(seed + 5) * 0.11
	-- This role used to roll Auto Mine. Gem Find is worth fewer points per
	-- percent, so the percent rises and the card stays the same power.
	if role.id == "tender" then
		primaryBase *= 2.5 / 1.8
	end
	local secondaryBase = 0.03 + hash01(seed + 6) * 0.06
	local trait = TRAITS[math.floor(hash01(seed + 9) * #TRAITS) + 1]
	return {
		family = FAMILY[MineCards.typeName(typeId)],
		roleId = role.id,
		roleName = role.name,
		typeId = typeId,
		primary = role.p,
		secondary = role.s,
		primaryBase = primaryBase,
		secondaryBase = secondaryBase,
		trait = trait,
	}
end

local ADDITIVE_STATS = { echo = true, zap = true, blastRadius = true, autoMine = true, oreYield = true, luckyFind = true, fossilFind = true, pulverize = true, scrap = true, coolant = true, shortFuse = true, reach = true }

local function addStat(b, key, amount)
	local ok, Stats = pcall(require, script.Parent:FindFirstChild("MineStats"))
	if ok and Stats and Stats.RUNE_ONLY and Stats.RUNE_ONLY[key] then
		return
	end
	if ADDITIVE_STATS[key] then
		b[key] = (b[key] or 0) + amount
	else
		b[key] = (b[key] or 1) + amount
	end
end

-- The family and trait a print carries. Both come from (setId, index), so a
-- pet's identity never shifts under it. Cards minted without an index (event
-- pets, some chest pets) hash their name instead.
function MineCards.familyTrait(card)
	if type(card) ~= "table" then
		return nil, nil
	end
	local typeId, seed
	if card.setId and card.index then
		typeId = MineCards.typeName(MineCards.typeOf(card.setId, card.index))
		seed = card.index * 131 + #tostring(card.setId) * 17
	else
		typeId = MineCards.typeName(card.typeId or "Crystal")
		local name, acc = tostring(card.name or ""), 0
		for i = 1, #name do
			acc += name:byte(i) * i
		end
		seed = acc
	end
	return typeId, TRAITS[math.floor(hash01(seed + 9) * #TRAITS) + 1]
end

function MineCards.family(typeId)
	return FAMILY[MineCards.typeName(typeId or "")]
end

function MineCards.applyFamily(b, typeId)
	local fam = MineCards.family(typeId)
	if not (b and fam) then
		return nil
	end
	for stat, amount in pairs(fam.stats) do
		addStat(b, stat, amount)
	end
	return fam
end

-- Conditional traits read the equipped count: Lone Wolf pays only while it is
-- your one pet, Squad Bond pays per OTHER pet standing beside it.
function MineCards.applyTrait(b, traitOrId, equippedCount)
	local t = type(traitOrId) == "table" and traitOrId or TRAIT_BY_ID[tostring(traitOrId or "")]
	if not (b and t) then
		return nil
	end
	local n = math.max(1, math.floor(tonumber(equippedCount) or 1))
	local scale = 1
	if t.solo then
		if n > 1 then
			return nil
		end
	elseif t.squad then
		scale = n - 1
		if scale <= 0 then
			return nil
		end
	end
	for stat, amount in pairs(t.stats) do
		addStat(b, stat, amount * scale)
	end
	return t
end

-- Both rails. Family and trait used to hang off the role path only, and every
-- one of the 322 named pets skips that path -- so no pet in the live game had
-- either, which is exactly why the team stopped feeling like a team.
function MineCards.applyIdentity(b, card, equippedCount)
	local typeId, trait = MineCards.familyTrait(card)
	return typeId, MineCards.applyFamily(b, typeId), MineCards.applyTrait(b, trait, equippedCount)
end

-- Card-face lines for the family and trait, including whether a conditional
-- trait is paying out right now.
function MineCards.identityLines(card, equippedCount)
	local typeId, trait = MineCards.familyTrait(card)
	local fam = MineCards.family(typeId)
	local out = {}
	if fam then
		table.insert(out, string.format("%s (%s)  %s", fam.name, typeId, fam.desc))
	end
	if trait then
		local n = math.max(1, math.floor(tonumber(equippedCount) or 1))
		local suffix = ""
		if trait.squad then
			suffix = n > 1
				and string.format("  (now +%d%% each)", math.floor((n - 1) * (trait.stats.mineSpeed or 0) * 100 + 0.5))
				or "  (needs a second pet)"
		elseif trait.solo then
			suffix = n > 1 and "  (off: you run more than one pet)" or "  (active)"
		end
		table.insert(out, string.format("%s  %s%s", trait.name, trait.desc, suffix))
	end
	return out, typeId, trait
end

local function lookupNamedBoosts(card)
	if not card or type(card.name) ~= "string" then
		return nil
	end
	-- MinePetBoosts is the set-in-stone spine; PackConfig mirrors it for chests.
	local okB, Boosts = pcall(require, script.Parent:FindFirstChild("MinePetBoosts"))
	if okB and Boosts and Boosts.boostsFor then
		local kit = Boosts.boostsFor(card.name, card.setId or card.setKey or card.packSet)
		if kit then
			return kit
		end
	end
	local ok, Packs = pcall(require, script.Parent:FindFirstChild("MinePackConfig"))
	if not ok or not Packs or not Packs.boostsFor then
		return nil
	end
	return Packs.boostsFor(card.name, card.setId or card.setKey or card.packSet)
end

local function applyNamedKit(b, kit, pow)
	pow = tonumber(pow) or 1
	local okS, Stats = pcall(require, script.Parent:FindFirstChild("MineStats"))
	if okS and Stats and Stats.withoutAutoMine then
		kit = Stats.withoutAutoMine(kit)
	end
	for stat, amount in pairs(kit) do
		if type(amount) == "number" and amount ~= 0 then
			addStat(b, stat, amount * pow)
		elseif type(amount) == "boolean" and amount then
			b[stat] = true
		end
	end
	return {
		named = true,
		roleName = "Named",
		roleId = "named",
		boosts = kit,
	}
end

-- Every stat MineStats.STATS can roll onto a kit has a seat here. It did not:
-- coinBonus, gemFind, chestLuck, blastRadius and autoMine were missing, so a pet
-- that granted one wrote a key the server then overwrote, and the pet did
-- nothing at all. If you add a stat to MineStats.STATS, add it here.
--
-- Multiplier stats start at 1 (1.00 = +0%). Additive ones start at 0.
function MineCards.emptyBoosts()
	return {
		-- multipliers
		mineSpeed = 1, luck = 1, walkSpeed = 1, dirtBreak = 1,
		backpack = 1, rareOre = 1, coinBonus = 1, gemFind = 1, chestLuck = 1,
		-- swingSec is a DURATION; kits grant swingRate, folded in by foldSwingRate.
		swingSec = 1,
		-- additive (oreYield = Blast % proc)
		echo = 0, zap = 0, blastRadius = 0, autoMine = 0, oreYield = 0, luckyFind = 0, fossilFind = 0, pulverize = 0,
		scrap = 0, coolant = 0, shortFuse = 0, reach = 0,
	}
end

-- Kits grant `swingRate` (swings per second); the game consumes `swingSec` (the
-- gap between swings). Adding a rate onto a duration key is how +20% swing rate
-- used to land on a field nothing read.
function MineCards.foldSwingRate(b)
	local rate = b.swingRate
	if rate and rate ~= 1 then
		b.swingSec = (b.swingSec or 1) / rate
		b.swingRate = nil
	end
	return b
end

function MineCards.applyKit(b, card, pow, equippedCount)
	if not card then
		return
	end
	if pow == nil then
		local okC, Cfg = pcall(require, script.Parent:FindFirstChild("MineConfig"))
		pow = (okC and Cfg and Cfg.cardPower and Cfg.cardPower(card)) or 1
	end
	pow = pow or 1
	local kit
	local named = lookupNamedBoosts(card)
	if named then
		kit = applyNamedKit(b, named, pow)
	elseif card.setId and card.index then
		kit = MineCards.getKit(card.setId, card.index)
		local function grant(stat, amount)
			if stat == "autoMine" then
				addStat(b, "gemFind", amount * (2.5 / 1.8))
			else
				addStat(b, stat, amount)
			end
		end
		grant(kit.primary, kit.primaryBase * pow)
		grant(kit.secondary, kit.secondaryBase * pow)
	else
		return nil
	end
	local typeId, fam, trait = MineCards.applyIdentity(b, card, equippedCount)
	if type(kit) == "table" then
		kit.typeId = kit.typeId or typeId
		kit.family = fam or kit.family
		kit.trait = trait or kit.trait
	end
	return kit
end

function MineCards.statLine(key, amount, pow)
	pow = pow or 1
	if key == "autoMine" then
		key = "gemFind"
		amount = amount * (2.5 / 1.8)
	end
	return string.format("%s  +%d%%", MineCards.STAT_LABEL[key] or key, math.floor(amount * pow * 100 + 0.5))
end

function MineCards.describe(card, pow)
	if not card then
		return nil, { "No kit" }
	end
	local named = lookupNamedBoosts(card)
	if named then
		local ok, Stats = pcall(require, script.Parent:FindFirstChild("MineStats"))
		local lines = {}
		local scaled = named
		local p = tonumber(pow) or 1
		if p ~= 1 then
			scaled = {}
			for stat, amount in pairs(named) do
				if type(amount) == "number" then
					scaled[stat] = amount * p
				else
					scaled[stat] = amount
				end
			end
		end
		if ok and Stats and Stats.withoutAutoMine then
			scaled = Stats.withoutAutoMine(scaled)
		end
		if ok and Stats and Stats.describe then
			for _, row in ipairs(Stats.describe(scaled)) do
				table.insert(lines, string.format("%s  %s", row.label, row.text))
			end
		else
			for stat, amount in pairs(scaled) do
				table.insert(lines, MineCards.statLine(stat, amount, 1))
			end
		end
		local typeId, trait = MineCards.familyTrait(card)
		for _, line in ipairs(MineCards.identityLines(card)) do
			table.insert(lines, line)
		end
		return { named = true, roleName = "Named", boosts = named, typeId = typeId,
			family = MineCards.family(typeId), trait = trait }, lines
	end
	if not card.setId then
		return nil, { "No kit" }
	end
	local kit = MineCards.getKit(card.setId, card.index)
	pow = pow or 1
	local lines = {
		MineCards.statLine(kit.primary, kit.primaryBase, pow),
		MineCards.statLine(kit.secondary, kit.secondaryBase, pow),
	}
	for _, line in ipairs(MineCards.identityLines(card)) do
		table.insert(lines, line)
	end
	return kit, lines
end

function MineCards.namedBoosts(card)
	return lookupNamedBoosts(card)
end

-- Kit budget points x rarity/variant/shiny/shadow/powerLevel.
-- This is the number "best pets" and the Boosts sort use.
function MineCards.boostScore(card)
	if type(card) ~= "table" then
		return 0
	end
	local pow = 1
	local okC, Cfg = pcall(require, script.Parent:FindFirstChild("MineConfig"))
	if okC and Cfg and Cfg.cardPower then
		pow = tonumber(Cfg.cardPower(card)) or 1
	end
	local kit = lookupNamedBoosts(card)
	if not kit and card.setId and card.index then
		local k = MineCards.getKit(card.setId, card.index)
		if k and k.primary then
			kit = {
				[k.primary] = k.primaryBase or 0,
				[k.secondary] = k.secondaryBase or 0,
			}
		end
	end
	local points = 0
	local okS, Stats = pcall(require, script.Parent:FindFirstChild("MineStats"))
	if kit and okS and Stats and Stats.valueOf then
		points = tonumber(Stats.valueOf(kit)) or 0
	end
	if points <= 0 then
		points = 1
	end
	return points * pow
end


-- Creature identity on the card face. Kits still key off stable `name`.
function MineCards.displayName(card)
	if type(card) ~= "table" then
		return tostring(card or "Pet")
	end
	local okB, Boosts = pcall(require, script.Parent:FindFirstChild("MinePetBoosts"))
	local animal = card.animal or card.animalName
	if (type(animal) ~= "string" or animal == "") and card.name then
		local ok, Packs = pcall(require, script.Parent:FindFirstChild("MinePackConfig"))
		if ok and Packs and Packs.CARD_BY_NAME and Packs.CARD_BY_NAME[card.name] then
			animal = Packs.CARD_BY_NAME[card.name].animal
		end
		if (type(animal) ~= "string" or animal == "") then
			local okR, Roster = pcall(require, script.Parent:FindFirstChild("MinePetRoster"))
			if okR and Roster and Roster.BY_NAME and Roster.BY_NAME[card.name] then
				animal = Roster.BY_NAME[card.name].animal
			end
		end
	end
	local view = { name = card.name, animal = animal }
	if okB and Boosts and Boosts.displayName then
		return Boosts.displayName(view)
	end
	return animal or card.name or "Pet"
end

function MineCards.subtitleName(card)
	if type(card) ~= "table" then
		return nil
	end
	local title = MineCards.displayName(card)
	local name = card.name
	if type(name) == "string" and title ~= name then
		return name
	end
	return nil
end

function MineCards.getCard(setId, index)
	local def = MineCards.SETS[setId]
	if not def then
		return nil
	end
	local isSecret = index > def.cardCount
	if isSecret and (index - def.cardCount) > def.secretCount then
		return nil
	end
	local rarityId = rarityFromIndex(index, def.cardCount, isSecret)
	local typeId = MineCards.typeOf(setId, index)
	local kit = MineCards.getKit(setId, index)
	local name = pick(PREFIX, index * 17.3 + #setId) .. " " .. pick(SPECIES, index * 9.1 + #setId * 3)
	return {
		setId = setId,
		index = index,
		cardKey = string.format("%s#%03d", setId, index),
		name = name,
		rarityId = rarityId,
		typeId = typeId,
		roleName = kit.roleName,
		kind = "Unit",
		setName = def.displayName,
	}
end

function MineCards.indicesOfRarity(setId, rarityId)
	local def = MineCards.SETS[setId]
	if not def then
		return {}
	end
	local out = {}
	local maxIndex = def.cardCount + def.secretCount
	for i = 1, maxIndex do
		local card = MineCards.getCard(setId, i)
		if card and card.rarityId == rarityId then
			table.insert(out, i)
		end
	end
	return out
end

local function weighted(rows, r)
	local total = 0
	for _, row in ipairs(rows) do
		total += row.weight
	end
	local t = r * total
	for _, row in ipairs(rows) do
		t -= row.weight
		if t <= 0 then
			return row.rarity
		end
	end
	return rows[#rows].rarity
end

--[[
	EVERY SLOT IS A HIT SLOT.

	A pack used to roll slots 1 and 2 off FILLER -- Common 82 / Uncommon 17 /
	Rare 1 -- and only slot 3 off the real table. Two thirds of every pack was
	therefore decided before it was opened, and the player learned to ignore the
	first two cards. That is the opposite of what a pack should feel like.

	Now every slot rolls the same table, so any card can be the one. Three times
	as many chances at a hit would be three times the hits, so the hit rungs are
	divided by SOFTEN and the freed weight goes back into Common and Uncommon in
	their own ratio. The arithmetic is deliberate: with SOFTEN equal to the card
	count of a standard pack, the EXPECTED number of Epics (or Legendaries, or
	Exotics) per pack is unchanged -- what changes is that the excitement is
	spread across the whole pack instead of being parked in the last slot.

	FILLER is left in place; it is still referenced by older callers and is the
	honest record of what the first two slots used to be.
]]
MineCards.SLOT_SOFTEN = 3

--[[
	The real per-slot odds, as percentages.

	One source of truth: rollPack draws from this, and the pack inspector prints
	it. A displayed number that is computed separately from the number that
	rolls is a number that will eventually be wrong.

	The HIT rows already sum to 100, and softening only moves weight between
	rungs, so these come out as percentages with no extra normalising.
]]
function MineCards.slotOdds(tier)
	local base = MineCards.HIT[tier] or MineCards.HIT.T1
	local soften = MineCards.SLOT_SOFTEN
	local fillerTotal, freed = 0, 0
	for _, row in ipairs(base) do
		if row.rarity == "Common" or row.rarity == "Uncommon" then
			fillerTotal += row.weight
		end
	end
	local rows = {}
	for _, row in ipairs(base) do
		local keep = row.weight
		if row.rarity ~= "Common" and row.rarity ~= "Uncommon" then
			keep = row.weight / soften
			freed += row.weight - keep
		end
		table.insert(rows, { rarity = row.rarity, weight = keep })
	end
	if fillerTotal > 0 then
		for _, row in ipairs(rows) do
			if row.rarity == "Common" or row.rarity == "Uncommon" then
				-- Split what the hit rungs gave back the way those two already
				-- sat relative to each other.
				local share = (base[row.rarity == "Common" and 1 or 2].weight) / fillerTotal
				row.weight += freed * share
			end
		end
	end
	return rows
end

-- `count` is how many slots this pack pays. It used to be hardcoded to 3, and
-- openPack then CYCLED the three results to fill a six- or eight-card pack --
-- so a Hopper handed you the same three cards twice.
function MineCards.rollPack(setId, rng, count)
	local def = MineCards.SETS[setId]
	if not def then
		setId = "dragons_dawn"
		def = MineCards.SETS[setId]
	end
	local odds = MineCards.slotOdds(def.tier)
	local cards = {}
	for _ = 1, math.max(1, math.floor(tonumber(count) or 3)) do
		local rarity = weighted(odds, rng:NextNumber())
		local pool = MineCards.indicesOfRarity(setId, rarity)
		if #pool == 0 then
			pool = MineCards.indicesOfRarity(setId, "Common")
		end
		local index = pool[rng:NextInteger(1, math.max(1, #pool))]
		table.insert(cards, MineCards.getCard(setId, index))
	end
	return cards
end

MineCards.TYPE_COLOR = {
	Fire = Color3.fromRGB(255, 110, 70),
	Water = Color3.fromRGB(70, 170, 255),
	Earth = Color3.fromRGB(90, 190, 90),
	Rock = Color3.fromRGB(170, 140, 100),
	Metal = Color3.fromRGB(180, 190, 210),
	Electric = Color3.fromRGB(255, 220, 70),
	Crystal = Color3.fromRGB(190, 120, 255),
	-- Legacy: cards minted before the merge still carry typeId "Mystic", so it
	-- keeps a colour and resolves to Crystal through TYPE_ALIAS.
	Mystic = Color3.fromRGB(190, 120, 255),
	Shadow = Color3.fromRGB(90, 70, 140),
}

-- Old saves still say "Mystic". Everything that shows a type to a player goes
-- through typeName, so nothing has to be rewritten on disk.
MineCards.TYPE_ALIAS = { Mystic = "Crystal" }

function MineCards.typeName(id)
	return MineCards.TYPE_ALIAS[id] or id
end

MineCards.RARITY_COLOR = {
	Common = Color3.fromRGB(170, 170, 170),
	Uncommon = Color3.fromRGB(85, 255, 127),
	Rare = Color3.fromRGB(85, 170, 255),
	Epic = Color3.fromRGB(170, 85, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
	Mythic = Color3.fromRGB(85, 220, 255),
	Divine = Color3.fromRGB(255, 245, 160),
	Exotic = Color3.fromRGB(255, 55, 55),
	HoloRare = Color3.fromRGB(170, 85, 255),
	UltraRare = Color3.fromRGB(255, 170, 0),
	HyperRare = Color3.fromRGB(85, 220, 255),
	SecretRare = Color3.fromRGB(255, 55, 55),
}

return MineCards
