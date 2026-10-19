--[[
	MineCandyTools -- the Candy Crypt's tools. THE TABLE, not a shop.

	Owner, 2026-10-19 (wiki/open-questions.md §0e, "The Candy Crypt,
	redesigned"):
	  * Normal tools do not work in events. In the Crypt only these do.
	  * Claiming the Crypt gives a free starter pick (STARTER_ID).
	  * Crypt tools come from Crypt CHESTS and Trick-or-Treat CASES. The
	    candy-tool shop is gone: no row has a price, and nothing sells them.
	  * Three identical tools merge into the next variant, Golden -> Prism ->
	    Rainbow, at the pets' multipliers (MineCryptRules owns that rule).
	  * They are yours to keep. When the Crypt closes they also work in the
	    main world, weaker (`worldOreTier`, read by MineCryptRules.worldRow).

	Before this, these were twelve candy-priced tools tuned to rock that was
	1 HP at the top, and the drills and explosives carried shapes ("bore",
	"blast") the swing code does not know, so they all hit like one pick. Every
	row now takes its swing, footprint and fuse from the forged tools of its
	family (MineOreTools.frameStats at FRAME_TIER) and its power from the
	Crypt's own rock (MineConfig.cryptRockHp), so a Crypt pick IS a pick.

	WHAT A ROW IS. One tier x one family. `power` is the IN-EVENT power of a
	Normal copy before the Halloween charms' Event Digging; MineCryptRules
	turns a row into what the server actually swings (variant, charm, event or
	main world). Every row carries `family`, which skins resolve by.

	EVERY NUMBER HERE IS PROPOSED (2026-10-19): the tiers and their bands,
	PICK_HITS, FRAME_TIER, worldOreTier, the drop chances and the case weights.
]]
local MineCandyTools = {}

local shared = script.Parent
local Config = require(shared:WaitForChild("MineConfig"))
local OreTools = require(shared:WaitForChild("MineOreTools"))

MineCandyTools.ZONE_ID = "hallow"

-- The tool card's line. The first-entry pop-up's text is MineCryptRules.NOTICE.
MineCandyTools.WARNING =
	"Event tool: digs the Candy Crypt now. It is yours to keep: when the event "
	.. "ends it also works in the main world, weaker."

MineCandyTools.FAMILIES = { "pickaxe", "hammer", "drill", "explosive" }
local NOUN = { pickaxe = "Pick", hammer = "Mallet", drill = "Auger", explosive = "Cracker" }

--[[
	HOW HARD A TIER HITS. A tier is tuned so a PICK takes PICK_HITS hits on the
	first layer of its band's last section (`throughSection`): comfortable
	through its own band, struggling at the next, which is what makes the next
	tier worth finding. The same 12 the old candy pick used.

	The other families do not get their own hit counts any more: they take the
	forged tools' family balance (MineOreTools.FAMILY_POWER: hammer 3.7, drill 1,
	explosive 4, with the frames' rates), so the hammer is still the best single
	block and the explosive still the best area, exactly as everywhere else.
]]
MineCandyTools.PICK_HITS = 12

--[[
	Whose frame each family borrows: the forged tool of this ore tier. Picked
	for the family's signature shape in a 3x3 pit -- a pick (rate 2.8), a hammer
	that sinks two (rate 1.3), a 3x3 aimed drill (rate 2.5, instant), and a
	radius-1 sphere charge on a 1.15 s fuse. The same frame at every Crypt tier,
	so only the power changes as you climb.
]]
MineCandyTools.FRAME_TIER = { pickaxe = 41, hammer = 41, drill = 41, explosive = 36 }

--[[
	THE THREE TIERS, one per 40-layer band of the 120-layer Crypt.

	  tier  band       tuned on   pick power   starter pick here
	  1     1-40       layer 31   ~768         1 hit at the top, 12 at L31
	  2     41-80      layer 71   ~33,900
	  3     81-120     layer 111  ~1.49M       ~28 hits at the bottom (L120)

	A Rainbow copy (x5.5) reaches about 18 layers deeper than a Normal one, so
	merging moves you down roughly half a band.

	`worldOreTier`: the forged ore whose level-1 tool this one equals in the
	MAIN world once the Crypt has closed -- the last ore of zone 1, 3 and 5,
	two zones below the hardness each band starts at in the Crypt (zone 3,
	~5.4, ~7.7). Events pay better than the main world (owner), so a Crypt
	tool there is a fresh forged tool of a modest ore, never better than one a
	player has levelled.
]]
MineCandyTools.TIERS = {
	{ key = "corn", name = "Candy Corn", throughSection = 4, worldOreTier = 8, rarityId = "Rare" },
	{ key = "toffee", name = "Toffee", throughSection = 8, worldOreTier = 24, rarityId = "Epic" },
	{ key = "jawbreaker", name = "Jawbreaker", throughSection = 12, worldOreTier = 41, rarityId = "Legendary" },
}

-- The free pick a Crypt claim hands over.
MineCandyTools.STARTER_ID = "candy_corn_pickaxe"

--[[
	DROPS (PROPOSED 2026-10-19).

	CHEST_TOOL_CHANCE: a Crypt chest pays a Crypt tool this often (x chest luck,
	capped). With about ten chests in the Crypt that is three tools a full dig.
	The tool is from the BAND THE CHEST IS IN (deeper chest, better tool), one
	tier better CHEST_TIER_UP_CHANCE of the time.

	CASE_TIER_WEIGHTS: which tier a Trick-or-Treat case's tool is (the case is
	bought anywhere, so it is not banded by depth). Mostly the starter band.
]]
MineCandyTools.CHEST_TOOL_CHANCE = 0.30
MineCandyTools.CHEST_TIER_UP_CHANCE = 0.15
MineCandyTools.CHEST_LUCK_CAP = 3
MineCandyTools.CASE_TIER_WEIGHTS = { 60, 30, 10 }

local function sectionFirstLayer(section)
	local span = Config.CANDY_SECTION_SPAN or 10
	return (section - 1) * span + 1
end

MineCandyTools.TOOLS = { pickaxe = {}, hammer = {}, drill = {}, explosive = {} }
local BY_ID = {}

for ti, tier in ipairs(MineCandyTools.TIERS) do
	local refLayer = sectionFirstLayer(tier.throughSection)
	local refHp = Config.cryptRockHp(refLayer)
	local pickPower = math.max(1, math.floor(refHp / MineCandyTools.PICK_HITS + 0.5))
	for _, family in ipairs(MineCandyTools.FAMILIES) do
		local frame = OreTools.frameStats(family, MineCandyTools.FRAME_TIER[family])
		local power = math.max(1, math.floor(pickPower * OreTools.familyPower(family) + 0.5))
		local row = {
			id = ("candy_%s_%s"):format(tier.key, family),
			name = ("%s %s"):format(tier.name, NOUN[family]),
			family = family,
			tier = ti,
			tierKey = tier.key,
			power = power,
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
			-- A Crypt tool, wherever it is. NOT `eventOnly`: that is Event
			-- Horizon's matter lock, and the Crypt's rock is ordinary HP. Which
			-- rock a Crypt tool may spend is MineSpaceMatter's event-only rule,
			-- keyed on the row MineCryptRules builds (`eventMine`).
			seasonalOnly = true,
			eventOnly = false,
			refLayer = refLayer,
			refHp = refHp,
			throughSection = tier.throughSection,
			worldOreTier = tier.worldOreTier,
			rarityId = tier.rarityId,
			-- No icon or model yet (a Cursor job): empty means "fall back".
			icon = "",
			warning = MineCandyTools.WARNING,
			blurb = ("About %d hits a block at layer %d. %s"):format(
				math.max(1, math.floor(refHp / math.max(1, power) + 0.5)), refLayer, MineCandyTools.WARNING),
		}
		table.insert(MineCandyTools.TOOLS[family], row)
		BY_ID[row.id] = row
	end
end

function MineCandyTools.all()
	local out = {}
	for _, family in ipairs(MineCandyTools.FAMILIES) do
		for _, t in ipairs(MineCandyTools.TOOLS[family]) do
			table.insert(out, t)
		end
	end
	return out
end

function MineCandyTools.byId(id)
	return BY_ID[tostring(id or "")]
end

-- The row for a tier and family, or nil.
function MineCandyTools.pick(tier, family)
	local list = MineCandyTools.TOOLS[tostring(family or "")]
	return list and list[math.floor(tonumber(tier) or 0)] or nil
end

-- The tier band a Crypt layer is in: 1 for layers 1-40, 2 for 41-80, 3 below.
function MineCandyTools.tierForLayer(layer)
	local span = Config.CANDY_SECTION_SPAN or 10
	local section = math.max(1, math.floor(((tonumber(layer) or 1) - 1) / span) + 1)
	for ti, tier in ipairs(MineCandyTools.TIERS) do
		if section <= tier.throughSection then
			return ti
		end
	end
	return #MineCandyTools.TIERS
end

local function num(rng)
	return (rng and rng.NextNumber) and rng:NextNumber() or math.random()
end

local function rollFamily(rng)
	local fams = MineCandyTools.FAMILIES
	return fams[math.clamp(math.floor(num(rng) * #fams) + 1, 1, #fams)]
end

-- A Trick-or-Treat case's tool: a tier by CASE_TIER_WEIGHTS, any family.
function MineCandyTools.rollCaseTool(rng)
	local w = MineCandyTools.CASE_TIER_WEIGHTS
	local tot = 0
	for _, v in ipairs(w) do
		tot += v
	end
	local pick, tier = num(rng) * tot, #w
	for i, v in ipairs(w) do
		pick -= v
		if pick <= 0 then
			tier = i
			break
		end
	end
	return MineCandyTools.pick(tier, rollFamily(rng))
end

-- The chance a Crypt chest pays a tool, after chest luck (capped).
function MineCandyTools.chestToolChance(chestLuck)
	local luck = math.clamp(tonumber(chestLuck) or 1, 1, MineCandyTools.CHEST_LUCK_CAP)
	return math.min(0.95, MineCandyTools.CHEST_TOOL_CHANCE * luck)
end

-- A Crypt chest's tool, or nil when the chest pays none.
function MineCandyTools.rollChestTool(layer, rng, chestLuck)
	if num(rng) >= MineCandyTools.chestToolChance(chestLuck) then
		return nil
	end
	local tier = MineCandyTools.tierForLayer(layer)
	if tier < #MineCandyTools.TIERS and num(rng) < MineCandyTools.CHEST_TIER_UP_CHANCE then
		tier += 1
	end
	return MineCandyTools.pick(tier, rollFamily(rng))
end

--[[
	The chest odds at a layer, for an odds sheet: the chance of a tool at all
	and the chance of each tier, family spread evenly. Same rule as
	rollChestTool, written as numbers.
]]
function MineCandyTools.chestOdds(layer, chestLuck)
	local p = MineCandyTools.chestToolChance(chestLuck)
	local tier = MineCandyTools.tierForLayer(layer)
	local out = { chance = p, tiers = {} }
	if tier < #MineCandyTools.TIERS then
		out.tiers[tier] = p * (1 - MineCandyTools.CHEST_TIER_UP_CHANCE)
		out.tiers[tier + 1] = p * MineCandyTools.CHEST_TIER_UP_CHANCE
	else
		out.tiers[tier] = p
	end
	return out
end

return MineCandyTools
