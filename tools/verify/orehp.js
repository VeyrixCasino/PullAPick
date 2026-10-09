// EVERY ORE HAD THE SAME HEALTH.
//
// Owner, 2026-10-08: "make it so all ores arent same health (should be a base
// health, and is multiplied by layer health multi)" and "make stone a little
// weaker".
//
// It was ORE_HP_MULT = 3, flat, applied to every ore in the game at one call
// site in MineServer. A Stone block and an Oganesson block at the same layer
// took exactly the same number of swings; the only thing that varied was the
// dirt curve underneath, which describes the LAYER and says nothing about what
// is in the rock.
//
// The shape now is  hardness(ore) x dirtHp(zone, layer)  -- the layer term
// untouched so no other block moves, and the ore term a MULTIPLIER rather than
// an absolute HP so an ore keeps its character at every depth instead of being
// trivial deep down and impossible early.
//
// Run: node tools/verify/orehp.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const CFG = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau"));
const SRV = Luau.readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineServer.server.luau"));

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

//[[ A CONSTANT INSIDE A COMMENT IS NOT A CONSTANT.
//
// This harness used to grep the raw source for `MineConfig.ORE_HP_MIN = ...`,
// which matches a commented-out line exactly as well as a live one. An awk
// line-delete in 4d7b8e7 removed the `]]` closing the comment above these
// three constants, so for two commits all of ORE_HP_MULT/MIN/MAX were comment
// text, oreHardness threw nil arithmetic on every ore block, and BOTH this
// file and compile.js passed -- compile.js because the file still parses, and
// this file because the text was still there to grep.
//
// So the source is stripped of block and line comments before anything is
// asserted about it. "Declared" now means declared, not merely written down.
//
// Nested [=[ ]=] forms are not handled; MineConfig uses them (the ore-face
// block) but never around a constant, and a stripper that tries to be clever
// about nesting is how you get a stripper with its own bug. ]]
const strip = (src) =>
  src
    .replace(/--\[\[[\s\S]*?\]\]/g, "")
    .replace(/--\[=\[[\s\S]*?\]=\]/g, "")
    .replace(/--[^\n]*/g, "");
const CFG_CODE = strip(CFG);
const SRV_CODE = strip(SRV);

console.log("orehp: an ore's health is its own, times the layer");

for (const k of ["ORE_HP_MULT", "ORE_HP_MIN", "ORE_HP_MAX", "ORE_HP_POW"]) {
  ok(new RegExp(`MineConfig\\.${k}\\s*=\\s*[0-9.]`).test(CFG_CODE),
    `${k} is live code, not comment text`,
    "oreHardness reads it; nil here throws on every ore block");
}

ok(/function MineConfig\.oreHardness\(/.test(CFG), "oreHardness exists");
ok(/function MineConfig\.oreBlockHp\(/.test(CFG), "oreBlockHp exists",
  "one function, so the stamp and any quote of it cannot disagree");
//[[ The call site is the thing that was actually wrong -- the flat multiply was
// written out there rather than living behind a function, which is how it
// stayed flat without anyone noticing. ]]
ok(/C\.oreBlockHp\(oreDef, zone, y\)/.test(SRV),
  "the server stamps ore blocks through oreBlockHp");
ok(/ORE_HP_MULT or 3\)\s*$/m.test(SRV) || /ORE_HP_MULT or 3\)/.test(SRV),
  "...with the old flat multiple still there as the unknown-ore fallback",
  "an unknown ore must stay breakable, not drop to 1 HP");

if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU)) {
  console.log("  " + Luau.missing("luau"));
  console.log(fails === 0 ? ">>> orehp OK (static only)" : `>>> ${fails} FAILED`);
  process.exit(fails === 0 ? 0 : 1);
}

const block = (src, head, close) => {
  const L = src.split("\n");
  const i = L.findIndex((l) => l.startsWith(head));
  if (i < 0) throw new Error("not found: " + head);
  for (let j = i; j < L.length; j++) if (L[j] === close) return L.slice(i, j + 1).join("\n");
  throw new Error("unterminated: " + head);
};
const K = (name, dflt) => {
  const m = new RegExp(`MineConfig\\.${name}\\s*=\\s*([0-9.]+)`).exec(CFG);
  return m ? m[1] : dflt;
};

//[[ The REAL roster, sliced, because tier/met/rough are exactly what the
// character term reads and a stub would be measuring invented ores. ]]
const harness = `local MineConfig = {
	ORE_HP_MULT = ${K("ORE_HP_MULT", "3")},
	ORE_HP_MIN = ${K("ORE_HP_MIN", "0.8")},
	ORE_HP_MAX = ${K("ORE_HP_MAX", "4.0")},
	ORE_HP_POW = ${K("ORE_HP_POW", "1.35")},
	ORE_HP_METAL = ${K("ORE_HP_METAL", "1.12")},
	ORE_HP_CRYSTAL = ${K("ORE_HP_CRYSTAL", "1.06")},
	ORE_HP_ROCK = ${K("ORE_HP_ROCK", "0.94")},
}
local Color3 = { fromRGB = function() return {} end }
local Enum = setmetatable({}, { __index = function() return setmetatable({}, { __index = function() return 0 end }) end })
${block(CFG, "MineConfig.ORES = {", "}")}
MineConfig.ORE_BY_ID = {}
for _, o in ipairs(MineConfig.ORES) do MineConfig.ORE_BY_ID[o.id] = o end
function MineConfig.oreById(id) return MineConfig.ORE_BY_ID[tostring(id or "")] end
${block(CFG, "function MineConfig.oreHardness(", "end")}

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

local N = #MineConfig.ORES
check("the roster is the real one", N == 82, N .. " ores")

-- ------------------------------------------- they are no longer all the same --
do
	local seen, lo, hi = {}, math.huge, 0
	for _, o in ipairs(MineConfig.ORES) do
		local h = MineConfig.oreHardness(o)
		seen[string.format("%.4f", h)] = true
		lo, hi = math.min(lo, h), math.max(hi, h)
	end
	local n = 0
	for _ in pairs(seen) do n += 1 end
	check("ores have different hardness", n > 40,
		string.format("%d distinct values across %d ores, %.2f..%.2f", n, N, lo, hi))
	check("...and the flat 3 is gone", seen["3.0000"] == nil or n > 1)
end

-- -------------------------------------------------------- stone is weaker --
do
	local stone = MineConfig.oreById("stone")
	local h = MineConfig.oreHardness(stone)
	check("stone is softer than the dirt around it", h < 1,
		string.format("%.2fx dirt (was 3.00x)", h))
	check("...but not free", h > 0.4, string.format("%.2f", h))
end

-- ------------------------------------------------------- the curve climbs --
do
	local bad = 0
	local prevBand = 0
	for t = 1, N, 1 do
		local o = MineConfig.ORES[t]
		-- band = the tier term alone, which must be monotonic even though
		-- character can make a neighbour dip.
		local f = ((t - 1) / (N - 1)) ^ MineConfig.ORE_HP_POW
		local band = MineConfig.ORE_HP_MIN + (MineConfig.ORE_HP_MAX - MineConfig.ORE_HP_MIN) * f
		if band < prevBand - 1e-9 then bad += 1 end
		prevBand = band
	end
	check("the tier term never goes backwards", bad == 0)
	check("the deepest ore is meaningfully harder than the first",
		MineConfig.oreHardness(MineConfig.ORES[N]) > MineConfig.oreHardness(MineConfig.ORES[1]) * 3,
		string.format("%.2f vs %.2f", MineConfig.oreHardness(MineConfig.ORES[N]),
			MineConfig.oreHardness(MineConfig.ORES[1])))
end

--[[
	AND IT STAYS SANE. A multiplier is the whole reason this is safe to apply at
	every depth: if the top ore were 50x the dirt it sits in, the deepest layers
	would be unplayable regardless of tool, because dirtHp is already the
	difficulty curve.
]]
do
	local worst = 0
	for _, o in ipairs(MineConfig.ORES) do
		worst = math.max(worst, MineConfig.oreHardness(o))
	end
	check("no ore is an unreasonable multiple of its layer", worst <= 6,
		string.format("worst %.2fx", worst))
end

-- ----------------------------------------- material actually changes things --
do
	local metal, crystal, rock = 0, 0, 0
	for _, o in ipairs(MineConfig.ORES) do
		local met = tonumber(o.met) or 0
		local rough = tonumber(o.rough) or 0.9
		if met >= 0.5 then metal += 1
		elseif rough <= 0.45 then crystal += 1
		else rock += 1 end
	end
	check("all three material characters are represented", metal > 0 and crystal > 0 and rock > 0,
		string.format("%d metal, %d crystal, %d rock", metal, crystal, rock))
	-- two ores one tier apart, different character, must not be identical
	local differ = 0
	for t = 2, N do
		if math.abs(MineConfig.oreHardness(MineConfig.ORES[t])
			- MineConfig.oreHardness(MineConfig.ORES[t - 1])) > 1e-6 then
			differ += 1
		end
	end
	check("neighbouring ores differ from each other", differ > N * 0.9,
		string.format("%d of %d adjacent pairs", differ, N - 1))
end

print(fails == 0 and ">>> orehp OK" or (">>> " .. fails .. " FAILED"))
`;

const tmp = path.join(require("os").tmpdir(), "orehp-harness.luau");
fs.writeFileSync(tmp, harness);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" });
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
}
process.stdout.write(out);
if (!/>>> orehp OK/.test(out)) fails++;

console.log(fails === 0 ? ">>> orehp OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
