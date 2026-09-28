-- MineEventHorizonPets / MineEHPets
-- Event Horizon roster: Matter+/Matter- canonical (no Horizon+/- display).
-- Budgets Common25..Exotic380. Soft spread guidance. No magnitude clamps on pet kits.
local MineEventHorizonPets = {}
MineEventHorizonPets.SET_IDS = { "genesis_spark", "first_light", "proto_ore" }
MineEventHorizonPets.MINE_ID = "bigbang"

MineEventHorizonPets.NAME_ALIASES = {
	["Horizon+"] = "Matter+",
	["Horizon-"] = "Matter-",
	["horizon_plus"] = "Matter+",
	["horizon_minus"] = "Matter-",
	["Albert Horizontein"] = "Albert Minestein",
	["Albert Minestine"] = "Albert Minestein",
	["Matter(+)"] = "Matter+",
	["Matter(-)"] = "Matter-",
}

MineEventHorizonPets.BUDGET = {
	Common = 25, Uncommon = 48, Rare = 60, Epic = 90,
	Legendary = 125, Mythic = 190, Divine = 275, Exotic = 380,
}

-- Soft spread: Common-Rare 2-3, Epic-Legendary 1-3, Mythic 1-4, Divine 1-5, Exotic 1-6
MineEventHorizonPets.PET_BOOSTS = {
	["Cosmo"] = { backpack = 1.36, walkSpeed = 1.06, luck = 0.4725, chestLuck = 0.43 }, -- 379.7 pts / 4 stats
	["Matter+"] = { luck = 0.3801, gemFind = 0.475, chestLuck = 0.3109, backpack = 1.368, coinBonus = 0.665, walkSpeed = 1.9 }, -- 380.0 pts / 6 stats
	["Matter-"] = { blastRadius = 0.2, mineSpeed = 0.8, dirtBreak = 1.2, swingRate = 0.4, coinBonus = 0.2 }, -- 380.0 pts / 6 stats
	["Albert Minestein"] = { gemFind = 1.1875, luck = 0.9501 }, -- 379.9 pts / 2 stats
	["Accretia"] = { blastRadius = 0.206, mineSpeed = 0.963, swingRate = 0.393 }, -- 274.9 pts / 3 stats
	["Singuluna"] = { luck = 0.6188, chestLuck = 0.437, rareOre = 0.306 }, -- 275.0 pts / 3 stats
	["Quasarin"] = { zap = 0.495, swingRate = 0.688 }, -- 275.0 pts / 3 stats
	["Photonna"] = { backpack = 1.76, luck = 0.3163, oreYield = 0.2238, gemFind = 0.1903 }, -- 274.9 pts / 3 stats
	["Gravpaw"] = { dirtBreak = 2.063, mineSpeed = 0.963, oreYield = 0.458 }, -- 275.0 pts / 3 stats
	["Relativox"] = { swingRate = 0.884, dirtBreak = 1.604, mineSpeed = 0.55 }, -- 275.0 pts / 3 stats
	["Nebulisk"] = { gemFind = 0.5348, luck = 0.2753 }, -- 275.2 pts / 3 stats
	["Crystalith"] = { rareOre = 0.688, gemFind = 0.602, oreYield = 0.458 }, -- 275.1 pts / 3 stats
	["Bangcub"] = { blastRadius = 0.143, mineSpeed = 0.665, swingRate = 0.271 }, -- 190.2 pts / 3 stats
	["Eventide"] = { luck = 0.4275, chestLuck = 0.302, rareOre = 0.211 }, -- 189.9 pts / 3 stats
	["Pulsarina"] = { zap = 0.342, swingRate = 0.475 }, -- 190.1 pts / 3 stats
	["Moonshear"] = { backpack = 1.221, walkSpeed = 0.739, coinBonus = 0.475 }, -- 190.0 pts / 3 stats
	["Craterjaw"] = { dirtBreak = 1.425, mineSpeed = 0.665, oreYield = 0.317 }, -- 190.0 pts / 3 stats
	["Frosthole"] = { swingRate = 0.611, dirtBreak = 1.108, mineSpeed = 0.38 }, -- 190.0 pts / 3 stats
	["Echoflare"] = { gemFind = 0.3694, luck = 0.1898 }, -- 189.9 pts / 3 stats
	["Gemnova"] = { rareOre = 0.475, gemFind = 0.416, oreYield = 0.317 }, -- 190.1 pts / 3 stats
	["Oreproto"] = { coinBonus = 1.069, oreYield = 0.554, backpack = 0.543 }, -- 190.0 pts / 3 stats
	["Starloom"] = { backpack = 1.221, oreYield = 0.554, walkSpeed = 0.422 }, -- 189.9 pts / 3 stats
	["Diskflare"] = { blastRadius = 0.129, mineSpeed = 0.475 }, -- 124.9 pts / 2 stats
	["Vantail"] = { luck = 0.3878, chestLuck = 0.216 }, -- 125.1 pts / 2 stats
	["Sparkorbit"] = { zap = 0.225, swingRate = 0.313 }, -- 125.0 pts / 3 stats
	["Tidewell"] = { backpack = 1.107, walkSpeed = 0.528 }, -- 125.0 pts / 2 stats
	["Faultstar"] = { dirtBreak = 1.292, mineSpeed = 0.475 }, -- 125.0 pts / 2 stats
	["Chillaxis"] = { swingRate = 0.554, dirtBreak = 0.792 }, -- 125.1 pts / 2 stats
	["Warpup"] = { gemFind = 0.243, luck = 0.1253 }, -- 125.2 pts / 3 stats
	["Prismoon"] = { rareOre = 0.431, gemFind = 0.297 }, -- 125.1 pts / 2 stats
	["Coinbang"] = { backpack = 0.95, coinBonus = 0.7688, gemFind = 0.0889 }, -- 125.0 pts / 2 stats
	["Bloomstar"] = { oreYield = 0.646, backpack = 0.679 }, -- 125.1 pts / 2 stats
	["Sparkwisp"] = { mineSpeed = 0.558, dirtBreak = 0.57 }, -- 90.0 pts / 2 stats
	["Shadechip"] = { luck = 0.279, chestLuck = 0.155 }, -- 89.9 pts / 2 stats
	["Zipquark"] = { zap = 0.223, swingRate = 0.244 }, -- 90.0 pts / 2 stats
	["Bagtide"] = { backpack = 0.797, walkSpeed = 0.38 }, -- 90.0 pts / 2 stats
	["Dustwell"] = { dirtBreak = 0.93, mineSpeed = 0.342 }, -- 90.0 pts / 2 stats
	["Icering"] = { swingRate = 0.399, dirtBreak = 0.57 }, -- 90.1 pts / 2 stats
	["Paralite"] = { oreYield = 0.0856 }, -- 90.1 pts / 2 stats
	["Glimore"] = { rareOre = 0.31, gemFind = 0.214 }, -- 90.0 pts / 2 stats
	["Smeltbit"] = { coinBonus = 0.698, oreYield = 0.285 }, -- 90.0 pts / 2 stats
	["Leafnova"] = { oreYield = 0.465, backpack = 0.489 }, -- 90.0 pts / 2 stats
	["Emberbit"] = { mineSpeed = 0.372, dirtBreak = 0.38 }, -- 60.0 pts / 2 stats
	["Duskchip"] = { luck = 0.186, chestLuck = 0.104 }, -- 60.1 pts / 2 stats
	["Boltseed"] = { zap = 0.149, swingRate = 0.163 }, -- 60.0 pts / 2 stats
	["Puddleorb"] = { backpack = 0.531, walkSpeed = 0.253 }, -- 59.9 pts / 2 stats
	["Crateroo"] = { dirtBreak = 0.62, mineSpeed = 0.228 }, -- 60.0 pts / 2 stats
	["Snowaxis"] = { swingRate = 0.266, dirtBreak = 0.38 }, -- 60.0 pts / 2 stats
	["Echopea"] = { luck = 0.114 }, -- 60.0 pts / 2 stats
	["Shardlet"] = { rareOre = 0.207, gemFind = 0.143 }, -- 60.1 pts / 2 stats
	["Coinseed"] = { coinBonus = 0.465, oreYield = 0.19 }, -- 60.0 pts / 2 stats
	["Petalstar"] = { oreYield = 0.31, backpack = 0.326 }, -- 60.0 pts / 2 stats
	["Ashorbit"] = { mineSpeed = 0.372, dirtBreak = 0.38 }, -- 60.0 pts / 2 stats
	["Nightbag"] = { luck = 0.186, backpack = 0.326 }, -- 60.0 pts / 2 stats
	["Zipmite"] = { zap = 0.149 }, -- 60.0 pts / 2 stats
	["Kelporb"] = { backpack = 0.531, coinBonus = 0.285 }, -- 60.0 pts / 2 stats
	["Dirtmoon"] = { dirtBreak = 0.62, oreYield = 0.19 }, -- 60.0 pts / 2 stats
	["Sparkitten"] = { mineSpeed = 0.298, dirtBreak = 0.304 }, -- 48.0 pts / 2 stats
	["Gloomouse"] = { luck = 0.1485, chestLuck = 0.083 }, -- 48.0 pts / 2 stats
	["Zippup"] = { zap = 0.119, swingRate = 0.13 }, -- 48.0 pts / 2 stats
	["Bubbleorb"] = { backpack = 0.425, walkSpeed = 0.203 }, -- 48.0 pts / 2 stats
	["Dustnip"] = { dirtBreak = 0.496, mineSpeed = 0.182 }, -- 48.0 pts / 2 stats
	["Chillbit"] = { swingRate = 0.213, dirtBreak = 0.304 }, -- 48.1 pts / 2 stats
	["Peeporbit"] = { coinBonus = 0.2282 }, -- 48.0 pts / 2 stats
	["Shimmerbit"] = { rareOre = 0.165, gemFind = 0.114 }, -- 47.9 pts / 2 stats
	["Tinyclink"] = { backpack = 0.3648, coinBonus = 0.1438, gemFind = 0.1014 }, -- 48.0 pts / 2 stats
	["Cloverbit"] = { backpack = 0.425, oreYield = 0.152 }, -- 48.0 pts / 2 stats
	["Speck"] = { dirtBreak = 0.258, mineSpeed = 0.095 }, -- 25.0 pts / 2 stats
	["Glowpuff"] = { luck = 0.0473 }, -- 25.1 pts / 2 stats
	["Dustmite"] = { oreYield = 0.129, backpack = 0.136 }, -- 25.0 pts / 2 stats
	["Tinyspark"] = { zap = 0.062, swingRate = 0.068 }, -- 25.0 pts / 2 stats
	["Barybub"] = { backpack = 0.221, walkSpeed = 0.106 }, -- 25.0 pts / 2 stats
	["Softphoton"] = { swingRate = 0.111, dirtBreak = 0.158 }, -- 25.0 pts / 2 stats
}

MineEventHorizonPets.ROSTER = {
	{ name = "Cosmo", id = "cosmo", animal = "Astronaut Dog", type = "Space", tier = "Exotic" },
	{ name = "Matter+", id = "matter_plus", animal = "White Box", type = "Crystal", tier = "Exotic" },
	{ name = "Matter-", id = "matter_minus", animal = "Black Box", type = "Shadow", tier = "Exotic" },
	{ name = "Albert Minestein", id = "albert_minestein", animal = "Albert Einstein", type = "Crystal", tier = "Exotic" },
	{ name = "Accretia", id = "accretia", animal = "Accretion Fox", type = "Fire", tier = "Divine" },
	{ name = "Singuluna", id = "singuluna", animal = "Singularity Cat", type = "Shadow", tier = "Divine" },
	{ name = "Quasarin", id = "quasarin", animal = "Quasar Hawk", type = "Electric", tier = "Divine" },
	{ name = "Photonna", id = "photonna", animal = "Photon Bunny", type = "Grass", tier = "Divine" },
	{ name = "Gravpaw", id = "gravpaw", animal = "Gravity Bear", type = "Ground", tier = "Divine" },
	{ name = "Relativox", id = "relativox", animal = "Relativity Wolf", type = "Frost", tier = "Divine" },
	{ name = "Nebulisk", id = "nebulisk", animal = "Nebula Serpent", type = "Space", tier = "Divine" },
	{ name = "Crystalith", id = "crystalith", animal = "Proto Crystal Drake", type = "Crystal", tier = "Divine" },
	{ name = "Bangcub", id = "bangcub", animal = "Big Bang Cub", type = "Fire", tier = "Mythic" },
	{ name = "Eventide", id = "eventide", animal = "Eventide Owl", type = "Shadow", tier = "Mythic" },
	{ name = "Pulsarina", id = "pulsarina", animal = "Pulsar Finch", type = "Electric", tier = "Mythic" },
	{ name = "Moonshear", id = "moonshear", animal = "Moon Sheep", type = "Water", tier = "Mythic" },
	{ name = "Craterjaw", id = "craterjaw", animal = "Crater Drake", type = "Ground", tier = "Mythic" },
	{ name = "Frosthole", id = "frosthole", animal = "Black Ice Fox", type = "Frost", tier = "Mythic" },
	{ name = "Echoflare", id = "echoflare", animal = "Echo Flare Pup", type = "Space", tier = "Mythic" },
	{ name = "Gemnova", id = "gemnova", animal = "Nova Gem Cat", type = "Crystal", tier = "Mythic" },
	{ name = "Oreproto", id = "oreproto", animal = "Proto Ore Beetle", type = "Metal", tier = "Mythic" },
	{ name = "Starloom", id = "starloom", animal = "Starloom Lamb", type = "Grass", tier = "Mythic" },
	{ name = "Diskflare", id = "diskflare", animal = "Disk Flare Lizard", type = "Fire", tier = "Legendary" },
	{ name = "Vantail", id = "vantail", animal = "Vanta Squirrel", type = "Shadow", tier = "Legendary" },
	{ name = "Sparkorbit", id = "sparkorbit", animal = "Orbit Spark Mouse", type = "Electric", tier = "Legendary" },
	{ name = "Tidewell", id = "tidewell", animal = "Gravity Otter", type = "Water", tier = "Legendary" },
	{ name = "Faultstar", id = "faultstar", animal = "Star Armadillo", type = "Ground", tier = "Legendary" },
	{ name = "Chillaxis", id = "chillaxis", animal = "Axis Penguin", type = "Frost", tier = "Legendary" },
	{ name = "Warpup", id = "warpup", animal = "Warp Puppy", type = "Space", tier = "Legendary" },
	{ name = "Prismoon", id = "prismoon", animal = "Moon Prism Cat", type = "Crystal", tier = "Legendary" },
	{ name = "Coinbang", id = "coinbang", animal = "Bang Coin Crab", type = "Metal", tier = "Legendary" },
	{ name = "Bloomstar", id = "bloomstar", animal = "Starflower Deer", type = "Grass", tier = "Legendary" },
	{ name = "Sparkwisp", id = "sparkwisp", animal = "Spark Wisp Fox", type = "Fire", tier = "Epic" },
	{ name = "Shadechip", id = "shadechip", animal = "Shade Chip Bat", type = "Shadow", tier = "Epic" },
	{ name = "Zipquark", id = "zipquark", animal = "Quark Ferret", type = "Electric", tier = "Epic" },
	{ name = "Bagtide", id = "bagtide", animal = "Bag Tide Seal", type = "Water", tier = "Epic" },
	{ name = "Dustwell", id = "dustwell", animal = "Dust Well Mole", type = "Ground", tier = "Epic" },
	{ name = "Icering", id = "icering", animal = "Ice Ring Cat", type = "Frost", tier = "Epic" },
	{ name = "Paralite", id = "paralite", animal = "Parallax Lite Pup", type = "Space", tier = "Epic" },
	{ name = "Glimore", id = "glimore", animal = "Glim Ore Bunny", type = "Crystal", tier = "Epic" },
	{ name = "Smeltbit", id = "smeltbit", animal = "Smelt Bit Mouse", type = "Metal", tier = "Epic" },
	{ name = "Leafnova", id = "leafnova", animal = "Nova Leaf Turtle", type = "Grass", tier = "Epic" },
	{ name = "Emberbit", id = "emberbit", animal = "Ember Bit Chick", type = "Fire", tier = "Rare" },
	{ name = "Duskchip", id = "duskchip", animal = "Dusk Chip Crow", type = "Shadow", tier = "Rare" },
	{ name = "Boltseed", id = "boltseed", animal = "Bolt Seed Mouse", type = "Electric", tier = "Rare" },
	{ name = "Puddleorb", id = "puddleorb", animal = "Orb Puddle Frog", type = "Water", tier = "Rare" },
	{ name = "Crateroo", id = "crateroo", animal = "Crater Roo", type = "Ground", tier = "Rare" },
	{ name = "Snowaxis", id = "snowaxis", animal = "Snow Axis Fox", type = "Frost", tier = "Rare" },
	{ name = "Echopea", id = "echopea", animal = "Echo Pea Owl", type = "Space", tier = "Rare" },
	{ name = "Shardlet", id = "shardlet", animal = "Shardlet Crab", type = "Crystal", tier = "Rare" },
	{ name = "Coinseed", id = "coinseed", animal = "Coin Seed Chick", type = "Metal", tier = "Rare" },
	{ name = "Petalstar", id = "petalstar", animal = "Star Petal Bunny", type = "Grass", tier = "Rare" },
	{ name = "Ashorbit", id = "ashorbit", animal = "Ash Orbit Lizard", type = "Fire", tier = "Rare" },
	{ name = "Nightbag", id = "nightbag", animal = "Night Bag Bat", type = "Shadow", tier = "Rare" },
	{ name = "Zipmite", id = "zipmite", animal = "Zip Mite", type = "Electric", tier = "Rare" },
	{ name = "Kelporb", id = "kelporb", animal = "Kelp Orb Otter", type = "Water", tier = "Rare" },
	{ name = "Dirtmoon", id = "dirtmoon", animal = "Moon Dirt Pig", type = "Ground", tier = "Rare" },
	{ name = "Sparkitten", id = "sparkitten", animal = "Spark Kitten", type = "Fire", tier = "Uncommon" },
	{ name = "Gloomouse", id = "gloomouse", animal = "Gloom Mouse", type = "Shadow", tier = "Uncommon" },
	{ name = "Zippup", id = "zippup", animal = "Zip Puppy", type = "Electric", tier = "Uncommon" },
	{ name = "Bubbleorb", id = "bubbleorb", animal = "Bubble Orb Axolotl", type = "Water", tier = "Uncommon" },
	{ name = "Dustnip", id = "dustnip", animal = "Dust Nip Hamster", type = "Ground", tier = "Uncommon" },
	{ name = "Chillbit", id = "chillbit", animal = "Chill Bit Penguin", type = "Frost", tier = "Uncommon" },
	{ name = "Peeporbit", id = "peeporbit", animal = "Orbit Peep Chick", type = "Space", tier = "Uncommon" },
	{ name = "Shimmerbit", id = "shimmerbit", animal = "Shimmer Bit Gecko", type = "Crystal", tier = "Uncommon" },
	{ name = "Tinyclink", id = "tinyclink", animal = "Tiny Clink Mouse", type = "Metal", tier = "Uncommon" },
	{ name = "Cloverbit", id = "cloverbit", animal = "Clover Bit Lamb", type = "Grass", tier = "Uncommon" },
	{ name = "Speck", id = "speck", animal = "Speck Mouse", type = "Ground", tier = "Common" },
	{ name = "Glowpuff", id = "glowpuff", animal = "Glowpuff Cloud Pup", type = "Space", tier = "Common" },
	{ name = "Dustmite", id = "dustmite", animal = "Cosmic Dustmite", type = "Grass", tier = "Common" },
	{ name = "Tinyspark", id = "tinyspark", animal = "Tinyspark Beetle", type = "Electric", tier = "Common" },
	{ name = "Barybub", id = "barybub", animal = "Bubble Tadpole", type = "Water", tier = "Common" },
	{ name = "Softphoton", id = "softphoton", animal = "Photon Kitten", type = "Frost", tier = "Common" },
}

function MineEventHorizonPets.resolveName(name)
	return MineEventHorizonPets.NAME_ALIASES[name] or name
end

function MineEventHorizonPets.boostsFor(name)
	name = MineEventHorizonPets.resolveName(name)
	return MineEventHorizonPets.PET_BOOSTS[name]
end

function MineEventHorizonPets.applyToPackConfig(MinePackConfig)
	if not MinePackConfig then return end
	MinePackConfig.PET_BOOSTS = MinePackConfig.PET_BOOSTS or { X = {}, Y = {} }
	MinePackConfig.PET_BOOSTS.EH = MinePackConfig.PET_BOOSTS.EH or {}
	MinePackConfig.PET_BOOSTS.X = MinePackConfig.PET_BOOSTS.X or {}
	MinePackConfig.PET_BOOSTS.Y = MinePackConfig.PET_BOOSTS.Y or {}
	MinePackConfig.SET_CARDS = MinePackConfig.SET_CARDS or {}
	local cards = {}
	for _, row in ipairs(MineEventHorizonPets.ROSTER) do
		table.insert(cards, {
			name = row.name,
			animal = row.animal,
			type = row.type,
			rarity = row.tier,
			tier = row.tier,
			id = row.id,
			setId = "EH",
		})
	end
	MinePackConfig.SET_CARDS.EH = cards
	for name, kit in pairs(MineEventHorizonPets.PET_BOOSTS) do
		MinePackConfig.PET_BOOSTS.EH[name] = kit
		if MinePackConfig.PET_BOOSTS.X[name] == nil then MinePackConfig.PET_BOOSTS.X[name] = kit end
		if MinePackConfig.PET_BOOSTS.Y[name] == nil then MinePackConfig.PET_BOOSTS.Y[name] = kit end
	end
end

MineEventHorizonPets.PETS = {}
for _, row in ipairs(MineEventHorizonPets.ROSTER) do
	table.insert(MineEventHorizonPets.PETS, {
		name = row.name, id = row.id, animal = row.animal, type = row.type,
		rarity = row.tier, tier = row.tier,
	})
end
MineEventHorizonPets.BY_NAME = {}
MineEventHorizonPets.BY_RARITY = {}
for _, pet in ipairs(MineEventHorizonPets.PETS) do
	MineEventHorizonPets.BY_NAME[pet.name] = pet
	MineEventHorizonPets.BY_RARITY[pet.rarity] = MineEventHorizonPets.BY_RARITY[pet.rarity] or {}
	table.insert(MineEventHorizonPets.BY_RARITY[pet.rarity], pet)
end
for oldName, newName in pairs(MineEventHorizonPets.NAME_ALIASES) do
	if MineEventHorizonPets.BY_NAME[newName] then
		MineEventHorizonPets.BY_NAME[oldName] = MineEventHorizonPets.BY_NAME[newName]
	end
end
function MineEventHorizonPets.count()
	return #MineEventHorizonPets.PETS
end
function MineEventHorizonPets.mergeIntoRoster(MinePetRoster)
	if not MinePetRoster or not MinePetRoster.PETS then return end
	MinePetRoster.NAME_ALIASES = MinePetRoster.NAME_ALIASES or {}
	for oldName, newName in pairs(MineEventHorizonPets.NAME_ALIASES) do
		MinePetRoster.NAME_ALIASES[oldName] = newName
	end
	local have = {}
	for _, p in ipairs(MinePetRoster.PETS) do have[p.name] = true end
	for _, row in ipairs(MineEventHorizonPets.ROSTER) do
		if not have[row.name] then
			table.insert(MinePetRoster.PETS, {
				name = row.name, animal = row.animal, tier = row.tier, tierVia = "eh",
			})
		else
			for _, p in ipairs(MinePetRoster.PETS) do
				if p.name == row.name then p.tier = row.tier; p.animal = row.animal end
			end
		end
	end
end
return MineEventHorizonPets
