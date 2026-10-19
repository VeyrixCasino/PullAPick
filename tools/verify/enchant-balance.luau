--[[
	THE ABILITY ENCHANTS' BALANCE PASS (owner, 2026-10-19: "Do balancing checks
	to make sure good enough, but not too overpowered stacked with enchants
	too, i want every ability enchant to be viable with different builds,
	depending on what their going for").

	Run by tools/verify/enchant-balance.js, after _enchant-sim.js's prelude
	and world: every number below comes out of the REAL modules and the REAL
	server proc code (Dig.procsAt, Dig.startQuake and the quake tick, sliced
	out of MineServer), swung through SIM.swing, swingBlock's own steps. The
	teams are what Equip Best would seat (the real Dig.petShares / petWorth)
	from the stage's pets.

	For each stage x tool family x Special x build it measures, on the stage's
	own rock:
	  AREA    blocks broken a second digging a pit layer by layer at the
	          stage's depth -- the progression number: ore, coins and XP
	          follow it. With this gear every block there breaks in one hit.
	  TOUGH   the same in rock that takes eight swings of the plain build a
	          block (pushing deeper than your gear is comfortable with),
	          counted as damage landed a second: a few blocks break in a run,
	          and a count that small is noise
	  SINGLE  damage a second landed on ONE block too tough to break: the
	          stubborn block an Earthquake build is for
	plus the swings a second, and prints one RES row each.

	THE BUILDS ARE INPUTS, not tunables: representative gear at each stage as
	the game has it on 2026-10-19 (charms, skins and pet variants belong to
	other systems). They are PROPOSED representatives -- the owner may know
	better what a typical player holds -- and the report lists them.
]]
local Roster = require("MinePetRoster")
local SetPets = require("MineSetPets")

local BAL = {}

BAL.STAGES = {
	--[[
		EARLY: the Special slot has just opened (player level 25). Greyvein
		Quarry at layer 2500 with the weakest tool that passes the gate there
		(ore tier 14), level 15; a Special at II (tier 1). Normal pets from the
		first two zone pots and the first two sets. A B skin (x1.9 power), the
		Sod Charm (+110% Mine Speed); proc charms Canopy (+55% Omni Blast) and
		Chainlink (+60% Zap).
	]]
	{ id = "early", zone = "sunscar", layer = 2500, tier = 14, level = 15, special = 2,
		variant = "Normal", zones = 2, sets = 2,
		skinBase = 1.9, skin = { swingRate = 0.2 }, procSkin = { chance = 0.35, procPower = 0 },
		charm = { mineSpeed = 1.10 },
		procCharm = { blast = { blastChance = 0.55 }, zap = { zap = 0.60 } } },
	--[[
		MID: Bloodmoon Hollow at layer 2500, ore tier 38 at level 20; a Special
		at IV (tier 2). Golden pets from the first five zones and eight sets.
		An S skin (x3), the Tideglass Charm (+200% Mine Speed, +40% Swing Rate);
		proc charms the Abyss Latch (+55% Omni Blast) and Chainlink.
	]]
	{ id = "mid", zone = "bloodmoon", layer = 2500, tier = 38, level = 20, special = 4,
		variant = "Golden", zones = 5, sets = 8,
		skinBase = 3.0, skin = { swingRate = 0.3 }, procSkin = { chance = 0.40, procPower = 0.8 },
		charm = { mineSpeed = 2.0, swingRate = 0.4 },
		procCharm = { blast = { blastChance = 0.55, scrap = 0.9 }, zap = { zap = 0.60 } } },
	--[[
		LATE: Primordium Heart at layer 4500, ore tier 82 at level 30; a Special
		at V (tier 3). Rainbow pets from every zone and set. An SSS skin (x5.5),
		the Gatebreaker Charm (+300% Mine Speed, +40% Swing Rate); proc charms
		the Galaxy Core (+860% Mine Speed, +260% Omni Blast: the best charm in
		the game) and Chainlink.
	]]
	{ id = "late", zone = "primordium", layer = 4500, tier = 82, level = 30, special = 5,
		variant = "Rainbow", zones = 10, sets = 19,
		skinBase = 5.5, skin = { swingRate = 0.4 }, procSkin = { chance = 0.45, procPower = 1.4 },
		charm = { mineSpeed = 3.0, swingRate = 0.4 },
		procCharm = { blast = { mineSpeed = 8.6, blastChance = 2.6 }, zap = { zap = 0.60 } } },
}
BAL.FAMILIES = { "pickaxe", "hammer", "drill", "jackhammer" }
BAL.SPECIALS = { "none", "zap", "blast", "tide", "shatter", "quake", "spellbook" }
--[[
	plain  Equip Best for no ability (plain stats), the stage's power charm
	       and skin: the enchant on its own
	charm  the plain pets, with the family's proc charm instead (Blast and Zap
	       have them)
	pets   Equip Best for this Special (its family's pets), the power charm
	stack  those pets, the family's proc charm (else the power charm) and a
	       skin carrying the family's chance and proc power: everything at once
]]
BAL.BUILDS = { "plain", "charm", "pets", "stack" }
BAL.FAMILY_OF = { zap = "zap", blast = "blast", tide = "tide", shatter = "shatter", quake = "quake", spellbook = "spell" }
BAL.SECONDS = 25
-- Streaks and the quake bank ramp up; a real dig is sustained, so each run
-- digs this long before it starts counting.
BAL.WARMUP = 10
-- The Damage-slot runs stop for this long every so often, as a player does
-- (walking to the next spot, a menu): the speed streaks lapse and ramp again.
BAL.PAUSE_EVERY = 15
BAL.PAUSE_FOR = 3
BAL.TOUGH_SWINGS = 8

local function zoneDef(id)
	for i, z in ipairs(C.ZONES) do
		if z.id == id then return z, i end
	end
end

-- Every regular pet a player could hold by this stage, at the stage's variant.
local function pool(stage)
	local zoneIx = {}
	for i, z in ipairs(C.ZONES) do zoneIx[z.id] = i end
	local setIx = {}
	for i, s in ipairs(SetPets.SETS or {}) do setIx[s.KEY] = s.INDEX or i end
	local out = {}
	for _, pet in ipairs(Roster.PETS) do
		local ok = false
		if not pet.holiday then
			if pet.zone and zoneIx[pet.zone] and zoneIx[pet.zone] <= stage.zones then ok = true end
			if pet.set and setIx[pet.set] and setIx[pet.set] <= stage.sets then ok = true end
		end
		if ok then
			table.insert(out, { id = pet.name, name = pet.name, rarityId = pet.tier, variant = stage.variant })
		end
	end
	return out
end

-- Equip Best's three for a family (nil = plain stats), by the server's own scorer.
local teamCache = {}
local function team(stage, family)
	local key = stage.id .. "|" .. tostring(family)
	if teamCache[key] then return teamCache[key] end
	stage._pool = stage._pool or pool(stage)
	stage._shares = stage._shares or {}
	local scored = {}
	for _, card in ipairs(stage._pool) do
		local sh = stage._shares[card.id]
		if not sh then
			sh = Dig.petShares(card)
			stage._shares[card.id] = sh
		end
		table.insert(scored, { card = card, pw = Dig.petWorth(sh, family) })
	end
	table.sort(scored, function(a, b)
		if a.pw ~= b.pw then return a.pw > b.pw end
		return a.card.id < b.card.id
	end)
	local t = { scored[1].card, scored[2].card, scored[3].card }
	teamCache[key] = t
	return t
end

local function profile(stage, fam, specialId, damageId)
	local p = { level = 200, xp = 0, zoneId = stage.zone, maxUnlockedZone = 10, enchantBooks = {},
		oreToolEquipped = "t1",
		oreTools = { { uid = "t1", familyId = fam, tier = stage.tier, level = stage.level, enchants = {} } } }
	if specialId ~= "none" then
		p.oreTools[1].enchants.special = { id = specialId, level = stage.special }
	end
	if damageId and damageId ~= "none" then
		p.oreTools[1].enchants.damage = { id = damageId, level = stage.special }
	end
	profiles[1] = p
	return p
end

-- Whether this build differs from "plain" for this Special (no duplicates).
function BAL.applies(specialId, buildId)
	if specialId == "none" then return buildId == "plain" end
	if buildId == "charm" then
		local f = BAL.FAMILY_OF[specialId]
		return BAL.STAGES[1].procCharm[f] ~= nil
	end
	return true
end

-- The boosts and the tool row a build swings with.
function BAL.build(stage, fam, specialId, buildId, damageId)
	local p = profile(stage, fam, specialId, damageId)
	local family = BAL.FAMILY_OF[specialId]
	local withPets = buildId == "pets" or buildId == "stack"
	local pets = team(stage, withPets and family or nil)
	local skin = table.clone(stage.skin)
	local charm = stage.charm
	if (buildId == "charm" or buildId == "stack") and family then
		charm = stage.procCharm[family] or charm
	end
	if buildId == "stack" and family then
		local proc = E.PROCS[family]
		if proc then
			skin[proc.chance] = (skin[proc.chance] or 0) + stage.procSkin.chance
		end
		skin.procPower = (skin.procPower or 0) + stage.procSkin.procPower
	end
	local b = SIM.boosts(p, { pets = pets, skin = skin, charm = charm })
	local held = p.oreTools[1]
	local tool = OreTools.frameStats(fam, held.tier)
	tool.power = OreTools.hitPower(held, stage.skinBase)
	tool.family = fam
	tool.oreTier = held.tier
	tool.oreId = C.ORES[held.tier].id
	return p, b, tool, pets
end

--[[
	THE SAME BUILD WITH EVERY ABILITY OFF: each family's chance, damage and
	extra at 0 and no Spellbook. An ability's worth to a build is the build
	over this, so the pets', charm's and skin's plain stats (swing rate, Mine
	Speed) cancel and what is left is what the ability stack adds.
]]
function BAL.bare(b)
	local out = table.clone(b)
	for _, proc in pairs(E.PROCS) do
		out[proc.chance] = 0
		if proc.damage ~= "procPower" then out[proc.damage] = 0 end
		for _, x in ipairs(proc.extra or {}) do out[x] = 0 end
	end
	out.spellEvery = nil
	return out
end

local plr = { UserId = 1, Name = "balance" }
WORLD.players[1] = plr

local function swingsPerSecond(p, b, tool)
	return (tonumber(tool.rate) or 2.5) / math.max(0.05, tonumber(b.swingSec) or 1) * EnchSvc.swingSpeed(p)
end

-- What one swing of this build lands before any enchant: the tough rock's yardstick.
local function swingDamage(b, tool)
	return (tool.power or 1) * (b.mineSpeed or 1) * (b.dirtBreak or 1)
end

-- A pit GRID wide of `hp` rock, generated a few layers ahead like ensureZone.
local GRID = 21
local function digArea(stage, fam, specialId, buildId, hp, bare, damageId, pauses)
	local p, b, tool = BAL.build(stage, fam, specialId, buildId, damageId)
	if bare then b = BAL.bare(b) end
	WORLD.reset()
	SIM.t = 1000
	local zone = { id = stage.zone }
	local built = stage.layer - 1
	local function ensure(toLayer)
		while built < toLayer do
			built += 1
			for x = 1, GRID do for zz = 1, GRID do WORLD.block(stage.zone, x, built, zz, hp) end end
		end
	end
	ensure(stage.layer + 8)
	local cur = { y = stage.layer, x = 1, z = 1 }
	local function nextTarget()
		local cells = WORLD.cells[stage.zone]
		while true do
			local b2 = cells[keyOf(stage.zone, cur.x, cur.y, cur.z)]
			if b2 then return b2 end
			cur.z += 1
			if cur.z > GRID then cur.z = 1 cur.x += 1 end
			if cur.x > GRID then cur.x = 1 cur.y += 1 ensure(cur.y + 8) end
		end
	end
	local warm = SIM.t + BAL.WARMUP
	while SIM.t < warm do
		SIM.swing(plr, p, b, tool, zone, nextTarget())
		SIM.advance(1 / swingsPerSecond(p, b, tool))
	end
	SIM.stats = { hits = 0, dmg = 0, broken = 0 }
	local t0 = SIM.t
	local swings = 0
	local nextPause = t0 + BAL.PAUSE_EVERY
	while SIM.t - t0 < BAL.SECONDS do
		if pauses and SIM.t >= nextPause then
			-- Walking to the next spot: no swings, and every streak lapses.
			SIM.advance(BAL.PAUSE_FOR)
			nextPause = SIM.t + BAL.PAUSE_EVERY
		end
		local part = nextTarget()
		SIM.swing(plr, p, b, tool, zone, part)
		swings += 1
		SIM.advance(1 / swingsPerSecond(p, b, tool))
	end
	return SIM.stats.broken / (SIM.t - t0), swings / (SIM.t - t0), b, SIM.stats.dmg / (SIM.t - t0)
end

-- One block too tough to break, inside rock just as tough.
local function digSingle(stage, fam, specialId, buildId, bare)
	local p, b, tool = BAL.build(stage, fam, specialId, buildId)
	if bare then b = BAL.bare(b) end
	WORLD.reset()
	SIM.t = 5000
	local zone = { id = stage.zone }
	local y0 = stage.layer
	for x = 1, 7 do for y = y0, y0 + 6 do for zz = 1, 7 do WORLD.block(stage.zone, x, y, zz, 1e300) end end end
	local target = WORLD.cells[stage.zone][keyOf(stage.zone, 4, y0 + 3, 4)]
	local onTarget = 0
	local warm = SIM.t + BAL.WARMUP
	while SIM.t < warm do
		SIM.swing(plr, p, b, tool, zone, target)
		SIM.advance(1 / swingsPerSecond(p, b, tool))
	end
	SIM.onHit = function(part, landed) if part == target then onTarget += landed end end
	local t0 = SIM.t
	while SIM.t - t0 < BAL.SECONDS do
		SIM.swing(plr, p, b, tool, zone, target)
		SIM.advance(1 / swingsPerSecond(p, b, tool))
	end
	SIM.onHit = nil
	return onTarget / (SIM.t - t0)
end

for _, stage in ipairs(BAL.STAGES) do
	local z = zoneDef(stage.zone)
	local hp = C.blockHp("dirt", z, stage.layer)
	local lo, hi = C.oreYieldFor(stage.tier)
	print(string.format("STAGE %s %s %d %d %d %.4g %.4g %.4f", stage.id, stage.zone, stage.layer, stage.tier, stage.level,
		hp, (tonumber(C.ORE_CHANCE) or 0.005) * (lo + hi) / 2, 0))
	for _, fam in ipairs(BAL.FAMILIES) do
		-- The tough rock: eight swings of this family's plain build, no enchant.
		local _, b0, tool0 = BAL.build(stage, fam, "none", "plain")
		local toughHp = BAL.TOUGH_SWINGS * swingDamage(b0, tool0)
		for _, sp in ipairs(BAL.SPECIALS) do
			for _, build in ipairs(BAL.BUILDS) do
				if BAL.applies(sp, build) then
					local area, sps, b = digArea(stage, fam, sp, build, hp)
					local _, _, _, tough = digArea(stage, fam, sp, build, toughHp)
					local single = digSingle(stage, fam, sp, build)
					local area0 = digArea(stage, fam, sp, build, hp, true)
					local _, _, _, tough0 = digArea(stage, fam, sp, build, toughHp, true)
					local single0 = digSingle(stage, fam, sp, build, true)
					local fam2 = BAL.FAMILY_OF[sp]
					local chance = fam2 and E.PROCS[fam2] and b[E.PROCS[fam2].chance] or 0
					print(string.format("RES %s %s %s %s %.4f %.4f %.6g %.3f %.4f %.3f %.4f %.4f %.6g", stage.id, fam, sp, build,
						area, tough, single, sps, chance, tonumber(b.procPower) or 0, area0, tough0, single0))
				end
			end
		end
	end
	local names = {}
	for _, fam in ipairs({ "zap", "blast", "tide", "shatter", "quake" }) do
		local t = team(stage, fam)
		table.insert(names, fam .. "=" .. t[1].name .. "+" .. t[2].name .. "+" .. t[3].name)
	end
	local plain = team(stage, nil)
	table.insert(names, "plain=" .. plain[1].name .. "+" .. plain[2].name .. "+" .. plain[3].name)
	print("TEAMS " .. stage.id .. " " .. string.gsub(table.concat(names, " "), " ", " "))
end
--[[
	THE DAMAGE SLOT, beside the abilities: the two Halloween Damage enchants
	against the ones they compete with, on the plain build with no Special, at
	the stage's Special level. AREA on the stage's rock (one hit a block: speed
	is what counts), TOUGH on eight-swing rock (damage is), both with a short
	pause every PAUSE_EVERY seconds so the streaks have to build again. Grave
	Digger reads the stage's depth: layer 2500 is halfway down a mine, 4500
	near the floor.
]]
BAL.DAMAGE = { "none", "power", "combo", "overclock", "sugar_rush", "grave_digger" }
for _, stage in ipairs(BAL.STAGES) do
	local z = zoneDef(stage.zone)
	local hp = C.blockHp("dirt", z, stage.layer)
	for _, fam in ipairs({ "pickaxe", "drill", "jackhammer" }) do
		local _, b0, tool0 = BAL.build(stage, fam, "none", "plain")
		local toughHp = BAL.TOUGH_SWINGS * swingDamage(b0, tool0)
		for _, d in ipairs(BAL.DAMAGE) do
			local area = digArea(stage, fam, "none", "plain", hp, true, d, true)
			local _, _, _, tough = digArea(stage, fam, "none", "plain", toughHp, true, d, true)
			print(string.format("DMG %s %s %s %.4f %.4f", stage.id, fam, d, area, tough))
		end
	end
end

--[[
	FLASHLIGHT, at I and V: how often it lights an ore and how much of the time
	one is glowing, for the stage's plain digging speed. After each light it
	rests its cooldown, then each broken block rolls its chance.
]]
for _, stage in ipairs(BAL.STAGES) do
	local z = zoneDef(stage.zone)
	local area = digArea(stage, "pickaxe", "none", "plain", C.blockHp("dirt", z, stage.layer), true)
	for _, lvl in ipairs({ 1, 5 }) do
		local f = E.flashlightAt(lvl)
		local period = f.cooldown + 1 / math.max(1e-9, area * f.chance)
		print(string.format("FLASH %s %d %.3f %.3f %d %d", stage.id, lvl, 60 / period, f.glow / period, f.radius, f.cooldown))
	end
end
print("DONE")
