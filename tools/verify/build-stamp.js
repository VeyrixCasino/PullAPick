// MineBuild only helps if it is telling the truth.
//
// It exists because Studio twice ran code older than src/ and nothing said so.
// The module answers that out loud -- but a list of expected modules that names
// something the repo does not have would warn on a PERFECTLY current Studio,
// which is worse than staying quiet: it trains everyone to ignore the warning.
//
// So:
//   * every module in MineBuild.EXPECT exists in src/
//   * every expected module is named with what the player loses
//   * the client actually calls announce(), guarded
//   * the shop says so when the Forge or the pouch fails to load
//
//   node tools/verify/build-stamp.js
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "../..");
const SHARED = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8");

let fail = 0;
const check = (ok, msg) => {
  console.log((ok ? "  ok    " : "  FAIL  ") + msg);
  if (!ok) fail++;
};

const build = read("src/ReplicatedStorage/Mine/Shared/MineBuild.luau");

// The stamp is a hint, not a proof -- but an empty one is not even that.
const stamp = (build.match(/MineBuild\.STAMP\s*=\s*"([^"]+)"/) || [])[1];
check(!!stamp && stamp.length > 8, `STAMP is set: ${JSON.stringify(stamp || null)}`);

// EXPECT: every name must be a real module, or the warning cries wolf.
const expectBlock = (build.match(/MineBuild\.EXPECT = \{([\s\S]*?)\n\}/) || [])[1] || "";
const rows = [...expectBlock.matchAll(/\{\s*name = "([^"]+)",\s*lost = "([^"]+)"\s*\}/g)];
check(rows.length >= 4, `EXPECT lists ${rows.length} modules`);

const missing = rows
  .map((m) => m[1])
  .filter((n) => !fs.existsSync(path.join(SHARED, n + ".luau")));
check(
  missing.length === 0,
  "every expected module exists in src/" +
    (missing.length ? "  — not found: " + missing.join(", ") : "")
);

// "MineForge nil" is a shrug; "no Forge tab" is a bug report.
const vague = rows.filter((m) => m[2].trim().length < 8).map((m) => m[1]);
check(vague.length === 0, "each one says what the player loses" +
  (vague.length ? "  — too terse: " + vague.join(", ") : ""));

// The modules whose absence proves staleness have to be on the list, or the
// exact failure this was written for slips through again.
for (const must of ["MineForge", "MineOrePouchView"]) {
  check(rows.some((m) => m[1] === must), `${must} is on the list`);
}

// A diagnostic nobody runs is not a diagnostic.
const client = read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau");
check(/MineBuild/.test(client) && /\.announce\(/.test(client),
  "MineClient calls MineBuild.announce on start");
check(/FindFirstChild\("MineBuild"\)/.test(client),
  "...through FindFirstChild, so a stale Studio warns instead of hanging");

// And the two panels that went quiet must not go quiet any more.
const shop = read("src/ReplicatedStorage/Mine/Shared/MineShopView.luau");
check(/NO FORGE/.test(shop), "MineShopView warns when the Forge does not load");
check(/NO ORE POUCH/.test(shop), "MineShopView warns when the ore pouch does not load");
check((shop.match(/NO FORGE/g) || []).length >= 2,
  "...on a failed require AND a thrown mount");

console.log("");
console.log(fail > 0 ? `>>> build-stamp: ${fail} FAILED assertion(s)`
                     : ">>> build-stamp: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
