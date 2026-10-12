--[[
	MineEnchantService -- enchants and the player level, on the server.

	The rules and numbers are MineEnchants (shared). MineServer wires this in
	as Verbs.Ench and calls:

	  init(ctx)                       ctx = { profiles, net, snap, markDirty }
	  dispatch(plr, action, payload)  every remote action starting "ench"
	  snapState(p)                    the block the snapshot carries
	  gainXp(plr, p, amount)          ore blocks and chests pay XP
	  chestBook(plr, p, rank, rng, chestLuck)   a chest's book, sometimes
	  returnBooks(p, tool)            a tool being recycled gives its enchants back
	  special(p)                      the held tool's Special enchant (for boosts)
	  layerStats(p)                   the held tool's Damage/Utility stats (for boosts)

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

function S.special(p)
	local t = heldTool(p)
	local e = t and type(t.enchants) == "table" and t.enchants.special or nil
	if e and E.slotUnlocked("special", p.level) then
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
		if e and E.slotUnlocked(slot, p.level) then
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
	if e and E.slotUnlocked("utility", p.level) then
		for _, s in ipairs(E.statsAt(E.get(e.id), e.level)) do
			if s.how == "xp" then
				return s.value
			end
		end
	end
	return 1
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

function S.chestBook(plr, p, rank, rng, chestLuck)
	S.ensure(p)
	local book = E.rollChestBook(rank, rng, chestLuck)
	if not book then
		return nil
	end
	addBook(p, book.id, book.level)
	local def = E.get(book.id)
	toast(plr, "📖 ENCHANT BOOK: " .. (def and def.name or book.id) .. " " .. E.roman(book.level))
	return book
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
	toast(plr, "📖 " .. def.name .. " " .. E.roman(level + 1) .. "!")
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
