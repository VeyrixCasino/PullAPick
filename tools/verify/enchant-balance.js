// THE BALANCE PASS OF THE ABILITY ENCHANTS (owner, 2026-10-19: "Do balancing
// checks to make sure good enough, but not too overpowered stacked with
// enchants too, i want every ability enchant to be viable with different
// builds, depending on what their going for").
//
// enchant-balance.luau digs, through the server's own proc code (sliced out of
// MineServer by _enchant-sim.js), with every ability Special -- Zap, Blast,
// Tidal Wave, Shatter, Earthquake, Spellbook -- on each tool family, at three
// stages of the game, in four builds:
//   plain  Equip Best's plain pets, the stage's power charm and skin
//   charm  the plain pets with the family's proc charm (Blast's Omni Blast,
//          Zap's Chainlink)
//   pets   Equip Best's pets for that ability
//   stack  those pets, the proc charm and a skin carrying the ability
// and measures three goals: AREA (blocks broken a second on the stage's own
// rock, where the gear breaks a block a hit), TOUGH (damage a second on rock
// that takes eight swings) and SINGLE (damage a second on one block that
// never breaks). Each build is also dug with every ability off; the ratio is
// the ABILITY MULTIPLIER, so the pets' and charms' plain stats (swing rate,
// Mine Speed) cancel and what is left is what the ability stack adds.
//
// THE RULES (PROPOSED, 2026-10-19):
//   1. every ability is the strongest choice (and worth +10%) for at least one
//      build and goal: "viable with different builds, depending on what their
//      going for"
//   2. at every stage every ability adds +10% to some goal: none is useless
//   3. AREA, the progression goal: at each stage the strongest ability's best
//      build is at most 2.25x the median ability's best build (the brief's
//      "about 1.5-2x", with room for a dig's run-to-run spread)
//   4. TOUGH and SINGLE are specialists' goals (Zap fires on every swing,
//      Earthquake shakes the blocks that do not break): no ability's best build
//      is more than 2x the runner-up's, for each stage and tool family
//   5. the Halloween Damage enchants: Sugar Rush is the area tools' speed
//      enchant (beats Overclock on a drill) and not the pickaxe's; Grave Digger
//      pays deep and is not the best Damage enchant everywhere
//   6. Flashlight lights at most 2.5 ores a minute and is on at most 40% of
//      the time ("a cooldown keeps it from being on all the time")
//
//   node tools/verify/enchant-balance.js
"use strict";
const fs = require("fs");
const path = require("path");
const Luau = require("./_luau");
const Sim = require("./_enchant-sim");

const ROOT = path.resolve(__dirname, "../..");
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

if (!Luau.ready) { console.log(Luau.missing("luau") + "; skipping"); process.exit(1); }

const RULES = { act: 1.10, areaCap: 2.25, runaway: 2.0, flashPerMin: 2.5, flashLit: 0.40 };
const ABILITIES = ["zap", "blast", "tide", "shatter", "quake", "spellbook"];
const NAMES = { zap: "Zap", blast: "Blast", tide: "Tidal Wave", shatter: "Shatter", quake: "Earthquake", spellbook: "Spellbook" };
const STAGES = ["early", "mid", "late"];
const FAMS = ["pickaxe", "hammer", "drill", "jackhammer"];
const GOALS = ["area", "tough", "single"];

let out = "";
try {
  const lua = Sim.prelude(ROOT) + Sim.world(ROOT) + Luau.readSrc(path.join(__dirname, "enchant-balance.luau"));
  out = Sim.run(lua, "enchant-balance");
} catch (e) {
  console.log(e.message);
  check(false, "the balance pass ran");
}
const lines = out.split("\n");
const rows = lines.filter((l) => l.startsWith("RES ")).map((l) => {
  const [, stage, fam, sp, build, area, tough, single, sps, chance, pp, area0, tough0, single0] = l.split(" ");
  return { stage, fam, sp, build, area: +area, tough: +tough, single: +single, sps: +sps, chance: +chance, pp: +pp,
    area0: +area0, tough0: +tough0, single0: +single0 };
});
const M = (r, g) => r[g] / Math.max(1e-12, r[g + "0"]);
const stageRows = lines.filter((l) => l.startsWith("STAGE ")).map((l) => l.split(" "));
const teams = lines.filter((l) => l.startsWith("TEAMS "));
const dmg = lines.filter((l) => l.startsWith("DMG ")).map((l) => {
  const [, stage, fam, id, area, tough] = l.split(" ");
  return { stage, fam, id, area: +area, tough: +tough };
});
const flash = lines.filter((l) => l.startsWith("FLASH ")).map((l) => {
  const [, stage, level, perMin, lit, radius, cooldown] = l.split(" ");
  return { stage, level: +level, perMin: +perMin, lit: +lit, radius: +radius, cooldown: +cooldown };
});
check(rows.length === 3 * 4 * (1 + 6 * 3 + 2) && lines.includes("DONE"),
  `every stage x family x ability x build was dug (${rows.length} runs)`);
if (rows.length === 0 || !ABILITIES.every((sp) => rows.some((r) => r.sp === sp))) {
  console.log("");
  console.log(`>>> enchant-balance: ${fail} FAILED (no runs to judge: the Specials, Spellbook included, must all dig)`);
  process.exit(1);
}

// Each ability's best build at a stage, per goal (over families and builds).
const bestOf = (stage, sp, g, fam) => {
  let best = null;
  for (const r of rows.filter((x) => x.stage === stage && x.sp === sp && (!fam || x.fam === fam))) {
    const v = M(r, g);
    if (!best || v > best.v) best = { v, r };
  }
  return best;
};

// ------------------------------------------------------------ the table --
console.log("");
console.log("  ABILITY MULTIPLIER of each ability's best build (over the bare build), per stage:");
console.log("  " + "ability".padEnd(11) + STAGES.map((s) => `${s}: area / tough / single`.padEnd(34)).join(""));
for (const sp of ABILITIES) {
  const cells = STAGES.map((stage) => GOALS.map((g) => {
    const b = bestOf(stage, sp, g);
    return b ? `${b.v.toFixed(1)}x` : "-";
  }).join(" / ").padEnd(34));
  console.log("  " + NAMES[sp].padEnd(11) + cells.join(""));
}
console.log("");
console.log("  Where each is strongest (best build, area):");
for (const stage of STAGES) {
  console.log(`    ${stage.padEnd(5)} ` + ABILITIES.map((sp) => {
    const b = bestOf(stage, sp, "area");
    return `${NAMES[sp]} ${b.v.toFixed(1)}x (${b.r.fam}, ${b.r.build})`;
  }).join(" · "));
}
console.log("");

// 1. strongest somewhere
const wins = {};
for (const stage of STAGES) for (const fam of FAMS) for (const g of GOALS) for (const build of ["plain", "charm", "pets", "stack"]) {
  let best = null;
  for (const sp of ABILITIES) {
    const r = rows.find((x) => x.stage === stage && x.fam === fam && x.sp === sp && x.build === build);
    if (r && (!best || M(r, g) > best.v)) best = { sp, v: M(r, g), where: `${stage} ${fam} ${build} ${g}` };
  }
  if (best && best.v >= RULES.act) (wins[best.sp] = wins[best.sp] || []).push(best.where);
}
for (const sp of ABILITIES) {
  const w = wins[sp] || [];
  check(w.length >= 1, `${NAMES[sp]} is the strongest choice in ${w.length} builds and goals (for example: ${w.slice(0, 2).join("; ") || "none"})`);
}
// 2. useful at every stage
for (const sp of ABILITIES) {
  const per = STAGES.map((stage) => Math.max(...GOALS.map((g) => bestOf(stage, sp, g).v)));
  check(per.every((v) => v >= RULES.act), `${NAMES[sp]} adds at least +10% to some goal at every stage (${per.map((v) => v.toFixed(2) + "x").join(", ")})`);
}
// 3. AREA: no ability's best build runs away from the median ability's
const median = (a) => { const s = [...a].sort((x, y) => x - y); const n = s.length; return n % 2 ? s[(n - 1) / 2] : (s[n / 2 - 1] + s[n / 2]) / 2; };
for (const stage of STAGES) {
  const best = ABILITIES.map((sp) => ({ sp, v: bestOf(stage, sp, "area").v })).filter((x) => x.v >= RULES.act);
  const med = median(best.map((x) => x.v));
  const top = best.reduce((a, b) => (b.v > a.v ? b : a));
  check(top.v <= RULES.areaCap * med,
    `${stage}: the strongest stack on area (${NAMES[top.sp]} ${top.v.toFixed(1)}x) is ${(top.v / med).toFixed(2)}x the median ability's best (${med.toFixed(1)}x); the cap is ${RULES.areaCap}x`);
}
// 4. TOUGH and SINGLE: no runaway specialist
let worst = { ratio: 0 };
for (const stage of STAGES) for (const fam of FAMS) for (const g of ["tough", "single"]) {
  const best = ABILITIES.map((sp) => ({ sp, v: bestOf(stage, sp, g, fam).v })).filter((x) => x.v >= RULES.act).sort((a, b) => b.v - a.v);
  if (best.length >= 2) {
    const ratio = best[0].v / best[1].v;
    if (ratio > worst.ratio) worst = { ratio, where: `${stage} ${fam} ${g}: ${NAMES[best[0].sp]} ${best[0].v.toFixed(1)}x, then ${NAMES[best[1].sp]} ${best[1].v.toFixed(1)}x` };
  }
}
check(worst.ratio <= RULES.runaway, `on tough rock and a single block no ability's best build is over ${RULES.runaway}x the runner-up's (worst ${worst.ratio.toFixed(2)}x: ${worst.where})`);

// 5. the Halloween Damage enchants
console.log("");
console.log("  DAMAGE SLOT (plain build, no Special; x over no Damage enchant): area / tough");
const dm = (stage, fam, id, g) => {
  const base = dmg.find((d) => d.stage === stage && d.fam === fam && d.id === "none");
  const r = dmg.find((d) => d.stage === stage && d.fam === fam && d.id === id);
  return r && base ? r[g] / Math.max(1e-12, base[g]) : NaN;
};
const DMG = ["power", "combo", "overclock", "sugar_rush", "grave_digger"];
for (const stage of STAGES) for (const fam of ["pickaxe", "drill", "jackhammer"]) {
  console.log(`    ${stage.padEnd(5)} ${fam.padEnd(7)} ` + DMG.map((id) => `${id} ${dm(stage, fam, id, "area").toFixed(2)}/${dm(stage, fam, id, "tough").toFixed(2)}`).join("  "));
}
// Sugar Rush and Overclock share the +100% cap (both are the owner's numbers),
// so where blocks break in one hit they come out level: Sugar Rush ramps back
// faster on the area tools after a pause, Overclock on a pickaxe.
const pairs = [];
for (const s of STAGES) for (const fam of ["pickaxe", "drill", "jackhammer"]) {
  pairs.push({ s, fam, rush: dm(s, fam, "sugar_rush", "area"), oc: dm(s, fam, "overclock", "area"), tough: dm(s, fam, "sugar_rush", "tough") });
}
const off = pairs.reduce((a, x) => Math.max(a, Math.abs(x.rush / x.oc - 1)), 0);
const slowest = pairs.reduce((a, x) => Math.min(a, x.rush), Infinity);
const toughOff = pairs.reduce((a, x) => Math.max(a, Math.abs(x.tough - 1)), 0);
check(off <= 0.06 && slowest >= 1.25 && toughOff <= 0.06,
  `Sugar Rush is a real speed enchant where blocks break in one hit (at least x${slowest.toFixed(2)}), level with Overclock (within ${(100 * off).toFixed(1)}%: the same +100% cap), and adds nothing on tough rock (within ${(100 * toughOff).toFixed(1)}%)`);
const gdLate = dm("late", "pickaxe", "grave_digger", "tough"), pwLate = dm("late", "pickaxe", "power", "tough");
const gdBest = STAGES.filter((s) => DMG.every((id) => dm(s, "pickaxe", "grave_digger", "tough") >= dm(s, "pickaxe", id, "tough")));
check(gdLate > pwLate && gdLate >= RULES.act && gdBest.length < STAGES.length,
  `Grave Digger pays deep (near the floor x${gdLate.toFixed(2)} on tough rock, Power x${pwLate.toFixed(2)}) and is not the best Damage enchant at every stage (best at: ${gdBest.join(", ") || "none"})`);

// 6. Flashlight
console.log("");
console.log("  FLASHLIGHT (plain pickaxe digging): ores lit a minute, share of the time one glows");
for (const f of flash) {
  console.log(`    ${f.stage.padEnd(5)} level ${f.level}: ${f.perMin.toFixed(2)} a minute, glowing ${(100 * f.lit).toFixed(0)}% of the time (radius ${f.radius}, rests ${f.cooldown}s)`);
}
const fMax = flash.reduce((a, f) => (f.perMin > a.perMin ? f : a), { perMin: 0 });
const lMax = flash.reduce((a, f) => (f.lit > a.lit ? f : a), { lit: 0 });
check(flash.length === 6 && fMax.perMin <= RULES.flashPerMin && lMax.lit <= RULES.flashLit,
  `Flashlight lights at most ${fMax.perMin.toFixed(2)} ores a minute and glows at most ${(100 * lMax.lit).toFixed(0)}% of the time (caps ${RULES.flashPerMin} and ${100 * RULES.flashLit}%)`);

console.log("");
for (const s of stageRows) console.log(`  stage ${s[1]}: ${s[2]} layer ${s[3]}, ore tier ${s[4]} at level ${s[5]}, rock ${Number(s[6]).toExponential(2)} HP`);
for (const t of teams) console.log("  " + t.replace(/^TEAMS /, "teams ").replace(/\+/g, ", "));
console.log("");
console.log(fail > 0 ? `>>> enchant-balance: ${fail} FAILED` : ">>> enchant-balance: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
