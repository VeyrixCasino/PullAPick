// EVERY ENCHANT, END TO END (owner, 2026-10-19: "make sure all enchants works").
//
// For each of the 26 enchants -- the 22 the main game had and the four
// Halloween ones -- this follows the whole chain and prints one row:
//
//   BOOK    where its book comes from: the main game's rolls (chests, lucky
//           blocks, the Forge's gem bundle, level gifts) for the 22, and ONLY
//           Candy Crypt chests for the Halloween four (MineEnchants)
//   EQUIP   the real MineEnchantService takes the book onto a tool of a family
//           it fits, at level V, and uses the book up
//   EFFECT  what the server then does, run for real: Layer 1 stats through
//           EnchSvc.layerStats and the boosts, the in-swing damage, the speed
//           streaks, the ore rolls, the reveal, and every ability through
//           MineServer's own Dig.procsAt and quake tick (sliced out of the
//           script by _enchant-sim.js) on a voxel world
//   CRYPT   inside the Candy Crypt a normal enchant does nothing and a
//           Halloween one still works (MineEnchants.activeHere; owner: in the
//           Crypt "normal enchants don't work")
//   CLIENT  what the player is shown: the Forge's line at every level, the
//           floating words, every ability word has an animation and sound
//           (MineProcFx), the speed event, the Flashlight glow
//
// Statically it also pins the swing the sim mirrors to swingBlock's text, so
// the two cannot drift, and checks the server reads every stat a Layer 1
// enchant writes.
//
//   node tools/verify/enchant-audit.js
"use strict";
const fs = require("fs");
const path = require("path");
const Luau = require("./_luau");
const Sim = require("./_enchant-sim");

const ROOT = path.resolve(__dirname, "../..");
const read = (p) => Luau.readSrc(path.join(ROOT, p));
const code = (s) => s.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/--[^\n]*/g, "");
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

if (!Luau.ready) { console.log(Luau.missing("luau") + "; skipping"); process.exit(1); }

// ------------------------------------------------------------ the luau half --
const test = `
local plr = { UserId = 1, Name = "audit" }
WORLD.players[1] = plr
local FAMS = { "pickaxe", "hammer", "drill", "jackhammer", "explosive" }
local function out(...) print(table.concat({ ... }, " ")) end

local function newProfile(fam, zoneId, tier)
	local p = { level = 200, xp = 0, zoneId = zoneId or "meadow", maxUnlockedZone = 10, gems = 0,
		enchantBooks = {}, oreToolEquipped = "t1",
		oreTools = { { uid = "t1", familyId = fam or "pickaxe", tier = tier or 20, level = 10, enchants = {} } } }
	profiles[1] = p
	return p
end
local function famFor(def)
	for _, f in ipairs(FAMS) do
		if E.compatible(def, f) then return f end
	end
	return nil
end
-- The real verb: the book in the bag, enchApply, and what landed on the tool.
local function equip(p, id, level)
	local def = E.get(id)
	p.enchantBooks[E.bookKey(id, level)] = 1
	EnchSvc.dispatch(plr, "enchApply", { uid = "t1", slot = def.slot, id = id, level = level })
	local e = p.oreTools[1].enchants and p.oreTools[1].enchants[def.slot]
	return e ~= nil and e.id == id and e.level == level and p.enchantBooks[E.bookKey(id, level)] == nil
end
-- The held tool's row, as Dig.toolInHand builds it for a forged tool.
local function toolRow(p)
	local held = p.oreTools[1]
	local row = OreTools.frameStats(held.familyId, held.tier)
	row.power = OreTools.hitPower(held, 1)
	row.family = held.familyId
	row.oreTier = held.tier
	row.oreId = C.ORES[held.tier] and C.ORES[held.tier].id
	return row
end
local function count(action, text)
	local n = 0
	for _, e in ipairs(SIM.events) do
		if e.action == action and (text == nil or (type(e.payload) == "table" and e.payload.text == text)) then n += 1 end
	end
	return n
end
local function field(zoneId, w, d, hp, from)
	WORLD.reset()
	for x = 1, w do for y = from or 1, (from or 1) + d - 1 do for z = 1, w do
		WORLD.block(zoneId, x, y, z, hp)
	end end end
end
local POS = Vector3.new(0, 0, 0)

-- ------------------------------------------------------------ BOOKS --
local rng = Random.new(11)
local mainN, hallowN, oddsIds, bundleIds = {}, {}, {}, {}
for _ = 1, 200000 do
	local id = E.rollBookId(rng)
	mainN[id] = (mainN[id] or 0) + 1
end
for _, rank in ipairs({ 1, 4, 8 }) do
	for _ = 1, 100000 do
		local id = E.rollHalloweenBook(rank, rng)
		if id then hallowN[id] = (hallowN[id] or 0) + 1 end
	end
end
for _ = 1, 20000 do
	for _, bk in ipairs(E.rollBundle(3, rng)) do bundleIds[bk.id] = true end
	local cb = E.rollChestBundle("S", rng, 3)
	for _, bk in ipairs(cb or {}) do bundleIds[bk.id] = true end
end
for _, o in ipairs(E.bookOdds()) do oddsIds[o.id] = true end
local hRates = {}
for _, rank in ipairs({ 1, 8 }) do
	local o = E.halloweenBookOdds(rank)
	local spell
	for _, b in ipairs(o.books) do if b.id == "spellbook" then spell = b.p end end
	table.insert(hRates, string.format("%.3f:%.3f", o.chance, spell or -1))
end
out("HBOOKS", table.concat(hRates, " "))
local hl = {}
for _, id in ipairs(E.HALLOWEEN) do table.insert(hl, id) end
out("HALLOWEEN", table.concat(hl, ","))

local function bookRow(def)
	local roundTrip = true
	for lvl = 1, 5 do
		local id, l = E.parseBookKey(E.bookKey(def.id, lvl))
		if id ~= def.id or l ~= lvl then roundTrip = false end
	end
	if def.event == "halloween" then
		return roundTrip and not oddsIds[def.id] and (mainN[def.id] or 0) == 0 and not bundleIds[def.id]
			and (hallowN[def.id] or 0) > 0, "Crypt chests " .. (hallowN[def.id] or 0) .. "/300k"
	end
	return roundTrip and oddsIds[def.id] == true and (mainN[def.id] or 0) > 0 and bundleIds[def.id] == true
		and (hallowN[def.id] or 0) == 0, "main game " .. (mainN[def.id] or 0) .. "/200k"
end

-- ------------------------------------------------------------ EFFECTS --
local LAYER_KINDS = { mult = true, add = true, multi = true }
local function near(a, b, tol) return math.abs(a - b) <= tol end

local function layerEffect(def, fam)
	local p = newProfile(fam)
	equip(p, def.id, 5)
	local stats = EnchSvc.layerStats(p)
	local want = E.statsAt(def, 5)
	local ok = #stats == #want and #want > 0
	local b = SIM.boosts(p)
	local base = SIM.boosts(newProfile(fam))
	local parts = {}
	for i, w in ipairs(want) do
		ok = ok and stats[i] and stats[i].stat == w.stat and near(stats[i].value, w.value, 1e-9)
		local key = (w.stat == "swingRate") and "swingSec" or w.stat
		local moved = (b[key] or 0) - (base[key] or 0)
		ok = ok and math.abs(moved) > 1e-6
		table.insert(parts, string.format("%s %+.3f", key, moved))
	end
	return ok, table.concat(parts, ", ")
end

local function hitEffect(def, fam)
	local p = newProfile(fam)
	equip(p, def.id, 5)
	if def.id == "crit" then
		local part = WORLD.block("meadow", 1, 1, 1, 1e12)
		local total = 0
		for _ = 1, 6000 do total += EnchSvc.hitDamage(plr, p, part, 100, 1e12) end
		local mean = total / 6000 / 100
		return near(mean, 1.3, 0.04) and count("loot", "CRIT!") > 0, string.format("x%.3f on average (20%% for x2.5)", mean)
	elseif def.id == "executioner" then
		local a = WORLD.block("meadow", 1, 1, 1, 1000, { HP = 150 })
		local b = WORLD.block("meadow", 2, 1, 1, 1000, { HP = 250 })
		local x, y = EnchSvc.hitDamage(plr, p, a, 100, 1000), EnchSvc.hitDamage(plr, p, b, 100, 1000)
		return x == 200 and y == 100, "x2 within 2 hits of breaking (" .. x .. "), x1 before (" .. y .. ")"
	elseif def.id == "demolition" then
		local a = WORLD.block("meadow", 1, 1, 1, 800)
		local b = WORLD.block("meadow", 2, 1, 1, 700)
		local x, y = EnchSvc.hitDamage(plr, p, a, 100, 800), EnchSvc.hitDamage(plr, p, b, 100, 700)
		return x == 140 and y == 100, "x1.4 on a block of 8+ hits (" .. x .. "), x1 below (" .. y .. ")"
	elseif def.id == "combo" then
		local part = WORLD.block("meadow", 1, 1, 1, 1e12)
		local first = EnchSvc.hitDamage(plr, p, part, 100, 1e12)
		local last
		for _ = 1, 120 do last = EnchSvc.hitDamage(plr, p, part, 100, 1e12) end
		SIM.t += 3
		local after = EnchSvc.hitDamage(plr, p, part, 100, 1e12)
		return first == 100 and last == 300 and after == 100, "first " .. first .. ", capped " .. last .. ", after a pause " .. after
	elseif def.id == "grave_digger" then
		local deep = WORLD.block("meadow", 1, 5000, 1, 1e12)
		local mid = WORLD.block("meadow", 1, 2500, 1, 1e12)
		local top = WORLD.block("meadow", 1, 1, 1, 1e12)
		local d, m, t = 0, 0, 0
		for _ = 1, 400 do
			d += EnchSvc.hitDamage(plr, p, deep, 1000, 1e12)
			m += EnchSvc.hitDamage(plr, p, mid, 1000, 1e12)
			t += EnchSvc.hitDamage(plr, p, top, 1000, 1e12)
		end
		d, m, t = d / 400000, m / 400000, t / 400000
		return near(d, 1.6, 0.002) and near(m, 1.396, 0.003) and t < 1.01,
			string.format("x%.3f at the floor, x%.3f halfway, x%.3f at the top", d, m, t)
	end
	return false, "no test"
end

local function speedEffect(def, fam)
	local p = newProfile(fam)
	equip(p, def.id, 5)
	SIM.events = {}
	local per = (def.id == "sugar_rush") and 9 or 1
	local swings = (def.id == "sugar_rush") and 6 or 20
	for _ = 1, swings do
		EnchSvc.afterSwing(plr, p, true, POS, per)
		SIM.t += 0.2
	end
	local top = EnchSvc.swingSpeed(p)
	EnchSvc.afterSwing(plr, p, false, POS, 1)
	local reset = EnchSvc.swingSpeed(p)
	EnchSvc.afterSwing(plr, p, true, POS, per)
	SIM.t += 3
	local lapsed = EnchSvc.swingSpeed(p)
	local told = count("enchSpeed")
	local words = (def.id == "sugar_rush") and count("loot", "SUGAR RUSH +100%") or count("loot", "OVERCLOCK x20")
	return near(top, 2, 1e-9) and reset == 1 and lapsed == 1 and told > 0 and words > 0,
		string.format("x%.2f at the cap after %d one-shot swings (%d blocks each), x%.0f after a miss or a pause", top, swings, per, reset)
end

local function oreEffect(def, fam)
	local p = newProfile(fam)
	equip(p, def.id, 5)
	if def.id == "veinminer" then
		return EnchSvc.veinCount(p) == 10, "takes " .. EnchSvc.veinCount(p) .. " more vein blocks"
	end
	local ore = C.ORES[10]
	local n, N = 0, 30000
	for _ = 1, N do
		if def.id == "alchemy" then
			if EnchSvc.alchemy(plr, p, ore, POS) ~= ore then n += 1 end
		elseif EnchSvc.duplicate(plr, p, 5, POS) == 10 then
			n += 1
		end
	end
	local want = (def.id == "alchemy") and 0.10 or 0.20
	return near(n / N, want, 0.012), string.format("%.1f%% of ore drops", 100 * n / N)
end

local function xpEffect(def, fam)
	local p = newProfile(fam)
	p.level = 150
	local before = p.xp
	EnchSvc.gainXp(plr, p, 100)
	local plain = p.xp - before
	equip(p, def.id, 5)
	before = p.xp
	EnchSvc.gainXp(plr, p, 100)
	local boosted = p.xp - before
	return plain == 100 and boosted == 161, "100 XP pays " .. boosted
end

-- Flashlight on a field with ores of known tiers around the broken block.
local function revealEffect(def, fam, zoneId)
	local p = newProfile(fam, zoneId or "meadow", 20)
	equip(p, def.id, 5)
	local zid = zoneId or "meadow"
	field(zid, 21, 21, 100)
	local function ore(x, y, z, tier)
		local b = WORLD.cells[zid][keyOf(zid, x, y, z)]
		b.attrs.Kind = "ore"
		b.attrs.OreTier = tier
		b.attrs.OreId = C.ORES[tier].id
		b.attrs.OreName = C.ORES[tier].name
		return b
	end
	ore(11, 13, 11, 5)           -- 2 away, common
	local want = ore(17, 11, 11, 30) -- 6 away: the rarest the tier-20 tool can break
	ore(11, 11, 18, 60)          -- 7 away, too hard for a tier-20 tool
	ore(1, 11, 11, 70)           -- 10 away, out of reach of the beam
	local centre = WORLD.cells[zid][keyOf(zid, 11, 11, 11)]
	-- The zone row finishBreak passes (the Crypt's has no strength gate).
	local zone = C.zoneById(zid)
	local cells, row = WORLD.cells[zid], toolRow(p)
	SIM.events = {}
	local lit, tries = nil, 0
	while not lit and tries < 2000 do
		tries += 1
		lit = EnchSvc.flashlight(plr, p, zone, centre, cells, keyOf, row)
		SIM.t += 0.05
	end
	local again = EnchSvc.flashlight(plr, p, zone, centre, cells, keyOf, row)
	local evt
	for _, e in ipairs(SIM.events) do if e.action == "flashlight" then evt = e.payload end end
	local f = E.flashlightAt(5)
	if zone.noStrengthGate then
		-- No breaking gate here (the Crypt): the rarest in reach, the tier 60.
		want = WORLD.cells[zid][keyOf(zid, 11, 11, 18)]
	end
	local ok = lit == want and again == nil and evt ~= nil and evt.part == want and evt.secs == f.glow
		and evt.name == want.attrs.OreName and typeof(evt.pos) ~= nil
	return ok, string.format("lit %s (tier %s) after %d breaks, then rests %ds", tostring(evt and evt.name),
		tostring(lit and lit.attrs.OreTier), tries, f.cooldown)
end

-- An ability, through MineServer's own Dig.procsAt: n swings at a field.
local WORDS = { zap = "ZAP", blast = "BLAST", tide = "TIDAL WAVE", shatter = "SHATTER", quake = "QUAKE" }
local function swingField(p, b, hp, swings)
	field(p.zoneId, 21, 12, hp)
	local zone = { id = p.zoneId }
	local tool = toolRow(p)
	tool.power = 1000
	SIM.events = {}
	SIM.stats = { hits = 0, dmg = 0, broken = 0 }
	local own = 0
	local targets = {}
	for y = 1, 12 do for x = 2, 20 do for z = 2, 20 do table.insert(targets, { x, y, z }) end end end
	local i = 0
	for _ = 1, swings do
		local part
		repeat
			i += 1
			local t = targets[i]
			part = t and WORLD.cells[p.zoneId][keyOf(p.zoneId, t[1], t[2], t[3])]
		until part or i >= #targets
		if not part then break end
		own += 1
		SIM.swing(plr, p, b, tool, zone, part)
		SIM.advance(0.4)
	end
	SIM.advance(6)
	return SIM.stats.hits - own
end

local function procEffect(def, fam)
	local p = newProfile(fam)
	equip(p, def.id, 5)
	local b = SIM.boosts(p)
	local e = def.effect
	if e.family == "spell" then
		local zeroed = true
		for _, proc in pairs(E.PROCS) do if (b[proc.chance] or 0) ~= 0 then zeroed = false end end
		-- Blocks that take two hits: on a one-shot field the book never draws
		-- Earthquake (the block it would shake is gone), by design.
		local extra = swingField(p, b, 1500, 400)
		local casts = count("loot", "SPELL")
		local seen, kinds = {}, 0
		for fam2, word in pairs(WORDS) do
			if count("loot", word) + ((fam2 == "blast") and (count("loot", "DETONATION") + count("loot", "BURST")) or 0) > 0 then
				seen[fam2] = true
				kinds += 1
			end
		end
		return zeroed and b.spellEvery == 4 and E.liveFamily(b) == "spell" and casts == 100 and kinds == 5 and extra > 0,
			string.format("%d casts in 400 swings (every %d), all %d abilities, %d extra hits", casts, b.spellEvery, kinds, extra)
	end
	local chance = b[E.PROCS[e.family].chance]
	local others = 0
	for key, proc in pairs(E.PROCS) do
		if key ~= e.family and (b[proc.chance] or 0) ~= 0 then others += 1 end
	end
	-- Break-only abilities on blocks a swing one-shots; Earthquake (on a hit
	-- that does not break) and Zap (any swing) on blocks that take many hits.
	local hp = (e.family == "quake" or e.family == "zap") and 1e7 or 500
	local extra = swingField(p, b, hp, 400)
	local words = count("loot", WORDS[e.family])
	if e.family == "blast" then words = count("loot", "DETONATION") end
	local rate = words / 400
	local ok = others == 0 and b.procTier == 3 and near(rate, chance, 0.07) and extra > 0
	-- A zap word is a hop; a quake word is a block starting to shake (tier 3
	-- shakes up to four more), so both run above the chance.
	if e.family == "zap" or e.family == "quake" then
		ok = others == 0 and b.procTier == 3 and extra > 0 and rate >= chance * 0.7
	end
	return ok, string.format("%.0f%% chance, %d words in 400 swings, %d extra hits at tier %d",
		100 * chance, words, extra, b.procTier)
end

local function effectRow(def, fam)
	local k = def.effect.kind
	if LAYER_KINDS[k] then return layerEffect(def, fam) end
	if k == "hit" and def.id == "overclock" then return speedEffect(def, fam) end
	if k == "hit" or k == "depth" then return hitEffect(def, fam) end
	if k == "rush" then return speedEffect(def, fam) end
	if k == "ore" then return oreEffect(def, fam) end
	if k == "xp" then return xpEffect(def, fam) end
	if k == "reveal" then return revealEffect(def, fam) end
	if k == "proc" then return procEffect(def, fam) end
	return false, "unknown kind " .. tostring(k)
end

-- ------------------------------------------------------------ CRYPT --
-- Equipped and standing in the Crypt: does it still do anything?
local function cryptRow(def, fam)
	local p = newProfile(fam, "hallow")
	equip(p, def.id, 5)
	local live = false
	local k = def.effect.kind
	if LAYER_KINDS[k] or k == "xp" then
		live = #EnchSvc.layerStats(p) > 0
		if k == "xp" then
			p.level = 150
			local before = p.xp
			EnchSvc.gainXp(plr, p, 100)
			live = (p.xp - before) ~= 100
		end
	elseif k == "proc" then
		live = EnchSvc.special(p) ~= nil
	elseif k == "depth" or k == "hit" then
		if def.id == "overclock" then
			for _ = 1, 20 do EnchSvc.afterSwing(plr, p, true, POS, 1) end
			live = EnchSvc.swingSpeed(p) > 1
		else
			local part = WORLD.block("hallow", 1, 120, 1, 1000, { HP = 150 })
			local total = 0
			for _ = 1, 300 do total += EnchSvc.hitDamage(plr, p, part, 100, 1000) end
			live = total ~= 30000
		end
	elseif k == "rush" then
		for _ = 1, 6 do EnchSvc.afterSwing(plr, p, true, POS, 9) end
		live = EnchSvc.swingSpeed(p) > 1
	elseif k == "ore" then
		live = (def.id == "veinminer" and EnchSvc.veinCount(p) > 0)
		for _ = 1, 400 do
			if def.id == "alchemy" and EnchSvc.alchemy(plr, p, C.ORES[10], POS) ~= C.ORES[10] then live = true end
			if def.id == "duplicator" and EnchSvc.duplicate(plr, p, 5, POS) ~= 5 then live = true end
		end
	elseif k == "reveal" then
		live = (revealEffect(def, fam, "hallow"))
	end
	local want = def.event == "halloween"
	return live == want and E.activeHere("hallow", def.id) == want and E.activeHere("meadow", def.id) == true,
		want and "works in the Crypt" or "off in the Crypt"
end

-- ------------------------------------------------------------ CLIENT --
local function clientRow(def)
	for lvl = 1, 5 do
		local d = E.describe(def, lvl)
		if type(d) ~= "string" or #d < 2 or not string.find(d, "%d") then
			return false, "level " .. lvl .. " has no line"
		end
	end
	return true, E.describe(def, 5)
end

-- Tidal Wave's tiers roll the wave DOWN (+cy is deeper): one certain wave at
-- tier 3 from the top of a fresh field hits 12 cells on each of 3 layers.
do
	local p = newProfile("pickaxe")
	equip(p, "tide", 5)
	local b = SIM.boosts(p)
	b.tidalWave = 1
	field("meadow", 9, 6, 500)
	SIM.stats = { hits = 0, dmg = 0, broken = 0 }
	local part = WORLD.cells.meadow[keyOf("meadow", 5, 1, 5)]
	local tool = toolRow(p)
	tool.power = 1000
	local layers = {}
	SIM.onHit = function(blk) layers[blk.attrs.CY] = (layers[blk.attrs.CY] or 0) + 1 end
	SIM.swing(plr, p, b, tool, { id = "meadow" }, part)
	SIM.onHit = nil
	out("TIDEDOWN", SIM.stats.hits - 1, layers[1] or 0, layers[2] or 0, layers[3] or 0)
end

-- ------------------------------------------------------------ the rows --
for _, def in ipairs(E.LIST) do
	local fam = famFor(def)
	local okB, dB = bookRow(def)
	local p = newProfile(fam)
	local okE = fam ~= nil and equip(p, def.id, 5)
	-- An incompatible tool refuses it (a Special on a charge; an in-swing one on a charge).
	local refused = true
	if def.slot == "special" or def.families then
		local bad
		for _, f in ipairs(FAMS) do if not E.compatible(def, f) then bad = f break end end
		if bad then
			local q = newProfile(bad)
			refused = not equip(q, def.id, 5)
		end
	end
	local okF, dF = effectRow(def, fam)
	local okC, dC = cryptRow(def, fam)
	local okU, dU = clientRow(def)
	out("ROW", def.id, okB and "ok" or "FAIL", (okE and refused) and "ok" or "FAIL", okF and "ok" or "FAIL",
		okC and "ok" or "FAIL", okU and "ok" or "FAIL", "|", def.name, "|", def.slot, "|", tostring(fam), "|", dB, "|", dF, "|", dC, "|", dU)
end
`;

let outText = "";
try {
  outText = Sim.run(Sim.prelude(ROOT) + Sim.world(ROOT) + test, "enchant-audit");
} catch (e) {
  console.log(e.message);
  check(false, "the audit ran");
}
const lines = outText.split("\n");
const get = (tag) => (lines.find((l) => l.startsWith(tag + " ")) || "").slice(tag.length + 1).trim();
const rows = lines.filter((l) => l.startsWith("ROW ")).map((l) => {
  const [head, name, slot, fam, book, effect, crypt, client] = l.slice(4).split(" | ");
  const [id, b, e, f, c, u] = head.split(" ");
  return { id, b, e, f, c, u, name, slot, fam, book, effect, crypt, client };
});

// The status table: one row an enchant.
console.log("");
console.log("  enchant           slot     tool        book  equip effect crypt client   what the server did at level V");
for (const r of rows) {
  console.log(`  ${r.name.padEnd(17)} ${r.slot.padEnd(8)} ${r.fam.padEnd(11)} ${r.b.padEnd(5)} ${r.e.padEnd(5)} ${r.f.padEnd(6)} ${r.c.padEnd(5)} ${r.u.padEnd(6)}   ${r.effect}`);
}
console.log("");

check(rows.length === 26, `all 26 enchants audited (${rows.length})`);
for (const r of rows) {
  const all = [r.b, r.e, r.f, r.c, r.u].every((x) => x === "ok");
  check(all, `${r.name}: book (${r.book}), equip, effect (${r.effect}), ${r.crypt}, client`);
}
check(get("HALLOWEEN") === "sugar_rush,grave_digger,spellbook,flashlight", "MineEnchants.HALLOWEEN lists the four ids the Crypt calls");
check(get("TIDEDOWN") === "36 13 12 12",
  `Tidal Wave V (Tsunami) rolls DOWN 3 layers, 12 cells each (hits, then by layer: ${get("TIDEDOWN")}); it rolled up into dug space before`);
const hb = get("HBOOKS").split(" ").map((x) => x.split(":").map(Number));
check(hb.length === 2 && hb[1][0] > hb[0][0] && hb[1][1] > hb[0][1],
  `a better Crypt chest drops a Halloween book more often and leans rarer (F ${hb[0] && hb[0][0]} / Spellbook ${hb[0] && hb[0][1]}, SSS ${hb[1] && hb[1][0]} / ${hb[1] && hb[1][1]})`);

// ------------------------------------------------------------ static half --
const server = read(Sim.SV + "/MineServer.server.luau");
const swing = code(Sim.swingBlockText(ROOT));
const order = [
  "dmg = Dig.EnchSvc.hitDamage(plr, p, part, dmg, maxHp)",
  "Patterns.resolve(useTool, cx, cy, cz, aim, b)",
  "local whole = (tonumber(other:GetAttribute(\"HP\")) or math.huge) >= (tonumber(other:GetAttribute(\"MaxHP\")) or 0)",
  "if broke and whole then",
  "local wasWhole = (tonumber(part:GetAttribute(\"HP\")) or maxHp) >= maxHp",
  "Dig.EnchSvc.afterSwing(plr, p, centreBroken and wasWhole, aimPos, oneShots + 1)",
  "Dig.procsAt(plr, p, b, zone, cells, part, cx, cy, cz, centreDmg, kind, centreBroken, tool and tool.omniBlast)",
  "local cast = Dig.EnchSvc and Dig.EnchSvc.spellCast(plr, p, b, centreBroken, aimPos)",
  "Dig.procsAt(plr, p, cast.b, zone, cells, part, cx, cy, cz,",
  "math.max(1, math.floor(centreDmg * cast.power + 0.5)), kind, cast.broke, false)",
];
let at = -1, inOrder = true;
for (const s of order) {
  const i = swing.indexOf(s, at + 1);
  if (i < 0) { inOrder = false; console.log("        missing from swingBlock: " + s); break; }
  at = i;
}
check(inOrder, "the swing the sim runs is swingBlock's, step for step: the hit enchant, the cells and their one-shots, the streaks, the ability, then the Spellbook's cast");
const fb = code(Sim.finishBreakText(ROOT));
check(/Dig\.EnchSvc\.flashlight\(plr, p, zone, part, voxels\[zone\.id\], keyOf, Dig\.heldTool and Dig\.heldTool\[p\]\)/.test(fb),
  "every broken block gives the Flashlight its chance (finishBreak)");
// Every stat a Layer 1 enchant writes is read by the server.
const READS = {
  mineSpeed: /\bb\.mineSpeed\b/, swingRate: /\bb\.swingSec\b/, shortFuse: /tonumber\(b\.shortFuse\)/,
  oreHaul: /C\.oreHaulMult\(bb and bb\.oreHaul\)/, coinBonus: /\(b\.coinBonus or 1\)/, gemFind: /\(b\.gemFind or 1\)/,
  chestLuck: /\bb\.chestLuck\b/, reach: /tonumber\(b\.reach\)/,
};
const sv = code(server);
const ench = read(Sim.SH + "/MineEnchants.luau");
const layerStats = [...new Set([...ench.matchAll(/kind = "(?:mult|add)", stat = "(\w+)"/g)].map((m) => m[1]).concat(["mineSpeed", "swingRate"]))];
for (const st of layerStats) {
  check(READS[st] && READS[st].test(sv), `the server reads ${st}, which a Layer 1 enchant writes`);
}
// What the player sees.
const fx = code(read(Sim.SH + "/MineProcFx.luau"));
const byText = (fx.match(/local BY_TEXT = \{[\s\S]*?\n\}/) || [""])[0];
const procs = code((server.match(/function Dig\.procsAt[\s\S]*?\nend\n/) || [""])[0])
  + code((server.match(/function Dig\.startQuake[\s\S]*?\nend\n/) || [""])[0]);
const words = new Set([...procs.matchAll(/"([A-Z][A-Z ]{2,})"/g)].map((m) => m[1]));
for (const w of ["BLAST", "BURST", "DETONATION", "TIDAL WAVE", "SHATTER", "QUAKE", "ZAP"]) {
  check(words.has(w), `the server sends the ability word ${w}`);
}
for (const w of [...words].concat(["SPELL", "FLASHLIGHT"])) {
  const key = /\s/.test(w) ? `["${w}"]` : w;
  check(byText.includes(key + " = M."), `${w} has an animation and a sound (MineProcFx)`);
}
const client = code(read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau"));
check(/action == "flashlight" and type\(payload\) == "table" then\s*\n\s*ClientFns\.procFx\("FLASHLIGHT", payload\.pos, payload\)/.test(client)
  && /function ClientFns\.procFx\(text, pos, extra\)[\s\S]{0,400}procFxMod\.play\(text, pos, extra\)/.test(client),
  "the client lights the Flashlight's block (MineProcFx.flashlight, through the rock, fading)");
check(/action == "enchSpeed"/.test(client) && /swingSec \/ ocMult/.test(client), "the client paces its swing by the speed streaks (Overclock, Sugar Rush)");
check(/action == "loot" and payload then\s*\n\s*floatText\(/.test(client), "every enchant word (CRIT!, COMBO, OVERCLOCK, SUGAR RUSH, SPELL, ALCHEMY!, DOUBLE!) floats over its block");
const flight = (fx.match(/function M\.flashlight[\s\S]*?\nend\n/) || [""])[0];
check(/AlwaysOnTop/.test(flight) && /TextTransparency/.test(flight) && !/TextSize\s*=\s*[^\n]*\*/.test(flight) && !/UIScale/.test(flight),
  "the glow shows through the rock and its label only fades (text never rides a scale animation)");

console.log("");
console.log(fail > 0 ? `>>> enchant-audit: ${fail} FAILED` : ">>> enchant-audit: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
