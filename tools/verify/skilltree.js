// Every stat the skill tree GRANTS must be a stat the server APPLIES.
//
// It wasn't. MineSkillData grants blastRadius on nine nodes -- Fire's primary,
// the headline buff of the first wedge -- and MineServer never read
// sk.blastRadius, so every point spent on it was discarded in silence. A player
// could max the Fire road and get nothing it advertised.
//
// This is the regression guard for that whole class: tree says it, server pays
// it, or this fails.
//
//   node tools/verify/skilltree.js
const fs = require("fs");
const path = require("path");
const ROOT = path.resolve(__dirname, "../..");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8");

const tree = read("src/ReplicatedStorage/Mine/Shared/MineSkillData.luau");
const server = read("src/ServerScriptService/Mine/MineServer.server.luau");
const stats = read("src/ReplicatedStorage/Mine/Shared/MineStats.luau");

let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

// What the tree hands out, read off the node rows verbatim.
const granted = new Set();
for (const m of tree.matchAll(/stats = \{([^}]*)\}/g)) {
  for (const s of m[1].matchAll(/(\w+) = [\d.]+/g)) granted.add(s[1]);
}
check(granted.size >= 8, `the tree grants ${granted.size} distinct stats`);

// What the server pays out of a skill total. Both shapes: the explicit
// `if sk.X then` lines and the key map at the top of the block.
const paid = new Set();
for (const m of server.matchAll(/sk\.(\w+)/g)) paid.add(m[1]);
// The server also pays several stats through a loop -- `for _, key in
// ipairs({ "earthquake", ... }) do ... sk[key] ... end` -- which the dotted
// form above cannot see. Collect the quoted names of any such list whose body
// indexes sk with the loop variable, or this check reports eight false drops.
for (const m of server.matchAll(
  /for\s+_,\s*key\s+in\s+ipairs\(\{([^}]*)\}\)\s*do([\s\S]*?)\bend\b/g)) {
  if (!/sk\[key\]/.test(m[2])) continue;
  for (const q of m[1].matchAll(/"(\w+)"/g)) paid.add(q[1]);
}
for (const m of server.matchAll(/^\t\t(\w+) = "(\w+)",?$/gm)) {
  if (server.includes("Skills.totalStats")) paid.add(m[1]);
}
const dropped = [...granted].filter((s) => !paid.has(s));
check(dropped.length === 0,
  "every stat the tree grants is applied by the server" +
    (dropped.length ? "  — DROPPED: " + dropped.join(", ") : ""));

// The one that was actually broken, named so it cannot quietly regress.
check(/if sk\.blastRadius then/.test(server),
  "blastRadius — Fire's primary — is applied");

// Energies are the element roster. Each one's primary must be a live stat:
// Space pointed at `echo`, which is retired and pays out as swingRate.
// Color3.fromRGB(r, g, b) has commas in it, so the colour field cannot be
// matched with [^,]+ — the first version of this check found zero energies and
// then happily reported that none of them had a retired primary.
const energies = [...tree.matchAll(
  /\{ id = "(\w+)", name = "(\w+)", verb = "\w+",[\s\S]*?primary = "(\w+)"/g)];
check(energies.length === 10, `the element roster has ${energies.length} energies`);

const legacy = new Set();
for (const m of stats.matchAll(/^\t(\w+)\s*=\s*\{[^}]*legacy = true/gm)) legacy.add(m[1]);
const deadPrimary = energies.filter((e) => legacy.has(e[3])).map((e) => `${e[2]} -> ${e[3]}`);
// Reported, not failed: the owner has not decided what Space should be yet.
console.log(deadPrimary.length
  ? `  note    an element's primary is a retired stat: ${deadPrimary.join(", ")}`
  : "  ok    no element's primary is a retired stat");

// RETIRED STATS must not be in any roll pool. backpack and walkSpeed were
// retired on 2026-10-04; echo and autoMine before them. A set rune takes its
// stat straight from MineRunes.SETS and bypasses NO_ROLL_STATS entirely, which
// is how Longhauler would have gone on minting dead runes.
const pools = {
  "MineTraits.LIST": read("src/ReplicatedStorage/Mine/Shared/MineTraits.luau")
    .match(/MineTraits\.LIST = \{[\s\S]*?\n\}/)[0],
  "MineGear.STAT_WEIGHT": read("src/ReplicatedStorage/Mine/Shared/MineGear.luau")
    .match(/MineGear\.STAT_WEIGHT = \{[\s\S]*?\n\}/)[0],
  "MineRunes.FAMILY_STATS": read("src/ReplicatedStorage/Mine/Shared/MineRunes.luau")
    .match(/MineRunes\.FAMILY_STATS = \{[\s\S]*?\n\}/)[0],
  "MineRunes.SETS": read("src/ReplicatedStorage/Mine/Shared/MineRunes.luau")
    .match(/MineRunes\.SETS = \{[\s\S]*?\n\}/)[0],
  "MineSkillData.ENERGIES": tree.match(/MineSkillData\.ENERGIES = \{[\s\S]*?\n\}/)[0],
};
// Comments stripped: the first run of this flagged backpack and walkSpeed in
// the very comments explaining that they had been retired.
//
// Scoped to the 2026-10-04 retirements. echo and autoMine deliberately keep
// entries in MineGear.STAT_WEIGHT and MineRunes.FAMILY_STATS so an
// already-rolled piece still resolves a weight -- both are documented in place,
// and both are kept out of the pools by NO_ROLL_STATS.
const RETIRED_NOW = ["backpack", "walkSpeed"];
const stripLua = (t) => t.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");
for (const [name, raw] of Object.entries(pools)) {
  const text = stripLua(raw);
  const hits = RETIRED_NOW.filter((st) => new RegExp(`["\\s]${st}["\\s=]`).test(text));
  check(hits.length === 0,
    `${name} rolls no retired stat` + (hits.length ? `  — found: ${hits.join(", ")}` : ""));
}

console.log("");
console.log(fail > 0 ? `>>> skilltree: ${fail} FAILED` : ">>> skilltree: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
