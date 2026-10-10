--[[ PetBodies/InfernalReign -- Infernal Reign's bodies: obsidian, forge iron and
	molten rock with glowing lava channels, kept cute (no demon faces).
	See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, WHITE, METAL, NEON, SLATE = K.INK, K.WHITE, K.METAL, K.NEON, K.SLATE
	local S = {}

	-- Lava and ember stay fixed: the glow is the set's signature, the rock repaints.
	local LAVA = C3(255, 116, 28)
	local EMBER = C3(255, 196, 70)
	local HORN = C3(236, 224, 200)
	local BRASS = C3(232, 186, 80)
	local SET = "infernal_reign"

	-- A little walking volcano: a rocky cone with ember eyes on its slope, stubby
	-- arms, lava bubbling in the crater and running down its sides.
	S.ir_volcano = {
		label = "Volcanoling",
		set = SET,
		tint = C3(66, 58, 76),
		scale = 0.94,
		head = CFrame.new(0, 0.88, 0),
		neck = CFrame.new(0, -0.62, 0.84),
		back = CFrame.new(0, -0.10, -0.66),
		build = function(c, p)
			-- Slope of the cone's faces (front/back and sides), and their normals.
			local a, b = math.atan(1.0 / 1.8), math.atan(1.05 / 1.8)
			local n = Vector3.new(0, math.sin(a), math.cos(a))
			local slope = CFrame.Angles(-a, 0, 0)
			c:cone(Vector3.new(2.10, 1.80, 2.00), CFrame.new(0, -0.10, 0), p.base, SLATE)
			-- Crater, lava pool, a popping bubble and a puff of smoke.
			c:box(Vector3.new(0.74, 0.30, 0.70), CFrame.new(0, 0.70, 0), p.dark, SLATE)
			c:box(Vector3.new(0.56, 0.06, 0.52), CFrame.new(0, 0.86, 0), LAVA, NEON)
			c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(0.10, 1.02, 0.05), LAVA, NEON)
			c:ball(Vector3.new(0.40, 0.40, 0.40), CFrame.new(-0.12, 1.20, -0.10), C3(170, 166, 170)).Transparency = 0.3
			-- Face on the front slope: ember eyes with dark pupils, and a smile.
			for _, s in ipairs({ -1, 1 }) do
				local at = Vector3.new(0.28 * s, -0.12, 0.51) + n * 0.05
				c:round(Vector3.new(0.38, 0.44, 0.14), CFrame.new(at) * slope, EMBER):SetAttribute("Eye", true)
				c:round(Vector3.new(0.22, 0.28, 0.10), CFrame.new(at + n * 0.05) * slope, INK):SetAttribute("Eye", true)
				c:round(Vector3.new(0.09, 0.09, 0.06), CFrame.new(at + n * 0.09 + Vector3.new(-0.04 * s, 0.07, 0)) * slope, WHITE):SetAttribute("Eye", true)
			end
			c:box(Vector3.new(0.34, 0.12, 0.10), CFrame.new(Vector3.new(0, -0.46, 0.70) + n * 0.04) * slope, INK)
			-- Lava running down the front, both sides and the back.
			c:box(Vector3.new(0.12, 0.60, 0.06), CFrame.new(Vector3.new(-0.22, 0.25, 0.306) + n * 0.03) * slope, LAVA, NEON)
			c:box(Vector3.new(0.12, 0.40, 0.06), CFrame.new(Vector3.new(0.20, 0.35, 0.25) + n * 0.03) * slope, LAVA, NEON)
			c:box(Vector3.new(0.12, 0.60, 0.06), CFrame.new(0.10, 0.115, -0.415) * CFrame.Angles(a, 0, 0), LAVA, NEON)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.06, 0.70, 0.12), CFrame.new(0.493 * s, 0.015, -0.20) * CFrame.Angles(0, 0, b * s), LAVA, NEON)
				-- Stubby rock arms and feet.
				c:box(Vector3.new(0.34, 0.30, 0.36), CFrame.new(0.80 * s, -0.38, 0.10) * CFrame.Angles(0, 0, -0.5 * s), p.base, SLATE)
				for _, t in ipairs({ -1, 1 }) do
					c:box(Vector3.new(0.46, 0.24, 0.46), CFrame.new(0.62 * s, -1.08, 0.52 * t), p.dark, SLATE)
				end
			end
			-- Cooled rock lumps.
			c:box(Vector3.new(0.30, 0.22, 0.28), CFrame.new(-0.40, -0.70, -0.84) * CFrame.Angles(0.3, 0.4, 0), p.dark, SLATE)
			c:box(Vector3.new(0.26, 0.22, 0.26), CFrame.new(-0.32, 0.30, -0.10) * CFrame.Angles(0, 0.3, 0.5), p.dark, SLATE)
			c:light(LAVA, 1.6, 8)
		end,
	}

	-- A living anvil: a long horn for a nose, a hot horseshoe cooling on its back
	-- and a little smith's hammer in one fist.
	S.ir_anvil = {
		label = "Anvil",
		set = SET,
		tint = C3(96, 100, 114),
		head = CFrame.new(0, 1.08, 0.24),
		neck = CFrame.new(0, -0.36, 0.72),
		back = CFrame.new(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.40, 1.20, 1.30), bodyMat = METAL,
				eyeColor = EMBER, eyeY = 0.08, eyeSpread = 0.34, eyeSize = Vector3.new(0.38, 0.40, 0.18),
				mouthY = -0.30, mouthSize = Vector3.new(0.46, 0.10, 0.12),
				legs = false, tail = false,
			})
			-- The striking face on top, and the horn out front.
			c:box(Vector3.new(1.90, 0.40, 1.90), CFrame.new(0, 0.86, -0.05), p.light, METAL)
			c:cone(Vector3.new(0.50, 0.70, 0.44), CFrame.new(0, 0.88, 1.24) * CFrame.Angles(math.pi / 2, 0, 0), p.light, METAL)
			-- Lava seams down both edges of the face.
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.04, 0.08, 1.80), CFrame.new(0.96 * s, 0.80, -0.05), LAVA, NEON)
			end
			-- The hardy hole, and a red-hot horseshoe cooling behind it.
			c:box(Vector3.new(0.22, 0.04, 0.22), CFrame.new(0, 1.07, -0.20), INK)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.12, 0.06, 0.46), CFrame.new(0.22 * s, 1.09, -0.62), LAVA, NEON)
			end
			c:box(Vector3.new(0.56, 0.06, 0.12), CFrame.new(0, 1.09, -0.84), LAVA, NEON)
			-- The waisted foot, splaying into four stubby feet.
			c:box(Vector3.new(1.60, 0.30, 1.50), CFrame.new(0, -0.66, 0), p.dark, METAL)
			for _, s in ipairs({ -1, 1 }) do
				for _, t in ipairs({ -1, 1 }) do
					c:box(Vector3.new(0.46, 0.26, 0.46), CFrame.new(0.76 * s, -0.90, 0.64 * t), p.deep, METAL)
				end
			end
			-- Stubby arms; the right one swings a tiny hammer.
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.30, 0.30, 0.46), CFrame.new(0.82 * s, -0.12, 0.22), p.base, METAL)
			end
			c:rod(Vector3.new(0.98, -0.30, 0.46), Vector3.new(0.98, 0.42, 0.56), 0.06, C3(124, 84, 52), nil, false)
			c:box(Vector3.new(0.26, 0.26, 0.48), CFrame.new(0.98, 0.48, 0.56), p.deep, METAL)
			c:light(LAVA, 1.4, 8)
		end,
	}

	-- A pot-bellied iron furnace: a fire grate for a grin, a stubby chimney and
	-- glowing vents down its sides.
	S.ir_furnace = {
		label = "Furnace",
		set = SET,
		tint = C3(84, 78, 92),
		scale = 1.08,
		head = CFrame.new(-0.30, 1.06, 0.24),
		neck = CFrame.new(0, -0.66, 0.86),
		back = CFrame.new(0, 0.20, -0.84),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.80, 1.60, 1.60), bodyMat = METAL,
				bib = { w = 1.40, h = 0.66, y = 0.42, color = p.light },
				eyeY = 0.42, eyeSpread = 0.40, eyeSize = Vector3.new(0.40, 0.44, 0.18),
				mouth = false, tail = false,
				legSize = Vector3.new(0.30, 0.30, 0.30), legX = 0.66, legY = -0.86, legZ = { 0.52, -0.52 },
			})
			-- The fire door: an iron frame, the blaze inside, two grate bars.
			c:box(Vector3.new(1.10, 0.66, 0.12), CFrame.new(0, -0.30, 0.84), p.dark, METAL)
			c:box(Vector3.new(0.84, 0.46, 0.08), CFrame.new(0, -0.30, 0.88), LAVA, NEON)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.07, 0.50, 0.06), CFrame.new(0.16 * s, -0.30, 0.92), p.deep, METAL)
			end
			-- Lid, chimney, chimney cap and one escaping ember.
			c:box(Vector3.new(1.96, 0.16, 1.76), CFrame.new(0, 0.94, 0), p.dark, METAL)
			c:cyl(Vector3.new(0.50, 0.44, 0.44), CFrame.new(0.40, 1.27, -0.34) * CFrame.Angles(0, 0, math.pi / 2), p.dark, METAL)
			c:box(Vector3.new(0.58, 0.10, 0.58), CFrame.new(0.40, 1.56, -0.34), p.deep, METAL)
			c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.36, 1.72, -0.30), EMBER, NEON)
			-- A brass pressure gauge on the lid.
			c:cyl(Vector3.new(0.08, 0.36, 0.36), CFrame.new(-0.52, 0.94, 0.86) * CFrame.Angles(0, math.pi / 2, 0), BRASS, METAL)
			c:box(Vector3.new(0.04, 0.14, 0.04), CFrame.new(-0.49, 0.98, 0.92) * CFrame.Angles(0, 0, -0.6), INK)
			-- Glowing vents down both sides.
			for _, s in ipairs({ -1, 1 }) do
				for _, y in ipairs({ 0.04, -0.22 }) do
					c:box(Vector3.new(0.06, 0.08, 0.80), CFrame.new(0.92 * s, y, -0.05), LAVA, NEON)
				end
			end
			c:light(LAVA, 2.0, 9)
		end,
	}

	-- A basalt tortoise: its shell is a cluster of six-sided rock columns of
	-- different heights, with lava glowing in the cracks between them.
	local COLUMNS = {
		-- x, z, height, darker?
		{ -0.54, -0.56, 0.70, false }, { 0, -0.56, 1.00, true }, { 0.54, -0.56, 0.62, false },
		{ -0.56, -0.04, 0.54, true }, { 0, -0.04, 0.82, false }, { 0.56, -0.04, 0.48, true },
		{ -0.28, 0.40, 0.40, false }, { 0.28, 0.40, 0.34, true },
	}
	S.ir_basaltoise = {
		label = "Basaltoise",
		set = SET,
		tint = C3(74, 70, 84),
		head = CFrame.new(0, 0.80, 0.78),
		neck = CFrame.new(0, -0.36, 0.96),
		back = CFrame.new(0, 0.30, -1.00),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.90, 1.20, 1.80), bodyColor = p.light,
				eyeY = 0.14, eyeSpread = 0.40, eyeSize = Vector3.new(0.42, 0.48, 0.20),
				snout = { w = 0.62, h = 0.36, d = 0.34, y = -0.22, color = p.pale, nose = p.deep },
				legSize = Vector3.new(0.50, 0.44, 0.54), legX = 0.66, legY = -0.70, legColor = p.dark,
				tailSize = Vector3.new(0.30, 0.26, 0.40), tailColor = p.dark,
			})
			-- Shell rim, the lava bed, then the columns standing in it.
			c:box(Vector3.new(2.10, 0.22, 2.00), CFrame.new(0, 0.62, -0.05), p.dark, SLATE)
			c:box(Vector3.new(1.76, 0.08, 1.66), CFrame.new(0, 0.76, -0.05), LAVA, NEON)
			for _, col in ipairs(COLUMNS) do
				local h = col[3]
				c:cyl(
					Vector3.new(h, 0.52, 0.52),
					CFrame.new(col[1], 0.74 + h / 2, col[2]) * CFrame.Angles(0, 0, math.pi / 2),
					col[4] and p.dark or p.base,
					SLATE
				)
			end
			-- The tallest column is still molten on top.
			c:cyl(Vector3.new(0.06, 0.40, 0.40), CFrame.new(0, 1.77, -0.56) * CFrame.Angles(0, 0, math.pi / 2), LAVA, NEON)
			c:light(LAVA, 1.4, 8)
		end,
	}

	-- A molten bull: a pale blaze down its face, curling ivory horns, a brass
	-- nose ring, a shoulder hump and lava cracks running down its flanks.
	S.ir_magmabull = {
		label = "Magma Bull",
		set = SET,
		tint = C3(92, 64, 60),
		head = CFrame.new(0, 1.20, 0.30),
		neck = CFrame.new(0, -0.42, 0.66),
		back = CFrame.new(0, 0.30, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = Vector3.new(2.06, 1.84, 1.86),
				bib = { w = 1.20, h = 0.84, y = 0.16, color = p.light },
				snout = { w = 0.92, h = 0.54, d = 0.40, y = -0.32, color = p.light, nose = p.light },
				legSize = Vector3.new(0.46, 0.40, 0.50), legColor = p.deep,
				tail = false,
			})
			-- Shoulder hump.
			c:box(Vector3.new(1.30, 0.34, 0.90), CFrame.new(0, 1.02, 0.05), p.base)
			for _, s in ipairs({ -1, 1 }) do
				-- Nostrils.
				c:box(Vector3.new(0.12, 0.10, 0.06), CFrame.new(0.18 * s, -0.26, 1.24), INK)
				-- Horns: out to the side, then up to a point.
				c:rod(Vector3.new(0.66 * s, 0.86, 0.46), Vector3.new(1.12 * s, 0.98, 0.52), 0.13, HORN, nil, false)
				c:cone(Vector3.new(0.24, 0.48, 0.24), CFrame.new(1.20 * s, 1.18, 0.52) * CFrame.Angles(0, 0, -0.30 * s), HORN)
				-- Lava cracks zig-zagging down the flank.
				c:box(Vector3.new(0.06, 0.56, 0.10), CFrame.new(1.10 * s, 0.22, -0.28) * CFrame.Angles(0.55, 0, 0), LAVA, NEON)
				c:box(Vector3.new(0.06, 0.46, 0.10), CFrame.new(1.10 * s, -0.20, -0.50) * CFrame.Angles(-0.50, 0, 0), LAVA, NEON)
			end
			-- Brass nose ring, read from the front as a U.
			c:rod(Vector3.new(-0.14, -0.44, 1.25), Vector3.new(-0.10, -0.62, 1.27), 0.04, BRASS, METAL, false)
			c:rod(Vector3.new(-0.10, -0.62, 1.27), Vector3.new(0.10, -0.62, 1.27), 0.04, BRASS, METAL, false)
			c:rod(Vector3.new(0.10, -0.62, 1.27), Vector3.new(0.14, -0.44, 1.25), 0.04, BRASS, METAL, false)
			-- Rope tail with an ember tuft.
			c:rod(Vector3.new(0, 0.30, -0.95), Vector3.new(0, -0.30, -1.25), 0.07, p.deep, nil, false)
			c:box(Vector3.new(0.26, 0.34, 0.26), CFrame.new(0, -0.40, -1.30), LAVA, NEON)
		end,
	}

	return S
end
