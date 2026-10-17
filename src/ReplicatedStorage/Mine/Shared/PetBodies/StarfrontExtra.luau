--[[ PetBodies/StarfrontExtra -- more Starfront recolour bodies (Common,
	Uncommon and Rare), so pets that share a body can stay vastly different
	colours. Grounded space exploration. See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block, ears, wings = K.C3, K.block, K.ears, K.wings
	local WHITE, METAL, NEON, GLASS = K.WHITE, K.METAL, K.NEON, K.GLASS
	local S = {}

	local V, CF = Vector3.new, CFrame.new
	local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2) -- stands a cylinder's X axis up
	local FACE_Z = CFrame.Angles(0, math.pi / 2, 0) -- turns a cylinder's X axis to face +Z

	-- A space pup: floppy ears, a glass bubble over its head, twin air tanks.
	S.sf_helmetpup = {
		label = "Helmet Pup",
		set = "starfront",
		tint = C3(214, 168, 112),
		head = CF(0, 1.54, 0.20),
		neck = CF(0, -0.56, 0.90),
		back = CF(0, 0.20, -1.10),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				snout = { w = 0.66, h = 0.44, d = 0.40, y = -0.24, color = p.pale },
				legColor = p.dark, tailSize = V(0.30, 0.30, 0.50),
			})
			ears(c, p.dark, "down")
			c:ball(V(1.30, 1.30, 1.30), CF(0, 0.86, 0.20), C3(190, 230, 255), GLASS)
			for _, s in ipairs({ -1, 1 }) do
				c:cyl(V(0.70, 0.30, 0.30), CF(0.30 * s, 0.50, -0.86) * UPRIGHT, p.light, METAL)
			end
			c:box(V(1.20, 0.14, 0.20), CF(0, -0.56, 0.86), p.light)
			c:ball(V(0.16, 0.16, 0.16), CF(0, -0.68, 0.96), p.glow, NEON)
		end,
	}

	-- A cratered moon rock with stubby feet and a tiny flag planted on top.
	S.sf_craterrock = {
		label = "Crater Rock",
		set = "starfront",
		tint = C3(150, 146, 160),
		head = CF(-0.30, 1.04, 0.20),
		neck = CF(0, -0.36, 0.92),
		back = CF(0, 0.20, -0.92),
		build = function(c, p)
			block(c, p, {
				shape = "round", legs = false, tail = false,
				eyeSize = V(0.44, 0.52, 0.20), eyeSpread = 0.40, mouthY = -0.30,
			})
			for _, v in ipairs({
				{ V(0.70, 0.50, 0.70), CF(-0.60, 0.86, -0.20) * CFrame.Angles(0.2, 0.5, 0.1) },
				{ V(0.50, 0.60, 0.60), CF(0.96, -0.30, -0.30) * CFrame.Angles(0.3, 0.2, 0.4) },
				{ V(0.50, 0.40, 0.50), CF(0.40, 0.90, -0.60) * CFrame.Angles(0.1, 0.8, 0.2) },
			}) do
				c:box(v[1], v[2], p.light)
			end
			for _, at in ipairs({ CF(0.50, 0.98, 0.30), CF(-0.40, 0.98, 0.50) }) do
				c:box(V(0.40, 0.08, 0.40), at, p.pale)
				c:box(V(0.26, 0.09, 0.26), at, p.deep)
			end
			c:box(V(0.06, 0.40, 0.40), CF(-1.05, -0.10, 0.10), p.deep)
			c:box(V(0.40, 0.40, 0.06), CF(0.20, 0.20, -0.88), p.deep)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.40, 0.24, 0.50), CF(0.50 * s, -0.86, 0.20), p.dark)
			end
			c:rod(V(0.10, 0.96, -0.10), V(0.10, 1.56, -0.10), 0.025, WHITE, nil, false)
			c:box(V(0.04, 0.24, 0.38), CF(0.10, 1.44, 0.10), p.glow)
		end,
	}

	-- A navigation buoy: a diamond of pyramid cap and keel, a wide collar, a beacon.
	S.sf_navbuoy = {
		label = "Nav Buoy",
		set = "starfront",
		tint = C3(236, 96, 64),
		scale = 1.15,
		head = CF(0, 1.94, 0),
		neck = CF(0, -0.50, 0.82),
		back = CF(0, 0.06, -0.82),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.60, 1.10, 1.60), legs = false, tail = false,
				eyeY = 0.04, eyeSpread = 0.34, eyeSize = V(0.42, 0.48, 0.20), mouthY = -0.30,
			})
			c:cone(V(1.60, 0.80, 1.60), CF(0, 1.01, 0), p.light)
			c:cone(V(1.60, 0.70, 1.60), CF(0, -0.84, 0) * CFrame.Angles(math.pi, 0, 0), p.dark)
			c:box(V(1.70, 0.14, 1.70), CF(0, 0.56, 0), p.pale)
			c:cyl(V(0.10, 2.30, 2.30), CF(0, -0.36, 0) * UPRIGHT, p.deep)
			for k = 0, 3 do
				local a = math.pi / 4 + k * math.pi / 2
				c:box(V(0.20, 0.20, 0.20), CF(math.cos(a) * 1.08, -0.24, math.sin(a) * 1.08), p.glow, NEON)
			end
			c:rod(V(0, 1.38, 0), V(0, 1.66, 0), 0.04, p.dark, METAL, false)
			c:ball(V(0.26, 0.26, 0.26), CF(0, 1.76, 0), p.glow, NEON)
		end,
	}

	-- A star-gazing owl: goggles round both eyes, ear tufts, a pocket telescope.
	S.sf_astroowl = {
		label = "Astro Owl",
		set = "starfront",
		tint = C3(120, 96, 200),
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.40, 0.90),
		back = CF(0, 0.20, -0.86),
		build = function(c, p)
			block(c, p, {
				shape = "bird", mouth = false, tail = false,
				eyeSize = V(0.48, 0.52, 0.20), eyeSpread = 0.40, eyeY = 0.24,
				legSize = V(0.30, 0.30, 0.40), legX = 0.36, legZ = { 0.10 },
				bib = { w = 0.96, h = 0.70, y = -0.38, color = p.pale },
			})
			for _, s in ipairs({ -1, 1 }) do
				c:cyl(V(0.06, 0.70, 0.70), CF(0.40 * s, 0.24, 0.92) * FACE_Z, p.dark, METAL)
			end
			c:box(V(0.24, 0.08, 0.10), CF(0, 0.24, 0.96), p.dark, METAL)
			c:cone(V(0.22, 0.28, 0.20), CF(0, -0.06, 0.96) * CFrame.Angles(math.pi, 0, 0), C3(255, 186, 60))
			ears(c, p.dark, "tuft")
			wings(c, p.dark, 0.26, 0.00, -0.10, 0.20)
			c:cyl(V(0.70, 0.20, 0.20), CF(-1.10, -0.50, 0.30) * CFrame.Angles(0, 0.6, 0.3), p.light, METAL)
			c:cyl(V(0.06, 0.16, 0.16), CF(-1.38, -0.42, 0.52) * CFrame.Angles(0, 0.6, 0.3), p.glow, NEON)
		end,
	}

	return S
end
