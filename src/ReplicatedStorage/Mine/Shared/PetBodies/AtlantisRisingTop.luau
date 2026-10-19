--[[ PetBodies/AtlantisRisingTop -- Atlantis Rising's top bodies: one body per
	Epic-and-up pet, so each one is worn by that pet alone and no two of them
	share a silhouette. The set is a sunken CITY -- ruins, relics, merfolk and
	deep oddities -- turquoise stone with Atlantean gold trim. NOT more
	seahorses, octopi or jellyfish (those are the base bodies).

	Gold, pearl and coral are fixed (the set's jewellery); the stone, mosaic
	and sea-creature colours come from p.*, so each pet wears its own tint.

	Epic stays charming and clean: small civic fragments. Legendary adds
	ornament and scale. Mythic, Divine and Exotic carry p.glow neon, pearls
	and sparkle, echoing the top packs "Sunken City", "Atlantean Vault" and
	"Throne of the Deep". See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, WHITE, METAL, NEON, GLASS, SLATE, WOOD = K.INK, K.WHITE, K.METAL, K.NEON, K.GLASS, K.SLATE, K.WOOD
	local S = {}
	local SET = "atlantis_rising"
	local SIDES = { -1, 1 }
	local V3, CF, ANG = Vector3.new, CFrame.new, CFrame.Angles
	local PI = math.pi
	local UP = ANG(0, 0, PI / 2) -- a cylinder standing on its end
	local FRONT = ANG(0, PI / 2, 0) -- a cylinder's flat face to the front
	local DIAMOND = ANG(0, 0, PI / 4)

	local GOLD = C3(236, 190, 70)
	local GOLD_DK = C3(196, 146, 48)
	local PEARL = C3(248, 242, 234)
	local CORAL = C3(255, 128, 128)
	local BLUSH = C3(255, 150, 172)
	local TEAL = C3(64, 208, 200)
	local DEEP = C3(24, 60, 120)

	local function face(c, y, z, spread, r, iris)
		c:eyes(y, z + r * 0.3, spread, r, iris)
		c:box(V3(r * 1.6, r * 0.45, 0.06), CF(0, y - r * 2.0, z + 0.02), INK)
	end

	local function blush(c, x, y, z)
		for _, s in ipairs(SIDES) do
			c:box(V3(0.20, 0.10, 0.05), CF(x * s, y, z), BLUSH)
		end
	end

	local function feet(c, colour, mat, x, y, z, sz)
		for _, s in ipairs(SIDES) do
			for _, t in ipairs(SIDES) do
				c:box(sz or V3(0.40, 0.22, 0.42), CF(x * s, y, z * t), colour, mat)
			end
		end
	end

	local function pearls(c, list, d)
		for _, v in ipairs(list) do
			c:ball(V3(d, d, d), CF(v[1], v[2], v[3]), PEARL)
		end
	end

	local function goldTrim(c, list, sz)
		for _, v in ipairs(list) do
			c:box(sz or V3(0.12, 0.12, 0.12), CF(v[1], v[2], v[3]), GOLD, METAL)
		end
	end


	--------------------------------------------------------------------------
	-- EPIC: small civic fragments of the sunken city, charming and clean.
	--------------------------------------------------------------------------

	-- A fluted column drum with gold capitals, a pearl on top and a face on the shaft.
	S.at_t_column = {
		label = "Tide Column",
		set = SET,
		tint = C3(64, 208, 200),
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.50, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:cyl(V3(1.40, 1.10, 1.10), CF(0, -0.10, 0) * UP, p.base, SLATE)
			c:cyl(V3(0.20, 1.30, 1.30), CF(0, 0.70, 0) * UP, p.light, SLATE)
			c:cyl(V3(0.18, 1.30, 1.30), CF(0, -0.90, 0) * UP, p.dark, SLATE)
			c:box(V3(1.50, 0.16, 1.50), CF(0, 0.90, 0), GOLD, METAL)
			c:box(V3(1.50, 0.16, 1.50), CF(0, -1.10, 0), GOLD, METAL)
			for i = 0, 5 do
				local a = i * PI / 3
				c:box(V3(0.10, 1.20, 0.14), CF(math.sin(a) * 0.56, -0.10, math.cos(a) * 0.56), p.deep, SLATE)
			end
			face(c, 0.10, 0.56, 0.28, 0.14)
			blush(c, 0.44, -0.16, 0.54)
			c:ball(V3(0.28, 0.28, 0.28), CF(0, 1.10, 0), PEARL)
			feet(c, p.deep, SLATE, 0.42, -1.24, 0.42, V3(0.36, 0.18, 0.36))
		end,
	}

	-- A walking floor panel of checkerboard tiles with a glowing diamond centre.
	S.at_t_mosaic = {
		label = "Floor Mosaic",
		set = SET,
		tint = C3(40, 140, 230),
		head = CF(0, 0.90, 0),
		neck = CF(0, -0.20, 0.90),
		back = CF(0, 0.10, -0.90),
		build = function(c, p)
			c:box(V3(2.00, 0.36, 2.00), CF(0, -0.40, 0), p.dark, SLATE)
			c:box(V3(1.80, 0.20, 1.80), CF(0, -0.14, 0), p.base, SLATE)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(V3(0.70, 0.10, 0.70), CF(0.42 * s, 0.00, 0.42 * t), (s * t > 0) and p.light or GOLD, METAL)
				end
			end
			c:box(V3(0.50, 0.12, 0.50), CF(0, 0.08, 0) * DIAMOND, TEAL, NEON)
			c:box(V3(1.60, 0.70, 0.50), CF(0, 0.40, 0.70), p.base)
			face(c, 0.50, 0.96, 0.30, 0.14)
			blush(c, 0.50, 0.24, 0.94)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 0.30, 0.40), CF(0.70 * s, -0.70, 0.70), p.deep, SLATE)
				c:box(V3(0.34, 0.30, 0.40), CF(0.70 * s, -0.70, -0.50), p.deep, SLATE)
			end
			pearls(c, { { 0.70, 0.14, 0.70 }, { -0.70, 0.14, -0.70 } }, 0.16)
		end,
	}

	-- A two-handled storage jar with a gold rim and a pearl stopper at its foot.
	S.at_t_amphora = {
		label = "Tide Amphora",
		set = SET,
		tint = C3(160, 110, 60),
		scale = 1.1,
		head = CF(0, 1.50, 0),
		neck = CF(0, -0.50, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:cyl(V3(1.10, 1.30, 1.30), CF(0, 0.10, 0) * UP, p.base)
			c:cyl(V3(0.50, 0.90, 0.90), CF(0, -0.70, 0) * UP, p.dark)
			c:cyl(V3(0.30, 0.70, 0.70), CF(0, 0.80, 0) * UP, p.light)
			c:cyl(V3(0.14, 0.90, 0.90), CF(0, 1.04, 0) * UP, GOLD, METAL)
			c:box(V3(0.50, 0.16, 0.50), CF(0, 1.20, 0), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.66 * s, 0.50, 0), V3(0.96 * s, 0.10, 0), 0.07, GOLD, METAL, false)
				c:rod(V3(0.96 * s, 0.10, 0), V3(0.66 * s, -0.30, 0), 0.07, GOLD, METAL, false)
			end
			c:box(V3(0.80, 0.10, 0.10), CF(0, 0.20, 0.66), GOLD, METAL)
			face(c, 0.20, 0.66, 0.28, 0.14)
			blush(c, 0.46, -0.10, 0.64)
			c:ball(V3(0.22, 0.22, 0.22), CF(0, -1.00, 0), PEARL)
			feet(c, p.deep, nil, 0.36, -1.16, 0.36, V3(0.32, 0.18, 0.32))
		end,
	}

	-- A long relief panel carved with rolling wave scrolls and gold borders.
	S.at_t_frieze = {
		label = "Wave Frieze",
		set = SET,
		tint = C3(120, 210, 250),
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.30, 0.50),
		back = CF(0, 0.20, -0.50),
		build = function(c, p)
			c:box(V3(2.20, 1.20, 0.50), CF(0, 0.00, 0), p.base, SLATE)
			c:box(V3(2.30, 0.14, 0.56), CF(0, 0.68, 0), GOLD, METAL)
			c:box(V3(2.30, 0.14, 0.56), CF(0, -0.68, 0), GOLD, METAL)
			for i = -2, 2 do
				c:box(V3(0.30, 0.40, 0.16), CF(i * 0.40, 0.10, 0.28) * ANG(0, 0, 0.4 * (i % 2 == 0 and 1 or -1)), p.light)
				c:box(V3(0.30, 0.40, 0.16), CF(i * 0.40, -0.20, 0.28) * ANG(0, 0, -0.4 * (i % 2 == 0 and 1 or -1)), TEAL)
			end
			face(c, 0.20, 0.28, 0.34, 0.14)
			blush(c, 0.56, -0.10, 0.26)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.30, 0.50, 0.40), CF(1.00 * s, -0.90, 0), p.deep, SLATE)
			end
			pearls(c, { { -0.80, 0.68, 0.20 }, { 0.80, 0.68, 0.20 } }, 0.14)
		end,
	}

	-- A stepped roof moulding with scallop shells perched along the ledge.
	S.at_t_cornice = {
		label = "Shell Cornice",
		set = SET,
		tint = C3(244, 238, 228),
		head = CF(0, 1.00, 0),
		neck = CF(0, -0.20, 0.80),
		back = CF(0, 0.10, -0.80),
		build = function(c, p)
			c:box(V3(2.10, 0.40, 1.40), CF(0, 0.40, 0), p.base, SLATE)
			c:box(V3(2.20, 0.16, 1.50), CF(0, 0.66, 0), GOLD, METAL)
			c:box(V3(1.80, 0.50, 1.10), CF(0, -0.10, 0), p.light, SLATE)
			c:box(V3(1.60, 0.40, 0.90), CF(0, -0.50, 0), p.dark, SLATE)
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.50, 0.36, 0.50), CF(0.70 * s, 0.90, 0.30) * ANG(PI, 0, 0), p.pale)
				c:cone(V3(0.40, 0.30, 0.40), CF(0.70 * s, 0.90, -0.30) * ANG(PI, 0, 0), CORAL)
			end
			face(c, -0.10, 0.56, 0.30, 0.14)
			blush(c, 0.48, -0.36, 0.54)
			feet(c, p.deep, SLATE, 0.50, -0.90, 0.40)
			c:ball(V3(0.24, 0.24, 0.24), CF(0, 0.70, 0.60), PEARL)
		end,
	}

	-- A little column-maiden statue holding a gold capital of pearls.
	S.at_t_caryatid = {
		label = "Pearl Caryatid",
		set = SET,
		tint = C3(200, 190, 255),
		scale = 1.1,
		head = CF(0, 1.60, 0.10),
		neck = CF(0, -0.50, 0.60),
		back = CF(0, 0.40, -0.60),
		build = function(c, p)
			c:box(V3(1.00, 1.40, 0.80), CF(0, 0.10, 0), p.base, SLATE)
			c:box(V3(1.20, 0.40, 0.90), CF(0, 1.00, 0), p.light, SLATE)
			c:box(V3(1.40, 0.20, 1.00), CF(0, 1.30, 0), GOLD, METAL)
			c:box(V3(0.90, 0.50, 0.70), CF(0, -0.80, 0), p.dark, SLATE)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.30, 0.90, 0.30), CF(0.60 * s, 0.20, 0), p.pale)
				c:box(V3(0.36, 0.20, 0.50), CF(0.30 * s, -1.14, 0.10), p.deep, SLATE)
			end
			c:eyes(0.40, 0.42, 0.26, 0.13)
			c:box(V3(0.24, 0.08, 0.06), CF(0, 0.10, 0.42), INK)
			blush(c, 0.40, 0.16, 0.40)
			pearls(c, { { -0.30, 1.00, 0.40 }, { 0.30, 1.00, 0.40 }, { 0, 1.40, 0 } }, 0.18)
			c:box(V3(0.50, 0.10, 0.10), CF(0, 0.70, 0.46), GOLD, METAL)
		end,
	}

	-- A three-pronged gold spear stood on its butt, face on the shaft boss.
	S.at_t_trident = {
		label = "Reef Trident",
		set = SET,
		tint = C3(255, 232, 120),
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.80, 0.30),
		back = CF(0, 0.20, -0.30),
		build = function(c, p)
			c:cyl(V3(1.80, 0.22, 0.22), CF(0, 0.00, 0) * UP, p.base, METAL)
			c:cyl(V3(0.30, 0.40, 0.40), CF(0, -0.90, 0) * UP, GOLD, METAL)
			c:box(V3(1.40, 0.20, 0.16), CF(0, 0.90, 0), GOLD, METAL)
			for _, x in ipairs({ -0.60, 0, 0.60 }) do
				c:box(V3(0.16, 0.70, 0.14), CF(x, 1.30, 0), p.light, METAL)
				c:cone(V3(0.20, 0.34, 0.20), CF(x, 1.76, 0), GOLD, METAL)
			end
			c:box(V3(0.70, 0.70, 0.40), CF(0, 0.10, 0.20), p.pale)
			face(c, 0.24, 0.42, 0.22, 0.12)
			blush(c, 0.34, 0.00, 0.40)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.28, 0.20, 0.34), CF(0.30 * s, -1.16, 0), p.deep, METAL)
			end
			c:ball(V3(0.22, 0.22, 0.22), CF(0, 0.90, 0.16), PEARL)
		end,
	}

	-- A giant coin on little feet, reeded edge and a pearl mint-mark.
	S.at_t_doubloon = {
		label = "Sunken Doubloon",
		set = SET,
		tint = C3(236, 190, 70),
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.60, 0.30),
		back = CF(0, 0.20, -0.30),
		build = function(c, p)
			c:cyl(V3(0.30, 2.00, 2.00), CF(0, 0.10, 0) * FRONT, GOLD, METAL)
			c:cyl(V3(0.34, 1.70, 1.70), CF(0, 0.10, 0) * FRONT, GOLD_DK, METAL)
			c:cyl(V3(0.10, 1.20, 1.20), CF(0, 0.10, 0.18) * FRONT, p.base, METAL)
			for i = 0, 7 do
				local a = i * PI / 4
				c:box(V3(0.18, 0.18, 0.12), CF(math.sin(a) * 0.96, 0.10 + math.cos(a) * 0.96, 0.10), GOLD, METAL)
			end
			face(c, 0.30, 0.24, 0.28, 0.14)
			blush(c, 0.46, 0.00, 0.22)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 0.22, 0.40), CF(0.50 * s, -1.10, 0), p.deep, METAL)
			end
			c:ball(V3(0.20, 0.20, 0.20), CF(0, 0.10, 0.28), PEARL)
		end,
	}

	-- Four stubby columns under a gold pediment, face in the doorway.
	S.at_t_portico = {
		label = "Lagoon Portico",
		set = SET,
		tint = C3(30, 150, 110),
		head = CF(0, 1.50, 0),
		neck = CF(0, -0.60, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(2.20, 0.30, 1.40), CF(0, 0.90, 0), p.light, SLATE)
			c:box(V3(2.30, 0.14, 1.50), CF(0, 1.12, 0), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:cyl(V3(1.40, 0.36, 0.36), CF(0.70 * s, 0.00, 0.40) * UP, p.base, SLATE)
				c:cyl(V3(1.40, 0.36, 0.36), CF(0.70 * s, 0.00, -0.40) * UP, p.base, SLATE)
				c:box(V3(0.50, 0.16, 0.50), CF(0.70 * s, 0.80, 0.40), GOLD, METAL)
				c:box(V3(0.50, 0.16, 0.50), CF(0.70 * s, 0.80, -0.40), GOLD, METAL)
			end
			c:box(V3(1.20, 0.90, 0.40), CF(0, 0.10, 0.70), p.pale)
			face(c, 0.30, 0.92, 0.28, 0.14)
			blush(c, 0.46, 0.00, 0.90)
			c:box(V3(2.00, 0.20, 1.40), CF(0, -0.90, 0), p.dark, SLATE)
			feet(c, p.deep, SLATE, 0.70, -1.12, 0.50, V3(0.36, 0.18, 0.36))
		end,
	}

	-- A standing stone slab with gold inscription bars and a glowing seal.
	S.at_t_stele = {
		label = "Ruin Stele",
		set = SET,
		tint = C3(168, 172, 160),
		head = CF(0, 1.50, 0),
		neck = CF(0, -0.70, 0.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			c:box(V3(1.20, 2.00, 0.40), CF(0, 0.10, 0), p.base, SLATE)
			c:box(V3(1.40, 0.20, 0.50), CF(0, 1.20, 0), GOLD, METAL)
			c:box(V3(1.50, 0.24, 0.60), CF(0, -1.00, 0), p.dark, SLATE)
			for _, y in ipairs({ 0.60, 0.20, -0.20 }) do
				c:box(V3(0.80, 0.10, 0.08), CF(0, y, 0.22), GOLD, METAL)
			end
			c:box(V3(0.40, 0.40, 0.08), CF(0, 0.60, 0.22) * DIAMOND, TEAL, NEON)
			face(c, 0.00, 0.22, 0.28, 0.13)
			blush(c, 0.44, -0.30, 0.20)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.30, 0.20, 0.40), CF(0.40 * s, -1.20, 0), p.deep, SLATE)
			end
			c:ball(V3(0.20, 0.20, 0.20), CF(0, 1.36, 0), PEARL)
		end,
	}

	-- A bay window jutting forward on gold mullions, glass face glowing.
	S.at_t_oriel = {
		label = "Tide Oriel",
		set = SET,
		tint = C3(100, 255, 190),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.40, 0.90),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:box(V3(1.40, 1.40, 1.00), CF(0, 0.10, -0.20), p.base, SLATE)
			c:box(V3(1.60, 0.20, 1.20), CF(0, 0.90, -0.10), GOLD, METAL)
			c:box(V3(1.20, 1.00, 0.70), CF(0, 0.10, 0.60), p.light, GLASS)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.10, 1.00, 0.70), CF(0.60 * s, 0.10, 0.60), GOLD, METAL)
				c:box(V3(0.36, 0.24, 0.40), CF(0.50 * s, -0.90, 0.40), p.deep, SLATE)
				c:box(V3(0.36, 0.24, 0.40), CF(0.50 * s, -0.90, -0.40), p.deep, SLATE)
			end
			c:box(V3(0.10, 1.00, 0.10), CF(0, 0.10, 0.94), GOLD, METAL)
			face(c, 0.30, 0.96, 0.28, 0.14)
			blush(c, 0.46, 0.00, 0.94)
			c:box(V3(0.50, 0.10, 0.50), CF(0, 1.06, 0.40) * DIAMOND, TEAL, NEON)
		end,
	}

	-- A rail of pearl-topped balusters with a little face in the middle.
	S.at_t_balustrade = {
		label = "Pearl Balustrade",
		set = SET,
		tint = C3(160, 236, 210),
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.40, 0.60),
		back = CF(0, 0.20, -0.60),
		build = function(c, p)
			c:box(V3(2.20, 0.24, 0.50), CF(0, 0.70, 0), GOLD, METAL)
			c:box(V3(2.20, 0.24, 0.50), CF(0, -0.70, 0), p.dark, SLATE)
			for i = -2, 2 do
				c:cyl(V3(1.20, 0.28, 0.28), CF(i * 0.44, 0.00, 0) * UP, p.base, SLATE)
				c:ball(V3(0.30, 0.30, 0.30), CF(i * 0.44, 0.70, 0), PEARL)
			end
			c:box(V3(0.80, 0.60, 0.40), CF(0, 0.10, 0.30), p.pale)
			face(c, 0.24, 0.52, 0.24, 0.12)
			blush(c, 0.38, -0.04, 0.50)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 0.20, 0.40), CF(0.90 * s, -1.00, 0), p.deep, SLATE)
			end
		end,
	}

	-- A tiny merfolk with a gold circlet, fin arms and a curling fish tail.
	S.at_t_merling = {
		label = "Lagoon Merling",
		set = SET,
		tint = C3(64, 208, 200),
		scale = 1.1,
		head = CF(0, 1.10, 0.20),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.40, -0.90),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.40, 1.50, 1.30),
				eyeY = 0.26, eyeSpread = 0.34, eyeSize = V3(0.40, 0.46, 0.18),
				snout = { w = 0.50, h = 0.34, d = 0.30, y = -0.20, color = p.light, nose = p.deep },
				legs = false, tail = false,
			})
			c:box(V3(1.00, 0.50, 0.80), CF(0, -0.90, -0.10), p.base)
			c:box(V3(0.70, 0.40, 0.90), CF(0, -1.00, -0.70), p.dark)
			c:wedge(V3(0.14, 0.50, 0.70), CF(0, -0.80, -1.20) * ANG(0, PI, 0), p.light)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.14, 0.50, 0.40), CF(0.76 * s, 0.20, -0.10) * ANG(0, 0, -0.4 * s), p.pale)
				c:box(V3(0.20, 0.16, 0.20), CF(0.40 * s, 0.90, 0.20), GOLD, METAL)
			end
			c:box(V3(0.60, 0.12, 0.50), CF(0, 0.94, 0.10), GOLD, METAL)
			c:ball(V3(0.18, 0.18, 0.18), CF(0, 0.96, 0.36), PEARL)
		end,
	}

	-- A sea-nymph sprite with coral hair pearls and a gold sash.
	S.at_t_nymph = {
		label = "Tide Nymph",
		set = SET,
		tint = C3(255, 128, 128),
		head = CF(0, 1.20, 0.10),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.40, -0.70),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.30, 1.50, 1.20),
				eyeY = 0.30, eyeSpread = 0.32, eyeSize = V3(0.38, 0.44, 0.18),
				mouthY = -0.20, mouthSize = V3(0.34, 0.10, 0.10),
				legs = false, tail = false,
			})
			c:box(V3(1.40, 0.50, 1.00), CF(0, -0.90, 0), p.light)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.12, 0.70, 0.50), CF(0.76 * s, 0.30, -0.20) * ANG(0, 0, -0.5 * s), p.pale)
				c:rod(V3(0.20 * s, 0.90, 0.20), V3(0.50 * s, 1.30, -0.10), 0.05, CORAL, nil, false)
				c:ball(V3(0.20, 0.20, 0.20), CF(0.52 * s, 1.34, -0.12), PEARL)
			end
			c:box(V3(0.80, 0.14, 0.60), CF(0, -0.50, 0.50), GOLD, METAL)
			c:box(V3(0.40, 0.30, 0.40), CF(0, -1.20, -0.40), p.deep)
		end,
	}

	-- An armoured deep-sea bug with plated segments and gold antenna tips.
	S.at_t_isopod = {
		label = "Ruin Isopod",
		set = SET,
		tint = C3(110, 60, 150),
		head = CF(0, 0.90, 0.40),
		neck = CF(0, -0.20, 1.00),
		back = CF(0, 0.20, -1.00),
		build = function(c, p)
			c:box(V3(1.40, 0.80, 2.00), CF(0, 0.00, 0), p.base)
			for i = -2, 2 do
				c:box(V3(1.50, 0.18, 0.30), CF(0, 0.50, i * 0.36), i % 2 == 0 and p.light or p.dark)
			end
			c:box(V3(0.90, 0.60, 0.50), CF(0, 0.10, 1.10), p.pale)
			c:eyes(0.30, 1.36, 0.26, 0.12)
			c:box(V3(0.30, 0.10, 0.08), CF(0, 0.00, 1.36), INK)
			blush(c, 0.40, 0.00, 1.34)
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.60, 0.00, -0.60 }) do
					c:box(V3(0.30, 0.16, 0.20), CF(0.80 * s, -0.50, z), p.deep)
				end
				c:box(V3(0.10, 0.20, 0.20), CF(0.50 * s, 0.30, 1.20), GOLD, METAL)
			end
			c:box(V3(0.40, 0.20, 0.30), CF(0, 0.20, -1.16), p.dark)
		end,
	}

	-- A pointed cathedral window of glowing glass in a coral-stone frame.
	S.at_t_lancet = {
		label = "Coral Lancet",
		set = SET,
		tint = C3(220, 60, 60),
		head = CF(0, 1.60, 0),
		neck = CF(0, -0.70, 0.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			c:box(V3(1.00, 1.60, 0.40), CF(0, 0.00, 0), p.base, SLATE)
			c:wedge(V3(1.00, 0.70, 0.40), CF(0, 1.10, 0), p.light, SLATE)
			c:box(V3(1.10, 0.14, 0.50), CF(0, -0.90, 0), GOLD, METAL)
			c:box(V3(0.70, 1.00, 0.10), CF(0, 0.20, 0.26), TEAL, NEON).Transparency = 0.35
			c:box(V3(0.10, 1.00, 0.10), CF(0, 0.20, 0.30), GOLD, METAL)
			face(c, 0.30, 0.22, 0.24, 0.12)
			blush(c, 0.38, 0.00, 0.20)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.28, 0.20, 0.36), CF(0.36 * s, -1.14, 0), p.deep, SLATE)
				c:box(V3(0.16, 0.30, 0.16), CF(0.56 * s, 0.40, 0), CORAL)
			end
			c:ball(V3(0.18, 0.18, 0.18), CF(0, 1.50, 0), PEARL)
		end,
	}

	-- A stepped display block with a pearl globe on its gold top.
	S.at_t_plinth = {
		label = "Gold Plinth",
		set = SET,
		tint = C3(236, 190, 70),
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.10, -0.80),
		build = function(c, p)
			c:box(V3(1.80, 0.40, 1.80), CF(0, -0.70, 0), p.dark, SLATE)
			c:box(V3(1.50, 0.50, 1.50), CF(0, -0.30, 0), p.base, SLATE)
			c:box(V3(1.60, 0.16, 1.60), CF(0, 0.00, 0), GOLD, METAL)
			c:box(V3(1.20, 0.80, 1.20), CF(0, 0.50, 0), p.light, SLATE)
			c:box(V3(1.30, 0.14, 1.30), CF(0, 0.96, 0), GOLD, METAL)
			c:ball(V3(0.50, 0.50, 0.50), CF(0, 1.30, 0), PEARL)
			face(c, 0.40, 0.62, 0.28, 0.13)
			blush(c, 0.46, 0.10, 0.60)
			feet(c, p.deep, SLATE, 0.60, -1.04, 0.60, V3(0.36, 0.18, 0.36))
			goldTrim(c, { { -0.60, -0.70, 0.90 }, { 0.60, -0.70, 0.90 } }, V3(0.16, 0.16, 0.16))
		end,
	}

	-- An Ionic scroll capital come alive, spiralling into a pearl eye.
	S.at_t_volute = {
		label = "Shell Volute",
		set = SET,
		tint = C3(250, 190, 160),
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:cyl(V3(0.50, 1.60, 1.60), CF(0, 0.10, 0) * FRONT, p.base)
			c:cyl(V3(0.40, 1.20, 1.20), CF(0, 0.10, 0.20) * FRONT, p.light)
			c:cyl(V3(0.30, 0.70, 0.70), CF(0, 0.10, 0.40) * FRONT, p.pale)
			c:ball(V3(0.40, 0.40, 0.40), CF(0, 0.10, 0.70), PEARL)
			for i = 0, 5 do
				local a = i * PI / 3
				c:box(V3(0.14, 0.30, 0.14), CF(math.sin(a) * 0.90, 0.10 + math.cos(a) * 0.90, 0), GOLD, METAL)
			end
			face(c, 0.30, 0.50, 0.24, 0.12)
			blush(c, 0.40, 0.00, 0.48)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 0.22, 0.40), CF(0.50 * s, -0.90, 0), p.deep)
			end
			c:box(V3(0.20, 0.50, 0.40), CF(0, -0.40, -0.90), p.dark)
		end,
	}

	--------------------------------------------------------------------------
	-- LEGENDARY: ornate civic works and deeper dwellers.
	--------------------------------------------------------------------------

	-- An open courtyard of four columns around a glass pool.
	S.at_t_atrium = {
		label = "Sunken Atrium",
		set = SET,
		tint = C3(40, 70, 180),
		scale = 1.15,
		head = CF(0, 1.60, 0),
		neck = CF(0, -0.60, 0.90),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			c:box(V3(2.20, 0.30, 2.00), CF(0, -0.80, 0), p.dark, SLATE)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(V3(0.40, 1.40, 0.40), CF(0.80 * s, 0.10, 0.70 * t), p.base, SLATE)
					c:box(V3(0.50, 0.16, 0.50), CF(0.80 * s, 0.90, 0.70 * t), GOLD, METAL)
				end
			end
			c:box(V3(2.00, 0.20, 1.80), CF(0, 1.00, 0), p.light, SLATE)
			c:box(V3(1.20, 0.10, 1.00), CF(0, 1.16, 0), TEAL, NEON).Transparency = 0.4
			c:box(V3(1.00, 0.80, 0.40), CF(0, 0.00, 0.90), p.pale)
			face(c, 0.20, 1.12, 0.30, 0.14)
			blush(c, 0.48, -0.10, 1.10)
			c:cyl(V3(0.20, 0.80, 0.80), CF(0, -0.50, 0) * UP, DEEP, GLASS).Transparency = 0.5
			pearls(c, { { 0, 1.20, 0 }, { 0.80, 0.90, 0.70 }, { -0.80, 0.90, -0.70 } }, 0.16)
		end,
	}

	-- Three arches carrying a channel of glowing water.
	S.at_t_aqueduct = {
		label = "Tide Aqueduct",
		set = SET,
		tint = C3(20, 110, 120),
		scale = 1.15,
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.50, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:box(V3(2.40, 0.40, 0.80), CF(0, 0.80, 0), p.light, SLATE)
			c:box(V3(2.20, 0.20, 0.50), CF(0, 1.00, 0), DEEP, GLASS).Transparency = 0.35
			for _, x in ipairs({ -0.80, 0, 0.80 }) do
				c:box(V3(0.40, 1.20, 0.70), CF(x, -0.20, 0), p.base, SLATE)
				c:box(V3(0.50, 0.30, 0.20), CF(x, 0.40, 0.40), p.dark, SLATE)
			end
			c:box(V3(0.80, 0.60, 0.40), CF(0, 0.10, 0.50), p.pale)
			face(c, 0.24, 0.72, 0.26, 0.13)
			blush(c, 0.42, -0.06, 0.70)
			c:box(V3(2.40, 0.20, 0.90), CF(0, -0.90, 0), p.dark, SLATE)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.36, 0.20, 0.40), CF(1.00 * s, -1.14, 0), p.deep, SLATE)
			end
			goldTrim(c, { { -1.10, 0.80, 0.40 }, { 1.10, 0.80, 0.40 } }, V3(0.18, 0.14, 0.14))
			c:ball(V3(0.20, 0.20, 0.20), CF(0, 1.16, 0), PEARL)
		end,
	}

	-- A little temple with a gold dome, twin side towers and a lit nave door.
	S.at_t_basilica = {
		label = "Deep Basilica",
		set = SET,
		tint = C3(52, 48, 70),
		scale = 1.2,
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.70, 0.90),
		back = CF(0, 0.40, -0.90),
		build = function(c, p)
			c:box(V3(2.00, 1.20, 1.60), CF(0, 0.00, 0), p.base, SLATE)
			c:box(V3(1.40, 0.80, 1.20), CF(0, 0.90, -0.10), p.light, SLATE)
			c:cone(V3(1.20, 0.60, 1.00), CF(0, 1.50, -0.10), GOLD, METAL)
			c:box(V3(0.80, 0.70, 0.30), CF(0, -0.10, 0.90), p.deep, SLATE)
			c:box(V3(0.50, 0.50, 0.10), CF(0, -0.10, 1.00), TEAL, NEON)
			face(c, 0.40, 0.82, 0.30, 0.14)
			blush(c, 0.50, 0.10, 0.80)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.40, 0.90, 0.40), CF(0.90 * s, 0.20, 0.50), p.dark, SLATE)
				c:cone(V3(0.40, 0.36, 0.40), CF(0.90 * s, 0.80, 0.50), GOLD, METAL)
				c:box(V3(0.36, 0.22, 0.40), CF(0.70 * s, -0.90, 0.50), p.deep, SLATE)
			end
			c:ball(V3(0.24, 0.24, 0.24), CF(0, 1.90, -0.10), PEARL)
			c:box(V3(2.10, 0.16, 1.70), CF(0, -0.70, 0), GOLD, METAL)
		end,
	}

	-- A civic square with a speaker's podium and pearl-topped posts.
	S.at_t_forum = {
		label = "Pearl Forum",
		set = SET,
		tint = C3(226, 206, 160),
		scale = 1.15,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.40, 0.90),
		back = CF(0, 0.20, -0.90),
		build = function(c, p)
			c:box(V3(2.20, 0.30, 2.00), CF(0, -0.70, 0), p.dark, SLATE)
			c:box(V3(1.80, 0.20, 1.60), CF(0, -0.40, 0), p.base, SLATE)
			c:box(V3(1.00, 1.00, 0.80), CF(0, 0.30, -0.40), p.light, SLATE)
			c:box(V3(1.10, 0.16, 0.90), CF(0, 0.90, -0.40), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:cyl(V3(1.00, 0.28, 0.28), CF(0.80 * s, 0.00, 0.60) * UP, p.base, SLATE)
				c:ball(V3(0.28, 0.28, 0.28), CF(0.80 * s, 0.60, 0.60), PEARL)
			end
			c:box(V3(0.80, 0.60, 0.40), CF(0, 0.10, 0.80), p.pale)
			face(c, 0.24, 1.02, 0.28, 0.13)
			blush(c, 0.44, -0.04, 1.00)
			feet(c, p.deep, SLATE, 0.80, -1.00, 0.70, V3(0.36, 0.18, 0.36))
			c:box(V3(0.40, 0.10, 0.40), CF(0, 1.04, -0.40) * DIAMOND, TEAL, NEON)
		end,
	}

	-- A round pavilion with a conical roof and gold cornice ring.
	S.at_t_rotunda = {
		label = "Tide Rotunda",
		set = SET,
		tint = C3(120, 210, 250),
		scale = 1.15,
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.60, 0.90),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			c:cyl(V3(1.40, 1.80, 1.80), CF(0, 0.00, 0) * UP, p.base, SLATE)
			c:cyl(V3(0.20, 2.00, 2.00), CF(0, 0.80, 0) * UP, GOLD, METAL)
			c:cone(V3(1.60, 0.70, 1.60), CF(0, 1.30, 0), p.light, SLATE)
			c:ball(V3(0.36, 0.36, 0.36), CF(0, 1.80, 0), PEARL)
			for i = 0, 5 do
				local a = i * PI / 3
				c:box(V3(0.20, 0.80, 0.14), CF(math.sin(a) * 0.92, 0.10, math.cos(a) * 0.92), p.dark, SLATE)
			end
			c:box(V3(0.70, 0.70, 0.20), CF(0, 0.10, 0.96), p.pale)
			face(c, 0.30, 1.08, 0.26, 0.13)
			blush(c, 0.42, 0.00, 1.06)
			feet(c, p.deep, SLATE, 0.60, -0.90, 0.60, V3(0.34, 0.18, 0.34))
			c:box(V3(0.50, 0.10, 0.50), CF(0, 0.90, 0) * DIAMOND, TEAL, NEON)
		end,
	}

	-- A covered walk of paired piers around a dark inner court.
	S.at_t_peristyle = {
		label = "Kelp Peristyle",
		set = SET,
		tint = C3(76, 112, 46),
		scale = 1.15,
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.50, 0.90),
		back = CF(0, 0.20, -0.90),
		build = function(c, p)
			c:box(V3(2.20, 0.24, 2.00), CF(0, 0.90, 0), p.light, SLATE)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs({ -1, 0, 1 }) do
					c:box(V3(0.30, 1.40, 0.30), CF(0.90 * s, 0.00, 0.70 * t), p.base, SLATE)
				end
			end
			c:box(V3(1.40, 0.80, 1.20), CF(0, 0.10, 0), p.dark, SLATE)
			c:box(V3(0.80, 0.60, 0.30), CF(0, 0.00, 0.90), p.pale)
			face(c, 0.20, 1.06, 0.26, 0.13)
			blush(c, 0.42, -0.10, 1.04)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.12, 0.80, 0.20), CF(0.50 * s, 0.40, 0.40), p.glow or TEAL)
			end
			c:box(V3(2.20, 0.20, 2.00), CF(0, -0.90, 0), p.deep, SLATE)
			goldTrim(c, { { 0, 1.06, 0 }, { 0.90, 0.80, 0.70 }, { -0.90, 0.80, -0.70 } }, V3(0.16, 0.12, 0.16))
		end,
	}

	-- A gold-banded treasure casket with a glowing viewing pane.
	S.at_t_ossuary = {
		label = "Deep Ossuary",
		set = SET,
		tint = C3(110, 60, 150),
		scale = 1.1,
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.50, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(1.60, 1.00, 1.20), CF(0, 0.00, 0), p.base, METAL)
			c:box(V3(1.70, 0.16, 1.30), CF(0, 0.60, 0), GOLD, METAL)
			c:box(V3(1.40, 0.40, 1.00), CF(0, 0.90, 0), p.light, METAL)
			c:box(V3(0.80, 0.50, 0.20), CF(0, 0.10, 0.62), TEAL, NEON)
			c:box(V3(0.40, 0.40, 0.12), CF(0, 0.10, 0.70) * DIAMOND, PEARL)
			face(c, -0.20, 0.62, 0.28, 0.13)
			blush(c, 0.46, -0.46, 0.60)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.20, 0.50, 0.20), CF(0.90 * s, 0.20, 0), GOLD, METAL)
				c:box(V3(0.36, 0.22, 0.40), CF(0.50 * s, -0.80, 0.40), p.deep, METAL)
				c:box(V3(0.36, 0.22, 0.40), CF(0.50 * s, -0.80, -0.40), p.deep, METAL)
			end
			c:ball(V3(0.28, 0.28, 0.28), CF(0, 1.20, 0), PEARL)
			c:sparkle(GOLD, 2, 0.4, 0.12)
		end,
	}

	-- A three-bank warship with a gold mast and a sail for a fin.
	S.at_t_trireme = {
		label = "Gold Trireme",
		set = SET,
		tint = C3(236, 190, 70),
		scale = 1.15,
		head = CF(0, 1.20, 0.40),
		neck = CF(0, -0.30, 1.10),
		back = CF(0, 0.20, -1.00),
		build = function(c, p)
			c:box(V3(1.20, 0.70, 2.20), CF(0, -0.20, 0), p.base)
			c:wedge(V3(1.20, 0.50, 0.60), CF(0, -0.10, 1.30), p.light)
			c:wedge(V3(1.00, 0.40, 0.50), CF(0, -0.10, -1.30) * ANG(0, PI, 0), p.dark)
			c:box(V3(0.16, 1.20, 0.16), CF(0, 0.60, -0.20), GOLD, METAL)
			c:box(V3(0.10, 0.80, 1.00), CF(0, 1.00, -0.20) * ANG(0, 0, 0.2), p.pale)
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.50, 0.00, -0.50 }) do
					c:box(V3(0.50, 0.08, 0.12), CF(0.70 * s, -0.10, z), GOLD, METAL)
				end
				c:box(V3(0.30, 0.20, 0.36), CF(0.40 * s, -0.70, 0.70), p.deep)
			end
			c:eyes(0.10, 1.50, 0.28, 0.12)
			c:box(V3(0.28, 0.10, 0.08), CF(0, -0.16, 1.50), INK)
			blush(c, 0.42, -0.20, 1.48)
			c:ball(V3(0.22, 0.22, 0.22), CF(0, 1.30, -0.20), PEARL)
		end,
	}

	-- A singing merfolk with coral hair strands and a gold collar.
	S.at_t_siren = {
		label = "Coral Siren",
		set = SET,
		tint = C3(220, 70, 170),
		scale = 1.1,
		head = CF(0, 1.30, 0.20),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.50, -0.90),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.40, 1.50, 1.20),
				eyeY = 0.28, eyeSpread = 0.34, eyeSize = V3(0.40, 0.46, 0.18),
				mouthY = -0.18, mouthSize = V3(0.36, 0.10, 0.10),
				legs = false, tail = false,
			})
			c:box(V3(1.10, 0.50, 0.90), CF(0, -0.90, -0.20), p.base)
			c:box(V3(0.70, 0.40, 1.00), CF(0, -1.00, -0.80), CORAL)
			c:wedge(V3(0.14, 0.60, 0.80), CF(0, -0.70, -1.30) * ANG(0, PI, 0), p.light)
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.20 * s, 0.90, 0.20), V3(0.60 * s, 1.40, 0.00), 0.06, CORAL, nil, false)
				c:ball(V3(0.22, 0.22, 0.22), CF(0.62 * s, 1.44, 0), PEARL)
				c:box(V3(0.14, 0.60, 0.50), CF(0.80 * s, 0.20, -0.20) * ANG(0, 0, -0.45 * s), p.pale)
			end
			c:box(V3(0.70, 0.12, 0.50), CF(0, 0.00, 0.60), GOLD, METAL)
			c:box(V3(0.30, 0.20, 0.16), CF(0, 0.50, 0.66), GOLD, METAL)
		end,
	}

	-- A horse-fronted sea charger with gold forelegs and a curling tail.
	S.at_t_hippocamp = {
		label = "Gold Hippocamp",
		set = SET,
		tint = C3(236, 190, 70),
		scale = 1.15,
		head = CF(0, 1.20, 0.20),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.40, -0.90),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.40, 1.50, 1.40),
				eyeY = 0.24, eyeSpread = 0.34, eyeSize = V3(0.40, 0.46, 0.18),
				snout = { w = 0.44, h = 0.36, d = 0.50, y = -0.14, color = p.light, nose = p.deep },
				legs = false, tail = false,
			})
			c:box(V3(0.90, 0.70, 0.70), CF(0, -0.90, 0.20), p.base)
			c:box(V3(0.60, 0.50, 0.80), CF(0, -1.10, -0.40), p.dark)
			c:box(V3(0.40, 0.40, 0.50), CF(0, -0.90, -0.90), p.light)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.30, 0.60, 0.30), CF(0.50 * s, -0.70, 0.50), GOLD, METAL)
				c:box(V3(0.14, 0.50, 0.40), CF(0.80 * s, 0.30, -0.10) * ANG(0, 0, -0.35 * s), p.pale)
			end
			c:box(V3(0.70, 0.16, 0.50), CF(0, 0.94, 0.00), GOLD, METAL)
			for _, x in ipairs({ -0.20, 0, 0.20 }) do
				c:cone(V3(0.16, 0.28, 0.16), CF(x, 1.18, 0), GOLD, METAL)
			end
			c:ball(V3(0.18, 0.18, 0.18), CF(0, 0.96, 0.30), PEARL)
		end,
	}

	-- A long deep-dweller with a round sucker mouth and gold rings.
	S.at_t_lamprey = {
		label = "Abyss Lamprey",
		set = SET,
		tint = C3(24, 60, 120),
		head = CF(0, 0.80, 0.50),
		neck = CF(0, -0.20, 1.10),
		back = CF(0, 0.20, -1.10),
		build = function(c, p)
			c:box(V3(1.00, 0.80, 2.20), CF(0, 0.00, 0), p.base)
			c:cyl(V3(0.50, 0.90, 0.90), CF(0, 0.00, 1.20) * FRONT, p.dark)
			c:cyl(V3(0.20, 0.60, 0.60), CF(0, 0.00, 1.50) * FRONT, p.deep)
			c:eyes(0.20, 1.40, 0.30, 0.12)
			blush(c, 0.40, -0.10, 1.38)
			for i = 0, 3 do
				c:box(V3(1.10, 0.12, 0.20), CF(0, 0.50, -0.20 - i * 0.40), i % 2 == 0 and p.light or GOLD)
			end
			for _, s in ipairs(SIDES) do
				c:box(V3(0.14, 0.40, 0.50), CF(0.56 * s, 0.10, 0.40), p.pale)
				c:box(V3(0.28, 0.16, 0.30), CF(0.40 * s, -0.56, 0.70), p.deep)
			end
			c:box(V3(0.50, 0.30, 0.40), CF(0, 0.10, -1.30), p.dark)
			c:ball(V3(0.16, 0.16, 0.16), CF(0, 0.00, 1.70), TEAL, NEON)
		end,
	}

	-- A chunky sea reptile with paddle flippers and a gold belly band.
	S.at_t_mosasaur = {
		label = "Ruin Mosasaur",
		set = SET,
		tint = C3(40, 140, 230),
		scale = 1.15,
		head = CF(0, 1.00, 0.50),
		neck = CF(0, -0.30, 1.20),
		back = CF(0, 0.30, -1.10),
		build = function(c, p)
			c:box(V3(1.40, 1.00, 2.20), CF(0, 0.00, 0), p.base)
			c:box(V3(1.10, 0.80, 0.70), CF(0, 0.10, 1.30), p.light)
			c:eyes(0.30, 1.60, 0.30, 0.14)
			c:box(V3(0.40, 0.16, 0.12), CF(0, -0.10, 1.66), INK)
			blush(c, 0.46, -0.10, 1.64)
			c:wedge(V3(0.16, 0.70, 1.00), CF(0, 0.80, -0.20) * ANG(0, PI, 0), p.pale)
			c:box(V3(0.14, 0.80, 0.70), CF(0, 0.20, -1.40) * ANG(-0.4, 0, 0), p.light)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.60, 0.14, 0.40), CF(0.80 * s, -0.30, 0.50), p.dark)
				c:box(V3(0.50, 0.12, 0.36), CF(0.70 * s, -0.30, -0.50), p.dark)
				c:box(V3(0.10, 0.20, 0.16), CF(0.40 * s, 0.60, 1.20), GOLD, METAL)
			end
			c:box(V3(0.80, 0.12, 1.80), CF(0, -0.56, 0), GOLD, METAL)
			pearls(c, { { 0, 0.60, 1.40 } }, 0.16)
		end,
	}

	-- A giant mosaic chip of gold with inlaid turquoise and coral.
	S.at_t_tessera = {
		label = "Gold Tessera",
		set = SET,
		tint = C3(255, 232, 120),
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.30, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:box(V3(1.60, 1.60, 0.50), CF(0, 0.10, 0), GOLD, METAL)
			c:box(V3(1.30, 1.30, 0.40), CF(0, 0.10, 0.10), p.base)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(V3(0.40, 0.40, 0.12), CF(0.36 * s, 0.36 * t + 0.10, 0.32), (s * t > 0) and TEAL or CORAL)
				end
			end
			c:box(V3(0.36, 0.36, 0.14), CF(0, 0.10, 0.36) * DIAMOND, PEARL)
			face(c, 0.10, 0.36, 0.28, 0.13)
			blush(c, 0.50, -0.26, 0.34)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 0.22, 0.40), CF(0.50 * s, -0.90, 0), p.deep, METAL)
			end
			c:box(V3(0.20, 0.40, 0.30), CF(0, -0.50, -0.40), p.dark)
		end,
	}

	-- A fountain shrine: pool, columns and a pearl canopy.
	S.at_t_nymphaeum = {
		label = "Pearl Nymphaeum",
		set = SET,
		tint = C3(200, 190, 255),
		scale = 1.15,
		head = CF(0, 1.50, 0),
		neck = CF(0, -0.50, 0.90),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			c:box(V3(2.00, 0.30, 1.60), CF(0, -0.70, 0), p.dark, SLATE)
			c:cyl(V3(0.40, 1.40, 1.40), CF(0, -0.30, 0) * UP, DEEP, GLASS).Transparency = 0.45
			for _, s in ipairs(SIDES) do
				c:box(V3(0.36, 1.20, 0.36), CF(0.80 * s, 0.20, 0.50), p.base, SLATE)
				c:box(V3(0.36, 1.20, 0.36), CF(0.80 * s, 0.20, -0.50), p.base, SLATE)
				c:ball(V3(0.30, 0.30, 0.30), CF(0.80 * s, 0.90, 0.50), PEARL)
			end
			c:box(V3(1.80, 0.24, 1.40), CF(0, 0.90, 0), GOLD, METAL)
			c:box(V3(0.80, 0.60, 0.40), CF(0, 0.10, 0.80), p.pale)
			face(c, 0.24, 1.02, 0.26, 0.13)
			blush(c, 0.42, -0.06, 1.00)
			c:ball(V3(0.36, 0.36, 0.36), CF(0, 1.20, 0), PEARL)
			c:sparkle(TEAL, 2, 0.4, 0.14)
		end,
	}

	--------------------------------------------------------------------------
	-- MYTHIC: spectacular ruins with glow, pearls and floating sparkle.
	--------------------------------------------------------------------------

	-- A hilltop citadel of columns under a gold-roofed temple.
	S.at_t_acropolis = {
		label = "Tide Acropolis",
		set = SET,
		tint = C3(40, 70, 180),
		scale = 1.25,
		head = CF(0, 1.80, -0.10),
		neck = CF(0, -0.70, 1.00),
		back = CF(0, 0.50, -1.00),
		build = function(c, p)
			c:box(V3(2.20, 0.50, 1.80), CF(0, -0.70, 0), p.dark, SLATE)
			c:box(V3(1.80, 0.40, 1.40), CF(0, -0.30, 0), p.base, SLATE)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:cyl(V3(1.00, 0.28, 0.28), CF(0.60 * s, 0.40, 0.40 * t) * UP, p.light, SLATE)
					c:box(V3(0.40, 0.14, 0.40), CF(0.60 * s, 1.00, 0.40 * t), GOLD, METAL)
				end
			end
			c:box(V3(1.60, 0.30, 1.20), CF(0, 1.20, 0), p.pale, SLATE)
			c:box(V3(1.00, 0.70, 0.70), CF(0, 1.60, -0.10), p.base, SLATE)
			c:cone(V3(0.90, 0.50, 0.70), CF(0, 2.10, -0.10), GOLD, METAL)
			c:box(V3(0.70, 0.50, 0.20), CF(0, -0.10, 0.90), TEAL, NEON)
			c:eyes(0.20, 0.96, 0.28, 0.13, p.glow)
			c:ball(V3(0.28, 0.28, 0.28), CF(0, 2.40, -0.10), PEARL)
			c:sparkle(GOLD, 3, 0.5, 0.18)
			c:light(TEAL, 1.4, 8)
		end,
	}

	-- A round temple ringed by columns under a gold conical roof.
	S.at_t_tholos = {
		label = "Sunken Tholos",
		set = SET,
		tint = C3(64, 208, 200),
		scale = 1.2,
		head = CF(0, 1.90, 0),
		neck = CF(0, -0.70, 0.90),
		back = CF(0, 0.40, -0.90),
		build = function(c, p)
			c:cyl(V3(1.20, 1.70, 1.70), CF(0, 0.00, 0) * UP, p.base, SLATE)
			for i = 0, 7 do
				local a = i * PI / 4
				c:cyl(V3(1.00, 0.22, 0.22), CF(math.sin(a) * 0.90, 0.20, math.cos(a) * 0.90) * UP, p.light, SLATE)
			end
			c:cone(V3(1.80, 0.80, 1.80), CF(0, 1.20, 0), GOLD, METAL)
			c:ball(V3(0.40, 0.40, 0.40), CF(0, 1.80, 0), p.glow, NEON)
			c:box(V3(0.70, 0.70, 0.20), CF(0, 0.10, 0.96), p.pale)
			face(c, 0.30, 1.08, 0.26, 0.13, p.glow)
			blush(c, 0.42, 0.00, 1.06)
			feet(c, p.deep, SLATE, 0.60, -0.80, 0.60, V3(0.34, 0.18, 0.34))
			c:sparkle(PEARL, 3, 0.5, 0.16)
			c:light(TEAL, 1.6, 9)
		end,
	}

	-- A crowned merman king with a glowing trident and neon tail fan.
	S.at_t_triton = {
		label = "Crown Triton",
		set = SET,
		tint = C3(236, 190, 70),
		scale = 1.2,
		head = CF(0, 1.40, 0.20),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.50, -0.90),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.50, 1.60, 1.30),
				eyeY = 0.28, eyeSpread = 0.36, eyeSize = V3(0.42, 0.48, 0.18), eyeColor = TEAL,
				snout = { w = 0.50, h = 0.34, d = 0.34, y = -0.18, color = p.light, nose = p.deep },
				legs = false, tail = false,
			})
			c:box(V3(1.20, 0.60, 0.90), CF(0, -0.95, -0.10), p.base)
			c:box(V3(0.80, 0.50, 1.00), CF(0, -1.10, -0.70), p.dark)
			c:wedge(V3(0.16, 0.70, 0.90), CF(0, -0.80, -1.30) * ANG(0, PI, 0), TEAL, NEON)
			c:box(V3(0.90, 0.20, 0.70), CF(0, 0.96, 0.00), GOLD, METAL)
			for _, x in ipairs({ -0.30, 0, 0.30 }) do
				c:cone(V3(0.20, 0.40, 0.20), CF(x, 1.30, 0), GOLD, METAL)
			end
			c:box(V3(0.14, 1.20, 0.14), CF(0.70, 0.40, 0.40), GOLD, METAL)
			c:box(V3(0.50, 0.14, 0.10), CF(0.70, 1.00, 0.40), GOLD, METAL)
			for _, x in ipairs({ -0.18, 0, 0.18 }) do
				c:cone(V3(0.12, 0.28, 0.12), CF(0.70 + x, 1.24, 0.40), p.glow, NEON)
			end
			for _, s in ipairs(SIDES) do
				c:box(V3(0.14, 0.60, 0.50), CF(0.86 * s, 0.20, -0.10) * ANG(0, 0, -0.4 * s), p.pale)
			end
			c:ball(V3(0.22, 0.22, 0.22), CF(0, 1.00, 0.36), PEARL)
			c:sparkle(GOLD, 2, 0.5, 0.14)
			c:light(GOLD, 1.2, 7)
		end,
	}

	-- A deep-sea whale-beast with a glowing neon tail and pearl lights.
	S.at_t_cetus = {
		label = "Abyss Cetus",
		set = SET,
		tint = C3(24, 60, 120),
		scale = 1.25,
		head = CF(0, 1.10, 0.50),
		neck = CF(0, -0.30, 1.20),
		back = CF(0, 0.40, -1.20),
		build = function(c, p)
			c:box(V3(1.60, 1.20, 2.40), CF(0, 0.10, 0), p.base)
			c:box(V3(1.20, 1.00, 0.80), CF(0, 0.20, 1.40), p.light)
			c:eyes(0.40, 1.76, 0.34, 0.15, TEAL)
			c:box(V3(0.50, 0.18, 0.12), CF(0, -0.10, 1.80), INK)
			blush(c, 0.50, -0.10, 1.78)
			c:wedge(V3(0.16, 0.80, 1.20), CF(0, 1.00, -0.20) * ANG(0, PI, 0), p.pale)
			c:box(V3(0.14, 1.00, 0.80), CF(0, 0.30, -1.50) * ANG(-0.5, 0, 0), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.70, 0.16, 0.50), CF(0.90 * s, -0.40, 0.60), p.dark)
				c:box(V3(0.60, 0.14, 0.44), CF(0.80 * s, -0.40, -0.50), p.dark)
			end
			c:box(V3(1.00, 0.14, 2.00), CF(0, -0.60, 0), GOLD, METAL)
			for _, z in ipairs({ 0.60, 0.00, -0.60 }) do
				c:ball(V3(0.20, 0.20, 0.20), CF(0, 0.80, z), p.glow, NEON)
			end
			c:sparkle(TEAL, 3, 0.5, 0.18)
			c:light(TEAL, 1.8, 10)
		end,
	}

	-- A standing suit of orichalcum armour with a glowing crest.
	S.at_t_panoply = {
		label = "Orichalcum Panoply",
		set = SET,
		tint = C3(236, 190, 70),
		scale = 1.2,
		head = CF(0, 1.50, 0),
		neck = CF(0, -0.50, 0.70),
		back = CF(0, 0.30, -0.70),
		build = function(c, p)
			c:box(V3(1.70, 1.50, 1.20), CF(0, 0.10, 0), GOLD, METAL)
			c:box(V3(1.90, 0.20, 1.40), CF(0, 0.90, 0), GOLD_DK, METAL)
			c:box(V3(1.40, 0.50, 0.90), CF(0, 1.20, 0), p.base, METAL)
			c:cone(V3(1.00, 0.50, 0.80), CF(0, 1.70, 0), p.glow, NEON)
			c:box(V3(0.80, 0.60, 0.20), CF(0, 0.20, 0.62), TEAL, NEON)
			face(c, 0.20, 0.72, 0.28, 0.13, p.glow)
			blush(c, 0.48, -0.10, 0.70)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.50, 0.80, 0.20), CF(0.95 * s, 0.30, 0) * ANG(0, 0, -0.3 * s), GOLD, METAL)
				c:box(V3(0.36, 0.24, 0.40), CF(0.50 * s, -0.90, 0.30), p.deep, METAL)
				c:box(V3(0.36, 0.24, 0.40), CF(0.50 * s, -0.90, -0.30), p.deep, METAL)
			end
			c:box(V3(0.50, 0.50, 0.16), CF(0, 0.20, 0.74) * DIAMOND, PEARL)
			c:sparkle(GOLD, 3, 0.5, 0.16)
			c:light(GOLD, 1.5, 8)
		end,
	}

	-- The lost civic hall itself: stepped massing, lit windows, floating pearls.
	S.at_t_atlanteum = {
		label = "Lost Atlanteum",
		set = SET,
		tint = C3(100, 255, 190),
		scale = 1.25,
		head = CF(0, 1.80, 0),
		neck = CF(0, -0.70, 0.90),
		back = CF(0, 0.40, -0.90),
		build = function(c, p)
			c:box(V3(2.20, 0.40, 2.00), CF(0, -0.80, 0), p.dark, SLATE)
			c:box(V3(1.80, 1.00, 1.60), CF(0, 0.00, 0), p.base, SLATE)
			c:box(V3(1.20, 0.80, 1.00), CF(0, 0.90, 0), p.light, SLATE)
			c:cone(V3(1.00, 0.60, 0.90), CF(0, 1.50, 0), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:cyl(V3(1.20, 0.36, 0.36), CF(0.90 * s, 0.00, 0.60) * UP, p.pale, SLATE)
				c:box(V3(0.20, 0.50, 0.16), CF(0.90 * s, 0.40, 0.90), p.glow, NEON)
			end
			c:box(V3(0.70, 0.60, 0.20), CF(0, 0.00, 0.90), TEAL, NEON)
			c:eyes(0.30, 0.96, 0.28, 0.13, p.glow)
			c:ball(V3(0.32, 0.32, 0.32), CF(0, 1.90, 0), PEARL)
			for i = 0, 3 do
				local a = i * PI / 2
				c:ball(V3(0.18, 0.18, 0.18), CF(math.sin(a) * 1.00, 1.20, math.cos(a) * 0.90), p.glow, NEON)
			end
			c:sparkle(TEAL, 4, 0.6, 0.2)
			c:light(TEAL, 2.0, 10)
		end,
	}

	--------------------------------------------------------------------------
	-- DIVINE: the holiest ruins of the deep, radiant.
	--------------------------------------------------------------------------

	-- A towering statue of the tide king on a gold plinth, trident raised.
	S.at_t_poseidon = {
		label = "Tide Poseidon",
		set = SET,
		tint = C3(40, 140, 230),
		scale = 1.25,
		head = CF(0, 1.80, 0.10),
		neck = CF(0, -0.60, 0.70),
		back = CF(0, 0.50, -0.70),
		build = function(c, p)
			c:box(V3(1.40, 1.60, 1.00), CF(0, 0.20, 0), p.base, SLATE)
			c:box(V3(1.20, 0.60, 0.80), CF(0, 1.20, 0.10), p.light, SLATE)
			c:box(V3(1.00, 0.50, 0.70), CF(0, -0.80, 0), p.dark, SLATE)
			c:box(V3(0.90, 0.20, 0.70), CF(0, 1.60, 0.10), GOLD, METAL)
			for _, x in ipairs({ -0.28, 0, 0.28 }) do
				c:cone(V3(0.22, 0.44, 0.22), CF(x, 1.96, 0.10), GOLD, METAL)
			end
			c:box(V3(0.16, 1.60, 0.16), CF(0.80, 0.60, 0.20), GOLD, METAL)
			c:box(V3(0.70, 0.16, 0.12), CF(0.80, 1.40, 0.20), GOLD, METAL)
			for _, x in ipairs({ -0.24, 0, 0.24 }) do
				c:cone(V3(0.14, 0.36, 0.14), CF(0.80 + x, 1.70, 0.20), p.glow, NEON)
			end
			c:eyes(1.30, 0.52, 0.28, 0.14, TEAL)
			c:box(V3(0.30, 0.10, 0.08), CF(0, 1.00, 0.52), INK)
			blush(c, 0.44, 1.06, 0.50)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.36, 0.24, 0.40), CF(0.40 * s, -1.20, 0.20), p.deep, SLATE)
			end
			c:box(V3(1.60, 0.20, 1.20), CF(0, -1.10, 0), GOLD, METAL)
			c:ball(V3(0.28, 0.28, 0.28), CF(0, 1.64, 0.40), PEARL)
			c:sparkle(GOLD, 4, 0.6, 0.2)
			c:light(TEAL, 2.2, 11)
		end,
	}

	-- Tiered stone rings around a glowing arena floor.
	S.at_t_amphitheater = {
		label = "Deep Amphitheater",
		set = SET,
		tint = C3(52, 48, 70),
		scale = 1.25,
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.50, 0.90),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			c:cyl(V3(0.40, 2.20, 2.20), CF(0, -0.50, 0) * UP, p.dark, SLATE)
			c:cyl(V3(0.30, 1.80, 1.80), CF(0, -0.20, 0) * UP, p.base, SLATE)
			c:cyl(V3(0.30, 1.30, 1.30), CF(0, 0.10, 0) * UP, p.light, SLATE)
			c:cyl(V3(0.20, 0.80, 0.80), CF(0, 0.30, 0) * UP, DEEP, GLASS).Transparency = 0.4
			c:box(V3(0.70, 0.50, 0.30), CF(0, 0.40, 0.90), p.pale)
			face(c, 0.50, 1.06, 0.26, 0.13, p.glow)
			blush(c, 0.42, 0.20, 1.04)
			for i = 0, 5 do
				local a = i * PI / 3
				c:box(V3(0.20, 0.30, 0.20), CF(math.sin(a) * 1.10, 0.00, math.cos(a) * 1.10), GOLD, METAL)
				c:ball(V3(0.16, 0.16, 0.16), CF(math.sin(a) * 1.10, 0.30, math.cos(a) * 1.10), p.glow, NEON)
			end
			c:box(V3(0.50, 0.10, 0.50), CF(0, 0.50, 0) * DIAMOND, TEAL, NEON)
			c:sparkle(GOLD, 3, 0.5, 0.18)
			c:light(TEAL, 2.0, 10)
		end,
	}

	-- A moonlit sea spirit with neon fins and a floating halo disc.
	S.at_t_nereid = {
		label = "Moon Nereid",
		set = SET,
		tint = C3(200, 190, 255),
		scale = 1.2,
		head = CF(0, 1.40, 0.20),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.50, -0.90),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.40, 1.50, 1.20),
				eyeY = 0.30, eyeSpread = 0.34, eyeSize = V3(0.40, 0.46, 0.18), eyeColor = TEAL,
				mouthY = -0.18, mouthSize = V3(0.34, 0.10, 0.10),
				legs = false, tail = false,
			})
			c:box(V3(1.10, 0.50, 0.90), CF(0, -0.90, -0.20), p.base)
			c:box(V3(0.70, 0.40, 1.00), CF(0, -1.00, -0.80), p.light)
			c:wedge(V3(0.14, 0.60, 0.80), CF(0, -0.70, -1.30) * ANG(0, PI, 0), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.16 * s, 0.90, 0.20), V3(0.56 * s, 1.50, 0.10), 0.05, p.pale, nil, false)
				c:ball(V3(0.24, 0.24, 0.24), CF(0.58 * s, 1.54, 0.10), PEARL)
				c:box(V3(0.14, 0.60, 0.50), CF(0.80 * s, 0.20, -0.20) * ANG(0, 0, -0.45 * s), TEAL, NEON).Transparency = 0.3
			end
			c:box(V3(0.70, 0.12, 0.50), CF(0, 0.10, 0.60), GOLD, METAL)
			c:cyl(V3(0.10, 0.70, 0.70), CF(0, 1.40, -0.40) * FRONT, p.glow, NEON).Transparency = 0.4
			c:sparkle(PEARL, 4, 0.6, 0.2)
			c:light(TEAL, 1.8, 9)
		end,
	}

	-- A stepped pyramid temple crowned with a glowing diamond beacon.
	S.at_t_ziggurat = {
		label = "Luminous Ziggurat",
		set = SET,
		tint = C3(255, 232, 120),
		scale = 1.25,
		head = CF(0, 1.90, 0),
		neck = CF(0, -0.80, 0.90),
		back = CF(0, 0.40, -0.90),
		build = function(c, p)
			c:box(V3(2.20, 0.40, 2.00), CF(0, -0.80, 0), p.dark, SLATE)
			c:box(V3(1.80, 0.40, 1.60), CF(0, -0.40, 0), p.base, SLATE)
			c:box(V3(1.40, 0.40, 1.20), CF(0, 0.00, 0), p.light, SLATE)
			c:box(V3(1.00, 0.40, 0.80), CF(0, 0.40, 0), p.pale, SLATE)
			c:box(V3(0.60, 0.50, 0.50), CF(0, 0.85, 0), GOLD, METAL)
			c:box(V3(0.40, 0.40, 0.40), CF(0, 1.30, 0) * DIAMOND, p.glow, NEON)
			c:box(V3(0.70, 0.50, 0.20), CF(0, -0.20, 0.90), TEAL, NEON)
			c:eyes(0.00, 0.96, 0.28, 0.13, p.glow)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.20, 0.30, 0.16), CF(0.70 * s, -0.20, 0.80), GOLD, METAL)
				c:ball(V3(0.20, 0.20, 0.20), CF(0.80 * s, 0.40, 0.50), PEARL)
			end
			c:sparkle(GOLD, 4, 0.6, 0.2)
			c:light(GOLD, 2.2, 11)
		end,
	}

	--------------------------------------------------------------------------
	-- EXOTIC: the first city under the waves.
	--------------------------------------------------------------------------

	-- A spiked undersea gateway with glowing portcullis bars.
	S.at_t_abyssgate = {
		label = "Primeval Abyssgate",
		set = SET,
		tint = C3(24, 60, 120),
		scale = 1.3,
		head = CF(0, 1.90, 0),
		neck = CF(0, -0.90, 0.50),
		back = CF(0, 0.30, -0.50),
		build = function(c, p)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.50, 2.20, 0.70), CF(1.00 * s, 0.10, 0), p.deep, SLATE)
				c:box(V3(0.60, 0.30, 0.80), CF(1.00 * s, 1.30, 0), GOLD, METAL)
				c:box(V3(0.60, 0.30, 0.80), CF(1.00 * s, -1.10, 0), p.dark, SLATE)
			end
			c:box(V3(2.40, 0.50, 0.80), CF(0, 1.50, 0), p.base, SLATE)
			c:box(V3(2.00, 0.20, 0.70), CF(0, 1.80, 0), GOLD, METAL)
			for _, x in ipairs({ -0.60, 0, 0.60 }) do
				c:box(V3(0.20, 1.80, 0.20), CF(x, 0.10, 0.20), p.base, METAL)
				c:cone(V3(0.24, 0.36, 0.24), CF(x, -0.90, 0.20) * ANG(PI, 0, 0), p.glow, NEON)
			end
			for _, y in ipairs({ 0.70, 0.10, -0.50 }) do
				c:box(V3(1.60, 0.14, 0.16), CF(0, y, 0.20), GOLD, METAL)
			end
			face(c, 0.40, 0.34, 0.30, 0.14, TEAL)
			blush(c, 0.50, 0.10, 0.32)
			c:box(V3(1.60, 1.80, 0.08), CF(0, 0.10, -0.30), TEAL, NEON).Transparency = 0.5
			c:sparkle(TEAL, 4, 0.6, 0.22)
			c:light(TEAL, 2.4, 12)
		end,
	}

	-- The sealed holy chamber: dome, pearl ring and a neon doorway.
	S.at_t_sanctum = {
		label = "Tidebound Sanctum",
		set = SET,
		tint = C3(64, 208, 200),
		scale = 1.3,
		head = CF(0, 1.90, 0),
		neck = CF(0, -0.80, 0.90),
		back = CF(0, 0.50, -0.90),
		build = function(c, p)
			c:box(V3(2.00, 1.40, 1.80), CF(0, 0.00, 0), p.base, SLATE)
			c:box(V3(1.40, 0.90, 1.20), CF(0, 1.10, 0), p.light, SLATE)
			c:cone(V3(1.20, 0.70, 1.00), CF(0, 1.80, 0), GOLD, METAL)
			c:box(V3(0.80, 0.70, 0.20), CF(0, 0.00, 0.96), p.glow, NEON)
			c:eyes(0.40, 1.02, 0.30, 0.14, TEAL)
			for _, s in ipairs(SIDES) do
				c:cyl(V3(1.40, 0.40, 0.40), CF(0.90 * s, 0.20, 0.60) * UP, p.pale, SLATE)
				c:ball(V3(0.30, 0.30, 0.30), CF(0.90 * s, 1.00, 0.60), PEARL)
				c:box(V3(0.16, 0.60, 0.16), CF(0.70 * s, 0.40, 0.90), GOLD, METAL)
			end
			c:box(V3(2.10, 0.20, 1.90), CF(0, -0.80, 0), GOLD, METAL)
			c:ball(V3(0.36, 0.36, 0.36), CF(0, 2.20, 0), p.glow, NEON)
			for i = 0, 5 do
				local a = i * PI / 3
				c:ball(V3(0.16, 0.16, 0.16), CF(math.sin(a) * 0.90, 1.60, math.cos(a) * 0.70), PEARL)
			end
			c:sparkle(GOLD, 5, 0.7, 0.22)
			c:light(TEAL, 2.4, 12)
		end,
	}

	-- The throne platform of the deep: stepped dais and glowing armrests.
	S.at_t_dais = {
		label = "Deepthrone Dais",
		set = SET,
		tint = C3(236, 190, 70),
		scale = 1.3,
		head = CF(0, 1.80, 0),
		neck = CF(0, -0.70, 0.90),
		back = CF(0, 0.40, -0.90),
		build = function(c, p)
			c:box(V3(2.20, 0.30, 2.00), CF(0, -0.80, 0), p.dark, SLATE)
			c:box(V3(1.80, 0.30, 1.60), CF(0, -0.50, 0), p.base, SLATE)
			c:box(V3(1.40, 0.30, 1.20), CF(0, -0.20, 0), GOLD, METAL)
			c:box(V3(1.00, 1.20, 0.80), CF(0, 0.60, -0.20), p.light, SLATE)
			c:box(V3(1.20, 0.30, 0.50), CF(0, 0.40, 0.50), GOLD, METAL)
			c:box(V3(0.80, 0.50, 0.30), CF(0, 1.40, -0.20), p.pale, SLATE)
			c:box(V3(0.90, 0.16, 0.40), CF(0, 1.70, -0.20), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.30, 0.70, 0.30), CF(0.70 * s, 0.80, -0.20), GOLD, METAL)
				c:cone(V3(0.26, 0.40, 0.26), CF(0.70 * s, 1.30, -0.20), p.glow, NEON)
			end
			c:box(V3(0.60, 0.40, 0.20), CF(0, 0.20, 0.90), TEAL, NEON)
			c:eyes(0.40, 0.96, 0.26, 0.13, p.glow)
			c:ball(V3(0.30, 0.30, 0.30), CF(0, 1.90, -0.20), PEARL)
			c:sparkle(GOLD, 5, 0.7, 0.22)
			c:light(GOLD, 2.4, 12)
		end,
	}

	-- A primeval standing stone etched with neon tide-runes.
	S.at_t_megalith = {
		label = "Oceanborn Megalith",
		set = SET,
		tint = C3(168, 172, 160),
		scale = 1.3,
		head = CF(0, 2.00, 0),
		neck = CF(0, -0.90, 0.50),
		back = CF(0, 0.30, -0.50),
		build = function(c, p)
			c:box(V3(1.40, 2.40, 0.70), CF(0, 0.10, 0), p.base, SLATE)
			c:box(V3(1.60, 0.30, 0.90), CF(0, 1.40, 0), GOLD, METAL)
			c:box(V3(1.70, 0.30, 1.00), CF(0, -1.20, 0), p.dark, SLATE)
			for _, y in ipairs({ 0.80, 0.20, -0.40 }) do
				c:box(V3(1.00, 0.14, 0.16), CF(0, y, 0.36), TEAL, NEON)
			end
			c:box(V3(0.50, 0.50, 0.16), CF(0, 0.80, 0.40) * DIAMOND, p.glow, NEON)
			face(c, 0.00, 0.38, 0.30, 0.14, TEAL)
			blush(c, 0.48, -0.30, 0.36)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.40, 0.90, 0.40), CF(0.90 * s, -0.60, 0), p.deep, SLATE)
				c:ball(V3(0.24, 0.24, 0.24), CF(0.90 * s, 0.00, 0), PEARL)
			end
			c:ball(V3(0.36, 0.36, 0.36), CF(0, 1.70, 0), p.glow, NEON)
			c:sparkle(TEAL, 5, 0.7, 0.24)
			c:light(TEAL, 2.6, 13)
		end,
	}

	-- A glass heart of the ocean on a gold cradle, ringed with pearls.
	S.at_t_heartstone = {
		label = "Fathom Heartstone",
		set = SET,
		tint = C3(220, 70, 170),
		scale = 1.3,
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.70, 0.70),
		back = CF(0, 0.40, -0.70),
		build = function(c, p)
			c:ball(V3(1.80, 1.80, 1.80), CF(0, 0.20, 0), p.base, GLASS).Transparency = 0.25
			c:ball(V3(1.20, 1.20, 1.20), CF(0, 0.20, 0), TEAL, NEON)
			c:ball(V3(0.70, 0.70, 0.70), CF(0, 0.20, 0), p.glow, NEON)
			c:box(V3(1.60, 0.30, 1.60), CF(0, -0.90, 0), GOLD, METAL)
			c:box(V3(1.20, 0.40, 1.20), CF(0, -1.20, 0), p.dark, SLATE)
			face(c, 0.40, 0.90, 0.30, 0.14, PEARL)
			blush(c, 0.50, 0.10, 0.88)
			for i = 0, 5 do
				local a = i * PI / 3
				c:rod(V3(0, 0.20, 0), V3(math.sin(a) * 1.10, 0.20 + math.cos(a) * 0.30, math.cos(a) * 1.10), 0.05, GOLD, METAL, false)
				c:ball(V3(0.20, 0.20, 0.20), CF(math.sin(a) * 1.10, 0.20 + math.cos(a) * 0.30, math.cos(a) * 1.10), PEARL)
			end
			feet(c, p.deep, SLATE, 0.50, -1.50, 0.50, V3(0.36, 0.18, 0.36))
			c:sparkle(TEAL, 5, 0.7, 0.24)
			c:light(TEAL, 2.8, 14)
		end,
	}

	-- The first well of Atlantis: a glowing vortex in a gold-rimmed cistern.
	S.at_t_tidewell = {
		label = "Genesis Tidewell",
		set = SET,
		tint = C3(100, 255, 190),
		scale = 1.3,
		head = CF(0, 1.80, 0),
		neck = CF(0, -0.70, 0.90),
		back = CF(0, 0.40, -0.90),
		build = function(c, p)
			c:cyl(V3(0.50, 2.20, 2.20), CF(0, -0.40, 0) * UP, p.dark, SLATE)
			c:cyl(V3(0.40, 1.80, 1.80), CF(0, -0.10, 0) * UP, GOLD, METAL)
			c:cyl(V3(0.80, 1.40, 1.40), CF(0, 0.20, 0) * UP, DEEP, GLASS).Transparency = 0.35
			c:cyl(V3(0.50, 1.00, 1.00), CF(0, 0.50, 0) * UP, TEAL, NEON)
			c:ball(V3(0.60, 0.60, 0.60), CF(0, 0.90, 0), p.glow, NEON)
			c:box(V3(0.70, 0.50, 0.20), CF(0, 0.20, 1.00), p.pale)
			face(c, 0.36, 1.12, 0.28, 0.13, TEAL)
			blush(c, 0.46, 0.06, 1.10)
			for i = 0, 7 do
				local a = i * PI / 4
				c:box(V3(0.18, 0.40, 0.18), CF(math.sin(a) * 1.10, 0.60, math.cos(a) * 1.10), GOLD, METAL)
				c:ball(V3(0.16, 0.16, 0.16), CF(math.sin(a) * 1.10, 0.90, math.cos(a) * 1.10), PEARL)
			end
			feet(c, p.deep, SLATE, 0.70, -0.90, 0.70, V3(0.36, 0.18, 0.36))
			c:sparkle(TEAL, 6, 0.8, 0.26)
			c:light(TEAL, 3.0, 14)
		end,
	}

	return S
end
