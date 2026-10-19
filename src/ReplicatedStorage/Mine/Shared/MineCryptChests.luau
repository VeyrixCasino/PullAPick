--[[
	MineCryptChests -- the Candy Crypt's eight chests: which rank spawns where,
	and what each pays. Pure: MineCrypt (server) rolls and grants; a screen and
	tools/gen/crypt-doc.js read the same numbers.

	Owner, 2026-10-19 ("Candy Crypt v2", wiki/open-questions.md):
	  * "Halloween packs and a flat candy amount only"; "8 chest tiers, rarer
	    ones with better packs".
	  * "each Crypt chest tier has its own special charm, mergeable, 0.5% flat
	    per charm, raised by Chest Luck" -- which charm is MineCharms'
	    (cryptChestCharm(rankKey), another agent's); the chance is here.
	  * "Halloween enchant books drop from Crypt chests (rarer chests more
	    often)" -- which book, and how often, is MineEnchants'
	    (rollHalloweenBook(rankIndex, rng), another agent's).
	  * "Every chest has its own name"; "ranks stay F to SSS behind the scenes,
	    shown as a badge. The Crypt's 8 chests get Halloween names."
	  * Rarer ranks rarer, and more common deeper (the same "better chests
	    deeper" the main mines have).

	BETTER PACKS = MORE AND LUCKIER HALLOWEEN PACKS. There is one Halloween pack
	(the Halloween 2026 Pack, PACK_ID). A bag row may carry `luck`, which
	openPack already honours (MinePackConfig.rollCard's siphonOdds: the odds
	lean toward the rarer pets) and the bag already shows ("+50%"). So a better
	chest pays more of them, luckier, with no new pack for the opener or the
	inventory to learn.

	EVERY NUMBER HERE IS PROPOSED (2026-10-19) except the owner's 0.5%.
]]
local MineCryptChests = {}

local Config = require(script.Parent:WaitForChild("MineConfig"))

MineCryptChests.PACK_ID = "halloween_2026"
MineCryptChests.PACK_NAME = "Halloween 2026 Pack"
MineCryptChests.PACK_SET = "halloween_2026"

--[[
	THE ONE TABLE OF CHEST NUMBERS (PROPOSED 2026-10-19).

	  RANKS       F .. SSS, each with its Halloween name, how many Halloween
	              packs it pays and at what pack luck, the flat candy it pays
	              (the same at every depth, like a block's), and the existing
	              chest look (MineConfig.CHEST_LOOK) it borrows until it has its
	              own art (tools/cursor/tasks/crypt-icons.md).
	  RATIO_TOP / RATIO_BOTTOM / SECTIONS
	              the rank odds, the same shape as the candy ores': each rank
	              is RATIO x as common as the one below it, the ratio walking
	              from RATIO_TOP in section 1 to RATIO_BOTTOM in section 12.
	  SSS_CAP     the top rank never passes this share of a section's chests.
	  CHARM_CHANCE  owner: 0.5% flat, raised by Chest Luck (multiplied, like
	              the graded charms' chest roll: MineCharms.CHARM_CHEST_CHANCE).
]]
MineCryptChests.RANKS = {
	{ key = "F", name = "Candy Sack", packs = 1, luck = 1.0, candy = 40, look = "native" },
	{ key = "D", name = "Pumpkin Pail", packs = 1, luck = 1.25, candy = 100, look = "native" },
	{ key = "C", name = "Cobweb Crate", packs = 1, luck = 1.5, candy = 250, look = "shape" },
	{ key = "B", name = "Bat Box", packs = 2, luck = 1.5, candy = 600, look = "shape" },
	{ key = "A", name = "Coffin Chest", packs = 2, luck = 2.0, candy = 1500, look = "currency" },
	{ key = "S", name = "Witch's Cauldron", packs = 3, luck = 2.5, candy = 4000, look = "currency" },
	{ key = "SS", name = "Phantom Vault", packs = 4, luck = 3.0, candy = 10000, look = "variant" },
	{ key = "SSS", name = "Pumpkin King's Hoard", packs = 5, luck = 4.0, candy = 25000, look = "variant" },
}
MineCryptChests.SECTIONS = 12
MineCryptChests.RATIO_TOP = 0.25
MineCryptChests.RATIO_BOTTOM = 0.55
MineCryptChests.SSS_CAP = 0.01
MineCryptChests.CHARM_CHANCE = 0.005
MineCryptChests.SECTION_SPAN = 10

local BY_KEY = {}
for i, r in ipairs(MineCryptChests.RANKS) do
	r.index = i
	r.id = "crypt_chest_" .. string.lower(r.key)
	BY_KEY[r.key] = r
end

function MineCryptChests.rank(key)
	return BY_KEY[tostring(key or "")]
end

-- The rank a chest block names (its ChestType, "crypt_chest_<key>"), or nil.
function MineCryptChests.rankOfId(id)
	local key = string.match(tostring(id or ""), "^crypt_chest_(%w+)$")
	return key and BY_KEY[string.upper(key)] or nil
end

function MineCryptChests.section(layer)
	local span = math.max(1, MineCryptChests.SECTION_SPAN)
	local s = math.max(1, math.floor(((tonumber(layer) or 1) - 1) / span) + 1)
	return math.min(s, MineCryptChests.SECTIONS)
end

--[[
	THE RANK ODDS OF ONE SECTION, F first (sums to 1). Rarer ranks are rarer;
	deeper sections lean rarer; SSS is capped and anything it gives up goes back
	to the rest in proportion.
]]
local cache = {}
function MineCryptChests.rankOdds(section)
	local n = MineCryptChests.SECTIONS
	local s = math.clamp(math.floor(tonumber(section) or 1), 1, n)
	if cache[s] then
		return cache[s]
	end
	local f = (n > 1) and ((s - 1) / (n - 1)) or 0
	local q = MineCryptChests.RATIO_TOP + (MineCryptChests.RATIO_BOTTOM - MineCryptChests.RATIO_TOP) * f
	-- The candy ores' shape (MineConfig.capRatioWeights): one rule for both.
	local w = Config.capRatioWeights(#MineCryptChests.RANKS, q, MineCryptChests.SSS_CAP)
	cache[s] = w
	return w
end

local function num(rng)
	return (rng and rng.NextNumber) and rng:NextNumber() or math.random()
end

-- The rank of a chest spawning at this layer.
function MineCryptChests.rollRank(layer, rng)
	local odds = MineCryptChests.rankOdds(MineCryptChests.section(layer))
	local pick = num(rng)
	for i, r in ipairs(MineCryptChests.RANKS) do
		pick -= odds[i]
		if pick <= 0 then
			return r
		end
	end
	return MineCryptChests.RANKS[1]
end

-- What a chest block is called and looks like (spawnVoxel stamps it).
function MineCryptChests.spawnDef(rank)
	rank = rank or MineCryptChests.RANKS[1]
	return {
		id = rank.id,
		name = rank.name,
		kind = rank.look,
		rank = rank.key,
		rankIndex = rank.index,
		crypt = true,
	}
end

-- The charm chance after Chest Luck: 0.5% x luck, never over 1.
function MineCryptChests.charmChance(chestLuck)
	local luck = math.max(1, tonumber(chestLuck) or 1)
	return math.min(1, MineCryptChests.CHARM_CHANCE * luck)
end

--[[
	The bag rows a rank's packs become: the Halloween pack, carrying the rank's
	pack luck when it has any (openPack and the inventory read `luck`).
]]
function MineCryptChests.packRows(rank)
	local out = {}
	if type(rank) ~= "table" then
		return out
	end
	for _ = 1, math.max(0, math.floor(tonumber(rank.packs) or 0)) do
		local row = {
			packId = MineCryptChests.PACK_ID,
			packName = MineCryptChests.PACK_NAME,
			setId = MineCryptChests.PACK_SET,
		}
		if (tonumber(rank.luck) or 1) > 1 then
			row.luck = rank.luck
		end
		table.insert(out, row)
	end
	return out
end

return MineCryptChests
