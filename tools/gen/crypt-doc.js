// THE CANDY CRYPT'S NUMBERS, generated from the code: docs/CANDY-CRYPT.md.
//
// Owner, 2026-10-19 ("Candy Crypt v2"): "the numbers document: block HP per
// section, ore spawn chances, the candy and ore drop amounts with their spread,
// craft and prestige cost per ore: in the repo, generated from the code, and
// as a web page".
//
// This runs the REAL Luau modules (MineConfig, MineCandyTools, MineCryptChests,
// MineTrickOrTreat, MineCryptRules, MineOreTools, MineOrePouch, ...) on the
// Crypt harness (tools/verify/_crypt.js) and writes what they say. Nothing is
// restated in JS: every number in the document is one the game computes. The
// only number of this file's own is the dig pace the per-hour columns assume
// (ASSUME, below), and the document says so.
//
// Another session's hooks are read when they exist: MineEnchants'
// rollHalloweenBook (sampled, seeded, so the book chances are measured, not
// typed) and MineCharms' cryptChestCharm (the charm each chest rank pays). So
// after merging those sessions, regenerate.
//
//   node tools/gen/crypt-doc.js           # write docs/CANDY-CRYPT.md
//   node tools/gen/crypt-doc.js --check   # fail if the committed one is stale
//                                         (tools/verify/crypt-doc.js runs this)
"use strict";
const fs = require("fs");
const path = require("path");
const H = require("../verify/_crypt");

const OUT = path.join(H.ROOT, "docs/CANDY-CRYPT.md");

// The one assumption of this document's own: how fast a player breaks blocks,
// for the per-hour columns. A block every three seconds is a matched tool at
// four to twelve hits a block (MineCandyTools.PICK_HITS at its own layer) and a
// pick's 2.8 swings a second, with walking and chests in between. Not measured:
// nobody has played the Crypt yet.
const ASSUME = { BLOCKS_PER_HOUR: 1200, BOOK_SAMPLES: 20000 };

// ------------------------------------------------------------ the Luau half --
const body = `
local function enc(v)
	local t = type(v)
	if t == "nil" then return "null" end
	if t == "boolean" then return v and "true" or "false" end
	if t == "number" then
		if v ~= v or v == math.huge or v == -math.huge then return "null" end
		if v == math.floor(v) and math.abs(v) < 1e15 then return string.format("%d", v) end
		return string.format("%.17g", v)
	end
	if t == "string" then
		local s = v:gsub('\\\\', '\\\\\\\\'):gsub('"', '\\\\"'):gsub("\\n", "\\\\n")
		return '"' .. s .. '"'
	end
	if t == "table" then
		if #v > 0 or next(v) == nil then
			local out = {}
			for i = 1, #v do out[i] = enc(v[i]) end
			return "[" .. table.concat(out, ",") .. "]"
		end
		local keys = {}
		for k in pairs(v) do table.insert(keys, tostring(k)) end
		table.sort(keys)
		local out = {}
		for _, k in ipairs(keys) do table.insert(out, enc(k) .. ":" .. enc(v[k])) end
		return "{" .. table.concat(out, ",") .. "}"
	end
	return "null"
end

local C = require("MineConfig")
local Tools = require("MineCandyTools")
local Chests = require("MineCryptChests")
local TT = require("MineTrickOrTreat")
local R = require("MineCryptRules")
local OreTools = require("MineOreTools")
local Pouch = require("MineOrePouch")
local Charms = require("MineCharms")
local E = require("MineEnchants")

local out = { assume = { blocksPerHour = ${ASSUME.BLOCKS_PER_HOUR} } }
local SECTIONS = C.CANDY_ECONOMY.SECTIONS
local SPAN = C.CANDY_SECTION_SPAN
out.sections = SECTIONS
out.span = SPAN
out.economy = C.CANDY_ECONOMY
out.chestChance = C.CHEST_CHANCE * (C.zoneById("hallow").chestMult or 1)
out.resetSec = C.MINE_RESET_SEC

-- 1. Block HP per section (and the next section below the bottom, where the
-- rock keeps hardening).
out.hp = {}
for s = 1, SECTIONS + 1 do
	local a, b = (s - 1) * SPAN + 1, s * SPAN
	table.insert(out.hp, { section = s, first = a, last = b, hpFirst = C.cryptRockHp(a), hpLast = C.cryptRockHp(b),
		coinsFirst = C.cryptSellHp(a), coinsLast = C.cryptSellHp(b) })
end

-- 2. The ores.
out.ores = {}
for _, o in ipairs(C.CANDY_ORES) do
	local t = Tools.forOre(o.id)
	table.insert(out.ores, { rank = o.rank, id = o.id, name = o.name, band = o.band, drop = o.drop, value = o.value,
		candy = o.candy, tool = t and t.name or nil })
end

-- 3/4. Odds and the per-block mix, per section.
out.odds, out.rarity, out.mix = {}, {}, {}
for s = 1, SECTIONS do
	local layer = (s - 1) * SPAN + 1
	local odds = C.candyOreOdds(layer)
	out.odds[s] = odds
	out.rarity[s] = C.candyRarityOdds(s)
	local m = { candy = 0, candy2 = 0, units = 0, units2 = 0, value = 0, value2 = 0 }
	for i, o in ipairs(C.CANDY_ORES) do
		local p = odds[i]
		local v = o.drop * o.value
		m.candy += p * o.candy
		m.candy2 += p * o.candy * o.candy
		m.units += p * o.drop
		m.units2 += p * o.drop * o.drop
		m.value += p * v
		m.value2 += p * v * v
	end
	m.candySd = math.sqrt(math.max(0, m.candy2 - m.candy * m.candy))
	m.unitsSd = math.sqrt(math.max(0, m.units2 - m.units * m.units))
	m.valueSd = math.sqrt(math.max(0, m.value2 - m.value * m.value))
	-- Chest candy per block at this section (chest chance x the rank mix).
	local ro = Chests.rankOdds(s)
	local chestCandy = 0
	for i, r in ipairs(Chests.RANKS) do chestCandy += ro[i] * r.candy end
	m.chestCandy = chestCandy
	-- The FIRST design's normal ores here, for the gem comparison: ORE_CHANCE a
	-- block (veins spend the same budget), less the share candy covered (15%),
	-- at the Crypt's old ore mix (oreWeights reads oreDifficulty's low curve),
	-- each selling for its gem value x its mid yield.
	local row = C.oreWeights("hallow", layer, 1)
	local gemsPerOreBlock = 0
	if row and row.tot and row.tot > 0 then
		for i, ore in ipairs(C.ORES) do
			local w = (row.w[i] or 0) / row.tot
			if w > 0 then
				local lo, hi = C.oreYieldFor(ore.tier)
				gemsPerOreBlock += w * Pouch.gemValue(ore) * ((lo + hi) / 2)
			end
		end
	end
	m.v1GemsPerBlock = (C.ORE_CHANCE or 0) * 0.85 * gemsPerOreBlock
	out.mix[s] = m
end

-- 5. Chests.
out.chests = {}
for _, r in ipairs(Chests.RANKS) do
	local row = { key = r.key, name = r.name, packs = r.packs, luck = r.luck, candy = r.candy, look = r.look }
	if type(Charms.cryptChestCharm) == "function" then
		local ok, id = pcall(Charms.cryptChestCharm, r.key)
		if ok and type(id) == "table" then id = id.id end
		local def = ok and Charms.byId(id) or nil
		row.charm = def and def.name or (ok and id) or nil
	end
	if type(E.rollHalloweenBook) == "function" then
		local rng = Random.new(1000 + r.index)
		local hits = 0
		for _ = 1, ${ASSUME.BOOK_SAMPLES} do
			local ok, res = pcall(E.rollHalloweenBook, r.index, rng)
			if ok and res ~= nil then hits += 1 end
		end
		row.bookChance = hits / ${ASSUME.BOOK_SAMPLES}
	end
	table.insert(out.chests, row)
end
out.chestOdds = {}
for s = 1, SECTIONS do out.chestOdds[s] = Chests.rankOdds(s) end
out.charmChance = Chests.CHARM_CHANCE
out.charmHook = type(Charms.cryptChestCharm) == "function"
out.bookHook = type(E.rollHalloweenBook) == "function"

-- 6. Trick-or-Treat.
out.case = R.caseOdds()

-- 7. Tools.
out.tools = {}
out.toolRules = { cap = Tools.CAP, prestigeMax = Tools.PRESTIGE_MAX, pickHits = Tools.PICK_HITS,
	prestigePower = Tools.PRESTIGE_POWER, costBase = Tools.PRESTIGE_COST.BASE, costGrowth = Tools.PRESTIGE_COST.GROWTH,
	scrapShare = Tools.SCRAP_SHARE, craftAfterEvent = Tools.CRAFT_AFTER_EVENT, world = Tools.WORLD,
	maxLevel = C.TOOL_MAX_LEVEL, topOre = C.ORES[#C.ORES].name }
for _, t in ipairs(Tools.TOOLS) do
	local row = { rank = t.rank, id = t.id, name = t.name, family = t.family, ore = t.oreName, band = t.band,
		craft = t.craft, skinFactor = t.skinFactor, tuneLayer = t.tuneLayer, costs = {}, crypt = {}, world = {}, worldEq = {}, scrap = {} }
	for k = 1, Tools.PRESTIGE_MAX do row.costs[k] = Tools.prestigeCost(t, k) end
	for k = 0, Tools.PRESTIGE_MAX do
		row.crypt[k + 1] = Tools.cryptPower(t, k, 0)
		row.world[k + 1] = Tools.worldPower(t, k, 0)
		local tier, level, ore = Tools.worldEquivalent(t, k)
		row.worldEq[k + 1] = { tier = tier, level = level, ore = ore and ore.name or "?" }
		row.scrap[k + 1] = Tools.scrapCandy(t, k)
	end
	row.total = Tools.totalSpent(t, Tools.PRESTIGE_MAX)
	row.bestNormal = OreTools.hitPower({ familyId = t.family, tier = #C.ORES, level = C.TOOL_MAX_LEVEL }, 1)
	table.insert(out.tools, row)
end

print("JSON " .. enc(out))
`;

function gather() {
  if (!H.Luau.ready) {
    throw new Error(H.Luau.missing("luau"));
  }
  const raw = H.run("crypt-doc", H.source(body, {}));
  const line = raw.split("\n").find((l) => l.startsWith("JSON "));
  if (!line) throw new Error("the Luau half printed no JSON line:\n" + raw.slice(0, 2000));
  return JSON.parse(line.slice(5));
}

// ------------------------------------------------------------ formatting --
const commas = (n) => {
  if (n === null || n === undefined) return "-";
  const r = Math.round(n);
  return r.toLocaleString("en-US");
};
// Big numbers in the game's own short form, for the damage tables.
const short = (n) => {
  if (n === null || n === undefined) return "-";
  const a = Math.abs(n);
  const units = [[1e12, "T"], [1e9, "B"], [1e6, "M"], [1e3, "K"]];
  for (const [v, s] of units) {
    if (a >= v) {
      const x = n / v;
      return (x >= 100 ? x.toFixed(0) : x >= 10 ? x.toFixed(1) : x.toFixed(2)) + s;
    }
  }
  return String(Math.round(n));
};
const pct = (p, digits) => {
  const v = p * 100;
  if (v === 0) return "0%";
  if (digits !== undefined) return v.toFixed(digits) + "%";
  if (v >= 10) return v.toFixed(1) + "%";
  if (v >= 1) return v.toFixed(2) + "%";
  if (v >= 0.01) return v.toFixed(3) + "%";
  return v.toFixed(4) + "%";
};
const fix = (n, d) => (n === null || n === undefined ? "-" : Number(n).toFixed(d));
const table = (head, rows) => {
  const out = ["| " + head.join(" | ") + " |", "|" + head.map(() => "---").join("|") + "|"];
  for (const r of rows) out.push("| " + r.join(" | ") + " |");
  return out.join("\n");
};

function render(d) {
  const L = [];
  const push = (...xs) => L.push(...xs);
  const bph = d.assume.blocksPerHour;
  const S = d.sections;

  push("# The Candy Crypt's numbers",
    "",
    "> **Generated from the code** by `tools/gen/crypt-doc.js`, which runs the game's own",
    "> Luau modules. Do not edit this file: change the module and run",
    "> `node tools/gen/crypt-doc.js`. `tools/verify/crypt-doc.js` fails when it is stale.",
    "> The owner's rules are in `wiki/open-questions.md` (\"Candy Crypt v2\"); every other",
    "> number here is PROPOSED (2026-10-19) and lives in one table per area:",
    "> `MineConfig.CANDY_ECONOMY` (ores), `MineCandyTools` (tools), `MineCryptChests`",
    "> (chests), `MineTrickOrTreat` (the case).",
    "",
    `Sections are ${d.span} layers. The odds stop moving at section ${S} (layers ${(S - 1) * d.span + 1}-${S * d.span}, the Crypt's`,
    `bottom); the rock keeps hardening below it. The Crypt is remade every ${d.resetSec / 60} minutes while the`,
    "event runs.",
    "",
    `**Per-hour columns assume ${commas(bph)} blocks an hour** (a block every three seconds). That is`,
    "this document's own estimate, not a measurement: nobody has played the Crypt yet.",
    "");

  // 1. HP
  push("## 1. Block HP per section", "",
    "Zone 3's surface rock at the top to zone 10's at layer 120 (owner), smooth per layer. Coins are",
    "the Crypt's old low curve (`cryptSellHp`), so the rock still sells for little.",
    "");
  push(table(["section", "layers", "HP, first layer", "HP, last layer", "coins a block"],
    d.hp.map((h) => [String(h.section) + (h.section > S ? " (below the bottom)" : ""), `${h.first}-${h.last}`,
      commas(h.hpFirst), commas(h.hpLast),
      h.coinsFirst === h.coinsLast ? commas(h.coinsFirst) : `${commas(h.coinsFirst)}-${commas(h.coinsLast)}`])), "");

  // 2. Ores
  push("## 2. The sixteen candy ores", "",
    "Two per rarity, by value. A block always drops the same number of its ore item (owner: \"every",
    "ore drops the same amount every time\"), and pays the same flat candy at every depth: about a",
    `quarter (\`CANDY_SHARE\` ${d.economy.CANDY_SHARE}) of its ore-drop value. Ore items sell for candy, never gems.`,
    "");
  push(table(["#", "ore", "rarity", "items a block", "candy an item", "a block's ore value", "candy a block", "crafts"],
    d.ores.map((o) => [o.rank, o.name, o.band, o.drop, commas(o.value), commas(o.drop * o.value), commas(o.candy), o.tool || "-"])), "");

  // 3. Odds
  push("## 3. Spawn chance per section", "",
    `Each rarity is q times as common as the one below it; q walks from ${d.economy.RATIO_TOP} (section 1) to`,
    `${d.economy.RATIO_BOTTOM} (section ${S}). The Exotic pair is capped at ${pct(d.economy.EXOTIC_CAP, 0)} (owner: "the rarest always`,
    `stay rare"). The two ores of a rarity split it ${pct(d.economy.PAIR_SPLIT, 0)} / ${pct(1 - d.economy.PAIR_SPLIT, 0)}.`,
    "", "### By rarity", "");
  const bands = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic"];
  const secHead = [];
  for (let s = 1; s <= S; s++) secHead.push(String(s));
  push(table(["rarity", ...secHead], bands.map((b, i) => [b, ...secHead.map((_, s) => pct(d.rarity[s][i]))])), "");
  push("### By ore", "");
  push(table(["ore", ...secHead], d.ores.map((o, i) => [o.name, ...secHead.map((_, s) => pct(d.odds[s][i]))])), "");

  // 4. Mix
  push("## 4. What a block pays, per section", "",
    "The expected value of one candy block at each section's odds, with the standard deviation",
    "across the spawn mix (the spread is wide: a rare block is worth hundreds of common ones). Chest",
    `candy is ${pct(d.chestChance, 1)} of blocks being a chest, times that section's average chest.`,
    "");
  push(table(["section", "candy a block", "SD", "ore items a block", "SD", "ore value a block", "SD",
    "chest candy a block", `candy an hour (blocks + chests)`, "candy an hour, selling every ore too"],
  secHead.map((_, s) => {
    const m = d.mix[s];
    const blocksCandy = m.candy + d.chestChance * m.chestCandy;
    return [s + 1, fix(m.candy, 2), fix(m.candySd, 1), fix(m.units, 2), fix(m.unitsSd, 2), fix(m.value, 1), fix(m.valueSd, 1),
      fix(d.chestChance * m.chestCandy, 2), commas(blocksCandy * bph), commas((blocksCandy + m.value) * bph)];
  })), "");

  // 5. Chests
  push("## 5. Crypt chests", "",
    `About ${commas(d.chestChance * bph)} chests an hour (${pct(d.chestChance, 1)} of blocks). Eight ranks, F to SSS, each with its own name.`,
    "A chest pays its rank's Halloween packs (the Halloween 2026 Pack, at the rank's pack luck, which",
    "leans the pack's odds toward rarer pets), flat candy (the same at every depth), the rank's own",
    `Halloween charm at ${pct(d.charmChance, 1)} x Chest Luck, and sometimes a Halloween enchant book. No coins, gems`,
    "or tools.",
    "");
  push(table(["rank", "chest", "Halloween packs", "pack luck", "candy", "charm (0.5% x Chest Luck)", "book chance"],
    d.chests.map((c) => [c.key, c.name, c.packs, c.luck > 1 ? "x" + c.luck : "plain", commas(c.candy),
      d.charmHook ? (c.charm || "-") : "the rank's (MineCharms.cryptChestCharm, not in this build)",
      d.bookHook ? pct(c.bookChance, 1) + " (measured)" : "MineEnchants.rollHalloweenBook (not in this build)"])), "");
  push("### Rank odds per section", "");
  push(table(["rank", ...secHead], d.chests.map((c, i) => [c.key + " " + c.name, ...secHead.map((_, s) => pct(d.chestOdds[s][i]))])), "");

  // 6. Case
  const c = d.case;
  push("## 6. The Trick-or-Treat case", "",
    `**${commas(c.price)} candy.** Halloween pets and Halloween skins only. The server rolls the rarity, the`,
    `kind and which one, **then a ${Math.round(c.treat * 100)}/${Math.round((1 - c.treat) * 100)} wheel: TREAT you get it, TRICK you get nothing.** A skin you`,
    "already own pays stardust instead. Kinds: " + c.kinds.map((k) => `${k.kind}s ${pct(k.pct / 100, 0)}`).join(", ") + ".",
    "\"Shown\" is the chance the wheel shows that prize; \"kept\" is the chance you get it (shown x TREAT).",
    "");
  push(table(["rung", "pet", "skin", "shown", "a pet", "a skin", "kept (TREAT)", "pets it can be", "skins it can be"],
    c.rows.map((r) => [r.index, r.pet, r.skin, pct(r.pct / 100), pct(r.petPct / 100), pct(r.skinPct / 100),
      pct(r.keepPct / 100), r.pets, r.skins])), "");

  // 7. Tools
  const tr = d.toolRules;
  push("## 7. Halloween tools", "",
    `Sixteen, one per candy ore, crafted from it at the Forge and never dropped. Prestige 1-${tr.prestigeMax}, paid in more`,
    `of that ore (step k costs craft x ${tr.costBase} x ${tr.costGrowth}^(k-1), rounded up); each prestige adds +${Math.round(tr.prestigePower * 100)}% of the base power.`,
    `At most ${tr.cap}. Scrapping pays ${pct(tr.scrapShare, 0)} of the candy value of every ore spent on the tool, no ore back.`,
    `New tools are crafted ${tr.craftAfterEvent ? "during and after the event" : "only while the event runs"}; prestige works after it too.`,
    "", "### The tools", "");
  push(table(["#", "tool", "family", "ore", "rarity", "craft (ore)", "all 10 prestiges (ore)", "Halloween-skin factor", "12 pick-hits at layer"],
    d.tools.map((t) => [t.rank, t.name, t.family, t.ore, t.band, t.craft, t.total - t.craft, "x" + t.skinFactor, t.tuneLayer])), "");
  push("### Prestige cost, in the tool's own ore", "");
  const pHead = [];
  for (let k = 1; k <= tr.prestigeMax; k++) pHead.push("P" + k);
  push(table(["tool", ...pHead, "total with craft"], d.tools.map((t) => [t.name, ...t.costs.map((x) => commas(x)), commas(t.total)])), "");
  push("### Damage in the Crypt, at every prestige", "",
    "One hit, before pets, skins, charms and enchants. A Halloween-set skin's whole multiplier is",
    "multiplied by the tool's factor on top.", "");
  const kHead = [];
  for (let k = 0; k <= tr.prestigeMax; k++) kHead.push("P" + k);
  push(table(["tool", ...kHead], d.tools.map((t) => [t.name, ...t.crypt.map(short)])), "");
  push("### Damage in the main world, after the event", "",
    "A Halloween tool there hits like a forged tool of its family: the ore and level below. The",
    `Jawbreaker Auger at P${tr.prestigeMax} is exactly the best normal drill at the top level (${tr.topOre}, level ${tr.maxLevel}); everything`,
    `else is weaker. x = (rank - 1 + prestige x ${tr.world.PRESTIGE_RANKS}) / (15 + 10 x ${tr.world.PRESTIGE_RANKS}); ore tier = ${tr.world.LOW_TIER} + (82 - ${tr.world.LOW_TIER}) x x^${tr.world.CURVE};`,
    `level = 1 + ${tr.maxLevel - 1} x prestige / 10.`, "");
  push(table(["tool", ...kHead, "best normal of its family"], d.tools.map((t) => [t.name, ...t.world.map(short), short(t.bestNormal)])), "");
  push("### What it hits like out there", "");
  push(table(["tool", "P0", "P5", "P10"], d.tools.map((t) => [t.name,
    ...[0, 5, 10].map((k) => `Lv ${t.worldEq[k].level} ${t.worldEq[k].ore}`)])), "");
  push("### Scrap value, in candy", "");
  push(table(["tool", "P0", "P5", "P10"], d.tools.map((t) => [t.name, commas(t.scrap[0]), commas(t.scrap[5]), commas(t.scrap[10])])), "");
  push("(The free Candy Corn Pick cost nothing to craft, so scrapping it refunds only the prestiges paid for.)", "");

  // 8. Gems
  push("## 8. Gems", "",
    "**Nothing in the Crypt pays gems** (owner: gems must hold their value). Candy ores sell for",
    "candy only, chests pay no gems, and the case pays pets and skins. The first design spawned",
    "normal ores in the Crypt, which sold for gems; v2 spawns none. What that removes, an hour:", "");
  push(table(["section", "first design's ore gems an hour", "v2"],
    secHead.map((_, s) => [s + 1, commas(d.mix[s].v1GemsPerBlock * bph), "0"])), "");
  push("(Lucky blocks roll on Crypt blocks in both designs, unchanged.)");
  return L.join("\n") + "\n";
}

/*
  THE SAME NUMBERS AS ROWS, for the web page (owner: the numbers document "in the
  repo, generated from the code, and as a web page"). One JSON file per table, raw
  numbers with no formatting, chances as fractions (0.25 = 25%). The page draws
  every figure from these, so it can never disagree with this document.

    node tools/gen/crypt-doc.js --data <dir>
*/
function datasets(d) {
  const S = d.sections;
  const bands = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic"];
  const tr = d.toolRules;
  const c = d.case;
  const bph = d.assume.blocksPerHour;
  const out = {};
  out.rules = [{
    blocksPerHour: bph, sectionLayers: d.span, sections: S, resetMinutes: d.resetSec / 60,
    candyShare: d.economy.CANDY_SHARE, ratioTop: d.economy.RATIO_TOP, ratioBottom: d.economy.RATIO_BOTTOM,
    exoticCap: d.economy.EXOTIC_CAP, pairSplit: d.economy.PAIR_SPLIT,
    chestChance: d.chestChance, chestsPerHour: d.chestChance * bph, charmChance: d.charmChance,
    casePrice: c.price, treatChance: c.treat,
    prestigeMax: tr.prestigeMax, prestigeCostBase: tr.costBase, prestigeCostGrowth: tr.costGrowth,
    prestigePower: tr.prestigePower, toolCap: tr.cap, scrapShare: tr.scrapShare,
    craftAfterEvent: tr.craftAfterEvent, topOre: tr.topOre, maxLevel: tr.maxLevel, pickHits: tr.pickHits,
  }];
  out.hp = d.hp.map((h) => ({
    section: h.section, layers: `${h.first}-${h.last}`, firstLayer: h.first, lastLayer: h.last,
    hpFirst: h.hpFirst, hpLast: h.hpLast, coinsFirst: h.coinsFirst, coinsLast: h.coinsLast, belowBottom: h.section > S,
  }));
  out.ores = d.ores.map((o) => ({
    rank: o.rank, ore: o.name, id: o.id, rarity: o.band, itemsPerBlock: o.drop, candyPerItem: o.value,
    oreValuePerBlock: o.drop * o.value, candyPerBlock: o.candy, crafts: o.tool || null,
  }));
  out.spawn = [];
  for (let s = 0; s < S; s++) {
    d.ores.forEach((o, i) => out.spawn.push({ section: s + 1, ore: o.name, rarity: o.band, chance: d.odds[s][i] }));
  }
  out.payouts = d.mix.map((m, s) => {
    const blocksCandy = m.candy + d.chestChance * m.chestCandy;
    return {
      section: s + 1, candyPerBlock: m.candy, candySd: m.candySd, oreItemsPerBlock: m.units, oreItemsSd: m.unitsSd,
      oreValuePerBlock: m.value, oreValueSd: m.valueSd, chestCandyPerBlock: d.chestChance * m.chestCandy,
      candyPerHour: blocksCandy * bph, candyPerHourSellingOres: (blocksCandy + m.value) * bph,
      firstDesignGemsPerHour: m.v1GemsPerBlock * bph, gemsPerHour: 0,
    };
  });
  out.chests = d.chests.map((ch) => ({
    rank: ch.key, chest: ch.name, packs: ch.packs, packLuck: ch.luck, candy: ch.candy,
    charm: d.charmHook ? (ch.charm || null) : null, bookChance: d.bookHook ? ch.bookChance : null,
  }));
  out.chestOdds = [];
  for (let s = 0; s < S; s++) {
    d.chests.forEach((ch, i) => out.chestOdds.push({ section: s + 1, rank: ch.key, chest: ch.name, chance: d.chestOdds[s][i] }));
  }
  out.trickOrTreat = c.rows.map((r) => ({
    rung: r.index, pet: r.pet, skin: r.skin, shown: r.pct / 100, petChance: r.petPct / 100,
    skinChance: r.skinPct / 100, kept: r.keepPct / 100, pets: r.pets, skins: r.skins,
  }));
  out.tools = d.tools.map((t) => ({
    rank: t.rank, tool: t.name, id: t.id, family: t.family, ore: t.ore, rarity: t.band, craftOre: t.craft,
    prestigeOre: t.total - t.craft, totalOre: t.total, skinFactor: t.skinFactor, tuneLayer: t.tuneLayer,
    bestNormal: t.bestNormal,
    worldP0: `Lv ${t.worldEq[0].level} ${t.worldEq[0].ore}`, worldP5: `Lv ${t.worldEq[5].level} ${t.worldEq[5].ore}`,
    worldP10: `Lv ${t.worldEq[10].level} ${t.worldEq[10].ore}`,
  }));
  out.prestige = [];
  for (const t of d.tools) {
    for (let k = 0; k <= tr.prestigeMax; k++) {
      out.prestige.push({
        tool: t.name, prestige: k, costOre: k === 0 ? null : t.costs[k - 1],
        cryptDamage: t.crypt[k], worldDamage: t.world[k], scrapCandy: t.scrap[k],
      });
    }
  }
  return out;
}

function main() {
  const at = process.argv.indexOf("--data");
  if (at !== -1) {
    const dir = process.argv[at + 1];
    if (!dir) throw new Error("--data needs a folder to write into");
    const sets = datasets(gather());
    fs.mkdirSync(dir, { recursive: true });
    for (const [name, rows] of Object.entries(sets)) {
      fs.writeFileSync(path.join(dir, name + ".json"), JSON.stringify(rows) + "\n");
    }
    console.log("wrote " + Object.keys(sets).length + " datasets to " + dir);
    return;
  }
  const doc = render(gather());
  if (process.argv.includes("--check")) {
    const have = fs.existsSync(OUT) ? fs.readFileSync(OUT, "utf8").split("\r\n").join("\n") : "";
    if (have !== doc) {
      console.log("docs/CANDY-CRYPT.md is stale: run  node tools/gen/crypt-doc.js");
      process.exit(1);
    }
    console.log("ok docs/CANDY-CRYPT.md matches the code");
    return;
  }
  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  fs.writeFileSync(OUT, doc);
  console.log("wrote docs/CANDY-CRYPT.md (" + doc.length + " bytes)");
}

try {
  main();
} catch (e) {
  console.log("crypt-doc: " + (e && e.message ? e.message : e));
  process.exit(1);
}
