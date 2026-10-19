// THE MINE ONLY EXISTS DOWN TO THE OPEN CHUNK, AND IT IS A DIFFERENT MINE EVERY
// SERVER.
//
// Owner, 2026-10-06: "load only 1 chunk.. once the top chunk is loaded, as soon
// as it is touched(block broken), then load chunk 2 [...] once that is loaded
// then load a chunk below that and so on", "chunks are for performance aswell",
// and "make sure its all rasndomized".
//
// Two separate claims, so two separate halves here:
//
//   CEILING. MineDigAuth.chunkCeiling bounds generation by how deep anyone has
//   reached. This is the generation twin of canCreditDepth: that one refuses the
//   depth, this one refuses the rock. The deadlock to watch for is off-by-one --
//   close the chunk one layer early and its floor can never be generated, so it
//   can never be mined, so the next chunk never opens.
//
//   RANDOMNESS. The complaint that started this was "every time i join 4
//   halitite on top of the line". Layer 1 is what every player sees first, so it
//   is the layer most likely to look identical across joins. Marginal ore shares
//   being right does NOT prove the layout changed -- that was the exact mistake
//   the vein hash made earlier, where every share looked fine while the field
//   was correlated. So this compares two servers CELL BY CELL.
//
// Run: node tools/verify/chunkload.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const AUTH = Luau.readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineDigAuth.luau"));
const SRV = Luau.readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineServer.server.luau"));
const CFG = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau"));

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

console.log("chunkload: generation stops at the open chunk, and the mine is re-rolled per server");

ok(/function MineDigAuth\.chunkCeiling\(/.test(AUTH), "chunkCeiling exists");
ok(/function MineDigAuth\.deepestReachedAcross\(/.test(AUTH), "deepestReachedAcross exists");

// The clamp has to sit in ensureZone, not at the call sites. Five callers ask for
// `deepest + LAYER_WINDOW` today and a sixth will be added by someone who has
// never read this file.
ok(/target = math\.min\(target, Dig\.Auth\.chunkCeiling\(Dig\.Auth\.deepestReachedAcross\(profiles, zone\.id\)\)\)/.test(SRV),
  "ensureZone clamps its target to the chunk ceiling",
  "one choke point, so a new caller cannot forget");

// The far path must not claim the frontier. This is the bug that left layers
// 4..2505 permanently ungeneratable after a plaza arrival.
ok(/local far = \(target - from\) >= Const\.ENSURE_FAR/.test(SRV),
  "the far path is tracked");
ok(/if not far then\s*\n\s*--[^\n]*\n\s*builtTo\[zone\.id\] = math\.max/.test(SRV),
  "only the near path advances builtTo",
  "the far path builds a detached band; claiming it strands every layer above");

// The per-server salt is what makes the field differ between servers. If this
// ever goes back to a hash of the zone name it is the same mine forever.
ok(/salt = Random\.new\(\):NextInteger\(/.test(SRV), "the vein salt is rolled from Random, not derived from the zone");
ok(/C\.setVeinSalt\(zone\.id, salt\)/.test(SRV), "the salt is pushed into the ore field");
ok(/function MineConfig\.setVeinSalt\(/.test(CFG), "MineConfig.setVeinSalt exists");

if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU)) {
  console.log("  " + Luau.missing("luau"));
  console.log(fails === 0 ? ">>> chunkload OK (static only)" : `>>> ${fails} FAILED`);
  process.exit(fails === 0 ? 0 : 1);
}

const block = (src, head, close) => {
  const L = src.split("\n");
  const i = L.findIndex((l) => l.startsWith(head));
  if (i < 0) throw new Error("not found: " + head);
  for (let j = i; j < L.length; j++) if (L[j] === close) return L.slice(i, j + 1).join("\n");
  throw new Error("unterminated: " + head);
};
const CHUNK = /MineConfig\.DIG_CHUNK_LAYERS\s*=\s*(\d+)/.exec(CFG)[1];

// Slice the real ore field out of MineConfig so the randomness half measures the
// shipped generator and not a restatement of it.
// Just the hash chain and the salt, not the whole ore field. veins.js already
// measures the field end to end; what is specific to chunk loading is narrower
// and is the thing the owner actually saw: LAYER 1, the first thing anyone looks
// at on joining, being the same layer every time.
const needed = [
  "local function mul32(", "local function veinMix(", "local function veinFinal(",
  "local function veinUnit(", "local function zoneSeed(",
  "function MineConfig.setVeinSalt(",
];
const have = needed.filter((h) => CFG.split("\n").some((l) => l.startsWith(h)));
const missing = needed.filter((h) => !have.includes(h));

const harness = `local C = { DIG_CHUNK_LAYERS = ${CHUNK} }
local MineDigAuth = {}
${block(AUTH, "function MineDigAuth.chunkCeiling(", "end")}

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

local CH = ${CHUNK}
-- ------------------------------------------------------------ the ceiling --
check("a fresh server may generate the whole first chunk and no more",
	MineDigAuth.chunkCeiling(0) == CH, "ceiling " .. MineDigAuth.chunkCeiling(0))
check("one layer short of the floor still stops at the floor",
	MineDigAuth.chunkCeiling(CH - 1) == CH)
check("reaching the floor opens exactly one more chunk",
	MineDigAuth.chunkCeiling(CH) == CH * 2, "ceiling " .. MineDigAuth.chunkCeiling(CH))
check("and no more than one",
	MineDigAuth.chunkCeiling(CH) < CH * 3)
check("a depth pass deep in the mine opens the chunk around it",
	MineDigAuth.chunkCeiling(2500) == 2550, "ceiling " .. MineDigAuth.chunkCeiling(2500))

-- The deadlock: every chunk floor must be inside the ceiling it produces, or
-- the floor cannot be generated, cannot be mined, and the mine stops forever.
do
	local stuck = nil
	local reached = 0
	for _ = 1, 400 do
		local ceil = MineDigAuth.chunkCeiling(reached)
		if ceil <= reached then stuck = reached break end
		reached = ceil          -- mine straight down to the floor it allows
	end
	check("mining to each ceiling always opens the next chunk", stuck == nil,
		stuck and ("deadlocked at " .. stuck) or ("walked to " .. reached))
end
check("garbage input does not open the mine", MineDigAuth.chunkCeiling(nil) == CH
	and MineDigAuth.chunkCeiling(-999) == CH and MineDigAuth.chunkCeiling("x") == CH)

print(fails == 0 and ">>> ceiling OK" or (">>> " .. fails .. " FAILED"))
`;

const tmp = path.join(require("os").tmpdir(), "chunkload-ceiling.luau");
fs.writeFileSync(tmp, harness);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" });
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
}
process.stdout.write(out);
if (!/>>> ceiling OK/.test(out)) fails++;

// ---------------------------------------------------------- randomness ----
if (missing.length) {
  ok(false, "could not slice the ore field out of MineConfig", "missing: " + missing.join(", "));
} else {
  const cfgLines = CFG.split("\n");
  const grab = (head) => block(CFG, head, "end");
  const consts = cfgLines
    .filter((l) => /^MineConfig\.(ORE_|VEIN_|GRID|LAYERS|MINE1_)\w*\s*=\s*[-\d.]/.test(l))
    .join("\n");
  const oreCount = (/MineConfig\.ORES\s*=\s*{/.test(CFG) ? null : null);

  const rnd = `local MineConfig = {}
${consts}
${cfgLines.filter((l) => l.startsWith("local VEIN_SALT =")).join("\n")}
local veinZoneSeed = {}
local veinZoneSalt = {}
${grab("local function mul32(")}
${grab("local function veinMix(")}
${grab("local function veinFinal(")}
${grab("local function veinUnit(")}
${grab("function MineConfig.setVeinSalt(")}
${grab("local function zoneSeed(")}

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

--[[
	The host roll, cell by cell, exactly as veinOreAt derives it.

	veinOreAt hashes the CELL -- floor(x/cell), floor(y/cell), floor(z/cell) --
	and veinUnit(h, 1) is the roll that decides whether that cell carries a vein
	at all. Two servers differ only by the layout salt, so sampling the same cells
	under two salts answers "is it the same mine every join" at the only place it
	can be answered.
]]
local GRID = ${/MineConfig\.GRID\s*=\s*(\d+)/.exec(CFG) ? /MineConfig\.GRID\s*=\s*(\d+)/.exec(CFG)[1] : 21}
local CELL = MineConfig.VEIN_CELL or 4
local function sampleLayer(salt, layer)
	MineConfig.setVeinSalt("meadow", salt)
	local seed = zoneSeed("meadow")
	local cy = math.floor(layer / CELL)
	local t = {}
	for x = 0, GRID - 1 do
		for z = 0, GRID - 1 do
			local h = veinMix(veinMix(veinMix(seed, math.floor(x / CELL)), cy), math.floor(z / CELL))
			table.insert(t, veinUnit(h, 1))
		end
	end
	return t
end
local function differing(a, b)
	local n = 0
	for i = 1, #a do if math.abs(a[i] - b[i]) > 1e-9 then n += 1 end end
	return n, #a
end

-- Layer 1 is the one the owner actually saw repeat, so it is tested by name.
do
	local A, B = sampleLayer(11111, 1), sampleLayer(22222, 1)
	local diff, total = differing(A, B)
	check("layer 1 is a different field on a different server",
		diff > total * 0.95,
		string.format("%d of %d cells differ", diff, total))
end
-- And the same salt must reproduce it, or a released layer would grow back as a
-- different mine when it is rebuilt.
do
	local A, B = sampleLayer(31337, 1), sampleLayer(31337, 1)
	local diff, total = differing(A, B)
	check("the same server rebuilds the same layer", diff == 0,
		string.format("%d of %d cells differ", diff, total))
end
-- Every layer of the first chunk, not just the top one.
do
	local worst, worstLayer = 1, 0
	for layer = 1, ${CHUNK} do
		local A, B = sampleLayer(777, layer), sampleLayer(999, layer)
		local diff, total = differing(A, B)
		local frac = diff / total
		if frac < worst then worst = frac; worstLayer = layer end
	end
	check("every layer of chunk 1 is re-rolled per server", worst > 0.95,
		string.format("worst layer %d, %.1f%% of cells differ", worstLayer, worst * 100))
end
-- A salt that only shifts the field would pass the above while still being the
-- same mine translated. Compare salt A at layer L against salt B at layer L+1.
do
	local A = sampleLayer(555, 7)
	local B = sampleLayer(666, 8)
	local diff, total = differing(A, B)
	check("the field is not merely shifted between servers", diff > total * 0.95,
		string.format("%d of %d cells differ", diff, total))
end

print(fails == 0 and ">>> randomness OK" or (">>> " .. fails .. " FAILED"))
`;
  const tmp2 = path.join(require("os").tmpdir(), "chunkload-random.luau");
  fs.writeFileSync(tmp2, rnd);
  let out2 = "";
  try {
    out2 = execFileSync(Luau.LUAU, [tmp2], { encoding: "utf8" });
  } catch (e) {
    out2 = (e.stdout || "") + (e.stderr || "");
  }
  process.stdout.write(out2);
  if (!/>>> randomness OK/.test(out2)) fails++;
}

console.log(fails === 0 ? ">>> chunkload OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
