--[[ PetBodies/MythicMenagerieTop -- Mythic Menagerie's top bodies: one body
	per Epic-and-up pet, each worn by that pet alone. The creature-collecting
	flagship: legendary species, nests, eggs and habitats. The creatures are
	the stars. Base bodies (Griffin, Phoenix Chick, Kirin, Hydra Pup, Sphinx
	Kitten, Trihorn) and extras (drake, horse, bigcat) are NOT remade here.

	Epic = charming critters. Legendary = bigger beasts. Mythic = habitats,
	nests and eggs (twelve of them). Divine = apex legends. Exotic = primordial
	titans. Kid-friendly, cute, no gore. See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block, ears, wings = K.C3, K.block, K.ears, K.wings
	local INK, WHITE, METAL, NEON, GLASS, SLATE, WOOD = K.INK, K.WHITE, K.METAL, K.NEON, K.GLASS, K.SLATE, K.WOOD
	local S = {}
	local SET = "mythic_menagerie"
	local SIDES = { -1, 1 }
	local V3, CF, ANG = Vector3.new, CFrame.new, CFrame.Angles
	local PI = math.pi
	local UP = ANG(0, 0, PI / 2)
	local FRONT = ANG(0, PI / 2, 0)

	local GOLD = C3(246, 196, 64)
	local BONE = C3(244, 240, 230)
	local LEAF = C3(86, 170, 70)
	local TWIG = C3(130, 90, 56)
	local CLOUD = C3(240, 244, 252)
	local AMBER = C3(255, 186, 70)
	local BLUSH = C3(255, 150, 172)
	local PEARL = C3(248, 242, 234)
	local MOSS = C3(90, 140, 70)
	local SHELL = C3(236, 210, 170)

	local function face(c, y, z, spread, r)
		c:eyes(y, z + r * 0.3, spread, r)
		c:box(V3(r * 1.5, r * 0.45, 0.06), CF(0, y - r * 2.0, z + 0.02), INK)
	end

	local function blush(c, x, y, z)
		for _, s in ipairs(SIDES) do
			c:box(V3(0.20, 0.10, 0.05), CF(x * s, y, z), BLUSH)
		end
	end


	--------------------------------------------------------------------------
	-- EPIC: charming critters.
	--------------------------------------------------------------------------

	-- A soft rabbit with tiny antlers and a fluffy cottontail.
	S.mm_t_leveret = {
		label = "Thornjack Leveret",
		set = SET,
		tint = C3(236, 196, 150),
		scale = 1.05,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.70, 1.50, 1.60),
				eyeY = 0.18, eyeSpread = 0.36, eyeSize = V3(0.46, 0.54, 0.20),
				snout = { w = 0.50, h = 0.28, d = 0.30, y = -0.20, color = p.pale, nose = p.deep },
				legSize = V3(0.34, 0.30, 0.36), legColor = p.dark, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V3(0.22, 0.70, 0.16), CF(0.34 * s, 1.00, 0.10) * ANG(0, 0, -0.15 * s), p.light)
				c:cone(V3(0.14, 0.40, 0.14), CF(0.22 * s, 1.20, 0.30) * ANG(-0.35, 0, -0.2 * s), BONE)
			end
			c:ball(V3(0.40, 0.40, 0.40), CF(0, -0.10, -0.95), p.pale)
			c:box(V3(0.20, 0.10, 0.16), CF(0, -0.30, 0.86), BLUSH)
		end,
	}

	-- A round porcupine pup bristling with soft tipped quills.
	S.mm_t_porcupette = {
		label = "Quilltip Porcupette",
		set = SET,
		tint = C3(150, 110, 80),
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.80, 1.60, 1.70),
				eyeY = 0.14, eyeSpread = 0.38,
				snout = { w = 0.46, h = 0.30, d = 0.28, y = -0.22, color = p.pale, nose = p.deep },
				legSize = V3(0.36, 0.28, 0.36), legColor = p.dark, tail = false,
			})
			for _, v in ipairs({
				{0, 1.10, 0.20}, {0.40, 1.00, -0.10}, {-0.40, 1.00, -0.10},
				{0.30, 0.95, 0.40}, {-0.30, 0.95, 0.40}, {0.50, 0.80, -0.40},
				{-0.50, 0.80, -0.40}, {0, 1.05, -0.40}, {0.20, 0.90, -0.70}, {-0.20, 0.90, -0.70},
			}) do
				c:cone(V3(0.14, 0.42, 0.14), CF(v[1], v[2], v[3]) * ANG(-0.4 + v[3] * 0.2, 0, v[1] * 0.3), p.light)
			end
			c:box(V3(0.30, 0.20, 0.50), CF(0, -0.20, -1.00), p.dark)
		end,
	}

	-- A chubby firefly carrying a glowing lantern belly.
	S.mm_t_firefly = {
		label = "Jarglow Firefly",
		set = SET,
		tint = C3(255, 230, 80),
		scale = 1.08,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.40, 1.40, 1.40),
				eyeY = 0.20, eyeSpread = 0.30, eyeSize = V3(0.44, 0.52, 0.18),
				mouthY = -0.24, legs = false, tail = false,
			})
			c:ball(V3(1.10, 1.10, 1.10), CF(0, -0.55, -0.20), p.glow, NEON)
			c:box(V3(0.90, 0.12, 0.90), CF(0, -0.10, -0.20), p.dark)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.90, 0.06, 0.50), CF(0.70 * s, 0.55, -0.10) * ANG(0, -0.2 * s, 0.25 * s), p.pale).Transparency = 0.3
				c:rod(V3(0.20 * s, 0.70, 0.30), V3(0.40 * s, 1.15, 0.45), 0.035, p.dark, nil, false)
				c:ball(V3(0.16, 0.16, 0.16), CF(0.40 * s, 1.18, 0.46), p.glow, NEON)
			end
			c:light(p.glow, 1.6, 8)
		end,
	}

	-- A goat-fish cub: woolly front half, scaly fish tail, cloud hooves.
	S.mm_t_capricub = {
		label = "Cloudfin Capricub",
		set = SET,
		tint = C3(180, 200, 220),
		scale = 1.1,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.60, 1.50, 1.60),
				eyeY = 0.22, eyeSpread = 0.34,
				snout = { w = 0.44, h = 0.34, d = 0.36, y = -0.12, color = p.pale, nose = p.deep },
				legSize = V3(0.30, 0.36, 0.30), legZ = { 0.40 }, legColor = CLOUD, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.12, 0.36, 0.12), CF(0.28 * s, 1.05, 0.20) * ANG(-0.2, 0, -0.25 * s), BONE)
				c:box(V3(0.16, 0.40, 0.50), CF(0.70 * s, 0.10, -0.20), p.light)
			end
			c:box(V3(0.90, 0.70, 0.80), CF(0, -0.20, -1.00), p.base)
			c:box(V3(0.70, 0.50, 0.60), CF(0, 0.05, -1.50) * ANG(0.3, 0, 0), p.dark)
			c:box(V3(0.80, 0.14, 0.50), CF(0, 0.20, -1.90), p.light)
			c:ball(V3(0.36, 0.28, 0.36), CF(0, -0.85, 0.45), CLOUD)
			c:ball(V3(0.36, 0.28, 0.36), CF(0, -0.85, -0.10), CLOUD)
		end,
	}

	-- A little softshell turtle with a leaf-shaped shell and stubby flippers.
	S.mm_t_tortling = {
		label = "Softshell Tortling",
		set = SET,
		tint = C3(120, 170, 100),
		scale = 1.05,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(1.70, 0.80, 1.70), CF(0, -0.20, 0), p.base)
			c:box(V3(1.90, 0.40, 1.90), CF(0, 0.30, 0), p.dark)
			c:box(V3(1.40, 0.30, 1.40), CF(0, 0.55, 0), LEAF)
			c:box(V3(0.90, 0.70, 0.80), CF(0, -0.10, 0.95), p.light)
			face(c, 0.05, 1.30, 0.26, 0.13)
			blush(c, 0.36, -0.20, 1.32)
			c:box(V3(0.30, 0.16, 0.40), CF(0, -0.30, 1.45), p.deep)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.70, 0.16, 0.40), CF(0.95 * s, -0.55, 0.30), p.pale)
				c:box(V3(0.70, 0.16, 0.40), CF(0.95 * s, -0.55, -0.50), p.pale)
			end
			c:box(V3(0.40, 0.20, 0.50), CF(0, -0.40, -1.00), p.dark)
		end,
	}

	-- A desert fennec with enormous ears and sand-soft paws.
	S.mm_t_fennecling = {
		label = "Sandear Fennecling",
		set = SET,
		tint = C3(240, 210, 150),
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.50, 1.40, 1.50),
				eyeY = 0.16, eyeSpread = 0.34,
				snout = { w = 0.40, h = 0.28, d = 0.40, y = -0.18, color = p.pale, nose = p.deep },
				legSize = V3(0.32, 0.28, 0.34), legColor = p.dark, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V3(0.50, 0.90, 0.14), CF(0.45 * s, 1.10, 0.05) * ANG(0, 0, -0.2 * s), p.light)
				c:box(V3(0.34, 0.60, 0.08), CF(0.45 * s, 1.15, 0.10) * ANG(0, 0, -0.2 * s), p.pale)
			end
			c:box(V3(0.30, 0.30, 0.70), CF(0, 0.10, -0.95) * ANG(0.3, 0, 0), p.base)
			c:box(V3(0.40, 0.40, 0.40), CF(0, 0.30, -1.30), p.pale)
		end,
	}

	-- A long white ermine with a black-tipped brushy tail.
	S.mm_t_ermine = {
		label = "Snowpuff Ermine",
		set = SET,
		tint = C3(246, 246, 250),
		scale = 1.12,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.40, 1.20, 1.90),
				eyeY = 0.18, eyeSpread = 0.32,
				snout = { w = 0.40, h = 0.28, d = 0.34, y = -0.14, color = p.pale, nose = INK },
				legSize = V3(0.28, 0.26, 0.30), legX = 0.70, legZ = { 0.55, -0.55 }, legColor = p.dark,
				tail = false,
			})
			c:box(V3(0.50, 0.40, 0.70), CF(0, 0.05, -1.20), p.base)
			c:box(V3(0.40, 0.36, 0.55), CF(0, 0.15, -1.70), p.pale)
			c:box(V3(0.34, 0.34, 0.34), CF(0, 0.20, -2.05), INK)
			ears(c, p.light, "up", p.pale)
		end,
	}

	-- A round smiling quokka with stubby ears and chunky paws.
	S.mm_t_quokka = {
		label = "Smileface Quokka",
		set = SET,
		tint = C3(180, 140, 90),
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.80, 1.70, 1.70),
				eyeY = 0.22, eyeSpread = 0.40, eyeSize = V3(0.48, 0.52, 0.20),
				mouthY = -0.30, mouthSize = V3(0.70, 0.14, 0.10),
				legSize = V3(0.40, 0.30, 0.40), legColor = p.dark, tail = false,
			})
			ears(c, p.light, "up", p.pale)
			c:box(V3(0.80, 0.50, 0.20), CF(0, -0.40, 0.90), p.pale)
			c:box(V3(0.36, 0.30, 0.50), CF(0, -0.20, -0.95), p.dark)
		end,
	}

	-- A sleek otterling floating on its back with a pebble on its belly.
	S.mm_t_otterling = {
		label = "Riverbend Otterling",
		set = SET,
		tint = C3(90, 140, 170),
		scale = 1.15,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.50, 1.20, 2.00),
				eyeY = 0.16, eyeSpread = 0.34,
				snout = { w = 0.44, h = 0.30, d = 0.36, y = -0.14, color = p.pale, nose = p.deep },
				bib = { w = 0.70, h = 0.50, y = -0.30, color = p.pale },
				legSize = V3(0.34, 0.22, 0.40), legX = 0.80, legZ = { 0.50, -0.50 }, legColor = p.dark,
				tail = false,
			})
			c:box(V3(0.60, 0.40, 0.80), CF(0, -0.10, -1.20), p.base)
			c:box(V3(0.50, 0.30, 0.60), CF(0, 0.0, -1.70), p.dark)
			c:box(V3(0.40, 0.20, 0.40), CF(0, 0.05, -2.05), p.base)
			c:ball(V3(0.34, 0.34, 0.34), CF(0, 0.40, 0.10), SHELL)
		end,
	}

	-- A fuzzy striped bumblebee with translucent wings and tiny pollen sacs.
	S.mm_t_bumblebee = {
		label = "Honeycomb Bumblebee",
		set = SET,
		tint = C3(255, 200, 40),
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.60, 1.40, 1.60),
				eyeY = 0.18, eyeSpread = 0.34, eyeSize = V3(0.46, 0.52, 0.18),
				mouthY = -0.26, legs = false, tail = false,
			})
			c:box(V3(1.64, 0.30, 1.64), CF(0, 0.10, 0), INK)
			c:box(V3(1.64, 0.30, 1.64), CF(0, -0.40, 0), INK)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.90, 0.06, 0.60), CF(0.85 * s, 0.70, 0) * ANG(0, 0, 0.3 * s), p.pale).Transparency = 0.3
				c:rod(V3(0.20 * s, 0.70, 0.40), V3(0.35 * s, 1.20, 0.50), 0.03, INK, nil, false)
				c:ball(V3(0.14, 0.14, 0.14), CF(0.35 * s, 1.22, 0.52), p.glow, NEON)
				c:ball(V3(0.28, 0.28, 0.28), CF(0.70 * s, -0.55, 0.20), AMBER)
			end
			c:cone(V3(0.20, 0.30, 0.20), CF(0, -0.10, 0.95) * ANG(PI / 2, 0, 0), INK)
		end,
	}

	-- An armadillo half-rolled into its banded shell, peeking out cute.
	S.mm_t_armadillo = {
		label = "Shellroll Armadillo",
		set = SET,
		tint = C3(160, 130, 90),
		scale = 1.05,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:ball(V3(1.80, 1.60, 1.80), CF(0, 0.0, 0), p.base)
			for i, z in ipairs({ 0.40, 0.05, -0.30, -0.65 }) do
				c:box(V3(1.70 - i * 0.05, 0.18, 0.30), CF(0, 0.55 - i * 0.08, z), p.dark)
			end
			c:box(V3(0.90, 0.70, 0.70), CF(0, -0.20, 0.95), p.light)
			face(c, -0.05, 1.25, 0.26, 0.13)
			blush(c, 0.34, -0.28, 1.26)
			c:box(V3(0.36, 0.20, 0.30), CF(0, -0.40, 1.35), p.deep)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.30, 0.20, 0.36), CF(0.70 * s, -0.80, 0.50), p.dark)
				c:box(V3(0.30, 0.20, 0.36), CF(0.55 * s, -0.80, -0.40), p.dark)
			end
			c:box(V3(0.30, 0.24, 0.50), CF(0, -0.30, -1.00), p.deep)
		end,
	}

	-- A fluffy alpaca with a cloud-like neck ruff and a tiny bow.
	S.mm_t_alpaca = {
		label = "Fluffcloud Alpaca",
		set = SET,
		tint = C3(230, 210, 190),
		scale = 1.08,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.50, 1.60, 1.60),
				eyeY = 0.28, eyeSpread = 0.32,
				snout = { w = 0.40, h = 0.34, d = 0.36, y = 0.0, color = p.pale, nose = p.deep },
				legSize = V3(0.28, 0.40, 0.28), legColor = p.dark, tail = false,
			})
			c:box(V3(1.20, 0.90, 1.00), CF(0, 0.70, 0.20), p.pale)
			c:box(V3(1.40, 0.50, 1.40), CF(0, 0.40, -0.10), p.light)
			ears(c, p.light, "up", p.pale)
			c:box(V3(0.30, 0.16, 0.10), CF(0, 0.55, 0.70), BLUSH)
			c:box(V3(0.24, 0.24, 0.24), CF(0, -0.10, -0.95), p.dark)
		end,
	}

	-- A soft moth with moon-spot wings and glowing antennae tips.
	S.mm_t_glowmoth = {
		label = "Moonspot Glowmoth",
		set = SET,
		tint = C3(200, 180, 255),
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.40, 1.30, 1.40),
				eyeY = 0.16, eyeSpread = 0.30, eyeSize = V3(0.42, 0.50, 0.18),
				mouthY = -0.24, legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V3(1.10, 0.90, 0.08), CF(0.85 * s, 0.55, -0.20) * ANG(0, 0, -0.35 * s), p.light)
				c:box(V3(0.80, 0.60, 0.08), CF(0.75 * s, -0.05, -0.30) * ANG(0, 0, 0.25 * s), p.pale)
				c:ball(V3(0.28, 0.28, 0.28), CF(0.90 * s, 0.70, -0.20), p.glow, NEON)
				c:rod(V3(0.18 * s, 0.70, 0.40), V3(0.40 * s, 1.25, 0.55), 0.03, p.dark, nil, false)
				c:ball(V3(0.16, 0.16, 0.16), CF(0.40 * s, 1.28, 0.56), p.glow, NEON)
			end
			c:box(V3(0.40, 0.30, 0.60), CF(0, -0.10, -0.90), p.base)
			c:light(p.glow, 1.0, 6)
		end,
	}

	-- A baby pangolin with overlapping scale bands and a curled tail tip.
	S.mm_t_pangopup = {
		label = "Scaleband Pangopup",
		set = SET,
		tint = C3(180, 150, 100),
		scale = 1.1,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.60, 1.30, 1.80),
				eyeY = 0.14, eyeSpread = 0.30,
				snout = { w = 0.36, h = 0.28, d = 0.50, y = -0.16, color = p.pale, nose = p.deep },
				legSize = V3(0.34, 0.28, 0.36), legX = 0.80, legZ = { 0.50, -0.50 }, legColor = p.dark,
				tail = false,
			})
			for i, z in ipairs({ 0.40, 0.0, -0.40 }) do
				c:box(V3(1.40 - i * 0.08, 0.20, 0.36), CF(0, 0.70, z), p.dark)
			end
			c:box(V3(0.60, 0.50, 0.70), CF(0, -0.10, -1.15), p.base)
			c:box(V3(0.46, 0.40, 0.50), CF(0.10, 0.05, -1.60) * ANG(0, 0.4, 0), p.dark)
			c:box(V3(0.34, 0.30, 0.34), CF(0.35, 0.20, -1.90) * ANG(0, 0.9, 0), p.base)
		end,
	}

	-- A gentle dugong with paddle flippers and a whiskery snout.
	S.mm_t_dugong = {
		label = "Tideflipper Dugong",
		set = SET,
		tint = C3(140, 180, 190),
		scale = 1.12,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.70, 1.30, 2.00),
				eyeY = 0.14, eyeSpread = 0.36,
				snout = { w = 0.70, h = 0.40, d = 0.50, y = -0.20, color = p.pale, nose = p.deep },
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V3(0.80, 0.14, 0.50), CF(0.95 * s, -0.55, 0.30), p.light)
				c:box(V3(0.16, 0.10, 0.20), CF(0.30 * s, -0.35, 1.05), WHITE)
			end
			c:box(V3(0.90, 0.50, 0.70), CF(0, -0.20, -1.20), p.base)
			c:box(V3(1.10, 0.16, 0.50), CF(0, -0.10, -1.70), p.light)
		end,
	}

	-- A tiny hedgie with soft moss spines and berry cheeks.
	S.mm_t_hedgelet = {
		label = "Bramble Hedgelet",
		set = SET,
		tint = C3(110, 140, 70),
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.70, 1.50, 1.60),
				eyeY = 0.14, eyeSpread = 0.36,
				snout = { w = 0.44, h = 0.28, d = 0.34, y = -0.22, color = p.pale, nose = p.deep },
				legSize = V3(0.34, 0.26, 0.34), legColor = p.dark, tail = false,
			})
			for _, v in ipairs({
				{0, 1.05, 0.10}, {0.35, 0.95, -0.15}, {-0.35, 0.95, -0.15},
				{0.45, 0.80, 0.25}, {-0.45, 0.80, 0.25}, {0, 1.00, -0.40},
				{0.30, 0.85, -0.55}, {-0.30, 0.85, -0.55},
			}) do
				c:cone(V3(0.16, 0.36, 0.16), CF(v[1], v[2], v[3]) * ANG(-0.5, 0, v[1] * 0.2), LEAF)
			end
			blush(c, 0.50, -0.30, 0.75)
		end,
	}

	-- A soft axolotl pup with twin frilly gills and a paddle tail.
	S.mm_t_axolpup = {
		label = "Twintail Axolpup",
		set = SET,
		tint = C3(255, 160, 190),
		scale = 1.08,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.60, 1.40, 1.60),
				eyeY = 0.16, eyeSpread = 0.36, eyeSize = V3(0.48, 0.52, 0.18),
				snout = { w = 0.50, h = 0.34, d = 0.36, y = -0.16, color = p.pale, nose = p.deep },
				bib = { w = 0.70, h = 0.50, y = -0.35, color = p.pale },
				legSize = V3(0.32, 0.24, 0.34), legColor = p.dark, tail = false,
			})
			for _, s in ipairs(SIDES) do
				for i, y in ipairs({ 0.70, 0.45, 0.20 }) do
					c:rod(V3(0.55 * s, y, 0.40), V3(0.95 * s, y + 0.15, 0.55), 0.04, p.light, nil, false)
					c:ball(V3(0.18, 0.18, 0.18), CF(0.98 * s, y + 0.16, 0.56), p.glow, NEON)
				end
			end
			c:box(V3(0.50, 0.40, 0.70), CF(0, -0.15, -1.05), p.base)
			c:box(V3(0.70, 0.14, 0.40), CF(0, -0.05, -1.50), p.light)
		end,
	}

	-- A plump arctic lemming with frosted toes and a stubby brush.
	S.mm_t_lemming = {
		label = "Frosttoe Lemming",
		set = SET,
		tint = C3(200, 180, 160),
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.70, 1.50, 1.60),
				eyeY = 0.16, eyeSpread = 0.36,
				snout = { w = 0.42, h = 0.28, d = 0.30, y = -0.20, color = p.pale, nose = p.deep },
				legSize = V3(0.36, 0.26, 0.36), legColor = CLOUD, tail = false,
			})
			ears(c, p.light, "up", p.pale)
			c:box(V3(0.30, 0.24, 0.40), CF(0, -0.15, -0.95), p.dark)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(V3(0.20, 0.08, 0.20), CF(0.50 * s, -0.90, 0.40 * t), CLOUD)
				end
			end
		end,
	}


	--------------------------------------------------------------------------
	-- LEGENDARY: bigger beasts.
	--------------------------------------------------------------------------

	-- A lion-bodied manticore with bat wings and a spiked scorpion tail.
	S.mm_t_manticore = {
		label = "Spiketail Manticore",
		set = SET,
		tint = C3(210, 90, 50),
		scale = 1.2,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.80, 1.60, 1.80),
				eyeY = 0.22, eyeSpread = 0.38,
				snout = { w = 0.60, h = 0.40, d = 0.50, y = -0.10, color = p.light, nose = p.deep },
				bib = { w = 0.90, h = 0.70, y = -0.40, color = p.pale },
				legSize = V3(0.40, 0.40, 0.40), legColor = p.dark, tail = false,
			})
			ears(c, p.light, "up", p.pale)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.14, 1.00, 0.90), CF(0.95 * s, 0.80, -0.30) * ANG(0.2, 0, -0.45 * s), p.dark)
				c:box(V3(0.12, 0.70, 0.60), CF(1.15 * s, 0.50, -0.70) * ANG(0.3, 0, -0.5 * s), p.deep)
			end
			c:box(V3(0.50, 0.40, 0.70), CF(0, 0.0, -1.15), p.base)
			c:box(V3(0.40, 0.50, 0.40), CF(0, 0.30, -1.55), p.dark)
			for i = 0, 3 do
				c:cone(V3(0.12, 0.28, 0.12), CF((i - 1.5) * 0.14, 0.65, -1.55) * ANG(-0.3, 0, 0), p.glow, NEON)
			end
		end,
	}

	-- Eagle front, horse rear: storm-feathered wings and a proud beak.
	S.mm_t_hippogriff = {
		label = "Stormmane Hippogriff",
		set = SET,
		tint = C3(90, 140, 200),
		scale = 1.22,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.70, 1.70, 1.80),
				eyeY = 0.28, eyeSpread = 0.36, mouth = false,
				legSize = V3(0.34, 0.44, 0.34), legColor = p.dark, tail = false,
			})
			c:box(V3(1.50, 0.80, 0.70), CF(0, 0.55, 0.55), p.pale)
			c:cone(V3(0.34, 0.44, 0.36), CF(0, 0.05, 1.05) * ANG(1.85, 0, 0), GOLD)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.16, 1.10, 1.00), CF(0.95 * s, 1.00, -0.30) * ANG(0, 0, -0.4 * s), p.dark)
				c:box(V3(0.14, 0.80, 0.70), CF(1.15 * s, 1.20, -0.70) * ANG(-0.2, 0, -0.45 * s), p.deep)
				c:cone(V3(0.20, 0.40, 0.16), CF(0.40 * s, 1.15, 0.30) * ANG(-0.3, 0, -0.2 * s), p.pale)
			end
			c:box(V3(0.40, 0.50, 0.70), CF(0, 0.20, -1.10), p.base)
			c:box(V3(0.30, 0.40, 0.50), CF(0, 0.40, -1.55), p.dark)
		end,
	}

	-- A marsh bunyip: broad snout, reed mane and glowing bog spots.
	S.mm_t_bunyip = {
		label = "Marshglow Bunyip",
		set = SET,
		tint = C3(60, 140, 110),
		scale = 1.18,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.90, 1.50, 1.90),
				eyeY = 0.18, eyeSpread = 0.42,
				snout = { w = 0.80, h = 0.44, d = 0.60, y = -0.18, color = p.light, nose = p.deep },
				legSize = V3(0.44, 0.36, 0.44), legColor = p.dark, tail = false,
			})
			for _, z in ipairs({ 0.40, 0.0, -0.40 }) do
				c:cone(V3(0.20, 0.50, 0.16), CF(0, 1.00, z) * ANG(-0.2, 0, 0), LEAF)
			end
			for _, v in ipairs({ {-0.55, 0.50}, {0.50, 0.20}, {-0.30, -0.30}, {0.40, -0.50} }) do
				c:box(V3(0.24, 0.08, 0.24), CF(v[1], 0.80, v[2]), p.glow, NEON)
			end
			c:box(V3(0.60, 0.50, 0.80), CF(0, -0.10, -1.20), p.base)
			c:box(V3(0.80, 0.16, 0.40), CF(0, 0.10, -1.70), p.light)
			c:light(p.glow, 0.8, 5)
		end,
	}

	-- A water-horse kelpie with braided seaweed mane and finned hooves.
	S.mm_t_kelpie = {
		label = "Tidebraid Kelpie",
		set = SET,
		tint = C3(40, 120, 160),
		scale = 1.2,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.60, 1.70, 1.80),
				eyeY = 0.26, eyeSpread = 0.34,
				snout = { w = 0.50, h = 0.40, d = 0.50, y = -0.05, color = p.light, nose = p.deep },
				legSize = V3(0.30, 0.44, 0.30), legColor = p.dark, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V3(0.20, 0.70, 0.14), CF(0.40 * s, 1.15, 0.10) * ANG(0, 0, -0.2 * s), p.light)
				for i = 0, 2 do
					c:box(V3(0.14, 0.40, 0.10), CF(0.55 * s, 0.80 - i * 0.25, 0.30 + i * 0.05) * ANG(0.3, 0, -0.4 * s), C3(40, 180, 170))
				end
				c:box(V3(0.40, 0.10, 0.30), CF(0.40 * s, -0.95, 0.40), p.light)
			end
			c:box(V3(0.40, 0.50, 0.70), CF(0, 0.20, -1.10), p.base)
			c:box(V3(0.70, 0.14, 0.40), CF(0, 0.40, -1.55), p.light)
		end,
	}

	-- A selkie mid-change: seal cloak draped over a soft humanoid torso.
	S.mm_t_selkie = {
		label = "Sealfriend Selkie",
		set = SET,
		tint = C3(170, 190, 210),
		scale = 1.15,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(1.40, 1.40, 1.20), CF(0, 0.10, 0), p.base)
			c:box(V3(1.20, 0.70, 1.00), CF(0, 0.90, 0.10), p.light)
			face(c, 0.95, 0.55, 0.28, 0.14)
			blush(c, 0.42, 0.70, 0.56)
			c:box(V3(1.80, 0.50, 1.60), CF(0, -0.50, -0.20), p.dark)
			c:box(V3(1.40, 0.40, 1.20), CF(0, -0.70, -0.80), p.deep)
			c:box(V3(0.80, 0.30, 0.70), CF(0, -0.60, -1.40), p.base)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.40, 0.70, 0.40), CF(0.70 * s, 0.30, 0.20), p.pale)
				c:box(V3(0.30, 0.20, 0.40), CF(0.40 * s, -0.95, 0.40), p.dark)
			end
			c:ball(V3(0.30, 0.30, 0.30), CF(0, 1.40, 0.10), p.pale)
		end,
	}

	-- A dream-eating baku with an elephant trunk, tiger stripes and a bushy tail.
	S.mm_t_baku = {
		label = "Dreamfeast Baku",
		set = SET,
		tint = C3(200, 160, 220),
		scale = 1.18,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.80, 1.60, 1.80),
				eyeY = 0.22, eyeSpread = 0.38, mouth = false,
				bib = { w = 0.80, h = 0.60, y = -0.40, color = p.pale },
				legSize = V3(0.40, 0.40, 0.40), legColor = p.dark, tail = false,
			})
			c:box(V3(0.36, 0.70, 0.36), CF(0, -0.30, 1.00) * ANG(0.6, 0, 0), p.light)
			c:box(V3(0.30, 0.40, 0.30), CF(0, -0.70, 1.25) * ANG(0.9, 0, 0), p.pale)
			ears(c, p.light, "down", p.pale)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.10, 0.50, 1.20), CF(0.85 * s, 0.30, -0.10), p.deep)
			end
			c:box(V3(0.50, 0.50, 0.60), CF(0, 0.20, -1.10), p.base)
			c:box(V3(0.60, 0.60, 0.50), CF(0, 0.40, -1.50), p.dark)
			c:light(p.glow, 0.7, 5)
		end,
	}

	-- A Wisconsin hodag: froggy grin, ridge of horns and stubby claws.
	S.mm_t_hodag = {
		label = "Hornridge Hodag",
		set = SET,
		tint = C3(80, 120, 70),
		scale = 1.15,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.80, 1.50, 1.80),
				eyeY = 0.20, eyeSpread = 0.40, eyeSize = V3(0.50, 0.46, 0.20),
				mouthY = -0.30, mouthSize = V3(0.90, 0.16, 0.12),
				legSize = V3(0.42, 0.34, 0.42), legColor = p.dark, tail = false,
			})
			for i, z in ipairs({ 0.45, 0.10, -0.25, -0.60 }) do
				c:cone(V3(0.18, 0.40 - i * 0.04, 0.18), CF(0, 0.95, z) * ANG(-0.25, 0, 0), BONE)
			end
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.14, 0.30, 0.14), CF(0.50 * s, 0.90, 0.40) * ANG(-0.2, 0, -0.3 * s), BONE)
				c:cone(V3(0.12, 0.22, 0.12), CF(0.55 * s, -0.85, 0.55) * ANG(0.8, 0, 0), BONE)
			end
			c:box(V3(0.50, 0.40, 0.70), CF(0, -0.10, -1.15), p.base)
		end,
	}

	-- A stag-bird peryton: antlers, feathered wings and cloven hooves.
	S.mm_t_peryton = {
		label = "Antlerwing Peryton",
		set = SET,
		tint = C3(140, 100, 70),
		scale = 1.22,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.60, 1.70, 1.70),
				eyeY = 0.26, eyeSpread = 0.34,
				snout = { w = 0.46, h = 0.40, d = 0.50, y = -0.05, color = p.light, nose = p.deep },
				legSize = V3(0.28, 0.44, 0.28), legColor = p.dark, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.25 * s, 1.00, 0.20), V3(0.55 * s, 1.50, 0.10), 0.04, BONE, nil, false)
				c:rod(V3(0.55 * s, 1.50, 0.10), V3(0.75 * s, 1.70, -0.10), 0.035, BONE, nil, false)
				c:rod(V3(0.55 * s, 1.50, 0.10), V3(0.40 * s, 1.75, 0.25), 0.03, BONE, nil, false)
				c:box(V3(0.14, 1.00, 0.90), CF(0.90 * s, 0.90, -0.30) * ANG(0, 0, -0.4 * s), p.dark)
			end
			c:box(V3(0.30, 0.40, 0.60), CF(0, 0.20, -1.05), p.base)
		end,
	}

	-- A peacock-tailed simurgh with a radiant plume crest.
	S.mm_t_simurgh = {
		label = "Plumecrest Simurgh",
		set = SET,
		tint = C3(255, 140, 80),
		scale = 1.2,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V3(1.60, 1.70, 1.60),
				eyeY = 0.28, eyeSpread = 0.34, mouth = false,
				bib = { w = 0.80, h = 0.60, y = -0.35, color = p.pale },
				legSize = V3(0.24, 0.40, 0.28), legZ = { 0.10 }, legColor = GOLD, tail = false,
			})
			c:cone(V3(0.28, 0.36, 0.28), CF(0, 0.05, 0.95) * ANG(1.75, 0, 0), GOLD)
			for i, x in ipairs({ -0.25, 0, 0.25 }) do
				c:cone(V3(0.20, 0.55, 0.20), CF(x, 1.20, 0.15) * ANG(-0.2, 0, -x), p.glow, NEON)
			end
			wings(c, p.dark, 0.20, 0.05, -0.10, 0.20)
			for i, x in ipairs({ -0.40, -0.15, 0.15, 0.40 }) do
				local cf = CF(x, 0.10, -0.95) * ANG(0.7, -x * 0.5, 0) * CF(0, 0, -0.40)
				c:box(V3(0.22, 0.14, 0.80), cf, p.base)
				c:ball(V3(0.22, 0.22, 0.22), cf * CF(0, 0, -0.50), p.glow, NEON)
			end
			c:light(p.glow, 1.0, 6)
		end,
	}

	-- A Mesopotamian anzu: lion body, eagle head, storm-cloud wings.
	S.mm_t_anzu = {
		label = "Stormbeak Anzu",
		set = SET,
		tint = C3(70, 100, 180),
		scale = 1.22,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.80, 1.60, 1.80),
				eyeY = 0.30, eyeSpread = 0.36, mouth = false,
				bib = { w = 0.90, h = 0.70, y = -0.40, color = p.pale },
				legSize = V3(0.40, 0.40, 0.40), legColor = p.dark, tail = false,
			})
			c:box(V3(1.40, 0.80, 0.70), CF(0, 0.55, 0.55), p.pale)
			c:cone(V3(0.36, 0.46, 0.36), CF(0, 0.10, 1.05) * ANG(1.85, 0, 0), GOLD)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.16, 1.05, 1.00), CF(0.95 * s, 0.95, -0.25) * ANG(0, 0, -0.4 * s), CLOUD)
				c:box(V3(0.14, 0.70, 0.70), CF(1.15 * s, 1.15, -0.65) * ANG(-0.2, 0, -0.45 * s), p.glow, NEON)
			end
			c:box(V3(0.40, 0.45, 0.70), CF(0, 0.10, -1.15), p.base)
			c:light(p.glow, 0.9, 6)
		end,
	}

	-- A turtle-shelled tarasque with six stubby legs and a lion face.
	S.mm_t_tarasque = {
		label = "Shellspine Tarasque",
		set = SET,
		tint = C3(100, 150, 80),
		scale = 1.2,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(2.00, 1.00, 1.80), CF(0, -0.20, 0), p.base)
			c:box(V3(2.20, 0.50, 2.00), CF(0, 0.40, 0), p.dark)
			for i, z in ipairs({ 0.50, 0.0, -0.50 }) do
				c:cone(V3(0.24, 0.40, 0.24), CF(0, 0.80, z), p.light)
			end
			c:box(V3(1.00, 0.80, 0.80), CF(0, 0.10, 1.00), p.light)
			face(c, 0.25, 1.35, 0.30, 0.14)
			c:box(V3(0.50, 0.30, 0.40), CF(0, -0.20, 1.50), p.pale)
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.50, 0.0, -0.50 }) do
					c:box(V3(0.34, 0.30, 0.34), CF(0.95 * s, -0.80, z), p.deep)
				end
				c:cone(V3(0.16, 0.36, 0.16), CF(0.40 * s, 0.70, 0.90) * ANG(-0.3, 0, -0.2 * s), BONE)
			end
			c:box(V3(0.50, 0.40, 0.70), CF(0, -0.20, -1.20), p.base)
		end,
	}

	-- A zaratan turtle so big a tiny palm grows on its shell island.
	S.mm_t_zaratan = {
		label = "Islandback Zaratan",
		set = SET,
		tint = C3(90, 160, 120),
		scale = 1.18,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(2.10, 0.90, 2.00), CF(0, -0.40, 0), p.base)
			c:box(V3(2.20, 0.50, 2.10), CF(0, 0.20, 0), p.dark)
			c:box(V3(1.60, 0.30, 1.50), CF(0, 0.50, 0), MOSS)
			c:box(V3(0.20, 0.70, 0.20), CF(0.20, 0.95, -0.10), TWIG, WOOD)
			c:box(V3(0.70, 0.20, 0.70), CF(0.20, 1.30, -0.10), LEAF)
			c:box(V3(0.90, 0.70, 0.80), CF(0, -0.20, 1.10), p.light)
			face(c, -0.05, 1.45, 0.28, 0.14)
			blush(c, 0.36, -0.30, 1.46)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.70, 0.16, 0.45), CF(1.05 * s, -0.85, 0.40), p.pale)
				c:box(V3(0.70, 0.16, 0.45), CF(1.05 * s, -0.85, -0.50), p.pale)
			end
			c:box(V3(0.50, 0.30, 0.60), CF(0, -0.50, -1.20), p.dark)
			c:box(V3(0.40, 0.20, 0.30), CF(0.40, 0.55, 0.40), SHELL)
		end,
	}


	--------------------------------------------------------------------------
	-- MYTHIC: habitats, nests and eggs.
	--------------------------------------------------------------------------

	-- A cliffside aerie nest of sticks, with eggs and a lookout perch.
	S.mm_t_aerie = {
		label = "Cliffside Aerie",
		set = SET,
		tint = C3(180, 140, 100),
		scale = 1.12,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(2.00, 0.50, 1.80), CF(0, -0.70, 0), TWIG, WOOD)
			c:box(V3(1.80, 0.40, 1.60), CF(0, -0.35, 0), p.base)
			for _, a in ipairs({ 0, 0.8, 1.6, 2.4, 3.2, 4.0, 4.8, 5.6 }) do
				c:box(V3(0.16, 0.20, 0.70), CF(0.85 * math.sin(a), -0.55, 0.75 * math.cos(a)) * ANG(0, a, 0.2), TWIG, WOOD)
			end
			c:ball(V3(0.50, 0.55, 0.50), CF(-0.30, 0.05, 0.10), SHELL)
			c:ball(V3(0.40, 0.45, 0.40), CF(0.35, 0.0, -0.20), p.pale)
			c:box(V3(0.20, 0.80, 0.20), CF(0.70, 0.20, 0.50), TWIG, WOOD)
			c:box(V3(0.50, 0.12, 0.40), CF(0.70, 0.65, 0.50), TWIG, WOOD)
			face(c, -0.20, 0.85, 0.30, 0.14)
			blush(c, 0.50, -0.45, 0.86)
			c:ball(V3(0.20, 0.20, 0.20), CF(-0.30, 0.40, 0.10), p.glow, NEON)
			c:light(p.glow, 0.8, 5)
		end,
	}

	-- Stacked cliff ledges with three nest bowls and tiny eggs.
	S.mm_t_rookery = {
		label = "Stormcliff Rookery",
		set = SET,
		tint = C3(100, 130, 170),
		scale = 1.12,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(2.00, 0.40, 1.20), CF(0, -0.90, 0), p.deep, SLATE)
			c:box(V3(1.70, 0.40, 1.20), CF(0, -0.40, 0.10), p.base, SLATE)
			c:box(V3(1.40, 0.40, 1.20), CF(0, 0.10, 0.20), p.dark, SLATE)
			for _, v in ipairs({
				{-0.40, -0.55, 0.40}, {0.40, -0.05, 0.50}, {0, 0.45, 0.55},
			}) do
				c:cyl(V3(0.20, 0.70, 0.70), CF(v[1], v[2], v[3]) * UP, TWIG, WOOD)
				c:ball(V3(0.22, 0.24, 0.22), CF(v[1], v[2] + 0.20, v[3]), SHELL)
			end
			face(c, -0.20, 0.75, 0.28, 0.13)
			c:box(V3(0.30, 0.50, 0.20), CF(-0.80, 0.50, -0.20) * ANG(0, 0, 0.3), p.light)
			c:light(AMBER, 0.7, 5)
		end,
	}

	-- A burrow mound with three tunnel mouths and a carrot welcome mat.
	S.mm_t_warren = {
		label = "Softloam Warren",
		set = SET,
		tint = C3(160, 120, 80),
		scale = 1.1,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:ball(V3(2.20, 1.40, 2.00), CF(0, -0.40, 0), p.base)
			c:box(V3(2.00, 0.30, 1.80), CF(0, -0.95, 0), MOSS)
			for _, v in ipairs({ {0, -0.20, 0.85}, {-0.55, -0.35, 0.50}, {0.55, -0.35, 0.50} }) do
				c:cyl(V3(0.40, 0.50, 0.50), CF(v[1], v[2], v[3]) * FRONT, INK)
			end
			face(c, 0.20, 0.95, 0.28, 0.14)
			blush(c, 0.50, -0.05, 0.96)
			c:cone(V3(0.20, 0.50, 0.20), CF(0.70, -0.40, 1.00) * ANG(PI, 0, 0), C3(255, 140, 40))
			c:box(V3(0.12, 0.30, 0.12), CF(0.70, -0.05, 1.00), LEAF)
			c:ball(V3(0.30, 0.30, 0.30), CF(-0.60, 0.40, -0.40), p.pale)
		end,
	}

	-- A warm stone cradle holding three glowing eggs under a reed canopy.
	S.mm_t_hatchery = {
		label = "Warmstone Hatchery",
		set = SET,
		tint = C3(220, 160, 90),
		scale = 1.12,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(2.00, 0.50, 1.60), CF(0, -0.80, 0), p.deep, SLATE)
			c:box(V3(1.80, 0.40, 1.40), CF(0, -0.40, 0), p.base)
			c:box(V3(1.60, 0.20, 1.20), CF(0, -0.10, 0), p.light)
			for _, x in ipairs({ -0.45, 0, 0.45 }) do
				c:ball(V3(0.50, 0.60, 0.50), CF(x, 0.25, 0), SHELL)
				c:box(V3(0.16, 0.16, 0.16), CF(x, 0.55, 0.10) * ANG(0.4, 0.4, 0), p.glow, NEON)
			end
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.80 * s, -0.40, -0.50), V3(0.50 * s, 0.90, -0.20), 0.05, TWIG, WOOD, false)
			end
			c:box(V3(1.40, 0.10, 0.80), CF(0, 0.95, -0.10), LEAF)
			face(c, -0.50, 0.75, 0.30, 0.13)
			c:light(p.glow, 1.2, 7)
		end,
	}

	-- A hollow log nursery lined with glowing moss and tiny nests.
	S.mm_t_broodhollow = {
		label = "Glowmoss Broodhollow",
		set = SET,
		tint = C3(80, 160, 100),
		scale = 1.12,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:cyl(V3(1.40, 2.00, 2.00), CF(0, -0.10, 0) * FRONT, TWIG, WOOD)
			c:cyl(V3(1.00, 1.70, 1.70), CF(0, -0.10, 0.10) * FRONT, INK)
			c:box(V3(0.20, 1.60, 1.60), CF(0, -0.10, 0.95), MOSS)
			for _, v in ipairs({ {-0.35, 0.20}, {0.30, -0.15}, {0, 0.45} }) do
				c:ball(V3(0.36, 0.40, 0.36), CF(v[1], v[2], 0.70), SHELL)
			end
			for _, s in ipairs(SIDES) do
				c:box(V3(0.30, 0.50, 0.20), CF(0.95 * s, 0.40, -0.40), LEAF)
				c:box(V3(0.10, 0.20, 0.10), CF(0.70 * s, 0.60, 0.80), p.glow, NEON)
			end
			face(c, 0.0, 1.05, 0.28, 0.13)
			c:light(p.glow, 1.0, 6)
		end,
	}

	-- A soft silk nest bed piled with pastel eggs and a blanket.
	S.mm_t_clutchbed = {
		label = "Silksoft Clutchbed",
		set = SET,
		tint = C3(240, 200, 220),
		scale = 1.1,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(2.00, 0.40, 1.80), CF(0, -0.70, 0), p.dark)
			c:box(V3(1.90, 0.50, 1.70), CF(0, -0.30, 0), p.base)
			c:box(V3(1.70, 0.20, 1.50), CF(0, 0.05, 0), p.pale)
			c:box(V3(1.20, 0.16, 0.80), CF(0, 0.20, 0.20), p.light)
			for _, v in ipairs({ {-0.40, 0.35, -0.20}, {0.35, 0.40, 0.10}, {0, 0.50, -0.40} }) do
				c:ball(V3(0.44, 0.50, 0.44), CF(v[1], v[2], v[3]), SHELL)
				c:box(V3(0.12, 0.12, 0.12), CF(v[1], v[2] + 0.28, v[3] + 0.05) * ANG(0, 0, PI / 4), p.glow, NEON)
			end
			face(c, -0.20, 0.90, 0.30, 0.14)
			blush(c, 0.55, -0.45, 0.91)
			c:light(p.glow, 0.9, 5)
		end,
	}

	-- A leaf-roofed den with a wooden door-face and pawprint mat.
	S.mm_t_denward = {
		label = "Leafcanopy Denward",
		set = SET,
		tint = C3(100, 160, 70),
		scale = 1.1,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(1.80, 1.20, 1.60), CF(0, -0.20, 0), p.base)
			c:box(V3(2.10, 0.30, 1.90), CF(0, 0.55, 0) * ANG(0, 0.1, 0), LEAF)
			c:box(V3(1.90, 0.20, 1.70), CF(0, 0.75, 0) * ANG(0, -0.1, 0), MOSS)
			c:box(V3(0.80, 1.00, 0.10), CF(0, -0.30, 0.85), TWIG, WOOD)
			face(c, -0.10, 0.92, 0.26, 0.13)
			c:box(V3(1.00, 0.12, 0.50), CF(0, -0.90, 0.90), p.dark)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.20, 0.16, 0.20), CF(0.25 * s, -0.85, 1.05), INK)
				c:box(V3(0.30, 0.60, 0.20), CF(0.95 * s, 0.10, -0.40), LEAF)
			end
			c:ball(V3(0.30, 0.30, 0.30), CF(0.50, 0.30, 0.50), p.glow, NEON)
		end,
	}

	-- A glass incubator dome over a glowing clutch on a pedestal.
	S.mm_t_incubarium = {
		label = "Amberglass Incubarium",
		set = SET,
		tint = C3(255, 180, 60),
		scale = 1.15,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(1.60, 0.30, 1.60), CF(0, -0.95, 0), GOLD, METAL)
			c:box(V3(1.20, 0.80, 1.20), CF(0, -0.40, 0), p.base)
			c:box(V3(1.40, 0.16, 1.40), CF(0, 0.10, 0), GOLD, METAL)
			c:ball(V3(0.55, 0.65, 0.55), CF(-0.25, 0.50, 0), SHELL)
			c:ball(V3(0.45, 0.55, 0.45), CF(0.30, 0.45, 0.15), p.pale)
			c:ball(V3(0.35, 0.42, 0.35), CF(0.05, 0.55, -0.30), AMBER)
			local glass = c:ball(V3(1.60, 1.40, 1.60), CF(0, 0.70, 0), p.pale, GLASS)
			glass.Transparency = 0.55
			face(c, -0.35, 0.65, 0.26, 0.12)
			c:box(V3(0.40, 0.10, 0.06), CF(0, -0.70, 0.62), GOLD, METAL)
			c:light(AMBER, 1.4, 8)
			c:sparkle(p.glow, 4, 0.7, 0.18)
		end,
	}

	-- A grove of three woven nests in a forked tree, feathers drifting.
	S.mm_t_nestgrove = {
		label = "Feathered Nestgrove",
		set = SET,
		tint = C3(140, 170, 90),
		scale = 1.15,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(0.40, 1.60, 0.40), CF(0, -0.20, 0), TWIG, WOOD)
			c:box(V3(1.20, 0.30, 0.30), CF(0, 0.60, 0), TWIG, WOOD)
			c:box(V3(0.30, 0.30, 1.00), CF(0, 0.60, 0), TWIG, WOOD)
			for _, v in ipairs({ {-0.55, 0.85, 0}, {0.55, 0.85, 0}, {0, 0.90, 0.55} }) do
				c:cyl(V3(0.18, 0.70, 0.70), CF(v[1], v[2], v[3]) * UP, p.base)
				c:ball(V3(0.24, 0.28, 0.24), CF(v[1], v[2] + 0.18, v[3]), SHELL)
			end
			c:box(V3(1.40, 0.40, 1.40), CF(0, -1.00, 0), MOSS)
			face(c, -0.30, 0.30, 0.22, 0.12)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.30, 0.08, 0.50), CF(0.70 * s, 0.30, -0.40) * ANG(0.4, 0, 0.2 * s), p.pale)
			end
			c:light(p.glow, 0.8, 5)
		end,
	}

	-- A spiralling runestone tower cradling a giant glowing egg.
	S.mm_t_eggspire = {
		label = "Runestone Eggspire",
		set = SET,
		tint = C3(160, 120, 220),
		scale = 1.15,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(1.40, 0.30, 1.40), CF(0, -1.00, 0), p.deep, SLATE)
			c:box(V3(1.00, 1.60, 1.00), CF(0, -0.10, 0), p.base, SLATE)
			for i, a in ipairs({ 0, 1.2, 2.4, 3.6 }) do
				c:box(V3(0.30, 0.24, 0.50), CF(0.60 * math.sin(a), -0.60 + i * 0.35, 0.60 * math.cos(a)) * ANG(0, a, 0), p.dark, SLATE)
				c:box(V3(0.14, 0.10, 0.14), CF(0.60 * math.sin(a), -0.45 + i * 0.35, 0.60 * math.cos(a)), p.glow, NEON)
			end
			c:ball(V3(0.90, 1.10, 0.90), CF(0, 1.00, 0), SHELL)
			c:box(V3(0.30, 0.30, 0.30), CF(0, 1.50, 0.20) * ANG(0.5, 0.5, 0), p.glow, NEON)
			face(c, -0.20, 0.55, 0.26, 0.13)
			c:light(p.glow, 1.3, 8)
		end,
	}

	-- An underwater hatch-hall of coral arches and pearl-eggs.
	S.mm_t_hatchhall = {
		label = "Coralreef Hatchhall",
		set = SET,
		tint = C3(40, 180, 170),
		scale = 1.15,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(2.00, 0.40, 1.60), CF(0, -0.90, 0), p.deep)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.30, 1.40, 0.30), CF(0.80 * s, -0.10, 0.50), p.base)
				c:box(V3(0.30, 1.40, 0.30), CF(0.80 * s, -0.10, -0.50), p.base)
				c:box(V3(0.40, 0.30, 1.40), CF(0.80 * s, 0.70, 0), p.light)
				c:cone(V3(0.30, 0.50, 0.30), CF(0.90 * s, 1.05, 0.30), C3(255, 120, 140), NEON)
			end
			c:box(V3(1.80, 0.24, 0.30), CF(0, 0.70, 0.50), p.pale)
			for _, x in ipairs({ -0.40, 0, 0.40 }) do
				c:ball(V3(0.40, 0.46, 0.40), CF(x, -0.40, 0), PEARL)
			end
			face(c, -0.50, 0.75, 0.28, 0.13)
			c:light(C3(80, 220, 220), 1.0, 6)
		end,
	}

	-- An open bestiary book whose pages sprout tiny creature silhouettes.
	S.mm_t_bestiary = {
		label = "Living Bestiary",
		set = SET,
		tint = C3(180, 140, 60),
		scale = 1.12,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(0.20, 1.40, 1.80), CF(0, 0.0, 0), TWIG, WOOD)
			c:box(V3(1.40, 0.12, 1.80), CF(-0.70, 0.0, 0) * ANG(0, 0, 0.35), p.base)
			c:box(V3(1.40, 0.12, 1.80), CF(0.70, 0.0, 0) * ANG(0, 0, -0.35), p.base)
			c:box(V3(1.20, 0.08, 1.60), CF(-0.70, 0.08, 0) * ANG(0, 0, 0.35), p.pale)
			c:box(V3(1.20, 0.08, 1.60), CF(0.70, 0.08, 0) * ANG(0, 0, -0.35), p.pale)
			-- Tiny creature silhouettes on the pages.
			c:box(V3(0.30, 0.24, 0.10), CF(-0.70, 0.30, 0.40) * ANG(0, 0, 0.35), p.deep)
			c:box(V3(0.20, 0.30, 0.10), CF(-0.50, 0.35, -0.30) * ANG(0, 0, 0.35), p.dark)
			c:box(V3(0.34, 0.20, 0.10), CF(0.60, 0.30, 0.20) * ANG(0, 0, -0.35), p.deep)
			c:cone(V3(0.16, 0.28, 0.10), CF(0.80, 0.40, -0.40) * ANG(0, 0, -0.35), p.glow, NEON)
			face(c, 0.10, 0.20, 0.22, 0.12)
			c:box(V3(0.50, 0.20, 0.10), CF(0, -0.80, 0.90), GOLD, METAL)
			c:light(p.glow, 0.8, 5)
		end,
	}


	--------------------------------------------------------------------------
	-- DIVINE: apex legends.
	--------------------------------------------------------------------------

	-- A winged lamassu: bull body, humanoid face, gold horned crown.
	S.mm_t_lamassu = {
		label = "Winged Lamassu",
		set = SET,
		tint = C3(220, 180, 80),
		scale = 1.25,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.80, 1.70, 1.90),
				eyeY = 0.30, eyeSpread = 0.34,
				snout = { w = 0.50, h = 0.40, d = 0.40, y = 0.0, color = p.pale, nose = p.deep },
				legSize = V3(0.36, 0.44, 0.36), legColor = p.dark, tail = false,
			})
			c:box(V3(0.90, 0.20, 0.70), CF(0, 1.10, 0.30), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.14, 0.36, 0.14), CF(0.25 * s, 1.35, 0.30), GOLD, METAL)
				c:box(V3(0.16, 1.10, 1.00), CF(0.95 * s, 0.90, -0.25) * ANG(0, 0, -0.4 * s), p.light)
				c:box(V3(0.12, 0.70, 0.70), CF(1.15 * s, 1.10, -0.65) * ANG(-0.2, 0, -0.45 * s), p.glow, NEON)
			end
			c:box(V3(0.40, 0.50, 0.70), CF(0, 0.20, -1.20), p.base)
			c:light(GOLD, 1.2, 7)
			c:sparkle(p.glow, 5, 0.8, 0.20)
		end,
	}

	-- A sacred xiezhi: lion-dog body, single jade horn, flame mane.
	S.mm_t_xiezhi = {
		label = "Jadehorn Xiezhi",
		set = SET,
		tint = C3(60, 200, 140),
		scale = 1.22,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.80, 1.70, 1.80),
				eyeY = 0.26, eyeSpread = 0.38,
				snout = { w = 0.56, h = 0.40, d = 0.50, y = -0.08, color = p.light, nose = p.deep },
				bib = { w = 0.90, h = 0.70, y = -0.40, color = p.pale },
				legSize = V3(0.40, 0.40, 0.40), legColor = p.dark, tail = false,
			})
			c:cone(V3(0.28, 0.80, 0.28), CF(0, 1.30, 0.30) * ANG(-0.25, 0, 0), C3(40, 220, 140), NEON)
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.22, 0.50, 0.22), CF(0.35 * s, 1.10, 0.05) * ANG(-0.2, 0, -0.3 * s), p.glow, NEON)
			end
			c:box(V3(0.50, 0.50, 0.70), CF(0, 0.20, -1.15), p.base)
			c:box(V3(0.40, 0.40, 0.40), CF(0, 0.45, -1.55), p.dark)
			c:light(p.glow, 1.3, 8)
			c:sparkle(C3(40, 220, 140), 5, 0.8, 0.20)
		end,
	}

	-- A heroic minotaur with a labyrinth crest and twin horns.
	S.mm_t_minotaur = {
		label = "Labyrinth Minotaur",
		set = SET,
		tint = C3(140, 90, 50),
		scale = 1.25,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.80, 1.90, 1.70),
				eyeY = 0.30, eyeSpread = 0.38,
				snout = { w = 0.60, h = 0.44, d = 0.50, y = -0.05, color = p.light, nose = p.deep },
				bib = { w = 0.90, h = 0.80, y = -0.45, color = p.pale },
				legSize = V3(0.42, 0.44, 0.42), legColor = p.dark, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.18, 0.70, 0.18), CF(0.40 * s, 1.30, 0.20) * ANG(-0.35, 0, -0.25 * s), BONE)
				c:box(V3(0.20, 0.50, 0.14), CF(0.55 * s, 0.90, 0.10) * ANG(0, 0, -0.2 * s), p.dark)
			end
			c:box(V3(0.70, 0.70, 0.10), CF(0, 0.20, 0.90), GOLD, METAL)
			c:box(V3(0.40, 0.40, 0.08), CF(0, 0.20, 0.96) * ANG(0, 0, PI / 4), p.glow, NEON)
			c:box(V3(0.36, 0.40, 0.60), CF(0, -0.10, -1.05), p.base)
			c:light(GOLD, 1.0, 6)
		end,
	}

	-- A starry centaur: horse body, archer torso, constellation sash.
	S.mm_t_centaur = {
		label = "Starstride Centaur",
		set = SET,
		tint = C3(200, 160, 100),
		scale = 1.28,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.70, 1.50, 2.00),
				eyeY = 0.70, eyeSpread = 0.30,
				snout = { w = 0.40, h = 0.30, d = 0.30, y = 0.50, color = p.pale, nose = p.deep },
				legSize = V3(0.32, 0.40, 0.32), legColor = p.dark, tail = false,
			})
			c:box(V3(0.90, 1.00, 0.70), CF(0, 0.90, 0.40), p.light)
			c:box(V3(0.70, 0.50, 0.50), CF(0, 1.50, 0.40), p.pale)
			face(c, 1.55, 0.65, 0.22, 0.11)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.30, 0.60, 0.30), CF(0.50 * s, 0.90, 0.40), p.base)
			end
			c:box(V3(0.80, 0.12, 0.10), CF(0, 1.10, 0.75), p.glow, NEON)
			for _, v in ipairs({ {-0.25, 1.10}, {0, 1.20}, {0.25, 1.10} }) do
				c:ball(V3(0.12, 0.12, 0.12), CF(v[1], v[2], 0.80), p.glow, NEON)
			end
			c:box(V3(0.36, 0.40, 0.70), CF(0, 0.10, -1.25), p.base)
			c:light(p.glow, 1.2, 7)
			c:sparkle(p.glow, 6, 0.9, 0.18)
		end,
	}

	-- A grove faun with curling horns, panpipes and leafy greaves.
	S.mm_t_faun = {
		label = "Grovehorn Faun",
		set = SET,
		tint = C3(120, 180, 80),
		scale = 1.2,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(1.20, 1.60, 1.00), CF(0, 0.10, 0), p.base)
			c:box(V3(1.00, 0.70, 0.80), CF(0, 1.00, 0.10), p.light)
			face(c, 1.05, 0.50, 0.26, 0.13)
			blush(c, 0.38, 0.80, 0.51)
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.16, 0.50, 0.16), CF(0.30 * s, 1.50, 0.10) * ANG(-0.2, 0, -0.4 * s), BONE)
				c:box(V3(0.36, 0.70, 0.36), CF(0.35 * s, -0.70, 0.10), p.dark)
				c:box(V3(0.40, 0.20, 0.40), CF(0.35 * s, -1.10, 0.10), LEAF)
			end
			c:box(V3(0.50, 0.20, 0.16), CF(0, 0.30, 0.55), TWIG, WOOD)
			for i = 0, 3 do
				c:cyl(V3(0.30, 0.08, 0.08), CF(-0.15 + i * 0.10, 0.30, 0.65) * UP, TWIG, WOOD)
			end
			c:box(V3(0.30, 0.40, 0.40), CF(0, -0.20, -0.70), p.base)
			c:light(LEAF, 0.9, 5)
			c:sparkle(p.glow, 4, 0.7, 0.16)
		end,
	}

	-- A thunderbird with storm wings, lightning crest and cloud talons.
	S.mm_t_thunderbird = {
		label = "Skyrend Thunderbird",
		set = SET,
		tint = C3(60, 80, 200),
		scale = 1.28,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V3(1.70, 1.80, 1.70),
				eyeY = 0.30, eyeSpread = 0.36, mouth = false,
				bib = { w = 0.90, h = 0.70, y = -0.35, color = p.pale },
				legSize = V3(0.26, 0.40, 0.30), legZ = { 0.10 }, legColor = GOLD, tail = false,
			})
			c:cone(V3(0.30, 0.40, 0.30), CF(0, 0.10, 1.00) * ANG(1.75, 0, 0), GOLD)
			for i, x in ipairs({ -0.30, 0, 0.30 }) do
				c:cone(V3(0.18, 0.60, 0.18), CF(x, 1.30, 0.15) * ANG(-0.2, 0, -x), C3(255, 236, 80), NEON)
			end
			for _, s in ipairs(SIDES) do
				c:box(V3(0.16, 1.20, 1.10), CF(1.00 * s, 0.90, -0.20) * ANG(0, 0, -0.45 * s), CLOUD)
				c:box(V3(0.12, 0.80, 0.80), CF(1.25 * s, 1.10, -0.60) * ANG(-0.2, 0, -0.5 * s), p.glow, NEON)
			end
			for i, x in ipairs({ -0.30, 0, 0.30 }) do
				c:box(V3(0.22, 0.14, 0.80), CF(x, 0.10, -1.00) * ANG(0.6, 0, 0), p.base)
			end
			c:light(C3(255, 236, 80), 1.5, 9)
			c:sparkle(p.glow, 6, 1.0, 0.22)
		end,
	}


	--------------------------------------------------------------------------
	-- EXOTIC: primordial titans.
	--------------------------------------------------------------------------

	-- A floating ark of origins: hull, glowing cargo-eggs and rainbow sails.
	S.mm_t_arkhold = {
		label = "Genesis Arkhold",
		set = SET,
		tint = C3(180, 140, 220),
		scale = 1.25,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(2.20, 0.60, 1.40), CF(0, -0.60, 0), p.base)
			c:box(V3(2.00, 0.50, 1.20), CF(0, -0.10, 0), p.dark)
			c:box(V3(0.16, 1.40, 0.16), CF(0, 0.70, 0), TWIG, WOOD)
			c:box(V3(0.10, 1.00, 1.00), CF(0.10, 0.90, 0) * ANG(0, 0, 0.3), p.glow, NEON)
			c:box(V3(0.10, 0.80, 0.80), CF(-0.10, 0.80, 0) * ANG(0, 0, -0.25), C3(80, 200, 255), NEON)
			for _, x in ipairs({ -0.60, -0.20, 0.20, 0.60 }) do
				c:ball(V3(0.36, 0.42, 0.36), CF(x, 0.30, 0), SHELL)
				c:box(V3(0.12, 0.12, 0.12), CF(x, 0.55, 0.05) * ANG(0.4, 0.4, 0), p.glow, NEON)
			end
			face(c, -0.50, 0.75, 0.30, 0.14)
			blush(c, 0.55, -0.75, 0.76)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.30, 0.20, 0.40), CF(1.10 * s, -0.90, 0.30), p.deep)
				c:box(V3(0.30, 0.20, 0.40), CF(1.10 * s, -0.90, -0.30), p.deep)
			end
			c:ball(V3(0.40, 0.30, 0.40), CF(0, 1.50, 0), CLOUD)
			c:light(p.glow, 1.6, 10)
			c:sparkle(p.glow, 8, 1.0, 0.24)
		end,
	}

	-- A living tower of stacked habitats: reef, canopy, snow and stars.
	S.mm_t_biotower = {
		label = "Primordial Biotower",
		set = SET,
		tint = C3(80, 200, 140),
		scale = 1.22,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(1.60, 0.40, 1.60), CF(0, -1.00, 0), p.deep)
			c:box(V3(1.40, 0.70, 1.40), CF(0, -0.50, 0), C3(40, 160, 180))
			c:box(V3(1.30, 0.70, 1.30), CF(0, 0.15, 0), LEAF)
			c:box(V3(1.20, 0.60, 1.20), CF(0, 0.75, 0), CLOUD)
			c:box(V3(1.00, 0.50, 1.00), CF(0, 1.25, 0), p.glow, NEON)
			c:cone(V3(0.80, 0.40, 0.80), CF(0, 1.65, 0), GOLD, METAL)
			face(c, -0.40, 0.75, 0.28, 0.13)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.20, 0.30, 0.20), CF(0.70 * s, -0.30, 0.70), C3(255, 120, 140), NEON)
				c:box(V3(0.30, 0.20, 0.20), CF(0.60 * s, 0.40, 0.65), TWIG, WOOD)
				c:ball(V3(0.20, 0.20, 0.20), CF(0.50 * s, 0.95, 0.55), WHITE)
			end
			c:light(p.glow, 1.5, 9)
			c:sparkle(p.glow, 7, 0.9, 0.22)
		end,
	}

	-- A crystal dome over a miniature world: mountains, sea and a sun.
	S.mm_t_primordome = {
		label = "Worldspan Primordome",
		set = SET,
		tint = C3(255, 120, 180),
		scale = 1.25,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(1.80, 0.40, 1.80), CF(0, -0.90, 0), GOLD, METAL)
			c:box(V3(1.60, 0.50, 1.60), CF(0, -0.50, 0), p.base)
			c:box(V3(1.40, 0.20, 0.70), CF(0, -0.20, 0.30), C3(40, 140, 220), GLASS)
			c:box(V3(0.60, 0.50, 0.50), CF(-0.30, 0.10, -0.20), p.dark, SLATE)
			c:cone(V3(0.50, 0.40, 0.50), CF(-0.30, 0.50, -0.20), CLOUD)
			c:box(V3(0.40, 0.30, 0.40), CF(0.40, 0.0, -0.30), LEAF)
			c:ball(V3(0.30, 0.30, 0.30), CF(0.40, 0.55, 0.20), C3(255, 200, 40), NEON)
			local dome = c:ball(V3(1.90, 1.50, 1.90), CF(0, 0.50, 0), p.pale, GLASS)
			dome.Transparency = 0.5
			face(c, -0.40, 0.85, 0.28, 0.13)
			blush(c, 0.50, -0.65, 0.86)
			c:light(C3(255, 200, 40), 1.6, 10)
			c:sparkle(p.glow, 8, 1.0, 0.24)
		end,
	}

	-- A colossal bone roost: rib cage arch, titan egg and glowing runes.
	S.mm_t_titanroost = {
		label = "Titanbone Titanroost",
		set = SET,
		tint = C3(200, 180, 140),
		scale = 1.28,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(2.20, 0.40, 1.80), CF(0, -0.95, 0), p.deep, SLATE)
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.90 * s, -0.80, 0.60), V3(0.40 * s, 1.20, 0.20), 0.08, BONE, nil, false)
				c:rod(V3(0.90 * s, -0.80, -0.40), V3(0.40 * s, 1.20, -0.20), 0.08, BONE, nil, false)
				c:cone(V3(0.20, 0.40, 0.20), CF(0.40 * s, 1.40, 0) * ANG(PI, 0, 0), BONE)
			end
			c:box(V3(1.00, 0.20, 1.00), CF(0, 1.30, 0), BONE)
			c:ball(V3(1.00, 1.20, 1.00), CF(0, 0.20, 0), SHELL)
			c:box(V3(0.36, 0.36, 0.36), CF(0, 0.80, 0.30) * ANG(0.5, 0.5, 0), p.glow, NEON)
			for i = 0, 5 do
				local a = i * PI / 3
				c:box(V3(0.16, 0.10, 0.10), CF(0.85 * math.sin(a), -0.70, 0.70 * math.cos(a)), p.glow, NEON)
			end
			face(c, -0.55, 0.95, 0.30, 0.14)
			c:light(p.glow, 1.8, 11)
			c:sparkle(p.glow, 9, 1.1, 0.26)
		end,
	}

	return S
end
