// THE TOOL THE SERVER HANDS THE BREAKING GATE MUST KNOW WHAT IT IS MADE OF.
//
// MineBreaking.toolBreakingPower resolves in three steps, in order:
//
//   1. a stamped `breakingPower` / `bp`
//   2. `oreId` or `ore` present  -> derive from the ore's tier
//   3. otherwise                 -> a shop rung off `rung` / `id`
//
// equippedTool() synthesises the row for a forged ore tool per swing, and that
// row had NONE of the three: no stamped power, no ore id, no `tier`, and an
// `id` of "oretool_<uid>" that tonumber cannot parse. So every forged tool in
// the game resolved to SHOP_POWER[1] -- which is 1, the weakest pick there is.
//
// Nothing reported it. A blocked swing is silent by design: it simply does no
// damage. With ZONE_STEP at 100 that walls a player a few hundred layers into
// zone 1 regardless of what they forged, so the whole ore ladder was unusable
// from the moment the gate began to be enforced.
//
// That is a hole a reader cannot see, because it is three fields NOT being
// there. This asserts the fields exist, and -- more usefully -- EXECUTES the
// real toolBreakingPower against the real row shape, so it fails if either side
// is changed without the other.
//
// It also guards the migration stamps, which had the mirror-image bug: `~= 1`
// is only "has not run" while 1 is the newest version, so every profile stamped
// 2 re-ran the V1 pass and reset itself to 1, which made the V2 guard fire too.
// Both migrations re-ran on every load, forever.
//
// Run: node tools/verify/heldtool.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const SRV = Luau.readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineServer.server.luau"));
const BRK = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineBreaking.luau"));

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

console.log("heldtool: the forged row carries its ore, and migrations run once");

// ---------------------------------------------- the row equippedTool returns --
// The `return { ... }` inside equippedTool's ore-tool branch.
const row = /oreTool = true/.test(SRV)
  ? /return \{\s*\n\s*id = "oretool_[\s\S]*?\n\t\t\t\}/.exec(SRV)
  : null;
ok(!!row, "the synthesised ore-tool row is findable in equippedTool");
if (row) {
  ok(/oreTier\s*=/.test(row[0]), "the row carries oreTier",
    "without it toolBreakingPower cannot derive from the ore");
  ok(/oreId\s*=/.test(row[0]), "the row carries oreId",
    "this is the field that selects the derive branch at all");
}

// ------------------------------------------- migrations are monotonic --
ok(!/if p\.oreRosterV ~= 1 then/.test(SRV),
  "the V1 migration guard is not `~= 1`",
  "a profile stamped 2 would re-run it and reset itself to 1");
ok(/\(tonumber\(p\.oreRosterV\) or 0\) < 1 then/.test(SRV),
  "the V1 guard tests older-than, not not-equal");
ok(!/if p\.oreRosterV ~= \(C\.ORE_ROSTER_V/.test(SRV),
  "the V2 migration guard is not `~=` either");
ok(/\(tonumber\(p\.oreRosterV\) or 0\) < \(C\.ORE_ROSTER_V/.test(SRV),
  "the V2 guard tests older-than too");

// --------------------------------- EXECUTE the real resolver on the real row --
if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU)) {
  console.log("  (luau not runnable here; skipped the executed half)");
} else {
  const lines = BRK.split("\n");
  const block = (head, close) => {
    const i = lines.findIndex((l) => l.startsWith(head));
    if (i < 0) throw new Error("not found: " + head);
    for (let j = i; j < lines.length; j++) if (lines[j] === close) return lines.slice(i, j + 1).join("\n");
    throw new Error("unterminated: " + head);
  };
  //[[ Constants here are not all one-liners. MineBreaking.MAX is DERIVED over
  // three lines -- "= 1" then two indented "+ ..." continuations -- and taking
  // only its first line set MAX to 1, which made oreStrength return 1 for every
  // tier and the harness "fail" on code that was fine. Consume the
  // continuations: keep taking lines while they are indented. ]]
  const assign = (name) => {
    const i = lines.findIndex((l) => l.startsWith("MineBreaking." + name + " ="));
    if (i < 0) throw new Error("not found: MineBreaking." + name);
    const out = [lines[i]];
    for (let j = i + 1; j < lines.length && /^\s+[+\-*/]/.test(lines[j]); j++) out.push(lines[j]);
    return out.join("\n");
  };

  const harness = `local MineBreaking = {}
${assign("ORE_POW")}
${assign("ZONE_STEP")}
${assign("ZONES")}
${assign("MAX_LAYER")}
${assign("LAYERS_PER_RUNG")}
${assign("MAX")}
${assign("SHOP_POWER")}
${block("local function clampInt(", "end")}
${block("function MineBreaking.oreStrength(", "end")}
${block("function MineBreaking.toolBreakingPower(", "end")}

-- The derived ceiling must survive the slicing, or every assertion below is
-- measuring a constant this harness invented rather than the game's.
assert(MineBreaking.MAX > 100, "MAX came out as " .. tostring(MineBreaking.MAX)
	.. " -- the multi-line derivation was not sliced whole")

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

-- The row as equippedTool builds it TODAY, field for field.
local function forgedRow(tier)
	return {
		id = "oretool_abc123", uid = "abc123", name = "Ore Tool",
		family = "pickaxe", oreTier = tier, oreId = "someore",
		power = 100, level = 5, oreTool = true, finish = "Normal",
	}
end
-- And as it was before the fix, to show the failure is real.
local function brokenRow(tier)
	return {
		id = "oretool_abc123", uid = "abc123", name = "Ore Tool",
		family = "pickaxe", power = 100, level = 5, oreTool = true,
	}
end

local N = 82
check("the old row shape resolves to 1, the weakest pick in the game",
	MineBreaking.toolBreakingPower(brokenRow(82), N) == 1,
	"tier 82 forged tool -> " .. tostring(MineBreaking.toolBreakingPower(brokenRow(82), N)))

local low = MineBreaking.toolBreakingPower(forgedRow(1), N)
local high = MineBreaking.toolBreakingPower(forgedRow(82), N)
check("a tier 1 forged tool is weak", low >= 1, tostring(low))
check("a tier 82 forged tool is strong", high > low * 4,
	string.format("tier1 %d vs tier82 %d", low, high))

-- Monotonic across the whole roster: a deeper ore must never break less.
local prev, mono = 0, true
for t = 1, N do
	local bp = MineBreaking.toolBreakingPower(forgedRow(t), N)
	if bp < prev then mono = false end
	prev = bp
end
check("breaking power never decreases as ore tier rises", mono)

-- A stamped value still wins, which is what keeps an already-forged tool from
-- changing in a player's hands if the roster moves.
local stamped = forgedRow(1)
stamped.breakingPower = 7
check("an explicit stamped breakingPower still outranks the ore",
	MineBreaking.toolBreakingPower(stamped, N) == 7)

print(fails == 0 and ">>> resolver OK" or (">>> " .. fails .. " FAILED"))
`;
  const tmp = path.join(require("os").tmpdir(), "heldtool-harness.luau");
  fs.writeFileSync(tmp, harness);
  let out = "";
  try {
    out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" });
  } catch (e) {
    out = (e.stdout || "") + (e.stderr || "");
  }
  process.stdout.write(out);
  if (!/>>> resolver OK/.test(out)) fails++;
}

console.log(fails === 0 ? ">>> heldtool OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
