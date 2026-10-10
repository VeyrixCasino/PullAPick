--[[
	MineCandyTools -- the Candy Crypt's shelf. Tools bought with CANDY.

	Owner, 2026-10-10: "You can buy halloween tools for candy too, but warn the
	player that the tools are extremely weak and only suited for seasonal events
	(like christmas, easter, valentines day shit like that)".

	So the warning is not a nicety here, it is the product: a player spending a
	Halloween's worth of candy on a tool that is useless in a real mine has been
	mis-sold. `MineCandyTools.WARNING` is the line the shop MUST show on the
	shelf and on every row, and `seasonalOnly` is the flag anything else can
	read.

	WHY THEY ARE WEAK, in numbers rather than adjectives. These are tuned to the
	Candy Crypt's own HP curve, which starts at 1 and climbs 3x per 10-layer
	section (MineConfig.blockHp, zone "hallow"). The deepest candy tool lands
	around 14,000 breaking power. An ordinary zone-10 tool is in the tens of
	millions, because Primordium's rock is. A candy tool is not a cheap endgame
	tool; it is a tool for rock that is made of candy.

	They are NOT event-locked the way Horizon tools are. Event Horizon rock is a
	separate matter pool and a meadow tool cannot spend it; the Crypt has no
	such pool, because the owner asked for surface tools to work here. A candy
	tool is therefore usable anywhere -- it is simply bad everywhere else, which
	is what the warning says.

	EVERY NUMBER HERE IS PROPOSED (2026-10-10): the hit counts, the prices, the
	tier bands and the rates.
]]
local MineCandyTools = {}

local Config = require(script.Parent:WaitForChild("MineConfig"))

MineCandyTools.ZONE_ID = "hallow"
MineCandyTools.CURRENCY = "candy"

MineCandyTools.WARNING =
	"These are seasonal tools. They are extremely weak outside event mines — "
	.. "fine in the Candy Crypt and the holiday mines to come, poor value anywhere else."

-- Hits a tool of its band should take on the rock it is sold for. Higher is
-- weaker. A pick swings fastest and so is allowed the most hits per block.
local HITS = { pickaxe = 12, hammer = 7, drill = 26, explosive = 40 }
local RATE = { pickaxe = 1.8, hammer = 1.1, drill = 1.2, explosive = 0.7 }
local CELLS = { pickaxe = 1, hammer = 1, drill = 9, explosive = 27 }
local SHAPE = { pickaxe = "melee", hammer = "melee", drill = "bore", explosive = "blast" }

--[[
	Three tiers, each sold against the rock at the BOTTOM of its band, so a tool
	is comfortable through its band and starts to struggle at the next -- which
	is what makes the next one worth buying rather than a formality.
]]
local TIERS = {
	{ key = "corn", name = "Candy Corn", throughSection = 4 },
	{ key = "toffee", name = "Toffee", throughSection = 8 },
	{ key = "jawbreaker", name = "Jawbreaker", throughSection = 12 },
}

local NOUN = { pickaxe = "Pick", hammer = "Mallet", drill = "Auger", explosive = "Cracker" }

local function sectionHp(section)
	-- The first layer of that section, through the Crypt's own curve.
	local span = Config.CANDY_SECTION_SPAN or 10
	local layer = (section - 1) * span + 1
	return Config.blockHp("dirt", "hallow", layer)
end

MineCandyTools.TOOLS = { pickaxe = {}, hammer = {}, drill = {}, explosive = {} }

for ti, tier in ipairs(TIERS) do
	local hp = sectionHp(tier.throughSection)
	for _, family in ipairs({ "pickaxe", "hammer", "drill", "explosive" }) do
		local power = math.max(1, math.floor(hp / HITS[family] + 0.5))
		--[[
			Price in candy, from what the band actually PAYS rather than from
			the tool's power. A band's blocks drop candy on the same 3x curve,
			so pricing off the rock keeps a tool at roughly a fixed number of
			blocks' worth however the curve is retuned -- change the curve and
			the shelf follows instead of drifting out of step with it.
		]]
		local price = math.max(5, math.floor(hp * 0.6 + 0.5))
		table.insert(MineCandyTools.TOOLS[family], {
			id = ("candy_%s_%s"):format(tier.key, family),
			name = ("%s %s"):format(tier.name, NOUN[family]),
			family = family,
			tier = ti,
			power = power,
			rate = RATE[family],
			radius = (family == "explosive") and 2 or 0,
			cells = CELLS[family],
			shape = SHAPE[family],
			currency = MineCandyTools.CURRENCY,
			price = price,
			zoneId = "hallow",
			seasonalOnly = true,
			-- Deliberately NOT eventOnly: that is the Event Horizon matter lock,
			-- and the Crypt has no matter pool. These work anywhere, badly.
			eventOnly = false,
			refHp = hp,
			throughSection = tier.throughSection,
			warning = MineCandyTools.WARNING,
			blurb = ("About %d hits on section %d rock. %s"):format(
				math.max(1, math.floor(hp / power)), tier.throughSection, MineCandyTools.WARNING),
		})
	end
end

function MineCandyTools.all()
	local out = {}
	for _, family in ipairs({ "pickaxe", "hammer", "drill", "explosive" }) do
		for _, t in ipairs(MineCandyTools.TOOLS[family]) do
			table.insert(out, t)
		end
	end
	return out
end

function MineCandyTools.byId(id)
	for _, t in ipairs(MineCandyTools.all()) do
		if t.id == tostring(id or "") then
			return t
		end
	end
	return nil
end

return MineCandyTools
