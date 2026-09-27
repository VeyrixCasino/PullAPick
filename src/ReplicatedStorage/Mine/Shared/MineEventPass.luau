--[[
	MineEventPass -- limited-event progression (quests + bonus track).

	Quests here are ONLY for the active event. Completing them grants
	event XP toward the bonus track — never coins/gems/packs from this ladder.
	Bonuses apply only while the event is live.
]]

local MineEventPass = {}

MineEventPass.TRACKS = {
	event_horizon = {
		id = "event_horizon",
		name = "Event Horizon Pass",
		blurb = "Clear event quests to power up your Event Horizon run.",
		tiers = {
			{ id = "eh1", xp = 0,   name = "Horizon Scout",   bonus = { luck = 1.05 }, tip = "+5% luck in Event Horizon" },
			{ id = "eh2", xp = 40,  name = "Rim Runner",      bonus = { luck = 1.08, sell = 1.05 }, tip = "+8% luck, +5% sell" },
			{ id = "eh3", xp = 90,  name = "Wormhole Ready",  bonus = { luck = 1.12, sell = 1.08, gems = 1.05 }, tip = "+12% luck, +8% sell, +5% gems" },
			{ id = "eh4", xp = 160, name = "Cosmo Dig",       bonus = { luck = 1.16, sell = 1.12, gems = 1.10 }, tip = "+16% luck, +12% sell, +10% gems" },
			{ id = "eh5", xp = 250, name = "Matter Bound",    bonus = { luck = 1.20, sell = 1.15, gems = 1.12, ore = 1.08 }, tip = "+20% luck, +15% sell, +12% gems, +8% ore" },
			{ id = "eh6", xp = 360, name = "Event Horizon",   bonus = { luck = 1.25, sell = 1.18, gems = 1.15, ore = 1.12 }, tip = "Max event power" },
		},
		quests = {
			{ id = "eh_mine50",   stat = "blocks",  goal = 50,   xp = 15, text = "Break 50 blocks during the event" },
			{ id = "eh_mine200",  stat = "blocks",  goal = 200,  xp = 25, text = "Break 200 blocks during the event" },
			{ id = "eh_mine500",  stat = "blocks",  goal = 500,  xp = 40, text = "Break 500 blocks during the event" },
			{ id = "eh_sell3",    stat = "sells",   goal = 3,    xp = 15, text = "Sell your haul 3 times" },
			{ id = "eh_sell10",   stat = "sells",   goal = 10,   xp = 25, text = "Sell your haul 10 times" },
			{ id = "eh_depth30",  stat = "depth",   goal = 30,   xp = 20, text = "Reach layer 30 in Event Horizon" },
			{ id = "eh_depth80",  stat = "depth",   goal = 80,   xp = 35, text = "Reach layer 80 in Event Horizon" },
			{ id = "eh_packs2",   stat = "packs",   goal = 2,    xp = 20, text = "Open 2 packs during the event" },
			{ id = "eh_packs5",   stat = "packs",   goal = 5,    xp = 35, text = "Open 5 packs during the event" },
			{ id = "eh_fossils",  stat = "fossils", goal = 1,    xp = 30, text = "Find a fossil pack in the event mine" },
		},
	},
}

function MineEventPass.track(eventId)
	return MineEventPass.TRACKS[eventId]
end

function MineEventPass.blankProgress(eventId)
	return {
		xp = 0,
		questIndex = 1,
		questBase = {},
		completed = {},
	}
end

function MineEventPass.ensure(profile, eventId)
	profile.eventPass = profile.eventPass or {}
	if type(profile.eventPass[eventId]) ~= "table" then
		profile.eventPass[eventId] = MineEventPass.blankProgress(eventId)
	end
	local ep = profile.eventPass[eventId]
	ep.xp = math.max(0, math.floor(tonumber(ep.xp) or 0))
	ep.questIndex = math.max(1, math.floor(tonumber(ep.questIndex) or 1))
	ep.questBase = type(ep.questBase) == "table" and ep.questBase or {}
	ep.completed = type(ep.completed) == "table" and ep.completed or {}
	return ep
end

function MineEventPass.liveStats(profile)
	profile.stats = profile.stats or {}
	return {
		blocks = tonumber(profile.stats.eventBlocks) or 0,
		sells = tonumber(profile.stats.eventSells) or 0,
		packs = tonumber(profile.stats.eventPacks) or 0,
		fossils = tonumber(profile.stats.eventFossils) or 0,
		depth = tonumber(profile.deepest and profile.deepest.bigbang) or 0,
	}
end

function MineEventPass.currentQuest(eventId, ep)
	local track = MineEventPass.TRACKS[eventId]
	if not track then return nil end
	local i = math.clamp(ep.questIndex or 1, 1, #track.quests + 1)
	if i > #track.quests then return nil, i end
	return track.quests[i], i
end

function MineEventPass.questProgress(ep, quest, liveStats)
	if not quest then return 0, 0 end
	liveStats = liveStats or {}
	local base = tonumber(ep.questBase and ep.questBase[quest.stat]) or 0
	local now = tonumber(liveStats[quest.stat]) or 0
	if quest.stat == "depth" then
		return math.min(quest.goal, now), quest.goal
	end
	return math.min(quest.goal, math.max(0, now - base)), quest.goal
end

function MineEventPass.tierIndex(eventId, xp)
	local track = MineEventPass.TRACKS[eventId]
	if not track then return 0, nil end
	local best, bestTier = 0, track.tiers[1]
	for i, tier in ipairs(track.tiers) do
		if xp >= (tier.xp or 0) then
			best, bestTier = i, tier
		end
	end
	return best, bestTier
end

function MineEventPass.activeBonus(eventId, xp)
	local _, tier = MineEventPass.tierIndex(eventId, xp)
	return (tier and tier.bonus) or {}
end

function MineEventPass.baselineQuest(ep, quest, liveStats)
	if not quest or quest.stat == "depth" then return end
	ep.questBase = ep.questBase or {}
	ep.questBase[quest.stat] = tonumber(liveStats and liveStats[quest.stat]) or 0
end

--[[
	Advance event quest if complete. Returns true if something changed.
	NO economy rewards — XP only.
]]
function MineEventPass.tick(eventId, profile)
	local track = MineEventPass.TRACKS[eventId]
	if not track then return false end
	local ep = MineEventPass.ensure(profile, eventId)
	local live = MineEventPass.liveStats(profile)
	local changed = false
	while true do
		local quest, qi = MineEventPass.currentQuest(eventId, ep)
		if not quest then break end
		if ep.questBase[quest.stat] == nil and quest.stat ~= "depth" then
			MineEventPass.baselineQuest(ep, quest, live)
		end
		local prog, goal = MineEventPass.questProgress(ep, quest, live)
		if prog < goal then break end
		ep.completed[quest.id] = true
		ep.xp += math.max(0, math.floor(tonumber(quest.xp) or 0))
		ep.questIndex = qi + 1
		changed = true
		local nextQ = MineEventPass.currentQuest(eventId, ep)
		if nextQ then
			MineEventPass.baselineQuest(ep, nextQ, live)
		end
	end
	return changed
end

function MineEventPass.payload(eventId, profile)
	local track = MineEventPass.TRACKS[eventId]
	if not track then return nil end
	local ep = MineEventPass.ensure(profile, eventId)
	local live = MineEventPass.liveStats(profile)
	local quest, qi = MineEventPass.currentQuest(eventId, ep)
	local prog, goal = 0, 0
	if quest then
		prog, goal = MineEventPass.questProgress(ep, quest, live)
	end
	local tierI, tier = MineEventPass.tierIndex(eventId, ep.xp)
	local nextTier = track.tiers[tierI + 1]
	return {
		eventId = eventId,
		name = track.name,
		blurb = track.blurb,
		xp = ep.xp,
		tierIndex = tierI,
		tier = tier and { id = tier.id, name = tier.name, tip = tier.tip, bonus = tier.bonus, xp = tier.xp } or nil,
		nextTier = nextTier and { id = nextTier.id, name = nextTier.name, tip = nextTier.tip, xp = nextTier.xp } or nil,
		tiers = track.tiers,
		quest = quest and {
			id = quest.id,
			text = quest.text,
			stat = quest.stat,
			progress = prog,
			goal = goal,
			xp = quest.xp,
		} or nil,
		questIndex = qi,
		questTotal = #track.quests,
		completed = ep.completed,
		bonus = MineEventPass.activeBonus(eventId, ep.xp),
	}
end

return MineEventPass
