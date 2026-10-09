// Lucky blocks show their odds, and the odds shown are the odds rolled.
//
// Lucky blocks are sold for credits, which are bought with Robux. Roblox
// requires a paid random item to show its odds before purchase. Owner,
// 2026-10-08: "fix all", on the finding that the lucky blocks showed none.
//
// So this checks the whole chain against the REAL modules:
//   1. MineLuckyBlocks.gradeOdds (computed exactly) sums to 1 from every start,
//   2. ...and matches a simulation of MineToolGrades.rollClash, the function
//      the server actually rolls with,
//   3. rollLoot's real draws match the KIND_TABLES rows the odds sheet reads,
//      so the sheet cannot drift from the roll,
//   4. the shop shows MineLuckyBlocks.oddsSheet, not numbers typed by hand.
//
//   node tools/verify/lucky-odds.js
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = path.resolve(__dirname, "../..");
const Luau = require("./_luau");
const LUAU = Luau.LUAU;
const read = (p) => Luau.readSrc(path.join(ROOT, p));
if (!Luau.ready) {
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(1);
}

const grades = read("src/ReplicatedStorage/Mine/Shared/MineToolGrades.luau");
const lucky = read("src/ReplicatedStorage/Mine/Shared/MineLuckyBlocks.luau")
  .replace('require(script.Parent:WaitForChild("MineToolGrades"))', "GRADES_STUB");

const harness = `
-- The block types carry colours; nothing here reads them.
Color3 = { fromRGB = function(r, g, b) return { r, g, b } end }
-- A deterministic Random, so the simulation is the same on every run.
Random = {}
Random.__index = Random
function Random.new(seed)
	return setmetatable({ s = (seed or 48611) % 2147483647 }, Random)
end
function Random:NextNumber()
	self.s = (self.s * 48271) % 2147483647
	return self.s / 2147483647
end
function Random:NextInteger(a, b)
	return a + math.floor(self:NextNumber() * (b - a + 1))
end

local Grades = (function()
${grades}
end)()
local GRADES_STUB = Grades
local LB = (function()
${lucky}
end)()

local fail = 0
local function check(ok, msg)
	if ok then print("  ok    " .. msg) else fail += 1 print("  FAIL  " .. msg) end
end
local ORDER = Grades.ORDER

-- 1. exact odds sum to 1 from every start the game hands out
for _, start in ipairs({ "F", "D", "C", "B", "A", "S", "SS", "SSS" }) do
	local o = LB.gradeOdds(start)
	local sum = 0
	for _, g in ipairs(ORDER) do sum += o[g] end
	check(math.abs(sum - 1) < 1e-9, string.format("gradeOdds(%s) sums to 1 (%.12f)", start, sum))
end

-- 2. ...and match the roll the server actually makes
local o = LB.gradeOdds("F")
local N = 200000
local rng = Random.new(7)
local counts = {}
for _, g in ipairs(ORDER) do counts[g] = 0 end
for _ = 1, N do
	local g = Grades.rollClash("F", rng, LB.UPGRADE_P)
	counts[g] += 1
end
local worst, worstG = 0, ""
for _, g in ipairs(ORDER) do
	local d = math.abs(counts[g] / N - o[g])
	if d > worst then worst, worstG = d, g end
end
check(worst < 0.004, string.format(
	"gradeOdds(F) matches %d rollClash rolls (worst gap %.3f%% at %s)", N, worst * 100, worstG))
print(string.format("        from F: F %.1f%%  D %.1f%%  C %.1f%%  B %.1f%%  A %.1f%%  S %.2f%%  SS %.2f%%  SSS %.2f%%",
	o.F * 100, o.D * 100, o.C * 100, o.B * 100, o.A * 100, o.S * 100, o.SS * 100, o.SSS * 100))

-- 3. rollLoot draws what KIND_TABLES says, for every block at every grade
local blocks = { "lucky_block", "super_lucky_block", "godly_lucky_block" }
local M = 6000
local worstLoot, where = 0, ""
local r2 = Random.new(99)
for _, b in ipairs(blocks) do
	for _, g in ipairs(ORDER) do
		local rows = LB.kindTable(b, g)
		check(type(rows) == "table" and #rows > 0, b .. " has kind rows at " .. g)
		local want, total = {}, 0
		for _, r in ipairs(rows) do total += r[1] end
		for _, r in ipairs(rows) do
			local k = (r[2] == "chase") and "dust" or r[2]
			want[k] = (want[k] or 0) + r[1] / total
		end
		local got = {}
		for _ = 1, M do
			local out = LB.rollLoot(b, g, r2)
			local k = out.kind
			if k == "scroll_white" or k == "scroll_black" or k == "scroll_omni" then
				-- rollLoot keeps these names in kind
			end
			got[k] = (got[k] or 0) + 1 / M
		end
		for k, p in pairs(want) do
			local d = math.abs((got[k] or 0) - p)
			if d > worstLoot then worstLoot, where = d, b .. " " .. g .. " " .. k end
		end
		for k in pairs(got) do
			check(want[k] ~= nil, b .. " at " .. g .. " only draws kinds in its table (" .. k .. ")")
		end
	end
end
check(worstLoot < 0.03, string.format(
	"rollLoot matches KIND_TABLES (worst gap %.2f%% at %s)", worstLoot * 100, where))

-- 4. the sheet adds up
for _, b in ipairs(blocks) do
	local s = LB.oddsSheet(b, "F")
	local ksum, psum = 0, 0
	for _, p in pairs(s.kinds) do ksum += p end
	for _, p in pairs(s.pets) do psum += p end
	check(math.abs(ksum - 1) < 1e-9, b .. ": reward chances sum to 1")
	check(math.abs(psum - (s.kinds.pet or 0)) < 1e-9, b .. ": pet tiers add up to the pet chance")
	for k in pairs(s.kinds) do
		check(LB.KIND_NAMES[k] ~= nil, b .. ": reward '" .. k .. "' has a name to show")
	end
end

if fail > 0 then
	print("")
	print(">>> lucky-odds: " .. fail .. " FAILED assertion(s)")
else
	print("")
	print(">>> lucky-odds: all assertions passed")
end
`;

const script = path.join(ROOT, ".luau-bin/lucky-odds-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(LUAU, [script], { encoding: "utf8" }); process.stdout.write(out); }
catch (e) {
  process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || "");
  process.exit(1);
}

let fail = /FAILED|FAIL /.test(out) ? 1 : 0;
const src = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };
const code = (s) => s.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");

// The front door: the odds are on the shop rows, BEFORE you buy, and they come
// from the module, not from numbers typed into a label.
const inv = read("src/ReplicatedStorage/Mine/Shared/MineInventoryView.luau");
const view = read("src/ReplicatedStorage/Mine/Shared/MineLuckyOddsView.luau");
const reveal = read("src/ReplicatedStorage/Mine/Shared/MineGradeReveal.luau");
src(/LB\.oddsSheet\(/.test(code(view)) && /WaitForChild\("MineLuckyBlocks"\)/.test(view),
  "the odds sheet (MineLuckyOddsView) reads MineLuckyBlocks.oddsSheet");
src(!/\d+(\.\d+)?%/.test(code(view).replace(/"%[^"]*"/g, "")),
  "...with no percentages typed in by hand");
src(/"ODDS"/.test(code(inv)) && /showLuckyOdds\(rowDef\.id/.test(code(inv)),
  "the credit shop has an ODDS button on every lucky row, before you buy");
src(/MineLuckyOddsView/.test(code(inv)) && /inspectStack\(g\)/.test(code(inv)),
  "...and a lucky block's info button in the bag opens its odds, not the pack inspector");
src(/oddsBtn/.test(code(reveal)) && /MineLuckyOddsView/.test(code(reveal)) && /st\.grade/.test(code(reveal)),
  "the lucky screen has ODDS for the grade the block is on now (Grade Up changes it)");

console.log("");
console.log(fail > 0 ? `>>> lucky-odds: ${fail} FAILED` : ">>> lucky-odds: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
