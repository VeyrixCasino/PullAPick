// The Forge must not read a snapshot field the shop never passes it.
//
// MineForge is mounted inside MineShopView's Upgrade tab, and the shop hands it
// a HAND-BUILT subset of its own state through getSnap -- not the whole
// snapshot. So a field the Forge reads but the shop omits is nil at runtime,
// and nil does not throw here: it falls through a `tonumber(...) or 1` and the
// panel prints a plausible, wrong number.
//
// That is exactly what happened adding the ore strip. It read
// snapshot.orePouchTier to show fill against capacity; the shop did not pass it;
// the default was 1, so every player saw a tier-1 pouch's capacity regardless of
// the one they had bought. Nothing in the suite could see that.
//
//   node tools/verify/forge-snap.js
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "../..");
const SHARED = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared");
const read = (n) => fs.readFileSync(path.join(SHARED, n + ".luau"), "utf8");

const forge = read("MineForge");
const shop = read("MineShopView");

// What the Forge reads off its snapshot.
const reads = new Set([...forge.matchAll(/\bsnapshot\.([A-Za-z_]\w*)/g)].map((m) => m[1]));
if (reads.size === 0) {
  console.error("FAIL no snapshot reads found in MineForge — has the parameter been renamed?");
  process.exit(1);
}

//[[ Which getSnap belongs to the Forge.
//
// The shop mounts more than one panel and each gets its own closure, so the
// right one is found by the comment block that introduces the Forge's mount and
// then the first getSnap after it. Anchoring on a brittle line number would
// quietly start checking the pouch panel's closure instead.
const anchor = shop.indexOf("MineForge draws every tool in the game");
if (anchor < 0) {
  console.error("FAIL could not find the MineForge mount in MineShopView");
  process.exit(1);
}
const gs = shop.indexOf("getSnap = function()", anchor);
if (gs < 0) {
  console.error("FAIL could not find the Forge's getSnap closure");
  process.exit(1);
}
const close = shop.indexOf("\n\t\t\tend,", gs);
// Skip the "getSnap = function()" line itself, which the key regex would
// otherwise count as a field the shop provides.
const body = shop.slice(shop.indexOf("\n", gs), close > 0 ? close : gs + 2000);
const provided = new Set([...body.matchAll(/^\s*([A-Za-z_]\w*)\s*=/gm)].map((m) => m[1]));

console.log(`  Forge reads ${reads.size} snapshot fields; the shop passes ${provided.size}`);

const missing = [...reads].filter((k) => !provided.has(k)).sort();
const unused = [...provided].filter((k) => !reads.has(k)).sort();

if (unused.length > 0) {
  console.log(`  note: passed but never read: ${unused.join(", ")}`);
}

if (missing.length === 0) {
  console.log("  ok    every field the Forge reads is passed to it");
  console.log("");
  console.log(">>> forge-snap: all assertions passed");
  process.exit(0);
}
console.log("");
for (const k of missing) {
  const line = forge.slice(0, forge.indexOf("snapshot." + k)).split("\n").length;
  console.log(`  FAIL  MineForge reads snapshot.${k} (line ${line}) and the shop does not pass it`);
}
console.log("");
console.log(`>>> forge-snap: ${missing.length} FAILED — field(s) read but never passed`);
process.exit(1);
