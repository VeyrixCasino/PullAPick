// THE BATTLE PASS (the owner's rework, 2026-10-16).
//
//   "about 2 weeks no daily xp cap"
//   "100 teirs, every 5 should be decent, every 10 should be good and every 25 is huge"
//   premium: "Exclusive pets, skins and books"; free: "Something every tier, smaller"
//   4 season pets on the huge tiers (25 Legendary .. 100 Exotic), made here;
//   4 season skins at 20 / 40 / 60 / 80, S to SSS.
//
// Runs the REAL MineScrolls.buildPassTrack in Luau, with the generated pass
// pets (HolidayPets/Pass202610) and MineSkins wired in, then checks every tier.
//
//   node tools/verify/battle-pass.js
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");

const ROOT = path.resolve(__dirname, "../..");
const SH = "src/ReplicatedStorage/Mine/Shared/";
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8").replace(/\r\n/g, "\n");
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

if (!Luau.ready) { console.log(Luau.missing("luau") + "; skipping"); process.exit(1); }

// The grade words players read (S is Mythic), lifted from the real MineTemper.
const WORDS = (read(SH + "MineTemper.luau").match(/MineTemper\.WORD_OF = \{[\s\S]*?\n\}/) || ["MineTemper.WORD_OF = {}"])[0]
  .replace("MineTemper.WORD_OF", "local WORD_OF");
const harness = `
Color3 = { fromRGB = function(r, g, b) return { r, g, b } end }
${WORDS}
local TEMPER = { wordOf = function(g) return WORD_OF[g] end }
local SKINS = (function()
${read(SH + "MineSkins.luau")}
end)()
local PASSPETS = (function()
${read(SH + "HolidayPets/Pass202610.luau")}
end)()
local passMod = { Name = "Pass202610", IsA = function(_, c) return c == "ModuleScript" end }
local folder = { GetChildren = function() return { passMod } end }
local parent = {
	WaitForChild = function(_, name) return { __name = name } end,
	FindFirstChild = function(_, name) if name == "HolidayPets" then return folder end return nil end,
}
local script = { Parent = parent }
local function require(m)
	if m == passMod then return PASSPETS end
	local n = type(m) == "table" and m.__name
	if n == "MineLaunch" then return { seasonNow = function() return 0 end } end
	if n == "MineSkins" then return SKINS end
	if n == "MineTemper" then return TEMPER end
	if n == "MineIcons" then return { IMAGES = {} } end
	error("unexpected require " .. tostring(n))
end
local S = (function()
${read(SH + "MineScrolls.luau")}
end)()
local function kinds(r)
	if type(r) ~= "table" then return "nil" end
	local t = {}
	for _, k in ipairs({ "toolId", "pet", "skin", "books", "gems", "dust", "credits" }) do
		if r[k] ~= nil then table.insert(t, k .. "=" .. tostring(r[k])) end
	end
	if r.pet then table.insert(t, "animal=" .. tostring(r.petAnimal) .. ":" .. tostring(r.petSpecies)) end
	if r.luckyBlocks then
		for _, b in ipairs(r.luckyBlocks) do table.insert(t, "lb=" .. b.id .. ":" .. b.startGrade) end
	end
	return table.concat(t, ",")
end
for n = 1, S.PASS_TIERS do
	local row = S.PASS_TRACK[n]
	print(string.format("T|%d|%s|%s|%s", n, row.class, kinds(row.free), kinds(row.premium)))
end
print("XP|" .. tostring(S.PASS_XP_PER_TIER) .. "|" .. tostring(S.PASS_DAILY_XP) .. "|" .. tostring(S.passXpFor and S.passXpFor(100)))
print("DESC|" .. S.describeReward(S.PASS_TRACK[25].premium) .. "|" .. S.describeReward(S.PASS_TRACK[80].premium))
for _, p in ipairs(PASSPETS.PETS) do print("PET|" .. p.name .. "|" .. p.tier .. "|" .. tostring(p.holiday)) end
print("PACK|" .. tostring(PASSPETS.KEY) .. "|" .. tostring(PASSPETS.PACK_ID))
for _, id in ipairs({ "gemfire", "geode_heart", "deepgold_seam", "the_motherlode" }) do
	local s = SKINS.byId(id)
	print("SKIN|" .. id .. "|" .. tostring(s and s.tier) .. "|" .. tostring(SKINS.isPass(id)))
end
-- DAY 29 (owner, 2026-10-19): a new pass will ship; if it is late, the old one pauses.
-- In a pcall, so a build without it fails these lines and nothing above.
local okD29, errD29 = pcall(function()
local END = S.PASS_SEASON_END
local function played()
	return { xp = 5000, owned = true, free = { [3] = true }, prem = { [3] = true }, day = "d", dayXp = 1, season = S.PASS_SEASON_ID }
end
print("D29PRE|" .. tostring(S.passPaused(END - 1)) .. "|" .. tostring(S.trackFor(played()) == S.PASS_TRACK)
	.. "|" .. S.passSecondsLeft(END - 10) .. "|" .. tostring(S.NEXT_TRACK))
local paused = S.reconcilePass(played(), END + 5)
print("D29PAUSE|" .. tostring(S.passPaused(END)) .. "|" .. tostring(S.passPaused(END + 86400 * 400)) .. "|" .. paused.xp
	.. "|" .. tostring(paused.owned) .. "|" .. tostring(paused.free[3]) .. "|" .. tostring(paused.prem[3]) .. "|" .. paused.season
	.. "|" .. S.passSecondsLeft(END + 5) .. "|" .. S.formatPassTimer(END + 5) .. "|" .. S.formatPassClock(END + 5))
S.NEXT_TRACK = { { tier = 1, class = "small", free = { gems = 1 }, premium = { gems = 2 } } }
local rolled = S.reconcilePass(played(), END + 5)
print("D29NEXT|" .. tostring(S.passPaused(END + 5)) .. "|" .. rolled.xp .. "|" .. tostring(rolled.owned)
	.. "|" .. tostring(next(rolled.free) == nil and next(rolled.prem) == nil) .. "|" .. rolled.season
	.. "|" .. tostring(S.trackFor(rolled) == S.NEXT_TRACK) .. "|" .. ((S.activeEnd(END + 5) - END) / 86400)
	.. "|" .. S.passSecondsLeft(END + 5))
rolled.xp = 300
rolled.free[1] = true
S.reconcilePass(rolled, END + 10)
print("D29ONCE|" .. rolled.xp .. "|" .. tostring(rolled.free[1]))
print("D29AGAIN|" .. tostring(S.passPaused(S.activeEnd(END + 5) + 1)))
S.NEXT_TRACK = nil
end)
if not okD29 then print("D29ERR|" .. tostring(errD29)) end
`;
const script = path.join(ROOT, ".luau-bin/battle-pass-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(Luau.LUAU, [script], { encoding: "utf8" }); }
catch (e) { process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || ""); fail++; }
const lines = out.split(/\r?\n/);
const tiers = lines.filter((l) => l.startsWith("T|")).map((l) => {
  const [, n, cls, free, prem] = l.split("|");
  return { n: +n, cls, free, prem };
});
const get = (tag) => (lines.find((l) => l.startsWith(tag + "|")) || "").split("|").slice(1);

check(tiers.length === 100, `100 tiers (${tiers.length})`);
const wantClass = (n) => (n % 25 === 0 ? "huge" : n % 10 === 0 ? "good" : n % 5 === 0 ? "decent" : "small");
check(tiers.every((t) => t.cls === wantClass(t.n)), "every 5th tier is decent, every 10th good, every 25th huge (owner)");
check(tiers.every((t) => t.free !== "nil" && t.free !== "" && t.prem !== "nil" && t.prem !== ""),
  "both tracks pay something on EVERY tier (owner: free pays \"something every tier, smaller\")");
check(tiers[0].free.includes("toolId=lunar_pick") && tiers[0].prem.includes("toolId=bp_eclipse"), "tier 1 keeps the signature tools");

// The season pets on the huge tiers.
const pets = lines.filter((l) => l.startsWith("PET|")).map((l) => l.split("|").slice(1));
const petAt = { 25: "Legendary", 50: "Mythic", 75: "Divine", 100: "Exotic" };
const petOk = Object.entries(petAt).every(([n, tier]) => {
  const pet = pets.find((p) => p[1] === tier);
  return pet && tiers[+n - 1].prem.includes("pet=" + pet[0]);
});
check(pets.length === 4 && petOk, "the premium huge tiers pay the 4 season pets: 25 Legendary, 50 Mythic, 75 Divine, 100 Exotic (owner)");
check(pets.every((p) => p[2] === "pass"), "...stamped holiday = \"pass\", so no pot, pack, wheel or case ever rolls one");
const pack = get("PACK");
check(pack[0] === "pass_2026_10" && pack[1] === "nil", "...and no pack sells them (the pass pack has no PACK_ID)");

// The season skins.
const skins = lines.filter((l) => l.startsWith("SKIN|")).map((l) => l.split("|").slice(1));
const skinAt = { 20: "gemfire", 40: "geode_heart", 60: "deepgold_seam", 80: "the_motherlode" };
check(Object.entries(skinAt).every(([n, id]) => tiers[+n - 1].prem.includes("skin=" + id)), "the premium 20 / 40 / 60 / 80 pay the 4 season skins (owner: \"4 skins\")");
check(skins.map((s) => s[1]).join(",") === "S,SS,SS,SSS" && skins.every((s) => s[2] === "true"),
  "...graded S, SS, SS, SSS, all from MineSkins' pass set (no case drops them)");
check([10, 30, 70, 90].every((n) => tiers[n - 1].prem.includes("lb=godly_lucky_block")), "the other premium 10s pay a Godly block and books");
check(tiers.filter((t) => t.cls === "decent").every((t) => t.free.includes("books=2") && t.prem.includes("books=3")),
  "every decent tier pays books on both tracks (2 free, 3 premium)");

// Pace.
const xp = get("XP");
check(+xp[0] === 90 && xp[1] === "nil" && +xp[2] >= 8500 && +xp[2] <= 9500,
  `about two weeks, no daily cap: ${xp[0]} XP a tier, ${xp[2]} for the season, PASS_DAILY_XP gone (owner: "about 2 weeks no daily xp cap")`);
const desc = get("DESC");
check(/ pet\)/.test(desc[0]) && / skin \(Exotic\)/.test(desc[1]), `the rail names the pet and the skin, by grade WORD not letter ("${desc[0]}" | "${desc[1]}")`);
check([25, 50, 75, 100].every((n) => /animal=(?!nil)[\w ]+:(?!nil)\w/.test(tiers[n - 1].prem)), "...and each pet tile knows its animal and body, so the rail draws the real pet");

// The server.
const sv = read("src/ServerScriptService/Mine/MineServer.server.luau");
const award = (sv.match(/local function awardPassXp[\s\S]*?\nend\n/) || [""])[0];
check(!/PASS_DAILY_XP|dayXp\s*>=|dayXp\s*>/.test(award), "awardPassXp never caps a day");
check(/function Dig\.grantPassExtras\(p, plr, reward\)/.test(sv) && /mint\(\{\s*\n\s*setId = Scrolls\.PASS_PET_PACK/.test(sv)
  && /p\.skins\[def\.id\] = true/.test(sv), "the server mints the season pet and grants the season skin");
check(/if profile == p then\s*\n\s*Dig\.grantPassExtras\(p, livePlr, reward\)/.test(sv) && (sv.match(/(?<!function )Dig\.grantPassExtras\(p, /g) || []).length === 2,
  "...on the live profile only, so a claim that also writes the stored save never mints a pet twice");

// The rail.
const inv = read(SH + "MineInventoryView.luau");
check(/Scrolls\.tierClass\(n\)/.test(inv) && /"★ HUGE"/.test(inv) && /"★ BIG"/.test(inv), "the rail marks decent, good and huge tiers so the big ones show from afar");
check(/reward\.pet and reward\.petAnimal and opts\.petViewport/.test(inv) && /reward\.skinWord/.test(inv),
  "...a pet tile draws the pet, a skin tile its grade word");
const tileH = +((inv.match(/local TILE_W, TILE_H = 118, (\d+)/) || [])[1] || 0);
check(tileH >= 172 && /UDim2\.fromOffset\(6, TILE_W - 6\), UDim2\.fromOffset\(TILE_W - 12, 30\)/.test(inv),
  `...and the caption (rows TILE_W - 6 to TILE_W + 24) ends above the status strip (TILE_H - 28; TILE_H ${tileH})`);
const icons = read(SH + "MineIcons.luau");
check(/\bbooks = "enchanter"/.test(icons), "book rewards draw the Enchanter's book art, not a \"BK\" placeholder");

// DAY 29 (owner, 2026-10-19): "a new pass will be ready; if it's late, the old one pauses".
const pre = get("D29PRE");
check(pre[0] === "false" && pre[1] === "true" && +pre[2] === 10 && pre[3] === "nil",
  "before the end nothing is paused, the pass pays out of PASS_TRACK, and no next track ships today");
const ps = get("D29PAUSE");
check(ps[0] === "true" && ps[1] === "true", "past the end with no next track the pass is paused, and stays paused");
check(+ps[2] === 5000 && ps[3] === "true" && ps[4] === "true" && ps[5] === "true" && ps[6] === "2026-10",
  "...and pausing keeps XP, claims and premium exactly as they were (no re-earning the season pets and skins)");
check(+ps[7] === 0 && ps[8] === "Next pass coming soon", `...the clock reads "${ps[9]}" / "${ps[8]}"`);
const nx = get("D29NEXT");
check(nx[0] === "false" && +nx[1] === 0 && nx[2] === "false" && nx[3] === "true" && nx[4] === "2026-11",
  "shipping MineScrolls.NEXT_TRACK un-pauses and rolls each pass over once: XP, claims and premium start clean");
check(nx[5] === "true", "...the claims pay out of the next track");
check(+nx[6] === 28 && +nx[7] === 28 * 86400 - 5, `...and the countdown runs to the next pass's own end (${nx[6]} days)`);
const once = get("D29ONCE");
check(+once[0] === 300 && once[1] === "true", "...once only: progress in the new pass survives the next reconcile");
check(get("D29AGAIN")[0] === "true", "...and when that pass ends with nothing further shipped, it pauses again");
const svc = sv.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
const awardC = (svc.match(/local function awardPassXp[\s\S]*?\nend\n/) || [""])[0];
check(/if Scrolls\.passPaused\(\) then\s*\n\s*return\s*\n\s*end/.test(awardC), "the server gives no pass XP while paused");
const claimC = (svc.match(/function Verbs\.claimPass\(plr, payload\)[\s\S]*?\nend\n/) || [""])[0];
check(/if Scrolls\.passPaused\(\) then[\s\S]{0,140}return/.test(claimC) && /Scrolls\.trackFor\(pass\)\[tier\]/.test(claimC) && !/Scrolls\.PASS_TRACK\[/.test(claimC),
  "...takes no claims while paused, and claims from the player's own track");
check(/local claimToken = lockKey\s*\n\s*if old\.pass\.season and old\.pass\.season ~= Scrolls\.PASS_SEASON_ID then\s*\n\s*claimToken = lockKey \.\. "@"/.test(claimC),
  "...and the claim ledger is per season after the first, so a rollover cannot refuse a new tier as \"already claimed\"");
const buyC = (svc.match(/local function buyBattlePassCredits\(plr\)[\s\S]*?\nend\n/) || [""])[0];
check(/if Scrolls\.passPaused\(\) then[\s\S]{0,140}return/.test(buyC) && buyC.indexOf("passPaused") < buyC.indexOf("p.credits -= cost"),
  "...sells no premium for credits while paused");
check(/info\.ProductId == bp\.productId then[\s\S]{0,200}if Scrolls\.passPaused\(\) then[\s\S]{0,300}p\.credits = \(p\.credits or 0\) \+ face[\s\S]{0,200}PurchaseGranted/.test(svc),
  "...and a Robux receipt that lands while paused becomes its face value in credits, never a pass that does not exist");
check(/paused = Scrolls\.passPaused\(\),/.test(svc), "...and the snapshot says so");
const invC = inv.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
check(!/Next season is live/.test(invC) && /endLbl\.Text = "Next pass coming soon"/.test(invC), "the panel says \"Next pass coming soon\", never \"Next season is live\"");
check(/local allowed = reached and not claimed and \(\(not isPrem\) or owned\) and not paused/.test(invC)
  && /if not owned and paused then[\s\S]{0,300}elseif not owned then/.test(invC) && /Scrolls\.trackFor\(pass\)/.test(invC),
  "...offers no CLAIM and no premium while paused, and draws the player's own track");
const notifs = read(SH + "MineNotifs.luau");
const today = read(SH + "MineToday.luau");
check(/type\(pass\) == "table" and not pass\.paused/.test(notifs) && /p\.paused then\s*\n[^\n]*\n\s*put\("pass", "next pass soon"\)/.test(today),
  "...and no badge or TODAY row counts a paused pass's rewards as claimable");

console.log("");
console.log(fail > 0 ? `>>> battle-pass: ${fail} FAILED` : ">>> battle-pass: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
