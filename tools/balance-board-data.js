// Work out the figures the balance board shows, using the game's own formatter.
//
// MineBigNum: base 1000 steps, 20 named suffixes then a 10-letter backlog, four
// significant figures, ALWAYS floored. The owner asked for "all significant
// numbers with no exponents", which is exactly what that formatter is for, so
// this mirrors it rather than printing 1.2e15.
const fs = require("fs");
const P = "src/ReplicatedStorage/Mine/Shared/MineConfig.luau";
const cfg = fs.readFileSync(P, "utf8").split("\r\n").join("\n");

const num = (k) => {
  const m = cfg.match(new RegExp("MineConfig\\." + k + "\\s*=\\s*([0-9.eE+]+)"));
  if (!m) throw new Error("missing " + k);
  return Number(m[1]);
};

const MAXLVL = num("TOOL_MAX_LEVEL");
const CLIMB_DMG = num("TOOL_CLIMB_DAMAGE");
const CLIMB_ORE = num("TOOL_CLIMB_ORE");
const CLIMB_DUST = num("TOOL_CLIMB_DUST");
const DMG_BASE = num("TOOL_DMG_BASE");
const TIER_SPAN = num("TOOL_TIER_SPAN");
const ORE_REACH = num("ORE_REACH");
// TOOL_CRAFT_BASE no longer exists. Craft cost is blocks x band x depth now
// (owner msg 67: drop amount, ore rarity, progression), so BALANCE-PROPOSAL §3's
// "TOOL_CRAFT_BASE 250 -> 150" is already superseded.
const CRAFT_BLOCKS = num("CRAFT_BLOCKS");

const rows = cfg.match(/MineConfig\.ORES = \{([\s\S]*?)\n\}/)[1]
  .split("\n").filter((l) => /\{\s*id = "/.test(l));
const NORE = rows.length;

// MineBigNum.NAMED + BACKLOG, verbatim.
const NAMED = ["K","M","B","T","Qa","Qi","Sx","Sp","Oc","No",
               "Dc","Ud","Dd","Td","Qad","Qid","Sxd","Spd","Ocd","Nod"];
const BACKLOG = ["q","r","s","t","u","v","w","x","y","z"];
const SUF = NAMED.concat(BACKLOG);

// Four significant figures, floored, never rounded up. A wallet that rounds up
// tells a player they can afford something they cannot (TODO 0.9).
function big(n) {
  if (!isFinite(n)) return "over";
  if (n < 1000) return String(Math.floor(n));
  let step = 0, v = n;
  while (v >= 1000 && step < SUF.length) { v /= 1000; step++; }
  const dp = v >= 100 ? 1 : v >= 10 ? 2 : 3;
  const f = Math.pow(10, dp);
  return (Math.floor(v * f) / f).toFixed(dp) + SUF[step - 1];
}

const perLevel = (total) => Math.pow(total, 1 / (MAXLVL - 1));
const dmgStep = perLevel(CLIMB_DMG);
const oreStep = perLevel(CLIMB_ORE);
const dustStep = perLevel(CLIMB_DUST);

// FIXED 2026-10-05. toolTierPower used to divide by a hardcoded 120 -- #ORES-1
// back when the roster was 121 -- so this file carried a tierPowLive/tierPowWant
// pair to show the gap. The divisor now reads ORE_COUNT, so live IS intended and
// there is one curve again.
//
// What there IS now is the per-band step: the four bands above tier 60 multiply
// on top of the smooth curve, because ORE_REACH 15 means a tier-67 tool already
// reaches every ore and forging higher buys no new access.
const BAND_DMG = { Common: 1, Uncommon: 1, Rare: 1, Epic: 1,
  Legendary: 2, Mythic: 4, Divine: 8, Exotic: 16 };

const BANDS = [["Common",1,18],["Uncommon",19,29],["Rare",30,49],["Epic",50,60],
               ["Legendary",61,69],["Mythic",70,75],["Divine",76,79],["Exotic",80,82]];

const bandOf = (t) => (BANDS.find((b) => t >= b[1] && t <= b[2]) || BANDS[0])[0];
const tierPow = (t) => Math.pow(6, TIER_SPAN * (t - 1) / (NORE - 1)) * (BAND_DMG[bandOf(t)] || 1);

const out = { MAXLVL, NORE, ORE_REACH, CRAFT_BLOCKS, TIER_SPAN, DMG_BASE,
  dmgStepPct: (dmgStep - 1) * 100, oreStepPct: (oreStep - 1) * 100,
  dustStepPct: (dustStep - 1) * 100, bands: [] };

for (const [name, lo, hi] of BANDS) {
  const l1 = DMG_BASE * tierPow(hi);
  const cap = l1 * Math.pow(dmgStep, MAXLVL - 1);
  // `want` and `ratio` survive for the board's existing columns; with the
  // divisor fixed they are the same curve, so the ratio is 1 by construction
  // and the column now reads as "no gap" rather than being deleted from under
  // the page.
  out.bands.push({ name, lo, hi, reach: Math.min(hi + ORE_REACH, NORE),
    bandStep: BAND_DMG[name] || 1,
    l1: big(l1), cap: big(cap), want: big(cap), ratio: 1 });
}

console.log("cap " + MAXLVL + " | roster " + NORE + " | reach +" + ORE_REACH +
            " | craft blocks " + CRAFT_BLOCKS);
console.log("per level: damage +" + out.dmgStepPct.toFixed(1) + "%  ore +" +
            out.oreStepPct.toFixed(1) + "%  dust +" + out.dustStepPct.toFixed(1) + "%");
console.log("");
console.log("band        tiers   reaches  dmg @L1      dmg @cap     should be    short by");
for (const b of out.bands) {
  console.log(
    b.name.padEnd(11) + (b.lo + "-" + b.hi).padEnd(8) +
    String(b.reach).padEnd(9) + b.l1.padEnd(13) + b.cap.padEnd(13) +
    b.want.padEnd(13) + Math.round(b.ratio).toLocaleString("en-US") + "x");
}
fs.writeFileSync("build/balance-board.json", JSON.stringify(out, null, 1));
console.log("\nwrote build/balance-board.json");
