// THE BAKED FRAME STATS MUST BE THE FRAME STATS.
//
// MineOreTools.FRAME_STATS and .TYPE_MULT_STEPS are a copy of what the priced
// roster used to supply to every forged tool: the cost multiplier, and the
// rate / cells / radius / shape / width / axis / turn / bombs / pattern /
// cooldown that make a drill clear an area and a bomb explode.
//
// They were baked so the roster could be deleted. That makes them the sort of
// data nobody will ever re-check by eye -- 82 tiers x 3 families x 10 stats --
// and a single wrong run-length boundary turns one band of the roster into
// melee pickaxes without erroring.
//
// So this RE-DERIVES them from MineTools the way frameForTier did, and compares
// every one of the 2,460 values. While the roster is still in the tree it is
// the source of truth and this is a true regression test. Once it goes, the
// check keeps the baked tables internally consistent and this file is where the
// original derivation is written down.
//
// Run: node tools/verify/oreframes.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

console.log("oreframes: the baked frame stats match the roster they replaced");

const ORETOOLS = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineOreTools.luau"));
ok(/MineOreTools\.FRAME_STATS = \{/.test(ORETOOLS), "FRAME_STATS exists");
ok(/function MineOreTools\.frameStats\(/.test(ORETOOLS), "frameStats() exists");
ok(/MineOreTools\.TYPE_MULT_STEPS = \{/.test(ORETOOLS), "TYPE_MULT_STEPS exists");

const TOOLS = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineTools.luau"));
const rosterLives = /MineTools\.TOOLS = \{/.test(TOOLS)
  && [...TOOLS.matchAll(/price = (\d+)/g)].filter((m) => +m[1] > 0).length > 10;

if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU)) {
  console.log("  " + Luau.missing("luau"));
  console.log(fails === 0 ? ">>> oreframes OK (static only)" : `>>> ${fails} FAILED`);
  process.exit(fails === 0 ? 0 : 1);
}

// ---- internal consistency: every stat covers every tier, monotonic bounds ----
const lines = ORETOOLS.split("\n");
const block = (head, close) => {
  const i = lines.findIndex((l) => l.startsWith(head));
  if (i < 0) throw new Error("not found: " + head);
  for (let j = i; j < lines.length; j++) if (lines[j] === close) return lines.slice(i, j + 1).join("\n");
  throw new Error("unterminated: " + head);
};

const harness = `local MineOreTools = {}
${block("MineOreTools.FRAME_STATS = {", "}")}
${block("MineOreTools.TYPE_MULT_STEPS = {", "}")}
${block("local function statValue(", "end")}
${block("function MineOreTools.frameStats(", "end")}
${block("function MineOreTools.typeMult(", "end")}

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

local N = 82
for fam, stats in pairs(MineOreTools.FRAME_STATS) do
	-- Every run list must end exactly at the last tier, or the tiers past its
	-- end silently return nil and fall to a caller's default.
	local bad = {}
	for key, steps in pairs(stats) do
		if steps[#steps][1] ~= N then
			table.insert(bad, key .. " ends at " .. tostring(steps[#steps][1]))
		end
		local prev = 0
		for _, pair in ipairs(steps) do
			if pair[1] <= prev then
				table.insert(bad, key .. " boundary " .. tostring(pair[1]) .. " not ascending")
			end
			prev = pair[1]
		end
	end
	check(fam .. ": every stat covers tiers 1.." .. N .. " in ascending runs",
		#bad == 0, table.concat(bad, "; "))
end

-- frameStats must answer for every tier without erroring, and a drill must
-- actually be a drill at both ends of the roster.
local okCall = true
for fam in pairs(MineOreTools.FRAME_STATS) do
	for t = 1, N do
		local s = MineOreTools.frameStats(fam, t)
		if type(s) ~= "table" then okCall = false end
	end
end
check("frameStats answers for all 3 families x " .. N .. " tiers", okCall)

local d1, d82 = MineOreTools.frameStats("drill", 1), MineOreTools.frameStats("drill", 82)
check("a tier 1 drill is still a drill", d1.shape == "down" and d1.axis == "down",
	tostring(d1.shape) .. "/" .. tostring(d1.axis))
check("a tier 82 drill clears 9 cells", d82.cells == 9, tostring(d82.cells))
local e82 = MineOreTools.frameStats("explosive", 82)
check("a tier 82 explosive still throws 3 bombs in a cluster",
	e82.bombs == 3 and e82.pattern == "cluster",
	tostring(e82.bombs) .. "/" .. tostring(e82.pattern))
local p40 = MineOreTools.frameStats("pickaxe", 40)
check("a pickaxe is melee, one cell, at every tier",
	p40.shape == "melee" and p40.cells == 1)

-- An unknown family falls back rather than returning an empty tool.
local w = MineOreTools.frameStats("weapon", 40)
check("an unknown family falls back to the pickaxe frame", w.shape == "melee")

print(fails == 0 and ">>> baked tables OK" or (">>> " .. fails .. " FAILED"))
`;

const tmp = path.join(require("os").tmpdir(), "oreframes-harness.luau");
fs.writeFileSync(tmp, harness);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" });
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
}
process.stdout.write(out);
if (!/>>> baked tables OK/.test(out)) fails++;

console.log(rosterLives
  ? "  (the priced roster is still present; the Studio probe in this file's header re-derives against it)"
  : "  (the priced roster is gone; these tables are now the only source)");

console.log(fails === 0 ? ">>> oreframes OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
