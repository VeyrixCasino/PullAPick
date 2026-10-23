// Holiday pets: the Halloween 2026 Pack's 60 pets (owner, 2026-10-10) and the
// 12 more on new bodies (owner, 2026-10-19).
//
//   1. the generated files are fresh (tools/gen/holiday-pets.js --check)
//   2. the owner's counts: costumes C20/U15/R10, Halloween bodies E6/L4/M2/D2/X1,
//      and 12 more (PROPOSED E4/L3/M2/D2/X1)
//   3. names, looks, (body, colour) and serials never collide with anything
//   4. specials wear a Halloween body; costume pets an everyday body + costume;
//      the 12 a body of their own, or a Halloween fallback until it is built
//   5. kits: the ladder at Event Horizon's level below Mythic, the 20% rule
//      (topBeat) at Mythic+; procs fit; odds sane
//   6. the holiday rule: every pet stamped, only the holiday pack may pay one
//   7. the module runs in luau, and the pack is wired end to end
//   (The 20% rule against the game's own boostScore, the builds and
//   MineHalloweenPets are tools/verify/halloween-power.js.)
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

// 2. counts. The 60 (owner, 2026-10-10), then the 12 on new bodies (owner,
// 2026-10-19: "12 more"; their split is PROPOSED).
const own = H.pets.filter((p) => !p.extra);
const extras = H.pets.filter((p) => p.extra);
const tally = (list) => list.reduce((a, p) => ((a[p.tier] = (a[p.tier] || 0) + 1), a), {});
const want = { Common: 20, Uncommon: 15, Rare: 10, Epic: 6, Legendary: 4, Mythic: 2, Divine: 2, Exotic: 1 };
const got = tally(own);
check(H && own.length === 60 && Object.entries(want).every(([t, n]) => got[t] === n),
  "60 Halloween pets: Common 20, Uncommon 15, Rare 10 (costumes); Epic 6, Legendary 4, Mythic 2, Divine 2, Exotic 1");
const wantX = { Epic: 4, Legendary: 3, Mythic: 2, Divine: 2, Exotic: 1 };
const gotX = tally(extras);
check(extras.length === 12 && H.pets.length === 72 && Object.entries(wantX).every(([t, n]) => gotX[t] === n) &&
  H.pets.slice(60).every((p) => p.extra),
  "12 more after them (72 in all): Epic 4, Legendary 3, Mythic 2, Divine 2, Exotic 1");

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
// A pet on a body still to be built wears its fallback: it must not look like
// any pet already on that body either.
const worn = skins.map((a) => (a.fallback || a.species) + "|" + a.rgb.join(",") + "|" + (a.detail || []).join(","));
check(new Set(worn).size === worn.length, "no two skins look alike as worn today (a planned body counted as its fallback)");
const animalNames = B.packs.flatMap((x) => Object.keys(x.animals));
const takenAnimals = new Set([...Object.keys(Z.G.animals), ...Object.keys(Z.newAnimals), ...Z.G.ehAnimals, ...S.sets.flatMap((s) => Object.keys(s.animals))]);
check(new Set(animalNames).size === animalNames.length && animalNames.every((a) => !takenAnimals.has(a)), "every holiday pet has its own look");
const hexes = B.packs.flatMap((x) => x.pets.map((p) => parseInt(p.hex3, 16)));
check(new Set(hexes).size === hexes.length && hexes.every((h) => h >= Gen.HEX_START && h <= Gen.HEX_END), "serial prefixes are unique and in their own range (0xC00-0xCFF)");

// 4. bodies and costumes. Season tags come from the factory and from any
// PetBodies module (where the 12 new bodies will live), as the generator reads them.
const pmfSrc = read("src/ReplicatedStorage/Mine/Shared/PetModelFactory.luau");
const season = {};
for (const [id, s] of Object.entries(R.species)) season[id] = s.season;
const costumeIds = new Set([...pmfSrc.matchAll(/\nD\.(cos_\w+) = function/g)].map((m) => m[1]));
const specials = own.filter((p) => !H.animals[p.animal].detail);
const costumed = own.filter((p) => H.animals[p.animal].detail);
check(specials.length === 15 && specials.every((p) => season[p.species] === "Halloween") && new Set(specials.map((p) => p.species)).size === 15,
  "the 15 specials wear the 15 Halloween bodies, one each");
check(costumed.length === 45 && costumed.every((p) => !season[p.species] && H.animals[p.animal].detail.every((d) => costumeIds.has(d))) &&
  costumed.every((p) => ["Common", "Uncommon", "Rare"].includes(p.tier)) && specials.every((p) => !["Common", "Uncommon", "Rare"].includes(p.tier)),
  "the 45 costume pets are everyday bodies in a cos_* costume, and only they are Common to Rare");
const usedBodies = new Set(H.pets.filter((p) => !p.extra).map((p) => p.species));
check(new Set(extras.map((p) => p.species)).size === 12 && extras.every((p) => !usedBodies.has(p.species)) &&
  extras.every((p) => ["Epic", "Legendary", "Mythic", "Divine", "Exotic"].includes(p.tier)) &&
  extras.every((p) => !H.animals[p.animal].detail),
  "the 12 each wear a body of their own, no other pet's, and are Epic or better");
check(extras.every((p) => (R.species[p.species] ? season[p.species] === "Halloween" && !H.animals[p.animal].fallback
  : season[H.animals[p.animal].fallback] === "Halloween")),
  `a built body is a Halloween body; until then each wears a Halloween fallback (${extras.filter((p) => !R.species[p.species]).length} of 12 still to build)`);

// 5. kits: the ladder below Mythic; at Mythic+ the 20% rule, topBeat x the
// best normal pet's score. (halloween-power.js checks the same rule on the
// game's own MineCards.boostScore.)
const value = (kit) => Object.entries(kit).reduce((a, [s, v]) => a + v * 100 * R.G.stats[s].weight, 0);
const TOPT = new Set(["Mythic", "Divine", "Exotic"]);
let worst = 0, wild = ["", 0], offTheme = 0, twoFamilies = 0;
const family = SetGen.setProcFamily(H.meta.buffs);
for (const p of H.pets) {
  const wantV = TOPT.has(p.tier) ? H.meta.topBeat[p.tier] * B.best.score : 1.5 * Zone.LADDER[p.tier] * H.mult;
  worst = Math.max(worst, Math.abs(value(H.kits[p.name]) * R.G.rarityMult[p.tier] / wantV - 1));
  const fams = new Set();
  for (const st of Object.keys(H.kits[p.name])) {
    const pf = SetGen.PROC_OF[st];
    if (pf) fams.add(pf[0]);
    if (pf && pf[0] !== family && !p.extra) offTheme++;
    if (pf && pf[1] === "chance") {
      const c = H.kits[p.name][st] * R.G.rarityMult[p.tier];
      if (c > wild[1]) wild = [`${p.name} ${st}`, c];
    }
  }
  if (fams.size > 1) twoFamilies++;
}
check(Math.abs(H.mult - Math.pow(Zone.ZONE_STEP, 10)) < 1e-9, `power is Event Horizon's (zone 11): x${H.mult.toFixed(2)}`);
check(["Mythic", "Divine", "Exotic"].every((t) => H.meta.topBeat[t] >= 1.2), "the pack's topBeat is at least 1.2 at Mythic, Divine and Exotic (owner: 20%)");
check(worst < 0.01, `every kit is worth 1.5 x the ladder at that power below Mythic, and topBeat x the best normal pet's score (${B.best.name}, ${B.best.score.toFixed(1)}) at Mythic+ (worst ${(worst * 100).toFixed(2)}%)`);
check(offTheme === 0, "every proc on the 60 is the pack's own (" + family + ")");
check(twoFamilies === 0, "no pet carries two ability families");
check(wild[1] <= 0.6, `proc odds stay at most 60%: highest ${(wild[1] * 100).toFixed(1)}% (${wild[0]})`);
check(own.filter((p) => TOPT.has(p.tier)).every((p) => Object.keys(H.kits[p.name]).every((s) => H.meta.buffs.includes(s))),
  "the 60's Mythic, Divine and Exotic use exactly the pack's buff set");

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
print((n == 72 and k == 72 and hol == 72 and m.PACK_ID == "halloween_2026") and "  ok    luau: the module loads, 72 pets, a kit each, all holiday" or ("  FAIL  luau: pets " .. n .. " kits " .. k .. " holiday " .. hol))
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
// The case pays this pack, or (the Crypt v2 case, owner 2026-10-19: pets and
// skins only) draws Halloween pets through MineHalloweenPets.
const tot = code(read(SH + "MineTrickOrTreat.luau"));
check(new RegExp(`PACK_ID = "${H.meta.packId}"`).test(tot) || /MineHalloweenPets/.test(tot),
  "the Trick-or-Treat case asks for this pack's id, or draws from MineHalloweenPets");

console.log("");
console.log(fail > 0 ? `>>> holiday-pets: ${fail} FAILED` : ">>> holiday-pets: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
