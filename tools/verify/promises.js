// WHAT A KID READS IS TRUE AND CLEAN (launch audit S39 and S41, owner 2026-10-19).
//
//   S39  The lobby leaderboards printed a reward on every rank, down to a
//        "101+ Everyone else — 100 gems" row, and nothing ever paid any of it.
//        The owner: remove the text. Neither the boards nor the player's own
//        "YouRow" may name a gem amount.
//   S41  A fallback find line read "You found some crazy shit". It is a kids'
//        game: no player-facing string in src/ may swear.
//
// Comments are stripped first (owner quotes in comments are not on screen).
//
//   node tools/verify/promises.js
"use strict";
const fs = require("fs");
const path = require("path");
const Luau = require("./_luau");

const ROOT = path.resolve(__dirname, "../..");
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const code = (s) => s.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };
const strings = (src) => [...src.matchAll(/"((?:[^"\\\n]|\\.)*)"/g)].map((m) => m[1]);

// S39
const lb = code(read("src/ServerScriptService/Mine/LeaderboardService/init.luau"));
check(lb.length > 5000, "read LeaderboardService");
check(!/rewardForRank|paintTailRow|Everyone else/.test(lb), "S39 no reward-per-rank table and no \"101+ Everyone else\" row");
const lbPromises = strings(lb).filter((s) => /\d[\d,]*\s*gems|\bpack\b/i.test(s));
check(lbPromises.length === 0, `...and no string on a board names gems or packs (${lbPromises.join(" | ") || "none"})`);
const cl = code(read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau"));
const youRow = (cl.match(/elseif action == "leaderboard" and type\(payload\) == "table" then[\s\S]*?\n\t(?:elseif |end\n)/) || [""])[0];
check(youRow.length > 200 && /you\.Text = /.test(youRow), "found the player's own row (YouRow)");
// ("gems" alone is a board's kind; an amount of gems, or a pack, is a reward.)
check(!strings(youRow).some((s) => /\d[\d,]*\s*gems|\bpack\b/i.test(s)), "...and it shows the rank with no reward after it");

// S41
const BAD = /\b(shit\w*|fuck\w*|bitch\w*|cunt\w*|asshole\w*|bastard\w*)\b/i;
const files = [];
const walk = (dir) => {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p);
    else if (e.name.endsWith(".luau")) files.push(p);
  }
};
walk(path.join(ROOT, "src"));
const hits = [];
for (const f of files) {
  for (const s of strings(code(Luau.readSrc(f)))) {
    if (BAD.test(s)) hits.push(path.relative(ROOT, f) + ': "' + s + '"');
  }
}
check(files.length >= 100, `scanned ${files.length} .luau files`);
check(hits.length === 0, `S41 no player-facing string swears${hits.length ? ": " + hits.join("; ") : ""}`);
const sv = read("src/ServerScriptService/Mine/MineServer.server.luau");
check((sv.match(/blurb = (?:blurb|def\.blurb) or "You found something amazing!"/g) || []).length === 2,
  "...the two fallback find lines are kid-safe");

console.log("");
console.log(fail > 0 ? `>>> promises: ${fail} FAILED` : ">>> promises: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
