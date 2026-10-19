--[[
	MineFishingService -- fishing on the server (TODO A3). The rules and data
	are MineFishing; the fight is MineFishingFight. MineServer wires this in
	as Verbs.Fish (no top-level local to spare there) and calls:

	  init(ctx)              ctx = { profiles, net, snap, markDirty }
	  dispatch(plr, action, payload)   every remote action starting "fish"
	  prompt(plr, part)      a fishing spot's ProximityPrompt (Machine "fish")
	  questBait(plr, p)      a daily quest was claimed: +QUEST_BAIT
	  snapState(p)           the small block the snapshot carries

	THE FLOW, and why the server believes it:
	  1. fishStart {spotId}  you are at the spot and have the bait; the cast bar
	                         starts (its position is a pure function of the
	                         tick, MineFishing.castBar).
	  2. fishCast {tick}     the tick you stopped the bar on. The server checks
	                         that much time really passed, grades the cast,
	                         spends the bait, rolls the catch, and sends the
	                         fight: a seed, the hardest fish's numbers, your
	                         rod's numbers and the bite delay.
	  3. fishReel {toggles, ticks}  the ticks the reel button went down and up.
	                         The server REPLAYS the fight with the same seed
	                         and presses (MineFishingFight.replay) and checks
	                         the fight took as long as it claims. Only a
	                         replayed "caught" lands the fish.
	  A 5-bait rod: five fish bite, one fight against the best of them; land it
	  and all five go in the cooler, worst to best; lose it and all five go.

	p.fishing (kept through rebirth: Verbs.KEEP_ON_REBIRTH):
	  bait, day, baitGot (gained today, capped), afk (seconds toward the next
	  AFK bait), rod (equipped id), rods = { [id] = { level, gates } },
	  cooler = { [fishId] = { n, best } }, casts, landed, lost, starter,
	  cotdGot, cotdClaimed (catch of the day; reset with baitGot on UTC day)
]]
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local shared = RS:WaitForChild("Mine"):WaitForChild("Shared")
local M = require(shared:WaitForChild("MineFishing"))
local Fight = require(shared:WaitForChild("MineFishingFight"))

local S = {}
S.TAG = "MineFishSpot"
S.STARTER_BAIT = 3 -- PROPOSED: a first visit can cast at once
S.AFK_TICK = 20 -- seconds between AFK bait accruals

local ctx = {}
local pending = {} -- [userId] = { stage, spotId, startedAt, ... }

local function today()
	return math.floor(os.time() / 86400)
end

function S.ensure(p)
	local f = p.fishing
	if type(f) ~= "table" then
		f = {}
		p.fishing = f
	end
	f.bait = math.max(0, math.floor(tonumber(f.bait) or 0))
	f.baitGot = math.max(0, math.floor(tonumber(f.baitGot) or 0))
	f.afk = math.max(0, tonumber(f.afk) or 0)
	f.day = tonumber(f.day) or today()
	if f.day ~= today() then
		f.day = today()
		f.baitGot = 0
		f.cotdGot = false
		f.cotdClaimed = false
	end
	if type(f.rods) ~= "table" then
		f.rods = {}
	end
	if type(f.rods[M.STARTER_ROD]) ~= "table" then
		f.rods[M.STARTER_ROD] = { level = 0, gates = 0 }
	end
	if not (type(f.rod) == "string" and f.rods[f.rod]) then
		f.rod = M.STARTER_ROD
	end
	if type(f.cooler) ~= "table" then
		f.cooler = {}
	end
	if not f.starter then
		f.starter = true
		f.bait += S.STARTER_BAIT
	end
	f.casts = tonumber(f.casts) or 0
	f.landed = tonumber(f.landed) or 0
	f.lost = tonumber(f.lost) or 0
	f.cotdGot = f.cotdGot == true
	f.cotdClaimed = f.cotdClaimed == true
	return f
end

-- Bait from a source that counts toward the day's cap. Returns how many.
local function gainBait(f, n)
	n = math.min(math.max(0, math.floor(n)), M.baitRoom(f.baitGot))
	f.bait += n
	f.baitGot += n
	return n
end

local function rodRow(f)
	local row = f.rods[f.rod] or { level = 0, gates = 0 }
	return f.rod, row
end

-- ------------------------------------------------------------- views --

function S.snapState(p)
	local f = S.ensure(p)
	local rodId, row = rodRow(f)
	local kinds, fish = 0, 0
	for _, c in pairs(f.cooler) do
		if (tonumber(c.n) or 0) > 0 or (tonumber(c.best) or 0) > 0 then
			kinds += 1
		end
		fish += math.max(0, math.floor(tonumber(c.n) or 0))
	end
	local target = M.catchOfDay(today())
	return {
		bait = f.bait,
		baitGot = f.baitGot,
		cap = M.BAIT_DAY_CAP,
		afkNext = math.max(0, math.ceil(M.AFK_SECS_PER_BAIT - f.afk)),
		rod = rodId,
		rodLevel = row.level or 0,
		coolerKinds = kinds,
		casts = f.casts, -- 0 until the first cast: the view points at CAST
		coolerFish = fish,
		catchOfDay = target and {
			id = target.id,
			name = target.name,
			grade = target.grade,
			zoneId = target.zoneId,
			got = f.cotdGot,
			claimed = f.cotdClaimed,
			reward = M.catchOfDayReward(target.id),
		} or nil,
	}
end

-- Everything the fishing screen shows: the spot, its odds, rods, the cooler.
local function fullState(p, spotId)
	local f = S.ensure(p)
	local spot = M.spot(spotId)
	local rodId, row = rodRow(f)
	local st = M.rodStats(rodId, row.level)
	local rods = {}
	for _, r in ipairs(M.RODS) do
		local own = f.rods[r.id]
		local level = own and own.level or 0
		local gates = own and own.gates or 0
		table.insert(rods, {
			id = r.id,
			owned = own ~= nil,
			level = level,
			gates = gates,
			cap = M.levelCap(gates),
			price = r.price,
			nextCost = (own and level < M.levelCap(gates)) and M.levelCost(r.id, level) or nil,
			prestigeCost = (own and level >= M.levelCap(gates) and level < M.LEVEL_MAX) and M.prestigeCost(gates) or nil,
			stats = M.rodStats(r.id, level),
		})
	end
	local album = spot and M.albumProgress(f.cooler, spot.zoneId) or nil
	local albumMult = album and album.luck or 1
	-- rod × spot × album (cast quality is applied only on fishCast).
	local luck = st.luck * (spot and spot.luck or 1) * albumMult
	local odds = {}
	if spot then
		for _, r in ipairs(M.catchOdds(spot.zoneId, luck)) do
			table.insert(odds, { id = r.fish.id, p = r.p })
		end
	end
	return {
		spotId = spotId,
		spot = spot and { id = spot.id, name = spot.name, zoneId = spot.zoneId, luck = spot.luck, kind = spot.kind } or nil,
		state = S.snapState(p),
		rods = rods,
		rodStats = st,
		luck = luck,
		album = album,
		odds = odds,
		cooler = f.cooler,
		tokens = tonumber(p.temperTokens) or 0,
		coins = tonumber(p.coins) or 0,
	}
end

local function send(plr, kind, data)
	data = data or {}
	data.kind = kind
	ctx.net:FireClient(plr, "fishing", data)
end

local function toast(plr, text)
	ctx.net:FireClient(plr, "toast", text)
end

local function refresh(plr, p, spotId)
	ctx.markDirty(plr)
	send(plr, "state", fullState(p, spotId))
	ctx.snap(plr)
end

-- ------------------------------------------------------------- spots --

-- The dock part of a spot, from the world (WorldBuilder / MineDepthPlazas tag it).
function S.spotPart(spotId)
	for _, part in ipairs(CollectionService:GetTagged(S.TAG)) do
		if part:GetAttribute("SpotId") == spotId and part:IsDescendantOf(workspace) then
			return part
		end
	end
	return nil
end

local function atSpot(plr, spotId)
	local spot = M.spot(spotId)
	local part = spot and S.spotPart(spotId)
	local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not (part and hrp) then
		return nil
	end
	if (hrp.Position - part.Position).Magnitude > M.SPOT_RADIUS then
		return nil
	end
	return spot
end

-- --------------------------------------------------------------- verbs --

local V = {}

function V.fishOpen(plr, p, payload)
	local spotId = type(payload) == "table" and payload.spotId
	if not atSpot(plr, spotId) then
		toast(plr, "Walk up to the water to fish")
		return
	end
	send(plr, "state", fullState(p, spotId))
end

function V.fishStart(plr, p, payload)
	local spotId = type(payload) == "table" and payload.spotId
	local spot = atSpot(plr, spotId)
	if not spot then
		toast(plr, "Walk up to the water to fish")
		return
	end
	local f = S.ensure(p)
	local rodId, row = rodRow(f)
	local st = M.rodStats(rodId, row.level)
	if f.bait < st.bait then
		toast(plr, (st.bait > 1) and ("This rod casts " .. st.bait .. " bait") or "No bait. AFK, quests or tokens get you more")
		return
	end
	pending[plr.UserId] = { stage = "cast", spotId = spotId, startedAt = os.clock() }
	send(plr, "cast", { spotId = spotId })
end

function V.fishCast(plr, p, payload)
	local pend = pending[plr.UserId]
	if not (pend and pend.stage == "cast") then
		return
	end
	local spot = atSpot(plr, pend.spotId)
	if not spot then
		pending[plr.UserId] = nil
		toast(plr, "You walked away from the water")
		return
	end
	local tick = math.floor(tonumber(type(payload) == "table" and payload.tick) or -1)
	local elapsed = os.clock() - pend.startedAt
	if tick < 0 or tick > M.CAST.maxTicks or tick / Fight.HZ > elapsed + 0.75 then
		pending[plr.UserId] = nil
		return
	end
	local f = S.ensure(p)
	local rodId, row = rodRow(f)
	local st = M.rodStats(rodId, row.level)
	if f.bait < st.bait then
		pending[plr.UserId] = nil
		return
	end
	f.bait -= st.bait
	f.casts += 1
	local quality = M.castQuality(tick)
	-- rod × spot × album (PROPOSED set bonuses) × cast quality
	local luck = st.luck * spot.luck * M.albumLuck(f.cooler, spot.zoneId) * (M.CAST.luck[quality] or 1)
	local rng = Random.new()
	local catches = {}
	for _ = 1, st.bait do
		local fish = M.rollFish(spot.zoneId, luck, rng)
		if fish then
			table.insert(catches, fish)
		end
	end
	if #catches == 0 then
		f.bait += st.bait
		pending[plr.UserId] = nil
		return
	end
	-- The fight is against the best of them: highest grade, then the biggest.
	local boss = catches[1]
	for _, c in ipairs(catches) do
		local gc, gb = M.fish(c.id).grade, M.fish(boss.id).grade
		if gc > gb or (gc == gb and c.size > boss.size) then
			boss = c
		end
	end
	local grade = M.fish(boss.id).grade
	local params = {
		seed = rng:NextInteger(1, 2147483000),
		fish = Fight.fishFromDifficulty(M.difficulty(spot.zoneId, grade)),
		rod = { reel = st.reel, line = st.line },
		size = boss.size,
	}
	local bite = M.BITE[1] + (M.BITE[2] - M.BITE[1]) * rng:NextNumber()
	pending[plr.UserId] = {
		stage = "fight",
		spotId = pend.spotId,
		params = params,
		catches = catches,
		fightAt = os.clock() + bite,
	}
	ctx.markDirty(plr)
	send(plr, "bite", {
		spotId = pend.spotId,
		quality = quality,
		bite = bite,
		fight = params,
		count = #catches,
		bait = f.bait,
	})
end

function V.fishReel(plr, p, payload)
	local pend = pending[plr.UserId]
	if not (pend and pend.stage == "fight") then
		return
	end
	pending[plr.UserId] = nil
	local f = S.ensure(p)
	local toggles = type(payload) == "table" and payload.toggles
	local ticks = math.floor(tonumber(type(payload) == "table" and payload.ticks) or 0)
	local result = "escaped"
	if type(toggles) == "table" and #toggles <= Fight.MAX_TICKS then
		-- It cannot have taken less time than it says (a little slack for lag).
		local elapsed = os.clock() - pend.fightAt
		if ticks / Fight.HZ <= elapsed * 1.15 + 1.5 then
			local r = Fight.replay(pend.params, toggles, ticks)
			if r == "caught" or r == "snapped" or r == "escaped" then
				result = r
			end
		end
	end
	if result == "caught" then
		f.landed += #pend.catches
		local target = M.catchOfDay(today())
		for _, c in ipairs(pend.catches) do
			local row = f.cooler[c.id]
			if type(row) ~= "table" then
				row = { n = 0, best = 0 }
				f.cooler[c.id] = row
				c.new = true
			end
			row.n = (tonumber(row.n) or 0) + 1
			if c.kg > (tonumber(row.best) or 0) then
				row.best = c.kg
				c.record = not c.new
			end
			if target and c.id == target.id then
				f.cotdGot = true
			end
		end
		M.sortCatch(pend.catches)
	else
		f.lost += #pend.catches
	end
	ctx.markDirty(plr)
	send(plr, "result", {
		result = result,
		catches = (result == "caught") and pend.catches or nil,
		count = #pend.catches,
		state = S.snapState(p),
	})
	ctx.snap(plr)
end

-- Walking away, closing the screen: the bait is spent, the fish is gone.
function V.fishGiveUp(plr, p)
	local pend = pending[plr.UserId]
	pending[plr.UserId] = nil
	if pend and pend.stage == "fight" then
		local f = S.ensure(p)
		f.lost += #pend.catches
		ctx.markDirty(plr)
	end
end

function V.fishBuyBait(plr, p, payload)
	local f = S.ensure(p)
	local want = math.clamp(math.floor(tonumber(type(payload) == "table" and payload.n) or 1), 1, M.BAIT_DAY_CAP)
	local room = M.baitRoom(f.baitGot)
	if room <= 0 then
		toast(plr, "That's today's " .. M.BAIT_DAY_CAP .. " bait. More tomorrow")
		return
	end
	local n = math.min(want, room)
	local cost = n * M.TOKEN_PRICE
	if (tonumber(p.temperTokens) or 0) < cost then
		toast(plr, "Not enough tokens: " .. n .. " bait is " .. cost)
		return
	end
	p.temperTokens = (tonumber(p.temperTokens) or 0) - cost
	gainBait(f, n)
	toast(plr, "+" .. n .. " bait")
	refresh(plr, p, type(payload) == "table" and payload.spotId)
end

function V.fishBuyRod(plr, p, payload)
	local f = S.ensure(p)
	local id = type(payload) == "table" and payload.rodId
	local r = M.rod(id)
	if not r or f.rods[id] then
		return
	end
	if (tonumber(p.coins) or 0) < r.price then
		toast(plr, "Not enough coins for the " .. r.name)
		return
	end
	p.coins = (tonumber(p.coins) or 0) - r.price
	f.rods[id] = { level = 0, gates = 0 }
	f.rod = id
	toast(plr, r.name .. " bought and equipped")
	refresh(plr, p, payload.spotId)
end

function V.fishEquipRod(plr, p, payload)
	local f = S.ensure(p)
	local id = type(payload) == "table" and payload.rodId
	if not f.rods[id] then
		return
	end
	f.rod = id
	refresh(plr, p, payload.spotId)
end

function V.fishUpgradeRod(plr, p, payload)
	local f = S.ensure(p)
	local id = type(payload) == "table" and payload.rodId
	local row = f.rods[id]
	if not row then
		return
	end
	local level, gates = tonumber(row.level) or 0, tonumber(row.gates) or 0
	if level >= M.levelCap(gates) then
		toast(plr, (level >= M.LEVEL_MAX) and "Max level" or "Prestige the rod with tokens to go past level " .. level)
		return
	end
	local cost = M.levelCost(id, level)
	if (tonumber(p.coins) or 0) < cost then
		toast(plr, "Not enough coins")
		return
	end
	p.coins = (tonumber(p.coins) or 0) - cost
	row.level = level + 1
	refresh(plr, p, payload.spotId)
end

function V.fishPrestigeRod(plr, p, payload)
	local f = S.ensure(p)
	local id = type(payload) == "table" and payload.rodId
	local row = f.rods[id]
	if not row then
		return
	end
	local level, gates = tonumber(row.level) or 0, tonumber(row.gates) or 0
	local cost = M.prestigeCost(gates)
	if not cost or level < M.levelCap(gates) or level >= M.LEVEL_MAX then
		return
	end
	if (tonumber(p.temperTokens) or 0) < cost then
		toast(plr, "Prestige costs " .. cost .. " tokens")
		return
	end
	p.temperTokens = (tonumber(p.temperTokens) or 0) - cost
	row.gates = gates + 1
	toast(plr, "Prestiged! Levels up to " .. M.levelCap(row.gates) .. " unlocked")
	refresh(plr, p, payload.spotId)
end

-- Sell one fish kind from the cooler for coins (PROPOSED prices). Keeps the
-- row at n=0 so the album still knows you caught it.
function V.fishSell(plr, p, payload)
	local f = S.ensure(p)
	local id = type(payload) == "table" and payload.fishId
	if not M.fish(id) then
		return
	end
	local row = f.cooler[id]
	local have = math.max(0, math.floor(tonumber(row and row.n) or 0))
	if have <= 0 then
		toast(plr, "None of those in the cooler")
		return
	end
	local want = math.clamp(math.floor(tonumber(type(payload) == "table" and payload.n) or 1), 1, have)
	local coins = M.sellCoins(id) * want
	row.n = have - want
	p.coins = (tonumber(p.coins) or 0) + coins
	toast(plr, "Sold " .. want .. "  +" .. coins .. " coins")
	refresh(plr, p, type(payload) == "table" and payload.spotId)
end

--[[
	SELL ALL cooler fish for coins. Without confirm: price and ask (same
	numbers the server will pay). With confirm: sell. Ore-pouch pattern.
]]
function V.fishSellAll(plr, p, payload)
	local f = S.ensure(p)
	local plan = M.sellPlan(f.cooler)
	if plan.units <= 0 then
		toast(plr, "Cooler is empty")
		return
	end
	if not (type(payload) == "table" and payload.confirm) then
		send(plr, "confirmSellAll", {
			units = plan.units,
			coins = plan.coins,
			kinds = plan.kinds,
			spotId = type(payload) == "table" and payload.spotId or nil,
		})
		return
	end
	for id, row in pairs(f.cooler) do
		local n = math.max(0, math.floor(tonumber(row and row.n) or 0))
		if n > 0 and M.fish(id) then
			row.n = 0
		end
	end
	p.coins = (tonumber(p.coins) or 0) + plan.coins
	toast(plr, "Sold " .. plan.units .. " fish  +" .. plan.coins .. " coins")
	refresh(plr, p, type(payload) == "table" and payload.spotId)
end

-- Claim catch-of-the-day coins once you have landed today's target.
function V.fishClaimCotd(plr, p, payload)
	local f = S.ensure(p)
	local target = M.catchOfDay(today())
	if not target then
		return
	end
	if not f.cotdGot then
		toast(plr, "Catch " .. target.name .. " today")
		return
	end
	if f.cotdClaimed then
		toast(plr, "Already claimed today's catch")
		return
	end
	f.cotdClaimed = true
	local coins = M.catchOfDayReward(target.id)
	p.coins = (tonumber(p.coins) or 0) + coins
	toast(plr, "Catch of the day! +" .. coins .. " coins")
	local spotId = type(payload) == "table" and payload.spotId
	if spotId then
		refresh(plr, p, spotId)
	else
		ctx.markDirty(plr)
		ctx.snap(plr)
	end
end

S.VERBS = V

function S.dispatch(plr, action, payload)
	local fn = V[action]
	local p = ctx.profiles and ctx.profiles[plr.UserId]
	if fn and p then
		fn(plr, p, payload)
	end
end

function S.prompt(plr, part)
	local p = ctx.profiles and ctx.profiles[plr.UserId]
	local spotId = part and part:GetAttribute("SpotId")
	if p and spotId then
		V.fishOpen(plr, p, { spotId = spotId })
	end
end

function S.questBait(plr, p)
	local f = S.ensure(p)
	local n = gainBait(f, M.QUEST_BAIT)
	if n > 0 then
		toast(plr, "+" .. n .. " bait")
	end
end

-- Time online pays bait (owner: "afked for"), toward the same daily cap.
local function afkTick()
	for _, plr in ipairs(Players:GetPlayers()) do
		local p = ctx.profiles and ctx.profiles[plr.UserId]
		if p then
			local f = S.ensure(p)
			if M.baitRoom(f.baitGot) > 0 then
				f.afk += S.AFK_TICK
				while f.afk >= M.AFK_SECS_PER_BAIT and M.baitRoom(f.baitGot) > 0 do
					f.afk -= M.AFK_SECS_PER_BAIT
					gainBait(f, 1)
					ctx.markDirty(plr)
				end
			else
				f.afk = 0
			end
		end
	end
end

function S.init(c)
	ctx = c
	Players.PlayerRemoving:Connect(function(plr)
		pending[plr.UserId] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(S.AFK_TICK)
			pcall(afkTick)
		end
	end)
end

return S
