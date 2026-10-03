// The stat tables must agree with each other.
//
// A stat lives in four places and they are all load-bearing in a different way:
//
//   MineStats.STATS          its label, weight and description
//   MineStats.STAT_ORDER     whether any screen lists it
//   MineCards.emptyBoosts()  the key the boost table starts with
//   MineCards.ADDITIVE_STATS whether it adds or multiplies
//
// The dangerous one is emptyBoosts. The relic fold is guarded by
// `b[r.stat] ~= nil`, so a stat with no key there is not an error -- it is a
// boost that silently does nothing. That is what this check exists for: it bit
// while adding Earthquake and Ricochet, and nothing else in the suite can see
// it.
//
// Both modules are pure Lua with no requires, so they run as they ship.
//
//   node tools/verify/stats.js
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

const harness = `
Color3 = { fromRGB = function() return {} end }
Enum = setmetatable({}, { __index = function() return setmetatable({}, { __index = function(_, k) return { Name = k } end }) end })
Random = { new = function() return { NextNumber = function() return 0.5 end, NextInteger = function(_, a) return a end } end }
script = { Name = "harness", Parent = { WaitForChild = function(_, n) return { Name = n } end } }
function require() error("these modules are meant to need nothing") end

local Stats = (function()
${read("MineStats")}
end)()
local Cards = (function()
${read("MineCards")}
end)()

local fail = 0
local function check(ok, msg)
	if not ok then fail += 1 print("  FAIL  " .. msg) else print("  ok    " .. msg) end
end

local b = Cards.emptyBoosts()

-- 1. Everything a screen lists must be a real stat.
local ghosts = {}
for _, s in ipairs(Stats.STAT_ORDER) do
	if not Stats.STATS[s] then table.insert(ghosts, s) end
end
check(#ghosts == 0, "every STAT_ORDER entry is a real stat" ..
	(#ghosts > 0 and ("  missing: " .. table.concat(ghosts, ", ")) or ""))

--[[
	2. THE ONE THAT BITES: a listed stat with no boost key is a silent no-op.

	swingRate is the one legitimate exception and it is spelled out rather than
	skipped silently: kits grant a RATE (swings per second) and the game consumes
	swingSec (the gap between them), so MineCards.foldSwingRate converts it and
	the boost table carries swingSec instead. Adding a rate onto a duration key
	is the bug that comment was written for.
]]
local FOLDED = { swingRate = "swingSec" }
local noKey = {}
for _, s in ipairs(Stats.STAT_ORDER) do
	if b[s] == nil and not (FOLDED[s] and b[FOLDED[s]] ~= nil) then
		table.insert(noKey, s)
	end
end
check(#noKey == 0, "every listed stat has a key in emptyBoosts" ..
	(#noKey > 0 and ("  missing: " .. table.concat(noKey, ", ")) or ""))

-- 3. Additive stats start at 0, multipliers at 1. A multiplier that starts at 0
--    zeroes everything it touches; an additive that starts at 1 is a free +100%.
local wrong = {}
for s, v in pairs(b) do
	if type(v) == "number" then
		local add = Cards.ADDITIVE_STATS and Cards.ADDITIVE_STATS[s]
		if add and v ~= 0 then table.insert(wrong, s .. " additive but starts " .. tostring(v)) end
		if not add and v ~= 1 and s ~= "swingSec" then
			-- swingSec is a duration and legitimately starts at 1.
			table.insert(wrong, s .. " multiplier but starts " .. tostring(v))
		end
	end
end
check(#wrong == 0, "additive stats start at 0, multipliers at 1" ..
	(#wrong > 0 and ("  " .. table.concat(wrong, "; ")) or ""))

-- 4. Retired stats: present so old saves resolve, absent from STAT_ORDER so no
--    screen offers them. echo was barred as a buff; autoMine became Gem Find.
for _, s in ipairs({ "echo", "autoMine" }) do
	local listed = false
	for _, o in ipairs(Stats.STAT_ORDER) do
		if o == s then listed = true end
	end
	check(Stats.STATS[s] ~= nil and not listed,
		("%s is retired: resolvable but unlisted"):format(s))
	check(Stats.STATS[s] and Stats.STATS[s].legacy == true,
		("%s is marked legacy"):format(s))
end
check(type(Stats.ECHO_TO_SWING) == "number" and Stats.ECHO_TO_SWING > 0,
	"echo has a conversion rate to Swing Rate")

-- 5. The two new build boosts, end to end.
for _, s in ipairs({ "earthquake", "ricochet" }) do
	check(Stats.STATS[s] ~= nil, s .. " is a registered stat")
	check(b[s] == 0, s .. " starts at 0 in the boost table")
	check(Cards.ADDITIVE_STATS and Cards.ADDITIVE_STATS[s] == true, s .. " is additive")
end

-- 6. withoutAutoMine folds both retired stats and leaves nothing behind.
local folded = Stats.withoutAutoMine({ echo = 0.10, autoMine = 0.10, swingRate = 0.05 })
check(folded.echo == nil and folded.autoMine == nil,
	"withoutAutoMine clears both retired keys")
check((folded.swingRate or 0) > 0.05, "echo lands on swingRate")
check((folded.gemFind or 0) > 0, "autoMine lands on gemFind")

if fail > 0 then
	print("")
	print(">>> stats: " .. fail .. " FAILED assertion(s)")
end
`;

const script = path.join(ROOT, ".luau-bin/stats-check.luau");
fs.writeFileSync(script, harness);
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
if (/FAILED|FAIL /.test(out)) process.exit(1);
console.log("");
console.log(">>> stats: all assertions passed");
