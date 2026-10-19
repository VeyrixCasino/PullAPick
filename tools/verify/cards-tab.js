// The Inventory's Cards tab and the Hats/Faces collection (owner's launch-audit
// picks, 2026-10-19: M5, S35, S37).
//
//   M5   the team rail draws the real number of seats. It drew four, and the
//        fourth said "GET VIP" and opened the VIP pass, but VIP adds no seat
//        (MineConfig.MAX_PET_SLOTS is 3 for everybody).
//   S35  card faces are kept by card id and repainted only when something on
//        them changed; the body clear never destroys a kept one; a closed
//        window keeps none; a reveal over the tab defers its redraw. The cache
//        logic is RUN in luau (lifted out of MineInventoryView) against stub
//        frames: paint once, reuse, repaint on a change, lift, prune.
//   S37  Collection -> Hats/Faces lists what can drop (MineHats.dropCatalog,
//        the pools MineGear.catalogFor rolls from), not the NewGear prototype.
//
//   node tools/verify/cards-tab.js
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
console.log("cards-tab: real seats, kept card faces, the hats and faces that can drop");

const viewRaw = read("src/ReplicatedStorage/Mine/Shared/MineInventoryView.luau");
const view = code(viewRaw);
const between = (s, a, b) => {
  const i = s.indexOf(a);
  const j = i < 0 ? -1 : s.indexOf(b, i + a.length);
  return (i < 0 || j < 0) ? "" : s.slice(i, j);
};
const cardsTab = between(view, "local function renderOwnedCards()", "local BOOST_LABEL = {");

// ------------------------------------------------------------------ M5 --
const cfg = code(read("src/ReplicatedStorage/Mine/Shared/MineConfig.luau"));
check(/MAX_PET_SLOTS\s*=\s*3\b/.test(cfg), "MineConfig.MAX_PET_SLOTS is 3: VIP adds no seat");
check(cardsTab.length > 3000, "found the Cards tab (renderOwnedCards)");
check(/for i = 1, petCap do/.test(cardsTab) && !/for i = 1, 4 do/.test(cardsTab),
  "the team rail draws one box per real seat (petCap), not four");
check(!/GET VIP|onBuyVipPass|"VIP"/.test(cardsTab), "no seat says GET VIP or opens the VIP pass");
check(!/"vipSeat"/.test(view), "no VIP seat item is left on the equipment card either");
check(/cardPetSeat = cardPetSeat % cap \+ 1/.test(cardsTab), "equipping steps to the next real seat, round the real seats");

// ----------------------------------------------------------------- S35 --
check(!/opts\.paintCard\(/.test(cardsTab) && /faces\.paint\(slot, card, CW\)/.test(cardsTab),
  "every card face goes through the face cache (faces.paint), never a bare paintCard");
check(!/opts\.petViewport/.test(cardsTab) && /faces\.railView\(box, pet\)/.test(cardsTab),
  "the team rail's pets come from the cache too (faces.railView)");
check(/faces\.prune\(cards\)/.test(cardsTab), "faces of cards no longer owned are let go");
check(/render = function\(\)\s*faces\.lift\(\)\s*baseRender\(\)/.test(view),
  "render lifts the kept faces out before the body is cleared");
check(/function ctl\.close\(\)[\s\S]{0,400}faces\.prune\(nil\)/.test(view), "closing the window keeps no pet models");
check(/local function cardsHidden\(\)\s*return busy and section == "inventory" and activeTab == "cards"/.test(view)
  && (view.match(/if root\.Visible and not cardsHidden\(\) then/g) || []).length === 2,
  "setState and setBusy do not redraw the Cards tab while a reveal covers it");
const client = code(read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau"));
check(/cardFaceKey = function\(card\) return ClientFns\.cardFaceKey\(card\) end/.test(client)
  && /function ClientFns\.cardFaceKey\(card\)[\s\S]{0,120}ClientFns\.cardContext\(card\)/.test(client),
  "the client keys faces on what paintCard reads besides the card (cardContext)");
check(/table\.sort\(list, function\(a, b\)\s*return cardLess\(a, b, cardSort, eq, indexOf, mergeCount, scoreOf\)/.test(cardsTab),
  "the sort scores each card once per redraw, not once per comparison");

// The cache itself, run: the block between `local faces` and renderOwnedCards.
const facesSrc = between(viewRaw, "\tlocal faces = { card = {}, rail = {} }", "\tlocal function renderOwnedCards()");
check(facesSrc.length > 1500, "found the face cache block");
if (!Luau.ready) { console.log(Luau.missing("luau") + "; skipping"); process.exit(1); }
const harness = `
typeof = function(x) return (type(x) == "table" and rawget(x, "__frame")) and "Instance" or type(x) end
UDim2 = { fromOffset = function() return {} end }
local made, destroyed = 0, 0
local function frame()
	local f = { parent = nil, dead = false }
	return setmetatable({ __frame = true }, {
		__index = function(_, k)
			if k == "Parent" then return f.parent end
			if k == "Destroy" then return function() if not f.dead then destroyed += 1 end f.dead = true f.parent = nil end end
			if k == "dead" then return f.dead end
		end,
		__newindex = function(_, k, v)
			if k == "Parent" then
				if f.dead then error("The Parent property is locked") end
				f.parent = v
			else
				rawset(_, k, v)
			end
		end,
	})
end
local faceKey = "3|zap"
local opts = {
	paintCard = function(slot, card, w) made += 1 local f = frame() f.Parent = slot return f end,
	petViewport = function(box) made += 1 local f = frame() f.Parent = box return f end,
	cardFaceKey = function(card) return faceKey end,
}
${facesSrc}
local slotA, slotB = {}, {}
local a = { id = "A1", name = "Fizzgig", rarityId = "Rare", variant = "Normal" }
local b = { id = "B2", name = "Taffy", rarityId = "Epic", variant = "Normal" }
faces.paint(slotA, a, 128)
faces.paint(slotB, b, 128)
print("FIRST", made)
faces.lift()
-- A redraw: a NEW table for the same card (as every snapshot sends), new slots.
local a2 = { id = "A1", name = "Fizzgig", rarityId = "Rare", variant = "Normal" }
local slotC = {}
faces.paint(slotC, a2, 128)
print("REUSE", made, faces.card.A1 and faces.card.A1.frame.Parent == slotC and "yes" or "no")
faces.lift()
local a3 = { id = "A1", name = "Fizzgig", rarityId = "Rare", variant = "Golden" }
faces.paint({}, a3, 128)
print("CHANGED", made, destroyed)
faces.lift()
faceKey = "2|zap"
faces.paint({}, a3, 128)
print("CONTEXT", made, destroyed)
faces.lift()
local box = {}
faces.railView(box, a3)
faces.lift()
faces.railView(box, { id = "A1", name = "Fizzgig", rarityId = "Rare", variant = "Golden" })
print("RAIL", made)
print("LIFTED", faces.card.A1.frame.Parent == nil and "yes" or "no")
faces.prune({ a3 })
print("PRUNE", faces.card.A1 and "kept" or "gone", faces.card.B2 and "kept" or "gone")
faces.prune(nil)
print("RELEASE", next(faces.card) == nil and next(faces.rail) == nil and "yes" or "no")
`;
const tmp = path.join(os.tmpdir(), "mfc-cards-tab-" + process.pid + ".luau");
fs.writeFileSync(tmp, harness);
let out = "";
try { out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" }); } catch (e) {
  out = String(e.stdout || "") + String(e.stderr || "");
  console.log(out.split("\n").slice(-8).join("\n"));
}
out = out.replace(/\t/g, " ");
fs.unlinkSync(tmp);
const line = (k) => { const m = out.match(new RegExp("^" + k + " (.*)$", "m")); return m ? m[1] : ""; };
check(line("FIRST") === "2", "two cards, two faces painted");
check(line("REUSE") === "2 yes", "a redraw of the same card reuses its face (no new model), in the new slot");
check(line("CHANGED") === "3 1", "a card that changed (merged to Golden) is repainted and its old face destroyed");
check(line("CONTEXT") === "4 2", "a change in what the face reads (pets out, the tool's proc) repaints it");
check(line("RAIL") === "5", "the team rail's viewport is kept the same way");
check(line("LIFTED") === "yes", "lift takes a kept face out of the body before it is cleared");
check(line("PRUNE") === "kept gone", "a card no longer owned loses its face");
check(line("RELEASE") === "yes", "closing releases every face");

// ----------------------------------------------------------------- S37 --
const newGear = between(view, "local function renderNewGear(kind)", "local function renderEquipmentDex()");
check(newGear.length > 2000, "found the Hats/Faces collection (renderNewGear)");
check(/Hats\.dropCatalog\(kind, newGearGrade\)/.test(newGear) && !/NG\.byGrade/.test(newGear),
  "the collection lists MineHats.dropCatalog, not the NewGear prototype");
const gear = code(read("src/ReplicatedStorage/Mine/Shared/MineGear.luau"));
const hatsSrc = code(read("src/ReplicatedStorage/Mine/Shared/MineHats.luau"));
check(/function MineGear\.catalogFor[\s\S]{0,200}Hats\.rollFor/.test(gear)
  && /function MineHats\.rollFor[\s\S]{0,200}rollFace[\s\S]{0,80}rollForSet/.test(hatsSrc)
  && /function MineHats\.rollFace[\s\S]{0,300}FACE_BY_GRADE/.test(hatsSrc)
  && /function MineHats\.rollForSet[\s\S]{0,300}DROP_BY_GRADE/.test(hatsSrc),
  "every hat and face drop rolls from MineHats' DROP_BY_GRADE and FACE_BY_GRADE (MineGear.catalogFor)");
const hatsTest = `
local Hats = (function()
${read("src/ReplicatedStorage/Mine/Shared/MineHats.luau").replace(/\n-- synced[^\n]*\s*$/, "")}
end)()
local function key(r) return r.id end
for _, kind in ipairs({ "hats", "faces" }) do
	local pools = (kind == "faces") and Hats.FACE_BY_GRADE or Hats.DROP_BY_GRADE
	local inPool, poolN = {}, 0
	for _, list in pairs(pools) do
		for _, r in ipairs(list) do inPool[key(r)] = true poolN += 1 end
	end
	local seen, n, outside, dupes = {}, 0, 0, 0
	local lastRank, ordered = 99, true
	local rankOf = {}
	for i, g in ipairs(Hats.GRADE_LADDER) do rankOf[g] = i end
	for _, r in ipairs(Hats.dropCatalog(kind)) do
		n += 1
		if seen[key(r)] then dupes += 1 end
		seen[key(r)] = true
		if not inPool[key(r)] then outside += 1 end
		local rk = rankOf[r.grade] or 0
		if rk > lastRank then ordered = false end
		lastRank = rk
	end
	local oneGrade = true
	for _, r in ipairs(Hats.dropCatalog(kind, "A")) do
		if r.grade ~= "A" then oneGrade = false end
	end
	print("CAT " .. kind .. " " .. n .. " " .. poolN .. " " .. outside .. " " .. dupes .. " " .. tostring(ordered) .. " " .. tostring(oneGrade))
end
local hatsN = 0
for _, r in ipairs(Hats.LIST) do if r.drop then hatsN += 1 end end
local facesN = 0
for _, r in ipairs(Hats.LEFTOVERS) do if r.kind == "Face" then facesN += 1 end end
print("ROWS " .. hatsN .. " " .. facesN)
`;
const tmp2 = path.join(os.tmpdir(), "mfc-cards-tab-hats-" + process.pid + ".luau");
fs.writeFileSync(tmp2, hatsTest);
let out2 = "";
try { out2 = execFileSync(Luau.LUAU, [tmp2], { encoding: "utf8" }); } catch (e) {
  out2 = String(e.stdout || "") + String(e.stderr || "");
  console.log(out2.split("\n").slice(-8).join("\n"));
}
fs.unlinkSync(tmp2);
const cat = (k) => { const m = out2.match(new RegExp("^CAT " + k + " (.*)$", "m")); return m ? m[1].split(" ") : []; };
const rows = (out2.match(/^ROWS (\d+) (\d+)$/m) || []).slice(1).map(Number);
const h = cat("hats"), f = cat("faces");
check(h.length === 6 && Number(h[0]) === Number(h[1]) && Number(h[0]) === rows[0] && h[2] === "0" && h[3] === "0",
  `Hats that can drop: all ${h[0]} droppable hats, each once, nothing that does not drop`);
check(f.length === 6 && Number(f[0]) === Number(f[1]) && Number(f[0]) === rows[1] && f[2] === "0" && f[3] === "0",
  `Faces that can drop: all ${f[0]} faces in the face pools, each once`);
check(h[4] === "true" && f[4] === "true" && h[5] === "true" && f[5] === "true",
  "best grade first, and a grade chip shows only that grade");

console.log(fail === 0 ? ">>> cards-tab OK" : `>>> ${fail} FAILED`);
process.exit(fail === 0 ? 0 : 1);
