--[[
	MineChestRanks — S/A/B/C/D/F ladder for zone chest pools.

	When the player unlocks the next permanent zone, each already-unlocked
	zone ages one step:

		D → F (extinct / removed)
		C → D
		B → C
		A → B
		S → A
		+ new S rows injected by content

	C is the main filler (highest weight). S is the new ultra-rare.
]]

local MineChestRanks = {}

MineChestRanks.ORDER = { "S", "A", "B", "C", "D", "F" }

MineChestRanks.WEIGHT = {
	S = 4,
	A = 10,
	B = 22,
	C = 100,
	D = 35,
	F = 0,
}

MineChestRanks.LABEL = {
	S = "Ultra Rare",
	A = "Epic",
	B = "Rare",
	C = "Common",
	D = "Lowend",
	F = "Extinct",
}

local AGE_NEXT = {
	S = "A",
	A = "B",
	B = "C",
	C = "D",
	D = "F",
	F = "F",
}

function MineChestRanks.nextRank(rank)
	return AGE_NEXT[rank] or rank
end

function MineChestRanks.agePool(pool)
	local out = {}
	for _, row in ipairs(pool or {}) do
		local rank = MineChestRanks.nextRank(row.rank or "C")
		if rank ~= "F" then
			table.insert(out, {
				chestId = row.chestId,
				rank = rank,
			})
		end
	end
	return out
end

function MineChestRanks.weightOf(rank)
	return MineChestRanks.WEIGHT[rank] or 0
end

function MineChestRanks.roll(pool, rng, opts)
	rng = rng or Random.new()
	opts = opts or {}
	local luck = math.max(0, tonumber(opts.luck) or 1)
	local total = 0
	local rows = {}
	for _, row in ipairs(pool or {}) do
		local w = MineChestRanks.weightOf(row.rank)
		if w > 0 then
			if row.rank ~= "C" then
				w = w * luck
			end
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
