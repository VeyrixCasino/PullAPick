--[[
	MineChestRanks -- the F..SSS ladder for chests (owner, 2026-10-19).

	The owner, on the Candy Crypt v2 answers: "lets go f-sss chests (sorry), and
	f-sss charms" -- "same system as packs" -- and, for the main game, "8 chest
	tiers" with "the same loot overall, split by tier": rarer tiers are rarer,
	turn up more often deeper, and pay more. "All separate names": every chest
	has a name of its own, and its rank is shown beside it as a badge.

	So a chest's RANK is fixed, a property of the chest (MineZoneChests), and the
	rank is what spawns: a block rolls a rank first (roll / odds below), then
	which of that rank's chests it is. Rolling the rank first is what keeps "the
	same loot overall" provable: everything a chest pays is a function of its
	rank, so the loot split is the rank split.

	  F  Common      the everyday chest
	  D  Uncommon
	  C  Rare
	  B  Epic
	  A  Legendary
	  S  Mythic
	  SS Divine
	  SSS Exotic     about 1 in 1,000 chests at a zone's top, 1 in 220 at its floor

	The words and colours are MineTemper's (MineTemper.WORD_OF, RARITY_COLOR), so
	a chest's S, a charm's S and a pack set's S are one ladder.

	DEPTH. MineConfig.chestRankLuck(zone, layer) is "better", x1 at a zone's top
	to x3 at its floor (Dirt Meadow and the event mines stay x1: owner, 2026-10-10).
	It multiplies each rank's weight by better ^ LIFT[rank], so a rarer rank gains
	more from depth. The count of chests never changes (MineConfig.CHEST_CHANCE).

	AGING IS RETIRED. Until 2026-10-19 unlocking a zone aged every earlier zone's
	pool one rank (S -> A ... -> F, where F meant extinct). A chest's rank is its
	badge now, and F is a real rank, so a pool no longer ages: agePool and
	nextRank are kept for old callers and change nothing.

	Every number here is PROPOSED (2026-10-19). tools/verify/economy-gems.js and
	tools/verify/chest-ranks.js prove the split keeps the old totals.
]]

local MineChestRanks = {}

-- Worst to best. (ORDER below is the old best-first reading order.)
MineChestRanks.LADDER = { "F", "D", "C", "B", "A", "S", "SS", "SSS" }
MineChestRanks.ORDER = { "SSS", "SS", "S", "A", "B", "C", "D", "F" }

MineChestRanks.INDEX = {}
for i, r in ipairs(MineChestRanks.LADDER) do
	MineChestRanks.INDEX[r] = i
end

--[[
	PROPOSED (2026-10-19). THE RANK SPLIT.

	WEIGHT is the share at a zone's top (x1): F 48%, D 28%, C 14%, B 6.4%, A 2.5%,
	S 0.8%, SS 0.25%, SSS 0.1%. LIFT is how hard depth pulls each rank up: at a
	zone's floor (x3) F is 42%, S 2.1%, SS 0.86% and SSS 0.45%.

	The old ladder had S 4, A 10, B 22, C 100, D 35 (C the filler) and lifted B, A
	and S x3 at the floor. The new one keeps the old S and A shares at the floor
	(2.1% and 5.0% against 2.2% and 4.9%).
]]
MineChestRanks.WEIGHT = {
	F = 480, D = 280, C = 140, B = 64, A = 25, S = 8, SS = 2.5, SSS = 1,
}
MineChestRanks.LIFT = {
	F = 0, D = 0, C = 0.25, B = 0.5, A = 0.75, S = 1, SS = 1.25, SSS = 1.5,
}

-- The word a player reads beside the badge (MineTemper.WORD_OF, typed here so a
-- server-only reader needs no second module).
MineChestRanks.LABEL = {
	F = "Common", D = "Uncommon", C = "Rare", B = "Epic",
	A = "Legendary", S = "Mythic", SS = "Divine", SSS = "Exotic",
}

-- The badge colours: MineTemper.RARITY_COLOR's, so the badge matches the reel.
MineChestRanks.COLOR = {
	F = Color3.fromRGB(170, 170, 170),
	D = Color3.fromRGB(85, 255, 127),
	C = Color3.fromRGB(85, 170, 255),
	B = Color3.fromRGB(170, 85, 255),
	A = Color3.fromRGB(255, 170, 0),
	S = Color3.fromRGB(120, 215, 255),
	SS = Color3.fromRGB(205, 180, 255),
	SSS = Color3.fromRGB(255, 55, 55),
}

function MineChestRanks.valid(rank)
	return MineChestRanks.INDEX[rank] ~= nil
end

-- 1 for F .. 8 for SSS; an unknown rank reads as F.
function MineChestRanks.index(rank)
	return MineChestRanks.INDEX[rank] or 1
end

-- "S · Mythic" for a toast; "" for nothing.
function MineChestRanks.badge(rank)
	if not MineChestRanks.valid(rank) then
		return ""
	end
	return rank .. " · " .. MineChestRanks.LABEL[rank]
end

-- Kept for old callers. A rank no longer ages (see the header).
function MineChestRanks.nextRank(rank)
	return rank
end

function MineChestRanks.agePool(pool)
	local out = {}
	for _, row in ipairs(pool or {}) do
		table.insert(out, row)
	end
	return out
end

-- A rank's weight at depth luck `better` (1 at a zone's top .. 3 at its floor).
function MineChestRanks.weightOf(rank, better)
	local w = MineChestRanks.WEIGHT[rank] or 0
	local b = math.max(1, tonumber(better) or 1)
	if b ~= 1 then
		w *= b ^ (MineChestRanks.LIFT[rank] or 0)
	end
	return w
end

--[[
	The rank split at depth luck `better`: { F = p, ..., SSS = p }, summing to 1.
	One function for the roll, the odds the screens show and the economy check,
	so they cannot disagree.
]]
function MineChestRanks.odds(better)
	local out, total = {}, 0
	for _, r in ipairs(MineChestRanks.LADDER) do
		local w = MineChestRanks.weightOf(r, better)
		out[r] = w
		total += w
	end
	for _, r in ipairs(MineChestRanks.LADDER) do
		out[r] = (total > 0) and (out[r] / total) or 0
	end
	return out
end

-- One rank, drawn from odds(better).
function MineChestRanks.rollRank(rng, better)
	local odds = MineChestRanks.odds(better)
	local u = ((rng and rng:NextNumber()) or math.random())
	for _, r in ipairs(MineChestRanks.LADDER) do
		u -= odds[r]
		if u <= 0 then
			return r
		end
	end
	return "F"
end

--[[
	One row of a pool `{ { chestId, rank }, ... }`, weighted by its rank. Kept
	for the old callers: a pool's own rows split their rank's weight between
	them, so a rank with two chests is not twice as common as a rank with one.
	`opts.better` is the depth luck; `opts.luck` is ignored (chest luck never
	moved a rank on the new ladder: it raises the case, skin, book and charm
	chances instead).
]]
function MineChestRanks.roll(pool, rng, opts)
	rng = rng or Random.new()
	opts = opts or {}
	local per = {}
	for _, row in ipairs(pool or {}) do
		per[row.rank] = (per[row.rank] or 0) + 1
	end
	local total = 0
	local rows = {}
	for _, row in ipairs(pool or {}) do
		local w = MineChestRanks.weightOf(row.rank, opts.better) / math.max(1, per[row.rank] or 1)
		if w > 0 then
			total += w
			table.insert(rows, { row = row, w = w })
		end
	end
	if total <= 0 or #rows == 0 then
		return nil
	end
	local roll = rng:NextNumber() * total
	local acc = 0
	for _, e in ipairs(rows) do
		acc += e.w
		if roll <= acc then
			return e.row
		end
	end
	return rows[#rows].row
end

return MineChestRanks
