#!/usr/bin/env node
// THE 19 EXCLUSIVE SETS: 2,043 named pets (owner, 2026-10-10).
//
//   "Just make pets for each set ... name all the new pets ... think out the
//    abilities of each pet more ... add more actual pet types"
//   "each set should have different pet budgets, that increase at the same
//    level as the last" (+5% a set), starting at zone 1's level.
//
// Inputs:  tools/gen/sets/_sets.json            the owner's table (order, grade, counts, packs)
//          tools/gen/sets/<key>.json            each set's bodies, names, palette, buffs
//          src/.../Shared/PetBodies/*.luau      each set's new bodies
// Writes:  src/.../Shared/SetPets/<Key>.luau    one data module per set
//          docs/SET-PETS.md                     the names sheet
//
//   node tools/gen/set-pets.js           write
//   node tools/gen/set-pets.js --check   exit 1 if anything is stale
"use strict";
const fs = require("fs");
const path = require("path");
const Zone = require("./zone-pets.js");

const ROOT = path.resolve(__dirname, "../..");
const SHARED = "src/ReplicatedStorage/Mine/Shared/";
const OUT_DIR = SHARED + "SetPets/";
const OUT_MD = "docs/SET-PETS.md";
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8").replace(/\r\n/g, "\n");

const { TIERS, LADDER, ZONE_STEP, ROLES, BANNED } = Zone;
const TOP = new Set(["Mythic", "Divine", "Exotic"]);
const SET_STEP = ZONE_STEP; // +5% a set, the zones' step
const TOP_SHARES = [1, 0.35, 0.15];
const SECONDARY = 0.5;
const PROC_CHANCE = new Set(["zap", "blastChance", "tidalWave", "ricochet", "earthquake"]);
// Set pets' serial prefixes live in their own range, so a zone pet added later
// (which counts up from the roster) can never collide with one.
const HEX_START = 0x400;

const pascal = (key) => key.split("_").map((w) => (w === "and" ? "And" : w[0].toUpperCase() + w.slice(1))).join("");

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
const lighten = (rgb, t) => rgb.map((c) => Math.round(c + (255 - c) * t));
const nameKey = (n) => n.toLowerCase().replace(/s$/, "");

// ---- read the game ----------------------------------------------------------
function readGame() {
  const meta = JSON.parse(read("tools/gen/sets/_sets.json")).sets;
  const data = {};
  for (const s of meta) {
    const f = `tools/gen/sets/${s.key}.json`;
    if (!fs.existsSync(path.join(ROOT, f))) throw new Error("missing " + f);
    data[s.key] = JSON.parse(read(f));
  }
  // Every body: the factory's own species plus every PetBodies module.
  const pmf = read(SHARED + "PetModelFactory.luau");
  const species = {};
  for (const m of pmf.matchAll(/\nS\.(\w+) = \{\n\tlabel = "([^"]+)",\n(\tseason = "(\w+)",\n)?/g)) {
    species[m[1]] = { label: m[2], season: m[4] || null, setBody: false };
  }
  const bodyDir = path.join(ROOT, SHARED, "PetBodies");
  for (const f of fs.existsSync(bodyDir) ? fs.readdirSync(bodyDir) : []) {
    if (!f.endsWith(".luau")) continue;
    const src = fs.readFileSync(path.join(bodyDir, f), "utf8").replace(/\r\n/g, "\n");
    for (const m of src.matchAll(/\bS\.(\w+)\s*=\s*\{[\s\S]*?label\s*=\s*"([^"]+)"/g)) {
      species[m[1]] = { label: m[2], season: /season\s*=/.test(m[0]) ? "?" : null, setBody: true, file: f };
    }
  }
  // Names and skins already in the game: roster, Event Horizon, zone pets.
  const Z = Zone.build();
  const takenNames = new Set([...Z.G.roster.map((r) => r.name), ...Z.G.ehNames, ...Z.pets.map((p) => p.name)]);
  const takenAnimals = new Set([...Object.keys(Z.G.animals), ...Object.keys(Z.newAnimals), ...Z.G.ehAnimals]);
  const tintsBy = {};
  for (const a of Object.values(Z.G.animals)) (tintsBy[a.species] = tintsBy[a.species] || []).push(a.rgb);
  for (const a of Object.values(Z.newAnimals)) (tintsBy[a.species] = tintsBy[a.species] || []).push(a.rgb);
  return { meta, data, species, takenNames, takenAnimals, tintsBy, G: Z.G };
}

// ---- build -------------------------------------------------------------------
function roleOfSpecies(sp, setBodies) {
  const own = setBodies.find((b) => b.id === sp);
  if (own) return own.role;
  for (const [role, r] of Object.entries(ROLES)) if (r.species.includes(sp)) return role;
  return "Striker";
}

function build() {
  const R = readGame();
  const usedKeys = new Set([...R.takenNames].map(nameKey));
  const usedAnimals = new Set(R.takenAnimals);
  const tintsBy = R.tintsBy;
  let hex = HEX_START;
  const sets = [];

  R.meta.forEach((m, idx) => {
    const d = R.data[m.key];
    const index = idx + 1;
    const mult = Math.pow(SET_STEP, index - 1);
    if (!Array.isArray(d.bodies) || d.bodies.length < 4) throw new Error(m.key + ": needs its own bodies");
    for (const b of d.bodies) {
      if (!R.species[b.id] || !R.species[b.id].setBody) throw new Error(`${m.key}: body ${b.id} has no PetBodies module`);
      if (!ROLES[b.role]) throw new Error(`${m.key}: body ${b.id} has unknown role ${b.role}`);
    }
    for (const sp of d.extraBodies || []) {
      if (!R.species[sp]) throw new Error(`${m.key}: extra body ${sp} does not exist`);
      if (R.species[sp].season) throw new Error(`${m.key}: extra body ${sp} is a holiday body`);
    }
    if (!Array.isArray(d.buffs) || d.buffs.length !== 3) throw new Error(m.key + ": needs 3 buffs");
    if (d.buffs.filter((s) => PROC_CHANCE.has(s)).length > 1) throw new Error(m.key + ": more than one proc chance in buffs");
    for (const s of d.buffs) if (BANNED.has(s) || !R.G.stats[s]) throw new Error(`${m.key}: buff ${s} is not a pet stat`);

    // Bodies: the set's own count double, so they lead; a few fitting old ones.
    const pool = [];
    for (const b of d.bodies) pool.push(b.id, b.id);
    for (const sp of d.extraBodies || []) pool.push(sp);
    const bodyCount = {};

    const names = shuffled([...new Set(d.names)], m.key + ":names").filter((n) => {
      const k = nameKey(n);
      if (usedKeys.has(k) || n.length > 16 || !/^[A-Za-z][A-Za-z' .-]*$/.test(n)) return false;
      usedKeys.add(k);
      return true;
    });
    const palette = d.palette.map((c) => ({ name: c[0], rgb: [c[1], c[2], c[3]] }));
    let nameAt = 0;
    const pets = [];
    const animals = {};
    const kits = {};
    const roles = {};
    let topK = 0;

    TIERS.forEach((tier, ti) => {
      for (let k = 0; k < m.counts[ti]; k++) {
        const si = pets.length;
        const species = pool.slice().sort((a, b) => ((bodyCount[a] || 0) / (pool.filter((x) => x === a).length)) -
          ((bodyCount[b] || 0) / (pool.filter((x) => x === b).length)) || fnv(a + si) - fnv(b + si))[0];
        bodyCount[species] = (bodyCount[species] || 0) + 1;
        const label = R.species[species].label;

        const taken = tintsBy[species] || (tintsBy[species] = []);
        const order = shuffled(palette, m.key + tier + si);
        let pick = null;
        for (const minDist of [40, 30, 22, 15, 8]) {
          pick = order.find((c) => taken.every((t) => dist(t, c.rgb) >= minDist) &&
            !usedAnimals.has(`${c.name} ${label}`));
          if (pick) break;
        }
        if (!pick) {
          // Out of distinct palette colours on this body: nudge one.
          const base = order[si % order.length];
          pick = { name: base.name, rgb: base.rgb.map((v, i) => Math.max(0, Math.min(255, v + ((si * (i + 3)) % 23) - 11))) };
        }
        taken.push(pick.rgb);

        const skin = { species, rgb: pick.rgb };
        const words = (d.topWords && d.topWords[tier]) || [];
        let animal;
        if (TOP.has(tier)) {
          animal = `${words[si % Math.max(1, words.length)] || tier} ${label}`;
          skin.glow = lighten(pick.rgb, 0.45);
          if (tier === "Mythic") { skin.material = "Glass"; skin.reflect = 0.25; }
          if (tier === "Divine") skin.transparency = 0.2;
          if (tier === "Exotic") skin.chroma = true;
        } else if (tier === "Legendary") {
          animal = `${words[si % Math.max(1, words.length)] || "Radiant"} ${pick.name} ${label}`;
          skin.glow = lighten(pick.rgb, 0.5);
          skin.reflect = 0.2;
        } else {
          animal = `${pick.name} ${label}`;
          if (tier === "Epic") {
            skin.glow = lighten(pick.rgb, 0.4);
            animal = `Glowing ${animal}`;
          }
        }
        for (let n = 2; usedAnimals.has(animal); n++) {
          animal = TOP.has(tier) ? `${words[(si + n) % Math.max(1, words.length)] || tier} ${pick.name} ${label}` : `${animal.replace(/ (II|III|IV|V|VI)$/, "")} ${["", "", "II", "III", "IV", "V", "VI"][n] || n}`;
          if (n > 8) throw new Error("animal collision: " + animal);
        }
        usedAnimals.add(animal);
        animals[animal] = skin;

        const name = names[nameAt++];
        if (!name) throw new Error(`${m.key}: ran out of names at ${pets.length + 1} of ${m.counts.reduce((a, b) => a + b, 0)}`);
        const pet = { name, hex3: (hex++).toString(16).padStart(3, "0"), animal, tier, set: m.key, species };
        pets.push(pet);

        // The kit: the approved ladder (lifted), +5% a set.
        const P = (LADDER[tier] / R.G.rarityMult[tier]) * mult;
        const kit = {};
        let statsUsed, shares;
        if (TOP.has(tier)) {
          statsUsed = d.buffs.slice(topK % 3).concat(d.buffs.slice(0, topK % 3));
          topK++;
          shares = TOP_SHARES;
          roles[name] = m.name;
        } else {
          const role = roleOfSpecies(species, d.bodies);
          const r = ROLES[role];
          const pairs = r.pairs.concat(tier !== "Common" && tier !== "Uncommon" && r.rarePlus ? r.rarePlus : []);
          statsUsed = pairs[fnv(name) % pairs.length];
          shares = [1, SECONDARY];
          roles[name] = role;
        }
        statsUsed.forEach((stat, i) => {
          if (BANNED.has(stat)) throw new Error("banned stat " + stat);
          kit[stat] = round4((P * shares[i]) / R.G.stats[stat].weight / 100);
        });
        kits[name] = kit;
      }
    });
    sets.push({ meta: m, data: d, index, mult, pets, animals, kits, roles, bodyCount });
  });
  if (hex > 0xc00) throw new Error("set serials overflow their range");
  return { R, sets };
}

// ---- render -------------------------------------------------------------------
const lq = (s) => '"' + String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';
const rgbLua = (c) => `Color3.fromRGB(${c[0]}, ${c[1]}, ${c[2]})`;
const kitLua = (kit) => "{ " + Object.entries(kit).map(([s, v]) => `${s} = ${v}`).join(", ") + " }";

function renderSet(S) {
  const m = S.meta;
  const L = [];
  L.push("--[[");
  L.push(`\tSetPets/${pascal(m.key)} -- ${m.name} (grade ${m.grade}), set ${S.index} of 19.`);
  L.push("\tGENERATED by tools/gen/set-pets.js from tools/gen/sets/" + m.key + ".json;");
  L.push("\tedit those, not this. Names are save data: never rename one without an alias.");
  L.push("]]");
  L.push("return {");
  L.push(`\tKEY = ${lq(m.key)},`);
  L.push(`\tNAME = ${lq(m.name)},`);
  L.push(`\tGRADE = ${lq(m.grade)},`);
  L.push(`\tINDEX = ${S.index},`);
  L.push(`\tPOWER = ${round4(S.mult)},`);
  L.push(`\tPACKS = { ${m.packs.map(lq).join(", ")} },`);
  L.push(`\tCOUNTS = { ${TIERS.map((t, i) => `${t} = ${m.counts[i]}`).join(", ")} },`);
  L.push(`\tBUFFS = { ${S.data.buffs.map(lq).join(", ")} },`);
  L.push("\tPETS = {");
  for (const p of S.pets) L.push(`\t\t{ name = ${lq(p.name)}, hex3 = ${lq(p.hex3)}, animal = ${lq(p.animal)}, tier = ${lq(p.tier)}, set = ${lq(p.set)} },`);
  L.push("\t},");
  L.push("\tANIMALS = {");
  for (const p of S.pets) {
    const s = S.animals[p.animal];
    const parts = [`species = ${lq(s.species)}`, `tint = ${rgbLua(s.rgb)}`];
    if (s.glow) parts.push(`glow = ${rgbLua(s.glow)}`);
    if (s.material) parts.push(`material = Enum.Material.${s.material}`);
    if (s.reflect) parts.push(`reflect = ${s.reflect}`);
    if (s.transparency) parts.push(`transparency = ${s.transparency}`);
    if (s.chroma) parts.push("chroma = true");
    L.push(`\t\t[${lq(p.animal)}] = { ${parts.join(", ")} },`);
  }
  L.push("\t},");
  L.push("\tKITS = {");
  for (const p of S.pets) L.push(`\t\t[${lq(p.name)}] = ${kitLua(S.kits[p.name])},`);
  L.push("\t},");
  L.push("\tROLE = {");
  for (const p of S.pets) L.push(`\t\t[${lq(p.name)}] = ${lq(S.roles[p.name])},`);
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
  L.push("# Set pets: the names sheet");
  L.push("");
  L.push("GENERATED by `tools/gen/set-pets.js`; do not edit by hand. The game reads");
  L.push("`src/ReplicatedStorage/Mine/Shared/SetPets/`. Boosts are at Normal, power level 1.");
  L.push("");
  L.push("Owner, 2026-10-10: 19 exclusive sets, every pet named; each set's pets +5% over");
  L.push("the set before, set 1 at zone 1's level. Mythic, Divine and Exotic carry the set's");
  L.push("own buff set; the rest take a role from their body.");
  L.push("");
  L.push("| # | set | grade | power | pets | buff set | bodies |");
  L.push("|---|---|---|---|---|---|---|");
  for (const S of B.sets) {
    L.push(`| ${S.index} | ${S.meta.name} | ${S.meta.grade} | ×${S.mult.toFixed(2)} | ${S.pets.length} | ${S.data.buffs.map((s) => G.stats[s].label).join(", ")} | ${S.data.bodies.map((b) => b.label).join(", ")} |`);
  }
  for (const S of B.sets) {
    L.push("");
    L.push(`## ${S.index}. ${S.meta.name} (${S.meta.grade}, ×${S.mult.toFixed(2)})`);
    L.push("");
    L.push(`Packs: ${S.meta.packs.join(" · ")}`);
    L.push("");
    L.push("| tier | name | looks like | role | boost |");
    L.push("|---|---|---|---|---|");
    for (const p of S.pets) L.push(`| ${p.tier} | ${p.name} | ${p.animal} | ${S.roles[p.name]} | ${fmt(S.kits[p.name], p.tier)} |`);
  }
  return L.join("\n") + "\n";
}

function outputs(B) {
  const files = B.sets.map((S) => [OUT_DIR + pascal(S.meta.key) + ".luau", renderSet(S)]);
  files.push([OUT_MD, renderMd(B)]);
  return files;
}

function main() {
  const B = build();
  const check = process.argv.includes("--check");
  let stale = 0;
  if (!check) fs.mkdirSync(path.join(ROOT, OUT_DIR), { recursive: true });
  for (const [rel, text] of outputs(B)) {
    const abs = path.join(ROOT, rel);
    const have = fs.existsSync(abs) ? fs.readFileSync(abs, "utf8").replace(/\r\n/g, "\n") : null;
    if (check) { if (have !== text) { console.log("STALE  " + rel); stale++; } }
    else fs.writeFileSync(abs, text);
  }
  const total = B.sets.reduce((a, S) => a + S.pets.length, 0);
  console.log(`${total} set pets in ${B.sets.length} sets${check ? "" : " written"}`);
  if (check && stale) process.exit(1);
}

module.exports = { build, outputs, renderSet, pascal, HEX_START, SET_STEP, OUT_DIR, OUT_MD };
if (require.main === module) main();
