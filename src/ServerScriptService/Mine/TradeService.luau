--[[
	TradeService -- player-to-player trades and coinflips, built so nothing can
	be duplicated.

	THE FLOW
	  invite    A asks B; B answers. Nobody is pulled into a window they did not
	            agree to open.
	  draft     Each side puts up cards, packs, runes, gear, and three
	            currencies: gems, stardust and tokens. Items are named by their
	            own ids (card serial, pack uid, rune id, gear id), never by where
	            they sit in a list, so what you see offered is what moves.
	  marks     Either side can mark the other's items WANT (green) or NO (red),
	            on the table or still in their bag, and put a number on any of
	            their currencies ("I want 5,000 gems"). Marks are talk, not
	            terms: they never change the deal and never un-accept anyone.
	  mode      TRADE swaps the two offers. COINFLIP pools them and a 50/50
	            gives the winner everything on the table. Either side can switch
	            it; switching un-accepts both.
	  accept    Both press ACCEPT. Any change to either offer or to the mode
	            un-accepts both.
	  confirm   With both accepted, CONFIRM unlocks after a 3-second countdown
	            and both have to press it. Only then does anything move.

	WHY IT DOES NOT DUPE
	  1. Escrow. At commit every item and every currency amount is checked
	     against the profiles as they are right then and taken out in one step,
	     with no yield in between -- nothing can be sold, scrapped, socketed,
	     spent or offered again while the trade finishes. A coinflip escrows
	     only the loser's side; the winner's stake never leaves them.
	  2. Cards carry a global serial registry (MineServer transferSerial). Each
	     card's owner is moved in the registry before it is delivered; if any
	     move fails, the ones that succeeded are moved back, the escrow is
	     returned, and nothing has changed.
	  3. Both players are saved the moment it lands, and MineServer's session
	     lock keeps a player who hops servers from loading anywhere else until
	     that save is in. A player leaving mid-commit waits for the commit
	     (onLeave) so their final save includes it.
	  4. Socketed runes, worn gear and cards without a registry serial cannot be
	     offered. Ephemeral profiles (a save that failed to load) cannot trade.
]]
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TradeValue = require(RS.Mine.Shared:WaitForChild("MineTradeValue"))

local TradeService = {}

TradeService.MAX_ITEMS = 16 -- per side
TradeService.INVITE_TTL = 30 -- seconds a request waits for an answer
TradeService.INVITE_COOLDOWN = 4 -- seconds between requests from one player
TradeService.CONFIRM_DELAY = 3 -- seconds after both ACCEPT before CONFIRM unlocks
TradeService.JOIN_GRACE = 15 -- seconds after joining before you can trade
TradeService.PEEK_MAX = 400 -- most items sent when browsing the other bag
TradeService.MAX_MARKS = 200
-- Flip to false to take coinflips out without touching anything else.
TradeService.COINFLIP_ENABLED = false -- off for launch: gems/packs trace back to Robux

-- The currencies on the table: offer key -> profile field.
local CURRENCY = { gems = "gems", dust = "dust", tokens = "temperTokens" }
local CURRENCY_ORDER = { "gems", "dust", "tokens" }
-- A "fossils" kind traded here too. Fossils are retired (§0.12) and every
-- piece was cashed out, so the kind is gone rather than left as an empty tab.
local KINDS = { "cards", "packs", "runes", "gear", "potions" }
local KIND_OK = { cards = true, packs = true, runes = true, gear = true, potions = true }

local sessions = {} -- [sessionId] = session
local byPlayer = {} -- [userId] = sessionId
local invites = {} -- [toUserId] = { from = userId, at = os.clock() }
local lastInvite = {} -- [fromUserId] = os.clock()
local lastPeek = {} -- [userId] = os.clock()
local joinedAt = {} -- [userId] = os.clock()

Players.PlayerAdded:Connect(function(p)
	joinedAt[p.UserId] = os.clock()
end)
for _, p in ipairs(Players:GetPlayers()) do
	joinedAt[p.UserId] = joinedAt[p.UserId] or os.clock()
end

local function plrOf(userId)
	return Players:GetPlayerByUserId(userId)
end

local function nameOf(userId)
	local p = plrOf(userId)
	return p and p.DisplayName or "?"
end

local function toast(net, plr, msg)
	if plr then
		net:FireClient(plr, "toast", msg)
	end
end

local function commas(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

local function emptyOffer()
	return { gems = 0, dust = 0, tokens = 0, cards = {}, packs = {}, runes = {}, gear = {}, potions = {} }
end

local function emptyAsks()
	return { gems = 0, dust = 0, tokens = 0 }
end

local function countOf(o)
	return #o.cards + #o.packs + #o.runes + #o.gear + #(o.potions or {})
end

local function hasAnything(o)
	return countOf(o) > 0 or o.gems > 0 or o.dust > 0 or o.tokens > 0
end

-- "A" or "B" for this player, and the other letter.
local function sideOf(sess, userId)
	if sess.a == userId then
		return "A", "B"
	end
	return "B", "A"
end

local function findCard(p, serial)
	for i, c in ipairs(p.cards or {}) do
		if type(c) == "table" and (c.serial or c.id) == serial then
			return i, c
		end
	end
end

local function findBy(list, field, value)
	for i, row in ipairs(list or {}) do
		if type(row) == "table" and row[field] == value then
			return i, row
		end
	end
end

local function gearWorn(p, g)
	return g and (p.equippedGear or {})[g.slot] == g.id
end

local function balance(p, key)
	return math.max(0, math.floor(tonumber(p[CURRENCY[key]]) or 0))
end

--------------------------------------------------------------------------------
-- What each side can see
--------------------------------------------------------------------------------

-- The rows behind an offer, so the other window can draw them. Only what the
-- offer names; never the rest of the inventory.
local function expand(p, o)
	local out = { gems = o.gems, dust = o.dust, tokens = o.tokens, cards = {}, packs = {}, runes = {}, gear = {}, potions = {} }
	if not p then
		return out
	end
	for _, serial in ipairs(o.cards) do
		local _, c = findCard(p, serial)
		if c then table.insert(out.cards, c) end
	end
	for _, uid in ipairs(o.packs) do
		local _, pk = findBy(p.packs, "uid", uid)
		if pk then table.insert(out.packs, pk) end
	end
	for _, id in ipairs(o.runes) do
		local _, r = findBy(p.runes, "id", id)
		if r then table.insert(out.runes, r) end
	end
	for _, id in ipairs(o.gear) do
		local _, g = findBy(p.gear, "id", id)
		if g then table.insert(out.gear, g) end
	end
	for _, id in ipairs(o.potions or {}) do
		table.insert(out.potions, { id = id, name = id })
	end
	return out
end

-- Items only, in stardust terms -- the "worth of loot" in a coinflip line.
local function lootValue(view)
	local sum = 0
	for _, c in ipairs(view.cards) do sum += TradeValue.cardValue(c) end
	for _, pk in ipairs(view.packs) do sum += TradeValue.packValue(pk) end
	for _, r in ipairs(view.runes) do sum += TradeValue.runeValue(r) end
	for _, g in ipairs(view.gear) do sum += TradeValue.gearValue(g) end
	for _, pot in ipairs(view.potions or {}) do
		local id = type(pot) == "table" and pot.id or pot
		local ok, v = pcall(function()
			return require(game:GetService("ReplicatedStorage").Mine.Shared.MinePotions).tradeValue(id)
		end)
		sum += (ok and tonumber(v) or 40)
	end
	return sum
end

-- Items plus gems and stardust. Tokens have no stardust rate; the windows show
-- them as their own number instead of pretending to price them.
local function valueOf(view)
	return lootValue(view) + math.floor((tonumber(view.gems) or 0) * TradeValue.GEM_TO_DUST)
		+ math.floor(tonumber(view.dust) or 0)
end

local function resetAccepts(sess)
	sess.acceptA, sess.acceptB = false, false
	sess.confirmA, sess.confirmB = false, false
	sess.confirmAt = nil
end

local function sync(net, sess, profiles)
	local viewA = expand(profiles[sess.a], sess.offerA)
	local viewB = expand(profiles[sess.b], sess.offerB)
	local stage = sess.committing and "committing" or (sess.confirmAt and "confirm" or "draft")
	local payload = {
		id = sess.id,
		a = sess.a,
		b = sess.b,
		nameA = nameOf(sess.a),
		nameB = nameOf(sess.b),
		userA = (plrOf(sess.a) or {}).Name or "",
		userB = (plrOf(sess.b) or {}).Name or "",
		mode = sess.mode,
		coinflipEnabled = TradeService.COINFLIP_ENABLED,
		stage = stage,
		confirmIn = sess.confirmAt and math.max(0, sess.confirmAt - os.clock()) or 0,
		offerA = viewA,
		offerB = viewB,
		valueA = valueOf(viewA),
		valueB = valueOf(viewB),
		acceptA = sess.acceptA,
		acceptB = sess.acceptB,
		confirmA = sess.confirmA,
		confirmB = sess.confirmB,
		marksA = sess.marksA,
		marksB = sess.marksB,
		asksA = sess.asksA,
		asksB = sess.asksB,
		note = sess.note,
		maxItems = TradeService.MAX_ITEMS,
	}
	sess.note = nil
	local aPlr, bPlr = plrOf(sess.a), plrOf(sess.b)
	if aPlr then net:FireClient(aPlr, "tradeSync", payload) end
	if bPlr then net:FireClient(bPlr, "tradeSync", payload) end
end

local function current(plr)
	local sid = byPlayer[plr.UserId]
	return sid and sessions[sid]
end

--------------------------------------------------------------------------------
-- Session lifecycle
--------------------------------------------------------------------------------

function TradeService.cancel(net, userId, reason)
	local sid = byPlayer[userId]
	local sess = sid and sessions[sid]
	if not sess then
		byPlayer[userId] = nil
		return
	end
	if sess.committing then
		-- A commit owns the session until it finishes; it closes it itself.
		return
	end
	sessions[sid] = nil
	byPlayer[sess.a] = nil
	byPlayer[sess.b] = nil
	local msg = reason or "Trade cancelled"
	for _, id in ipairs({ sess.a, sess.b }) do
		local plr = plrOf(id)
		if plr then
			net:FireClient(plr, "tradeClosed", msg)
			toast(net, plr, msg)
		end
	end
end

function TradeService.inTrade(userId)
	return byPlayer[userId] ~= nil
end

function TradeService.invite(net, profiles, fromPlr, toUserId)
	toUserId = tonumber(toUserId)
	if not toUserId or toUserId == fromPlr.UserId then
		return toast(net, fromPlr, "Pick someone else to trade with")
	end
	local toPlr = plrOf(toUserId)
	if not toPlr then
		return toast(net, fromPlr, "They are not in this server")
	end
	local now = os.clock()
	if now - (lastInvite[fromPlr.UserId] or -99) < TradeService.INVITE_COOLDOWN then
		return toast(net, fromPlr, "Give it a second")
	end
	if now - (joinedAt[fromPlr.UserId] or 0) < TradeService.JOIN_GRACE then
		return toast(net, fromPlr, "You can trade a few seconds after joining")
	end
	if now - (joinedAt[toUserId] or 0) < TradeService.JOIN_GRACE then
		return toast(net, fromPlr, "They only just joined -- try again in a moment")
	end
	-- Roblox's rules for this player (see MineServer Verbs.fetchPolicy).
	if fromPlr:GetAttribute("PolicyNoTrade") == true then
		return toast(net, fromPlr, "Trading isn't available in your region")
	end
	if toPlr:GetAttribute("PolicyNoTrade") == true then
		return toast(net, fromPlr, toPlr.DisplayName .. " can't trade in their region")
	end
	if byPlayer[fromPlr.UserId] then
		return toast(net, fromPlr, "You are already in a trade")
	end
	if byPlayer[toUserId] then
		return toast(net, fromPlr, toPlr.DisplayName .. " is already trading")
	end
	local pf, pt = profiles[fromPlr.UserId], profiles[toUserId]
	if not pf or not pt or pf._ephemeral or pt._ephemeral then
		return toast(net, fromPlr, "Trading is not available right now")
	end
	lastInvite[fromPlr.UserId] = now
	invites[toUserId] = { from = fromPlr.UserId, at = now }
	net:FireClient(toPlr, "tradeInvite", {
		from = fromPlr.UserId,
		name = fromPlr.DisplayName,
		ttl = TradeService.INVITE_TTL,
	})
	toast(net, fromPlr, "Trade request sent to " .. toPlr.DisplayName)
end

-- Old verb name; a coinflip is now a mode inside the trade window.
function TradeService.request(net, profiles, fromPlr, toUserId)
	return TradeService.invite(net, profiles, fromPlr, toUserId)
end

function TradeService.respond(net, profiles, plr, accept)
	local inv = invites[plr.UserId]
	invites[plr.UserId] = nil
	if not inv or os.clock() - inv.at > TradeService.INVITE_TTL then
		return toast(net, plr, "That trade request expired")
	end
	local fromPlr = plrOf(inv.from)
	if not fromPlr then
		return toast(net, plr, "They left the server")
	end
	if not accept then
		return toast(net, fromPlr, plr.DisplayName .. " declined your trade")
	end
	if plr:GetAttribute("PolicyNoTrade") == true or fromPlr:GetAttribute("PolicyNoTrade") == true then
		toast(net, fromPlr, "That trade can't happen in one of your regions")
		return toast(net, plr, "Trading isn't available in your region")
	end
	if byPlayer[inv.from] or byPlayer[plr.UserId] then
		return toast(net, plr, "Someone is already in a trade")
	end
	local pa, pb = profiles[inv.from], profiles[plr.UserId]
	if not pa or not pb or pa._ephemeral or pb._ephemeral then
		return toast(net, plr, "Trading is not available right now")
	end
	local id = HttpService:GenerateGUID(false)
	local sess = {
		id = id,
		a = inv.from,
		b = plr.UserId,
		mode = "trade",
		offerA = emptyOffer(),
		offerB = emptyOffer(),
		marksA = {},
		marksB = {},
		asksA = emptyAsks(),
		asksB = emptyAsks(),
	}
	resetAccepts(sess)
	sessions[id] = sess
	byPlayer[sess.a] = id
	byPlayer[sess.b] = id
	sync(net, sess, profiles)
end

local function sameOffer(x, y)
	for _, k in ipairs(CURRENCY_ORDER) do
		if x[k] ~= y[k] then
			return false
		end
	end
	for _, kind in ipairs(KINDS) do
		if #x[kind] ~= #y[kind] then
			return false
		end
		for i, v in ipairs(x[kind]) do
			if y[kind][i] ~= v then
				return false
			end
		end
	end
	return true
end

--[[
	An offer is currency amounts plus lists of ids. Only what the player owns
	right now, and can actually give, makes it in: the server keeps the cleaned
	version and that is what both windows show.
]]
function TradeService.setOffer(net, profiles, plr, offer, deps)
	local sess = current(plr)
	if not sess or sess.committing then
		return
	end
	local p = profiles[plr.UserId]
	if not p or type(offer) ~= "table" then
		return
	end
	deps = deps or {}
	local me = sideOf(sess, plr.UserId)
	local clean = emptyOffer()
	local seen = {}
	local function room()
		return countOf(clean) < TradeService.MAX_ITEMS
	end
	for _, k in ipairs(CURRENCY_ORDER) do
		clean[k] = math.clamp(math.floor(tonumber(offer[k]) or 0), 0, balance(p, k))
	end
	for _, serial in ipairs(type(offer.cards) == "table" and offer.cards or {}) do
		if type(serial) == "string" and not seen["c" .. serial] and room() then
			local _, c = findCard(p, serial)
			-- Only cards the registry knows can move; anything else would be
			-- deleted by the anti-dupe check on the other side.
			if c and (not deps.isCardSerial or deps.isCardSerial(serial)) then
				seen["c" .. serial] = true
				table.insert(clean.cards, serial)
			end
		end
	end
	for _, uid in ipairs(type(offer.packs) == "table" and offer.packs or {}) do
		if type(uid) == "string" and not seen["p" .. uid] and room() then
			local _, pk = findBy(p.packs, "uid", uid)
			if pk then
				seen["p" .. uid] = true
				table.insert(clean.packs, uid)
			end
		end
	end
	for _, id in ipairs(type(offer.runes) == "table" and offer.runes or {}) do
		if type(id) == "string" and not seen["r" .. id] and room() then
			local _, r = findBy(p.runes, "id", id)
			if r and not (deps.runeBusy and deps.runeBusy(p, id)) then
				seen["r" .. id] = true
				table.insert(clean.runes, id)
			end
		end
	end
	for _, id in ipairs(type(offer.gear) == "table" and offer.gear or {}) do
		if type(id) == "string" and not seen["g" .. id] and room() then
			local _, g = findBy(p.gear, "id", id)
			if g and not gearWorn(p, g) then
				seen["g" .. id] = true
				table.insert(clean.gear, id)
			end
		end
	end
	clean.potions = {}
	for _, id in ipairs(type(offer.potions) == "table" and offer.potions or {}) do
		if type(id) == "string" and room() then
			local have = tonumber((p.potions or {})[id]) or 0
			local already = 0
			for _, x in ipairs(clean.potions) do
				if x == id then already += 1 end
			end
			if have > already then
				table.insert(clean.potions, id)
			end
		end
	end
	if sameOffer(clean, sess["offer" .. me]) then
		-- Nothing moved (a repeat push): keep everyone's accept.
		return sync(net, sess, profiles)
	end
	sess["offer" .. me] = clean
	if sess.acceptA or sess.acceptB then
		sess.note = nameOf(plr.UserId) .. " changed their offer -- accept again"
	end
	resetAccepts(sess)
	sync(net, sess, profiles)
end

function TradeService.setMode(net, profiles, plr, mode)
	local sess = current(plr)
	if not sess or sess.committing then
		return
	end
	mode = (mode == "coinflip") and "coinflip" or "trade"
	if mode == "coinflip" and not TradeService.COINFLIP_ENABLED then
		return toast(net, plr, "Coinflips are turned off")
	end
	if sess.mode == mode then
		return
	end
	sess.mode = mode
	resetAccepts(sess)
	sess.note = mode == "coinflip"
		and (nameOf(plr.UserId) .. " made this a COINFLIP -- winner takes everything on the table")
		or (nameOf(plr.UserId) .. " switched back to a normal TRADE")
	sync(net, sess, profiles)
end

-- WANT / NO on one of the OTHER player's items, on the table or in their bag.
function TradeService.mark(net, profiles, plr, payload)
	local sess = current(plr)
	if not sess or sess.committing or type(payload) ~= "table" then
		return
	end
	local key = payload.key
	if type(key) ~= "string" or #key > 80 then
		return
	end
	local kind = key:match("^(%a+):.+$")
	if not KIND_OK[kind] then
		return
	end
	local me = sideOf(sess, plr.UserId)
	local marks = sess["marks" .. me]
	local mark = (payload.mark == "want" or payload.mark == "no") and payload.mark or nil
	if mark and not marks[key] then
		local n = 0
		for _ in pairs(marks) do
			n += 1
		end
		if n >= TradeService.MAX_MARKS then
			return toast(net, plr, "That's a lot of marks -- clear a few first")
		end
	end
	marks[key] = mark
	sync(net, sess, profiles)
end

-- A number on the other player's currency: "I want this many".
function TradeService.want(net, profiles, plr, payload)
	local sess = current(plr)
	if not sess or sess.committing or type(payload) ~= "table" then
		return
	end
	local me = sideOf(sess, plr.UserId)
	local asks = sess["asks" .. me]
	for _, k in ipairs(CURRENCY_ORDER) do
		if payload[k] ~= nil then
			asks[k] = math.clamp(math.floor(tonumber(payload[k]) or 0), 0, 1e12)
		end
	end
	sync(net, sess, profiles)
end

-- The other player's tradeable items, so you can point at what you want.
function TradeService.peek(net, profiles, plr, deps)
	local sess = current(plr)
	if not sess then
		return
	end
	local now = os.clock()
	if now - (lastPeek[plr.UserId] or -99) < 1.5 then
		return
	end
	lastPeek[plr.UserId] = now
	deps = deps or {}
	local _, them = sideOf(sess, plr.UserId)
	local theirId = them == "A" and sess.a or sess.b
	local p = profiles[theirId]
	if not p then
		return
	end
	local out = { owner = theirId, cards = {}, packs = {}, runes = {}, gear = {} }
	local left = TradeService.PEEK_MAX
	for _, c in ipairs(p.cards or {}) do
		local serial = type(c) == "table" and (c.serial or c.id)
		if left > 0 and type(serial) == "string" and (not deps.isCardSerial or deps.isCardSerial(serial)) then
			table.insert(out.cards, c)
			left -= 1
		end
	end
	for _, pk in ipairs(p.packs or {}) do
		if left > 0 and type(pk) == "table" and pk.uid then
			table.insert(out.packs, pk)
			left -= 1
		end
	end
	for _, r in ipairs(p.runes or {}) do
		if left > 0 and type(r) == "table" and r.id and not (deps.runeBusy and deps.runeBusy(p, r.id)) then
			table.insert(out.runes, r)
			left -= 1
		end
	end
	for _, g in ipairs(p.gear or {}) do
		if left > 0 and type(g) == "table" and g.id and not gearWorn(p, g) then
			table.insert(out.gear, g)
			left -= 1
		end
	end
	net:FireClient(plr, "tradePeek", out)
end

--------------------------------------------------------------------------------
-- Commit
--------------------------------------------------------------------------------

local function removeRows(list, rows)
	local drop = {}
	for _, r in ipairs(rows) do
		drop[r] = true
	end
	local keep = {}
	for _, r in ipairs(list or {}) do
		if not drop[r] then
			table.insert(keep, r)
		end
	end
	return keep
end

local function append(list, rows)
	for _, r in ipairs(rows) do
		table.insert(list, r)
	end
end

-- Every named item and amount, found in the profile as it is right now, or a
-- reason why not.
local function gather(p, o, deps)
	for _, k in ipairs(CURRENCY_ORDER) do
		if balance(p, k) < o[k] then
			return nil, "not enough " .. (k == "dust" and "stardust" or k)
		end
	end
	local items = { cards = {}, packs = {}, runes = {}, gear = {}, potions = {} }
	for _, serial in ipairs(o.cards) do
		local _, c = findCard(p, serial)
		if not c then return nil, "a card is no longer there" end
		table.insert(items.cards, c)
	end
	for _, uid in ipairs(o.packs) do
		local _, pk = findBy(p.packs, "uid", uid)
		if not pk then return nil, "a pack is no longer there" end
		table.insert(items.packs, pk)
	end
	for _, id in ipairs(o.runes) do
		local _, r = findBy(p.runes, "id", id)
		if not r or (deps.runeBusy and deps.runeBusy(p, id)) then
			return nil, "a rune is gone or socketed"
		end
		table.insert(items.runes, r)
	end
	for _, id in ipairs(o.gear) do
		local _, g = findBy(p.gear, "id", id)
		if not g or gearWorn(p, g) then
			return nil, "a gear piece is gone or being worn"
		end
		table.insert(items.gear, g)
	end
	do
		local need = {}
		for _, id in ipairs(o.potions or {}) do
			need[id] = (need[id] or 0) + 1
		end
		local bag = p.potions or {}
		for id, n in pairs(need) do
			if (tonumber(bag[id]) or 0) < n then
				return nil, "a potion is gone"
			end
			for _ = 1, n do
				table.insert(items.potions, { id = id })
			end
		end
	end
	return items
end

local function escrow(p, items, o)
	for _, k in ipairs(CURRENCY_ORDER) do
		local field = CURRENCY[k]
		p[field] = (tonumber(p[field]) or 0) - o[k]
	end
	p.cards = removeRows(p.cards, items.cards)
	p.packs = removeRows(p.packs, items.packs)
	p.runes = removeRows(p.runes, items.runes)
	p.gear = removeRows(p.gear, items.gear)
	do
		local bag = p.potions or {}
		for _, row in ipairs(items.potions or {}) do
			local id = row.id or row
			bag[id] = (tonumber(bag[id]) or 0) - 1
			if bag[id] <= 0 then bag[id] = nil end
		end
		p.potions = bag
	end
	local gone = {}
	for _, c in ipairs(items.cards) do
		gone[c.serial or c.id] = true
	end
	local eq = {}
	for _, id in ipairs(p.equipped or {}) do
		if not gone[id] then
			table.insert(eq, id)
		end
	end
	p.equipped = eq
end

local function deliver(p, items, o)
	for _, k in ipairs(CURRENCY_ORDER) do
		local field = CURRENCY[k]
		p[field] = (tonumber(p[field]) or 0) + o[k]
	end
	p.cards = p.cards or {}
	p.packs = p.packs or {}
	p.runes = p.runes or {}
	p.gear = p.gear or {}
	for _, c in ipairs(items.cards) do
		local serial = c.serial or c.id
		c.id, c.serial = serial, serial
		table.insert(p.cards, c)
	end
	append(p.packs, items.packs)
	append(p.runes, items.runes)
	append(p.gear, items.gear)
	p.potions = p.potions or {}
	for _, row in ipairs(items.potions or {}) do
		local id = row.id or row
		p.potions[id] = (tonumber(p.potions[id]) or 0) + 1
	end
end

-- "1,200 Stardust + 12 Tokens & 5,000 Gems"
local function currencyLine(dust, tokens, gems)
	local parts = {}
	if dust > 0 then table.insert(parts, commas(dust) .. " Stardust") end
	if tokens > 0 then table.insert(parts, commas(tokens) .. (tokens == 1 and " Token" or " Tokens")) end
	if gems > 0 then table.insert(parts, commas(gems) .. " Gems") end
	if #parts == 0 then
		return nil
	end
	if #parts == 1 then
		return parts[1]
	end
	return table.concat(parts, " + ", 1, #parts - 1) .. " & " .. parts[#parts]
end

local function announceFlip(net, sess, winnerId, loserId, viewA, viewB)
	local dust = sess.offerA.dust + sess.offerB.dust
	local tokens = sess.offerA.tokens + sess.offerB.tokens
	local gems = sess.offerA.gems + sess.offerB.gems
	local loot = lootValue(viewA) + lootValue(viewB)
	local money = currencyLine(dust, tokens, gems)
	local stake
	if money and loot > 0 then
		stake = money .. " and " .. commas(loot) .. " worth of loot"
	elseif money then
		stake = money
	else
		stake = commas(loot) .. " worth of loot"
	end
	local text = string.format("%s just beat %s in a coinflip for %s!", nameOf(winnerId), nameOf(loserId), stake)
	net:FireAllClients("sysChat", { text = text, color = "#FFCE5C" })
	print("[Coinflip] " .. text)
end

local function commit(net, profiles, sess, deps)
	sess.committing = true
	sync(net, sess, profiles)
	local function close(msg, ok, result)
		sess.committing = false
		sessions[sess.id] = nil
		byPlayer[sess.a] = nil
		byPlayer[sess.b] = nil
		for _, id in ipairs({ sess.a, sess.b }) do
			local plr = plrOf(id)
			if plr then
				net:FireClient(plr, ok and "tradeResult" or "tradeClosed", ok and (result or { ok = true }) or msg)
				if msg then
					toast(net, plr, msg)
				end
				if deps.push then
					pcall(deps.push, plr)
				end
			end
		end
		if ok and deps.save then
			for _, id in ipairs({ sess.a, sess.b }) do
				local plr = plrOf(id)
				if plr then
					task.spawn(deps.save, plr)
				end
			end
		end
	end

	local a, b = profiles[sess.a], profiles[sess.b]
	if not a or not b or a._ephemeral or b._ephemeral then
		return close("Trade failed: a player left", false)
	end

	-- 1. Check both sides against the profiles as they are now. A coinflip
	-- checks the winner's stake too: you cannot win against a pot that is not
	-- there.
	local itemsA, whyA = gather(a, sess.offerA, deps)
	local itemsB, whyB = gather(b, sess.offerB, deps)
	if not itemsA or not itemsB then
		return close("Trade cancelled: " .. tostring(whyA or whyB), false)
	end
	local viewA = expand(a, sess.offerA)
	local viewB = expand(b, sess.offerB)

	-- Who gives what. A trade moves both sides across; a coinflip moves only
	-- the loser's stake to the winner.
	local moves
	local winnerId, loserId
	if sess.mode == "coinflip" then
		local aWins = Random.new():NextNumber() < 0.5
		winnerId = aWins and sess.a or sess.b
		loserId = aWins and sess.b or sess.a
		if aWins then
			moves = { { from = sess.b, to = sess.a, items = itemsB, offer = sess.offerB } }
		else
			moves = { { from = sess.a, to = sess.b, items = itemsA, offer = sess.offerA } }
		end
	else
		moves = {
			{ from = sess.a, to = sess.b, items = itemsA, offer = sess.offerA },
			{ from = sess.b, to = sess.a, items = itemsB, offer = sess.offerB },
		}
	end

	-- 2. Take everything that moves out of its owner, in the same step. (What
	-- each had equipped is remembered, so a rollback restores it exactly.)
	local eqs = {}
	for _, m in ipairs(moves) do
		local p = profiles[m.from]
		eqs[m.from] = table.clone(p.equipped or {})
		escrow(p, m.items, m.offer)
	end

	-- 3. Move card ownership in the registry. This yields.
	local moved, failed = {}, false
	for _, m in ipairs(moves) do
		for _, c in ipairs(m.items.cards) do
			local serial = c.serial or c.id
			local ok = deps.transferSerial and deps.transferSerial(serial, m.from, m.to)
			if not ok then
				failed = true
				break
			end
			table.insert(moved, { serial = serial, from = m.from, to = m.to })
		end
		if failed then
			break
		end
	end

	-- Profiles cannot vanish during this: onLeave waits for the commit.
	a, b = profiles[sess.a], profiles[sess.b]
	if failed or not a or not b then
		for i = #moved, 1, -1 do
			local mv = moved[i]
			pcall(deps.transferSerial, mv.serial, mv.to, mv.from)
		end
		for _, m in ipairs(moves) do
			local p = profiles[m.from]
			if p then
				deliver(p, m.items, m.offer)
				p.equipped = eqs[m.from]
			end
		end
		warn(string.format("[Trade] %d <-> %d rolled back (registry move failed)", sess.a, sess.b))
		return close("Trade failed -- nothing moved. Try again in a moment.", false)
	end

	-- 4. Deliver, save both, and tell them.
	for _, m in ipairs(moves) do
		deliver(profiles[m.to], m.items, m.offer)
		print(string.format("[Trade] %d -> %d: %d cards %d packs %d runes %d gear, %d gems %d dust %d tokens%s",
			m.from, m.to, #m.items.cards, #m.items.packs, #m.items.runes, #m.items.gear,
			m.offer.gems, m.offer.dust, m.offer.tokens, sess.mode == "coinflip" and " (coinflip)" or ""))
	end
	if sess.mode == "coinflip" then
		local result = {
			ok = true,
			coinflip = true,
			winner = winnerId,
			loser = loserId,
			winnerName = nameOf(winnerId),
			loserName = nameOf(loserId),
		}
		announceFlip(net, sess, winnerId, loserId, viewA, viewB)
		close(nil, true, result)
	else
		close("Trade complete!", true)
	end
end

-- Stage one. ACCEPT toggles while drafting; both on starts the countdown.
function TradeService.accept(net, profiles, plr, deps)
	local sess = current(plr)
	if not sess or sess.committing or sess.confirmAt then
		return
	end
	local me = sideOf(sess, plr.UserId)
	if sess["accept" .. me] then
		sess["accept" .. me] = false
		return sync(net, sess, profiles)
	end
	if sess.mode == "coinflip" then
		if not (hasAnything(sess.offerA) and hasAnything(sess.offerB)) then
			return toast(net, plr, "A coinflip needs something from both of you")
		end
	elseif not (hasAnything(sess.offerA) or hasAnything(sess.offerB)) then
		return toast(net, plr, "Nothing has been offered yet")
	end
	sess["accept" .. me] = true
	if sess.acceptA and sess.acceptB then
		sess.confirmAt = os.clock() + TradeService.CONFIRM_DELAY
		local id, at = sess.id, sess.confirmAt
		-- Tell both windows the moment CONFIRM unlocks.
		task.delay(TradeService.CONFIRM_DELAY + 0.05, function()
			local s2 = sessions[id]
			if s2 and s2.confirmAt == at and not s2.committing then
				sync(net, s2, profiles)
			end
		end)
	end
	sync(net, sess, profiles)
end

-- Stage two: only after the countdown, and only both.
function TradeService.confirm(net, profiles, plr, deps)
	deps = deps or {}
	local sess = current(plr)
	if not sess or sess.committing or not sess.confirmAt then
		return
	end
	if os.clock() < sess.confirmAt - 0.05 then
		return toast(net, plr, "Hold on -- CONFIRM unlocks in a moment")
	end
	local me = sideOf(sess, plr.UserId)
	sess["confirm" .. me] = true
	sync(net, sess, profiles)
	if sess.confirmA and sess.confirmB then
		commit(net, profiles, sess, deps)
	end
end

-- Out of the countdown and back to drafting.
function TradeService.back(net, profiles, plr)
	local sess = current(plr)
	if not sess or sess.committing or not sess.confirmAt then
		return
	end
	resetAccepts(sess)
	sess.note = nameOf(plr.UserId) .. " wants to change the deal"
	sync(net, sess, profiles)
end

-- Kept for old clients: READY is now the first ACCEPT.
function TradeService.setReady(net, profiles, plr, ready)
	local sess = current(plr)
	if not sess then
		return
	end
	local me = sideOf(sess, plr.UserId)
	if (ready and true or false) ~= sess["accept" .. me] then
		TradeService.accept(net, profiles, plr)
	end
end

function TradeService.onLeave(net, userId)
	invites[userId] = nil
	for to, inv in pairs(invites) do
		if inv.from == userId then
			invites[to] = nil
		end
	end
	lastInvite[userId] = nil
	lastPeek[userId] = nil
	joinedAt[userId] = nil
	local sid = byPlayer[userId]
	local sess = sid and sessions[sid]
	if sess and sess.committing then
		-- Let the commit land first, so this player's final save includes it.
		local deadline = os.clock() + 15
		while sess.committing and os.clock() < deadline do
			task.wait(0.05)
		end
	end
	if byPlayer[userId] then
		TradeService.cancel(net, userId, "Your trade partner left")
	end
end

return TradeService
