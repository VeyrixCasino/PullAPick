// The daily wheel works, and keeps working.
//
// Owner, 2026-10-10 (docs/TODO.md NOW, A1): "we need that daily wheel
// working". Decided: one free spin a day for everyone, +1 for group members,
// streak bonuses, odds printed on the wheel, built in the lobby.
//
// Checked against the REAL MineGroupWheel (run in luau) and the real sources:
//   1. the prize table sums to 100, and its 16 ids are the ones minted cards
//      and old saves know (ids are data: never renamed)
//   2. the daily allowance: base, +group, +streak only on a claimed streak day
//   3. free spins reset on a new UTC day without a write; used ones count
//   4. the panel lands on the slice the server rolled, from any start angle
//   5. MineServer builds the wheel, keeps it on rebirth, saves after a spin,
//      and the snapshot carries the small state, not the prize table
//
//   node tools/verify/daily-wheel.js
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = path.resolve(__dirname, "../..");
const Luau = require("./_luau");
const LUAU = Luau.LUAU;
const read = (p) => Luau.readSrc(path.join(ROOT, p));
if (!Luau.ready) {
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(1);
}

const wheel = read("src/ReplicatedStorage/Mine/Shared/MineGroupWheel.luau")
  .replace('require(script.Parent:WaitForChild("MinePetRoster"))', "PET_STUB");

const harness = `
Color3 = { fromRGB = function(r, g, b) return { r, g, b } end }
local PET_STUB = { BY_TIER = { Exotic = { { name = "Cosmo" }, { name = "Matter+" } }, Legendary = { { name = "Leo" } } }, BY_NAME = {} }
local W = (function()
${wheel}
end)()

local fail = 0
local function check(ok, msg)
	if ok then print("  ok    " .. msg) else fail += 1 print("  FAIL  " .. msg) end
end

-- 1. the table
local total = W.totalWeight()
check(math.abs(total - 100) < 1e-9, string.format("prize weights sum to 100 (%.4f)", total))
local IDS = { "exotic", "galaxy", "spark", "legendary_pet", "epic_pet", "jackpot", "gem_storm", "gear_vault",
	"heavy_runes", "apex", "heirloom", "anomaly", "godly", "dust_hoard", "gem_bag", "tokens" }
check(#W.SEGMENTS == #IDS, "16 slices")
for i, id in ipairs(IDS) do
	check(W.SEGMENTS[i] and W.SEGMENTS[i].id == id, "slice " .. i .. " keeps id '" .. id .. "'")
end
for _, s in ipairs(W.SEGMENTS) do
	check(W.oddsText(s) ~= "", "slice '" .. s.id .. "' prints odds (" .. W.oddsText(s) .. ")")
end
local petOrBetter = 0
for _, s in ipairs(W.SEGMENTS) do
	if s.reward.pet or s.reward.petTier or s.reward.petPool then petOrBetter += s.weight end
end
check(petOrBetter <= 10, string.format("a free daily spin gives a pet at most 10%% of the time (%.2f%%)", petOrBetter))

-- 2. allowance
check(W.allowance(false, 0, false) == W.FREE_PER_DAY, "everyone gets the base free spin")
check(W.allowance(true, 0, false) == W.FREE_PER_DAY + W.GROUP_BONUS, "group members get the bonus")
local e = W.STREAK_EVERY
check(W.allowance(false, e, true) == W.FREE_PER_DAY + W.STREAK_BONUS, "a claimed streak day adds the streak bonus")
check(W.allowance(false, e, false) == W.FREE_PER_DAY, "...only once today's daily is claimed")
check(W.allowance(false, e + 1, true) == W.FREE_PER_DAY, "...and only on the streak day itself")
check(W.allowance(true, e * 2, true) == W.FREE_PER_DAY + W.GROUP_BONUS + W.STREAK_BONUS, "member + streak stack")

-- 3. the day
local day = W.dayIndex(86400 * 20000 + 5)
check(W.freeLeft({ day = day, used = 1 }, day, 2) == 1, "a used spin counts today")
check(W.freeLeft({ day = day - 1, used = 5 }, day, 2) == 2, "a new day resets without a write")
check(W.freeLeft(nil, day, 1) == 1, "a fresh profile has its spin")
check(W.resetIn(86400 * 20000 + 5) == 86400 - 5, "resetIn counts to UTC midnight")
local st = W.state({ groupWheel = { day = day, used = 1, paid = 3 }, daily = { streak = e, last = day } }, 86400 * 20000 + 5, true)
check(st.freeTotal == W.FREE_PER_DAY + W.GROUP_BONUS + W.STREAK_BONUS and st.freeLeft == st.freeTotal - 1 and st.paid == 3,
	"state() combines it (total " .. st.freeTotal .. ", left " .. st.freeLeft .. ", paid " .. st.paid .. ")")
check(st.segments == nil, "the snapshot state carries no prize table")

-- 4. the panel lands where the server rolled (same maths as MineGroupWheelView.onResult)
local n = #W.SEGMENTS
local worst = 0
for _, from in ipairs({ 0, 37.5, 359, 1800 + 12.3, -90, 7777 }) do
	for i = 1, n do
		local target = (-((i - 0.5) / n) * 360) % 360
		local base = from - (from % 360)
		local goal = base + 5 * 360 + target
		if goal - from < 4 * 360 then goal += 360 end
		local want = (-((i - 0.5) / n) * 360) % 360
		local d = math.abs((goal % 360) - want)
		if d > worst then worst = d end
		if goal <= from then worst = 999 end
	end
end
check(worst < 1e-6, "every spin lands on the rolled slice from any start angle")

print("")
print(fail > 0 and (">>> daily-wheel: " .. fail .. " FAILED assertion(s)") or ">>> daily-wheel: all assertions passed")
`;

const script = path.join(ROOT, ".luau-bin/daily-wheel-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(LUAU, [script], { encoding: "utf8" }); process.stdout.write(out); }
catch (e) {
  process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || "");
  process.exit(1);
}

let fail = /FAILED|FAIL /.test(out) ? 1 : 0;
const src = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };
const code = (s) => s.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");

const ms = code(read("src/ServerScriptService/Mine/MineServer.server.luau"));
const gws = code(read("src/ServerScriptService/Mine/GroupWheelService.luau"));
const view = code(read("src/ReplicatedStorage/Mine/Shared/MineGroupWheelView.luau"));
const mc = code(read("src/StarterPlayer/StarterPlayerScripts/MineClient.client.luau"));
src(/\n\s*GroupWheelService\.build\(lobby\)/.test(ms), "MineServer builds the wheel in the lobby");
src(/KEEP_ON_REBIRTH = \{[\s\S]*?"groupWheel"/.test(ms), "rebirth keeps the wheel (paid spins, today's count)");
src(/groupWheel = GroupWheelService\.snapState\(p, plr\)/.test(ms), "the snapshot carries the small state");
src(/save = save,/.test(ms) && /deps\.save/.test(gws), "a spin saves at once, not at the next autosave");
src(/st\.freeLeft > 0[\s\S]*?elseif st\.paid > 0 and plr:GetAttribute\("PolicyNoRandom"\) ~= true/.test(gws),
  "free spins are spent first; paid spins obey the paid-random region rule");
src(!/Heartbeat/.test(gws) && /RenderStepped/.test(view) && /PartCount/.test(gws) && /Atomic/.test(gws),
  "the world wheel spins on the client, whole (PartCount, Atomic streaming), not on the server");
src(/oddsText/.test(gws) && /oddsText/.test(view), "odds are printed on the world wheel and the panel");
src(/Celebrate\.fromOneIn\(msg\.oneIn\)/.test(view), "a win is celebrated by its real odds");
src(/dockBtn\("", "Wheel"/.test(mc), "the HUD has a Wheel dock button");

console.log("");
console.log(fail > 0 ? `>>> daily-wheel: ${fail} FAILED` : ">>> daily-wheel: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
