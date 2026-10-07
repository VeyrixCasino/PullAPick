// FIVE TRADERS, IN FIVE DIFFERENT PLACES, SELLING WHAT THEIR DEPTH ALLOWS.
//
// Owner, 2026-10-07: "a wandering trader that spawns at random depth outposts in
// random zones, and dependant on what depths/zone has different stuff (5
// different cases (random tool), custom hats case, random charm case)" and "5
// different traders at once".
//
// Each clause is a check here. The two that would be invisible in play until
// somebody screenshots them:
//
//   DRAWN WITHOUT REPLACEMENT. Five independent draws over ~50 spots collide
//   about a quarter of the time, and two traders standing on one pad reads as a
//   bug. Same for a trader listing one case twice.
//
//   THE DEPTH GATE IS A GATE, not a preference. A surface trader must never be
//   able to sell Apex however the hash falls -- so this walks thousands of
//   rotations at the shallowest spot and asserts it never appears, rather than
//   checking one rotation and trusting it.
//
// Run: node tools/verify/trader.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const SRC = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineTrader.luau");
const TRADER = Luau.readSrc(SRC);

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

console.log("trader: five wandering traders, placed and stocked by where they stand");

ok(/MineTrader\.COUNT = 5/.test(TRADER), "five traders at once");
ok(/MineTrader\.ROTATE_SECONDS/.test(TRADER), "the roster rotates on a clock");
const caseIds = [...TRADER.matchAll(/id = "(case_[a-z]+)"/g)].map((m) => m[1]);
ok(caseIds.length === 7, "seven cases: five tool, one hat, one charm", caseIds.join(" "));
// Counted inside the CASES table only. rollCase also returns `kind = "tool"`,
// so matching the whole file reports six and the check fails on correct code.
const casesBlock = TRADER.slice(TRADER.indexOf("MineTrader.CASES = {"),
  TRADER.indexOf("MineTrader.CASE_BY_ID = {}"));
ok((casesBlock.match(/kind = "tool"/g) || []).length === 5, "exactly five tool cases");
ok(/kind = "hat"/.test(TRADER) && /kind = "charm"/.test(TRADER), "a hats case and a charm case");

if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU)) {
  console.log("  " + Luau.missing("luau"));
  console.log(fails === 0 ? ">>> trader OK (static only)" : `>>> ${fails} FAILED`);
  process.exit(fails === 0 ? 0 : 1);
}

// The module requires MineCharms and MineTemper; stub both. The charm stub only
// has to return something identifiable, because what rollCase does with a charm
// is delegate -- the charm ladder itself is charms.js's job, not this one.
const body = TRADER
  .replace(/^local Charms = require\([^\n]*\)$/m,
    'local Charms = { rollChestCharm = function() return { id = "stub_charm", name = "Stub", rarity = "C" } end }')
  .replace(/^local Temper = require\([^\n]*\)$/m,
    'local Temper = { GRADE_ORDER = { "F","D","C","B","A","S","SS","SSS" },' +
    ' RARITY_WEIGHTS = { F=5000,D=2763,C=1250,B=675,A=250,S=50,SS=10,SSS=2 } }')
  .replace(/^return MineTrader$/m, "");

// Roblox's Random does not exist in standalone Luau. An LCG is enough: the
// checks below ask whether a roll stays inside its band and which end it
// favours, not whether the generator is good.
const harness = `local Random = {}
Random.__index = Random
function Random.new(seed)
	return setmetatable({ s = (tonumber(seed) or 12345) % 2147483647 }, Random)
end
function Random:_next()
	self.s = (self.s * 1103515245 + 12345) % 2147483648
	return self.s / 2147483648
end
function Random:NextNumber(a, b)
	local r = self:_next()
	if a and b then return a + r * (b - a) end
	return r
end
function Random:NextInteger(a, b)
	return math.floor(a + self:_next() * (b - a + 1 - 1e-9))
end

${body}

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

-- A realistic spot list: 11 zones x the seam ladder, which is what the server
-- passes once the plazas are built.
local spots = {}
for zi = 1, 11 do
	for _, seam in ipairs({ 500, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000 }) do
		table.insert(spots, { zoneId = "zone" .. zi, zoneIndex = zi, seam = seam })
	end
end
check("the spot list is the whole outpost grid", #spots == 110, tostring(#spots) .. " spots")

-- ------------------------------------------------------------ placement --
do
	local p = MineTrader.placements(1, spots)
	check("five traders are placed", #p == 5, tostring(#p))
end
do
	-- No two on the same pad, over many rotations. This is the one that fails if
	-- placement ever goes back to five independent draws.
	local collisions, rotations = 0, 5000
	for rot = 1, rotations do
		local p = MineTrader.placements(rot, spots)
		local seen = {}
		for _, t in ipairs(p) do
			local key = t.zoneId .. "|" .. t.seam
			if seen[key] then collisions += 1 end
			seen[key] = true
		end
	end
	check("no two traders ever share an outpost", collisions == 0,
		string.format("%d collisions over %d rotations", collisions, rotations))
end
do
	-- Every spot should be reachable, and no spot should be favoured. With 110
	-- spots and 5 per rotation, 20000 rotations gives ~909 visits each.
	local seen, rotations = {}, 20000
	for rot = 1, rotations do
		for _, t in ipairs(MineTrader.placements(rot, spots)) do
			local key = t.zoneId .. "|" .. t.seam
			seen[key] = (seen[key] or 0) + 1
		end
	end
	local n, lo, hi = 0, math.huge, 0
	for _, v in pairs(seen) do
		n += 1
		lo, hi = math.min(lo, v), math.max(hi, v)
	end
	check("every outpost can host a trader", n == #spots, string.format("%d of %d reached", n, #spots))
	local expect = rotations * 5 / #spots
	check("no outpost is favoured", lo > expect * 0.75 and hi < expect * 1.25,
		string.format("visits %d..%d, expected ~%.0f", lo, hi, expect))
end
do
	-- Same rotation, same answer. A trader that moved between two players asking
	-- would make "there's one at Bloodmoon 1500" a lie.
	local a, b = MineTrader.placements(77, spots), MineTrader.placements(77, spots)
	local same = #a == #b
	for i = 1, #a do
		if a[i].zoneId ~= b[i].zoneId or a[i].seam ~= b[i].seam then same = false end
	end
	check("a rotation always places the same way", same)
	local c = MineTrader.placements(78, spots)
	local moved = false
	for i = 1, math.min(#a, #c) do
		if a[i].zoneId ~= c[i].zoneId or a[i].seam ~= c[i].seam then moved = true end
	end
	check("the next rotation moves them", moved)
end
check("fewer spots than traders still works", #MineTrader.placements(3, { spots[1], spots[2] }) == 2)
check("no spots places nobody", #MineTrader.placements(3, {}) == 0)

-- ---------------------------------------------------------------- stock --
do
	local s = MineTrader.stockFor(1, 6, 3500)
	check("a trader carries some cases", #s >= MineTrader.STOCK_MIN and #s <= MineTrader.STOCK_MAX,
		tostring(#s) .. " cases")
	local seen, dup = {}, 0
	for _, row in ipairs(s) do
		if seen[row.caseId] then dup += 1 end
		seen[row.caseId] = true
	end
	check("a trader never lists the same case twice", dup == 0)
end
do
	-- THE GATE. The shallowest, earliest spot must never show a deep case, over
	-- thousands of rotations rather than one.
	local leaked, rotations = {}, 4000
	for rot = 1, rotations do
		for _, row in ipairs(MineTrader.stockFor(rot, 1, 0)) do
			local c = MineTrader.CASE_BY_ID[row.caseId]
			if (c.minSeam or 0) > 0 or (c.minZone or 1) > 1 then
				leaked[row.caseId] = true
			end
		end
	end
	local names = {}
	for id in pairs(leaked) do table.insert(names, id) end
	check("a surface zone-1 trader never stocks a gated case", #names == 0,
		#names > 0 and table.concat(names, ",") or "clean over " .. rotations .. " rotations")
end
do
	-- And the deep spot must actually reach the top case, or the gate is a wall.
	local sawApex = false
	for rot = 1, 4000 do
		for _, row in ipairs(MineTrader.stockFor(rot, 11, 5000)) do
			if row.caseId == "case_apex" then sawApex = true end
		end
	end
	check("a deep late-zone trader does stock the Apex case", sawApex)
end
do
	local a = MineTrader.stockFor(5, 3, 1500)
	local b = MineTrader.stockFor(5, 3, 1500)
	local same = #a == #b
	for i = 1, #a do if a[i].caseId ~= b[i].caseId then same = false end end
	check("the same trader shows the same shelf to everyone", same)
	local other = MineTrader.stockFor(5, 7, 1500)
	check("a different zone is a different shelf",
		#other ~= #a or other[1].caseId ~= a[1].caseId or other[1].tokens ~= a[1].tokens)
end

-- ---------------------------------------------------------------- price --
do
	local shallow = MineTrader.priceFor("case_rough", 1, 0)
	local deep = MineTrader.priceFor("case_rough", 11, 5000)
	check("the same case costs more deeper", deep > shallow,
		string.format("%d at zone 1 surface vs %d at zone 11 / 5000", shallow, deep))
	check("price never falls below the base",
		MineTrader.priceFor("case_rough", 1, 0) >= MineTrader.CASE_BY_ID.case_rough.tokens)
	check("an unknown case has no price", MineTrader.priceFor("nope", 1, 0) == nil)
	local climbs = true
	local last = 0
	for _, id in ipairs({ "case_rough", "case_keen", "case_fine", "case_prime", "case_apex" }) do
		local v = MineTrader.priceFor(id, 6, 2500)
		if v <= last then climbs = false end
		last = v
	end
	check("the tool cases get dearer as their tiers climb", climbs)
end

-- ----------------------------------------------------------------- roll --
do
	local rng = Random.new(99)
	local lo, hi = math.huge, 0
	for _ = 1, 4000 do
		local r = MineTrader.rollCase("case_apex", rng)
		lo, hi = math.min(lo, r.tier), math.max(hi, r.tier)
	end
	local c = MineTrader.CASE_BY_ID.case_apex
	check("a tool case only pays inside its band", lo >= c.tierLo and hi <= c.tierHi,
		string.format("rolled %d..%d, band %d..%d", lo, hi, c.tierLo, c.tierHi))
	check("and it reaches both ends of it", lo == c.tierLo and hi == c.tierHi,
		string.format("%d..%d", lo, hi))

	local charm = MineTrader.rollCase("case_charm", rng)
	check("the charm case pays a charm", charm and charm.kind == "charm")
	local hat = MineTrader.rollCase("case_hats", rng)
	check("the hats case pays a hat with a grade", hat and hat.kind == "hat" and hat.rarity ~= nil)
	-- The hat grade must favour the common end, like every other graded roll.
	local lowN, topN = 0, 0
	for _ = 1, 20000 do
		local h = MineTrader.rollCase("case_hats", rng)
		if h.rarity == "F" or h.rarity == "D" then lowN += 1 end
		if h.rarity == "SS" or h.rarity == "SSS" then topN += 1 end
	end
	check("hat grades favour the common end", lowN > topN * 10,
		string.format("%d low vs %d top", lowN, topN))
	check("an unknown case rolls nothing", MineTrader.rollCase("nope", rng) == nil)
end

-- ------------------------------------------------------------- rotation --
do
	check("the rotation advances with the clock",
		MineTrader.rotationFor(0) == 0
			and MineTrader.rotationFor(MineTrader.ROTATE_SECONDS) == 1
			and MineTrader.rotationFor(MineTrader.ROTATE_SECONDS * 3 + 1) == 3)
	local left = MineTrader.secondsLeft(MineTrader.ROTATE_SECONDS * 2 + 10)
	check("the countdown is inside the period", left > 0 and left <= MineTrader.ROTATE_SECONDS,
		tostring(left) .. "s left")
end

print(fails == 0 and ">>> trader OK" or (">>> " .. fails .. " FAILED"))
`;

//[[ ------------------------------------------------- the server wiring ----
// The rules above are pure and provable. The spend is not: it happens inside a
// verb, against a profile, in a script this harness cannot run. So the checks
// that matter most are static, and each one is an exploit if it goes missing.
//
// The shape of the exploit is always the same: the prompt is in the WORLD, so a
// client can fire the buy verb naming any outpost it likes without walking to
// one. Every check below exists because the client controls that payload.
{
  const SRV = Luau.readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineServer.server.luau"));
  const NPC = Luau.readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineTraderNPC.luau"));
  console.log("");

  ok(/elseif action == "buyTraderCase" then Verbs\.buyTraderCase\(plr, payload\)/.test(SRV),
    "buyTraderCase is reachable from the net dispatch");

  const verb = SRV.slice(SRV.indexOf("function Verbs.buyTraderCase("),
    SRV.indexOf("--[[\n\tBUY A GRADED CHARM"));
  ok(verb.length > 0, "Verbs.buyTraderCase exists");
  ok(/Dig\.TraderNPC\.canTrade\(p, zoneId, seam, Dig\.Auth\)/.test(verb),
    "it re-checks that a trader is actually at that outpost",
    "otherwise a surface player buys the deep stock by sending a different seam");
  ok(/for _, r in ipairs\(offer\.stock or \{\}\) do/.test(verb) && /if not row then/.test(verb),
    "it refuses a case that is not on that trader's shelf",
    "without this the depth gate in stockFor is decoration");
  ok(/tonumber\(row\.tokens\)/.test(verb) && !/payload\.(tokens|price)/.test(verb),
    "the price comes from the shelf row, never from the payload");
  ok(/p\.temperTokens = \(tonumber\(p\.temperTokens\) or 0\) \+ price/.test(verb),
    "a case that cannot build its reward refunds instead of charging for nothing");
  // Debit must come after the roll resolves, or a nil reward still costs.
  const rollAt = verb.indexOf("Dig.Trader.rollCase("), debitAt = verb.indexOf("- price");
  ok(rollAt > -1 && debitAt > rollAt,
    "the reward is rolled before the tokens are taken",
    "debiting first means a failed roll is a paid-for nothing");
  // The seam check lives in canTrade, not in the verb -- the verb passes Dig.Auth
  // down to it. Asserted on both halves, because either one going missing breaks
  // it: a verb that stops passing auth, or a canTrade that stops using it.
  ok(/auth and auth\.canAccessSeam and not auth\.canAccessSeam\(p, zoneId, seam\)/.test(NPC),
    "canTrade refuses a seam the player has not opened",
    "a trader at 3,000 is not a way to shop past a seam you never bought");
  ok(/canTrade\(p, zoneId, seam, Dig\.Auth\)/.test(verb),
    "the verb hands canTrade the real auth module, so that check can run");

  // The spawner's own trap: placement draws from spots() BY INDEX, so an
  // unsorted list would make two servers disagree about where the traders are --
  // silently undoing the whole reason the rules are deterministic.
  ok(/table\.sort\(out, function\(a, b\)/.test(NPC),
    "the outpost list is sorted before placement draws from it",
    "GetChildren order is not guaranteed; unsorted means servers disagree");
  ok(/DepthPlaza_\(\.-\)_\(%d\+\)/.test(NPC),
    "spots come from the plazas that were actually built, not from the seam ladder");
  ok(/p\.CanQuery = false/.test(NPC) && /p\.CastShadow = false/.test(NPC),
    "trader parts are non-query and non-shadow, like the rest of the mine");
}

const tmp = path.join(require("os").tmpdir(), "trader-harness.luau");
fs.writeFileSync(tmp, harness);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" });
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
}
process.stdout.write(out);
if (!/>>> trader OK/.test(out)) fails++;

console.log(fails === 0 ? ">>> trader OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
