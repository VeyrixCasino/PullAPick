--[[
	MineFishingFight -- the reel fight, as a pure simulation (TODO A3).

	Owner, 2026-10-10, the whole design in their words:

	  "you have to press reel in and the fish is either RED, YELLOW, or GREEN.
	  On yellow you can reel it in but the tension grows a decent bit, on green
	  you can reel in and it come in quick, and tension doesnt go up much at
	  all. Red the tension grows fast as fuck. So basically when the fish gets
	  to far, it breaks free, when the tension bar maxes out, it gets free.
	  Better the fish hard it is to get in, sometimes taking minutes for Exotic
	  catchs ... You have to player it smart and spam tap when it runs, or hold
	  for just long enough so it doesnt snap you rodd off.. after holding so
	  much tension for a ehile your rods minimum turns to that number.. if the
	  fish goes above 100 meters a way theres a 3% chance per percent/second
	  that the fish gets away."

	and on the escape rule chose "3%/s for each meter past 100 m".

	So, per tick:
	  * the fish has a COLOUR -- green (tired), yellow (struggling), red
	    (running) -- in spells of random length. Harder fish run more often,
	    for longer, and tire later.
	  * REELING pulls the fish in (fast on green, slow on red) and raises the
	    TENSION (barely on green, a fair bit on yellow, very fast on red),
	    divided by the rod's line strength.
	  * NOT reeling lets the tension fall back -- but never below the FLOOR.
	  * the fish always swims away, hardest on red.
	  * THE FLOOR CREEPS UP while the tension is held high (RATCHET_AT), so
	    holding too long costs you headroom for the rest of the fight.
	  * tension 1 snaps the line; distance 0 lands the fish; past
	    ESCAPE_AT metres, each metre over is ESCAPE_PER_M a second of escape.

	DETERMINISTIC ON PURPOSE. Only + - * / and comparisons, and its own
	integer generator (no Random, no math.random, no math.log): the client
	plays the fight, sends when the reel button went down and up, and the
	server REPLAYS the same seed and the same presses and gets the same
	answer (MineFishing / MineFishingService). tools/sim/fishing-tune.js runs
	it offline too, to tune the fish against a bot.
]]
local F = {}

F.HZ = 30
F.DT = 1 / 30
F.ESCAPE_AT = 100 -- metres (owner)
F.ESCAPE_PER_M = 0.03 -- escape chance per second, per metre past ESCAPE_AT (owner)
F.MAX_TICKS = 30 * 60 * 20 -- 20 minutes: a fight that long is called off (the fish wins)
F.MAX_DIST = 140 -- the line runs out here; the fish is gone

-- What a colour does to reeling, to the tension a reel adds, and to the run.
F.COLOUR = {
	green = { reel = 1.0, tension = 0.25, swim = 0.15 },
	yellow = { reel = 0.75, tension = 1.0, swim = 0.55 },
	red = { reel = 0.3, tension = 3.2, swim = 1.6 },
}
F.TENSION_DECAY = 0.55 -- per second, toward the floor, while not reeling
F.RATCHET_AT = 0.6 -- tension held above this lifts the floor...
F.RATCHET_RATE = 0.06 -- ...closing this share of the gap a second
F.FLOOR_MAX = 0.85
F.TIRE_RED = 0.6 -- a fully tired fish runs this much less often
F.TIRE_SWIM = 0.5 -- ...and swims this much slower
--[[
	NO TWO FISH ALIKE, AND THE BIG ONES FIGHT. The first tuning run found a
	cliff: with every fish of a grade the same, a good player landed it every
	time or never, and tuning the common fish to "almost always" made them
	minute-long fights. So a fish's SPIRIT (x its swim and pull) follows its
	SIZE: the smallest of a kind fights at SPIRIT_LO, the biggest at SPIRIT_HI.
	Most catches are small (MineFishing.rollFish), so most fights are quick,
	and the record-sized one is the fight you remember. LONG_RUN of runs also
	last LONG_RUN_X as long. All of it rides the fight's params and seed, so it
	still replays.
]]
F.SPIRIT_LO = 0.6
F.SPIRIT_HI = 1.6

-- size: 0 = the smallest of its kind, 1 = the biggest.
function F.spiritOf(size)
	return F.SPIRIT_LO + (F.SPIRIT_HI - F.SPIRIT_LO) * math.clamp(tonumber(size) or 0.5, 0, 1)
end
F.LONG_RUN = 0.2
F.LONG_RUN_X = 2.5

-- A fish's fight from one number, its DIFFICULTY (0 = a sleepy minnow, ~1 =
-- the hardest the tuner found any bot could land; MineFishing sets it per
-- grade). Every field is plain data, so a fight can be sent and replayed.
function F.fishFromDifficulty(d)
	d = math.max(0, tonumber(d) or 0)
	return {
		difficulty = d,
		startDist = 30 + 30 * d, -- metres out when it bites
		swim = 1 + 2.2 * d, -- metres a second it pulls away (x the colour's swim)
		pull = 0.25 + 0.9 * d, -- tension a second while reeling on yellow
		pRed = math.min(0.55, 0.12 + 0.33 * d), -- share of spells that are runs
		pYellow = 0.35,
		redLen = 1 + 1.2 * d, -- mean seconds of a run
		calmLen = 2.2, -- mean seconds of a green spell
		fightLen = 1.6, -- mean seconds of a yellow spell
		stamina = 40 + 200 * d, -- seconds until it is fully tired
	}
end

-- A seed the generator accepts: 1 .. 2^31-2.
function F.seed(n)
	n = math.floor(math.abs(tonumber(n) or 1)) % 2147483646
	return n + 1
end

local function rand(s)
	s.r = (s.r * 48271) % 2147483647
	return s.r / 2147483647
end

local function nextSpell(s)
	local fish = s.fish
	local tired = math.min(1, s.t / math.max(1, fish.stamina))
	local pRed = fish.pRed * (1 - F.TIRE_RED * tired)
	local pYellow = fish.pYellow
	local u = rand(s)
	local colour, mean
	if u < pRed then
		colour, mean = "red", fish.redLen
		if rand(s) < F.LONG_RUN then
			mean *= F.LONG_RUN_X
		end
	elseif u < pRed + pYellow then
		colour, mean = "yellow", fish.fightLen
	else
		colour, mean = "green", fish.calmLen
	end
	-- Uniform 0.5x .. 1.5x of the mean: no log, so it replays exactly.
	s.colour = colour
	s.left = math.max(3, math.floor(mean * (0.5 + rand(s)) * F.HZ + 0.5))
end

--[[
	params = { seed, fish (fishFromDifficulty), rod = { reel = m/s, line = x },
	           size = 0..1 (the fish's size within its kind; MineFishing.rollFish) }
	A fight opens on a green spell, so the first second is never a coin flip.
]]
function F.new(params)
	local s = {
		r = F.seed(params.seed),
		fish = params.fish,
		reel = math.max(0.1, tonumber(params.rod and params.rod.reel) or 4),
		line = math.max(0.1, tonumber(params.rod and params.rod.line) or 1),
		dist = params.fish.startDist,
		tension = 0,
		floor = 0,
		tick = 0,
		t = 0,
		colour = "green",
		left = F.HZ,
		result = nil,
	}
	-- A fish's size sets its spirit; without one (old callers), the seed does.
	local u = rand(s)
	s.spirit = F.spiritOf(params.size ~= nil and params.size or u)
	return s
end

-- One tick. `reeling` is whether the reel button is down this tick.
function F.step(s, reeling)
	if s.result then
		return s.result
	end
	local dt = F.DT
	s.tick += 1
	s.t = s.tick * dt
	local c = F.COLOUR[s.colour]
	local fish = s.fish
	local tired = math.min(1, s.t / math.max(1, fish.stamina))
	if reeling then
		s.dist -= s.reel * c.reel * dt
		s.tension += fish.pull * s.spirit * c.tension / s.line * dt
	else
		s.tension = math.max(s.floor, s.tension - F.TENSION_DECAY * dt)
	end
	s.dist += fish.swim * s.spirit * c.swim * (1 - F.TIRE_SWIM * tired) * dt
	-- The floor remembers what you held.
	if s.tension > F.RATCHET_AT and s.tension > s.floor then
		s.floor = math.min(F.FLOOR_MAX, s.floor + (s.tension - s.floor) * F.RATCHET_RATE * dt)
	end
	if s.tension >= 1 then
		s.tension = 1
		s.result = "snapped"
	elseif s.dist <= 0 then
		s.dist = 0
		s.result = "caught"
	elseif s.dist >= F.MAX_DIST then
		s.result = "escaped"
	elseif s.dist > F.ESCAPE_AT then
		-- The owner's rule: 3% a second for every metre past 100.
		if rand(s) < F.ESCAPE_PER_M * (s.dist - F.ESCAPE_AT) * dt then
			s.result = "escaped"
		end
	end
	if not s.result and s.tick >= F.MAX_TICKS then
		s.result = "escaped"
	end
	s.left -= 1
	if s.left <= 0 then
		nextSpell(s)
	end
	return s.result
end

--[[
	Replay a fight from its presses. `toggles` is the list of ticks on which
	the reel button changed (down, up, down ...), ascending; `ticks` is how
	long the client says it ran. Returns the result and the tick it ended on,
	or nil if the log is malformed.
]]
function F.replay(params, toggles, ticks)
	if type(toggles) ~= "table" then
		return nil
	end
	ticks = math.floor(tonumber(ticks) or 0)
	if ticks < 1 or ticks > F.MAX_TICKS or #toggles > ticks + 1 then
		return nil
	end
	local s = F.new(params)
	local i, reeling, last = 1, false, 0
	for tick = 1, ticks do
		while toggles[i] ~= nil do
			local at = tonumber(toggles[i])
			if not at or at < last then
				return nil
			end
			if at > tick then
				break
			end
			last = at
			reeling = not reeling
			i += 1
		end
		local r = F.step(s, reeling)
		if r then
			return r, tick, s
		end
	end
	return "unfinished", ticks, s
end

return F
