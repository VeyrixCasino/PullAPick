--[[
	MineTradeValue -- stardust-equivalent pricing for trade / coinflip offers.
	Server recomputes; clients may preview with the same module.
]]
local RS = game:GetService("ReplicatedStorage")
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local Packs = require(shared:WaitForChild("MinePackConfig"))

local MineTradeValue = {}

MineTradeValue.GEM_TO_DUST = 2
MineTradeValue.COIN_TO_DUST = 0.002
MineTradeValue.DUST_TO_DUST = 1

MineTradeValue.RUNE_DUST = {
	Common = 8, Uncommon = 18, Rare = 40, Epic = 90,
	Legendary = 200, Mythic = 450, Divine = 1000, Exotic = 2200,
}
MineTradeValue.GEAR_DUST = {
	Common = 12, Uncommon = 28, Rare = 60, Epic = 140,
	Legendary = 320, Mythic = 700, Divine = 1600, Exotic = 3600,
}
MineTradeValue.PACK_DUST = {
	rune_pack = 55, gear_pack = 70,
}

local function tierOf(card)
	if not card then return "Common" end
	local tid = card.rarityId or card.tier or card.rarity
	if type(tid) == "string" and MineTradeValue.RUNE_DUST[tid] then
		return tid
	end
	if Packs.TIERS and Packs.TIERS[tid] then
		return Packs.TIERS[tid].name or Packs.TIERS[tid].id or "Common"
	end
	return "Common"
end

function MineTradeValue.cardValue(card)
	if type(card) ~= "table" then return 0 end
	local tier = tierOf(card)
	local base = Packs.recycleValue and Packs.recycleValue(tier, card.variant, card.shiny)
		or (Packs.RECYCLE_STARDUST and Packs.RECYCLE_STARDUST[tier]) or 5
	local power = math.max(1, tonumber(card.powerLevel) or 1)
	return math.floor(base * (1 + (power - 1) * 0.35))
end

function MineTradeValue.packValue(entry)
	if type(entry) ~= "table" then return 0 end
	local id = entry.packId or entry.chestId or entry.id
	if id and MineTradeValue.PACK_DUST[id] then
		return MineTradeValue.PACK_DUST[id]
	end
	local price = tonumber(entry.stardustValue) or tonumber(entry.dustValue)
	if price then return math.floor(price) end
	local gemPrice = tonumber(entry.gemPrice) or (Packs.PACK_PRICE and Packs.PACK_PRICE[id]) or 25
	return math.floor(gemPrice * MineTradeValue.GEM_TO_DUST * 0.6)
end

--[[
	Runes are tiered 1..5, not named: two of a tier fuse into one of the next at
	50%, so each tier up costs about four of the one below. Looking them up by
	rarity name found nothing and every rune priced as 8 -- a T5 read the same
	as a T1 in a trade window, which is exactly how people get scammed.
]]
MineTradeValue.RUNE_TIER_DUST = { 25, 100, 400, 1600, 6400 }

function MineTradeValue.runeValue(entry)
	if type(entry) ~= "table" then
		return MineTradeValue.RUNE_TIER_DUST[1]
	end
	local tier = tonumber(entry.tier)
	if tier then
		tier = math.clamp(math.floor(tier), 1, #MineTradeValue.RUNE_TIER_DUST)
		return MineTradeValue.RUNE_TIER_DUST[tier]
	end
	local named = entry.rarityId or entry.rarity
	return MineTradeValue.RUNE_DUST[named] or MineTradeValue.RUNE_TIER_DUST[1]
end

-- Gear grades are letters; they sit on the same ladder as the card names.
MineTradeValue.GRADE_TO_NAME = {
	F = "Common", D = "Uncommon", C = "Rare", B = "Epic",
	A = "Legendary", S = "Mythic", SS = "Divine", SSS = "Exotic",
}

function MineTradeValue.gearValue(entry)
	local r = (type(entry) == "table" and (entry.rarityId or entry.rarity or entry.tier)) or "Common"
	r = MineTradeValue.GRADE_TO_NAME[r] or r
	return MineTradeValue.GEAR_DUST[r] or 12
end

function MineTradeValue.total(offer, cardLookup)
	if type(offer) ~= "table" then return 0 end
	local sum = 0
	sum += math.floor((tonumber(offer.gems) or 0) * MineTradeValue.GEM_TO_DUST)
	sum += math.floor((tonumber(offer.coins) or 0) * MineTradeValue.COIN_TO_DUST)
	sum += math.floor((tonumber(offer.dust) or 0) * MineTradeValue.DUST_TO_DUST)
	for _, id in ipairs(offer.cardIds or offer.cards or {}) do
		local card = cardLookup and cardLookup(id) or (type(id) == "table" and id) or nil
		sum += MineTradeValue.cardValue(card or { rarityId = "Common" })
	end
	for _, pk in ipairs(offer.packs or {}) do
		sum += MineTradeValue.packValue(type(pk) == "table" and pk or { packId = pk })
	end
	for _, r in ipairs(offer.runes or {}) do
		sum += MineTradeValue.runeValue(r)
	end
	for _, g in ipairs(offer.gear or {}) do
		sum += MineTradeValue.gearValue(g)
	end
	for _, t in ipairs(offer.potions or {}) do
		local id = type(t) == "table" and (t.id or t.potionId) or t
		local ok, v = pcall(function()
			return require(shared:WaitForChild("MinePotions")).tradeValue(id)
		end)
		sum += (ok and tonumber(v) or 40)
	end
	for _, t in ipairs(offer.tools or {}) do
		sum += math.floor(tonumber(type(t) == "table" and t.dustValue) or 80)
	end
	return math.max(0, sum)
end

return MineTradeValue
