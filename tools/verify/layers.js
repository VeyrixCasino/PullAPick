// Two layers, and the second multiplies the first.
//
// Owner, 2026-10-04: "skills+skins+tools+enchantments are the very bottom ...
// equipment+pets are #2 [if skin has +50% damage, and pet says +100% damage,
// and the tools base is 100, then it turns to 300, rather than 250 (if it was
// all the same)]" and "Gear powers pets. Should just be a boost."
//
// The worked example IS the specification, so it is assertion one. The rest
// stops the old arithmetic creeping back: gear counted once per pet, and a face
// that multiplied the hats.
//
//   node tools/verify/layers.js
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

const mod = read("src/ReplicatedStorage/Mine/Shared/MineBoostLayers.luau");
const gear = read("src/ReplicatedStorage/Mine/Shared/MineGear.luau");
const server = read("src/ServerScriptService/Mine/MineServer.server.luau");

const body = mod.replace(/\nreturn MineBoostLayers\s*$/, "\n");
if (/require\(/.test(body)) {
  console.error("FAIL MineBoostLayers grew a require — this check assumes it has none");
  process.exit(1);
}

const harness = `
${body}
local L = MineBoostLayers
local fail = 0
local function check(ok, msg)
	if not ok then fail += 1 print("  FAIL  " .. msg) else print("  ok    " .. msg) end
end

--[[ THE OWNER'S EXAMPLE. Everything else here protects this one line. ]]
local layered = L.combineOne(100, 0.5, 1.0)
check(math.abs(layered - 300) < 1e-9,
	("skin +50%% (layer 1) and pet +100%% (layer 2) on a base of 100 -> %.0f"):format(layered))
-- ...and explicitly NOT the one pile the owner rejected.
check(math.abs(layered - 250) > 1e-9, "...not 250, which is one additive pile")

-- Within a layer, things add.
local t1 = {}
L.add(t1, "mineSpeed", 0.3)
L.add(t1, "mineSpeed", 0.2)
check(math.abs(t1.mineSpeed - 0.5) < 1e-9, "two sources in ONE layer add (0.3 + 0.2 = 0.5)")

-- Across layers, they multiply.
local b = { mineSpeed = 1 }
L.apply(b, { mineSpeed = 0.5 }, { mineSpeed = 1.0 }, {})
check(math.abs(b.mineSpeed - 3.0) < 1e-9,
	("a multiplier stat ends at %.2fx, not %.2fx"):format(b.mineSpeed, 2.5))

-- A pet is worth the same whatever your skin is. That is the property a single
-- pile cannot have, and the reason for the whole change.
local poorSkin = L.combineOne(100, 0.1, 1.0) / L.combineOne(100, 0.1, 0)
local richSkin = L.combineOne(100, 5.0, 1.0) / L.combineOne(100, 5.0, 0)
check(math.abs(poorSkin - richSkin) < 1e-9,
	("a +100%% pet doubles your damage at any skin (%.3fx vs %.3fx)"):format(poorSkin, richSkin))

-- CHANCE stats are not layered: "1 + x" on a blast chance is meaningless.
local c = { oreYield = 0.1 }
L.apply(c, { oreYield = 0.2 }, { oreYield = 0.3 }, { oreYield = true })
check(math.abs(c.oreYield - 0.6) < 1e-9,
	("a chance stat sums to %.2f instead of being multiplied"):format(c.oreYield))

-- A stat the table has never heard of starts at 1, not 0, or the first layer
-- that touches it would zero the stat out.
local fresh = {}
L.apply(fresh, { gemFind = 0.5 }, {}, {})
check(math.abs(fresh.gemFind - 1.5) < 1e-9, "an unseen multiplier stat starts at 1")

-- Order cannot matter.
local x, y = { luck = 1 }, { luck = 1 }
L.apply(x, { luck = 0.4 }, { luck = 0.7 }, {})
L.apply(y, { luck = 0.7 }, { luck = 0.4 }, {})
check(math.abs(x.luck - y.luck) < 1e-9, "the layers commute")

-- Nothing in, nothing out.
local z = { luck = 1 }
L.apply(z, {}, {}, {})
check(z.luck == 1, "no contributions, no change")

check(#L.LAYER1 == 4 and #L.LAYER2 == 2,
	"layer 1 names four sources and layer 2 names two")
for _, name in ipairs({ "skills", "skins", "tools", "enchantments" }) do
	check(L.TIER_OF[name] == 1, name .. " is layer 1")
end
for _, name in ipairs({ "equipment", "pets" }) do
	check(L.TIER_OF[name] == 2, name .. " is layer 2")
end

if fail > 0 then
	print("")
	print(">>> layers: " .. fail .. " FAILED assertion(s)")
else
	print("")
	print(">>> layers: all assertions passed")
end
`;

const script = path.join(ROOT, ".luau-bin/layers-check.luau");
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

// "Gear powers pets. Should just be a boost."
const stack = code((gear.match(/function MineGear\.stackPets[\s\S]*?\n^end$/m) || [""])[0]);
src(/function MineGear\.stackPets\(pets\)/.test(gear),
  "stackPets takes pets only — no hats, no face");
src(!/hats/.test(stack) && !/face/.test(stack),
  "...and its body mentions neither, so gear cannot be counted per pet again");
src(/function MineGear\.flatBoost\(hats, face\)/.test(gear),
  "gear is summed once, by flatBoost");
const flat = code((gear.match(/function MineGear\.flatBoost[\s\S]*?\n^end$/m) || [""])[0]);
src(!/pets/.test(flat), "...with no knowledge of pets at all");
src(!/effectiveHat/.test(gear), "the face-multiplies-the-hats term is gone");

const boosts = code((server.match(/local function boosts\(p\)[\s\S]*?\n^end$/m) || [""])[0]);
src(/local T1, T2 = \{\}, \{\}/.test(boosts), "boosts collects two layers");
src(/Dig\.Layers\.apply\(b, T1, T2, Cards\.ADDITIVE_STATS\)/.test(boosts),
  "...and combines them once, through ADDITIVE_STATS");
src(/Dig\.Layers\.add\(T1, def\.stat/.test(boosts), "the tool's enchantment is layer 1");
src(/Dig\.Layers\.add\(T1, key, sk\[stat\]\)/.test(boosts), "rebirth skills are layer 1");
src(/T2, Dig\.tailor\[p\] = Dig\.layer2\(p, n\)/.test(boosts), "pets and gear are layer 2");
src(!/Dig\.applyPets/.test(boosts), "the old applyPets mutation is gone");
// Combining early would make the answer depend on source order.
src(boosts.indexOf("Dig.Layers.apply") > boosts.indexOf("Dig.Layers.add(T1, key"),
  "the combine happens after every source has contributed");

console.log("");
console.log(fail > 0 ? `>>> layers: ${fail} FAILED` : ">>> layers: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
