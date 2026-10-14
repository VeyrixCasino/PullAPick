--[[ PetBodies/InfernalReignTop -- Infernal Reign's top bodies: one body per
	Epic-and-up pet, so each one is worn by that pet alone and no two of them
	share a silhouette. The set is black volcanic stone, wrought iron and lava
	channels -- forge craft and infernal ARCHITECTURE, never a demon portrait --
	so every body here is something that belongs in a volcano's workshop or in
	the citadel built on top of it: bellows, a crucible, a slag pot, a
	portcullis, a gatehouse, a molten fountain, and the pumice-and-ember
	creatures that live among them.

	Lava, ember, brass and soot are fixed (the glow and the brasswork are the
	set's signature); the stone, brick, clay, leather and ironwork itself come
	from p.*, so each pet wears its own tint over the same shape.

	Epic stays charming and clean: hand tools and small creatures. Legendary
	adds wrought-iron and brass ornament. Mythic, Divine and Exotic carry neon
	magma, p.glow, point light and sparkle, echoing the top packs "Infernal
	Citadel" and "Ninth Circle". See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, WHITE, METAL, NEON, GLASS, SLATE, WOOD = K.INK, K.WHITE, K.METAL, K.NEON, K.GLASS, K.SLATE, K.WOOD
	local S = {}
	local SET = "infernal_reign"
	local SIDES = { -1, 1 }
	local V3, CF, ANG = Vector3.new, CFrame.new, CFrame.Angles
	local PI = math.pi
	local UP = ANG(0, 0, PI / 2) -- a cylinder standing on its end
	local FRONT = ANG(0, PI / 2, 0) -- a cylinder's flat face to the front
	local DIAMOND = ANG(0, 0, PI / 4) -- a square turned onto its point, face-on

	-- The fire, the brass and the soot never repaint: they are what makes the
	-- set read as a forge whatever colour the pet is.
	local LAVA = C3(255, 116, 28)
	local EMBER = C3(255, 196, 70)
	local WHITEHOT = C3(255, 244, 206)
	local BRASS = C3(232, 186, 80)
	local SOOT = C3(38, 34, 40)
	local COAL = C3(46, 42, 48)
	local STEAM = C3(226, 232, 240)
	local HORN = C3(236, 224, 200)
	local LEATHER = C3(126, 84, 54)
	local TIMBER = C3(118, 80, 48)

	-- Cartoon eyes and a small smile on a flat front at depth `z`.
	local function face(c, y, z, spread, r, iris)
		c:eyes(y, z + r * 0.3, spread, r, iris)
		c:box(V3(r * 1.6, r * 0.45, 0.06), CF(0, y - r * 2.0, z + 0.02), INK)
	end

	-- Warm cheeks either side of a face.
	local function blush(c, x, y, z)
		for _, s in ipairs(SIDES) do
			c:box(V3(0.20, 0.10, 0.05), CF(x * s, y, z), EMBER)
		end
	end

	-- A tongue of flame with a white-hot heart inside it.
	local function flame(c, pos, w, h, colour)
		c:cone(V3(w, h, w), CF(pos), colour or LAVA, NEON)
		c:cone(V3(w * 0.52, h * 0.58, w * 0.52), CF(pos + V3(0, h * 0.06, 0)), WHITEHOT, NEON)
	end

	-- Brass rivets at a list of { x, y, z } points.
	local function rivets(c, list, d)
		for _, v in ipairs(list) do
			c:ball(V3(d, d, d), CF(v[1], v[2], v[3]), BRASS, METAL)
		end
	end

	-- Four stubby feet under a body.
	local function feet(c, colour, mat, x, y, z, sz)
		for _, s in ipairs(SIDES) do
			for _, t in ipairs(SIDES) do
				c:box(sz or V3(0.42, 0.24, 0.44), CF(x * s, y, z * t), colour, mat)
			end
		end
	end

	--------------------------------------------------------------------------
	-- EPIC: the forge's hand tools and its smallest creatures, charming and clean.
	--------------------------------------------------------------------------

	-- A pair of great leather bellows: wooden boards above and below, pleated
	-- leather squeezed between them, and an iron nozzle for a snout.
	S.ir_t_bellows = {
		label = "Forge Bellows",
		set = SET,
		tint = C3(150, 92, 52),
		head = CF(0, 1.00, -0.40),
		neck = CF(0, -0.30, 0.90),
		back = CF(0, 0.70, -0.90),
		build = function(c, p)
			c:box(V3(1.40, 0.22, 1.70), CF(0, 0.54, -0.10), p.dark, WOOD)
			c:box(V3(1.40, 0.22, 1.70), CF(0, -0.60, -0.10), p.dark, WOOD)
			for i, y in ipairs({ 0.30, 0.06, -0.18, -0.40 }) do
				c:box(V3(1.26 + i * 0.03, 0.20, 1.54), CF(0, y, -0.10), i % 2 == 0 and p.base or p.light)
			end
			-- The front plate carries the face; the air nozzle is its nose.
			c:box(V3(1.08, 1.00, 0.16), CF(0, -0.03, 0.80), p.pale)
			c:eyes(0.26, 0.92, 0.30, 0.15)
			blush(c, 0.46, 0.00, 0.89)
			c:cyl(V3(0.66, 0.30, 0.30), CF(0, -0.30, 1.14) * FRONT, p.deep, METAL)
			c:cyl(V3(0.10, 0.42, 0.42), CF(0, -0.30, 1.44) * FRONT, SOOT, METAL)
			c:ball(V3(0.26, 0.26, 0.26), CF(0, -0.30, 1.54), EMBER, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V3(1.46, 0.08, 0.26), CF(0, 0.54 * s, 0.56), p.deep, METAL)
				c:rod(V3(0.42 * s, 0.60, -0.76), V3(0.56 * s, 1.18, -1.00), 0.07, p.deep, WOOD, false)
				c:ball(V3(0.20, 0.20, 0.20), CF(0.56 * s, 1.21, -1.02), p.dark, METAL)
				c:box(V3(0.38, 0.22, 0.42), CF(0.48 * s, -0.82, 0.24), SOOT, METAL)
			end
			rivets(c, { { -0.50, 0.54, 0.70 }, { 0.50, 0.54, 0.70 }, { -0.50, -0.60, 0.70 }, { 0.50, -0.60, 0.70 } }, 0.13)
		end,
	}

	-- A fireclay crucible brimming with white-hot metal, stood in an iron
	-- trivet, with a pouring lip and a soot smudge under it.
	S.ir_t_crucible = {
		label = "Smelt Crucible",
		set = SET,
		tint = C3(196, 120, 86),
		scale = 1.15,
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.40, 0.86),
		back = CF(0, 0.20, -0.86),
		build = function(c, p)
			c:cyl(V3(1.30, 1.56, 1.56), CF(0, 0.00, 0) * UP, p.base, SLATE)
			c:cyl(V3(0.26, 1.18, 1.18), CF(0, -0.78, 0) * UP, p.dark, SLATE)
			c:cyl(V3(0.18, 1.72, 1.72), CF(0, 0.58, 0) * UP, p.dark, SLATE)
			c:cyl(V3(0.10, 1.46, 1.46), CF(0, 0.66, 0) * UP, LAVA, NEON)
			c:cyl(V3(0.07, 0.86, 0.86), CF(0, 0.71, 0) * UP, WHITEHOT, NEON)
			c:ball(V3(0.30, 0.30, 0.30), CF(0.26, 0.74, 0.10), LAVA, NEON)
			-- The lip, a frozen drip off it, and the face below both.
			c:box(V3(0.56, 0.22, 0.40), CF(0, 0.58, 0.88) * ANG(0.45, 0, 0), p.light, SLATE)
			c:box(V3(0.18, 0.44, 0.14), CF(0, 0.28, 0.90), LAVA, NEON)
			c:box(V3(0.34, 0.30, 0.06), CF(0, 0.26, 0.80), SOOT)
			face(c, -0.14, 0.78, 0.30, 0.15)
			blush(c, 0.48, -0.40, 0.72)
			-- The trivet it stands in.
			c:cyl(V3(0.10, 1.22, 1.22), CF(0, -0.90, 0) * UP, p.deep, METAL)
			for k = 0, 2 do
				local a = k * 2 * PI / 3 + PI / 6
				local sx, sz = math.sin(a), math.cos(a)
				c:rod(V3(0.50 * sx, -0.86, 0.50 * sz), V3(0.84 * sx, -1.16, 0.84 * sz), 0.09, p.deep, METAL, false)
				c:box(V3(0.32, 0.14, 0.32), CF(0.88 * sx, -1.20, 0.88 * sz), SOOT, METAL)
			end
		end,
	}

	-- A pair of smith's tongs stood on their handles: the rivet boss is its
	-- face, and the jaws hold a glowing billet overhead.
	S.ir_t_tongs = {
		label = "Forge Tongs",
		set = SET,
		tint = C3(150, 158, 176),
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.60, 0.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.10 * s, 0.30, 0), V3(0.42 * s, 1.18, 0), 0.10, p.base, METAL, false)
				c:box(V3(0.44, 0.28, 0.42), CF(0.48 * s, 1.28, 0) * ANG(0, 0, -0.35 * s), p.light, METAL)
				c:rod(V3(0.10 * s, 0.30, 0), V3(0.58 * s, -1.00, 0), 0.09, p.base, METAL, false)
				c:box(V3(0.26, 0.38, 0.30), CF(0.62 * s, -1.10, 0), LEATHER)
				c:box(V3(0.34, 0.16, 0.44), CF(0.66 * s, -1.30, 0.04), SOOT, METAL)
			end
			c:cyl(V3(0.26, 0.90, 0.90), CF(0, 0.30, 0) * FRONT, p.light, METAL)
			c:cyl(V3(0.12, 0.30, 0.30), CF(0, 0.28, 0.16) * FRONT, BRASS, METAL)
			c:eyes(0.50, 0.18, 0.21, 0.12)
			c:box(V3(0.24, 0.06, 0.06), CF(0, 0.06, 0.15), INK)
			blush(c, 0.34, 0.14, 0.14)
			-- The billet, still white in the middle.
			c:box(V3(0.72, 0.32, 0.40), CF(0, 1.34, 0), LAVA, NEON)
			c:box(V3(0.46, 0.16, 0.26), CF(0, 1.34, 0), WHITEHOT, NEON)
			rivets(c, { { -0.30, 0.68, 0.14 }, { 0.30, 0.68, 0.14 } }, 0.12)
		end,
	}

	-- A beehive brick kiln: courses of brick narrowing to a dome, an arched
	-- fire mouth with the blaze behind its grate, and a sooty chimney.
	S.ir_t_kiln = {
		label = "Brick Kiln",
		set = SET,
		tint = C3(178, 90, 48),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.70, 0.92),
		back = CF(0, 0.10, -0.92),
		build = function(c, p)
			c:box(V3(2.00, 0.26, 1.90), CF(0, -0.98, 0), p.dark, SLATE)
			c:box(V3(1.76, 1.00, 1.66), CF(0, -0.36, 0), p.base, SLATE)
			c:box(V3(1.84, 0.12, 1.74), CF(0, 0.14, 0), p.dark, SLATE)
			c:box(V3(1.46, 0.46, 1.38), CF(0, 0.42, 0), p.light, SLATE)
			c:cone(V3(1.40, 0.56, 1.32), CF(0, 0.90, 0), p.base, SLATE)
			c:cyl(V3(0.36, 0.40, 0.40), CF(0, 1.20, 0) * UP, p.deep, METAL)
			c:ball(V3(0.32, 0.32, 0.32), CF(0, 1.50, 0), SOOT).Transparency = 0.35
			-- The fire mouth.
			c:box(V3(1.04, 0.74, 0.14), CF(0, -0.44, 0.86), p.deep, METAL)
			c:box(V3(0.78, 0.56, 0.10), CF(0, -0.44, 0.94), LAVA, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.07, 0.58, 0.08), CF(0.18 * s, -0.44, 0.98), SOOT, METAL)
				c:box(V3(0.06, 0.12, 1.72), CF(0.90 * s, -0.20, 0), p.deep, METAL)
				c:box(V3(1.82, 0.12, 0.06), CF(0, -0.20, 0.84 * s), p.deep, METAL)
			end
			c:eyes(0.00, 0.88, 0.34, 0.17)
			blush(c, 0.56, -0.20, 0.85)
			-- Spare bricks stacked against its flank.
			c:box(V3(0.42, 0.22, 0.48), CF(0.94, -0.74, 0.54), p.light, SLATE)
			c:box(V3(0.42, 0.22, 0.48), CF(0.90, -0.52, 0.50) * ANG(0, 0.2, 0), p.base, SLATE)
		end,
	}

	-- A foundry ladle hung in its yoke: a banded iron drum brimming with slag,
	-- a pouring lip with a drip frozen on it, and a brass tilting wheel.
	S.ir_t_ladle = {
		label = "Slag Ladle",
		set = SET,
		tint = C3(128, 106, 94),
		scale = 1.15,
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.40, 0.84),
		back = CF(0, 0.20, -0.84),
		build = function(c, p)
			c:cyl(V3(1.20, 1.50, 1.50), CF(0, 0.10, 0) * UP, p.base, METAL)
			c:cyl(V3(0.14, 1.62, 1.62), CF(0, 0.62, 0) * UP, p.dark, METAL)
			c:cyl(V3(0.12, 1.58, 1.58), CF(0, -0.30, 0) * UP, p.dark, METAL)
			c:cyl(V3(0.08, 1.38, 1.38), CF(0, 0.70, 0) * UP, LAVA, NEON)
			c:box(V3(0.50, 0.20, 0.38), CF(0, 0.58, 0.82) * ANG(0.5, 0, 0), p.light, METAL)
			c:box(V3(0.18, 0.46, 0.14), CF(0, 0.30, 0.86), LAVA, NEON)
			face(c, -0.14, 0.76, 0.32, 0.15)
			blush(c, 0.48, -0.40, 0.70)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.16, 1.80, 0.40), CF(0.82 * s, 0.10, -0.10), p.dark, METAL)
				c:cyl(V3(0.26, 0.34, 0.34), CF(0.76 * s, 0.10, -0.10), BRASS, METAL)
				c:box(V3(0.30, 0.26, 0.42), CF(0.84 * s, -0.90, -0.10), SOOT, METAL)
			end
			c:cyl(V3(1.76, 0.18, 0.18), CF(0, 0.96, -0.10), p.dark, METAL)
			c:cyl(V3(0.10, 0.62, 0.62), CF(0.94, 0.44, -0.10), BRASS, METAL)
			c:box(V3(0.08, 0.58, 0.10), CF(0.94, 0.44, -0.10), BRASS, METAL)
			c:box(V3(0.08, 0.10, 0.58), CF(0.94, 0.44, -0.10), BRASS, METAL)
			-- A skimming rake hooked over the yoke.
			c:rod(V3(-0.88, -0.30, 0.34), V3(-1.04, 0.92, 0.22), 0.05, TIMBER, WOOD, false)
			c:box(V3(0.34, 0.08, 0.20), CF(-0.88, -0.34, 0.36), p.deep, METAL)
		end,
	}

	-- A treadle grindstone: the wheel's flat face is the pet's face, its iron
	-- hub the nose, and a spray of sparks runs off the rim where a bar rests.
	S.ir_t_grindstone = {
		label = "Spark Grindstone",
		set = SET,
		tint = C3(152, 148, 146),
		head = CF(0, 1.60, 0),
		neck = CF(0, -0.60, 0.46),
		back = CF(0, 0.20, -0.46),
		build = function(c, p)
			c:cyl(V3(0.40, 1.90, 1.90), CF(0, 0.30, 0) * FRONT, p.base, SLATE)
			c:cyl(V3(0.44, 1.56, 1.56), CF(0, 0.30, 0) * FRONT, p.light, SLATE)
			c:cyl(V3(0.50, 0.34, 0.34), CF(0, 0.30, 0) * FRONT, p.deep, METAL)
			c:eyes(0.60, 0.26, 0.28, 0.14)
			c:box(V3(0.26, 0.07, 0.06), CF(0, 0.02, 0.24), INK)
			blush(c, 0.46, 0.08, 0.23)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.18, 1.40, 0.30), CF(0.92 * s, -0.10, 0), p.deep, WOOD)
				c:box(V3(0.44, 0.20, 0.70), CF(0.92 * s, -0.86, 0), p.dark, WOOD)
				c:cyl(V3(0.22, 0.30, 0.30), CF(0.88 * s, 0.30, 0), p.dark, METAL)
			end
			c:box(V3(2.00, 0.18, 0.26), CF(0, -0.52, 0.24), p.dark, WOOD)
			c:rod(V3(0.97, 0.30, 0), V3(1.20, 0.30, 0), 0.05, BRASS, METAL, false)
			c:rod(V3(1.20, 0.30, 0), V3(1.20, 0.30, 0.32), 0.05, BRASS, METAL, false)
			c:ball(V3(0.20, 0.20, 0.20), CF(1.20, 0.30, 0.36), TIMBER, WOOD)
			-- The bar being sharpened, and the sparks flying off the rim.
			c:box(V3(0.74, 0.12, 0.26), CF(-0.16, 1.30, 0.04) * ANG(0, 0, 0.18), p.light, METAL)
			for _, v in ipairs({ { 0.30, 1.24, 0.14 }, { 0.46, 1.18, -0.08 }, { 0.58, 1.08, 0.06 } }) do
				c:ball(V3(0.14, 0.14, 0.14), CF(v[1], v[2], v[3]), EMBER, NEON)
			end
			-- The quenching trough slung under the frame.
			c:box(V3(1.10, 0.34, 0.60), CF(0, -0.70, 0.40), p.dark, SLATE)
			c:box(V3(0.86, 0.08, 0.44), CF(0, -0.56, 0.40), p.deep)
		end,
	}

	-- A coal scuttle tipped forward on its pedestal foot, heaped with coal and
	-- a couple of nuggets still alight, its shovel hooked on the side.
	S.ir_t_scuttle = {
		label = "Coal Scuttle",
		set = SET,
		tint = C3(96, 60, 40),
		head = CF(0, 1.10, -0.20),
		neck = CF(0, -0.30, 0.66),
		back = CF(0, 0.40, -0.76),
		build = function(c, p)
			c:box(V3(1.40, 1.10, 1.30), CF(0, 0.10, -0.10), p.base, METAL)
			c:box(V3(1.30, 0.56, 0.68), CF(0, 0.40, 0.70) * ANG(0.5, 0, 0), p.light, METAL)
			c:box(V3(1.44, 0.10, 1.34), CF(0, -0.32, -0.10), p.dark, METAL)
			c:eyes(-0.10, 0.60, 0.32, 0.16)
			c:box(V3(0.30, 0.08, 0.06), CF(0, -0.42, 0.56), INK)
			blush(c, 0.50, -0.30, 0.54)
			-- The heap inside the scoop.
			for _, v in ipairs({ { -0.34, 0.58, 0.22 }, { 0.10, 0.66, 0.10 }, { 0.40, 0.56, 0.26 }, { -0.06, 0.60, 0.44 } }) do
				c:box(V3(0.34, 0.30, 0.34), CF(v[1], v[2], v[3]) * ANG(0.4, 0.5, 0.2), COAL, SLATE)
			end
			c:box(V3(0.26, 0.24, 0.26), CF(-0.14, 0.78, 0.22) * ANG(0.3, 0.4, 0.3), LAVA, NEON)
			c:box(V3(0.20, 0.18, 0.20), CF(0.28, 0.74, 0.34) * ANG(0.2, 0.6, 0.1), EMBER, NEON)
			-- Pedestal foot and a carrying handle over the back.
			c:cyl(V3(0.24, 0.90, 0.90), CF(0, -0.50, -0.10) * UP, p.dark, METAL)
			c:cyl(V3(0.16, 1.26, 1.26), CF(0, -0.70, -0.10) * UP, SOOT, METAL)
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.70 * s, 0.50, -0.20), V3(0.40 * s, 0.98, -0.52), 0.05, BRASS, METAL, false)
			end
			c:rod(V3(-0.40, 0.98, -0.52), V3(0.40, 0.98, -0.52), 0.06, BRASS, METAL, false)
			-- The little shovel.
			c:rod(V3(0.70, -0.22, 0.30), V3(0.92, 0.76, 0.18), 0.05, TIMBER, WOOD, false)
			c:box(V3(0.34, 0.10, 0.34), CF(0.70, -0.26, 0.32), p.light, METAL)
		end,
	}

	-- A cinder chough: a glossy black crag bird with a red-hot curved bill and
	-- bright legs, ash on its wing tips, carrying an ember home.
	S.ir_t_chough = {
		label = "Cinder Chough",
		set = SET,
		tint = C3(44, 40, 52),
		scale = 1.05,
		head = CF(0, 1.16, 0.10),
		neck = CF(0, -0.10, 0.84),
		back = CF(0, 0.30, -0.76),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V3(1.50, 1.70, 1.50),
				eyeY = 0.34, eyeSpread = 0.32, eyeSize = V3(0.40, 0.48, 0.20),
				mouth = false,
				bib = { w = 0.84, h = 0.70, y = -0.36, color = p.light },
				legSize = V3(0.16, 0.42, 0.24), legX = 0.28, legZ = { 0.08 }, legY = -0.94, legColor = LAVA,
				tail = false,
			})
			c:cone(V3(0.26, 0.46, 0.24), CF(0, 0.06, 0.88) * ANG(1.35, 0, 0), LAVA)
			c:cone(V3(0.20, 0.28, 0.18), CF(0, -0.10, 1.12) * ANG(1.85, 0, 0), LAVA)
			c:ball(V3(0.24, 0.24, 0.24), CF(0, -0.20, 1.22), EMBER, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.14, 0.86, 1.06), CF(0.78 * s, 0.10, -0.18) * ANG(0.22, 0, 0.12 * s), p.dark)
				c:box(V3(0.16, 0.26, 0.40), CF(0.80 * s, -0.26, -0.56) * ANG(0.22, 0, 0.12 * s), p.pale)
				c:box(V3(0.24, 0.08, 0.34), CF(0.28 * s, -1.14, 0.18), LAVA)
				c:box(V3(0.12, 0.34, 0.12), CF(0.18 * s, 1.04, -0.08) * ANG(-0.3, 0, -0.3 * s), p.light)
			end
			c:box(V3(0.42, 0.14, 0.90), CF(0, -0.04, -1.08) * ANG(0.4, 0, 0), p.dark)
			c:box(V3(0.36, 0.12, 0.34), CF(0, 0.22, -1.56) * ANG(0.4, 0, 0), p.pale)
		end,
	}

	-- A forge scarab: an iron-plated beetle with a lava seam down its back and
	-- a brass head shield, rolling a glowing cinder along in front of it.
	S.ir_t_scarab = {
		label = "Forge Scarab",
		set = SET,
		tint = C3(72, 152, 140),
		scale = 1.10,
		head = CF(0, 0.70, 0.40),
		neck = CF(0, -0.30, 0.96),
		back = CF(0, 0.74, -0.40),
		build = function(c, p)
			c:ovoid(V3(1.70, 0.94, 1.70), CF(0, 0.08, -0.14), p.base, METAL)
			c:box(V3(0.14, 0.24, 1.56), CF(0, 0.50, -0.14), LAVA, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.70, 0.44, 1.50), CF(0.48 * s, 0.26, -0.14) * ANG(0, 0, 0.2 * s), p.dark, METAL)
				c:box(V3(0.10, 0.14, 1.20), CF(0.80 * s, 0.10, -0.14), p.light, METAL)
				for _, z in ipairs({ 0.34, -0.10, -0.54 }) do
					c:rod(V3(0.74 * s, -0.18, z), V3(1.08 * s, -0.62, z + 0.08), 0.06, p.deep, METAL, false)
				end
			end
			-- The head shield, notched like a real scarab's.
			c:box(V3(1.10, 0.44, 0.60), CF(0, -0.02, 0.84), BRASS, METAL)
			for _, x in ipairs({ -0.36, 0, 0.36 }) do
				c:cone(V3(0.22, 0.24, 0.22), CF(x, 0.04, 1.12) * ANG(PI / 2, 0, 0), BRASS, METAL)
			end
			c:eyes(0.08, 1.04, 0.36, 0.15)
			c:box(V3(0.28, 0.07, 0.06), CF(0, -0.18, 1.10), INK)
			-- The cinder it pushes.
			c:ball(V3(0.70, 0.70, 0.70), CF(0, -0.38, 1.44), COAL, SLATE)
			c:box(V3(0.22, 0.22, 0.22), CF(-0.18, -0.20, 1.66) * ANG(0.4, 0.4, 0), LAVA, NEON)
			c:box(V3(0.18, 0.18, 0.18), CF(0.22, -0.48, 1.70) * ANG(0.2, 0.6, 0), EMBER, NEON)
		end,
	}

	-- An ember skink: long, low and glassy black, with a bright banded belly
	-- and glowing stripes running down both flanks.
	S.ir_t_skink = {
		label = "Ember Skink",
		set = SET,
		tint = C3(124, 62, 156),
		scale = 1.15,
		head = CF(0, 0.76, 0.46),
		neck = CF(0, -0.26, 1.02),
		back = CF(0, 0.70, -0.50),
		build = function(c, p)
			block(c, p, {
				bodySize = V3(1.60, 1.04, 1.90),
				eyeY = 0.16, eyeSpread = 0.40, eyeSize = V3(0.44, 0.50, 0.20),
				mouthY = -0.26, mouthSize = V3(0.62, 0.10, 0.12),
				bib = { w = 0.90, h = 0.54, y = -0.34, color = p.pale },
				legSize = V3(0.50, 0.26, 0.42), legX = 0.90, legY = -0.40, legZ = { 0.54, -0.54 }, legColor = p.dark,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V3(0.06, 0.14, 1.64), CF(0.81 * s, 0.26, -0.05), LAVA, NEON)
				c:box(V3(0.06, 0.10, 1.40), CF(0.78 * s, -0.12, -0.05), EMBER, NEON)
				c:box(V3(0.30, 0.10, 0.34), CF(1.02 * s, -0.52, 0.62), p.deep)
				c:box(V3(0.30, 0.10, 0.34), CF(1.02 * s, -0.52, -0.46), p.deep)
			end
			-- Scale ridges along the spine, then the tapering tail.
			for i, z in ipairs({ 0.52, 0.10, -0.32 }) do
				c:box(V3(0.80 - i * 0.08, 0.12, 0.26), CF(0, 0.60, z), p.dark)
			end
			c:box(V3(0.70, 0.56, 0.70), CF(0.06, -0.16, -1.22) * ANG(0, 0.18, 0), p.base)
			c:box(V3(0.52, 0.44, 0.60), CF(0.26, -0.22, -1.70) * ANG(0, 0.52, 0), p.dark)
			c:box(V3(0.34, 0.30, 0.46), CF(0.60, -0.26, -2.00) * ANG(0, 0.90, 0), p.base)
			c:box(V3(0.10, 0.10, 0.34), CF(0.80, -0.26, -2.14) * ANG(0, 1.10, 0), LAVA, NEON)
		end,
	}

	-- A pumice marmot: a chubby pale rock-furred whistler sat up on its
	-- haunches, pitted all over, hugging a stone that is still warm.
	S.ir_t_marmot = {
		label = "Pumice Marmot",
		set = SET,
		tint = C3(208, 198, 184),
		head = CF(0, 1.26, 0.10),
		neck = CF(0, -0.36, 0.90),
		back = CF(0, 0.30, -0.84),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.70, 1.76, 1.60),
				eyeY = 0.30, eyeSpread = 0.34, eyeSize = V3(0.44, 0.52, 0.20),
				snout = { w = 0.62, h = 0.38, d = 0.38, y = -0.16, color = p.pale, nose = SOOT },
				bib = { w = 0.84, h = 0.70, y = -0.46, color = p.light },
				legSize = V3(0.34, 0.24, 0.44), legX = 0.44, legY = -0.86, legZ = { 0.26 }, legColor = p.dark,
				tail = false,
			})
			c:box(V3(0.22, 0.20, 0.08), CF(-0.09, -0.34, 0.92), WHITE)
			c:box(V3(0.22, 0.20, 0.08), CF(0.09, -0.34, 0.92), WHITE)
			for _, s in ipairs(SIDES) do
				c:round(V3(0.34, 0.30, 0.16), CF(0.56 * s, 0.92, 0.04), p.light)
				c:box(V3(0.28, 0.46, 0.34), CF(0.56 * s, -0.36, 0.56) * ANG(0, 0, 0.3 * s), p.base)
			end
			-- Pumice pits, and the warm stone it is holding.
			for _, v in ipairs({ { -0.52, 0.52, 0.66 }, { 0.46, 0.60, 0.62 }, { -0.70, -0.10, 0.52 }, { 0.72, 0.10, 0.44 }, { 0.10, 0.84, -0.40 } }) do
				c:box(V3(0.18, 0.18, 0.12), CF(v[1], v[2], v[3]), p.deep)
			end
			c:box(V3(0.52, 0.44, 0.44), CF(0, -0.44, 0.84), COAL, SLATE)
			c:box(V3(0.18, 0.30, 0.08), CF(0, -0.44, 1.04), LAVA, NEON)
			c:box(V3(0.46, 0.44, 0.50), CF(0, -0.28, -0.98), p.light)
			c:box(V3(0.34, 0.34, 0.40), CF(0, -0.10, -1.30) * ANG(0.5, 0, 0), p.base)
		end,
	}

	-- A magma lily: six obsidian petals round a glowing heart, on a basalt
	-- stem rooted in a cracked rock.
	S.ir_t_lily = {
		label = "Magma Lily",
		set = SET,
		tint = C3(210, 30, 86),
		head = CF(0, 1.60, 0),
		neck = CF(0, -0.20, 0.50),
		back = CF(0, 0.60, -0.50),
		build = function(c, p)
			local at = CF(0, 0.50, 0)
			for k = 0, 5 do
				local a = k * PI / 3
				local lit = k % 2 == 0
				c:box(V3(0.46, 0.80, 0.22), at * ANG(0, 0, a) * CF(0, 0.78, -0.08) * ANG(0.35, 0, 0), lit and p.base or p.dark)
				c:cone(V3(0.34, 0.34, 0.20), at * ANG(0, 0, a) * CF(0, 1.22, -0.14) * ANG(0.35, 0, 0), lit and p.light or p.base)
			end
			c:cyl(V3(0.30, 1.00, 1.00), at * FRONT, p.dark, SLATE)
			c:cyl(V3(0.14, 0.80, 0.80), at * CF(0, 0, 0.16) * FRONT, LAVA, NEON)
			face(c, 0.58, 0.24, 0.20, 0.12)
			blush(c, 0.30, 0.32, 0.22)
			-- Stamens, stem, leaves and the rock it grew out of.
			for _, x in ipairs({ -0.22, 0.22 }) do
				c:rod(V3(x, 0.84, 0.18), V3(x * 1.5, 1.16, 0.30), 0.03, p.deep, nil, false)
				c:ball(V3(0.14, 0.14, 0.14), CF(x * 1.5, 1.18, 0.31), EMBER, NEON)
			end
			c:rod(V3(0, 0.22, 0), V3(0, -0.64, 0), 0.11, p.deep, SLATE, false)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.56, 0.10, 0.36), CF(0.40 * s, -0.16, 0.06) * ANG(0, 0, 0.45 * s), p.dark, SLATE)
				c:box(V3(0.18, 0.06, 0.18), CF(0.56 * s, -0.08, 0.08), LAVA, NEON)
			end
			c:box(V3(1.30, 0.44, 1.20), CF(0, -0.82, 0), p.deep, SLATE)
			c:box(V3(1.10, 0.20, 1.00), CF(0, -1.06, 0), p.dark, SLATE)
			c:box(V3(0.08, 0.10, 0.90), CF(0.34, -0.72, 0), LAVA, NEON)
		end,
	}

	-- A cinder cricket: glowing wing covers it rubs together, long back legs
	-- folded high, and antennae with ember tips.
	S.ir_t_cricket = {
		label = "Cinder Cricket",
		set = SET,
		tint = C3(190, 230, 40),
		scale = 1.10,
		head = CF(0, 0.84, 0.44),
		neck = CF(0, -0.30, 0.96),
		back = CF(0, 0.76, -0.50),
		build = function(c, p)
			c:ovoid(V3(0.94, 0.86, 0.84), CF(0, 0.12, 0.70), p.base)
			c:ovoid(V3(1.14, 0.92, 1.50), CF(0, 0.16, -0.40), p.dark)
			c:box(V3(1.18, 0.14, 1.20), CF(0, 0.58, -0.40), p.light)
			c:box(V3(0.50, 0.16, 1.04), CF(0, 0.66, -0.44) * ANG(0, 0, 0.06), LAVA, NEON)
			c:eyes(0.26, 1.08, 0.28, 0.15)
			c:box(V3(0.28, 0.07, 0.06), CF(0, 0.00, 1.08), INK)
			blush(c, 0.42, 0.04, 1.02)
			for _, s in ipairs(SIDES) do
				-- Antennae.
				c:rod(V3(0.18 * s, 0.46, 1.02), V3(0.52 * s, 1.14, 1.20), 0.04, p.deep, nil, false)
				c:ball(V3(0.16, 0.16, 0.16), CF(0.52 * s, 1.16, 1.21), EMBER, NEON)
				-- Front and middle legs.
				c:rod(V3(0.42 * s, -0.22, 0.62), V3(0.76 * s, -0.72, 0.84), 0.05, p.deep, nil, false)
				c:rod(V3(0.48 * s, -0.24, 0.10), V3(0.84 * s, -0.74, 0.20), 0.05, p.deep, nil, false)
				-- The big jumping legs: thigh up, shin down.
				c:box(V3(0.24, 0.70, 0.46), CF(0.60 * s, 0.26, -0.44) * ANG(0, 0, -0.25 * s), p.base)
				c:rod(V3(0.66 * s, 0.56, -0.56), V3(0.92 * s, -0.70, -0.30), 0.06, p.deep, nil, false)
				c:box(V3(0.26, 0.10, 0.36), CF(0.92 * s, -0.76, -0.22), p.dark)
			end
			c:cone(V3(0.30, 0.40, 0.30), CF(0, 0.22, -1.22) * ANG(-PI / 2, 0, 0), p.base)
		end,
	}

	-- A smith's apron off its hook and walking: a scorched leather bib with a
	-- face, straps over the shoulders, a tool pocket and two heavy boots.
	S.ir_t_apron = {
		label = "Smith Apron",
		set = SET,
		tint = C3(126, 76, 48),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.10, 0.40),
		back = CF(0, 0.40, -0.40),
		build = function(c, p)
			c:box(V3(1.10, 1.00, 0.26), CF(0, 0.52, 0), p.base)
			c:box(V3(1.60, 1.20, 0.30), CF(0, -0.32, 0), p.base)
			c:box(V3(1.64, 0.10, 0.34), CF(0, -0.94, 0), p.dark)
			face(c, 0.58, 0.16, 0.26, 0.14)
			blush(c, 0.40, 0.26, 0.15)
			for _, s in ipairs(SIDES) do
				-- Shoulder straps, curling up like little ears.
				c:rod(V3(0.44 * s, 0.98, 0.04), V3(0.62 * s, 1.44, -0.14), 0.07, p.dark, nil, false)
				c:rod(V3(0.62 * s, 1.44, -0.14), V3(0.40 * s, 1.30, -0.34), 0.07, p.dark, nil, false)
				-- Waist ties, and the boots.
				c:box(V3(0.42, 0.18, 0.20), CF(0.92 * s, 0.06, -0.04) * ANG(0, 0, -0.3 * s), p.deep)
				c:box(V3(0.42, 0.22, 0.60), CF(0.40 * s, -1.14, 0.12), SOOT, METAL)
				c:box(V3(0.36, 0.14, 0.34), CF(0.40 * s, -1.26, 0.22), p.deep, METAL)
			end
			-- The tool pocket: a punch, a chisel and a stub of chalk.
			c:box(V3(0.90, 0.40, 0.10), CF(0, -0.30, 0.19), p.light)
			c:rod(V3(-0.26, -0.26, 0.24), V3(-0.26, 0.24, 0.24), 0.05, p.deep, METAL, false)
			c:rod(V3(0.02, -0.26, 0.24), V3(0.06, 0.18, 0.24), 0.05, BRASS, METAL, false)
			c:rod(V3(0.28, -0.26, 0.24), V3(0.32, 0.10, 0.24), 0.04, WHITE, nil, false)
			-- Burn speckles across the bib.
			for _, v in ipairs({ { -0.50, -0.62, 0.16 }, { 0.44, -0.70, 0.16 }, { 0.62, -0.40, 0.16 }, { -0.34, 0.86, 0.14 } }) do
				c:box(V3(0.16, 0.14, 0.05), CF(v[1], v[2], v[3]), SOOT)
			end
		end,
	}

	-- A leaning chimney stack off a forge roof: courses of brick, a soot-black
	-- iron cap, and the flue glowing right up the inside.
	S.ir_t_chimney = {
		label = "Soot Chimney",
		set = SET,
		tint = C3(82, 80, 90),
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.50, 0.60),
		back = CF(0, 0.20, -0.60),
		build = function(c, p)
			c:box(V3(1.50, 0.34, 1.40), CF(0, -1.00, 0), p.dark, SLATE)
			local lean = ANG(0, 0, 0.08)
			for i, y in ipairs({ -0.56, -0.08, 0.40, 0.88 }) do
				c:box(V3(1.02 - i * 0.04, 0.46, 0.96 - i * 0.04), CF(0, y, 0) * lean, i % 2 == 0 and p.light or p.base, SLATE)
				c:box(V3(1.10 - i * 0.04, 0.08, 1.02 - i * 0.04), CF(0, y + 0.24, 0) * lean, p.dark, SLATE)
			end
			-- The iron cap, and the heat coming up through it.
			c:box(V3(1.14, 0.14, 1.06), CF(0, 1.18, 0) * lean, SOOT, METAL)
			c:box(V3(0.70, 0.20, 0.64), CF(-0.10, 1.32, 0) * lean, LAVA, NEON)
			for _, s in ipairs(SIDES) do
				c:rod(V3(-0.52 + 0.44 * s, 1.24, 0.42 * s), V3(-0.60 + 0.48 * s, 1.60, 0.46 * s), 0.05, SOOT, METAL, false)
			end
			c:box(V3(0.80, 0.12, 0.72), CF(-0.14, 1.62, 0), SOOT, METAL)
			-- The face on the front, and an open soot door under it.
			c:eyes(0.18, 0.54, 0.26, 0.14)
			c:box(V3(0.26, 0.07, 0.06), CF(0, -0.10, 0.50), INK)
			blush(c, 0.38, -0.08, 0.48)
			c:box(V3(0.50, 0.40, 0.10), CF(0.04, -0.62, 0.50), p.deep, METAL)
			c:box(V3(0.36, 0.26, 0.08), CF(0.04, -0.62, 0.56), LAVA, NEON)
			-- Soot on the brickwork, and a brass sweep's ring on the side.
			c:box(V3(0.18, 0.44, 0.06), CF(-0.34, 0.84, 0.46), SOOT)
			c:box(V3(0.14, 0.30, 0.06), CF(0.28, 0.30, 0.44), SOOT)
			c:cyl(V3(0.08, 0.32, 0.32), CF(0.54, 0.00, 0.10), BRASS, METAL)
		end,
	}

	-- A coal brazier on three clawed legs: a shallow iron bowl of embers, ring
	-- handles either side, and flames standing up out of it.
	S.ir_t_brazier = {
		label = "Coal Brazier",
		set = SET,
		tint = C3(198, 162, 78),
		scale = 1.10,
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.40, 0.76),
		back = CF(0, 0.10, -0.76),
		build = function(c, p)
			c:cone(V3(1.60, 0.70, 1.56), CF(0, -0.10, 0) * ANG(PI, 0, 0), p.base, METAL)
			c:cyl(V3(0.18, 1.70, 1.70), CF(0, 0.28, 0) * UP, p.dark, METAL)
			c:cyl(V3(0.10, 1.46, 1.46), CF(0, 0.26, 0) * UP, COAL, SLATE)
			c:cyl(V3(0.06, 1.10, 1.10), CF(0, 0.32, 0) * UP, LAVA, NEON)
			flame(c, V3(0, 0.62, -0.10), 0.52, 0.66)
			flame(c, V3(-0.38, 0.50, 0.22), 0.30, 0.42, EMBER)
			flame(c, V3(0.40, 0.46, 0.18), 0.26, 0.34, EMBER)
			-- The face on the bowl's sloping front.
			face(c, -0.20, 0.64, 0.28, 0.14)
			blush(c, 0.46, -0.44, 0.52)
			-- Ring handles, legs and claw feet.
			for _, s in ipairs(SIDES) do
				c:cyl(V3(0.08, 0.44, 0.44), CF(0.86 * s, 0.22, 0), BRASS, METAL)
				c:box(V3(0.18, 0.16, 0.22), CF(0.78 * s, 0.26, 0), p.dark, METAL)
			end
			for k = 0, 2 do
				local a = k * 2 * PI / 3 + PI / 2
				local sx, sz = math.sin(a), math.cos(a)
				c:rod(V3(0.40 * sx, -0.40, 0.40 * sz), V3(0.70 * sx, -1.06, 0.70 * sz), 0.09, p.deep, METAL, false)
				c:box(V3(0.34, 0.16, 0.34), CF(0.74 * sx, -1.12, 0.74 * sz), p.dark, METAL)
				c:cone(V3(0.16, 0.22, 0.16), CF(0.86 * sx, -1.10, 0.86 * sz) * ANG(PI, 0, 0), p.light, METAL)
			end
			c:light(LAVA, 1.4, 8)
		end,
	}

	-- A quenching trough: a hollowed basalt tub of black water with a red-hot
	-- bar still hissing in it, steam rolling off the top.
	S.ir_t_trough = {
		label = "Quench Trough",
		set = SET,
		tint = C3(140, 164, 196),
		head = CF(0, 1.00, 0),
		neck = CF(0, -0.50, 0.70),
		back = CF(0, 0.10, -0.70),
		build = function(c, p)
			c:box(V3(2.10, 0.90, 1.20), CF(0, -0.30, 0), p.base, SLATE)
			c:box(V3(2.18, 0.16, 1.28), CF(0, 0.22, 0), p.dark, SLATE)
			c:box(V3(1.86, 0.10, 0.96), CF(0, 0.24, 0), SOOT)
			c:box(V3(1.40, 0.06, 0.30), CF(0.10, 0.28, 0.04), p.deep)
			-- The bar, hissing where it goes under.
			c:box(V3(0.80, 0.16, 0.20), CF(-0.40, 0.34, -0.22) * ANG(0, 0, 0.18), p.light, METAL)
			c:box(V3(0.44, 0.14, 0.18), CF(0.14, 0.44, -0.22) * ANG(0, 0, 0.18), LAVA, NEON)
			for _, v in ipairs({ { -0.30, 0.46, -0.18, 0.40 }, { 0.22, 0.56, -0.10, 0.32 }, { -0.70, 0.52, 0.10, 0.28 }, { 0.62, 0.48, 0.16, 0.24 } }) do
				c:ball(V3(v[4], v[4], v[4]), CF(v[1], v[2], v[3]), STEAM).Transparency = 0.35
			end
			face(c, -0.24, 0.62, 0.36, 0.16)
			blush(c, 0.66, -0.48, 0.58)
			-- Banding, a tap at one end and four stone feet.
			for _, s in ipairs(SIDES) do
				c:box(V3(0.08, 0.80, 1.24), CF(0.86 * s, -0.30, 0), p.deep, METAL)
				c:box(V3(0.24, 0.22, 0.26), CF(1.06 * s, -0.18, 0), BRASS, METAL)
			end
			c:rod(V3(0, -0.60, -0.62), V3(0, -0.60, -0.90), 0.06, BRASS, METAL, false)
			c:box(V3(0.22, 0.20, 0.10), CF(0, -0.42, -0.84), BRASS, METAL)
			feet(c, p.dark, SLATE, 0.76, -0.88, 0.40, V3(0.40, 0.26, 0.40))
		end,
	}

	-- A bench vise whose jaws are its grin: a swivel base, a long screw and a
	-- tommy bar through the handle.
	S.ir_t_vise = {
		label = "Bench Vise",
		set = SET,
		tint = C3(40, 70, 200),
		scale = 1.10,
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.50, 0.80),
		back = CF(0, 0.10, -0.90),
		build = function(c, p)
			-- Fixed jaw at the back, sliding jaw at the front, mouth between.
			c:box(V3(1.50, 0.80, 0.52), CF(0, 0.30, -0.42), p.base, METAL)
			c:box(V3(1.50, 0.80, 0.46), CF(0, 0.30, 0.34), p.light, METAL)
			c:box(V3(1.20, 0.18, 0.14), CF(0, 0.30, 0.08), INK)
			c:box(V3(1.24, 0.10, 0.16), CF(0, 0.60, 0.08), p.pale, METAL)
			c:box(V3(1.24, 0.10, 0.16), CF(0, 0.00, 0.08), p.pale, METAL)
			c:eyes(0.78, 0.60, 0.36, 0.17)
			blush(c, 0.58, 0.44, 0.58)
			-- Body, slide bar and the screw with its tommy bar.
			c:box(V3(1.00, 0.50, 1.30), CF(0, -0.22, -0.10), p.dark, METAL)
			c:box(V3(0.30, 0.22, 1.60), CF(0, -0.18, 0.32), p.deep, METAL)
			c:rod(V3(0, 0.08, 0.56), V3(0, 0.08, 1.20), 0.09, BRASS, METAL, false)
			c:cyl(V3(0.14, 0.52, 0.52), CF(0, 0.08, 1.24) * FRONT, BRASS, METAL)
			c:rod(V3(-0.56, 0.08, 1.30), V3(0.56, 0.08, 1.30), 0.06, p.deep, METAL, false)
			for _, s in ipairs(SIDES) do
				c:ball(V3(0.22, 0.22, 0.22), CF(0.58 * s, 0.08, 1.30), p.deep, METAL)
				c:box(V3(0.14, 0.34, 0.30), CF(0.70 * s, 0.30, -0.42), p.dark, METAL)
			end
			-- Swivel base, bolted to its own scrap of bench.
			c:cyl(V3(0.26, 1.20, 1.20), CF(0, -0.60, -0.10) * UP, p.deep, METAL)
			c:box(V3(1.70, 0.22, 1.50), CF(0, -0.84, -0.10), TIMBER, WOOD)
			rivets(c, { { -0.66, -0.72, 0.44 }, { 0.66, -0.72, 0.44 }, { -0.66, -0.72, -0.62 }, { 0.66, -0.72, -0.62 } }, 0.16)
			c:box(V3(0.26, 0.24, 0.26), CF(0.46, 0.66, 0.08), LAVA, NEON)
		end,
	}

	--------------------------------------------------------------------------
	-- LEGENDARY: wrought iron and brass, ornament on everything.
	--------------------------------------------------------------------------

	-- The citadel's portcullis, down and awake: a spiked iron grid in a
	-- basalt arch, with winch chains still hanging from the top corners.
	S.ir_t_portcullis = {
		label = "Iron Portcullis",
		set = SET,
		tint = C3(96, 110, 136),
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.80, 0.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			-- The arch it hangs in.
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 2.20, 0.60), CF(1.08 * s, 0.00, 0), p.deep, SLATE)
				c:box(V3(0.46, 0.22, 0.70), CF(1.08 * s, -1.16, 0), p.dark, SLATE)
				c:box(V3(0.46, 0.20, 0.70), CF(1.08 * s, 0.92, 0), p.dark, SLATE)
			end
			c:box(V3(2.50, 0.40, 0.66), CF(0, 1.22, 0), p.deep, SLATE)
			c:box(V3(2.10, 0.20, 0.72), CF(0, 0.96, 0), p.dark, SLATE)
			-- The grid: three uprights, three bars, spikes along the bottom.
			for _, x in ipairs({ -0.62, 0, 0.62 }) do
				c:box(V3(0.18, 2.00, 0.22), CF(x, 0.00, 0.10), p.base, METAL)
			end
			for _, y in ipairs({ 0.72, 0.00, -0.72 }) do
				c:box(V3(1.70, 0.16, 0.18), CF(0, y, 0.10), p.light, METAL)
			end
			for _, x in ipairs({ -0.62, 0, 0.62 }) do
				c:cone(V3(0.22, 0.34, 0.22), CF(x, -1.16, 0.10) * ANG(PI, 0, 0), p.pale, METAL)
			end
			face(c, 0.34, 0.24, 0.32, 0.15)
			blush(c, 0.50, 0.08, 0.22)
			-- Chains to the winch, and lava light leaking through the gateway.
			for _, s in ipairs(SIDES) do
				for _, y in ipairs({ 1.00, 0.76 }) do
					c:cyl(V3(0.10, 0.26, 0.26), CF(0.62 * s, y, 0.10), p.deep, METAL)
				end
				c:box(V3(0.24, 0.20, 0.08), CF(0.90 * s, 0.70, -0.24), BRASS, METAL)
			end
			c:box(V3(1.60, 1.90, 0.08), CF(0, -0.10, -0.26), LAVA, NEON).Transparency = 0.45
			rivets(c, { { -0.62, 0.72, 0.21 }, { 0.62, 0.72, 0.21 }, { -0.62, -0.72, 0.21 }, { 0.62, -0.72, 0.21 } }, 0.16)
		end,
	}

	-- An obsidian ibex: ridged horns sweeping back over its shoulders, a
	-- beard, cloven hooves and lava cracks across its flanks.
	S.ir_t_ibex = {
		label = "Obsidian Ibex",
		set = SET,
		tint = C3(46, 42, 58),
		scale = 1.15,
		head = CF(0, 1.30, 0.30),
		neck = CF(0, -0.40, 0.74),
		back = CF(0, 0.40, -0.74),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.80, 1.70, 1.80),
				eyeY = 0.20, eyeSpread = 0.34, eyeSize = V3(0.40, 0.46, 0.20), eyeColor = EMBER,
				snout = { w = 0.66, h = 0.44, d = 0.44, y = -0.26, color = p.light, nose = SOOT },
				legSize = V3(0.40, 0.42, 0.44), legColor = p.deep,
				tail = false,
			})
			-- The horns: up off the brow, then a long ridged sweep backwards.
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.28 * s, 0.94, 0.42), V3(0.42 * s, 1.44, 0.10), 0.12, HORN, nil, false)
				c:rod(V3(0.42 * s, 1.44, 0.10), V3(0.46 * s, 1.40, -0.76), 0.11, HORN, nil, false)
				c:cone(V3(0.20, 0.30, 0.20), CF(0.46 * s, 1.26, -0.96) * ANG(1.2, 0, 0), HORN)
				for i = 0, 3 do
					c:box(V3(0.28, 0.10, 0.12), CF(0.44 * s, 1.44 - i * 0.02, -0.06 - i * 0.22), p.pale)
				end
				-- Lava cracks down the flank, and cloven hooves.
				c:box(V3(0.06, 0.52, 0.10), CF(0.94 * s, 0.26, -0.22) * ANG(0.5, 0, 0), LAVA, NEON)
				c:box(V3(0.06, 0.40, 0.10), CF(0.94 * s, -0.16, -0.46) * ANG(-0.5, 0, 0), LAVA, NEON)
				for _, z in ipairs({ 0.42, -0.42 }) do
					c:box(V3(0.18, 0.14, 0.44), CF(0.50 * s, -1.08, z), HORN)
					c:box(V3(0.08, 0.16, 0.10), CF(0.50 * s, -1.08, z + 0.22), SOOT)
				end
			end
			c:box(V3(0.34, 0.46, 0.26), CF(0, -0.62, 0.84), p.dark)
			c:box(V3(0.24, 0.26, 0.20), CF(0, -0.88, 0.76), p.deep)
			c:box(V3(0.30, 0.34, 0.50), CF(0, 0.22, -0.98), p.dark)
		end,
	}

	-- A cinder echidna: its spines are forge nails driven into its back, tips
	-- still glowing, with a long tube snout and big digging claws.
	S.ir_t_echidna = {
		label = "Cinder Echidna",
		set = SET,
		tint = C3(152, 22, 54),
		scale = 1.10,
		head = CF(0, 0.90, 0.40),
		neck = CF(0, -0.30, 1.00),
		back = CF(0, 0.84, -0.40),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.80, 1.30, 1.70),
				eyeY = 0.12, eyeSpread = 0.30, eyeSize = V3(0.34, 0.40, 0.18),
				mouth = false,
				legSize = V3(0.40, 0.26, 0.42), legX = 0.60, legY = -0.70, legColor = p.deep,
				tail = false,
			})
			c:box(V3(0.34, 0.30, 0.74), CF(0, -0.22, 1.02), p.dark)
			c:box(V3(0.26, 0.22, 0.20), CF(0, -0.22, 1.42), SOOT)
			-- The nails: brass heads, glowing points, in staggered rows.
			for _, row in ipairs({ { 0.62, 0.70 }, { 0.20, 0.82 }, { -0.24, 0.76 }, { -0.66, 0.60 } }) do
				for _, x in ipairs({ -0.56, -0.18, 0.18, 0.56 }) do
					local tilt = ANG(-row[1] * 0.4, 0, x * 0.5)
					c:rod(V3(x, row[2] - 0.10, row[1]), V3(x * 1.2, row[2] + 0.42, row[1] * 1.3), 0.055, p.light, METAL, false)
					c:ball(V3(0.16, 0.16, 0.16), CF(x * 1.2, row[2] + 0.44, row[1] * 1.3) * tilt, EMBER, NEON)
				end
			end
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 0.14, 0.30), CF(0.62 * s, -0.86, 0.46), p.dark)
				for _, dx in ipairs({ -0.10, 0.10 }) do
					c:cone(V3(0.10, 0.26, 0.10), CF(0.62 * s + dx, -0.88, 0.66) * ANG(PI / 2, 0, 0), HORN)
				end
				c:box(V3(0.06, 0.12, 0.70), CF(0.91 * s, -0.24, -0.10), LAVA, NEON)
			end
		end,
	}

	-- A water-driven triphammer: a timber frame, the cam shaft that lifts it,
	-- and the head held up over a glowing billet on its stock block.
	S.ir_t_triphammer = {
		label = "Forge Triphammer",
		set = SET,
		tint = C3(90, 100, 30),
		head = CF(0, 1.60, -0.30),
		neck = CF(0, -0.50, 0.80),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			-- Frame.
			for _, s in ipairs(SIDES) do
				c:box(V3(0.22, 1.90, 0.24), CF(0.84 * s, 0.10, -0.40), TIMBER, WOOD)
				c:box(V3(0.40, 0.20, 0.60), CF(0.84 * s, -0.94, -0.40), p.deep, WOOD)
				c:cyl(V3(0.24, 0.40, 0.40), CF(0.76 * s, 0.56, -0.40), BRASS, METAL)
			end
			c:box(V3(1.90, 0.24, 0.30), CF(0, 1.02, -0.40), TIMBER, WOOD)
			c:box(V3(1.90, 0.20, 0.30), CF(0, -0.78, -0.40), p.deep, WOOD)
			-- The cam shaft, with three lifting cams on it.
			c:cyl(V3(1.60, 0.34, 0.34), CF(0, 0.56, -0.40), p.dark, METAL)
			for _, x in ipairs({ -0.42, 0, 0.42 }) do
				c:box(V3(0.14, 0.56, 0.24), CF(x, 0.68, -0.40) * ANG(0.5, 0, 0), p.light, METAL)
			end
			-- The helve and the hammer head, raised, with a face on its cheek.
			c:box(V3(0.40, 0.28, 1.80), CF(0, 0.44, 0.34) * ANG(-0.18, 0, 0), TIMBER, WOOD)
			c:box(V3(0.80, 0.76, 0.72), CF(0, 0.20, 1.12), p.base, METAL)
			c:box(V3(0.86, 0.14, 0.78), CF(0, 0.60, 1.12), p.light, METAL)
			face(c, 0.24, 0.48, 0.24, 0.14)
			blush(c, 0.40, 0.00, 0.44)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.08, 0.60, 0.60), CF(0.42 * s, 0.20, 1.12), p.deep, METAL)
			end
			-- The stock block below, and the billet taking the blow.
			c:box(V3(1.10, 0.46, 1.00), CF(0, -0.60, 1.10), p.deep, SLATE)
			c:box(V3(1.20, 0.14, 1.08), CF(0, -0.32, 1.10), p.dark, METAL)
			c:box(V3(0.62, 0.22, 0.46), CF(0, -0.16, 1.10), LAVA, NEON)
			c:box(V3(0.34, 0.10, 0.26), CF(0, -0.10, 1.10), WHITEHOT, NEON)
			for _, v in ipairs({ { -0.46, 0.00, 1.30 }, { 0.44, -0.06, 1.36 }, { 0.10, 0.08, 1.48 } }) do
				c:ball(V3(0.14, 0.14, 0.14), CF(v[1], v[2], v[3]), EMBER, NEON)
			end
		end,
	}

	-- A slag pot on its trunnion carriage: a riveted iron bucket brimming with
	-- crust and glow, brass tipping gears, and four little wheels.
	S.ir_t_slagpot = {
		label = "Slag Pot",
		set = SET,
		tint = C3(110, 10, 10),
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.50, 0.84),
		back = CF(0, 0.10, -0.84),
		build = function(c, p)
			c:cone(V3(1.70, 1.30, 1.60), CF(0, 0.12, 0) * ANG(PI, 0, 0), p.base, METAL)
			c:cyl(V3(0.20, 1.76, 1.76), CF(0, 0.66, 0) * UP, p.dark, METAL)
			c:cyl(V3(0.10, 1.52, 1.52), CF(0, 0.66, 0) * UP, COAL, SLATE)
			for _, v in ipairs({ { -0.34, 0.74, 0.18, 0.46 }, { 0.30, 0.76, -0.22, 0.40 }, { 0.14, 0.72, 0.42, 0.30 } }) do
				c:box(V3(v[4], 0.14, v[4]), CF(v[1], v[2], v[3]) * ANG(0, 0.4, 0), LAVA, NEON)
			end
			c:ball(V3(0.30, 0.30, 0.30), CF(-0.14, 0.82, -0.04), LAVA, NEON)
			-- The face on the pot's belly.
			face(c, 0.02, 0.74, 0.32, 0.16)
			blush(c, 0.52, -0.28, 0.64)
			-- Riveted bands, trunnions and the brass tipping gear.
			for _, s in ipairs(SIDES) do
				c:cyl(V3(0.34, 0.40, 0.40), CF(0.84 * s, 0.34, 0), p.deep, METAL)
				c:box(V3(0.20, 1.50, 0.40), CF(1.04 * s, -0.34, 0), p.dark, METAL)
				c:box(V3(0.44, 0.22, 0.52), CF(1.04 * s, -1.02, 0), p.deep, METAL)
				for _, z in ipairs({ 0.34, -0.34 }) do
					c:cyl(V3(0.14, 0.38, 0.38), CF(1.08 * s, -1.10, z), SOOT, METAL)
				end
			end
			c:cyl(V3(0.12, 0.76, 0.76), CF(1.08, 0.34, 0), BRASS, METAL)
			for k = 0, 3 do
				c:box(V3(0.10, 0.80, 0.10), CF(1.14, 0.34, 0) * ANG(k * PI / 4, 0, 0), BRASS, METAL)
			end
			c:box(V3(2.00, 0.18, 0.40), CF(0, -1.14, 0), p.deep, METAL)
			rivets(c, { { -0.54, 0.56, 0.62 }, { 0.54, 0.56, 0.62 }, { 0, 0.58, 0.80 } }, 0.16)
		end,
	}

	-- An iron wall sconce off its bracket: a scrolled backplate with a face, a
	-- fire bowl held out front, a drip pan and two hanging chain links.
	S.ir_t_sconce = {
		label = "Iron Sconce",
		set = SET,
		tint = C3(60, 30, 120),
		head = CF(0, 1.60, -0.20),
		neck = CF(0, -0.60, 0.30),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			-- Backplate, scrolled at the corners.
			c:box(V3(1.20, 1.60, 0.24), CF(0, 0.34, -0.40), p.base, METAL)
			c:box(V3(1.36, 0.20, 0.30), CF(0, 1.08, -0.40), p.dark, METAL)
			c:box(V3(1.36, 0.20, 0.30), CF(0, -0.40, -0.40), p.dark, METAL)
			for _, s in ipairs(SIDES) do
				c:cyl(V3(0.14, 0.44, 0.44), CF(0.70 * s, 1.08, -0.40) * FRONT, p.light, METAL)
				c:cyl(V3(0.14, 0.44, 0.44), CF(0.70 * s, -0.40, -0.40) * FRONT, p.light, METAL)
				c:box(V3(0.14, 0.90, 0.20), CF(0.60 * s, 0.34, -0.40), p.light, METAL)
			end
			face(c, 0.52, -0.26, 0.26, 0.14)
			blush(c, 0.42, 0.24, -0.28)
			-- The arm out front, the bowl and its flame.
			c:rod(V3(0, 0.00, -0.28), V3(0, -0.04, 0.42), 0.09, p.dark, METAL, false)
			c:cone(V3(0.90, 0.42, 0.86), CF(0, 0.12, 0.56) * ANG(PI, 0, 0), p.base, METAL)
			c:cyl(V3(0.12, 0.96, 0.96), CF(0, 0.34, 0.56) * UP, p.dark, METAL)
			c:cyl(V3(0.07, 0.76, 0.76), CF(0, 0.38, 0.56) * UP, COAL, SLATE)
			flame(c, V3(0, 0.56, 0.56), 0.54, 0.74)
			flame(c, V3(-0.26, 0.48, 0.70), 0.22, 0.30, EMBER)
			-- Drip pan under the bowl, and the chain it hung from.
			c:cyl(V3(0.10, 0.70, 0.70), CF(0, -0.30, 0.56) * UP, p.deep, METAL)
			c:box(V3(0.12, 0.28, 0.12), CF(0, -0.48, 0.56), LAVA, NEON)
			for _, y in ipairs({ 1.32, 1.58 }) do
				c:cyl(V3(0.10, 0.30, 0.30), CF(0, y, -0.40), p.deep, METAL)
			end
			rivets(c, { { 0, 0.98, -0.27 }, { 0, -0.30, -0.27 } }, 0.16)
			c:light(LAVA, 1.2, 7)
		end,
	}

	-- An ember caracal: long legs, a lean back, and tall black ear tufts that
	-- trail sparks, with glowing pads under its paws.
	S.ir_t_caracal = {
		label = "Ember Caracal",
		set = SET,
		tint = C3(255, 170, 120),
		scale = 1.10,
		head = CF(0, 1.30, 0.20),
		neck = CF(0, -0.30, 0.86),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.60, 1.60, 1.80),
				eyeY = 0.26, eyeSpread = 0.32, eyeSize = V3(0.42, 0.48, 0.20),
				snout = { w = 0.56, h = 0.34, d = 0.30, y = -0.22, color = p.pale, nose = SOOT },
				legSize = V3(0.34, 0.60, 0.38), legX = 0.54, legY = -0.70, legColor = p.dark,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				-- Ears: a dark cone with a tuft of sparks off the tip.
				c:cone(V3(0.38, 0.52, 0.26), CF(0.40 * s, 1.14, 0.12), p.dark)
				c:cone(V3(0.20, 0.26, 0.16), CF(0.40 * s, 1.08, 0.18), p.pale)
				c:rod(V3(0.40 * s, 1.34, 0.10), V3(0.52 * s, 1.72, 0.02), 0.05, SOOT, nil, false)
				c:ball(V3(0.16, 0.16, 0.16), CF(0.52 * s, 1.74, 0.02), EMBER, NEON)
				-- Cheek whiskers, and glowing pads.
				c:rod(V3(0.18 * s, -0.24, 0.88), V3(0.62 * s, -0.16, 1.02), 0.025, WHITE, nil, false)
				for _, z in ipairs({ 0.42, -0.42 }) do
					c:box(V3(0.30, 0.14, 0.38), CF(0.54 * s, -1.04, z + 0.06), p.deep)
					c:box(V3(0.18, 0.06, 0.22), CF(0.54 * s, -1.10, z + 0.14), LAVA, NEON)
				end
			end
			c:box(V3(0.56, 0.18, 0.26), CF(0, 0.96, 0.46), p.dark)
			-- Short black-tipped tail, held up.
			c:rod(V3(0, 0.10, -0.90), V3(0, 0.56, -1.22), 0.11, p.base, nil, false)
			c:box(V3(0.24, 0.30, 0.24), CF(0, 0.70, -1.28), SOOT)
		end,
	}

	-- A basalt obelisk on its stepped plinth: channels cut down all four faces
	-- and filled with lava, a brass band, and a capstone like a little pyramid.
	S.ir_t_obelisk = {
		label = "Basalt Obelisk",
		set = SET,
		tint = C3(20, 24, 60),
		head = CF(0, 1.80, 0),
		neck = CF(0, -0.70, 0.46),
		back = CF(0, 0.00, -0.46),
		build = function(c, p)
			c:box(V3(1.70, 0.26, 1.70), CF(0, -1.14, 0), p.deep, SLATE)
			c:box(V3(1.36, 0.26, 1.36), CF(0, -0.88, 0), p.dark, SLATE)
			c:box(V3(1.04, 0.26, 1.04), CF(0, -0.62, 0), p.deep, SLATE)
			c:box(V3(0.86, 1.90, 0.86), CF(0, 0.44, 0), p.base, SLATE)
			c:box(V3(0.72, 0.30, 0.72), CF(0, 1.52, 0), p.dark, SLATE)
			c:cone(V3(0.74, 0.46, 0.74), CF(0, 1.88, 0), p.light, SLATE)
			c:box(V3(0.20, 0.20, 0.20), CF(0, 2.14, 0) * ANG(0, PI / 4, 0), LAVA, NEON)
			-- Lava channels down each face, and a brass band round the shaft.
			for k = 0, 3 do
				local a = k * PI / 2
				c:box(V3(0.14, 1.20, 0.06), CF(0, 0.60, 0) * ANG(0, a, 0) * CF(0, 0, 0.44), LAVA, NEON)
				c:box(V3(0.34, 0.08, 0.06), CF(0, 1.26, 0) * ANG(0, a, 0) * CF(0, 0, 0.44), EMBER, NEON)
			end
			c:box(V3(0.96, 0.18, 0.96), CF(0, -0.12, 0), BRASS, METAL)
			-- The face is carved into the shaft above the band.
			face(c, 0.36, 0.44, 0.22, 0.12)
			blush(c, 0.32, 0.14, 0.42)
			-- Carved glyph notches, and rubble round the plinth.
			for _, y in ipairs({ 0.82, 1.06 }) do
				c:box(V3(0.30, 0.07, 0.06), CF(0, y, 0.44), p.deep)
			end
			c:box(V3(0.44, 0.34, 0.40), CF(0.88, -1.14, 0.56) * ANG(0.2, 0.5, 0.1), p.dark, SLATE)
			c:box(V3(0.36, 0.28, 0.34), CF(-0.84, -1.12, -0.50) * ANG(0.1, 0.3, 0.2), p.base, SLATE)
			c:light(LAVA, 1.0, 7)
		end,
	}

	-- An ember firecrest: the smallest bird in the crags, with a blazing
	-- crown stripe, bold eye bars and wings held half out.
	S.ir_t_firecrest = {
		label = "Ember Firecrest",
		set = SET,
		tint = C3(255, 112, 170),
		scale = 1.05,
		head = CF(0, 1.14, 0.10),
		neck = CF(0, -0.10, 0.80),
		back = CF(0, 0.30, -0.74),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V3(1.46, 1.64, 1.46),
				eyeY = 0.36, eyeSpread = 0.30, eyeSize = V3(0.38, 0.46, 0.20),
				mouth = false,
				bib = { w = 0.84, h = 0.72, y = -0.34, color = p.pale },
				legSize = V3(0.14, 0.38, 0.22), legX = 0.26, legZ = { 0.08 }, legY = -0.92, legColor = BRASS,
				tail = false,
			})
			c:cone(V3(0.20, 0.30, 0.18), CF(0, 0.10, 0.84) * ANG(PI / 2, 0, 0), SOOT)
			-- The crown: a bright stripe between two dark borders.
			c:box(V3(0.22, 0.14, 0.84), CF(0, 0.96, -0.02), LAVA, NEON)
			c:box(V3(0.12, 0.10, 0.80), CF(0, 0.99, -0.02), WHITEHOT, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.14, 0.12, 0.80), CF(0.20 * s, 0.94, -0.02), SOOT)
				c:box(V3(0.34, 0.10, 0.08), CF(0.30 * s, 0.52, 0.56) * ANG(0, 0, -0.15 * s), SOOT)
				-- Wings, half out, with a pale bar across each.
				c:box(V3(0.14, 0.80, 0.94), CF(0.80 * s, 0.06, -0.14) * ANG(0.18, 0, 0.3 * s), p.dark)
				c:box(V3(0.16, 0.14, 0.60), CF(0.86 * s, -0.10, -0.08) * ANG(0.18, 0, 0.3 * s), p.pale)
				c:box(V3(0.12, 0.22, 0.26), CF(0.92 * s, 0.38, -0.44) * ANG(0.18, 0, 0.3 * s), EMBER, NEON)
			end
			c:box(V3(0.38, 0.14, 0.70), CF(0, -0.10, -0.98) * ANG(0.35, 0, 0), p.dark)
			c:box(V3(0.30, 0.12, 0.24), CF(0, 0.08, -1.38) * ANG(0.35, 0, 0), p.base)
		end,
	}

	-- A cinder antlion sat in its ash funnel: broad flat head, two great
	-- curved pincers held open, and grains of ash sliding down the slope.
	S.ir_t_antlion = {
		label = "Cinder Antlion",
		set = SET,
		tint = C3(208, 126, 76),
		scale = 1.15,
		head = CF(0, 0.74, 0.40),
		neck = CF(0, -0.10, 1.00),
		back = CF(0, 0.50, -0.70),
		build = function(c, p)
			-- The funnel it waits in.
			c:cone(V3(2.40, 0.90, 2.30), CF(0, -0.58, -0.10) * ANG(PI, 0, 0), p.dark, SLATE)
			c:cone(V3(1.60, 0.56, 1.52), CF(0, -0.46, -0.10) * ANG(PI, 0, 0), p.deep, SLATE)
			for _, v in ipairs({ { -0.84, -0.26, 0.42 }, { 0.78, -0.20, -0.46 }, { 0.46, -0.34, 0.76 } }) do
				c:box(V3(0.22, 0.14, 0.22), CF(v[1], v[2], v[3]), p.pale, SLATE)
			end
			-- The grub itself, half buried.
			c:ovoid(V3(1.20, 0.80, 1.30), CF(0, 0.06, -0.34), p.base)
			c:box(V3(1.04, 0.14, 1.10), CF(0, 0.42, -0.34), p.dark)
			c:ovoid(V3(1.00, 0.54, 0.70), CF(0, 0.06, 0.52), p.light)
			c:box(V3(1.06, 0.12, 0.60), CF(0, 0.30, 0.52), p.dark)
			c:eyes(0.14, 0.86, 0.34, 0.15, EMBER)
			c:box(V3(0.28, 0.07, 0.06), CF(0, -0.10, 0.84), INK)
			for _, s in ipairs(SIDES) do
				-- Pincers: out, forward, then hooked inward.
				c:rod(V3(0.34 * s, -0.06, 0.78), V3(0.78 * s, 0.02, 1.08), 0.09, p.deep, nil, false)
				c:rod(V3(0.78 * s, 0.02, 1.08), V3(0.72 * s, 0.10, 1.58), 0.08, p.deep, nil, false)
				c:cone(V3(0.18, 0.34, 0.18), CF(0.56 * s, 0.14, 1.76) * ANG(PI / 2, 0, -0.6 * s), p.pale)
				for _, t in ipairs({ 0.22, 0.44 }) do
					c:cone(V3(0.12, 0.18, 0.12), CF(0.76 * s, 0.10, 1.00 + t) * ANG(0, 0, -PI / 2 * s), p.pale)
				end
				-- Little legs, and heat glowing out of the sand.
				c:rod(V3(0.52 * s, -0.22, 0.26), V3(0.84 * s, -0.52, 0.34), 0.05, p.deep, nil, false)
				c:box(V3(0.06, 0.08, 0.50), CF(0.56 * s, 0.44, -0.40), LAVA, NEON)
			end
			c:light(LAVA, 0.8, 6)
		end,
	}

	-- An ore barrow: an iron-tyred wheel, a riveted pan heaped with glowing
	-- ore, and two long handles with worn grips.
	S.ir_t_barrow = {
		label = "Ore Barrow",
		set = SET,
		tint = C3(72, 140, 255),
		head = CF(0, 1.10, -0.20),
		neck = CF(0, -0.40, 0.90),
		back = CF(0, 0.40, -1.10),
		build = function(c, p)
			-- The pan, flared out at the back.
			c:box(V3(1.50, 0.70, 1.20), CF(0, 0.08, -0.10), p.base, METAL)
			c:box(V3(1.70, 0.60, 0.16), CF(0, 0.28, -0.72), p.light, METAL)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.16, 0.60, 1.20), CF(0.80 * s, 0.28, -0.14) * ANG(0, 0, -0.18 * s), p.light, METAL)
				c:box(V3(0.06, 0.16, 1.24), CF(0.86 * s, 0.00, -0.10), p.deep, METAL)
				-- Handles and legs.
				c:rod(V3(0.58 * s, -0.20, -0.30), V3(0.66 * s, 0.10, -1.42), 0.07, TIMBER, WOOD, false)
				c:box(V3(0.22, 0.22, 0.34), CF(0.68 * s, 0.12, -1.56), LEATHER)
				c:box(V3(0.18, 0.46, 0.20), CF(0.58 * s, -0.50, -0.86), TIMBER, WOOD)
				c:box(V3(0.30, 0.14, 0.34), CF(0.58 * s, -0.78, -0.88), p.deep, METAL)
			end
			-- The heap of ore, two pieces of it still hot.
			for _, v in ipairs({ { -0.42, 0.52, 0.10, 0.44 }, { 0.14, 0.58, -0.18, 0.48 }, { 0.46, 0.50, 0.14, 0.38 }, { -0.10, 0.52, 0.36, 0.34 } }) do
				c:box(V3(v[4], v[4] * 0.8, v[4]), CF(v[1], v[2], v[3]) * ANG(0.3, 0.5, 0.2), p.dark, SLATE)
			end
			c:box(V3(0.28, 0.26, 0.28), CF(-0.24, 0.76, 0.06) * ANG(0.4, 0.3, 0.2), LAVA, NEON)
			c:box(V3(0.22, 0.20, 0.22), CF(0.30, 0.74, -0.06) * ANG(0.2, 0.6, 0.1), EMBER, NEON)
			-- The wheel out front, and the face on the pan above it.
			c:cyl(V3(0.26, 1.10, 1.10), CF(0, -0.34, 0.62), p.deep, METAL)
			c:cyl(V3(0.30, 0.76, 0.76), CF(0, -0.34, 0.62), p.dark, METAL)
			c:cyl(V3(0.34, 0.26, 0.26), CF(0, -0.34, 0.62), BRASS, METAL)
			c:box(V3(0.30, 0.90, 0.22), CF(0, -0.34, 0.74), p.base, METAL)
			c:eyes(0.12, 0.58, 0.30, 0.15)
			c:box(V3(0.28, 0.07, 0.06), CF(0, -0.12, 0.54), INK)
			blush(c, 0.46, -0.10, 0.52)
		end,
	}

	-- A slagclaw wolverine: low, heavy and shaggy, with a pale stripe over its
	-- back and long claws that glow where they have dragged through slag.
	S.ir_t_wolverine = {
		label = "Slagclaw Wolverine",
		set = SET,
		tint = C3(88, 60, 96),
		scale = 1.10,
		head = CF(0, 1.06, 0.26),
		neck = CF(0, -0.30, 0.94),
		back = CF(0, 0.60, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V3(1.90, 1.46, 1.90),
				eyeY = 0.14, eyeSpread = 0.32, eyeSize = V3(0.38, 0.44, 0.20),
				snout = { w = 0.74, h = 0.44, d = 0.46, y = -0.26, color = p.dark, nose = SOOT },
				brow = p.dark,
				legSize = V3(0.48, 0.36, 0.50), legX = 0.62, legY = -0.74, legColor = p.deep,
				tail = false,
			})
			-- The pale stripe, shoulder to rump, both sides.
			for _, s in ipairs(SIDES) do
				c:box(V3(0.22, 0.44, 1.70), CF(0.86 * s, 0.34, -0.10) * ANG(0, 0, 0.2 * s), p.pale)
				c:cone(V3(0.30, 0.34, 0.22), CF(0.44 * s, 0.86, 0.24), p.dark)
				c:box(V3(0.34, 0.12, 0.10), CF(0.26 * s, -0.42, 0.98), p.light)
				for _, z in ipairs({ 0.46, -0.44 }) do
					c:box(V3(0.42, 0.16, 0.42), CF(0.62 * s, -0.96, z + 0.08), p.dark)
					for _, dx in ipairs({ -0.12, 0.12 }) do
						c:cone(V3(0.10, 0.26, 0.10), CF(0.62 * s + dx, -0.98, z + 0.30) * ANG(PI / 2, 0, 0), EMBER, NEON)
					end
				end
			end
			-- Shaggy shoulders and a thick brush of a tail.
			c:box(V3(1.40, 0.34, 0.90), CF(0, 0.84, 0.10), p.base)
			c:box(V3(0.60, 0.56, 0.70), CF(0, 0.10, -1.04), p.base)
			c:box(V3(0.48, 0.44, 0.56), CF(0, 0.34, -1.40) * ANG(0.5, 0, 0), p.light)
			c:box(V3(0.26, 0.30, 0.26), CF(0, 0.58, -1.62), p.pale)
		end,
	}

	--------------------------------------------------------------------------
	-- MYTHIC: the volcano itself, with the glow turned all the way up.
	--------------------------------------------------------------------------

	-- A brimstone geyser: a crusted vent on mineral terraces, throwing a
	-- column of bright water and steam straight up.
	S.ir_t_geyser = {
		label = "Brimstone Geyser",
		set = SET,
		tint = C3(232, 214, 82),
		scale = 1.10,
		head = CF(0, 1.00, 0.20),
		neck = CF(0, -0.60, 0.90),
		back = CF(0, 0.00, -0.90),
		build = function(c, p)
			-- Terraces, each one a little smaller.
			c:cyl(V3(0.26, 2.40, 2.40), CF(0, -1.00, 0) * UP, p.dark, SLATE)
			c:cyl(V3(0.26, 1.90, 1.90), CF(0, -0.76, 0) * UP, p.base, SLATE)
			c:cyl(V3(0.26, 1.46, 1.46), CF(0, -0.52, 0) * UP, p.light, SLATE)
			c:cyl(V3(0.10, 1.30, 1.30), CF(0, -0.38, 0) * UP, p.glow, NEON)
			-- The vent cone, crusted with brimstone.
			c:cone(V3(1.20, 0.90, 1.16), CF(0, 0.04, 0), p.base, SLATE)
			c:cyl(V3(0.14, 0.52, 0.52), CF(0, 0.52, 0) * UP, p.deep, SLATE)
			for k = 0, 5 do
				local a = k * PI / 3
				c:box(V3(0.24, 0.20, 0.18), CF(0, 0.14, 0) * ANG(0, a, 0) * CF(0, 0, 0.46), p.pale, SLATE)
			end
			-- The column: wide at the bottom, breaking up at the top.
			c:cyl(V3(0.60, 0.70, 0.70), CF(0, 0.78, 0) * UP, p.glow, NEON)
			c:cyl(V3(0.50, 0.50, 0.50), CF(0, 1.30, 0) * UP, WHITEHOT, NEON)
			c:ball(V3(0.62, 0.62, 0.62), CF(0, 1.72, 0), STEAM).Transparency = 0.3
			c:ball(V3(0.46, 0.46, 0.46), CF(-0.32, 1.52, 0.18), STEAM).Transparency = 0.4
			c:ball(V3(0.40, 0.40, 0.40), CF(0.34, 1.60, -0.14), STEAM).Transparency = 0.4
			-- The face on the cone's front, under the spray.
			face(c, 0.02, 0.50, 0.26, 0.14, EMBER)
			blush(c, 0.40, -0.26, 0.42)
			-- Runnels of hot water down the terraces.
			for _, s in ipairs(SIDES) do
				c:box(V3(0.14, 0.08, 0.50), CF(0.50 * s, -0.40, 0.44), p.glow, NEON)
				c:box(V3(0.14, 0.08, 0.44), CF(0.74 * s, -0.64, -0.52), p.glow, NEON)
			end
			c:sparkle(p.glow, 3, 0.6, 0.18)
			c:light(p.glow, 1.4, 8)
		end,
	}

	-- A smoking caldera: a ring of volcanic rock round a lake of lava, with
	-- islands still standing in it and steam drifting off the rim.
	S.ir_t_caldera = {
		label = "Smoking Caldera",
		set = SET,
		tint = C3(255, 122, 32),
		scale = 1.20,
		head = CF(0, 0.90, 0.10),
		neck = CF(0, -0.50, 1.00),
		back = CF(0, 0.30, -1.00),
		build = function(c, p)
			c:cone(V3(2.40, 1.10, 2.30), CF(0, -0.50, 0) * ANG(PI, 0, 0), p.dark, SLATE)
			c:cyl(V3(0.50, 2.20, 2.20), CF(0, 0.20, 0) * UP, p.base, SLATE)
			c:cyl(V3(0.20, 1.76, 1.76), CF(0, 0.40, 0) * UP, p.deep, SLATE)
			c:cyl(V3(0.12, 1.60, 1.60), CF(0, 0.48, 0) * UP, LAVA, NEON)
			c:cyl(V3(0.08, 0.90, 0.90), CF(0, 0.53, 0) * UP, WHITEHOT, NEON)
			-- Peaks round the rim, tallest at the back.
			for k = 0, 5 do
				local a = k * PI / 3 + PI / 6
				local h = 0.34 + 0.22 * math.max(0, -math.cos(a))
				c:cone(V3(0.50, h + 0.30, 0.48), CF(0, 0.42 + h / 2, 0) * ANG(0, a, 0) * CF(0, 0, 0.98), p.light, SLATE)
			end
			-- Islands of cooled rock in the lake.
			c:box(V3(0.44, 0.24, 0.40), CF(-0.34, 0.54, -0.26) * ANG(0, 0.4, 0), p.dark, SLATE)
			c:box(V3(0.32, 0.20, 0.30), CF(0.40, 0.52, 0.20) * ANG(0, 0.7, 0), p.deep, SLATE)
			-- The face on the outer slope.
			face(c, -0.20, 1.00, 0.38, 0.18, EMBER)
			blush(c, 0.66, -0.52, 0.92)
			-- Lava running down the outside, and steam on the rim.
			for _, s in ipairs(SIDES) do
				c:box(V3(0.16, 0.90, 0.14), CF(0.84 * s, -0.10, 0.52) * ANG(0.4, 0, 0.3 * s), LAVA, NEON)
				c:ball(V3(0.44, 0.44, 0.44), CF(0.80 * s, 0.84, -0.62), STEAM).Transparency = 0.4
			end
			c:ball(V3(0.60, 0.60, 0.60), CF(0, 0.92, -0.20), STEAM).Transparency = 0.35
			c:sparkle(EMBER, 3, 0.6, 0.2)
			c:light(LAVA, 1.8, 10)
		end,
	}

	-- An obsidian lavafall: a glassy black cliff with a sheet of lava pouring
	-- off its lip into a glowing pool, and hardened ledges either side.
	S.ir_t_lavafall = {
		label = "Obsidian Lavafall",
		set = SET,
		tint = C3(220, 56, 34),
		scale = 1.10,
		head = CF(0, 1.50, -0.30),
		neck = CF(0, -0.70, 0.80),
		back = CF(0, 0.40, -0.70),
		build = function(c, p)
			-- The cliff and its lip.
			c:box(V3(1.90, 1.90, 0.90), CF(0, 0.40, -0.60), p.dark, SLATE)
			c:box(V3(2.06, 0.26, 1.10), CF(0, 1.30, -0.52), p.deep, SLATE)
			c:box(V3(1.40, 0.14, 0.50), CF(0, 1.42, -0.12), LAVA, NEON)
			-- The sheet of lava, breaking into three strands as it falls.
			c:box(V3(1.20, 1.80, 0.26), CF(0, 0.50, -0.06), LAVA, NEON)
			c:box(V3(0.56, 1.70, 0.14), CF(0, 0.40, 0.06), WHITEHOT, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.26, 1.10, 0.20), CF(0.74 * s, 0.10, 0.02) * ANG(0, 0, 0.1 * s), LAVA, NEON)
				c:box(V3(0.30, 0.90, 0.60), CF(0.94 * s, 0.70, -0.32), p.base, SLATE)
				c:box(V3(0.34, 0.16, 0.66), CF(0.94 * s, 1.18, -0.28), p.light, SLATE)
				c:ball(V3(0.34, 0.34, 0.34), CF(0.62 * s, -0.26, 0.42), STEAM).Transparency = 0.4
			end
			-- The pool it lands in, with a crust growing over the edge.
			c:cyl(V3(0.34, 2.10, 2.10), CF(0, -0.86, 0.10) * UP, p.deep, SLATE)
			c:cyl(V3(0.14, 1.80, 1.80), CF(0, -0.68, 0.10) * UP, LAVA, NEON)
			c:cyl(V3(0.09, 1.00, 1.00), CF(0, -0.63, 0.14) * UP, WHITEHOT, NEON)
			for k = 0, 4 do
				local a = k * 2 * PI / 5 + 0.4
				c:box(V3(0.40, 0.18, 0.34), CF(0, -0.64, 0.10) * ANG(0, a, 0) * CF(0, 0, 0.80), p.dark, SLATE)
			end
			-- The face is on the cliff above the fall.
			face(c, 0.92, -0.14, 0.44, 0.19, EMBER)
			c:sparkle(LAVA, 4, 0.7, 0.2)
			c:light(LAVA, 2.0, 10)
		end,
	}

	-- A chainfire loom: a timber frame weaving red-hot chain into a sheet of
	-- cloth that is still glowing, with treadles and a flying shuttle.
	S.ir_t_loom = {
		label = "Chainfire Loom",
		set = SET,
		tint = C3(150, 40, 255),
		head = CF(0, 1.70, -0.20),
		neck = CF(0, -0.60, 0.80),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.22, 2.20, 0.24), CF(0.92 * s, 0.10, -0.50), p.deep, WOOD)
				c:box(V3(0.22, 1.30, 0.24), CF(0.92 * s, -0.35, 0.62), p.deep, WOOD)
				c:box(V3(0.40, 0.20, 0.60), CF(0.92 * s, -1.08, 0.06), p.dark, WOOD)
				c:box(V3(0.26, 0.24, 1.60), CF(0.92 * s, 0.10, 0.06), p.dark, WOOD)
			end
			c:box(V3(2.00, 0.24, 0.30), CF(0, 1.26, -0.50), p.deep, WOOD)
			c:box(V3(2.00, 0.22, 0.30), CF(0, 0.26, 0.62), p.dark, WOOD)
			-- The warp: glowing chain strung from the top beam down to the web.
			for _, x in ipairs({ -0.62, -0.32, 0, 0.32, 0.62 }) do
				c:box(V3(0.10, 1.40, 0.10), CF(x, 0.50, -0.40) * ANG(0.12, 0, 0), p.glow, NEON)
			end
			-- The web coming off the breast beam, cooling as it goes.
			c:box(V3(1.60, 0.14, 0.90), CF(0, 0.22, 0.10) * ANG(0.12, 0, 0), LAVA, NEON)
			c:box(V3(1.50, 0.14, 0.60), CF(0, -0.02, 0.76), p.light)
			c:box(V3(1.40, 0.12, 0.30), CF(0, -0.34, 1.04) * ANG(0.6, 0, 0), p.dark)
			-- The beater, the shuttle flying across it, and the treadles.
			c:box(V3(1.80, 0.20, 0.22), CF(0, 0.74, -0.18) * ANG(0.2, 0, 0), p.base, WOOD)
			c:box(V3(0.56, 0.16, 0.20), CF(0.44, 0.60, -0.04), BRASS, METAL)
			c:cone(V3(0.18, 0.26, 0.18), CF(0.80, 0.60, -0.04) * ANG(0, 0, -PI / 2), BRASS, METAL)
			for _, x in ipairs({ -0.40, 0.40 }) do
				c:box(V3(0.44, 0.14, 0.70), CF(x, -0.90, 0.28) * ANG(0.15, 0, 0), p.base, WOOD)
			end
			-- The face is on the castle of the loom, over the warp.
			face(c, 0.96, -0.32, 0.34, 0.16)
			blush(c, 0.56, 0.62, -0.34)
			c:sparkle(p.glow, 3, 0.5, 0.18)
			c:light(LAVA, 1.6, 9)
		end,
	}

	-- A cinder gatehouse: two drum towers with a glowing arch between them,
	-- battlements, murder-holes above the gate and banners down the flanks.
	S.ir_t_gatehouse = {
		label = "Cinder Gatehouse",
		set = SET,
		tint = C3(10, 80, 90),
		scale = 1.15,
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.80, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:box(V3(2.20, 0.26, 1.40), CF(0, -1.12, 0), p.deep, SLATE)
			c:box(V3(1.20, 1.90, 1.10), CF(0, -0.04, 0), p.base, SLATE)
			c:box(V3(1.34, 0.22, 1.24), CF(0, 1.02, 0), p.dark, SLATE)
			for _, s in ipairs(SIDES) do
				-- A drum tower each side, capped with merlons.
				c:cyl(V3(2.00, 1.00, 1.00), CF(0.90 * s, -0.04, 0) * UP, p.light, SLATE)
				c:cyl(V3(0.22, 1.16, 1.16), CF(0.90 * s, 1.02, 0) * UP, p.dark, SLATE)
				for k = 0, 3 do
					local a = k * PI / 2 + PI / 4
					c:box(V3(0.26, 0.34, 0.26), CF(0.90 * s, 1.28, 0) * ANG(0, a, 0) * CF(0, 0, 0.40), p.light, SLATE)
				end
				c:box(V3(0.10, 0.34, 0.22), CF(0.90 * s, 0.30, 0.52), LAVA, NEON)
				-- Banners hung off the tower fronts.
				c:box(V3(0.34, 0.80, 0.08), CF(0.90 * s, -0.30, 0.56), p.deep)
				c:cone(V3(0.34, 0.26, 0.08), CF(0.90 * s, -0.82, 0.56) * ANG(PI, 0, 0), p.deep)
				c:box(V3(0.20, 0.20, 0.06), CF(0.90 * s, -0.20, 0.60) * DIAMOND, EMBER, NEON)
			end
			-- Merlons over the middle, and the gate arch itself.
			for _, x in ipairs({ -0.40, 0, 0.40 }) do
				c:box(V3(0.26, 0.36, 0.30), CF(x, 1.30, 0), p.light, SLATE)
			end
			c:box(V3(0.88, 1.10, 0.14), CF(0, -0.52, 0.56), p.deep, SLATE)
			c:box(V3(0.66, 0.86, 0.10), CF(0, -0.56, 0.62), LAVA, NEON)
			c:cone(V3(0.74, 0.30, 0.12), CF(0, 0.00, 0.62), LAVA, NEON)
			for _, x in ipairs({ -0.18, 0.18 }) do
				c:box(V3(0.10, 0.90, 0.08), CF(x, -0.56, 0.66), p.dark, METAL)
			end
			-- Murder-holes read as its eyes; the arch is its mouth.
			c:eyes(0.42, 0.62, 0.30, 0.16, EMBER)
			c:box(V3(0.50, 0.10, 0.06), CF(0, 0.74, 0.58), p.deep)
			c:sparkle(EMBER, 2, 0.5, 0.18)
			c:light(LAVA, 1.8, 9)
		end,
	}

	-- A forge stagbeetle: brass pincer-mandibles held high, iron elytra with a
	-- lava seam between them, and glowing joints down its legs.
	S.ir_t_stagbeetle = {
		label = "Forge Stagbeetle",
		set = SET,
		tint = C3(98, 214, 112),
		scale = 1.15,
		head = CF(0, 0.90, 0.50),
		neck = CF(0, -0.30, 1.00),
		back = CF(0, 0.80, -0.50),
		build = function(c, p)
			c:ovoid(V3(1.50, 0.90, 1.60), CF(0, 0.10, -0.40), p.base, METAL)
			c:box(V3(0.12, 0.30, 1.50), CF(0, 0.52, -0.40), LAVA, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.64, 0.50, 1.46), CF(0.42 * s, 0.30, -0.40) * ANG(0, 0, 0.22 * s), p.dark, METAL)
				c:box(V3(0.10, 0.16, 1.10), CF(0.74 * s, 0.12, -0.40), p.light, METAL)
				for _, z in ipairs({ 0.12, -0.36, -0.84 }) do
					c:rod(V3(0.66 * s, -0.08, z), V3(1.04 * s, -0.46, z - 0.06), 0.07, p.deep, METAL, false)
					c:ball(V3(0.16, 0.16, 0.16), CF(0.86 * s, -0.28, z - 0.03), EMBER, NEON)
					c:rod(V3(1.04 * s, -0.46, z - 0.06), V3(1.18 * s, -0.86, z - 0.02), 0.05, p.deep, METAL, false)
				end
			end
			-- Thorax, head and the great mandibles.
			c:box(V3(1.10, 0.60, 0.60), CF(0, 0.10, 0.52), p.light, METAL)
			c:box(V3(0.82, 0.54, 0.52), CF(0, 0.06, 1.02), p.dark, METAL)
			c:eyes(0.14, 1.26, 0.30, 0.15, EMBER)
			c:box(V3(0.26, 0.07, 0.06), CF(0, -0.10, 1.26), INK)
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.26 * s, 0.26, 1.22), V3(0.56 * s, 0.66, 1.62), 0.10, BRASS, METAL, false)
				c:rod(V3(0.56 * s, 0.66, 1.62), V3(0.30 * s, 1.02, 1.96), 0.09, BRASS, METAL, false)
				c:cone(V3(0.18, 0.32, 0.18), CF(0.18 * s, 1.20, 2.08) * ANG(0.6, 0, 0.5 * s), BRASS, METAL)
				c:cone(V3(0.14, 0.24, 0.14), CF(0.52 * s, 0.84, 1.78) * ANG(0, 0, -PI / 2 * s), BRASS, METAL)
				c:rod(V3(0.20 * s, 0.26, 1.18), V3(0.46 * s, 0.10, 1.44), 0.04, p.deep, nil, false)
			end
			c:sparkle(EMBER, 2, 0.5, 0.16)
			c:light(LAVA, 1.2, 8)
		end,
	}

	--------------------------------------------------------------------------
	-- DIVINE: the citadel and its regalia, radiant.
	--------------------------------------------------------------------------

	-- The Infernal Citadel itself on its floating crag: curtain wall, corner
	-- towers, a glowing gate for a mouth and lava running off the rock below.
	S.ir_t_citadel = {
		label = "Infernal Citadel",
		set = SET,
		tint = C3(120, 50, 200),
		scale = 1.25,
		head = CF(0, 1.70, -0.20),
		neck = CF(0, -0.60, 1.00),
		back = CF(0, 0.60, -1.00),
		build = function(c, p)
			-- The crag.
			c:box(V3(2.10, 0.50, 1.80), CF(0, -0.60, 0), p.dark, SLATE)
			c:cone(V3(1.80, 1.10, 1.50), CF(0, -1.40, 0) * ANG(PI, 0, 0), p.deep, SLATE)
			c:box(V3(0.14, 0.80, 0.14), CF(0.30, -1.50, 0.20), LAVA, NEON)
			c:box(V3(0.12, 0.60, 0.12), CF(-0.36, -1.34, -0.24), EMBER, NEON)
			-- Curtain wall with battlements.
			c:box(V3(2.00, 0.80, 1.70), CF(0, 0.05, 0), p.base, SLATE)
			c:box(V3(2.06, 0.14, 1.76), CF(0, 0.52, 0), p.light, SLATE)
			for _, x in ipairs({ -0.66, -0.22, 0.22, 0.66 }) do
				c:box(V3(0.24, 0.30, 0.24), CF(x, 0.72, 0.80), p.light, SLATE)
			end
			-- The keep behind, and the two corner towers.
			c:box(V3(1.00, 0.90, 0.90), CF(0, 0.84, -0.40), p.base, SLATE)
			c:box(V3(1.10, 0.14, 1.00), CF(0, 1.34, -0.40), p.light, SLATE)
			c:cone(V3(1.00, 0.56, 0.92), CF(0, 1.68, -0.40), p.deep, SLATE)
			c:box(V3(0.18, 0.18, 0.18), CF(0, 2.02, -0.40) * ANG(0, PI / 4, 0), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:cyl(V3(1.50, 0.70, 0.70), CF(0.86 * s, 0.30, 0.70) * UP, p.light, SLATE)
				c:cyl(V3(0.16, 0.86, 0.86), CF(0.86 * s, 1.08, 0.70) * UP, p.deep, SLATE)
				c:cone(V3(0.80, 0.52, 0.80), CF(0.86 * s, 1.42, 0.70), p.deep, SLATE)
				c:box(V3(0.10, 0.26, 0.18), CF(0.86 * s, 0.50, 1.06), LAVA, NEON)
				c:box(V3(0.28, 0.22, 0.06), CF(0.86 * s, 1.74, 0.70) * DIAMOND, p.glow, NEON)
				c:box(V3(0.14, 0.60, 0.10), CF(0.50 * s, 0.10, 0.88), p.deep)
			end
			-- The gate: its mouth, with a face on the wall above it.
			c:box(V3(0.80, 0.66, 0.16), CF(0, -0.18, 0.86), p.deep, SLATE)
			c:box(V3(0.60, 0.48, 0.10), CF(0, -0.20, 0.92), LAVA, NEON)
			c:cone(V3(0.66, 0.26, 0.12), CF(0, 0.14, 0.92), LAVA, NEON)
			c:eyes(0.26, 0.90, 0.34, 0.16, EMBER)
			c:sparkle(p.glow, 3, 0.5, 0.2)
			c:light(LAVA, 2.0, 10)
		end,
	}

	-- An everburning halo: a ring of flame stood upright in an obsidian
	-- cradle, with a bright disc at its heart and iron spokes holding it true.
	S.ir_t_halo = {
		label = "Everburning Halo",
		set = SET,
		tint = C3(255, 240, 214),
		head = CF(0, 1.80, 0),
		neck = CF(0, -0.90, 0.30),
		back = CF(0, 0.30, -0.30),
		build = function(c, p)
			local at = CF(0, 0.44, 0)
			-- The ring: twelve segments, every other one white-hot.
			for k = 0, 11 do
				local a = k * PI / 6
				c:box(V3(0.30, 0.42, 0.30), at * ANG(0, 0, a) * CF(0, 1.02, 0), k % 2 == 0 and LAVA or p.glow, NEON)
			end
			for k = 0, 5 do
				local a = k * PI / 3 + PI / 6
				c:cone(V3(0.26, 0.34, 0.26), at * ANG(0, 0, a) * CF(0, 1.34, 0), WHITEHOT, NEON)
			end
			-- Spokes to the hub, so nothing is adrift.
			for k = 0, 3 do
				local a = k * PI / 2 + PI / 4
				c:box(V3(0.12, 1.10, 0.12), at * ANG(0, 0, a) * CF(0, 0.58, 0), p.deep, METAL)
			end
			c:cyl(V3(0.26, 0.96, 0.96), at * FRONT, p.dark, METAL)
			c:cyl(V3(0.12, 0.76, 0.76), at * CF(0, 0, 0.16) * FRONT, p.pale, NEON)
			face(c, 0.52, 0.24, 0.22, 0.13)
			blush(c, 0.32, 0.26, 0.22)
			-- The cradle it stands in.
			c:box(V3(1.40, 0.30, 1.20), CF(0, -0.96, 0), p.dark, SLATE)
			c:box(V3(1.10, 0.18, 0.90), CF(0, -0.74, 0), p.deep, SLATE)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.22, 0.60, 0.34), CF(0.44 * s, -0.42, 0) * ANG(0, 0, -0.3 * s), p.base, SLATE)
				c:box(V3(0.16, 0.16, 0.26), CF(0.58 * s, -0.10, 0), BRASS, METAL)
				c:box(V3(0.12, 0.10, 0.60), CF(0.52 * s, -0.84, 0), LAVA, NEON)
			end
			c:sparkle(WHITEHOT, 4, 0.6, 0.2)
			c:light(LAVA, 2.2, 11)
		end,
	}

	-- A magma harp: an obsidian pillar and a carved soundbox strung with
	-- strings of molten rock that ring when they are plucked.
	S.ir_t_harp = {
		label = "Magma Harp",
		set = SET,
		tint = C3(230, 40, 200),
		scale = 1.10,
		head = CF(0, 1.80, -0.30),
		neck = CF(0, -0.60, 0.40),
		back = CF(0, 0.20, -0.50),
		build = function(c, p)
			-- The soundbox, leaning back, with the face on its front.
			c:box(V3(0.70, 2.00, 0.60), CF(0.60, 0.10, 0.10) * ANG(0, 0, 0.12), p.base, SLATE)
			c:box(V3(0.22, 1.80, 0.16), CF(0.60, 0.10, 0.42) * ANG(0, 0, 0.12), p.light, SLATE)
			c:box(V3(0.86, 0.22, 0.74), CF(0.54, -0.92, 0.10), p.dark, SLATE)
			-- The pillar, and the curved neck across the top.
			c:rod(V3(-0.74, -0.84, 0.06), V3(-0.62, 0.96, 0.06), 0.13, p.dark, SLATE, false)
			c:box(V3(0.44, 0.24, 0.44), CF(-0.74, -0.94, 0.06), p.deep, SLATE)
			c:rod(V3(-0.62, 1.00, 0.06), V3(-0.10, 1.48, 0.08), 0.12, p.deep, SLATE, false)
			c:rod(V3(-0.10, 1.48, 0.08), V3(0.52, 1.22, 0.10), 0.12, p.deep, SLATE, false)
			c:cone(V3(0.26, 0.36, 0.26), CF(-0.66, 1.16, 0.06) * ANG(0, 0, 0.5), p.light, SLATE)
			-- The strings, longest at the pillar end.
			for i = 0, 5 do
				local x = -0.52 + i * 0.21
				local top = 1.44 - math.abs(i - 1) * 0.05
				c:box(V3(0.08, top - (-0.10 + i * 0.16), 0.08), CF(x, (top + (-0.10 + i * 0.16)) / 2, 0.14), i % 2 == 0 and LAVA or EMBER, NEON)
			end
			face(c, 0.30, 0.46, 0.20, 0.13, EMBER)
			blush(c, 0.26, 0.04, 0.44)
			-- Brass tuning pins along the neck, and a brass foot.
			for i = 0, 5 do
				c:ball(V3(0.18, 0.18, 0.18), CF(-0.52 + i * 0.21, 1.42 - math.abs(i - 1) * 0.05, 0.20), BRASS, METAL)
			end
			c:box(V3(0.96, 0.14, 0.84), CF(0.54, -1.08, 0.10), BRASS, METAL)
			c:sparkle(EMBER, 3, 0.5, 0.18)
			c:light(LAVA, 1.6, 9)
		end,
	}

	-- A sunforged aegis: a great round shield whose boss is its face, with
	-- lava channels radiating out of it and a flame crest over the rim.
	S.ir_t_aegis = {
		label = "Sunforged Aegis",
		set = SET,
		tint = C3(255, 186, 50),
		scale = 1.10,
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.90, 0.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			local at = CF(0, 0.26, 0)
			c:cyl(V3(0.30, 2.20, 2.20), at * FRONT, p.deep, METAL)
			c:cyl(V3(0.34, 1.96, 1.96), at * CF(0, 0, 0.06) * FRONT, p.base, METAL)
			c:cyl(V3(0.34, 1.20, 1.20), at * CF(0, 0, 0.14) * FRONT, p.dark, METAL)
			-- Radiating channels, and studs between them.
			for k = 0, 7 do
				local a = k * PI / 4
				c:box(V3(0.12, 0.84, 0.10), at * ANG(0, 0, a) * CF(0, 0.74, 0.22), LAVA, NEON)
				c:ball(V3(0.20, 0.20, 0.20), at * ANG(0, 0, a + PI / 8) * CF(0, 0.92, 0.18), BRASS, METAL)
			end
			c:cyl(V3(0.30, 0.86, 0.86), at * CF(0, 0, 0.22) * FRONT, p.light, METAL)
			face(c, 0.36, 0.36, 0.24, 0.14)
			blush(c, 0.36, 0.08, 0.34)
			-- Flame crest over the top of the rim.
			flame(c, V3(0, 1.36, 0.04), 0.46, 0.60)
			flame(c, V3(-0.44, 1.18, 0.04), 0.30, 0.40, EMBER)
			flame(c, V3(0.44, 1.18, 0.04), 0.28, 0.36, EMBER)
			-- Arm straps behind, and two little legs to carry it on.
			for _, s in ipairs(SIDES) do
				c:box(V3(0.60, 0.20, 0.20), CF(0.34 * s, 0.26, -0.20), LEATHER)
				c:box(V3(0.34, 0.54, 0.34), CF(0.46 * s, -0.96, 0.04), p.dark, METAL)
				c:box(V3(0.42, 0.18, 0.52), CF(0.46 * s, -1.24, 0.12), p.deep, METAL)
			end
			c:sparkle(EMBER, 3, 0.5, 0.18)
			c:light(LAVA, 1.8, 9)
		end,
	}

	-- A hellbound chariot: an iron car with a face on its dash, lava-rimmed
	-- wheels, a yoke pole with a flame on the end and a banner at the back.
	S.ir_t_chariot = {
		label = "Hellbound Chariot",
		set = SET,
		tint = C3(46, 44, 58),
		scale = 1.15,
		head = CF(0, 1.20, 0.20),
		neck = CF(0, -0.50, 1.10),
		back = CF(0, 0.50, -0.90),
		build = function(c, p)
			-- The car.
			c:box(V3(1.40, 0.30, 1.20), CF(0, -0.42, -0.10), p.dark, METAL)
			c:box(V3(1.40, 0.80, 0.20), CF(0, 0.10, 0.44), p.base, METAL)
			c:box(V3(1.46, 0.16, 0.30), CF(0, 0.54, 0.44), p.light, METAL)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.18, 0.70, 1.00), CF(0.64 * s, 0.05, -0.10), p.base, METAL)
				c:box(V3(0.22, 0.14, 1.04), CF(0.64 * s, 0.44, -0.10), p.light, METAL)
				c:box(V3(0.08, 0.40, 0.70), CF(0.74 * s, 0.05, -0.10), LAVA, NEON)
				-- Wheels: six spokes and a glowing tyre.
				c:cyl(V3(0.20, 1.40, 1.40), CF(0.94 * s, -0.34, -0.30), p.deep, METAL)
				c:cyl(V3(0.24, 1.10, 1.10), CF(0.96 * s, -0.34, -0.30), LAVA, NEON)
				c:cyl(V3(0.28, 0.88, 0.88), CF(0.98 * s, -0.34, -0.30), p.dark, METAL)
				c:cyl(V3(0.34, 0.30, 0.30), CF(1.00 * s, -0.34, -0.30), BRASS, METAL)
				for k = 0, 2 do
					c:box(V3(0.10, 0.84, 0.10), CF(0.98 * s, -0.34, -0.30) * ANG(k * PI / 3, 0, 0), p.light, METAL)
				end
			end
			c:cyl(V3(2.10, 0.20, 0.20), CF(0, -0.34, -0.30), p.deep, METAL)
			-- The dash carries the face; the pole runs out front to a flame.
			c:eyes(0.24, 0.60, 0.32, 0.16, EMBER)
			c:box(V3(0.34, 0.08, 0.06), CF(0, -0.06, 0.56), INK)
			blush(c, 0.52, -0.04, 0.54)
			c:rod(V3(0, -0.30, 0.46), V3(0, -0.18, 1.56), 0.09, p.deep, METAL, false)
			c:cyl(V3(0.16, 0.44, 0.44), CF(0, -0.18, 1.58) * FRONT, BRASS, METAL)
			flame(c, V3(0, 0.00, 1.60), 0.38, 0.50)
			-- Banner on a staff at the back.
			c:rod(V3(0, 0.20, -0.66), V3(0, 1.30, -0.66), 0.06, p.deep, METAL, false)
			c:box(V3(0.70, 0.60, 0.08), CF(0.30, 1.00, -0.66), p.glow, NEON)
			c:box(V3(0.24, 0.24, 0.06), CF(0.30, 1.00, -0.62) * DIAMOND, WHITEHOT, NEON)
			c:sparkle(LAVA, 4, 0.7, 0.2)
			c:light(LAVA, 2.0, 10)
		end,
	}

	-- A basalt leviathan breaching a sea of lava: a columnar head out front,
	-- two plated humps behind it and spray where it broke the crust.
	S.ir_t_leviathan = {
		label = "Basalt Leviathan",
		set = SET,
		tint = C3(30, 110, 140),
		scale = 1.30,
		head = CF(0, 1.10, 0.90),
		neck = CF(0, -0.10, 1.40),
		back = CF(0, 0.30, -0.40),
		build = function(c, p)
			-- Head and jaw.
			c:box(V3(1.20, 1.10, 1.00), CF(0, 0.34, 0.90), p.base, SLATE)
			c:box(V3(1.00, 0.34, 0.70), CF(0, -0.14, 1.10), p.light, SLATE)
			c:box(V3(0.90, 0.14, 0.56), CF(0, 0.04, 1.18), LAVA, NEON)
			c:eyes(0.56, 1.42, 0.32, 0.17, EMBER)
			for _, x in ipairs({ -0.30, 0, 0.30 }) do
				c:cone(V3(0.16, 0.22, 0.14), CF(x, 0.06, 1.34) * ANG(PI, 0, 0), HORN)
			end
			-- Columnar basalt plates up the head and down the back.
			for i, z in ipairs({ 0.70, 0.30, -0.20 }) do
				c:cyl(V3(0.30 + i * 0.04, 0.52 - i * 0.04, 0.52 - i * 0.04), CF(0, 0.96, z) * UP, p.dark, SLATE)
			end
			for _, s in ipairs(SIDES) do
				c:cyl(V3(0.26, 0.42, 0.42), CF(0.42 * s, 0.86, 0.50) * UP, p.deep, SLATE)
				c:box(V3(0.14, 0.60, 0.80), CF(0.64 * s, 0.10, 0.60) * ANG(0.3, 0, -0.5 * s), p.light, SLATE)
				c:box(V3(0.06, 0.40, 0.60), CF(0.62 * s, 0.34, 0.90), LAVA, NEON)
				c:ball(V3(0.40, 0.40, 0.40), CF(0.72 * s, -0.34, 0.86), STEAM).Transparency = 0.4
			end
			-- Humps arching out of the lava behind it.
			c:box(V3(1.00, 0.90, 0.90), CF(0, -0.30, -0.30) * ANG(PI / 4, 0, 0), p.base, SLATE)
			c:box(V3(0.84, 0.74, 0.74), CF(0, -0.42, -1.00) * ANG(PI / 4, 0, 0), p.dark, SLATE)
			c:cone(V3(0.18, 0.34, 0.34), CF(0, 0.26, -0.30), p.light, SLATE)
			c:cone(V3(0.16, 0.28, 0.28), CF(0, 0.02, -1.00), p.light, SLATE)
			c:box(V3(0.70, 0.14, 0.50), CF(0, -0.36, -1.52) * ANG(-0.5, 0, 0), p.light, SLATE)
			-- The lava sea, and its crust.
			c:box(V3(2.20, 0.30, 2.90), CF(0, -0.80, -0.10), LAVA, NEON)
			for _, v in ipairs({ { -0.80, 0.60 }, { 0.84, -0.20 }, { -0.70, -1.10 }, { 0.60, -1.30 } }) do
				c:box(V3(0.56, 0.16, 0.52), CF(v[1], -0.72, v[2]) * ANG(0, 0.4, 0), p.dark, SLATE)
			end
			c:sparkle(EMBER, 3, 0.6, 0.2)
			c:light(LAVA, 2.0, 11)
		end,
	}

	-- An emberglass oriole: a bird blown from glowing volcanic glass, perched
	-- on an obsidian branch, with two long flame streamers for a tail.
	S.ir_t_oriole = {
		label = "Emberglass Oriole",
		set = SET,
		tint = C3(255, 150, 30),
		scale = 1.10,
		head = CF(0, 1.20, 0.10),
		neck = CF(0, -0.10, 0.86),
		back = CF(0, 0.34, -0.76),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V3(1.50, 1.64, 1.50),
				eyeY = 0.34, eyeSpread = 0.30, eyeSize = V3(0.40, 0.48, 0.20),
				mouth = false,
				bib = { w = 0.86, h = 0.72, y = -0.34, color = p.glow },
				legs = false, tail = false,
			})
			c:cone(V3(0.22, 0.34, 0.20), CF(0, 0.10, 0.86) * ANG(PI / 2, 0, 0), BRASS, METAL)
			c:box(V3(0.20, 0.18, 0.06), CF(0, 0.62, 0.78) * DIAMOND, WHITEHOT, NEON)
			for _, s in ipairs(SIDES) do
				-- Glassy wings, half open, edged in fire.
				local wing = c:box(V3(0.14, 0.92, 1.06), CF(0.80 * s, 0.10, -0.16) * ANG(0.2, 0, 0.34 * s), p.light, GLASS)
				wing.Transparency = 0.3
				c:box(V3(0.16, 0.16, 0.90), CF(0.92 * s, 0.46, -0.20) * ANG(0.2, 0, 0.34 * s), LAVA, NEON)
				c:box(V3(0.14, 0.30, 0.30), CF(0.98 * s, -0.26, -0.44) * ANG(0.2, 0, 0.34 * s), EMBER, NEON)
				-- Feet gripping the branch.
				c:rod(V3(0.24 * s, -0.78, 0.10), V3(0.26 * s, -1.02, 0.14), 0.05, BRASS, METAL, false)
				c:box(V3(0.20, 0.08, 0.38), CF(0.26 * s, -1.06, 0.20), BRASS, METAL)
				-- The streamers.
				c:box(V3(0.14, 0.20, 1.00), CF(0.16 * s, -0.24, -1.04) * ANG(0.3, 0, 0), LAVA, NEON)
				c:box(V3(0.12, 0.16, 0.70), CF(0.24 * s, -0.56, -1.74) * ANG(0.5, 0, 0), EMBER, NEON)
			end
			c:box(V3(0.34, 0.20, 0.80), CF(0, -0.06, -0.92), p.glow, NEON)
			-- The branch of obsidian it stands on.
			c:rod(V3(-0.90, -1.14, 0.18), V3(0.90, -1.14, 0.18), 0.12, p.deep, SLATE, false)
			c:box(V3(0.30, 0.34, 0.30), CF(-0.84, -1.30, 0.14), p.dark, SLATE)
			c:box(V3(0.26, 0.30, 0.26), CF(0.80, -1.28, 0.22), p.dark, SLATE)
			c:sparkle(EMBER, 4, 0.6, 0.2)
			c:light(LAVA, 1.8, 9)
		end,
	}

	-- The ninefold keystone: the stone at the crown of the Ninth Circle's
	-- arch, nine rings cut into its face, held between two spans of voussoirs.
	S.ir_t_keystone = {
		label = "Ninefold Keystone",
		set = SET,
		tint = C3(140, 150, 180),
		head = CF(0, 1.50, 0),
		neck = CF(0, -0.80, 0.50),
		back = CF(0, 0.20, -0.50),
		build = function(c, p)
			-- The keystone: a wedge, wide at the top.
			c:box(V3(1.20, 1.50, 1.00), CF(0, 0.30, 0), p.base, SLATE)
			c:box(V3(0.86, 0.40, 1.04), CF(0, -0.64, 0), p.base, SLATE)
			c:box(V3(1.34, 0.20, 1.08), CF(0, 1.14, 0), p.light, SLATE)
			-- Nine rings cut into the face, the middle one alight.
			for i = 0, 8 do
				local r = 0.10 + i * 0.045
				c:cyl(V3(0.06, r * 2, r * 2), CF(0, 0.34, 0.51 + i * 0.004) * FRONT, i == 4 and LAVA or (i % 2 == 0 and p.dark or p.deep), i == 4 and NEON or SLATE)
			end
			face(c, 0.44, 0.58, 0.24, 0.13, EMBER)
			blush(c, 0.40, 0.14, 0.54)
			-- The voussoirs curving away either side.
			for _, s in ipairs(SIDES) do
				for i = 1, 3 do
					local a = i * 0.34
					c:box(V3(0.44, 1.10 - i * 0.08, 0.96), CF(0, 0.30, 0) * ANG(0, 0, a * s) * CF(0.70 * s + 0.22 * s * (i - 1), 0, 0), i % 2 == 0 and p.light or p.dark, SLATE)
				end
				c:box(V3(0.30, 0.44, 1.00), CF(1.74 * s, -0.84, 0), p.deep, SLATE)
				c:box(V3(0.10, 1.30, 0.14), CF(0.62 * s, 0.26, 0.54) * ANG(0, 0, 0.3 * s), LAVA, NEON)
			end
			c:box(V3(0.24, 0.24, 0.24), CF(0, 1.38, 0) * ANG(0, PI / 4, 0), p.glow, NEON)
			c:cone(V3(0.30, 0.34, 0.30), CF(0, 1.62, 0), WHITEHOT, NEON)
			c:sparkle(p.glow, 3, 0.5, 0.18)
			c:light(LAVA, 1.6, 9)
		end,
	}

	--------------------------------------------------------------------------
	-- EXOTIC: the wonders at the bottom of the Ninth Circle.
	--------------------------------------------------------------------------

	-- The ninefold spire: nine tiers of obsidian stepping up to a flame, each
	-- ringed with a band of light, buttressed down to a six-sided plinth.
	S.ir_t_spire = {
		label = "Ninefold Spire",
		set = SET,
		tint = C3(190, 160, 230),
		scale = 1.15,
		head = CF(0, 1.90, 0),
		neck = CF(0, -0.90, 0.60),
		back = CF(0, 0.00, -0.60),
		build = function(c, p)
			-- The plinth.
			c:cyl(V3(0.26, 2.10, 2.10), CF(0, -1.18, 0) * UP, p.deep, SLATE)
			c:cyl(V3(0.20, 1.70, 1.70), CF(0, -0.96, 0) * UP, p.dark, SLATE)
			c:cyl(V3(0.08, 1.80, 1.80), CF(0, -0.84, 0) * UP, LAVA, NEON)
			-- Nine tiers, each a little narrower than the one below it.
			for i = 0, 8 do
				local y = -0.70 + i * 0.28
				local w = 1.46 - i * 0.13
				c:box(V3(w, 0.22, w), CF(0, y, 0) * ANG(0, i * 0.12, 0), i % 2 == 0 and p.base or p.light, SLATE)
				c:box(V3(w * 0.92, 0.07, w * 0.92), CF(0, y + 0.15, 0) * ANG(0, i * 0.12, 0), i == 4 and WHITEHOT or LAVA, NEON)
			end
			c:cone(V3(0.44, 0.46, 0.44), CF(0, 1.98, 0), p.dark, SLATE)
			flame(c, V3(0, 2.26, 0), 0.40, 0.56)
			-- Buttresses running up the first three tiers, and the face.
			for k = 0, 2 do
				local a = k * 2 * PI / 3 + PI / 3
				c:box(V3(0.26, 1.10, 0.44), CF(0, -0.36, 0) * ANG(0, a, 0) * CF(0, 0, 0.72) * ANG(-0.2, 0, 0), p.dark, SLATE)
				c:cone(V3(0.24, 0.30, 0.24), CF(0, 0.26, 0) * ANG(0, a, 0) * CF(0, 0, 0.56), p.pale, SLATE)
			end
			face(c, -0.46, 0.76, 0.28, 0.15, EMBER)
			blush(c, 0.48, -0.74, 0.70)
			c:sparkle(p.glow, 5, 0.7, 0.22)
			c:light(LAVA, 2.4, 12)
		end,
	}

	-- A molten fountain: three basalt basins brimming over, pouring sheets of
	-- lava down into the pool, with carved spouts and steam off the surface.
	S.ir_t_fountain = {
		label = "Molten Fountain",
		set = SET,
		tint = C3(40, 220, 230),
		scale = 1.20,
		head = CF(0, 1.80, 0),
		neck = CF(0, -0.70, 0.90),
		back = CF(0, 0.10, -0.90),
		build = function(c, p)
			-- The pool.
			c:cyl(V3(0.46, 2.40, 2.40), CF(0, -0.98, 0) * UP, p.base, SLATE)
			c:cyl(V3(0.16, 2.50, 2.50), CF(0, -0.72, 0) * UP, p.dark, SLATE)
			c:cyl(V3(0.12, 2.16, 2.16), CF(0, -0.74, 0) * UP, LAVA, NEON)
			c:cyl(V3(0.08, 1.30, 1.30), CF(0, -0.70, 0) * UP, WHITEHOT, NEON)
			-- Two tiers of basin above it, on a stem.
			c:cyl(V3(0.44, 0.50, 0.50), CF(0, -0.42, 0) * UP, p.deep, SLATE)
			c:cyl(V3(0.18, 1.50, 1.50), CF(0, -0.10, 0) * UP, p.base, SLATE)
			c:cyl(V3(0.10, 1.30, 1.30), CF(0, 0.02, 0) * UP, LAVA, NEON)
			c:cyl(V3(0.44, 0.38, 0.38), CF(0, 0.26, 0) * UP, p.deep, SLATE)
			c:cyl(V3(0.16, 0.96, 0.96), CF(0, 0.54, 0) * UP, p.light, SLATE)
			c:cyl(V3(0.09, 0.80, 0.80), CF(0, 0.64, 0) * UP, LAVA, NEON)
			c:cyl(V3(0.34, 0.30, 0.30), CF(0, 0.86, 0) * UP, p.deep, SLATE)
			c:cone(V3(0.46, 0.44, 0.46), CF(0, 1.18, 0), p.dark, SLATE)
			flame(c, V3(0, 1.48, 0), 0.40, 0.54)
			-- The overflow: sheets of lava from each rim to the one below.
			for k = 0, 3 do
				local a = k * PI / 2 + PI / 4
				c:box(V3(0.26, 0.42, 0.14), CF(0, 0.38, 0) * ANG(0, a, 0) * CF(0, 0, 0.44), LAVA, NEON)
				c:box(V3(0.34, 0.50, 0.16), CF(0, -0.28, 0) * ANG(0, a, 0) * CF(0, 0, 0.70), LAVA, NEON)
			end
			-- Carved spouts round the pool rim, and the face on the kerb.
			for k = 0, 5 do
				local a = k * PI / 3 + PI / 6
				c:cone(V3(0.26, 0.30, 0.26), CF(0, -0.62, 0) * ANG(0, a, 0) * CF(0, 0, 1.18), p.pale, SLATE)
			end
			face(c, -1.00, 1.22, 0.38, 0.18, EMBER)
			blush(c, 0.68, -1.30, 1.14)
			c:ball(V3(0.50, 0.50, 0.50), CF(-0.70, -0.30, 0.70), STEAM).Transparency = 0.4
			c:ball(V3(0.40, 0.40, 0.40), CF(0.78, -0.36, -0.52), STEAM).Transparency = 0.4
			c:sparkle(EMBER, 5, 0.7, 0.22)
			c:light(LAVA, 2.6, 12)
		end,
	}

	-- The infernal engine: the machine that drives the whole forge -- a
	-- glowing firebox for a face, a great flywheel, a piston and brass pipes.
	S.ir_t_engine = {
		label = "Infernal Engine",
		set = SET,
		tint = C3(100, 140, 170),
		scale = 1.20,
		head = CF(0, 1.40, -0.20),
		neck = CF(0, -0.60, 1.00),
		back = CF(0, 0.40, -1.00),
		build = function(c, p)
			-- Bed plate and boiler.
			c:box(V3(2.20, 0.26, 1.60), CF(0, -1.04, 0), p.deep, METAL)
			c:cyl(V3(1.80, 1.30, 1.30), CF(0, -0.20, -0.10) * FRONT, p.base, METAL)
			for _, z in ipairs({ -0.70, 0.30 }) do
				c:cyl(V3(0.12, 1.38, 1.38), CF(0, -0.20, z) * FRONT, p.dark, METAL)
			end
			-- The firebox door at the front is its face.
			c:cyl(V3(0.20, 1.26, 1.26), CF(0, -0.20, 0.82) * FRONT, p.light, METAL)
			c:cyl(V3(0.12, 0.92, 0.92), CF(0, -0.20, 0.90) * FRONT, LAVA, NEON)
			c:eyes(0.08, 0.98, 0.30, 0.16, EMBER)
			c:box(V3(0.44, 0.10, 0.06), CF(0, -0.44, 0.96), INK)
			c:cyl(V3(0.14, 0.26, 0.26), CF(0.46, -0.20, 0.94) * FRONT, BRASS, METAL)
			-- Steam dome, chimney and a pressure gauge.
			c:ball(V3(0.50, 0.50, 0.50), CF(0, 0.44, -0.30), BRASS, METAL)
			c:cyl(V3(0.70, 0.40, 0.40), CF(0, 0.70, 0.30) * UP, p.deep, METAL)
			c:cyl(V3(0.12, 0.54, 0.54), CF(0, 1.06, 0.30) * UP, p.dark, METAL)
			c:ball(V3(0.40, 0.40, 0.40), CF(0.06, 1.34, 0.30), STEAM).Transparency = 0.35
			c:cyl(V3(0.10, 0.44, 0.44), CF(-0.40, 0.54, 0.44) * FRONT, BRASS, METAL)
			c:box(V3(0.05, 0.16, 0.05), CF(-0.38, 0.58, 0.50) * ANG(0, 0, -0.6), INK)
			-- The flywheel on one side, with its crank and connecting rod.
			c:cyl(V3(0.22, 1.90, 1.90), CF(1.00, -0.26, -0.30), p.dark, METAL)
			c:cyl(V3(0.26, 1.56, 1.56), CF(1.02, -0.26, -0.30), p.light, METAL)
			c:cyl(V3(0.34, 0.36, 0.36), CF(1.06, -0.26, -0.30), BRASS, METAL)
			for k = 0, 2 do
				c:box(V3(0.12, 1.48, 0.12), CF(1.02, -0.26, -0.30) * ANG(k * PI / 3, 0, 0), p.base, METAL)
			end
			c:box(V3(0.12, 0.26, 0.26), CF(1.06, -0.26, 0.34), BRASS, METAL)
			c:rod(V3(1.06, -0.26, 0.34), V3(0.74, -0.40, 0.98), 0.07, p.pale, METAL, false)
			-- Piston and valve gear on the other side.
			c:cyl(V3(1.00, 0.52, 0.52), CF(-0.96, -0.40, 0.40) * FRONT, p.dark, METAL)
			c:rod(V3(-0.96, -0.40, 0.88), V3(-0.96, -0.40, 1.32), 0.06, p.pale, METAL, false)
			c:box(V3(0.26, 0.40, 0.14), CF(-0.96, -0.40, 1.38), p.light, METAL)
			c:rod(V3(-0.96, 0.10, -0.46), V3(-0.96, -0.24, 0.30), 0.05, BRASS, METAL, false)
			c:box(V3(0.14, 0.50, 0.14), CF(-0.96, 0.34, -0.50), BRASS, METAL)
			-- Lava glowing through the grate under the boiler.
			c:box(V3(1.60, 0.14, 1.30), CF(0, -0.88, -0.10), LAVA, NEON)
			c:sparkle(EMBER, 4, 0.6, 0.2)
			c:light(LAVA, 2.4, 12)
		end,
	}

	-- A cinderborn roc: the great bird of the ash wastes, wings spread and
	-- edged in fire, obsidian talons gripping a crag that is still cooling.
	S.ir_t_roc = {
		label = "Cinderborn Roc",
		set = SET,
		tint = C3(240, 90, 40),
		scale = 1.30,
		head = CF(0, 1.40, 0.20),
		neck = CF(0, -0.10, 0.90),
		back = CF(0, 0.50, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V3(1.60, 1.70, 1.50),
				eyeY = 0.34, eyeSpread = 0.32, eyeSize = V3(0.42, 0.50, 0.20), eyeColor = EMBER,
				mouth = false,
				bib = { w = 0.96, h = 0.80, y = -0.32, color = p.glow },
				legs = false, tail = false,
			})
			-- Hooked beak and a crest of flame.
			c:cone(V3(0.34, 0.44, 0.30), CF(0, 0.14, 0.88) * ANG(1.45, 0, 0), BRASS, METAL)
			c:cone(V3(0.22, 0.26, 0.20), CF(0, -0.08, 1.08) * ANG(1.9, 0, 0), BRASS, METAL)
			for i, z in ipairs({ 0.32, -0.04, -0.40 }) do
				c:cone(V3(0.22, 0.52 - i * 0.06, 0.34), CF(0, 1.02 - i * 0.02, z), i % 2 == 1 and LAVA or EMBER, NEON)
			end
			for _, s in ipairs(SIDES) do
				-- Wings: an inner arm, a long spread outer panel, fire on the edge.
				c:box(V3(0.80, 0.26, 1.10), CF(0.92 * s, 0.46, -0.20) * ANG(0, 0, 0.22 * s), p.dark)
				c:box(V3(1.00, 0.20, 1.30), CF(1.80 * s, 0.62, -0.34) * ANG(0, 0.14 * s, 0.14 * s), p.base)
				c:box(V3(1.04, 0.18, 0.26), CF(1.84 * s, 0.66, -1.00) * ANG(0, 0.14 * s, 0.14 * s), LAVA, NEON)
				c:box(V3(0.34, 0.20, 1.20), CF(2.26 * s, 0.70, -0.36) * ANG(0, 0.14 * s, 0.14 * s), EMBER, NEON)
				c:box(V3(0.24, 0.16, 0.50), CF(1.30 * s, 0.56, -0.86) * ANG(0, 0.14 * s, 0.14 * s), p.light)
				-- Legs and talons on the crag.
				c:rod(V3(0.34 * s, -0.78, 0.10), V3(0.40 * s, -1.14, 0.18), 0.11, p.deep, nil, false)
				c:box(V3(0.34, 0.14, 0.52), CF(0.40 * s, -1.20, 0.28), p.dark)
				for _, dx in ipairs({ -0.12, 0.12 }) do
					c:cone(V3(0.12, 0.26, 0.12), CF(0.40 * s + dx, -1.24, 0.54) * ANG(PI / 2, 0, 0), SOOT)
				end
				c:box(V3(0.22, 0.26, 0.90), CF(0.22 * s, -0.42, -1.00) * ANG(0.4, 0, 0), p.light)
			end
			c:box(V3(0.56, 0.24, 1.10), CF(0, -0.18, -1.00) * ANG(0.35, 0, 0), p.dark)
			c:box(V3(0.44, 0.18, 0.40), CF(0, 0.18, -1.66) * ANG(0.35, 0, 0), LAVA, NEON)
			-- The crag it has taken.
			c:box(V3(1.60, 0.40, 1.20), CF(0, -1.46, 0.10), p.deep, SLATE)
			c:box(V3(1.10, 0.26, 0.90), CF(0.10, -1.74, 0.06) * ANG(0, 0.3, 0), p.dark, SLATE)
			c:box(V3(0.14, 0.34, 0.90), CF(0.52, -1.44, 0.10), LAVA, NEON)
			c:sparkle(EMBER, 5, 0.7, 0.24)
			c:light(LAVA, 2.4, 12)
		end,
	}

	return S
end
