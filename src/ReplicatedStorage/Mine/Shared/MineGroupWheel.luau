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

--[[
	LABELS ARE FOR A PLAYER WHO ARRIVED A MINUTE AGO.

	`id` is identity; `label` and `sub` are display only, so these are free to
	say what the prize actually IS. Nobody knows what a "temper" is -- but
	everybody understands pulling a CASE. Same for "gem storm" and "dust hoard":
	the internal name meant something to us and nothing to anyone else.

	Labels carry the meaning on their own, because the world wheel prints only
	the label (GroupWheelService) -- the sub exists for the UI panel.
]]
-- weight ≈ percent when the table sums near 100.
-- `hype` marks the chases: the slices worth stopping on. Named rather than
-- inferred from weight, because low weight is not the same as good -- 8K GEMS
-- is rare and dull, APEX PACK is common and great.
MineGroupWheel.SEGMENTS = {
	{ id = "exotic", label = "MYSTERY PET", sub = "Exotic — 1 in 400", color = Color3.fromRGB(18, 16, 22), weight = 0.25, hype = true,
		mystery = true, reward = { petPool = "droppable_exotic" } },
	{ id = "galaxy", label = "DIVINE PET", sub = "Galaxy", color = Color3.fromRGB(255, 245, 160), weight = 0.5, hype = true,
		reward = { pet = "Galaxy" } },
	{ id = "spark", label = "MYTHIC PET", sub = "Spark", color = Color3.fromRGB(85, 220, 255), weight = 1.5, hype = true,
		reward = { pet = "Spark" } },
	{ id = "legendary_pet", label = "LEGENDARY PET", sub = "Any Legendary", color = Color3.fromRGB(255, 170, 60), weight = 6, hype = true,
		reward = { petTier = "Legendary" } },
	{ id = "epic_pet", label = "EPIC PET", sub = "Any Epic", color = Color3.fromRGB(190, 120, 255), weight = 12,
		reward = { petTier = "Epic" } },
	{ id = "jackpot", label = "JACKPOT", sub = "50K Gems + Apex x2", color = Color3.fromRGB(255, 80, 120), weight = 2, hype = true,
		reward = { gems = 50000, packs = { { id = "apex_pack", qty = 2 } } } },
	{ id = "gem_storm", label = "20K GEMS", sub = "Gem Storm", color = Color3.fromRGB(80, 200, 255), weight = 4,
		reward = { gems = 20000 } },
	{ id = "gear_vault", label = "GEAR CASE", sub = "x2", color = Color3.fromRGB(255, 180, 60), weight = 8,
		reward = { packs = { { id = "gear_vault_pack", qty = 2 } } } },
	{ id = "heavy_runes", label = "RUNE CASE", sub = "x2", color = Color3.fromRGB(180, 100, 255), weight = 8,
		reward = { packs = { { id = "rune_heavy_pack", qty = 2 } } } },
	{ id = "apex", label = "APEX PACK", sub = "Best pack", color = Color3.fromRGB(255, 220, 80), weight = 11,
		reward = { packs = { { id = "apex_pack", qty = 1 } } } },
	{ id = "heirloom", label = "HEIRLOOM", sub = "Pack x2", color = Color3.fromRGB(120, 255, 180), weight = 11,
		reward = { packs = { { id = "heirloom_pack", qty = 2 } } } },
	{ id = "anomaly", label = "ANOMALY", sub = "Pack x2", color = Color3.fromRGB(100, 255, 255), weight = 11,
		reward = { packs = { { id = "anomaly_pack", qty = 2 } } } },
	{ id = "godly", label = "LUCKY BLOCK", sub = "Grade A", color = Color3.fromRGB(255, 120, 40), weight = 8,
		reward = { blocks = { { id = "godly_lucky_block", grade = "A", qty = 1 } } } },
	{ id = "dust_hoard", label = "25K DUST", sub = "Stardust", color = Color3.fromRGB(220, 180, 255), weight = 5,
		reward = { dust = 25000 } },
	{ id = "gem_bag", label = "8K GEMS", sub = "Gem Bag", color = Color3.fromRGB(100, 160, 255), weight = 5.75,
		reward = { gems = 8000 } },
	{ id = "tokens", label = "TEMPER CASE", sub = "80 Tokens = 4 cases", color = Color3.fromRGB(255, 200, 120), weight = 6,
		reward = { tokens = 80 } },
}

--[[
	THE SEASON CLOCK, WHICH THE HEADER ABOVE ALREADY CLAIMED.

	These read os.time(). SALE_START is 2026-09-22 and SALE_ENDS a week later,
	both already in the past -- so isLive() returned FALSE for everyone, the
	week-long sale having expired before a single player saw it, and the
	Studio escape hatch only fires BEFORE SALE_START so it was dead there too.

	Reading the launch clock makes the window mean what it says: one week from
	the moment the owner launches, wherever that lands in real time. Required
	lazily so this module stays leaf-level -- MineLaunch requires nothing, and
	keeping the edge out of the load graph means a future require inside it
	cannot cycle back through here.
]]
local function seasonNow(now)
	if tonumber(now) then
		return tonumber(now)
	end
	local ok, L = pcall(function()
		return require(script.Parent:WaitForChild("MineLaunch"))
	end)
	if ok and type(L) == "table" and type(L.seasonNow) == "function" then
		return L.seasonNow()
	end
	return os.time()
end

function MineGroupWheel.isLive(now)
	now = seasonNow(now)
	if now < MineGroupWheel.SALE_START then
		return game:GetService("RunService"):IsStudio()
	end
	return now < MineGroupWheel.SALE_ENDS
end

function MineGroupWheel.saleLeft(now)
	now = seasonNow(now)
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

--[[
	Any pet of a given tier.

	The wheel could only ever name one specific pet or roll the exotic pool, so
	the only pets on it were three chase slots totalling 2.25%. A new player
	would far rather walk away with an Epic or Legendary pet than with all the
	stardust in the world, and the roster already carries 33 Epics and 29
	Legendaries -- they just had no way onto the wheel.
]]
function MineGroupWheel.rollPetOfTier(tier, rng)
	rng = rng or Random.new()
	local roster = script.Parent:FindFirstChild("MinePetRoster")
	local ok, PR = pcall(require, roster)
	if not ok or type(PR) ~= "table" then
		return nil
	end
	local pool = {}
	for _, pet in ipairs((PR.BY_TIER or {})[tier] or {}) do
		local name = (type(pet) == "table") and pet.name or pet
		if type(name) == "string" and name ~= "" and not MineGroupWheel.EXOTIC_EXCLUDE[name] then
			table.insert(pool, name)
		end
	end
	if #pool == 0 then
		return nil
	end
	return pool[rng:NextInteger(1, #pool)]
end

function MineGroupWheel.resolvePetName(reward, rng)
	reward = reward or {}
	if type(reward.petTier) == "string" and reward.petTier ~= "" then
		return MineGroupWheel.rollPetOfTier(reward.petTier, rng)
	end
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

--[[
	TWO CLOCKS, DELIBERATELY.

	`now` is REAL time and stays real: the 6h spin cooldown is a wall-clock
	promise to the player and must not pause because the season has not
	started. The SALE WINDOW is season time, so isLive and saleLeft are called
	with no argument and resolve it themselves.

	Passing `now` into those two is what made the sale read as already over --
	the callers hand in os.time(), which is years past a window anchored to
	2026-09-22.
]]
function MineGroupWheel.payload(p, now)
	p = p or {}
	now = tonumber(now) or os.time()
	local gw = type(p.groupWheel) == "table" and p.groupWheel or {}
	local ready, wait = MineGroupWheel.ready(gw.last, now)
	local live = MineGroupWheel.isLive()
	return {
		live = live,
		saleLeft = MineGroupWheel.saleLeft(),
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
