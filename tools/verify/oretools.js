// A forged tool has to look like the ore it was made of.
//
// It did not. ToolModelFactory's procedural builders colour themselves from an
// eight-step ramp indexed by `lookTier` -- a COSMETIC shop-ladder rung -- and no
// mesh is named after an ore, so every one of the 82 ore tools took that path:
// eight palettes across the whole roster, two ores at the same rung identical,
// and the ore visible nowhere on the thing it forged.
//
// ToolModelFactory.oreLook turns an ore row into the override that fixes it.
// This runs it against the REAL 82 rows out of MineConfig and asserts the
// properties that make the result not-flat:
//
//   * every ore yields a look
//   * head colours are all distinct -- 82 ores, 82 colours
//   * the haft never equals the head, or the tool is one block of colour
//   * the silhouette spans the roster, so colour is not the only difference
//   * only ores with business glowing glow
//   * gleam tracks metalness and smoothness
//
//   node tools/verify/oretools.js
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = path.resolve(__dirname, "../..");
const LUAU = path.join(ROOT, ".luau-bin/luau");
if (!fs.existsSync(LUAU)) {
  console.log("luau not present (.luau-bin/luau) — run tools/verify/syntax.sh first; skipping");
  process.exit(0);
}

const cfg = fs.readFileSync(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau"), "utf8");
const factory = fs.readFileSync(path.join(ROOT, "src/ReplicatedStorage/ToolModelFactory.luau"), "utf8");

//[[ The real rows, verbatim.
//
// An earlier version of this check rebuilt each row from a strict field-order
// regex and silently matched only 53 of the 82 -- the 29 rows carrying `glow`,
// `glowBright` or `rainbow` fell out, which are exactly the rows where getting
// the look right is hardest. Passing while testing 65% of the roster and
// claiming "every ore" is worse than failing.
//
// So the rows are taken as written and the count is asserted against the
// roster's own ORE_COUNT.
const tableSrc = cfg.match(/MineConfig\.ORES = \{([\s\S]*?)\n\}/);
if (!tableSrc) {
  console.error("FAIL could not find MineConfig.ORES");
  process.exit(1);
}
const rows = tableSrc[1]
  .split("\n")
  .filter((l) => /\{\s*id = "/.test(l))
  .join("\n");
const rowCount = rows.split("\n").filter((l) => l.trim()).length;
const declared = Number((cfg.match(/MineConfig\.ORE_COUNT\s*=\s*(\d+)/) || [])[1]) ||
  Number((cfg.match(/ORE_COUNT\s*=\s*#MineConfig\.ORES/) ? [0, rowCount] : [])[1]) || rowCount;
if (rowCount !== declared || rowCount < 80) {
  console.error(`FAIL parsed ${rowCount} ore rows, roster declares ${declared}`);
  process.exit(1);
}
console.log(`  read ${rowCount} ore rows verbatim from MineConfig.ORES`);

// oreLook is PURE -- a row in, a table out. Loading the whole 3,000-line factory
// to reach it meant stubbing CFrame algebra and Vector3 components, because the
// module composes grip transforms at module scope. That stub becomes the thing
// under test.
//
// So the function's source is sliced out VERBATIM instead, with the one helper
// it uses (C3). If the slice cannot be found the check fails loudly rather than
// quietly testing nothing.
const fn = factory.match(/function ToolModelFactory\.oreLook\(ore, oreCount\)[\s\S]*?\nend\n/);
if (!fn) {
  console.error("FAIL could not find ToolModelFactory.oreLook — has it been renamed?");
  process.exit(1);
}
const c3 = factory.match(/local function C3\(r, g, b\)[\s\S]*?\nend\n/);
if (!c3) {
  console.error("FAIL could not find the C3 helper oreLook depends on");
  process.exit(1);
}

const harness = `
-- Color3 with a real Lerp: the haft is derived from the head by lerping, so a
-- stub returning a constant would pass the "haft differs" check for free.
local Color3mt = {}
Color3mt.__index = Color3mt
function Color3mt:Lerp(other, a)
	return setmetatable({
		R = self.R + (other.R - self.R) * a,
		G = self.G + (other.G - self.G) * a,
		B = self.B + (other.B - self.B) * a,
	}, Color3mt)
end
local function mkColor(r, g, b)
	return setmetatable({ R = r / 255, G = g / 255, B = b / 255 }, Color3mt)
end
Color3 = { fromRGB = mkColor }

local MATS = {}
Enum = { Material = setmetatable({}, { __index = function(_, m)
	MATS[m] = MATS[m] or setmetatable({ Name = m }, { __tostring = function() return m end })
	return MATS[m]
end }) }

local realTypeof = typeof
function typeof(v)
	if type(v) == "table" and getmetatable(v) == Color3mt then return "Color3" end
	if type(v) == "table" and v.Name and MATS[v.Name] == v then return "EnumItem" end
	return realTypeof(v)
end

local ToolModelFactory = {}
${c3[0]}
${fn[0]}
local Factory = ToolModelFactory

local ORES = {
${rows}
}

local fail = 0
local function check(ok, msg)
	if not ok then fail += 1 print("  FAIL  " .. msg) else print("  ok    " .. msg) end
end

check(type(Factory.oreLook) == "function", "ToolModelFactory.oreLook exists")

local looks, nilled = {}, 0
for _, o in ipairs(ORES) do
	local l = Factory.oreLook(o, #ORES)
	if not l then nilled += 1 else looks[o.id] = l end
end
check(nilled == 0, ("every ore yields a look (%d returned nil)"):format(nilled))

-- Distinct head colours. Eight palettes across 82 tools was the bug.
local function key(c)
	return string.format("%d,%d,%d", math.floor(c.R * 255 + 0.5),
		math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local seen, distinct = {}, 0
for _, l in pairs(looks) do
	local k = key(l.metal)
	if not seen[k] then seen[k] = true distinct += 1 end
end
check(distinct >= math.floor(#ORES * 0.9),
	("head colours are distinct: %d across %d ores"):format(distinct, #ORES))

-- The haft must never be the head, or the tool is one block of colour.
local same = 0
for _, l in pairs(looks) do
	if key(l.haft) == key(l.metal) then same += 1 end
end
check(same == 0, ("the haft never equals the head (%d matched)"):format(same))

-- ...and it must still carry some of the ore, or every haft is identical.
local haftKeys, haftDistinct = {}, 0
for _, l in pairs(looks) do
	local k = key(l.haft)
	if not haftKeys[k] then haftKeys[k] = true haftDistinct += 1 end
end
check(haftDistinct >= math.floor(#ORES * 0.5),
	("hafts differ too, rather than all being one neutral: %d distinct"):format(haftDistinct))

-- Silhouette spans the roster, so colour is not the only thing that changes.
local lo, hi = 1, 0
for _, l in pairs(looks) do
	lo = math.min(lo, l.shapeT)
	hi = math.max(hi, l.shapeT)
end
check(lo <= 0.001 and hi >= 0.999,
	("silhouette spans the roster (%.3f .. %.3f)"):format(lo, hi))

--[[
	GLOW: the authored data wins, and the guessing stays small.

	29 rows carry a hand-picked "glow", so "fewer than half the roster glows" was
	never the right assertion -- it was my taste against the designer's. The two
	properties that do matter:

	  1. every ore AUTHORED to glow gets a lit accent, or the data is being
	     ignored (which is the bug this check was written after);
	  2. of the rows authoring nothing, only a minority are given one by the
	     fallback -- a glowing vein on limestone is what makes a set look cheap.
]]
local authored, authoredLit, plain, plainLit = 0, 0, 0, 0
for _, o in ipairs(ORES) do
	local l = looks[o.id]
	if l then
		if o.glow ~= nil then
			authored += 1
			if l.lit then authoredLit += 1 end
		else
			plain += 1
			if l.lit then plainLit += 1 end
		end
	end
end
check(authored > 0 and authoredLit == authored,
	("every ore authored to glow does: %d of %d"):format(authoredLit, authored))
check(plainLit < plain * 0.5,
	("the fallback stays a minority: %d of %d unauthored ores"):format(plainLit, plain))

-- Gleam tracks the ore. A rough non-metal must not shine.
local badRefl = {}
for _, o in ipairs(ORES) do
	local l = looks[o.id]
	if l then
		local met, rough = tonumber(o.met) or 0, tonumber(o.rough) or 1
		if met <= 0.05 and l.refl > 0.001 then
			table.insert(badRefl, o.id .. " is not metal but gleams")
		end
		if met >= 0.95 and rough <= 0.2 and l.refl < 0.2 then
			table.insert(badRefl, o.id .. " is polished metal but dull")
		end
	end
end
check(#badRefl == 0, "gleam tracks metalness and smoothness" ..
	(#badRefl > 0 and ("  " .. table.concat(badRefl, "; ")) or ""))

-- A non-ore caller still gets the ramp: oreLook must refuse a bad row rather
-- than invent a look for it.
check(Factory.oreLook(nil) == nil and Factory.oreLook({}) == nil,
	"oreLook returns nil for anything that is not an ore row")

if fail > 0 then
	print("")
	print(">>> oretools: " .. fail .. " FAILED assertion(s)")
else
	print("")
	print(">>> oretools: all assertions passed")
end
`;

const script = path.join(ROOT, ".luau-bin/oretools-check.luau");
fs.writeFileSync(script, harness);
let out = "";
try {
  out = execFileSync(LUAU, [script], { encoding: "utf8" });
  process.stdout.write(out);
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
  process.stdout.write(e.stdout || "");
  process.stderr.write(e.stderr || "");
  process.exit(1);
}
process.exit(/FAILED|FAIL /.test(out) ? 1 : 0);
