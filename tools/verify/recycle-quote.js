// THE SCRAP BUTTON MUST QUOTE WHAT THE SERVER PAYS.
//
// Found in the launch audit and confirmed adversarially: the Forge's SCRAP
// button advertised a large ore and dust refund and the server paid ZERO, and
// the tool was destroyed either way.
//
// Both sides called MineConfig.toolRecycle, which is the rule at the top of
// MineForge -- "Pricing is never computed here... so the panel and the server
// cannot quote different numbers". The rule held for the price. It did not hold
// for the refund, because toolRecycle takes FOUR arguments and a panel passed
// three, or a literal 1:
//
//   toolRecycle(tier, level, typeMult, baseLevel)   baseLevel defaults to 1
//
// The server passes the tool's real `base`. One argument, and the two sides
// computed different things from the same shared function. It happened TWICE:
// first in the old Forge (MineForge, fixed 2026-10-1x), then again in the Forge
// hub (MineForgeHub, launch audit 2026-10-19 S10, which quoted base 1) -- the
// derivation of the argument was copied, not shared, so it could be dropped.
//
// So since S10 the whole reading lives in ONE function, MineOreTools.recycleRefund
// (level, `base` with its clamp and fallback, typeMult from the ore tier), and
// the server's recycleOreTool, the Forge hub and the old Forge all call it with
// the tool row. This check asserts that, and EXECUTES the shared function
// against the server's pre-S10 arithmetic (nothing the server pays moved) and
// against both panel bugs (the harness can see them).
//
// It is not an edge case. A newly forged tool INHERITS the highest level you
// own and is stamped `base = inherited`, so once anything of yours is level 10
// every tool you forge starts at level 10 with base 10, and for that tool
// spent(10) - spent(10) = 0 while the panel showed the whole climb.
//
// Run: node tools/verify/recycle-quote.js
const fs = require("fs"), path = require("path"), { execFileSync } = require("child_process");
const Luau = require("./_luau");
const ROOT = path.join(__dirname, "..", "..");
const SHARED = "src/ReplicatedStorage/Mine/Shared/";
const CFG = Luau.readSrc(path.join(ROOT, SHARED + "MineConfig.luau"));
const ORE = Luau.readSrc(path.join(ROOT, SHARED + "MineOreTools.luau"));
const FORGE = Luau.readSrc(path.join(ROOT, SHARED + "MineForge.luau"));
const HUB = Luau.readSrc(path.join(ROOT, SHARED + "MineForgeHub.luau"));
const SRV = Luau.readSrc(path.join(ROOT, "src/ServerScriptService/Mine/MineServer.server.luau"));

let fails = 0;
const ok = (c, msg, detail) => {
  console.log((c ? "  ok    " : "  FAIL  ") + msg + (detail ? "   " + detail : ""));
  if (!c) fails++;
};
// Code only: a comment that QUOTES the old call must not satisfy or fail a check.
const code = (s) => s.replace(/--\[\[[\s\S]*?\]\]/g, "").replace(/--[^\n]*/g, "");

console.log("recycle-quote: every SCRAP quote equals the server's payout");

// ---------------------------------------------------------------- static --
const refundFn = (ORE.match(/function MineOreTools\.recycleRefund\(tool\)[\s\S]*?\nend\n/) || [""])[0];
ok(refundFn.length > 0, "MineOreTools.recycleRefund exists (the one reading of a refund)");
ok(/math\.clamp\(math\.floor\(tonumber\(tool\.base\) or 1\), 1, level\)/.test(refundFn),
  "...it reads tool.base with the clamp and the generous fallback");
const inner = /C\.toolRecycle\(([^)]*)\)/.exec(refundFn);
ok(!!inner && inner[1].split(",").length === 4, "...and passes baseLevel (4 args, not 3)");

const recycleVerb = code((SRV.match(/function Verbs\.recycleOreTool[\s\S]*?\nend\n/) || [""])[0]);
ok(/\.recycleRefund\(tool\)/.test(recycleVerb), "the server's recycleOreTool pays through it");
for (const [name, src] of [["the Forge hub (MineForgeHub)", HUB], ["the old Forge (MineForge)", FORGE]]) {
  const c = code(src);
  ok(/OreTools\.recycleRefund\(/.test(c), name + " quotes SCRAP through it");
  ok(!/C\.toolRecycle\(/.test(c), name + " computes no refund of its own");
}
ok(!/C\.toolRecycle\(/.test(code(SRV)), "...and neither does the server, outside the shared function");

// Destroying a tool should not be one click.
ok(/scrapArmed/.test(FORGE), "the old Forge's SCRAP arms before it fires");
ok(/TAP AGAIN TO SCRAP/.test(HUB) && /state\.uConfirm == o\.uid/.test(HUB),
  "the hub's SCRAP asks twice", "the honest quote is often +0, so a misclick costs a tool for nothing");

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
// its LENGTH is read (by clampTier). recycleRefund and typeMult come from
// MineOreTools, which reads MineConfig as `C`. ]]
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
local C = MineConfig
local MineOreTools = {}
${block(ORE, "MineOreTools.TYPE_MULT_STEPS = {", "}")}
${block(ORE, "function MineOreTools.typeMult(", "end")}
${block(ORE, "function MineOreTools.recycleRefund(", "end")}

local fails = 0
local function check(name, cond, detail)
	print((cond and "  ok    " or "  FAIL  ") .. name .. (detail and ("   " .. detail) or ""))
	if not cond then fails += 1 end
end

-- What the server paid before S10, verbatim: Verbs._oreToolCost's typeMult
-- (MineOreTools.typeMult of the row's family and tier) and the inline base.
local function serverBefore(t)
	local level = math.max(1, tonumber(t.level) or 1)
	local base = math.clamp(math.floor(tonumber(t.base) or 1), 1, level)
	return MineConfig.toolRecycle(t.tier, level, MineOreTools.typeMult(t.familyId or "pickaxe", t.tier), base)
end
-- The two panel bugs: the hub's literal 1 (S10), the old Forge's missing arg.
local function hubBefore(t)
	return MineConfig.toolRecycle(t.tier, t.level, MineOreTools.typeMult(t.familyId, t.tier), 1)
end
local function forgeBefore(t)
	return MineConfig.toolRecycle(t.tier, t.level, MineOreTools.typeMult(t.familyId, t.tier))
end

--[[
	THE WHOLE POINT. Sweep the roster rather than spot-checking, because the
	divergence depends on base vs level and a couple of hand-picked rows is how
	this got through twice.
]]
do
	local rows, moved, hubBad, forgeBad, worst, worstAt = 0, 0, 0, 0, 0, ""
	for _, fam in ipairs({ "pickaxe", "hammer", "drill", "jackhammer", "explosive" }) do
		for tier = 1, 82, 3 do
			for base = 1, 30, 4 do
				for _, up in ipairs({ 0, 1, 5, 12 }) do
					local t = { familyId = fam, tier = tier, level = math.min(30, base + up), base = base }
					rows += 1
					local o, d = MineOreTools.recycleRefund(t)
					local so, sd = serverBefore(t)
					if o ~= so or d ~= sd then
						moved += 1
					end
					local ho = hubBefore(t)
					if ho ~= o then
						hubBad += 1
						if math.abs(ho - o) > worst then
							worst, worstAt = math.abs(ho - o), string.format("%s t%d base %d lvl %d", fam, tier, base, t.level)
						end
					end
					if forgeBefore(t) ~= o then
						forgeBad += 1
					end
				end
			end
		end
	end
	check("the shared refund is exactly what the server paid before (nothing moved)", moved == 0,
		string.format("%d of %d rows differ", moved, rows))
	-- Proves the harness can actually SEE the bugs, rather than passing vacuously.
	check("...and the hub's old base-1 quote really was wrong", hubBad > 0,
		string.format("%d rows differed, worst by %d ore at %s", hubBad, worst, worstAt))
	check("...and so was the old Forge's three-arg form", forgeBad > 0,
		string.format("%d rows differed", forgeBad))
end

-- A row saved before base existed refunds on the old, generous terms.
do
	local t = { familyId = "drill", tier = 41, level = 18 }
	check("a row with no base reads base 1", MineOreTools.recycleRefund(t) == hubBefore(t))
	local over = { familyId = "drill", tier = 41, level = 12, base = 20 }
	check("a base above the level is clamped to it (refunds nothing)", MineOreTools.recycleRefund(over) == 0)
end

--[[
	A tool forged at its level and never upgraded refunds NOTHING. This is the
	common case -- inheritance stamps base = level -- and it is the one the
	player saw a big number for.
]]
do
	local allZero = true
	for tier = 1, 82, 7 do
		for base = 2, 30, 7 do
			if MineOreTools.recycleRefund({ familyId = "hammer", tier = tier, level = base, base = base }) ~= 0 then
				allZero = false
			end
		end
	end
	check("a tool that bought no levels refunds nothing", allZero)
end

-- And one that DID buy levels gets something back, or the stat is decoration.
do
	local got = MineOreTools.recycleRefund({ familyId = "pickaxe", tier = 41, level = 18, base = 10 })
	check("a tool that bought levels refunds something", got > 0, tostring(got) .. " ore")
	check("but never more than a tool that bought more",
		got < MineOreTools.recycleRefund({ familyId = "pickaxe", tier = 41, level = 25, base = 10 }))
end

-- Refund can never exceed what was poured in, or scrapping prints ore.
do
	local leak = false
	for tier = 1, 82, 5 do
		for base = 1, 20, 6 do
			local level = math.min(30, base + 10)
			local mult = MineOreTools.typeMult("drill", tier)
			local spent = MineConfig.toolSpent(tier, level, mult)
			local baseSpent = MineConfig.toolSpent(tier, base, mult)
			local o = MineOreTools.recycleRefund({ familyId = "drill", tier = tier, level = level, base = base })
			if o > (spent - baseSpent) then leak = true end
		end
	end
	check("a refund never exceeds what was spent above base", not leak,
		"otherwise forge -> scrap -> repeat is an ore printer")
end

print(fails == 0 and ">>> recycle-quote harness OK" or (">>> " .. fails .. " FAILED"))
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
if (!/>>> recycle-quote harness OK/.test(out)) fails++;

console.log(fails === 0 ? ">>> recycle-quote OK" : `>>> ${fails} FAILED`);
process.exit(fails === 0 ? 0 : 1);
