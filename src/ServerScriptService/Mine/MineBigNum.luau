--[[
	MineBigNum — the big-number system. SERVER ONLY, on purpose.

	This lives under ServerScriptService so the client cannot require it. The
	server is what turns a number into the string a player reads, and the client
	renders that string. A client that formats its own numbers is a client that
	can disagree with the server about what something costs.

	Two readouts, same number:

	  suffix form   1.23 Qa        legible, the default
	  science form  1.23e^45       exact magnitude, for the deep end

	BASE 30, three digits a step
	---------------------------
	Every step is 1000x, so one symbol covers three decimal digits. The symbol
	set is 30 wide:

	  steps  1-20   the named suffixes, K M B T Qa ... Nod
	  steps 21-30   the backlog: the last ten letters, q r s t u v w x y z

	Past 30 it carries like any positional numeral in base 30 -- "Kq", "KK",
	and so on -- so there is no ceiling short of absurdity. Nothing has to be
	authored past the named twenty.

	ALWAYS ROUNDS DOWN
	------------------
	Every value shown is floor'd to one decimal of its unit. A player is never
	told they have more than they have. This is the opposite of MineAbbrev.ceil,
	which rounds UP because block HP labels must never understate the block --
	a label smaller than the rock would read as a broken number. Both are
	deliberate; do not "fix" either into the other.
]]
local MineBigNum = {}

-- Steps 1-20. Index is the power-of-1000 step, so NAMED[1] is thousands.
MineBigNum.NAMED = {
	"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No",
	"Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod",
}

-- Steps 21-30, the backlog. The last ten letters, in order.
MineBigNum.BACKLOG = { "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" }

MineBigNum.BASE = 30

-- The 30 symbols as one flat table, so base-30 carry is a plain index.
local function symbols()
	if MineBigNum._symbols then
		return MineBigNum._symbols
	end
	local t = {}
	for _, s in ipairs(MineBigNum.NAMED) do
		t[#t + 1] = s
	end
	for _, s in ipairs(MineBigNum.BACKLOG) do
		t[#t + 1] = s
	end
	MineBigNum._symbols = t
	return t
end

--[[
	The symbol for a power-of-1000 step.

	step 1..30 is a single symbol. Past that it carries in base 30, most
	significant symbol first, so step 31 is "KK" -- one full turn of the wheel
	plus one. Returns "" for step 0, which is a bare number under 1000.
]]
function MineBigNum.suffix(step)
	step = math.floor(tonumber(step) or 0)
	if step <= 0 then
		return ""
	end
	local sym = symbols()
	local base = MineBigNum.BASE
	if step <= base then
		return sym[step]
	end
	-- Zero-based from here so the carry is ordinary positional arithmetic.
	local n = step - 1
	local out = ""
	while n >= 0 do
		out = sym[(n % base) + 1] .. out
		n = math.floor(n / base) - 1
		if n < 0 then
			break
		end
	end
	return out
end

-- Floor to one decimal. 1.29 -> 1.2, never 1.3: the player is never told they
-- hold more than they hold.
local function floorTenth(x)
	return math.floor(x * 10 + 1e-9) / 10
end

--[[
	The step a number sits in, and its mantissa within that step.

	Returns step, mantissa where mantissa is in [1, 1000) for any step above 0.
	Split out because both readouts need it and neither should recompute it.
]]
function MineBigNum.split(n)
	n = tonumber(n) or 0
	local sign = n < 0 and -1 or 1
	n = math.abs(n)
	if n < 1000 then
		return 0, n * sign
	end
	local step = math.floor(math.log(n, 10) / 3)
	local mant = n / (10 ^ (step * 3))
	-- Floating point can land a hair under 1 or at 1000; nudge back in range so
	-- a value never renders as "0.9K" or "1000K".
	if mant >= 1000 then
		step += 1
		mant = n / (10 ^ (step * 3))
	elseif mant < 1 and step > 0 then
		step -= 1
		mant = n / (10 ^ (step * 3))
	end
	return step, mant * sign
end

-- Suffix form: "1.2 Qa". The default readout.
function MineBigNum.format(n, space)
	local step, mant = MineBigNum.split(n)
	if step <= 0 then
		return tostring(math.floor(mant))
	end
	local sep = (space == false) and "" or " "
	return string.format("%s%s%s", tostring(floorTenth(mant)), sep, MineBigNum.suffix(step))
end

--[[
	Science form: "1.23e^45".

	The exponent is the true base-10 exponent, not the step, because this
	readout exists to answer "how big, exactly" rather than "what do I call it".
]]
function MineBigNum.sci(n, places)
	n = tonumber(n) or 0
	if n == 0 then
		return "0"
	end
	local sign = n < 0 and "-" or ""
	n = math.abs(n)
	local exp = math.floor(math.log(n, 10))
	local mant = n / (10 ^ exp)
	if mant >= 10 then
		exp += 1
		mant = n / (10 ^ exp)
	end
	local p = math.max(0, math.floor(tonumber(places) or 2))
	local mult = 10 ^ p
	mant = math.floor(mant * mult + 1e-9) / mult   -- round down, as everywhere
	return string.format("%s%se^%d", sign, tostring(mant), exp)
end

--[[
	Pick a readout for the player.

	Suffix form while a name still exists for the step, science past it. The
	cutover is where the names stop being useful rather than a taste call: once
	a suffix is three carried symbols deep it communicates less than the
	exponent does.
]]
function MineBigNum.auto(n)
	local step = MineBigNum.split(n)
	if step <= MineBigNum.BASE then
		return MineBigNum.format(n)
	end
	return MineBigNum.sci(n)
end

return MineBigNum
