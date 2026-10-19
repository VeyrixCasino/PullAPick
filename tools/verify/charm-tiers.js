// ONE RARITY PER CHARM, A TIER I TO V, AND EIGHT CHARM PACKS (owner, 2026-10-19).
//
// "each charm has its own rarity always. {sod charm rare always}"; "f-sss
// charms (same system as packs)"; merging raises a charm's "teir i to v", for
// gems plus "any charm of the same tier", and never changes its rarity; "more
// charm types at every rarity" (Common and Uncommon too); "charm packs for the
// main game, one per chest rarity ("{rarity} Charm Pack")", for gems or
// credits; and the Candy Crypt's eight chest charms
// (MineCharms.cryptChestCharm, the contract the Crypt calls).
//
// Runs the real MineCharms (with the real MineConfig ore roster and MineTemper)
// and the real server verbs (MineCharmService) on stub profiles, in luau:
//   1. every charm has one rarity, F..SSS; every rarity has a real pool; the
//      new charms carry no gem lever; the Sod Charm is Rare (C)
//   2. tiers: stats at I are the charm's own; they grow to V; Gem Find, Ore
//      Quality, Ore Finder and a pact's cost do not
//   3. the merge: tier up, fodder of the same tier used up, gems charged,
//      rarity unchanged, every refusal changes nothing, the worn copy is safe
//   4. the Charm Packs: eight, priced up the ladder, odds = the draw, tier I
//   5. a chest's charm keeps the 36's rarity shares; the draw matches
//   6. the Crypt contract
//   7. wiring: the verbs, the paid-random rule, the snapshot, rebirth, load,
//      the client and the shelf
//
//   node tools/verify/charm-tiers.js
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");
const Shared = require("./_shared");
const Stubs = require("./_stubs");

const ROOT = path.resolve(process.argv[2] || path.join(__dirname, "../.."));
let fail = 0;
const check = (ok, msg, detail) => {
  console.log((ok ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!ok) fail++;
};
if (!Luau.ready) {
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(1);
}
const SH = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared");
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const mods = Stubs.ECONOMY_MODULES.filter((m) => fs.existsSync(path.join(SH, m + ".luau")));
const SVC = path.join(ROOT, "src/ServerScriptService/Mine/MineCharmService.luau");
const svcSrc = fs.existsSync(SVC) ? Luau.readSrc(SVC) : "return nil";

const test = `
local function R(n) return require(SHARED:FindFirstChild(n)) end
local ok, err = pcall(function()
local Ch = R("MineCharms")
local Temper = R("MineTemper")
local C = R("MineConfig")
local function out(tag, ...) print(tag .. " " .. table.concat({ ... }, " ")) end
local LAD = { "F", "D", "C", "B", "A", "S", "SS", "SSS" }
local VALID = {}
for _, g in ipairs(LAD) do VALID[g] = true end

-- 1. rarity
local noRarity, oreWrong, ids, names, dupId = 0, 0, {}, {}, 0
for _, d in ipairs(Ch.LIST) do
	if not VALID[d.rarity] then noRarity += 1 print("NORARITY " .. d.id) end
	if ids[d.id] then dupId += 1 end
	ids[d.id] = true
	if d.source == "ore" then
		local ore = C.oreById and C.oreById(d.oreId)
		if not ore or LAD[ore.bandIndex] ~= d.rarity then oreWrong += 1 end
	end
end
out("RARITY", noRarity, oreWrong, dupId, #Ch.LIST, tostring(Ch.byId("sod") and Ch.byId("sod").rarity))
local pools, lever, peakBad = {}, 0, {}
for _, g in ipairs(LAD) do table.insert(pools, g .. "=" .. #Ch.gradedOf(g)) end
local peak = {}
for _, d in ipairs(Ch.GRADED) do
	local m = 0
	for _, v in pairs(d.stats or {}) do m = math.max(m, v) end
	peak[d.rarity] = math.max(peak[d.rarity] or 0, m)
end
for _, r in ipairs(Ch.NEW_GRADED or {}) do
	for stat in pairs(r.stats) do
		if stat == "gemFind" or stat == "rareOre" or stat == "fossilFind" or stat == "backpack" then lever += 1 end
	end
end
for i = 2, #LAD do
	if not ((peak[LAD[i]] or 0) > (peak[LAD[i - 1]] or 0)) then table.insert(peakBad, LAD[i]) end
end
out("POOLS", table.concat(pools, ","), #(Ch.NEW_GRADED or {}), lever, #peakBad > 0 and table.concat(peakBad, ",") or "none")

-- 2. tiers
local function same(a, b)
	for k, v in pairs(a) do if math.abs((b[k] or 0) - v) > 1e-9 then return false end end
	for k, v in pairs(b) do if math.abs((a[k] or 0) - v) > 1e-9 then return false end end
	return true
end
local tierI, grow, flat, pact = true, true, true, true
for _, d in ipairs(Ch.LIST) do
	if not same(Ch.statsAt(d, 1), d.stats or {}) then tierI = false end
	local v5 = Ch.statsAt(d, 5)
	for stat, v in pairs(d.stats or {}) do
		if v > 0 and not Ch.TIER_FLAT[stat] and not (v5[stat] > v) then grow = false end
		if Ch.TIER_FLAT[stat] and v5[stat] ~= v then flat = false end
		if v < 0 and v5[stat] ~= v then pact = false end
	end
end
local mono = true
for t = 2, Ch.TIER_MAX do if not (Ch.TIER_MULT[t] > Ch.TIER_MULT[t - 1]) then mono = false end end
out("TIERS", Ch.TIER_MAX, Ch.TIER_MULT[1], tostring(mono), tostring(tierI), tostring(grow), tostring(flat), tostring(pact),
	Ch.romanTier(1), Ch.romanTier(5))

-- 3. the merge (the shared rule, then the server verb)
local p = { charms = { sod = 2, greenleaf = 1, darkmoon = true }, gems = 10 ^ 9, equippedCharm = "sod" }
local okA, why = Ch.applyMerge(p, "sod", 1, "greenleaf")
out("MERGE1", tostring(okA), tostring(p.charms.sod), tostring(p.charms.greenleaf), tostring(p.charmTiers.sod and p.charmTiers.sod.II),
	tostring(10 ^ 9 - p.gems == Ch.mergeGemCost("C", 2)), tostring(Ch.byId("sod").rarity))
local snap = function() return p.gems, p.charms.sod, p.charmTiers.sod and p.charmTiers.sod.II end
local g0, s0, t0 = snap()
local refusals = {
	{ "sod", 2, "darkmoon" },        -- fodder at another tier
	{ "sod", 3, "sod" },             -- no copy at III
	{ "sod", 5, "sod" },             -- V is the top
	{ "nothing", 1, "sod" },         -- not a charm
}
local refusedAll = true
for _, r in ipairs(refusals) do
	local okR = Ch.applyMerge(p, r[1], r[2], r[3])
	if okR then refusedAll = false end
end
local poor = { charms = { sod = 2 }, gems = 1 }
local okPoor = Ch.applyMerge(poor, "sod", 1, "sod")
local g1, s1, t1 = snap()
out("REFUSE", tostring(refusedAll), tostring(okPoor), tostring(g0 == g1 and s0 == s1 and t0 == t1), tostring(poor.charms.sod == 2 and poor.gems == 1))
-- the worn copy: never used up to raise another charm; two copies of it merge fine
local w = { charms = { galaxy_core = 1, greenleaf = 1 }, gems = 10 ^ 9, equippedCharm = "galaxy_core" }
local okW = Ch.applyMerge(w, "greenleaf", 1, "galaxy_core")
local w2 = { charms = { galaxy_core = 2 }, gems = 10 ^ 9, equippedCharm = "galaxy_core" }
local okW2 = Ch.applyMerge(w2, "galaxy_core", 1, "galaxy_core")
out("WORN", tostring(okW), tostring(w.charms.galaxy_core), tostring(okW2), tostring(Ch.bestTier(w2, "galaxy_core")), tostring(w2.equippedCharm))
-- fodder is any charm at the tier, cheapest first; tiers I..V all the way up
local f = Ch.fodderFor({ charms = { galaxy_core = 1, greenleaf = 1, darkmoon = 1, sod = 1 }, equippedCharm = "darkmoon" }, "galaxy_core", 1)
local fl = {}
for _, x in ipairs(f) do table.insert(fl, x.id) end
out("FODDER", table.concat(fl, ","))
local climb = { charms = { acorn_charm = 16 }, gems = 10 ^ 12 }
local steps = 0
for t = 1, 4 do
	while Ch.tierCounts(climb, "acorn_charm")[t] >= 2 do
		if not Ch.applyMerge(climb, "acorn_charm", t, "acorn_charm") then break end
		steps += 1
	end
end
local cc = Ch.tierCounts(climb, "acorn_charm")
out("CLIMB", steps, table.concat(cc, ","), tostring(climb.charms.acorn_charm), tostring(Ch.byId("acorn_charm").rarity))
-- applied at the worn tier
local b1, b5 = { mineSpeed = 1 }, { mineSpeed = 1 }
Ch.applyEquipped(b1, "acorn_charm", { charms = { acorn_charm = 1 }, equippedCharm = "acorn_charm" })
Ch.applyEquipped(b5, "acorn_charm", climb.equippedCharm and climb or { charms = climb.charms, charmTiers = climb.charmTiers, equippedCharm = "acorn_charm" })
out("APPLY", string.format("%.6f %.6f %.6f", b1.mineSpeed, b5.mineSpeed, Ch.TIER_MULT[5]))
-- the server verb (MineCharmService), on a stub profile
local Svc = (function()
${svcSrc}
end)()
local toasts, saves = {}, 0
local prof = { charms = { sod = 1, acorn_charm = 1 }, gems = 10 ^ 9, credits = 1000, equippedCharm = "sod" }
local plr = { UserId = 7 }
Svc.init({ profiles = { [7] = prof }, net = { FireClient = function(_, _, kind, msg) if kind == "toast" then table.insert(toasts, tostring(msg)) end end },
	snap = function() end, markDirty = function() end, walk = function() end, bumpStat = function() end, benchNum = function(n) return tostring(n) end,
	save = function() saves += 1 end })
Svc.merge(plr, { id = "sod", tier = 1, fodderId = "acorn_charm" })
out("SVCMERGE", tostring(Ch.bestTier(prof, "sod")), tostring(prof.charms.acorn_charm), tostring(10 ^ 9 - prof.gems))
local before = prof.credits
Svc.buyPack(plr, { rarity = "SSS", pay = "credits" })
local boughtId
for id, n in pairs(prof.charms) do
	local d = Ch.byId(id)
	if d and d.rarity == "SSS" and d.source == "charm" then boughtId = id end
end
out("SVCPACK", tostring(before - prof.credits), tostring(boughtId), tostring(boughtId and Ch.bestTier(prof, boughtId)), tostring(saves))
local g = prof.gems
Svc.buyPack(plr, { rarity = "F", pay = "gems" })
out("SVCPACKG", tostring(g - prof.gems))
local poorP = { charms = {}, gems = 1, credits = 0 }
Svc.init({ profiles = { [8] = poorP }, net = { FireClient = function() end }, snap = function() end, markDirty = function() end })
Svc.buyPack({ UserId = 8 }, { rarity = "A", pay = "credits" })
Svc.buyPack({ UserId = 8 }, { rarity = "nope", pay = "gems" })
out("SVCPOOR", tostring(next(poorP.charms) == nil and poorP.gems == 1 and poorP.credits == 0))
local bad = { charms = { sod = 1 }, charmTiers = { sod = { II = 3, V = 1 }, ghost = { II = 1 } } }
Ch.normalizeTiers(bad)
out("NORMALIZE", tostring(bad.charmTiers.ghost == nil), table.concat(Ch.tierCounts(bad, "sod"), ","))

-- 4. the Charm Packs
local packs, monoG, oddsOk, rollOk = {}, true, true, true
local prevG, prevC = 0, 0
for _, pk in ipairs(Ch.CHARM_PACKS) do
	table.insert(packs, pk.name)
	if not (pk.gems > prevG and pk.credits > prevC) then monoG = false end
	prevG, prevC = pk.gems, pk.credits
	local odds = Ch.charmPackOdds(pk.rarity)
	local want, sum = {}, 0
	for _, r in ipairs(odds) do
		want[r.id] = r.p
		sum += r.p
		if Ch.byId(r.id).rarity ~= pk.rarity then oddsOk = false end
	end
	if math.abs(sum - 1) > 1e-9 or #odds < 5 then oddsOk = false end
	local rng, got, N = Random.new(11), {}, 30000
	for _ = 1, N do
		local d = Ch.rollCharmPack(pk.rarity, rng)
		got[d.id] = (got[d.id] or 0) + 1
	end
	for id, p0 in pairs(want) do
		if math.abs((got[id] or 0) / N - p0) > 0.01 then rollOk = false end
	end
end
out("PACKS", #Ch.CHARM_PACKS, table.concat(packs, "|"), tostring(monoG), tostring(oddsOk), tostring(rollOk))

-- 5. chest charm shares
local old = { F = 8 * 5000, D = 7 * 2763, C = 6 * 1250, B = 5 * 675, A = 4 * 250, S = 3 * 50, SS = 2 * 10, SSS = 2 }
local oldTot = 0
for _, v in pairs(old) do oldTot += v end
local worstShare = 0
local odds = Ch.chestCharmOdds()
for _, row in ipairs(odds) do worstShare = math.max(worstShare, math.abs(row.p - old[row.grade] / oldTot)) end
local rng, got, N = Random.new(3), {}, 200000
for _ = 1, N do
	local d = Ch.rollChestCharm(rng)
	got[d.rarity] = (got[d.rarity] or 0) + 1
end
local worstDraw = 0
for _, row in ipairs(odds) do worstDraw = math.max(worstDraw, math.abs((got[row.grade] or 0) / N - row.p)) end
out("CHEST", #odds, string.format("%.2e %.4f", worstShare, worstDraw))

-- 6. the Crypt contract
local cryptIds, cryptOk = {}, true
for _, r in ipairs(LAD) do
	local id = Ch.cryptChestCharm(r)
	local d = id and Ch.byId(id)
	if not d or d.rarity ~= r or d.source ~= "crypt" or string.sub(id, 1, 7) ~= "hallow_" or not Ch.mergeTarget(id, 1) then cryptOk = false end
	if cryptIds[tostring(id)] then cryptOk = false end
	cryptIds[tostring(id)] = true
end
out("CRYPT", tostring(cryptOk), tostring(Ch.cryptChestCharm("X") == nil), tostring(Ch.charmTokenPrice(Ch.cryptChestCharm("S")) == nil))
end)
if not ok then print("ERROR " .. tostring(err)) end
`;

const lua = Shared.prelude(ROOT, mods, ["SetPets", "HolidayPets"]) + Stubs.ROBLOX + test;
const tmp = path.join(require("os").tmpdir(), `mfc-charm-tiers-${process.pid}.luau`);
fs.writeFileSync(tmp, lua);
let outText = "";
try {
  outText = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8", maxBuffer: 1 << 26 });
} catch (e) {
  outText = String(e.stdout || "") + String(e.stderr || "");
}
try { fs.unlinkSync(tmp); } catch (e) { /* gone */ }
const get = (tag) => {
  const m = outText.match(new RegExp("^" + tag + " (.*)$", "m"));
  return m ? m[1].split(" ") : [];
};
const err = (outText.match(/^ERROR (.*)$/m) || [])[1];
check(!err && outText.includes("RARITY"), "the real modules load and run", err || "");

// 1
const ra = get("RARITY");
check(ra[0] === "0", "every charm has one rarity, F..SSS", `${ra[0]} without, of ${ra[3]}`);
check(ra[1] === "0", "an ore charm's rarity is its ore's band (Common F .. Exotic SSS)", `${ra[1]} wrong`);
check(ra[2] === "0", "no two charms share an id");
check(ra[4] === "C", "the Sod Charm is Rare, always (owner: \"{sod charm rare always}\")", ra[4]);
const po = get("POOLS");
check(po[0] === "F=12,D=11,C=10,B=9,A=8,S=7,SS=6,SSS=5", "every rarity has a real pool, Common and Uncommon too", po[0]);
check(po[1] === "32", "32 new charm types, four at every rarity", po[1]);
check(po[2] === "0", "no new charm carries Gem Find, Ore Quality, Ore Finder or the retired Backpack", `${po[2]} do`);
check(po[3] === "none", "a rarer graded charm still peaks higher", po[3]);

// 2
const ti = get("TIERS");
check(ti[0] === "5" && ti[1] === "1" && ti[2] === "true", "tiers I to V, x1 at I, climbing", ti.slice(0, 3).join(" "));
check(ti[3] === "true", "a charm's stats at tier I are its own");
check(ti[4] === "true", "every gift grows by tier V");
check(ti[5] === "true", "Gem Find, Ore Quality and Ore Finder never grow (a merge never prints gems)");
check(ti[6] === "true", "a pact's cost stays bounded (never grows past its tier-I value)");
check(ti[7] === "I" && ti[8] === "V", "tiers read as roman numerals");

// 3
const m1 = get("MERGE1");
check(m1[0] === "true" && m1[1] === "2" && m1[2] === "nil" && m1[3] === "1",
  "a merge raises one copy a tier and uses up a charm of the same tier (any charm)", m1.join(" "));
check(m1[4] === "true", "...and charges the rarity's gem price for the tier it reaches");
check(m1[5] === "C", "...and never changes the rarity");
const rf = get("REFUSE");
check(rf[0] === "true", "refused: fodder at another tier, no copy at that tier, past V, not a charm");
check(rf[1] === "false" && rf[3] === "true", "refused when the gems are short, and nothing is taken");
check(rf[2] === "true", "a refused merge changes nothing");
const wo = get("WORN");
check(wo[0] === "false" && wo[1] === "1", "the worn charm is never used up to raise another one");
check(wo[2] === "true" && wo[3] === "2" && wo[4] === "galaxy_core", "two copies of the worn charm merge, and it stays worn, a tier up");
check(get("FODDER").join(" ") === "greenleaf,sod", "the fodder list: any charm at the tier, cheapest first, never the worn one", get("FODDER").join(" "));
const cl = get("CLIMB");
check(cl[0] === "15" && cl[1] === "0,0,0,0,1" && cl[2] === "1", "16 copies climb to one at tier V in 15 merges", cl.join(" "));
const ap = get("APPLY").map(Number);
// statsAt rounds a grown stat to a whole percent (+52% x2.10 = +109%).
check(ap[0] > 1 && Math.abs((ap[1] - 1) - (ap[0] - 1) * ap[2]) <= 0.0051,
  "the worn charm pays at its tier (a tier-V Acorn gives x2.10 its tier-I gift, to the percent)", ap.slice(0, 2).join(" vs "));
const sm = get("SVCMERGE");
check(sm[0] === "2" && sm[1] === "nil" && Number(sm[2]) > 0, "the server verb merges (MineCharmService.merge)", sm.join(" "));
const sp = get("SVCPACK");
check(sp[0] === "500" && sp[1] !== "nil" && sp[2] === "1", "an SSS Charm Pack for 500 credits pays an SSS charm at tier I", sp.join(" "));
check(sp[3] === "1", "...and the purchase is saved at once, like the other gem and credit buys", `${sp[3]} saves`);
check(get("SVCPACKG")[0] === "2500", "an F Charm Pack takes 2,500 gems", get("SVCPACKG")[0]);
check(get("SVCPOOR")[0] === "true", "a player who cannot pay, or names no pack, is charged nothing and gets nothing");
const nz = get("NORMALIZE");
check(nz[0] === "true" && nz[1] === "0,0,0,0,1", "a broken tier save is trimmed on load, keeping the best copy", nz.join(" "));

// 4
const pk = get("PACKS");
check(pk[0] === "8", "eight Charm Packs", pk[0]);
const packLine = outText.match(/^PACKS (\d+) (.*) (true|false) (true|false) (true|false)$/m);
check(packLine && packLine[2] === "F Charm Pack|D Charm Pack|C Charm Pack|B Charm Pack|A Charm Pack|S Charm Pack|SS Charm Pack|SSS Charm Pack",
  "named \"{rarity} Charm Pack\", F to SSS, in order", packLine ? packLine[2] : "");
check(packLine && packLine[3] === "true", "priced up the ladder in gems and in credits");
check(packLine && packLine[4] === "true", "each pack's odds: its own rarity's charms, each as likely, summing to 1");
check(packLine && packLine[5] === "true", "...and the roll draws them (30,000 opens each)");

// 5
const cs = get("CHEST");
check(cs[0] === "8" && Number(cs[1]) < 1e-12, "a chest's charm keeps the 36's rarity shares, with more charms in each", cs.join(" "));
check(Number(cs[2]) < 0.004, "rollChestCharm draws them (200,000 rolls)", cs[2]);

// 6
const cr = get("CRYPT");
check(cr[0] === "true", "MineCharms.cryptChestCharm gives each Crypt rank F..SSS its own Halloween charm, of that rarity, mergeable");
check(cr[1] === "true" && cr[2] === "true", "...nil for an unknown rank, and Crypt charms are not token-bought");

// 7 wiring (static)
const strip = (s) => s.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
const SRV = strip(read("src/ServerScriptService/Mine/MineServer.server.luau"));
check(/Verbs\.Charm = require\(script\.Parent:WaitForChild\("MineCharmService"\)\)/.test(SRV), "MineServer wires MineCharmService as Verbs.Charm");
{
  // Every value handed to the service is a local declared (and, for markDirty,
  // assigned) ABOVE the wiring, or it would reach the service as nil.
  const at = SRV.indexOf("Verbs.Charm.init(");
  const above = (re) => { const m = re.exec(SRV); return !!m && m.index < at; };
  check(at > -1 && /save = save,/.test(SRV.slice(at, at + 400))
    && above(/^local profiles\b/m) && above(/^local net = /m) && above(/^local function snap\(/m)
    && above(/^function markDirty\(/m) && above(/^local function walk\(/m) && above(/^local function bumpStat\(/m)
    && above(/^local function save\(/m),
    "the service gets profiles, net, snap, markDirty, walk, bumpStat and save, all set above the wiring");
}
check(/function Verbs\.mergeCharm\(plr, payload\)\s*Verbs\.Charm\.merge\(plr, payload\)/.test(SRV), "mergeCharm keeps its name and calls the service");
check(/elseif action == "buyCharmPack" then Verbs\.Charm\.buyPack\(plr, payload\)/.test(SRV), "buyCharmPack is routed");
check(/buyCharmPack = true,/.test(SRV), "a Charm Pack is a paid random buy (Verbs.PAID_RANDOM)");
check(/charmTiers = p\.charmTiers,/.test(SRV) && /fresh\.charmTiers = p\.charmTiers/.test(SRV) && /charmTiers = \{\},/.test(SRV),
  "the tier save rides the snapshot, survives rebirth and starts empty");
const decl = SRV.indexOf("local Charms = require(");
const norm = SRV.indexOf("Charms.normalizeTiers(p)");
check(decl > -1 && norm > decl && SRV.indexOf("local Verbs = {}") > norm,
  "load trims the tier save through the Charms upvalue (Verbs is declared later: the global-read trap)");
const CLI = strip(read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau"));
check(/FireServer\("buyCharmPack", \{ rarity = /.test(CLI) && /FireServer\("mergeCharm", \{ id = id, tier = tier, fodderId = fodderId \}\)/.test(CLI),
  "the client sends the pack buy and the merge with its tier and fodder");
const INV = strip(read("src/ReplicatedStorage/Mine/Shared/MineInventoryView.luau"));
check(/Charms\.CHARM_PACKS/.test(INV) && /Charms\.charmPackOdds\(pack\.rarity\)/.test(INV) && /View\.sheet\(root, \{/.test(INV)
  && /opts\.onBuyCharmPack\(pack\.rarity, "gems"\)/.test(INV) && /opts\.onBuyCharmPack\(pack\.rarity, "credits"\)/.test(INV),
  "the charm shelf sells the eight packs for gems or credits, with an odds sheet read off MineCharms");
check(!/onBuyCharmsPack/.test(INV), "the old Charms Pack row is off the shelf");
check(/Charms\.fodderFor\(state, item\.id, t\)/.test(INV) && /opts\.onMergeCharm\(item\.id, t, f\.id\)/.test(INV),
  "the merge picker lists what can be used up and sends the choice");
check(/rarity = def\.rarity, tier = best/.test(INV), "a charm tile carries its rarity and its tier");

console.log("");
console.log(fail > 0 ? `>>> charm-tiers: ${fail} FAILED` : ">>> charm-tiers: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
