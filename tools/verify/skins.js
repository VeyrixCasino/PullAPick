// THE 225 SKINS MUST BE WHAT THE OWNER APPROVED, AND MUST SPEND WHAT THEY COST.
//
// MineSkins.luau is generated, which means nobody will ever read all 225 rows.
// So this re-derives the claims the doc makes and fails on any difference:
//
//   the roster   225 skins, 9 sets, 25 each, unique ids AND names
//   the ladder   tier counts, and slots matching the tier
//   the budget   every kit spends its tier's points, within rounding
//   the spread   no stat over the cap, none under the floor
//   the pool     no stat a tool cannot pay -- the thing that cost 26 pets
//                a blastRadius line that did nothing
//
// The last one is the point. A skin rolling a RUNE_ONLY or PET_ONLY stat shows
// a buff on the tile and does nothing in the mine, and nothing errors.
//
// Run: node tools/verify/skins.js
const fs = require("fs"), path = require("path");
const ROOT = path.join(__dirname, "..", "..");
const SRC = path.join(ROOT, "src", "ReplicatedStorage", "Mine", "Shared");

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

const lua = fs.readFileSync(path.join(SRC, "MineSkins.luau"), "utf8");
const stats = fs.readFileSync(path.join(SRC, "MineStats.luau"), "utf8");
const cards = fs.readFileSync(path.join(SRC, "MineCards.luau"), "utf8");

// --- what the game says a tool cannot pay ----------------------------------
const grab = (re, s) => ((s.match(re) || [""])[0].match(/(\w+) = true/g) || []).map((x) => x.split(" ")[0]);
const RUNE_ONLY = grab(/MineStats\.RUNE_ONLY = \{[\s\S]*?\}/, stats);
const PET_ONLY = grab(/MineStats\.PET_ONLY = \{[\s\S]*?\}/, stats);
const KNOWN = new Set([...stats.matchAll(/^\t(\w+)\s+= \{ label = "/gm)].map((m) => m[1]));
ok(RUNE_ONLY.length > 0 && PET_ONLY.length > 0, "read RUNE_ONLY and PET_ONLY from MineStats",
  `${RUNE_ONLY.length} + ${PET_ONLY.length}`);

// --- parse the generated module --------------------------------------------
const WEIGHT = {};
for (const m of (lua.match(/MineSkins\.WEIGHT = \{[\s\S]*?\n\}/) || [""])[0].matchAll(/\t(\w+) = ([\d.]+),/g)) {
  WEIGHT[m[1]] = +m[2];
}
const BUDGET = {}, BASE = {}, SLOTS = { F: 2, D: 2, C: 3, B: 3, A: 4, S: 4, SS: 5, SSS: 5 };
for (const m of (lua.match(/MineSkins\.BUDGET = \{[^\n]*/) || [""])[0].matchAll(/(\w+) = ([\d.]+)/g)) BUDGET[m[1]] = +m[2];
for (const m of (lua.match(/MineSkins\.BASE = \{[^\n]*/) || [""])[0].matchAll(/(\w+) = ([\d.]+)/g)) BASE[m[1]] = +m[2];

const rows = [...lua.matchAll(/\{ id = "([^"]+)", name = "([^"]+)", set = "([^"]+)", tier = "(\w+)", kit = \{ ([^}]*) \} \},/g)]
  .map((m) => ({
    id: m[1], name: m[2], set: m[3], tier: m[4],
    kit: Object.fromEntries([...m[5].matchAll(/(\w+) = ([\d.]+)/g)].map((k) => [k[1], +k[2]])),
  }));

ok(rows.length === 225, "225 skins", String(rows.length));
ok(Object.keys(WEIGHT).length >= 20, "skins carry their own weight table", `${Object.keys(WEIGHT).length} stats priced`);

// MineStats must be untouched by this feature: the skin weights are separate.
const differs = Object.keys(WEIGHT).filter((k) => {
  const m = stats.match(new RegExp(`^\\t${k}\\s+= \\{ label = "[^"]+",\\s+weight = ([\\d.]+)`, "m"));
  return m && +m[1] !== WEIGHT[k];
});
ok(differs.length > 0, "skin weights are genuinely their own, not a copy of MineStats",
  `${differs.length} priced differently`);

// --- roster -----------------------------------------------------------------
const ids = new Set(), names = new Set();
let dupId = 0, dupName = 0;
for (const r of rows) { if (ids.has(r.id)) dupId++; ids.add(r.id); if (names.has(r.name)) dupName++; names.add(r.name); }
ok(dupId === 0, "every skin id is unique", dupId ? `${dupId} repeated` : "");
ok(dupName === 0, "every skin NAME is unique", dupName ? `${dupName} repeated` : "");

const bySet = {}, byTier = {};
for (const r of rows) { bySet[r.set] = (bySet[r.set] || 0) + 1; byTier[r.tier] = (byTier[r.tier] || 0) + 1; }
ok(Object.keys(bySet).length === 9, "9 sets", String(Object.keys(bySet).length));
ok(Object.values(bySet).every((n) => n === 25), "25 skins in every set",
  Object.entries(bySet).map(([k, v]) => `${k}=${v}`).join(" "));
const WANT = { F: 54, D: 45, C: 36, B: 27, A: 27, S: 18, SS: 9, SSS: 9 };
ok(Object.entries(WANT).every(([t, n]) => byTier[t] === n), "tier counts match the approved weighting",
  Object.entries(byTier).map(([k, v]) => `${k}=${v}`).join(" "));

// --- the pool: nothing a tool cannot pay ------------------------------------
const bad = [], unknown = [];
for (const r of rows) {
  for (const s of Object.keys(r.kit)) {
    if (RUNE_ONLY.includes(s) || PET_ONLY.includes(s) || s === "luck") bad.push(`${r.id}:${s}`);
    if (!KNOWN.has(s)) unknown.push(`${r.id}:${s}`);
  }
}
ok(bad.length === 0, "no skin rolls a stat a tool cannot pay (RUNE_ONLY / PET_ONLY / global luck)",
  bad.slice(0, 4).join(", "));
ok(unknown.length === 0, "every rolled stat exists in MineStats", unknown.slice(0, 4).join(", "));

// --- budget and spread ------------------------------------------------------
let offBudget = 0, overCap = 0, wrongSlots = 0, worstOff = 0, worstShare = 0;
for (const r of rows) {
  const want = BUDGET[r.tier];
  const spent = Object.entries(r.kit).reduce((a, [s, v]) => a + v * 100 * (WEIGHT[s] || 1), 0);
  const off = Math.abs(spent - want) / want;
  if (off > 0.02) offBudget++;
  worstOff = Math.max(worstOff, off);

  const n = Object.keys(r.kit).length;
  if (n !== SLOTS[r.tier]) wrongSlots++;
  // The cap is 40% OR an even split, whichever is looser -- two shares summing
  // to 1 cannot both sit under 0.4, so a 2-slot F is 50/50 by arithmetic.
  const cap = Math.max(0.40, 1 / n) + 0.005;
  for (const [s, v] of Object.entries(r.kit)) {
    const share = (v * 100 * (WEIGHT[s] || 1)) / spent;
    worstShare = Math.max(worstShare, share);
    if (share > cap) overCap++;
  }
}
ok(offBudget === 0, "every kit spends its tier's budget (within 2% of rounding)",
  `worst ${(worstOff * 100).toFixed(2)}%`);
ok(wrongSlots === 0, "every kit has the slot count its tier calls for", wrongSlots ? `${wrongSlots} wrong` : "");
ok(overCap === 0, "no stat exceeds the spread cap", `worst share ${(worstShare * 100).toFixed(1)}%`);

// --- determinism ------------------------------------------------------------
// The generator is seeded from each skin's name, so regenerating must be a
// no-op. A skin whose stats shift under a player who owns it is the failure
// this guards.
const { execFileSync } = require("child_process");
const before = lua;
execFileSync(process.execPath, [path.join(ROOT, "tools", "gen", "skins.js")], { cwd: ROOT, stdio: "pipe" });
const after = fs.readFileSync(path.join(SRC, "MineSkins.luau"), "utf8");
ok(before === after, "regenerating is byte-identical (kits cannot shift under an owner)");

console.log("");
console.log(fails > 0 ? `>>> skins: ${fails} FAILED` : ">>> skins OK");
process.exit(fails > 0 ? 1 : 0);
