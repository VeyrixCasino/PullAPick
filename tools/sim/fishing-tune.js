// THE LEARNING MACHINE for the fishing fight (TODO A3).
//
// Owner, 2026-10-10: "test with a little shitty learning machine, and figure
// out whats the brink of possibility, and tone down from there".
//
// So this:
//   1. trains a bot to play MineFishingFight -- a small policy (how much
//      tension to allow on each colour, when to panic about distance, how to
//      tap through a run) found by the cross-entropy method, on the REAL
//      fight module run in luau;
//   2. finds the BRINK: the hardest fish (MineFishingFight.fishFromDifficulty)
//      a perfect-reflex bot still lands half the time, with the reference rod;
//   3. tones down from there: each grade's difficulty is set so a HUMAN-like
//      bot with the reference rod lands it TARGET[grade] of the time (never
//      above the brink) -- a 5-star fish is "usually human error and you fuck
//      it" (owner);
//   4. reports how often a HUMAN-like bot (a reaction delay and a shaky read
//      of the tension bar, also trained) lands each grade, with each rod.
//
// It writes docs/FISHING-TUNING.md and prints the DIFFICULTY row to paste
// into MineFishing. Takes a few minutes.
//
//   node tools/sim/fishing-tune.js            full run
//   node tools/sim/fishing-tune.js --quick    fewer episodes, for a smoke test
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("../verify/_luau");

const ROOT = path.resolve(__dirname, "../..");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8").replace(/\r\n/g, "\n");
if (!Luau.ready) { console.log(Luau.missing("luau")); process.exit(1); }
const QUICK = process.argv.includes("--quick");

// Tuning choices, stated here so the report can print them. PROPOSED.
// The 5-star fish: a human-like player with the reference rod lands it this
// often ("usually results in human error and you fuck it" -- owner) ...
const TOP_TARGET = 0.35;
// ... and it is never more than this share of the brink (tone down from it).
const TOP_CAP = 0.95;
// The 1-star fish's difficulty: a quick, near-certain catch.
const BOTTOM = 0.08;
// A committed Greyvein fisher: the second rod, ten levels in, no prestige yet.
const REF_ROD = { id: "quarry_rod", level: 10 };
const ROD_ROWS = [
  { id: "twig_rod", level: 0 },
  { id: "twig_rod", level: 10 },
  { id: "quarry_rod", level: 10 },
  { id: "quarry_rod", level: 20 },
  { id: "deepline_rod", level: 30 },
  { id: "trawler_rod", level: 50 },
];
const HUMAN = { delay: 7, noise: 0.06 }; // ~230 ms reactions, +-0.06 on the bar
const CEM = QUICK
  ? { iters: 5, pop: 16, elite: 4, eps: 24, evalEps: 80 }
  : { iters: 10, pop: 28, elite: 6, eps: 60, evalEps: 400 };

const fight = read("src/ReplicatedStorage/Mine/Shared/MineFishingFight.luau");
const fishing = read("src/ReplicatedStorage/Mine/Shared/MineFishing.luau");

const harness = `
Color3 = { fromRGB = function(r, g, b) return { r, g, b } end }
local F = (function()
${fight}
end)()
local M = (function()
${fishing}
end)()
math.randomseed(20261011)

-- The bot. theta = { g, y, r, hyst, urgDist, urgBoost, tapOn, tapOff }.
local LO = { 0.05, 0.05, 0.0, 0.0, 60, 0.0, 1, 0 }
local HI = { 1.0, 1.0, 1.0, 0.5, 100, 0.4, 12, 24 }
local function clampTheta(t)
	local o = {}
	for i = 1, #LO do o[i] = math.clamp(t[i], LO[i], HI[i]) end
	return o
end

local function play(theta, params, delay, noise)
	local s = F.new(params)
	local hist = {}
	local reeling, phase = false, 0
	local tapOn, tapOff = math.floor(theta[7] + 0.5), math.floor(theta[8] + 0.5)
	while true do
		hist[s.tick] = { c = s.colour, t = s.tension, d = s.dist }
		local o = hist[math.max(0, s.tick - delay)]
		local thr = (o.c == "green" and theta[1]) or (o.c == "yellow" and theta[2]) or theta[3]
		if o.d > theta[5] then thr += theta[6] end
		local tn = o.t + (noise > 0 and (math.random() * 2 - 1) * noise or 0)
		if o.c == "red" then
			phase = (phase + 1) % math.max(1, tapOn + tapOff)
			reeling = phase < tapOn and tn < thr
		elseif reeling then
			reeling = tn < thr
		else
			reeling = tn < thr - theta[4]
		end
		hist[s.tick - delay - 2] = nil
		local r = F.step(s, reeling)
		if r then return r, s.tick end
	end
end

local function rate(theta, mk, eps, delay, noise, seed0)
	local caught, ticks = 0, 0
	for e = 1, eps do
		local r, t = play(theta, mk(seed0 + e * 7919), delay, noise)
		if r == "caught" then caught += 1 ticks += t end
	end
	return caught / eps, (caught > 0) and (ticks / caught / F.HZ) or 0
end

local function gauss()
	local u1, u2 = math.max(1e-9, math.random()), math.random()
	return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
end

-- Cross-entropy method: sample, keep the best, refit. WARM-STARTED from the
-- best policy found so far for the same reflexes, and never returns anything
-- worse than it: a fresh CEM run can land in a poor corner, and a rod's table
-- row should not read worse than it is because its training was unlucky.
local KNOWN = {}
local function train(mk, delay, noise)
	local key = delay .. ":" .. noise
	local start = KNOWN[key] or { 0.85, 0.7, 0.35, 0.15, 85, 0.1, 3, 6 }
	local mean = table.clone(start)
	local sd = { 0.2, 0.2, 0.25, 0.1, 12, 0.1, 3, 6 }
	local best, bestScore = mean, -1
	for it = 1, ${CEM.iters} do
		local pop = { { t = start } }
		for k = 2, ${CEM.pop} do
			local t = {}
			for i = 1, #mean do t[i] = mean[i] + sd[i] * gauss() end
			table.insert(pop, { t = clampTheta(t) })
		end
		for _, c in ipairs(pop) do
			local r, secs = rate(c.t, mk, ${CEM.eps}, delay, noise, it * 1000)
			c.s = r - secs / 100000
		end
		table.sort(pop, function(a, b) return a.s > b.s end)
		for i = 1, #mean do
			local m, v = 0, 0
			for k = 1, ${CEM.elite} do m += pop[k].t[i] end
			m /= ${CEM.elite}
			for k = 1, ${CEM.elite} do v += (pop[k].t[i] - m) ^ 2 end
			mean[i] = m
			sd[i] = math.max(math.sqrt(v / ${CEM.elite}), (HI[i] - LO[i]) * 0.02)
		end
		if pop[1].s > bestScore then best, bestScore = pop[1].t, pop[1].s end
	end
	-- Score the mean, the best and the warm start on fresh seeds; keep the best.
	local pick, top = start, rate(start, mk, ${CEM.evalEps}, delay, noise, 777777)
	for _, t in ipairs({ clampTheta(mean), best }) do
		local r = rate(t, mk, ${CEM.evalEps}, delay, noise, 777777)
		if r > top then pick, top = t, r end
	end
	KNOWN[key] = pick
	return pick
end

local function maker(dLo, dHi, rodId, level)
	local st = M.rodStats(rodId, level)
	local rod = { reel = st.reel, line = st.line }
	return function(seed)
		local d = dLo
		if dHi > dLo then
			d = dLo + (dHi - dLo) * ((seed * 0.6180339887) % 1)
		end
		-- Sizes as MineFishing.rollFish rolls them: a uniform roll squared.
		local u = (seed * 0.7548776662) % 1
		return { seed = seed, fish = F.fishFromDifficulty(d), rod = rod, size = u * u }
	end
end

-- The catch rate of a FIXED policy at one difficulty: a smooth curve to read.
local EVAL = ${CEM.evalEps}
local function curve(theta, d, rodId, level, delay, noise)
	return rate(theta, maker(d, d, rodId, level), EVAL, delay, noise, 424242)
end

-- The largest difficulty a fixed policy still lands TARGET of the time.
local function invert(theta, target, rodId, level, delay, noise, hiD)
	local a, b = 0, hiD
	for _ = 1, 12 do
		local mid = (a + b) / 2
		if curve(theta, mid, rodId, level, delay, noise) >= target then a = mid else b = mid end
	end
	return (a + b) / 2
end

local REF, REFL = "${REF_ROD.id}", ${REF_ROD.level}

-- 1. The brink: a general expert first, then a specialist at its brink.
local ex = train(maker(0.2, 2.5, REF, REFL), 0, 0)
local brink0 = invert(ex, 0.5, REF, REFL, 0, 0, 3)
print(string.format("BISECT %.4f general", brink0))
local exS = train(maker(brink0 * 0.9, brink0 * 1.15, REF, REFL), 0, 0)
local brink = math.max(brink0, invert(exS, 0.5, REF, REFL, 0, 0, 3))
print(string.format("BRINK %.4f", brink))

-- 2. The grades. The 5-star fish: where a human-like player with the
-- reference rod lands it TOP_TARGET of the time, and never past TOP_CAP x the
-- brink. The 1-star fish: BOTTOM. The rest step up geometrically between.
local hu = train(maker(0.02, brink, REF, REFL), ${HUMAN.delay}, ${HUMAN.noise})
local top = math.min(${TOP_CAP} * brink, invert(hu, ${TOP_TARGET}, REF, REFL, ${HUMAN.delay}, ${HUMAN.noise}, brink * 1.5))
local diff = {}
for g = 1, 9 do
	diff[g] = ${BOTTOM} * (top / ${BOTTOM}) ^ ((g - 1) / 8)
	print(string.format("GRADE %d %.4f", g, diff[g]))
end
local row = {}
for g = 1, 9 do table.insert(row, string.format("%.3f", diff[g])) end
print("DIFFICULTY " .. table.concat(row, ", "))

-- 3. Each rod: its own expert and human policies, read at every grade.
local rods = { ${ROD_ROWS.map((r) => `{ "${r.id}", ${r.level} }`).join(", ")} }
for _, rd in ipairs(rods) do
	local e = train(maker(0.02, brink * 1.2, rd[1], rd[2]), 0, 0)
	local h = train(maker(0.02, brink * 1.2, rd[1], rd[2]), ${HUMAN.delay}, ${HUMAN.noise})
	for g = 1, 9 do
		local er, es = curve(e, diff[g], rd[1], rd[2], 0, 0)
		local hr, hs = curve(h, diff[g], rd[1], rd[2], ${HUMAN.delay}, ${HUMAN.noise})
		print(string.format("RATE %d %s %d %.3f %.1f %.3f %.1f", g, rd[1], rd[2], er, es, hr, hs))
	end
end
`;
const script = path.join(ROOT, ".luau-bin/fishing-tune.luau");
fs.writeFileSync(script, harness);
console.log("training ... (" + (QUICK ? "quick" : "full") + ")");
const t0 = Date.now();
let out;
try {
  out = execFileSync(Luau.LUAU, ["-O2", script], { encoding: "utf8", maxBuffer: 1 << 26, timeout: 60 * 60 * 1000 });
} catch (e) {
  process.stdout.write(e.stdout || "");
  process.stderr.write(e.stderr || "");
  process.exit(1);
}
const lines = out.split(/\r?\n/).filter(Boolean);
for (const l of lines) if (l.startsWith("BISECT") || l.startsWith("BRINK") || l.startsWith("DIFFICULTY")) console.log(l);
const brink = Number((lines.find((l) => l.startsWith("BRINK ")) || "BRINK 0").split(" ")[1]);
const diffRow = (lines.find((l) => l.startsWith("DIFFICULTY ")) || "").slice(11);
const rates = lines.filter((l) => l.startsWith("RATE ")).map((l) => {
  const [, g, rod, level, e, es, h, hs] = l.split(" ");
  return { g: +g, rod, level: +level, e: +e, es: +es, h: +h, hs: +hs };
});
const STARS = ["★", "★½", "★★", "★★½", "★★★", "★★★½", "★★★★", "★★★★½", "★★★★★"];
const pct = (x) => Math.round(x * 100) + "%";
const head = "| grade | difficulty | " + ROD_ROWS.map((r) => `${r.id.replace("_rod", "")} L${r.level}`).join(" | ") + " |";
const sep = "|---|---|" + ROD_ROWS.map(() => "---").join("|") + "|";
const diffs = diffRow.split(",").map((x) => x.trim());
const tableFor = (key, secsKey) => [head, sep, ...STARS.map((st, i) => {
  const cells = ROD_ROWS.map((r) => {
    const row = rates.find((x) => x.g === i + 1 && x.rod === r.id && x.level === r.level);
    return row ? `${pct(row[key])} · ${Math.round(row[secsKey])}s` : "-";
  });
  return `| ${st} | ${diffs[i] || "-"} | ${cells.join(" | ")} |`;
})].join("\n");

const md = `# Fishing tuning (generated)

Written by \`node tools/sim/fishing-tune.js\` on ${new Date().toISOString().slice(0, 10)}${QUICK ? " (QUICK run: rough numbers)" : ""}.
Do not hand-edit; rerun it after touching \`MineFishingFight\` or the rods.

Owner, 2026-10-10: *"test with a little shitty learning machine, and figure out whats
the brink of possibility, and tone down from there"*.

## What it did

1. Trained a bot (cross-entropy method over a small policy: the tension to allow
   on green, yellow and red, a hysteresis, when to panic about distance, and a tap
   rhythm for runs) on the real \`MineFishingFight\`, run in luau.
2. **The brink.** With the ${REF_ROD.id} at level ${REF_ROD.level}, a perfect-reflex bot lands a fish
   of difficulty **${brink.toFixed(3)}** half the time. Anything harder is out of reach.
3. **Toned down.** The ★★★★★ fish is set where the human-like bot (below) with the
   reference rod lands it ${pct(TOP_TARGET)} of the time, and never past ${TOP_CAP} × the brink. The ★
   fish is ${BOTTOM}, a quick sure catch, and the grades between step up geometrically.
   A fish's fight also follows its size (\`MineFishingFight.spiritOf\`), so every cell
   below averages small and big catches as they are rolled. PROPOSED numbers. The row
   for \`MineFishing.DIFFICULTY\`:

   \`{ ${diffRow} }\`

4. Measured each grade with each rod, for the expert bot and a HUMAN-like bot (it
   reacts ${HUMAN.delay} ticks late, about ${Math.round(HUMAN.delay / 30 * 1000)} ms, and reads the tension bar ±${HUMAN.noise};
   also trained). Cells are catch rate · mean seconds to land.

## Human-like bot

${tableFor("h", "hs")}

## Perfect-reflex bot

${tableFor("e", "es")}

Took ${Math.round((Date.now() - t0) / 1000)} s.
`;
fs.writeFileSync(path.join(ROOT, "docs/FISHING-TUNING.md"), md);
console.log("wrote docs/FISHING-TUNING.md");
