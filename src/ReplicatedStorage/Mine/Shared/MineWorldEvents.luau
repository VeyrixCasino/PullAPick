-- MineWorldEvents: World Pulse DISABLED (random short mine buffs removed).
-- Module kept for snapshot/API compat; startLoop is a no-op.
-- Simple chance buffs only (gems / sell / luck). Tiers 1–4 gated; tier 5 reserved.

local MineWorldEvents = {}

MineWorldEvents.PULSE_GAP_SEC = 15 * 60
MineWorldEvents.DURATION_MIN = 60
MineWorldEvents.DURATION_MAX = 5 * 60

local RANK = { F = 1, D = 2, C = 3, B = 4, A = 5, S = 6, SS = 7, SSS = 8 }

MineWorldEvents.EVENTS = {
	{
		id = "lucky_breeze",
		name = "Lucky Breeze",
		tier = 1,
		blurb = "+25% luck while the pulse lasts.",
	},
	{
		id = "pocket_change",
		name = "Pocket Change",
		tier = 1,
		blurb = "+25% sell / coin value.",
	},
	{
		id = "gem_glow",
		name = "Gem Glow",
		tier = 2,
		blurb = "1.5× gems from sells.",
	},
	{
		id = "fortune_150",
		name = "Fortune 150",
		tier = 2,
		blurb = "150% luck (×1.5).",
	},
	{
		id = "double_sell",
		name = "Double Sell",
		tier = 3,
		blurb = "2× sell / coin value.",
	},
	{
		id = "gem_tide",
		name = "Gem Tide",
		tier = 3,
		blurb = "1.5× gems and a little luck.",
	},
	{
		id = "high_roller",
		name = "High Roller",
		tier = 4,
		blurb = "×1.75 luck — strong, not absurd.",
	},
	{
		id = "rich_haul",
		name = "Rich Haul",
		tier = 4,
		blurb = "×1.75 sell value and ×1.35 gems.",
	},
}

-- Tier 5 reserved — no events assigned (keep empty until we want absurd).
MineWorldEvents.TIER5_RESERVED = true

local BY_ID = {}
for _, ev in ipairs(MineWorldEvents.EVENTS) do
	BY_ID[ev.id] = ev
end

function MineWorldEvents.eventById(id)
	return BY_ID[id]
end

function MineWorldEvents.gearRank(rarity)
	if type(rarity) ~= "string" then
		return 0
	end
	return RANK[rarity] or 0
end

function MineWorldEvents.bestGearRankFromEquipped(equippedPieces)
	local best = 0
	if type(equippedPieces) ~= "table" then
		return 0
	end
	for _, piece in pairs(equippedPieces) do
		if type(piece) == "table" then
			local r = piece.rarity
			best = math.max(best, MineWorldEvents.gearRank(r))
		end
	end
	return best
end

--[[
	profile fields used for gates (same names as snap / live profile):
	  prestige, maxUnlockedZone, bestGearRank
]]
function MineWorldEvents.canAccess(profile, tier)
	tier = math.floor(tonumber(tier) or 1)
	if tier <= 1 then
		return true
	end
	if tier >= 5 then
		return false
	end
	profile = profile or {}
	local prestige = tonumber(profile.prestige) or 0
	local maxZ = tonumber(profile.maxUnlockedZone) or 1
	local gearRank = tonumber(profile.bestGearRank) or 0
	if tier == 2 then
		return maxZ >= 2 or prestige >= 1
	elseif tier == 3 then
		return prestige >= 3 or gearRank >= 5 -- A+
	elseif tier == 4 then
		return prestige >= 5 or gearRank >= 7 -- SS+
	end
	return false
end

function MineWorldEvents.lockReason(profile, tier)
	tier = math.floor(tonumber(tier) or 1)
	if MineWorldEvents.canAccess(profile, tier) then
		return nil
	end
	if tier >= 5 then
		return "Tier 5 reserved"
	end
	if tier == 2 then
		return "Need zone 2+ or 1 rebirth"
	end
	if tier == 3 then
		return "Need R3+ or A+ gear equipped"
	end
	if tier == 4 then
		return "Need R5+ or SS+ gear equipped"
	end
	return "Locked"
end

function MineWorldEvents.pickEvent(rng)
	rng = rng or Random.new()
	local list = MineWorldEvents.EVENTS
	return list[rng:NextInteger(1, #list)]
end

function MineWorldEvents.rollDuration(rng)
	rng = rng or Random.new()
	local mins = rng:NextInteger(1, 5)
	return mins * 60
end

local function mul(b, key, factor)
	if b[key] ~= nil then
		b[key] *= factor
	end
end

--[[
	Simple chance buffs only: luck / gemFind / coinBonus (sell value).
	No hot-zone dig absurdity — tier 5 stays empty for later.
]]
function MineWorldEvents.applyToBoosts(b, event, ctx)
	if not b or not event then
		return b
	end
	local id = event.id

	if id == "lucky_breeze" then
		mul(b, "luck", 1.25)
	elseif id == "pocket_change" then
		mul(b, "coinBonus", 1.25)
	elseif id == "gem_glow" then
		mul(b, "gemFind", 1.50)
	elseif id == "fortune_150" then
		mul(b, "luck", 1.50)
	elseif id == "double_sell" then
		mul(b, "coinBonus", 2.00)
	elseif id == "gem_tide" then
		mul(b, "gemFind", 1.50)
		mul(b, "luck", 1.25)
	elseif id == "high_roller" then
		mul(b, "luck", 1.75)
	elseif id == "rich_haul" then
		mul(b, "coinBonus", 1.75)
		mul(b, "gemFind", 1.35)
	end

	return b
end

function MineWorldEvents.chestSpawnMult(event, ctx)
	-- Chance buffs only; no chest-density pulses yet.
	return 1
end

--------------------------------------------------------------------------------
-- Server pulse runtime (kept on the module so MineServer needs no new locals).
--------------------------------------------------------------------------------

MineWorldEvents._rng = Random.new()
MineWorldEvents._event = nil
MineWorldEvents._endsAt = 0
MineWorldEvents._nextAt = os.clock() + MineWorldEvents.PULSE_GAP_SEC
MineWorldEvents._deps = nil

function MineWorldEvents.bind(deps)
	MineWorldEvents._deps = deps
end

function MineWorldEvents.deepestId(maxUnlocked)
	local C = MineWorldEvents._deps and MineWorldEvents._deps.C
	if not C then
		return "meadow"
	end
	maxUnlocked = math.max(1, math.floor(tonumber(maxUnlocked) or 1))
	local bestId = (C.ZONES[1] and C.ZONES[1].id) or "meadow"
	for i, z in ipairs(C.ZONES) do
		if i <= maxUnlocked and (not C.isProgressionZone or C.isProgressionZone(z)) then
			bestId = z.id
		end
	end
	return bestId
end

function MineWorldEvents.access(p)
	local Gear = MineWorldEvents._deps and MineWorldEvents._deps.Gear
	local equippedPieces = {}
	for slot, pieceId in pairs(p.equippedGear or {}) do
		if pieceId then
			for _, g in ipairs(p.gear or {}) do
				if g.id == pieceId then
					local rarity = g.rarity
					if Gear and Gear.migrateRarity then
						rarity = Gear.migrateRarity(rarity)
					end
					equippedPieces[slot] = { rarity = rarity }
					break
				end
			end
		end
	end
	return {
		prestige = p.prestige or 0,
		maxUnlockedZone = p.maxUnlockedZone or 1,
		bestGearRank = MineWorldEvents.bestGearRankFromEquipped(equippedPieces),
		zoneId = p.zoneId,
	}
end

function MineWorldEvents.ctx(p)
	local access = MineWorldEvents.access(p)
	local deepestId = MineWorldEvents.deepestId(access.maxUnlockedZone)
	access.deepestZoneId = deepestId
	access.inHotZone = access.zoneId == deepestId
	return access
end

function MineWorldEvents.payload(phase, p)
	local ev = MineWorldEvents._event
	local now = os.clock()
	local active = ev ~= nil and now < (MineWorldEvents._endsAt or 0)
	if not active then
		ev = nil
	end
	local access = p and MineWorldEvents.access(p) or { prestige = 0, maxUnlockedZone = 1, bestGearRank = 0 }
	local eligible = ev ~= nil and MineWorldEvents.canAccess(access, ev.tier)
	return {
		phase = phase,
		event = ev and { id = ev.id, name = ev.name, tier = ev.tier, blurb = ev.blurb } or nil,
		endsAt = active and MineWorldEvents._endsAt or 0,
		nextAt = MineWorldEvents._nextAt or 0,
		eligible = eligible == true,
		lockReason = (ev and not eligible) and MineWorldEvents.lockReason(access, ev.tier) or nil,
		serverNow = now,
	}
end

function MineWorldEvents.broadcast(phase)
	local deps = MineWorldEvents._deps
	if not deps then
		return
	end
	for _, plr in ipairs(deps.Players:GetPlayers()) do
		deps.net:FireClient(plr, "worldEvent", MineWorldEvents.payload(phase, deps.profiles[plr.UserId]))
	end
end

function MineWorldEvents.foldBoosts(b, p)
	local ev = MineWorldEvents._event
	if not (ev and os.clock() < (MineWorldEvents._endsAt or 0)) then
		return
	end
	local ctx = MineWorldEvents.ctx(p)
	if MineWorldEvents.canAccess(ctx, ev.tier) then
		MineWorldEvents.applyToBoosts(b, ev, ctx)
	end
end

function MineWorldEvents.startLoop(snapFn)
	-- Disabled: no random 1–5m mine pulses.
	MineWorldEvents._event = nil
	MineWorldEvents._endsAt = 0
	MineWorldEvents._nextAt = math.huge
	return
end

return MineWorldEvents
