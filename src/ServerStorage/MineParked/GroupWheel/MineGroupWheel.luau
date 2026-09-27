--[[
	MineGroupWheel -- limited-week lobby prize wheel.

	Same season clock as MineRotatingOffers / LIMITED_SALE_OPENS_AT.
	Featured chase: Galaxy (Divine 0.5%) + Spark (Mythic 1.5%).
	Landing EXOTIC rolls a random droppable Exotic (Matter± / Albert excluded).
	Free spin every 6h for group members; Robux packs bank paid spins.
]]

local MineGroupWheel = {}

local PetRoster = require(script.Parent:WaitForChild("MinePetRoster"))

-- Align with MineRotatingOffers.START / MineConfig.LIMITED_SALE_OPENS_AT.
local START = 1790049600
local WEEK = 604800

MineGroupWheel.COOLDOWN_SEC = 6 * 3600
MineGroupWheel.SALE_START = START
MineGroupWheel.SALE_ENDS = START + WEEK
MineGroupWheel.FEATURED_DIVINE = "Galaxy"
MineGroupWheel.FEATURED_MYTHIC = "Spark"
MineGroupWheel.TAGLINE = "Galaxy + Spark = EXOTIC"

-- Event Horizon limiteds stay off the random Exotic pool.
MineGroupWheel.EXOTIC_EXCLUDE = {
	["Matter+"] = true,
	["Matter-"] = true,
	["Albert Minestein"] = true,
}

MineGroupWheel.PRODUCT_KEYS = {
	{ key = "group_wheel_1", spins = 1, robux = 20 },
	{ key = "group_wheel_5", spins = 5, robux = 80 },
	{ key = "group_wheel_10", spins = 10, robux = 150 },
}

-- weight ≈ percent when the table sums near 100.
MineGroupWheel.SEGMENTS = {
	{ id = "exotic", label = "EXOTIC", sub = "Mystery Pet", color = Color3.fromRGB(18, 16, 22), weight = 0.25,
		mystery = true, reward = { petPool = "droppable_exotic" } },
	{ id = "galaxy", label = "GALAXY", sub = "Divine Pet", color = Color3.fromRGB(255, 245, 160), weight = 0.5,
		reward = { pet = "Galaxy" } },
	{ id = "spark", label = "SPARK", sub = "Mythic Pet", color = Color3.fromRGB(85, 220, 255), weight = 1.5,
		reward = { pet = "Spark" } },
	{ id = "jackpot", label = "JACKPOT", sub = "50K Gems + Apex x2", color = Color3.fromRGB(255, 80, 120), weight = 2,
		reward = { gems = 50000, packs = { { id = "apex_pack", qty = 2 } } } },
	{ id = "gem_storm", label = "GEM STORM", sub = "20K Gems", color = Color3.fromRGB(80, 200, 255), weight = 6,
		reward = { gems = 20000 } },
	{ id = "gear_vault", label = "GEAR VAULT", sub = "Vault x2", color = Color3.fromRGB(255, 180, 60), weight = 8,
		reward = { packs = { { id = "gear_vault_pack", qty = 2 } } } },
	{ id = "heavy_runes", label = "HEAVY RUNES", sub = "Rune Case x2", color = Color3.fromRGB(180, 100, 255), weight = 8,
		reward = { packs = { { id = "rune_heavy_pack", qty = 2 } } } },
	{ id = "apex", label = "APEX", sub = "Apex Pack", color = Color3.fromRGB(255, 220, 80), weight = 10,
		reward = { packs = { { id = "apex_pack", qty = 1 } } } },
	{ id = "heirloom", label = "HEIRLOOM", sub = "Heirloom x2", color = Color3.fromRGB(120, 255, 180), weight = 10,
		reward = { packs = { { id = "heirloom_pack", qty = 2 } } } },
	{ id = "anomaly", label = "ANOMALY", sub = "Anomaly x2", color = Color3.fromRGB(100, 255, 255), weight = 10,
		reward = { packs = { { id = "anomaly_pack", qty = 2 } } } },
	{ id = "godly", label = "GODLY BLOCK", sub = "Lucky Block A", color = Color3.fromRGB(255, 120, 40), weight = 8,
		reward = { blocks = { { id = "godly_lucky_block", grade = "A", qty = 1 } } } },
	{ id = "dust_hoard", label = "STARDUST", sub = "25K Dust", color = Color3.fromRGB(220, 180, 255), weight = 12,
		reward = { dust = 25000 } },
	{ id = "gem_bag", label = "GEM BAG", sub = "8K Gems", color = Color3.fromRGB(100, 160, 255), weight = 12,
		reward = { gems = 8000 } },
	{ id = "tokens", label = "TEMPER", sub = "80 Tokens", color = Color3.fromRGB(255, 200, 120), weight = 11.75,
		reward = { tokens = 80 } },
}

function MineGroupWheel.isLive(now)
	now = tonumber(now) or os.time()
	if now < MineGroupWheel.SALE_START then
		return game:GetService("RunService"):IsStudio()
	end
	return now < MineGroupWheel.SALE_ENDS
end

function MineGroupWheel.saleLeft(now)
	now = tonumber(now) or os.time()
	return math.max(0, MineGroupWheel.SALE_ENDS - now)
end

function MineGroupWheel.droppableExotics()
	local out = {}
	for _, pet in ipairs((PetRoster.BY_TIER and PetRoster.BY_TIER.Exotic) or {}) do
		if type(pet) == "table" and type(pet.name) == "string" and not MineGroupWheel.EXOTIC_EXCLUDE[pet.name] then
			out[#out + 1] = pet.name
		end
	end
	table.sort(out)
	return out
end

function MineGroupWheel.rollDroppableExotic(rng)
	rng = rng or Random.new()
	local pool = MineGroupWheel.droppableExotics()
	if #pool == 0 then
		return "Cosmo"
	end
	return pool[rng:NextInteger(1, #pool)]
end

function MineGroupWheel.resolvePetName(reward, rng)
	reward = reward or {}
	if type(reward.pet) == "string" and reward.pet ~= "" then
		return reward.pet
	end
	if reward.petPool == "droppable_exotic" then
		return MineGroupWheel.rollDroppableExotic(rng)
	end
	return nil
end

function MineGroupWheel.totalWeight()
	local n = 0
	for _, s in ipairs(MineGroupWheel.SEGMENTS) do
		n += math.max(0, tonumber(s.weight) or 0)
	end
	return n
end

function MineGroupWheel.roll(rng)
	rng = rng or Random.new()
	local total = MineGroupWheel.totalWeight()
	if total <= 0 then
		return MineGroupWheel.SEGMENTS[1], 1
	end
	local pick = rng:NextNumber(0, total)
	local acc = 0
	for i, s in ipairs(MineGroupWheel.SEGMENTS) do
		acc += math.max(0, tonumber(s.weight) or 0)
		if pick <= acc then
			return s, i
		end
	end
	local last = #MineGroupWheel.SEGMENTS
	return MineGroupWheel.SEGMENTS[last], last
end

function MineGroupWheel.nextAt(last)
	last = tonumber(last) or 0
	if last <= 0 then
		return 0
	end
	return last + MineGroupWheel.COOLDOWN_SEC
end

function MineGroupWheel.ready(last, now)
	now = tonumber(now) or os.time()
	local nextAt = MineGroupWheel.nextAt(last)
	if nextAt <= 0 then
		return true, 0
	end
	return now >= nextAt, math.max(0, nextAt - now)
end

function MineGroupWheel.paidSpins(p)
	local gw = type(p) == "table" and type(p.groupWheel) == "table" and p.groupWheel or {}
	return math.max(0, math.floor(tonumber(gw.paid) or 0))
end

function MineGroupWheel.payload(p, now)
	p = p or {}
	now = tonumber(now) or os.time()
	local gw = type(p.groupWheel) == "table" and p.groupWheel or {}
	local ready, wait = MineGroupWheel.ready(gw.last, now)
	local live = MineGroupWheel.isLive(now)
	return {
		live = live,
		saleLeft = MineGroupWheel.saleLeft(now),
		saleEnds = MineGroupWheel.SALE_ENDS,
		tagline = MineGroupWheel.TAGLINE,
		featuredDivine = MineGroupWheel.FEATURED_DIVINE,
		featuredMythic = MineGroupWheel.FEATURED_MYTHIC,
		ready = ready,
		wait = wait,
		nextAt = MineGroupWheel.nextAt(gw.last),
		paid = MineGroupWheel.paidSpins(p),
		segments = MineGroupWheel.SEGMENTS,
		cooldownSec = MineGroupWheel.COOLDOWN_SEC,
		products = MineGroupWheel.PRODUCT_KEYS,
	}
end

function MineGroupWheel.rewardLines(seg)
	local r = seg and seg.reward or {}
	local lines = {}
	if type(r.pet) == "string" then
		lines[#lines + 1] = r.pet
	end
	if r.petPool == "droppable_exotic" then
		lines[#lines + 1] = "Mystery Exotic"
	end
	if (tonumber(r.gems) or 0) > 0 then
		lines[#lines + 1] = string.format("%s Gems", tostring(r.gems))
	end
	if (tonumber(r.dust) or 0) > 0 then
		lines[#lines + 1] = string.format("%s Stardust", tostring(r.dust))
	end
	if (tonumber(r.tokens) or 0) > 0 then
		lines[#lines + 1] = string.format("%s Temper Tokens", tostring(r.tokens))
	end
	for _, row in ipairs(r.packs or {}) do
		lines[#lines + 1] = string.format("%s x%d", tostring(row.id), tonumber(row.qty) or 1)
	end
	for _, row in ipairs(r.blocks or {}) do
		lines[#lines + 1] = string.format("%s [%s]", tostring(row.id), tostring(row.grade or "F"))
	end
	return lines
end

return MineGroupWheel
