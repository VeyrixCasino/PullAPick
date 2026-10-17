local Launch = require(script.Parent:WaitForChild("MineLaunch"))
-- MineScrolls: the credit packs, the battle pass and its track, the daily.
-- The white / black / omni scrolls it was named for were rune tools, retired
-- with runes on 2026-10-12; ITEMS stays (empty) so old readers find nothing.
-- Credits track ~1 Robux = 1 credit at face value (passes & limiteds cost the
-- same number either way). Bigger packs add bonus credits — that is the deal,
-- so buying a Vault/Crate then spending credits undercuts paying Robux direct.
local MineScrolls = {}

MineScrolls.ITEMS = {}

-- Live developer products. The ids and Robux prices are the real ones from the
-- Creator Dashboard; `credits` is what we grant. ProcessReceipt matches on
-- productId, so adding a row here is all it takes to make a product work.
--
-- NOTE ON "1200 Cash": the product is LISTED on Roblox as "1200 Cash", but this
-- game has no cash currency -- there is not one reference to it anywhere in the
-- codebase. Its price sits exactly on the credits ladder (+18%, between the 550
-- and 3200 packs), so it is a credits pack with a leftover name, and it grants
-- credits here. Rename the product on the dashboard to "1200 Credits" or the
-- purchase prompt will say one thing and the game another.
--
-- NOTE ON THE 100 PACK: at 99 Robux for 100 it is WORSE value than two 50 packs
-- (98 Robux for the same 100). Anyone who does the arithmetic never buys it.
-- Either drop it to 89 or lift it to 110 credits.
MineScrolls.CREDIT_PACKS = {
	-- List prices are already min Robux for earnedRobux = floor(robux*0.7).
	-- Value (credits/R$) rises with size — never better to buy smaller.
	{ id = "c10", label = "Handful", credits = 10, robux = 10, earnedRobux = 7, bonusPct = 0,
		tag = nil, productId = 3713196394, icon = "credit_handful",
		iconImage = "rbxassetid://83194524418120" },
	{ id = "c25", label = "Starter", credits = 25, robux = 24, earnedRobux = 16, bonusPct = 4,
		tag = nil, productId = 3713200476, icon = "credit_starter",
		iconImage = "rbxassetid://111821940203483" },
	{ id = "c55", label = "Pocket", credits = 55, robux = 49, earnedRobux = 34, bonusPct = 12,
		tag = nil, productId = 3712300990, icon = "credit_pocket",
		iconImage = "rbxassetid://81945984433737" },
	{ id = "c125", label = "Pouch", credits = 125, robux = 99, earnedRobux = 69, bonusPct = 26,
		tag = "+26% free", productId = 3712300389, icon = "credit_pouch",
		iconImage = "rbxassetid://136749825863793" },
	{ id = "c275", label = "Sack", credits = 275, robux = 199, earnedRobux = 139, bonusPct = 38,
		tag = "+38% free", productId = 3712300417, icon = "credit_sack",
		iconImage = "rbxassetid://87948711465516" },
	{ id = "c575", label = "Crate", credits = 575, robux = 399, earnedRobux = 279, bonusPct = 44,
		tag = "+44% free · Popular", productId = 3712300444, icon = "credit_crate",
		iconImage = "rbxassetid://118952009409330" },
	{ id = "c1200", label = "Vault", credits = 1200, robux = 749, earnedRobux = 524, bonusPct = 60,
		tag = "+60% free", productId = 3712300482, icon = "credit_vault",
		iconImage = "rbxassetid://117447901452563" },
	{ id = "c7000", label = "Treasury", credits = 7000, robux = 4999, earnedRobux = 3499, bonusPct = 63,
		tag = "+63% free · Whale", productId = 3712300525, icon = "credit_treasury",
		iconImage = "rbxassetid://94754649897464" },
}

function MineScrolls.minRobuxForEarn(net)
	net = math.max(0, math.floor(tonumber(net) or 0))
	local p = math.ceil(net / 0.7)
	while math.floor(p * 0.7) < net do
		p += 1
	end
	return p
end

function MineScrolls.creditPackIcon(pack)
	if type(pack) ~= "table" then
		return nil
	end
	if type(pack.iconImage) == "string" and pack.iconImage ~= "" then
		return pack.iconImage
	end
	local Icons = require(script.Parent:WaitForChild("MineIcons"))
	local key = pack.icon
	if key and Icons.IMAGES and Icons.IMAGES[key] then
		return Icons.IMAGES[key]
	end
	return Icons.IMAGES and Icons.IMAGES.credits or nil
end

-- Bought once, not consumed. ProcessReceipt sets pass.owned; free+premium
-- tracks claim via claimPass. XP comes from quests, with no daily cap.
MineScrolls.BATTLE_PASS = {
	id = "battlepass",
	name = "Battle Pass",
	robux = 399,
	credits = 399, -- 1:1 face; bulk credit packs make this cheaper in real Robux
	productId = 3712300643,
}

function MineScrolls.emptyBag()
	return {}
end

function MineScrolls.packById(id)
	for _, row in ipairs(MineScrolls.CREDIT_PACKS) do
		if row.id == id then return row end
	end
end

function MineScrolls.itemById(id)
	return MineScrolls.ITEMS[id]
end


--------------------------------------------------------------------------------
-- BATTLE PASS — the 2026-10-16 rework (tiers 1–100)
-- Horizontal icon rails; credit caps 100/1200; signature tools at tier 1
-- (free Lunar, premium Eclipse; fuse → Lunar Eclipse). XP: quests only
-- (MineServer awardPassXp), no daily cap; see PASS_XP_PER_TIER.
--------------------------------------------------------------------------------
MineScrolls.PASS_TIERS = 100
MineScrolls.PASS_FREE_CREDIT_CAP = 100
MineScrolls.PASS_PREM_CREDIT_CAP = 1200

local FREE_CREDITS = {
	[5] = 5, [15] = 5, [25] = 5, [35] = 5, [45] = 5,
	[55] = 10, [65] = 10, [75] = 10, [85] = 10,
	[95] = 17, [100] = 18,
}
local PREM_CREDITS = {
	[5] = 15, [10] = 15, [15] = 15, [20] = 15, [25] = 15, [30] = 15, [35] = 15, [40] = 15,
	[45] = 25, [50] = 25, [55] = 25, [60] = 25, [65] = 25, [70] = 25,
	[75] = 40, [80] = 40, [85] = 40, [90] = 40,
	[92] = 50, [94] = 50, [96] = 50, [98] = 50,
	[100] = 570,
}

local function lb(id, startGrade, qty)
	return { luckyBlocks = { { id = id, startGrade = startGrade or "F", qty = qty or 1 } } }
end

local function shallowClone(t)
	local out = {}
	for k, v in pairs(t) do out[k] = v end
	return out
end

local function mergeReward(a, b)
	local out = shallowClone(a or {})
	for k, v in pairs(b or {}) do
		if k == "luckyBlocks" and out.luckyBlocks then
			local copy = {}
			for i, row in ipairs(out.luckyBlocks) do copy[i] = row end
			for _, row in ipairs(v) do table.insert(copy, row) end
			out.luckyBlocks = copy
		elseif type(v) == "number" and type(out[k]) == "number" then
			out[k] = out[k] + v
		else
			out[k] = v
		end
	end
	return out
end

--[[
	THE TRACK. Owner, 2026-10-16: "100 teirs, every 5 should be decent, every 10
	should be good and every 25 is huge"; the premium track is "Exclusive pets,
	skins and books"; the free track pays "Something every tier, smaller".

	  small   every tier   free: gems, stardust or a Lucky Block, in turn
	                       premium: a Lucky Block, gems or a book
	  decent  every 5th    free: 2 books; premium: a Diamond block + 3 books
	  good    every 10th   free: a Diamond block + gems; premium: a season
	                       SKIN at 20 / 40 / 60 / 80, else a Godly block + 4 books
	  huge    every 25th   free: a Godly block + books; premium: a season PET
	                       (25 Legendary, 50 Mythic, 75 Divine, 100 Exotic)

	Tier 1 keeps the signature tools, and the credits back ride on top
	(FREE_CREDITS, PREM_CREDITS). The pets are the generated HolidayPets pack
	PASS_PET_PACK; the skins are MineSkins' pass set. The amounts are PROPOSED.
]]
MineScrolls.PASS_PET_PACK = "pass_2026_10"
MineScrolls.PASS_PET_TIERS = { [25] = "Legendary", [50] = "Mythic", [75] = "Divine", [100] = "Exotic" }
MineScrolls.PASS_SKINS = { [20] = "gemfire", [40] = "geode_heart", [60] = "deepgold_seam", [80] = "the_motherlode" }

function MineScrolls.tierClass(n)
	n = math.floor(tonumber(n) or 0)
	if n % 25 == 0 then
		return "huge"
	elseif n % 10 == 0 then
		return "good"
	elseif n % 5 == 0 then
		return "decent"
	end
	return "small"
end

-- A Lucky Block's starting grade climbs with the tier.
local function gradeFor(n)
	return (n <= 15 and "F") or (n <= 30 and "D") or (n <= 45 and "C") or (n <= 65 and "B") or "A"
end

-- The season's pets by tier, read off the generated pack.
local function passPetNames()
	local out = {}
	pcall(function()
		local folder = script.Parent:FindFirstChild("HolidayPets")
		for _, mod in ipairs(folder and folder:GetChildren() or {}) do
			if mod:IsA("ModuleScript") then
				local ok, set = pcall(require, mod)
				if ok and type(set) == "table" and set.KEY == MineScrolls.PASS_PET_PACK then
					for _, row in ipairs(set.PETS or {}) do
						out[row.tier] = row.name
					end
				end
			end
		end
	end)
	return out
end

local function skinInfo(id)
	local info
	pcall(function()
		local Skins = require(script.Parent:WaitForChild("MineSkins", 5))
		local sk = Skins.byId(id)
		if sk and Skins.isPass and Skins.isPass(sk) then
			info = { name = sk.name, tier = sk.tier }
		end
	end)
	return info
end

local function iconOf(r)
	if r.pet then return "pet" end
	if r.skin then return "skin" end
	if r.toolId then return r.toolId end
	if r.luckyBlocks and r.luckyBlocks[1] then return r.luckyBlocks[1].id end
	if r.books then return "books" end
	if r.credits then return "credits" end
	if r.gems then return "gems" end
	if r.dust then return "stardust" end
	return "gift"
end

local function buildPassTrack()
	local track = {}
	local pets = passPetNames()
	for tier = 1, MineScrolls.PASS_TIERS do
		local class = MineScrolls.tierClass(tier)
		local g = gradeFor(tier)
		local free, prem
		if tier == 1 then
			free = { toolId = "lunar_pick", icon = "lunar_pick" }
			prem = { toolId = "bp_eclipse", icon = "bp_eclipse" }
		elseif class == "huge" then
			local godly = (tier == 25 and "D") or (tier == 50 and "C") or (tier == 75 and "B") or "A"
			free = mergeReward(lb("godly_lucky_block", godly), { books = (tier >= 75) and 4 or 3 })
			if tier == 100 then
				free = mergeReward(free, { dust = 500 })
			end
			local petTier = MineScrolls.PASS_PET_TIERS[tier]
			if pets[petTier] then
				prem = { pet = pets[petTier], petTier = petTier, books = 3 }
			else
				-- The pet pack is missing from this build: never a blank huge tier.
				prem = mergeReward(lb("godly_lucky_block", godly), { books = 5 })
			end
			if tier == 100 then
				prem = mergeReward(prem, lb("godly_lucky_block", "A"))
			end
		elseif class == "good" then
			free = mergeReward(lb("super_lucky_block", g), { gems = 200 + tier * 6 })
			local skinId = MineScrolls.PASS_SKINS[tier]
			local info = skinId and skinInfo(skinId)
			if info then
				prem = { skin = skinId, skinName = info.name, skinTier = info.tier, books = 2 }
			else
				prem = mergeReward(lb("godly_lucky_block", g), { books = 4 })
			end
		elseif class == "decent" then
			free = { books = 2 }
			prem = mergeReward(lb("super_lucky_block", g), { books = 3 })
		else
			local k = tier % 3
			free = (k == 0 and { gems = 50 + tier * 4 }) or (k == 1 and { dust = 25 + tier * 2 }) or lb("lucky_block", g)
			if tier % 2 == 0 then
				prem = lb(tier > 60 and "super_lucky_block" or "lucky_block", g)
			elseif tier % 4 == 1 then
				prem = { gems = 100 + tier * 6 }
			else
				prem = { books = 1 }
			end
		end
		if FREE_CREDITS[tier] then free = mergeReward(free, { credits = FREE_CREDITS[tier] }) end
		if PREM_CREDITS[tier] then prem = mergeReward(prem, { credits = PREM_CREDITS[tier] }) end
		free.icon = free.icon or iconOf(free)
		prem.icon = prem.icon or iconOf(prem)
		track[tier] = { tier = tier, class = class, free = free, premium = prem }
	end
	return track
end

MineScrolls.PASS_TRACK = buildPassTrack()

--[[
	What each kind of claim feeds the battle pass. ONE table, read by the
	server when it grants (MineServer claim verbs) and by the Job Board when
	it labels the row — so the promise and the payout cannot drift apart.
]]
MineScrolls.PASS_XP_AWARD = {
	quest = 80,
	daily = 100,
	contract = 120,
	milestone = 70,
}

function MineScrolls.freeTrackTotals()
	local out = { credits = 0, gems = 0, dust = 0 }
	for _, row in ipairs(MineScrolls.PASS_TRACK) do
		local f = row.free or {}
		out.credits += (f.credits or 0)
		out.gems += (f.gems or 0)
		out.dust += (f.dust or 0)
	end
	return out
end

function MineScrolls.premTrackTotals()
	local out = { credits = 0, gems = 0, dust = 0 }
	for _, row in ipairs(MineScrolls.PASS_TRACK) do
		out.credits += (row.premium.credits or 0)
		out.gems += (row.premium.gems or 0)
		out.dust += (row.premium.dust or 0)
	end
	return out
end

do
	local f = MineScrolls.freeTrackTotals()
	local p = MineScrolls.premTrackTotals()
	assert(f.credits == 100, ("free pass credits expected 100, got %d"):format(f.credits))
	assert(p.credits == 1200, ("prem pass credits expected 1200, got %d"):format(p.credits))
	assert(#MineScrolls.PASS_TRACK == MineScrolls.PASS_TIERS)
end

-- Pace (owner, 2026-10-16: "about 2 weeks no daily xp cap"): 90 XP a tier,
-- 9,000 for all 100. A player doing every daily (3 x 100) and contract
-- (3 x 120) earns ~660 a day plus chain quests and milestones, so about 12
-- days; a kid who plays most days, about two weeks. PROPOSED.
MineScrolls.PASS_XP_PER_TIER = 90
MineScrolls.PASS_SEASON_DAYS = 28

function MineScrolls.passXpFor(tier)
	return math.max(0, (tonumber(tier) or 0)) * MineScrolls.PASS_XP_PER_TIER
end

function MineScrolls.passTier(xp)
	local t = math.floor((tonumber(xp) or 0) / MineScrolls.PASS_XP_PER_TIER)
	return math.clamp(t, 0, MineScrolls.PASS_TIERS)
end

function MineScrolls.emptyPass()
	return { xp = 0, owned = false, free = {}, prem = {}, day = "", dayXp = 0, season = MineScrolls.PASS_SEASON_ID }
end

--[[
	THE PASS IS 47 DAYS LONG, and these two numbers are a LENGTH, not dates.

	MineLaunch pins the season clock to PASS_SEASON_START until the owner
	launches, then runs it from that moment, so the pass ends 47 days after
	launch whatever the calendar says. The constants still read as the original
	calendar (2026-09-22 00:00 ET start) only so they line up with
	MineRotatingOffers and MineConfig.LIMITED_DAYS.

	It was 40 days. The offers got "ONE MORE WEEK, ON EVERYTHING"
	(MineRotatingOffers.EXTEND_SEC) and Event Horizon runs LIMITED_DAYS = 47,
	but the pass was missed, so it would have ended a week before the season it
	belongs to. tools/verify/launch.js now pins the lengths together.
]]
MineScrolls.PASS_SEASON_ID = "2026-10"
MineScrolls.PASS_SEASON_NEXT = "2026-11"
MineScrolls.PASS_SEASON_START = 1790049600
MineScrolls.PASS_SEASON_END = 1794110400
-- No calendar date: the real end depends on when the season was launched.
-- passEndLabel() gives the real one.
MineScrolls.PASS_SEASON_LABEL = "when the countdown ends"

--[[
	THE SEASON CLOCK FOR A CLIENT. Pass it workspace:GetServerTimeNow().

	Real server time is the wrong input for anything below: the pass is measured
	on the season clock, which waits for launch. A client that handed the raw
	server time to passSecondsLeft counted down to a calendar date while the
	server's season had not begun, and would show SEASON OVER mid-season after a
	late launch.
]]
function MineScrolls.seasonClock(realNow)
	return Launch.seasonNow(realNow)
end

-- When the pass really ends, in the reader's own local time (os.date on a
-- client is local). Before launch there is no date to give.
function MineScrolls.passEndLabel()
	local at = Launch.stamp and Launch.stamp() or 0
	if at <= 0 then
		return "Starts at launch"
	end
	local endsAt = at + (MineScrolls.PASS_SEASON_END - MineScrolls.PASS_SEASON_START)
	-- "*t" rather than a strftime pattern, so the text is the same everywhere.
	local t = os.date("*t", endsAt)
	local months = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
	local h = t.hour % 12
	if h == 0 then
		h = 12
	end
	return string.format("%s %d · %d:%02d %s", months[t.month] or "?", t.day, h, t.min, t.hour < 12 and "AM" or "PM")
end

function MineScrolls.passSecondsLeft(now)
	return math.max(0, MineScrolls.PASS_SEASON_END - (now or Launch.seasonNow()))
end

-- Live clock, always down to the second so the pass header visibly ticks.
-- `now` is SEASON time: on a client pass seasonClock(workspace:GetServerTimeNow()),
-- never the raw server time.
function MineScrolls.formatPassClock(now)
	local left = math.floor(MineScrolls.passSecondsLeft(now))
	if left <= 0 then
		return "SEASON OVER"
	end
	local d = math.floor(left / 86400)
	local h = math.floor((left % 86400) / 3600)
	local m = math.floor((left % 3600) / 60)
	local s = left % 60
	if d > 0 then
		return string.format("%dd %02dh %02dm %02ds", d, h, m, s)
	end
	return string.format("%02dh %02dm %02ds", h, m, s)
end

function MineScrolls.formatPassTimer(now)
	local left = MineScrolls.passSecondsLeft(now)
	if left <= 0 then
		return "Next pass is live"
	end
	return MineScrolls.formatPassClock(now) .. "  ·  ends " .. MineScrolls.passEndLabel()
end

-- Free and premium are separate claim ledgers. A season rollover wipes both,
-- plus XP and the premium unlock, so the next pass starts clean.
function MineScrolls.reconcilePass(pass, now)
	if type(pass) ~= "table" then
		return pass
	end
	now = now or Launch.seasonNow()
	pass.free = pass.free or {}
	pass.prem = pass.prem or {}
	pass.xp = tonumber(pass.xp) or 0
	if now >= MineScrolls.PASS_SEASON_END then
		if pass.season ~= MineScrolls.PASS_SEASON_NEXT then
			pass.xp = 0
			pass.free = {}
			pass.prem = {}
			pass.owned = false
			pass.day = ""
			pass.dayXp = 0
			pass.season = MineScrolls.PASS_SEASON_NEXT
		end
	else
		pass.season = pass.season or MineScrolls.PASS_SEASON_ID
	end
	return pass
end

function MineScrolls.describeReward(reward)
	if type(reward) ~= "table" then return "--" end
	local parts = {}
	if reward.toolId then
		local names = { lunar_pick = "Lunar Pickaxe", bp_eclipse = "Eclipse", lunar_eclipse = "Lunar Eclipse" }
		parts[#parts + 1] = names[reward.toolId] or tostring(reward.toolId)
	end
	if type(reward.luckyBlocks) == "table" then
		for _, b in ipairs(reward.luckyBlocks) do
			local nm = ({
				lucky_block = "Lucky Block",
				super_lucky_block = "Super Lucky Block",
				godly_lucky_block = "Godly Lucky Block",
			})[b.id] or b.id
			local g = b.startGrade and (" (" .. b.startGrade .. ")") or ""
			local q = (b.qty and b.qty > 1) and (" x" .. b.qty) or ""
			parts[#parts + 1] = nm .. g .. q
		end
	end
	if reward.credits then parts[#parts + 1] = reward.credits .. " Credits" end
	if reward.gems then parts[#parts + 1] = reward.gems .. " Gems" end
	if reward.dust then parts[#parts + 1] = reward.dust .. " Stardust" end
	if reward.pet then parts[#parts + 1] = tostring(reward.pet) .. " (" .. tostring(reward.petTier or "season") .. " pet)" end
	if reward.skin then parts[#parts + 1] = tostring(reward.skinName or reward.skin) .. " skin (" .. tostring(reward.skinTier or "") .. ")" end
	if reward.books then parts[#parts + 1] = reward.books .. " Enchant Books" end
	if #parts == 0 then return "--" end
	return table.concat(parts, "  +  ")
end

--[[
	The daily.

	A seven-day cycle that repeats; the streak keeps counting past seven so a
	long run still reads as one. Miss a day and it starts over at one -- that is
	the whole mechanic, and it is the cheapest reason a player has to come back
	tomorrow.

	Gems scale with the deepest zone unlocked, because a flat gem reward is a
	fortune on day one and pocket change by zone six, and a daily that stops
	mattering is a daily nobody opens. Packs and credits do not scale: a pack is
	a pack, and credits are premium currency -- inflating those would undercut
	the thing people pay for.
]]
--[[
	Every day is worth more than the last, and day seven is the one worth
	coming back for. Credits stay where they were (10 on day four, 25 on day
	seven) -- they are the premium currency.
]]
MineScrolls.DAILY = {
	{ gems = 400 },
	{ pack = "clay_pack", packQty = 2 },
	{ gems = 900, potion = "fortune_sip" },
	{ credits = 10, luckyBlocks = { { id = "lucky_block", startGrade = "D", qty = 1 } } },
	{ gems = 1800, pack = "iron_pack", packQty = 2 },
	{ dust = 400, potion = "haste_flask", potionQty = 2 },
	{ gems = 3500, credits = 25, pack = "night_pack", packQty = 2,
		luckyBlocks = { { id = "super_lucky_block", startGrade = "D", qty = 1 } }, jackpot = true },
}
MineScrolls.DAILY_DAYS = #MineScrolls.DAILY
-- Gems multiply by 1 + (zone - 1) * this.
MineScrolls.DAILY_ZONE_SCALE = 0.8
-- Each full week of unbroken streak adds this much to the gems, up to double.
MineScrolls.DAILY_WEEK_BONUS = 0.25
MineScrolls.DAILY_WEEK_MAX = 2

function MineScrolls.dailyWeekMult(streak)
	local s = math.max(1, math.floor(tonumber(streak) or 1))
	local weeks = math.floor((s - 1) / MineScrolls.DAILY_DAYS)
	return math.min(MineScrolls.DAILY_WEEK_MAX, 1 + weeks * MineScrolls.DAILY_WEEK_BONUS)
end

-- Where a streak sits in the cycle. Streak 1 is day 1, streak 8 is day 1 again.
function MineScrolls.dailyDay(streak)
	local s = math.max(1, math.floor(tonumber(streak) or 1))
	return ((s - 1) % MineScrolls.DAILY_DAYS) + 1
end

function MineScrolls.dailyReward(streak)
	return MineScrolls.DAILY[MineScrolls.dailyDay(streak)]
end

function MineScrolls.dailyGems(reward, zone, streak)
	if not reward or not reward.gems then
		return 0
	end
	local z = math.max(1, math.floor(tonumber(zone) or 1))
	return math.floor(reward.gems * (1 + (z - 1) * MineScrolls.DAILY_ZONE_SCALE)
		* MineScrolls.dailyWeekMult(streak))
end

-- One description, shared by the server's toast and the claim card, so the
-- reward a player is shown and the one they get cannot drift apart.
-- Each reward line on its own, short enough for a calendar tile.
function MineScrolls.dailyParts(reward, zone, streak)
	local parts = {}
	if type(reward) ~= "table" then
		return parts
	end
	local gems = MineScrolls.dailyGems(reward, zone, streak)
	if gems > 0 then
		parts[#parts + 1] = gems .. " Gems"
	end
	if reward.credits then
		parts[#parts + 1] = reward.credits .. " Credits"
	end
	if reward.pack then
		local qty = reward.packQty or 1
		local nm = tostring(reward.pack):gsub("_", " "):gsub("^%l", string.upper):gsub(" %l", string.upper)
		parts[#parts + 1] = (qty > 1) and (nm .. " x" .. qty) or nm
	end
	if reward.dust then
		parts[#parts + 1] = reward.dust .. " Stardust"
	end
	if reward.potion then
		local okP, Potions = pcall(require, script.Parent:WaitForChild("MinePotions"))
		local def = okP and Potions and Potions.def and Potions.def(reward.potion)
		local qty = reward.potionQty or 1
		parts[#parts + 1] = ((def and def.name) or "Potion") .. ((qty > 1) and (" x" .. qty) or "")
	end
	if type(reward.luckyBlocks) == "table" then
		for _, b in ipairs(reward.luckyBlocks) do
			local nm = ({ lucky_block = "Lucky Block", super_lucky_block = "Diamond Lucky Block",
				godly_lucky_block = "Godly Lucky Block" })[b.id] or "Lucky Block"
			local qty = b.qty or 1
			parts[#parts + 1] = nm .. ((qty > 1) and (" x" .. qty) or "")
		end
	end
	return parts
end

function MineScrolls.describeDaily(reward, zone, streak)
	local parts = MineScrolls.dailyParts(reward, zone, streak)
	if #parts == 0 then
		return "--"
	end
	return table.concat(parts, "  +  ")
end

--[[
	The week the next claim sits in, as seven tiles for the calendar. `shown`
	is the streak of the tile to highlight (the next claim when one is ready,
	today's claim when it is already taken).
]]
function MineScrolls.dailyCalendar(shown, ready, zone)
	local s = math.max(1, math.floor(tonumber(shown) or 1))
	local todayDay = MineScrolls.dailyDay(s)
	local cycleStart = s - (todayDay - 1)
	local out = {}
	for i = 1, MineScrolls.DAILY_DAYS do
		local reward = MineScrolls.DAILY[i]
		out[i] = {
			day = i,
			parts = MineScrolls.dailyParts(reward, zone, cycleStart + i - 1),
			claimed = (i < todayDay) or (i == todayDay and not ready),
			today = i == todayDay,
			jackpot = reward.jackpot == true,
		}
	end
	return out
end
return MineScrolls
