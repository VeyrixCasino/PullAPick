// A FORGE CARD MUST SAY WHAT THE SERVER DOES.
//
// Launch audit 2026-10-19, decided by the owner the same day:
//
//   S9   "the card's craft price is right": the craft verb built its type
//        multiplier with NO ore tier -- Verbs._oreToolTypeMult({ familyId,
//        typeId }) -> MineOreTools.typeMult(family, nil) -> step 1 for every
//        ore -- while the Forge's card used the ore's real step. From ore tier
//        7 up, the card and the charge were different numbers.
//   S11  "cards show true damage per hit, hits per second, area, use; Lv is
//        the inherited level": the card printed C.toolPower without the
//        family (hammer x3.7, explosive x4, jackhammer x0.67), the skin or the
//        finish -- a Stone Hammer card said 10 and the swing hit 37 -- and a
//        craft read "Lv 1" though a new tool arrives at your best level.
//
// The fix is one copy of each rule in MineOreTools (craftCost, hitPower,
// inheritedLevel, cardStats), called by the server AND every Forge panel. This
// asserts that wiring, then EXECUTES the shared functions:
//   * craftCost is the card's old number for every ore x family, and the
//     server's old tierless number really did differ (the harness sees S9);
//   * hitPower is exactly the arithmetic equippedTool used inline, for every
//     ore x family x level x skin x finish (nothing a player holds moved),
//     and the card's old number really did differ (the harness sees S11).
//
// Run: node tools/verify/forge-cards.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const SHARED = "src/ReplicatedStorage/Mine/Shared/";
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const CFG = read(SHARED + "MineConfig.luau");
const ORE = read(SHARED + "MineOreTools.luau");
const HUB = read(SHARED + "MineForgeHub.luau");
const FORGE = read(SHARED + "MineForge.luau");
const SRV = read("src/ServerScriptService/Mine/MineServer.server.luau");

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};
// Code only: comments here quote the old calls on purpose.
const code = (s) => s.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");
const fn = (src, head) => (src.match(new RegExp(head.replace(/[.()]/g, "\\$&") + "[\\s\\S]*?\\nend\\n")) || [""])[0];

console.log("forge-cards: the Forge's price, damage and level are the server's");

// ------------------------------------------------------------ S9: the price --
const craft = code(fn(SRV, "function Verbs.craftOreTool("));
ok(craft.length > 200, "found Verbs.craftOreTool");
ok(/local cost = OreTools\.craftCost\(familyId, oreDef\.tier\)/.test(craft),
  "the craft verb charges MineOreTools.craftCost(family, ore tier)");
ok(!/_oreToolTypeMult\(\{\s*familyId = familyId, typeId/.test(craft) && !/C\.toolCraftCost\(/.test(craft),
  "...and no longer builds its own tierless typeMult");
ok(/local cost = OreTools\.craftCost\(fam, def\.tier\)/.test(code(HUB)),
  "the Forge hub's recipe price is that same call");
ok((code(FORGE).match(/OreTools\.craftCost\(/g) || []).length === 3,
  "the old Forge's three price quotes are that same call");
for (const [name, src] of [["the hub", HUB], ["the old Forge", FORGE], ["the server", SRV]]) {
  ok(!/C\.toolCraftCost\(/.test(code(src)), name + " prices a craft nowhere else");
}

// --------------------------------------------- S11: the hit, the level, use --
const toolInHand = code(fn(SRV, "function Dig.toolInHand("));
ok(/local power = OreToolsPow\.hitPower\(held, skinMult\)/.test(toolInHand),
  "the held forged tool's power is MineOreTools.hitPower(row, skin)");
ok(!/C\.toolPower\(/.test(code(SRV)), "...and the server computes a tool's power nowhere else");
ok(!/power \* \(C\.(NIGHTMARE|SHADOW|SHINY)_MULT/.test(toolInHand),
  "...with the finish applied once, inside hitPower");
ok(/local inherited = OreTools\.inheritedLevel\(p\.oreTools\)/.test(craft),
  "a forge arrives at MineOreTools.inheritedLevel");
const hub = code(HUB);
ok(/OreTools\.cardStats\(row, mult\)/.test(hub) && !/C\.toolPower\(/.test(hub),
  "the hub's damage is MineOreTools.cardStats, never its own toolPower");
ok(/local lvNew = OreTools\.inheritedLevel\(snapC\.oreTools\)/.test(hub) && /starts Lv %d/.test(hub) && !/Lv 1 →/.test(hub),
  "the craft card shows the inherited level, not \"Lv 1\"");
ok(/perSecText\(card\.perSec\)/.test(hub) && /card\.area/.test(hub) && /card\.use/.test(hub),
  "the craft and loadout cards show hits per second, area and use");
ok(/local _, mult = wornSkin\(snap, row\.familyId or "pickaxe"\)/.test(hub),
  "the card's skin is the family's worn skin, looked up as the server does");
ok(/OreTools\.hitPower\(\{ familyId = selFamily/.test(code(FORGE)) && /OreTools\.inheritedLevel\(snapshot\.oreTools\)/.test(code(FORGE)),
  "the old Forge's damage and level go through the same functions");

if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU)) {
  console.log("  " + Luau.missing("luau"));
  console.log(fails === 0 ? ">>> forge-cards OK (static only)" : `>>> ${fails} FAILED`);
  process.exit(fails === 0 ? 0 : 1);
}

// --------------------------------------------------------------- executed --
const lines = (src) => src.split("\n");
function block(src, head, close) {
  const L = lines(src);
  const i = L.findIndex((l) => l.startsWith(head));
  if (i < 0) throw new Error("not found: " + head);
  for (let j = i; j < L.length; j++) if (L[j] === close) return { i, text: L.slice(i, j + 1).join("\n") };
  throw new Error("unterminated: " + head);
}
function line(src, head) {
  const L = lines(src);
  const i = L.findIndex((l) => l.startsWith(head));
  if (i < 0) throw new Error("not found: " + head);
  return { i, text: L[i] };
}

// MineConfig, sliced in FILE ORDER (some of these read others declared below).
const cfgParts = [
  line(CFG, "MineConfig.SHINY_MULT ="),
  line(CFG, "MineConfig.SHADOW_MULT ="),
  line(CFG, "MineConfig.NIGHTMARE_MULT ="),
  block(CFG, "MineConfig.ORE_YIELD_BANDS = {", "}"),
  block(CFG, "function MineConfig.oreYieldFor(", "end"),
  line(CFG, "MineConfig.TOOL_MAX_LEVEL ="),
  line(CFG, "MineConfig.TOOL_CLIMB_DAMAGE ="),
  block(CFG, "local function perLevel(", "end"),
  line(CFG, "MineConfig.TOOL_TIER_SPAN ="),
  line(CFG, "MineConfig.TOOL_DMG_BASE ="),
  block(CFG, "MineConfig.TOOL_BAND_DMG = {", "}"),
  line(CFG, "MineConfig.TOOL_DMG_STEP ="),
  block(CFG, "local function clampLevel(", "end"),
  block(CFG, "local function clampTier(", "end"),
  block(CFG, "function MineConfig.toolTierPower(", "end"),
  block(CFG, "function MineConfig.toolPower(", "end"),
  line(CFG, "MineConfig.CRAFT_BLOCKS ="),
  line(CFG, "MineConfig.CRAFT_BAND_EASE ="),
  line(CFG, "MineConfig.CRAFT_DEPTH_SLOPE ="),
  block(CFG, "function MineConfig.craftBlocks(", "end"),
  block(CFG, "function MineConfig.oreYieldMid(", "end"),
  block(CFG, "MineConfig.FAMILY_CRAFT_COST = {", "}"),
  block(CFG, "function MineConfig.toolCraftCost(", "end"),
  line(CFG, "MineConfig.ORE_COUNT ="),
  line(CFG, "MineConfig.ORE_BAND_ORDER ="),
  block(CFG, "function MineConfig.oreBandForTier(", "end"),
].sort((a, b) => a.i - b.i);

const oreParts = [
  block(ORE, "MineOreTools.FAMILY_POWER = {", "}"),
  block(ORE, "function MineOreTools.familyPower(", "end"),
  block(ORE, "MineOreTools.TYPE_MULT_STEPS = {", "}"),
  block(ORE, "MineOreTools.FRAME_STATS = {", "}"),
  block(ORE, "local function statValue(", "end"),
  block(ORE, "function MineOreTools.frameStats(", "end"),
  block(ORE, "function MineOreTools.typeMult(", "end"),
  block(ORE, "function MineOreTools.craftCost(", "end"),
  block(ORE, "function MineOreTools.inheritedLevel(", "end"),
  block(ORE, "function MineOreTools.hitPower(", "end"),
  block(ORE, "function MineOreTools.cardStats(", "end"),
].sort((a, b) => a.i - b.i);

const harness = `local MineConfig = {}
-- ORES is stubbed to its real length: ORE_COUNT and clampTier only read #ORES.
MineConfig.ORES = table.create(82, { tier = 1 })
${cfgParts.map((p) => p.text).join("\n")}
local C = MineConfig
local MineOreTools = {}
${oreParts.map((p) => p.text).join("\n")}

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end
local FAMS = { "pickaxe", "hammer", "drill", "jackhammer", "explosive" }

-- S9. The card's number (the hub's old formula, the owner's pick) is the price.
do
	local rows, same, oldDiff, firstDiff = 0, 0, 0, nil
	for _, fam in ipairs(FAMS) do
		for t = 1, 82 do
			rows += 1
			local now = MineOreTools.craftCost(fam, t)
			local card = C.toolCraftCost(t, MineOreTools.typeMult(fam, t), fam)
			local serverBefore = C.toolCraftCost(t, MineOreTools.typeMult(fam, nil), fam)
			if now == card then same += 1 end
			if serverBefore ~= card then
				oldDiff += 1
				firstDiff = firstDiff or string.format("%s tier %d: card %d, server charged %d", fam, t, card, serverBefore)
			end
		end
	end
	check("craftCost is the card's number for every ore x family", same == rows,
		string.format("%d of %d", same, rows))
	check("...and the server's old tierless price really differed", oldDiff > 0,
		string.format("%d rows, first: %s", oldDiff, tostring(firstDiff)))
	check("...from pickaxe ore tier 7 up, as the audit said",
		C.toolCraftCost(6, MineOreTools.typeMult("pickaxe", nil), "pickaxe") == MineOreTools.craftCost("pickaxe", 6)
		and C.toolCraftCost(7, MineOreTools.typeMult("pickaxe", nil), "pickaxe") ~= MineOreTools.craftCost("pickaxe", 7))
end

-- S11. hitPower is the arithmetic equippedTool ran inline, verbatim.
local function serverBefore(row, skin)
	local famId = row.familyId or "pickaxe"
	local typeMult = MineOreTools.typeMult(famId, row.tier)
	local lvl = math.max(1, tonumber(row.level) or 1)
	local famPow = (MineOreTools.familyPower and MineOreTools.familyPower(famId)) or 1
	local power = math.max(1, math.floor(C.toolPower(row.tier, lvl, typeMult) * famPow * skin))
	if row.nightmare then
		power = math.max(1, math.floor(power * (C.NIGHTMARE_MULT or 4.5)))
	elseif row.shadow then
		power = math.max(1, math.floor(power * (C.SHADOW_MULT or 3)))
	elseif row.shiny then
		power = math.max(1, math.floor(power * (C.SHINY_MULT or 1.5)))
	end
	return power
end
do
	local rows, moved, cardDiff = 0, 0, 0
	local finishes = { {}, { shiny = true }, { shadow = true }, { nightmare = true }, { shiny = true, shadow = true } }
	for _, fam in ipairs(FAMS) do
		for t = 1, 82, 3 do
			for _, lv in ipairs({ 1, 7, 18, 30 }) do
				for _, skin in ipairs({ 1, 1.15, 1.9, 3, 5.5 }) do
					for _, fin in ipairs(finishes) do
						local row = { familyId = fam, tier = t, level = lv,
							shiny = fin.shiny, shadow = fin.shadow, nightmare = fin.nightmare }
						rows += 1
						local now = MineOreTools.hitPower(row, skin)
						if now ~= serverBefore(row, skin) then moved += 1 end
						-- The card's old number: toolPower alone.
						if math.floor(C.toolPower(t, lv, MineOreTools.typeMult(fam, t))) ~= now then
							cardDiff += 1
						end
					end
				end
			end
		end
	end
	check("hitPower is exactly the swing's old inline arithmetic (nothing held moved)", moved == 0,
		string.format("%d of %d rows differ", moved, rows))
	check("...and the card's old toolPower-only number really differed", cardDiff > 0,
		string.format("%d of %d rows", cardDiff, rows))
	local hammer = MineOreTools.hitPower({ familyId = "hammer", tier = 1, level = 1 })
	local oldCard = math.floor(C.toolPower(1, 1, MineOreTools.typeMult("hammer", 1)))
	check("a Stone Hammer card now says what it hits (the audit's 10 vs 37)", hammer == 37 and oldCard == 10,
		string.format("card was %d, hits %d", oldCard, hammer))
end

-- The inherited level, as the craft verb stamps it.
check("an empty rack forges at level 1", MineOreTools.inheritedLevel({}) == 1 and MineOreTools.inheritedLevel(nil) == 1)
check("a forge takes the best level on the rack",
	MineOreTools.inheritedLevel({ { level = 3 }, { level = 12 }, "junk", { level = 7 } }) == 12)
check("...clamped to the cap", MineOreTools.inheritedLevel({ { level = 99 } }) == C.TOOL_MAX_LEVEL)

-- What each class says about how it is used and what it clears.
do
	local function card(fam, t) return MineOreTools.cardStats({ familyId = fam, tier = t, level = 1 }, 1) end
	local p, h, d, j, e = card("pickaxe", 40), card("hammer", 40), card("drill", 82), card("jackhammer", 82), card("explosive", 82)
	check("pickaxe: swing, one block", p.use == "swing" and p.area == "1 block", p.use .. " / " .. p.area)
	check("hammer: swing, one block two deep", h.use == "swing" and h.area == "1 block, 2 deep", h.use .. " / " .. h.area)
	check("drill: hold, its bore", d.use == "hold" and d.area == "3x3", d.use .. " / " .. d.area)
	check("jackhammer: hold, down only", j.use == "hold, down only" and j.area == "3x3", j.use .. " / " .. j.area)
	check("explosive: throw, bombs x blocks", e.use == "throw" and e.area == "3 x 33 blocks", e.use .. " / " .. e.area)
	local fs = MineOreTools.frameStats("explosive", 82)
	check("a thrown explosive's hits a second are its bombs over its cooldown",
		math.abs(e.perSec - fs.bombs / fs.cooldown) < 1e-9, string.format("%.3f", e.perSec))
	check("a swung tool's hits a second are its frame rate",
		p.perSec == MineOreTools.frameStats("pickaxe", 40).rate)
	check("the card's hit is hitPower", p.hit == MineOreTools.hitPower({ familyId = "pickaxe", tier = 40, level = 1 }, 1))
end

print(fails == 0 and ">>> forge-cards harness OK" or (">>> " .. fails .. " FAILED"))
`;

const tmp = path.join(require("os").tmpdir(), "forge-cards-harness.luau");
fs.writeFileSync(tmp, harness);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" });
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
}
process.stdout.write(out);
if (!/>>> forge-cards harness OK/.test(out)) fails++;

console.log(fails === 0 ? ">>> forge-cards OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
