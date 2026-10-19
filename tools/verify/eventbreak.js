// EVENT HORIZON MUST BE MINEABLE, AND ONLY BY EVENT TOOLS.
//
// Found 2026-10-08 by a verification sweep, then confirmed adversarially: NOT
// ONE BLOCK in zone 11 could be broken by any tool in the game. Zone 11 demanded
// breaking power 1000 at every layer and every Event Horizon tool resolved to 1.
// The free Wormhole Bag claim handed a player a mine they could never use, and
// the event window was live while that was true.
//
// Two separate mistakes made it, and this harness exists because neither looked
// like a bug:
//
//   The comment in MineBreaking said zone 11 "simply clamps at MAX" as though
//   clamping were an exemption. MAX is the HARDEST requirement in the game, so
//   the clamp was the wall.
//
//   MineHorizonTools rows carry `tier` and `power` but no `breakingPower` and
//   no `oreId`, so toolBreakingPower fell through to the shop-pick fallback:
//   tonumber("eh_shallow_pick") is nil, rung 1, SHOP_POWER[1] = 1.
//
// tools/verify/breaking.js never caught it because it loops zi only up to
// MineBreaking.ZONES, which is 10. Zone 11 was never exercised by anything.
//
// Run: node tools/verify/eventbreak.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const BRK = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineBreaking.luau"));
const HOR = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineHorizonTools.luau"));

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

console.log("eventbreak: zone 11 is mineable, and event tools outrank the whole ore ladder");

ok(/MineBreaking\.EVENT_ZONE\s*=\s*\d+/.test(BRK), "the event zone is a named constant, not a literal at call sites");
ok(/MineBreaking\.EVENT_MAX = MineBreaking\.EVENT_FLOOR/.test(BRK),
  "EVENT_MAX is DERIVED from what the deepest layer demands",
  "hardcoding it put the top tool 9x above anything depth asked for");
ok(/if tool\.eventOnly then/.test(BRK), "toolBreakingPower has an event branch");
// Order matters: the stamped branch clamps to MAX, which would put an event
// tool straight back under the event floor.
const evAt = BRK.indexOf("if tool.eventOnly then");
const stampAt = BRK.indexOf("local stamped = tonumber(tool.breakingPower");
ok(evAt > -1 && stampAt > evAt,
  "the event branch is checked BEFORE the stamped branch",
  "stamped clamps to MAX, which is below the event floor");
ok(/eventOnly = true/.test(HOR), "Horizon rows are marked eventOnly");

if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU)) {
  console.log("  " + Luau.missing("luau"));
  console.log(fails === 0 ? ">>> eventbreak OK (static only)" : `>>> ${fails} FAILED`);
  process.exit(fails === 0 ? 0 : 1);
}

const block = (src, head, close) => {
  const L = src.split("\n");
  const i = L.findIndex((l) => l.startsWith(head));
  if (i < 0) throw new Error("not found: " + head);
  for (let j = i; j < L.length; j++) if (L[j] === close) return L.slice(i, j + 1).join("\n");
  throw new Error("unterminated: " + head);
};
const line = (src, head) => {
  const L = src.split("\n");
  const out = L.filter((l) => l.startsWith(head));
  if (!out.length) throw new Error("no line: " + head);
  return out.join("\n");
};
// The constants are multi-line expressions; take the whole block between the
// first dial and the end of the derived EVENT_MAX.
// Strip BLOCK comments too, not just `--` lines. A --[[ ]] body's interior
// lines do not start with --, so a line filter pulls comment prose straight
// into the generated Luau and it dies on the first stray word.
const consts = (() => {
  const L = BRK.split("\n");
  const a = L.findIndex((l) => l.startsWith("MineBreaking.ZONES"));
  const b = L.findIndex((l) => l.startsWith("\t+ math.floor((MineBreaking.MAX_LAYER - 1) / MineBreaking.EVENT_LAYERS_PER_RUNG)"));
  if (a < 0 || b < 0) throw new Error("constant block not found");
  const out = [];
  let inBlock = false;
  for (const l of L.slice(a, b + 1)) {
    if (inBlock) {
      if (/\]\]/.test(l)) inBlock = false;
      continue;
    }
    if (/^\s*--\[\[/.test(l)) {
      if (!/\]\]/.test(l)) inBlock = true;
      continue;
    }
    if (/^\s*--/.test(l)) continue;
    out.push(l);
  }
  return out.join("\n");
})();

// LAYERS_PER_RUNG (46), ORE_POW (80) and ZONE_STEP (140) are declared EARLIER
// in the file than ZONES (221), so the contiguous slice below misses them and
// MAX comes out nil. Pulled by name rather than widening the slice, which would
// drag in a hundred lines of unrelated dials.
// EVENT_RUNGS is declared the other side of the slice, just above
// eventStrength, so it is pulled by name as well.
const earlyDials = ["MineBreaking.LAYERS_PER_RUNG", "MineBreaking.ORE_POW", "MineBreaking.ZONE_STEP",
  "MineBreaking.EVENT_RUNGS"]
  .map((k) => line(BRK, k + " =")).join("\n");

const harness = `local MineBreaking = {}
${earlyDials}
${consts}
${block(BRK, "local function clampInt(", "end")}
${block(BRK, "function MineBreaking.layerStrength(", "end")}
${block(BRK, "function MineBreaking.oreStrength(", "end")}
${block(BRK, "function MineBreaking.eventStrength(", "end")}
${block(BRK, "function MineBreaking.toolBreakingPower(", "end")}

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

local EZ = MineBreaking.EVENT_ZONE
local FLOOR, EMAX = MineBreaking.EVENT_FLOOR, MineBreaking.EVENT_MAX
local RUNGS = MineBreaking.EVENT_RUNGS

print(string.format("  normal MAX %d | event floor %d | event max %d | rungs %d",
	MineBreaking.MAX, FLOOR, EMAX, RUNGS))

-- ---------------------------------------- the bug: zone 11 was unbreakable --
local function horizonTool(tier, rungs)
	-- Exactly the shape MineHorizonTools builds: tier, power and the stamped
	-- rungs, with no breakingPower and no oreId. This is what used to
	-- resolve to 1.
	return { id = "eh_x_pick", family = "pickaxe", tier = tier,
		rungs = rungs or RUNGS, power = 10, eventOnly = true }
end

--[[
	THE THREE FAMILIES ARE DIFFERENT LENGTHS, and that is the trap here.

	tier in MineHorizonTools is assigned per family, and measured live the
	families are 12 pickaxes, 38 drills and 88 explosives. A single shared rung
	count flattens the two longer ladders: at 20, every drill from tier 20 and
	every explosive from tier 20 clamps to the same strength, so two thirds of
	the explosive ladder would be identical and nobody would notice from the
	numbers alone.
]]
for _, fam in ipairs({ { "pickaxe", 12 }, { "drill", 38 }, { "explosive", 88 } }) do
	local name, n = fam[1], fam[2]
	local lo = MineBreaking.toolBreakingPower(horizonTool(1, n), 82)
	local hi = MineBreaking.toolBreakingPower(horizonTool(n, n), 82)
	check(("the %s ladder spans the whole event range"):format(name),
		lo == FLOOR and hi == EMAX, string.format("%d..%d against %d..%d", lo, hi, FLOOR, EMAX))
	local flat = 0
	for t = 2, n do
		if MineBreaking.toolBreakingPower(horizonTool(t, n), 82)
			== MineBreaking.toolBreakingPower(horizonTool(t - 1, n), 82) then
			flat += 1
		end
	end
	check(("no two %s rungs share a strength"):format(name), flat == 0,
		string.format("%d of %d rungs are duplicates", flat, n))
end
check("a tier-1 Horizon tool is no longer breaking power 1",
	MineBreaking.toolBreakingPower(horizonTool(1), 82) > 1,
	"it was SHOP_POWER[1] = 1 against rock needing 1000")
check("the weakest event tool clears the event's first layer",
	MineBreaking.toolBreakingPower(horizonTool(1), 82) >= MineBreaking.layerStrength(EZ, 1))
check("the strongest event tool reaches the event floor",
	MineBreaking.toolBreakingPower(horizonTool(RUNGS), 82) >= MineBreaking.layerStrength(EZ, MineBreaking.MAX_LAYER))

-- Every rung must clear SOME depth, or a tool on the ladder is dead weight.
do
	local dead = {}
	for t = 1, RUNGS do
		if MineBreaking.toolBreakingPower(horizonTool(t), 82) < MineBreaking.layerStrength(EZ, 1) then
			table.insert(dead, t)
		end
	end
	check("no event rung is too weak for the event's own surface", #dead == 0,
		#dead > 0 and ("rungs " .. table.concat(dead, ",")) or "all " .. RUNGS .. " clear layer 1")
end

-- ------------------------------------------- progression inside the event --
--[[
	The failure a hardcoded ceiling caused: with EVENT_MAX = MAX * 10, the top
	tool sat 9x above anything depth asked for, so every rung from 2 up cleared
	the whole zone and the event had no ladder at all.
]]
do
	local reach = {}
	for t = 1, RUNGS do
		local bp = MineBreaking.toolBreakingPower(horizonTool(t), 82)
		local deepest = 1
		for l = 1, MineBreaking.MAX_LAYER, 5 do
			if bp >= MineBreaking.layerStrength(EZ, l) then deepest = l end
		end
		reach[t] = deepest
	end
	local climbs = true
	for t = 2, RUNGS do
		if reach[t] <= reach[t - 1] then climbs = false end
	end
	check("every event rung reaches strictly deeper than the one below", climbs,
		string.format("rung 1 -> layer %d, rung %d -> layer %d", reach[1], RUNGS, reach[RUNGS]))
	check("the first rung does NOT already clear the whole event", reach[1] < MineBreaking.MAX_LAYER,
		string.format("rung 1 stops at layer %d", reach[1]))
end

-- ------------------------------------- event tools outrank the ore ladder --
check("the weakest event tool beats the best ore tool",
	MineBreaking.toolBreakingPower(horizonTool(1), 82) > MineBreaking.oreStrength(82, 82),
	string.format("%d vs %d", MineBreaking.toolBreakingPower(horizonTool(1), 82),
		MineBreaking.oreStrength(82, 82)))

-- ----------------------------- and the normal ladder is completely untouched --
--[[
	The whole normal game runs through layerStrength. If the event branch leaked
	into zones 1-10 it would move every block's strength in the game, so this is
	checked exhaustively rather than at a couple of spots.
]]
do
	local moved = nil
	for zi = 1, MineBreaking.ZONES do
		for _, l in ipairs({ 1, 2, 50, 51, 499, 500, 2500, 4999, 5000 }) do
			local want = math.clamp(1 + (zi - 1) * MineBreaking.ZONE_STEP
				+ math.floor((l - 1) / MineBreaking.LAYERS_PER_RUNG), 1, MineBreaking.MAX)
			if MineBreaking.layerStrength(zi, l) ~= want then
				moved = string.format("zone %d layer %d: %d not %d", zi, l,
					MineBreaking.layerStrength(zi, l), want)
			end
		end
	end
	check("zones 1-10 are byte-for-byte unchanged", moved == nil, moved or "all sampled points match")
	check("the best ore tool still exactly reaches the normal mine floor",
		MineBreaking.oreStrength(82, 82) == MineBreaking.layerStrength(MineBreaking.ZONES, MineBreaking.MAX_LAYER))
end

-- An ore tool must NOT be able to mine the event, or the event ladder is
-- pointless and the free claim means nothing.
check("the best ore tool cannot break the event's easiest layer",
	MineBreaking.oreStrength(82, 82) < MineBreaking.layerStrength(EZ, 1),
	string.format("%d vs %d", MineBreaking.oreStrength(82, 82), MineBreaking.layerStrength(EZ, 1)))

print(fails == 0 and ">>> eventbreak OK" or (">>> " .. fails .. " FAILED"))
`;

const tmp = path.join(require("os").tmpdir(), "eventbreak-harness.luau");
fs.writeFileSync(tmp, harness);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" });
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
}
process.stdout.write(out);
if (!/>>> eventbreak OK/.test(out)) fails++;

console.log(fails === 0 ? ">>> eventbreak OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
