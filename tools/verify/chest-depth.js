// Better chests deeper, and skin cases from chests (owner, 2026-10-10/11).
//
//   1. the depth curve: x1 at a zone's top, x3 at its floor, front-loaded;
//      Meadow and the event mines stay x1
//   2. it lifts only the B/A/S ranks of a zone's pool (MineChestRanks `better`)
//   3. a chest's skin case: 3%, and a better rank shifts the tier ladder up
//   4. wiring: the spawn, the open-time fallback and openChestBlock use it
//
// Runs the real MineChestRanks and the real MineConfig functions (cut out of
// the file verbatim) in luau, on a stub of the zone table and the HP curve.
//
//   node tools/verify/chest-depth.js
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");

const ROOT = path.resolve(__dirname, "../..");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8").replace(/\r\n/g, "\n");
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

if (!Luau.ready) { console.log(Luau.missing("luau") + "; skipping"); process.exit(1); }
const SH = "src/ReplicatedStorage/Mine/Shared/";
const cfg = read(SH + "MineConfig.luau");
const depth = read(SH + "MineDepth.luau");
const ranks = read(SH + "MineChestRanks.luau");
const cut = (src, from, to) => {
  const i = src.indexOf(from);
  const j = src.indexOf(to, i);
  if (i < 0 || j < 0) throw new Error("cannot cut " + from);
  return src.slice(i, j);
};
const depthBlock = cut(cfg, "MineConfig.CHEST_DEPTH_LUCK_MAX", "-- Pit lucky cubes");
const skinBlock = cut(cfg, "MineConfig.SKIN_CASE_TIERS = {", "\n--[[\n\tHOW MANY PACKS A PACK CHEST PAYS.");
const hpBase = (depth.match(/MineDepth\.HP_BASE = ([\d.]+)/) || [])[1];
const hpPer = (depth.match(/MineDepth\.HP_PER_LAYER = ([\d.]+)/) || [])[1];

const harness = `
Random = {}
Random.__index = Random
function Random.new(seed) return setmetatable({ s = (seed or 48611) % 2147483647 }, Random) end
function Random:NextNumber() self.s = (self.s * 48271) % 2147483647 return self.s / 2147483647 end
function Random:NextInteger(a, b) return a + math.floor(self:NextNumber() * (b - a + 1)) end
local Depth = { meadowDirtHp = function(l) return ${hpBase} + ${hpPer} * l end }
local MineConfig = {}
local ZONES = {
	meadow = { id = "meadow" }, sunscar = { id = "sunscar" }, primordium = { id = "primordium" },
	bigbang = { id = "bigbang", limited = true },
}
function MineConfig.zoneById(id) return ZONES[id] or ZONES.meadow end
function MineConfig.zoneLayers(z) return (z.id == "meadow") and 10000 or 5000 end
${depthBlock}
${skinBlock}
local Ranks = (function()
${ranks}
end)()
local function f(x) return string.format("%.2f", x) end
print("CURVE " .. f(MineConfig.chestRankLuck("sunscar", 1)) .. " " .. f(MineConfig.chestRankLuck("sunscar", 100)) .. " "
	.. f(MineConfig.chestRankLuck("sunscar", 500)) .. " " .. f(MineConfig.chestRankLuck("sunscar", 1000)) .. " "
	.. f(MineConfig.chestRankLuck("primordium", 5000)) .. " " .. f(MineConfig.chestRankLuck("sunscar", 99999)))
print("FLAT " .. f(MineConfig.chestRankLuck("meadow", 1)) .. " " .. f(MineConfig.chestRankLuck("meadow", 9000)) .. " "
	.. f(MineConfig.chestRankLuck("bigbang", 40)) .. " " .. f(MineConfig.chestRankLuck("nowhere", 400)))
local mono = true
local last = 0
for l = 1, 5000, 37 do
	local v = MineConfig.chestRankLuck("sunscar", l)
	if v < last then mono = false end
	last = v
end
print("MONO " .. tostring(mono))
-- 2. The sunscar pool's rank shares at the top and the floor.
local pool = {
	{ chestId = "a", rank = "C" }, { chestId = "b", rank = "C" }, { chestId = "c", rank = "C" },
	{ chestId = "d", rank = "B" }, { chestId = "e", rank = "B" }, { chestId = "f", rank = "S" },
	{ chestId = "g", rank = "B" }, { chestId = "h", rank = "A" }, { chestId = "i", rank = "D" },
}
local function shares(better)
	local rng = Random.new(7)
	local n = { S = 0, A = 0, B = 0, C = 0, D = 0 }
	for _ = 1, 40000 do
		local r = Ranks.roll(pool, rng, { luck = 1, better = better })
		n[r.rank] += 1
	end
	return n
end
local top, floor = shares(1), shares(3)
print(string.format("RANKS top S%d A%d B%d C%d D%d floor S%d A%d B%d C%d D%d",
	top.S, top.A, top.B, top.C, top.D, floor.S, floor.A, floor.B, floor.C, floor.D))
-- 3. Skin tiers by rank.
local function line(rank)
	local t = {}
	for _, r in ipairs(MineConfig.skinCaseTierOdds(rank)) do table.insert(t, r.tier .. "=" .. string.format("%.4f", r.p)) end
	return table.concat(t, " ")
end
print("SKIN_C " .. line("C"))
print("SKIN_B " .. line("B"))
print("SKIN_S " .. line("S"))
print("SKIN_F " .. line("F"))
do
	local rng = Random.new(11)
	local got, sss = 0, 0
	for _ = 1, 200000 do
		local t = MineConfig.rollChestSkinTier("A", rng, 1)
		if t then got += 1 if t == "SSS" then sss += 1 end end
	end
	print("ROLL " .. got .. " " .. sss)
	local capped = 0
	for _ = 1, 200000 do
		if MineConfig.rollChestSkinTier("C", rng, 50) then capped += 1 end
	end
	print("CAP " .. capped)
end
`;
const script = path.join(ROOT, ".luau-bin/chest-depth-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(Luau.LUAU, [script], { encoding: "utf8" }); }
catch (e) { process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || ""); fail++; }
const get = (tag) => (out.split(/\r?\n/).find((l) => l.startsWith(tag + " ")) || "").slice(tag.length + 1).trim();

// 1. the curve
const curve = get("CURVE").split(" ").map(Number);
check(curve[0] === 1 && curve[4] === 3 && curve[5] === 3, `a zone's top is x1 and its floor x3 (got ${get("CURVE")})`);
check(curve[1] > 1.6 && curve[1] < 1.8 && curve[2] > 2.1 && curve[2] < 2.3 && curve[3] > 2.4 && curve[3] < 2.5,
  "front-loaded: about x1.7 at layer 100, x2.2 at 500, x2.45 at 1,000");
check(get("FLAT") === "1.00 1.00 1.00 1.00", "Dirt Meadow, Event Horizon and an unknown zone stay x1 (owner: every zone except the first)");
check(get("MONO") === "true", "deeper is never worse");

// 2. ranks
const r = get("RANKS").match(/top S(\d+) A(\d+) B(\d+) C(\d+) D(\d+) floor S(\d+) A(\d+) B(\d+) C(\d+) D(\d+)/);
if (r) {
  const [tS, tA, tB, tC, tD, fS, fA, fB, fC, fD] = r.slice(1).map(Number);
  console.log(`        sunscar pool, per 40,000 chests: top S ${tS} A ${tA} B ${tB} C ${tC} D ${tD}; floor S ${fS} A ${fA} B ${fB} C ${fC} D ${fD}`);
  check(fS > tS * 2 && fA > tA * 2 && fB > tB * 2, "at the floor, S, A and B chests are more than twice as common");
  check(fD < tD && fC < tC, "...and D and C chests are rarer (only the better ranks are lifted)");
} else check(false, "rank shares printed");

// 3. skins
const odds = (tag) => Object.fromEntries(get(tag).split(" ").map((kv) => kv.split("=")).map(([k, v]) => [k, Number(v)]));
const sc = odds("SKIN_C"), sb = odds("SKIN_B"), ss = odds("SKIN_S"), sf = odds("SKIN_F");
check(Math.abs(sc.F - 400 / 1000) < 1e-3 && Math.abs(sc.SSS - 4 / 1000) < 1e-3, "a C chest's skin case rolls SKIN_CASE_TIERS as written");
check(sb.F === 0 && Math.abs(sb.D - 400 / 996) < 1e-3, "a B chest starts the ladder one tier up (D at F's weight)");
check(ss.F === 0 && ss.D === 0 && ss.C === 0 && ss.SSS > sc.SSS * 10, "an S chest starts at B, and its SSS share is over 10x a C chest's");
check(JSON.stringify(sf) === JSON.stringify(sc), "low ranks are never pushed down (an F chest rolls like a C)");
const [got, sss] = get("ROLL").split(" ").map(Number);
check(got > 5400 && got < 6600, `about 3% of chests drop a skin case (${got} of 200,000)`);
check(sss > 0, "an A chest's skin case can be SSS");
const capped = Number(get("CAP"));
check(capped > 17000 && capped < 19000, `chest luck is capped at x3: 9% at luck 50 (${capped} of 200,000)`);

// 4. wiring
const server = read("src/ServerScriptService/Mine/MineServer.server.luau");
check(/ZoneChests\.rollSpawn\(zone\.id, y, [^\n]*\n\t*C\.chestRankLuck and C\.chestRankLuck\(zone\.id, y\)/.test(server),
  "the wall's chest spawn passes the depth luck");
check(/better = C\.chestRankLuck and C\.chestRankLuck\(zone\.id, layer\)/.test(server), "the open-time fallback roll uses it too");
const open = (server.match(/local function openChestBlock\([\s\S]*?\nend\n/) || [""])[0];
check(/C\.rollChestSkinTier\(rank, rng/.test(open) && /Dig\.grantChestSkin\(p, tier, rng\)/.test(open),
  "openChestBlock rolls the skin case by the chest's rank and grants it");
const zc = read(SH + "MineZoneChests.luau");
check(/function MineZoneChests\.rollSpawn\(zoneId, layer, zoneIndex, better\)/.test(zc)
  && /rollChestAt\(1, layer, rng, better\)/.test(zc) && /better = better/.test(zc),
  "rollSpawn feeds it to the pool roll and the catalog roll");

console.log("");
console.log(fail > 0 ? `>>> chest-depth: ${fail} FAILED` : ">>> chest-depth: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
