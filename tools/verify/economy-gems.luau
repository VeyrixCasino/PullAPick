--[[
	economy-gems.luau -- the gem economy, measured off the real tables.

	Owner, 2026-10-19: "make sure gems semi maintain the same ish value (pet
	simulator 99 or whatever ... disgusts me because of the inflation)". So no
	change may quietly print gems. This file is appended to the shared harness
	prelude (tools/verify/_shared.js) by economy-gems.js, which then calls one
	of the two entry points at the bottom:

	  MEASURE("after")    this tree: chests through MineZoneChests.spawnTable /
	                      payout (the rank-first chests of 2026-10-19), charms
	                      through MineCharms (tiers, Charm Packs)
	  MEASURE("before")   a 3863d14 tree: the old openChestBlock resolution,
	                      re-stated exactly (Meadow and Event Horizon paid their
	                      section chest; elsewhere a pool roll by rank weight,
	                      B/A/S lifted by depth; the native row opened rankless)

	Both print the same lines, so economy-gems.js can store "before" once as a
	baseline and compare "after" against it on every run.

	WHAT A LINE IS
	  CHEST <zone> <layer> k=v ...   one average chest at that depth: coins,
	                                 gems, pouch gems (pgems), pack case count
	                                 and stardust value, skin case tier value,
	                                 books and book levels, player XP, card
	                                 value (pval, the stardust its card packs
	                                 recycle for), and the zone pack slots
	  STAGE <name> k=v ...           an hour of digging at a stage (below)
	  CHARM k=v ...                  the gem-facing charm numbers

	THE HOUR (PROPOSED assumptions, 2026-10-19). A player at a stage breaks
	BLOCKS_PER_HOUR blocks: 20 chests an hour at MineConfig.CHEST_CHANCE, the
	figure the chest pacing was cut against (MineConfig's CHEST_CHANCE comment).
	Gems in: chests (and their pouches) plus the ore those blocks hold, sold at
	the surface (MineConfig.oreWeights x oreYieldFor x MineOrePouch.gemValue).
	Lucky blocks, quests and level gifts are left out: nothing here changes them.
	A "gem build" player also wears the strongest Gem Find charm there is, at
	the best tier it can reach.
]]

local function R(n)
	return require(SHARED:FindFirstChild(n))
end
-- The pieces of Roblox MineConfig and friends touch at load.
local function dt()
	return setmetatable({}, { __index = function()
		return function(...)
			return setmetatable({ X = 0, Y = 0, Z = 0, Magnitude = 0 }, {
				__index = function() return 0 end,
				__add = function(a) return a end, __sub = function(a) return a end,
				__mul = function(a) return a end,
			})
		end
	end })
end
Vector3, Vector2, CFrame, UDim2, UDim = dt(), dt(), dt(), dt(), dt()
NumberSequence, ColorSequence, NumberRange, TweenInfo, BrickColor = dt(), dt(), dt(), dt(), dt()
ColorSequenceKeypoint, NumberSequenceKeypoint, Rect, Font, PhysicalProperties = dt(), dt(), dt(), dt(), dt()
Color3 = {
	new = function(r, g, b) return { R = r or 0, G = g or 0, B = b or 0 } end,
	fromRGB = function(r, g, b) return { R = (r or 0) / 255, G = (g or 0) / 255, B = (b or 0) / 255 } end,
	fromHSV = function() return { R = 0, G = 0, B = 0 } end,
	fromHex = function() return { R = 0, G = 0, B = 0 } end,
}
task = { wait = function() end, spawn = function() end, delay = function() end, defer = function() end }
local function node(name)
	local n = { Name = name }
	n.IsStudio = function() return false end
	n.IsServer = function() return true end
	n.IsClient = function() return false end
	n.WaitForChild = function(_, c)
		if c == "Shared" then return SHARED end
		return node(c)
	end
	n.FindFirstChild = n.WaitForChild
	return n
end
game = { GetService = function(_, s) return node(s) end }
do
	-- MineConfig snapshots MineDepth with :Clone(); a clone that will not
	-- require falls back to the real module, which is what happens here.
	local find = SHARED.FindFirstChild
	SHARED.FindFirstChild = function(self, n)
		local m = find(self, n)
		if m and not m.Clone then
			m.Clone = function(me) return { Name = me.Name, Destroy = function() end } end
			m.Destroy = function() end
		end
		return m
	end
	SHARED.WaitForChild = function(self, n)
		return SHARED.FindFirstChild(self, n) or error("no stub for Shared." .. tostring(n))
	end
end

local C = R("MineConfig")
local ZP = R("MineZonePacks")
local Cases = R("MineCases")
local E = R("MineEnchants")
local Packs = R("MinePackConfig")
local SetPacks = R("MineSetPacks")
local SetPets = R("MineSetPets")
local Pouch = R("MineOrePouch")
local Charms = R("MineCharms")

-- PROPOSED (2026-10-19): the stages and the hour.
local CHESTS_PER_HOUR = 20
local BLOCKS_PER_HOUR = CHESTS_PER_HOUR / C.CHEST_CHANCE
local STAGES = {
	{ name = "start", zone = "meadow", layer = 100 },
	{ name = "early", zone = "sunscar", layer = 250 },
	{ name = "mid", zone = "bloodmoon", layer = 750 },
	{ name = "late", zone = "primordium", layer = 1500 },
}
local SAMPLE_LAYERS = { 1, 100, 250, 500, 1000, 2500, 5000 }
local ZONES = { "meadow", "sunscar", "mistreef", "arcwork", "bloodmoon", "eclipse",
	"riftmarch", "starfall", "mythral", "primordium", "bigbang" }
local SLOTS = { "pack_common", "pack_rare", "pack_legendary", "currency_common", "currency_rare" }
local SKIN_IDX = { F = 1, D = 2, C = 3, B = 4, A = 5, S = 6, SS = 7, SSS = 8 }

local function mid(b)
	if type(b) ~= "table" then return 0 end
	return ((b[1] or 0) + (b[2] or b[1] or 0)) / 2
end

-- -------------------------------------------------------------- packs --
local DUST = Packs.RECYCLE_STARDUST
local function zoneSlotValue(zoneId, slot, layer)
	local zp = ZP.get(ZP.id(zoneId, slot))
	if not zp or zp.kind ~= "cards" then
		return 0
	end
	local maxL = (zoneId == "meadow") and (C.MINE1_LAYERS or 2500) or C.zoneLayers(zoneId)
	local heat = (slot == "pack_legendary") and 2 or (slot == "pack_rare") and 1 or 0
	local odds = Packs.depthCardOdds(layer, maxL, heat)
	local per, tot = 0, 0
	for t, p in pairs(odds) do
		per += p * (DUST[t] or 0)
		tot += p
	end
	return (zp.cards or 3) * per / math.max(tot, 1e-9)
end
local function setPackValue(setKey, stars)
	local set = SetPets.BY_KEY[setKey]
	return SetPacks.expectedPackDust(stars, DUST, set and set.GRADE)
end

-- What every rank-keyed table pays a chest of `rank`, in expectation.
local function rankLoot(out, rank)
	for _, r in ipairs(Cases.chestCaseOdds(rank)) do
		out.caseN += r.p
		out.caseDust += r.p * Cases.expectedDust(r.def.id)
	end
	for _, r in ipairs(C.skinCaseTierOdds(rank)) do
		out.skin += C.CHEST_SKIN_CASE_CHANCE * r.p * (SKIN_IDX[r.tier] or 1)
	end
	local n = E.CHEST_BUNDLE[rank or ""] or E.CHEST_BUNDLE_BASE
	local lift = E.BOOK_RANK_LEVEL[rank or ""]
	out.books += E.CHEST_BOOK_CHANCE * n
	out.bookLv += E.CHEST_BOOK_CHANCE * n * (1 + (lift and (lift[1] + lift[2]) or 0))
	out.xp += E.XP_CHEST * (E.XP_CHEST_RANK[rank or ""] or 1)
end

local function blank()
	local o = { coins = 0, gems = 0, pgems = 0, caseN = 0, caseDust = 0, skin = 0, books = 0, bookLv = 0, xp = 0, pval = 0 }
	for _, s in ipairs(SLOTS) do o[s] = 0 end
	return o
end

local function addSlot(o, zoneId, slot, p, layer)
	o[slot] = (o[slot] or 0) + p
	local zp = ZP.get(ZP.id(zoneId, slot))
	if zp and zp.kind == "currency" then
		o.pgems += p * mid(zp.gems)
	else
		o.pval += p * zoneSlotValue(zoneId, slot, layer)
	end
end

-- ---------------------------------------------------------------- after --
local function afterTable(zoneId, layer)
	local ZC = R("MineZoneChests")
	local SC = R("MineSetChests")
	local rows = {}
	for _, r in ipairs(ZC.spawnTable(zoneId, layer, C.zoneIndex(zoneId), C.chestRankLuck(zoneId, layer))) do
		local pay = ZC.payout(r.def, zoneId, layer)
		local o = blank()
		o.coins, o.gems = mid(pay.coins), mid(pay.gems)
		for _, e in ipairs(pay.packs) do
			local p = (e.chance or 0) / 100
			if e.set then
				for _, so in ipairs(SC.packOdds(e.set, e.tier)) do
					o.pval += p * so.p * setPackValue(e.set, so.stars)
				end
			else
				addSlot(o, zoneId, e.slot, p, layer)
			end
		end
		rankLoot(o, r.rank)
		table.insert(rows, { p = r.p, o = o, rank = r.rank })
	end
	return rows
end

-- --------------------------------------------------------------- before --
local function beforeTable(zoneId, layer)
	local ZC = R("MineZoneChests")
	local Ranks = R("MineChestRanks")
	local rows = {}
	local function push(def, rank, p)
		local o = blank()
		o.coins, o.gems = mid(def.coins), mid(def.gems)
		for _, e in ipairs(def.packs or {}) do
			addSlot(o, zoneId, e.slot, (e.chance or 0) / 100, layer)
		end
		rankLoot(o, rank)
		table.insert(rows, { p = p, o = o, rank = rank or "native" })
	end
	if zoneId == "meadow" or zoneId == "bigbang" then
		push(ZC.exclusiveFor(zoneId, layer), "native", 1)
		return rows
	end
	local better = C.chestRankLuck(zoneId, layer)
	local zi = C.zoneIndex(zoneId)
	local shiny = 0
	if zi <= 1 then
		shiny = (layer >= 2500) and (1 / 8000) or 0
	else
		local t = math.clamp((zi - 1) / 9, 0, 1)
		shiny = (1 / 2500) * (1 - t) + 0.008 * t
	end
	local pool = {}
	for _, row in ipairs(ZC.POOLS[zoneId] or {}) do
		table.insert(pool, row)
	end
	local ex = ZC.exclusiveFor(zoneId, layer)
	table.insert(pool, { chestId = ex.id, rank = "C", def = ex, native = true })
	local ws, tot = {}, 0
	for i, row in ipairs(pool) do
		local w = Ranks.weightOf(row.rank)
		if row.rank == "B" or row.rank == "A" or row.rank == "S" then
			w *= better
		end
		ws[i] = w
		tot += w
	end
	for i, row in ipairs(pool) do
		push(row.def or ZC.DEFS[row.chestId], (not row.native) and row.rank or nil, (1 - shiny) * ws[i] / tot)
	end
	if shiny > 0 then
		push(ZC.DEFS.shiny_chest, nil, shiny)
	end
	return rows
end

local function expect(rows)
	local acc = blank()
	for _, r in ipairs(rows) do
		for k, v in pairs(r.o) do
			acc[k] = (acc[k] or 0) + r.p * v
		end
	end
	return acc
end

-- ------------------------------------------------------------------ ore --
local function oreGemsPerOreBlock(zoneId, layer)
	local row = C.oreWeights(zoneId, layer, nil)
	local ev, tot = 0, 0
	for i, o in ipairs(C.ORES) do
		local w = row.w[i] or 0
		if w > 0 then
			local lo, hi = C.oreYieldFor(o.tier)
			ev += w * Pouch.gemValue(o) * (lo + hi) / 2
			tot += w
		end
	end
	return (tot > 0) and (ev / tot) or 0
end

-- ---------------------------------------------------------------- charms --
-- The strongest Gem Find any one charm gives (+N as a fraction), at the best
-- tier a player can reach: TIER_MAX after 2026-10-19, tier I before.
local function bestGemFind()
	local best, who = 0, "none"
	local tier = Charms.TIER_MAX or 1
	for _, def in ipairs(Charms.LIST) do
		local stats = Charms.statsAt and Charms.statsAt(def, tier) or def.stats or {}
		local g = tonumber(stats.gemFind) or 0
		if g > best then
			best, who = g, def.id
		end
	end
	return best, who
end

local function fmt(o)
	local keys = {}
	for k in pairs(o) do table.insert(keys, k) end
	table.sort(keys)
	local bits = {}
	for _, k in ipairs(keys) do
		table.insert(bits, string.format("%s=%.6g", k, o[k]))
	end
	return table.concat(bits, " ")
end

function MEASURE(mode)
	local tableOf = (mode == "before") and beforeTable or afterTable
	for _, z in ipairs(ZONES) do
		for _, L in ipairs(SAMPLE_LAYERS) do
			print(string.format("CHEST %s %d %s", z, L, fmt(expect(tableOf(z, L)))))
		end
	end
	local gf, gfWho = bestGemFind()
	print(string.format("CHARM bestGemFind=%.6g", gf), "who=" .. tostring(gfWho))
	for _, s in ipairs(STAGES) do
		local a = expect(tableOf(s.zone, s.layer))
		local chests = CHESTS_PER_HOUR * ((s.zone == "meadow" and s.layer <= 100) and (C.MEADOW_SHALLOW_CHEST_MULT or 1) or 1)
		local chestGems = chests * (a.gems + a.pgems)
		local oreGems = BLOCKS_PER_HOUR * C.ORE_CHANCE * oreGemsPerOreBlock(s.zone, s.layer)
		local buildGems = chests * (a.gems * (1 + gf) + a.pgems)
		print(string.format("STAGE %s chests=%.6g chestGems=%.6g oreGems=%.6g gemsIn=%.6g gemsInGemBuild=%.6g",
			s.name, chests, chestGems, oreGems, chestGems + oreGems, buildGems + oreGems))
	end
	if mode == "after" then
		-- The sinks this change adds, priced as they are charged.
		for _, pack in ipairs(Charms.CHARM_PACKS or {}) do
			local odds = Charms.charmPackOdds(pack.rarity)
			local sum, gemsBack = 0, 0
			for _, r in ipairs(odds) do
				sum += r.p
			end
			local def = Charms.rollCharmPack(pack.rarity, Random.new(7))
			print(string.format("PACK %s gems=%d credits=%d n=%d psum=%.9f rolls=%s back=%d",
				pack.rarity, pack.gems, pack.credits, #odds, sum,
				tostring(def and def.rarity == pack.rarity and def.id), gemsBack))
		end
		for _, r in ipairs({ "F", "D", "C", "B", "A", "S", "SS", "SSS" }) do
			local total = 0
			for t = 2, Charms.TIER_MAX do
				total += Charms.mergeGemCost(r, t) or 0
			end
			print(string.format("MERGE %s toII=%d toV=%d", r, Charms.mergeGemCost(r, 2) or 0, total))
		end
	end
end
