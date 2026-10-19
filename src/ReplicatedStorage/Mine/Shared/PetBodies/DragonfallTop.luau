--[[ PetBodies/DragonfallTop -- Dragonfall's top bodies: one body per Epic-and-up
	pet, each worn by that pet alone. Dragonkin of every outline (newt, coatl,
	ouroboros, longship) mixed with the things that live round a dragon's hoard and
	its volcanic ruins (mimics, fossils, guardians, gates), so no two good pets
	read as the same animal. See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block, ridge = K.C3, K.block, K.ridge
	local INK, WHITE, METAL, NEON, GLASS, SLATE, WOOD = K.INK, K.WHITE, K.METAL, K.NEON, K.GLASS, K.SLATE, K.WOOD
	local S = {}
	local SET = "dragonfall"
	local SIDES = { -1, 1 }
	local V3, CF, ANG = Vector3.new, CFrame.new, CFrame.Angles
	local PI = math.pi

	-- Treasure, bone, lava and gems stay fixed; everything else is the pet's colour.
	local GOLD = C3(246, 196, 64)
	local COIN = C3(255, 218, 96)
	local BONE = C3(244, 240, 230)
	local AMBER = C3(255, 170, 40)
	local LAVA = C3(255, 110, 30)
	local RUBY = C3(230, 40, 80)
	local EMERALD = C3(60, 220, 120)
	local SAPPHIRE = C3(70, 150, 255)
	local STONE = C3(150, 144, 136)
	local CLOUD = C3(240, 244, 252)
	local TIMBER = C3(130, 90, 56)
	local LEAF = C3(86, 170, 70)
	local BOLT = C3(255, 236, 110)

	--------------------------------------------------------------------------
	-- EPIC: charming and clean.
	--------------------------------------------------------------------------

	-- A sprawling ember newt: long and low, legs splayed out to the sides, a
	-- flame crest down its back, glowing spots and its tail swept round.
	S.df_t_newt = {
		label = "Ember Newt",
		set = SET,
		tint = C3(255, 92, 40),
		scale = 1.15,
		head = CF(0, 0.70, 0.40),
		neck = CF(0, -0.20, 1.00),
		back = CF(0, 0.70, -0.60),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.80, 1.20, 2.00),
				eyeY = 0.16, eyeSpread = 0.44, eyeSize = V3(0.46, 0.54, 0.20),
				mouthY = -0.26, mouthSize = V3(0.70, 0.10, 0.10),
				legSize = V3(0.50, 0.30, 0.46), legX = 0.98, legY = -0.40, legZ = { 0.56, -0.56 }, legColor = p.dark,
				tail = false,
			})
			for i, z in ipairs({ 0.45, 0.0, -0.45 }) do
				c:cone(V3(0.30, 0.46 - i * 0.06, 0.40), CF(0, 0.86, z), p.light)
			end
			for _, v in ipairs({ { -0.52, 0.30 }, { 0.48, -0.12 }, { -0.36, -0.62 } }) do
				c:box(V3(0.26, 0.06, 0.26), CF(v[1], 0.67, v[2]), p.glow, NEON)
			end
			c:box(V3(0.70, 0.56, 0.70), CF(0.10, -0.14, -1.25) * ANG(0, 0.25, 0), p.base)
			c:box(V3(0.50, 0.42, 0.60), CF(0.45, -0.22, -1.70) * ANG(0, 0.70, 0), p.base)
			c:box(V3(0.32, 0.28, 0.50), CF(0.92, -0.30, -1.90) * ANG(0, 1.20, 0), p.dark)
		end,
	}

	-- A dragonfly with a scaled body: big eye domes, four glassy wings and a
	-- long banded tail.
	S.df_t_dragonfly = {
		label = "Scale Dragonfly",
		set = SET,
		tint = C3(30, 200, 220),
		scale = 1.20,
		head = CF(0, 0.96, 0.10),
		neck = CF(0, -0.30, 0.70),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.30, 1.20, 1.30),
				eyeY = 0.16, eyeSpread = 0.32, eyeSize = V3(0.46, 0.54, 0.20),
				mouthY = -0.28,
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V3(0.50, 0.34, 0.50), CF(0.34 * s, 0.78, 0.28), p.light)
				-- Front and back wings, the front pair veined with light.
				c:box(V3(1.20, 0.06, 0.50), CF(0.86 * s, 0.72, 0.12) * ANG(0, -0.20 * s, 0.12 * s), p.pale).Transparency = 0.25
				c:box(V3(1.10, 0.06, 0.46), CF(0.82 * s, 0.68, -0.40) * ANG(0, 0.25 * s, 0.10 * s), p.pale).Transparency = 0.25
				c:box(V3(0.90, 0.07, 0.08), CF(0.86 * s, 0.73, 0.12) * ANG(0, -0.20 * s, 0.12 * s), p.glow, NEON)
				for _, z in ipairs({ 0.30, 0.0, -0.30 }) do
					c:rod(V3(0.40 * s, -0.42, z), V3(0.64 * s, -0.80, z + 0.10), 0.05, p.deep, nil, false)
				end
			end
			c:box(V3(0.56, 0.52, 0.50), CF(0, 0.04, -0.86), p.dark)
			c:box(V3(0.46, 0.44, 0.48), CF(0, 0.08, -1.32), p.base)
			c:box(V3(0.36, 0.34, 0.44), CF(0, 0.12, -1.74), p.dark)
			c:box(V3(0.26, 0.26, 0.26), CF(0, 0.16, -2.04), p.glow, NEON)
		end,
	}

	-- A pocket fairy dragon: round, floating on butterfly wings, with glowing
	-- antennae and a curly little tail.
	S.df_t_pixie = {
		label = "Pixie Drakelet",
		set = SET,
		tint = C3(250, 120, 210),
		scale = 1.05,
		head = CF(0, 1.00, 0.10),
		neck = CF(0, -0.30, 0.86),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.70, 1.60, 1.60),
				eyeY = 0.20, eyeSpread = 0.38, eyeSize = V3(0.50, 0.60, 0.20),
				snout = { w = 0.50, h = 0.30, d = 0.26, y = -0.18, color = p.pale, nose = p.deep },
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V3(1.00, 0.90, 0.08), CF(0.86 * s, 0.76, -0.86) * ANG(0, 0, -0.45 * s), p.light)
				c:box(V3(0.70, 0.60, 0.08), CF(0.78 * s, 0.02, -0.86) * ANG(0, 0, 0.40 * s), p.pale)
				c:box(V3(0.30, 0.30, 0.10), CF(1.00 * s, 0.88, -0.88) * ANG(0, 0, -0.45 * s), p.glow, NEON)
				c:rod(V3(0.22 * s, 0.80, 0.30), V3(0.42 * s, 1.25, 0.45), 0.04, p.dark, nil, false)
				c:ball(V3(0.18, 0.18, 0.18), CF(0.42 * s, 1.27, 0.46), p.glow, NEON)
			end
			c:box(V3(0.26, 0.26, 0.36), CF(0, -0.40, -0.98), p.base)
			c:box(V3(0.22, 0.22, 0.26), CF(0, -0.22, -1.16) * ANG(0.8, 0, 0), p.dark)
		end,
	}

	-- A treasure chest that is secretly alive: lid thrown open on a heap of
	-- gold, gold bands, a lock plate and four stubby feet.
	S.df_t_mimic = {
		label = "Coffer Mimic",
		set = SET,
		tint = C3(130, 60, 190),
		head = CF(0, 1.00, 0.10),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.40, -1.10),
		build = function(c, p)
			c:box(V3(1.90, 1.00, 1.50), CF(0, -0.35, 0), p.base)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.16, 1.04, 1.54), CF(0.62 * s, -0.35, 0), GOLD, METAL)
				c:box(V3(0.18, 0.40, 1.58), CF(0.62 * s, 0.86, -1.10) * ANG(-1.8, 0, 0), GOLD, METAL)
				for _, z in ipairs({ 0.50, -0.50 }) do
					c:box(V3(0.30, 0.20, 0.30), CF(0.70 * s, -0.95, z), p.dark)
				end
			end
			c:box(V3(1.94, 0.14, 1.54), CF(0, -0.80, 0), GOLD, METAL)
			-- The lid, hinged at the back and thrown open.
			c:box(V3(1.94, 0.36, 1.54), CF(0, 0.86, -1.10) * ANG(-1.8, 0, 0), p.dark)
			-- The hoard inside.
			c:box(V3(1.70, 0.30, 1.30), CF(0, 0.20, 0), GOLD, METAL)
			c:cyl(V3(0.06, 0.36, 0.36), CF(0.40, 0.40, 0.20) * ANG(0, 0, 1.3), COIN, METAL)
			c:cyl(V3(0.06, 0.36, 0.36), CF(-0.30, 0.42, -0.20) * ANG(0.4, 0, 1.0), COIN, METAL)
			c:box(V3(0.26, 0.26, 0.26), CF(-0.52, 0.42, 0.25) * ANG(0, 0.6, PI / 4), RUBY, NEON)
			-- The face on the front, under the lock.
			c:eyes(-0.18, 0.80, 0.42, 0.20)
			c:box(V3(0.56, 0.10, 0.06), CF(0, -0.58, 0.77), INK)
			c:box(V3(0.30, 0.26, 0.08), CF(0, 0.02, 0.77), GOLD, METAL)
		end,
	}

	-- A wobbly tower of coins with a face: a coin on edge for a hat, little
	-- arms, and an emerald held up proudly.
	S.df_t_coinstack = {
		label = "Coinstack Critter",
		set = SET,
		tint = C3(240, 128, 150),
		head = CF(0, 1.50, 0),
		neck = CF(0, -0.20, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			local stack = {
				{ 0.00, -0.80, 0.00 }, { 0.04, -0.52, 0.03 }, { -0.03, -0.24, -0.02 },
				{ 0.03, 0.04, 0.02 }, { -0.02, 0.32, 0.00 }, { 0.02, 0.60, 0.03 },
			}
			for i, v in ipairs(stack) do
				c:cyl(V3(0.28, 1.50, 1.50), CF(v[1], v[2], v[3]) * ANG(0, 0, PI / 2), i % 2 == 0 and p.light or p.base, METAL)
			end
			c:cyl(V3(0.12, 0.80, 0.80), CF(0, 1.10, -0.05) * ANG(0, PI / 2, 0), p.light, METAL)
			c:eyes(0.22, 0.80, 0.30, 0.18)
			c:box(V3(0.40, 0.10, 0.06), CF(0, -0.12, 0.77), INK)
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.70 * s, -0.10, 0.10), V3(1.00 * s, 0.25, 0.30), 0.07, p.dark, nil, false)
				c:ball(V3(0.24, 0.24, 0.24), CF(1.00 * s, 0.25, 0.30), p.dark)
				c:box(V3(0.40, 0.20, 0.46), CF(0.36 * s, -1.04, 0.10), p.dark)
			end
			c:box(V3(0.26, 0.26, 0.26), CF(1.04, 0.46, 0.32) * ANG(0, 0.5, PI / 4), EMERALD, NEON)
		end,
	}

	-- A puddle of molten gold that got up and smiled: drips down its sides, a
	-- swirl on top, coins and a ruby stuck in it.
	S.df_t_ooze = {
		label = "Molten Gold Ooze",
		set = SET,
		tint = C3(255, 196, 30),
		head = CF(0, 1.30, -0.05),
		neck = CF(0, -0.30, 0.96),
		back = CF(0, 0.30, -0.92),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.90, 1.40, 1.80),
				eyeY = 0.12, eyeSpread = 0.40, eyeSize = V3(0.48, 0.56, 0.20),
				mouthY = -0.28,
				legs = false, tail = false,
			})
			c:box(V3(2.40, 0.18, 2.20), CF(0, -0.66, 0), p.dark)
			c:box(V3(1.00, 0.34, 0.90), CF(0, 0.90, -0.05), p.base)
			c:box(V3(0.50, 0.30, 0.46), CF(0.08, 1.18, -0.05) * ANG(0, 0.4, 0), p.light)
			c:box(V3(0.22, 0.50, 0.14), CF(-0.74, 0.42, 0.93), p.light)
			c:box(V3(0.14, 0.60, 0.24), CF(0.97, 0.30, 0.30), p.light)
			c:box(V3(0.14, 0.44, 0.22), CF(-0.97, 0.36, -0.40), p.light)
			c:cyl(V3(0.07, 0.42, 0.42), CF(0.55, 0.80, 0.30) * ANG(0.3, 0, 1.1), COIN, METAL)
			c:cyl(V3(0.07, 0.42, 0.42), CF(-0.60, 0.78, -0.30) * ANG(-0.2, 0, 1.9), COIN, METAL)
			c:cyl(V3(0.07, 0.42, 0.42), CF(1.05, -0.55, 0.60) * ANG(0, 0, 1.45), COIN, METAL)
			c:box(V3(0.26, 0.26, 0.26), CF(0.08, 1.42, -0.05) * ANG(0.5, 0.5, 0.5), RUBY, NEON)
		end,
	}

	-- A trilobite from the ash beds: a wide head shield with eyes up on little
	-- towers, cheek spines, a ribbed body, tiny legs and feelers.
	S.df_t_trilobite = {
		label = "Ash Trilobite",
		set = SET,
		tint = C3(96, 120, 200),
		scale = 1.15,
		head = CF(0, 0.50, 0.40),
		neck = CF(0, -0.40, 1.10),
		back = CF(0, 0.10, -0.80),
		build = function(c, p)
			c:box(V3(2.00, 0.60, 0.80), CF(0, -0.30, 0.66), p.base)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 0.56, 0.34), CF(0.42 * s, 0.20, 0.80), p.light)
				c:cone(V3(0.22, 0.60, 0.22), CF(1.00 * s, -0.44, 0.10) * ANG(-PI / 2, 0, 0), p.light)
				for _, z in ipairs({ 0.36, 0.0, -0.40 }) do
					c:box(V3(0.30, 0.12, 0.14), CF(0.98 * s, -0.62, z) * ANG(0, 0, -0.5 * s), p.deep)
				end
				c:rod(V3(0.26 * s, -0.20, 1.04), V3(0.62 * s, 0.30, 1.30), 0.04, p.dark, nil, false)
			end
			c:eyes(0.30, 1.02, 0.42, 0.16)
			c:box(V3(0.44, 0.08, 0.06), CF(0, -0.38, 1.07), INK)
			for i = 0, 3 do
				c:box(V3(1.84 - i * 0.16, 0.44, 0.36), CF(0, -0.38, 0.12 - i * 0.36), i % 2 == 0 and p.dark or p.base)
			end
			c:box(V3(0.60, 0.58, 1.60), CF(0, -0.20, -0.40), p.light)
			c:box(V3(1.10, 0.36, 0.50), CF(0, -0.42, -1.36), p.base)
		end,
	}

	-- A drop of amber with a little fossil bug still asleep inside it, on two
	-- stubby feet.
	S.df_t_amber = {
		label = "Amber Drop",
		set = SET,
		tint = C3(255, 150, 20),
		head = CF(0, 1.36, 0),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.10, -0.80),
		build = function(c, p)
			c:box(V3(1.60, 1.30, 1.40), CF(0, -0.20, 0), p.base, GLASS).Transparency = 0.3
			c:box(V3(1.10, 0.50, 1.00), CF(0, 0.65, 0), p.base, GLASS).Transparency = 0.3
			c:cone(V3(0.56, 0.50, 0.56), CF(0, 1.15, 0), p.light, GLASS)
			-- The bug inside.
			c:box(V3(0.36, 0.20, 0.56), CF(0, 0.30, -0.10), p.deep)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.40, 0.04, 0.26), CF(0.26 * s, 0.36, -0.05) * ANG(0, 0.4 * s, 0), p.deep)
				c:box(V3(0.40, 0.22, 0.46), CF(0.40 * s, -0.95, 0.10), p.dark)
				c:box(V3(0.22, 0.40, 0.26), CF(0.88 * s, -0.30, 0.15) * ANG(0, 0, 0.3 * s), p.light, GLASS)
			end
			c:eyes(-0.05, 0.74, 0.36, 0.20)
			c:box(V3(0.30, 0.08, 0.06), CF(0, -0.42, 0.72), INK)
			c:box(V3(0.10, 0.40, 0.06), CF(-0.58, 0.18, 0.71) * ANG(0, 0, 0.3), WHITE, NEON)
			c:box(V3(0.08, 0.20, 0.06), CF(-0.42, 0.38, 0.71) * ANG(0, 0, 0.3), WHITE, NEON)
		end,
	}

	-- A pangolin in dragon-scale armour: overlapping plates over its back and
	-- sides, a plated brow, a long snout and a heavy scaled tail.
	S.df_t_pangolin = {
		label = "Scale Pangolin",
		set = SET,
		tint = C3(64, 176, 104),
		scale = 1.20,
		head = CF(0, 1.06, 0.20),
		neck = CF(0, -0.30, 1.06),
		back = CF(0, 0.70, -0.80),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.90, 1.50, 1.90),
				eyeY = 0.04, eyeSpread = 0.36, eyeSize = V3(0.40, 0.46, 0.20),
				snout = { w = 0.50, h = 0.34, d = 0.56, y = -0.34, color = p.pale, nose = p.deep },
				legSize = V3(0.44, 0.34, 0.46), legColor = p.pale,
				tail = false,
			})
			for i, z in ipairs({ 0.62, 0.20, -0.22, -0.64 }) do
				c:box(V3(2.10, 0.20, 0.62), CF(0, 0.88, z) * ANG(0.35, 0, 0), i % 2 == 1 and p.dark or p.base)
			end
			for _, s in ipairs(SIDES) do
				c:box(V3(0.20, 0.70, 1.60), CF(1.00 * s, 0.30, -0.10) * ANG(0, 0, 0.25 * s), p.dark)
			end
			c:box(V3(1.30, 0.18, 0.44), CF(0, 0.70, 0.86) * ANG(0.5, 0, 0), p.dark)
			c:box(V3(0.80, 0.50, 0.70), CF(0, -0.20, -1.20) * ANG(0.3, 0, 0), p.dark)
			c:box(V3(0.60, 0.40, 0.60), CF(0, -0.50, -1.62) * ANG(0.6, 0, 0), p.base)
			c:box(V3(0.40, 0.30, 0.40), CF(0, -0.74, -1.92), p.dark)
		end,
	}

	-- A kobold miner: a little upright lizard in a hard hat with a candle stuck
	-- on top, frilled ears and a pickaxe over its shoulder.
	S.df_t_kobold = {
		label = "Candle Kobold",
		set = SET,
		tint = C3(214, 96, 46),
		scale = 1.05,
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.10, 0.76),
		back = CF(0, 0.20, -0.76),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.40, 1.70, 1.30),
				eyeY = 0.30, eyeSpread = 0.32, eyeSize = V3(0.42, 0.50, 0.20),
				snout = { w = 0.56, h = 0.32, d = 0.40, y = -0.04, color = p.light, nose = p.deep },
				bib = { w = 0.80, h = 0.66, y = -0.46, color = p.pale },
				legSize = V3(0.44, 0.36, 0.52), legX = 0.38, legZ = { 0.10 }, legY = -0.92, legColor = p.dark,
				tailSize = V3(0.34, 0.32, 0.80), tailColor = p.dark,
			})
			c:box(V3(1.20, 0.30, 1.10), CF(0, 1.04, 0), p.deep, METAL)
			c:box(V3(1.30, 0.08, 0.30), CF(0, 0.92, 0.62), p.deep, METAL)
			local wax = C3(250, 240, 210)
			c:cyl(V3(0.44, 0.30, 0.30), CF(0, 1.40, 0) * ANG(0, 0, PI / 2), wax)
			c:box(V3(0.08, 0.18, 0.08), CF(0.12, 1.30, 0.14), wax)
			c:box(V3(0.16, 0.26, 0.16), CF(0, 1.74, 0), AMBER, NEON)
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.16, 0.40, 0.30), CF(0.78 * s, 0.60, 0) * ANG(0, 0, -0.9 * s), p.light)
				c:box(V3(0.26, 0.26, 0.26), CF(0.80 * s, -0.10 - 0.15 * (1 - s), 0.36), p.base)
			end
			c:rod(V3(0.80, -0.40, 0.40), V3(0.92, 0.70, 0.36), 0.06, TIMBER, WOOD, false)
			c:box(V3(0.86, 0.14, 0.14), CF(0.92, 0.72, 0.36) * ANG(0, 0, 0.15), STONE, METAL)
			c:light(AMBER, 1.0, 6)
		end,
	}

	-- A magpie that hoards like a dragon: white breast, folded wings with
	-- white flashes, a long tail, and a gold coin held in its beak.
	S.df_t_magpie = {
		label = "Hoard Magpie",
		set = SET,
		tint = C3(70, 60, 210),
		scale = 1.10,
		head = CF(0, 1.14, 0.10),
		neck = CF(0, -0.10, 0.84),
		back = CF(0, 0.30, -0.76),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V3(1.60, 1.70, 1.50),
				eyeY = 0.32, eyeSpread = 0.34, eyeSize = V3(0.40, 0.48, 0.20),
				mouth = false,
				bib = { w = 0.96, h = 0.84, y = -0.40, color = p.pale },
				legSize = V3(0.16, 0.40, 0.24), legX = 0.30, legZ = { 0.05 }, legY = -0.92, legColor = INK,
				tail = false,
			})
			c:cone(V3(0.28, 0.46, 0.24), CF(0, 0.05, 0.98) * ANG(PI / 2, 0, 0), p.deep)
			c:cyl(V3(0.08, 0.42, 0.42), CF(0, -0.10, 1.20) * ANG(0, PI / 2, 0), COIN, METAL)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.16, 0.90, 1.10), CF(0.86 * s, 0.10, -0.20) * ANG(0.25, 0, 0), p.dark)
				c:box(V3(0.18, 0.30, 0.50), CF(0.88 * s, 0.25, 0.05) * ANG(0.25, 0, 0), p.pale)
			end
			c:box(V3(0.40, 0.12, 1.00), CF(0, 0.05, -1.15) * ANG(0.55, 0, 0), p.dark)
			c:box(V3(0.34, 0.10, 0.40), CF(0, 0.41, -1.75) * ANG(0.55, 0, 0), p.deep)
			c:cone(V3(0.24, 0.36, 0.30), CF(0, 1.04, 0.10) * ANG(-0.4, 0, 0), p.deep)
		end,
	}

	-- A leafy sea-drake: an upright little seahorse-dragon with a long tube
	-- snout, a curled tail and leafy fronds drifting off it.
	S.df_t_seadrake = {
		label = "Leafy Seadrake",
		set = SET,
		tint = C3(170, 220, 50),
		scale = 1.05,
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.10, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.10, 1.50, 1.20),
				eyeY = 0.30, eyeSpread = 0.28, eyeSize = V3(0.36, 0.44, 0.18),
				snout = { w = 0.26, h = 0.24, d = 0.80, y = 0.0, color = p.light, nose = p.deep },
				bib = { w = 0.70, h = 0.70, y = -0.35, color = p.pale },
				legs = false, tail = false,
			})
			c:box(V3(0.70, 0.60, 0.70), CF(0, -0.95, -0.30), p.base)
			c:box(V3(0.50, 0.46, 0.50), CF(0, -1.22, 0.10), p.dark)
			c:box(V3(0.34, 0.34, 0.34), CF(0, -1.04, 0.42), p.base)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.56, 0.06, 0.42), CF(0.78 * s, 0.42, -0.10) * ANG(0, 0, 0.50 * s), p.light)
				c:box(V3(0.56, 0.06, 0.42), CF(0.72 * s, -0.46, -0.20) * ANG(0, 0, -0.50 * s), p.light)
				c:box(V3(0.08, 0.50, 0.30), CF(0.20 * s, 1.04, -0.05) * ANG(0, 0, -0.40 * s), p.glow)
			end
			c:box(V3(0.08, 0.36, 0.60), CF(0, 0.30, -0.86) * ANG(0.5, 0, 0), p.light)
			c:box(V3(0.08, 0.34, 0.50), CF(0, -0.96, -0.80) * ANG(-0.6, 0, 0), p.light)
			c:box(V3(0.06, 0.30, 0.50), CF(0, 0.92, -0.30), p.pale).Transparency = 0.3
		end,
	}

	-- A whiskered carp leaping the dragon gate: little horn buds already
	-- growing, a round "O" mouth, a tall fin and a split tail.
	S.df_t_carp = {
		label = "Whisker Carp",
		set = SET,
		tint = C3(255, 136, 40),
		scale = 1.10,
		head = CF(0, 1.00, 0.30),
		neck = CF(0, -0.40, 1.00),
		back = CF(0, 0.30, -1.10),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.40, 1.50, 1.90),
				eyeY = 0.24, eyeSpread = 0.38, eyeSize = V3(0.42, 0.48, 0.20),
				mouthY = -0.26, mouthSize = V3(0.36, 0.28, 0.12), mouthColor = p.deep,
				bib = { w = 0.90, h = 0.60, y = -0.46, color = p.pale },
				legs = false, tail = false,
			})
			c:box(V3(0.10, 0.50, 1.20), CF(0, 0.98, -0.15) * ANG(0.2, 0, 0), p.light)
			c:box(V3(0.80, 0.80, 0.50), CF(0, 0.10, -1.15), p.base)
			c:box(V3(0.10, 0.80, 0.50), CF(0, 0.45, -1.55) * ANG(-0.6, 0, 0), p.light)
			c:box(V3(0.10, 0.80, 0.50), CF(0, -0.25, -1.55) * ANG(0.6, 0, 0), p.light)
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.20 * s, -0.30, 1.00), V3(0.62 * s, -0.62, 1.20), 0.04, p.pale, nil, false)
				c:box(V3(0.50, 0.08, 0.36), CF(0.82 * s, -0.30, 0.40) * ANG(0, 0, -0.4 * s), p.light)
				c:box(V3(0.06, 0.30, 0.30), CF(0.71 * s, 0.30, -0.10), p.light)
				c:box(V3(0.06, 0.26, 0.26), CF(0.71 * s, -0.10, -0.50), p.light)
				c:cone(V3(0.16, 0.26, 0.16), CF(0.30 * s, 0.94, 0.70), p.glow)
			end
		end,
	}

	-- A hermit crab that moved into an old dragon skull: the skull's snout
	-- points back, its horns curl forward, and the crab peeks out the front.
	S.df_t_hermit = {
		label = "Skull Hermit",
		set = SET,
		tint = C3(250, 100, 80),
		scale = 1.05,
		head = CF(0, 1.00, -0.30),
		neck = CF(0, -0.50, 0.96),
		back = CF(0, 0.60, -1.30),
		build = function(c, p)
			c:box(V3(1.70, 1.20, 1.40), CF(0, 0.30, -0.30), p.pale)
			c:box(V3(1.00, 0.70, 0.80), CF(0, 0.15, -1.30), p.pale)
			c:box(V3(1.04, 0.10, 0.84), CF(0, -0.02, -1.30), INK)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.06, 0.34, 0.40), CF(0.86 * s, 0.45, -0.55), INK)
				c:cone(V3(0.24, 0.70, 0.24), CF(0.55 * s, 1.15, -0.10) * ANG(0.4, 0, -0.3 * s), p.light)
				c:rod(V3(0.25 * s, -0.15, 0.80), V3(0.32 * s, 0.35, 0.92), 0.05, p.base, nil, false)
				c:eye(V3(0.32 * s, 0.42, 0.94), 0.15)
				for _, z in ipairs({ 0.45, 0.10 }) do
					c:box(V3(0.46, 0.14, 0.16), CF(0.80 * s, -0.72, z) * ANG(0, 0, -0.4 * s), p.base)
				end
			end
			c:box(V3(1.20, 0.66, 0.60), CF(0, -0.45, 0.62), p.base)
			c:box(V3(0.50, 0.40, 0.50), CF(-0.60, -0.55, 1.05), p.dark)
			c:box(V3(0.44, 0.16, 0.42), CF(-0.60, -0.26, 1.10) * ANG(-0.35, 0, 0), p.dark)
			c:box(V3(0.34, 0.30, 0.38), CF(0.58, -0.60, 1.00), p.dark)
			c:box(V3(0.24, 0.08, 0.06), CF(0, -0.40, 0.93), INK)
		end,
	}

	-- A walking goblet from the hoard: a jewelled cup brimming with gold, a
	-- stem and foot, a smiling face and two little arms.
	S.df_t_goblet = {
		label = "Goblet Imp",
		set = SET,
		tint = C3(30, 170, 170),
		head = CF(0, 1.50, 0),
		neck = CF(0, 0.10, 0.90),
		back = CF(0, 0.40, -0.90),
		build = function(c, p)
			c:box(V3(1.70, 1.00, 1.70), CF(0, 0.40, 0), p.base, METAL)
			c:box(V3(1.84, 0.14, 1.84), CF(0, 0.94, 0), p.light, METAL)
			c:box(V3(1.10, 0.30, 1.10), CF(0, -0.22, 0), p.dark, METAL)
			c:cyl(V3(0.50, 0.34, 0.34), CF(0, -0.58, 0) * ANG(0, 0, PI / 2), p.dark, METAL)
			c:box(V3(1.20, 0.18, 1.20), CF(0, -0.88, 0), p.base, METAL)
			c:box(V3(1.50, 0.26, 1.50), CF(0, 1.08, 0), GOLD, METAL)
			c:cyl(V3(0.07, 0.40, 0.40), CF(0.35, 1.26, 0.25) * ANG(0.2, 0, 1.2), COIN, METAL)
			c:cyl(V3(0.07, 0.40, 0.40), CF(-0.40, 1.24, -0.20) * ANG(-0.3, 0, 1.9), COIN, METAL)
			c:box(V3(0.28, 0.28, 0.28), CF(0, 1.32, -0.25) * ANG(0.6, 0.4, 0.6), EMERALD, NEON)
			c:eyes(0.50, 0.87, 0.36, 0.18)
			c:box(V3(0.46, 0.10, 0.06), CF(0, 0.12, 0.87), INK)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.08, 0.24, 0.24), CF(0.86 * s, 0.45, 0) * ANG(PI / 4, 0, 0), s < 0 and RUBY or SAPPHIRE, NEON)
				c:rod(V3(0.86 * s, 0.30, 0.10), V3(1.10 * s, 0.00, 0.30), 0.07, p.dark, METAL, false)
				c:ball(V3(0.22, 0.22, 0.22), CF(1.10 * s, 0.00, 0.30), p.dark, METAL)
			end
		end,
	}

	-- An obsidian scorpion: low and glossy, big pincers, six little legs and
	-- its tail curled right over its back to a soft glowing tip.
	S.df_t_scorpion = {
		label = "Obsidian Scorpion",
		set = SET,
		tint = C3(80, 60, 120),
		scale = 1.10,
		head = CF(0, 0.60, 0.30),
		neck = CF(0, -0.20, 0.96),
		back = CF(0, 0.70, -0.40),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.60, 0.90, 1.60),
				eyeY = 0.12, eyeSpread = 0.30, eyeSize = V3(0.36, 0.42, 0.18),
				mouthY = -0.18, mouthSize = V3(0.26, 0.10, 0.10),
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.35, -0.05, -0.45 }) do
					c:rod(V3(0.78 * s, -0.10, z), V3(1.12 * s, -0.62, z + 0.05), 0.06, p.dark, nil, false)
				end
				c:rod(V3(0.55 * s, -0.05, 0.72), V3(0.80 * s, 0.00, 1.15), 0.08, p.base, nil, false)
				c:box(V3(0.42, 0.32, 0.46), CF(0.82 * s, 0.02, 1.36), p.base)
				c:box(V3(0.14, 0.12, 0.36), CF(0.72 * s, 0.12, 1.66) * ANG(0, 0.3 * s, 0), p.light)
			end
			c:box(V3(0.46, 0.44, 0.46), CF(0, 0.36, -0.96) * ANG(-0.4, 0, 0), p.base)
			c:box(V3(0.42, 0.42, 0.42), CF(0, 0.84, -1.16) * ANG(0.3, 0, 0), p.dark)
			c:box(V3(0.38, 0.38, 0.38), CF(0, 1.30, -0.98) * ANG(0.9, 0, 0), p.base)
			c:box(V3(0.34, 0.34, 0.34), CF(0, 1.52, -0.58) * ANG(1.5, 0, 0), p.dark)
			c:cone(V3(0.26, 0.40, 0.26), CF(0, 1.42, -0.22) * ANG(2.3, 0, 0), p.glow, NEON)
		end,
	}

	-- A paper lantern with a dragon's face: a glowing window, corner posts,
	-- horns on the lid, long whiskers and a tassel hanging below.
	S.df_t_lantern = {
		label = "Wyrm Lantern",
		set = SET,
		tint = C3(230, 36, 56),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.10, -0.80),
		build = function(c, p)
			c:box(V3(1.50, 1.30, 1.50), CF(0, 0.05, 0), p.base)
			for _, sx in ipairs(SIDES) do
				for _, sz in ipairs(SIDES) do
					c:box(V3(0.14, 1.34, 0.14), CF(0.75 * sx, 0.05, 0.75 * sz), p.deep)
				end
			end
			c:box(V3(1.70, 0.20, 1.70), CF(0, 0.80, 0), p.deep)
			c:box(V3(1.70, 0.20, 1.70), CF(0, -0.70, 0), p.deep)
			c:box(V3(1.04, 0.84, 0.06), CF(0, 0.05, 0.76), p.glow, NEON)
			c:eyes(0.20, 0.82, 0.32, 0.18)
			c:box(V3(0.40, 0.10, 0.06), CF(0, -0.22, 0.80), INK)
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.40 * s, -0.10, 0.80), V3(1.05 * s, -0.30, 0.90), 0.04, p.light, nil, false)
				c:cone(V3(0.20, 0.40, 0.20), CF(0.45 * s, 1.10, 0.10) * ANG(0, 0, -0.3 * s), p.light)
			end
			c:rod(V3(0, -0.80, 0), V3(0, -1.10, 0), 0.04, GOLD, nil, false)
			c:box(V3(0.26, 0.36, 0.26), CF(0, -1.25, 0), p.light)
			c:cyl(V3(0.10, 0.46, 0.46), CF(0, 1.10, -0.15) * ANG(0, PI / 2, 0), GOLD, METAL)
			c:light(p.glow, 1.2, 8)
		end,
	}

	-- A snapdragon in a pot whose bloom is a little dragon's head: petal
	-- crest, a jutting lower lip with two tiny fangs, and leaves on the stem.
	S.df_t_snapdragon = {
		label = "Snapdragon Sprout",
		set = SET,
		tint = C3(250, 60, 150),
		head = CF(0, 1.70, 0),
		neck = CF(0, 0.30, 0.80),
		back = CF(0, 0.80, -0.60),
		build = function(c, p)
			local pot = C3(196, 110, 70)
			c:box(V3(1.20, 0.70, 1.20), CF(0, -0.70, 0), pot)
			c:box(V3(1.40, 0.20, 1.40), CF(0, -0.30, 0), pot:Lerp(INK, 0.25))
			c:box(V3(0.22, 0.70, 0.22), CF(0, 0.05, 0), LEAF)
			c:box(V3(1.30, 1.00, 1.10), CF(0, 0.90, 0.05), p.base)
			c:box(V3(0.96, 0.24, 0.40), CF(0, 0.50, 0.72), p.light)
			for _, x in ipairs({ -0.40, 0, 0.40 }) do
				c:box(V3(0.36, 0.50, 0.20), CF(x, 1.55, -0.05) * ANG(0, 0, -x * 0.8), p.light)
			end
			for _, s in ipairs(SIDES) do
				c:box(V3(0.60, 0.08, 0.30), CF(0.36 * s, 0.0, 0.05) * ANG(0, 0, 0.5 * s), LEAF)
				c:box(V3(0.20, 0.50, 0.40), CF(0.72 * s, 1.00, 0.0) * ANG(0, 0, -0.5 * s), p.light)
				c:cone(V3(0.12, 0.16, 0.12), CF(0.25 * s, 0.70, 0.86), WHITE)
			end
			c:eyes(1.02, 0.66, 0.30, 0.17)
		end,
	}

	--------------------------------------------------------------------------
	-- LEGENDARY: more ornate.
	--------------------------------------------------------------------------

	-- A feathered serpent rising out of its own coils: a plumed ruff fanned
	-- behind its face, feathered wings and a glowing tuft on its tail tip.
	S.df_t_coatl = {
		label = "Plumed Coatl",
		set = SET,
		tint = C3(0, 210, 200),
		scale = 1.20,
		head = CF(0, 1.12, 0.10),
		neck = CF(0, 0.10, 0.62),
		back = CF(0, 0.50, -0.45),
		build = function(c, p)
			-- The coils on the ground, the tail tip curling round the front.
			c:box(V3(0.46, 0.50, 1.50), CF(-0.75, -0.75, -0.05), p.base)
			c:box(V3(0.46, 0.50, 1.50), CF(0.75, -0.75, -0.05), p.base)
			c:box(V3(1.50, 0.50, 0.46), CF(0, -0.75, -0.65), p.dark)
			c:box(V3(0.80, 0.44, 0.42), CF(0.35, -0.78, 0.62), p.dark)
			c:box(V3(0.44, 0.32, 0.34), CF(-0.20, -0.84, 0.70), p.base)
			c:box(V3(0.30, 0.30, 0.20), CF(-0.50, -0.84, 0.74) * ANG(0, 0, PI / 4), p.glow, NEON)
			c:box(V3(1.30, 0.40, 1.20), CF(0, -0.35, -0.05), p.dark)
			-- The rising body, its belly, snout and a gold collar.
			c:box(V3(1.10, 1.30, 0.95), CF(0, 0.45, 0.10), p.base)
			c:box(V3(1.16, 0.10, 1.01), CF(0, -0.17, 0.10), GOLD, METAL)
			c:box(V3(0.66, 0.40, 0.06), CF(0, 0.10, 0.60), p.pale)
			c:box(V3(0.60, 0.30, 0.26), CF(0, 0.42, 0.68), p.light)
			c:box(V3(0.30, 0.06, 0.04), CF(0, 0.32, 0.82), INK)
			c:eyes(0.80, 0.60, 0.26, 0.15)
			-- The plumed ruff.
			for i, a in ipairs({ -1.0, -0.5, 0, 0.5, 1.0 }) do
				local lit = i % 2 == 1
				c:box(V3(0.26, 0.72, 0.08), CF(0.66 * math.sin(a), 0.80 + 0.66 * math.cos(a), -0.32) * ANG(0, 0, -a), lit and p.glow or p.light, lit and NEON or nil)
			end
			for _, s in ipairs(SIDES) do
				c:box(V3(1.00, 0.08, 0.56), CF(0.95 * s, 0.75, -0.20) * ANG(0, 0, 0.45 * s), p.light)
				c:box(V3(0.80, 0.08, 0.42), CF(0.88 * s, 0.60, -0.05) * ANG(0, 0, 0.25 * s), p.pale)
				c:box(V3(0.30, 0.10, 0.34), CF(1.40 * s, 0.97, -0.20) * ANG(0, 0, 0.45 * s), p.glow, NEON)
			end
		end,
	}

	-- A Viking longship that is the dragon: eyes painted on its bow, a carved
	-- dragon prow, a curled stern, a striped sail, shields and oars.
	S.df_t_longship = {
		label = "Drakkar Longship",
		set = SET,
		tint = C3(50, 100, 220),
		scale = 1.15,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.30, 1.30),
		back = CF(0, 0.20, -1.00),
		build = function(c, p)
			c:box(V3(1.40, 0.70, 1.80), CF(0, -0.45, 0), p.base)
			c:box(V3(1.46, 0.12, 1.86), CF(0, -0.12, 0), p.light)
			c:box(V3(1.00, 0.66, 0.40), CF(0, -0.42, 1.08), p.base)
			c:eyes(-0.28, 1.30, 0.26, 0.14)
			c:box(V3(0.40, 0.06, 0.04), CF(0, -0.58, 1.29), INK)
			-- The carved prow and the curled stern.
			c:box(V3(0.36, 0.90, 0.36), CF(0, 0.25, 1.12) * ANG(0.25, 0, 0), p.dark)
			c:box(V3(0.40, 0.34, 0.56), CF(0, 0.82, 1.36), p.dark)
			c:box(V3(0.34, 0.90, 0.34), CF(0, 0.25, -1.05) * ANG(-0.25, 0, 0), p.dark)
			c:cone(V3(0.30, 0.40, 0.30), CF(0, 0.86, -1.17), p.light)
			-- Mast, yard and the striped sail.
			c:rod(V3(0, -0.10, 0), V3(0, 1.30, 0), 0.06, TIMBER, WOOD, false)
			c:box(V3(1.30, 0.90, 0.06), CF(0, 0.78, 0.04), p.pale)
			for _, x in ipairs({ -0.40, 0.40 }) do
				c:box(V3(0.30, 0.90, 0.08), CF(x, 0.78, 0.04), p.deep)
			end
			c:box(V3(1.40, 0.08, 0.08), CF(0, 1.24, 0.04), TIMBER, WOOD)
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.12, 0.30, 0.12), CF(0.12 * s, 1.05, 1.24) * ANG(-0.4, 0, -0.2 * s), p.light)
				c:box(V3(0.06, 0.08, 0.08), CF(0.20 * s, 0.88, 1.46), p.glow, NEON)
				for i, z in ipairs({ 0.55, 0, -0.55 }) do
					local gold = i % 2 == 0
					c:cyl(V3(0.08, 0.38, 0.38), CF(0.74 * s, -0.30, z), gold and GOLD or p.light, gold and METAL or nil)
				end
				for _, z in ipairs({ 0.28, -0.28 }) do
					c:rod(V3(0.70 * s, -0.40, z), V3(1.05 * s, -0.95, z + 0.10), 0.04, TIMBER, WOOD, false)
				end
			end
		end,
	}

	-- A cockatrice chick: rooster comb and wattle, little bat wings, scaly
	-- chicken feet and a dragon's tail ending in a glowing spade.
	S.df_t_cockatrice = {
		label = "Ember Cockatrice",
		set = SET,
		tint = C3(255, 60, 50),
		scale = 1.10,
		head = CF(0, 1.30, 0.10),
		neck = CF(0, -0.20, 0.86),
		back = CF(0, 0.30, -0.76),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V3(1.50, 1.60, 1.50),
				eyeY = 0.28, eyeSpread = 0.32, eyeSize = V3(0.38, 0.46, 0.20),
				mouth = false,
				bib = { w = 0.86, h = 0.70, y = -0.40, color = p.pale },
				legSize = V3(0.18, 0.44, 0.22), legX = 0.30, legZ = { 0.05 }, legY = -0.95, legColor = AMBER,
				tail = false,
			})
			c:cone(V3(0.30, 0.42, 0.26), CF(0, 0.08, 0.95) * ANG(PI / 2, 0, 0), AMBER)
			c:box(V3(0.16, 0.30, 0.10), CF(0, -0.18, 0.90), RUBY)
			for i, z in ipairs({ 0.30, 0.02, -0.26 }) do
				c:box(V3(0.14, 0.42 - i * 0.06, 0.28), CF(0, 1.07 - i * 0.03, z), p.glow, NEON)
			end
			for _, s in ipairs(SIDES) do
				c:box(V3(0.12, 0.70, 0.80), CF(0.80 * s, 0.20, -0.15) * ANG(0.20, 0, 0.15 * s), p.dark)
				c:box(V3(0.10, 0.55, 0.60), CF(0.90 * s, 0.55, -0.40) * ANG(0.30, 0, -0.45 * s), p.light)
				c:box(V3(0.40, 0.06, 0.34), CF(0.30 * s, -1.18, 0.16), AMBER)
			end
			-- A dragon's tail instead of tail feathers.
			c:box(V3(0.40, 0.40, 0.70), CF(0, -0.10, -1.00) * ANG(0.5, 0, 0), p.base)
			c:box(V3(0.32, 0.32, 0.60), CF(0, 0.30, -1.32) * ANG(1.0, 0, 0), p.dark)
			c:cone(V3(0.20, 0.26, 0.20), CF(0, 0.14, -1.06), p.light)
			c:cone(V3(0.38, 0.42, 0.10), CF(0, 0.74, -1.48), p.glow, NEON)
		end,
	}

	-- A pixiu, the dragon's son who eats gold and never lets it go: a chubby
	-- winged beast with one horn and a curly mane, an old square-holed coin
	-- in its mouth, sat on a slab of treasure.
	S.df_t_pixiu = {
		label = "Coinmunch Pixiu",
		set = SET,
		tint = C3(225, 170, 60),
		scale = 1.05,
		head = CF(0, 1.10, 0.20),
		neck = CF(0, -0.40, 0.96),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.70, 1.60, 1.60),
				eyeY = 0.26, eyeSpread = 0.38, eyeSize = V3(0.42, 0.50, 0.20),
				snout = { w = 0.70, h = 0.40, d = 0.30, y = -0.14, color = p.light, nose = p.deep },
				legSize = V3(0.44, 0.36, 0.50), legX = 0.52, legZ = { 0.42, -0.30 }, legColor = p.dark,
				tail = false,
			})
			c:cyl(V3(0.08, 0.46, 0.46), CF(0, -0.40, 1.04) * ANG(0, PI / 2, 0), COIN, METAL)
			c:box(V3(0.10, 0.10, 0.10), CF(0, -0.40, 1.07), INK)
			c:cone(V3(0.18, 0.60, 0.18), CF(0, 1.10, 0.30) * ANG(-0.3, 0, 0), p.pale)
			for _, v in ipairs({ { -0.36, 0.92, -0.20 }, { 0.36, 0.92, -0.20 }, { 0, 0.96, -0.50 } }) do
				c:box(V3(0.36, 0.28, 0.30), CF(v[1], v[2], v[3]) * ANG(0, 0, PI / 4), p.dark)
			end
			for _, s in ipairs(SIDES) do
				c:box(V3(0.10, 0.50, 0.70), CF(0.90 * s, 0.40, -0.20) * ANG(0.2, 0, -0.4 * s), p.light)
				c:box(V3(0.08, 0.22, 0.30), CF(1.02 * s, 0.66, -0.30) * ANG(0.2, 0, -0.4 * s), p.glow, NEON)
				c:cyl(V3(0.06, 0.36, 0.36), CF(0.80 * s, -0.99, 0.80) * ANG(0, 0, PI / 2), COIN, METAL)
			end
			c:ball(V3(0.46, 0.46, 0.46), CF(0, 0.10, -0.92), p.dark)
			c:cone(V3(0.24, 0.36, 0.24), CF(0, 0.42, -0.98), p.glow, NEON)
			c:box(V3(1.80, 0.20, 1.50), CF(0, -1.12, 0), GOLD, METAL)
		end,
	}

	-- A lindworm from the crags: a wingless dragon with only two strong front
	-- legs, its long body curling round beside it to a spiked tail, great
	-- horns, a spiky mane and a shaggy beard.
	S.df_t_lindworm = {
		label = "Crag Lindworm",
		set = SET,
		tint = C3(40, 180, 80),
		scale = 1.05,
		head = CF(0, 0.92, 0.20),
		neck = CF(0, -0.30, 0.90),
		back = CF(0.40, 0.10, -0.80),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.50, 1.30, 1.40),
				eyeY = 0.20, eyeSpread = 0.36, eyeSize = V3(0.40, 0.46, 0.20),
				snout = { w = 0.70, h = 0.40, d = 0.40, y = -0.16, color = p.light, nose = p.deep },
				brow = p.dark,
				legSize = V3(0.46, 0.50, 0.50), legX = 0.62, legZ = { 0.30 }, legY = -0.70, legColor = p.dark,
				tail = false,
			})
			c:box(V3(0.90, 0.80, 0.80), CF(0.35, -0.40, -0.80), p.base)
			c:box(V3(0.70, 0.66, 0.70), CF(0.85, -0.50, -0.95), p.dark)
			c:box(V3(0.60, 0.54, 0.66), CF(1.15, -0.60, -0.50), p.base)
			c:cone(V3(0.40, 0.50, 0.30), CF(1.22, -0.62, -0.05) * ANG(PI / 2, 0, 0), p.light)
			for _, v in ipairs({ { 0.35, 0.06, -0.80 }, { 0.85, -0.10, -0.95 }, { 1.15, -0.26, -0.50 } }) do
				c:cone(V3(0.24, 0.30, 0.24), CF(v[1], v[2], v[3]), p.light)
			end
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.22, 0.60, 0.22), CF(0.42 * s, 0.98, 0.10) * ANG(-0.5, 0, -0.3 * s), p.pale)
				c:cone(V3(0.26, 0.40, 0.26), CF(0.40 * s, 0.82, -0.40) * ANG(0, 0, -0.5 * s), p.dark)
				for _, dx in ipairs({ -0.12, 0.12 }) do
					c:box(V3(0.12, 0.10, 0.16), CF(0.62 * s + dx, -0.90, 0.60), p.pale)
				end
			end
			c:cone(V3(0.30, 0.44, 0.30), CF(0, 0.86, -0.30), p.dark)
			c:box(V3(0.44, 0.34, 0.20), CF(0, -0.56, 0.82), p.pale)
			c:box(V3(0.26, 0.06, 0.26), CF(0.10, 0.02, -1.00), LEAF)
		end,
	}

	-- An amphisbaena: a little winged serpent with a head at BOTH ends,
	-- curled into a U so the twins sit side by side, one wearing a crown and
	-- one a sapphire.
	S.df_t_amphis = {
		label = "Twin Amphisbaena",
		set = SET,
		tint = C3(255, 150, 190),
		scale = 1.10,
		head = CF(0.60, 0.70, 0.75),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, -0.10, -0.70),
		build = function(c, p)
			c:box(V3(1.80, 0.60, 0.60), CF(0, -0.55, -0.60), p.base)
			for _, s in ipairs(SIDES) do
				local x = 0.60 * s
				c:box(V3(0.60, 0.60, 1.00), CF(x, -0.55, 0.05), p.dark)
				c:box(V3(0.50, 0.60, 0.50), CF(x, -0.20, 0.60), p.base)
				c:box(V3(0.80, 0.80, 0.70), CF(x, 0.25, 0.75), p.base)
				c:eye(V3(x - 0.17, 0.34, 1.12), 0.12)
				c:eye(V3(x + 0.17, 0.34, 1.12), 0.12)
				c:box(V3(0.44, 0.24, 0.20), CF(x, 0.10, 1.18), p.light)
				c:box(V3(0.20, 0.04, 0.04), CF(x, 0.04, 1.29), INK)
				c:cone(V3(0.12, 0.26, 0.12), CF(x - 0.22, 0.72, 0.70), p.pale)
				c:cone(V3(0.12, 0.26, 0.12), CF(x + 0.22, 0.72, 0.70), p.pale)
				c:box(V3(0.10, 0.80, 0.90), CF(0.85 * s, 0.20, -0.60) * ANG(0, 0.3 * s, -0.45 * s), p.light)
				c:box(V3(0.08, 0.30, 0.40), CF(1.05 * s, 0.55, -0.70) * ANG(0, 0.3 * s, -0.45 * s), p.glow, NEON)
			end
			c:box(V3(0.36, 0.18, 0.36), CF(-0.60, 0.74, 0.75), GOLD, METAL)
			c:box(V3(0.18, 0.18, 0.18), CF(0.60, 0.74, 0.75) * ANG(PI / 4, 0, PI / 4), SAPPHIRE, NEON)
			for _, x in ipairs({ -0.50, 0, 0.50 }) do
				c:cone(V3(0.20, 0.26, 0.20), CF(x, -0.15, -0.60), p.light)
			end
		end,
	}

	-- One of the gold-digging ants of old legend: a big head, a little waist
	-- and a striped round tail, elbowed feelers tipped with light, and a lump
	-- of hoard gold carried proudly over its back.
	S.df_t_ant = {
		label = "Golddust Ant",
		set = SET,
		tint = C3(170, 40, 140),
		scale = 1.10,
		head = CF(0, 0.42, 0.75),
		neck = CF(0, -0.50, 1.15),
		back = CF(0, 0.50, -0.75),
		build = function(c, p)
			c:box(V3(1.00, 0.90, 0.80), CF(0, -0.05, 0.75), p.base)
			c:box(V3(0.60, 0.50, 0.60), CF(0, -0.10, 0.10), p.dark)
			c:box(V3(1.10, 0.95, 1.10), CF(0, 0.05, -0.75), p.base)
			c:box(V3(1.14, 0.14, 1.14), CF(0, 0.20, -0.75), p.light)
			c:box(V3(1.14, 0.14, 1.14), CF(0, -0.15, -0.75), p.light)
			c:eyes(0.05, 1.17, 0.24, 0.16)
			c:box(V3(0.30, 0.06, 0.04), CF(0, -0.28, 1.16), INK)
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.25 * s, 0.38, 0.95), V3(0.45 * s, 0.85, 1.05), 0.04, p.deep, nil, false)
				c:rod(V3(0.45 * s, 0.85, 1.05), V3(0.62 * s, 0.95, 1.40), 0.035, p.deep, nil, false)
				c:ball(V3(0.14, 0.14, 0.14), CF(0.62 * s, 0.95, 1.40), p.glow, NEON)
				for _, v in ipairs({ { 0.85, 0.55 }, { 0.95, 0.10 }, { 0.85, -0.40 } }) do
					c:rod(V3(0.28 * s, -0.20, v[2] * 0.4), V3(v[1] * s, -0.85, v[2]), 0.05, p.deep, nil, false)
				end
			end
			c:box(V3(0.80, 0.60, 0.70), CF(0, 0.85, -0.20) * ANG(0.3, 0.5, 0.2), GOLD, METAL)
			c:box(V3(0.30, 0.26, 0.30), CF(0.40, 1.25, -0.05) * ANG(0.5, 0.3, 0.6), GOLD, METAL)
			c:box(V3(0.18, 0.18, 0.18), CF(-0.35, 1.20, 0.10) * ANG(0.6, 0.6, 0), RUBY, NEON)
		end,
	}

	-- A curled war horn carved from a dragon's own horn, which sings by
	-- itself: its bell is a singing mouth, the tube curls up to a gold
	-- mouthpiece, with little wings, gold bands and notes floating out.
	S.df_t_horn = {
		label = "Wyrmhorn Bugle",
		set = SET,
		tint = C3(240, 220, 170),
		scale = 1.10,
		head = CF(0, 0.55, 0.60),
		neck = CF(0, -0.60, 1.00),
		back = CF(0, 0.60, -0.60),
		build = function(c, p)
			c:box(V3(1.30, 1.20, 0.50), CF(0, -0.10, 0.70), p.base)
			c:box(V3(1.40, 1.30, 0.10), CF(0, -0.10, 0.97), p.light)
			c:box(V3(0.80, 0.50, 0.04), CF(0, -0.32, 1.03), INK)
			c:eyes(0.26, 1.04, 0.30, 0.15)
			c:box(V3(1.00, 0.95, 0.50), CF(0, -0.10, 0.25), p.dark)
			c:box(V3(0.80, 0.75, 0.50), CF(0, 0.05, -0.20) * ANG(0.3, 0, 0), p.base)
			c:box(V3(0.60, 0.55, 0.45), CF(0, 0.40, -0.55) * ANG(0.7, 0, 0), p.dark)
			c:box(V3(0.46, 0.42, 0.40), CF(0, 0.82, -0.70) * ANG(1.2, 0, 0), p.base)
			c:box(V3(0.30, 0.30, 0.30), CF(0, 1.14, -0.62), GOLD, METAL)
			c:box(V3(0.84, 0.08, 0.54), CF(0, 0.05, -0.20) * ANG(0.3, 0, 0), GOLD, METAL)
			c:box(V3(0.50, 0.08, 0.44), CF(0, 0.82, -0.70) * ANG(1.2, 0, 0), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.10, 0.60, 0.70), CF(0.65 * s, 0.30, 0.10) * ANG(0, 0, -0.5 * s), p.light)
				c:box(V3(0.36, 0.22, 0.50), CF(0.40 * s, -0.80, 0.30), p.deep)
				c:box(V3(0.04, 0.24, 0.24), CF(0.66 * s, -0.20, 0.70) * ANG(PI / 4, 0, 0), p.pale)
			end
			c:box(V3(0.14, 0.14, 0.04), CF(0.55, 0.75, 1.20) * ANG(0, 0, PI / 4), p.glow, NEON)
			c:box(V3(0.10, 0.10, 0.04), CF(0.80, 1.00, 1.35) * ANG(0, 0, PI / 4), p.glow, NEON)
		end,
	}

	-- A temple gong that thunders by itself: its bronze disc is its face,
	-- hung from a frame whose beam ends in two dragon heads, with tassels, a
	-- pearl and its own little mallet.
	S.df_t_gong = {
		label = "Wyrmframe Gong",
		set = SET,
		tint = C3(190, 120, 60),
		scale = 1.10,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.60, 0.40),
		back = CF(0, 0.20, -0.30),
		build = function(c, p)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.24, 1.80, 0.24), CF(1.00 * s, -0.10, 0), p.dark)
				c:box(V3(0.60, 0.20, 0.70), CF(1.00 * s, -1.05, 0), p.deep)
				c:box(V3(0.36, 0.30, 0.40), CF(1.20 * s, 1.00, 0.04), p.base)
				c:cone(V3(0.10, 0.26, 0.10), CF(1.18 * s, 1.24, -0.04) * ANG(-0.3, 0, -0.3 * s), p.light)
				c:box(V3(0.06, 0.06, 0.06), CF(1.20 * s, 1.04, 0.25), p.glow, NEON)
				c:box(V3(0.10, 0.30, 0.10), CF(1.30 * s, 0.70, 0.04), RUBY)
				c:rod(V3(0.45 * s, 0.82, 0), V3(0.30 * s, 0.62, 0), 0.03, GOLD, METAL, false)
			end
			c:box(V3(2.20, 0.26, 0.30), CF(0, 0.95, 0), p.dark)
			c:ball(V3(0.26, 0.26, 0.26), CF(0, 1.20, 0), p.glow, NEON)
			-- The gong: a dark rim, the face disc and a boss for a nose.
			c:cyl(V3(0.14, 1.36, 1.36), CF(0, -0.05, 0) * ANG(0, PI / 2, 0), p.dark, METAL)
			c:cyl(V3(0.16, 1.10, 1.10), CF(0, -0.05, 0) * ANG(0, PI / 2, 0), p.base, METAL)
			c:cyl(V3(0.20, 0.26, 0.26), CF(0, -0.12, 0) * ANG(0, PI / 2, 0), p.light, METAL)
			c:eyes(0.22, 0.10, 0.28, 0.16)
			c:box(V3(0.36, 0.06, 0.04), CF(0, -0.38, 0.09), INK)
			c:rod(V3(0.95, -0.85, 0.40), V3(0.70, -0.30, 0.55), 0.04, TIMBER, WOOD, false)
			c:box(V3(0.26, 0.26, 0.26), CF(0.68, -0.22, 0.56), RUBY)
		end,
	}

	-- A painted folding fan from the dragon court, opened wide: its ribs
	-- spread from a jewelled pivot, the face sits in the middle under painted
	-- gems, two little claws grip its edges and a tassel swings below.
	S.df_t_fan = {
		label = "Wyrmpaint Fan",
		set = SET,
		tint = C3(120, 170, 255),
		scale = 1.15,
		head = CF(0, 0.78, 0),
		neck = CF(0, -0.70, 0.20),
		back = CF(0, 0.10, -0.20),
		build = function(c, p)
			local PIV = V3(0, -0.80, 0)
			for k = 0, 6 do
				local a = -1.0 + k * (2.0 / 6)
				local dir = V3(math.sin(a), math.cos(a), 0)
				local lift = V3(0, 0, (k % 2) * 0.03)
				c:box(V3(0.50, 1.50, 0.06), CF(PIV + dir * 0.75 + lift) * ANG(0, 0, -a), k % 2 == 0 and p.base or p.light)
				c:box(V3(0.40, 0.10, 0.10), CF(PIV + dir * 1.50 + lift) * ANG(0, 0, -a), p.dark)
			end
			c:eyes(0.30, 0.10, 0.30, 0.17)
			c:box(V3(0.30, 0.06, 0.04), CF(0, 0.02, 0.08), INK)
			for _, v in ipairs({ { -0.30, 0.55 }, { 0, 0.62 }, { 0.30, 0.55 } }) do
				c:box(V3(0.14, 0.14, 0.04), CF(v[1], v[2], 0.07) * ANG(0, 0, PI / 4), p.glow, NEON)
			end
			c:cyl(V3(0.14, 0.24, 0.24), CF(PIV + V3(0, 0, 0.06)) * ANG(0, PI / 2, 0), GOLD, METAL)
			c:rod(PIV, PIV + V3(0, -0.30, 0.02), 0.025, GOLD, METAL, false)
			c:box(V3(0.14, 0.26, 0.14), CF(PIV + V3(0, -0.44, 0.02)), RUBY)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.20, 0.20, 0.20), CF(1.10 * s, -0.10, 0.06), p.deep)
			end
		end,
	}

	-- A wooden rocking dragon from the hoard's toy chest: painted spots, a
	-- saddle, a handle through its head, wooden wings, a yarn mane and tail,
	-- all on two curved rockers.
	S.df_t_rocking = {
		label = "Rocking Drake",
		set = SET,
		tint = C3(150, 80, 220),
		scale = 1.05,
		head = CF(0, 0.80, 0.45),
		neck = CF(0, -0.30, 1.00),
		back = CF(0, 0.70, -0.40),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.50, 1.10, 1.70),
				eyeY = 0.12, eyeSpread = 0.36, eyeSize = V3(0.40, 0.46, 0.20),
				snout = { w = 0.66, h = 0.36, d = 0.36, y = -0.18, color = p.light, nose = p.deep },
				legSize = V3(0.30, 0.50, 0.30), legX = 0.50, legZ = { 0.55, -0.55 }, legY = -0.70, legColor = p.dark,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V3(0.12, 0.14, 1.00), CF(0.50 * s, -1.02, 0), p.deep, WOOD)
				c:box(V3(0.12, 0.14, 0.70), CF(0.50 * s, -0.92, 0.80) * ANG(-0.35, 0, 0), p.deep, WOOD)
				c:box(V3(0.12, 0.14, 0.70), CF(0.50 * s, -0.92, -0.80) * ANG(0.35, 0, 0), p.deep, WOOD)
				c:cone(V3(0.18, 0.40, 0.18), CF(0.30 * s, 0.78, 0.45) * ANG(-0.3, 0, -0.2 * s), p.light)
				c:box(V3(0.10, 0.50, 0.70), CF(0.80 * s, 0.35, -0.20) * ANG(0, 0, -0.5 * s), p.light, WOOD)
				c:box(V3(0.04, 0.22, 0.22), CF(0.76 * s, -0.05, -0.25), p.pale)
			end
			c:rod(V3(-0.85, 0.30, 0.55), V3(0.85, 0.30, 0.55), 0.05, TIMBER, WOOD)
			c:box(V3(0.90, 0.12, 0.70), CF(0, 0.64, -0.15), RUBY)
			c:box(V3(0.94, 0.06, 0.74), CF(0, 0.58, -0.15), GOLD, METAL)
			for _, z in ipairs({ 0.62, 0.36 }) do
				c:box(V3(0.22, 0.22, 0.22), CF(0, 0.66, z) * ANG(0, PI / 4, 0), p.glow)
			end
			c:rod(V3(0, 0.10, -0.85), V3(0, -0.20, -1.20), 0.06, p.glow, nil, false)
			c:box(V3(0.22, 0.30, 0.22), CF(0, -0.30, -1.28), p.glow)
		end,
	}

	-- The dragon king's banner, walking on its own three-legged stand: a
	-- swallow-tailed flag with a face and a glowing crest, a gold orb with
	-- wings atop the pole and tassels swinging from the crossbar.
	S.df_t_banner = {
		label = "Kingscrest Banner",
		set = SET,
		tint = C3(240, 140, 40),
		head = CF(0, 1.50, -0.10),
		neck = CF(0, -0.40, 0.20),
		back = CF(0, 0.20, -0.20),
		build = function(c, p)
			c:rod(V3(0, -1.20, -0.10), V3(0, 1.30, -0.10), 0.06, TIMBER, WOOD, false)
			c:box(V3(1.70, 0.12, 0.12), CF(0, 1.05, 0), GOLD, METAL)
			c:box(V3(1.40, 1.60, 0.10), CF(0, 0.20, 0.06), p.base)
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.70, 0.50, 0.10), CF(0.35 * s, -0.85, 0.06) * ANG(PI, 0, 0), p.base)
				c:box(V3(0.10, 1.60, 0.12), CF(0.70 * s, 0.20, 0.06), p.light)
				c:box(V3(0.30, 0.16, 0.04), CF(0.32 * s, -0.18, 0.13) * ANG(0, 0, 0.4 * s), p.light)
				c:cone(V3(0.10, 0.30, 0.20), CF(0.15 * s, 1.47, -0.10) * ANG(0, 0, -0.6 * s), GOLD, METAL)
				c:rod(V3(0.85 * s, 1.00, 0), V3(0.85 * s, 0.62, 0), 0.025, GOLD, METAL, false)
				c:box(V3(0.12, 0.22, 0.12), CF(0.85 * s, 0.52, 0), RUBY)
			end
			c:eyes(0.45, 0.13, 0.30, 0.17)
			c:box(V3(0.30, 0.06, 0.04), CF(0, 0.18, 0.12), INK)
			c:box(V3(0.36, 0.36, 0.04), CF(0, -0.25, 0.12) * ANG(0, 0, PI / 4), p.glow, NEON)
			c:ball(V3(0.26, 0.26, 0.26), CF(0, 1.40, -0.10), GOLD, METAL)
			for k = 0, 2 do
				c:box(V3(0.70, 0.12, 0.16), CF(0, -1.20, -0.10) * ANG(0, k * PI / 3, 0), p.dark)
			end
		end,
	}

	--------------------------------------------------------------------------
	-- MYTHIC: spectacular.
	--------------------------------------------------------------------------

	-- A sea serpent breaching the waves: a finned head out front, two humps
	-- arching out of the water behind it, tail flukes, foam and a pearl.
	S.df_t_seaserpent = {
		label = "Wavecrest Serpent",
		set = SET,
		tint = C3(20, 140, 200),
		scale = 1.30,
		head = CF(0, 0.86, 0.85),
		neck = CF(0, -0.20, 1.32),
		back = CF(0, 0.0, -0.30),
		build = function(c, p)
			local WATER = C3(80, 170, 240)
			c:box(V3(1.20, 1.30, 0.90), CF(0, 0.20, 0.85), p.base)
			c:box(V3(0.70, 0.36, 0.30), CF(0, -0.02, 1.42), p.light)
			c:eyes(0.48, 1.32, 0.30, 0.17)
			c:box(V3(0.36, 0.06, 0.04), CF(0, -0.14, 1.58), INK)
			c:box(V3(0.08, 0.45, 0.70), CF(0, 0.98, 0.75), p.glow, NEON)
			c:box(V3(0.90, 0.70, 0.70), CF(0, -0.62, 0.55), p.base)
			c:box(V3(0.60, 0.50, 0.05), CF(0, -0.60, 0.91), p.pale)
			-- Two humps arching out of the waves.
			c:box(V3(0.80, 0.80, 0.80), CF(0, -0.58, -0.30) * ANG(PI / 4, 0, 0), p.dark)
			c:box(V3(0.70, 0.64, 0.64), CF(0, -0.66, -0.95) * ANG(PI / 4, 0, 0), p.base)
			c:cone(V3(0.12, 0.30, 0.30), CF(0, 0.06, -0.30), p.light)
			c:cone(V3(0.10, 0.24, 0.24), CF(0, -0.15, -0.95), p.light)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.10, 0.55, 0.40), CF(0.64 * s, 0.55, 0.70) * ANG(0.3, 0, -0.5 * s), p.light)
				c:rod(V3(0.30 * s, -0.08, 1.52), V3(0.75 * s, -0.24, 1.76), 0.035, p.glow, NEON, false)
				c:box(V3(0.45, 0.10, 0.35), CF(0.28 * s, -0.42, -1.42) * ANG(0, 0, 0.60 * s), p.light)
			end
			-- The sea itself, its foam and spray.
			c:box(V3(2.00, 0.30, 2.80), CF(0, -1.00, 0), WATER, GLASS).Transparency = 0.35
			c:box(V3(1.10, 0.12, 0.90), CF(0, -0.84, 0.55), CLOUD)
			c:box(V3(1.00, 0.12, 0.70), CF(0, -0.84, -0.30), CLOUD)
			c:box(V3(0.90, 0.12, 0.60), CF(0, -0.84, -1.05), CLOUD)
			c:ball(V3(0.16, 0.16, 0.16), CF(0.75, -0.55, 1.00), CLOUD)
			c:ball(V3(0.12, 0.12, 0.12), CF(-0.70, -0.45, 0.20), CLOUD)
			c:ball(V3(0.26, 0.26, 0.26), CF(0, 1.42, 0.95), p.glow, NEON)
		end,
	}

	-- A raptor dug out of the amber beds: upright on big clawed feet, little
	-- feathered arms, bone ribs and back plate, a glowing amber heart.
	S.df_t_raptor = {
		label = "Amberbone Raptor",
		set = SET,
		tint = C3(200, 160, 110),
		scale = 1.25,
		head = CF(0, 0.92, 0.30),
		neck = CF(0, -0.20, 0.86),
		back = CF(0, 0.50, -0.60),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.40, 1.60, 1.40),
				eyeY = 0.40, eyeSpread = 0.32, eyeSize = V3(0.38, 0.46, 0.20),
				snout = { w = 0.80, h = 0.40, d = 0.50, y = -0.10, color = p.light, nose = p.deep },
				bib = { w = 0.80, h = 0.70, y = -0.40, color = p.pale },
				legSize = V3(0.46, 0.50, 0.70), legX = 0.42, legZ = { 0.10 }, legY = -0.90, legColor = p.dark,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.10, 0.16, 0.10), CF(0.22 * s, -0.36, 0.98) * ANG(PI, 0, 0), WHITE)
				c:box(V3(0.20, 0.20, 0.40), CF(0.55 * s, -0.12, 0.82), p.dark)
				c:box(V3(0.06, 0.30, 0.30), CF(0.66 * s, -0.05, 0.80), p.glow, NEON)
				c:cone(V3(0.12, 0.30, 0.12), CF(0.42 * s, -0.98, 0.52) * ANG(0.6, 0, 0), BONE)
				for _, z in ipairs({ -0.05, -0.40 }) do
					c:box(V3(0.06, 0.80, 0.12), CF(0.71 * s, 0.10, z), BONE)
				end
			end
			for _, z in ipairs({ 0.35, 0.0, -0.35 }) do
				c:box(V3(0.10, 0.44 - math.abs(z) * 0.3, 0.30), CF(0, 1.06 - math.abs(z) * 0.15, z) * ANG(-0.3, 0, 0), p.glow, NEON)
			end
			c:box(V3(0.80, 0.60, 0.10), CF(0, 0.40, -0.74), BONE)
			c:box(V3(0.60, 0.55, 0.70), CF(0, -0.10, -0.95), p.base)
			c:box(V3(0.44, 0.40, 0.60), CF(0, 0.05, -1.50), p.dark)
			c:box(V3(0.36, 0.08, 0.40), CF(0, 0.15, -1.90), p.glow, NEON)
			c:box(V3(0.26, 0.26, 0.08), CF(0, -0.30, 0.84) * ANG(0, 0, PI / 4), AMBER, NEON)
			c:box(V3(0.16, 0.30, 0.10), CF(1.00, 0.90, -0.30) * ANG(0.4, 0.3, 0.6), BONE)
			c:box(V3(0.14, 0.26, 0.10), CF(-0.95, 1.05, 0.10) * ANG(-0.3, 0.2, -0.5), BONE)
			c:light(AMBER, 1.0, 6)
		end,
	}

	-- A temple pillar with a dragon coiled all the way up it: its head rests
	-- on the top at the front, whiskers glowing, one claw on a flaming
	-- pearl, with clouds round the plinth.
	S.df_t_pillar = {
		label = "Dragoncoil Pillar",
		set = SET,
		tint = C3(200, 40, 50),
		scale = 1.10,
		head = CF(0.10, 1.22, 0.75),
		neck = CF(0, -0.40, 0.90),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:box(V3(1.40, 0.30, 1.40), CF(0, -1.10, 0), p.deep, SLATE)
			c:box(V3(0.90, 1.90, 0.90), CF(0, 0.0, 0), p.pale)
			c:box(V3(1.30, 0.24, 1.30), CF(0, 1.05, 0), p.deep, SLATE)
			c:box(V3(0.04, 0.60, 0.14), CF(-0.46, -0.50, 0), p.glow, NEON)
			-- The coils, spiralling up round the pillar's four faces.
			local coil = {
				{ V3(0, -0.85, 0.63), V3(0.90, 0.34, 0.34) },
				{ V3(0.63, -0.55, 0), V3(0.34, 0.34, 0.90) },
				{ V3(0, -0.25, -0.63), V3(0.90, 0.34, 0.34) },
				{ V3(-0.63, 0.05, 0), V3(0.34, 0.34, 0.90) },
				{ V3(0, 0.35, 0.63), V3(0.90, 0.34, 0.34) },
				{ V3(0.63, 0.65, 0), V3(0.34, 0.34, 0.90) },
			}
			for i, v in ipairs(coil) do
				c:box(v[2], CF(v[1]), i % 2 == 0 and p.dark or p.base)
			end
			c:cone(V3(0.24, 0.40, 0.24), CF(-0.62, -0.85, 0.63) * ANG(0, 0, PI / 2), p.light)
			-- Its head at the top.
			c:box(V3(0.70, 0.60, 0.60), CF(0.10, 0.88, 0.75), p.base)
			c:box(V3(0.44, 0.26, 0.24), CF(0.10, 0.72, 1.14), p.light)
			c:box(V3(0.24, 0.04, 0.04), CF(0.10, 0.64, 1.27), INK)
			for _, s in ipairs(SIDES) do
				c:eye(V3(0.10 + 0.20 * s, 0.98, 1.06), 0.13)
				c:cone(V3(0.12, 0.36, 0.12), CF(0.10 + 0.22 * s, 1.30, 0.66) * ANG(-0.4, 0, -0.3 * s), p.pale)
				c:rod(V3(0.10 + 0.20 * s, 0.70, 1.20), V3(0.10 + 0.60 * s, 0.55, 1.40), 0.03, p.glow, NEON, false)
				c:box(V3(0.80, 0.24, 0.50), CF(0.75 * s, -1.20, 0.55 * s), CLOUD)
			end
			c:ball(V3(0.32, 0.32, 0.32), CF(0.62, 0.20, 0.92), p.glow, NEON)
			c:cone(V3(0.20, 0.30, 0.20), CF(0.62, 0.44, 0.92), AMBER, NEON)
			c:box(V3(0.22, 0.16, 0.22), CF(0.55, 0.30, 0.78), p.dark)
			c:light(p.glow, 1.0, 7)
		end,
	}

	-- A seeing-orb held up in a golden dragon's claw: four talons curl round
	-- the glowing ball, which has a face, a tilted ring of runes circles it
	-- and crystal shards float above.
	S.df_t_talonorb = {
		label = "Wyrmtalon Orb",
		set = SET,
		tint = C3(90, 200, 255),
		scale = 1.10,
		head = CF(0, 1.02, 0),
		neck = CF(0, -0.50, 0.70),
		back = CF(0, 0.25, -0.75),
		build = function(c, p)
			c:ball(V3(1.50, 1.50, 1.50), CF(0, 0.25, 0), p.base)
			c:eyes(0.40, 0.70, 0.30, 0.18)
			c:box(V3(0.30, 0.06, 0.04), CF(0, 0.02, 0.73), INK)
			c:box(V3(0.90, 0.30, 0.90), CF(0, -0.62, 0), GOLD, METAL)
			c:box(V3(0.50, 0.40, 0.50), CF(0, -0.95, 0), p.dark, METAL)
			c:box(V3(1.20, 0.20, 1.20), CF(0, -1.22, 0), p.deep)
			for _, sx in ipairs(SIDES) do
				for _, sz in ipairs(SIDES) do
					local tip = V3(0.62 * sx, 0.05, 0.45 * sz)
					c:rod(V3(0.38 * sx, -0.55, 0.38 * sz), tip, 0.09, GOLD, METAL, false)
					c:cone(V3(0.14, 0.30, 0.14), CF(tip + V3(-0.04 * sx, 0.14, -0.03 * sz)) * ANG(0.25 * sz, 0, 0.35 * sx), BONE)
				end
			end
			for k = 0, 7 do
				local a = k * PI / 4
				c:box(V3(0.18, 0.08, 0.10), CF(1.05 * math.sin(a), 0.25 - 0.45 * math.cos(a), 1.05 * math.cos(a)) * ANG(0, a, 0), p.glow, NEON)
			end
			c:box(V3(0.16, 0.30, 0.16), CF(0.45, 1.30, 0.10) * ANG(0.2, 0, -0.3), p.light, NEON)
			c:box(V3(0.12, 0.24, 0.12), CF(-0.40, 1.25, -0.10) * ANG(-0.2, 0, 0.4), p.light, NEON)
			c:light(p.glow, 1.4, 9)
		end,
	}

	-- A chrysalis of dragon scales hanging from a branch, glowing along its
	-- seams, with little wing buds already peeking out: whatever hatches
	-- from it is going to be very shiny.
	S.df_t_chrysalis = {
		label = "Scale Chrysalis",
		set = SET,
		tint = C3(120, 220, 120),
		scale = 1.05,
		head = CF(0, 1.02, 0),
		neck = CF(0, -0.60, 0.50),
		back = CF(0, 0.10, -0.66),
		build = function(c, p)
			c:rod(V3(-1.00, 1.24, 0), V3(1.00, 1.30, 0), 0.07, TIMBER, WOOD, false)
			c:box(V3(0.36, 0.08, 0.24), CF(-0.90, 1.32, 0.12) * ANG(0, 0.4, 0.3), LEAF)
			c:box(V3(0.36, 0.08, 0.24), CF(0.85, 1.36, -0.10) * ANG(0, -0.3, -0.3), LEAF)
			c:rod(V3(0, 1.22, 0), V3(0, 0.95, 0), 0.03, CLOUD, nil, false)
			c:box(V3(0.60, 0.30, 0.55), CF(0, 0.82, 0), p.dark)
			c:box(V3(1.10, 0.50, 1.00), CF(0, 0.45, 0), p.base)
			c:box(V3(1.40, 0.70, 1.20), CF(0, -0.15, 0), p.base)
			c:box(V3(1.00, 0.40, 0.90), CF(0, -0.70, 0), p.dark)
			c:cone(V3(0.60, 0.50, 0.55), CF(0, -1.12, 0) * ANG(PI, 0, 0), p.base)
			c:box(V3(1.44, 0.10, 1.24), CF(0, -0.48, 0), GOLD, METAL)
			c:eyes(0.0, 0.62, 0.30, 0.17)
			c:box(V3(0.26, 0.06, 0.04), CF(0, -0.28, 0.61), INK)
			for _, x in ipairs({ -0.30, 0, 0.30 }) do
				c:box(V3(0.22, 0.22, 0.06), CF(x, -0.70, 0.46) * ANG(0, 0, PI / 4), p.light)
			end
			for _, x in ipairs({ -0.22, 0.22 }) do
				c:box(V3(0.20, 0.20, 0.06), CF(x, 0.50, 0.51) * ANG(0, 0, PI / 4), p.light)
			end
			for _, s in ipairs(SIDES) do
				c:box(V3(0.04, 0.66, 0.10), CF(0.71 * s, -0.15, 0), p.glow, NEON)
				c:box(V3(0.08, 0.50, 0.40), CF(0.76 * s, 0.10, -0.25) * ANG(0, 0, -0.3 * s), p.pale).Transparency = 0.3
			end
			c:box(V3(0.30, 0.04, 0.04), CF(0.25, 0.30, 0.51) * ANG(0, 0, 0.3), p.glow, NEON)
			for _, v in ipairs({ { 0.85, 0.40, 0.30 }, { -0.80, -0.30, 0.25 }, { 0.70, -0.85, -0.20 } }) do
				c:ball(V3(0.12, 0.12, 0.12), CF(v[1], v[2], v[3]), p.glow, NEON)
			end
			c:light(p.glow, 1.0, 7)
		end,
	}

	-- A great chandelier from the dragon king's hall, alive: a round iron
	-- body with a face, four dragon-neck arms holding lit candles, a gold
	-- crown band, wing plates and a glowing crystal drop.
	S.df_t_chandelier = {
		label = "Wyrm Chandelier",
		set = SET,
		tint = C3(60, 50, 140),
		scale = 1.10,
		head = CF(0, 0.60, 0),
		neck = CF(0, -0.40, 0.56),
		back = CF(0, 0.10, -0.56),
		build = function(c, p)
			local WAX = C3(250, 240, 210)
			c:box(V3(1.00, 0.90, 1.00), CF(0, 0.10, 0), p.base, METAL)
			c:box(V3(1.06, 0.10, 1.06), CF(0, 0.50, 0), GOLD, METAL)
			c:eyes(0.25, 0.52, 0.24, 0.15)
			c:box(V3(0.26, 0.06, 0.04), CF(0, -0.02, 0.51), INK)
			c:rod(V3(0, 0.55, 0), V3(0, 1.20, 0), 0.04, GOLD, METAL, false)
			c:box(V3(0.36, 0.08, 0.36), CF(0, 1.24, 0), GOLD, METAL)
			c:cone(V3(0.50, 0.50, 0.50), CF(0, -0.60, 0) * ANG(PI, 0, 0), p.dark, METAL)
			c:box(V3(0.20, 0.20, 0.20), CF(0, -0.95, 0) * ANG(PI / 4, 0, PI / 4), p.glow, NEON)
			for _, sx in ipairs(SIDES) do
				for _, sz in ipairs(SIDES) do
					local tip = V3(0.80 * sx, 0.25, 0.80 * sz)
					c:rod(V3(0.40 * sx, 0.0, 0.40 * sz), tip, 0.07, p.dark, METAL, false)
					c:box(V3(0.30, 0.10, 0.30), CF(tip + V3(0, 0.04, 0)), GOLD, METAL)
					c:cyl(V3(0.30, 0.14, 0.14), CF(tip + V3(0, 0.24, 0)) * ANG(0, 0, PI / 2), WAX)
					c:cone(V3(0.12, 0.22, 0.12), CF(tip + V3(0, 0.50, 0)), AMBER, NEON)
				end
				c:box(V3(0.08, 0.40, 0.50), CF(0.56 * sx, 0.20, -0.05) * ANG(0, 0, -0.4 * sx), p.light, METAL)
				c:box(V3(0.10, 0.20, 0.10), CF(0.55 * sx, -0.30, 0.55) * ANG(PI / 4, 0, 0), p.light, NEON)
			end
			c:light(AMBER, 1.2, 8)
		end,
	}

	--------------------------------------------------------------------------
	-- DIVINE: regal and radiant.
	--------------------------------------------------------------------------

	-- A round little drake with three pairs of wings (raised, spread and
	-- lowered), a gold halo, a star held to its chest, riding on clouds.
	S.df_t_seraph = {
		label = "Seraph Drake",
		set = SET,
		tint = C3(255, 240, 200),
		scale = 1.25,
		head = CF(0, 0.92, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.50, 1.50, 1.40),
				eyeY = 0.18, eyeSpread = 0.36, eyeSize = V3(0.44, 0.52, 0.20),
				snout = { w = 0.56, h = 0.32, d = 0.28, y = -0.18, color = p.pale, nose = p.deep },
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V3(0.14, 0.80, 0.50), CF(0.70 * s, 1.05, -0.40) * ANG(0, 0, -0.50 * s), p.light)
				c:box(V3(0.70, 0.14, 0.50), CF(1.05 * s, 0.30, -0.40) * ANG(0, 0, 0.20 * s), p.pale)
				c:box(V3(0.24, 0.16, 0.36), CF(1.42 * s, 0.38, -0.40) * ANG(0, 0, 0.20 * s), p.glow, NEON)
				c:box(V3(0.14, 0.70, 0.45), CF(0.80 * s, -0.55, -0.40) * ANG(0, 0, 0.50 * s), p.light)
				c:cone(V3(0.16, 0.30, 0.16), CF(0.32 * s, 0.92, 0.30), p.pale)
				c:box(V3(0.24, 0.24, 0.24), CF(0.40 * s, -0.45, 0.72), p.base)
			end
			for k = 0, 5 do
				local a = k * PI / 3
				c:box(V3(0.44, 0.08, 0.10), CF(0.42 * math.cos(a), 1.32, -0.05 + 0.42 * math.sin(a)) * ANG(0, -a - PI / 2, 0), GOLD, NEON)
			end
			c:box(V3(0.16, 0.16, 0.06), CF(0, 0.62, 0.72) * ANG(0, 0, PI / 4), SAPPHIRE, NEON)
			c:box(V3(0.30, 0.30, 0.08), CF(0, -0.45, 0.80) * ANG(0, 0, PI / 4), BOLT, NEON)
			c:rod(V3(0, -0.40, -0.70), V3(0, -0.70, -1.05), 0.08, p.base, nil, false)
			c:cone(V3(0.24, 0.30, 0.24), CF(0, -0.75, -1.12) * ANG(-2.3, 0, 0), p.glow, NEON)
			c:box(V3(1.40, 0.30, 1.00), CF(0, -0.95, 0), CLOUD)
			c:box(V3(0.80, 0.25, 0.60), CF(0.55, -1.05, 0.40), CLOUD)
			c:box(V3(0.70, 0.25, 0.60), CF(-0.60, -1.02, -0.35), CLOUD)
			c:sparkle(p.glow, 3, 0.5, 0.2)
			c:light(p.glow, 1.2, 8)
		end,
	}

	-- A floating island that broke off the dragon's mountain: a face on its
	-- rocky front, a little domed temple and a tree on its grassy top, a
	-- waterfall of light pouring off one side, roots and clouds beneath.
	S.df_t_skyisle = {
		label = "Skyruin Isle",
		set = SET,
		tint = C3(60, 150, 90),
		scale = 1.25,
		head = CF(-0.40, 0.60, 0.40),
		neck = CF(0, -0.50, 0.90),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			c:box(V3(1.90, 0.70, 1.70), CF(0, 0.0, 0), p.base)
			c:box(V3(2.06, 0.18, 1.86), CF(0, 0.42, 0), p.light)
			c:cone(V3(1.60, 1.00, 1.40), CF(0, -0.85, 0) * ANG(PI, 0, 0), p.dark)
			c:eyes(0.06, 0.87, 0.36, 0.18)
			c:box(V3(0.36, 0.06, 0.04), CF(0, -0.22, 0.86), INK)
			c:rod(V3(0.30, -1.10, 0.20), V3(0.40, -1.45, 0.30), 0.04, TIMBER, WOOD, false)
			c:rod(V3(-0.30, -0.90, -0.20), V3(-0.45, -1.30, -0.30), 0.04, TIMBER, WOOD, false)
			-- The temple.
			c:box(V3(1.00, 0.10, 0.80), CF(0.25, 0.56, -0.25), STONE, SLATE)
			for _, dx in ipairs({ -0.35, 0.35 }) do
				for _, dz in ipairs({ -0.30, 0.30 }) do
					c:cyl(V3(0.50, 0.12, 0.12), CF(0.25 + dx, 0.86, -0.25 + dz) * ANG(0, 0, PI / 2), STONE)
				end
			end
			c:box(V3(1.00, 0.10, 0.80), CF(0.25, 1.15, -0.25), STONE, SLATE)
			c:ball(V3(0.70, 0.70, 0.70), CF(0.25, 1.25, -0.25), p.pale)
			c:box(V3(0.12, 0.12, 0.12), CF(0.25, 1.64, -0.25) * ANG(PI / 4, 0, PI / 4), p.glow, NEON)
			c:rod(V3(-0.65, 0.50, 0.35), V3(-0.65, 0.85, 0.35), 0.05, TIMBER, WOOD, false)
			c:box(V3(0.44, 0.36, 0.44), CF(-0.65, 0.98, 0.35), LEAF)
			-- The waterfall, clouds and floating gems.
			c:box(V3(0.06, 1.10, 0.40), CF(-0.98, -0.25, 0.30), p.glow, NEON).Transparency = 0.4
			c:ball(V3(0.36, 0.30, 0.36), CF(-0.98, -0.85, 0.30), CLOUD)
			c:box(V3(0.80, 0.22, 0.50), CF(1.10, -0.45, 0.40), CLOUD)
			c:box(V3(0.80, 0.22, 0.50), CF(-1.05, -0.50, -0.40), CLOUD)
			c:box(V3(0.70, 0.20, 0.50), CF(0.30, -0.55, -1.00), CLOUD)
			c:box(V3(0.14, 0.14, 0.14), CF(1.15, 0.60, -0.20) * ANG(0.5, 0.5, 0), SAPPHIRE, NEON)
			c:box(V3(0.12, 0.12, 0.12), CF(-1.10, 0.75, -0.30) * ANG(0.3, 0.6, 0), EMERALD, NEON)
			c:sparkle(p.glow, 2, 0.5, 0.2)
		end,
	}

	-- A dragon drawn in the stars: a bright star-orb with a face is its
	-- head, and glowing stars joined by fine lines trace its neck, wings,
	-- body, legs and tail.
	S.df_t_constellation = {
		label = "Wyrm Constellation",
		set = SET,
		tint = C3(200, 180, 255),
		head = CF(0, 0.86, 0.40),
		neck = CF(0, -0.10, 0.84),
		back = CF(0, 0.90, -0.60),
		build = function(c, p)
			local H = V3(0, 0.30, 0.40)
			c:ball(V3(0.90, 0.90, 0.90), CF(H), p.light)
			c:eyes(0.40, 0.80, 0.24, 0.15)
			c:box(V3(0.24, 0.05, 0.04), CF(0, 0.16, 0.83), INK)
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.12, 0.30, 0.12), CF(0.22 * s, 0.78, 0.35) * ANG(0, 0, -0.3 * s), p.glow, NEON)
			end
			local N, B = V3(0.55, 0.75, 0.0), V3(0.20, 0.95, -0.55)
			local W1, W2, W3 = V3(1.20, 1.25, -0.20), V3(1.05, 0.55, -0.40), V3(-0.75, 1.30, -0.40)
			local C, T1, T2 = V3(-0.40, 0.40, -0.80), V3(-0.95, -0.10, -0.55), V3(-1.10, -0.65, -0.05)
			local L1, L2 = V3(0.50, -0.45, -0.30), V3(-0.20, -0.55, -0.60)
			for _, pos in ipairs({ N, B, W1, W2, W3, C, T1, T2, L1, L2 }) do
				c:box(V3(0.20, 0.20, 0.06), CF(pos) * ANG(0, 0, PI / 4), p.glow, NEON)
			end
			for _, l in ipairs({
				{ H, N }, { N, B }, { B, W1 }, { W1, W2 }, { B, W3 },
				{ B, C }, { C, T1 }, { T1, T2 }, { C, L2 }, { N, L1 },
			}) do
				c:rod(l[1], l[2], 0.025, p.pale, NEON, false)
			end
			c:sparkle(p.glow, 3, 0.4, 0.2)
			c:light(p.glow, 1.2, 8)
		end,
	}

	-- The dragon king's palanquin, carried along by clouds: a curtained cabin
	-- with a face, a tiered roof with upturned eaves and a pearl on top,
	-- gold-capped carrying poles and tassels.
	S.df_t_palanquin = {
		label = "Dragon Palanquin",
		set = SET,
		tint = C3(250, 200, 60),
		scale = 1.15,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.50, 0.76),
		back = CF(0, 0.10, -0.76),
		build = function(c, p)
			c:box(V3(1.40, 1.30, 1.40), CF(0, 0.0, 0), p.base)
			c:box(V3(0.90, 0.80, 0.06), CF(0, 0.08, 0.71), p.pale)
			c:eyes(0.24, 0.74, 0.26, 0.16)
			c:box(V3(0.28, 0.06, 0.04), CF(0, -0.06, 0.75), INK)
			c:box(V3(1.80, 0.16, 1.80), CF(0, 0.73, 0), p.dark)
			c:box(V3(1.30, 0.30, 1.30), CF(0, 0.95, 0), p.deep)
			c:box(V3(0.70, 0.20, 0.70), CF(0, 1.18, 0), p.dark)
			c:ball(V3(0.26, 0.26, 0.26), CF(0, 1.40, 0), GOLD, METAL)
			c:cone(V3(0.16, 0.30, 0.16), CF(0, 1.62, 0), p.glow, NEON)
			c:box(V3(1.50, 0.16, 1.50), CF(0, -0.72, 0), GOLD, METAL)
			for _, sx in ipairs(SIDES) do
				c:box(V3(0.12, 0.20, 0.06), CF(0.42 * sx, 0.10, 0.75), GOLD, METAL)
				c:rod(V3(0.80 * sx, -0.30, -1.40), V3(0.80 * sx, -0.30, 1.40), 0.07, p.deep, WOOD, false)
				for _, sz in ipairs(SIDES) do
					c:cone(V3(0.20, 0.30, 0.20), CF(0.92 * sx, 0.85, 0.92 * sz) * ANG(0.4 * sz, 0, -0.4 * sx), p.light)
					c:ball(V3(0.18, 0.18, 0.18), CF(0.80 * sx, -0.30, 1.42 * sz), GOLD, METAL)
				end
				c:box(V3(0.10, 0.30, 0.10), CF(0.90 * sx, 0.50, 0.90), RUBY)
			end
			c:box(V3(1.30, 0.25, 0.90), CF(0, -0.95, 0), CLOUD)
			c:box(V3(0.60, 0.22, 0.50), CF(0.75, -1.00, 0.55), CLOUD)
			c:box(V3(0.60, 0.22, 0.50), CF(-0.75, -1.00, -0.55), CLOUD)
			c:sparkle(GOLD, 2, 0.5, 0.18)
		end,
	}

	--------------------------------------------------------------------------
	-- EXOTIC: world-scale wonders.
	--------------------------------------------------------------------------

	-- A festival dragon-dance costume come to life: a big mask with pompoms,
	-- horns, whiskers and a beard, a fringed body and two pairs of boots.
	S.df_t_parade = {
		label = "Parade Dragon",
		set = SET,
		tint = C3(255, 200, 40),
		scale = 1.25,
		head = CF(0, 0.92, 0.60),
		neck = CF(0, -0.60, 1.22),
		back = CF(0, 0.95, -0.40),
		build = function(c, p)
			c:box(V3(1.50, 1.30, 1.20), CF(0, 0.20, 0.60), p.base)
			c:box(V3(1.30, 0.30, 0.80), CF(0, -0.58, 0.80), p.light)
			c:box(V3(0.70, 0.16, 0.06), CF(0, -0.30, 1.21), INK)
			c:eyes(0.40, 1.22, 0.36, 0.21)
			c:ball(V3(0.30, 0.30, 0.30), CF(0, 0.08, 1.26), RUBY, NEON)
			c:box(V3(0.80, 0.30, 0.20), CF(0, -0.82, 1.05), p.pale)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.46, 0.14, 0.14), CF(0.36 * s, 0.72, 1.18), p.dark)
				c:ball(V3(0.30, 0.30, 0.30), CF(0.36 * s, 0.92, 1.10), p.glow, NEON)
				c:cone(V3(0.26, 0.70, 0.26), CF(0.45 * s, 1.10, 0.30) * ANG(-0.4, 0, -0.25 * s), p.light)
				c:rod(V3(0.55 * s, -0.10, 1.15), V3(1.05 * s, -0.35, 1.30), 0.04, p.pale, nil, false)
				c:box(V3(0.14, 0.90, 0.70), CF(0.80 * s, 0.15, 0.50), p.dark)
				c:box(V3(0.26, 0.24, 0.34), CF(0.30 * s, -0.86, 0.70), p.deep)
				c:rod(V3(0.30 * s, -0.05, -0.75), V3(0.30 * s, -0.78, -0.75), 0.08, p.deep, nil, false)
				c:box(V3(0.26, 0.24, 0.34), CF(0.30 * s, -0.86, -0.70), p.deep)
			end
			-- The long fringed body behind the mask.
			c:box(V3(1.20, 0.70, 0.60), CF(0, 0.55, -0.20), p.base)
			c:box(V3(1.10, 0.65, 0.60), CF(0, 0.25, -0.75), p.dark)
			c:box(V3(1.00, 0.60, 0.55), CF(0, 0.60, -1.25), p.base)
			c:box(V3(0.70, 0.50, 0.40), CF(0, 0.95, -1.55) * ANG(0.5, 0, 0), p.glow, NEON)
			for _, v in ipairs({ { 0.94, -0.20 }, { 0.62, -0.75 }, { 0.94, -1.25 } }) do
				c:cone(V3(0.24, 0.30, 0.30), CF(0, v[1], v[2]), p.light)
			end
			c:box(V3(1.24, 0.12, 0.62), CF(0, 0.16, -0.20), p.pale)
			c:box(V3(1.14, 0.12, 0.62), CF(0, -0.10, -0.75), p.pale)
		end,
	}

	-- The gate a carp leaps to become a dragon: pillars on clouds, upturned
	-- eaves, a dragon's face on the plaque, lanterns, a pearl, a curtain of
	-- light and a little carp mid-leap.
	S.df_t_gate = {
		label = "Dragon Leap Gate",
		set = SET,
		tint = C3(230, 60, 40),
		scale = 1.20,
		head = CF(0, 1.32, 0),
		neck = CF(0, 0.20, 0.36),
		back = CF(0, 0.60, -0.36),
		build = function(c, p)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 2.00, 0.34), CF(0.85 * s, -0.10, 0), p.base)
				c:box(V3(0.80, 0.30, 0.70), CF(0.85 * s, -1.10, 0), CLOUD)
				c:cone(V3(0.20, 0.40, 0.30), CF(1.36 * s, 1.34, 0) * ANG(0, 0, -0.6 * s), p.light)
				c:rod(V3(1.18 * s, 0.85, 0.20), V3(1.18 * s, 0.60, 0.20), 0.03, GOLD, METAL, false)
				c:box(V3(0.22, 0.28, 0.22), CF(1.18 * s, 0.45, 0.20), RUBY, NEON)
				c:cone(V3(0.14, 0.36, 0.14), CF(0.35 * s, 1.18, 0.30) * ANG(0.3, 0, -0.3 * s), p.light)
				c:rod(V3(0.20 * s, 0.42, 0.28), V3(0.55 * s, 0.30, 0.50), 0.03, p.pale, nil, false)
			end
			c:box(V3(2.10, 0.22, 0.36), CF(0, 0.55, 0), p.dark)
			c:box(V3(2.50, 0.30, 0.50), CF(0, 1.00, 0), p.dark)
			c:box(V3(2.70, 0.16, 0.70), CF(0, 1.22, 0), p.deep)
			-- The dragon's face on the plaque.
			c:box(V3(1.10, 0.90, 0.26), CF(0, 0.62, 0.0), GOLD, METAL)
			c:box(V3(1.00, 0.80, 0.30), CF(0, 0.62, 0.04), p.base)
			c:eyes(0.74, 0.22, 0.26, 0.17)
			c:box(V3(0.40, 0.22, 0.12), CF(0, 0.44, 0.24), p.light)
			c:box(V3(0.28, 0.05, 0.04), CF(0, 0.38, 0.31), INK)
			-- The curtain of light, the pearl and the leaping carp.
			c:box(V3(1.20, 1.30, 0.06), CF(0, -0.45, -0.05), p.glow, NEON).Transparency = 0.45
			c:box(V3(1.40, 0.10, 0.80), CF(0, -1.12, 0), p.glow, NEON)
			c:ball(V3(0.34, 0.34, 0.34), CF(0, 1.48, 0), p.glow, NEON)
			c:cone(V3(0.20, 0.30, 0.20), CF(0, 1.68, 0), p.light)
			c:box(V3(0.24, 0.26, 0.46), CF(0.25, -0.55, 0.22) * ANG(0.8, 0, 0), AMBER)
			c:box(V3(0.04, 0.24, 0.20), CF(0.25, -0.80, 0.02) * ANG(0.8, 0, 0), AMBER)
			c:light(p.glow, 1.2, 8)
		end,
	}

	-- A castle built inside a giant (friendly) dragon skull: its eyes glow
	-- in the sockets, a door in its jaw, towers and flags on top, and four
	-- stubby legs so it can carry its keep about.
	S.df_t_skullkeep = {
		label = "Dragonskull Keep",
		set = SET,
		tint = C3(230, 220, 200),
		scale = 1.25,
		head = CF(0, 1.20, 0.20),
		neck = CF(0, -0.60, 1.32),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			c:box(V3(1.80, 1.30, 1.60), CF(0, 0.10, 0), p.base)
			c:box(V3(1.30, 0.60, 0.60), CF(0, -0.35, 1.00), p.base)
			for _, x in ipairs({ -0.45, -0.15, 0.15, 0.45 }) do
				c:cone(V3(0.14, 0.20, 0.12), CF(x, -0.74, 1.22) * ANG(PI, 0, 0), BONE)
			end
			c:box(V3(0.40, 0.36, 0.06), CF(0, -0.42, 1.31), TIMBER, WOOD)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.50, 0.46, 0.06), CF(0.42 * s, 0.38, 0.81), INK)
				c:eye(V3(0.42 * s, 0.38, 0.86), 0.17, p.glow)
				c:box(V3(0.12, 0.10, 0.04), CF(0.25 * s, -0.12, 1.31), INK)
				c:cone(V3(0.30, 0.90, 0.30), CF(0.75 * s, 0.95, -0.45) * ANG(-0.8, 0, -0.3 * s), p.light)
				-- A tower, its roof, flag and lit window.
				c:cyl(V3(0.70, 0.44, 0.44), CF(0.62 * s, 1.15, -0.35) * ANG(0, 0, PI / 2), STONE)
				c:cone(V3(0.56, 0.44, 0.56), CF(0.62 * s, 1.72, -0.35), p.deep)
				c:rod(V3(0.62 * s, 1.88, -0.35), V3(0.62 * s, 2.14, -0.35), 0.025, GOLD, METAL, false)
				c:box(V3(0.24, 0.16, 0.04), CF(0.62 * s + 0.12, 2.06, -0.35), p.glow, NEON)
				c:box(V3(0.10, 0.18, 0.04), CF(0.62 * s, 1.20, -0.12), AMBER, NEON)
				for _, z in ipairs({ 0.45, -0.45 }) do
					c:box(V3(0.40, 0.30, 0.45), CF(0.60 * s, -0.65, z), p.dark)
				end
			end
			c:box(V3(1.40, 0.40, 0.80), CF(0, 0.95, -0.15), STONE)
			for _, x in ipairs({ -0.50, 0, 0.50 }) do
				c:box(V3(0.24, 0.18, 0.20), CF(x, 1.24, 0.15), STONE)
			end
		end,
	}

	-- A colossal crowned statue head rising out of the rubble of its temple,
	-- vines on its cheeks, glowing cracks, a hand either side holding a coin
	-- and an emerald up to the light.
	S.df_t_colossus = {
		label = "Crowned Colossus",
		set = SET,
		tint = C3(170, 160, 140),
		scale = 1.10,
		head = CF(0, 1.62, 0),
		neck = CF(0, -0.60, 0.80),
		back = CF(0, 0.30, -0.70),
		build = function(c, p)
			c:box(V3(2.30, 0.40, 1.80), CF(0, -0.85, 0), p.dark)
			c:box(V3(1.50, 1.60, 1.30), CF(0, 0.15, 0), p.base)
			c:box(V3(1.56, 0.20, 0.20), CF(0, 0.74, 0.62), p.dark)
			c:box(V3(0.30, 0.50, 0.25), CF(0, 0.20, 0.74), p.light)
			c:eyes(0.38, 0.68, 0.34, 0.17)
			c:box(V3(0.50, 0.08, 0.04), CF(0, -0.14, 0.66), INK)
			c:box(V3(0.90, 0.40, 0.24), CF(0, -0.46, 0.66), p.dark)
			-- The crown.
			c:box(V3(1.60, 0.30, 1.40), CF(0, 1.10, 0), GOLD, METAL)
			for i, x in ipairs({ -0.55, 0, 0.55 }) do
				c:cone(V3(0.30, 0.40, 0.30), CF(x, 1.45, 0.50), GOLD, METAL)
				c:box(V3(0.16, 0.16, 0.06), CF(x, 1.10, 0.72) * ANG(0, 0, PI / 4), i == 2 and RUBY or p.glow, NEON)
			end
			for _, x in ipairs({ -0.55, 0.55 }) do
				c:cone(V3(0.30, 0.40, 0.30), CF(x, 1.45, -0.50), GOLD, METAL)
			end
			-- Cracks, vines and rubble.
			c:box(V3(0.06, 0.50, 0.04), CF(-0.55, -0.05, 0.66) * ANG(0, 0, 0.5), p.glow, NEON)
			c:box(V3(0.05, 0.36, 0.04), CF(0.60, 0.10, 0.66) * ANG(0, 0, -0.4), p.glow, NEON)
			c:box(V3(0.06, 0.90, 0.30), CF(0.76, 0.20, 0.30), LEAF)
			c:box(V3(0.20, 0.16, 0.06), CF(0.66, 0.45, 0.66), LEAF)
			c:box(V3(0.06, 0.70, 0.26), CF(-0.76, 0.30, -0.20), LEAF)
			c:box(V3(0.50, 0.40, 0.50), CF(0.80, -0.55, 0.78) * ANG(0.2, 0.5, 0.1), p.deep)
			c:box(V3(0.44, 0.36, 0.44), CF(-1.00, -0.60, -0.40) * ANG(0.1, 0.3, 0.2), p.deep)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.40, 0.50, 0.40), CF(1.05 * s, -0.40, 0.25), p.base)
			end
			c:cyl(V3(0.08, 0.40, 0.40), CF(1.05, -0.05, 0.30) * ANG(0, 0, PI / 2), COIN, METAL)
			c:box(V3(0.24, 0.24, 0.24), CF(-1.05, -0.02, 0.30) * ANG(0.6, 0.6, 0), EMERALD, NEON)
			c:box(V3(0.24, 0.24, 0.24), CF(0.95, 1.55, -0.30) * ANG(0.4, 0.4, 0.4), p.dark)
			c:box(V3(0.20, 0.20, 0.20), CF(-0.95, 1.40, 0.20) * ANG(0.5, 0.2, 0.3), p.dark)
			c:box(V3(0.12, 0.12, 0.04), CF(0, 1.85, 0.10) * ANG(0, 0, PI / 4), p.glow, NEON)
			c:light(p.glow, 1.0, 7)
		end,
	}

	-- A great jewel from the bottom of the hoard, with a dragon's heart: a
	-- faceted gem with a face, a gold setting, little wings, horns, and a
	-- ring of scales orbiting beneath it.
	S.df_t_heartgem = {
		label = "Dragonheart Gem",
		set = SET,
		tint = C3(230, 20, 90),
		scale = 1.20,
		head = CF(0, 1.00, 0),
		neck = CF(0, -0.40, 0.86),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			c:box(V3(1.90, 0.70, 1.60), CF(0, 0.25, 0), p.base)
			c:box(V3(1.30, 0.30, 1.10), CF(0, 0.75, 0), p.light)
			c:cone(V3(1.80, 1.30, 1.50), CF(0, -0.75, 0) * ANG(PI, 0, 0), p.dark)
			c:eyes(0.30, 0.82, 0.36, 0.18)
			c:box(V3(0.36, 0.08, 0.04), CF(0, 0.02, 0.81), INK)
			c:box(V3(0.08, 0.40, 0.04), CF(-0.72, 0.30, 0.81) * ANG(0, 0, 0.4), WHITE, NEON)
			c:box(V3(0.06, 0.22, 0.04), CF(-0.56, 0.40, 0.81) * ANG(0, 0, 0.4), WHITE, NEON)
			c:box(V3(1.96, 0.10, 1.66), CF(0, -0.08, 0), GOLD, METAL)
			for _, sx in ipairs(SIDES) do
				for _, sz in ipairs(SIDES) do
					c:box(V3(0.14, 0.80, 0.14), CF(0.92 * sx, 0.18, 0.77 * sz), GOLD, METAL)
				end
				c:box(V3(0.10, 0.70, 0.80), CF(1.20 * sx, 0.55, -0.30) * ANG(0, 0.30 * sx, -0.45 * sx), p.deep)
				c:rod(V3(0.90 * sx, 0.40, -0.25), V3(1.45 * sx, 0.95, -0.45), 0.05, p.light, nil, false)
				c:cone(V3(0.16, 0.36, 0.16), CF(0.40 * sx, 1.05, 0), p.pale)
			end
			for k = 0, 5 do
				local a = k * PI / 3 + PI / 6
				local lit = k % 2 == 0
				c:box(V3(0.22, 0.30, 0.06), CF(1.30 * math.sin(a), -0.60, 1.05 * math.cos(a)) * ANG(0, a, PI / 4), lit and p.glow or p.light, lit and NEON or nil)
			end
			c:sparkle(p.glow, 3, 0.5, 0.2)
			c:light(p.glow, 1.5, 9)
		end,
	}

	-- A knight's great helm that walks about on its own: the visor is its
	-- face, a glowing dragon crest and wing plates, gauntlets, boots, a
	-- shield, a banner and a cape.
	S.df_t_helm = {
		label = "Scalemail Helm",
		set = SET,
		tint = C3(190, 200, 220),
		scale = 1.15,
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.50, 0.84),
		back = CF(0, 0.30, -0.84),
		build = function(c, p)
			c:box(V3(1.60, 1.60, 1.60), CF(0, 0.15, 0), p.base, METAL)
			c:box(V3(1.66, 0.20, 1.66), CF(0, 0.60, 0), p.dark, METAL)
			c:box(V3(1.20, 0.46, 0.06), CF(0, 0.22, 0.81), INK)
			c:eyes(0.24, 0.86, 0.28, 0.16, p.glow)
			c:box(V3(0.14, 1.60, 0.14), CF(0, 0.15, 0.80), p.light, METAL)
			for _, x in ipairs({ -0.36, -0.20, 0.20, 0.36 }) do
				c:box(V3(0.08, 0.36, 0.04), CF(x, -0.30, 0.81), p.dark, METAL)
			end
			for i, z in ipairs({ 0.45, 0.10, -0.25, -0.60 }) do
				c:cone(V3(0.14, 0.50 - i * 0.06, 0.40), CF(0, 1.20 - i * 0.03, z), p.glow, NEON)
			end
			for _, s in ipairs(SIDES) do
				c:box(V3(0.10, 0.80, 0.90), CF(0.95 * s, 0.85, -0.20) * ANG(0, 0.20 * s, -0.40 * s), p.light, METAL)
				c:box(V3(0.10, 0.50, 0.60), CF(1.15 * s, 1.15, -0.40) * ANG(0, 0.25 * s, -0.70 * s), p.deep, METAL)
				c:box(V3(0.30, 0.50, 0.30), CF(0.95 * s, -0.25, 0.20), p.dark, METAL)
				c:box(V3(0.42, 0.30, 0.56), CF(0.40 * s, -0.80, 0.10), p.dark, METAL)
				c:box(V3(0.10, 0.20, 0.20), CF(0.81 * s, 0.30, 0.0) * ANG(PI / 4, 0, 0), s < 0 and RUBY or SAPPHIRE, NEON)
			end
			-- Shield on one arm, a banner in the other, a cape behind.
			c:box(V3(0.10, 0.80, 0.70), CF(-1.16, -0.20, 0.30), p.deep, METAL)
			c:box(V3(0.04, 0.30, 0.30), CF(-1.22, -0.18, 0.30) * ANG(PI / 4, 0, 0), p.glow, NEON)
			c:rod(V3(1.10, -0.55, 0.30), V3(1.10, 1.00, 0.30), 0.05, TIMBER, WOOD, false)
			c:box(V3(0.04, 0.45, 0.40), CF(1.10, 0.75, 0.52), p.pale)
			c:box(V3(1.40, 1.20, 0.08), CF(0, 0.0, -0.85), p.deep)
			c:box(V3(0.12, 0.12, 0.04), CF(-0.90, 1.35, 0.30) * ANG(0, 0, PI / 4), p.glow, NEON)
			c:box(V3(0.10, 0.10, 0.04), CF(0.80, 1.55, -0.20) * ANG(0, 0, PI / 4), p.glow, NEON)
		end,
	}

	-- A three-roofed pagoda that walks the ruins: a face on its ground floor,
	-- upturned eaves hung with bells, a gold spire with a pearl, and a dragon
	-- wound round its middle storey peeking out at the front.
	S.df_t_pagoda = {
		label = "Wyrm Pagoda",
		set = SET,
		tint = C3(40, 170, 150),
		scale = 1.20,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.90, 0.80),
		back = CF(0, -0.40, -0.80),
		build = function(c, p)
			c:box(V3(2.00, 0.20, 2.00), CF(0, -1.15, 0), STONE, SLATE)
			c:box(V3(1.50, 0.90, 1.50), CF(0, -0.60, 0), p.pale)
			c:eyes(-0.42, 0.77, 0.32, 0.17)
			c:box(V3(0.40, 0.24, 0.04), CF(0, -0.82, 0.76), INK)
			c:box(V3(2.00, 0.14, 2.00), CF(0, -0.08, 0), p.base)
			c:box(V3(1.10, 0.55, 1.10), CF(0, 0.27, 0), p.pale)
			c:box(V3(1.60, 0.12, 1.60), CF(0, 0.60, 0), p.base)
			c:box(V3(0.80, 0.45, 0.80), CF(0, 0.88, 0), p.pale)
			c:box(V3(1.20, 0.12, 1.20), CF(0, 1.16, 0), p.base)
			c:rod(V3(0, 1.22, 0), V3(0, 1.66, 0), 0.04, GOLD, METAL, false)
			c:box(V3(0.20, 0.04, 0.20), CF(0, 1.36, 0), GOLD, METAL)
			c:box(V3(0.16, 0.04, 0.16), CF(0, 1.50, 0), GOLD, METAL)
			c:ball(V3(0.20, 0.20, 0.20), CF(0, 1.72, 0), p.glow, NEON)
			for _, sx in ipairs(SIDES) do
				for _, sz in ipairs(SIDES) do
					c:cone(V3(0.20, 0.30, 0.20), CF(1.00 * sx, 0.02, 1.00 * sz) * ANG(0.4 * sz, 0, -0.4 * sx), p.light)
					c:cone(V3(0.16, 0.26, 0.16), CF(0.80 * sx, 0.68, 0.80 * sz) * ANG(0.4 * sz, 0, -0.4 * sx), p.light)
				end
				c:box(V3(0.12, 0.16, 0.12), CF(0.90 * sx, -0.25, 0.90), GOLD, METAL)
				c:box(V3(0.80, 0.24, 0.50), CF(1.20 * sx, -0.50, -0.40 * sx), CLOUD)
			end
			-- The dragon wound round its middle storey.
			c:box(V3(0.24, 0.24, 1.30), CF(0.62, 0.20, 0), p.dark)
			c:box(V3(1.30, 0.24, 0.24), CF(0, 0.32, -0.62), p.dark)
			c:box(V3(0.24, 0.24, 1.10), CF(-0.62, 0.40, 0.08), p.dark)
			c:box(V3(0.34, 0.30, 0.40), CF(-0.50, 0.42, 0.70), p.dark)
			c:box(V3(0.06, 0.06, 0.06), CF(-0.42, 0.48, 0.91), p.glow, NEON)
			c:cone(V3(0.16, 0.30, 0.16), CF(0.62, 0.16, 0.72) * ANG(PI / 2, 0, 0), p.light)
		end,
	}

	-- The great round door of the Dragon King's Vault, walking on stubby
	-- feet: a ring of gold bolts, a spoked wheel for a nose, a glowing crest,
	-- hinges, horns on its frame and coins spilling out at its feet.
	S.df_t_vault = {
		label = "Wyrmvault Door",
		set = SET,
		tint = C3(120, 130, 160),
		scale = 1.10,
		head = CF(0, 1.16, -0.10),
		neck = CF(0, -0.90, 0.50),
		back = CF(0, 0.20, -0.36),
		build = function(c, p)
			c:box(V3(2.20, 2.20, 0.40), CF(0, 0, -0.10), p.dark, SLATE)
			c:cyl(V3(0.32, 1.90, 1.90), CF(0, 0, 0.16) * ANG(0, PI / 2, 0), p.light, METAL)
			c:cyl(V3(0.34, 1.70, 1.70), CF(0, 0, 0.18) * ANG(0, PI / 2, 0), p.base, METAL)
			for k = 0, 7 do
				local a = k * PI / 4 + PI / 8
				c:box(V3(0.18, 0.18, 0.10), CF(0.75 * math.sin(a), 0.75 * math.cos(a), 0.37) * ANG(0, 0, -a), GOLD, METAL)
			end
			c:cyl(V3(0.14, 0.30, 0.30), CF(0, -0.30, 0.40) * ANG(0, PI / 2, 0), GOLD, METAL)
			for k = 0, 2 do
				c:box(V3(0.86, 0.07, 0.07), CF(0, -0.30, 0.42) * ANG(0, 0, k * PI / 3), GOLD, METAL)
			end
			c:eyes(0.30, 0.38, 0.30, 0.17)
			c:box(V3(0.22, 0.22, 0.04), CF(0, 0.58, 0.36) * ANG(0, 0, PI / 4), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.20, 0.30, 0.30), CF(-1.12, 0.50 * s, 0.10), p.deep, METAL)
				c:cone(V3(0.26, 0.50, 0.26), CF(0.95 * s, 1.30, -0.10) * ANG(0, 0, -0.4 * s), p.light)
				c:box(V3(0.50, 0.20, 0.60), CF(0.70 * s, -1.20, 0), p.deep)
			end
			c:cyl(V3(0.06, 0.36, 0.36), CF(-0.40, -1.27, 0.45) * ANG(0, 0, PI / 2), COIN, METAL)
			c:cyl(V3(0.06, 0.36, 0.36), CF(0.15, -1.27, 0.60) * ANG(0, 0, PI / 2), COIN, METAL)
			c:cyl(V3(0.06, 0.32, 0.32), CF(0.55, -1.18, 0.40) * ANG(0.4, 0, 1.2), COIN, METAL)
			c:box(V3(0.18, 0.18, 0.18), CF(-0.10, -1.20, 0.40) * ANG(0.5, 0.5, 0), RUBY, NEON)
			c:light(p.glow, 0.8, 6)
		end,
	}

	-- The dragon's lair itself, awake: a rocky hill whose cave mouth glows
	-- with gold behind stalactite teeth, eyes above it, crystals on its
	-- slopes, smoke from its top, and its dragon's tail and wings peeking over.
	S.df_t_lair = {
		label = "Dragonlair Cavern",
		set = SET,
		tint = C3(120, 60, 50),
		scale = 1.15,
		head = CF(0.10, 1.10, 0),
		neck = CF(0, -0.60, 1.00),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(2.20, 0.80, 1.80), CF(0, -0.70, 0), p.dark)
			c:box(V3(1.80, 0.70, 1.50), CF(0, 0.0, 0), p.base)
			c:box(V3(1.20, 0.50, 1.10), CF(0, 0.55, 0), p.dark)
			c:box(V3(0.70, 0.30, 0.60), CF(0.10, 0.90, 0), p.base)
			c:box(V3(1.10, 0.60, 0.06), CF(0, -0.80, 0.91), INK)
			c:box(V3(0.70, 0.20, 0.06), CF(0, -0.42, 0.91), INK)
			c:box(V3(0.90, 0.20, 0.10), CF(0, -1.00, 0.92), GOLD, METAL)
			c:cyl(V3(0.06, 0.34, 0.34), CF(-0.35, -1.07, 1.12) * ANG(0, 0, PI / 2), COIN, METAL)
			c:cyl(V3(0.06, 0.30, 0.30), CF(0.30, -1.07, 1.18) * ANG(0, 0, PI / 2), COIN, METAL)
			c:box(V3(0.18, 0.18, 0.18), CF(0.05, -0.92, 1.00) * ANG(0.5, 0.5, 0), RUBY, NEON)
			for _, x in ipairs({ -0.35, 0, 0.35 }) do
				c:cone(V3(0.14, 0.24, 0.10), CF(x, -0.42, 0.95) * ANG(PI, 0, 0), BONE)
			end
			c:eyes(0.10, 0.77, 0.40, 0.19)
			for _, v in ipairs({ { 1.00, -0.20, 0.30, -0.4 }, { -1.05, -0.35, -0.20, 0.5 }, { 0.70, 0.45, -0.40, -0.3 } }) do
				c:cone(V3(0.24, 0.50, 0.24), CF(v[1], v[2], v[3]) * ANG(0, 0, v[4]), p.glow, NEON)
			end
			c:box(V3(0.30, 0.30, 0.70), CF(-0.40, 0.95, -0.55) * ANG(0.5, 0, 0), p.deep)
			c:cone(V3(0.24, 0.36, 0.10), CF(-0.40, 1.30, -0.85), p.light)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.08, 0.60, 0.70), CF(1.00 * s, 0.50, -0.70) * ANG(0, 0, -0.4 * s), p.deep)
			end
			c:ball(V3(0.34, 0.34, 0.34), CF(0.10, 1.25, 0), CLOUD)
			c:ball(V3(0.26, 0.26, 0.26), CF(0.25, 1.52, -0.10), CLOUD)
			c:box(V3(0.40, 0.06, 0.30), CF(-0.60, 0.36, 0.40), LEAF)
			c:light(GOLD, 1.0, 6)
		end,
	}

	-- A carousel of little dragons that turns by itself: a face on its
	-- centre post, four gold poles with dragon riders bobbing up and down, a
	-- scalloped canopy hung with lights and a flag on top.
	S.df_t_carousel = {
		label = "Wyrm Carousel",
		set = SET,
		tint = C3(255, 120, 200),
		scale = 1.15,
		head = CF(0, 1.50, 0),
		neck = CF(0, -0.70, 0.50),
		back = CF(0, -0.20, -0.50),
		build = function(c, p)
			c:cyl(V3(0.20, 2.20, 2.20), CF(0, -1.00, 0) * ANG(0, 0, PI / 2), p.dark)
			c:cyl(V3(0.10, 2.30, 2.30), CF(0, -0.88, 0) * ANG(0, 0, PI / 2), p.light)
			c:box(V3(0.90, 1.40, 0.90), CF(0, -0.15, 0), p.base)
			c:eyes(0.10, 0.47, 0.24, 0.16)
			c:box(V3(0.28, 0.06, 0.04), CF(0, -0.20, 0.46), INK)
			c:cyl(V3(0.16, 2.20, 2.20), CF(0, 0.66, 0) * ANG(0, 0, PI / 2), p.light)
			c:cone(V3(2.00, 0.70, 2.00), CF(0, 1.09, 0), p.base)
			c:rod(V3(0, 1.40, 0), V3(0, 1.80, 0), 0.03, GOLD, METAL, false)
			c:box(V3(0.30, 0.20, 0.04), CF(0.16, 1.70, 0), p.glow, NEON)
			for k = 0, 3 do
				local a = k * PI / 2
				local b = a + PI / 4
				c:box(V3(0.30, 0.16, 0.06), CF(1.06 * math.sin(a), 0.52, 1.06 * math.cos(a)) * ANG(0, a, 0), p.pale)
				c:ball(V3(0.12, 0.12, 0.12), CF(1.05 * math.sin(b), 0.56, 1.05 * math.cos(b)), p.glow, NEON)
				-- A pole and its dragon rider, each bobbing at its own height.
				local px, pz = 0.78 * math.sin(b), 0.78 * math.cos(b)
				local y = k % 2 == 0 and -0.20 or 0.10
				local hue = k % 2 == 0 and p.deep or p.glow
				c:rod(V3(px, -0.88, pz), V3(px, 0.60, pz), 0.04, GOLD, METAL, false)
				c:box(V3(0.24, 0.26, 0.46), CF(px, y, pz) * ANG(0, b + PI / 2, 0), hue)
				c:box(V3(0.20, 0.20, 0.20), CF(px + 0.24 * math.cos(b), y + 0.16, pz - 0.24 * math.sin(b)), hue)
			end
		end,
	}

	return S
end
