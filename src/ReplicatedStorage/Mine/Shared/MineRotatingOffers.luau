--[[
	MineRotatingOffers — scheduled limited aisle.

	US Eastern (EDT, UTC-4). That is the timezone with the most Roblox players,
	and the battle pass already ends on an Eastern midnight.
	Season: 2026-09-22 00:00 ET through 2026-11-01 00:00 ET, so Oct 31 is a full day
	and the clock hits zero at midnight.

	Two or three offers are live at once. Windows are 1 week or 2 weeks, except
	Founders, which stays up the whole season. Lucky Block Week and Pot of Gold
	do not return.
]]

local MineRotatingOffers = {}

local LuckyBlocks = require(script.Parent:WaitForChild("MineLuckyBlocks"))
local ZonePacks = require(script.Parent:WaitForChild("MineZonePacks"))
--[[
	The season clock, not the wall clock. Before the owner launches,
	seasonNow() is pinned to SEASON_START, so slot one is live and nothing has
	expired however long the game sits unlaunched. Defaulted HERE rather than at
	the call sites so every caller -- client panels included -- gets it without
	having to know the rule.
]]
local Launch = require(script.Parent:WaitForChild("MineLaunch"))

local START = 1790049600
local WEEK = 604800
local ENDS = 1793505600

MineRotatingOffers.SEASON_START = START
MineRotatingOffers.SEASON_END = ENDS
MineRotatingOffers.SLOT_COUNT = 3

MineRotatingOffers.OFFERS = {
	{
		id = "deal_lucky_week", key = "deal_lucky_week", kind = "deal",
		title = "Lucky Block Week", icon = "lucky_block",
		credits = 599, max = 3, neverReturns = true,
		starts = START, ends = START + WEEK,
		blocks = {
			{ id = "lucky_block", qty = 5 },
			{ id = "super_lucky_block", qty = 3 },
			{ id = "godly_lucky_block", qty = 1 },
		},
		packs = {
			{ id = "heirloom_pack", qty = 4 },
			{ id = "omen_pack", qty = 2 },
			{ id = "shiny_pack", qty = 2 },
		},
		pet = 1,
		blurb = "LIMITED TIME. NEVER COMING BACK. 5 Lucky Blocks, 3 Diamond, 1 Godly, a Lucky Block pet, plus 4 Heirloom, 2 Omen, 2 Shiny packs. 599 credits. Max 3.",
		toast = "Lucky Block Week claimed — open them in your bag",
	},
	{
		id = "deal_pot_gold", key = "deal_pot_gold", kind = "deal",
		title = "Pot of Gold", icon = "luck",
		credits = 599, max = 1, neverReturns = true,
		starts = START, ends = START + 2 * WEEK,
		charm = "lucky_charm", shinyPacks = 8,
		packs = {
			{ id = "heirloom_pack", qty = 3 },
			{ id = "omen_pack", qty = 2 },
			{ id = "apex_pack", qty = 1 },
		},
		potions = { { id = "pot_t3_fortune", qty = 2 } },
		blurb = "LIMITED TIME. NEVER COMING BACK. 200% Luck charm, 8 Shiny Packs, 3 Heirloom, 2 Omen, 1 Apex, and 2 Fortune Flasks. 599 credits. Max 1.",
		toast = "Pot of Gold claimed — equip the charm, then open the packs",
	},
	{
		id = "rot_founders", key = "patron_rig", kind = "founders",
		title = "Founders Bag", icon = "logo",
		credits = 799,
		starts = START, ends = ENDS,
		blurb = "The long one. Founders Bag stays on the shelf through Oct 31. 799 credits.",
	},
	{
		id = "feat_lucky10", key = "feat_lucky10", kind = "deal",
		title = "Lucky Stack", icon = "lucky_block",
		credits = 350,
		starts = START + WEEK, ends = START + 3 * WEEK,
		blocks = { { id = "lucky_block", qty = 10 } },
		blurb = "10 Lucky Blocks for 2 weeks. 350 credits.",
		toast = "Lucky Stack claimed",
	},
	{
		id = "feat_diamond", key = "feat_diamond", kind = "deal",
		title = "Diamond Stack", icon = "super_lucky_block",
		credits = 360,
		starts = START + 2 * WEEK, ends = START + 4 * WEEK,
		blocks = { { id = "super_lucky_block", qty = 3 } },
		blurb = "3 Diamond Blocks for 2 weeks. 360 credits.",
		toast = "Diamond Stack claimed",
	},
	{
		id = "feat_mythic", key = "feat_mythic", kind = "deal",
		title = "Godly Cube", icon = "godly_lucky_block",
		credits = 280,
		starts = START + 3 * WEEK, ends = START + 5 * WEEK,
		blocks = { { id = "godly_lucky_block", qty = 1 } },
		blurb = "1 Godly Block for 2 weeks. 280 credits.",
		toast = "Godly Cube claimed",
	},
	{
		id = "feat_lucky_late", key = "feat_lucky_late", kind = "deal",
		title = "Lucky Stack", icon = "lucky_block",
		credits = 350,
		starts = START + 4 * WEEK, ends = ENDS,
		blocks = { { id = "lucky_block", qty = 10 } },
		blurb = "10 Lucky Blocks through Oct 31. 350 credits.",
		toast = "Lucky Stack claimed",
	},
}

--[[
	ONE MORE WEEK, ON EVERYTHING.

	Applied as a pass over the table rather than by editing seven `ends`
	fields, so the windows keep reading as START + n * WEEK -- which is how
	they were designed and how the next person will expect to read them -- and
	extending again is one number instead of seven edits.

	SEASON_END moves with them. Two offers end AT the season end, so leaving
	it put would have pushed them past the season they belong to.
]]
MineRotatingOffers.EXTEND_SEC = WEEK
do
	for _, o in ipairs(MineRotatingOffers.OFFERS) do
		if tonumber(o.ends) then
			o.ends = o.ends + MineRotatingOffers.EXTEND_SEC
		end
	end
	MineRotatingOffers.SEASON_END = ENDS + MineRotatingOffers.EXTEND_SEC
end

function MineRotatingOffers.isLive(offer, now)
	now = now or Launch.seasonNow()
	if type(offer) ~= "table" then
		return false
	end
	return now >= (offer.starts or 0) and now < (offer.ends or 0)
end

function MineRotatingOffers.byId(id)
	id = tostring(id or "")
	for _, row in ipairs(MineRotatingOffers.OFFERS) do
		if row.id == id or row.key == id then
			return row
		end
	end
	return nil
end

function MineRotatingOffers.bought(p, offer)
	local n = p and p.dealBuys and offer and p.dealBuys[offer.id]
	return math.max(0, math.floor(tonumber(n) or 0))
end

function MineRotatingOffers.deny(p, offer)
	if not offer then
		return "Unknown deal"
	end
	if offer.max and MineRotatingOffers.bought(p, offer) >= offer.max then
		return string.format("Max %d per player", offer.max)
	end
	return nil
end

function MineRotatingOffers.grant(p, offer)
	if MineRotatingOffers.deny(p, offer) then
		return false
	end
	p.dealBuys = p.dealBuys or {}
	p.dealBuys[offer.id] = MineRotatingOffers.bought(p, offer) + 1
	p.packs = p.packs or {}
	for _, block in ipairs(offer.blocks or {}) do
		LuckyBlocks.grant(p, block.id, "F", block.qty or 1)
	end
	if offer.pet then
		p.ownedPets = p.ownedPets or {}
		local cur = p.ownedPets.lucky_block
		local n = (cur == true) and 1 or math.max(0, math.floor(tonumber(cur) or 0))
		local room = 3 - n
		if room > 0 then
			p.ownedPets.lucky_block = n + math.min(offer.pet, room)
		end
	end
	if offer.charm then
		p.charms = p.charms or {}
		p.charms[offer.charm] = true
	end
	local nShiny = math.floor(tonumber(offer.shinyPacks) or 0)
	if nShiny > 0 then
		local packId = ZonePacks.id("meadow", "pack_legendary")
		for _ = 1, nShiny do
			table.insert(p.packs, {
				packId = packId,
				packName = "Shiny Pack",
				zoneId = "meadow",
				setId = "dragons_dawn",
				luck = 3,
				shiny = 100,
			})
		end
	end
	do
		local Packs = require(script.Parent:WaitForChild("MinePackConfig"))
		for _, row in ipairs(offer.packs or {}) do
			local id = tostring(row.id or "")
			local def = Packs.PACK_BY_ID and Packs.PACK_BY_ID[id]
			for _ = 1, math.max(1, math.floor(tonumber(row.qty) or 1)) do
				table.insert(p.packs, {
					packId = id,
					packName = (def and def.name) or id,
					setId = "dragons_dawn",
				})
			end
		end
	end
	for _, row in ipairs(offer.potions or {}) do
		pcall(function()
			require(script.Parent:WaitForChild("MinePotions")).grant(p, row.id, row.qty or 1)
		end)
	end
	return true
end

function MineRotatingOffers.dayKey(now)
	now = now or Launch.seasonNow()
	local left = math.max(0, ENDS - now)
	local days = math.floor(left / 86400)
	return string.format("%dd left in the season", days)
end

function MineRotatingOffers.active(now)
	now = now or Launch.seasonNow()
	local out = {}
	for _, row in ipairs(MineRotatingOffers.OFFERS) do
		if MineRotatingOffers.isLive(row, now) then
			local copy = table.clone(row)
			copy.dayKey = MineRotatingOffers.dayKey(now)
			table.insert(out, copy)
		end
	end
	return out
end

function MineRotatingOffers.headline(now)
	local rows = MineRotatingOffers.active(now)
	local titles = {}
	for _, r in ipairs(rows) do
		table.insert(titles, r.title)
	end
	if #titles == 0 then
		return "Season shelf is quiet"
	end
	return table.concat(titles, " · ")
end

return MineRotatingOffers
