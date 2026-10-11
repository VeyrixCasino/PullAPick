--[[
	MineFishing -- fishing's rules and data (TODO A3). Pure: no services, no
	profile writes, so the server, the client and tools/verify/fishing.js all
	read the same numbers. The fight itself is MineFishingFight; the verbs are
	ServerScriptService/Mine/MineFishingService.

	THE OWNER'S CALLS (2026-10-10/11; wiki systems/fishing):
	  * The first spot is in ZONE 2 (Greyvein Quarry, id sunscar), on the
	    surface. Every zone gets "a couple underground fishing areas ... (at
	    outposts)": the station bays of the 1,000 and 3,000 outposts, deeper
	    ones luckier. Each zone has its own fish.
	  * RODS cost coins. Upgrading one "gets retarded expensive super fast"
	    (x1.6 a level, 50 levels), and "every 10 levels you have to prestige
	    with tokens, to unlock the next 10 levels" -- tokens are TEMPER tokens
	    (owner: "IF I EVER SAY TOKENS I MEAN TEMPER TOKENS"). Rod levels stay
	    through rebirth. Four rods; the top one casts 5 bait at once: ONE fight
	    against the best fish, win all five or lose all five, and the catch is
	    shown worst to best.
	  * BAIT is not bought with coins: it is AFK'd for (1 per 8 minutes
	    online), paid by daily quests (+2 each) or bought with tokens (10
	    each), and all of it counts toward 15 a day.
	  * CAST then REEL, both minigames: a good or perfect cast is a luck bonus;
	    the reel is MineFishingFight. No skipping.
	  * A catch is a FISH CARD in your COOLER, the fish inventory, opened at
	    any fishing spot. Selling comes later ("idk tbh.. just make it give
	    fish cards for now").
	  * "make rare fish actually rare": a 5-star fish is 1 in 2,000 casts
	    before luck.
]]
local M = {}

-- ------------------------------------------------------------ grades --

-- Stars, 1 to 5 in half steps (TODO §0: every grade in stars, nine of them).
M.GRADES = { 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5 }
M.GRADE_TEXT = { "★", "★½", "★★", "★★½", "★★★", "★★★½", "★★★★", "★★★★½", "★★★★★" }
M.GRADE_COLOR = {
	Color3.fromRGB(176, 178, 186), -- 1
	Color3.fromRGB(150, 205, 160), -- 1.5
	Color3.fromRGB(96, 214, 120), -- 2
	Color3.fromRGB(70, 200, 210), -- 2.5
	Color3.fromRGB(84, 150, 255), -- 3
	Color3.fromRGB(170, 110, 255), -- 3.5
	Color3.fromRGB(255, 164, 60), -- 4
	Color3.fromRGB(255, 110, 190), -- 4.5
	Color3.fromRGB(255, 70, 70), -- 5
}

--[[
	How often each grade bites, before luck: weights, out of 9,995. A 5-star
	fish is 1 in 2,000 casts; 4.5 is 1 in 333; 4 is 1 in 111. Luck lifts a
	grade by luck ^ ((grade - 1) / 8): a 5-star by the whole of it, a 1-star
	not at all, so luck never makes the common fish rarer by more than the
	renormalising.
]]
M.GRADE_WEIGHT = { 4500, 2500, 1400, 800, 450, 220, 90, 30, 5 }

--[[
	How hard each grade fights: MineFishingFight.fishFromDifficulty's number.
	TUNED, not guessed (owner: "test with a little shitty learning machine, and
	figure out whats the brink of possibility, and tone down from there").
	tools/sim/fishing-tune.js trains a bot and finds the BRINK -- the hardest
	fish a perfect-reflex bot lands half the time -- then the 5-star sits a
	notch under it and the rest step down. Its last report is in
	docs/FISHING-TUNING.md; rerun it after touching the fight.
]]
M.DIFFICULTY = { 0.080, 0.108, 0.147, 0.199, 0.269, 0.364, 0.493, 0.667, 0.903 }

-- Later zones' fish fight harder; the zone's rods are levelled to match.
M.ZONE_DIFFICULTY = {
	sunscar = 1,
}

-- ------------------------------------------------------------- fish --

--[[
	Each zone's own fish (owner: "Make each zone have different fish").
	`grade` indexes GRADES; `kg` is the size range, most catches near the low
	end. Ids are save data: the cooler is keyed by them.
]]
M.FISH = {
	sunscar = {
		{ id = "gravel_minnow", name = "Gravel Minnow", grade = 1, kg = { 0.05, 0.2 } },
		{ id = "slate_guppy", name = "Slate Guppy", grade = 1, kg = { 0.03, 0.15 } },
		{ id = "grit_perch", name = "Grit Perch", grade = 2, kg = { 0.2, 0.8 } },
		{ id = "pebble_loach", name = "Pebble Loach", grade = 2, kg = { 0.1, 0.5 } },
		{ id = "quarry_bass", name = "Quarry Bass", grade = 3, kg = { 0.6, 2.5 } },
		{ id = "flint_trout", name = "Flint Trout", grade = 3, kg = { 0.5, 2.2 } },
		{ id = "shale_pike", name = "Shale Pike", grade = 4, kg = { 1.5, 6 } },
		{ id = "chisel_catfish", name = "Chisel Catfish", grade = 5, kg = { 2, 12 } },
		{ id = "granite_carp", name = "Granite Carp", grade = 6, kg = { 3, 15 } },
		{ id = "greyvein_eel", name = "Greyvein Eel", grade = 7, kg = { 4, 20 } },
		{ id = "bedrock_sturgeon", name = "Bedrock Sturgeon", grade = 8, kg = { 20, 90 } },
		{ id = "monolith_koi", name = "Monolith Koi", grade = 9, kg = { 40, 160 } },
	},
}

M.FISH_BY_ID = {}
for zoneId, list in pairs(M.FISH) do
	for _, f in ipairs(list) do
		f.zoneId = zoneId
		M.FISH_BY_ID[f.id] = f
	end
end

function M.fish(id)
	return M.FISH_BY_ID[id]
end

-- ------------------------------------------------------------ spots --

--[[
	Where you can fish. The surface pond is built by WorldBuilder; the
	underground ones sit in the station bay of their seam's outpost
	(MineDepthPlazas). `luck` multiplies the catch luck: deeper is better.
]]
M.OUTPOST_SEAMS = { 1000, 3000 }
M.OUTPOST_LUCK = { [1000] = 1.25, [3000] = 1.6 }
M.SPOT_RADIUS = 40 -- studs from the spot's dock the server accepts a cast

M.SPOTS = {}
M.SPOT_BY_ID = {}
local function addSpot(spot)
	table.insert(M.SPOTS, spot)
	M.SPOT_BY_ID[spot.id] = spot
end
addSpot({ id = "sunscar_pond", zoneId = "sunscar", kind = "surface", name = "Quarry Pool", luck = 1 })
for zoneId in pairs(M.FISH) do
	for _, seam in ipairs(M.OUTPOST_SEAMS) do
		addSpot({
			id = zoneId .. "_" .. seam,
			zoneId = zoneId,
			kind = "outpost",
			seam = seam,
			name = (seam == 1000) and "Seep Pool" or "Deep Sump",
			luck = M.OUTPOST_LUCK[seam] or 1,
		})
	end
end

function M.spot(id)
	return M.SPOT_BY_ID[id]
end

-- ------------------------------------------------------------- rods --

--[[
	Four rods, bought with coins. `reel` is metres a second on a green fish,
	`line` divides the tension a reel adds, `luck` multiplies the catch luck,
	`bait` is how many bait one cast spends (and how many fish bite).

	Levels: each adds to the rod's own numbers (LEVEL_GAIN, of its base), and
	costs levelBase x LEVEL_COST_GROW ^ level coins. Every PRESTIGE_EVERY
	levels the rod stops until you pay PRESTIGE_TOKENS temper tokens.
	PROPOSED prices (owner chose the shape: 4 rods, 50 levels, x1.6).
]]
M.RODS = {
	{ id = "twig_rod", name = "Twig Rod", price = 0, bait = 1, reel = 4, line = 1, luck = 1, levelBase = 400,
		blurb = "Everyone's first rod. Free." },
	{ id = "quarry_rod", name = "Quarry Rod", price = 60000, bait = 1, reel = 4.8, line = 1.25, luck = 1.12,
		levelBase = 6000, blurb = "Stiffer line, faster reel." },
	{ id = "deepline_rod", name = "Deepline Rod", price = 4000000, bait = 1, reel = 5.6, line = 1.55, luck = 1.25,
		levelBase = 300000, blurb = "Built for the long fights." },
	{ id = "trawler_rod", name = "Trawler Rod", price = 300000000, bait = 5, reel = 6, line = 1.8, luck = 1.35,
		levelBase = 20000000, blurb = "Casts 5 bait at once. One fight for all five: land it or lose them all." },
}
M.ROD_BY_ID = {}
for i, r in ipairs(M.RODS) do
	r.index = i
	M.ROD_BY_ID[r.id] = r
end
M.STARTER_ROD = "twig_rod"

M.LEVEL_MAX = 50
M.LEVEL_COST_GROW = 1.6
M.LEVEL_GAIN = { reel = 0.02, line = 0.025, luck = 0.015 }
M.PRESTIGE_EVERY = 10
M.PRESTIGE_TOKENS = { 100, 300, 1000, 3000 }

function M.rod(id)
	return M.ROD_BY_ID[id]
end

-- A rod's numbers at a level.
function M.rodStats(id, level)
	local r = M.ROD_BY_ID[id] or M.ROD_BY_ID[M.STARTER_ROD]
	level = math.clamp(math.floor(tonumber(level) or 0), 0, M.LEVEL_MAX)
	return {
		reel = r.reel * (1 + M.LEVEL_GAIN.reel * level),
		line = r.line * (1 + M.LEVEL_GAIN.line * level),
		luck = r.luck * (1 + M.LEVEL_GAIN.luck * level),
		bait = r.bait,
	}
end

-- Coins to go from `level` to level + 1.
function M.levelCost(id, level)
	local r = M.ROD_BY_ID[id]
	if not r then
		return math.huge
	end
	return math.floor(r.levelBase * M.LEVEL_COST_GROW ^ math.max(0, level) + 0.5)
end

-- The highest level a rod can reach with `gates` prestiges paid.
function M.levelCap(gates)
	return math.min(M.LEVEL_MAX, M.PRESTIGE_EVERY * (math.max(0, math.floor(tonumber(gates) or 0)) + 1))
end

-- Tokens for the next prestige, or nil when there is none left.
function M.prestigeCost(gates)
	return M.PRESTIGE_TOKENS[math.max(0, math.floor(tonumber(gates) or 0)) + 1]
end

-- ------------------------------------------------------------- bait --

M.BAIT_DAY_CAP = 15
M.AFK_SECS_PER_BAIT = 8 * 60
M.QUEST_BAIT = 2
M.TOKEN_PRICE = 10 -- temper tokens a bait

-- How many more bait can be gained today.
function M.baitRoom(gotToday)
	return math.max(0, M.BAIT_DAY_CAP - math.floor(tonumber(gotToday) or 0))
end

-- ------------------------------------------------------------- cast --

--[[
	THE CAST. A power bar sweeps up and down (PERIOD seconds for the round
	trip); stop it on the sweet spot. Owner: "we will have a good and perfect
	cast luck bonus". The bar is a pure function of the tick, so the server
	works out the quality from the tick the client stopped on.
]]
M.CAST = {
	period = 1.6,
	sweet = 0.85,
	perfect = 0.035,
	good = 0.11,
	luck = { perfect = 1.5, good = 1.2, ok = 1 },
	maxTicks = 30 * 20, -- 20 seconds to make up your mind
}

-- Where the bar is (0..1) on `tick` (30 a second).
function M.castBar(tick)
	local hz = 30
	local phase = ((tonumber(tick) or 0) / (M.CAST.period * hz)) % 1
	return (phase < 0.5) and (phase * 2) or (2 - phase * 2)
end

function M.castQuality(tick)
	local off = math.abs(M.castBar(tick) - M.CAST.sweet)
	if off <= M.CAST.perfect then
		return "perfect"
	elseif off <= M.CAST.good then
		return "good"
	end
	return "ok"
end

-- Seconds between the cast landing and the bite.
M.BITE = { 1.2, 3.5 }

-- ------------------------------------------------------------ catch --

-- The catch table at a luck: { { fish, p } ... } in grade order, p sums to 1.
function M.catchOdds(zoneId, luck)
	local list = M.FISH[zoneId] or {}
	luck = math.max(1, tonumber(luck) or 1)
	local perGrade = {}
	for _, f in ipairs(list) do
		perGrade[f.grade] = (perGrade[f.grade] or 0) + 1
	end
	local rows, total = {}, 0
	for _, f in ipairs(list) do
		local w = (M.GRADE_WEIGHT[f.grade] or 0) / perGrade[f.grade] * luck ^ ((f.grade - 1) / 8)
		total += w
		table.insert(rows, { fish = f, p = w })
	end
	for _, r in ipairs(rows) do
		r.p = (total > 0) and (r.p / total) or 0
	end
	return rows
end

--[[
	One fish: { id, kg, size }. `size` is 0..1 within its kind and is what
	makes a big one fight harder (MineFishingFight.spiritOf). It is a uniform
	roll SQUARED, so most catches are small: half of them sit in the bottom
	quarter of the range.
]]
function M.rollFish(zoneId, luck, rng)
	rng = rng or Random.new()
	local u = rng:NextNumber()
	local pick
	for _, r in ipairs(M.catchOdds(zoneId, luck)) do
		u -= r.p
		pick = r.fish
		if u <= 0 then
			break
		end
	end
	if not pick then
		return nil
	end
	local lo, hi = pick.kg[1], pick.kg[2]
	local s = rng:NextNumber()
	local size = s * s
	local kg = lo + (hi - lo) * size
	return { id = pick.id, kg = math.floor(kg * 100 + 0.5) / 100, size = math.floor(size * 1000 + 0.5) / 1000 }
end

-- How hard a fish of this grade fights in this zone.
function M.difficulty(zoneId, grade)
	return (M.DIFFICULTY[grade] or M.DIFFICULTY[1]) * (M.ZONE_DIFFICULTY[zoneId] or 1)
end

-- Sort a catch worst to best (owner: "it goes from least to best").
function M.sortCatch(list)
	table.sort(list, function(a, b)
		local fa, fb = M.FISH_BY_ID[a.id], M.FISH_BY_ID[b.id]
		local ga, gb = fa and fa.grade or 0, fb and fb.grade or 0
		if ga ~= gb then
			return ga < gb
		end
		return (a.kg or 0) < (b.kg or 0)
	end)
	return list
end

return M
