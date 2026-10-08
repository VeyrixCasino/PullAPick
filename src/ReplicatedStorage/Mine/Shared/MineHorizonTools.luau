-- MineHorizonTools: Event Horizon shop. Twenty tools, one per dirt section.
-- Space rock uses that section's dirt HP. A later tool still erases earlier dirt.
-- A pick is about 16 hits on its own section, a bore about 40 per cell,
-- a sinkcharge about 70 per cell. Pay is Space coins. The Loam pick is free.

local MineHorizonTools = {}

local Depth = require(script.Parent:WaitForChild("MineDepth"))

local EH_ZI = 11
local PICK_HITS = 16
local BORE_HITS = 40
local CHARGE_HITS = 70
local MINUTES = 4

local function sig2(n)
	n = math.max(0, math.floor(n + 0.5))
	if n <= 0 then
		return 0
	end
	local exp = math.floor(math.log10(n))
	local f = 10 ^ math.max(0, exp - 1)
	return math.floor(n / f + 0.5) * f
end

MineHorizonTools.ZONE_ID = "bigbang"
MineHorizonTools.ZONE_INDEX = EH_ZI
MineHorizonTools.TOOLS = { pickaxe = {}, drill = {}, explosive = {} }

local prevDps = nil
local prevPrice = 0
local function priceFromPrev()
	if not prevDps then
		prevPrice = 0
		return 0
	end
	local price = sig2(prevDps * MINUTES * 60)
	if price < prevPrice then
		price = sig2(math.max(prevPrice + 1, prevPrice * 1.35))
		if price < prevPrice then
			price = prevPrice
		end
	end
	prevPrice = price
	return price
end

--[[
	THE 10,000x PASS, TOOL SIDE. Owner, 2026-10-08: "10 thousand x in ONLY the
	event mine".

	Event Horizon blocks scale through the depth curve at zone index 11
	(MineDepth.hpScaleFor), and this file prices every Horizon tool off the
	AUTHORED SECTIONS dirtHp -- a different table. Those are the two halves of
	a closed loop: zone 11 blocks are only ever broken by these tools, which
	are eventOnly and minZone 11, so as long as both move by the same factor
	nothing a player experiences changes and no number outside the event moves.

	Scaling the reference HP here rather than the power below means the hit
	counts underneath -- PICK_HITS 16, BORE_HITS 40, CHARGE_HITS 70 -- stay
	exactly what they say they are, and the space-coin prices derived from dps
	come along on their own, which is the "with whatever custom currency they
	are using" half of the original ask.
]]
local EH_SCALE = (Depth.hpScaleFor and Depth.hpScaleFor(EH_ZI)) or 1

for _, sec in ipairs(Depth.SECTIONS) do
	local hp = math.max(1, math.floor((tonumber(sec.dirtHp) or 1) * EH_SCALE))
	local band = sec.band
	if band == "shallow" then
		local power = math.max(1, math.floor(hp / PICK_HITS + 0.5))
		local rate = 1.8
		local price = priceFromPrev()
		prevDps = power * rate
		local id = (sec.id == "loam") and "eh_shallow_pick" or ("eh_" .. sec.id .. "_pick")
		table.insert(MineHorizonTools.TOOLS.pickaxe, {
			id = id,
			name = "Horizon " .. sec.name .. " Pick",
			family = "pickaxe",
			tier = #MineHorizonTools.TOOLS.pickaxe + 1,
			power = power,
			rate = rate,
			radius = 0,
			cells = 1,
			shape = "melee",
			eventOnly = true,
			minDepth = math.floor(((sec.layers and sec.layers[1] or 1) - 1) / 500) * 500,
			currency = "space",
			price = price,
			minZone = EH_ZI,
			zoneId = "bigbang",
			band = "shallow",
			sectionId = sec.id,
			refHp = hp,
			blurb = string.format("Too heavy in meadow gravity. About %d hits on %s.", math.max(1, math.floor(hp / power)), sec.name),
		})
	elseif band == "mid" then
		local power = math.max(1, math.floor(hp / BORE_HITS + 0.5))
		local rate = 1.2
		local price = priceFromPrev()
		prevDps = power * rate
		table.insert(MineHorizonTools.TOOLS.drill, {
			id = "eh_" .. sec.id .. "_bore",
			name = "Singularity " .. sec.name .. " Bore",
			family = "drill",
			tier = #MineHorizonTools.TOOLS.drill + 1,
			power = power,
			rate = rate,
			width = 5,
			cells = 25,
			shape = "down",
			axis = "down",
			turn = 1.4,
			radius = 0,
			eventOnly = true,
			minDepth = math.floor(((sec.layers and sec.layers[1] or 1) - 1) / 500) * 500,
			currency = "space",
			price = price,
			minZone = EH_ZI,
			zoneId = "bigbang",
			band = "mid",
			sectionId = sec.id,
			refHp = hp,
			blurb = string.format("Too heavy in meadow gravity. 5x5 bore, about %d hits a cell on %s.", math.max(1, math.floor(hp / power)), sec.name),
		})
	else
		local power = math.max(1, math.floor(hp / CHARGE_HITS + 0.5))
		local rate = 0.55
		local price = priceFromPrev()
		prevDps = power * rate
		local bi = #MineHorizonTools.TOOLS.explosive + 1
		table.insert(MineHorizonTools.TOOLS.explosive, {
			id = "eh_" .. sec.id .. "_charge",
			name = "Event " .. sec.name .. " Sinkcharge",
			family = "explosive",
			tier = bi,
			power = power,
			bombs = 1,
			pattern = "shaftdown",
			width = 3,
			depth = 8,
			cells = 72,
			rate = rate,
			cooldown = 3.4 + bi * 0.55,
			eventOnly = true,
			minDepth = math.floor(((sec.layers and sec.layers[1] or 1) - 1) / 500) * 500,
			currency = "space",
			price = price,
			minZone = EH_ZI,
			zoneId = "bigbang",
			band = "deep",
			sectionId = sec.id,
			refHp = hp,
			blurb = string.format("Too heavy in meadow gravity. About %d hits a cell on %s.", math.max(1, math.floor(hp / power)), sec.name),
		})
	end
end

function MineHorizonTools.all()
	local out = {}
	for _, fam in ipairs({ "pickaxe", "drill", "explosive" }) do
		for _, t in ipairs(MineHorizonTools.TOOLS[fam]) do
			table.insert(out, t)
		end
	end
	return out
end

function MineHorizonTools.tool(familyId, toolId)
	for _, t in ipairs(MineHorizonTools.TOOLS[familyId] or {}) do
		if t.id == toolId then return t end
	end
	return nil
end

function MineHorizonTools.byId(id)
	for _, t in ipairs(MineHorizonTools.all()) do
		if t.id == id then return t end
	end
	return nil
end

function MineHorizonTools.shopRows(family)
	local out = {}
	for _, t in ipairs(MineHorizonTools.TOOLS[family] or {}) do
		table.insert(out, t)
	end
	return out
end

function MineHorizonTools.forBand(band)
	band = (band == "surface" or band == "surface_band" or band == "" or band == nil) and "shallow" or band
	if band == "deeprock" then band = "mid" end
	if band == "shadowzone" then band = "deep" end
	local out = {}
	for _, t in ipairs(MineHorizonTools.all()) do
		if t.band == band then
			table.insert(out, t)
		end
	end
	return out
end

--[[
	SHARED MODULE -- it cannot reach into ServerStorage.

	This block is written by the tool-rename pass. Its original form was
	require(game.ServerStorage:WaitForChild("ApplyToolRename")), and
	ServerStorage never replicates: on the CLIENT that WaitForChild never
	returns, the require never finishes, and every script that required
	this module -- MineClient included -- stopped dead on that line. No
	HUD, no panels, nothing. The server was unaffected, which is what made
	it look like a UI bug instead of a require that never came back.

	Same rename, same effect, resolved from the copy already sitting in
	Shared. FindFirstChild does not yield, so the worst case is the rename
	is skipped -- not the game failing to start.

	IF THE RENAME PASS REWRITES THIS FILE IT WILL PUT THE OLD LINE BACK.
	The generator needs to emit this form too.
]]
do
	local src = script.Parent:FindFirstChild("ApplyToolRename")
		or game:GetService("ServerStorage"):FindFirstChild("ApplyToolRename")
	if src then
		pcall(function()
			require(src).apply(MineHorizonTools)
		end)
	end
end

--[[
	STAMP EACH ROW WITH ITS OWN LADDER LENGTH.

	`tier` here is per FAMILY, not global -- it is assigned as
	`#TOOLS.<family> + 1` as each row is built -- and the three families are
	nothing like the same length: 12 pickaxes, 38 drills, 88 explosives.

	MineBreaking.eventStrength spreads a tool's tier across the event's strength
	range, so it needs to know how many rungs that tool's ladder has. Without
	this it has to assume one number for all three, and whichever number it
	picks is wrong for the other two: at 20, every drill past tier 20 and every
	explosive past tier 20 clamps to the same strength, so two thirds of the
	explosive ladder would be identical.

	Stamped on the data rather than looked up from MineBreaking, so the module
	that owns the ladder owns its length and MineBreaking needs no dependency on
	this file. Done after the rename pass because that pass may rebuild rows.
]]
for _, fam in ipairs({ "pickaxe", "drill", "explosive" }) do
	local list = MineHorizonTools.TOOLS and MineHorizonTools.TOOLS[fam]
	if type(list) == "table" then
		for _, row in ipairs(list) do
			row.rungs = #list
		end
	end
end

return MineHorizonTools
