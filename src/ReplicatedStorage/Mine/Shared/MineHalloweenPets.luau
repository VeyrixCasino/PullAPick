--[[
	MineHalloweenPets -- the Halloween pets, for the Candy Crypt and its case.

	Owner, 2026-10-19 (wiki/open-questions.md, "Candy Crypt v2"): twelve more
	Halloween pets on new bodies; the Crypt's packs and the Trick-or-Treat case
	pay Halloween pets; Halloween Mythic+ pets are 20% better than the best
	normal pets, even after the event; and some make builds possible that
	nothing else does.

	The pets themselves are GENERATED (tools/gen/holiday-pets.js writes
	HolidayPets/Halloween2026). This module only answers questions about them,
	from the roster, so every caller agrees with the pack, the wheel and the
	card painter:

	  pool(rarity)     the roster rows the Crypt's packs and the Trick-or-Treat
	                   case may pay: the Halloween 2026 pack's own pets (the 60
	                   and the 12 of 2026-10-19), only `rarity`'s when one is
	                   given. A fresh list each call; the rows are the roster's
	                   own, so read them, never write them. Not the three older
	                   Halloween pets (Spindle, Spooky, Wisp): the Halloween
	                   2026 Pack still pays those.
	  isHalloween(c)   true for a Halloween pet's card, whatever minted it (a
	                   pack, the Crypt, the wheel): its roster row says
	                   holiday = "halloween". Takes a card or a pet's name.
	  rowOf(c)         the roster row behind a card or a name, or nil.
	  buildOf(c)       the build a Halloween pet makes possible ("Crater",
	                   "Hex Storm" ...), or nil.
	  card(row)        a card for a pool row, minted the way a pack mints one
	                   (MineSetPacks.petCard), with the pack's key as its home so
	                   every copy stacks.

	Pure reads; no services. The server and the client may both require it.
]]
local MineHalloweenPets = {}

-- The generated pack's KEY (HolidayPets/Halloween2026), which is also every
-- Halloween 2026 pet's home in its stack key ("halloween_2026:<name>").
MineHalloweenPets.KEY = "halloween_2026"
MineHalloweenPets.HOLIDAY = "halloween"

local shared = script.Parent
local Roster = require(shared:WaitForChild("MinePetRoster"))
local Sets = require(shared:WaitForChild("MineSetPets"))
local Boosts = require(shared:WaitForChild("MinePetBoosts"))

local function pack()
	return Sets.BY_KEY and Sets.BY_KEY[MineHalloweenPets.KEY]
end

-- The pack's own pets as roster rows, in the pack's order. Built once: the
-- roster never changes at runtime.
local packRows
local function rows()
	if packRows then
		return packRows
	end
	local out = {}
	local p = pack()
	for _, row in ipairs((p and p.PETS) or {}) do
		local r = Roster.BY_NAME[row.name]
		if r and r.holiday == MineHalloweenPets.HOLIDAY then
			table.insert(out, r)
		end
	end
	packRows = out
	return out
end

function MineHalloweenPets.pool(rarity)
	local out = {}
	for _, r in ipairs(rows()) do
		if rarity == nil or r.tier == rarity then
			table.insert(out, r)
		end
	end
	return out
end

-- A card's pet name: its `name`, else the name in its stack key.
local function nameOf(x)
	if type(x) == "string" then
		return x
	end
	if type(x) ~= "table" then
		return nil
	end
	if type(x.name) == "string" then
		return x.name
	end
	if type(x.cardKey) == "string" then
		return string.match(x.cardKey, ":(.+)$")
	end
	return nil
end

function MineHalloweenPets.rowOf(x)
	local n = nameOf(x)
	if type(n) ~= "string" or n == "" then
		return nil
	end
	return Roster.BY_NAME[Boosts.resolveName(n)]
end

function MineHalloweenPets.isHalloween(x)
	local r = MineHalloweenPets.rowOf(x)
	return r ~= nil and r.holiday == MineHalloweenPets.HOLIDAY
end

function MineHalloweenPets.buildOf(x)
	local r = MineHalloweenPets.rowOf(x)
	local p = pack()
	return (r and p and p.BUILD and p.BUILD[r.name]) or nil
end

-- Required here, not at the top: MineSetPacks is only needed to mint.
function MineHalloweenPets.card(row)
	local SetPacks = require(shared:WaitForChild("MineSetPacks"))
	local p = pack()
	return SetPacks.petCard(row, MineHalloweenPets.KEY, (p and p.NAME) or "Halloween 2026")
end

return MineHalloweenPets
