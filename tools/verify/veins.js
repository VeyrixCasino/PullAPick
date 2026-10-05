// ORE COMES IN VEINS, and the veins must not change how much ore there is.
//
// MineConfig.veinOreAt replaced a per-block coin flip with a positional lattice:
// a cell hosts a vein of ore o with probability ORE_CHANCE * CELL^3 * share_o /
// size_o, and the vein then fills size_o blocks. The size cancels on paper, so
// expected ore per block is still ORE_CHANCE * share_o. "Cancels on paper" is a
// claim about arithmetic I wrote, which is exactly the kind of claim that is
// wrong by a factor of CELL^3 and looks fine in review.
//
// So this EXECUTES the real functions over a real volume and counts what comes
// out: total density, per-ore density, cluster sizes, cluster contiguity, and
// the inverse relationship between vein size and vein count the owner asked for.
//
// What this does NOT check is the share curve itself -- which ore is how likely
// at what depth. That is zones.js and ladder-climbable.js, and this harness
// stubs oreDifficulty to a depth ramp so it exercises a changing mix without
// restating a curve it does not own.
//
// Run: node tools/verify/veins.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const CFG = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau");
const src = Luau.readSrc(CFG);

if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU)) {
  console.log("  " + Luau.missing("luau"));
  process.exit(0);
}

const lines = src.split("\n");
function block(head, close) {
  const i = lines.findIndex((l) => l.startsWith(head));
  if (i < 0) throw new Error("not found: " + head);
  for (let j = i; j < lines.length; j++) {
    if (lines[j] === close) return { i, text: lines.slice(i, j + 1).join("\n") };
  }
  throw new Error("unterminated: " + head);
}
function line(head) {
  const i = lines.findIndex((l) => l.startsWith(head));
  if (i < 0) throw new Error("not found: " + head);
  return { i, text: lines[i] };
}

// Everything the vein layer reads, sliced from the real file and kept in file
// order so a later reorder that breaks load order shows up here.
const parts = [
  line("MineConfig.ORE_CHANCE ="),
  line("MineConfig.ORE_X0 ="),
  line("MineConfig.ORE_K ="),
  line("MineConfig.ORE_S ="),
  line("MineConfig.ORE_W ="),
  line("MineConfig.ORE_MIN_SHARE ="),
  block("MineConfig.ORES = {", "}"),
  block("function MineConfig.oreFindShift(", "end"),
  block("function MineConfig.oreWeights(", "end"),
  line("MineConfig.VEIN_CELL ="),
  line("MineConfig.VEIN_BIG_TIERS ="),
  line("MineConfig.VEIN_SOLO_FRAC ="),
  block("local VEIN_ORDER = {", "}"),
  line("MineConfig.VEIN_MAX ="),
  block("local function mul32(", "end"),
  block("local function veinMix(", "end"),
  block("local function veinFinal(", "end"),
  line("local VEIN_SALT ="),
  block("local function veinUnit(", "end"),
  block("local function zoneSeed(", "end"),
  block("function MineConfig.veinSizeFor(", "end"),
  block("function MineConfig.veinSizeMean(", "end"),
  block("function MineConfig.veinWeights(", "end"),
  block("function MineConfig.veinOreAt(", "end"),
];
parts.sort((a, b) => a.i - b.i);

// oreWeights caches on a table declared just above it; veinWeights likewise.
// Both are `local X = {}` one-liners, so they are declared here rather than
// sliced -- there is nothing in them to get wrong.
// Color3 and Enum are Roblox globals the ORES rows use for colour and material.
// Stubbed rather than avoided, because the point is to run the REAL roster.
const harness = `local Color3 = { fromRGB = function() return {} end }
local Enum = { Material = setmetatable({}, { __index = function() return {} end }) }

local MineConfig = {}
local Depth = { sectionFor = function(layer) return { id = math.floor(layer / 40) } end }
local oreWeightCache, veinWeightCache, veinZoneSeed = {}, {}, {}

${parts.map((p) => p.text).join("\n\n")}

MineConfig.ORE_COUNT = #MineConfig.ORES

-- The ore ladder's depth coordinate. ORE_DMAX comes off the live HP curve in
-- MineDepth, which this harness does not load; the vein layer only needs the
-- ores spread over SOME range, so the live span is restated as a local.
local DMAX = 10.9936
do
	local n = #MineConfig.ORES
	for _, o in ipairs(MineConfig.ORES) do
		o.d = (o.tier - 1) * DMAX / (n - 1)
	end
end

-- Depth ramp instead of the real rock-HP curve, for the reason in the header.
function MineConfig.oreDifficulty(_zoneId, layer)
	return math.clamp((layer / 2000) * DMAX, 0, DMAX)
end

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

print("veins: hash, shape, size bands, density conservation, contiguity")

-- ----------------------------------------------------------------- hash --
-- The 16-bit split multiply has to wrap like a real uint32 or murmur's
-- avalanche is built on garbage low bits. 0xFFFFFFFF^2 mod 2^32 is 1.
check("mul32 wraps exactly at 32 bits", mul32(0xFFFFFFFF, 0xFFFFFFFF) == 1,
	string.format("0x%08x", mul32(0xFFFFFFFF, 0xFFFFFFFF)))
check("mul32 agrees with a plain product where one fits in 53 bits",
	mul32(0x10001, 3) == 0x30003, string.format("0x%08x", mul32(0x10001, 3)))

--[[
	JOINT independence, not marginal uniformity.

	Two broken mixers shipped past a marginal check here: each of the six streams
	was a flat 10% per decile while being almost perfectly correlated with the
	others. The failure needs the streams measured TOGETHER -- among the cells
	that pass the host roll, the size jitter must still be a coin flip. The second
	broken mixer scored 10 in 1565 on this.
]]
do
	local cell = MineConfig.VEIN_CELL
	local hosted, jitterHigh = 0, 0
	for cy = 0, 999 do
		for cx = 0, 5 do
			for cz = 0, 5 do
				local h = veinMix(veinMix(veinMix(veinMix(zoneSeed("meadow"), cx), cy), cz), 0)
				-- 0.09 is about the real host probability; what matters is that it
				-- is a SMALL slice, because that is when correlation bites.
				if veinUnit(h, 1) < 0.09 then
					hosted += 1
					if veinUnit(h, 3) >= 0.5 then jitterHigh += 1 end
				end
			end
		end
	end
	local frac = jitterHigh / math.max(1, hosted)
	check("the size jitter is independent of the host roll",
		hosted > 300 and math.abs(frac - 0.5) < 0.06,
		string.format("%d of %d hosting cells have jitter >= 0.5 (%.1f%%, want ~50%%)",
			jitterHigh, hosted, frac * 100))
	-- cell is read so the lattice size cannot silently become meaningless here
	check("VEIN_CELL leaves room for a 2x2x2 vein", cell >= 2, tostring(cell))
end

-- ---------------------------------------------------------------- shape --
check("VEIN_MAX is 8, the owner's ceiling for all ores",
	MineConfig.VEIN_MAX == 8, tostring(MineConfig.VEIN_MAX))

-- Every size the band function can return, over the whole roster and the whole
-- jitter range. Nothing may exceed the ceiling or fall below one block.
local n = MineConfig.ORE_COUNT
local bands, worst, least = {}, 0, 99
for t = 1, n do
	local lo, hi = 99, 0
	for k = 0, 40 do
		local s = MineConfig.veinSizeFor(t, k / 40 * 0.9999)
		lo, hi = math.min(lo, s), math.max(hi, s)
		worst, least = math.max(worst, s), math.min(least, s)
	end
	bands[t] = { lo = lo, hi = hi }
end
check("no ore can ever exceed VEIN_MAX blocks", worst <= MineConfig.VEIN_MAX,
	"largest reachable size " .. tostring(worst))
check("no ore can vein to zero blocks", least >= 1, "smallest " .. tostring(least))

local big, mid, solo = {}, 0, 0
for t = 1, n do
	local b = bands[t]
	if b.hi >= 6 then
		table.insert(big, t)
	elseif b.lo <= 2 then
		solo += 1
	else
		mid += 1
	end
end
check("2-3 ores TOTAL group in 6-8s", #big >= 2 and #big <= 3,
	string.format("%d ores: tiers %s", #big, table.concat(big, ",")))
check("most of the roster groups in 3-4", mid > n / 2,
	string.format("%d of %d ores in 3-4", mid, n))
check("the rarest ores come in ones and twos", solo > 0,
	string.format("%d ores in 1-2", solo))
for _, t in ipairs(big) do
	check("tier " .. t .. " spans exactly 6-8",
		bands[t].lo == 6 and bands[t].hi == 8,
		string.format("%d-%d", bands[t].lo, bands[t].hi))
end

-- veinSizeMean must be the real mean of veinSizeFor, or the density correction
-- divides by the wrong number and every conservation check below drifts.
local meanOk = true
for t = 1, n do
	local sum, cnt = 0, 0
	for k = 0, 599 do
		sum += MineConfig.veinSizeFor(t, k / 600)
		cnt += 1
	end
	local got, want = sum / cnt, MineConfig.veinSizeMean(t)
	if math.abs(got - want) > 0.02 then
		meanOk = false
		print(string.format("        tier %d: sampled mean %.4f vs veinSizeMean %.4f", t, got, want))
	end
end
check("veinSizeMean matches the mean of veinSizeFor for every ore", meanOk)

-- ------------------------------------------------------- the real volume --
-- 24 x 24 columns (MineConfig.GRID) over 2000 layers: 1.15M blocks, which is
-- about 5,700 ore blocks -- enough for the aggregate, thin per-ore, which is
-- why per-ore is asserted in aggregate bands rather than ore by ore.
local GRID, DEEP = 24, 2000
local total, oreN = 0, 0
local perOre, cells = {}, {}
local seen = {}
for y = 1, DEEP do
	for x = 0, GRID - 1 do
		for z = 0, GRID - 1 do
			total += 1
			local o = MineConfig.veinOreAt("meadow", x, y, z, 1)
			if o then
				oreN += 1
				perOre[o.tier] = (perOre[o.tier] or 0) + 1
				seen[x .. ":" .. y .. ":" .. z] = o.tier
			end
		end
	end
end

print(string.format("  sampled %d blocks, %d ore (1 in %.1f)", total, oreN, total / math.max(1, oreN)))

local want = MineConfig.ORE_CHANCE
local got = oreN / total
check("total ore density is still ORE_CHANCE, unchanged by clustering",
	math.abs(got - want) / want < 0.08,
	string.format("1 in %.1f vs 1 in %.1f (%+.1f%%)", 1 / got, 1 / want, (got / want - 1) * 100))

-- ------------------------------------------------------------- clusters --
-- 6-connected flood fill over the ore blocks, same ore only. Two neighbouring
-- cells CAN each host a vein of the same ore and touch, so a measured cluster is
-- allowed to exceed 8 occasionally; what must hold is that it is rare.
local function key(x, y, z) return x .. ":" .. y .. ":" .. z end
local visited, sizes, bySizeOre = {}, {}, {}
local over, clusters = 0, 0
for k, tier in pairs(seen) do
	if not visited[k] then
		local sx, sy, sz = k:match("^(-?%d+):(-?%d+):(-?%d+)$")
		local stack = { { tonumber(sx), tonumber(sy), tonumber(sz) } }
		visited[k] = true
		local size = 0
		while #stack > 0 do
			local p = table.remove(stack)
			size += 1
			local steps = { { 1, 0, 0 }, { -1, 0, 0 }, { 0, 1, 0 }, { 0, -1, 0 }, { 0, 0, 1 }, { 0, 0, -1 } }
			for _, d in ipairs(steps) do
				local nx, ny, nz = p[1] + d[1], p[2] + d[2], p[3] + d[3]
				local nk = key(nx, ny, nz)
				if seen[nk] == tier and not visited[nk] then
					visited[nk] = true
					table.insert(stack, { nx, ny, nz })
				end
			end
		end
		clusters += 1
		sizes[size] = (sizes[size] or 0) + 1
		bySizeOre[tier] = bySizeOre[tier] or { n = 0, blocks = 0 }
		bySizeOre[tier].n += 1
		bySizeOre[tier].blocks += size
		if size > MineConfig.VEIN_MAX then over += 1 end
	end
end

local keys = {}
for s in pairs(sizes) do table.insert(keys, s) end
table.sort(keys)
local line = {}
for _, s in ipairs(keys) do table.insert(line, string.format("%dx%d", s, sizes[s])) end
print("  cluster sizes: " .. table.concat(line, " "))

check("ore is actually clustered, not noise", (oreN / math.max(1, clusters)) > 1.8,
	string.format("%.2f blocks per cluster across %d clusters", oreN / math.max(1, clusters), clusters))
check("clusters larger than 8 are rare (touching veins of the same ore)",
	over / math.max(1, clusters) < 0.05,
	string.format("%d of %d clusters (%.2f%%)", over, clusters, over / math.max(1, clusters) * 100))

--[[
	EVERY SIZE IN A BAND HAS TO ACTUALLY HAPPEN.

	This is the assertion that catches a correlated hash. veinOreAt derives the
	host roll, the ore pick, the size jitter and the three anchor axes from one
	cell hash plus a salt; if those streams are not independent, the size jitter
	tracks the host roll, and a cell only hosts when the host roll is small -- so
	the jitter is always small too and a band collapses onto its lowest size.

	The first implementation did exactly that: 6 and 3 appeared, 4, 7 and 8 never
	did, across 1.15 million blocks. The density was still right, the clustering
	was still right, and the bug was invisible to every other check here.
]]
local sawBig, sawMid = {}, {}
for s = 6, 8 do sawBig[s] = sizes[s] or 0 end
for s = 3, 4 do sawMid[s] = sizes[s] or 0 end
check("all three big-vein sizes (6, 7, 8) occur",
	sawBig[6] > 0 and sawBig[7] > 0 and sawBig[8] > 0,
	string.format("6:%d 7:%d 8:%d", sawBig[6], sawBig[7], sawBig[8]))
check("both mid-vein sizes (3, 4) occur",
	sawMid[3] > 0 and sawMid[4] > 0,
	string.format("3:%d 4:%d", sawMid[3], sawMid[4]))

-- ------------------------------ vein count falls as vein size rises ------
-- The owner's requirement (a): "something that spawns in 6-8s should have much
-- less veins spawning, than something that groups in 1s or 2s". Per ore, veins
-- per block of ore delivered must be 1/size -- so comparing veins-per-ore-block
-- between the bands is comparing 1/7 against 1/1.5.
local function bandRate(pred)
	local veins, blocks = 0, 0
	for tier, rec in pairs(bySizeOre) do
		if pred(tier) then
			veins += rec.n
			blocks += rec.blocks
		end
	end
	if blocks == 0 then return nil, 0 end
	return veins / blocks, blocks
end
local bigRate, bigBlocks = bandRate(function(t) return bands[t].hi >= 6 end)
local midRate, midBlocks = bandRate(function(t) return bands[t].lo >= 3 and bands[t].hi <= 4 end)
local soloRate, soloBlocks = bandRate(function(t) return bands[t].lo <= 2 and bands[t].hi <= 2 end)

print(string.format("  veins per ore block -- big:%s mid:%s solo:%s",
	bigRate and string.format("%.3f (%d blocks)", bigRate, bigBlocks) or "none sampled",
	midRate and string.format("%.3f (%d blocks)", midRate, midBlocks) or "none sampled",
	soloRate and string.format("%.3f (%d blocks)", soloRate, soloBlocks) or "none sampled"))

if bigRate and midRate then
	check("a 6-8 ore starts far fewer veins per block than a 3-4 ore",
		bigRate < midRate * 0.75,
		string.format("%.3f vs %.3f", bigRate, midRate))
else
	check("a 6-8 ore starts far fewer veins per block than a 3-4 ore", false,
		"not enough samples in one of the bands")
end
if midRate and soloRate then
	check("a 3-4 ore starts fewer veins per block than a 1-2 ore",
		midRate < soloRate * 0.85,
		string.format("%.3f vs %.3f", midRate, soloRate))
end

-- ------------------------------------------- per-ore density is intact ---
-- Aggregate the roster into the three vein bands and compare each band's
-- measured share of ore against the share oreWeights hands out. This is where a
-- missing 1/size would show as one band swallowing the others.
local wTot, wBand = 0, { big = 0, mid = 0, solo = 0 }
for y = 1, DEEP, 40 do
	local row = MineConfig.oreWeights("meadow", y, 1)
	for i = 1, n do
		local share = row.w[i] / row.tot
		wTot += share
		local b = bands[i]
		if b.hi >= 6 then
			wBand.big += share
		elseif b.lo <= 2 then
			wBand.solo += share
		else
			wBand.mid += share
		end
	end
end
local mBand = { big = 0, mid = 0, solo = 0 }
for tier, c in pairs(perOre) do
	local b = bands[tier]
	if b.hi >= 6 then
		mBand.big += c
	elseif b.lo <= 2 then
		mBand.solo += c
	else
		mBand.mid += c
	end
end
for _, nameB in ipairs({ "big", "mid", "solo" }) do
	local expect = wBand[nameB] / wTot
	local actual = mBand[nameB] / math.max(1, oreN)
	-- Solo ores are a millionth of the roll at these depths, so an absolute
	-- tolerance carries it where a relative one would divide by nothing.
	local okB = math.abs(actual - expect) < 0.05
	check(nameB .. " ores keep their share of the ore roll", okB,
		string.format("%.3f%% measured vs %.3f%% from oreWeights", actual * 100, expect * 100))
end

print(fails == 0 and ">>> veins OK" or (">>> " .. fails .. " FAILED"))
`;

// os.exit does NOT exist in this luau build -- `print(type(os.exit))` is nil.
// Four harnesses in this directory call it to signal failure, which throws
// "attempt to call a nil value" instead of exiting; that happens to still be a
// non-zero exit, so they report failure by accident rather than by design. This
// one reads the verdict out of stdout instead, so a pass and a fail are both
// deliberate.
const tmp = path.join(require("os").tmpdir(), "veins-harness.luau");
fs.writeFileSync(tmp, harness);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" });
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
  process.stdout.write(out);
  console.log("  FAIL  the luau harness exited non-zero");
  process.exit(1);
}
process.stdout.write(out);
if (!/>>> veins OK/.test(out)) {
  process.exit(1);
}
