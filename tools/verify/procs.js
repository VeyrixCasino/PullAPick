// Proc DAMAGE and proc CHANCE are two different stats.
//
// Owner, 2026-10-03: "almost no effect should do full pickaxe damage" and
// "Just make damage and chance 2 different stats."
//
// Every proc used to hand its neighbour `dmg` -- the whole swing -- so one stat
// bought both how often it fired and how hard. This asserts the split holds:
// the shares are real fractions, procPower is the only thing that moves them,
// zap's chain actually terminates, and no caller passes a raw swing any more.
//
//   node tools/verify/procs.js
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = path.resolve(__dirname, "../..");
const Luau = require("./_luau");
const LUAU = Luau.LUAU;
const read = (p) => Luau.readSrc(path.join(ROOT, p));
if (!Luau.ready) {
  // Names the platform and the fix, instead of "skipping" with no reason --
  // and exits 1, because a check that cannot run is not a check that passed.
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(1);
}

const cfg = read("src/ReplicatedStorage/Mine/Shared/MineConfig.luau");
const server = read("src/ServerScriptService/Mine/MineServer.server.luau");
const cards = read("src/ReplicatedStorage/Mine/Shared/MineCards.luau");
const stats = read("src/ReplicatedStorage/Mine/Shared/MineStats.luau");
const gear = read("src/ReplicatedStorage/Mine/Shared/MineGear.luau");
const runes = read("src/ReplicatedStorage/Mine/Shared/MineRunes.luau");

const grab = (re, what) => {
  const m = cfg.match(re);
  if (!m) { console.error(`FAIL could not find ${what} in MineConfig`); process.exit(1); }
  return m[0];
};
const share = grab(/MineConfig\.PROC_SHARE = \{[\s\S]*?\n\}/, "PROC_SHARE");
const fn = grab(/function MineConfig\.procDamage\(dmg, which, procPower\)[\s\S]*?\nend\n/, "procDamage");
const num = (k) => Number((cfg.match(new RegExp(`MineConfig\\.${k}\\s*=\\s*([\\d.]+)`)) || [])[1]);

const harness = `
local MineConfig = { PROC_POWER_CAP = ${num("PROC_POWER_CAP")} }
${share.replace("MineConfig.PROC_SHARE", "MineConfig.PROC_SHARE")}
${fn}

local fail = 0
local function check(ok, msg)
	if not ok then fail += 1 print("  FAIL  " .. msg) else print("  ok    " .. msg) end
end

local S = MineConfig.PROC_SHARE
for _, k in ipairs({ "blast", "zap", "ricochet", "quake" }) do
	check(type(S[k]) == "number" and S[k] > 0, k .. " has a share (" .. tostring(S[k]) .. ")")
	-- The ask, in one assertion: no single proc hit is a whole swing.
	check(S[k] < 1, k .. " is worth less than a full swing per hit")
end

-- Blast is the one that multiplies: 6 faces. Keep the BURST under control too.
check(S.blast * 6 <= 2.5,
	("blast burst stays bounded: %.2f x 6 = %.2f swings"):format(S.blast, S.blast * 6))
-- A full quake life, against a swing.
local sec = ${num("EARTHQUAKE_SEC")}
check(S.quake * sec < 1,
	("a whole quake is under one swing: %.2f x %d = %.2f"):format(S.quake, sec, S.quake * sec))

-- Zap's chain terminates, and its total is bounded even if every hop lands.
local hops, fall = ${num("ZAP_MAX_HOPS")}, ${num("ZAP_FALLOFF")}
check(hops <= 8, "zap is capped at " .. hops .. " hops (was 32)")
check(fall < 0.85, "zap falls off " .. fall .. "x a hop, steeply enough to matter")
local total = 0
for h = 1, hops do total += S.zap * (fall ^ (h - 1)) end
check(total < 2.0, ("a whole zap chain is %.2f swings, even if every hop lands"):format(total))

-- procDamage is the only thing that moves proc damage.
check(MineConfig.procDamage(1000, "blast", 0) == math.floor(1000 * S.blast),
	"procDamage with no procPower is just the share")
check(MineConfig.procDamage(1000, "blast", 1) > MineConfig.procDamage(1000, "blast", 0),
	"procPower raises it")
check(MineConfig.procDamage(1000, "blast", 99) == MineConfig.procDamage(1000, "blast", MineConfig.PROC_POWER_CAP),
	"...and clamps at PROC_POWER_CAP (" .. MineConfig.PROC_POWER_CAP .. ")")
check(MineConfig.procDamage(1000, "blast", -5) == MineConfig.procDamage(1000, "blast", 0),
	"...and a negative procPower cannot reduce it below the share")
check(MineConfig.procDamage(1, "quake", 0) >= 1, "never rounds a proc down to zero damage")
check(MineConfig.procDamage(1000, "nonsense", 0) == 0,
	"an unknown proc gets nothing rather than a default swing")

if fail > 0 then
	print("")
	print(">>> procs: " .. fail .. " FAILED assertion(s)")
else
	print("")
	print(">>> procs: all assertions passed")
end
`;

const script = path.join(ROOT, ".luau-bin/procs-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try { out = execFileSync(LUAU, [script], { encoding: "utf8" }); process.stdout.write(out); }
catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
  process.stdout.write(e.stdout || ""); process.stderr.write(e.stderr || "");
  process.exit(1);
}

let fail = /FAILED|FAIL /.test(out) ? 1 : 0;
const src = (ok, msg) => { console.log((ok ? "  ok    " : "  FAIL  ") + msg); if (!ok) fail++; };
const code = (lua) => lua.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");

const procs = code((server.match(/function Dig\.procsAt[\s\S]*?\n^end$/m) || [""])[0]);
src(procs.length > 400, "found Dig.procsAt");
for (const which of ["blast", "ricochet", "quake", "zap"]) {
  src(new RegExp(`procDamage\\(dmg, "${which}"`).test(procs),
    `${which} goes through C.procDamage`);
}
// The bug being locked out: handing a proc the player's whole swing.
src(!/swingNeighbour, plr, other, dmg, p/.test(procs) && !/swingNeighbour, plr, hit, dmg, p/.test(procs),
  "no proc passes the raw swing damage any more");
src(!/\^ hops\)\)/.test(procs) || /falloff \^/.test(procs),
  "zap's falloff comes from C.ZAP_FALLOFF, not a literal");
src(!/for hops = 1, 32 do/.test(procs), "zap's 32-hop chain is gone");
// The quake tick must not re-apply a share on top of a pre-scaled figure.
src(!/EARTHQUAKE_TICK_SHARE/.test(code(server)),
  "the quake tick no longer multiplies by its own share (double-scaling)");

src(/procPower = 0,/.test(cards), "procPower starts at 0 in emptyBoosts");
src(/procPower = true/.test(cards), "...and is additive");
src(/procPower\s*= \{ label = "Proc Power"/.test(stats), "procPower is a real stat");
src(/"earthquake", "ricochet", "procPower",/.test(stats), "...and is in STAT_ORDER");
src(/procPower = 0\.\d+,/.test(gear), "gear can roll procPower");
src((runes.match(/"procPower"/g) || []).length >= 3, "runes can roll procPower on 3+ families");
src(/drill = \{[^}]*"procPower"/.test(runes), "...drills among them (the drill-friendly ask)");

console.log("");
console.log(fail > 0 ? `>>> procs: ${fail} FAILED` : ">>> procs: all assertions passed");
process.exit(fail > 0 ? 1 : 0);
