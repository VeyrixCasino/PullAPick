// Runes, scrolls, sockets and tool traits are RETIRED (owner, 2026-10-12:
// "RETIRE RUNES AND TRAITS.. ENCHNATS TAKE OVERTHAT FEILD"; "no one has
// played.. ur good", so nothing is refunded). Enchants took the field.
//
// This keeps them gone, and pins what replaced each place they paid out:
//   1. the modules are deleted and nothing requires them
//   2. the server has no rune / scroll / trait verb, and boosts() pays none
//   3. the paid rewards that gave scrolls give enchant books (the pass,
//      the Founders pack), and the daily wheel's rune slice is 3 Lucky Books
//   4. the tutorial and the quests teach enchants
//   5. the Enchanter keeps Summon / Temper / Salvage / Dust (owner's pick)
//
//   node tools/verify/runes-retired.js
"use strict";
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "../..");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8").replace(/\r\n/g, "\n");
const exists = (p) => fs.existsSync(path.join(ROOT, p));
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

const SH = "src/ReplicatedStorage/Mine/Shared/";
const sv = read("src/ServerScriptService/Mine/MineServer.server.luau");
const cl = read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau");

// 1
const gone = ["MineRunes", "MineRunesView", "MineSocketsView", "MineTraits", "MineTraitView"];
check(gone.every((m) => !exists(SH + m + ".luau")), "the five rune and trait modules are deleted");
const live = [];
const walk = (dir) => {
  for (const e of fs.readdirSync(path.join(ROOT, dir), { withFileTypes: true })) {
    const rel = dir + "/" + e.name;
    if (e.isDirectory()) {
      if (!/ServerStorage$/.test(dir) || !/^_|^Wave|^MineParked/.test(e.name)) walk(rel);
    } else if (/\.luau$/.test(e.name) && !/^src\/ReplicatedStorage\/MineGear/.test(rel)) {
      const t = read(rel);
      for (const m of gone) if (new RegExp(`WaitForChild\\("${m}"|shared\\.${m}\\b|soft\\("${m}"\\)`).test(t)) live.push(rel + " -> " + m);
    }
  }
};
walk("src");
check(live.length === 0, "nothing requires them" + (live.length ? ": " + live.join(", ") : ""));

// 2
const verbs = ["rollRune", "fuseRune", "socketToolRune", "destroyToolRune", "socketPetRune", "socketGearRune",
  "buyScroll", "buyPouch", "buyCrate", "armWhiteScroll", "blackUnequipToolRune", "applyOmniscroll", "rollTrait", "debugGrantRune"];
const still = verbs.filter((v) => new RegExp(`action == "${v}"|function Verbs\\.${v}\\(`).test(sv));
check(still.length === 0, "the server has no rune, scroll or trait verb" + (still.length ? " (still: " + still.join(", ") + ")" : ""));
const boosts = (sv.match(/local function boosts\(p\)[\s\S]*?\n^end$/m) || [""])[0];
check(boosts.length > 0 && !/Runes\.|\.trait\b|toolSockets|petSockets|shopToolRunes/.test(boosts), "boosts() pays no rune and no trait");
check(/p\.runes, p\.toolSockets, p\.petSockets, p\.shopToolRunes, p\.scrolls = nil, nil, nil, nil, nil/.test(sv)
  && /t\.trait = nil/.test(sv), "an old save's runes, sockets, scrolls and traits are dropped on load (no refund: nobody has played)");
check(/RUNE_CASE = \{ rune_pack = true, rune_heavy_pack = true, rune_sealed_pack = true \}/.test(sv) && /table\.remove\(p\.packs, i\)/.test(sv),
  "...and so are unopened rune cases, which could never open now");
check(/enchBuyBundle = true/.test(sv), "the gem book bundle is a paid random item, so the region rule (PolicyNoRandom) covers it");

// 3
const scrolls = read(SH + "MineScrolls.luau");
check(!/scrolls = \{/.test(scrolls) && /prem = \{ books = 1 \}/.test(scrolls) && /free = \{ books = 2 \}/.test(scrolls),
  "the pass pays no scroll anywhere; books took their place (and since the 2026-10-16 rework, every 5th tier pays books on both tracks)");
check(/MineScrolls\.ITEMS = \{\}/.test(scrolls), "no scroll is for sale (ITEMS is empty)");
check((sv.match(/Dig\.grantBooks\((p|profile), reward\.books\)/g) || []).length === 2, "both pass-claim paths grant the books");
const founders = read(SH + "MineFounders.luau");
check(/MineFounders\.BOOKS = 3/.test(founders) && /opts\.grantBooks\(p, MineFounders\.BOOKS\)/.test(founders) && !/grantScrolls/.test(sv + founders),
  "the Founders pack's White Scroll became 3 enchant books");
const wheel = read(SH + "MineGroupWheel.luau");
check(/id = "heavy_runes", label = "3 LUCKY BOOKS"[^\n]*weight = 6,\s*\n\s*reward = \{ books = \{ n = 3, rank = "S" \} \}/.test(wheel),
  "the daily wheel's 6% rune slice pays 3 Lucky Books (owner: \"3 lucky enchanted books\")");
check(/type\(reward\.books\) == "table" and deps\.grantBooks/.test(read("src/ServerScriptService/Mine/GroupWheelService.luau"))
  && /grantBooks = Dig\.grantBooks,/.test(sv), "...and the wheel service grants them");

// 4
check(/\[8\] = \{ text = "FREE BOOKS! [^"]*ENCHANT your pick\.", panel = "forge", tab = "enchant", grantBooks = 2, requireAction = "enchApply"/.test(sv)
  && /order = \{ 27, 1, 2, 3, 4, 5, 6, 7, 12, 18, 8, 19, 20, 16, 14 \}/.test(sv),
  "the tutorial's rune lesson is one enchant lesson: 2 free books, the Forge on ENCHANT");
check(/Dig\.grantBooks\(p, d\.grantBooks, nil, \{ damage = true \}\)/.test(sv), "...Damage books only, the slot a new player has open");
check(/onApply = function\(plr, p\)\s*\n\s*introAdvance\(plr, p, 8\)/.test(sv), "...and applying a book ends the step");
const quests = read(SH + "MineQuests.luau");
check(!/stat = "runes"|stat = "traits"/.test(quests) && /id = "ench1",\s+stat = "enchants"/.test(quests) && /id = "bookmerge1", stat = "bookmerges"/.test(quests),
  "no quest asks for runes or traits; the ladder asks for enchants and book merges");
check(/stat == "enchants" then/.test(sv) && /stat == "bookmerges" then/.test(sv), "...and the server counts both");

// 5
check(/\{ "summon", "Summon" \}, \{ "temper", "Temper" \}, \{ "salvage", "Salvage" \}, \{ "dust", "Dust" \} \}/.test(cl)
  && !/"trait", "Traits"|"runes", "Merge"|"sockets", "Sockets"/.test(cl),
  "the Enchanter keeps Summon, Temper, Salvage and Dust (owner's pick); Traits, Merge and Sockets are gone");
check(!/row\("Rune Case"/.test(cl), "...and its Summon tab has no Rune Case row");
check(!/"runes"/.test((read(SH + "MineTradeView.luau").match(/local KINDS = \{[^}]*\}/) || [""])[0])
  && !/KIND_OK = \{[^}]*runes/.test(read("src/ServerScriptService/Mine/TradeService.luau")), "runes are no longer a kind of trade item");
check(!/rune_pack|rune_heavy_pack|rune_sealed_pack/.test(read(SH + "Mine1PacksData.luau") + read(SH + "MinePackConfig.luau")), "the three rune cases are gone from the packs and their prices");

console.log("");
console.log(fail > 0 ? `>>> runes-retired: ${fail} FAILED` : ">>> runes-retired: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
