// A pet's family and trait, its conditional-trait text and its Special-gate
// notes (owner's launch-audit picks, 2026-10-19: S32, S33, S34).
//
// Runs the real MineCards, MineEnchants and the whole pet roster (zone pots,
// the 19 sets, Event Horizon, the holiday packs) in luau:
//
//   S32  every named pet hashes its family and trait from its name and home.
//        Before this, MineSetPacks.petCard minted every pack pet with index 1
//        and a home that is no legacy set, so all of them were family Crystal
//        (Facet Eye) with one trait per length of the home's id. Asserted: the
//        spread over the roster is healthy (no family over 30%, all 12 traits
//        used, none over 15%), every big home is mixed, every copy of a pet
//        from any source (pack, wheel, lucky block, Event Horizon's
//        "genesis_spark") agrees, the server's pay (applyKit) and the card's
//        text read the same identity, and the 41 legacy sets' prints keep the
//        identity their (setId, index) always gave them.
//   S33  Lone Wolf and Squad Bond lines read the pets-out count they are paid
//        on, and the card painter passes it.
//   S34  a line the Special gate zeroes says so ("needs a Zap Special"); the
//        live family read off a gated boosts table is the gate's own pick.
//
//   node tools/verify/pet-identity.js
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");
const Shared = require("./_shared");

const ROOT = path.resolve(__dirname, "../..");
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const code = (s) => s.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

console.log("pet-identity: family and trait from the name, trait text, Special-gate notes");
if (!Luau.ready) { console.log(Luau.missing("luau") + "; skipping"); process.exit(1); }

const test = `
local Cards = require(SHARED:FindFirstChild("MineCards"))
local Roster = require(SHARED:FindFirstChild("MinePetRoster"))
local E = require(SHARED:FindFirstChild("MineEnchants"))
local function out(...) print(table.concat({ ... }, " ")) end

-- S32: the roster, minted the way a pack mints it (MineSetPacks.petCard).
local fam, trait, combos, homes, total = {}, {}, {}, {}, 0
local sourceMismatch, payMismatch = 0, 0
for _, pet in ipairs(Roster.PETS) do
	local home = Roster.homeOf(pet)
	local card = { setId = home, index = 1, name = pet.name, typeId = "Crystal" }
	local f, t = Cards.familyTrait(card)
	total += 1
	fam[f] = (fam[f] or 0) + 1
	trait[t and t.id or "nil"] = (trait[t and t.id or "nil"] or 0) + 1
	combos[tostring(f) .. "/" .. tostring(t and t.id)] = true
	homes[home] = homes[home] or { n = 0, fam = {} }
	homes[home].n += 1
	homes[home].fam[f] = (homes[home].fam[f] or 0) + 1
	-- Every other source mints the same pet with another setId.
	for _, src in ipairs({ "group_wheel", "lucky_block", "genesis_spark", "dev", "meadow" }) do
		local f2, t2 = Cards.familyTrait({ setId = src, index = 1, name = pet.name, typeId = "Crystal" })
		if f2 ~= f or t2 ~= t then sourceMismatch += 1 end
	end
	-- The server's pay and the card's text read one identity. With three pets
	-- out a Lone Wolf pays nothing, so applyKit reports no trait for it.
	if total <= 400 then
		local b = Cards.emptyBoosts()
		local kit = Cards.applyKit(b, card, 1, 3)
		local dk = Cards.describe(card, 1, 3)
		local paidTrait = t
		if t and t.solo then
			paidTrait = nil
		end
		if not kit or kit.typeId ~= f or kit.trait ~= paidTrait or not dk or dk.typeId ~= f or dk.trait ~= t then
			payMismatch += 1
		end
	end
end
out("TOTAL", total)
local maxFam, nFam = 0, 0
for k, n in pairs(fam) do nFam += 1 maxFam = math.max(maxFam, n) out("FAM", k, n) end
local maxTrait, nTrait = 0, 0
for k, n in pairs(trait) do nTrait += 1 maxTrait = math.max(maxTrait, n) end
local nCombos = 0
for _ in pairs(combos) do nCombos += 1 end
out("SPREAD", nFam, maxFam, nTrait, maxTrait, nCombos)
local bigHomes, badHomes = 0, 0
for home, h in pairs(homes) do
	if h.n >= 40 then
		bigHomes += 1
		local m, k = 0, 0
		for _, n in pairs(h.fam) do m = math.max(m, n) k += 1 end
		if m / h.n > 0.35 or k < 6 then badHomes += 1 out("BADHOME", home, h.n, m, k) end
	end
end
out("HOMES", bigHomes, badHomes)
out("SOURCES", sourceMismatch)
out("PAY", payMismatch)

-- The 41 legacy sets keep their prints' identity.
local function hash01(a)
	local x = math.floor(a * 9973) % 100000
	return (x % 10000) / 10000
end
local prints, legacyBad, sets = 0, 0, 0
for setId, def in pairs(Cards.SETS) do
	sets += 1
	for i = 1, def.cardCount + def.secretCount do
		local c = Cards.getCard(setId, i)
		if c and not Cards.namedBoosts(c) then
			prints += 1
			local f, t = Cards.familyTrait(c)
			local seed = i * 131 + #setId * 17
			local wantF = Cards.typeName(Cards.typeOf(setId, i))
			local wantT = Cards.TRAITS[math.floor(hash01(seed + 9) * #Cards.TRAITS) + 1]
			if f ~= wantF or t ~= wantT then legacyBad += 1 end
		end
	end
end
out("LEGACY", sets, prints, legacyBad)

-- S33: the conditional traits read the count.
local function findTrait(id)
	for _, pet in ipairs(Roster.PETS) do
		local card = { setId = Roster.homeOf(pet), index = 1, name = pet.name, typeId = "Crystal" }
		local _, t = Cards.familyTrait(card)
		if t and t.id == id then return card end
	end
end
local function lineWith(card, n, needle)
	local _, lines = Cards.describe(card, 1, n)
	for _, l in ipairs(lines or {}) do
		if string.find(l, needle, 1, true) then return l end
	end
	return ""
end
local lone, squad = findTrait("loneWolf"), findTrait("squadBond")
out("LONE1", lone and (string.find(lineWith(lone, 1, "Lone Wolf"), "(active)", 1, true) and "yes" or "no") or "none")
out("LONE3", lone and (string.find(lineWith(lone, 3, "Lone Wolf"), "(off:", 1, true) and "yes" or "no") or "none")
out("SQUAD1", squad and (string.find(lineWith(squad, 1, "Squad Bond"), "(needs a second pet)", 1, true) and "yes" or "no") or "none")
out("SQUAD3", squad and (string.find(lineWith(squad, 3, "Squad Bond"), "(now +18% each)", 1, true) and "yes" or "no") or "none")

-- S34: the gate's notes.
local function gn(stats, live)
	local text, all = E.gateNote(stats, live)
	return tostring(text) .. "|" .. tostring(all)
end
out("NOTE1", gn({ "zap" }, "blast"))
out("NOTE2", gn({ "zap" }, "zap"))
out("NOTE3", gn({ "procPower" }, nil))
out("NOTE4", gn({ "procPower" }, "tide"))
out("NOTE5", gn({ "zap", "swingRate" }, "blast"))
out("NOTE6", gn({ "mineSpeed" }, nil))
local function boostsWith()
	return { zap = 0.3, zapDamage = 0.5, blastChance = 0.4, blastDamage = 0.2, blastRadius = 1, tidalWave = 0.2,
		tideDamage = 0.1, ricochet = 0.1, shatterDamage = 0.1, earthquake = 0.05, procPower = 0.3, mineSpeed = 1 }
end
out("LIVE", tostring(E.liveFamily(E.gateProcs(boostsWith(), { id = "zap", level = 1 }))),
	tostring(E.liveFamily(E.gateProcs(boostsWith(), nil))),
	tostring(E.liveFamily(E.gateProcs({ zap = 0, blastChance = 0, tidalWave = 0, ricochet = 0, earthquake = 0 }, nil))))
-- A pet whose kit has a Zap line, on a Blast tool and on a Zap tool.
local zapPet
for _, pet in ipairs(Roster.PETS) do
	local card = { setId = Roster.homeOf(pet), index = 1, name = pet.name, typeId = "Crystal" }
	local kit = Cards.namedBoosts(card)
	if kit and (tonumber(kit.zap) or 0) > 0 then zapPet = card break end
end
local function zapNote(live)
	if not zapPet then return "none" end
	local _, lines, notes = Cards.describe(zapPet, 1, 3, { family = live })
	for i, l in ipairs(lines) do
		if string.sub(l, 1, 4) == "Zap " then
			local n = notes[i]
			return n and (n.text .. "|" .. tostring(n.all)) or "nil"
		end
	end
	return "noline"
end
out("ZAPPET", zapNote("blast"), zapNote("zap"))
local _, _, noGate = Cards.describe(zapPet or {}, 1, 3)
out("NOGATE", tostring(next(noGate or {}) == nil))
`;

const lua = Shared.prelude(ROOT, [
  "MineCards", "MineStats", "MinePetBoosts", "MinePetRoster", "MineZonePets",
  "MineSetPets", "MineEHPets", "MineEnchants",
], ["SetPets", "HolidayPets"]) + test;
const tmp = path.join(require("os").tmpdir(), "mfc-pet-identity-" + process.pid + ".luau");
fs.writeFileSync(tmp, lua);
let outText = "";
try {
  outText = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8", maxBuffer: 1 << 26 });
} catch (e) {
  outText = String(e.stdout || "") + String(e.stderr || "");
  console.log(outText.split("\n").slice(-12).join("\n"));
  check(false, "the harness ran");
}
fs.unlinkSync(tmp);
const get = (key) => {
  const m = outText.match(new RegExp("^" + key + " (.*)$", "m"));
  return m ? m[1].split(" ") : null;
};

// S32
const total = Number((get("TOTAL") || [0])[0]);
check(total >= 3000, `the roster loads: ${total} named pets (zone pots, 19 sets, Event Horizon, holiday)`);
const sp = (get("SPREAD") || []).map(Number);
const [nFam, maxFam, nTrait, maxTrait, nCombos] = sp;
check(nFam === 8 && maxFam / total <= 0.30,
  `all 8 families in use and none over 30% (largest ${(100 * maxFam / total).toFixed(1)}%)`);
check(nTrait === 12 && maxTrait / total <= 0.15,
  `all 12 traits in use and none over 15% (largest ${(100 * maxTrait / total).toFixed(1)}%)`);
check(nCombos >= 90, `${nCombos} of 96 family x trait pairs in use`);
const homes = (get("HOMES") || []).map(Number);
check(homes[0] >= 25 && homes[1] === 0, `every home of 40+ pets is mixed: 6+ families, none over 35% (${homes[0]} homes)`);
check(Number((get("SOURCES") || [1])[0]) === 0, "a pet from a pack, the wheel, a lucky block or Event Horizon has one family and trait");
check(Number((get("PAY") || [1])[0]) === 0, "the server's pay (applyKit) and the card's lines (describe) read the same identity");
const legacy = (get("LEGACY") || []).map(Number);
check(legacy[0] === 41 && legacy[1] > 3000 && legacy[2] === 0,
  `the 41 legacy sets' ${legacy[1]} prints keep the identity (setId, index) gave them (${legacy[2]} moved)`);

// S33
check((get("LONE1") || [])[0] === "yes" && (get("LONE3") || [])[0] === "yes",
  "Lone Wolf reads (active) with one pet out and (off: ...) with three");
check((get("SQUAD1") || [])[0] === "yes" && (get("SQUAD3") || [])[0] === "yes",
  "Squad Bond reads (needs a second pet) with one out and (now +18% each) with three");
const client = code(read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau"));
const paint = client.slice(client.indexOf("paintCard = function(parent, card, w)"), client.indexOf("local function clear(body)"));
check(paint.length > 2000 && /ClientFns\.cardLines\(card, pow\)/.test(paint) && !/Cards\.describe\(card, pow\)/.test(paint),
  "the card painter reads its lines through ClientFns.cardLines, not a count-less describe");
check(/function ClientFns\.cardLines[\s\S]{0,200}Cards\.describe\(card, pow, n, gate\)/.test(client)
  && /function ClientFns\.cardContext[\s\S]{0,400}#eq[\s\S]{0,300}math\.min\(seats, n \+ 1\)/.test(client),
  "cardLines passes the pets-out count (the team, or the team the card would make)");
const server = code(read("src/ServerScriptService/Mine/MineServer.server.luau"));
check(/local n = #\(p\.equipped or \{\}\)/.test(server) && /Cards\.applyKit\(one, c, C\.cardPower\(c\), n\)/.test(server),
  "the server pays the traits off #p.equipped (Dig.petRows), the count the card reads");

// S34
const note = (k) => (get(k) || []).join(" ");
check(note("NOTE1") === "needs a Zap Special|true", "a Zap line on a Blast tool: needs a Zap Special, nothing on it pays");
check(note("NOTE2") === "nil|false" && note("NOTE6") === "nil|false", "a line the tool fires, or a plain stat, has no note");
check(note("NOTE3") === "needs a Special|true" && note("NOTE4") === "nil|false",
  "generic proc damage needs a Special only when no proc fires");
check(note("NOTE5") === "Zap part needs a Zap Special|false", "a line with a plain stat beside the zeroed one names the part");
check(note("LIVE") === "zap blast nil", "liveFamily reads the gate's pick: the Special's family, else the best proc, else none");
check(note("ZAPPET") === "needs a Zap Special|true nil", "a real Zap pet's card: dimmed on a Blast tool, clean on a Zap tool");
check(note("NOGATE") === "true", "no gate given (trades, old callers): no notes");
check(/local gated = lineNotes and lineNotes\[i\]/.test(paint) && /gated\.all\) and MUTED/.test(paint) && /gated\.text/.test(paint),
  "the card painter dims a fully gated line and prints its note");
const ench = code(read("src/ReplicatedStorage/Mine/Shared/MineEnchants.luau"));
check(/function M\.gateNote[\s\S]{0,300}M\.familyOfStat\(stat\)/.test(ench),
  "the note reads MineEnchants.familyOfStat, the map Dig.petShares scores pets by");

console.log(fail === 0 ? ">>> pet-identity OK" : `>>> ${fail} FAILED`);
process.exit(fail === 0 ? 0 : 1);
