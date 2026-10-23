// EVERY PAID RANDOM BUY SHOWS ITS ODDS FIRST, AND THE REGION RULE COVERS IT.
//
// Owner, 2026-10-19 (launch audit M3, wiki open-questions §0e): "odds on every
// paid random buy" -- credits, gems and tokens all trace back to Robux here --
// "and the region block also covers credit deals, trader cases and the wheel".
// The audit found four buys with no odds (the Mystery Case buyer, the Charms
// Pack, the Forge's 3 random books, the wandering traders' cases) and three
// doors the PolicyNoRandom block skipped.
//
// Two halves, the same as lucky-odds.js:
//   1. EVERY DOOR. Each buy has an ODDS / ⓘ button that opens a sheet, and the
//      server's paid-random list covers the three new doors (statically).
//   2. THE ODDS ARE THE ODDS ROLLED. The new odds functions are RUN against the
//      real roll functions they describe: MineCharms.packOdds vs rollPack,
//      charmPackOdds vs rollCharmPack (the eight Charm Packs, 2026-10-19),
//      chestCharmOdds vs rollChestCharm, MineEnchants.bookOdds vs rollBookId,
//      MineTrader.caseOdds vs rollCase, and MineCases.wildGradeOdds(paid) vs
//      rollWildSet -- so a sheet cannot drift from what the server rolls.
//
// Run: node tools/verify/paid-odds.js
const fs = require("fs"), path = require("path"), os = require("os"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const SH = "src/ReplicatedStorage/Mine/Shared/";
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const codeOnly = (s) => s.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");

const SRV = codeOnly(read("src/ServerScriptService/Mine/MineServer.server.luau"));
const CLIENT = codeOnly(read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau"));
const INV = codeOnly(read(SH + "MineInventoryView.luau"));
const FORGE = codeOnly(read(SH + "MineForgeHub.luau"));

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};
// A percentage typed into code: "12.5%" or "12%" outside a format string.
const typedPct = (s) => /\d+(\.\d+)?%/.test(s.replace(/"[^"\n]*%[^"\n]*"/g, (m) => (/\d%/.test(m.replace(/%%/g, "")) ? m : '""')));

console.log("paid-odds: every paid random buy shows its odds, and the odds are the rolled ones");

// ------------------------------------------------------- the region rule --
const paidRandom = (SRV.match(/Verbs\.PAID_RANDOM = \{[\s\S]*?\n\}/) || [""])[0];
ok(paidRandom.length > 0, "found Verbs.PAID_RANDOM");
ok(/buyProductCredits = function\(/.test(paidRandom) && /isRandomBuy\(key\)/.test(paidRandom),
  "credit deals: buyProductCredits is blocked when the deal pays anything random (isRandomBuy)");
ok(/buyTraderCase = true/.test(paidRandom), "trader cases: buyTraderCase is blocked");
ok(/groupWheelSpin = function\(/.test(paidRandom) && /freeLeft/.test(paidRandom) && /\.paid\)/.test(paidRandom),
  "the wheel: groupWheelSpin is blocked only when it would spend a BOUGHT spin");
const policy = (SRV.match(/function Verbs\.policyBlocks\(plr, action, payload\)[\s\S]*?\nend\n/) || [""])[0];
ok(/type\(rule\) == "function"/.test(policy) && /pcall\(rule, plr, payload/.test(policy),
  "Verbs.policyBlocks runs a function rule with the request's payload");
ok(/Verbs\.policyBlocks\(plr, action, payload\)/.test(SRV), "...and the dispatcher hands it the payload");
for (const v of ["buyCart", "buyDustCase", "buyCharmsPack", "buyCharmPack", "enchBuyBundle"]) {
  ok(new RegExp(`\\b${v} = true`).test(paidRandom), `${v} is still on the list`);
}

// ------------------------------------------------------------ the doors --
const buyer = (INV.match(/local function mysteryBuyer\([\s\S]*?\n\tend\n/) || [""])[0];
ok(buyer.length > 0, "found the Mystery Case buyer");
ok(/Text = "ODDS"/.test(buyer) && /showPackInspect\(\{[\s\S]*?paid = not isDust/.test(buyer),
  "the Mystery Case buyer has ODDS: the case inspector, credit-bought odds in the credit shop");
const fwd = INV.indexOf("local showPackInspect\n"), mb = INV.indexOf("local function mysteryBuyer("),
  def = INV.indexOf("function showPackInspect(g)");
ok(fwd > -1 && fwd < mb && def > mb && !/local function showPackInspect\(/.test(INV),
  "...and the inspector it calls is forward-declared above it (no nil-global read)");
ok(/Cases\.wildGradeOdds\(g\.paid == true\)/.test(INV), "the inspector shows a credit-bought case's exact split");
ok(/heroOdds\.MouseButton1Click:Connect\(function\(\)[\s\S]*?showPackInspect\(/.test(INV),
  "the Packs hero (the 5-star wild case) has ODDS");
const box = (INV.match(/elseif activeTab == "box" then[\s\S]*?elseif activeTab == "limited" then/) || [""])[0];
ok(/infoBadge\(tile, \{[\s\S]*?paid = true/.test(box), "every Build-a-Box tile has its ⓘ (the box sells wild cases too)");
// 2026-10-19: the one Charms Pack became eight Charm Packs, F to SSS.
ok(/Charms\.charmPackOdds\(pack\.rarity\)/.test(INV) && /View\.sheet\(root, \{\s*title = string\.upper\(pack\.name\) \.\. "  ODDS"/.test(INV),
  "each of the eight Charm Packs has ODDS, from MineCharms.charmPackOdds");
ok(/E\.bookOdds\(\)/.test(FORGE) && /View\.sheet\(root, \{[\s\S]*?BOOK BUNDLE  ODDS/.test(FORGE),
  "the Forge's book bundle has ODDS, from MineEnchants.bookOdds");
const traderOdds = (CLIENT.match(/function ClientFns\.traderOdds\([\s\S]*?\nend\n/) || [""])[0];
ok(/Trader\.caseOdds\(/.test(traderOdds) && /View\.sheet\(/.test(traderOdds),
  "a trader case's ODDS come from MineTrader.caseOdds");
const shop = (CLIENT.match(/function ClientFns\.showTraderShop\([\s\S]*?\nend\n/) || [""])[0];
ok(/Text = "ODDS"/.test(shop) && /ClientFns\.traderOdds\(f, row\)/.test(shop), "...and every row of the trader's shelf has the button");
ok(!typedPct(traderOdds), "...with no percentage typed in by hand");
const forgeOdds = (FORGE.match(/local oddsB = pill\(shop, "ODDS"[\s\S]*?\n\t\tend\)/) || [""])[0];
ok(forgeOdds.length > 0 && !typedPct(forgeOdds), "the Forge sheet types no percentage either");
ok(/local familyId = reward\.familyId/.test(SRV) && !/\(\{ "pickaxe", "drill", "explosive" \}\)\[/.test(SRV),
  "the server takes a trader tool's family from the roll the sheet describes");
// S2 (owner, 2026-10-19): the Lucky Charm "599 CR" row beside the Charms Pack only
// ever answered "That offer moved". It is gone from every screen; the server keeps
// refusing it, so an old client still cannot buy it.
const views = fs.readdirSync(path.join(ROOT, SH)).filter((f) => /View|Hub/.test(f) && f.endsWith(".luau"))
  .map((f) => codeOnly(read(SH + f))).concat([CLIENT]);
ok(views.length > 5 && !views.some((s) => /"Lucky Charm"|onBuyProductCredits\("lucky_charm"\)|onBuyLuckyCharm\(\)/.test(s)),
  "no screen offers the dead Lucky Charm row any more (S2)", `${views.length} UI files`);
ok(/if key == "lucky_charm" or key == "lucky_block_pet" then\s*net:FireClient\(plr, "toast", "That offer moved/.test(SRV),
  "...and the server still refuses buyProductCredits(\"lucky_charm\")");

// ---------------------------------------------------- the odds are real --
if (!Luau.ready) {
  console.log("  " + Luau.missing("luau"));
  console.log(fails === 0 ? ">>> paid-odds OK (static only)" : `>>> ${fails} FAILED`);
  process.exit(fails === 0 ? 0 : 1);
}

// The real roster, so MineCharms builds its real lists (the same reading charms.js does).
const cfg = read(SH + "MineConfig.luau");
const ores = [...cfg.matchAll(/\{ id = "(\w+)", name = "([^"]+)", tier = (\d+),/g)].map((m) => ({ id: m[1], name: m[2], tier: +m[3] }));
const cuts = [...cfg.matchAll(/\{ upTo = (\d+), lo = \d+, hi = \d+ \}/g)].map((m) => +m[1]);
const BANDS = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic"];
const bandFor = (t) => { for (let i = 0; i < cuts.length; i++) if (t <= cuts[i]) return [BANDS[i], i + 1]; return [BANDS[7], 8]; };
const oreRows = ores.map((o) => { const [b, bi] = bandFor(o.tier); return `{ id = "${o.id}", name = "${o.name}", tier = ${o.tier}, band = "${b}", bandIndex = ${bi}, homeHp = 20 },`; }).join("\n");
// MineTemper's real ladder, read rather than retyped.
const temper = read(SH + "MineTemper.luau");
const gradeOrder = (temper.match(/MineTemper\.GRADE_ORDER = (\{[^}]*\})/) || [])[1];
const rarityWeights = (temper.match(/MineTemper\.RARITY_WEIGHTS = (\{[\s\S]*?\})/) || [])[1];
ok(!!gradeOrder && !!rarityWeights, "read MineTemper's grade ladder and weights");

// The 19 sets' data modules, for MineCases (its sets come from MineSetPets).
const setDir = path.join(ROOT, SH, "SetPets");
let setMods = "";
for (const f of fs.readdirSync(setDir).filter((x) => x.endsWith(".luau"))) {
  setMods += `MODULES["SetPets/${f.replace(".luau", "")}"] = (function()\n${Luau.readSrc(path.join(setDir, f))}\nend)()\n`;
}

const harness = `
Color3 = { fromRGB = function() return {} end, fromHSV = function() return {} end, new = function() return {} end }
Enum = setmetatable({}, { __index = function() return setmetatable({}, { __index = function(_, k) return { Name = k } end }) end })
-- A Lehmer generator: good enough to compare draw frequencies with odds.
Random = {}
Random.__index = Random
function Random.new(seed) return setmetatable({ s = (tonumber(seed) or 48611) % 2147483647 }, Random) end
function Random:NextNumber() self.s = (self.s * 48271) % 2147483647 return self.s / 2147483647 end
function Random:NextInteger(a, b) return a + math.floor(self:NextNumber() * (b - a + 1)) end
warn = function() end

local MODULES = {}
${setMods}
local SETPETS = { Name = "SetPets", GetChildren = function()
	local out = {}
	for k in pairs(MODULES) do
		local n = string.match(k, "^SetPets/(.+)$")
		if n then table.insert(out, { Name = n, _key = k, IsA = function() return true end }) end
	end
	return out
end }
local SHARED = {
	WaitForChild = function(_, n) return { Name = n } end,
	FindFirstChild = function(_, n)
		if n == "SetPets" then return SETPETS end
		return nil
	end,
}
script = { Name = "harness", Parent = SHARED }
function require(t)
	local n = type(t) == "table" and (t._key or t.Name) or tostring(t)
	local m = MODULES[n]
	if m == nil then error("no stub for " .. n) end
	return m
end
MODULES.MineConfig = { ORE_COUNT = ${ores.length}, ORE_BAND_ORDER = { ${BANDS.map((b) => JSON.stringify(b)).join(", ")} },
	ZONES = { {id="z1"},{id="z2"},{id="z3"},{id="z4"},{id="z5"},{id="z6"},{id="z7"},{id="z8"},{id="z9"},{id="z10"},{id="z11"} },
	ORES = {
${oreRows}
	} }
function MODULES.MineConfig.zoneIndex(id)
	for i, z in ipairs(MODULES.MineConfig.ZONES) do if z.id == id then return i end end
	return 1
end
MODULES.MineTemper = { GRADE_ORDER = ${gradeOrder}, RARITY_WEIGHTS = ${rarityWeights} }
MODULES.MineCharms = (function()
${read(SH + "MineCharms.luau")}
end)()
MODULES.MineEnchants = (function()
${read(SH + "MineEnchants.luau")}
end)()
MODULES.MineTrader = (function()
${read(SH + "MineTrader.luau")}
end)()
MODULES.MineSetPets = (function()
${read(SH + "MineSetPets.luau")}
end)()
MODULES.MineSetPacks = (function()
${read(SH + "MineSetPacks.luau")}
end)()
MODULES.MinePackArt = { ORDER = {}, SETS = {}, packArt = function() return nil end }
MODULES.MineCases = (function()
${read(SH + "MineCases.luau")}
end)()

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. tostring(detail)) or ""))
	if not cond then fails += 1 end
end
local function sum(rows, key)
	local s = 0
	for _, r in ipairs(rows) do s += r[key or "p"] end
	return s
end
-- The largest gap between how often each key came up in N draws and its odds.
local function gap(odds, draw, N)
	local seen = {}
	for _ = 1, N do
		local k = draw()
		seen[k] = (seen[k] or 0) + 1
	end
	local worst, at = 0, "-"
	for k, p in pairs(odds) do
		local d = math.abs((seen[k] or 0) / N - p)
		if d > worst then worst, at = d, tostring(k) end
	end
	for k in pairs(seen) do
		if odds[k] == nil then return 1, "drew " .. tostring(k) .. ", which the odds do not list" end
	end
	return worst, at
end

-- ---------------------------------------------------------- Charms Pack --
local Charms = MODULES.MineCharms
local pool = Charms.packPool()
check("the Charms Pack has charms to draw", #pool > 3, #pool)
local owned = { [pool[1].id] = 1, [pool[2].id] = true }
local po = Charms.packOdds(owned)
check("packOdds leaves out what you own", #po == #pool - 2, #po)
check("...and sums to 1", math.abs(sum(po) - 1) < 1e-9, sum(po))
local want = {}
for _, r in ipairs(po) do want[r.id] = r.p end
local rng = Random.new(11)
local w, at = gap(want, function() return Charms.rollPack(owned, rng).id end, 60000)
check("rollPack draws what packOdds says", w < 0.01, string.format("worst gap %.2f%% at %s", w * 100, at))
local all = {}
for _, d in ipairs(pool) do all[d.id] = 1 end
check("owning them all: no odds and no draw", #Charms.packOdds(all) == 0 and Charms.rollPack(all, rng) == nil)

-- ------------------------------------ the eight Charm Packs (2026-10-19) --
-- (The old Charms Pack above is off sale; its functions stay for old callers.)
for _, pk in ipairs(Charms.CHARM_PACKS or {}) do
	local odds = Charms.charmPackOdds(pk.rarity)
	local cp = {}
	for _, r in ipairs(odds) do cp[r.id] = r.p end
	local wc, atc = gap(cp, function() return Charms.rollCharmPack(pk.rarity, rng).id end, 40000)
	check(pk.name .. ": rollCharmPack draws what charmPackOdds says",
		#odds > 0 and math.abs(sum(odds) - 1) < 1e-9 and wc < 0.012,
		string.format("%d charms, worst gap %.2f%% at %s", #odds, wc * 100, atc))
end
check("eight Charm Packs", #(Charms.CHARM_PACKS or {}) == 8, #(Charms.CHARM_PACKS or {}))

-- ----------------------------------------------- the chest charm ladder --
local co = Charms.chestCharmOdds()
check("chestCharmOdds sums to 1", math.abs(sum(co) - 1) < 1e-9, sum(co))
local byGrade = {}
for _, r in ipairs(co) do byGrade[r.grade] = r.p end
w, at = gap(byGrade, function() return Charms.rollChestCharm(rng).rarity end, 200000)
check("rollChestCharm draws grades as chestCharmOdds says", w < 0.005, string.format("worst gap %.3f%% at %s", w * 100, at))

-- ------------------------------------------------ the Forge's book bundle --
local E = MODULES.MineEnchants
local bo = E.bookOdds()
-- Every enchant but the Halloween four, whose books come only from Candy
-- Crypt chests (MineEnchants.rollHalloweenBook, owner 2026-10-19).
local mainBooks = 0
for _, d in ipairs(E.LIST) do if d.event == nil then mainBooks += 1 end end
check("bookOdds lists every enchant a bundle can roll", #bo == mainBooks and mainBooks >= 22, #bo)
check("...and sums to 1", math.abs(sum(bo) - 1) < 1e-9, sum(bo))
local books = {}
for _, r in ipairs(bo) do books[r.id] = r.p end
w, at = gap(books, function() return E.rollBookId(rng) end, 200000)
check("rollBookId draws what bookOdds says", w < 0.005, string.format("worst gap %.3f%% at %s", w * 100, at))
local lv1 = true
for _ = 1, 500 do
	for _, b in ipairs(E.rollBundle(E.SHOP_BUNDLE, rng)) do
		if b.level ~= 1 then lv1 = false end
	end
end
check("a shop bundle's books are always level I, as the sheet says", lv1)

-- ---------------------------------------------------- the trader's cases --
local Trader = MODULES.MineTrader
for _, c in ipairs(Trader.CASES) do
	local odds = Trader.caseOdds(c.id)
	if c.kind == "tool" then
		check(c.id .. ": tiers and families each sum to 1",
			math.abs(sum(odds.tiers) - 1) < 1e-9 and math.abs(sum(odds.families) - 1) < 1e-9)
		local tiers, fams = {}, {}
		for _, r in ipairs(odds.tiers) do tiers[r.tier] = r.p end
		for _, r in ipairs(odds.families) do fams[r.id] = r.p end
		local wt, at1 = gap(tiers, function() return Trader.rollCase(c.id, rng).tier end, 60000)
		local wf, at2 = gap(fams, function() return Trader.rollCase(c.id, rng).familyId end, 30000)
		check(c.id .. ": rollCase rolls the tiers and families the sheet shows",
			wt < 0.012 and wf < 0.012, string.format("tier gap %.2f%% at %s, family gap %.2f%% at %s", wt * 100, at1, wf * 100, at2))
	else
		check(c.id .. ": grades sum to 1", math.abs(sum(odds.grades) - 1) < 1e-9, sum(odds.grades))
		local grades = {}
		for _, r in ipairs(odds.grades) do grades[r.grade] = (grades[r.grade] or 0) + r.p end
		local wg, at3 = gap(grades, function() return Trader.rollCase(c.id, rng).rarity end, 200000)
		check(c.id .. ": rollCase rolls the grades the sheet shows", wg < 0.005, string.format("worst gap %.3f%% at %s", wg * 100, at3))
	end
end
check("an unknown case has no odds", Trader.caseOdds("nope") == nil)

-- --------------------------------------------------- the mystery cases --
local Cases = MODULES.MineCases
check("the wild cases read their 19 sets", #Cases.SETS == 19, #Cases.SETS)
local paidRows = Cases.wildGradeOdds(true)
check("a credit-bought case's grade odds sum to 100%", math.abs(sum(paidRows, "pct") - 100) < 1e-6, sum(paidRows, "pct"))
local free, flagged = 0, 0
for _, r in ipairs(Cases.wildGradeOdds()) do
	if r.paidOnly then flagged += 1 else free += r.pct end
end
check("an earned case's odds sum to 100%, with the credit-only grade flagged", math.abs(free - 100) < 1e-6 and flagged >= 1,
	string.format("%.6f, %d flagged", free, flagged))
local gradeOf = {}
for _, s in ipairs(Cases.SETS) do gradeOf[s.key] = s.grade end
local paidOdds = {}
for _, r in ipairs(paidRows) do paidOdds[r.grade] = r.pct / 100 end
w, at = gap(paidOdds, function() return gradeOf[Cases.rollWildSet(rng, true)] end, 400000)
check("rollWildSet(paid) draws the grades the credit shop shows", w < 0.003, string.format("worst gap %.3f%% at %s", w * 100, at))

print(fails == 0 and ">>> paid-odds: all assertions passed" or (">>> paid-odds: " .. fails .. " FAILED"))
`;

const script = path.join(os.tmpdir(), `mfc-paid-odds-${process.pid}.luau`);
fs.writeFileSync(script, harness);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [script], { encoding: "utf8", maxBuffer: 1 << 26 });
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
} finally {
  try { fs.unlinkSync(script); } catch (e) { /* already gone */ }
}
process.stdout.write(out);
if (!/>>> paid-odds: all assertions passed/.test(out)) {
  fails++;
}
console.log(fails === 0 ? ">>> paid-odds OK" : `>>> paid-odds: ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
