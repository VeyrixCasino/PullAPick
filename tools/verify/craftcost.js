// A craft costs what it costs because of the ore, not a flat number.
//
// Owner, 2026-10-03: "for the craft tool, i want it to be variable, dependent
// on a) ore drop amount, b) Rarity of the ore, c) how far into progression".
//
// It was TOOL_CRAFT_BASE 250 x a tier curve, which used none of the three.
// This runs the real functions against the real band tables and asserts all
// three are actually in the answer.
//
//   node tools/verify/craftcost.js
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const ROOT = path.resolve(__dirname, "../..");
const Luau = require("./_luau");
const LUAU = Luau.LUAU;
const read = (p) => Luau.readSrc(path.join(ROOT, p));
if (!Luau.ready) {
  // Names the platform and the fix, instead of "skipping" with no reason --
  // and exits 1, because a check that cannot run is not a check that passed.
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(1);
}
const cfg = read("src/ReplicatedStorage/Mine/Shared/MineConfig.luau");
const grab = (re, what) => {
  const m = cfg.match(re);
  if (!m) { console.error(`FAIL could not find ${what}`); process.exit(1); }
  return m[0];
};
const num = (k) => Number((cfg.match(new RegExp(`MineConfig\\.${k}\\s*=\\s*([\\d.]+)`)) || [])[1]);
const oreCount = (cfg.match(/MineConfig\.ORES = \{([\s\S]*?)\n\}/) || ["", ""])[1]
  .split("\n").filter((l) => /\{\s*id = "/.test(l)).length;

const harness = `
local MineConfig = { ORE_COUNT = ${oreCount},
	CRAFT_BLOCKS = ${num("CRAFT_BLOCKS")},
	CRAFT_BAND_EASE = ${num("CRAFT_BAND_EASE")},
	CRAFT_DEPTH_SLOPE = ${num("CRAFT_DEPTH_SLOPE")} }
${grab(/MineConfig\.ORE_YIELD_BANDS = \{[\s\S]*?\n\}/, "ORE_YIELD_BANDS")}
${grab(/MineConfig\.ORE_BAND_ORDER = \{[^\n]*\}/, "ORE_BAND_ORDER")}
${grab(/function MineConfig\.oreYieldFor\(tier\)[\s\S]*?\nend\n/, "oreYieldFor")}
${grab(/function MineConfig\.oreBandForTier\(tier\)[\s\S]*?\nend\n/, "oreBandForTier")}
${grab(/function MineConfig\.craftBlocks\(tier\)[\s\S]*?\nend\n/, "craftBlocks")}
${grab(/function MineConfig\.oreYieldMid\(tier\)[\s\S]*?\nend\n/, "oreYieldMid")}
${grab(/function MineConfig\.toolCraftCost\(tier, typeMult\)[\s\S]*?\nend\n/, "toolCraftCost")}
local C = MineConfig
local fail = 0
local function check(ok, msg)
	if not ok then fail += 1 print("  FAIL  " .. msg) else print("  ok    " .. msg) end
end

-- Nothing is free, and nothing is nil.
local bad = 0
for t = 1, C.ORE_COUNT do
	local c = C.toolCraftCost(t, 1)
	if type(c) ~= "number" or c < 1 or c ~= math.floor(c) then bad += 1 end
end
check(bad == 0, "every one of the " .. C.ORE_COUNT .. " ores has a whole, non-zero cost")

-- (a) DROP AMOUNT. Two ores at the same depth-and-band pressure but different
-- drop rates must not cost the same. Epic drops 13.5 a block, Exotic 3.
local epic, exotic = C.toolCraftCost(55, 1), C.toolCraftCost(82, 1)
check(epic > exotic * 2,
	("drop amount is in the answer: Epic %d vs Exotic %d"):format(epic, exotic))
check(math.abs(C.oreYieldMid(55) - 13.5) < 1e-9, "oreYieldMid reads the real band (Epic 13.5)")
check(math.abs(C.oreYieldMid(82) - 3) < 1e-9, "...and the Exotic one (3)")

-- (b) RARITY. A rarer band needs FEWER blocks than depth alone would ask, or
-- scarcity gets multiplied by itself.
local easeOff = C.craftBlocks(82) / C.craftBlocks(60)
check(easeOff < 1.4,
	("rarity eases the block count rather than compounding it (%.2fx from Epic to Exotic)"):format(easeOff))

-- (c) PROGRESSION. Deeper is a bigger errand than tier 1, by a lot.
check(C.craftBlocks(82) > C.craftBlocks(1) * 1.8,
	("depth is in the answer: %.0f blocks at tier 82 vs %.0f at tier 1"):format(
		C.craftBlocks(82), C.craftBlocks(1)))
--[[
	The curve steps DOWN at every band boundary, and that is the design, not a
	bug: the first Uncommon ore is rarer than the last Common one, so the ease
	in (b) lands as a discrete drop while depth climbs smoothly. The first
	version of this check asserted a monotonic rise and failed on exactly that.

	What must hold is that no single step is a cliff -- a boundary that halved
	the cost would make "mine one tier deeper" a way to pay less for strictly
	more tool.
]]
local worstStep, at = 1, 0
for t = 2, C.ORE_COUNT do
	local r = C.craftBlocks(t) / C.craftBlocks(t - 1)
	if r < worstStep then worstStep, at = r, t end
end
check(worstStep > 0.85,
	("no band boundary is a cliff: worst step is %.3fx, at tier %d"):format(worstStep, at))
-- And the trend across the whole roster is still upward.
check(C.craftBlocks(60) > C.craftBlocks(20) and C.craftBlocks(20) > C.craftBlocks(1),
	"the trend across bands is still upward")

-- It must actually VARY. A formula that collapses to a constant would pass
-- everything above by accident if the factors cancelled.
local lo, hi = math.huge, 0
for t = 1, C.ORE_COUNT do
	local c = C.toolCraftCost(t, 1)
	lo, hi = math.min(lo, c), math.max(hi, c)
end
check(hi > lo * 3, ("cost spans %d..%d across the roster"):format(lo, hi))

-- typeMult still multiplies, since the Forge and the craft verb both pass it.
check(C.toolCraftCost(30, 2) > C.toolCraftCost(30, 1), "typeMult still raises the cost")

if fail > 0 then
	print("")
	print(">>> craftcost: " .. fail .. " FAILED assertion(s)")
else
	print("")
	print(">>> craftcost: all assertions passed")
end
`;
const script = path.join(ROOT, ".luau-bin/craftcost-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(LUAU, [script], { encoding: "utf8" }); process.stdout.write(out); }
catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
  process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || "");
  process.exit(1);
}
let fail = /FAILED|FAIL /.test(out) ? 1 : 0;
const src = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };
src(!/TOOL_CRAFT_BASE/.test(cfg), "the flat TOOL_CRAFT_BASE is gone");
src(/about %d blocks/.test(read("src/ReplicatedStorage/Mine/Shared/MineForge.luau")),
  "the Forge shows the cost in blocks, which is the readable unit");
console.log("");
console.log(fail > 0 ? `>>> craftcost: ${fail} FAILED` : ">>> craftcost: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
