--[[
	MineCryptRules -- the Candy Crypt's rules, in one place both sides read.

	The owner's redesign, 2026-10-19 (wiki/open-questions.md §0e, "The Candy
	Crypt, redesigned"): only event tools dig the Crypt; claiming it gives a
	free starter pick; Crypt tools come from Crypt chests and Trick-or-Treat
	cases; three identical tools merge Golden -> Prism -> Rainbow at the pets'
	multipliers; the tools are yours to keep, and once the Crypt closes they
	also work in the main world (weaker) and in later event mines; a pop-up on
	first entry says so.

	The SERVER (ServerScriptService/Mine/MineCrypt) is the authority for every
	roll, payout and gate and calls these. The CLIENT reads the same functions
	to draw the screens, so a number on a card is the number the server uses.

	WHAT IS HERE (the client may call any of these):

	  ZONE_ID, EVENT_ID, CURRENCY      "hallow", "candy_crypt", "candy"
	  NOTICE / noticeFor(zoneId)       the first-entry pop-up: { title, text }
	  window(now)                      { opensAt, closesAt, open, ended }
	  MERGE_COUNT, VARIANTS            3, { "Normal", "Golden", "Prism", "Rainbow" }
	  stackKey(id, variant)            "candy_corn_pickaxe|Golden"
	  parseKey(key) / defOf(key)       id, variant / tool def, variant
	  variantMult(v) / nextVariant(v)  MineConfig.VARIANT_MULT / the next rung
	  mergePlan(p, key, times)         what a merge would do, or nil + reason
	  toolTable()                      every Crypt tool def (MineCandyTools)
	  inEventPower / worldPower / worldBreakingPower
	  eventRow / worldRow / NONE_ROW   what the server puts in a player's hands
	  heldRow(p, zoneId, now)          THE swap rule (see below)
	  chestCandy(layer), chestOdds(layer, chestLuck), caseOdds()
	  candyOreValue(id), candyOreRows(ores, locks)
	  charmRecipes(p)                  the six Halloween charms and their costs
	  stateFor(p, now)                 the snapshot's `crypt` block

	THE SAVE (MineCrypt keeps it straight; nothing here writes):

	  p.cryptTools         { ["<toolId>|<variant>"] = copies }
	  p.cryptToolEquipped  the stack key in hand, or nil
	  p.cryptToolWorld     true = hold it in the main world too (after the event)
	  p.eventNoticeSeen    { [zoneId] = true } once the pop-up is dismissed
	  p.candySeen          { [candyOreId] = true } candy ores ever dug

	EVERY NUMBER HERE NOT QUOTED FROM THE OWNER IS PROPOSED (2026-10-19).
]]
local R = {}

local shared = script.Parent
local C = require(shared:WaitForChild("MineConfig"))
local Tools = require(shared:WaitForChild("MineCandyTools"))
local OreTools = require(shared:WaitForChild("MineOreTools"))
local Breaking = require(shared:WaitForChild("MineBreaking"))
local Charms = require(shared:WaitForChild("MineCharms"))
local TT = require(shared:WaitForChild("MineTrickOrTreat"))

R.ZONE_ID = "hallow"
R.EVENT_ID = "candy_crypt"
R.CURRENCY = "candy"

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

-- Said when a player asks to hold a Crypt tool outside before the event ends.
R.WORLD_LOCKED_TEXT = "Crypt tools work in the main world once the Candy Crypt closes."

--------------------------------------------------------------------------------
-- THE WINDOW
--------------------------------------------------------------------------------

--[[
	The Crypt's own window, on the WALL clock (LIMITED_WINDOWS.hallow carries
	calendar dates; owner, 2026-10-10). `now` is optional: the server passes
	nothing (os.time); a client should pass workspace:GetServerTimeNow().

	`ended` is what turns the main-world use on. LIMITED_START_UNIX <= 0 is the
	dev switch MineConfig.limitedActive treats as "everything open", and it is
	honoured the same way here, so the two never disagree.
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

--------------------------------------------------------------------------------
-- STACKS, VARIANTS AND MERGING
--------------------------------------------------------------------------------

--[[
	A Crypt tool is not an instance with a uid: two copies of the same tool in
	the same variant are identical, so the save is a COUNT per (tool, variant)
	-- "candy_corn_pickaxe|Golden" = 2. Merging is arithmetic on those counts,
	and the item bag counts the copies (MineConfig.ITEM_BAG_FIELDS).
]]
R.MERGE_COUNT = 3
R.VARIANTS = { "Normal", "Golden", "Prism", "Rainbow" }
local VARIANT_RANK = {}
for i, v in ipairs(R.VARIANTS) do
	VARIANT_RANK[v] = i
end
R.VARIANT_RANK = VARIANT_RANK

function R.stackKey(id, variant)
	return tostring(id or "") .. "|" .. tostring(variant or "Normal")
end

function R.parseKey(key)
	local id, variant = string.match(tostring(key or ""), "^([%w_]+)|(%a+)$")
	return id, variant
end

function R.validVariant(v)
	return VARIANT_RANK[tostring(v or "")] ~= nil
end

-- The tool def and variant a key names, or nil for anything not real.
function R.defOf(key)
	local id, variant = R.parseKey(key)
	if not id or not R.validVariant(variant) then
		return nil
	end
	local def = Tools.byId(id)
	if not def then
		return nil
	end
	return def, variant
end

-- The pets' multipliers (MineConfig.VARIANT_MULT): 1 / 2.25 / 3.5 / 5.5.
function R.variantMult(v)
	return tonumber(C.VARIANT_MULT and C.VARIANT_MULT[tostring(v or "Normal")]) or 1
end

-- The next rung, or nil at Rainbow. Its own walk rather than C.nextVariant,
-- which also takes the cards' legacy "Shiny" -- a word no Crypt tool can carry.
function R.nextVariant(v)
	local i = VARIANT_RANK[tostring(v or "")]
	return i and R.VARIANTS[i + 1] or nil
end

function R.toolTable()
	return Tools.all()
end

local function count(p, key)
	local stacks = type(p) == "table" and p.cryptTools
	return (type(stacks) == "table" and math.max(0, math.floor(tonumber(stacks[key]) or 0))) or 0
end
R.count = count

--[[
	What merging `key` `times` times would do: 3 x (id, variant) -> 1 x (id,
	next variant), the pets' rule. `times` defaults to 1 and is clamped to what
	the player owns; pass math.huge to merge every full set. Returns the plan, or
	nil and a player-facing reason (the server toasts it as written).
]]
function R.mergePlan(p, key, times)
	local def, variant = R.defOf(key)
	if not def then
		return nil, "That tool is not in the game"
	end
	local nextV = R.nextVariant(variant)
	if not nextV then
		return nil, "That one is already Rainbow"
	end
	local most = math.floor(count(p, key) / R.MERGE_COUNT)
	if most < 1 then
		return nil, ("Merging takes %d identical copies"):format(R.MERGE_COUNT)
	end
	local n = math.floor(tonumber(times) or 1)
	if n ~= n then
		n = 1
	end
	n = math.clamp(n, 1, most)
	return {
		from = R.stackKey(def.id, variant),
		to = R.stackKey(def.id, nextV),
		times = n,
		consumed = n * R.MERGE_COUNT,
		def = def,
		variant = variant,
		nextVariant = nextV,
	}
end

--------------------------------------------------------------------------------
-- POWER, IN THE EVENT AND IN THE MAIN WORLD
--------------------------------------------------------------------------------

-- Event Digging from the worn charm (the Halloween charms), as a fraction:
-- 0.42 means +42%. Read off the charm, not off boosts(): boosts() asks what is
-- held, and what is held asks this, so going through boosts would loop.
function R.eventDigOf(p)
	-- At the worn copy's tier, I..V (MineCharms, 2026-10-19).
	if Charms.wornStat then
		return math.max(0, Charms.wornStat(p, "eventDig"))
	end
	local id = type(p) == "table" and p.equippedCharm
	local def = (type(id) == "string" and id ~= "") and Charms.byId(id) or nil
	local v = def and type(def.stats) == "table" and tonumber(def.stats.eventDig)
	return math.max(0, v or 0)
end

-- A Crypt tool's power inside an event mine.
function R.inEventPower(def, variant, dig)
	return math.max(1, math.floor((tonumber(def and def.power) or 1)
		* R.variantMult(variant) * (1 + math.max(0, tonumber(dig) or 0)) + 0.5))
end

--[[
	THE MAIN WORLD, AFTER THE EVENT: WEAKER (owner: events must pay better).

	A Crypt tool there is mapped onto the main world's own ladder: it hits like
	a LEVEL-1 FORGED tool of its family made from `worldOreTier` (MineCandyTools:
	the last ore of zone 1, 3 or 5 for the three tiers), times its variant and
	Event Digging, and it has that ore's breaking power (Basalt, Rime and Topaz
	for the three tiers). About 1/13, 1/32 and 1/60 of its Crypt power: a Jawbreaker
	Pick tuned for zone-9 rock in the Crypt is a fresh Topaz pick out here,
	never better than a forged tool a player has levelled. Read through
	MineConfig.toolPower and MineBreaking, so a retune of either moves this with
	it.
]]
function R.worldPower(def, variant, dig)
	local t = math.max(1, math.floor(tonumber(def and def.worldOreTier) or 1))
	local fam = (def and def.family) or "pickaxe"
	local base = C.toolPower(t, 1, OreTools.typeMult(fam, t)) * OreTools.familyPower(fam)
	return math.max(1, math.floor(base * R.variantMult(variant)
		* (1 + math.max(0, tonumber(dig) or 0)) + 0.5))
end

function R.worldBreakingPower(def)
	local t = math.max(1, math.floor(tonumber(def and def.worldOreTier) or 1))
	return Breaking.oreStrength(t, #(C.ORES or {}))
end

local function baseRow(def, variant)
	local row = table.clone(def)
	row.variant = variant
	row.key = R.stackKey(def.id, variant)
	row.baseName = def.name
	if variant ~= "Normal" then
		row.name = variant .. " " .. def.name
	end
	row.cryptTool = true
	return row
end

--[[
	The row the server swings INSIDE an event mine. `eventMine` is what
	MineSpaceMatter keys the event-only rule on: this row spends that mine's
	rock and nothing else. No breaking power: those mines have no strength gate
	(`noStrengthGate`), the HP is the gate.
]]
function R.eventRow(def, variant, zoneId, dig)
	local row = baseRow(def, variant)
	row.power = R.inEventPower(def, variant, dig)
	row.eventMine = zoneId or R.ZONE_ID
	return row
end

-- The row the server swings in the MAIN world once the event has ended.
function R.worldRow(def, variant, dig)
	local row = baseRow(def, variant)
	row.power = R.worldPower(def, variant, dig)
	row.breakingPower = R.worldBreakingPower(def)
	row.world = true
	return row
end

--[[
	EMPTY HANDS IN AN EVENT MINE. Somebody with no Crypt tool (which a claim
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

-- The stack in hand, if the player owns it. Never trusts the key alone.
function R.equippedStack(p)
	if type(p) ~= "table" then
		return nil
	end
	local key = p.cryptToolEquipped
	if type(key) ~= "string" or count(p, key) <= 0 then
		return nil
	end
	local def, variant = R.defOf(key)
	if not def then
		return nil
	end
	return { key = key, def = def, variant = variant, count = count(p, key) }
end

-- Rows are read-only to every caller (Event Horizon returns its shared rows
-- the same way), so they are cached: equippedTool runs several times a swing.
local rowCache = {}
local function cachedRow(kind, def, variant, zoneId, dig)
	local k = kind .. "|" .. def.id .. "|" .. variant .. "|" .. tostring(zoneId) .. "|" .. tostring(dig)
	local hit = rowCache[k]
	if hit then
		return hit
	end
	if kind == "event" then
		hit = R.eventRow(def, variant, zoneId, dig)
	else
		hit = R.worldRow(def, variant, dig)
	end
	rowCache[k] = hit
	return hit
end

--[[
	THE SWAP RULE: what a player holds, given where they stand.

	  In an event-tools-only mine (the Crypt; any later one that sets the flag):
	    their equipped Crypt tool, at event power -- in the Crypt always, in a
	    later event mine once the Crypt has ended ("and in future events").
	    No Crypt tool: NONE_ROW, empty hands.
	  In Event Horizon: nil. It keeps its own tools and rules (owner: "Crypt
	    only for now").
	  Anywhere else: their equipped Crypt tool at WORLD power, but only once the
	    Crypt has ended AND they chose to hold it there (`cryptToolWorld`).
	    During the event Crypt tools do nothing out here.
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
	local stack = R.equippedStack(p)
	if zone and zone.eventToolsOnly then
		if stack then
			local allowed = zid == R.ZONE_ID
			if not allowed then
				w = R.window(now)
				allowed = w.ended
			end
			if allowed then
				return cachedRow("event", stack.def, stack.variant, zid, R.eventDigOf(p)),
					stack.def.family, stack.def.tier
			end
		end
		return R.NONE_ROW, "pickaxe", 0
	end
	if zid == "bigbang" then
		return nil
	end
	if stack and p.cryptToolWorld == true then
		w = w or R.window(now)
		if w.ended then
			return cachedRow("world", stack.def, stack.variant, nil, R.eventDigOf(p)),
				stack.def.family, stack.def.tier
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- CHESTS AND CASES
--------------------------------------------------------------------------------

--[[
	A CRYPT CHEST pays candy and, sometimes, a Crypt tool (MineCandyTools:
	CHEST_TOOL_CHANCE, from the chest's own depth band). No coins, gems or packs:
	the Crypt's packs would be another mine's, and its rewards are candy and
	tools. The candy is CHEST_CANDY_BLOCKS candy blocks' worth of the candy ore
	centred at the chest's depth. PROPOSED (2026-10-19): 5.
]]
R.CHEST_CANDY_BLOCKS = 5

-- The candy ore whose `at` sits nearest this layer (no roll: a chest's candy is
-- a fixed amount for its depth).
function R.candyOreNear(layer)
	local list = C.CANDY_ORES or {}
	local depth = math.max(1, tonumber(C.CANDY_DEPTH_LAYERS) or 120)
	local t = math.clamp((tonumber(layer) or 1) / depth, 0, 1)
	local best, bestD = list[1], math.huge
	for _, o in ipairs(list) do
		local d = math.abs((tonumber(o.at) or 0) - t)
		if d < bestD then
			best, bestD = o, d
		end
	end
	return best
end

function R.chestCandy(layer)
	local ore = R.candyOreNear(layer)
	if not ore then
		return 0
	end
	return math.max(1, math.floor(C.candyFor(ore, layer) * R.CHEST_CANDY_BLOCKS))
end

-- The chance of a tool, and of each tier, from a chest at this layer.
function R.chestOdds(layer, chestLuck)
	return Tools.chestOdds(layer, chestLuck)
end

--[[
	The Trick-or-Treat odds sheet: every outcome's share (MineTrickOrTreat.odds),
	plus the tool slot broken into tiers (MineCandyTools.CASE_TIER_WEIGHTS) and
	what the skin case can be. Every row's `pct` is out of 100.
]]
function R.caseOdds(packPresent)
	local rows = TT.odds(packPresent)
	local toolShare = 0
	for _, r in ipairs(rows) do
		if r.kind == "tool" then
			toolShare = r.pct
		end
	end
	local tiers, tot = {}, 0
	for _, w in ipairs(Tools.CASE_TIER_WEIGHTS) do
		tot += w
	end
	for ti, w in ipairs(Tools.CASE_TIER_WEIGHTS) do
		local tier = Tools.TIERS[ti]
		table.insert(tiers, {
			tier = ti,
			name = tier and tier.name or tostring(ti),
			pct = (tot > 0) and (toolShare * w / tot) or 0,
		})
	end
	return {
		price = TT.PRICE,
		currency = TT.CURRENCY,
		rows = rows,
		toolTiers = tiers,
		skinCaseOreTiers = TT.SKIN_CASE_ORE_TIERS,
	}
end

--------------------------------------------------------------------------------
-- CANDY ORES
--------------------------------------------------------------------------------

-- Candy for one unit (MineConfig.candyOreValue). 0 for anything not candy.
function R.candyOreValue(id)
	return C.candyOreValue and C.candyOreValue(id) or 0
end

-- All sixteen candy ores with what the player holds, for the pouch and the
-- candy-sell screen. Always sixteen rows, in ladder order.
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
			homeLayer = C.candyHomeLayer(o),
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
-- THE HALLOWEEN CHARMS
--------------------------------------------------------------------------------

-- The six, with what crafting each costs and whether `p` can afford it.
function R.charmRecipes(p)
	local ores = type(p) == "table" and p.ores or {}
	local owned = type(p) == "table" and p.charms or {}
	local out = {}
	for _, def in ipairs(Charms.candyCharms()) do
		local rec = def.recipe or {}
		local ore = C.candyOreById(rec.oreId)
		local have = math.max(0, math.floor(tonumber((ores or {})[rec.oreId]) or 0))
		local cost = math.max(1, math.floor(tonumber(rec.count) or 1))
		local n = (owned or {})[def.id]
		table.insert(out, {
			charmId = def.id,
			name = def.name,
			rarity = def.rarity,
			rarityLabel = Charms.RARITY_LABEL and Charms.RARITY_LABEL[def.rarity] or def.rarity,
			blurb = def.blurb,
			stats = def.stats,
			oreId = rec.oreId,
			oreName = ore and ore.name or rec.oreId,
			cost = cost,
			have = have,
			canCraft = have >= cost,
			owned = (n == true) and 1 or math.max(0, math.floor(tonumber(n) or 0)),
			-- No art yet: empty means the client's generic charm icon.
			icon = def.art or "",
		})
	end
	return out
end

--------------------------------------------------------------------------------
-- THE SNAPSHOT
--------------------------------------------------------------------------------

--[[
	The `crypt` block of the snapshot. Per-player state only; the static tables
	(tools, odds, notice text, merge rule) are the functions above.

	  zoneId, eventId          "hallow", "candy_crypt"
	  owned                    claimed (p.hallowOwned)
	  candy                    the balance
	  window                   { opensAt, closesAt, open, ended } (wall clock)
	  tools                    owned stacks, best first:
	                           { key, id, name, family, tier, tierName, variant,
	                             count, power, worldPower, worldBreakingPower,
	                             nextVariant, merges, equipped, rarityId, icon }
	  equipped                 the key in hand, or nil
	  world / worldActive      chose to hold it outside / and the event has ended
	  noticeSeen               { [zoneId] = true }
	  recipes                  charmRecipes(p)
	  candyOres                candyOreRows(p.ores, p.oreLocks, p.candySeen)
	  sellUpTo                 the pouch's remembered SELL UP TO ceiling
	  casePrice                Trick-or-Treat price in candy
]]
function R.stateFor(p, now)
	if type(p) ~= "table" then
		return nil
	end
	local w = R.window(now)
	local dig = R.eventDigOf(p)
	local tools = {}
	for key, n in pairs(type(p.cryptTools) == "table" and p.cryptTools or {}) do
		local def, variant = R.defOf(key)
		local c = math.max(0, math.floor(tonumber(n) or 0))
		if def and c > 0 then
			local tier = Tools.TIERS[def.tier]
			local nextV = R.nextVariant(variant)
			table.insert(tools, {
				key = key,
				id = def.id,
				name = (variant ~= "Normal") and (variant .. " " .. def.name) or def.name,
				family = def.family,
				tier = def.tier,
				tierName = tier and tier.name or nil,
				variant = variant,
				count = c,
				power = R.inEventPower(def, variant, dig),
				worldPower = R.worldPower(def, variant, dig),
				worldBreakingPower = R.worldBreakingPower(def),
				nextVariant = nextV,
				merges = nextV and math.floor(c / R.MERGE_COUNT) or 0,
				equipped = p.cryptToolEquipped == key,
				rarityId = def.rarityId,
				icon = def.icon or "",
			})
		end
	end
	local famOrder = {}
	for i, f in ipairs(Tools.FAMILIES) do
		famOrder[f] = i
	end
	table.sort(tools, function(a, b)
		if a.tier ~= b.tier then
			return a.tier > b.tier
		end
		local va, vb = VARIANT_RANK[a.variant] or 0, VARIANT_RANK[b.variant] or 0
		if va ~= vb then
			return va > vb
		end
		return (famOrder[a.family] or 9) < (famOrder[b.family] or 9)
	end)
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
		tools = tools,
		equipped = R.equippedStack(p) and p.cryptToolEquipped or nil,
		world = p.cryptToolWorld == true,
		worldActive = (p.cryptToolWorld == true) and w.ended,
		noticeSeen = seen,
		recipes = R.charmRecipes(p),
		candyOres = R.candyOreRows(p.ores, p.oreLocks, p.candySeen),
		sellUpTo = settings.oreSellUpTo or "Everything",
		casePrice = TT.PRICE,
	}
end

return R
