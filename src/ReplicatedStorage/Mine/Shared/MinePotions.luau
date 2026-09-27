-- MinePotions: 5-tier short dig buffs. Same-stat drinks queue: highest % first.
local MinePotions = {}

local STATS = {
	{ id = "haste", stat = "mineSpeed", word = "Haste" },
	{ id = "power", stat = "dirtBreak", word = "Power" },
	{ id = "fortune", stat = "luck", word = "Fortune" },
	{ id = "purse", stat = "coinBonus", word = "Purse" },
	{ id = "haul", stat = "backpack", word = "Haul" },
}

local TIERS = {
	{ n = 1, tag = "Sip", add = 0.30, durationSec = 5 * 60, dust = 40 },
	{ n = 2, tag = "Vial", add = 0.60, durationSec = 5 * 60, dust = 90 },
	{ n = 3, tag = "Flask", add = 1.20, durationSec = 10 * 60, dust = 220 },
	{ n = 4, tag = "Tonic", add = 2.40, durationSec = 10 * 60, dust = 520 },
	{ n = 5, tag = "Elixir", add = 4.00, durationSec = 15 * 60, dust = 1400 },
}

MinePotions.DEFS = {}
for _, t in ipairs(TIERS) do
	for _, s in ipairs(STATS) do
		local id = string.format("pot_t%d_%s", t.n, s.id)
		table.insert(MinePotions.DEFS, {
			id = id,
			name = string.format("%s %s", t.tag, s.word),
			blurb = string.format("+%d%% %s for %d min",
				math.floor(t.add * 100 + 0.5), s.word:lower(), t.durationSec / 60),
			stat = s.stat,
			add = t.add,
			durationSec = t.durationSec,
			tier = t.n,
			dust = t.dust,
		})
	end
end

MinePotions.BY_ID = {}
for _, d in ipairs(MinePotions.DEFS) do
	MinePotions.BY_ID[d.id] = d
end

function MinePotions.def(id)
	return MinePotions.BY_ID[tostring(id or "")]
end

function MinePotions.dustPrice(id)
	local d = MinePotions.def(id)
	return d and d.dust or 80
end

function MinePotions.tradeValue(id)
	return MinePotions.dustPrice(id)
end

function MinePotions.ensureBag(p)
	p.potions = p.potions or {}
	return p.potions
end

function MinePotions.grant(p, potionId, qty)
	local def = MinePotions.def(potionId)
	if not def then
		return false
	end
	qty = math.max(1, math.floor(tonumber(qty) or 1))
	local bag = MinePotions.ensureBag(p)
	bag[def.id] = (tonumber(bag[def.id]) or 0) + qty
	return true
end

local function queues(p)
	p.potionQueues = p.potionQueues or {}
	return p.potionQueues
end

local function tickQueues(p, now)
	now = now or os.time()
	local last = tonumber(p.potionClock) or now
	local dt = math.max(0, now - last)
	p.potionClock = now
	local qmap = queues(p)
	for stat, q in pairs(qmap) do
		if type(q) == "table" and #q > 0 then
			table.sort(q, function(a, b)
				return (tonumber(a.add) or 0) > (tonumber(b.add) or 0)
			end)
			q[1].remaining = (tonumber(q[1].remaining) or 0) - dt
			while #q > 0 and (tonumber(q[1].remaining) or 0) <= 0 do
				table.remove(q, 1)
				if #q > 0 then
					table.sort(q, function(a, b)
						return (tonumber(a.add) or 0) > (tonumber(b.add) or 0)
					end)
				end
			end
		end
		if type(q) ~= "table" or #q == 0 then
			qmap[stat] = nil
		end
	end
end

function MinePotions.drink(p, potionId)
	local def = MinePotions.def(potionId)
	if not def then
		return nil, "Unknown potion"
	end
	local bag = MinePotions.ensureBag(p)
	local have = tonumber(bag[def.id]) or 0
	if have < 1 then
		return nil, "No " .. def.name
	end
	bag[def.id] = have - 1
	if bag[def.id] <= 0 then
		bag[def.id] = nil
	end
	tickQueues(p)
	local qmap = queues(p)
	local q = qmap[def.stat] or {}
	local merged = false
	for _, seg in ipairs(q) do
		if math.abs((tonumber(seg.add) or 0) - def.add) < 1e-6 then
			seg.remaining = (tonumber(seg.remaining) or 0) + def.durationSec
			merged = true
			break
		end
	end
	if not merged then
		q[#q + 1] = { id = def.id, add = def.add, remaining = def.durationSec }
	end
	table.sort(q, function(a, b)
		return (tonumber(a.add) or 0) > (tonumber(b.add) or 0)
	end)
	qmap[def.stat] = q
	return def, nil
end

function MinePotions.applyBoosts(b, p)
	if not (b and p) then
		return
	end
	tickQueues(p)
	for stat, q in pairs(queues(p)) do
		local top = type(q) == "table" and q[1]
		local add = top and tonumber(top.add) or 0
		if add > 0 and b[stat] ~= nil then
			if stat == "echo" or stat == "zap" or stat == "oreYield" or stat == "luckyFind"
				or stat == "fossilFind" or stat == "pulverize" or stat == "autoMine" then
				b[stat] = (b[stat] or 0) + add
			else
				b[stat] = (b[stat] or 1) * (1 + add)
			end
		end
	end
end

function MinePotions.snapshot(p)
	tickQueues(p)
	local bag = {}
	for id, qty in pairs(p and p.potions or {}) do
		local q = tonumber(qty) or 0
		if q > 0 then
			local def = MinePotions.def(id)
			bag[#bag + 1] = {
				id = id,
				qty = q,
				name = def and def.name or id,
				blurb = def and def.blurb or "",
				tier = def and def.tier or 1,
				mergeTo = MinePotions.nextId(id),
				mergeCost = MinePotions.mergeDust(id),
			}
		end
	end
	table.sort(bag, function(a, b)
		if (a.tier or 1) ~= (b.tier or 1) then
			return (a.tier or 1) > (b.tier or 1)
		end
		return a.name < b.name
	end)
	local active = {}
	for stat, q in pairs(queues(p)) do
		for i, seg in ipairs(q) do
			local def = MinePotions.def(seg.id)
			active[#active + 1] = {
				id = seg.id,
				stat = stat,
				add = seg.add,
				remaining = math.max(0, tonumber(seg.remaining) or 0),
				name = def and def.name or stat,
				live = i == 1,
			}
		end
	end
	return { bag = bag, active = active }
end

function MinePotions.shopPool(rng)
	rng = rng or Random.new()
	local weighted = {}
	for _, d in ipairs(MinePotions.DEFS) do
		local w = ({ [1] = 3, [2] = 4, [3] = 4, [4] = 2, [5] = 1 })[d.tier] or 2
		for _ = 1, w do
			weighted[#weighted + 1] = d
		end
	end
	for i = #weighted, 2, -1 do
		local j = rng:NextInteger(1, i)
		weighted[i], weighted[j] = weighted[j], weighted[i]
	end
	local seen, out = {}, {}
	for _, d in ipairs(weighted) do
		if not seen[d.id] then
			seen[d.id] = true
			out[#out + 1] = d
			if #out >= 8 then
				break
			end
		end
	end
	return out
end

function MinePotions.roll(rng)
	rng = rng or Random.new()
	local bag = {}
	for _, d in ipairs(MinePotions.DEFS) do
		local w = math.max(1, 6 - (d.tier or 1))
		for _ = 1, w do
			bag[#bag + 1] = d
		end
	end
	return bag[rng:NextInteger(1, #bag)]
end

MinePotions.MERGE_COUNT = 3

function MinePotions.nextId(id)
	local def = MinePotions.def(id)
	if not def or (def.tier or 1) >= 5 then
		return nil
	end
	local stat = tostring(id or ""):match("^pot_t%d+_(.+)$")
	if not stat then
		return nil
	end
	local nid = string.format("pot_t%d_%s", (def.tier or 1) + 1, stat)
	return MinePotions.def(nid) and nid or nil
end

function MinePotions.mergeDust(id)
	local nxt = MinePotions.nextId(id)
	local nextDef = nxt and MinePotions.def(nxt)
	if not nextDef then
		return nil
	end
	return math.max(15, math.ceil((nextDef.dust or 80) * 0.25))
end

function MinePotions.merge(p, potionId)
	local def = MinePotions.def(potionId)
	if not def then
		return nil, "Unknown potion"
	end
	local nid = MinePotions.nextId(def.id)
	if not nid then
		return nil, "Already max tier"
	end
	local bag = MinePotions.ensureBag(p)
	local have = tonumber(bag[def.id]) or 0
	if have < MinePotions.MERGE_COUNT then
		return nil, "Need 3 " .. def.name
	end
	local cost = MinePotions.mergeDust(def.id) or 15
	if (tonumber(p.dust) or 0) < cost then
		return nil, "Need " .. cost .. " stardust"
	end
	p.dust = (tonumber(p.dust) or 0) - cost
	bag[def.id] = have - MinePotions.MERGE_COUNT
	if bag[def.id] <= 0 then
		bag[def.id] = nil
	end
	MinePotions.grant(p, nid, 1)
	return MinePotions.def(nid), cost
end

return MinePotions

