--[[
	MineRotatingOffers — scheduled limited aisle.

	US Eastern (EDT, UTC-4). That is the timezone with the most Roblox players,
	and the battle pass already ends on an Eastern midnight.
	Season: 2026-09-22 00:00 ET through 2026-11-01 00:00 ET, so Oct 31 is a full day
	and the clock hits zero at midnight.

	Two or three offers are live at once. Windows are 1 week or 2 weeks, except
	Founders, which stays up the whole season. Lucky Block Week and Pot of Gold
	do not return.
]]

local MineRotatingOffers = {}

local LuckyBlocks = require(script.Parent:WaitForChild("MineLuckyBlocks"))
local ZonePacks = require(script.Parent:WaitForChild("MineZonePacks"))
--[[
	The season clock, not the wall clock. Before the owner launches,
	seasonNow() is pinned to SEASON_START, so slot one is live and nothing has
	expired however long the game sits unlaunched. Defaulted HERE rather than at
	the call sites so every caller -- client panels included -- gets it without
	having to know the rule.
]]
local Launch = require(script.Parent:WaitForChild("MineLaunch"))

local START = 1790049600
local WEEK = 604800
local ENDS = 1793505600

MineRotatingOffers.SEASON_START = START
MineRotatingOffers.SEASON_END = ENDS
MineRotatingOffers.SLOT_COUNT = 3

MineRotatingOffers.OFFERS = {
	{
		id = "deal_lucky_week", key = "deal_lucky_week", kind = "deal",
		title = "Lucky Block Week", icon = "lucky_block",
		credits = 599, max = 3, neverReturns = true,
		starts = START, ends = START + WEEK,
		blocks = {
			{ id = "lucky_block", qty = 5 },
			{ id = "super_lucky_block", qty = 3 },
			{ id = "godly_lucky_block", qty = 1 },
		},
		--[[
			WILD CASES WHERE THE RETIRED PACKS WERE (owner, 2026-10-19: "wild
			cases of about the same value"). The deal paid 4 Heirloom, 2 Omen and
			2 Shiny packs, which left the shelves on 2026-10-10. Valued the way
			the cases are priced (MineCases.expectedDust, MinePackConfig
			.expectedDust: what the cards recycle for), read 2026-10-19:

			  old  4 x Heirloom 6,888 + 2 x Omen 3,204 + 2 x Shiny 24,056
			       = 82,072 stardust, 502 credits at the old list prices
			  new  3 x 5-star 15,958 + 2 x 4.5-star 10,425 + 3 x 4-star 4,893
			       = 83,403 stardust, 505 credits at today's case prices

			Eight cases for eight packs, within 2% on both counts. The deal is
			bought with credits, so they are paid cases (MineCases.bagRow).
			PROPOSED (2026-10-19): the mix.
		]]
		packs = {
			{ id = "case_6", qty = 3 },
			{ id = "case_5_6", qty = 2 },
			{ id = "case_5", qty = 3 },
		},
		--[[
			A REAL PET, ONE PER PURCHASE (owner, 2026-10-19: "a real existing
			lucky-block pet (an Epic-ish one that fits)"). It used to write
			ownedPets.lucky_block, which nothing in the game reads, so buyers
			got no pet at all. Lucky Dice is an Epic of the Lost & Found set:
			lucky blocks pay mystery cases, whose packs drop it. The server mints
			it as a card the way lucky blocks minted pets (MineServer
			Dig.mintDealPet). PROPOSED (2026-10-19): which pet.
		]]
		pet = "Lucky Dice",
		blurb = "LIMITED TIME. NEVER COMING BACK. 5 Lucky Blocks, 3 Diamond, 1 Godly, the Lucky Dice pet (Epic), plus 8 Wild Cases: 3 ★★★★★, 2 ★★★★½, 3 ★★★★. 599 credits. Max 3.",
		toast = "Lucky Block Week claimed — Lucky Dice joined your pets; the blocks and cases are in your bag",
	},
	{
		id = "deal_pot_gold", key = "deal_pot_gold", kind = "deal",
		title = "Pot of Gold", icon = "luck",
		credits = 599, max = 1, neverReturns = true,
		starts = START, ends = START + 2 * WEEK,
		charm = "lucky_charm", shinyPacks = 8,
		--[[
			WILD CASES WHERE THE RETIRED PACKS WERE (owner, 2026-10-19: "Use all
			defaults": wild cases of about the same value). The deal paid 3
			Heirloom and 2 Omen packs, off the shelves since 2026-10-10. Valued the
			way Lucky Block Week's were (MinePackConfig.expectedDust,
			MineCases.expectedDust: what the cards recycle for), read 2026-10-19:

			  old  3 x Heirloom 6,888 + 2 x Omen 3,204
			       = 27,071 stardust, 257 credits at the old list prices
			  new  1 x 4.5-star 10,425 + 3 x 4-star 4,893 + 1 x 3-star 1,364
			       + 1 x 2.5-star 906
			       = 27,374 stardust (+1.1%), 255 credits at today's case prices

			The ★★★ case it already paid (in place of the Apex Pack retired
			2026-10-11) stays, so it is 2 ★★★ in the list. The 8 Shiny Packs are
			not retired packs: they are Meadow Legendary packs, all-shiny at luck
			x3 (shinyPacks below), and stay. Bought with credits, so the cases are
			paid cases (MineCases.bagRow). PROPOSED (2026-10-19): the mix.
		]]
		packs = {
			{ id = "case_5_6", qty = 1 },
			{ id = "case_5", qty = 3 },
			{ id = "case_4", qty = 2 },
			{ id = "case_3_4", qty = 1 },
		},
		potions = { { id = "pot_t3_fortune", qty = 2 } },
		blurb = "LIMITED TIME. NEVER COMING BACK. 200% Luck charm, 8 Shiny Packs, 7 Wild Cases (1 ★★★★½, 3 ★★★★, 2 ★★★, 1 ★★½), and 2 Fortune Flasks. 599 credits. Max 1.",
		toast = "Pot of Gold claimed — equip the charm, then open the packs",
	},
	{
		id = "rot_founders", key = "patron_rig", kind = "founders",
		title = "Founders Bag", icon = "logo",
		credits = 799,
		starts = START, ends = ENDS,
		-- No calendar date (2026-10-19): the season runs 47 days from launch,
		-- whenever that is (MineLaunch), so "through Oct 31" was wrong either way.
		blurb = "The long one. Founders Bag stays on the shelf all season. 799 credits.",
	},
	{
		id = "feat_lucky10", key = "feat_lucky10", kind = "deal",
		title = "Lucky Stack", icon = "lucky_block",
		credits = 350,
		starts = START + WEEK, ends = START + 3 * WEEK,
		blocks = { { id = "lucky_block", qty = 10 } },
		blurb = "10 Lucky Blocks for 2 weeks. 350 credits.",
		toast = "Lucky Stack claimed",
	},
	{
		id = "feat_diamond", key = "feat_diamond", kind = "deal",
		title = "Diamond Stack", icon = "super_lucky_block",
		credits = 360,
		starts = START + 2 * WEEK, ends = START + 4 * WEEK,
		blocks = { { id = "super_lucky_block", qty = 3 } },
		blurb = "3 Diamond Blocks for 2 weeks. 360 credits.",
		toast = "Diamond Stack claimed",
	},
	{
		id = "feat_mythic", key = "feat_mythic", kind = "deal",
		title = "Godly Cube", icon = "godly_lucky_block",
		credits = 280,
		starts = START + 3 * WEEK, ends = START + 5 * WEEK,
		blocks = { { id = "godly_lucky_block", qty = 1 } },
		blurb = "1 Godly Block for 2 weeks. 280 credits.",
		toast = "Godly Cube claimed",
	},
	{
		id = "feat_lucky_late", key = "feat_lucky_late", kind = "deal",
		title = "Lucky Stack", icon = "lucky_block",
		credits = 350,
		starts = START + 4 * WEEK, ends = ENDS,
		blocks = { { id = "lucky_block", qty = 10 } },
		blurb = "10 Lucky Blocks until the season ends. 350 credits.",
		toast = "Lucky Stack claimed",
	},
}

--[[
	ONE MORE WEEK, ON EVERYTHING.

	Applied as a pass over the table rather than by editing seven `ends`
	fields, so the windows keep reading as START + n * WEEK -- which is how
	they were designed and how the next person will expect to read them -- and
	extending again is one number instead of seven edits.

	SEASON_END moves with them. Two offers end AT the season end, so leaving
	it put would have pushed them past the season they belong to.
]]
MineRotatingOffers.EXTEND_SEC = WEEK
do
	for _, o in ipairs(MineRotatingOffers.OFFERS) do
		if tonumber(o.ends) then
			o.ends = o.ends + MineRotatingOffers.EXTEND_SEC
		end
	end
	MineRotatingOffers.SEASON_END = ENDS + MineRotatingOffers.EXTEND_SEC
end

function MineRotatingOffers.isLive(offer, now)
	now = now or Launch.seasonNow()
	if type(offer) ~= "table" then
		return false
	end
	return now >= (offer.starts or 0) and now < (offer.ends or 0)
end

function MineRotatingOffers.byId(id)
	id = tostring(id or "")
	for _, row in ipairs(MineRotatingOffers.OFFERS) do
		if row.id == id or row.key == id then
			return row
		end
	end
	return nil
end

function MineRotatingOffers.bought(p, offer)
	local n = p and p.dealBuys and offer and p.dealBuys[offer.id]
	return math.max(0, math.floor(tonumber(n) or 0))
end

function MineRotatingOffers.deny(p, offer)
	if not offer then
		return "Unknown deal"
	end
	if offer.max and MineRotatingOffers.bought(p, offer) >= offer.max then
		return string.format("Max %d per player", offer.max)
	end
	return nil
end

--[[
	`hooks.mintPet(name)` mints a named pet as a card and returns true. Only the
	server can (it owns the serials), so an offer with a pet is REFUSED without
	the hook, before anything is counted or granted: a deal that took the money
	and skipped the pet is the bug this replaced. The pet goes first, so a mint
	that fails leaves nothing half-granted and the caller can refund.
]]
function MineRotatingOffers.grant(p, offer, hooks)
	if MineRotatingOffers.deny(p, offer) then
		return false
	end
	if offer.pet and not (type(hooks) == "table" and type(hooks.mintPet) == "function") then
		return false
	end
	p.dealBuys = p.dealBuys or {}
	local before = MineRotatingOffers.bought(p, offer)
	-- Counted before the mint, which can wait on a datastore: a second buy in
	-- that gap must already see this one.
	p.dealBuys[offer.id] = before + 1
	if offer.pet then
		local okPet, minted = pcall(hooks.mintPet, offer.pet)
		if not okPet or minted ~= true then
			p.dealBuys[offer.id] = before
			return false
		end
	end
	p.packs = p.packs or {}
	for _, block in ipairs(offer.blocks or {}) do
		LuckyBlocks.grant(p, block.id, "F", block.qty or 1)
	end
	if offer.charm then
		p.charms = p.charms or {}
		p.charms[offer.charm] = true
	end
	local nShiny = math.floor(tonumber(offer.shinyPacks) or 0)
	if nShiny > 0 then
		local packId = ZonePacks.id("meadow", "pack_legendary")
		for _ = 1, nShiny do
			table.insert(p.packs, {
				packId = packId,
				packName = "Shiny Pack",
				zoneId = "meadow",
				setId = "dragons_dawn",
				luck = 3,
				shiny = 100,
			})
		end
	end
	do
		local Packs = require(script.Parent:WaitForChild("MinePackConfig"))
		local Cases = require(script.Parent:WaitForChild("MineCases"))
		for _, row in ipairs(offer.packs or {}) do
			local id = tostring(row.id or "")
			local def = Packs.PACK_BY_ID and Packs.PACK_BY_ID[id]
			for _ = 1, math.max(1, math.floor(tonumber(row.qty) or 1)) do
				-- A pack case is its own bag row; a deal is bought with credits,
				-- so it is a paid case (MineCases.bagRow).
				table.insert(p.packs, Cases.bagRow(id, true) or {
					packId = id,
					packName = (def and def.name) or id,
					setId = "dragons_dawn",
				})
			end
		end
	end
	for _, row in ipairs(offer.potions or {}) do
		pcall(function()
			require(script.Parent:WaitForChild("MinePotions")).grant(p, row.id, row.qty or 1)
		end)
	end
	return true
end

function MineRotatingOffers.dayKey(now)
	now = now or Launch.seasonNow()
	-- SEASON_END, not the file-local ENDS: ENDS is the season before the extra
	-- week (40 days), so the header said "40d left" in a 47-day season.
	local left = math.max(0, MineRotatingOffers.SEASON_END - now)
	local days = math.floor(left / 86400)
	return string.format("%dd left in the season", days)
end

--[[
	COUNTDOWNS RUN ON THE SEASON CLOCK (launch audit M8, 2026-10-19).

	`starts` and `ends` are season-clock instants. The shop subtracted os.time()
	from them, and the season clock sits at SEASON_START until launch and runs
	behind the wall clock after it, so every limited deal read "ends 0d 0h"
	from the day it went up. Every countdown goes through these instead, which
	default `now` to the season clock like the rest of this module.
]]
function MineRotatingOffers.secondsLeft(offer, now)
	now = now or Launch.seasonNow()
	return math.max(0, math.floor((tonumber(offer and offer.ends) or 0) - now))
end

-- Seconds until the next offer goes up (offers change weekly), or nil once
-- nothing new is still to come this season.
function MineRotatingOffers.nextOfferIn(now)
	now = now or Launch.seasonNow()
	local soonest = nil
	for _, row in ipairs(MineRotatingOffers.OFFERS) do
		local s = tonumber(row.starts)
		if s and s > now and (soonest == nil or s < soonest) then
			soonest = s
		end
	end
	return soonest and math.floor(soonest - now) or nil
end

-- "6d 23h", or "5h 07m" inside the last day.
function MineRotatingOffers.clockText(secs)
	secs = math.max(0, math.floor(tonumber(secs) or 0))
	if secs >= 86400 then
		return string.format("%dd %dh", secs // 86400, (secs % 86400) // 3600)
	end
	return string.format("%dh %02dm", secs // 3600, (secs % 3600) // 60)
end

--[[
	DOES BUYING THIS ROLL ANYTHING?

	Roblox restricts paid random items in some regions (MineServer
	Verbs.PAID_RANDOM, the PolicyNoRandom attribute). A deal is a bundle of
	fixed things, but the lucky blocks and cases in it are random items bought
	with credits (and credits trace back to Robux), so a deal carrying any is a
	paid random buy. Read off what the grant pays out, never a flag typed
	beside it that could drift.
]]
function MineRotatingOffers.hasRandom(offer)
	if type(offer) ~= "table" then
		return false
	end
	return #(offer.blocks or {}) > 0 or #(offer.packs or {}) > 0 or (tonumber(offer.shinyPacks) or 0) > 0
end

--[[
	A DEAL'S ODDS, BEFORE YOU BUY (owner, 2026-10-19, "Use all defaults": limited
	deals with lucky blocks or cases get an odds sheet). Every chance is read off
	the table its roll uses, never typed:

	  lucky blocks  MineLuckyBlocks.oddsSheet: the final grade (rollClash) and
	                what that grade pays (rollLoot's kind tables), from grade F,
	                which is how a deal grants them
	  wild cases    MineCases.wildGradeOdds(true): the set a paid case's spin lands
	                on (rollWildSet); MineCases.levelOdds: its pack's stars
	  Shiny Packs   MinePackConfig.siphonOdds over the Meadow Legendary pack's own
	                odds at the deal's luck x3: each card's rarity (rollCard)

	Returns a spec for MineLuckyOddsView.sheet -- { title, sub, sections = {
	{ header, rows = { { name, p, grade? } } } }, note } -- or nil for a deal with
	nothing random in it. `grade` lets the screen tint a row.
]]
MineRotatingOffers.SHINY_PACK_LUCK = 3
function MineRotatingOffers.oddsSheet(offer)
	if not MineRotatingOffers.hasRandom(offer) then
		return nil
	end
	local GRADES = { "F", "D", "C", "B", "A", "S", "SS", "SSS" }
	local sections = {}
	for _, b in ipairs(offer.blocks or {}) do
		local sheet = LuckyBlocks.oddsSheet and LuckyBlocks.oddsSheet(b.id, "F")
		if sheet then
			local def = LuckyBlocks.TYPES and LuckyBlocks.TYPES[b.id]
			local head = string.upper(tostring((def and def.name) or b.id)) .. "  x" .. tostring(b.qty or 1)
			local grades = { header = head .. "  ·  FINAL GRADE", rows = {} }
			for _, g in ipairs(GRADES) do
				local p = (sheet.grades or {})[g] or 0
				if p > 0 then
					table.insert(grades.rows, { name = "Grade " .. g, p = p, grade = g })
				end
			end
			table.insert(sections, grades)
			local kinds = {}
			for k, p in pairs(sheet.kinds or {}) do
				table.insert(kinds, { k = k, p = p })
			end
			table.sort(kinds, function(x, y)
				if x.p ~= y.p then
					return x.p > y.p
				end
				return x.k < y.k
			end)
			local what = { header = head .. "  ·  WHAT EACH OPEN PAYS", rows = {} }
			for _, e in ipairs(kinds) do
				table.insert(what.rows, { name = (LuckyBlocks.KIND_NAMES and LuckyBlocks.KIND_NAMES[e.k]) or e.k, p = e.p })
			end
			table.insert(sections, what)
		end
	end
	local Cases, SetPacks
	local wild = {}
	for _, row in ipairs(offer.packs or {}) do
		Cases = Cases or require(script.Parent:WaitForChild("MineCases"))
		local def = Cases.get(row.id)
		if def and def.caseType == "wild" then
			table.insert(wild, { def = def, qty = row.qty or 1 })
		end
	end
	if #wild > 0 then
		SetPacks = require(script.Parent:WaitForChild("MineSetPacks"))
		local stars = { header = "WILD CASES  ·  THE PACK EACH SPIN PAYS 3 OF", rows = {} }
		for _, w in ipairs(wild) do
			for _, lv in ipairs(Cases.levelOdds(w.def)) do
				table.insert(stars.rows, {
					name = string.format("%s x%d: a %s pack", w.def.name, w.qty, tostring(SetPacks.STAR_TEXT[lv.level])),
					p = lv.p,
				})
			end
		end
		table.insert(sections, stars)
		-- Bought with credits, so these are paid cases: the SSS set's share too.
		local sets = { header = "WILD CASES  ·  THE SET EACH SPIN LANDS ON", rows = {} }
		for _, r in ipairs(Cases.wildGradeOdds(true)) do
			table.insert(sets.rows, {
				name = string.format("A grade %s set (%d %s)", r.grade, r.sets, (r.sets == 1) and "set" or "sets"),
				p = (tonumber(r.pct) or 0) / 100, grade = r.grade,
			})
		end
		table.insert(sections, sets)
	end
	local nShiny = math.floor(tonumber(offer.shinyPacks) or 0)
	if nShiny > 0 then
		local Packs = require(script.Parent:WaitForChild("MinePackConfig"))
		local zdef = ZonePacks.get and ZonePacks.get(ZonePacks.id("meadow", "pack_legendary"))
		local odds = zdef and zdef.odds and Packs.siphonOdds(zdef.odds, MineRotatingOffers.SHINY_PACK_LUCK)
		if odds then
			local total = 0
			for _, v in pairs(odds) do
				total += math.max(0, tonumber(v) or 0)
			end
			local cards = { header = string.format("SHINY PACK x%d  ·  EACH CARD'S RARITY (%d a pack, every one shiny)",
				nShiny, tonumber(zdef.cards) or 5), rows = {} }
			for i, r in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic" }) do
				local v = math.max(0, tonumber(odds[r]) or 0)
				if v > 0 and total > 0 then
					table.insert(cards.rows, { name = r, p = v / total, grade = GRADES[i] })
				end
			end
			table.insert(sections, cards)
		end
	end
	return {
		title = string.upper(tostring(offer.title or offer.id)) .. "  ODDS",
		sub = "Everything random in this deal, with the chance it rolls",
		sections = sections,
		note = "Bought with credits. Lucky blocks open from grade F. "
			.. "Wild cases go in your bag and spin when you open them. "
			.. "Everything else in the deal is fixed.",
	}
end

-- The same question for any key MineServer's buyProductCredits takes: a deal
-- here, else a MineConfig.PRODUCTS row (packs, lucky blocks, or the Starter
-- Crate's random Common pet -- its grant defaults commonPet to 1, so this does).
function MineRotatingOffers.isRandomBuy(key)
	key = tostring(key or "")
	local offer = MineRotatingOffers.byId(key)
	if offer then
		return MineRotatingOffers.hasRandom(offer)
	end
	local C = require(script.Parent:WaitForChild("MineConfig"))
	local prod = C.product and C.product(key)
	if type(prod) ~= "table" then
		return false
	end
	if #(prod.packs or {}) > 0 or #(prod.blocks or {}) > 0 then
		return true
	end
	return key == "starter_bundle" and (tonumber(prod.commonPet) or 1) > 0
end

function MineRotatingOffers.active(now)
	now = now or Launch.seasonNow()
	local out = {}
	for _, row in ipairs(MineRotatingOffers.OFFERS) do
		if MineRotatingOffers.isLive(row, now) then
			local copy = table.clone(row)
			copy.dayKey = MineRotatingOffers.dayKey(now)
			table.insert(out, copy)
		end
	end
	return out
end

function MineRotatingOffers.headline(now)
	local rows = MineRotatingOffers.active(now)
	local titles = {}
	for _, r in ipairs(rows) do
		table.insert(titles, r.title)
	end
	if #titles == 0 then
		return "Season shelf is quiet"
	end
	return table.concat(titles, " · ")
end

return MineRotatingOffers
