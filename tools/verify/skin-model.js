// WHAT A SKIN IS ACTUALLY WORTH, END TO END.
//
// The skin system has three multiplying parts and it is very easy to reason
// about one of them and be wrong about the product:
//
//   1. the BASE        skin base x ore tool power, before any boost
//   2. the KIT         into LAYER 1, which ADDS with skills and the tool trait
//   3. the LAYERS      base x (1 + layer1) x (1 + layer2)   <- they MULTIPLY
//
// So a +100% skin stat and a +100% pet stat is x4 on the part they both touch,
// not +200%. That is the owner's own worked example, recorded in boosts():
// "if skin has +50% damage, and pet says +100% damage, and the tools base is
// 100, then it turns to 300, rather than 250".
//
// This models the product rather than asserting a number, and fails if the
// result leaves the band a reviewer would want to see.
//
// Run: node tools/verify/skin-model.js
const fs = require("fs"), path = require("path");
const ROOT = path.join(__dirname, "..", "..");
const SRC = path.join(ROOT, "src", "ReplicatedStorage", "Mine", "Shared");

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

const lua = fs.readFileSync(path.join(SRC, "MineSkins.luau"), "utf8");
const cfg = fs.readFileSync(path.join(SRC, "MineConfig.luau"), "utf8");
const cards = fs.readFileSync(path.join(SRC, "MineCards.luau"), "utf8");

const WEIGHT = {};
for (const m of (lua.match(/MineSkins\.WEIGHT = \{[\s\S]*?\n\}/) || [""])[0].matchAll(/\t(\w+) = ([\d.]+),/g)) WEIGHT[m[1]] = +m[2];
const BASE = {}, BUDGET = {};
for (const m of (lua.match(/MineSkins\.BASE = \{[^\n]*/) || [""])[0].matchAll(/(\w+) = ([\d.]+)/g)) BASE[m[1]] = +m[2];
for (const m of (lua.match(/MineSkins\.BUDGET = \{[^\n]*/) || [""])[0].matchAll(/(\w+) = ([\d.]+)/g)) BUDGET[m[1]] = +m[2];
const TIERS = ["F", "D", "C", "B", "A", "S", "SS", "SSS"];
const ADDITIVE = new Set(((cards.match(/^local ADDITIVE_STATS = \{.*$/m) || [""])[0].match(/(\w+) = true/g) || []).map((x) => x.split(" ")[0]));

const skins = [...lua.matchAll(/\{ id = "([^"]+)", name = "([^"]+)", set = "([^"]+)", tier = "(\w+)", kit = \{ ([^}]*) \} \},/g)]
  .map((m) => ({ id: m[1], name: m[2], set: m[3], tier: m[4],
    kit: Object.fromEntries([...m[5].matchAll(/(\w+) = ([\d.]+)/g)].map((k) => [k[1], +k[2]])) }));

console.log(`  modelling ${skins.length} skins\n`);

// --- 1. THE BASE -----------------------------------------------------------
// Pure multiplier on tool power, before boosts. Nothing else touches it.
console.log("  THE BASE -- multiplies ore tool power before any boost");
console.log("  " + TIERS.map((t) => `${t} ${BASE[t]}x`).join("   "));
ok(BASE.SSS / BASE.F > 4 && BASE.SSS / BASE.F < 6,
  "base spread is a chase but not a replacement for the ore ladder",
  `${(BASE.SSS / BASE.F).toFixed(2)}x from F to SSS`);

// --- 2. THE KIT, as the player reads it ------------------------------------
console.log("\n  THE KIT -- biggest single line a tier can roll, per stat kind");
const bestAt = {};
for (const s of skins) {
  for (const [stat, amt] of Object.entries(s.kit)) {
    const k = `${s.tier}|${stat}`;
    if (!bestAt[k] || amt > bestAt[k].amt) bestAt[k] = { amt, name: s.name };
  }
}
for (const t of TIERS) {
  const rows = Object.entries(bestAt).filter(([k]) => k.startsWith(t + "|"))
    .map(([k, v]) => ({ stat: k.split("|")[1], ...v })).sort((a, b) => b.amt - a.amt);
  const top = rows[0];
  if (top) console.log(`  ${t.padEnd(4)} ${(`+${(top.amt * 100).toFixed(0)}% ${top.stat}`).padEnd(26)} ${top.name}`);
}

// --- 3. THE PRODUCT --------------------------------------------------------
// The part everyone gets wrong. Layer 1 and layer 2 MULTIPLY.
console.log("\n  THE PRODUCT -- base x (1 + layer1) x (1 + layer2), on a 100-power tool");
console.log(`  ${"tier".padEnd(5)} ${"base".padEnd(7)} ${"skin swing".padEnd(12)} ${"+pet 100%".padEnd(12)} ${"effective"}`);
const PET = 1.0; // a layer-2 source at +100%, the owner's own example
const rows = [];
for (const t of TIERS) {
  // Best swingRate a tier can roll, as a stand-in for "the damage line".
  const best = (bestAt[`${t}|swingRate`] || { amt: 0 }).amt;
  const eff = 100 * BASE[t] * (1 + best) * (1 + PET);
  rows.push({ t, base: BASE[t], best, eff });
  console.log(`  ${t.padEnd(5)} ${(BASE[t] + "x").padEnd(7)} ${(`+${(best * 100).toFixed(0)}%`).padEnd(12)} ${("x" + (1 + PET)).padEnd(12)} ${eff.toFixed(0)}`);
}
const fRow = rows[0], sssRow = rows[rows.length - 1];
ok(sssRow.eff / fRow.eff > 3 && sssRow.eff / fRow.eff < 12,
  "an SSS is a big upgrade over an F without being a different game",
  `${(sssRow.eff / fRow.eff).toFixed(1)}x`);

// --- 4. THE GRIND SETUP ----------------------------------------------------
// The owner's question: what does this look like when someone optimises?
console.log("\n  THE OPTIMISED SETUP -- the compounding that actually needs watching");
const luckSkin = (bestAt["SSS|oreLuck"] || { amt: 0 }).amt;
// Dig.oreLuck multiplies the GLOBAL luck pool by the SECTOR pool.
for (const global of [0, 0.5, 1.0, 2.0]) {
  const total = (1 + global) * (1 + luckSkin);
  console.log(`  global luck +${(global * 100).toFixed(0).padStart(3)}%  x  skin oreLuck +${(luckSkin * 100).toFixed(0)}%  =  ${total.toFixed(2)}x ore cases`);
}
ok(luckSkin > 0, "an SSS can actually roll the luck sector its set leans on");
ok((1 + 2.0) * (1 + luckSkin) < 8,
  "even a +200% global luck grinder stays under 8x ore cases from one skin",
  `${((1 + 2.0) * (1 + luckSkin)).toFixed(2)}x`);

// --- 5. HOW LONG TO SEE ONE ------------------------------------------------
console.log("\n  THE CHASE -- chests to a given tier");
const lootTot = [...cfg.matchAll(/\{ kind = "\w+",\s+weight = ([\d.]+)/g)].reduce((a, m) => a + +m[1], 0);
const skinW = +(cfg.match(/kind = "skincase", weight = ([\d.]+)/) || [0, 0])[1];
const caseRows = [...(cfg.match(/MineConfig\.SKIN_CASE_TIERS = \{[\s\S]*?\n\}/) || [""])[0]
  .matchAll(/\{ tier = "(\w+)",\s+weight = (\d+) \}/g)].map((m) => ({ tier: m[1], w: +m[2] }));
const caseTot = caseRows.reduce((a, r) => a + r.w, 0);
ok(skinW > 0 && caseTot > 0, "chest table and case table both parse",
  `skincase weight ${skinW}/${lootTot.toFixed(1)}, case tiers total ${caseTot}`);
for (const r of caseRows) {
  const perChest = (skinW / lootTot) * (r.w / caseTot);
  console.log(`  ${r.tier.padEnd(4)} 1 in ${Math.round(1 / perChest).toLocaleString().padStart(9)} chests`);
}
const sssRate = (skinW / lootTot) * ((caseRows.find((r) => r.tier === "SSS") || { w: 0 }).w / caseTot);
//[[ The band, in CHESTS, and why it is where it is.
//
// Chests are MineConfig.CHEST_CHANCE, about 1 block in 400, so 8,500 chests is
// roughly 3.4 MILLION blocks for ANY SSS -- and 9 SSS exist, so a SPECIFIC one
// is nine times that. Wide band because the honest answer is a range: below
// ~4,000 chests an SSS stops being a chase, above ~100,000 nobody in a season
// ever holds one and the top of the ladder may as well not exist.
//
// docs/SKINS.md claimed "one SSS per 83,000 chests" before this model was
// written. That was wrong by a factor of ten, and it was wrong in the
// direction that would have made someone loosen the drop rate to fix a
// problem that did not exist. Modelling it is how it got caught.
const perSSS = 1 / sssRate;
ok(perSSS > 4000 && perSSS < 100000,
  "an SSS is a genuine chase, not a lottery nobody ever wins",
  `1 in ${Math.round(perSSS).toLocaleString()} chests ~ ${(perSSS * 400 / 1e6).toFixed(1)}M blocks`);

// --- 6. SET COMPLETION -----------------------------------------------------
const perSet = {};
for (const s of skins) perSet[s.set] = (perSet[s.set] || 0) + 1;
ok(Object.values(perSet).every((n) => n === 25), "every set is still 25 -- completion is a real target");

console.log("");
console.log(fails > 0 ? `>>> skin-model: ${fails} FAILED` : ">>> skin-model OK");
process.exit(fails > 0 ? 1 : 0);
