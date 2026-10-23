// THE SHOPS CHARGE WHAT THEY SAY, ONCE, FOR THINGS THEY STILL SELL.
//
// Six launch-audit fixes the owner decided on 2026-10-19 (wiki open-questions
// §0e). Each one is a screen and a till that disagreed:
//
//   M4  The Founders Rig said "BUY 799 Robux" and took 799 credits in one tap.
//       It says credits and asks twice.
//   S1  Cart CONFIRM stayed live while "Confirming": a second charge for one
//       cart. CONFIRM waits for the server, and the server refuses an order it
//       has already been paid for (the cart's `token`).
//   S3  Depth desks priced gem bags in coins and showed tool cards the till
//       refuses (FORGE_ONLY_FAMILIES).
//   S5  The Starter Bundle popup listed packs and gems the product never gives.
//   S7  A crafted cart could still buy retired card and gear packs: the price
//       lookup read the old table before the live shelf.
//   S8  A Build-a-Box of ten of one pack cost 12% off where its own 10x button
//       was 30% off.
//
// S3, S7 and S8 are RUN (MineDepthShop.catalog, MinePackConfig.priceOf and
// boxPrice against the real MineCases shelf); the rest are wiring, checked in
// the code with comments stripped.
//
// Run: node tools/verify/shop-guards.js
const fs = require("fs"), path = require("path"), os = require("os"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const SH = "src/ReplicatedStorage/Mine/Shared/";
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const codeOnly = (s) => s.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");

const SRV = codeOnly(read("src/ServerScriptService/Mine/MineServer.server.luau"));
const CLIENT = codeOnly(read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau"));
const INV = codeOnly(read(SH + "MineInventoryView.luau"));
const SHOP = codeOnly(read(SH + "MineShopView.luau"));
const DESKVIEW = codeOnly(read(SH + "MineDepthShopView.luau"));

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};
const between = (src, a, b) => {
  const i = src.indexOf(a);
  if (i < 0) return "";
  const j = src.indexOf(b, i + a.length);
  return j < 0 ? src.slice(i) : src.slice(i, j);
};

console.log("shop-guards: the shops charge what they say, once, for things they still sell");

// ------------------------------------------------------------------ M4 --
ok(!/"Robux"/.test(SHOP) && !/" Robux"/.test(SHOP), "the backpack shelf never says Robux (the Founders Rig is credits)");
ok(/if activeTab == "backpack" and row\.robux then\s*currency = "credits"/.test(SHOP), "...it labels the rig in credits");
ok(/if row\.robux then\s*return \(\(state\.credits or 0\) >= rigCredits\(row\)\)/.test(SHOP),
  "...and greys it out on the credits the player has, not on nothing");
const rigClick = between(SHOP, "if row and row.robux then", "opts.onBuyBackpack");
ok(/state\.rigArmedAt and \(now - state\.rigArmedAt\) < 4/.test(rigClick) && /state\.rigArmedAt = now/.test(rigClick),
  "buying it takes two taps (the first arms a 4-second confirm)");
ok(/opts\.onBuyProductCredits\(row\.productKey or "patron_rig"\)/.test(rigClick) && !/PromptProductPurchase/.test(rigClick),
  "...and buys with credits only, never a Robux prompt behind a credits label");
ok(/C\.productCredits\(/.test(between(SHOP, "local function rigCredits(", "local function bagPrice(")),
  "the price shown is the server's (MineConfig.productCredits)");

// ------------------------------------------------------------------ S1 --
const checkout = between(INV, "local function doCheckout()", "function MineInventoryView._settleCart(");
ok(/^local function doCheckout\(\)\s*if pending then\s*return\s*end/.test(checkout),
  "a checkout already waiting on the server sends nothing more");
ok(/cart\.token = cart\.token or game:GetService\("HttpService"\):GenerateGUID\(false\)/.test(checkout)
  && /opts\.onBuyCart\(lines, cart\.token\)/.test(checkout), "...and every order carries its id");
ok(!/pending = nil\s*sheet\.settle\(false, "No reply from the server"\)/.test(checkout),
  "a reply that is only late does not re-open CONFIRM at 6 s");
const cartSheet = between(INV, "local function showCart()", "refreshCart = function()");
ok(/local waiting = pending ~= nil/.test(cartSheet) && /confirm\.Text = "CONFIRMING\.\.\."/.test(cartSheet)
  && /confirm\.MouseButton1Click:Connect\(function\(\)\s*if pending then\s*return/.test(cartSheet),
  "CONFIRM is shut while the checkout is out");
ok(/net:FireServer\("buyCart", \{ lines = lines, token = token \}\)/.test(CLIENT), "the client sends the order id");
const buyCart = between(SRV, "local function buyCart(plr, payload)", "local function grantPassSignatureTool(");
const refuseAt = buyCart.indexOf("Dig.cartPaid[plr][token] then"), debitAt = buyCart.indexOf("p.credits -= pay"),
  recordAt = buyCart.indexOf("Dig.cartPaid[plr][token] = true");
ok(refuseAt > -1 && debitAt > refuseAt && recordAt > debitAt,
  "the server refuses an order it was already paid for, and records each one it charges");
ok((buyCart.match(/p\.credits -= /g) || []).length === 1, "one charge per request, after the whole cart is priced");
ok(/payload\.dup == true/.test(INV), "a duplicate's reply empties the cart (nothing was charged twice)");
ok(/if busy\[plr\.UserId\] then return end/.test(SRV), "the per-player busy lock still drops a request that lands mid-purchase");

// ------------------------------------------------------------------ S3 --
ok(/row\.currency == "gems"/.test(DESKVIEW) && /tonumber\(row\.gemPrice\)/.test(DESKVIEW)
  && /gemPay and \(state\.gems or 0\)/.test(DESKVIEW) && /gemPay and " gems"/.test(DESKVIEW),
  "the desk prices bags in gems against the gems you have");
ok(/fmtCoins\(state\.gems or 0\) \.\. " gems"/.test(DESKVIEW), "...and its purse shows gems");
ok(/depthShopCtl\.setState\(\{[\s\S]*?gems = payload\.gems[\s\S]*?backpackTier = payload\.backpackTier/.test(CLIENT),
  "...kept current from the snapshot");

// ------------------------------------------------------------------ S5 --
const starter = between(CLIENT, "function ClientFns.offerStarter(force)", "\nend\n");
ok(starter.length > 0 && !/prod\.packs/.test(starter) && !/prod\.gems/.test(starter),
  "the Starter Bundle popup no longer lists packs or gems the bundle never gives");
const fallbacks = [/tonumber\(prod\.bagRung\) or 2/, /tonumber\(prod\.coins\) or 8000/, /tonumber\(prod\.commonPet\) or 1/];
ok(fallbacks.every((re) => re.test(starter)),
  "...it lists the bag rung, the coins and the pet, from the product row");
const grants = SRV.match(/key == "starter_bundle"[\s\S]*?p\.starterBought = true/g) || [];
ok(grants.length >= 2 && grants.every((g) => fallbacks.every((re) => re.test(g))),
  "...with the same fields and fallbacks as both of the server's grants", `${grants.length} grants`);

// ------------------------------------------------------------------ S8 --
ok(/local price = Packs\.boxPrice\(line\.packs\)/.test(SRV), "the server charges a box at MinePackConfig.boxPrice");
ok(/return Packs\.boxPrice\(line\.packs\) or 0/.test(INV) && /local boxPay = Packs\.boxPrice\(boxPicks\) or 0/.test(INV),
  "...and the cart and the Box tab print the same function");
ok(!/\*\s*0\.88/.test(SRV) && !/\*\s*0\.88/.test(INV), "no 0.88 typed beside it any more");

// ------------------------------------------------------------ behaviour --
if (!Luau.ready) {
  console.log("  " + Luau.missing("luau"));
  console.log(fails === 0 ? ">>> shop-guards OK (static only)" : `>>> ${fails} FAILED`);
  process.exit(fails === 0 ? 0 : 1);
}

const cfg = read(SH + "MineConfig.luau");
const forgeOnly = (cfg.match(/MineConfig\.FORGE_ONLY_FAMILIES = (\{[\s\S]*?\n\})/) || [])[1] || "{}";
const setDir = path.join(ROOT, SH, "SetPets");
let setMods = "";
for (const f of fs.readdirSync(setDir).filter((x) => x.endsWith(".luau"))) {
  setMods += `MODULES["SetPets/${f.replace(".luau", "")}"] = (function()\n${Luau.readSrc(path.join(setDir, f))}\nend)()\n`;
}

const harness = `
Color3 = { fromRGB = function() return {} end, fromHSV = function() return {} end, new = function() return {} end }
Enum = setmetatable({}, { __index = function() return setmetatable({}, { __index = function(_, k) return { Name = k } end }) end })
Random = {}
Random.__index = Random
function Random.new(seed) return setmetatable({ s = (tonumber(seed) or 48611) % 2147483647 }, Random) end
function Random:NextNumber() self.s = (self.s * 48271) % 2147483647 return self.s / 2147483647 end
function Random:NextInteger(a, b) return a + math.floor(self:NextNumber() * (b - a + 1)) end
Vector3 = { new = function() return {} end }
warn = function() end
local function node(name)
	return setmetatable({ Name = name, WaitForChild = function(_, n) return node(n) end, FindFirstChild = function(_, n) return node(n) end,
		IsStudio = function() return false end, IsServer = function() return true end, IsClient = function() return false end },
		{ __index = function() return function() end end })
end
game = { GetService = function(_, n) return node(n) end }

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
		if MODULES[n] ~= nil then return { Name = n } end
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

-- ------------------------------------------------- S3: a depth desk's shelf --
-- The ladders and bags are stubs shaped like the real rows; the rule under test
-- is MineDepthShop's, run as it is.
MODULES.MineDepth = { SEAMS = { 500, 1000, 1500, 2000, 2500 }, depthSellMult = function() return 1 end }
MODULES.MineTools = { TOOLS = {} }
MODULES.MineConfig = { FORGE_ONLY_FAMILIES = ${forgeOnly}, ZONES = { { id = "meadow" }, { id = "bigbang" } } }
local LADDER = {
	{ id = "lad_pick_3", family = "pickaxe", slot = 3, name = "Shop Pick", power = 9, price = 900 },
	{ id = "lad_drill_2", family = "drill", slot = 2, name = "Shop Drill", power = 7, price = 700 },
	{ id = "lad_bucket_1", family = "bucket", slot = 1, name = "Not A Tool", power = 1, price = 50 },
}
MODULES.MineShopLadders = {
	ZONE_ORDER = { "meadow" },
	forDesk = function() return LADDER end,
	byId = function(id) for _, r in ipairs(LADDER) do if r.id == id then return r end end return nil end,
}
MODULES.MineBags = {
	gemPrice = function(t) return math.floor(100 * 1.08 ^ (math.max(1, t) - 1) + 0.5) end,
	shopRows = function()
		return {
			{ id = "bag_12", family = "backpack", tier = 12, name = "Desk Pack", slots = 30000, price = 4321 },
			{ id = "bag_480", family = "backpack", tier = 480, name = "Founders Rig", robux = true, price = 0 },
		}
	end,
}
MODULES.MineHorizonTools = { forBand = function() return { { id = "eh_shallow_pick", family = "pickaxe", tier = 1, name = "EH Pick", price = 50, currency = "space" } } end }
local Desk = (function()
${read(SH + "MineDepthShop.luau")}
end)()

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. tostring(detail)) or ""))
	if not cond then fails += 1 end
end
local rows = Desk.catalog(1, 500, "deeprock")
local ids, bag = {}, nil
for _, r in ipairs(rows) do
	ids[r.id] = true
	if r.id == "bag_12" then bag = r end
end
check("a desk no longer shows the coin tools its till refuses", not ids.lad_pick_3 and not ids.lad_drill_2)
check("...but keeps a ladder row of a family it still sells", ids.lad_bucket_1 == true)
check("its bags are priced in gems, at the till's gem price", bag ~= nil and bag.currency == "gems"
	and bag.gemPrice == MODULES.MineBags.gemPrice(12), bag and (tostring(bag.currency) .. " " .. tostring(bag.gemPrice)))
check("...with the coin figure left on the row for what else reads it", bag ~= nil and bag.price == 4321)
check("the Founders Rig is not a desk item", not ids.bag_480)
local eh = Desk.catalog(2, 500, "deeprock")
local ehIds = {}
for _, r in ipairs(eh) do ehIds[r.id] = true end
check("Event Horizon's space-coin tools still sell at its desks", ehIds.eh_shallow_pick == true)
check("the till's own test agrees: the refused tools are not in the catalog",
	Desk.catalogHas(1, 500, "lad_pick_3", "deeprock") == nil and Desk.catalogHas(1, 500, "bag_12", "deeprock") ~= nil)

-- ------------------------------------------ S7 and S8: the credit shelf --
MODULES.MineChestRanks = (function()
${read(SH + "MineChestRanks.luau")}
end)()
MODULES.MineZonePacks = (function()
${read(SH + "MineZonePacks.luau")}
end)()
MODULES.Mine1PacksData = (function()
${read(SH + "Mine1PacksData.luau")}
end)()
MODULES.Mine1ChestsData = {}
MODULES.MinePotions = {}
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
local Packs = (function()
${read(SH + "MinePackConfig.luau")}
end)()
-- MineCases prices lazily off MinePackConfig (its require loop rule).
MODULES.MinePackConfig = Packs
local Cases = MODULES.MineCases
local shelf = Cases.creditShelf()
check("read today's credit shelf", #shelf >= 9, #shelf)
local retired = { "heirloom_pack", "omen_pack", "shiny_pack", "apex_pack", "hopper_pack", "gear_pack", "gear_vault_pack" }
local sold = {}
for _, id in ipairs(retired) do
	if Packs.priceOf(id) ~= nil or Packs.bundlePrice(id) ~= nil then table.insert(sold, id) end
end
check("no retired card or gear pack has a price any more", #sold == 0, table.concat(sold, ","))
local unpriced = {}
for _, id in ipairs(shelf) do
	if Packs.priceOf(id) ~= Cases.creditPrice(id) or not Packs.priceOf(id) then table.insert(unpriced, id) end
end
check("everything on the live shelf keeps its shelf price", #unpriced == 0, table.concat(unpriced, ","))
check("an unknown id costs nothing because it is not sold", Packs.priceOf("nope_pack") == nil)

local ten, mixed = {}, {}
for i = 1, 10 do
	ten[i] = "case_6"
	mixed[i] = shelf[((i - 1) % #shelf) + 1]
end
local unit = Packs.priceOf("case_6")
check("a box of ten of one pack costs its 10x bundle (30% off)", Packs.boxPrice(ten) == Packs.bundlePrice("case_6"),
	string.format("%s vs bundle %s (12%% off would be %d)", tostring(Packs.boxPrice(ten)), tostring(Packs.bundlePrice("case_6")),
		math.floor(unit * 10 * 0.88 + 0.5)))
local sum = 0
for _, id in ipairs(mixed) do sum += Packs.priceOf(id) end
check("a mixed box is still 12% off its list", Packs.boxPrice(mixed) == math.floor(sum * Packs.BOX_RATE + 0.5),
	tostring(Packs.boxPrice(mixed)) .. " of " .. sum)
local five = { "case_6", "case_6", "case_6", "case_6", "case_6" }
check("a short box of one pack is 12% off (the bundle is ten)", Packs.boxPrice(five) == math.floor(unit * 5 * Packs.BOX_RATE + 0.5))
check("an empty box, an eleven-pack box, or a retired pick has no price",
	Packs.boxPrice({}) == nil and Packs.boxPrice({ "case_6", "case_6", "case_6", "case_6", "case_6", "case_6",
		"case_6", "case_6", "case_6", "case_6", "case_6" }) == nil and Packs.boxPrice({ "case_6", "heirloom_pack" }) == nil)

print(fails == 0 and ">>> shop-guards: all assertions passed" or (">>> shop-guards: " .. fails .. " FAILED"))
`;

const script = path.join(os.tmpdir(), `mfc-shop-guards-${process.pid}.luau`);
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
if (!/>>> shop-guards: all assertions passed/.test(out)) {
  fails++;
}
console.log(fails === 0 ? ">>> shop-guards OK" : `>>> shop-guards: ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
