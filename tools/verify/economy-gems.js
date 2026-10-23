// GEMS HOLD THEIR VALUE (owner, 2026-10-19).
//
// "make sure gems semi maintain the same ish value (pet simulator 99 or
// whatever ... disgusts me because of the inflation)". The F..SSS chests, the
// 57 set chests, the charm tiers and the Charm Packs all touch what a player
// earns, so this measures the gem economy off the REAL tables
// (economy-gems.luau, run against the real modules in luau) and compares it
// with a baseline measured the same way on 3863d14, the commit before them
// (economy-gems.baseline.json).
//
//   1. an average chest at 7 depths of all 11 zones: gems within GEMS_TOL;
//      coins, cases, skins, books and XP within LOOT_TOL; each zone pack slot
//      within SLOT_TOL; the card value (with the set chests' set packs) up by
//      no more than CARD_RISE ("the same loot overall, split by tier")
//   2. gems in per hour at four stages, for a plain player and for one in the
//      strongest Gem Find charm at its best tier: up by no more than GEMS_TOL
//   3. the strongest single-charm Gem Find is unchanged (a tier never prints
//      gems: MineCharms.TIER_FLAT)
//   4. the eight Charm Packs are a gem SINK: priced in gems, climbing with the
//      rarity, each a real slice of an hour's gems at the stage it belongs
//      to, paying a charm of its rarity and no gems back; merging costs gems
//
// Every tolerance is PROPOSED (2026-10-19).
//
//   node tools/verify/economy-gems.js                  check this tree
//   node tools/verify/economy-gems.js --baseline DIR   re-measure the baseline
//                                                       from a 3863d14 tree at DIR
//   node tools/verify/economy-gems.js --root DIR       check another tree
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");
const Shared = require("./_shared");

const HERE = __dirname;
const argv = process.argv.slice(2);
const opt = (k) => { const i = argv.indexOf(k); return i >= 0 ? argv[i + 1] : null; };
const BASELINE_FILE = path.join(HERE, "economy-gems.baseline.json");

// PROPOSED (2026-10-19).
const GEMS_TOL = 0.05;   // gems per chest, and gems in per hour
const LOOT_TOL = 0.15;   // coins, cases, skins, books, XP per chest
const SLOT_TOL = 0.20;   // each zone pack slot per chest
const CARD_RISE = 0.35;  // the card value per chest may rise this much (set chests)
// A Charm Pack must cost at least this many minutes of the gems a player earns
// in an hour at its stage, or it is not a sink: F/D early, C/B mid, A+ late.
const PACK_STAGE = { F: "start", D: "early", C: "early", B: "mid", A: "mid", S: "late", SS: "late", SSS: "late" };
const PACK_MIN_MINUTES = 5;

let fail = 0;
const check = (ok, msg, detail) => {
  console.log((ok ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!ok) fail++;
};

if (!Luau.ready) {
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(1);
}

const MODULES = [
  "MineConfig", "MineDepth", "MineBags", "MineShopEconomy", "MineBagNames", "MineLaunch",
  "MineZoneChests", "MineChestRanks", "MineZonePacks", "MinePackConfig", "Mine1PacksData",
  "Mine1ChestsData", "MinePotions", "MineCases", "MinePackArt", "MineSetPacks", "MineSetPets",
  "MineEnchants", "MineTemper", "MineIcons", "MineSkillData", "MineStats", "MineCharms",
  "MineOrePouch", "MineSetChests",
];

function measure(root, mode) {
  const SH = path.join(root, "src/ReplicatedStorage/Mine/Shared");
  const mods = MODULES.filter((m) => fs.existsSync(path.join(SH, m + ".luau")));
  const lua = Shared.prelude(root, mods, ["SetPets", "HolidayPets"])
    + "\n" + Luau.readSrc(path.join(HERE, "economy-gems.luau"))
    + `\nMEASURE("${mode}")\n`;
  const tmp = path.join(require("os").tmpdir(), `mfc-economy-gems-${process.pid}-${mode}.luau`);
  fs.writeFileSync(tmp, lua);
  let out = "";
  try {
    out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8", maxBuffer: 1 << 26 });
  } catch (e) {
    out = String(e.stdout || "") + String(e.stderr || "");
    console.log(out.split("\n").slice(-8).join("\n"));
    check(false, `the ${mode} measurement ran`);
  } finally {
    try { fs.unlinkSync(tmp); } catch (e) { /* gone */ }
  }
  const kv = (s) => Object.fromEntries(s.trim().split(/\s+/).filter((x) => x.includes("=")).map((x) => {
    const [k, v] = x.split("=");
    return [k, isNaN(Number(v)) ? v : Number(v)];
  }));
  const res = { chests: {}, stages: {}, charm: {}, packs: {}, merges: {} };
  for (const line of out.split(/\r?\n/)) {
    let m;
    if ((m = line.match(/^CHEST (\w+) (\d+) (.*)$/))) res.chests[`${m[1]}@${m[2]}`] = kv(m[3]);
    else if ((m = line.match(/^STAGE (\w+) (.*)$/))) res.stages[m[1]] = kv(m[2]);
    else if ((m = line.match(/^CHARM (.*)$/))) res.charm = kv(m[1].replace(/\t/g, " "));
    else if ((m = line.match(/^PACK (\w+) (.*)$/))) res.packs[m[1]] = kv(m[2]);
    else if ((m = line.match(/^MERGE (\w+) (.*)$/))) res.merges[m[1]] = kv(m[2]);
  }
  return res;
}

// ------------------------------------------------------------ baseline --
const baseDir = opt("--baseline");
if (baseDir) {
  const before = measure(path.resolve(baseDir), "before");
  const n = Object.keys(before.chests).length;
  check(n === 77, `the baseline measured 77 depth samples (${n})`);
  if (fail === 0) {
    fs.writeFileSync(BASELINE_FILE, JSON.stringify({
      _comment: "Measured by `node tools/verify/economy-gems.js --baseline <3863d14 tree>` (MEASURE(\"before\") in economy-gems.luau). Do not hand-edit: re-measure.",
      commit: "3863d14",
      measured: "2026-10-19",
      ...before,
    }, null, 1) + "\n");
    console.log(`  wrote ${path.relative(path.join(HERE, "../.."), BASELINE_FILE)}`);
  }
  process.exit(fail > 0 ? 1 : 0);
}

// --------------------------------------------------------------- check --
const ROOT = path.resolve(opt("--root") || path.join(HERE, "../.."));
const base = JSON.parse(fs.readFileSync(BASELINE_FILE, "utf8"));
const now = measure(ROOT, "after");
const pct = (x) => (x >= 0 ? "+" : "") + (x * 100).toFixed(1) + "%";
const rel = (a, b) => (b === 0 ? (a === 0 ? 0 : Infinity) : a / b - 1);

// 1. chests
const keys = Object.keys(base.chests);
check(keys.length === 77 && keys.every((k) => now.chests[k]), "every baseline depth was measured again",
  `${keys.filter((k) => now.chests[k]).length} of ${keys.length}`);
const worst = {};
const track = (name, k, d) => { if (!worst[name] || Math.abs(d) > Math.abs(worst[name].d)) worst[name] = { d, k }; };
for (const k of keys) {
  const a = now.chests[k], b = base.chests[k];
  if (!a) continue;
  track("gems", k, rel(a.gems + a.pgems, b.gems + b.pgems));
  for (const f of ["coins", "caseDust", "skin", "books", "bookLv", "xp"]) track(f, k, rel(a[f], b[f]));
  for (const s of ["pack_common", "pack_rare", "pack_legendary", "currency_common", "currency_rare"]) track(s, k, rel(a[s], b[s]));
  track("pval", k, rel(a.pval, b.pval));
}
const w = (n) => worst[n] || { d: 0, k: "-" };
check(Math.abs(w("gems").d) <= GEMS_TOL, `an average chest's gems stay within ${GEMS_TOL * 100}% at every depth`,
  `worst ${pct(w("gems").d)} at ${w("gems").k}`);
for (const f of ["coins", "caseDust", "skin", "books", "bookLv", "xp"]) {
  check(Math.abs(w(f).d) <= LOOT_TOL, `...and its ${f} within ${LOOT_TOL * 100}%`, `worst ${pct(w(f).d)} at ${w(f).k}`);
}
for (const s of ["pack_common", "pack_rare", "pack_legendary", "currency_common", "currency_rare"]) {
  check(Math.abs(w(s).d) <= SLOT_TOL, `...its ${s} within ${SLOT_TOL * 100}%`, `worst ${pct(w(s).d)} at ${w(s).k}`);
}
check(w("pval").d <= CARD_RISE, `...and the cards its packs hold (set packs included) rise no more than ${CARD_RISE * 100}%`,
  `worst ${pct(w("pval").d)} at ${w("pval").k}`);

// 2. per hour
console.log("");
console.log("        gems in per hour            before        after      change   (gem build: before / after)");
for (const s of ["start", "early", "mid", "late"]) {
  const a = now.stages[s], b = base.stages[s];
  if (!a || !b) { check(false, `stage ${s} measured`); continue; }
  console.log(`        ${s.padEnd(6)} chests+ore    ${String(Math.round(b.gemsIn)).padStart(12)} ${String(Math.round(a.gemsIn)).padStart(12)}  ${pct(rel(a.gemsIn, b.gemsIn)).padStart(8)}   (${Math.round(b.gemsInGemBuild)} / ${Math.round(a.gemsInGemBuild)})`);
  check(rel(a.gemsIn, b.gemsIn) <= GEMS_TOL, `${s}: gems in per hour up no more than ${GEMS_TOL * 100}%`, pct(rel(a.gemsIn, b.gemsIn)));
  check(rel(a.gemsInGemBuild, b.gemsInGemBuild) <= GEMS_TOL,
    `${s}: ...and for a player in the best Gem Find charm at its best tier`, pct(rel(a.gemsInGemBuild, b.gemsInGemBuild)));
}

// 3. charms never print gems
check(now.charm.bestGemFind <= base.charm.bestGemFind + 1e-9,
  "the strongest Gem Find on one charm, at its best tier, is no higher than before",
  `${now.charm.bestGemFind} vs ${base.charm.bestGemFind} (${now.charm.who})`);

// 4. the Charm Packs are a sink
console.log("");
const LAD = ["F", "D", "C", "B", "A", "S", "SS", "SSS"];
check(LAD.every((r) => now.packs[r]), "eight Charm Packs, F to SSS", Object.keys(now.packs).join(" ") || "none");
let prevG = 0, prevC = 0, mono = true;
for (const r of LAD) {
  const p = now.packs[r];
  if (!p) continue;
  if (!(p.gems > prevG && p.credits > prevC)) mono = false;
  prevG = p.gems; prevC = p.credits;
  const stage = now.stages[PACK_STAGE[r]];
  const minutes = stage ? (p.gems / stage.gemsIn) * 60 : 0;
  console.log(`        ${(r + " Charm Pack").padEnd(16)} ${String(p.gems).padStart(9)} gems  ${String(p.credits).padStart(4)} credits   ${minutes.toFixed(1).padStart(7)} min of ${PACK_STAGE[r]} gems   ${p.n} charms`);
  check(minutes >= PACK_MIN_MINUTES, `${r} Charm Pack costs at least ${PACK_MIN_MINUTES} minutes of ${PACK_STAGE[r]} gems`, `${minutes.toFixed(1)} min`);
  check(Math.abs(p.psum - 1) < 1e-6 && p.n >= 5 && p.rolls !== "nil" && p.rolls !== "false",
    `${r} Charm Pack: its odds sum to 1 over ${p.n} charms, and it rolls one of its rarity`);
  check(p.back === 0, `${r} Charm Pack pays no gems back`);
}
check(mono, "pack prices climb with the rarity, in gems and in credits");
const mergeMono = LAD.every((r, i) => !now.merges[r] ? false : (i === 0 || now.merges[r].toV > now.merges[LAD[i - 1]].toV));
check(mergeMono, "a merge costs gems, more for a rarer charm",
  LAD.map((r) => now.merges[r] ? `${r} ${now.merges[r].toV}` : `${r} ?`).join("  "));

// The verb itself: it only ever takes gems, and nothing turns a charm into gems.
const SVC = path.join(ROOT, "src/ServerScriptService/Mine/MineCharmService.luau");
const svc = fs.existsSync(SVC) ? Luau.readSrc(SVC).replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "") : "";
check(/p\.gems = have - price/.test(svc) && !/p\.gems\s*=\s*[^\n]*\+/.test(svc),
  "the Charm Pack and merge verbs only ever take gems (MineCharmService)");

console.log("");
console.log(fail > 0 ? `>>> economy-gems: ${fail} FAILED` : ">>> economy-gems: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
