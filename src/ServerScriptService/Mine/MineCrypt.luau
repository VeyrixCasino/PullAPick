--[[
	MineCrypt -- the Candy Crypt on the server ("Candy Crypt v2", owner,
	2026-10-19; wiki/open-questions.md). The rules and numbers are shared:
	MineCryptRules (the rules both sides read), MineCandyTools (the sixteen
	Halloween tools), MineCryptChests (the eight chests), MineTrickOrTreat (the
	case) and MineConfig.CANDY_ECONOMY (the candy ores). This module owns the
	profile, the grants and the verbs, and is the authority for every roll,
	payout, price and gate.

	MineServer wires it in as Verbs.Crypt (and Dig.Crypt, for the functions
	declared above Verbs) and calls:

	  init(ctx)                          ctx = { profiles, net, snap, markDirty,
	                                     givePickaxe, bumpStat, chestXp,
	                                     grantPet }; starts the event-end tick
	  normalize(p)                       on load: shape the save, retire v1,
	                                     move the Halloween inventory into the
	                                     main one once the event has ended,
	                                     repair a claim with no tool
	  dispatch(plr, action, payload)     every remote action starting "crypt"
	  heldTool(p)                        equippedTool's swap (MineCryptRules.heldRow)
	  petTeam(p) / charmFor(p)           what counts in boosts() where p stands
	  mainTeamRefuses(p, cardId)         the main team's equip refuses Halloween
	                                     pets while the event runs
	  onClaim(plr, p, zone)              the Crypt was just claimed: starter pick
	  onEnterZone(plr, p, zone, fromId)  re-give the held tool; first-entry pop-up
	  onBlockBroken(plr, p, part, kind, layer, bb)   a candy block's candy + ore
	  haulPoints(p, landed, layer)       the Crypt's low coin curve, for payDamage
	  chestSpawnDef(layer, rng)          which of the eight chests spawns here
	  openChest(plr, p, part, b)         what a Crypt chest pays
	  buyTrickOrTreat(plr)               buy and open one case
	  snapState(p)                       the snapshot's `crypt` block
	The cross-agent contract (owner's spec, 2026-10-19):
	  inventoryOf(p)                     the Halloween inventory (MineCryptRules)
	  tradeLocked(p, kind, id)           true for Halloween tools, candy ores and
	                                     Halloween-inventory items while the
	                                     event runs (TradeService asks)

	REMOTE ACTIONS (client -> server), all through net:FireServer(action, payload):

	  cryptCraft          { toolId }                       craft a Halloween tool
	  cryptPrestige       { uid }                          next prestige, paid in its ore
	  cryptScrap          { uid }, then { uid, confirm = true }   for candy
	  cryptEquip          { uid }                          hold that Halloween tool
	                      { world = true | false }         hold it in the main world
	                                                       (refused until the event ends)
	  cryptTeam           { ids = { cardId, ... } }        the Halloween pet team
	  cryptCharm          { charmId } / { charmId = "" }   wear / take off the
	                                                       Halloween charm
	  cryptSellCandyOres  { oreIds = { ... }, counts = { [id] = n }? } or { all = true },
	                      then the same with confirm = true
	  cryptNoticeSeen     { zoneId = "hallow" }            the pop-up was shown
	  buyTrickOrTreat     (no payload)

	PUSHES (server -> client):

	  eventNotice            { zoneId, title, text }       first entry, until seen
	  cryptSellCandyConfirm  { units, candy, rows = { { id, name, n, candy } },
	                           lockedSkipped }
	  cryptScrapConfirm      { uid, id, name, prestige, candy }
	  cryptPrestiged         { uid, id, name, prestige, power, worldPower, cost, oreId }
	  trickOrTreatOpened     { rarityIndex, rarity, kind = "pet"|"skin",
	                           outcome = "treat"|"trick"|"refund",
	                           reward = { name, kind, id?, cardId?, petName?,
	                                      skinId?, tier?, dupeDust? },
	                           price, candyLeft }
	  chestOpened            (the zone-chest event) with kind = "crypt", rank,
	                           rankIndex, name, candy, packs (names), packIds,
	                           charm = { id, name } | nil, book = { id, level } | nil
	  foundTool              a crafted tool, a chest's charm, as reveals
	  bookBundle             { books = { { id, level } }, source = "crypt" }
	  cryptClosed            { zoneId } once, when the event-end move runs live
]]
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared:WaitForChild("MineConfig"))
local R = require(shared:WaitForChild("MineCryptRules"))
local Tools = require(shared:WaitForChild("MineCandyTools"))
local Chests = require(shared:WaitForChild("MineCryptChests"))
local TT = require(shared:WaitForChild("MineTrickOrTreat"))
local Charms = require(shared:WaitForChild("MineCharms"))

local S = {}
local ctx = {}

-- How often the event-end move looks at everyone online. The load path
-- covers whoever is offline when the window closes.
S.TICK_SEC = 30
--[[
	The Trick-or-Treat result is also a toast until the client's reveal (the
	rarity, then the wheel) ships: the client never shows the result yet, and a
	silent case is worse than a spoiled one. The client's session turns this
	off when the wheel lands (it shows the result itself).
]]
S.CASE_RESULT_TOAST = true

-- The fraction of a coin the Crypt's haul owes, per profile. Weak keys, and
-- never on the profile: save() writes the profile table whole.
local carry = setmetatable({}, { __mode = "k" })

local function toast(plr, text)
	if plr and ctx.net then
		ctx.net:FireClient(plr, "toast", text)
	end
end

local function fire(plr, name, payload)
	if plr and ctx.net then
		ctx.net:FireClient(plr, name, payload)
	end
end

local function dirty(plr)
	if plr and ctx.markDirty then
		ctx.markDirty(plr)
	end
end

local function snapNow(plr)
	if plr and ctx.snap then
		ctx.snap(plr)
	end
end

local function regive(plr)
	if plr and ctx.givePickaxe then
		pcall(ctx.givePickaxe, plr)
	end
end

local function hex16()
	local g = string.gsub(HttpService:GenerateGUID(false), "-", ""):lower()
	return string.sub(g, 1, 16)
end

local function short(n)
	n = math.floor(tonumber(n) or 0)
	local s = tostring(n)
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

local function count(t, id)
	return math.max(0, math.floor(tonumber((t or {})[id]) or 0))
end

--------------------------------------------------------------------------------
-- THE PROFILE
--------------------------------------------------------------------------------

-- The best tool a player owns: highest rank, then prestige.
function S.bestUid(p)
	local best, bestScore = nil, -1
	for _, t in ipairs(R.ownedTools(p)) do
		local def = Tools.byId(t.id)
		local score = def.rank * 100 + Tools.clampPrestige(t.prestige)
		if score > bestScore then
			best, bestScore = t.uid, score
		end
	end
	return best
end

--[[
	Shape the save. Idempotent, and cheap enough to run on every verb: drops a
	tool entry that names no real tool, gives every entry a uid, floors counts,
	points the equip at something owned, and makes the flags plain values.
]]
function S.ensure(p)
	if type(p) ~= "table" then
		return p
	end
	local h = p.halloween
	if type(h) ~= "table" then
		h = {}
		p.halloween = h
	end
	local tools = {}
	for _, t in ipairs(type(h.tools) == "table" and h.tools or {}) do
		if type(t) == "table" and Tools.byId(t.id) then
			if type(t.uid) ~= "string" or t.uid == "" then
				t.uid = hex16()
			end
			t.prestige = Tools.clampPrestige(t.prestige)
			if type(t.spent) ~= "table" then
				t.spent = {}
			end
			table.insert(tools, t)
		end
	end
	h.tools = tools
	local ores = {}
	for id, n in pairs(type(h.ores) == "table" and h.ores or {}) do
		local c = math.floor(tonumber(n) or 0)
		if c > 0 and C.candyOreById(id) then
			ores[id] = c
		end
	end
	h.ores = ores
	if type(h.team) ~= "table" then
		h.team = {}
	end
	if type(h.seen) ~= "table" then
		h.seen = {}
	end
	if h.charm ~= nil and (type(h.charm) ~= "string" or h.charm == "") then
		h.charm = nil
	end
	if h.moved ~= true then
		h.moved = nil
	end
	if type(h.tool) ~= "string" or not R.findTool(p, h.tool) then
		h.tool = S.bestUid(p)
	end
	if p.cryptToolWorld ~= true then
		p.cryptToolWorld = nil
	end
	if type(p.eventNoticeSeen) ~= "table" then
		p.eventNoticeSeen = {}
	end
	p.candy = math.max(0, math.floor(tonumber(p.candy) or 0))
	return p
end

--[[
	Add a Halloween tool. Returns its entry, or nil and a reason. Equips it
	when nothing is in hand. `spent` is what it cost ({ [oreId] = n }; the
	free starter cost nothing), which is what scrapping refunds half of. The
	cap is checked by the caller's plan (craftPlan); a claim or repair grant
	passes `force`. `plr` may be nil (load-time repair).
]]
function S.grantTool(plr, p, toolId, spent, force)
	local def = Tools.byId(toolId)
	if not def then
		return nil, "That tool is not in the game"
	end
	S.ensure(p)
	local h = p.halloween
	if not force and #h.tools >= Tools.CAP then
		return nil, "Halloween tool cap reached"
	end
	local entry = { uid = hex16(), id = def.id, prestige = 0, spent = table.clone(spent or {}) }
	table.insert(h.tools, entry)
	if not h.tool then
		h.tool = entry.uid
		regive(plr)
	end
	dirty(plr)
	return entry
end

--[[
	A candy ore into the inventory that holds candy ores right now: the
	Halloween inventory while the event runs, `p.ores` after the move. No room
	check: candy ores take no pouch room (MineOrePouch.held), and they are not
	a currency anything converts to gems.
]]
function S.addCandyOre(p, oreId, n)
	local ore = C.candyOreById(oreId)
	n = math.max(0, math.floor(tonumber(n) or 0))
	if not ore or n <= 0 then
		return 0
	end
	S.ensure(p)
	p.halloween.seen[ore.id] = true
	if R.separate(p) then
		p.halloween.ores[ore.id] = count(p.halloween.ores, ore.id) + n
	else
		p.ores = p.ores or {}
		p.ores[ore.id] = count(p.ores, ore.id) + n
	end
	return n
end

-- Take n of a candy ore from where candy ores live now. False if short.
function S.takeCandyOre(p, oreId, n)
	local store = R.oreStore(p)
	local have = count(store, oreId)
	n = math.max(0, math.floor(tonumber(n) or 0))
	if have < n then
		return false
	end
	local left = have - n
	store[oreId] = (left > 0) and left or nil
	return true
end

-- Candy after the bag (the Trick-or-Treat Bucket's candyMult) and the charm's
-- Candy Find. `b` is the caller's boosts table, when it has one.
function S.candyMultiplied(p, candy, b)
	candy = math.max(0, math.floor(tonumber(candy) or 0))
	local bag = C.BACKPACKS and C.BACKPACKS[p.backpackTier]
	local bagMult = bag and tonumber(bag.candyMult)
	if bagMult and bagMult > 1 then
		candy = math.floor(candy * bagMult)
	end
	local find = b and tonumber(b.candyFind)
	if find and find > 1 then
		candy = math.floor(candy * find)
	end
	return candy
end

--[[
	WHEN THE EVENT ENDS, THE HALLOWEEN INVENTORY MOVES INTO THE MAIN ONE (owner,
	2026-10-19). Idempotent (`moved`), run on load and by the tick when the
	window closes.
	  candy ores   into p.ores (they take no pouch room there)
	  pets         already in p.cards; the Halloween team is cleared, so they
	               are ordinary pets the main team may wear
	  charms       already in p.charms; the worn Halloween charm takes the
	               main slot if that is empty
	  tools        stay in p.halloween.tools, now held in the main world through
	               cryptEquip { world = true }, and prestige still works
	Returns true when it moved something.
]]
function S.moveToMain(p, now)
	if type(p) ~= "table" then
		return false
	end
	S.ensure(p)
	local h = p.halloween
	if h.moved or not R.window(now).ended then
		return false
	end
	p.ores = p.ores or {}
	for id, n in pairs(h.ores) do
		p.ores[id] = count(p.ores, id) + n
	end
	h.ores = {}
	h.team = {}
	if h.charm and not (type(p.equippedCharm) == "string" and p.equippedCharm ~= "") then
		p.equippedCharm = h.charm
	end
	h.charm = nil
	h.moved = true
	return true
end

--[[
	The event-end move for everyone online, every TICK_SEC (S.init starts it).
	A player who is offline when the window closes is moved on their next load
	(normalize).
]]
function S.tick(now)
	if not R.window(now).ended then
		return 0
	end
	local moved = 0
	for uid, p in pairs(ctx.profiles or {}) do
		if type(p) == "table" and not (type(p.halloween) == "table" and p.halloween.moved) and not p._ephemeral then
			if S.moveToMain(p, now) then
				moved += 1
				local plr = Players:GetPlayerByUserId(uid)
				if plr then
					regive(plr)
					dirty(plr)
					snapNow(plr)
					fire(plr, "cryptClosed", { zoneId = R.ZONE_ID })
					toast(plr, "The Candy Crypt has closed: your Halloween things are in your main inventory")
				end
			end
		end
	end
	return moved
end

function S.init(c)
	ctx = c or {}
	if not ctx.noTick then
		task.spawn(function()
			while true do
				task.wait(S.TICK_SEC)
				pcall(S.tick)
			end
		end)
	end
end

--[[
	ON LOAD. Shape the save, then three one-way steps:
	  1. RETIRE v1 (the first Crypt design, 2026-10-19): its tool stacks
	     (p.cryptTools, Golden/Prism/Rainbow) are not v2 tools and are dropped;
	     its six crafted candy charms are retired (MineCharms.RETIRED_CANDY_CHARMS)
	     and come off the main slot; candy ores it kept in p.ores move into the
	     Halloween inventory while the event runs. The game is not open yet, so
	     test saves lose v1 items rather than being converted (the claim repair
	     below hands back a starter pick).
	  2. The event-end move, if the event has ended (idempotent).
	  3. A claim always came with a pick: a claimed save with no Halloween tool
	     gets the Candy Corn Pick back.
]]
function S.normalize(p)
	S.ensure(p)
	local h = p.halloween
	p.cryptTools = nil
	p.cryptToolEquipped = nil
	if type(p.candySeen) == "table" then
		for id, v in pairs(p.candySeen) do
			if v and C.candyOreById(id) then
				h.seen[id] = true
			end
		end
	end
	p.candySeen = nil
	local retired = Charms.RETIRED_CANDY_CHARMS or {}
	if type(p.charms) == "table" then
		for id in pairs(retired) do
			p.charms[id] = nil
		end
	end
	if retired[p.equippedCharm or ""] then
		p.equippedCharm = nil
	end
	if retired[h.charm or ""] then
		h.charm = nil
	end
	if R.separate(p) and type(p.ores) == "table" then
		for _, ore in ipairs(C.CANDY_ORES or {}) do
			local n = count(p.ores, ore.id)
			if n > 0 then
				h.ores[ore.id] = count(h.ores, ore.id) + n
				p.ores[ore.id] = nil
			end
		end
	end
	S.moveToMain(p)
	if p.hallowOwned == true and #h.tools == 0 then
		S.grantTool(nil, p, Tools.STARTER_ID, {}, true)
	end
	return p
end

--------------------------------------------------------------------------------
-- HOOKS MineServer calls
--------------------------------------------------------------------------------

function S.heldTool(p)
	return R.heldRow(p, p and p.zoneId, nil)
end

-- The pets boosts() counts where the player stands (MineCryptRules.teamFor).
function S.petTeam(p)
	return R.teamFor(p, p and p.zoneId, nil)
end

-- The charm boosts() applies where the player stands, or nil for none.
function S.charmFor(p)
	return R.charmFor(p, p and p.zoneId, nil)
end

-- The main team's equip asks: a Halloween pet goes on the Halloween team
-- while the event runs (owner: a separate Halloween pet team).
S.MAIN_TEAM_TEXT = R.MAIN_TEAM_TEXT
function S.mainTeamRefuses(p, cardId)
	return R.separate(p) and R.isHalloweenItem("pet", R.cardById(p, cardId)) or false
end

-- The contract's view of the Halloween inventory (MineCryptRules.inventoryOf).
function S.inventoryOf(p)
	return R.inventoryOf(p, nil)
end

--[[
	TRADING (owner, 2026-10-19): "Halloween tools and candy ores can't be traded
	during the event; tradable once it ends", and the Halloween inventory's
	items with them. TradeService asks this for every item it would put on the
	table or move. `kind` is the trade's kind ("cards" with a card serial,
	"packs" with a pack uid) or a Crypt kind ("tool", "ore", "charm", "pet").
	Packs are NOT locked: the Halloween pack is a main-inventory item (asked in
	the build report).
]]
S.TRADE_LOCKED_TEXT = R.TRADE_LOCKED_TEXT
function S.tradeLocked(p, kind, id)
	if type(p) ~= "table" or not R.separate(p) then
		return false
	end
	kind = tostring(kind or "")
	if kind == "cards" or kind == "card" or kind == "pet" or kind == "pets" then
		local card = (type(id) == "table") and id or nil
		if not card then
			for _, c in ipairs(type(p.cards) == "table" and p.cards or {}) do
				if type(c) == "table" and (c.serial == id or c.id == id) then
					card = c
					break
				end
			end
		end
		return card ~= nil and R.isHalloweenItem("pet", card)
	elseif kind == "tool" or kind == "tools" or kind == "cryptTool" then
		return true
	elseif kind == "ore" or kind == "ores" then
		return R.isHalloweenItem("ore", id)
	elseif kind == "charm" or kind == "charms" then
		return R.isHalloweenItem("charm", id)
	end
	return false
end

function S.onClaim(plr, p, zone)
	S.ensure(p)
	local gave = false
	if #p.halloween.tools == 0 then
		gave = S.grantTool(plr, p, Tools.STARTER_ID, {}, true) ~= nil
		local def = Tools.byId(Tools.STARTER_ID)
		if gave and def then
			fire(plr, "foundTool", {
				kind = "cryptTool",
				name = def.name,
				rarityId = def.rarityId,
				title = "FREE HALLOWEEN TOOL",
				blurb = def.warning,
			})
		end
	end
	toast(plr, ("%s claimed%s -- only Halloween tools dig here"):format(
		(zone and zone.name) or "Candy Crypt", gave and ", here is a free Candy Corn Pick" or ""))
	dirty(plr)
end

function S.onEnterZone(plr, p, zone, fromZoneId)
	if not zone then
		return
	end
	local from = fromZoneId and C.zoneById(fromZoneId)
	local fromEvent = from and from.id == fromZoneId and from.eventToolsOnly
	-- The hands change when you cross into or out of an event mine.
	if zone.eventToolsOnly or fromEvent then
		regive(plr)
	end
	if zone.eventToolsOnly then
		S.ensure(p)
		if not p.eventNoticeSeen[zone.id] then
			local n = R.noticeFor(zone.id)
			fire(plr, "eventNotice", { zoneId = zone.id, title = n.title, text = n.text })
		end
	end
end

--[[
	A CANDY BLOCK PAYS its flat candy and its ore's fixed drop (owner, v2:
	"every ore drops the same amount every time"; candy "the same at every
	depth"). The candy was banked on the block at spawn (MineConfig.candyFor),
	so the payout matches the block the player looked at; the drop is the ore's
	own (MineConfig.candyDropFor). Candy Find and a candy bag multiply the
	candy, never the ore. Returns true when it paid.
]]
function S.onBlockBroken(plr, p, part, kind, layer, bb)
	if not part then
		return false
	end
	local candy = tonumber(part:GetAttribute("Candy"))
	if not candy or candy <= 0 then
		return false
	end
	S.ensure(p)
	candy = S.candyMultiplied(p, candy, bb)
	p.candy = math.max(0, math.floor((tonumber(p.candy) or 0) + candy))
	local ore = C.candyOreById(part:GetAttribute("CandyOre"))
	local got = ore and S.addCandyOre(p, ore.id, C.candyDropFor(ore)) or 0
	local text = ("+%s candy"):format(short(candy))
	if got > 0 then
		text = text .. ("  +%d %s"):format(got, ore.name)
	end
	fire(plr, "loot", { text = text, color = part.Color, pos = part.Position })
	dirty(plr)
	return true
end

--[[
	THE CRYPT SELLS FOR LITTLE. payDamage pays one haul point (a bag slot and a
	coin) per point of damage everywhere; in the Crypt a point of damage is worth
	MineConfig.cryptHaulRatio of one, so a block pays the old curve's coins
	however hard its rock now is. The fraction carries between hits, so even
	1/538 of a coin a hit adds up instead of flooring to nothing.
]]
function S.haulPoints(p, landed, layer)
	local exact = (tonumber(landed) or 0) * C.cryptHaulRatio(layer) + (carry[p] or 0)
	-- The 1e-9 absorbs float drift: 538 hits of 1/538 must make 1, not 0.99999.
	local whole = math.floor(exact + 1e-9)
	carry[p] = exact - whole
	return whole
end

-- Which of the eight chests spawns at this layer (MineCryptChests: rarer ranks
-- rarer, more common deeper). spawnVoxel stamps the def on the block.
function S.chestSpawnDef(layer, rng)
	return Chests.spawnDef(Chests.rollRank(layer, rng or Random.new()))
end

--[[
	A Halloween charm into p.charms (a tally, like every charm grant). While the
	event runs it is worn in the Halloween slot if that is empty; afterwards in
	the main slot if that is.
]]
function S.grantCharm(plr, p, charmId, source)
	local def = Charms.byId(charmId)
	if not def then
		return false
	end
	S.ensure(p)
	p.charms = p.charms or {}
	local had = p.charms[def.id]
	p.charms[def.id] = ((had == true) and 1 or math.max(0, math.floor(tonumber(had) or 0))) + 1
	local how
	if R.separate(p) then
		if not p.halloween.charm then
			p.halloween.charm = def.id
			how = "worn in the Crypt"
		else
			how = "wear it from your Halloween inventory"
		end
	elseif not (type(p.equippedCharm) == "string" and p.equippedCharm ~= "") then
		p.equippedCharm = def.id
		how = "equipped"
	else
		how = "equip it in Inventory → Equipment"
	end
	fire(plr, "foundTool", {
		kind = "charm",
		charmId = def.id,
		name = def.name,
		title = "HALLOWEEN CHARM",
		rarityId = (Charms.RARITY_LABEL and def.rarity and Charms.RARITY_LABEL[def.rarity]) or "Legendary",
		blurb = (def.blurb or "") .. "  ·  " .. how,
		source = source,
	})
	toast(plr, "Halloween charm: " .. def.name .. " -- " .. how)
	return true
end

-- A Halloween enchant book (MineEnchants.rollHalloweenBook, another agent's)
-- for a chest of this rank, or nil. Granted the way MineEnchantService does.
function S.rollBook(p, rank, rng)
	local okE, E = pcall(function()
		local node = shared:FindFirstChild("MineEnchants")
		return node and require(node) or nil
	end)
	if not (okE and type(E) == "table" and type(E.rollHalloweenBook) == "function" and type(E.bookKey) == "function") then
		return nil
	end
	local ok, res = pcall(E.rollHalloweenBook, rank.index, rng)
	if not ok or res == nil then
		return nil
	end
	local id, level = res, 1
	if type(res) == "table" then
		id, level = res.id, tonumber(res.level) or 1
	end
	if type(id) ~= "string" or id == "" then
		return nil
	end
	p.enchantBooks = type(p.enchantBooks) == "table" and p.enchantBooks or {}
	local key = E.bookKey(id, level)
	p.enchantBooks[key] = (tonumber(p.enchantBooks[key]) or 0) + 1
	return { id = id, level = level }
end

--[[
	A CRYPT CHEST PAYS (owner, v2): its rank's Halloween packs and flat candy;
	the rank's special Halloween charm at 0.5% x Chest Luck; and sometimes a
	Halloween enchant book (rarer ranks more often). No coins, gems or tools.
	The rank is the one stamped on the block at spawn, so the chest pays what
	it showed.
]]
function S.openChest(plr, p, part, b)
	S.ensure(p)
	b = b or {}
	local layer = math.max(1, math.floor(tonumber(part and part:GetAttribute("CY")) or 1))
	local rng = Random.new()
	local rank = Chests.rankOfId(part and part:GetAttribute("ChestType")) or Chests.rollRank(layer, rng)
	if ctx.bumpStat then
		ctx.bumpStat(plr, p, "chests")
	end
	if ctx.chestXp then
		pcall(ctx.chestXp, plr, p)
	end
	local candy = S.candyMultiplied(p, rank.candy, b)
	p.candy = math.max(0, math.floor((tonumber(p.candy) or 0) + candy))
	p.packs = p.packs or {}
	local names, ids = {}, {}
	for _, row in ipairs(Chests.packRows(rank)) do
		table.insert(p.packs, row)
		table.insert(names, row.packName)
		table.insert(ids, row.packId)
	end
	local charm = nil
	if type(Charms.cryptChestCharm) == "function" and rng:NextNumber() < Chests.charmChance(b.chestLuck) then
		local ok, id = pcall(Charms.cryptChestCharm, rank.key)
		if ok and type(id) == "table" then
			id = id.id
		end
		if ok and type(id) == "string" and S.grantCharm(plr, p, id, "chest") then
			local def = Charms.byId(id)
			charm = { id = id, name = def and def.name or id }
		end
	end
	local book = S.rollBook(p, rank, rng)
	if book then
		fire(plr, "bookBundle", { books = { book }, source = "crypt" })
	end
	fire(plr, "chestOpened", {
		id = rank.id,
		name = rank.name,
		kind = "crypt",
		rank = rank.key,
		rankIndex = rank.index,
		coins = 0,
		gems = 0,
		candy = candy,
		packs = names,
		packIds = ids,
		charm = charm,
		book = book,
		pos = part and part.Position or nil,
	})
	fire(plr, "loot", {
		text = ("+%s candy"):format(short(candy)),
		color = Color3.fromRGB(255, 142, 44),
		pos = part and part.Position or nil,
	})
	dirty(plr)
end

--[[
	BUY AND OPEN A TRICK-OR-TREAT CASE (owner, v2): Halloween pets and skins
	only; the server rolls the prize, then the 50/50; TREAT you get it, TRICK
	you get nothing. One push carries the rarity, the reward and the outcome
	(`trickOrTreatOpened`), so the client shows the rarity and then spins the
	wheel to where the server already landed. A prize that cannot be given
	(nothing Halloween to give, or the pet mint failed) refunds the price.
]]
function S.buyTrickOrTreat(plr)
	local p = ctx.profiles and ctx.profiles[plr.UserId]
	if not p then
		return
	end
	S.ensure(p)
	-- Sold only while the Crypt is open, and only to someone who claimed it.
	local zone = C.zoneById(R.ZONE_ID)
	local flag = zone and zone.id == R.ZONE_ID and zone.ownedFlag
	if not (flag and p[flag]) then
		toast(plr, "Claim the Candy Crypt first")
		return
	end
	if not C.limitedActive(R.ZONE_ID) then
		toast(plr, "The Candy Crypt has closed")
		return
	end
	local price = math.max(1, math.floor(tonumber(TT.PRICE) or 1))
	if p.candy < price then
		toast(plr, ("Need %s candy"):format(short(price)))
		return
	end
	p.candy -= price

	local rng = Random.new()
	local roll = TT.roll(rng)
	local prize = R.casePrize(roll, rng)
	local out = {
		price = price,
		outcome = roll.outcome,
		rarityIndex = prize and prize.rarityIndex or roll.rarityIndex,
		rarity = prize and prize.rarity or roll.pet,
		kind = prize and prize.kind or roll.kind,
		reward = prize and { name = prize.name, kind = prize.kind } or nil,
	}
	local refund = prize == nil
	if prize and roll.outcome == "treat" then
		if prize.kind == "pet" then
			local card = ctx.grantPet and ctx.grantPet(plr, p, prize.pet, R.PET_SET) or nil
			if type(card) == "table" then
				out.reward.cardId = card.id
				out.reward.petName = card.name or prize.name
			else
				refund = true
			end
		else
			local def = prize.skin
			p.skins = p.skins or {}
			out.reward.skinId = def.id
			out.reward.tier = def.tier
			if p.skins[def.id] then
				-- A skin you own pays stardust, the chest skin's rule (Dig.grantChestSkin).
				local Skins = require(shared:WaitForChild("MineSkins"))
				local dust = math.max(1, math.floor(20 * ((Skins.TIER_RANK or {})[def.tier] or 1)))
				p.dust = (tonumber(p.dust) or 0) + dust
				out.reward.dupeDust = dust
			else
				p.skins[def.id] = true
				p.skinNotice = { name = def.name, tier = def.tier, set = def.set }
			end
		end
	end
	if refund then
		p.candy += price
		out.outcome = "refund"
	end
	out.candyLeft = p.candy
	dirty(plr)
	snapNow(plr)
	fire(plr, "trickOrTreatOpened", out)
	if S.CASE_RESULT_TOAST then
		if out.outcome == "treat" then
			toast(plr, "TREAT! " .. tostring(out.reward and out.reward.name or "a prize"))
		elseif out.outcome == "trick" then
			toast(plr, "TRICK! The " .. tostring(out.reward and out.reward.name or "prize") .. " got away")
		else
			toast(plr, "Trick-or-Treat: nothing to give right now (refunded)")
		end
	end
end

function S.snapState(p)
	return R.stateFor(p, nil)
end

--------------------------------------------------------------------------------
-- THE VERBS
--------------------------------------------------------------------------------

local VERBS = {}

local function payloadTable(payload, key)
	if type(payload) == "table" then
		return payload
	end
	return { [key] = payload }
end

--[[
	CRAFT A HALLOWEEN TOOL at the Forge (owner, v2): N of its candy ore, never a
	drop. Refused at the cap of ten ("crafting is blocked until you scrap one").
	The ore spent is recorded on the tool, so scrapping refunds what it really
	cost.
]]
function VERBS.cryptCraft(plr, p, payload)
	local args = payloadTable(payload, "toolId")
	local plan, why = R.craftPlan(p, tostring(args.toolId or args.id or ""))
	if not plan then
		toast(plr, why)
		return
	end
	S.takeCandyOre(p, plan.oreId, plan.cost)
	local entry = S.grantTool(plr, p, plan.def.id, { [plan.oreId] = plan.cost })
	if not entry then
		-- Cannot happen after craftPlan's cap check; hand the ore back if it does.
		S.addCandyOre(p, plan.oreId, plan.cost)
		toast(plr, "That craft did not go through")
		return
	end
	dirty(plr)
	snapNow(plr)
	fire(plr, "foundTool", {
		kind = "cryptTool",
		uid = entry.uid,
		toolId = plan.def.id,
		name = plan.def.name,
		rarityId = plan.def.rarityId,
		title = "HALLOWEEN TOOL CRAFTED",
		blurb = plan.def.warning,
	})
	toast(plr, ("Crafted %s  (-%d %s)"):format(plan.def.name, plan.cost, plan.def.oreName))
end

-- PRESTIGE: the next of ten, paid in more of the tool's own ore (owner). Works
-- after the event too ("prestige keeps working after the event").
function VERBS.cryptPrestige(plr, p, payload)
	local args = payloadTable(payload, "uid")
	local plan, why = R.prestigePlan(p, tostring(args.uid or ""))
	if not plan then
		toast(plr, why)
		return
	end
	S.takeCandyOre(p, plan.oreId, plan.cost)
	local e = plan.entry
	e.prestige = plan.to
	e.spent = e.spent or {}
	e.spent[plan.oreId] = count(e.spent, plan.oreId) + plan.cost
	if p.halloween.tool == e.uid then
		regive(plr)
	end
	dirty(plr)
	snapNow(plr)
	local dig = R.eventDigOf(p)
	fire(plr, "cryptPrestiged", {
		uid = e.uid,
		id = plan.def.id,
		name = plan.def.name,
		prestige = e.prestige,
		power = Tools.cryptPower(plan.def, e.prestige, dig),
		worldPower = Tools.worldPower(plan.def, e.prestige, dig),
		cost = plan.cost,
		oreId = plan.oreId,
	})
	toast(plr, ("%s is prestige %d  (-%d %s)"):format(plan.def.name, e.prestige, plan.cost, plan.def.oreName))
end

--[[
	SCRAP: half the candy value of every ore spent on the tool, in candy, no
	ores back (owner). Two calls, like SELL ALL: without `confirm` the server
	prices it and asks; with it, the scrap happens, priced by the same plan.
]]
function VERBS.cryptScrap(plr, p, payload)
	local args = payloadTable(payload, "uid")
	local plan, why = R.scrapPlan(p, tostring(args.uid or ""))
	if not plan then
		toast(plr, why)
		return
	end
	if not args.confirm then
		fire(plr, "cryptScrapConfirm", {
			uid = plan.entry.uid,
			id = plan.def.id,
			name = plan.def.name,
			prestige = Tools.clampPrestige(plan.entry.prestige),
			candy = plan.candy,
		})
		return
	end
	local h = p.halloween
	for i, t in ipairs(h.tools) do
		if t.uid == plan.entry.uid then
			table.remove(h.tools, i)
			break
		end
	end
	p.candy += plan.candy
	if h.tool == plan.entry.uid then
		h.tool = S.bestUid(p)
		regive(plr)
	end
	dirty(plr)
	snapNow(plr)
	toast(plr, ("Scrapped %s  +%s candy"):format(plan.def.name, short(plan.candy)))
end

function VERBS.cryptEquip(plr, p, payload)
	local args = payloadTable(payload, "uid")
	local said
	local uid = args.uid or args.key
	if uid ~= nil then
		local entry = R.findTool(p, tostring(uid))
		local def = entry and Tools.byId(entry.id)
		if not def then
			toast(plr, "You do not have that tool")
			return
		end
		p.halloween.tool = entry.uid
		said = def.name .. " equipped"
	end
	if args.world == true then
		if not R.window().ended then
			toast(plr, R.WORLD_LOCKED_TEXT)
			return
		end
		if not R.equippedEntry(p) then
			toast(plr, "You have no Halloween tool")
			return
		end
		p.cryptToolWorld = true
		said = (said or "Halloween tool") .. " -- held in the main world too"
	elseif args.world == false then
		p.cryptToolWorld = nil
		said = said or "Back to your own tools out here"
	end
	if not said then
		return
	end
	regive(plr)
	dirty(plr)
	snapNow(plr)
	toast(plr, said)
end

--[[
	THE HALLOWEEN PET TEAM (owner: a separate Halloween pet team). Replaces the
	team with `ids`, keeping only Halloween pets the player owns, no repeats,
	up to the main team's seats. Only while the Halloween inventory is its own:
	afterwards Halloween pets are ordinary pets on the main team.
]]
function VERBS.cryptTeam(plr, p, payload)
	if not R.separate(p) then
		toast(plr, "The Candy Crypt has closed: Halloween pets go on your main team now")
		return
	end
	local ids = (type(payload) == "table" and type(payload.ids) == "table") and payload.ids or {}
	local cap = R.teamCap(p)
	local team, seen = {}, {}
	for _, id in ipairs(ids) do
		if #team >= cap then
			break
		end
		local c = R.cardById(p, id)
		if c and not seen[c.id] and R.isHalloweenItem("pet", c) then
			seen[c.id] = true
			table.insert(team, c.id)
		end
	end
	p.halloween.team = team
	dirty(plr)
	snapNow(plr)
	toast(plr, (#team > 0) and ("Halloween team: %d pet%s"):format(#team, #team == 1 and "" or "s")
		or "Halloween team cleared")
end

-- The Halloween charm worn in the Crypt: any Halloween charm the player owns,
-- or "" / nil to take it off.
function VERBS.cryptCharm(plr, p, payload)
	if not R.separate(p) then
		toast(plr, "The Candy Crypt has closed: wear Halloween charms in your main charm slot")
		return
	end
	local args = payloadTable(payload, "charmId")
	local id = args.charmId
	if id == nil or id == "" then
		p.halloween.charm = nil
		dirty(plr)
		snapNow(plr)
		toast(plr, "Halloween charm off")
		return
	end
	id = tostring(id)
	local n = type(p.charms) == "table" and p.charms[id]
	local owned = (n == true) or ((tonumber(n) or 0) > 0)
	if not owned or not R.isHalloweenItem("charm", id) then
		toast(plr, "That is not a Halloween charm you own")
		return
	end
	p.halloween.charm = id
	local def = Charms.byId(id)
	dirty(plr)
	snapNow(plr)
	regive(plr)
	toast(plr, (def and def.name or id) .. " worn in the Crypt")
end

--[[
	SELL CANDY ORES FOR CANDY (owner, 2026-10-19: "tick candy ores to sell for
	candy"), from wherever candy ores live now: the Halloween inventory while the
	event runs, the main pouch after it. Two calls, like SELL ALL: without
	`confirm` the server prices the sale and sends it back; with it, the sale
	happens, built by the same plan so the number agreed to is the number paid.

	Ticked ores (`oreIds`) sell even if locked: the player named them, the same
	as selling one ore row. `all = true` is the bulk button, and skips locked.
]]
function S.candySellPlan(p, payload)
	local ores = R.oreStore(p)
	local locks = p.oreLocks or {}
	local rows, units, candy, lockedSkipped = {}, 0, 0, 0
	local function add(id, want)
		local ore = C.candyOreById(id)
		local have = ore and count(ores, ore.id) or 0
		local n = math.min(have, math.max(0, math.floor(tonumber(want) or have)))
		if ore and n > 0 then
			local each = R.candyOreValue(ore)
			table.insert(rows, { id = ore.id, name = ore.name, n = n, candy = each * n })
			units += n
			candy += each * n
		end
	end
	if type(payload) == "table" and payload.all then
		for _, ore in ipairs(C.CANDY_ORES or {}) do
			if count(ores, ore.id) > 0 then
				if locks[ore.id] then
					lockedSkipped += 1
				else
					add(ore.id, nil)
				end
			end
		end
	elseif type(payload) == "table" and type(payload.oreIds) == "table" then
		local seen = {}
		for i, id in ipairs(payload.oreIds) do
			if i > #(C.CANDY_ORES or {}) then
				break
			end
			id = tostring(id)
			if not seen[id] then
				seen[id] = true
				local want = type(payload.counts) == "table" and payload.counts[id] or nil
				add(id, want)
			end
		end
	end
	return { rows = rows, units = units, candy = candy, lockedSkipped = lockedSkipped }
end

function VERBS.cryptSellCandyOres(plr, p, payload)
	local plan = S.candySellPlan(p, payload)
	if plan.units <= 0 then
		toast(plr, (plan.lockedSkipped > 0) and "Nothing to sell -- those candy ores are locked"
			or "No candy ores to sell")
		return
	end
	if not (type(payload) == "table" and payload.confirm) then
		fire(plr, "cryptSellCandyConfirm", {
			units = plan.units,
			candy = plan.candy,
			rows = plan.rows,
			lockedSkipped = plan.lockedSkipped,
		})
		return
	end
	for _, row in ipairs(plan.rows) do
		S.takeCandyOre(p, row.id, row.n)
	end
	p.candy += plan.candy
	dirty(plr)
	snapNow(plr)
	toast(plr, ("Sold %s candy ore  +%s candy"):format(short(plan.units), short(plan.candy)))
end

function VERBS.cryptNoticeSeen(plr, p, payload)
	local zid = tostring((type(payload) == "table" and payload.zoneId) or payload or R.ZONE_ID)
	local zone = C.zoneById(zid)
	if not (zone and zone.id == zid and zone.limited) then
		return
	end
	p.eventNoticeSeen[zid] = true
	dirty(plr)
	snapNow(plr)
end

S.VERBS = VERBS

function S.dispatch(plr, action, payload)
	local fn = VERBS[action]
	if not fn then
		return
	end
	local p = ctx.profiles and ctx.profiles[plr.UserId]
	if not p then
		return
	end
	S.ensure(p)
	fn(plr, p, payload)
end

return S
