// Holiday pets: the Halloween 2026 Pack's 60 pets (owner, 2026-10-10).
//
//   1. the generated files are fresh (tools/gen/holiday-pets.js --check)
//   2. the owner's counts: costumes C20/U15/R10, Halloween bodies E6/L4/M2/D2/X1
//   3. names, looks, (body, colour) and serials never collide with anything
//   4. specials wear a Halloween body; costume pets an everyday body + costume
//   5. kits: the ladder at Event Horizon's level; procs fit; odds sane
//   6. the holiday rule: every pet stamped, only the holiday pack may pay one
//   7. the module runs in luau, and the pack is wired end to end
//
//   node tools/verify/holiday-pets.js
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = path.resolve(__dirname, "../..");
const Gen = require("../gen/holiday-pets.js");
const SetGen = require("../gen/set-pets.js");
const Zone = require("../gen/zone-pets.js");
const Luau = require("./_luau");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8").replace(/\r\n/g, "\n");
const code = (s) => s.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");

let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

const B = Gen.build();
const R = B.R;
const H = B.packs.find((x) => x.meta.key === "halloween_2026");

// 1. fresh
const stale = Gen.outputs(B).filter(([rel, text]) => !fs.existsSync(path.join(ROOT, rel)) || read(rel) !== text);
check(stale.length === 0, "HolidayPets modules and docs/HOLIDAY-PETS.md match the generator" + (stale.length ? " (stale: " + stale.map((s) => s[0]).join(", ") + ")" : ""));

// 2. counts
const want = { Common: 20, Uncommon: 15, Rare: 10, Epic: 6, Legendary: 4, Mythic: 2, Divine: 2, Exotic: 1 };
const got = {};
for (const p of H.pets) got[p.tier] = (got[p.tier] || 0) + 1;
check(H && H.pets.length === 60 && Object.entries(want).every(([t, n]) => got[t] === n),
  "60 Halloween pets: Common 20, Uncommon 15, Rare 10 (costumes); Epic 6, Legendary 4, Mythic 2, Divine 2, Exotic 1");

// 3. identity, against every pet in the game
const Z = Zone.build();
const S = SetGen.build();
// (A zone pot lists roster pets too, so the other names go through a Set.)
const others = new Set([...Z.G.roster.map((r) => r.name), ...Z.G.ehNames, ...Z.pets.map((p) => p.name), ...S.sets.flatMap((s) => s.pets.map((p) => p.name))]);
const mine = B.packs.flatMap((x) => x.pets.map((p) => p.name));
check(new Set(mine).size === mine.length && mine.every((n) => !others.has(n)), "every holiday pet's name is new");
const nk = (n) => n.toLowerCase().replace(/s$/, "");
const otherKeys = new Set([...others].map(nk));
const mineKeys = mine.map(nk);
check(new Set(mineKeys).size === mineKeys.length && mineKeys.every((k) => !otherKeys.has(k)), "no holiday name is a plural or case twin of any name in the game");
check(mine.every((n) => n.length <= 16 && n.split(" ").length <= 2), "names are 1-2 words, at most 16 characters");
const skins = [...Object.values(Z.G.animals), ...Object.values(Z.newAnimals), ...S.sets.flatMap((s) => Object.values(s.animals)), ...B.packs.flatMap((x) => Object.values(x.animals))];
const pairs = skins.map((a) => a.species + "|" + a.rgb.join(",") + "|" + (a.detail || []).join(","));
check(new Set(pairs).size === pairs.length, `no two skins share a body, a colour and a costume (${pairs.length} skins)`);
const animalNames = B.packs.flatMap((x) => Object.keys(x.animals));
const takenAnimals = new Set([...Object.keys(Z.G.animals), ...Object.keys(Z.newAnimals), ...Z.G.ehAnimals, ...S.sets.flatMap((s) => Object.keys(s.animals))]);
check(new Set(animalNames).size === animalNames.length && animalNames.every((a) => !takenAnimals.has(a)), "every holiday pet has its own look");
const hexes = B.packs.flatMap((x) => x.pets.map((p) => parseInt(p.hex3, 16)));
check(new Set(hexes).size === hexes.length && hexes.every((h) => h >= Gen.HEX_START && h <= Gen.HEX_END), "serial prefixes are unique and in their own range (0xC00-0xCFF)");

// 4. bodies and costumes
const pmfSrc = read("src/ReplicatedStorage/Mine/Shared/PetModelFactory.luau");
const season = {};
for (const m of pmfSrc.matchAll(/\nS\.(\w+) = \{\n\tlabel = "([^"]+)",\n(\tseason = "(\w+)",\n)?/g)) season[m[1]] = m[4] || null;
const costumeIds = new Set([...pmfSrc.matchAll(/\nD\.(cos_\w+) = function/g)].map((m) => m[1]));
const specials = H.pets.filter((p) => !H.animals[p.animal].detail);
const costumed = H.pets.filter((p) => H.animals[p.animal].detail);
check(specials.length === 15 && specials.every((p) => season[p.species] === "Halloween") && new Set(specials.map((p) => p.species)).size === 15,
  "the 15 specials wear the 15 Halloween bodies, one each");
check(costumed.length === 45 && costumed.every((p) => !season[p.species] && H.animals[p.animal].detail.every((d) => costumeIds.has(d))) &&
  costumed.every((p) => ["Common", "Uncommon", "Rare"].includes(p.tier)) && specials.every((p) => !["Common", "Uncommon", "Rare"].includes(p.tier)),
  "the 45 costume pets are everyday bodies in a cos_* costume, and only they are Common to Rare");

// 5. kits
const value = (kit) => Object.entries(kit).reduce((a, [s, v]) => a + v * 100 * R.G.stats[s].weight, 0);
let worst = 0, wild = ["", 0], offTheme = 0;
const family = SetGen.setProcFamily(H.meta.buffs);
for (const p of H.pets) {
  const wantV = 1.5 * Zone.LADDER[p.tier] * H.mult;
  worst = Math.max(worst, Math.abs(value(H.kits[p.name]) * R.G.rarityMult[p.tier] / wantV - 1));
  for (const st of Object.keys(H.kits[p.name])) {
    const pf = SetGen.PROC_OF[st];
    if (pf && pf[0] !== family) offTheme++;
    if (pf && pf[1] === "chance") {
      const c = H.kits[p.name][st] * R.G.rarityMult[p.tier];
      if (c > wild[1]) wild = [`${p.name} ${st}`, c];
    }
  }
}
check(Math.abs(H.mult - Math.pow(Zone.ZONE_STEP, 10)) < 1e-9, `power is Event Horizon's (zone 11): x${H.mult.toFixed(2)}`);
check(worst < 0.01, `every kit is worth 1.5 x the ladder at that power (worst ${(worst * 100).toFixed(2)}%)`);
check(offTheme === 0, "every proc is the pack's own (" + family + ")");
check(wild[1] <= 0.6, `proc odds stay lowish: highest ${(wild[1] * 100).toFixed(1)}% (${wild[0]}), at most 60%`);
check(H.pets.filter((p) => ["Mythic", "Divine", "Exotic"].includes(p.tier)).every((p) => Object.keys(H.kits[p.name]).every((s) => H.meta.buffs.includes(s))),
  "Mythic, Divine and Exotic use exactly the pack's buff set");

// 6. the holiday rule
check(H.pets.every((p) => p.holiday === "halloween"), "every pet is stamped holiday = halloween");
const zp = read("src/ReplicatedStorage/Mine/Shared/MineZonePets.luau");
check(H.meta.legacy.every((n) => new RegExp(`\\["${n}"\\] = "halloween"`).test(zp)), "the older Halloween pets the pack also pays are on the holiday list");

// 7. luau load, and the wiring
if (!Luau.ready) { console.log(Luau.missing("luau") + "; skipping"); process.exit(1); }
const mod = read(Gen.OUT_DIR + Gen.pascal(H.meta.key) + ".luau");
const harness = `
Color3 = { fromRGB = function(r, g, b) return { r, g, b } end }
local m = (function()
${mod}
end)()
local n, k, hol = #m.PETS, 0, 0
for _ in pairs(m.KITS) do k += 1 end
for _, row in ipairs(m.PETS) do if row.holiday == m.HOLIDAY then hol += 1 end end
print((n == 60 and k == 60 and hol == 60 and m.PACK_ID == "halloween_2026") and "  ok    luau: the module loads, 60 pets, a kit each, all holiday" or ("  FAIL  luau: pets " .. n .. " kits " .. k .. " holiday " .. hol))
`;
const script = path.join(ROOT, ".luau-bin/holiday-pets-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(Luau.LUAU, [script], { encoding: "utf8" }); process.stdout.write(out); }
catch (e) { process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || ""); fail++; }
if (/FAIL/.test(out)) fail++;

const SH = "src/ReplicatedStorage/Mine/Shared/";
const sets = code(read(SH + "MineSetPets.luau"));
check(/FindFirstChild\("HolidayPets"\)/.test(sets) && /HOLIDAY_SETS/.test(sets) && /LEGACY_SET/.test(sets), "MineSetPets gathers HolidayPets/ apart from the 19 sets");
const roster = code(read(SH + "MinePetRoster.luau"));
check(/holiday = row\.holiday/.test(roster) && /LEGACY_SET/.test(roster), "the roster keeps the holiday stamp and files the older Halloween pets under the pack");
const packs = code(read(SH + "MineSetPacks.luau"));
check(/kind = "holiday"/.test(packs) && /allowHoliday or not pet\.holiday/.test(packs), "the holiday pack is kind \"holiday\", and pickPet skips holiday pets unless told otherwise");
const cfg = code(read(SH + "MinePackConfig.luau"));
check(/SetPacks\.HOLIDAY_PACKS/.test(cfg), "MinePackConfig registers the holiday pack");
const server = code(read("src/ServerScriptService/Mine/MineServer.server.luau"));
const calls = [...server.matchAll(/SetPacks\.pickPet\(([^\n]*)\)/g)].map((m) => m[1]);
check(calls.filter((c) => /holiday/.test(c)).length === 1 && calls.length >= 2,
  "openPack lets only a holiday pack pay holiday pets; every other pickPet call skips them");
const tot = read(SH + "MineTrickOrTreat.luau");
check(new RegExp(`PACK_ID = "${H.meta.packId}"`).test(tot), "the Trick-or-Treat case asks for this pack's id");

console.log("");
console.log(fail > 0 ? `>>> holiday-pets: ${fail} FAILED` : ">>> holiday-pets: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
