// The blacksmith upgrade model: pure functions in MineConfig, so the bench,
// the recycler and the UI all price a level the same way.
const fs = require("fs"), path = require("path");
const CFG = path.join(__dirname, "..", "src/ReplicatedStorage/Mine/Shared/MineConfig.luau");
const raw = fs.readFileSync(CFG, "utf8");
const CRLF = raw.indexOf("\r\n") >= 0;
let s = raw.split("\r\n").join("\n");
if (s.indexOf("TOOL_MAX_LEVEL") >= 0) { console.log("already present"); process.exit(0); }

const anchor = "MineConfig.ORE_MIGRATION = {";
if (s.split(anchor).length - 1 !== 1) throw new Error("anchor not unique");

const block = `--[[
	THE BLACKSMITH UPGRADE MODEL.

	Every tool runs its own 1..TOOL_MAX_LEVEL scale. Ore tier does not set a
	tool's starting level any more -- it sets the band the tool plays in, and
	the level is the whole climb inside it. A tier-121 pick used to be BORN at
	level 700, which made finding one the end of its story rather than the
	start, and left nothing worth spending stardust on.

	Tier is therefore a multiplier: TOOL_TIER_SPAN says how many x6 steps
	separate tier 1 from tier 121, the same unit the mine measures depth in.

	A level costs ORE and STARDUST. Ore is the real gate -- you cannot level
	what you cannot dig -- and stardust is the throttle. Both scale with the
	tool's tier and type, anchored so a tier-1 pickaxe is the 1x baseline and
	nothing in the game is ever cheaper to level than that.

	Numbers come from the balance model in tools/upgrade-calculator.html; the
	harnesses under tools/verify assert on them.
]]
MineConfig.TOOL_MAX_LEVEL = 1000
MineConfig.TOOL_TIER_SPAN = 16        -- 6^16 from tier 1 to tier 121
MineConfig.TOOL_DMG_BASE = 10
MineConfig.TOOL_DMG_STEP = 1.02       -- per level
MineConfig.TOOL_ORE_BASE = 4
MineConfig.TOOL_ORE_GROW = 1.0075
MineConfig.TOOL_DUST_BASE = 25
MineConfig.TOOL_DUST_GROW = 1.011
MineConfig.TOOL_COST_TIER = 0.85      -- cost exponent on ore tier
MineConfig.TOOL_COST_TYPE = 0.5       -- cost exponent on type rarity
MineConfig.TOOL_RECYCLE_PCT = 0.5     -- flat cut of what went in

local function clampLevel(level)
	local n = math.floor(tonumber(level) or 1)
	return math.clamp(n, 1, MineConfig.TOOL_MAX_LEVEL)
end
local function clampTier(tier)
	local n = math.floor(tonumber(tier) or 1)
	return math.clamp(n, 1, #MineConfig.ORES)
end

-- Both anchor at 1 and only ever go UP. typeMult is the tool type's rarity
-- weight (1 for a plain pickaxe); a rarer frame costs more per level.
function MineConfig.toolCostMult(tier, typeMult)
	local t = clampTier(tier)
	local m = math.max(1, tonumber(typeMult) or 1)
	return (t ^ MineConfig.TOOL_COST_TIER) * (m ^ MineConfig.TOOL_COST_TYPE)
end

-- What tier alone is worth, before any levelling.
function MineConfig.toolTierPower(tier)
	local t = clampTier(tier)
	return 6 ^ (MineConfig.TOOL_TIER_SPAN * (t - 1) / 120)
end

function MineConfig.toolPower(tier, level, typeMult)
	local L = clampLevel(level)
	return MineConfig.TOOL_DMG_BASE
		* MineConfig.toolTierPower(tier)
		* math.max(0.01, tonumber(typeMult) or 1)
		* (MineConfig.TOOL_DMG_STEP ^ (L - 1))
end

-- Cost of the step from \`level\` to \`level + 1\`. Returns nil at the cap so a
-- caller cannot accidentally charge for a level that does not exist.
function MineConfig.toolUpgradeCost(tier, level, typeMult)
	local L = clampLevel(level)
	if L >= MineConfig.TOOL_MAX_LEVEL then
		return nil, nil
	end
	local mult = MineConfig.toolCostMult(tier, typeMult)
	local ore = math.ceil(MineConfig.TOOL_ORE_BASE * (MineConfig.TOOL_ORE_GROW ^ (L - 1)) * mult)
	local dust = math.ceil(MineConfig.TOOL_DUST_BASE * (MineConfig.TOOL_DUST_GROW ^ (L - 1)) * mult)
	return ore, dust
end

-- Everything poured in to reach \`level\` from 1. Geometric, so it stays exact
-- at level 1000 instead of drifting the way a loop would.
function MineConfig.toolSpent(tier, level, typeMult)
	local L = clampLevel(level)
	if L <= 1 then
		return 0, 0
	end
	local mult = MineConfig.toolCostMult(tier, typeMult)
	local ro, rd = MineConfig.TOOL_ORE_GROW, MineConfig.TOOL_DUST_GROW
	local ore = math.ceil(MineConfig.TOOL_ORE_BASE * ((ro ^ (L - 1)) - 1) / (ro - 1) * mult)
	local dust = math.ceil(MineConfig.TOOL_DUST_BASE * ((rd ^ (L - 1)) - 1) / (rd - 1) * mult)
	return ore, dust
end

--[[
	Scrapping returns a flat cut of what was actually spent -- no tier falloff,
	no type falloff, no level tax.

	All of that machinery existed to stop a tool FOUND in a wall from being a
	payout, because a found tool used to arrive at level 700 with a huge
	notional build cost behind it. On this scale it arrives at level 1 with
	nothing behind it, so the exploit is gone by construction and the rate can
	be generous and legible instead of defensive.
]]
function MineConfig.toolRecycle(tier, level, typeMult)
	local ore, dust = MineConfig.toolSpent(tier, level, typeMult)
	local pct = MineConfig.TOOL_RECYCLE_PCT
	return math.floor(ore * pct), math.floor(dust * pct)
end

`;

s = s.replace(anchor, block + anchor);
fs.writeFileSync(CFG, CRLF ? s.split("\n").join("\r\n") : s);
console.log("upgrade model added to MineConfig");
