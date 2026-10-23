// LIMITED DEALS AND THE FOUNDERS PACK GIVE WHAT THEY SAY, WHEN THEY SAY.
//
// The launch audit (2026-10-19, wiki open-questions §0e) found five ways a paid
// shelf promised one thing and did another. The owner decided all five; each is
// pinned here, and most of them by EXECUTING the real MineRotatingOffers and
// MineFounders rather than restating them:
//
//   M6  The Founders Pack card listed the Founders Bag; buying the pack never
//       gave it. MineFounders.grant takes the bag grant from every caller now.
//   M7  Lucky Block Week paid "a Lucky Block pet" (ownedPets.lucky_block, which
//       nothing reads) and three pack types retired on 2026-10-10. It mints a
//       real roster pet and pays wild cases of about the same value.
//   M8  Every deal read "ends 0d 0h" from day one (season-clock end minus the
//       wall clock), the header said 40 days left in a 47-day season, and the
//       home banner promised new offers every midnight though they change weekly.
//   S4  Two blurbs said "through Oct 31" in a season that starts at launch.
//   S6  Robux for a deal already at its max: "granted", nothing given. It pays
//       the deal's credit price back now, and the client will not prompt.
//
// Run: node tools/verify/deals.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const SH = "src/ReplicatedStorage/Mine/Shared/";
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const codeOnly = (s) => s.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");

const OFFERS = read(SH + "MineRotatingOffers.luau");
const FOUNDERS = read(SH + "MineFounders.luau");
const CASES = read(SH + "MineCases.luau");
const INV = read(SH + "MineInventoryView.luau");
const SRV = read("src/ServerScriptService/Mine/MineServer.server.luau");
const CLIENT = read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau");
const OFFERS_CODE = codeOnly(OFFERS), SRV_CODE = codeOnly(SRV), INV_CODE = codeOnly(INV);
const CLIENT_CODE = codeOnly(CLIENT), FOUNDERS_CODE = codeOnly(FOUNDERS);

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};
// The text of one `function X(...)` up to the next top-level `function`/`end`.
const fnBody = (src, head) => {
  const at = src.indexOf(head);
  if (at < 0) return "";
  const rest = src.slice(at);
  const stop = rest.search(/\nend\n/);
  return stop < 0 ? rest : rest.slice(0, stop);
};

console.log("deals: limited deals and the Founders Pack deliver what the shop says");

// ------------------------------------------------------------------ M7 --
const lucky = (OFFERS_CODE.match(/id = "deal_lucky_week"[\s\S]*?\n\t\},/) || [""])[0];
ok(lucky.length > 0, "found Lucky Block Week in MineRotatingOffers");
const wildBlock = (CASES.match(/M\.WILD_GRADES = \{([\s\S]*?)\n\}/) || [])[1] || "";
const WILD = [...wildBlock.matchAll(/\{([^\n]*?)levels = \{([^}]*)\}/g)].map((m) => {
  const named = m[1].match(/id = "([a-z0-9_]+)"/);
  return named ? named[1] : "case_" + m[2].split(",").map((x) => x.trim()).join("_");
});
ok(WILD.length === 9, "read the nine wild case ids from MineCases.WILD_GRADES", WILD.join(" "));
const packsBlock = (lucky.match(/packs = \{([\s\S]*?)\n\t\t\}/) || [])[1] || "";
const dealPacks = [...packsBlock.matchAll(/\{ id = "([a-z0-9_]+)", qty = (\d+) \}/g)].map((m) => ({ id: m[1], qty: +m[2] }));
ok(dealPacks.length > 0, "Lucky Block Week still pays packs or cases", `${dealPacks.length} rows`);
const notWild = dealPacks.filter((r) => !WILD.includes(r.id)).map((r) => r.id);
ok(notWild.length === 0, "...and every one is a wild case, not a pack retired on 2026-10-10",
  notWild.length ? notWild.join(", ") : dealPacks.map((r) => r.qty + "x " + r.id).join(", "));
const petName = (lucky.match(/\bpet = "([^"]+)"/) || [])[1];
ok(!!petName, "Lucky Block Week names a pet", petName || "pet is not a name");
const setDir = path.join(ROOT, SH, "SetPets");
let petTier = null;
for (const f of fs.readdirSync(setDir)) {
  const m = new RegExp(`name = "${(petName || "\u0000").replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}", hex3 = "[0-9a-f]+", animal = "[^"]+", tier = "([A-Za-z]+)"`)
    .exec(fs.readFileSync(path.join(setDir, f), "utf8"));
  if (m) petTier = m[1];
}
ok(petTier !== null, "...that is a real set pet a lucky block's mystery case can drop", `${petName}: ${petTier}`);
ok(petTier === "Epic", "...an Epic, as the owner asked (\"an Epic-ish one that fits\")", petTier || "none");

// No code anywhere still writes or reads the pet that never existed.
const ghost = [];
(function walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p);
    else if (e.name.endsWith(".luau") && /ownedPets\.lucky_block/.test(codeOnly(Luau.readSrc(p)))) {
      ghost.push(path.relative(ROOT, p));
    }
  }
})(path.join(ROOT, "src"));
ok(ghost.length === 0, "nothing touches ownedPets.lucky_block any more", ghost.join(", ") || "clean");

const mintFn = fnBody(SRV_CODE, "function Dig.mintDealPet(");
ok(/PetRoster\.BY_NAME/.test(mintFn) && /mint\(\{[\s\S]*?\}, plr\.UserId, true\)/.test(mintFn) && /table\.insert\(p\.cards, c\)/.test(mintFn),
  "the server mints the deal's pet as a real card (Dig.mintDealPet)");
const grants = SRV_CODE.match(/Offers\.grant\(p, deal[^)]*/g) || [];
ok(grants.length >= 2 && grants.every((g) => g.includes("mintPet")),
  "both deal grants (credits and Robux) hand Offers.grant the pet minter", `${grants.length} call(s)`);
ok(!/Offers\.grant\(p, deal\)/.test(SRV_CODE), "...and none calls it without one");

// The blurb says what the data pays.
const blurb = (lucky.match(/blurb = "([^"]*)"/) || [])[1] || "";
const blocks = [...lucky.matchAll(/\{ id = "([a-z_]*lucky_block)", qty = (\d+) \}/g)].map((m) => +m[2]);
const nCases = dealPacks.reduce((s, r) => s + r.qty, 0);
ok(blocks.length === 3 && blurb.includes(`${blocks[0]} Lucky Blocks`) && blurb.includes(`${blocks[1]} Diamond`)
  && blurb.includes(`${blocks[2]} Godly`), "the Lucky Block Week blurb counts the blocks it pays", blocks.join("/"));
ok(blurb.includes(`${nCases} Wild Cases`) && !!petName && blurb.includes(petName),
  "...and the cases and the pet", `${nCases} cases, ${petName}`);

// ------------------------------------------------------------------ S4 --
const MONTH = /\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.? \d{1,2}\b/;
const dated = [...OFFERS_CODE.matchAll(/blurb = "([^"]*)"/g)].map((m) => m[1]).filter((b) => MONTH.test(b));
ok(dated.length === 0, "no deal blurb names a calendar date (the season starts at launch)",
  dated.length ? dated.join(" | ") : "");

// ------------------------------------------------------------------ M8 --
ok(!/offer\.ends\)\s*or\s*0\)\s*-\s*os\.time\(\)/.test(INV_CODE),
  "the deal countdown no longer subtracts the wall clock from a season-clock end");
ok(/RotatingOffers\.secondsLeft\(offer\)/.test(INV_CODE), "...it asks MineRotatingOffers.secondsLeft");
ok(!/86400\s*-\s*\(os\.time\(\)\s*%\s*86400\)/.test(INV_CODE),
  "the home banner no longer counts to UTC midnight");
ok(/RotatingOffers\.nextOfferIn\(\)/.test(INV_CODE), "...it counts to the next weekly offer (nextOfferIn)");
ok(/MineRotatingOffers\.SEASON_END\s*-\s*now/.test(fnBody(OFFERS_CODE, "function MineRotatingOffers.dayKey(")),
  "the header's days-left reads the extended season end, not ENDS");

// ------------------------------------------------------------------ S6 --
const receipt = SRV_CODE.slice(SRV_CODE.indexOf("Verbs.grantReceipt = function"), SRV_CODE.indexOf("Svc.Marketplace.ProcessReceipt"));
ok(receipt.length > 0, "found the receipt handler");
ok(!/if Offers\.deny\(p, deal\) then\s*return true/.test(receipt),
  "a Robux deal at its max is no longer acknowledged with nothing given");
ok(/Dig\.creditBack\(plr, p, tonumber\(deal\.credits\)/.test(receipt),
  "...it pays the deal's credit price back (Dig.creditBack)");
ok(/p\.credits = \(p\.credits or 0\) \+ n/.test(fnBody(SRV_CODE, "function Dig.creditBack(")),
  "Dig.creditBack credits the player");
const robuxFn = (CLIENT_CODE.match(/onBuyProductRobux = function\(key\)[\s\S]*?PromptProductPurchase/) || [""])[0];
ok(/Offers\.deny\(/.test(robuxFn) && /Offers\.isLive\(/.test(robuxFn),
  "the client will not prompt Robux for a deal at its max or off the shelf");
ok(/PolicyNoRandom/.test(robuxFn) && /isRandomBuy\(key\)/.test(robuxFn),
  "...nor for a random buy where paid random items are restricted");
ok(/dealBuys = p\.dealBuys or \{\}/.test(SRV_CODE), "the snapshot carries dealBuys");
ok(/RotatingOffers\.deny\(\{ dealBuys = state\.dealBuys or \{\} \}, offer\)/.test(INV_CODE),
  "the Limited tab greys a deal out at its max");

// ------------------------------------------------------------------ M6 --
ok(/opts\.grantBag\(p, plr\)/.test(FOUNDERS_CODE), "MineFounders.grant grants the Founders Bag");
const calls = SRV_CODE.match(/Founders\.grant\(p, plr, "(gamepass|credits)", \{[\s\S]*?\}\)/g) || [];
ok(calls.length >= 4 && calls.every((c) => /grantBag = Dig\.grantFoundersBag/.test(c)),
  "every Founders.grant call passes the bag grant", `${calls.filter((c) => /grantBag/.test(c)).length} of ${calls.length}`);
const bagFn = fnBody(SRV_CODE, "function Dig.grantFoundersBag(");
ok(/p\.foundersBag = true/.test(bagFn) && /p\.equippedBag = "founders"/.test(bagFn)
  && /p\.backpackTier = target/.test(bagFn) && /giveBackpackModel/.test(bagFn),
  "Dig.grantFoundersBag grants what the bag's own buy grants (rung, flag, worn, model)");
const grantsCard = (INV_CODE.match(/sectionHeader\("WHAT IT GRANTS"[\s\S]*?\n\t\t\t\}/) || [""])[0];
ok(/"Founders Bag"/.test(grantsCard) && !/Equip it below/.test(INV),
  "the pack's card lists the bag and no longer points at a bag picker that does not exist");

// ------------------------------------------------------------ behaviour --
if (!Luau.ready) {
  console.log("  " + Luau.missing("luau"));
  console.log(fails === 0 ? ">>> deals OK (static only)" : `>>> ${fails} FAILED`);
  process.exit(fails === 0 ? 0 : 1);
}

const harness = `
local MODULES = {}
local SHARED = { WaitForChild = function(_, n) return { Name = n } end, FindFirstChild = function(_, n) return { Name = n } end }
script = { Name = "harness", Parent = SHARED }
function require(t)
	local n = type(t) == "table" and t.Name or tostring(t)
	local m = MODULES[n]
	if m == nil then error("no stub for " .. n) end
	return m
end
local NOW = 0
MODULES.MineLaunch = { seasonNow = function() return NOW end }
MODULES.MineLuckyBlocks = { grant = function(p, id, grade, qty)
	for _ = 1, qty do table.insert(p.packs, { kind = "lucky_block", blockId = id }) end
end }
MODULES.MineZonePacks = { id = function() return "meadow_pack_legendary" end }
MODULES.MinePackConfig = { PACK_BY_ID = {} }
local WILD = {}
for _, id in ipairs({ ${WILD.map((w) => JSON.stringify(w)).join(", ")} }) do WILD[id] = true end
MODULES.MineCases = { bagRow = function(id, paid)
	if not WILD[id] then return nil end
	return { packId = id, kind = "pack_case", paid = paid or nil }
end }
MODULES.MinePotions = { grant = function() return true end }
-- Shapes of the real MineConfig.PRODUCTS rows isRandomBuy reads.
local PRODUCTS = {
	weekend_haul = { packs = { { id = "x", qty = 1 } }, blocks = { { id = "lucky_block", qty = 1 } } },
	starter_bundle = { bagRung = 2, coins = 8000, commonPet = 1 },
	coin_double = {}, patron_rig = {},
}
MODULES.MineConfig = { product = function(k) return PRODUCTS[k] end }

local O = (function()
${OFFERS}
end)()

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. tostring(detail)) or ""))
	if not cond then fails += 1 end
end
local START, WEEK = O.SEASON_START, 604800
NOW = START

-- M8: on the season clock, before launch (NOW pinned at START).
check("the header counts the 47-day season", O.dayKey() == "47d left in the season", O.dayKey())
local lw = O.byId("deal_lucky_week")
check("Lucky Block Week shows its whole two weeks before launch", O.secondsLeft(lw) == 2 * WEEK, O.secondsLeft(lw))
check("...and reads as 14d 0h", O.clockText(O.secondsLeft(lw)) == "14d 0h", O.clockText(O.secondsLeft(lw)))
check("the last hours read in hours and minutes", O.clockText(5 * 3600 + 7 * 60) == "5h 07m", O.clockText(5 * 3600 + 7 * 60))
check("new offers come in a week, not at midnight", O.nextOfferIn() == WEEK, O.nextOfferIn())
NOW = START + WEEK + 3600
check("...an hour into week two, six days and 23 hours", O.nextOfferIn() == WEEK - 3600, O.nextOfferIn())
NOW = START + 4 * WEEK
check("...and nothing once the last offer is up", O.nextOfferIn() == nil, tostring(O.nextOfferIn()))
local allPositive = true
for _, row in ipairs(O.active(START + WEEK + 10)) do
	if O.secondsLeft(row, START + WEEK + 10) <= 0 then allPositive = false end
end
check("every live deal has time left on its own clock", allPositive)
NOW = START

-- M7: the pet is real, or the deal is refused before anything is given.
local p = { packs = {} }
check("without a pet minter the deal is refused", O.grant(p, lw) == false)
check("...and nothing was counted or granted", O.bought(p, lw) == 0 and #p.packs == 0)
local minted = {}
local hooks = { mintPet = function(name) table.insert(minted, name) return true end }
check("with one, Lucky Block Week is granted", O.grant(p, lw, hooks) == true)
check("...minting its pet once", #minted == 1 and minted[1] == lw.pet, table.concat(minted, ","))
local blocks, cases, paid = 0, 0, 0
for _, row in ipairs(p.packs) do
	if row.kind == "lucky_block" then blocks += 1 end
	if row.kind == "pack_case" then
		cases += 1
		if row.paid then paid += 1 end
	end
end
check("...its 9 lucky blocks", blocks == 9, blocks)
check("...and its wild cases, every one a real case row", cases == ${nCases} and cases == #p.packs - blocks, cases)
check("...bought with credits, so each is a paid case", paid == cases, paid)
O.grant(p, lw, hooks)
O.grant(p, lw, hooks)
check("three is the most", O.grant(p, lw, hooks) == false and O.bought(p, lw) == 3 and #minted == 3)
local q = { packs = {} }
check("a pet that cannot be minted refuses the deal", O.grant(q, lw, { mintPet = function() return false end }) == false)
check("...leaving the count and the bag untouched", O.bought(q, lw) == 0 and #q.packs == 0)

-- M3: which buys roll something (the region rule's question).
check("Lucky Block Week is a paid random buy", O.hasRandom(lw) == true)
check("the Founders Bag is not", O.isRandomBuy("patron_rig") == false)
check("Pot of Gold is", O.isRandomBuy("deal_pot_gold") == true)
check("Weekend Haul is (packs and a lucky block)", O.isRandomBuy("weekend_haul") == true)
check("the Starter Crate is (its Common pet is random)", O.isRandomBuy("starter_bundle") == true)
check("2x Coins is not", O.isRandomBuy("coin_double") == false)

print(fails == 0 and "  rotating offers: all assertions passed" or ("  rotating offers: " .. fails .. " FAILED"))

-- M6: the pack's grant hands the bag to the caller's grant.
-- (MineFounders reaches for the VFX module inside a pcall; with no \`game\`
-- here that pcall simply fails, which is all the harness needs.)
local F = (function()
${FOUNDERS}
end)()
local fp, gotBag, said = {}, 0, ""
F.grant(fp, "plr", "credits", {
	grantBooks = function() end,
	grantBag = function(pp, plr) if pp == fp and plr == "plr" then gotBag += 1 end end,
	toast = function(_, msg) said = msg end,
})
check("the Founders Pack grants the Founders Bag once", gotBag == 1, gotBag)
check("...and says so", string.find(said, "Founders Bag", 1, true) ~= nil, said)
local bare = {}
F.grant(bare, nil, "credits", {})
check("a caller that forgets still leaves the bag owned", bare.foundersBag == true)
check("a member is never granted twice", F.grant(fp, "plr", "credits", { grantBag = function() gotBag += 1 end }) == false and gotBag == 1)
print(fails == 0 and ">>> deals: all assertions passed" or (">>> deals: " .. fails .. " FAILED"))
`;

// In the temp dir, not .luau-bin: several sessions share one .luau-bin.
const script = path.join(require("os").tmpdir(), `mfc-deals-check-${process.pid}.luau`);
fs.writeFileSync(script, harness);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [script], { encoding: "utf8" });
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
} finally {
  try { fs.unlinkSync(script); } catch (e) { /* already gone */ }
}
process.stdout.write(out);
if (/FAILED|FAIL |error|attempt to/i.test(out) || !/>>> deals: all assertions passed/.test(out)) {
  fails++;
}
console.log(fails === 0 ? ">>> deals OK" : `>>> deals: ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
