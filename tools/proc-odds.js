// What the AoE procs ACTUALLY fire at, once a real build is on.
//
// Owner, 2026-10-05: "i wanted all to be worthwhile endgame, not to be worth it
// right away.. this is more about the odds of it happening.. with pets what is
// the average odds that they proc. thats the issue, not the max hops of zap."
//
// So: every source that feeds a proc CHANCE, what it grants, and what a player
// is holding at three points in the game. Chance stats are additive (MineServer
// keeps echo/zap/blastChance/blastRadius out of the multiplicative table), so a
// total is a sum and these numbers add up the way the server adds them.
const fs = require("fs");
const path = require("path");
const read = (p) => fs.readFileSync(p, "utf8").split("\r\n").join("\n");
const S = "src/ReplicatedStorage/Mine/Shared";

const PROCS = ["blastChance", "zap", "earthquake", "ricochet"];

// Pull every `key = 0.1234` for our four stats out of a module, with the row
// name that carries it where there is one.
function harvest(file) {
  const src = read(path.join(S, file));
  const out = {};
  for (const k of PROCS) out[k] = [];
  const re = new RegExp("\\[?\"?([A-Za-z0-9_ '\\-]+)\"?\\]?\\s*=\\s*\\{([^}]*)\\}", "g");
  let m;
  while ((m = re.exec(src))) {
    const row = m[1].trim();
    const body = m[2];
    for (const k of PROCS) {
      const hit = body.match(new RegExp("\\b" + k + "\\s*=\\s*([\\d.]+)"));
      if (hit) out[k].push({ row, v: Number(hit[1]) });
    }
  }
  return out;
}

const FILES = ["MinePetBoosts.luau", "MineEHPets.luau", "MineGear.luau",
  "MineCharms.luau", "MineTraits.luau", "MineRunes.luau", "MineCards.luau",
  "MinePotions.luau", "MineTemper.luau", "MineSkillData.luau"];

console.log("WHERE PROC CHANCE COMES FROM");
console.log("source".padEnd(22) + PROCS.map((p) => p.slice(0, 11).padStart(13)).join(""));
const totals = {};
for (const k of PROCS) totals[k] = { rows: 0, sum: 0, max: 0 };

for (const f of FILES) {
  let got;
  try { got = harvest(f); } catch (e) { continue; }
  const cells = PROCS.map((k) => {
    const list = got[k];
    if (!list.length) return "-".padStart(13);
    totals[k].rows += list.length;
    for (const e of list) {
      totals[k].sum += e.v;
      if (e.v > totals[k].max) totals[k].max = e.v;
    }
    const avg = list.reduce((a, b) => a + b.v, 0) / list.length;
    return (list.length + " @" + (avg * 100).toFixed(1) + "%").padStart(13);
  });
  console.log(f.replace(".luau", "").padEnd(22) + cells.join(""));
}

console.log("");
console.log("TOTAL ROWS GRANTING IT, AND THE BIGGEST SINGLE ONE");
for (const k of PROCS) {
  const t = totals[k];
  console.log("  " + k.padEnd(14) + String(t.rows).padStart(4) + " rows" +
    ("  avg " + (t.rows ? (t.sum / t.rows * 100).toFixed(1) : "0") + "%").padStart(14) +
    ("  best " + (t.max * 100).toFixed(1) + "%").padStart(14));
}

// ---- what a build actually carries ---------------------------------------
// Pets are the question asked. Three seats, and the pool is whatever grants
// the stat, so a player chasing a proc stacks the three best they own.
const pets = harvest("MinePetBoosts.luau");
console.log("");
console.log("THREE PET SEATS, STACKED FOR ONE STAT");
console.log("  stat            pool    best three        total from pets");
for (const k of PROCS) {
  const list = pets[k].slice().sort((a, b) => b.v - a.v);
  if (!list.length) {
    console.log("  " + k.padEnd(14) + "   0    no pet grants it    " + "0%".padStart(8));
    continue;
  }
  const top = list.slice(0, 3);
  console.log("  " + k.padEnd(14) + String(list.length).padStart(4) + "    " +
    top.map((e) => (e.v * 100).toFixed(0) + "%").join(" + ").padEnd(18) +
    ((top.reduce((a, b) => a + b.v, 0) * 100).toFixed(0) + "%").padStart(8));
}
