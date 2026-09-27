--[[
	MineFossilEconomy — identity rarity + piece sink for the new fossil loop.

	Craft / recipe progress costs PIECES_NEEDED.
	Lower identity rarity yields more pieces when broken down / deposited.
	Grade (quality) stays separate and is rolled at creation time.
	Fossil packs: 3 pulls, duplicates allowed.
]]

local MineFossilEconomy = {}

MineFossilEconomy.PIECES_NEEDED = 100

MineFossilEconomy.RARITIES = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Divine",
	"Exotic",
}

MineFossilEconomy.PIECES_BY_RARITY = {
	Common = 25,
	Uncommon = 20,
	Rare = 15,
	Epic = 10,
	Legendary = 5,
	Mythic = 4,
	Divine = 3,
	Exotic = 1,
}

MineFossilEconomy.PACK_PULLS = 3
MineFossilEconomy.ALLOW_DUPES = true

function MineFossilEconomy.piecesFor(rarity)
	return MineFossilEconomy.PIECES_BY_RARITY[rarity] or 1
end

function MineFossilEconomy.needed()
	return MineFossilEconomy.PIECES_NEEDED
end

function MineFossilEconomy.normalizeRarity(rarity)
	if MineFossilEconomy.PIECES_BY_RARITY[rarity] then
		return rarity
	end
	return "Common"
end

--[[
	Weighted rarity from a pack odds table (Common..Exotic keys).
]]
function MineFossilEconomy.rollRarity(odds, rng)
	rng = rng or Random.new()
	local total = 0
	for _, id in ipairs(MineFossilEconomy.RARITIES) do
		total += math.max(0, tonumber((odds or {})[id]) or 0)
	end
	if total <= 0 then
		return "Common"
	end
	local roll = rng:NextNumber() * total
	local acc = 0
	for _, id in ipairs(MineFossilEconomy.RARITIES) do
		acc += math.max(0, tonumber((odds or {})[id]) or 0)
		if roll <= acc then
			return id
		end
	end
	return "Common"
end

return MineFossilEconomy
