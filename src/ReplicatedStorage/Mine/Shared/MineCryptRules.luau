--[[
	MineCryptRules -- the Candy Crypt's rules, in one place both sides read.

	The owner's design, 2026-10-19, twice: the first redesign (wiki/open-
	questions.md §0e) and "Candy Crypt v2" the same day, which replaced much of
	it. v2, in short:
	  * Candy blocks only; sixteen candy ores two per rarity; a fixed ore drop
	    and a flat candy amount per ore (MineConfig.CANDY_ECONOMY).
	  * Only Halloween tools dig the Crypt. They are CRAFTED at the Forge from
	    candy ores and PRESTIGED 1-10 with more of that ore; at most ten;
	    scrapping pays half their ore's candy value (MineCandyTools).
	  * Eight Crypt chests, F to SSS, paying Halloween packs, flat candy, the
	    rank's Halloween charm (0.5% x Chest Luck) and Halloween enchant books
	    (MineCryptChests).
	  * The Trick-or-Treat case pays Halloween pets and skins, then a 50/50
	    TREAT or TRICK (MineTrickOrTreat).
	  * A SEPARATE HALLOWEEN INVENTORY while the event runs: Halloween pets
	    (and their own team), Halloween tools, candy ores and Halloween charms
	    live there and are what counts inside the Crypt; skins and hats are
	    shared. When the event ends it all moves into the main inventory.
	  * Halloween tools, candy ores and Halloween-inventory items cannot be
	    traded while the event runs.

	The SERVER (ServerScriptService/Mine/MineCrypt) is the authority for every
	roll, payout, price and gate and calls these. The CLIENT reads the same
	functions to draw the screens, so a number on a card is the number the
	server uses.

	WHAT IS HERE (the client may call any of these):

	  ZONE_ID, EVENT_ID, CURRENCY      "hallow", "candy_crypt", "candy"
	  NOTICE / noticeFor(zoneId)       the first-entry pop-up: { title, text }
	  window(now)                      { opensAt, closesAt, open, ended }
	  separate(p, now)                 is the Halloween inventory its own?
	  isHalloweenItem(kind, x)         pet/card, tool, ore, charm, skin, pack
	  toolTable(), toolDef(id)         the sixteen Halloween tools
	  prestigeLadder(def, dig)         damage at P0..P10, in the Crypt and out
	  craftPlan / prestigePlan / scrapPlan   what a verb would do, or why not
	  heldRow(p, zoneId, now)          THE swap rule (see below)
	  teamFor(p, zoneId, now)          the pets that count where you stand
	  charmFor(p, zoneId, now)         the charm that counts where you stand
	  casePrize(roll, rng), caseOdds() the Trick-or-Treat case
	  chestOdds(layer, chestLuck)      a Crypt chest's ranks and its charm chance
	  candyOreRows(ores, locks, seen)  the sixteen candy ores and what you hold
	  inventoryOf(p, now)              the Halloween inventory, for a screen
	  stateFor(p, now)                 the snapshot's `crypt` block

	THE SAVE (MineCrypt keeps it straight; nothing here writes):

	  p.halloween = {
	    tools  = { { uid, id, prestige, spent = { [oreId] = n } } },
	    tool   = uid in hand, or nil
	    ores   = { [candyOreId] = n }      candy ores, while the event runs
	    team   = { cardId, ... }           the Halloween pet team
	    charm  = charmId or nil            the Halloween charm worn in the Crypt
	    seen   = { [candyOreId] = true }   candy ores ever dug
	    moved  = true once the event-end move has run
	  }
	  p.cryptToolWorld     true = hold the Halloween tool in the main world too
	  p.eventNoticeSeen    { [zoneId] = true } once the pop-up is dismissed

	EVERY NUMBER HERE NOT QUOTED FROM THE OWNER IS PROPOSED (2026-10-19).
]]
local R = {}

local shared = script.Parent
local C = require(shared:WaitForChild("MineConfig"))
local Tools = require(shared:WaitForChild("MineCandyTools"))
local Chests = require(shared:WaitForChild("MineCryptChests"))
local TT = require(shared:WaitForChild("MineTrickOrTreat"))
local Breaking = require(shared:WaitForChild("MineBreaking"))
local Charms = require(shared:WaitForChild("MineCharms"))

R.ZONE_ID = "hallow"
R.EVENT_ID = "candy_crypt"
R.CURRENCY = "candy"
-- The Halloween pets' set (the Halloween 2026 Pack's) and the skins' set key.
R.PET_SET = "halloween_2026"
R.SKIN_SET = "halloween"
R.TOOL_CAP = Tools.CAP

--[[
	THE FIRST-ENTRY POP-UP (owner, 2026-10-19), once per event per player, plus
	the same text behind an (i) on the event's card. The wording is the
	owner-approved line from the build spec.
]]
R.NOTICE = {
	title = "Only event tools work here",
	text = "Only event tools work here. Tools you find are yours to keep: when "
		.. "the event ends they work in the main world too (weaker).",
}
R.NOTICES = { hallow = R.NOTICE }

function R.noticeFor(zoneId)
	return R.NOTICES[tostring(zoneId or "")] or R.NOTICE
end

-- Said when a player asks to hold a Halloween tool outside before the event ends.
R.WORLD_LOCKED_TEXT = "Halloween tools work in the main world once the Candy Crypt closes."
-- Said when a Halloween pet is put on the main team while the event runs.
R.MAIN_TEAM_TEXT = "Halloween pets go on your Halloween team until the event ends."
R.TRADE_LOCKED_TEXT = "Halloween items can be traded once the Candy Crypt closes."

--------------------------------------------------------------------------------
-- THE WINDOW
--------------------------------------------------------------------------------

--[[
	The Crypt's own window, on the WALL clock (LIMITED_WINDOWS.hallow carries
	calendar dates; owner, 2026-10-10). `now` is optional: the server passes
	nothing (os.time); a client should pass workspace:GetServerTimeNow().

	`ended` is what turns the main-world use on and moves the Halloween
	inventory into the main one. LIMITED_START_UNIX <= 0 is the dev switch
	MineConfig.limitedActive treats as "everything open", and it is honoured
	the same way here, so the two never disagree.
]]
function R.window(now)
	local opens, closes = nil, nil
	if C.limitedWindow then
		opens, closes = C.limitedWindow(R.ZONE_ID)
	end
	local t = tonumber(now) or os.time()
	local open, ended = false, false
	if (tonumber(C.LIMITED_START_UNIX) or 0) <= 0 then
		open = true
	elseif opens and closes then
		open = t >= opens and t < closes
		ended = t >= closes
	end
	return { opensAt = opens, closesAt = closes, open = open, ended = ended }
end

local function inv(p)
	return type(p) == "table" and type(p.halloween) == "table" and p.halloween or nil
end

--[[
	IS THE HALLOWEEN INVENTORY ITS OWN? Until the event ends and the move has
	run (owner: "When the event ends, everything in it moves into the main
	inventory"). Before the window opens it is separate too, and empty.
]]
function R.separate(p, now)
	local h = inv(p)
	if h and h.moved then
		return false
	end
	return not R.window(now).ended
end

-- The candy-ore store to read: the Halloween inventory's, or after the move
-- the main pouch (p.ores).
function R.oreStore(p, now)
	if type(p) ~= "table" then
		return {}
	end
	if R.separate(p, now) then
		local h = inv(p)
		return (h and type(h.ores) == "table") and h.ores or {}
	end
	return type(p.ores) == "table" and p.ores or {}
end

--------------------------------------------------------------------------------
-- WHAT IS A HALLOWEEN ITEM
--------------------------------------------------------------------------------

--[[
	Optional modules, looked up once: another agent's (MineHalloweenPets) or a
	heavy one (MineSkins). boosts() reaches teamFor on every swing, so this must
	not search the tree each time. `false` caches "not in this build".
]]
local lazyCache = {}
local function lazy(name)
	local hit = lazyCache[name]
	if hit ~= nil then
		return hit or nil
	end
	local ok, m = pcall(function()
		local node = shared:FindFirstChild(name)
		return node and require(node) or nil
	end)
	hit = (ok and type(m) == "table") and m or false
	lazyCache[name] = hit
	return hit or nil
end

-- The Halloween 2026 Pack's pet list (HolidayPets/Halloween2026), or nil.
local function holidayList()
	local hit = lazyCache["HolidayPets/Halloween2026"]
	if hit ~= nil then
		return hit or nil
	end
	local ok, m = pcall(function()
		local folder = shared:FindFirstChild("HolidayPets")
		local node = folder and folder:FindFirstChild("Halloween2026")
		return node and require(node) or nil
	end)
	hit = (ok and type(m) == "table") and m or false
	lazyCache["HolidayPets/Halloween2026"] = hit
	return hit or nil
end

local function isHalloweenCard(card)
	if type(card) ~= "table" then
		return false
	end
	local HP = lazy("MineHalloweenPets")
	if HP and type(HP.isHalloween) == "function" then
		local ok, yes = pcall(HP.isHalloween, card)
		if ok then
			return yes == true
		end
	end
	if card.holiday == "halloween" or card.setId == R.PET_SET then
		return true
	end
	local key = type(card.cardKey) == "string" and card.cardKey or ""
	return string.sub(key, 1, #R.PET_SET + 1) == R.PET_SET .. ":"
end

-- The ids of the eight Crypt chest charms (MineCharms.cryptChestCharm, another
-- agent's), cached once read.
local chestCharmIds = nil
local function cryptChestCharmIds()
	if chestCharmIds then
		return chestCharmIds
	end
	local out = {}
	if type(Charms.cryptChestCharm) == "function" then
		for _, rank in ipairs(Chests.RANKS) do
			local ok, id = pcall(Charms.cryptChestCharm, rank.key)
			if ok and type(id) == "table" then
				id = id.id
			end
			if ok and type(id) == "string" and id ~= "" then
				out[id] = rank.key
			end
		end
		chestCharmIds = out
	end
	return out
end
R.cryptChestCharmIds = cryptChestCharmIds

local function isHalloweenCharm(id)
	id = (type(id) == "table" and id.id) or id
	if type(id) ~= "string" or id == "" then
		return false
	end
	if cryptChestCharmIds()[id] then
		return true
	end
	local def = Charms.byId(id)
	return type(def) == "table" and (def.holiday == "halloween" or def.event == "halloween"
		or def.crypt == true or def.source == "crypt") or false
end

--[[
	IS THIS A HALLOWEEN ITEM? (the cross-agent contract). `kind` is one of:
	  "pet" / "card"   x = a card table (MineHalloweenPets.isHalloween when it
	                   exists; else the Halloween 2026 set, by setId or cardKey)
	  "tool"           x = a Halloween tool id, or a tool entry / row
	  "ore"            x = a candy ore id
	  "charm"          x = a charm id (a Crypt chest charm, or a charm def
	                   marked halloween / crypt)
	  "skin"           x = a skin id or def of the Halloween set
	  "pack"           x = a pack id or bag row of the Halloween pack
]]
function R.isHalloweenItem(kind, x)
	kind = tostring(kind or "")
	if kind == "pet" or kind == "card" or kind == "cards" then
		return isHalloweenCard(x)
	elseif kind == "tool" or kind == "tools" then
		local id = (type(x) == "table" and (x.id or x.toolId)) or x
		return Tools.byId(id) ~= nil
	elseif kind == "ore" or kind == "ores" then
		local id = (type(x) == "table" and x.id) or x
		return C.candyOreById(id) ~= nil
	elseif kind == "charm" or kind == "charms" then
		return isHalloweenCharm(x)
	elseif kind == "skin" or kind == "skins" then
		local def = x
		if type(x) == "string" then
			local Skins = lazy("MineSkins")
			def = Skins and Skins.byId and Skins.byId(x) or nil
		end
		return type(def) == "table" and def.set == R.SKIN_SET
	elseif kind == "pack" or kind == "packs" then
		local id = (type(x) == "table" and x.packId) or x
		return id == Chests.PACK_ID
	end
	return false
end

--------------------------------------------------------------------------------
-- HALLOWEEN TOOLS
--------------------------------------------------------------------------------

function R.toolTable()
	return Tools.all()
end

function R.toolDef(id)
	return Tools.byId(id)
end

-- The tool entries a player owns (the save's rows), in save order.
function R.ownedTools(p)
	local h = inv(p)
	local out = {}
	for _, t in ipairs((h and type(h.tools) == "table") and h.tools or {}) do
		if type(t) == "table" and type(t.uid) == "string" and Tools.byId(t.id) then
			table.insert(out, t)
		end
	end
	return out
end

function R.findTool(p, uid)
	for i, t in ipairs(R.ownedTools(p)) do
		if t.uid == uid then
			return t, i
		end
	end
	return nil
end

-- The entry in hand, if the player owns it. Never trusts the uid alone.
function R.equippedEntry(p)
	local h = inv(p)
	local uid = h and h.tool
	if type(uid) ~= "string" then
		return nil
	end
	local t = R.findTool(p, uid)
	if not t then
		return nil
	end
	return t, Tools.byId(t.id)
end

--[[
	Event Digging from the charm that counts in the Crypt (a Halloween charm),
	as a fraction: 0.42 means +42%. Read off the charm, not off boosts():
	boosts() asks what is held, and what is held asks this, so going through
	boosts would loop.
]]
function R.eventDigOf(p)
	local id = R.charmFor(p, R.ZONE_ID, nil)
	local def = (type(id) == "string" and id ~= "") and Charms.byId(id) or nil
	local v = def and type(def.stats) == "table" and tonumber(def.stats.eventDig)
	return math.max(0, v or 0)
end

--[[
	A TOOL'S DAMAGE AT EVERY PRESTIGE (owner: "each tool shows its damage at
	every prestige"): { [1] = P0, ..., [11] = P10 }, each
	  { prestige, crypt, world, worldTier, worldLevel, worldOre, cost }
	`cost` is what that prestige step costs in the tool's ore (nil at P0).
]]
function R.prestigeLadder(def, dig)
	local out = {}
	if type(def) ~= "table" then
		return out
	end
	for k = 0, Tools.PRESTIGE_MAX do
		local tier, level, ore = Tools.worldEquivalent(def, k)
		table.insert(out, {
			prestige = k,
			crypt = Tools.cryptPower(def, k, dig),
			world = Tools.worldPower(def, k, dig),
			worldTier = tier,
			worldLevel = level,
			worldOre = ore and ore.name or nil,
			cost = (k > 0) and Tools.prestigeCost(def, k) or nil,
		})
	end
	return out
end

local function baseRow(def, entry)
	local row = table.clone(def)
	local k = Tools.clampPrestige(entry and entry.prestige)
	row.uid = entry and entry.uid or nil
	row.prestige = k
	row.baseName = def.name
	-- MineToolSkins.wear multiplies a Halloween-set skin's whole multiplier by
	-- this (owner: "always multiplier to the full multiplier").
	row.halloweenSkinFactor = def.skinFactor
	row.cryptTool = true
	return row
end

--[[
	The row the server swings INSIDE an event mine. `eventMine` is what
	MineSpaceMatter keys the event-only rule on: this row spends that mine's
	rock and nothing else. No breaking power: those mines have no strength gate
	(`noStrengthGate`), the HP is the gate.
]]
function R.eventRow(def, entry, zoneId, dig)
	local row = baseRow(def, entry)
	row.power = Tools.cryptPower(def, row.prestige, dig)
	row.eventMine = zoneId or R.ZONE_ID
	return row
end

-- The row the server swings in the MAIN world once the event has ended.
function R.worldRow(def, entry, dig)
	local row = baseRow(def, entry)
	local tier, level = Tools.worldEquivalent(def, row.prestige)
	row.power = Tools.worldPower(def, row.prestige, dig)
	row.breakingPower = Breaking.oreStrength(tier, #(C.ORES or {}))
	row.worldTier, row.worldLevel = tier, level
	row.world = true
	return row
end

--[[
	EMPTY HANDS IN AN EVENT MINE. Somebody with no Halloween tool (which a claim
	prevents, so this is a broken-save guard) holds nothing: `none` keeps
	givePickaxe from building a model, and the event-only rule refuses the swing
	with "Only event tools work here."
]]
R.NONE_ROW = {
	id = "crypt_none",
	name = "No event tool",
	family = "pickaxe",
	tier = 0,
	power = 0,
	rate = 1,
	cells = 1,
	radius = 0,
	shape = "melee",
	none = true,
	cryptNone = true,
}

-- Rows are read-only to every caller, so they are cached: equippedTool runs
-- several times a swing.
local rowCache = {}
local function cachedRow(kind, def, entry, zoneId, dig)
	local k = kind .. "|" .. def.id .. "|" .. tostring(entry.uid) .. "|" .. tostring(entry.prestige)
		.. "|" .. tostring(zoneId) .. "|" .. tostring(dig)
	local hit = rowCache[k]
	if hit then
		return hit
	end
	if kind == "event" then
		hit = R.eventRow(def, entry, zoneId, dig)
	else
		hit = R.worldRow(def, entry, dig)
	end
	rowCache[k] = hit
	return hit
end

--[[
	THE SWAP RULE: what a player holds, given where they stand.

	  In an event-tools-only mine (the Crypt; any later one that sets the flag):
	    their Halloween tool in hand, at Crypt power -- in the Crypt always, in
	    a later event mine once the Crypt has ended ("and in future events").
	    No Halloween tool: NONE_ROW, empty hands.
	  In Event Horizon: nil. It keeps its own tools and rules (owner: "Crypt
	    only for now").
	  Anywhere else: their Halloween tool at WORLD power, but only once the
	    Crypt has ended AND they chose to hold it there (`cryptToolWorld`).
	    During the event Halloween tools do nothing out here.
	  Otherwise nil, and the normal tool chain decides.

	Returns row, family, tier -- the shape equippedTool returns.
]]
function R.heldRow(p, zoneId, now)
	if type(p) ~= "table" then
		return nil
	end
	local zid = tostring(zoneId or "")
	local zone = C.zoneById and C.zoneById(zid)
	if zone and zone.id ~= zid then
		zone = nil
	end
	local w = nil
	local entry, def = R.equippedEntry(p)
	if zone and zone.eventToolsOnly then
		if entry and def then
			local allowed = zid == R.ZONE_ID
			if not allowed then
				w = R.window(now)
				allowed = w.ended
			end
			if allowed then
				return cachedRow("event", def, entry, zid, R.eventDigOf(p)), def.family, def.rank
			end
		end
		return R.NONE_ROW, "pickaxe", 0
	end
	if zid == "bigbang" then
		return nil
	end
	if entry and def and p.cryptToolWorld == true then
		w = w or R.window(now)
		if w.ended then
			return cachedRow("world", def, entry, nil, R.eventDigOf(p)), def.family, def.rank
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- CRAFT, PRESTIGE, SCRAP: what a verb would do, or why not
--------------------------------------------------------------------------------

--[[
	Each returns a plan, or nil and a player-facing reason (the server toasts it
	as written). The server applies the plan it is given, so the number a
	player agreed to is the number paid.
]]
function R.craftPlan(p, toolId, now)
	local def = Tools.byId(toolId)
	if not def then
		return nil, "That tool is not in the game"
	end
	local w = R.window(now)
	if w.ended and not Tools.CRAFT_AFTER_EVENT then
		return nil, "Halloween tools are crafted while the Candy Crypt is open"
	end
	if #R.ownedTools(p) >= Tools.CAP then
		return nil, ("You have %d Halloween tools -- scrap one to craft another"):format(Tools.CAP)
	end
	local store = R.oreStore(p, now)
	local have = math.max(0, math.floor(tonumber(store[def.oreId]) or 0))
	if have < def.craft then
		return nil, ("Need %d %s (you have %d)"):format(def.craft, def.oreName, have)
	end
	return { def = def, oreId = def.oreId, cost = def.craft, have = have }
end

function R.prestigePlan(p, uid, now)
	local entry = R.findTool(p, uid)
	local def = entry and Tools.byId(entry.id)
	if not def then
		return nil, "You do not have that tool"
	end
	local k = Tools.clampPrestige(entry.prestige)
	if k >= Tools.PRESTIGE_MAX then
		return nil, ("%s is already at prestige %d"):format(def.name, Tools.PRESTIGE_MAX)
	end
	local cost = Tools.prestigeCost(def, k + 1)
	local store = R.oreStore(p, now)
	local have = math.max(0, math.floor(tonumber(store[def.oreId]) or 0))
	if have < cost then
		return nil, ("Need %d %s (you have %d)"):format(cost, def.oreName, have)
	end
	return { def = def, entry = entry, oreId = def.oreId, cost = cost, have = have, to = k + 1 }
end

function R.scrapPlan(p, uid)
	local entry = R.findTool(p, uid)
	local def = entry and Tools.byId(entry.id)
	if not def then
		return nil, "You do not have that tool"
	end
	if #R.ownedTools(p) <= 1 then
		return nil, "Keep at least one Halloween tool: it is how you dig the Crypt"
	end
	return { def = def, entry = entry, candy = Tools.scrapCandy(def, entry.prestige, entry.spent) }
end

--------------------------------------------------------------------------------
-- PETS AND CHARMS THAT COUNT
--------------------------------------------------------------------------------

local function cardById(p, id)
	for _, c in ipairs(type(p) == "table" and type(p.cards) == "table" and p.cards or {}) do
		if type(c) == "table" and c.id == id then
			return c
		end
	end
	return nil
end
R.cardById = cardById

local function inCrypt(p, zoneId)
	return tostring(zoneId or (type(p) == "table" and p.zoneId) or "") == R.ZONE_ID
end

--[[
	THE PETS THAT COUNT WHERE YOU STAND (owner: "only Halloween pets count in
	the Crypt"; a separate Halloween pet team while the event runs).

	  In the Crypt, during the event: the Halloween team.
	  In the Crypt, after it: the Halloween pets on your (main) team.
	  Anywhere else, during the event: your main team WITHOUT Halloween pets
	    (they are in the Halloween inventory).
	  Anywhere else, after it: your main team, as it is.
	Returns a list of card ids (a new table, safe to keep).
]]
function R.teamFor(p, zoneId, now)
	if type(p) ~= "table" then
		return {}
	end
	local sep = R.separate(p, now)
	local out = {}
	if inCrypt(p, zoneId) then
		local h = inv(p)
		local src = (sep and h and type(h.team) == "table") and h.team or (not sep and p.equipped) or {}
		for _, id in ipairs(src) do
			local c = cardById(p, id)
			if c and isHalloweenCard(c) then
				table.insert(out, id)
			end
		end
		return out
	end
	for _, id in ipairs(type(p.equipped) == "table" and p.equipped or {}) do
		if not sep or not isHalloweenCard(cardById(p, id)) then
			table.insert(out, id)
		end
	end
	return out
end

--[[
	THE CHARM THAT COUNTS WHERE YOU STAND. In the Crypt only a Halloween charm
	counts: during the event the Halloween inventory's slot, after it the main
	slot if it holds a Halloween charm. Elsewhere the main slot, unless it holds
	a Halloween charm while the event runs (that charm lives in the Halloween
	inventory). nil means no charm applies.
]]
function R.charmFor(p, zoneId, now)
	if type(p) ~= "table" then
		return nil
	end
	local sep = R.separate(p, now)
	local main = (type(p.equippedCharm) == "string" and p.equippedCharm ~= "") and p.equippedCharm or nil
	if inCrypt(p, zoneId) then
		if sep then
			local h = inv(p)
			local id = h and h.charm
			return (type(id) == "string" and isHalloweenCharm(id)) and id or nil
		end
		return (main and isHalloweenCharm(main)) and main or nil
	end
	if main and sep and isHalloweenCharm(main) then
		return nil
	end
	return main
end

-- Halloween charms the player owns (p.charms tallies), name order.
function R.halloweenCharms(p)
	local out = {}
	for id, n in pairs(type(p) == "table" and type(p.charms) == "table" and p.charms or {}) do
		local count = (n == true) and 1 or math.max(0, math.floor(tonumber(n) or 0))
		if count > 0 and isHalloweenCharm(id) then
			local def = Charms.byId(id)
			table.insert(out, {
				id = id,
				name = def and def.name or id,
				rarity = def and def.rarity or nil,
				rank = cryptChestCharmIds()[id],
				n = count,
			})
		end
	end
	table.sort(out, function(a, b)
		return a.name < b.name
	end)
	return out
end

-- Halloween pets the player owns: their card ids, in bag order.
function R.halloweenPets(p)
	local out = {}
	for _, c in ipairs(type(p) == "table" and type(p.cards) == "table" and p.cards or {}) do
		if type(c) == "table" and c.id and isHalloweenCard(c) then
			table.insert(out, c.id)
		end
	end
	return out
end

-- Pet seats on a team (the main team's: C.effectivePetSlots).
function R.teamCap(p)
	return math.max(1, math.floor(tonumber(C.effectivePetSlots and C.effectivePetSlots(p)
		or (type(p) == "table" and p.petSlots) or 3) or 3))
end

--------------------------------------------------------------------------------
-- THE TRICK-OR-TREAT CASE
--------------------------------------------------------------------------------

--[[
	The Halloween pets of one rarity, as roster rows ({ name, tier, animal,
	... }): MineHalloweenPets.pool (another agent's) when it exists, else the
	Halloween 2026 Pack's own list.
]]
function R.petPool(rarity)
	local HP = lazy("MineHalloweenPets")
	if HP and type(HP.pool) == "function" then
		local ok, rows = pcall(HP.pool, rarity)
		if ok and type(rows) == "table" then
			local out = {}
			for _, r in ipairs(rows) do
				if type(r) == "table" and (rarity == nil or (r.tier or r.rarityId or r.rarity) == rarity) then
					table.insert(out, r)
				end
			end
			return out
		end
	end
	local list = holidayList()
	local out = {}
	for _, r in ipairs((list and list.PETS) or {}) do
		if rarity == nil or r.tier == rarity then
			table.insert(out, r)
		end
	end
	return out
end

-- The Halloween-set skins of one tier (F..SSS), never a pass skin.
function R.skinPool(tier)
	local Skins = lazy("MineSkins")
	local out = {}
	for _, s in ipairs((Skins and Skins.LIST) or {}) do
		if s.set == R.SKIN_SET and not s.pass and (tier == nil or s.tier == tier) then
			table.insert(out, s)
		end
	end
	return out
end

local function pickOne(list, rng)
	if #list == 0 then
		return nil
	end
	local i = (rng and rng.NextInteger) and rng:NextInteger(1, #list) or math.random(1, #list)
	return list[math.clamp(i, 1, #list)]
end

--[[
	WHICH prize a roll (MineTrickOrTreat.roll) names: a Halloween pet or skin of
	its rarity. A rarity with nothing of that kind steps down a rung, then the
	other kind is tried, so an open always names a real prize. Returns
	  { kind = "pet", rarityIndex, rarity, pet = <roster row>, name }
	  { kind = "skin", rarityIndex, rarity, skin = <skin def>, name }
	or nil when there is nothing Halloween to give at all.
]]
function R.casePrize(roll, rng)
	if type(roll) ~= "table" then
		return nil
	end
	local order = { roll.kind, (roll.kind == "pet") and "skin" or "pet" }
	for _, kind in ipairs(order) do
		for idx = math.floor(tonumber(roll.rarityIndex) or 1), 1, -1 do
			local rung = TT.rarity(idx)
			if rung then
				if kind == "pet" then
					local pet = pickOne(R.petPool(rung.pet), rng)
					if pet then
						return { kind = "pet", rarityIndex = idx, rarity = rung.pet, pet = pet, name = pet.name }
					end
				else
					local skin = pickOne(R.skinPool(rung.skin), rng)
					if skin then
						return { kind = "skin", rarityIndex = idx, rarity = rung.skin, skin = skin, name = skin.name }
					end
				end
			end
		end
	end
	return nil
end

--[[
	The odds sheet (MineTrickOrTreat.odds), plus how many Halloween pets and
	skins each rarity can be, so the sheet can say "1 of 20".
]]
function R.caseOdds()
	local sheet = TT.odds()
	for _, row in ipairs(sheet.rows) do
		row.pets = #R.petPool(row.pet)
		row.skins = #R.skinPool(row.skin)
	end
	return sheet
end

--------------------------------------------------------------------------------
-- CHESTS
--------------------------------------------------------------------------------

--[[
	A Crypt chest at this layer, for an odds sheet: each rank's chance (F
	first) and the charm chance after Chest Luck.
]]
function R.chestOdds(layer, chestLuck)
	local odds = Chests.rankOdds(Chests.section(layer))
	local ranks = {}
	for i, r in ipairs(Chests.RANKS) do
		table.insert(ranks, {
			key = r.key,
			name = r.name,
			pct = (odds[i] or 0) * 100,
			packs = r.packs,
			luck = r.luck,
			candy = r.candy,
		})
	end
	return { ranks = ranks, charm = Chests.charmChance(chestLuck) }
end

--------------------------------------------------------------------------------
-- CANDY ORES
--------------------------------------------------------------------------------

-- Candy for one item (MineConfig.candyOreValue). 0 for anything not candy.
function R.candyOreValue(id)
	return C.candyOreValue and C.candyOreValue(id) or 0
end

-- All sixteen candy ores with what the player holds, for the Halloween
-- inventory and the candy-sell screen. Always sixteen rows, in ladder order.
function R.candyOreRows(ores, locks, seen)
	local out = {}
	for _, o in ipairs(C.CANDY_ORES or {}) do
		local n = math.max(0, math.floor(tonumber((ores or {})[o.id]) or 0))
		local each = R.candyOreValue(o)
		table.insert(out, {
			id = o.id,
			name = o.name,
			rank = o.rank,
			band = o.band,
			bandIndex = o.bandIndex,
			drop = o.drop,
			blockCandy = o.candy,
			n = n,
			candyEach = each,
			candyValue = each * n,
			locked = (locks or {})[o.id] and true or false,
			seen = (n > 0) or ((seen or {})[o.id] == true),
		})
	end
	return out
end

--------------------------------------------------------------------------------
-- THE HALLOWEEN INVENTORY, AND THE SNAPSHOT
--------------------------------------------------------------------------------

-- One owned tool, as a screen draws it.
local function toolView(p, entry, dig, heldUid, store)
	local def = Tools.byId(entry.id)
	local k = Tools.clampPrestige(entry.prestige)
	local nextCost = (k < Tools.PRESTIGE_MAX) and Tools.prestigeCost(def, k + 1) or nil
	local have = math.max(0, math.floor(tonumber(store[def.oreId]) or 0))
	local tier, level, ore = Tools.worldEquivalent(def, k)
	return {
		uid = entry.uid,
		id = def.id,
		name = def.name,
		family = def.family,
		rank = def.rank,
		band = def.band,
		rarityId = def.rarityId,
		oreId = def.oreId,
		oreName = def.oreName,
		prestige = k,
		prestigeMax = Tools.PRESTIGE_MAX,
		power = Tools.cryptPower(def, k, dig),
		worldPower = Tools.worldPower(def, k, dig),
		worldTier = tier,
		worldLevel = level,
		worldOre = ore and ore.name or nil,
		worldBreakingPower = Breaking.oreStrength(tier, #(C.ORES or {})),
		nextCost = nextCost,
		canPrestige = nextCost ~= nil and have >= nextCost,
		scrapCandy = Tools.scrapCandy(def, k, entry.spent),
		skinFactor = def.skinFactor,
		equipped = heldUid == entry.uid,
		icon = def.icon or "",
		cryptTool = true,
	}
end
-- (No damage ladder on the row: the snapshot flushes up to ten times a second
-- while digging, and the ladder never changes. A screen calls
-- prestigeLadder(toolDef(row.id), dig) itself.)

--[[
	THE HALLOWEEN INVENTORY, as a screen draws it (the contract's
	MineCrypt.inventoryOf serves this):

	  separate   true while it is its own inventory (the event runs)
	  tools      owned Halloween tools, best first (toolView rows)
	  tool       the uid in hand, or nil
	  toolCount / toolCap
	  ores       the sixteen candy ores (candyOreRows), from oreStore
	  pets       Halloween pet card ids (they live in p.cards)
	  team / teamCap   the Halloween pet team (card ids) and its seats
	  charms     Halloween charms owned ({ id, name, rarity, rank, n })
	  charm      the Halloween charm worn in the Crypt, or nil
]]
function R.inventoryOf(p, now)
	if type(p) ~= "table" then
		return nil
	end
	local h = inv(p) or {}
	local dig = R.eventDigOf(p)
	local store = R.oreStore(p, now)
	local held = select(1, R.equippedEntry(p))
	local tools = {}
	for _, entry in ipairs(R.ownedTools(p)) do
		table.insert(tools, toolView(p, entry, dig, held and held.uid, store))
	end
	table.sort(tools, function(a, b)
		if a.rank ~= b.rank then
			return a.rank > b.rank
		end
		if a.prestige ~= b.prestige then
			return a.prestige > b.prestige
		end
		return a.uid < b.uid
	end)
	local sep = R.separate(p, now)
	local team = {}
	for _, id in ipairs(type(h.team) == "table" and h.team or {}) do
		table.insert(team, id)
	end
	return {
		separate = sep,
		tools = tools,
		tool = held and held.uid or nil,
		toolCount = #tools,
		toolCap = Tools.CAP,
		ores = R.candyOreRows(store, p.oreLocks, h.seen),
		pets = R.halloweenPets(p),
		team = team,
		teamCap = R.teamCap(p),
		charms = R.halloweenCharms(p),
		charm = (type(h.charm) == "string" and h.charm ~= "") and h.charm or nil,
	}
end

--[[
	The Forge's Halloween recipes: all sixteen tools, what each costs, what you
	hold of its ore, and whether a craft would go through (and if not, why).
]]
function R.recipes(p, now)
	local store = R.oreStore(p, now)
	local out = {}
	for _, def in ipairs(Tools.TOOLS) do
		local plan, why = R.craftPlan(p, def.id, now)
		table.insert(out, {
			id = def.id,
			name = def.name,
			family = def.family,
			rank = def.rank,
			band = def.band,
			oreId = def.oreId,
			oreName = def.oreName,
			cost = def.craft,
			have = math.max(0, math.floor(tonumber(store[def.oreId]) or 0)),
			canCraft = plan ~= nil,
			why = why,
			skinFactor = def.skinFactor,
			power = Tools.cryptPower(def, 0, 0),
			worldPower = Tools.worldPower(def, 0, 0),
			icon = def.icon or "",
		})
	end
	return out
end

--[[
	The `crypt` block of the snapshot. Per-player state; the static tables
	(tools, costs, odds, notice text) are the functions above.

	  zoneId, eventId          "hallow", "candy_crypt"
	  owned                    claimed (p.hallowOwned)
	  candy                    the balance
	  window                   { opensAt, closesAt, open, ended } (wall clock)
	  inventory                inventoryOf(p): tools, ores, pets, team, charms
	  recipes                  recipes(p): the sixteen crafts
	  equipped                 the Halloween tool's uid in hand, or nil
	  world / worldActive      chose to hold it outside / and the event has ended
	  noticeSeen               { [zoneId] = true }
	  candyOres                inventory.ores (kept at this key for the pouch)
	  sellUpTo                 the pouch's remembered SELL UP TO ceiling
	  casePrice                Trick-or-Treat price in candy
]]
function R.stateFor(p, now)
	if type(p) ~= "table" then
		return nil
	end
	local w = R.window(now)
	local inventory = R.inventoryOf(p, now)
	local seen = {}
	for zid, v in pairs(type(p.eventNoticeSeen) == "table" and p.eventNoticeSeen or {}) do
		if v then
			seen[zid] = true
		end
	end
	local settings = type(p.settings) == "table" and p.settings or {}
	return {
		zoneId = R.ZONE_ID,
		eventId = R.EVENT_ID,
		owned = p.hallowOwned == true,
		candy = math.max(0, math.floor(tonumber(p.candy) or 0)),
		window = w,
		inventory = inventory,
		recipes = R.recipes(p, now),
		equipped = inventory.tool,
		world = p.cryptToolWorld == true,
		worldActive = (p.cryptToolWorld == true) and w.ended,
		noticeSeen = seen,
		candyOres = inventory.ores,
		sellUpTo = settings.oreSellUpTo or "Everything",
		casePrice = TT.PRICE,
	}
end

return R
