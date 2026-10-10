--[[ PetBodies/CrystalHollow -- Crystal Hollow's bodies: minerals, geodes and
	crystal formations, each a different crystal habit (a geode's cut face,
	pointed quartz, cubic pyrite, bladed gypsum, a hexagonal column). See
	tools/gen/sets/README.md. ]]
return function(K)
	local C3, block, ears = K.C3, K.block, K.ears
	local WHITE, METAL, GLASS, SLATE = K.WHITE, K.METAL, K.GLASS, K.SLATE
	local S = {}

	-- A crystal point: a square shaft turned 45 degrees and a pyramid tip,
	-- tilted from its root by `ax` (back/forward) and `az` (sideways).
	local function point(c, root, ax, az, w, h, colour)
		local cf = CFrame.new(root) * CFrame.Angles(ax, 0, az)
		local turn = CFrame.Angles(0, math.pi / 4, 0)
		c:box(Vector3.new(w, h, w), cf * CFrame.new(0, h * 0.5, 0) * turn, colour, GLASS)
		c:cone(Vector3.new(w, w * 1.1, w), cf * CFrame.new(0, h + w * 0.55, 0) * turn, colour, GLASS)
	end

	-- A boulder sawn open: the cut face shows the rind, a white agate band and a
	-- crystal-lined hollow with teeth pointing in. A few crystals break the top.
	S.ch_geode = {
		label = "Geode",
		set = "crystal_hollow",
		tint = C3(152, 96, 214),
		head = CFrame.new(0, 1.04, 0.20),
		neck = CFrame.new(0, -0.36, 0.70),
		back = CFrame.new(0, 0.20, -0.96),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodyColor = p.dark, bodyMat = SLATE,
				eyeSize = Vector3.new(0.44, 0.52, 0.20), eyeSpread = 0.32, eyeY = 0.18,
				mouthY = -0.24, mouthSize = Vector3.new(0.26, 0.12, 0.12),
				legSize = Vector3.new(0.46, 0.30, 0.50), legColor = p.deep, tail = false,
			})
			-- The cut face, outside in: agate band, crystal hollow, bright heart.
			c:box(Vector3.new(1.62, 1.50, 0.20), CFrame.new(0, 0.08, 0.80), p.pale)
			c:box(Vector3.new(1.30, 1.18, 0.20), CFrame.new(0, 0.08, 0.83), p.base, GLASS)
			c:box(Vector3.new(0.92, 0.80, 0.20), CFrame.new(0, 0.10, 0.86), p.light)
			-- Crystal teeth round the hollow's rim, pointing inward.
			for _, t in ipairs({
				{ 0.62, 0.66 }, { -0.62, 0.66 }, { 0.62, -0.50 }, { -0.62, -0.50 },
				{ 0, 0.70 }, { 0, -0.56 }, { 0.70, 0.08 }, { -0.70, 0.08 },
			}) do
				local a = math.atan2(t[2] - 0.08, t[1])
				c:cone(Vector3.new(0.24, 0.32, 0.10), CFrame.new(t[1], t[2], 0.95) * CFrame.Angles(0, 0, a + math.pi / 2), WHITE, GLASS)
			end
			-- Rough rind lumps on the back.
			c:box(Vector3.new(0.70, 0.40, 0.60), CFrame.new(-0.40, 0.88, -0.40) * CFrame.Angles(0.3, 0.5, 0.2), p.deep, SLATE)
			c:box(Vector3.new(0.56, 0.50, 0.50), CFrame.new(0.60, 0.20, -0.78) * CFrame.Angles(0.4, 0.2, 0.5), p.deep, SLATE)
			c:box(Vector3.new(0.50, 0.40, 0.44), CFrame.new(-0.86, -0.36, -0.50) * CFrame.Angles(0.2, 0.7, 0.3), p.dark, SLATE)
			-- Two crystals breaking through the crown.
			point(c, Vector3.new(0.40, 0.86, -0.34), -0.25, -0.35, 0.28, 0.36, p.light)
			point(c, Vector3.new(0.08, 0.90, -0.58), -0.45, 0.25, 0.22, 0.26, p.base)
		end,
	}

	-- A little critter carrying a cluster of quartz points on its back.
	S.ch_quartzback = {
		label = "Quartzback",
		set = "crystal_hollow",
		tint = C3(236, 156, 192),
		-- The cluster makes it tall.
		scale = 1.16,
		head = CFrame.new(0, 1.04, 0.40),
		neck = CFrame.new(0, -0.30, 0.66),
		back = CFrame.new(0, 0.20, -0.66),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				snout = { w = 0.60, h = 0.42, d = 0.40, color = p.pale },
				legSize = Vector3.new(0.48, 0.38, 0.54), legColor = p.dark,
				tailSize = Vector3.new(0.40, 0.36, 0.50), tailColor = p.dark,
			})
			ears(c, p.dark, "round", p.pale)
			-- The cluster: a tall centre point and four leaning out round it.
			point(c, Vector3.new(0, 0.90, -0.42), -0.20, 0, 0.42, 0.74, p.light)
			point(c, Vector3.new(-0.46, 0.84, -0.30), -0.10, 0.50, 0.34, 0.52, p.pale)
			point(c, Vector3.new(0.46, 0.84, -0.38), -0.15, -0.50, 0.34, 0.58, p.pale)
			point(c, Vector3.new(-0.30, 0.80, -0.78), -0.60, 0.30, 0.30, 0.44, p.light)
			point(c, Vector3.new(0.32, 0.80, -0.76), -0.65, -0.30, 0.28, 0.38, p.base)
		end,
	}

	-- Cubic pyrite: a cube with smaller cubes grown through its corners at odd
	-- angles, glinting.
	S.ch_cubeling = {
		label = "Cubeling",
		set = "crystal_hollow",
		tint = C3(212, 180, 92),
		scale = 1.06,
		head = CFrame.new(0, 1.04, 0.30),
		neck = CFrame.new(0, -0.30, 0.62),
		back = CFrame.new(0, 0.20, -0.62),
		build = function(c, p)
			block(c, p, {
				square = true, bodyMat = METAL,
				mouthSize = Vector3.new(0.30, 0.14, 0.14), tail = false,
				legSize = Vector3.new(0.44, 0.34, 0.44), legColor = p.deep,
			})
			for _, k in ipairs({
				{ 0.92, -0.62, 0.92, -0.36, 0.35, 0.55, 0.25, p.light },
				{ 0.72, 0.78, 0.82, -0.34, 0.60, 0.20, 0.45, p.base },
				{ 0.84, 0.66, -0.10, -0.80, 0.25, 0.70, 0.15, p.dark },
				{ 0.60, -1.04, -0.26, 0.18, 0.50, 0.45, 0.10, p.light },
				{ 0.50, -0.20, 0.30, -1.02, 0.80, 0.30, 0.60, p.base },
			}) do
				c:box(Vector3.new(k[1], k[1], k[1]), CFrame.new(k[2], k[3], k[4]) * CFrame.Angles(k[5], k[6], k[7]), k[8], METAL)
			end
			-- Glints, and rosy cheeks.
			c:star(Vector3.new(-0.62, 1.52, -0.30), 0.34, WHITE)
			c:star(Vector3.new(1.16, 0.20, 0.50), 0.28, WHITE)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.24, 0.12, 0.06), CFrame.new(0.66 * s, -0.18, 0.92), C3(255, 150, 140))
			end
		end,
	}

	-- A desert rose: bladed crystals grown in petals round a sandy body, with a
	-- star of small blades on the crown.
	S.ch_desertrose = {
		label = "Desert Rose",
		set = "crystal_hollow",
		tint = C3(216, 164, 122),
		scale = 1.12,
		head = CFrame.new(0, 1.30, 0.06),
		neck = CFrame.new(0, -0.30, 0.62),
		back = CFrame.new(0, 0.20, -0.96),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.80, 1.70, 1.66),
				eyeSpread = 0.40, mouthY = -0.32,
				legSize = Vector3.new(0.40, 0.30, 0.44), legX = 0.48, legColor = p.dark, tail = false,
			})
			-- Each blade is a thin round disc standing edge-out, flared away from the body.
			local faceOut = CFrame.Angles(0, math.pi / 2, 0)
			local function blade(angle, y, r, d, tilt, colour)
				c:cyl(Vector3.new(0.08, d, d), CFrame.Angles(0, angle, 0) * CFrame.new(0, y, r) * CFrame.Angles(tilt, 0, 0) * faceOut, colour)
			end
			-- Lower ring of petals round the sides and back, leaving the face clear.
			for _, deg in ipairs({ 60, 120, 180, 240, 300 }) do
				blade(math.rad(deg), -0.20, 0.92, 1.00, 0.40, p.light)
			end
			-- Upper ring, offset.
			for _, deg in ipairs({ 90, 150, 210, 270 }) do
				blade(math.rad(deg), 0.48, 0.72, 0.86, 0.50, p.pale)
			end
			-- Crown: three blades crossed in a star.
			for _, deg in ipairs({ 0, 60, 120 }) do
				c:cyl(Vector3.new(0.08, 0.66, 0.66), CFrame.new(0, 1.04, -0.06) * CFrame.Angles(0, math.rad(deg), 0) * faceOut, p.pale)
			end
		end,
	}

	-- A hexagonal crystal column (beryl) with a pointed tip and a growth band,
	-- standing on the rock it grew from, two baby crystals at its feet.
	S.ch_hexling = {
		label = "Hexling",
		set = "crystal_hollow",
		tint = C3(56, 190, 120),
		-- Tall: the tip and the rock base.
		scale = 1.20,
		head = CFrame.new(0, 1.90, 0),
		neck = CFrame.new(0, -0.40, 0.98),
		back = CFrame.new(0, 0.20, -0.98),
		build = function(c, p)
			local R, H = 1.10, 1.86
			local hex = Vector3.new(R, H, R * math.sqrt(3))
			-- Three boxes turned 60 degrees apart make a hexagonal prism, with a flat
			-- facet facing forward for the face.
			block(c, p, {
				square = true, bodySize = hex, bodyMat = GLASS,
				eyeSize = Vector3.new(0.30, 0.40, 0.18), eyeSpread = 0.24, eyeY = 0.20,
				mouthSize = Vector3.new(0.22, 0.10, 0.12), mouthY = -0.12,
				legs = false, tail = false,
			})
			for _, a in ipairs({ math.pi / 3, -math.pi / 3 }) do
				c:box(hex, CFrame.new(0, 0.06, 0) * CFrame.Angles(0, a, 0), p.base, GLASS)
			end
			-- Pointed termination.
			for _, a in ipairs({ 0, math.pi / 4 }) do
				c:cone(Vector3.new(1.44, 0.90, 1.44), CFrame.new(0, 1.44, 0) * CFrame.Angles(0, a, 0), p.light, GLASS)
			end
			-- Growth band (a phantom line inside the crystal).
			for _, a in ipairs({ 0, math.pi / 3, -math.pi / 3 }) do
				c:box(Vector3.new(R + 0.04, 0.08, R * math.sqrt(3) + 0.06), CFrame.new(0, 0.62, 0) * CFrame.Angles(0, a, 0), p.pale)
			end
			-- The rock it grew from.
			c:box(Vector3.new(2.10, 0.34, 1.90), CFrame.new(0, -0.98, 0) * CFrame.Angles(0, 0.30, 0), p.deep, SLATE)
			c:box(Vector3.new(1.40, 0.30, 1.30), CFrame.new(0.30, -1.06, -0.20) * CFrame.Angles(0, -0.40, 0.06), p.dark, SLATE)
			-- Two baby crystals at its feet.
			point(c, Vector3.new(-0.72, -0.82, 0.34), 0.20, 0.70, 0.24, 0.30, p.light)
			point(c, Vector3.new(0.74, -0.82, -0.20), -0.10, -0.75, 0.22, 0.26, p.base)
			c:light(p.glow, 1.4, 7)
		end,
	}

	return S
end
