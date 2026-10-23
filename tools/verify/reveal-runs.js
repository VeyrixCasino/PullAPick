// Reveals that run through many results, and the rare-find card (owner's
// launch-audit picks, 2026-10-19: S24, S25, S28, S29).
//
//   S24  a Gear Vault (the daily wheel's prize) reels every item it paid --
//        it reeled min(#cards, 3), and its five are sorted worst to best, so
//        the two best never showed -- and each next reel starts when the
//        player CLOSES the last, not when it stops. ctl.play's onDone keeps
//        its meaning (the reel stopped); the wait is a separate onClosed.
//   S25  a run of mystery cases (up to 50 spins of 5.4 s) has SKIP ALL: one
//        grid of every result, from the payloads the server sent, and one
//        celebration, for the best.
//   S28  a rare find's card prints its TRUE rarity; the finish bump (shiny
//        +1, shadow +2, nightmare +3) only sizes the celebration.
//   S29  the lucky-block SKIP ALL card lists the enchant books, potions and
//        which skin cases, not just gems, stardust and a case count.
//
// The run logic (playRun, close, SKIP ALL) and the lucky card's rows are
// lifted out of MineGradeReveal and RUN in luau against stubs, and so is
// MinePackFX's pull score.
//
//   node tools/verify/reveal-runs.js
"use strict";
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");

const ROOT = path.resolve(__dirname, "../..");
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const code = (s) => s.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };
console.log("reveal-runs: every vault item, SKIP ALL for case runs, true rarity on finds, the lucky run card");

const between = (s, a, b, from) => {
  const i = s.indexOf(a, from || 0);
  const j = i < 0 ? -1 : s.indexOf(b, i + a.length);
  return (i < 0 || j < 0) ? "" : s.slice(i, j + b.length);
};
function runLuau(src) {
  const tmp = path.join(os.tmpdir(), "mfc-reveal-runs-" + process.pid + "-" + Math.random().toString(36).slice(2) + ".luau");
  fs.writeFileSync(tmp, src);
  let out = "";
  try { out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" }); } catch (e) {
    out = String(e.stdout || "") + String(e.stderr || "");
    console.log(out.split("\n").slice(-6).map((l) => "        " + l).join("\n"));
  }
  fs.unlinkSync(tmp);
  return out.replace(/\t/g, " ");
}
const lineOf = (out, k) => { const m = out.match(new RegExp("^" + k + " (.*)$", "m")); return m ? m[1] : ""; };
if (!Luau.ready) { console.log(Luau.missing("luau") + "; skipping"); process.exit(1); }

const gradeRaw = read("src/ReplicatedStorage/Mine/Shared/MineGradeReveal.luau");
const grade = code(gradeRaw);
const clientRaw = read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau");
const client = code(clientRaw);

// ----------------------------------------------------------- S24 / S25 --
// Since 2026-10-19 (owner: every case "up to 5 slot spins at a time"; see
// case-stack.js) the gear branch hands its design to ClientFns.playCaseReels,
// which reels every item through ClientFns.gearReels and plays the run in
// stacked rounds. The S24 / S25 properties are pinned where they now live.
const gearBranch = between(client, 'if design.kind == "gear" then', "local openedId = design.packId");
check(gearBranch.length > 50 && /ClientFns\.playCaseReels\(\{ design \}, clearPackRevealBusy\)/.test(gearBranch),
  "found the gear case branch of the opened handler (it plays through ClientFns.playCaseReels)");
const gearReels = between(client, "function ClientFns.gearReels(design)", "\nend");
check(!/math\.min\(#cards, 3\)/.test(gearReels) && /for _, item in ipairs\(design\.cards or \{\}\) do\s*table\.insert\(reels, reelAround\(item\)\)/.test(gearReels),
  "a gear case reels EVERY item it paid (a Gear Vault's five), not the first three");
const caseReels = between(client, "function ClientFns.playCaseReels(designs, done)", "\nend");
check(/caseScreen\(\)\.playRun\(reels, \{/.test(caseReels) && /onDone = done/.test(caseReels)
  && /ClientFns\.gearReels\(d\)/.test(caseReels) && !/caseScreen\(\)\.play\(payload, nextReel\)/.test(client),
  "a run of cases (a vault's items too) plays through playRun, so it chains on close and gets SKIP ALL");

const caseSpin = between(grade, "function MineGradeReveal.caseSpin(parent, opts)", "\nreturn MineGradeReveal");
check(caseSpin.length > 5000, "found the case reel (MineGradeReveal.caseSpin)");
check(/function ctl\.play\(payload, onDone, playOpts\)/.test(caseSpin)
  && /celebrate\(grade, winInk, payload\)\s*if onDone then\s*task\.defer\(onDone, payload\)/.test(caseSpin),
  "ctl.play's onDone still fires when the reel stops; waiting for the close is a separate onClosed");
check(/Text = "SKIP ALL"/.test(caseSpin) && /finishNow\(true\)/.test(caseSpin) && /if silent == true then\s*return/.test(caseSpin),
  "SKIP ALL stops the reel without its own celebration");
check(/local function showSummary\(list\)[\s\S]*summaryTile\(e\.p, n, n == 1\)[\s\S]*celebrate\(grade, ink, best\)/.test(caseSpin),
  "the SKIP ALL grid draws every result and celebrates the best one, once");
check(/local row = \(type\(p\.reel\) == "table" and p\.reel\[tonumber\(p\.at\) or 0\]\)/.test(caseSpin),
  "each grid tile is the winning tile the server built (payload.reel[payload.at])");

// The run logic, run: playRun, close and the SKIP ALL handler, against stubs.
const playRun = between(gradeRaw, "\tfunction ctl.playRun(list, runOpts)", "\n\tend\n");
const closeFn = between(gradeRaw, "\tfunction ctl.close()", "\n\tend\n", gradeRaw.indexOf("\tfunction ctl.playRun("));
const skipAll = between(gradeRaw, "\tskipAllBtn.MouseButton1Click:Connect(function()", "\n\tend)\n");
check(playRun.length > 500 && closeFn.length > 200 && skipAll.length > 300, "lifted playRun, close and the SKIP ALL handler");
const runTest = `
task = { defer = function(f, ...) f(...) end }
UDim2 = { fromScale = function() return {} end, fromOffset = function() return {} end }
local ctl = {}
local closeHooks, run, shown = {}, nil, nil
local playing, finishNow = false, nil
local played, summaryOf, stopped = {}, nil, 0
local summary, track, sub, boxStroke, box = {}, {}, {}, {}, {}
-- The stacked reels' pieces close() also resets (MineCaseStack; case-stack.js).
local stackHost, calmGrid = {}, false
local function stopStack() end
local function setBoxHeight() end
local MUTED, GOLD = "muted", "gold"
local skipAllBtn = { MouseButton1Click = {} }
local skipAllFn
function skipAllBtn.MouseButton1Click:Connect(f) skipAllFn = f end
local function clearCelebration() end
local function setGuiOn() end
local function refreshSkipAll() end
local function showSummary(all) summaryOf = all end
function ctl.play(payload, onDone, playOpts)
	if playOpts and playOpts.onClosed then table.insert(closeHooks, playOpts.onClosed) end
	shown = payload
	table.insert(played, payload.id)
	playing = true
	finishNow = function(silent) playing = false if silent then stopped += 1 end end
end
${playRun}
${closeFn}
${skipAll}
local function ids(t) local o = {} for _, p in ipairs(t or {}) do table.insert(o, type(p) == "table" and p.id or p) end return table.concat(o, ",") end
local function r(id) return { id = id, reel = {}, at = 1, rarity = "B" } end
local done = 0
ctl.playRun({ r("A"), r("B"), r("C") }, { onDone = function() done += 1 end })
print("START " .. ids(played) .. " " .. done)
playing = false -- the reel stopped: nothing more may start until it is closed
print("STOPPED " .. ids(played))
ctl.close()
print("CLOSE1 " .. ids(played) .. " " .. done)
ctl.close()
ctl.close()
print("END " .. ids(played) .. " " .. done)
played, done = {}, 0
ctl.playRun({ r("D"), r("E"), r("F") }, { onDone = function() done += 1 end })
ctl.playRun({ r("G") }, { onDone = function() done += 10 end })
skipAllFn()
print("SKIP " .. ids(played) .. " " .. ids(summaryOf) .. " " .. stopped .. " " .. done)
ctl.close()
print("SKIPCLOSE " .. ids(played) .. " " .. done)
`;
const runOut = runLuau(runTest);
check(lineOf(runOut, "START") === "A 0" && lineOf(runOut, "STOPPED") === "A",
  "a run starts its first reel, and the reel stopping starts nothing");
check(lineOf(runOut, "CLOSE1") === "A,B 0", "closing the result starts the next reel");
check(lineOf(runOut, "END") === "A,B,C 1", "closing the last result ends the run, once");
check(lineOf(runOut, "SKIP") === "D D,E,F,G 1 0",
  "SKIP ALL stops the spinning reel silently and shows every result of the run (one joined mid-run too)");
check(lineOf(runOut, "SKIPCLOSE") === "D 11", "closing the grid ends the run (both callers told), and nothing more spins");

// ------------------------------------------------------------------ S28 --
const found = between(client, "function ClientFns.foundReveal(payload)", "\nend");
check(found.length > 1500, "found ClientFns.foundReveal");
check(/rarityId = rarity,\s*hypeRarity = hype,/.test(found) && !/\brarity = FINISH_BUMP\[/.test(found)
  && /hype = FINISH_BUMP\[math\.min\(#FINISH_BUMP, at \+ step\)\]/.test(found),
  "a find's card keeps its true rarity; the finish bump rides as hypeRarity");
const fxRaw = read("src/ReplicatedStorage/Mine/Shared/MinePackFX.luau");
const scoreSrc = between(fxRaw, "local VARIANT_FALLBACK", "\n\treturn grade, band\nend\n");
check(scoreSrc.length > 1000 && /local base = MinePackFX\.hypeRankOf\(card, Cards\)/.test(scoreSrc),
  "the pull score (how loud the reveal gets) reads hypeRankOf");
const reveal = code(read("src/ReplicatedStorage/Mine/Shared/MinePackReveal.luau"));
check(/local rank = PackFX\.hypeRankOf\(card, Cards\)\s*if band == "GOD" or rank >= 5 then/.test(reveal)
  && /buildUp\(back, PackFX\.rankOf\(card, Cards\)\)/.test(reveal),
  "the big title sizes by the bump; the rarity build-up flickers the TRUE rarity");
const scoreTest = `
local MinePackFX = {}
local Cards = {
	RARITY_RANK = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6, Divine = 7, Exotic = 8 },
	VARIANT_RANK = { Normal = 1, Shiny = 2, Golden = 3, Prism = 4, Rainbow = 5 },
}
${scoreSrc}
local function band(c) local _, b = MinePackFX.pullScore(c, Cards) return b end
print("SHINY " .. band({ rarityId = "Rare", shiny = true, hypeRarity = "Epic" }) .. " " .. band({ rarityId = "Epic", shiny = true }))
print("SHADOW " .. band({ rarityId = "Rare", shadow = true, hypeRarity = "Legendary" }) .. " " .. band({ rarityId = "Legendary" }))
print("NIGHT " .. band({ rarityId = "Rare", hypeRarity = "Divine" }) .. " " .. band({ rarityId = "Divine" }))
print("PLAIN " .. band({ rarityId = "Rare" }))
print("RANK " .. MinePackFX.rankOf({ rarityId = "Rare", hypeRarity = "Divine" }, Cards) .. " " .. MinePackFX.hypeRankOf({ rarityId = "Rare", hypeRarity = "Divine" }, Cards))
`;
const scoreOut = runLuau(scoreTest);
check(lineOf(scoreOut, "SHINY") === "HIT HIT" && lineOf(scoreOut, "SHADOW") === "CHASE CHASE"
  && lineOf(scoreOut, "NIGHT") === "GOD GOD" && lineOf(scoreOut, "PLAIN") === "HIT",
  "a shiny/shadow/nightmare Rare celebrates like an Epic/Legendary/Divine");
check(lineOf(scoreOut, "RANK") === "3 7", "while its rarity, the one the card prints, stays Rare");
const paintLoot = between(client, "function ClientFns.paintLoot(parent, item, w)", "\nend");
check(/Cards\.RARITY_LABEL\[item\.rarityId\]/.test(paintLoot) && !/hypeRarity/.test(paintLoot),
  "the find's card prints rarityId and never the bump");

// ------------------------------------------------------------------ S29 --
const lucky = between(grade, "function MineGradeReveal.lucky(parent, opts)", "\nend\n");
check(/showCard\(#all \.\. " lucky blocks opened", best, nil, nil, runRows\(all\)\)/.test(lucky),
  "the lucky SKIP ALL card is built from every block's loot (runRows)");
const prettySrc = between(gradeRaw, "\tlocal function pretty(id)", "\n\tend\n");
const rowsSrc = between(gradeRaw, "\tlocal function runRows(all)", "\n\tend\n");
check(prettySrc.length > 50 && rowsSrc.length > 1500, "lifted runRows");
const rowsTest = `
local fmt = tostring
${prettySrc}
${rowsSrc}
local all = {
	{ loot = { caseId = "case_3", caseQty = 2, caseName = "Wild Case", books = { {}, {} } } },
	{ loot = { caseId = "case_3", caseQty = 1, caseName = "Wild Case", books = { {} }, dust = 500 } },
	{ loot = { oreId = "peridot", oreCaseName = "Peridot Case", books = { {}, {} } } },
	{ loot = { oreId = "peridot", oreCaseName = "Peridot Case", gems = 40 } },
	{ loot = { oreId = "starmetal", oreCaseName = "Starmetal Case", potionId = "luck_potion", potionQty = 2 } },
	{ loot = { gems = 60, potionId = "luck_potion" } },
}
for _, row in ipairs(runRows(all)) do print("ROW " .. row.text .. " | " .. tostring(row.packId or row.icon or row.emoji)) end
`;
const rowsOut = runLuau(rowsTest);
const rowTexts = [...rowsOut.matchAll(/^ROW (.*)$/gm)].map((m) => m[1]);
const has = (t) => rowTexts.some((r) => r.startsWith(t));
check(has("3x  Wild Case | case_3"), "mystery cases are named and totalled (3x Wild Case), with their case art");
check(has("2x  Peridot Case | peridot_ore_pack") && has("Starmetal Case | starmetal_ore_pack"),
  "every skin case is named (2x Peridot Case, Starmetal Case), in its ore's colour");
check(has("3x  Luck potion"), "potions are listed and totalled (3x Luck potion)");
check(has("5  Enchant books, for the Forge"), "the enchant books are counted (5 books from three blocks)");
check(has("100  Gems") && has("500  Stardust"), "gems and stardust are still summed");

console.log(fail === 0 ? ">>> reveal-runs OK" : `>>> ${fail} FAILED`);
process.exit(fail === 0 ? 0 : 1);
