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
  // oreWeights asks oreSpreadK for the width now, so the ramp comes with it.
  line("MineConfig.ORE_K_TOP ="),
  line("MineConfig.ORE_K_RAMP ="),
  block("function MineConfig.oreSpreadK(", "end"),
  block("MineConfig.ORES = {", "}"),
  block("function MineConfig.oreFindShift(", "end"),
  block("function MineConfig.oreWeights(", "end"),
  line("MineConfig.VEIN_CELL ="),
  // Vein size is driven by cost/yield/rarity now, not two index thresholds, and
  // the shape is GROWN per cell rather than chosen from a table.
  line("MineConfig.VEIN_AXIS_BIAS ="),
  line("MineConfig.VEIN_MAX ="),
  line("MineConfig.VEIN_MEAN_AT_EASY ="),
  line("MineConfig.VEIN_MEAN_TYPICAL ="),
  line("MineConfig.VEIN_MEAN_AT_HARD ="),
  line("MineConfig.VEIN_W_COST ="),
  line("MineConfig.VEIN_W_YIELD ="),
  line("MineConfig.VEIN_W_RARITY ="),
  line("MineConfig.VEIN_TAIL_POWER_BIG ="),
  line("MineConfig.VEIN_TAIL_POWER_SMALL ="),
  // veinSizeMean reads the craft cost and the yield band, so the whole cost
  // chain comes with it. Sliced from the real file so the harness measures the
  // shipped prices rather than a restatement of them.
  line("MineConfig.CRAFT_BLOCKS ="),
  line("MineConfig.CRAFT_BAND_EASE ="),
  line("MineConfig.CRAFT_DEPTH_SLOPE ="),
  block("MineConfig.ORE_YIELD_BANDS = {", "}"),
  // ORE_BAND_ORDER is a ONE-LINER. block() searches forward for a line that is
  // exactly "}", so asking for it as a block swallowed another 90 lines --
  // including the do-block that derives ORE_DMAX from MineDepth, which then
  // died on a Depth stub that has no dirtHp. Same trap as MineDepth.SEAMS.
  line("MineConfig.ORE_BAND_ORDER ="),
  block("function MineConfig.oreBandForTier(", "end"),
  block("function MineConfig.oreYieldFor(", "end"),
  block("function MineConfig.craftBlocks(", "end"),
  block("function MineConfig.oreYieldMid(", "end"),
  block("function MineConfig.toolCraftCost(", "end"),
  block("function MineConfig._veinSpans(", "end"),
  block("function MineConfig._veinRaw(", "end"),
  block("function MineConfig.veinEffort(", "end"),
  block("local function mul32(", "end"),
  block("local function veinMix(", "end"),
  block("local function veinFinal(", "end"),
  line("local VEIN_SALT ="),
  block("local function veinUnit(", "end"),
  line("local VEIN_DIRS ="),
  block("local function veinGrow(", "end"),
  // zoneSeed reads the per-zone layout salt, so its table comes too. Without
  // it the sheet hashes against a nil salt and the harness errors rather than
  // quietly measuring a different mine.
  line("local veinZoneSeed ="),
  line("local veinZoneSalt ="),
  block("function MineConfig.setVeinSalt(", "end"),
  block("local function zoneSeed(", "end"),
  block("function MineConfig.veinSizeFor(", "end"),
  block("function MineConfig.veinSizeMean(", "end"),
  // The memo locals the two functions below read. Sliced explicitly because
  // they are module state, not constants, and omitting them made veinOreAt
  // index a nil `veinCell`.
  line("local vwZone, vwSec, vwBucket, vwRow ="),
  block("function MineConfig.veinWeights(", "end"),
  line("local veinCell ="),
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
--[[
	The ceiling was 8 and is now 14. Owner, 2026-10-06: "NO LIMIT ON VEINS.. MAKE
	AN EQUATION, BUT LETS SAY THE HIGHEST AVERAGE SHOULD BE 12-14 [WITH *MAYBE*
	ONE OR 2 ORES.. 90% SHOULD BE SUB 8]". So the ceiling itself is no longer the
	interesting property -- the SHAPE OF THE DISTRIBUTION is, and that is what the
	checks below pin: one or two ores up at 12-14, nine tenths of the roster under
	8, and the bulk still at 3-4.
]]
check("VEIN_MAX leaves room for a 12-14 average",
	MineConfig.VEIN_MAX >= 14, tostring(MineConfig.VEIN_MAX))

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
local huge, sub8 = {}, 0
for t = 1, n do
	local b = bands[t]
	local m = MineConfig.veinSizeMean(t)
	if m >= 12 then
		table.insert(huge, t)
	end
	if m < 8 then
		sub8 += 1
	end
	if b.hi >= 6 then
		table.insert(big, t)
	elseif b.lo <= 2 then
		solo += 1
	else
		mid += 1
	end
end
-- "THE HIGHEST AVERAGE SHOULD BE 12-14 [WITH *MAYBE* ONE OR 2 ORES"
check("one or two ores average 12-14", #huge >= 1 and #huge <= 2,
	string.format("%d ores: tiers %s", #huge, table.concat(huge, ",")))
do
	local top = 0
	for t = 1, n do top = math.max(top, MineConfig.veinSizeMean(t)) end
	check("the biggest average lands in 12-14", top >= 12 and top <= 14,
		string.format("%.2f", top))
end
-- "90% SHOULD BE SUB 8"
check("at least 90% of the roster averages under 8", sub8 >= n * 0.9,
	string.format("%d of %d (%.0f%%)", sub8, n, sub8 / n * 100))
check("a handful of ores reach 6+, not a band", #big >= 2 and #big <= 8,
	string.format("%d ores: tiers %s", #big, table.concat(big, ",")))
-- The bulk still has to sit at 3-4; without this the gentle end of the curve
-- quietly drags half the roster down to ones and twos, which it did at
-- VEIN_TAIL_POWER_SMALL = 2.
check("most of the roster groups in 3-4", mid > n / 2,
	string.format("%d of %d ores in 3-4", mid, n))
check("the rarest ores still come in ones and twos", solo > 0,
	string.format("%d ores in 1-2", solo))

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
-- Larger than VEIN_MAX, not larger than 8: a 13-block vein is deliberate now, so
-- the only suspicious cluster is one bigger than any single vein can be, which
-- means two veins of the same ore grew into each other.
check("clusters larger than VEIN_MAX are rare (touching veins of the same ore)",
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
local sawMid = {}
for s = 3, 4 do sawMid[s] = sizes[s] or 0 end
--[[
	Sizes past the old eight-block ceiling must actually reach the ground.

	This replaces a check that 6, 7 AND 8 each occur, which encoded the retired
	three-band design where the big ores spanned exactly 6-8. The big end is a
	12-14 average now, so the question is whether anything above 8 is placed at
	all -- if veinGrow's box were too small, or the anchor clamp wrong, big veins
	would be silently truncated into mid ones and every density check here would
	still pass. That is exactly the failure mode the note above describes.
]]
do
	local over8, biggest = 0, 0
	for s, k in pairs(sizes) do
		if s > 8 then over8 += k end
		if k > 0 then biggest = math.max(biggest, s) end
	end
	check("veins larger than 8 blocks actually get placed", over8 > 0,
		string.format("%d clusters over 8, biggest %d", over8, biggest))
	check("and they are not truncated well short of the 12-14 average",
		biggest >= 10, "biggest placed " .. tostring(biggest))
end
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

--[[
	THE MINE MUST NOT BE THE SAME MINE EVERY TIME.

	Owner, 2026-10-06: "the mine isnt random anymore... every time i join 4
	halite on top of the line". It was exactly that: veinOreAt is positional by
	design, and the only thing seeding it was a hash of the zone's NAME, which
	never changes. Every server and every rejoin produced a byte-identical ore
	layout.

	The per-zone layout salt reaches it now. Two salts must give two different
	mines -- and the same salt must still give the same mine, because that is
	what lets a block regenerate into what it was an hour later.
]]
do
	local function layout(salt)
		MineConfig.setVeinSalt("meadow", salt)
		local hits = {}
		for y = 1, 120 do
			for x = 0, 11 do
				for z = 0, 11 do
					local o = MineConfig.veinOreAt("meadow", x, y, z, 1)
					if o then
						table.insert(hits, x .. ":" .. y .. ":" .. z .. "=" .. o.id)
					end
				end
			end
		end
		return table.concat(hits, ","), #hits
	end
	local a, naa = layout(12345)
	local b, nbb = layout(987654321)
	local a2 = layout(12345)
	check("a different layout salt gives a different mine", a ~= b,
		string.format("%d vs %d ore blocks in the same volume", naa, nbb))
	check("the same salt gives the same mine, so regen is stable", a == a2)
	check("both layouts still produce ore", naa > 0 and nbb > 0)
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
