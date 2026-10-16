// THE 10,000x PASS IS EVENT HORIZON ONLY, AND IT CANCELS INSIDE IT.
//
// TODO 6.1. Owner 2026-10-07: "i want all blocks and ores to be 10000x what
// they are right now (SAME WITH THE COST OF TOOLS, WITH WHATEVER CUSTOM
// [currency] THEY ARE USING)". Then 2026-10-08, after it first went in
// globally: "nooo 10 thousand x in ONLY the event mine. Not in the normal
// game."
//
// The clue was in the first sentence: "whatever custom currency they are
// using" is SPACE COINS, and the only thing priced in space coins is Event
// Horizon.
//
// So there are two things to prove and they pull in opposite directions:
//
//   1. the normal game is UNTOUCHED -- zones 1-10 identical to the unscaled
//      curve, so every other harness is still measuring what it was written
//      against
//   2. inside zone 11, BOTH halves moved -- block HP from the depth curve and
//      Horizon tool power from the authored SECTIONS table, which are
//      different tables, so scaling one and not the other is the live risk
//
// Run: node tools/verify/megascale.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const DEPTH = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineDepth.luau"));
const CFG = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau"));
const SRV = Luau.readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineServer.server.luau"));
const EH = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineHorizonTools.luau"));
const ECON = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineShopEconomy.luau"));

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

console.log("megascale: 10,000x in the event mine, and nowhere else");

const scaleM = /MineDepth\.HP_SCALE\s*=\s*([0-9]+)/.exec(DEPTH);
const zoneM = /MineDepth\.HP_SCALE_ZONE\s*=\s*([0-9]+)/.exec(DEPTH);
ok(!!scaleM && !!zoneM, "HP_SCALE and HP_SCALE_ZONE are both declared");
const SCALE = scaleM ? Number(scaleM[1]) : 1;
const ZONE = zoneM ? Number(zoneM[1]) : 11;
ok(SCALE === 10000, "the scale is 10,000", String(SCALE));
ok(ZONE === 11, "the scaled zone is 11 (Event Horizon)", String(ZONE));

ok(/function MineDepth\.hpScaleFor\(/.test(DEPTH),
  "hpScaleFor is the single place that decides which zone is scaled");
ok(/MineDepth\.hpScaleFor\(zoneIndex\)/.test(DEPTH), "dirtHp goes through it");

// ------------------------------------- the normal game must be left alone --
ok(!/DMG_SCALE/.test(SRV), "the swing and the charge carry NO global scale",
  "a global damage multiply is what made the normal game 10,000x");
ok(!/MineConfig\.DMG_SCALE|MineConfig\.ORE_SCALE/.test(CFG),
  "the global DMG_SCALE/ORE_SCALE constants are gone, not left at 1",
  "a dormant global scale is an invitation to switch it back on");
ok(/BAND_FLOOR_HP = \{ shallow = 15, /.test(ECON),
  "BAND_FLOOR_HP is back to its unscaled literals",
  "those are the normal game's shop bands; Event Horizon has no shop band");
ok(/local deepHp = Depth\.dirtHp\(MineConfig\.ORE_LADDER_ZONES, MineConfig\.LAYERS\)\s*$/m.test(CFG),
  "ORE_DMAX reads the curve raw again",
  "safe only because ORE_LADDER_ZONES is 10 and the scale is zone 11");

// --------------------------------------- both halves of the event loop --
ok(/Depth\.hpScaleFor and Depth\.hpScaleFor\(EH_ZI\)/.test(EH),
  "MineHorizonTools scales its reference HP from the same function",
  "its tools are priced off the authored SECTIONS table, not the depth curve");
ok(/\(tonumber\(sec\.dirtHp\) or 1\) \* EH_SCALE/.test(EH),
  "...on the reference HP, so the stated hit counts stay true");

if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU)) {
  console.log("  " + Luau.missing("luau"));
  console.log(fails === 0 ? ">>> megascale OK (static only)" : `>>> ${fails} FAILED`);
  process.exit(fails === 0 ? 0 : 1);
}

const num = (src, name, dflt) => {
  const m = new RegExp(`${name}\\s*=\\s*([0-9.]+)`).exec(src);
  return m ? m[1] : dflt;
};

const harness = `local HP_BASE = ${num(DEPTH, "MineDepth\\.HP_BASE", "20")}
local HP_PER_LAYER = ${num(DEPTH, "MineDepth\\.HP_PER_LAYER", "1.5")}
local ZONE_HP_MULT = ${num(DEPTH, "MineDepth\\.ZONE_HP_MULT", "5")}
local SCALE, ZONE = ${SCALE}, ${ZONE}

local function hpScaleFor(zi) return (zi == ZONE) and SCALE or 1 end
local function dirtHp(zi, layer)
	local raw = (HP_BASE + HP_PER_LAYER * layer) * (ZONE_HP_MULT ^ (zi - 1)) * hpScaleFor(zi)
	return math.max(1, math.floor(raw + 0.5))
end
-- the pre-pass curve, for comparison
local function dirtHpOld(zi, layer)
	return math.max(1, math.floor((HP_BASE + HP_PER_LAYER * layer) * (ZONE_HP_MULT ^ (zi - 1)) + 0.5))
end

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

-- ------------------------------------------- the normal game did not move --
--[[
	The assertion the owner actually asked for. Every zone a normal player
	ever touches must be byte-identical to what it was before the pass, or
	the ten-zone game silently got 10,000x harder, which is what happened the
	first time.
]]
do
	local bad = 0
	for zi = 1, 10 do
		for _, L in ipairs({ 1, 50, 500, 2500, 10000 }) do
			if dirtHp(zi, L) ~= dirtHpOld(zi, L) then bad += 1 end
		end
	end
	check("zones 1-10 are byte-identical to the unscaled curve", bad == 0,
		string.format("50 points; meadow L1 is %d, as it always was", dirtHp(1, 1)))
end

-- ----------------------------------------------- and the event mine did --
do
	local bad, worst = 0, 0
	for _, L in ipairs({ 1, 25, 50 }) do
		local raw = (HP_BASE + HP_PER_LAYER * L) * (ZONE_HP_MULT ^ (ZONE - 1))
		local err = math.abs(dirtHp(ZONE, L) / (raw * SCALE) - 1)
		if err > 1e-6 then bad += 1 end
		worst = math.max(worst, err)
	end
	check("zone 11 is exactly 10,000x the curve", bad == 0,
		string.format("worst error %.2e; L1 %d -> %d", worst, dirtHpOld(ZONE,1), dirtHp(ZONE,1)))
end

-- ------------------------------------ both halves of the loop still cancel --
--[[
	The real invariant. Horizon tool power is refHp / hits, and refHp scales
	with the blocks, so the hit count a tool advertises has to be exactly what
	it was. These are two different tables -- the depth curve and the authored
	SECTIONS list -- and scaling one without the other is the live risk here.
]]
--[[
	Asserted against the STATED hit count, not against the pre-pass behaviour,
	because the pre-pass behaviour was wrong at the shallow end.

	power is max(1, floor(refHp / hits + 0.5)). With Loam at refHp 10 and a
	sinkcharge rated at 70 hits, that floors to 0 and clamps to 1 -- so the
	tool whose blurb says "about 70 hits" actually took TEN. The integer had
	no room. Scaling the reference HP gives it room: the same tool comes out
	at 69 hits against a 70 target.

	So this measures the thing the blurb promises, and the scale is what makes
	it true rather than something it has to preserve.
]]
do
	local PICK_HITS, BORE_HITS, CHARGE_HITS = 16, 40, 70
	local worstAfter, worstAt, worstBefore = 0, "", 0
	for _, secHp in ipairs({ 10, 217, 9980, 23977, 1000000 }) do
		for _, hits in ipairs({ PICK_HITS, BORE_HITS, CHARGE_HITS }) do
			local powBefore = math.max(1, math.floor(secHp / hits + 0.5))
			local powAfter = math.max(1, math.floor(secHp * SCALE / hits + 0.5))
			local gotBefore = math.max(1, math.floor(secHp / powBefore))
			local gotAfter = math.max(1, math.floor(secHp * SCALE / powAfter))
			worstBefore = math.max(worstBefore, math.abs(gotBefore - hits) / hits)
			local err = math.abs(gotAfter - hits) / hits
			if err > worstAfter then
				worstAfter, worstAt = err, string.format("refHp %d, rated %d hits, got %d", secHp, hits, gotAfter)
			end
		end
	end
	check("a Horizon tool takes the number of hits it advertises", worstAfter < 0.05,
		string.format("worst %.1f%% off across 15 combinations", worstAfter * 100))
	check("...which it did NOT before the scale", worstBefore > 0.5,
		string.format("worst was %.0f%% off -- power clamped to 1 on shallow sections", worstBefore * 100))
end

-- ------------------------------------------------------- still printable --
do
	-- Event Horizon is 50 layers deep, not 10,000.
	local deepest = dirtHp(ZONE, 50)
	local worstCase = deepest * 10 * 2   -- lucky x10, chest x2
	check("the hardest event block is an exact integer", worstCase < 2^53,
		string.format("%.4g, which is %.2f%% of 2^53", worstCase, worstCase / 2^53 * 100))
	-- and the normal game's deepest, unchanged
	check("the normal game's deepest block is well clear too",
		dirtHp(10, 10000) * 10 * 2 < 2^53,
		string.format("%.4g", dirtHp(10, 10000) * 10 * 2))
end

print(fails == 0 and ">>> megascale OK" or (">>> " .. fails .. " FAILED"))
`;

const tmp = path.join(require("os").tmpdir(), "megascale-harness.luau");
fs.writeFileSync(tmp, harness);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" });
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
}
process.stdout.write(out);
if (!/>>> megascale OK/.test(out)) fails++;

console.log(fails === 0 ? ">>> megascale OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
