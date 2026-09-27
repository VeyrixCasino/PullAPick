-- MineBags: haul capacity from dirt HP × comfort × island mult.
-- Target 100+ bags: shop-aligned + fossil bags + limited.
-- See handoff/launch/TOOL_AND_BAG_COUNTS.md

local MineBags = {}

-- Coin prices only. Never gems — zone buyCost is the gem sink.
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
-- Meadow early satchels. Slots are ~8× the old 60-slot starter so a loam
-- haul is about a minute, not six blocks. Prices stay put.
local MEADOW_SATCHELS = {
	{ slots = 480, price = 0 },
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
	local authored = extra and extra.nameKey and BagNames.get(extra.zoneId or extra.nameZone, extra.nameKind, extra.nameIndex)
	if authored then
		name = authored
		if extra then extra.needsName = nil end
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

-- 6 fossil bags / zone.
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

function MineBags.coinPrice(slots)
	slots = math.max(1, math.floor(tonumber(slots) or 1))
	return math.floor(MineBags.COIN_A * (slots ^ MineBags.COIN_B) + 0.5)
end

-- Fossil bags are crafted on the fossil track, never bought. They stay in LIST
-- (backpackTier indexes it) but the coin shelf and the buy verb both skip them.
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
	name = "Founders Rig",
	slots = math.floor(topCoin.slots * 1.12 + 0.5),
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
})

nextId += 1
table.insert(LIST, {
	id = nextId,
	name = "Wormhole Bag",
	slots = math.floor(topCoin.slots * 4 + 0.5),
	price = 0,
	minZone = 1,
	band = "deep",
	blurb = "Best bag in the game. Event Horizon haul.",
	limited = "bigbang",
	infinite = true,
	best = true,
	skin = "wormhole",
	zoneId = "bigbang",
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

return MineBags
