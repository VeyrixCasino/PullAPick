// Preconditions for the legacy ore-pack migration (Dig.bankOrePacks).
//
// The migration converts an unopened "<id>_ore_pack" into banked ore on load.
// It pays the yield band's MIDPOINT times the pack's stamped (capped) ore
// finder, and it refuses to convert unless the whole amount fits the pouch --
// because Dig.addOre spills what does not fit and spilled ore is destroyed.
//
// That makes two things load-bearing, and neither is obvious from the function:
//
//   1. No pack may be bigger than a TIER-1 pouch, or it can never be converted
//      and never opened by hand either -- a permanently stuck row.
//   2. The midpoint must land inside what opening could actually have paid, so
//      the migration is neither a nerf nor a payday.
//
// It runs the REAL MineOrePouch (so capacities are the shipping ones) against a
// MineConfig stub carrying the REAL roster and the REAL yield bands, read out of
// MineConfig.luau. MineConfig itself is not loaded here for the same reason
// charms.js does not load it: it is a cycle with MineBags/MineShopEconomy/
// MineDepth and reaches for enough Roblox surface that stubbing the engine
// becomes the test.
//
// Needs the luau binary that tools/verify/syntax.sh fetches into .luau-bin/.
//
//   node tools/verify/orepacks.js
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
const pouch = fs.readFileSync(path.join(SHARED, "MineOrePouch.luau"), "utf8");

const ores = [...cfg.matchAll(/\{ id = "(\w+)", name = "([^"]+)", tier = (\d+),/g)]
  .map((m) => ({ id: m[1], name: m[2], tier: Number(m[3]) }));
const bands = [...cfg.matchAll(/\{ upTo = (\d+), lo = (\d+), hi = (\d+) \}/g)]
  .map((m) => ({ upTo: Number(m[1]), lo: Number(m[2]), hi: Number(m[3]) }));
const findCap = cfg.match(/MineConfig\.ORE_PACK_FIND_CAP\s*=\s*([\d.]+)/);

if (ores.length === 0 || bands.length === 0) {
  console.error(`FAIL could not read MineConfig: ${ores.length} ores, ${bands.length} yield bands`);
  process.exit(1);
}
if (!findCap) {
  console.error("FAIL MineConfig.ORE_PACK_FIND_CAP is missing — MineServer reads it to cap a legacy pack's stamped ore finder");
  process.exit(1);
}

const harness = `
Color3 = { fromRGB = function() return {} end, fromHSV = function() return {} end }
Enum = setmetatable({}, { __index = function() return setmetatable({}, { __index = function(_, k) return { Name = k } end }) end })
Random = { new = function() return { NextNumber = function() return 0.5 end, NextInteger = function(_, a) return a end } end }

local STUB_CONFIG = {
	ORE_COUNT = ${ores.length},
	ORE_PACK_FIND_CAP = ${findCap[1]},
	ORE_YIELD_BANDS = {
${bands.map((b) => `\t\t{ upTo = ${b.upTo}, lo = ${b.lo}, hi = ${b.hi} },`).join("\n")}
	},
	ORES = {
${ores.map((o) => `\t\t{ id = "${o.id}", name = "${o.name}", tier = ${o.tier} },`).join("\n")}
	},
}
function STUB_CONFIG.oreById(id)
	for _, o in ipairs(STUB_CONFIG.ORES) do if o.id == id then return o end end
	return nil
end
-- The real body, copied from MineConfig.oreYieldFor, over the real bands.
function STUB_CONFIG.oreYieldFor(tier)
	local t = math.max(1, math.floor(tonumber(tier) or 1))
	for _, b in ipairs(STUB_CONFIG.ORE_YIELD_BANDS) do
		if t <= b.upTo then return b.lo, b.hi end
	end
	local last = STUB_CONFIG.ORE_YIELD_BANDS[#STUB_CONFIG.ORE_YIELD_BANDS]
	return last.lo, last.hi
end

local MODULES = { MineConfig = STUB_CONFIG }
local SHARED = { WaitForChild = function(_, n) return { Name = n } end }
script = { Name = "MineOrePouch", Parent = SHARED }
function require(t)
	local n = type(t) == "table" and t.Name or tostring(t)
	local m = MODULES[n]
	if m == nil then error("no stub for " .. n) end
	return m
end

local C = STUB_CONFIG
local Pouch = (function()
${pouch}
end)()

local fail = 0
local function check(ok, msg)
	if not ok then fail += 1 print("  FAIL  " .. msg) else print("  ok    " .. msg) end
end

local CAP = C.ORE_PACK_FIND_CAP
local cap1 = Pouch.capacity(1)
check(#C.ORES == C.ORE_COUNT, ("read the real roster (%d ores)"):format(#C.ORES))
check(cap1 > 0, ("a tier-1 pouch holds something (%d)"):format(cap1))
check(Pouch.room({}, 1) == cap1, "an empty pouch has its whole capacity free")

-- The migration's own arithmetic, over every ore, at the richest legal finder.
local worst, worstId, tooBig, belowLo, aboveHi = 0, "?", 0, 0, 0
for _, ore in ipairs(C.ORES) do
	local lo, hi = C.oreYieldFor(ore.tier)
	lo, hi = math.min(lo, hi), math.max(lo, hi)
	-- Exactly the expression in Dig.bankOrePacks.
	local each = math.max(1, math.floor(((lo + hi) / 2) * (1 + CAP) + 0.5))
	if each > worst then worst, worstId = each, ore.id end
	if each > cap1 then
		tooBig += 1
		print(("          %s wants %d, a tier-1 pouch holds %d"):format(ore.id, each, cap1))
	end
	-- Opening pays a uniform [lo, hi] times the same capped finder.
	local openLo = math.max(1, math.floor(lo + 0.5))
	local openHi = math.max(1, math.floor(hi * (1 + CAP) + 0.5))
	if each < openLo then belowLo += 1 print("          " .. ore.id .. " pays under the worst open roll") end
	if each > openHi then aboveHi += 1 print("          " .. ore.id .. " pays over the best open roll") end
end

check(tooBig == 0,
	("no pack outgrows a tier-1 pouch (worst %s at %d of %d)"):format(worstId, worst, cap1))
check(belowLo == 0, "the midpoint never pays under what opening could")
check(aboveHi == 0, "the midpoint never pays over what opening could")

-- bankOrePacks leaves a row alone when its ore is not on the roster, rather
-- than banking a rock that no longer exists.
check(C.oreById("definitely_not_an_ore") == nil, "an unknown ore id does not resolve")

-- room() floors at zero: an overfull pouch must not report negative room, or
-- the "< each" guard in the migration would read as plenty of space.
local full = {}
for _, ore in ipairs(C.ORES) do full[ore.id] = cap1 end
check(Pouch.room(full, 1) == 0, "an overfull pouch reports no room, not a negative")

if fail > 0 then
	print(">>> orepacks: " .. fail .. " failing assertion(s)")
	os.exit(1)
end
print(">>> orepacks: all assertions passed")
`;

const out = path.join(ROOT, ".luau-bin/orepacks-check.luau");
fs.writeFileSync(out, harness);
try {
  process.stdout.write(execFileSync(LUAU, [out], { encoding: "utf8" }));
} catch (e) {
  process.stdout.write(e.stdout || "");
  process.stderr.write(e.stderr || "");
  process.exit(1);
}
