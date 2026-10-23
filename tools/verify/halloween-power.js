// Halloween pets and skins: the 20% rule, the builds, and MineHalloweenPets.
//
// Owner, 2026-10-19 (wiki/open-questions.md, "Candy Crypt v2"):
//   * "12 more, new bodies";
//   * "Halloween Mythic+ pets and skins are 20% better than the best normal
//     ones, even after the event" ("20%");
//   * "make some of these pets influence builds that wouldn't be possible
//     without the pets ... (for example a big blast radius, or a high proc
//     chance pets)".
//
// Runs the real modules in luau (tools/verify/_shared.js): MineCards,
// MinePetRoster, MinePetBoosts, MineSetPets with HolidayPets/, MineEnchants,
// MineSkins, MineToolSkins, MineHalloweenPets, PetModelFactory with its
// PetBodies, and the server's MinePatterns. MineConfig does not load whole
// outside Roblox, so its real cardPower and multiplier tables are sliced in.
//
//   1. pets: every Halloween Mythic, Divine and Exotic scores at least 1.2x
//      (and its TOP_BEAT) the best non-Halloween pet on MineCards.boostScore,
//      Normal, power level 1, the number "best pets" and the Boosts sort use;
//      the generator's BEST_NORMAL is the pet the game finds;
//   2. skins: every Halloween S, SS and SSS skin is at least 1.2x the best other
//      skin of its grade on its damage base (MineSkins.baseOf, which the
//      server's MineToolSkins.wear spends) and on its kit's points;
//   3. MineHalloweenPets: pool() is the pack's own 72 (the 60 and the 12) and
//      the three older Halloween pets, as roster rows, pool(r) filters, isHalloween() is true for every copy from
//      any source and false for anything else, card() stacks, buildOf();
//   4. the 12 new pets: each builds today (PetModelFactory wears the fallback
//      Halloween body until the real one exists), family and trait come from
//      name and home like every named pet;
//   5. the builds: one ability family each; Hex Storm, Bog Tide, Gravequake and
//      Rattlebones' Shatter chance beat every normal pet's in that family by
//      20%; the Crater pets' Blast Radius pays (and only on a named Halloween
//      kit: a legacy print's still drops), only Halloween pets carry it and
//      at most 30 do (PROPOSAL §0 line 6), the proc gate keeps it on a bomb
//      and zeroes it on a Zap tool, and MinePatterns grows the bomb while
//      MAX_BLAST_RADIUS bounds it.
//
//   node tools/verify/halloween-power.js
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

console.log("halloween-power: the 20% rule for pets and skins, the builds, MineHalloweenPets");
if (!Luau.ready) { console.log(Luau.missing("luau") + "; skipping"); process.exit(1); }

// ---- MineConfig's real card power, sliced (it does not load outside Roblox) --
const cfg = read("src/ReplicatedStorage/Mine/Shared/MineConfig.luau");
const slice = (re) => (cfg.match(re) || [""])[0];
const cfgParts = {
  shiny: slice(/\nMineConfig\.SHINY_MULT = [^\n]+/),
  shadow: slice(/\nMineConfig\.SHADOW_MULT = [^\n]+/),
  variant: slice(/\nMineConfig\.VARIANT_MULT = \{[\s\S]*?\n\}/),
  rarity: slice(/\nMineConfig\.RARITY_MULT = \{[\s\S]*?\n\}/),
  cardPower: slice(/\nfunction MineConfig\.cardPower\(card\)[\s\S]*?\nend/),
};
const missing = Object.entries(cfgParts).filter(([, s]) => !s).map(([k]) => k);
check(missing.length === 0, "sliced MineConfig's cardPower, RARITY_MULT, VARIANT_MULT, SHINY_MULT and SHADOW_MULT" + (missing.length ? " (missing: " + missing.join(", ") + ")" : ""));
const miniConfig = `local MineConfig = {}\n${Object.values(cfgParts).join("\n")}\nreturn MineConfig`;

// The twelve of 2026-10-19, as the generator's input names them (a body built
// later drops its `fallback` from the generated rows, so the rows cannot say).
const hallowJson = path.join(ROOT, "tools/gen/holiday/halloween_2026.json");
const EXTRAS = fs.existsSync(hallowJson) ? (JSON.parse(read("tools/gen/holiday/halloween_2026.json")).extraPets || []) : [];
const lq = (s) => '"' + String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';
const extrasLua = "local EXTRAS = {\n" + EXTRAS.map((e) =>
  `\t{ name = ${lq(e.name)}, body = ${lq(e.body)}, fallback = ${lq(e.fallback)}, label = ${lq(e.label)} },`).join("\n") + "\n}\n";

const stubs = `
local U
U = setmetatable({}, {
	__index = function() return U end,
	__call = function() return U end,
	__mul = function() return U end, __add = function() return U end, __sub = function() return U end,
	__div = function() return U end, __unm = function() return U end,
})
Vector3 = setmetatable({ new = function(x, y, z) return { X = x or 0, Y = y or 0, Z = z or 0 } end }, { __index = function() return U end })
CFrame = U
Instance = U
UDim2 = U
NumberSequence = U
ColorSequence = U
NumberRange = U
NumberSequenceKeypoint = U
ColorSequenceKeypoint = U
`;

const test = `
local Cards = require(SHARED:FindFirstChild("MineCards"))
local Roster = require(SHARED:FindFirstChild("MinePetRoster"))
local Boosts = require(SHARED:FindFirstChild("MinePetBoosts"))
local Sets = require(SHARED:FindFirstChild("MineSetPets"))
local E = require(SHARED:FindFirstChild("MineEnchants"))
local Skins = require(SHARED:FindFirstChild("MineSkins"))
local ToolSkins = require(SHARED:FindFirstChild("MineToolSkins"))
local Cfg = require(SHARED:FindFirstChild("MineConfig"))
local Patterns = require(SHARED:FindFirstChild("MinePatterns"))
local okH, H = pcall(require, SHARED:FindFirstChild("MineHalloweenPets"))
local okF, F = pcall(require, SHARED:FindFirstChild("PetModelFactory"))
local function out(...) local t = {} for i, v in ipairs({ ... }) do t[i] = tostring(v) end print(table.concat(t, "|")) end
local TOP = { Mythic = true, Divine = true, Exotic = true }
local pack = Sets.BY_KEY and Sets.BY_KEY.halloween_2026

-- 1. The 20% rule on the game's own measure.
out("POWER", Cfg.cardPower({ rarityId = "Exotic" }), Cfg.cardPower({ rarityId = "Mythic", variant = "Golden" }))
local best, bestName, n, nHall = 0, "", 0, 0
local scores = {}
for _, pet in ipairs(Roster.PETS) do
	local card = { name = pet.name, rarityId = pet.tier, variant = "Normal", setId = Roster.homeOf(pet), index = 1 }
	local s = Cards.boostScore(card)
	scores[pet.name] = s
	n += 1
	if pet.holiday == "halloween" then
		nHall += 1
	elseif s > best then
		best, bestName = s, pet.name
	end
end
out("BEST", bestName, best, n, nHall)
local tops, worst, worstName, beatBad = 0, math.huge, "", 0
for _, row in ipairs((pack and pack.PETS) or {}) do
	if TOP[row.tier] then
		tops += 1
		local r = scores[row.name] / best
		if r < worst then worst, worstName = r, row.name end
		local beat = pack.TOP_BEAT and pack.TOP_BEAT[row.tier] or 0
		if r < beat - 1e-9 then beatBad += 1 out("BEATBAD", row.name, row.tier, r, beat) end
	end
end
out("TOPS", tops, worst, worstName, beatBad, pack and pack.BEST_NORMAL and pack.BEST_NORMAL.name or "nil")

-- 2. Skins: base and points, Halloween's S/SS/SSS against the best other skin of the grade.
for _, g in ipairs({ "S", "SS", "SSS" }) do
	local nb, np, hb, hp, hn = 0, 0, math.huge, math.huge, 0
	for _, s in ipairs(Skins.LIST) do
		if s.tier == g then
			if Skins.isHalloween(s) then
				hn += 1
				hb = math.min(hb, Skins.baseOf(s))
				hp = math.min(hp, Skins.pointsOf(s))
			else
				nb = math.max(nb, Skins.baseOf(s))
				np = math.max(np, Skins.pointsOf(s))
			end
		end
	end
	out("SKIN", g, hn, hb / nb, hp / np)
end
local king = Skins.byId("harvest_of_souls")
local worn = ToolSkins.wear({ family = "pickaxe", power = 1000 }, king)
out("WEAR", ToolSkins.mult(king), worn.power, Skins.edgeOf(Skins.byId("high_score_forever") or Skins.LIST[1]), ToolSkins.multText(king))

-- 3. MineHalloweenPets.
out("MODULE", okH, okH and "" or tostring(H))
if okH then
	local pool = H.pool()
	local same, home, hol = 0, 0, 0
	local names = {}
	for _, r in ipairs(pool) do
		names[r.name] = true
		if Roster.BY_NAME[r.name] == r then same += 1 end
		if r.set == "halloween_2026" then home += 1 end
		if r.holiday == "halloween" then hol += 1 end
	end
	local byTier, sum = {}, 0
	for _, t in ipairs({ "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic" }) do
		local p = H.pool(t)
		local ok = true
		for _, r in ipairs(p) do if r.tier ~= t then ok = false end end
		byTier[#byTier + 1] = t .. "=" .. #p .. (ok and "" or "!")
		sum += #p
	end
	pool[1] = nil
	local fresh = #H.pool() == 75 and H.pool()[1] ~= nil
	out("POOL", #H.pool(), same, home, hol, sum, table.concat(byTier, ","), tostring(fresh),
		tostring(names.Spindle == true and names.Spooky == true and names.Wisp == true))
	local missingNew = {}
	for _, nm in ipairs({ "Boomjaw", "Sparkplug", "Hexbolt", "Bogsplash", "Thudwing", "Moonbark", "Orbella", "Gravy", "Cawlin", "Bubblebrew", "Zoomstick", "Boo Manor" }) do
		if not names[nm] then table.insert(missingNew, nm) end
	end
	out("NEW", #missingNew, table.concat(missingNew, ","))
	local isBad, cardBad = 0, 0
	for _, r in ipairs(H.pool()) do
		local c = H.card(r)
		if c.cardKey ~= "halloween_2026:" .. r.name or c.rarityId ~= r.tier or c.animal ~= r.animal or c.name ~= r.name then cardBad += 1 end
		for _, src in ipairs({ "halloween_2026", "crypt", "trick_or_treat_case", "group_wheel" }) do
			if not H.isHalloween({ name = r.name, setId = src, index = 1 }) then isBad += 1 end
		end
		if not H.isHalloween(r.name) or not H.isHalloween({ cardKey = "halloween_2026:" .. r.name }) then isBad += 1 end
	end
	out("IS", isBad, cardBad, tostring(H.isHalloween("Spindle")), tostring(H.isHalloween({ name = "Segfault", setId = "chaos_theory" })),
		tostring(H.isHalloween(nil)), tostring(H.isHalloween({})), tostring(H.isHalloween("Ember Fox")), tostring(H.isHalloween("Bedrock Bob")))
	out("BUILDOF", tostring(H.buildOf("Boomjaw")), tostring(H.buildOf({ name = "Hexbolt" })), tostring(H.buildOf("Webster")), tostring(H.buildOf("Segfault")))
end

-- 4. The twelve: they build today, and keep the identity rules. A body built
-- since (PetBodies/Halloween*.luau) is worn as itself; one still to build,
-- as its fallback.
out("FACTORY", okF, okF and "" or tostring(F))
local idBad, famSeen, nFam = 0, {}, 0
for _, e in ipairs(EXTRAS) do
	local row = Roster.BY_NAME[e.name]
	if row then
		if okF then
			local a = F.ANIMALS[row.animal]
			local sp = a and F.resolveSpecies(a.species)
			local want = F.SPECIES[e.body] and e.body or e.fallback
			out("LOOK", row.name, a and a.species or "nil", want, tostring(sp), tostring(F.SPECIES[want] and F.SPECIES[want].season), F.SPECIES[e.body] and "built" or "planned")
		end
		local f1, t1 = Cards.familyTrait({ name = row.name, setId = "halloween_2026", index = 1, typeId = "Crystal" })
		local f2, t2 = Cards.familyTrait({ name = row.name, setId = "crypt", index = 1, typeId = "Crystal" })
		local kit = Cards.applyKit(Cards.emptyBoosts(), { name = row.name, rarityId = row.tier, setId = "crypt", index = 1 }, 1, 3)
		if f1 ~= f2 or t1 ~= t2 or not f1 or not t1 or not kit or kit.typeId ~= f1 then idBad += 1 end
		if f1 and not famSeen[f1] then famSeen[f1] = true nFam += 1 end
	end
end
out("IDENTITY", idBad, nFam)

-- 5. The builds.
local FAM = { zap = "zap", blastChance = "blast", tidalWave = "tide", ricochet = "shatter", earthquake = "quake" }
local bestChance = {}
local radiusPets, radiusOther = 0, 0
for _, pet in ipairs(Roster.PETS) do
	local kit = Boosts.boostsFor(pet.name) or {}
	local rm = Cfg.RARITY_MULT[pet.tier] or 1
	if (kit.blastRadius or 0) > 0 then
		if pet.holiday == "halloween" then radiusPets += 1 else radiusOther += 1 end
	end
	if pet.holiday ~= "halloween" then
		for stat, fam in pairs(FAM) do
			local c = (kit[stat] or 0) * rm
			if c > (bestChance[fam] or 0) then bestChance[fam] = c end
		end
	end
end
out("RADIUSPETS", radiusPets, radiusOther)
local function chanceOf(name, stat)
	local row = Roster.BY_NAME[name]
	local kit = Boosts.boostsFor(name) or {}
	return (kit[stat] or 0) * (Cfg.RARITY_MULT[row and row.tier or "Common"] or 1)
end
for _, b in ipairs({ { "Hexbolt", "zap" }, { "Bogsplash", "tidalWave" }, { "Thudwing", "earthquake" }, { "Rattlebones", "ricochet" } }) do
	local fams = {}
	local nf = 0
	for stat in pairs(Boosts.boostsFor(b[1]) or {}) do
		local f = E.familyOfStat(stat)
		if f and f ~= "*" and not fams[f] then fams[f] = true nf += 1 end
	end
	out("CHANCE", b[1], b[2], chanceOf(b[1], b[2]), bestChance[FAM[b[2]]], nf)
end
-- Crater: Blast Radius pays on the named kit; a legacy print's still drops.
local crater = Cards.emptyBoosts()
Cards.applyKit(crater, { name = "Boomjaw", rarityId = "Exotic", setId = "halloween_2026", index = 1 }, Cfg.cardPower({ rarityId = "Exotic" }), 1)
local spark = Cards.emptyBoosts()
Cards.applyKit(spark, { name = "Sparkplug", rarityId = "Divine", setId = "halloween_2026", index = 1 }, Cfg.cardPower({ rarityId = "Divine" }), 1)
local printRadius, printsWithRadius = 0, 0
for setId, def in pairs(Cards.SETS) do
	for i = 1, def.cardCount + def.secretCount do
		local c = Cards.getCard(setId, i)
		if c and not Cards.namedBoosts(c) then
			local k = Cards.getKit(setId, i)
			if k.primary == "blastRadius" or k.secondary == "blastRadius" then
				printsWithRadius += 1
				local b = Cards.emptyBoosts()
				Cards.applyKit(b, c, 4, 1)
				printRadius += b.blastRadius or 0
			end
		end
	end
end
out("CRATER", crater.blastRadius, crater.blastChance, spark.blastRadius, printsWithRadius, printRadius)
-- The gate: a bomb takes no Special, so gear's best proc stays; a Zap tool zeroes Blast Radius.
local team = Cards.emptyBoosts()
team.blastRadius = crater.blastRadius + spark.blastRadius
team.blastChance = crater.blastChance + spark.blastChance
local bomb = E.gateProcs(table.clone(team), nil)
local zapTool = E.gateProcs(table.clone(team), { id = "zap", level = 5 })
out("GATE", bomb.blastRadius, tostring(E.liveFamily(bomb)), zapTool.blastRadius, tostring(E.liveFamily(zapTool)))
-- MinePatterns: a radius-2 sphere bomb, plain, with the Crater pair, and with an absurd stack.
local bombDef = { pattern = "sphere", radius = 2, shape = false }
local plain = Patterns.count(bombDef, { blastRadius = 0 })
local withPair = Patterns.count(bombDef, { blastRadius = bomb.blastRadius })
local huge = Patterns.count(bombDef, { blastRadius = 50 })
local r6 = Patterns.count({ pattern = "sphere", radius = 6, shape = false }, { blastRadius = 0 })
out("PATTERN", plain, withPair, huge, r6, Patterns.MAX_BLAST_RADIUS)
`;

const names = ["MineCards", "MineStats", "MinePetBoosts", "MinePetRoster", "MineZonePets", "MineSetPets", "MineEHPets", "MineEnchants",
  "MineSkins", "MineToolSkins", "MineSetPacks", "PetModelFactory"];
let lua = stubs + Shared.prelude(ROOT, names, ["SetPets", "HolidayPets", "PetBodies"]);
lua += `SOURCES["Shared/MineConfig"] = function()\n${miniConfig}\nend\n`;
lua += `SOURCES["Shared/MinePatterns"] = function()\n${read("src/ServerScriptService/Mine/MinePatterns.luau")}\nend\n`;
// MineHalloweenPets is optional to the harness: on a tree without it the
// check must FAIL, not crash before it can say so.
const hpPath = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineHalloweenPets.luau");
if (fs.existsSync(hpPath)) lua += `SOURCES["Shared/MineHalloweenPets"] = function()\n${read("src/ReplicatedStorage/Mine/Shared/MineHalloweenPets.luau")}\nend\n`;
lua += extrasLua + test;
const tmp = path.join(require("os").tmpdir(), "mfc-halloween-power-" + process.pid + ".luau");
fs.writeFileSync(tmp, lua);
let outText = "";
try {
  outText = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8", maxBuffer: 1 << 28 });
} catch (e) {
  outText = String(e.stdout || "") + String(e.stderr || "");
  console.log(outText.split("\n").slice(-12).join("\n"));
  check(false, "the harness ran");
}
fs.unlinkSync(tmp);
const rows = outText.split("\n").filter(Boolean).map((l) => l.split("|"));
const get = (key) => rows.find((r) => r[0] === key) || null;
const all = (key) => rows.filter((r) => r[0] === key);
const num = (x) => Number(x);

// 1. pets
const power = get("POWER") || [];
check(num(power[1]) === 4.4 && Math.abs(num(power[2]) - 2.6 * 2.25) < 1e-9, `the real cardPower ran: Exotic Normal ${power[1]}, Mythic Golden ${power[2]}`);
const bestRow = get("BEST") || [];
const best = num(bestRow[2]);
check(num(bestRow[3]) > 3000 && num(bestRow[4]) >= 75 && best > 0, `the roster loads: ${bestRow[3]} pets, ${bestRow[4]} of them Halloween; the best normal pet is ${bestRow[1]} at ${best.toFixed(1)}`);
const tops = get("TOPS") || [];
check(num(tops[1]) === 10 && num(tops[2]) >= 1.2, `every Halloween Mythic, Divine and Exotic (${tops[1]}) is at least 1.2x the best normal pet: weakest ${tops[3]} at ${num(tops[2]).toFixed(3)}x`);
check(num(tops[4]) === 0 && tops[5] === bestRow[1], `each meets its TOP_BEAT (Mythic 1.2, Divine 1.3, Exotic 1.4), and the generator's BEST_NORMAL (${tops[5]}) is the one the game finds`);

// 2. skins
const skins = all("SKIN");
check(skins.length === 3 && skins.every((r) => num(r[2]) > 0 && num(r[3]) >= 1.2 - 1e-9 && num(r[4]) >= 1.2 * 0.98),
  "every Halloween S, SS and SSS skin is 1.2x the best other skin of its grade, on its damage base and its kit's points (kits round to 0.1%): " +
  skins.map((r) => `${r[1]} x${num(r[3]).toFixed(2)} base, x${num(r[4]).toFixed(3)} points`).join("; "));
const wear = get("WEAR") || [];
check(Math.abs(num(wear[1]) - 6.6) < 1e-9 && num(wear[2]) === 6600 && num(wear[3]) === 1 && wear[4] === "x6.6",
  `the server's skin path spends it: Harvest of Souls wears as x${wear[1]} (a 1000 hit becomes ${wear[2]}), its card says ${wear[4]}; a normal skin's edge is ${wear[3]}`);

// 3. MineHalloweenPets
const mod = get("MODULE") || [];
check(mod[1] === "true", "MineHalloweenPets loads" + (mod[1] === "true" ? "" : ": " + (mod[2] || "missing")));
const pool = get("POOL") || [];
check(num(pool[1]) === 75 && num(pool[2]) === 75 && num(pool[3]) === 75 && num(pool[4]) === 75 && num(pool[5]) === 75 && !/!/.test(pool[6] || "!"),
  `pool() is the pack's 72 plus the 3 older Halloween pets, as the roster's own rows, every one Halloween 2026; pool(rarity) filters (${pool[6]})`);
check(pool[7] === "true" && pool[8] === "true", "pool() hands out a fresh list each call, and includes the older Spindle, Spooky and Wisp (owner, 2026-10-19: \"Yes\")");
const nw = get("NEW") || [];
check(nw[1] === "0", "the 12 new pets are in the pool" + (nw[1] === "0" ? "" : ": missing " + nw[2]));
const is = get("IS") || [];
check(is[1] === "0" && is[2] === "0", "isHalloween is true for every pool pet from any source (pack, Crypt, case, wheel, a name, a stack key); card() stacks on halloween_2026:<name>");
check(is[3] === "true" && is[4] === "false" && is[5] === "false" && is[6] === "false" && is[7] === "false" && is[8] === "false",
  "isHalloween: the older Spindle yes; a normal pet, nil, an empty card, an unnamed print and a pass pet no");
const bo = get("BUILDOF") || [];
check(bo[1] === "Crater" && bo[2] === "Hex Storm" && bo[3] === "nil" && bo[4] === "nil", `buildOf: Boomjaw ${bo[1]}, Hexbolt ${bo[2]}, Webster ${bo[3]}, Segfault ${bo[4]}`);

// 4. the twelve build today
const fac = get("FACTORY") || [];
check(fac[1] === "true", "PetModelFactory loads with its PetBodies" + (fac[1] === "true" ? "" : ": " + fac[2]));
const looks = all("LOOK");
const planned = looks.filter((r) => r[6] === "planned");
check(looks.length === 12 && looks.every((r) => r[2] === r[3] && r[4] === r[3] && r[5] === "Halloween"),
  `all 12 build today on a Halloween body: ${looks.length - planned.length} on their own, ${planned.length} on their fallback until theirs is built (e.g. ${looks[0] ? looks[0][1] + " wears " + looks[0][2] : "none"}); none falls to the default fox`);
const id = get("IDENTITY") || [];
check(id[1] === "0" && num(id[2]) >= 4, `their family and trait come from name and home, the same from any source and on the pay path (${id[2]} families among the 12)`);

// 5. the builds
const rp = get("RADIUSPETS") || [];
check(num(rp[1]) >= 2 && num(rp[1]) <= 30 && rp[2] === "0", `only Halloween pets carry Blast Radius: ${rp[1]} (PROPOSAL §0 line 6: at most 30 pets), ${rp[2]} others`);
for (const r of all("CHANCE")) {
  const mine = num(r[3]), theirs = num(r[4]);
  const whose = /s$/.test(r[1]) ? r[1] + "'" : r[1] + "'s";
  check(r[5] === "1" && mine >= 1.2 * theirs && mine <= 0.6,
    `${whose} ${r[2]} ${(mine * 100).toFixed(1)}% beats the best normal pet's ${(theirs * 100).toFixed(1)}% by ${(mine / theirs).toFixed(2)}x (at least 1.2x, at most 60%), one ability family`);
}
check(all("CHANCE").length === 4, "four proc builds measured (Hex Storm, Bog Tide, Gravequake, Rattlebones' Shatter)");
const cr = get("CRATER") || [];
check(num(cr[1]) > 0.3 && num(cr[2]) > 0 && num(cr[3]) > 0.3,
  `Crater: Boomjaw pays +${(num(cr[1]) * 100).toFixed(1)}% Blast Radius and ${(num(cr[2]) * 100).toFixed(1)}% Blast Chance at Normal, Sparkplug +${(num(cr[3]) * 100).toFixed(1)}%`);
check(num(cr[4]) > 0 && num(cr[5]) === 0, `a legacy print's Blast Radius still pays nothing (${cr[4]} prints carry one): the exemption is the named kit's only`);
const gate = get("GATE") || [];
check(num(gate[1]) > 0.6 && gate[2] === "blast" && num(gate[3]) === 0 && gate[4] === "zap",
  `the gate keeps the pair's +${(num(gate[1]) * 100).toFixed(0)}% on a bomb (no Special: Blast is the live proc) and zeroes it on a Zap tool`);
const pat = get("PATTERN") || [];
check(num(pat[1]) === 33 && num(pat[2]) === 123 && num(pat[3]) === num(pat[4]) && num(pat[5]) === 6,
  `a radius-2 bomb: ${pat[1]} cells plain, ${pat[2]} with the Crater pair (radius 3), ${pat[3]} at most (MAX_BLAST_RADIUS ${pat[5]})`);

// Static: the wiring the harness cannot see.
const factory = code(read("src/ReplicatedStorage/Mine/Shared/PetModelFactory.luau"));
check(/skin\.fallback and S\[skin\.species\] == nil and S\[skin\.fallback\]/.test(factory),
  "PetModelFactory dresses a set or holiday skin whose body is not built in its fallback");
const cards = code(read("src/ReplicatedStorage/Mine/Shared/MineCards.luau"));
check(/addStat\(b, stat, amount \* pow, true\)/.test(cards) && /Stats\.NAMED_PET_OK\[key\]/.test(cards),
  "MineCards pays MineStats.NAMED_PET_OK stats on the named-kit path only");
const brief = path.join(ROOT, "tools/cursor/tasks/halloween-pet-bodies.md");
const briefText = fs.existsSync(brief) ? read("tools/cursor/tasks/halloween-pet-bodies.md") : "";
check(briefText.length > 0 && EXTRAS.length === 12 && EXTRAS.every((e) => briefText.includes("`" + e.body + "`") && briefText.includes(e.label) && briefText.includes(e.name)),
  "the Cursor brief for the new bodies exists and names all 12 bodies, their labels and their pets");

console.log(fail === 0 ? ">>> halloween-power OK" : `>>> ${fail} FAILED`);
process.exit(fail === 0 ? 0 : 1);
