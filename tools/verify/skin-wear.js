// A SKIN IS WORN THE SAME WAY ON EVERY TOOL, AND THE WARDROBE TELLS THE TRUTH.
//
// Owner, 2026-10-19 (launch-audit build spec): "one wardrobe everywhere" --
// event tools wear the same skins -- and "make skins work, all of it". Before
// this, a skin was resolved three ways:
//
//   damage   equippedTool multiplied the skin in on the FORGED path only
//   kit      boosts() looked the family up from p.oreToolEquipped only
//   look     givePickaxe read p.skinEquipped[family of whatever was held]
//
// so an Event Horizon tool (and, next, a Candy Crypt tool) wore a skin's look
// with none of its power. And the Skins wardrobe read `snap.heldFamily`, a
// field the server never sends: no tile ever said EQUIPPED, the footer always
// said "Hold a tool", and no screen showed what a skin does. An ore case's
// "skin" was a temper filed where the wardrobe never looks (audit S14).
//
// Now MineToolSkins is the one rule (any tool record with a `family`), the
// server's equippedTool puts the skin on WHATEVER Dig.toolInHand returns and
// stamps `skinId`, and the kit and the look read that stamp. This asserts the
// wiring, then EXECUTES MineToolSkins and the server's own wearSkin/equippedTool
// slices against a forged row, an event tool and a Crypt-shaped record.
//
// Run: node tools/verify/skin-wear.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const SHARED = "src/ReplicatedStorage/Mine/Shared/";
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const SRV = read("src/ServerScriptService/Mine/MineServer.server.luau");
const VIEW = read(SHARED + "MineSkinsView.luau");
const HUB = read(SHARED + "MineForgeHub.luau");
const FACTORY = read("src/ReplicatedStorage/ToolModelFactory.luau");
const TOOLSKINS_PATH = path.join(ROOT, SHARED + "MineToolSkins.luau");

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};
const code = (s) => s.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");
const fn = (src, head) => (src.match(new RegExp(head.replace(/[.()]/g, "\\$&") + "[\\s\\S]*?\\nend\\n")) || [""])[0];
const SRVC = code(SRV);

console.log("skin-wear: one rule for which skin a tool wears, on every tool");

// ------------------------------------------------------- the server's rule --
ok(fs.existsSync(TOOLSKINS_PATH), "MineToolSkins exists (the one resolver)");
const wrapper = fn(SRVC, "local function equippedTool(p)");
ok((SRVC.match(/local function equippedTool\(/g) || []).length === 1, "there is one equippedTool");
ok(/local row, fam, rung = Dig\.toolInHand\(p\)\s*\n\s*return Dig\.wearSkin\(p, row, fam\), fam, rung/.test(wrapper),
  "equippedTool puts the skin on whatever toolInHand returns (forged, event, chest)");
const wear = fn(SRVC, "function Dig.wearSkin(");
ok(/row\.skinId ~= nil/.test(wear) && /ToolSkins\.familyOf\(row, fam\)/.test(wear) && /ToolSkins\.wear\(row, worn\)/.test(wear),
  "Dig.wearSkin resolves by the row's family and never wears a skin twice");
const skinBase = fn(SRVC, "local function skinBase(");
ok(/ToolSkins\.skinFor\(p\.skinEquipped, familyId\)/.test(skinBase), "skinBase looks the skin up through MineToolSkins.skinFor");
const inHand = fn(SRVC, "function Dig.toolInHand(");
ok(/skinBase\(p, famId\)/.test(inHand) && /skinId = worn and worn\.id or nil/.test(inHand),
  "the forged path stamps the skin it built into hitPower");

// The kit pays off the stamp, so it is always the damage's skin.
const boosts = fn(SRVC, "local function boosts(");
ok(/local held = equippedTool\(p\)\s*\n\s*local id = type\(held\) == "table" and held\.skinId/.test(boosts),
  "boosts() pays the kit of the skin equippedTool stamped (event tools included)");
ok(!/for _, t in ipairs\(p\.oreTools or \{\}\) do\s*\n\s*if t\.uid == uid then\s*\n\s*fam = t\.familyId/.test(boosts),
  "...not of a skin looked up from the forged tool's uid only");
// The look reads the same stamp, in the hand and on a thrown charge.
ok(/local skinId = row and row\.skinId/.test(fn(SRVC, "local function givePickaxe(")),
  "givePickaxe builds the look of the stamped skin");
ok(/tool\.skinId and ToolModels\.buildSkinned/.test(fn(SRVC, "local function flingCharge(")),
  "a thrown charge wears the held tool's skin form too");
// Every other place the profile's skin map is touched is the equip verb.
const reads = (SRVC.match(/skinEquipped\[/g) || []).length;
const inVerb = (fn(SRVC, "function Verbs.equipSkin(").match(/skinEquipped\[/g) || []).length;
ok(reads > 0 && reads === inVerb, "nothing outside Verbs.equipSkin indexes p.skinEquipped by hand",
  `${reads} total, ${inVerb} in equipSkin`);
const equip = fn(SRVC, "function Verbs.equipSkin(");
ok(/local _, heldFam = equippedTool\(p\)/.test(equip) && /ToolSkins\.isFamily\(fam\)/.test(equip),
  "equipSkin falls back to the class in hand, any tool, and stores only real tool classes");
ok(/ToolSkins\.STATS_ONLY/.test(equip) && /ToolModels\.hasSkinForm/.test(equip),
  "...and says \"stats only\" when that class has no skin form yet");
ok(/family = fam, tier = tier, power = t\.power, skinId = t\.skinId/.test(SRVC),
  "the snapshot's tool row carries its family and skin to the screens");

// ---------------------------------------------------- the ore case (S14) --
const oreCase = (SRVC.match(/elseif zdef\.kind == "ore_case" then[\s\S]*?elseif zdef\.kind == "ore" then/) || [""])[0];
ok(oreCase.length > 0, "found openPack's ore-case branch");
ok(/local _, rarity = Temper\.rollTemperament\(crng\)/.test(oreCase) && /Dig\.grantChestSkin\(p, grade, crng\)/.test(oreCase),
  "an ore case pays a wardrobe skin, on a temper case's grade odds, by the chests' own grant");
ok(!/p\.tempers/.test(oreCase), "...and files nothing in p.tempers any more");
ok(/ToolSkins\.caseReel\(crng, skinDef\)/.test(oreCase) && /"temperCase"/.test(oreCase),
  "...with the same reel ceremony, built of skins");
ok(/return "skin", def\.name, tier, def/.test(SRVC), "Dig.grantChestSkin hands back the skin it granted");

// --------------------------------------------------------- the screens --
const view = code(VIEW);
ok(!/heldFamily/.test(view) && /tool\.family/.test(view), "the wardrobe reads the class in hand from snap.tool, not heldFamily");
ok(/t\.sub\.Text = "EQUIPPED"/.test(view) && /opts\.onEquipSkin\("", fam\)/.test(view),
  "...shows EQUIPPED and takes a worn skin off on a second tap");
ok(/ToolSkins\.multText\(s\)/.test(view) && /ToolSkins\.kitText\(s, 1\)/.test(view) && /ToolSkins\.powerLine\(s\)/.test(view),
  "...shows each skin's damage multiplier and kit");
ok(/ToolSkins\.STATS_ONLY/.test(view), "...and says \"stats only\" where the class has no form");
const hub = code(HUB);
ok(/ToolSkins\.multText\(s\)/.test(hub) && /ToolSkins\.kitText\(s, 3\)/.test(hub) && /looksLabel\(o\.fam, s\)/.test(hub),
  "the Forge's skin picker shows the same power and \"stats only\"");
ok(/Factory\.buildSkinned\(fam, skin, look\)/.test(hub), "the Forge shows an owned tool in its skin form");
ok(/SKIN_PALETTES\[setKey\] ~= nil/.test(fn(FACTORY, "function ToolModelFactory.hasSkinForm(")),
  "hasSkinForm claims a look only where buildSkinned can build one (a palette too)");

if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU) || !fs.existsSync(TOOLSKINS_PATH)) {
  console.log("  " + Luau.missing("luau"));
  console.log(fails === 0 ? ">>> skin-wear OK (static only)" : `>>> ${fails} FAILED`);
  process.exit(fails === 0 ? 0 : 1);
}

// ------------------------------------------------------------ executed --
// The real modules, loaded through a stand-in `require` keyed by name, in the
// order they need each other. script.Parent:WaitForChild(name) hands back the
// name, which is what the stand-in require takes.
const mod = (name) => `MODULES.${name} = (function()\n${read(SHARED + name + ".luau")}\nend)()`;
const block = (src, head) => {
  const L = src.split("\n");
  const i = L.findIndex((l) => l.startsWith(head));
  if (i < 0) throw new Error("not found: " + head);
  for (let j = i; j < L.length; j++) if (L[j] === "end") return L.slice(i, j + 1).join("\n");
  throw new Error("unterminated: " + head);
};

const harness = `
Color3 = { fromRGB = function(r, g, b) return { r, g, b } end }
local MODULES = {}
local function require(name)
	local m = MODULES[name]
	if m == nil then error("no module " .. tostring(name)) end
	return m
end
script = { Parent = { WaitForChild = function(_, name) return name end } }
${mod("MineStats")}
${mod("MineSkins")}
${mod("MineTemper")}
${mod("MineToolSkins")}
local ToolSkins = MODULES.MineToolSkins
local Skins = MODULES.MineSkins

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

-- Two real skins: an F and an SSS, neither from the pass set.
local F, SSS
for _, s in ipairs(Skins.LIST) do
	if not Skins.isPass(s) then
		if s.tier == "F" and not F then F = s end
		if s.tier == "SSS" and not SSS then SSS = s end
	end
end
check("found an F and an SSS skin", F ~= nil and SSS ~= nil)

-- The rule: a record's family, from a def (family) or a forged row (familyId).
check("an event def's family", ToolSkins.familyOf({ family = "drill" }) == "drill")
check("a forged row's familyId", ToolSkins.familyOf({ familyId = "hammer" }) == "hammer")
check("a bare family name", ToolSkins.familyOf("explosive") == "explosive")
check("no family falls back", ToolSkins.familyOf({}, "pickaxe") == "pickaxe")
check("only real tool classes", ToolSkins.isFamily("jackhammer") and not ToolSkins.isFamily("hat") and not ToolSkins.isFamily(""))

local equipped = { pickaxe = SSS.id, hammer = F.id }
check("an Event Horizon pick wears the pickaxe skin",
	ToolSkins.skinFor(equipped, { id = "eh_shallow_pick", family = "pickaxe", power = 100 }) == SSS)
check("a Candy Crypt mallet (any record with a family) wears the hammer skin",
	ToolSkins.skinFor(equipped, { id = "crypt_corn_hammer", family = "hammer", power = 50 }) == F)
check("a family wearing nothing wears nothing", ToolSkins.skinFor(equipped, { family = "drill" }) == nil)
check("no wardrobe at all is no skin", ToolSkins.skinFor(nil, { family = "pickaxe" }) == nil)

-- Wearing it: the base under every power, on a copy, once.
local def = { id = "eh_shallow_pick", family = "pickaxe", power = 1000, spacePower = 40, jackpotPower = 9 }
local worn = ToolSkins.wear(def, SSS)
check("the skin's base multiplies the tool's power", worn.power == math.floor(1000 * Skins.BASE.SSS),
	tostring(worn.power))
check("...and its space and jackpot power", worn.spacePower == math.floor(40 * Skins.BASE.SSS)
	and worn.jackpotPower == math.floor(9 * Skins.BASE.SSS))
check("...stamped with the skin, for the kit and the look", worn.skinId == SSS.id and worn.skinMult == Skins.BASE.SSS)
check("...on a copy: the module's shared def is untouched", def.power == 1000 and def.skinId == nil)
check("a row already wearing a skin is not multiplied twice", ToolSkins.wear(worn, SSS) == worn)
check("bare hands wear nothing", ToolSkins.wear({ none = true, power = 0 }, SSS).skinId == nil)
check("no skin is the same row", ToolSkins.wear(def, nil) == def)
check("the multiplier reads as words", ToolSkins.multText(SSS) == "x5.5" and ToolSkins.multText(F) == "x1.15",
	ToolSkins.multText(SSS) .. " / " .. ToolSkins.multText(F))
check("the power line leads with the damage", string.sub(ToolSkins.powerLine(SSS), 1, 11) == "x5.5 damage",
	ToolSkins.powerLine(SSS, 2))
local on = ToolSkins.wornOn({ pickaxe = SSS.id, drill = SSS.id, hammer = F.id }, SSS.id)
check("a skin worn on two classes is listed on both", #on == 2 and on[1] == "pickaxe" and on[2] == "drill")

-- The ore case's reel: the winner where the reel stops, never a pass skin.
local seed = 0
local rng = {
	NextNumber = function() seed = (seed * 1103515245 + 12345) % 2147483648 return seed / 2147483648 end,
	NextInteger = function(_, lo, hi) seed = (seed * 1103515245 + 12345) % 2147483648 return lo + seed % (hi - lo + 1) end,
}
local reel, at = ToolSkins.caseReel(rng, SSS)
check("the reel is a temper case's length", #reel == MODULES.MineTemper.CASE_REEL, tostring(#reel))
check("...and stops on the winner", at == MODULES.MineTemper.CASE_WINNER_AT and reel[at].id == SSS.id
	and reel[at].rarity == "SSS")
local passIn = false
for _, r in ipairs(reel) do
	if Skins.isPass(r.id) then passIn = true end
end
check("...and never shows a pass skin", not passIn)

-- THE SERVER'S OWN SLICES: skinBase, Dig.wearSkin and the equippedTool wrapper.
local shared = { WaitForChild = function(_, name) return name end }
local Dig = {}
${block(SRV, "local function skinBase(")}
${block(SRV, "function Dig.wearSkin(")}
${block(SRV, "local function equippedTool(p)")}
local function hold(row, fam) Dig.toolInHand = function() return row, fam, 0 end end
local p = { skinEquipped = { pickaxe = SSS.id, hammer = F.id } }

hold({ id = "eh_deep_pick", family = "pickaxe", power = 200 }, "pickaxe")
local t, fam = equippedTool(p)
check("server: an event tool in hand wears its family's skin", t.power == math.floor(200 * Skins.BASE.SSS) and t.skinId == SSS.id
	and fam == "pickaxe", tostring(t.power))
hold({ id = "crypt_toffee_mallet", family = "hammer", power = 70 }, "hammer")
t = equippedTool(p)
check("server: a Crypt-shaped record wears it too", t.skinId == F.id and t.power == math.floor(70 * Skins.BASE.F))
hold({ id = "oretool_x", family = "hammer", power = 37, skinId = F.id, skinMult = Skins.BASE.F, oreTool = true }, "hammer")
t = equippedTool(p)
check("server: a forged row (skin already in hitPower) is left alone", t.power == 37)
hold({ id = "bp_drill", family = "drill", power = 90 }, "drill")
t = equippedTool(p)
check("server: a family with no skin is the plain tool", t.power == 90 and t.skinId == nil)
hold({ id = "bare_hands", none = true, power = 0 }, "pickaxe")
t = equippedTool(p)
check("server: bare hands wear nothing", t.skinId == nil)
local m, d = skinBase(p, { family = "hammer" })
check("server: skinBase reads a record or a name the same", m == Skins.BASE.F and d == F and skinBase(p, "hammer") == m)

print(fails == 0 and ">>> skin-wear harness OK" or (">>> " .. fails .. " FAILED"))
`;

const tmp = path.join(require("os").tmpdir(), "skin-wear-harness.luau");
fs.writeFileSync(tmp, harness);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" });
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
}
process.stdout.write(out);
if (!/>>> skin-wear harness OK/.test(out)) fails++;

console.log(fails === 0 ? ">>> skin-wear OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
