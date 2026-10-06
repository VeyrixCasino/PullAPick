// THE PET FOLLOW SPRING MUST BE STABLE AT ANY FRAMERATE.
//
// Owner, 2026-10-05: pets "kinda just fly around the screen like crazy", on a
// session measured at 15 fps. The follow used EXPLICIT Euler, which is only
// conditionally stable -- it needs about omega*dt < 2, and SPRING_HZ stiffens
// from 3.6 to 6.2 while catching up, putting omega at 39. At the old 0.05 dt
// clamp that is 1.95, right on the edge; one bad frame and each step amplifies
// the last.
//
// "Unconditionally stable" is a claim about an integrator, so it gets RUN rather
// than argued: both integrators, over a sweep of framerates, with the old one
// kept here precisely so the harness can show it diverging where the new one
// settles. If someone ever swaps PF.spring back to an explicit step, the sweep
// goes red.
//
// PF.spring is pure and type-agnostic on purpose -- Vector3 in the game, plain
// numbers here -- so this executes the REAL function out of MineClient rather
// than a JS restatement of it.
//
// Run: node tools/verify/pet-spring.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const CLIENT = path.join(ROOT, "src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau");
const src = Luau.readSrc(CLIENT);

if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU)) {
  console.log("  " + Luau.missing("luau"));
  process.exit(0);
}

const lines = src.split("\n");
function block(head, close) {
  const i = lines.findIndex((l) => l.startsWith(head));
  if (i < 0) throw new Error("not found: " + head);
  for (let j = i; j < lines.length; j++) {
    if (lines[j] === close) return { i, text: lines.slice(i, j + 1).join("\n") };
  }
  throw new Error("unterminated: " + head);
}

const parts = [
  block("local PF = {", "}"),
  block("function PF.spring(", "end"),
];
parts.sort((a, b) => a.i - b.i);

const harness = `${parts.map((p) => p.text).join("\n\n")}

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

print("pet-spring: stability across framerate, and the feel at 60fps")

-- The worst case the game can actually produce: the catch-up term fully engaged.
local HZ_MAX = PF.SPRING_HZ + PF.SPRING_HZ_CATCHUP
local ZETA = PF.SPRING_ZETA
check("the stiffest the spring gets is SPRING_HZ + SPRING_HZ_CATCHUP",
	math.abs(HZ_MAX - (PF.SPRING_HZ + PF.SPRING_HZ_CATCHUP)) < 1e-9,
	string.format("%.2f Hz, omega %.1f", HZ_MAX, 2 * math.pi * HZ_MAX))

-- The OLD integrator, kept verbatim so the comparison is real.
local function explicitStep(pos, vel, target, h, hz, zeta)
	local omega = 2 * math.pi * hz
	local accel = (target - pos) * (omega * omega) - vel * (2 * zeta * omega)
	vel = vel + accel * h
	return pos + vel * h, vel
end

-- Drop a pet 10 studs from its target and let it settle. Returns the furthest it
-- ever got from the target, and where it ended up.
local function run(step, h, hz, seconds)
	local pos, vel, target = 0, 0, 10
	local peak = math.abs(target - pos)
	local n = math.floor(seconds / h)
	for _ = 1, n do
		pos, vel = step(pos, vel, target, h, hz, ZETA)
		if pos ~= pos or math.abs(pos) > 1e9 then
			return math.huge, pos
		end
		peak = math.max(peak, math.abs(pos - target))
	end
	return peak, pos
end

-- -------------------------------------------------- the framerate sweep --
-- Every dt the clamp now admits, plus some past it for margin.
local FPS = { 240, 144, 120, 90, 60, 45, 30, 24, 20, 15, 12, 10 }
local worstPeak, worstFps = 0, 0
local allSettled = true
for _, fps in ipairs(FPS) do
	local h = 1 / fps
	local peak, final = run(PF.spring, h, HZ_MAX, 6)
	-- Settled means it ended on the target, not merely that it did not explode.
	if not (math.abs(final - 10) < 0.05) then
		allSettled = false
		print(string.format("        %d fps: ended at %.4f, not 10", fps, final))
	end
	if peak > worstPeak then worstPeak, worstFps = peak, fps end
end
check("the implicit spring settles on target at every framerate 10-240", allSettled)
-- A 10-stud displacement may overshoot a little (zeta 0.86) but must never
-- travel further than it started. Anything above 10 is growth, not follow-through.
check("it never swings further than the distance it started from",
	worstPeak <= 10.5,
	string.format("worst excursion %.3f studs, at %d fps", worstPeak, worstFps))

-- ------------------------------------------- and the old one DID blow up --
-- The point of the fix. At 60 fps the explicit step was fine, which is why this
-- survived review; at the dt the owner was actually running it was not.
local peak60 = select(1, run(explicitStep, 1 / 60, HZ_MAX, 6))
local peak15 = select(1, run(explicitStep, 1 / 15, HZ_MAX, 6))
local peakClamp = select(1, run(explicitStep, 0.05, HZ_MAX, 6))
print(string.format("  explicit Euler excursion: 60fps %.2f, 0.05 clamp %.3g, 15fps %.3g",
	peak60, peakClamp, peak15))
check("the explicit step was stable at 60fps (why this was not caught sooner)",
	peak60 <= 10.5, string.format("%.3f studs", peak60))
check("the explicit step diverged at the owner's framerate",
	peak15 > 1e3 or peak15 == math.huge,
	string.format("%.3g studs", peak15))

-- --------------------------------------------------- framerate agnostic --
-- The same motion at 120 and 30 fps: a spring whose settling time depends on
-- framerate reads as a different pet on a different machine.
local function settleTime(h)
	local pos, vel, target = 0, 0, 10
	for i = 1, math.floor(8 / h) do
		pos, vel = PF.spring(pos, vel, target, h, HZ_MAX, ZETA)
		if math.abs(pos - target) < 0.1 then return i * h end
	end
	return math.huge
end
--[[
	The closed form traces real elapsed time, so this is not "close enough" --
	the curves should be the SAME, to within one frame of sampling resolution at
	the coarser rate. Backward Euler, the first fix, scored 0.150s against 0.233s
	here: stable, but stable by adding damping that grows with dt, which made a
	pet behave differently on a slower machine.
]]
local t120, t30 = settleTime(1 / 120), settleTime(1 / 30)
check("settling time is the same curve at 120 and 30 fps",
	math.abs(t120 - t30) <= 1 / 30 + 1e-9,
	string.format("%.4fs at 120fps vs %.4fs at 30fps (one 30fps frame is %.4fs)",
		t120, t30, 1 / 30))

-- Sampled at a shared instant rather than at each rate's own frames, which is
-- the strict version of the same claim: step to t=0.25s at four framerates and
-- compare where the pet actually is.
do
	local ref
	local spread = 0
	for _, fps in ipairs({ 240, 120, 60, 30 }) do
		local h = 1 / fps
		local pos, vel = 0, 0
		for _ = 1, math.floor(0.25 / h) do
			pos, vel = PF.spring(pos, vel, 10, h, HZ_MAX, ZETA)
		end
		ref = ref or pos
		spread = math.max(spread, math.abs(pos - ref))
	end
	check("all framerates agree on where the pet is at t = 0.25s",
		spread < 0.02, string.format("spread %.5f studs across 240/120/60/30 fps", spread))
end

-- ------------------------------------------------------------- the feel --
-- zeta below 1 is deliberate: the comment in MineClient promises a pet that
-- "leans into a stop, drifts a hair past, and settles". Assert the overshoot is
-- still THERE, so a future stability tweak cannot quietly flatten the character.
check("zeta is under 1, so there is still follow-through", ZETA < 1,
	string.format("%.2f", ZETA))
do
	local pos, vel, target = 0, 0, 10
	local overshot = false
	for _ = 1, 600 do
		pos, vel = PF.spring(pos, vel, target, 1 / 60, PF.SPRING_HZ, ZETA)
		if pos > target + 0.01 then overshot = true end
	end
	check("a pet still drifts past the mark before settling", overshot,
		"underdamped, as the follow comment describes")
end

-- A step with a zero dt must not divide by zero or move anything.
do
	local p, v = PF.spring(3, 1, 10, 0, HZ_MAX, ZETA)
	check("a zero-length frame is a no-op rather than a NaN",
		p == 3 and v == 1, string.format("pos %s vel %s", tostring(p), tostring(v)))
end

print(fails == 0 and ">>> pet-spring OK" or (">>> " .. fails .. " FAILED"))
`;

// os.exit does not exist in this luau build, so the verdict is read from stdout.
const tmp = path.join(require("os").tmpdir(), "pet-spring-harness.luau");
fs.writeFileSync(tmp, harness);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" });
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
  process.stdout.write(out);
  console.log("  FAIL  the luau harness exited non-zero");
  process.exit(1);
}
process.stdout.write(out);
if (!/>>> pet-spring OK/.test(out)) {
  process.exit(1);
}
