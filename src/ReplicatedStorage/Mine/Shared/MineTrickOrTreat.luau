--[[
	MineTrickOrTreat -- the Candy Crypt's case, bought with candy.

	Owner, 2026-10-19 ("Candy Crypt v2", wiki/open-questions.md): the case pays
	"pets and skins only (no candy, no tools; charms come from chests only)";
	"the win says its rarity, then a 50/50 wheel with the reward in its middle:
	TREAT you get it, TRICK you get nothing. Only this case gets the wheel."

	SO ONE OPEN IS THREE ROLLS, ALL ON THE SERVER, ALL BEFORE ANYTHING IS SHOWN:
	  1. the RARITY (RARITIES weights), 1 = Common / F .. 8 = Exotic / SSS
	  2. the KIND, a Halloween pet or a Halloween skin (KIND_WEIGHTS), and then
	     WHICH one of that rarity (MineCryptRules.casePrize picks it from the
	     Halloween pets and the Halloween skin set)
	  3. the WHEEL: TREAT_CHANCE says you get it, else TRICK and nothing
	MineCrypt sends the rarity, the reward and the outcome in one push
	(`trickOrTreatOpened`), so the client shows the rarity, then spins the
	wheel with the reward in its middle and lands where the server already did.

	`roll` is pure: a plain description, no side effects, no Instances, so it
	can be tested and replayed. `odds` is the sheet a paid random buy shows
	before it is bought (MineLuckyOddsView's rule).

	The owner's numbers are the 50/50 and the two prize kinds. The price, the
	rarity weights and the pet / skin split are PROPOSED (2026-10-19).
]]
local MineTrickOrTreat = {}

MineTrickOrTreat.CASE_ID = "trick_or_treat_case"
MineTrickOrTreat.NAME = "Trick-or-Treat Case"
MineTrickOrTreat.CURRENCY = "candy"

-- The Halloween set the case's pets come from: the Halloween 2026 Pack's
-- (its set key is the pack's id). The case no longer pays the pack itself.
MineTrickOrTreat.PACK_ID = "halloween_2026"

--[[
	THE ONE TABLE OF CASE NUMBERS (PROPOSED 2026-10-19, except the 50/50).

	  PRICE         candy. About twenty minutes of a mid-depth dig's block candy
	                (section 6, docs/CANDY-CRYPT.md), and more if you sell ores.
	  TREAT_CHANCE  owner: 50/50.
	  KIND_WEIGHTS  a Halloween pet or a Halloween skin. Pets lead: there are
	                72 of them to collect and skins repeat (a skin you own pays
	                stardust instead, as a chest skin does).
	  RARITIES      the rarity roll. `pet` and `skin` are the two ladders' names
	                for the same rung (pets Common .. Exotic, skins F .. SSS).
]]
MineTrickOrTreat.PRICE = 4000
MineTrickOrTreat.TREAT_CHANCE = 0.5
MineTrickOrTreat.KIND_WEIGHTS = { pet = 70, skin = 30 }
MineTrickOrTreat.KIND_ORDER = { "pet", "skin" }
MineTrickOrTreat.RARITIES = {
	{ pet = "Common", skin = "F", weight = 40 },
	{ pet = "Uncommon", skin = "D", weight = 25 },
	{ pet = "Rare", skin = "C", weight = 15 },
	{ pet = "Epic", skin = "B", weight = 10 },
	{ pet = "Legendary", skin = "A", weight = 6 },
	{ pet = "Mythic", skin = "S", weight = 2.5 },
	{ pet = "Divine", skin = "SS", weight = 1.2 },
	{ pet = "Exotic", skin = "SSS", weight = 0.3 },
}
for i, r in ipairs(MineTrickOrTreat.RARITIES) do
	r.index = i
end

MineTrickOrTreat.LABEL = {
	pet = "A Halloween pet",
	skin = "A Halloween skin",
	treat = "TREAT",
	trick = "TRICK",
}

local function sum(t)
	local s = 0
	for _, v in pairs(t) do
		s += tonumber(v) or 0
	end
	return s
end

-- A rarity rung by index (1..8), or nil.
function MineTrickOrTreat.rarity(index)
	return MineTrickOrTreat.RARITIES[math.floor(tonumber(index) or 0)]
end

--[[
	THE ODDS SHEET: every rarity with its chance, split by kind, plus the wheel.
	Every `pct` is out of 100 and is the chance of being SHOWN that prize; the
	chance of KEEPING it is that times `treat` (both are on the sheet, so the
	50/50 is never hidden).

	  { price, currency, treat = 0.5,
	    kinds = { { kind = "pet", pct }, { kind = "skin", pct } },
	    rows  = { { index, pet, skin, pct, petPct, skinPct, keepPct }, ... } }
]]
function MineTrickOrTreat.odds()
	local wTot = 0
	for _, r in ipairs(MineTrickOrTreat.RARITIES) do
		wTot += r.weight
	end
	local kTot = sum(MineTrickOrTreat.KIND_WEIGHTS)
	local kinds = {}
	for _, k in ipairs(MineTrickOrTreat.KIND_ORDER) do
		table.insert(kinds, {
			kind = k,
			label = MineTrickOrTreat.LABEL[k],
			pct = (kTot > 0) and (MineTrickOrTreat.KIND_WEIGHTS[k] / kTot * 100) or 0,
		})
	end
	local rows = {}
	for _, r in ipairs(MineTrickOrTreat.RARITIES) do
		local pct = (wTot > 0) and (r.weight / wTot * 100) or 0
		table.insert(rows, {
			index = r.index,
			pet = r.pet,
			skin = r.skin,
			pct = pct,
			petPct = pct * ((kTot > 0) and MineTrickOrTreat.KIND_WEIGHTS.pet / kTot or 0),
			skinPct = pct * ((kTot > 0) and MineTrickOrTreat.KIND_WEIGHTS.skin / kTot or 0),
			keepPct = pct * MineTrickOrTreat.TREAT_CHANCE,
		})
	end
	return {
		id = MineTrickOrTreat.CASE_ID,
		name = MineTrickOrTreat.NAME,
		price = MineTrickOrTreat.PRICE,
		currency = MineTrickOrTreat.CURRENCY,
		treat = MineTrickOrTreat.TREAT_CHANCE,
		kinds = kinds,
		rows = rows,
	}
end

local function num(rng)
	return (rng and rng.NextNumber) and rng:NextNumber() or math.random()
end

--[[
	One open, as a plain description:
	  { rarityIndex = 1..8, pet = "Common", skin = "F", kind = "pet" | "skin",
	    outcome = "treat" | "trick" }
	WHICH pet or skin is chosen by the caller from that rarity
	(MineCryptRules.casePrize), so this stays free of the pet roster.
]]
function MineTrickOrTreat.roll(rng)
	local wTot = 0
	for _, r in ipairs(MineTrickOrTreat.RARITIES) do
		wTot += r.weight
	end
	local pick = num(rng) * wTot
	local rung = MineTrickOrTreat.RARITIES[1]
	for _, r in ipairs(MineTrickOrTreat.RARITIES) do
		pick -= r.weight
		if pick <= 0 then
			rung = r
			break
		end
	end
	local kTot = sum(MineTrickOrTreat.KIND_WEIGHTS)
	local kpick = num(rng) * kTot
	local kind = MineTrickOrTreat.KIND_ORDER[1]
	for _, k in ipairs(MineTrickOrTreat.KIND_ORDER) do
		kpick -= MineTrickOrTreat.KIND_WEIGHTS[k] or 0
		if kpick <= 0 then
			kind = k
			break
		end
	end
	local outcome = (num(rng) < MineTrickOrTreat.TREAT_CHANCE) and "treat" or "trick"
	return {
		rarityIndex = rung.index,
		pet = rung.pet,
		skin = rung.skin,
		kind = kind,
		outcome = outcome,
	}
end

return MineTrickOrTreat
