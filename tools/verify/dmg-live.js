// EXECUTE the real toolTierPower, in the real declaration order.
//
// Every other damage check in this repo reimplements the formula in JS by
// parsing constants out of the Luau. That is how the numbers were chosen and it
// cannot catch the one thing that could actually break here:
//
//   toolTierPower is declared at line ~2665 and now calls MineConfig.ORE_COUNT
//   (~3175) and MineConfig.oreBandForTier (~3193) -- both about five hundred
//   lines FURTHER DOWN the same file. At runtime that is fine, because nothing
//   calls toolTierPower during module load. "Fine by load order" is a claim
//   about execution, so it gets executed instead of argued.
//
// The harness keeps the slices IN FILE ORDER, so if someone later moves a call
// above its definition this check goes red rather than the game going nil.
//
// Run: node tools/verify/dmg-live.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const CFG = path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau");
const src = Luau.readSrc(CFG);

if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU)) {
  console.log("  luau binary not runnable on this platform; skipping");
  process.exit(0);
}

const lines = src.split("\n");

// Take a block starting at the line that matches `head`, ending at the first
// line that is exactly the closing token at column 0.
function block(head, close) {
  const i = lines.findIndex((l) => l.startsWith(head));
  if (i < 0) throw new Error("not found: " + head);
  for (let j = i; j < lines.length; j++) {
    if (lines[j] === close) return { i, text: lines.slice(i, j + 1).join("\n") };
  }
  throw new Error("unterminated: " + head);
}
function line(head) {
  const i = lines.findIndex((l) => l.startsWith(head));
  if (i < 0) throw new Error("not found: " + head);
  return { i, text: lines[i] };
}

const parts = [
  block("MineConfig.ORE_YIELD_BANDS = {", "}"),
  line("MineConfig.TOOL_MAX_LEVEL ="),
  line("MineConfig.TOOL_CLIMB_DAMAGE ="),
  block("local function perLevel(", "end"),
  line("MineConfig.TOOL_TIER_SPAN ="),
  line("MineConfig.TOOL_DMG_BASE ="),
  block("MineConfig.TOOL_BAND_DMG = {", "}"),
  line("MineConfig.TOOL_DMG_STEP ="),
  block("local function clampLevel(", "end"),
  block("local function clampTier(", "end"),
  block("function MineConfig.toolTierPower(", "end"),
  block("function MineConfig.toolPower(", "end"),
  line("MineConfig.ORE_COUNT ="),
  line("MineConfig.ORE_BAND_ORDER ="),
  block("function MineConfig.oreBandForTier(", "end"),
];
// FILE ORDER. This is the whole point of the check.
parts.sort((a, b) => a.i - b.i);

const harness = `local MineConfig = {}
-- ORES is stubbed to its real length: ORE_COUNT and clampTier only read #ORES.
MineConfig.ORES = table.create(82, { tier = 1 })

${parts.map((p) => p.text).join("\n\n")}

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

print("toolTierPower, executed in file order")

local okCall, p = pcall(MineConfig.toolTierPower, 82)
check("toolTierPower(82) does not error", okCall,
	okCall and string.format("%.6g", p) or tostring(p))
if not okCall then os.exit(1) end

local n = MineConfig.ORE_COUNT
local topBand = MineConfig.ORE_BAND_ORDER[#MineConfig.ORE_BAND_ORDER]
local want = (6 ^ MineConfig.TOOL_TIER_SPAN) * MineConfig.TOOL_BAND_DMG[topBand]
check("tier " .. n .. " = 6^TOOL_TIER_SPAN x the top band step (no /120 left)",
	math.abs(p - want) / want < 1e-9, string.format("%.6g vs %.6g", p, want))

check("tier 1 is exactly the 1x baseline",
	math.abs(MineConfig.toolTierPower(1) - 1) < 1e-12,
	string.format("%.12g", MineConfig.toolTierPower(1)))

-- The band step must be a visible jump at the Epic -> Legendary border.
local epicTop
for i, b in ipairs(MineConfig.ORE_YIELD_BANDS) do
	if MineConfig.ORE_BAND_ORDER[i] == "Epic" then epicTop = b.upTo end
end
local smooth = 6 ^ (MineConfig.TOOL_TIER_SPAN / (n - 1))
local real = MineConfig.toolTierPower(epicTop + 1) / MineConfig.toolTierPower(epicTop)
check("crossing into Legendary jumps more than one smooth tier step",
	real > smooth * 1.5,
	string.format("x%.3f at tier %d->%d vs x%.3f per tier", real, epicTop, epicTop + 1, smooth))

local prev, mono = 0, true
for t = 1, n do
	local v = MineConfig.toolTierPower(t)
	if v < prev then mono = false end
	prev = v
end
check("damage never decreases with tier", mono)

-- toolPower must thread level and typeMult through unchanged.
local full = MineConfig.toolPower(82, MineConfig.TOOL_MAX_LEVEL, 4)
   / MineConfig.toolPower(82, 1, 1)
check("a full climb x the Frack multiplier is TOOL_CLIMB_DAMAGE x 4",
	math.abs(full - MineConfig.TOOL_CLIMB_DAMAGE * 4) / (MineConfig.TOOL_CLIMB_DAMAGE * 4) < 1e-6,
	string.format("x%.6g", full))
print(string.format("  tier 82 Frack at max level: %.6g",
	MineConfig.toolPower(82, MineConfig.TOOL_MAX_LEVEL, 4)))

if fails == 0 then
	print(">>> toolTierPower runs, and the band lookup resolves from where it is called")
else
	print(">>> " .. fails .. " FAILED")
	os.exit(1)
end
`;

const out = path.join(ROOT, ".luau-bin/dmg-live-check.luau");
fs.writeFileSync(out, harness);
try {
  process.stdout.write(execFileSync(Luau.LUAU, [out], { encoding: "utf8" }));
} catch (e) {
  process.stdout.write((e.stdout || "") + (e.stderr || ""));
  console.log("  FAIL  the luau harness exited non-zero");
  process.exit(1);
}
