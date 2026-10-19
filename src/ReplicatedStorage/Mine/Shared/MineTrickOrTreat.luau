--[[
	MineTrickOrTreat -- the Candy Crypt's case, bought with candy.

	Owner, 2026-10-10: "Collect some and you can trade it in for Trick or Treat
	cases and pull seasonal packs, skin cases, hat cases, Extremely rare
	halloween bucket."

	Owner, 2026-10-19 (wiki/open-questions.md §0e): tools 85%, skin case 5%,
	hat 7%, Halloween pack 2.9%, bucket 0.1%, and NO candy back. The case is
	now the main source of Crypt tools (MineCandyTools), with Crypt chests.

	WHY THIS IS NOT A MineCases CASE. A MineCases case holds PACKS and nothing
	else -- open one and packs land in your bag. This one pays five different
	KINDS of thing, so it is its own roll. It still behaves like a case
	everywhere it matters: one id, bought once, opened once, and every outcome
	is a thing the game already knows how to grant.

	WHAT IT PAYS, and where each comes from (MineCrypt grants it):

	  tool      a Crypt tool (MineCandyTools.rollCaseTool), a Normal copy
	  skincase  an ORE CASE in the bag (`<ore>_ore_case`, the same row a broken
	            ore block drops), which the player opens for a skin or that
	            ore's charm. It used to roll a temperament on the spot; the
	            owner's "skin case" is a case you open, not a skin.
	  hat       a head-slot gear piece, MineGear.rollPiece(id, rng, "head")
	  pack      the Halloween 2026 Pack, IF it is registered -- see PACK_ID
	  bucket    the Trick-or-Treat Bucket (MineBags), the chase

	THE PACK SLOT IS CONDITIONAL ON PURPOSE. `resolvedPack()` looks the id up at
	roll time and the weight table drops the slot when it is missing, folding
	its chance into the hat slot, so the case never silently pays nothing.

	The weights are the owner's. The price, the case's tool tiers
	(MineCandyTools.CASE_TIER_WEIGHTS) and the ore-case range are PROPOSED.
]]
local MineTrickOrTreat = {}

MineTrickOrTreat.CASE_ID = "trick_or_treat_case"
MineTrickOrTreat.NAME = "Trick-or-Treat Case"
MineTrickOrTreat.CURRENCY = "candy"

--[[
	Priced off the candy a mid-depth section pays, so the case costs roughly a
	section's work rather than a number picked in a vacuum. Kept at 2,500 on
	2026-10-19 (candy went 3x the same day, so the case got cheaper in work).
]]
MineTrickOrTreat.PRICE = 2500

-- The pack this case wants to pay. Not required to exist.
MineTrickOrTreat.PACK_ID = "halloween_2026"

--[[
	Weights, not percentages, so a missing slot can be removed without the rest
	needing to be renormalised by hand. They sum to 1,000, so each is the
	owner's percentage times ten: 85 / 5 / 7 / 2.9 / 0.1.
]]
MineTrickOrTreat.WEIGHTS = {
	tool = 850,
	skincase = 50,
	hat = 70,
	pack = 29,
	bucket = 1,
}

-- Fixed display and roll order.
MineTrickOrTreat.ORDER = { "tool", "skincase", "hat", "pack", "bucket" }

MineTrickOrTreat.LABEL = {
	tool = "A Crypt tool",
	skincase = "A skin case",
	hat = "A hat",
	pack = "A Halloween 2026 Pack",
	bucket = "The Trick-or-Treat Bucket",
}

--[[
	The skin case is an ore case of an ore in this tier range, picked evenly.
	PROPOSED (2026-10-19): ore tiers 10-40, the middle of the lucky blocks'
	ranges -- a mid-game ore, so its charm is a real one without being a deep
	ore's.
]]
MineTrickOrTreat.SKIN_CASE_ORE_TIERS = { 10, 40 }

--[[
	Is the seasonal pack registered yet? Looked up lazily and defensively:
	MinePackConfig requires half the pack system, and this module is required by
	the shop, so a hard require at load would be a cycle waiting to happen.
]]
function MineTrickOrTreat.resolvedPack()
	local ok, Packs = pcall(function()
		return require(script.Parent:WaitForChild("MinePackConfig"))
	end)
	if not ok or type(Packs) ~= "table" then
		return nil
	end
	local byId = Packs.PACK_BY_ID
	if type(byId) ~= "table" then
		return nil
	end
	return byId[MineTrickOrTreat.PACK_ID] and MineTrickOrTreat.PACK_ID or nil
end

-- The live weight table: the pack slot is dropped, and its weight handed to
-- hats, whenever no seasonal pack is registered.
function MineTrickOrTreat.weights(packPresent)
	local w = {}
	for k, v in pairs(MineTrickOrTreat.WEIGHTS) do
		w[k] = v
	end
	if packPresent == nil then
		packPresent = MineTrickOrTreat.resolvedPack() ~= nil
	end
	if not packPresent then
		w.hat = (w.hat or 0) + (w.pack or 0)
		w.pack = nil
	end
	return w
end

--[[
	THE ODDS SHEET: every outcome with its percentage, in ORDER. The case is
	bought with candy, which nothing sells for Robux, but it is still a random
	buy and the sheet costs nothing to show. `packPresent` is optional (the
	client can pass what it knows; the default looks it up).
]]
function MineTrickOrTreat.odds(packPresent)
	local w = MineTrickOrTreat.weights(packPresent)
	local tot = 0
	for _, k in ipairs(MineTrickOrTreat.ORDER) do
		tot += (w[k] or 0)
	end
	local out = {}
	for _, k in ipairs(MineTrickOrTreat.ORDER) do
		if (w[k] or 0) > 0 then
			table.insert(out, {
				kind = k,
				label = MineTrickOrTreat.LABEL[k] or k,
				weight = w[k],
				pct = (tot > 0) and (w[k] / tot * 100) or 0,
			})
		end
	end
	return out
end

--[[
	Roll one open. Returns a plain table the server acts on, never an Instance
	and never a side effect, so the roll can be tested and replayed:

	  { kind = "tool",     id = "candy_corn_pickaxe", tier = 1, family = "pickaxe" }
	  { kind = "skincase", oreTier = 23 }
	  { kind = "hat" }                 -- the server rolls the gear piece
	  { kind = "pack",     id = "halloween_2026" }
	  { kind = "bucket" }
]]
function MineTrickOrTreat.roll(rng)
	local function num()
		return (rng and rng.NextNumber) and rng:NextNumber() or math.random()
	end
	local w = MineTrickOrTreat.weights()
	local tot = 0
	for _, k in ipairs(MineTrickOrTreat.ORDER) do
		tot += (w[k] or 0)
	end
	local chosen = "tool"
	if tot > 0 then
		local pick = num() * tot
		for _, k in ipairs(MineTrickOrTreat.ORDER) do
			pick -= (w[k] or 0)
			if pick <= 0 then
				chosen = k
				break
			end
		end
	end

	if chosen == "tool" then
		local Tools = require(script.Parent:WaitForChild("MineCandyTools"))
		local def = Tools.rollCaseTool(rng)
		if def then
			return { kind = "tool", id = def.id, tier = def.tier, family = def.family }
		end
		return { kind = "hat" }
	elseif chosen == "skincase" then
		local lo = MineTrickOrTreat.SKIN_CASE_ORE_TIERS[1]
		local hi = MineTrickOrTreat.SKIN_CASE_ORE_TIERS[2]
		local t = lo + math.floor(num() * (hi - lo + 1))
		return { kind = "skincase", oreTier = math.clamp(t, lo, hi) }
	elseif chosen == "hat" then
		--[[
			No id, on purpose. A hat in this game is a GEAR PIECE rolled by
			Gear.rollPiece(id, rng, "head") -- not a MineHats id you can name
			here. So the case says "a hat" and the server rolls it the one way
			everything else does.
		]]
		return { kind = "hat" }
	elseif chosen == "pack" then
		local id = MineTrickOrTreat.resolvedPack()
		if not id then
			return { kind = "hat" }
		end
		return { kind = "pack", id = id }
	end
	return { kind = "bucket" }
end

return MineTrickOrTreat
