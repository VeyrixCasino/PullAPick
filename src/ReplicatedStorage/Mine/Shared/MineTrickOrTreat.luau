--[[
	MineTrickOrTreat -- the Candy Crypt's case, bought with candy.

	Owner, 2026-10-10: "Collect some and you can trade it in for Trick or Treat
	cases and pull seasonal packs, skin cases, hat cases, Extremely rare
	halloween bucket."

	WHY THIS IS NOT A MineCases CASE. A MineCases case holds PACKS and nothing
	else -- open one and packs land in your bag. This one has to pay four
	different KINDS of thing (a pack, a hat, a skin, a bag), so it is its own
	roll. It still behaves like a case everywhere it matters: one id, bought
	once, opened once, and every outcome is a thing the game already knows how
	to grant.

	WHAT IT PAYS, and where each pool actually comes from:

	  candy    a partial refund, so a bad open is not a dead open
	  hat      MineHats.DROP_BY_GRADE / FACE_BY_GRADE, the live hat pool
	  skin     a temperament roll -- in this codebase a "skin" IS a temper
	           (wiki: systems/skins-cases-and-temper)
	  pack     the seasonal pack, IF one is registered -- see PACK_ID below
	  bucket   the Trick-or-Treat Bucket (MineBags), the chase

	THE SEASONAL PACK SLOT IS CONDITIONAL ON PURPOSE. The Halloween 2026 Pack
	does not exist yet; it is queued in the rewards pass. Rather than block the
	whole case on it, `resolvedPack()` looks the id up at roll time and the
	weight table drops the slot when it is missing, folding its chance into the
	hat slot. The day that pack is registered the case starts paying it with no
	change here. A case that silently paid nothing for one slot would be worse
	than one that never had the slot.

	EVERY NUMBER HERE IS PROPOSED (2026-10-10): the price, the weights, the
	refund band and the bucket's rarity.
]]
local MineTrickOrTreat = {}

MineTrickOrTreat.CASE_ID = "trick_or_treat_case"
MineTrickOrTreat.NAME = "Trick-or-Treat Case"
MineTrickOrTreat.CURRENCY = "candy"

--[[
	Priced off the candy a mid-depth section actually pays, so the case costs
	roughly a section's work rather than a number picked in a vacuum. Section 6
	candy ore pays 243 x its own base, and a case should be a handful of those.
]]
MineTrickOrTreat.PRICE = 2500

-- The pack this case wants to pay. Not required to exist.
MineTrickOrTreat.PACK_ID = "halloween_2026"

--[[
	Weights, not percentages, so a missing slot can be removed without the rest
	needing to be renormalised by hand.

	The bucket is 1 in 1,000 openings. It is the only permanent thing in the
	mine and the event runs three weeks, so it should be a story rather than a
	milestone -- and because it is a BAG, a player who never sees one has lost
	nothing they needed.
]]
MineTrickOrTreat.WEIGHTS = {
	candy = 520,
	hat = 300,
	skin = 150,
	pack = 29,
	bucket = 1,
}

-- Candy back, as a fraction of the price. A refund that beat the price would
-- make the case a currency printer.
MineTrickOrTreat.REFUND = { lo = 0.15, hi = 0.60 }

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
function MineTrickOrTreat.weights()
	local w = {}
	for k, v in pairs(MineTrickOrTreat.WEIGHTS) do
		w[k] = v
	end
	if not MineTrickOrTreat.resolvedPack() then
		w.hat = (w.hat or 0) + (w.pack or 0)
		w.pack = nil
	end
	return w
end

--[[
	Roll one open. Returns a plain table the server acts on, never an Instance
	and never a side effect, so the roll can be tested and replayed:

	  { kind = "candy",  amount = n }
	  { kind = "hat",    id = "..." }
	  { kind = "skin" }                 -- server runs its own rollTemperament
	  { kind = "pack",   id = "..." }
	  { kind = "bucket" }
]]
function MineTrickOrTreat.roll(rng)
	local function num()
		return (rng and rng.NextNumber) and rng:NextNumber() or math.random()
	end
	local w = MineTrickOrTreat.weights()
	local order = { "candy", "hat", "skin", "pack", "bucket" }
	local tot = 0
	for _, k in ipairs(order) do
		tot += (w[k] or 0)
	end
	if tot <= 0 then
		return { kind = "candy", amount = math.floor(MineTrickOrTreat.PRICE * MineTrickOrTreat.REFUND.lo) }
	end
	local pick = num() * tot
	local chosen = "candy"
	for _, k in ipairs(order) do
		pick -= (w[k] or 0)
		if pick <= 0 then
			chosen = k
			break
		end
	end

	if chosen == "candy" then
		local r = MineTrickOrTreat.REFUND
		local frac = r.lo + num() * (r.hi - r.lo)
		return { kind = "candy", amount = math.max(1, math.floor(MineTrickOrTreat.PRICE * frac + 0.5)) }
	elseif chosen == "hat" then
		--[[
			No id, on purpose. A hat in this game is a GEAR PIECE rolled by
			Gear.rollPiece(id, rng, "head") -- not a MineHats id you can name
			here. MineHats is the catalogue the roller draws from; picking from
			it directly would produce something the wardrobe has never seen.
			So the case says "a hat" and the server rolls it the one way
			everything else does.
		]]
		return { kind = "hat" }
	elseif chosen == "skin" then
		return { kind = "skin" }
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
