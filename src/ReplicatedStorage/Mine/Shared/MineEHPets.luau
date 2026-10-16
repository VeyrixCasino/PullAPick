-- MineEventHorizonPets / MineEHPets
-- Event Horizon's 73 pets: their roster and names (Matter+/Matter- canonical).
-- Their KITS are not here: every named pet's kit is MineZonePets.KITS, where
-- Event Horizon sits on the ladder as zone 11 (tools/gen/zone-pets.js).
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
