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
const Luau = require("./_luau");
const LUAU = Luau.LUAU;

if (!Luau.ready) {
  // Names the platform and the fix, rather than "skipping" with no reason.
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(0);
}

const read = (n) => fs.readFileSync(path.join(SHARED, n + ".luau"), "utf8");
const EXPECTED_SLOTS = 5;

const harness = `
Color3 = { fromRGB = function() return {} end }
Enum = setmetatable({}, { __index = function() return setmetatable({}, { __index = function(_, k) return { Name = k } end }) end })
Random = { new = function() return { NextNumber = function() return 0.5 end, NextInteger = function(_, a) return a end } end }
Vector3 = { new = function() return {} end }
UDim2 = { fromOffset = function() return {} end, fromScale = function() return {} end, new = function() return {} end }
--[[
	MinePackConfig walks a chain at module scope:
	game:GetService("ReplicatedStorage"):WaitForChild("Mine"):WaitForChild("Shared").
	So the stub node has to be SELF-SIMILAR -- a node whose WaitForChild returns
	another node -- or the second hop finds a bare table.
]]
local function node(name)
	local t
	t = setmetatable({
		Name = name,
		WaitForChild = function(_, n) return node(n) end,
		FindFirstChild = function(_, n) return node(n) end,
		IsStudio = function() return false end,
		IsServer = function() return true end,
	}, { __index = function() return function() end end })
	return t
end
game = { GetService = function(_, n) return node(n) end }

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
-- MinePackConfig, for the card-subset assertions. Its data dependencies are
-- stubbed: cardPoolFor is pure, so the real roster is not what is under test.
MODULES.Mine1PacksData = (function()
${read("Mine1PacksData")}
end)()
MODULES.Mine1ChestsData = {}
MODULES.MinePotions = {}
script = { Name = "MinePackConfig", Parent = SHARED }
MODULES.MinePackConfig = (function()
${read("MinePackConfig")}
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

--[[
	5. EACH PACK DRAWS A SUBSET OF THE PETS, and no pet is orphaned.

	MinePackConfig is loaded for this with its data dependencies stubbed -- the
	function under test is pure (a pack id and a pool of indices in, a slice
	out), so the real pack roster is not what is being checked here. What IS
	checked is the property that makes the scheme safe: narrowing packs must not
	make any card unreachable from every pack.
]]
local Packs = MODULES.MinePackConfig
if Packs and Packs.cardPoolFor then
	local function poolOf(n)
		local t = {}
		for i = 1, n do t[i] = i end
		return t
	end

	-- Small pools are left whole: narrowing 2 to 1 orphans the other for nothing.
	local kept = true
	for n = 1, (Packs.CARD_SUBSET_MIN_POOL or 3) - 1 do
		local out = Packs.cardPoolFor({ id = "any_pack" }, poolOf(n))
		if #out ~= n then kept = false end
	end
	check(kept, ("pools under %d are left whole"):format(Packs.CARD_SUBSET_MIN_POOL or 3))

	-- It actually narrows a real pool, and by the share it advertises.
	local big = poolOf(10)
	local slice = Packs.cardPoolFor({ id = "loam_pack" }, big)
	check(#slice < #big and #slice >= 2,
		("a pool of 10 narrows to %d"):format(#slice))

	-- Deterministic: a pack's pet list is a fact, not a reroll per open.
	local again = Packs.cardPoolFor({ id = "loam_pack" }, poolOf(10))
	local same = #slice == #again
	for i = 1, #slice do
		if slice[i] ~= again[i] then same = false end
	end
	check(same, "the same pack always draws the same slice")

	-- The real pack roster, for the two assertions that are about the roster
	-- rather than about the function.
	local ids = {}
	for _, row in ipairs(Packs.PACKS or {}) do
		if type(row) == "table" and row.id then ids[#ids + 1] = row.id end
	end
	check(#ids > 1, ("read the real pack roster (%d packs)"):format(#ids))

	--[[
		PACKS DIFFER -- in aggregate, which is the honest claim.

		With the window snapped to a tile there are only two windows, so half of
		all pack PAIRS share a slice by design. Asserting that two named packs
		differ tests the hash, not the feature. What matters is that the roster
		uses more than one window, so opening a different pack can mean a
		different pet.
	]]
	local windows = {}
	for _, id in ipairs(ids) do
		local s = Packs.cardPoolFor({ id = id }, poolOf(10))
		windows[tostring(s[1])] = true
	end
	local distinct = 0
	for _ in pairs(windows) do distinct += 1 end
	check(distinct > 1, ("the roster uses %d distinct windows, not one"):format(distinct))

	local worstN, worstMissing = nil, nil
	for _, n in ipairs({ 3, 4, 5, 7, 10, 14, 20 }) do
		local seen = {}
		for _, id in ipairs(ids) do
			for _, idx in ipairs(Packs.cardPoolFor({ id = id }, poolOf(n))) do
				seen[idx] = true
			end
		end
		local missing = 0
		for i = 1, n do
			if not seen[i] then missing += 1 end
		end
		if missing > 0 and not worstN then worstN, worstMissing = n, missing end
	end
	check(worstN == nil,
		("every card stays reachable from some pack, at every pool size (%s)")
			:format(worstN and ("pool " .. worstN .. " orphans " .. worstMissing) or "checked 3..20"))
else
	check(false, "MinePackConfig.cardPoolFor is missing")
end

if fail > 0 then
	print(">>> packs: " .. fail .. " FAILED assertion(s)")
else
	print(">>> packs: all assertions passed")
end
`;

const script = path.join(ROOT, ".luau-bin/packs-check.luau");
fs.writeFileSync(script, harness);
// The exit code is decided HERE, from the output, not by the Lua.
// This luau build has no os.exit, so a check that called it failed only by
// erroring on a nil value -- which happens to be non-zero today and would go
// silent the moment it did not. A verify script that can pass when it should
// fail is worse than no verify script.
let out = "";
try {
  out = execFileSync(LUAU, [script], { encoding: "utf8" });
  process.stdout.write(out);
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
  process.stdout.write(e.stdout || "");
  process.stderr.write(e.stderr || "");
  process.exit(1);
}
process.exit(/FAILED|FAIL /.test(out) ? 1 : 0);
