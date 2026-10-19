#!/usr/bin/env node
// HOLIDAY PETS: the Halloween 2026 Pack's 60 pets (owner, 2026-10-10), the
// twelve more on new bodies (owner, 2026-10-19), and the battle pass's four.
//
//   "make it 60 halloween pets [keep the specaltiy ones as as rare ones, and for
//    the others just make them normal cards with a costume {simple shit like a
//    dog costume on or something}]"
//   Rarities: costumes Common 20 / Uncommon 15 / Rare 10; the 15 Halloween
//   bodies Epic 6 / Legendary 4 / Mythic 2 / Divine 2 / Exotic 1.
//   Power: Event Horizon's level (zone 11 on the ladder).
//
// Owner, 2026-10-19 (wiki/open-questions.md, Candy Crypt v2):
//   * "12 more, new bodies": a pack's `extraPets`, each on a body still to be
//     built in Studio. Until its PetBodies module exists the pet wears its
//     `fallback` Halloween body (PetModelFactory reads `fallback`), so every
//     pet builds today. Their serials come after every pack's own pets.
//   * "Halloween Mythic+ pets ... 20% better than the best normal ones, even
//     after the event": a pack's `topBeat`. Each Mythic, Divine and Exotic is
//     lifted to topBeat[tier] x the best non-Halloween pet's score
//     (MineCards.boostScore at Normal, power level 1: kit points x
//     RARITY_MULT). The best is re-read from the zone and set generators on
//     every run, so a stronger normal pet makes this output stale and a
//     regenerate lifts the Halloween pets over it again.
//   * "some ... influence builds that wouldn't be possible without the pets":
//     an extra pet's `kit` spends its whole budget on the shares it names,
//     with no calm pass, and may carry MineStats.NAMED_PET_OK (blastRadius).
//
// Holiday rule ("only allow it from {Holiday} {year} Pack"): every pet here is
// stamped `holiday`, so no pot, wheel, lucky block or set pack ever rolls one;
// only the holiday pack itself may.
//
// Inputs:  tools/gen/holiday/<key>.json
//          PetModelFactory and PetBodies/ (species, season tags, cos_* costumes)
//          the zone and set generators (names, skins, tints and kits already taken)
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
// A lifted kit rounds UP, so "at least topBeat x the best" survives rounding.
const ceil4 = (v) => Math.ceil(v * 10000 - 1e-9) / 10000;
const nameKey = (n) => n.toLowerCase().replace(/s$/, "");
const lq = (s) => '"' + String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';
const rgbLua = (c) => `Color3.fromRGB(${c[0]}, ${c[1]}, ${c[2]})`;
const kitLua = (kit) => "{ " + Object.entries(kit).map(([s, v]) => `${s} = ${v}`).join(", ") + " }";

// ---- read the game ----------------------------------------------------------
// Every body in a PetBodies module: `S.<id> = { label = "...", season = "..." ...`,
// the header fields read up to its build function (a module may put the season
// after the label, unlike the factory's own fixed layout).
function bodiesIn(src) {
  const out = {};
  const starts = [...src.matchAll(/\bS\.(\w+)\s*=\s*\{/g)].map((m) => ({ id: m[1], at: m.index }));
  starts.forEach((s, i) => {
    let head = src.slice(s.at, i + 1 < starts.length ? starts[i + 1].at : src.length);
    const b = head.search(/\bbuild\s*=/);
    if (b > 0) head = head.slice(0, b);
    const label = head.match(/\blabel\s*=\s*"([^"]+)"/);
    const season = head.match(/\bseason\s*=\s*"(\w+)"/);
    if (label) out[s.id] = { label: label[1], season: season ? season[1] : null, module: true };
  });
  return out;
}

function readGame() {
  const pmf = read(SHARED + "PetModelFactory.luau");
  const species = {};
  // PetBodies first: the factory loads them after its own and never overwrites an id.
  const bodyDir = path.join(ROOT, SHARED, "PetBodies");
  for (const f of fs.existsSync(bodyDir) ? fs.readdirSync(bodyDir).sort() : []) {
    if (f.endsWith(".luau")) Object.assign(species, bodiesIn(read(SHARED + "PetBodies/" + f)));
  }
  for (const m of pmf.matchAll(/\nS\.(\w+) = \{\n\tlabel = "([^"]+)",\n(\tseason = "(\w+)",\n)?/g)) {
    species[m[1]] = { label: m[2], season: m[4] || null };
  }
  const costumes = new Set([...pmf.matchAll(/\nD\.(cos_\w+) = function/g)].map((m) => m[1]));
  const statsSrc = read(SHARED + "MineStats.luau");
  const namedOk = new Set((((statsSrc.match(/MineStats\.NAMED_PET_OK = \{[\s\S]*?\}/) || [""])[0]).match(/(\w+) = true/g) || [])
    .map((x) => x.split(" ")[0]));
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
  return { species, costumes, namedOk, takenNames, takenAnimals, tintsBy, G: Z.G, Z, S };
}

function roleOf(sp) {
  for (const [role, r] of Object.entries(ROLES)) if (r.species.includes(sp)) return role;
  return null;
}

// The colour for one pet: the first of the palette (walked from a per-pet
// start) that no skin on any of these bodies is near. Two pets on one body
// never share a colour; neither does a holiday pet with any pet already in the
// game. A pet on a planned body checks its fallback body too, since that is
// the body it wears until the new one is built.
// `skip(name)`, when given, rules a colour out by its name ("Bone" on a Bone
// Dragon would read "Bone Bone Dragon").
function pickColour(palette, bodies, seed, tintsBy, skip) {
  const lists = [].concat(bodies).map((sp) => tintsBy[sp] || (tintsBy[sp] = []));
  const start = fnv(seed) % palette.length;
  for (const minD of [40, 24, 12]) {
    for (let k = 0; k < palette.length; k++) {
      const c = palette[(start + k) % palette.length];
      const rgb = c.slice(1);
      if (skip && skip(c[0])) continue;
      if (lists.every((taken) => taken.every((t) => dist(t, rgb) >= minD))) {
        lists.forEach((taken) => taken.push(rgb));
        return { name: c[0], rgb };
      }
    }
  }
  throw new Error("no free colour on " + [].concat(bodies).join("/"));
}

// Points -> a kit, like zone-pets' pointsKit, but a stat in `allow` (MineStats.
// NAMED_PET_OK) may pass the ban, and `round` picks the rounding.
function kitOfPoints(pts, R, allow, round) {
  const kit = {};
  for (const [stat, v] of Object.entries(pts)) {
    if (BANNED.has(stat) && !(allow && allow.has(stat))) throw new Error("banned stat " + stat);
    const w = R.G.stats[stat] && R.G.stats[stat].weight;
    if (!w) throw new Error("no MineStats weight for " + stat);
    kit[stat] = (round || round4)(v / w / 100);
  }
  return kit;
}

// A pet's kit from its plan (stats and their shares of the primary) and its
// primary points per unit of card power, after the calm pass's weakening.
function kitFromPlan(plan, P, R, round) {
  const pts = {};
  plan.statsUsed.forEach((stat, i) => { pts[stat] = (pts[stat] || 0) + P * plan.shares[i]; });
  return kitOfPoints(Zone.weakenPoints(pts, plan.statsUsed), R, null, round);
}

// What a kit is worth on MineCards.boostScore at Normal, power level 1.
const scoreOf = (kit, tier, R) =>
  Object.entries(kit).reduce((a, [s, v]) => a + v * 100 * R.G.stats[s].weight, 0) * R.G.rarityMult[tier];

// ---- build ------------------------------------------------------------------
function buildOne(d, R, hexFrom) {
  const mult = Math.pow(ZONE_STEP, d.zoneLevel - 1);
  for (const sp of d.specials) {
    const s = R.species[sp.body];
    if (!s) throw new Error(`${d.key}: special body ${sp.body} is not a species`);
    // `anyBody`: a pack that is not a holiday (the battle pass's season pets,
    // 2026-10-16) may dress any everyday body, but never a holiday one.
    if (d.anyBody) {
      if (s.season) throw new Error(`${d.key}: ${sp.body} is a holiday body`);
    } else if (!s.season || s.season.toLowerCase() !== d.holiday) {
      throw new Error(`${d.key}: ${sp.body} is not a ${d.holiday} body`);
    }
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

  const pets = [], animals = {}, kits = {}, roles = {}, plans = {}, builds = {};
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
    // The calm pass (zone-pets.js calmProcs), as for every other pet.
    statsUsed = Zone.calmProcs(name, statsUsed, { keepAll: TOP.has(tier), plain: d.buffs.filter((s) => !SetGen.PROC_OF[s]) });
    plans[name] = { statsUsed, shares };
    kits[name] = kitFromPlan(plans[name], (LADDER[tier] / R.G.rarityMult[tier]) * mult, R);
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
  return { meta: d, mult, pets, animals, kits, roles, plans, builds, usedAnimals, names: names.length, extras: [] };
}

/*
  THE BEST NORMAL PET: the highest MineCards.boostScore at Normal, power level 1,
  over every named pet that is not a Halloween pet: the zone pots (with the
  original roster dealt into them), Event Horizon, the older holiday pets, the
  19 sets and every other holiday pack (the battle pass). The game reads the
  same kits (MinePetBoosts: a zone kit first, then a set's).
*/
function bestNormal(R, packs) {
  const { Z, S } = R;
  const rows = [];
  for (const p of Z.pets) rows.push({ name: p.name, tier: p.tier, kit: Z.kits[p.name] });
  for (const p of Z.ehPets) rows.push({ name: p.name, tier: p.tier, kit: Z.kits[p.name] });
  for (const h of Z.holiday) if (h.holiday !== "halloween") rows.push({ name: h.name, tier: h.tier, kit: Z.kits[h.name] });
  for (const s of S.sets) for (const p of s.pets) rows.push({ name: p.name, tier: p.tier, kit: s.kits[p.name] });
  for (const H of packs) if (H.meta.holiday !== "halloween") for (const p of H.pets) rows.push({ name: p.name, tier: p.tier, kit: H.kits[p.name] });
  let best = null;
  for (const r of rows) {
    if (!r.kit) throw new Error("no kit for " + r.name);
    const score = scoreOf(r.kit, r.tier, R);
    if (!best || score > best.score + 1e-9) best = { name: r.name, tier: r.tier, score };
  }
  return best;
}

// Mythic, Divine and Exotic pets of a pack with `topBeat`, lifted to their
// share of the rule. Same stats and shares; only the budget moves.
function liftTop(H, R, best) {
  const beat = H.meta.topBeat;
  for (const p of H.pets) {
    if (!TOP.has(p.tier)) continue;
    if (!(beat[p.tier] >= 1.2)) throw new Error(`${H.meta.key}: topBeat.${p.tier} must be at least 1.2 (owner: 20% better)`);
    const P = (beat[p.tier] * best.score) / (1.5 * R.G.rarityMult[p.tier]);
    H.kits[p.name] = kitFromPlan(H.plans[p.name], P, R, ceil4);
  }
}

/*
  THE EXTRA PETS (owner, 2026-10-19: "12 more, new bodies"). Each names its
  own name, tier, body, label and fallback. A Mythic+ extra spends the topBeat
  budget on its `kit` shares (a build); the rest take a role like the specials.
*/
function addExtras(H, R, best, hexFrom, nameKeys) {
  const d = H.meta;
  let hex = hexFrom;
  const seenBodies = new Set();
  for (const e of d.extraPets || []) {
    const tag = `${d.key} extra ${e.name}`;
    if (!TIERS.includes(e.tier)) throw new Error(`${tag}: unknown tier ${e.tier}`);
    // The name: new, 1-2 words, at most 16 characters, and no plural or case
    // twin of any pet in the game or any name a pack's list could still deal.
    const k = nameKey(e.name);
    if (e.name.length > 16 || e.name.split(" ").length > 2) throw new Error(`${tag}: name too long`);
    if (nameKeys.has(k)) throw new Error(`${tag}: name is taken`);
    nameKeys.add(k);
    // The body: built (a season-tagged species of this holiday) or planned.
    if (seenBodies.has(e.body)) throw new Error(`${tag}: body ${e.body} is used twice`);
    seenBodies.add(e.body);
    const built = R.species[e.body];
    if (built && (!built.season || built.season.toLowerCase() !== d.holiday)) throw new Error(`${tag}: ${e.body} exists and is not a ${d.holiday} body`);
    const fb = R.species[e.fallback];
    if (!fb || !fb.season || fb.season.toLowerCase() !== d.holiday) throw new Error(`${tag}: fallback ${e.fallback} is not a ${d.holiday} body`);
    // The look's name is the JSON label, built body or not: a minted card
    // stores its `animal`, so building the body must not rename it.
    const label = e.label;
    if (built && built.label !== label) throw new Error(`${tag}: body ${e.body} is labelled "${built.label}", the pet wants "${label}"`);
    const words = new Set(label.toLowerCase().split(" "));
    const col = pickColour(d.spookyPalette, [e.body, e.fallback], d.key + ":" + e.body, R.tintsBy,
      (cname) => cname.toLowerCase().split(" ").some((w) => words.has(w)));
    const animal = `${col.name} ${label}`;
    if (R.takenAnimals.has(animal) || H.usedAnimals.has(animal)) throw new Error(`${tag}: look "${animal}" is taken`);
    H.usedAnimals.add(animal);
    H.animals[animal] = built ? { species: e.body, rgb: col.rgb } : { species: e.body, rgb: col.rgb, fallback: e.fallback };
    if (hex > HEX_END) throw new Error("holiday serials overflow their range");
    const pet = { name: e.name, hex3: (hex++).toString(16).padStart(3, "0"), animal, tier: e.tier, set: d.key, holiday: d.holiday,
      species: e.body, extra: true, built: !!built, fallback: e.fallback, label };
    H.pets.push(pet);
    H.extras.push(pet);
    if (TOP.has(e.tier)) {
      if (!e.kit) throw new Error(`${tag}: a Mythic+ extra names its kit`);
      const sum = Object.values(e.kit).reduce((a, b) => a + b, 0);
      if (Math.abs(sum - 1) > 1e-9) throw new Error(`${tag}: kit shares sum to ${sum}, not 1`);
      const total = (d.topBeat[e.tier] * best.score) / R.G.rarityMult[e.tier];
      const pts = {};
      for (const [stat, share] of Object.entries(e.kit)) pts[stat] = total * share;
      H.kits[e.name] = kitOfPoints(pts, R, R.namedOk, ceil4);
      H.roles[e.name] = e.build ? e.build + " build" : d.name;
      if (e.build) H.builds[e.name] = e.build;
    } else {
      if (!ROLES[e.role]) throw new Error(`${tag}: unknown role ${e.role}`);
      const r = ROLES[e.role];
      const pairs = r.pairs.concat(e.tier !== "Common" && e.tier !== "Uncommon" && r.rarePlus ? r.rarePlus : []);
      let statsUsed = SetGen.fitToSet(pairs[fnv(e.name) % pairs.length], d.buffs);
      statsUsed = Zone.calmProcs(e.name, statsUsed, { plain: d.buffs.filter((s) => !SetGen.PROC_OF[s]) });
      H.plans[e.name] = { statsUsed, shares: [1, SECONDARY] };
      H.kits[e.name] = kitFromPlan(H.plans[e.name], (LADDER[e.tier] / R.G.rarityMult[e.tier]) * H.mult, R);
      H.roles[e.name] = e.role;
    }
  }
  return hex;
}

function build() {
  const R = readGame();
  const files = fs.readdirSync(path.join(ROOT, IN_DIR)).filter((f) => f.endsWith(".json")).sort();
  const packs = [];
  // Every pack's own pets first, serials in file order from HEX_START, so a
  // pack's extras never move another pack's serials.
  let hex = HEX_START;
  for (const f of files) {
    const d = JSON.parse(read(IN_DIR + f));
    const H = buildOne(d, R, hex);
    hex += H.pets.length;
    packs.push(H);
  }
  const best = bestNormal(R, packs);
  const nameKeys = new Set([...R.takenNames, ...packs.flatMap((H) => H.pets.map((p) => p.name).concat(H.meta.names || []))].map(nameKey));
  for (const H of packs) {
    if (H.meta.topBeat) liftTop(H, R, best);
    if (H.meta.extraPets) {
      if (!H.meta.topBeat && H.meta.extraPets.some((e) => TOP.has(e.tier))) throw new Error(`${H.meta.key}: Mythic+ extras need a topBeat`);
      hex = addExtras(H, R, best, hex, nameKeys);
    }
  }
  return { R, packs, best };
}

// ---- render -----------------------------------------------------------------
function renderModule(H, best) {
  const d = H.meta;
  const L = [];
  L.push("--[[");
  L.push(`\tHolidayPets/${pascal(d.key)} -- the ${d.packName || d.name}'s pets.`);
  L.push(`\tGENERATED by tools/gen/holiday-pets.js from ${IN_DIR}${d.key}.json;`);
  L.push("\tedit those, not this. Names are save data: never rename one without an alias.");
  L.push("");
  if (d.packId) {
    L.push("\tHoliday rule (owner): these pets come ONLY from this pack. Every row");
    L.push("\tcarries `holiday`, which every random roll skips.");
  } else {
    L.push("\tNo pack sells these. They come ONLY from where the game grants them by");
    L.push("\tname (the battle pass), and every row carries `holiday`, which every");
    L.push("\trandom roll skips.");
  }
  if (d.topBeat) {
    L.push("");
    L.push("\tTOP_BEAT (owner, 2026-10-19: Mythic+ \"20% better than the best normal");
    L.push("\tones, even after the event\"): each Mythic, Divine and Exotic here scores");
    L.push("\tat least TOP_BEAT[tier] x BEST_NORMAL.score on MineCards.boostScore at");
    L.push("\tNormal, power level 1. A stronger normal pet makes this file stale.");
  }
  if (H.extras.length) {
    L.push("");
    L.push("\tThe last pets (owner, 2026-10-19: \"12 more, new bodies\") wear bodies");
    L.push("\tstill to be built in Studio; an ANIMALS row with `fallback` wears that");
    L.push("\tHalloween body until its own exists (PetModelFactory). BUILD names the");
    L.push("\tbuild a pet makes possible (MineHalloweenPets.buildOf).");
  }
  L.push("]]");
  L.push("return {");
  L.push(`\tKEY = ${lq(d.key)},`);
  L.push(`\tNAME = ${lq(d.name)},`);
  L.push(`\tHOLIDAY = ${lq(d.holiday)},`);
  // A pack id only where a pack sells them: MineSetPacks lists every PACK_ID.
  if (d.packId) {
    L.push(`\tPACK_ID = ${lq(d.packId)},`);
    L.push(`\tPACK_NAME = ${lq(d.packName)},`);
  }
  L.push(`\tPOWER = ${round4(H.mult)},`);
  if (d.topBeat) {
    L.push(`\tTOP_BEAT = { ${["Mythic", "Divine", "Exotic"].map((t) => `${t} = ${d.topBeat[t]}`).join(", ")} },`);
    L.push(`\tBEST_NORMAL = { name = ${lq(best.name)}, tier = ${lq(best.tier)}, score = ${round4(best.score)} },`);
  }
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
    if (s.fallback) parts.push(`fallback = ${lq(s.fallback)}`);
    L.push(`\t\t[${lq(p.animal)}] = { ${parts.join(", ")} },`);
  }
  L.push("\t},");
  L.push("\tKITS = {");
  for (const p of H.pets) L.push(`\t\t[${lq(p.name)}] = ${kitLua(H.kits[p.name])},`);
  L.push("\t},");
  L.push("\tROLE = {");
  for (const p of H.pets) L.push(`\t\t[${lq(p.name)}] = ${lq(H.roles[p.name])},`);
  L.push("\t},");
  if (Object.keys(H.builds).length) {
    L.push("\tBUILD = {");
    for (const p of H.pets) if (H.builds[p.name]) L.push(`\t\t[${lq(p.name)}] = ${lq(H.builds[p.name])},`);
    L.push("\t},");
  }
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
    const own = H.pets.filter((p) => !p.extra);
    L.push("");
    L.push(`## ${d.packName} (${H.pets.length} pets, power ×${H.mult.toFixed(2)})`);
    L.push("");
    L.push(`Owner: ${d.note}`);
    if (d.extraNote) {
      L.push("");
      L.push(d.extraNote);
    }
    if (d.topBeat) {
      L.push("");
      L.push(d.topNote);
      L.push("");
      L.push(`The best normal pet is **${B.best.name}** (${B.best.tier}), score **${B.best.score.toFixed(1)}**.`);
      L.push("");
      L.push("| tier | rule | Halloween score | × the best normal pet |");
      L.push("|---|---|---|---|");
      for (const t of ["Mythic", "Divine", "Exotic"]) {
        const mine = H.pets.filter((p) => p.tier === t).map((p) => scoreOf(H.kits[p.name], t, B.R));
        if (!mine.length) continue;
        const lo = Math.min(...mine);
        L.push(`| ${t} | ${d.topBeat[t]}× | ${lo.toFixed(1)} to ${Math.max(...mine).toFixed(1)} | ${(lo / B.best.score).toFixed(3)} or more |`);
      }
    }
    L.push("");
    L.push(`Also pays the older ${d.holiday} pets: ${d.legacy.join(", ")}.`);
    L.push("");
    L.push("| tier | name | looks like | role | boost |");
    L.push("|---|---|---|---|---|");
    for (const t of TIERS.slice().reverse()) {
      for (const p of own.filter((x) => x.tier === t)) {
        L.push(`| ${p.tier} | ${p.name} | ${p.animal} | ${H.roles[p.name]} | ${fmt(H.kits[p.name], p.tier)} |`);
      }
    }
    if (H.extras.length) {
      L.push("");
      L.push(`### ${H.extras.length} more on new bodies`);
      L.push("");
      L.push("A body marked *to build* is a Cursor job (`tools/cursor/tasks/halloween-pet-bodies.md`); until then the pet wears the fallback.");
      L.push("");
      L.push("| tier | name | looks like | body | build or role | boost |");
      L.push("|---|---|---|---|---|---|");
      for (const t of TIERS.slice().reverse()) {
        for (const p of H.extras.filter((x) => x.tier === t)) {
          const body = p.built ? `\`${p.species}\`` : `\`${p.species}\` *to build* (wears \`${p.fallback}\`)`;
          L.push(`| ${p.tier} | ${p.name} | ${p.animal} | ${body} | ${H.builds[p.name] ? "**" + H.builds[p.name] + "**" : H.roles[p.name]} | ${fmt(H.kits[p.name], p.tier)} |`);
        }
      }
      const blurbs = (d.extraPets || []).filter((e) => e.blurb);
      if (blurbs.length) {
        L.push("");
        L.push("**The builds.**");
        L.push("");
        for (const e of blurbs) L.push(`- **${e.build}** (${e.name}): ${e.blurb}`);
      }
    }
  }
  return L.join("\n") + "\n";
}

function outputs(B) {
  const out = B.packs.map((H) => [OUT_DIR + pascal(H.meta.key) + ".luau", renderModule(H, B.best)]);
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
  console.log(`${n} holiday pets in ${B.packs.length} pack(s) written; best normal pet ${B.best.name} (${B.best.tier}) ${B.best.score.toFixed(1)}`);
}

module.exports = { build, outputs, renderModule, pascal, scoreOf, bodiesIn, HEX_START, HEX_END, OUT_DIR, OUT_MD, TOP };
if (require.main === module) main();
