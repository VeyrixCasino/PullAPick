--[[
	MineStars -- one place to turn any grade-like value into the shared ★ scale.

	TODO ★ NOW / B4: every grading system shows a ★ equivalent beside its
	current name. The ladder is 1★ to 5★ in half steps (nine grades). This
	module does not invent odds or pay; it only maps names the game already
	uses onto that display scale.

	Canonical half-steps match MineFishing.GRADES / MineCases.WILD_GRADES.
	Letter and word ladders (F…SSS / Common…Exotic) are the same eight rungs
	(MineTemper.WORD_OF, MineGear.PRINT_OF); ★★★★½ has no letter twin.
]]

local MineStars = {}

-- Nine half-star grades, low to high.
MineStars.VALUES = { 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5 }

MineStars.TEXT = {
	[1] = "★",
	[1.5] = "★½",
	[2] = "★★",
	[2.5] = "★★½",
	[3] = "★★★",
	[3.5] = "★★★½",
	[4] = "★★★★",
	[4.5] = "★★★★½",
	[5] = "★★★★★",
}

-- F…SSS / Common…Exotic display map. Gap at 4.5★: eight letter rungs, nine
-- half-steps. Top of each ladder (SSS / Exotic) is 5★.
MineStars.LETTER = {
	F = 1,
	D = 1.5,
	C = 2,
	B = 2.5,
	A = 3,
	S = 3.5,
	SS = 4,
	SSS = 5,
}

MineStars.WORD = {
	Common = 1,
	Uncommon = 1.5,
	Rare = 2,
	Epic = 2.5,
	Legendary = 3,
	Mythic = 3.5,
	Divine = 4,
	Exotic = 5,
}

-- Zone card packs (MinePackConfig.ZONE_PACK_STARS).
MineStars.ZONE_PACK = {
	pack_common = 1,
	pack_rare = 2,
	pack_legendary = 3,
}

-- Event Horizon pass track rungs (MineEventPass.TRACKS.event_horizon.tiers).
-- Display only: six named tiers onto the first six half-steps.
MineStars.PASS_TIER = {
	eh1 = 1,
	eh2 = 1.5,
	eh3 = 2,
	eh4 = 2.5,
	eh5 = 3,
	eh6 = 3.5,
}

local TEXT_TO_VALUE = {}
for value, text in pairs(MineStars.TEXT) do
	TEXT_TO_VALUE[text] = value
end

local function half(n)
	n = tonumber(n)
	if not n then
		return nil
	end
	return math.clamp(math.floor(n * 2 + 0.5) / 2, 0.5, 5)
end

--[[
	Numeric star value in half steps, or nil when gradeLike is unknown.
	Accepts:
	  * a half-star number (1 … 5)
	  * letter F…SSS or word Common…Exotic
	  * zone pack slot ids (pack_common / pack_rare / pack_legendary)
	  * Event Horizon pass tier ids (eh1 … eh6)
	  * a fishing / wild-case glyph string ("★★½")
	  * fishing grade index 1..9 only when tagged as { gradeIndex = n }
	    or passed as the table form below — bare integers 1..5 stay star values
]]
function MineStars.value(gradeLike)
	if gradeLike == nil then
		return nil
	end
	if type(gradeLike) == "table" then
		if gradeLike.gradeIndex ~= nil then
			local i = math.floor(tonumber(gradeLike.gradeIndex) or 0)
			return MineStars.VALUES[i]
		end
		if gradeLike.stars ~= nil then
			return half(gradeLike.stars)
		end
		if gradeLike.grade ~= nil then
			return MineStars.value(gradeLike.grade)
		end
		if gradeLike.rarity ~= nil then
			return MineStars.value(gradeLike.rarity)
		end
		return nil
	end
	if type(gradeLike) == "number" then
		return half(gradeLike)
	end
	local s = tostring(gradeLike)
	if TEXT_TO_VALUE[s] then
		return TEXT_TO_VALUE[s]
	end
	if MineStars.LETTER[s] then
		return MineStars.LETTER[s]
	end
	if MineStars.WORD[s] then
		return MineStars.WORD[s]
	end
	if MineStars.ZONE_PACK[s] then
		return MineStars.ZONE_PACK[s]
	end
	if MineStars.PASS_TIER[s] then
		return MineStars.PASS_TIER[s]
	end
	-- "3.5★" / "4★" compact labels from MinePackConfig.starLabel.
	local compact = string.match(s, "^(%d+%.?%d*)★$")
	if compact then
		return half(compact)
	end
	return nil
end

-- Glyph string for UI ("★★★½"), or "" when unknown.
function MineStars.stars(gradeLike)
	local v = MineStars.value(gradeLike)
	if not v then
		return ""
	end
	return MineStars.TEXT[v] or ""
end

-- Compact "3.5★" form for single-line labels.
function MineStars.label(gradeLike)
	local v = MineStars.value(gradeLike)
	if not v then
		return ""
	end
	if v % 1 == 0 then
		return string.format("%d★", v)
	end
	return string.format("%.1f★", v)
end

-- Letter/word kept, stars beside it: "SSS  ★★★★★". Falls back to stars alone
-- when gradeLike is already numeric or a glyph.
function MineStars.beside(gradeLike)
	local glyph = MineStars.stars(gradeLike)
	if glyph == "" then
		return tostring(gradeLike or "")
	end
	if type(gradeLike) == "string" and (MineStars.LETTER[gradeLike] or MineStars.WORD[gradeLike]) then
		return gradeLike .. "  " .. glyph
	end
	return glyph
end

return MineStars
