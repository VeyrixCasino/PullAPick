// A SERVER VERB WITH NO CALLER IS A FEATURE THAT DOES NOT EXIST.
//
// This failure happened FIVE times in one audit, and every instance looked
// identical: a verb written carefully, gated correctly, dispatched, priced,
// persisted -- and reachable from nothing. The UI often advertised it.
//
//   launchSeason   the game could never start
//   buyCharter     4 gem upgrades, and the panel said "the charter spends them"
//   buyPouch       3 rune cases, and the panel said "open a Rune Case"
//   buyCharm       36 token-priced charms
//   skillBuySlot   a padlock with no price and no buy
//
// Nothing could catch it. Each half is correct on its own; only the ABSENCE
// of a pairing is wrong, and absence is exactly what a reader does not notice.
// So it is checked here instead.
//
// HOW IT WORKS. Every `action == "name"` in MineServer's dispatcher is a verb.
// Every `FireServer("name")` under src/ outside ServerScriptService and
// ServerStorage is a caller. A verb with no caller and no entry in KNOWN below
// fails the suite.
//
// Adding a verb to KNOWN is a decision, not a formality: write the reason. If
// the honest reason is "nothing calls it yet", that is a bug, not an entry.
//
// Run: node tools/verify/orphan-verbs.js
const fs = require("fs"), path = require("path");
const ROOT = path.join(__dirname, "..", "..");

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

//[[ Verbs that are reachable, or deliberately unreachable, for a stated
// reason. Every one of these was confirmed against the source. ]]
const KNOWN = {
  // Called from the admin CHAT command, not from a client FireServer.
  launchSeason: "MineAdmin '/admin launch now' calls it through deps, by design",

  // Studio-only, and all four are gated on Svc.Run:IsStudio() at the verb.
  devGrant: "Studio only, gated at the verb",
  debugGrantRune: "Studio only, gated at the verb",
  debugGrantBlastSet: "Studio only, gated at the verb",
  debugGrantL99Blast: "Studio only, gated at the verb",

  // Answered deliberately so an OLD CLIENT gets a sensible reply.
  coinflipAsk: "answered with a redirect; kept for old clients",
  fossil_assemble: "fossils are retired (TODO 0.12); answered so old clients hear why",
  fossil_equip: "fossils are retired; answered so old clients hear why",
  fossil_sell: "fossils are retired; answered so old clients hear why",
  dig: "legacy name; the live path is swingBlock",

  // Server-side aliases for a verb the client does fire under another name.
  tradeReady: "legacy alias for trade accept, which the client does fire",
  skillSacrifice: "alias",
  unsocketToolRune: "alias",
  unequipTool: "alias",
  profileView: "reached server-side from SocialService.publicProfile",

  // KNOWN GAPS, each with the reason it is not simply wired.
  // (buyCrate was here until the set picker landed; the stale-entry check
  // below is what caught that its excuse had expired.)
  friendRemove: "GAP: social is half-wired -- create and leave exist, invite/remove/msg do not",
  socialInviteGroup: "GAP: social is half-wired",
  socialGroupMsg: "GAP: social is half-wired",
};

const srv = fs.readFileSync(
  path.join(ROOT, "src/ServerScriptService/Mine/MineServer.server.luau"), "utf8");

const actions = [...new Set(
  [...srv.matchAll(/action\s*==\s*"([A-Za-z_][A-Za-z0-9_]*)"/g)].map((m) => m[1]))];
ok(actions.length > 100, "the dispatcher was parsed", `${actions.length} actions`);

//[[ Client-reachable = anything a player's machine runs. ServerScriptService
// and ServerStorage are the server's own code and cannot FireServer. ]]
const files = [];
(function walk(d) {
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, e.name);
    if (e.isDirectory()) walk(p);
    else if (e.name.endsWith(".luau")) files.push(p);
  }
})(path.join(ROOT, "src"));

let client = "";
for (const f of files) {
  if (f.includes("ServerScriptService") || f.includes("ServerStorage")) continue;
  client += fs.readFileSync(f, "utf8");
}
const callers = new Set(
  [...client.matchAll(/FireServer\(\s*"([A-Za-z_][A-Za-z0-9_]*)"/g)].map((m) => m[1]));
ok(callers.size > 100, "client callers were parsed", `${callers.size} distinct names`);

const orphans = actions.filter((a) => !callers.has(a)).sort();
const unexplained = orphans.filter((a) => !KNOWN[a]);

console.log(`  info  ${orphans.length} verbs have no FireServer caller; ${orphans.length - unexplained.length} are accounted for`);

ok(unexplained.length === 0,
  "every verb without a caller has a stated reason",
  unexplained.length > 0
    ? "UNEXPLAINED: " + unexplained.join(", ")
    : "no new orphans");

//[[ The other direction, which is cheaper to get wrong: a client firing a name
// the dispatcher does not handle is a button that silently does nothing. ]]
const ghosts = [...callers].filter((c) => !actions.includes(c)).sort();
//[[ Some FireServer names are handled by a DIFFERENT remote (admin, trade,
// social have their own), so this reports rather than fails. ]]
console.log(`  info  ${ghosts.length} client FireServer names are not in the main dispatcher`
  + (ghosts.length ? " (may belong to admin/trade/social remotes)" : ""));

//[[ KNOWN must not rot either: an entry for a verb that now HAS a caller, or
// that no longer exists, is a stale excuse and hides the next real one. ]]
const stale = Object.keys(KNOWN).filter((k) => !orphans.includes(k)).sort();
ok(stale.length === 0,
  "no stale entries in KNOWN",
  stale.length > 0
    ? "these now have callers or are gone, so drop them: " + stale.join(", ")
    : `all ${Object.keys(KNOWN).length} entries still apply`);

const gaps = Object.entries(KNOWN).filter(([, v]) => v.startsWith("GAP:"));
console.log(`  info  ${gaps.length} known gaps still owed:`);
for (const [k, v] of gaps) console.log(`          ${k} -- ${v.slice(5).trim()}`);

console.log(fails === 0 ? ">>> orphan-verbs OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
