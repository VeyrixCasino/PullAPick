--[[
	OreBalanceSim -- the ore brief's asserts, run against the real MineConfig.

	Pure Lua, no world, no player. It reads C.ORES / C.ORE_BAND_WEIGHT /
	C.blockHp and re-derives every share the generator would roll, so the
	numbers in the brief are checked against the shipping config rather than
	against a spreadsheet that agreed with it once.

	Run it from the command bar (Edit or Run, either works):

		require(game.ServerStorage.OreBalanceSim).run()

	It prints the spawn table and then PASS/FAIL per rule. A FAIL is a tuning
	job -- ORE_BAND_WEIGHT, the `home` column, ORE_EXOTIC_OFF_ZONE -- never a
	reason to relax the rule.

	Scope: the 10 MAIN zones. Event Horizon runs MineHorizonTools and its own
	gate, and is deliberately not modelled here.
]]

local OreBalanceSim = {}

local RS = game:GetService("ReplicatedStorage")
local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared:WaitForChild("MineConfig"))

-- The brief's two reference players, in blocks per hour.
OreBalanceSim.RATE_NEW = 9000
OreBalanceSim.RATE_STRONG = 145000

-- Rule b: no ore of these bands may ever exceed this share, anywhere.
OreBalanceSim.CAP = { Legendary = 0.015, Mythic = 0.004, Divine = 0.001, Exotic = 0.0005}
-- Rule c: every ore must reach at least this share at its own best spot.
OreBalanceSim.FLOOR = {
	Common = 0.003, Uncommon = 0.003, Rare = 0.003, Epic = 0.003,
	Legendary = 0.003, Mythic = 0.001, Divine = 0.0003, Exotic = 0.0001,
}
-- Rule c2: the three Exotic ores together, at the deepest main-zone spot.
OreBalanceSim.EXOTIC_LO, OreBalanceSim.EXOTIC_HI = 0.00028, 0.0014

local function mainZones()
	local out = {}
	for i, z in ipairs(C.ZONES or {}) do
		if z.id ~= "bigbang" then
			out[#out + 1] = { index = i, id = z.id }
		end
	end
	return out
end

-- Every spot the asserts sweep: each main zone x every 40 layers, plus the
-- deepest reachable layer, which is where the top bands actually live.
local function spots()
	local out = {}
	for _, z in ipairs(mainZones()) do
		for L = 1, 2480, 40 do
			out[#out + 1] = { zi = z.index, id = z.id, L = L }
		end
		out[#out + 1] = { zi = z.index, id = z.id, L = 2441 }
		out[#out + 1] = { zi = z.index, id = z.id, L = 2500 }
	end
	return out
end

--[[
	The generator's own weight, re-derived.

	Deliberately a copy of MineConfig.oreWeights rather than a call to it: the
	live one caches per section and bucket, and a sim that reads the cache would
	pass while the formula underneath it was wrong.
]]
function OreBalanceSim.shares(zoneId, layer)
	local X0, K, S, W = C.ORE_X0, C.ORE_K, C.ORE_S, C.ORE_W
	local bandW = C.ORE_BAND_WEIGHT or {}
	local zi = C.zoneIndex(zoneId)
	local dl = C.oreDifficulty(zoneId, layer) + (C.ZONE_ORE_SHIFT or 0) * zi
	local offZone = (zoneId ~= C.ORE_EXOTIC_HOME_ZONE) and (C.ORE_EXOTIC_OFF_ZONE or 1) or 1
	local w, tot = {}, 0
	for i, o in ipairs(C.ORES) do
		local x = o.d - dl
		local v = 1 / (1 + math.exp((x - X0) / K))
		if x < 0 then
			v = v * math.exp(x / S) * math.exp(-((x / W) ^ 2))
		end
		v = v * (bandW[o.band] or 1)
		if o.band == "Exotic" then
			v = v * offZone
		end
		w[i] = v
		tot += v
	end
	if tot <= 0 then
		return w, 0
	end
	for i = 1, #w do
		w[i] = w[i] / tot
	end
	return w, tot
end

local function bandTotals(sh)
	local t = {}
	for _, b in ipairs(C.ORE_BAND_ORDER) do
		t[b] = 0
	end
	for i, o in ipairs(C.ORES) do
		t[o.band] = (t[o.band] or 0) + sh[i]
	end
	return t
end

local function ranked(sh)
	local idx = {}
	for i = 1, #sh do
		idx[i] = i
	end
	table.sort(idx, function(a, b) return sh[a] > sh[b] end)
	local rank = {}
	for r, i in ipairs(idx) do
		rank[i] = r
	end
	return rank, idx
end

--[[
	Best spot per ore: where it is the largest share of the roll. That spot is
	the ore's HOME for every later purpose -- tool power is anchored to the
	rock there, and so is how much of it you can gather per hour.
]]
function OreBalanceSim.survey()
	local best = {}
	for i = 1, #C.ORES do
		best[i] = { share = -1 }
	end
	for _, s in ipairs(spots()) do
		local sh = OreBalanceSim.shares(s.id, s.L)
		local rank = ranked(sh)
		for i = 1, #sh do
			if sh[i] > best[i].share then
				best[i] = {
					share = sh[i], zone = s.id, zi = s.zi, L = s.L,
					rank = rank[i], hardness = C.oreDifficulty(s.id, s.L),
					hp = C.blockHp("dirt", s.id, s.L),
				}
			end
		end
	end
	return best
end

local function fmtHours(h)
	if h ~= h or h == math.huge then return "never" end
	if h < 1 / 60 then return string.format("%.0fs", h * 3600) end
	if h < 1 then return string.format("%.0fm", h * 60) end
	return string.format("%.2fh", h)
end

function OreBalanceSim.report()
	local best = OreBalanceSim.survey()
	print(("="):rep(132))
	print("ORE SPAWN TABLE -- 82 ores, main zones only")
	print(string.format("%3s %-13s %-10s %6s %13s %-20s %8s %5s %10s %12s %11s",
		"t", "ore", "band", "home", "home HP", "best spot", "share", "rank",
		"ore/h 9K", "ore/h 145K", "h/find 145K"))
	print(("-"):rep(132))
	for i, o in ipairs(C.ORES) do
		local b = best[i]
		local perOreBlock = C.ORE_CHANCE * b.share
		local oh9 = OreBalanceSim.RATE_NEW * perOreBlock
		local oh145 = OreBalanceSim.RATE_STRONG * perOreBlock
		print(string.format("%3d %-13s %-10s %6.2f %13s %-20s %7.4f%% %5d %10.2f %12.2f %11s",
			o.tier, o.name, o.band, o.home or 0, C.abbrev and C.abbrev(b.hp) or tostring(b.hp),
			b.zone .. " L" .. b.L, b.share * 100, b.rank, oh9, oh145,
			fmtHours(oh145 > 0 and 1 / oh145 or math.huge)))
	end
	return best
end

function OreBalanceSim.run(verbose)
	if verbose ~= false then
		OreBalanceSim.report()
	end
	local best = OreBalanceSim.survey()
	local fails = {}
	local function fail(rule, msg)
		fails[#fails + 1] = rule .. "  " .. msg
	end

	-- roster shape -------------------------------------------------------
	if #C.ORES ~= 82 then
		fail("roster", ("#C.ORES = %d, expected 82"):format(#C.ORES))
	end
	for i, o in ipairs(C.ORES) do
		if o.tier ~= i then
			fail("roster", ("%s tier %d at index %d"):format(o.name, o.tier, i))
		end
		if not C.ORE_BAND_INDEX[o.band] then
			fail("roster", ("%s has no band"):format(o.name))
		end
		if o.name:match("Crystal$") or o.name:match("Shard$") or o.name:find(" ") or o.name:find("'") then
			fail("naming", ("%s breaks the naming rule"):format(o.name))
		end
		if type(o.yield) ~= "table" or not o.yield[1] or not o.yield[2] then
			fail("roster", ("%s has no pack yield"):format(o.name))
		end
	end

	-- rule a: Epic is the deepest common vein ------------------------------
	local deep = OreBalanceSim.shares("primordium", 2441)
	local _, order = ranked(deep)
	local topBand = C.ORES[order[1]].band
	if topBand ~= "Epic" then
		fail("a", ("deepest most-common is %s (%s), want an Epic"):format(C.ORES[order[1]].name, topBand))
	end

	-- rules b: caps, never top-10, and the rare-band ladder ---------------
	for _, s in ipairs(spots()) do
		local sh = OreBalanceSim.shares(s.id, s.L)
		local rank = ranked(sh)
		for i, o in ipairs(C.ORES) do
			local cap = OreBalanceSim.CAP[o.band]
			if cap then
				if sh[i] > cap then
					fail("b-cap", ("%s %.4f%% > %.2f%% at %s L%d"):format(o.name, sh[i] * 100, cap * 100, s.id, s.L))
				end
				if rank[i] <= 10 then
					fail("b-top10", ("%s rank %d at %s L%d"):format(o.name, rank[i], s.id, s.L))
				end
			end
		end
		local bt = bandTotals(sh)
		local ladder = { "Legendary", "Mythic", "Divine", "Exotic" }
		for k = 1, #ladder - 1 do
			if bt[ladder[k + 1]] > bt[ladder[k]] + 1e-15 then
				fail("b-ladder", ("%s > %s at %s L%d"):format(ladder[k + 1], ladder[k], s.id, s.L))
			end
		end
	end

	-- rule c: floors -------------------------------------------------------
	for i, o in ipairs(C.ORES) do
		local floor = OreBalanceSim.FLOOR[o.band] or 0
		if best[i].share < floor then
			fail("c-floor", ("%s (%s) best %.4f%% < %.2f%%"):format(o.name, o.band, best[i].share * 100, floor * 100))
		end
	end

	-- rule c2: the exotic headline, and its depth gate ---------------------
	local bt = bandTotals(deep)
	local exo = bt.Exotic
	if exo < OreBalanceSim.EXOTIC_LO or exo > OreBalanceSim.EXOTIC_HI then
		fail("c2", ("exotic band at deepest = %.4f%%, want %.3f%%-%.3f%%"):format(
			exo * 100, OreBalanceSim.EXOTIC_LO * 100, OreBalanceSim.EXOTIC_HI * 100))
	end
	local exoP1 = bandTotals(OreBalanceSim.shares("primordium", 1)).Exotic
	if exoP1 > exo / 10 then
		fail("c2-gate", ("primordium L1 exotic only %.1fx rarer"):format(exo / math.max(exoP1, 1e-18)))
	end
	local worstOut = 0
	for _, z in ipairs(mainZones()) do
		if z.id ~= C.ORE_EXOTIC_HOME_ZONE then
			for L = 1, 2500, 40 do
				worstOut = math.max(worstOut, bandTotals(OreBalanceSim.shares(z.id, L)).Exotic)
			end
			worstOut = math.max(worstOut, bandTotals(OreBalanceSim.shares(z.id, 2441)).Exotic)
		end
	end
	if worstOut > exo / 100 then
		fail("c2-gate", ("outside primordium exotic only %.1fx rarer"):format(exo / math.max(worstOut, 1e-18)))
	end

	-- rule d: every zone surface a different ore ---------------------------
	local surf = {}
	for _, z in ipairs(mainZones()) do
		local sh = OreBalanceSim.shares(z.id, 1)
		local _, ord = ranked(sh)
		surf[#surf + 1] = C.ORES[ord[1]].name
	end
	for k = 2, #surf do
		if surf[k] == surf[k - 1] then
			fail("d", ("surfaces repeat: %s"):format(surf[k]))
		end
	end

	-- pack yields ---------------------------------------------------------
	local evSum, evN = 0, 0
	for _, o in ipairs(C.ORES) do
		if o.tier >= 53 then
			evSum += (o.yield[1] + o.yield[2]) / 2
			evN += 1
		end
	end
	local evAvg = evN > 0 and evSum / evN or 0
	if evAvg < 6 or evAvg > 7 then
		fail("yield", ("top-30 average EV %.3f, want 6.0-7.0"):format(evAvg))
	end

	-- ---------------------------------------------------------------------
	print(("="):rep(132))
	print("zone surfaces: " .. table.concat(surf, ", "))
	print(string.format("rare bands at the deepest spot: Legendary %.4f%%  Mythic %.4f%%  Divine %.4f%%  Exotic %.4f%%",
		bt.Legendary * 100, bt.Mythic * 100, bt.Divine * 100, bt.Exotic * 100))
	for _, b in ipairs({ "Legendary", "Mythic", "Divine", "Exotic" }) do
		local perBlock = C.ORE_CHANCE * bt[b]
		print(string.format("  %-10s %s at %dK blocks/h,  %s at %dK",
			b, fmtHours(1 / (OreBalanceSim.RATE_STRONG * perBlock)), OreBalanceSim.RATE_STRONG // 1000,
			fmtHours(1 / (OreBalanceSim.RATE_NEW * perBlock)), OreBalanceSim.RATE_NEW // 1000))
	end
	print(string.format("exotic gate: primordium L1 %.1fx rarer, outside primordium %.1fx rarer",
		exo / math.max(exoP1, 1e-18), exo / math.max(worstOut, 1e-18)))
	print(string.format("top-30 pack yield average EV %.3f", evAvg))
	print(("="):rep(132))
	if #fails == 0 then
		print("ALL ORE ASSERTS PASS (" .. #C.ORES .. " ores, " .. #spots() .. " spots swept)")
	else
		print("FAILS: " .. #fails)
		local seen = {}
		for _, f in ipairs(fails) do
			local key = f:match("^%S+")
			if not seen[key] then
				seen[key] = true
				print("   " .. f)
			end
		end
	end
	return #fails == 0, fails
end

--[[
	MIGRATION TEST -- a synthetic save holding every removed and renamed ore.

	The maps are where the bugs live: a chain that ends on an id that no longer
	exists deletes a player's stock silently, and a tier index that lands
	outside 1..82 puts a tool nobody can name in the bench. This builds a save
	that holds one of everything, walks it through v1 then v2 exactly as
	MineServer does, and then checks the result rather than the intent.

		require(game.ServerStorage.OreBalanceSim).migrationTest()
]]
function OreBalanceSim.migrationTest()
	local kept = {}
	for _, o in ipairs(C.ORES) do
		kept[o.id] = o.tier
	end

	-- one of every id the maps mention, plus every kept id
	local save = { ores = {}, packs = {}, oreTools = {}, dust = 0, oreRosterV = 0 }
	local sourced = 0
	for _, map in ipairs({ C.ORE_MIGRATION or {}, C.ORE_MIGRATION_V2 or {} }) do
		for oldId in pairs(map) do
			if save.ores[oldId] == nil then
				save.ores[oldId] = 100
				save.packs[#save.packs + 1] = { packId = oldId .. "_ore_pack" }
				sourced += 1
			end
		end
	end
	for id in pairs(kept) do
		save.ores[id] = (save.ores[id] or 0) + 7
	end
	-- tools at every old index, including levels above the new cap
	for oldTier = 1, 121 do
		save.oreTools[#save.oreTools + 1] =
			{ uid = "u" .. oldTier, tier = oldTier, level = (oldTier % 7 == 0) and 640 or 12 }
	end
	local beforeTotal = 0
	for _, v in pairs(save.ores) do
		beforeTotal += v
	end

	-- ---- the same two passes MineServer runs ----
	local function pass(map)
		for oldId, newId in pairs(map) do
			if oldId ~= newId then
				local held = tonumber(save.ores[oldId])
				if held and held > 0 then
					save.ores[newId] = (tonumber(save.ores[newId]) or 0) + held
				end
				save.ores[oldId] = nil
			end
		end
		for _, pk in ipairs(save.packs) do
			local base = pk.packId:match("^(.*)_ore_pack$")
			local to = base and map[base]
			if to then
				pk.packId = to .. "_ore_pack"
			end
		end
	end
	pass(C.ORE_MIGRATION or {})
	pass(C.ORE_MIGRATION_V2 or {})
	local cap = math.min(100, tonumber(C.TOOL_MAX_LEVEL) or 100)
	local clamped = 0
	for _, t in ipairs(save.oreTools) do
		local r = (C.ORE_TIER_REMAP_V2 or {})[t.tier]
		if r then
			t.tier = r
		end
		if t.level > cap then
			t.level = cap
			clamped += 1
		end
	end

	-- ---- checks ----
	local fails = {}
	local afterTotal = 0
	for id, v in pairs(save.ores) do
		afterTotal += v
		if not kept[id] then
			fails[#fails + 1] = ("ore pile left on a dead id: %s"):format(id)
		end
	end
	if math.abs(afterTotal - beforeTotal) > 0.001 then
		fails[#fails + 1] = ("ore total changed: %d -> %d"):format(beforeTotal, afterTotal)
	end
	for _, pk in ipairs(save.packs) do
		local base = pk.packId:match("^(.*)_ore_pack$")
		if not (base and kept[base]) then
			fails[#fails + 1] = ("pack left on a dead id: %s"):format(pk.packId)
		end
	end
	for _, t in ipairs(save.oreTools) do
		if type(t.tier) ~= "number" or t.tier < 1 or t.tier > #C.ORES then
			fails[#fails + 1] = ("tool %s tier out of range: %s"):format(tostring(t.uid), tostring(t.tier))
		end
		if t.level < 1 or t.level > cap then
			fails[#fails + 1] = ("tool %s level %s outside 1..%d"):format(tostring(t.uid), tostring(t.level), cap)
		end
	end
	-- no chain may end on a removed id, even if only one pass runs
	for _, map in ipairs({ C.ORE_MIGRATION or {}, C.ORE_MIGRATION_V2 or {} }) do
		for oldId, newId in pairs(map) do
			if not kept[newId] then
				fails[#fails + 1] = ("map chain ends on a dead id: %s -> %s"):format(oldId, newId)
			end
		end
	end
	-- idempotence: running both passes again must change nothing
	local snap = {}
	for id, v in pairs(save.ores) do
		snap[id] = v
	end
	pass(C.ORE_MIGRATION or {})
	pass(C.ORE_MIGRATION_V2 or {})
	for id, v in pairs(save.ores) do
		if snap[id] ~= v then
			fails[#fails + 1] = ("not idempotent: %s %s -> %s"):format(id, tostring(snap[id]), tostring(v))
		end
	end

	print(("="):rep(80))
	print(("migration test: %d dead ids sourced, %d kept ids, %d tools, %d levels clamped")
		:format(sourced, #C.ORES, #save.oreTools, clamped))
	print(("ore total preserved: %d -> %d"):format(beforeTotal, afterTotal))
	if #fails == 0 then
		print("MIGRATION TEST PASSES")
	else
		print("MIGRATION FAILS: " .. #fails)
		for i = 1, math.min(#fails, 12) do
			print("   " .. fails[i])
		end
	end
	return #fails == 0, fails
end

return OreBalanceSim
