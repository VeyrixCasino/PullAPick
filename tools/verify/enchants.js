// An enchantment is a prefix on your tool, and it replaced two systems.
//
// Owner, 2026-10-04: "replace runes with enchantments. Pretty much just walk to
// the enchanter and its a prefix too your tool (Sharp Stone Pickaxe, Lucky
// Stone Drill)" + "and gear aswell".
//
// This runs the REAL MineEnchants -- the whole module, with only its MineStats
// require swapped for the real weights parsed out of MineStats -- and asserts
// the properties the prefix depends on: one word per stat, no collisions, a
// magnitude derived from the stat's own weight, and a price that cannot be
// talked down by a client.
//
//   node tools/verify/enchants.js
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

const mod = read("src/ReplicatedStorage/Mine/Shared/MineEnchants.luau");
const statsSrc = read("src/ReplicatedStorage/Mine/Shared/MineStats.luau");
const oretools = read("src/ReplicatedStorage/Mine/Shared/MineOreTools.luau");
const server = read("src/ServerScriptService/Mine/MineServer.server.luau");

// The real weights, verbatim, so the derivation is tested against live data.
const statBlock = (statsSrc.match(/MineStats\.STATS = \{([\s\S]*?)\n\}/) || ["", ""])[1];
const weights = {};
for (const m of statBlock.matchAll(/^\t(\w+)\s*=\s*\{[^}]*?weight\s*=\s*([\d.]+)/gm)) {
  weights[m[1]] = Number(m[2]);
}
if (Object.keys(weights).length < 15) {
  console.error(`FAIL parsed only ${Object.keys(weights).length} stat weights`);
  process.exit(1);
}
console.log(`  ${Object.keys(weights).length} stat weights read verbatim from MineStats`);

// Run the real module, with only its requires replaced.
const body = mod
  .replace(/local RS = game:GetService\("ReplicatedStorage"\)[\s\S]*?local Stats = require\(shared:WaitForChild\("MineStats"\)\)/,
    "local Stats = STATS_STUB")
  .replace(/\nreturn MineEnchants\s*$/, "\n");
if (/require\(/.test(body)) {
  console.error("FAIL MineEnchants still has a require after stubbing — update this check");
  process.exit(1);
}

const harness = `
local STATS_STUB = { STATS = {
${Object.entries(weights).map(([k, w]) => `\t${k} = { weight = ${w} },`).join("\n")}
} }
${body}

local fail = 0
local function check(ok, msg)
	if not ok then fail += 1 print("  FAIL  " .. msg) else print("  ok    " .. msg) end
end

local E = MineEnchants
check(#E.LIST >= 20, ("the roster has %d enchantments"):format(#E.LIST))

-- The prefix IS the identity the player reads. Two enchantments sharing a word
-- would make two different tools read identically.
local ids, prefixes, stats, dupe = {}, {}, {}, {}
for _, e in ipairs(E.LIST) do
	if ids[e.id] then table.insert(dupe, "id " .. e.id) end
	if prefixes[e.prefix] then table.insert(dupe, "prefix " .. e.prefix) end
	if stats[e.stat] then table.insert(dupe, "stat " .. e.stat) end
	ids[e.id], prefixes[e.prefix], stats[e.stat] = true, true, true
end
check(#dupe == 0, "every id, prefix and stat is unique" ..
	(#dupe > 0 and ("  — " .. table.concat(dupe, ", ")) or ""))

-- An enchantment naming a stat nothing pays out is a dead prefix.
local unknown = {}
for _, e in ipairs(E.LIST) do
	if not STATS_STUB.STATS[e.stat] then table.insert(unknown, e.id .. " -> " .. e.stat) end
end
check(#unknown == 0, "every enchantment names a real stat" ..
	(#unknown > 0 and ("  — " .. table.concat(unknown, ", ")) or ""))

-- Magnitude comes off the stat's weight, so nobody maintains a second opinion
-- about what a stat is worth.
local cheapest, dearest
for _, e in ipairs(E.LIST) do
	local per = E.perLevel(e.id)
	check(per >= E.PER_MIN - 1e-9 and per <= E.PER_MAX + 1e-9,
		("%s per-level %.4f is inside the clamp"):format(e.id, per))
	local w = STATS_STUB.STATS[e.stat].weight
	if not cheapest or w > cheapest then cheapest = w end
	if not dearest or w < dearest then dearest = w end
end
-- An expensive stat must not out-earn a cheap one per level.
local sharp = E.perLevel("sharp")        -- mineSpeed, weight 1.0
local wide = E.perLevel("wide")          -- blastRadius, weight 6.0
check(sharp > wide, ("a cheap stat pays more per level than an expensive one (%.3f > %.3f)"):format(sharp, wide))

-- Linear, so "what does one more level buy" has one answer at every rung.
check(math.abs(E.amount("sharp", 3) - 3 * E.amount("sharp", 1)) < 1e-9,
	"level 3 is worth exactly three level 1s")
check(E.amount("sharp", 999) == E.amount("sharp", E.MAX_LEVEL),
	"levels clamp at MAX_LEVEL (" .. E.MAX_LEVEL .. ")")
check(E.amount("sharp", 0) == E.amount("sharp", 1), "...and at 1 from below")

-- THE PREFIX, which is the whole feature.
check(E.decorate("Stone Pickaxe", { id = "sharp", level = 1 }) == "Sharp Stone Pickaxe",
	'decorate -> "Sharp Stone Pickaxe"')
check(E.decorate("Stone Drill", { id = "lucky", level = 4 }) == "Lucky Stone Drill",
	'decorate -> "Lucky Stone Drill"')
check(E.decorate("Stone Pickaxe", nil) == "Stone Pickaxe",
	"no enchantment, no prefix")
check(E.decorate("Stone Pickaxe", { id = "nonsense" }) == "Stone Pickaxe",
	"an unknown enchantment adds no prefix rather than a nil one")
-- The level is NOT in the name: the owner wrote "Sharp Stone Pickaxe", not
-- "Sharp III Stone Pickaxe".
check(not string.find(E.decorate("Stone Pickaxe", { id = "sharp", level = 7 }), "7"),
	"the level stays out of the name")

-- Price: strictly rising, and nil past the cap so nothing charges for a level
-- that does not exist.
local prev = 0
local rising = true
for lv = 1, E.MAX_LEVEL do
	local c = E.gemCost(lv)
	if not c or c <= prev then rising = false end
	prev = c or prev
end
check(rising, "gem cost rises at every level")
check(E.gemCost(E.MAX_LEVEL + 1) == nil, "...and is nil above the cap")
check(E.gemCost(0) == nil, "...and nil below level 1")
check(E.gemSpent(E.MAX_LEVEL) > E.gemCost(E.MAX_LEVEL),
	"a full climb costs more than its last step")

-- Additive stats add, multiplier stats multiply.
local ADD = { oreYield = true, zap = true, procPower = true }
local b = { oreYield = 0, mineSpeed = 1 }
E.apply(b, { id = "blasting", level = 2 }, ADD)
check(math.abs(b.oreYield - E.amount("blasting", 2)) < 1e-9,
	"an additive stat takes the amount straight")
E.apply(b, { id = "sharp", level = 2 }, ADD)
check(math.abs(b.mineSpeed - (1 + E.amount("sharp", 2))) < 1e-9,
	"a multiplier stat takes 1 + amount")

-- Migration never takes power away.
local back = E.fromStatAmount("mineSpeed", E.amount("sharp", 4))
check(back and back.id == "sharp" and back.level >= 4,
	"converting a rune/gear amount back never rounds down")
check(E.fromStatAmount("notAStat", 1) == nil,
	"a stat no enchantment covers converts to nil, for the caller to refund")

if fail > 0 then
	print("")
	print(">>> enchants: " .. fail .. " FAILED assertion(s)")
else
	print("")
	print(">>> enchants: all assertions passed")
end
`;

const script = path.join(ROOT, ".luau-bin/enchants-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(LUAU, [script], { encoding: "utf8" }); process.stdout.write(out); }
catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
  process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || "");
  process.exit(1);
}

let fail = /FAILED|FAIL /.test(out) ? 1 : 0;
const src = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };
const code = (lua) => lua.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");

src(/function MineOreTools\.name\(oreDef, familyId, ench\)/.test(oretools),
  "MineOreTools.name takes the enchantment");
src(/Ench\.decorate\(/.test(oretools), "...and prefixes through MineEnchants.decorate");
src(/MineOreTools\.name\(MineOreTools\.oreOf\(tool\), tool\.familyId, tool\.ench\)/.test(oretools),
  "a forged row carries its own enchantment, so it cannot be named without one");

const verb = code((server.match(/function Verbs\.enchantTool[\s\S]*?\n^end$/m) || [""])[0]);
src(verb.length > 300, "found Verbs.enchantTool");
// The client names a uid and an enchant id. Everything else is re-derived.
src(!/payload\.level/.test(verb), "the verb never trusts a level from the client");
src(!/payload\.cost/.test(verb) && /Ench\.gemCost\(target\)/.test(verb),
  "...and re-derives the price itself");
src(/Ench\.byId\(payload\.enchantId\)/.test(verb), "...validating the enchant id against the roster");
src(/target > Ench\.MAX_LEVEL/.test(verb), "...and refusing to go past the cap");
src(/elseif action == "enchantTool" then/.test(server), "enchantTool is wired to the net dispatch");

const boosts = code((server.match(/local function boosts\(p\)[\s\S]*?\n^end$/m) || [""])[0]);
src(/Dig\.Ench\.apply\(b, t\.ench, Cards\.ADDITIVE_STATS\)/.test(boosts),
  "boosts folds the equipped tool's enchantment through ADDITIVE_STATS");
src(/p\.oreToolEquipped/.test(boosts),
  "...and only the tool actually in your hands");

console.log("");
console.log(fail > 0 ? `>>> enchants: ${fail} FAILED` : ">>> enchants: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
