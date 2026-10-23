--[[
	MineCases -- PACK CASES. A case holds PACKS, never cards: open one and its
	packs land in your bag, to be opened like any other pack.

	Owner, 2026-10-10: "Should have 2 types of cases.. Cases for a set
	(determines what exact packs and how many [3 min]{stardust})), and cases
	that is a complete wild draw (such as chest cases, random packs, random set)".

	  WILD CASES  one per star grade, 1★ to 5★ in half steps (M.WILD_GRADES):
	              a CS:GO-style spin over packs of that grade from any set,
	              top-graded sets rarer (MineSetPacks.GRADE_WEIGHT); you get 3
	              of the pack it lands on (M.WILD_PACKS, M.wildReel). Chests
	              drop them, the daily wheel pays them, and both shops sell
	              them. The SSS set only ever comes out of one bought with
	              credits (M.PAID_ONLY_GRADES).
	  SET CASES   "<setKey>_case_<starter|collector|vault>", three per set,
	              exact contents, sold for stardust, and only for the sets
	              graded B or lower (M.SHOP_MAX_GRADE):
	                Starter    ★ + ★½ + ★★
	                Collector  ★★ + ★★★ + ★★★ + ★★★★
	                Vault      ★★★★ + ★★★★ + ★★★★★

	The prices, chest rates, wheel slices and featured packs were decided in
	the owner's pricing pass, 2026-10-10 (wiki: systems/pack-cases).

	Ids are data: a case sits in a save as a bag row in p.packs.

	MinePackConfig registers every case in PACK_BY_ID (kind "pack_case"), so the
	bag tile, the stars, the sort and the shops read a case like a pack.
	Opening one never reaches openPack: MineServer hands any case to
	MineCases.open first, the way it hands lucky blocks to openLuckyBlock.

	Nothing here requires MinePackConfig at load: MinePackConfig requires this
	module, and a require loop never returns. The prices read it lazily.
]]
local M = {}

local SetPets = require(script.Parent:WaitForChild("MineSetPets"))
local SetPacks = require(script.Parent:WaitForChild("MineSetPacks"))
local Art = require(script.Parent:WaitForChild("MinePackArt"))

M.KIND = "pack_case"

--[[
	The 19 sets in the owner's order: { key, name, grade, index }. From the set
	pets when they are loaded, else from the pack-art list, which carries the
	same names and grades (tools/pack-sprites/sets.js).
]]
M.SETS = {}
M.SET_BY_KEY = {}
do
	if #(SetPets.SETS or {}) > 0 then
		for i, s in ipairs(SetPets.SETS) do
			table.insert(M.SETS, { key = s.KEY, name = s.NAME, grade = s.GRADE, index = s.INDEX or i })
		end
	else
		for i, key in ipairs(Art.ORDER or {}) do
			local a = Art.SETS[key]
			table.insert(M.SETS, { key = key, name = a.name, grade = a.grade, index = a.index or i })
		end
	end
	for _, s in ipairs(M.SETS) do
		M.SET_BY_KEY[s.key] = s
	end
end

M.GRADE_RANK = { F = 1, D = 2, C = 3, B = 4, A = 5, S = 6, SS = 7, SSS = 8 }

--[[
	WHAT THE SHOPS CARRY. Owner, 2026-10-10: "Make it so shops dont carry any
	sets above b". Set cases and featured set packs are sold only for sets
	graded B or lower; the A, S, SS and SSS sets come out of wild cases only,
	which is what makes a wild case the better buy.
]]
M.SHOP_MAX_GRADE = "B"

function M.inShops(setKey)
	local set = M.SET_BY_KEY[setKey]
	return set ~= nil and (M.GRADE_RANK[set.grade] or 99) <= M.GRADE_RANK[M.SHOP_MAX_GRADE]
end

--[[
	THE SSS SET. Owner, 2026-10-10: Chaos Theory comes "credits, and 0.5%
	only" (and stays something you trade for). Only a wild case bought with
	credits can roll it, in exactly this share of its slots; every other wild
	case (chests, the wheel, stardust) never does. A credit-bought case
	carries `paid` on its bag row (MineCases.bagRow).
]]
M.PAID_ONLY_GRADES = { SSS = true }
M.PAID_ONLY_SHARE = 0.005

-- PROPOSED. The three set cases, by the star grade (1..6) of each pack inside.
M.SET_CASES = {
	{ key = "starter", name = "Starter Case", levels = { 1, 2, 3 } },
	{ key = "collector", name = "Collector Case", levels = { 3, 4, 4, 5 } },
	{ key = "vault", name = "Vault", levels = { 5, 5, 6 } },
}

--[[
	A chest's chance of a case (M.CHEST_CASE_CHANCE) is multiplied by the
	player's chest luck, but never by more than this (owner: keep chest luck).
]]
M.CHEST_LUCK_CAP = 3

-- PROPOSED. Wild cases from this star grade up announce themselves when a
-- chest drops one (a popup, not just a line on the chest card).
M.CHEST_POPUP_LEVEL = 5

--[[
	THE WILD CASES, ONE PER STAR GRADE: 1★ to 5★ in half steps, nine grades
	(TODO §NOW, decided; owner 2026-10-10: "I need 2.5, 3.5 and 4.5 stars per
	case"). A case is better only because the packs in it are: no luck boost.

	`levels` are the pack star levels (MineSetPacks.STARS index 1..6) a slot
	draws from. The sets have no 2.5, 3.5 or 4.5 packs, so a half-star case
	mixes its two neighbours, each pack a coin flip (owner: "Mix of both").

	Ids are data: "case_<level>" for a whole grade (case_1..case_6, as shipped),
	"case_<lo>_<hi>" for a half grade. A row may name its `id` outright.

	`weights` (optional) splits a mixed case's packs between its levels; with
	none, each level is equally likely (M.levelOdds).

	EVERY CASE GIVES THE STARS IT SAYS. Owner, 2026-10-11: "set it up so they
	all give how many stars it says.. keep original price". This undid a
	same-day change that made the top two a chance (★★★★★ 35% ★★★★★ packs,
	★★★★½ 15%), which had priced the ★★★★★ case down to 12,500 stardust. A
	whole-star case pays only its own packs; a half-star case is the coin flip
	between its neighbours the owner first chose ("Mix of both"), so it averages
	the stars it says. Prices are the 70% return on that, the original rule.
	`weights` stays supported (M.levelOdds) but no row uses it.
]]
M.WILD_GRADES = {
	{ levels = { 1 }, stars = 1, text = "★" },
	{ levels = { 2 }, stars = 1.5, text = "★½" },
	{ levels = { 3 }, stars = 2, text = "★★" },
	{ levels = { 3, 4 }, stars = 2.5, text = "★★½" },
	{ levels = { 4 }, stars = 3, text = "★★★" },
	{ levels = { 4, 5 }, stars = 3.5, text = "★★★½" },
	{ levels = { 5 }, stars = 4, text = "★★★★" },
	{ levels = { 5, 6 }, stars = 4.5, text = "★★★★½" },
	{ levels = { 6 }, stars = 5, text = "★★★★★" },
}

-- One spin, and you get this many of the pack it lands on (owner: "Whatever
-- reel lands on, you get 3 of").
M.WILD_PACKS = 3

-- The wild case of a pack star level (1..6), or of a pair of them.
function M.wildId(level, hi)
	if hi and hi ~= level then
		return "case_" .. level .. "_" .. hi
	end
	return "case_" .. level
end

-- The id of a WILD_GRADES row.
function M.wildGradeId(g)
	return g.id or M.wildId(g.levels[1], g.levels[#g.levels])
end

--[[
	A wild case's pack levels and how likely each is: { { level, p } ... },
	p summing to 1. Even unless the case names `weights`. The roll, the reel,
	the price and the inspector all read this, so they cannot disagree.
]]
function M.levelOdds(def)
	local levels = (def and def.levels) or { def and def.starLevel or 1 }
	local weights = def and def.weights
	local total = 0
	for i = 1, #levels do
		total += math.max(0, tonumber(weights and weights[i]) or 1)
	end
	local out = {}
	for i, level in ipairs(levels) do
		local w = math.max(0, tonumber(weights and weights[i]) or 1)
		table.insert(out, { level = level, p = (total > 0) and (w / total) or (1 / #levels) })
	end
	return out
end

function M.setCaseId(setKey, kind)
	return setKey .. "_case_" .. kind
end

M.CASES = {}
M.BY_ID = {}
M.WILD = {} -- the wild cases, worst to best

local function add(def)
	def.kind = M.KIND
	table.insert(M.CASES, def)
	M.BY_ID[def.id] = def
end

for _, g in ipairs(M.WILD_GRADES) do
	local lo, hi = g.levels[1], g.levels[#g.levels]
	local packText = SetPacks.STAR_TEXT[lo]
	if hi ~= lo then
		packText = SetPacks.STAR_TEXT[lo] .. " or " .. SetPacks.STAR_TEXT[hi]
	end
	local def = {
		id = M.wildGradeId(g),
		name = g.text .. " Wild Case",
		caseType = "wild",
		levels = g.levels,
		weights = g.weights,
		-- The colour and rank of a half grade are its lower neighbour's, so a
		-- 2.5★ case never passes for a 3★ one. The ★★★★★ case names its own.
		starLevel = g.starLevel or lo,
		stars = g.stars,
		cards = 0,
		packText = packText,
		blurb = "one spin: 3 of the " .. packText .. " pack it lands on, from any set",
	}
	if g.weights and hi ~= lo then
		local odds = M.levelOdds(def)
		def.blurb ..= string.format(" (%d%% %s)", math.floor(odds[#odds].p * 100 + 0.5), SetPacks.STAR_TEXT[hi])
	end
	add(def)
	table.insert(M.WILD, def)
end

for _, set in ipairs(M.SETS) do
	for _, kind in ipairs(M.SET_CASES) do
		local packs, top = {}, 1
		for _, level in ipairs(kind.levels) do
			table.insert(packs, SetPacks.packId(set.key, level))
			top = math.max(top, level)
		end
		-- Every set gets the rows, so a case already in a bag still opens;
		-- only the sets the shops carry are for sale (M.inShops).
		add({
			id = M.setCaseId(set.key, kind.key),
			name = set.name .. " " .. kind.name,
			caseType = "set",
			caseKind = kind.key,
			setKey = set.key,
			setName = set.name,
			grade = set.grade,
			forSale = M.inShops(set.key),
			-- PROPOSED: a set case shows the stars of the best pack in it.
			starLevel = top,
			stars = SetPacks.STARS[top],
			packs = packs,
			cards = #packs,
			blurb = #packs .. " " .. set.name .. " packs",
		})
	end
end

function M.get(id)
	return M.BY_ID[tostring(id or "")]
end

function M.isCase(id)
	return M.get(id) ~= nil
end

-- The star grade (1..6) of a set pack id, and its set key.
function M.parsePack(packId)
	local key, level = string.match(tostring(packId or ""), "^(.-)_pack_(%d)$")
	level = tonumber(level)
	if not (key and M.SET_BY_KEY[key] and level and SetPacks.STARS[level]) then
		return nil
	end
	return key, level
end

function M.packName(packId)
	local def = SetPacks.PACK_BY_ID and SetPacks.PACK_BY_ID[packId]
	if def and def.name then
		return def.name
	end
	local key, level = M.parsePack(packId)
	if not key then
		return tostring(packId)
	end
	return M.SET_BY_KEY[key].name .. " " .. SetPacks.STAR_TEXT[level]
end

-- The rarity colour a case or a set pack borrows on reveals and popups.
function M.rarityOf(id)
	local def = M.get(id)
	local level = (def and def.starLevel) or select(2, M.parsePack(id)) or 1
	return SetPacks.STAR_TIER[level] or "Common"
end

-- "3 packs", "3-5 packs": what a case tile says it holds.
function M.countText(id)
	local def = M.get(id)
	if not def then
		return ""
	end
	if def.caseType == "set" then
		return #def.packs .. " packs"
	end
	return "1 spin · " .. M.WILD_PACKS .. " packs"
end

-- ------------------------------------------------------------- rolling --

local function weighted(rows, rng, weightOf)
	local total = 0
	for _, row in ipairs(rows) do
		total += math.max(0, weightOf(row))
	end
	if total <= 0 then
		return rows[1]
	end
	local roll = (rng and rng:NextNumber() or math.random()) * total
	for _, row in ipairs(rows) do
		roll -= math.max(0, weightOf(row))
		if roll <= 0 then
			return row
		end
	end
	return rows[#rows]
end

-- The sets a wild slot draws from: everything but the paid-only grades, or
-- only the paid-only grades.
local function wildPool(paidOnly)
	local out = {}
	for _, s in ipairs(M.SETS) do
		if (M.PAID_ONLY_GRADES[s.grade] == true) == paidOnly then
			table.insert(out, s)
		end
	end
	return out
end

--[[
	The set filling one wild slot: any set, top grades rarer
	(MineSetPacks.GRADE_WEIGHT). A credit-bought case (`paid`) first gives
	the paid-only sets their fixed share.
]]
function M.rollWildSet(rng, paid)
	local special = wildPool(true)
	if paid and #special > 0 and (rng and rng:NextNumber() or math.random()) < M.PAID_ONLY_SHARE then
		local set = weighted(special, rng, function(s)
			return SetPacks.GRADE_WEIGHT[s.grade] or 1
		end)
		return set and set.key
	end
	local set = weighted(wildPool(false), rng, function(s)
		return SetPacks.GRADE_WEIGHT[s.grade] or 1
	end)
	return set and set.key
end

--[[
	For the inspector: how likely one wild slot is to come from a set of each
	grade, best grade last: { { grade, pct, sets, paidOnly } }. The paid-only
	grades print their share of a credit-bought case.

	`paid` asks for a CREDIT-BOUGHT case's exact odds (the shop's mystery
	buyer, launch audit M3): rollWildSet gives the paid-only sets their share
	first, so every other grade gets (1 - PAID_ONLY_SHARE) of its weight and the
	rows sum to 100. Without it, the rows are an earned case's odds (the other
	grades are the whole draw), and the paid-only rows are listed, flagged, for
	the inspector to say which cases can roll them.
]]
function M.wildGradeOdds(paid)
	local scale = 1
	if paid == true and #wildPool(true) > 0 then
		scale = 1 - M.PAID_ONLY_SHARE
	end
	local byGrade, total = {}, 0
	for _, s in ipairs(wildPool(false)) do
		local w = SetPacks.GRADE_WEIGHT[s.grade] or 1
		total += w
		byGrade[s.grade] = byGrade[s.grade] or { grade = s.grade, pct = 0, sets = 0 }
		byGrade[s.grade].pct += w
		byGrade[s.grade].sets += 1
	end
	local out = {}
	for _, g in ipairs({ "F", "D", "C", "B", "A", "S", "SS", "SSS" }) do
		local row = byGrade[g]
		if row then
			row.pct = (total > 0) and (row.pct / total * 100 * scale) or 0
			table.insert(out, row)
		elseif M.PAID_ONLY_GRADES[g] then
			local n = 0
			for _, s in ipairs(M.SETS) do
				if s.grade == g then
					n += 1
				end
			end
			if n > 0 then
				table.insert(out, { grade = g, pct = M.PAID_ONLY_SHARE * 100, sets = n, paidOnly = true })
			end
		end
	end
	return out
end

-- What a case holds, as set pack ids. A set case always holds the same.
-- `paid` is true for a wild case bought with credits.
function M.contents(id, rng, paid)
	local def = M.get(id)
	if not def then
		return {}
	end
	if def.caseType == "set" then
		return table.clone(def.packs)
	end
	-- One spin: you get WILD_PACKS of the pack it lands on.
	local packId = M.rollWildPack(def, rng, paid)
	local out = {}
	for _ = 1, M.WILD_PACKS do
		table.insert(out, packId)
	end
	return out
end

-- One wild pack: a set (top grades rarer) and, for a mixed case, one of its
-- pack levels by M.levelOdds (a coin flip unless the case names weights).
function M.rollWildPack(def, rng, paid)
	local key = M.rollWildSet(rng, paid) or (M.SETS[1] and M.SETS[1].key)
	local pick = weighted(M.levelOdds(def), rng, function(r)
		return r.p
	end)
	return SetPacks.packId(key, pick and pick.level or def.starLevel or 1)
end

--[[
	THE REEL. Owner, 2026-10-10: "these myster cases are meant to be like csgo
	slots", and "Whatever reel lands on, you get 3 of". A wild case opens on a
	CS:GO-style reel (MineGradeReveal.caseSpin) of packs from random sets, each
	coloured by its set's grade on the shared rarity ladder (MineTemper:
	F Common grey ... S Mythic light blue, SS Divine lavender, SSS Exotic red).

	The winner is decided before the reel is built, and sits at REEL_WIN_AT.
	The other tiles are drawn the same way the winner was, so the reel shows
	what this case can really land on: an SSS tile only on a credit-bought case.
]]
M.REEL_LENGTH = 44
M.REEL_WIN_AT = 38

local function reelRow(packId)
	local key = M.parsePack(packId)
	local set = key and M.SET_BY_KEY[key]
	local art = Art.packArt(packId)
	return {
		id = packId,
		rarity = (set and set.grade) or "F",
		name = M.packName(packId),
		icon = art and art.image or nil,
	}
end

function M.wildReel(def, winPackId, rng, paid)
	local rows = {}
	for i = 1, M.REEL_LENGTH do
		if i == M.REEL_WIN_AT then
			table.insert(rows, reelRow(winPackId))
		else
			table.insert(rows, reelRow(M.rollWildPack(def, rng, paid)))
		end
	end
	return rows, M.REEL_WIN_AT
end

-- -------------------------------------------------------------- the bag --

-- A case as a bag row. `setId` is the case's set, or "wild": never a random
-- old card set, which the bag tile would print as the case's set. `paid` marks
-- a wild case bought with credits, the only kind that can roll the SSS set.
function M.bagRow(id, paid)
	local def = M.get(id)
	if not def then
		return nil
	end
	return {
		packId = def.id,
		packName = def.name,
		kind = M.KIND,
		setId = def.setKey or "wild",
		paid = (paid and def.caseType == "wild") or nil,
	}
end

-- A set pack as a bag row, the shape Verbs.grantPacks writes.
function M.packRow(packId)
	local key = M.parsePack(packId)
	return {
		packId = packId,
		packName = M.packName(packId),
		setId = key,
	}
end

--[[
	OPEN ONE CASE. The caller has already taken `pk` out of the bag. Its packs
	go into p.packs, and this returns what the reveal shows: one loot row per
	pack (MineClient paints kind "pack" with the pack's own art) and the
	design the reveal tears open.

	No luck rides into the packs. Owner, 2026-10-10: a higher grade is better
	"by design (Not a % boos[t])" -- its packs' own odds, nothing stamped on.
]]
function M.open(p, pk, rng)
	local def = M.get(pk and pk.packId)
	if not def then
		return nil
	end
	rng = rng or Random.new()
	p.packs = p.packs or {}
	local loot = {}
	for _, packId in ipairs(M.contents(def.id, rng, pk.paid == true)) do
		local row = M.packRow(packId)
		table.insert(p.packs, row)
		local key, level = M.parsePack(packId)
		local set = key and M.SET_BY_KEY[key]
		table.insert(loot, {
			kind = "pack",
			packId = packId,
			name = row.packName,
			rarityId = SetPacks.STAR_TIER[level or 1] or "Common",
			setName = set and set.name or nil,
			stars = level and SetPacks.STARS[level] or nil,
			-- The reveal card's small print: the set and its grade.
			sub = set and (set.name .. "  ·  grade " .. tostring(set.grade)) or nil,
		})
	end
	p.packsOpened = p.packsOpened or {}
	p.packsOpened[def.id] = (tonumber(p.packsOpened[def.id]) or 0) + 1
	local design = {
		packId = def.id,
		name = def.name,
		setName = def.setName or "Any set",
		kind = M.KIND,
	}
	--[[
		A wild case spins (MineClient plays it on MineGradeReveal.caseSpin): the
		reel, where it stops, and the words for the result. The packs are already
		in the bag; the reel only shows which one it was.
	]]
	if def.caseType == "wild" and loot[1] then
		local won = loot[1].packId
		local key = M.parsePack(won)
		local set = key and M.SET_BY_KEY[key]
		local reel, at = M.wildReel(def, won, rng, pk.paid == true)
		design.reel = {
			reel = reel,
			at = at,
			id = won,
			rarity = (set and set.grade) or "F",
			title = def.name,
			resultText = #loot .. "x  " .. loot[1].name,
			resultSub = set and (set.name .. "  ·  grade " .. set.grade .. "  ·  "
				.. (SetPacks.STAR_TEXT[select(2, M.parsePack(won)) or 1] or "")) or "",
			note = "in your bag",
			celebrateTitle = string.upper((set and set.name) or "JACKPOT") .. "!",
		}
	end
	return loot, design
end

--[[
	CHEST CASES. Owner, 2026-10-10, on the old 0.5-10% by rank: "WAY to high
	(look at the value difference.. make each rarity 2x as rare as the last..
	10% base drop rate for case)", then chose "10% get a case, grades halve"
	and "better chests, better grades".

	  CHEST_CASE_CHANCE  a chest drops a case this often (chest luck raises
	                     it, capped at CHEST_LUCK_CAP)
	  CHEST_GRADE_FALLOFF each grade is this much as common as the one below:
	                     ★ 50% of cases, ★½ 25% ... ★★★★★ about 0.2%
	  CHEST_RANK_SHIFT   half-star steps the ladder starts above ★: a B chest
	                     starts at ★½, A at ★★, S at ★★½. F and D start below
	                     ★, and a grade below ★ is no case at all, so they drop
	                     one about a quarter and a half as often.

	F TO SSS (2026-10-19). Chests rank F..SSS now, F the everyday one
	(MineChestRanks), so the shifts were re-cut on that ladder: a step may be a
	fraction, which mixes the two whole shifts around it (F -0.5 is half the
	-1 ladder and half the 0 one). PROPOSED, fitted so the case value of an
	average chest stays where it was on 3863d14 (tools/verify/economy-gems.js:
	within 10% at every depth).
]]
M.CHEST_CASE_CHANCE = 0.10
M.CHEST_GRADE_FALLOFF = 0.5
M.CHEST_RANK_SHIFT = {
	F = -0.5, D = 0, C = 0.5, B = 1.25, A = 2, S = 2.75, SS = 3.5, SSS = 4.5,
	native = 0,
}

-- The case ladder at one whole shift: { { def, p } }, and the no-case share.
local function caseOddsAt(shift)
	-- Ladder positions k = 0, 1, 2 ... start at grade index 1 + shift and
	-- run to the best grade; a position below grade 1 is "no case".
	local rows, total = {}, 0
	local k = 0
	while true do
		local index = 1 + shift + k
		if index > #M.WILD then
			break
		end
		local w = M.CHEST_GRADE_FALLOFF ^ k
		total += w
		table.insert(rows, { def = M.WILD[index], w = w })
		k += 1
	end
	local out, none = {}, 1 - M.CHEST_CASE_CHANCE
	for _, r in ipairs(rows) do
		local p = M.CHEST_CASE_CHANCE * r.w / total
		if r.def then
			table.insert(out, { def = r.def, p = p })
		else
			none += p
		end
	end
	return out, none
end

--[[
	The odds of each outcome when a chest of `rank` rolls its case:
	{ { def, p }, ... } with p per chest (no chest luck), plus the chance of no
	case. Used by the roll and by the wiki's numbers. A fractional shift mixes
	the two whole shifts around it.
]]
function M.chestCaseOdds(rank)
	local shift = tonumber(M.CHEST_RANK_SHIFT[rank or ""]) or 0
	local lo = math.floor(shift)
	local f = shift - lo
	if f <= 1e-9 then
		return caseOddsAt(lo)
	end
	local a, noneA = caseOddsAt(lo)
	local b, noneB = caseOddsAt(lo + 1)
	local byId, order = {}, {}
	local function add(rows, k)
		for _, r in ipairs(rows) do
			local row = byId[r.def.id]
			if not row then
				row = { def = r.def, p = 0 }
				byId[r.def.id] = row
				table.insert(order, row)
			end
			row.p += r.p * k
		end
	end
	add(a, 1 - f)
	add(b, f)
	return order, noneA * (1 - f) + noneB * f
end

--[[
	A chest's case, if it drops one: a bag row, or nil. `rank` is the chest's
	(MineZoneChests: F..S, or "native" for the meadow and Event Horizon). The
	chest luck stat raises the chance, capped; the grade is never boosted.
]]
function M.rollChestCase(rank, rng, chestLuck)
	rng = rng or Random.new()
	local luck = math.clamp(tonumber(chestLuck) or 1, 1, M.CHEST_LUCK_CAP)
	if rng:NextNumber() >= M.CHEST_CASE_CHANCE * luck then
		return nil
	end
	local odds = M.chestCaseOdds(rank)
	-- The grade, among the case outcomes plus "no case" for the low ranks.
	local rows, caseShare = {}, 0
	for _, r in ipairs(odds) do
		table.insert(rows, r)
		caseShare += r.p
	end
	table.insert(rows, { def = nil, p = math.max(0, M.CHEST_CASE_CHANCE - caseShare) })
	local pick = weighted(rows, rng, function(r)
		return r.p
	end)
	return pick and pick.def and M.bagRow(pick.def.id) or nil
end

-- -------------------------------------------------------------- prices --

--[[
	PRICES ARE SET BY RETURN: what the cards inside recycle for, as a share of
	the price. Owner, 2026-10-10: "Make it even, pretty numbers.. 50-70% rtp";
	then wild cases "should return 70% stardust value across the board", and
	set cases "55-65 (Higher teir less rtp, but more volitile)".

	  WILD_RTP      every wild case, every grade
	  SET_RTP_TOP   the set cases of the lowest set the shops carry (Pebblebound)
	  SET_RTP_LOW   ...falling evenly to the highest one (Royal Reserve), so a
	                better set costs more for the same recycle value: its pets
	                are stronger, which recycling does not pay for

	This replaced "+10% per better set" (SET_VALUE_STEP), which priced the
	stronger pets on top of the recycle value and so returned as little as 30%.
]]
M.WILD_RTP = 0.70
M.SET_RTP_TOP = 0.65
M.SET_RTP_LOW = 0.55

local function dustOfTier()
	local Packs = require(script.Parent:WaitForChild("MinePackConfig"))
	return Packs.RECYCLE_STARDUST or {}
end

--[[
	What a case, or a set pack, is expected to recycle for in stardust: each
	pack's expected card value (MineSetPacks.expectedPackDust over
	MinePackConfig.RECYCLE_STARDUST). Recycling pays by rarity only, but since
	2026-10-10 a set's grade scales its packs' Epic-and-better odds
	(MineSetPacks.GRADE_ODDS_MULT), so the set's grade is passed in. A wild
	case averages over the grades its reel can land on (wildGradeOdds).
]]
local function gradeOfKey(key)
	local s = key and M.SET_BY_KEY[key]
	return s and s.grade or nil
end

function M.expectedDust(id)
	local dust = dustOfTier()
	local def = M.get(id)
	if def and def.caseType == "set" then
		local ev = 0
		for _, packId in ipairs(def.packs) do
			local key, level = M.parsePack(packId)
			ev += SetPacks.expectedPackDust(level, dust, gradeOfKey(key))
		end
		return ev
	elseif def then
		-- A mixed case's pack is one of its levels by M.levelOdds; the set is
		-- any wild set, by the reel's own grade odds (free cases; the paid-only
		-- share is too small to price).
		local grades = {}
		for _, row in ipairs(M.wildGradeOdds()) do
			if not row.paidOnly then
				table.insert(grades, row)
			end
		end
		local per = 0
		for _, lv in ipairs(M.levelOdds(def)) do
			local ev = 0
			for _, row in ipairs(grades) do
				ev += SetPacks.expectedPackDust(lv.level, dust, row.grade) * row.pct / 100
			end
			per += ev * lv.p
		end
		return per * M.WILD_PACKS
	end
	local key, level = M.parsePack(id)
	if key then
		return SetPacks.expectedPackDust(level, dust, gradeOfKey(key))
	end
	return 0
end

-- The return a case or set pack is priced at (see above).
function M.rtpOf(id)
	local def = M.get(id)
	if def and def.caseType == "wild" then
		return M.WILD_RTP
	end
	local key = (def and def.setKey) or M.parsePack(id)
	local sets = M.shopSets()
	for i, s in ipairs(sets) do
		if s.key == key then
			local t = (#sets > 1) and ((i - 1) / (#sets - 1)) or 0
			return M.SET_RTP_TOP + (M.SET_RTP_LOW - M.SET_RTP_TOP) * t
		end
	end
	return M.SET_RTP_LOW
end

--[[
	A pretty price (owner: "even, pretty numbers"): under 100 to the nearest 5,
	otherwise two figures with the second a 0 or a 5 (3,683 -> 3,700; 44,655 ->
	44,500). Close enough that a return never moves more than a couple of points.
]]
function M.prettyPrice(n)
	n = tonumber(n) or 0
	if n < 100 then
		return math.max(5, math.floor(n / 5 + 0.5) * 5)
	end
	local step = 5 * 10 ^ (math.floor(math.log10(n)) - 2)
	return math.floor(n / step + 0.5) * step
end

-- The stardust price, or nil for anything the stardust shop does not carry.
function M.dustPrice(id)
	local def = M.get(id)
	if not def or (def.caseType == "set" and not def.forSale) then
		return nil
	end
	return M.prettyPrice(M.expectedDust(id) / M.rtpOf(id))
end

--[[
	PROPOSED. Credit price from the same curve the credit shop's packs sit on
	today: credits = 12 x (expected stardust / 250) ^ 0.45. Fitted 2026-10-10
	to the old shelf: Hopper 12 credits at ~250 expected stardust, Heirloom 55
	at ~6,900, Shiny 95 at ~24,000. Value rises faster than price, as it did
	there: a better pack is a better deal.

	Read off the case's recycle value, then scaled by its return the way the
	stardust price is (a wild case at 70% is the curve as-is; a set pack at
	55-65% costs a little more), and rounded to a pretty number.
]]
M.CREDIT_CURVE = { base = 12, at = 250, power = 0.45 }

local function creditsFor(id)
	local c = M.CREDIT_CURVE
	local ev = math.max(0, M.expectedDust(id))
	local credits = c.base * (ev / c.at) ^ c.power * (M.WILD_RTP / M.rtpOf(id))
	return M.prettyPrice(credits)
end

-- --------------------------------------------------------------- shops --

-- PROPOSED. The set packs the credit shop features each UTC day: four sets
-- the shops carry, one pack each, at these star grades.
M.FEATURED_LEVELS = { 4, 5, 5, 6 }

function M.dayIndex(now)
	return math.floor((tonumber(now) or os.time()) / 86400)
end

-- The sets the shops carry, in the owner's order.
function M.shopSets()
	local out = {}
	for _, s in ipairs(M.SETS) do
		if M.inShops(s.key) then
			table.insert(out, s)
		end
	end
	return out
end

-- Today's featured set packs. The same on every server and every client.
function M.featuredSetPacks(day)
	day = tonumber(day) or M.dayIndex()
	local rng = Random.new(day * 7919 + 17)
	local keys = {}
	for _, s in ipairs(M.shopSets()) do
		table.insert(keys, s.key)
	end
	local out = {}
	for _, level in ipairs(M.FEATURED_LEVELS) do
		if #keys == 0 then
			break
		end
		local key = table.remove(keys, rng:NextInteger(1, #keys))
		local id = SetPacks.packId(key, level)
		-- Only a pack the game can open: set packs exist once the set pets do.
		if SetPacks.PACK_BY_ID and SetPacks.PACK_BY_ID[id] then
			table.insert(out, id)
		end
	end
	return out
end

-- What the credit shop sells: the wild cases, then today's featured set packs.
function M.creditShelf(day)
	local out = {}
	for _, def in ipairs(M.WILD) do
		table.insert(out, def.id)
	end
	for _, id in ipairs(M.featuredSetPacks(day)) do
		table.insert(out, id)
	end
	return out
end

-- The credit price of anything on today's credit shelf, else nil. The server
-- prices a cart line with this, so an item off the shelf cannot be bought.
-- (A credit-bought wild case can roll the SSS set, but SSS cards recycle by
-- rarity like any other, so it does not move the price.)
function M.creditPrice(id, day)
	id = tostring(id or "")
	local listed = false
	for _, row in ipairs(M.creditShelf(day)) do
		if row == id then
			listed = true
			break
		end
	end
	if not listed then
		return nil
	end
	local def = M.get(id)
	if def and def.caseType == "wild" then
		--[[
			A wild case never costs the same as the grade below it: the owner
			set ★½ apart from ★ by hand, and the grade odds (2026-10-10) then
			rounded ★★ onto ★½'s 15. Walk the ladder and bump a tie by 5.
		]]
		local prev = 0
		for _, g in ipairs(M.WILD_GRADES) do
			local gid = M.wildGradeId(g)
			local p = math.max(M.CREDIT_SET[gid] or creditsFor(gid), prev + 5)
			if gid == id then
				return p
			end
			prev = p
		end
	end
	return M.CREDIT_SET[id] or creditsFor(id)
end

-- Credit prices the owner set by hand, over the curve. ★½ rounded to the same
-- 10 credits as ★; owner, 2026-10-10: "make ★½ 15 credits".
M.CREDIT_SET = { case_2 = 15 }

-- What the stardust shop's cases tab sells: the wild cases, then the three
-- cases of every set the shops carry, in the owner's order.
function M.dustShelf()
	local out = {}
	for _, def in ipairs(M.CASES) do
		if def.caseType == "wild" or def.forSale then
			table.insert(out, def.id)
		end
	end
	return out
end

return M
