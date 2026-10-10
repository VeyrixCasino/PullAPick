// Zone pet pots: 70 pets per zone, +5% per zone, each zone's top pets with
// their own buff set, and nothing about an existing pet's identity changed.
//
// Owner, 2026-10-10 (docs/PETS-AND-SETS.md): "make more like 70 per zone",
// "+5% per zone", "Mythic, Divine and Exotic pets get a different buff set in
// each zone", "lets not overuse the holiday ones".
//
// Checked against the generator's own build AND the real files:
//   1. the generated files are fresh (tools/gen/zone-pets.js --check)
//   2. every zone holds exactly its quota; every regular roster pet is in one
//   3. names, animals, (body, colour) and hex3 never collide with anything
//   4. kits: on the approved ladder x 1.05 per zone, no dead or banned stats,
//      Blast on <= 15% and never Common/Uncommon, top pets = the zone's buffs
//   5. the real MineZonePets module runs in luau and answers zoneOf / zoneMult
//   6. the roster, kit lookup and model factory read it, in the right order
//
//   node tools/verify/zone-pets.js
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = path.resolve(__dirname, "../..");
const Gen = require("../gen/zone-pets.js");
const Luau = require("./_luau");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8").replace(/\r\n/g, "\n");
const code = (s) => s.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");

let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

// 1. fresh
const B = Gen.build();
check(read(Gen.OUT_LUAU) === Gen.renderLuau(B), "MineZonePets.luau matches the generator (re-run tools/gen/zone-pets.js)");
check(read(Gen.OUT_MD) === Gen.renderMd(B), "docs/ZONE-PETS.md matches the generator");

// 2. quotas
const { pets, G } = B;
const perZone = {};
for (const p of pets) {
  perZone[p.zone] = perZone[p.zone] || {};
  perZone[p.zone][p.tier] = (perZone[p.zone][p.tier] || 0) + 1;
}
const quotaOk = Gen.ZONES.every((z) => Gen.TIERS.every((t) => (perZone[z.id] || {})[t] === Gen.QUOTA[t]));
const quotaTotal = Gen.TIERS.reduce((a, t) => a + Gen.QUOTA[t], 0);
check(quotaTotal === 70 && quotaOk, `every one of ${Gen.ZONES.length} zones holds ${quotaTotal} pets in its quota`);
const holidayNames = new Set(B.holiday.map((h) => h.name));
const regular = G.roster.filter((r) => !G.ehNames.has(r.name) && !holidayNames.has(r.name));
const existing = pets.filter((p) => !p.isNew);
check(regular.length > 200 && existing.length === regular.length && new Set(existing.map((p) => p.name)).size === regular.length,
  `all ${regular.length} regular roster pets are in exactly one zone`);

// Holiday pets are NOT in the game (owner, 2026-10-10: "make sure NO holiday
// ones are in the game.. only allow it from {Holiday} {year} Pack").
const HOLIDAY_BODIES = new Set(["pumpkin", "ghost", "spider", "skelehound", "reaper", "reindeer", "snowman", "gingerbread", "giftbox", ...Object.keys(G.seasons)]);
check(Object.keys(G.seasons).length >= 15, `every season-tagged body counts as a holiday body (${Object.keys(G.seasons).length})`);
const onHolidayBody = G.roster.filter((r) => !G.ehNames.has(r.name) && G.animals[r.animal] && HOLIDAY_BODIES.has(G.animals[r.animal].species));
check(B.holiday.length >= 6 && onHolidayBody.every((r) => holidayNames.has(r.name)),
  `every pet on a holiday body is a holiday pet (${B.holiday.map((h) => h.name).join(", ")})`);
check(pets.every((p) => !holidayNames.has(p.name)) && B.holiday.every((h) => B.kits[h.name]),
  "no holiday pet sits in a zone pot, and each keeps a kit so owned copies still pay");
const wheelSrc = code(read("src/ReplicatedStorage/Mine/Shared/MineGroupWheel.luau"));
const roller = wheelSrc.slice(wheelSrc.indexOf("function MineGroupWheel.rollPetOfTier"), wheelSrc.indexOf("function MineGroupWheel.resolvePetName"));
check(/pet\.holiday/.test(roller) && /not holiday/.test(roller) && /pet\.holiday = zp\.HOLIDAY/.test(code(read("src/ReplicatedStorage/Mine/Shared/MinePetRoster.luau"))),
  "the random pet roll (wheel and lucky blocks) skips holiday pets");
const sameTier = existing.every((p) => regular.find((r) => r.name === p.name).tier === p.tier);
check(sameTier, "no existing pet changed tier");

// 3. identity
const fresh = pets.filter((p) => p.isNew);
const allNames = [...G.roster.map((r) => r.name), ...G.ehNames, ...fresh.map((p) => p.name)];
check(new Set(allNames).size === new Set(G.roster.map((r) => r.name)).size + G.ehNames.size - [...G.ehNames].filter((n) => G.roster.some((r) => r.name === n)).length + fresh.length,
  `${fresh.length} new names, none reused`);
const key = (n) => n.toLowerCase().replace(/s$/, "");
const oldKeys = new Set([...G.roster.map((r) => key(r.name)), ...[...G.ehNames].map(key)]);
check(fresh.every((p) => !oldKeys.has(key(p.name))) && new Set(fresh.map((p) => key(p.name))).size === fresh.length,
  "no new name is a plural or case twin of another (Murmur / Murmurs)");
const animalsAll = [...Object.keys(G.animals), ...Object.keys(B.newAnimals)];
check(new Set(animalsAll).size === animalsAll.length && fresh.every((p) => !G.ehAnimals.has(p.animal)), "every new pet has its own animal");
const pairs = [...Object.values(G.animals), ...Object.values(B.newAnimals)].map((a) => a.species + "|" + a.rgb.join(","));
check(new Set(pairs).size === pairs.length, `no two skins share a body and a colour (${pairs.length} skins)`);
const HOLIDAY = new Set(["pumpkin", "ghost", "spider", "skelehound", "reaper", "reindeer", "snowman", "gingerbread", "giftbox", "matterbox", ...Object.keys(G.seasons)]);
check(fresh.every((p) => !HOLIDAY.has(p.species)), "no new zone pet uses a holiday or Event Horizon body");
const hexes = [...G.roster.map((r) => r.hex3), ...fresh.map((p) => p.hex3)];
check(new Set(hexes).size === hexes.length && hexes.every((h) => /^[0-9a-f]{3}$/.test(h)), "every hex3 serial prefix is unique");
const okPattern = Object.entries(B.newAnimals).every(([, s]) => !s.detail || s.detail.every((d) =>
  ({ stripes: ["horse", "bigcat"], spots: ["hound", "bigcat", "beetle"], bands: ["beetle"], scales: ["drake", "serpent", "lizard"] })[d].includes(s.species)));
check(okPattern, "patterns only on bodies that already wear them");

// 4. kits
const value = (kit) => Object.entries(kit).reduce((a, [s, v]) => a + v * 100 * G.stats[s].weight, 0);
let worst = 0;
for (const p of pets) {
  const zi = Gen.ZONES.findIndex((z) => z.id === p.zone);
  const want = 1.5 * Gen.LADDER[p.tier] * Math.pow(Gen.ZONE_STEP, zi);
  const got = value(B.kits[p.name]) * G.rarityMult[p.tier];
  worst = Math.max(worst, Math.abs(got / want - 1));
}
check(worst < 0.01, `every kit is worth 1.5 x the ladder x 1.05 per zone, at Normal PL1 (worst ${(worst * 100).toFixed(2)}%)`);
let ehWorst = 0;
const ehMult = Math.pow(Gen.ZONE_STEP, Gen.EVENT_ZONE.index - 1);
for (const p of B.ehPets) {
  const got = value(B.kits[p.name]) * G.rarityMult[p.tier];
  ehWorst = Math.max(ehWorst, Math.abs(got / (1.5 * Gen.LADDER[p.tier] * ehMult) - 1));
}
check(B.ehPets.length === 73 && ehWorst < 0.01,
  `Event Horizon's ${B.ehPets.length} sit on the ladder as zone ${Gen.EVENT_ZONE.index} (x${ehMult.toFixed(3)}, worst ${(ehWorst * 100).toFixed(2)}%)`);
const meadowC = value(B.kits[pets.find((p) => p.zone === "meadow" && p.tier === "Common").name]);
const primordC = value(B.kits[pets.find((p) => p.zone === "primordium" && p.tier === "Common").name]);
check(Math.abs(primordC / meadowC - Math.pow(1.05, 9)) < 0.01, `zone 10 is ${(primordC / meadowC).toFixed(3)}x zone 1 (1.05^9 = 1.551)`);
const statsUsed = new Set(Object.values(B.kits).flatMap((k) => Object.keys(k)));
check([...statsUsed].every((s) => !Gen.BANNED.has(s) && G.stats[s]), "no kit carries a retired, rune-only or unknown stat: " + [...statsUsed].sort().join(" "));
const blast = pets.filter((p) => B.kits[p.name].blastChance);
check(blast.length > 0 && blast.length <= 0.15 * pets.length && blast.every((p) => p.tier !== "Common" && p.tier !== "Uncommon"),
  `Blast on ${blast.length} of ${pets.length} pets, Rare or better only (cap 15%)`);
let topOk = true;
for (const z of Gen.ZONES) {
  const top = pets.filter((p) => p.zone === z.id && ["Mythic", "Divine", "Exotic"].includes(p.tier));
  const used = new Set(top.flatMap((p) => Object.keys(B.kits[p.name])));
  if (top.length !== 8 || used.size !== 3 || ![...used].every((s) => z.stats.includes(s))) topOk = false;
}
check(topOk, "each zone's 8 Mythic/Divine/Exotic pets use exactly that zone's three buffs");
// Owner, 2026-10-10: "make the rare pets with tidal wave (3 of them) only go up
// to around 50-60% proc chance", and every proc's odds stay "lowish (~tidal
// wave)" -- priced, never capped (MineStats weights).
const tideTop = pets.filter((p) => p.zone === "mistreef" && ["Mythic", "Divine", "Exotic"].includes(p.tier))
  .map((p) => (B.kits[p.name].tidalWave || 0) * G.rarityMult[p.tier]).sort((a, b) => b - a);
const trio = tideTop.slice(0, 3).reduce((a, b) => a + b, 0);
check(trio >= 0.5 && trio <= 0.6, `the three top Tidal Wave pets together reach ${(trio * 100).toFixed(1)}% at Normal (50-60%)`);
let wildest = ["", 0];
for (const p of pets.concat(B.ehPets)) {
  for (const st of ["blastChance", "tidalWave", "zap", "ricochet", "earthquake"]) {
    const c = (B.kits[p.name][st] || 0) * G.rarityMult[p.tier];
    if (c > wildest[1]) wildest = [p.name + " " + st, c];
  }
}
check(wildest[1] <= 0.4, `no single pet's proc chance tops 40% at Normal (highest: ${wildest[0]} ${(wildest[1] * 100).toFixed(1)}%)`);
const sets = new Set(Gen.ZONES.map((z) => z.stats.slice().sort().join("+")));
check(sets.size === Gen.ZONES.length, "no two zones share a buff set");

// 5. the real module, in luau
if (!Luau.ready) {
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(1);
}
const mod = read(Gen.OUT_LUAU);
const harness = `
Color3 = { fromRGB = function(r, g, b) return { r, g, b } end }
Enum = { Material = setmetatable({}, { __index = function(_, k) return k end }) }
local M = (function()
${mod}
end)()
local n, perZone = 0, {}
for name, zone in pairs(M.ZONE_OF) do n += 1 perZone[zone] = (perZone[zone] or 0) + 1 end
local ok = n == ${pets.length + B.ehPets.length} and perZone[M.EVENT_ZONE] == ${B.ehPets.length}
for _, z in ipairs(M.ZONE_ORDER) do if perZone[z] ~= 70 then ok = false end end
print(ok and "  ok    luau: ZONE_OF covers ${pets.length + B.ehPets.length} pets: 70 per zone, ${B.ehPets.length} in Event Horizon" or "  FAIL  luau: ZONE_OF counts " .. n)
local m10 = M.zoneMult("primordium")
print(math.abs(m10 - 1.05 ^ 9) < 1e-9 and M.zoneMult("meadow") == 1 and math.abs(M.zoneMult("bigbang") - 1.05 ^ 10) < 1e-9
	and M.zoneMult("nowhere") == 1
	and "  ok    luau: zoneMult meadow 1, primordium 1.05^9, bigbang 1.05^10, unknown 1" or "  FAIL  luau: zoneMult " .. tostring(m10))
local missingKit = 0
for name in pairs(M.ZONE_OF) do if not M.KITS[name] then missingKit += 1 end end
for animal, skin in pairs(M.ANIMALS) do if not skin.species or not skin.tint then missingKit += 1 end end
print(missingKit == 0 and "  ok    luau: every zone pet has a kit and every new skin a body and a tint" or "  FAIL  luau: " .. missingKit .. " missing")
`;
const script = path.join(ROOT, ".luau-bin/zone-pets-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(Luau.LUAU, [script], { encoding: "utf8" }); process.stdout.write(out); }
catch (e) { process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || ""); fail++; }
if (/FAIL/.test(out)) fail++;

// 6. wiring
const roster = code(read("src/ReplicatedStorage/Mine/Shared/MinePetRoster.luau"));
const merge = roster.indexOf('FindFirstChild("MineZonePets")');
check(merge > 0 && merge < roster.indexOf("MinePetRoster.BY_NAME = {}") && merge < roster.indexOf("MinePetRoster.HEX3_BY_NAME = {}"),
  "MinePetRoster merges the zone pets before it builds BY_NAME and HEX3_BY_NAME");
check(/BY_ZONE\[pet\.zone\]/.test(roster), "MinePetRoster indexes pets by zone (BY_ZONE)");
const boosts = code(read("src/ReplicatedStorage/Mine/Shared/MinePetBoosts.luau"));
const fn = boosts.slice(boosts.indexOf("function M.boostsFor"));
check(/PET_BOOSTS\.Z\[name\] = kit/.test(boosts) && /zp\.KITS/.test(boosts) && /return z and z\[name\]/.test(fn), "boostsFor answers from the one kit table (PET_BOOSTS.Z)");
const pmf = code(read("src/ReplicatedStorage/Mine/Shared/PetModelFactory.luau"));
check(/zp\.ANIMALS[\s\S]{0,200}PetModelFactory\.ANIMALS\[animal\] == nil/.test(pmf), "PetModelFactory adds the zone skins without overwriting any");

// 7. the old information stays gone (owner, 2026-10-10: "remove all old
//    information, because as long as we keep it there its gonna keep tripping
//    up agents"). Each of these was dead or contradicted the live data.
const SHARED = "src/ReplicatedStorage/Mine/Shared/";
const gone = [
  ["MinePetBoosts", /\b(X|Y|EH)\s*=\s*\{/, "the X / Y / second-EH kit bags"],
  ["MineEHPets", /\.(PET_BOOSTS|BUDGET|applyToPackConfig|boostsFor)\b/, "Event Horizon's stale kit copy, budget and X/Y injector"],
  ["MinePackConfig", /\b(SET_CARDS|SET_SPLIT|SET_SHAPE|SET_OF|CARD_BY_NAME|SET_PROFILE|PET_BUDGET|VARIANT_ODDS|setBias|NEW_CARD_BIAS|openChest|rollVariant)\b/, "the X/Y sets, old pet budgets and per-pack variant odds"],
  ["MineStats", /\b(TIER_BUDGET|SET_PROFILE|kitFor|TYPE_KITS|NEUTRAL_STATS)\b/, "the old X/Y kit generator"],
  ["Mine1PacksData", /\bvariants\s*=\s*\{/, "per-pack Golden/Prism/Rainbow/Void rows"],
  ["MineZoneMapView", /PET_BOOSTS\.X|bag\.X/, "the zone map reading the old X kits"],
];
for (const [mod, re, what] of gone) {
  const text = code(read(SHARED + mod + ".luau"));
  const m = text.match(re);
  check(!m, `${mod}: ${what} stay removed${m ? " (found " + m[0] + ")" : ""}`);
}

console.log("");
console.log(fail > 0 ? `>>> zone-pets: ${fail} FAILED` : ">>> zone-pets: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
