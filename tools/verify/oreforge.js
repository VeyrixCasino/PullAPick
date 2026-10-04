// A forged tool IS its ore.
//
// Owner, 2026-10-03, on first seeing the Forge: "everything in forge should be
// called {ore} {tool}", "i want crafting to be sorted by the actual ore", "i
// dont want different tools to cost different ores. If i want to upgrade my
// stone pick, it should cost stone, at an increasing amount each time."
//
// The rule that makes all of that hold is that the FRAME IS DERIVED from the
// ore's tier instead of being chosen. This runs the real MineOreTools against
// the real rosters and asserts the properties that derivation has to have, then
// checks the two callers still obey it.
//
//   node tools/verify/oreforge.js
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = path.resolve(__dirname, "../..");
const LUAU = path.join(ROOT, ".luau-bin/luau");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8");
if (!fs.existsSync(LUAU)) {
  console.log("luau not present (.luau-bin/luau) — run tools/verify/syntax.sh first; skipping");
  process.exit(0);
}

const mod = read("src/ReplicatedStorage/Mine/Shared/MineOreTools.luau");
const tools = read("src/ReplicatedStorage/Mine/Shared/MineTools.luau");
const cfg = read("src/ReplicatedStorage/Mine/Shared/MineConfig.luau");
const forge = read("src/ReplicatedStorage/Mine/Shared/MineForge.luau");
const server = read("src/ServerScriptService/Mine/MineServer.server.luau");

// The ore roster's real size: frameForTier maps 1..ORE_COUNT onto the rungs.
const oreCount = (cfg.match(/MineConfig\.ORES = \{([\s\S]*?)\n\}/) || ["", ""])[1]
  .split("\n").filter((l) => /\{\s*id = "/.test(l)).length;

// The real rungs, per family, verbatim from MineTools.TOOLS.
const toolsBlock = (tools.match(/MineTools\.TOOLS = \{([\s\S]*?)\n\}\n/) || ["", ""])[1];
const families = {};
let fam = null;
for (const line of toolsBlock.split("\n")) {
  const f = line.match(/^\t(\w+) = \{/);
  if (f) { fam = f[1]; families[fam] = []; continue; }
  if (fam && /\{\s*id = "/.test(line)) families[fam].push(line.trim().replace(/,$/, ""));
}
if (oreCount < 80 || !families.pickaxe || families.pickaxe.length < 10) {
  console.error(`FAIL could not parse rosters (ores=${oreCount}, pickaxes=${(families.pickaxe||[]).length})`);
  process.exit(1);
}
console.log(`  ${oreCount} ores, ${Object.keys(families).length} families read verbatim`);

// The functions under test, sliced out rather than reimplemented.
const slice = (re, what) => {
  const m = mod.match(re);
  if (!m) { console.error(`FAIL could not find ${what} in MineOreTools`); process.exit(1); }
  return m[0];
};
const fns = [
  slice(/function MineOreTools\.familyNoun\(familyId\)[\s\S]*?\nend\n/, "familyNoun"),
  slice(/function MineOreTools\.frames\(familyId\)[\s\S]*?\nend\n/, "frames"),
  slice(/function MineOreTools\.frameForTier\(familyId, oreTier\)[\s\S]*?\nend\n/, "frameForTier"),
  slice(/function MineOreTools\.name\(oreDef, familyId, trait\)[\s\S]*?\nend\n/, "name"),
].join("\n");
const noun = slice(/MineOreTools\.NOUN = \{[\s\S]*?\n\}/, "NOUN");

const harness = `
local C = { ORE_COUNT = ${oreCount} }
-- The enchantment prefix has its own check (tools/verify/traits.js). Here it
-- is stubbed to a pass-through so this file keeps testing the ORE half of the
-- name -- a real decorate would make "Stone Pickaxe" depend on the roster too.
local Traits = { decorate = function(name, e) return name end }
local Tools = { TOOLS = {
${Object.entries(families).map(([f, rows]) =>
  `\t${f} = {\n${rows.map((r) => "\t\t" + r + ",").join("\n")}\n\t},`).join("\n")}
} }
local MineOreTools = {}
${noun}
local frameCache = {}
${fns}

local fail = 0
local function check(ok, msg)
	if not ok then fail += 1 print("  FAIL  " .. msg) else print("  ok    " .. msg) end
end

for _, famId in ipairs({ "pickaxe", "drill", "explosive" }) do
	local pool = MineOreTools.frames(famId)
	check(#pool > 0, famId .. ": has a forgeable pool (" .. #pool .. " rungs)")

	-- The free starter is GIVEN. If it ever enters the pool, the cheapest frame
	-- in the game joins the ore economy and the craft verb's id guard becomes
	-- the only thing standing in the way.
	local freebie = 0
	for _, td in ipairs(pool) do
		if (tonumber(td.price) or 0) <= 0 then freebie += 1 end
	end
	check(freebie == 0, famId .. ": no unpriced or free rung is forgeable")

	-- Every ore in the roster must land on a frame, or some ore cannot be made
	-- into a tool at all and the rail has a dead row.
	local nilled, used, seen = 0, 0, {}
	local lastTier, monotonic = -1, true
	for t = 1, C.ORE_COUNT do
		local f = MineOreTools.frameForTier(famId, t)
		if not f then
			nilled += 1
		else
			if not seen[f.id] then seen[f.id] = true used += 1 end
			local ft = tonumber(f.tier) or 0
			if ft < lastTier then monotonic = false end
			lastTier = ft
		end
	end
	check(nilled == 0, famId .. ": every ore tier yields a frame (" .. nilled .. " nil)")

	-- Spread, not a pile on the top rung. "Nearest tier" would park every ore
	-- past rung 24 on the last frame; proportional is the whole point.
	check(used >= math.floor(#pool * 0.9),
		famId .. (": frames spread across the roster (%d of %d used)"):format(used, #pool))

	-- Deeper ore never steps BACK to a shallower frame.
	check(monotonic, famId .. ": frame tier never decreases as ore tier rises")

	-- The endpoints are the endpoints.
	local lo = MineOreTools.frameForTier(famId, 1)
	local hi = MineOreTools.frameForTier(famId, C.ORE_COUNT)
	check(lo and lo.id == pool[1].id, famId .. ": tier 1 wears the first rung")
	check(hi and hi.id == pool[#pool].id, famId .. ": the deepest ore wears the last rung")

	-- Pure: same question, same answer. The panel quotes with this and the verb
	-- charges with it, and they never speak to each other.
	local stable = true
	for t = 1, C.ORE_COUNT do
		local a = MineOreTools.frameForTier(famId, t)
		local b = MineOreTools.frameForTier(famId, t)
		if a ~= b then stable = false end
	end
	check(stable, famId .. ": frameForTier is pure")
end

-- {ore} {tool}, which is the ask in four words.
check(MineOreTools.name({ name = "Stone" }, "pickaxe") == "Stone Pickaxe",
	'name({name="Stone"}, "pickaxe") == "Stone Pickaxe"')
check(MineOreTools.name({ name = "Clay" }, "drill") == "Clay Drill",
	'name({name="Clay"}, "drill") == "Clay Drill"')

if fail > 0 then
	print("")
	print(">>> oreforge: " .. fail .. " FAILED assertion(s)")
else
	print("")
	print(">>> oreforge: all assertions passed")
end
`;

const script = path.join(ROOT, ".luau-bin/oreforge-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try {
  out = execFileSync(LUAU, [script], { encoding: "utf8" });
  process.stdout.write(out);
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
  process.stdout.write(e.stdout || "");
  process.stderr.write(e.stderr || "");
  process.exit(1);
}

// ---- the callers still obey the rule ---------------------------------------
let fail = /FAILED|FAIL /.test(out) ? 1 : 0;
const src = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

const craft = (server.match(/function Verbs\.craftOreTool[\s\S]*?\nend\n/) || [""])[0];
src(craft.length > 200, "found Verbs.craftOreTool");
// Comments stripped first. The first version of this check matched the comment
// SAYING payload.typeId is ignored and reported that it was not -- a check that
// reads prose is a check that fails on honesty.
const code = (lua) => lua.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");
const craftCode = code(craft);
// The client may NAME a frame; the server must not believe it.
src(!/payload\.typeId/.test(craftCode),
  "craftOreTool ignores payload.typeId and derives the frame itself");
src(/OreTools\.frameForTier\(/.test(craft),
  "...via MineOreTools.frameForTier, the same function the panel quotes with");
// The uid bug: `uid` is not a local in this function, so it read as a nil global
// and forging both failed to equip the new tool and unequipped the held one.
src(/p\.oreToolEquipped = row\.uid/.test(craft),
  "craftOreTool equips the row it just made (row.uid, not the nil global uid)");
src(!/if p\.oreToolEquipped == uid then/.test(craft),
  "...and the pasted toggle that read an undeclared `uid` is gone");

// Upgrading charges the tool's OWN ore, growing per level. This was already
// true and is the half of the owner's ask that needed guarding, not fixing.
const up = (server.match(/function Verbs\.upgradeOreTool[\s\S]*?\nend\n/) || [""])[0];
src(/local ore, dust, oreDef = Verbs\._oreToolCost\(tool\)/.test(up),
  "upgradeOreTool prices from the tool's own ore");
src(/p\.ores\[oreId\] = haveOre - spentOre/.test(up),
  "...and spends that same ore");
src(/C\.toolUpgradeCost\(tool\.tier, level \+ i, typeMult\)/.test(up),
  "...stepping the price up per level");

// The panel says {ore} {tool} everywhere, and lists ores rather than frames.
src(/OreTools\.toolName\(tool\)/.test(forge), "the Forge titles a forged tool {ore} {tool}");
src(/OreTools\.name\(row\.def, fam\)/.test(forge), "...and a craft recipe too");
src(/OreTools\.name\(o\.def, selFamily\)/.test(forge), "...and every rail row");
src(!/local function typeMultOf/.test(forge),
  "the Forge's duplicate typeMultOf is gone; MineOreTools owns the rule");
src(/colButton\("SHOP"/.test(forge), "SHOP is a tab on the mode rail");
src(/colButton\("CRAFT"/.test(forge) && /colButton\("UPGRADE"/.test(forge),
  "...beside CRAFT and UPGRADE");

console.log("");
console.log(fail > 0 ? `>>> oreforge: ${fail} FAILED` : ">>> oreforge: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
