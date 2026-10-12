// Enchants (owner, 2026-10-11): three slots, books, the player level.
//
//   1. the Special slot decides the proc: other families zeroed, no special =
//      no proc, the enchant adds its own, chance over 100% becomes damage
//   2. levels I-V: compounding where the owner said so (Power +5%/level)
//   3. compatibility: explosives take no Special and no in-swing enchant
//   3b. the eight MINING enchants (owner, 2026-10-12: "Make the 'coming soon'
//      enchants actually work"): crit, executioner, demolition, combo,
//      overclock, vein miner, alchemy, duplicator -- their maths and wiring
//   4. books: keys round-trip, 3 merge into 1 a level up, ~5% of chests drop one
//   4b. bundles (owner, 2026-10-12): chests 2-4 books, lucky blocks 2/3/5, never
//      cases; gems buy a 3-book bundle at the Forge
//   5. the player level: the XP curve, slot unlocks at 1/10/25, a gift every 5
//   6. wiring: MineServer feeds Layer 1, gates procs, pays XP and books,
//      returns books on recycle, keeps books and level through rebirth
//
//   node tools/verify/enchants.js
"use strict";
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");
const Luau = require("./_luau");

const ROOT = path.resolve(__dirname, "../..");
const read = (p) => fs.readFileSync(path.join(ROOT, p), "utf8").replace(/\r\n/g, "\n");
let fail = 0;
const check = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };

if (!Luau.ready) { console.log(Luau.missing("luau") + "; skipping"); process.exit(1); }
const src = read("src/ReplicatedStorage/Mine/Shared/MineEnchants.luau");
const harness = `
Color3 = { fromRGB = function(r, g, b) return { r, g, b } end }
Random = {}
Random.__index = Random
function Random.new(seed) return setmetatable({ s = (seed or 48611) % 2147483647 }, Random) end
function Random:NextNumber() self.s = (self.s * 48271) % 2147483647 return self.s / 2147483647 end
function Random:NextInteger(a, b) return a + math.floor(self:NextNumber() * (b - a + 1)) end
local E = (function()
${src}
end)()
local function boostsWith()
	return { zap = 0.3, zapDamage = 0.5, blastChance = 0.4, blastDamage = 0.2, blastRadius = 1, tidalWave = 0.2,
		tideDamage = 0.1, ricochet = 0.1, shatterDamage = 0.1, earthquake = 0.05, procPower = 0.3, mineSpeed = 1 }
end
-- 1. gating
local b = E.gateProcs(boostsWith(), { id = "zap", level = 5 })
print(string.format("ZAP %.3f %.3f %.3f %.3f %.3f %.3f %.3f", b.zap, b.zapDamage, b.blastChance, b.blastDamage, b.blastRadius, b.tidalWave, b.procPower))
local n = E.gateProcs(boostsWith(), nil)
print(string.format("NONE %.3f %.3f %.3f %.3f %.3f %.3f", n.zap, n.blastChance, n.tidalWave, n.earthquake, n.procPower, n.blastDamage))
local bare = E.gateProcs({ zap = 0, blastChance = 0, tidalWave = 0, ricochet = 0, earthquake = 0, procPower = 0.4 }, nil)
print(string.format("BARE %.3f", bare.procPower))
local o = boostsWith()
o.zap = 1.1
o = E.gateProcs(o, { id = "zap", level = 2 })
print(string.format("OVER %.3f %.3f", o.zap, o.zapDamage))
-- 2. levels
local power = E.statsAt(E.get("power"), 5)[1]
local heavy = E.statsAt(E.get("heavy"), 5)
print(string.format("POWER %s %.4f", power.stat, power.value))
print(string.format("HEAVY %.4f %.4f", heavy[1].value, heavy[2].value))
print("DESC " .. E.describe(E.get("power"), 5) .. " | " .. E.describe(E.get("zap"), 3))
print("LATER " .. #E.statsAt(E.get("crit"), 5))
print("TIER " .. E.tierOf(1) .. E.tierOf(2) .. E.tierOf(3) .. E.tierOf(4) .. E.tierOf(5) .. " " .. E.tier("zap", 3).chains .. " " .. E.tier("shatter", 2).maxProcs .. " " .. E.tier("blast", 3).chainMax)
local g5 = E.gateProcs({ zap = 0.1, zapDamage = 0 }, { id = "zap", level = 5 })
local g0 = E.gateProcs({ zap = 0.1 }, nil)
print("PTIER " .. g5.procTier .. " " .. g0.procTier)
-- 3. compatibility
local okS = E.compatible(E.get("zap"), "explosive")
local okP = E.compatible(E.get("zap"), "pickaxe")
local okL = E.compatible(E.get("crit"), "explosive")
local okC = E.compatible(E.get("crit"), "pickaxe")
local okPw = E.compatible(E.get("power"), "explosive")
print("COMPAT " .. tostring(okS) .. " " .. tostring(okP) .. " " .. tostring(okL) .. " " .. tostring(okC) .. " " .. tostring(okPw))
-- 3b. mining enchants
local function hm(id, h) return (E.hitMult(E.get(id), 5, h)) end
print(string.format("HIT %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f",
	hm("crit", { dmg = 10, roll = 0.1 }), hm("crit", { dmg = 10, roll = 0.3 }),
	hm("executioner", { dmg = 10, hp = 20 }), hm("executioner", { dmg = 10, hp = 21 }),
	hm("demolition", { dmg = 10, maxHp = 80 }), hm("demolition", { dmg = 10, maxHp = 79 }),
	hm("combo", { dmg = 10, combo = 1 }), hm("combo", { dmg = 10, combo = 500 }), hm("power", { dmg = 10, roll = 0 })))
local _, word = E.hitMult(E.get("crit"), 1, { dmg = 1, roll = 0 })
print("CRITWORD " .. tostring(word))
local oc = E.get("overclock")
print(string.format("SPEED %.3f %.3f %.3f %.3f", E.overclockSpeed(oc, 5, 0), E.overclockSpeed(oc, 5, 20), E.overclockSpeed(oc, 5, 99), E.overclockSpeed(E.get("combo"), 5, 20)))
print(string.format("ORE %.3f %.3f %d %d %.3f", E.oreChance(E.get("alchemy"), 5), E.oreChance(E.get("duplicator"), 5),
	E.veinBlocks(E.get("veinminer"), 5), E.veinBlocks(E.get("fortune"), 5), E.oreChance(E.get("fortune"), 5)))
local allLive = true
for _, d in ipairs(E.LIST) do if not d.live then allLive = false end end
print("LIVE " .. tostring(allLive) .. " " .. E.describe(E.get("combo"), 5) .. " | " .. E.describe(E.get("duplicator"), 5))
-- 4. books
local id, lv = E.parseBookKey(E.bookKey("gemfinder", 3))
print("KEY " .. tostring(id) .. " " .. tostring(lv) .. " " .. tostring(E.parseBookKey("nope:9")))
local rng = Random.new(3)
local got, lifted = 0, 0
for i = 1, 100000 do
	local bk = E.rollChestBook("S", rng, 1)
	if bk then got += 1 if bk.level > 1 then lifted += 1 end end
end
local gotC = 0
for i = 1, 100000 do if E.rollChestBook("C", rng, 1) then gotC += 1 end end
print("BOOKS " .. got .. " " .. lifted .. " " .. gotC)
-- 4b. bundles
local rngB = Random.new(7)
local sizes = {}
for _, r in ipairs({ "S", "A", "B", "C", "F" }) do
	local bnd
	repeat bnd = E.rollChestBundle(r, rngB, 1) until bnd
	table.insert(sizes, tostring(#bnd))
end
print("CBUNDLE " .. table.concat(sizes, " "))
print("LBUNDLE " .. #E.luckyBundle("lucky_block") .. " " .. #E.luckyBundle("super_lucky_block") .. " " .. #E.luckyBundle("godly_lucky_block") .. " " .. #E.luckyBundle("nope"))
print("PRICE " .. E.bundlePrice(1) .. " " .. E.bundlePrice(2) .. " " .. E.bundlePrice(10))
local nb = 0
for i = 1, 100000 do if E.rollChestBundle("C", rngB, 1) then nb += 1 end end
print("CBRATE " .. nb)
print("BTEXT " .. E.bundleText({ { id = "power", level = 1 }, { id = "zap", level = 2 } }))
-- 5. levels
print(string.format("XP %d %d %d", E.xpToNext(1), E.xpToNext(10), E.xpToNext(25)))
local total10, total25 = 0, 0
for l = 1, 9 do total10 += E.xpToNext(l) end
for l = 1, 24 do total25 += E.xpToNext(l) end
print("TOTAL " .. total10 .. " " .. total25)
local r10, r25, r5, r1 = E.levelRewards(10), E.levelRewards(25), E.levelRewards(5), E.levelRewards(1)
print("REWARDS " .. table.concat(r10.unlocks, ",") .. " " .. table.concat(r25.unlocks, ",") .. " " .. tostring(r5.gift and r5.gift.gems) .. " " .. #r1.unlocks)
print("SLOTS " .. tostring(E.slotUnlocked("utility", 9)) .. " " .. tostring(E.slotUnlocked("utility", 10)) .. " " .. tostring(E.slotUnlocked("special", 25)))
local ids, dup = {}, 0
for _, d in ipairs(E.LIST) do if ids[d.id] then dup += 1 end ids[d.id] = true end
local slots = { damage = 0, utility = 0, special = 0 }
for _, d in ipairs(E.LIST) do slots[d.slot] += 1 end
print("LIST " .. #E.LIST .. " " .. dup .. " " .. slots.damage .. " " .. slots.utility .. " " .. slots.special)
`;
const script = path.join(ROOT, ".luau-bin/enchants-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(Luau.LUAU, [script], { encoding: "utf8" }); }
catch (e) { process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || ""); fail++; }
const get = (tag) => (out.split(/\r?\n/).find((l) => l.startsWith(tag + " ")) || "").slice(tag.length + 1).trim();
const num = (tag) => get(tag).split(" ").map(Number);

// 1
const z = num("ZAP");
check(Math.abs(z[0] - 0.55) < 1e-9 && Math.abs(z[1] - 1.0) < 1e-9, "a Zap V tool keeps its zap and adds the enchant's (30% + 25%; damage 50% + 50%)");
check(z[2] === 0 && z[3] === 0 && z[4] === 0 && z[5] === 0, "...and every other family (blast, its radius, tide) is zeroed: pets only boost YOUR proc (owner)");
check(Math.abs(z[6] - 0.3) < 1e-9, "generic proc damage stays for the proc you have");
const nn = num("NONE");
check(nn[0] === 0 && Math.abs(nn[1] - 0.4) < 1e-9 && nn[2] === 0 && nn[3] === 0 && Math.abs(nn[4] - 0.3) < 1e-9 && Math.abs(nn[5] - 0.2) < 1e-9,
  "no Special yet: the tool keeps its gear's BEST proc (blast 40% here) and nothing else (owner: \"Pets' best proc until you pick one\")");
check(get("BARE") === "0.000", "no proc at all: proc damage has nothing to land on");
const ov = num("OVER");
check(ov[0] === 1 && Math.abs(ov[1] - (0.5 + 0.2 + 0.2)) < 1e-9, "a chance over 100% converts into that proc's damage (owner): 110% + 10% -> 100% and +20% damage");
// 2
const pw = get("POWER").split(" ");
check(pw[0] === "mineSpeed" && Math.abs(Number(pw[1]) - (1.05 ** 5 - 1)) < 1e-4, "Power V is +27.6% damage: +5% a level, compounded (owner)");
const hv = num("HEAVY");
check(Math.abs(hv[0] - 0.3) < 1e-4 && Math.abs(hv[1] + 0.2) < 1e-4, "Heavy Impact V is +30% damage and -20% speed (owner)");
check(get("DESC") === "+27.6% | T2 Fork: 2 chains · 15% chance, +30% damage", "the cards print the real numbers, with the ability tier");
check(get("TIER") === "11223 3 6 3", "3 tiers per ability: I-II tier 1, III-IV tier 2, V tier 3 (owner); Storm 3 chains, Splinter 6 bursts, Detonation 3 pops");
check(get("PTIER") === "3 1", "a Special V tool is tier 3; pets' best proc alone is tier 1");
check(get("LATER") === "0", "a mining enchant (Critical Strike) adds no Layer 1 stat: it acts inside the swing");
// 3
check(get("COMPAT") === "false true false true true", "explosives take no Special (they roll no procs) and no in-swing enchant (a charge never swings); Power still fits them");
// 3b
const hit = num("HIT");
check(hit[0] === 2.5 && hit[1] === 1, "Critical Strike V: a 20% chance of x2.5 (4% a level, PROPOSED)");
check(get("CRITWORD") === "CRIT!", "...and a crit flashes CRIT! over the block");
check(hit[2] === 2 && hit[3] === 1, "Executioner V: +100% on a block within 2 hits of breaking, nothing before");
check(Math.abs(hit[4] - 1.4) < 1e-9 && hit[5] === 1, "Demolitionist V: +40% on a block that takes 8+ hits, nothing on softer ones");
check(hit[6] === 1 && Math.abs(hit[7] - 3) < 1e-9, "Combo V: the first hit is plain, then +2% a hit in a row up to 100 (owner): +200% at the cap");
check(hit[8] === 1, "a plain stat enchant (Power) does nothing inside the swing: it is already in Layer 1");
const sp = num("SPEED");
check(sp[0] === 1 && sp[1] === 2 && sp[2] === 2 && sp[3] === 1, "Overclock V: +5% speed a one-shot in a row, max 20 (owner): twice as fast at the cap, never more");
const ore = num("ORE");
check(Math.abs(ore[0] - 0.1) < 1e-9 && Math.abs(ore[1] - 0.2) < 1e-9 && ore[2] === 10 && ore[3] === 0 && ore[4] === 0,
  "Alchemy V 10%, Duplicator V 20%, Vein Miner V 10 more blocks (PROPOSED); other enchants roll none of these");
check(/^true /.test(get("LIVE")), "every enchant is live: no card says COMING SOON any more");
check(get("LIVE").includes("damage a hit in a row (max 100)") && get("LIVE").includes("20% double ore"), "the cards say what the mining enchants do, with the real numbers");
// 4
check(get("KEY") === "gemfinder 3 nil", "book keys round-trip; a bad key is refused");
const [got, lifted, gotC] = num("BOOKS");
check(got > 4500 && got < 5500 && gotC > 4500 && gotC < 5500, `about 5% of chests drop a book (${got}, ${gotC} of 100,000)`);
check(lifted / got > 0.3 && lifted / got < 0.4, `an S chest's book is II or III about 35% of the time (${(lifted / got * 100).toFixed(0)}%)`);
// 4b
check(get("CBUNDLE") === "4 3 3 2 2", "a chest's book roll pays a bundle: 4 books from an S chest, 3 from A or B, 2 otherwise (owner chose 2-5, scaled)");
check(get("LBUNDLE") === "2 3 5 2", "every lucky block pays a bundle: Lucky 2, Diamond 3, Godly 5");
check(get("PRICE") === "500 575 1759", "the Forge's gem bundle is 500 gems, x1.15 a zone (PROPOSED)");
const cbr = num("CBRATE")[0];
check(cbr > 4500 && cbr < 5500, `bundles drop from about 5% of chests, as the single book did (${cbr} of 100,000)`);
check(get("BTEXT") === "Power I, Zap II", "a bundle's toast names its books");
// 5
const xp = num("XP");
check(xp[0] === 40 && xp[1] === 94 && xp[2] === 394, "the XP step is 40 x 1.1^(level-1)");
const tot = num("TOTAL");
check(tot[0] > 500 && tot[0] < 600 && tot[1] > 3400 && tot[1] < 3700, `Utility (level 10) is ${tot[0]} XP, Special (25) ${tot[1]}`);
check(get("REWARDS") === "utility special 250 0", "level 10 unlocks Utility, 25 Special; every 5 levels a gift (owner's pick)");
check(get("SLOTS") === "false true true", "slots unlock at their level, not before");
const ls = num("LIST");
check(ls[1] === 0 && ls[2] >= 5 && ls[3] >= 5 && ls[4] === 5, `${ls[0]} enchants, unique ids; ${ls[2]} damage, ${ls[3]} utility, 5 specials (one per proc)`);

// 6 wiring
const sv = read("src/ServerScriptService/Mine/MineServer.server.luau");
check(/Enchants = require\(shared:WaitForChild\("MineEnchants"\)\)/.test(sv) && /Dig\.EnchSvc = Verbs\.Ench/.test(sv), "MineServer loads the module and the service");
check(/string\.sub\(action, 1, 4\) == "ench" then\s*\n\s*Verbs\.Ench\.dispatch/.test(sv), "every \"ench\" action goes to the service");
check(/for _, st in ipairs\(Dig\.EnchSvc\.layerStats\(p\)\) do\s*\n\s*Dig\.Layers\.add\(T1, st\.stat, st\.value\)/.test(sv), "Damage and Utility enchants are Layer 1, where traits sit");
check(/b = Dig\.Enchants\.gateProcs\(b, Dig\.EnchSvc\.special\(p\)\)\s*\n\s*end\s*\n\s*return Runes\.clampBoosts\(b\)/.test(sv), "the Special slot gates the procs last, on the finished boosts");
check(/Dig\.EnchSvc\.chestBundle\(plr, p, rank, rng/.test(sv) && /XP_CHEST \* \(Dig\.Enchants\.XP_CHEST_RANK/.test(sv) && /gainXp\(plr, p, Dig\.Enchants\.XP_ORE\)/.test(sv),
  "chests drop books and pay XP; ore blocks pay XP");
const rec = (sv.match(/function Verbs\.recycleOreTool[\s\S]*?\nend\n/) || [""])[0];
check(/Dig\.EnchSvc\.returnBooks\(p, tool\)[\s\S]*table\.remove\(p\.oreTools, index\)/.test(rec), "recycling a tool gives its enchants back first");
check(/"enchantBooks", "level", "xp",/.test(sv), "books and the player level survive rebirth");
const procs = (sv.match(/function Dig\.procsAt[\s\S]*?\nend\n/) || [""])[0];
check(/local tier = math\.clamp\(math\.floor\(tonumber\(b\.procTier\) or 1\), 1, 3\)/.test(procs) && /Tiers\("blast", tier\)/.test(procs) && /Tiers\("tide", tier\)/.test(procs)
  && /Tiers\("shatter", tier\)/.test(procs) && /Tiers\("quake", tier\)/.test(procs) && /Tiers\("zap", tier\)/.test(procs), "every ability reads its tier in Dig.procsAt");
check(/pops < popMax/.test(procs) && /math\.clamp\(math\.floor\(tonumber\(tt\.chains\) or 1\), 1, 3\)/.test(procs) && /math\.min\(spread, #near\)/.test(procs), "the tiers are capped: blast pops, zap chains and quake spread all have limits");
check(/manual \*= Dig\.EnchSvc\.swingSpeed\(p\)/.test(sv), "Overclock speeds up the server's swing budget");
check(/dmg = Dig\.EnchSvc\.hitDamage\(plr, p, part, dmg, maxHp\)/.test(sv), "the swing's damage goes through the Damage slot's mining enchant");
check(/local wasWhole = /.test(sv) && /Dig\.EnchSvc\.afterSwing\(plr, p, centreBroken and wasWhole, aimPos\)/.test(sv), "Overclock counts one-shots: a whole block broken by one swing");
check(/ore = Dig\.EnchSvc\.alchemy\(plr, p, ore, part\.Position\)/.test(sv) && /got = Dig\.EnchSvc\.duplicate\(plr, p, got, part\.Position\)/.test(sv),
  "ore breaks roll Alchemy (before the yield) and Duplicator (after Ore Haul)");
check(/C\.oreHaulMult\(bb and bb\.oreHaul\)/.test(sv) && !/C\.oreHaulMult\(b and b\.oreHaul\)/.test(sv), "Ore Haul reads this function's boosts (bb): it read an undefined b and never paid");
const vein = (sv.match(/function Dig\.veinAt[\s\S]*?\nend\n/) || [""])[0];
check(/Dig\.veinAt\(plr, p, zone, part\)/.test(sv) && /Dig\.veining\[p\] = true/.test(vein) && /if n <= 0 or Dig\.veining\[p\]/.test(vein)
  && /GetAttribute\("OreId"\) == oreId/.test(vein) && /took < n/.test(vein), "Vein Miner takes only the same ore, at most n blocks, and a vein block never starts its own vein");
const cl = read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau");
check(/ClientFns\.enchSpeed = \{/.test(cl) && /swingSec \/ ocMult/.test(cl), "the client paces its swings by Overclock's speed, and lets it lapse after the grace");
const lucky = (sv.match(/function openLuckyBlock[\s\S]*?\nend\n/) || [""])[0];
check(/loot\.books = Dig\.EnchSvc\.luckyBundle\(p, blockId, rng\)/.test(lucky), "opening a lucky block pays its bundle");
check((sv.match(/EnchSvc\.chestBundle\(/g) || []).length === 1 && (sv.match(/EnchSvc\.luckyBundle\(/g) || []).length === 1
  && !/rollChestBook|chestBook\(/.test(sv), "books come from exactly two places, chests and lucky blocks: never cases (owner)");
check(/loot\.books/.test(read("src/ReplicatedStorage/Mine/Shared/MineGradeReveal.luau")), "the lucky reveal lists the books with the rest of the loot");
const hub = read("src/ReplicatedStorage/Mine/Shared/MineForgeHub.luau");
check(/act\("enchBuyBundle"/.test(hub) && /function ctl\.showBundle/.test(hub) && /hub\.showBundle/.test(read("src/StarterPlayer/StarterPlayerScripts/MineForgeHub.client.luau")),
  "the Forge sells the bundle and opens it on screen");
const svc = read("src/ServerScriptService/Mine/MineEnchantService.luau");
const buy = (svc.match(/function V\.enchBuyBundle[\s\S]*?\nend\n/) || [""])[0];
check(/< price then\s*\n\s*return/.test(buy) && buy.indexOf("< price") < buy.indexOf("p.gems = ") && /bundlePrice\(p\)/.test(buy),
  "buying checks the gems before taking them, at the server's own price");
check(/__mode = "k"/.test(svc) && /now - s\.comboAt > E\.COMBO_GRACE/.test(svc) && /E\.OVERCLOCK_GRACE/.test(svc), "streaks are per player, never saved, and end after a pause");
check(/E\.slotUnlocked\(slot, p\.level\)/.test(svc) && /E\.compatible\(def, tool\.familyId/.test(svc) && /takeBook\(p, def\.id, level, 1\)/.test(svc),
  "applying checks the level, the slot, compatibility and the book before anything changes");
check(/RunService:IsStudio\(\)/.test((svc.match(/function V\.enchDebugGrant[\s\S]*?\nend\n/) || [""])[0]), "the book grant works only in Studio");

console.log("");
console.log(fail > 0 ? `>>> enchants: ${fail} FAILED` : ">>> enchants: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
