// THE CANDY CRYPT, REDESIGNED (owner, 2026-10-19; wiki/open-questions.md §0e).
//
// Runs the REAL shared modules -- MineConfig, MineDepth, MineCandyTools,
// MineTrickOrTreat, MineCryptRules, MineCharms, MineOrePouch, MineSpaceMatter,
// MineBreaking, MineOreTools and the rest of their require tree -- and the real
// server module MineCrypt, in luau, on a small Roblox stub. Nothing about the
// Crypt is re-derived in JS: the numbers below come out of the modules.
//
// What it pins, in the order the build spec lists them:
//   tool gating     only Crypt tools spend Crypt rock; Crypt tools spend no
//                   other rock during the event; Event Horizon's two pools are
//                   unchanged; the swap rule (MineCryptRules.heldRow)
//   drop tables     Trick-or-Treat 85 / 5 / 7 / 2.9 / 0.1 with no candy back,
//                   the case's tool tiers, the chest's banded tool roll
//   candy 3x        every candy block pays 3x the 2026-10-10 amount
//   HP curve        zone 3 hardness at the top, zone 10 at the bottom, and the
//                   coin value kept on the old low curve
//   candy ores      sixteen, the four new ones in by value, two per band
//   merge ladder    3 x (tool, variant) -> 1 x next variant, pets' multipliers
//   keep-after-event  tools stay; main-world use only once the Crypt has
//                   closed, weaker than in the event
//   charm recipes   six Halloween charms, deeper ore -> better grade
//   pouch           SELL ALL never sells locked or candy ores; "sell up to"
//   wiring          the MineServer hooks exist where the build spec says
//
// Needs the luau binary (bash tools/verify/syntax.sh fetches it).
//
//   node tools/verify/crypt.js
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");

const ROOT = path.resolve(__dirname, "../..");
const SH = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared");
const SV = path.join(ROOT, "src/ServerScriptService/Mine");
const read = (p) => Luau.readSrc(p);

let fail = 0;
const check = (ok, msg, detail) => {
  console.log((ok ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!ok) fail++;
};
const strip = (s) => s.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");

console.log("crypt: the Candy Crypt redesign -- rules, drops, gating, merge, keep-after-event");

// ------------------------------------------------------------ static wiring --
const srv = strip(read(path.join(SV, "MineServer.server.luau")));
const bodyOf = (name) => {
  const lines = srv.split("\n");
  const re = new RegExp("^(local )?function " + name.replace(/\./g, "\\.") + "\\s*\\(");
  const i = lines.findIndex((l) => re.test(l));
  if (i < 0) return "";
  for (let j = i + 1; j < lines.length; j++) if (lines[j] === "end") return lines.slice(i, j + 1).join("\n");
  return "";
};
{
  const bz = bodyOf("buyZone");
  check(/C\.limitedActive\(zone\.id\)/.test(bz) && /zone\.ownedFlag/.test(bz),
    "buyZone claims a limited zone on ITS window and ITS flag (audit M2)");
  check(!/^\s*p\.bigbangOwned = true/m.test(bz),
    "buyZone no longer sets bigbangOwned for whatever zone was claimed");
  check(/Verbs\.Crypt\.onClaim\(/.test(bz), "claiming the Crypt in buyZone grants the starter pick");
  const ez = bodyOf("enterZone");
  check(/Dig\.Crypt\.onClaim\(/.test(ez) && /Dig\.Crypt\.onEnterZone\(/.test(ez),
    "enterZone grants the starter on a free claim and re-gives the hands on entry");
  const et = bodyOf("equippedTool");
  const ehAt = et.indexOf('p.zoneId == "bigbang"');
  const crAt = et.indexOf("Dig.Crypt.heldTool(p)");
  check(ehAt > -1 && crAt > ehAt, "equippedTool swaps in the Crypt tool, after Event Horizon's own branch");
  for (const fn of ["swingBlock", "swingNeighbour"]) {
    check(/if zone and zone\.noStrengthGate then\s+okBreak = true/.test(bodyOf(fn)),
      fn + " honours the zone's noStrengthGate (the Crypt's HP is its gate)");
  }
  check(/zoneId == "hallow" and Dig\.Crypt[\s\S]{0,80}Dig\.Crypt\.haulPoints\(/.test(bodyOf("payDamage")),
    "payDamage pays the Crypt's haul on the old low curve");
  const fb = bodyOf("finishBreak");
  const candyAt = fb.indexOf("Dig.Crypt.onBlockBroken(");
  const oreAt = fb.indexOf('if kind == "ore" then');
  check(candyAt > -1 && oreAt > candyAt, "a candy block pays OUTSIDE the ore branch (any kind of block)");
  check(!/GetAttribute\("Candy"\)\)\s*\n\s*if candyGot/.test(fb), "the old ore-only candy payout is gone (no double pay)");
  check(/GetAttribute\("ZoneId"\) == "hallow"[\s\S]{0,60}Dig\.Crypt\.openChest\(/.test(bodyOf("openChestBlock")),
    "a Crypt chest opens through MineCrypt");
  check(/part:SetAttribute\("Candy", C\.candyFor\(cdef, y\)\)/.test(bodyOf("spawnVoxel")),
    "spawnVoxel banks candy through MineConfig.candyFor (3x)");
  check(/string\.sub\(action, 1, 5\) == "crypt"[\s\S]{0,120}Verbs\.Crypt\.dispatch\(/.test(srv),
    "every \"crypt*\" action dispatches to MineCrypt");
  check(/crypt = Dig\.Crypt and Dig\.Crypt\.snapState\(p\)/.test(srv) && /limitedOpen = \(function\(\)/.test(srv),
    "the snapshot carries the crypt block and every limited zone's own open state");
  const sa = bodyOf("Verbs.sellAllOres");
  check(/Pouch\.sellAllPlan\(p\.ores, p\.oreLocks, upTo\)/.test(sa) && /oreSellUpTo/.test(sa),
    "SELL ALL takes and remembers a sell-up-to ceiling");
  check(/Verbs\.Crypt\.buyTrickOrTreat\(plr\)/.test(bodyOf("Verbs.buyTrickOrTreat")),
    "the Trick-or-Treat verb is served by MineCrypt");
  const map = strip(read(path.join(SH, "MineZoneMapView.luau")));
  const fx = strip(read(path.join(SH, "MinePortalFX.luau")));
  check(/zone\.ownedFlag/.test(map) && /limitedOpen/.test(map) && /zone\.ownedFlag/.test(fx) && /limitedOpen/.test(fx),
    "Planets Travel and the portals read each limited zone's own flag and window");
}

if (!Luau.ready) {
  console.log("  " + Luau.missing("luau") + "; skipping the luau half");
  console.log(fail === 0 ? ">>> crypt OK (static only)" : `>>> crypt: ${fail} FAILED`);
  process.exit(fail === 0 ? 0 : 1);
}

// --------------------------------------------------------------- the luau half --
const MODULES = {
  MineConfig: path.join(SH, "MineConfig.luau"),
  MineDepth: path.join(SH, "MineDepth.luau"),
  MineBags: path.join(SH, "MineBags.luau"),
  MineBagNames: path.join(SH, "MineBagNames.luau"),
  MineShopEconomy: path.join(SH, "MineShopEconomy.luau"),
  MineLaunch: path.join(SH, "MineLaunch.luau"),
  MineTools: path.join(SH, "MineTools.luau"),
  MineOreTools: path.join(SH, "MineOreTools.luau"),
  MineBreaking: path.join(SH, "MineBreaking.luau"),
  MineStats: path.join(SH, "MineStats.luau"),
  MineTemper: path.join(SH, "MineTemper.luau"),
  MineCharms: path.join(SH, "MineCharms.luau"),
  MineOrePouch: path.join(SH, "MineOrePouch.luau"),
  MineSpaceMatter: path.join(SH, "MineSpaceMatter.luau"),
  MineCandyTools: path.join(SH, "MineCandyTools.luau"),
  MineTrickOrTreat: path.join(SH, "MineTrickOrTreat.luau"),
  MineCryptRules: path.join(SH, "MineCryptRules.luau"),
  MineCrypt: path.join(SV, "MineCrypt.luau"),
};
const factories = Object.entries(MODULES).map(([name, file]) =>
  `FACTORY[${JSON.stringify(name)}] = function()\n` +
  `\tlocal script = { Name = ${JSON.stringify(name)}, Parent = ${name === "MineCrypt" ? "SERVERDIR" : "SHARED"} }\n` +
  read(file) + "\nend\n").join("\n");

const prelude = `
-- ------------------------------------------------------------ roblox stub --
local V3 = {}
V3.__index = V3
Vector3 = {}
function Vector3.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
end
V3.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__mul = function(a, b)
	if type(a) == "number" then return Vector3.new(b.X * a, b.Y * a, b.Z * a) end
	if type(b) == "number" then return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
	return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b) return Vector3.new(a.X / b, a.Y / b, a.Z / b) end
V3.__unm = function(a) return Vector3.new(-a.X, -a.Y, -a.Z) end
Vector3.zero = Vector3.new(0, 0, 0)
Vector3.one = Vector3.new(1, 1, 1)
Vector2 = { new = function(x, y) return { X = x or 0, Y = y or 0 } end }
local function c3(r, g, b) return { R = r or 0, G = g or 0, B = b or 0, Lerp = function(self) return self end } end
Color3 = {
	fromRGB = function(r, g, b) return c3((r or 0) / 255, (g or 0) / 255, (b or 0) / 255) end,
	new = function(r, g, b) return c3(r, g, b) end,
	fromHSV = function(h, s, v) return c3(v, v, v) end,
	fromHex = function() return c3(1, 1, 1) end,
}
local any = setmetatable({}, { __index = function() return function() return {} end end })
CFrame = setmetatable({ new = function() return {} end }, { __index = function() return function() return {} end end })
UDim2 = any
UDim = any
NumberRange = any
NumberSequence = any
NumberSequenceKeypoint = any
ColorSequence = any
ColorSequenceKeypoint = any
TweenInfo = any
Font = any
local enumCache = {}
Enum = setmetatable({}, { __index = function(_, k)
	local t = enumCache[k]
	if not t then
		t = setmetatable({}, { __index = function(_, k2) return { Name = k2, EnumType = k } end })
		enumCache[k] = t
	end
	return t
end })
-- A seeded generator, so every roll below is the same on every run.
Random = {}
Random.__index = Random
local seedCounter = 977
function Random.new(seed)
	seedCounter += 7919
	return setmetatable({ s = ((seed or seedCounter) % 2147483646) + 1 }, Random)
end
function Random:NextNumber(a, b)
	self.s = (self.s * 48271) % 2147483647
	local u = self.s / 2147483647
	if a and b then return a + (b - a) * u end
	return u
end
function Random:NextInteger(a, b)
	return a + math.floor(self:NextNumber() * (b - a + 1))
end
warn = function(...) end
task = { wait = function() end, spawn = function(f, ...) end, delay = function() end, defer = function() end }
typeof = typeof or function(v) return type(v) end

local FACTORY, LOADED = {}, {}
local function inst(name)
	return { Name = name, WaitForChild = function(_, n) return inst(n) end, FindFirstChild = function(_, n)
		if FACTORY[n] then return inst(n) end
		return nil
	end, Clone = function(self) return inst(self.Name) end, Destroy = function() end }
end
SHARED = inst("Shared")
SERVERDIR = inst("Mine")
local MINE = { Name = "Mine", WaitForChild = function() return SHARED end, FindFirstChild = function() return SHARED end }
local RS = { Name = "ReplicatedStorage", WaitForChild = function() return MINE end, FindFirstChild = function() return MINE end }
local guid = 0
local SERVICES = {
	ReplicatedStorage = RS,
	RunService = { IsStudio = function() return false end, IsServer = function() return true end, IsClient = function() return false end },
	ServerStorage = { FindFirstChild = function() return nil end, WaitForChild = function(_, n) return inst(n) end },
	HttpService = {
		GenerateGUID = function()
			guid += 1
			return string.format("%08x-0000-0000-0000-%012x", guid, guid)
		end,
		JSONEncode = function() return "{}" end,
	},
}
game = { GetService = function(_, n) return SERVICES[n] or any end }
workspace = { FindFirstChild = function() return nil end, GetServerTimeNow = function() return os.time() end }

function require(t)
	local n = type(t) == "table" and t.Name or tostring(t)
	if LOADED[n] ~= nil then return LOADED[n] end
	local f = FACTORY[n]
	if not f then error("no module " .. tostring(n)) end
	local m = f()
	LOADED[n] = m
	return m
end

-- Lazily required, stubbed: the pack table (the case's pack slot) and gear.
FACTORY.MinePackConfig = function()
	return { PACK_BY_ID = { halloween_2026 = { id = "halloween_2026", name = "Halloween 2026 Pack", setKey = "halloween_2026" } } }
end
FACTORY.MineGear = function()
	return { rollPiece = function(id, rng, slot) return { id = id, name = "Test Hat", slot = slot } end }
end
FACTORY.MineIcons = function() return {} end
`;

const body = `
local fails = 0
local function check(cond, name, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. tostring(detail)) or ""))
	if not cond then fails += 1 end
end
local function near(a, b, tol) return math.abs(a - b) <= tol end

local C = require("MineConfig")
local Depth = require("MineDepth")
local Breaking = require("MineBreaking")
local OreTools = require("MineOreTools")
local Tools = require("MineCandyTools")
local TT = require("MineTrickOrTreat")
local Charms = require("MineCharms")
local Pouch = require("MineOrePouch")
local Matter = require("MineSpaceMatter")
local R = require("MineCryptRules")
local S = require("MineCrypt")
local Temper = require("MineTemper")

-- ------------------------------------------------------------ HP curve --
print("")
local N = C.CANDY_DEPTH_LAYERS
check(C.cryptRockHp(1) == Depth.dirtHp(3, 1), "the Crypt's top rock is zone 3's", C.cryptRockHp(1))
check(C.cryptRockHp(N) == Depth.dirtHp(10, 1), "its bottom rock (layer " .. N .. ") is zone 10's", C.cryptRockHp(N))
do
	local mono, smooth = true, true
	local last = 0
	for l = 1, N + 60 do
		local hp = C.cryptRockHp(l)
		if hp <= last then mono = false end
		if last > 0 and hp / last > 1.2 then smooth = false end
		last = hp
	end
	check(mono, "rock hardens every layer, past the bottom too")
	check(smooth, "...smoothly (no step over 20% between two layers)")
end
check(C.blockHp("dirt", "hallow", 40) == C.cryptRockHp(40) and C.blockHp("chest", "hallow", 40) == C.cryptRockHp(40) * C.CHEST_HP_MULT,
	"blockHp reads the Crypt curve for rock and chests")
check(C.cryptSellHp(1) == 1 and C.cryptSellHp(N) == 3 ^ 11, "the coin value keeps the OLD curve: 1 at the top, 3^11 at the bottom",
	C.cryptSellHp(N))
do
	local worst = 0
	for l = 1, N do
		local paid = C.cryptRockHp(l) * C.cryptHaulRatio(l)
		worst = math.max(worst, math.abs(paid - C.cryptSellHp(l)) / C.cryptSellHp(l))
		if C.cryptHaulRatio(l) > 1 then worst = math.huge end
	end
	check(worst < 1e-9, "a whole Crypt block pays its old-curve coins (haul ratio x HP)")
end
do
	local carry = {}
	local paid = 0
	for _ = 1, C.cryptRockHp(1) do
		paid += S.haulPoints(carry, 1, 1)
	end
	check(paid == C.cryptSellHp(1), "the haul carries fractions: 538 one-point hits at layer 1 still pay 1 coin", paid)
end
check(near(C.oreDifficulty("hallow", 90), math.log(math.max(20, C.cryptSellHp(90)) / 20) / math.log(6), 1e-12),
	"the Crypt's normal-ore mix reads the old curve, not the harder rock")

-- ------------------------------------------------------------ candy ores --
print("")
local CO = C.CANDY_ORES
check(#CO == 16, "sixteen candy ores", #CO)
local want = { pop_rocks = true, milk_chocolate = true, white_chocolate = true, cotton_candy = true }
local found, rising, ids, mats = 0, true, {}, true
for i, o in ipairs(CO) do
	if want[o.id] then found += 1 end
	if i > 1 and o.candy <= CO[i - 1].candy then rising = false end
	if ids[o.id] then rising = false end
	ids[o.id] = true
	if not (o.color and o.material and o.name) then mats = false end
end
check(found == 4, "Pop Rocks, Milk Chocolate, White Chocolate and Cotton Candy are in")
check(rising, "the ladder is in value order (and ids are unique)")
check(mats, "every candy ore has a name, colour and material")
do
	local even, bands = true, {}
	for i, o in ipairs(CO) do
		if not near(o.at, (i - 1) / 15, 1e-9) then even = false end
		bands[o.band] = (bands[o.band] or 0) + 1
		if o.rank ~= i or C.candyOreById(o.id) ~= o then even = false end
	end
	local two = true
	for _, b in ipairs(C.ORE_BAND_ORDER) do
		if bands[b] ~= 2 then two = false end
	end
	check(even, "spaced evenly down the Crypt, top to bottom")
	check(two and CO[1].band == "Common" and CO[16].band == "Exotic", "two candies to each pouch band, Common to Exotic")
end
do
	local seen, top, bottom = {}, 0, 0
	local rng = Random.new(42)
	for l = 1, N do
		for _ = 1, 40 do
			local o = C.candyOreAt(l, rng, N)
			seen[o.id] = true
			if l == 1 and o.id == "candy_corn" then top += 1 end
			if l == N and o.id == "jawbreaker" then bottom += 1 end
		end
	end
	local all = true
	for _, o in ipairs(CO) do if not seen[o.id] then all = false end end
	check(all, "every candy ore turns up somewhere in the Crypt")
	check(top >= 20 and bottom >= 20, "Candy Corn leads the top, Jawbreaker the bottom", top .. " / " .. bottom .. " of 40")
end

-- ------------------------------------------------------------ candy 3x --
print("")
check(C.CANDY_RATE_MULT == 3, "candy is 3x (CANDY_RATE_MULT)")
do
	local ok3 = true
	for _, o in ipairs(CO) do
		for _, l in ipairs({ 1, 15, 47, 88, N }) do
			local old = math.floor(o.candy * C.candySectionMult(l))
			if C.candyFor(o, l) ~= 3 * old then ok3 = false end
		end
	end
	check(ok3, "every candy block pays exactly 3x the 2026-10-10 amount")
	check(C.candyOreValue("candy_corn") >= 1 and C.candyOreValue("jawbreaker") > C.candyOreValue("rock_candy"),
		"a candy ore sells for candy, more the deeper it lives", C.candyOreValue("jawbreaker"))
	check(C.candyOreValue("stone") == 0 and R.candyOreValue("not_a_candy") == 0, "nothing else sells for candy")
end

-- ------------------------------------------------------------ the tool table --
print("")
local all = Tools.all()
check(#all == #Tools.TIERS * #Tools.FAMILIES, "one tool per tier and family", #all)
do
	local okRows, noPrice, fams = true, true, true
	local idSeen = {}
	for _, t in ipairs(all) do
		if idSeen[t.id] or t.power < 1 or not t.rate or t.eventOnly ~= false then okRows = false end
		idSeen[t.id] = true
		if t.price ~= nil or t.currency ~= nil then noPrice = false end
		if not table.find(Tools.FAMILIES, t.family) then fams = false end
		if t.family == "explosive" and not (t.cooldown and t.pattern) then okRows = false end
		if t.family == "drill" and not (t.shape == "dir" and t.width) then okRows = false end
	end
	check(okRows, "every row is a real tool of its family (drills aim, charges throw)")
	check(fams, "every row carries its family (skins resolve by it)")
	check(noPrice, "no row has a price: the candy-tool shop is gone")
	local climbs = true
	for _, fam in ipairs(Tools.FAMILIES) do
		for ti = 2, #Tools.TIERS do
			if Tools.pick(ti, fam).power <= Tools.pick(ti - 1, fam).power then climbs = false end
		end
	end
	check(climbs, "deeper tiers hit harder, in every family")
end
local starter = Tools.byId(Tools.STARTER_ID)
check(starter and starter.tier == 1 and starter.family == "pickaxe", "the starter is the tier-1 pick", Tools.STARTER_ID)
do
	local hitsTop = math.ceil(C.cryptRockHp(1) / starter.power)
	check(hitsTop <= 1, "the starter pick breaks the top in one hit", hitsTop)
	local deepest = {}
	for ti = 1, #Tools.TIERS do
		local pick = Tools.pick(ti, "pickaxe")
		local d = 0
		for l = 1, N + 40 do
			if C.cryptRockHp(l) / pick.power <= Tools.PICK_HITS then d = l end
		end
		deepest[ti] = d
	end
	check(deepest[1] < deepest[2] and deepest[2] < deepest[3], "better tools go deeper (" .. Tools.PICK_HITS .. " hits a block)",
		table.concat(deepest, " / "))
	check(deepest[3] >= N - 15, "the best tier reaches the bottom in reasonable hits", deepest[3])
	check(Tools.tierForLayer(1) == 1 and Tools.tierForLayer(40) == 1 and Tools.tierForLayer(41) == 2
		and Tools.tierForLayer(80) == 2 and Tools.tierForLayer(81) == 3 and Tools.tierForLayer(500) == 3,
		"the chest bands: 1-40, 41-80, 81 down")
end

-- ------------------------------------------------------------ variants and merge --
print("")
check(table.concat(R.VARIANTS, ",") == "Normal,Golden,Prism,Rainbow", "the pets' ladder: Normal, Golden, Prism, Rainbow")
check(R.variantMult("Golden") == C.VARIANT_MULT.Golden and R.variantMult("Rainbow") == C.VARIANT_MULT.Rainbow
	and R.variantMult("Normal") == 1, "with the pets' multipliers (MineConfig.VARIANT_MULT)")
check(R.nextVariant("Prism") == "Rainbow" and R.nextVariant("Rainbow") == nil and R.nextVariant("Shiny") == nil,
	"Rainbow is the top; a card's legacy Shiny is not a tool variant")
check(R.parseKey("candy_toffee_drill|Golden") == "candy_toffee_drill" and R.defOf("candy_toffee_drill|Gold") == nil
	and R.defOf("nope|Golden") == nil, "stack keys parse, and a bad key names nothing")
do
	local key = R.stackKey(Tools.STARTER_ID, "Normal")
	local p = { cryptTools = { [key] = 2 } }
	check(R.mergePlan(p, key) == nil, "two copies do not merge")
	p.cryptTools[key] = 7
	local plan = R.mergePlan(p, key, math.huge)
	check(plan and plan.times == 2 and plan.consumed == 6 and plan.to == R.stackKey(Tools.STARTER_ID, "Golden"),
		"seven copies merge twice, three each, into Golden")
	check(R.inEventPower(starter, "Rainbow", 0) == math.floor(starter.power * C.VARIANT_MULT.Rainbow + 0.5),
		"a Rainbow copy hits for 5.5x")
end

-- ------------------------------------------------------------ the server, end to end --
print("")
local sent = {}
local function lastSent(name)
	for i = #sent, 1, -1 do if sent[i].name == name then return sent[i].payload end end
	return nil
end
local net = { FireClient = function(_, plr, name, payload) table.insert(sent, { name = name, payload = payload }) end }
local plr = { UserId = 7 }
local p = { ores = {}, oreLocks = {}, charms = {}, candy = 0, backpackTier = 1, orePouchTier = 10, hallowOwned = false }
local profiles = { [7] = p }
local given = 0
S.init({
	profiles = profiles, net = net,
	snap = function() end, markDirty = function() end,
	givePickaxe = function() given += 1 end,
	bumpStat = function() end,
	pouchTier = function(q) return q.orePouchTier or 1 end,
	pouchFullToast = function() end,
	chestXp = function() end,
})
S.normalize(p)
check(next(p.cryptTools) == nil, "no claim, no tool")
local crypt = C.zoneById("hallow")
p.hallowOwned = true
S.onClaim(plr, p, crypt)
local skey = R.stackKey(Tools.STARTER_ID, "Normal")
check(S.count(p, skey) == 1 and p.cryptToolEquipped == skey, "claiming the Crypt hands over the starter pick, in hand")
S.onClaim(plr, p, crypt)
check(S.count(p, skey) == 1, "a second claim does not hand over a second one")
do
	local q = { hallowOwned = true }
	S.normalize(q)
	check(S.count(q, skey) == 1, "a save with the claim and no tool gets the starter back on load")
end

-- The window, moved by hand: LIMITED_WINDOWS.hallow is read on every call.
local realWindow = C.LIMITED_WINDOWS.hallow
local now = os.time()
local function duringEvent() C.LIMITED_WINDOWS.hallow = { opensUnix = now - 86400, closesUnix = now + 86400 } end
local function afterEvent() C.LIMITED_WINDOWS.hallow = { opensUnix = now - 2 * 86400, closesUnix = now - 60 } end

duringEvent()
check(R.window().open and not R.window().ended, "the moved window reads open")
p.zoneId = "hallow"
local row, fam, tier = S.heldTool(p)
check(row and row.eventMine == "hallow" and row.cryptTool and fam == "pickaxe" and tier == 1,
	"in the Crypt the player holds their Crypt tool")
check(row.power == starter.power, "at its event power", row.power)
p.zoneId = "meadow"
check(S.heldTool(p) == nil, "outside the Crypt during the event, a Crypt tool is not held")
p.cryptToolWorld = true
check(S.heldTool(p) == nil, "...not even when asked to be")
p.cryptToolWorld = nil
local sentBefore = #sent
S.dispatch(plr, "cryptEquip", { world = true })
check(p.cryptToolWorld == nil and sent[#sent].payload == R.WORLD_LOCKED_TEXT, "holding one out here is refused during the event")
do
	local q = { cryptTools = {}, zoneId = "hallow" }
	local none = R.heldRow(q, "hallow")
	check(none == R.NONE_ROW and none.none == true, "no Crypt tool in the Crypt is empty hands")
end

-- Gating on the block itself (MineSpaceMatter), both damage paths' one rule.
local function part(zoneId, extra)
	local attrs = { ZoneId = zoneId, HP = 100, MaxHP = 100 }
	for k, v in pairs(extra or {}) do attrs[k] = v end
	return { attrs = attrs, GetAttribute = function(self, k) return self.attrs[k] end,
		SetAttribute = function(self, k, v) self.attrs[k] = v end }
end
local normalTool = { id = "oretool_x", name = "Stone Pickaxe", power = 10, oreTier = 1 }
local ehTool = { id = "eh_shallow_pick", eventOnly = true, zoneId = "bigbang", power = 10 }
p.zoneId = "hallow"
local cryptRow = S.heldTool(p)
check(Matter.reject(cryptRow, part("hallow")) == nil and Matter.chip(part("hallow"), cryptRow, 5).ok,
	"a Crypt tool spends Crypt rock")
check(Matter.reject(normalTool, part("hallow")) == Matter.EVENT_ONLY and not Matter.chip(part("hallow"), normalTool, 5).ok,
	"a normal tool does not (\\"" .. Matter.TOAST.eventonly .. "\\")")
check(Matter.reject(R.NONE_ROW, part("hallow")) == Matter.EVENT_ONLY, "empty hands do not")
check(Matter.reject(ehTool, part("hallow")) == Matter.EVENT_ONLY, "an Event Horizon tool does not")
check(Matter.reject(cryptRow, part("meadow")) == Matter.EVENT_TOOL and not Matter.chip(part("meadow"), cryptRow, 5).ok,
	"a Crypt tool's event row spends no other rock")
check(Matter.reject(normalTool, part("meadow")) == nil and Matter.chip(part("meadow"), normalTool, 5).ok,
	"a normal tool on normal rock is untouched")
check(Matter.reject(normalTool, part("bigbang")) == "weak" and Matter.reject(ehTool, part("bigbang")) == nil
	and Matter.reject(ehTool, part("meadow")) == "heavy", "Event Horizon's two pools are unchanged")
check(Matter.reject(cryptRow, part("bigbang")) == Matter.EVENT_TOOL, "a Crypt tool spends no Event Horizon matter")

-- ------------------------------------------------------------ keep after the event --
print("")
afterEvent()
check(R.window().ended and not R.window().open, "the moved window reads ended")
S.ensure(p)
check(S.count(p, skey) == 1, "the event ending takes nothing away")
p.zoneId = "hallow"
check(S.heldTool(p) and S.heldTool(p).eventMine == "hallow", "the Crypt still takes its own tools after the event")
p.zoneId = "meadow"
check(S.heldTool(p) == nil, "out here it is the player's own tool until they choose the Crypt tool")
S.dispatch(plr, "cryptEquip", { world = true })
check(p.cryptToolWorld == true, "after the event, holding it in the main world is allowed")
local wrow = S.heldTool(p)
check(wrow and wrow.world and wrow.eventMine == nil and wrow.breakingPower == Breaking.oreStrength(starter.worldOreTier, #C.ORES),
	"out here it is the world row, with its ore's breaking power")
check(Matter.reject(wrow, part("meadow")) == nil and Matter.reject(wrow, part("hallow")) == Matter.EVENT_ONLY,
	"the world row spends main-world rock, and never the Crypt's")
do
	local weaker, mapped = true, true
	for _, t in ipairs(all) do
		for _, v in ipairs(R.VARIANTS) do
			if R.worldPower(t, v, 0) >= R.inEventPower(t, v, 0) then weaker = false end
			local forged = C.toolPower(t.worldOreTier, 1, OreTools.typeMult(t.family, t.worldOreTier)) * OreTools.familyPower(t.family)
			if R.worldPower(t, v, 0) ~= math.max(1, math.floor(forged * R.variantMult(v) + 0.5)) then mapped = false end
		end
	end
	check(weaker, "every Crypt tool is weaker in the main world than in the event")
	check(mapped, "...exactly a level-1 forged tool of its worldOreTier, times its variant")
end
p.zoneId = "bigbang"
check(S.heldTool(p) == nil, "Event Horizon keeps its own tools, world flag or not")
do
	-- A later event mine takes Crypt tools only once the Crypt has ended.
	table.insert(C.ZONES, { id = "test_event", name = "Test Event", limited = true, eventToolsOnly = true })
	local q = { cryptTools = { [skey] = 1 }, cryptToolEquipped = skey }
	local erow = R.heldRow(q, "test_event")
	check(erow and erow.eventMine == "test_event", "after the Crypt, its tools work in a later event mine")
	duringEvent()
	check(R.heldRow(q, "test_event") == R.NONE_ROW, "...but not while the Crypt is still running")
	table.remove(C.ZONES)
	afterEvent()
end
p.zoneId = "hallow"
p.cryptToolWorld = nil

-- ------------------------------------------------------------ merging, through the verb --
print("")
p.cryptTools[skey] = 9
S.dispatch(plr, "cryptMerge", { key = skey, all = true })
local gkey = R.stackKey(Tools.STARTER_ID, "Golden")
check(S.count(p, skey) == 0 and S.count(p, gkey) == 3, "nine Normal merge into three Golden")
check(p.cryptToolEquipped == gkey, "merging away the tool in hand hands you what it became")
S.dispatch(plr, "cryptMerge", { key = gkey })
local pkey = R.stackKey(Tools.STARTER_ID, "Prism")
check(S.count(p, gkey) == 0 and S.count(p, pkey) == 1, "three Golden merge into one Prism")
S.dispatch(plr, "cryptMerge", { key = pkey })
check(S.count(p, pkey) == 1, "one Prism does not merge")
p.cryptTools[R.stackKey(Tools.STARTER_ID, "Rainbow")] = 3
S.dispatch(plr, "cryptMerge", { key = R.stackKey(Tools.STARTER_ID, "Rainbow") })
check(S.count(p, R.stackKey(Tools.STARTER_ID, "Rainbow")) == 3, "Rainbow is the top and refuses")

-- ------------------------------------------------------------ a candy block --
print("")
duringEvent()
p.candy = 0
local blk = part("hallow", { Candy = C.candyFor(C.candyOreById("taffy"), 33), CandyOre = "taffy" })
blk.Color, blk.Position = Color3.fromRGB(1, 2, 3), Vector3.new(0, 0, 0)
check(S.onBlockBroken(plr, p, blk, "dirt", 33, { candyFind = 1 }), "a candy block of plain rock pays")
check(p.candy == C.candyFor(C.candyOreById("taffy"), 33) and p.ores.taffy == 1, "its candy, and one candy ore into the pouch")
check(p.oresSeen == nil, "a candy ore stays out of oresSeen (the Forge's recipe rail)")
p.candy = 0
S.onBlockBroken(plr, p, blk, "dirt", 33, { candyFind = 1.56 })
check(p.candy == math.floor(C.candyFor(C.candyOreById("taffy"), 33) * 1.56), "Candy Find multiplies it")

-- ------------------------------------------------------------ the pouch --
print("")
p.ores = { stone = 10, coal = 4, taffy = 5, jawbreaker = 2 }
p.oreLocks = { coal = true }
local plan = Pouch.sellAllPlan(p.ores, p.oreLocks)
local soldIds = {}
for _, r in ipairs(plan.rows) do soldIds[r.id] = true end
check(soldIds.stone and not soldIds.coal and not soldIds.taffy and not soldIds.jawbreaker,
	"SELL ALL sells neither locked ores nor candy ores", "candy skipped: " .. tostring(plan.candyUnits))
local deep = C.ORES[#C.ORES]
p.ores[deep.id] = 3
local capped = Pouch.sellAllPlan(p.ores, p.oreLocks, "Common")
local cappedIds = {}
for _, r in ipairs(capped.rows) do cappedIds[r.id] = true end
check(cappedIds.stone and not cappedIds[deep.id] and capped.aboveUnits == 3, "SELL UP TO Common keeps the Exotic")
check(Pouch.sellAllPlan(p.ores, p.oreLocks, "Everything").units == Pouch.sellAllPlan(p.ores, p.oreLocks).units,
	"Everything is what SELL ALL always did")
check(#Pouch.SELL_UP_TO == 6 and Pouch.SELL_UP_TO[1] == "Common" and Pouch.SELL_UP_TO[6] == "Everything",
	"the six ceilings: Common .. +Legendary, Everything")
do
	local rows = Pouch.rows(p.ores, p.oreLocks, { includeCandy = true })
	local candyRows = 0
	for _, r in ipairs(rows) do if r.candy then candyRows += 1 end end
	check(candyRows == 2 and #Pouch.rows(p.ores, p.oreLocks) == #rows - 2,
		"the pouch shows candy ores only to a screen that asks for them")
end

-- ------------------------------------------------------------ selling candy ores --
print("")
p.candy = 0
p.oreLocks.jawbreaker = true
S.dispatch(plr, "cryptSellCandyOres", { all = true })
local ask = lastSent("cryptSellCandyConfirm")
check(ask and ask.units == 5 and ask.lockedSkipped == 1 and p.ores.taffy == 5, "the bulk sell asks first, and skips a locked candy ore")
S.dispatch(plr, "cryptSellCandyOres", { all = true, confirm = true })
check(p.ores.taffy == nil and p.ores.jawbreaker == 2 and p.candy == 5 * C.candyOreValue("taffy"),
	"confirmed, it pays the asked candy")
S.dispatch(plr, "cryptSellCandyOres", { oreIds = { "jawbreaker", "stone" }, confirm = true })
check(p.ores.jawbreaker == nil and p.ores.stone == 10, "a ticked ore sells even if locked; a normal ore never sells for candy")

-- ------------------------------------------------------------ Halloween charms --
print("")
local cc = Charms.candyCharms()
check(#cc == 6, "six Halloween charms", #cc)
do
	local order, okStats, okRecipe, deeper = Temper.GRADE_ORDER, true, true, true
	local gradeAt = {}
	for i, g in ipairs(order) do gradeAt[g] = i end
	local lastGrade, lastRank = 0, 0
	for _, d in ipairs(cc) do
		local m = Temper.RARITY_MULT[d.rarity]
		local others = 0
		for k, v in pairs(d.stats) do
			if k ~= "candyFind" and k ~= "eventDig" then
				others += 1
				if not near(v, math.floor(m * Charms.CANDY_CHARM_SHARE.normal * 100 + 1e-9) / 100, 1e-9) then okStats = false end
			end
		end
		if others ~= 1 or not near(d.stats.candyFind, math.floor(m * 0.8 * 100 + 1e-9) / 100, 1e-9)
			or not near(d.stats.eventDig, math.floor(m * 0.6 * 100 + 1e-9) / 100, 1e-9) then okStats = false end
		local ore = C.candyOreById(d.recipe.oreId)
		if not ore or d.recipe.count < 1 or d.source ~= "candy" then okRecipe = false end
		if gradeAt[d.rarity] <= lastGrade or (ore and ore.rank <= lastRank) then deeper = false end
		lastGrade, lastRank = gradeAt[d.rarity], ore and ore.rank or 99
		if Charms.charmTokenPrice(d) ~= nil or table.find(Charms.GRADED, d) then okRecipe = false end
		if Charms.mergeTarget(d.id) ~= nil then okRecipe = false end
	end
	check(okStats, "each: Candy Find, Event Digging and one small normal stat, scaled by its grade")
	check(okRecipe, "each crafted from one candy ore; not a chest drop, not token-bought, not merged")
	check(deeper, "deeper ore, better grade")
	check(#R.charmRecipes(p) == 6 and R.charmRecipes(p)[1].cost == cc[1].recipe.count, "the recipe rows E2 renders")
end
do
	local d = cc[1]
	p.ores[d.recipe.oreId] = d.recipe.count - 1
	p.charms, p.equippedCharm = {}, nil
	S.dispatch(plr, "cryptCraftCharm", { charmId = d.id })
	check((p.charms[d.id] or 0) == 0, "one short of the recipe crafts nothing")
	p.ores[d.recipe.oreId] = d.recipe.count + 2
	S.dispatch(plr, "cryptCraftCharm", { charmId = d.id })
	check(p.charms[d.id] == 1 and p.ores[d.recipe.oreId] == 2 and p.equippedCharm == d.id,
		"crafting spends the ore, grants the charm and wears it when nothing is worn")
	p.zoneId = "hallow"
	local boosted = S.heldTool(p)
	check(boosted.power == R.inEventPower(Tools.byId(R.parseKey(p.cryptToolEquipped)), select(2, R.parseKey(p.cryptToolEquipped)), d.stats.eventDig)
		and boosted.power > R.inEventPower(Tools.byId(R.parseKey(p.cryptToolEquipped)), select(2, R.parseKey(p.cryptToolEquipped)), 0),
		"Event Digging raises the event tool's power")
	local b = { mineSpeed = 1, coinBonus = 1 }
	Charms.applyEquipped(b, d.id, p)
	check(near(b.candyFind, 1 + d.stats.candyFind, 1e-9) and near(b.coinBonus, 1 + d.stats.coinBonus, 1e-9),
		"the charm's Candy Find and normal stat land in boosts like any charm")
end

-- ------------------------------------------------------------ Trick-or-Treat --
print("")
do
	local w = TT.WEIGHTS
	local tot = 0
	for _, v in pairs(w) do tot += v end
	check(w.tool == 850 and w.skincase == 50 and w.hat == 70 and w.pack == 29 and w.bucket == 1 and tot == 1000,
		"weights: tools 85, skin case 5, hat 7, pack 2.9, bucket 0.1")
	check(w.candy == nil, "no candy back")
	local sum, sumNo = 0, 0
	for _, r in ipairs(TT.odds(true)) do sum += r.pct end
	local hatNo = 0
	for _, r in ipairs(TT.odds(false)) do
		sumNo += r.pct
		if r.kind == "hat" then hatNo = r.pct end
		if r.kind == "pack" then hatNo = -1 end
	end
	check(near(sum, 100, 1e-9) and near(sumNo, 100, 1e-9) and near(hatNo, 9.9, 1e-9),
		"the odds sheet sums to 100, and a missing pack folds into hats")
	local co = R.caseOdds(true)
	local tiers = 0
	for _, t in ipairs(co.toolTiers) do tiers += t.pct end
	check(near(tiers, 85, 1e-9) and co.price == 2500, "the tool slot splits into tiers (60/30/10) and the price stays 2,500")
	local n, got = 200000, { tool = 0, skincase = 0, hat = 0, pack = 0, bucket = 0 }
	local tierN = { 0, 0, 0 }
	local rng = Random.new(2026)
	local okShape = true
	for _ = 1, n do
		local r = TT.roll(rng)
		got[r.kind] = (got[r.kind] or 0) + 1
		if r.kind == "tool" then
			local def = Tools.byId(r.id)
			if not def then okShape = false else tierN[def.tier] += 1 end
		elseif r.kind == "skincase" then
			if not (r.oreTier >= 10 and r.oreTier <= 40) then okShape = false end
		elseif r.kind == "pack" then
			if r.id ~= "halloween_2026" then okShape = false end
		end
	end
	check(okShape, "every roll is a real tool, an ore case of tier 10-40, or the Halloween pack")
	check(near(got.tool / n, 0.85, 0.005) and near(got.skincase / n, 0.05, 0.003) and near(got.hat / n, 0.07, 0.003)
		and near(got.pack / n, 0.029, 0.002) and near(got.bucket / n, 0.001, 0.0005),
		"200,000 opens land on the weights", string.format("tool %.3f skin %.3f hat %.3f pack %.4f bucket %.4f",
			got.tool / n, got.skincase / n, got.hat / n, got.pack / n, got.bucket / n))
	check(near(tierN[1] / got.tool, 0.6, 0.01) and near(tierN[3] / got.tool, 0.1, 0.01), "the case's tool tiers land 60/30/10")
end
do
	p.candy = 10000
	p.zoneId = "hallow"
	local before = 0
	for _, v in pairs(p.cryptTools) do before += v end
	local packsBefore, gearBefore = #(p.packs or {}), #(p.gear or {})
	for _ = 1, 3 do S.buyTrickOrTreat(plr) end
	local after = 0
	for _, v in pairs(p.cryptTools) do after += v end
	local opened = lastSent("trickOrTreatOpened")
	check(p.candy == 10000 - 3 * TT.PRICE and opened and opened.price == TT.PRICE, "a case costs 2,500 candy, and there is no candy back")
	check(after + #(p.packs or {}) + #(p.gear or {}) + (p.trickBucket and 1 or 0) - before - packsBefore - gearBefore == 3,
		"each open pays exactly one prize")
	local outEvent = p.candy
	afterEvent()
	S.buyTrickOrTreat(plr)
	check(p.candy == outEvent, "closed, the case is not sold")
	duringEvent()
end

-- ------------------------------------------------------------ chests --
print("")
do
	local o = R.chestOdds(10)
	check(o.chance == Tools.CHEST_TOOL_CHANCE and near((o.tiers[1] or 0) + (o.tiers[2] or 0), o.chance, 1e-12),
		"a top chest: tool chance " .. Tools.CHEST_TOOL_CHANCE .. ", tier 1 or a lucky tier 2")
	local deepOdds = R.chestOdds(110)
	check(deepOdds.tiers[1] == nil and near(deepOdds.tiers[3], deepOdds.chance, 1e-12), "a deep chest pays only the deep tier")
	check(near(Tools.chestToolChance(99), math.min(0.95, Tools.CHEST_TOOL_CHANCE * Tools.CHEST_LUCK_CAP), 1e-12),
		"chest luck raises it, capped")
	local rng = Random.new(5)
	local hits, tierOk, n = 0, true, 40000
	for _ = 1, n do
		local t = Tools.rollChestTool(60, rng, 1)
		if t then
			hits += 1
			if t.tier < 2 then tierOk = false end
		end
	end
	check(near(hits / n, Tools.CHEST_TOOL_CHANCE, 0.01) and tierOk, "40,000 chests at layer 60 pay a tool ~30% of the time, never tier 1",
		string.format("%.3f", hits / n))
	check(R.chestCandy(50) == math.floor(C.candyFor(R.candyOreNear(50), 50) * R.CHEST_CANDY_BLOCKS), "a chest pays five candy blocks' worth")
	check(S.chestSpawnDef(5).name == "Candy Corn Chest" and S.chestSpawnDef(100).name == "Jawbreaker Chest",
		"a chest is named for its band")
	check(crypt.chestMult and crypt.chestMult > 0 and crypt.eventToolsOnly and crypt.noStrengthGate,
		"the Crypt row: chests back, event tools only, no strength gate")
	local cbefore = p.candy
	local chestPart = part("hallow", { CY = 100 })
	chestPart.Position = Vector3.new(0, 0, 0)
	S.openChest(plr, p, chestPart, { chestLuck = 1 })
	local opened = lastSent("chestOpened")
	check(opened and opened.kind == "crypt" and p.candy - cbefore == opened.candy and opened.candy == R.chestCandy(100),
		"opening one pays its candy and says so")
end

-- ------------------------------------------------------------ notice and snapshot --
print("")
do
	local q = { cryptTools = { [skey] = 1 }, cryptToolEquipped = skey, eventNoticeSeen = {}, hallowOwned = true }
	profiles[8] = q
	local plr8 = { UserId = 8 }
	sent = {}
	S.onEnterZone(plr8, q, crypt, "meadow")
	local n = lastSent("eventNotice")
	check(n and n.zoneId == "hallow" and n.text == R.NOTICE.text, "first entry pushes the pop-up text")
	S.dispatch(plr8, "cryptNoticeSeen", { zoneId = "hallow" })
	check(q.eventNoticeSeen.hallow == true, "cryptNoticeSeen marks it")
	sent = {}
	S.onEnterZone(plr8, q, crypt, "meadow")
	check(lastSent("eventNotice") == nil, "and it does not come back")
	check(R.NOTICE.text == "Only event tools work here. Tools you find are yours to keep: when the event ends they work in the main world too (weaker).",
		"the pop-up says exactly the owner's line")
	local st = R.stateFor(p)
	check(st and st.zoneId == "hallow" and type(st.tools) == "table" and #st.tools >= 1 and st.window.closesAt
		and #st.recipes == 6 and #st.candyOres == 16 and st.casePrice == TT.PRICE,
		"the snapshot block carries tools, window, recipes, candy ores and the price")
	local okRows = true
	for _, t in ipairs(st.tools) do
		if not (t.key and t.variant and t.count and t.power and t.worldPower and t.family) then okRows = false end
	end
	check(okRows, "each tool row carries key, variant, count, both powers and family")
end

C.LIMITED_WINDOWS.hallow = realWindow
print("RESULT " .. fails)
`;

const script = path.join(Luau.BIN, "crypt-check.luau");
fs.writeFileSync(script, prelude + "\n" + factories + "\n" + body);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [script], { encoding: "utf8", maxBuffer: 1 << 24 });
} catch (e) {
  process.stdout.write(e.stdout || "");
  process.stderr.write(e.stderr || "");
  console.log("  FAIL  the luau half did not run to the end");
  fail++;
}
process.stdout.write(out.split("\n").filter((l) => !/^RESULT /.test(l)).join("\n"));
const m = out.match(/^RESULT (\d+)/m);
if (!m) {
  if (out) console.log("  FAIL  the luau half printed no RESULT line");
  fail++;
} else {
  fail += Number(m[1]);
}
console.log(fail === 0 ? ">>> crypt OK" : `>>> crypt: ${fail} FAILED`);
process.exit(fail === 0 ? 0 : 1);
