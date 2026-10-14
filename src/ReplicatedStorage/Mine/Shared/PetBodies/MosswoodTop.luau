--[[ PetBodies/MosswoodTop -- Mosswood's top bodies. See tools/gen/sets/README.md.

	One body per Epic-and-up pet; no other pet wears any of these. Forest-floor
	creatures and small natural curiosities: a badger, a wren, a dormouse with
	its hazelnut, a stick insect, a bracket fungus, a nest, a mossy birdhouse, a
	firefly jar, a gnome with a moss beard, a lyrebird, a wolpertinger. Muted
	woods and greens; any glow stays small (fireflies, lanterns, a spring),
	never a giant magic tree.
]]
return function(K)
	local C3, block, ears, spots = K.C3, K.block, K.ears, K.spots
	local INK, WHITE, NOSE, WOOD, METAL, NEON, GLASS, SLATE = K.INK, K.WHITE, K.NOSE, K.WOOD, K.METAL, K.NEON, K.GLASS, K.SLATE
	local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
	local PI = math.pi
	local S = {}

	local MOSS = C3(108, 136, 74)
	local LEAF = C3(124, 150, 82)
	local TWIG = C3(110, 80, 56)
	local BLUSH = C3(232, 150, 150)
	local CREAM = C3(238, 228, 204)
	local GOLD = C3(226, 186, 92)
	local IRON = C3(80, 72, 64)
	local SIDES = { -1, 1 }

	local function smile(c, y, z, w)
		c:box(V(w or 0.28, 0.08, 0.06), CF(0, y, z), INK)
	end
	local function blush(c, x, y, z)
		for _, s in ipairs(SIDES) do
			c:box(V(0.20, 0.12, 0.05), CF(x * s, y, z), BLUSH)
		end
	end

	-- ===================================================================== Epic

	-- A badger: low and wide, a white stripe from nose to crown, dark masks.
	S.mw_t_badger = {
		label = "Bramble Badger",
		set = "mosswood",
		tint = C3(70, 72, 90),
		head = CF(0, 1.04, 0.20),
		neck = CF(0, -0.30, 1.00),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(2.02, 1.50, 1.90),
				snout = { w = 0.52, h = 0.36, d = 0.52, y = -0.20, color = p.pale, nose = NOSE },
				eyeY = 0.12, eyeSpread = 0.44, eyeSize = V(0.36, 0.42, 0.18),
				legSize = V(0.46, 0.30, 0.50), legY = -0.70, legColor = p.deep, tail = false,
			})
			c:box(V(0.34, 0.90, 0.08), CF(0, 0.30, 0.97), p.pale)
			c:box(V(0.34, 0.08, 1.10), CF(0, 0.80, 0.36), p.pale)
			for _, s in ipairs(SIDES) do
				c:box(V(0.40, 0.70, 0.06), CF(0.42 * s, 0.14, 0.96), p.deep)
				c:box(V(0.40, 0.34, 0.22), CF(0.62 * s, 0.84, 0.10), p.deep)
			end
			-- A bramble sprig caught on its back: a leaf and a blackberry.
			c:box(V(0.46, 0.06, 0.30), CF(-0.40, 0.80, -0.40) * A(0.2, 0.5, 0.1), LEAF)
			c:ball(V(0.26, 0.26, 0.26), CF(-0.18, 0.86, -0.52), C3(76, 36, 84))
		end,
	}

	-- A wren: a round little bird on a twig, its barred tail cocked straight up.
	S.mw_t_wren = {
		label = "Thicket Wren",
		set = "mosswood",
		tint = C3(178, 104, 56),
		head = CF(0, 0.98, 0.10),
		neck = CF(0, -0.30, 0.92),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V(1.80, 1.70, 1.70), mouth = false,
				eyeY = 0.22, eyeSpread = 0.38, eyeSize = V(0.34, 0.42, 0.18),
				bib = { w = 1.00, h = 0.80, y = -0.32, color = p.pale },
				legs = false, tail = false,
			})
			c:cone(V(0.26, 0.40, 0.26), CF(0, -0.02, 1.02) * A(PI / 2, 0, 0), C3(84, 66, 52))
			for _, s in ipairs(SIDES) do
				c:box(V(0.40, 0.08, 0.06), CF(0.38 * s, 0.52, 0.74) * A(0, 0, -0.2 * s), p.pale)
				c:box(V(0.16, 0.72, 0.96), CF(0.94 * s, 0.04, -0.12) * A(0, 0, 0.12 * s), p.dark)
				c:box(V(0.18, 0.06, 0.70), CF(0.96 * s, 0.10, -0.18), p.deep)
				c:box(V(0.10, 0.30, 0.10), CF(0.26 * s, -0.86, 0.12), p.deep)
			end
			local tail = CF(0, 0.80, -0.96) * A(-0.35, 0, 0)
			c:box(V(0.46, 0.94, 0.14), tail, p.dark)
			for _, y in ipairs({ -0.12, 0.20 }) do
				c:box(V(0.48, 0.06, 0.16), tail * CF(0, y, 0), p.light)
			end
			c:cyl(V(1.90, 0.18, 0.18), CF(0, -1.06, 0.12), TWIG, WOOD)
		end,
	}

	-- A dormouse curled round, its fluffy tail wrapped up one side, hugging a hazelnut.
	S.mw_t_dormouse = {
		label = "Hazel Dormouse",
		set = "mosswood",
		tint = C3(236, 178, 80),
		head = CF(0, 1.30, 0.04),
		neck = CF(0, -0.40, 0.96),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.90, 1.70, 1.80),
				snout = { w = 0.36, h = 0.24, d = 0.30, y = -0.16, color = p.pale, nose = BLUSH },
				eyeY = 0.26, eyeSpread = 0.40, eyeSize = V(0.46, 0.54, 0.20),
				legs = false, tail = false,
			})
			ears(c, p.base, "round", p.pale)
			c:box(V(0.56, 0.50, 0.96), CF(0.62, -0.62, -0.86), p.dark)
			c:box(V(0.56, 0.56, 0.90), CF(1.04, -0.46, -0.08), p.dark)
			c:box(V(0.52, 0.80, 0.52), CF(1.10, 0.10, 0.56), p.dark)
			c:box(V(0.44, 0.44, 0.44), CF(1.04, 0.62, 0.64), p.light)
			c:ball(V(0.52, 0.48, 0.48), CF(0, -0.56, 1.00), C3(168, 108, 58))
			c:box(V(0.34, 0.10, 0.26), CF(0.22, -0.40, 1.06) * A(0, 0, -0.5), LEAF)
			for _, s in ipairs(SIDES) do
				c:box(V(0.24, 0.20, 0.20), CF(0.30 * s, -0.48, 1.08), p.pale)
			end
		end,
	}

	-- A pine marten: long and low, a creamy bib, round ears and a long bushy tail.
	S.mw_t_marten = {
		label = "Pine Marten",
		set = "mosswood",
		tint = C3(140, 58, 40),
		scale = 1.25,
		head = CF(0, 0.86, 0.40),
		neck = CF(0, -0.30, 1.08),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			local bib = C3(240, 204, 120)
			block(c, p, {
				shape = "quad", bodySize = V(1.50, 1.30, 1.90),
				snout = { w = 0.50, h = 0.34, d = 0.50, y = -0.12, color = p.base, nose = NOSE },
				bib = { w = 0.90, h = 0.62, y = -0.30, color = bib },
				eyeY = 0.14, eyeSpread = 0.36, eyeSize = V(0.36, 0.44, 0.18),
				legSize = V(0.36, 0.40, 0.40), legX = 0.46, legY = -0.66, legZ = { 0.60, -0.60 },
				legColor = p.deep, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V(0.36, 0.32, 0.18), CF(0.42 * s, 0.76, 0.40), p.base)
				c:box(V(0.20, 0.18, 0.06), CF(0.42 * s, 0.74, 0.50), bib)
			end
			c:box(V(0.46, 0.46, 0.70), CF(0, 0.10, -1.22) * A(0.30, 0, 0), p.dark)
			c:box(V(0.42, 0.42, 0.36), CF(0, 0.26, -1.64) * A(0.40, 0, 0), p.deep)
		end,
	}

	-- A red panda: white brows and muzzle, white-rimmed ears, a long ringed tail.
	S.mw_t_redpanda = {
		label = "Ringtail Panda",
		set = "mosswood",
		tint = C3(214, 92, 40),
		scale = 1.25,
		head = CF(0, 1.30, 0.06),
		neck = CF(0, -0.34, 0.94),
		back = CF(0, 0.40, -0.86),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.90, 1.70, 1.76),
				snout = { w = 0.52, h = 0.36, d = 0.40, y = -0.22, color = CREAM, nose = NOSE },
				eyeY = 0.14, eyeSpread = 0.42, eyeSize = V(0.38, 0.46, 0.18),
				legSize = V(0.42, 0.30, 0.46), legX = 0.54, legY = -0.82, legColor = p.deep, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V(0.30, 0.16, 0.06), CF(0.42 * s, 0.50, 0.88), CREAM)
				c:box(V(0.46, 0.50, 0.22), CF(0.62 * s, 1.04, 0.04) * A(0, 0, -0.2 * s), CREAM)
				c:box(V(0.28, 0.32, 0.10), CF(0.62 * s, 1.02, 0.16) * A(0, 0, -0.2 * s), p.deep)
			end
			for i = 1, 4 do
				c:box(V(0.60, 0.60, 0.34), CF(0, -0.12 - i * 0.02, -0.80 - i * 0.30), i % 2 == 1 and p.light or p.dark)
			end
		end,
	}

	-- A kiwi: a round bird with no wings to speak of, a long beak and a fern on its back.
	S.mw_t_kiwi = {
		label = "Fernbird Kiwi",
		set = "mosswood",
		tint = C3(104, 140, 80),
		head = CF(0, 1.00, -0.10),
		neck = CF(0, -0.30, 0.96),
		back = CF(0, 0.30, -0.92),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.90, 1.60, 1.90), mouth = false,
				eyeY = 0.30, eyeSpread = 0.34, eyeSize = V(0.28, 0.34, 0.16),
				legs = false, tail = false,
			})
			local beak = C3(226, 206, 166)
			c:rod(V(0, 0.08, 0.92), V(0, -0.22, 1.46), 0.09, beak, nil, false)
			c:rod(V(0, -0.22, 1.46), V(0, -0.58, 1.76), 0.07, beak, nil, false)
			c:ball(V(0.16, 0.16, 0.16), CF(0, -0.22, 1.46), beak)
			for _, s in ipairs(SIDES) do
				c:box(V(0.26, 0.46, 0.26), CF(0.40 * s, -0.86, 0.10), p.deep)
				c:box(V(0.40, 0.10, 0.50), CF(0.40 * s, -1.10, 0.22), p.deep)
			end
			spots(c, p.dark, { { -0.50, 0.86, -0.40 }, { 0.42, 0.86, -0.10 }, { 0.06, 0.86, -0.66 } }, V(0.36, 0.08, 0.30))
			c:rod(V(0.30, 0.84, -0.40), V(0.66, 1.48, -0.80), 0.04, LEAF, nil, false)
			for i, t in ipairs({ 0.25, 0.50, 0.75 }) do
				local s = i % 2 == 0 and -1 or 1
				c:box(V(0.40, 0.06, 0.16), CF(0.30 + 0.36 * t, 0.84 + 0.64 * t, -0.40 - 0.40 * t) * A(0, 0.6 * s, 0.5), LEAF)
			end
		end,
	}

	-- A spotted salamander: a flat, wide-mouthed head, splayed legs, yellow spots.
	S.mw_t_salamander = {
		label = "Spotted Salamander",
		set = "mosswood",
		tint = C3(52, 56, 110),
		scale = 1.25,
		head = CF(0, 0.50, 0.80),
		neck = CF(0, -0.40, 1.34),
		back = CF(0, 0.30, -0.50),
		build = function(c, p)
			c:box(V(1.40, 0.90, 1.70), CF(0, -0.20, -0.05), p.base)
			c:box(V(1.60, 1.00, 0.70), CF(0, -0.10, 0.95), p.base)
			c:box(V(0.80, 0.60, 0.60), CF(0.10, -0.34, -1.10), p.base)
			c:box(V(0.60, 0.44, 0.56), CF(0.50, -0.42, -1.46) * A(0, 0.7, 0), p.dark)
			c:box(V(0.40, 0.30, 0.50), CF(0.98, -0.48, -1.62) * A(0, 1.2, 0), p.dark)
			for _, s in ipairs(SIDES) do
				c:eye(V(0.44 * s, 0.26, 1.30), 0.16)
				c:box(V(0.20, 0.12, 0.05), CF(0.56 * s, -0.12, 1.31), BLUSH)
				c:box(V(0.44, 0.26, 0.34), CF(0.86 * s, -0.56, 0.50) * A(0, -0.3 * s, 0), p.dark)
				c:box(V(0.44, 0.26, 0.34), CF(0.86 * s, -0.56, -0.50) * A(0, 0.3 * s, 0), p.dark)
			end
			smile(c, -0.30, 1.31, 0.60)
			spots(c, C3(250, 206, 40), {
				{ -0.36, 0.42, 0.80 }, { 0.36, 0.42, 0.80 }, { -0.40, 0.27, 0.20 },
				{ 0.36, 0.27, -0.10 }, { -0.30, 0.27, -0.50 }, { 0.40, 0.27, -0.62 },
			}, V(0.24, 0.06, 0.24))
		end,
	}

	-- A brook trout: a speckled fish with a pale belly, a stripe and a forked tail.
	S.mw_t_trout = {
		label = "Brook Trout",
		set = "mosswood",
		tint = C3(70, 150, 180),
		scale = 1.25,
		head = CF(0, 1.02, 0.30),
		neck = CF(0, -0.50, 1.10),
		back = CF(0, 0.60, -0.90),
		build = function(c, p)
			c:box(V(1.10, 1.30, 2.00), CF(0, 0.10, 0), p.base)
			c:box(V(0.90, 1.00, 0.30), CF(0, 0.06, 1.12), p.base)
			c:box(V(1.14, 0.34, 1.80), CF(0, -0.40, 0.02), p.pale)
			c:box(V(1.16, 0.14, 1.70), CF(0, 0.04, -0.06), p.light)
			c:eyes(0.34, 1.30, 0.26, 0.13)
			c:box(V(0.24, 0.14, 0.06), CF(0, -0.12, 1.28), INK)
			c:box(V(0.60, 0.70, 0.40), CF(0, 0.10, -1.16), p.base)
			for _, s in ipairs(SIDES) do
				c:box(V(0.14, 0.80, 0.50), CF(0, 0.10 + 0.32 * s, -1.56) * A(-0.6 * s, 0, 0), p.dark)
				c:box(V(0.40, 0.08, 0.40), CF(0.66 * s, -0.30, 0.40) * A(0, -0.4 * s, -0.4 * s), p.dark)
				for _, v in ipairs({ { 0.40, 0.50 }, { 0.48, -0.20 }, { 0.30, -0.70 } }) do
					c:box(V(0.04, 0.14, 0.14), CF(0.56 * s, v[1], v[2]), p.deep)
				end
			end
			c:box(V(0.12, 0.50, 0.70), CF(0, 0.92, -0.10) * A(-0.3, 0, 0), p.dark)
		end,
	}

	-- A crayfish: eyes on stalks, long feelers, two big pincers and a fanned tail.
	S.mw_t_crayfish = {
		label = "Creek Crayfish",
		set = "mosswood",
		tint = C3(206, 64, 48),
		scale = 1.25,
		head = CF(0, 0.70, 0.30),
		neck = CF(0, -0.40, 1.10),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			c:box(V(1.30, 0.90, 1.20), CF(0, -0.20, 0.30), p.base)
			for i, w in ipairs({ 1.10, 0.96, 0.80 }) do
				c:box(V(w, 0.74 - i * 0.08, 0.40), CF(0, -0.26 - i * 0.04, -0.12 - i * 0.36), i % 2 == 1 and p.dark or p.base)
			end
			c:box(V(1.20, 0.14, 0.50), CF(0, -0.50, -1.46), p.dark)
			for _, s in ipairs(SIDES) do
				c:box(V(0.12, 0.30, 0.12), CF(0.30 * s, 0.34, 0.80), p.dark)
				c:eye(V(0.30 * s, 0.56, 0.86), 0.14)
				c:rod(V(0.18 * s, 0.00, 0.90), V(0.80 * s, 0.86, 1.30), 0.03, p.dark, nil, false)
				c:rod(V(0.55 * s, -0.36, 0.70), V(0.86 * s, -0.24, 1.10), 0.10, p.dark, nil, false)
				c:box(V(0.46, 0.40, 0.56), CF(0.90 * s, -0.20, 1.30), p.base)
				c:box(V(0.20, 0.16, 0.36), CF(0.80 * s, 0.06, 1.46) * A(-0.3, 0, 0), p.dark)
				for _, z in ipairs({ 0.40, 0.00 }) do
					c:box(V(0.46, 0.10, 0.10), CF(0.78 * s, -0.62, z) * A(0, 0, -0.4 * s), p.dark)
				end
			end
			smile(c, -0.30, 0.92, 0.26)
		end,
	}

	-- A marimo: a perfectly round, fuzzy ball of moss sitting in a shallow pool.
	S.mw_t_marimo = {
		label = "Marimo Ball",
		set = "mosswood",
		tint = C3(70, 160, 80),
		head = CF(0, 1.16, 0),
		neck = CF(0, -0.40, 0.92),
		back = CF(0, 0.20, -0.96),
		build = function(c, p)
			c:ball(V(1.90, 1.90, 1.90), CF(0, 0.10, 0), p.base)
			local tufts = {
				{ 0, 1, 0 }, { 0.68, 0.70, -0.20 }, { -0.68, 0.70, -0.20 }, { 0, 0.70, -0.72 },
				{ 0.96, 0.10, -0.24 }, { -0.96, 0.10, -0.24 }, { 0.50, 0.08, -0.86 }, { -0.50, 0.08, -0.86 },
			}
			for i, d in ipairs(tufts) do
				local u = V(d[1], d[2], d[3]).Unit
				c:box(V(0.32, 0.32, 0.32), CF(u * 0.92 + V(0, 0.10, 0)) * A(0.6, 0.6 * i, 0), i % 2 == 0 and p.light or p.dark)
			end
			c:eyes(0.30, 0.90, 0.32, 0.15)
			smile(c, -0.10, 0.93, 0.26)
			blush(c, 0.52, 0.04, 0.81)
			c:cyl(V(0.24, 2.30, 2.30), CF(0, -0.90, 0) * A(0, 0, PI / 2), C3(120, 176, 196), GLASS)
			c:ball(V(0.36, 0.28, 0.36), CF(0.94, -0.74, 0.60), C3(150, 150, 156))
			c:ball(V(0.30, 0.24, 0.30), CF(-0.98, -0.76, 0.44), C3(176, 172, 164))
			c:ball(V(0.22, 0.22, 0.22), CF(-0.70, 1.20, 0.40), C3(206, 232, 240), GLASS)
			c:ball(V(0.14, 0.14, 0.14), CF(-0.92, 1.46, 0.46), C3(206, 232, 240), GLASS)
		end,
	}

	-- A bracket fungus: three shelves growing from a chunk of bark; the big one has the face.
	S.mw_t_bracket = {
		label = "Bracket Fungus",
		set = "mosswood",
		tint = C3(224, 140, 64),
		head = CF(0, 1.40, -0.60),
		neck = CF(0, -0.40, 0.76),
		back = CF(0, 0.20, -1.04),
		build = function(c, p)
			c:box(V(1.40, 2.20, 0.50), CF(0, 0.10, -0.75), p.deep, WOOD)
			c:box(V(1.00, 0.12, 0.40), CF(0, 1.24, -0.72), MOSS)
			for _, s in ipairs(SIDES) do
				c:box(V(0.40, 0.20, 0.50), CF(0.40 * s, -1.02, -0.60), p.deep, WOOD)
			end
			c:box(V(2.20, 0.56, 1.30), CF(0, -0.10, 0.05), p.base)
			c:box(V(1.80, 0.04, 0.90), CF(0, 0.20, -0.05), p.light)
			c:box(V(1.60, 0.30, 1.00), CF(0, 0.66, -0.10), p.light)
			c:box(V(1.20, 0.04, 0.66), CF(0, 0.83, -0.12), p.pale)
			c:box(V(1.40, 0.26, 0.90), CF(0, -0.76, -0.15), p.dark)
			c:box(V(0.56, 0.20, 0.60), CF(0.86, 0.94, -0.60), p.light)
			c:eyes(-0.02, 0.74, 0.36, 0.12)
			smile(c, -0.26, 0.71, 0.26)
			blush(c, 0.64, -0.20, 0.71)
		end,
	}

	-- A stick insect: a twig of a body on six long, kneed legs, with long feelers.
	S.mw_t_stickbug = {
		label = "Walking Stick",
		set = "mosswood",
		tint = C3(160, 150, 70),
		scale = 1.15,
		head = CF(0, 0.66, 0.80),
		neck = CF(0, -0.10, 1.20),
		back = CF(0, 0.50, -0.60),
		build = function(c, p)
			c:box(V(0.50, 0.46, 1.10), CF(0, 0.10, 0.04), p.base)
			c:box(V(0.44, 0.40, 1.10), CF(0, 0.24, -0.98) * A(0.25, 0, 0), p.dark)
			c:box(V(0.70, 0.60, 0.56), CF(0, 0.16, 0.86), p.base)
			c:eyes(0.24, 1.18, 0.20, 0.13)
			smile(c, 0.02, 1.15, 0.20)
			c:box(V(0.14, 0.20, 0.14), CF(0, 0.40, -0.20), p.deep)
			c:box(V(0.12, 0.18, 0.12), CF(0, 0.50, -1.10), p.deep)
			for _, s in ipairs(SIDES) do
				c:rod(V(0.14 * s, 0.40, 1.08), V(0.50 * s, 0.96, 1.46), 0.03, p.deep, nil, false)
				for _, l in ipairs({ { 0.40, 0.18 }, { 0.00, 0.00 }, { -0.40, -0.18 } }) do
					local knee = V(0.66 * s, 0.46, l[1] + l[2])
					c:rod(V(0.22 * s, 0.06, l[1]), knee, 0.05, p.dark, nil, false)
					c:rod(knee, V(0.96 * s, -0.86, l[1] + l[2] * 2), 0.04, p.dark, nil, false)
				end
			end
		end,
	}

	-- A speckled wood butterfly: a chubby body with its wings spread flat behind.
	S.mw_t_butterfly = {
		label = "Speckled Wood",
		set = "mosswood",
		tint = C3(232, 180, 60),
		scale = 1.1,
		head = CF(0, 0.70, 0.20),
		neck = CF(0, -0.36, 0.64),
		back = CF(0, 0.10, -0.50),
		build = function(c, p)
			c:box(V(0.86, 0.86, 1.00), CF(0, 0.10, 0.10), p.dark)
			c:eyes(0.24, 0.64, 0.22, 0.13)
			smile(c, -0.04, 0.61, 0.22)
			for _, s in ipairs(SIDES) do
				c:box(V(1.10, 1.00, 0.10), CF(0.78 * s, 0.56, -0.30) * A(0, 0, -0.30 * s), p.base)
				c:box(V(0.80, 0.80, 0.10), CF(0.64 * s, -0.36, -0.30) * A(0, 0, 0.40 * s), p.deep)
				c:box(V(0.24, 0.24, 0.04), CF(1.02 * s, 0.80, -0.23), p.pale)
				c:box(V(0.18, 0.18, 0.04), CF(0.60 * s, 0.86, -0.23), p.pale)
				c:box(V(0.20, 0.20, 0.04), CF(0.70 * s, -0.42, -0.23), p.pale)
				c:box(V(0.20, 0.12, 0.05), CF(0.26 * s, 0.04, 0.60), BLUSH)
				c:rod(V(0.14 * s, 0.50, 0.40), V(0.44 * s, 1.16, 0.56), 0.035, p.deep, nil, false)
				c:ball(V(0.16, 0.16, 0.16), CF(0.44 * s, 1.16, 0.56), p.deep)
			end
		end,
	}

	-- A millipede winding along the ground, its front end reared up, moss on its back.
	S.mw_t_millipede = {
		label = "Moss Millipede",
		set = "mosswood",
		tint = C3(140, 56, 110),
		scale = 1.15,
		head = CF(0, 0.92, 0.90),
		neck = CF(0, -0.10, 1.30),
		back = CF(0.40, 0.20, -0.60),
		build = function(c, p)
			local segs = {
				{ 0.00, 0.30, 0.95, 1.00, 0.90, 0.60, 0 },
				{ 0.05, -0.10, 0.50, 0.86, 0.74, 0.46, 0.15 },
				{ 0.20, -0.30, 0.10, 0.82, 0.70, 0.46, 0.45 },
				{ 0.42, -0.34, -0.28, 0.80, 0.68, 0.46, 0.35 },
				{ 0.48, -0.36, -0.70, 0.76, 0.64, 0.46, -0.20 },
				{ 0.26, -0.38, -1.06, 0.70, 0.60, 0.44, -0.70 },
				{ -0.10, -0.40, -1.28, 0.62, 0.54, 0.42, -1.10 },
			}
			for i, g in ipairs(segs) do
				local cf = CF(g[1], g[2], g[3]) * A(0, g[7], 0)
				c:box(V(g[4], g[5], g[6]), cf, i % 2 == 1 and p.base or p.dark)
				if i > 1 then
					c:box(V(g[4] + 0.34, 0.10, 0.14), cf * CF(0, -g[5] * 0.5 - 0.02, 0), p.deep)
				end
			end
			c:eyes(0.42, 1.28, 0.24, 0.14)
			smile(c, 0.12, 1.26, 0.26)
			for _, s in ipairs(SIDES) do
				c:rod(V(0.20 * s, 0.70, 1.10), V(0.60 * s, 1.20, 1.40), 0.04, p.deep, nil, false)
			end
			c:box(V(0.50, 0.10, 0.36), CF(0.42, 0.02, -0.28) * A(0, 0.35, 0), MOSS)
			c:box(V(0.40, 0.10, 0.30), CF(0.26, -0.06, -1.06) * A(0, -0.7, 0), MOSS)
		end,
	}

	-- A woven twig nest with a fluffy chick sitting up in it, beside two speckled eggs.
	S.mw_t_nest = {
		label = "Twigweave Nest",
		set = "mosswood",
		tint = C3(200, 170, 110),
		head = CF(0, 1.16, 0.04),
		neck = CF(0, -0.30, 1.06),
		back = CF(0, 0.00, -1.06),
		build = function(c, p)
			c:box(V(1.90, 0.50, 1.90), CF(0, -0.62, 0), p.base, WOOD)
			for _, s in ipairs(SIDES) do
				c:box(V(2.10, 0.36, 0.40), CF(0, -0.24, 0.85 * s) * A(0, 0.05 * s, 0.04 * s), p.dark, WOOD)
				c:box(V(0.40, 0.36, 2.10), CF(0.85 * s, -0.22, 0) * A(0.05 * s, 0, 0), p.dark, WOOD)
			end
			c:box(V(0.08, 0.08, 0.80), CF(0.90, -0.04, 0.60) * A(0.3, 0.8, 0), p.deep, WOOD)
			c:box(V(0.70, 0.08, 0.08), CF(-1.00, -0.10, -0.50) * A(0, 0.4, 0.4), p.deep, WOOD)
			c:box(V(0.08, 0.60, 0.08), CF(-0.70, 0.10, -0.86) * A(0.3, 0, 0.5), p.deep, WOOD)
			c:box(V(1.20, 1.10, 1.00), CF(0, 0.30, 0), p.pale)
			c:eyes(0.44, 0.56, 0.26, 0.13)
			c:cone(V(0.22, 0.26, 0.22), CF(0, 0.22, 0.60) * A(PI / 2, 0, 0), C3(240, 160, 60))
			for _, s in ipairs(SIDES) do
				c:box(V(0.14, 0.44, 0.56), CF(0.64 * s, 0.24, 0), p.light)
				c:box(V(0.10, 0.26, 0.10), CF(0.08 * s, 0.96, 0) * A(0, 0, -0.4 * s), p.light)
				c:ball(V(0.40, 0.50, 0.40), CF(0.66 * s, 0.02, 0.50), C3(170, 210, 222))
			end
		end,
	}

	-- A baby tapir: a stout body, a short drooping trunk and pale stripes down its sides.
	S.mw_t_tapir = {
		label = "Striped Tapir",
		set = "mosswood",
		tint = C3(90, 110, 150),
		head = CF(0, 1.10, 0.20),
		neck = CF(0, -0.30, 1.06),
		back = CF(0, 0.40, -0.90),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(1.90, 1.60, 2.00), mouth = false,
				eyeY = 0.18, eyeSpread = 0.40, eyeSize = V(0.34, 0.40, 0.18),
				legSize = V(0.42, 0.40, 0.46), legY = -0.84, legColor = p.deep,
				tailSize = V(0.20, 0.24, 0.30),
			})
			c:box(V(0.48, 0.38, 0.50), CF(0, -0.16, 1.16), p.dark)
			c:box(V(0.38, 0.34, 0.32), CF(0, -0.34, 1.44) * A(0.4, 0, 0), p.dark)
			for _, s in ipairs(SIDES) do
				c:box(V(0.40, 0.36, 0.20), CF(0.56 * s, 0.86, 0.24), p.dark)
				for _, y in ipairs({ 0.34, 0.00 }) do
					c:box(V(0.04, 0.10, 1.40), CF(1.01 * s, y, -0.10), p.pale)
				end
			end
		end,
	}

	-- A woodpecker clinging upright to a mossy log: red cap, chisel beak, barred wings.
	S.mw_t_woodpecker = {
		label = "Logtap Woodpecker",
		set = "mosswood",
		tint = C3(236, 232, 222),
		head = CF(0, 1.30, 0.06),
		neck = CF(0, -0.20, 0.70),
		back = CF(0, 0.40, -1.20),
		build = function(c, p)
			local red = C3(212, 40, 44)
			c:cyl(V(2.40, 0.96, 0.96), CF(0, 0, -0.76) * A(0, 0, PI / 2), TWIG, WOOD)
			c:box(V(0.70, 0.10, 0.70), CF(0, 1.22, -0.76), MOSS)
			c:box(V(0.10, 0.50, 0.50), CF(-0.50, 0.60, -0.80), MOSS)
			c:box(V(1.20, 1.70, 1.00), CF(0, 0.10, 0.10), p.base)
			c:box(V(0.80, 1.00, 0.10), CF(0, -0.20, 0.62), p.pale)
			c:eyes(0.44, 0.64, 0.30, 0.14)
			c:cone(V(0.22, 0.60, 0.22), CF(0, 0.22, 0.90) * A(PI / 2, 0, 0), C3(60, 60, 70))
			c:box(V(0.80, 0.30, 0.80), CF(0, 1.06, 0.06), red)
			c:box(V(0.40, 0.30, 0.40), CF(0, 1.10, -0.36) * A(-0.5, 0, 0), red)
			for _, s in ipairs(SIDES) do
				c:box(V(0.14, 1.10, 0.80), CF(0.66 * s, 0.10, -0.04), p.dark)
				c:box(V(0.16, 0.08, 0.60), CF(0.67 * s, 0.24, -0.04), p.pale)
				c:box(V(0.16, 0.08, 0.60), CF(0.67 * s, -0.06, -0.04), p.pale)
				c:box(V(0.20, 0.14, 0.30), CF(0.30 * s, -0.78, -0.24), p.deep)
			end
			c:box(V(0.40, 0.70, 0.12), CF(0, -0.86, -0.36) * A(0.4, 0, 0), p.dark)
		end,
	}

	-- A hollow log lying on root feet: its open end is the face, moss and a toadstool on top.
	S.mw_t_hollowlog = {
		label = "Hollow Log",
		set = "mosswood",
		tint = C3(126, 88, 58),
		head = CF(0, 1.10, 0.20),
		neck = CF(0, -0.50, 1.24),
		back = CF(0, 0.30, -1.24),
		build = function(c, p)
			c:cyl(V(2.40, 1.70, 1.70), A(0, PI / 2, 0), p.base, WOOD)
			c:cyl(V(0.04, 1.50, 1.50), CF(0, 0, 1.21) * A(0, PI / 2, 0), p.pale, WOOD)
			c:cyl(V(0.04, 0.86, 0.86), CF(0, -0.22, 1.23) * A(0, PI / 2, 0), C3(46, 34, 28))
			c:eyes(0.42, 1.27, 0.34, 0.14)
			for _, a in ipairs({ -0.9, 0, 0.9 }) do
				c:box(V(0.12, 0.10, 2.30), A(0, 0, a) * CF(0, 0.86, 0), p.dark, WOOD)
			end
			c:box(V(1.00, 0.14, 1.60), CF(0.10, 0.86, -0.10), MOSS)
			c:box(V(0.14, 0.26, 0.14), CF(-0.40, 1.00, -0.40), CREAM)
			c:box(V(0.40, 0.14, 0.40), CF(-0.40, 1.18, -0.40), C3(196, 60, 50))
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.70, -0.70 }) do
					c:box(V(0.34, 0.30, 0.40), CF(0.50 * s, -0.82, z), p.dark, WOOD)
				end
			end
			c:cyl(V(0.40, 0.34, 0.34), CF(0.98, 0.10, -0.30), p.base, WOOD)
		end,
	}

	-- ================================================================ Legendary

	-- A copper pheasant: red face wattles, a white collar and two long barred plumes.
	S.mw_t_pheasant = {
		label = "Copper Pheasant",
		set = "mosswood",
		tint = C3(204, 110, 46),
		scale = 1.2,
		head = CF(0, 1.00, 0.20),
		neck = CF(0, -0.30, 0.88),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V(1.70, 1.60, 1.70), mouth = false,
				eyeY = 0.24, eyeSpread = 0.36, eyeSize = V(0.30, 0.38, 0.16),
				legs = false, tail = false,
			})
			c:cone(V(0.22, 0.32, 0.22), CF(0, 0.02, 0.98) * A(PI / 2, 0, 0), C3(232, 214, 160))
			c:box(V(1.30, 0.12, 0.10), CF(0, -0.16, 0.86), WHITE)
			for _, s in ipairs(SIDES) do
				c:box(V(0.40, 0.50, 0.06), CF(0.36 * s, 0.22, 0.84), C3(206, 40, 48))
				c:box(V(0.12, 0.30, 0.12), CF(0.30 * s, 0.94, 0.30) * A(0, 0, -0.3 * s), p.deep)
				c:box(V(0.10, 0.30, 0.10), CF(0.24 * s, -0.86, 0.10), p.deep)
				c:box(V(0.16, 0.72, 0.94), CF(0.88 * s, 0.02, -0.20) * A(0, 0, 0.15 * s), p.dark)
				local plume = CF(0.10 * s, 0.70, -1.40) * A(0.6, 0.08 * s, 0)
				c:box(V(0.28, 0.10, 1.60), plume, p.base)
				c:box(V(0.30, 0.12, 0.10), plume * CF(0, 0, -0.30 + 0.30 * s), p.deep)
			end
			spots(c, p.light, { { -0.40, 0.76, -0.30 }, { 0.36, 0.76, -0.50 }, { 0.00, 0.82, 0.00 } }, V(0.26, 0.06, 0.26))
		end,
	}

	-- A mossy birdhouse on a post: round entrance hole, a tiny bird peeking out, twigs and moss.
	S.mw_t_birdhouse = {
		label = "Mossy Birdhouse",
		set = "mosswood",
		tint = C3(120, 70, 44),
		scale = 1.2,
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			-- Post and ground plate so the house is planted, not floating.
			c:box(V(0.34, 1.10, 0.34), CF(0, -0.86, 0), TWIG, WOOD)
			c:box(V(0.80, 0.16, 0.80), CF(0, -1.36, 0), p.deep, WOOD)
			-- House body; face sits on the front face.
			c:box(V(1.50, 1.40, 1.20), CF(0, 0.20, 0), p.base, WOOD)
			for _, s in ipairs(SIDES) do
				c:box(V(1.16, 0.14, 1.40), CF(0.44 * s, 1.14, 0) * A(0, 0, -0.55 * s), p.dark, WOOD)
				c:box(V(0.10, 0.46, 0.10), CF(0.82 * s, 0.40, -0.20) * A(0.15, 0, 0.25 * s), TWIG, WOOD)
				c:box(V(0.40, 0.08, 0.26), CF(0.72 * s, 0.66, -0.10) * A(0, 0.4 * s, 0.2), LEAF)
			end
			c:box(V(0.22, 0.12, 1.44), CF(0, 1.48, 0), p.deep, WOOD)
			c:box(V(0.60, 0.10, 0.50), CF(-0.28, 1.28, 0.20) * A(0, 0.2, 0.45), MOSS)
			c:box(V(0.50, 0.10, 0.40), CF(0.34, 1.22, -0.14) * A(0, -0.3, -0.5), MOSS)
			c:box(V(0.40, 0.10, 0.50), CF(0.10, 0.92, -0.50) * A(0.2, 0.6, 0), MOSS)
			-- Round entrance hole on the front; a tiny bird peeks out.
			c:cyl(V(0.06, 0.72, 0.72), CF(0, 0.34, 0.62) * A(0, PI / 2, 0), C3(46, 34, 28))
			c:ball(V(0.40, 0.38, 0.40), CF(0, 0.38, 0.78), p.light)
			c:cone(V(0.12, 0.20, 0.12), CF(0, 0.34, 1.02) * A(PI / 2, 0, 0), C3(240, 160, 60))
			for _, s in ipairs(SIDES) do
				c:box(V(0.08, 0.08, 0.04), CF(0.10 * s, 0.46, 0.98), INK)
			end
			-- House face around the hole.
			c:eyes(0.78, 0.64, 0.28, 0.12)
			smile(c, -0.16, 0.62, 0.36)
			blush(c, 0.54, 0.02, 0.61)
			-- Twig perch under the hole.
			c:cyl(V(1.00, 0.10, 0.10), CF(0, -0.14, 0.70) * A(0, 0, PI / 2), TWIG, WOOD)
			c:box(V(0.46, 0.08, 0.22), CF(0, -0.24, 0.66), p.dark, WOOD)
		end,
	}

	-- A little log cabin: lit windows for eyes, the door for a mouth, smoke from the chimney.
	S.mw_t_cabin = {
		label = "Woodland Cabin",
		set = "mosswood",
		tint = C3(176, 70, 56),
		scale = 1.12,
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.60, 0.96),
		back = CF(0, 0.00, -0.90),
		build = function(c, p)
			local smoke = C3(222, 222, 228)
			c:box(V(1.90, 1.30, 1.60), CF(0, -0.30, 0), p.base, WOOD)
			for _, s in ipairs(SIDES) do
				for _, y in ipairs({ -0.66, -0.30, 0.06 }) do
					c:cyl(V(1.70, 0.16, 0.16), CF(0.96 * s, y, 0) * A(0, PI / 2, 0), p.dark, WOOD)
				end
				c:box(V(1.30, 0.14, 1.90), CF(0.56 * s, 0.70, 0) * A(0, 0, -0.65 * s), p.deep, WOOD)
				c:box(V(0.50, 0.10, 0.70), CF(0.60 * s, 0.76, 0.30 * s) * A(0, 0, -0.65 * s), MOSS)
				c:box(V(0.50, 0.46, 0.06), CF(0.48 * s, 0.00, 0.81), C3(250, 214, 120), NEON)
				c:eye(V(0.48 * s, 0.00, 0.86), 0.13)
			end
			c:box(V(0.26, 0.16, 1.94), CF(0, 1.12, 0), p.dark, WOOD)
			c:box(V(0.34, 0.80, 0.34), CF(0.56, 1.00, -0.40), C3(130, 128, 134), SLATE)
			c:ball(V(0.36, 0.32, 0.36), CF(0.62, 1.56, -0.40), smoke)
			c:ball(V(0.46, 0.40, 0.46), CF(0.82, 1.86, -0.40), smoke)
			c:box(V(0.42, 0.56, 0.06), CF(0, -0.66, 0.81), p.deep, WOOD)
			c:ball(V(0.08, 0.08, 0.08), CF(0.12, -0.66, 0.85), GOLD, METAL)
			c:box(V(0.80, 0.12, 0.30), CF(0, -0.92, 0.94), p.dark, WOOD)
			for _, v in ipairs({ { -0.13, -0.84 }, { 0.13, -0.84 }, { 0, -0.62 } }) do
				c:cyl(V(0.50, 0.24, 0.24), CF(-1.22 + v[1], v[2], 0.30) * A(0, PI / 2, 0), TWIG, WOOD)
			end
		end,
	}

	-- A straw skep: a beehive of coiled straw, its doorway the mouth, three fat bees about it.
	S.mw_t_skep = {
		label = "Straw Skep",
		set = "mosswood",
		tint = C3(232, 190, 90),
		head = CF(0, 1.46, 0),
		neck = CF(0, -0.50, 1.10),
		back = CF(0, 0.00, -1.06),
		build = function(c, p)
			c:box(V(2.30, 0.14, 2.30), CF(0, -0.95, 0), p.deep, WOOD)
			for i, d in ipairs({ 2.10, 2.04, 1.86, 1.56, 1.14, 0.62 }) do
				c:cyl(V(0.36, d, d), CF(0, -0.70 + (i - 1) * 0.32, 0) * A(0, 0, PI / 2), i % 2 == 1 and p.base or p.light)
			end
			c:box(V(0.24, 0.20, 0.24), CF(0, 1.06, 0), p.dark)
			c:eyes(-0.06, 0.96, 0.32, 0.15)
			blush(c, 0.56, -0.20, 0.76)
			c:box(V(0.46, 0.24, 0.10), CF(0, -0.62, 1.04), C3(60, 40, 30))
			c:box(V(0.14, 0.30, 0.08), CF(0.18, -0.82, 1.06), C3(240, 170, 40))
			for _, b in ipairs({ { 1.20, 0.50, 0.40 }, { -1.16, 0.20, 0.60 }, { 0.50, 1.40, 0.30 } }) do
				local at = CF(b[1], b[2], b[3])
				c:box(V(0.28, 0.22, 0.32), at, C3(250, 206, 50))
				c:box(V(0.30, 0.24, 0.08), at * CF(0, 0, -0.04), INK)
				c:box(V(0.30, 0.04, 0.14), at * CF(0, 0.13, -0.04), C3(236, 240, 246), GLASS)
			end
		end,
	}

	-- An okapi: big upright ears, two furry horns, a long muzzle and zebra-striped legs.
	S.mw_t_okapi = {
		label = "Forest Okapi",
		set = "mosswood",
		tint = C3(110, 48, 60),
		head = CF(0, 1.16, 0.20),
		neck = CF(0, -0.30, 1.10),
		back = CF(0, 0.40, -0.90),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(1.70, 1.60, 2.00),
				snout = { w = 0.56, h = 0.46, d = 0.60, y = -0.26, color = p.deep, nose = NOSE },
				eyeY = 0.16, eyeSpread = 0.40, eyeSize = V(0.36, 0.44, 0.18),
				legSize = V(0.34, 0.74, 0.38), legX = 0.50, legY = -0.92, legColor = p.pale,
				tailSize = V(0.14, 0.50, 0.14),
			})
			for _, s in ipairs(SIDES) do
				c:box(V(0.20, 0.56, 0.40), CF(0.70 * s, 0.98, 0.10) * A(0, 0, -0.6 * s), p.base)
				c:box(V(0.12, 0.30, 0.12), CF(0.24 * s, 0.94, 0.36), p.dark)
				for _, z in ipairs({ 0.42, -0.42 }) do
					c:box(V(0.36, 0.08, 0.40), CF(0.50 * s, -1.04, z), p.deep)
				end
				for _, y in ipairs({ 0.30, -0.04 }) do
					c:box(V(0.04, 0.12, 0.60), CF(0.90 * s, y, -0.56), p.pale)
				end
			end
		end,
	}

	-- A rhinoceros beetle with lichen growing on its wing cases and a great curved horn.
	S.mw_t_beetle = {
		label = "Lichen Beetle",
		set = "mosswood",
		tint = C3(70, 110, 64),
		scale = 1.12,
		head = CF(0, 0.90, -0.30),
		neck = CF(0, -0.40, 1.20),
		back = CF(0, 0.30, -1.30),
		build = function(c, p)
			c:box(V(1.80, 1.00, 1.90), CF(0, -0.10, -0.30), p.base)
			c:box(V(0.04, 1.02, 1.80), CF(0, -0.08, -0.34), p.deep)
			c:box(V(0.30, 0.04, 1.20), CF(-0.50, 0.41, -0.30), p.light)
			c:box(V(1.50, 0.80, 0.70), CF(0, -0.15, 0.95), p.dark)
			c:eyes(0.06, 1.34, 0.42, 0.13)
			c:rod(V(0, -0.30, 1.28), V(0, 0.40, 1.66), 0.12, p.deep, nil, false)
			c:rod(V(0, 0.40, 1.66), V(0, 0.84, 1.48), 0.09, p.deep, nil, false)
			c:ball(V(0.24, 0.24, 0.24), CF(0, 0.40, 1.66), p.deep)
			c:cone(V(0.22, 0.36, 0.22), CF(0, 0.42, 0.90), p.deep)
			blush(c, 0.60, -0.22, 1.31)
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.70, 0.00, -0.70 }) do
					c:rod(V(0.80 * s, -0.40, z), V(1.12 * s, -0.86, z * 1.2), 0.06, p.deep, nil, false)
				end
			end
			c:box(V(0.50, 0.08, 0.40), CF(0.40, 0.42, -0.60) * A(0, 0.4, 0), MOSS)
			c:box(V(0.40, 0.08, 0.36), CF(-0.36, 0.42, -0.90) * A(0, -0.3, 0), C3(178, 190, 140))
			c:box(V(0.30, 0.08, 0.30), CF(0.30, 0.42, 0.10) * A(0, 0.8, 0), MOSS)
		end,
	}

	-- A lynx: tall tufted ears, a ruff of cheek fur, big paws, a bobtail and spots.
	S.mw_t_lynx = {
		label = "Tufted Lynx",
		set = "mosswood",
		tint = C3(212, 176, 128),
		head = CF(0, 1.20, 0.10),
		neck = CF(0, -0.30, 1.00),
		back = CF(0, 0.40, -0.86),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(1.90, 1.70, 1.80),
				snout = { w = 0.56, h = 0.36, d = 0.40, y = -0.22, color = p.pale, nose = NOSE },
				eyeY = 0.16, eyeSpread = 0.42, eyeSize = V(0.38, 0.46, 0.18),
				legSize = V(0.52, 0.36, 0.58), legColor = p.base,
				tailSize = V(0.30, 0.30, 0.36), tailColor = p.deep,
			})
			ears(c, p.base, "up", p.pale)
			for _, s in ipairs(SIDES) do
				c:box(V(0.08, 0.36, 0.08), CF(0.60 * s, 1.60, 0.04) * A(0, 0, -0.16 * s), INK)
				c:box(V(0.40, 0.56, 0.30), CF(0.88 * s, -0.20, 0.66) * A(0, 0, 0.4 * s), p.pale)
			end
			spots(c, p.dark, { { 1.01, 0.24, -0.30 }, { 1.01, -0.12, -0.60 }, { -1.01, 0.20, -0.50 }, { -1.01, -0.16, -0.20 } }, V(0.06, 0.18, 0.18))
		end,
	}

	-- A wild boar: a bristly mane from crown to rump, little tusks and a broad snout.
	S.mw_t_boar = {
		label = "Bristle Boar",
		set = "mosswood",
		tint = C3(110, 82, 70),
		head = CF(0, 1.12, 0.30),
		neck = CF(0, -0.30, 1.10),
		back = CF(0, 0.50, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(2.00, 1.60, 1.90),
				snout = { w = 0.70, h = 0.50, d = 0.44, y = -0.26, color = p.light, nose = p.deep },
				eyeY = 0.16, eyeSpread = 0.44, eyeSize = V(0.34, 0.40, 0.18),
				legSize = V(0.42, 0.36, 0.46), legColor = p.deep, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(V(0.12, 0.30, 0.12), CF(0.40 * s, -0.08, 1.16), CREAM)
				c:box(V(0.26, 0.36, 0.14), CF(0.56 * s, 0.94, 0.30) * A(0, 0, -0.3 * s), p.dark)
			end
			for i = 0, 4 do
				c:box(V(0.20, 0.36, 0.26), CF(0, 0.88 - i * 0.04, 0.50 - i * 0.30) * A(-0.4, 0, 0), p.deep)
			end
			c:box(V(0.10, 0.40, 0.10), CF(0, 0.00, -1.00) * A(0.3, 0, 0), p.deep)
			c:box(V(0.16, 0.20, 0.16), CF(0, -0.22, -1.06), p.deep)
		end,
	}

	-- A kingfisher on a mossy post, a little silver fish crossways in its long beak.
	S.mw_t_kingfisher = {
		label = "Brook Kingfisher",
		set = "mosswood",
		tint = C3(30, 130, 210),
		scale = 1.1,
		head = CF(0, 1.00, 0.10),
		neck = CF(0, -0.30, 0.90),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			local orange, silver = C3(236, 130, 50), C3(196, 206, 214)
			block(c, p, {
				shape = "bird", bodySize = V(1.70, 1.70, 1.60), mouth = false,
				eyeY = 0.22, eyeSpread = 0.38, eyeSize = V(0.32, 0.40, 0.18),
				bib = { w = 1.10, h = 0.90, y = -0.36, color = orange },
				legs = false, tail = false,
			})
			c:cone(V(0.24, 0.90, 0.24), CF(0, 0.02, 1.24) * A(PI / 2, 0, 0), C3(40, 40, 48))
			c:box(V(0.44, 0.16, 0.12), CF(0.10, 0.02, 1.30), silver)
			c:box(V(0.14, 0.20, 0.06), CF(-0.16, 0.02, 1.30), silver)
			for _, s in ipairs(SIDES) do
				c:box(V(0.10, 0.22, 0.34), CF(0.84 * s, 0.10, 0.36), orange)
				c:box(V(0.10, 0.18, 0.20), CF(0.84 * s, -0.12, 0.40), CREAM)
				c:box(V(0.16, 0.70, 0.90), CF(0.88 * s, 0.00, -0.18) * A(0, 0, 0.12 * s), p.dark)
				c:box(V(0.10, 0.20, 0.10), CF(0.24 * s, -0.80, 0.10), C3(220, 80, 60))
			end
			spots(c, p.light, { { -0.97, 0.20, -0.30 }, { 0.97, 0.10, -0.40 }, { 0.00, 0.88, -0.20 } }, V(0.04, 0.12, 0.18))
			c:box(V(0.40, 0.14, 0.50), CF(0, -0.30, -0.96) * A(-0.5, 0, 0), p.dark)
			c:box(V(0.80, 0.60, 0.80), CF(0, -1.20, 0.10), TWIG, WOOD)
			c:box(V(0.84, 0.10, 0.84), CF(0, -0.88, 0.10), MOSS)
		end,
	}

	-- A koala with big fluffy ears and a dark button nose, holding a sprig of gum leaves.
	S.mw_t_koala = {
		label = "Gumleaf Koala",
		set = "mosswood",
		tint = C3(150, 154, 170),
		head = CF(0, 1.20, 0.00),
		neck = CF(0, -0.40, 1.00),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			local gum = C3(140, 174, 150)
			block(c, p, {
				shape = "round", bodySize = V(1.90, 1.80, 1.70), mouth = false,
				eyeY = 0.20, eyeSpread = 0.48, eyeSize = V(0.28, 0.34, 0.16),
				bib = { w = 1.00, h = 0.70, y = -0.46, color = p.pale },
				legSize = V(0.44, 0.30, 0.50), legX = 0.50, legY = -0.90, legZ = { 0.30 }, legColor = p.dark, tail = false,
			})
			c:box(V(0.40, 0.50, 0.26), CF(0, -0.06, 0.92), C3(50, 48, 56))
			for _, s in ipairs(SIDES) do
				c:box(V(0.80, 0.70, 0.30), CF(0.92 * s, 0.84, 0), p.base)
				c:box(V(0.50, 0.44, 0.20), CF(0.92 * s, 0.82, 0.10), p.pale)
				c:box(V(0.34, 0.30, 0.50), CF(0.42 * s, -0.46, 0.86), p.base)
			end
			c:rod(V(-0.62, -0.62, 1.06), V(0.62, -0.20, 1.08), 0.04, TWIG, WOOD, false)
			c:box(V(0.46, 0.06, 0.18), CF(0.60, -0.12, 1.10) * A(0, 0, 0.6), gum)
			c:box(V(0.46, 0.06, 0.18), CF(-0.60, -0.52, 1.10) * A(0, 0, -0.5), gum)
			c:box(V(0.40, 0.06, 0.16), CF(0.16, -0.32, 1.12) * A(0, 0, -0.3), gum)
		end,
	}

	-- A tree kangaroo: round ears, big hind feet, a long tail hanging down, a joey peeking out.
	S.mw_t_kangaroo = {
		label = "Treetop Kangaroo",
		set = "mosswood",
		tint = C3(196, 120, 90),
		head = CF(0, 1.16, 0.06),
		neck = CF(0, -0.30, 0.86),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V(1.60, 1.80, 1.40),
				snout = { w = 0.44, h = 0.30, d = 0.34, y = -0.16, color = p.pale, nose = NOSE },
				eyeY = 0.24, eyeSpread = 0.36, eyeSize = V(0.34, 0.42, 0.18),
				bib = { w = 0.90, h = 0.80, y = -0.46, color = p.pale },
				legSize = V(0.40, 0.26, 0.76), legX = 0.44, legY = -0.90, legZ = { 0.16 }, legColor = p.dark, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V(0.42, 0.40, 0.20), CF(0.56 * s, 1.08, 0.02), p.dark)
				c:box(V(0.24, 0.22, 0.10), CF(0.56 * s, 1.06, 0.12), p.pale)
				c:box(V(0.26, 0.56, 0.28), CF(0.66 * s, -0.20, 0.62) * A(0.5, 0, 0.2 * s), p.base)
			end
			c:box(V(0.44, 0.44, 0.60), CF(0, -0.56, -0.90), p.base)
			c:box(V(0.38, 0.70, 0.38), CF(0, -1.00, -1.18), p.dark)
			c:box(V(0.34, 0.40, 0.34), CF(0, -1.36, -1.16), p.deep)
			c:box(V(0.44, 0.34, 0.16), CF(0, -0.44, 0.84), p.light)
			c:box(V(0.06, 0.08, 0.04), CF(-0.09, -0.40, 0.93), INK)
			c:box(V(0.06, 0.08, 0.04), CF(0.09, -0.40, 0.93), INK)
		end,
	}

	-- A potted bonsai: the pot wears the face, moss on the soil, a twisted trunk and leaf pads.
	S.mw_t_bonsai = {
		label = "Moss Bonsai",
		set = "mosswood",
		tint = C3(96, 150, 84),
		scale = 1.1,
		head = CF(0, 1.90, 0),
		neck = CF(0, -0.60, 0.80),
		back = CF(0, -0.40, -0.80),
		build = function(c, p)
			c:box(V(1.90, 0.90, 1.50), CF(0, -0.55, 0), p.deep)
			c:box(V(2.04, 0.16, 1.64), CF(0, -0.06, 0), p.dark)
			for _, x in ipairs({ -0.70, 0.70 }) do
				for _, z in ipairs({ -0.50, 0.50 }) do
					c:box(V(0.30, 0.14, 0.30), CF(x, -1.06, z), p.dark)
				end
			end
			c:eyes(-0.44, 0.78, 0.36, 0.14)
			smile(c, -0.76, 0.76, 0.30)
			blush(c, 0.66, -0.66, 0.76)
			c:box(V(1.80, 0.10, 1.40), CF(0, 0.04, 0), MOSS)
			c:ball(V(0.30, 0.20, 0.26), CF(0.66, 0.12, 0.40), C3(150, 150, 156))
			c:rod(V(0.10, 0.04, 0), V(-0.26, 0.66, 0), 0.13, TWIG, WOOD, false)
			c:ball(V(0.26, 0.26, 0.26), CF(-0.26, 0.66, 0), TWIG, WOOD)
			c:rod(V(-0.26, 0.66, 0), V(0.18, 1.12, -0.04), 0.11, TWIG, WOOD, false)
			for _, v in ipairs({ { -0.56, 0.80, 0.02, 0.90 }, { 0.56, 1.18, 0.04, 0.84 }, { 0.02, 1.52, -0.06, 0.70 } }) do
				c:box(V(v[4], 0.36, v[4] * 0.86), CF(v[1], v[2], v[3]), p.base)
				c:box(V(v[4] * 0.8, 0.08, v[4] * 0.66), CF(v[1], v[2] + 0.20, v[3]), p.light)
			end
		end,
	}

	-- =================================================================== Mythic

	-- A puffball on a mossy glade, ringed by little toadstools, spores glowing over it.
	S.mw_t_fairyring = {
		label = "Puffball Ring",
		set = "mosswood",
		tint = C3(190, 156, 220),
		head = CF(0, 0.80, 0),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.00, -0.80),
		build = function(c, p)
			c:cyl(V(0.20, 2.50, 2.50), CF(0, -0.92, 0) * A(0, 0, PI / 2), p.dark)
			c:box(V(1.20, 0.08, 0.80), CF(-0.30, -0.80, -0.50) * A(0, 0.5, 0), MOSS)
			c:ball(V(1.50, 1.40, 1.50), CF(0, -0.10, 0), p.base)
			c:box(V(0.30, 0.14, 0.30), CF(0, 0.64, 0) * A(0, PI / 4, 0), p.light)
			c:eyes(0.06, 0.70, 0.26, 0.15)
			smile(c, -0.24, 0.72, 0.24)
			blush(c, 0.44, -0.16, 0.62)
			for _, deg in ipairs({ 0, 45, 135, 180, 240, 300 }) do
				local r = math.rad(deg)
				local x, z = math.cos(r) * 1.08, math.sin(r) * 1.08
				c:box(V(0.14, 0.30, 0.14), CF(x, -0.68, z), CREAM)
				c:box(V(0.40, 0.14, 0.40), CF(x, -0.50, z), p.light)
			end
			for i, v in ipairs({ { -0.80, 0.70, 0.30 }, { 0.70, 0.90, 0.10 }, { 0.10, 1.20, -0.30 }, { -0.40, 1.40, -0.10 }, { 0.90, 0.30, 0.60 }, { -1.00, 0.10, -0.40 } }) do
				local d = i % 2 == 0 and 0.16 or 0.22
				c:ball(V(d, d, d), CF(v[1], v[2], v[3]), p.glow, NEON)
			end
			c:sparkle(p.glow, 3, 0.4, 0.18)
		end,
	}

	-- A jar of fireflies with a face on its label, moss and a twig inside, a cloth lid.
	S.mw_t_fireflyjar = {
		label = "Firefly Jar",
		set = "mosswood",
		tint = C3(244, 206, 92),
		head = CF(0, 1.50, 0),
		neck = CF(0, -0.40, 0.86),
		back = CF(0, 0.00, -0.86),
		build = function(c, p)
			local jar = c:box(V(1.60, 1.80, 1.60), CF(0, -0.10, 0), p.light, GLASS)
			jar.Transparency = 0.55
			c:box(V(1.50, 0.30, 1.50), CF(0, -0.84, 0), MOSS)
			c:rod(V(-0.40, -0.70, -0.20), V(0.36, 0.40, -0.30), 0.05, TWIG, WOOD, false)
			for _, v in ipairs({ { -0.40, 0.30, 0.10 }, { 0.36, 0.50, -0.20 }, { 0.10, -0.20, 0.30 }, { -0.30, -0.40, -0.40 }, { 0.44, -0.30, 0.20 }, { 0.00, 0.60, 0.40 } }) do
				c:ball(V(0.18, 0.18, 0.18), CF(v[1], v[2], v[3]), p.glow, NEON)
			end
			c:box(V(1.00, 0.70, 0.04), CF(0, -0.20, 0.82), CREAM)
			c:eyes(-0.10, 0.86, 0.24, 0.12)
			smile(c, -0.36, 0.85, 0.22)
			blush(c, 0.38, -0.30, 0.85)
			c:box(V(1.70, 0.14, 1.70), CF(0, 0.86, 0), p.base)
			c:box(V(1.30, 0.30, 1.30), CF(0, 1.00, 0), p.deep, WOOD)
			for _, s in ipairs(SIDES) do
				c:box(V(0.30, 0.16, 0.08), CF(0.18 * s, 0.84, 0.86) * A(0, 0, 0.4 * s), p.dark)
				c:rod(V(0.66 * s, 0.86, 0), V(0, 1.50, 0), 0.03, IRON, METAL, false)
			end
			for _, v in ipairs({ { 1.10, 0.80, 0.40 }, { -1.06, 1.20, -0.20 } }) do
				c:box(V(0.16, 0.14, 0.24), CF(v[1], v[2], v[3]), INK)
				c:ball(V(0.16, 0.16, 0.16), CF(v[1], v[2] - 0.02, v[3] - 0.18), p.glow, NEON)
			end
			c:light(p.glow, 0.8, 6)
		end,
	}

	-- A gnome with a beard of moss, a tall floppy hat and a little lantern.
	S.mw_t_gnome = {
		label = "Mossbeard Gnome",
		set = "mosswood",
		tint = C3(208, 60, 58),
		scale = 1.1,
		head = CF(0, 1.80, -0.10),
		neck = CF(0, -0.50, 0.80),
		back = CF(0, -0.10, -0.70),
		build = function(c, p)
			c:box(V(1.50, 1.30, 1.30), CF(0, -0.35, 0), p.dark)
			c:eyes(0.06, 0.68, 0.30, 0.13)
			c:ball(V(0.36, 0.32, 0.30), CF(0, -0.12, 0.74), C3(236, 162, 140))
			c:box(V(1.20, 0.70, 0.30), CF(0, -0.56, 0.66), MOSS)
			c:box(V(0.70, 0.40, 0.26), CF(0, -1.00, 0.62), MOSS)
			for _, s in ipairs(SIDES) do
				c:box(V(0.38, 0.14, 0.16), CF(0.22 * s, -0.26, 0.82) * A(0, 0, 0.3 * s), LEAF)
				c:box(V(0.30, 0.60, 0.30), CF(0.86 * s, -0.40, 0.10) * A(0, 0, 0.15 * s), p.dark)
				c:box(V(0.32, 0.26, 0.32), CF(0.92 * s, -0.78, 0.14), p.pale)
				c:box(V(0.46, 0.28, 0.60), CF(0.36 * s, -1.06, 0.08), p.deep)
			end
			c:box(V(1.66, 0.16, 1.46), CF(0, 0.38, 0), p.deep)
			c:box(V(1.30, 0.44, 1.20), CF(0, 0.66, 0), p.base)
			c:box(V(1.34, 0.10, 1.24), CF(0, 0.50, 0), p.light)
			c:box(V(0.36, 0.06, 0.20), CF(0.50, 0.58, 0.60) * A(0, 0.3, 0.5), LEAF)
			c:box(V(0.94, 0.40, 0.86), CF(0, 1.04, -0.06) * A(-0.1, 0, 0), p.base)
			c:box(V(0.56, 0.34, 0.52), CF(0, 1.38, -0.16) * A(-0.25, 0, 0.1), p.base)
			c:box(V(0.26, 0.28, 0.26), CF(0.06, 1.62, -0.30) * A(-0.4, 0, 0.2), p.light)
			c:box(V(0.24, 0.30, 0.24), CF(1.10, -0.92, 0.46), p.glow, NEON)
			c:box(V(0.36, 0.08, 0.36), CF(1.10, -0.73, 0.46), IRON, METAL)
			c:box(V(0.36, 0.08, 0.36), CF(1.10, -1.11, 0.46), IRON, METAL)
			for _, v in ipairs({ { -1.00, 0.40, 0.40 }, { 0.90, 0.90, 0.30 }, { -0.70, 1.30, -0.20 } }) do
				c:ball(V(0.16, 0.16, 0.16), CF(v[1], v[2], v[3]), p.glow, NEON)
			end
			c:light(p.glow, 0.8, 6)
		end,
	}

	-- A floating islet: a mossy glade on a rocky root, a little pine, a pond spilling over the side.
	S.mw_t_islet = {
		label = "Glade Islet",
		set = "mosswood",
		tint = C3(112, 170, 96),
		scale = 1.12,
		head = CF(0, 1.40, -0.30),
		neck = CF(0, -0.60, 0.96),
		back = CF(0, 0.00, -0.96),
		build = function(c, p)
			c:box(V(2.20, 0.40, 2.00), CF(0, 0.10, 0), p.base)
			c:box(V(2.00, 0.60, 1.80), CF(0, -0.40, 0), p.deep)
			c:box(V(1.50, 0.40, 1.30), CF(0, -0.88, 0), p.dark, SLATE)
			c:box(V(0.90, 0.36, 0.80), CF(0, -1.22, 0), p.dark, SLATE)
			c:box(V(0.40, 0.30, 0.40), CF(0, -1.50, 0), p.dark, SLATE)
			c:eyes(-0.30, 0.94, 0.36, 0.14)
			smile(c, -0.54, 0.92, 0.26)
			blush(c, 0.66, -0.46, 0.91)
			c:box(V(0.14, 0.30, 0.14), CF(-0.50, 0.44, -0.40), TWIG, WOOD)
			for i, w in ipairs({ 0.76, 0.54, 0.32 }) do
				c:box(V(w, 0.30, w), CF(-0.50, 0.62 + (i - 1) * 0.26, -0.40) * A(0, PI / 4 * i, 0), p.dark)
			end
			c:box(V(0.60, 0.06, 0.50), CF(0.46, 0.31, 0.30), C3(110, 170, 200), GLASS)
			local fall = c:box(V(0.06, 0.90, 0.36), CF(1.11, -0.24, 0.30), C3(176, 214, 232), GLASS)
			fall.Transparency = 0.3
			for _, m in ipairs({ { 0.20, -0.50, 0.30 }, { 0.70, -0.30, 0.22 } }) do
				c:box(V(0.10, 0.20, 0.10), CF(m[1], 0.40, m[2]), CREAM)
				c:box(V(m[3], 0.10, m[3]), CF(m[1], 0.54, m[2]), C3(196, 60, 50))
			end
			for _, v in ipairs({ { -1.20, 0.60, 0.40 }, { 1.10, 0.90, -0.30 }, { 0.20, 1.40, 0.50 }, { -0.80, 1.20, -0.60 } }) do
				c:ball(V(0.16, 0.16, 0.16), CF(v[1], v[2], v[3]), p.glow, NEON)
			end
			c:box(V(0.30, 0.24, 0.30), CF(-1.10, -0.90, 0.30) * A(0.4, 0.3, 0.2), p.dark, SLATE)
			c:box(V(0.22, 0.18, 0.22), CF(0.96, -1.20, -0.20) * A(0.2, 0.6, 0.4), p.dark, SLATE)
			c:box(V(0.50, 0.30, 0.08), CF(-0.70, 0.12, 1.02), MOSS)
		end,
	}

	-- A jade chrysalis hanging from a twig, gold-dotted, its new wings just peeking out.
	S.mw_t_chrysalis = {
		label = "Jade Chrysalis",
		set = "mosswood",
		tint = C3(70, 180, 140),
		scale = 1.1,
		head = CF(0, 1.30, 0.30),
		neck = CF(0, -0.60, 0.74),
		back = CF(0, 0.00, -0.70),
		build = function(c, p)
			c:cyl(V(2.20, 0.20, 0.20), CF(0, 1.56, -0.10), TWIG, WOOD)
			c:box(V(0.44, 0.06, 0.26), CF(-0.80, 1.66, -0.06) * A(0, 0.4, 0.2), LEAF)
			c:box(V(0.40, 0.06, 0.24), CF(0.84, 1.64, -0.14) * A(0, -0.5, -0.2), LEAF)
			c:box(V(0.12, 0.26, 0.12), CF(0, 1.36, -0.06), CREAM)
			c:box(V(0.80, 0.40, 0.70), CF(0, 1.08, 0), p.base)
			c:box(V(1.30, 0.56, 1.10), CF(0, 0.64, 0), p.base)
			c:box(V(1.60, 0.80, 1.36), CF(0, 0.00, 0), p.base)
			c:box(V(1.20, 0.50, 1.00), CF(0, -0.62, 0), p.light)
			c:box(V(0.60, 0.34, 0.50), CF(0, -1.02, 0), p.light)
			c:box(V(1.34, 0.10, 1.14), CF(0, 0.84, 0), GOLD, METAL)
			for _, v in ipairs({ { -0.62, 0.30, 0.70 }, { 0.62, 0.30, 0.70 }, { -0.40, -0.62, 0.51 }, { 0.40, -0.62, 0.51 } }) do
				c:ball(V(0.12, 0.12, 0.12), CF(v[1], v[2], v[3]), GOLD, NEON)
			end
			for _, s in ipairs(SIDES) do
				local wing = c:box(V(0.06, 1.20, 0.90), CF(0.86 * s, -0.04, -0.16) * A(0, 0, -0.2 * s), p.pale)
				wing.Transparency = 0.3
				c:box(V(0.04, 0.22, 0.22), CF(0.90 * s, 0.16, -0.10), p.glow, NEON)
			end
			c:eyes(0.06, 0.72, 0.30, 0.15)
			smile(c, -0.20, 0.70, 0.24)
			blush(c, 0.52, -0.12, 0.69)
			for _, v in ipairs({ { -1.00, 0.40, 0.30 }, { 1.00, -0.40, 0.20 }, { 0.70, 1.00, 0.40 } }) do
				c:ball(V(0.14, 0.14, 0.14), CF(v[1], v[2], v[3]), p.glow, NEON)
			end
			c:sparkle(p.glow, 3, 0.4, 0.18)
		end,
	}

	-- A walnut-shell galleon on a puddle: a leaf for a sail, lanterns fore and aft.
	S.mw_t_galleon = {
		label = "Walnut Galleon",
		set = "mosswood",
		tint = C3(150, 104, 60),
		scale = 1.1,
		head = CF(0, 1.90, 0),
		neck = CF(0, -0.60, 1.14),
		back = CF(0, -0.20, -1.14),
		build = function(c, p)
			c:cyl(V(0.10, 2.70, 2.70), CF(0, -1.12, 0) * A(0, 0, PI / 2), C3(120, 172, 200), GLASS)
			c:box(V(1.60, 0.70, 2.20), CF(0, -0.55, 0), p.base, WOOD)
			c:box(V(1.20, 0.30, 1.80), CF(0, -0.98, 0), p.dark, WOOD)
			for _, s in ipairs(SIDES) do
				c:box(V(0.06, 0.60, 2.00), CF(0.81 * s, -0.55, 0), p.dark, WOOD)
				c:box(V(0.16, 0.20, 0.16), CF(0.62 * s, -0.08, 0.90 * s), p.glow, NEON)
				c:box(V(0.22, 0.06, 0.22), CF(0.62 * s, 0.04, 0.90 * s), IRON, METAL)
			end
			c:eyes(-0.44, 1.14, 0.34, 0.14)
			smile(c, -0.72, 1.12, 0.28)
			blush(c, 0.58, -0.62, 1.12)
			c:rod(V(0, -0.20, -0.10), V(0, 1.70, -0.10), 0.06, TWIG, WOOD, false)
			c:box(V(1.40, 1.30, 0.08), CF(0, 0.80, 0.02) * A(0.1, 0, 0), p.light)
			c:box(V(0.06, 1.30, 0.04), CF(0, 0.80, 0.07) * A(0.1, 0, 0), p.pale)
			c:box(V(0.50, 0.04, 0.04), CF(-0.28, 0.90, 0.07) * A(0.1, 0, -0.5), p.pale)
			c:box(V(0.50, 0.04, 0.04), CF(0.28, 0.66, 0.07) * A(0.1, 0, 0.5), p.pale)
			c:box(V(0.40, 0.18, 0.04), CF(0.22, 1.74, -0.10), C3(200, 60, 60))
			c:rod(V(0, 1.66, -0.10), V(0, -0.20, 1.05), 0.02, CREAM, nil, false)
			c:rod(V(0, 1.66, -0.10), V(0, -0.20, -1.05), 0.02, CREAM, nil, false)
			for _, v in ipairs({ { -1.10, 0.60, 0.30 }, { 1.00, 1.10, -0.20 }, { 0.80, 0.30, 0.90 } }) do
				c:ball(V(0.14, 0.14, 0.14), CF(v[1], v[2], v[3]), p.glow, NEON)
			end
		end,
	}

	-- =================================================================== Divine

	-- A green man: a round, smiling face fringed with oak leaves, a halo of light behind it.
	S.mw_t_greenman = {
		label = "Greenleaf Mask",
		set = "mosswood",
		tint = C3(140, 200, 110),
		scale = 1.15,
		head = CF(0, 1.50, 0),
		neck = CF(0, -1.00, 0.40),
		back = CF(0, 0.10, -0.60),
		build = function(c, p)
			c:box(V(1.70, 1.80, 1.00), CF(0, 0.10, 0), p.base)
			for i = 0, 7 do
				local a = i * PI / 4 + PI / 8
				c:box(V(0.70, 0.40, 0.10), CF(0, 0.10, -0.10) * A(0, 0, a) * CF(1.10, 0, 0), i % 2 == 0 and p.light or p.dark)
			end
			c:box(V(0.30, 0.70, 0.10), CF(-0.40, 1.30, 0.10) * A(0, 0, 0.4), p.light)
			c:box(V(0.30, 0.76, 0.10), CF(0, 1.40, 0.12), p.light)
			c:box(V(0.30, 0.70, 0.10), CF(0.40, 1.30, 0.10) * A(0, 0, -0.4), p.light)
			for _, s in ipairs(SIDES) do
				c:box(V(0.50, 0.14, 0.10), CF(0.36 * s, 0.56, 0.52) * A(0, 0, -0.2 * s), p.dark)
				c:box(V(0.40, 0.12, 0.10), CF(0.24 * s, -0.22, 0.54) * A(0, 0, 0.4 * s), p.dark)
				c:ball(V(0.22, 0.26, 0.22), CF(0.92 * s, -0.40, 0.30), C3(170, 120, 62))
				c:rod(V(0.30 * s, -0.80, 0), V(0.50 * s, -1.30, 0.10), 0.04, LEAF, nil, false)
			end
			c:eyes(0.30, 0.54, 0.36, 0.16)
			smile(c, -0.38, 0.52, 0.50)
			blush(c, 0.60, -0.06, 0.52)
			for i = 0, 5 do
				local a = i * PI / 3
				c:ball(V(0.18, 0.18, 0.18), CF(math.cos(a) * 1.50, 0.10 + math.sin(a) * 1.50, -0.50), p.glow, NEON)
			end
			c:sparkle(p.glow, 3, 0.4, 0.18)
		end,
	}

	-- A lyrebird: a small bird under a towering lyre of a tail, its plumes tipped with light.
	S.mw_t_lyrebird = {
		label = "Lyrebird",
		set = "mosswood",
		tint = C3(206, 198, 236),
		scale = 1.2,
		head = CF(0, 0.90, 0.20),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.60, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V(1.50, 1.50, 1.50), mouth = false,
				eyeY = 0.20, eyeSpread = 0.32, eyeSize = V(0.30, 0.36, 0.16),
				legs = false, tail = false,
			})
			c:cone(V(0.20, 0.30, 0.20), CF(0, 0.00, 0.88) * A(PI / 2, 0, 0), C3(70, 62, 60))
			for _, s in ipairs(SIDES) do
				c:box(V(0.14, 0.62, 0.80), CF(0.76 * s, 0.00, -0.16) * A(0, 0, 0.12 * s), p.dark)
				c:box(V(0.10, 0.36, 0.10), CF(0.22 * s, -0.84, 0.06), p.deep)
				local a, b = V(0.18 * s, 0.30, -0.66), V(0.74 * s, 0.96, -0.86)
				local d, e = V(0.62 * s, 1.62, -0.90), V(0.92 * s, 1.98, -0.84)
				c:rod(a, b, 0.11, p.dark, nil, false)
				c:rod(b, d, 0.11, p.dark, nil, false)
				c:rod(d, e, 0.09, p.dark, nil, false)
				c:ball(V(0.22, 0.22, 0.22), CF(b), p.dark)
				c:ball(V(0.22, 0.22, 0.22), CF(d), p.dark)
				c:ball(V(0.26, 0.26, 0.26), CF(e), p.glow, NEON)
			end
			for i = -2, 2 do
				local ang = i * 0.24
				local tip = V(math.sin(ang) * 1.70, 0.30 + math.cos(ang) * 1.70, -0.80)
				c:rod(V(0, 0.30, -0.70), tip, 0.04, p.light, nil, false)
				c:ball(V(0.20, 0.20, 0.20), CF(tip), p.glow, NEON)
			end
			c:sparkle(p.glow, 3, 0.4, 0.18)
		end,
	}

	-- =================================================================== Exotic

	-- A wolpertinger: a forest bunny with little antlers and feathered wings.
	S.mw_t_wolpertinger = {
		label = "Wolpertinger",
		set = "mosswood",
		tint = C3(210, 150, 100),
		scale = 1.1,
		head = CF(0, 1.10, -0.20),
		neck = CF(0, -0.30, 0.94),
		back = CF(0, 0.40, -0.90),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.80, 1.70, 1.70),
				snout = { w = 0.40, h = 0.28, d = 0.30, y = -0.16, color = p.pale, nose = BLUSH },
				eyeY = 0.20, eyeSpread = 0.40, eyeSize = V(0.42, 0.50, 0.20),
				legSize = V(0.42, 0.28, 0.52), legX = 0.50, legY = -0.82, legColor = p.pale, tail = false,
			})
			blush(c, 0.62, -0.14, 0.86)
			c:box(V(0.40, 0.40, 0.40), CF(0, -0.10, -0.98), p.pale)
			for _, s in ipairs(SIDES) do
				c:box(V(0.34, 0.90, 0.22), CF(0.40 * s, 1.24, 0.10) * A(0, 0, -0.18 * s), p.base)
				c:box(V(0.18, 0.60, 0.10), CF(0.40 * s, 1.20, 0.20) * A(0, 0, -0.18 * s), p.pale)
				local root, mid, tine, top = V(0.22 * s, 0.84, -0.30), V(0.60 * s, 1.50, -0.36), V(0.86 * s, 1.40, -0.20), V(0.56 * s, 1.92, -0.40)
				c:rod(root, mid, 0.07, p.deep, nil, false)
				c:rod(V(0.42 * s, 1.18, -0.33), tine, 0.05, p.deep, nil, false)
				c:rod(mid, top, 0.05, p.deep, nil, false)
				c:ball(V(0.16, 0.16, 0.16), CF(tine), p.glow, NEON)
				c:ball(V(0.16, 0.16, 0.16), CF(top), p.glow, NEON)
				c:box(V(0.14, 0.70, 0.80), CF(1.00 * s, 0.30, -0.30) * A(0, 0, -0.5 * s), p.light)
				c:box(V(0.12, 0.50, 0.56), CF(1.20 * s, 0.56, -0.40) * A(0, 0, -0.8 * s), p.dark)
			end
			c:sparkle(p.glow, 3, 0.4, 0.18)
		end,
	}

	-- A shaggy sasquatch: long arms, big feet, moss and glowing mushrooms on one shoulder,
	-- a bird's nest on its head.
	S.mw_t_sasquatch = {
		label = "Shaggy Sasquatch",
		set = "mosswood",
		tint = C3(120, 86, 64),
		scale = 1.15,
		head = CF(0, 1.36, 0),
		neck = CF(0, -0.20, 0.80),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			c:box(V(1.80, 2.00, 1.40), CF(0, 0.00, 0), p.base)
			c:box(V(1.10, 0.80, 0.10), CF(0, 0.40, 0.72), p.pale)
			c:box(V(1.00, 0.14, 0.14), CF(0, 0.78, 0.74), p.dark)
			c:eyes(0.50, 0.80, 0.26, 0.13)
			c:box(V(0.22, 0.14, 0.10), CF(0, 0.30, 0.80), INK)
			smile(c, 0.12, 0.78, 0.40)
			c:box(V(0.90, 0.80, 0.08), CF(0, -0.46, 0.72), p.light)
			for _, s in ipairs(SIDES) do
				c:box(V(0.40, 0.30, 0.30), CF(0.80 * s, 0.92, 0.30) * A(0, 0, 0.5 * s), p.dark)
				c:box(V(0.30, 0.40, 0.30), CF(0.92 * s, -0.50, -0.30) * A(0, 0, 0.3 * s), p.dark)
				c:box(V(0.50, 1.40, 0.56), CF(1.10 * s, -0.20, 0.10) * A(0, 0, 0.08 * s), p.base)
				c:box(V(0.54, 0.40, 0.56), CF(1.14 * s, -1.00, 0.12), p.pale)
				c:box(V(0.66, 0.30, 0.90), CF(0.45 * s, -1.12, 0.20), p.pale)
			end
			c:box(V(0.70, 0.16, 0.70), CF(0.55, 1.04, 0), MOSS)
			c:box(V(0.10, 0.20, 0.10), CF(0.70, 1.20, -0.10), CREAM)
			c:box(V(0.30, 0.10, 0.30), CF(0.70, 1.32, -0.10), p.glow, NEON)
			c:box(V(0.08, 0.16, 0.08), CF(0.42, 1.18, 0.20), CREAM)
			c:box(V(0.22, 0.08, 0.22), CF(0.42, 1.28, 0.20), p.glow, NEON)
			c:box(V(0.80, 0.24, 0.80), CF(-0.40, 1.12, -0.10), TWIG, WOOD)
			c:ball(V(0.36, 0.34, 0.36), CF(-0.40, 1.38, -0.10), C3(120, 150, 200))
			c:cone(V(0.10, 0.14, 0.10), CF(-0.40, 1.38, 0.12) * A(PI / 2, 0, 0), C3(240, 170, 60))
			for _, v in ipairs({ { -1.30, 0.80, 0.40 }, { 1.36, 0.60, -0.20 }, { 0.10, 1.70, 0.30 } }) do
				c:ball(V(0.16, 0.16, 0.16), CF(v[1], v[2], v[3]), p.glow, NEON)
			end
		end,
	}

	-- A little dragon with fern fronds down its spine, leaf wings and twig horns.
	S.mw_t_fernscale = {
		label = "Fernscale Dragon",
		set = "mosswood",
		tint = C3(50, 150, 100),
		scale = 1.2,
		head = CF(0, 1.16, 0.30),
		neck = CF(0, -0.30, 1.10),
		back = CF(0, 0.60, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(1.90, 1.70, 1.90),
				snout = { w = 0.70, h = 0.44, d = 0.50, y = -0.24, color = p.light, nose = p.deep },
				eyeY = 0.18, eyeSpread = 0.42, eyeSize = V(0.40, 0.48, 0.18),
				bib = { w = 1.00, h = 0.70, y = -0.44, color = p.pale },
				legSize = V(0.46, 0.34, 0.52), legColor = p.dark, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:rod(V(0.36 * s, 0.84, 0.20), V(0.56 * s, 1.40, -0.04), 0.07, TWIG, WOOD, false)
				c:ball(V(0.16, 0.16, 0.16), CF(0.56 * s, 1.40, -0.04), p.glow, NEON)
				local wing = CF(0.80 * s, 0.60, -0.30) * A(0, 0, -0.7 * s) * CF(0, 0.45, 0)
				c:box(V(0.10, 1.00, 1.00), wing, p.dark)
				c:box(V(0.12, 0.84, 0.08), wing, p.glow, NEON)
			end
			for i = 0, 3 do
				c:box(V(0.08, 0.50 - i * 0.06, 0.40), CF(0, 0.98 - i * 0.03, 0.30 - i * 0.36) * A(-0.3, 0, 0), p.light)
			end
			c:box(V(0.60, 0.56, 0.60), CF(0, -0.20, -1.10), p.base)
			c:box(V(0.46, 0.46, 0.50), CF(0, 0.12, -1.46) * A(0.5, 0, 0), p.base)
			c:box(V(0.34, 0.36, 0.40), CF(0, 0.50, -1.62) * A(1.0, 0, 0), p.dark)
			c:box(V(0.10, 0.50, 0.40), CF(0, 0.84, -1.62) * A(0.3, 0, 0), p.light)
			c:sparkle(p.glow, 3, 0.4, 0.18)
		end,
	}

	-- A rhino with a hide like bark, a moss saddle, glowing lichen and an oxpecker riding along.
	S.mw_t_rhino = {
		label = "Barkhide Rhino",
		set = "mosswood",
		tint = C3(124, 128, 140),
		scale = 1.1,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.30, 1.14),
		back = CF(0, 0.50, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(2.02, 1.70, 2.00), bodyMat = WOOD,
				snout = { w = 0.80, h = 0.60, d = 0.50, y = -0.26, color = p.light, nose = p.deep },
				eyeY = 0.18, eyeSpread = 0.46, eyeSize = V(0.32, 0.38, 0.18),
				legSize = V(0.50, 0.40, 0.54), legColor = p.dark,
				tailSize = V(0.14, 0.40, 0.14),
			})
			c:cone(V(0.40, 0.76, 0.40), CF(0, 0.40, 1.24), p.pale, WOOD)
			c:cone(V(0.26, 0.40, 0.26), CF(0, 0.98, 0.80), p.pale, WOOD)
			for _, s in ipairs(SIDES) do
				c:box(V(0.26, 0.34, 0.14), CF(0.58 * s, 0.96, 0.30) * A(0, 0, -0.3 * s), p.base)
				for _, z in ipairs({ 0.20, -0.50 }) do
					c:box(V(0.10, 0.90, 0.14), CF(1.08 * s, 0.10, z), p.dark, WOOD)
				end
				c:ball(V(0.16, 0.16, 0.16), CF(1.10 * s, 0.30, -0.16), p.glow, NEON)
				c:ball(V(0.12, 0.12, 0.12), CF(1.08 * s, -0.20, -0.80), p.glow, NEON)
			end
			c:box(V(1.10, 0.14, 1.00), CF(0, 0.88, -0.40), MOSS)
			c:box(V(0.10, 0.50, 0.30), CF(-0.30, 1.16, -0.60) * A(0.2, 0, 0.3), LEAF)
			c:box(V(0.10, 0.44, 0.26), CF(-0.10, 1.14, -0.70) * A(-0.2, 0, -0.2), LEAF)
			c:box(V(0.30, 0.30, 0.44), CF(0.24, 1.10, -0.30), C3(176, 140, 100))
			c:cone(V(0.10, 0.18, 0.10), CF(0.24, 1.12, -0.02) * A(PI / 2, 0, 0), C3(232, 170, 40))
			c:sparkle(p.glow, 3, 0.4, 0.18)
		end,
	}

	-- A stone wishing well over a glowing spring: its roof, crank and bucket, coins floating up.
	S.mw_t_wishwell = {
		label = "Springstone Well",
		set = "mosswood",
		tint = C3(110, 140, 190),
		scale = 1.15,
		head = CF(0, 2.10, 0),
		neck = CF(0, -0.70, 1.04),
		back = CF(0, -0.50, -1.04),
		build = function(c, p)
			c:cyl(V(1.00, 2.00, 2.00), CF(0, -0.60, 0) * A(0, 0, PI / 2), p.base, SLATE)
			c:cyl(V(0.20, 2.14, 2.14), CF(0, 0.00, 0) * A(0, 0, PI / 2), p.light, SLATE)
			c:cyl(V(0.06, 1.60, 1.60), CF(0, 0.12, 0) * A(0, 0, PI / 2), p.glow, NEON)
			for _, b in ipairs({ { 0.9, -0.30 }, { -0.9, -0.30 }, { 2.2, -0.86 }, { -2.2, -0.86 } }) do
				c:box(V(0.40, 0.22, 0.08), A(0, b[1], 0) * CF(0, b[2], 1.01), p.dark, SLATE)
			end
			c:eyes(-0.40, 1.04, 0.34, 0.15)
			smile(c, -0.74, 1.01, 0.28)
			blush(c, 0.62, -0.62, 0.80)
			for _, s in ipairs(SIDES) do
				c:box(V(0.16, 1.40, 0.16), CF(0.94 * s, 0.70, 0), TWIG, WOOD)
				c:box(V(1.30, 0.12, 1.60), CF(0.48 * s, 1.60, 0) * A(0, 0, -0.6 * s), p.deep, WOOD)
			end
			c:box(V(0.20, 0.14, 1.64), CF(0, 1.98, 0), p.dark, WOOD)
			c:cyl(V(1.90, 0.12, 0.12), CF(0, 1.10, 0), IRON, METAL)
			c:box(V(0.08, 0.30, 0.08), CF(1.02, 0.98, 0.10), IRON, METAL)
			c:rod(V(0, 1.10, 0), V(0, 0.66, 0), 0.03, CREAM, nil, false)
			c:box(V(0.36, 0.34, 0.36), CF(0, 0.50, 0), TWIG, WOOD)
			c:box(V(0.50, 0.10, 0.30), CF(-0.70, 0.12, 0.60) * A(0, 0.8, 0), MOSS)
			c:box(V(0.40, 0.10, 0.30), CF(0.80, 0.10, -0.40) * A(0, -0.6, 0), MOSS)
			for _, v in ipairs({ { 0.40, 0.50, 0.40 }, { -0.44, 0.70, 0.20 }, { 0.20, 0.90, -0.40 } }) do
				c:cyl(V(0.04, 0.22, 0.22), CF(v[1], v[2], v[3]) * A(0, 0.6, 0.3), GOLD, METAL)
			end
			for _, v in ipairs({ { -1.20, 0.90, 0.40 }, { 1.24, 0.50, 0.50 } }) do
				c:ball(V(0.16, 0.16, 0.16), CF(v[1], v[2], v[3]), p.glow, NEON)
			end
			c:light(p.glow, 1, 8)
			c:sparkle(p.glow, 3, 0.4, 0.18)
		end,
	}

	-- A hornbill: a dark bird under a huge beak and upturned casque with a glowing stripe.
	S.mw_t_hornbill = {
		label = "Crested Hornbill",
		set = "mosswood",
		tint = C3(232, 120, 40),
		scale = 1.25,
		head = CF(0, 1.00, 0.00),
		neck = CF(0, -0.30, 0.86),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V(1.70, 1.70, 1.70), bodyColor = p.deep, shapeColor = p.deep,
				mouth = false, eyeY = 0.26, eyeSpread = 0.40, eyeSize = V(0.30, 0.38, 0.16),
				bib = { w = 1.00, h = 0.70, y = -0.40, color = CREAM },
				legs = false, tail = false,
			})
			c:box(V(0.40, 0.40, 0.80), CF(0, 0.00, 1.20), p.light)
			c:box(V(0.30, 0.28, 0.44), CF(0, -0.14, 1.70) * A(0.5, 0, 0), p.light)
			c:box(V(0.36, 0.30, 0.84), CF(0, 0.34, 1.16), p.base)
			c:box(V(0.30, 0.26, 0.32), CF(0, 0.50, 1.62) * A(-0.6, 0, 0), p.base)
			c:box(V(0.38, 0.06, 0.70), CF(0, 0.50, 1.16), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V(0.40, 0.46, 0.06), CF(0.40 * s, 0.26, 0.86), p.light)
				c:box(V(0.24, 0.05, 0.06), CF(0.40 * s, 0.52, 0.90) * A(0, 0, -0.2 * s), INK)
				c:box(V(0.16, 0.80, 1.00), CF(0.88 * s, 0.00, -0.16), p.deep)
				c:box(V(0.18, 0.12, 0.80), CF(0.89 * s, -0.24, -0.16), p.pale)
				c:box(V(0.10, 0.30, 0.10), CF(0.24 * s, -0.86, 0.10), p.dark)
				local plume = CF(0.14 * s, -0.50, -1.00) * A(-1.0, 0, 0)
				c:box(V(0.26, 0.10, 1.20), plume, p.pale)
				c:ball(V(0.24, 0.24, 0.24), plume * CF(0, 0, -0.60), p.glow, NEON)
			end
			c:box(V(0.56, 0.14, 0.16), CF(0, -0.50, -1.00) * A(-1.0, 0, 0), INK)
			for _, v in ipairs({ { -1.10, 0.80, 0.30 }, { 1.06, 1.00, -0.20 } }) do
				c:ball(V(0.14, 0.14, 0.14), CF(v[1], v[2], v[3]), p.glow, NEON)
			end
			c:sparkle(p.glow, 3, 0.4, 0.18)
		end,
	}

	return S
end
