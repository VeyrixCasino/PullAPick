--[[
	MineCharmService -- the charm verbs that changed on 2026-10-19, on the server.

	The rules and numbers are MineCharms (shared): one rarity per charm forever,
	a tier I to V, a merge that costs gems plus any charm of the same tier, and
	the eight Charm Packs. MineServer wires this in as Verbs.Charm (MineServer
	sits at Luau's 200-local ceiling, so new verbs live here) and calls:

	  init(ctx)                   ctx = { profiles, net, snap, markDirty, walk,
	                              bumpStat, benchNum, save }
	  merge(plr, payload)         Verbs.mergeCharm: { id, tier, fodderId }
	  buyPack(plr, payload)       buyCharmPack: { rarity | packId, pay = "gems" | "credits" }
	  normalize(p)                on load: the tier save is a table and agrees
	                              with the tally

	SERVER-AUTHORITATIVE. The client names a charm, a tier and the charm to use
	up, or a pack and a currency. Every price, every count and every draw is
	read here from MineCharms, never from the payload.
]]
local RS = game:GetService("ReplicatedStorage")

local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local Charms = require(shared:WaitForChild("MineCharms"))

local S = {}
local ctx = {}

function S.init(c)
	ctx = c or {}
end

local function toast(plr, text)
	if ctx.net then
		ctx.net:FireClient(plr, "toast", text)
	end
end

local function num(n)
	if ctx.benchNum then
		local ok, s = pcall(ctx.benchNum, n)
		if ok and s then
			return s
		end
	end
	return tostring(math.floor(tonumber(n) or 0))
end

local function done(plr, p, walk)
	if ctx.markDirty then
		ctx.markDirty(plr)
	end
	if ctx.snap then
		ctx.snap(plr)
	end
	if walk and ctx.walk then
		ctx.walk(plr)
	end
end

-- The tier save is a table, and no charm claims more high-tier copies than
-- the tally holds (MineCharms.normalizeTiers; MineServer's load calls it too).
function S.normalize(p)
	Charms.normalizeTiers(p)
end

--[[
	MERGE: raise one copy of a charm a tier (I -> II ... IV -> V), paying gems
	and using up any one charm of the same tier (owner, 2026-10-19: "teir i to
	v"; gems "plus any charm of the same tier"; "never changes the charm's
	rarity"). `tier` is the copy's tier now; `fodderId` the charm used up. An
	old client sending only { id } merges its lowest tier with the cheapest
	charm it can spare (MineCharms.fodderFor), so the button still works.
]]
function S.merge(plr, payload)
	local p = ctx.profiles and ctx.profiles[plr.UserId]
	if not p then
		return
	end
	S.normalize(p)
	local id = payload
	if type(payload) == "table" then
		id = payload.id or payload.charmId or payload.charm
	end
	id = tostring(id or "")
	local def = Charms.byId(id)
	if not def then
		toast(plr, "That charm is not in the game")
		return
	end
	local tier = math.floor(tonumber(type(payload) == "table" and payload.tier) or 0)
	local fodderId = type(payload) == "table" and payload.fodderId and tostring(payload.fodderId) or nil
	if tier < 1 or not fodderId then
		-- The old one-tap merge: the lowest tier that has fodder, cheapest fodder.
		local counts = Charms.tierCounts(p, id)
		for t = 1, Charms.TIER_MAX - 1 do
			if counts[t] > 0 then
				local list = Charms.fodderFor(p, id, t)
				if list[1] then
					tier, fodderId = t, list[1].id
					break
				end
			end
		end
		if not fodderId then
			toast(plr, "Merging needs another charm at the same tier")
			return
		end
	end
	local ok, res = Charms.applyMerge(p, id, tier, fodderId)
	if not ok then
		toast(plr, tostring(res or "That charm cannot merge"))
		return
	end
	if ctx.bumpStat then
		pcall(ctx.bumpStat, plr, p, "merges")
	end
	local fdef = Charms.byId(fodderId)
	toast(plr, string.format("%s  ->  tier %s  (-%s gems, used %s)",
		def.name, Charms.romanTier(res.toTier), num(res.cost), fdef and fdef.name or fodderId))
	if ctx.net then
		ctx.net:FireClient(plr, "foundTool", {
			kind = "charm",
			charmId = def.id,
			name = def.name .. " " .. Charms.romanTier(res.toTier),
			title = "CHARM MERGED",
			rarityId = (Charms.RARITY_LABEL and Charms.RARITY_LABEL[def.rarity]) or "Legendary",
			blurb = Charms.describe(def, nil, res.toTier),
		})
	end
	done(plr, p, true)
end

--[[
	BUY ONE CHARM PACK (owner, 2026-10-19: eight Charm Packs, "{rarity} Charm
	Pack", for gems or credits). One charm of the pack's rarity at tier I,
	drawn by MineCharms.rollCharmPack -- the draw charmPackOdds shows. A paid
	random item: Verbs.PAID_RANDOM blocks it where the player's rules do.
	The draw resolves before anything is charged, so a pack that cannot pay
	never costs.
]]
function S.buyPack(plr, payload)
	local p = ctx.profiles and ctx.profiles[plr.UserId]
	if not p then
		return
	end
	local key = payload
	if type(payload) == "table" then
		key = payload.rarity or payload.packId or payload.id
	end
	local pack = Charms.charmPack(tostring(key or ""))
	if not pack then
		toast(plr, "That Charm Pack is not on the shelf")
		return
	end
	local pay = (type(payload) == "table" and payload.pay == "credits") and "credits" or "gems"
	local price = (pay == "credits") and pack.credits or pack.gems
	price = math.max(1, math.floor(tonumber(price) or 0))
	local have = math.floor(tonumber(pay == "credits" and p.credits or p.gems) or 0)
	if have < price then
		toast(plr, string.format("%s costs %s %s (you have %s)", pack.name, num(price),
			pay == "credits" and "credits" or "gems", num(have)))
		return
	end
	local def = Charms.rollCharmPack(pack.rarity, Random.new())
	if not def then
		toast(plr, pack.name .. " has nothing in it yet")
		return
	end
	if pay == "credits" then
		p.credits = have - price
	else
		p.gems = have - price
	end
	p.charms = p.charms or {}
	-- A tally, like every other charm grant: a new copy at tier I. (A legacy
	-- `true` is one copy, as everywhere else.)
	local had = p.charms[def.id]
	if had == true then
		had = 1
	end
	p.charms[def.id] = (tonumber(had) or 0) + 1
	local wearing = type(p.equippedCharm) == "string" and p.equippedCharm ~= ""
	if not wearing then
		p.equippedCharm = def.id
	end
	toast(plr, string.format("%s: %s%s", pack.name, def.name,
		wearing and " -- equip it in Inventory -> Equipment" or " -- equipped"))
	if ctx.net then
		-- The pack opens like a pack (MinePackReveal, forced): that is the buy fx.
		ctx.net:FireClient(plr, "foundTool", {
			kind = "charm",
			charmId = def.id,
			name = def.name,
			title = string.upper(pack.name),
			rarityId = (Charms.RARITY_LABEL and Charms.RARITY_LABEL[def.rarity]) or "Legendary",
			blurb = (def.blurb or "") .. "  ·  " .. pack.word .. " (" .. pack.rarity .. ")",
		})
	end
	done(plr, p, true)
	-- A purchase is saved at once, like the other gem and credit buys.
	if ctx.save then
		ctx.save(plr)
	end
end

return S
