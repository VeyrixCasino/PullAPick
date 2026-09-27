-- MineToolGrades: F→SSS grades, fusion up to A, Clash Royale–style lucky rolls.
--
-- Live draw is a CR chest process (NOT a weighted table):
--   upgrade p = 1/3, miss = 2/3, stop at 3 misses OR SSS.
-- Ladder: F → D → C → B → A → S → SS → SSS
-- From F, max upgrades = 7. Same process from D/C/B/A with fewer steps to SSS.

local MineToolGrades = {}

MineToolGrades.ORDER = { "F", "D", "C", "B", "A", "S", "SS", "SSS" }

-- Upgrade chance per step (owner-locked). Not 25% / "75-25".
MineToolGrades.UPGRADE_P = 1 / 3
MineToolGrades.MISS_LIMIT = 3

--[[
	Theoretical final odds from a pure F start (negative-binomial freeze at 3
	misses, absorb at SSS). Ending at rank r takes r-1 upgrades and then the
	third miss, so the numerator is C(r+1, 2) * 8 -- which is where this table
	had gone wrong: A, S and SS were written as 112 / 140 / 160 instead of
	120 / 168 / 224, and because SSS is defined as the leftover it swallowed the
	whole error and read 1.95%% instead of 0.83%%. That made the table claim SSS
	was 2.4x COMMONER than SS, which is not what the process does.

	Verified against a 300k-draw simulation of rollClash:
	  F 29.63  D 29.63  C 19.75  B 10.97  A 5.49  S 2.56  SS 1.14  SSS 0.83

	NOTE: nothing rolls gear from this any more. Gear letters come from
	MineGear.rollRarity, which draws the shared case ladder
	(MineTemper.RARITY_WEIGHTS). This stays for lucky blocks and for docs.
]]
MineToolGrades.FINAL_ODDS_FROM_F = {
	F = 8 / 27,
	D = 8 / 27,
	C = 48 / 243,
	B = 80 / 729,
	A = 120 / 2187,
	S = 168 / 6561,
	SS = 224 / 19683,
	-- SSS absorbs remaining mass (paths that hit 7 upgrades before 3rd miss).
	SSS = 1 - (8 / 27 + 8 / 27 + 48 / 243 + 80 / 729 + 120 / 2187 + 168 / 6561 + 224 / 19683),
}

-- Legacy weighted table (docs / old sims only). Live draw uses rollClash.
MineToolGrades.RARITY_WEIGHTS = {
	F = 1855, D = 2355, C = 3160, B = 1855,
	A = 485, S = 80, SS = 10, SSS = 2,
}

-- Power (and similar) multiplier vs F.
MineToolGrades.MULT = {
	F = 1, D = 2, C = 4, B = 8,
	A = 16, S = 32, SS = 64, SSS = 128,
}

MineToolGrades.FUSE_CAP = "A" -- cannot fuse into S+

function MineToolGrades.rankOf(grade)
	for i, g in ipairs(MineToolGrades.ORDER) do
		if g == grade then
			return i
		end
	end
	return 1
end

function MineToolGrades.mult(grade)
	return MineToolGrades.MULT[grade or "F"] or 1
end

--[[
	Clash Royale–style grade climb.

	Returns: finalGrade, info
	info = {
		steps = { { ok = bool, grade = string }, ... },  -- grade AFTER the step
		upgrades = number,
		misses = number,
		start = string,
		final = string,
	}
	Server is authoritative: send info.steps to the client for animation;
	do not re-roll on the client.
]]
--[[
	The chance of the NEXT step, given the rank you are on (1 = F). A caller may
	pass its own ladder as `probs`; lucky blocks do (MineLuckyBlocks.UPGRADE_P).
	Without one every step is UPGRADE_P, which is what gear and tools still use.
]]
function MineToolGrades.upgradeChance(rank, probs)
	if type(probs) == "table" then
		local p = tonumber(probs[rank])
		if p then
			return p
		end
	end
	return MineToolGrades.UPGRADE_P
end

function MineToolGrades.rollClash(startGrade, rng, probs)
	rng = rng or Random.new()
	local start = startGrade or "F"
	local rank = MineToolGrades.rankOf(start)
	local maxRank = #MineToolGrades.ORDER
	local grade = MineToolGrades.ORDER[rank] or "F"
	local steps = {}
	local upgrades, misses = 0, 0
	local missLimit = MineToolGrades.MISS_LIMIT

	if rank >= maxRank then
		return grade, {
			steps = steps,
			upgrades = 0,
			misses = 0,
			start = grade,
			final = grade,
		}
	end

	while misses < missLimit and rank < maxRank do
		local ok = rng:NextNumber() < MineToolGrades.upgradeChance(rank, probs)
		if ok then
			rank += 1
			upgrades += 1
			grade = MineToolGrades.ORDER[rank]
			table.insert(steps, { ok = true, grade = grade })
		else
			misses += 1
			table.insert(steps, { ok = false, grade = grade })
		end
	end

	return grade, {
		steps = steps,
		upgrades = upgrades,
		misses = misses,
		start = MineToolGrades.ORDER[MineToolGrades.rankOf(start)] or "F",
		final = grade,
	}
end

-- Default tool/gear draw: CR process from F (replaces weighted RARITY_WEIGHTS).
function MineToolGrades.roll(rng)
	local grade = MineToolGrades.rollClash("F", rng)
	return grade
end

--[[
	Monte-carlo audit helper. Returns { [grade] = fraction, ... }.
	Optional; not used in production rolls.
]]
function MineToolGrades.simulateOdds(startGrade, n)
	n = math.max(1, math.floor(tonumber(n) or 100000))
	local counts = {}
	for _, g in ipairs(MineToolGrades.ORDER) do
		counts[g] = 0
	end
	local rng = Random.new()
	for _ = 1, n do
		local g = MineToolGrades.rollClash(startGrade or "F", rng)
		counts[g] = (counts[g] or 0) + 1
	end
	local out = {}
	for _, g in ipairs(MineToolGrades.ORDER) do
		out[g] = counts[g] / n
	end
	return out
end

function MineToolGrades.nextGrade(grade)
	local r = MineToolGrades.rankOf(grade)
	local cap = MineToolGrades.rankOf(MineToolGrades.FUSE_CAP)
	if r >= cap then
		return nil
	end
	return MineToolGrades.ORDER[r + 1]
end

-- Fuse two earned tools of same id+grade into next grade (cap A).
function MineToolGrades.canFuse(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	if a.id ~= b.id and a.toolId ~= b.toolId then
		local idA = a.toolId or a.fossilId or a.id
		local idB = b.toolId or b.fossilId or b.id
		if idA ~= idB then
			return false
		end
	end
	local g = a.grade or "F"
	if (b.grade or "F") ~= g then
		return false
	end
	return MineToolGrades.nextGrade(g) ~= nil
end

function MineToolGrades.applyPower(basePower, grade)
	return math.floor((basePower or 0) * MineToolGrades.mult(grade) + 0.5)
end

return MineToolGrades
