--[[ PetBodies/ShogunsOathTop -- Shogun's Oath's top bodies. See tools/gen/sets/README.md.

	Epic and up: each body here is worn by exactly ONE pet in the game, so no
	two share a silhouette. The set is Japan: weapons and honour, lacquer, gold
	leaf waves, folk toys and friendly yokai. Epic stays charming and clean
	(folk toys, tea things, little yokai); Legendary gets lacquer and gold;
	Mythic, Divine and Exotic get neon gold leaf, halos and auras, echoing the
	top packs "Shogun's Treasury" and "Thousand-Year Katana". All cute, bloodless.
]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, WHITE, METAL, NEON, WOOD = K.INK, K.WHITE, K.METAL, K.NEON, K.WOOD
	local S = {}

	local SIDES = { -1, 1 }
	local UP = CFrame.Angles(0, 0, math.pi / 2) -- a cylinder standing up
	local FRONT = CFrame.Angles(0, math.pi / 2, 0) -- a cylinder's flat face to the front
	local GOLD, GOLD_DARK = C3(236, 190, 76), C3(190, 140, 44)
	local LACQ, SUMI, WASHI = C3(170, 26, 34), C3(30, 28, 34), C3(250, 244, 228)
	local STEEL, TIMBER, ROPE = C3(200, 208, 222), C3(186, 136, 82), C3(214, 188, 130)
	local RED, BLUSH, TONGUE = C3(214, 40, 52), C3(255, 150, 170), C3(240, 110, 140)
	local LEAF, SKY, BEAK = C3(70, 160, 70), C3(120, 200, 255), C3(250, 186, 60)

	-- Rosy cheeks either side of a face.
	local function blush(c, x, y, z)
		for _, s in ipairs(SIDES) do
			c:box(Vector3.new(0.20, 0.10, 0.05), CFrame.new(x * s, y, z), BLUSH)
		end
	end

	-- A floating square halo of four glowing bars.
	local function halo(c, y, z, r, colour)
		c:box(Vector3.new(r * 2 + 0.10, 0.08, 0.10), CFrame.new(0, y, z + r), colour, NEON)
		c:box(Vector3.new(r * 2 + 0.10, 0.08, 0.10), CFrame.new(0, y, z - r), colour, NEON)
		c:box(Vector3.new(0.10, 0.08, r * 2), CFrame.new(-r, y, z), colour, NEON)
		c:box(Vector3.new(0.10, 0.08, r * 2), CFrame.new(r, y, z), colour, NEON)
	end

	-- A gold-leaf wave crest (seigaiha): three stacked half-discs facing front.
	local function seigaiha(c, x, y, z, d, colour)
		c:cyl(Vector3.new(0.05, d, d), CFrame.new(x, y, z) * FRONT, colour, METAL)
		c:cyl(Vector3.new(0.05, d * 0.66, d * 0.66), CFrame.new(x, y, z + 0.03) * FRONT, WASHI)
		c:cyl(Vector3.new(0.05, d * 0.34, d * 0.34), CFrame.new(x, y, z + 0.06) * FRONT, colour, METAL)
	end

	----------------------------------------------------------------------------
	-- EPIC: charming and clean.
	----------------------------------------------------------------------------

	-- A kokeshi: a turned-wood doll, a big round head on a kimono'd post with an
	-- obi, painted flowers, a bob of black hair and a flower hairpin.
	S.so_t_kokeshi = {
		label = "Kokeshi Doll",
		set = "shoguns_oath",
		tint = C3(40, 170, 170),
		head = CFrame.new(0, 1.50, 0),
		neck = CFrame.new(0, -0.20, 0.66),
		back = CFrame.new(0, 0.10, -0.86),
		build = function(c, p)
			c:cyl(Vector3.new(1.10, 1.20, 1.20), CFrame.new(0, -0.48, 0) * UP, p.base)
			c:cyl(Vector3.new(0.14, 1.36, 1.36), CFrame.new(0, -1.00, 0) * UP, p.deep)
			c:cyl(Vector3.new(0.28, 1.26, 1.26), CFrame.new(0, -0.38, 0) * UP, p.dark)
			c:ball(Vector3.new(1.70, 1.70, 1.70), CFrame.new(0, 0.55, 0), p.pale)
			c:round(Vector3.new(1.76, 0.80, 1.76), CFrame.new(0, 1.06, -0.06), SUMI)
			c:box(Vector3.new(0.90, 0.24, 0.10), CFrame.new(0, 0.98, 0.70), SUMI)
			for _, s in ipairs(SIDES) do
				c:round(Vector3.new(0.30, 1.00, 0.90), CFrame.new(0.80 * s, 0.50, -0.12), SUMI)
			end
			c:eyes(0.58, 0.80, 0.28, 0.10)
			blush(c, 0.48, 0.36, 0.76)
			c:box(Vector3.new(0.16, 0.08, 0.06), CFrame.new(0, 0.30, 0.83), RED)
			for _, v in ipairs({ { -0.30, -0.70 }, { 0.28, -0.84 }, { 0.02, -0.62 } }) do
				c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(v[1], v[2], 0.58), p.light)
			end
			c:ball(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0.52, 1.30, 0.24), BLUSH)
			c:ball(Vector3.new(0.12, 0.12, 0.12), CFrame.new(0.52, 1.30, 0.40), GOLD, METAL)
		end,
	}

	-- Bunbuku chagama: a tanuki who turned into an iron tea kettle, his masked
	-- face, ears, feet and striped tail poking out, a lid and an arched handle.
	S.so_t_tanuki = {
		label = "Kettle Tanuki",
		set = "shoguns_oath",
		tint = C3(176, 110, 60),
		scale = 1.12,
		head = CFrame.new(0, 1.06, 0),
		neck = CFrame.new(0, -0.40, 1.00),
		back = CFrame.new(0, 0.10, -1.10),
		build = function(c, p)
			local iron = C3(70, 66, 72)
			c:cyl(Vector3.new(1.20, 2.00, 2.00), CFrame.new(0, -0.30, 0) * UP, iron)
			c:cyl(Vector3.new(0.16, 2.12, 2.12), CFrame.new(0, 0.32, 0) * UP, p.deep)
			c:cyl(Vector3.new(0.16, 1.20, 1.20), CFrame.new(0, 0.46, 0) * UP, iron)
			c:ball(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0, 0.64, 0), GOLD, METAL)
			c:rod(Vector3.new(-0.90, 0.36, 0), Vector3.new(-0.50, 1.00, 0), 0.05, p.deep, nil, false)
			c:rod(Vector3.new(-0.50, 1.00, 0), Vector3.new(0.50, 1.00, 0), 0.05, p.deep, nil, false)
			c:rod(Vector3.new(0.50, 1.00, 0), Vector3.new(0.90, 0.36, 0), 0.05, p.deep, nil, false)
			c:round(Vector3.new(1.24, 1.00, 0.50), CFrame.new(0, 0.10, 0.90), p.base)
			c:box(Vector3.new(1.00, 0.30, 0.10), CFrame.new(0, 0.20, 1.13), p.deep)
			c:eyes(0.20, 1.18, 0.26, 0.11)
			c:round(Vector3.new(0.44, 0.30, 0.24), CFrame.new(0, -0.08, 1.16), p.pale)
			c:ball(Vector3.new(0.14, 0.14, 0.14), CFrame.new(0, 0.00, 1.28), INK)
			for _, s in ipairs(SIDES) do
				c:round(Vector3.new(0.30, 0.30, 0.16), CFrame.new(0.42 * s, 0.66, 0.86), p.base)
				for _, z in ipairs({ 0.50, -0.50 }) do
					c:round(Vector3.new(0.44, 0.30, 0.50), CFrame.new(0.62 * s, -0.94, z), p.base)
				end
			end
			c:round(Vector3.new(0.50, 0.50, 0.90), CFrame.new(0, -0.30, -1.20), p.base)
			c:box(Vector3.new(0.54, 0.54, 0.10), CFrame.new(0, -0.30, -1.06), p.deep)
			c:box(Vector3.new(0.48, 0.48, 0.10), CFrame.new(0, -0.30, -1.36), p.deep)
		end,
	}

	-- A fukura suzume: a sparrow puffed round against the winter cold, a lucky
	-- charm, with a brown cap, black cheek dots, a little bib and a plum blossom.
	S.so_t_sparrow = {
		label = "Fukura Sparrow",
		set = "shoguns_oath",
		tint = C3(236, 150, 80),
		head = CFrame.new(0, 1.12, 0),
		neck = CFrame.new(0, -0.40, 0.90),
		back = CFrame.new(0, 0.10, -1.00),
		build = function(c, p)
			c:round(Vector3.new(2.00, 1.84, 1.90), CFrame.new(0, 0, 0), p.base)
			c:round(Vector3.new(1.50, 0.60, 1.40), CFrame.new(0, 0.82, -0.05), p.dark)
			c:round(Vector3.new(1.50, 0.90, 0.20), CFrame.new(0, 0.14, 0.86), p.pale)
			c:round(Vector3.new(0.50, 0.30, 0.12), CFrame.new(0, -0.30, 0.94), INK)
			c:eyes(0.32, 0.98, 0.34, 0.11)
			c:cone(Vector3.new(0.22, 0.26, 0.22), CFrame.new(0, 0.10, 1.06) * CFrame.Angles(math.pi / 2, 0, 0), BEAK)
			for _, s in ipairs(SIDES) do
				c:round(Vector3.new(0.22, 0.20, 0.08), CFrame.new(0.62 * s, 0.02, 0.92), INK)
				c:round(Vector3.new(0.30, 0.90, 1.10), CFrame.new(1.00 * s, -0.05, -0.10) * CFrame.Angles(0, 0, 0.12 * s), p.dark)
				c:box(Vector3.new(0.06, 0.10, 0.80), CFrame.new(1.16 * s, 0.05, -0.10), WASHI)
				c:box(Vector3.new(0.12, 0.20, 0.30), CFrame.new(0.32 * s, -0.98, 0.20), BEAK)
			end
			c:box(Vector3.new(0.50, 0.12, 0.50), CFrame.new(0, 0.10, -1.05) * CFrame.Angles(0.5, 0, 0), p.deep)
			c:ball(Vector3.new(0.26, 0.26, 0.26), CFrame.new(0.40, 1.12, 0.20), BLUSH)
			c:ball(Vector3.new(0.10, 0.10, 0.10), CFrame.new(0.40, 1.14, 0.32), GOLD)
		end,
	}

	-- A shuriken that spins on its own: four bright points round a hub with a
	-- cheeky face, a gold rivet behind and a red tassel swinging below.
	S.so_t_shuriken = {
		label = "Shuriken Spinner",
		set = "shoguns_oath",
		tint = C3(120, 150, 210),
		head = CFrame.new(0, 1.30, 0),
		neck = CFrame.new(0, -0.50, 0.30),
		back = CFrame.new(0, 0.10, -0.30),
		build = function(c, p)
			c:cyl(Vector3.new(0.36, 1.20, 1.20), CFrame.new(0, 0.10, 0) * FRONT, p.base)
			for i = 0, 3 do
				local a = i * math.pi / 2 + math.pi / 4
				c:cone(Vector3.new(0.70, 0.90, 0.30), CFrame.new(0, 0.10, 0) * CFrame.Angles(0, 0, a) * CFrame.new(0, 0.95, 0), p.light, METAL)
			end
			c:cyl(Vector3.new(0.06, 0.90, 0.90), CFrame.new(0, 0.10, 0.20) * FRONT, p.pale)
			c:cyl(Vector3.new(0.10, 0.50, 0.50), CFrame.new(0, 0.10, -0.20) * FRONT, GOLD, METAL)
			c:eyes(0.20, 0.26, 0.20, 0.10)
			blush(c, 0.30, 0.02, 0.24)
			c:box(Vector3.new(0.16, 0.06, 0.04), CFrame.new(0, -0.10, 0.24), INK)
			c:rod(Vector3.new(0, -0.50, 0), Vector3.new(0, -1.00, 0), 0.04, RED, nil, false)
			c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(0, -1.06, 0), RED)
		end,
	}

	-- An onigiri: a triangle of rice in a nori wrap, an umeboshi plum on top,
	-- stray grains, stubby arms and feet.
	S.so_t_onigiri = {
		label = "Nori Onigiri",
		set = "shoguns_oath",
		tint = C3(248, 246, 236),
		head = CFrame.new(0, 1.20, 0),
		neck = CFrame.new(0, -0.40, 0.76),
		back = CFrame.new(0, 0, -0.76),
		build = function(c, p)
			c:prism(Vector3.new(1.40, 2.00, 2.30), CFrame.new(0, 0, 0) * FRONT, p.base)
			c:box(Vector3.new(1.20, 0.86, 1.50), CFrame.new(0, -0.54, 0), C3(28, 50, 38))
			c:eyes(0.26, 0.74, 0.28, 0.12)
			blush(c, 0.46, 0.08, 0.72)
			c:box(Vector3.new(0.18, 0.08, 0.05), CFrame.new(0, 0.04, 0.72), INK)
			c:ball(Vector3.new(0.38, 0.38, 0.38), CFrame.new(0, 1.00, 0), C3(220, 40, 70))
			c:box(Vector3.new(0.10, 0.04, 0.24), CFrame.new(0.10, 1.20, 0) * CFrame.Angles(0, 0, 0.4), LEAF)
			for _, v in ipairs({ { -0.36, 0.52, 0.72 }, { 0.40, 0.40, 0.72 }, { 0.10, 0.60, -0.72 } }) do
				c:box(Vector3.new(0.08, 0.14, 0.04), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0, 0, 0.5), p.light)
			end
			for _, s in ipairs(SIDES) do
				c:round(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0.96 * s, -0.50, 0.20), p.base)
				c:round(Vector3.new(0.40, 0.24, 0.46), CFrame.new(0.46 * s, -1.06, 0.10), p.dark)
			end
		end,
	}

	-- A bake-zori: a wooden geta clog come to life, on its two tall teeth, a red
	-- thong strap on top, a tongue sticking out and little waving arms.
	S.so_t_geta = {
		label = "Geta Hopper",
		set = "shoguns_oath",
		tint = C3(214, 168, 104),
		head = CFrame.new(0, 0.60, -0.20),
		neck = CFrame.new(0, -0.30, 1.10),
		back = CFrame.new(0, 0, -1.10),
		build = function(c, p)
			c:box(Vector3.new(1.60, 0.70, 2.00), CFrame.new(0, 0, 0), p.base)
			for _, z in ipairs({ 0.56, -0.56 }) do
				c:box(Vector3.new(1.40, 0.50, 0.30), CFrame.new(0, -0.58, z), p.dark)
			end
			c:box(Vector3.new(1.20, 0.04, 0.06), CFrame.new(0, 0.36, -0.30), p.dark)
			c:box(Vector3.new(1.20, 0.04, 0.06), CFrame.new(0, 0.36, 0.20), p.dark)
			c:rod(Vector3.new(-0.60, 0.36, -0.40), Vector3.new(0, 0.50, 0.60), 0.06, RED, nil, false)
			c:rod(Vector3.new(0.60, 0.36, -0.40), Vector3.new(0, 0.50, 0.60), 0.06, RED, nil, false)
			c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0, 0.52, 0.62), RED)
			c:eyes(0.10, 1.04, 0.36, 0.13)
			blush(c, 0.62, -0.10, 1.02)
			c:box(Vector3.new(0.30, 0.06, 0.30), CFrame.new(0, -0.22, 1.12) * CFrame.Angles(-0.3, 0, 0), TONGUE)
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.80 * s, 0, 0.30), Vector3.new(1.15 * s, 0.40, 0.50), 0.07, p.light)
			end
		end,
	}

	-- A karakasa-obake: a closed paper parasol hopping on its one wooden leg,
	-- one big friendly eye, a long tongue and a little geta for a foot.
	S.so_t_karakasa = {
		label = "Karakasa",
		set = "shoguns_oath",
		tint = C3(60, 80, 200),
		scale = 1.12,
		head = CFrame.new(0, 1.62, 0),
		neck = CFrame.new(0, -0.40, 0.66),
		back = CFrame.new(0, 0, -0.50),
		build = function(c, p)
			c:cone(Vector3.new(1.30, 2.00, 1.30), CFrame.new(0, 0.20, 0), p.base)
			c:box(Vector3.new(1.00, 0.14, 1.00), CFrame.new(0, -0.30, 0), p.dark)
			c:box(Vector3.new(1.50, 0.10, 1.50), CFrame.new(0, -0.78, 0), p.light)
			c:rod(Vector3.new(0, 1.20, 0), Vector3.new(0, 1.56, 0), 0.06, p.deep)
			c:eye(Vector3.new(0, 0.38, 0.36), 0.20)
			c:box(Vector3.new(0.40, 0.07, 0.05), CFrame.new(0, 0.66, 0.30) * CFrame.Angles(-0.6, 0, 0), INK)
			c:box(Vector3.new(0.40, 0.10, 0.06), CFrame.new(0, -0.08, 0.58), INK)
			c:box(Vector3.new(0.26, 0.50, 0.06), CFrame.new(0, -0.34, 0.66) * CFrame.Angles(0.4, 0, 0), TONGUE)
			c:rod(Vector3.new(0, -0.80, 0), Vector3.new(0, -1.24, 0), 0.12, TIMBER)
			c:box(Vector3.new(0.46, 0.12, 0.62), CFrame.new(0, -1.34, 0.06), p.dark)
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.40 * s, -0.10, 0.20), Vector3.new(0.86 * s, 0.24, 0.26), 0.06, p.light, nil, false)
			end
		end,
	}

	-- A kendama: the red ball is the face, perched on the wooden cross with its
	-- two cups held out like arms, the string looping down one side.
	S.so_t_kendama = {
		label = "Kendama Kid",
		set = "shoguns_oath",
		tint = C3(255, 110, 40),
		head = CFrame.new(0, 1.22, 0),
		neck = CFrame.new(0, -0.20, 0.80),
		back = CFrame.new(0, 0.40, -0.80),
		build = function(c, p)
			c:ball(Vector3.new(1.60, 1.60, 1.60), CFrame.new(0, 0.40, 0), p.base)
			c:cyl(Vector3.new(0.14, 1.64, 1.64), CFrame.new(0, 0.40, 0) * UP, WASHI)
			c:eyes(0.66, 0.74, 0.28, 0.12)
			blush(c, 0.46, 0.48, 0.70)
			c:box(Vector3.new(0.20, 0.07, 0.05), CFrame.new(0, 0.24, 0.78), INK)
			c:box(Vector3.new(1.90, 0.40, 0.50), CFrame.new(0, -0.56, 0), TIMBER)
			c:cyl(Vector3.new(0.30, 0.80, 0.80), CFrame.new(-1.06, -0.56, 0), TIMBER)
			c:cyl(Vector3.new(0.30, 0.62, 0.62), CFrame.new(1.04, -0.56, 0), TIMBER)
			c:box(Vector3.new(0.40, 0.60, 0.40), CFrame.new(0, -1.00, 0), TIMBER)
			c:cyl(Vector3.new(0.18, 0.56, 0.56), CFrame.new(0, -1.32, 0) * UP, p.dark)
			c:rod(Vector3.new(0.70, 0.04, 0.10), Vector3.new(0.96, -0.34, 0.10), 0.03, WASHI, nil, false)
		end,
	}

	-- A kappa: a river imp with a water dish on its head ringed by hair, a
	-- yellow beak, a turtle shell on its back and a cucumber held in both hands.
	S.so_t_kappa = {
		label = "River Kappa",
		set = "shoguns_oath",
		tint = C3(60, 190, 110),
		head = CFrame.new(0, 1.16, 0),
		neck = CFrame.new(0, -0.40, 0.90),
		back = CFrame.new(0, 0.10, -1.16),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.70, 1.80, 1.50), mouth = false, tail = false,
				eyeY = 0.26, eyeSpread = 0.36, eyeSize = Vector3.new(0.40, 0.48, 0.20),
				legSize = Vector3.new(0.42, 0.30, 0.46), legX = 0.50, legY = -0.90, legZ = { 0.36, -0.36 },
			})
			c:box(Vector3.new(0.60, 0.22, 0.30), CFrame.new(0, -0.08, 0.86), BEAK)
			c:box(Vector3.new(0.50, 0.12, 0.26), CFrame.new(0, -0.24, 0.84), C3(220, 150, 40))
			c:cyl(Vector3.new(0.16, 1.40, 1.40), CFrame.new(0, 0.94, 0) * UP, p.dark)
			c:cyl(Vector3.new(0.12, 1.00, 1.00), CFrame.new(0, 1.04, 0) * UP, WASHI)
			c:cyl(Vector3.new(0.04, 0.80, 0.80), CFrame.new(0, 1.11, 0) * UP, SKY)
			c:round(Vector3.new(1.50, 1.60, 0.50), CFrame.new(0, 0.06, -0.86), p.deep)
			for _, v in ipairs({ { 0, 0.40 }, { -0.36, -0.20 }, { 0.36, -0.20 } }) do
				c:box(Vector3.new(0.40, 0.40, 0.08), CFrame.new(v[1], v[2], -1.12), p.dark)
			end
			c:round(Vector3.new(1.00, 0.90, 0.12), CFrame.new(0, -0.48, 0.76), C3(240, 220, 140))
			c:rod(Vector3.new(-0.55, -0.50, 0.96), Vector3.new(0.55, -0.26, 0.96), 0.12, LEAF)
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.85 * s, 0, 0.20), Vector3.new(0.55 * s, -0.38, 0.90), 0.08, p.base, nil, false)
			end
		end,
	}

	-- A shogi general: a pentagonal wooden game piece stood up, an inked
	-- character on its chest, a gold rim, a tiny crest and stubby limbs.
	S.so_t_shogi = {
		label = "Shogi General",
		set = "shoguns_oath",
		tint = C3(238, 204, 120),
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, -0.30, 0.40),
		back = CFrame.new(0, 0, -0.40),
		build = function(c, p)
			c:box(Vector3.new(1.60, 1.50, 0.60), CFrame.new(0, -0.25, 0), p.base)
			c:prism(Vector3.new(0.60, 0.80, 1.60), CFrame.new(0, 0.90, 0) * FRONT, p.base)
			c:box(Vector3.new(0.12, 0.20, 0.12), CFrame.new(0, 1.38, 0), GOLD, METAL)
			c:box(Vector3.new(1.62, 0.10, 0.62), CFrame.new(0, -0.98, 0), GOLD, METAL)
			c:eyes(0.24, 0.32, 0.30, 0.12)
			blush(c, 0.52, 0.06, 0.31)
			c:box(Vector3.new(0.18, 0.06, 0.04), CFrame.new(0, 0.04, 0.32), INK)
			c:box(Vector3.new(0.80, 0.08, 0.04), CFrame.new(0, -0.24, 0.32), INK)
			c:box(Vector3.new(0.60, 0.08, 0.04), CFrame.new(0, -0.50, 0.32), INK)
			c:box(Vector3.new(0.86, 0.08, 0.04), CFrame.new(0, -0.78, 0.32), INK)
			c:box(Vector3.new(0.08, 0.56, 0.04), CFrame.new(0, -0.51, 0.33), INK)
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.80 * s, -0.20, 0), Vector3.new(1.10 * s, -0.50, 0.20), 0.07, p.dark, nil, false)
				c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(1.12 * s, -0.52, 0.22), p.dark)
				c:box(Vector3.new(0.36, 0.30, 0.40), CFrame.new(0.40 * s, -1.16, 0), p.dark)
			end
		end,
	}

	-- A jubako: three tiers of red lacquer picnic box with gold bands, a gold
	-- wave in maki-e, a family crest, a lid with chopsticks and little feet.
	S.so_t_jubako = {
		label = "Jubako Stack",
		set = "shoguns_oath",
		tint = C3(196, 30, 50),
		head = CFrame.new(0, 1.30, 0),
		neck = CFrame.new(0, -0.40, 1.00),
		back = CFrame.new(0, 0, -1.00),
		build = function(c, p)
			for _, y in ipairs({ -0.60, 0, 0.60 }) do
				c:box(Vector3.new(1.90, 0.60, 1.90), CFrame.new(0, y, 0), p.base)
			end
			for _, y in ipairs({ -0.30, 0.30, 0.90 }) do
				c:box(Vector3.new(1.94, 0.06, 1.94), CFrame.new(0, y, 0), GOLD, METAL)
			end
			c:box(Vector3.new(1.96, 0.24, 1.96), CFrame.new(0, 1.02, 0), p.dark)
			c:box(Vector3.new(0.06, 0.06, 1.40), CFrame.new(-0.10, 1.18, 0) * CFrame.Angles(0, 0.10, 0), TIMBER)
			c:box(Vector3.new(0.06, 0.06, 1.40), CFrame.new(0.10, 1.18, 0) * CFrame.Angles(0, 0.16, 0), TIMBER)
			c:eyes(0.04, 0.98, 0.34, 0.13)
			blush(c, 0.62, -0.12, 0.96)
			c:box(Vector3.new(0.20, 0.07, 0.05), CFrame.new(0, -0.14, 0.97), INK)
			seigaiha(c, 0, -0.62, 0.96, 0.44, GOLD)
			c:cyl(Vector3.new(0.05, 0.36, 0.36), CFrame.new(0, 0.60, 0.96) * FRONT, GOLD, METAL)
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.70, -0.70 }) do
					c:box(Vector3.new(0.30, 0.12, 0.30), CFrame.new(0.70 * s, -0.96, z), p.deep)
				end
			end
		end,
	}

	-- A tsuba: a round bronze sword guard rolling on its edge, the blade slot
	-- above its face, openwork blossoms, the wrapped hilt rising from the top.
	S.so_t_tsuba = {
		label = "Tsuba Medallion",
		set = "shoguns_oath",
		tint = C3(200, 124, 60),
		scale = 1.10,
		head = CFrame.new(0, 1.70, 0),
		neck = CFrame.new(0, -0.50, 0.32),
		back = CFrame.new(0, 0.10, -0.32),
		build = function(c, p)
			c:cyl(Vector3.new(0.50, 2.00, 2.00), CFrame.new(0, 0.10, 0) * FRONT, p.base, METAL)
			c:cyl(Vector3.new(0.40, 2.16, 2.16), CFrame.new(0, 0.10, 0) * FRONT, p.dark, METAL)
			c:box(Vector3.new(0.22, 0.50, 0.06), CFrame.new(0, 0.62, 0.26), INK)
			for _, s in ipairs(SIDES) do
				c:cyl(Vector3.new(0.05, 0.36, 0.36), CFrame.new(0.62 * s, 0.46, 0.26) * FRONT, p.light)
				c:round(Vector3.new(0.36, 0.20, 0.50), CFrame.new(0.40 * s, -0.96, 0), p.deep)
			end
			c:eyes(0.02, 0.30, 0.32, 0.12)
			blush(c, 0.56, -0.18, 0.27)
			c:box(Vector3.new(0.18, 0.06, 0.04), CFrame.new(0, -0.22, 0.28), INK)
			c:rod(Vector3.new(0, 1.10, 0), Vector3.new(0, 1.56, 0), 0.13, SUMI, nil, false)
			c:box(Vector3.new(0.20, 0.08, 0.28), CFrame.new(0, 1.24, 0) * CFrame.Angles(0, 0, 0.6), WASHI)
			c:box(Vector3.new(0.20, 0.08, 0.28), CFrame.new(0, 1.42, 0) * CFrame.Angles(0, 0, -0.6), WASHI)
			c:ball(Vector3.new(0.28, 0.28, 0.28), CFrame.new(0, 1.62, 0), GOLD, METAL)
		end,
	}

	-- A suzumushi: the bell cricket kept for its song, long sweeping feelers,
	-- folded veined wings, big springy hind legs and a tiny gold bell.
	S.so_t_suzumushi = {
		label = "Suzumushi",
		set = "shoguns_oath",
		tint = C3(200, 224, 60),
		head = CFrame.new(0, 0.70, 0.30),
		neck = CFrame.new(0, -0.50, 0.96),
		back = CFrame.new(0, 0.60, -0.70),
		build = function(c, p)
			c:round(Vector3.new(1.40, 1.10, 2.00), CFrame.new(0, -0.10, 0), p.base)
			c:box(Vector3.new(1.30, 0.12, 1.50), CFrame.new(0, 0.48, -0.25) * CFrame.Angles(0.10, 0, 0), p.pale)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.05, 0.14, 1.30), CFrame.new(0.30 * s, 0.52, -0.25) * CFrame.Angles(0.10, 0, 0), p.dark)
				c:rod(Vector3.new(0.20 * s, 0.30, 0.90), Vector3.new(0.70 * s, 1.36, 0.40), 0.04, p.dark, nil, false)
				c:ball(Vector3.new(0.14, 0.14, 0.14), CFrame.new(0.70 * s, 1.36, 0.40), p.light)
				c:rod(Vector3.new(0.60 * s, -0.10, -0.30), Vector3.new(0.95 * s, 0.35, -0.80), 0.10, p.dark, nil, false)
				c:rod(Vector3.new(0.95 * s, 0.35, -0.80), Vector3.new(0.90 * s, -0.85, -0.90), 0.07, p.dark, nil, false)
				c:rod(Vector3.new(0.50 * s, -0.40, 0.50), Vector3.new(0.75 * s, -0.88, 0.65), 0.06, p.dark, nil, false)
			end
			c:eyes(0.12, 0.98, 0.34, 0.15)
			c:box(Vector3.new(0.18, 0.06, 0.05), CFrame.new(0, -0.20, 1.00), INK)
			c:rod(Vector3.new(0, -0.40, 0.92), Vector3.new(0, -0.56, 0.98), 0.02, RED, nil, false)
			c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0, -0.64, 0.98), GOLD, METAL)
		end,
	}

	-- A kamaitachi: the sickle weasel who rides the whirlwind, a long low body,
	-- a fluffy upswept tail, little steel sickles on its forepaws, cloud puffs.
	S.so_t_kamaitachi = {
		label = "Kamaitachi",
		set = "shoguns_oath",
		tint = C3(150, 210, 255),
		scale = 1.15,
		head = CFrame.new(0, 0.70, 0.50),
		neck = CFrame.new(0, -0.10, 1.10),
		back = CFrame.new(0, 0.60, -0.70),
		build = function(c, p)
			c:round(Vector3.new(1.10, 0.90, 2.00), CFrame.new(0, 0.10, -0.10), p.base)
			c:box(Vector3.new(0.40, 0.06, 1.40), CFrame.new(0, 0.56, -0.20), p.dark)
			c:round(Vector3.new(0.50, 0.34, 0.30), CFrame.new(0, -0.02, 0.96), p.pale)
			c:ball(Vector3.new(0.14, 0.14, 0.14), CFrame.new(0, 0.06, 1.12), INK)
			c:eyes(0.30, 0.92, 0.26, 0.11)
			c:round(Vector3.new(0.40, 0.40, 1.00), CFrame.new(0, 0.55, -1.30) * CFrame.Angles(-0.8, 0, 0), p.base)
			c:round(Vector3.new(0.44, 0.44, 0.44), CFrame.new(0, 0.98, -1.58), p.pale)
			for _, s in ipairs(SIDES) do
				c:round(Vector3.new(0.24, 0.24, 0.12), CFrame.new(0.30 * s, 0.60, 0.70), p.base)
				for _, z in ipairs({ 0.55, -0.70 }) do
					c:round(Vector3.new(0.30, 0.40, 0.34), CFrame.new(0.40 * s, -0.40, z), p.dark)
				end
				c:box(Vector3.new(0.06, 0.12, 0.30), CFrame.new(0.52 * s, -0.46, 0.80), TIMBER)
				c:box(Vector3.new(0.05, 0.40, 0.12), CFrame.new(0.52 * s, -0.30, 1.00) * CFrame.Angles(-0.7, 0, 0), STEEL, METAL)
			end
			for _, v in ipairs({ { -0.60, 0.30 }, { 0.50, -0.40 }, { 0, -1.10 } }) do
				c:round(Vector3.new(0.80, 0.30, 0.80), CFrame.new(v[1], -0.74, v[2]), WASHI)
			end
		end,
	}

	-- A shodo brush: a calligraphy brush standing on its inky tuft, a brass
	-- ferrule, a jointed bamboo handle, and a drop of sumi ink at its feet.
	S.so_t_brush = {
		label = "Shodo Brush",
		set = "shoguns_oath",
		tint = C3(60, 56, 90),
		head = CFrame.new(0, 1.50, 0),
		neck = CFrame.new(0, -0.50, 0.70),
		back = CFrame.new(0, 0, -0.76),
		build = function(c, p)
			c:round(Vector3.new(1.50, 1.50, 1.50), CFrame.new(0, -0.25, 0), p.base)
			c:cone(Vector3.new(0.58, 0.40, 0.58), CFrame.new(0, -1.18, 0) * CFrame.Angles(math.pi, 0, 0), p.deep)
			c:cyl(Vector3.new(0.26, 1.20, 1.20), CFrame.new(0, 0.62, 0) * UP, GOLD, METAL)
			c:cyl(Vector3.new(0.60, 0.66, 0.66), CFrame.new(0, 1.04, 0) * UP, p.light)
			c:cyl(Vector3.new(0.08, 0.72, 0.72), CFrame.new(0, 1.04, 0) * UP, p.dark)
			c:cyl(Vector3.new(0.10, 0.60, 0.60), CFrame.new(0, 1.40, 0) * UP, p.dark)
			c:eyes(0.0, 0.74, 0.30, 0.13)
			blush(c, 0.50, -0.20, 0.74)
			c:box(Vector3.new(0.18, 0.06, 0.05), CFrame.new(0, -0.22, 0.76), INK)
			c:ball(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0.92, -0.92, 0.30), SUMI)
			c:cone(Vector3.new(0.20, 0.22, 0.20), CFrame.new(0.92, -0.68, 0.30), SUMI)
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.72 * s, -0.20, 0.20), Vector3.new(1.04 * s, 0.06, 0.34), 0.07, p.dark)
			end
		end,
	}

	-- A sakura blossom: five petals round a round face, gold stamens, two
	-- leaves and a twig, and one petal drifting free.
	S.so_t_sakura = {
		label = "Sakura Bloom",
		set = "shoguns_oath",
		tint = C3(255, 168, 200),
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, -0.50, 0.30),
		back = CFrame.new(0, 0.10, -0.30),
		build = function(c, p)
			for i = 0, 4 do
				c:round(Vector3.new(0.90, 1.00, 0.30), CFrame.new(0, 0.10, 0) * CFrame.Angles(0, 0, i * math.pi * 0.4) * CFrame.new(0, 0.72, 0), p.base)
			end
			c:cyl(Vector3.new(0.40, 1.10, 1.10), CFrame.new(0, 0.10, 0) * FRONT, p.pale)
			c:eyes(0.20, 0.24, 0.24, 0.11)
			blush(c, 0.36, 0.00, 0.22)
			c:box(Vector3.new(0.14, 0.06, 0.04), CFrame.new(0, -0.08, 0.22), INK)
			for _, a in ipairs({ -0.6, 0, 0.6 }) do
				c:ball(Vector3.new(0.12, 0.12, 0.12), CFrame.new(0.44 * math.sin(a), 0.10 + 0.44 * math.cos(a), 0.22), GOLD)
			end
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.50, 0.24, 0.06), CFrame.new(0.36 * s, -0.98, -0.12) * CFrame.Angles(0, 0, 0.5 * s), LEAF)
			end
			c:rod(Vector3.new(0, -0.80, -0.10), Vector3.new(0.30, -1.30, -0.10), 0.06, C3(110, 70, 50), nil, false)
			c:round(Vector3.new(0.30, 0.36, 0.10), CFrame.new(1.20, 0.90, 0.20) * CFrame.Angles(0, 0, 0.6), p.light)
		end,
	}

	-- A sumo champion: round and proud, a purple mawashi with hanging cords,
	-- the champion's white rope with paper zigzags, a topknot and strong arms.
	S.so_t_sumo = {
		label = "Sumo Champ",
		set = "shoguns_oath",
		tint = C3(255, 182, 140),
		head = CFrame.new(0, 1.10, -0.10),
		neck = CFrame.new(0, -0.30, 0.90),
		back = CFrame.new(0, 0.10, -0.90),
		build = function(c, p)
			local belt = C3(110, 50, 180)
			c:round(Vector3.new(2.00, 1.70, 1.70), CFrame.new(0, -0.05, 0), p.base)
			c:box(Vector3.new(2.06, 0.50, 1.76), CFrame.new(0, -0.55, 0), belt)
			for _, x in ipairs({ -0.24, 0, 0.24 }) do
				c:box(Vector3.new(0.08, 0.40, 0.06), CFrame.new(x, -0.94, 0.86), belt)
			end
			c:box(Vector3.new(2.10, 0.18, 1.80), CFrame.new(0, -0.24, 0), WASHI)
			c:round(Vector3.new(1.60, 0.30, 1.40), CFrame.new(0, 0.74, -0.05), SUMI)
			c:round(Vector3.new(0.36, 0.30, 0.50), CFrame.new(0, 0.94, -0.10), SUMI)
			c:eyes(0.30, 0.84, 0.34, 0.12)
			blush(c, 0.62, 0.06, 0.84)
			c:box(Vector3.new(0.24, 0.08, 0.05), CFrame.new(0, -0.02, 0.86), INK)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.34, 0.08, 0.05), CFrame.new(0.34 * s, 0.56, 0.86) * CFrame.Angles(0, 0, 0.2 * s), INK)
				c:box(Vector3.new(0.14, 0.24, 0.04), CFrame.new(0.36 * s, -0.38, 0.92) * CFrame.Angles(0, 0, 0.5 * s), WASHI)
				c:round(Vector3.new(0.50, 0.90, 0.50), CFrame.new(1.10 * s, -0.05, 0.20) * CFrame.Angles(0, 0, 0.5 * s), p.base)
				c:round(Vector3.new(0.60, 0.50, 0.60), CFrame.new(0.55 * s, -0.95, 0.10), p.base)
			end
		end,
	}

	-- A shishi-odoshi: the bamboo water clacker of a garden, its tube tipped on
	-- a pivot over a stone basin, a face on its open end, a spout trickling in.
	S.so_t_clacker = {
		label = "Bamboo Clacker",
		set = "shoguns_oath",
		tint = C3(110, 200, 70),
		head = CFrame.new(0, 1.30, 0.50),
		neck = CFrame.new(0, -0.50, 0.80),
		back = CFrame.new(0, 0.10, -1.00),
		build = function(c, p)
			local stone = C3(130, 128, 124)
			c:box(Vector3.new(1.60, 0.60, 1.40), CFrame.new(0, -0.70, 0), stone)
			c:box(Vector3.new(1.30, 0.06, 1.10), CFrame.new(0, -0.38, 0), SKY)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.20, 1.10, 0.20), CFrame.new(0.50 * s, -0.10, -0.20), p.dark)
				c:ball(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0.95 * s, -0.88, 0.50), stone)
			end
			c:cyl(Vector3.new(1.20, 0.12, 0.12), CFrame.new(0, 0.30, -0.20), GOLD, METAL)
			local tilt = CFrame.Angles(-0.35, 0, 0)
			c:cyl(Vector3.new(2.20, 0.70, 0.70), CFrame.new(0, 0.40, -0.20) * tilt * FRONT, p.base)
			for _, d in ipairs({ -0.50, 0.30 }) do
				c:cyl(Vector3.new(0.08, 0.76, 0.76), CFrame.new(0, 0.40, -0.20) * tilt * CFrame.new(0, 0, d) * FRONT, p.dark)
			end
			local mouth = CFrame.new(0, 0.40, -0.20) * tilt * CFrame.new(0, 0, 1.11)
			c:cyl(Vector3.new(0.06, 0.62, 0.62), mouth * FRONT, p.pale)
			c:eye(mouth * Vector3.new(-0.15, 0.06, 0.06), 0.09)
			c:eye(mouth * Vector3.new(0.15, 0.06, 0.06), 0.09)
			c:box(Vector3.new(0.14, 0.05, 0.04), mouth * CFrame.new(0, -0.14, 0.05), INK)
			c:rod(Vector3.new(0.90, 1.30, 0.20), Vector3.new(0.20, 1.16, 0.70), 0.07, p.light)
			c:ball(Vector3.new(0.12, 0.12, 0.12), CFrame.new(0.14, 1.04, 0.74), SKY)
			c:ball(Vector3.new(0.09, 0.09, 0.09), CFrame.new(0.10, 0.94, 0.78), SKY)
		end,
	}

	----------------------------------------------------------------------------
	-- LEGENDARY: lacquer, gold trim, more ornament.
	----------------------------------------------------------------------------

	-- A flat ribbon (a feather, a streamer) running from a to b.
	local function ribbon(c, a, b, w, colour, mat)
		return c:box(Vector3.new(w, 0.05, (b - a).Magnitude), CFrame.lookAt((a + b) * 0.5, b), colour, mat)
	end

	-- An onagadori: the long-tailed rooster, a red comb and wattle, a golden
	-- hackle cape, and three tail streamers sweeping up, back and down.
	S.so_t_onagadori = {
		label = "Onagadori",
		set = "shoguns_oath",
		tint = C3(255, 200, 60),
		scale = 1.15,
		head = CFrame.new(0, 1.20, 0.20),
		neck = CFrame.new(0, -0.20, 1.00),
		back = CFrame.new(0, 0.50, -0.80),
		build = function(c, p)
			c:round(Vector3.new(1.50, 1.50, 1.50), CFrame.new(0, 0.10, 0.20), p.base)
			c:round(Vector3.new(1.60, 0.70, 1.20), CFrame.new(0, 0.40, -0.10), p.light)
			for i, z in ipairs({ 0.50, 0.24, -0.02 }) do
				c:box(Vector3.new(0.12, 0.30 - i * 0.04, 0.22), CFrame.new(0, 0.96, z), RED)
			end
			c:round(Vector3.new(0.24, 0.30, 0.14), CFrame.new(0, -0.28, 1.00), RED)
			c:cone(Vector3.new(0.24, 0.30, 0.24), CFrame.new(0, 0.04, 1.06) * CFrame.Angles(math.pi / 2, 0, 0), BEAK)
			c:eyes(0.34, 0.94, 0.32, 0.12)
			for _, s in ipairs(SIDES) do
				c:round(Vector3.new(0.30, 0.80, 1.10), CFrame.new(0.78 * s, 0, -0.05) * CFrame.Angles(0, 0, 0.15 * s), p.dark)
				c:rod(Vector3.new(0.30 * s, -0.50, 0.20), Vector3.new(0.30 * s, -0.96, 0.24), 0.06, BEAK, nil, false)
				c:box(Vector3.new(0.24, 0.08, 0.34), CFrame.new(0.30 * s, -1.00, 0.30), BEAK)
			end
			for i, x in ipairs({ -0.24, 0, 0.24 }) do
				local col = i == 2 and GOLD or p.deep
				local a, b = Vector3.new(x, 0.60, -0.40), Vector3.new(x * 1.4, 1.14, -1.10)
				local d, e = Vector3.new(x * 1.8, 0.50, -1.62), Vector3.new(x * 2.2, -0.70, -1.74)
				ribbon(c, a, b, 0.22, col, i == 2 and METAL or nil)
				ribbon(c, b, d, 0.20, col, i == 2 and METAL or nil)
				ribbon(c, d, e, 0.18, col, i == 2 and METAL or nil)
			end
		end,
	}

	-- A katanakake: a red lacquer sword stand with a long and a short sword
	-- resting in its hooks, a gold crest on the crossbar, a face on the plinth.
	S.so_t_katanarack = {
		label = "Katana Rack",
		set = "shoguns_oath",
		tint = C3(176, 24, 44),
		scale = 1.20,
		head = CFrame.new(0, 1.36, 0),
		neck = CFrame.new(0, -0.80, 0.56),
		back = CFrame.new(0, 0, -0.56),
		build = function(c, p)
			c:box(Vector3.new(2.20, 0.50, 1.00), CFrame.new(0, -0.80, 0), p.base)
			c:box(Vector3.new(2.24, 0.06, 1.04), CFrame.new(0, -0.56, 0), GOLD, METAL)
			c:box(Vector3.new(1.90, 0.14, 0.20), CFrame.new(0, 0.98, 0), p.dark)
			c:cyl(Vector3.new(0.06, 0.40, 0.40), CFrame.new(0, 1.12, 0.10) * FRONT, GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.30, 1.60, 0.50), CFrame.new(0.80 * s, 0.10, 0), p.base)
				c:box(Vector3.new(0.36, 0.10, 0.56), CFrame.new(0.80 * s, 0.92, 0), p.dark)
				c:box(Vector3.new(0.40, 0.10, 1.00), CFrame.new(0.80 * s, -1.08, 0), p.dark)
				for _, y in ipairs({ -0.04, 0.56 }) do
					c:box(Vector3.new(0.30, 0.12, 0.30), CFrame.new(0.80 * s, y, 0.36), p.dark)
				end
			end
			-- Katana above, wakizashi below: scabbard, guard, wrapped hilt, pommel.
			for _, v in ipairs({ { 0.68, 1.30, 0.13 }, { 0.08, 1.00, 0.11 } }) do
				local y, len, r = v[1], v[2], v[3]
				c:rod(Vector3.new(-len, y, 0.40), Vector3.new(len * 0.55, y + 0.04, 0.40), r, SUMI, nil, false)
				c:cyl(Vector3.new(0.06, r * 3.4, r * 3.4), CFrame.new(len * 0.56, y + 0.04, 0.40), GOLD, METAL)
				c:rod(Vector3.new(len * 0.58, y + 0.04, 0.40), Vector3.new(len * 0.96, y + 0.07, 0.40), r * 0.9, WASHI, nil, false)
				c:ball(Vector3.new(r * 2.2, r * 2.2, r * 2.2), CFrame.new(len * 0.98, y + 0.07, 0.40), GOLD, METAL)
			end
			c:eyes(-0.78, 0.54, 0.40, 0.12)
			blush(c, 0.72, -0.92, 0.51)
			c:box(Vector3.new(0.20, 0.07, 0.05), CFrame.new(0, -0.94, 0.52), INK)
		end,
	}

	-- A torii that walks: two vermilion pillars on black feet, the black top
	-- beam with upswept gold-tipped ends, a face on the name plaque, and a
	-- sacred rope with paper zigzags slung under the tie beam.
	S.so_t_torii = {
		label = "Torii Walker",
		set = "shoguns_oath",
		tint = C3(236, 60, 36),
		scale = 1.20,
		head = CFrame.new(0, 1.30, 0),
		neck = CFrame.new(0, 0.10, 0.30),
		back = CFrame.new(0, 0.40, -0.30),
		build = function(c, p)
			c:box(Vector3.new(2.60, 0.24, 0.42), CFrame.new(0, 1.00, 0), SUMI)
			c:box(Vector3.new(2.30, 0.16, 0.36), CFrame.new(0, 0.84, 0), p.base)
			c:box(Vector3.new(2.20, 0.18, 0.24), CFrame.new(0, 0.38, 0), p.base)
			for _, s in ipairs(SIDES) do
				c:cyl(Vector3.new(1.80, 0.36, 0.36), CFrame.new(0.75 * s, -0.10, 0) * UP, p.base)
				c:cyl(Vector3.new(0.20, 0.48, 0.48), CFrame.new(0.75 * s, -0.98, 0) * UP, SUMI)
				c:box(Vector3.new(0.50, 0.16, 0.42), CFrame.new(1.40 * s, 1.08, 0) * CFrame.Angles(0, 0, 0.35 * s), SUMI)
				c:box(Vector3.new(0.14, 0.18, 0.44), CFrame.new(1.62 * s, 1.18, 0) * CFrame.Angles(0, 0, 0.35 * s), GOLD, METAL)
				c:box(Vector3.new(0.12, 0.26, 0.04), CFrame.new(0.30 * s, 0.00, 0.08) * CFrame.Angles(0, 0, 0.3), WASHI)
			end
			c:box(Vector3.new(1.10, 0.56, 0.12), CFrame.new(0, 0.61, 0.10), GOLD, METAL)
			c:box(Vector3.new(0.98, 0.46, 0.14), CFrame.new(0, 0.61, 0.11), p.pale)
			c:eyes(0.64, 0.20, 0.22, 0.09)
			blush(c, 0.36, 0.50, 0.19)
			c:box(Vector3.new(0.14, 0.05, 0.04), CFrame.new(0, 0.50, 0.19), INK)
			c:rod(Vector3.new(-0.60, 0.16, 0.04), Vector3.new(0.60, 0.16, 0.04), 0.07, ROPE, nil, false)
		end,
	}

	-- A komuso: a wandering flute monk, head hidden in a woven straw basket
	-- with only a little window for his eyes, a gold stole, a bamboo flute.
	S.so_t_komuso = {
		label = "Komuso Flutist",
		set = "shoguns_oath",
		tint = C3(214, 180, 110),
		head = CFrame.new(0, 1.42, 0),
		neck = CFrame.new(0, -0.20, 0.80),
		back = CFrame.new(0, -0.20, -0.80),
		build = function(c, p)
			c:box(Vector3.new(1.60, 1.30, 1.40), CFrame.new(0, -0.45, 0), p.dark)
			c:box(Vector3.new(0.30, 1.40, 0.06), CFrame.new(-0.28, -0.40, 0.72) * CFrame.Angles(0, 0, 0.6), GOLD_DARK)
			c:box(Vector3.new(1.64, 0.12, 1.44), CFrame.new(0, -0.70, 0), p.deep)
			c:round(Vector3.new(1.90, 1.30, 1.80), CFrame.new(0, 0.65, 0), p.base)
			for _, y in ipairs({ 0.24, 0.62, 1.00 }) do
				c:cyl(Vector3.new(0.06, 1.86, 1.86), CFrame.new(0, y, 0) * UP, p.light)
			end
			c:cyl(Vector3.new(0.12, 0.40, 0.40), CFrame.new(0, 1.32, 0) * UP, p.light)
			c:box(Vector3.new(0.90, 0.32, 0.06), CFrame.new(0, 0.48, 0.90), SUMI)
			c:eyes(0.48, 0.95, 0.24, 0.10, C3(255, 240, 200))
			c:rod(Vector3.new(0.28, -0.90, 0.86), Vector3.new(0.10, 0.18, 0.98), 0.07, TIMBER, nil, false)
			for _, t in ipairs({ 0.3, 0.7 }) do
				c:cyl(Vector3.new(0.04, 0.17, 0.17), CFrame.new(0.28 - 0.18 * t, -0.90 + 1.08 * t, 0.86 + 0.12 * t) * UP, p.deep)
			end
			for _, s in ipairs(SIDES) do
				c:round(Vector3.new(0.50, 0.60, 0.50), CFrame.new(0.80 * s, -0.35, 0.35), p.dark)
				c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(0.20 + 0.06 * s, -0.40 + 0.25 * s, 0.94), C3(255, 214, 180))
				c:box(Vector3.new(0.40, 0.16, 0.56), CFrame.new(0.40 * s, -1.14, 0.06), p.deep)
			end
		end,
	}

	-- A hyotan: a red-lacquered water gourd, two round bulbs tied at the waist
	-- with gold cord, bows and a tassel, a wooden stopper and gold-leaf flecks.
	S.so_t_hyotan = {
		label = "Hyotan Gourd",
		set = "shoguns_oath",
		tint = C3(230, 70, 40),
		head = CFrame.new(0, 1.60, 0),
		neck = CFrame.new(0, -0.60, 0.86),
		back = CFrame.new(0, -0.20, -0.86),
		build = function(c, p)
			c:ball(Vector3.new(1.70, 1.70, 1.70), CFrame.new(0, -0.35, 0), p.base)
			c:ball(Vector3.new(1.10, 1.10, 1.10), CFrame.new(0, 0.75, 0), p.base)
			c:cyl(Vector3.new(0.12, 0.82, 0.82), CFrame.new(0, 0.34, 0) * UP, GOLD, METAL)
			c:cyl(Vector3.new(0.30, 0.36, 0.36), CFrame.new(0, 1.38, 0) * UP, TIMBER)
			c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0, 1.56, 0), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.26, 0.14, 0.06), CFrame.new(0.16 * s, 0.34, 0.44) * CFrame.Angles(0, 0, 0.4 * s), RED)
				c:round(Vector3.new(0.40, 0.24, 0.46), CFrame.new(0.45 * s, -1.16, 0.10), p.deep)
				c:rod(Vector3.new(0.82 * s, -0.30, 0.10), Vector3.new(1.08 * s, -0.02, 0.24), 0.07, p.dark)
			end
			c:rod(Vector3.new(0.10, 0.30, 0.42), Vector3.new(0.20, -0.04, 0.82), 0.03, RED, nil, false)
			c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.21, -0.08, 0.84), RED)
			for _, v in ipairs({ { -0.30, 0.90, 0.40 }, { 0.36, 0.64, 0.38 }, { 0.10, 1.10, 0.32 } }) do
				c:box(Vector3.new(0.12, 0.12, 0.06), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0, 0, 0.7), GOLD, METAL)
			end
			c:eyes(-0.22, 0.80, 0.30, 0.13)
			blush(c, 0.52, -0.42, 0.68)
			c:box(Vector3.new(0.20, 0.07, 0.05), CFrame.new(0, -0.48, 0.82), INK)
		end,
	}

	-- A shamisen: the square drum body is its face, the long neck rising to a
	-- peg box, three strings, gold corner caps, and the ginkgo-leaf plectrum.
	S.so_t_shamisen = {
		label = "Shamisen Bard",
		set = "shoguns_oath",
		tint = C3(150, 80, 50),
		scale = 1.12,
		head = CFrame.new(0, 0.56, -0.10),
		neck = CFrame.new(0, -0.70, 0.44),
		back = CFrame.new(0, -0.20, -0.40),
		build = function(c, p)
			c:box(Vector3.new(1.70, 1.40, 0.70), CFrame.new(0, -0.20, 0), p.base)
			c:box(Vector3.new(1.50, 1.20, 0.06), CFrame.new(0, -0.20, 0.36), p.pale)
			c:box(Vector3.new(0.26, 1.10, 0.26), CFrame.new(0, 1.05, 0), p.dark)
			c:box(Vector3.new(0.34, 0.40, 0.30), CFrame.new(0, 1.76, -0.04) * CFrame.Angles(-0.25, 0, 0), p.deep)
			for i, y in ipairs({ 1.66, 1.78, 1.90 }) do
				local s = i == 2 and -1 or 1
				c:rod(Vector3.new(0, y, -0.06), Vector3.new(0.36 * s, y + 0.02, -0.06), 0.04, WASHI, nil, false)
			end
			for _, x in ipairs({ -0.08, 0, 0.08 }) do
				c:rod(Vector3.new(x, -0.76, 0.42), Vector3.new(x * 0.5, 1.56, 0.14), 0.012, WASHI, nil, false)
			end
			c:box(Vector3.new(0.40, 0.10, 0.08), CFrame.new(0, -0.70, 0.42), p.deep)
			for _, s in ipairs(SIDES) do
				for _, y in ipairs({ 0.46, -0.86 }) do
					c:box(Vector3.new(0.20, 0.16, 0.74), CFrame.new(0.78 * s, y, 0), GOLD, METAL)
				end
				c:box(Vector3.new(0.34, 0.30, 0.40), CFrame.new(0.50 * s, -1.04, 0), p.dark)
			end
			c:eyes(0.06, 0.42, 0.42, 0.12)
			blush(c, 0.56, -0.18, 0.40)
			c:box(Vector3.new(0.16, 0.07, 0.04), CFrame.new(-0.30, -0.22, 0.41), INK)
			c:box(Vector3.new(0.10, 0.50, 0.06), CFrame.new(1.02, -0.50, 0.40) * CFrame.Angles(0, 0, -0.4), WASHI)
			c:cone(Vector3.new(0.56, 0.36, 0.08), CFrame.new(1.16, -0.20, 0.40) * CFrame.Angles(0, 0, -0.4 + math.pi), WASHI)
			c:rod(Vector3.new(0.17, 1.92, 0), Vector3.new(0.30, 1.50, 0.10), 0.03, RED, nil, false)
		end,
	}

	-- A taikobashi: a red lacquer drum bridge humping over a stream, its face on
	-- the arch's side beam, railings with gold onion finials, stone piers.
	S.so_t_bridge = {
		label = "Lacquer Bridge",
		set = "shoguns_oath",
		tint = C3(220, 44, 44),
		scale = 1.20,
		head = CFrame.new(0, 1.20, 0),
		neck = CFrame.new(0, 0, 0.76),
		back = CFrame.new(0, 0.40, -0.76),
		build = function(c, p)
			local stone = C3(140, 136, 130)
			c:box(Vector3.new(1.20, 0.60, 1.40), CFrame.new(0, 0.30, 0), p.base)
			c:box(Vector3.new(1.10, 0.04, 1.30), CFrame.new(0, 0.62, 0), p.pale)
			c:box(Vector3.new(1.30, 0.10, 1.46), CFrame.new(0, 0.02, 0), GOLD, METAL)
			c:box(Vector3.new(1.40, 0.08, 1.00), CFrame.new(0, -0.95, 0), SKY)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(1.00, 0.36, 1.40), CFrame.new(0.95 * s, 0.02, 0) * CFrame.Angles(0, 0, -0.55 * s), p.base)
				c:box(Vector3.new(0.40, 0.70, 1.20), CFrame.new(1.25 * s, -0.66, 0), stone)
				c:box(Vector3.new(1.20, 0.08, 0.08), CFrame.new(0, 1.00, 0.66 * s), p.base)
				for _, x in ipairs({ -0.60, 0.60 }) do
					c:box(Vector3.new(0.10, 0.40, 0.10), CFrame.new(x, 0.80, 0.66 * s), p.dark)
					c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(x, 1.06, 0.66 * s), GOLD, METAL)
				end
			end
			c:eyes(0.34, 0.74, 0.34, 0.12)
			blush(c, 0.48, 0.18, 0.72)
			c:box(Vector3.new(0.18, 0.06, 0.05), CFrame.new(0, 0.16, 0.73), INK)
		end,
	}

	-- A tiny warrior rowing a black-and-red lacquer rice bowl down the river,
	-- a chopstick for an oar, a sewing needle for a sword, gold waves on the bowl.
	S.so_t_rower = {
		label = "Ricebowl Rower",
		set = "shoguns_oath",
		tint = C3(36, 44, 96),
		scale = 1.10,
		head = CFrame.new(0, 1.00, 0.05),
		neck = CFrame.new(0, -0.50, 1.16),
		back = CFrame.new(0, 0.20, -1.12),
		build = function(c, p)
			c:cyl(Vector3.new(0.70, 2.20, 2.20), CFrame.new(0, -0.50, 0) * UP, p.base)
			c:cyl(Vector3.new(0.16, 1.20, 1.20), CFrame.new(0, -0.92, 0) * UP, p.dark)
			c:cyl(Vector3.new(0.06, 2.26, 2.26), CFrame.new(0, -0.17, 0) * UP, GOLD, METAL)
			c:cyl(Vector3.new(0.06, 2.00, 2.00), CFrame.new(0, -0.13, 0) * UP, LACQ)
			seigaiha(c, 0, -0.52, 1.10, 0.46, GOLD)
			c:box(Vector3.new(0.94, 0.40, 0.84), CFrame.new(0, -0.02, 0.05), C3(90, 120, 200))
			c:box(Vector3.new(0.90, 0.80, 0.80), CFrame.new(0, 0.50, 0.05), C3(255, 218, 186))
			c:box(Vector3.new(0.94, 0.14, 0.84), CFrame.new(0, 0.80, 0.05), RED)
			c:round(Vector3.new(0.30, 0.26, 0.40), CFrame.new(0, 1.00, -0.06), SUMI)
			c:eyes(0.50, 0.48, 0.20, 0.09)
			blush(c, 0.30, 0.34, 0.46)
			c:box(Vector3.new(0.12, 0.05, 0.04), CFrame.new(0, 0.30, 0.46), INK)
			c:rod(Vector3.new(0.50, 0.40, 0.20), Vector3.new(1.40, -0.70, -0.20), 0.05, TIMBER, nil, false)
			c:rod(Vector3.new(-0.46, -0.10, -0.30), Vector3.new(-0.70, 0.90, -0.50), 0.03, STEEL, METAL, false)
			c:ball(Vector3.new(0.12, 0.12, 0.12), CFrame.new(-0.52, 0.16, -0.35), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.60, 0.04, 0.30), CFrame.new(1.30 * s, -0.84, 0.60), SKY)
			end
		end,
	}

	-- A nurikabe: a stretch of castle stone wall that waddles about on stubby
	-- legs, plastered and roofed with black tiles on top, a face in the stones.
	S.so_t_nurikabe = {
		label = "Nurikabe",
		set = "shoguns_oath",
		tint = C3(150, 146, 136),
		scale = 1.15,
		head = CFrame.new(0, 1.56, 0),
		neck = CFrame.new(0, -0.50, 0.44),
		back = CFrame.new(0, 0, -0.44),
		build = function(c, p)
			c:box(Vector3.new(2.40, 1.80, 0.80), CFrame.new(0, 0, 0), p.base)
			for _, v in ipairs({ { -0.84, 0.62, 0.60, 0.40, 1 }, { 0.84, 0.60, 0.56, 0.44, 2 }, { -0.80, -0.62, 0.70, 0.46, 2 },
				{ 0.10, -0.66, 0.60, 0.40, 1 }, { 0.86, -0.40, 0.56, 0.60, 1 }, { -0.20, 0.72, 0.50, 0.30, 2 } }) do
				c:box(Vector3.new(v[3], v[4], 0.10), CFrame.new(v[1], v[2], 0.42), v[5] == 1 and p.light or p.dark)
			end
			c:box(Vector3.new(2.50, 0.22, 0.90), CFrame.new(0, 1.00, 0), WASHI)
			c:prism(Vector3.new(2.70, 0.40, 1.16), CFrame.new(0, 1.30, 0), SUMI)
			c:eyes(0.20, 0.46, 0.38, 0.14)
			blush(c, 0.58, -0.04, 0.42)
			c:box(Vector3.new(0.24, 0.08, 0.05), CFrame.new(0, -0.10, 0.43), INK)
			c:round(Vector3.new(0.50, 0.20, 0.30), CFrame.new(-0.80, -0.36, 0.44), LEAF)
			for _, s in ipairs(SIDES) do
				c:round(Vector3.new(0.40, 0.70, 0.40), CFrame.new(1.30 * s, -0.10, 0.10) * CFrame.Angles(0, 0, 0.3 * s), p.dark)
				c:box(Vector3.new(0.60, 0.30, 0.60), CFrame.new(0.60 * s, -1.05, 0), p.dark)
			end
		end,
	}

	-- A karakuri ningyo: an Edo clockwork tea-serving doll, bob-cut hair, a
	-- hakama, a lacquer tray with a cup of matcha, gear wheels and a wind-up key.
	S.so_t_karakuri = {
		label = "Karakuri Doll",
		set = "shoguns_oath",
		tint = C3(250, 120, 60),
		head = CFrame.new(0, 1.16, 0),
		neck = CFrame.new(0, -0.40, 1.14),
		back = CFrame.new(0, 0.20, -1.10),
		build = function(c, p)
			c:box(Vector3.new(1.60, 1.40, 1.40), CFrame.new(0, 0.25, 0), C3(255, 236, 216))
			c:box(Vector3.new(1.66, 0.40, 1.46), CFrame.new(0, 0.92, 0), SUMI)
			c:box(Vector3.new(1.20, 0.16, 0.10), CFrame.new(0, 0.72, 0.70), SUMI)
			c:box(Vector3.new(1.70, 0.80, 1.50), CFrame.new(0, -0.70, 0), p.base)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.12, 0.50, 0.06), CFrame.new(0.16 * s, -0.20, 0.72) * CFrame.Angles(0, 0, 0.5 * s), p.dark)
				c:rod(Vector3.new(0.75 * s, -0.10, 0.40), Vector3.new(0.40 * s, -0.30, 1.00), 0.10, p.base, nil, false)
				c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(0.38 * s, -0.30, 1.02), C3(255, 236, 216))
				c:cyl(Vector3.new(0.08, 0.60, 0.60), CFrame.new(0.88 * s, -0.80, 0), GOLD, METAL)
			end
			c:eyes(0.30, 0.72, 0.34, 0.12)
			blush(c, 0.56, 0.08, 0.71)
			c:box(Vector3.new(0.16, 0.06, 0.04), CFrame.new(0, 0.00, 0.72), RED)
			c:box(Vector3.new(0.90, 0.06, 0.60), CFrame.new(0, -0.34, 1.10), LACQ)
			c:cyl(Vector3.new(0.30, 0.32, 0.32), CFrame.new(0, -0.16, 1.10) * UP, WASHI)
			c:cyl(Vector3.new(0.02, 0.26, 0.26), CFrame.new(0, -0.01, 1.10) * UP, LEAF)
			c:rod(Vector3.new(0, 0.20, -0.70), Vector3.new(0, 0.20, -1.00), 0.05, GOLD, METAL, false)
			c:box(Vector3.new(0.60, 0.30, 0.06), CFrame.new(0, 0.20, -1.06), GOLD, METAL)
		end,
	}

	-- A yumi quiver: a lacquered arrow case bristling with white-fletched
	-- arrows, the tall samurai bow strung behind it, a gold crest and tassel.
	S.so_t_quiver = {
		label = "Yumi Quiver",
		set = "shoguns_oath",
		tint = C3(30, 110, 100),
		scale = 1.15,
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, -0.50, 0.52),
		back = CFrame.new(0, 0, -0.70),
		build = function(c, p)
			c:box(Vector3.new(1.30, 1.60, 0.90), CFrame.new(0, -0.25, 0), p.base)
			c:box(Vector3.new(1.36, 0.14, 0.96), CFrame.new(0, 0.50, 0), GOLD, METAL)
			c:box(Vector3.new(1.36, 0.10, 0.96), CFrame.new(0, -0.98, 0), p.dark)
			for i, x in ipairs({ -0.36, -0.12, 0.12, 0.36 }) do
				local top = Vector3.new(x * 1.5, 1.22 + (i % 2) * 0.10, -0.05)
				c:rod(Vector3.new(x, 0.50, 0), top, 0.035, TIMBER, nil, false)
				c:box(Vector3.new(0.05, 0.30, 0.16), CFrame.new(top) * CFrame.Angles(0, 0, -x), WASHI)
			end
			c:rod(Vector3.new(-0.90, -1.00, -0.62), Vector3.new(-0.98, 0.10, -0.62), 0.05, p.deep, nil, false)
			c:rod(Vector3.new(-0.98, 0.10, -0.62), Vector3.new(-0.70, 1.40, -0.62), 0.05, p.deep, nil, false)
			c:box(Vector3.new(0.14, 0.26, 0.14), CFrame.new(-0.98, -0.20, -0.62), RED)
			c:rod(Vector3.new(-0.90, -1.00, -0.66), Vector3.new(-0.70, 1.40, -0.66), 0.012, WASHI, nil, false)
			c:cyl(Vector3.new(0.05, 0.40, 0.40), CFrame.new(0, 0.18, 0.46) * FRONT, GOLD, METAL)
			c:eyes(-0.22, 0.48, 0.32, 0.12)
			blush(c, 0.48, -0.44, 0.46)
			c:box(Vector3.new(0.16, 0.06, 0.04), CFrame.new(0, -0.48, 0.46), INK)
			c:rod(Vector3.new(0.66, 0.30, 0.20), Vector3.new(0.72, -0.20, 0.30), 0.03, RED, nil, false)
			c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.72, -0.26, 0.30), RED)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.40, 0.20, 0.50), CFrame.new(0.40 * s, -1.12, 0.06), p.dark)
			end
		end,
	}

	-- A kadomatsu: three diagonal-cut bamboo stalks in a straw-bound base, pine
	-- sprigs and plum blossoms tucked in, a gold mizuhiki bow on the rope.
	S.so_t_kadomatsu = {
		label = "Kadomatsu",
		set = "shoguns_oath",
		tint = C3(60, 180, 80),
		scale = 1.10,
		head = CFrame.new(0, 1.84, 0),
		neck = CFrame.new(0, -0.70, 1.00),
		back = CFrame.new(0, -0.40, -1.00),
		build = function(c, p)
			c:cyl(Vector3.new(0.90, 1.90, 1.90), CFrame.new(0, -0.60, 0) * UP, ROPE)
			for _, y in ipairs({ -0.35, -0.85 }) do
				c:cyl(Vector3.new(0.10, 1.96, 1.96), CFrame.new(0, y, 0) * UP, C3(160, 120, 60))
			end
			for _, v in ipairs({ { -0.45, 1.60, 0.10 }, { 0, 2.00, -0.15 }, { 0.45, 1.30, 0.10 } }) do
				local x, h, z = v[1], v[2], v[3]
				local top = -0.20 + h
				c:cyl(Vector3.new(h, 0.50, 0.50), CFrame.new(x, -0.20 + h / 2, z) * UP, p.base)
				c:box(Vector3.new(0.52, 0.04, 0.62), CFrame.new(x, top, z) * CFrame.Angles(0.6, 0, 0), p.pale)
				c:cyl(Vector3.new(0.06, 0.54, 0.54), CFrame.new(x, top - 0.50, z) * UP, p.dark)
			end
			for _, v in ipairs({ { -0.80, 0.10, 0.40, 0.6 }, { 0.80, 0.10, 0.30, -0.6 }, { 0.20, 0.10, -0.70, 0.2 } }) do
				c:box(Vector3.new(0.40, 0.30, 0.30), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0, 0, v[4]), C3(30, 110, 60))
			end
			c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(-0.72, 0.30, 0.56), BLUSH)
			c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(0.66, 0.26, 0.52), C3(255, 250, 250))
			c:box(Vector3.new(0.50, 0.14, 0.06), CFrame.new(0, -0.35, 0.99), GOLD, METAL)
			c:eyes(-0.54, 0.96, 0.34, 0.11)
			blush(c, 0.56, -0.68, 0.95)
			c:box(Vector3.new(0.18, 0.06, 0.04), CFrame.new(0, -0.72, 0.97), INK)
		end,
	}

	----------------------------------------------------------------------------
	-- MYTHIC: the most spectacular, with neon gold-leaf glow.
	----------------------------------------------------------------------------

	-- A shachihoko: the golden tiger-faced carp from a castle roof ridge,
	-- standing on its head with its body arched up and its forked tail high.
	S.so_t_shachihoko = {
		label = "Shachihoko",
		set = "shoguns_oath",
		tint = C3(255, 150, 30),
		scale = 1.20,
		head = CFrame.new(0, 1.90, -0.30),
		neck = CFrame.new(0, -0.80, 1.00),
		back = CFrame.new(0, 0.80, -1.00),
		build = function(c, p)
			c:box(Vector3.new(1.50, 0.20, 1.30), CFrame.new(0, -1.08, 0.10), SUMI)
			c:box(Vector3.new(1.54, 0.06, 1.34), CFrame.new(0, -0.96, 0.10), GOLD, METAL)
			c:box(Vector3.new(1.60, 1.20, 1.40), CFrame.new(0, -0.36, 0.20), p.base, METAL)
			c:box(Vector3.new(1.30, 1.00, 1.00), CFrame.new(0, 0.32, -0.50) * CFrame.Angles(0.5, 0, 0), p.base, METAL)
			c:box(Vector3.new(1.00, 0.90, 0.80), CFrame.new(0, 0.95, -0.62) * CFrame.Angles(-0.2, 0, 0), p.base, METAL)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.10, 0.90, 0.70), CFrame.new(0.30 * s, 1.52, -0.36) * CFrame.Angles(-0.5, 0, 0.4 * s), p.light)
				c:cyl(Vector3.new(0.05, 0.46, 0.46), CFrame.new(0.66 * s, 0.30, -0.50) * CFrame.Angles(0.5, 0, 0), p.light)
				c:cyl(Vector3.new(0.05, 0.40, 0.40), CFrame.new(0.51 * s, 0.95, -0.62), p.light)
				c:box(Vector3.new(0.30, 0.08, 0.05), CFrame.new(0.34 * s, 0.30, 0.94) * CFrame.Angles(0, 0, -0.3 * s), p.deep)
				c:box(Vector3.new(0.08, 0.16, 0.06), CFrame.new(0.20 * s, -0.56, 0.94), WASHI)
				c:rod(Vector3.new(0.50 * s, -0.36, 0.92), Vector3.new(1.00 * s, -0.10, 1.02), 0.025, GOLD, METAL, false)
				c:cone(Vector3.new(0.22, 0.50, 0.40), CFrame.new(0.92 * s, -0.20, 0.20) * CFrame.Angles(0, 0, -math.pi / 2 * s), p.light)
				c:box(Vector3.new(0.40, 0.10, 0.46), CFrame.new(0.90 * s, -0.80, 0.30) * CFrame.Angles(0, 0, -0.4 * s), p.light)
				c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(1.10 * s, 0.60 + 0.30 * s, 0.30), p.glow, NEON)
			end
			for i = 0, 2 do
				c:cone(Vector3.new(0.18, 0.30, 0.30), CFrame.new(0, 0.86 - i * 0.40, -0.92 - i * 0.18) * CFrame.Angles(-0.5 - i * 0.3, 0, 0), p.dark)
			end
			c:eyes(-0.06, 0.94, 0.34, 0.14)
			c:box(Vector3.new(0.70, 0.14, 0.06), CFrame.new(0, -0.48, 0.92), INK)
		end,
	}

	-- An ittan-momen: a long strip of white cotton that flies through the
	-- night sky, rearing up in an S with its face at the top, little cloth
	-- arms, gold-leaf hems and waves, red tassels and neon wind behind it.
	S.so_t_ittanmomen = {
		label = "Ittan Momen",
		set = "shoguns_oath",
		tint = C3(240, 244, 255),
		head = CFrame.new(0, 1.62, 0.10),
		neck = CFrame.new(0, 0.40, 0.50),
		back = CFrame.new(0, -0.40, -0.90),
		build = function(c, p)
			local pts = {
				Vector3.new(0, -0.60, -1.60), Vector3.new(0, -0.90, -0.90), Vector3.new(0, -0.60, -0.20),
				Vector3.new(0, 0, 0.20), Vector3.new(0, 0.70, 0.30), Vector3.new(0, 1.30, 0.15),
			}
			for k = 1, 5 do
				local a, b = pts[k], pts[k + 1]
				local cf = CFrame.lookAt((a + b) * 0.5, b)
				local len = (b - a).Magnitude + 0.06
				c:box(Vector3.new(1.20, 0.07, len), cf, k % 2 == 0 and p.light or p.base)
				c:box(Vector3.new(0.08, 0.09, len), cf * CFrame.new(0.60, 0, 0), GOLD, METAL)
				if k <= 3 then
					c:cyl(Vector3.new(0.04, 0.40, 0.40), cf * CFrame.new(-0.20, 0.05, 0) * UP, GOLD, METAL)
				end
			end
			local top = CFrame.lookAt((pts[5] + pts[6]) * 0.5, pts[6])
			c:eye(top * Vector3.new(-0.22, 0.10, -0.08), 0.11)
			c:eye(top * Vector3.new(0.22, 0.10, -0.08), 0.11)
			c:box(Vector3.new(0.16, 0.05, 0.06), top * CFrame.new(0, 0.06, 0.16), INK)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.18, 0.05, 0.10), top * CFrame.new(0.40 * s, 0.06, 0.06), BLUSH)
				c:box(Vector3.new(0.50, 0.06, 0.24), CFrame.new(0.78 * s, 0.30, 0.30) * CFrame.Angles(0, 0, -0.5 * s), p.base)
				ribbon(c, pts[1] + Vector3.new(0.40 * s, 0, 0), pts[1] + Vector3.new(0.50 * s, -0.40, -0.30), 0.08, RED)
				c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(pts[1] + Vector3.new(0.50 * s, -0.44, -0.33)), GOLD, METAL)
			end
			for _, v in ipairs({ { -0.90, 0.80, -0.60 }, { 0.90, 0.30, -1.00 }, { -0.70, -0.30, -1.30 } }) do
				ribbon(c, Vector3.new(v[1], v[2], v[3]), Vector3.new(v[1] * 0.8, v[2] + 0.20, v[3] - 0.50), 0.06, p.glow, NEON)
			end
		end,
	}

	-- A byobu: a three-panel gold-leaf folding screen, its middle panel the
	-- face under a neon sun, indigo waves and white clouds painted on the wings,
	-- a pine bough, lacquer frames, and gold clouds drifting overhead.
	S.so_t_byobu = {
		label = "Byobu Screen",
		set = "shoguns_oath",
		tint = C3(240, 200, 90),
		scale = 1.15,
		head = CFrame.new(0, 1.30, 0),
		neck = CFrame.new(0, -0.50, 0.20),
		back = CFrame.new(0, 0.10, -0.40),
		build = function(c, p)
			local wave, pine = C3(40, 60, 160), C3(40, 120, 70)
			local panels = {
				CFrame.new(0, 0.10, 0),
				CFrame.new(0.78, 0.10, -0.23) * CFrame.Angles(0, 0.6, 0),
				CFrame.new(-0.78, 0.10, -0.23) * CFrame.Angles(0, -0.6, 0),
			}
			for i, cf in ipairs(panels) do
				local w = i == 1 and 0.90 or 0.80
				c:box(Vector3.new(w, 1.90, 0.10), cf, p.base, METAL)
				c:box(Vector3.new(w + 0.04, 0.10, 0.14), cf * CFrame.new(0, 0.95, 0), p.dark)
				c:box(Vector3.new(w + 0.04, 0.10, 0.14), cf * CFrame.new(0, -0.95, 0), p.dark)
				if i > 1 then
					c:box(Vector3.new(0.70, 0.20, 0.04), cf * CFrame.new(0, 0.40, 0.06), WASHI)
					for k, d in ipairs({ 0.56, 0.36, 0.16 }) do
						c:cyl(Vector3.new(0.04, d, d), cf * CFrame.new(0, -0.62, 0.05 + k * 0.01) * FRONT, k == 2 and WASHI or wave)
					end
				end
			end
			c:box(Vector3.new(0.50, 0.12, 0.04), panels[2] * CFrame.new(0, 0.10, 0.06) * CFrame.Angles(0, 0, 0.3), pine)
			c:box(Vector3.new(0.30, 0.20, 0.04), panels[2] * CFrame.new(0.10, 0.10, 0.07), pine)
			c:cyl(Vector3.new(0.05, 0.50, 0.50), CFrame.new(0, 0.80, 0.06) * FRONT, p.glow, NEON)
			c:eyes(0.30, 0.10, 0.22, 0.11)
			blush(c, 0.34, 0.08, 0.07)
			c:box(Vector3.new(0.16, 0.06, 0.04), CFrame.new(0, 0.02, 0.07), INK)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.30, 0.20, 0.40), CFrame.new(0.30 * s, -0.95, 0.05), p.dark)
			end
			for _, v in ipairs({ { -0.60, 1.40, 0.30 }, { 0.70, 1.30, 0.10 }, { 0.05, 1.56, -0.10 } }) do
				c:round(Vector3.new(0.50, 0.20, 0.30), CFrame.new(v[1], v[2], v[3]), GOLD, METAL)
			end
		end,
	}

	-- A tenshu: a castle keep on its stone base, three tiers of white walls
	-- under copper-green roofs with gables, neon-lit windows, gold shachihoko
	-- on the ridge, a little war banner, and a glowing moon beside it.
	S.so_t_castle = {
		label = "Tenshu Castle",
		set = "shoguns_oath",
		tint = C3(70, 170, 150),
		scale = 1.20,
		head = CFrame.new(0, 2.00, 0),
		neck = CFrame.new(0, -0.70, 1.00),
		back = CFrame.new(0, 0, -0.96),
		build = function(c, p)
			local stone = C3(150, 144, 132)
			c:box(Vector3.new(2.20, 0.50, 1.80), CFrame.new(0, -0.85, 0), stone)
			c:box(Vector3.new(2.22, 0.04, 1.82), CFrame.new(0, -0.80, 0), C3(110, 106, 98))
			c:box(Vector3.new(2.22, 0.04, 1.82), CFrame.new(0, -0.96, 0), C3(110, 106, 98))
			for _, t in ipairs({
				{ -0.25, 0.70, 1.90, 1.50, 2.30, 1.90, 0.14, 2.10, 1.70, 0.33 },
				{ 0.62, 0.50, 1.30, 1.00, 1.70, 1.40, 0.90, 1.50, 1.20, 1.08 },
			}) do
				c:box(Vector3.new(t[3], t[2], t[4]), CFrame.new(0, t[1], 0), WASHI)
				c:box(Vector3.new(t[5], 0.10, t[6]), CFrame.new(0, t[7], 0), p.base)
				c:prism(Vector3.new(t[8], 0.30, t[9]), CFrame.new(0, t[10], 0), p.base)
				c:prism(Vector3.new(0.30, 0.30, 0.60), CFrame.new(0, t[10] + 0.04, t[9] * 0.5) * FRONT, p.dark)
				c:cyl(Vector3.new(0.04, 0.14, 0.14), CFrame.new(0, t[10], t[9] * 0.5 + 0.16) * FRONT, GOLD, METAL)
			end
			c:box(Vector3.new(0.80, 0.40, 0.60), CFrame.new(0, 1.32, 0), WASHI)
			c:prism(Vector3.new(1.10, 0.36, 0.80), CFrame.new(0, 1.60, 0), p.base)
			for _, x in ipairs({ -0.30, 0.30 }) do
				c:box(Vector3.new(0.18, 0.18, 0.04), CFrame.new(x, 0.62, 0.51), p.glow, NEON)
			end
			c:box(Vector3.new(0.18, 0.16, 0.04), CFrame.new(0, 1.32, 0.31), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.10, 0.26, 0.20), CFrame.new(0.44 * s, 1.86, 0) * CFrame.Angles(0, 0, 0.5 * s), GOLD, METAL)
				c:box(Vector3.new(0.40, 0.20, 0.50), CFrame.new(0.70 * s, -1.18, 0.30), C3(110, 106, 98))
			end
			c:eyes(-0.22, 0.78, 0.36, 0.14)
			blush(c, 0.66, -0.40, 0.76)
			c:box(Vector3.new(0.20, 0.07, 0.05), CFrame.new(0, -0.44, 0.77), INK)
			c:rod(Vector3.new(1.00, -0.60, -0.60), Vector3.new(1.00, 0.80, -0.60), 0.03, TIMBER, nil, false)
			c:box(Vector3.new(0.04, 0.70, 0.30), CFrame.new(1.00, 0.40, -0.44), RED)
			c:ball(Vector3.new(0.40, 0.40, 0.40), CFrame.new(-1.10, 1.50, -0.40), p.glow, NEON)
		end,
	}

	-- An amabie: the lucky sea yokai, a scaly round body, long flowing hair, a
	-- little diamond beak, three fish tails for feet and neon droplets about it.
	S.so_t_amabie = {
		label = "Amabie",
		set = "shoguns_oath",
		tint = C3(80, 220, 200),
		head = CFrame.new(0, 1.30, -0.10),
		neck = CFrame.new(0, -0.40, 0.80),
		back = CFrame.new(0, 0.20, -0.96),
		build = function(c, p)
			c:round(Vector3.new(1.60, 1.70, 1.40), CFrame.new(0, 0, 0), p.base)
			c:round(Vector3.new(1.80, 1.00, 1.60), CFrame.new(0, 0.75, -0.10), p.pale)
			c:box(Vector3.new(1.20, 0.25, 0.12), CFrame.new(0, 0.70, 0.70), p.pale)
			for i, v in ipairs({ { -0.85, 0.10 }, { 0.85, 0.10 }, { -0.60, -0.70 }, { 0.60, -0.70 }, { 0, -0.85 } }) do
				c:box(Vector3.new(0.30, 1.60, 0.14), CFrame.new(v[1], -0.10, v[2]) * CFrame.Angles(0, math.atan2(v[1], v[2]), 0), i % 2 == 0 and p.light or p.pale)
			end
			c:eyes(0.26, 0.70, 0.30, 0.12)
			blush(c, 0.50, 0.04, 0.68)
			c:box(Vector3.new(0.30, 0.30, 0.20), CFrame.new(0, -0.04, 0.76) * CFrame.Angles(0, 0, math.pi / 4), BEAK)
			for _, v in ipairs({ { -0.30, -0.40 }, { 0, -0.40 }, { 0.30, -0.40 }, { -0.15, -0.64 }, { 0.15, -0.64 } }) do
				c:cyl(Vector3.new(0.05, 0.30, 0.30), CFrame.new(v[1], v[2], 0.70) * FRONT, p.light)
			end
			for _, v in ipairs({ { -0.45, 0.30 }, { 0.45, 0.30 }, { 0, -0.45 } }) do
				c:round(Vector3.new(0.30, 0.40, 0.30), CFrame.new(v[1], -0.80, v[2]), p.dark)
				c:box(Vector3.new(0.50, 0.10, 0.40), CFrame.new(v[1], -1.00, v[2] * 1.3), p.light)
			end
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.40, 0.10, 0.30), CFrame.new(0.86 * s, -0.20, 0.40) * CFrame.Angles(0, 0, -0.4 * s), p.light)
			end
			for _, v in ipairs({ { -1.10, 1.10, 0.30 }, { 1.05, 0.90, 0.40 }, { -0.20, 1.50, 0.40 }, { 0.70, 1.45, -0.20 } }) do
				c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(v[1], v[2], v[3]), p.glow, NEON)
			end
		end,
	}

	-- A gissha: a Heian court ox-carriage in black lacquer, its face behind
	-- the bamboo blind, two great spoked wheels with neon hubs, gold trim,
	-- purple tassels, long shafts in front and sakura petals drifting.
	S.so_t_gissha = {
		label = "Gissha Carriage",
		set = "shoguns_oath",
		tint = C3(120, 30, 50),
		scale = 1.10,
		head = CFrame.new(0, 1.30, 0),
		neck = CFrame.new(0, -0.40, 1.40),
		back = CFrame.new(0, 0.30, -0.96),
		build = function(c, p)
			local tassel = C3(150, 70, 200)
			c:box(Vector3.new(1.40, 1.20, 1.60), CFrame.new(0, 0.10, 0), p.base)
			c:box(Vector3.new(1.70, 0.18, 1.90), CFrame.new(0, 0.78, 0), p.dark)
			c:prism(Vector3.new(1.80, 0.36, 1.60), CFrame.new(0, 1.02, 0) * FRONT, p.dark)
			c:box(Vector3.new(1.74, 0.06, 0.08), CFrame.new(0, 0.86, 0.96), GOLD, METAL)
			c:box(Vector3.new(1.74, 0.06, 0.08), CFrame.new(0, 0.86, -0.96), GOLD, METAL)
			c:cyl(Vector3.new(0.05, 0.24, 0.24), CFrame.new(0, 1.00, 0.92) * FRONT, GOLD, METAL)
			c:box(Vector3.new(1.20, 0.90, 0.06), CFrame.new(0, 0.10, 0.82), ROPE)
			for _, y in ipairs({ 0.40, -0.20 }) do
				c:box(Vector3.new(1.20, 0.03, 0.08), CFrame.new(0, y, 0.84), C3(160, 120, 60))
			end
			c:eyes(0.12, 0.86, 0.30, 0.12)
			blush(c, 0.46, -0.06, 0.85)
			c:box(Vector3.new(0.16, 0.06, 0.04), CFrame.new(0, -0.10, 0.86), INK)
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.55 * s, 0.50, 0.86), Vector3.new(0.55 * s, 0.10, 0.90), 0.03, tassel, nil, false)
				c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.55 * s, 0.04, 0.90), tassel)
				c:cyl(Vector3.new(0.16, 2.00, 2.00), CFrame.new(0.85 * s, -0.10, 0), p.deep)
				c:box(Vector3.new(0.06, 1.80, 0.10), CFrame.new(0.95 * s, -0.10, 0), p.light)
				c:box(Vector3.new(0.06, 0.10, 1.80), CFrame.new(0.95 * s, -0.10, 0), p.light)
				c:cyl(Vector3.new(0.16, 0.36, 0.36), CFrame.new(1.00 * s, -0.10, 0), p.glow, NEON)
				c:rod(Vector3.new(0.50 * s, -0.40, 0.80), Vector3.new(0.50 * s, -0.55, 1.60), 0.05, p.dark, nil, false)
			end
			c:box(Vector3.new(1.20, 0.10, 0.10), CFrame.new(0, -0.55, 1.56), p.dark)
			for _, v in ipairs({ { -0.80, 1.30, 0.60 }, { 0.90, 1.10, 0.80 }, { 0.20, 1.50, -0.40 } }) do
				c:round(Vector3.new(0.20, 0.24, 0.06), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0, 0, 0.6), p.glow, NEON)
			end
		end,
	}

	-- A great tengu of the mountains: a red face with a long proud nose, bushy
	-- white brows and beard, a tiny black cap, crow-black wings, a monk's robe
	-- with pom-poms, one-toothed geta and a ringed staff; neon feathers drift.
	S.so_t_tengu = {
		label = "Mountain Tengu",
		set = "shoguns_oath",
		tint = C3(230, 50, 40),
		scale = 1.15,
		head = CFrame.new(0, 1.30, 0),
		neck = CFrame.new(0, -0.40, 0.90),
		back = CFrame.new(0, 0.20, -1.00),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.70, 1.80, 1.50), mouth = false, legs = false, tail = false,
				eyeY = 0.30, eyeSpread = 0.34, eyeSize = Vector3.new(0.34, 0.40, 0.18),
			})
			c:box(Vector3.new(1.76, 0.80, 1.56), CFrame.new(0, -0.55, 0), C3(242, 238, 228))
			c:box(Vector3.new(1.80, 0.12, 1.60), CFrame.new(0, -0.22, 0), p.dark)
			c:rod(Vector3.new(0, 0.06, 0.74), Vector3.new(0, 0.12, 1.36), 0.13, p.base)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.42, 0.14, 0.12), CFrame.new(0.34 * s, 0.62, 0.78) * CFrame.Angles(0, 0, -0.3 * s), WASHI)
				for i = 0, 2 do
					c:box(Vector3.new(0.12, 1.10 - i * 0.16, 0.40), CFrame.new((0.98 + i * 0.16) * s, 0.30 + i * 0.06, -0.50) * CFrame.Angles(0, 0, -(0.30 + i * 0.32) * s), p.deep)
				end
				c:box(Vector3.new(0.40, 0.12, 0.60), CFrame.new(0.40 * s, -1.06, 0), TIMBER)
				c:box(Vector3.new(0.10, 0.24, 0.30), CFrame.new(0.40 * s, -1.24, 0), TIMBER)
			end
			c:round(Vector3.new(0.80, 0.50, 0.24), CFrame.new(0, -0.28, 0.82), WASHI)
			c:box(Vector3.new(0.36, 0.30, 0.36), CFrame.new(0, 1.06, 0.20) * CFrame.Angles(0, math.pi / 4, 0), SUMI)
			for i, x in ipairs({ -0.36, 0, 0.36 }) do
				c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(x, -0.62, 0.82), i == 2 and p.glow or p.light, i == 2 and NEON or nil)
			end
			c:rod(Vector3.new(1.10, -1.10, 0.40), Vector3.new(1.10, 1.30, 0.40), 0.04, TIMBER, nil, false)
			c:cyl(Vector3.new(0.06, 0.40, 0.40), CFrame.new(1.10, 1.44, 0.40) * FRONT, GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:ball(Vector3.new(0.12, 0.12, 0.12), CFrame.new(1.10 + 0.20 * s, 1.30, 0.40), GOLD, METAL)
			end
			c:rod(Vector3.new(0.80, -0.10, 0.30), Vector3.new(1.08, 0, 0.40), 0.09, p.base, nil, false)
			c:box(Vector3.new(0.10, 0.04, 0.40), CFrame.new(-1.30, 1.20, 0.30) * CFrame.Angles(0.4, 0, 0.5), p.glow, NEON)
			c:box(Vector3.new(0.10, 0.04, 0.36), CFrame.new(1.50, 0.70, -0.30) * CFrame.Angles(-0.3, 0, -0.4), p.glow, NEON)
		end,
	}

	-- A kanabo oni: a chubby little blue ogre, a mop of curly hair, two ivory
	-- horns, a cheeky tusked grin, gold earrings, a tiger-striped wrap and a
	-- big iron club studded with neon.
	S.so_t_oni = {
		label = "Kanabo Oni",
		set = "shoguns_oath",
		tint = C3(60, 120, 240),
		scale = 1.15,
		head = CFrame.new(0, 1.50, 0),
		neck = CFrame.new(0, -0.30, 0.96),
		back = CFrame.new(0, 0.20, -0.96),
		build = function(c, p)
			local tiger = C3(250, 190, 40)
			block(c, p, {
				tail = false, brow = p.deep, mouthSize = Vector3.new(0.60, 0.16, 0.14), mouthY = -0.30,
				legColor = tiger,
			})
			c:round(Vector3.new(1.90, 0.50, 1.70), CFrame.new(0, 1.00, -0.04), SUMI)
			c:ball(Vector3.new(0.40, 0.40, 0.40), CFrame.new(-0.40, 1.24, 0.40), SUMI)
			c:ball(Vector3.new(0.40, 0.40, 0.40), CFrame.new(0.40, 1.24, 0.40), SUMI)
			c:box(Vector3.new(2.06, 0.50, 1.84), CFrame.new(0, -0.60, 0), tiger)
			for _, x in ipairs({ -0.50, 0, 0.50 }) do
				c:box(Vector3.new(0.10, 0.44, 0.06), CFrame.new(x, -0.60, 0.93) * CFrame.Angles(0, 0, 0.3), SUMI)
			end
			for _, s in ipairs(SIDES) do
				c:cone(Vector3.new(0.26, 0.50, 0.26), CFrame.new(0.42 * s, 1.40, 0.10) * CFrame.Angles(0, 0, -0.2 * s), WASHI)
				c:box(Vector3.new(0.08, 0.16, 0.06), CFrame.new(0.20 * s, -0.18, 0.97), WASHI)
				c:cyl(Vector3.new(0.06, 0.30, 0.30), CFrame.new(1.04 * s, 0.00, 0.10), GOLD, METAL)
			end
			c:round(Vector3.new(0.40, 0.70, 0.40), CFrame.new(1.10, -0.20, 0.30), p.base)
			c:round(Vector3.new(0.40, 0.70, 0.40), CFrame.new(-1.12, 0.20, 0.20) * CFrame.Angles(0, 0, -0.6), p.base)
			c:rod(Vector3.new(1.10, -0.60, 0.50), Vector3.new(1.40, 1.10, 0.30), 0.14, C3(60, 60, 70))
			c:box(Vector3.new(0.32, 0.30, 0.32), CFrame.new(1.12, -0.48, 0.49) * CFrame.Angles(0, 0, -0.17), RED)
			for i = 1, 4 do
				local t = 0.35 + i * 0.15
				c:ball(Vector3.new(0.14, 0.14, 0.14), CFrame.new(1.10 + 0.30 * t, -0.60 + 1.70 * t, 0.66 - 0.20 * t), p.glow, NEON)
			end
		end,
	}

	----------------------------------------------------------------------------
	-- DIVINE: heavenly, glowing, a little translucent (the tier skin).
	----------------------------------------------------------------------------

	-- A cone frame whose point (+Y) faces `dir`, sat at `pos`.
	local function pointing(pos, dir)
		if dir.Y > 0.99 then
			return CFrame.new(pos)
		end
		return CFrame.lookAt(pos, pos + dir) * CFrame.Angles(-math.pi / 2, 0, 0)
	end

	-- The yatagarasu: the three-legged crow of the sun who guides travellers,
	-- wings raised before a great neon sun disc, a gold plume, sparkles.
	S.so_t_yatagarasu = {
		label = "Yatagarasu",
		set = "shoguns_oath",
		tint = C3(60, 50, 110),
		scale = 1.20,
		head = CFrame.new(0, 1.10, 0.10),
		neck = CFrame.new(0, -0.30, 0.86),
		back = CFrame.new(0, 0.40, -1.10),
		build = function(c, p)
			c:cyl(Vector3.new(0.10, 2.20, 2.20), CFrame.new(0, 0.40, -0.90) * FRONT, p.glow, NEON)
			c:cyl(Vector3.new(0.08, 2.40, 2.40), CFrame.new(0, 0.40, -0.96) * FRONT, GOLD, METAL)
			c:round(Vector3.new(1.60, 1.60, 1.60), CFrame.new(0, 0.10, 0), p.base)
			c:box(Vector3.new(0.60, 0.12, 0.70), CFrame.new(0, -0.30, -0.95) * CFrame.Angles(0.4, 0, 0), p.dark)
			c:cone(Vector3.new(0.26, 0.36, 0.26), CFrame.new(0, 0.10, 0.90) * CFrame.Angles(math.pi / 2, 0, 0), BEAK)
			for _, s in ipairs(SIDES) do
				c:round(Vector3.new(0.40, 0.46, 0.10), CFrame.new(0.30 * s, 0.36, 0.76), WASHI)
				c:round(Vector3.new(1.00, 0.50, 0.70), CFrame.new(0.95 * s, 0.45, -0.15) * CFrame.Angles(0, 0, -0.5 * s), p.base)
				for i = 0, 2 do
					c:box(Vector3.new(0.12, 0.80, 0.28), CFrame.new((1.30 + 0.12 * i) * s, 0.95 - 0.20 * i, -0.15 - 0.10 * i) * CFrame.Angles(0, 0, -(0.60 + 0.30 * i) * s), p.dark)
				end
			end
			c:eyes(0.36, 0.84, 0.30, 0.12)
			for i, x in ipairs({ -0.35, 0, 0.35 }) do
				local z = i == 2 and 0.24 or 0.06
				c:rod(Vector3.new(x, -0.56, z), Vector3.new(x, -1.00, z + 0.04), 0.05, BEAK, nil, false)
				c:box(Vector3.new(0.22, 0.06, 0.30), CFrame.new(x, -1.02, z + 0.12), BEAK)
			end
			for i, a in ipairs({ -0.4, 0, 0.4 }) do
				c:box(Vector3.new(0.10, 0.50 - math.abs(a) * 0.3, 0.06), CFrame.new(0.40 * a, 0.98, 0.20) * CFrame.Angles(0, 0, -a), GOLD, METAL)
			end
			c:star(Vector3.new(-1.20, 1.40, 0.30), 0.30, p.glow)
			c:star(Vector3.new(1.10, -0.40, 0.50), 0.24, p.glow)
		end,
	}

	-- A magatama: the comma-shaped jade jewel of the imperial treasures, a
	-- glowing heart inside, a gold cord and crest above, a neon halo, two
	-- little magatama circling it and soft clouds below.
	S.so_t_magatama = {
		label = "Magatama",
		set = "shoguns_oath",
		tint = C3(40, 210, 130),
		head = CFrame.new(0.15, 1.60, 0),
		neck = CFrame.new(0, -0.40, 0.80),
		back = CFrame.new(0, 0.20, -0.80),
		build = function(c, p)
			c:ball(Vector3.new(1.60, 1.60, 1.60), CFrame.new(0.15, 0.30, 0), p.base)
			c:ball(Vector3.new(0.80, 0.80, 0.80), CFrame.new(0.15, 0.30, 0), p.glow, NEON)
			for _, v in ipairs({ { -0.35, -0.25, 1.20 }, { -0.25, -0.75, 0.90 }, { 0.15, -1.00, 0.65 }, { 0.55, -1.00, 0.42 } }) do
				c:ball(Vector3.new(v[3], v[3], v[3]), CFrame.new(v[1], v[2], 0), p.base)
			end
			c:cyl(Vector3.new(0.10, 0.28, 0.28), CFrame.new(0.40, 0.84, 0.48) * FRONT, INK)
			c:rod(Vector3.new(0.40, 0.88, 0.40), Vector3.new(0.10, 1.40, 0), 0.03, GOLD, METAL, false)
			c:rod(Vector3.new(0.40, 0.88, 0.40), Vector3.new(0.60, 1.40, 0), 0.03, GOLD, METAL, false)
			c:cyl(Vector3.new(0.06, 0.36, 0.36), CFrame.new(0.35, 1.45, 0) * FRONT, GOLD, METAL)
			c:eye(Vector3.new(-0.13, 0.36, 0.72), 0.12)
			c:eye(Vector3.new(0.43, 0.36, 0.72), 0.12)
			c:box(Vector3.new(0.16, 0.06, 0.04), CFrame.new(0.15, 0.12, 0.78), INK)
			c:box(Vector3.new(0.18, 0.10, 0.05), CFrame.new(-0.30, 0.16, 0.66), BLUSH)
			c:box(Vector3.new(0.18, 0.10, 0.05), CFrame.new(0.60, 0.16, 0.66), BLUSH)
			halo(c, 1.70, 0, 0.50, p.glow)
			for _, v in ipairs({ { -1.20, 0.80, 0.30 }, { 1.20, -0.30, -0.20 } }) do
				c:ball(Vector3.new(0.40, 0.40, 0.40), CFrame.new(v[1], v[2], v[3]), p.light)
				c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(v[1] - 0.12, v[2] - 0.24, v[3]), p.glow, NEON)
			end
			c:round(Vector3.new(0.90, 0.24, 0.60), CFrame.new(-0.40, -1.16, 0.10), WASHI)
			c:round(Vector3.new(0.80, 0.22, 0.50), CFrame.new(0.50, -1.24, -0.10), WASHI)
		end,
	}

	-- A hokora: a tiny Shinto house on stilts, its doors the face, crossed gold
	-- chigi and neon katsuogi logs on the thatch, a sacred rope with paper
	-- zigzags, sakaki sprigs in white vases and blessing lights floating.
	S.so_t_hokora = {
		label = "Hokora",
		set = "shoguns_oath",
		tint = C3(255, 228, 160),
		scale = 1.10,
		head = CFrame.new(0, 1.70, 0),
		neck = CFrame.new(0, -0.50, 0.90),
		back = CFrame.new(0, 0.20, -0.86),
		build = function(c, p)
			c:box(Vector3.new(1.50, 1.10, 1.30), CFrame.new(0, 0, 0), p.base)
			c:box(Vector3.new(1.80, 0.12, 1.60), CFrame.new(0, -0.61, 0), p.dark)
			c:box(Vector3.new(0.80, 0.10, 0.30), CFrame.new(0, -0.80, 0.90), p.dark)
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.62, -0.62 }) do
					c:box(Vector3.new(0.16, 0.50, 0.16), CFrame.new(0.76 * s, -0.92, z), p.dark)
				end
				c:box(Vector3.new(0.08, 0.70, 0.12), CFrame.new(0.90 * s, 1.36, 0) * CFrame.Angles(0, 0, 0.45), GOLD, METAL)
				c:box(Vector3.new(0.08, 0.70, 0.12), CFrame.new(0.90 * s, 1.36, 0) * CFrame.Angles(0, 0, -0.45), GOLD, METAL)
				c:cyl(Vector3.new(0.30, 0.18, 0.18), CFrame.new(0.95 * s, -0.40, 0.95) * UP, WASHI)
				c:box(Vector3.new(0.20, 0.40, 0.10), CFrame.new(0.95 * s, -0.10, 0.95) * CFrame.Angles(0, 0, 0.3 * s), LEAF)
				c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(1.20 * s, 0.90 + 0.20 * s, 0.60), p.glow, NEON)
			end
			c:prism(Vector3.new(1.90, 0.70, 1.70), CFrame.new(0, 0.90, 0), p.deep)
			for _, x in ipairs({ -0.40, 0, 0.40 }) do
				c:cyl(Vector3.new(0.50, 0.16, 0.16), CFrame.new(x, 1.30, 0) * FRONT, p.glow, NEON)
			end
			c:box(Vector3.new(1.00, 0.80, 0.04), CFrame.new(0, -0.05, 0.66), p.light)
			c:box(Vector3.new(0.04, 0.80, 0.06), CFrame.new(0, -0.05, 0.67), p.dark)
			c:eyes(0.08, 0.70, 0.26, 0.12)
			blush(c, 0.36, -0.12, 0.69)
			c:box(Vector3.new(0.14, 0.05, 0.04), CFrame.new(0.14, -0.22, 0.69), INK)
			c:rod(Vector3.new(-0.74, 0.48, 0.72), Vector3.new(0.74, 0.48, 0.72), 0.07, ROPE, nil, false)
			for _, x in ipairs({ -0.40, 0, 0.40 }) do
				c:box(Vector3.new(0.10, 0.24, 0.04), CFrame.new(x, 0.32, 0.76) * CFrame.Angles(0, 0, 0.3), WASHI)
			end
		end,
	}

	-- A kusudama: a paper ball of folded blossoms, neon at their hearts, a
	-- face on its front flower, a red hanging loop and a long golden tassel.
	S.so_t_kusudama = {
		label = "Kusudama",
		set = "shoguns_oath",
		tint = C3(250, 130, 40),
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, -0.60, 0.80),
		back = CFrame.new(0, 0.10, -0.96),
		build = function(c, p)
			c:ball(Vector3.new(1.80, 1.80, 1.80), CFrame.new(0, 0.10, 0), p.base)
			local dirs = {
				Vector3.new(0, 1, 0), Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
				Vector3.new(0, 0, -1), Vector3.new(0.6, -0.6, 0.5).Unit, Vector3.new(-0.6, -0.6, 0.5).Unit,
			}
			for i, d in ipairs(dirs) do
				local at = Vector3.new(0, 0.10, 0) + d * 0.90
				c:cone(Vector3.new(0.50, 0.40, 0.50), pointing(at, d), p.light)
				if i <= 3 then
					c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(at + d * 0.22), p.glow, NEON)
				end
			end
			c:round(Vector3.new(1.00, 0.80, 0.20), CFrame.new(0, 0.12, 0.86), p.pale)
			c:eyes(0.20, 0.96, 0.26, 0.12)
			blush(c, 0.36, 0.00, 0.96)
			c:box(Vector3.new(0.14, 0.05, 0.04), CFrame.new(0, -0.06, 0.97), INK)
			c:rod(Vector3.new(0, 0.95, 0), Vector3.new(0, 1.30, 0), 0.03, RED, nil, false)
			c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0, 1.32, 0), GOLD, METAL)
			c:rod(Vector3.new(0, -0.78, 0), Vector3.new(0, -1.00, 0), 0.03, RED, nil, false)
			c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0, -1.02, 0), GOLD, METAL)
			c:box(Vector3.new(0.30, 0.40, 0.30), CFrame.new(0, -1.30, 0), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.12, 0.90, 0.04), CFrame.new(0.30 * s, -1.00, 0.20) * CFrame.Angles(0, 0, 0.15 * s), p.light)
			end
		end,
	}

	----------------------------------------------------------------------------
	-- EXOTIC: the rarest; the tier skin cycles their colour.
	----------------------------------------------------------------------------

	-- A raku tea bowl mended with gold (kintsugi): gold seams zigzag over it,
	-- one of them neon, frothy matcha inside, steam rising, a whisk floating
	-- by, and a glowing ring beneath.
	S.so_t_teabowl = {
		label = "Raku Teabowl",
		set = "shoguns_oath",
		tint = C3(150, 70, 60),
		scale = 1.10,
		head = CFrame.new(0, 0.80, 0),
		neck = CFrame.new(0, -0.50, 1.16),
		back = CFrame.new(0, 0, -1.16),
		build = function(c, p)
			c:cyl(Vector3.new(1.30, 2.20, 2.20), CFrame.new(0, -0.25, 0) * UP, p.base)
			c:cyl(Vector3.new(0.20, 1.20, 1.20), CFrame.new(0, -0.98, 0) * UP, p.dark)
			c:cyl(Vector3.new(0.10, 2.26, 2.26), CFrame.new(0, 0.42, 0) * UP, p.light)
			c:cyl(Vector3.new(0.04, 2.00, 2.00), CFrame.new(0, 0.46, 0) * UP, C3(120, 180, 60))
			for _, v in ipairs({ { -0.40, 0.20 }, { 0.30, -0.30 }, { 0.10, 0.50 } }) do
				c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(v[1], 0.48, v[2]), C3(190, 230, 140))
			end
			for k, a in ipairs({ 0.9, -0.9, math.pi }) do
				local col, mat = k == 3 and p.glow or GOLD, k == 3 and NEON or METAL
				for j = 0, 2 do
					c:box(Vector3.new(0.06, 0.46, 0.05), CFrame.Angles(0, a, 0) * CFrame.new((j % 2) * 0.16 - 0.08, 0.20 - j * 0.40, 1.12) * CFrame.Angles(0, 0, j % 2 == 0 and 0.5 or -0.5), col, mat)
				end
			end
			c:eyes(-0.10, 1.12, 0.34, 0.14)
			blush(c, 0.60, -0.36, 1.10)
			c:box(Vector3.new(0.22, 0.07, 0.05), CFrame.new(0, -0.40, 1.12), INK)
			for i, v in ipairs({ { -0.30, 0.90, 0 }, { 0.20, 1.20, 0.10 }, { -0.10, 1.50, -0.10 } }) do
				c:ball(Vector3.new(0.30 - i * 0.05, 0.30 - i * 0.05, 0.30 - i * 0.05), CFrame.new(v[1], v[2], v[3]), p.glow, NEON)
			end
			c:rod(Vector3.new(1.40, 0.90, 0.20), Vector3.new(1.40, 0.40, 0.20), 0.05, TIMBER, nil, false)
			c:cone(Vector3.new(0.40, 0.40, 0.40), CFrame.new(1.40, 0.20, 0.20) * CFrame.Angles(math.pi, 0, 0), C3(220, 210, 160))
			halo(c, -1.08, 0, 1.00, p.glow)
		end,
	}

	-- A gold-leaf great wave: a deep swell whose crest curls forward over its
	-- face like a hood, foam fingers at the lip, seigaiha scales in gold leaf
	-- on its front and neon spray leaping off.
	S.so_t_wave = {
		label = "Seigaiha Wave",
		set = "shoguns_oath",
		tint = C3(30, 90, 210),
		scale = 1.10,
		head = CFrame.new(0, 1.60, 0),
		neck = CFrame.new(0, -0.70, 0.96),
		back = CFrame.new(0, 0, -1.00),
		build = function(c, p)
			c:round(Vector3.new(2.00, 1.00, 1.80), CFrame.new(0, -0.60, 0), p.base)
			for i, v in ipairs({ { 0, -0.10, -0.50, 0.3 }, { 0, 0.55, -0.55, -0.2 }, { 0, 1.10, -0.25, -0.9 }, { 0, 1.30, 0.25, -1.6 }, { 0, 1.10, 0.62, -2.3 } }) do
				local w = 1.80 - i * 0.10
				c:round(Vector3.new(w, 0.60, 0.70), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(v[4], 0, 0), i % 2 == 0 and p.light or p.base)
			end
			c:round(Vector3.new(1.20, 0.60, 0.50), CFrame.new(0, 0.55, 0.05), p.deep)
			for _, x in ipairs({ -0.60, -0.20, 0.20, 0.60 }) do
				c:cone(Vector3.new(0.26, 0.40, 0.26), pointing(Vector3.new(x, 0.80, 0.90), Vector3.new(0, -0.6, 0.8)), WASHI)
			end
			c:eyes(-0.46, 0.92, 0.34, 0.13)
			blush(c, 0.62, -0.68, 0.90)
			c:box(Vector3.new(0.20, 0.07, 0.05), CFrame.new(0, -0.74, 0.92), INK)
			for _, s in ipairs(SIDES) do
				seigaiha(c, 0.70 * s, -0.86, 0.90, 0.40, GOLD)
			end
			for _, v in ipairs({ { -1.10, 1.30, 0.60 }, { 1.00, 1.50, 0.40 }, { 0.40, 1.80, 0.70 } }) do
				c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(v[1], v[2], v[3]), p.glow, NEON)
			end
		end,
	}

	-- The oathbound katana: a sword stood point-down in a cloud, its round
	-- pommel the face, a gold guard, a wrapped grip, a neon edge, two spectral
	-- blades fanned behind, a streaming cord and sakura petals drifting.
	S.so_t_katana = {
		label = "Oathbound Katana",
		set = "shoguns_oath",
		tint = C3(200, 40, 80),
		scale = 1.15,
		head = CFrame.new(0, 1.90, 0),
		neck = CFrame.new(0, 0.10, 0.40),
		back = CFrame.new(0, 0.60, -0.40),
		build = function(c, p)
			for _, v in ipairs({ { -0.50, -1.15, 0.10, 0.90 }, { 0.50, -1.18, -0.10, 0.80 }, { 0, -1.05, 0, 1.00 } }) do
				c:round(Vector3.new(v[4], 0.36, v[4] * 0.7), CFrame.new(v[1], v[2], v[3]), p.pale)
			end
			c:box(Vector3.new(0.26, 1.20, 0.06), CFrame.new(0, -0.40, 0), STEEL, METAL)
			c:box(Vector3.new(0.05, 1.20, 0.07), CFrame.new(0.12, -0.40, 0), p.glow, NEON)
			c:box(Vector3.new(0.04, 1.00, 0.07), CFrame.new(-0.02, -0.36, 0), WASHI)
			c:cone(Vector3.new(0.26, 0.24, 0.06), CFrame.new(0, -1.12, 0) * CFrame.Angles(math.pi, 0, 0), STEEL, METAL)
			c:box(Vector3.new(0.30, 0.16, 0.10), CFrame.new(0, 0.26, 0), GOLD, METAL)
			c:cyl(Vector3.new(0.10, 1.00, 1.00), CFrame.new(0, 0.38, 0) * UP, GOLD, METAL)
			c:box(Vector3.new(0.32, 0.60, 0.26), CFrame.new(0, 0.73, 0), p.deep)
			c:box(Vector3.new(0.34, 0.08, 0.20), CFrame.new(0, 0.60, 0) * CFrame.Angles(0, 0, 0.6), WASHI)
			c:box(Vector3.new(0.34, 0.08, 0.20), CFrame.new(0, 0.86, 0) * CFrame.Angles(0, 0, -0.6), WASHI)
			c:ball(Vector3.new(1.00, 1.00, 1.00), CFrame.new(0, 1.40, 0), p.base)
			c:eyes(1.46, 0.44, 0.20, 0.10)
			blush(c, 0.30, 1.26, 0.40)
			c:box(Vector3.new(0.14, 0.05, 0.04), CFrame.new(0, 1.22, 0.47), INK)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.18, 2.00, 0.05), CFrame.new(0.60 * s, 0.10, -0.30) * CFrame.Angles(0, 0, 0.5 * s), p.glow, NEON)
			end
			local a, b, d = Vector3.new(0.16, 0.70, 0.10), Vector3.new(0.60, 0.20, 0.30), Vector3.new(0.90, -0.40, 0.20)
			ribbon(c, a, b, 0.10, p.light)
			ribbon(c, b, d, 0.10, p.light)
			c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(d), GOLD, METAL)
			for _, v in ipairs({ { -0.90, 1.10, 0.30 }, { 1.00, 1.30, -0.10 }, { -1.10, -0.20, 0.20 }, { 0.70, -0.80, 0.50 } }) do
				c:round(Vector3.new(0.20, 0.24, 0.06), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0, 0, v[1]), BLUSH)
			end
		end,
	}

	-- A hanabi: a summer-festival firework shell bursting, its round face in
	-- the middle, eight rays of neon sparks, its fuse fizzing below.
	S.so_t_hanabi = {
		label = "Hanabi Burst",
		set = "shoguns_oath",
		tint = C3(255, 70, 190),
		scale = 1.10,
		head = CFrame.new(0, 1.00, 0),
		neck = CFrame.new(0, -0.50, 0.70),
		back = CFrame.new(0, 0.10, -0.70),
		build = function(c, p)
			c:ball(Vector3.new(1.40, 1.40, 1.40), CFrame.new(0, 0.10, 0), p.base)
			c:cyl(Vector3.new(0.10, 1.44, 1.44), CFrame.new(0, 0.10, 0) * UP, p.dark)
			c:eyes(0.30, 0.62, 0.26, 0.12)
			blush(c, 0.40, 0.12, 0.62)
			c:ball(Vector3.new(0.18, 0.18, 0.10), CFrame.new(0, -0.08, 0.68), INK)
			for k = 0, 7 do
				local a = k * math.pi / 4 + math.pi / 8
				local d = Vector3.new(math.sin(a), math.cos(a), 0)
				local o = Vector3.new(0, 0.10, -0.10)
				c:rod(o + d * 0.75, o + d * 1.30, 0.04, p.light, nil, false)
				c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(o + d * 1.38), p.glow, NEON)
			end
			c:rod(Vector3.new(0, -0.58, -0.10), Vector3.new(0.12, -1.10, -0.20), 0.04, p.dark, nil, false)
			c:star(Vector3.new(0.12, -1.18, -0.20), 0.30, GOLD)
			c:star(Vector3.new(-0.60, 0.95, 0.40), 0.22, p.glow)
			c:star(Vector3.new(0.70, -0.40, 0.50), 0.22, p.glow)
		end,
	}

	-- A sumi inkblot: a splash of brush ink come alive, splatter lobes, drips,
	-- two flicked brush strokes, a red artist's seal, and a neon enso circle.
	S.so_t_inkblot = {
		label = "Sumi Inkblot",
		set = "shoguns_oath",
		tint = C3(36, 34, 50),
		scale = 1.10,
		head = CFrame.new(0, 1.10, 0),
		neck = CFrame.new(0, -0.40, 0.80),
		back = CFrame.new(0, 0.10, -0.80),
		build = function(c, p)
			for k = 0, 6 do
				local a = 0.5 + k * 0.80
				c:box(Vector3.new(0.50, 0.16, 0.10), CFrame.new(0, 0.10, -0.90) * CFrame.Angles(0, 0, a) * CFrame.new(0, 1.30, 0), p.glow, NEON)
			end
			c:round(Vector3.new(1.80, 1.50, 1.50), CFrame.new(0, 0, 0), p.base)
			for _, v in ipairs({ { -0.95, -0.50, 0.30, 0.60 }, { 0.95, -0.40, 0.10, 0.50 }, { 0.40, -0.70, 0.70, 0.40 }, { -0.50, 0.70, -0.20, 0.50 } }) do
				c:round(Vector3.new(v[4], v[4], v[4]), CFrame.new(v[1], v[2], v[3]), p.base)
			end
			for _, v in ipairs({ { -0.50, 0.50 }, { 0.20, 0.60 }, { 0.70, 0.40 } }) do
				c:rod(Vector3.new(v[1], -0.60, v[2]), Vector3.new(v[1], -1.00, v[2]), 0.06, p.dark, nil, false)
				c:ball(Vector3.new(0.18, 0.22, 0.18), CFrame.new(v[1], -1.04, v[2]), p.dark)
			end
			for _, s in ipairs(SIDES) do
				c:round(Vector3.new(0.40, 0.46, 0.10), CFrame.new(0.32 * s, 0.22, 0.74), WASHI)
				c:box(Vector3.new(0.60, 0.10, 0.08), CFrame.new(0.50 * s, 0.84, 0.20) * CFrame.Angles(0, 0, 0.5 * s), p.dark)
			end
			c:eyes(0.20, 0.82, 0.32, 0.12)
			c:box(Vector3.new(0.20, 0.06, 0.04), CFrame.new(0, -0.14, 0.76), WASHI)
			c:box(Vector3.new(0.26, 0.26, 0.06), CFrame.new(0.70, -0.30, 0.66), RED)
		end,
	}

	-- A warlord kabuto: a floating samurai helmet spirit, glowing eyes in its
	-- dark face opening, a tiny grinning half-mask with curled gold whiskers,
	-- a flared three-layer neck guard, turned-back wings with crests, a
	-- sweeping gold crescent with neon tips, cords and spirit lights.
	S.so_t_kabuto = {
		label = "Warlord Kabuto",
		set = "shoguns_oath",
		tint = C3(180, 30, 40),
		scale = 1.15,
		head = CFrame.new(0, 1.30, -0.20),
		neck = CFrame.new(0, -0.80, 0.70),
		back = CFrame.new(0, 0, -1.20),
		build = function(c, p)
			c:round(Vector3.new(1.80, 1.10, 1.80), CFrame.new(0, 0.55, 0), p.base)
			for _, x in ipairs({ -0.40, 0, 0.40 }) do
				c:box(Vector3.new(0.06, 0.08, 1.70), CFrame.new(x, 1.08, 0), p.dark)
			end
			c:cyl(Vector3.new(0.10, 0.36, 0.36), CFrame.new(0, 1.12, 0) * UP, GOLD, METAL)
			c:box(Vector3.new(1.70, 0.10, 0.40), CFrame.new(0, 0.12, 0.80) * CFrame.Angles(0.3, 0, 0), p.dark)
			c:box(Vector3.new(1.20, 0.70, 0.10), CFrame.new(0, -0.25, 0.70), SUMI)
			c:eyes(-0.12, 0.78, 0.28, 0.13, p.glow)
			c:box(Vector3.new(0.90, 0.36, 0.30), CFrame.new(0, -0.62, 0.66), p.deep)
			c:box(Vector3.new(0.30, 0.06, 0.04), CFrame.new(0, -0.60, 0.82), INK)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.26, 0.08, 0.06), CFrame.new(0.26 * s, -0.48, 0.82) * CFrame.Angles(0, 0, 0.4 * s), GOLD, METAL)
				c:box(Vector3.new(0.50, 0.42, 0.10), CFrame.new(1.10 * s, 0.35, 0.55) * CFrame.Angles(0, -0.5 * s, 0), p.base)
				c:cyl(Vector3.new(0.05, 0.24, 0.24), CFrame.new(1.16 * s, 0.35, 0.62) * CFrame.Angles(0, -0.5 * s, 0) * FRONT, GOLD, METAL)
				ribbon(c, Vector3.new(0.90 * s, 0.10, 0.40), Vector3.new(1.00 * s, -0.90, 0.60), 0.08, RED)
			end
			for i = 0, 2 do
				local col = i == 1 and p.light or p.base
				c:box(Vector3.new(1.90 + 0.20 * i, 0.24, 0.12), CFrame.new(0, -0.05 - 0.26 * i, -0.90 - 0.10 * i) * CFrame.Angles(0.3, 0, 0), col)
				for _, s in ipairs(SIDES) do
					c:box(Vector3.new(0.12, 0.24, 1.50), CFrame.new((0.95 + 0.10 * i) * s, -0.05 - 0.26 * i, -0.10) * CFrame.Angles(0, 0, 0.3 * s), col)
				end
			end
			local pts = {}
			for k = 0, 4 do
				local a = math.rad(-150 + k * 30)
				pts[k + 1] = Vector3.new(1.20 * math.cos(a), 2.00 + 1.20 * math.sin(a), 0.92)
			end
			for k = 1, 4 do
				c:box(Vector3.new((pts[k + 1] - pts[k]).Magnitude + 0.04, (k == 1 or k == 4) and 0.10 or 0.16, 0.06),
					CFrame.new((pts[k] + pts[k + 1]) * 0.5) * CFrame.Angles(0, 0, math.atan2(pts[k + 1].Y - pts[k].Y, pts[k + 1].X - pts[k].X)), GOLD, METAL)
			end
			c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(pts[1]), p.glow, NEON)
			c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(pts[5]), p.glow, NEON)
			c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(-1.30, 0.90, -0.20), p.glow, NEON)
			c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(1.30, -0.20, -0.40), p.glow, NEON)
		end,
	}

	return S
end
