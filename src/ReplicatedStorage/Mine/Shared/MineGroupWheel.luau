--[[
	MineGroupWheel -- the DAILY WHEEL in the lobby. Shared rules: the prize
	table, the daily allowance, the payload. No services, so a verify script
	can run all of it (tools/verify/daily-wheel.js).

	Owner, 2026-10-10 (docs/TODO.md, NOW, A1): "we need that daily wheel
	working". Decided: EVERY player gets one free spin a day, group members get
	+1, and login streaks add more. It stands in the lobby with its odds printed
	on it.

	It used to be a one-week paid "Group Wheel": group members only, a rolling
	6h cooldown, and a sale window that had already closed before launch. The
	module keeps its name and its profile key (`p.groupWheel`) because both are
	data. A save written by the old wheel loads into this one.

	THE DAY is the UTC day, `floor(os.time() / 86400)`, the same boundary every
	other daily in the game uses (MineServer `utcDayIndex`).
]]

local MineGroupWheel = {}

local PetRoster = require(script.Parent:WaitForChild("MinePetRoster"))

--[[
	PROPOSED (2026-10-10, awaiting the owner): spins per day.
	  FREE_PER_DAY   every player
	  GROUP_BONUS    extra for group members (MineConfig.GROUP_ID)
	  STREAK_EVERY   on every Nth consecutive login day (the daily calendar's
	                 streak, p.daily.streak, counted once today's daily is claimed)
	  STREAK_BONUS   ...this many extra spins that day
]]
MineGroupWheel.FREE_PER_DAY = 1
MineGroupWheel.GROUP_BONUS = 1
MineGroupWheel.STREAK_EVERY = 7
MineGroupWheel.STREAK_BONUS = 1

MineGroupWheel.FEATURED_DIVINE = "Galaxy"
MineGroupWheel.FEATURED_MYTHIC = "Spark"
MineGroupWheel.TAGLINE = "1 FREE SPIN EVERY DAY  ·  +1 FOR GROUP MEMBERS"

-- Event Horizon limiteds stay off the random Exotic pool.
MineGroupWheel.EXOTIC_EXCLUDE = {
	["Matter+"] = true,
	["Matter-"] = true,
	["Albert Minestein"] = true,
}

-- Paid spins. Prices and spin counts live in MineConfig.PRODUCTS (the source
-- the receipt grant reads). productId is 0 until the owner pastes real ids.
MineGroupWheel.PRODUCT_KEYS = { "group_wheel_1", "group_wheel_5", "group_wheel_10" }

--[[
	THE PRIZE TABLE. PROPOSED 2026-10-10, awaiting the owner.

	The old table was tuned for a one-week PAID wheel: an 18% chance of an Epic
	or better pet and a 50K-gem jackpot, against a 400-gem day-one daily
	reward. As a free spin for every player, every day, that would have flooded
	the economy in a week. This keeps the same 16 slices and ids, with the
	chase where a free daily spin can afford it.

	`weight` is a percentage (the table sums to 100). `hype` marks a chase
	slice: at least a GREAT celebration, rays on the world wheel. `id` is
	identity and is never renamed; `label` and `sub` are display only.
]]
MineGroupWheel.SEGMENTS = {
	{ id = "exotic", label = "MYSTERY PET", sub = "Exotic", color = Color3.fromRGB(18, 16, 22), weight = 0.05, hype = true,
		mystery = true, reward = { petPool = "droppable_exotic" } },
	{ id = "galaxy", label = "DIVINE PET", sub = "Galaxy", color = Color3.fromRGB(255, 245, 160), weight = 0.15, hype = true,
		reward = { pet = "Galaxy" } },
	{ id = "spark", label = "MYTHIC PET", sub = "Spark", color = Color3.fromRGB(85, 220, 255), weight = 0.5, hype = true,
		reward = { pet = "Spark" } },
	{ id = "legendary_pet", label = "LEGENDARY PET", sub = "Any Legendary", color = Color3.fromRGB(255, 170, 60), weight = 2, hype = true,
		reward = { petTier = "Legendary" } },
	{ id = "epic_pet", label = "EPIC PET", sub = "Any Epic", color = Color3.fromRGB(190, 120, 255), weight = 5,
		reward = { petTier = "Epic" } },
	{ id = "jackpot", label = "JACKPOT", sub = "15K Gems + Apex", color = Color3.fromRGB(255, 80, 120), weight = 0.8, hype = true,
		reward = { gems = 15000, packs = { { id = "apex_pack", qty = 1 } } } },
	{ id = "gem_storm", label = "5K GEMS", sub = "Gem Storm", color = Color3.fromRGB(80, 200, 255), weight = 3,
		reward = { gems = 5000 } },
	{ id = "gear_vault", label = "GEAR CASE", sub = "x1", color = Color3.fromRGB(255, 180, 60), weight = 6,
		reward = { packs = { { id = "gear_vault_pack", qty = 1 } } } },
	{ id = "heavy_runes", label = "RUNE CASE", sub = "x1", color = Color3.fromRGB(180, 100, 255), weight = 6,
		reward = { packs = { { id = "rune_heavy_pack", qty = 1 } } } },
	{ id = "apex", label = "APEX PACK", sub = "Best pack", color = Color3.fromRGB(255, 220, 80), weight = 6,
		reward = { packs = { { id = "apex_pack", qty = 1 } } } },
	{ id = "heirloom", label = "HEIRLOOM", sub = "Pack x1", color = Color3.fromRGB(120, 255, 180), weight = 10,
		reward = { packs = { { id = "heirloom_pack", qty = 1 } } } },
	{ id = "anomaly", label = "ANOMALY", sub = "Pack x1", color = Color3.fromRGB(100, 255, 255), weight = 10,
		reward = { packs = { { id = "anomaly_pack", qty = 1 } } } },
	-- id "godly" is kept (identity); the prize is now a grade-C Lucky Block.
	{ id = "godly", label = "LUCKY BLOCK", sub = "Grade C", color = Color3.fromRGB(255, 120, 40), weight = 6,
		reward = { blocks = { { id = "lucky_block", grade = "C", qty = 1 } } } },
	{ id = "dust_hoard", label = "5K DUST", sub = "Stardust", color = Color3.fromRGB(220, 180, 255), weight = 8,
		reward = { dust = 5000 } },
	{ id = "gem_bag", label = "1.5K GEMS", sub = "Gem Bag", color = Color3.fromRGB(100, 160, 255), weight = 20.5,
		reward = { gems = 1500 } },
	{ id = "tokens", label = "20 TOKENS", sub = "Temper tokens", color = Color3.fromRGB(255, 200, 120), weight = 16,
		reward = { tokens = 20 } },
}

-- -------------------------------------------------------------- the day --

function MineGroupWheel.dayIndex(now)
	return math.floor((tonumber(now) or os.time()) / 86400)
end

-- Seconds until the next UTC midnight, when the free spins refill.
function MineGroupWheel.resetIn(now)
	now = math.floor(tonumber(now) or os.time())
	return 86400 - (now % 86400)
end

--[[
	How many free spins a player gets TODAY.
	  member         in the group (cached by GroupWheelService, never yields here)
	  streak         p.daily.streak
	  claimedToday   p.daily.last == today, so the streak counts for today
]]
function MineGroupWheel.allowance(member, streak, claimedToday)
	local n = MineGroupWheel.FREE_PER_DAY
	if member then
		n += MineGroupWheel.GROUP_BONUS
	end
	streak = math.floor(tonumber(streak) or 0)
	local every = MineGroupWheel.STREAK_EVERY
	if claimedToday and every > 0 and streak >= every and streak % every == 0 then
		n += MineGroupWheel.STREAK_BONUS
	end
	return n
end

-- True when today is a streak-bonus day (for the panel's copy).
function MineGroupWheel.isStreakDay(streak, claimedToday)
	local every = MineGroupWheel.STREAK_EVERY
	streak = math.floor(tonumber(streak) or 0)
	return claimedToday == true and every > 0 and streak >= every and streak % every == 0
end

-- Free spins already used today. A new day reads as zero without a write.
function MineGroupWheel.usedToday(gw, day)
	if type(gw) ~= "table" or gw.day ~= day then
		return 0
	end
	return math.max(0, math.floor(tonumber(gw.used) or 0))
end

function MineGroupWheel.freeLeft(gw, day, allowance)
	return math.max(0, (tonumber(allowance) or 0) - MineGroupWheel.usedToday(gw, day))
end

function MineGroupWheel.paidSpins(p)
	local gw = type(p) == "table" and type(p.groupWheel) == "table" and p.groupWheel or {}
	return math.max(0, math.floor(tonumber(gw.paid) or 0))
end

--[[
	Everything the panel and the HUD need, small enough for every snapshot:
	no segment table (the client has it, this module is shared).
]]
function MineGroupWheel.state(p, now, member)
	p = type(p) == "table" and p or {}
	now = tonumber(now) or os.time()
	local day = MineGroupWheel.dayIndex(now)
	local daily = type(p.daily) == "table" and p.daily or {}
	local claimedToday = tonumber(daily.last) == day
	local allowance = MineGroupWheel.allowance(member, daily.streak, claimedToday)
	return {
		freeLeft = MineGroupWheel.freeLeft(p.groupWheel, day, allowance),
		freeTotal = allowance,
		paid = MineGroupWheel.paidSpins(p),
		resetIn = MineGroupWheel.resetIn(now),
		member = member == true,
		streakDay = MineGroupWheel.isStreakDay(daily.streak, claimedToday),
		claimedDaily = claimedToday,
	}
end

-- --------------------------------------------------------------- prizes --

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

-- Any pet of a tier, Event Horizon limiteds excluded.
function MineGroupWheel.rollPetOfTier(tier, rng)
	rng = rng or Random.new()
	local pool = {}
	for _, pet in ipairs((PetRoster.BY_TIER or {})[tier] or {}) do
		local name = (type(pet) == "table") and pet.name or pet
		-- Holiday pets come only from a holiday pack (owner, 2026-10-10), never
		-- from a random roll: the wheel and lucky blocks both come through here.
		local holiday = type(pet) == "table" and pet.holiday
		if type(name) == "string" and name ~= "" and not holiday and not MineGroupWheel.EXOTIC_EXCLUDE[name] then
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

-- "1 in N" for a slice, from its real weight.
function MineGroupWheel.oneIn(seg)
	local w = math.max(0, tonumber(seg and seg.weight) or 0)
	local total = MineGroupWheel.totalWeight()
	if w <= 0 or total <= 0 then
		return math.huge
	end
	return total / w
end

-- The odds as a player reads them: "20%" for common, "1 in 200" for rare.
function MineGroupWheel.oddsText(seg)
	local total = MineGroupWheel.totalWeight()
	local w = math.max(0, tonumber(seg and seg.weight) or 0)
	if total <= 0 or w <= 0 then
		return ""
	end
	local pct = w / total * 100
	if pct >= 10 then
		return string.format("%.0f%%", pct)
	elseif pct >= 1 then
		return string.format("%.1f%%", pct)
	end
	return string.format("1 in %d", math.floor(100 / pct + 0.5))
end

-- A player-facing name for a pack or block id ("apex_pack" -> "Apex Pack").
function MineGroupWheel.prettyId(id)
	local s = tostring(id or ""):gsub("_", " ")
	return (s:gsub("(%a)([%w]*)", function(a, b)
		return string.upper(a) .. b
	end))
end

return MineGroupWheel
