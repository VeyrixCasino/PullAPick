#!/usr/bin/env node
// chest-tools: forever/chest tool drops are live, and rarity maps to ★.
//
// Pins open-questions #7: openChestBlock must close over a forward-declared
// rollChestTool (not a later `local function`, which is a nil global at the
// call site). Also pins TOOL_RARITY_FIND rungs against MineStars.WORD.

"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..", "..");
let failed = 0;

function ok(cond, msg) {
  if (cond) {
    console.log("  ok    " + msg);
  } else {
    failed++;
    console.log("  FAIL  " + msg);
  }
}

const serverPath = path.join(root, "src", "ServerScriptService", "Mine", "MineServer.server.luau");
const toolsPath = path.join(root, "src", "ReplicatedStorage", "Mine", "Shared", "MineTools.luau");
const starsPath = path.join(root, "src", "ReplicatedStorage", "Mine", "Shared", "MineStars.luau");

const server = fs.readFileSync(serverPath, "utf8");
const tools = fs.readFileSync(toolsPath, "utf8");
const stars = fs.readFileSync(starsPath, "utf8");

const openIdx = server.indexOf("local function openChestBlock");
const fwdIdx = server.indexOf("local rollChestTool");
const defMatch = server.match(/\nfunction rollChestTool\s*\(/);
const badLocalAfter = (() => {
  if (openIdx < 0) return true;
  const after = server.slice(openIdx);
  // A `local function rollChestTool` AFTER openChestBlock would re-shadow and
  // leave the forward upvalue nil forever.
  return /\nlocal function rollChestTool\s*\(/.test(after);
})();

ok(openIdx >= 0, "openChestBlock exists");
ok(fwdIdx >= 0 && fwdIdx < openIdx, "local rollChestTool is forward-declared before openChestBlock");
ok(!!defMatch, "rollChestTool is assigned with `function rollChestTool` (not a new local)");
ok(!badLocalAfter, "no `local function rollChestTool` after openChestBlock");

const findBlock = tools.match(/TOOL_RARITY_FIND\s*=\s*\{([\s\S]*?)\n\}/);
ok(!!findBlock, "TOOL_RARITY_FIND table present");

const EXPECT = ["Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic"];
const found = {};
if (findBlock) {
  for (const m of findBlock[1].matchAll(/(\w+)\s*=\s*([0-9.]+)/g)) {
    found[m[1]] = Number(m[2]);
  }
}
for (const r of EXPECT) {
  ok(found[r] != null && found[r] > 0, "TOOL_RARITY_FIND." + r + " = " + found[r]);
  ok(new RegExp("\\b" + r + "\\s*=").test(stars), "MineStars.WORD covers " + r);
}

const shop = fs.readFileSync(
  path.join(root, "src", "ReplicatedStorage", "Mine", "Shared", "MineShopView.luau"),
  "utf8"
);
ok(/MineStars/.test(shop) && /Stars\.beside/.test(shop), "Secrets rarity chip uses Stars.beside");

const inv = fs.readFileSync(
  path.join(root, "src", "ReplicatedStorage", "Mine", "Shared", "MineInventoryView.luau"),
  "utf8"
);
ok(/Stars\.beside\(def\.rarity/.test(inv), "Found forever tools sub-line uses Stars.beside");

console.log("");
if (failed) {
  console.log(">>> chest-tools FAIL (" + failed + ")");
  process.exit(1);
}
console.log(">>> chest-tools OK");
