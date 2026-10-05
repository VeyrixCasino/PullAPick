// The two number formatters must not disagree about the same number.
//
// MineBigNum (server-only, TODO 0.8) is meant to be THE formatter, and the
// client is meant to render its string. MineAbbrev.currency (TODO 0.9) is what
// every currency readout actually uses today. Both claim four significant
// figures, floored. Two formatters that disagree about the same number is the
// whole reason there is meant to be one, so this pins them together:
//
//   * four significant figures, for every mantissa shape (1.234K / 12.34K /
//     123.4K), from both
//   * floored, never rounded up -- a player is never told they hold more than
//     they hold
//   * IDENTICAL output below step 21, which is every magnitude a player will
//     ever see
//
// Past step 21 (10^63) they diverge on purpose and this records where: 0.8
// prescribes MineBigNum's q..z backlog, MineAbbrev carries on with Vg/Uvg/Dvg.
// That is an open owner call, not a bug, so it is reported rather than failed.
//
// Both modules are pure Lua with no requires, so they are run as they ship.
//
//   node tools/verify/bignum.js
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = path.resolve(__dirname, "../..");
const Luau = require("./_luau");
const LUAU = Luau.LUAU;
if (!Luau.ready) {
  // Names the platform and the fix, rather than "skipping" with no reason.
  console.log(Luau.missing("luau") + "; skipping");
  process.exit(0);
}

const abbrev = fs.readFileSync(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineAbbrev.luau"), "utf8");
const bignum = fs.readFileSync(path.join(ROOT, "src/ServerScriptService/Mine/MineBigNum.luau"), "utf8");

// Step 21 is 10^63: the first step past MineBigNum's twenty named suffixes.
const AGREE_BELOW_STEP = 21;

const harness = `
local MineAbbrev = (function()
${abbrev}
end)()
local MineBigNum = (function()
${bignum}
end)()

local fail = 0
local function check(ok, msg)
	if not ok then fail += 1 print("  FAIL  " .. msg) else print("  ok    " .. msg) end
end

-- 1. Four significant figures, from both, for every mantissa shape.
local function sigFigs(s)
	local digits = string.gsub(string.match(s, "^%-?[%d%.]+") or "", "%D", "")
	digits = string.gsub(digits, "^0+", "")
	return #digits
end
local shapeBad = 0
for step = 1, ${AGREE_BELOW_STEP - 1} do
	for _, m in ipairs({ 1.234, 12.34, 123.4, 1, 999.9 }) do
		local n = m * 10 ^ (step * 3)
		for name, s in pairs({ abbrev = MineAbbrev.currency(n), bignum = MineBigNum.auto(n) }) do
			if sigFigs(s) ~= 4 then
				shapeBad += 1
				print(("          %s(%g e%d) = %s is %d figures, not 4")
					:format(name, m, step * 3, s, sigFigs(s)))
			end
		end
	end
end
check(shapeBad == 0, "both read four significant figures, every mantissa shape")

-- 2. Floored, never up. 1299 must never read 1.3K.
local roundedUp = 0
for _, pair in ipairs({ { 1299, "1.299K" }, { 1999, "1.999K" }, { 12999, "12.99K" },
                        { 129999, "129.9K" }, { 999999, "999.9K" } }) do
	for name, s in pairs({ abbrev = MineAbbrev.currency(pair[1]), bignum = MineBigNum.auto(pair[1]) }) do
		if s ~= pair[2] then
			roundedUp += 1
			print(("          %s(%d) = %s, expected %s"):format(name, pair[1], s, pair[2]))
		end
	end
end
check(roundedUp == 0, "both floor; 1299 reads 1.299K and never 1.3K")

-- 3. Identical below step 21 -- every magnitude a player will see.
local diff, firstDiff = 0, nil
for step = 0, ${AGREE_BELOW_STEP - 1} do
	for _, m in ipairs({ 1, 1.234, 5.5, 12.34, 99.99, 123.4, 999.9 }) do
		local n = m * 10 ^ (step * 3)
		local a, b = MineAbbrev.currency(n), MineBigNum.auto(n)
		if a ~= b then
			diff += 1
			if not firstDiff then firstDiff = ("%g e%d: abbrev %s vs bignum %s"):format(m, step * 3, a, b) end
		end
	end
end
check(diff == 0, ("the two agree on every magnitude below step ${AGREE_BELOW_STEP} (%d disagreements%s)")
	:format(diff, firstDiff and ("; first " .. firstDiff) or ""))

-- 4. Zero and small values are plain integers, not "0.000".
check(MineAbbrev.currency(0) == "0" and MineBigNum.auto(0) == "0", "zero reads 0")
check(MineAbbrev.currency(999) == "999" and MineBigNum.auto(999) == "999", "999 reads 999")

-- 5. Where they diverge on purpose. Reported, not failed: TODO 0.8 prescribes
--    the q..z backlog and 0.9 points currencies at MineAbbrev, and which one
--    wins past Nod is an owner call.
print("")
print("  past step ${AGREE_BELOW_STEP} the symbol sets diverge BY DESIGN (owner call, see TODO 0.8/0.9):")
for step = ${AGREE_BELOW_STEP}, ${AGREE_BELOW_STEP} + 3 do
	local n = 1.234 * 10 ^ (step * 3)
	print(("    10^%-4d abbrev %-12s bignum %s"):format(step * 3, MineAbbrev.currency(n), MineBigNum.auto(n)))
end

if fail > 0 then
	print("")
	print(">>> bignum: " .. fail .. " FAILED assertion(s)")
else
	print("")
	print(">>> bignum: all assertions passed")
end
`;

const script = path.join(ROOT, ".luau-bin/bignum-check.luau");
fs.writeFileSync(script, harness);
// The exit code is decided HERE, from the output, not by the Lua.
// This luau build has no os.exit, so a check that called it failed only by
// erroring on a nil value -- which happens to be non-zero today and would go
// silent the moment it did not. A verify script that can pass when it should
// fail is worse than no verify script.
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
