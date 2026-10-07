// Behavioural check for the generated ore charms.
//
// Unlike luau-balance.js (syntax) and syntax.sh (parse), this one RUNS the real
// MineCharms generator and asserts what it produced. That matters because the
// alternative -- re-deriving the expected roster in another language -- only
// proves the other language agrees with my intent, not that the Luau does.
//
// It executes outside Studio, so it writes a self-contained Luau file: a tiny
// Roblox stub (Color3, Enum, Random), a MineConfig stub carrying the REAL 82-row
// roster read out of MineConfig.luau, and MineCharms.luau itself inlined
// verbatim. Nothing about the charm logic is reimplemented here.
//
// Needs the luau binary that tools/verify/syntax.sh fetches into .luau-bin/.
// Run that first, or this exits 0 with a note rather than failing the build.
//
//   node tools/verify/charms.js
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = path.resolve(__dirname, "../..");
const SHARED = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared");
const Luau = require("./_luau");
const LUAU = Luau.LUAU;

if (!Luau.ready) {
  // Names the platform and the fix, rather than "skipping" with no reason.
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(0);
}

const cfg = fs.readFileSync(path.join(SHARED, "MineConfig.luau"), "utf8");
const charms = fs.readFileSync(path.join(SHARED, "MineCharms.luau"), "utf8");

// The real roster, and the real band cutoffs it is graded by.
const rows = [...cfg.matchAll(/\{ id = "(\w+)", name = "([^"]+)", tier = (\d+),/g)]
  .map((m) => ({ id: m[1], name: m[2], tier: Number(m[3]) }));
const cuts = [...cfg.matchAll(/\{ upTo = (\d+), lo = \d+, hi = \d+ \}/g)].map((m) => Number(m[1]));
const BANDS = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic"];

if (rows.length === 0 || cuts.length !== BANDS.length) {
  console.error(`FAIL could not read the roster: ${rows.length} ores, ${cuts.length} band cutoffs`);
  process.exit(1);
}
const bandFor = (tier) => {
  for (let i = 0; i < cuts.length; i++) if (tier <= cuts[i]) return [BANDS[i], i + 1];
  return [BANDS[BANDS.length - 1], BANDS.length];
};

const oreRows = rows
  .map((o) => {
    const [band, bandIndex] = bandFor(o.tier);
    return `\t{ id = "${o.id}", name = "${o.name}", tier = ${o.tier}, band = "${band}", bandIndex = ${bandIndex}, homeHp = 20 },`;
  })
  .join("\n");

const EXPECTED_ORES = rows.length;
const VARIANTS = 2;
const EXPECTED_CHARMS = EXPECTED_ORES * VARIANTS;
// (shape, stat, condition) signatures actually used across the 164 charms, out
// of 96 possible (8 unconditional per shape x 4, plus 8x4 for each of the two
// conditional shapes). The divisor terms in the generator's indexing are what
// get it this high; drop either and it falls to 48.
const EXPECTED_SIGNATURES = 86;

const harness = `
Color3 = { fromRGB = function() return {} end, fromHSV = function() return {} end }
Enum = setmetatable({}, { __index = function() return setmetatable({}, { __index = function(_, k) return { Name = k } end }) end })
Random = { new = function() return { NextNumber = function() return 0.5 end, NextInteger = function(_, a) return a end } end }

local STUB_CONFIG = {
	ORE_COUNT = ${EXPECTED_ORES},
	ORE_BAND_ORDER = { ${BANDS.map((b) => JSON.stringify(b)).join(", ")} },
	ZONES = { {id="z1"},{id="z2"},{id="z3"},{id="z4"},{id="z5"},{id="z6"},{id="z7"},{id="z8"},{id="z9"},{id="z10"},{id="z11"} },
	ORES = {
${oreRows}
	},
}
function STUB_CONFIG.zoneIndex(id)
	for i, z in ipairs(STUB_CONFIG.ZONES) do if z.id == id then return i end end
	return 1
end

-- The graded charms read MineTemper's rarity ladder rather than inventing a
-- second one, so the stub carries the real weights: rollChestCharm draws against
-- them, and a stub with flat weights would make the draw test meaningless.
local STUB_TEMPER = {
	GRADE_ORDER = { "F", "D", "C", "B", "A", "S", "SS", "SSS" },
	RARITY_WEIGHTS = { F = 5000, D = 2763, C = 1250, B = 675, A = 250, S = 50, SS = 10, SSS = 2 },
	RARITY_MULT = { F = 0.45, D = 0.70, C = 1.05, B = 1.55, A = 2.30, S = 3.40, SS = 5.00, SSS = 7.50 },
}
STUB_TEMPER.RARITY_ORDER = STUB_TEMPER.GRADE_ORDER

local MODULES = { MineConfig = STUB_CONFIG, MineTemper = STUB_TEMPER }
local SHARED = { WaitForChild = function(_, n) return { Name = n } end }
script = { Name = "MineCharms", Parent = SHARED }
function require(t)
	local n = type(t) == "table" and t.Name or tostring(t)
	local m = MODULES[n]
	if m == nil then error("no stub for " .. n) end
	return m
end

local MineCharms = (function()
${charms}
end)()

local fail = 0
local function check(ok, msg)
	if not ok then fail += 1 print("  FAIL  " .. msg) else print("  ok    " .. msg) end
end
-- A fresh boost table shaped like the real one.
local function freshB()
	return { mineSpeed = 1, dirtBreak = 1, coinBonus = 1, gemFind = 1, luck = 1,
	         chestLuck = 1, backpack = 1, swingSec = 1 }
end
local function changed(b)
	for _, v in pairs(b) do if v ~= 1 then return true end end
	return false
end

local ore = {}
for _, d in ipairs(MineCharms.LIST) do
	if d.source == "ore" then table.insert(ore, d) end
end

check(#ore == ${EXPECTED_CHARMS},
	("${VARIANTS} charms per ore: ${EXPECTED_CHARMS} (got %d)"):format(#ore))

-- Every ore has both variants, reachable by the accessors.
local missing, pairFail, nameClash = 0, 0, 0
local seenName = {}
for _, o in ipairs(STUB_CONFIG.ORES) do
	local list = MineCharms.oreCharms(o.id)
	local a, b = list[1], list[2]
	if not a or not b then
		missing += 1
	else
		-- The pair guarantee: different SHAPE and different primary stat, so
		-- neither variant is an upgrade of the other.
		local function primaryOf(d)
			local best
			for stat, amt in pairs(d.stats) do
				if amt > 0 and (best == nil or amt > d.stats[best]) then best = stat end
			end
			return best
		end
		if a.shape == b.shape or primaryOf(a) == primaryOf(b) then
			pairFail += 1
		end
	end
end
check(missing == 0, ("every ore has both variants via oreCharms (missing %d)"):format(missing))
check(pairFail == 0,
	("an ore's two variants always differ in shape AND stat (%d collide)"):format(pairFail))

for _, d in ipairs(ore) do
	if seenName[d.name] then nameClash += 1 end
	seenName[d.name] = true
end
check(nameClash == 0, ("every charm name is distinct (%d clashes)"):format(nameClash))

-- Variant 1 keeps the unsuffixed id that already exists in saves.
local legacyOk = true
for _, o in ipairs(STUB_CONFIG.ORES) do
	if MineCharms.oreCharmId(o.id, 1) ~= (o.id .. "_charm") then legacyOk = false end
end
check(legacyOk, "variant 1 keeps the legacy <ore>_charm id, so old saves resolve")
check(MineCharms.oreCharm(STUB_CONFIG.ORES[1].id) ~= nil,
	"oreCharm with no variant still returns one (back-compatible)")

-- rollOreCharm must be able to return either variant, never nil.
do
	local first = STUB_CONFIG.ORES[1].id
	local got = {}
	for seed = 1, 40 do
		local fakeRng = { NextInteger = function(_, a, b) return a + (seed % (b - a + 1)) end }
		local pick = MineCharms.rollOreCharm(first, fakeRng)
		if pick then got[pick.variant] = true end
	end
	check(got[1] and got[2], "rollOreCharm can return either variant")
	check(MineCharms.rollOreCharm("no_such_ore") == nil, "rollOreCharm is nil for an unknown ore")
end

local nShapes = 0
local seenShape = {}
for _, d in ipairs(ore) do
	if d.shape and not seenShape[d.shape] then seenShape[d.shape] = true nShapes += 1 end
end
check(nShapes == #MineCharms.SHAPES,
	("every shape is used: %d of %d"):format(nShapes, #MineCharms.SHAPES))

local sigs, nSig = {}, 0
for _, d in ipairs(ore) do
	local primary
	for stat, amt in pairs(d.stats) do
		if amt > 0 and (primary == nil or amt > d.stats[primary]) then primary = stat end
	end
	local key = tostring(d.shape) .. "|" .. tostring(primary) .. "|" .. tostring(d.condition)
	if not sigs[key] then sigs[key] = true nSig += 1 end
end
check(nSig == ${EXPECTED_SIGNATURES},
	("${EXPECTED_SIGNATURES} distinct (shape, stat, condition) signatures (got %d)"):format(nSig))

-- A multiplicative penalty at or past -100% erases a stat instead of costing one.
local worst = 0
for _, d in ipairs(ore) do
	for _, amt in pairs(d.stats) do if amt < worst then worst = amt end end
end
check(worst > -1.0, ("worst penalty %.2f is strictly above -1.00"):format(worst))

local banned = false
for _, d in ipairs(ore) do
	for stat in pairs(d.stats) do
		if stat == "echo" or stat == "zap" or stat == "blastRadius" then banned = true end
	end
end
check(not banned, "no echo / zap / blastRadius in any generated charm")

-- Conditional: pays nothing unmet, something met.
local cond
for _, d in ipairs(ore) do if d.condition == "lean" then cond = d break end end
check(cond ~= nil, "a 'lean' conditional charm exists to test")
if cond then
	local off, on = freshB(), freshB()
	MineCharms.applyEquipped(off, cond.id, { equipped = { 1, 2, 3 } })
	MineCharms.applyEquipped(on, cond.id, { equipped = { 1 } })
	check(not changed(off), "conditional charm pays nothing while its condition is unmet")
	check(changed(on), "conditional charm pays once its condition is met")
end

-- Ramp: cold is nothing, scales with stacks, expires, cannot be faked forward.
local ramp
for _, d in ipairs(ore) do if d.shape == "ramp" then ramp = d break end end
check(ramp ~= nil, "a ramp charm exists to test")
if ramp then
	local now = os.time()
	local cold = freshB()
	MineCharms.applyEquipped(cold, ramp.id, {})
	check(not changed(cold), "ramp pays nothing with no stacks")

	local half, full = freshB(), freshB()
	MineCharms.applyEquipped(half, ramp.id, { charmRamp = { n = MineCharms.RAMP_MAX // 2, at = now } })
	MineCharms.applyEquipped(full, ramp.id, { charmRamp = { n = MineCharms.RAMP_MAX, at = now } })
	local h, f
	for _, v in pairs(half) do if v ~= 1 then h = v end end
	for _, v in pairs(full) do if v ~= 1 then f = v end end
	check(h ~= nil and f ~= nil and f > h, "ramp pays more at full stacks than at half")

	local stale = freshB()
	MineCharms.applyEquipped(stale, ramp.id,
		{ charmRamp = { n = MineCharms.RAMP_MAX, at = now - (MineCharms.RAMP_IDLE_SEC + 5) } })
	check(not changed(stale), "an idled-out ramp reads as cold")

	local ahead = freshB()
	MineCharms.applyEquipped(ahead, ramp.id, { charmRamp = { n = MineCharms.RAMP_MAX, at = now + 9999 } })
	check(not changed(ahead), "a future ramp timestamp reads as cold, not infinitely fresh")

	local prof = {}
	for _ = 1, MineCharms.RAMP_MAX + 20 do MineCharms.bumpRamp(prof) end
	check(prof.charmRamp.n == MineCharms.RAMP_MAX, "bumpRamp climbs and caps at RAMP_MAX")
end

-- The first charm is never a roll, and ownership is read honestly.
check(MineCharms.caseCharmShare(false, 0.25) == 1, "first charm guaranteed: share is 1 while you own none")
check(MineCharms.caseCharmShare(true, 0.25) == 0.25, "share returns to the configured one once you own any")
check(MineCharms.ownsAnyCharm({ charms = {} }) == false, "an empty charm table is not ownership")
check(MineCharms.ownsAnyCharm({ charms = { [ore[1].id] = 0 } }) == false, "a tally left at zero is not ownership")
check(MineCharms.ownsAnyCharm({ charms = { [ore[1].id] = 1 } }) == true, "a tally of one is ownership")
check(MineCharms.ownsAnyCharm({ charms = { [ore[1].id] = true } }) == true, "a legacy true is ownership")

print("")
--[[
	MERGING: three copies into one a tier deeper.

	The claim the implementation makes is that a merge is a TRADE rather than an
	upgrade -- the charm one tier up has a different shape, so you are buying
	depth and variety rather than a bigger number (TODO 0.13). That is an
	arithmetic consequence of how charms are indexed, not a hope, so it is
	checked: k = (tier-1) * variants + (variant-1), shape = k % #SHAPES, and a
	merge moves k by exactly "variants". If that ever stops changing the shape,
	merging silently becomes a pure power ladder and this fails.
]]
--[[
	MERGING COSTS GEMS, NOT CHARMS. Owner, 2026-10-04: "rather than merging it
	should cost gems."

	This used to assert MERGE_COST >= 2 -- that eating copies was "a real
	cost". That WAS the design, and it is exactly the design the owner threw
	out: if three of a thing make one of a thing, each one is worth a third of
	a thing, which is the "everything feels worthless" problem in its purest
	form. One charm in, one charm out, and gems pay for the step.
]]
check(math.floor(tonumber(MineCharms.MERGE_COST) or 0) == 1,
	("merging consumes exactly one charm (%s)"):format(tostring(MineCharms.MERGE_COST)))
check(type(MineCharms.mergeGemCost) == "function", "merging has a gem price")
if type(MineCharms.mergeGemCost) == "function" then
	local lo, hi = MineCharms.mergeGemCost(1), MineCharms.mergeGemCost(60)
	check(lo > 0, ("a tier-1 merge costs %d gems"):format(lo))
	check(hi > lo, ("...and a deep one costs more (%d at tier 60)"):format(hi))
	local rising = true
	for t = 2, 82 do
		if MineCharms.mergeGemCost(t) < MineCharms.mergeGemCost(t - 1) then rising = false end
	end
	check(rising, "the gem price never steps backwards with tier")
end

local topTier, merged, sameShape, wrongVariant, wrongTier = 0, 0, 0, 0, 0
for _, o in ipairs(STUB_CONFIG.ORES) do
	topTier = math.max(topTier, o.tier)
end
for _, o in ipairs(STUB_CONFIG.ORES) do
	for v = 1, ${VARIANTS} do
		local id = MineCharms.oreCharmId(o.id, v)
		local srcDef = MineCharms.byId(id)
		local tgtId, tgtDef, why = MineCharms.mergeTarget(id)
		if o.tier >= topTier then
			if tgtId ~= nil then
				wrongTier += 1
				print("          the deepest charm " .. id .. " still offers a merge")
			end
			if not why then
				wrongTier += 1
				print("          " .. id .. " refuses without saying why")
			end
		elseif not tgtId then
			wrongTier += 1
			print("          " .. id .. " cannot merge: " .. tostring(why))
		else
			merged += 1
			if tgtDef.variant ~= v then wrongVariant += 1 end
			if tgtDef.tier ~= o.tier + 1 then wrongTier += 1 end
			-- The property that makes it a trade.
			local function shapeOf(d)
				return d and d.shape or (d and d.shapeId) or nil
			end
			local a, b = shapeOf(srcDef), shapeOf(tgtDef)
			if a ~= nil and a == b then
				sameShape += 1
			end
		end
	end
end
check(merged > 0, ("every ore charm below the top merges (%d of them)"):format(merged))
check(wrongTier == 0, "a merge goes exactly one tier up, and the top tier refuses with a reason")
check(wrongVariant == 0, "a merge keeps its variant")
check(sameShape == 0,
	("a merge always changes the SHAPE, so it is a trade not an upgrade (%d kept it)"):format(sameShape))

-- Legacy charms must not feed the ladder: §6.0 still has an open owner call on
-- whether they are retired at all, and merging them would decide it quietly.
local legacyChecked, legacyMergeable = 0, 0
for _, d in ipairs(MineCharms.LIST) do
	if d.source ~= "ore" then
		legacyChecked += 1
		if (MineCharms.mergeTarget(d.id)) ~= nil then legacyMergeable += 1 end
	end
end
check(legacyChecked > 0 and legacyMergeable == 0,
	("the %d legacy charms do not merge"):format(legacyChecked))

-- A chain has to terminate, or a client walking it to show the ladder hangs.
local walk, steps = MineCharms.oreCharmId(STUB_CONFIG.ORES[1].id, 1), 0
while walk and steps < 500 do
	walk = (MineCharms.mergeTarget(walk))
	steps += 1
end
check(steps < 500 and steps == topTier,
	("the merge chain terminates, in %d steps for %d tiers"):format(steps, topTier))

--[[
	THE 36 GRADED CHARMS (owner, 2026-10-07).

	"make 36 charms. make them all unique, and each come in their own rarity. they
	can be found in chests (0.5%) or bought with tokens."

	Each clause of that is a check below. The one that matters most is the LAST:
	a graded charm must never also be a zone grant. ZONE_BAND indexes on
	zoneId|band, so a row that carried both would quietly become a free zone drop
	as well as a 0.5% chest prize, and nothing else here would notice.
]]
print("")
do
	local graded = MineCharms.GRADED or {}
	check(#graded == 36, ("there are 36 graded charms (%d)"):format(#graded))

	local byRarity, ids, names, dupId, dupName = {}, {}, {}, 0, 0
	for _, def in ipairs(graded) do
		byRarity[def.rarity] = (byRarity[def.rarity] or 0) + 1
		if ids[def.id] then dupId += 1 end
		if names[def.name] then dupName += 1 end
		ids[def.id], names[def.name] = true, true
	end
	check(dupId == 0 and dupName == 0,
		("every graded charm is unique (%d id clashes, %d name clashes)"):format(dupId, dupName))

	-- "each come in their own rarity": every grade on the ladder is represented,
	-- and the spread thins toward SSS rather than piling on one grade.
	local missing, order = {}, STUB_TEMPER.GRADE_ORDER
	for _, g in ipairs(order) do
		if not byRarity[g] then table.insert(missing, g) end
	end
	check(#missing == 0, ("every rarity F..SSS has at least one charm (missing %s)")
		:format(#missing > 0 and table.concat(missing, ",") or "none"))

	local monotone = true
	for i = 2, #order do
		if (byRarity[order[i]] or 0) > (byRarity[order[i - 1]] or 0) then monotone = false end
	end
	local shape = {}
	for _, g in ipairs(order) do table.insert(shape, g .. ":" .. tostring(byRarity[g] or 0)) end
	check(monotone, ("the ladder never widens as it gets rarer (%s)"):format(table.concat(shape, " ")))

	-- Magnitude has to follow the grade, or the rarity is decoration.
	local worstPair = nil
	local function biggest(def)
		local m = 0
		for _, v in pairs(def.stats or {}) do m = math.max(m, v) end
		return m
	end
	local bestOf = {}
	for _, def in ipairs(graded) do
		bestOf[def.rarity] = math.max(bestOf[def.rarity] or 0, biggest(def))
	end
	for i = 2, #order do
		local lo, hi = bestOf[order[i - 1]], bestOf[order[i]]
		if lo and hi and hi <= lo then worstPair = order[i - 1] .. ">=" .. order[i] end
	end
	check(worstPair == nil,
		("a rarer charm always peaks higher (%s)"):format(worstPair or "monotone F..SSS"))

	-- Every one must be buyable, and the price must climb with the grade.
	local noPrice, priceBad = 0, nil
	for _, def in ipairs(graded) do
		if not MineCharms.charmTokenPrice(def) then noPrice += 1 end
	end
	check(noPrice == 0, ("every graded charm has a token price (%d without)"):format(noPrice))
	for i = 2, #order do
		local a = MineCharms.CHARM_TOKEN_PRICE[order[i - 1]]
		local b = MineCharms.CHARM_TOKEN_PRICE[order[i]]
		if a and b and b <= a then priceBad = order[i - 1] .. ">=" .. order[i] end
	end
	check(priceBad == nil, ("token price climbs with rarity (%s)"):format(priceBad or "monotone"))

	check(math.abs((MineCharms.CHARM_CHEST_CHANCE or 0) - 0.005) < 1e-9,
		("the chest chance is 0.5%% (%s)"):format(tostring(MineCharms.CHARM_CHEST_CHANCE)))

	-- The roll must be able to reach both ends, and must favour the common end.
	do
		local seen, lowN, highN = {}, 0, 0
		local seeded = { NextNumber = function(self) self.i = (self.i or 0) + 1; return ((self.i * 0.0007919) % 1) end }
		for _ = 1, 4000 do
			local d = MineCharms.rollChestCharm(seeded)
			if d then
				seen[d.rarity] = (seen[d.rarity] or 0) + 1
				if d.rarity == "F" or d.rarity == "D" then lowN += 1 end
				if d.rarity == "SS" or d.rarity == "SSS" then highN += 1 end
			end
		end
		check(lowN > highN * 10,
			("the chest roll lands on the common end far more often (%d low vs %d top)"):format(lowN, highN))
		check(MineCharms.rollChestCharm(nil) ~= nil, "rollChestCharm works without an rng")
	end

	-- The one that would be invisible: graded charms must not also be zone grants.
	local alsoZone = 0
	for _, def in ipairs(graded) do
		if def.zoneId or def.band then alsoZone += 1 end
	end
	check(alsoZone == 0,
		("no graded charm is also a zone grant (%d would be free as well as 0.5%%)"):format(alsoZone))

	-- The retired stat must not come back in on new content.
	local retired = 0
	for _, def in ipairs(graded) do
		if (def.stats or {}).backpack then retired += 1 end
	end
	check(retired == 0, ("no graded charm carries the retired backpack stat (%d do)"):format(retired))

	-- The drawn six lead the list and are the ones carrying art.
	local drawn = 0
	for i = 1, 6 do
		if graded[i] and graded[i].icon == i then drawn += 1 end
	end
	check(drawn == 6, ("the first six charms carry sheet icons 1-6 (%d do)"):format(drawn))
end

if fail == 0 then
	print(">>> charms: all assertions passed")
else
	print(">>> charms: " .. fail .. " assertion(s) FAILED")
	error("charm assertions failed", 0)
end
`;

const tmp = path.join(require("os").tmpdir(), `charms-check-${process.pid}.luau`);
fs.writeFileSync(tmp, harness);
try {
  const out = execFileSync(LUAU, [tmp], { encoding: "utf8" });
  process.stdout.write(out);
  process.exit(/FAILED/.test(out) ? 1 : 0);
} catch (e) {
  process.stdout.write((e.stdout || "") + (e.stderr || ""));
  process.exit(1);
} finally {
  fs.unlinkSync(tmp);
}
