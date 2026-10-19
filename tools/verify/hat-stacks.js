// EACH HAT ONCE, "xN" WHEN YOU HAVE SEVERAL.
//
// Owner, 2026-10-19 (wiki open-questions, "Candy Crypt v2"): "hat inventory is
// messy. each hat should say the hat, and if multiple say xXXX". It was worse
// than duplicates: the Equipment tab's Backpack listed every spare hat once per
// hat SEAT (three seats, three tiles each), and a hat worn in one seat showed up
// again from the other two.
//
//   * MineGear.stackKey / MineGear.stacks decide what is "the same hat": slot,
//     grade, catalog item, name and every stat line. RUN on the real MineGear.
//   * The three lists that show your hats (a seat's list, the Backpack, the
//     Collection's "Your hats") stack the spares with an "xN" badge, keep a worn
//     piece on its own tile, and act on ONE copy when you equip or sell.
//
// Fails on 3863d14 (no stackKey; every copy its own tile).
//
//   node tools/verify/hat-stacks.js
"use strict";
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");
const Shared = require("./_shared");

const ROOT = path.resolve(__dirname, "../..");
const SH = "src/ReplicatedStorage/Mine/Shared/";
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const code = (s) => s.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
let fail = 0;
const check = (ok, msg, detail) => {
  console.log((ok ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!ok) fail++;
};
const between = (s, a, b, from) => {
  const i = s.indexOf(a, from || 0);
  const j = i < 0 ? -1 : s.indexOf(b, i + a.length);
  return (i < 0 || j < 0) ? "" : s.slice(i, j + b.length);
};
console.log("hat-stacks: each hat once, with xN for copies; equip and sell act on one");

const INV = code(read(SH + "MineInventoryView.luau"));
const GEAR = code(read(SH + "MineGear.luau"));
check(/function MineGear\.stackKey\(piece\)/.test(GEAR) && /function MineGear\.stacks\(list, skip\)/.test(GEAR),
  "MineGear.stackKey and MineGear.stacks exist");

// A seat's list (Inventory -> Equipment).
const items = between(INV, "local function equipItems(slotId)", "\n\tlocal function equippedIn(slotId)");
check(/for _, st in ipairs\(Gear\.stacks\(pool, isWorn\)\) do\s*add\(st\.piece, st\)/.test(items)
  && /if isWorn\(g\) then\s*add\(g, nil\)/.test(items),
  "a seat lists each worn piece on its own and the spares as stacks");
check(/count = st and st\.count or 1, ids = st and st\.ids or \{ g\.id \}/.test(items) && /id = g\.id,/.test(items),
  "a stack carries its count and every copy's id; its id (what EQUIP and SELL send) is one copy");
check(/owned \+= tonumber\(it\.count\) or 1/.test(INV), "the seat header counts pieces, not tiles");
check(/eq\.countBadge\(tile, item\.count, UDim2\.fromOffset\(88, 6\), 20\)/.test(INV), "a stack's tile in the seat list says xN");
// The Backpack.
const bag = between(INV, 'sectionHeader("Backpack", 8)', "if eq.card and eq.card.Parent and eq.cardKey");
check(/local dupe = item\.source == "gear" and \(item\.worn or seenGear\[tostring\(item\.id\)\]\)/.test(bag)
  && /seenGear\[tostring\(item\.id\)\] = true/.test(bag),
  "the Backpack draws each hat once (not once per hat seat) and leaves out a hat worn in another seat");
check(/pick\.tap\("gear", stackIds, canSell\)/.test(bag) && /eq\.countBadge\(tile, item\.count/.test(bag),
  "...says xN, and ticks a stack as a whole for RECYCLE, like a pack stack");
// The Collection's "Your hats".
const mine = between(INV, "local function renderNewGear(kind)", "local Hats = Gear.Hats");
check(/for _, st in ipairs\(Gear\.stacks\(mine, isOn\)\) do/.test(mine) && /local g = st\.piece/.test(mine)
  && /countBadge\(well, st\.count/.test(mine) && /opts\.onEquipGear\(g\.id\)/.test(mine),
  "Collection -> Hats/Faces shows each hat once with xN, and EQUIP puts on one copy");
check(/local countBadge = eq\.countBadge\s*local eq = state\.equippedGear or \{\}/.test(mine),
  "...taking the badge from the mount's eq before the worn-seats eq hides it (no nil read)");
check(/\(stackN > 1\) and \("  x" \.\. stackN\)/.test(INV), "the item card's title says xN too");

if (!Luau.ready) {
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(1);
}
const test = Shared.prelude(ROOT, ["MineGear", "MineToolGrades", "MineStats", "MineTemper"], []) + `
local Gear = require(SHARED:FindFirstChild("MineGear"))
local set = Gear.SETS[1].id
local function hat(id, grade, cat)
	return Gear.makePiece(id, set, "hat", grade, { id = cat, catalogId = #cat * 1000 + 7, name = "Hat " .. cat, setId = set })
end
local function face(id, grade)
	return Gear.makePiece(id, set, "face", grade, { id = "smile", catalogId = 55, name = "Smile", setId = set })
end
local a, b, c = hat("id1", "C", "redcap"), hat("id2", "C", "redcap"), hat("id3", "C", "redcap")
print("SAMEKEY " .. tostring(Gear.stackKey(a) == Gear.stackKey(b) and Gear.stackKey(b) == Gear.stackKey(c)) .. " " .. tostring(string.find(Gear.stackKey(a), "id1", 1, true) == nil))
local list = { a, hat("id4", "B", "redcap"), b, hat("id5", "C", "bluecap"), c, face("id6", "C") }
local merged = hat("id7", "C", "redcap")
merged.merged = true
merged.stats = { { stat = "luck", pct = 0.5 }, { stat = "coinBonus", pct = 0.2 } }
table.insert(list, merged)
local out = {}
for _, st in ipairs(Gear.stacks(list)) do
	table.insert(out, st.count .. ":" .. st.piece.id .. ":" .. table.concat(st.ids, "+"))
end
print("STACKS " .. table.concat(out, " "))
local worn = { id2 = true }
local out2 = {}
for _, st in ipairs(Gear.stacks(list, function(g) return worn[g.id] end)) do
	table.insert(out2, st.count .. ":" .. table.concat(st.ids, "+"))
end
print("SKIP " .. table.concat(out2, " "))
print("EMPTY " .. #Gear.stacks({}) .. " " .. tostring(Gear.stackKey(nil)))
`;
const tmp = path.join(os.tmpdir(), "mfc-hat-stacks-" + process.pid + ".luau");
fs.writeFileSync(tmp, test);
let out = "";
try { out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8", maxBuffer: 1 << 26 }); } catch (e) {
  out = String(e.stdout || "") + String(e.stderr || "");
  console.log(out.split("\n").slice(-6).map((l) => "        " + l).join("\n"));
}
fs.unlinkSync(tmp);
out = out.replace(/\t/g, " ");
const lineOf = (k) => { const m = out.match(new RegExp("^" + k + " (.*)$", "m")); return m ? m[1] : ""; };
check(lineOf("SAMEKEY") === "true true", "three copies of one hat share a key, and the key holds no instance id", lineOf("SAMEKEY"));
check(lineOf("STACKS") === "3:id1:id1+id2+id3 1:id4:id4 1:id5:id5 1:id6:id6 1:id7:id7",
  "they stack x3 (first copy leads); another grade, another hat, a face and a merged hat each stand alone", lineOf("STACKS"));
check(lineOf("SKIP") === "2:id1+id3 1:id4 1:id5 1:id6 1:id7", "a worn copy is left out of the stack", lineOf("SKIP"));
check(lineOf("EMPTY") === "0 nil", "nothing stacks out of nothing", lineOf("EMPTY"));

console.log(fail === 0 ? ">>> hat-stacks OK" : `>>> ${fail} FAILED`);
process.exit(fail === 0 ? 0 : 1);
