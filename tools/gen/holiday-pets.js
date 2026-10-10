#!/usr/bin/env node
// HOLIDAY PETS: the Halloween 2026 Pack's 60 pets (owner, 2026-10-10).
//
//   "make it 60 halloween pets [keep the specaltiy ones as as rare ones, and for
//    the others just make them normal cards with a costume {simple shit like a
//    dog costume on or something}]"
//   Rarities: costumes Common 20 / Uncommon 15 / Rare 10; the 15 Halloween
//   bodies Epic 6 / Legendary 4 / Mythic 2 / Divine 2 / Exotic 1.
//   Power: Event Horizon's level (zone 11 on the ladder).
//
// Holiday rule ("only allow it from {Holiday} {year} Pack"): every pet here is
// stamped `holiday`, so no pot, wheel, lucky block or set pack ever rolls one;
// only the holiday pack itself may.
//
// Inputs:  tools/gen/holiday/<key>.json
//          PetModelFactory (species, season tags, cos_* costumes)
//          the zone and set generators (names, skins and tints already taken)
// Writes:  src/.../Shared/HolidayPets/<Key>.luau   one data module per holiday pack
//          docs/HOLIDAY-PETS.md                     the names sheet
//
//   node tools/gen/holiday-pets.js           write
//   node tools/gen/holiday-pets.js --check   exit 1 if anything is stale
"use strict";
const fs = require("fs");
const path = require("path");
const Zone = require("./zone-pets.js");
const SetGen = require("./set-pets.js");

const ROOT = path.resolve(__dirname, "../..");
const SHARED = "src/ReplicatedStorage/Mine/Shared/";
const OUT_DIR = SHARED + "HolidayPets/";
const OUT_MD = "docs/HOLIDAY-PETS.md";
const IN_DIR = "tools/gen/holiday/";
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8").replace(/\r\n/g, "\n");

const { TIERS, LADDER, ZONE_STEP, ROLES, BANNED } = Zone;
const TOP = new Set(["Mythic", "Divine", "Exotic"]);
const TOP_SHARES = [1, 0.35, 0.15];
const SECONDARY = 0.5;
// Holiday pets' serial prefixes: their own range, after the sets' (0x400-0xBFF).
const HEX_START = 0xc00;
const HEX_END = 0xcff;

const pascal = (key) => key.split("_").map((w) => (/^\d/.test(w) ? w : w[0].toUpperCase() + w.slice(1))).join("");
function fnv(s) {
  let h = 0x811c9dc5;
  for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 0x01000193) >>> 0; }
  return h >>> 0;
}
function shuffled(list, seed) {
  const out = list.slice();
  let x = fnv(seed) || 1;
  for (let i = out.length - 1; i > 0; i--) {
    x ^= x << 13; x >>>= 0; x ^= x >>> 17; x ^= x << 5; x >>>= 0;
    const j = x % (i + 1);
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}
const dist = (a, b) => Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2]);
const round4 = (v) => Math.round(v * 10000) / 10000;
const nameKey = (n) => n.toLowerCase().replace(/s$/, "");
const lq = (s) => '"' + String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';
const rgbLua = (c) => `Color3.fromRGB(${c[0]}, ${c[1]}, ${c[2]})`;
const kitLua = (kit) => "{ " + Object.entries(kit).map(([s, v]) => `${s} = ${v}`).join(", ") + " }";

// ---- read the game ----------------------------------------------------------
function readGame() {
  const pmf = read(SHARED + "PetModelFactory.luau");
  const species = {};
  for (const m of pmf.matchAll(/\nS\.(\w+) = \{\n\tlabel = "([^"]+)",\n(\tseason = "(\w+)",\n)?/g)) {
    species[m[1]] = { label: m[2], season: m[4] || null };
  }
  const costumes = new Set([...pmf.matchAll(/\nD\.(cos_\w+) = function/g)].map((m) => m[1]));
  const Z = Zone.build();
  const S = SetGen.build();
  const takenNames = new Set([
    ...Z.G.roster.map((r) => r.name), ...Z.G.ehNames, ...Z.pets.map((p) => p.name),
    ...S.sets.flatMap((s) => s.pets.map((p) => p.name)),
  ]);
  const takenAnimals = new Set([
    ...Object.keys(Z.G.animals), ...Object.keys(Z.newAnimals), ...Z.G.ehAnimals,
    ...S.sets.flatMap((s) => Object.keys(s.animals)),
  ]);
  const tintsBy = {};
  const addTint = (a) => (tintsBy[a.species] = tintsBy[a.species] || []).push(a.rgb);
  Object.values(Z.G.animals).forEach(addTint);
  Object.values(Z.newAnimals).forEach(addTint);
  S.sets.forEach((s) => Object.values(s.animals).forEach(addTint));
  return { species, costumes, takenNames, takenAnimals, tintsBy, G: Z.G };
}

function roleOf(sp) {
  for (const [role, r] of Object.entries(ROLES)) if (r.species.includes(sp)) return role;
  return null;
}

// The colour for one pet: the first of the palette (walked from a per-pet
// start) that no skin on this body is near. Two pets on one body never share
// a colour; neither does a holiday pet with any pet already in the game.
function pickColour(palette, sp, seed, tintsBy) {
  const taken = tintsBy[sp] || (tintsBy[sp] = []);
  const start = fnv(seed) % palette.length;
  for (const minD of [40, 24, 12]) {
    for (let k = 0; k < palette.length; k++) {
      const c = palette[(start + k) % palette.length];
      const rgb = c.slice(1);
      if (taken.every((t) => dist(t, rgb) >= minD)) {
        taken.push(rgb);
        return { name: c[0], rgb };
      }
    }
  }
  throw new Error("no free colour on " + sp);
}

// ---- build ------------------------------------------------------------------
function buildOne(d, R, hexFrom) {
  const mult = Math.pow(ZONE_STEP, d.zoneLevel - 1);
  for (const sp of d.specials) {
    const s = R.species[sp.body];
    if (!s) throw new Error(`${d.key}: special body ${sp.body} is not a species`);
    if (!s.season || s.season.toLowerCase() !== d.holiday) throw new Error(`${d.key}: ${sp.body} is not a ${d.holiday} body`);
  }
  for (const sp of d.costumeBodies) {
    if (!R.species[sp]) throw new Error(`${d.key}: costume body ${sp} is not a species`);
    if (R.species[sp].season) throw new Error(`${d.key}: costume body ${sp} is a holiday body`);
    if (!roleOf(sp)) throw new Error(`${d.key}: costume body ${sp} has no role`);
  }
  for (const c of d.costumes) if (!R.costumes.has(c.id)) throw new Error(`${d.key}: costume ${c.id} is not in PetModelFactory.DETAILS`);

  // Names: shuffled, minus anything taken, minus plural/case twins.
  const usedKeys = new Set([...R.takenNames].map(nameKey));
  const names = [];
  for (const n of shuffled(d.names, d.key)) {
    const k = nameKey(n);
    if (n.length > 16 || n.split(" ").length > 2 || usedKeys.has(k)) continue;
    usedKeys.add(k);
    names.push(n);
  }
  let nameAt = 0;
  const nextName = () => {
    const n = names[nameAt++];
    if (!n) throw new Error(`${d.key}: ran out of names`);
    return n;
  };

  const pets = [], animals = {}, kits = {}, roles = {};
  let hex = hexFrom;
  const usedAnimals = new Set();
  const addPet = (tier, species, animal, skin, role) => {
    if (R.takenAnimals.has(animal) || usedAnimals.has(animal)) throw new Error(`${d.key}: look "${animal}" is taken`);
    usedAnimals.add(animal);
    animals[animal] = skin;
    const name = nextName();
    if (hex > HEX_END) throw new Error("holiday serials overflow their range");
    const pet = { name, hex3: (hex++).toString(16).padStart(3, "0"), animal, tier, set: d.key, holiday: d.holiday, species };
    pets.push(pet);
    // The kit: the approved ladder (lifted) at this pack's zone level.
    const P = (LADDER[tier] / R.G.rarityMult[tier]) * mult;
    const kit = {};
    let statsUsed, shares;
    if (TOP.has(tier)) {
      const k = pets.filter((p) => TOP.has(p.tier)).length - 1;
      statsUsed = d.buffs.slice(k % 3).concat(d.buffs.slice(0, k % 3));
      shares = TOP_SHARES;
      roles[name] = d.name;
    } else {
      const r = ROLES[role];
      const pairs = r.pairs.concat(tier !== "Common" && tier !== "Uncommon" && r.rarePlus ? r.rarePlus : []);
      statsUsed = SetGen.fitToSet(pairs[fnv(name) % pairs.length], d.buffs);
      shares = [1, SECONDARY];
      roles[name] = role;
    }
    statsUsed.forEach((stat, i) => {
      if (BANNED.has(stat)) throw new Error("banned stat " + stat);
      kit[stat] = round4((P * shares[i]) / R.G.stats[stat].weight / 100);
    });
    kits[name] = kit;
  };

  // The 15 specials, rarest first: a Halloween body in a spooky colour.
  const order = ["Exotic", "Divine", "Mythic", "Legendary", "Epic"];
  for (const tier of order) {
    for (const sp of d.specials.filter((x) => x.tier === tier)) {
      if (!ROLES[sp.role]) throw new Error(`${d.key}: unknown role ${sp.role}`);
      const col = pickColour(d.spookyPalette, sp.body, d.key + sp.body, R.tintsBy);
      const animal = `${col.name} ${R.species[sp.body].label}`;
      addPet(tier, sp.body, animal, { species: sp.body, rgb: col.rgb }, sp.role);
    }
  }
  // The 45 costume pets: an everyday body in fancy dress. Costume k%8 on body
  // (c + 2r) % 9 gives every pair at most once, each costume ~6 times and each
  // body ~5, and every rarity band sees every costume.
  const nC = d.costumes.length, nB = d.costumeBodies.length;
  const bands = [];
  for (const t of ["Common", "Uncommon", "Rare"]) for (let i = 0; i < d.costumeCounts[t]; i++) bands.push(t);
  bands.forEach((tier, k) => {
    const c = k % nC, r = Math.floor(k / nC);
    const sp = d.costumeBodies[(c + 2 * r) % nB];
    const cos = d.costumes[c];
    const col = pickColour(d.furPalette, sp, d.key + sp + cos.id, R.tintsBy);
    let animal = `${cos.label} ${R.species[sp].label}`;
    if (R.takenAnimals.has(animal) || usedAnimals.has(animal)) animal = `${col.name} ${animal}`;
    addPet(tier, sp, animal, { species: sp, rgb: col.rgb, detail: [cos.id] }, roleOf(sp));
  });
  return { meta: d, mult, pets, animals, kits, roles, names: names.length };
}

function build() {
  const R = readGame();
  const files = fs.readdirSync(path.join(ROOT, IN_DIR)).filter((f) => f.endsWith(".json")).sort();
  const packs = [];
  let hex = HEX_START;
  for (const f of files) {
    const d = JSON.parse(read(IN_DIR + f));
    const H = buildOne(d, R, hex);
    hex += H.pets.length;
    packs.push(H);
  }
  return { R, packs };
}

// ---- render -----------------------------------------------------------------
function renderModule(H) {
  const d = H.meta;
  const L = [];
  L.push("--[[");
  L.push(`\tHolidayPets/${pascal(d.key)} -- the ${d.packName}'s pets.`);
  L.push(`\tGENERATED by tools/gen/holiday-pets.js from ${IN_DIR}${d.key}.json;`);
  L.push("\tedit those, not this. Names are save data: never rename one without an alias.");
  L.push("");
  L.push("\tHoliday rule (owner): these pets come ONLY from this pack. Every row");
  L.push("\tcarries `holiday`, which every random roll skips.");
  L.push("]]");
  L.push("return {");
  L.push(`\tKEY = ${lq(d.key)},`);
  L.push(`\tNAME = ${lq(d.name)},`);
  L.push(`\tHOLIDAY = ${lq(d.holiday)},`);
  L.push(`\tPACK_ID = ${lq(d.packId)},`);
  L.push(`\tPACK_NAME = ${lq(d.packName)},`);
  L.push(`\tPOWER = ${round4(H.mult)},`);
  L.push(`\t-- Older ${d.holiday} pets, already in saves, that this pack also pays.`);
  L.push(`\tLEGACY = { ${d.legacy.map(lq).join(", ")} },`);
  L.push(`\tBUFFS = { ${d.buffs.map(lq).join(", ")} },`);
  L.push("\tPETS = {");
  for (const p of H.pets) L.push(`\t\t{ name = ${lq(p.name)}, hex3 = ${lq(p.hex3)}, animal = ${lq(p.animal)}, tier = ${lq(p.tier)}, set = ${lq(p.set)}, holiday = ${lq(p.holiday)} },`);
  L.push("\t},");
  L.push("\tANIMALS = {");
  for (const p of H.pets) {
    const s = H.animals[p.animal];
    const parts = [`species = ${lq(s.species)}`, `tint = ${rgbLua(s.rgb)}`];
    if (s.detail) parts.push(`detail = { ${s.detail.map(lq).join(", ")} }`);
    L.push(`\t\t[${lq(p.animal)}] = { ${parts.join(", ")} },`);
  }
  L.push("\t},");
  L.push("\tKITS = {");
  for (const p of H.pets) L.push(`\t\t[${lq(p.name)}] = ${kitLua(H.kits[p.name])},`);
  L.push("\t},");
  L.push("\tROLE = {");
  for (const p of H.pets) L.push(`\t\t[${lq(p.name)}] = ${lq(H.roles[p.name])},`);
  L.push("\t},");
  L.push("}");
  return L.join("\n") + "\n";
}

function renderMd(B) {
  const G = B.R.G;
  const fmt = (kit, tier) => Object.entries(kit).map(([s, v]) => {
    const pct = v * 100 * G.rarityMult[tier];
    return `+${pct >= 10 ? pct.toFixed(0) : pct.toFixed(1)}% ${G.stats[s].label}`;
  }).join(", ");
  const L = [];
  L.push("# Holiday pets: the names sheet");
  L.push("");
  L.push("GENERATED by `tools/gen/holiday-pets.js`; do not edit by hand. The game reads");
  L.push("`src/ReplicatedStorage/Mine/Shared/HolidayPets/`. Boosts are at Normal, power level 1.");
  L.push("");
  L.push("Holiday rule (owner): a holiday pet comes only from its \"{Holiday} {year} Pack\".");
  for (const H of B.packs) {
    const d = H.meta;
    L.push("");
    L.push(`## ${d.packName} (${H.pets.length} pets, power ×${H.mult.toFixed(2)})`);
    L.push("");
    L.push(`Owner: ${d.note}`);
    L.push("");
    L.push(`Also pays the older ${d.holiday} pets: ${d.legacy.join(", ")}.`);
    L.push("");
    L.push("| tier | name | looks like | role | boost |");
    L.push("|---|---|---|---|---|");
    for (const t of TIERS.slice().reverse()) {
      for (const p of H.pets.filter((x) => x.tier === t)) {
        L.push(`| ${p.tier} | ${p.name} | ${p.animal} | ${H.roles[p.name]} | ${fmt(H.kits[p.name], p.tier)} |`);
      }
    }
  }
  return L.join("\n") + "\n";
}

function outputs(B) {
  const out = B.packs.map((H) => [OUT_DIR + pascal(H.meta.key) + ".luau", renderModule(H)]);
  out.push([OUT_MD, renderMd(B)]);
  return out;
}

function main() {
  const check = process.argv.includes("--check");
  const B = build();
  let stale = 0;
  for (const [rel, text] of outputs(B)) {
    const abs = path.join(ROOT, rel);
    const cur = fs.existsSync(abs) ? fs.readFileSync(abs, "utf8").replace(/\r\n/g, "\n") : null;
    if (cur === text) continue;
    stale++;
    if (check) console.log("stale: " + rel);
    else {
      fs.mkdirSync(path.dirname(abs), { recursive: true });
      fs.writeFileSync(abs, text);
    }
  }
  const n = B.packs.reduce((a, H) => a + H.pets.length, 0);
  if (check) process.exit(stale ? 1 : 0);
  console.log(`${n} holiday pets in ${B.packs.length} pack(s) written`);
}

module.exports = { build, outputs, renderModule, pascal, HEX_START, HEX_END, OUT_DIR, OUT_MD };
if (require.main === module) main();
