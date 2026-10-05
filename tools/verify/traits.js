// An trait is a prefix on your tool, rolled on the skins ladder.
//
// Owner, 2026-10-04: "replace runes with traits ... its a prefix too your
// tool (Sharp Stone Pickaxe, Lucky Stone Drill)", "and gear aswell", "the same
// rarity as rune/temperment/skins", "exotic should be 1 in 1000, exotic V 1 in
// 5000", "random 1-5 to determine level", "Make each trait have its own
// rarity", "Make trait price stay the [same] with rebirths".
//
// Every one of those is an assertion below, checked against the REAL modules --
// the odds against MineTemper's own skins table rather than a number copied
// into a comment, so a skins rebalance that breaks the rule gets caught here.
//
//   node tools/verify/traits.js
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = path.resolve(__dirname, "../..");
const Luau = require("./_luau");
const LUAU = Luau.LUAU;
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8");
if (!Luau.ready) {
  // Names the platform and the fix, instead of "skipping" with no reason --
  // and exits 1, because a check that cannot run is not a check that passed.
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(1);
}

const mod = read("src/ReplicatedStorage/Mine/Shared/MineTraits.luau");
const statsSrc = read("src/ReplicatedStorage/Mine/Shared/MineStats.luau");
const temperSrc = read("src/ReplicatedStorage/Mine/Shared/MineTemper.luau");
const oretools = read("src/ReplicatedStorage/Mine/Shared/MineOreTools.luau");
const server = read("src/ServerScriptService/Mine/MineServer.server.luau");

const weights = {};
for (const m of (statsSrc.match(/MineStats\.STATS = \{([\s\S]*?)\n\}/) || ["", ""])[1]
  .matchAll(/^\t(\w+)\s*=\s*\{[^}]*?weight\s*=\s*([\d.]+)/gm)) weights[m[1]] = Number(m[2]);

// The skins ladder, verbatim. The whole rarity rule is stated against it.
const luaTable = (name) => {
  const m = temperSrc.match(new RegExp(`MineTemper\\.${name} = \\{([\\s\\S]*?)\\n\\}`));
  if (!m) { console.error(`FAIL could not find MineTemper.${name}`); process.exit(1); }
  const out = {};
  for (const r of m[1].matchAll(/(\w+)\s*=\s*([\d.]+)/g)) out[r[1]] = Number(r[2]);
  return out;
};
const skinWeights = luaTable("RARITY_WEIGHTS");
const rarityMult = luaTable("RARITY_MULT");
const procMult = luaTable("PROC_RARITY_MULT");
const skinTotal = Object.values(skinWeights).reduce((a, b) => a + b, 0);
if (Object.keys(weights).length < 15 || skinTotal < 1000) {
  console.error("FAIL could not parse the stat weights or the skins ladder");
  process.exit(1);
}
console.log(`  ${Object.keys(weights).length} stat weights; skins ladder sums to ${skinTotal}`);

const body = mod
  .replace(/local RS = game:GetService\("ReplicatedStorage"\)[\s\S]*?local Temper = require\(shared:WaitForChild\("MineTemper"\)\)/,
    "local Stats = STATS_STUB\nlocal Temper = TEMPER_STUB")
  .replace(/\nreturn MineTraits\s*$/, "\n");
if (/require\(/.test(body)) {
  console.error("FAIL MineTraits still has a require after stubbing — update this check");
  process.exit(1);
}

const luaOf = (o) => "{ " + Object.entries(o).map(([k, v]) => `${k} = ${v}`).join(", ") + " }";
const harness = `
local STATS_STUB = { STATS = {
${Object.entries(weights).map(([k, w]) => `\t${k} = { weight = ${w} },`).join("\n")}
} }
local TEMPER_STUB = {
	RARITY_WEIGHTS = ${luaOf(skinWeights)},
	RARITY_MULT = ${luaOf(rarityMult)},
	PROC_RARITY_MULT = ${luaOf(procMult)},
}
local SKIN_TOTAL = ${skinTotal}

-- Random is a Roblox API and this is standalone luau, so the roll gets a
-- deterministic stand-in. Seeded, so a distribution failure here reproduces
-- rather than being a coin flip in CI.
local Random = {}
function Random.new(seed)
	local state = (tonumber(seed) or 1) % 2147483647
	if state <= 0 then state += 2147483646 end
	return {
		NextInteger = function(_, lo, hi)
			state = (state * 16807) % 2147483647
			return lo + (state % (hi - lo + 1))
		end,
	}
end
${body}

local fail = 0
local function check(ok, msg)
	if not ok then fail += 1 print("  FAIL  " .. msg) else print("  ok    " .. msg) end
end
local E = MineTraits

------------------------------------------------------------------ roster --
check(#E.LIST >= 20, ("the roster has %d traits"):format(#E.LIST))
local ids, prefixes, stats, dupe = {}, {}, {}, {}
for _, e in ipairs(E.LIST) do
	if ids[e.id] then table.insert(dupe, "id " .. e.id) end
	if prefixes[e.prefix] then table.insert(dupe, "prefix " .. e.prefix) end
	if stats[e.stat] then table.insert(dupe, "stat " .. e.stat) end
	if not STATS_STUB.STATS[e.stat] then table.insert(dupe, "unknown stat " .. e.stat) end
	if not E.RARITY_WEIGHTS[e.rarity] then table.insert(dupe, "unknown rarity " .. tostring(e.rarity)) end
	ids[e.id], prefixes[e.prefix], stats[e.stat] = true, true, true
end
check(#dupe == 0, "every id, prefix and stat is unique and real" ..
	(#dupe > 0 and ("  — " .. table.concat(dupe, ", ")) or ""))

-- Owner: "Make each trait have its own rarity."
local missingTier = {}
for _, g in ipairs(E.RARITY_ORDER) do
	if #(E.BY_RARITY[g] or {}) == 0 then table.insert(missingTier, g) end
end
check(#missingTier == 0, "every rarity tier has at least one trait" ..
	(#missingTier > 0 and ("  — empty: " .. table.concat(missingTier, ", ")) or ""))

------------------------------------------------------------------- odds --
local sum = 0
for _, g in ipairs(E.RARITY_ORDER) do sum += E.RARITY_WEIGHTS[g] end
check(sum == E.RARITY_TOTAL,
	("the rarity weights sum to RARITY_TOTAL (%d of %d)"):format(sum, E.RARITY_TOTAL))

local mono = true
for i = 2, #E.RARITY_ORDER do
	if E.RARITY_WEIGHTS[E.RARITY_ORDER[i]] >= E.RARITY_WEIGHTS[E.RARITY_ORDER[i - 1]] then
		mono = false
	end
end
check(mono, "each tier is strictly rarer than the one below it")

-- THE OWNER'S TWO NUMBERS.
local exoticChance = E.RARITY_TOTAL / E.RARITY_WEIGHTS.SSS
check(math.abs(exoticChance - 1000) < 1e-9,
	("Exotic is 1 in %.0f"):format(exoticChance))
check(math.abs(E.odds("wide") - 1000) < 1e-9,
	("Wide, the only Exotic, is 1 in %.0f"):format(E.odds("wide")))
check(math.abs(E.odds("wide", 5) - 5000) < 1e-9,
	("Exotic V is 1 in %.0f"):format(E.odds("wide", 5)))

--[[
	THE CONDENSE RULE. Owner: "condense it so the rarity is the chance to get a
	the V level, for all the rarest ones (over 1-200)".

	For every tier at or rarer than 1/200, the chance of that tier AT LEVEL V
	must equal the skins table's own chance for that tier. Checked against
	MineTemper, so this breaks loudly if skins are rebalanced.
]]
local checkedRule = 0
for _, g in ipairs(E.RARITY_ORDER) do
	local tierChance = E.RARITY_WEIGHTS[g] / E.RARITY_TOTAL
	if tierChance <= 1 / 200 + 1e-12 then
		local vChance = tierChance / E.MAX_LEVEL
		local skin = (TEMPER_STUB.RARITY_WEIGHTS[g] or 0) / SKIN_TOTAL
		checkedRule += 1
		check(math.abs(vChance - skin) < 1e-9,
			("%s V is 1 in %.0f, and skins %s is 1 in %.0f"):format(
				g, 1 / vChance, g, skin > 0 and 1 / skin or 0))
	end
end
check(checkedRule >= 2, ("the rule covers %d tiers at or rarer than 1/200"):format(checkedRule))

------------------------------------------------------------------ levels --
check(E.MAX_LEVEL == 5, "five levels")
check(E.amount("sharp", 999) == E.amount("sharp", E.MAX_LEVEL), "levels clamp at the cap")
check(math.abs(E.amount("sharp", 3) - 3 * E.amount("sharp", 1)) < 1e-9,
	"level 3 is worth exactly three level 1s")

-- Rarity scales magnitude, and a CHANCE stat takes the gentle ladder or a
-- Divine Blasting would be +75 points of blast chance, which is not a proc.
check(E.rarityMult("blasting") == TEMPER_STUB.PROC_RARITY_MULT.SS,
	"a chance trait uses PROC_RARITY_MULT")
check(E.rarityMult("sharp") == TEMPER_STUB.RARITY_MULT.F,
	"a non-chance trait uses RARITY_MULT")
check(E.amount("blasting", 5) < 0.30,
	("Blasting V adds %.3f blast chance, not most of a certainty"):format(E.amount("blasting", 5)))

------------------------------------------------------------------- roll --
local rng = Random.new(12345)
local seen, badLevel, badId = {}, 0, 0
for _ = 1, 20000 do
	local r = E.roll(rng)
	if not r or not E.byId(r.id) then badId += 1 end
	if r and (r.level < 1 or r.level > E.MAX_LEVEL or r.level ~= math.floor(r.level)) then
		badLevel += 1
	end
	if r then seen[r.id] = (seen[r.id] or 0) + 1 end
end
check(badId == 0, "every roll returns a real trait")
check(badLevel == 0, "every roll returns a whole level in 1..MAX_LEVEL")
-- The commonest tier must actually dominate; a uniform roll would be a bug.
check((seen.sharp or 0) > (seen.wide or 0), "common traits roll far more often than Exotic")

------------------------------------------------------------------ prefix --
check(E.decorate("Stone Pickaxe", { id = "sharp", level = 1 }) == "Sharp Stone Pickaxe",
	'decorate -> "Sharp Stone Pickaxe"')
check(E.decorate("Stone Drill", { id = "lucky", level = 4 }) == "Lucky Stone Drill",
	'decorate -> "Lucky Stone Drill"')
check(E.decorate("Stone Pickaxe", nil) == "Stone Pickaxe", "no trait, no prefix")
check(E.decorate("Stone Pickaxe", { id = "nonsense" }) == "Stone Pickaxe",
	"an unknown trait adds no prefix rather than a nil one")
check(not string.find(E.decorate("Stone Pickaxe", { id = "sharp", level = 5 }), "V"),
	"the level stays out of the tool's name")
check(E.label({ id = "wide", level = 5 }) == "Exotic Wide V",
	'label -> "Exotic Wide V"  (got "' .. E.label({ id = "wide", level = 5 }) .. '")')

------------------------------------------------------------------- price --
check(type(E.ROLL_PRICE) == "number" and E.ROLL_PRICE > 0,
	("the roll costs a flat %d gems"):format(E.ROLL_PRICE))

if fail > 0 then
	print("")
	print(">>> traits: " .. fail .. " FAILED assertion(s)")
else
	print("")
	print(">>> traits: all assertions passed")
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

src(/function MineOreTools\.name\(oreDef, familyId, trait\)/.test(oretools),
  "MineOreTools.name takes the trait");
src(/MineOreTools\.name\(MineOreTools\.oreOf\(tool\), tool\.familyId, tool\.trait\)/.test(oretools),
  "a forged row carries its own trait, so it cannot be named without one");

const verb = code((server.match(/function Verbs\.rollTrait[\s\S]*?\n^end$/m) || [""])[0]);
src(verb.length > 300, "found Verbs.rollTrait");
src(/Traits\.roll\(Random\.new\(\)\)/.test(verb), "the verb rolls with a server rng");
src(!/payload\.level/.test(verb) && !/payload\.traitId/.test(verb),
  "...and takes nothing from the client but a uid");
// Owner: the price "stays the same with rebirths".
src(/Traits\.ROLL_PRICE/.test(verb), "the price is MineTraits.ROLL_PRICE");
src(!/prestige|rebirth|p\.zoneId|tool\.tier/i.test(verb),
  "...and reads no prestige, rebirth, zone or tool tier");
src(/elseif action == "rollTrait" then/.test(server), "rollTrait is wired to the net dispatch");

const boosts = code((server.match(/local function boosts\(p\)[\s\S]*?\n^end$/m) || [""])[0]);
// The trait is LAYER 1 now (MineBoostLayers), beside skills and skins,
// rather than being multiplied straight into the boost table. tools/verify/
// layers.js owns the layering rule; this only checks the trait reaches it.
src(/Dig\.Layers\.add\(T1, def\.stat,/.test(boosts),
  "boosts puts the equipped tool's trait into layer 1");
src(/Dig\.Traits\.amount\(t\.trait\.id, t\.trait\.level\)/.test(boosts),
  "...at the magnitude MineTraits derives, rarity and all");
src(/p\.oreToolEquipped/.test(boosts), "...and only the tool actually in your hands");

// --- the front door -------------------------------------------------------
// A trait system with no screen is unreachable, which is what stages 1
// and 2 of TODO 0.17 were about.
const view = read("src/ReplicatedStorage/Mine/Shared/MineTraitView.luau");
const client = read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau");

src(/function MineTraitView\.mount\(parent, opts\)/.test(view),
  "MineTraitView mounts like the Enchanter's other tabs");
src(/setVisible = function\(on\)/.test(view), "...and exposes setVisible");
// Every number on screen must come from the module, or the screen and the roll
// drift apart the moment the weights move.
src(/Traits\.odds\(/.test(view), "the panel derives its odds from MineTraits.odds");
src(/Traits\.ROLL_PRICE/.test(view), "...and its price from MineTraits.ROLL_PRICE");
// Comments stripped: the file's own header explains that this is a 1-in-1000
// chase, which is prose, not a label a player reads.
src(!/1 in 1000|1 in 5000/.test(code(view)),
  "...with no odds written into a label by hand");
src(/Traits\.label\(cur\)/.test(view), "it names what a roll would replace");

src(/\{ "trait", "Traits" \}/.test(client), "the Enchanter has a Traits tab");
src(/local enchantTab = "trait"/.test(client), "...and opens on it");
src(/net:FireServer\("rollTrait", \{ uid = uid \}\)/.test(client),
  "the client sends a uid and nothing else");
src(/NO TRAIT TAB/.test(client),
  "a missing MineTraitView warns instead of losing the tab in silence");

console.log("");
console.log(fail > 0 ? `>>> traits: ${fail} FAILED` : ">>> traits: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
