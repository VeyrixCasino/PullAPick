// THE THREE DEFERRED SHOP DEFAULTS (owner, 2026-10-19: "Use all defaults").
//
//   (a) Pot of Gold and the Weekend Haul paid the Heirloom, Omen and Shiny packs
//       retired on 2026-10-10. They pay wild cases of about the same value now:
//       RUN on the real MinePackConfig and MineCases, the old packs' and the new
//       cases' recycle value (expectedDust) and list price agree within 3%, and
//       both are paid cases (a credit/Robux buy can roll the SSS set).
//   (b) The Limited tab's Founders Bag bought in one tap. It takes two now, the
//       Backpacks shelf's Founders Rig confirm.
//   (c) A limited deal with lucky blocks or cases has an ODDS sheet, and every
//       chance on it comes from the table its roll uses: MineRotatingOffers
//       .oddsSheet is RUN on the real MineLuckyBlocks / MineCases / MinePackConfig
//       / MineZonePacks and checked against them.
//
// Fails on 3863d14 (retired packs in both, no oddsSheet, a one-tap Founders Bag).
//
//   node tools/verify/deal-odds.js
"use strict";
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");
const Shared = require("./_shared");

const ROOT = path.resolve(__dirname, "../..");
const SH = "src/ReplicatedStorage/Mine/Shared/";
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const code = (s) => s.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
let fail = 0;
const check = (ok, msg, detail) => {
  console.log((ok ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!ok) fail++;
};
const between = (s, a, b, from) => {
  const i = s.indexOf(a, from || 0);
  const j = i < 0 ? -1 : s.indexOf(b, i + a.length);
  return (i < 0 || j < 0) ? "" : s.slice(i, j + b.length);
};
console.log("deal-odds: wild cases for the retired packs, a two-tap Founders Bag, odds on random deals");

const OFFERS = code(read(SH + "MineRotatingOffers.luau"));
const CONFIG = code(read(SH + "MineConfig.luau"));
const SRV = code(read("src/ServerScriptService/Mine/MineServer.server.luau"));
const INV = code(read(SH + "MineInventoryView.luau"));
const RETIRED = /"(heirloom_pack|omen_pack|shiny_pack|apex_pack)"/;

// ---------------------------------------------------------------- (a) --
const pot = between(OFFERS, 'id = "deal_pot_gold"', "\n\t},");
const haul = between(CONFIG, "weekend_haul = {", "\n\t},");
check(pot.length > 200 && haul.length > 100, "found Pot of Gold and the Weekend Haul");
const potRows = [...pot.matchAll(/\{ id = "([a-z0-9_]+)", qty = (\d+) \}/g)].map((m) => ({ id: m[1], qty: +m[2] }))
  .filter((r) => !/^pot_/.test(r.id));
const haulRows = [...haul.matchAll(/\{ id = "([a-z0-9_]+)", qty = (\d+) \}/g)].map((m) => ({ id: m[1], qty: +m[2] }))
  .filter((r) => r.id !== "lucky_block");
check(!RETIRED.test(pot) && potRows.length > 0 && potRows.every((r) => /^case_\d(_\d)?$/.test(r.id)),
  "Pot of Gold pays wild cases, not retired packs", potRows.map((r) => r.qty + "x " + r.id).join(", "));
check(!RETIRED.test(haul) && haulRows.length > 0 && haulRows.every((r) => /^case_\d(_\d)?$/.test(r.id)),
  "the Weekend Haul pays wild cases, not retired packs", haulRows.map((r) => r.qty + "x " + r.id).join(", "));
const potBlurb = (pot.match(/blurb = "([^"]*)"/) || [])[1] || "";
const nPot = potRows.reduce((s, r) => s + r.qty, 0);
check(new RegExp(`${nPot} Wild Cases`).test(potBlurb) && !/Heirloom|Omen/.test(potBlurb),
  "Pot of Gold's blurb counts its cases and names no retired pack", `${nPot} cases`);
const grants = SRV.match(/Verbs\.grantPacks\(plr, p, prod\.packs[^)]*\)/g) || [];
check(grants.length === 2 && grants.every((g) => /, true\)$/.test(g)),
  "both Weekend Haul grants (credits, Robux) make paid cases", grants.join(" | "));
check(/function Verbs\.grantPacks\(plr, p, list, paid\)/.test(SRV) && /Cases\.bagRow\(row\.id, paid == true\)/.test(SRV),
  "Verbs.grantPacks stamps `paid` on a wild case when told");

// ---------------------------------------------------------------- (b) --
const limited = between(INV, 'elseif activeTab == "limited" then', 'elseif activeTab == "packs" then');
check(/local twoTap = offer\.kind == "founders"/.test(limited)
  && /if not \(eq\.dealArm and eq\.dealArm\.id == offer\.id and \(now - eq\.dealArm\.at\) < 4\) then\s*eq\.dealArm = \{ id = offer\.id, at = now \}[\s\S]*?return\s*end\s*eq\.dealArm = nil/.test(limited),
  "the Limited tab's Founders Bag arms on the first tap and buys on a second within 4 s");
const armIdx = limited.indexOf("eq.dealArm = { id = offer.id, at = now }"), buyIdx = limited.indexOf("opts.onBuyProductCredits(offer.key or offer.id)");
check(armIdx > -1 && buyIdx > armIdx, "...the buy comes after the arm, never on the first tap");
check(/\(armed and "TAP AGAIN"\)/.test(limited) && /"Tap again to spend "/.test(limited), "...and says what the second tap spends");

// ---------------------------------------------------------------- (c) --
check(/local oddsSpec = RotatingOffers\.oddsSheet and RotatingOffers\.oddsSheet\(offer\)/.test(limited)
  && /inspectP = View\.sheet\(root, oddsSpec, \{/.test(limited) && /Text = "ODDS"/.test(limited),
  "a limited deal's row has ODDS when the deal rolls anything, drawn by MineLuckyOddsView.sheet");
const sheetFn = between(OFFERS, "function MineRotatingOffers.oddsSheet(offer)", "\nend\n");
check(/LuckyBlocks\.oddsSheet\(b\.id, "F"\)/.test(sheetFn) && /Cases\.wildGradeOdds\(true\)/.test(sheetFn)
  && /Cases\.levelOdds\(w\.def\)/.test(sheetFn) && /Packs\.siphonOdds\(zdef\.odds, MineRotatingOffers\.SHINY_PACK_LUCK\)/.test(sheetFn),
  "every chance on the sheet is read off the roll's own table (no typed percentages)");
check(!/\d+(\.\d+)?%/.test(sheetFn.replace(/"[^"\n]*"/g, '""')), "...and none is typed in");
const grantFn = between(OFFERS, "function MineRotatingOffers.grant(p, offer, hooks)", "\nend\n");
check(/luck = 3,/.test(grantFn) && /MineRotatingOffers\.SHINY_PACK_LUCK = 3/.test(OFFERS),
  "the Shiny Packs' sheet uses the luck the deal stamps on them (x3)");

if (!Luau.ready) {
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(1);
}
const potLua = potRows.map((r) => `{ id = "${r.id}", qty = ${r.qty} }`).join(", ");
const haulLua = haulRows.map((r) => `{ id = "${r.id}", qty = ${r.qty} }`).join(", ");
const test = Shared.prelude(ROOT, ["MineRotatingOffers", "MineLuckyBlocks", "MineToolGrades", "MineZonePacks", "MineLaunch",
  "MineCases", "MinePackConfig", "MineSetPets", "MineSetPacks", "MinePackArt", "Mine1PacksData", "Mine1ChestsData"], ["SetPets"]) + `
local O = require(SHARED:FindFirstChild("MineRotatingOffers"))
local Cases = require(SHARED:FindFirstChild("MineCases"))
local Packs = require(SHARED:FindFirstChild("MinePackConfig"))
local LB = require(SHARED:FindFirstChild("MineLuckyBlocks"))
local ZP = require(SHARED:FindFirstChild("MineZonePacks"))
local function value(list)
	local dust, credits = 0, 0
	for _, r in ipairs(list) do
		if Cases.get(r.id) then
			dust += Cases.expectedDust(r.id) * r.qty
			credits += Cases.creditPrice(r.id) * r.qty
		else
			dust += Packs.expectedDust(r.id) * r.qty
			credits += Packs.PACK_PRICE[r.id] * r.qty
		end
	end
	return dust, credits
end
local function ratio(new, old)
	local nd, nc = value(new)
	local od, oc = value(old)
	return string.format("%.4f %.4f %d %d %d %d", nd / od, nc / oc, math.floor(nd + 0.5), math.floor(od + 0.5), nc, oc)
end
-- The old contents, as they were at 3863d14 (the ★★★ case Pot of Gold already paid is in both).
print("POT " .. ratio({ ${potLua} }, { { id = "heirloom_pack", qty = 3 }, { id = "omen_pack", qty = 2 }, { id = "case_4", qty = 1 } }))
print("HAUL " .. ratio({ ${haulLua} }, { { id = "heirloom_pack", qty = 1 }, { id = "shiny_pack", qty = 1 }, { id = "omen_pack", qty = 1 } }))
local paid = Cases.bagRow("${(potRows[0] || { id: "case_6" }).id}", true)
print("PAID " .. tostring(paid and paid.paid))

-- The odds sheet of every deal.
local function sum(rows) local s = 0 for _, r in ipairs(rows) do s += r.p end return s end
local function close(a, b) return math.abs(a - b) < 1e-6 end
for _, offer in ipairs(O.OFFERS) do
	local spec = O.oddsSheet(offer)
	if not spec then
		print("NONE " .. offer.id .. " " .. tostring(O.hasRandom(offer)))
	else
		local bad = {}
		for _, s in ipairs(spec.sections) do
			if #s.rows == 0 then table.insert(bad, "empty:" .. s.header) end
			for _, r in ipairs(s.rows) do
				if type(r.p) ~= "number" or r.p < 0 or r.p > 1 then table.insert(bad, "p:" .. s.header) end
			end
		end
		-- Lucky blocks: each block's grades and kinds sum to 1 and equal oddsSheet.
		for _, b in ipairs(offer.blocks or {}) do
			local sheet = LB.oddsSheet(b.id, "F")
			for _, s in ipairs(spec.sections) do
				if string.find(s.header, "FINAL GRADE", 1, true) and string.find(s.header, "x" .. b.qty, 1, true)
					and string.find(s.header, string.upper(LB.TYPES[b.id].name), 1, true) then
					if not close(sum(s.rows), 1) then table.insert(bad, "gsum:" .. b.id) end
					for _, r in ipairs(s.rows) do
						if not close(r.p, sheet.grades[r.grade] or -1) then table.insert(bad, "grade:" .. b.id .. r.grade) end
					end
				end
				if string.find(s.header, "WHAT EACH OPEN PAYS", 1, true) and string.find(s.header, string.upper(LB.TYPES[b.id].name), 1, true) then
					if not close(sum(s.rows), 1) then table.insert(bad, "ksum:" .. b.id) end
				end
			end
		end
		-- Wild cases: the set rows are a paid case's exact split; each case's stars sum to 1.
		local stars, sets = nil, nil
		for _, s in ipairs(spec.sections) do
			if string.find(s.header, "THE SET EACH SPIN", 1, true) then sets = s end
			if string.find(s.header, "THE PACK EACH SPIN", 1, true) then stars = s end
		end
		local nWild = 0
		for _, r in ipairs(offer.packs or {}) do if Cases.get(r.id) then nWild += 1 end end
		if nWild > 0 then
			if not (sets and close(sum(sets.rows), 1)) then table.insert(bad, "sets") end
			local want = Cases.wildGradeOdds(true)
			for i, r in ipairs((sets and sets.rows) or {}) do
				if not (want[i] and close(r.p, want[i].pct / 100) and r.grade == want[i].grade) then table.insert(bad, "setrow" .. i) end
			end
			if not (stars and close(sum(stars.rows), nWild)) then table.insert(bad, "stars") end
		end
		-- Shiny Packs: each card's rarity is the Meadow Legendary pack at luck x3.
		if (tonumber(offer.shinyPacks) or 0) > 0 then
			local shiny = nil
			for _, s in ipairs(spec.sections) do if string.find(s.header, "SHINY PACK", 1, true) then shiny = s end end
			local odds = Packs.siphonOdds(ZP.get(ZP.id("meadow", "pack_legendary")).odds, 3)
			local total = 0
			for _, v in pairs(odds) do total += v end
			if not (shiny and close(sum(shiny.rows), 1)) then table.insert(bad, "shinysum") end
			for _, r in ipairs((shiny and shiny.rows) or {}) do
				if not close(r.p, odds[r.name] / total) then table.insert(bad, "shiny:" .. r.name) end
			end
		end
		print("SHEET " .. offer.id .. " " .. #spec.sections .. " " .. (#bad == 0 and "clean" or table.concat(bad, ",")))
	end
end
`;
const tmp = path.join(os.tmpdir(), "mfc-deal-odds-" + process.pid + ".luau");
fs.writeFileSync(tmp, test);
let out = "";
try { out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8", maxBuffer: 1 << 26 }); } catch (e) {
  out = String(e.stdout || "") + String(e.stderr || "");
  console.log(out.split("\n").slice(-6).map((l) => "        " + l).join("\n"));
}
fs.unlinkSync(tmp);
out = out.replace(/\t/g, " ");
const lineOf = (k) => { const m = out.match(new RegExp("^" + k + " (.*)$", "m")); return m ? m[1] : ""; };
const within = (line) => {
  const [d, c] = line.split(" ").map(Number);
  return Number.isFinite(d) && Number.isFinite(c) && Math.abs(d - 1) <= 0.03 && Math.abs(c - 1) <= 0.03;
};
check(within(lineOf("POT")), "Pot of Gold's cases match the packs they replace within 3% (recycle value, list price)",
  "new/old dust, credits; new dust, old dust, new cr, old cr: " + lineOf("POT"));
check(within(lineOf("HAUL")), "the Weekend Haul's cases match its retired packs within 3% (recycle value, list price)",
  lineOf("HAUL"));
check(lineOf("PAID") === "true", "a deal's wild case is a paid case");
const sheets = [...out.matchAll(/^SHEET (\S+) (\d+) (.*)$/gm)].map((m) => ({ id: m[1], n: +m[2], verdict: m[3] }));
const nones = [...out.matchAll(/^NONE (\S+) (\S+)$/gm)].map((m) => ({ id: m[1], random: m[2] }));
const byId = (id) => sheets.find((s) => s.id === id);
check(sheets.length >= 5 && sheets.every((s) => s.verdict === "clean"),
  "every random deal's sheet sums to 1 per roll and matches the tables the rolls use",
  sheets.map((s) => `${s.id}:${s.n}:${s.verdict}`).join(" "));
check(byId("deal_lucky_week") && byId("deal_lucky_week").n === 8,
  "Lucky Block Week shows three blocks (grade and payout each) and its wild cases (stars and set)",
  byId("deal_lucky_week") && String(byId("deal_lucky_week").n));
check(byId("deal_pot_gold") && byId("deal_pot_gold").n === 3, "Pot of Gold shows its wild cases and its Shiny Packs' card odds",
  byId("deal_pot_gold") && String(byId("deal_pot_gold").n));
check(nones.length >= 1 && nones.every((x) => x.random === "false") && nones.some((x) => x.id === "rot_founders"),
  "a deal with nothing random (the Founders Bag) has no sheet", nones.map((x) => x.id).join(" "));

console.log(fail === 0 ? ">>> deal-odds OK" : `>>> ${fail} FAILED`);
process.exit(fail === 0 ? 0 : 1);
