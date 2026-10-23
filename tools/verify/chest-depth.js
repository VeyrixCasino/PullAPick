// Better chests deeper, and skin cases from chests (owner, 2026-10-10/11).
//
//   1. the depth curve: x1 at a zone's top, x3 at its floor, front-loaded;
//      Meadow and the event mines stay x1
//   2. it lifts the ranks from C up, the rarer the harder, and F and D get
//      rarer (MineChestRanks `better` and LIFT; F..SSS since 2026-10-19)
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
Color3 = { fromRGB = function(r, g, b) return { R = r, G = g, B = b } end }
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
-- 2. A zone's rank shares at the top and the floor (F..SSS, 2026-10-19): the
-- odds, and a pool roll against them (two F rows split F's share).
local pool = {
	{ chestId = "a", rank = "F" }, { chestId = "b", rank = "F" }, { chestId = "c", rank = "D" },
	{ chestId = "d", rank = "C" }, { chestId = "e", rank = "B" }, { chestId = "f", rank = "A" },
	{ chestId = "g", rank = "S" }, { chestId = "h", rank = "SS" }, { chestId = "i", rank = "SSS" },
}
local top, floor = Ranks.odds(1), Ranks.odds(3)
local lifts = {}
for _, r in ipairs(Ranks.LADDER) do table.insert(lifts, r .. "=" .. string.format("%.4f", floor[r] / top[r])) end
print("LIFTS " .. table.concat(lifts, " "))
local rng7, n, N = Random.new(7), {}, 200000
for _ = 1, N do
	local r = Ranks.roll(pool, rng7, { better = 3 })
	n[r.rank] = (n[r.rank] or 0) + 1
end
local worst = 0
for _, r in ipairs(Ranks.LADDER) do worst = math.max(worst, math.abs((n[r] or 0) / N - floor[r])) end
print("POOLROLL " .. string.format("%.5f", worst))
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
print("SKIN_D " .. line("D"))
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
const lifts = Object.fromEntries(get("LIFTS").split(" ").filter(Boolean).map((kv) => kv.split("=")).map(([k, v]) => [k, Number(v)]));
if (lifts.SSS) {
  console.log(`        share at a zone's floor / at its top: ${get("LIFTS")}`);
  const up = ["C", "B", "A", "S", "SS", "SSS"];
  check(up.every((k, i) => lifts[k] > 1 && (i === 0 || lifts[k] > lifts[up[i - 1]])) && lifts.S > 2,
    "at the floor every rank from C up is more common, the rarer the more (S more than twice)");
  check(lifts.F < 1 && lifts.D < 1, "...and F and D chests are rarer (the common ranks are not lifted)");
  check(Number(get("POOLROLL")) < 0.004, `a zone pool's roll draws those odds (worst gap ${get("POOLROLL")})`);
} else check(false, "rank shares printed");

// 3. skins
const odds = (tag) => Object.fromEntries(get(tag).split(" ").map((kv) => kv.split("=")).map(([k, v]) => [k, Number(v)]));
const sc = odds("SKIN_C"), sb = odds("SKIN_B"), ss = odds("SKIN_S"), sf = odds("SKIN_F"), sd = odds("SKIN_D");
check(Math.abs(sf.F - 400 / 1000) < 1e-3 && Math.abs(sf.SSS - 4 / 1000) < 1e-3, "an F chest's skin case rolls SKIN_CASE_TIERS as written");
check(Math.abs(sc.F - 200 / 1000) < 1e-3 && sc.F < sf.F, "a C chest is half a tier up (half the ladder as written, half shifted one)");
check(sb.F === 0 && Math.abs(sb.D - 400 / 996) < 1e-3, "a B chest starts the ladder one tier up (D at F's weight)");
check(ss.F === 0 && ss.D === 0 && ss.C === 0 && ss.SSS > sf.SSS * 10, "an S chest starts at B, and its SSS share is over 10x an F chest's");
check(JSON.stringify(sd) === JSON.stringify(sf), "low ranks are never pushed down (a D chest rolls like an F)");
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
// 2026-10-19: one spawn table (rank first, then the zone's or a set's chest of
// that rank) replaced the pool roll and the Mine 1 catalog roll.
check(/function MineZoneChests\.rollSpawn\(zoneId, layer, zoneIndex, better\)[\s\S]{0,120}?MineZoneChests\.spawnTable\(zoneId, layer, zoneIndex, better\)/.test(zc)
  && /MineZoneChests\.spawnTable\(zoneId, opts\.layer, opts\.zoneIndex, opts\.better\)/.test(zc),
  "rollSpawn and the open-time roll both draw the spawn table at that depth luck");

console.log("");
console.log(fail > 0 ? `>>> chest-depth: ${fail} FAILED` : ">>> chest-depth: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
