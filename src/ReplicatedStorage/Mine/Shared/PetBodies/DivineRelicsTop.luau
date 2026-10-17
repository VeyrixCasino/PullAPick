--[[ PetBodies/DivineRelicsTop -- Divine Relics' Epic-and-up bodies. Each one is
	worn by a single pet in the whole game: sacred artifacts, ancient mechanisms and
	mythic craftsmanship come to life. See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, WHITE, METAL, NEON, GLASS, WOOD = K.INK, K.WHITE, K.METAL, K.NEON, K.GLASS, K.WOOD
	local V3, CF, ANG = Vector3.new, CFrame.new, CFrame.Angles
	local PI = math.pi
	local S = {}
	local SET = "divine_relics"

	-- Gold trim, gems, flames and blush stay fixed; each relic's own body repaints.
	local GOLD = C3(246, 204, 92)
	local GEM = C3(64, 214, 226)
	local RUBY = C3(230, 50, 90)
	local SUN = C3(255, 232, 140)
	local FLAME = C3(255, 150, 40)
	local BLUSH = C3(255, 150, 160)
	local BOLT = C3(255, 236, 80)
	local TIMBER = C3(150, 100, 60)
	local CLOUD = C3(244, 246, 255)
	local PAGE = C3(250, 240, 214)

	local UP = ANG(0, 0, PI / 2) -- stands a cylinder up (axis Y)
	local FACE = ANG(0, PI / 2, 0) -- turns a cylinder to face the front (axis Z)
	local DIAMOND = ANG(0, 0, PI / 4)

	-- Two blush marks either side of a face.
	local function cheeks(c, y, z, spread)
		for _, s in ipairs({ -1, 1 }) do
			c:box(V3(0.18, 0.09, 0.04), CF(spread * s, y, z), BLUSH)
		end
	end

	-- A small smile.
	local function smile(c, y, z, w)
		c:box(V3(w or 0.26, 0.08, 0.05), CF(0, y, z), INK)
	end

	-- A ring of n short bars round `cf`: a flat halo, or with `upright` a hoop
	-- standing in the X-Y plane and facing the front.
	local function hoop(c, cf, r, n, thick, colour, mat, upright)
		local len = 2 * PI * r / n * 1.08
		for i = 0, n - 1 do
			local a = (i + 0.5) * 2 * PI / n
			if upright then
				c:box(V3(len, thick, thick), cf * CF(math.cos(a) * r, math.sin(a) * r, 0) * ANG(0, 0, a + PI / 2), colour, mat)
			else
				c:box(V3(len, thick, thick), cf * CF(math.cos(a) * r, 0, math.sin(a) * r) * ANG(0, -(a + PI / 2), 0), colour, mat)
			end
		end
	end

	-- ===================================================================
	-- EPIC: charming, clean relics.
	-- ===================================================================

	-- A blue faience hippo statuette: a barrel body on stubby legs, a broad
	-- muzzle, little round ears, and lotus flowers painted on its flanks.
	S.dv_t_hippo = {
		label = "Faience Hippo",
		set = SET,
		tint = C3(40, 140, 230),
		head = CF(0, 1.00, 0.30),
		neck = CF(0, -0.40, 1.00),
		back = CF(0, 0.30, -0.96),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.90, 1.50, 1.90),
				eyeY = 0.30, eyeSpread = 0.46, eyeSize = V3(0.40, 0.46, 0.20),
				snout = { w = 1.30, h = 0.62, d = 0.46, y = -0.26, color = p.light, nose = p.deep },
				legSize = V3(0.50, 0.40, 0.56), legY = -0.80,
				tailSize = V3(0.20, 0.20, 0.36),
			})
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.24, 0.20, 0.18), CF(0.56 * s, 0.88, 0.50), p.deep)
				-- A painted lotus on each flank: stem, bloom and a leaf.
				c:box(V3(0.06, 0.70, 0.08), CF(0.965 * s, -0.08, 0.10), p.dark)
				c:box(V3(0.06, 0.30, 0.30), CF(0.965 * s, 0.36, 0.10) * ANG(PI / 4, 0, 0), p.pale)
				c:box(V3(0.06, 0.14, 0.40), CF(0.965 * s, -0.20, -0.20) * ANG(0.5, 0, 0), p.dark)
			end
			c:box(V3(0.40, 0.08, 0.40), CF(0, 0.85, -0.20) * ANG(0, PI / 4, 0), p.pale)
		end,
	}

	-- A pocket sphinx lying on its plinth: a striped headdress, forepaws
	-- stretched out in front and a tufted tail.
	S.dv_t_sphinx = {
		label = "Pocket Sphinx",
		set = SET,
		tint = C3(226, 186, 120),
		head = CF(0, 1.02, 0.46),
		neck = CF(0, -0.30, 1.10),
		back = CF(0, 0.40, -0.90),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V3(1.50, 1.30, 2.00),
				eyeY = 0.16, eyeSpread = 0.34, eyeSize = V3(0.38, 0.44, 0.18),
				snout = { w = 0.46, h = 0.30, d = 0.24, y = -0.18, color = p.light, nose = p.deep },
				legs = false, tail = false,
			})
			c:box(V3(1.62, 0.26, 1.00), CF(0, 0.82, 0.46), p.pale)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.24, 1.00, 0.40), CF(0.86 * s, 0.20, 0.74), p.pale)
				for _, y in ipairs({ 0.40, 0.10 }) do
					c:box(V3(0.26, 0.07, 0.42), CF(0.86 * s, y, 0.74), p.deep)
				end
				c:box(V3(0.40, 0.26, 0.70), CF(0.42 * s, -0.47, 1.20), p.base)
				c:box(V3(0.40, 0.56, 0.80), CF(0.80 * s, -0.32, -0.50), p.base)
			end
			c:box(V3(0.18, 0.18, 0.08), CF(0, 0.82, 0.98) * DIAMOND, GEM, NEON)
			c:rod(V3(0, -0.40, -1.00), V3(0.40, -0.48, -1.30), 0.07, p.dark)
			c:box(V3(0.22, 0.22, 0.22), CF(0.44, -0.48, -1.36), p.deep)
			c:box(V3(1.80, 0.20, 2.80), CF(0, -0.70, 0.20), p.dark)
		end,
	}

	-- A brass astrolabe on two little feet: a star-pointed disc with a face on
	-- its engraved plate and a hanging ring on top.
	S.dv_t_astrolabe = {
		label = "Brass Astrolabe",
		set = SET,
		tint = C3(40, 70, 190),
		head = CF(0, 1.90, 0),
		neck = CF(0, -0.50, 0.30),
		back = CF(0, 0.10, -0.30),
		build = function(c, p)
			c:cyl(V3(0.22, 2.24, 2.24), CF(0, 0.10, 0) * FACE, p.dark, METAL)
			c:cyl(V3(0.30, 2.00, 2.00), CF(0, 0.10, 0) * FACE, p.base, METAL)
			c:cyl(V3(0.04, 1.50, 1.50), CF(0, 0.10, 0.16) * FACE, p.light, METAL)
			for i = 1, 7 do
				local a = i * PI / 4
				c:box(V3(0.24, 0.24, 0.16), CF(math.sin(a) * 1.16, 0.10 + math.cos(a) * 1.16, 0) * ANG(0, 0, a + PI / 4), GOLD, METAL)
			end
			c:eyes(0.30, 0.20, 0.34, 0.15)
			c:ball(V3(0.14, 0.14, 0.14), CF(0, 0.06, 0.20), GOLD, METAL)
			smile(c, -0.16, 0.19)
			cheeks(c, -0.04, 0.19, 0.56)
			c:box(V3(0.40, 0.30, 0.24), CF(0, 1.30, 0), p.dark, METAL)
			c:cyl(V3(0.10, 0.50, 0.50), CF(0, 1.62, 0) * FACE, GOLD, METAL)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.36, 0.22, 0.40), CF(0.40 * s, -1.04, 0), p.deep, METAL)
			end
		end,
	}

	-- A chalice sprite: a goblet with its face on the cup, glowing ambrosia at
	-- the brim, ruby studs and two curled gold handles.
	S.dv_t_chalice = {
		label = "Chalice Sprite",
		set = SET,
		tint = C3(245, 190, 40),
		head = CF(0, 1.30, 0),
		neck = CF(0, 0.10, 0.86),
		back = CF(0, 0.50, -0.86),
		build = function(c, p)
			c:box(V3(1.60, 1.00, 1.60), CF(0, 0.55, 0), p.base, METAL)
			c:box(V3(1.80, 0.16, 1.80), CF(0, 1.10, 0), p.light, METAL)
			c:box(V3(1.40, 0.04, 1.40), CF(0, 1.19, 0), SUN, NEON)
			c:cone(V3(1.60, 0.40, 1.60), CF(0, -0.15, 0) * ANG(PI, 0, 0), p.base, METAL)
			c:cyl(V3(0.50, 0.30, 0.30), CF(0, -0.55, 0) * UP, p.dark, METAL)
			c:ball(V3(0.40, 0.40, 0.40), CF(0, -0.50, 0), GOLD, METAL)
			c:cyl(V3(0.16, 1.20, 1.20), CF(0, -0.86, 0) * UP, p.dark, METAL)
			c:eyes(0.66, 0.82, 0.34, 0.17)
			smile(c, 0.34, 0.81)
			cheeks(c, 0.44, 0.81, 0.58)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.08, 0.24, 0.24), CF(0.82 * s, 0.55, 0) * ANG(PI / 4, 0, 0), RUBY, NEON)
				c:rod(V3(0.80 * s, 0.85, 0), V3(1.20 * s, 0.80, 0), 0.07, GOLD, METAL, false)
				c:rod(V3(1.20 * s, 0.80, 0), V3(0.80 * s, 0.25, 0), 0.07, GOLD, METAL, false)
			end
		end,
	}

	-- A tortoise whose shell is a sundial: hour marks round a pale dial, a
	-- gold gnomon on top, and a sleepy head poking out in front.
	S.dv_t_tortoise = {
		label = "Sundial Tortoise",
		set = SET,
		tint = C3(110, 160, 60),
		head = CF(0, 1.10, -0.20),
		neck = CF(0, -0.10, 1.40),
		back = CF(0, 0.20, -1.10),
		build = function(c, p)
			c:box(V3(1.90, 0.70, 1.90), CF(0, 0.05, 0), p.base)
			c:box(V3(2.06, 0.16, 2.06), CF(0, -0.30, 0), p.dark)
			c:cyl(V3(0.10, 1.80, 1.80), CF(0, 0.45, 0) * UP, p.pale)
			for i = 0, 3 do
				local a = i * PI / 2
				c:box(V3(0.12, 0.04, 0.26), CF(math.sin(a) * 0.72, 0.51, math.cos(a) * 0.72) * ANG(0, a, 0), p.deep)
			end
			c:wedge(V3(0.10, 0.60, 0.90), CF(0, 0.80, -0.05), GOLD, METAL)
			c:box(V3(0.80, 0.70, 0.60), CF(0, 0.00, 1.20), p.light)
			c:eyes(0.14, 1.52, 0.20, 0.12)
			smile(c, -0.14, 1.51, 0.20)
			cheeks(c, -0.08, 1.51, 0.30)
			for _, s in ipairs({ -1, 1 }) do
				for _, z in ipairs({ 0.66, -0.66 }) do
					c:box(V3(0.44, 0.40, 0.44), CF(0.72 * s, -0.58, z), p.light)
				end
			end
			c:box(V3(0.22, 0.20, 0.34), CF(0, -0.30, -1.16), p.light)
		end,
	}

	-- A roof gargoyle crouched on its ledge: stubby horns, little folded bat
	-- wings, two tiny fangs and a pointed tail. More grin than growl.
	S.dv_t_gargoyle = {
		label = "Roof Gargoyle",
		set = SET,
		tint = C3(140, 120, 200),
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.40, 0.86),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V3(1.70, 1.50, 1.50),
				eyeY = 0.24, eyeSpread = 0.40, eyeSize = V3(0.44, 0.50, 0.20), brow = p.deep,
				mouthY = -0.16, mouthSize = V3(0.50, 0.12, 0.12),
				legs = false, tail = false,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:cone(V3(0.26, 0.44, 0.26), CF(0.50 * s, 1.00, 0.20) * ANG(0, 0, -0.30 * s), p.pale)
				c:box(V3(0.12, 0.80, 0.90), CF(0.96 * s, 0.40, -0.40) * ANG(0, 0, -0.45 * s), p.dark)
				c:box(V3(0.10, 0.44, 0.50), CF(1.24 * s, 0.86, -0.56) * ANG(0, 0, -0.70 * s), p.dark)
				c:box(V3(0.46, 0.60, 0.80), CF(0.70 * s, -0.62, 0.05), p.base)
				c:box(V3(0.36, 0.24, 0.40), CF(0.40 * s, -0.76, 0.86), p.light)
				c:box(V3(0.08, 0.10, 0.06), CF(0.14 * s, -0.25, 0.79), WHITE)
			end
			c:rod(V3(0, -0.40, -0.76), V3(0, -0.80, -1.10), 0.07, p.base, nil, false)
			c:cone(V3(0.24, 0.30, 0.10), CF(0, -0.92, -1.20) * ANG(PI, 0, 0), p.deep)
			c:box(V3(2.10, 0.28, 1.90), CF(0, -1.02, 0.10), p.deep)
		end,
	}

	-- A mosaic koi: a chunky fish with whisker barbels, gold and pale tiles
	-- set into its flanks, a swept dorsal fin and a split tail.
	S.dv_t_koi = {
		label = "Mosaic Koi",
		set = SET,
		tint = C3(255, 140, 40),
		head = CF(0, 1.02, 0.30),
		neck = CF(0, -0.40, 0.90),
		back = CF(0, 0.40, -1.10),
		build = function(c, p)
			c:box(V3(1.30, 1.30, 2.10), CF(0, 0.20, 0), p.base)
			c:eyes(0.40, 1.06, 0.34, 0.15)
			c:box(V3(0.34, 0.22, 0.12), CF(0, 0.00, 1.08), p.deep)
			cheeks(c, 0.12, 1.07, 0.48)
			for _, s in ipairs({ -1, 1 }) do
				c:rod(V3(0.18 * s, 0.00, 1.10), V3(0.50 * s, -0.30, 1.30), 0.03, p.pale, nil, false)
				c:box(V3(0.06, 0.34, 0.34), CF(0.665 * s, 0.50, 0.40), p.pale)
				c:box(V3(0.06, 0.34, 0.34), CF(0.665 * s, 0.05, -0.05), GOLD, METAL)
				c:box(V3(0.06, 0.34, 0.34), CF(0.665 * s, 0.50, -0.55), p.dark)
				c:box(V3(0.44, 0.08, 0.44), CF(0.80 * s, -0.24, 0.40) * ANG(0, 0, -0.40 * s), p.light)
			end
			c:wedge(V3(0.10, 0.50, 1.00), CF(0, 1.10, -0.20) * ANG(0, PI, 0), p.light)
			c:box(V3(0.10, 0.70, 0.50), CF(0, 0.55, -1.30) * ANG(-0.60, 0, 0), p.light)
			c:box(V3(0.10, 0.70, 0.50), CF(0, -0.15, -1.30) * ANG(0.60, 0, 0), p.light)
		end,
	}

	-- An oracle's mask that floats on its own: a smiling face plate, gold
	-- brows, a gem on the crest, three plumes and two trailing ribbons.
	S.dv_t_mask = {
		label = "Oracle Mask",
		set = SET,
		tint = C3(30, 200, 190),
		head = CF(0, 1.90, 0.20),
		neck = CF(0, -0.90, 0.50),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			c:box(V3(1.40, 1.30, 0.50), CF(0, 0.20, -0.02), p.dark)
			c:box(V3(1.80, 1.50, 0.36), CF(0, 0.20, 0.40), p.base)
			c:box(V3(1.90, 0.30, 0.44), CF(0, 1.00, 0.40), p.light)
			c:box(V3(1.00, 0.30, 0.36), CF(0, -0.70, 0.40), p.base)
			c:eyes(0.40, 0.60, 0.40, 0.18)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.56, 0.10, 0.08), CF(0.40 * s, 0.70, 0.60) * ANG(0, 0, 0.25 * s), GOLD, METAL)
				c:box(V3(0.18, 0.18, 0.06), CF(0.64 * s, -0.02, 0.60) * DIAMOND, p.pale)
				c:box(V3(0.10, 0.18, 0.06), CF(0.34 * s, -0.24, 0.60) * ANG(0, 0, 0.6 * s), INK)
				c:box(V3(0.14, 0.90, 0.06), CF(1.00 * s, -0.30, 0.20) * ANG(0, 0, 0.15 * s), p.deep)
			end
			c:box(V3(0.50, 0.10, 0.06), CF(0, -0.30, 0.60), INK)
			c:box(V3(0.22, 0.22, 0.08), CF(0, 1.00, 0.64) * DIAMOND, GEM, NEON)
			for i = -1, 1 do
				c:box(V3(0.18, 0.80, 0.10), CF(i * 0.42, 1.50, 0.30) * ANG(0, 0, -i * 0.35), i == 0 and p.glow or p.pale)
			end
		end,
	}

	-- A lucky coin toad: squat and wide, a square-holed coin held in its grin,
	-- three more coins stacked along its back.
	S.dv_t_toad = {
		label = "Coin Toad",
		set = SET,
		tint = C3(40, 180, 110),
		head = CF(0, 0.90, -0.10),
		neck = CF(0, -0.60, 0.96),
		back = CF(0, 0.10, -0.90),
		build = function(c, p)
			c:box(V3(1.90, 1.10, 1.70), CF(0, -0.20, 0), p.base)
			c:box(V3(1.20, 0.56, 0.06), CF(0, -0.44, 0.86), p.pale)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.50, 0.40, 0.50), CF(0.52 * s, 0.45, 0.45), p.base)
				c:eye(V3(0.52 * s, 0.48, 0.72), 0.16)
				c:box(V3(0.36, 0.40, 0.40), CF(0.62 * s, -0.70, 0.66), p.dark)
				c:box(V3(0.60, 0.50, 0.90), CF(0.96 * s, -0.55, -0.30), p.dark)
				c:box(V3(0.18, 0.09, 0.04), CF(0.74 * s, 0.10, 0.86), BLUSH)
			end
			c:box(V3(1.10, 0.07, 0.06), CF(0, 0.08, 0.87), INK)
			c:cyl(V3(0.10, 0.62, 0.62), CF(0, -0.24, 0.92) * FACE, GOLD, METAL)
			c:box(V3(0.16, 0.16, 0.04), CF(0, -0.24, 0.98), p.deep)
			for i = -1, 1 do
				c:cyl(V3(0.08, 0.40, 0.40), CF(i * 0.50, 0.39, -0.40 + math.abs(i) * 0.10) * UP, GOLD, METAL)
			end
			for _, v in ipairs({ { -0.30, 0.10 }, { 0.40, -0.80 }, { -0.70, -0.70 } }) do
				c:box(V3(0.24, 0.06, 0.24), CF(v[1], 0.37, v[2]), p.light)
			end
		end,
	}

	-- A lantern moth: a fluffy collar, feathery antennae, eyespots on its four
	-- wings, and a glowing lantern for an abdomen.
	S.dv_t_moth = {
		label = "Lantern Moth",
		set = SET,
		tint = C3(190, 240, 130),
		head = CF(0, 1.10, 0.30),
		neck = CF(0, -0.30, 0.94),
		back = CF(0, 0.60, -0.70),
		build = function(c, p)
			c:box(V3(1.10, 1.10, 1.20), CF(0, 0.30, 0.30), p.base)
			c:box(V3(1.30, 0.36, 0.90), CF(0, 0.80, 0.30), p.pale)
			c:box(V3(0.80, 0.80, 0.90), CF(0, 0.10, -0.70), p.glow, NEON)
			for _, y in ipairs({ 0.30, -0.10 }) do
				c:box(V3(0.86, 0.10, 0.96), CF(0, y, -0.70), p.dark)
			end
			c:eyes(0.40, 0.92, 0.28, 0.17)
			smile(c, 0.08, 0.91, 0.22)
			for _, s in ipairs({ -1, 1 }) do
				local wing = CF(1.00 * s, 0.70, 0.05) * ANG(0, 0.30 * s, 0.35 * s)
				c:box(V3(1.00, 0.12, 1.00), wing, p.light)
				c:box(V3(0.34, 0.04, 0.34), wing * CF(0.10 * s, 0.08, 0), p.deep)
				c:box(V3(0.70, 0.10, 0.70), CF(0.86 * s, 0.30, -0.60) * ANG(0, 0.40 * s, -0.20 * s), p.light)
				c:rod(V3(0.20 * s, 0.85, 0.80), V3(0.50 * s, 1.35, 1.00), 0.04, p.dark, nil, false)
				c:box(V3(0.12, 0.30, 0.18), CF(0.52 * s, 1.40, 1.02) * ANG(0, 0, -0.5 * s), p.dark)
				c:box(V3(0.16, 0.30, 0.16), CF(0.30 * s, -0.36, 0.50), p.dark)
			end
			c:light(SUN, 1.2, 7)
		end,
	}

	-- A crab carrying a round bronze shield for a shell: eyes up on stalks,
	-- two chunky pincers and three little legs a side.
	S.dv_t_crab = {
		label = "Shield Crab",
		set = SET,
		tint = C3(255, 110, 90),
		head = CF(0, 1.00, -0.30),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.10, -0.80),
		build = function(c, p)
			c:box(V3(1.60, 0.80, 1.30), CF(0, -0.20, 0), p.base)
			c:cyl(V3(0.18, 1.86, 1.86), CF(0, 0.34, -0.30) * UP, p.dark, METAL)
			c:cyl(V3(0.24, 1.70, 1.70), CF(0, 0.36, -0.30) * UP, p.light, METAL)
			c:cyl(V3(0.20, 0.64, 0.64), CF(0, 0.52, -0.30) * UP, GOLD, METAL)
			smile(c, -0.30, 0.66, 0.30)
			cheeks(c, -0.16, 0.66, 0.50)
			for _, s in ipairs({ -1, 1 }) do
				c:rod(V3(0.30 * s, 0.10, 0.66), V3(0.34 * s, 0.70, 0.70), 0.06, p.base, nil, false)
				c:eye(V3(0.34 * s, 0.80, 0.72), 0.15)
				c:rod(V3(0.80 * s, -0.20, 0.30), V3(1.10 * s, 0.00, 0.70), 0.08, p.base, nil, false)
				c:box(V3(0.40, 0.40, 0.36), CF(1.16 * s, 0.06, 0.86), p.light)
				c:box(V3(0.16, 0.28, 0.30), CF(1.16 * s, 0.36, 0.90) * ANG(-0.30, 0, 0), p.light)
				for _, z in ipairs({ 0.20, -0.20, -0.55 }) do
					c:box(V3(0.50, 0.10, 0.10), CF(0.98 * s, -0.52, z) * ANG(0, 0, -0.60 * s), p.dark)
				end
			end
		end,
	}

	-- A blob of sealing wax with a stamped crown on top, drips down its front,
	-- lumpy edges and two parchment ribbons trailing out.
	S.dv_t_seal = {
		label = "Wax Seal",
		set = SET,
		tint = C3(160, 20, 60),
		head = CF(0, 0.80, 0),
		neck = CF(0, -0.40, 0.90),
		back = CF(0, 0.10, -0.90),
		build = function(c, p)
			c:box(V3(1.90, 1.20, 1.70), CF(0, -0.10, 0), p.base)
			for _, v in ipairs({ { 1.00, -0.40, 0.30 }, { -1.00, -0.42, 0.20 }, { 0.80, -0.45, -0.70 }, { -0.70, -0.48, -0.80 } }) do
				c:box(V3(0.50, 0.44, 0.50), CF(v[1], v[2], v[3]), p.base)
			end
			for _, x in ipairs({ -0.50, 0.62 }) do
				c:box(V3(0.20, 0.36, 0.20), CF(x, -0.62, 0.84), p.base)
			end
			c:cyl(V3(0.08, 1.30, 1.30), CF(0, 0.54, 0) * UP, p.dark)
			c:box(V3(0.50, 0.10, 0.16), CF(0, 0.61, 0.10), p.light)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.14, 0.10, 0.40), CF(0.26 * s, 0.61, -0.10) * ANG(0, 0.5 * s, 0), p.light)
				c:box(V3(0.30, 0.06, 0.90), CF(0.40 * s, -0.72, 1.10) * ANG(0.30, 0.30 * s, 0), C3(214, 178, 90))
			end
			c:eyes(0.16, 0.86, 0.38, 0.17)
			smile(c, -0.16, 0.85)
			cheeks(c, -0.04, 0.85, 0.62)
		end,
	}

	-- A snail whose shell is a cog wheel: eight teeth round a gold hub, eyes on
	-- stalks, and a long slow foot.
	S.dv_t_snail = {
		label = "Gear Snail",
		set = SET,
		tint = C3(200, 90, 50),
		head = CF(0, 1.50, -0.25),
		neck = CF(0, -0.30, 1.20),
		back = CF(0, 0.30, -1.20),
		build = function(c, p)
			c:box(V3(0.90, 0.60, 2.20), CF(0, -0.65, 0.10), p.light)
			c:box(V3(0.90, 0.90, 0.60), CF(0, -0.10, 0.95), p.light)
			c:eyes(0.02, 1.26, 0.22, 0.13)
			smile(c, -0.30, 1.25, 0.20)
			cheeks(c, -0.22, 1.25, 0.34)
			for _, s in ipairs({ -1, 1 }) do
				c:rod(V3(0.20 * s, 0.30, 0.95), V3(0.30 * s, 0.75, 1.05), 0.05, p.light, nil, false)
				c:ball(V3(0.16, 0.16, 0.16), CF(0.30 * s, 0.78, 1.06), p.deep)
			end
			local hub = CF(0, 0.45, -0.25)
			c:cyl(V3(0.70, 1.80, 1.80), hub, p.base, METAL)
			for i = 0, 7 do
				local a = i * PI / 4
				c:box(V3(0.60, 0.26, 0.26), hub * CF(0, math.cos(a) * 0.98, math.sin(a) * 0.98) * ANG(a, 0, 0), p.dark, METAL)
			end
			c:cyl(V3(0.80, 0.60, 0.60), hub, GOLD, METAL)
		end,
	}

	-- A thunder drum: a laced barrel drum with a lightning bolt under its face
	-- and two drumsticks crossed on its head.
	S.dv_t_drum = {
		label = "Thunder Drum",
		set = SET,
		tint = C3(210, 40, 50),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.40, 0.90),
		back = CF(0, 0.10, -0.90),
		build = function(c, p)
			c:cyl(V3(1.40, 1.70, 1.70), CF(0, 0.08, 0) * UP, p.base)
			c:cyl(V3(0.08, 1.74, 1.74), CF(0, 0.81, 0) * UP, p.pale)
			for _, y in ipairs({ 0.72, -0.56 }) do
				c:cyl(V3(0.14, 1.84, 1.84), CF(0, y, 0) * UP, p.dark)
			end
			-- Zig-zag lacing round the sides and back, clear of the face.
			for i = 0, 5 do
				local a = PI * (0.30 + i * 0.233)
				local b = a + 0.20 * PI
				c:rod(V3(math.sin(a) * 0.92, 0.62, math.cos(a) * 0.92), V3(math.sin(b) * 0.92, -0.46, math.cos(b) * 0.92), 0.03, p.light, nil, false)
			end
			c:eyes(0.30, 0.86, 0.32, 0.16)
			smile(c, 0.00, 0.86)
			cheeks(c, 0.10, 0.72, 0.46)
			c:box(V3(0.12, 0.30, 0.06), CF(0.04, -0.20, 0.86) * ANG(0, 0, -0.5), BOLT, NEON)
			c:box(V3(0.12, 0.30, 0.06), CF(-0.04, -0.40, 0.86) * ANG(0, 0, -0.5), BOLT, NEON)
			for _, s in ipairs({ -1, 1 }) do
				c:rod(V3(-0.70 * s, 0.95, 0.30 * s), V3(0.50 * s, 1.15, -0.40 * s), 0.05, TIMBER, WOOD, false)
				c:ball(V3(0.18, 0.18, 0.18), CF(0.52 * s, 1.16, -0.41 * s), p.pale)
			end
		end,
	}

	-- An altar candle: wax drips down its sides, a little flame on top, stubby
	-- wax arms, standing in a gold dish with a ring handle.
	S.dv_t_candle = {
		label = "Altar Candle",
		set = SET,
		tint = C3(255, 170, 210),
		head = CF(0, 1.90, 0),
		neck = CF(0, -0.50, 0.66),
		back = CF(0, 0.10, -0.66),
		build = function(c, p)
			c:box(V3(1.20, 1.80, 1.20), CF(0, 0.10, 0), p.base)
			c:box(V3(1.30, 0.14, 1.30), CF(0, 1.00, 0), p.light)
			for _, v in ipairs({ { -0.40, 0.62, 0.50 }, { 0.30, 0.62, 0.34 } }) do
				c:box(V3(0.18, v[3], 0.06), CF(v[1], 0.95 - v[3] * 0.5, v[2]), p.light)
			end
			for _, v in ipairs({ { 0.62, 0.20, 0.60 }, { -0.62, -0.30, 0.44 } }) do
				c:box(V3(0.06, v[3], 0.18), CF(v[1], 0.95 - v[3] * 0.5, v[2]), p.light)
			end
			c:box(V3(0.08, 0.24, 0.08), CF(0, 1.18, 0), INK)
			c:cone(V3(0.40, 0.60, 0.40), CF(0, 1.56, 0), FLAME, NEON)
			c:ball(V3(0.24, 0.30, 0.24), CF(0, 1.40, 0), SUN, NEON)
			c:cyl(V3(0.20, 2.00, 2.00), CF(0, -0.86, 0) * UP, GOLD, METAL)
			c:cyl(V3(0.10, 0.50, 0.50), CF(1.16, -0.70, 0) * FACE, GOLD, METAL)
			c:eyes(0.10, 0.62, 0.30, 0.16)
			smile(c, -0.18, 0.61)
			cheeks(c, -0.06, 0.61, 0.46)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.30, 0.18, 0.18), CF(0.74 * s, -0.20, 0.10) * ANG(0, 0, 0.50 * s), p.base)
			end
			c:light(FLAME, 1.4, 8)
		end,
	}

	-- A wooden steed on a wheeled plank: a toy horse with a block mane, perky
	-- ears and a long tail, rolling along on four gold wheels.
	S.dv_t_steed = {
		label = "Wooden Steed",
		set = SET,
		tint = C3(180, 110, 60),
		head = CF(0, 1.10, 0.20),
		neck = CF(0, -0.40, 0.96),
		back = CF(0, 0.30, -0.96),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V3(1.50, 1.40, 1.70),
				eyeY = 0.22, eyeSpread = 0.38, eyeSize = V3(0.40, 0.48, 0.20),
				snout = { w = 0.80, h = 0.50, d = 0.40, y = -0.22, color = p.light, nose = p.deep },
				legSize = V3(0.34, 0.40, 0.34), legX = 0.48, legY = -0.80, legZ = { 0.50, -0.50 },
				tailSize = V3(0.24, 0.70, 0.24), tailColor = p.dark,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.24, 0.36, 0.16), CF(0.40 * s, 0.94, 0.46), p.dark)
			end
			for i = 0, 3 do
				c:box(V3(0.26, 0.26, 0.30), CF(0, 0.86, 0.56 - i * 0.36), p.dark)
			end
			c:box(V3(1.40, 0.16, 2.00), CF(0, -1.08, 0), p.deep, WOOD)
			for _, s in ipairs({ -1, 1 }) do
				for _, z in ipairs({ 0.70, -0.70 }) do
					c:cyl(V3(0.16, 0.46, 0.46), CF(0.78 * s, -1.16, z), GOLD, METAL)
				end
			end
		end,
	}

	-- A temple cat sitting tall: pointed ears, a gold earring and collar with a
	-- gem, bright eyes, and its tail curled round its paws.
	S.dv_t_cat = {
		label = "Temple Cat",
		set = SET,
		tint = C3(50, 45, 70),
		head = CF(0, 1.40, 0.10),
		neck = CF(0, -0.10, 0.74),
		back = CF(0, 0.30, -0.70),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V3(1.40, 1.90, 1.30),
				eyeY = 0.44, eyeSpread = 0.34, eyeSize = V3(0.38, 0.46, 0.18), eyeColor = C3(170, 230, 60),
				snout = { w = 0.40, h = 0.26, d = 0.20, y = 0.10, color = p.light, nose = BLUSH },
				legs = false, tail = false,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:cone(V3(0.36, 0.44, 0.30), CF(0.44 * s, 1.22, 0.10), p.base)
				c:box(V3(0.34, 0.24, 0.40), CF(0.30 * s, -0.79, 0.74), p.base)
				c:box(V3(0.36, 0.70, 0.90), CF(0.78 * s, -0.55, -0.10), p.base)
				c:box(V3(0.40, 0.03, 0.03), CF(0.42 * s, 0.10, 0.72) * ANG(0, 0, 0.12 * s), p.pale)
			end
			c:cyl(V3(0.06, 0.20, 0.20), CF(0.68, 1.06, 0.10) * FACE, GOLD, METAL)
			c:box(V3(1.50, 0.18, 1.40), CF(0, -0.06, 0), GOLD, METAL)
			c:box(V3(0.18, 0.18, 0.06), CF(0, -0.24, 0.71) * DIAMOND, GEM, NEON)
			c:rod(V3(0.50, -0.80, -0.70), V3(1.00, -0.85, 0.30), 0.08, p.dark, nil, false)
			c:rod(V3(1.00, -0.85, 0.30), V3(0.60, -0.85, 0.85), 0.08, p.dark, nil, false)
		end,
	}

	-- A living tome standing on its edge: a face on the front cover, gold
	-- corner caps and clasp, a gem, and two bookmark ribbons hanging below.
	S.dv_t_tome = {
		label = "Living Tome",
		set = SET,
		tint = C3(130, 50, 190),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.60, 0.50),
		back = CF(0, 0.10, -0.50),
		build = function(c, p)
			for _, z in ipairs({ 0.40, -0.40 }) do
				c:box(V3(1.60, 2.00, 0.12), CF(0, 0.10, z), p.base)
			end
			c:box(V3(0.14, 2.00, 0.92), CF(-0.80, 0.10, 0), p.dark)
			c:box(V3(1.50, 1.90, 0.70), CF(0.02, 0.10, 0), PAGE)
			c:eyes(0.42, 0.48, 0.34, 0.17)
			smile(c, 0.10, 0.47)
			cheeks(c, 0.26, 0.47, 0.56)
			for _, x in ipairs({ -0.70, 0.70 }) do
				for _, y in ipairs({ 1.00, -0.80 }) do
					c:box(V3(0.24, 0.24, 0.16), CF(x, y, 0.42) * DIAMOND, GOLD, METAL)
				end
			end
			c:box(V3(0.40, 0.20, 0.98), CF(0.72, 0.06, 0), GOLD, METAL)
			c:box(V3(0.24, 0.24, 0.08), CF(0, -0.40, 0.48) * DIAMOND, GEM, NEON)
			c:box(V3(0.12, 0.60, 0.04), CF(0.10, -1.10, 0.10), p.light)
			c:box(V3(0.12, 0.44, 0.04), CF(0.30, -1.02, -0.10), RUBY)
		end,
	}

	-- ===================================================================
	-- LEGENDARY: ornate relics, more trim and more pieces.
	-- ===================================================================

	-- A temple griffin: a lion's body with an eagle's hooked gold beak, a
	-- feather crest, a feathered chest and two swept wings.
	S.dv_t_griffin = {
		label = "Relic Griffin",
		set = SET,
		tint = C3(205, 130, 50),
		head = CF(0, 1.10, 0.30),
		neck = CF(0, -0.30, 0.98),
		back = CF(0, 0.40, -0.96),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.70, 1.50, 1.80),
				eyeY = 0.30, eyeSpread = 0.40, eyeSize = V3(0.40, 0.46, 0.20), brow = p.deep,
				mouth = false, bib = { w = 1.10, h = 0.60, y = -0.30, color = p.pale },
				legColor = p.dark, tailSize = V3(0.16, 0.16, 0.60), tailColor = p.dark,
			})
			c:cone(V3(0.44, 0.50, 0.30), CF(0, -0.02, 1.12) * ANG(PI / 2, 0, 0), GOLD, METAL)
			c:box(V3(0.20, 0.16, 0.14), CF(0, -0.16, 1.30), GOLD, METAL)
			for i = -1, 1 do
				c:box(V3(0.16, 0.50, 0.24), CF(i * 0.22, 0.98, 0.50 - math.abs(i) * 0.12) * ANG(-0.30, 0, -i * 0.30), i == 0 and p.light or p.pale)
			end
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.14, 0.80, 1.20), CF(0.92 * s, 0.60, -0.25) * ANG(0.30, 0, -0.35 * s), p.light)
				c:box(V3(0.12, 0.60, 0.90), CF(1.06 * s, 0.98, -0.45) * ANG(0.30, 0, -0.50 * s), p.pale)
				c:box(V3(0.10, 0.36, 0.50), CF(1.22 * s, 1.28, -0.65) * ANG(0.30, 0, -0.65 * s), GOLD, METAL)
			end
			c:box(V3(0.30, 0.30, 0.30), CF(0, -0.26, -1.36) * DIAMOND, p.deep)
			cheeks(c, 0.02, 0.92, 0.58)
		end,
	}

	-- A shrine guardian lion sitting on its plinth: a ring of curls for a
	-- mane, one paw resting on a gold ball, a bell on its collar and a curled tail.
	S.dv_t_lion = {
		label = "Shrine Lion",
		set = SET,
		tint = C3(40, 170, 120),
		head = CF(0, 1.30, 0.10),
		neck = CF(0, -0.30, 0.86),
		back = CF(0, 0.30, -0.86),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V3(1.50, 1.70, 1.40),
				eyeY = 0.36, eyeSpread = 0.36, eyeSize = V3(0.38, 0.44, 0.18), brow = p.deep,
				snout = { w = 0.70, h = 0.40, d = 0.30, y = 0.00, color = p.light, nose = p.deep },
				legs = false, tail = false,
			})
			for _, v in ipairs({ { -0.80, 0.70 }, { -0.40, 1.00 }, { 0.00, 1.06 }, { 0.40, 1.00 }, { 0.80, 0.70 }, { -0.86, 0.20 }, { 0.86, 0.20 }, { -0.80, -0.30 }, { 0.80, -0.30 } }) do
				c:box(V3(0.34, 0.34, 0.30), CF(v[1], v[2], 0.62), p.dark)
			end
			c:box(V3(0.36, 0.60, 0.40), CF(-0.40, -0.66, 0.80), p.base)
			c:box(V3(0.36, 0.36, 0.40), CF(0.42, -0.30, 0.90), p.base)
			c:ball(V3(0.46, 0.46, 0.46), CF(0.42, -0.72, 0.96), GOLD, METAL)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.40, 0.70, 0.90), CF(0.82 * s, -0.50, -0.20), p.base)
			end
			c:box(V3(0.30, 0.70, 0.24), CF(0, 0.10, -0.82), p.dark)
			c:box(V3(0.40, 0.36, 0.36), CF(0, 0.56, -0.86), p.dark)
			c:box(V3(0.80, 0.10, 0.08), CF(0, -0.32, 0.72), RUBY)
			c:ball(V3(0.18, 0.18, 0.18), CF(0, -0.44, 0.78), GOLD, METAL)
			c:box(V3(1.90, 0.24, 1.90), CF(0, -1.08, 0.10), p.deep)
			cheeks(c, 0.10, 0.72, 0.54)
		end,
	}

	-- A jackal warden sitting tall: long ears, a long muzzle, gold eyes, a
	-- broad gold-and-turquoise collar and its tail laid along the plinth.
	S.dv_t_jackal = {
		label = "Jackal Warden",
		set = SET,
		tint = C3(34, 36, 70),
		head = CF(0, 1.60, 0.10),
		neck = CF(0, -0.10, 0.70),
		back = CF(0, 0.30, -0.66),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V3(1.20, 2.00, 1.20),
				eyeY = 0.50, eyeSpread = 0.30, eyeSize = V3(0.32, 0.40, 0.18), eyeColor = C3(255, 200, 60),
				snout = { w = 0.50, h = 0.36, d = 0.60, y = 0.14, color = p.base, nose = INK },
				legs = false, tail = false,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:cone(V3(0.30, 0.70, 0.20), CF(0.36 * s, 1.40, 0.10), p.base)
				c:cone(V3(0.16, 0.44, 0.06), CF(0.36 * s, 1.34, 0.22), p.light)
				c:box(V3(0.26, 0.06, 0.24), CF(0.36 * s, 1.20, 0.10), GOLD, METAL)
				c:box(V3(0.30, 0.30, 0.50), CF(0.30 * s, -0.80, 0.74), p.base)
				c:box(V3(0.30, 0.70, 0.90), CF(0.66 * s, -0.56, -0.10), p.base)
			end
			c:box(V3(1.30, 0.14, 1.30), CF(0, -0.04, 0), GOLD, METAL)
			c:box(V3(1.28, 0.12, 1.28), CF(0, -0.18, 0), GEM)
			c:box(V3(0.26, 0.20, 0.80), CF(0.40, -0.84, -0.70) * ANG(0, 0.6, 0), p.base)
			c:box(V3(1.80, 0.30, 1.80), CF(0, -1.10, 0.10), p.pale)
			c:box(V3(1.84, 0.06, 1.84), CF(0, -0.94, 0.10), GOLD, METAL)
		end,
	}

	-- A canopic jar: a tall alabaster jar with its face on the belly, a
	-- domed lid with two little ears, a gold band and a row of painted glyphs.
	S.dv_t_canopic = {
		label = "Canopic Jar",
		set = SET,
		tint = C3(245, 230, 190),
		head = CF(0, 1.80, 0),
		neck = CF(0, -0.30, 0.76),
		back = CF(0, 0.10, -0.76),
		build = function(c, p)
			c:box(V3(1.40, 1.60, 1.40), CF(0, -0.10, 0), p.base)
			c:box(V3(1.20, 0.30, 1.20), CF(0, -1.00, 0), p.dark)
			c:box(V3(1.10, 0.20, 1.10), CF(0, 0.78, 0), p.dark)
			c:box(V3(1.30, 0.40, 1.30), CF(0, 1.06, 0), p.light)
			c:cone(V3(0.80, 0.40, 0.80), CF(0, 1.46, 0), p.light)
			c:ball(V3(0.24, 0.24, 0.24), CF(0, 1.70, 0), GOLD, METAL)
			c:eyes(0.24, 0.72, 0.34, 0.17)
			smile(c, -0.08, 0.71)
			cheeks(c, 0.04, 0.71, 0.56)
			c:box(V3(1.44, 0.12, 1.44), CF(0, -0.42, 0), GOLD, METAL)
			for i, x in ipairs({ -0.42, -0.14, 0.14, 0.42 }) do
				c:box(V3(0.16, 0.16, 0.04), CF(x, -0.68, 0.71) * (i % 2 == 0 and DIAMOND or CF()), i % 2 == 0 and p.deep or GEM)
			end
			for _, s in ipairs({ -1, 1 }) do
				c:cone(V3(0.26, 0.40, 0.16), CF(0.46 * s, 1.40, 0.10) * ANG(0, 0, -0.30 * s), p.light)
				c:box(V3(0.36, 0.20, 0.40), CF(0.40 * s, -1.22, 0.10), p.deep)
			end
		end,
	}

	-- A ram wearing the golden fleece: a crown of fleece puffs over its
	-- back, spiral horns with gold tips, a pale muzzle and a bell at its throat.
	S.dv_t_ram = {
		label = "Fleece Ram",
		set = SET,
		tint = C3(255, 214, 60),
		head = CF(0, 1.30, 0.20),
		neck = CF(0, -0.40, 0.96),
		back = CF(0, 0.50, -0.90),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.80, 1.50, 1.80),
				eyeY = 0.22, eyeSpread = 0.38, eyeSize = V3(0.38, 0.44, 0.20),
				snout = { w = 0.70, h = 0.44, d = 0.34, y = -0.24, color = p.pale, nose = BLUSH },
				legSize = V3(0.34, 0.50, 0.38), legColor = p.deep, legY = -0.80,
				tail = false,
			})
			for _, v in ipairs({ { -0.50, 0.50 }, { 0.00, 0.58 }, { 0.50, 0.50 }, { -0.46, -0.20 }, { 0.10, -0.10 }, { 0.40, -0.62 } }) do
				c:box(V3(0.56, 0.36, 0.56), CF(v[1], 0.90, v[2]), p.light)
			end
			for _, s in ipairs({ -1, 1 }) do
				c:rod(V3(0.60 * s, 0.80, 0.50), V3(1.05 * s, 0.75, 0.20), 0.13, p.dark, nil, false)
				c:rod(V3(1.05 * s, 0.75, 0.20), V3(1.10 * s, 0.25, 0.15), 0.12, p.dark, nil, false)
				c:rod(V3(1.10 * s, 0.25, 0.15), V3(1.00 * s, 0.20, 0.55), 0.10, p.dark, nil, false)
				c:ball(V3(0.22, 0.22, 0.22), CF(1.00 * s, 0.22, 0.58), GOLD, METAL)
			end
			c:box(V3(0.40, 0.40, 0.30), CF(0, 0.30, -0.98), p.light)
			c:ball(V3(0.20, 0.20, 0.20), CF(0, -0.62, 0.96), GOLD, METAL)
		end,
	}

	-- A rune anvil: a broad face plate with a horn and a heel, a narrow
	-- waist and four feet, a glowing ingot on top, sparks, and its hammer.
	S.dv_t_anvil = {
		label = "Rune Anvil",
		set = SET,
		tint = C3(100, 112, 150),
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:box(V3(1.70, 0.50, 1.10), CF(0, 0.55, 0), p.base, METAL)
			c:cone(V3(0.50, 0.70, 0.50), CF(-1.20, 0.60, 0) * ANG(0, 0, PI / 2), p.base, METAL)
			c:box(V3(0.30, 0.40, 0.90), CF(0.95, 0.60, 0), p.dark, METAL)
			c:box(V3(1.00, 0.70, 0.80), CF(0, -0.05, 0), p.dark, METAL)
			c:box(V3(1.60, 0.40, 1.20), CF(0, -0.60, 0), p.base, METAL)
			for _, s in ipairs({ -1, 1 }) do
				for _, z in ipairs({ 0.40, -0.40 }) do
					c:box(V3(0.36, 0.16, 0.36), CF(0.60 * s, -0.88, z), p.deep, METAL)
				end
			end
			c:eyes(0.58, 0.56, 0.36, 0.15)
			smile(c, 0.38, 0.56)
			cheeks(c, 0.44, 0.56, 0.62)
			c:box(V3(0.60, 0.18, 0.30), CF(0.20, 0.89, 0), FLAME, NEON)
			for _, v in ipairs({ { 0.00, 1.20, 0.10 }, { 0.40, 1.30, -0.10 }, { 0.25, 1.50, 0.15 } }) do
				c:box(V3(0.10, 0.10, 0.10), CF(v[1], v[2], v[3]) * DIAMOND, SUN, NEON)
			end
			c:box(V3(0.20, 0.20, 0.04), CF(0, -0.60, 0.61) * DIAMOND, GEM, NEON)
			c:rod(V3(1.25, -0.80, 0.30), V3(1.25, 0.36, 0.10), 0.05, TIMBER, WOOD, false)
			c:box(V3(0.30, 0.24, 0.50), CF(1.25, 0.46, 0.08), p.dark, METAL)
			c:light(FLAME, 1, 6)
		end,
	}

	-- A temple lyre: a soundbox with a face, two curved arms up to a crossbar,
	-- five glowing strings, gold finials and a music note floating above.
	S.dv_t_lyre = {
		label = "Temple Lyre",
		set = SET,
		tint = C3(250, 110, 170),
		head = CF(0, 1.80, 0),
		neck = CF(0, -0.60, 0.50),
		back = CF(0, 0.00, -0.50),
		build = function(c, p)
			c:box(V3(1.60, 1.00, 0.80), CF(0, -0.50, 0), p.base)
			c:box(V3(1.70, 0.14, 0.86), CF(0, -0.02, 0), p.dark)
			c:eyes(-0.36, 0.42, 0.34, 0.16)
			smile(c, -0.66, 0.41)
			cheeks(c, -0.54, 0.41, 0.58)
			for _, s in ipairs({ -1, 1 }) do
				c:rod(V3(0.66 * s, 0.00, 0), V3(0.90 * s, 0.70, 0), 0.12, p.light, nil, false)
				c:ball(V3(0.26, 0.26, 0.26), CF(0.90 * s, 0.70, 0), p.light)
				c:rod(V3(0.90 * s, 0.70, 0), V3(0.70 * s, 1.24, 0), 0.11, p.light, nil, false)
				c:cone(V3(0.20, 0.30, 0.20), CF(0.68 * s, 1.44, 0), GOLD, METAL)
				c:box(V3(0.36, 0.20, 0.40), CF(0.50 * s, -1.08, 0.04), p.deep)
			end
			c:box(V3(1.70, 0.16, 0.20), CF(0, 1.22, 0), p.dark)
			for i = -2, 2 do
				c:box(V3(0.04, 1.24, 0.04), CF(i * 0.18, 0.60, 0), SUN, NEON)
			end
			c:box(V3(0.20, 0.16, 0.10), CF(0.30, 1.66, 0.10), p.glow, NEON)
			c:box(V3(0.05, 0.36, 0.05), CF(0.38, 1.80, 0.10), p.glow, NEON)
		end,
	}

	-- A temple elephant: big flat ears, a trunk curling down, two little
	-- tusks, a jewelled headpiece and a gold-domed howdah on its back.
	S.dv_t_elephant = {
		label = "Howdah Elephant",
		set = SET,
		tint = C3(130, 170, 230),
		head = CF(0, 2.00, -0.10),
		neck = CF(0, -0.50, 1.00),
		back = CF(0, 0.30, -0.96),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.80, 1.50, 1.80),
				eyeY = 0.28, eyeSpread = 0.44, eyeSize = V3(0.34, 0.40, 0.18),
				mouth = false, legSize = V3(0.50, 0.50, 0.50), legY = -0.80,
				tailSize = V3(0.12, 0.40, 0.12),
			})
			c:box(V3(0.40, 0.50, 0.36), CF(0, -0.10, 1.04), p.base)
			c:box(V3(0.34, 0.44, 0.32), CF(0, -0.52, 1.14), p.base)
			c:box(V3(0.30, 0.18, 0.34), CF(0, -0.76, 1.30), p.light)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.14, 1.00, 0.90), CF(1.00 * s, 0.20, 0.30) * ANG(0, 0.35 * s, 0), p.light)
				c:cone(V3(0.12, 0.40, 0.12), CF(0.30 * s, -0.50, 1.04) * ANG(PI / 2 - 0.3, 0, 0), WHITE)
				for _, z in ipairs({ 0.40, -0.60 }) do
					c:box(V3(0.08, 0.50, 0.08), CF(0.60 * s, 1.18, z), GOLD, METAL)
				end
			end
			c:box(V3(0.44, 0.46, 0.08), CF(0, 0.64, 0.93), RUBY)
			c:box(V3(0.16, 0.16, 0.06), CF(0, 0.64, 0.98) * DIAMOND, GOLD, METAL)
			c:box(V3(1.40, 0.12, 1.20), CF(0, 0.88, -0.10), RUBY)
			c:box(V3(1.40, 0.12, 1.20), CF(0, 1.48, -0.10), p.dark)
			c:cone(V3(0.90, 0.40, 0.80), CF(0, 1.74, -0.10), GOLD, METAL)
		end,
	}

	-- A prayer crane folded from paper: a creased body, two wings raised in
	-- a V, a pointed neck and tail, sat on a gold dish with a tassel.
	S.dv_t_crane = {
		label = "Prayer Crane",
		set = SET,
		tint = C3(235, 50, 60),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.40, 0.72),
		back = CF(0, 0.30, -0.72),
		build = function(c, p)
			c:box(V3(1.20, 0.90, 1.40), CF(0, -0.10, 0), p.base)
			c:cone(V3(1.20, 0.50, 1.40), CF(0, 0.60, 0), p.light)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.90, 0.06, 1.10), CF(0.82 * s, 0.50, 0) * ANG(0, 0, 0.55 * s), p.light)
				c:box(V3(0.40, 0.07, 0.70), CF(1.32 * s, 0.80, -0.10) * ANG(0, 0, 0.55 * s), p.pale)
				c:box(V3(0.04, 0.40, 0.40), CF(0.61 * s, -0.10, 0) * ANG(PI / 4, 0, 0), p.deep)
			end
			c:box(V3(0.14, 0.90, 0.14), CF(0, 0.80, 0.80) * ANG(0.35, 0, 0), p.base)
			c:box(V3(0.12, 0.12, 0.34), CF(0, 1.25, 1.00) * ANG(0.6, 0, 0), p.dark)
			c:box(V3(0.14, 0.90, 0.14), CF(0, 0.70, -0.85) * ANG(-0.45, 0, 0), p.base)
			c:eyes(-0.05, 0.72, 0.30, 0.15)
			smile(c, -0.32, 0.71)
			cheeks(c, -0.20, 0.71, 0.44)
			c:cyl(V3(0.16, 1.40, 1.40), CF(0, -0.64, 0) * UP, GOLD, METAL)
			c:box(V3(0.06, 0.30, 0.06), CF(0, -0.90, 0.72), RUBY)
			c:ball(V3(0.14, 0.14, 0.14), CF(0, -1.08, 0.72), GOLD, METAL)
		end,
	}

	-- A moon mirror standing on its handle: a round frame with a face in the
	-- glass, gold rays round the rim, a ruby on top and a glint across it.
	S.dv_t_mirror = {
		label = "Moon Mirror",
		set = SET,
		tint = C3(180, 160, 255),
		head = CF(0, 1.80, 0),
		neck = CF(0, -0.60, 0.30),
		back = CF(0, 0.40, -0.30),
		build = function(c, p)
			c:cyl(V3(0.20, 1.90, 1.90), CF(0, 0.40, 0) * FACE, p.base, METAL)
			c:cyl(V3(0.04, 1.50, 1.50), CF(0, 0.40, 0.11) * FACE, p.pale)
			for _, i in ipairs({ 1, 2, 3, 5, 6, 7 }) do
				local a = i * PI / 4
				c:cone(V3(0.22, 0.30, 0.10), CF(math.sin(a) * 1.10, 0.40 + math.cos(a) * 1.10, 0) * ANG(0, 0, -a), GOLD, METAL)
			end
			c:box(V3(0.24, 0.24, 0.10), CF(0, 1.52, 0) * DIAMOND, RUBY, NEON)
			c:box(V3(0.10, 0.50, 0.03), CF(-0.40, 0.72, 0.14) * ANG(0, 0, -0.6), WHITE)
			c:eyes(0.56, 0.14, 0.36, 0.17)
			smile(c, 0.20, 0.14)
			cheeks(c, 0.32, 0.14, 0.58)
			c:box(V3(0.30, 0.70, 0.24), CF(0, -0.90, 0), p.dark, METAL)
			c:ball(V3(0.32, 0.32, 0.32), CF(0, -0.58, 0), GOLD, METAL)
			c:box(V3(1.00, 0.16, 0.60), CF(0, -1.26, 0), p.dark, METAL)
		end,
	}

	-- An incense burner on three legs: a round-bellied pot with ring handles,
	-- a pagoda lid with glowing vents, and three puffs of smoke rising.
	S.dv_t_censer = {
		label = "Incense Burner",
		set = SET,
		tint = C3(90, 200, 190),
		head = CF(0, 2.00, 0),
		neck = CF(0, -0.30, 0.90),
		back = CF(0, 0.10, -0.90),
		build = function(c, p)
			c:box(V3(1.70, 1.10, 1.70), CF(0, -0.10, 0), p.base, METAL)
			c:box(V3(1.84, 0.16, 1.84), CF(0, 0.50, 0), p.dark, METAL)
			c:box(V3(1.40, 0.20, 1.40), CF(0, 0.68, 0), p.light, METAL)
			c:cone(V3(1.20, 0.40, 1.20), CF(0, 0.98, 0), p.light, METAL)
			c:ball(V3(0.26, 0.26, 0.26), CF(0, 1.24, 0), GOLD, METAL)
			c:box(V3(1.74, 0.10, 1.74), CF(0, -0.50, 0), GOLD, METAL)
			for i = 0, 2 do
				local a = i * 2 * PI / 3 + PI / 3
				c:box(V3(0.30, 0.40, 0.30), CF(math.sin(a) * 0.60, -0.84, math.cos(a) * 0.60), p.dark, METAL)
			end
			for _, s in ipairs({ -1, 1 }) do
				c:cyl(V3(0.10, 0.50, 0.50), CF(0.90 * s, 0.20, 0), GOLD, METAL)
				c:box(V3(0.16, 0.10, 0.04), CF(0.30 * s, 0.68, 0.71), FLAME, NEON)
			end
			for _, v in ipairs({ { 0.18, 1.46, 0.28 }, { -0.12, 1.70, 0.22 }, { 0.10, 1.90, 0.16 } }) do
				c:ball(V3(v[3], v[3], v[3]), CF(v[1], v[2], 0), CLOUD)
			end
			c:eyes(0.06, 0.86, 0.36, 0.17)
			smile(c, -0.24, 0.86)
			cheeks(c, -0.12, 0.86, 0.60)
		end,
	}

	-- A terracotta guard: a chibi clay soldier with a topknot helmet, a gold
	-- belt over a skirt of armour plates, a round shield and a spear.
	S.dv_t_warrior = {
		label = "Terracotta Guard",
		set = SET,
		tint = C3(200, 100, 60),
		head = CF(0, 1.60, 0),
		neck = CF(0, -0.20, 0.66),
		back = CF(0, 0.20, -0.66),
		build = function(c, p)
			c:box(V3(1.30, 1.70, 1.10), CF(0, 0.10, 0), p.base)
			c:box(V3(1.40, 0.24, 1.20), CF(0, 0.98, 0), p.dark)
			c:box(V3(0.40, 0.34, 0.40), CF(0, 1.26, -0.10), p.dark)
			c:box(V3(0.12, 0.30, 0.12), CF(0, 1.50, -0.10), RUBY)
			c:eyes(0.56, 0.56, 0.30, 0.15)
			smile(c, 0.30, 0.56, 0.22)
			cheeks(c, 0.40, 0.56, 0.46)
			c:box(V3(1.40, 0.14, 1.20), CF(0, 0.10, 0), GOLD, METAL)
			for r = 0, 2 do
				c:box(V3(1.36, 0.16, 1.16), CF(0, -0.12 - r * 0.22, 0), r % 2 == 0 and p.light or p.dark)
			end
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.40, 0.26, 0.50), CF(0.34 * s, -0.88, 0.06), p.deep)
				c:box(V3(0.30, 0.70, 0.36), CF(0.80 * s, 0.00, 0.10), p.base)
				c:box(V3(0.28, 0.24, 0.30), CF(0.80 * s, -0.40, 0.14), p.light)
			end
			c:rod(V3(0.80, -0.90, 0.20), V3(0.80, 1.36, 0.20), 0.05, TIMBER, WOOD, false)
			c:cone(V3(0.16, 0.30, 0.10), CF(0.80, 1.50, 0.20), GOLD, METAL)
			c:cyl(V3(0.10, 0.80, 0.80), CF(-1.00, -0.10, 0.10), p.light)
			c:cyl(V3(0.10, 0.30, 0.30), CF(-1.07, -0.10, 0.10), GOLD, METAL)
		end,
	}

	-- ===================================================================
	-- MYTHIC: spectacular relics, glowing accents and floating bits.
	-- ===================================================================

	-- The ouroboros: a serpent curled into a standing ring, wearing a little
	-- crown, its tail tip at its mouth, a glowing world orb held inside.
	S.dv_t_ouroboros = {
		label = "Ouroboros Ring",
		set = SET,
		tint = C3(120, 220, 60),
		head = CF(0, 1.80, 0.05),
		neck = CF(0, -0.60, 0.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			hoop(c, CF(0, 0.20, 0), 1.00, 12, 0.40, p.base, nil, true)
			c:box(V3(0.70, 0.60, 0.70), CF(0, 1.20, 0.05), p.base)
			c:eyes(1.30, 0.42, 0.18, 0.12)
			smile(c, 1.08, 0.41, 0.20)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.06, 0.10, 0.04), CF(0.10 * s, 0.99, 0.42), WHITE)
			end
			c:cone(V3(0.20, 0.40, 0.20), CF(-0.50, 1.16, 0.05) * ANG(0, 0, -PI / 2), p.light)
			c:box(V3(0.50, 0.12, 0.40), CF(0, 1.56, 0.05), GOLD, METAL)
			for i = -1, 1 do
				c:cone(V3(0.14, 0.24, 0.14), CF(i * 0.18, 1.74, 0.05), p.glow, NEON)
			end
			for i = 0, 3 do
				local a = PI / 4 + i * PI / 2
				c:box(V3(0.18, 0.18, 0.06), CF(math.cos(a) * 1.00, 0.20 + math.sin(a) * 1.00, 0.22) * DIAMOND, GEM, NEON)
			end
			c:ball(V3(0.70, 0.70, 0.70), CF(0, 0.20, 0), p.glow, NEON)
			for _, v in ipairs({ { 1.40, 0.80 }, { -1.40, 0.60 }, { 1.30, -0.50 } }) do
				c:box(V3(0.14, 0.14, 0.14), CF(v[1], v[2], 0) * DIAMOND, p.glow, NEON)
			end
			c:box(V3(1.00, 0.20, 0.80), CF(0, -1.00, 0), p.dark)
			c:light(p.glow, 1.2, 8)
		end,
	}

	-- A brass orrery: a smiling sun on a stand, rays on its crown, two tilted
	-- rings carrying little planets, and a star floating overhead.
	S.dv_t_orrery = {
		label = "Brass Orrery",
		set = SET,
		tint = C3(30, 50, 150),
		head = CF(0, 1.60, 0),
		neck = CF(0, -0.40, 0.66),
		back = CF(0, 0.30, -0.66),
		build = function(c, p)
			c:box(V3(1.20, 1.20, 1.20), CF(0, 0.30, 0), p.base)
			c:eyes(0.50, 0.62, 0.30, 0.16)
			smile(c, 0.22, 0.61)
			cheeks(c, 0.32, 0.61, 0.46)
			for i = -1, 1 do
				c:cone(V3(0.26, 0.40, 0.26), CF(i * 0.40, 1.06 - math.abs(i) * 0.08, 0) * ANG(0, 0, -i * 0.4), p.glow, NEON)
			end
			local r1 = CF(0, 0.30, 0) * ANG(0.30, 0, 0.20)
			local r2 = CF(0, 0.30, 0) * ANG(0.90, 0, -0.50)
			hoop(c, r1, 1.20, 10, 0.10, GOLD, METAL, false)
			hoop(c, r2, 1.05, 8, 0.08, p.light, METAL, false)
			c:ball(V3(0.30, 0.30, 0.30), r1 * CF(math.cos(0.6) * 1.20, 0, math.sin(0.6) * 1.20), RUBY)
			c:ball(V3(0.24, 0.24, 0.24), r1 * CF(math.cos(3.6) * 1.20, 0, math.sin(3.6) * 1.20), GEM)
			c:ball(V3(0.28, 0.28, 0.28), r2 * CF(math.cos(2.2) * 1.05, 0, math.sin(2.2) * 1.05), p.deep)
			c:ball(V3(0.16, 0.16, 0.16), r2 * CF(math.cos(5.0) * 1.05, 0, math.sin(5.0) * 1.05), p.pale)
			c:rod(V3(0, -0.30, 0), V3(0, -0.90, 0), 0.10, p.dark, METAL, false)
			c:cyl(V3(0.20, 1.20, 1.20), CF(0, -1.00, 0) * UP, p.dark, METAL)
			c:box(V3(0.30, 0.30, 0.10), CF(0, 1.48, 0) * DIAMOND, SUN, NEON)
			c:light(SUN, 1.2, 8)
		end,
	}

	-- A clockwork kraken: a riveted brass dome with a glowing porthole, big
	-- eyes, six curling tentacles tipped with light and a wind-up key behind.
	S.dv_t_kraken = {
		label = "Clockwork Kraken",
		set = SET,
		tint = C3(190, 90, 220),
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			c:box(V3(1.60, 1.50, 1.50), CF(0, 0.30, 0), p.base, METAL)
			c:box(V3(1.20, 0.40, 1.10), CF(0, 1.20, 0), p.light, METAL)
			c:cyl(V3(0.08, 0.76, 0.76), CF(0, 1.40, 0) * UP, GOLD, METAL)
			c:cyl(V3(0.10, 0.60, 0.60), CF(0, 1.42, 0) * UP, p.glow, NEON)
			c:eyes(0.44, 0.76, 0.38, 0.20)
			smile(c, 0.06, 0.76)
			cheeks(c, 0.16, 0.76, 0.62)
			c:box(V3(1.66, 0.12, 1.56), CF(0, -0.20, 0), p.dark, METAL)
			for _, s in ipairs({ -1, 1 }) do
				c:ball(V3(0.12, 0.12, 0.12), CF(0.50 * s, -0.20, 0.78), GOLD, METAL)
			end
			for i = 0, 5 do
				local a = i * PI / 3 + PI / 6
				local sx, cz = math.sin(a), math.cos(a)
				local root = V3(sx * 0.60, -0.40, cz * 0.60)
				local mid = V3(sx * 1.05, -0.75, cz * 1.05)
				local tip = V3(sx * 1.25, -0.55, cz * 1.25)
				c:rod(root, mid, 0.10, p.dark, METAL, false)
				c:rod(mid, tip, 0.08, p.dark, METAL, false)
				c:box(V3(0.16, 0.16, 0.16), CF(tip) * DIAMOND, p.glow, NEON)
			end
			c:rod(V3(0, 0.40, -0.75), V3(0, 0.40, -1.05), 0.06, GOLD, METAL, false)
			c:box(V3(0.60, 0.36, 0.10), CF(0, 0.40, -1.12), GOLD, METAL)
		end,
	}

	-- The scales of fate: a pillar with its face on the base, a gold beam
	-- holding two pans on chains, a sun in one pan and a star in the other.
	S.dv_t_scales = {
		label = "Fate Scales",
		set = SET,
		tint = C3(220, 60, 120),
		head = CF(0, 1.80, 0),
		neck = CF(0, -0.70, 0.56),
		back = CF(0, -0.30, -0.56),
		build = function(c, p)
			c:box(V3(1.20, 1.00, 1.00), CF(0, -0.50, 0), p.base, METAL)
			c:box(V3(1.50, 0.20, 1.20), CF(0, -1.08, 0), p.dark, METAL)
			c:eyes(-0.34, 0.52, 0.30, 0.16)
			smile(c, -0.64, 0.51)
			cheeks(c, -0.54, 0.51, 0.48)
			c:box(V3(0.30, 1.20, 0.30), CF(0, 0.60, 0), p.light, METAL)
			c:box(V3(0.18, 0.18, 0.06), CF(0, 0.70, 0.17) * DIAMOND, GEM, NEON)
			c:box(V3(2.40, 0.14, 0.16), CF(0, 1.20, 0), GOLD, METAL)
			c:cone(V3(0.30, 0.40, 0.30), CF(0, 1.47, 0), p.glow, NEON)
			c:ball(V3(0.16, 0.16, 0.16), CF(0, 1.72, 0), GOLD, METAL)
			for _, s in ipairs({ -1, 1 }) do
				c:ball(V3(0.20, 0.20, 0.20), CF(1.20 * s, 1.20, 0), GOLD, METAL)
				c:rod(V3(1.10 * s, 1.18, 0), V3(0.86 * s, 0.30, 0.14), 0.02, GOLD, METAL, false)
				c:rod(V3(1.10 * s, 1.18, 0), V3(1.34 * s, 0.30, -0.14), 0.02, GOLD, METAL, false)
				c:cyl(V3(0.10, 0.80, 0.80), CF(1.10 * s, 0.26, 0) * UP, p.dark, METAL)
				c:box(V3(0.40, 0.20, 0.06), CF(0.30 * s, 0.95, 0) * ANG(0, 0, 0.4 * s), p.pale)
			end
			c:ball(V3(0.40, 0.40, 0.40), CF(-1.10, 0.50, 0), p.glow, NEON)
			c:box(V3(0.36, 0.36, 0.12), CF(1.10, 0.50, 0) * DIAMOND, CLOUD, NEON)
			for _, v in ipairs({ { -0.70, 1.60 }, { 0.80, 1.70 } }) do
				c:box(V3(0.12, 0.12, 0.12), CF(v[1], v[2], 0.10) * DIAMOND, p.glow, NEON)
			end
		end,
	}

	-- ===================================================================
	-- DIVINE: the holiest relics. Haloes, light and heavenly creatures.
	-- ===================================================================

	-- A votive phoenix: a round firebird with a gold beak, a crest of flame,
	-- wings raised in three tiers and three tail plumes tipped with light.
	S.dv_t_phoenix = {
		label = "Votive Phoenix",
		set = SET,
		tint = C3(255, 90, 30),
		head = CF(0, 1.60, 0.10),
		neck = CF(0, -0.30, 0.86),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V3(1.50, 1.60, 1.50),
				eyeY = 0.30, eyeSpread = 0.34, eyeSize = V3(0.36, 0.42, 0.18),
				mouth = false, bib = { w = 0.80, h = 0.50, y = -0.36, color = p.pale },
				legSize = V3(0.20, 0.30, 0.24), legX = 0.30, legZ = { 0.10 }, legColor = GOLD,
				tail = false,
			})
			c:cone(V3(0.30, 0.34, 0.24), CF(0, 0.02, 0.90) * ANG(PI / 2, 0, 0), GOLD, METAL)
			for i = -1, 1 do
				c:cone(V3(0.26, 0.60, 0.20), CF(i * 0.26, 1.10 - math.abs(i) * 0.12, 0.10) * ANG(-0.2, 0, -i * 0.35), i == 0 and p.glow or p.light, i == 0 and NEON or nil)
			end
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.70, 0.18, 0.90), CF(0.95 * s, 0.50, -0.10) * ANG(0, 0, 0.55 * s), p.base)
				c:box(V3(0.56, 0.16, 0.70), CF(1.25 * s, 0.95, -0.20) * ANG(0, 0, 0.90 * s), p.light)
				c:box(V3(0.36, 0.14, 0.44), CF(1.38 * s, 1.35, -0.30) * ANG(0, 0, 1.20 * s), p.glow, NEON)
			end
			for i = -1, 1 do
				local plume = CF(i * 0.30, -0.10, -1.10) * ANG(0.35, i * 0.30, 0)
				c:box(V3(0.20, 0.10, 0.90), plume, p.light)
				c:box(V3(0.26, 0.12, 0.30), plume * CF(0, 0, -0.56), p.glow, NEON)
			end
			c:box(V3(0.24, 0.24, 0.06), CF(0, -0.30, 0.90) * DIAMOND, FLAME, NEON)
			c:light(FLAME, 1.2, 8)
		end,
	}

	-- A cloud pegasus: a horse with a glowing mane and tail, a star on its
	-- brow, three-tier feathered wings and little clouds round its hooves.
	S.dv_t_pegasus = {
		label = "Cloud Pegasus",
		set = SET,
		tint = C3(170, 210, 255),
		head = CF(0, 1.20, 0.40),
		neck = CF(0, -0.30, 1.04),
		back = CF(0, 0.40, -0.96),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.50, 1.50, 1.90),
				eyeY = 0.30, eyeSpread = 0.36, eyeSize = V3(0.36, 0.44, 0.18),
				snout = { w = 0.70, h = 0.50, d = 0.50, y = -0.20, color = p.light, nose = p.deep },
				legSize = V3(0.34, 0.56, 0.36), legY = -0.84, legColor = p.light,
				tail = false,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:cone(V3(0.20, 0.34, 0.16), CF(0.34 * s, 0.98, 0.66), p.base)
				c:box(V3(0.14, 0.90, 1.10), CF(0.86 * s, 0.80, -0.10) * ANG(0.25, 0, -0.40 * s), p.pale)
				c:box(V3(0.12, 0.70, 0.80), CF(1.04 * s, 1.30, -0.30) * ANG(0.25, 0, -0.55 * s), p.pale)
				c:box(V3(0.10, 0.40, 0.50), CF(1.16 * s, 1.66, -0.48) * ANG(0.25, 0, -0.70 * s), p.glow, NEON)
				for _, z in ipairs({ 0.42, -0.42 }) do
					c:box(V3(0.44, 0.18, 0.46), CF(0.56 * s, -1.06, z), CLOUD)
				end
			end
			for i = 0, 3 do
				c:box(V3(0.24, 0.36, 0.30), CF(0, 0.92, 0.50 - i * 0.34), p.glow, NEON)
			end
			c:box(V3(0.24, 0.70, 0.24), CF(0, 0.20, -1.05) * ANG(-0.5, 0, 0), p.glow, NEON)
			c:box(V3(0.20, 0.50, 0.20), CF(0, -0.30, -1.20) * ANG(-0.2, 0, 0), p.glow, NEON)
			c:box(V3(0.16, 0.16, 0.06), CF(0, 0.66, 1.02) * DIAMOND, GOLD, NEON)
		end,
	}

	-- A starmap whale swimming through the sky: constellations glowing on
	-- its flanks, a pale grooved belly, a raised fluke and a spout of light.
	S.dv_t_whale = {
		label = "Starmap Whale",
		set = SET,
		tint = C3(30, 70, 190),
		head = CF(0, 1.00, 0.40),
		neck = CF(0, -0.50, 1.14),
		back = CF(0, 0.40, -1.00),
		build = function(c, p)
			c:box(V3(1.60, 1.30, 2.00), CF(0, 0.20, 0.10), p.base)
			c:box(V3(1.40, 0.40, 1.80), CF(0, -0.50, 0.15), p.pale)
			for _, x in ipairs({ -0.36, 0, 0.36 }) do
				c:box(V3(0.06, 0.06, 1.60), CF(x, -0.71, 0.15), p.light)
			end
			c:box(V3(0.90, 0.80, 0.70), CF(0, 0.30, -1.20), p.base)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.80, 0.14, 0.50), CF(0.40 * s, 0.66, -1.62) * ANG(0, 0.3 * s, 0.4 * s), p.dark)
				c:box(V3(0.60, 0.12, 0.40), CF(0.95 * s, -0.30, 0.40) * ANG(0, -0.3 * s, -0.4 * s), p.dark)
				for _, v in ipairs({ { 0.50, 0.50 }, { 0.30, 0.00 }, { 0.60, -0.40 }, { 0.10, -0.60 } }) do
					c:box(V3(0.06, 0.12, 0.12), CF(0.81 * s, v[1], v[2]) * ANG(PI / 4, 0, 0), CLOUD, NEON)
				end
			end
			c:eyes(0.34, 1.12, 0.42, 0.17)
			c:box(V3(0.80, 0.06, 0.05), CF(0, -0.10, 1.12), INK)
			cheeks(c, 0.04, 1.11, 0.62)
			c:box(V3(0.16, 0.40, 0.16), CF(0, 1.05, 0.30), p.glow, NEON)
			for _, v in ipairs({ { 0, 1.35, 0.20 }, { -0.25, 1.45, 0.16 }, { 0.25, 1.45, 0.16 } }) do
				c:ball(V3(v[3], v[3], v[3]), CF(v[1], v[2], 0.30), p.glow, NEON)
			end
		end,
	}

	-- A halo jelly drifting along: a tiered bell with a face, a frilled rim,
	-- five glowing tentacles and a gold halo floating over its crown.
	S.dv_t_jelly = {
		label = "Halo Jelly",
		set = SET,
		tint = C3(255, 120, 210),
		head = CF(0, 1.80, 0),
		neck = CF(0, -0.10, 0.92),
		back = CF(0, 0.30, -0.92),
		build = function(c, p)
			c:box(V3(1.80, 0.90, 1.80), CF(0, 0.30, 0), p.base)
			c:box(V3(1.30, 0.40, 1.30), CF(0, 0.90, 0), p.light)
			c:box(V3(0.70, 0.24, 0.70), CF(0, 1.20, 0), p.pale)
			hoop(c, CF(0, -0.18, 0), 0.88, 8, 0.20, p.dark, nil, false)
			for _, v in ipairs({ { -0.50, 0.40 }, { 0.50, 0.40 }, { -0.40, -0.40 }, { 0.40, -0.40 }, { 0.00, -0.10 } }) do
				c:box(V3(0.10, 0.50, 0.10), CF(v[1], -0.50, v[2]) * ANG(0, 0, 0.2), p.glow, NEON)
				c:box(V3(0.10, 0.40, 0.10), CF(v[1] + 0.05, -0.92, v[2]) * ANG(0, 0, -0.2), p.pale)
			end
			c:eyes(0.42, 0.92, 0.42, 0.18)
			smile(c, 0.12, 0.91)
			cheeks(c, 0.22, 0.91, 0.66)
			hoop(c, CF(0, 1.62, 0), 0.50, 8, 0.08, GOLD, NEON, false)
			c:light(p.glow, 1, 7)
		end,
	}

	-- A seraph wheel: a smiling core inside two gold rings crossed like a
	-- gyroscope, four little wings behind and a glowing gem on top.
	S.dv_t_wheel = {
		label = "Seraph Wheel",
		set = SET,
		tint = C3(255, 210, 40),
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.40, 0.62),
		back = CF(0, 0.20, -0.62),
		build = function(c, p)
			c:box(V3(1.10, 1.10, 1.10), CF(0, 0.20, 0), p.base)
			c:eyes(0.36, 0.56, 0.26, 0.15)
			smile(c, 0.06, 0.56, 0.22)
			cheeks(c, 0.16, 0.56, 0.42)
			hoop(c, CF(0, 0.20, 0) * ANG(0, -PI / 4, 0), 1.15, 10, 0.14, GOLD, METAL, true)
			hoop(c, CF(0, 0.20, 0) * ANG(0, PI / 4, 0), 1.15, 10, 0.14, p.light, METAL, true)
			for _, s in ipairs({ -1, 1 }) do
				for _, t in ipairs({ -1, 1 }) do
					c:box(V3(0.70, 0.36, 0.10), CF(0.90 * s, 0.20 + 0.66 * t, -0.40) * ANG(0, 0, 0.5 * s * t), p.pale)
				end
			end
			c:box(V3(0.22, 0.22, 0.22), CF(0, 1.50, 0) * DIAMOND, p.glow, NEON)
			c:light(SUN, 1, 7)
		end,
	}

	-- A winged sun disc: a smiling sun with glowing rays, a gold crest and a
	-- ruby on top, three rows of feathers to each side and a feathered tail.
	S.dv_t_sundisc = {
		label = "Winged Sun Disc",
		set = SET,
		tint = C3(255, 150, 0),
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.60, 0.40),
		back = CF(0, 0.30, -0.40),
		build = function(c, p)
			c:cyl(V3(0.50, 1.50, 1.50), CF(0, 0.30, 0) * FACE, p.base)
			c:cyl(V3(0.10, 1.10, 1.10), CF(0, 0.30, 0.26) * FACE, p.light)
			c:eyes(0.46, 0.33, 0.30, 0.15)
			smile(c, 0.14, 0.33)
			cheeks(c, 0.24, 0.33, 0.40)
			for _, a in ipairs({ PI / 4, 3 * PI / 4, 5 * PI / 4, 7 * PI / 4 }) do
				c:cone(V3(0.20, 0.34, 0.14), CF(math.sin(a) * 0.95, 0.30 + math.cos(a) * 0.95, 0) * ANG(0, 0, -a), p.glow, NEON)
			end
			c:cone(V3(0.30, 0.40, 0.20), CF(0, 1.24, 0), GOLD, METAL)
			c:ball(V3(0.16, 0.16, 0.16), CF(0, 1.50, 0), RUBY)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.70, 0.36, 0.16), CF(0.95 * s, 0.42, -0.05) * ANG(0, 0, 0.15 * s), p.light)
				c:box(V3(0.64, 0.26, 0.14), CF(0.98 * s, 0.14, -0.05) * ANG(0, 0, 0.10 * s), p.pale)
				c:box(V3(0.50, 0.20, 0.12), CF(0.94 * s, -0.08, -0.05) * ANG(0, 0, 0.05 * s), p.dark)
				c:box(V3(0.30, 0.30, 0.12), CF(1.36 * s, 0.56, -0.05) * ANG(0, 0, 0.5 * s), GOLD, METAL)
			end
			for i = -1, 1 do
				c:box(V3(0.18, 0.50, 0.10), CF(i * 0.22, -0.66, -0.05) * ANG(0, 0, i * 0.3), i == 0 and p.light or p.pale)
			end
			c:light(SUN, 1.5, 9)
		end,
	}

	-- A dream crescent: a smiling crescent moon in a nightcap with a glowing
	-- pom-pom, resting on a cloud with stars twinkling beside it.
	S.dv_t_crescent = {
		label = "Dream Crescent",
		set = SET,
		tint = C3(250, 235, 140),
		head = CF(0.20, 1.90, 0),
		neck = CF(-0.60, -0.30, 0.44),
		back = CF(-0.40, 0.30, -0.44),
		build = function(c, p)
			for _, deg in ipairs({ 110, 135, 158, 180, 202, 225, 250 }) do
				local th = math.rad(deg)
				local t = 0.25 + 0.50 * math.cos(th - PI)
				c:box(V3(t, 0.48, 0.80), CF(0.35 + math.cos(th) * 0.95, 0.30 + math.sin(th) * 0.95, 0) * ANG(0, 0, th), p.base)
			end
			c:eye(V3(-0.80, 0.50, 0.42), 0.13)
			c:eye(V3(-0.46, 0.50, 0.42), 0.13)
			c:box(V3(0.20, 0.07, 0.05), CF(-0.63, 0.24, 0.42), INK)
			for _, x in ipairs({ -0.90, -0.36 }) do
				c:box(V3(0.14, 0.08, 0.04), CF(x, 0.30, 0.41), BLUSH)
			end
			c:cone(V3(0.50, 0.70, 0.50), CF(0.20, 1.40, 0) * ANG(0, 0, -0.6), p.deep)
			c:ball(V3(0.24, 0.24, 0.24), CF(0.42, 1.72, 0), p.glow, NEON)
			c:box(V3(1.40, 0.40, 0.90), CF(0.10, -0.95, 0), CLOUD)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.60, 0.36, 0.60), CF(0.10 + 0.75 * s, -0.88, 0.10), CLOUD)
			end
			for _, v in ipairs({ { 0.70, 0.60, 0.26 }, { 0.98, 0.10, 0.20 }, { 0.62, -0.25, 0.16 }, { -1.10, 1.00, 0.14 }, { 1.05, 0.95, 0.12 } }) do
				c:box(V3(v[3], v[3], 0.08), CF(v[1], v[2], 0) * DIAMOND, p.glow, NEON)
			end
			c:light(p.glow, 1, 7)
		end,
	}

	-- A shrine fox: a fox with tall ears and a glowing brow mark, a bell at
	-- its chest and nine tails fanned out behind it, every other one alight.
	S.dv_t_fox = {
		label = "Shrine Fox",
		set = SET,
		tint = C3(140, 60, 220),
		head = CF(0, 1.30, 0.30),
		neck = CF(0, -0.30, 0.86),
		back = CF(0, 1.30, -1.00),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.50, 1.40, 1.60),
				eyeY = 0.22, eyeSpread = 0.36, eyeSize = V3(0.38, 0.44, 0.18),
				snout = { w = 0.50, h = 0.36, d = 0.50, y = -0.24, color = p.pale, nose = INK },
				bib = { w = 0.80, h = 0.40, y = -0.45, color = p.pale },
				legSize = V3(0.30, 0.40, 0.32), legColor = p.dark, tail = false,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:cone(V3(0.36, 0.56, 0.24), CF(0.44 * s, 1.02, 0.30) * ANG(0, 0, -0.2 * s), p.base)
				c:cone(V3(0.20, 0.34, 0.08), CF(0.44 * s, 0.98, 0.43) * ANG(0, 0, -0.2 * s), p.pale)
			end
			c:box(V3(0.14, 0.28, 0.06), CF(0, 0.62, 0.82), p.glow, NEON)
			c:ball(V3(0.18, 0.18, 0.18), CF(0, -0.70, 0.88), GOLD, METAL)
			local root = V3(0, 0.20, -0.80)
			for i = 0, 8 do
				local a = -1.20 + i * 0.30
				local rot = ANG(-0.45, 0, -a)
				local dir = rot * V3(0, 1, 0)
				c:box(V3(0.28, 1.00, 0.28), CF(root + dir * 0.55) * rot, i % 2 == 0 and p.light or p.base)
				if i % 2 == 0 then
					c:box(V3(0.24, 0.24, 0.24), CF(root + dir * 1.08) * rot, p.glow, NEON)
				end
			end
		end,
	}

	-- A comet seahorse standing tall: a long snout, a gold coronet, belly
	-- plates, a glowing dorsal fin, a curled tail and a trail of stars.
	S.dv_t_seahorse = {
		label = "Comet Seahorse",
		set = SET,
		tint = C3(0, 200, 180),
		head = CF(0, 1.60, 0),
		neck = CF(0, -0.20, 0.60),
		back = CF(0, 0.40, -0.74),
		build = function(c, p)
			c:box(V3(1.10, 1.40, 1.00), CF(0, 0.30, 0), p.base)
			c:box(V3(0.90, 0.60, 0.80), CF(0, -0.60, -0.10), p.base)
			c:box(V3(0.60, 0.36, 0.50), CF(0, -0.96, -0.40), p.dark)
			c:box(V3(0.40, 0.40, 0.40), CF(0, -0.98, -0.86), p.dark)
			c:box(V3(0.30, 0.30, 0.30), CF(0, -0.70, -0.98), p.dark)
			for _, y in ipairs({ 0.00, -0.22, -0.44 }) do
				c:box(V3(0.66, 0.10, 0.06), CF(0, y, y < -0.30 and 0.32 or 0.52), p.pale)
			end
			c:eyes(0.62, 0.52, 0.28, 0.15)
			cheeks(c, 0.38, 0.52, 0.42)
			c:box(V3(0.30, 0.26, 0.50), CF(0, 0.32, 0.72), p.light)
			c:box(V3(0.36, 0.32, 0.10), CF(0, 0.32, 0.98), p.dark)
			c:box(V3(0.70, 0.14, 0.60), CF(0, 1.07, 0), GOLD, METAL)
			for i = -1, 1 do
				c:cone(V3(0.16, 0.30, 0.16), CF(i * 0.24, 1.29, 0), i == 0 and p.glow or GOLD, i == 0 and NEON or METAL)
			end
			c:box(V3(0.10, 0.80, 0.40), CF(0, 0.30, -0.62), p.glow, NEON)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.06, 0.34, 0.34), CF(0.58 * s, 0.56, -0.10) * ANG(PI / 4, 0, 0), p.light)
			end
			for _, v in ipairs({ { 0.30, 1.20, -0.70, 0.24 }, { 0.55, 1.45, -1.00, 0.18 }, { 0.75, 1.65, -1.25, 0.12 } }) do
				c:box(V3(v[4], v[4], v[4]), CF(v[1], v[2], v[3]) * DIAMOND, p.glow, NEON)
			end
		end,
	}

	-- An astral stag: a slender deer with gold antlers tipped in starlight,
	-- a dappled back and a star floating between its antlers.
	S.dv_t_stag = {
		label = "Astral Stag",
		set = SET,
		tint = C3(150, 100, 60),
		head = CF(0, 1.95, 0.20),
		neck = CF(0, -0.30, 0.96),
		back = CF(0, 0.40, -0.96),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.40, 1.40, 1.80),
				eyeY = 0.24, eyeSpread = 0.36, eyeSize = V3(0.38, 0.44, 0.18),
				snout = { w = 0.56, h = 0.40, d = 0.34, y = -0.24, color = p.pale, nose = INK },
				legSize = V3(0.26, 0.60, 0.28), legX = 0.46, legY = -0.84, legColor = p.dark,
				tailSize = V3(0.26, 0.30, 0.20), tailColor = p.pale,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.36, 0.16, 0.20), CF(0.62 * s, 0.70, 0.50) * ANG(0, 0, -0.35 * s), p.base)
				c:rod(V3(0.30 * s, 0.76, 0.40), V3(0.62 * s, 1.40, 0.30), 0.06, GOLD, METAL, false)
				c:rod(V3(0.45 * s, 1.05, 0.36), V3(0.20 * s, 1.40, 0.50), 0.05, GOLD, METAL, false)
				c:rod(V3(0.62 * s, 1.40, 0.30), V3(0.95 * s, 1.62, 0.20), 0.05, GOLD, METAL, false)
				c:rod(V3(0.62 * s, 1.40, 0.30), V3(0.55 * s, 1.80, 0.25), 0.05, GOLD, METAL, false)
				for _, t in ipairs({ { 0.20, 1.40, 0.50 }, { 0.95, 1.62, 0.20 }, { 0.55, 1.80, 0.25 } }) do
					c:box(V3(0.14, 0.14, 0.14), CF(t[1] * s, t[2], t[3]) * DIAMOND, p.glow, NEON)
				end
			end
			for _, v in ipairs({ { 0.30, -0.20 }, { -0.30, -0.20 }, { 0.20, -0.60 }, { -0.20, -0.60 } }) do
				c:box(V3(0.18, 0.06, 0.18), CF(v[1], 0.78, v[2]), p.pale)
			end
			c:box(V3(0.30, 0.30, 0.10), CF(0, 1.65, 0.30) * DIAMOND, SUN, NEON)
		end,
	}

	-- A pearl wyrmling: a little sky dragon whose body winds back in coils,
	-- with gold horns and whiskers, glowing spines, and a pearl in its claw.
	S.dv_t_wyrm = {
		label = "Pearl Wyrmling",
		set = SET,
		tint = C3(40, 200, 90),
		head = CF(0, 1.30, 0.60),
		neck = CF(0, -0.30, 1.30),
		back = CF(0.10, 0.90, -0.75),
		build = function(c, p)
			c:box(V3(1.20, 1.10, 1.00), CF(0, 0.30, 0.70), p.base)
			c:box(V3(0.80, 0.40, 0.30), CF(0, 0.08, 1.32), p.light)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.08, 0.08, 0.04), CF(0.18 * s, 0.18, 1.48), INK)
				c:rod(V3(0.36 * s, 0.10, 1.40), V3(0.86 * s, 0.30, 1.55), 0.025, GOLD, METAL, false)
				c:cone(V3(0.20, 0.50, 0.20), CF(0.36 * s, 1.05, 0.50) * ANG(-0.4, 0, -0.2 * s), GOLD, METAL)
			end
			c:eyes(0.56, 1.22, 0.30, 0.15)
			cheeks(c, 0.34, 1.21, 0.50)
			c:box(V3(0.90, 0.80, 0.80), CF(0.35, 0.00, -0.10), p.base)
			c:box(V3(0.80, 0.70, 0.70), CF(0.10, 0.45, -0.75), p.base)
			c:box(V3(0.60, 0.56, 0.60), CF(-0.35, 0.15, -1.15), p.base)
			c:cone(V3(0.40, 0.50, 0.30), CF(-0.62, 0.40, -1.32) * ANG(0, 0, 0.8), p.light)
			for _, v in ipairs({ { 0, 0.92, 0.30 }, { 0.35, 0.47, -0.10 }, { 0.10, 0.87, -0.75 }, { -0.35, 0.50, -1.15 } }) do
				c:cone(V3(0.22, 0.28, 0.22), CF(v[1], v[2], v[3]), p.glow, NEON)
			end
			c:box(V3(0.26, 0.36, 0.26), CF(-0.45, -0.36, 0.80), p.dark)
			c:box(V3(0.26, 0.30, 0.30), CF(0.50, -0.30, 1.05), p.dark)
			c:ball(V3(0.44, 0.44, 0.44), CF(0.55, -0.62, 1.20), CLOUD, NEON)
			for _, x in ipairs({ 0.40, -0.20 }) do
				c:box(V3(0.24, 0.30, 0.24), CF(x, -0.05, -0.75), p.dark)
			end
			c:box(V3(1.40, 0.30, 1.00), CF(0, -0.95, -0.10), CLOUD)
			c:box(V3(0.80, 0.30, 0.70), CF(0.50, -0.88, 0.70), CLOUD)
			c:light(CLOUD, 1, 6)
		end,
	}

	-- A lotus throne floating on its pad: two rings of petals round a smiling
	-- seed pod, glowing seeds on top and a gold halo hovering over it.
	S.dv_t_lotus = {
		label = "Lotus Throne",
		set = SET,
		tint = C3(255, 190, 150),
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.10, -0.80),
		build = function(c, p)
			c:cyl(V3(0.14, 2.20, 2.20), CF(0, -0.80, 0) * UP, p.dark)
			for i = 0, 7 do
				local a = i * PI / 4
				c:box(V3(0.50, 0.70, 0.16), CF(math.sin(a) * 0.80, -0.38, math.cos(a) * 0.80) * ANG(0, a, 0) * ANG(0.6, 0, 0), p.light)
			end
			for i = 1, 5 do
				local a = i * PI / 3
				c:box(V3(0.44, 0.80, 0.14), CF(math.sin(a) * 0.72, 0.10, math.cos(a) * 0.72) * ANG(0, a, 0) * ANG(0.30, 0, 0), p.base)
			end
			c:box(V3(0.90, 0.90, 0.90), CF(0, 0.20, 0), p.pale)
			c:eyes(0.38, 0.47, 0.24, 0.14)
			smile(c, 0.10, 0.46, 0.22)
			cheeks(c, 0.20, 0.46, 0.36)
			for _, v in ipairs({ { -0.22, 0.10 }, { 0.22, 0.10 }, { 0, -0.22 } }) do
				c:box(V3(0.16, 0.06, 0.16), CF(v[1], 0.67, v[2]), p.glow, NEON)
			end
			hoop(c, CF(0, 1.15, 0), 0.45, 8, 0.07, GOLD, NEON, false)
			c:light(p.glow, 1, 7)
		end,
	}

	-- A thunder nimbus: a fluffy storm cloud with a smile, a dark underside,
	-- two zig-zag lightning bolts, raindrops and a halo above.
	S.dv_t_nimbus = {
		label = "Thunder Nimbus",
		set = SET,
		tint = C3(90, 110, 170),
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.40, 0.74),
		back = CF(0, 0.40, -0.74),
		build = function(c, p)
			c:box(V3(1.80, 1.10, 1.40), CF(0, 0.20, 0), p.base)
			c:box(V3(1.00, 0.90, 1.10), CF(-0.55, 0.80, -0.05), p.light)
			c:box(V3(1.10, 1.00, 1.10), CF(0.45, 0.90, 0), p.light)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.70, 0.70, 0.90), CF(1.05 * s, 0.10, 0), p.base)
				c:box(V3(0.14, 0.40, 0.10), CF(0.40 * s, -0.74, 0.20) * ANG(0, 0, 0.5), BOLT, NEON)
				c:box(V3(0.14, 0.40, 0.10), CF(0.40 * s, -1.04, 0.20) * ANG(0, 0, -0.5), BOLT, NEON)
			end
			c:box(V3(1.70, 0.30, 1.30), CF(0, -0.40, 0), p.dark)
			c:eyes(0.30, 0.72, 0.36, 0.17)
			smile(c, -0.02, 0.71)
			cheeks(c, 0.08, 0.71, 0.62)
			for _, v in ipairs({ { 0.00, -0.80, 0.30 }, { -0.80, -0.70, -0.20 } }) do
				c:box(V3(0.10, 0.16, 0.10), CF(v[1], v[2], v[3]), GEM, NEON)
			end
			hoop(c, CF(0, 1.55, 0) * ANG(0.2, 0, 0), 0.50, 8, 0.07, GOLD, NEON, false)
		end,
	}

	-- A dawn prism: a floating crystal with a face on its band, a ring of
	-- light round it, shards drifting nearby and a rainbow spilling out.
	S.dv_t_prism = {
		label = "Dawn Prism",
		set = SET,
		tint = C3(120, 240, 255),
		head = CF(0, 1.90, 0),
		neck = CF(0, -0.40, 0.66),
		back = CF(0, 0.20, -0.66),
		build = function(c, p)
			c:box(V3(1.20, 0.60, 1.20), CF(0, 0.20, 0), p.base)
			c:cone(V3(1.20, 1.00, 1.20), CF(0, 1.00, 0), p.light)
			c:cone(V3(1.20, 1.00, 1.20), CF(0, -0.60, 0) * ANG(PI, 0, 0), p.dark)
			c:eyes(0.30, 0.62, 0.30, 0.15)
			smile(c, 0.06, 0.61, 0.22)
			cheeks(c, 0.12, 0.61, 0.46)
			hoop(c, CF(0, 0.20, 0) * ANG(0.35, 0, 0), 1.20, 10, 0.06, p.glow, NEON, false)
			for k, col in ipairs({ RUBY, SUN, GEM }) do
				c:box(V3(0.70, 0.08, 0.08), CF(1.00, -0.40 - k * 0.12, 0.10) * ANG(0, 0, -0.25 - k * 0.12), col, NEON)
			end
			c:cone(V3(0.24, 0.40, 0.24), CF(-1.20, 0.80, 0.10) * ANG(0, 0, 0.3), p.pale)
			c:cone(V3(0.20, 0.34, 0.20), CF(1.10, 1.00, -0.20) * ANG(0, 0, -0.3), p.glow, NEON)
			c:cone(V3(0.20, 0.34, 0.20), CF(-1.00, -0.60, -0.30) * ANG(PI, 0, 0.3), p.pale)
			c:box(V3(0.18, 0.18, 0.18), CF(0, 1.75, 0) * DIAMOND, p.glow, NEON)
			c:light(p.glow, 1.2, 8)
		end,
	}

	-- An elixir hare on a moon dais: long ears tipped with light, a gold
	-- crescent on its brow, grinding a glowing elixir in a mortar.
	S.dv_t_hare = {
		label = "Elixir Hare",
		set = SET,
		tint = C3(250, 248, 240),
		head = CF(0, 2.00, 0),
		neck = CF(0, -0.20, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V3(1.30, 1.60, 1.20),
				eyeY = 0.34, eyeSpread = 0.34, eyeSize = V3(0.36, 0.44, 0.18),
				snout = { w = 0.40, h = 0.26, d = 0.20, y = 0.04, color = p.pale, nose = BLUSH },
				legs = false, tail = false,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.30, 0.90, 0.20), CF(0.30 * s, 1.30, 0) * ANG(0, 0, -0.12 * s), p.base)
				c:box(V3(0.16, 0.66, 0.06), CF(0.30 * s, 1.28, 0.11) * ANG(0, 0, -0.12 * s), BLUSH)
				c:box(V3(0.24, 0.16, 0.22), CF(0.36 * s, 1.80, 0) * ANG(0, 0, -0.12 * s), p.glow, NEON)
				c:box(V3(0.24, 0.40, 0.30), CF(0.45 * s, -0.25, 0.70), p.base)
				c:box(V3(0.40, 0.20, 0.56), CF(0.34 * s, -0.84, 0.40), p.light)
				c:box(V3(0.18, 0.09, 0.04), CF(0.48 * s, 0.04, 0.62), BLUSH)
			end
			c:box(V3(0.24, 0.08, 0.04), CF(0, 0.68, 0.62), GOLD, NEON)
			c:box(V3(0.70, 0.40, 0.50), CF(0, -0.45, 0.86), p.deep)
			c:box(V3(0.78, 0.10, 0.56), CF(0, -0.22, 0.86), GOLD, METAL)
			c:box(V3(0.60, 0.06, 0.40), CF(0, -0.19, 0.86), p.glow, NEON)
			c:rod(V3(0.05, -0.30, 0.86), V3(0.60, 0.00, 1.02), 0.06, TIMBER, WOOD, true)
			c:box(V3(0.40, 0.40, 0.30), CF(0, -0.40, -0.70), CLOUD)
			c:cyl(V3(0.24, 1.80, 1.80), CF(0, -1.06, 0.10) * UP, SUN)
			c:box(V3(0.22, 0.22, 0.08), CF(-0.70, 1.20, 0.20) * DIAMOND, SUN, NEON)
		end,
	}

	-- A sigil manta gliding by: broad wings marked with glowing runes, two
	-- curled head fins, a tiny gold crown and a long tail tipped with light.
	S.dv_t_manta = {
		label = "Sigil Manta",
		set = SET,
		tint = C3(20, 30, 90),
		scale = 1.2,
		head = CF(0, 1.00, 0.30),
		neck = CF(0, -0.40, 0.90),
		back = CF(0, 0.60, -0.60),
		build = function(c, p)
			c:box(V3(1.20, 0.70, 1.60), CF(0, 0.10, 0), p.base)
			c:box(V3(1.00, 0.12, 1.40), CF(0, -0.30, 0), p.pale)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.80, 0.20, 1.30), CF(0.90 * s, 0.10, 0) * ANG(0, 0, 0.15 * s), p.base)
				c:box(V3(0.50, 0.16, 0.90), CF(1.40 * s, 0.25, -0.10) * ANG(0, 0.25 * s, 0.30 * s), p.light)
				for _, z in ipairs({ 0.30, -0.20 }) do
					c:box(V3(0.50, 0.04, 0.12), CF(0.95 * s, 0.22, z) * ANG(0, 0, 0.15 * s), p.glow, NEON)
				end
				c:box(V3(0.16, 0.40, 0.30), CF(0.62 * s, 0.10, 0.90) * ANG(0.2, 0, 0), p.dark)
			end
			c:eyes(0.22, 0.82, 0.28, 0.14)
			c:box(V3(0.50, 0.06, 0.05), CF(0, -0.08, 0.82), INK)
			cheeks(c, 0.02, 0.81, 0.40)
			c:box(V3(0.10, 0.10, 1.10), CF(0, 0.10, -1.30), p.dark)
			c:box(V3(0.14, 0.14, 0.14), CF(0, 0.10, -1.90) * DIAMOND, p.glow, NEON)
			c:box(V3(0.50, 0.10, 0.40), CF(0, 0.50, 0.30), GOLD, METAL)
			for i = -1, 1 do
				c:cone(V3(0.12, 0.22, 0.12), CF(i * 0.16, 0.66, 0.30), p.glow, NEON)
			end
			for _, v in ipairs({ { -0.80, 0.80, -0.40 }, { 0.60, 0.95, 0.20 }, { 0.00, 1.10, -0.60 } }) do
				c:box(V3(0.12, 0.12, 0.12), CF(v[1], v[2], v[3]) * DIAMOND, CLOUD, NEON)
			end
		end,
	}

	-- ===================================================================
	-- EXOTIC: the first relics, from before the world.
	-- ===================================================================

	-- The world egg: a speckled egg hatching light, its cap floating off,
	-- stars swirling out, and a ring of light orbiting its middle.
	S.dv_t_egg = {
		label = "World Egg",
		set = SET,
		tint = C3(70, 40, 140),
		head = CF(0, 2.00, 0),
		neck = CF(0, -0.50, 0.90),
		back = CF(0, 0.10, -0.90),
		build = function(c, p)
			c:box(V3(1.50, 0.40, 1.40), CF(0, -0.80, 0), p.base)
			c:box(V3(1.80, 0.90, 1.70), CF(0, -0.20, 0), p.base)
			c:box(V3(1.60, 0.50, 1.50), CF(0, 0.48, 0), p.base)
			for _, v in ipairs({ { -0.50, 0.40 }, { 0.50, 0.40 }, { -0.40, -0.45 }, { 0.40, -0.45 } }) do
				c:cone(V3(0.36, 0.30, 0.36), CF(v[1], 0.88, v[2]), p.light)
			end
			c:box(V3(1.30, 0.30, 1.20), CF(0, 0.75, 0), p.glow, NEON)
			local cap = CF(0.20, 1.45, -0.10) * ANG(0.20, 0, -0.35)
			c:box(V3(1.20, 0.40, 1.10), cap, p.base)
			c:cone(V3(0.70, 0.30, 0.70), cap * CF(0, 0.34, 0), p.light)
			for _, v in ipairs({ { -0.30, 1.05, 0.20 }, { 0.45, 1.10, 0.30 }, { -0.60, 1.40, 0.10 } }) do
				c:box(V3(0.14, 0.14, 0.14), CF(v[1], v[2], v[3]) * DIAMOND, CLOUD, NEON)
			end
			c:eyes(0.02, 0.86, 0.40, 0.18)
			smile(c, -0.34, 0.86)
			cheeks(c, -0.22, 0.86, 0.66)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.06, 0.30, 0.30), CF(0.91 * s, -0.10, -0.30), p.pale)
				c:box(V3(0.40, 0.24, 0.46), CF(0.40 * s, -1.08, 0.20), p.dark)
			end
			hoop(c, CF(0, -0.10, 0) * ANG(0.45, 0, 0.15), 1.30, 10, 0.07, p.glow, NEON, false)
			c:light(p.glow, 1.4, 9)
		end,
	}

	-- The genesis tree: a smiling trunk on a floating island, a tiered canopy
	-- hung with glowing fruit, a waterfall spilling off and a tiny sun above.
	S.dv_t_tree = {
		label = "Genesis Tree",
		set = SET,
		tint = C3(90, 200, 80),
		scale = 1.15,
		head = CF(0, 2.00, 0),
		neck = CF(0, -0.50, 0.50),
		back = CF(0, 0.00, -0.50),
		build = function(c, p)
			c:box(V3(1.80, 0.40, 1.60), CF(0, -0.90, 0), p.dark)
			c:cone(V3(1.20, 0.40, 1.00), CF(0, -1.30, 0) * ANG(PI, 0, 0), p.deep)
			c:box(V3(1.00, 1.10, 0.90), CF(0, -0.15, 0), p.deep)
			c:eyes(0.02, 0.47, 0.26, 0.15)
			smile(c, -0.26, 0.46, 0.20)
			cheeks(c, -0.16, 0.46, 0.40)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V3(0.50, 0.20, 0.30), CF(0.62 * s, -0.62, 0.20) * ANG(0, 0, 0.4 * s), p.deep)
				c:box(V3(0.60, 0.50, 0.60), CF(1.20 * s, 0.50, 0.10), p.base)
			end
			c:box(V3(0.30, 0.20, 0.50), CF(0, -0.62, -0.62) * ANG(-0.4, 0, 0), p.deep)
			c:box(V3(2.20, 0.70, 1.90), CF(0, 0.70, 0), p.base)
			c:box(V3(1.60, 0.50, 1.40), CF(0, 1.25, 0), p.light)
			c:box(V3(0.90, 0.36, 0.80), CF(0, 1.62, 0), p.pale)
			for _, v in ipairs({ { 0.80, 0.70 }, { -0.80, 0.70 }, { 0.60, -0.70 }, { -0.60, -0.70 } }) do
				c:ball(V3(0.24, 0.24, 0.24), CF(v[1], 0.24, v[2]), p.glow, NEON)
			end
			c:ball(V3(0.30, 0.30, 0.30), CF(0.95, 1.70, 0.20), SUN, NEON)
			for _, v in ipairs({ { -0.90, 1.50, 0.30 }, { -0.40, 1.95, -0.10 } }) do
				c:box(V3(0.12, 0.12, 0.12), CF(v[1], v[2], v[3]) * DIAMOND, CLOUD, NEON)
			end
			c:box(V3(0.30, 0.60, 0.06), CF(0.60, -1.20, 0.80), GEM, NEON)
			c:light(p.glow, 1.2, 8)
		end,
	}

	return S
end
