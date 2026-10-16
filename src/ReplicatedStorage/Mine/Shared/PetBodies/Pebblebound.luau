--[[ PetBodies/Pebblebound -- Pebblebound's bodies. See tools/gen/sets/README.md.

	The starter set: plain rock, earthy colours, no glow. Five silhouettes a kid
	can name at follow distance: a cracked-open geode, a banded rock armadillo,
	a mole with digging claws, a balanced stone cairn and a ram with stone horns.
]]
return function(K)
	local C3, block, spots = K.C3, K.block, K.spots
	local SLATE, METAL, GLASS = K.SLATE, K.METAL, K.GLASS
	local S = {}

	-- A round rock split open on top, with a cluster of crystals inside.
	S.pb_geode = {
		label = "Geode",
		set = "pebblebound",
		tint = C3(150, 140, 130),
		head = CFrame.new(0, 1.20, 0.34),
		neck = CFrame.new(0, -0.30, 0.66),
		back = CFrame.new(0, 0.20, -0.66),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(2.06, 1.76, 1.90), bodyMat = SLATE,
				eyeY = 0.06, mouthY = -0.42, mouthSize = Vector3.new(0.42, 0.14, 0.14),
				legSize = Vector3.new(0.40, 0.30, 0.44), legY = -0.86, legColor = p.deep, tail = false,
			})
			-- The broken lip of the shell, and the dark hollow inside it.
			c:box(Vector3.new(1.56, 0.10, 1.34), CFrame.new(0, 0.97, -0.02), p.deep, SLATE)
			for _, s in ipairs({ -1, 1 }) do
				c:cone(Vector3.new(0.40, 0.34, 0.40), CFrame.new(0.78 * s, 1.04, 0.62) * CFrame.Angles(0, 0, 0.2 * s), p.base, SLATE)
				c:cone(Vector3.new(0.36, 0.30, 0.36), CFrame.new(0.80 * s, 1.02, -0.64) * CFrame.Angles(0, 0, -0.2 * s), p.dark, SLATE)
			end
			-- The crystal cluster: one tall point, four leaning around it.
			c:cone(Vector3.new(0.46, 0.92, 0.46), CFrame.new(0, 1.40, -0.04), p.pale, GLASS)
			for _, v in ipairs({
				{ 0.40, 1.22, 0.16, -0.36, 0.10 }, { -0.40, 1.20, 0.14, 0.38, 0.12 },
				{ 0.32, 1.16, -0.38, -0.30, -0.24 }, { -0.30, 1.18, -0.36, 0.30, -0.26 },
			}) do
				c:cone(Vector3.new(0.30, 0.62, 0.30), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(v[5], 0, v[4]), p.glow, GLASS)
			end
			-- A zigzag crack down one flank, and a few knobbly lumps.
			c:box(Vector3.new(0.06, 0.36, 0.08), CFrame.new(1.08, 0.34, 0.16) * CFrame.Angles(0.4, 0, 0), p.deep)
			c:box(Vector3.new(0.06, 0.30, 0.08), CFrame.new(1.08, 0.04, 0.18) * CFrame.Angles(-0.4, 0, 0), p.deep)
			spots(c, p.dark, { { -1.06, -0.30, 0.20 }, { 1.06, -0.42, -0.30 }, { -0.40, -0.60, -0.92 } }, Vector3.new(0.30, 0.26, 0.30))
		end,
	}

	-- An armadillo whose back is banded slate plates; pointy snout, segmented tail.
	S.pb_rockadillo = {
		label = "Rockadillo",
		set = "pebblebound",
		tint = C3(176, 128, 90),
		head = CFrame.new(0, 1.12, 0.40),
		neck = CFrame.new(0, -0.30, 0.66),
		back = CFrame.new(0, 0.30, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = Vector3.new(2.02, 1.62, 2.00),
				snout = { w = 0.46, h = 0.38, d = 0.66, y = -0.26, color = p.pale },
				eyeY = 0.12, eyeSize = Vector3.new(0.46, 0.54, 0.20),
				legSize = Vector3.new(0.40, 0.30, 0.46), legY = -0.78, legColor = p.deep, tail = false,
			})
			-- Head plate, then four shell bands over the back, light and dark.
			c:box(Vector3.new(1.30, 0.22, 0.46), CFrame.new(0, 0.94, 0.60), p.dark, SLATE)
			for i = 0, 3 do
				c:box(
					Vector3.new(2.18, 0.42 - i * 0.02, 0.40),
					CFrame.new(0, 0.84, 0.24 - i * 0.40),
					(i % 2 == 0) and p.light or p.dark,
					SLATE
				)
			end
			for _, s in ipairs({ -1, 1 }) do
				c:cone(Vector3.new(0.24, 0.40, 0.18), CFrame.new(0.40 * s, 1.16, 0.66) * CFrame.Angles(0, 0, -0.2 * s), p.pale)
			end
			-- A ringed tail tapering away behind.
			c:box(Vector3.new(0.42, 0.38, 0.40), CFrame.new(0, -0.30, -1.14), p.light, SLATE)
			c:box(Vector3.new(0.32, 0.30, 0.38), CFrame.new(0, -0.40, -1.48), p.dark, SLATE)
			c:box(Vector3.new(0.22, 0.22, 0.34), CFrame.new(0, -0.50, -1.80), p.light, SLATE)
		end,
	}

	-- A velvet mole: big pink digging paws out front, a star nose, ore on its back.
	S.pb_mole = {
		label = "Mole",
		set = "pebblebound",
		tint = C3(96, 84, 80),
		head = CFrame.new(0, 1.00, 0.06),
		neck = CFrame.new(0, -0.30, 0.66),
		back = CFrame.new(0, 0.30, -0.66),
		build = function(c, p)
			local pink, claw = C3(238, 168, 172), C3(244, 240, 230)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(2.04, 1.70, 1.90),
				eyeY = 0.24, eyeSpread = 0.40, eyeSize = Vector3.new(0.30, 0.34, 0.16),
				snout = { w = 0.52, h = 0.40, d = 0.44, y = -0.16, color = pink, nose = C3(204, 104, 124) },
				legSize = Vector3.new(0.40, 0.30, 0.46), legZ = { -0.40 }, legColor = p.deep,
				tailSize = Vector3.new(0.20, 0.20, 0.30), tailColor = pink,
			})
			for _, s in ipairs({ -1, 1 }) do
				-- Spade paws turned outward, three claws on each.
				c:box(Vector3.new(0.20, 0.70, 0.72), CFrame.new(1.06 * s, -0.36, 0.48) * CFrame.Angles(0, -0.5 * s, 0), pink)
				for i = -1, 1 do
					c:cone(
						Vector3.new(0.12, 0.26, 0.12),
						CFrame.new(1.24 * s, -0.36 + i * 0.22, 0.82) * CFrame.Angles(math.pi / 2, 0, 0),
						claw
					)
				end
			end
			-- Ore chunks stuck in its fur: copper, gold and iron.
			c:box(Vector3.new(0.34, 0.28, 0.34), CFrame.new(-0.50, 0.96, -0.34) * CFrame.Angles(0.3, 0.4, 0), C3(196, 112, 62), METAL)
			c:box(Vector3.new(0.40, 0.30, 0.40), CFrame.new(0.38, 0.96, -0.10) * CFrame.Angles(-0.2, 0.7, 0.2), C3(240, 196, 72), METAL)
			c:box(Vector3.new(0.30, 0.24, 0.30), CFrame.new(0.10, 0.92, -0.66) * CFrame.Angles(0.2, -0.3, 0.3), C3(150, 152, 162), METAL)
		end,
	}

	-- Three balanced stones and a pebble on top; the face is on the middle stone.
	S.pb_cairn = {
		label = "Cairn",
		set = "pebblebound",
		tint = C3(140, 136, 128),
		head = CFrame.new(0, 1.40, 0.04),
		neck = CFrame.new(0, -0.40, 0.90),
		back = CFrame.new(0, 0.10, -0.80),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(2.02, 0.96, 1.70), bodyMat = SLATE,
				eyeY = 0.12, eyeSpread = 0.40, eyeSize = Vector3.new(0.40, 0.46, 0.18),
				mouthY = -0.24, mouthSize = Vector3.new(0.30, 0.12, 0.12),
				legs = false, tail = false,
			})
			-- Wide bottom stone, smaller top stone and a pebble, each turned a little.
			c:box(Vector3.new(2.30, 0.70, 1.90), CFrame.new(0, -0.70, 0), p.dark, SLATE)
			c:box(Vector3.new(1.50, 0.56, 1.30), CFrame.new(0.06, 0.80, -0.04) * CFrame.Angles(0, 0.22, 0.04), p.light, SLATE)
			c:box(Vector3.new(0.70, 0.42, 0.62), CFrame.new(-0.04, 1.26, 0) * CFrame.Angles(0, -0.36, 0), p.pale, SLATE)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.50, 0.26, 0.56), CFrame.new(0.62 * s, -1.14, 0.34), p.deep, SLATE)
				c:box(Vector3.new(0.34, 0.34, 0.34), CFrame.new(1.16 * s, -0.08, 0.20) * CFrame.Angles(0.3, 0.3, 0.2), p.light, SLATE)
			end
			-- Strata lines on the base stone, and lichen dots.
			c:box(Vector3.new(1.80, 0.05, 0.05), CFrame.new(0, -0.60, 0.98), p.deep)
			c:box(Vector3.new(1.40, 0.05, 0.05), CFrame.new(0.10, -0.82, 0.98), p.deep)
			spots(c, C3(168, 178, 120), { { -0.80, -0.44, 0.94 }, { 0.62, 1.10, 0.50 }, { 1.12, -0.90, -0.40 } }, Vector3.new(0.18, 0.12, 0.16))
		end,
	}

	-- A craggy ram with big curled stone horns.
	S.pb_ram = {
		label = "Ram",
		set = "pebblebound",
		tint = C3(156, 148, 138),
		scale = 1.10,
		head = CFrame.new(0, 1.12, 0.06),
		neck = CFrame.new(0, -0.30, 0.62),
		back = CFrame.new(0, 0.30, -0.62),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodyMat = SLATE,
				snout = { w = 0.64, h = 0.50, d = 0.44, color = p.pale },
				brow = p.deep,
				legSize = Vector3.new(0.38, 0.44, 0.42), legColor = p.deep,
				tailSize = Vector3.new(0.30, 0.30, 0.30), tailColor = p.light,
			})
			for _, s in ipairs({ -1, 1 }) do
				-- A horn that curls out, back, down and forward again.
				c:box(Vector3.new(0.44, 0.40, 0.46), CFrame.new(0.76 * s, 1.04, 0.10) * CFrame.Angles(0, 0, -0.3 * s), p.pale, SLATE)
				c:box(Vector3.new(0.38, 0.44, 0.40), CFrame.new(1.08 * s, 0.84, -0.12) * CFrame.Angles(0.3, 0, -0.6 * s), p.light, SLATE)
				c:box(Vector3.new(0.32, 0.40, 0.34), CFrame.new(1.20 * s, 0.46, 0.00) * CFrame.Angles(0.5, 0, 0), p.pale, SLATE)
				c:box(Vector3.new(0.26, 0.28, 0.30), CFrame.new(1.08 * s, 0.20, 0.28) * CFrame.Angles(0.8, 0, 0.3 * s), p.light, SLATE)
			end
			-- Craggy rock tufts along the back.
			for _, v in ipairs({ { -0.42, 0.98, -0.30, 0.3 }, { 0.36, 1.00, -0.52, -0.4 }, { 0, 0.94, 0.06, 0.6 } }) do
				c:box(Vector3.new(0.48, 0.34, 0.48), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0, v[4], 0.2), p.light, SLATE)
			end
			-- Split hooves.
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.06, 0.22, 0.08), CFrame.new(0.56 * s, -0.96, 0.64), C3(40, 36, 40))
			end
		end,
	}

	return S
end
