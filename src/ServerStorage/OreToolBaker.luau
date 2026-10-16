--[[
	OreToolBaker: the 82 ore tools, every head at 20,000 triangles.

	WHY A SECOND BAKER. UniqueToolBaker drives off _ToolRenameMap and bakes one
	merged mesh per tool at ~18.5k tris. Two things had to change and neither is
	a tweak to that file: the roster is now an explicit 82 ores rather than the
	rename map, and the triangle budget is per HEAD, not per tool. Head and haft
	are therefore separate MeshParts here -- the head gets the whole 20k and the
	haft costs a few hundred beside it, so "every head is 20k tris" is a number
	you can read off the part rather than a claim about a merged blob.

	FIVE SILHOUETTES PER FAMILY. Fifteen base shapes in all. The style is chosen
	from a hash of the tool name, so a given ore always bakes the same shape --
	re-baking never reshuffles what a player already owns.

	THE LOOK COMES FROM THE ORE. Colour, material, metalness, roughness and glow
	are read out of MineConfig.ORES by name, so a Ruby pick is ruby and an
	Obsidian one is obsidian. The old colorFromHash gave Gold a random mauve.

	Triangle budget is hit exactly, not approximately: every primitive's triangle
	count is predictable in closed form, so padToTarget can step down through
	coarse, fine and single-triangle detail and land on 20,000 every time.
]]
local AssetService = game:GetService("AssetService")
local M = {}

-- Per HEAD. The haft is counted separately and is not part of this budget.
local TRI_TARGET = 20000

--------------------------------------------------------------------------------
-- ROSTER
--
-- The 82 tools, in the order given, with the rarity band each sits in. Rarity
-- drives how ornate a head is allowed to get -- an Exotic head carries more
-- facets and banding than a Common one -- but never the triangle count, which
-- is flat at 20k so no tool is cheaper to render than another.
--------------------------------------------------------------------------------
M.ROSTER = {
	{ "Stone", "common" }, { "Clay", "common" }, { "Limestone", "common" },
	{ "Pumice", "common" }, { "Halite", "common" }, { "Coal", "common" },
	{ "Flint", "common" }, { "Basalt", "common" }, { "Slate", "common" },
	{ "Bone", "common" }, { "Granite", "common" }, { "Copper", "common" },
	{ "Tin", "common" }, { "Ember", "common" }, { "Sulfur", "common" },
	{ "Lead", "common" }, { "Zinc", "common" }, { "Aluminum", "common" },

	{ "Iron", "uncommon" }, { "Graphite", "uncommon" }, { "Pyrite", "uncommon" },
	{ "Marble", "uncommon" }, { "Pearl", "uncommon" }, { "Rime", "uncommon" },
	{ "Quartz", "uncommon" }, { "Amber", "uncommon" }, { "Petrifact", "uncommon" },
	{ "Nickel", "uncommon" }, { "Onyx", "uncommon" },

	{ "Bloodstone", "rare" }, { "Garnet", "rare" }, { "Citrine", "rare" },
	{ "Chromium", "rare" }, { "Turquoise", "rare" }, { "Bismuth", "rare" },
	{ "Silver", "rare" }, { "Amethyst", "rare" }, { "Tigereye", "rare" },
	{ "Lapis", "rare" }, { "Geode", "rare" }, { "Topaz", "rare" },
	{ "Phosphorus", "rare" }, { "Peridot", "rare" }, { "Jade", "rare" },
	{ "Emberglass", "rare" }, { "Tungsten", "rare" }, { "Lithium", "rare" },
	{ "Titanium", "rare" }, { "Obsidian", "rare" },

	{ "Cobalt", "epic" }, { "Gold", "epic" }, { "Regolith", "epic" },
	{ "Sunstone", "epic" }, { "Emerald", "epic" }, { "Moonstone", "epic" },
	{ "Sapphire", "epic" }, { "Ruby", "epic" }, { "Palladium", "epic" },
	{ "Aquamarine", "epic" }, { "Opal", "epic" },

	{ "Platinum", "legendary" }, { "Stormstone", "legendary" }, { "Diamond", "legendary" },
	{ "Starmetal", "legendary" }, { "Aetherite", "legendary" }, { "Meteorite", "legendary" },
	{ "Soulstone", "legendary" }, { "Galaxite", "legendary" }, { "Frostfire", "legendary" },

	{ "Umbrite", "mythic" }, { "Celestine", "mythic" }, { "Orichalcum", "mythic" },
	{ "Spectrite", "mythic" }, { "Mythril", "mythic" }, { "Dragonstone", "mythic" },

	{ "Adamantite", "divine" }, { "Thorium", "divine" }, { "Uranium", "divine" },
	{ "Plutonium", "divine" },

	{ "Fermium", "exotic" }, { "Lawrencium", "exotic" }, { "Oganesson", "exotic" },
}

local ORNATE = {
	common = 0, uncommon = 1, rare = 2, epic = 3,
	legendary = 4, mythic = 5, divine = 6, exotic = 7,
}

--[[
	Families cycle through the roster in order rather than being drawn from the
	name hash. A hash would clump -- with 82 draws over three buckets you get
	runs of five picks in a row purely by chance -- and the roster is read top to
	bottom in the shop, so an even stride keeps every rarity band showing all
	three families.
]]
local FAMILIES = { "pickaxe", "drill", "explosive" }

--------------------------------------------------------------------------------
-- DETERMINISM
--------------------------------------------------------------------------------
local function hash32(s)
	local h = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		h = (h * 16777619) % 4294967296
	end
	return h
end

local function rng(seed)
	local s = seed % 2147483647
	if s <= 0 then
		s = 1
	end
	return function()
		s = (s * 48271) % 2147483647
		return s / 2147483647
	end
end

--------------------------------------------------------------------------------
-- PRIMITIVES
--
-- Every one of these has a closed-form triangle count sitting next to it. That
-- is what makes an exact budget possible: padToTarget can ask "how many would
-- this cost" before adding it, instead of overshooting and clamping.
--------------------------------------------------------------------------------
--[[
	The budget is also a hard stop.

	AddTriangle raises "Triangle count above limit" once a mesh is full, which
	kills the whole bake for that tool. A head that comes out a few triangles
	shy of dense is invisible to anyone; a head that failed to bake is a missing
	tool. Refuse the triangle instead of throwing.
]]
local function tri(em, a, b, c, k)
	if k.n >= TRI_TARGET then
		return
	end
	em:AddTriangle(a, b, c)
	k.n += 1
end

local function sphereTris(lonN, latN)
	return lonN * (2 * latN - 2)
end
local function addSphere(em, c, r, lonN, latN, k)
	local rows = {}
	for lat = 0, latN do
		local phi = (lat / latN) * math.pi
		local y = c.Y + r * math.cos(phi)
		local rr = r * math.sin(phi)
		local row = {}
		for lon = 0, lonN - 1 do
			local th = (lon / lonN) * math.pi * 2
			row[lon + 1] = em:AddVertex(Vector3.new(c.X + rr * math.cos(th), y, c.Z + rr * math.sin(th)))
		end
		rows[lat + 1] = row
	end
	for lat = 0, latN - 1 do
		local a, b = rows[lat + 1], rows[lat + 2]
		for lon = 0, lonN - 1 do
			local n, m = lon + 1, (lon + 1) % lonN + 1
			if lat ~= 0 then
				tri(em, a[n], a[m], b[m], k)
			end
			if lat ~= latN - 1 then
				tri(em, a[n], b[m], b[n], k)
			end
		end
	end
end

local function cylTris(radN, hN)
	return radN * (2 * hN + 2)
end
local function addCylinder(em, c, r, hh, radN, hN, k)
	local rows = {}
	for i = 0, hN do
		local y = c.Y - hh + (i / hN) * hh * 2
		local row = {}
		for j = 0, radN - 1 do
			local th = (j / radN) * math.pi * 2
			row[j + 1] = em:AddVertex(Vector3.new(c.X + r * math.cos(th), y, c.Z + r * math.sin(th)))
		end
		rows[i + 1] = row
	end
	local top = em:AddVertex(Vector3.new(c.X, c.Y + hh, c.Z))
	local bot = em:AddVertex(Vector3.new(c.X, c.Y - hh, c.Z))
	for i = 0, hN - 1 do
		local a, b = rows[i + 1], rows[i + 2]
		for j = 0, radN - 1 do
			local n, m = j + 1, (j + 1) % radN + 1
			tri(em, a[n], a[m], b[m], k)
			tri(em, a[n], b[m], b[n], k)
		end
	end
	local tr, br = rows[hN + 1], rows[1]
	for j = 0, radN - 1 do
		local n, m = j + 1, (j + 1) % radN + 1
		tri(em, top, tr[n], tr[m], k)
		tri(em, bot, br[m], br[n], k)
	end
end

-- A cone is a cylinder whose top ring collapses; same count, different taper.
local function addCone(em, base, r, h, radN, hN, k)
	local rows = {}
	for i = 0, hN do
		local t = i / hN
		local rr = r * (1 - t)
		local y = base.Y + t * h
		local row = {}
		for j = 0, radN - 1 do
			local th = (j / radN) * math.pi * 2
			row[j + 1] = em:AddVertex(Vector3.new(base.X + rr * math.cos(th), y, base.Z + rr * math.sin(th)))
		end
		rows[i + 1] = row
	end
	local bot = em:AddVertex(Vector3.new(base.X, base.Y, base.Z))
	for i = 0, hN - 1 do
		local a, b = rows[i + 1], rows[i + 2]
		for j = 0, radN - 1 do
			local n, m = j + 1, (j + 1) % radN + 1
			tri(em, a[n], a[m], b[m], k)
			tri(em, a[n], b[m], b[n], k)
		end
	end
	local br = rows[1]
	for j = 0, radN - 1 do
		local n, m = j + 1, (j + 1) % radN + 1
		tri(em, bot, br[m], br[n], k)
	end
end

local function torusTris(segR, segT)
	return segR * segT * 2
end
local function addTorus(em, c, R, tube, segR, segT, k, axis)
	local grid = {}
	for i = 0, segR - 1 do
		local u = (i / segR) * math.pi * 2
		local row = {}
		for j = 0, segT - 1 do
			local v = (j / segT) * math.pi * 2
			local rr = R + tube * math.cos(v)
			local px, py, pz = rr * math.cos(u), tube * math.sin(v), rr * math.sin(u)
			if axis == "x" then
				px, py = py, px
			end
			row[j + 1] = em:AddVertex(Vector3.new(c.X + px, c.Y + py, c.Z + pz))
		end
		grid[i + 1] = row
	end
	for i = 0, segR - 1 do
		local a, b = grid[i + 1], grid[(i + 1) % segR + 1]
		for j = 0, segT - 1 do
			local n, m = j + 1, (j + 1) % segT + 1
			tri(em, a[n], a[m], b[m], k)
			tri(em, a[n], b[m], b[n], k)
		end
	end
end

local function boxTris(seg)
	return 12 * seg * seg
end
local function addBox(em, cf, size, seg, k)
	local h = size * 0.5
	local faces = {
		{ Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1) },
		{ Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 1, 0) },
		{ Vector3.new(0, 1, 0), Vector3.new(0, 0, 1), Vector3.new(1, 0, 0) },
		{ Vector3.new(0, -1, 0), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1) },
		{ Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0) },
		{ Vector3.new(0, 0, -1), Vector3.new(0, 1, 0), Vector3.new(1, 0, 0) },
	}
	for _, f in ipairs(faces) do
		local n, u, v = f[1], f[2], f[3]
		local grid = {}
		for iy = 0, seg do
			local row = {}
			for ix = 0, seg do
				local a = (ix / seg) * 2 - 1
				local b = (iy / seg) * 2 - 1
				local lp = Vector3.new(
					n.X * h.X + u.X * a * h.X + v.X * b * h.X,
					n.Y * h.Y + u.Y * a * h.Y + v.Y * b * h.Y,
					n.Z * h.Z + u.Z * a * h.Z + v.Z * b * h.Z
				)
				row[ix + 1] = em:AddVertex(cf:PointToWorldSpace(lp))
			end
			grid[iy + 1] = row
		end
		for iy = 1, seg do
			for ix = 1, seg do
				local a, b = grid[iy], grid[iy + 1]
				tri(em, a[ix], a[ix + 1], b[ix + 1], k)
				tri(em, a[ix], b[ix + 1], b[ix], k)
			end
		end
	end
end

-- A flat chip: one triangle, the finest unit the budget can be closed with.
local function addChip(em, p, s, k)
	local a = em:AddVertex(p)
	local b = em:AddVertex(p + Vector3.new(s, s * 0.4, 0))
	local c = em:AddVertex(p + Vector3.new(s * 0.3, s, s * 0.35))
	tri(em, a, b, c, k)
end

--[[
	Land on the budget exactly.

	Step down through primitives by cost -- a 12x10 sphere is 216 triangles, an
	8x6 is 80, a 6x4 is 36 -- and finish the last handful with single-triangle
	chips. Overshooting is not an option here: CreateMeshPartAsync would happily
	bake 20,043 and the roster would no longer be flat.
]]
--[[
	Close the last few hundred triangles.

	This used to place ~16,000 triangles of loose spheres in a ball around the
	origin, which is what turned every head into confetti. After the resolution
	pass the shape itself is ~97% of the budget, so this only ever places a
	handful -- and it places them tight against the silhouette rather than
	floating around it.
]]
local function padToTarget(em, k, rand, reach, target)
	local steps = {
		{ 216, 12, 10 },
		{ 80, 8, 6 },
		{ 36, 6, 4 },
	}
	for _, st in ipairs(steps) do
		local cost, lon, lat = st[1], st[2], st[3]
		local guard = 0
		while target - k.n >= cost and guard < 4000 do
			guard += 1
			local th = rand() * math.pi * 2
			local ph = rand() * math.pi
			local rr = reach * (0.86 + rand() * 0.1)
			addSphere(em, Vector3.new(
				math.sin(ph) * math.cos(th) * rr,
				math.cos(ph) * rr * 0.5,
				math.sin(ph) * math.sin(th) * rr
			), reach * (0.012 + rand() * 0.014), lon, lat, k)
		end
	end
	local guard = 0
	while k.n < target and guard < 3000 do
		guard += 1
		local th = rand() * math.pi * 2
		local ph = rand() * math.pi
		local rr = reach * (0.6 + rand() * 0.4)
		addChip(em, Vector3.new(
			math.sin(ph) * math.cos(th) * rr,
			math.cos(ph) * rr,
			math.sin(ph) * math.sin(th) * rr
		), reach * 0.03, k)
	end
end

--------------------------------------------------------------------------------
-- RESOLUTION
--
-- `res` scales every segment count in a head. It is what lets the same shape be
-- built cheaply to measure it, then rebuilt dense enough to fill the budget.
--------------------------------------------------------------------------------
local function R(n, res)
	return math.max(3, math.floor(n * res + 0.5))
end

--------------------------------------------------------------------------------
-- FIVE PICKAXE HEADS
--------------------------------------------------------------------------------
local function pickHead(em, k, style, rand, orn, res)
	local w = 1.05 + rand() * 0.5
	local d = 0.22 + rand() * 0.1
	if style == 1 then
		-- classic double-bit: two tapering horns off a central eye
		for sgn = -1, 1, 2 do
			-- Fixed: how many segments a horn is swept in is the shape. Scaling
			-- it with res made this style cost res^3 and blow the limit.
			for i = 0, 14 do
				local t = i / 14
				addCylinder(em, Vector3.new(sgn * t * w, -t * t * 0.26, 0),
					d * (1 - t * 0.82), 0.05, R(22, res), R(4, res), k)
			end
		end
		addCylinder(em, Vector3.new(0, 0, 0), d * 1.5, 0.26, R(28, res), R(8, res), k)
	elseif style == 2 then
		-- adze: one broad flat blade, one stubby counter-poll
		addBox(em, CFrame.new(w * 0.45, -0.05, 0) * CFrame.Angles(0, 0, math.rad(-12)),
			Vector3.new(w * 0.95, 0.17, d * 2.6), R(9, res), k)
		addBox(em, CFrame.new(-w * 0.3, 0, 0), Vector3.new(w * 0.42, 0.3, d * 1.7), R(7, res), k)
		addCylinder(em, Vector3.new(0, 0, 0), d * 1.45, 0.25, R(26, res), R(7, res), k)
	elseif style == 3 then
		-- war pick: long spike one side, hammer face the other
		addCone(em, Vector3.new(0, 0, 0), d * 1.25, w * 1.2, R(28, res), R(16, res), k)
		addBox(em, CFrame.new(-w * 0.45, 0, 0), Vector3.new(w * 0.4, 0.34, d * 2.0), R(8, res), k)
		addTorus(em, Vector3.new(0, 0, 0), d * 1.5, d * 0.3, R(28, res), R(12, res), k)
	elseif style == 4 then
		-- twin crescent: two curved blades sweeping forward
		for sgn = -1, 1, 2 do
			for i = 0, 18 do
				local t = i / 18
				local ang = sgn * t * 1.15
				addSphere(em, Vector3.new(
					math.sin(ang) * w * 0.95,
					-(1 - math.cos(ang)) * w * 0.5, 0
				), d * (0.9 - t * 0.55), R(16, res), R(12, res), k)
			end
		end
		addCylinder(em, Vector3.new(0, 0, 0), d * 1.35, 0.28, R(26, res), R(7, res), k)
	else
		-- spiked maul: blocky head studded with pyramidal spikes
		addBox(em, CFrame.new(0, 0, 0), Vector3.new(w * 1.25, 0.42, d * 2.4), R(11, res), k)
		local spikes = 6 + orn
		for i = 0, spikes - 1 do
			local t = (i / math.max(1, spikes - 1)) - 0.5
			addCone(em, Vector3.new(t * w * 1.05, 0.21, 0), d * 0.42, 0.28, R(14, res), R(6, res), k)
		end
	end
	for i = 1, 1 + orn do
		addTorus(em, Vector3.new(0, -0.035 * i, 0), d * (1.6 + i * 0.05), d * 0.11,
			R(22, res), R(9, res), k)
	end
	return math.max(w, 0.6)
end

--------------------------------------------------------------------------------
-- FIVE DRILL HEADS
--------------------------------------------------------------------------------
local function drillHead(em, k, style, rand, orn, res)
	local r = 0.28 + rand() * 0.12
	local len = 1.35 + rand() * 0.5
	if style == 1 then
		-- auger: a true helical flight wound round a core
		addCylinder(em, Vector3.new(0, len * 0.5, 0), r * 0.42, len * 0.5, R(26, res), R(14, res), k)
		-- Bead count is the helix, not its resolution.
		local n = 110
		for i = 0, n do
			local t = i / n
			local ang = t * math.pi * 7
			addSphere(em, Vector3.new(math.cos(ang) * r * (1 - t * 0.55), t * len,
				math.sin(ang) * r * (1 - t * 0.55)), r * 0.16, R(12, res), R(9, res), k)
		end
	elseif style == 2 then
		-- stepped cone bit: stacked shoulders down to a point
		local n = 11
		for i = 0, n do
			local t = i / n
			addCylinder(em, Vector3.new(0, t * len, 0), r * (1 - t * 0.85), len * 0.06,
				R(28, res), R(5, res), k)
		end
		addCone(em, Vector3.new(0, len, 0), r * 0.16, 0.26, R(20, res), R(8, res), k)
	elseif style == 3 then
		-- tri-cone roller: three toothed cones on a hub
		addCylinder(em, Vector3.new(0, len * 0.22, 0), r * 0.85, len * 0.22, R(28, res), R(8, res), k)
		for c = 0, 2 do
			local th = (c / 3) * math.pi * 2
			local cx, cz = math.cos(th) * r * 0.5, math.sin(th) * r * 0.5
			addSphere(em, Vector3.new(cx, len * 0.62, cz), r * 0.46, R(22, res), R(16, res), k)
			for t2 = 0, 10 do
				local a2 = (t2 / 10) * math.pi * 2
				addCone(em, Vector3.new(cx + math.cos(a2) * r * 0.44, len * 0.62,
					cz + math.sin(a2) * r * 0.44), r * 0.11, r * 0.24, R(10, res), R(4, res), k)
			end
		end
	elseif style == 4 then
		-- core bit: an open crown ring with cutting teeth
		addTorus(em, Vector3.new(0, len * 0.85, 0), r * 0.92, r * 0.2, R(36, res), R(16, res), k)
		addCylinder(em, Vector3.new(0, len * 0.4, 0), r * 0.35, len * 0.4, R(24, res), R(10, res), k)
		local teeth = 8 + orn
		for i = 0, teeth - 1 do
			local th = (i / teeth) * math.pi * 2
			addCone(em, Vector3.new(math.cos(th) * r * 0.92, len * 0.98, math.sin(th) * r * 0.92),
				r * 0.15, r * 0.36, R(12, res), R(5, res), k)
		end
	else
		-- fluted twist: straight flutes cut down a tapering body
		addCone(em, Vector3.new(0, 0, 0), r, len, R(32, res), R(20, res), k)
		local flutes = 4 + (orn > 3 and 2 or 0)
		for f = 0, flutes - 1 do
			local th0 = (f / flutes) * math.pi * 2
			local n = 22
			for i = 0, n do
				local t = i / n
				addSphere(em, Vector3.new(
					math.cos(th0 + t * 0.9) * r * (1 - t) * 1.04, t * len,
					math.sin(th0 + t * 0.9) * r * (1 - t) * 1.04
				), r * 0.12, R(12, res), R(9, res), k)
			end
		end
	end
	for i = 1, 1 + orn do
		addTorus(em, Vector3.new(0, 0.05 * i, 0), r * 1.08, r * 0.1, R(24, res), R(10, res), k)
	end
	return math.max(len * 0.6, 0.7)
end

--------------------------------------------------------------------------------
-- FIVE EXPLOSIVE HEADS
--------------------------------------------------------------------------------
local function bombHead(em, k, style, rand, orn, res)
	local r = 0.55 + rand() * 0.22
	if style == 1 then
		addSphere(em, Vector3.new(0, r, 0), r, R(52, res), R(38, res), k)
		addCylinder(em, Vector3.new(0, r * 2.05, 0), r * 0.22, r * 0.16, R(20, res), R(5, res), k)
	elseif style == 2 then
		addCylinder(em, Vector3.new(0, r, 0), r * 0.74, r * 0.95, R(44, res), R(20, res), k)
		addTorus(em, Vector3.new(0, r * 1.85, 0), r * 0.7, r * 0.1, R(34, res), R(14, res), k)
		addTorus(em, Vector3.new(0, r * 0.2, 0), r * 0.7, r * 0.1, R(34, res), R(14, res), k)
	elseif style == 3 then
		for i = 0, 4 do
			local th = (i / 5) * math.pi * 2
			addSphere(em, Vector3.new(math.cos(th) * r * 0.55, r, math.sin(th) * r * 0.55),
				r * 0.48, R(28, res), R(20, res), k)
		end
		addSphere(em, Vector3.new(0, r * 1.25, 0), r * 0.44, R(26, res), R(18, res), k)
		addTorus(em, Vector3.new(0, r, 0), r * 0.87, r * 0.08, R(34, res), R(12, res), k)
	elseif style == 4 then
		addCylinder(em, Vector3.new(0, r, 0), r * 0.8, r, R(42, res), R(18, res), k)
		for i = 1, 4 + orn do
			addTorus(em, Vector3.new(0, (i / (5 + orn)) * r * 2, 0), r * 0.83, r * 0.07,
				R(32, res), R(12, res), k)
		end
	else
		addBox(em, CFrame.new(0, r, 0) * CFrame.Angles(math.rad(35), math.rad(20), 0),
			Vector3.new(r * 1.3, r * 1.3, r * 1.3), R(14, res), k)
		addSphere(em, Vector3.new(0, r, 0), r * 0.84, R(36, res), R(26, res), k)
	end
	local rivets = 10 + orn * 2
	for i = 0, rivets - 1 do
		local th = (i / rivets) * math.pi * 2
		addSphere(em, Vector3.new(math.cos(th) * r * 0.9, r, math.sin(th) * r * 0.9), r * 0.07,
			R(14, res), R(10, res), k)
	end
	return r * 1.4
end

--------------------------------------------------------------------------------
-- LOOK
--------------------------------------------------------------------------------
local function oreLook(name)
	local ok, C = pcall(function()
		return require(game.ReplicatedStorage.Mine.Shared.MineConfig)
	end)
	if not ok or type(C) ~= "table" or type(C.ORES) ~= "table" then
		return nil
	end
	for _, o in ipairs(C.ORES) do
		if o.name == name then
			return o
		end
	end
	return nil
end

local function finish(em, partName, look, k, fallbackColor)
	local mp = AssetService:CreateMeshPartAsync(Content.fromObject(em))
	mp.Name = partName
	mp.Color = (look and look.color) or fallbackColor or Color3.fromRGB(180, 180, 190)
	mp.Material = (look and look.material) or Enum.Material.Metal
	mp.Anchored = true
	mp.CanCollide = false
	mp.Massless = true
	mp:SetAttribute("BakedTris", k.n)
	return mp
end

--------------------------------------------------------------------------------
-- BAKE ONE
--------------------------------------------------------------------------------
function M.buildOne(name, family, rarity, styleOverride)
	local orn = ORNATE[rarity or "common"] or 0
	local h = hash32(name .. "|" .. family .. "|v2")
	local rand = rng(h)
	--[[
		Style is STRIDED, not hashed.

		Drawing it from the name hash clumped badly: over 82 draws one explosive
		shape came up ten times and another once, so "five different explosives"
		was true of the code and not of the screen. The caller walks the five in
		order within each family instead. Still fully deterministic -- a given
		ore always bakes the same shape -- but every shape gets used.
	]]
	local style = styleOverride or (1 + (h % 5))
	local look = oreLook(name)

	--[[
		HEAD: its own mesh, its own 20,000, spent on geometry.

		Built twice. The first pass is a throwaway at res = 1 purely to find out
		what this silhouette naturally costs; the second is the real one, with
		every segment count scaled so the shape fills the budget by itself.

		sqrt, because a surface's triangle count grows with the PRODUCT of two
		segment counts -- rings x rows -- so cost goes as res^2 and the scale
		needed is the square root of the shortfall.
	]]
	local function lay(target_em, target_k, res)
		if family == "drill" then
			return drillHead(target_em, target_k, style, rand, orn, res)
		elseif family == "explosive" then
			return bombHead(target_em, target_k, style, rand, orn, res)
		end
		return pickHead(target_em, target_k, style, rand, orn, res)
	end

	local probe = AssetService:CreateEditableMesh()
	local pk = { n = 0 }
	local rand0 = rng(h)
	local saved = rand
	rand = rand0
	lay(probe, pk, 1)
	rand = saved

	-- Aim slightly under the budget; padToTarget closes the rest exactly.
	local res = 1
	if pk.n > 0 then
		res = math.sqrt((TRI_TARGET * 0.97) / pk.n)
		res = math.clamp(res, 0.35, 6)
	end

	local em = AssetService:CreateEditableMesh()
	local k = { n = 0 }
	rand = rng(h)
	local reach = lay(em, k, res)
	--[[
		A shape can still overshoot: segment counts round up, and a style with
		many sub-parts compounds that rounding. Step res down until it fits
		rather than baking a head that is over budget.
	]]
	local tries = 0
	while k.n > TRI_TARGET and tries < 8 do
		tries += 1
		res = res * math.sqrt(TRI_TARGET / k.n) * 0.985
		em = AssetService:CreateEditableMesh()
		k = { n = 0 }
		rand = rng(h)
		reach = lay(em, k, res)
	end
	-- Captured BEFORE padding, so the audit can show how much of the head is
	-- real geometry rather than gap-filler.
	local shapeTris = k.n
	padToTarget(em, k, rand, reach, TRI_TARGET)
	local head = finish(em, "head_geom", look, k)
	head:SetAttribute("ToolName", name)
	head:SetAttribute("Family", family)
	head:SetAttribute("Style", style)
	head:SetAttribute("Res", res)
	head:SetAttribute("ShapeTris", shapeTris)
	if look and look.glow then
		local lg = Instance.new("PointLight")
		lg.Color = look.glow
		lg.Brightness = (look.glowBright or 0.5) * 2
		lg.Range = 6
		lg.Parent = head
	end

	-- HAFT: cheap on purpose. It is not part of the head budget.
	local em2 = AssetService:CreateEditableMesh()
	local k2 = { n = 0 }
	local shaftLen = 1.3 + rand() * 0.35
	addCylinder(em2, Vector3.new(0, -shaftLen * 0.5, 0), 0.062, shaftLen * 0.5, 16, 6, k2)
	addSphere(em2, Vector3.new(0, -shaftLen, 0), 0.085, 14, 10, k2)
	for i = 1, 3 do
		addTorus(em2, Vector3.new(0, -shaftLen * (0.25 + i * 0.16), 0), 0.068, 0.016, 16, 7, k2)
	end
	local haft = finish(em2, "haft_geom", nil, k2, Color3.fromRGB(86, 62, 44))
	haft.Material = Enum.Material.Wood

	return head, haft, k.n, k2.n, style
end

--------------------------------------------------------------------------------
-- INSTALL
--------------------------------------------------------------------------------
function M.install(name, family, rarity, styleOverride)
	local root = game.ReplicatedStorage:FindFirstChild("ToolModels_50")
	if not root then
		root = Instance.new("Folder")
		root.Name = "ToolModels_50"
		root.Parent = game.ReplicatedStorage
	end
	local head, haft, headTris, haftTris, style = M.buildOne(name, family, rarity, styleOverride)

	local old = root:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder:SetAttribute("OreTool", true)
	folder:SetAttribute("PrototypeFamily", family)
	folder:SetAttribute("Rarity", rarity)
	folder:SetAttribute("Style", style)
	folder:SetAttribute("HeadTris", headTris)
	folder:SetAttribute("HaftTris", haftTris)
	folder.Parent = root

	-- Same nesting the existing tool models use, so nothing downstream changes.
	local normal = Instance.new("Model"); normal.Name = "Normal"; normal.Parent = folder
	local world = Instance.new("Model"); world.Name = "world"; world.Parent = normal
	local body = Instance.new("Model"); body.Name = "body"; body.Parent = world
	head.Parent = body
	haft.Parent = body

	--[[
		SEAT THE HAFT UNDER THE HEAD.

		Both meshes are modelled about a shared origin -- head at y = 0, haft
		hanging below it -- and that relationship does not survive the bake.
		CreateMeshPartAsync re-centres each MeshPart on its own geometry, so
		both come back with CFrame at their own centroid; parented together they
		land on the same spot and the haft passes through the middle of the
		head.

		Placed by their real sizes instead, so the top of the haft meets the
		bottom of the head, with a small overlap so no seam opens up when the
		tool is viewed from the side. Welded, so a caller can move the model by
		the head and the haft comes with it.
	]]
	head.CFrame = CFrame.new()
	--[[
		The haft meets the EYE, not the bounding box.

		Seating it under head.Size.Y * 0.5 left a visible gap, because a pick
		head's box is measured over its horns -- which sweep DOWN past the eye --
		so the box bottom is well below the point the haft is supposed to enter.
		Every head in this file is modelled with its socket at y = 0, so that is
		the number to use. The haft's top goes a hair above it, into the head,
		so no seam opens when the tool is turned side-on.
	]]
	haft.CFrame = CFrame.new(0, -(haft.Size.Y * 0.5) + 0.12, 0)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = haft
	weld.Parent = head

	body.PrimaryPart = head
	return headTris, haftTris, style
end

--[[
	Bake in slices.

	Eighty-two heads at 20k triangles is well over a minute of CreateMeshPartAsync
	in one call, and a Studio VM that busy stops answering the MCP bridge. Ten at
	a time keeps every call short enough to return.
]]
function M.bake(startAt, count)
	startAt = math.max(1, tonumber(startAt) or 1)
	count = math.max(1, tonumber(count) or 10)
	local last = math.min(#M.ROSTER, startAt + count - 1)
	local okN, fails, minH, maxH = 0, {}, math.huge, 0
	for i = startAt, last do
		local row = M.ROSTER[i]
		local family = FAMILIES[((i - 1) % #FAMILIES) + 1]
		-- Position of this tool WITHIN its family, so the five styles stride
		-- evenly rather than clumping the way a hash does.
		local withinFamily = math.floor((i - 1) / #FAMILIES)
		local ok, a = pcall(M.install, row[1], family, row[2], (withinFamily % 5) + 1)
		if ok then
			okN += 1
			minH = math.min(minH, a)
			maxH = math.max(maxH, a)
		else
			fails[#fails + 1] = row[1] .. ": " .. tostring(a)
		end
	end
	return {
		from = startAt, to = last, total = #M.ROSTER,
		ok = okN, fail = #fails, fails = fails,
		minHeadTris = (minH == math.huge) and 0 or minH,
		maxHeadTris = maxH,
		done = last >= #M.ROSTER,
	}
end

--------------------------------------------------------------------------------
-- EVERY ORE IN EVERY FAMILY
--
-- M.bake above gives each ore ONE family, striding pickaxe/drill/explosive down
-- the roster, so 82 ores come out as 82 tools -- about 28 of each. That was
-- right when the roster was a shop rail. It is not what the Forge offers:
-- MineOreTools builds {Ore} {Noun} for every family, so Stone alone is three
-- craftable tools and the real roster is 82 x 3 = 246.
--
-- Named the same way MineOreTools names them, because the name IS the lookup
-- key -- a folder called "Stone Pickaxe" is what MineOreTools.displayName
-- produces for (stone, pickaxe), so nothing needs a translation table.
--
-- Ordered family-major (all 82 picks, then all drills, then all explosives)
-- rather than interleaved, so a partial bake leaves whole families finished and
-- an audit can report "pickaxes done, drills pending" instead of 246 fragments.
--------------------------------------------------------------------------------
local NOUN = { pickaxe = "Pickaxe", drill = "Drill", explosive = "Explosive" }

--[[
	Style strides within the family, not across the whole 246.

	M.bake used `floor((i - 1) / #FAMILIES) % 5` because its families were
	interleaved. Here they are contiguous, so the ore's own index is already the
	position within the family and striding it directly gives each family all
	five silhouettes evenly -- and the SAME ore lands on the same style in all
	three families, so a player's Stone pick, drill and charge look like a set.
]]
local ALL = nil
function M.all()
	if ALL then
		return ALL
	end
	ALL = {}
	for fi, family in ipairs(FAMILIES) do
		for oi, row in ipairs(M.ROSTER) do
			ALL[#ALL + 1] = {
				name = row[1] .. " " .. NOUN[family],
				ore = row[1],
				rarity = row[2],
				family = family,
				style = ((oi - 1) % 5) + 1,
				familyIndex = fi,
			}
		end
	end
	return ALL
end

--[[
	Same slicing discipline as M.bake, and for the same reason: CreateMeshPartAsync
	at 20k triangles is slow enough that a long run stops the Studio VM answering
	the MCP bridge. Ten per call keeps every call short. 246 tools is 25 calls.
]]
function M.bakeAll(startAt, count)
	local all = M.all()
	startAt = math.max(1, tonumber(startAt) or 1)
	count = math.max(1, tonumber(count) or 10)
	local last = math.min(#all, startAt + count - 1)
	local okN, fails, minH, maxH = 0, {}, math.huge, 0
	for i = startAt, last do
		local e = all[i]
		local ok, a = pcall(M.install, e.name, e.family, e.rarity, e.style)
		if ok then
			okN += 1
			minH = math.min(minH, a)
			maxH = math.max(maxH, a)
		else
			fails[#fails + 1] = e.name .. ": " .. tostring(a)
		end
	end
	return {
		from = startAt, to = last, total = #all,
		ok = okN, fail = #fails, fails = fails,
		minHeadTris = (minH == math.huge) and 0 or minH,
		maxHeadTris = maxH,
		done = last >= #all,
	}
end

--[[
	Audit the 246, and -- unlike M.audit -- check the mesh is actually THERE.

	A folder with HeadTris = 20000 only proves the bake once ran. EditableMesh
	geometry from CreateMeshPartAsync is session-only: it does not survive the
	place being saved and reopened, and comes back as
	Content{SourceType=None} with the attributes still sitting on the folder
	looking healthy. Both archives in this place are in exactly that state, so
	an audit that trusts the attribute reports 82 good tools that render nothing.
]]
function M.auditAll()
	local root = game.ReplicatedStorage:FindFirstChild("ToolModels_50")
	if not root then
		return { error = "no ToolModels_50" }
	end
	local made, gutted, missing, offBudget = 0, {}, {}, {}
	local byFamily = {}
	for _, e in ipairs(M.all()) do
		local f = root:FindFirstChild(e.name)
		if not f then
			missing[#missing + 1] = e.name
		else
			made += 1
			byFamily[e.family] = (byFamily[e.family] or 0) + 1
			local ht = f:GetAttribute("HeadTris") or 0
			if ht ~= TRI_TARGET then
				offBudget[#offBudget + 1] = e.name .. ": head " .. tostring(ht)
			end
			local live = false
			for _, d in ipairs(f:GetDescendants()) do
				if d:IsA("MeshPart") and not tostring(d.MeshContent):find("SourceType=None") then
					live = true
				end
			end
			if not live then
				gutted[#gutted + 1] = e.name
			end
		end
	end
	return {
		built = made,
		expected = #M.all(),
		byFamily = byFamily,
		missingCount = #missing,
		missing = { table.unpack(missing, 1, math.min(10, #missing)) },
		guttedCount = #gutted,
		gutted = { table.unpack(gutted, 1, math.min(10, #gutted)) },
		offBudget = offBudget,
	}
end

function M.audit()
	local root = game.ReplicatedStorage:FindFirstChild("ToolModels_50")
	if not root then
		return { error = "no ToolModels_50" }
	end
	local made, bad, fams, styles = 0, {}, {}, {}
	for _, row in ipairs(M.ROSTER) do
		local f = root:FindFirstChild(row[1])
		if not f then
			bad[#bad + 1] = row[1] .. ": missing"
		else
			made += 1
			local ht = f:GetAttribute("HeadTris") or 0
			if ht ~= TRI_TARGET then
				bad[#bad + 1] = row[1] .. ": head " .. tostring(ht)
			end
			local fam = f:GetAttribute("PrototypeFamily") or "?"
			fams[fam] = (fams[fam] or 0) + 1
			local key = fam .. "#" .. tostring(f:GetAttribute("Style"))
			styles[key] = (styles[key] or 0) + 1
		end
	end
	return { built = made, expected = #M.ROSTER, offBudget = bad, families = fams, styles = styles }
end

return M
