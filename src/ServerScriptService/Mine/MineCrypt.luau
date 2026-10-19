--[[
	MineCrypt -- the Candy Crypt on the server (owner's redesign, 2026-10-19;
	wiki/open-questions.md §0e). The rules and numbers are MineCryptRules,
	MineCandyTools and MineTrickOrTreat (shared); this module owns the profile,
	the grants and the verbs, and is the authority for every roll and payout.

	MineServer wires it in as Verbs.Crypt (and Dig.Crypt, for the functions
	declared above Verbs) and calls:

	  init(ctx)                          ctx = { profiles, net, snap, markDirty,
	                                     givePickaxe, bumpStat, pouchTier,
	                                     pouchFullToast, chestXp }
	  normalize(p)                       on load: shape the save, repair a claim
	                                     with no tool
	  dispatch(plr, action, payload)     every remote action starting "crypt"
	  heldTool(p)                        equippedTool's swap (MineCryptRules.heldRow)
	  onClaim(plr, p, zone)              the Crypt was just claimed: starter pick
	  onEnterZone(plr, p, zone, fromId)  re-give the held tool; first-entry pop-up
	  onBlockBroken(plr, p, part, kind, layer, bb)   a candy block's candy + ore
	  haulPoints(p, landed, layer)       the Crypt's low coin curve, for payDamage
	  chestSpawnDef(layer)               what a Crypt chest is called and looks like
	  openChest(plr, p, part, b)         what a Crypt chest pays
	  buyTrickOrTreat(plr)               buy and open one case
	  snapState(p)                       the snapshot's `crypt` block
	                                     (MineServer also sends `limitedOpen`,
	                                     { [zoneId] = open } for every limited zone)

	REMOTE ACTIONS (client -> server), all through net:FireServer(action, payload):

	  cryptEquip          { key = "<toolId>|<variant>" }   hold that stack
	                      { world = true | false }         hold it in the main world
	                                                       (refused until the event ends)
	  cryptMerge          { key, times = n | all = true }  3 copies -> next variant
	  cryptSellCandyOres  { oreIds = { ... }, counts = { [id] = n }? } or { all = true },
	                      then the same with confirm = true
	  cryptCraftCharm     { charmId }                      a Halloween charm
	  cryptNoticeSeen     { zoneId = "hallow" }            the pop-up was shown
	  buyTrickOrTreat     (no payload; the old verb, now served from here)

	PUSHES (server -> client):

	  eventNotice            { zoneId, title, text }       first entry, until seen
	  cryptSellCandyConfirm  { units, candy, rows = { { id, name, n, candy } },
	                           lockedSkipped }
	  cryptMerged            { from, to, times, name }
	  trickOrTreatOpened     { kind, label, name, key?, id?, variant?, oreId?,
	                           packId?, price, candyLeft }
	  chestOpened            (the zone-chest event) with kind = "crypt", candy,
	                           cryptTool = { key, id, name, family, tier } or nil
	  foundTool              a chest's Crypt tool and a crafted charm, as reveals
]]
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local C = require(shared:WaitForChild("MineConfig"))
local R = require(shared:WaitForChild("MineCryptRules"))
local Tools = require(shared:WaitForChild("MineCandyTools"))
local Charms = require(shared:WaitForChild("MineCharms"))
local Pouch = require(shared:WaitForChild("MineOrePouch"))

local S = {}
local ctx = {}

-- The fraction of a coin the Crypt's haul owes, per profile. Weak keys, and
-- never on the profile: save() writes the profile table whole.
local carry = setmetatable({}, { __mode = "k" })

function S.init(c)
	ctx = c or {}
end

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

--------------------------------------------------------------------------------
-- THE PROFILE
--------------------------------------------------------------------------------

S.count = R.count

-- The best stack a player owns: deepest tier, then best variant, pick first.
function S.bestKey(p)
	local bestKey, bestScore = nil, -1
	local famOrder = {}
	for i, f in ipairs(Tools.FAMILIES) do
		famOrder[f] = i
	end
	for key, n in pairs(type(p.cryptTools) == "table" and p.cryptTools or {}) do
		local def, variant = R.defOf(key)
		if def and (tonumber(n) or 0) > 0 then
			local score = def.tier * 100 + (R.VARIANT_RANK[variant] or 0) * 10 + (10 - (famOrder[def.family] or 9))
			if score > bestScore then
				bestKey, bestScore = key, score
			end
		end
	end
	return bestKey
end

--[[
	Shape the save. Idempotent, and cheap enough to run on every verb: drops a
	stack key that names no real tool or variant, floors counts, points the
	equip at something owned, and makes the flags plain values.
]]
function S.ensure(p)
	if type(p) ~= "table" then
		return p
	end
	if type(p.cryptTools) ~= "table" then
		p.cryptTools = {}
	end
	for key, n in pairs(p.cryptTools) do
		local c = math.floor(tonumber(n) or 0)
		if not R.defOf(key) or c <= 0 then
			p.cryptTools[key] = nil
		elseif c ~= n then
			p.cryptTools[key] = c
		end
	end
	if type(p.cryptToolEquipped) ~= "string" or S.count(p, p.cryptToolEquipped) <= 0 then
		p.cryptToolEquipped = S.bestKey(p)
	end
	if p.cryptToolWorld ~= true then
		p.cryptToolWorld = nil
	end
	if type(p.eventNoticeSeen) ~= "table" then
		p.eventNoticeSeen = {}
	end
	if type(p.candySeen) ~= "table" then
		p.candySeen = {}
	end
	p.candy = math.max(0, math.floor(tonumber(p.candy) or 0))
	return p
end

--[[
	Add `n` copies of a tool to the save. Returns the stack key, or nil when the
	id is not a Crypt tool. Equips it when nothing is in hand. `plr` may be nil
	(load-time repair), in which case nothing is told to anyone.
]]
function S.grantTool(plr, p, id, variant, n, source)
	local def = Tools.byId(id)
	variant = variant or "Normal"
	if not def or not R.validVariant(variant) then
		return nil
	end
	S.ensure(p)
	local key = R.stackKey(def.id, variant)
	n = math.max(1, math.floor(tonumber(n) or 1))
	p.cryptTools[key] = S.count(p, key) + n
	if not p.cryptToolEquipped then
		p.cryptToolEquipped = key
		regive(plr)
	end
	dirty(plr)
	return key
end

-- Room-checked, like Dig.addOre, but a candy ore never enters `oresSeen`: that
-- list is the Forge's recipe rail, and candy is not forged.
function S.addCandyOre(p, oreId, n)
	local ore = C.candyOreById(oreId)
	n = math.max(0, math.floor(tonumber(n) or 0))
	if not ore or n <= 0 then
		return 0, n
	end
	p.ores = p.ores or {}
	p.candySeen = p.candySeen or {}
	p.candySeen[ore.id] = true
	local tier = (ctx.pouchTier and ctx.pouchTier(p)) or p.orePouchTier or 1
	local room = Pouch.room(p.ores, tier)
	local got = math.min(n, room)
	if got > 0 then
		p.ores[ore.id] = (tonumber(p.ores[ore.id]) or 0) + got
	end
	return got, n - got
end

-- Candy after the bag (the Trick-or-Treat Bucket's candyMult) and the worn
-- charm's Candy Find. `b` is the caller's boosts table, when it has one.
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

function S.normalize(p)
	S.ensure(p)
	-- A claim always came with a pick. A save that has the claim and no tool
	-- (claimed before 2026-10-19, or a merge bug) gets the starter back.
	if p.hallowOwned == true and next(p.cryptTools) == nil then
		S.grantTool(nil, p, Tools.STARTER_ID, "Normal", 1, "repair")
	end
	return p
end

--------------------------------------------------------------------------------
-- HOOKS MineServer calls
--------------------------------------------------------------------------------

function S.heldTool(p)
	return R.heldRow(p, p and p.zoneId, nil)
end

function S.onClaim(plr, p, zone)
	S.ensure(p)
	local gave = false
	if next(p.cryptTools) == nil then
		gave = S.grantTool(plr, p, Tools.STARTER_ID, "Normal", 1, "claim") ~= nil
		local def = Tools.byId(Tools.STARTER_ID)
		if gave and def then
			fire(plr, "foundTool", {
				kind = "cryptTool",
				name = def.name,
				rarityId = def.rarityId,
				title = "FREE EVENT TOOL",
				blurb = def.warning,
			})
		end
	end
	toast(plr, ("%s claimed%s -- only event tools dig here"):format(
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
	A CANDY BLOCK PAYS candy AND one unit of its candy ore (owner, 2026-10-19),
	whatever kind of block the candy sits in. It used to pay only from an ORE
	block -- the payout sat inside finishBreak's ore branch while spawnVoxel
	paints candy onto any block -- so in practice almost no candy block paid.
	Returns true when it paid.
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
	local oreId = part:GetAttribute("CandyOre")
	local ore = C.candyOreById(oreId)
	local kept, spilled = S.addCandyOre(p, oreId, 1)
	local text = ("+%s candy"):format(short(candy))
	if kept > 0 and ore then
		text = text .. ("  +1 %s"):format(ore.name)
	end
	fire(plr, "loot", { text = text, color = part.Color, pos = part.Position })
	if spilled > 0 and ctx.pouchFullToast then
		ctx.pouchFullToast(plr, p)
	end
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

-- A Crypt chest, named for its band so "deeper is better" shows on the block.
function S.chestSpawnDef(layer)
	local tier = Tools.TIERS[Tools.tierForLayer(layer)] or Tools.TIERS[1]
	return {
		id = "crypt_chest_" .. tier.key,
		name = tier.name .. " Chest",
		kind = "chase",
		crypt = true,
	}
end

function S.openChest(plr, p, part, b)
	S.ensure(p)
	local layer = math.max(1, math.floor(tonumber(part and part:GetAttribute("CY")) or 1))
	local rng = Random.new()
	local def = S.chestSpawnDef(layer)
	if ctx.bumpStat then
		ctx.bumpStat(plr, p, "chests")
	end
	if ctx.chestXp then
		pcall(ctx.chestXp, plr, p)
	end
	local candy = S.candyMultiplied(p, R.chestCandy(layer), b)
	p.candy = math.max(0, math.floor((tonumber(p.candy) or 0) + candy))
	local tool = Tools.rollChestTool(layer, rng, b and b.chestLuck)
	local got = nil
	if tool then
		local key = S.grantTool(plr, p, tool.id, "Normal", 1, "chest")
		if key then
			got = { key = key, id = tool.id, name = tool.name, family = tool.family, tier = tool.tier }
		end
	end
	fire(plr, "chestOpened", {
		id = def.id,
		name = def.name,
		kind = "crypt",
		coins = 0,
		gems = 0,
		candy = candy,
		packs = got and { got.name } or {},
		cryptTool = got,
		pos = part and part.Position or nil,
	})
	fire(plr, "loot", {
		text = ("+%s candy"):format(short(candy)),
		color = Color3.fromRGB(255, 142, 44),
		pos = part and part.Position or nil,
	})
	if got then
		fire(plr, "foundTool", {
			kind = "cryptTool",
			name = got.name,
			rarityId = tool.rarityId,
			title = "CRYPT TOOL",
			blurb = tool.warning,
		})
	end
	dirty(plr)
end

--[[
	BUY AND OPEN A TRICK-OR-TREAT CASE. One verb, not two: the owner asked for
	candy you "trade in", so nothing sits unopened in a bag. The roll is
	MineTrickOrTreat.roll (a plain description, no side effects); the grant is
	here, and a grant that cannot happen refunds the whole price.
]]
function S.buyTrickOrTreat(plr)
	local p = ctx.profiles and ctx.profiles[plr.UserId]
	if not p then
		return
	end
	S.ensure(p)
	local TT = require(shared:WaitForChild("MineTrickOrTreat"))
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
	local price = math.max(1, math.floor(tonumber(TT.PRICE) or 2500))
	if p.candy < price then
		toast(plr, ("Need %s candy"):format(short(price)))
		return
	end
	p.candy -= price

	local prize = TT.roll(Random.new()) or { kind = "hat" }
	local out = { kind = prize.kind, label = TT.LABEL[prize.kind] or prize.kind, price = price }
	local ok = false
	if prize.kind == "tool" then
		local key = S.grantTool(plr, p, prize.id, "Normal", 1, "case")
		local def = Tools.byId(prize.id)
		if key and def then
			ok = true
			out.key, out.id, out.variant, out.name = key, def.id, "Normal", def.name
			out.family, out.tier = def.family, def.tier
		end
	elseif prize.kind == "skincase" then
		--[[
			A SKIN CASE IS A CASE YOU OPEN. The same bag row a broken ore block
			drops (`<ore>_ore_case`): it opens to a skin or that ore's charm, by
			whatever rule ore cases follow.
		]]
		local ore = C.ORES and C.ORES[math.floor(tonumber(prize.oreTier) or 0)]
		if ore then
			p.packs = p.packs or {}
			table.insert(p.packs, {
				packId = ore.id .. "_ore_case",
				packName = ore.name .. " Case",
				kind = "ore_case",
				oreId = ore.id,
			})
			ok = true
			out.oreId, out.name = ore.id, ore.name .. " Case"
		end
	elseif prize.kind == "hat" then
		-- Head-slot gear, rolled the one way the chest path rolls it. `p.gear`
		-- is an ARRAY of pieces; there is no hat-id set on the profile.
		local okG, Gear = pcall(function()
			return require(shared:WaitForChild("MineGear"))
		end)
		local piece = okG and Gear and Gear.rollPiece and Gear.rollPiece(hex16(), Random.new(), "head") or nil
		if piece then
			p.gear = p.gear or {}
			table.insert(p.gear, piece)
			ok = true
			out.name = piece.name or "a hat"
		end
	elseif prize.kind == "pack" and prize.id then
		--[[
			The bag row a pack needs: packId (what openPack resolves), its name
			and its set. This was { setId = id } alone, which openPack cannot
			resolve -- the Halloween pack would have opened as a legacy crate
			with no holiday pets in it.
		]]
		local okP, Packs = pcall(function()
			return require(shared:WaitForChild("MinePackConfig"))
		end)
		local pdef = okP and Packs and Packs.PACK_BY_ID and Packs.PACK_BY_ID[prize.id]
		if pdef then
			p.packs = p.packs or {}
			table.insert(p.packs, { packId = pdef.id, packName = pdef.name, setId = pdef.setKey })
			ok = true
			out.packId, out.name = pdef.id, pdef.name
		end
	elseif prize.kind == "bucket" then
		--[[
			The bucket is a BAG TIER, owned through a flag (p.trickBucket) the way
			the Wormhole Bag is, and equipped only when it is an upgrade: winning
			it must never demote someone carrying something bigger.
		]]
		local row, idx
		for i, r in ipairs(C.BACKPACKS or {}) do
			if r.limited == R.ZONE_ID then
				row, idx = r, i
				break
			end
		end
		if row and idx then
			p.trickBucket = true
			local cur = C.BACKPACKS[p.backpackTier]
			if not cur or (tonumber(row.slots) or 0) > (tonumber(cur.slots) or 0) then
				p.backpackTier = idx
			end
			ok = true
			out.name = row.name or "Trick-or-Treat Bucket"
		end
	end
	if not ok then
		p.candy += price
		out.kind, out.name = "refund", "nothing (refunded)"
	end
	out.candyLeft = p.candy
	dirty(plr)
	snapNow(plr)
	fire(plr, "trickOrTreatOpened", out)
	toast(plr, "Trick-or-Treat: " .. tostring(out.name or out.label))
end

function S.snapState(p)
	return R.stateFor(p, nil)
end

--------------------------------------------------------------------------------
-- THE VERBS
--------------------------------------------------------------------------------

local VERBS = {}

function VERBS.cryptEquip(plr, p, payload)
	if type(payload) ~= "table" then
		payload = { key = payload }
	end
	local said
	if payload.key ~= nil then
		local key = tostring(payload.key)
		local def, variant = R.defOf(key)
		if not def or S.count(p, key) <= 0 then
			toast(plr, "You do not have that tool")
			return
		end
		p.cryptToolEquipped = key
		said = ((variant ~= "Normal") and (variant .. " ") or "") .. def.name .. " equipped"
	end
	if payload.world == true then
		if not R.window().ended then
			toast(plr, R.WORLD_LOCKED_TEXT)
			return
		end
		if not R.equippedStack(p) then
			toast(plr, "You have no Crypt tool")
			return
		end
		p.cryptToolWorld = true
		said = (said or "Crypt tool") .. " -- held in the main world too"
	elseif payload.world == false then
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

function VERBS.cryptMerge(plr, p, payload)
	if type(payload) ~= "table" then
		payload = { key = payload }
	end
	local times = payload.all and math.huge or payload.times
	local plan, why = R.mergePlan(p, tostring(payload.key or ""), times)
	if not plan then
		toast(plr, why)
		return
	end
	local left = S.count(p, plan.from) - plan.consumed
	p.cryptTools[plan.from] = (left > 0) and left or nil
	p.cryptTools[plan.to] = S.count(p, plan.to) + plan.times
	local held = p.cryptToolEquipped == plan.from and left <= 0
	if held then
		-- Merging away the tool in hand hands you what it became.
		p.cryptToolEquipped = plan.to
		regive(plr)
	end
	local name = plan.nextVariant .. " " .. plan.def.name
	dirty(plr)
	snapNow(plr)
	fire(plr, "cryptMerged", { from = plan.from, to = plan.to, times = plan.times, name = name })
	toast(plr, ("%d x %s  ->  %d x %s"):format(plan.consumed,
		((plan.variant ~= "Normal") and (plan.variant .. " ") or "") .. plan.def.name, plan.times, name))
end

--[[
	SELL CANDY ORES FOR CANDY (owner, 2026-10-19: "tick candy ores to sell for
	candy"). Two calls, like SELL ALL: without `confirm` the server prices the
	sale and sends it back; with it, the sale happens, built by the same plan so
	the number agreed to is the number paid.

	Ticked ores (`oreIds`) sell even if locked: the player named them, the same
	as selling one ore row. `all = true` is the bulk button, and skips locked.
]]
function S.candySellPlan(p, payload)
	local ores = p.ores or {}
	local locks = p.oreLocks or {}
	local rows, units, candy, lockedSkipped = {}, 0, 0, 0
	local function add(id, want)
		local ore = C.candyOreById(id)
		local have = ore and math.max(0, math.floor(tonumber(ores[ore.id]) or 0)) or 0
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
			if (tonumber(ores[ore.id]) or 0) > 0 then
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
		local left = math.max(0, math.floor(tonumber(p.ores[row.id]) or 0) - row.n)
		p.ores[row.id] = (left > 0) and left or nil
	end
	p.candy += plan.candy
	dirty(plr)
	snapNow(plr)
	toast(plr, ("Sold %s candy ore  +%s candy"):format(short(plan.units), short(plan.candy)))
end

--[[
	CRAFT A HALLOWEEN CHARM from N of one candy ore (MineCharms.recipeFor).
	Charms tally, like every other charm grant, and the first one you own goes
	on if you wear nothing.
]]
function VERBS.cryptCraftCharm(plr, p, payload)
	local id = tostring((type(payload) == "table" and payload.charmId) or payload or "")
	local recipe = Charms.recipeFor(id)
	local def = Charms.byId(id)
	if not recipe or not def then
		toast(plr, "That charm is not crafted from candy")
		return
	end
	local ore = C.candyOreById(recipe.oreId)
	local cost = math.max(1, math.floor(tonumber(recipe.count) or 1))
	p.ores = p.ores or {}
	local have = math.max(0, math.floor(tonumber(p.ores[recipe.oreId]) or 0))
	if have < cost then
		toast(plr, ("Need %d %s (you have %d)"):format(cost, ore and ore.name or recipe.oreId, have))
		return
	end
	local left = have - cost
	p.ores[recipe.oreId] = (left > 0) and left or nil
	p.charms = p.charms or {}
	local had = p.charms[id]
	p.charms[id] = ((had == true) and 1 or math.max(0, math.floor(tonumber(had) or 0))) + 1
	local wearing = type(p.equippedCharm) == "string" and p.equippedCharm ~= ""
	if not wearing then
		p.equippedCharm = id
	end
	local how = wearing and "equip it in Inventory → Equipment" or "equipped"
	dirty(plr)
	snapNow(plr)
	fire(plr, "foundTool", {
		kind = "charm",
		charmId = id,
		name = def.name,
		title = "CHARM CRAFTED",
		rarityId = (Charms.RARITY_LABEL and Charms.RARITY_LABEL[def.rarity]) or "Legendary",
		blurb = (def.blurb or "") .. "  ·  " .. how,
	})
	toast(plr, "Crafted " .. def.name .. " -- " .. how)
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
