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

const { TIERS, LADDER, ZONE_STEP, ROLES, BANNED, calmProcs, weakenPoints, pointsKit } = Zone;
const TOP = new Set(["Mythic", "Divine", "Exotic"]);
const SET_STEP = ZONE_STEP; // +5% a set, the zones' step
const TOP_SHARES = [1, 0.35, 0.15];
const SECONDARY = 0.5;
const PROC_CHANCE = new Set(["zap", "blastChance", "tidalWave", "ricochet", "earthquake"]);
// Set pets' serial prefixes live in their own range, so a zone pet added later
// (which counts up from the roster) can never collide with one. 0x400-0xBFF
// filled up with the first 2,043; 0xC00-0xCFF is Halloween's (HolidayPets), so
// pets added since (owner, 2026-10-10: "MAKE MORE FUCKING GOOD CARDS") count up
// from 0xD00.
const HEX_START = 0x400;
const HEX_NEW = 0xd00;
const HEX_END = 0x1000;

/*
  WHO MAY BE A RECOLOUR (owner, 2026-10-10): "recolors fore common, uncommon,
  rare. Vastly different colors tho. thats all i will allow", and for the rest
  "ALL UNIQUE".

  - Common, Uncommon and Rare pets share bodies, but two pets on one body must
    be VASTLY different colours: at least RECOLOUR_DE apart in CIELAB (CIE76).
    Zone pets already wearing a shared species count too.
  - Epic and up each wear a body of their own (the set's `topBodies`), worn by
    no other pet in the game.
*/
const RECOLOUR_TIERS = new Set(["Common", "Uncommon", "Rare"]);
const RECOLOUR_DE = 35;
function lab(rgb) {
  const lin = rgb.map((v) => { v /= 255; return v > 0.04045 ? Math.pow((v + 0.055) / 1.055, 2.4) : v / 12.92; });
  const X = (lin[0] * 0.4124 + lin[1] * 0.3576 + lin[2] * 0.1805) / 0.95047;
  const Y = lin[0] * 0.2126 + lin[1] * 0.7152 + lin[2] * 0.0722;
  const Z = (lin[0] * 0.0193 + lin[1] * 0.1192 + lin[2] * 0.9505) / 1.08883;
  const f = (t) => (t > 216 / 24389 ? Math.cbrt(t) : (24389 / 27 * t + 16) / 116);
  return [116 * f(Y) - 16, 500 * (f(X) - f(Y)), 200 * (f(Y) - f(Z))];
}
const deltaE = (a, b) => { const p = lab(a), q = lab(b); return Math.hypot(p[0] - q[0], p[1] - q[1], p[2] - q[2]); };

// The pets already shipped, read back from the generated modules: their names,
// serials and rarities are save data and never move. Looks may change.
function readLock(key) {
  const f = path.join(ROOT, OUT_DIR, pascal(key) + ".luau");
  if (!fs.existsSync(f)) return [];
  // Normalise CRLF so the ROLE block regex matches on Windows checkouts.
  const src = fs.readFileSync(f, "utf8").replace(/\r\n/g, "\n");
  // Each shipped pet's role too: a role is what a Common-to-Legendary kit is
  // built from, and it used to come from the body. New bodies must not quietly
  // change the stats of a pet a player already owns, so the old role is kept.
  const roleOf = {};
  const roleBlock = (src.match(/\n\tROLE = \{\n([\s\S]*?)\n\t\},/) || [])[1] || "";
  for (const m of roleBlock.matchAll(/\["((?:[^"\\]|\\.)*)"\] = "([^"]+)"/g)) {
    roleOf[m[1].replace(/\\(.)/g, "$1")] = m[2];
  }
  const out = [];
  for (const m of src.matchAll(/\{ name = "((?:[^"\\]|\\.)*)", hex3 = "([0-9a-f]{3})", animal = "(?:[^"\\]|\\.)*", tier = "(\w+)"/g)) {
    const name = m[1].replace(/\\(.)/g, "$1");
    out.push({ name, hex3: m[2], tier: m[3], role: roleOf[name] });
  }
  return out;
}

/*
  BUFFS THAT FIT THE SET (owner, 2026-10-10: "given buffs (that make sense)").
  Below Mythic a pet's stats come from its body's role, and a role can carry a
  proc from another theme (every Mystic body zaps, every rare Tidecaller makes
  waves). Such a proc becomes the set's OWN proc; a set with no proc in its buff
  set (Pebblebound, Mosswood...) gets one of its plain buff stats instead, so it
  stays free of flashy effects. Only which stat changes: every stat is still
  priced from the same ladder value, so a pet's power does not move.
*/
const PROC_OF = {
  zap: ["zap", "chance"], zapDamage: ["zap", "damage"],
  blastChance: ["blast", "chance"], blastDamage: ["blast", "damage"],
  tidalWave: ["tide", "chance"], tideDamage: ["tide", "damage"],
  ricochet: ["shatter", "chance"], shatterDamage: ["shatter", "damage"],
  earthquake: ["quake", "chance"],
};
const PROC_STATS = {
  zap: { chance: "zap", damage: "zapDamage" },
  blast: { chance: "blastChance", damage: "blastDamage" },
  tide: { chance: "tidalWave", damage: "tideDamage" },
  shatter: { chance: "ricochet", damage: "shatterDamage" },
  quake: { chance: "earthquake" }, // Earthquake has no damage stat of its own
};
function setProcFamily(buffs) {
  const p = buffs.map((s) => PROC_OF[s]).find((x) => x && x[1] === "chance");
  return p ? p[0] : null;
}
function fitToSet(pair, buffs) {
  const family = setProcFamily(buffs);
  const plain = buffs.filter((s) => !PROC_OF[s]);
  const out = [];
  for (const stat of pair) {
    const p = PROC_OF[stat];
    let next = stat;
    if (p && p[0] !== family) next = family ? PROC_STATS[family][p[1]] || PROC_STATS[family].chance : null;
    if (!next || out.includes(next)) {
      next = plain.find((s) => !out.includes(s) && !pair.includes(s)) || plain.find((s) => !out.includes(s));
    }
    out.push(next);
  }
  return out;
}

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
function readGame(opts) {
  const meta = JSON.parse(read("tools/gen/sets/_sets.json")).sets;
  const data = {};
  const broken = {};
  for (const s of meta) {
    const f = `tools/gen/sets/${s.key}.json`;
    if (!fs.existsSync(path.join(ROOT, f))) throw new Error("missing " + f);
    try {
      data[s.key] = JSON.parse(read(f));
    } catch (e) {
      // --plan runs while several sets are mid-edit: one bad file must not
      // hide every other set's report.
      if (!(opts && opts.plan)) throw e;
      broken[s.key] = "bad JSON: " + e.message;
    }
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
  return { meta, data, broken, species, takenNames, takenAnimals, tintsBy, G: Z.G };
}

// ---- build -------------------------------------------------------------------
function roleOfSpecies(sp, setBodies) {
  const own = setBodies.find((b) => b.id === sp);
  if (own) return own.role;
  for (const [role, r] of Object.entries(ROLES)) if (r.species.includes(sp)) return role;
  return "Striker";
}

/*
  `opts.plan`: do not throw when a set runs short of recolour room or of top
  bodies; count the shortfall instead (node tools/gen/set-pets.js --plan).
*/
function build(opts) {
  opts = opts || {};
  const R = readGame(opts);
  const usedKeys = new Set([...R.takenNames].map(nameKey));
  const usedAnimals = new Set(R.takenAnimals);
  const tintsBy = R.tintsBy;
  let hexNew = HEX_NEW;
  const sets = [];
  const plan = [];

  // Every top body is worn by one pet in the whole game: not a zone species,
  // not another set's, not one of this set's recolour bodies.
  const topOwner = {};
  for (const m of R.meta) {
    for (const b of ((R.data[m.key] || {}).topBodies || [])) {
      if (topOwner[b.id]) throw new Error(`top body ${b.id} is listed by ${topOwner[b.id]} and ${m.key}`);
      topOwner[b.id] = m.key;
    }
  }

  // Locked names first, so a new pet can never take one.
  const locks = {};
  for (const m of R.meta) {
    locks[m.key] = readLock(m.key);
    for (const p of locks[m.key]) usedKeys.add(nameKey(p.name));
  }

  R.meta.forEach((m, idx) => {
    if (!opts.plan) return buildSet(m, idx);
    if (R.broken[m.key]) { plan.push({ key: m.key, error: R.broken[m.key] }); return; }
    try {
      buildSet(m, idx);
    } catch (e) {
      plan.push({ key: m.key, error: e.message });
    }
  });
  function buildSet(m, idx) {
    const d = R.data[m.key];
    const index = idx + 1;
    const mult = Math.pow(SET_STEP, index - 1);
    if (!Array.isArray(d.bodies) || d.bodies.length < 4) throw new Error(m.key + ": needs its own bodies");
    for (const b of d.bodies) {
      if (!R.species[b.id] || !R.species[b.id].setBody) throw new Error(`${m.key}: body ${b.id} has no PetBodies module`);
      if (!ROLES[b.role]) throw new Error(`${m.key}: body ${b.id} has unknown role ${b.role}`);
      if (topOwner[b.id]) throw new Error(`${m.key}: ${b.id} is both a recolour body and a top body`);
    }
    for (const sp of d.extraBodies || []) {
      if (!R.species[sp]) throw new Error(`${m.key}: extra body ${sp} does not exist`);
      if (R.species[sp].season) throw new Error(`${m.key}: extra body ${sp} is a holiday body`);
      if (topOwner[sp]) throw new Error(`${m.key}: ${sp} is both an extra body and a top body`);
    }
    const tops = d.topBodies || [];
    for (const b of tops) {
      if (!R.species[b.id] || !R.species[b.id].setBody) {
        if (opts.plan) continue;
        throw new Error(`${m.key}: top body ${b.id} has no PetBodies module`);
      }
      if (!ROLES[b.role]) throw new Error(`${m.key}: top body ${b.id} has unknown role ${b.role}`);
      if (!TIERS.includes(b.tier) || RECOLOUR_TIERS.has(b.tier)) throw new Error(`${m.key}: top body ${b.id} needs an Epic-or-better tier`);
      if (!Array.isArray(b.tint) || b.tint.length !== 3) throw new Error(`${m.key}: top body ${b.id} needs a tint [r, g, b]`);
      if (tintsBy[b.id] && tintsBy[b.id].length) throw new Error(`${m.key}: top body ${b.id} is already worn by a zone pet`);
    }
    if (!Array.isArray(d.buffs) || d.buffs.length !== 3) throw new Error(m.key + ": needs 3 buffs");
    if (d.buffs.filter((s) => PROC_CHANCE.has(s)).length > 1) throw new Error(m.key + ": more than one proc chance in buffs");
    for (const s of d.buffs) if (BANNED.has(s) || !R.G.stats[s]) throw new Error(`${m.key}: buff ${s} is not a pet stat`);

    // Recolour bodies: the set's own count double, so they lead; a few fitting old ones.
    const weight = {};
    for (const b of d.bodies) weight[b.id] = 2;
    for (const sp of d.extraBodies || []) weight[sp] = 1;
    const recolourBodies = Object.keys(weight);
    const bodyCount = {};

    const names = shuffled([...new Set(d.names)], m.key + ":names").filter((n) => {
      const k = nameKey(n);
      if (usedKeys.has(k) || n.length > 16 || !/^[A-Za-z][A-Za-z' .-]*$/.test(n)) return false;
      usedKeys.add(k);
      return true;
    });
    const palette = d.palette.map((c) => ({ name: c[0], rgb: [c[1], c[2], c[3]] }));
    const lock = locks[m.key];
    let nameAt = 0;
    const pets = [];
    const animals = {};
    const kits = {};
    const roles = {};
    // Buff-rotation index must stay stable across regenerations. Sorting by
    // hex3 keeps every previously shipped Mythic/Divine/Exotic ahead of any
    // newly added one (old serials live in 0x400-0xBFF; new ones start at
    // HEX_NEW), so adding pets never reshuffles an owned pet's buffs. File
    // order alone is not enough: new Mythics sit before old Divines/Exotics.
    const lockedTop = lock
      .filter((p) => TOP.has(p.tier))
      .slice()
      .sort((a, b) => parseInt(a.hex3, 16) - parseInt(b.hex3, 16))
      .map((p) => p.name);
    const topIndexOf = new Map(lockedTop.map((n, i) => [n, i]));
    let newTopK = lockedTop.length;
    const short = { recolour: 0, top: {} };

    TIERS.forEach((tier, ti) => {
      const locked = lock.filter((p) => p.tier === tier);
      if (locked.length > m.counts[ti]) throw new Error(`${m.key}: ${tier} count ${m.counts[ti]} is below the ${locked.length} pets already shipped`);
      const tierTops = tops.filter((b) => b.tier === tier && R.species[b.id]);
      if (!RECOLOUR_TIERS.has(tier) && tierTops.length !== m.counts[ti]) {
        if (opts.plan) short.top[tier] = m.counts[ti] - tierTops.length;
        else throw new Error(`${m.key}: ${tier} has ${m.counts[ti]} pets but ${tierTops.length} top bodies; each needs its own`);
      }
      for (let k = 0; k < m.counts[ti]; k++) {
        const si = pets.length;
        let name, hex3, lockedRole = null;
        if (k < locked.length) {
          name = locked[k].name;
          hex3 = locked[k].hex3;
          lockedRole = locked[k].role || null;
        } else {
          name = names[nameAt++];
          if (!name) {
            if (opts.plan) { short.names = (short.names || 0) + 1; continue; }
            throw new Error(`${m.key}: ran out of names at ${pets.length + 1} of ${m.counts.reduce((a, b) => a + b, 0)}`);
          }
          hex3 = (hexNew++).toString(16).padStart(3, "0");
        }

        let species, skin, animal;
        if (RECOLOUR_TIERS.has(tier)) {
          // The least-worn body that still has a palette colour VASTLY unlike
          // every colour already on it.
          const order = recolourBodies.slice().sort((a, b) =>
            ((bodyCount[a] || 0) / weight[a]) - ((bodyCount[b] || 0) / weight[b]) || fnv(a + si) - fnv(b + si));
          let pick = null;
          for (const sp of order) {
            const label = R.species[sp].label;
            const taken = tintsBy[sp] || [];
            const c = shuffled(palette, m.key + tier + si + sp).find((c) =>
              taken.every((t) => deltaE(t, c.rgb) >= RECOLOUR_DE) && !usedAnimals.has(`${c.name} ${label}`));
            if (c) { pick = c; species = sp; break; }
          }
          if (!pick) {
            if (opts.plan) { short.recolour++; continue; }
            throw new Error(`${m.key}: no room for a ${tier} recolour ${RECOLOUR_DE} dE from every pet on its body; add recolour bodies or palette colours`);
          }
          (tintsBy[species] = tintsBy[species] || []).push(pick.rgb);
          bodyCount[species] = (bodyCount[species] || 0) + 1;
          skin = { species, rgb: pick.rgb };
          animal = `${pick.name} ${R.species[species].label}`;
        } else {
          const body = tierTops[k];
          if (!body) continue; // plan mode: counted above
          species = body.id;
          bodyCount[species] = 1;
          (tintsBy[species] = tintsBy[species] || []).push(body.tint);
          skin = { species, rgb: body.tint };
          const label = R.species[species].label;
          const words = (d.topWords && d.topWords[tier]) || [];
          if (tier === "Epic") {
            animal = label;
            skin.glow = lighten(body.tint, 0.4);
          } else {
            animal = `${words[si % Math.max(1, words.length)] || tier} ${label}`;
            skin.glow = lighten(body.tint, tier === "Legendary" ? 0.5 : 0.45);
            if (tier === "Legendary") skin.reflect = 0.2;
            if (tier === "Mythic") { skin.material = "Glass"; skin.reflect = 0.25; }
            if (tier === "Divine") skin.transparency = 0.2;
            if (tier === "Exotic") skin.chroma = true;
          }
          for (let n = 1; usedAnimals.has(animal); n++) {
            animal = `${words[(si + n) % Math.max(1, words.length)] || tier} ${label}`;
            if (n > 8) throw new Error("animal collision: " + animal);
          }
        }
        if (usedAnimals.has(animal)) throw new Error("animal collision: " + animal);
        usedAnimals.add(animal);
        animals[animal] = skin;

        const pet = { name, hex3, animal, tier, set: m.key, species };
        pets.push(pet);

        // The kit: the approved ladder (lifted), +5% a set.
        const P = (LADDER[tier] / R.G.rarityMult[tier]) * mult;
        const kit = {};
        let statsUsed, shares;
        if (TOP.has(tier)) {
          // A shipped Mythic/Divine/Exotic keeps its place in the buff
          // rotation; new ones continue after the shipped ones, so adding
          // pets never reshuffles an owned pet's buffs.
          const idx = topIndexOf.has(name) ? topIndexOf.get(name) : newTopK++;
          statsUsed = d.buffs.slice(idx % 3).concat(d.buffs.slice(0, idx % 3));
          shares = TOP_SHARES;
          roles[name] = m.name;
        } else {
          // A shipped pet keeps its role (and so its stats); a new pet takes
          // the role its own body suggests.
          const role = (lockedRole && ROLES[lockedRole]) ? lockedRole : roleOfSpecies(species, d.bodies.concat(tops));
          const r = ROLES[role];
          const pairs = r.pairs.concat(tier !== "Common" && tier !== "Uncommon" && r.rarePlus ? r.rarePlus : []);
          statsUsed = fitToSet(pairs[fnv(name) % pairs.length], d.buffs);
          shares = [1, SECONDARY];
          roles[name] = role;
        }
        // The calm pass (zone-pets.js calmProcs): half of the ability pets
        // below Mythic swap it for one of the set's own plain buffs, and the
        // rest keep it a little weaker.
        statsUsed = calmProcs(name, statsUsed, { keepAll: TOP.has(tier), plain: d.buffs.filter((s) => !PROC_OF[s]) });
        const pts = {};
        statsUsed.forEach((stat, i) => { pts[stat] = (pts[stat] || 0) + P * shares[i]; });
        Object.assign(kit, pointsKit(weakenPoints(pts, statsUsed), (s) => R.G.stats[s] && R.G.stats[s].weight));
        kits[name] = kit;
      }
    });
    if (opts.plan) plan.push({ key: m.key, ...short, names: (short.names || 0) });
    sets.push({ meta: m, data: d, index, mult, pets, animals, kits, roles, bodyCount });
  }
  if (hexNew > HEX_END) throw new Error("new set serials overflow 0xD00-0xFFF");
  return { R, sets, plan };
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
  if (process.argv.includes("--plan")) {
    // What each set still needs before it can be written: top bodies by tier,
    // recolour room, names. Writes nothing.
    const B = build({ plan: true });
    const at = process.argv.indexOf("--only");
    const only = at > 0 ? process.argv[at + 1] : null;
    for (const p of B.plan) {
      if (only && p.key !== only) continue;
      if (p.error) { console.log(`${p.key.padEnd(17)} ERROR: ${p.error}`); continue; }
      const tops = Object.entries(p.top).filter(([, n]) => n > 0).map(([t, n]) => `${t} ${n}`).join(", ");
      console.log(`${p.key.padEnd(17)} top bodies short: ${tops || "none"} | recolours with no room: ${p.recolour} | names short: ${p.names}`);
    }
    return;
  }
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

module.exports = { PROC_OF, setProcFamily, fitToSet, build, outputs, renderSet, pascal, HEX_START, HEX_NEW, HEX_END, SET_STEP, OUT_DIR, OUT_MD, RECOLOUR_TIERS, RECOLOUR_DE, deltaE, readLock };
if (require.main === module) main();
