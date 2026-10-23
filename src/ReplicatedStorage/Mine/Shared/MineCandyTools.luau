--[[
	MineCandyTools -- the Candy Crypt's HALLOWEEN TOOLS. The table, the craft
	and prestige costs, and what each hits for in the Crypt and in the main
	world. Pure: no Instances, no profile writes (MineCrypt grants and spends).

	Owner, 2026-10-19 ("Candy Crypt v2", wiki/open-questions.md):
	  * "crafted from candy ores" at the Forge, never dropped. One recipe per
	    tool: N of ITS candy ore.
	  * "prestige 1-10 with more ores (no level upgrades; prestige replaces
	    merging)", paid in more of that ore. Each tool shows its damage at every
	    prestige; "prestige keeps working after the event".
	  * "at most 10 Halloween tools"; at 10, crafting is blocked until you
	    scrap one; "scrapping pays half, in candy value, no ores back" -- half
	    the candy value of EVERY ore spent on it, craft and prestiges.
	  * "make each tool different, but yeah always multiplier to the full
	    multiplier": each tool has its own factor (`skinFactor`) on the WHOLE
	    damage multiplier of a Halloween-set skin worn on it
	    (MineToolSkins.wear).
	  * Power: tuned to the Crypt's rock while the event runs; afterwards they
	    also work in the main world, weaker, "I want the top tool at prestige to
	    be ~the same as top tool, at top level" (worldPower below).

	WHY ONE TOOL PER CANDY ORE. Sixteen ores, sixteen tools, so every ore has a
	job and "more of that ore" names one thing. The ten-tool cap then makes a
	real choice: you cannot keep all sixteen. Two per rarity, in four families
	(pick, mallet, auger, cracker), so each family has one tool in four of the
	eight rarities.

	WHAT A ROW IS (built below from TOOL_TABLE, nothing typed twice):
	  id          "hallow_<ore>_<noun>"  (MineTheme.eventKeyOf reads "hallow_")
	  name        "<Ore> <Noun>"         ("Candy Corn Pick", "Jawbreaker Auger")
	  oreId, rank, band   its candy ore, 1..16, and that ore's rarity
	  family      pickaxe / hammer / drill / explosive (skins resolve by it)
	  craft       candy ore items it takes to craft
	  skinFactor  this tool's factor on a Halloween skin's multiplier
	  tuneLayer   the Crypt layer where a Normal pick of its power takes
	              PICK_HITS hits; the other families scale by FAMILY_POWER
	  rate, cells, radius, shape, ...  the forged frame of its family
	  cryptTool = true, seasonalOnly = true, eventOnly = false (see below)

	EVERY NUMBER HERE IS PROPOSED (2026-10-19) except the owner's: ten
	prestiges, the cap of ten, half back in candy, and the top tool's match.
]]
local MineCandyTools = {}

local shared = script.Parent
local Config = require(shared:WaitForChild("MineConfig"))
local OreTools = require(shared:WaitForChild("MineOreTools"))

MineCandyTools.ZONE_ID = "hallow"

-- The tool card's line. The first-entry pop-up's text is MineCryptRules.NOTICE.
MineCandyTools.WARNING =
	"Halloween tool: digs the Candy Crypt now. It is yours to keep: when the "
	.. "event ends it also works in the main world, weaker."

MineCandyTools.FAMILIES = { "pickaxe", "hammer", "drill", "explosive" }
MineCandyTools.NOUN = { pickaxe = "Pick", hammer = "Mallet", drill = "Auger", explosive = "Cracker" }

--[[
	THE ONE TABLE OF TOOL NUMBERS (PROPOSED 2026-10-19).

	  PICK_HITS        hits a Normal pick of a tool's base power takes at its
	                   tuneLayer: comfortable above it, a slog below, which is
	                   what makes the next tool worth crafting. 12, the v1 number.
	  TUNE_FIRST/STEP  tool r is tuned to layer TUNE_FIRST + TUNE_STEP x (r-1):
	                   the free Candy Corn Pick takes 12 hits at layer 15 (3 at
	                   the top), the Jawbreaker Auger 12 at layer 120, the
	                   bottom. Seven layers apart, about x2 rock per tool.
	  PRESTIGE_MAX     owner: prestige 1 to 10.
	  PRESTIGE_POWER   each prestige adds this share of the base power: P10 hits
	                   x4, about two tools further down the ladder.
	  PRESTIGE_COST    prestige k costs ceil(craft x BASE x GROWTH^(k-1)) of the
	                   tool's own ore: P1 half a craft, P10 2.6 crafts, all ten
	                   13 crafts.
	  CAP              owner: at most ten Halloween tools.
	  SCRAP_SHARE      owner: scrapping pays half the candy value of every ore
	                   spent on the tool.
	  CRAFT_AFTER_EVENT  crafting a NEW tool once the event has ended. false:
	                   the owner said prestige keeps working afterwards and was
	                   silent on crafting (asked in the build report).
	  FRAME_TIER       whose forged frame (swing, footprint, fuse) each family
	                   borrows: one frame per family, so only power changes up
	                   the ladder.
	  WORLD            the main-world mapping, see worldEquivalent.
	  CRAFT_BY_BAND    ore items one craft takes, by the ore's rarity: rarer
	                   ores are scarcer, so fewer of them.
	  TOOL_TABLE       per tool, in ore order: its family and its skin factor.
	                   The factors sit around the owner's first "2x" and differ
	                   by tool (owner: "make each tool different").
]]
MineCandyTools.PICK_HITS = 12
MineCandyTools.TUNE_FIRST = 15
MineCandyTools.TUNE_STEP = 7
MineCandyTools.PRESTIGE_MAX = 10
MineCandyTools.PRESTIGE_POWER = 0.30
MineCandyTools.PRESTIGE_COST = { BASE = 0.5, GROWTH = 1.2 }
MineCandyTools.CAP = 10
MineCandyTools.SCRAP_SHARE = 0.5
MineCandyTools.CRAFT_AFTER_EVENT = false
MineCandyTools.FRAME_TIER = { pickaxe = 41, hammer = 41, drill = 41, explosive = 36 }
--[[
	MAIN WORLD, AFTER THE EVENT. A Halloween tool there hits like a FORGED tool
	of its family: ore tier T at level Lv, read through MineOreTools.hitPower,
	and it breaks what that ore breaks (MineBreaking.oreStrength). With
	x = (rank - 1 + prestige x PRESTIGE_RANKS) / (15 + 10 x PRESTIGE_RANKS):
	  T  = LOW_TIER + (top ore - LOW_TIER) x x^CURVE   (8 Basalt .. 82 Oganesson)
	  Lv = 1 + (TOOL_MAX_LEVEL - 1) x prestige / 10    (P0 level 1, P10 the cap)
	So the Jawbreaker Auger at prestige 10 IS a top-level Oganesson Drill, the
	best normal drill (owner: "~the same as top tool, at top level"), and every
	other tool and prestige is weaker. CURVE > 1 keeps the low and middle of the
	ladder well under the rock they were tuned for in the Crypt.
]]
MineCandyTools.WORLD = { LOW_TIER = 8, CURVE = 1.5, PRESTIGE_RANKS = 0.25 }
MineCandyTools.CRAFT_BY_BAND = {
	Common = 40, Uncommon = 40, Rare = 30, Epic = 25,
	Legendary = 20, Mythic = 15, Divine = 12, Exotic = 10,
}
MineCandyTools.TOOL_TABLE = {
	{ oreId = "candy_corn", family = "pickaxe", skinFactor = 2.5 },
	{ oreId = "gumdrop", family = "hammer", skinFactor = 1.75 },
	{ oreId = "licorice", family = "drill", skinFactor = 2.25 },
	{ oreId = "cotton_candy", family = "explosive", skinFactor = 1.5 },
	{ oreId = "caramel", family = "hammer", skinFactor = 2.0 },
	{ oreId = "taffy", family = "pickaxe", skinFactor = 2.5 },
	{ oreId = "pop_rocks", family = "explosive", skinFactor = 1.75 },
	{ oreId = "toffee_shard", family = "drill", skinFactor = 2.25 },
	{ oreId = "nougat", family = "pickaxe", skinFactor = 1.5 },
	{ oreId = "rock_candy", family = "hammer", skinFactor = 2.0 },
	{ oreId = "milk_chocolate", family = "drill", skinFactor = 2.5 },
	{ oreId = "candy_apple", family = "explosive", skinFactor = 1.75 },
	{ oreId = "white_chocolate", family = "hammer", skinFactor = 2.25 },
	{ oreId = "sugar_skull", family = "pickaxe", skinFactor = 1.5 },
	{ oreId = "chocolate_skull", family = "explosive", skinFactor = 2.0 },
	{ oreId = "jawbreaker", family = "drill", skinFactor = 2.5 },
}

-- The free pick a Crypt claim hands over: the first tool, the Candy Corn Pick.
MineCandyTools.STARTER_ID = "hallow_candy_corn_pick"

function MineCandyTools.toolIdFor(oreId, family)
	return ("hallow_%s_%s"):format(tostring(oreId), string.lower(MineCandyTools.NOUN[family] or "pick"))
end

MineCandyTools.TOOLS = {}
local BY_ID = {}
local BY_ORE = {}

for rank, spec in ipairs(MineCandyTools.TOOL_TABLE) do
	local ore = Config.candyOreById(spec.oreId)
	local family = spec.family
	local frame = OreTools.frameStats(family, MineCandyTools.FRAME_TIER[family] or 41)
	local tuneLayer = MineCandyTools.TUNE_FIRST + MineCandyTools.TUNE_STEP * (rank - 1)
	local row = {
		id = MineCandyTools.toolIdFor(spec.oreId, family),
		name = ("%s %s"):format(ore and ore.name or spec.oreId, MineCandyTools.NOUN[family] or "Pick"),
		oreId = spec.oreId,
		oreName = ore and ore.name or spec.oreId,
		rank = rank,
		band = ore and ore.band or "Common",
		bandIndex = ore and ore.bandIndex or 1,
		-- Kept for the screens that sort and colour by `tier` and `rarityId`.
		tier = rank,
		rarityId = ore and ore.band or "Common",
		family = family,
		craft = math.max(1, math.floor(tonumber(MineCandyTools.CRAFT_BY_BAND[ore and ore.band or "Common"]) or 10)),
		skinFactor = tonumber(spec.skinFactor) or 2,
		tuneLayer = tuneLayer,
		-- The forged frame's mechanics. `false` there means absent, and
		-- frameStats already turned it into nil.
		rate = frame.rate or 2.6,
		cells = frame.cells or 1,
		radius = frame.radius or 0,
		shape = frame.shape or "melee",
		width = frame.width,
		axis = frame.axis,
		turn = frame.turn,
		bombs = frame.bombs,
		pattern = frame.pattern,
		cooldown = frame.cooldown,
		depth = frame.depth,
		sink = frame.sink,
		auto = frame.auto,
		windSec = frame.windSec,
		zoneId = MineCandyTools.ZONE_ID,
		--[[
			A Crypt tool, wherever it is. NOT `eventOnly`: that is Event
			Horizon's matter lock, and the Crypt's rock is ordinary HP. Which
			rock a Halloween tool may spend is MineSpaceMatter's event-only rule,
			keyed on the row MineCryptRules builds (`eventMine`).
		]]
		cryptTool = true,
		seasonalOnly = true,
		eventOnly = false,
		-- No icon or model yet (tools/cursor/tasks/crypt-icons.md): empty
		-- means "fall back".
		icon = "",
		warning = MineCandyTools.WARNING,
	}
	table.insert(MineCandyTools.TOOLS, row)
	BY_ID[row.id] = row
	BY_ORE[row.oreId] = row
end

function MineCandyTools.all()
	return table.clone(MineCandyTools.TOOLS)
end

function MineCandyTools.byId(id)
	return BY_ID[tostring(id or "")]
end

-- The tool a candy ore crafts, or nil.
function MineCandyTools.forOre(oreId)
	return BY_ORE[tostring(oreId or "")]
end

local function prestigeOf(k)
	return math.clamp(math.floor(tonumber(k) or 0), 0, MineCandyTools.PRESTIGE_MAX)
end
MineCandyTools.clampPrestige = prestigeOf

--------------------------------------------------------------------------------
-- COSTS
--------------------------------------------------------------------------------

-- Ore items prestige `k` (1..10) costs: the step FROM k-1 TO k. nil past 10.
function MineCandyTools.prestigeCost(def, k)
	k = math.floor(tonumber(k) or 0)
	if type(def) ~= "table" or k < 1 or k > MineCandyTools.PRESTIGE_MAX then
		return nil
	end
	local c = MineCandyTools.PRESTIGE_COST
	return math.max(1, math.ceil(def.craft * c.BASE * c.GROWTH ^ (k - 1) - 1e-9))
end

-- Ore items a tool at prestige `k` has cost in all: the craft and every step.
function MineCandyTools.totalSpent(def, k)
	if type(def) ~= "table" then
		return 0
	end
	local n = def.craft
	for i = 1, prestigeOf(k) do
		n += MineCandyTools.prestigeCost(def, i) or 0
	end
	return n
end

--[[
	What scrapping pays, in candy: SCRAP_SHARE of the candy value of every ore
	item spent on it (owner: "half, in candy value, no ores back"). `spent` is
	the tool's own ledger (MineCrypt records what each copy really cost, so a
	retune never changes a refund); without one, the table's cost at its
	prestige. The free starter cost nothing to craft, so its craft is not
	refunded -- only prestiges paid for.
]]
function MineCandyTools.scrapCandy(def, prestige, spent)
	if type(def) ~= "table" then
		return 0
	end
	local value = Config.candyOreValue(def.oreId)
	local items
	if type(spent) == "table" then
		items = 0
		for oreId, n in pairs(spent) do
			items += math.max(0, math.floor(tonumber(n) or 0)) * (oreId == def.oreId and 1 or 0)
		end
	else
		items = MineCandyTools.totalSpent(def, prestige)
	end
	return math.floor(items * value * MineCandyTools.SCRAP_SHARE)
end

--------------------------------------------------------------------------------
-- POWER
--------------------------------------------------------------------------------

-- The multiplier prestige `k` puts on a tool's base power: 1 at P0, 4 at P10.
function MineCandyTools.prestigeMult(k)
	return 1 + MineCandyTools.PRESTIGE_POWER * prestigeOf(k)
end

--[[
	IN THE CRYPT. A Normal pick of base power takes PICK_HITS hits at the
	tool's tuneLayer (MineConfig.cryptRockHp, so a retune of the rock moves the
	tools with it); other families scale by the forged tools' family balance
	(MineOreTools.FAMILY_POWER: hammer 3.7, explosive 4), so the hammer is still
	the best single block and the cracker the best area, as everywhere else.
	`dig` is Event Digging from the worn Halloween charm, as a fraction.
]]
function MineCandyTools.basePower(def)
	if type(def) ~= "table" then
		return 1
	end
	local hp = Config.cryptRockHp(def.tuneLayer)
	return hp / MineCandyTools.PICK_HITS * OreTools.familyPower(def.family)
end

function MineCandyTools.cryptPower(def, prestige, dig)
	return math.max(1, math.floor(MineCandyTools.basePower(def) * MineCandyTools.prestigeMult(prestige)
		* (1 + math.max(0, tonumber(dig) or 0)) + 0.5))
end

--[[
	THE MAIN WORLD: the forged tool this one hits like (WORLD, above). Returns
	the ore tier, the level and that ore's row.
]]
function MineCandyTools.worldEquivalent(def, prestige)
	local W = MineCandyTools.WORLD
	local k = prestigeOf(prestige)
	local n = #MineCandyTools.TOOLS
	local span = (n - 1) + MineCandyTools.PRESTIGE_MAX * W.PRESTIGE_RANKS
	local x = (((def and def.rank) or 1) - 1 + k * W.PRESTIGE_RANKS) / math.max(1e-9, span)
	x = math.clamp(x, 0, 1)
	local top = #(Config.ORES or {})
	local tier = math.clamp(math.floor(W.LOW_TIER + (top - W.LOW_TIER) * x ^ W.CURVE + 0.5), 1, top)
	local maxLv = math.max(1, math.floor(tonumber(Config.TOOL_MAX_LEVEL) or 30))
	local level = 1 + math.floor((maxLv - 1) * k / MineCandyTools.PRESTIGE_MAX + 0.5)
	return tier, level, (Config.ORES or {})[tier]
end

function MineCandyTools.worldPower(def, prestige, dig)
	local tier, level = MineCandyTools.worldEquivalent(def, prestige)
	local base = OreTools.hitPower({ familyId = (def and def.family) or "pickaxe", tier = tier, level = level }, 1)
	return math.max(1, math.floor(base * (1 + math.max(0, tonumber(dig) or 0)) + 0.5))
end

return MineCandyTools
