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
const LUAU = path.join(ROOT, ".luau-bin/luau");

if (!fs.existsSync(LUAU)) {
  console.log("luau not present (.luau-bin/luau) — run tools/verify/syntax.sh first; skipping");
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
// 6 shapes x 8 stats, with the stat index stepped so the pair period is their
// product rather than their LCM. If either count changes, this changes with it.
const EXPECTED_FAMILIES = 48;

const harness = `
Color3 = { fromRGB = function() return {} end, fromHSV = function() return {} end }
Enum = setmetatable({}, { __index = function() return setmetatable({}, { __index = function(_, k) return { Name = k } end }) end })
Random = { new = function() return { NextNumber = function() return 0.5 end, NextInteger = function(_, a) return a end } end }

local STUB_CONFIG = {
	ORE_COUNT = ${EXPECTED_ORES},
	ORE_BAND_ORDER = { ${BANDS.map((b) => `"${b}"`).join(", ")} },
	ZONES = { {id="z1"},{id="z2"},{id="z3"},{id="z4"},{id="z5"},{id="z6"},{id="z7"},{id="z8"},{id="z9"},{id="z10"},{id="z11"} },
	ORES = {
${oreRows}
	},
}
function STUB_CONFIG.zoneIndex(id)
	for i, z in ipairs(STUB_CONFIG.ZONES) do if z.id == id then return i end end
	return 1
end

local MODULES = { MineConfig = STUB_CONFIG }
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

check(#ore == ${EXPECTED_ORES}, ("one charm per ore: ${EXPECTED_ORES} (got %d)"):format(#ore))

local missing = 0
for _, o in ipairs(STUB_CONFIG.ORES) do
	if not MineCharms.oreCharm(o.id) then missing += 1 end
end
check(missing == 0, ("every ore resolves through oreCharm (missing %d)"):format(missing))

local nShapes = 0
local seenShape = {}
for _, d in ipairs(ore) do
	if d.shape and not seenShape[d.shape] then seenShape[d.shape] = true nShapes += 1 end
end
check(nShapes == #MineCharms.SHAPES,
	("every shape is used: %d of %d"):format(nShapes, #MineCharms.SHAPES))

local fams, nFam = {}, 0
for _, d in ipairs(ore) do
	local primary
	for stat, amt in pairs(d.stats) do
		if amt > 0 and (primary == nil or amt > d.stats[primary]) then primary = stat end
	end
	local key = tostring(d.shape) .. "|" .. tostring(primary)
	if not fams[key] then fams[key] = true nFam += 1 end
end
check(nFam == ${EXPECTED_FAMILIES},
	("${EXPECTED_FAMILIES} distinct (shape, stat) families, so that many best-in-family charms (got %d)"):format(nFam))

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
