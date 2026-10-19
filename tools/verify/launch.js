// THE SEASON DOES NOT START UNTIL THE OWNER SAYS SO.
//
// Owner, 2026-10-07: "i want the timer to not actually start until i say launch,
// and rather just keep ticking down".
//
// Two halves that sound contradictory, so both are pinned here: nothing in the
// season may advance before launch, and the visible countdown must still move.
//
// The failure this exists to catch is silent and total. The season is currently
// two absolute dates (2026-09-22 to 2026-11-01), so it is already running with
// nobody playing -- week one is gone, the pass is counting down, and no error is
// raised anywhere. If seasonNow() ever reverts to os.time(), that comes straight
// back and looks like nothing at all.
//
// Run: node tools/verify/launch.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const SRC = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineLaunch.luau");
const LAUNCH = Luau.readSrc(SRC);
const OFFERS = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineRotatingOffers.luau"));
const SCROLLS = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineScrolls.luau"));

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

console.log("launch: the season is a duration, and it starts when the owner says");

// The three season starts must agree, or seasonNow() shifts the clock onto a
// different origin than the offers and the pass measure from -- which would put
// the season weeks out without failing anything.
const gl = (src, key) => {
  const m = new RegExp(key + "\\s*=\\s*(\\d{9,})").exec(src);
  return m ? m[1] : null;
};
const lStart = gl(LAUNCH, "MineLaunch\\.SEASON_START");
const oStart = gl(OFFERS, "local START");
const pStart = gl(SCROLLS, "MineScrolls\\.PASS_SEASON_START");
ok(lStart && oStart && lStart === oStart,
  "MineLaunch.SEASON_START matches MineRotatingOffers' START",
  `${lStart} vs ${oStart}`);
ok(lStart && pStart && lStart === pStart,
  "...and matches MineScrolls.PASS_SEASON_START",
  `${lStart} vs ${pStart}`);

// A date would launch the game while nobody is watching. That is the failure
// mode the whole module exists for.
ok(/MineLaunch\.launchedAt = 0/.test(LAUNCH),
  "the game ships NOT launched");
ok(!/MineLaunch\.launchedAt = \d{9,}/.test(LAUNCH),
  "launch is a flag stamped by the owner, never a hard-coded date");

//[[ ------------------------------------------------------- the wiring ----
// The module is only worth anything if the season systems actually read it.
// Both default their `now` rather than relying on call sites to pass one --
// there are client panels among those callers, and one that still read
// os.time() would show a different season than the server was running.
ok(/now = now or Launch\.seasonNow\(\)/.test(OFFERS),
  "MineRotatingOffers defaults its clock to the season clock");
ok(!/now = now or os\.time\(\)/.test(OFFERS),
  "...and no offer path still reads the wall clock");
ok(/Launch\.seasonNow\(\)/.test(SCROLLS),
  "MineScrolls reads the season clock for the battle pass");
ok(!/\(now or os\.time\(\)\)/.test(SCROLLS),
  "...and the pass countdown no longer reads the wall clock");

{
  const SRV = Luau.readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineServer.server.luau"));
  ok(/Launch = require\(shared:WaitForChild\("MineLaunch"\)\)/.test(SRV),
    "the server holds the launch module");
  ok(/function Verbs\._loadLaunch\(\)/.test(SRV) && /pcall\(Verbs\._loadLaunch\)/.test(SRV),
    "the flag is loaded at boot");
  const load = SRV.slice(SRV.indexOf("function Verbs._loadLaunch()"), SRV.indexOf("function Verbs.launchSeason("));
  // A failed datastore read must not start the season. This is the one that
  // would be invisible: the game would simply be live one morning.
  ok(/Dig\.Launch\.launchedAt = 0/.test(load),
    "a failed or empty read leaves the game UNLAUNCHED",
    "the safe direction -- a datastore blip must never start the season");
  const verb = SRV.slice(SRV.indexOf("function Verbs.launchSeason("), SRV.indexOf("\tBUY A CASE FROM A WANDERING TRADER"));
  ok(/Allow\.isAdmin/.test(verb), "launching is admin-gated");
  ok(/store:SetAsync\("launch_v1"/.test(verb), "the launch is persisted");
  // Persist before announcing, or a restart silently rewinds the season.
  const saveAt = verb.indexOf("SetAsync"), sayAt = verb.indexOf("Season launched.");
  ok(saveAt > -1 && sayAt > saveAt,
    "it saves before it announces",
    "announcing an unsaved launch would rewind on the next restart");
  ok(/Dig\.Launch\.launchedAt = 0\s*\n\s*net:FireClient\(plr, "toast", "Launch FAILED/.test(verb),
    "a failed save rolls the flag back rather than leaving it half-launched");
  ok(/elseif action == "launchSeason" then Verbs\.launchSeason\(plr\)/.test(SRV),
    "launchSeason is reachable from the dispatch");
}

if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU)) {
  console.log("  " + Luau.missing("luau"));
  console.log(fails === 0 ? ">>> launch OK (static only)" : `>>> ${fails} FAILED`);
  process.exit(fails === 0 ? 0 : 1);
}

const harness = `${LAUNCH.replace(/^return MineLaunch$/m, "")}

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

local S = MineLaunch.SEASON_START
-- A real-looking wall clock well past the hard-coded season dates, which is the
-- situation the game is actually in: the calendar says the season ended.
local LATE = S + 86400 * 120

-- ------------------------------------------- nothing moves before launch --
MineLaunch.launchedAt = 0
check("not launched by default", MineLaunch.isLaunched() == false)
check("the season clock sits at second zero", MineLaunch.seasonNow(LATE) == S,
	string.format("%d vs %d", MineLaunch.seasonNow(LATE), S))
check("no time has elapsed in the season", MineLaunch.elapsed(LATE) == 0)
--[[
	THE ONE THAT MATTERS. Real time passing must not move the season on. If this
	fails, the game launches itself on a calendar date with nobody watching --
	which is exactly what it does today.
]]
do
	local a = MineLaunch.seasonNow(LATE)
	local b = MineLaunch.seasonNow(LATE + 86400 * 30)
	check("a month of real time does not advance the season", a == b,
		string.format("%d then %d", a, b))
end

-- ------------------------------------- but the visible countdown is alive --
do
	local t = S + 1000
	local a = MineLaunch.teaserLeft(t)
	local b = MineLaunch.teaserLeft(t + 1)
	local c = MineLaunch.teaserLeft(t + 2)
	check("the teaser countdown ticks DOWN second by second",
		b == a - 1 and c == a - 2, string.format("%d, %d, %d", a, b, c))
	local inRange = true
	for k = 0, 200000, 97 do
		local v = MineLaunch.teaserLeft(S + k)
		if v < 1 or v > MineLaunch.TEASER_PERIOD then inRange = false end
	end
	check("it never hits zero and never goes negative -- it rolls over", inRange)
end

-- ------------------------------------------------- launching starts it --
do
	MineLaunch.launchedAt = 0
	local at, why = MineLaunch.launch(LATE)
	check("launch stamps the moment it was thrown", at == LATE, tostring(at) .. " " .. tostring(why))
	check("it reads as launched", MineLaunch.isLaunched())
	check("the season begins at its start, not partway through",
		MineLaunch.seasonNow(LATE) == S,
		"a player joining at launch must see week one")
	check("one hour later the season is one hour old",
		MineLaunch.elapsed(LATE + 3600) == 3600)
	check("thirty days later the season is thirty days old",
		MineLaunch.elapsed(LATE + 86400 * 30) == 86400 * 30)
	check("the teaser countdown stops once launched", MineLaunch.teaserLeft(LATE) == nil,
		"two countdowns side by side would be a lie")
end

-- Delay must be free: a season launched late is still a whole season.
do
	MineLaunch.launchedAt = 0
	MineLaunch.launch(LATE)
	local a = MineLaunch.elapsed(LATE + 86400 * 7)
	MineLaunch.launchedAt = 0
	MineLaunch.launch(LATE + 86400 * 365)
	local b = MineLaunch.elapsed(LATE + 86400 * 365 + 86400 * 7)
	check("launching a year later still gives the same first week", a == b,
		string.format("%d vs %d seconds in", a, b))
end

-- --------------------------------------------------------- the guards --
do
	MineLaunch.launchedAt = 0
	MineLaunch.launch(LATE)
	local again, why = MineLaunch.launch(LATE + 60)
	check("launching twice is refused", again == nil and why == "already_launched",
		"a second launch would restart the season under everyone")
end
do
	MineLaunch.launchedAt = 0
	local bad, why = MineLaunch.launch(0)
	check("a zero clock cannot launch", bad == nil and why == "bad_clock")
end
do
	-- A server with a bad clock, or a launch stamped in the future.
	MineLaunch.launchedAt = LATE + 86400
	check("a backwards clock never rewinds the season before its start",
		MineLaunch.seasonNow(LATE) == S,
		"rewinding would resurrect offers that already expired")
end

print(fails == 0 and ">>> launch OK" or (">>> " .. fails .. " FAILED"))
`;

const tmp = path.join(require("os").tmpdir(), "launch-harness.luau");
fs.writeFileSync(tmp, harness);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" });
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
}
process.stdout.write(out);
if (!/>>> launch OK/.test(out)) fails++;

console.log(fails === 0 ? ">>> launch OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
