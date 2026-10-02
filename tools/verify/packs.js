// Behavioural check that the FOSSIL PACKS are gone and the chest tables that
// used to name them are still well formed.
//
// Same approach as charms.js: it RUNS the real MineZonePacks and MineZoneChests
// under a small Roblox stub rather than re-deriving them here. The thing worth
// guarding is not "the word fossil is absent from a file" -- grep does that --
// but that the GENERATED roster and the 90-odd chest loot tables still line up
// after three of the eight per-zone slots were taken out:
//
//   * no pack id, anywhere, is a fossil pack
//   * every zone authors exactly the 5 remaining slots
//   * every chest's pack list names a slot that exists, with no duplicates
//     (entries are independent chances, so a duplicate silently rolls twice)
//   * every chest still offers at least one pack
//
// Needs the luau binary that tools/verify/syntax.sh fetches into .luau-bin/.
//
//   node tools/verify/packs.js
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

const read = (n) => fs.readFileSync(path.join(SHARED, n + ".luau"), "utf8");
const EXPECTED_SLOTS = 5;

const harness = `
Color3 = { fromRGB = function() return {} end }
Enum = setmetatable({}, { __index = function() return setmetatable({}, { __index = function(_, k) return { Name = k } end }) end })
Random = { new = function() return { NextNumber = function() return 0.5 end, NextInteger = function(_, a) return a end } end }

local MODULES = {}
local SHARED = { WaitForChild = function(_, n) return { Name = n } end,
                 FindFirstChild = function(_, n) return { Name = n } end }
script = { Name = "harness", Parent = SHARED }
function require(t)
	local n = type(t) == "table" and t.Name or tostring(t)
	local m = MODULES[n]
	if m == nil then error("no stub for " .. n) end
	return m
end

MODULES.MineChestRanks = (function()
${read("MineChestRanks")}
end)()
MODULES.MineZonePacks = (function()
${read("MineZonePacks")}
end)()
local ZP = MODULES.MineZonePacks
local ZC = (function()
${read("MineZoneChests")}
end)()

local fail = 0
local function check(ok, msg)
	if not ok then fail += 1 print("  FAIL  " .. msg) else print("  ok    " .. msg) end
end

-- 1. No fossil pack survives anywhere in the generated roster.
local fossilIds, total = {}, 0
for id in pairs(ZP.PACKS) do
	total += 1
	if string.find(id, "fossil", 1, true) then table.insert(fossilIds, id) end
end
check(#fossilIds == 0, ("no fossil pack in the roster (found %d of %d)")
	:format(#fossilIds, total))
if #fossilIds > 0 then
	table.sort(fossilIds)
	for _, id in ipairs(fossilIds) do print("          " .. id) end
end

-- 2. Slot count, and every zone carrying all of them.
check(#ZP.SLOTS == ${EXPECTED_SLOTS},
	("${EXPECTED_SLOTS} slots per zone (got %d)"):format(#ZP.SLOTS))
local slotOk = true
for _, slot in ipairs(ZP.SLOTS) do
	if not ZP.SLOT_META[slot] then slotOk = false print("          no SLOT_META for " .. slot) end
end
check(slotOk, "every slot has a SLOT_META row")

local zones = #ZP.ZONE_ORDER + 1 -- the permanent zones plus the limited one
local missing = 0
for _, zoneId in ipairs(ZP.ZONE_ORDER) do
	for _, slot in ipairs(ZP.SLOTS) do
		if not ZP.PACKS[ZP.id(zoneId, slot)] then missing += 1 end
	end
end
check(missing == 0, ("every zone authors every slot (%d missing)"):format(missing))
check(total == zones * ${EXPECTED_SLOTS},
	("%d zones x ${EXPECTED_SLOTS} slots = %d packs (got %d)")
		:format(zones, zones * ${EXPECTED_SLOTS}, total))

-- 3. Every chest's pack list: known slots, no duplicates, at least one pack.
local known = {}
for _, slot in ipairs(ZP.SLOTS) do known[slot] = true end
local badSlot, dupes, empty, chests = 0, 0, 0, 0
for id, def in pairs(ZC.DEFS) do
	chests += 1
	local seen, n = {}, 0
	for _, entry in ipairs(def.packs or {}) do
		n += 1
		if not known[entry.slot] then
			badSlot += 1
			print(("          %s names unknown slot %s"):format(id, tostring(entry.slot)))
		end
		if seen[entry.slot] then
			dupes += 1
			print(("          %s rolls %s twice"):format(id, tostring(entry.slot)))
		end
		seen[entry.slot] = true
	end
	if n == 0 then
		empty += 1
		print("          " .. id .. " offers no pack at all")
	end
end
check(badSlot == 0, ("all %d chests name known slots"):format(chests))
check(dupes == 0, "no chest rolls the same slot twice")
check(empty == 0, "every chest offers at least one pack")

-- 4. rollPackDrops still returns ids that resolve, for every zone.
local unresolved = 0
for _, zoneId in ipairs(ZP.ZONE_ORDER) do
	for _, def in pairs(ZC.DEFS) do
		for _, id in ipairs(ZC.rollPackDrops(zoneId, def, Random.new())) do
			if not ZP.PACKS[id] then
				unresolved += 1
				print("          " .. id .. " does not resolve")
			end
		end
	end
end
check(unresolved == 0, "every rolled pack id resolves to a real pack")

if fail > 0 then
	print(">>> packs: " .. fail .. " failing assertion(s)")
	os.exit(1)
end
print(">>> packs: all assertions passed")
`;

const out = path.join(ROOT, ".luau-bin/packs-check.luau");
fs.writeFileSync(out, harness);
try {
  process.stdout.write(execFileSync(LUAU, [out], { encoding: "utf8" }));
} catch (e) {
  process.stdout.write(e.stdout || "");
  process.stderr.write(e.stderr || "");
  process.exit(1);
}
