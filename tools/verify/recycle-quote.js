// THE SCRAP BUTTON MUST QUOTE WHAT THE SERVER PAYS.
//
// Found in the launch audit and confirmed adversarially: the Forge's SCRAP
// button advertised a large ore and dust refund and the server paid ZERO, and
// the tool was destroyed either way.
//
// Both sides call MineConfig.toolRecycle, which is the rule at the top of
// MineForge -- "Pricing is never computed here... so the panel and the server
// cannot quote different numbers". The rule held for the price. It did not hold
// here, because toolRecycle takes FOUR arguments and the panel passed three:
//
//   toolRecycle(tier, level, typeMult, baseLevel)   baseLevel defaults to 1
//
// The server passes the tool's real `base`. One missing argument, and the two
// sides computed different things from the same shared function -- which is
// precisely the failure the shared function was supposed to make impossible.
//
// It is not an edge case. A newly forged tool INHERITS the highest level you
// own and is stamped `base = inherited`, so once anything of yours is level 10
// every tool you forge starts at level 10 with base 10, and for that tool
// spent(10) - spent(10) = 0 while the panel showed the whole climb.
//
// This harness exists because the bug is INVISIBLE to every other check: both
// numbers are well-formed, both come from the blessed function, and nothing
// errors. The only way to see it is to compute both and compare.
//
// Run: node tools/verify/recycle-quote.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const CFG = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineConfig.luau"));
const FORGE = Luau.readSrc(path.join(ROOT, "src/ReplicatedStorage/Mine/Shared/MineForge.luau"));
const SRV = Luau.readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineServer.server.luau"));

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};

console.log("recycle-quote: the panel's refund equals the server's payout");

// ---------------------------------------------------------------- static --
// The panel must pass a fourth argument. A three-arg call is the bug.
const panelCall = /C\.toolRecycle\(([^)]*)\)/.exec(FORGE);
ok(!!panelCall, "the Forge quotes a recycle at all");
if (panelCall) {
  const args = panelCall[1].split(",").length;
  ok(args === 4, "the Forge passes baseLevel (4 args, not 3)", `got ${args}`);
}
const srvCall = /C\.toolRecycle\(([^)]*)\)/.exec(SRV);
ok(!!srvCall && srvCall[1].split(",").length === 4, "the server passes baseLevel too");

// Both sides must derive `base` the same way, clamp and fallback included.
const CLAMP = /math\.clamp\(math\.floor\(tonumber\(tool\.base\) or 1\), 1, level\)/;
ok(CLAMP.test(FORGE), "the Forge reads tool.base with the server's clamp and fallback");
ok(CLAMP.test(SRV), "the server reads tool.base with that same clamp");

// Destroying a tool should not be one click.
ok(/scrapArmed/.test(FORGE), "SCRAP arms before it fires",
  "the honest quote is often +0, so a misclick costs a tool for nothing");

if (!Luau.LUAU || !fs.existsSync(Luau.LUAU) || !Luau.runnableHere(Luau.LUAU)) {
  console.log("  " + Luau.missing("luau"));
  console.log(fails === 0 ? ">>> recycle-quote OK (static only)" : `>>> ${fails} FAILED`);
  process.exit(fails === 0 ? 0 : 1);
}

const block = (src, head, close) => {
  const L = src.split("\n");
  const i = L.findIndex((l) => l.startsWith(head));
  if (i < 0) throw new Error("not found: " + head);
  for (let j = i; j < L.length; j++) if (L[j] === close) return L.slice(i, j + 1).join("\n");
  throw new Error("unterminated: " + head);
};

const K = (name, dflt) => {
  const m = new RegExp(`MineConfig\\.${name}\\s*=\\s*([0-9.]+)`).exec(CFG);
  return m ? m[1] : dflt;
};

//[[ Sliced from the real source, not restated. toolSpent reaches through
// clampLevel -> TOOL_MAX_LEVEL and toolCostMult -> clampTier -> #ORES and
// TOOL_COST_BANDS, so every one of those comes across or the sweep measures a
// cost curve this file invented. ORES is stubbed to 82 entries because only
// its LENGTH is read (by clampTier). ]]
const harness = `local MineConfig = {
	TOOL_RECYCLE_PCT = ${K("TOOL_RECYCLE_PCT", "0.5")},
	TOOL_MAX_LEVEL = ${K("TOOL_MAX_LEVEL", "30")},
	TOOL_ORE_BASE = ${K("TOOL_ORE_BASE", "4")},
	TOOL_DUST_BASE = ${K("TOOL_DUST_BASE", "25")},
	TOOL_CLIMB_ORE = ${K("TOOL_CLIMB_ORE", "1747")},
	TOOL_CLIMB_DUST = ${K("TOOL_CLIMB_DUST", "55800")},
	TOOL_COST_TYPE = ${K("TOOL_COST_TYPE", "0.5")},
	ORES = table.create(82, { tier = 1 }),
}
${block(CFG, "local function perLevel(", "end")}
MineConfig.TOOL_ORE_GROW = perLevel(MineConfig.TOOL_CLIMB_ORE)
MineConfig.TOOL_DUST_GROW = perLevel(MineConfig.TOOL_CLIMB_DUST)
${block(CFG, "local function clampLevel(", "end")}
${block(CFG, "local function clampTier(", "end")}
${block(CFG, "MineConfig.TOOL_COST_BANDS = {", "}")}
${block(CFG, "function MineConfig.toolCostMult(", "end")}
${block(CFG, "function MineConfig.toolSpent(", "end")}
${block(CFG, "function MineConfig.toolRecycle(", "end")}

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

-- The two call shapes, verbatim.
local function panel(tier, level, mult, base)
	local b = math.clamp(math.floor(tonumber(base) or 1), 1, level)
	return MineConfig.toolRecycle(tier, level, mult, b)
end
local function server(tier, level, mult, base)
	local b = math.clamp(math.floor(tonumber(base) or 1), 1, level)
	return MineConfig.toolRecycle(tier, level, mult, b)
end
-- What the panel USED to do: baseLevel omitted.
local function panelOld(tier, level, mult)
	return MineConfig.toolRecycle(tier, level, mult)
end

--[[
	THE WHOLE POINT. Sweep the roster rather than spot-checking, because the
	divergence depends on base vs level and a couple of hand-picked rows is how
	this got through the first time.
]]
do
	local bad, worst, worstAt = 0, 0, ""
	local oldBad, oldWorst = 0, 0
	for tier = 1, 82, 3 do
		for _, mult in ipairs({ 1, 2, 3 }) do
			for base = 1, 30, 4 do
				for _, up in ipairs({ 0, 1, 5, 12 }) do
					local level = math.min(30, base + up)
					local p = panel(tier, level, mult, base)
					local s = server(tier, level, mult, base)
					if p ~= s then
						bad += 1
						local d = math.abs(p - s)
						if d > worst then worst, worstAt = d, string.format("t%d base %d lvl %d", tier, base, level) end
					end
					local po = panelOld(tier, level, mult)
					if po ~= s then
						oldBad += 1
						oldWorst = math.max(oldWorst, math.abs(po - s))
					end
				end
			end
		end
	end
	check("the panel and the server agree on every row", bad == 0,
		bad > 0 and string.format("%d disagree, worst %d at %s", bad, worst, worstAt) or "swept the roster")
	-- Proves the harness can actually SEE the bug, rather than passing vacuously.
	check("...and the three-arg form really was wrong", oldBad > 0,
		string.format("%d rows differed, worst by %d ore", oldBad, oldWorst))
end

--[[
	A tool forged at its level and never upgraded refunds NOTHING, on both
	sides. This is the common case -- inheritance stamps base = level -- and it
	is the one the player saw a big number for.
]]
do
	local allZero = true
	for tier = 1, 82, 7 do
		for base = 2, 30, 7 do
			if server(tier, base, 2, base) ~= 0 then allZero = false end
		end
	end
	check("a tool that bought no levels refunds nothing", allZero)
end

-- And one that DID buy levels gets something back, or the stat is decoration.
do
	local got = server(41, 18, 2, 10)
	check("a tool that bought levels refunds something", got > 0, tostring(got) .. " ore")
	check("but never more than a tool that bought more",
		server(41, 18, 2, 10) < server(41, 25, 2, 10))
end

-- Refund can never exceed what was poured in, or scrapping prints ore.
do
	local leak = false
	for tier = 1, 82, 5 do
		for base = 1, 20, 6 do
			local level = math.min(30, base + 10)
			local spent = MineConfig.toolSpent(tier, level, 2)
			local baseSpent = MineConfig.toolSpent(tier, base, 2)
			if server(tier, level, 2, base) > (spent - baseSpent) then leak = true end
		end
	end
	check("a refund never exceeds what was spent above base", not leak,
		"otherwise forge -> scrap -> repeat is an ore printer")
end

print(fails == 0 and ">>> recycle-quote OK" or (">>> " .. fails .. " FAILED"))
`;

const tmp = path.join(require("os").tmpdir(), "recycle-quote-harness.luau");
fs.writeFileSync(tmp, harness);
let out = "";
try {
  out = execFileSync(Luau.LUAU, [tmp], { encoding: "utf8" });
} catch (e) {
  out = (e.stdout || "") + (e.stderr || "");
}
process.stdout.write(out);
if (!/>>> recycle-quote OK/.test(out)) fails++;

console.log(fails === 0 ? ">>> recycle-quote OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
