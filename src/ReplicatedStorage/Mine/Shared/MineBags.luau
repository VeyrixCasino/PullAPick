-- MineBags: haul capacity from dirt HP × comfort × island mult.
-- Target 100+ bags: shop-aligned + fossil bags + limited.
-- See handoff/launch/TOOL_AND_BAG_COUNTS.md

local MineBags = {}

--[[
	BAGS ARE BOUGHT WITH GEMS. See MineBags.gemPrice further down, which is
	what the buy verb actually charges.

	This line used to read "Coin prices only. Never gems -- zone buyCost is the
	gem sink", which the gemPrice block below has contradicted ever since bags
	moved onto gems. A file that states the opposite of its own code in its
	header is how MineShopView came to price this shelf in coins while the
	server deducted gems -- wrong currency and wrong number, in the one place a
	reader would go to check.

	The `price` field on each row stays, and stays a COIN figure: sell value,
	shop ordering and the dex all read it. It is simply not what anyone pays.
]]
local Eco = require(script.Parent:WaitForChild("MineShopEconomy"))
local BagNames = require(script.Parent:WaitForChild("MineBagNames"))
local PRICE_FRAC = Eco.BAG_PRICE_FRAC or 0.35
local ENDSOIL_HP = 18000000

local ZONE_ORDER = {
	{ id = "meadow", short = "Meadow", zi = 1 },
	{ id = "sunscar", short = "Greyvein", zi = 2 },
	{ id = "mistreef", short = "Mistreef", zi = 3 },
	{ id = "arcwork", short = "Arcwork", zi = 4 },
	{ id = "bloodmoon", short = "Bloodmoon", zi = 5 },
	{ id = "eclipse", short = "Eclipse", zi = 6 },
	{ id = "riftmarch", short = "Riftmarch", zi = 7 },
	{ id = "starfall", short = "Starfall", zi = 8 },
	{ id = "mythral", short = "Mythral", zi = 9 },
	{ id = "primordium", short = "Primordium", zi = 10 },
}

local SURFACE_HP = { 10, 45, 180, 700, 2800, 5500, 12000, 28000 }
--[[
	Meadow early satchels. Slots are ~8x the old 60-slot starter so a loam haul
	is about a minute, not six blocks. Prices stay put.

	THE FREE ONE IS 200, SET DELIBERATELY. Owner, 2026-10-08: "set starter bag
	to 200 blocks". That is the first bag every new profile gets -- cap() reads
	C.BACKPACKS[1] when a player has no backpackTier -- so it is the number that
	decides how long the very first trip lasts.

	It is a cut from 480, against the reasoning in the line above: 200 loam is
	well under the "about a minute" that 480 was chosen for, and the first sell
	trip now comes roughly two and a half times sooner. That is the intent --
	the first walk back to the surface is what teaches the loop -- but it is a
	deliberate move away from the stated target, not a drift, so it is written
	down here rather than left looking like the old number.

	The paid rungs are untouched, so the first purchase is now a 6x jump
	instead of 2.5x and reads as a real upgrade.
]]
local MEADOW_SATCHELS = {
	{ slots = 200, price = 0 },
	{ slots = 1200, price = 100 },
	{ slots = 2000, price = 350 },
	{ slots = 4000, price = 800 },
	{ slots = 7200, price = 1400 },
	{ slots = 12000, price = 2200 },
}
local SURFACE_BAG_SLOTS = { 480, 1200, 2000, 4000, 7200, 12000, 25600, 56000 }
local DESK_HP = {
	shallow = { 5500, 12000 },
	mid = { 70000, 320000 },
	deep = { 3500000, 18000000 },
}
local FOSSIL_HP = { 90, 1400, 12000, 70000, 700000, 8000000 }

local function zoneMult(zi)
	return 6 ^ (math.max(1, zi) - 1)
end

local LIST = {}
local nextId = 0
local takenSlots = {}

-- Pre-462 ladder. Used to keep haul capacity when the catalog densifies.
MineBags.LEGACY_SLOTS = { 480, 1200, 2000, 2160, 4000, 7200, 12000, 22400, 24000, 33600, 36000, 43200, 72000, 112000, 134400, 144000, 216000, 224000, 259200, 288000, 432000, 672000, 720000, 806400, 864000, 1296000, 1344000, 1440000, 1555200, 1680000, 1728000, 2592000, 4032000, 4320000, 4838400, 5184000, 7776000, 8064000, 8640000, 9331200, 10080000, 15552000, 24192000, 25920000, 29030400, 31104000, 46656000, 48384000, 51840000, 55987200, 60480000, 93312000, 100800000, 145152000, 155520000, 174182400, 186624000, 279936000, 290304000, 311040000, 335923200, 559872000, 604800000, 870912000, 933120000, 1045094400, 1119744000, 1679616000, 1741824000, 1866240000, 2015539200, 3359232000, 3628800000, 5225472000, 5598720000, 6270566400, 6718464000, 6912000000, 10077696000, 10450944000, 11197440000, 12093235200, 20155392000, 31352832000, 33592320000, 37623398400, 40310784000, 41472000000, 60466176000, 62705664000, 67184640000, 72559411200, 120932352000, 188116992000, 201553920000, 225740390400, 248832000000, 362797056000, 376233984000, 403107840000, 1128701952000, 1209323520000, 1492992000000, 2257403904000, 2418647040000, 7255941120000, 8957952000000, 14511882240000, 53747712000000, 322486272000000, 361184624640000, 1289945088000000 }

local function geo(a, b, t)
	a, b = math.max(1, a), math.max(1, b)
	return a * ((b / a) ^ math.clamp(t, 0, 1))
end

local function uniqSlots(s)
	s = math.max(1, math.floor(s + 0.5))
	while takenSlots[s] do
		s += 1
	end
	takenSlots[s] = true
	return s
end

local function push(name, slots, minZone, band, blurb, extra)
	nextId += 1
	local free = extra and (extra.robux or extra.limited)
	local price = free and 0 or Eco.bagPrice(slots, minZone or 1, band or "shallow")
	local authored = extra and BagNames.get(extra.zoneId, extra.nameKind, extra.nameIndex)
	if authored then
		name = authored
	end
	if extra then
		extra.nameKey = nil
		extra.nameKind = nil
		extra.nameIndex = nil
		if authored then
			extra.needsName = nil
		end
	end
	local r = {
		id = nextId,
		name = name,
		slots = uniqSlots(slots),
		price = math.max(0, math.floor(price + 0.5)),
		minZone = minZone or 1,
		band = band,
		blurb = blurb,
	}
	if extra then
		for k, v in pairs(extra) do r[k] = v end
	end
	table.insert(LIST, r)
end

-- 16 surface satchels / zone. Meadow 1-6 keep authored prices.
local SURFACE_N = 16
for _, z in ipairs(ZONE_ORDER) do
	local lo = (z.zi == 1) and 480 or (2000 * zoneMult(z.zi))
	local hi = 56000 * zoneMult(z.zi)
	for i = 1, SURFACE_N do
		if z.zi == 1 and MEADOW_SATCHELS[i] then
			local row = MEADOW_SATCHELS[i]
			local nm = BagNames.get(z.id, "satchel", i) or string.format("Meadow Satchel %d", i)
			nextId += 1
			table.insert(LIST, {
				id = nextId,
				name = nm,
				slots = uniqSlots(row.slots),
				price = row.price,
				minZone = 1,
				band = "shallow",
				blurb = i == 1 and "Starter haul" or (i == 3 and "First real upgrade" or "Surface shop bag"),
				needsName = BagNames.get(z.id, "satchel", i) == nil,
				authoredPrice = true,
				skin = "satchel",
				zoneId = z.id,
			})
		else
			local t = (i - 1) / math.max(1, SURFACE_N - 1)
			push(
				string.format("%s Satchel %d", z.short, i),
				geo(lo, hi, t), z.zi, "shallow",
				"Surface shop bag",
				{ needsName = true, skin = "satchel", zoneId = z.id, nameKey = true, nameKind = "satchel", nameIndex = i }
			)
		end
	end
end

-- 8 packs per desk × 3 desks × 10 zones.
local DESK_N = 8
local MEADOW_DESK_SPAN = {
	shallow = { 22400, 72000 },
	mid = { 112000, 480000 },
	deep = { 720000, 3200000 },
}
for _, z in ipairs(ZONE_ORDER) do
	local mult = zoneMult(z.zi)
	for _, band in ipairs({ "shallow", "mid", "deep" }) do
		local span = MEADOW_DESK_SPAN[band]
		for i = 1, DESK_N do
			local t = (i - 1) / math.max(1, DESK_N - 1)
			local skin = (band == "deep" and i >= 5) and "workhorse" or "pack"
			push(
				string.format("%s %s Pack %d", z.short, band, i),
				geo(span[1], span[2], t) * mult, z.zi, band,
				"Depth desk bag",
				{ needsName = true, skin = skin, zoneId = z.id, nameKey = true, nameKind = band, nameIndex = i }
			)
		end
	end
end

--[[
	6 FOSSIL-TRACK BAGS / ZONE -- UNOBTAINABLE, AND THEY STAY.

	These were crafted on the fossil bench. Fossils are retired (§0.12) and the
	bench is gone, so nothing can grant one any more.

	They are NOT deleted, and must not be. A bag's id is "bag_<index into LIST>"
	(see shopRows and byId), so dropping 60 rows would renumber every bag above
	them and silently hand every player a different backpack than the one they
	bought. They stay as index padding: `fossil = true` keeps them off the coin
	shelf (sellable), out of shopRows, and out of the owned/total count the shop
	header prints, so no player ever sees one. The buy verb refuses them too.
]]
local FOSSIL_N = 6
local FOSSIL_SPAN = { 90, 8000000 }
for _, z in ipairs(ZONE_ORDER) do
	local mult = zoneMult(math.max(1, z.zi - 1))
	for i = 1, FOSSIL_N do
		local t = (i - 1) / math.max(1, FOSSIL_N - 1)
		local hp = geo(FOSSIL_SPAN[1], FOSSIL_SPAN[2], t)
		local band = (i <= 2 and "shallow") or (i <= 4 and "mid") or "deep"
		push(
			string.format("%s Fossil Bag %d", z.short, i),
			hp * 24 * mult, z.zi, band,
			"Fossil track bag",
			{
				fossil = true,
				needsName = true,
				skin = "fossil",
				zoneId = z.id,
				price = Eco.bagPrice(hp * 3 * mult, z.zi, band),
				nameKey = true,
				nameKind = "fossil",
				nameIndex = i,
			}
		)
	end
end

table.sort(LIST, function(a, b)
	if a.slots == b.slots then
		local af = a.fossil and 1 or 0
		local bf = b.fossil and 1 or 0
		if af ~= bf then
			return af < bf
		end
		return (a.minZone or 1) < (b.minZone or 1)
	end
	return a.slots < b.slots
end)

-- ---------------------------------------------------------------------------
-- MINIMUM RUNG: 100 SLOTS.
--
-- Three rails feeding one ladder produced rungs a single slot apart: Bone
-- Pouch at 2160 then Quartz Bone at 2161 -- nineteen coins for ONE slot, and
-- fifteen pairs like it. With AFK filling the bag while you are away, a rung
-- that buys one slot is not an upgrade, it is a rounding error with a price
-- tag on it.
--
-- Runs after the sort and before ids and prices are assigned, so ids stay in
-- capacity order and the coin curve is computed from the corrected figures.
-- Infinite bags are not a capacity rung and are skipped.
--
-- This is a normalisation pass, not authored data: new bags dropped into the
-- list are spaced by it automatically.
-- ---------------------------------------------------------------------------
MineBags.MIN_TIER_STEP = 100
do
	local prev
	for _, r in ipairs(LIST) do
		if not r.infinite then
			local s = math.max(1, math.floor(tonumber(r.slots) or 1))
			if prev and s < prev + MineBags.MIN_TIER_STEP then
				s = prev + MineBags.MIN_TIER_STEP
			end
			r.slots = s
			prev = s
		end
	end
end
for i, r in ipairs(LIST) do
	r.id = i
end
nextId = #LIST

-- ---------------------------------------------------------------------------
-- Coin shelf: one price curve for the whole ladder.
--
-- Three rails built this list and none of them agreed. Satchels priced through
-- Eco.bagPrice pay slots x bagHaulsToOwn(zone), so a zone-10 satchel ran 400
-- coins per slot, while desk packs scale price and slots by the same island
-- mult and sat flat at 0.25-3.3. Sorted together by capacity that produced 29
-- price inversions in 92 steps and a 4800x spread in coins per slot:
-- Primordium Satchel 2 cost 800x MORE than the bigger bag one rung above it.
--
-- price = COIN_A * slots^COIN_B is monotonic in slots by construction, so a
-- bigger bag always costs more. It is pinned to the authored Meadow rail at the
-- bottom (12k slots = 2200 coins) and to roughly twice the old top rung at the
-- ceiling, which tracks the shallow/mid packs players actually bought.
-- Meadow satchels keep their authored prices (authoredPrice).
-- ---------------------------------------------------------------------------
MineBags.COIN_A = 0.036576
MineBags.COIN_B = 1.17186

-- ---------------------------------------------------------------------------
-- BAGS ARE BOUGHT WITH GEMS.
--
-- Coins are payment for work -- one per point of block HP -- so pricing the
-- bag in coins meant the thing that lets you carry more coins was itself
-- priced in coins, and the curve fought the sink it was meant to be.
--
-- 100 * 1.08^x, flat compound per rung. The coin figures stay on the rows
-- (sell value, shop sorting, the dex all read them); this is what the buy
-- verb actually charges.
--
-- The Founders Rig is Robux and returns before any of this, so it is
-- untouched, exactly as intended.
-- ---------------------------------------------------------------------------
MineBags.GEM_BASE = 100
MineBags.GEM_RATE = 1.08

function MineBags.gemPrice(tier)
	local x = math.max(0, math.floor(tonumber(tier) or 1) - 1)
	return math.floor(MineBags.GEM_BASE * (MineBags.GEM_RATE ^ x) + 0.5)
end

function MineBags.coinPrice(slots)
	slots = math.max(1, math.floor(tonumber(slots) or 1))
	return math.floor(MineBags.COIN_A * (slots ^ MineBags.COIN_B) + 0.5)
end

-- The retired fossil-track bags are unobtainable and stay in LIST only so the
-- "bag_<index>" ids above them do not shift (see the block that builds them).
-- The coin shelf and the buy verb both skip them.
function MineBags.sellable(row)
	if type(row) ~= "table" then return false end
	return not (row.fossil or row.robux or row.limited)
end

do
	local floorPrice = 0
	for _, r in ipairs(LIST) do
		if not (r.robux or r.limited) then
			if not r.authoredPrice then
				r.price = MineBags.coinPrice(r.slots)
			end
			if (r.price or 0) > 0 then
				if r.price <= floorPrice then
					-- Two rungs rounded onto the same figure: always step up.
					r.price = math.floor(floorPrice * 1.05 + 1)
				end
				floorPrice = r.price
			end
		end
	end
end

local topCoin = LIST[#LIST]
nextId += 1
table.insert(LIST, {
	id = nextId,
	name = "Wormhole Bag",
	slots = math.floor(topCoin.slots * 4 + 0.5),
	price = 0,
	minZone = 1,
	band = "deep",
	blurb = "Event Horizon haul. Cashes itself when full.",
	limited = "bigbang",
	--[[
		NOT infinite -- that is the Founders Rig, and it is why this is the
		SECOND best bag rather than the best.

		It also could not work otherwise: cap() rewrites an infinite bag to
		1e15 slots, so an infinite bag is never full, and this bag's whole
		ability is that it cashes itself WHEN FULL. Left infinite, the
		ability could never once fire.

		The ceiling is still not one a player reaches, and saying otherwise
		here was wrong. Block HP is a flat 20 in every zone at every depth, so
		load accrues at roughly 600 a second, and these slots are 4x the top
		coin bag. The ability is wired and correct; the number in front of it
		is the open question.
	]]
	autoSellSec = 180,
	ability = "Cashes itself every 3 min once it is full.",
	skin = "wormhole",
	zoneId = "bigbang",
})

--[[
	THE TRICK-OR-TREAT BUCKET -- the Candy Crypt's chase.

	Owner, 2026-10-10: candy buys cases, and one of them pays an "extremely rare
	halloween bucket". This is it, and it is the only thing in the Crypt that is
	not consumable, which is what makes the case worth opening twice.

	Smaller than the Wormhole Bag on purpose. That one is the SECOND best bag in
	the game and is earned by claiming an endgame event; this is won from a case
	bought with candy in a three-week holiday mine, and it should not quietly
	become the best bag anyone ever needs.

	1.5x the top coin bag (owner, 2026-10-10 — it was 2x, which put it close
	enough to the Wormhole's 4x to read as second best). It is now clearly a
	step above the best bag you can buy and clearly below the one you earn.

	`limited = "hallow"` is read against the ZONE's ownedFlag now, not against
	bigbangOwned -- see the bag gate in MineServer.

	PROPOSED (2026-10-10): the slot count and the ability.
]]
nextId += 1
table.insert(LIST, {
	id = nextId,
	name = "Trick-or-Treat Bucket",
	slots = math.floor(topCoin.slots * 1.5 + 0.5),
	price = 0,
	minZone = 1,
	band = "deep",
	blurb = "Won from a Trick-or-Treat case. Heavier than it looks.",
	limited = "hallow",
	ability = "Candy blocks pay double while it is carried.",
	-- The ability as a NUMBER the payout reads, not just the sentence above it.
	-- A bag whose ability exists only in its blurb is a bag with no ability.
	candyMult = 2,
	skin = "candy",
	zoneId = "hallow",
})

nextId += 1
table.insert(LIST, {
	id = nextId,
	name = "Founders Rig",
	slots = math.floor(topCoin.slots * 4.5 + 0.5),
	price = 0,
	minZone = 1,
	band = "deep",
	blurb = "Founders infinite haul",
	robux = true,
	robuxPrice = 799,
	productId = 0,
	productKey = "patron_rig",
	infinite = true,
	shopTier = 100,
	skin = "founders",
	zoneId = "meadow",
	-- The only bag that genuinely never fills, so it is the top of the ladder.
	best = true,
})

MineBags.LIST = LIST
MineBags.PRICE_FRAC = PRICE_FRAC

function MineBags.byTier(tier)
	return LIST[math.clamp(math.floor(tonumber(tier) or 1), 1, #LIST)]
end

function MineBags.byId(id)
	id = tostring(id or "")
	for _, r in ipairs(LIST) do
		if tostring(r.id) == id or r.name == id then return r end
	end
	return nil
end

function MineBags.shopRows(zoneIndex, band)
	zoneIndex = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	band = tostring(band or "")
	if band == "surface" then band = "shallow" end
	if band == "deeprock" then band = "mid" end
	if band == "shadowzone" then band = "deep" end
	local out = {}
	for i, r in ipairs(LIST) do
		if not (r.robux or r.limited or r.fossil) then
			local mz = math.floor(tonumber(r.minZone) or 1)
			local bandOk = true
			if band == "mid" or band == "deep" or band == "shallow" then
				bandOk = (r.band == band)
			end
			if mz <= zoneIndex and bandOk then
				table.insert(out, {
					id = "bag_" .. i,
					family = "backpack",
					tier = i,
					name = r.name,
					role = "Bag",
					slots = r.slots,
					power = r.slots,
					price = r.price,
					minZone = mz,
					band = r.band,
					blurb = r.blurb,
					skin = r.skin,
					zoneId = r.zoneId,
				})
			end
		end
	end
	if band == "shallow" or band == "" then
		for i, r in ipairs(LIST) do
			if r.robux and r.infinite then
				table.insert(out, {
					id = "bag_" .. i,
					family = "backpack",
					tier = i,
					shopTier = r.shopTier or 100,
					infinite = true,
					name = "Founders Rig",
					role = "Bag",
					slots = r.slots,
					power = r.slots,
					price = r.price,
					minZone = 1,
					band = r.band,
					blurb = r.blurb,
					robux = r.robux,
					robuxPrice = r.robuxPrice,
					productId = r.productId,
					productKey = r.productKey,
				})
			end
		end
	end
	return out
end

function MineBags.counts()
	local fossil, shop, limited = 0, 0, 0
	for _, r in ipairs(LIST) do
		if r.fossil then fossil += 1
		elseif r.robux or r.limited then limited += 1
		else shop += 1 end
	end
	return { total = #LIST, shop = shop, fossil = fossil, limited = limited }
end

--------------------------------------------------------------------------------
-- RARITY
--
-- Bags had no grade at all, so a starter satchel and a 322-trillion-slot deep
-- pack were presented identically: same card, same colour, nothing to want.
--
-- Graded by RANK in the slot ladder, not by raw slots. Capacity spans nearly
-- twelve orders of magnitude, so any threshold on the number itself puts ~100
-- bags in one bucket and two in another. Rank spreads them the way a player
-- actually meets them.
--
-- Stamped onto the rows at load so every reader -- inventory, the reveal, the
-- shop, trade -- sees `rarity` on a bag exactly like it does on a tool, with no
-- second code path.
--------------------------------------------------------------------------------
MineBags.RARITY_ORDER = {
	"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic",
}
-- Share of the ladder each grade owns, shallow-heavy on purpose: most bags a
-- player ever holds should be ordinary, and Exotic has to stay a word that means
-- something.
MineBags.RARITY_SHARE = { 0.25, 0.20, 0.18, 0.15, 0.10, 0.07, 0.04, 0.01 }

function MineBags.rarityOf(row)
	return row and (row.rarity or row.rarityId) or nil
end

do
	-- Rank the finite bags by capacity.
	local ranked = {}
	for _, b in ipairs(MineBags.LIST) do
		if not b.infinite then
			ranked[#ranked + 1] = b
		end
	end
	table.sort(ranked, function(x, y)
		local sx, sy = tonumber(x.slots) or 0, tonumber(y.slots) or 0
		if sx ~= sy then
			return sx < sy
		end
		return (tonumber(x.id) or 0) < (tonumber(y.id) or 0)
	end)
	local n = #ranked
	local cut, acc = {}, 0
	for i, share in ipairs(MineBags.RARITY_SHARE) do
		acc += share
		cut[i] = math.floor(n * acc + 0.5)
	end
	local at = 1
	for i, b in ipairs(ranked) do
		while at < #MineBags.RARITY_ORDER and i > (cut[at] or n) do
			at += 1
		end
		b.rarity = MineBags.RARITY_ORDER[at]
		b.rarityId = b.rarity
	end
	-- The two infinite bags sit outside the ladder: they are not a capacity
	-- rung, they are the end of the road.
	for _, b in ipairs(MineBags.LIST) do
		if b.infinite then
			b.rarity = "Exotic"
			b.rarityId = "Exotic"
		end
	end
end


return MineBags
