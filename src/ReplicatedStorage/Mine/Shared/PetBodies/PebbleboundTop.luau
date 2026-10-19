--[[ PetBodies/PebbleboundTop -- Pebblebound's top bodies. See tools/gen/sets/README.md.

	Epic and up: each body here is worn by exactly ONE pet in the game, so no
	two of them share a silhouette. The set is the plain starter collection
	(rock, ore, the miner's kit), so these stay earthy and readable. Only the
	Mythic, Divine and Exotic bodies get small neon accents: an ore vein, a
	glowing geode heart, echoing the set's top pack, "Earth's Heart".
]]
return function(K)
	local C3, block, ears, spots = K.C3, K.block, K.ears, K.spots
	local SLATE, METAL, GLASS, NEON, WOOD = K.SLATE, K.METAL, K.GLASS, K.NEON, K.WOOD
	local INK, WHITE = K.INK, K.WHITE
	local BRASS, GOLD, IRON, BONE = C3(196, 156, 74), C3(240, 196, 72), C3(150, 152, 162), C3(244, 240, 230)
	local COPPER, BLUSH = C3(196, 112, 62), C3(255, 150, 160)
	local SIDES = { -1, 1 }
	local S = {}

	----------------------------------------------------------------------------
	-- EPIC: charming and clean.
	----------------------------------------------------------------------------

	-- A fox knapped from flint: tall chipped ears and a big flaked tail.
	S.pb_t_flintfox = {
		label = "Flint Fox",
		set = "pebblebound",
		tint = C3(236, 132, 40),
		head = CFrame.new(0, 0.98, 0.10),
		neck = CFrame.new(0, -0.36, 0.66),
		back = CFrame.new(0, 0.30, -0.60),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.90, 1.70, 1.70),
				snout = { w = 0.56, h = 0.40, d = 0.56, y = -0.22, color = p.pale },
				eyeY = 0.20, eyeSize = Vector3.new(0.44, 0.52, 0.20),
				bib = { w = 0.96, h = 0.46, y = -0.58, color = p.pale },
				legSize = Vector3.new(0.36, 0.34, 0.42), legColor = p.deep, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(Vector3.new(0.50, 0.72, 0.40), CFrame.new(0.56 * s, 1.26, 0.06) * CFrame.Angles(0, 0, -0.16 * s), p.base, SLATE)
				c:cone(Vector3.new(0.26, 0.42, 0.10), CFrame.new(0.55 * s, 1.16, 0.26) * CFrame.Angles(0, 0, -0.16 * s), p.pale)
			end
			-- The flaked tail curls up behind; its tip is white like a fresh chip.
			c:box(Vector3.new(0.54, 0.54, 0.66), CFrame.new(0, -0.14, -0.98) * CFrame.Angles(0.5, 0, 0), p.base, SLATE)
			c:box(Vector3.new(0.66, 0.66, 0.60), CFrame.new(0, 0.28, -1.28) * CFrame.Angles(0.9, 0, 0.2), p.dark, SLATE)
			c:cone(Vector3.new(0.52, 0.60, 0.52), CFrame.new(0, 0.80, -1.42) * CFrame.Angles(-0.2, 0, 0), p.pale, SLATE)
		end,
	}

	-- A round pebble owl: wide facial discs, stone ear tufts, a speckled breast.
	S.pb_t_pebbleowl = {
		label = "Pebble Owl",
		set = "pebblebound",
		tint = C3(150, 108, 72),
		head = CFrame.new(0, 1.12, 0.06),
		neck = CFrame.new(0, -0.20, 0.62),
		back = CFrame.new(0, 0.20, -0.62),
		build = function(c, p)
			local beak = C3(236, 180, 70)
			block(c, p, {
				bodySize = Vector3.new(1.84, 2.00, 1.60),
				eyeY = 0.32, eyeSpread = 0.42, eyeSize = Vector3.new(0.52, 0.58, 0.20),
				bib = { w = 1.10, h = 0.86, y = -0.44, color = p.pale },
				mouth = false, legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.76, 0.78, 0.08), CFrame.new(0.42 * s, 0.32, 0.83), p.light)
				c:cone(Vector3.new(0.36, 0.52, 0.30), CFrame.new(0.62 * s, 1.30, 0.06) * CFrame.Angles(0, 0, -0.36 * s), p.dark, SLATE)
				c:box(Vector3.new(0.20, 1.10, 1.10), CFrame.new(0.98 * s, -0.06, -0.12) * CFrame.Angles(0, 0, -0.10 * s), p.dark, SLATE)
				c:box(Vector3.new(0.40, 0.18, 0.44), CFrame.new(0.40 * s, -1.02, 0.30), beak)
			end
			c:cone(Vector3.new(0.22, 0.30, 0.16), CFrame.new(0, 0.02, 0.90) * CFrame.Angles(math.pi, 0, 0), beak)
			spots(c, p.dark, { { -0.26, -0.30, 0.94 }, { 0.22, -0.54, 0.94 }, { 0.02, -0.76, 0.94 } }, Vector3.new(0.18, 0.12, 0.10))
		end,
	}

	-- The miner's canary, perched safe in its little brass cage.
	S.pb_t_canary = {
		label = "Cage Canary",
		set = "pebblebound",
		tint = C3(252, 222, 50),
		head = CFrame.new(0, 1.52, 0),
		neck = CFrame.new(0, -0.30, 0.70),
		back = CFrame.new(0, 0.10, -0.66),
		build = function(c, p)
			local beak = C3(244, 140, 50)
			c:box(Vector3.new(1.30, 1.20, 1.10), CFrame.new(0, -0.08, 0.06), p.base)
			c:box(Vector3.new(0.90, 0.56, 0.12), CFrame.new(0, -0.38, 0.63), p.pale)
			c:eyes(0.12, 0.64, 0.28, 0.13)
			c:cone(Vector3.new(0.24, 0.28, 0.20), CFrame.new(0, -0.08, 0.72) * CFrame.Angles(math.pi / 2, 0, 0), beak)
			c:cone(Vector3.new(0.22, 0.34, 0.34), CFrame.new(0, 0.64, 0.16) * CFrame.Angles(-0.4, 0, 0), p.light)
			c:box(Vector3.new(0.46, 0.14, 0.56), CFrame.new(0, -0.24, -0.66) * CFrame.Angles(-0.5, 0, 0), p.dark)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.16, 0.66, 0.74), CFrame.new(0.70 * s, -0.10, -0.02) * CFrame.Angles(0, 0, -0.18 * s), p.dark)
				-- Corner bars only, so the bird stays in plain view.
				for _, z in ipairs(SIDES) do
					c:rod(Vector3.new(0.92 * s, -0.92, 0.92 * z), Vector3.new(0.92 * s, 0.84, 0.92 * z), 0.06, BRASS, METAL, false)
				end
			end
			c:cyl(Vector3.new(1.90, 0.12, 0.12), CFrame.new(0, -0.74, 0.06), BRASS, METAL)
			c:box(Vector3.new(2.04, 0.22, 2.04), CFrame.new(0, -1.02, 0), p.deep)
			c:cone(Vector3.new(2.04, 0.62, 2.04), CFrame.new(0, 1.14, 0), p.dark)
			c:cyl(Vector3.new(0.10, 0.44, 0.44), CFrame.new(0, 1.62, 0) * CFrame.Angles(0, math.pi / 2, 0), BRASS, METAL)
		end,
	}

	-- A tunnel ant: big-headed, six-legged, hauling a gold nugget home.
	S.pb_t_ant = {
		label = "Tunnel Ant",
		set = "pebblebound",
		tint = C3(74, 66, 82),
		head = CFrame.new(0, 0.72, 0.56),
		neck = CFrame.new(0, -0.44, 1.00),
		back = CFrame.new(0, 0.80, -1.00),
		build = function(c, p)
			c:box(Vector3.new(1.30, 1.16, 1.00), CFrame.new(0, 0.04, 0.56), p.base)
			c:eyes(0.18, 1.08, 0.30, 0.17)
			c:box(Vector3.new(0.30, 0.10, 0.10), CFrame.new(0, -0.24, 1.08), INK)
			c:box(Vector3.new(0.76, 0.62, 0.70), CFrame.new(0, -0.06, -0.20), p.dark)
			c:box(Vector3.new(1.36, 1.16, 1.30), CFrame.new(0, 0.12, -0.98) * CFrame.Angles(-0.2, 0, 0), p.base)
			c:box(Vector3.new(1.40, 0.16, 0.90), CFrame.new(0, 0.12, -1.00) * CFrame.Angles(-0.2, 0, 0), p.light)
			for _, s in ipairs(SIDES) do
				c:cone(Vector3.new(0.18, 0.34, 0.16), CFrame.new(0.30 * s, -0.40, 1.12) * CFrame.Angles(math.pi / 2, 0, 0.3 * s), p.deep)
				c:rod(Vector3.new(0.26 * s, 0.60, 0.80), Vector3.new(0.56 * s, 1.14, 1.12), 0.05, p.deep, nil, false)
				c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.56 * s, 1.14, 1.12), p.deep)
				for i = -1, 1 do
					c:rod(Vector3.new(0.30 * s, -0.20, -0.20 + i * 0.26), Vector3.new(0.92 * s, -0.96, -0.20 + i * 0.50), 0.06, p.deep, nil, false)
				end
			end
			c:box(Vector3.new(0.70, 0.56, 0.66), CFrame.new(0, 0.62, -0.24) * CFrame.Angles(0.3, 0.5, 0.2), GOLD, METAL)
		end,
	}

	-- A hermit crab that moved into a lost miner's hard hat, lamp and all.
	S.pb_t_hermit = {
		label = "Hardhat Hermit",
		set = "pebblebound",
		tint = C3(64, 176, 210),
		head = CFrame.new(0, 1.18, -0.10),
		neck = CFrame.new(0, -0.50, 0.80),
		back = CFrame.new(0, 0.40, -0.92),
		build = function(c, p)
			c:box(Vector3.new(1.80, 1.00, 1.80), CFrame.new(0, 0.50, -0.10), p.base)
			c:box(Vector3.new(0.34, 0.20, 1.70), CFrame.new(0, 1.06, -0.10), p.light)
			c:box(Vector3.new(2.20, 0.14, 2.24), CFrame.new(0, -0.02, 0.02), p.dark)
			c:cyl(Vector3.new(0.22, 0.46, 0.46), CFrame.new(0, 0.56, 0.86) * CFrame.Angles(0, math.pi / 2, 0), BRASS, METAL)
			c:cyl(Vector3.new(0.06, 0.34, 0.34), CFrame.new(0, 0.56, 0.98) * CFrame.Angles(0, math.pi / 2, 0), C3(255, 238, 170), NEON)
			-- The crab peeking out from under the brim.
			c:box(Vector3.new(1.40, 0.70, 1.20), CFrame.new(0, -0.46, 0.30), p.pale)
			c:eyes(-0.36, 0.92, 0.30, 0.15)
			c:box(Vector3.new(0.26, 0.08, 0.08), CFrame.new(0, -0.64, 0.92), INK)
			for _, s in ipairs(SIDES) do
				local k = s > 0 and 1.25 or 1
				c:box(Vector3.new(0.40 * k, 0.36 * k, 0.48 * k), CFrame.new((0.82 + 0.06 * k) * s, -0.56, 0.86), p.light)
				c:cone(Vector3.new(0.30 * k, 0.36 * k, 0.26 * k), CFrame.new((0.84 + 0.06 * k) * s, -0.52, 1.20) * CFrame.Angles(math.pi / 2, 0, 0), p.light)
				for _, z in ipairs({ 0.10, -0.40 }) do
					c:rod(Vector3.new(0.60 * s, -0.56, z), Vector3.new(1.06 * s, -1.02, z - 0.12), 0.07, p.light, nil, false)
				end
			end
		end,
	}

	-- A woolly pack llama with banana ears and saddlebags full of ore.
	S.pb_t_llama = {
		label = "Ore Llama",
		set = "pebblebound",
		tint = C3(238, 224, 184),
		head = CFrame.new(0, 1.18, 0.20),
		neck = CFrame.new(0, -0.26, 0.66),
		back = CFrame.new(0, 1.10, -0.40),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.70, 1.96, 1.70),
				snout = { w = 0.62, h = 0.46, d = 0.40, y = -0.30, color = p.pale },
				eyeY = 0.30, eyeSpread = 0.40, eyeSize = Vector3.new(0.40, 0.50, 0.20),
				legSize = Vector3.new(0.34, 0.40, 0.38), legX = 0.52, legY = -1.06, legColor = p.dark,
				tailSize = Vector3.new(0.30, 0.40, 0.30),
			})
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.24, 0.62, 0.22), CFrame.new(0.46 * s, 1.32, 0.20) * CFrame.Angles(0, 0, -0.14 * s), p.base)
				c:box(Vector3.new(0.20, 0.24, 0.20), CFrame.new(0.40 * s, 1.66, 0.22) * CFrame.Angles(0, 0, 0.5 * s), p.base)
				c:box(Vector3.new(0.34, 0.66, 0.84), CFrame.new(0.98 * s, 0.10, -0.24), C3(150, 96, 60), WOOD)
				c:box(Vector3.new(0.30, 0.26, 0.30), CFrame.new(0.96 * s, 0.52, -0.10) * CFrame.Angles(0.3, 0.4, 0.2), s > 0 and GOLD or COPPER, METAL)
			end
			c:box(Vector3.new(1.80, 0.12, 0.70), CFrame.new(0, 1.06, -0.24), p.deep)
			c:box(Vector3.new(0.66, 0.30, 0.56), CFrame.new(0, 1.16, 0.34), p.light)
		end,
	}

	-- A fuzzy moth whose wings are thin, glassy sheets of mica.
	S.pb_t_micamoth = {
		label = "Mica Moth",
		set = "pebblebound",
		tint = C3(196, 164, 240),
		scale = 1.15,
		head = CFrame.new(0, 0.98, 0.10),
		neck = CFrame.new(0, -0.40, 0.62),
		back = CFrame.new(0, 0.30, -0.62),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.40, 1.50, 1.30),
				eyeY = 0.12, eyeSpread = 0.34, eyeSize = Vector3.new(0.40, 0.46, 0.18),
				mouthY = -0.30, mouthSize = Vector3.new(0.22, 0.12, 0.12),
				legs = false, tail = false,
			})
			c:box(Vector3.new(1.56, 0.32, 1.42), CFrame.new(0, 0.66, 0), p.pale)
			c:box(Vector3.new(0.86, 0.66, 0.70), CFrame.new(0, -0.40, -0.84) * CFrame.Angles(0.3, 0, 0), p.dark)
			for _, s in ipairs(SIDES) do
				local up = CFrame.new(0.98 * s, 0.56, -0.30) * CFrame.Angles(0, 0.30 * s, -0.40 * s)
				c:box(Vector3.new(1.00, 1.04, 0.06), up, p.light, GLASS)
				c:box(Vector3.new(0.30, 0.30, 0.04), up * CFrame.new(0.16 * s, 0.10, 0.05), p.deep)
				c:box(Vector3.new(0.76, 0.74, 0.06), CFrame.new(0.88 * s, -0.36, -0.36) * CFrame.Angles(0, 0.30 * s, 0.40 * s), p.base, GLASS)
				c:rod(Vector3.new(0.22 * s, 0.80, 0.40), Vector3.new(0.48 * s, 1.30, 0.72), 0.05, p.deep, nil, false)
				c:cone(Vector3.new(0.24, 0.34, 0.10), CFrame.new(0.48 * s, 1.34, 0.72) * CFrame.Angles(0.5, 0, -0.4 * s), p.dark)
			end
		end,
	}

	-- A fossil come back to life: crescent head shield, ribbed three-lobed back.
	S.pb_t_trilobite = {
		label = "Shale Trilobite",
		set = "pebblebound",
		tint = C3(70, 120, 120),
		scale = 1.10,
		head = CFrame.new(0, 0.46, 0.70),
		neck = CFrame.new(0, -0.56, 1.10),
		back = CFrame.new(0, 0.20, -0.80),
		build = function(c, p)
			c:box(Vector3.new(2.10, 1.00, 0.80), CFrame.new(0, -0.26, 0.70), p.base, SLATE)
			c:eyes(-0.18, 1.12, 0.40, 0.17)
			c:box(Vector3.new(0.34, 0.10, 0.08), CFrame.new(0, -0.52, 1.12), INK)
			c:box(Vector3.new(1.80, 0.80, 1.70), CFrame.new(0, -0.40, -0.40), p.dark, SLATE)
			c:box(Vector3.new(0.56, 0.30, 2.10), CFrame.new(0, 0.04, -0.30), p.light, SLATE)
			for i = 0, 3 do
				c:box(Vector3.new(1.90 - i * 0.18, 0.12, 0.22), CFrame.new(0, 0.02, 0.10 - i * 0.38), p.light, SLATE)
			end
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.40, 0.30, 0.40), CFrame.new(0.50 * s, 0.30, 0.76), p.light)
				c:cone(Vector3.new(0.20, 0.90, 0.24), CFrame.new(1.00 * s, -0.56, 0.00) * CFrame.Angles(-math.pi / 2, 0, 0), p.base, SLATE)
				for _, z in ipairs({ -0.10, -0.70 }) do
					c:box(Vector3.new(0.30, 0.22, 0.16), CFrame.new(0.82 * s, -0.86, z), p.deep)
				end
			end
			c:cone(Vector3.new(0.40, 0.50, 0.30), CFrame.new(0, -0.44, -1.40) * CFrame.Angles(-math.pi / 2, 0, 0), p.dark, SLATE)
		end,
	}

	-- An ammonite: a ribbed spiral shell with a curious face and a tentacle fringe.
	S.pb_t_ammonite = {
		label = "Coil Ammonite",
		set = "pebblebound",
		tint = C3(110, 214, 170),
		head = CFrame.new(0, 1.46, -0.36),
		neck = CFrame.new(0, -0.70, 0.96),
		back = CFrame.new(0, 0.30, -1.30),
		build = function(c, p)
			c:cyl(Vector3.new(1.20, 2.30, 2.30), CFrame.new(0, 0.30, -0.36), p.base, SLATE)
			c:cyl(Vector3.new(1.32, 1.60, 1.60), CFrame.new(0, 0.40, -0.44), p.light, SLATE)
			c:cyl(Vector3.new(1.44, 0.86, 0.86), CFrame.new(0, 0.48, -0.50), p.dark, SLATE)
			c:cyl(Vector3.new(1.54, 0.30, 0.30), CFrame.new(0, 0.52, -0.54), p.pale, SLATE)
			for _, s in ipairs(SIDES) do
				for i = 0, 2 do
					local a = i * 2.1 + 0.4
					c:box(Vector3.new(0.06, 0.12, 0.30), CFrame.new(0.62 * s, 0.30, -0.36) * CFrame.Angles(a, 0, 0) * CFrame.new(0, 0, 0.96), p.dark)
				end
			end
			c:box(Vector3.new(1.10, 0.90, 0.60), CFrame.new(0, -0.44, 0.74), p.pale)
			c:eyes(-0.28, 1.06, 0.26, 0.15)
			c:box(Vector3.new(0.22, 0.08, 0.08), CFrame.new(0, -0.60, 1.05), INK)
			for i = -2, 2 do
				c:rod(Vector3.new(i * 0.20, -0.82, 0.80), Vector3.new(i * 0.28, -1.12, 1.14 - math.abs(i) * 0.08), 0.07, p.light, nil, false)
			end
		end,
	}

	-- A horseshoe magnet standing on its poles, an iron nugget stuck between them.
	S.pb_t_magnet = {
		label = "Lodestone Magnet",
		set = "pebblebound",
		tint = C3(222, 40, 52),
		head = CFrame.new(0, 1.12, 0),
		neck = CFrame.new(0, 0.10, 0.56),
		back = CFrame.new(0, 0.70, -0.50),
		build = function(c, p)
			c:box(Vector3.new(1.40, 0.80, 0.90), CFrame.new(0, 0.70, 0), p.base)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.56, 0.56, 0.90), CFrame.new(0.68 * s, 0.62, 0) * CFrame.Angles(0, 0, 0.62 * s), p.base)
				c:box(Vector3.new(0.62, 1.20, 0.90), CFrame.new(0.66 * s, -0.24, 0), p.base)
				c:box(Vector3.new(0.66, 0.40, 0.94), CFrame.new(0.66 * s, -1.02, 0), IRON, METAL)
				c:box(Vector3.new(0.20, 0.12, 0.06), CFrame.new(0.42 * s, 0.52, 0.47), BLUSH)
				c:box(Vector3.new(0.40, 0.18, 0.30), CFrame.new(1.04 * s, 0.10, 0.10) * CFrame.Angles(0, 0, -0.5 * s), p.dark)
			end
			c:eyes(0.78, 0.48, 0.28, 0.14)
			c:box(Vector3.new(0.26, 0.10, 0.08), CFrame.new(0, 0.54, 0.47), INK)
			c:box(Vector3.new(0.40, 0.36, 0.40), CFrame.new(0, -0.66, 0.10) * CFrame.Angles(0.4, 0.6, 0.2), IRON, METAL)
			for _, v in ipairs({ { -0.16, -0.20, 0.20 }, { 0.14, -0.30, -0.10 }, { 0.02, 0.06, 0.04 } }) do
				c:box(Vector3.new(0.10, 0.10, 0.10), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0.6, 0.6, 0), IRON, METAL)
			end
		end,
	}

	-- Pumice floats: a light, holey stone cloud bobbing over two dust puffs.
	S.pb_t_pumice = {
		label = "Pumice Puff",
		set = "pebblebound",
		tint = C3(208, 216, 232),
		head = CFrame.new(0, 1.30, 0),
		neck = CFrame.new(0, -0.40, 0.72),
		back = CFrame.new(0, 0.30, -0.72),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(2.10, 1.40, 1.60), bodyMat = SLATE,
				eyeY = 0.04, eyeSpread = 0.40, eyeSize = Vector3.new(0.42, 0.50, 0.20),
				mouthY = -0.34, mouthSize = Vector3.new(0.26, 0.12, 0.12),
				legs = false, tail = false,
			})
			c:box(Vector3.new(0.90, 0.70, 0.90), CFrame.new(-0.46, 0.86, -0.06), p.light, SLATE)
			c:box(Vector3.new(0.80, 0.60, 0.80), CFrame.new(0.50, 0.80, 0.08), p.light, SLATE)
			c:box(Vector3.new(0.64, 0.50, 0.64), CFrame.new(0.06, 1.12, -0.10), p.pale, SLATE)
			spots(c, p.dark, { { -0.72, 0.40, 0.82 }, { 0.74, 0.32, 0.82 }, { -1.06, -0.10, 0.30 }, { 1.06, 0.00, -0.20 } }, Vector3.new(0.16, 0.14, 0.12))
			c:box(Vector3.new(0.40, 0.30, 0.40), CFrame.new(-0.42, -1.00, 0.10), p.pale)
			c:box(Vector3.new(0.30, 0.22, 0.30), CFrame.new(0.40, -1.10, -0.10), p.pale)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.30, 0.22, 0.26), CFrame.new(1.16 * s, -0.20, 0.20) * CFrame.Angles(0, 0, -0.4 * s), p.base)
			end
		end,
	}

	-- One tall dripstone point growing up from the cave floor, a drop about to land.
	S.pb_t_stalagmite = {
		label = "Stalagmite Sprout",
		set = "pebblebound",
		tint = C3(232, 170, 140),
		head = CFrame.new(0, 1.50, 0),
		neck = CFrame.new(0, -0.56, 0.74),
		back = CFrame.new(0, -0.20, -0.66),
		build = function(c, p)
			-- A pyramid from y = -1.05 to 1.45; the face sits out on its front slope.
			c:cone(Vector3.new(1.80, 2.50, 1.70), CFrame.new(0, 0.20, 0), p.base, SLATE)
			c:box(Vector3.new(1.96, 0.36, 1.86), CFrame.new(0, -0.90, 0), p.dark, SLATE)
			c:box(Vector3.new(0.92, 0.12, 0.88), CFrame.new(0, 0.30, 0), p.light, SLATE)
			c:box(Vector3.new(0.56, 0.10, 0.54), CFrame.new(0, 0.80, 0), p.light, SLATE)
			c:eyes(-0.26, 0.62, 0.26, 0.15)
			c:box(Vector3.new(0.24, 0.08, 0.08), CFrame.new(0, -0.56, 0.71), INK)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.18, 0.10, 0.06), CFrame.new(0.42 * s, -0.46, 0.68), BLUSH)
				c:box(Vector3.new(0.40, 0.20, 0.44), CFrame.new(0.48 * s, -1.04, 0.80), p.deep)
				c:box(Vector3.new(0.30, 0.24, 0.24), CFrame.new(0.76 * s, -0.30, 0.10) * CFrame.Angles(0, 0, -0.5 * s), p.base)
				c:cone(Vector3.new(0.34, 0.56, 0.34), CFrame.new(0.88 * s, -0.44, -0.30), p.light, SLATE)
			end
			c:ball(Vector3.new(0.26, 0.34, 0.26), CFrame.new(0, 1.72, 0), C3(170, 220, 255), GLASS)
		end,
	}

	-- A woodpecker for rock: a steel chisel beak, a red crest and a stiff tail prop.
	S.pb_t_rockpecker = {
		label = "Rockpecker",
		set = "pebblebound",
		tint = C3(56, 96, 204),
		head = CFrame.new(0, 1.12, 0.06),
		neck = CFrame.new(0, -0.20, 0.66),
		back = CFrame.new(0, 0.30, -0.66),
		build = function(c, p)
			local crest, steel = C3(222, 52, 48), C3(132, 136, 150)
			block(c, p, {
				shape = "bird", bodySize = Vector3.new(1.60, 2.00, 1.50),
				eyeY = 0.42, eyeSpread = 0.36, eyeSize = Vector3.new(0.40, 0.46, 0.20),
				bib = { w = 0.90, h = 0.90, y = -0.36, color = p.pale },
				mouth = false, legs = false, tail = false,
			})
			c:box(Vector3.new(0.30, 0.26, 0.70), CFrame.new(0, 0.14, 1.04), steel, METAL)
			c:wedge(Vector3.new(0.30, 0.26, 0.30), CFrame.new(0, 0.14, 1.54) * CFrame.Angles(0, math.pi, 0), steel, METAL)
			c:cone(Vector3.new(0.30, 0.50, 0.44), CFrame.new(0, 1.26, 0.10) * CFrame.Angles(-0.5, 0, 0), crest)
			c:cone(Vector3.new(0.26, 0.40, 0.36), CFrame.new(0, 1.14, -0.26) * CFrame.Angles(-0.9, 0, 0), crest)
			c:box(Vector3.new(0.50, 0.14, 0.90), CFrame.new(0, -0.74, -0.96) * CFrame.Angles(-0.6, 0, 0), p.dark)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.06, 0.16, 0.90), CFrame.new(0.82 * s, 0.22, 0.20), WHITE)
				c:box(Vector3.new(0.20, 1.10, 1.00), CFrame.new(0.86 * s, 0.00, -0.24) * CFrame.Angles(0, 0, -0.08 * s), p.dark)
				c:box(Vector3.new(0.36, 0.16, 0.40), CFrame.new(0.36 * s, -0.98, 0.30), C3(70, 66, 76))
			end
		end,
	}

	-- A little blind-cave minnow, pink and round, trailing a bubble.
	S.pb_t_minnow = {
		label = "Grotto Minnow",
		set = "pebblebound",
		tint = C3(252, 164, 196),
		head = CFrame.new(0, 1.00, 0.10),
		neck = CFrame.new(0, -0.40, 0.84),
		back = CFrame.new(0, 0.30, -0.84),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.50, 1.60, 2.00),
				eyeY = 0.18, eyeSpread = 0.36, eyeSize = Vector3.new(0.40, 0.46, 0.18),
				mouthY = -0.24, mouthSize = Vector3.new(0.36, 0.20, 0.14), mouthColor = C3(200, 90, 120),
				legs = false, tail = false,
			})
			for _, v in ipairs({ { 1, -0.5 }, { -1, 0.5 } }) do
				c:box(Vector3.new(0.12, 0.86, 0.56), CFrame.new(0, 0.30 * v[1], -1.24) * CFrame.Angles(v[2], 0, 0), p.light)
			end
			c:box(Vector3.new(0.12, 0.50, 0.70), CFrame.new(0, 0.96, -0.10) * CFrame.Angles(-0.3, 0, 0), p.light)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.40, 0.10, 0.36), CFrame.new(0.86 * s, -0.30, 0.30) * CFrame.Angles(0, 0, -0.5 * s), p.light)
			end
			c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(0.30, 1.00, 1.10), C3(200, 236, 255), GLASS)
			c:ball(Vector3.new(0.14, 0.14, 0.14), CFrame.new(0.46, 1.30, 1.22), C3(200, 236, 255), GLASS)
		end,
	}

	-- Fool's gold: a shiny cube with smaller cubes grown into it at angles.
	S.pb_t_pyrite = {
		label = "Pyrite Cluster",
		set = "pebblebound",
		tint = C3(210, 170, 50),
		head = CFrame.new(0, 1.30, 0),
		neck = CFrame.new(0, -0.36, 0.72),
		back = CFrame.new(0, 0.20, -0.72),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.80, 1.70, 1.70), bodyMat = METAL,
				eyeY = 0.10, eyeSpread = 0.40, eyeSize = Vector3.new(0.44, 0.52, 0.20),
				mouthY = -0.36, legSize = Vector3.new(0.40, 0.30, 0.44), legY = -0.88, legColor = p.deep, tail = false,
			})
			for i, v in ipairs({
				{ 0.80, 0.50, 0.96, -0.10, 0.3, 0.5, 0.2 },
				{ 0.60, -0.46, 0.92, 0.10, -0.2, 0.3, 0.4 },
				{ 0.50, -0.06, 1.26, -0.40, 0.4, 0.8, 0.1 },
				{ 0.56, 0.96, -0.10, -0.40, 0.3, 0.2, 0.5 },
				{ 0.46, -0.96, 0.20, -0.30, 0.5, 0.3, 0.2 },
				{ 0.40, 0.60, -0.40, -0.92, 0.2, 0.6, 0.3 },
			}) do
				c:box(Vector3.new(v[1], v[1], v[1]), CFrame.new(v[2], v[3], v[4]) * CFrame.Angles(v[5], v[6], v[7]), (i % 2 == 0) and p.light or p.base, METAL)
			end
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.20, 0.12, 0.06), CFrame.new(0.52 * s, -0.20, 0.87), BLUSH)
			end
		end,
	}

	-- A puppy laid like a little brick wall, mortar lines and all.
	S.pb_t_brickpup = {
		label = "Brick Pup",
		set = "pebblebound",
		tint = C3(182, 70, 46),
		head = CFrame.new(0, 1.04, 0.06),
		neck = CFrame.new(0, -0.36, 0.66),
		back = CFrame.new(0, 0.30, -0.66),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.90, 1.70, 1.80),
				snout = { w = 0.70, h = 0.44, d = 0.40, y = -0.26, color = p.pale },
				eyeY = 0.24, eyeSize = Vector3.new(0.46, 0.54, 0.20),
				legSize = Vector3.new(0.42, 0.34, 0.46), legColor = p.dark, tail = false,
			})
			ears(c, p.dark, "down")
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.04, 0.06, 1.80), CFrame.new(0.96 * s, 0.30, 0), p.pale)
				c:box(Vector3.new(0.04, 0.06, 1.80), CFrame.new(0.96 * s, -0.24, 0), p.pale)
				c:box(Vector3.new(0.04, 0.54, 0.06), CFrame.new(0.96 * s, 0.03, 0.24 * s), p.pale)
			end
			c:box(Vector3.new(1.90, 0.04, 0.06), CFrame.new(0, 0.92, -0.30), p.pale)
			c:box(Vector3.new(0.06, 0.04, 0.60), CFrame.new(0.20, 0.92, -0.60), p.pale)
			c:box(Vector3.new(0.24, 0.24, 0.62), CFrame.new(0, 0.30, -1.06) * CFrame.Angles(0.7, 0, 0), p.base)
			c:box(Vector3.new(1.20, 0.16, 0.10), CFrame.new(0, -0.60, 0.92), C3(60, 120, 200))
			c:cyl(Vector3.new(0.06, 0.24, 0.24), CFrame.new(0, -0.76, 0.96) * CFrame.Angles(0, math.pi / 2, 0), COPPER, METAL)
		end,
	}

	-- An inchworm mid-inch: a gravel-studded arch, the head end down in front.
	S.pb_t_inchworm = {
		label = "Gravel Inchworm",
		set = "pebblebound",
		tint = C3(150, 210, 70),
		head = CFrame.new(0, 1.16, 0),
		neck = CFrame.new(0, -0.70, 1.10),
		back = CFrame.new(0, 0.10, -0.80),
		build = function(c, p)
			-- Segments along an arch from the back foot, over the top, to the head.
			for i = 0, 5 do
				local t = math.pi - i * math.pi / 6
				local z, y = 0.90 * math.cos(t), -0.70 + 1.40 * math.sin(t)
				local tilt = math.atan2(1.40 * math.cos(t), 0.90 * math.sin(t))
				c:box(Vector3.new(0.90, 0.74, 0.70), CFrame.new(0, y, z) * CFrame.Angles(tilt, 0, 0), (i % 2 == 0) and p.base or p.light)
			end
			c:box(Vector3.new(1.10, 1.00, 0.86), CFrame.new(0, -0.40, 0.76), p.base)
			c:eyes(-0.28, 1.20, 0.26, 0.15)
			c:box(Vector3.new(0.24, 0.08, 0.08), CFrame.new(0, -0.62, 1.20), INK)
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.24 * s, 0.08, 0.86), Vector3.new(0.40 * s, 0.42, 1.04), 0.04, p.deep, nil, false)
				c:ball(Vector3.new(0.14, 0.14, 0.14), CFrame.new(0.40 * s, 0.42, 1.04), p.deep)
				c:box(Vector3.new(0.30, 0.20, 0.34), CFrame.new(0.32 * s, -0.98, 0.76), p.dark)
				c:box(Vector3.new(0.30, 0.20, 0.34), CFrame.new(0.32 * s, -0.98, -0.90), p.dark)
			end
			for _, v in ipairs({ { -0.18, 1.10, -0.10 }, { 0.20, 1.04, 0.24 }, { 0.04, 0.90, -0.52 } }) do
				c:box(Vector3.new(0.22, 0.18, 0.22), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0.4, 0.6, 0.2), C3(150, 146, 140), SLATE)
			end
		end,
	}

	-- A masked raccoon panning for gold, two nuggets already in its pan.
	S.pb_t_raccoon = {
		label = "Gold Pan Raccoon",
		set = "pebblebound",
		tint = C3(100, 104, 120),
		head = CFrame.new(0, 1.14, 0.06),
		neck = CFrame.new(0, -0.10, 0.70),
		back = CFrame.new(0, 0.30, -0.64),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.90, 1.90, 1.60),
				snout = { w = 0.50, h = 0.34, d = 0.34, y = -0.12, color = p.pale },
				eyeY = 0.30, eyeSpread = 0.40, eyeSize = Vector3.new(0.40, 0.46, 0.20), brow = p.pale,
				bib = { w = 1.00, h = 0.70, y = -0.56, color = p.pale },
				legZ = { -0.30 }, legSize = Vector3.new(0.50, 0.30, 0.60), legColor = p.deep, tail = false,
			})
			c:box(Vector3.new(1.50, 0.40, 0.08), CFrame.new(0, 0.30, 0.82), p.deep)
			ears(c, p.dark, "round", p.pale)
			c:box(Vector3.new(0.40, 0.40, 0.44), CFrame.new(0.36, -0.60, -0.96), p.base)
			c:box(Vector3.new(0.38, 0.38, 0.40), CFrame.new(0.70, -0.44, -1.18) * CFrame.Angles(0, 0.6, 0.3), p.deep)
			c:box(Vector3.new(0.34, 0.34, 0.36), CFrame.new(0.96, -0.14, -1.22) * CFrame.Angles(0, 0.9, 0.6), p.base)
			c:cyl(Vector3.new(0.10, 1.00, 1.00), CFrame.new(0, -0.62, 1.12) * CFrame.Angles(0.45, 0, 0) * CFrame.Angles(0, 0, math.pi / 2), C3(110, 96, 90), METAL)
			c:box(Vector3.new(0.20, 0.16, 0.20), CFrame.new(-0.16, -0.54, 1.12) * CFrame.Angles(0.3, 0.5, 0), GOLD, METAL)
			c:box(Vector3.new(0.16, 0.14, 0.16), CFrame.new(0.18, -0.52, 1.24) * CFrame.Angles(0.2, 0.9, 0), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.30, 0.30, 0.40), CFrame.new(0.46 * s, -0.52, 0.92), p.deep)
			end
		end,
	}

	----------------------------------------------------------------------------
	-- LEGENDARY: more ornate; the miner's world come to life.
	----------------------------------------------------------------------------

	-- A cheerful minecart heaped with ore, rolling along its own bit of track.
	S.pb_t_minecart = {
		label = "Rumble Minecart",
		set = "pebblebound",
		tint = C3(200, 44, 60),
		head = CFrame.new(0, 1.16, 0),
		neck = CFrame.new(0, -0.30, 0.86),
		back = CFrame.new(0, 0.10, -0.88),
		build = function(c, p)
			local plank = C3(120, 84, 52)
			c:box(Vector3.new(1.90, 1.00, 1.60), CFrame.new(0, -0.10, 0), p.base, METAL)
			c:box(Vector3.new(2.06, 0.16, 1.76), CFrame.new(0, 0.46, 0), p.dark, METAL)
			c:box(Vector3.new(1.96, 0.12, 1.66), CFrame.new(0, -0.50, 0), p.deep, METAL)
			c:eyes(0.08, 0.82, 0.36, 0.17)
			c:box(Vector3.new(0.36, 0.10, 0.06), CFrame.new(0, -0.24, 0.82), INK)
			-- The ore heap: a dark pile with gold, copper and pale nuggets on it.
			c:box(Vector3.new(1.50, 0.30, 1.24), CFrame.new(0, 0.62, 0), p.deep)
			c:box(Vector3.new(0.40, 0.34, 0.40), CFrame.new(-0.40, 0.86, 0.20) * CFrame.Angles(0.3, 0.6, 0.2), GOLD, METAL)
			c:box(Vector3.new(0.46, 0.40, 0.44), CFrame.new(0.32, 0.90, -0.12) * CFrame.Angles(0.2, 0.3, -0.3), p.light)
			c:box(Vector3.new(0.34, 0.30, 0.34), CFrame.new(-0.06, 1.00, -0.36) * CFrame.Angles(0.5, 0.9, 0.1), COPPER, METAL)
			c:box(Vector3.new(0.26, 0.24, 0.26), CFrame.new(0.52, 0.80, 0.38) * CFrame.Angles(0.4, 0.2, 0.6), GOLD, METAL)
			c:box(Vector3.new(0.30, 0.26, 0.30), CFrame.new(-0.54, 0.80, -0.38) * CFrame.Angles(0.1, 0.7, 0.3), p.pale)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.22, 0.12, 0.04), CFrame.new(0.62 * s, -0.14, 0.81), BLUSH)
				for _, z in ipairs(SIDES) do
					c:cyl(Vector3.new(0.18, 0.56, 0.56), CFrame.new(0.98 * s, -0.66, 0.50 * z), IRON, METAL)
					c:cyl(Vector3.new(0.06, 0.22, 0.22), CFrame.new(1.09 * s, -0.66, 0.50 * z), BRASS, METAL)
				end
				c:box(Vector3.new(0.10, 0.08, 2.10), CFrame.new(0.98 * s, -0.98, 0), IRON, METAL)
			end
			for _, z in ipairs({ -0.70, 0, 0.70 }) do
				c:box(Vector3.new(2.30, 0.10, 0.26), CFrame.new(0, -1.07, z), plank, WOOD)
			end
		end,
	}

	-- A round tunnel lantern on stubby feet, its little flame peeking out the top.
	S.pb_t_lantern = {
		label = "Tunnel Lantern",
		set = "pebblebound",
		tint = C3(255, 206, 84),
		head = CFrame.new(0, 1.30, 0),
		neck = CFrame.new(0, -0.44, 0.80),
		back = CFrame.new(0, 0, -0.80),
		build = function(c, p)
			local UP = CFrame.Angles(0, 0, math.pi / 2)
			c:cyl(Vector3.new(1.40, 1.50, 1.50), CFrame.new(0, -0.10, 0) * UP, p.pale)
			c:cyl(Vector3.new(0.16, 1.62, 1.62), CFrame.new(0, 0.54, 0) * UP, p.base, METAL)
			c:cyl(Vector3.new(0.16, 1.62, 1.62), CFrame.new(0, -0.74, 0) * UP, p.base, METAL)
			c:cyl(Vector3.new(0.24, 1.76, 1.76), CFrame.new(0, -0.92, 0) * UP, p.dark, METAL)
			for i = 0, 3 do
				local a = math.pi / 4 + i * math.pi / 2
				c:box(Vector3.new(0.12, 1.30, 0.12), CFrame.new(math.sin(a) * 0.76, -0.10, math.cos(a) * 0.76) * CFrame.Angles(0, a, 0), p.base, METAL)
			end
			c:eyes(0.02, 0.74, 0.30, 0.17)
			c:box(Vector3.new(0.28, 0.10, 0.06), CFrame.new(0, -0.30, 0.76), INK)
			c:round(Vector3.new(1.44, 0.70, 1.44), CFrame.new(0, 0.80, 0), p.dark, METAL)
			c:cyl(Vector3.new(0.30, 0.44, 0.44), CFrame.new(0, 1.24, 0) * UP, p.base, METAL)
			c:cone(Vector3.new(0.24, 0.42, 0.24), CFrame.new(0, 1.58, 0), C3(255, 196, 84), NEON)
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.70 * s, 0.56, 0), Vector3.new(0.46 * s, 1.88, 0), 0.05, BRASS, METAL, false)
				c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0.82 * s, 0.54, 0), BRASS, METAL)
				c:box(Vector3.new(0.40, 0.20, 0.50), CFrame.new(0.42 * s, -1.12, 0.16), p.deep)
				c:box(Vector3.new(0.22, 0.12, 0.04), CFrame.new(0.50 * s, -0.20, 0.58) * CFrame.Angles(0, 0.73 * s, 0), BLUSH)
			end
			c:rod(Vector3.new(-0.46, 1.88, 0), Vector3.new(0.46, 1.88, 0), 0.05, BRASS, METAL, false)
		end,
	}

	-- A burrowing badger: a white stripe from nose to tail, big digging claws, a find on its back.
	S.pb_t_badger = {
		label = "Burrow Badger",
		set = "pebblebound",
		tint = C3(64, 66, 108),
		head = CFrame.new(0, 0.86, 0.30),
		neck = CFrame.new(0, -0.34, 0.98),
		back = CFrame.new(0, 0.80, -0.30),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = Vector3.new(2.00, 1.36, 1.84),
				snout = { w = 0.58, h = 0.38, d = 0.46, y = -0.20, color = p.pale },
				eyeY = 0.12, eyeSize = Vector3.new(0.36, 0.42, 0.20),
				legSize = Vector3.new(0.50, 0.34, 0.52), legColor = p.deep,
				tailSize = Vector3.new(0.40, 0.30, 0.36), tailColor = p.pale,
			})
			c:box(Vector3.new(0.30, 0.46, 0.08), CFrame.new(0, 0.50, 0.94), p.pale)
			c:box(Vector3.new(0.32, 0.10, 1.70), CFrame.new(0, 0.78, 0), p.pale)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.30, 0.24, 0.18), CFrame.new(0.66 * s, 0.86, 0.36), p.deep)
				for i = 0, 1 do
					c:cone(Vector3.new(0.10, 0.28, 0.10), CFrame.new(0.50 * s + i * 0.14 * s, -0.96, 0.76) * CFrame.Angles(math.pi / 2, 0, 0), BONE)
				end
			end
			-- What it dug up: a gold nugget riding on its back.
			c:box(Vector3.new(0.34, 0.28, 0.34), CFrame.new(0.24, 0.94, -0.56) * CFrame.Angles(0.4, 0.2, 0.3), GOLD, METAL)
		end,
	}

	-- A long-legged stag whose antlers grew as clear quartz points.
	S.pb_t_stag = {
		label = "Quartz Stag",
		set = "pebblebound",
		tint = C3(170, 230, 255),
		head = CFrame.new(0, 1.50, 0.10),
		neck = CFrame.new(0, -0.20, 0.90),
		back = CFrame.new(0, 0.90, -0.60),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.70, 1.46, 1.70),
				snout = { w = 0.50, h = 0.36, d = 0.40, y = -0.18, color = p.pale, nose = INK },
				eyeY = 0.20, eyeSpread = 0.38, eyeSize = Vector3.new(0.40, 0.50, 0.20),
				bib = { w = 0.80, h = 0.46, y = -0.44, color = p.pale },
				legs = false, tailSize = Vector3.new(0.30, 0.34, 0.24), tailColor = p.pale,
			})
			spots(c, p.pale, { { -0.40, 0.80, -0.30 }, { 0.36, 0.80, 0.06 } }, Vector3.new(0.24, 0.06, 0.24))
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.46, -0.46 }) do
					c:box(Vector3.new(0.28, 0.80, 0.30), CFrame.new(0.50 * s, -0.96, z), p.dark)
					c:box(Vector3.new(0.32, 0.14, 0.34), CFrame.new(0.50 * s, -1.38, z + 0.02), p.deep)
				end
				c:box(Vector3.new(0.40, 0.18, 0.16), CFrame.new(0.98 * s, 0.62, 0.40) * CFrame.Angles(0, 0, 0.35 * s), p.base)
				-- Antlers: a socket, a tall quartz point and a branch leaning out.
				c:box(Vector3.new(0.24, 0.14, 0.24), CFrame.new(0.40 * s, 0.84, 0.06), p.deep)
				c:cone(Vector3.new(0.22, 0.76, 0.22), CFrame.new(0.52 * s, 1.18, 0.02) * CFrame.Angles(0, 0, -0.35 * s), p.light, GLASS)
				c:cone(Vector3.new(0.16, 0.48, 0.16), CFrame.new(0.74 * s, 1.10, 0.10) * CFrame.Angles(0, 0, -0.95 * s), p.pale, GLASS)
			end
		end,
	}

	-- A bulldog shaped like a blacksmith's anvil: a flat top, a horn off one side, a big underbite.
	S.pb_t_anvil = {
		label = "Anvil Bulldog",
		set = "pebblebound",
		tint = C3(44, 72, 170),
		scale = 1.2,
		head = CFrame.new(0, 1.04, 0),
		neck = CFrame.new(0, -0.36, 0.90),
		back = CFrame.new(0, 0.30, -0.84),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.80, 1.30, 1.60),
				snout = { w = 0.96, h = 0.48, d = 0.34, y = -0.24, color = p.light, nose = INK },
				eyeY = 0.18, eyeSpread = 0.46, eyeSize = Vector3.new(0.38, 0.40, 0.20), brow = p.deep,
				legX = 0.66, legY = -0.74, legSize = Vector3.new(0.52, 0.34, 0.50),
				tailSize = Vector3.new(0.24, 0.24, 0.24),
			})
			-- The anvil: a flat steel top, the horn to one side, the square heel to the other.
			c:box(Vector3.new(2.20, 0.30, 1.70), CFrame.new(0, 0.86, 0), p.dark, METAL)
			c:cone(Vector3.new(0.50, 0.80, 0.44), CFrame.new(1.50, 0.86, 0) * CFrame.Angles(0, 0, -math.pi / 2), p.dark, METAL)
			c:box(Vector3.new(0.30, 0.30, 0.90), CFrame.new(-1.25, 0.86, 0), p.dark, METAL)
			c:box(Vector3.new(1.86, 0.14, 1.66), CFrame.new(0, -0.54, 0), BRASS, METAL)
			for _, s in ipairs(SIDES) do
				c:cone(Vector3.new(0.10, 0.18, 0.10), CFrame.new(0.26 * s, -0.40, 1.05), WHITE)
				c:box(Vector3.new(0.14, 0.40, 0.40), CFrame.new(0.95 * s, 0.36, 0.36) * CFrame.Angles(0, 0, 0.2 * s), p.deep)
				c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.50 * s, -0.54, 0.84), IRON, METAL)
			end
		end,
	}

	-- A sand hourglass in a little wooden frame; the face is on its full bottom bulb.
	S.pb_t_hourglass = {
		label = "Sand Hourglass",
		set = "pebblebound",
		tint = C3(236, 214, 160),
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, -0.56, 0.70),
		back = CFrame.new(0, 0, -0.80),
		build = function(c, p)
			local UP = CFrame.Angles(0, 0, math.pi / 2)
			c:box(Vector3.new(1.70, 0.24, 1.70), CFrame.new(0, -1.10, 0), p.dark, WOOD)
			c:box(Vector3.new(1.70, 0.24, 1.70), CFrame.new(0, 1.10, 0), p.dark, WOOD)
			c:box(Vector3.new(1.78, 0.08, 1.78), CFrame.new(0, -0.96, 0), BRASS, METAL)
			c:box(Vector3.new(1.78, 0.08, 1.78), CFrame.new(0, 0.96, 0), BRASS, METAL)
			for _, s in ipairs(SIDES) do
				for _, z in ipairs(SIDES) do
					c:cyl(Vector3.new(2.00, 0.16, 0.16), CFrame.new(0.72 * s, 0, 0.72 * z) * UP, p.deep, WOOD)
					c:ball(Vector3.new(0.26, 0.26, 0.26), CFrame.new(0.66 * s, -1.30, 0.66 * z), BRASS, METAL)
				end
				c:box(Vector3.new(0.20, 0.10, 0.04), CFrame.new(0.40 * s, -0.48, 0.53) * CFrame.Angles(0, 0.66 * s, 0), BLUSH)
			end
			-- The bulbs: the bottom one full of sand (and the face), the top one nearly empty.
			c:ball(Vector3.new(1.32, 1.32, 1.32), CFrame.new(0, -0.38, 0), p.base)
			c:ball(Vector3.new(1.00, 1.00, 1.00), CFrame.new(0, 0.50, 0), p.pale, GLASS)
			c:cyl(Vector3.new(0.30, 0.34, 0.34), CFrame.new(0, 0.10, 0) * UP, p.light)
			c:eyes(-0.30, 0.62, 0.26, 0.15)
			c:box(Vector3.new(0.14, 0.10, 0.06), CFrame.new(0, -0.58, 0.64), INK)
			c:cone(Vector3.new(0.40, 0.34, 0.40), CFrame.new(0, 1.39, 0), p.light)
		end,
	}

	-- A cave axolotl: a wide smile, feathery gill fronds and a long finned tail.
	S.pb_t_axolotl = {
		label = "Cavern Axolotl",
		set = "pebblebound",
		tint = C3(255, 150, 190),
		head = CFrame.new(0, 0.80, 0.30),
		neck = CFrame.new(0, -0.30, 0.90),
		back = CFrame.new(0, 0.80, -0.50),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.90, 1.20, 1.70),
				eyeY = 0.16, eyeSpread = 0.56, eyeSize = Vector3.new(0.30, 0.34, 0.20),
				mouthSize = Vector3.new(0.60, 0.08, 0.10), mouthY = -0.20,
				legSize = Vector3.new(0.36, 0.30, 0.40), legX = 0.74, legY = -0.62, tail = false,
			})
			-- Three gill fronds a side, each ending in a soft bobble.
			for _, s in ipairs(SIDES) do
				for _, f in ipairs({ { 0.40, 0.55, 0.16 }, { 0.48, 0.22, -0.06 }, { 0.38, -0.10, -0.26 } }) do
					local tip = Vector3.new((0.92 + f[1]) * s, 0.40 + f[2], 0.40 + f[3])
					c:rod(Vector3.new(0.92 * s, 0.40, 0.40), tip, 0.07, p.light, nil, false)
					c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(tip), p.pale)
				end
			end
			c:box(Vector3.new(0.50, 0.44, 0.80), CFrame.new(0, -0.06, -1.18), p.base)
			c:box(Vector3.new(0.10, 0.76, 1.20), CFrame.new(0, 0.02, -1.36), p.light)
			c:box(Vector3.new(0.10, 0.20, 1.20), CFrame.new(0, 0.76, -0.30), p.light)
			spots(c, p.dark, { { -0.50, 0.67, -0.30 }, { 0.40, 0.67, 0.10 }, { 0.34, 0.67, -0.56 } }, Vector3.new(0.18, 0.04, 0.18))
		end,
	}

	-- A stonemason beaver: buck teeth, a flat paddle tail and a little mallet for dressing stone.
	S.pb_t_beaver = {
		label = "Mason Beaver",
		set = "pebblebound",
		tint = C3(150, 92, 48),
		head = CFrame.new(0, 1.16, 0),
		neck = CFrame.new(0, -0.20, 0.86),
		back = CFrame.new(0, 0.20, -0.86),
		build = function(c, p)
			local plank = C3(150, 108, 66)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.80, 1.90, 1.60),
				snout = { w = 0.66, h = 0.40, d = 0.40, y = -0.12, color = p.pale },
				eyeY = 0.36, eyeSpread = 0.40, eyeSize = Vector3.new(0.38, 0.44, 0.20),
				bib = { w = 1.00, h = 0.66, y = -0.56, color = p.light },
				legs = false, tail = false,
			})
			c:box(Vector3.new(0.26, 0.24, 0.06), CFrame.new(0, -0.42, 1.02), WHITE)
			c:box(Vector3.new(0.03, 0.24, 0.07), CFrame.new(0, -0.42, 1.02), INK)
			-- The paddle tail, cross-hatched.
			c:box(Vector3.new(0.90, 0.14, 1.10), CFrame.new(0, -0.84, -1.30), p.dark)
			c:box(Vector3.new(0.92, 0.04, 0.06), CFrame.new(0, -0.76, -1.10), p.deep)
			c:box(Vector3.new(0.92, 0.04, 0.06), CFrame.new(0, -0.76, -1.50), p.deep)
			c:box(Vector3.new(0.06, 0.04, 1.00), CFrame.new(0, -0.76, -1.30), p.deep)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.30, 0.28, 0.18), CFrame.new(0.56 * s, 1.08, 0.10), p.dark)
				c:box(Vector3.new(0.50, 0.24, 0.66), CFrame.new(0.50 * s, -0.92, 0.36), p.deep)
			end
			-- One paw on its tummy, the other gripping the mallet.
			c:box(Vector3.new(0.30, 0.30, 0.30), CFrame.new(-0.62, -0.30, 0.86), p.deep)
			c:box(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0.96, -0.20, 0.40), p.deep)
			c:rod(Vector3.new(1.02, -0.70, 0.40), Vector3.new(1.02, 0.36, 0.40), 0.06, plank, WOOD, false)
			c:box(Vector3.new(0.30, 0.30, 0.52), CFrame.new(1.02, 0.46, 0.40), IRON, METAL)
		end,
	}

	-- A little stegosaur with a staggered row of slate plates and a spiked tail.
	S.pb_t_stegosaur = {
		label = "Slate Stegosaur",
		set = "pebblebound",
		tint = C3(150, 200, 60),
		head = CFrame.new(0, 1.30, 0.40),
		neck = CFrame.new(0, -0.30, 0.96),
		back = CFrame.new(0, 0.40, -0.96),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.90, 1.40, 1.86),
				snout = { w = 0.62, h = 0.36, d = 0.36, y = -0.24, color = p.pale },
				eyeY = 0.14, eyeSize = Vector3.new(0.38, 0.44, 0.20),
				legSize = Vector3.new(0.50, 0.40, 0.50), legY = -0.78, legColor = p.dark, tail = false,
			})
			for i = 0, 4 do
				local k = 0.46 - math.abs(i - 2) * 0.07
				c:box(Vector3.new(0.10, k, k), CFrame.new(i % 2 == 0 and 0.14 or -0.14, 0.70 + k * 0.71, 0.56 - i * 0.34) * CFrame.Angles(math.pi / 4, 0, 0), p.light, SLATE)
			end
			c:box(Vector3.new(0.64, 0.54, 0.60), CFrame.new(0, -0.10, -1.18), p.base)
			c:box(Vector3.new(0.44, 0.38, 0.50), CFrame.new(0, 0, -1.62), p.base)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.24, 0.12, 0.04), CFrame.new(0.70 * s, -0.20, 0.94), BLUSH)
				for _, z in ipairs({ -1.54, -1.76 }) do
					c:cone(Vector3.new(0.12, 0.42, 0.12), CFrame.new(0.32 * s, 0.14, z) * CFrame.Angles(0, 0, -1.0 * s), BONE)
				end
			end
		end,
	}

	-- A woolly mammoth calf: a curled trunk, two bone tusks, floppy ears and a shaggy hump.
	S.pb_t_mammoth = {
		label = "Fossil Mammoth",
		set = "pebblebound",
		tint = C3(226, 218, 200),
		head = CFrame.new(0, 1.30, 0.10),
		neck = CFrame.new(0, -0.40, 1.10),
		back = CFrame.new(0, 0.40, -0.90),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = Vector3.new(2.00, 1.80, 1.80),
				eyeY = 0.36, eyeSpread = 0.46, eyeSize = Vector3.new(0.34, 0.40, 0.20),
				mouth = false, legSize = Vector3.new(0.56, 0.44, 0.56), legColor = p.dark,
				tailSize = Vector3.new(0.20, 0.40, 0.20),
			})
			-- The trunk hangs from between the eyes and curls up at the tip.
			c:box(Vector3.new(0.42, 0.42, 0.30), CFrame.new(0, -0.02, 0.98), p.base)
			c:box(Vector3.new(0.36, 0.40, 0.30), CFrame.new(0, -0.38, 1.04), p.base)
			c:box(Vector3.new(0.30, 0.32, 0.30), CFrame.new(0, -0.68, 1.16) * CFrame.Angles(-0.5, 0, 0), p.base)
			c:box(Vector3.new(0.26, 0.24, 0.24), CFrame.new(0, -0.74, 1.40) * CFrame.Angles(-1.1, 0, 0), p.dark)
			for _, s in ipairs(SIDES) do
				local mid = Vector3.new(0.50 * s, -0.66, 1.20)
				c:rod(Vector3.new(0.30 * s, -0.24, 0.92), mid, 0.08, BONE, nil, false)
				c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(mid), BONE)
				c:rod(mid, Vector3.new(0.48 * s, -0.46, 1.50), 0.07, BONE, nil, false)
				c:box(Vector3.new(0.16, 0.84, 0.74), CFrame.new(1.12 * s, 0.24, 0.30) * CFrame.Angles(0, 0.2 * s, 0), p.dark)
			end
			c:box(Vector3.new(1.20, 0.30, 1.00), CFrame.new(0, 1.08, -0.10), p.dark)
		end,
	}

	-- A friendly mining robot on treads: a drill for one hand, an ore scoop for the other.
	S.pb_t_drillbot = {
		label = "Drill Bot",
		set = "pebblebound",
		tint = C3(36, 170, 190),
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, -0.30, 0.66),
		back = CFrame.new(0, 0.20, -0.66),
		build = function(c, p)
			c:box(Vector3.new(1.50, 1.30, 1.20), CFrame.new(0, 0.10, 0), p.base, METAL)
			c:box(Vector3.new(1.10, 0.66, 0.06), CFrame.new(0, 0.30, 0.62), p.pale)
			c:eyes(0.34, 0.68, 0.26, 0.15)
			c:box(Vector3.new(0.30, 0.08, 0.04), CFrame.new(0, 0.10, 0.66), INK)
			c:cyl(Vector3.new(0.06, 0.24, 0.24), CFrame.new(0, -0.30, 0.62) * CFrame.Angles(0, math.pi / 2, 0), BRASS, METAL)
			c:rod(Vector3.new(0, 0.75, 0), Vector3.new(0, 1.20, 0), 0.05, IRON, METAL, false)
			c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(0, 1.28, 0), C3(255, 92, 80), NEON)
			c:box(Vector3.new(1.00, 0.20, 0.80), CFrame.new(0, -0.62, 0), p.deep, METAL)
			for _, s in ipairs(SIDES) do
				c:cyl(Vector3.new(0.16, 0.30, 0.30), CFrame.new(0.82 * s, 0.34, 0), IRON, METAL)
				c:box(Vector3.new(0.46, 0.50, 1.40), CFrame.new(0.52 * s, -0.84, 0), p.dark)
				for _, z in ipairs(SIDES) do
					c:cyl(Vector3.new(0.06, 0.32, 0.32), CFrame.new(0.78 * s, -0.84, 0.44 * z), IRON, METAL)
				end
			end
			-- Right hand: a drill. Left hand: a scoop with a gold nugget in it.
			c:rod(Vector3.new(0.78, 0, 0), Vector3.new(1.06, -0.24, 0.50), 0.10, p.dark, METAL, false)
			c:cyl(Vector3.new(0.16, 0.40, 0.40), CFrame.new(1.06, -0.24, 0.60) * CFrame.Angles(0, math.pi / 2, 0), p.deep, METAL)
			c:cone(Vector3.new(0.34, 0.70, 0.34), CFrame.new(1.06, -0.24, 1.02) * CFrame.Angles(math.pi / 2, 0, 0), IRON, METAL)
			c:rod(Vector3.new(-0.78, 0, 0), Vector3.new(-1.06, -0.24, 0.44), 0.10, p.dark, METAL, false)
			c:box(Vector3.new(0.44, 0.24, 0.44), CFrame.new(-1.06, -0.32, 0.64), p.light, METAL)
			c:box(Vector3.new(0.24, 0.20, 0.24), CFrame.new(-1.06, -0.12, 0.64) * CFrame.Angles(0.3, 0.6, 0.2), GOLD, METAL)
		end,
	}

	-- An agate scorpion: big friendly pincers and a curled tail tipped with a round amber gem.
	S.pb_t_scorpion = {
		label = "Agate Scorpion",
		set = "pebblebound",
		tint = C3(236, 116, 64),
		scale = 1.2,
		head = CFrame.new(0, 0.30, 0.40),
		neck = CFrame.new(0, -0.50, 0.86),
		back = CFrame.new(0, 0.40, -0.40),
		build = function(c, p)
			c:box(Vector3.new(1.60, 0.84, 1.60), CFrame.new(0, -0.30, 0), p.base)
			c:eyes(-0.16, 0.82, 0.30, 0.16)
			c:box(Vector3.new(0.24, 0.08, 0.06), CFrame.new(0, -0.48, 0.81), INK)
			for i = -1, 1 do
				c:box(Vector3.new(1.66, 0.10, 0.40), CFrame.new(0, 0.16, i * 0.50), i == 0 and p.light or p.dark)
			end
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.70 * s, -0.40, 0.60), Vector3.new(1.00 * s, -0.30, 1.10), 0.10, p.dark, nil, false)
				c:box(Vector3.new(0.44, 0.34, 0.50), CFrame.new(1.00 * s, -0.30, 1.34), p.base)
				c:cone(Vector3.new(0.16, 0.36, 0.14), CFrame.new(1.10 * s, -0.24, 1.70) * CFrame.Angles(math.pi / 2, 0, 0), p.light)
				c:cone(Vector3.new(0.14, 0.30, 0.12), CFrame.new(0.90 * s, -0.36, 1.66) * CFrame.Angles(math.pi / 2, 0, 0), p.light)
				for _, z in ipairs({ 0.36, -0.04, -0.44 }) do
					c:rod(Vector3.new(0.78 * s, -0.56, z), Vector3.new(1.12 * s, -0.92, z - 0.10), 0.05, p.deep, nil, false)
				end
			end
			-- The tail curls up and forward over its back.
			c:box(Vector3.new(0.46, 0.42, 0.44), CFrame.new(0, -0.10, -0.92), p.base)
			c:box(Vector3.new(0.42, 0.40, 0.40), CFrame.new(0, 0.30, -1.14) * CFrame.Angles(0.4, 0, 0), p.dark)
			c:box(Vector3.new(0.38, 0.38, 0.38), CFrame.new(0, 0.72, -1.10) * CFrame.Angles(0.9, 0, 0), p.base)
			c:box(Vector3.new(0.34, 0.34, 0.34), CFrame.new(0, 1.06, -0.84) * CFrame.Angles(1.4, 0, 0), p.dark)
			c:ball(Vector3.new(0.40, 0.40, 0.40), CFrame.new(0, 1.16, -0.48), C3(255, 176, 60), GLASS)
		end,
	}

	----------------------------------------------------------------------------
	-- MYTHIC: the most spectacular; small p.glow neon accents, floating bits.
	----------------------------------------------------------------------------

	-- A little sitting drake crusted with druse crystals: bat wings, stubby horns, a glowing tail tip.
	S.pb_t_drake = {
		label = "Druse Drake",
		set = "pebblebound",
		tint = C3(40, 176, 96),
		scale = 1.2,
		head = CFrame.new(0, 1.30, 0.10),
		neck = CFrame.new(0, -0.20, 0.86),
		back = CFrame.new(0, 0.40, -0.90),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.70, 1.86, 1.60),
				snout = { w = 0.62, h = 0.38, d = 0.42, y = -0.10, color = p.light, nose = p.deep },
				eyeY = 0.36, eyeSpread = 0.40, eyeSize = Vector3.new(0.40, 0.48, 0.20),
				bib = { w = 0.90, h = 0.80, y = -0.50, color = p.pale },
				legSize = Vector3.new(0.44, 0.34, 0.50), legZ = { 0.36, -0.30 }, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(Vector3.new(0.22, 0.52, 0.22), CFrame.new(0.42 * s, 1.18, -0.10) * CFrame.Angles(-0.4, 0, -0.3 * s), p.pale)
				-- A bat wing: the arm, two membrane panels and a crystal claw at the top.
				c:rod(Vector3.new(0.70 * s, 0.60, -0.86), Vector3.new(1.50 * s, 1.24, -0.86), 0.07, p.deep, nil, false)
				c:box(Vector3.new(0.80, 0.66, 0.08), CFrame.new(1.12 * s, 0.70, -0.86) * CFrame.Angles(0, 0, 0.35 * s), p.dark)
				c:box(Vector3.new(0.56, 0.44, 0.08), CFrame.new(1.04 * s, 0.22, -0.86) * CFrame.Angles(0, 0, 0.15 * s), p.base)
				c:cone(Vector3.new(0.14, 0.32, 0.14), CFrame.new(1.56 * s, 1.36, -0.86) * CFrame.Angles(0, 0, -0.5 * s), p.glow, NEON)
				c:box(Vector3.new(0.16, 0.16, 0.16), CFrame.new(1.30 * s, 1.56, 0.30) * CFrame.Angles(0.6, 0.6, 0.6), p.glow, NEON)
			end
			-- Crystal spines on its crown and down its back, and a gem on its brow.
			c:cone(Vector3.new(0.24, 0.46, 0.24), CFrame.new(0, 1.20, -0.40) * CFrame.Angles(-0.5, 0, 0), p.glow, NEON)
			c:cone(Vector3.new(0.20, 0.40, 0.20), CFrame.new(0, 0.50, -1.00) * CFrame.Angles(-1.3, 0, 0), p.light, GLASS)
			c:box(Vector3.new(0.18, 0.18, 0.06), CFrame.new(0, 0.80, 0.81) * CFrame.Angles(0, 0, math.pi / 4), p.glow, NEON)
			-- The tail curls round to the front, a glowing crystal at its tip.
			c:box(Vector3.new(0.44, 0.40, 0.50), CFrame.new(0.40, -0.70, -0.98), p.base)
			c:box(Vector3.new(0.40, 0.36, 0.50), CFrame.new(0.86, -0.74, -0.70) * CFrame.Angles(0, 0.8, 0), p.base)
			c:box(Vector3.new(0.34, 0.32, 0.46), CFrame.new(1.08, -0.78, -0.24) * CFrame.Angles(0, 0.2, 0), p.dark)
			c:cone(Vector3.new(0.26, 0.44, 0.26), CFrame.new(1.10, -0.76, 0.18) * CFrame.Angles(math.pi / 2, 0, 0), p.glow, NEON)
		end,
	}

	-- A sunstone phoenix on its perch rock: a fan of glowing tail feathers and an ember crest.
	S.pb_t_phoenix = {
		label = "Sunstone Phoenix",
		set = "pebblebound",
		tint = C3(255, 112, 30),
		head = CFrame.new(0, 1.30, 0.10),
		neck = CFrame.new(0, -0.20, 0.72),
		back = CFrame.new(0, 0.20, -0.72),
		build = function(c, p)
			local beak = C3(255, 196, 70)
			c:box(Vector3.new(1.40, 1.50, 1.30), CFrame.new(0, 0, 0), p.base)
			c:box(Vector3.new(0.96, 0.80, 0.10), CFrame.new(0, -0.26, 0.68), p.pale)
			c:eyes(0.32, 0.70, 0.30, 0.16)
			c:cone(Vector3.new(0.26, 0.34, 0.24), CFrame.new(0, 0.06, 0.82) * CFrame.Angles(math.pi / 2, 0, 0), beak)
			for i = -1, 1 do
				c:cone(Vector3.new(0.18, 0.50 - math.abs(i) * 0.12, 0.18), CFrame.new(i * 0.20, 0.98, 0.10) * CFrame.Angles(-0.2, 0, -i * 0.4), p.glow, NEON)
			end
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.18, 0.86, 0.86), CFrame.new(0.78 * s, 0.10, -0.04) * CFrame.Angles(0, 0, -0.12 * s), p.dark)
				c:box(Vector3.new(0.16, 0.76, 0.60), CFrame.new(1.06 * s, 0.74, -0.14) * CFrame.Angles(0, 0, -0.55 * s), p.dark)
				c:cone(Vector3.new(0.16, 0.40, 0.16), CFrame.new(1.30 * s, 1.18, -0.14) * CFrame.Angles(0, 0, -0.55 * s), p.glow, NEON)
				c:rod(Vector3.new(0.30 * s, -0.70, 0.12), Vector3.new(0.30 * s, -1.04, 0.16), 0.06, beak, nil, false)
				c:box(Vector3.new(0.30, 0.08, 0.40), CFrame.new(0.30 * s, -1.08, 0.24), beak)
				c:box(Vector3.new(0.14, 0.14, 0.14), CFrame.new(0.92 * s, 1.56, 0.30) * CFrame.Angles(0.6, 0.6, 0.6), p.glow, NEON)
			end
			-- Five tail feathers fanned up behind it; every other one ends in a glowing eye.
			for i = -2, 2 do
				local a = i * 0.36
				c:box(Vector3.new(0.26, 1.10, 0.10), CFrame.new(math.sin(a) * 0.60, 0.20 + math.cos(a) * 0.60, -0.76) * CFrame.Angles(0, 0, -a), i % 2 == 0 and p.light or p.base)
				if i % 2 == 0 then
					c:box(Vector3.new(0.22, 0.22, 0.06), CFrame.new(math.sin(a) * 1.04, 0.20 + math.cos(a) * 1.04, -0.70) * CFrame.Angles(0, 0, math.pi / 4 - a), p.glow, NEON)
				end
			end
			c:box(Vector3.new(1.40, 0.30, 1.00), CFrame.new(0, -1.27, 0.10), p.deep, SLATE)
		end,
	}

	-- A floating opal medusa: a geode crown on its bell and glowing tips on its tentacles.
	S.pb_t_jelly = {
		label = "Opal Medusa",
		set = "pebblebound",
		tint = C3(206, 170, 255),
		head = CFrame.new(0, 1.60, 0),
		neck = CFrame.new(0, -0.10, 0.92),
		back = CFrame.new(0, 0.40, -0.92),
		build = function(c, p)
			local UP = CFrame.Angles(0, 0, math.pi / 2)
			c:round(Vector3.new(1.90, 1.40, 1.80), CFrame.new(0, 0.40, 0), p.base)
			c:eyes(0.40, 0.90, 0.34, 0.17)
			c:box(Vector3.new(0.26, 0.10, 0.06), CFrame.new(0, 0.08, 0.92), INK)
			c:cyl(Vector3.new(0.20, 2.10, 2.10), CFrame.new(0, -0.30, 0) * UP, p.light)
			c:cyl(Vector3.new(0.12, 1.70, 1.70), CFrame.new(0, -0.44, 0) * UP, p.dark)
			for _, s in ipairs(SIDES) do
				c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.74 * s, -0.30, 0.74), p.glow, NEON)
			end
			for i = 0, 4 do
				local a = i * math.pi * 2 / 5 + math.pi / 2
				local x, z = math.cos(a) * 0.56, math.sin(a) * 0.56
				local tip = Vector3.new(x * 1.3, -1.30, z * 1.3)
				c:rod(Vector3.new(x, -0.44, z), tip, 0.08, p.light, nil, false)
				c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(tip), p.glow, NEON)
			end
			-- The geode crown: a socket and a cluster of crystal points.
			c:box(Vector3.new(0.70, 0.16, 0.70), CFrame.new(0, 1.10, 0), p.deep)
			c:cone(Vector3.new(0.30, 0.64, 0.30), CFrame.new(0, 1.48, 0), p.glow, NEON)
			c:cone(Vector3.new(0.20, 0.44, 0.20), CFrame.new(0.24, 1.36, 0.06) * CFrame.Angles(0, 0, -0.5), p.light, GLASS)
			c:cone(Vector3.new(0.20, 0.44, 0.20), CFrame.new(-0.24, 1.36, 0.06) * CFrame.Angles(0, 0, 0.5), p.light, GLASS)
			c:cone(Vector3.new(0.20, 0.44, 0.20), CFrame.new(0, 1.36, -0.22) * CFrame.Angles(-0.5, 0, 0), p.light, GLASS)
			c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(1.16, 0.96, 0.30), p.pale, GLASS)
			c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(-1.20, 0.30, 0.36), p.pale, GLASS)
		end,
	}

	-- A guardian lion carved from granite: a blocky curled mane, a glowing brow gem, a paw on an ore pearl.
	S.pb_t_lion = {
		label = "Granite Lion",
		set = "pebblebound",
		tint = C3(196, 120, 84),
		head = CFrame.new(0, 1.40, 0.30),
		neck = CFrame.new(0, -0.40, 0.92),
		back = CFrame.new(0, 0.50, -0.86),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = Vector3.new(1.80, 1.70, 1.70),
				snout = { w = 0.60, h = 0.40, d = 0.40, y = -0.22, color = p.pale },
				eyeY = 0.20, eyeSize = Vector3.new(0.40, 0.46, 0.20), brow = p.deep,
				legSize = Vector3.new(0.46, 0.36, 0.50), tail = false,
			})
			-- The mane frames the face: a top roll, side rolls and four corner curls.
			c:box(Vector3.new(1.90, 0.40, 0.44), CFrame.new(0, 1.00, 0.56), p.dark, SLATE)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.40, 1.20, 0.44), CFrame.new(1.04 * s, 0.24, 0.56), p.dark, SLATE)
				c:box(Vector3.new(0.44, 0.44, 0.44), CFrame.new(0.92 * s, 0.90, 0.60) * CFrame.Angles(0, 0, math.pi / 4), p.dark, SLATE)
				c:box(Vector3.new(0.40, 0.40, 0.40), CFrame.new(0.96 * s, -0.40, 0.62) * CFrame.Angles(0, 0, math.pi / 4), p.dark, SLATE)
				c:box(Vector3.new(0.30, 0.30, 0.20), CFrame.new(0.56 * s, 1.30, 0.50), p.base)
			end
			c:box(Vector3.new(0.20, 0.20, 0.08), CFrame.new(0, 0.70, 0.88) * CFrame.Angles(0, 0, math.pi / 4), p.glow, NEON)
			c:ball(Vector3.new(0.56, 0.56, 0.56), CFrame.new(0.52, -0.78, 1.06), p.glow, NEON)
			c:box(Vector3.new(0.40, 0.24, 0.46), CFrame.new(0.52, -0.38, 1.04), p.deep)
			c:rod(Vector3.new(0, -0.40, -0.84), Vector3.new(0.46, 0.36, -1.10), 0.08, p.base, nil, false)
			c:box(Vector3.new(0.34, 0.34, 0.34), CFrame.new(0.48, 0.46, -1.10) * CFrame.Angles(0.5, 0.5, 0.5), p.dark, SLATE)
			-- The plinth it guards, trimmed with a glowing seam.
			c:box(Vector3.new(2.10, 0.24, 2.10), CFrame.new(0, -1.20, 0.20), p.deep, SLATE)
			c:box(Vector3.new(2.16, 0.06, 2.16), CFrame.new(0, -1.06, 0.20), p.glow, NEON)
		end,
	}

	-- A floating whale banded with rock strata, spouting a fountain of glowing crystals.
	S.pb_t_whale = {
		label = "Strata Whale",
		set = "pebblebound",
		tint = C3(60, 160, 240),
		scale = 1.15,
		head = CFrame.new(0, 0.96, 0.40),
		neck = CFrame.new(0, -0.50, 1.00),
		back = CFrame.new(0, 0.30, -1.20),
		build = function(c, p)
			local UP = CFrame.Angles(0, 0, math.pi / 2)
			c:box(Vector3.new(1.70, 1.40, 2.20), CFrame.new(0, 0, 0), p.base)
			c:box(Vector3.new(1.50, 0.40, 2.00), CFrame.new(0, -0.64, 0.06), p.pale)
			-- Strata bands along the flanks, stopping short of the face.
			c:box(Vector3.new(1.74, 0.10, 1.60), CFrame.new(0, 0.40, -0.30), p.dark)
			c:box(Vector3.new(1.74, 0.10, 1.60), CFrame.new(0, 0.12, -0.30), p.light)
			c:box(Vector3.new(1.74, 0.10, 1.60), CFrame.new(0, -0.20, -0.30), p.deep)
			c:eyes(0.24, 1.12, 0.40, 0.17)
			c:box(Vector3.new(0.80, 0.08, 0.06), CFrame.new(0, -0.20, 1.12), INK)
			-- The spout: a fountain of glowing crystals and two droplets.
			c:cyl(Vector3.new(0.14, 0.44, 0.44), CFrame.new(0, 0.76, 0.40) * UP, p.deep)
			c:cone(Vector3.new(0.20, 0.64, 0.20), CFrame.new(0, 1.12, 0.40), p.glow, NEON)
			c:cone(Vector3.new(0.16, 0.48, 0.16), CFrame.new(0.22, 1.00, 0.40) * CFrame.Angles(0, 0, -0.5), p.glow, NEON)
			c:cone(Vector3.new(0.16, 0.48, 0.16), CFrame.new(-0.22, 1.00, 0.40) * CFrame.Angles(0, 0, 0.5), p.glow, NEON)
			c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.50, 1.40, 0.40), p.glow, NEON)
			c:ball(Vector3.new(0.14, 0.14, 0.14), CFrame.new(-0.46, 1.50, 0.40), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.24, 0.12, 0.04), CFrame.new(0.62 * s, -0.02, 1.11), BLUSH)
				c:box(Vector3.new(0.60, 0.12, 0.40), CFrame.new(1.10 * s, -0.36, 0.40) * CFrame.Angles(0, 0, -0.4 * s), p.dark)
				c:box(Vector3.new(0.70, 0.12, 0.44), CFrame.new(0.46 * s, 0.30, -1.80) * CFrame.Angles(0, 0, 0.3 * s), p.dark)
				c:box(Vector3.new(0.26, 0.24, 0.26), CFrame.new(1.30 * s, 0.70 - s * 0.20, -0.30 + s * 0.50) * CFrame.Angles(0.5, 0.7, 0.2), p.deep, SLATE)
			end
			c:box(Vector3.new(0.70, 0.56, 0.60), CFrame.new(0, 0.10, -1.36), p.base)
			c:box(Vector3.new(0.50, 0.24, 0.60), CFrame.new(0, 0.82, -0.50), p.dark)
			spots(c, p.pale, { { 0.86, 0.30, 0.70 }, { -0.86, -0.36, 0.64 }, { 0.86, -0.40, -0.10 } }, Vector3.new(0.06, 0.16, 0.16))
		end,
	}

	-- A floating standing stone with a sage's beard: glowing ore veins, orbiting pebbles, a crystal crown.
	S.pb_t_monolith = {
		label = "Monolith Sage",
		set = "pebblebound",
		tint = C3(120, 110, 170),
		head = CFrame.new(0, 1.56, 0),
		neck = CFrame.new(0, -0.40, 0.56),
		back = CFrame.new(0, 0.20, -0.46),
		build = function(c, p)
			local UP = CFrame.Angles(0, 0, math.pi / 2)
			c:box(Vector3.new(1.30, 2.00, 0.80), CFrame.new(0, 0.10, 0), p.base, SLATE)
			c:box(Vector3.new(1.40, 0.18, 0.90), CFrame.new(0, 1.16, 0), p.dark, SLATE)
			c:eyes(0.52, 0.44, 0.28, 0.16)
			c:cone(Vector3.new(0.70, 0.66, 0.20), CFrame.new(0, -0.14, 0.48) * CFrame.Angles(math.pi, 0, 0), p.pale)
			c:box(Vector3.new(0.62, 0.14, 0.12), CFrame.new(0, 0.22, 0.52), p.pale)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.40, 0.12, 0.12), CFrame.new(0.28 * s, 0.80, 0.44) * CFrame.Angles(0, 0, -0.2 * s), p.pale)
				c:box(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0.86 * s, -0.10, 0.20) * CFrame.Angles(0.4, 0.4, 0.4), p.dark, SLATE)
			end
			-- Ore veins glowing through the stone.
			c:box(Vector3.new(0.06, 0.70, 0.04), CFrame.new(0.44, -0.46, 0.41) * CFrame.Angles(0, 0, 0.3), p.glow, NEON)
			c:box(Vector3.new(0.06, 0.50, 0.04), CFrame.new(-0.46, -0.56, 0.41) * CFrame.Angles(0, 0, -0.4), p.glow, NEON)
			c:box(Vector3.new(0.04, 0.80, 0.06), CFrame.new(0.66, 0.30, 0.10) * CFrame.Angles(0.3, 0, 0), p.glow, NEON)
			-- A crown of crystals hovering over its head.
			for i = 0, 4 do
				local a = i * math.pi * 2 / 5
				c:cone(Vector3.new(0.14, 0.34, 0.14), CFrame.new(math.sin(a) * 0.40, 1.50, math.cos(a) * 0.30), p.glow, NEON)
			end
			-- A ring of pebbles orbiting its middle.
			for i = 0, 5 do
				local a = i * math.pi / 3
				c:box(Vector3.new(0.22, 0.22, 0.22), CFrame.new(math.cos(a) * 1.06, -0.36 + math.sin(a) * 0.14, math.sin(a) * 0.80) * CFrame.Angles(a, a, 0), p.dark, SLATE)
			end
			c:cone(Vector3.new(0.90, 0.50, 0.50), CFrame.new(0, -1.20, 0) * CFrame.Angles(math.pi, 0, 0), p.deep, SLATE)
			c:cyl(Vector3.new(0.06, 1.20, 1.20), CFrame.new(0, -1.52, 0) * UP, p.glow, NEON)
		end,
	}

	----------------------------------------------------------------------------
	-- DIVINE: heavenly and floating, with a halo of glow.
	----------------------------------------------------------------------------

	-- A selenite pegasus pony standing on clouds: feathered wings, a flowing mane, a glowing halo.
	S.pb_t_pegasus = {
		label = "Selenite Pegasus",
		set = "pebblebound",
		tint = C3(244, 240, 255),
		scale = 1.2,
		head = CFrame.new(0, 1.24, 0.40),
		neck = CFrame.new(0, -0.30, 0.96),
		back = CFrame.new(0, 0.90, -0.40),
		build = function(c, p)
			local UP = CFrame.Angles(0, 0, math.pi / 2)
			block(c, p, {
				bodySize = Vector3.new(1.76, 1.56, 1.84),
				snout = { w = 0.62, h = 0.46, d = 0.46, y = -0.24, color = p.pale, nose = p.deep },
				eyeY = 0.20, eyeSpread = 0.42, eyeSize = Vector3.new(0.42, 0.52, 0.20),
				legSize = Vector3.new(0.36, 0.44, 0.40), legColor = p.light, legY = -0.80, tail = false,
			})
			c:box(Vector3.new(0.30, 0.40, 0.44), CFrame.new(0, 0.96, 0.54), p.glow)
			c:box(Vector3.new(0.30, 0.44, 0.44), CFrame.new(0, 0.94, 0.14), p.glow)
			c:box(Vector3.new(0.30, 0.40, 0.44), CFrame.new(0, 0.90, -0.26), p.glow)
			for _, s in ipairs(SIDES) do
				c:cone(Vector3.new(0.20, 0.36, 0.16), CFrame.new(0.42 * s, 1.02, 0.50) * CFrame.Angles(0, 0, -0.2 * s), p.base)
				-- A feathered wing: three layers sweeping up and out, the top edge glowing.
				c:box(Vector3.new(0.14, 0.80, 0.70), CFrame.new(0.98 * s, 0.70, -0.20) * CFrame.Angles(0, 0, -0.5 * s), p.pale)
				c:box(Vector3.new(0.12, 0.70, 0.56), CFrame.new(1.32 * s, 1.14, -0.30) * CFrame.Angles(0, 0, -0.8 * s), p.pale)
				c:box(Vector3.new(0.10, 0.52, 0.44), CFrame.new(1.04 * s, 0.30, -0.36) * CFrame.Angles(0, 0, -0.9 * s), p.light)
				c:box(Vector3.new(0.06, 0.64, 0.10), CFrame.new(1.40 * s, 1.20, -0.06) * CFrame.Angles(0, 0, -0.8 * s), p.glow, NEON)
			end
			c:box(Vector3.new(0.30, 0.40, 0.40), CFrame.new(0, 0.30, -1.08), p.glow)
			c:box(Vector3.new(0.28, 0.40, 0.36), CFrame.new(0, -0.06, -1.30) * CFrame.Angles(0.4, 0, 0), p.glow)
			c:box(Vector3.new(0.24, 0.36, 0.30), CFrame.new(0, -0.40, -1.36) * CFrame.Angles(0.8, 0, 0), p.light)
			-- The halo: a glowing disc with a plain centre, so it reads as a ring.
			c:cyl(Vector3.new(0.06, 0.84, 0.84), CFrame.new(0, 1.62, 0.30) * UP, p.glow, NEON)
			c:cyl(Vector3.new(0.08, 0.56, 0.56), CFrame.new(0, 1.62, 0.30) * UP, p.base)
			c:round(Vector3.new(1.00, 0.40, 0.80), CFrame.new(-0.46, -1.10, 0.40), WHITE)
			c:round(Vector3.new(1.00, 0.40, 0.80), CFrame.new(0.50, -1.12, -0.30), WHITE)
			c:round(Vector3.new(0.70, 0.34, 0.60), CFrame.new(0.40, -1.06, 0.60), WHITE)
		end,
	}

	-- A moonstone sphinx cat: a striped headdress, a jewelled collar and a crescent moon floating overhead.
	S.pb_t_sphinx = {
		label = "Moonstone Sphinx",
		set = "pebblebound",
		tint = C3(150, 196, 255),
		head = CFrame.new(0, 1.34, 0),
		neck = CFrame.new(0, -0.36, 0.90),
		back = CFrame.new(0, 0.30, -0.80),
		build = function(c, p)
			local UP = CFrame.Angles(0, 0, math.pi / 2)
			block(c, p, {
				bodySize = Vector3.new(1.60, 1.80, 1.50),
				snout = { w = 0.44, h = 0.28, d = 0.30, y = -0.08, color = p.pale },
				eyeY = 0.30, eyeSpread = 0.36, eyeSize = Vector3.new(0.36, 0.46, 0.20),
				bib = { w = 0.80, h = 0.40, y = -0.62, color = p.pale },
				legs = false, tail = false,
			})
			-- The striped headdress: a cap and two flaps down beside the face.
			c:box(Vector3.new(1.72, 0.24, 1.40), CFrame.new(0, 1.04, -0.02), p.light)
			c:box(Vector3.new(1.74, 0.08, 1.42), CFrame.new(0, 0.94, -0.02), p.deep)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.20, 1.00, 0.60), CFrame.new(0.88 * s, 0.40, 0.34), p.light)
				c:box(Vector3.new(0.22, 0.08, 0.62), CFrame.new(0.88 * s, 0.60, 0.34), p.deep)
				c:box(Vector3.new(0.22, 0.08, 0.62), CFrame.new(0.88 * s, 0.28, 0.34), p.deep)
				c:cone(Vector3.new(0.26, 0.40, 0.20), CFrame.new(0.50 * s, 1.34, 0.02) * CFrame.Angles(0, 0, -0.2 * s), p.base)
				c:box(Vector3.new(0.40, 0.30, 0.66), CFrame.new(0.36 * s, -0.70, 0.96), p.base)
				c:box(Vector3.new(0.40, 0.70, 0.90), CFrame.new(0.92 * s, -0.48, -0.20), p.base)
			end
			c:box(Vector3.new(0.18, 0.18, 0.06), CFrame.new(0, 0.74, 0.77) * CFrame.Angles(0, 0, math.pi / 4), p.glow, NEON)
			c:box(Vector3.new(1.66, 0.14, 1.56), CFrame.new(0, -0.32, 0), GOLD, METAL)
			c:box(Vector3.new(0.20, 0.20, 0.08), CFrame.new(0, -0.50, 0.90) * CFrame.Angles(0, 0, math.pi / 4), p.glow, NEON)
			-- The tail wraps round its side.
			c:rod(Vector3.new(-0.30, -0.78, -0.80), Vector3.new(-1.16, -0.78, -0.50), 0.10, p.base, nil, false)
			c:rod(Vector3.new(-1.16, -0.78, -0.50), Vector3.new(-1.20, -0.70, 0.30), 0.10, p.base, nil, false)
			c:ball(Vector3.new(0.26, 0.26, 0.26), CFrame.new(-1.20, -0.70, 0.36), p.dark)
			-- A crescent moon and a star floating overhead, and a glowing disc beneath.
			for i = -1, 1 do
				local a = math.pi + i * 0.7
				c:box(Vector3.new(0.14, 0.32, 0.12), CFrame.new(math.cos(a) * 0.30, 1.86 + math.sin(a) * 0.30, 0) * CFrame.Angles(0, 0, a), p.glow, NEON)
			end
			c:star(Vector3.new(0.34, 1.96, 0), 0.26, p.glow)
			c:cyl(Vector3.new(0.06, 1.90, 1.90), CFrame.new(0, -0.90, 0.10) * UP, p.glow, NEON)
		end,
	}

	----------------------------------------------------------------------------
	-- EXOTIC: the set's showpieces, from the heart of the earth.
	----------------------------------------------------------------------------

	-- A gem kraken: a round mantle with a crystal crown, six curling tentacles with glowing tips.
	S.pb_t_kraken = {
		label = "Gemstone Kraken",
		set = "pebblebound",
		tint = C3(20, 200, 176),
		scale = 1.2,
		head = CFrame.new(0, 1.70, 0),
		neck = CFrame.new(0, -0.30, 0.90),
		back = CFrame.new(0, 0.40, -0.90),
		build = function(c, p)
			local UP = CFrame.Angles(0, 0, math.pi / 2)
			c:round(Vector3.new(1.80, 1.70, 1.70), CFrame.new(0, 0.30, 0), p.base)
			c:eyes(0.30, 0.86, 0.38, 0.19)
			c:box(Vector3.new(0.30, 0.10, 0.06), CFrame.new(0, 0.02, 0.86), INK)
			c:cyl(Vector3.new(0.18, 0.90, 0.90), CFrame.new(0, 1.20, 0) * UP, GOLD, METAL)
			for i = 0, 3 do
				local a = i * math.pi / 2 + math.pi / 4
				c:cone(Vector3.new(0.18, 0.46, 0.18), CFrame.new(math.sin(a) * 0.36, 1.50, math.cos(a) * 0.36), p.glow, NEON)
			end
			c:cone(Vector3.new(0.24, 0.62, 0.24), CFrame.new(0, 1.58, 0), p.glow, NEON)
			for i = 0, 5 do
				local a = i * math.pi / 3 + math.pi / 6
				local dx, dz = math.sin(a), math.cos(a)
				local mid = Vector3.new(dx * 1.12, -0.86, dz * 1.12)
				local tip = Vector3.new(dx * 1.44, -0.56, dz * 1.44)
				c:rod(Vector3.new(dx * 0.62, -0.40, dz * 0.62), mid, 0.15, p.base, nil, false)
				c:rod(mid, tip, 0.11, p.light, nil, false)
				c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(tip), p.glow, NEON)
			end
			c:ball(Vector3.new(0.26, 0.26, 0.26), CFrame.new(1.10, 1.10, 0.30), p.pale, GLASS)
			c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(-1.16, 1.36, 0.10), p.pale, GLASS)
		end,
	}

	-- A little planet that is a geode: cracked open on top to a crystal heart, a ring of rubble, a pet moon.
	S.pb_t_planetoid = {
		label = "Geode Planetoid",
		set = "pebblebound",
		tint = C3(150, 80, 230),
		scale = 1.2,
		head = CFrame.new(0, 1.60, 0),
		neck = CFrame.new(0, -0.50, 0.80),
		back = CFrame.new(0, 0.10, -0.90),
		build = function(c, p)
			local UP = CFrame.Angles(0, 0, math.pi / 2)
			c:ball(Vector3.new(1.80, 1.80, 1.80), CFrame.new(0, 0, 0), p.base)
			c:eyes(0.06, 0.84, 0.34, 0.18)
			c:box(Vector3.new(0.24, 0.10, 0.06), CFrame.new(0, -0.28, 0.88), INK)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.22, 0.12, 0.04), CFrame.new(0.56 * s, -0.16, 0.70) * CFrame.Angles(0, 0.68 * s, 0), BLUSH)
			end
			-- The crack on top, opening onto the crystal heart.
			c:cyl(Vector3.new(0.10, 1.10, 1.10), CFrame.new(0, 0.80, 0) * UP, p.deep)
			c:cone(Vector3.new(0.32, 0.74, 0.32), CFrame.new(0, 1.18, 0), p.glow, NEON)
			for i = 0, 3 do
				local a = i * math.pi / 2 + math.pi / 4
				local dx, dz = math.sin(a), math.cos(a)
				c:cone(Vector3.new(0.20, 0.48, 0.20), CFrame.new(dx * 0.26, 1.04, dz * 0.26) * CFrame.Angles(dz * 0.45, 0, -dx * 0.45), p.light, GLASS)
				c:box(Vector3.new(0.24, 0.20, 0.24), CFrame.new(dx * 0.52, 0.84, dz * 0.52) * CFrame.Angles(0.4, a, 0.3), p.dark)
			end
			-- A tilted ring of rubble, dipping low in front so the face stays clear.
			for i = 0, 9 do
				local a = i * math.pi / 5
				c:box(Vector3.new(0.26, 0.08, 0.84), CFrame.new(0, -0.10, 0) * CFrame.Angles(0.35, 0, 0) * CFrame.Angles(0, a, 0) * CFrame.new(1.34, 0, 0), i % 2 == 0 and p.light or p.dark)
			end
			c:ball(Vector3.new(0.46, 0.46, 0.46), CFrame.new(1.36, 0.92, -0.30), p.pale)
			c:box(Vector3.new(0.12, 0.12, 0.04), CFrame.new(1.30, 0.98, -0.08), p.dark)
			c:star(Vector3.new(-1.24, 1.04, 0.30), 0.32, p.glow)
		end,
	}

	-- A three-headed prism hydra: three cheerful heads on short necks, each crowned with crystal.
	S.pb_t_hydra = {
		label = "Prism Hydra",
		set = "pebblebound",
		tint = C3(240, 70, 140),
		head = CFrame.new(0, 1.56, 0.30),
		neck = CFrame.new(0, -0.50, 0.86),
		back = CFrame.new(0, 0.30, -0.96),
		build = function(c, p)
			c:box(Vector3.new(1.70, 1.10, 1.70), CFrame.new(0, -0.40, -0.10), p.base)
			c:box(Vector3.new(1.20, 0.70, 0.10), CFrame.new(0, -0.46, 0.78), p.pale)
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.36, -0.56 }) do
					c:box(Vector3.new(0.42, 0.34, 0.48), CFrame.new(0.60 * s, -1.04, z), p.deep)
				end
			end
			c:box(Vector3.new(0.50, 0.40, 0.70), CFrame.new(0, -0.62, -1.24), p.base)
			c:cone(Vector3.new(0.30, 0.50, 0.30), CFrame.new(0, -0.62, -1.82) * CFrame.Angles(-math.pi / 2, 0, 0), p.glow, NEON)
			c:cone(Vector3.new(0.24, 0.40, 0.24), CFrame.new(0, 0.30, -0.50) * CFrame.Angles(-0.4, 0, 0), p.light, GLASS)
			-- Three heads, the middle one biggest: a neck, a head, two eyes and a crystal crest each.
			for _, h in ipairs({ { 0, 1.00, 0.30, 0.80, 0.22 }, { -0.90, 0.58, 0.40, 0.66, 0.17 }, { 0.90, 0.58, 0.40, 0.66, 0.17 } }) do
				local x, y, z, w = h[1], h[2], h[3], h[4]
				local ez, sp, r = z + w * 0.45 + 0.04, w * 0.24, w * 0.14
				c:rod(Vector3.new(x * 0.40, -0.10, 0.10), Vector3.new(x, y - w * 0.40, z), h[5], p.base, nil, false)
				c:box(Vector3.new(w, w * 0.88, w * 0.90), CFrame.new(x, y, z), p.base)
				c:eye(Vector3.new(x - sp, y + 0.04, ez), r)
				c:eye(Vector3.new(x + sp, y + 0.04, ez), r)
				c:cone(Vector3.new(w * 0.28, w * 0.62, w * 0.28), CFrame.new(x, y + w * 0.44 + w * 0.26, z - 0.04), p.glow, NEON)
			end
			c:box(Vector3.new(0.28, 0.06, 0.04), CFrame.new(0, 0.84, 0.67), INK)
		end,
	}

	-- A cheeky meteorite with a glowing comet tail, little rocks and sparkles tumbling round it.
	S.pb_t_meteor = {
		label = "Starfall Meteor",
		set = "pebblebound",
		tint = C3(255, 150, 40),
		scale = 1.2,
		head = CFrame.new(0, 1.10, 0.20),
		neck = CFrame.new(0, -0.50, 0.96),
		back = CFrame.new(0, 0.40, -0.84),
		build = function(c, p)
			c:box(Vector3.new(1.70, 1.60, 1.60), CFrame.new(0, 0, 0.10), p.base, SLATE)
			c:box(Vector3.new(0.80, 0.80, 0.80), CFrame.new(0.66, 0.56, -0.30) * CFrame.Angles(0.5, 0.6, 0.4), p.dark, SLATE)
			c:box(Vector3.new(0.70, 0.70, 0.70), CFrame.new(-0.72, -0.40, -0.24) * CFrame.Angles(0.3, 0.8, 0.5), p.dark, SLATE)
			c:box(Vector3.new(0.60, 0.60, 0.60), CFrame.new(-0.50, 0.70, 0.04) * CFrame.Angles(0.7, 0.2, 0.6), p.base, SLATE)
			c:box(Vector3.new(0.56, 0.56, 0.56), CFrame.new(0.58, -0.66, 0.24) * CFrame.Angles(0.2, 0.9, 0.3), p.base, SLATE)
			c:cyl(Vector3.new(0.06, 0.36, 0.36), CFrame.new(0.86, 0.10, 0.40), p.deep)
			c:cyl(Vector3.new(0.06, 0.30, 0.30), CFrame.new(-0.86, 0.30, 0.50), p.deep)
			c:cyl(Vector3.new(0.06, 0.28, 0.28), CFrame.new(0.40, 0.81, 0.50) * CFrame.Angles(0, 0, math.pi / 2), p.deep)
			c:eyes(0.18, 0.92, 0.34, 0.18)
			c:box(Vector3.new(0.30, 0.22, 0.06), CFrame.new(0, -0.30, 0.92), INK)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.24, 0.12, 0.04), CFrame.new(0.60 * s, -0.12, 0.91), BLUSH)
			end
			c:box(Vector3.new(0.30, 0.30, 0.30), CFrame.new(-0.10, 0.88, 0.46) * CFrame.Angles(0.6, 0.7, 0.5), p.glow, NEON)
			-- The comet tail streams up and back: one big flame, two side flames, two wisps.
			local trail = CFrame.Angles(-math.pi / 2 + 0.3, 0, 0)
			c:cone(Vector3.new(1.10, 1.40, 1.10), CFrame.new(0, 0.40, -1.20) * trail, p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:cone(Vector3.new(0.56, 1.00, 0.56), CFrame.new(0.56 * s, 0.10, -1.00) * CFrame.Angles(0, -0.3 * s, 0) * trail, p.light, NEON)
				c:cone(Vector3.new(0.30, 0.50, 0.30), CFrame.new(0.30 * s, 1.00, -1.86) * trail, p.glow, NEON)
			end
			c:box(Vector3.new(0.24, 0.24, 0.24), CFrame.new(1.20, 0.90, 0.40) * CFrame.Angles(0.5, 0.5, 0.2), p.dark, SLATE)
			c:box(Vector3.new(0.20, 0.20, 0.20), CFrame.new(-1.20, 0.40, 0.60) * CFrame.Angles(0.2, 0.7, 0.4), p.dark, SLATE)
			c:box(Vector3.new(0.18, 0.18, 0.18), CFrame.new(1.14, -0.80, 0.30) * CFrame.Angles(0.6, 0.1, 0.5), p.dark, SLATE)
			c:star(Vector3.new(-1.10, 1.10, 0.30), 0.30, p.glow)
			c:star(Vector3.new(1.10, -0.20, 0.80), 0.24, p.glow)
		end,
	}

	return S
end
