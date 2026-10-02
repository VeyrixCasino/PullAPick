--[[
	MineLootPacks -- what comes out of a fossil, rune or gear pack.

	The pack rows in Mine1PacksData carry `kind` and an `odds` table over the
	same eight-name rarity ladder the card packs use. This module is the roller
	that turns one of those rolls into an actual item, and the ONE place that
	knows how Common..Exotic maps onto each family's own scale:

		rune    tiers 1..5              -- five tiers, so Mythic+ is unreachable
		fossil  the sixteen recipes     -- two recipes per rung, in unlock order
		gear    F→SSS off the shared case ladder — pack odds do NOT set the
		        final letter; see MineGear.rollRarity

	For fossil, the pack's odds GOVERN. Gear letters and rune tiers both come
	off MineTemper.RARITY_WEIGHTS, so one ladder decides how rare "rare" is in
	all three systems: SSS gear and an SSS temperament are both 1 in 5,000, and
	a T5 rune sits on A at 1 in 40.

	Every item comes back carrying `rarityId` off the shared ladder, which is
	what lets the reveal treat it exactly like a card: rarity colour, hold
	timing, pull grade, and the worst-to-best sort all read that one field.
]]

local MineLootPacks = {}

local Gear = require(script.Parent:WaitForChild("MineGear"))
local ToolGrades = require(script.Parent:WaitForChild("MineToolGrades"))
local Runes = require(script.Parent:WaitForChild("MineRunes"))
local Stats = require(script.Parent:WaitForChild("MineStats"))

MineLootPacks.LADDER = {
	"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic",
}

MineLootPacks.RANK = {}
for i, id in ipairs(MineLootPacks.LADDER) do
	MineLootPacks.RANK[id] = i
end

function MineLootPacks.isLoot(kind)
	-- "fossil" is gone with the fossil system; kept out of the list rather than
	-- left in to match a kind nothing produces.
	return kind == "rune" or kind == "gear"
end

--[[
	Pick a rung from the pack's own odds.

	Weights are used as given rather than normalised to 100: a row that sums to
	99.994 because of rounding should still roll, and scaling by the true total
	is both correct and free.
]]
function MineLootPacks.rollRarity(odds, rng)
	rng = rng or Random.new()
	local total = 0
	for _, id in ipairs(MineLootPacks.LADDER) do
		total += math.max(0, tonumber((odds or {})[id]) or 0)
	end
	if total <= 0 then
		return "Common"
	end
	local roll = rng:NextNumber() * total
	local acc = 0
	for _, id in ipairs(MineLootPacks.LADDER) do
		acc += math.max(0, tonumber((odds or {})[id]) or 0)
		if roll <= acc then
			return id
		end
	end
	return "Common"
end

-- ---------------------------------------------------------------- gear ----

--[[
	Gear grades use MineTemper.RARITY_WEIGHTS (same ladder as temperament kits),
	not Clash Royale rollClash and not pack odds rows.

	Lucky blocks / premium crates can still pass opts.startGrade to floor the
	draw (reroll until >= startGrade).
]]
function MineLootPacks.gearItem(rarityId, mintId, rng, opts)
	rng = rng or Random.new()
	opts = type(opts) == "table" and opts or {}
	local Temper = require(script.Parent:WaitForChild("MineTemper"))
	local grade = Gear.rollRarity and Gear.rollRarity(rng) or "F"
	local floor = opts.startGrade and Temper.normalizeRarity(opts.startGrade) or nil
	if floor then
		local order = Temper.GRADE_ORDER or { "F", "D", "C", "B", "A", "S", "SS", "SSS" }
		local floorRank = table.find(order, floor) or 1
		for _ = 1, 24 do
			local r = table.find(order, grade) or 1
			if r >= floorRank then
				break
			end
			grade = Gear.rollRarity(rng)
		end
	end
	-- Same door the summon banner uses, so a hat out of a pack is the same kind
	-- of object as a hat out of a roll: a real catalog item, named after itself.
	local slot = Gear.rollSlot and Gear.rollSlot(rng) or Gear.SLOTS[rng:NextInteger(1, #Gear.SLOTS)]
	if Gear.snapGrade then
		grade = Gear.snapGrade(slot, grade)
	end
	local catalog = Gear.catalogFor and Gear.catalogFor(slot, grade, nil, rng) or nil
	local setId = (catalog and catalog.setId) or Gear.SETS[rng:NextInteger(1, #Gear.SETS)].id
	local set = Gear.SETS_BY_ID[setId] or Gear.SETS[1]
	local piece = Gear.makePiece(mintId, set.id, slot, grade, catalog)
	if not piece then
		return nil
	end
	return {
		kind = "gear",
		rarityId = Gear.PRINT_OF[grade] or "Common",
		name = piece.name or ((piece.setName or piece.setId or "Gear") .. " " .. (Gear.SLOT_LABEL[piece.slot] or piece.slot)),
		sub = (piece.setName or piece.setId or "") .. " set  -  "
			.. ((Stats.STATS[piece.stat] and Stats.STATS[piece.stat].label) or piece.stat or ""),
		gear = piece,
	}
end

-- ---------------------------------------------------------------- rune ----

--[[
	Runes stop at tier five, so the top three rungs are unreachable and the pack
	rows declare them as 0.00% rather than leaving them out. Clamping instead
	would quietly turn a Divine row into another Legendary, which is the kind of
	generosity that reads as a bug when someone counts.
]]
function MineLootPacks.runeItem(rarityId, mintId, rng)
	rng = rng or Random.new()
	local rank = MineLootPacks.RANK[rarityId] or 1
	local tier = math.clamp(rank, 1, Runes.MAX_DROP_TIER or 5)
	-- newRune refuses "gear" outright; gear comes from gear packs, not these.
	local kind = "pet"
	for _ = 1, 8 do
		local k = Runes.rollDropKind(rng)
		if k and k ~= "gear" then
			kind = k
			break
		end
	end
	local rune = Runes.newRune(kind, mintId, rng)
	rune.tier = tier
	rune.pct = Runes.pctForTier(rune.stat, tier)
	return {
		kind = "rune",
		rarityId = rarityId,
		-- "T4 Drill Damage", not "T4": tierLabel alone is the rung, and the
		-- reveal shows this as the item's headline.
		name = string.format("T%d %s", tier, (Stats.STATS[rune.stat] and Stats.STATS[rune.stat].label) or rune.stat),
		-- describe() repeats the kind, the tier and the percentage, all three of
		-- which are already on the face. What the face cannot say is what the
		-- rune is FOR, and "which of my things can take this" is the question
		-- someone actually has when a rune lands. Read off the real socket
		-- rules: a pet rune goes anywhere, the others match their family or
		-- go into gear.
		sub = (kind == "pet")
			and "Fits any pet, tool or gear"
			or ("Fits " .. ((kind == "explosive") and "an " or "a ") .. tostring(kind) .. " or gear"),
		rune = rune,
	}
end

-- -------------------------------------------------------------- fossil ----

--[[
	A fossil loot item used to be minted here. Fossils are retired and both
	fossil modules are deleted, so there is nothing to mint: the pack kinds that
	produced one are gone, and a legacy fossil pack cashes out to gems on the
	server instead of opening.
]]

--[[
	Roll a whole pack.

	`mint` is the id factory the caller passes in (MineServer's instanceHex16),
	rather than one built here: item ids have to be unique against everything
	already in the save, and only the server knows that.
]]
function MineLootPacks.roll(packDef, rng, mint)
	rng = rng or Random.new()
	mint = mint or function() return tostring(math.random(1, 2 ^ 31)) end
	local kind = packDef and packDef.kind
	if not MineLootPacks.isLoot(kind) then
		return {}
	end
	local made = {}
	local want = math.max(1, math.floor(tonumber(packDef.cards) or 1))
	for _ = 1, want do
		local rarityId = MineLootPacks.rollRarity(packDef.odds, rng)
		local item
		if kind == "gear" then
			-- CR process from F (lucky-block API: pass startGrade via gearItem opts).
			item = MineLootPacks.gearItem(rarityId, mint(), rng, { startGrade = "F" })
		elseif kind == "rune" then
			item = MineLootPacks.runeItem(rarityId, mint(), rng)
		end
		if item then
			item.packId = packDef.id
			table.insert(made, item)
		end
	end
	return made
end

return MineLootPacks
