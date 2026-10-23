--[[
	MineEnchantService -- enchants and the player level, on the server.

	The rules and numbers are MineEnchants (shared). MineServer wires this in
	as Verbs.Ench and calls:

	  init(ctx)                       ctx = { profiles, net, snap, markDirty, onApply }
	                                  (onApply(plr, p): the tutorial's enchant step)
	  dispatch(plr, action, payload)  every remote action starting "ench"
	  snapState(p)                    the block the snapshot carries
	  gainXp(plr, p, amount)          ore blocks and chests pay XP
	  chestBundle(plr, p, rank, rng, chestLuck)   a chest's book bundle, sometimes
	  luckyBundle(p, blockId, rng)    a lucky block's bundle (shown by its reveal)
	  grantBundle(p, n, rank)         n books from a reward (the pass, the Founders
	                                  pack, the daily wheel); the giver says what
	  returnBooks(p, tool)            a tool being recycled gives its enchants back
	  special(p)                      the held tool's Special enchant (for boosts)
	  layerStats(p)                   the held tool's Damage/Utility stats (for boosts)
	  hitDamage(plr, p, part, dmg, maxHp)   a swing's damage, through the Damage
	                                  slot's mining enchant (crit, executioner,
	                                  demolition, combo, grave digger)
	  afterSwing(plr, p, oneShot, pos, blocks)  Overclock's and Sugar Rush's
	                                  streaks, after the swing lands (`blocks`:
	                                  how many it broke in one hit)
	  swingSpeed(p)                   Overclock's or Sugar Rush's swing speed now
	  spellCast(plr, p, b, broke, pos)  Spellbook: every few swings, the cast to
	                                  run through Dig.procsAt, or nil
	  flashlight(plr, p, zone, part, cells, keyOf, tool)  Flashlight, on a block
	                                  broken: maybe light the rarest ore near it
	  alchemy(plr, p, ore, pos)       an ore drop, maybe the next ore up
	  duplicate(plr, p, got, pos)     an ore count, maybe doubled
	  veinCount(p)                    how many vein blocks Vein Miner takes

	WHERE AN ENCHANT WORKS: every read below goes through E.activeHere with the
	zone the player is in, so inside the Candy Crypt only the Halloween four
	work (owner, 2026-10-19: in the Crypt "normal enchants don't work").

	SERVER-AUTHORITATIVE. The client names a tool, a slot and a book; this
	checks you own the tool and the book, the slot is unlocked at your level,
	the book belongs in that slot, it fits the tool's family and its effect is
	live. Nothing the client sends decides an amount.

	Saves:
	  p.enchantBooks = { ["power:1"] = 2, ... }
	  p.oreTools[i].enchants = { damage = { id, level }, utility = ..., special = ... }
	  p.level, p.xp  (the player level; kept through rebirth)
]]
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local E = require(shared:WaitForChild("MineEnchants"))

local S = {}
local ctx = {}

function S.ensure(p)
	if type(p.enchantBooks) ~= "table" then
		p.enchantBooks = {}
	end
	p.level = math.clamp(math.floor(tonumber(p.level) or 1), 1, E.MAX_PLAYER_LEVEL)
	p.xp = math.max(0, math.floor(tonumber(p.xp) or 0))
	return p
end

local function toast(plr, text)
	ctx.net:FireClient(plr, "toast", text)
end

local function findTool(p, uid)
	for i, t in ipairs(p.oreTools or {}) do
		if type(t) == "table" and t.uid == uid then
			return t, i
		end
	end
	return nil
end

local function heldTool(p)
	return p.oreToolEquipped and findTool(p, p.oreToolEquipped) or nil
end

local function addBook(p, id, level, n)
	local key = E.bookKey(id, level)
	p.enchantBooks[key] = (tonumber(p.enchantBooks[key]) or 0) + (n or 1)
end

local function takeBook(p, id, level, n)
	local key = E.bookKey(id, level)
	local have = tonumber(p.enchantBooks[key]) or 0
	if have < (n or 1) then
		return false
	end
	have -= (n or 1)
	p.enchantBooks[key] = (have > 0) and have or nil
	return true
end

-- ------------------------------------------------------------ boosts --

-- In a slot, unlocked at the player's level, and working where they stand.
local function counts(p, slot, e)
	return type(e) == "table" and E.slotUnlocked(slot, p.level) and E.activeHere(p.zoneId, e.id)
end

function S.special(p)
	local t = heldTool(p)
	local e = t and type(t.enchants) == "table" and t.enchants.special or nil
	if counts(p, "special", e) then
		return e
	end
	return nil
end

-- The held tool's Damage and Utility stats, for Layer 1: { { stat, value } }.
function S.layerStats(p)
	local out = {}
	local t = heldTool(p)
	if not (t and type(t.enchants) == "table") then
		return out
	end
	for _, slot in ipairs({ "damage", "utility" }) do
		local e = t.enchants[slot]
		if counts(p, slot, e) then
			for _, s in ipairs(E.statsAt(E.get(e.id), e.level)) do
				if s.how == "layer" then
					table.insert(out, s)
				end
			end
		end
	end
	return out
end

local function xpMult(p)
	local t = heldTool(p)
	local e = t and type(t.enchants) == "table" and t.enchants.utility or nil
	if counts(p, "utility", e) then
		for _, s in ipairs(E.statsAt(E.get(e.id), e.level)) do
			if s.how == "xp" then
				return s.value
			end
		end
	end
	return 1
end

-- ---------------------------------------------------- mining enchants --
--[[
	The eight that needed mining code (owner, 2026-10-12: "Make the 'coming
	soon' enchants actually work"). The maths is MineEnchants (hitMult,
	overclockSpeed, oreChance, veinBlocks); this keeps the two STREAKS and
	flashes the word over the block. Streaks are per player and never saved:
	a weak table keyed by the profile, so a leaving player takes theirs along.
]]
local streaks = setmetatable({}, { __mode = "k" })
local FLASH = {
	crit = Color3.fromRGB(255, 90, 70),
	combo = Color3.fromRGB(255, 160, 60),
	overclock = Color3.fromRGB(120, 220, 255),
	alchemy = Color3.fromRGB(200, 140, 255),
	duplicator = Color3.fromRGB(120, 255, 160),
	-- The Halloween four: candy pink, and the book's purple.
	sugar_rush = Color3.fromRGB(255, 120, 200),
	spell = Color3.fromRGB(180, 110, 255),
}

-- The held tool's live enchant in a slot, and its level, or nil.
local function slotEnchant(p, slot)
	local t = heldTool(p)
	local e = t and type(t.enchants) == "table" and t.enchants[slot] or nil
	if not counts(p, slot, e) then
		return nil
	end
	local def = E.get(e.id)
	if not (def and def.live) then
		return nil
	end
	return def, math.clamp(math.floor(tonumber(e.level) or 1), 1, E.MAX_LEVEL)
end

local function streak(p)
	local s = streaks[p]
	if not s then
		s = { combo = 0, comboAt = 0, oc = 0, ocAt = 0, rush = 0, rushAt = 0, spell = 0, flashReady = 0 }
		streaks[p] = s
	end
	return s
end

local function flash(plr, text, color, pos)
	if pos then
		ctx.net:FireClient(plr, "loot", { text = text, color = color, pos = pos })
	end
end

-- Round by chance, like the swing's own damage: x1.2 on a 1-damage hit is a
-- 2 one time in five rather than never.
local function roundByChance(x)
	local n = math.floor(x)
	if math.random() < (x - n) then
		n += 1
	end
	return math.max(1, n)
end

--[[
	The floor of the mine a block is in, for Grave Digger: the Candy Crypt's
	own depth inside the Crypt, MineConfig.LAYERS (5000) everywhere else --
	Meadow runs to 10,000 and is simply at full strength from 5,000 down.
]]
local Config
local function mineFloor(zoneId)
	Config = Config or require(shared:WaitForChild("MineConfig"))
	if tostring(zoneId or "") == "hallow" then
		return tonumber(Config.CANDY_DEPTH_LAYERS) or 120
	end
	return tonumber(Config.LAYERS) or 5000
end

function S.hitDamage(plr, p, part, dmg, maxHp)
	local def, level = slotEnchant(p, "damage")
	local kind = def and def.effect.kind
	if not (kind == "hit" or kind == "depth") or def.id == "overclock" then
		return dmg
	end
	local h = { dmg = dmg, maxHp = maxHp, hp = tonumber(part:GetAttribute("HP")) or maxHp, roll = math.random() }
	if kind == "depth" then
		h.layer = tonumber(part:GetAttribute("CY")) or 1
		h.floor = mineFloor(part:GetAttribute("ZoneId"))
	end
	if def.id == "combo" then
		local s, now = streak(p), os.clock()
		if now - s.comboAt > E.COMBO_GRACE then
			s.combo = 0
		end
		s.combo += 1
		s.comboAt = now
		h.combo = s.combo
		if s.combo % 25 == 0 and s.combo <= def.effect.stacks + 1 then
			flash(plr, "COMBO " .. s.combo, FLASH.combo, part.Position)
		end
	end
	local mult, word = E.hitMult(def, level, h)
	if word then
		flash(plr, word, FLASH[def.id] or FLASH.crit, part.Position)
	end
	if mult == 1 then
		return dmg
	end
	return roundByChance(dmg * mult)
end

--[[
	SUGAR RUSH (a Halloween Damage enchant; owner: "speed that stacks while
	breaking in combos [2% per block, one shot blocks only up to 100%]"). Every
	block this swing broke in one hit adds to the run -- the aimed block and the
	tool's own area cells, so a 3x3 drill adds nine -- while the aimed block
	itself was a one-shot. A swing whose aimed block takes more than one hit
	ends the run, and so does the grace without a one-shot. The client paces by
	the same "enchSpeed" event Overclock uses.
]]
local function sugarRush(plr, s, def, level, oneShot, pos, blocks)
	local t = E.TUNING.sugarRush
	local now = os.clock()
	local was = (now - s.rushAt <= t.grace) and s.rush or 0
	local add = math.max(1, math.floor(tonumber(blocks) or 1))
	s.rush = oneShot and math.min(t.maxBlocks, was + add) or 0
	s.rushAt = now
	if s.rush > 0 or was > 0 then
		ctx.net:FireClient(plr, "enchSpeed", { mult = E.rushSpeed(def, level, s.rush), grace = t.grace })
	end
	-- A word at every quarter of the way to the cap.
	local step = math.max(1, math.floor(t.maxBlocks / 4))
	if s.rush > was and math.floor(s.rush / step) > math.floor(was / step) then
		flash(plr, "SUGAR RUSH +" .. math.floor((E.rushSpeed(def, level, s.rush) - 1) * 100 + 0.5) .. "%", FLASH.sugar_rush, pos)
	end
end

-- Overclock counts one-shots in a row: the block was whole and this swing
-- broke it. Anything else ends the streak. The client is told every time it
-- moves, because it paces its own swings ("enchSpeed").
function S.afterSwing(plr, p, oneShot, pos, blocks)
	local def, level = slotEnchant(p, "damage")
	local s = streaks[p]
	if def and def.id == "sugar_rush" then
		if s and s.oc > 0 then
			s.oc = 0
		end
		return sugarRush(plr, streak(p), def, level, oneShot, pos, blocks)
	end
	if s and s.rush > 0 then
		-- The rush ends with the enchant (swapped tool, swapped book, the Crypt).
		s.rush = 0
		ctx.net:FireClient(plr, "enchSpeed", { mult = 1, grace = E.OVERCLOCK_GRACE })
	end
	if not (def and def.id == "overclock") then
		if s and s.oc > 0 then
			s.oc = 0
			ctx.net:FireClient(plr, "enchSpeed", { mult = 1, grace = E.OVERCLOCK_GRACE })
		end
		return
	end
	s = streak(p)
	local now = os.clock()
	local was = (now - s.ocAt <= E.OVERCLOCK_GRACE) and s.oc or 0
	s.oc = oneShot and math.min(def.effect.stacks, was + 1) or 0
	s.ocAt = now
	if s.oc > 0 or was > 0 then
		ctx.net:FireClient(plr, "enchSpeed", { mult = E.overclockSpeed(def, level, s.oc), grace = E.OVERCLOCK_GRACE })
	end
	if s.oc > was and s.oc % 5 == 0 then
		flash(plr, "OVERCLOCK x" .. s.oc, FLASH.overclock, pos)
	end
end

function S.swingSpeed(p)
	local s = streaks[p]
	if s and s.rush > 0 and os.clock() - s.rushAt <= E.TUNING.sugarRush.grace then
		local def, level = slotEnchant(p, "damage")
		return E.rushSpeed(def, level, s.rush)
	end
	if not (s and s.oc > 0 and os.clock() - s.ocAt <= E.OVERCLOCK_GRACE) then
		return 1
	end
	local def, level = slotEnchant(p, "damage")
	return E.overclockSpeed(def, level, s.oc)
end

--[[
	SPELLBOOK (a Halloween Special; owner: "casts a random ability every few
	hits: Zap, Blast, Tidal Wave, Shatter, Earthquake, at reduced power").
	`b` is the swing's finished boosts: gateProcs set b.spellEvery only for a
	Spellbook that works where the player stands, so b is the authority. Every
	b.spellEvery-th swing that lands returns the cast for MineServer to run
	through Dig.procsAt -- the same code a natural proc runs -- as
	{ family, b (that ability certain to fire), power (x the swing's damage),
	broke (the break flag that lets it fire) }. Otherwise nil.
]]
function S.spellCast(plr, p, b, broke, pos)
	local every = type(b) == "table" and tonumber(b.spellEvery) or 0
	if every <= 0 then
		return nil
	end
	local s = streak(p)
	s.spell += 1
	if s.spell < every then
		return nil
	end
	s.spell = 0
	local family = E.spellPick(Random.new(), broke)
	flash(plr, "SPELL", FLASH.spell, pos)
	return {
		family = family,
		b = E.spellBoosts(b, family),
		power = tonumber(b.spellPower) or E.TUNING.spellbook.power,
		-- Blast, Tidal Wave and Shatter go off where the book points even on a
		-- block still standing; Earthquake shakes a standing block (spellPick
		-- leaves it out when the block broke); Zap fires either way.
		broke = (family == "zap" and broke == true) or (family ~= "zap" and family ~= "quake"),
	}
end

local nextOre
--[[
	FLASHLIGHT (a Halloween Utility enchant; owner: "chance to reveal the
	rarest ore in a radius, and make it glow"). On a broken block, off its
	cooldown, it rolls its chance; on a hit it looks through `cells` (the
	zone's voxels, keyed by keyOf) within its radius for the rarest ore the
	held tool can break -- highest ore tier, or candy ore rank in the Crypt;
	the nearest on a tie -- and tells the client to light that block for a few
	seconds ("flashlight"). Then the cooldown. Nothing in range: a short retry.
	Returns the block it lit, or nil.
]]
local Breaking
local function oreRank(part)
	local tier = tonumber(part:GetAttribute("OreTier"))
	if tier then
		return tier
	end
	local candy = part:GetAttribute("CandyOre")
	local cdef = candy and Config.candyOreById and Config.candyOreById(candy)
	return cdef and tonumber(cdef.rank) or nil
end

function S.flashlight(plr, p, zone, part, cells, keyOf, tool)
	local def, level = slotEnchant(p, "utility")
	if not (def and def.id == "flashlight" and zone and part and cells and keyOf) then
		return nil
	end
	local s = streak(p)
	local now = os.clock()
	if now < s.flashReady then
		return nil
	end
	local f = E.flashlightAt(level)
	if math.random() >= f.chance then
		return nil
	end
	Config = Config or require(shared:WaitForChild("MineConfig"))
	Breaking = Breaking or require(shared:WaitForChild("MineBreaking"))
	local cx, cy, cz = part:GetAttribute("CX"), part:GetAttribute("CY"), part:GetAttribute("CZ")
	if not (cx and cy and cz) then
		return nil
	end
	local zi = (Config.zoneIndex and Config.zoneIndex(zone.id)) or 1
	local r = f.radius
	local best, bestRank, bestD = nil, -math.huge, math.huge
	for dx = -r, r do
		for dy = -r, r do
			for dz = -r, r do
				local d2 = dx * dx + dy * dy + dz * dz
				if d2 > 0 and d2 <= r * r then
					local other = cells[keyOf(zone.id, cx + dx, cy + dy, cz + dz)]
					if other and typeof(other) == "Instance" and other.Parent then
						local rank = oreRank(other)
						if rank and (rank > bestRank or (rank == bestRank and d2 < bestD))
							and (zone.noStrengthGate or Breaking.canBreak(tool, zi, cy + dy,
								tonumber(other:GetAttribute("OreTier")), #(Config.ORES or {}), p.maxUnlockedZone)) then
							best, bestRank, bestD = other, rank, d2
						end
					end
				end
			end
		end
	end
	if not best then
		s.flashReady = now + f.retry
		return nil
	end
	s.flashReady = now + f.cooldown
	local oreId, candyId = best:GetAttribute("OreId"), best:GetAttribute("CandyOre")
	local odef = (oreId and Config.oreById and Config.oreById(oreId))
		or (candyId and Config.candyOreById and Config.candyOreById(candyId)) or nil
	ctx.net:FireClient(plr, "flashlight", {
		pos = best.Position,
		part = best,
		name = tostring(best:GetAttribute("OreName") or best:GetAttribute("CandyName") or (odef and odef.name) or "Ore"),
		color = (odef and odef.color) or best.Color,
		secs = f.glow,
	})
	return best
end

function nextOre(ore)
	Config = Config or require(shared:WaitForChild("MineConfig"))
	local want = (tonumber(ore.tier) or 0) + 1
	for _, o in ipairs(Config.ORES or {}) do
		if o.tier == want then
			return o
		end
	end
	return nil
end

function S.alchemy(plr, p, ore, pos)
	local def, level = slotEnchant(p, "utility")
	if not (ore and def and def.id == "alchemy") or math.random() >= E.oreChance(def, level) then
		return ore
	end
	local up = nextOre(ore)
	if not up then
		return ore
	end
	flash(plr, "ALCHEMY! " .. tostring(up.name), FLASH.alchemy, pos)
	return up
end

function S.duplicate(plr, p, got, pos)
	local def, level = slotEnchant(p, "utility")
	if not (def and def.id == "duplicator") or math.random() >= E.oreChance(def, level) then
		return got
	end
	flash(plr, "DOUBLE!", FLASH.duplicator, pos)
	return got * 2
end

function S.veinCount(p)
	local def, level = slotEnchant(p, "utility")
	return (def and def.id == "veinminer") and E.veinBlocks(def, level) or 0
end

-- -------------------------------------------------------------- XP --

function S.gainXp(plr, p, amount)
	S.ensure(p)
	local gain = math.floor((tonumber(amount) or 0) * xpMult(p) + 0.5)
	if gain <= 0 or p.level >= E.MAX_PLAYER_LEVEL then
		return
	end
	p.xp += gain
	local ups = {}
	while p.level < E.MAX_PLAYER_LEVEL and p.xp >= E.xpToNext(p.level) do
		p.xp -= E.xpToNext(p.level)
		p.level += 1
		table.insert(ups, p.level)
	end
	for _, level in ipairs(ups) do
		local r = E.levelRewards(level)
		local gift
		if r.gift then
			-- A book for a slot you can use now, and some gems.
			local open = {}
			for _, s in ipairs(E.SLOTS) do
				if E.slotUnlocked(s.id, level) then
					open[s.id] = true
				end
			end
			local id = E.rollBookId(Random.new(), open)
			addBook(p, id, 1)
			p.gems = (tonumber(p.gems) or 0) + r.gift.gems
			gift = { book = id, gems = r.gift.gems }
		end
		ctx.net:FireClient(plr, "playerLevel", { level = level, unlocks = r.unlocks, gift = gift })
		if #r.unlocks > 0 then
			local names = {}
			for _, id in ipairs(r.unlocks) do
				table.insert(names, E.SLOT_BY_ID[id].name)
			end
			toast(plr, "LEVEL " .. level .. "! " .. table.concat(names, " + ") .. " enchant slot unlocked")
		else
			toast(plr, "LEVEL " .. level .. "!")
		end
	end
	ctx.markDirty(plr)
end

-- ------------------------------------------------------------ books --

local function giveBooks(p, books)
	for _, bk in ipairs(books or {}) do
		addBook(p, bk.id, bk.level)
	end
end

-- The Forge's gem price for a bundle: up a little each zone you have opened.
local function bundlePrice(p)
	return E.bundlePrice(math.max(1, math.floor(tonumber(p.maxUnlockedZone) or 1)))
end

function S.chestBundle(plr, p, rank, rng, chestLuck)
	S.ensure(p)
	local books = E.rollChestBundle(rank, rng, chestLuck)
	if not books then
		return nil
	end
	giveBooks(p, books)
	toast(plr, "📖 BOOK BUNDLE! " .. E.bundleText(books))
	ctx.net:FireClient(plr, "bookBundle", { books = books, source = "chest" })
	return books
end

-- n books from a reward, rolled at a rank's levels (nil = level I). No toast:
-- the giver (the pass, the Founders pack, the daily wheel) says what it paid.
function S.grantBundle(p, n, rank, slotFilter)
	S.ensure(p)
	local books = E.rollBundle(n, Random.new(), rank, slotFilter)
	giveBooks(p, books)
	return books
end

-- No toast: the lucky block's own reveal lists the books with the rest.
function S.luckyBundle(p, blockId, rng)
	S.ensure(p)
	local books = E.luckyBundle(blockId, rng)
	giveBooks(p, books)
	return books
end

function S.returnBooks(p, tool)
	S.ensure(p)
	if type(tool) == "table" and type(tool.enchants) == "table" then
		for _, e in pairs(tool.enchants) do
			if type(e) == "table" and E.get(e.id) then
				addBook(p, e.id, e.level)
			end
		end
		tool.enchants = nil
	end
end

function S.snapState(p)
	S.ensure(p)
	return {
		books = p.enchantBooks,
		level = p.level,
		xp = p.xp,
		next = E.xpToNext(p.level),
		bundlePrice = bundlePrice(p),
		bundleSize = E.SHOP_BUNDLE,
	}
end

-- ------------------------------------------------------------ verbs --

local V = {}

-- Put a book on a tool's slot. The book is used up; what was there comes back as a book.
function V.enchApply(plr, p, payload)
	if type(payload) ~= "table" then
		return
	end
	local tool = findTool(p, payload.uid)
	local slot = tostring(payload.slot or "")
	local def = E.get(payload.id)
	local level = math.floor(tonumber(payload.level) or 0)
	if not tool then
		return toast(plr, "That tool is not yours")
	end
	if not E.SLOT_BY_ID[slot] then
		return
	end
	if not E.slotUnlocked(slot, p.level) then
		return toast(plr, E.SLOT_BY_ID[slot].name .. " slot unlocks at level " .. E.SLOT_BY_ID[slot].unlockLevel)
	end
	if not def or def.slot ~= slot then
		return toast(plr, "That book goes in another slot")
	end
	local ok, why = E.compatible(def, tool.familyId or "pickaxe")
	if not ok then
		return toast(plr, why or "Can't go on this tool")
	end
	if level < 1 or level > E.MAX_LEVEL then
		return
	end
	if not takeBook(p, def.id, level, 1) then
		return toast(plr, "You don't have that book")
	end
	tool.enchants = type(tool.enchants) == "table" and tool.enchants or {}
	local old = tool.enchants[slot]
	if type(old) == "table" and E.get(old.id) then
		addBook(p, old.id, old.level)
	end
	tool.enchants[slot] = { id = def.id, level = level }
	toast(plr, "✨ " .. def.name .. " " .. E.roman(level) .. " applied")
	if ctx.onApply then
		ctx.onApply(plr, p)
	end
	ctx.markDirty(plr)
	ctx.snap(plr)
end

-- Take an enchant off; it comes back as a book.
function V.enchRemove(plr, p, payload)
	if type(payload) ~= "table" then
		return
	end
	local tool = findTool(p, payload.uid)
	local slot = tostring(payload.slot or "")
	local e = tool and type(tool.enchants) == "table" and tool.enchants[slot]
	if not (e and E.get(e.id)) then
		return
	end
	addBook(p, e.id, e.level)
	tool.enchants[slot] = nil
	ctx.markDirty(plr)
	ctx.snap(plr)
end

-- Three of the same book at the same level make one a level up.
function V.enchMerge(plr, p, payload)
	if type(payload) ~= "table" then
		return
	end
	local def = E.get(payload.id)
	local level = math.floor(tonumber(payload.level) or 0)
	if not def or level < 1 or level >= E.MAX_LEVEL then
		return
	end
	if not takeBook(p, def.id, level, E.MERGE_COST) then
		return toast(plr, "Merging needs " .. E.MERGE_COST .. " of the same book")
	end
	addBook(p, def.id, level + 1)
	-- A lifetime count, for the "merge books" quests (kept through rebirth).
	p.bookMerges = (tonumber(p.bookMerges) or 0) + 1
	toast(plr, "📖 " .. def.name .. " " .. E.roman(level + 1) .. "!")
	ctx.markDirty(plr)
	ctx.snap(plr)
end

-- Buy a bundle of books with gems, at the Forge.
function V.enchBuyBundle(plr, p)
	local price = bundlePrice(p)
	if (tonumber(p.gems) or 0) < price then
		return toast(plr, "A book bundle is " .. price .. " gems")
	end
	p.gems = (tonumber(p.gems) or 0) - price
	local books = E.rollBundle(E.SHOP_BUNDLE, Random.new())
	giveBooks(p, books)
	toast(plr, "📖 BOOK BUNDLE! " .. E.bundleText(books))
	ctx.net:FireClient(plr, "bookBundle", { books = books, source = "shop" })
	ctx.markDirty(plr)
	ctx.snap(plr)
end

-- Studio only: a stack of books to try things with.
function V.enchDebugGrant(plr, p)
	if not RunService:IsStudio() then
		return
	end
	for _, def in ipairs(E.LIST) do
		addBook(p, def.id, 1, 3)
		addBook(p, def.id, 3, 1)
	end
	p.level = math.max(p.level, 25)
	toast(plr, "Studio: 3 of every book at I, one at III, level 25")
	ctx.markDirty(plr)
	ctx.snap(plr)
end

S.VERBS = V

function S.dispatch(plr, action, payload)
	local fn = V[action]
	local p = ctx.profiles and ctx.profiles[plr.UserId]
	if fn and p then
		S.ensure(p)
		fn(plr, p, payload)
	end
end

function S.init(c)
	ctx = c
end

return S
