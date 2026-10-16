// The 19 exclusive sets: 2,043 named pets, exactly the owner's counts.
//
// Owner, 2026-10-10 (docs/PETS-AND-SETS.md, tools/gen/sets/_sets.json):
// every set pet named by hand, ~100 new bodies, each set +5% over the set
// before (set 1 at zone 1's level), no holiday bodies, proc odds "lowish".
//
//   1. the generated files are fresh (tools/gen/set-pets.js --check)
//   2. every set holds exactly the owner's count at every rarity (2,043)
//   3. names, looks, (body, colour) and serials never collide with anything
//   4. bodies: every own body exists in PetBodies and is used; no holiday body
//   5. kits: the ladder x 1.05 a set; top pets use the set's buffs; odds sane
//   6. each SetPets module runs in luau and carries what it claims
//   7. the roster, kit lookup and model factory read the sets
//
//   node tools/verify/set-pets.js
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = path.resolve(__dirname, "../..");
const Gen = require("../gen/set-pets.js");
const Zone = require("../gen/zone-pets.js");
const Luau = require("./_luau");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8").replace(/\r\n/g, "\n");
const code = (s) => s.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");

let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

const B = Gen.build();
const R = B.R;

// 1. fresh
const stale = Gen.outputs(B).filter(([rel, text]) => !fs.existsSync(path.join(ROOT, rel)) || read(rel) !== text);
check(stale.length === 0, "the SetPets modules and docs/SET-PETS.md match the generator" + (stale.length ? " (stale: " + stale.map((s) => s[0]).join(", ") + ")" : ""));

// 2. counts
let countsOk = true, total = 0;
for (const S of B.sets) {
  Zone.TIERS.forEach((t, i) => {
    const n = S.pets.filter((p) => p.tier === t).length;
    if (n !== S.meta.counts[i]) countsOk = false;
  });
  total += S.pets.length;
}
check(B.sets.length === 19 && total === 2043 && countsOk, `19 sets, ${total} pets, every set exactly the owner's count at every rarity`);

// 3. identity
const Z = Zone.build();
const all = [...R.takenNames, ...B.sets.flatMap((S) => S.pets.map((p) => p.name))];
check(new Set(all).size === all.length, `every set pet's name is new (${total})`);
const keys = all.map((n) => n.toLowerCase().replace(/s$/, ""));
check(new Set(keys).size === keys.length, "no name is a plural or case twin of another anywhere in the game");
const setAnimals = B.sets.flatMap((S) => Object.keys(S.animals));
check(new Set(setAnimals).size === setAnimals.length && setAnimals.every((a) => !R.takenAnimals.has(a)), "every set pet has its own look");
const pairs = [...Object.values(Z.G.animals), ...Object.values(Z.newAnimals), ...B.sets.flatMap((S) => Object.values(S.animals))]
  .map((a) => a.species + "|" + a.rgb.join(","));
check(new Set(pairs).size === pairs.length, `no two skins share a body and a colour (${pairs.length} skins)`);
const hexes = B.sets.flatMap((S) => S.pets.map((p) => parseInt(p.hex3, 16)));
const otherHex = new Set([...Z.G.roster.map((r) => parseInt(r.hex3, 16)), ...Z.pets.map((p) => parseInt(p.hex3, 16))]);
check(new Set(hexes).size === hexes.length && hexes.every((h) => h >= Gen.HEX_START && h < 0xc00 && !otherHex.has(h)),
  "set serial prefixes are unique and live in their own range (0x400-0xBFF)");

// 4. bodies
let bodiesOk = true, ownBodies = 0, unused = [];
for (const S of B.sets) {
  for (const b of S.data.bodies) {
    ownBodies++;
    if (!R.species[b.id] || !R.species[b.id].setBody) bodiesOk = false;
    if (!(S.bodyCount[b.id] >= 3)) unused.push(b.id);
  }
}
check(bodiesOk && ownBodies >= 95, `${ownBodies} new set bodies, each in a PetBodies module`);
check(unused.length === 0, "every set body is worn by at least 3 of its set's pets" + (unused.length ? ": " + unused.join(", ") : ""));
// Owner: the theme is the predominant type. The own (themed) bodies dress most of a set.
const thin = B.sets.filter((S) => {
  const own = new Set(S.data.bodies.map((b) => b.id));
  return S.pets.filter((p) => own.has(p.species)).length / S.pets.length < 0.6;
}).map((S) => S.meta.key);
check(thin.length === 0, "every set's own themed bodies dress at least 60% of its pets" + (thin.length ? ": " + thin.join(", ") : ""));
const holiday = B.sets.flatMap((S) => S.pets.filter((p) => R.species[p.species] && R.species[p.species].season));
check(holiday.length === 0, "no set pet wears a holiday body");
const bodySrc = fs.readdirSync(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/PetBodies")).filter((f) => f.endsWith(".luau"))
  .map((f) => read("src/ReplicatedStorage/Mine/Shared/PetBodies/" + f));
check(bodySrc.length === 19 && bodySrc.every((s) => !/season\s*=/.test(code(s)) && /^\s*(--\[\[[\s\S]*?\]\]\s*)?return function\(K\)/m.test(s)),
  "19 PetBodies modules, each a plain function of the kit with no season tag");

// 5. kits
const value = (kit) => Object.entries(kit).reduce((a, [s, v]) => a + v * 100 * R.G.stats[s].weight, 0);
let worst = 0, topOk = true, wild = ["", 0];
for (const S of B.sets) {
  for (const p of S.pets) {
    const want = 1.5 * Zone.LADDER[p.tier] * S.mult;
    worst = Math.max(worst, Math.abs(value(S.kits[p.name]) * R.G.rarityMult[p.tier] / want - 1));
    for (const st of ["blastChance", "tidalWave", "zap", "ricochet", "earthquake"]) {
      const c = (S.kits[p.name][st] || 0) * R.G.rarityMult[p.tier];
      if (c > wild[1]) wild = [`${p.name} (${S.meta.name}) ${st}`, c];
    }
  }
  const top = S.pets.filter((p) => ["Mythic", "Divine", "Exotic"].includes(p.tier));
  if (!top.every((p) => Object.keys(S.kits[p.name]).every((s) => S.data.buffs.includes(s)))) topOk = false;
}
check(worst < 0.01, `every kit is worth 1.5 x the ladder x 1.05 a set (worst ${(worst * 100).toFixed(2)}%)`);
check(Math.abs(B.sets[18].mult - Math.pow(1.05, 18)) < 1e-9 && B.sets[0].mult === 1, `set 1 is x1.00 (zone 1), set 19 is x${B.sets[18].mult.toFixed(2)}`);
check(topOk, "every set's Mythic/Divine/Exotic pets use exactly that set's buff set");
check(wild[1] <= 0.6, `proc odds stay lowish: the highest single-pet chance is ${(wild[1] * 100).toFixed(1)}% (${wild[0]}), at most 60%`);
// Owner: buffs must make sense. Below Mythic a proc is always the set's own,
// and a set with no proc has none at all.
const offTheme = [];
for (const S of B.sets) {
  const family = Gen.setProcFamily(S.data.buffs);
  for (const p of S.pets) {
    for (const st of Object.keys(S.kits[p.name])) {
      const pf = Gen.PROC_OF[st];
      if (pf && pf[0] !== family) offTheme.push(`${p.name} (${S.meta.name}) ${st}`);
    }
  }
}
check(offTheme.length === 0, "every set pet's proc is its set's own proc; sets with no proc have none" + (offTheme.length ? ": " + offTheme.slice(0, 5).join(", ") + (offTheme.length > 5 ? " ..." : "") : ""));
const usedStats = new Set(B.sets.flatMap((S) => Object.values(S.kits).flatMap((k) => Object.keys(k))));
check([...usedStats].every((s) => !Zone.BANNED.has(s) && R.G.stats[s]), "no kit carries a retired, rune-only or unknown stat");

// 6. luau
if (!Luau.ready) { console.log(Luau.missing("luau") + "; skipping"); process.exit(1); }
const chunks = B.sets.map((S) => `do local m = (function()\n${read(Gen.OUT_DIR + Gen.pascal(S.meta.key) + ".luau")}\nend)()
	local n, k = #m.PETS, 0
	for name in pairs(m.KITS) do k += 1 end
	if n ~= ${S.pets.length} or k ~= n or m.INDEX ~= ${S.index} then bad += 1 print("  FAIL  luau: ${S.meta.key} pets " .. n .. " kits " .. k) end
	total += n end`).join("\n");
const harness = `
Color3 = { fromRGB = function(r, g, b) return { r, g, b } end }
Enum = { Material = setmetatable({}, { __index = function(_, k) return k end }) }
local bad, total = 0, 0
${chunks}
print(bad == 0 and ("  ok    luau: all 19 SetPets modules load, " .. total .. " pets, a kit each") or "  FAIL  luau: " .. bad .. " modules")
`;
const script = path.join(ROOT, ".luau-bin/set-pets-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(Luau.LUAU, [script], { encoding: "utf8" }); process.stdout.write(out); }
catch (e) { process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || ""); fail++; }
if (/FAIL/.test(out)) fail++;

// 7. wiring
const SH = "src/ReplicatedStorage/Mine/Shared/";
const roster = code(read(SH + "MinePetRoster.luau"));
const merge = roster.indexOf('FindFirstChild("MineSetPets")');
check(merge > 0 && merge < roster.indexOf("MinePetRoster.BY_NAME = {}") && /BY_SET\[pet\.set\]/.test(roster),
  "MinePetRoster merges the set pets before its indexes, and indexes them by set");
const boosts = code(read(SH + "MinePetBoosts.luau"));
check(/sp\.KITS/.test(boosts) && /PET_BOOSTS\.Z\[name\] = kit/.test(boosts), "the set kits join the one kit table");
const pmf = code(read(SH + "PetModelFactory.luau"));
check(/sp\.ANIMALS/.test(pmf) && /FindFirstChild\("PetBodies"\)/.test(pmf) && /PetModelFactory\.KIT = \{/.test(pmf),
  "PetModelFactory loads the PetBodies modules and the set skins");
// Roblox draws nothing for the legacy Pyramid and Prism mesh types (wiki
// luau-traps §10): every cone and prism must be made of real wedge parts.
const invisible = [pmf, ...bodySrc.map(code)].filter((s) => /MeshType\.(Pyramid|Prism|ParallelRamp|RightAngleRamp)\b/.test(s)).length;
check(invisible === 0, "no pet part uses a mesh type Roblox no longer draws (Pyramid, Prism)");

console.log("");
console.log(fail > 0 ? `>>> set-pets: ${fail} FAILED` : ">>> set-pets: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
