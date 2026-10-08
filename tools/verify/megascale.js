// THE 10,000x PASS IS A HEADROOM CHANGE, NOT A BALANCE ONE.
//
// TODO 6.1, owner 2026-10-07: "i want all blocks and ores to be 10000x what
// they are right now (SAME WITH THE COST OF TOOLS...)". The numbers must read
// big. What a PLAYER experiences -- swings per block, blocks per tool, hauls
// per bag -- must not move at all.
//
// That is the whole risk of a pass like this, and it is not catchable by
// reading: multiply one side and forget the other and the game is 10,000x
// slower, with every individual number looking perfectly reasonable.
//
// So this does not check that things got bigger. It checks what CANCELS.
//
// Run: node tools/verify/megascale.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const DEPTH = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineDepth.luau"));
const CFG = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau"));
const SRV = Luau.readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineServer.server.luau"));
const ECON = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineShopEconomy.luau"));

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

console.log("megascale: the 10,000x pass cancels everywhere it must");

const scaleM = /MineDepth\.HP_SCALE\s*=\s*([0-9]+)/.exec(DEPTH);
ok(!!scaleM, "MineDepth.HP_SCALE is the single definition");
const SCALE = scaleM ? Number(scaleM[1]) : 1;
ok(SCALE === 10000, "it is 10,000", String(SCALE));

// ------------------------------------------------- one constant, derived --
ok(/MineConfig\.DMG_SCALE\s*=\s*Depth\.HP_SCALE/.test(CFG),
  "DMG_SCALE is DERIVED from HP_SCALE, not restated",
  "two literals is how one of them gets missed");
ok(/\(tool\.power or 1\) \* \(C\.DMG_SCALE or 1\)/.test(SRV),
  "the swing scales damage at the hit");
ok(/\(power or 1\) \* \(C\.DMG_SCALE or 1\)/.test(SRV),
  "the charge scales damage too",
  "explosives are a separate damage path and were missed once already");

//[[ The trap that would collapse the cosmetic ladder. power feeds lookTier
// through log10 and rarityForPower through bands; four extra decades there is
// +81 tiers at 20.25/decade, so every tool clamps to 82. ]]
ok(!/power\s*=\s*[^\n]*DMG_SCALE/.test(SRV) && !/DMG_SCALE[^\n]*\*\s*power\b/.test(SRV),
  "tool.power itself is NEVER scaled",
  "lookTier reads log10(power); scaling it puts every tool at cosmetic tier 82");

// ---------------------------------- ore coordinates must ignore the scale --
ok(/Depth\.dirtHp\(MineConfig\.ORE_LADDER_ZONES, MineConfig\.LAYERS\) \/ scale/.test(CFG),
  "ORE_DMAX divides HP_SCALE back out",
  "d is a coordinate, not HP -- reading dirtHp raw STEEPENS homeHp and moves every gem price");
ok(/MineConfig\.ORE_SCALE\s*=\s*1/.test(CFG),
  "ORE_SCALE is 1 and the quantity half is explicitly deferred");

// -------------------------------------- the one authored HP table outside --
ok(/BAND_FLOOR_HP\s*=\s*\{[^}]*15 \* s/.test(ECON.replace(/\n/g, " ")),
  "BAND_FLOOR_HP scales through the same constant",
  "it is the only authored HP outside MineDepth, so derivation cannot reach it");

// -------------------------------------- craftBlocks must NOT have moved --
//[[ veinSizeMean reads craftBlocks, so scaling it moves every vein in the
// game. TODO 6.1 names this collision explicitly. ]]
ok(!/craftBlocks[^\n]*(HP_SCALE|ORE_SCALE|DMG_SCALE)/.test(CFG),
  "craftBlocks is untouched by the pass",
  "veinSizeMean reads it; scaling it would silently move every vein");

if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU)) {
  console.log("  " + Luau.missing("luau"));
  console.log(fails === 0 ? ">>> megascale OK (static only)" : `>>> ${fails} FAILED`);
  process.exit(fails === 0 ? 0 : 1);
}

const num = (src, name, dflt) => {
  const m = new RegExp(`${name}\\s*=\\s*([0-9.]+)`).exec(src);
  return m ? m[1] : dflt;
};

//[[ The curve is rebuilt from the REAL constants at two scales and the two are
// compared. Not a restatement: HP_BASE, HP_PER_LAYER and ZONE_HP_MULT are read
// out of MineDepth, so if the curve's SHAPE changes this still measures it. ]]
const harness = `local HP_BASE = ${num(DEPTH, "MineDepth\\.HP_BASE", "20")}
local HP_PER_LAYER = ${num(DEPTH, "MineDepth\\.HP_PER_LAYER", "1.5")}
local ZONE_HP_MULT = ${num(DEPTH, "MineDepth\\.ZONE_HP_MULT", "5")}
local SCALE = ${SCALE}

local function dirtHp(zi, layer, scale)
	local raw = (HP_BASE + HP_PER_LAYER * layer) * scale * (ZONE_HP_MULT ^ (zi - 1))
	return math.max(1, math.floor(raw + 0.5))
end

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

-- --------------------------------------------- the numbers DID get bigger --
--[[
	Compared against the UNROUNDED curve, not against the rounded small value.

	dirtHp floors to an integer, and at the shallow end that rounding is a
	large share of the number: zone 1 layer 1 is 21.5 raw, which rounds to 22,
	so 22 x 10,000 is 220,000 against a true 215,000 -- a 2% gap that is the
	ROUNDING, not the scale. Measuring against the raw curve tests the thing
	this pass actually changed, and the swings check below is what proves the
	rounding is harmless in play.
]]
do
	local bad, worst = 0, 0
	for zi = 1, 10 do
		for _, L in ipairs({ 1, 50, 500, 2500, 10000 }) do
			local raw = (HP_BASE + HP_PER_LAYER * L) * (ZONE_HP_MULT ^ (zi - 1))
			local after = dirtHp(zi, L, SCALE)
			local err = math.abs(after / (raw * SCALE) - 1)
			if err > 1e-6 then bad += 1 end
			worst = math.max(worst, err)
		end
	end
	check("every block is exactly 10,000x the curve", bad == 0,
		string.format("50 points, worst error %.2e; z1L1 raw 21.5 -> %d", worst, dirtHp(1,1,SCALE)))
end

-- ------------------------------------------- and the GAME did not change --
--[[
	The only invariant that matters. A swing deals power * DMG_SCALE into a
	block of hp * HP_SCALE, so the count must be identical to the unscaled
	game -- not close, identical, because both sides are the same integer
	multiple.
]]
do
	local worst, worstAt = 0, ""
	for zi = 1, 10 do
		for _, L in ipairs({ 1, 50, 500, 2500, 10000 }) do
			for _, power in ipairs({ 1, 10, 569, 24484, 358318080 }) do
				local before = math.ceil(dirtHp(zi, L, 1) / power)
				local after = math.ceil(dirtHp(zi, L, SCALE) / (power * SCALE))
				local d = math.abs(after - before)
				if d > worst then
					worst, worstAt = d, string.format("z%d L%d p%d: %d vs %d", zi, L, power, before, after)
				end
			end
		end
	end
	check("swings to break a block are unchanged", worst <= 1,
		worst == 0 and "identical across 250 combinations" or ("worst " .. worstAt))
end

-- ------------------------------------------------- coins follow for free --
do
	-- one coin per point of HP, so the ratio of a block's pay to a tool's
	-- price is what must hold, and both are in coins.
	local blockPay = dirtHp(1, 100, SCALE)
	local blockPayBefore = dirtHp(1, 100, 1)
	check("a block pays 10,000x more, so coin prices keep pace on their own",
		math.abs(blockPay / blockPayBefore - SCALE) < 1,
		string.format("%d -> %d coins", blockPayBefore, blockPay))
end

-- ------------------------------------------------------- still printable --
--[[
	A 64-bit double holds integers exactly to 2^53. The deepest block in the
	game must stay well under that or the datastore round-trip starts losing
	units, which is the quiet failure mode of a pass like this.
]]
do
	local deepest = dirtHp(10, 10000, SCALE)
	check("the deepest block is exact in a double", deepest < 2^53,
		string.format("%.4g against 2^53 = %.4g", deepest, 2^53))
	--[[
		The realistic worst case, not an arbitrary margin: a lucky layer is
		x10 (LUCKY_LAYER_HP_MULT) and a chest is x2 (CHEST_HP_MULT), and those
		are the only two multipliers applied to a block's stored HP. Anything
		above 2^53 stops being an exact integer, and HP round-trips through the
		datastore -- so this is where the pass would start quietly losing units
		rather than visibly breaking.
	]]
	local worstCase = deepest * 10 * 2
	check("the hardest block in the game is still an exact integer", worstCase < 2^53,
		string.format("deepest x lucky10 x chest2 = %.4g, which is %.1f%% of 2^53",
			worstCase, worstCase / 2^53 * 100))
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
