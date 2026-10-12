--[[
	MineEnchants -- tool ENCHANTMENTS: three slots, levels I to V, books.

	The owner's design (2026-10-11), in short:
	  * Every compatible tool has THREE slots, one enchant each:
	      DAMAGE   make the tool break blocks better
	      UTILITY  get more out of what you break
	      SPECIAL  change how the tool mines: it decides the tool's PROC. "This
	               slot determines which effect your tool will have, regardless
	               of pet setup. The pets only boost this." A proc chance over
	               100% converts into that proc's damage.
	  * Levels I to V. "anything that is a progressive boost is compounded".
	  * Enchants replace TRAITS and RUNES ("RETIRE RUNES AND TRAITS.. ENCHNATS
	    TAKE OVERTHAT FEILD").
	and chose (2026-10-11): enchants come as BOOKS from chests (2026-10-12: in
	BUNDLES, from chests and lucky blocks, never cases; gems buy them too); three
	of the same book at the same level merge into one a level up (to V); the
	slots unlock with the new PLAYER LEVEL (Damage 1, Utility 10, Special 25),
	which is earned from ores and chests, never from the pass.

	THIS FILE IS THE ONE SOURCE. The server's stats, the Forge's cards and the
	checks all read these definitions; nothing else states an enchant's number.
	Values marked PROPOSED are first passes for the owner; the ones the owner
	gave are marked (owner).

	LIVE vs NOT YET. An enchant whose effect needs mining code the game does
	not have is marked `live = false`: the Forge shows it as "COMING SOON" and
	the server refuses to apply it, so no card ever promises something the game
	does not do. Since 2026-10-12 every enchant here is live (owner: "Make the
	'coming soon' enchants actually work"); the flag stays for the next one.

	Pure: no services. MineServer reads it as Dig.Enchants.
]]
local M = {}

M.MAX_LEVEL = 5
M.ROMAN = { "I", "II", "III", "IV", "V" }

-- ------------------------------------------------------------- slots --
M.SLOTS = {
	{ id = "damage", name = "Damage", icon = "⚔", color = Color3.fromRGB(255, 110, 70), unlockLevel = 1,
		purpose = "Break blocks faster" },
	{ id = "utility", name = "Utility", icon = "💰", color = Color3.fromRGB(110, 220, 130), unlockLevel = 10,
		purpose = "Get more from every block" },
	{ id = "special", name = "Special", icon = "✨", color = Color3.fromRGB(170, 120, 255), unlockLevel = 25,
		purpose = "Your tool's power" },
}
M.SLOT_BY_ID = {}
for i, s in ipairs(M.SLOTS) do
	s.index = i
	M.SLOT_BY_ID[s.id] = s
end

-- ------------------------------------------------------------- procs --
--[[
	The proc FAMILIES a Special enchant can give a tool, and the stat keys each
	one owns in boosts(). Every other family's chance and damage is zeroed for
	the tool in hand (gateProcs), so a pet, skin or charm only ever BOOSTS the
	proc your Special enchant picked.
]]
M.PROCS = {
	zap = { name = "Zap", chance = "zap", damage = "zapDamage" },
	blast = { name = "Blast", chance = "blastChance", damage = "blastDamage", extra = { "blastRadius" } },
	tide = { name = "Tidal Wave", chance = "tidalWave", damage = "tideDamage" },
	shatter = { name = "Shatter", chance = "ricochet", damage = "shatterDamage" },
	quake = { name = "Earthquake", chance = "earthquake", damage = "procPower" },
}
M.PROC_ORDER = { "zap", "blast", "tide", "shatter", "quake" }

--[[
	THREE TIERS PER ABILITY. Owner, 2026-10-12: "Make 3 levels of abilities",
	and chose tiers that CHANGE HOW IT WORKS, picked by the Special enchant's
	level: I-II tier 1, III-IV tier 2, V tier 3 (TIER_OF). "also made the
	ability itself have a proc chance and dmage": every level adds both (the
	Special entries' effect.chance / effect.damage). A tool on its pets' best
	proc, with no Special, is tier 1. MineServer Dig.procsAt reads b.procTier.

	Every tier is capped so one hit cannot snowball (owner's "real limits"):
	the caps are the numbers in each tier below. PROPOSED.
]]
M.TIER_OF = { 1, 1, 2, 2, 3 }
M.TIERS = {
	zap = {
		{ name = "Spark", text = "1 chain", chains = 1, continue = 0.80 },
		{ name = "Fork", text = "2 chains", chains = 2, continue = 0.80 },
		{ name = "Storm", text = "3 longer chains", chains = 3, continue = 0.85 },
	},
	blast = {
		{ name = "Pop", text = "the 6 sides", cells = "face6" },
		{ name = "Burst", text = "18 blocks around", cells = "edge18" },
		{ name = "Detonation", text = "all 26 around, and breaks pop again (max 3)", cells = "cube26", chain = 0.25, chainMax = 3 },
	},
	tide = {
		{ name = "Swell", text = "1 layer", layers = 1 },
		{ name = "Breaker", text = "2 layers", layers = 2 },
		{ name = "Tsunami", text = "3 layers", layers = 3 },
	},
	shatter = {
		{ name = "Crack", text = "up to 3 bursts", maxProcs = 3 },
		{ name = "Splinter", text = "up to 6 bursts", maxProcs = 6 },
		{ name = "Cascade", text = "up to 10 bursts", maxProcs = 10 },
	},
	quake = {
		{ name = "Tremor", text = "1 block shakes", spread = 0, mult = 1 },
		{ name = "Rumble", text = "+2 blocks nearby", spread = 2, mult = 1 },
		{ name = "Cataclysm", text = "+4 blocks, +50% damage", spread = 4, mult = 1.5 },
	},
}

function M.tierOf(level)
	return M.TIER_OF[math.clamp(math.floor(tonumber(level) or 1), 1, M.MAX_LEVEL)] or 1
end

-- The tier table for a proc family at a tier.
function M.tier(family, tier)
	local t = M.TIERS[family]
	return t and t[math.clamp(math.floor(tonumber(tier) or 1), 1, 3)] or nil
end

-- Tool families. Explosives detonate without rolling procs (MineServer
-- detonate), so a Special enchant would do nothing on one: not compatible.
M.FAMILIES = { "pickaxe", "hammer", "drill", "jackhammer", "explosive" }
M.FAMILY_NAME = { pickaxe = "Pickaxes", hammer = "Sledgehammers", drill = "Drills", jackhammer = "Jackhammers",
	explosive = "Explosives" }

-- ---------------------------------------------------------- rarities --
M.RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
M.RARITY_COLOR = {
	Common = Color3.fromRGB(170, 170, 170),
	Uncommon = Color3.fromRGB(85, 255, 127),
	Rare = Color3.fromRGB(85, 170, 255),
	Epic = Color3.fromRGB(170, 85, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
}
-- How often each rarity's books drop, relative (PROPOSED).
M.RARITY_WEIGHT = { Common = 100, Uncommon = 45, Rare = 18, Epic = 7, Legendary = 2.5 }

-- --------------------------------------------------------- the list --
--[[
	effect kinds:
	  mult   a multiplier stat, compounding: x (base ^ level). Added to Layer 1
	         (where traits were) as the fraction (base^level - 1).
	  add    an additive stat: + per * level.
	  multi  several of the above at once (Heavy Impact).
	  proc   a Special: { family, chance per level, damage per level }.
	  hit    a Damage enchant that acts inside the swing (hitMult,
	         overclockSpeed below; MineEnchantService keeps the streaks).
	  ore    a Utility enchant that acts on an ore drop (oreChance,
	         veinBlocks below).
]]
-- The tools that SWING. A thrown charge never swings, so the in-swing Damage
-- enchants do nothing on one: not compatible (Power and Heavy still are).
local SWUNG = { "pickaxe", "hammer", "drill", "jackhammer" }

M.LIST = {
	-- ---------------------------------------------------- DAMAGE --
	{ id = "power", name = "Power", icon = "💪", slot = "damage", rarity = "Common", live = true,
		effect = { kind = "mult", stat = "mineSpeed", base = 1.05 },
		blurb = "More damage on every hit" }, -- owner: +5% per level, compounded
	{ id = "heavy", name = "Heavy Impact", icon = "🔨", slot = "damage", rarity = "Uncommon", live = true,
		effect = { kind = "multi", parts = {
			{ stat = "mineSpeed", base = 1.3 ^ (1 / 5) },
			{ stat = "swingRate", base = 0.8 ^ (1 / 5) },
		} },
		blurb = "Much harder hits, slower swings" }, -- owner: +30% damage, -20% speed (at V)
	{ id = "crit", name = "Critical Strike", icon = "💥", slot = "damage", rarity = "Rare", live = true, families = SWUNG,
		effect = { kind = "hit", chance = 0.04, mult = 2.5 },
		blurb = "A chance for a huge hit" }, -- PROPOSED 4% a level, x2.5
	{ id = "executioner", name = "Executioner", icon = "🪓", slot = "damage", rarity = "Rare", live = true, families = SWUNG,
		effect = { kind = "hit", per = 0.2, hitsLeft = 2 },
		blurb = "Finishes blocks that are almost broken" }, -- PROPOSED +20% a level within 2 hits of breaking
	{ id = "demolition", name = "Demolitionist", icon = "🧱", slot = "damage", rarity = "Rare", live = true, families = SWUNG,
		effect = { kind = "hit", per = 0.08, hitsFrom = 8 },
		blurb = "Big damage on tough blocks" }, -- PROPOSED +8% a level on blocks of 8+ hits
	{ id = "overclock", name = "Overclock", icon = "⚡", slot = "damage", rarity = "Epic", live = true, families = SWUNG,
		effect = { kind = "hit", perStack = 0.01, stacks = 20 },
		blurb = "Faster with every one-shot in a row" }, -- owner: +5%/one-shot, max 20 (at V)
	{ id = "combo", name = "Combo", icon = "🔥", slot = "damage", rarity = "Epic", live = true, families = SWUNG,
		effect = { kind = "hit", perStack = 0.004, stacks = 100 },
		blurb = "Stronger with every hit in a row" }, -- owner: +2%/hit, max 100 (at V)

	-- --------------------------------------------------- UTILITY --
	{ id = "fortune", name = "Fortune", icon = "🍀", slot = "utility", rarity = "Uncommon", live = true,
		effect = { kind = "add", stat = "oreHaul", per = 0.1 },
		blurb = "More ore from every ore block" }, -- PROPOSED +10% a level
	{ id = "scavenger", name = "Scavenger", icon = "🪙", slot = "utility", rarity = "Common", live = true,
		effect = { kind = "mult", stat = "coinBonus", base = 1.1 },
		blurb = "More coins" }, -- PROPOSED x1.1 a level
	{ id = "gemfinder", name = "Gemfinder", icon = "💎", slot = "utility", rarity = "Rare", live = true,
		effect = { kind = "mult", stat = "gemFind", base = 1.08 },
		blurb = "More gems" }, -- PROPOSED x1.08 a level
	{ id = "treasure", name = "Treasure Hunter", icon = "🗝", slot = "utility", rarity = "Rare", live = true,
		effect = { kind = "mult", stat = "chestLuck", base = 1.08 },
		blurb = "Better chests and cases" }, -- PROPOSED x1.08 a level
	{ id = "reach", name = "Reach", icon = "🎯", slot = "utility", rarity = "Common", live = true,
		effect = { kind = "add", stat = "reach", per = 0.08 },
		blurb = "Hit blocks from further away" }, -- PROPOSED +8% a level
	{ id = "experience", name = "Experience", icon = "⭐", slot = "utility", rarity = "Uncommon", live = true,
		effect = { kind = "xp", base = 1.1 },
		blurb = "More player XP" }, -- PROPOSED x1.1 a level
	{ id = "veinminer", name = "Vein Miner", icon = "⛓", slot = "utility", rarity = "Epic", live = true,
		effect = { kind = "ore", blocks = 2 },
		blurb = "Breaks the rest of an ore vein" }, -- owner; PROPOSED +2 vein blocks a level, ore only
	{ id = "alchemy", name = "Alchemy", icon = "⚗", slot = "utility", rarity = "Epic", live = true,
		effect = { kind = "ore", chance = 0.02 },
		blurb = "A chance to upgrade the ore you mine" }, -- owner's 2nd "Fortune"; PROPOSED 2% a level
	{ id = "duplicator", name = "Duplicator", icon = "📋", slot = "utility", rarity = "Rare", live = true,
		effect = { kind = "ore", chance = 0.04 },
		blurb = "A chance for double ore" }, -- PROPOSED 4% a level

	-- --------------------------------------------------- SPECIAL --
	-- Owner: "Zap, Blast, Tidal wave, Etcetc". Chance and damage are PROPOSED.
	{ id = "zap", name = "Zap", icon = "⚡", slot = "special", rarity = "Epic", live = true,
		effect = { kind = "proc", family = "zap", chance = 0.05, damage = 0.1 },
		blurb = "Lightning jumps from block to block" },
	{ id = "blast", name = "Blast", icon = "💣", slot = "special", rarity = "Epic", live = true,
		effect = { kind = "proc", family = "blast", chance = 0.05, damage = 0.1 },
		blurb = "Breaking a block blows up its neighbours" },
	{ id = "tide", name = "Tidal Wave", icon = "🌊", slot = "special", rarity = "Epic", live = true,
		effect = { kind = "proc", family = "tide", chance = 0.04, damage = 0.1 },
		blurb = "A wave hits the whole layer around you" },
	{ id = "shatter", name = "Shatter", icon = "🔷", slot = "special", rarity = "Rare", live = true,
		effect = { kind = "proc", family = "shatter", chance = 0.06, damage = 0.1 },
		blurb = "Shards fly into nearby blocks" },
	{ id = "quake", name = "Earthquake", icon = "🌋", slot = "special", rarity = "Legendary", live = true,
		effect = { kind = "proc", family = "quake", chance = 0.04, damage = 0.1 },
		blurb = "Hits build a quake that shakes everything" },
}

M.BY_ID = {}
for i, def in ipairs(M.LIST) do
	def.index = i
	M.BY_ID[def.id] = def
end

function M.get(id)
	return M.BY_ID[tostring(id or "")]
end

function M.roman(level)
	return M.ROMAN[math.clamp(math.floor(tonumber(level) or 1), 1, M.MAX_LEVEL)]
end

-- -------------------------------------------------------- the effect --
local function pct(x)
	local v = x * 100
	if math.abs(v - math.floor(v + 0.5)) < 0.05 then
		return string.format("%d%%", math.floor(v + 0.5))
	end
	return string.format("%.1f%%", v)
end

-- The stats one enchant adds at a level, for boosts(): { { stat, value, how } }.
-- `how` is "layer" (Layer 1, like the trait it replaces) or "xp" (read by the
-- XP grant, not a boost). Specials go through gateProcs instead.
function M.statsAt(def, level)
	level = math.clamp(math.floor(tonumber(level) or 1), 1, M.MAX_LEVEL)
	local e = def and def.effect
	local out = {}
	if not (e and def.live) then
		return out
	end
	if e.kind == "mult" then
		table.insert(out, { stat = e.stat, value = e.base ^ level - 1, how = "layer" })
	elseif e.kind == "add" then
		table.insert(out, { stat = e.stat, value = e.per * level, how = "layer" })
	elseif e.kind == "multi" then
		for _, part in ipairs(e.parts) do
			table.insert(out, { stat = part.stat, value = part.base ^ level - 1, how = "layer" })
		end
	elseif e.kind == "xp" then
		table.insert(out, { stat = "xp", value = e.base ^ level, how = "xp" })
	end
	return out
end

-- One short line for a level: what it does, with the real number.
function M.describe(def, level)
	level = math.clamp(math.floor(tonumber(level) or 1), 1, M.MAX_LEVEL)
	local e = def and def.effect
	if not e then
		return ""
	end
	if e.kind == "mult" then
		return "+" .. pct(e.base ^ level - 1)
	elseif e.kind == "add" then
		return "+" .. pct(e.per * level)
	elseif e.kind == "multi" then
		local a, b = e.parts[1], e.parts[2]
		return "+" .. pct(a.base ^ level - 1) .. " damage, " .. pct(b.base ^ level - 1) .. " speed"
	elseif e.kind == "xp" then
		return "+" .. pct(e.base ^ level - 1) .. " XP"
	elseif e.kind == "proc" then
		local t = M.tier(e.family, M.tierOf(level))
		return (t and ("T" .. M.tierOf(level) .. " " .. t.name .. ": " .. t.text .. " · ") or "")
			.. pct(e.chance * level) .. " chance, +" .. pct(e.damage * level) .. " damage"
	elseif def.id == "crit" then
		return pct(e.chance * level) .. " for x" .. tostring(e.mult)
	elseif def.id == "executioner" then
		return "+" .. pct(e.per * level) .. " near breaking"
	elseif def.id == "demolition" then
		return "+" .. pct(e.per * level) .. " on tough blocks"
	elseif def.id == "overclock" then
		return "+" .. pct(e.perStack * level) .. " speed a one-shot in a row (max " .. e.stacks .. ")"
	elseif def.id == "combo" then
		return "+" .. pct(e.perStack * level) .. " damage a hit in a row (max " .. e.stacks .. ")"
	elseif def.id == "veinminer" then
		return "+" .. tostring(e.blocks * level) .. " vein blocks"
	elseif def.id == "alchemy" then
		return pct(e.chance * level) .. " to upgrade the ore"
	elseif def.id == "duplicator" then
		return pct(e.chance * level) .. " double ore"
	elseif e.chance then
		return pct(e.chance * level) .. " chance"
	end
	return ""
end

-- ---------------------------------------------------- mining enchants --
--[[
	The Damage enchants that act INSIDE a swing and the Utility ones that act on
	an ORE DROP. Pure maths; MineEnchantService keeps the streaks and MineServer
	calls it from the swing (swingBlock) and the ore break (finishBreak).

	A streak ends after a pause (PROPOSED graces below): Combo after
	COMBO_GRACE seconds without a hit, Overclock after OVERCLOCK_GRACE
	without a one-shot -- or at once, on a swing that did not one-shot.
]]
M.COMBO_GRACE = 2
M.OVERCLOCK_GRACE = 2.5

local function lv(level)
	return math.clamp(math.floor(tonumber(level) or 1), 1, M.MAX_LEVEL)
end

--[[
	One swing's damage multiplier from a Damage enchant, and the word to flash
	(or nil). h = { dmg, hp, maxHp, combo, roll }: hp is the block's HP before
	the swing, combo the streak counting THIS hit, roll a 0-1 number (the crit's
	dice). Overclock is speed, not damage: overclockSpeed.
]]
function M.hitMult(def, level, h)
	local e = def and def.live and def.effect
	if not (e and e.kind == "hit" and type(h) == "table") then
		return 1, nil
	end
	level = lv(level)
	local dmg = math.max(1, tonumber(h.dmg) or 1)
	if def.id == "crit" then
		if (tonumber(h.roll) or 1) < e.chance * level then
			return e.mult, "CRIT!"
		end
	elseif def.id == "executioner" then
		if (tonumber(h.hp) or math.huge) <= dmg * e.hitsLeft then
			return 1 + e.per * level, nil
		end
	elseif def.id == "demolition" then
		if (tonumber(h.maxHp) or 0) >= dmg * e.hitsFrom then
			return 1 + e.per * level, nil
		end
	elseif def.id == "combo" then
		-- The hits BEFORE this one are the stacks, so the first hit is plain.
		local stacks = math.clamp(math.floor(tonumber(h.combo) or 1) - 1, 0, e.stacks)
		return 1 + e.perStack * level * stacks, nil
	end
	return 1, nil
end

-- Overclock's swing speed at a streak of one-shots (1 = no faster).
function M.overclockSpeed(def, level, streak)
	local e = def and def.live and def.id == "overclock" and def.effect
	if not e then
		return 1
	end
	return 1 + e.perStack * lv(level) * math.clamp(math.floor(tonumber(streak) or 0), 0, e.stacks)
end

-- Alchemy's and Duplicator's chance on one ore drop.
function M.oreChance(def, level)
	local e = def and def.live and def.effect
	if not (e and e.kind == "ore" and e.chance) then
		return 0
	end
	return e.chance * lv(level)
end

-- How many more blocks of the vein Vein Miner takes.
function M.veinBlocks(def, level)
	local e = def and def.live and def.id == "veinminer" and def.effect
	return e and (e.blocks * lv(level)) or 0
end

-- ----------------------------------------------------- compatibility --
-- Can `def` go on a tool of `familyId`? Returns ok, reason.
function M.compatible(def, familyId)
	if not def then
		return false, "Unknown enchant"
	end
	if not def.live then
		return false, "Coming soon"
	end
	if def.slot == "special" and familyId == "explosive" then
		return false, "Explosives have no procs"
	end
	if def.families then
		for _, f in ipairs(def.families) do
			if f == familyId then
				return true
			end
		end
		return false, "Not for " .. (M.FAMILY_NAME[familyId] or familyId)
	end
	return true
end

function M.slotUnlocked(slotId, playerLevel)
	local s = M.SLOT_BY_ID[slotId]
	return s ~= nil and (math.floor(tonumber(playerLevel) or 1) >= s.unlockLevel)
end

--[[
	THE SPECIAL SLOT DECIDES THE PROC. Called on the finished boosts table for
	the tool in hand, with that tool's special enchant (or nil):
	  * every OTHER family's chance and damage goes to 0, so pets, skins and
	    charms only boost the proc you picked (owner);
	  * no Special enchant yet: the tool keeps the ONE proc your gear gives the
	    most chance of (owner, 2026-10-12: "Pets' best proc until you pick
	    one"), so a new player still has a proc before the slot opens at 25;
	  * the enchant adds its own chance and damage for its family;
	  * a chance over 100% converts into that proc's damage (owner).
	Returns b.
]]
function M.gateProcs(b, special)
	local def = special and M.get(special.id)
	local fam = def and def.live and def.effect and def.effect.kind == "proc" and def.effect.family or nil
	local fromEnchant = fam ~= nil
	-- The ability's tier: the Special's level picks it; pets' best proc is tier 1.
	b.procTier = fromEnchant and M.tierOf(special.level) or 1
	if not fam then
		-- Pets' best proc until a Special is chosen. Ties go in PROC_ORDER.
		local best = 0
		for _, key in ipairs(M.PROC_ORDER) do
			local c = tonumber(b[M.PROCS[key].chance]) or 0
			if c > best then
				best, fam = c, key
			end
		end
	end
	for key, proc in pairs(M.PROCS) do
		if key ~= fam then
			b[proc.chance] = 0
			if proc.damage ~= "procPower" then
				b[proc.damage] = 0
			end
			for _, x in ipairs(proc.extra or {}) do
				b[x] = 0
			end
		end
	end
	if fam then
		local proc = M.PROCS[fam]
		if fromEnchant then
			local level = math.clamp(math.floor(tonumber(special.level) or 1), 1, M.MAX_LEVEL)
			b[proc.chance] = (b[proc.chance] or 0) + def.effect.chance * level
			b[proc.damage] = (b[proc.damage] or 0) + def.effect.damage * level
		end
		local over = (b[proc.chance] or 0) - 1
		if over > 0 then
			b[proc.chance] = 1
			b[proc.damage] = (b[proc.damage] or 0) + over
		end
	else
		-- No proc to boost: generic proc damage has nothing to land on.
		b.procPower = 0
	end
	return b
end

-- -------------------------------------------------------------- books --
-- A book in the bag: p.enchantBooks["power:1"] = how many.
function M.bookKey(id, level)
	return tostring(id) .. ":" .. tostring(math.clamp(math.floor(tonumber(level) or 1), 1, M.MAX_LEVEL))
end

function M.parseBookKey(key)
	local id, level = string.match(tostring(key or ""), "^([%w_]+):(%d)$")
	level = tonumber(level)
	if not (id and level and M.BY_ID[id] and level >= 1 and level <= M.MAX_LEVEL) then
		return nil
	end
	return id, level
end

M.MERGE_COST = 3 -- three of the same book at the same level make one a level up (owner's pick)

--[[
	BOOKS FROM CHESTS (owner: "Enchant books from chests and cases"). A chest
	drops one CHEST_BOOK_CHANCE of the time (chest luck raises it, capped like
	the cases); which enchant is by rarity weight; the level is I unless the
	chest's rank lifts it (BOOK_RANK_LEVEL: B/A/S chests have a chance at II+).
	PROPOSED numbers. Not-yet-live enchants still drop: a book can wait for its
	effect, and a merge stack can be built early.
]]
M.CHEST_BOOK_CHANCE = 0.05
M.BOOK_LUCK_CAP = 3
M.BOOK_RANK_LEVEL = { B = { 0.15, 0 }, A = { 0.25, 0.05 }, S = { 0.35, 0.12 } } -- chance of II, of III

function M.rollBookId(rng, slotFilter)
	local total = 0
	for _, def in ipairs(M.LIST) do
		if not slotFilter or slotFilter[def.slot] then
			total += M.RARITY_WEIGHT[def.rarity] or 1
		end
	end
	local u = rng:NextNumber() * total
	for _, def in ipairs(M.LIST) do
		if not slotFilter or slotFilter[def.slot] then
			u -= M.RARITY_WEIGHT[def.rarity] or 1
			if u <= 0 then
				return def.id
			end
		end
	end
	return M.LIST[1].id
end

-- A book's level: I, unless a rank (B/A/S) lifts it (BOOK_RANK_LEVEL).
local function liftLevel(rank, rng)
	local lift = M.BOOK_RANK_LEVEL[rank or ""]
	if lift then
		local u = rng:NextNumber()
		if u < lift[2] then
			return 3
		elseif u < lift[1] then
			return 2
		end
	end
	return 1
end

function M.rollChestBook(rank, rng, chestLuck)
	rng = rng or Random.new()
	local luck = math.clamp(tonumber(chestLuck) or 1, 1, M.BOOK_LUCK_CAP)
	if rng:NextNumber() >= M.CHEST_BOOK_CHANCE * luck then
		return nil
	end
	return { id = M.rollBookId(rng), level = liftLevel(rank, rng) }
end

--[[
	BOOK BUNDLES. Owner, 2026-10-12: "Book buddles from lucky blocks, and
	chest(not cases)", and chose 2-5 books, scaled:
	  * a chest's book roll (CHEST_BOOK_CHANCE, as before) pays a BUNDLE:
	    CHEST_BUNDLE_BASE books, more from a better chest (CHEST_BUNDLE);
	  * every lucky block pays one on top of its loot (LUCKY_BUNDLE): Lucky 2,
	    Diamond 3, Godly 5, the better blocks lifting levels like a good chest;
	  * gems buy a SHOP_BUNDLE at the Forge (owner chose "Gems buy book
	    bundles": the gem sink runes used to be), priced up a little a zone.
	Cases never drop books. PROPOSED: the gem price and its step.
]]
M.CHEST_BUNDLE_BASE = 2
M.CHEST_BUNDLE = { S = 4, A = 3, B = 3 }
M.LUCKY_BUNDLE = {
	lucky_block = { n = 2 },
	super_lucky_block = { n = 3, rank = "A" },
	godly_lucky_block = { n = 5, rank = "S" },
}
M.SHOP_BUNDLE = 3
M.SHOP_BUNDLE_PRICE = 500 -- gems at zone 1: the price the trait roll had (PROPOSED)
M.SHOP_BUNDLE_STEP = 1.15 -- x a zone (PROPOSED)

function M.bundlePrice(zoneIndex)
	local z = math.max(1, math.floor(tonumber(zoneIndex) or 1))
	return math.floor(M.SHOP_BUNDLE_PRICE * M.SHOP_BUNDLE_STEP ^ (z - 1) + 0.5)
end

-- n books by rarity weight; a rank can lift their levels.
function M.rollBundle(n, rng, rank)
	rng = rng or Random.new()
	local out = {}
	for _ = 1, math.clamp(math.floor(tonumber(n) or 1), 1, 10) do
		table.insert(out, { id = M.rollBookId(rng), level = liftLevel(rank, rng) })
	end
	return out
end

-- A chest's bundle, or nil (most chests).
function M.rollChestBundle(rank, rng, chestLuck)
	rng = rng or Random.new()
	local luck = math.clamp(tonumber(chestLuck) or 1, 1, M.BOOK_LUCK_CAP)
	if rng:NextNumber() >= M.CHEST_BOOK_CHANCE * luck then
		return nil
	end
	return M.rollBundle(M.CHEST_BUNDLE[rank or ""] or M.CHEST_BUNDLE_BASE, rng, rank)
end

function M.luckyBundle(blockId, rng)
	local spec = M.LUCKY_BUNDLE[tostring(blockId or "")] or M.LUCKY_BUNDLE.lucky_block
	return M.rollBundle(spec.n, rng, spec.rank)
end

-- "Power I, Zap II, Fortune I" for a toast.
function M.bundleText(books)
	local names = {}
	for _, bk in ipairs(books or {}) do
		local def = M.get(bk.id)
		table.insert(names, (def and def.name or tostring(bk.id)) .. " " .. M.roman(bk.level))
	end
	return table.concat(names, ", ")
end

-- --------------------------------------------------------- player XP --
--[[
	THE PLAYER LEVEL (owner: "add levels, from breaking ores and chests. This
	doesnt effect pass xp"; levels unlock the slots and give a gift every 5).
	PROPOSED: an ore block 3 XP, a chest 15 (more for a better rank); the step
	to the next level is 40 x 1.1^(level-1), so Utility (10) is about 45
	minutes of mining and Special (25) a few hours.
]]
M.XP_ORE = 3
M.XP_CHEST = 15
M.XP_CHEST_RANK = { F = 0.6, D = 0.8, C = 1, native = 1, B = 1.4, A = 2, S = 3 }
M.MAX_PLAYER_LEVEL = 200
M.GIFT_EVERY = 5
M.GIFT_GEMS = 250 -- x (level / 5)

function M.xpToNext(level)
	level = math.max(1, math.floor(tonumber(level) or 1))
	return math.floor(40 * 1.1 ^ (level - 1) + 0.5)
end

-- What a level-up to `level` gives: slot unlocks and, every GIFT_EVERY, a gift.
function M.levelRewards(level)
	local out = { unlocks = {}, gift = nil }
	for _, s in ipairs(M.SLOTS) do
		if s.unlockLevel == level and level > 1 then
			table.insert(out.unlocks, s.id)
		end
	end
	if level % M.GIFT_EVERY == 0 then
		out.gift = { book = true, gems = M.GIFT_GEMS * (level / M.GIFT_EVERY) }
	end
	return out
end

return M
