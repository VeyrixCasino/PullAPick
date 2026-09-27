--[[
	MineAbbrev — health and shop prices.

	Default: normal suffixes K M B T Qa Qi Sx Sp Oc No Dc ...
	Settings option "Simple abbrev": after T use aa, ab, ac ... yz, zz.
	The label is never smaller than the number (ceil to one decimal of the unit).
]]

local MineAbbrev = {}

local NORMAL = {
	"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No",
	"Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod",
	"Vg", "Uvg", "Dvg", "Tvg", "Qavg", "Qivg", "Sxvg", "Spvg", "Ocvg", "Novg",
	"Tg", "Utg", "Dtg", "Ttg", "Qatg", "Qitg", "Sxtg", "Sptg", "Octg", "Notg",
}

-- Default off: normal names. Simple = aa/ab after trillion.
MineAbbrev.simple = false

function MineAbbrev.setSimple(on)
	MineAbbrev.simple = on and true or false
end

function MineAbbrev.isSimple()
	return MineAbbrev.simple == true
end

local function simpleSuffix(exp)
	if exp <= 4 then
		return NORMAL[exp]
	end
	local n = exp - 5
	if n > 675 then
		n = 675
	end
	local a = math.floor(n / 26)
	local b = n % 26
	return string.char(97 + a) .. string.char(97 + b)
end

local function normalSuffix(exp)
	if exp <= #NORMAL then
		return NORMAL[exp]
	end
	-- Past the named list: keep going with simple letters so a label still exists.
	return simpleSuffix(exp)
end

local function suffix(exp)
	if MineAbbrev.simple then
		return simpleSuffix(exp)
	end
	return normalSuffix(exp)
end

local function maxExp()
	if MineAbbrev.simple then
		return 4 + 26 * 26 - 1
	end
	return math.max(#NORMAL, 4 + 26 * 26 - 1)
end

local function ceilTenth(x)
	local t = x * 10
	local f = math.floor(t + 1e-6)
	if t - f > 1e-4 then
		f += 1
	end
	return f / 10
end

function MineAbbrev.ceil(n)
	n = tonumber(n) or 0
	if n <= 0 then
		return 0
	end
	if n < 1000 then
		return math.ceil(n - 1e-8)
	end
	local cap = maxExp()
	local exp = math.floor(math.log10(n) / 3)
	exp = math.clamp(exp, 1, cap)
	local unit = 10 ^ (exp * 3)
	local shown = ceilTenth(n / unit)
	if shown >= 1000 and exp < cap then
		exp += 1
		unit = 10 ^ (exp * 3)
		shown = ceilTenth(n / unit)
	end
	return shown * unit
end

function MineAbbrev.format(n)
	local c = MineAbbrev.ceil(n)
	if c < 1000 then
		return tostring(math.floor(c + 0.5))
	end
	local cap = maxExp()
	local exp = math.floor(math.log10(math.max(c, 1)) / 3)
	exp = math.clamp(exp, 1, cap)
	local unit = 10 ^ (exp * 3)
	local shown = c / unit
	if shown >= 999.95 and exp < cap then
		exp += 1
		unit = 10 ^ (exp * 3)
		shown = c / unit
	end
	local text
	if math.abs(shown - math.floor(shown + 1e-4)) < 1e-2 then
		text = string.format("%.0f", shown)
	else
		text = string.format("%.1f", shown)
	end
	return text .. suffix(exp)
end

return MineAbbrev
