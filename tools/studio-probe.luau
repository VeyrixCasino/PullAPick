--[[
	STUDIO COMMAND BAR PROBES.

	Paste into the Studio Command Bar with the place open. Edit mode is fine --
	nothing here spawns, saves or touches a profile on disk. Read-only.

	Probe 1 verifies the depth gate actually loaded and prices correctly in the
	LIVE place rather than in the repo, and that grandfathering works.

	Probe 2 answers the one number the entire balance design rests on and that
	nobody has ever measured: BLOCKS PER HOUR. Every coin price in the seam
	ladder, the rebirth ladder and the shop ladder scales off an assumed 2,000.
	If the real figure is 1,000 or 4,000, the formulas hold but every constant
	moves.
]]

local shared = game:GetService("ReplicatedStorage").Mine.Shared
local Depth = require(shared.MineDepth)
local C = require(shared.MineConfig)

local function fmt(n)
	local s = string.format("%.0f", n)
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

----------------------------------------------------------------------
print("========== PROBE 1: depth gate ==========")
print("SEAMS:", table.concat(Depth.SEAMS, ", "))
print(string.format("%s min per gate @ %s blocks/hr (assumed)",
	tostring(Depth.SEAM_MINUTES), tostring(Depth.GATE_BLOCKS_PER_HOUR)))
print("")
print(string.format("%-7s %-14s %14s %18s", "seam", "band", "Meadow", "Primordium"))
for _, s in ipairs(Depth.SEAMS) do
	local lo, hi = Depth.gateBand(s)
	print(string.format("%-7d %-14s %14s %18s",
		s, lo .. "-" .. hi, fmt(Depth.seamPrice(s, 1)), fmt(Depth.seamPrice(s, 10))))
end

-- Grandfathering: a profile that already dug to 2,700 must keep every gate at
-- or below it and be given none above it.
local fake = { deepest = { meadow = 2700 }, seams = {} }
local granted = Depth.grantReachedSeams(fake)
local kept, wrong = {}, {}
for _, s in ipairs(Depth.SEAMS) do
	if Depth.ownsSeam(fake, s, 1) then
		table.insert(kept, s)
		if s > 2700 then
			table.insert(wrong, s)
		end
	end
end
print("")
print("grandfather @ deepest 2700 -> granted " .. granted .. ": " .. table.concat(kept, ", "))
print("re-run grants (must be 0):", Depth.grantReachedSeams(fake))
print(#wrong == 0 and "OK: nothing granted above 2700" or ("BAD: over-granted " .. table.concat(wrong, ", ")))
print("free surface (layer 1 gate, must be nil):", tostring(Depth.gateForLayer(1)))
print("tail open (layer 50000 -> last seam):", tostring(Depth.gateForLayer(50000)))

----------------------------------------------------------------------
print("")
print("========== PROBE 2: blocks per hour ==========")
print("SWING_SEC = " .. tostring(C.SWING_SEC) .. "   (one swing)")
print("Assumes one block per swing-chain and no blast/zap/echo multi-break.")
print("")
print(string.format("%-6s %-6s %12s %10s %9s %11s", "tier", "lvl", "block HP", "power", "swings", "blocks/hr"))

local function row(zone, layer, tier, level)
	local hp = Depth.dirtHp(zone, layer)
	local power = C.toolPower(tier, level, 1)
	local swings = math.max(1, math.ceil(hp / math.max(1, power)))
	local bph = 3600 / (swings * C.SWING_SEC)
	print(string.format("%-6d %-6d %12s %10s %9d %11s",
		tier, level, fmt(hp), fmt(power), swings, fmt(bph)))
end

print("-- Meadow layer 1, fresh account --")
row(1, 1, 1, 1)
print("-- Meadow layer 1, tier 2-5 at level 1 --")
for t = 2, 5 do
	row(1, 1, t, 1)
end
print("-- Meadow layer 500 / 2500, tier 5 level 1 --")
row(1, 500, 5, 1)
row(1, 2500, 5, 1)

print("")
print("Read the fresh-account row: that is the 2,000 the whole ladder assumes.")
print("If it is far off, say so -- the formulas hold but every price rescales.")
