--[[
	THE WANDERING TRADER.

	Owner, 2026-10-07: "make a rotating shop with tokens with a wandering trader
	that spawns at random depth outposts in random zones, and dependant on what
	depths/zone has different stuff (5 different cases (random tool), custom hats
	case, random charm case)" and "5 different traders at once".

	EVERYTHING HERE IS DETERMINISTIC IN THE ROTATION NUMBER, and that is the one
	design decision the rest follows from. Where the five traders are, and what
	each one is selling, is a pure function of (rotation, zone, seam) -- no state,
	no saved table, no roll at spawn time. Three things fall out of that:

	  Every server agrees. A player who says "there's one at Bloodmoon 1500" is
	  right on your server too, which is the whole appeal of a wandering trader.
	  A per-server roll would make that sentence meaningless.

	  A late joiner sees what everybody else sees, with no catch-up state to
	  replicate and nothing to save on the profile.

	  It is testable without a server: the harness walks thousands of rotations
	  and checks the distribution, which is how the "random" in the request gets
	  held to account.

	The clock is the only input, through rotationFor(os.time()). Wall clock, not
	os.clock(), for the same reason the charm ramp uses it: os.clock() is
	process-relative and means nothing across two servers.
]]
local MineTrader = {}

local Charms = require(script.Parent:WaitForChild("MineCharms"))
local Temper = require(script.Parent:WaitForChild("MineTemper"))

-- Five at once, as asked. Also the reason placement draws WITHOUT replacement:
-- five traders stacked on one outpost is not five traders.
MineTrader.COUNT = 5

-- A rotation is 15 minutes. Long enough that finding one is worth telling
-- somebody about, short enough that a bad roster is never long to wait out.
MineTrader.ROTATE_SECONDS = 900

--[[
	THE SEVEN CASES.

	Five tool cases plus a hats case and a charm case, as asked. The five tool
	cases are not five names for the same thing: each covers a band of the 82-ore
	tool ladder, and `minSeam`/`minZone` is what makes a trader's stock depend on
	where it is standing. A surface outpost in zone 1 cannot sell Apex.

	`tokens` is the base price. depthPrice() scales it by where the trader stands,
	so the same case costs more the deeper it is sold -- the tools inside are
	better there.
]]
MineTrader.CASES = {
	{
		id = "case_rough", name = "Rough Tool Case", kind = "tool",
		tierLo = 1, tierHi = 20, tokens = 25, minSeam = 0, minZone = 1,
		blurb = "A tool from the first twenty tiers.",
	},
	{
		id = "case_keen", name = "Keen Tool Case", kind = "tool",
		tierLo = 15, tierHi = 38, tokens = 60, minSeam = 500, minZone = 1,
		blurb = "A tool from the working tiers.",
	},
	{
		id = "case_fine", name = "Fine Tool Case", kind = "tool",
		tierLo = 32, tierHi = 55, tokens = 140, minSeam = 1500, minZone = 2,
		blurb = "A tool from the deep tiers.",
	},
	{
		id = "case_prime", name = "Prime Tool Case", kind = "tool",
		tierLo = 50, tierHi = 70, tokens = 320, minSeam = 2500, minZone = 4,
		blurb = "A tool from the rare tiers.",
	},
	{
		id = "case_apex", name = "Apex Tool Case", kind = "tool",
		tierLo = 66, tierHi = 82, tokens = 750, minSeam = 3500, minZone = 6,
		blurb = "A tool from the last sixteen tiers.",
	},
	{
		id = "case_hats", name = "Travelling Hats Case", kind = "hat",
		tokens = 180, minSeam = 500, minZone = 1,
		blurb = "Headwear the trader carries and nobody else sells.",
	},
	{
		id = "case_charm", name = "Charm Case", kind = "charm",
		tokens = 200, minSeam = 1000, minZone = 1,
		blurb = "One charm, drawn on the rarity ladder.",
	},
}

MineTrader.CASE_BY_ID = {}
for _, c in ipairs(MineTrader.CASES) do
	MineTrader.CASE_BY_ID[c.id] = c
end

-- How many cases one trader offers. Fewer than the catalogue, so two traders in
-- the same rotation are worth visiting both.
MineTrader.STOCK_MIN = 3
MineTrader.STOCK_MAX = 5

--[[
	A 32-bit mix, so placement is spread rather than merely varied.

	The same exact-multiply problem as MineConfig.mul32: Luau numbers are doubles,
	and `h * 0x85EBCA6B` loses the low bits a hash lives in. Split at 16 and the
	intermediates all fit inside 2^53.
]]
local function mul32(a, b)
	local ah, al = bit32.rshift(a, 16), bit32.band(a, 0xFFFF)
	local bh, bl = bit32.rshift(b, 16), bit32.band(b, 0xFFFF)
	local mid = bit32.band(ah * bl + al * bh, 0xFFFF) * 65536
	return bit32.band(al * bl + mid, 0xFFFFFFFF)
end

local function mix(h, v)
	h = bit32.bxor(bit32.band(h, 0xFFFFFFFF), bit32.band(v, 0xFFFFFFFF))
	h = mul32(h, 0x85EBCA6B)
	h = bit32.bxor(h, bit32.rshift(h, 13))
	h = mul32(h, 0xC2B2AE35)
	return bit32.bxor(h, bit32.rshift(h, 16))
end

-- 0..1 from a hash and a salt index.
local function unit(h, salt)
	return mix(h, salt * 0x9E3779B1 % 0x100000000) / 4294967296
end

MineTrader.ROTATION_SALT = 0x5bf03635

function MineTrader.rotationFor(now)
	local t = math.max(0, math.floor(tonumber(now) or 0))
	return math.floor(t / math.max(1, MineTrader.ROTATE_SECONDS))
end

-- Seconds until the roster changes. The shop panel counts down on this.
function MineTrader.secondsLeft(now)
	local period = math.max(1, MineTrader.ROTATE_SECONDS)
	local t = math.max(0, math.floor(tonumber(now) or 0))
	return period - (t % period)
end

--[[
	Where the five traders are this rotation.

	`spots` is every (zoneId, zoneIndex, seam) a trader could stand at -- the
	caller passes the outposts that actually exist, so this never places one at a
	plaza that was never built.

	DRAWN WITHOUT REPLACEMENT, by a partial Fisher-Yates over a copy. Picking five
	independent indices would collide often -- with 50-odd spots, five independent
	draws collide about a quarter of the time -- and two traders on one pad reads
	as a bug, not as luck. Shuffling is also what keeps the distribution flat;
	rejection-sampling until five differ biases nothing but is unbounded work.
]]
function MineTrader.placements(rotation, spots)
	local out = {}
	if type(spots) ~= "table" or #spots == 0 then
		return out
	end
	local pool = table.create(#spots)
	for i, s in ipairs(spots) do
		pool[i] = s
	end
	local h = mix(MineTrader.ROTATION_SALT, math.floor(tonumber(rotation) or 0))
	local want = math.min(MineTrader.COUNT, #pool)
	for i = 1, want do
		-- Pick from the remaining tail, then swap it into place.
		local r = unit(h, i)
		local j = i + math.floor(r * (#pool - i + 1))
		if j > #pool then
			j = #pool
		end
		pool[i], pool[j] = pool[j], pool[i]
		local spot = pool[i]
		table.insert(out, {
			zoneId = spot.zoneId,
			zoneIndex = spot.zoneIndex,
			seam = spot.seam,
			slot = i,
		})
	end
	return out
end

--[[
	Which cases a trader at this spot is carrying.

	Two filters, then a draw. `minSeam`/`minZone` decide what COULD be here --
	that is the "dependant on what depths/zone has different stuff" -- and the
	rotation decides which of those it actually brought. A case that cannot be
	here is never drawn, so a surface trader cannot sell Apex however the hash
	falls.

	Deterministic in (rotation, zoneIndex, seam), so two players asking the same
	trader see the same shelf.
]]
function MineTrader.stockFor(rotation, zoneIndex, seam)
	local zi = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	local sm = math.max(0, math.floor(tonumber(seam) or 0))
	local eligible = {}
	for _, c in ipairs(MineTrader.CASES) do
		if zi >= (c.minZone or 1) and sm >= (c.minSeam or 0) then
			table.insert(eligible, c)
		end
	end
	if #eligible == 0 then
		return {}
	end
	local h = mix(mix(mix(MineTrader.ROTATION_SALT, math.floor(tonumber(rotation) or 0)), zi), sm)
	local lo = math.max(1, MineTrader.STOCK_MIN)
	local hi = math.max(lo, MineTrader.STOCK_MAX)
	local want = math.min(#eligible, lo + math.floor(unit(h, 11) * (hi - lo + 1)))
	-- Same partial shuffle as placements, and for the same reason: a trader
	-- listing the same case twice is a bug a player would screenshot.
	for i = 1, want do
		local j = i + math.floor(unit(h, 20 + i) * (#eligible - i + 1))
		if j > #eligible then
			j = #eligible
		end
		eligible[i], eligible[j] = eligible[j], eligible[i]
	end
	local out = {}
	for i = 1, want do
		local c = eligible[i]
		table.insert(out, {
			caseId = c.id,
			name = c.name,
			kind = c.kind,
			blurb = c.blurb,
			tokens = MineTrader.priceFor(c, zi, sm),
		})
	end
	return out
end

--[[
	What a case costs here.

	Base price times depth. The deeper trader sells better tools out of the same
	case id, so charging the same would make the shallow one strictly worse to
	visit and the deep one the only stop worth making.

	Floored and never below the base, so a quoted price is never under what is
	charged and a surface trader is never cheaper than free.
]]
MineTrader.DEPTH_PRICE_PER_SEAM = 0.10
MineTrader.ZONE_PRICE_PER_STEP = 0.18

function MineTrader.priceFor(caseOrId, zoneIndex, seam)
	local c = type(caseOrId) == "table" and caseOrId or MineTrader.CASE_BY_ID[tostring(caseOrId or "")]
	if type(c) ~= "table" then
		return nil
	end
	local zi = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	local sm = math.max(0, math.floor(tonumber(seam) or 0))
	local depth = 1 + MineTrader.DEPTH_PRICE_PER_SEAM * (sm / 500)
	local zone = 1 + MineTrader.ZONE_PRICE_PER_STEP * (zi - 1)
	return math.max(c.tokens, math.floor(c.tokens * depth * zone + 0.5))
end

--[[
	What one case pays out.

	Returns a plain description -- kind plus the band or grade -- rather than the
	item itself, because the server owns granting and this module is shared with
	the client. A client that could resolve the reward could also predict it.

	The charm case draws on the same ladder MineCharms.rollChestCharm uses, so a
	charm is no commoner from a trader than from a chest; you are paying for the
	certainty of getting one at all, not for better odds.
]]
function MineTrader.rollCase(caseOrId, rng)
	local c = type(caseOrId) == "table" and caseOrId or MineTrader.CASE_BY_ID[tostring(caseOrId or "")]
	if type(c) ~= "table" then
		return nil
	end
	local r = rng or Random.new()
	if c.kind == "charm" then
		local def = Charms.rollChestCharm and Charms.rollChestCharm(r)
		return def and { kind = "charm", charmId = def.id, name = def.name, rarity = def.rarity } or nil
	end
	if c.kind == "hat" then
		-- Grade on MineTemper's weights, so a trader hat is no likelier to be SSS
		-- than one from a gear crate. The catalogue pick is the server's.
		local order = Temper.GRADE_ORDER or { "F" }
		local weights = Temper.RARITY_WEIGHTS or {}
		local total = 0
		for _, g in ipairs(order) do
			total += math.max(0, tonumber(weights[g]) or 0)
		end
		local pick = r:NextNumber() * math.max(1e-9, total)
		for _, g in ipairs(order) do
			pick -= math.max(0, tonumber(weights[g]) or 0)
			if pick <= 0 then
				return { kind = "hat", rarity = g }
			end
		end
		return { kind = "hat", rarity = order[1] }
	end
	-- Tool: a tier inside the case's band, uniform. The band IS the product.
	local lo = math.max(1, math.floor(tonumber(c.tierLo) or 1))
	local hi = math.max(lo, math.floor(tonumber(c.tierHi) or lo))
	return { kind = "tool", tier = r:NextInteger(lo, hi) }
end

return MineTrader
