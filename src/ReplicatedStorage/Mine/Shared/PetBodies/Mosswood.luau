--[[ PetBodies/Mosswood -- Mosswood's bodies. See tools/gen/sets/README.md.

	Small finds on a forest floor, in muted greens and wood: a toadstool, a cut
	stump with a sprout, a snail with a mossy swirl shell, a hedgehog with leaves
	caught in its spines and an acorn in its cap. No glow, no giant magic tree.
]]
return function(K)
	local C3, block, spots = K.C3, K.block, K.spots
	local INK, NOSE, WOOD = K.INK, K.NOSE, K.WOOD
	local S = {}

	local MOSS = C3(108, 136, 74)
	local LEAF = C3(124, 150, 82)

	-- A fat mushroom: a cream stalk with the face, under a wide spotted cap.
	S.mw_toadstool = {
		label = "Toadstool",
		set = "mosswood",
		tint = C3(178, 84, 64),
		scale = 1.08,
		head = CFrame.new(0, 1.66, 0.04),
		neck = CFrame.new(0, -0.36, 0.76),
		back = CFrame.new(0, 0.10, -0.76),
		build = function(c, p)
			local stalk = C3(236, 226, 204)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.56, 1.30, 1.46), bodyColor = stalk,
				eyeY = 0.10, eyeSpread = 0.34, eyeSize = Vector3.new(0.40, 0.50, 0.18),
				mouthY = -0.26, mouthSize = Vector3.new(0.26, 0.12, 0.12),
				legSize = Vector3.new(0.40, 0.26, 0.44), legX = 0.40, legY = -0.66, legZ = { 0.12 },
				legColor = C3(206, 192, 164), tail = false,
			})
			-- Gills under the rim, then the cap in three steps.
			c:box(Vector3.new(2.30, 0.06, 2.10), CFrame.new(0, 0.66, 0), p.pale)
			c:box(Vector3.new(2.50, 0.50, 2.30), CFrame.new(0, 0.92, 0), p.base)
			c:box(Vector3.new(1.90, 0.36, 1.76), CFrame.new(0, 1.30, 0), p.base)
			c:box(Vector3.new(1.10, 0.24, 1.00), CFrame.new(0, 1.56, 0), p.dark)
			-- Pale spots round the rim and over the top.
			spots(c, p.pale, { { -0.70, 0.94, 1.16 }, { 0.52, 0.98, 1.16 }, { 1.00, 0.86, 1.16 } }, Vector3.new(0.30, 0.24, 0.10))
			spots(c, p.pale, { { 0.70, 1.49, 0.56 }, { -0.72, 1.49, -0.50 }, { 1.08, 1.19, -0.60 } }, Vector3.new(0.34, 0.08, 0.34))
			-- Moss growing round the foot of the stalk.
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.50, 0.24, 0.40), CFrame.new(0.62 * s, -0.56, 0.42) * CFrame.Angles(0, 0.3 * s, 0), MOSS)
			end
		end,
	}

	-- A cut stump: ringed top, bark ridges, splayed roots and a sprout.
	S.mw_stump = {
		label = "Stump",
		set = "mosswood",
		tint = C3(140, 104, 72),
		head = CFrame.new(0, 1.10, 0.06),
		neck = CFrame.new(0, -0.36, 0.70),
		back = CFrame.new(0, 0.20, -0.70),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(2.00, 1.70, 1.86), bodyMat = WOOD,
				eyeY = 0.14, eyeSpread = 0.42, eyeSize = Vector3.new(0.44, 0.52, 0.20),
				brow = p.dark, mouthY = -0.30, mouthSize = Vector3.new(0.40, 0.14, 0.14),
				legs = false, tail = false,
			})
			-- The cut face: tree rings, light and pale.
			c:box(Vector3.new(1.86, 0.06, 1.72), CFrame.new(0, 0.93, 0), p.pale, WOOD)
			c:box(Vector3.new(1.24, 0.07, 1.12), CFrame.new(0, 0.94, 0), p.light, WOOD)
			c:box(Vector3.new(0.62, 0.08, 0.56), CFrame.new(0, 0.95, 0), p.pale, WOOD)
			-- Bark ridges down the sides and back.
			for _, s in ipairs({ -1, 1 }) do
				for _, z in ipairs({ -0.50, 0.30 }) do
					c:box(Vector3.new(0.12, 1.60, 0.16), CFrame.new(1.00 * s, 0.04, z), p.dark, WOOD)
				end
				c:box(Vector3.new(0.18, 1.60, 0.12), CFrame.new(0.46 * s, 0.04, -0.93), p.dark, WOOD)
				-- Roots splaying out at the four corners.
				for _, t in ipairs({ -1, 1 }) do
					c:box(Vector3.new(0.40, 0.34, 0.72), CFrame.new(0.80 * s, -0.76, 0.70 * t) * CFrame.Angles(0, 0.6 * s * t, 0), p.dark, WOOD)
				end
			end
			-- A sprout on top, moss down the front corner, a shelf fungus.
			c:rod(Vector3.new(0.30, 0.96, -0.20), Vector3.new(0.34, 1.40, -0.20), 0.04, LEAF, nil, false)
			c:box(Vector3.new(0.34, 0.06, 0.20), CFrame.new(0.18, 1.40, -0.20) * CFrame.Angles(0, 0, 0.4), LEAF)
			c:box(Vector3.new(0.34, 0.06, 0.20), CFrame.new(0.50, 1.44, -0.20) * CFrame.Angles(0, 0, -0.4), LEAF)
			c:box(Vector3.new(0.84, 0.14, 0.34), CFrame.new(-0.44, 0.96, 0.76), MOSS)
			c:box(Vector3.new(0.30, 0.34, 0.10), CFrame.new(-0.66, 0.78, 0.94), MOSS)
			c:box(Vector3.new(0.34, 0.10, 0.54), CFrame.new(1.12, 0.06, -0.10), C3(214, 196, 150))
		end,
	}

	-- A snail: a pale foot with eyes on stalks, and a swirl shell with moss on it.
	S.mw_snail = {
		label = "Snail",
		set = "mosswood",
		tint = C3(168, 124, 84),
		head = CFrame.new(0, 1.46, -0.50),
		neck = CFrame.new(0, -0.40, 1.02),
		back = CFrame.new(0, 0.48, -1.30),
		build = function(c, p)
			local skin = p.pale
			-- Head, the long foot under everything, and its tapering tail.
			c:box(Vector3.new(1.24, 1.10, 0.80), CFrame.new(0, -0.06, 0.62), skin)
			c:box(Vector3.new(1.30, 0.44, 2.20), CFrame.new(0, -0.58, -0.12), skin)
			c:box(Vector3.new(0.70, 0.28, 0.42), CFrame.new(0, -0.66, -1.38), p.light)
			-- The shell, with a swirl on each side made of nested, turning squares.
			c:box(Vector3.new(1.66, 1.66, 1.56), CFrame.new(0, 0.48, -0.50), p.base)
			for _, s in ipairs({ -1, 1 }) do
				for i, row in ipairs({ { 1.24, p.dark }, { 0.86, p.light }, { 0.48, p.dark }, { 0.18, p.light } }) do
					c:box(
						Vector3.new(0.04 + i * 0.02, row[1], row[1]),
						CFrame.new(0.83 * s, 0.48, -0.50) * CFrame.Angles((i - 1) * 0.4 * s, 0, 0),
						row[2]
					)
				end
			end
			c:box(Vector3.new(0.90, 0.16, 0.80), CFrame.new(0.06, 1.38, -0.46), MOSS)
			-- Eyes on stalks, a smile and rosy cheeks.
			for _, s in ipairs({ -1, 1 }) do
				c:rod(Vector3.new(0.28 * s, 0.44, 0.80), Vector3.new(0.40 * s, 1.08, 0.90), 0.06, skin, nil, false)
				c:ball(Vector3.new(0.32, 0.32, 0.32), CFrame.new(0.40 * s, 1.14, 0.92), skin)
				c:eye(Vector3.new(0.40 * s, 1.14, 1.04), 0.10)
				c:box(Vector3.new(0.20, 0.12, 0.06), CFrame.new(0.42 * s, -0.12, 1.03), C3(232, 150, 150))
			end
			c:box(Vector3.new(0.34, 0.10, 0.08), CFrame.new(0, -0.24, 1.03), INK)
		end,
	}

	-- A hedgehog: pointed snout, little ears, a back of spines with leaves caught in it.
	S.mw_hedgehog = {
		label = "Hedgehog",
		set = "mosswood",
		tint = C3(122, 102, 86),
		head = CFrame.new(0, 1.30, 0.20),
		neck = CFrame.new(0, -0.30, 0.66),
		back = CFrame.new(0, 0.30, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = Vector3.new(2.02, 1.60, 1.90), shapeColor = p.base,
				snout = { w = 0.42, h = 0.34, d = 0.58, y = -0.24, color = p.pale, nose = NOSE },
				eyeY = 0.12, eyeSize = Vector3.new(0.42, 0.50, 0.20),
				bib = { w = 1.10, h = 0.70, y = -0.40, color = p.pale },
				legSize = Vector3.new(0.40, 0.28, 0.44), legY = -0.80, legColor = p.deep, tail = false,
			})
			-- Spines: three rows over the back, all swept towards the tail.
			for _, z in ipairs({ 0.34, -0.18, -0.68 }) do
				for _, x in ipairs({ -0.60, 0, 0.60 }) do
					c:cone(Vector3.new(0.38, 0.62, 0.38), CFrame.new(x, 0.96, z) * CFrame.Angles(-0.6, 0, -x * 0.5), p.dark)
				end
			end
			for _, s in ipairs({ -1, 1 }) do
				c:cone(Vector3.new(0.36, 0.56, 0.36), CFrame.new(0.98 * s, 0.40, -0.30) * CFrame.Angles(-0.5, 0, -1.0 * s), p.dark)
				c:box(Vector3.new(0.26, 0.24, 0.14), CFrame.new(0.52 * s, 0.86, 0.66), p.pale)
			end
			-- An autumn leaf and a green one caught in the spines, and a berry.
			c:box(Vector3.new(0.44, 0.06, 0.28), CFrame.new(-0.36, 1.26, -0.30) * CFrame.Angles(0.3, 0.5, 0.2), C3(196, 120, 60))
			c:box(Vector3.new(0.40, 0.06, 0.26), CFrame.new(0.44, 1.20, -0.66) * CFrame.Angles(-0.2, -0.6, -0.3), LEAF)
			c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0.18, 1.26, 0.10), C3(170, 40, 52))
		end,
	}

	-- An acorn: a brown nut with a crosshatched cap, a stem and an oak leaf.
	S.mw_acorn = {
		label = "Acorn",
		set = "mosswood",
		tint = C3(160, 112, 66),
		head = CFrame.new(0, 1.40, 0.04),
		neck = CFrame.new(0, -0.36, 0.70),
		back = CFrame.new(0, 0.20, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.90, 1.80, 1.80),
				eyeY = 0.08, eyeSpread = 0.40, eyeSize = Vector3.new(0.42, 0.52, 0.20),
				mouthY = -0.32, mouthSize = Vector3.new(0.28, 0.12, 0.12),
				legSize = Vector3.new(0.40, 0.26, 0.46), legX = 0.50, legY = -0.86, legZ = { 0.20 },
				legColor = p.deep, tail = false,
			})
			-- The cap: a rim, a dome, and a crosshatch over its top.
			c:box(Vector3.new(2.14, 0.16, 2.02), CFrame.new(0, 0.74, 0), p.deep, WOOD)
			c:box(Vector3.new(2.06, 0.50, 1.94), CFrame.new(0, 1.00, 0), p.dark, WOOD)
			for _, a in ipairs({ 0.785, -0.785 }) do
				for _, o in ipairs({ -0.36, 0.36 }) do
					c:box(Vector3.new(0.08, 0.04, 2.20), CFrame.new(0, 1.26, 0) * CFrame.Angles(0, a, 0) * CFrame.new(o, 0, 0), p.deep)
				end
			end
			c:box(Vector3.new(0.20, 0.42, 0.20), CFrame.new(0.06, 1.44, 0) * CFrame.Angles(0, 0, -0.2), p.deep, WOOD)
			c:box(Vector3.new(0.60, 0.06, 0.32), CFrame.new(0.40, 1.42, 0.08) * CFrame.Angles(0.1, 0.3, -0.25), LEAF)
			-- The pointed tip underneath, little arms and two streaks.
			c:cone(Vector3.new(0.50, 0.34, 0.50), CFrame.new(0, -0.94, -0.20) * CFrame.Angles(math.pi, 0, 0), p.dark)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.30, 0.42, 0.30), CFrame.new(1.00 * s, -0.20, 0.30) * CFrame.Angles(0, 0, -0.3 * s), p.base)
				c:box(Vector3.new(0.10, 0.80, 0.06), CFrame.new(0.40 * s, -0.10, -0.88), p.light)
			end
		end,
	}

	return S
end
