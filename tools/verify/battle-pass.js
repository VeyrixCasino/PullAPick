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

const harness = `
Color3 = { fromRGB = function(r, g, b) return { r, g, b } end }
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
check(/ pet\)/.test(desc[0]) && / skin \(SSS\)/.test(desc[1]), `the rail names the pet and the skin ("${desc[0]}" | "${desc[1]}")`);

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

console.log("");
console.log(fail > 0 ? `>>> battle-pass: ${fail} FAILED` : ">>> battle-pass: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
