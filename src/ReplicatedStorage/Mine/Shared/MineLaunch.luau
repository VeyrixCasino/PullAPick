--[[
	MineLaunch — the season does not begin until the owner says so.

	Owner, 2026-10-07: "i want the timer to not actually start until i say
	launch, and rather just keep ticking down".

	THE SEASON IS A DURATION, NOT A DATE. That is the whole idea here, and
	everything else follows from it.

	Today the season is two absolute timestamps: MineRotatingOffers.SEASON_START
	(2026-09-22) and SEASON_END (2026-11-01). Those are wall-clock dates, so the
	season is ALREADY RUNNING -- offers have rotated, the battle pass has been
	counting down, and week one is long gone, with nobody playing. Whenever the
	game actually opens, players arrive midway through a season they never saw
	the start of, and nothing can stop that except moving the dates by hand and
	moving them again on every slip.

	So the clock is shifted instead. `seasonNow()` is what every season-timed
	system should read in place of os.time():

	  BEFORE LAUNCH it returns SEASON_START exactly. Zero seconds have elapsed,
	  so offer slot one is live, the pass is full length, and nothing can expire.
	  The season is not paused in some separate sense -- it genuinely has not
	  begun, because no time has passed in it.

	  AFTER LAUNCH it returns SEASON_START + (now - launchedAt), so the season
	  runs its full designed length starting from the moment the switch was
	  thrown, whenever that is. A week's delay costs nothing; the season is still
	  a whole season.

	THE VISIBLE COUNTDOWN KEEPS TICKING, which is the second half of the ask and
	the part that looks contradictory. `teaserLeft()` is driven by real os.time()
	and falls second by second, so a player watching the screen sees a live clock
	rather than a frozen one -- but it is cosmetic. It counts toward
	TEASER_TARGET, nothing watches it, and when it runs out it rolls over and
	counts down again. No season logic reads it. Nothing fires when it hits zero.

	LAUNCHING IS A FLAG, NOT A DATE, deliberately. A date would launch the game
	while nobody is awake to watch it, which is the exact failure this exists to
	prevent. `launchedAt` is stamped by the owner through an admin verb and
	persisted; until then the game sits at second zero for as long as it takes.
]]
local MineLaunch = {}

-- Set by the server from saved state. 0 means "not launched yet".
-- Never read this directly; go through isLaunched / seasonNow, which handle the
-- nil, the zero and the negative-clock cases in one place.
MineLaunch.launchedAt = 0

--[[
	The season's own start instant, which every season timestamp is measured
	from. Kept here rather than imported from MineRotatingOffers so this module
	stays leaf-level: MineRotatingOffers will read seasonNow(), and a cycle
	between the two would be a load-order bug waiting to happen.

	It must stay equal to MineRotatingOffers.SEASON_START and
	MineScrolls.PASS_SEASON_START. tools/verify/launch.js asserts that.
]]
MineLaunch.SEASON_START = 1790049600

-- What the cosmetic pre-launch countdown counts toward, in seconds. It rolls
-- over and starts again; the number only has to look alive.
MineLaunch.TEASER_PERIOD = 86400

function MineLaunch.isLaunched()
	return (tonumber(MineLaunch.launchedAt) or 0) > 0
end

--[[
	The season clock. Pass this wherever a season-timed function wants `now`.

	`realNow` is injectable so a harness can walk the clock without sleeping, and
	so the server can pass one consistent value across a whole snapshot rather
	than letting three systems read os.time() a millisecond apart.
]]
function MineLaunch.seasonNow(realNow)
	local t = math.floor(tonumber(realNow) or os.time())
	local at = math.floor(tonumber(MineLaunch.launchedAt) or 0)
	if at <= 0 then
		return MineLaunch.SEASON_START
	end
	-- max(0): a clock that went backwards (a server with a bad time, or a
	-- launch stamped in the future) must not rewind the season to before it
	-- started, which would resurrect expired offers.
	return MineLaunch.SEASON_START + math.max(0, t - at)
end

-- How long the season has been running, in seconds. 0 before launch.
function MineLaunch.elapsed(realNow)
	return MineLaunch.seasonNow(realNow) - MineLaunch.SEASON_START
end

--[[
	The cosmetic countdown, in seconds. Always between 1 and TEASER_PERIOD, and
	always falling.

	Returns nil once launched: after launch the real season timers are the ones
	worth showing, and a second countdown next to them would be a lie.
]]
function MineLaunch.teaserLeft(realNow)
	if MineLaunch.isLaunched() then
		return nil
	end
	local period = math.max(1, math.floor(tonumber(MineLaunch.TEASER_PERIOD) or 86400))
	local t = math.floor(tonumber(realNow) or os.time())
	return period - (t % period)
end

--[[
	Stamp the launch. Returns the timestamp used, or nil if it was already
	launched -- re-launching would restart the season and wipe everyone's
	progress through it, so it is refused rather than made idempotent-looking.
]]
function MineLaunch.launch(realNow)
	if MineLaunch.isLaunched() then
		return nil, "already_launched"
	end
	local t = math.floor(tonumber(realNow) or os.time())
	if t <= 0 then
		return nil, "bad_clock"
	end
	MineLaunch.launchedAt = t
	return t
end

return MineLaunch
