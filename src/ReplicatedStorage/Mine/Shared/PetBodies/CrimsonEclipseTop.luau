--[[ PetBodies/CrimsonEclipseTop -- Crimson Eclipse's top bodies. See tools/gen/sets/README.md.

	Epic and up: each body here is worn by exactly ONE pet in the game, so no
	two share a silhouette. The set is kid-friendly gothic under a blood-red
	moon: Victorian manor relics (gaslamp, postbox, wardrobe, hearth, chimney),
	a nocturne of music (metronome, clavichord, music box, a living note,
	psaltery, carillon), eclipse rituals (altar, thurible, pendulum, alembic,
	monstrance) and night creatures (nightjar, basilisk, caladrius, bicorn, the
	moon-chasing tiangou), plus manor gothic (hearth, oriel, steeple, belfry,
	cloister, clocktower, rosewindow, manor, totality). No bats, fangs, capes
	or skulls (those are the Halloween bodies), and nothing gory. Epic stays
	charming and clean; Legendary gets gold and trim; Mythic, Divine and Exotic
	get neon moonlight, halos and auras, echoing the top packs "Immortal
	Dynasty" and "Blood Moon Ascendant".
]]
return function(K)
	local C3, block, spots = K.C3, K.block, K.spots
	local METAL, NEON, SLATE, WOOD, GLASS = K.METAL, K.NEON, K.SLATE, K.WOOD, K.GLASS
	local INK, WHITE = K.INK, K.WHITE
	local S = {}

	local V, CF, ANG = Vector3.new, CFrame.new, CFrame.Angles
	local PI = math.pi
	local SIDES = { -1, 1 }
	local UP = ANG(0, 0, PI / 2) -- a cylinder standing up
	local FACE = ANG(0, PI / 2, 0) -- a cylinder's flat face to the front
	local FWD = ANG(PI / 2, 0, 0) -- a cone pointing to the front
	local DOWN = ANG(PI, 0, 0) -- a cone pointing down
	local DIAMOND = ANG(0, 0, PI / 4)
	local GEM = ANG(PI / 4, 0, PI / 4) -- a cube stood on its corner
	local GOLD = C3(232, 186, 76)
	local BLOOD = C3(220, 30, 60)
	local CRATER = C3(150, 10, 30)
	local BLUSH = C3(255, 140, 160)
	local IRON = C3(58, 52, 64)
	local BONE = C3(240, 228, 200)
	local FLAME = C3(255, 196, 96)
	local SILVER = C3(214, 218, 230)
	local MOON = C3(232, 232, 245)
	local LEAF = C3(52, 92, 58)
	local SMOKE = C3(200, 198, 214)

	-- Rosy cheeks either side of a face: 2 parts.
	local function blush(c, x, y, z, cx)
		cx = cx or 0
		for _, s in ipairs(SIDES) do
			c:box(V(0.16, 0.08, 0.06), CF(cx + x * s, y, z), BLUSH)
		end
	end

	-- Two eyes, a small mouth and cheeks on a flat front at depth z: 7 parts.
	local function face(c, y, z, spread, r, x)
		x = x or 0
		c:eye(V(x - spread, y, z), r)
		c:eye(V(x + spread, y, z), r)
		c:box(V(spread * 0.7, 0.07, 0.05), CF(x, y - r * 2.2, z - 0.02), INK)
		blush(c, spread + r * 0.9, y - r * 1.6, z - 0.02, x)
	end

	-- A flat ring of n slabs in the XZ plane of `cf` (a halo): n parts.
	local function ring(c, cf, r, n, colour, mat, t)
		t = t or 0.08
		local side = 2 * r * math.tan(PI / n) + t
		for i = 0, n - 1 do
			c:box(V(side, t, t), cf * ANG(0, i * 2 * PI / n, 0) * CF(0, 0, r), colour, mat)
		end
	end

	-- The same ring stood up to face the front: n parts.
	local function hoop(c, cf, r, n, colour, mat, t)
		ring(c, cf * ANG(PI / 2, 0, 0), r, n, colour, mat, t)
	end

	-- A floating music note, head and stem: 2 parts.
	local function note(c, x, y, z, colour)
		c:ball(V(0.18, 0.14, 0.10), CF(x, y, z), colour, NEON)
		c:box(V(0.04, 0.34, 0.04), CF(x + 0.07, y + 0.17, z), colour, NEON)
	end

	-- A candle flame, a neon teardrop: 1 part.
	local function flame(c, x, y, z, s)
		s = s or 1
		c:ball(V(0.16 * s, 0.26 * s, 0.16 * s), CF(x, y, z), FLAME, NEON)
	end

	---------------------------------------------------------------- EPIC

	-- A round red songbird from the cathedral choir: tall crest, black mask,
	-- a white choir ruff and a note in the air.
	S.ce_t_cardinal = {
		label = "Choir Cardinal",
		set = "crimson_eclipse",
		tint = C3(214, 24, 48),
		head = CF(0, 1.30, 0.10),
		neck = CF(0, -0.50, 0.86),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "bird",
				bodySize = V(1.84, 1.80, 1.70),
				eyeSize = V(0.42, 0.52, 0.20), eyeY = 0.24, eyeSpread = 0.38,
				mouth = false, legs = false, tail = false,
			})
			c:box(V(0.62, 0.42, 0.04), CF(0, -0.14, 0.88), INK)
			c:cone(V(0.36, 0.36, 0.30), CF(0, -0.10, 1.04) * FWD, C3(255, 150, 60))
			c:cone(V(0.30, 0.62, 0.46), CF(0, 1.16, 0.06) * ANG(-0.35, 0, 0), p.base)
			c:box(V(1.24, 0.16, 0.56), CF(0, -0.50, 0.70), WHITE)
			for _, s in ipairs(SIDES) do
				c:box(V(0.18, 0.86, 1.06), CF(0.94 * s, -0.02, -0.14) * ANG(0.10, 0, 0), p.dark)
				c:box(V(0.12, 0.26, 0.12), CF(0.30 * s, -0.86, 0.10), C3(90, 60, 50))
				c:box(V(0.30, 0.08, 0.34), CF(0.30 * s, -1.02, 0.18), C3(90, 60, 50))
			end
			c:box(V(0.54, 0.12, 0.84), CF(0, -0.07, -1.11) * ANG(0.45, 0, 0), p.dark)
			note(c, 0.98, 0.86, 0.30, p.glow)
		end,
	}

	-- A desert jerboa that hops by moonlight: huge ears, kangaroo feet, a
	-- tufted tail and a velvet bow.
	S.ce_t_jerboa = {
		label = "Moonhop Jerboa",
		set = "crimson_eclipse",
		tint = C3(200, 130, 150),
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.36, 0.66),
		back = CF(0, 0.20, -0.66),
		build = function(c, p)
			block(c, p, {
				shape = "round",
				bodySize = V(1.30, 1.40, 1.20),
				eyeSize = V(0.36, 0.44, 0.20), eyeY = 0.18, eyeSpread = 0.30,
				snout = { w = 0.36, h = 0.24, d = 0.20, y = -0.14, color = p.pale, nose = BLUSH },
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				local ear = CF(0.40 * s, 1.16, 0) * ANG(0, 0, -0.22 * s)
				c:box(V(0.40, 0.84, 0.12), ear, p.base)
				c:box(V(0.24, 0.58, 0.06), ear * CF(0, -0.02, 0.07), BLUSH)
				c:box(V(0.30, 0.50, 0.60), CF(0.58 * s, -0.46, -0.12), p.dark)
				c:box(V(0.24, 0.14, 0.72), CF(0.54 * s, -0.84, 0.16), p.pale)
			end
			c:box(V(0.42, 0.12, 0.10), CF(0, -0.32, 0.62), BLOOD)
			c:rod(V(0, -0.40, -0.50), V(0, -0.72, -1.36), 0.05, p.dark, nil, false)
			c:box(V(0.26, 0.26, 0.40), CF(0, -0.76, -1.52), INK)
		end,
	}

	-- A three-branch candelabra with a round face on its knop.
	S.ce_t_candelabra = {
		label = "Vesper Candelabra",
		set = "crimson_eclipse",
		tint = C3(236, 180, 60),
		head = CF(0, 1.62, 0),
		neck = CF(0, -0.40, 0.46),
		back = CF(0, -0.10, -0.46),
		build = function(c, p)
			c:box(V(0.96, 0.20, 0.96), CF(0, -1.00, 0), p.dark, METAL)
			c:box(V(0.46, 0.34, 0.46), CF(0, -0.76, 0), p.base, METAL)
			c:box(V(1.00, 0.96, 0.80), CF(0, -0.12, 0), p.base, METAL)
			face(c, -0.04, 0.42, 0.24, 0.13)
			c:box(V(0.24, 0.30, 0.24), CF(0, 0.48, 0), p.light, METAL)
			c:box(V(2.00, 0.14, 0.16), CF(0, 0.56, 0), p.base, METAL)
			for _, x in ipairs({ -0.93, 0, 0.93 }) do
				local tall = (x == 0) and 0.62 or 0.46
				if x ~= 0 then
					c:box(V(0.14, 0.32, 0.14), CF(x, 0.70, 0), p.base, METAL)
				end
				c:box(V(0.32, 0.10, 0.32), CF(x, 0.88, 0), p.dark, METAL)
				c:box(V(0.20, tall, 0.20), CF(x, 0.93 + tall / 2, 0), BONE)
				flame(c, x, 1.06 + tall, 0)
			end
			c:light(FLAME, 1.2, 7)
		end,
	}

	-- A pocket watch on two feet, both hands at midnight, its chain looping
	-- down to a T-bar.
	S.ce_t_fobwatch = {
		label = "Midnight Fobwatch",
		set = "crimson_eclipse",
		tint = C3(70, 60, 160),
		head = CF(0, 1.46, 0),
		neck = CF(0, -0.60, 0.30),
		back = CF(0, 0, -0.30),
		build = function(c, p)
			c:cyl(V(0.30, 1.96, 1.96), CF(0, 0, -0.04) * FACE, p.dark, METAL)
			c:cyl(V(0.36, 1.80, 1.80), CF(0, 0, 0) * FACE, p.base, METAL)
			c:cyl(V(0.06, 1.50, 1.50), CF(0, 0, 0.19) * FACE, BONE)
			c:eyes(0.18, 0.25, 0.32, 0.14)
			c:box(V(0.26, 0.06, 0.04), CF(0, -0.24, 0.23), INK)
			blush(c, 0.48, -0.12, 0.22)
			c:box(V(0.06, 0.60, 0.04), CF(0, 0.30, 0.23), INK)
			c:box(V(0.12, 0.12, 0.05), CF(0, 0, 0.23), GOLD, METAL)
			for _, x in ipairs({ -0.62, 0.62 }) do
				c:box(V(0.16, 0.07, 0.04), CF(x, 0, 0.23), INK)
			end
			c:cyl(V(0.22, 0.22, 0.22), CF(0, 1.00, 0) * UP, GOLD, METAL)
			c:cyl(V(0.14, 0.34, 0.34), CF(0, 1.16, 0) * UP, GOLD, METAL)
			hoop(c, CF(0, 1.40, 0), 0.16, 4, GOLD, METAL, 0.06)
			c:rod(V(0.12, 1.40, 0), V(0.98, 0.70, -0.10), 0.03, GOLD, METAL, false)
			c:rod(V(0.98, 0.70, -0.10), V(1.06, -0.30, -0.10), 0.03, GOLD, METAL, false)
			c:box(V(0.30, 0.08, 0.08), CF(1.06, -0.34, -0.10), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:box(V(0.36, 0.20, 0.40), CF(0.40 * s, -1.00, 0), p.dark)
			end
		end,
	}

	-- A music box with its mirrored lid up, a crank at the side and a star
	-- turning on its spindle.
	S.ce_t_musicbox = {
		label = "Twinkle Musicbox",
		set = "crimson_eclipse",
		tint = C3(226, 86, 130),
		head = CF(0, 1.50, -0.60),
		neck = CF(0, -0.70, 0.70),
		back = CF(0, 0.20, -0.86),
		build = function(c, p)
			c:box(V(1.80, 1.00, 1.30), CF(0, -0.40, 0), p.base, WOOD)
			face(c, -0.34, 0.67, 0.36, 0.15)
			c:box(V(1.90, 0.14, 1.40), CF(0, -0.88, 0), p.dark, WOOD)
			c:box(V(1.84, 0.08, 1.34), CF(0, 0.08, 0), GOLD, METAL)
			c:box(V(1.80, 1.30, 0.12), CF(0, 0.74, -0.72) * ANG(-0.15, 0, 0), p.base, WOOD)
			c:box(V(1.40, 0.96, 0.04), CF(0, 0.74, -0.65) * ANG(-0.15, 0, 0), SILVER, METAL)
			c:cyl(V(0.06, 0.50, 0.50), CF(0, 0.15, 0.10) * UP, GOLD, METAL)
			c:cyl(V(0.30, 0.08, 0.08), CF(0, 0.33, 0.10) * UP, GOLD, METAL)
			c:star(V(0, 0.66, 0.10), 0.46, p.glow)
			c:cyl(V(0.24, 0.10, 0.10), CF(1.02, -0.40, 0), GOLD, METAL)
			c:box(V(0.08, 0.38, 0.08), CF(1.14, -0.26, 0), GOLD, METAL)
			c:ball(V(0.16, 0.16, 0.16), CF(1.14, -0.06, 0.06), BLOOD)
			for _, s in ipairs(SIDES) do
				c:box(V(0.30, 0.14, 1.20), CF(0.70 * s, -1.01, 0), GOLD, METAL)
			end
			note(c, -0.72, 0.62, 0.30, p.glow)
		end,
	}

	-- A long-nosed borzoi with silky ears, a lace ruff and a gold medallion.
	S.ce_t_borzoi = {
		label = "Courtly Borzoi",
		set = "crimson_eclipse",
		tint = C3(236, 224, 214),
		head = CF(0, 1.10, 0.20),
		neck = CF(0, -0.46, 0.96),
		back = CF(0, 0.40, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				bodySize = V(1.50, 1.70, 1.60),
				eyeSize = V(0.36, 0.44, 0.20), eyeY = 0.38, eyeSpread = 0.30,
				snout = { w = 0.46, h = 0.40, d = 0.66, y = 0.02, color = p.light, nose = INK },
				legSize = V(0.30, 0.56, 0.34), legY = -1.02, legX = 0.46, legZ = { 0.44, -0.44 },
				legColor = p.light, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V(0.22, 0.46, 0.40), CF(0.62 * s, 0.76, 0.06) * ANG(0.5, 0, -0.35 * s), p.dark)
			end
			c:cyl(V(0.14, 1.50, 1.50), CF(0, -0.30, 0.30) * UP, BONE)
			c:box(V(0.18, 0.18, 0.06), CF(0, -0.46, 1.08) * DIAMOND, GOLD, METAL)
			c:box(V(0.20, 0.20, 0.86), CF(0, -0.36, -1.12) * ANG(-0.5, 0, 0), p.light)
			c:box(V(0.80, 0.46, 0.20), CF(0, -0.56, 0.82), p.pale)
		end,
	}

	-- A verdigris rooster weathervane on its arrow, over a compass cross.
	S.ce_t_weathercock = {
		label = "Iron Weathercock",
		set = "crimson_eclipse",
		tint = C3(70, 160, 140),
		head = CF(0, 1.16, 0.10),
		neck = CF(0, 0.10, 0.46),
		back = CF(0, 0.50, -0.50),
		build = function(c, p)
			c:cyl(V(1.16, 0.12, 0.12), CF(0, -0.72, 0) * UP, IRON, METAL)
			c:cyl(V(0.12, 0.56, 0.56), CF(0, -1.30, 0) * UP, IRON, METAL)
			c:box(V(1.80, 0.08, 0.08), CF(0, -0.84, 0), IRON, METAL)
			c:box(V(0.08, 0.08, 1.80), CF(0, -0.84, 0), IRON, METAL)
			c:box(V(2.10, 0.08, 0.08), CF(0, -0.12, 0), p.dark, METAL)
			c:cone(V(0.14, 0.32, 0.30), CF(1.16, -0.12, 0) * ANG(0, 0, -PI / 2), p.dark, METAL)
			c:box(V(0.30, 0.30, 0.04), CF(-1.02, -0.12, 0) * DIAMOND, p.dark, METAL)
			c:box(V(0.90, 0.90, 0.80), CF(0, 0.38, 0), p.base, METAL)
			c:eyes(0.52, 0.42, 0.20, 0.11)
			c:cone(V(0.16, 0.24, 0.14), CF(0, 0.36, 0.52) * FWD, GOLD, METAL)
			c:box(V(0.10, 0.18, 0.06), CF(0, 0.18, 0.43), BLOOD)
			c:cone(V(0.14, 0.32, 0.44), CF(0, 0.99, 0.06), BLOOD)
			c:box(V(1.20, 0.80, 0.08), CF(0, 0.82, -0.44), p.dark, METAL)
			for _, s in ipairs(SIDES) do
				c:box(V(0.50, 0.70, 0.08), CF(0.62 * s, 0.78, -0.46) * ANG(0, 0, -0.5 * s), p.light, METAL)
				c:box(V(0.10, 0.50, 0.60), CF(0.48 * s, 0.36, -0.04), p.dark, METAL)
			end
		end,
	}

	-- A Victorian street lamp: iron post, ladder bar, a glowing glass head with
	-- a face, and fog curling round its foot.
	S.ce_t_gaslamp = {
		label = "Foggy Gaslamp",
		set = "crimson_eclipse",
		tint = C3(44, 60, 110),
		head = CF(0, 1.74, 0),
		neck = CF(0, 0.30, 0.50),
		back = CF(0, 0.70, -0.50),
		build = function(c, p)
			c:box(V(0.80, 0.30, 0.80), CF(0, -0.95, 0), p.dark, METAL)
			c:box(V(0.56, 0.30, 0.56), CF(0, -0.68, 0), p.base, METAL)
			c:cyl(V(0.84, 0.22, 0.22), CF(0, -0.13, 0) * UP, p.base, METAL)
			c:box(V(0.90, 0.08, 0.08), CF(0, 0.15, 0), p.base, METAL)
			c:box(V(1.00, 0.10, 1.00), CF(0, 0.30, 0), p.dark, METAL)
			c:box(V(0.80, 0.80, 0.80), CF(0, 0.72, 0), C3(255, 214, 150), NEON)
			for _, x in ipairs({ -0.42, 0.42 }) do
				for _, z in ipairs({ -0.42, 0.42 }) do
					c:box(V(0.08, 0.86, 0.08), CF(x, 0.72, z), p.base, METAL)
				end
			end
			c:cone(V(1.10, 0.50, 1.10), CF(0, 1.36, 0), p.dark, METAL)
			c:ball(V(0.16, 0.16, 0.16), CF(0, 1.68, 0), GOLD, METAL)
			face(c, 0.80, 0.42, 0.20, 0.11)
			for _, s in ipairs(SIDES) do
				c:ball(V(0.70, 0.30, 0.56), CF(0.42 * s, -1.06, 0.28), SMOKE)
			end
			c:light(FLAME, 1.4, 8)
		end,
	}

	-- A pomegranate with a crown-shaped calyx and a few jewel seeds showing.
	S.ce_t_pomegranate = {
		label = "Ruby Pomegranate",
		set = "crimson_eclipse",
		tint = C3(170, 20, 80),
		head = CF(0, 1.44, 0),
		neck = CF(0, -0.46, 0.92),
		back = CF(0, 0.20, -0.92),
		build = function(c, p)
			block(c, p, {
				shape = "round",
				bodySize = V(1.90, 1.80, 1.80),
				eyeSize = V(0.44, 0.52, 0.20), eyeY = 0.12, eyeSpread = 0.38,
				mouthY = -0.30, legs = false, tail = false,
			})
			blush(c, 0.40, -0.22, 0.88)
			c:cyl(V(0.30, 0.60, 0.60), CF(0, 1.06, 0) * UP, p.dark)
			for i = 0, 2 do
				local a = i * 2 * PI / 3 + PI / 2
				c:cone(
					V(0.18, 0.34, 0.18),
					CF(0.24 * math.cos(a), 1.34, 0.24 * math.sin(a)) * ANG(0.35 * math.sin(a), 0, -0.35 * math.cos(a)),
					p.dark
				)
			end
			for _, v in ipairs({ { 0.40, -0.44 }, { 0.18, -0.46 } }) do
				c:box(V(0.14, 0.18, 0.10), CF(v[1], v[2], 0.88), C3(255, 70, 110), NEON)
			end
			for _, s in ipairs(SIDES) do
				c:box(V(0.40, 0.20, 0.40), CF(0.45 * s, -0.90, 0.10), p.deep)
			end
		end,
	}

	-- A pillar postbox: its slot is a mouth with a sealed letter on its tongue.
	S.ce_t_postbox = {
		label = "Pillar Postbox",
		set = "crimson_eclipse",
		tint = C3(176, 16, 30),
		head = CF(0, 1.36, 0),
		neck = CF(0, -0.60, 0.62),
		back = CF(0, 0, -0.62),
		build = function(c, p)
			c:cyl(V(0.24, 1.40, 1.40), CF(0, -1.00, 0) * UP, p.dark)
			c:cyl(V(1.60, 1.20, 1.20), CF(0, -0.10, 0) * UP, p.base)
			c:cyl(V(0.10, 1.24, 1.24), CF(0, 0.55, 0) * UP, p.dark)
			c:cyl(V(0.20, 1.36, 1.36), CF(0, 0.78, 0) * UP, p.light)
			c:cyl(V(0.24, 1.00, 1.00), CF(0, 0.98, 0) * UP, p.light)
			c:ball(V(0.30, 0.30, 0.30), CF(0, 1.18, 0), GOLD, METAL)
			c:eyes(0.30, 0.60, 0.24, 0.13)
			c:box(V(0.44, 0.12, 0.06), CF(0, -0.06, 0.60), INK)
			c:box(V(0.34, 0.30, 0.03), CF(0, -0.16, 0.64) * ANG(-0.3, 0, 0), BONE)
			c:box(V(0.10, 0.10, 0.04), CF(0, -0.22, 0.68), BLOOD)
			c:cyl(V(0.04, 0.30, 0.30), CF(0, -0.52, 0.60) * FACE, GOLD, METAL)
			c:cyl(V(0.05, 0.24, 0.24), CF(0.06, -0.48, 0.61) * FACE, p.base)
			for _, s in ipairs(SIDES) do
				c:box(V(0.36, 0.16, 0.40), CF(0.36 * s, -1.18, 0.20), p.deep)
			end
		end,
	}

	-- A tuning fork humming a note: a face on its bend, glowing ripples
	-- either side of its prongs.
	S.ce_t_tuningfork = {
		label = "Echo Tuningfork",
		set = "crimson_eclipse",
		tint = C3(188, 196, 214),
		head = CF(0, 1.00, 0),
		neck = CF(0, -0.50, 0.24),
		back = CF(0, -0.20, -0.24),
		build = function(c, p)
			c:ball(V(0.40, 0.40, 0.40), CF(0, -1.12, 0), p.dark, METAL)
			c:cyl(V(0.70, 0.24, 0.24), CF(0, -0.78, 0) * UP, p.dark, METAL)
			c:box(V(0.34, 0.14, 0.30), CF(0, -0.56, 0.04), BLOOD)
			c:box(V(1.24, 0.66, 0.42), CF(0, -0.18, 0), p.base, METAL)
			face(c, -0.12, 0.23, 0.26, 0.12)
			for _, s in ipairs(SIDES) do
				c:box(V(0.28, 1.40, 0.38), CF(0.48 * s, 0.84, 0), p.base, METAL)
				c:box(V(0.06, 0.50, 0.06), CF(0.86 * s, 1.02, 0) * ANG(0, 0, -0.25 * s), p.glow, NEON)
				c:box(V(0.06, 0.74, 0.06), CF(1.08 * s, 0.96, 0) * ANG(0, 0, -0.30 * s), p.glow, NEON)
			end
			note(c, -0.04, 1.30, 0.10, p.glow)
		end,
	}

	-- A wooden metronome, its weighted arm swung out to one side.
	S.ce_t_metronome = {
		label = "Nocturne Metronome",
		set = "crimson_eclipse",
		tint = C3(110, 40, 90),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.60, 0.54),
		back = CF(0, -0.10, -0.46),
		build = function(c, p)
			c:box(V(1.36, 0.30, 1.00), CF(0, -0.95, 0), p.dark, WOOD)
			c:box(V(1.10, 1.30, 0.80), CF(0, -0.15, 0), p.base, WOOD)
			c:cone(V(1.10, 0.70, 0.80), CF(0, 0.85, 0), p.base, WOOD)
			face(c, 0.12, 0.42, 0.24, 0.13)
			c:box(V(0.06, 1.50, 0.05), CF(0.39, 0.09, 0.46) * ANG(0, 0, -0.55), GOLD, METAL)
			c:box(V(0.24, 0.18, 0.10), CF(0.55, 0.36, 0.48) * ANG(0, 0, -0.55), GOLD, METAL)
			c:box(V(0.16, 0.16, 0.10), CF(0, -0.56, 0.44), GOLD, METAL)
			c:box(V(0.10, 0.30, 0.30), CF(0.60, -0.30, 0), GOLD, METAL)
			note(c, -0.80, 0.70, 0.20, p.glow)
		end,
	}

	-- A cot mobile: a sleepy moon, two stars, a cloud and a ruby heart
	-- dangling from crossed gold bars.
	S.ce_t_mobile = {
		label = "Dreamstar Mobile",
		set = "crimson_eclipse",
		tint = C3(60, 110, 200),
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.50, 0.20),
		back = CF(0, 0.90, -0.70),
		build = function(c, p)
			c:rod(V(0, 1.30, 0), V(0, 0.92, 0), 0.03, GOLD, METAL, false)
			c:ball(V(0.16, 0.16, 0.16), CF(0, 1.32, 0), GOLD, METAL)
			c:box(V(2.00, 0.06, 0.06), CF(0, 0.90, 0), GOLD, METAL)
			c:box(V(0.06, 0.06, 1.40), CF(0, 0.90, 0), GOLD, METAL)
			c:rod(V(0, 0.90, 0), V(0, 0.45, 0), 0.015, BONE, nil, false)
			c:cyl(V(0.30, 0.92, 0.92), CF(0, 0, 0) * FACE, p.base)
			face(c, 0.06, 0.17, 0.18, 0.11)
			for _, x in ipairs({ -0.96, 0.96 }) do
				c:rod(V(x, 0.90, 0), V(x, 0.42, 0), 0.015, BONE, nil, false)
				c:star(V(x, 0.26, 0), 0.40, p.glow)
			end
			c:rod(V(0, 0.90, -0.68), V(0, 0.50, -0.68), 0.015, BONE, nil, false)
			c:ball(V(0.40, 0.30, 0.30), CF(-0.08, 0.38, -0.68), WHITE)
			c:ball(V(0.30, 0.24, 0.26), CF(0.14, 0.42, -0.68), WHITE)
			c:rod(V(0, 0.90, 0.68), V(0, 0.66, 0.68), 0.015, BONE, nil, false)
			c:box(V(0.20, 0.20, 0.08), CF(0, 0.56, 0.68) * DIAMOND, BLOOD, NEON)
		end,
	}

	-- A nightjar asleep-awake on an iron rail: flat head, wide grin, tiny beak,
	-- long crossed wings.
	S.ce_t_nightjar = {
		label = "Dusk Nightjar",
		set = "crimson_eclipse",
		tint = C3(130, 90, 150),
		head = CF(0, 0.90, 0.10),
		neck = CF(0, -0.40, 0.86),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "bird",
				bodySize = V(1.90, 1.40, 1.70),
				eyeSize = V(0.50, 0.50, 0.20), eyeY = 0.16, eyeSpread = 0.46,
				mouthSize = V(0.96, 0.10, 0.14), mouthY = -0.18,
				legs = false, tail = false,
			})
			c:cone(V(0.16, 0.16, 0.12), CF(0, -0.06, 0.92) * FWD, INK)
			spots(c, p.deep, { { -0.50, 0.74, 0.20 }, { 0.36, 0.74, 0.10 }, { -0.10, 0.68, -0.50 } }, V(0.22, 0.06, 0.22))
			for _, s in ipairs(SIDES) do
				c:box(V(0.20, 0.50, 1.40), CF(0.86 * s, 0.10, -0.40) * ANG(0.12, 0.12 * s, 0), p.dark)
				c:box(V(0.14, 0.12, 0.20), CF(0.30 * s, -0.70, 0.20), INK)
				c:box(V(0.16, 0.06, 0.10), CF(0.20 * s, 0.02, -1.36), BONE)
			end
			c:box(V(0.70, 0.12, 0.70), CF(0, -0.06, -1.10), p.dark)
			c:cyl(V(2.10, 0.14, 0.14), CF(0, -0.83, 0.10), IRON, METAL)
		end,
	}

	-- A tall wardrobe on claw feet, a carved crescent on its pediment and its
	-- two doors for a face.
	S.ce_t_wardrobe = {
		label = "Creaky Wardrobe",
		set = "crimson_eclipse",
		tint = C3(120, 64, 40),
		head = CF(0, 1.52, 0),
		neck = CF(0, -0.50, 0.52),
		back = CF(0, 0.20, -0.50),
		build = function(c, p)
			c:box(V(1.40, 2.00, 0.90), CF(0, 0, 0), p.base, WOOD)
			c:box(V(1.56, 0.16, 1.02), CF(0, 1.06, 0), p.dark, WOOD)
			c:prism(V(0.30, 0.36, 1.30), CF(0, 1.30, 0.30) * ANG(0, PI / 2, 0), p.dark, WOOD)
			c:box(V(0.16, 0.16, 0.04), CF(0, 1.27, 0.47) * DIAMOND, GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:box(V(0.64, 1.70, 0.06), CF(0.34 * s, -0.04, 0.47), p.light, WOOD)
				c:ball(V(0.12, 0.12, 0.12), CF(0.10 * s, -0.12, 0.53), GOLD, METAL)
				for _, z in ipairs({ 0.30, -0.30 }) do
					c:box(V(0.20, 0.20, 0.20), CF(0.58 * s, -1.10, z), p.dark)
				end
			end
			c:box(V(0.04, 1.70, 0.07), CF(0, -0.04, 0.47), INK)
			c:eyes(0.46, 0.52, 0.34, 0.15)
			c:box(V(0.30, 0.06, 0.04), CF(0, 0.12, 0.51), INK)
			blush(c, 0.52, 0.22, 0.51)
		end,
	}

	-- A kinkajou with a velvet collar, its long tail curled up behind.
	S.ce_t_kinkajou = {
		label = "Velvet Kinkajou",
		set = "crimson_eclipse",
		tint = C3(196, 130, 70),
		head = CF(0, 1.00, 0.10),
		neck = CF(0, -0.36, 0.86),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				bodySize = V(1.60, 1.50, 1.60),
				eyeSize = V(0.46, 0.54, 0.20), eyeY = 0.22, eyeSpread = 0.36,
				snout = { w = 0.46, h = 0.30, d = 0.24, y = -0.16, color = p.light, nose = INK },
				legSize = V(0.36, 0.30, 0.44), legY = -0.72, legX = 0.50,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V(0.28, 0.26, 0.12), CF(0.56 * s, 0.84, 0.10), p.dark)
			end
			c:box(V(1.10, 0.14, 0.20), CF(0, -0.38, 0.74), BLOOD)
			for i, v in ipairs({ { 0, -0.30, -0.95, 0.4 }, { 0.10, 0.10, -1.20, 1.0 }, { 0.20, 0.55, -1.22, 1.7 }, { 0.26, 0.86, -1.00, 2.5 } }) do
				local w = 0.28 - i * 0.02
				c:box(V(w, w, 0.50), CF(v[1], v[2], v[3]) * ANG(v[4], 0, 0), p.dark)
			end
		end,
	}

	-- Brass opera glasses resting on a velvet cushion; the lenses are its eyes.
	S.ce_t_glasses = {
		label = "Opera Glasses",
		set = "crimson_eclipse",
		tint = C3(226, 170, 70),
		head = CF(0, 0.80, 0),
		neck = CF(0, -0.30, 0.42),
		back = CF(0, 0.30, -0.50),
		build = function(c, p)
			c:box(V(1.70, 0.30, 0.80), CF(0, -0.22, 0), BLOOD)
			for _, s in ipairs(SIDES) do
				c:cyl(V(0.60, 0.70, 0.70), CF(0.46 * s, 0.30, 0) * FACE, p.base, METAL)
				c:cyl(V(0.20, 0.56, 0.56), CF(0.46 * s, 0.30, -0.38) * FACE, p.dark, METAL)
				c:cyl(V(0.08, 0.80, 0.80), CF(0.46 * s, 0.30, 0.30) * FACE, GOLD, METAL)
				c:eye(V(0.46 * s, 0.30, 0.36), 0.21)
				c:box(V(0.14, 0.24, 0.14), CF(0.82 * s, -0.30, 0.36), GOLD, METAL)
			end
			c:box(V(0.40, 0.22, 0.30), CF(0, 0.34, 0), GOLD, METAL)
			c:cyl(V(0.14, 0.26, 0.26), CF(0, 0.52, 0), GOLD, METAL)
			c:box(V(0.36, 0.16, 0.10), CF(0, 0.10, 0.12), p.dark)
			c:box(V(0.20, 0.05, 0.04), CF(0, 0.10, 0.18), INK)
			c:box(V(0.12, 0.80, 0.12), CF(1.06, 0.02, 0.10) * ANG(0, 0, 1.1), GOLD, METAL)
		end,
	}

	-- A living eighth note with a sleepy smile, singing a lullaby.
	S.ce_t_note = {
		label = "Lullaby Note",
		set = "crimson_eclipse",
		tint = C3(70, 40, 140),
		head = CF(0.40, 1.46, 0),
		neck = CF(-0.20, -0.90, 0.40),
		back = CF(-0.20, -0.40, -0.40),
		build = function(c, p)
			local at = CF(-0.20, -0.50, 0) * ANG(0, 0, 0.25)
			c:box(V(1.24, 0.90, 0.80), at, p.base)
			c:box(V(1.00, 1.00, 0.76), at * DIAMOND, p.base)
			c:eye(V(-0.44, -0.40, 0.42), 0.12)
			c:eye(V(0.02, -0.30, 0.42), 0.12)
			c:box(V(0.24, 0.06, 0.04), CF(-0.24, -0.66, 0.41) * ANG(0, 0, 0.25), INK)
			c:box(V(0.14, 0.08, 0.04), CF(-0.62, -0.58, 0.41), BLUSH)
			c:box(V(0.14, 0.08, 0.04), CF(0.16, -0.44, 0.41), BLUSH)
			c:box(V(0.16, 1.90, 0.20), CF(0.33, 0.42, 0), p.dark)
			c:box(V(0.16, 0.70, 0.20), CF(0.62, 1.06, 0) * ANG(0, 0, 0.9), p.dark)
			c:box(V(0.16, 0.50, 0.20), CF(0.74, 0.70, 0) * ANG(0, 0, 0.6), p.dark)
			c:star(V(-0.80, 0.50, 0), 0.30, p.glow)
			c:star(V(-0.40, 1.00, 0.10), 0.20, p.glow)
		end,
	}

	---------------------------------------------------------------- LEGENDARY

	-- A brick hearth with a mantel clock, glowing coals and a little face
	-- in the firebox.
	S.ce_t_hearth = {
		label = "Cozy Hearth",
		set = "crimson_eclipse",
		tint = C3(180, 70, 40),
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.50, 0.70),
		back = CF(0, 0.10, -0.70),
		build = function(c, p)
			c:box(V(2.00, 1.60, 1.10), CF(0, -0.10, 0), p.base)
			c:box(V(2.20, 0.20, 1.30), CF(0, 0.80, 0), p.dark)
			c:box(V(1.40, 0.90, 0.20), CF(0, -0.20, 0.56), INK)
			face(c, -0.10, 0.68, 0.24, 0.12)
			c:box(V(1.20, 0.30, 0.50), CF(0, -0.70, 0.20), IRON, METAL)
			for _, x in ipairs({ -0.30, 0, 0.30 }) do
				c:box(V(0.22, 0.16, 0.30), CF(x, -0.52, 0.30), CRATER)
				flame(c, x, -0.30, 0.36, 0.7)
			end
			c:cyl(V(0.20, 0.36, 0.36), CF(0, 1.00, 0) * FACE, GOLD, METAL)
			c:box(V(0.04, 0.14, 0.02), CF(0, 1.04, 0.20), INK)
			for _, s in ipairs(SIDES) do
				c:box(V(0.30, 0.16, 0.40), CF(0.80 * s, -0.96, 0.20), p.deep)
				c:box(V(0.16, 0.40, 0.16), CF(0.90 * s, 0.40, 0.40), GOLD, METAL)
			end
			c:light(FLAME, 1.2, 7)
		end,
	}

	-- A low eclipse altar: stepped plinth, cloth, a crescent dish and twin
	-- candles.
	S.ce_t_altar = {
		label = "Eclipse Altar",
		set = "crimson_eclipse",
		tint = C3(90, 30, 70),
		head = CF(0, 1.50, 0),
		neck = CF(0, -0.50, 0.70),
		back = CF(0, 0.10, -0.70),
		build = function(c, p)
			c:box(V(1.80, 0.30, 1.20), CF(0, -0.90, 0), p.dark)
			c:box(V(1.50, 0.90, 1.00), CF(0, -0.30, 0), p.base)
			c:box(V(1.70, 0.16, 1.16), CF(0, 0.24, 0), GOLD, METAL)
			c:box(V(1.40, 0.08, 0.90), CF(0, 0.36, 0), BLOOD)
			face(c, -0.20, 0.52, 0.28, 0.13)
			c:cyl(V(0.10, 0.70, 0.70), CF(0, 0.50, 0) * UP, SILVER, METAL)
			c:cyl(V(0.12, 0.50, 0.50), CF(0.10, 0.52, 0) * UP, p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V(0.16, 0.40, 0.16), CF(0.55 * s, 0.56, 0.20), BONE)
				flame(c, 0.55 * s, 0.90, 0.20, 0.8)
				c:box(V(0.28, 0.14, 0.36), CF(0.55 * s, -1.10, 0.20), p.deep)
			end
			c:light(FLAME, 1.1, 6)
		end,
	}

	-- A grandfather-clock pendulum: long rod, gold bob, a face on the weight.
	S.ce_t_pendulum = {
		label = "Grand Pendulum",
		set = "crimson_eclipse",
		tint = C3(200, 160, 60),
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.80, 0.30),
		back = CF(0, 0.20, -0.30),
		build = function(c, p)
			c:box(V(0.50, 0.20, 0.30), CF(0, 1.20, 0), p.dark, WOOD)
			c:box(V(0.10, 1.60, 0.10), CF(0.20, 0.20, 0) * ANG(0, 0, -0.25), GOLD, METAL)
			c:cyl(V(0.50, 1.00, 1.00), CF(0.46, -0.70, 0) * FACE, p.base, METAL)
			c:cyl(V(0.12, 0.80, 0.80), CF(0.46, -0.70, 0.26) * FACE, GOLD, METAL)
			face(c, -0.66, 0.52, 0.20, 0.12)
			c:box(V(0.40, 0.12, 0.40), CF(0, 1.40, 0), GOLD, METAL)
			hoop(c, CF(0, 1.52, 0), 0.18, 5, GOLD, METAL, 0.05)
			for _, s in ipairs(SIDES) do
				c:box(V(0.24, 0.14, 0.30), CF(0.30 * s, -1.20, 0.10), p.deep)
				c:star(V(0.70 * s, 0.40, 0.10), 0.22, p.glow)
			end
		end,
	}

	-- A brass alembic: round cucurbit, swan-neck retort and a drip into a flask.
	S.ce_t_alembic = {
		label = "Crimson Alembic",
		set = "crimson_eclipse",
		tint = C3(180, 120, 40),
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.50, 0.70),
		back = CF(0, 0.10, -0.70),
		build = function(c, p)
			c:box(V(1.20, 0.20, 1.00), CF(0, -1.00, 0), IRON, METAL)
			c:ball(V(1.40, 1.20, 1.30), CF(0, -0.30, 0), p.base, METAL)
			face(c, -0.20, 0.66, 0.28, 0.13)
			c:cyl(V(0.40, 0.50, 0.50), CF(0, 0.50, 0) * UP, p.dark, METAL)
			c:ball(V(0.70, 0.60, 0.70), CF(0, 0.90, 0), p.light, METAL)
			c:rod(V(0.20, 1.00, 0), V(0.90, 0.70, 0.20), 0.06, GOLD, METAL, false)
			c:rod(V(0.90, 0.70, 0.20), V(1.00, -0.20, 0.20), 0.06, GOLD, METAL, false)
			c:cyl(V(0.50, 0.40, 0.40), CF(1.00, -0.50, 0.20) * UP, p.glow, NEON)
			c:box(V(0.30, 0.10, 0.30), CF(1.00, -0.80, 0.20), IRON, METAL)
			for _, s in ipairs(SIDES) do
				c:box(V(0.28, 0.14, 0.36), CF(0.40 * s, -1.14, 0.20), p.deep)
			end
			flame(c, -0.50, -0.70, 0.50, 0.7)
			c:light(FLAME, 1.0, 5)
		end,
	}

	-- A plump velvet basilisk: crest of gold plates, coiled tail, no fangs.
	S.ce_t_basilisk = {
		label = "Velvet Basilisk",
		set = "crimson_eclipse",
		tint = C3(60, 140, 90),
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.40, 0.90),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				bodySize = V(1.70, 1.50, 1.80),
				eyeSize = V(0.40, 0.48, 0.20), eyeY = 0.28, eyeSpread = 0.34,
				snout = { w = 0.50, h = 0.34, d = 0.40, y = -0.08, color = p.light, nose = BLOOD },
				legSize = V(0.34, 0.36, 0.40), legY = -0.80, legX = 0.50,
				tail = false,
			})
			for i = 0, 3 do
				c:box(V(0.20, 0.18, 0.08), CF(0, 0.70 + i * 0.12, 0.20 - i * 0.04) * DIAMOND, GOLD, METAL)
			end
			for _, s in ipairs(SIDES) do
				c:box(V(0.20, 0.30, 0.50), CF(0.70 * s, 0.20, -0.20), p.dark)
			end
			for i, v in ipairs({ { 0, -0.20, -1.00, 0.3 }, { 0.10, 0.10, -1.30, 0.9 }, { 0.16, 0.40, -1.40, 1.5 } }) do
				local w = 0.36 - i * 0.04
				c:box(V(w, w * 0.8, 0.46), CF(v[1], v[2], v[3]) * ANG(v[4], 0, 0), p.dark)
			end
			c:box(V(0.80, 0.12, 0.16), CF(0, -0.40, 0.80), GOLD, METAL)
		end,
	}

	-- A pure white caladrius: healing bird of the sickroom, a ruby tear of care.
	S.ce_t_caladrius = {
		label = "Silver Caladrius",
		set = "crimson_eclipse",
		tint = C3(230, 230, 240),
		head = CF(0, 1.20, 0.10),
		neck = CF(0, -0.40, 0.86),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "bird",
				bodySize = V(1.70, 1.60, 1.60),
				eyeSize = V(0.38, 0.46, 0.20), eyeY = 0.22, eyeSpread = 0.34,
				mouth = false, legs = false, tail = false,
			})
			c:cone(V(0.22, 0.28, 0.22), CF(0, -0.06, 0.92) * FWD, GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:box(V(0.18, 0.70, 1.20), CF(0.90 * s, 0.10, -0.30) * ANG(0.10, 0.10 * s, 0), p.light)
				c:box(V(0.12, 0.20, 0.12), CF(0.28 * s, -0.80, 0.10), GOLD, METAL)
				c:box(V(0.24, 0.08, 0.28), CF(0.28 * s, -0.94, 0.18), GOLD, METAL)
			end
			c:box(V(0.50, 0.14, 0.70), CF(0, 0.10, -1.10) * ANG(0.4, 0, 0), p.dark)
			c:cone(V(0.30, 0.50, 0.40), CF(0, 1.10, 0.10) * ANG(-0.3, 0, 0), p.pale)
			c:ball(V(0.14, 0.18, 0.14), CF(0.55, -0.20, 0.70), BLOOD, NEON)
			c:box(V(0.70, 0.12, 0.16), CF(0, -0.50, 0.70), BLOOD)
		end,
	}

	-- A bicorn: horse-like, two crescent horns and a velvet bridle.
	S.ce_t_bicorn = {
		label = "Twinhorn Bicorn",
		set = "crimson_eclipse",
		tint = C3(40, 36, 70),
		head = CF(0, 1.20, 0.20),
		neck = CF(0, -0.46, 0.96),
		back = CF(0, 0.40, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				bodySize = V(1.60, 1.70, 1.70),
				eyeSize = V(0.36, 0.44, 0.20), eyeY = 0.34, eyeSpread = 0.30,
				snout = { w = 0.48, h = 0.40, d = 0.50, y = 0.00, color = p.light, nose = INK },
				legSize = V(0.30, 0.56, 0.34), legY = -1.02, legX = 0.48, legZ = { 0.44, -0.44 },
				legColor = p.dark, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(V(0.18, 0.50, 0.18), CF(0.28 * s, 1.10, 0.10) * ANG(0, 0, -0.25 * s), SILVER, METAL)
				c:box(V(0.16, 0.16, 0.06), CF(0.28 * s, 1.36, 0.10) * DIAMOND, p.glow, NEON)
			end
			c:box(V(1.00, 0.12, 0.16), CF(0, -0.30, 0.90), BLOOD)
			c:box(V(0.20, 0.20, 0.70), CF(0, -0.20, -1.10) * ANG(-0.4, 0, 0), p.dark)
			c:box(V(0.30, 0.30, 0.20), CF(0, 0.00, -1.40), INK)
		end,
	}

	-- A tiangou: plump night-dog that chases the moon, a moon disk on a ribbon.
	S.ce_t_tiangou = {
		label = "Moonchase Tiangou",
		set = "crimson_eclipse",
		tint = C3(50, 40, 80),
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.40, 0.90),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round",
				bodySize = V(1.80, 1.60, 1.60),
				eyeSize = V(0.42, 0.50, 0.20), eyeY = 0.20, eyeSpread = 0.36,
				snout = { w = 0.50, h = 0.34, d = 0.30, y = -0.16, color = p.pale, nose = INK },
				legSize = V(0.36, 0.34, 0.40), legY = -0.84, legX = 0.50,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V(0.30, 0.36, 0.12), CF(0.60 * s, 0.90, 0.10), p.dark)
			end
			c:box(V(0.24, 0.50, 0.40), CF(0, 0.10, -1.00) * ANG(-0.5, 0, 0), p.dark)
			c:rod(V(0.40, 0.60, 0.40), V(0.90, 1.00, 0.30), 0.03, GOLD, METAL, false)
			c:cyl(V(0.12, 0.50, 0.50), CF(1.00, 1.10, 0.30) * FACE, MOON, NEON)
			c:cyl(V(0.08, 0.30, 0.30), CF(1.04, 1.10, 0.36) * FACE, CRATER, NEON)
			c:box(V(0.90, 0.12, 0.16), CF(0, -0.40, 0.78), BLOOD)
		end,
	}

	-- A glass inkwell with a red quill dipped in, blotting paper for feet.
	S.ce_t_inkwell = {
		label = "Quill Inkwell",
		set = "crimson_eclipse",
		tint = C3(40, 50, 120),
		head = CF(0, 1.50, 0),
		neck = CF(0, -0.50, 0.60),
		back = CF(0, 0.10, -0.60),
		build = function(c, p)
			c:box(V(1.40, 0.16, 1.20), CF(0, -0.90, 0), BONE)
			c:cyl(V(1.00, 1.00, 1.00), CF(0, -0.20, 0) * UP, p.base, GLASS)
			c:cyl(V(0.40, 0.80, 0.80), CF(0, 0.40, 0) * UP, INK)
			c:cyl(V(0.16, 1.10, 1.10), CF(0, 0.50, 0) * UP, GOLD, METAL)
			face(c, -0.10, 0.52, 0.26, 0.12)
			c:rod(V(0.10, 0.55, 0), V(0.70, 1.30, 0.10), 0.04, BONE, nil, false)
			c:box(V(0.20, 0.50, 0.08), CF(0.78, 1.40, 0.10) * ANG(0, 0, 0.4), BLOOD)
			c:box(V(0.10, 0.10, 0.06), CF(0.90, 1.60, 0.12), INK)
			for _, s in ipairs(SIDES) do
				c:box(V(0.36, 0.10, 0.40), CF(0.50 * s, -1.02, 0.20), BONE)
			end
			note(c, -0.70, 0.80, 0.20, p.glow)
		end,
	}

	-- A swinging thurible: pierced brass ball on chains, a puff of sweet smoke.
	S.ce_t_thurible = {
		label = "Swinging Thurible",
		set = "crimson_eclipse",
		tint = C3(200, 150, 50),
		head = CF(0, 1.60, 0),
		neck = CF(0, -0.70, 0.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			c:box(V(0.40, 0.12, 0.40), CF(0, 1.20, 0), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:rod(V(0.12 * s, 1.20, 0), V(0.30 * s, 0.40, 0), 0.03, GOLD, METAL, false)
			end
			c:rod(V(0, 1.20, 0), V(0, 0.40, 0), 0.03, GOLD, METAL, false)
			c:ball(V(1.20, 1.20, 1.20), CF(0, -0.20, 0), p.base, METAL)
			face(c, -0.10, 0.60, 0.26, 0.13)
			c:cyl(V(0.20, 0.70, 0.70), CF(0, 0.50, 0) * UP, GOLD, METAL)
			c:cone(V(0.80, 0.30, 0.80), CF(0, 0.70, 0), GOLD, METAL)
			for _, a in ipairs({ 0, 1.05, 2.1, 3.15 }) do
				c:box(V(0.16, 0.16, 0.06), CF(0.40 * math.cos(a), 0.10, 0.40 * math.sin(a) + 0.50) * DIAMOND, p.glow, NEON)
			end
			c:ball(V(0.50, 0.30, 0.50), CF(0.50, 0.90, 0.20), SMOKE)
			for _, s in ipairs(SIDES) do
				c:box(V(0.28, 0.14, 0.30), CF(0.36 * s, -0.90, 0.20), p.deep)
			end
		end,
	}

	-- A bay oriel window: stone sill, diamond panes, a little face in the glass.
	S.ce_t_oriel = {
		label = "Oriel Window",
		set = "crimson_eclipse",
		tint = C3(70, 90, 150),
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.50, 0.50),
		back = CF(0, 0.20, -0.50),
		build = function(c, p)
			c:box(V(1.80, 0.24, 0.80), CF(0, -0.90, 0), p.dark, SLATE)
			c:box(V(1.60, 1.50, 0.60), CF(0, 0.00, 0), p.base, SLATE)
			c:box(V(1.40, 1.20, 0.20), CF(0, 0.10, 0.32), p.glow, GLASS)
			face(c, 0.20, 0.44, 0.28, 0.13)
			c:box(V(0.06, 1.20, 0.06), CF(0, 0.10, 0.42), GOLD, METAL)
			c:box(V(1.40, 0.06, 0.06), CF(0, 0.10, 0.42), GOLD, METAL)
			c:prism(V(0.40, 0.50, 1.60), CF(0, 1.00, 0.20) * ANG(0, PI / 2, 0), p.dark, SLATE)
			c:box(V(0.16, 0.16, 0.06), CF(0, 1.10, 0.50) * DIAMOND, GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:box(V(0.20, 1.50, 0.50), CF(0.80 * s, 0.00, -0.10) * ANG(0, 0.25 * s, 0), p.light, SLATE)
				c:box(V(0.30, 0.14, 0.36), CF(0.50 * s, -1.06, 0.20), p.deep)
			end
		end,
	}

	-- A little clavichord: keys, a propped lid and a music book on the stand.
	S.ce_t_clavichord = {
		label = "Nocturne Clavichord",
		set = "crimson_eclipse",
		tint = C3(120, 50, 40),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.50, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:box(V(2.00, 0.70, 1.20), CF(0, -0.40, 0), p.base, WOOD)
			c:box(V(2.10, 0.12, 1.30), CF(0, -0.80, 0), p.dark, WOOD)
			c:box(V(1.80, 0.16, 0.50), CF(0, 0.02, 0.30), BONE)
			for i = -3, 3 do
				c:box(V(0.16, 0.20, 0.10), CF(i * 0.22, 0.10, 0.48), i % 2 == 0 and INK or BONE)
			end
			face(c, -0.30, 0.62, 0.28, 0.12)
			c:box(V(1.90, 0.90, 0.12), CF(0, 0.50, -0.50) * ANG(-0.4, 0, 0), p.base, WOOD)
			c:box(V(0.50, 0.40, 0.08), CF(0, 0.55, -0.20) * ANG(-0.2, 0, 0), BONE)
			note(c, 0.80, 0.90, 0.20, p.glow)
			for _, s in ipairs(SIDES) do
				c:box(V(0.28, 0.14, 0.40), CF(0.70 * s, -0.96, 0.20), GOLD, METAL)
			end
		end,
	}

	---------------------------------------------------------------- MYTHIC

	-- A round rose window: stone tracery, glowing glass petals, a face in the
	-- oculus.
	S.ce_t_rosewindow = {
		label = "Gothic Rosewindow",
		set = "crimson_eclipse",
		tint = C3(180, 40, 90),
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.60, 0.30),
		back = CF(0, 0.20, -0.30),
		build = function(c, p)
			c:cyl(V(0.30, 2.00, 2.00), CF(0, 0.10, -0.10) * FACE, p.dark, SLATE)
			c:cyl(V(0.20, 1.70, 1.70), CF(0, 0.10, 0) * FACE, p.base, GLASS)
			c:cyl(V(0.16, 0.70, 0.70), CF(0, 0.10, 0.14) * FACE, p.pale)
			face(c, 0.16, 0.24, 0.18, 0.11)
			for i = 0, 7 do
				local a = i * PI / 4
				c:box(V(0.10, 0.70, 0.08), CF(0, 0.10, 0.08) * ANG(0, 0, a) * CF(0, 0.50, 0), GOLD, METAL)
				c:box(
					V(0.28, 0.28, 0.08),
					CF(0.70 * math.cos(a), 0.10 + 0.70 * math.sin(a), 0.12) * DIAMOND,
					(i % 2 == 0) and BLOOD or p.glow,
					NEON
				)
			end
			hoop(c, CF(0, 0.10, 0.20), 0.95, 10, GOLD, METAL, 0.06)
			for _, s in ipairs(SIDES) do
				c:box(V(0.30, 0.14, 0.30), CF(0.50 * s, -1.00, 0.10), p.deep)
			end
			c:star(V(0, 1.30, 0.20), 0.30, p.glow)
		end,
	}

	-- A miniature clocktower: four faces, a peaked roof and a glowing dial.
	S.ce_t_clocktower = {
		label = "Midnight Clocktower",
		set = "crimson_eclipse",
		tint = C3(70, 50, 100),
		head = CF(0, 1.80, 0),
		neck = CF(0, -0.50, 0.60),
		back = CF(0, 0.30, -0.60),
		build = function(c, p)
			c:box(V(1.20, 1.60, 1.20), CF(0, -0.20, 0), p.base, SLATE)
			c:box(V(1.40, 0.20, 1.40), CF(0, 0.70, 0), p.dark, SLATE)
			c:box(V(1.00, 0.80, 1.00), CF(0, 1.10, 0), p.light, SLATE)
			c:cyl(V(0.10, 0.70, 0.70), CF(0, 1.10, 0.52) * FACE, BONE)
			c:box(V(0.04, 0.22, 0.04), CF(0, 1.18, 0.58), INK)
			c:box(V(0.12, 0.04, 0.04), CF(0.06, 1.10, 0.58), INK)
			face(c, -0.10, 0.62, 0.24, 0.12)
			c:cone(V(1.30, 0.60, 1.30), CF(0, 1.70, 0), p.dark, SLATE)
			c:ball(V(0.20, 0.20, 0.20), CF(0, 2.06, 0), GOLD, METAL)
			c:box(V(0.40, 0.50, 0.10), CF(0, -0.60, 0.62), INK)
			for _, s in ipairs(SIDES) do
				c:box(V(0.30, 0.14, 0.40), CF(0.40 * s, -1.06, 0.20), p.deep)
				c:box(V(0.16, 0.30, 0.16), CF(0.55 * s, 0.40, 0.55), GOLD, METAL)
			end
			c:star(V(0.70, 1.50, 0.30), 0.24, p.glow)
		end,
	}

	-- A jewelled reliquary chest: gold bands, a crescent latch, a glow inside.
	S.ce_t_reliquary = {
		label = "Lunar Reliquary",
		set = "crimson_eclipse",
		tint = C3(200, 160, 50),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.50, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:box(V(1.80, 1.00, 1.20), CF(0, -0.30, 0), p.base, WOOD)
			c:box(V(1.90, 0.16, 1.30), CF(0, 0.30, 0), GOLD, METAL)
			c:box(V(1.70, 0.50, 1.10), CF(0, 0.60, 0) * ANG(-0.2, 0, 0), p.dark, WOOD)
			face(c, -0.20, 0.62, 0.28, 0.13)
			c:cyl(V(0.08, 0.40, 0.40), CF(0, -0.10, 0.62) * FACE, SILVER, METAL)
			c:cyl(V(0.06, 0.24, 0.24), CF(0.06, -0.10, 0.64) * FACE, p.glow, NEON)
			for _, y in ipairs({ -0.60, 0.00 }) do
				c:box(V(1.84, 0.10, 1.24), CF(0, y, 0), GOLD, METAL)
			end
			for _, s in ipairs(SIDES) do
				c:box(V(0.16, 0.16, 0.08), CF(0.50 * s, -0.30, 0.62) * DIAMOND, p.glow, NEON)
				c:box(V(0.30, 0.14, 0.40), CF(0.60 * s, -0.90, 0.20), GOLD, METAL)
			end
			c:star(V(0, 1.00, 0.20), 0.28, p.glow)
			c:light(p.glow, 1.0, 5)
		end,
	}

	-- A carillon of hanging bells on a gold frame, the biggest one a face.
	S.ce_t_carillon = {
		label = "Moon Carillon",
		set = "crimson_eclipse",
		tint = C3(200, 180, 60),
		head = CF(0, 1.60, 0),
		neck = CF(0, -0.70, 0.40),
		back = CF(0, 0.30, -0.40),
		build = function(c, p)
			c:box(V(2.00, 0.12, 0.40), CF(0, 1.10, 0), GOLD, METAL)
			c:box(V(0.12, 0.50, 0.12), CF(0, 1.40, 0), GOLD, METAL)
			hoop(c, CF(0, 1.60, 0), 0.16, 5, GOLD, METAL, 0.05)
			c:cyl(V(0.80, 0.90, 0.90), CF(0, 0.10, 0) * UP, p.base, METAL)
			c:cone(V(0.90, 0.40, 0.90), CF(0, -0.50, 0) * DOWN, p.base, METAL)
			face(c, 0.20, 0.46, 0.22, 0.12)
			c:box(V(0.10, 0.30, 0.10), CF(0, -0.80, 0), GOLD, METAL)
			c:ball(V(0.20, 0.20, 0.20), CF(0, -1.00, 0), GOLD, METAL)
			for _, x in ipairs({ -0.80, 0.80 }) do
				c:rod(V(x, 1.10, 0), V(x, 0.50, 0), 0.025, GOLD, METAL, false)
				c:cyl(V(0.40, 0.50, 0.50), CF(x, 0.20, 0) * UP, p.light, METAL)
				c:cone(V(0.50, 0.24, 0.50), CF(x, -0.10, 0) * DOWN, p.light, METAL)
			end
			note(c, -0.40, 0.90, 0.30, p.glow)
			for _, s in ipairs(SIDES) do
				c:box(V(0.26, 0.12, 0.30), CF(0.40 * s, -1.10, 0.10), p.deep)
			end
		end,
	}

	-- A tall lectern with an open moonlit book and a reading candle.
	S.ce_t_lectern = {
		label = "Midnight Lectern",
		set = "crimson_eclipse",
		tint = C3(100, 50, 40),
		head = CF(0, 1.60, 0),
		neck = CF(0, -0.50, 0.60),
		back = CF(0, 0.20, -0.60),
		build = function(c, p)
			c:box(V(0.80, 0.20, 0.80), CF(0, -1.00, 0), p.dark, WOOD)
			c:cyl(V(1.00, 0.30, 0.30), CF(0, -0.40, 0) * UP, p.base, WOOD)
			c:box(V(1.40, 0.16, 0.90), CF(0, 0.20, 0.10) * ANG(-0.35, 0, 0), p.base, WOOD)
			c:box(V(0.60, 0.06, 0.70), CF(-0.28, 0.36, 0.20) * ANG(-0.35, 0.1, 0), BONE)
			c:box(V(0.60, 0.06, 0.70), CF(0.28, 0.36, 0.20) * ANG(-0.35, -0.1, 0), BONE)
			face(c, 0.30, 0.50, 0.22, 0.11)
			c:box(V(0.14, 0.40, 0.14), CF(0.55, 0.50, 0.30), BONE)
			flame(c, 0.55, 0.84, 0.30, 0.8)
			c:box(V(0.16, 0.16, 0.06), CF(0, 0.50, 0.40) * DIAMOND, GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:box(V(0.28, 0.14, 0.36), CF(0.30 * s, -1.14, 0.20), p.deep)
				c:star(V(0.70 * s, 0.80, 0.10), 0.22, p.glow)
			end
			c:light(FLAME, 1.0, 5)
		end,
	}

	-- A cathedral steeple: pointed spire, belfry windows and a weathercock tip.
	S.ce_t_steeple = {
		label = "Crimson Steeple",
		set = "crimson_eclipse",
		tint = C3(140, 30, 50),
		head = CF(0, 1.90, 0),
		neck = CF(0, -0.50, 0.50),
		back = CF(0, 0.40, -0.50),
		build = function(c, p)
			c:box(V(1.20, 1.20, 1.20), CF(0, -0.40, 0), p.base, SLATE)
			face(c, -0.30, 0.62, 0.24, 0.12)
			c:box(V(0.40, 0.50, 0.10), CF(0, -0.50, 0.62), INK)
			c:box(V(1.40, 0.16, 1.40), CF(0, 0.30, 0), p.dark, SLATE)
			c:box(V(0.90, 0.60, 0.90), CF(0, 0.70, 0), p.light, SLATE)
			for _, s in ipairs(SIDES) do
				c:box(V(0.20, 0.30, 0.08), CF(0.30 * s, 0.70, 0.48), INK)
			end
			c:cone(V(1.20, 1.00, 1.20), CF(0, 1.40, 0), p.dark, SLATE)
			c:rod(V(0, 1.90, 0), V(0, 2.20, 0), 0.04, GOLD, METAL, false)
			c:box(V(0.30, 0.08, 0.08), CF(0.10, 2.16, 0), GOLD, METAL)
			c:cone(V(0.10, 0.16, 0.10), CF(0.28, 2.16, 0) * ANG(0, 0, -PI / 2), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:box(V(0.30, 0.14, 0.40), CF(0.40 * s, -1.06, 0.20), p.deep)
			end
			c:star(V(0.60, 1.60, 0.30), 0.26, p.glow)
		end,
	}

	---------------------------------------------------------------- DIVINE

	-- A monstrance: radiant sunburst holding a glowing moon host.
	S.ce_t_monstrance = {
		label = "Haloed Monstrance",
		set = "crimson_eclipse",
		tint = C3(230, 190, 60),
		head = CF(0, 1.60, 0),
		neck = CF(0, -0.70, 0.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			c:box(V(0.70, 0.20, 0.70), CF(0, -1.00, 0), GOLD, METAL)
			c:cyl(V(0.60, 0.20, 0.20), CF(0, -0.60, 0) * UP, GOLD, METAL)
			c:box(V(0.50, 0.40, 0.40), CF(0, -0.20, 0), GOLD, METAL)
			c:cyl(V(0.20, 0.90, 0.90), CF(0, 0.50, 0) * FACE, p.glow, NEON)
			face(c, 0.56, 0.12, 0.18, 0.10)
			for i = 0, 11 do
				local a = i * PI / 6
				c:box(V(0.12, 0.50, 0.08), CF(0, 0.50, 0) * ANG(0, 0, a) * CF(0, 0.70, 0), GOLD, METAL)
			end
			ring(c, CF(0, 0.50, 0), 0.95, 10, p.glow, NEON, 0.06)
			c:star(V(0, 1.50, 0), 0.34, WHITE)
			for _, s in ipairs(SIDES) do
				c:box(V(0.26, 0.12, 0.30), CF(0.28 * s, -1.14, 0.10), p.deep)
			end
			c:light(p.glow, 1.3, 7)
		end,
	}

	-- A bishop's crozier curled into a shepherd's hook, jewelled and glowing.
	S.ce_t_crozier = {
		label = "Lunar Crozier",
		set = "crimson_eclipse",
		tint = C3(160, 120, 200),
		head = CF(0, 1.80, 0),
		neck = CF(0, -0.80, 0.30),
		back = CF(0, 0.20, -0.30),
		build = function(c, p)
			c:cyl(V(1.40, 0.22, 0.22), CF(0, -0.20, 0) * UP, GOLD, METAL)
			c:box(V(0.40, 0.30, 0.40), CF(0, 0.60, 0), p.base, METAL)
			face(c, 0.66, 0.22, 0.16, 0.10)
			c:rod(V(0, 0.80, 0), V(0, 1.30, 0), 0.08, GOLD, METAL, false)
			c:rod(V(0, 1.30, 0), V(0.50, 1.50, 0), 0.08, GOLD, METAL, false)
			c:rod(V(0.50, 1.50, 0), V(0.70, 1.20, 0), 0.08, GOLD, METAL, false)
			c:cyl(V(0.16, 0.40, 0.40), CF(0.70, 1.00, 0) * FACE, p.glow, NEON)
			c:box(V(0.16, 0.16, 0.08), CF(0, 0.60, 0.22) * DIAMOND, BLOOD, NEON)
			c:ball(V(0.30, 0.30, 0.30), CF(0, -1.00, 0), GOLD, METAL)
			for i = 0, 4 do
				local a = i * 2 * PI / 5
				c:star(V(0.80 * math.cos(a), 0.60 + 0.20 * math.sin(a), 0.80 * math.sin(a)), 0.18, p.glow)
			end
			for _, s in ipairs(SIDES) do
				c:box(V(0.24, 0.12, 0.28), CF(0.24 * s, -1.14, 0.10), p.deep)
			end
		end,
	}

	-- A blood-moon diadem: crescent points, a central ruby and a halo ring.
	S.ce_t_diadem = {
		label = "Bloodmoon Diadem",
		set = "crimson_eclipse",
		tint = C3(200, 40, 70),
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.60, 0.30),
		back = CF(0, 0.20, -0.30),
		build = function(c, p)
			c:cyl(V(0.24, 1.60, 1.60), CF(0, 0.10, 0) * FACE, GOLD, METAL)
			c:cyl(V(0.20, 1.30, 1.30), CF(0, 0.10, 0.10) * FACE, p.base)
			face(c, 0.16, 0.22, 0.22, 0.12)
			for i = -2, 2 do
				c:cone(V(0.16, 0.40 + math.abs(i) * 0.06, 0.16), CF(i * 0.28, 0.90, 0.10), GOLD, METAL)
			end
			c:box(V(0.22, 0.22, 0.10), CF(0, 1.20, 0.16) * DIAMOND, BLOOD, NEON)
			hoop(c, CF(0, 0.10, 0.30), 0.90, 12, p.glow, NEON, 0.06)
			for _, s in ipairs(SIDES) do
				c:box(V(0.28, 0.12, 0.30), CF(0.40 * s, -0.80, 0.10), p.deep)
				c:star(V(0.90 * s, 0.50, 0.20), 0.22, p.glow)
			end
			c:light(BLOOD, 1.1, 6)
		end,
	}

	-- An eclipse chalice: stem, bowl of moonlight wine, a floating sip spark.
	S.ce_t_chalice = {
		label = "Eclipse Chalice",
		set = "crimson_eclipse",
		tint = C3(180, 50, 90),
		head = CF(0, 1.60, 0),
		neck = CF(0, -0.60, 0.50),
		back = CF(0, 0.20, -0.50),
		build = function(c, p)
			c:cyl(V(0.16, 0.80, 0.80), CF(0, -0.90, 0) * UP, GOLD, METAL)
			c:cyl(V(0.70, 0.24, 0.24), CF(0, -0.40, 0) * UP, GOLD, METAL)
			c:box(V(0.40, 0.30, 0.40), CF(0, 0.00, 0), GOLD, METAL)
			c:cyl(V(0.70, 1.20, 1.20), CF(0, 0.50, 0) * UP, p.base, METAL)
			c:cyl(V(0.30, 1.00, 1.00), CF(0, 0.60, 0) * UP, BLOOD, NEON)
			face(c, 0.40, 0.62, 0.24, 0.12)
			c:cyl(V(0.12, 1.30, 1.30), CF(0, 0.90, 0) * UP, GOLD, METAL)
			c:star(V(0.60, 1.20, 0.30), 0.28, p.glow)
			c:ball(V(0.20, 0.20, 0.20), CF(-0.50, 1.10, 0.20), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V(0.26, 0.12, 0.30), CF(0.30 * s, -1.06, 0.10), p.deep)
				c:box(V(0.14, 0.14, 0.06), CF(0.50 * s, 0.50, 0.60) * DIAMOND, GOLD, METAL)
			end
			c:light(BLOOD, 1.2, 6)
		end,
	}

	-- An umbra disk: the moon in totality, a red rim and a halo of beads.
	S.ce_t_umbra = {
		label = "Umbra Disk",
		set = "crimson_eclipse",
		tint = C3(30, 20, 40),
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.60, 0.30),
		back = CF(0, 0.20, -0.30),
		build = function(c, p)
			c:cyl(V(0.30, 1.90, 1.90), CF(0, 0.10, -0.06) * FACE, BLOOD, NEON)
			c:cyl(V(0.28, 1.60, 1.60), CF(0, 0.10, 0) * FACE, INK)
			c:cyl(V(0.16, 0.90, 0.90), CF(0, 0.10, 0.12) * FACE, CRATER)
			face(c, 0.16, 0.22, 0.20, 0.11)
			hoop(c, CF(0, 0.10, 0.20), 1.05, 14, p.glow, NEON, 0.05)
			for i = 0, 5 do
				local a = i * PI / 3
				c:ball(V(0.16, 0.16, 0.16), CF(1.10 * math.cos(a), 0.10 + 1.10 * math.sin(a), 0.20), p.glow, NEON)
			end
			for _, s in ipairs(SIDES) do
				c:box(V(0.28, 0.12, 0.30), CF(0.40 * s, -0.96, 0.10), p.deep)
			end
			c:star(V(0, 1.30, 0.20), 0.32, WHITE)
			c:light(BLOOD, 1.4, 8)
		end,
	}

	-- A sanguine coronet of twisted thorns and moon pearls.
	S.ce_t_coronet = {
		label = "Sanguine Coronet",
		set = "crimson_eclipse",
		tint = C3(160, 20, 50),
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.60, 0.30),
		back = CF(0, 0.20, -0.30),
		build = function(c, p)
			c:cyl(V(0.30, 1.50, 1.50), CF(0, 0.00, 0) * FACE, p.base, METAL)
			c:cyl(V(0.20, 1.20, 1.20), CF(0, 0.00, 0.12) * FACE, p.pale)
			face(c, 0.06, 0.24, 0.22, 0.12)
			for i = 0, 7 do
				local a = i * PI / 4
				c:rod(
					V(0.60 * math.cos(a), 0.20 + 0.60 * math.sin(a), 0.10),
					V(0.85 * math.cos(a), 0.50 + 0.85 * math.sin(a), 0.10),
					0.04,
					IRON,
					METAL,
					false
				)
				c:ball(V(0.14, 0.14, 0.14), CF(0.90 * math.cos(a), 0.55 + 0.90 * math.sin(a), 0.12), MOON, NEON)
			end
			c:box(V(0.20, 0.20, 0.10), CF(0, 1.10, 0.16) * DIAMOND, BLOOD, NEON)
			ring(c, CF(0, 0.00, 0), 0.85, 8, GOLD, METAL, 0.06)
			for _, s in ipairs(SIDES) do
				c:box(V(0.28, 0.12, 0.30), CF(0.40 * s, -0.86, 0.10), p.deep)
			end
		end,
	}

	-- An open belfry: four pillars, arched openings, a swinging bell with a face.
	S.ce_t_belfry = {
		label = "Vesper Belfry",
		set = "crimson_eclipse",
		tint = C3(90, 70, 110),
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.50, 0.60),
		back = CF(0, 0.30, -0.60),
		build = function(c, p)
			c:box(V(1.40, 0.20, 1.40), CF(0, -0.90, 0), p.dark, SLATE)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(V(0.20, 1.40, 0.20), CF(0.55 * s, -0.10, 0.55 * t), p.base, SLATE)
				end
			end
			c:box(V(1.50, 0.20, 1.50), CF(0, 0.70, 0), p.dark, SLATE)
			c:cone(V(1.60, 0.70, 1.60), CF(0, 1.20, 0), p.base, SLATE)
			c:cyl(V(0.60, 0.70, 0.70), CF(0, 0.10, 0) * UP, GOLD, METAL)
			c:cone(V(0.70, 0.30, 0.70), CF(0, -0.30, 0) * DOWN, GOLD, METAL)
			face(c, 0.20, 0.36, 0.18, 0.10)
			c:box(V(0.08, 0.24, 0.08), CF(0, -0.50, 0), GOLD, METAL)
			c:ball(V(0.16, 0.16, 0.16), CF(0, -0.66, 0), GOLD, METAL)
			c:star(V(0, 1.70, 0), 0.28, p.glow)
			for _, s in ipairs(SIDES) do
				c:box(V(0.28, 0.12, 0.36), CF(0.40 * s, -1.06, 0.20), p.deep)
			end
			note(c, 0.70, 0.90, 0.30, p.glow)
		end,
	}

	-- A cloister arcade: three arches, a moonlit walk and ivy.
	S.ce_t_cloister = {
		label = "Moon Cloister",
		set = "crimson_eclipse",
		tint = C3(140, 140, 170),
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.50, 0.60),
		back = CF(0, 0.20, -0.60),
		build = function(c, p)
			c:box(V(2.10, 0.20, 1.00), CF(0, -0.90, 0), p.dark, SLATE)
			c:box(V(2.10, 0.20, 1.00), CF(0, 0.70, 0), p.dark, SLATE)
			for _, x in ipairs({ -0.80, 0, 0.80 }) do
				c:box(V(0.20, 1.40, 0.20), CF(x - 0.35, -0.10, 0.30), p.base, SLATE)
				c:box(V(0.20, 1.40, 0.20), CF(x + 0.35, -0.10, 0.30), p.base, SLATE)
				c:box(V(0.70, 0.16, 0.20), CF(x, 0.50, 0.30), p.base, SLATE)
			end
			c:box(V(0.90, 0.90, 0.50), CF(0, -0.20, -0.10), p.light, SLATE)
			face(c, -0.10, 0.18, 0.22, 0.12)
			for _, s in ipairs(SIDES) do
				c:box(V(0.20, 0.50, 0.12), CF(0.90 * s, 0.20, 0.40), LEAF)
				c:box(V(0.28, 0.12, 0.36), CF(0.70 * s, -1.06, 0.20), p.deep)
			end
			c:cyl(V(0.12, 0.40, 0.40), CF(0.70, 1.00, 0) * FACE, MOON, NEON)
			c:star(V(-0.70, 1.00, 0.20), 0.24, p.glow)
		end,
	}

	-- A psaltery: trapezoid soundbox, glowing strings and a bow of moonlight.
	S.ce_t_psaltery = {
		label = "Haloed Psaltery",
		set = "crimson_eclipse",
		tint = C3(180, 100, 140),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.50, 0.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			c:box(V(1.80, 1.20, 0.40), CF(0, 0.00, 0), p.base, WOOD)
			c:box(V(1.40, 0.80, 0.20), CF(0, 0.00, 0.22), p.pale, WOOD)
			face(c, 0.10, 0.34, 0.26, 0.12)
			for i = -2, 2 do
				c:box(V(0.04, 0.90, 0.04), CF(i * 0.22, 0.00, 0.34), p.glow, NEON)
			end
			c:box(V(1.90, 0.12, 0.16), CF(0, 0.70, 0), GOLD, METAL)
			c:box(V(1.50, 0.12, 0.16), CF(0, -0.70, 0), GOLD, METAL)
			c:rod(V(0.90, -0.80, 0.20), V(1.10, 0.80, 0.20), 0.04, SILVER, METAL, false)
			hoop(c, CF(0, 0.00, 0.40), 0.80, 8, p.glow, NEON, 0.05)
			note(c, -0.80, 0.80, 0.20, p.glow)
			for _, s in ipairs(SIDES) do
				c:box(V(0.28, 0.12, 0.30), CF(0.60 * s, -0.96, 0.10), p.deep)
			end
		end,
	}

	-- A garden sundial under a blood moon, gnomon casting a neon shadow.
	S.ce_t_sundial = {
		label = "Crimson Sundial",
		set = "crimson_eclipse",
		tint = C3(170, 50, 60),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.50, 0.70),
		back = CF(0, 0.10, -0.70),
		build = function(c, p)
			c:cyl(V(0.30, 1.40, 1.40), CF(0, -0.80, 0) * UP, p.dark, SLATE)
			c:cyl(V(0.20, 1.80, 1.80), CF(0, -0.20, 0) * UP, p.base, SLATE)
			c:cyl(V(0.12, 1.50, 1.50), CF(0, -0.08, 0) * UP, GOLD, METAL)
			face(c, -0.30, 0.72, 0.26, 0.12)
			c:wedge(V(0.20, 0.50, 0.70), CF(0, 0.20, 0.10) * ANG(0, 0, 0), GOLD, METAL)
			c:box(V(0.08, 0.08, 0.80), CF(0.30, 0.00, 0.20) * ANG(0, 0.4, 0), p.glow, NEON)
			for i = 0, 7 do
				local a = i * PI / 4
				c:box(V(0.10, 0.06, 0.20), CF(0.70 * math.cos(a), -0.10, 0.70 * math.sin(a)), GOLD, METAL)
			end
			c:cyl(V(0.16, 0.50, 0.50), CF(0.80, 0.80, 0) * FACE, BLOOD, NEON)
			c:cyl(V(0.10, 0.30, 0.30), CF(0.86, 0.80, 0.06) * FACE, INK)
			for _, s in ipairs(SIDES) do
				c:box(V(0.30, 0.14, 0.36), CF(0.50 * s, -1.00, 0.20), p.deep)
			end
			c:light(BLOOD, 1.0, 5)
		end,
	}

	---------------------------------------------------------------- EXOTIC

	-- A whole crimson manor in miniature: gables, glowing windows, a garden
	-- moon on the lawn.
	S.ce_t_manor = {
		label = "Crimson Manor",
		set = "crimson_eclipse",
		tint = C3(120, 30, 50),
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.50, 0.80),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			c:box(V(2.10, 1.20, 1.40), CF(0, -0.20, 0), p.base)
			c:box(V(2.20, 0.16, 1.50), CF(0, 0.50, 0), p.dark)
			c:prism(V(0.70, 0.70, 2.10), CF(0, 0.90, 0.40) * ANG(0, PI / 2, 0), p.dark)
			face(c, 0.00, 0.72, 0.28, 0.13)
			c:box(V(0.40, 0.60, 0.10), CF(0, -0.50, 0.72), INK)
			for _, x in ipairs({ -0.70, 0.70 }) do
				c:box(V(0.30, 0.30, 0.08), CF(x, 0.10, 0.72), p.glow, NEON)
			end
			c:box(V(0.70, 0.80, 0.70), CF(0.80, 0.30, -0.20), p.light)
			c:cone(V(0.90, 0.50, 0.90), CF(0.80, 0.90, -0.20), p.dark)
			c:box(V(0.20, 0.20, 0.08), CF(0.80, 0.40, 0.18), p.glow, NEON)
			c:cyl(V(0.12, 0.40, 0.40), CF(-0.80, -0.70, 0.70) * FACE, MOON, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V(0.30, 0.14, 0.40), CF(0.70 * s, -0.90, 0.30), p.deep)
			end
			for i = 0, 3 do
				local a = i * PI / 2 + 0.4
				c:star(V(1.20 * math.cos(a), 0.80 + 0.30 * math.sin(a), 1.00 * math.sin(a)), 0.20, p.glow)
			end
			ring(c, CF(0, 1.40, 0), 0.50, 8, BLOOD, NEON, 0.05)
			c:light(p.glow, 1.4, 8)
		end,
	}

	-- Totality itself: a dark moon, a blazing corona and orbiting sparkles.
	S.ce_t_totality = {
		label = "Grand Totality",
		set = "crimson_eclipse",
		tint = C3(20, 16, 30),
		head = CF(0, 1.50, 0),
		neck = CF(0, -0.60, 0.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			c:cyl(V(0.40, 1.70, 1.70), CF(0, 0.10, 0) * FACE, INK)
			c:cyl(V(0.20, 1.40, 1.40), CF(0, 0.10, 0.16) * FACE, CRATER)
			face(c, 0.16, 0.28, 0.22, 0.12)
			for i = 0, 15 do
				local a = i * PI / 8
				local len = (i % 2 == 0) and 0.70 or 0.45
				c:box(V(0.10, len, 0.08), CF(0, 0.10, 0.08) * ANG(0, 0, a) * CF(0, 0.95, 0), FLAME, NEON)
			end
			hoop(c, CF(0, 0.10, 0.30), 1.15, 16, BLOOD, NEON, 0.06)
			for i = 0, 5 do
				local a = i * PI / 3 + 0.2
				c:star(V(1.30 * math.cos(a), 0.10 + 1.30 * math.sin(a), 0.30), 0.22, p.glow)
			end
			c:ball(V(0.24, 0.24, 0.24), CF(0, 1.40, 0.20), BLOOD, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V(0.28, 0.12, 0.30), CF(0.40 * s, -0.90, 0.10), p.deep)
			end
			c:light(FLAME, 1.6, 10)
		end,
	}

	return S
end
