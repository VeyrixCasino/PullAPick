-- MineCharms: one-equip chase identities.
-- Zone grants: every second (odd) island × three depth bands.
-- Pack: 15 gem/Robux pool. Lucky Charm is reserved limited (not in pack).

local MineCharms = {}
-- Numbers follow handoff/launch/CHARMS.md ("one slot = chase": a shallow charm is
-- +100-140%, mid +170-230%, deep +250-320%). A morning retune had cut the five dig
-- charms to +18-90%; the user asked for them back (2026-09-19).

function MineCharms.bandForLayer(layer)
	layer = math.max(1, math.floor(tonumber(layer) or 1))
	if layer <= 500 then
		return "shallow"
	elseif layer <= 1500 then
		return "mid"
	end
	return "deep"
end

MineCharms.CHARM_ZONES = {
	meadow = true,
	mistreef = true,
	bloodmoon = true,
	riftmarch = true,
	mythral = true,
}

local LIST = {
	{ id = "sod", name = "Sod Charm", source = "zone", zoneId = "meadow", band = "shallow",
		blurb = "+110% Mine Speed", stats = { mineSpeed = 1.10 } },
	{ id = "rootstride", name = "Rootstride Charm", source = "zone", zoneId = "meadow", band = "mid",
		blurb = "+180% Mine Speed · +60% Backpack", stats = { mineSpeed = 1.80, backpack = 0.60 } },
	{ id = "thornvault", name = "Thornvault Charm", source = "zone", zoneId = "meadow", band = "deep",
		blurb = "+260% Dirt Break · +40% Pulverizer", stats = { dirtBreak = 2.60, pulverize = 0.40 } },

	{ id = "brine", name = "Brine Charm", source = "zone", zoneId = "mistreef", band = "shallow",
		blurb = "+130% Gem Find", stats = { gemFind = 1.30 } },
	{ id = "tideglass", name = "Tideglass Charm", source = "zone", zoneId = "mistreef", band = "mid",
		blurb = "+200% Mine Speed · +40% Swing Rate", stats = { mineSpeed = 2.00, swingRate = 0.40 } },
	{ id = "abyss_latch", name = "Abyss Latch", source = "zone", zoneId = "mistreef", band = "deep",
		blurb = "+55% Omni Blast · +90% Scrap", stats = { oreYield = 0.55, scrap = 0.90 } },

	{ id = "emberseal", name = "Emberseal Charm", source = "zone", zoneId = "bloodmoon", band = "shallow",
		blurb = "+140% Dirt Break", stats = { dirtBreak = 1.40 } },
	{ id = "veilspike", name = "Veilspike Charm", source = "zone", zoneId = "bloodmoon", band = "mid",
		blurb = "+210% Mine Speed · +50% Luck", stats = { mineSpeed = 2.10, luck = 0.50 } },
	{ id = "crimson_crown", name = "Crimson Crown", source = "zone", zoneId = "bloodmoon", band = "deep",
		blurb = "+280% Coin Bonus · +70% Chest Luck", stats = { coinBonus = 2.80, chestLuck = 0.70 } },

	{ id = "fracture_pin", name = "Fracture Pin", source = "zone", zoneId = "riftmarch", band = "shallow",
		blurb = "+140% Mine Speed · +50% Dirt Break", stats = { mineSpeed = 1.40, dirtBreak = 0.50 } },
	{ id = "scarpsign", name = "Scarpsign Charm", source = "zone", zoneId = "riftmarch", band = "mid",
		blurb = "+70% Pulverizer · +80% Fossil Finder", stats = { pulverize = 0.70, fossilFind = 0.80 } },
	{ id = "gatebreaker", name = "Gatebreaker Charm", source = "zone", zoneId = "riftmarch", band = "deep",
		blurb = "+300% Mine Speed · +40% Swing Rate", stats = { mineSpeed = 3.00, swingRate = 0.40 } },

	{ id = "prism_nail", name = "Prism Nail", source = "zone", zoneId = "mythral", band = "shallow",
		blurb = "+120% Luck · +80% Gem Find", stats = { luck = 1.20, gemFind = 0.80 } },
	{ id = "catacomb_key", name = "Catacomb Key", source = "zone", zoneId = "mythral", band = "mid",
		blurb = "+100% Chest Luck · +100% Scrap", stats = { chestLuck = 1.00, scrap = 1.00 } },
	{ id = "aether_seal", name = "Aether Seal", source = "zone", zoneId = "mythral", band = "deep",
		blurb = "+75% Omni Blast · +250% Mine Speed", stats = { oreYield = 0.75, mineSpeed = 2.50 } },

	{ id = "jackhammer", name = "Jackhammer", source = "pack",
		blurb = "+160% Dirt Break · +50% Swing Rate", stats = { dirtBreak = 1.60, swingRate = 0.50 } },
	{ id = "midas_touch", name = "Midas Touch", source = "pack",
		blurb = "+200% Coin Bonus", stats = { coinBonus = 2.00 } },
	{ id = "piggybank", name = "Piggybank", source = "pack",
		blurb = "+170% sell payout", stats = { coinBonus = 1.70 } },
	{ id = "cartwright", name = "Cartwright", source = "pack",
		blurb = "+180% Backpack", stats = { backpack = 1.80 } },
	{ id = "night_shift", name = "Night Shift", source = "pack",
		blurb = "+120% Chest Luck", stats = { chestLuck = 1.20 } },
	{ id = "seer", name = "Seer", source = "pack",
		blurb = "+130% Luck", stats = { luck = 1.30 } },
	{ id = "smelter", name = "Smelter", source = "pack",
		blurb = "+65% Pulverizer", stats = { pulverize = 0.65 } },
	{ id = "prospector", name = "Prospector", source = "pack",
		blurb = "+200% Gem Find", stats = { gemFind = 2.00 } },
	{ id = "spindle", name = "Spindle", source = "pack",
		blurb = "+100% Swing Rate", stats = { swingRate = 1.00 } },
	{ id = "striker", name = "Striker", source = "pack",
		blurb = "+230% Mine Speed", stats = { mineSpeed = 2.30 } },
	{ id = "chainlink", name = "Chainlink", source = "pack",
		blurb = "+60% Zap", stats = { zap = 0.60 } },
	{ id = "yardarm", name = "Yardarm", source = "pack",
		blurb = "+100% Fossil Finder", stats = { fossilFind = 1.00 } },
	{ id = "scrappers_sign", name = "Scrapper's Sign", source = "pack",
		blurb = "+120% Scrap", stats = { scrap = 1.20 } },
	{ id = "cubit_pin", name = "Cubit Pin", source = "pack",
		blurb = "+50% Lucky Find", stats = { luckyFind = 0.50 } },
	{ id = "canopy", name = "Canopy", source = "pack",
		blurb = "+55% Omni Blast", stats = { oreYield = 0.55 } },

	--[[
		Pot of Gold carries EVERY kind of luck.

		It was one stat -- pack luck -- on an item sold as the luck item. Chest
		odds, ore quality, ore quantity, gems and lucky blocks are all separate
		stats and it touched none of them.

		`luck` stays at 2. It is advertised at 200% on a limited item people
		paid for, and dropping it to 1.00 to make the row tidy would be a nerf
		to something already bought. Everything else lands at a full 100%.
	]]
	{ id = "lucky_charm", name = "Pot of Gold", source = "limited",
		blurb = "200% Luck + 100% of every other luck. LIMITED TIME. NEVER COMING BACK.",
		stats = {
			luck = 2,            -- packs / cards
			chestLuck = 1.00,    -- chests
			rareOre = 1.00,      -- ore quality
			fossilFind = 1.00,   -- ore quantity (the ore finder)
			gemFind = 1.00,      -- gems
			luckyFind = 1.00,    -- lucky blocks
		} },
}

--[[
	A ZONE CHARM IS A FIND, NOT A DOOR PRIZE.

	It used to be handed over the first time you broke a block in the right
	band -- a 100% drop in every zone, which made five of the strongest items in
	the game a formality you walked into.

	It is a roll per qualifying block now. The exception is your FIRST charm:
	somebody who owns none gets the next one outright, because the early game is
	built around wearing one (the Sod Charm is most of why the second pickaxe
	one-shots dirt) and a new player should never be gated behind a 1-in-220 on
	their way to it.
]]
-- A roll PER BLOCK. 0.01% flat, set directly by the owner.
-- (1 in 220 before, which was a charm every twenty-odd seconds.)
MineCharms.ZONE_DROP_ONE_IN = 10000

function MineCharms.zoneDropChance(ownsAny)
	if not ownsAny then
		return 1
	end
	return 1 / math.max(1, MineCharms.ZONE_DROP_ONE_IN)
end


--[[
	ONE CHARM PER ORE, ALL 82, DERIVED FROM THE ROSTER.

	Charms are an ORE drop now -- the contents of an ore case -- not a zone
	hand-out and not something a chest pays. So the roster has to cover the
	roster: every ore that can drop a case must have a charm behind it, or a
	case rolls a charm and finds nothing there.

	These are GENERATED rather than authored, on purpose. 82 hand-written rows
	would be 82 chances to leave one out, and the roster is renumbered often
	enough that it has already happened once to the tool ladder. Deriving them
	means "one per ore" is a property of the code instead of a thing somebody
	has to remember. The ore's own tier, band and name are the only inputs.

	MAGNITUDE rides the ore's tier, straight down the band spec: +100% at
	tier 1 to +320% at tier 82. A shallow charm lands in the +100-140% range
	and a deep one in +250-320%, which is where the authored charms already
	sit, so an ore charm never reads as a different class of item from them.

	WHICH STAT cycles through the pool by tier, so neighbouring ores do not all
	buff the same thing and no stat is left without a charm. Every third ore
	gets a second, smaller stat -- enough variety that two charms in the same
	band are worth telling apart, without a second magnitude ladder to balance.

	Deliberately NOT in the pool: echo (barred as a buff), zap and blastRadius
	(both pending a nerf). A generated table is the last place a stat under
	review should quietly get 82 new sources.
]]
-- Multiplicative stats only. One magnitude scale cannot serve both these and
-- the additive ones, which are fractions; the additive secondaries below get
-- their own, much smaller scale.
local ORE_CHARM_STATS = {
	"mineSpeed", "dirtBreak", "coinBonus", "gemFind",
	"luck", "chestLuck", "backpack", "swingRate",
}
-- Secondaries are additive, so these are fractions of a whole, not multipliers.
local ORE_CHARM_SECOND = { "pulverize", "scrap", "fossilFind", "oreYield", "luckyFind" }

MineCharms.ORE_CHARM_MIN = 1.00
MineCharms.ORE_CHARM_MAX = 3.20

local STAT_LABEL = {
	mineSpeed = "Mine Speed", dirtBreak = "Dirt Break", coinBonus = "Coin Bonus",
	gemFind = "Gem Find", luck = "Luck", chestLuck = "Chest Luck",
	backpack = "Backpack", swingRate = "Swing Rate", pulverize = "Pulverizer",
	scrap = "Scrap", fossilFind = "Fossil Finder", oreYield = "Omni Blast",
	luckyFind = "Lucky Find",
}

-- The charm id for an ore id. One function, so the server and the UI cannot
-- disagree about what an ore's charm is called.
function MineCharms.oreCharmId(oreId)
	return tostring(oreId or "") .. "_charm"
end

do
	local C = require(script.Parent:WaitForChild("MineConfig"))
	local ores = C.ORES or {}
	local span = math.max(1, (C.ORE_COUNT or #ores) - 1)
	local lo, hi = MineCharms.ORE_CHARM_MIN, MineCharms.ORE_CHARM_MAX
	for i, ore in ipairs(ores) do
		local tier = tonumber(ore.tier) or i
		local t = math.clamp((tier - 1) / span, 0, 1)
		local primary = ORE_CHARM_STATS[((tier - 1) % #ORE_CHARM_STATS) + 1]
		-- Floor to a hundredth so the number a player reads is the number
		-- applied, rather than a rounded label over a longer float.
		local mag = math.floor((lo + (hi - lo) * t) * 100 + 1e-9) / 100
		local stats = { [primary] = mag }
		local blurb = string.format("+%d%% %s", math.floor(mag * 100 + 1e-9), STAT_LABEL[primary] or primary)
		if tier % 3 == 0 then
			local second = ORE_CHARM_SECOND[((tier // 3 - 1) % #ORE_CHARM_SECOND) + 1]
			local sm = math.floor(mag * 0.25 * 100 + 1e-9) / 100
			stats[second] = sm
			blurb = blurb .. string.format(" · +%d%% %s", math.floor(sm * 100 + 1e-9), STAT_LABEL[second] or second)
		end
		table.insert(LIST, {
			id = MineCharms.oreCharmId(ore.id),
			name = (ore.name or ore.id) .. " Charm",
			source = "ore",
			oreId = ore.id,
			tier = tier,
			band = ore.band,
			blurb = blurb,
			stats = stats,
		})
	end
end

MineCharms.LIST = LIST
MineCharms.PACK_PRICE_GEMS = 2500

local BY_ID = {}
local ZONE_BAND = {}
local PACK = {}
local BY_ORE = {}
for _, def in ipairs(LIST) do
	BY_ID[def.id] = def
	if def.source == "zone" and def.zoneId and def.band then
		ZONE_BAND[def.zoneId .. "|" .. def.band] = def
	elseif def.source == "pack" then
		table.insert(PACK, def)
	elseif def.source == "ore" and def.oreId then
		BY_ORE[tostring(def.oreId)] = def
	end
end

function MineCharms.byId(id)
	return BY_ID[tostring(id or "")]
end

--[[
	The charm an ore pays, by ore id.

	Every ore has one, and this is the only way to ask for it: a caller that
	builds the id by hand would go quietly nil the day the suffix changes.
]]
function MineCharms.oreCharm(oreId)
	return BY_ORE[tostring(oreId or "")]
end

function MineCharms.zoneBandCharm(zoneId, band)
	return ZONE_BAND[tostring(zoneId or "") .. "|" .. tostring(band or "")]
end

function MineCharms.packPool()
	return PACK
end

local ADDITIVE = {
	echo = true, zap = true, blastRadius = true, autoMine = true, oreYield = true,
	luckyFind = true, fossilFind = true, pulverize = true, scrap = true,
	coolant = true, shortFuse = true, reach = true,
}

function MineCharms.applyEquipped(b, charmId)
	local def = MineCharms.byId(charmId)
	if not def or not b or type(def.stats) ~= "table" then
		return
	end
	for stat, amount in pairs(def.stats) do
		amount = tonumber(amount) or 0
		if amount == 0 then
			-- skip
		elseif stat == "swingRate" then
			b.swingSec = (b.swingSec or 1) / (1 + amount)
		elseif ADDITIVE[stat] then
			b[stat] = (b[stat] or 0) + amount
		else
			b[stat] = (b[stat] or 1) + amount
		end
	end
end

function MineCharms.describe(def)
	if not def then
		return ""
	end
	return def.blurb or def.name or ""
end

function MineCharms.rollPack(ownedSet, rng)
	rng = rng or Random.new()
	local pool = {}
	for _, def in ipairs(PACK) do
		if not (ownedSet and ownedSet[def.id]) then
			table.insert(pool, def)
		end
	end
	if #pool == 0 then
		return nil
	end
	return pool[rng:NextInteger(1, #pool)]
end

return MineCharms
