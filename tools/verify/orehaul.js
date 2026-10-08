// ORE HAUL: THE ONE STAT THAT MULTIPLIES ORE OUT OF A BLOCK, AND IT IS CAPPED.
//
// Owner, 2026-10-06: "REMEMBER ESPICALLY ENDGAME ENCHANTS BUFF THAT SO KEEP IT
// HIGH". Measured in docs/ore-yield-and-vein-balance.md §4, nothing did: the
// drop was math.random(lo, hi) off oreYieldFor with no boost, enchant, luck or
// finder applied anywhere, so an Exotic tool cost ~12 MILLION blocks broken and
// no amount of gear could move that number.
//
// The reason this needs a harness rather than just a constant is the warning the
// drop site already carried, which is correct: "yield multipliers on a flat
// per-block rate are how the boost stack compounds". Ore drops on every ore
// block forever, and this game stacks boosts across pets, charms, gear, runes
// and skills. An uncapped multiplier there is the fastest-running-away number in
// the game, and it would not look wrong in any other check.
//
// Run: node tools/verify/orehaul.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const CFG = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau"));
const SRV = Luau.readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineServer.server.luau"));
const CARDS = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineCards.luau"));
const STATS = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineStats.luau"));

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

console.log("orehaul: ore quantity can be multiplied, and the multiplier has a ceiling");

ok(/oreHaul\s*=\s*\{ label = "Ore Haul"/.test(STATS), "the Ore Haul stat exists");
ok(/"fossilFind", "oreHaul"/.test(STATS), "it is listed in STAT_ORDER so screens show it");

//[[ The two registrations that fail SILENTLY if forgotten. MineCards' own
// comment says it: the relic fold skips any stat whose key is not already on
// the boost table, so a missing emptyBoosts entry means every Ore Haul roll in
// the game quietly does nothing, with no error anywhere. ]]
ok(/oreHaul = 0,/.test(CARDS),
  "oreHaul starts at 0 in emptyBoosts",
  "a missing key is a silently ignored boost, not an error");
ok(/ADDITIVE_STATS = \{[^\n]*oreHaul = true/.test(CARDS),
  "oreHaul is additive, so sources sum from 0 rather than from 1",
  "listed as a multiplier, a single +50% would be spent as 2.5x");

ok(/MineConfig\.ORE_HAUL_CAP\s*=\s*\d+/.test(CFG), "there is a cap constant");
ok(/function MineConfig\.oreHaulMult\(/.test(CFG), "oreHaulMult exists");

// The drop site must use it, and must still refuse the finder.
ok(/local haul = C\.oreHaulMult\(b and b\.oreHaul\)/.test(SRV),
  "the ore drop applies Ore Haul");
ok(/local got = math\.random\(lo, hi\)\s*\n\s*local haul/.test(SRV),
  "it rolls first and multiplies after",
  "multiplying the band ends would lose the low end to flooring");
ok(/THE ORE FINDER IS STILL NOT APPLIED HERE/.test(SRV),
  "the ore finder is still kept out of quantity",
  "it is already spent as the quality shift in oreWeights");

if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU)) {
  console.log("  " + Luau.missing("luau"));
  console.log(fails === 0 ? ">>> orehaul OK (static only)" : `>>> ${fails} FAILED`);
  process.exit(fails === 0 ? 0 : 1);
}

const block = (src, head, close) => {
  const L = src.split("\n");
  const i = L.findIndex((l) => l.startsWith(head));
  if (i < 0) throw new Error("not found: " + head);
  for (let j = i; j < L.length; j++) if (L[j] === close) return L.slice(i, j + 1).join("\n");
  throw new Error("unterminated: " + head);
};
const CAP = /MineConfig\.ORE_HAUL_CAP\s*=\s*(\d+)/.exec(CFG)[1];

const harness = `local MineConfig = { ORE_HAUL_CAP = ${CAP} }
${block(CFG, "function MineConfig.oreHaulMult(", "end")}

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

local CAP = ${CAP}

-- ------------------------------------------------------- the base case --
check("no boost means no change", MineConfig.oreHaulMult(0) == 1)
check("nil means no change", MineConfig.oreHaulMult(nil) == 1,
	"an absent boost table must not error on every ore block")
check("+50% is 1.5x", math.abs(MineConfig.oreHaulMult(0.5) - 1.5) < 1e-9)
check("+900% is 10x", math.abs(MineConfig.oreHaulMult(9) - 10) < 1e-9)

-- ------------------------------------------------------------- the cap --
--[[
	THE ONE THAT MATTERS. Pets, charms, gear, runes and skills all stack, so the
	question is not whether a big number is reachable but whether an ARBITRARY
	one is. Nothing may pay more than CAP times the base roll.
]]
check("the cap holds at exactly the cap", MineConfig.oreHaulMult(CAP - 1) == CAP)
check("one past the cap is still the cap", MineConfig.oreHaulMult(CAP) == CAP)
do
	local worst = 0
	for _, h in ipairs({ 50, 500, 5000, 1e6, 1e12, math.huge }) do
		worst = math.max(worst, MineConfig.oreHaulMult(h))
	end
	check("no stack however absurd exceeds the cap", worst == CAP,
		string.format("worst %s against cap %d", tostring(worst), CAP))
end

-- --------------------------------------------- a boost cannot cost you --
do
	local bad = false
	for _, h in ipairs({ -1, -0.5, -1e9 }) do
		if MineConfig.oreHaulMult(h) < 1 then bad = true end
	end
	check("a negative boost never reduces a drop", not bad,
		"corrupt or debuffed, a player must not get LESS ore than base")
	check("NaN reads as no bonus rather than poisoning the drop",
		MineConfig.oreHaulMult(0 / 0) == 1)
	check("a string reads as no bonus", MineConfig.oreHaulMult("lots") == 1)
end

-- ------------------------------------------- it actually moves the grind --
--[[
	The point of the stat. The measured cost of an Exotic tool was ~12 million
	blocks broken with nothing able to move it. At the cap it must come down to
	something a determined player can reach, or the stat is decoration.
]]
do
	local EXOTIC_BLOCKS = 12000000
	local atCap = EXOTIC_BLOCKS / MineConfig.oreHaulMult(CAP)
	check("full Ore Haul brings the Exotic grind under a million blocks",
		atCap < 1000000, string.format("%.0f blocks at %dx", atCap, CAP))
	check("...but does not trivialise it", atCap > 100000,
		string.format("%.0f blocks still", atCap))
end

print(fails == 0 and ">>> orehaul OK" or (">>> " .. fails .. " FAILED"))
`;

const tmp = path.join(require("os").tmpdir(), "orehaul-harness.luau");
fs.writeFileSync(tmp, harness);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" });
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
}
process.stdout.write(out);
if (!/>>> orehaul OK/.test(out)) fails++;

console.log(fails === 0 ? ">>> orehaul OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
