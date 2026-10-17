--[[ PetBodies/CrystalHollowTop -- Crystal Hollow's top bodies. See tools/gen/sets/README.md.

	Epic and up: each body here is worn by exactly ONE pet in the game. The set
	is geology and mineral collecting, so each body is a crystal habit, a cave
	formation, a mineral's party trick (double refraction, fluorescence,
	asterism, chatoyancy, schiller), a collector's tool, or a creature from
	miners' tales, given a face. Mythic, Divine and Exotic carry neon glow.
]]
return function(K)
	local C3, block, ears, wings, spots = K.C3, K.block, K.ears, K.wings, K.spots
	local INK, WHITE, NOSE = K.INK, K.WHITE, K.NOSE
	local METAL, NEON, GLASS, SLATE, WOOD = K.METAL, K.NEON, K.GLASS, K.SLATE, K.WOOD
	local GOLD, SILVER, BLUSH = C3(240, 196, 72), C3(206, 210, 222), C3(255, 150, 160)
	local RUBY, AQUA, CITRINE, LEAF = C3(230, 40, 80), C3(80, 220, 230), C3(250, 200, 50), C3(60, 190, 90)
	local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
	local PI = math.pi
	local SIDES = { -1, 1 }
	local S = {}

	-- A crystal point: a square shaft turned 45 degrees and a pyramid tip,
	-- tilted from its root by `ax` (back/forward) and `az` (sideways).
	local function point(c, root, ax, az, w, h, colour, mat)
		local cf = CF(root) * A(ax, 0, az)
		local turn = A(0, PI / 4, 0)
		c:box(V(w, h, w), cf * CF(0, h * 0.5, 0) * turn, colour, mat or GLASS)
		c:cone(V(w, w * 1.1, w), cf * CF(0, h + w * 0.55, 0) * turn, colour, mat or GLASS)
	end

	-- Two pyramids base to base: an octahedron, `h` tall each way.
	local function octa(c, cf, w, h, colour, mat)
		c:cone(V(w, h, w), cf * CF(0, h * 0.5, 0), colour, mat)
		c:cone(V(w, h, w), cf * CF(0, -h * 0.5, 0) * A(PI, 0, 0), colour, mat)
	end

	-- A hexagonal prism along the local Y axis: three boxes 60 degrees apart.
	local function hex(c, cf, r, h, colour, mat)
		for i = 0, 2 do
			c:box(V(r, h, r * 1.732), cf * A(0, i * PI / 3, 0), colour, mat)
		end
	end

	local function cheeks(c, y, z, spread)
		for _, s in ipairs(SIDES) do
			c:box(V(0.20, 0.10, 0.04), CF(spread * s, y, z), BLUSH)
		end
	end

	----------------------------------------------------------------------------
	-- EPIC: charming and clean.
	----------------------------------------------------------------------------

	-- Natrolite grows as sprays of fine needles: a round urchin bristling with
	-- glassy spikes, its face left clear.
	S.ch_t_urchin = {
		label = "Natrolite Urchin",
		set = "crystal_hollow",
		tint = C3(230, 240, 255),
		scale = 1.28,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.36, 0.70),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.80, 1.70, 1.70),
				eyeSpread = 0.34, eyeSize = V(0.42, 0.50, 0.20), eyeY = 0.14,
				mouthY = -0.26, mouthSize = V(0.24, 0.12, 0.12),
				legs = false, tail = false,
			})
			for i, d in ipairs({
				{ 0, 0 }, { 0.80, 0.85 }, { -0.80, 0.85 }, { 1.57, 0.95 }, { -1.57, 0.95 },
				{ 1.57, 1.65 }, { -1.57, 1.65 }, { 2.36, 0.85 }, { -2.36, 0.85 },
				{ PI, 0.55 }, { PI, 1.45 }, { 1.90, 2.30 }, { -1.90, 2.30 },
			}) do
				local cf = CF(0, 0.06, 0) * A(0, d[1], 0) * A(d[2], 0, 0)
				c:box(V(0.10, 0.80, 0.10), cf * CF(0, 1.18, 0), i % 2 == 0 and p.pale or p.light, GLASS)
			end
			cheeks(c, -0.12, 0.88, 0.56)
		end,
	}

	-- A halite hopper crystal: salt grows fastest along its edges, so each face
	-- is a stepped, sunken square. Big hind feet, because it hops.
	S.ch_t_hopper = {
		label = "Halite Stepper",
		set = "crystal_hollow",
		tint = C3(120, 150, 255),
		head = CF(0, 1.30, 0.10),
		neck = CF(0, -0.30, 0.66),
		back = CF(0, 0.30, -0.66),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.80, 1.66, 1.66), bodyMat = GLASS,
				eyeSize = V(0.44, 0.52, 0.20), eyeSpread = 0.38, eyeY = 0.12,
				mouthSize = V(0.26, 0.12, 0.12), mouthY = -0.30,
				legs = false, tail = false,
			})
			c:box(V(1.70, 0.12, 1.56), CF(0, 0.95, 0), p.light, GLASS)
			c:box(V(1.20, 0.10, 1.06), CF(0, 1.06, 0), p.pale, GLASS)
			c:box(V(0.66, 0.06, 0.58), CF(0, 1.13, 0), p.deep)
			for _, s in ipairs(SIDES) do
				c:box(V(0.12, 1.30, 1.30), CF(0.95 * s, 0.06, -0.06), p.light, GLASS)
				c:box(V(0.08, 0.70, 0.70), CF(1.04 * s, 0.06, -0.06), p.deep)
				c:box(V(0.50, 0.30, 0.96), CF(0.62 * s, -0.86, -0.22), p.dark)
				c:box(V(0.34, 0.24, 0.34), CF(0.46 * s, -0.84, 0.56), p.dark)
			end
			-- Loose salt grains.
			for _, g in ipairs({ { -1.10, 0.90, 0.30, 0.18 }, { 1.12, 1.10, -0.40, 0.14 }, { 0.20, 1.40, -0.60, 0.16 } }) do
				c:box(V(g[4], g[4], g[4]), CF(g[1], g[2], g[3]) * A(0.5, 0.6, 0.3), p.pale, GLASS)
			end
		end,
	}

	-- A fish of gypsum whose tail is a swallowtail twin: two blades grown
	-- together in a deep V. Satin striations run down its sides.
	S.ch_t_fishtail = {
		label = "Fishtail Gypsum",
		set = "crystal_hollow",
		tint = C3(240, 214, 130),
		scale = 1.12,
		head = CF(0, 1.00, 0.20),
		neck = CF(0, -0.34, 0.80),
		back = CF(0, 0.40, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.30, 1.60, 1.90), bodyMat = GLASS,
				eyeSpread = 0.30, eyeSize = V(0.36, 0.46, 0.20), eyeY = 0.18,
				mouthSize = V(0.28, 0.14, 0.12), mouthY = -0.22,
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V(0.16, 1.00, 0.44), CF(0, 0.06 + 0.36 * s, -1.24) * A(-0.70 * s, 0, 0), p.light, GLASS)
				c:box(V(0.10, 0.36, 0.56), CF(0.72 * s, -0.20, 0.10) * A(0.3, 0, 0.5 * s), p.pale, GLASS)
				c:box(V(0.04, 1.10, 0.10), CF(0.68 * s, 0.06, -0.20), p.pale)
				c:box(V(0.04, 0.90, 0.10), CF(0.68 * s, 0.06, -0.50), p.pale)
			end
			c:box(V(0.12, 0.50, 0.90), CF(0, 0.96, -0.20) * A(-0.35, 0, 0), p.light, GLASS)
			c:ball(V(0.16, 0.16, 0.16), CF(0.30, 1.20, 1.00), p.pale, GLASS)
			c:ball(V(0.10, 0.10, 0.10), CF(0.42, 1.44, 1.04), p.pale, GLASS)
		end,
	}

	-- A crocodile bristling with crocoite: bright orange needle crystals down
	-- its back and tail. Tiny friendly teeth.
	S.ch_t_croc = {
		label = "Crocoite Croc",
		set = "crystal_hollow",
		tint = C3(250, 104, 30),
		scale = 1.35,
		head = CF(0, 0.80, 0.30),
		neck = CF(0, -0.30, 1.10),
		back = CF(0, 0.40, -0.40),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.60, 1.10, 1.80),
				eyeSize = V(0.36, 0.40, 0.22), eyeSpread = 0.40, eyeY = 0.40,
				snout = { w = 1.00, h = 0.40, d = 0.70, y = -0.18, color = p.light },
				legSize = V(0.42, 0.30, 0.50), legX = 0.78, legY = -0.52, legZ = { 0.55, -0.55 }, legColor = p.dark,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(V(0.10, 0.14, 0.10), CF(0.40 * s, -0.42, 1.30) * A(PI, 0, 0), WHITE)
			end
			c:box(V(0.76, 0.52, 0.70), CF(0, -0.10, -1.20), p.base)
			c:box(V(0.46, 0.36, 0.60), CF(0, -0.20, -1.72), p.dark)
			for i, n in ipairs({
				{ 0.10, 0.84, 0.50, 0.2, 0.0 }, { -0.25, 0.84, 0.20, -0.2, 0.3 }, { 0.30, 0.84, -0.15, 0.25, -0.35 },
				{ -0.10, 0.84, -0.50, -0.3, 0.1 }, { 0.20, 0.84, -0.80, 0.2, -0.2 }, { -0.10, 0.44, -1.20, -0.25, 0.3 },
				{ 0.10, 0.26, -1.72, 0.1, -0.2 },
			}) do
				c:box(V(0.12, 0.62, 0.12), CF(n[1], n[2], n[3]) * A(n[4], 0, n[5]), i % 2 == 0 and p.light or p.pale, GLASS)
			end
		end,
	}

	-- A walrus whose tusks are dogtooth calcite: long, sharp, glassy points.
	S.ch_t_walrus = {
		label = "Dogtooth Walrus",
		set = "crystal_hollow",
		tint = C3(196, 130, 92),
		head = CF(0, 1.04, 0.10),
		neck = CF(0, -0.50, 0.80),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(2.10, 1.70, 1.90),
				eyeSize = V(0.34, 0.40, 0.18), eyeSpread = 0.42, eyeY = 0.34,
				snout = { w = 0.96, h = 0.50, d = 0.40, y = -0.06, color = p.pale },
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(V(0.22, 0.70, 0.22), CF(0.26 * s, -0.58, 1.04) * A(PI, 0, 0.06 * s), WHITE, GLASS)
				c:box(V(0.70, 0.16, 0.50), CF(0.92 * s, -0.76, 0.40) * A(0, -0.4 * s, -0.2 * s), p.dark)
				c:box(V(0.50, 0.14, 0.60), CF(0.36 * s, -0.70, -1.10) * A(0, 0.5 * s, 0), p.dark)
			end
			spots(c, p.deep, { { -0.24, -0.02, 1.26 }, { 0.24, -0.02, 1.26 }, { -0.12, -0.14, 1.26 }, { 0.12, -0.14, 1.26 } }, V(0.07, 0.07, 0.05))
		end,
	}

	-- Under ultraviolet light many minerals glow. So does this gecko's spotted
	-- back, like fluorite and willemite under a blacklight.
	S.ch_t_gecko = {
		label = "Blacklight Gecko",
		set = "crystal_hollow",
		tint = C3(110, 40, 220),
		scale = 1.15,
		head = CF(0, 0.70, 0.30),
		neck = CF(0, -0.20, 1.00),
		back = CF(0, 0.60, -0.40),
		build = function(c, p)
			local glowA, glowB = C3(120, 255, 90), C3(255, 150, 40)
			block(c, p, {
				bodySize = V(1.70, 1.00, 2.10),
				eyeSize = V(0.48, 0.50, 0.30), eyeSpread = 0.50, eyeY = 0.26,
				mouthSize = V(0.60, 0.08, 0.10), mouthY = -0.20,
				legSize = V(0.56, 0.20, 0.34), legX = 1.00, legY = -0.30, legZ = { 0.62, -0.62 }, legColor = p.dark,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.62, -0.62 }) do
					c:ball(V(0.26, 0.16, 0.26), CF(1.32 * s, -0.36, z + 0.08), p.pale)
				end
			end
			c:box(V(0.56, 0.40, 0.70), CF(0, -0.16, -1.30), p.base)
			c:box(V(0.42, 0.32, 0.56), CF(0.30, -0.20, -1.80) * A(0, 0.6, 0), p.dark)
			c:box(V(0.30, 0.26, 0.40), CF(0.70, -0.22, -1.98) * A(0, 1.3, 0), p.base)
			for i, s in ipairs({ { -0.40, 0.58, 0.40 }, { 0.36, 0.58, 0.10 }, { -0.20, 0.58, -0.40 }, { 0.42, 0.58, -0.70 }, { 0, 0.06, -1.30 } }) do
				c:ball(V(0.26, 0.10, 0.26), CF(s[1], s[2], s[3]), i % 2 == 0 and glowB or glowA, NEON)
			end
		end,
	}

	-- A ring-tailed lemur whose tail is banded onyx, black and white, climbing
	-- up behind it and curling over.
	S.ch_t_lemur = {
		label = "Onyx Lemur",
		set = "crystal_hollow",
		tint = C3(64, 60, 76),
		scale = 1.16,
		head = CF(0, 1.04, 0.10),
		neck = CF(0, -0.30, 0.66),
		back = CF(0, 0.20, -0.66),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.80, 1.70, 1.60),
				eyeSize = V(0.40, 0.44, 0.20), eyeSpread = 0.40, eyeY = 0.20, eyeColor = C3(250, 160, 40),
				snout = { w = 0.50, h = 0.36, d = 0.46, y = -0.24, color = p.pale, nose = INK },
				bib = { w = 1.00, h = 0.60, y = -0.50, color = p.pale },
				legSize = V(0.42, 0.34, 0.46), legColor = p.dark, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V(0.58, 0.60, 0.06), CF(0.40 * s, 0.20, 0.81), p.deep)
			end
			ears(c, p.pale, "tuft")
			for i, t in ipairs({ { -0.10, -1.00 }, { 0.36, -1.18 }, { 0.82, -1.26 }, { 1.28, -1.22 }, { 1.70, -1.04 }, { 1.98, -0.76 } }) do
				c:box(V(0.38, 0.48, 0.38), CF(0, t[1], t[2]) * A(0.2 - 0.12 * i, 0, 0), i % 2 == 0 and WHITE or p.deep)
			end
		end,
	}

	-- A bison whose hump is a cluster of hexagonal basalt columns, like the
	-- ones lava leaves when it cools and cracks.
	S.ch_t_bison = {
		label = "Basalt Bison",
		set = "crystal_hollow",
		tint = C3(78, 92, 120),
		scale = 1.10,
		head = CF(0, 1.40, 0.30),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			block(c, p, {
				bodySize = V(2.00, 1.70, 1.90), bodyMat = SLATE,
				eyeSize = V(0.34, 0.40, 0.18), eyeSpread = 0.46, eyeY = 0.20,
				snout = { w = 0.84, h = 0.50, d = 0.36, y = -0.26, color = p.pale },
				brow = p.deep,
				legSize = V(0.50, 0.40, 0.50), legColor = p.deep,
				tailSize = V(0.20, 0.50, 0.20), tailColor = p.deep,
			})
			for _, s in ipairs(SIDES) do
				c:cone(V(0.24, 0.50, 0.24), CF(0.96 * s, 0.84, 0.52) * A(0, 0, -0.9 * s), p.pale)
			end
			c:box(V(0.50, 0.40, 0.20), CF(0, -0.68, 0.94), p.deep)
			hex(c, CF(0, 1.10, 0.10), 0.50, 0.70, p.dark, SLATE)
			hex(c, CF(-0.46, 1.00, -0.30), 0.42, 0.50, p.base, SLATE)
			c:box(V(0.40, 0.40, 0.69), CF(0.44, 0.96, -0.36) * A(0, 0.5, 0), p.light, SLATE)
		end,
	}

	-- Harvester ants carry garnets up to their hills. This anteater collects
	-- them instead, and wears a few on its back.
	S.ch_t_anteater = {
		label = "Garnet Anteater",
		set = "crystal_hollow",
		tint = C3(150, 20, 46),
		scale = 1.25,
		head = CF(0, 1.00, 0.20),
		neck = CF(0, -0.30, 1.00),
		back = CF(0, 0.30, -0.70),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.60, 1.60, 1.90),
				eyeSize = V(0.28, 0.34, 0.18), eyeSpread = 0.36, eyeY = 0.28,
				snout = { w = 0.36, h = 0.34, d = 0.80, y = -0.10, color = p.pale },
				legSize = V(0.44, 0.40, 0.50), legColor = p.deep, tail = false,
			})
			ears(c, p.dark, "round", p.pale)
			c:box(V(0.34, 0.60, 0.60), CF(0, 0.10, -1.10), p.dark)
			c:box(V(0.26, 1.30, 0.90), CF(0, 0.70, -1.30) * A(-0.35, 0, 0), p.deep)
			for _, g in ipairs({ { -0.30, 0.94, 0.20, 0.24 }, { 0.30, 0.92, -0.20, 0.28 }, { -0.10, 0.92, -0.62, 0.22 } }) do
				c:box(V(g[4], g[4], g[4]), CF(g[1], g[2], g[3]) * A(0.6, 0.78, 0.4), p.light, GLASS)
			end
			for _, s in ipairs(SIDES) do
				c:cone(V(0.14, 0.24, 0.14), CF(0.56 * s, -1.08, 0.70) * A(1.6, 0, 0), p.pale)
			end
			c:box(V(0.30, 0.30, 0.30), CF(0.70, -0.88, 1.20) * A(0.6, 0.78, 0.4), p.light, GLASS)
		end,
	}

	-- A pelican whose pouch bulges with gem crystals scooped from a pegmatite
	-- pocket. Its tail is a book of silvery mica.
	S.ch_t_pelican = {
		label = "Pegmatite Pelican",
		set = "crystal_hollow",
		tint = C3(250, 186, 160),
		scale = 1.12,
		head = CF(0, 1.10, 0.00),
		neck = CF(0, -0.10, 0.70),
		back = CF(0, 0.30, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V(1.80, 1.90, 1.70),
				eyeSize = V(0.34, 0.40, 0.18), eyeSpread = 0.40, eyeY = 0.42,
				mouth = false,
				legSize = V(0.20, 0.40, 0.20), legX = 0.36, legY = -0.96, legZ = { 0.10 }, legColor = C3(240, 150, 60),
				tail = false,
			})
			c:box(V(0.50, 0.14, 1.10), CF(0, 0.30, 1.30) * A(-0.12, 0, 0), p.pale)
			c:box(V(0.56, 0.48, 0.90), CF(0, -0.18, 1.24), p.light)
			for _, g in ipairs({ { -0.16, 0.12, 1.30, 0.22, RUBY }, { 0.16, 0.14, 1.10, 0.20, AQUA }, { 0.02, 0.12, 1.56, 0.18, CITRINE } }) do
				c:box(V(g[4], g[4] * 1.4, g[4]), CF(g[1], g[2], g[3]) * A(0.3, 0.78, 0.2), g[5], GLASS)
			end
			wings(c, p.dark, 0.30, 0.00, -0.20, 0.25)
			c:box(V(0.80, 0.12, 0.60), CF(0, -0.40, -1.00) * A(0.3, 0, 0), p.dark)
			c:box(V(0.60, 0.06, 0.40), CF(0, -0.32, -1.04) * A(0.3, 0, 0), SILVER, METAL)
		end,
	}

	-- A cicada whose wings are panes of clear citrine, folded in a tent over
	-- its back, with three tiny gem eyes on top.
	S.ch_t_cicada = {
		label = "Citrine Cicada",
		set = "crystal_hollow",
		tint = C3(250, 196, 30),
		scale = 1.10,
		head = CF(0, 0.90, 0.30),
		neck = CF(0, -0.30, 0.90),
		back = CF(0, 0.80, -0.40),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.60, 1.30, 1.90),
				eyeSize = V(0.50, 0.50, 0.32), eyeSpread = 0.64, eyeY = 0.16,
				mouthSize = V(0.20, 0.10, 0.10), mouthY = -0.24,
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				local wing = CF(0.46 * s, 0.86, -0.30) * A(0, 0, 0.62 * s)
				c:box(V(0.08, 0.90, 2.10), wing, p.pale, GLASS)
				c:box(V(0.10, 0.06, 1.90), wing * CF(0, 0.10, 0), p.deep)
				for _, z in ipairs({ 0.50, 0, -0.50 }) do
					c:rod(V(0.60 * s, -0.50, z), V(0.92 * s, -0.86, z + 0.10), 0.07, p.deep, nil, false)
				end
				c:rod(V(0.30 * s, 0.66, 0.86), V(0.50 * s, 0.98, 1.10), 0.04, p.deep, nil, false)
			end
			for _, x in ipairs({ -0.14, 0, 0.14 }) do
				c:ball(V(0.10, 0.10, 0.10), CF(x, 0.74, 0.70 + math.abs(x)), p.glow, GLASS)
			end
		end,
	}

	-- Clear calcite (Iceland spar) splits light in two, so everything seen
	-- through it is doubled. This rhomb sees double: a second, fainter pair of
	-- eyes and a second smile peek out beside its own.
	S.ch_t_spar = {
		label = "Iceland Spar",
		set = "crystal_hollow",
		tint = C3(180, 250, 225),
		head = CF(0, 1.10, 0.00),
		neck = CF(0, -0.30, 0.70),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.70, 1.60, 1.50), bodyMat = GLASS,
				eyeSize = V(0.40, 0.48, 0.20), eyeSpread = 0.36, eyeY = 0.10,
				mouthSize = V(0.24, 0.12, 0.12), mouthY = -0.30,
				legSize = V(0.40, 0.30, 0.40), legColor = p.dark, tail = false,
			})
			-- A leaning slab behind makes the outline a rhomb.
			c:box(V(1.50, 1.80, 0.90), CF(0, 0.06, -0.40) * A(0, 0, -0.34), p.light, GLASS)
			for _, s in ipairs(SIDES) do
				c:eye(V(0.36 * s + 0.24, 0.34, 0.76), 0.13, p.dark)
				c:box(V(0.08, 1.64, 0.08), CF(0.86 * s, 0.06, 0.76), p.pale)
			end
			c:box(V(0.24, 0.08, 0.06), CF(0.24, -0.06, 0.77), p.dark)
			c:box(V(1.74, 0.08, 0.08), CF(0, 0.88, 0.76), p.pale)
			c:box(V(1.74, 0.08, 0.08), CF(0, -0.76, 0.76), p.pale)
		end,
	}

	-- Helictites are cave formations that ignore gravity and twist off in any
	-- direction. This little blob has curls going every which way, each with
	-- a bead of water at its tip.
	S.ch_t_helictite = {
		label = "Helictite Curl",
		set = "crystal_hollow",
		tint = C3(230, 80, 120),
		scale = 1.10,
		head = CF(0, 1.40, 0.00),
		neck = CF(0, -0.36, 0.70),
		back = CF(0, 0.30, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.60, 1.50, 1.50),
				eyeSize = V(0.40, 0.48, 0.20), eyeSpread = 0.34, eyeY = 0.10,
				mouthSize = V(0.22, 0.12, 0.12), mouthY = -0.30,
				legs = false, tail = false,
			})
			for i, t in ipairs({
				{ V(0, 0.70, -0.10), V(0.20, 1.15, -0.20), V(0.50, 1.30, 0.00), V(0.55, 1.10, 0.25) },
				{ V(-0.74, 0.30, 0), V(-1.15, 0.45, 0.10), V(-1.30, 0.80, -0.10), V(-1.05, 0.95, -0.30) },
				{ V(0.76, -0.10, -0.10), V(1.15, -0.25, 0.10), V(1.30, 0.10, 0.20) },
				{ V(0.10, 0.40, -0.70), V(0, 0.70, -1.10), V(-0.35, 0.65, -1.30) },
			}) do
				for k = 1, #t - 1 do
					c:rod(t[k], t[k + 1], 0.07, k % 2 == 0 and p.pale or p.light, GLASS, false)
				end
				c:ball(V(0.16, 0.18, 0.16), CF(t[#t]), i % 2 == 0 and p.pale or C3(170, 220, 255), GLASS)
			end
		end,
	}

	-- A bowerbird collects blue treasures to decorate its bower. This one
	-- hoards azurite: nodules, and a flat azurite "sun".
	S.ch_t_bowerbird = {
		label = "Azurite Bowerbird",
		set = "crystal_hollow",
		tint = C3(20, 44, 180),
		scale = 1.10,
		head = CF(0, 1.06, 0.00),
		neck = CF(0, -0.10, 0.70),
		back = CF(0, 0.30, -0.70),
		build = function(c, p)
			local twig = C3(150, 110, 70)
			block(c, p, {
				shape = "bird", bodySize = V(1.70, 1.80, 1.60),
				eyeSize = V(0.34, 0.40, 0.18), eyeSpread = 0.38, eyeY = 0.32, eyeColor = C3(120, 200, 255),
				mouth = false,
				legSize = V(0.20, 0.36, 0.20), legX = 0.34, legY = -0.94, legZ = { 0.10 }, legColor = C3(60, 52, 70),
				tail = false,
			})
			c:cone(V(0.26, 0.34, 0.20), CF(0, 0.02, 0.92) * A(PI / 2, 0, 0), C3(240, 210, 120))
			wings(c, p.dark, 0.26, 0.04, -0.20, 0.30)
			c:box(V(0.50, 0.14, 0.80), CF(0, -0.36, -1.02) * A(0.4, 0, 0), p.deep)
			-- The bower: an arch of twigs behind.
			c:rod(V(-1.02, -1.00, -0.70), V(-0.70, 0.90, -1.10), 0.06, twig, WOOD, false)
			c:rod(V(1.02, -1.00, -0.70), V(0.70, 0.90, -1.10), 0.06, twig, WOOD, false)
			c:rod(V(-0.70, 0.90, -1.10), V(0.70, 0.90, -1.10), 0.06, twig, WOOD, false)
			for _, b in ipairs({ { -0.80, -0.98, 0.70, 0.30 }, { 0.84, -1.00, 0.50, 0.24 }, { 0.60, -1.02, 0.90, 0.18 } }) do
				c:ball(V(b[4], b[4], b[4]), CF(b[1], b[2], b[3]), p.light)
			end
			c:cyl(V(0.06, 0.44, 0.44), CF(-0.50, -1.08, 1.00) * A(0, 0, PI / 2), p.pale)
		end,
	}

	-- A "fairy cross": two staurolite prisms grown through each other at right
	-- angles. It floats, and its face is where they cross.
	S.ch_t_cross = {
		label = "Staurolite Cross",
		set = "crystal_hollow",
		tint = C3(176, 88, 48),
		head = CF(0, 1.30, 0.00),
		neck = CF(0, -0.50, 0.50),
		back = CF(0, 0.20, -0.50),
		build = function(c, p)
			c:box(V(0.86, 2.50, 0.74), CF(0, 0.06, 0), p.base, SLATE)
			c:box(V(2.50, 0.86, 0.74), CF(0, 0.06, 0), p.base, SLATE)
			c:box(V(0.90, 0.90, 0.80), CF(0, 0.06, 0), p.dark, SLATE)
			for _, a in ipairs({ 0, PI / 2, PI, -PI / 2 }) do
				c:prism(V(0.74, 0.30, 0.86), CF(0, 0.06, 0) * A(0, 0, a) * CF(0, 1.40, 0) * A(0, PI / 2, 0), p.light, SLATE)
			end
			c:eyes(0.16, 0.44, 0.20, 0.12)
			c:box(V(0.18, 0.07, 0.06), CF(0, -0.12, 0.42), INK)
			cheeks(c, -0.04, 0.42, 0.32)
			-- Mica flakes glinting in the stone.
			for _, m in ipairs({ { -0.90, 0.20 }, { 0.80, -0.06 }, { 0.10, 0.90 }, { -0.10, -0.86 } }) do
				c:box(V(0.14, 0.14, 0.04), CF(m[1], m[2], 0.39) * A(0, 0, 0.7), p.pale, METAL)
			end
		end,
	}

	-- A fluorite octahedron balanced on its point, colour-banded across its
	-- middle, juggling two little fluorite cubes.
	S.ch_t_bipyramid = {
		label = "Fluorite Bipyramid",
		set = "crystal_hollow",
		tint = C3(110, 230, 110),
		head = CF(0, 1.40, 0.00),
		neck = CF(0, -0.30, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			octa(c, CF(0, 0.10, 0), 1.70, 1.24, p.base, GLASS)
			c:box(V(1.76, 0.10, 1.76), CF(0, 0.10, 0), p.pale, GLASS)
			c:box(V(1.16, 0.08, 1.16), CF(0, 0.52, 0), p.light, GLASS)
			c:eyes(0.30, 0.76, 0.26, 0.13)
			c:box(V(0.20, 0.07, 0.08), CF(0, -0.10, 0.74), INK)
			cheeks(c, 0.0, 0.80, 0.46)
			for _, s in ipairs(SIDES) do
				c:ball(V(0.30, 0.30, 0.30), CF(0.96 * s, 0.02, 0.10), p.light)
			end
			c:box(V(0.24, 0.24, 0.24), CF(-0.96, 0.62, 0.30) * A(0.4, 0.5, 0.2), p.pale, GLASS)
			c:box(V(0.20, 0.20, 0.20), CF(1.02, 0.80, 0.10) * A(0.6, 0.2, 0.5), p.light, GLASS)
		end,
	}

	-- A hammerhead whose head IS a geologist's rock hammer: a square face on
	-- one end, a pick on the other, an eye at each tip.
	S.ch_t_shark = {
		label = "Rockhammer Shark",
		set = "crystal_hollow",
		tint = C3(100, 130, 170),
		scale = 1.15,
		head = CF(0, 0.96, 0.00),
		neck = CF(0, -0.50, 0.80),
		back = CF(0, 0.70, -0.60),
		build = function(c, p)
			c:box(V(1.30, 1.10, 2.00), CF(0, 0.00, -0.20), p.base)
			c:box(V(1.10, 0.30, 1.80), CF(0, -0.50, -0.16), p.pale)
			c:box(V(2.20, 0.50, 0.56), CF(0, 0.20, 1.06), p.dark, METAL)
			c:box(V(0.40, 0.60, 0.66), CF(-1.20, 0.20, 1.06), p.dark, METAL)
			c:cone(V(0.36, 0.50, 0.40), CF(1.34, 0.20, 1.06) * A(0, 0, -PI / 2), p.dark, METAL)
			c:eye(V(-1.20, 0.30, 1.42), 0.13)
			c:eye(V(0.90, 0.30, 1.37), 0.13)
			c:box(V(0.50, 0.10, 0.08), CF(0, -0.24, 0.81), INK)
			cheeks(c, -0.12, 0.82, 0.42)
			c:wedge(V(0.14, 0.70, 0.80), CF(0, 0.88, -0.30), p.dark)
			for _, s in ipairs(SIDES) do
				c:box(V(0.80, 0.10, 0.44), CF(0.94 * s, -0.36, 0.20) * A(0, 0.3 * s, -0.3 * s), p.dark)
				c:box(V(0.14, s > 0 and 0.90 or 0.56, 0.44), CF(0, 0.06 + 0.36 * s, -1.42) * A(-0.6 * s, 0, 0), p.dark)
			end
		end,
	}

	-- A round pika perched on a heap of broken scree (talus), a sprig of hay
	-- in its mouth for the winter pile.
	S.ch_t_pika = {
		label = "Talus Pika",
		set = "crystal_hollow",
		tint = C3(214, 180, 120),
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.10, 0.70),
		back = CF(0, 0.40, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.70, 1.40, 1.50),
				eyeSize = V(0.34, 0.40, 0.18), eyeSpread = 0.36, eyeY = 0.24,
				mouthSize = V(0.18, 0.10, 0.10), mouthY = -0.06,
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:round(V(0.50, 0.46, 0.22), CF(0.52 * s, 0.86, 0.00), p.dark)
				c:round(V(0.28, 0.26, 0.14), CF(0.52 * s, 0.86, 0.08), p.pale)
			end
			c:ball(V(0.16, 0.12, 0.10), CF(0, 0.06, 0.80), NOSE)
			c:rod(V(-0.10, -0.08, 0.86), V(0.62, 0.10, 1.00), 0.03, C3(160, 190, 80), nil, false)
			c:box(V(0.20, 0.10, 0.10), CF(0.62, 0.12, 1.00) * A(0, 0, 0.4), C3(250, 220, 90))
			for _, r in ipairs({
				{ 0, -0.90, 0.10, 1.30, 0.50, 1.20, 0.1 }, { -0.80, -0.94, 0.30, 0.70, 0.46, 0.70, 0.6 },
				{ 0.84, -0.96, -0.10, 0.66, 0.42, 0.66, -0.5 }, { 0.20, -0.92, 0.80, 0.50, 0.36, 0.50, 0.9 },
				{ -0.30, -0.92, -0.70, 0.56, 0.40, 0.56, 0.3 },
			}) do
				c:box(V(r[4], r[5], r[6]), CF(r[1], r[2], r[3]) * A(r[7] * 0.3, r[7], r[7] * 0.2), r[1] > 0 and p.deep or p.dark, SLATE)
			end
		end,
	}

	----------------------------------------------------------------------------
	-- LEGENDARY: more ornate.
	----------------------------------------------------------------------------

	-- An eel of smoky quartz threaded with golden rutile needles, swimming in
	-- an S, a fin ridge down its back.
	S.ch_t_eel = {
		label = "Rutilated Eel",
		set = "crystal_hollow",
		tint = C3(130, 100, 84),
		scale = 1.20,
		head = CF(0, 1.20, 0.90),
		neck = CF(0, 0.10, 1.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			local segs = {
				{ 0.00, 0.40, 0.90, 1.00, 0.96, 0.96 },
				{ 0.18, 0.04, 0.24, 0.86, 0.82, 0.80 },
				{ 0.40, -0.30, -0.36, 0.76, 0.70, 0.76 },
				{ 0.16, -0.54, -0.92, 0.66, 0.60, 0.70 },
				{ -0.30, -0.62, -1.36, 0.56, 0.50, 0.62 },
				{ -0.70, -0.56, -1.66, 0.46, 0.42, 0.52 },
			}
			for i, g in ipairs(segs) do
				c:box(V(g[4], g[5], g[6]), CF(g[1], g[2], g[3]) * A(0, i > 1 and (i - 2) * 0.3 or 0, 0), i % 2 == 0 and p.light or p.base, GLASS)
			end
			c:eyes(0.56, 1.42, 0.24, 0.13)
			c:box(V(0.40, 0.08, 0.08), CF(0, 0.16, 1.40), INK)
			cheeks(c, 0.30, 1.40, 0.38)
			for i = 1, 4 do
				local g = segs[i]
				c:box(V(0.08, 0.30, g[6] * 0.9), CF(g[1], g[2] + g[5] * 0.5 + 0.12, g[3]), p.pale, GLASS)
			end
			c:box(V(0.08, 0.60, 0.50), CF(-0.92, -0.50, -1.96) * A(0, 0.9, 0), p.pale, GLASS)
			for i, g in ipairs(segs) do
				if i > 1 then
					c:box(V(g[4] + 0.20, 0.04, 0.04), CF(g[1], g[2] + 0.06 * (i % 3 - 1), g[3]) * A(0.3 * i, 0, 0.5 - 0.2 * i), GOLD, NEON)
				end
			end
			for _, s in ipairs(SIDES) do
				c:box(V(0.40, 0.08, 0.30), CF(0.62 * s, 0.10, 0.80) * A(0, 0, -0.4 * s), p.pale, GLASS)
			end
		end,
	}

	-- A hoodoo: soft rock worn into a pillar under a hard cap stone that keeps
	-- the rain off. Its stripes are the layers it was laid down in.
	S.ch_t_hoodoo = {
		label = "Capstone Hoodoo",
		set = "crystal_hollow",
		tint = C3(226, 112, 64),
		scale = 1.24,
		head = CF(0, 1.86, 0.00),
		neck = CF(0, -0.20, 0.62),
		back = CF(0, 0.20, -0.62),
		build = function(c, p)
			c:box(V(1.90, 0.70, 1.70), CF(0, -0.96, 0) * A(0, 0.2, 0), p.dark, SLATE)
			c:box(V(1.30, 0.80, 1.20), CF(0, -0.30, 0), p.base, SLATE)
			c:box(V(1.10, 0.80, 1.04), CF(0.06, 0.46, 0), p.light, SLATE)
			c:box(V(0.80, 0.50, 0.80), CF(-0.04, 1.08, 0), p.base, SLATE)
			for _, b in ipairs({ { -0.30, 1.36, 1.26 }, { 0.80, 1.16, 1.10 }, { 1.08, 0.86, 0.86 } }) do
				c:box(V(b[2], 0.08, b[3]), CF(0.03, b[1], 0), p.pale, SLATE)
			end
			c:box(V(1.90, 0.36, 1.60), CF(0.10, 1.50, 0) * A(0.04, 0.3, -0.08), p.deep, SLATE)
			c:box(V(1.00, 0.24, 0.90), CF(-0.20, 1.76, -0.10) * A(0, -0.2, 0.06), p.dark, SLATE)
			c:eyes(0.56, 0.58, 0.26, 0.14)
			c:box(V(0.28, 0.08, 0.08), CF(0.06, 0.22, 0.54), INK)
			cheeks(c, 0.36, 0.54, 0.42)
			for _, s in ipairs(SIDES) do
				c:box(V(0.40, 0.30, 0.34), CF(0.80 * s, -0.20, 0.10) * A(0, 0, 0.5 * s), p.base, SLATE)
			end
			for _, r in ipairs({ { -0.80, 0.90, 0.22 }, { 0.90, 0.70, 0.18 }, { 0.40, 1.00, 0.16 } }) do
				c:box(V(r[3], r[3], r[3]), CF(r[1], -1.20, r[2]) * A(0.4, 0.7, 0.2), p.deep, SLATE)
			end
			c:ball(V(0.36, 0.30, 0.36), CF(-0.60, -0.50, 0.70), C3(140, 170, 110))
		end,
	}

	-- A starfish cut en cabochon from star ruby. A six-rayed star of light
	-- (asterism) shines out from behind it.
	S.ch_t_starfish = {
		label = "Asterism Starfish",
		set = "crystal_hollow",
		tint = C3(220, 40, 96),
		scale = 1.16,
		head = CF(0, 1.50, 0.00),
		neck = CF(0, -0.30, 0.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			local mid = CF(0, 0.16, 0)
			for k = 0, 4 do
				local arm = mid * A(0, 0, k * 2 * PI / 5)
				c:box(V(0.70, 0.80, 0.56), arm * CF(0, 0.66, 0), p.base)
				c:box(V(0.44, 0.56, 0.44), arm * CF(0, 1.24, 0), p.light)
				c:ball(V(0.14, 0.14, 0.14), arm * CF(0, 0.90, 0.30), p.pale)
			end
			c:cyl(V(0.64, 1.16, 1.16), mid * A(0, PI / 2, 0), p.dark)
			c:eyes(0.30, 0.40, 0.22, 0.13)
			c:box(V(0.24, 0.08, 0.06), CF(0, 0.00, 0.36), INK)
			cheeks(c, 0.10, 0.34, 0.36)
			for k = 0, 2 do
				c:box(V(0.08, 3.00, 0.06), mid * CF(0, 0, -0.34) * A(0, 0, k * PI / 3 + PI / 6), WHITE, NEON)
			end
		end,
	}

	-- A meerkat on sentry duty, standing tall on a blocky twinned feldspar
	-- crystal the way meerkats keep watch from a rock.
	S.ch_t_meerkat = {
		label = "Feldspar Meerkat",
		set = "crystal_hollow",
		tint = C3(70, 200, 170),
		scale = 1.18,
		head = CF(0, 1.30, 0.00),
		neck = CF(0, 0.30, 0.56),
		back = CF(0, 0.40, -0.56),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.30, 2.00, 1.10),
				eyeSize = V(0.30, 0.34, 0.16), eyeSpread = 0.30, eyeY = 0.52,
				snout = { w = 0.40, h = 0.30, d = 0.40, y = 0.20, color = p.pale },
				bib = { w = 0.80, h = 1.00, y = -0.36, color = p.pale },
				legSize = V(0.36, 0.30, 0.50), legX = 0.36, legY = -1.06, legZ = { 0.10 }, legColor = p.dark,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V(0.40, 0.40, 0.04), CF(0.30 * s, 0.52, 0.56), p.deep)
				c:round(V(0.26, 0.24, 0.16), CF(0.62 * s, 0.86, 0.10), p.dark)
				c:box(V(0.24, 0.40, 0.24), CF(0.30 * s, 0.00, 0.64) * A(0.5, 0, 0), p.dark)
			end
			c:rod(V(0, -0.80, -0.50), V(0, -1.16, -1.20), 0.10, p.dark, nil, false)
			c:box(V(1.50, 0.40, 1.30), CF(0, -1.40, 0) * A(0, 0.25, 0), p.light, GLASS)
			c:box(V(1.20, 0.30, 1.00), CF(0.20, -1.62, 0.10) * A(0, -0.35, 0), p.base, GLASS)
			c:wedge(V(0.80, 0.30, 0.40), CF(-0.50, -1.12, 0.40), p.pale, GLASS)
		end,
	}

	-- A little dinosaur with a sail of flat blue kyanite blades fanned along
	-- its spine, streaked like the real mineral.
	S.ch_t_spinosaur = {
		label = "Kyanite Spinosaur",
		set = "crystal_hollow",
		tint = C3(60, 120, 230),
		scale = 1.20,
		head = CF(0, 1.00, 0.40),
		neck = CF(0, -0.30, 1.00),
		back = CF(0, 1.60, -0.30),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(1.70, 1.60, 1.90),
				eyeSize = V(0.34, 0.40, 0.18), eyeSpread = 0.40, eyeY = 0.28,
				snout = { w = 0.80, h = 0.46, d = 0.56, y = -0.20, color = p.pale },
				legSize = V(0.46, 0.40, 0.50), legColor = p.dark, tail = false,
			})
			for i, b in ipairs({ { 0.40, 0.70 }, { 0.10, 1.00 }, { -0.22, 1.20 }, { -0.54, 1.00 }, { -0.84, 0.70 } }) do
				local cf = CF(0, 0.80 + b[2] * 0.5, b[1]) * A((i - 3) * -0.22, 0, 0)
				c:box(V(0.10, b[2], 0.34), cf, i % 2 == 0 and p.light or p.pale, GLASS)
				if i == 3 then
					c:box(V(0.12, b[2] * 0.8, 0.05), cf, p.deep)
				end
			end
			c:box(V(0.70, 0.60, 0.80), CF(0, -0.14, -1.20), p.base)
			c:box(V(0.44, 0.40, 0.70), CF(0, -0.10, -1.80) * A(0.2, 0, 0), p.dark)
			for _, s in ipairs(SIDES) do
				c:box(V(0.10, 0.08, 0.06), CF(0.20 * s, -0.04, 1.42), INK)
				c:cone(V(0.12, 0.18, 0.12), CF(0.62 * s, -1.06, 0.72) * A(1.6, 0, 0), WHITE)
			end
		end,
	}

	-- A silverback whose silver back is galena: bright lead-grey cubes
	-- stepped across its shoulders.
	S.ch_t_gorilla = {
		label = "Galena Gorilla",
		set = "crystal_hollow",
		tint = C3(120, 124, 140),
		scale = 1.10,
		head = CF(0, 1.14, 0.10),
		neck = CF(0, -0.20, 0.80),
		back = CF(0, 0.40, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(2.00, 1.80, 1.60),
				eyeSize = V(0.28, 0.32, 0.16), eyeSpread = 0.30, eyeY = 0.30,
				snout = { w = 0.80, h = 0.50, d = 0.30, y = -0.12, color = p.pale, nose = p.deep },
				brow = p.deep,
				legSize = V(0.50, 0.36, 0.56), legX = 0.50, legZ = { -0.30 }, legColor = p.dark,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V(0.50, 1.30, 0.50), CF(1.06 * s, -0.20, 0.36) * A(0.15, 0, 0.1 * s), p.dark)
				c:box(V(0.62, 0.36, 0.62), CF(1.12 * s, -0.92, 0.50), p.deep)
				c:round(V(0.30, 0.30, 0.16), CF(1.02 * s, 0.70, 0.10), p.dark)
			end
			for _, k in ipairs({ { 0, 0.92, -0.30, 0.56 }, { -0.44, 0.84, -0.50, 0.44 }, { 0.42, 0.80, -0.56, 0.40 }, { 0.10, 0.70, -0.80, 0.36 }, { -0.20, 1.20, -0.40, 0.30 } }) do
				c:box(V(k[4], k[4], k[4]), CF(k[1], k[2], k[3]) * A(0.1, 0.3, 0.05), p.pale, METAL)
			end
			c:box(V(0.90, 0.50, 0.10), CF(0, -0.50, 0.80), p.pale)
		end,
	}

	-- A caddisfly larva builds its case from whatever it finds. This one lives
	-- in a crystal pocket, so its case is studded with gems.
	S.ch_t_caddis = {
		label = "Gemcase Caddis",
		set = "crystal_hollow",
		tint = C3(150, 200, 80),
		scale = 1.12,
		head = CF(0, 1.06, -0.20),
		neck = CF(0, -0.30, 1.30),
		back = CF(0, 0.30, -1.10),
		build = function(c, p)
			c:cyl(V(2.10, 1.50, 1.50), CF(0, 0.10, -0.30) * A(0, PI / 2, 0), p.base, SLATE)
			c:cyl(V(0.20, 1.62, 1.62), CF(0, 0.10, 0.70) * A(0, PI / 2, 0), p.dark, SLATE)
			c:round(V(1.00, 0.90, 0.60), CF(0, 0.06, 0.96), p.light)
			c:eyes(0.20, 1.28, 0.22, 0.12)
			c:box(V(0.22, 0.07, 0.06), CF(0, -0.10, 1.26), INK)
			for _, s in ipairs(SIDES) do
				c:rod(V(0.14 * s, 0.40, 1.10), V(0.40 * s, 0.76, 1.40), 0.03, p.deep, nil, false)
				for _, z in ipairs({ 0.86, 1.04, 1.22 }) do
					c:rod(V(0.32 * s, -0.24, z), V(0.50 * s, -0.64, z + 0.10), 0.05, p.deep, nil, false)
				end
			end
			local gems = { RUBY, AQUA, CITRINE, LEAF, C3(170, 90, 230), WHITE }
			for i, g in ipairs({
				{ 0, 0.85, 0.20 }, { 0.70, 0.40, 0.00 }, { -0.70, 0.40, -0.30 }, { 0.40, 0.75, -0.80 }, { -0.42, 0.74, 0.40 },
				{ 0.75, -0.10, -0.70 }, { -0.76, -0.10, 0.20 }, { 0, 0.86, -1.10 }, { -0.50, 0.66, -1.00 },
			}) do
				c:box(V(0.24, 0.24, 0.24), CF(g[1], g[2] + 0.10, g[3]) * A(0.6, 0.78, 0.3 * i), gems[(i - 1) % #gems + 1], GLASS)
			end
		end,
	}

	-- "Cactus" amethyst: a big point whose sides are crusted with tiny
	-- crystals, grown here into a two-armed saguaro on its rock.
	S.ch_t_cactus = {
		label = "Cactus Amethyst",
		set = "crystal_hollow",
		tint = C3(160, 80, 220),
		scale = 1.24,
		head = CF(0, 1.70, 0.00),
		neck = CF(0, -0.40, 0.56),
		back = CF(0, 0.30, -0.56),
		build = function(c, p)
			c:box(V(1.00, 2.30, 1.00), CF(0, 0.10, 0), p.base, GLASS)
			c:cone(V(1.00, 0.60, 1.00), CF(0, 1.55, 0), p.light, GLASS)
			for _, s in ipairs(SIDES) do
				local up = s > 0 and 0.30 or -0.10
				c:box(V(0.60, 0.40, 0.50), CF(0.76 * s, up, 0), p.base, GLASS)
				c:box(V(0.44, 0.80, 0.44), CF(0.94 * s, up + 0.56, 0), p.base, GLASS)
				c:cone(V(0.44, 0.30, 0.44), CF(0.94 * s, up + 1.11, 0), p.light, GLASS)
			end
			c:eyes(0.52, 0.56, 0.24, 0.13)
			c:box(V(0.24, 0.08, 0.06), CF(0, 0.22, 0.52), INK)
			cheeks(c, 0.34, 0.52, 0.36)
			for _, d in ipairs({ { -0.52, -0.40, 0.30, 0, 0.9 }, { 0.52, -0.60, 0.20, 0, -0.9 }, { -0.30, 1.00, -0.52, -0.8, 0.3 }, { 1.18, 0.86, 0, 0, -0.9 }, { -1.16, 0.46, 0, 0, 0.9 } }) do
				c:cone(V(0.16, 0.26, 0.16), CF(d[1], d[2], d[3]) * A(d[4], 0, d[5]), p.pale, GLASS)
			end
			c:box(V(1.50, 0.40, 1.40), CF(0, -1.20, 0) * A(0, 0.3, 0), p.deep, SLATE)
		end,
	}

	-- A slice across watermelon tourmaline: a rounded triangle with a pink
	-- heart and a green skin, standing up like a slice of melon.
	S.ch_t_melon = {
		label = "Melon Tourmaline",
		set = "crystal_hollow",
		tint = C3(255, 110, 150),
		scale = 1.08,
		head = CF(0, 1.30, 0.00),
		neck = CF(0, -0.50, 0.50),
		back = CF(0, 0.00, -0.50),
		build = function(c, p)
			local rind = C3(70, 180, 90)
			c:prism(V(0.70, 2.30, 2.50), CF(0, 0.04, -0.06) * A(0, PI / 2, 0), rind, GLASS)
			c:prism(V(0.70, 2.00, 2.16), CF(0, -0.04, 0.04) * A(0, PI / 2, 0), p.pale, GLASS)
			c:prism(V(0.70, 1.76, 1.90), CF(0, -0.10, 0.10) * A(0, PI / 2, 0), p.base, GLASS)
			c:eyes(-0.20, 0.52, 0.28, 0.14)
			c:box(V(0.26, 0.08, 0.06), CF(0, -0.56, 0.48), INK)
			cheeks(c, -0.40, 0.47, 0.50)
			-- Dark inclusions like melon seeds.
			for _, d in ipairs({ { -0.16, 0.20 }, { 0.18, 0.12 }, { 0, 0.44 } }) do
				c:box(V(0.08, 0.14, 0.04), CF(d[1], d[2], 0.46), INK)
			end
			for _, s in ipairs(SIDES) do
				c:box(V(0.40, 0.24, 0.50), CF(0.50 * s, -1.24, 0.10), p.deep)
				c:box(V(0.06, 1.30, 0.66), CF(0.86 * s, -0.40, -0.06) * A(0, 0, 0.50 * s), rind)
			end
		end,
	}

	-- Painters once ground lapis lazuli into ultramarine. A stone mortar,
	-- flecked with pyrite, its bowl full of blue powder, pestle propped in it.
	S.ch_t_mortar = {
		label = "Lapis Mortar",
		set = "crystal_hollow",
		tint = C3(30, 50, 150),
		scale = 1.12,
		head = CF(0, 0.90, -0.40),
		neck = CF(0, -0.40, 1.00),
		back = CF(0, 0.00, -1.00),
		build = function(c, p)
			c:cyl(V(1.30, 2.00, 2.00), CF(0, -0.30, 0) * A(0, 0, PI / 2), p.base, SLATE)
			c:cyl(V(0.20, 2.16, 2.16), CF(0, 0.38, 0) * A(0, 0, PI / 2), p.dark, SLATE)
			c:cyl(V(0.10, 1.70, 1.70), CF(0, 0.46, 0) * A(0, 0, PI / 2), p.light)
			c:cyl(V(0.30, 2.10, 2.10), CF(0, -0.86, 0) * A(0, 0, PI / 2), p.dark, SLATE)
			c:eyes(-0.10, 1.04, 0.30, 0.14)
			c:box(V(0.30, 0.08, 0.08), CF(0, -0.46, 1.00), INK)
			cheeks(c, -0.30, 0.87, 0.50)
			c:rod(V(-0.20, 0.30, -0.10), V(0.70, 1.40, -0.30), 0.14, p.pale, SLATE)
			for _, f in ipairs({ { -0.60, 0.10 }, { 0.66, -0.20 }, { -0.40, -0.66 }, { 0.50, 0.20 } }) do
				c:box(V(0.12, 0.12, 0.04), CF(0, f[2], 0) * A(0, math.asin(f[1]), 0) * CF(0, 0, 1.00), GOLD, METAL)
			end
			c:ball(V(0.40, 0.36, 0.40), CF(-0.50, 0.64, 0.20), p.light)
			c:ball(V(0.28, 0.24, 0.28), CF(-0.70, 0.86, 0.40), p.pale)
		end,
	}

	-- A rock-shop hamster: cheeks stuffed with tumbled jasper, one more
	-- pebble held tight in its paws.
	S.ch_t_hamster = {
		label = "Jasper Hamster",
		set = "crystal_hollow",
		tint = C3(200, 70, 50),
		head = CF(0, 1.00, 0.10),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.90, 1.60, 1.70),
				eyeSize = V(0.30, 0.36, 0.16), eyeSpread = 0.34, eyeY = 0.30,
				mouthSize = V(0.14, 0.10, 0.10), mouthY = -0.02,
				bib = { w = 1.00, h = 0.70, y = -0.44, color = p.pale },
				legSize = V(0.40, 0.24, 0.40), legY = -0.80, legColor = p.pale, tail = false,
			})
			c:ball(V(0.16, 0.12, 0.10), CF(0, 0.10, 0.90), NOSE)
			for _, s in ipairs(SIDES) do
				c:round(V(0.66, 0.60, 0.50), CF(0.66 * s, -0.10, 0.62), p.pale)
				c:ball(V(0.20, 0.18, 0.16), CF(0.20 * s, -0.16, 0.92), s > 0 and C3(240, 170, 60) or C3(170, 60, 90), GLASS)
				c:round(V(0.44, 0.40, 0.18), CF(0.56 * s, 0.98, 0.10), p.dark)
				c:round(V(0.24, 0.20, 0.20), CF(0.26 * s, -0.42, 1.00), p.pale)
			end
			c:round(V(0.40, 0.32, 0.30), CF(0, -0.46, 1.00), p.deep, GLASS)
			spots(c, p.dark, { { -0.46, 0.84, 0.30 }, { 0.40, 0.84, -0.20 }, { -0.10, 0.84, -0.50 } }, V(0.22, 0.10, 0.22))
		end,
	}

	-- The collector's tumbler: a barrel that rolls rough stones for weeks until
	-- they come out glossy. It spills a few as it turns.
	S.ch_t_tumbler = {
		label = "Rock Tumbler",
		set = "crystal_hollow",
		tint = C3(60, 160, 200),
		scale = 1.10,
		head = CF(0, 1.06, 0.00),
		neck = CF(0, -0.50, 0.76),
		back = CF(0, 0.20, -0.76),
		build = function(c, p)
			c:cyl(V(1.90, 1.50, 1.50), CF(0, 0.10, 0), p.base)
			for _, x in ipairs({ -0.62, 0.62 }) do
				c:cyl(V(0.14, 1.60, 1.60), CF(x, 0.10, 0), SILVER, METAL)
			end
			c:cyl(V(0.16, 1.20, 1.20), CF(1.00, 0.10, 0), p.dark)
			c:cyl(V(0.10, 0.40, 0.40), CF(1.10, 0.10, 0), SILVER, METAL)
			c:eyes(0.24, 0.80, 0.24, 0.13)
			c:box(V(0.26, 0.08, 0.08), CF(0, -0.10, 0.76), INK)
			cheeks(c, 0.02, 0.74, 0.40)
			c:box(V(2.60, 0.24, 1.50), CF(0, -0.92, 0), p.deep)
			for _, z in ipairs({ 0.40, -0.40 }) do
				c:cyl(V(2.10, 0.24, 0.24), CF(0, -0.68, z), SILVER, METAL)
			end
			c:box(V(0.50, 0.50, 0.60), CF(-1.20, -0.56, -0.20), p.dark)
			c:box(V(0.06, 0.70, 0.10), CF(-1.00, -0.34, -0.40) * A(0, 0, 0.3), INK)
			for _, st in ipairs({ { -0.70, 0.90, 0.26, RUBY }, { 0.70, 1.00, 0.22, AQUA }, { 0.20, 1.06, 0.18, CITRINE } }) do
				c:ball(V(st[3], st[3] * 0.8, st[3]), CF(st[1], -0.94, st[2]), st[4], GLASS)
			end
			c:star(V(0.86, 0.80, 0.50), 0.30, WHITE)
		end,
	}

	----------------------------------------------------------------------------
	-- MYTHIC: spectacular, with glow.
	----------------------------------------------------------------------------

	-- A great beast of layered bedrock: strata bands round its flanks, a seam
	-- of glowing ore, and a ridge of crystals breaking through its back.
	S.ch_t_behemoth = {
		label = "Bedrock Behemoth",
		set = "crystal_hollow",
		tint = C3(150, 100, 70),
		scale = 1.14,
		head = CF(0, 1.30, 0.40),
		neck = CF(0, -0.30, 1.00),
		back = CF(0, 1.30, -0.40),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(2.10, 1.80, 2.00), bodyMat = SLATE,
				eyeSize = V(0.34, 0.40, 0.18), eyeSpread = 0.46, eyeY = 0.26,
				snout = { w = 1.00, h = 0.56, d = 0.40, y = -0.24, color = p.pale },
				brow = p.deep,
				legSize = V(0.62, 0.44, 0.62), legColor = p.deep,
				tailSize = V(0.30, 0.30, 0.50), tailColor = p.deep,
			})
			for i, y in ipairs({ -0.40, 0.04, 0.46 }) do
				c:box(V(2.26, 0.12, 1.70), CF(0, y, -0.20), i == 2 and p.pale or p.dark, SLATE)
			end
			c:box(V(2.24, 0.06, 1.20), CF(0, -0.18, -0.30), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V(0.14, 0.34, 0.14), CF(0.40 * s, -0.56, 1.22) * A(0.3, 0, 0.2 * s), WHITE)
			end
			point(c, V(0, 0.84, -0.10), 0.10, 0, 0.42, 0.56, p.light)
			point(c, V(-0.44, 0.80, -0.40), -0.20, 0.40, 0.32, 0.40, p.pale)
			point(c, V(0.44, 0.80, -0.50), -0.30, -0.40, 0.30, 0.36, p.pale)
			point(c, V(0, 0.76, -0.80), -0.50, 0, 0.28, 0.30, p.light)
			c:neon(V(0.20, 0.20, 0.20), CF(0, 0.98, 0.16), p.glow)
			c:light(p.glow, 1.4, 8)
		end,
	}

	-- A gentle one-eyed giant whose eye is a cat's-eye cabochon: a polished
	-- dome crossed by a single band of light (chatoyancy).
	S.ch_t_cyclops = {
		label = "Cabochon Cyclops",
		set = "crystal_hollow",
		tint = C3(200, 170, 40),
		scale = 1.16,
		head = CF(0, 1.66, 0.00),
		neck = CF(0, -0.10, 0.80),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			c:box(V(1.80, 1.90, 1.50), CF(0, 0.10, 0), p.base)
			c:box(V(1.20, 0.60, 0.10), CF(0, -0.50, 0.78), p.pale)
			c:round(V(1.00, 0.86, 0.30), CF(0, 0.52, 0.80), WHITE):SetAttribute("Eye", true)
			c:round(V(0.70, 0.62, 0.34), CF(0, 0.52, 0.86), C3(214, 160, 40), GLASS):SetAttribute("Eye", true)
			c:box(V(0.06, 0.56, 0.06), CF(0, 0.52, 1.03), WHITE, NEON):SetAttribute("Eye", true)
			c:ball(V(0.16, 0.16, 0.10), CF(0.18, 0.68, 1.02), WHITE):SetAttribute("Eye", true)
			c:box(V(0.50, 0.10, 0.08), CF(0, -0.02, 0.80), INK)
			cheeks(c, 0.10, 0.77, 0.56)
			for _, s in ipairs(SIDES) do
				c:box(V(0.44, 1.10, 0.50), CF(1.12 * s, -0.10, 0.10) * A(0, 0, 0.18 * s), p.dark)
				c:round(V(0.52, 0.46, 0.52), CF(1.24 * s, -0.70, 0.20), p.light)
				c:box(V(0.56, 0.40, 0.66), CF(0.48 * s, -1.02, 0.10), p.dark)
			end
			c:box(V(1.84, 0.20, 1.54), CF(0, 1.00, 0), p.deep, METAL)
			for _, x in ipairs({ -0.66, -0.22, 0.22, 0.66 }) do
				c:round(V(0.22, 0.22, 0.12), CF(x, 1.00, 0.80), p.glow, GLASS)
			end
			c:cone(V(0.40, 0.70, 0.40), CF(0, 1.40, 0), p.light, GLASS)
			for _, f in ipairs({ { -1.30, 1.10, -0.40 }, { 1.30, 1.20, -0.20 }, { 0, 1.60, -0.80 } }) do
				c:round(V(0.24, 0.20, 0.12), CF(f[1], f[2], f[3]), p.glow, NEON)
			end
			c:light(p.glow, 1.2, 7)
		end,
	}

	-- A brilliant-cut diamond floating in its own ring setting: a flat table
	-- on top, a pointed pavilion below, golden prongs for arms.
	S.ch_t_solitaire = {
		label = "Solitaire Diamond",
		set = "crystal_hollow",
		tint = C3(200, 240, 255),
		scale = 1.10,
		head = CF(0, 1.30, 0.00),
		neck = CF(0, -0.50, 0.70),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			local g = CF(0, 0.30, 0)
			for _, a in ipairs({ 0, PI / 4 }) do
				c:box(V(1.96, 0.16, 1.96), g * A(0, a, 0), p.pale, GLASS)
				c:cone(V(1.90, 1.40, 1.90), g * CF(0, -0.78, 0) * A(0, a, 0) * A(PI, 0, 0), p.base, GLASS)
				c:box(V(1.40, 0.36, 1.40), g * CF(0, 0.26, 0) * A(0, a, 0), p.light, GLASS)
				c:box(V(0.96, 0.06, 0.96), g * CF(0, 0.46, 0) * A(0, a, 0), p.pale, GLASS)
			end
			c:eyes(0.06, 0.97, 0.28, 0.13)
			c:box(V(0.22, 0.08, 0.06), CF(0, -0.24, 0.96), INK)
			cheeks(c, -0.10, 0.76, 0.46)
			for _, s in ipairs(SIDES) do
				c:rod(V(0.90 * s, 0.20, 0.30), V(1.20 * s, 0.60, 0.20), 0.07, GOLD, METAL)
				c:rod(V(0.90 * s, 0.20, -0.40), V(1.10 * s, 0.66, -0.60), 0.07, GOLD, METAL, false)
			end
			c:star(V(-0.70, 1.10, 0.30), 0.40, WHITE)
			c:star(V(0.80, -0.40, 0.50), 0.30, WHITE)
			for _, o in ipairs({ { -1.30, -0.20, -0.30, RUBY }, { 1.30, 0.70, -0.40, AQUA }, { 0.10, -1.20, -0.60, p.glow } }) do
				c:box(V(0.22, 0.22, 0.22), CF(o[1], o[2], o[3]) * A(0.6, 0.78, 0), o[4], NEON)
			end
			c:light(p.glow, 1.4, 8)
		end,
	}

	-- A tall ocean sunfish of labradorite: grey-blue until it turns, then a
	-- flash of blue, green and gold (schiller) runs over its sides.
	S.ch_t_sunfish = {
		label = "Schiller Sunfish",
		set = "crystal_hollow",
		tint = C3(40, 110, 140),
		scale = 1.18,
		head = CF(0, 1.00, 0.30),
		neck = CF(0, -0.40, 0.90),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			c:box(V(1.00, 1.70, 1.80), CF(0, 0.06, 0), p.base)
			c:box(V(1.06, 1.30, 1.30), CF(0, 0.06, -0.10), p.dark)
			c:box(V(0.90, 0.70, 0.40), CF(0, -0.10, 0.94), p.pale)
			c:eyes(0.40, 0.96, 0.26, 0.13)
			c:box(V(0.20, 0.12, 0.08), CF(0, -0.22, 1.16), INK)
			cheeks(c, 0.05, 1.15, 0.30)
			c:box(V(0.16, 0.80, 0.60), CF(0, 1.20, -0.30) * A(-0.25, 0, 0), p.light)
			c:box(V(0.16, 0.80, 0.60), CF(0, -1.08, -0.30) * A(0.25, 0, 0), p.light)
			for i = -1, 1 do
				c:box(V(0.14, 0.40, 0.34), CF(0, 0.06 + i * 0.44, -1.02) * A(i * 0.4, 0, 0), p.pale)
			end
			for _, s in ipairs(SIDES) do
				c:box(V(0.10, 0.30, 0.40), CF(0.56 * s, -0.10, 0.40) * A(0, 0.4 * s, 0), p.light)
				for i, col in ipairs({ C3(60, 140, 255), C3(60, 230, 190), C3(250, 200, 70) }) do
					c:box(V(0.04, 0.12, 1.20), CF(0.55 * s, 0.50 - i * 0.28, -0.10) * A(0.35, 0, 0), col, NEON)
				end
			end
			for _, b in ipairs({ { 0.30, 1.30, 0.80, 0.18 }, { 0.46, 1.60, 0.90, 0.12 }, { -0.36, 1.50, 0.70, 0.10 } }) do
				c:ball(V(b[4], b[4], b[4]), CF(b[1], b[2], b[3]), p.glow, NEON)
			end
			c:light(p.glow, 1.0, 6)
		end,
	}

	----------------------------------------------------------------------------
	-- DIVINE: spectacular, with glow, crowns and auras.
	----------------------------------------------------------------------------

	-- An amethyst "cathedral": a tall geode shell open at the front, its arch
	-- lined with purple points, three spires on the roof and a light in its
	-- heart.
	S.ch_t_cathedral = {
		label = "Amethyst Cathedral",
		set = "crystal_hollow",
		tint = C3(140, 60, 220),
		scale = 1.35,
		head = CF(0, 1.90, 0.00),
		neck = CF(0, -0.50, 0.80),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			c:box(V(1.80, 1.70, 1.30), CF(0, -0.25, -0.10), p.deep, SLATE)
			c:cyl(V(1.30, 1.80, 1.80), CF(0, 0.60, -0.10) * A(0, PI / 2, 0), p.deep, SLATE)
			c:box(V(1.50, 1.50, 0.20), CF(0, -0.30, 0.58), p.base, GLASS)
			c:cyl(V(0.20, 1.50, 1.50), CF(0, 0.45, 0.58) * A(0, PI / 2, 0), p.base, GLASS)
			c:box(V(1.00, 1.20, 0.10), CF(0, -0.25, 0.70), p.light, GLASS)
			for _, t in ipairs({ { -0.66, -0.80 }, { 0.66, -0.80 }, { -0.66, 0.10 }, { 0.66, 0.10 }, { -0.46, 0.90 }, { 0.46, 0.90 } }) do
				local a = math.atan2(t[2], t[1])
				c:cone(V(0.20, 0.34, 0.12), CF(t[1], t[2], 0.74) * A(0, 0, a + PI / 2), p.pale, GLASS)
			end
			c:eyes(0.22, 0.80, 0.26, 0.14)
			c:box(V(0.26, 0.08, 0.06), CF(0, -0.12, 0.76), INK)
			cheeks(c, 0.06, 0.76, 0.44)
			c:neon(V(0.30, 0.30, 0.14), CF(0, -0.56, 0.76), p.glow)
			point(c, V(0, 1.36, -0.10), 0, 0, 0.44, 0.44, p.light)
			point(c, V(-0.56, 1.10, -0.10), 0, 0.30, 0.32, 0.46, p.base)
			point(c, V(0.56, 1.10, -0.10), 0, -0.30, 0.32, 0.46, p.base)
			c:box(V(2.10, 0.30, 1.60), CF(0, -1.24, 0) * A(0, 0.2, 0), p.dark, SLATE)
			c:star(V(0.96, 1.40, 0.40), 0.40, WHITE)
			c:light(p.glow, 1.6, 9)
		end,
	}

	-- From Chilean miners' tales: a bird that eats gold and silver ore, so its
	-- feathers shine like metal and its eyes give off light. Follow it and it
	-- leads you to a vein.
	S.ch_t_alicanto = {
		label = "Alicanto",
		set = "crystal_hollow",
		tint = C3(250, 200, 60),
		scale = 1.24,
		head = CF(0, 1.30, 0.00),
		neck = CF(0, -0.10, 0.70),
		back = CF(0, 0.30, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V(1.70, 1.80, 1.60), bodyMat = METAL,
				eyeSize = V(0.32, 0.38, 0.18), eyeSpread = 0.36, eyeY = 0.34,
				mouth = false,
				legSize = V(0.18, 0.40, 0.18), legX = 0.30, legY = -0.96, legZ = { 0.10 }, legColor = p.deep,
				tail = false,
			})
			c:cone(V(0.28, 0.40, 0.22), CF(0, 0.06, 0.94) * A(PI / 2, 0, 0), p.deep, METAL)
			c:box(V(0.20, 0.18, 0.18), CF(0.10, -0.10, 1.16) * A(0.4, 0.6, 0.2), SILVER, METAL)
			for _, s in ipairs(SIDES) do
				c:neon(V(0.10, 0.10, 0.06), CF(0.36 * s, 0.30, 0.94), p.glow)
				for i = 1, 3 do
					c:box(V(0.14, 1.10 - i * 0.16, 0.36), CF((0.90 + i * 0.12) * s, 0.30 + i * 0.12, 0.20 - i * 0.30) * A(-0.20, 0, -(0.35 + i * 0.18) * s), i == 2 and p.light or p.pale, METAL)
				end
			end
			for i = -1, 1 do
				local cf = CF(i * 0.20, 1.10, 0.20 - math.abs(i) * 0.12) * A(-0.3, 0, -i * 0.35)
				c:box(V(0.10, 0.50, 0.18), cf, p.light, METAL)
				c:neon(V(0.14, 0.14, 0.14), cf * CF(0, 0.30, 0), p.glow)
			end
			for i = -1, 1 do
				c:box(V(0.24, 0.12, 1.10), CF(i * 0.24, -0.40, -1.20) * A(0.40, i * 0.25, 0), i == 0 and p.light or p.base, METAL)
			end
			c:sparkle(p.glow, 4, 0.6, 0.2)
			c:light(p.glow, 1.4, 8)
		end,
	}

	-- Bismuth grows as hopper crystals: square frames stepping back, each a
	-- little turned, with a rainbow oxide skin. The face looks out from the
	-- innermost frame. It floats.
	S.ch_t_bismuth = {
		label = "Bismuth Spiral",
		set = "crystal_hollow",
		tint = C3(220, 90, 200),
		scale = 1.15,
		head = CF(0, 1.50, 0.00),
		neck = CF(0, -0.60, 0.80),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			c:box(V(1.10, 1.10, 1.30), CF(0, 0.10, -0.20), p.base, METAL)
			local skins = { C3(250, 200, 60), C3(80, 200, 255), C3(240, 80, 200) }
			for i, f in ipairs({ { 1.50, 0.35, 0.10 }, { 2.04, 0.10, 0.22 }, { 2.56, -0.15, 0.34 } }) do
				local cf = CF(0, 0.10, f[2]) * A(0, 0, f[3])
				local s, t = f[1], 0.20
				local col = i == 1 and p.light or (i == 2 and p.base or p.dark)
				c:box(V(s, t, 0.30), cf * CF(0, (s - t) / 2, 0), col, METAL)
				c:box(V(s, t, 0.30), cf * CF(0, -(s - t) / 2, 0), col, METAL)
				c:box(V(t, s - 2 * t, 0.30), cf * CF((s - t) / 2, 0, 0), col, METAL)
				c:box(V(t, s - 2 * t, 0.30), cf * CF(-(s - t) / 2, 0, 0), col, METAL)
				c:box(V(s - 0.10, 0.04, 0.32), cf * CF(0, s / 2 + 0.01, 0), skins[i], NEON)
			end
			c:eyes(0.26, 0.51, 0.22, 0.13)
			c:box(V(0.22, 0.08, 0.06), CF(0, -0.06, 0.48), INK)
			cheeks(c, 0.08, 0.47, 0.40)
			c:box(V(0.70, 0.20, 0.70), CF(0, 0.74, -0.20) * A(0, 0.3, 0), p.light, METAL)
			c:box(V(0.40, 0.20, 0.40), CF(0, 0.92, -0.20) * A(0, 0.6, 0), p.glow, NEON)
			for _, d in ipairs({ { -1.50, 1.10, -0.40 }, { 1.50, -0.60, -0.30 }, { 1.30, 1.30, -0.60 } }) do
				c:box(V(0.24, 0.24, 0.24), CF(d[1], d[2], d[3]) * A(0.3, 0.6, 0.2), p.pale, METAL)
			end
			c:light(p.glow, 1.2, 7)
		end,
	}

	-- In some caves the stalactites ring like bells when tapped, and people
	-- have built organs that play them. This organ sings back.
	S.ch_t_organ = {
		label = "Stalacpipe Organ",
		set = "crystal_hollow",
		tint = C3(255, 190, 120),
		scale = 1.16,
		head = CF(0, 1.86, 0.00),
		neck = CF(0, -0.70, 0.80),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:box(V(2.40, 0.40, 1.30), CF(0, 1.30, -0.10) * A(0, 0, 0.03), p.dark, SLATE)
			c:box(V(1.40, 0.30, 0.90), CF(-0.30, 1.56, -0.20) * A(0, 0.2, 0), p.deep, SLATE)
			for i = 1, 7 do
				local h = 1.10 - math.abs(i - 4) * 0.16
				c:cone(V(0.26, h, 0.26), CF(-1.02 + (i - 1) * 0.34, 1.10 - h / 2, 0.20 - (i % 2) * 0.30) * A(PI, 0, 0), i % 2 == 0 and p.light or p.pale, GLASS)
			end
			c:box(V(1.90, 1.00, 1.20), CF(0, -0.56, 0), p.base, WOOD)
			c:eyes(-0.34, 0.66, 0.30, 0.14)
			c:box(V(0.28, 0.08, 0.06), CF(0, -0.68, 0.62), INK)
			cheeks(c, -0.52, 0.62, 0.50)
			c:box(V(1.70, 0.12, 0.40), CF(0, -0.10, 0.70) * A(0.2, 0, 0), WHITE)
			for _, x in ipairs({ -0.50, -0.10, 0.30, 0.66 }) do
				c:box(V(0.10, 0.06, 0.22), CF(x, -0.03, 0.66) * A(0.2, 0, 0), INK)
			end
			for _, s in ipairs(SIDES) do
				c:box(V(0.40, 0.20, 0.50), CF(0.66 * s, -1.16, 0.10), p.deep, WOOD)
			end
			c:rod(V(1.00, -0.10, 0.20), V(1.40, 0.60, 0.40), 0.05, C3(150, 110, 70), WOOD, false)
			c:ball(V(0.24, 0.24, 0.24), CF(1.40, 0.60, 0.40), p.pale)
			for _, n in ipairs({ { -1.30, 0.50, 0.50 }, { 1.20, 1.00, 0.60 } }) do
				c:neon(V(0.16, 0.16, 0.16), CF(n[1], n[2], n[3]), p.glow)
				c:box(V(0.04, 0.30, 0.04), CF(n[1] + 0.07, n[2] + 0.14, n[3]), p.glow, NEON)
			end
			c:light(p.glow, 1.2, 8)
		end,
	}

	-- A mountain nymph: a gown of rock strata, a snowy crown of hair, a halo
	-- of crystals behind, and pebbles floating at her hem.
	S.ch_t_oread = {
		label = "Summit Oread",
		set = "crystal_hollow",
		tint = C3(150, 210, 255),
		scale = 1.18,
		head = CF(0, 1.66, 0.00),
		neck = CF(0, 0.20, 0.56),
		back = CF(0, 0.60, -0.56),
		build = function(c, p)
			c:cone(V(1.90, 1.60, 1.70), CF(0, -0.56, 0), p.dark, SLATE)
			for i, y in ipairs({ -1.10, -0.70 }) do
				local w = 1.90 * (1 - (y + 1.36) / 1.60) + 0.10
				c:box(V(w, 0.10, w * 0.90), CF(0, y, 0), i == 1 and p.pale or p.light, SLATE)
			end
			c:box(V(1.20, 1.10, 1.00), CF(0, 0.66, 0), p.base)
			c:eyes(0.74, 0.56, 0.26, 0.14)
			c:box(V(0.22, 0.08, 0.06), CF(0, 0.42, 0.52), INK)
			cheeks(c, 0.56, 0.52, 0.42)
			c:box(V(1.30, 0.30, 1.10), CF(0, 1.30, -0.04), p.pale)
			for _, s in ipairs(SIDES) do
				c:box(V(0.24, 0.90, 0.80), CF(0.66 * s, 0.86, -0.10), p.pale)
				c:rod(V(0.60 * s, 0.40, 0.10), V(0.96 * s, -0.10, 0.40), 0.10, p.base)
			end
			for k = 0, 6 do
				local a = (k - 3) * 0.42
				c:box(V(0.18, 0.40, 0.18), CF(0, 1.10, -0.70) * A(0, 0, a) * CF(0, 0.80, 0) * A(0, PI / 4, 0), k % 2 == 0 and p.light or p.glow, k % 2 == 0 and GLASS or NEON)
			end
			for _, r in ipairs({ { -1.16, -1.10, 0.40 }, { 1.20, -0.90, -0.20 }, { 0.30, -1.50, 0.80 } }) do
				c:box(V(0.24, 0.20, 0.24), CF(r[1], r[2], r[3]) * A(0.4, 0.7, 0.2), p.deep, SLATE)
			end
			c:light(p.glow, 1.2, 7)
		end,
	}

	-- A trapiche emerald slice: a green hexagon split into six sectors by dark
	-- spokes, a clear core in the middle. Six little emeralds orbit it.
	S.ch_t_trapiche = {
		label = "Trapiche Mandala",
		set = "crystal_hollow",
		tint = C3(40, 200, 110),
		scale = 1.20,
		head = CF(0, 1.40, 0.00),
		neck = CF(0, -0.70, 0.40),
		back = CF(0, 0.10, -0.40),
		build = function(c, p)
			local mid = CF(0, 0.10, 0)
			local face = mid * A(PI / 2, 0, 0)
			hex(c, face, 1.24, 0.50, p.base, GLASS)
			hex(c, face * CF(0, 0.05, 0), 0.56, 0.50, p.light, GLASS)
			for k = 0, 5 do
				c:box(V(0.10, 0.80, 0.06), mid * A(0, 0, k * PI / 3 + PI / 6) * CF(0, 0.84, 0.25), p.deep)
				c:box(V(0.24, 0.24, 0.24), mid * A(0, 0, k * PI / 3) * CF(0, 1.46, -0.10) * A(0.6, 0.78, 0), p.pale, GLASS)
			end
			c:eyes(0.18, 0.36, 0.18, 0.12)
			c:box(V(0.18, 0.07, 0.06), CF(0, -0.06, 0.33), INK)
			cheeks(c, 0.04, 0.32, 0.30)
			c:cyl(V(0.06, 2.80, 2.80), mid * CF(0, 0, -0.32) * A(0, PI / 2, 0), p.glow, NEON)
			c:light(p.glow, 1.4, 8)
		end,
	}

	-- White chalk cliffs are made of coccoliths: tiny plankton that wear an
	-- armour of round chalk plates. This one is big enough to cuddle.
	S.ch_t_coccolith = {
		label = "Chalk Coccolith",
		set = "crystal_hollow",
		tint = C3(140, 220, 230),
		scale = 1.16,
		head = CF(0, 1.30, 0.00),
		neck = CF(0, -0.50, 0.80),
		back = CF(0, 0.20, -0.90),
		build = function(c, p)
			c:ball(V(1.70, 1.70, 1.70), CF(0, 0.10, 0), p.base)
			for i, d in ipairs({
				{ 0, 0 }, { 0.70, 0.80 }, { -0.70, 0.80 }, { 1.57, 0.70 }, { -1.57, 0.70 }, { 1.57, 1.50 },
				{ -1.57, 1.50 }, { 2.40, 0.90 }, { -2.40, 0.90 }, { PI, 0.60 }, { PI, 1.40 }, { 2.20, 2.20 }, { -2.20, 2.20 },
			}) do
				local cf = CF(0, 0.10, 0) * A(0, d[1], 0) * A(d[2], 0, 0) * CF(0, 0.86, 0)
				c:cyl(V(0.10, 0.72, 0.72), cf * A(0, 0, PI / 2), i % 3 == 0 and p.light or p.pale)
				if i % 2 == 1 then
					c:cyl(V(0.12, 0.28, 0.28), cf * A(0, 0, PI / 2), p.deep)
				end
			end
			c:eyes(0.22, 0.84, 0.28, 0.14)
			c:box(V(0.24, 0.08, 0.06), CF(0, -0.10, 0.84), INK)
			cheeks(c, 0.02, 0.73, 0.46)
			c:neon(V(0.24, 0.24, 0.24), CF(0, 1.06, 0), p.glow)
			for _, b in ipairs({ { 0.90, 1.10, 0.50, 0.20 }, { 1.10, 1.44, 0.30, 0.12 }, { -1.00, 1.30, 0.20, 0.14 } }) do
				c:ball(V(b[4], b[4], b[4]), CF(b[1], b[2], b[3]), p.pale, GLASS)
			end
			c:light(p.glow, 1.2, 7)
		end,
	}

	-- The carbuncle of old tales: a small shy beast with a glowing red gem set
	-- in its forehead. Lucky miners glimpse it in the dark.
	S.ch_t_carbuncle = {
		label = "Ruby Carbuncle",
		set = "crystal_hollow",
		tint = C3(250, 150, 60),
		scale = 1.14,
		head = CF(0, 1.30, 0.00),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.30, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(1.70, 1.60, 1.80),
				eyeSize = V(0.36, 0.44, 0.18), eyeSpread = 0.40, eyeY = 0.14,
				snout = { w = 0.50, h = 0.34, d = 0.36, y = -0.30, color = p.pale },
				legSize = V(0.40, 0.36, 0.44), legColor = p.dark, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(V(0.36, 0.80, 0.24), CF(0.46 * s, 1.24, -0.04) * A(0, 0, -0.28 * s), p.base)
				c:cone(V(0.18, 0.50, 0.12), CF(0.45 * s, 1.16, 0.06) * A(0, 0, -0.28 * s), p.pale)
			end
			c:cyl(V(0.10, 0.54, 0.54), CF(0, 0.64, 0.92) * A(0, PI / 2, 0), GOLD, METAL)
			c:round(V(0.42, 0.40, 0.24), CF(0, 0.64, 0.98), RUBY, GLASS)
			c:neon(V(0.16, 0.16, 0.10), CF(0, 0.66, 1.08), C3(255, 120, 140))
			c:box(V(1.20, 0.30, 0.40), CF(0, -0.62, 0.80), p.pale)
			c:box(V(0.50, 0.50, 0.70), CF(0, 0.00, -1.16) * A(0.5, 0, 0), p.base)
			c:box(V(0.60, 0.70, 0.60), CF(0, 0.54, -1.42) * A(0.9, 0, 0), p.light)
			c:box(V(0.40, 0.40, 0.40), CF(0, 1.02, -1.30) * A(0.3, 0.78, 0), RUBY, GLASS)
			for _, r in ipairs({ { -1.20, 0.90, 0.30 }, { 1.20, 1.10, -0.20 }, { 0.90, -0.40, 0.90 } }) do
				c:box(V(0.18, 0.18, 0.18), CF(r[1], r[2], r[3]) * A(0.6, 0.78, 0), RUBY, NEON)
			end
			c:light(RUBY, 1.4, 8)
		end,
	}

	-- A tarsier, all eyes, hugging a tall tanzanite crystal that glows at its
	-- tip. Tanzanite turns from blue to violet as you turn it.
	S.ch_t_tarsier = {
		label = "Tanzanite Tarsier",
		set = "crystal_hollow",
		tint = C3(90, 70, 230),
		scale = 1.25,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 0.70),
		back = CF(0, 0.30, -0.70),
		build = function(c, p)
			point(c, V(0, -1.40, -0.80), 0, 0, 0.56, 2.50, p.light)
			block(c, p, {
				shape = "round", bodySize = V(1.50, 1.40, 1.20),
				eyeSize = V(0.62, 0.70, 0.24), eyeSpread = 0.36, eyeY = 0.18,
				mouthSize = V(0.12, 0.06, 0.08), mouthY = -0.34,
				legs = false, tail = false,
			})
			c:ball(V(0.12, 0.08, 0.08), CF(0, -0.20, 0.64), NOSE)
			for _, s in ipairs(SIDES) do
				c:round(V(0.48, 0.52, 0.12), CF(0.62 * s, 0.86, -0.10), p.dark)
				c:round(V(0.28, 0.32, 0.08), CF(0.62 * s, 0.86, -0.02), BLUSH)
				c:rod(V(0.66 * s, 0.10, -0.10), V(0.40 * s, 0.40, -0.66), 0.10, p.base, nil, false)
				c:round(V(0.24, 0.18, 0.24), CF(0.36 * s, 0.42, -0.66), p.pale)
				c:rod(V(0.50 * s, -0.50, -0.10), V(0.38 * s, -0.70, -0.66), 0.12, p.base, nil, false)
				c:round(V(0.30, 0.20, 0.30), CF(0.34 * s, -0.72, -0.62), p.pale)
			end
			c:rod(V(0, -0.50, -0.60), V(0.10, -1.40, -0.40), 0.05, p.base, nil, false)
			c:round(V(0.20, 0.30, 0.20), CF(0.10, -1.50, -0.40), p.pale)
			c:neon(V(0.24, 0.24, 0.24), CF(0, 1.76, -0.80), p.glow)
			c:star(V(-0.90, 1.20, -0.40), 0.30, WHITE)
			c:star(V(0.96, -0.40, 0.20), 0.26, WHITE)
			c:light(p.glow, 1.2, 7)
		end,
	}

	-- Muscovite mica splits into sheets thinner than paper. This colugo (a
	-- gliding "flying lemur") glides on wings of stacked mica sheets that
	-- glint at their edges, shedding glowing flakes.
	S.ch_t_colugo = {
		label = "Muscovite Colugo",
		set = "crystal_hollow",
		tint = C3(180, 150, 250),
		scale = 1.30,
		head = CF(0, 1.10, 0.00),
		neck = CF(0, -0.36, 0.70),
		back = CF(0, 0.30, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.40, 1.30, 1.40),
				eyeSize = V(0.46, 0.54, 0.22), eyeSpread = 0.34, eyeY = 0.12,
				mouthSize = V(0.16, 0.08, 0.10), mouthY = -0.28,
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:round(V(0.26, 0.24, 0.14), CF(0.46 * s, 0.70, 0.00), p.dark)
				-- The wing: a book of mica sheets with a glowing edge, and a paw at
				-- each corner.
				local wing = CF(1.10 * s, 0.00, -0.05) * A(0, 0, 0.15 * s)
				c:box(V(1.20, 0.06, 1.30), wing, p.base, GLASS)
				c:box(V(1.00, 0.05, 1.10), wing * CF(-0.04 * s, 0.05, 0), p.light, GLASS)
				c:box(V(0.06, 0.08, 1.24), wing * CF(0.60 * s, 0.02, 0), p.glow, NEON)
				for _, z in ipairs({ 0.62, -0.62 }) do
					c:round(V(0.22, 0.18, 0.22), wing * CF(0.56 * s, 0, z), p.dark)
				end
			end
			c:box(V(0.90, 0.06, 0.60), CF(0, -0.30, -0.95), p.base, GLASS)
			c:rod(V(0, -0.30, -1.20), V(0, -0.50, -1.70), 0.08, p.dark, nil, false)
			for _, f in ipairs({ { -0.90, 0.90, 0.30 }, { 0.95, 0.85, -0.20 }, { 0, 1.10, -0.60 } }) do
				c:box(V(0.26, 0.03, 0.26), CF(f[1], f[2], f[3]) * A(0.5, 0.6, 0.3), p.glow, NEON)
			end
			c:sparkle(p.glow, 4, 0.6, 0.2)
			c:light(p.glow, 1.2, 7)
		end,
	}

	-- Larimar is a sea-blue stone found by only one Caribbean sea, where
	-- manatees graze. Its white ripples look like sunlight on water.
	S.ch_t_manatee = {
		label = "Larimar Manatee",
		set = "crystal_hollow",
		tint = C3(80, 180, 230),
		scale = 1.20,
		head = CF(0, 1.00, 0.40),
		neck = CF(0, -0.40, 1.10),
		back = CF(0, 0.40, -0.60),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.90, 1.60, 2.20),
				eyeSize = V(0.24, 0.26, 0.14), eyeSpread = 0.44, eyeY = 0.30,
				snout = { w = 1.10, h = 0.60, d = 0.40, y = -0.14, color = p.pale, nose = p.deep },
				legs = false, tail = false,
			})
			for i, r in ipairs({ { 0.86, 0.20, 1.20 }, { 0.86, -0.40, 1.00 }, { 0.84, 0.60, 0.80 } }) do
				c:box(V(r[3], 0.06, 0.16), CF(0, r[1], r[2]) * A(0, 0.3 * i, 0), WHITE)
			end
			c:cyl(V(0.16, 1.10, 1.10), CF(0, -0.30, -1.45) * A(0, 0, PI / 2), p.dark)
			c:box(V(0.60, 0.40, 0.50), CF(0, -0.24, -1.10), p.base)
			for _, s in ipairs(SIDES) do
				c:box(V(0.60, 0.14, 0.40), CF(1.04 * s, -0.40, 0.50) * A(0.2, 0.3 * s, -0.4 * s), p.dark)
			end
			spots(c, p.deep, { { -0.26, -0.06, 1.41 }, { 0.26, -0.06, 1.41 }, { 0, -0.20, 1.41 } }, V(0.06, 0.06, 0.04))
			for k = -2, 2 do
				c:ball(V(0.20, 0.20, 0.20), CF(k * 0.28, 0.92, 0.20), k == 0 and p.glow or p.pale, k == 0 and NEON or GLASS)
			end
			for _, b in ipairs({ { 0.70, 1.40, 0.70, 0.16 }, { 0.90, 1.70, 0.60, 0.10 } }) do
				c:ball(V(b[4], b[4], b[4]), CF(b[1], b[2], b[3]), p.pale, GLASS)
			end
			c:light(p.glow, 1.0, 7)
		end,
	}

	-- Wulfenite grows as thin square orange plates, so thin they glow when the
	-- light is behind them. Four of them make the sails of a little mill.
	S.ch_t_windmill = {
		label = "Wulfenite Windmill",
		set = "crystal_hollow",
		tint = C3(255, 140, 20),
		scale = 1.25,
		head = CF(0, 1.60, -0.30),
		neck = CF(0, -0.70, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:box(V(1.40, 1.90, 1.30), CF(0, -0.25, 0), p.dark, SLATE)
			c:prism(V(1.30, 0.70, 1.50), CF(0, 1.05, 0) * A(0, PI / 2, 0), p.deep, SLATE)
			c:eyes(-0.25, 0.71, 0.30, 0.14)
			c:box(V(0.26, 0.08, 0.06), CF(0, -0.55, 0.67), INK)
			cheeks(c, -0.42, 0.67, 0.46)
			c:box(V(0.40, 0.40, 0.06), CF(0, -0.98, 0.66), p.deep, WOOD)
			c:cyl(V(0.30, 0.40, 0.40), CF(0, 1.00, 0.74) * A(0, PI / 2, 0), SILVER, METAL)
			for k = 0, 3 do
				local arm = CF(0, 1.00, 0.86) * A(0, 0, k * PI / 2 + PI / 4)
				c:box(V(0.08, 0.90, 0.06), arm * CF(0, 0.46, 0), p.deep, WOOD)
				c:box(V(0.50, 0.60, 0.04), arm * CF(0.25, 0.60, 0), k % 2 == 0 and p.light or p.base, GLASS)
				c:box(V(0.40, 0.50, 0.05), arm * CF(0.25, 0.60, 0), p.glow, NEON)
			end
			c:box(V(1.80, 0.24, 1.60), CF(0, -1.30, 0), p.deep, SLATE)
			c:light(p.glow, 1.2, 7)
		end,
	}

	----------------------------------------------------------------------------
	-- EXOTIC: the showpieces.
	----------------------------------------------------------------------------

	-- What every crystal is inside: atoms in a repeating grid. A ball-and-stick
	-- unit cell, with the friendly atom at its centre.
	S.ch_t_lattice = {
		label = "Crystal Lattice",
		set = "crystal_hollow",
		tint = C3(255, 100, 220),
		scale = 1.14,
		head = CF(0, 1.60, 0.00),
		neck = CF(0, -0.60, 1.20),
		back = CF(0, 0.30, -1.20),
		build = function(c, p)
			local R, y0 = 1.06, 0.10
			c:ball(V(1.20, 1.20, 1.20), CF(0, y0, 0), p.base)
			c:eyes(y0 + 0.14, 0.60, 0.22, 0.13)
			c:box(V(0.20, 0.07, 0.06), CF(0, y0 - 0.16, 0.58), INK)
			cheeks(c, y0 - 0.04, 0.50, 0.36)
			local corners = {}
			for _, x in ipairs(SIDES) do
				for _, y in ipairs(SIDES) do
					for _, z in ipairs(SIDES) do
						local v = V(x * R, y0 + y * R, z * R)
						table.insert(corners, v)
						local lit = x * y * z > 0
						c:ball(V(0.42, 0.42, 0.42), CF(v), lit and p.glow or p.light, lit and NEON or GLASS)
					end
				end
			end
			-- The twelve bonds along the cell's edges.
			for i = 1, #corners do
				for j = i + 1, #corners do
					if math.abs((corners[i] - corners[j]).Magnitude - 2 * R) < 0.01 then
						c:rod(corners[i], corners[j], 0.06, p.pale, nil, false)
					end
				end
			end
			for _, e in ipairs({ { 0, y0 + 1.50, 0.40 }, { 1.50, y0 + 0.20, 0.30 }, { -1.40, y0 - 0.60, -0.40 } }) do
				c:neon(V(0.16, 0.16, 0.16), CF(e[1], e[2], e[3]), WHITE)
			end
			c:sparkle(p.glow, 5, 0.8, 0.2)
			c:light(p.glow, 1.6, 9)
		end,
	}

	-- The thunder beast of old stories, which comes down with the lightning.
	-- Where lightning strikes sand it leaves fulgurite, a branching tube of
	-- glass: this raiju's fur is made of it, and its tail is a bolt.
	S.ch_t_raiju = {
		label = "Fulgurite Raiju",
		set = "crystal_hollow",
		tint = C3(100, 240, 200),
		scale = 1.20,
		head = CF(0, 1.10, 0.40),
		neck = CF(0, -0.30, 1.10),
		back = CF(0, 0.50, -0.60),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(1.60, 1.50, 2.10),
				eyeSize = V(0.36, 0.44, 0.18), eyeSpread = 0.38, eyeY = 0.20,
				snout = { w = 0.56, h = 0.36, d = 0.46, y = -0.24, color = p.pale },
				legSize = V(0.36, 0.40, 0.44), legX = 0.50, legZ = { 0.60, -0.60 }, legColor = p.dark, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(V(0.34, 0.56, 0.24), CF(0.46 * s, 1.08, 0.30) * A(0, 0, -0.30 * s), p.base)
				c:neon(V(0.16, 0.16, 0.08), CF(0.66 * s, -0.10, 0.92), p.glow)
			end
			for i, f in ipairs({ { 0.00, 0.50, 0.20 }, { -0.30, 0.10, 0.70 }, { 0.30, -0.30, -0.70 }, { -0.10, -0.70, 0.30 } }) do
				local cf = CF(f[1], 0.80, f[2]) * A(-0.3, 0, f[3])
				c:cyl(V(0.60, 0.16, 0.16), cf * CF(0, 0.26, 0) * A(0, 0, PI / 2), p.light, GLASS)
				if i % 2 == 1 then
					c:cyl(V(0.30, 0.10, 0.10), cf * CF(0.10, 0.50, 0) * A(0, 0, PI / 2 - 0.7), p.pale, GLASS)
				end
			end
			local pts = { V(0, 0.10, -1.00), V(0.40, 0.60, -1.30), V(-0.20, 1.00, -1.50), V(0.30, 1.50, -1.60), V(0, 1.90, -1.40) }
			for i = 1, #pts - 1 do
				c:rod(pts[i], pts[i + 1], 0.12, i % 2 == 0 and p.glow or p.light, i % 2 == 0 and NEON or GLASS, false)
			end
			c:cone(V(0.34, 0.46, 0.34), CF(0, 2.10, -1.40), p.glow, NEON)
			c:star(V(-1.20, 1.10, 0.30), 0.30, p.glow)
			c:star(V(1.20, 0.80, -0.50), 0.30, p.glow)
			c:sparkle(p.glow, 6, 1.2, 0.2)
			c:light(p.glow, 1.6, 9)
		end,
	}

	return S
end
