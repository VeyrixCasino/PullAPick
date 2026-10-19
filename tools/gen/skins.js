#!/usr/bin/env node
//[[ GENERATES src/ReplicatedStorage/Mine/Shared/MineSkins.luau
//
// The 225 skins' NAMES, SETS and TIERS are not typed here -- they are parsed
// out of docs/SKINS.md, which is the roster the owner approved. One source of
// truth: rename a skin in the doc and it is renamed in the game.
//
// What this file owns is the arithmetic the doc describes:
//
//   budget      points per tier, F 80 -> SSS 500
//   WEIGHT      skins' OWN prices, read by nothing else (see the doc for why)
//   spread      no stat over 40% of budget, none under 10%
//
// Kits are DETERMINISTIC: the seed is the skin's own name, so regenerating
// produces byte-identical output and a skin's stats never shift under a player
// who already owns it. That is the whole reason this is a generator and not a
// roll at runtime.
//
// Run: node tools/gen/skins.js
const fs = require("fs"), path = require("path");
const ROOT = path.join(__dirname, "..", "..");
const DOC = path.join(ROOT, "docs", "SKINS.md");
const OUT = path.join(ROOT, "src", "ReplicatedStorage", "Mine", "Shared", "MineSkins.luau");

// ---------------------------------------------------------------------------
// The numbers from the doc. Change them THERE first -- the doc is what the
// owner reads -- then here.
// ---------------------------------------------------------------------------
const TIERS = ["F", "D", "C", "B", "A", "S", "SS", "SSS"];
const BUDGET = { F: 80, D: 105, C: 135, B: 175, A: 225, S: 290, SS: 380, SSS: 500 };
const BASE   = { F: 1.15, D: 1.35, C: 1.60, B: 1.90, A: 2.30, S: 3.00, SS: 4.00, SSS: 5.50 };
const SLOTS  = { F: 2, D: 2, C: 3, B: 3, A: 4, S: 4, SS: 5, SSS: 5 };

//[[ A SET'S EDGE: how much better its skins of a grade are than every other
// skin of that grade, on both halves of a skin -- the damage base AND the buff
// budget. Owner, 2026-10-19: Halloween Mythic+ "pets and skins are 20% better
// than the best normal ones, even after the event" ("20%"). Skins' Mythic+ is
// S, SS and SSS (MineTemper.WORD_OF); every other skin of a grade shares one
// BASE and one BUDGET, so 1.2 x the grade's is 20% over the best of them.
// No seasonal gate: the edge stays when the event ends.
const EDGE = {
  halloween: { S: 1.2, SS: 1.2, SSS: 1.2 },
};
const edgeOf = (skin) => (EDGE[skin.set] && EDGE[skin.set][skin.tier]) || 1;

// Skins' own prices. NOT MineStats.STATS -- see the doc: editing those moves
// runes, gear, traits, the tree and pets all at once.
const WEIGHT = {
  oreLuck: 2.6, chestLuck: 2.6, packLuck: 2.6,
  swingRate: 2.4,
  rareOre: 1.6,
  gemFind: 1.5,
  procPower: 1.4,
  blastChance: 1.3, zap: 1.3, tidalWave: 1.3,
  blastDamage: 1.2, tideDamage: 1.2, zapDamage: 1.2, shatterDamage: 1.2,
  earthquake: 1.2, ricochet: 1.2, fossilFind: 1.2,
  pulverize: 1.1,
  dirtBreak: 1.0, oreHaul: 1.0,
  coinBonus: 0.9,
};

// The spread rule. Without it every serious player hunts one skin.
const MAX_SHARE = 0.40, MIN_SHARE = 0.10;

// Each set leans on its own stats so a set reads as a build. First two are the
// identity; the rest is the pool it draws filler from.
const LEAN = {
  toybox:       ["packLuck", "chestLuck", "oreLuck"],
  cursed:       ["procPower", "shatterDamage", "rareOre"],
  pharaohs_tomb:["gemFind", "coinBonus", "oreLuck"],
  wasteland:    ["oreHaul", "pulverize", "dirtBreak"],
  clockwork:    ["swingRate", "ricochet", "earthquake"],
  carnival:     ["packLuck", "fossilFind", "coinBonus"],
  atomic_age:   ["blastDamage", "zap", "zapDamage"],
  arcade:       ["swingRate", "procPower", "blastChance"],
  halloween:    ["tidalWave", "tideDamage", "fossilFind"],
  season_one_pass: ["oreHaul", "chestLuck", "rareOre"],
};
const POOL = Object.keys(WEIGHT);

// ---------------------------------------------------------------------------
const slug = (s) => s.toLowerCase().replace(/['’]/g, "").replace(/[^a-z0-9]+/g, "_").replace(/^_|_$/g, "");

function parseRoster() {
  const md = fs.readFileSync(DOC, "utf8");
  const roster = md.slice(0, md.indexOf("## Numbers"));
  const out = [];
  let set = null, bonus = false, pass = false;
  for (const line of roster.split(/\r?\n/)) {
    const h = line.match(/^## (?:\d+\. )?(.+?)(?: \*|$)/);
    if (h) {
      // A "Pass set" (2026-10-16) is a bonus set that only the battle pass
      // grants: every random pool skips it (MineSkins.isPass).
      pass = /^Pass set/.test(h[1]);
      bonus = pass || /^Bonus set/.test(h[1]);
      const name = h[1].replace(/^(Bonus|Pass) set — /, "").trim();
      set = /^(How a skin|Numbers)/.test(name) ? null : { name, key: slug(name), bonus, pass };
      continue;
    }
    const m = line.match(/^\| (F|D|C|B|A|S|SS|SSS) \| (.+?) \|$/);
    if (!m || !set) continue;
    for (const n of m[2].split("·").map((x) => x.trim()).filter(Boolean)) {
      out.push({ name: n, id: slug(n), set: set.key, setName: set.name, bonus: set.bonus, pass: set.pass, tier: m[1] });
    }
  }
  return out;
}

// Deterministic PRNG seeded from the skin's own name.
function rng(seed) {
  let h = 2166136261;
  for (let i = 0; i < seed.length; i++) { h ^= seed.charCodeAt(i); h = Math.imul(h, 16777619); }
  return () => { h += 0x6D2B79F5; let t = h; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
}

//[[ Spend a tier's budget across `slots` stats.
//
// The set's lean stats come first so every skin in a set shares an identity,
// then the rest is drawn from the pool. Shares are dealt descending and clamped
// into [MIN_SHARE, MAX_SHARE], then renormalised so the kit spends its budget
// exactly -- a kit that spends 97% of its points is a kit that quietly costs
// the player 3% of the item.
function buildKit(skin) {
  const r = rng(skin.id);
  const lean = LEAN[skin.set] || [];
  const n = SLOTS[skin.tier];
  const picked = [];
  for (const s of lean) { if (picked.length < n && !picked.includes(s)) picked.push(s); }
  const rest = POOL.filter((s) => !picked.includes(s));
  while (picked.length < n) picked.push(rest.splice(Math.floor(r() * rest.length), 1)[0]);

  //[[ The cap cannot be below an even split.
  //
  // MAX_SHARE is 40%, but a 2-slot F has to put 50% in each -- two shares that
  // sum to 1 cannot both be under 0.4, and clamping anyway just made the loop
  // give up and return 50/50 while the code claimed a 40% cap. So the cap is
  // the looser of the two, stated rather than silently violated. It binds where
  // it is meant to: 4 and 5 slot skins, which is where the one-stat build
  // would otherwise live.
  const cap = Math.max(MAX_SHARE, 1 / n);
  const floor = Math.min(MIN_SHARE, 1 / n);

  // Descending raw shares, so slot 1 reads as the headline.
  let shares = picked.map((_, i) => (1 / (i + 1)) * (0.85 + r() * 0.3));
  let sum = shares.reduce((a, b) => a + b, 0);
  shares = shares.map((s) => s / sum);

  //[[ Clamp by WATER-FILLING, not by clamp-then-renormalise.
  //
  // Renormalising after a clamp divides every share by the new sum, which
  // pushes the clamped one straight back above the cap. It converges toward
  // the cap but never reaches it, so the cap was never actually enforced --
  // six passes still left a 2-slot F at 50.7% against a 50% cap, and the
  // harness caught it.
  //
  // Instead: clamp, then hand the leftover only to the shares that still have
  // room. That terminates and lands exactly on the cap.
  for (let pass = 0; pass < 24; pass++) {
    shares = shares.map((s) => Math.min(cap, Math.max(floor, s)));
    const gap = 1 - shares.reduce((a, b) => a + b, 0);
    if (Math.abs(gap) < 1e-12) break;
    // Who can still move in the direction we need?
    const room = shares.map((s) => (gap > 0 ? cap - s : s - floor));
    const total = room.reduce((a, b) => a + b, 0);
    if (total < 1e-12) break; // every share is pinned; the split is forced
    shares = shares.map((s, i) => s + gap * (room[i] / total));
  }
  const budget = BUDGET[skin.tier] * edgeOf(skin);
  const kit = {};
  picked.forEach((stat, i) => {
    // points -> amount: points = amount * 100 * weight
    const amount = (budget * shares[i]) / (100 * WEIGHT[stat]);
    kit[stat] = Math.round(amount * 1000) / 1000; // 0.1% resolution
  });
  return kit;
}

const skins = parseRoster();
// Pass sets (2026-10-16) sit outside the 225: only the battle pass grants them.
const coreCount = skins.filter((x) => !x.pass).length;
if (coreCount !== 225) { console.error(`FAIL: parsed ${coreCount} core skins, expected 225`); process.exit(1); }

const lua = [];
lua.push(`--[[`);
lua.push(`\tMineSkins -- GENERATED by tools/gen/skins.js. Do not hand-edit.`);
lua.push(`\tNames, sets and tiers come from docs/SKINS.md; the arithmetic from the generator.`);
lua.push(``);
lua.push(`\tA skin is the damage BASE the ore tool multiplies, plus a buff kit bought`);
lua.push(`\twith a points budget on skins' OWN weights (WEIGHT below) -- never`);
lua.push(`\tMineStats.STATS, because every other budget system divides by those.`);
lua.push(``);
lua.push(`\tOne concept covers all five tool classes: same name, set, tier and kit.`);
lua.push(`]]`);
lua.push(`local MineSkins = {}`);
lua.push(``);
lua.push(`MineSkins.TIERS = { ${TIERS.map((t) => `"${t}"`).join(", ")} }`);
lua.push(`MineSkins.TIER_RANK = { ${TIERS.map((t, i) => `${t} = ${i + 1}`).join(", ")} }`);
lua.push(`MineSkins.BASE = { ${TIERS.map((t) => `${t} = ${BASE[t]}`).join(", ")} }`);
lua.push(`MineSkins.BUDGET = { ${TIERS.map((t) => `${t} = ${BUDGET[t]}`).join(", ")} }`);
lua.push(``);
lua.push(`-- A set's edge over every other skin of a grade, on its base AND its budget`);
lua.push(`-- (owner, 2026-10-19: Halloween Mythic+ skins are 20% better, even after the`);
lua.push(`-- event). Read through MineSkins.edgeOf / MineSkins.baseOf, never BASE alone.`);
lua.push(`MineSkins.EDGE = {`);
for (const [set, row] of Object.entries(EDGE)) lua.push(`\t${set} = { ${TIERS.filter((t) => row[t]).map((t) => `${t} = ${row[t]}`).join(", ")} },`);
lua.push(`}`);
lua.push(``);
lua.push(`-- Skins' own prices. Read by nothing else; see docs/SKINS.md.`);
lua.push(`MineSkins.WEIGHT = {`);
for (const [k, v] of Object.entries(WEIGHT)) lua.push(`\t${k} = ${v},`);
lua.push(`}`);
lua.push(``);
const sets = [...new Map(skins.map((s) => [s.set, s])).values()];
lua.push(`MineSkins.SETS = {`);
for (const s of sets) lua.push(`\t{ key = "${s.set}", name = "${s.setName}", bonus = ${s.bonus}${s.pass ? ", pass = true" : ""} },`);
lua.push(`}`);
lua.push(``);
lua.push(`MineSkins.LIST = {`);
for (const s of skins) {
  const kit = buildKit(s);
  const kitStr = Object.entries(kit).map(([k, v]) => `${k} = ${v}`).join(", ");
  lua.push(`\t{ id = "${s.id}", name = "${s.name}", set = "${s.set}", tier = "${s.tier}", kit = { ${kitStr} } },`);
}
lua.push(`}`);
lua.push(``);
lua.push(`-- Pass sets: only the battle pass grants them, and every random pool skips`);
lua.push(`-- a skin with \`pass\` set (MineSkins.isPass).`);
lua.push(`local passSet = {}`);
lua.push(`for _, set in ipairs(MineSkins.SETS) do`);
lua.push(`\tif set.pass then`);
lua.push(`\t\tpassSet[set.key] = true`);
lua.push(`\tend`);
lua.push(`end`);
lua.push(`MineSkins.BY_ID = {}`);
lua.push(`for _, s in ipairs(MineSkins.LIST) do`);
lua.push(`\tMineSkins.BY_ID[s.id] = s`);
lua.push(`\ts.pass = passSet[s.set] or nil`);
lua.push(`end`);
lua.push(``);
lua.push(`function MineSkins.isPass(skin)`);
lua.push(`\tlocal s = type(skin) == "table" and skin or MineSkins.BY_ID[tostring(skin or "")]`);
lua.push(`\treturn s ~= nil and s.pass == true`);
lua.push(`end`);
lua.push(``);
lua.push(`function MineSkins.byId(id)`);
lua.push(`\treturn MineSkins.BY_ID[tostring(id or "")]`);
lua.push(`end`);
lua.push(``);
lua.push(`-- How much better this skin is than every other skin of its grade (1 for most).`);
lua.push(`function MineSkins.edgeOf(skin)`);
lua.push(`\tlocal s = type(skin) == "table" and skin or MineSkins.byId(skin)`);
lua.push(`\tlocal row = s and MineSkins.EDGE[s.set]`);
lua.push(`\treturn (row and row[s.tier]) or 1`);
lua.push(`end`);
lua.push(``);
lua.push(`function MineSkins.isHalloween(skin)`);
lua.push(`\tlocal s = type(skin) == "table" and skin or MineSkins.BY_ID[tostring(skin or "")]`);
lua.push(`\treturn s ~= nil and s.set == "halloween"`);
lua.push(`end`);
lua.push(``);
lua.push(`-- The base multiplier a skin puts under the ore tool's damage: its grade's,`);
lua.push(`-- times its set's edge.`);
lua.push(`function MineSkins.baseOf(skin)`);
lua.push(`\tlocal s = type(skin) == "table" and skin or MineSkins.byId(skin)`);
lua.push(`\treturn (s and MineSkins.BASE[s.tier] and MineSkins.BASE[s.tier] * MineSkins.edgeOf(s)) or 1`);
lua.push(`end`);
lua.push(``);
lua.push(`-- What a kit cost, on skins' own weights. For the verify harness and the UI.`);
lua.push(`function MineSkins.pointsOf(skin)`);
lua.push(`\tlocal s = type(skin) == "table" and skin or MineSkins.byId(skin)`);
lua.push(`\tif not s then`);
lua.push(`\t\treturn 0`);
lua.push(`\tend`);
lua.push(`\tlocal total = 0`);
lua.push(`\tfor stat, amount in pairs(s.kit or {}) do`);
lua.push(`\t\ttotal += amount * 100 * (MineSkins.WEIGHT[stat] or 1)`);
lua.push(`\tend`);
lua.push(`\treturn total`);
lua.push(`end`);
lua.push(``);
lua.push(`return MineSkins`);
lua.push(``);

fs.writeFileSync(OUT, lua.join("\r\n"), "utf8");
const byTier = {};
for (const s of skins) byTier[s.tier] = (byTier[s.tier] || 0) + 1;
console.log(`wrote ${path.relative(ROOT, OUT)}`);
console.log(`  ${skins.length} skins in ${sets.length} sets`);
console.log(`  ${TIERS.map((t) => `${t}=${byTier[t] || 0}`).join("  ")}`);
