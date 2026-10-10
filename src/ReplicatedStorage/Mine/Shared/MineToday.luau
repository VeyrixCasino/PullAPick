--[[
	MineToday -- the TODAY checklist (TODO A2).

	Owner, 2026-10-10: the TODAY checklist goes INSIDE the Quests panel, at the
	top. One row per daily thing, with its timer: the daily reward, the daily
	quests, playtime gifts, the wheel, the Job Board, the pass, the event pass's
	quests and the event mines. A row that pays out now is READY and pulses
	(candy-style: "what pays out always moves"); tapping a row opens its screen.

	PURE ON PURPOSE. rows() reads only what the client already holds -- the
	snapshot, the clock, and a small context the caller builds (the playtime
	estimate, the gift schedule, the Candy Crypt's window) -- and requires
	nothing, so tools/verify/today.js runs it offline. MineClient paints it
	(ClientFns.paintTodayBox) on every snapshot and once a second.

	Every daily resets at UTC midnight (the server's day is floor(os.time()/86400)).
]]
local M = {}

-- Row order, and where a tap goes (MineClient ClientFns.todayOpen reads `open`).
M.ORDER = {
	{ id = "daily", label = "Daily reward", open = "daily" },
	{ id = "quests", label = "Daily quests", open = "daily" },
	{ id = "gifts", label = "Playtime gifts", open = "gifts" },
	{ id = "wheel", label = "Wheel", open = "wheel" },
	{ id = "jobs", label = "Job Board", open = "jobs" },
	{ id = "pass", label = "Pass rewards", open = "pass" },
	{ id = "eventpass", label = "Event quests", open = "events" },
	{ id = "bigbang", label = "Event Horizon", open = "events" },
	{ id = "hallow", label = "Candy Crypt", open = "zones" },
}

-- "5h 12m", "12m", "45s": coarse far out, finer close in.
function M.clock(secs)
	secs = math.max(0, math.floor(tonumber(secs) or 0))
	if secs >= 3600 then
		return string.format("%dh %02dm", math.floor(secs / 3600), math.floor(secs % 3600 / 60))
	end
	if secs >= 60 then
		return string.format("%dm %02ds", math.floor(secs / 60), secs % 60)
	end
	return secs .. "s"
end

local function untilMidnight(now)
	return 86400 - (math.floor(now) % 86400)
end

-- Claimable / claimed counts for a quest-shaped list (daily quests, contracts).
local function questCounts(list)
	local ready, claimed, total = 0, 0, 0
	for _, q in ipairs(type(list) == "table" and list or {}) do
		total += 1
		if q.claimed then
			claimed += 1
		elseif q.ready then
			ready += 1
		end
	end
	return ready, claimed, total
end

local function listedSet(list)
	local s = {}
	for _, n in ipairs(type(list) == "table" and list or {}) do
		s[math.floor(tonumber(n) or 0)] = true
	end
	return s
end

--[[
	rows(snap, now, ctx) -> { { id, label, open, text, ready, done, live } ... }

	  ready  pays out now (pulses, counts toward the panel's green dot)
	  done   nothing more today (muted)
	  live   an event that is open (gold), never "ready": it is a place, not a prize

	ctx (all optional):
	  giftSecs, giftsGot   ClientFns.playtimeNow(): seconds played today, claimed map
	  gifts                MineQuests.PLAYTIME: { { min = 2 }, ... }
	  crypt                { active = bool, countdown = "6d 5h" | "closed" }
]]
function M.rows(snap, now, ctx)
	snap = type(snap) == "table" and snap or {}
	ctx = type(ctx) == "table" and ctx or {}
	now = tonumber(now) or 0
	local out = {}
	local function put(id, text, flags)
		for _, def in ipairs(M.ORDER) do
			if def.id == id then
				flags = flags or {}
				table.insert(out, {
					id = id,
					label = def.label,
					open = def.open,
					text = text,
					ready = flags.ready == true,
					done = flags.done == true,
					live = flags.live == true,
				})
				return
			end
		end
	end
	local reset = M.clock(untilMidnight(now))

	-- Daily reward calendar.
	local d = snap.daily
	if type(d) == "table" and d.ready then
		put("daily", "CLAIM!", { ready = true })
	else
		put("daily", "in " .. reset, { done = true })
	end

	-- The three daily quests.
	do
		local ready, claimed, total = questCounts(snap.dailyQuests)
		if ready > 0 then
			put("quests", ready .. " to claim", { ready = true })
		elseif total > 0 and claimed >= total then
			put("quests", "done  ·  new in " .. reset, { done = true })
		else
			put("quests", claimed .. "/" .. math.max(total, 3) .. " done")
		end
	end

	-- Playtime gifts: ready when played long enough and not yet opened.
	do
		local secs = tonumber(ctx.giftSecs) or 0
		local got = type(ctx.giftsGot) == "table" and ctx.giftsGot or {}
		local ready, nextIn, left = 0, nil, 0
		for i, g in ipairs(type(ctx.gifts) == "table" and ctx.gifts or {}) do
			if not got[tostring(i)] and not got[i] then
				left += 1
				local at = (tonumber(g.min) or 0) * 60
				if secs >= at then
					ready += 1
				elseif not nextIn or at - secs < nextIn then
					nextIn = at - secs
				end
			end
		end
		if ready > 0 then
			put("gifts", ready == 1 and "OPEN!" or (ready .. " to open"), { ready = true })
		elseif left == 0 then
			put("gifts", "done  ·  new in " .. reset, { done = true })
		else
			put("gifts", "next in " .. M.clock(nextIn or 0))
		end
	end

	-- The wheel: free spins refill at UTC midnight. Paid spins never expire.
	do
		local w = snap.groupWheel
		local free = type(w) == "table" and (tonumber(w.freeLeft) or 0) or 0
		if free > 0 then
			put("wheel", free == 1 and "1 free spin" or (free .. " free spins"), { ready = true })
		else
			put("wheel", "free spin in " .. reset, { done = true })
		end
	end

	-- Job Board contracts.
	do
		local ready, claimed, total = questCounts(snap.contracts)
		if ready > 0 then
			put("jobs", ready .. " to claim", { ready = true })
		elseif total > 0 and claimed >= total then
			put("jobs", "done  ·  new in " .. reset, { done = true })
		else
			put("jobs", claimed .. "/" .. math.max(total, 3) .. " done")
		end
	end

	-- The pass: every tier reached pays a free reward, and a premium one if owned.
	-- Reads the claimed LISTS (the claim maps can arrive empty over the remote).
	do
		local p = snap.pass
		if type(p) == "table" then
			local tier = math.floor(tonumber(p.tier) or 0)
			local free, prem = listedSet(p.freeClaimed), listedSet(p.premClaimed)
			local n = 0
			for t = 1, tier do
				if not free[t] then
					n += 1
				end
				if p.owned and not prem[t] then
					n += 1
				end
			end
			if n > 0 then
				put("pass", n == 1 and "1 reward" or (n .. " rewards"), { ready = true })
			else
				put("pass", "tier " .. tier .. "/" .. tostring(p.tiers or 100))
			end
		else
			put("pass", "-")
		end
	end

	-- The event pass's quests: one at a time, finished by playing (no claim).
	do
		local ep = snap.eventPass
		if not snap.limitedActive then
			put("eventpass", "event closed", { done = true })
		elseif type(ep) ~= "table" then
			put("eventpass", "-")
		elseif type(ep.quest) ~= "table" then
			put("eventpass", "all " .. tostring(ep.questTotal or 10) .. " done", { done = true })
		else
			local goal = math.max(1, tonumber(ep.quest.goal) or 1)
			local pct = math.floor(math.clamp((tonumber(ep.quest.progress) or 0) / goal, 0, 1) * 100)
			put("eventpass", string.format("quest %d/%d  ·  %d%%", tonumber(ep.questIndex) or 1,
				tonumber(ep.questTotal) or 10, pct))
		end
	end

	-- Event mines. Event Horizon's window runs on the server's launch clock, which
	-- the client does not have, so its open/closed comes from the snapshot. The
	-- Candy Crypt is on real dates, which the client can count itself.
	put("bigbang", snap.limitedActive and "OPEN" or "closed", { live = snap.limitedActive == true, done = not snap.limitedActive })
	do
		local c = type(ctx.crypt) == "table" and ctx.crypt or {}
		local cd = tostring(c.countdown or "closed")
		if c.active then
			put("hallow", "OPEN  ·  " .. cd .. " left", { live = true })
		elseif cd == "closed" then
			put("hallow", "closed", { done = true })
		else
			put("hallow", "opens in " .. cd)
		end
	end
	return out
end

--[[
	ONLY WHAT IS ACTIVE (owner, 2026-10-10, on seeing all nine rows: "to many
	quests and unneed info.. just put active ones"). The panel shows a row only
	while it pays out now (ready) or is an event mine that is open (live). Done
	rows, closed events and countdowns are hidden; so are the daily quests and
	the event quests, which the Daily Quests box right below already shows.
	With nothing active the TODAY box is not shown at all.
]]
M.NOT_IN_PANEL = { quests = true, eventpass = true }

function M.active(rows)
	local out = {}
	for _, r in ipairs(rows or {}) do
		if (r.ready or r.live) and not M.NOT_IN_PANEL[r.id] then
			table.insert(out, r)
		end
	end
	return out
end

function M.readyCount(rows)
	local n = 0
	for _, r in ipairs(rows or {}) do
		if r.ready then
			n += 1
		end
	end
	return n
end

return M
