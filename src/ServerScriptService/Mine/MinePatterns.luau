-- MinePatterns: which grid cells a tool touches, and how hard.
--
-- Kept separate from MineServer so the shapes can be checked on their own. If
-- the pattern here and the number MineTools prices ever disagree, the shop is
-- lying to the player -- so `count` exists purely to be asserted against
-- MineTools.cellsOf.
--
-- Grid convention, matching the voxel store: cx/cz are horizontal, cy is DEPTH
-- (larger cy is deeper). "Down" travels +cy. "Directional" travels along the
-- horizontal axis you are aiming down, eating into the wall.
--
-- Falloff is 100% at the impact cell, 70% at half radius, 40% at the rim --
-- linear in d/r. Today every cell in a blast takes full power, which is a
-- straight overstatement of what the balance model priced.
local MinePatterns = {}

local function clampAxis(v)
	-- Quantise an aim vector to the dominant horizontal axis, because the voxel
	-- grid is axis-aligned and a diagonal ray would carve a staircase.
	if math.abs(v.X) >= math.abs(v.Z) then
		return Vector3.new(v.X >= 0 and 1 or -1, 0, 0)
	end
	return Vector3.new(0, 0, v.Z >= 0 and 1 or -1)
end

--[[
	Falloff for a cell `d` away from an impact of radius `r`.

	r = 0 (a single cell) is always full power: there is no rim to fall off to.
]]
function MinePatterns.falloff(d, r)
	if not r or r <= 0 then
		return 1
	end
	return math.clamp(1 - 0.6 * (d / r), 0.4, 1)
end

-- Every integer cell within Euclidean `r`, as offsets, with falloff attached.
local function sphere(out, ox, oy, oz, r, weight)
	for dx = -r, r do
		for dy = -r, r do
			for dz = -r, r do
				local d2 = dx * dx + dy * dy + dz * dz
				if d2 <= r * r then
					table.insert(out, {
						cx = ox + dx, cy = oy + dy, cz = oz + dz,
						factor = MinePatterns.falloff(math.sqrt(d2), r) * (weight or 1),
					})
				end
			end
		end
	end
end

-- A flat disc on the wall face: the plane perpendicular to the aim axis.
local function disc(out, ox, oy, oz, r, axis, weight)
	local alongX = math.abs(axis.X) > 0
	local span = math.floor(r)
	for a = -span, span do
		for bb = -span, span do
			local d2 = a * a + bb * bb
			if d2 <= r * r then
				local cx = ox + (alongX and 0 or a)
				local cz = oz + (alongX and a or 0)
				table.insert(out, {
					cx = cx, cy = oy + bb, cz = cz,
					factor = MinePatterns.falloff(math.sqrt(d2), r) * (weight or 1),
				})
			end
		end
	end
end

-- Cells running back along the aim ray from the impact.
local function line(out, ox, oy, oz, depth, axis, weight)
	for i = 0, depth - 1 do
		table.insert(out, {
			cx = ox + math.floor(axis.X * i),
			cy = oy,
			cz = oz + math.floor(axis.Z * i),
			-- A line does not fall off across its width; it falls off with
			-- distance travelled, which is what makes depth a real trade.
			factor = math.clamp(1 - 0.5 * (i / math.max(1, depth - 1)), 0.5, 1) * (weight or 1),
		})
	end
end

-- A w x w footprint. `travel` is the axis the drill advances along, so the
-- footprint spans the other two.
local function footprint(out, ox, oy, oz, w, travel)
	local half = math.floor(w / 2)
	local lo, hi = -half, half
	-- Even widths have no centre cell; bias toward the aim.
	if w % 2 == 0 then
		lo, hi = 0, w - 1
	end
	for a = lo, hi do
		for bb = lo, hi do
			if travel == "down" then
				table.insert(out, { cx = ox + a, cy = oy, cz = oz + bb, factor = 1 })
			elseif math.abs(travel.X) > 0 then
				table.insert(out, { cx = ox, cy = oy + a, cz = oz + bb, factor = 1 })
			else
				table.insert(out, { cx = ox + a, cy = oy + bb, cz = oz, factor = 1 })
			end
		end
	end
end

--[[
	Event Horizon explosive: horizontal W×W face, then D cells straight down (+cy).
]]
local function shaftdown(out, ox, oy, oz, width, depth)
	width = math.max(1, math.floor(tonumber(width) or 3))
	depth = math.max(1, math.floor(tonumber(depth) or 10))
	local half = math.floor(width / 2)
	for dx = -half, half do
		for dz = -half, half do
			local horiz = math.max(math.abs(dx), math.abs(dz))
			for dy = 0, depth - 1 do
				local vert = dy / math.max(1, depth - 1)
				local factor = math.clamp(
					1 - 0.28 * (horiz / math.max(1, half)) - 0.35 * vert,
					0.35,
					1
				)
				table.insert(out, {
					cx = ox + dx,
					cy = oy + dy,
					cz = oz + dz,
					factor = factor,
				})
			end
		end
	end
end

--[[
	Resolve one use of `tool` at cell (cx, cy, cz) with the player aiming `aim`.

	Returns a list of { cx, cy, cz, factor }. `factor` multiplies the tool's
	power; the caller still caps each cell at the block's remaining HP.
]]
function MinePatterns.resolve(tool, cx, cy, cz, aim, boosts)
	local out = {}
	boosts = boosts or {}
	local axis = clampAxis(aim or Vector3.new(0, 0, -1))

	local pattern = tool.pattern
	local shape = tool.shape

	-- Drills: a footprint that advances. Chest tools can sink two layers a tick.
	if shape == "down" or shape == "dir" then
		local w = tool.width or 1
		footprint(out, cx, cy, cz, w, shape == "down" and "down" or axis)
		if tool.special == "doublesink" and shape == "down" then
			footprint(out, cx, cy + 1, cz, w, "down")
		end
		return out
	end

	-- Pickaxes and anything without a pattern: the aimed cell, unless the tool
	-- declares a footprint (Crater is the only 3x3 pick — width on the wall face).
	if not pattern or shape == "melee" then
		local w = math.floor(tonumber(tool.footprint) or 1)
		if w > 1 then
			footprint(out, cx, cy, cz, w, axis)
		else
			table.insert(out, { cx = cx, cy = cy, cz = cz, factor = 1 })
		end
		return out
	end

	local radius = math.floor((tool.radius or 0) * (1 + (boosts.blastRadius or 0)))

	if pattern == "sphere" or pattern == "blackhole" then
		sphere(out, cx, cy, cz, radius, 1)
	elseif pattern == "splash" then
		-- Floor / steep aim: a wall-disc reads as a line of cells. Use a sphere
		-- when the throw is mostly vertical; keep the disc for wall faces.
		local aimY = aim and math.abs(aim.Y) or 0
		if aimY >= 0.55 then
			sphere(out, cx, cy, cz, math.max(1, radius), 1)
		else
			disc(out, cx, cy, cz, math.max(1.2, radius * 1.6), axis, 1)
		end
	elseif pattern == "line" then
		line(out, cx, cy, cz, tool.depth or 1, axis, 1)
	elseif pattern == "shaftdown" then
		shaftdown(out, cx, cy, cz, tool.width or 3, tool.depth or 10)
	elseif pattern == "linesplash" then
		line(out, cx, cy, cz, tool.depth or 1, axis, 1)
		disc(out, cx, cy, cz, radius * 1.6, axis, 1)
	elseif pattern == "cluster" then
		-- Pods are THROWN, each a few degrees off your aim, so a cluster
		-- scatters around where you pointed rather than landing on a rigid
		-- lattice. A little jitter on top keeps two throws from being identical.
		--
		-- Overlap is deliberately allowed. In open rock the pods spread and
		-- cover ground; in a confined shaft they land on top of each other and
		-- their damage STACKS on the blocks in that radius, because every pod is
		-- resolved separately by the caller. Forcing them apart, which is what
		-- this did before, threw away the tight-quarters case entirely.
		local bombs = tool.bombs or 1
		local fan = tool.fan
		if not fan then
			fan = {}
			local spread = 22.5
			local mid = (bombs - 1) / 2
			for i = 0, bombs - 1 do
				table.insert(fan, (i - mid) * spread)
			end
		end
		-- Deterministic per impact so a pattern preview and the real blast agree,
		-- but different at every different spot you throw at.
		local rng = Random.new(cx * 73856093 + cy * 19349663 + cz * 83492791)
		local jitter = tool.jitter or 7
		local reach = radius * 2 + 2
		local perp = math.abs(axis.X) > 0 and Vector3.new(0, 0, 1) or Vector3.new(1, 0, 0)
		for i = 1, #fan do
			local deg = fan[i] + (rng:NextNumber() * 2 - 1) * jitter
			local rad = math.rad(deg)
			-- Rotate the throw off the aim: sideways by sin, and slightly short
			-- or long by cos, so pods do not all land on one line.
			local lateral = math.sin(rad) * reach
			local along = (1 - math.cos(rad)) * reach
			local ox = math.floor(perp.X * lateral - axis.X * along + 0.5)
			local oz = math.floor(perp.Z * lateral - axis.Z * along + 0.5)
			-- A touch of vertical scatter so a cluster does not read as flat.
			local oy = (i % 2 == 0) and 0 or (rng:NextNumber() < 0.5 and -1 or 0)
			sphere(out, cx + ox, cy + oy, cz + oz, radius, 1)
		end
	else
		table.insert(out, { cx = cx, cy = cy, cz = cz, factor = 1 })
	end
	return out
end

--[[
	Returns COVERAGE (distinct cells) and BUDGET (total pod-cell entries).

	Budget is what MineTools prices and what the rock takes, because overlapping
	pods each resolve separately and their damage stacks. Coverage is the smaller
	number you actually see cleared, and the two diverge exactly when a cluster
	lands in a confined space -- which is the trade the family is built on.
]]
function MinePatterns.count(tool, boosts)
	local cells = MinePatterns.resolve(tool, 0, 0, 0, Vector3.new(0, 0, -1), boosts)
	local seen, n = {}, 0
	for _, c in ipairs(cells) do
		local k = c.cx .. ":" .. c.cy .. ":" .. c.cz
		if not seen[k] then
			seen[k] = true
			n += 1
		end
	end
	return n, #cells
end

return MinePatterns
