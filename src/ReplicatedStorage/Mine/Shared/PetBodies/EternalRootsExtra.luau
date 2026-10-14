--[[ PetBodies/EternalRootsExtra -- more Eternal Roots recolour bodies (Common,
	Uncommon, Rare). See tools/gen/sets/README.md. Three more silhouettes so the
	set's recolours have room to stay vastly different colours: a truffle-hunting
	pig, a finch with a seedling on its head, and a mouse hugging a seed. ]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, WHITE, NEON, GLASS, SLATE = K.INK, K.WHITE, K.NEON, K.GLASS, K.SLATE
	local LEAF, LEAF_DARK = C3(104, 186, 84), C3(64, 132, 58)
	local BARK = C3(118, 84, 58)
	local BLUSH = C3(255, 150, 170)
	local S = {}

	S.er_trufflepig = {
		label = "Trufflepig",
		set = "eternal_roots",
		tint = C3(240, 160, 176),
		head = CFrame.new(0, 1.04, 0.10),
		neck = CFrame.new(0, -0.36, 1.00),
		back = CFrame.new(0, 0.20, -0.80),
		build = function(c, p)
			-- A round little pig that snuffles out truffles among the roots; it has
			-- just found one.
			block(c, p, {
				shape = "round",
				eyeY = 0.26, eyeSpread = 0.42,
				snout = { w = 0.66, h = 0.46, d = 0.24, y = -0.12, color = p.light, nose = p.light },
				legSize = Vector3.new(0.36, 0.30, 0.36), legY = -0.84,
				tail = false,
			})
			for _, s in ipairs({ -1, 1 }) do
				-- Floppy ears folded forward, nostrils, and a mud patch on each flank.
				c:box(Vector3.new(0.44, 0.10, 0.40), CFrame.new(0.52 * s, 1.00, 0.50) * CFrame.Angles(0.50, 0, -0.30 * s), p.dark)
				c:box(Vector3.new(0.10, 0.14, 0.04), CFrame.new(0.14 * s, -0.12, 1.15), INK)
				c:box(Vector3.new(0.04, 0.40, 0.50), CFrame.new(1.02 * s, 0.10, -0.30), p.dark)
			end
			-- A curly tail.
			c:rod(Vector3.new(0, 0.30, -0.90), Vector3.new(0, 0.50, -1.12), 0.05, p.dark, nil, false)
			c:rod(Vector3.new(0, 0.50, -1.12), Vector3.new(0.16, 0.60, -1.00), 0.05, p.dark, nil, false)
			-- The truffle it just dug up, and a leaf stuck to its head.
			c:ball(Vector3.new(0.34, 0.34, 0.34), CFrame.new(0.40, -0.76, 1.20), C3(72, 52, 44))
			c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0.56, -0.70, 1.10), C3(72, 52, 44))
			c:box(Vector3.new(0.34, 0.06, 0.22), CFrame.new(-0.20, 1.04, 0.10) * CFrame.Angles(0, 0.50, 0.20), LEAF)
		end,
	}

	S.er_sproutfinch = {
		label = "Sproutfinch",
		set = "eternal_roots",
		tint = C3(250, 210, 70),
		head = CFrame.new(0, 1.40, -0.06),
		neck = CFrame.new(0, -0.30, 0.86),
		back = CFrame.new(0, 0.20, -0.80),
		build = function(c, p)
			-- A plump little finch with a seedling growing out of its crown.
			local beak = C3(240, 150, 60)
			local _, fz = block(c, p, {
				shape = "bird", bodySize = Vector3.new(1.80, 1.70, 1.60),
				eyeY = 0.20, eyeSpread = 0.40,
				mouth = false,
				bib = { w = 0.90, h = 0.70, y = -0.36, color = p.pale },
				legSize = Vector3.new(0.20, 0.30, 0.30), legX = 0.34, legY = -0.90, legZ = { 0.20 }, legColor = beak,
				tail = false,
			})
			c:cone(Vector3.new(0.30, 0.34, 0.26), CFrame.new(0, -0.02, fz + 0.14) * CFrame.Angles(math.pi / 2, 0, 0), beak)
			for _, s in ipairs({ -1, 1 }) do
				-- Wings folded against the flanks, and cheek blush.
				c:box(Vector3.new(0.12, 0.80, 1.00), CFrame.new(0.96 * s, 0.00, -0.20) * CFrame.Angles(0.30, 0, 0), p.dark)
				c:box(Vector3.new(0.12, 0.30, 0.60), CFrame.new(0.96 * s, -0.40, -0.60) * CFrame.Angles(0.30, 0, 0), p.deep)
				c:box(Vector3.new(0.20, 0.10, 0.04), CFrame.new(0.56 * s, -0.06, fz + 0.02), BLUSH)
			end
			-- A tail fan.
			c:box(Vector3.new(0.80, 0.14, 0.60), CFrame.new(0, 0.10, -1.00) * CFrame.Angles(-0.50, 0, 0), p.dark)
			-- The seedling.
			c:rod(Vector3.new(0, 0.90, 0), Vector3.new(0, 1.30, 0), 0.05, LEAF_DARK, nil, false)
			c:box(Vector3.new(0.40, 0.06, 0.24), CFrame.new(0.20, 1.32, 0) * CFrame.Angles(0, 0, 0.40), LEAF)
			c:box(Vector3.new(0.40, 0.06, 0.24), CFrame.new(-0.20, 1.32, 0) * CFrame.Angles(0, 0, -0.40), LEAF)
		end,
	}

	S.er_seedmouse = {
		label = "Seedmouse",
		set = "eternal_roots",
		tint = C3(170, 150, 220),
		head = CFrame.new(0, 1.30, 0.06),
		neck = CFrame.new(0, -0.30, 0.86),
		back = CFrame.new(0, 0.20, -0.70),
		build = function(c, p)
			-- A mouse sat up on its haunches, hugging a seed nearly as big as itself.
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.70, 1.70, 1.50),
				eyeY = 0.28, eyeSpread = 0.36,
				snout = { w = 0.44, h = 0.30, d = 0.26, y = 0.02, color = p.pale, nose = BLUSH },
				bib = { w = 0.80, h = 0.60, y = -0.40, color = p.pale },
				legSize = Vector3.new(0.44, 0.20, 0.56), legX = 0.44, legY = -0.82, legZ = { 0.20 },
				tail = false,
			})
			for _, s in ipairs({ -1, 1 }) do
				-- Big round ears, paws round the seed, whiskers.
				c:box(Vector3.new(0.66, 0.66, 0.12), CFrame.new(0.66 * s, 1.06, -0.10) * CFrame.Angles(0, 0, -0.30 * s), p.base)
				c:box(Vector3.new(0.40, 0.40, 0.04), CFrame.new(0.66 * s, 1.06, -0.02) * CFrame.Angles(0, 0, -0.30 * s), BLUSH)
				c:box(Vector3.new(0.22, 0.20, 0.22), CFrame.new(0.30 * s, -0.20, 1.02), p.light)
				c:box(Vector3.new(0.40, 0.03, 0.03), CFrame.new(0.40 * s, 0.00, 1.02) * CFrame.Angles(0, 0, 0.15 * s), INK)
			end
			-- The seed: fat and striped.
			c:box(Vector3.new(0.50, 0.64, 0.40), CFrame.new(0, -0.44, 1.00), C3(70, 60, 56))
			c:box(Vector3.new(0.10, 0.60, 0.42), CFrame.new(-0.12, -0.44, 1.00), C3(236, 228, 210))
			c:box(Vector3.new(0.10, 0.60, 0.42), CFrame.new(0.12, -0.44, 1.00), C3(236, 228, 210))
			-- A long tail curling up behind.
			c:rod(Vector3.new(0, -0.60, -0.70), Vector3.new(0.40, -0.80, -1.20), 0.06, p.dark, nil, false)
			c:rod(Vector3.new(0.40, -0.80, -1.20), Vector3.new(0.60, -0.20, -1.40), 0.05, p.dark, nil, false)
			c:rod(Vector3.new(0.60, -0.20, -1.40), Vector3.new(0.40, 0.10, -1.20), 0.04, p.dark, nil, false)
		end,
	}

	return S
end
