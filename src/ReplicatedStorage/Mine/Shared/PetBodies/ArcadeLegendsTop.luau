--[[ PetBodies/ArcadeLegendsTop -- Arcade Legends' top bodies. See tools/gen/sets/README.md.

	Epic and up: each body here is worn by exactly ONE pet in the game, so no
	two of them share a silhouette. The set is retro games, pixel art and neon,
	so every body is something you would find in a coin-op arcade: the machines
	(pinball, jukebox, coin pusher, rhythm pad), the hardware (joystick,
	cartridge, telly, handheld) and the sprites on the screen (maze spook, pixel
	invader, final boss, power-ups). Epic stays charming and clean; Legendary
	gets chrome and lights; Mythic, Divine and Exotic get neon glow, crowns,
	halos and floating pixels, echoing the top packs, "High Score" and "One More
	Life".
]]
return function(K)
	local C3 = K.C3
	local INK, WHITE, METAL, NEON, GLASS = K.INK, K.WHITE, K.METAL, K.NEON, K.GLASS
	local S = {}

	local SIDES = { -1, 1 }
	local FACE_Z = CFrame.Angles(0, math.pi / 2, 0) -- turns a cylinder's X axis to face +Z
	local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2) -- stands a cylinder's X axis up
	local DARK_KEY = C3(44, 44, 56)
	local SCREEN = C3(18, 22, 46)
	local PHOSPHOR = C3(110, 255, 160)
	local CHROME = C3(200, 204, 214)
	local GOLD = C3(255, 206, 84)
	local BLUSH = C3(255, 140, 170)
	local STEM = C3(70, 170, 60)
	local BTN = { C3(236, 52, 70), C3(255, 210, 60), C3(80, 210, 110), C3(70, 140, 255) }

	-- Two round eyes with glints, centred on `at` (a CFrame facing +Z).
	local function eyePair(c, at, spread, w, iris)
		for _, s in ipairs(SIDES) do
			c:round(Vector3.new(w, w * 1.3, 0.10), at * CFrame.new(spread * s, 0, 0), iris or INK):SetAttribute("Eye", true)
			c:round(Vector3.new(w * 0.38, w * 0.42, 0.06), at * CFrame.new(spread * s + w * 0.2, w * 0.3, 0.05), WHITE):SetAttribute("Eye", true)
		end
	end

	-- Eyes plus a small smile just in front of them (5 parts).
	local function faceAt(c, at, spread, w, iris)
		eyePair(c, at, spread, w, iris)
		c:box(Vector3.new(w * 1.1, 0.06, 0.05), at * CFrame.new(0, -w * 1.05, 0.02), INK)
	end
	local function face(c, y, z, spread, w, iris)
		faceAt(c, CFrame.new(0, y, z), spread, w, iris)
	end

	-- Rosy cheeks either side of a face.
	local function cheeks(c, x, y, z)
		for _, s in ipairs(SIDES) do
			c:box(Vector3.new(0.18, 0.10, 0.04), CFrame.new(x * s, y, z), BLUSH)
		end
	end

	-- A pixel-art face: two square eyes with a highlight pixel, and a stepped
	-- smile. `at` is the face's centre, facing +Z; `u` is one pixel (7 parts).
	local function pixelFace(c, at, u, spread, eyeCol)
		for _, s in ipairs(SIDES) do
			c:box(Vector3.new(u, u * 1.25, 0.06), at * CFrame.new(spread * s, u * 0.6, 0), eyeCol or INK):SetAttribute("Eye", true)
			c:box(Vector3.new(u * 0.4, u * 0.4, 0.04), at * CFrame.new(spread * s + u * 0.22, u * 0.95, 0.03), WHITE):SetAttribute("Eye", true)
			c:box(Vector3.new(u * 0.5, u * 0.5, 0.06), at * CFrame.new(u * 0.75 * s, -u * 0.7, 0), eyeCol or INK)
		end
		c:box(Vector3.new(u, u * 0.5, 0.06), at * CFrame.new(0, -u * 1.1, 0), eyeCol or INK)
	end

	-- A floating square halo of four neon bars (4 parts).
	local function halo(c, y, r, colour)
		c:box(Vector3.new(r * 2 + 0.10, 0.08, 0.10), CFrame.new(0, y, r), colour, NEON)
		c:box(Vector3.new(r * 2 + 0.10, 0.08, 0.10), CFrame.new(0, y, -r), colour, NEON)
		c:box(Vector3.new(0.10, 0.08, r * 2), CFrame.new(-r, y, 0), colour, NEON)
		c:box(Vector3.new(0.10, 0.08, r * 2), CFrame.new(r, y, 0), colour, NEON)
	end

	-- A pixel crown: a gold band, three square points and a lit gem (5 parts).
	local function crown(c, y, z, w, gem)
		c:box(Vector3.new(w, 0.16, w * 0.7), CFrame.new(0, y, z), GOLD, METAL)
		for _, x in ipairs({ -w * 0.38, 0, w * 0.38 }) do
			c:box(Vector3.new(w * 0.2, 0.22, w * 0.2), CFrame.new(x, y + 0.18, z), GOLD, METAL)
		end
		c:box(Vector3.new(0.12, 0.12, 0.06), CFrame.new(0, y, z + w * 0.35 + 0.02), gem, NEON)
	end

	-- Floating pixel bits: { x, y, z, size } rows.
	local function bits(c, list, colour, mat)
		for _, v in ipairs(list) do
			local s = v[4] or 0.14
			c:box(Vector3.new(s, s, s), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0.4, 0.6, 0), colour, mat)
		end
	end

	-- A flat slab from point a to point b.
	local function slab(c, a, b, w, t, colour, mat)
		return c:box(Vector3.new(w, t, (b - a).Magnitude), CFrame.lookAt((a + b) * 0.5, b), colour, mat)
	end

	-- ===================================================================
	-- EPIC: charming and clean.
	-- ===================================================================

	-- A joystick base with a face; the stick and its ball top make a topknot.
	S.al_t_joystick = {
		label = "Joystick Jumper",
		set = "arcade_legends",
		tint = C3(235, 35, 45),
		head = CFrame.new(0, 1.62, -0.10),
		neck = CFrame.new(0, -0.62, 0.90),
		back = CFrame.new(0, -0.30, -0.88),
		build = function(c, p)
			c:box(Vector3.new(1.90, 1.00, 1.70), CFrame.new(0, -0.40, 0), p.base)
			c:box(Vector3.new(1.70, 0.12, 1.50), CFrame.new(0, 0.16, 0), p.dark)
			c:box(Vector3.new(0.50, 0.14, 0.50), CFrame.new(0, 0.28, -0.10), INK)
			c:rod(Vector3.new(0, 0.30, -0.10), Vector3.new(0, 1.05, -0.10), 0.09, DARK_KEY, nil, false)
			c:ball(Vector3.new(0.72, 0.72, 0.72), CFrame.new(0, 1.24, -0.10), p.light)
			c:ball(Vector3.new(0.18, 0.18, 0.12), CFrame.new(-0.16, 1.42, 0.14), WHITE)
			for i, col in ipairs({ BTN[2], BTN[3], BTN[4] }) do
				c:cyl(Vector3.new(0.10, 0.22, 0.22), CFrame.new(0.58, 0.26, 0.42 - i * 0.26) * UPRIGHT, col)
			end
			face(c, -0.36, 0.87, 0.34, 0.26)
			cheeks(c, 0.62, -0.56, 0.86)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.04, 0.12, 1.40), CFrame.new(0.96 * s, -0.40, 0), p.glow, NEON)
				for _, z in ipairs({ 0.55, -0.55 }) do
					c:box(Vector3.new(0.36, 0.14, 0.36), CFrame.new(0.62 * s, -0.97, z), p.deep)
				end
			end
		end,
	}

	-- A game cartridge standing up: ridged grip, a sticker with a face, gold
	-- contacts for feet.
	S.al_t_cartridge = {
		label = "Cartridge Buddy",
		set = "arcade_legends",
		tint = C3(60, 100, 255),
		head = CFrame.new(0, 1.22, 0),
		neck = CFrame.new(0, -0.50, 0.42),
		back = CFrame.new(0, 0.10, -0.42),
		build = function(c, p)
			c:box(Vector3.new(1.80, 2.00, 0.70), CFrame.new(0, 0.10, 0), p.base)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.20, 0.30, 0.74), CFrame.new(0.82 * s, 0.96, 0), p.dark)
				c:box(Vector3.new(0.30, 0.20, 0.60), CFrame.new(0.78 * s, -1.00, 0.06), p.deep)
			end
			c:box(Vector3.new(1.20, 0.30, 0.50), CFrame.new(0, -1.05, 0), p.dark)
			c:box(Vector3.new(1.00, 0.14, 0.54), CFrame.new(0, -1.12, 0), GOLD, METAL)
			for i = 0, 3 do
				c:box(Vector3.new(1.30, 0.06, 0.06), CFrame.new(0, 1.00 - i * 0.12, 0.37), p.dark)
			end
			c:box(Vector3.new(1.44, 1.10, 0.04), CFrame.new(0, 0.05, 0.36), p.pale)
			c:box(Vector3.new(1.44, 0.14, 0.05), CFrame.new(0, 0.53, 0.37), p.glow, NEON)
			face(c, 0.08, 0.40, 0.32, 0.26)
			cheeks(c, 0.56, -0.12, 0.39)
			c:cyl(Vector3.new(0.06, 0.20, 0.20), CFrame.new(0, 0.30, -0.36) * FACE_Z, CHROME, METAL)
		end,
	}

	-- A pinball pop bumper: skirt, chrome kicker ring, lit cap and a star.
	S.al_t_bumper = {
		label = "Pop Bumper",
		set = "arcade_legends",
		tint = C3(0, 190, 255),
		head = CFrame.new(0, 1.12, 0),
		neck = CFrame.new(0, -0.40, 0.80),
		back = CFrame.new(0, -0.10, -0.80),
		build = function(c, p)
			c:cyl(Vector3.new(0.30, 2.00, 2.00), CFrame.new(0, -0.78, 0) * UPRIGHT, p.dark)
			c:cyl(Vector3.new(0.90, 1.50, 1.50), CFrame.new(0, -0.18, 0) * UPRIGHT, p.base)
			c:cyl(Vector3.new(0.08, 1.80, 1.80), CFrame.new(0, -0.58, 0) * UPRIGHT, CHROME, METAL)
			c:cyl(Vector3.new(0.10, 1.56, 1.56), CFrame.new(0, 0.30, 0) * UPRIGHT, p.glow, NEON)
			c:cyl(Vector3.new(0.34, 1.80, 1.80), CFrame.new(0, 0.50, 0) * UPRIGHT, p.light)
			c:ball(Vector3.new(1.40, 0.50, 1.40), CFrame.new(0, 0.70, 0), p.pale)
			c:star(Vector3.new(0, 1.00, 0), 0.40, p.glow)
			face(c, -0.12, 0.74, 0.30, 0.26)
			cheeks(c, 0.44, -0.34, 0.64)
			for _, v in ipairs({ { 0.6, 0.6 }, { -0.6, 0.6 }, { 0.6, -0.6 }, { -0.6, -0.6 } }) do
				c:cyl(Vector3.new(0.16, 0.26, 0.26), CFrame.new(v[1], -1.01, v[2]) * UPRIGHT, p.deep)
			end
		end,
	}

	-- A maze spook: stepped pixel dome, a wavy hem, big sideways eyes.
	S.al_t_spook = {
		label = "Maze Spook",
		set = "arcade_legends",
		tint = C3(255, 140, 210),
		head = CFrame.new(0, 1.42, 0),
		neck = CFrame.new(0, -0.30, 0.84),
		back = CFrame.new(0, 0.30, -0.84),
		build = function(c, p)
			c:box(Vector3.new(1.80, 1.40, 1.60), CFrame.new(0, 0.10, 0), p.base)
			c:box(Vector3.new(1.40, 0.36, 1.30), CFrame.new(0, 0.98, 0), p.base)
			c:box(Vector3.new(0.80, 0.20, 0.80), CFrame.new(0, 1.24, 0), p.base)
			for i, x in ipairs({ -0.675, -0.225, 0.225, 0.675 }) do
				local h = (i % 2 == 1) and 0.46 or 0.30
				c:box(Vector3.new(0.45, h, 1.60), CFrame.new(x, -0.60 - h * 0.5, 0), p.base)
			end
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.46, 0.56, 0.06), CFrame.new(0.36 * s, 0.36, 0.82), WHITE):SetAttribute("Eye", true)
				c:box(Vector3.new(0.24, 0.28, 0.06), CFrame.new(0.36 * s + 0.10, 0.30, 0.85), C3(40, 70, 220)):SetAttribute("Eye", true)
				c:box(Vector3.new(0.30, 0.30, 0.40), CFrame.new(1.02 * s, 0.00, 0.20), p.base)
			end
			for i, x in ipairs({ -0.24, -0.08, 0.08, 0.24 }) do
				c:box(Vector3.new(0.14, 0.06, 0.04), CFrame.new(x, -0.12 + (i % 2) * 0.06, 0.82), INK)
			end
			cheeks(c, 0.66, -0.06, 0.81)
			bits(c, { { -0.30, 0.20, -1.10, 0.16 }, { 0.30, -0.20, -1.30, 0.12 } }, p.glow, NEON)
		end,
	}

	-- A fat stack of folded prize tickets, the end of the strip curling up
	-- behind like a tail.
	S.al_t_tickets = {
		label = "Prize Tickets",
		set = "arcade_legends",
		tint = C3(255, 205, 30),
		head = CFrame.new(0, 0.62, 0.20),
		neck = CFrame.new(0, -0.50, 0.66),
		back = CFrame.new(0, 1.10, -0.60),
		build = function(c, p)
			c:box(Vector3.new(1.90, 1.40, 1.20), CFrame.new(0, -0.20, 0), p.base)
			for i = 0, 3 do
				c:box(Vector3.new(1.94, 0.05, 1.24), CFrame.new(0, -0.74 + i * 0.36, 0), p.dark)
			end
			for _, s in ipairs(SIDES) do
				c:cyl(Vector3.new(0.04, 0.22, 0.22), CFrame.new(0.96 * s, -0.20, 0), INK)
				c:box(Vector3.new(0.40, 0.18, 0.50), CFrame.new(0.55 * s, -0.99, 0.10), p.deep)
			end
			face(c, -0.10, 0.62, 0.34, 0.26)
			cheeks(c, 0.62, -0.30, 0.61)
			local pts = {
				Vector3.new(0, 0.48, -0.50), Vector3.new(0, 1.00, -0.25),
				Vector3.new(0, 1.35, -0.75), Vector3.new(0, 1.72, -0.45),
			}
			for i = 1, 3 do
				slab(c, pts[i], pts[i + 1], 1.50, 0.08, (i % 2 == 1) and p.light or p.base)
			end
			c:star(Vector3.new(0, 1.18, -0.48), 0.30, p.glow)
		end,
	}

	-- An arcade crane's claw: a hub with a face, three hinged chrome prongs and
	-- the prize it is holding.
	S.al_t_claw = {
		label = "Claw Grabber",
		set = "arcade_legends",
		tint = C3(120, 255, 70),
		head = CFrame.new(0, 1.66, 0),
		neck = CFrame.new(0, -0.20, 0.70),
		back = CFrame.new(0, 0.30, -0.70),
		build = function(c, p)
			c:box(Vector3.new(1.30, 0.90, 1.30), CFrame.new(0, 0.30, 0), p.base)
			c:cyl(Vector3.new(0.30, 0.90, 0.90), CFrame.new(0, 0.90, 0) * UPRIGHT, p.dark)
			c:box(Vector3.new(1.36, 0.10, 1.36), CFrame.new(0, -0.10, 0), p.glow, NEON)
			c:rod(Vector3.new(0, 1.05, 0), Vector3.new(0, 1.56, 0), 0.06, CHROME, METAL, false)
			c:box(Vector3.new(0.40, 0.14, 0.30), CFrame.new(0, 1.60, 0), DARK_KEY)
			face(c, 0.36, 0.67, 0.28, 0.24)
			for _, a in ipairs({ math.rad(55), math.rad(180), math.rad(305) }) do
				local d = Vector3.new(math.sin(a), 0, math.cos(a))
				local p1 = d * 0.60 + Vector3.new(0, -0.05, 0)
				local p2 = d * 1.05 + Vector3.new(0, -0.50, 0)
				local p3 = d * 0.55 + Vector3.new(0, -1.00, 0)
				c:rod(p1, p2, 0.08, CHROME, METAL, false)
				c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(p2), p.dark)
				c:rod(p2, p3, 0.07, CHROME, METAL, false)
				c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(p3), p.light)
			end
			c:ball(Vector3.new(0.60, 0.60, 0.60), CFrame.new(0, -0.80, 0), p.pale)
		end,
	}

	-- A squat old telly: a pixel face on the screen, knobs, rabbit-ear
	-- antennae with lit tips.
	S.al_t_telly = {
		label = "Bitscreen Telly",
		set = "arcade_legends",
		tint = C3(255, 150, 70),
		head = CFrame.new(0, 0.82, -0.20),
		neck = CFrame.new(0, -0.66, 0.80),
		back = CFrame.new(0, 0.00, -1.24),
		build = function(c, p)
			c:box(Vector3.new(2.00, 1.50, 1.50), CFrame.new(0, -0.05, 0), p.base)
			c:box(Vector3.new(1.40, 1.10, 0.50), CFrame.new(0, -0.05, -0.98), p.dark)
			c:box(Vector3.new(1.56, 1.04, 0.06), CFrame.new(0, 0.12, 0.76), p.deep)
			c:box(Vector3.new(1.36, 0.86, 0.06), CFrame.new(0, 0.12, 0.79), SCREEN)
			pixelFace(c, CFrame.new(0, 0.14, 0.83), 0.16, 0.30, PHOSPHOR)
			c:box(Vector3.new(0.50, 0.12, 0.40), CFrame.new(0, 0.76, -0.10), p.dark)
			for i = 0, 1 do
				c:box(Vector3.new(0.60, 0.05, 0.04), CFrame.new(0, -0.52 - i * 0.12, 0.76), p.dark)
			end
			for _, s in ipairs(SIDES) do
				c:cyl(Vector3.new(0.08, 0.20, 0.20), CFrame.new(0.66 * s, -0.56, 0.78) * FACE_Z, DARK_KEY)
				local tip = Vector3.new(0.72 * s, 1.50, -0.10)
				c:rod(Vector3.new(0.16 * s, 0.80, -0.10), tip, 0.04, CHROME, METAL, false)
				c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(tip), p.glow, NEON)
				for _, z in ipairs({ 0.50, -0.50 }) do
					c:box(Vector3.new(0.24, 0.24, 0.24), CFrame.new(0.72 * s, -0.90, z), p.deep)
				end
			end
		end,
	}

	-- A tall table-tennis paddle bar knocking a square pixel ball, with the
	-- dashed centre net beside it.
	S.al_t_paddle = {
		label = "Paddle Bopper",
		set = "arcade_legends",
		tint = C3(0, 255, 180),
		head = CFrame.new(0, 1.34, 0),
		neck = CFrame.new(0, -0.20, 0.38),
		back = CFrame.new(0, 0.20, -0.38),
		build = function(c, p)
			c:box(Vector3.new(0.70, 2.20, 0.70), CFrame.new(0, 0.10, 0), p.base)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.76, 0.16, 0.76), CFrame.new(0, 0.10 + 1.04 * s, 0), p.dark)
				c:box(Vector3.new(0.05, 1.80, 0.05), CFrame.new(0.31 * s, 0.10, 0.36), p.glow, NEON)
				c:box(Vector3.new(0.22, 0.20, 0.36), CFrame.new(0.20 * s, -1.12, 0.06), p.deep)
				c:rod(Vector3.new(0.36 * s, 0.00, 0), Vector3.new(0.62 * s, -0.30, 0.16), 0.06, p.dark, nil, false)
				c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.64 * s, -0.32, 0.18), p.pale)
			end
			face(c, 0.56, 0.37, 0.15, 0.17)
			c:box(Vector3.new(0.42, 0.42, 0.42), CFrame.new(1.20, 0.80, 0.10), p.pale)
			for i, sz in ipairs({ 0.26, 0.18, 0.12 }) do
				c:box(Vector3.new(sz, sz, sz), CFrame.new(1.20 - i * 0.20, 0.80 - i * 0.16, 0.10), p.light)
			end
			for i = 0, 3 do
				c:box(Vector3.new(0.08, 0.26, 0.08), CFrame.new(-1.00, -0.70 + i * 0.48, -0.10), p.glow, NEON)
			end
		end,
	}

	-- A falling-block T piece: four bevelled cubes, the face on the middle one.
	S.al_t_dropblock = {
		label = "Drop Block",
		set = "arcade_legends",
		tint = C3(160, 50, 255),
		head = CFrame.new(0, 0.90, 0),
		neck = CFrame.new(0, -0.60, 0.44),
		back = CFrame.new(0, 0.40, -0.44),
		build = function(c, p)
			local u = 0.80
			for _, v in ipairs({ { -1, 0.5 }, { 0, 0.5 }, { 1, 0.5 }, { 0, -0.5 } }) do
				local cf = CFrame.new(v[1] * u, v[2] * u, 0)
				c:box(Vector3.new(u, u, u), cf, p.base)
				c:box(Vector3.new(u * 0.70, u * 0.70, 0.04), cf * CFrame.new(0, 0, u * 0.5 + 0.01), p.light)
				c:box(Vector3.new(0.14, 0.14, 0.05), cf * CFrame.new(-u * 0.30, u * 0.30, u * 0.5 + 0.03), p.pale)
			end
			face(c, 0.36, 0.46, 0.20, 0.20)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.22, 0.24, 0.30), CFrame.new(0.20 * s, -0.92, 0.05), p.deep)
			end
			c:star(Vector3.new(1.25, 1.05, 0), 0.36, p.glow)
		end,
	}

	-- A two-tone power-up capsule lying down, with a lit plus sign above it.
	S.al_t_capsule = {
		label = "Power Capsule",
		set = "arcade_legends",
		tint = C3(255, 40, 120),
		scale = 1.15,
		head = CFrame.new(0, 0.80, 0),
		neck = CFrame.new(0, -0.40, 0.62),
		back = CFrame.new(0, 0.30, -0.60),
		build = function(c, p)
			c:cyl(Vector3.new(0.90, 1.20, 1.20), CFrame.new(-0.45, 0.10, 0), p.base)
			c:cyl(Vector3.new(0.90, 1.20, 1.20), CFrame.new(0.45, 0.10, 0), p.pale)
			c:ball(Vector3.new(1.20, 1.20, 1.20), CFrame.new(-0.90, 0.10, 0), p.base)
			c:ball(Vector3.new(1.20, 1.20, 1.20), CFrame.new(0.90, 0.10, 0), p.pale)
			c:cyl(Vector3.new(0.10, 1.26, 1.26), CFrame.new(0, 0.10, 0), p.dark)
			c:box(Vector3.new(1.10, 0.06, 0.12), CFrame.new(-0.30, 0.66, 0.24), WHITE)
			face(c, 0.12, 0.64, 0.30, 0.24)
			cheeks(c, 0.52, -0.06, 0.60)
			for _, v in ipairs({ { 0.62, 0.30 }, { -0.62, 0.30 }, { 0.62, -0.30 }, { -0.62, -0.30 } }) do
				c:box(Vector3.new(0.24, 0.20, 0.24), CFrame.new(v[1], -0.56, v[2]), p.deep)
			end
			c:box(Vector3.new(0.40, 0.12, 0.12), CFrame.new(0, 1.06, 0), p.glow, NEON)
			c:box(Vector3.new(0.12, 0.40, 0.12), CFrame.new(0, 1.06, 0), p.glow, NEON)
		end,
	}

	-- A pixel go-kart: headlight eyes on the nose, a seat, a wheel, a spoiler.
	S.al_t_kart = {
		label = "Pixel Kart",
		set = "arcade_legends",
		tint = C3(30, 190, 70),
		head = CFrame.new(0, 0.76, -0.20),
		neck = CFrame.new(0, -0.40, 1.12),
		back = CFrame.new(0, 1.02, -0.82),
		build = function(c, p)
			c:box(Vector3.new(1.60, 0.70, 1.50), CFrame.new(0, -0.25, -0.10), p.base)
			c:box(Vector3.new(1.40, 0.60, 0.50), CFrame.new(0, -0.30, 0.85), p.base)
			c:box(Vector3.new(1.44, 0.14, 0.54), CFrame.new(0, 0.04, 0.85), p.light)
			c:box(Vector3.new(1.00, 0.80, 0.20), CFrame.new(0, 0.40, -0.65), p.dark)
			c:rod(Vector3.new(0, 0.10, 0.45), Vector3.new(0, 0.50, 0.20), 0.05, DARK_KEY, nil, false)
			c:cyl(Vector3.new(0.08, 0.50, 0.50), CFrame.new(0, 0.54, 0.18) * CFrame.Angles(-0.5, 0, 0) * FACE_Z, INK)
			face(c, -0.28, 1.11, 0.36, 0.24)
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.62, -0.62 }) do
					c:cyl(Vector3.new(0.34, 0.62, 0.62), CFrame.new(0.92 * s, -0.52, z), DARK_KEY)
					c:cyl(Vector3.new(0.36, 0.26, 0.26), CFrame.new(0.92 * s, -0.52, z), CHROME, METAL)
				end
				c:box(Vector3.new(0.08, 0.80, 0.08), CFrame.new(0.40 * s, 0.50, -0.86), p.dark)
				c:box(Vector3.new(0.16, 0.16, 0.18), CFrame.new(0.40 * s, -0.30, -0.94), p.glow, NEON)
			end
			c:box(Vector3.new(1.80, 0.10, 0.40), CFrame.new(0, 0.95, -0.86), p.light)
		end,
	}

	-- A seven-segment "8" lit up on its display tile, eyes peeking through
	-- the top loop and a smile in the bottom one.
	S.al_t_digit = {
		label = "Neon Digit",
		set = "arcade_legends",
		tint = C3(200, 170, 255),
		head = CFrame.new(0, 1.42, -0.10),
		neck = CFrame.new(0, -0.50, 0.30),
		back = CFrame.new(0, 0.20, -0.40),
		build = function(c, p)
			c:box(Vector3.new(1.80, 2.50, 0.20), CFrame.new(0, 0.12, -0.20), SCREEN)
			c:box(Vector3.new(1.90, 2.60, 0.12), CFrame.new(0, 0.12, -0.32), p.deep)
			local segs = {
				{ 0, 1.12, true }, { 0, 0.12, true }, { 0, -0.88, true },
				{ -0.60, 0.62, false }, { 0.60, 0.62, false }, { -0.60, -0.38, false }, { 0.60, -0.38, false },
			}
			for _, v in ipairs(segs) do
				local across = v[3]
				c:box(across and Vector3.new(0.92, 0.26, 0.30) or Vector3.new(0.26, 0.80, 0.30), CFrame.new(v[1], v[2], 0), p.base)
				c:box(across and Vector3.new(0.70, 0.08, 0.04) or Vector3.new(0.08, 0.60, 0.04), CFrame.new(v[1], v[2], 0.16), p.glow, NEON)
			end
			eyePair(c, CFrame.new(0, 0.64, -0.06), 0.22, 0.22)
			c:box(Vector3.new(0.30, 0.07, 0.04), CFrame.new(0, -0.36, -0.08), INK)
			c:box(Vector3.new(0.20, 0.20, 0.30), CFrame.new(0.80, -1.00, 0), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.28, 0.30, 0.30), CFrame.new(0.40 * s, -1.32, -0.20), p.deep)
			end
		end,
	}

	-- Two bonus cherries holding hands at the stem, each with its own face.
	S.al_t_cherries = {
		label = "Bonus Cherries",
		set = "arcade_legends",
		tint = C3(190, 0, 40),
		head = CFrame.new(0.10, 1.20, -0.05),
		neck = CFrame.new(0, -0.70, 0.50),
		back = CFrame.new(0, -0.10, -0.50),
		build = function(c, p)
			for _, s in ipairs(SIDES) do
				local x = 0.56 * s
				c:box(Vector3.new(1.00, 0.76, 0.90), CFrame.new(x, -0.35, 0), p.base)
				c:box(Vector3.new(0.76, 1.00, 0.90), CFrame.new(x, -0.35, 0), p.base)
				c:box(Vector3.new(0.18, 0.18, 0.04), CFrame.new(x - 0.26, -0.05, 0.46), p.pale)
				faceAt(c, CFrame.new(x, -0.40, 0.47), 0.20, 0.18)
				c:rod(Vector3.new(x, 0.12, 0), Vector3.new(0.10, 1.00, -0.05), 0.05, STEM, nil, false)
			end
			c:box(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.10, 1.02, -0.05), p.deep)
			c:box(Vector3.new(0.60, 0.08, 0.34), CFrame.new(0.42, 1.10, -0.05) * CFrame.Angles(0, 0, 0.35), STEM)
		end,
	}

	-- A round pixel bomb with a lit fuse: cartoon, all sparkle and no bang.
	S.al_t_bomb = {
		label = "Bitbomb",
		set = "arcade_legends",
		tint = C3(40, 40, 120),
		head = CFrame.new(-0.20, 1.10, 0),
		neck = CFrame.new(0, -0.50, 0.92),
		back = CFrame.new(0, 0.10, -0.92),
		build = function(c, p)
			c:box(Vector3.new(1.90, 1.30, 1.60), CFrame.new(0, -0.05, 0), p.base)
			c:box(Vector3.new(1.30, 1.90, 1.60), CFrame.new(0, -0.05, 0), p.base)
			c:box(Vector3.new(1.40, 1.40, 1.80), CFrame.new(0, -0.05, 0), p.base)
			c:box(Vector3.new(0.24, 0.24, 0.04), CFrame.new(-0.46, 0.46, 0.91), p.pale)
			c:box(Vector3.new(0.14, 0.14, 0.04), CFrame.new(-0.26, 0.60, 0.91), p.pale)
			c:cyl(Vector3.new(0.26, 0.56, 0.56), CFrame.new(0.30, 0.98, 0) * UPRIGHT, p.dark)
			c:rod(Vector3.new(0.30, 1.10, 0), Vector3.new(0.55, 1.45, 0.05), 0.05, DARK_KEY, nil, false)
			c:star(Vector3.new(0.60, 1.55, 0.05), 0.42, C3(255, 200, 60))
			face(c, -0.12, 0.93, 0.34, 0.26)
			cheeks(c, 0.56, -0.32, 0.91)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.36, 0.18, 0.50), CFrame.new(0.42 * s, -1.02, 0.10), p.deep)
			end
		end,
	}

	-- A pixel mouse pointer: a stepped arrowhead with a dark outline, a tilted
	-- stem and a blinking text cursor beside it.
	S.al_t_cursor = {
		label = "Arrow Cursor",
		set = "arcade_legends",
		tint = C3(245, 245, 255),
		head = CFrame.new(-0.60, 1.62, 0),
		neck = CFrame.new(-0.10, -0.40, 0.40),
		back = CFrame.new(-0.10, 0.30, -0.40),
		build = function(c, p)
			local u, T, L, D = 0.27, 1.55, -0.80, 0.70
			for i = 0, 7 do
				local n = i < 7 and i + 1 or 4
				local cf = CFrame.new(L + n * u * 0.5, T - (i + 0.5) * u, 0)
				c:box(Vector3.new(n * u, u, D), cf, p.base)
				c:box(Vector3.new(n * u + 0.12, u + 0.12, D - 0.08), cf * CFrame.new(0, 0, -0.04), p.deep)
			end
			local stem = CFrame.new(L + 4.2 * u, T - 9.4 * u, 0) * CFrame.Angles(0, 0, 0.45)
			c:box(Vector3.new(0.50, 0.90, D), stem, p.base)
			c:box(Vector3.new(0.62, 1.00, D - 0.08), stem * CFrame.new(0, 0, -0.04), p.deep)
			faceAt(c, CFrame.new(-0.20, 0.30, D * 0.5 + 0.02), 0.20, 0.20)
			c:box(Vector3.new(0.12, 0.50, 0.12), CFrame.new(1.12, -0.60, 0), p.glow, NEON)
		end,
	}

	-- A quad roller skate from the rink by the arcade: light-up wheels, laces,
	-- a toe stop and a face on the toe cap.
	S.al_t_skate = {
		label = "Neon Skate",
		set = "arcade_legends",
		tint = C3(255, 70, 230),
		head = CFrame.new(0, 1.50, -0.50),
		neck = CFrame.new(0, -0.20, 1.00),
		back = CFrame.new(0, 0.80, -0.98),
		build = function(c, p)
			c:box(Vector3.new(1.00, 0.20, 2.00), CFrame.new(0, -0.55, 0), p.dark)
			c:box(Vector3.new(1.00, 0.70, 1.90), CFrame.new(0, -0.10, 0), p.base)
			c:box(Vector3.new(1.00, 1.10, 0.90), CFrame.new(0, 0.80, -0.50), p.base)
			c:box(Vector3.new(1.10, 0.16, 1.00), CFrame.new(0, 1.40, -0.50), p.light)
			c:box(Vector3.new(1.04, 0.40, 0.40), CFrame.new(0, -0.10, 0.78), p.light)
			c:cyl(Vector3.new(0.20, 0.40, 0.40), CFrame.new(0, -0.50, 1.06) * FACE_Z, p.deep)
			for i = 0, 2 do
				c:box(Vector3.new(0.70, 0.06, 0.04), CFrame.new(0, 0.50 + i * 0.26, -0.04) * CFrame.Angles(0, 0, (i % 2 == 0) and 0.3 or -0.3), WHITE)
			end
			face(c, -0.04, 0.99, 0.26, 0.20)
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.62, -0.62 }) do
					c:cyl(Vector3.new(0.30, 0.56, 0.56), CFrame.new(0.40 * s, -0.86, z), p.glow, NEON)
				end
				c:box(Vector3.new(0.04, 0.12, 1.20), CFrame.new(0.51 * s, 0.00, 0.10) * CFrame.Angles(0.3, 0, 0), p.glow, NEON)
			end
		end,
	}

	-- A stepped pixel fireball power-up with a curled tip and a trail of embers.
	S.al_t_fireball = {
		label = "Bit Fireball",
		set = "arcade_legends",
		tint = C3(255, 90, 20),
		head = CFrame.new(-0.12, 1.92, -0.20),
		neck = CFrame.new(0, -0.50, 0.84),
		back = CFrame.new(0, 0.30, -0.82),
		build = function(c, p)
			c:box(Vector3.new(1.80, 1.20, 1.60), CFrame.new(0, -0.30, 0), p.base)
			c:box(Vector3.new(1.40, 0.50, 1.30), CFrame.new(-0.05, 0.55, -0.05), p.base)
			c:box(Vector3.new(0.90, 0.45, 1.00), CFrame.new(-0.20, 1.02, -0.10), p.base)
			c:box(Vector3.new(0.45, 0.40, 0.70), CFrame.new(-0.40, 1.44, -0.15), p.base)
			c:box(Vector3.new(0.30, 0.30, 0.50), CFrame.new(-0.12, 1.75, -0.20), p.light)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.40, 0.60, 0.90), CFrame.new(1.05 * s, 0.10, -0.10), p.base)
				c:box(Vector3.new(0.26, 0.30, 0.60), CFrame.new(1.20 * s, 0.50, -0.15), p.light)
			end
			c:box(Vector3.new(1.10, 0.80, 0.04), CFrame.new(0, -0.40, 0.81), p.pale)
			c:box(Vector3.new(0.70, 0.36, 0.04), CFrame.new(-0.05, 0.50, 0.61), p.pale)
			face(c, -0.30, 0.85, 0.30, 0.24)
			cheeks(c, 0.66, -0.50, 0.81)
			bits(c, { { -0.40, -1.10, 0.10, 0.18 }, { 0.35, -1.20, 0, 0.14 }, { 0, -1.45, -0.10, 0.12 } }, p.glow, NEON)
			c:light(p.glow, 1.2, 6)
		end,
	}

	-- A platformer's jump booster: a bouncy pad with a face on a chrome coil.
	S.al_t_spring = {
		label = "Boing Booster",
		set = "arcade_legends",
		tint = C3(210, 255, 40),
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, 0.40, 0.84),
		back = CFrame.new(0, 0.70, -0.84),
		build = function(c, p)
			c:box(Vector3.new(1.80, 0.90, 1.60), CFrame.new(0, 0.75, 0), p.base)
			c:box(Vector3.new(1.90, 0.16, 1.70), CFrame.new(0, 0.25, 0), p.dark)
			face(c, 0.80, 0.82, 0.34, 0.26)
			cheeks(c, 0.62, 0.58, 0.81)
			local prev
			for i = 0, 6 do
				local a = i * math.pi * 2 / 3 + math.pi / 6
				local pt = Vector3.new(0.60 * math.cos(a), 0.17 - i * 0.16, 0.50 * math.sin(a))
				c:ball(Vector3.new(0.15, 0.15, 0.15), CFrame.new(pt), CHROME, METAL)
				if prev then
					c:rod(prev, pt, 0.07, CHROME, METAL, false)
				end
				prev = pt
			end
			c:box(Vector3.new(1.60, 0.16, 1.40), CFrame.new(0, -0.92, 0), p.dark)
			c:box(Vector3.new(1.64, 0.06, 1.44), CFrame.new(0, -0.82, 0), p.glow, NEON)
		end,
	}

	-- ===================================================================
	-- LEGENDARY: more ornate, chrome and lights.
	-- ===================================================================

	-- A pinball table on legs: a tilted playfield with bumpers, flippers and a
	-- chrome ball, and the backbox's glass for a face.
	S.al_t_pinball = {
		label = "Pinball Table",
		set = "arcade_legends",
		tint = C3(20, 80, 255),
		head = CFrame.new(0, 1.56, -1.10),
		neck = CFrame.new(0, -0.20, 1.30),
		back = CFrame.new(0, 0.80, -1.30),
		build = function(c, p)
			local tf = CFrame.new(0, -0.20, 0.15) * CFrame.Angles(0.20, 0, 0)
			c:box(Vector3.new(1.60, 0.36, 2.40), tf, p.base)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.10, 0.20, 2.40), tf * CFrame.new(0.80 * s, 0.24, 0), p.light)
				for _, z in ipairs({ 1.00, -0.90 }) do
					local top = (tf * CFrame.new(0.66 * s, -0.18, z)).Position
					c:rod(top, Vector3.new(0.70 * s, -1.05, top.Z), 0.07, p.dark, nil, false)
				end
				c:box(Vector3.new(0.50, 0.10, 0.14), tf * CFrame.new(0.30 * s, 0.22, 0.85) * CFrame.Angles(0, 0.45 * s, 0), WHITE)
			end
			for _, v in ipairs({ { -0.35, -0.30 }, { 0.35, -0.30 }, { 0, -0.70 } }) do
				c:cyl(Vector3.new(0.16, 0.34, 0.34), tf * CFrame.new(v[1], 0.26, v[2]) * UPRIGHT, p.glow, NEON)
			end
			for i = -1, 1 do
				c:box(Vector3.new(0.10, 0.04, 0.16), tf * CFrame.new(i * 0.24, 0.19, 0.20), p.pale)
			end
			c:ball(Vector3.new(0.24, 0.24, 0.24), tf * CFrame.new(0.20, 0.30, 0.40), CHROME, METAL)
			c:rod((tf * CFrame.new(0.62, 0.05, 1.20)).Position, (tf * CFrame.new(0.62, 0.05, 1.45)).Position, 0.04, CHROME, METAL, false)
			c:ball(Vector3.new(0.16, 0.16, 0.16), tf * CFrame.new(0.62, 0.05, 1.48), p.glow, NEON)
			c:box(Vector3.new(0.50, 0.22, 0.04), tf * CFrame.new(0, -0.02, 1.21), p.deep)
			-- The backbox: a neck, the cabinet, its glass with a face, the topper.
			c:box(Vector3.new(1.40, 0.30, 0.30), CFrame.new(0, 0.22, -1.10), p.deep)
			c:box(Vector3.new(1.60, 1.10, 0.36), CFrame.new(0, 0.86, -1.10), p.dark)
			c:box(Vector3.new(1.40, 0.86, 0.04), CFrame.new(0, 0.88, -0.91), SCREEN)
			pixelFace(c, CFrame.new(0, 0.90, -0.88), 0.15, 0.30, C3(255, 240, 120))
			c:box(Vector3.new(1.60, 0.14, 0.40), CFrame.new(0, 1.48, -1.10), p.glow, NEON)
		end,
	}

	-- A crab-shaped pixel invader built run by run, antennae lit, with round
	-- eyes in its two sockets and a pair of laser shots below.
	S.al_t_invader = {
		label = "Pixel Invader",
		set = "arcade_legends",
		tint = C3(80, 255, 90),
		scale = 1.15,
		head = CFrame.new(0, 1.16, 0),
		neck = CFrame.new(0, -0.30, 0.50),
		back = CFrame.new(0, 0.20, -0.66),
		build = function(c, p)
			local u, D = 0.26, 0.90
			-- Pixel runs, top down: { row, first column, last column, shade }.
			local runs = {
				{ 0, 2, 2, "glow" }, { 0, 8, 8, "glow" }, { 1, 3, 3 }, { 1, 7, 7 }, { 2, 2, 8 },
				{ 3, 1, 2 }, { 3, 4, 6 }, { 3, 8, 9 }, { 4, 0, 10 },
				{ 5, 0, 0 }, { 5, 2, 8 }, { 5, 10, 10 },
				{ 6, 0, 0, "dark" }, { 6, 2, 2, "dark" }, { 6, 8, 8, "dark" }, { 6, 10, 10, "dark" },
				{ 7, 3, 4, "dark" }, { 7, 6, 7, "dark" },
			}
			local function at(col, row)
				return Vector3.new((col - 5) * u, (3.5 - row) * u + 0.10, 0)
			end
			for _, r in ipairs(runs) do
				local n = r[3] - r[2] + 1
				local mid = (at(r[2], r[1]) + at(r[3], r[1])) * 0.5
				if r[4] == "glow" then
					c:box(Vector3.new(n * u, u, D), CFrame.new(mid), p.glow, NEON)
				else
					c:box(Vector3.new(n * u, u, D), CFrame.new(mid), r[4] == "dark" and p.dark or p.base)
				end
			end
			for _, col in ipairs({ 3, 7 }) do
				local e = at(col, 3)
				c:round(Vector3.new(0.30, 0.38, 0.10), CFrame.new(e.X, e.Y, D * 0.5 - 0.02), INK):SetAttribute("Eye", true)
				c:round(Vector3.new(0.11, 0.13, 0.06), CFrame.new(e.X + 0.06, e.Y + 0.08, D * 0.5 + 0.03), WHITE):SetAttribute("Eye", true)
			end
			c:box(Vector3.new(0.60, 0.07, 0.04), CFrame.new(at(5, 5).X, at(5, 5).Y, D * 0.5 + 0.02), INK)
			c:box(Vector3.new(9 * u, 4 * u, 0.30), CFrame.new(0, at(5, 3.5).Y, -D * 0.5 - 0.14), p.deep)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.08, 0.34, 0.08), CFrame.new(0.90 * s, -1.25, 0.20), p.glow, NEON)
			end
		end,
	}

	-- An 8-bit hero: plumed helmet, an open visor for the face, a belted tunic,
	-- a shield on one arm and a sword held high in the other.
	S.al_t_hero = {
		label = "Bitsword Hero",
		set = "arcade_legends",
		tint = C3(230, 50, 50),
		scale = 1.10,
		head = CFrame.new(0, 1.62, -0.10),
		neck = CFrame.new(0, -0.20, 0.70),
		back = CFrame.new(0, 0.30, -0.80),
		build = function(c, p)
			c:box(Vector3.new(1.50, 1.80, 1.30), CFrame.new(0, 0.05, 0), p.base)
			c:box(Vector3.new(1.60, 0.40, 1.40), CFrame.new(0, 1.15, 0), p.light, METAL)
			c:box(Vector3.new(1.10, 0.66, 0.04), CFrame.new(0, 0.46, 0.66), C3(255, 214, 170))
			face(c, 0.52, 0.69, 0.26, 0.22)
			cheeks(c, 0.42, 0.30, 0.68)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.20, 0.70, 0.30), CFrame.new(0.66 * s, 0.62, 0.56), p.light, METAL)
				c:box(Vector3.new(0.45, 0.30, 0.60), CFrame.new(0.38 * s, -1.00, 0.05), p.deep)
			end
			for i, v in ipairs({ { 1.45, 0.05 }, { 1.62, -0.25 }, { 1.50, -0.55 } }) do
				c:box(Vector3.new(0.22, 0.30 - i * 0.04, 0.34), CFrame.new(0, v[1], v[2]), p.glow)
			end
			c:box(Vector3.new(1.54, 0.16, 1.34), CFrame.new(0, -0.25, 0), p.dark)
			c:box(Vector3.new(0.24, 0.20, 0.04), CFrame.new(0, -0.25, 0.68), GOLD, METAL)
			-- Shield with a cross.
			c:box(Vector3.new(0.12, 0.90, 0.80), CFrame.new(-0.86, -0.05, 0.15), p.light, METAL)
			c:box(Vector3.new(0.04, 0.50, 0.12), CFrame.new(-0.93, -0.05, 0.15), GOLD, METAL)
			c:box(Vector3.new(0.04, 0.12, 0.40), CFrame.new(-0.93, 0.02, 0.15), GOLD, METAL)
			-- Sword arm and the sword raised.
			c:box(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0.86, -0.05, 0.28), p.base)
			c:box(Vector3.new(0.12, 0.36, 0.12), CFrame.new(0.97, 0.12, 0.30), p.deep)
			c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.97, -0.10, 0.30), p.glow, NEON)
			c:box(Vector3.new(0.50, 0.10, 0.14), CFrame.new(0.97, 0.34, 0.30), GOLD, METAL)
			c:box(Vector3.new(0.18, 1.20, 0.06), CFrame.new(0.97, 0.99, 0.30), CHROME, METAL)
			c:box(Vector3.new(0.04, 1.00, 0.02), CFrame.new(0.97, 0.99, 0.34), p.glow, NEON)
			c:cone(Vector3.new(0.18, 0.20, 0.06), CFrame.new(0.97, 1.69, 0.30), CHROME, METAL)
			-- Cape.
			c:box(Vector3.new(1.30, 1.50, 0.08), CFrame.new(0, 0.00, -0.70) * CFrame.Angles(0.08, 0, 0), p.dark)
		end,
	}

	-- A rhythm-game dance pad: four lit arrow panels, a safety rail and a
	-- screen on posts with a pixel face.
	S.al_t_dancepad = {
		label = "Rhythm Pad",
		set = "arcade_legends",
		tint = C3(255, 150, 220),
		head = CFrame.new(0, 1.66, -0.80),
		neck = CFrame.new(0, -0.60, 1.10),
		back = CFrame.new(0, 0.50, -1.00),
		build = function(c, p)
			c:box(Vector3.new(2.20, 0.30, 1.90), CFrame.new(0, -0.85, 0.15), p.dark)
			c:box(Vector3.new(2.28, 0.06, 1.98), CFrame.new(0, -0.98, 0.15), p.glow, NEON)
			c:box(Vector3.new(0.55, 0.06, 0.55), CFrame.new(0, -0.68, 0.15), p.light)
			for _, d in ipairs({ { 0, 1 }, { 0, -1 }, { -1, 0 }, { 1, 0 } }) do
				local pos = Vector3.new(d[1] * 0.62, -0.68, 0.15 + d[2] * 0.62)
				c:box(Vector3.new(0.55, 0.06, 0.55), CFrame.new(pos), p.base)
				local cf = CFrame.new(pos + Vector3.new(0, 0.04, 0)) * CFrame.Angles(0, math.atan2(d[1], d[2]), 0)
				c:box(Vector3.new(0.10, 0.03, 0.26), cf * CFrame.new(0, 0, -0.06), p.glow, NEON)
				c:box(Vector3.new(0.20, 0.03, 0.20), cf * CFrame.new(0, 0, 0.08) * CFrame.Angles(0, math.pi / 4, 0), p.glow, NEON)
			end
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.90 * s, -0.70, -0.68), Vector3.new(0.90 * s, 0.55, -0.76), 0.06, CHROME, METAL, false)
				c:box(Vector3.new(0.30, 0.36, 0.30), CFrame.new(0.90 * s, -0.30, -0.70), p.deep)
			end
			c:rod(Vector3.new(-0.90, 0.20, -0.74), Vector3.new(0.90, 0.20, -0.74), 0.05, p.light, nil, false)
			c:box(Vector3.new(1.70, 1.00, 0.30), CFrame.new(0, 1.00, -0.80), p.base)
			c:box(Vector3.new(1.46, 0.76, 0.04), CFrame.new(0, 1.00, -0.63), SCREEN)
			pixelFace(c, CFrame.new(0, 1.02, -0.60), 0.15, 0.30, PHOSPHOR)
			c:box(Vector3.new(1.70, 0.08, 0.08), CFrame.new(0, 1.53, -0.70), p.glow, NEON)
		end,
	}

	-- A basketball hoop game: a netted ramp, a backboard with a face, a lit
	-- square rim with its net, the ball and the score.
	S.al_t_hoop = {
		label = "Hoop Shot",
		set = "arcade_legends",
		tint = C3(255, 130, 20),
		scale = 1.10,
		head = CFrame.new(0, 1.92, -0.85),
		neck = CFrame.new(0, -0.50, 1.20),
		back = CFrame.new(0, 0.60, -1.10),
		build = function(c, p)
			local ramp = CFrame.new(0, -0.62, 0.30) * CFrame.Angles(0.12, 0, 0)
			c:box(Vector3.new(1.60, 0.30, 1.80), ramp, p.base)
			c:box(Vector3.new(1.40, 0.04, 1.60), ramp * CFrame.new(0, 0.16, 0), p.light)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.08, 0.60, 1.80), ramp * CFrame.new(0.80 * s, 0.40, 0), p.dark)
				c:box(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0.60 * s, -0.98, 0.90), p.deep)
			end
			c:box(Vector3.new(0.30, 1.00, 0.30), CFrame.new(0, -0.10, -0.75), p.dark)
			c:box(Vector3.new(1.80, 1.30, 0.08), CFrame.new(0, 0.95, -0.93), p.base)
			c:box(Vector3.new(1.70, 1.20, 0.12), CFrame.new(0, 0.95, -0.85), p.pale)
			face(c, 1.08, -0.77, 0.34, 0.24)
			cheeks(c, 0.62, 0.86, -0.78)
			-- The rim, its bracket and the net.
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.62, 0.06, 0.06), CFrame.new(0, 0.42, -0.45 + 0.28 * s), p.glow, NEON)
				c:box(Vector3.new(0.06, 0.06, 0.56), CFrame.new(0.28 * s, 0.42, -0.45), p.glow, NEON)
				for _, t in ipairs(SIDES) do
					c:rod(Vector3.new(0.28 * s, 0.40, -0.45 + 0.26 * t), Vector3.new(0.14 * s, 0.06, -0.45 + 0.13 * t), 0.025, WHITE, nil, false)
				end
			end
			c:box(Vector3.new(0.12, 0.06, 0.16), CFrame.new(0, 0.42, -0.74), p.dark)
			-- The ball on the ramp.
			c:ball(Vector3.new(0.48, 0.48, 0.48), CFrame.new(0.30, -0.24, 0.60), C3(255, 140, 40))
			c:box(Vector3.new(0.02, 0.49, 0.49), CFrame.new(0.30, -0.24, 0.60), INK)
			c:box(Vector3.new(0.49, 0.02, 0.49), CFrame.new(0.30, -0.24, 0.60), INK)
			-- Score display.
			c:box(Vector3.new(1.00, 0.30, 0.20), CFrame.new(0, 1.74, -0.85), p.dark)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.12, 0.20, 0.04), CFrame.new(0.15 * s, 1.74, -0.74), p.glow, NEON)
			end
		end,
	}

	-- A coin pusher: an open glass hood over stepped shelves heaped with gold
	-- coins, a pusher block, the face on its cabinet and a prize tray mouth.
	S.al_t_pusher = {
		label = "Coin Pusher",
		set = "arcade_legends",
		tint = C3(255, 215, 60),
		head = CFrame.new(0, 1.40, -0.20),
		neck = CFrame.new(0, -0.70, 0.86),
		back = CFrame.new(0, 0.00, -0.84),
		build = function(c, p)
			c:box(Vector3.new(2.00, 1.30, 1.60), CFrame.new(0, -0.45, 0), p.base)
			for _, x in ipairs({ -0.94, 0.94 }) do
				for _, z in ipairs({ 0.74, -0.74 }) do
					c:box(Vector3.new(0.12, 1.00, 0.12), CFrame.new(x, 0.70, z), p.dark)
				end
			end
			c:box(Vector3.new(2.00, 0.16, 1.60), CFrame.new(0, 1.26, 0), p.dark)
			c:box(Vector3.new(1.80, 0.22, 0.06), CFrame.new(0, 1.26, 0.82), p.glow, NEON)
			c:box(Vector3.new(1.76, 0.12, 1.40), CFrame.new(0, 0.26, 0), p.light)
			c:box(Vector3.new(1.76, 0.40, 0.70), CFrame.new(0, 0.46, -0.35), p.dark)
			c:box(Vector3.new(1.76, 0.10, 0.70), CFrame.new(0, 0.70, -0.35), p.light)
			for _, v in ipairs({
				{ -0.60, 0.35, 0.50 }, { -0.20, 0.35, 0.55 }, { 0.20, 0.35, 0.45 }, { 0.60, 0.35, 0.55 },
				{ 0, 0.35, 0.20 }, { -0.40, 0.42, 0.15 }, { -0.30, 0.78, -0.30 }, { 0.40, 0.78, -0.20 },
			}) do
				c:cyl(Vector3.new(0.06, 0.36, 0.36), CFrame.new(v[1], v[2], v[3]) * UPRIGHT, GOLD, METAL)
			end
			face(c, -0.40, 0.82, 0.36, 0.26)
			cheeks(c, 0.64, -0.60, 0.81)
			c:box(Vector3.new(1.00, 0.20, 0.20), CFrame.new(0, -0.86, 0.86), p.deep)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.06, 0.18, 0.04), CFrame.new(0.75 * s, 0.05, 0.81), GOLD, NEON)
			end
		end,
	}

	-- A strongman bell tower: a base with a face and a strike pad, a lit
	-- scale up the column, the puck, the gold bell and a mallet at its side.
	S.al_t_tester = {
		label = "Strength Tester",
		set = "arcade_legends",
		tint = C3(150, 60, 255),
		scale = 1.25,
		head = CFrame.new(0, 2.02, -0.40),
		neck = CFrame.new(0, -0.70, 0.74),
		back = CFrame.new(0, -0.40, -0.74),
		build = function(c, p)
			c:box(Vector3.new(1.80, 0.80, 1.40), CFrame.new(0, -0.60, 0), p.base)
			c:box(Vector3.new(1.86, 0.10, 1.46), CFrame.new(0, -0.22, 0), p.dark)
			face(c, -0.60, 0.72, 0.36, 0.24)
			cheeks(c, 0.66, -0.80, 0.71)
			c:cyl(Vector3.new(0.14, 0.56, 0.56), CFrame.new(0, -0.10, 0.35) * UPRIGHT, p.light)
			c:box(Vector3.new(0.44, 1.70, 0.30), CFrame.new(0, 0.65, -0.40), p.dark)
			for i = 0, 4 do
				c:box(Vector3.new(0.30, 0.10, 0.04), CFrame.new(0, 0.05 + i * 0.30, -0.24), p.glow, NEON)
			end
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.26 * s, -0.15, -0.40), Vector3.new(0.26 * s, 1.50, -0.40), 0.04, CHROME, METAL, false)
				c:box(Vector3.new(0.50, 0.12, 1.20), CFrame.new(0.60 * s, -1.06, 0), p.deep)
			end
			c:box(Vector3.new(0.60, 0.22, 0.40), CFrame.new(0, 0.95, -0.40), p.light)
			c:box(Vector3.new(0.80, 0.10, 0.10), CFrame.new(0, 1.52, -0.40), p.base)
			c:ball(Vector3.new(0.70, 0.56, 0.70), CFrame.new(0, 1.72, -0.40), GOLD, METAL)
			c:star(Vector3.new(0, 2.14, -0.40), 0.40, p.glow)
			c:rod(Vector3.new(1.05, -1.00, 0.20), Vector3.new(1.20, 0.40, 0.10), 0.06, p.deep, nil, false)
			c:cyl(Vector3.new(0.60, 0.40, 0.40), CFrame.new(1.21, 0.52, 0.10) * CFrame.Angles(0, 0, 0.1), p.pale)
		end,
	}

	-- A flip-open handheld: keys on the bottom half, a pixel face on the lid's
	-- screen, and its link cable trailing behind like a tail.
	S.al_t_handheld = {
		label = "Flip Handheld",
		set = "arcade_legends",
		tint = C3(150, 210, 40),
		head = CFrame.new(0, 1.12, -1.00),
		neck = CFrame.new(0, -0.60, 0.80),
		back = CFrame.new(0, 0.20, -1.16),
		build = function(c, p)
			c:box(Vector3.new(1.90, 0.30, 1.40), CFrame.new(0, -0.75, 0.05), p.base)
			c:cyl(Vector3.new(1.70, 0.34, 0.34), CFrame.new(0, -0.55, -0.70), p.dark)
			local lid = CFrame.new(0, 0.20, -0.86) * CFrame.Angles(-0.18, 0, 0)
			c:box(Vector3.new(1.90, 1.50, 0.26), lid, p.base)
			c:box(Vector3.new(1.60, 1.10, 0.04), lid * CFrame.new(0, 0.08, 0.14), p.dark)
			c:box(Vector3.new(1.36, 0.88, 0.04), lid * CFrame.new(0, 0.08, 0.16), SCREEN)
			pixelFace(c, lid * CFrame.new(0, 0.10, 0.19), 0.15, 0.30, PHOSPHOR)
			c:box(Vector3.new(0.10, 0.10, 0.04), lid * CFrame.new(0.70, -0.60, 0.14), p.glow, NEON)
			-- D-pad, A and B, start and select, a speaker grille.
			c:box(Vector3.new(0.46, 0.06, 0.15), CFrame.new(-0.52, -0.57, 0.20), DARK_KEY)
			c:box(Vector3.new(0.15, 0.06, 0.46), CFrame.new(-0.52, -0.57, 0.20), DARK_KEY)
			c:cyl(Vector3.new(0.06, 0.22, 0.22), CFrame.new(0.40, -0.57, 0.32) * UPRIGHT, BTN[1])
			c:cyl(Vector3.new(0.06, 0.22, 0.22), CFrame.new(0.66, -0.57, 0.10) * UPRIGHT, BTN[1])
			for _, x in ipairs({ -0.12, 0.12 }) do
				c:box(Vector3.new(0.16, 0.05, 0.06), CFrame.new(x, -0.58, 0.58), p.dark)
			end
			for i = 0, 2 do
				c:box(Vector3.new(0.26, 0.04, 0.04), CFrame.new(0.60, -0.59, 0.50 + i * 0.08), p.deep)
			end
			-- Link cable and plug.
			local bend = Vector3.new(1.30, -0.80, -0.70)
			c:rod(Vector3.new(0.95, -0.75, -0.30), bend, 0.05, DARK_KEY, nil, false)
			c:rod(bend, Vector3.new(1.15, -0.85, -1.10), 0.05, DARK_KEY, nil, false)
			c:box(Vector3.new(0.20, 0.16, 0.26), CFrame.new(1.12, -0.86, -1.22), p.light)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.40, 0.10, 0.40), CFrame.new(0.60 * s, -0.95, 0.30), p.deep)
			end
		end,
	}

	-- A home games console: a cartridge sticking out of its slot, a face on
	-- its front and two controllers lying at its feet on their cords.
	S.al_t_gamebox = {
		label = "Retro Gamebox",
		set = "arcade_legends",
		tint = C3(40, 210, 255),
		head = CFrame.new(0, 1.00, -0.20),
		neck = CFrame.new(0, -0.62, 0.86),
		back = CFrame.new(0, -0.30, -0.86),
		build = function(c, p)
			c:box(Vector3.new(2.20, 0.70, 1.60), CFrame.new(0, -0.55, 0), p.base)
			c:box(Vector3.new(2.00, 0.12, 1.40), CFrame.new(0, -0.14, 0), p.light)
			c:box(Vector3.new(1.20, 0.10, 0.36), CFrame.new(0, -0.04, -0.20), p.deep)
			c:box(Vector3.new(1.00, 0.90, 0.26), CFrame.new(0, 0.40, -0.20), p.dark)
			c:box(Vector3.new(0.76, 0.50, 0.04), CFrame.new(0, 0.40, -0.06), p.pale)
			c:box(Vector3.new(0.76, 0.08, 0.05), CFrame.new(0, 0.70, -0.06), p.glow, NEON)
			for i = 0, 2 do
				c:box(Vector3.new(0.40, 0.03, 0.06), CFrame.new(0.72, -0.065, 0.30 - i * 0.16), p.dark)
			end
			face(c, -0.52, 0.82, 0.40, 0.26)
			cheeks(c, 0.72, -0.72, 0.81)
			for _, x in ipairs({ -0.70, -0.42 }) do
				c:box(Vector3.new(0.22, 0.08, 0.18), CFrame.new(x, -0.04, 0.45), p.dark)
			end
			c:box(Vector3.new(0.08, 0.08, 0.04), CFrame.new(0.86, -0.36, 0.81), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				local pad = CFrame.new(0.78 * s, -0.84, 1.28) * CFrame.Angles(0, -0.30 * s, 0)
				c:box(Vector3.new(0.76, 0.14, 0.42), pad, p.dark)
				c:box(Vector3.new(0.20, 0.04, 0.07), pad * CFrame.new(-0.18, 0.08, 0), DARK_KEY)
				c:box(Vector3.new(0.07, 0.04, 0.20), pad * CFrame.new(-0.18, 0.08, 0), DARK_KEY)
				c:cyl(Vector3.new(0.04, 0.10, 0.10), pad * CFrame.new(0.18, 0.08, 0) * UPRIGHT, BTN[1])
				c:rod(Vector3.new(0.60 * s, -0.75, 0.80), (pad * CFrame.new(0, 0, -0.21)).Position, 0.035, DARK_KEY, nil, false)
			end
		end,
	}

	-- A synthwave motorbike: light-up wheels, headlight eyes on the cowl, a
	-- windscreen, chrome forks and exhausts, and a neon underglow.
	S.al_t_cycle = {
		label = "Synth Cycle",
		set = "arcade_legends",
		tint = C3(255, 0, 150),
		scale = 1.10,
		head = CFrame.new(0, 0.80, -0.30),
		neck = CFrame.new(0, 0.10, 1.12),
		back = CFrame.new(0, 0.60, -1.10),
		build = function(c, p)
			for _, z in ipairs({ 0.92, -0.92 }) do
				c:cyl(Vector3.new(0.30, 1.00, 1.00), CFrame.new(0, -0.48, z), DARK_KEY)
				c:cyl(Vector3.new(0.34, 0.56, 0.56), CFrame.new(0, -0.48, z), p.glow, NEON)
			end
			c:box(Vector3.new(0.70, 0.60, 1.60), CFrame.new(0, 0.05, -0.05), p.base)
			c:box(Vector3.new(0.90, 0.70, 0.40), CFrame.new(0, 0.30, 0.80), p.base)
			c:box(Vector3.new(0.80, 0.40, 0.08), CFrame.new(0, 0.80, 0.66) * CFrame.Angles(-0.4, 0, 0), p.pale)
			c:rod(Vector3.new(-0.60, 0.72, 0.52), Vector3.new(0.60, 0.72, 0.52), 0.04, CHROME, METAL, false)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.14, 0.14, 0.24), CFrame.new(0.66 * s, 0.72, 0.52), INK)
				c:rod(Vector3.new(0.20 * s, 0.10, 0.85), Vector3.new(0.20 * s, -0.48, 0.92), 0.05, CHROME, METAL, false)
				c:rod(Vector3.new(0.30 * s, -0.10, -0.60), Vector3.new(0.30 * s, -0.05, -1.25), 0.07, CHROME, METAL, false)
				c:box(Vector3.new(0.12, 0.12, 0.20), CFrame.new(0.30 * s, -0.05, -1.36), p.glow, NEON)
				c:box(Vector3.new(0.04, 0.10, 1.30), CFrame.new(0.36 * s, 0.05, -0.05), p.glow, NEON)
			end
			c:box(Vector3.new(0.60, 0.20, 0.70), CFrame.new(0, 0.45, -0.40), p.dark)
			c:box(Vector3.new(0.12, 0.40, 0.50), CFrame.new(0, 0.55, -0.85) * CFrame.Angles(-0.4, 0, 0), p.light)
			c:box(Vector3.new(0.50, 0.06, 1.40), CFrame.new(0, -0.28, 0), p.glow, NEON)
			face(c, 0.38, 1.01, 0.22, 0.20)
		end,
	}

	-- An 80s keytar worn on its strap: a keybed, knobs and a pitch wheel, a
	-- neck raised up-left, and notes floating off it.
	S.al_t_keytar = {
		label = "Neon Keytar",
		set = "arcade_legends",
		tint = C3(0, 255, 200),
		scale = 1.25,
		head = CFrame.new(0.10, 0.62, 0),
		neck = CFrame.new(0.20, -0.50, 0.34),
		back = CFrame.new(0, 0.30, -0.40),
		build = function(c, p)
			local body = CFrame.new(0.20, -0.10, 0) * CFrame.Angles(0, 0, -0.30)
			c:box(Vector3.new(2.20, 0.80, 0.50), body, p.base)
			c:box(Vector3.new(2.24, 0.06, 0.54), body * CFrame.new(0, -0.40, 0), p.glow, NEON)
			c:box(Vector3.new(1.50, 0.12, 0.34), body * CFrame.new(0.20, 0.44, 0.06), WHITE)
			for i = 0, 3 do
				c:box(Vector3.new(0.10, 0.08, 0.20), body * CFrame.new(-0.35 + i * 0.32, 0.52, 0), INK)
			end
			faceAt(c, body * CFrame.new(-0.05, -0.02, 0.27), 0.28, 0.22)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.18, 0.10, 0.04), body * CFrame.new(-0.05 + 0.50 * s, -0.20, 0.26), BLUSH)
			end
			local neck = body * CFrame.new(-1.45, 0.05, 0)
			c:box(Vector3.new(0.80, 0.26, 0.26), neck, p.dark)
			c:box(Vector3.new(0.70, 0.04, 0.04), neck * CFrame.new(0, 0.06, 0.14), p.glow, NEON)
			c:box(Vector3.new(0.34, 0.50, 0.30), body * CFrame.new(-1.95, 0.10, 0), p.light)
			for i = 0, 2 do
				c:cyl(Vector3.new(0.06, 0.14, 0.14), body * CFrame.new(0.70 + i * 0.16, 0.10, 0.25) * FACE_Z, DARK_KEY)
			end
			c:cyl(Vector3.new(0.10, 0.30, 0.30), body * CFrame.new(-0.80, 0.10, 0.25), DARK_KEY)
			local top = Vector3.new(0, 1.00, -0.40)
			c:rod((body * CFrame.new(-1.00, 0.30, -0.26)).Position, top, 0.05, p.deep, nil, false)
			c:rod(top, (body * CFrame.new(1.05, 0.30, -0.26)).Position, 0.05, p.deep, nil, false)
			for _, v in ipairs({ { 0.95, 0.90 }, { 1.30, 0.50 } }) do
				c:box(Vector3.new(0.18, 0.14, 0.10), CFrame.new(v[1], v[2], 0.10), p.glow, NEON)
				c:box(Vector3.new(0.05, 0.34, 0.05), CFrame.new(v[1] + 0.07, v[2] + 0.16, 0.10), p.glow, NEON)
			end
		end,
	}

	-- A brick-breaker wall: staggered bricks with one knocked out, the ball
	-- flying from the gap, and the lit paddle it stands on.
	S.al_t_brickwall = {
		label = "Brickbreak Wall",
		set = "arcade_legends",
		tint = C3(200, 90, 50),
		head = CFrame.new(-0.30, 0.84, 0),
		neck = CFrame.new(0, -0.50, 0.40),
		back = CFrame.new(0, 0.20, -0.40),
		build = function(c, p)
			local bh, D = 0.32, 0.70
			c:box(Vector3.new(1.90, 1.40, D - 0.10), CFrame.new(0, 0.12, -0.04), p.deep)
			local rows = { { 0.62, p.light, false }, { 0.28, p.base, true }, { -0.06, p.light, false }, { -0.40, p.base, true } }
			for r, row in ipairs(rows) do
				local xs = row[3] and { -0.80, -0.32, 0.32, 0.80 } or { -0.64, 0, 0.64 }
				for i, x in ipairs(xs) do
					if not (r == 1 and i == 3) then
						local w = (row[3] and (i == 1 or i == #xs)) and 0.30 or 0.60
						c:box(Vector3.new(w, bh - 0.02, D), CFrame.new(x, row[1], 0), row[2])
					end
				end
			end
			face(c, 0.00, 0.37, 0.30, 0.24)
			cheeks(c, 0.62, -0.22, 0.36)
			c:box(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0.85, 1.20, 0.30), p.pale)
			c:box(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0.72, 1.00, 0.30), p.light)
			c:box(Vector3.new(0.12, 0.12, 0.12), CFrame.new(0.62, 0.86, 0.30), p.light)
			c:box(Vector3.new(1.40, 0.16, 0.60), CFrame.new(0, -0.80, 0.05), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.24, 0.16, 0.30), CFrame.new(0.45 * s, -0.64, 0), p.dark)
			end
		end,
	}

	-- ===================================================================
	-- MYTHIC: spectacular -- neon, crowns, floating pixels.
	-- ===================================================================

	-- The last level's boss: a crowned, horned block with a cape, fists, a
	-- toothy grin and its health bar floating overhead.
	S.al_t_boss = {
		label = "Final Boss",
		set = "arcade_legends",
		tint = C3(130, 30, 200),
		scale = 1.10,
		head = CFrame.new(0, 1.22, 0),
		neck = CFrame.new(0, -0.40, 0.92),
		back = CFrame.new(0, 0.30, -1.00),
		build = function(c, p)
			c:box(Vector3.new(2.00, 1.70, 1.70), CFrame.new(0, -0.05, 0), p.base)
			c:box(Vector3.new(1.30, 0.80, 0.06), CFrame.new(0, -0.40, 0.86), p.light)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.30, 0.36, 0.30), CFrame.new(0.72 * s, 0.98, 0.10), p.pale)
				c:box(Vector3.new(0.22, 0.30, 0.22), CFrame.new(0.92 * s, 1.26, 0.10), p.pale)
				c:box(Vector3.new(0.40, 0.08, 0.05), CFrame.new(0.34 * s, 0.58, 0.87) * CFrame.Angles(0, 0, -0.30 * s), INK)
				c:cone(Vector3.new(0.12, 0.16, 0.05), CFrame.new(0.14 * s, -0.08, 0.88) * CFrame.Angles(math.pi, 0, 0), WHITE)
				c:box(Vector3.new(0.40, 0.44, 0.44), CFrame.new(1.18 * s, -0.30, 0.25), p.base)
				c:box(Vector3.new(0.42, 0.10, 0.46), CFrame.new(1.18 * s, -0.10, 0.25), p.dark)
				c:box(Vector3.new(0.60, 0.20, 0.70), CFrame.new(0.55 * s, -1.00, 0.10), p.deep)
			end
			eyePair(c, CFrame.new(0, 0.32, 0.87), 0.36, 0.28)
			c:box(Vector3.new(0.50, 0.08, 0.05), CFrame.new(0, 0.02, 0.88), INK)
			crown(c, 0.90, 0, 0.90, p.glow)
			c:box(Vector3.new(1.90, 1.60, 0.10), CFrame.new(0, -0.10, -0.92) * CFrame.Angles(-0.06, 0, 0), p.deep)
			c:box(Vector3.new(2.10, 0.20, 0.30), CFrame.new(0, 0.72, -0.80), p.dark)
			-- The boss's health bar, a little chipped.
			c:box(Vector3.new(1.80, 0.22, 0.12), CFrame.new(0, 1.70, 0), DARK_KEY)
			c:box(Vector3.new(1.20, 0.14, 0.14), CFrame.new(-0.27, 1.70, 0), p.glow, NEON)
			c:box(Vector3.new(0.40, 0.14, 0.14), CFrame.new(0.57, 1.70, 0), C3(236, 52, 70))
			bits(c, { { -1.20, 1.10, -0.30 }, { 1.25, 0.90, -0.40 }, { -1.10, 0.20, -0.70 } }, p.glow, NEON)
			c:light(p.glow, 1.6, 8)
		end,
	}

	-- A retro-future hoverboard: kicked-up nose with the face, grip deck,
	-- four glowing hover pads with thrust below, tail fins and speed lines.
	S.al_t_hoverboard = {
		label = "Turbo Hoverboard",
		set = "arcade_legends",
		tint = C3(0, 230, 255),
		scale = 1.20,
		head = CFrame.new(0, 0.26, -0.20),
		neck = CFrame.new(0, -0.10, 1.42),
		back = CFrame.new(0, 0.30, -1.42),
		build = function(c, p)
			c:box(Vector3.new(1.20, 0.30, 2.00), CFrame.new(0, 0, 0), p.base)
			local nose = CFrame.new(0, 0.15, 1.15) * CFrame.Angles(-0.25, 0, 0)
			c:box(Vector3.new(1.20, 0.60, 0.40), nose, p.light)
			faceAt(c, nose * CFrame.new(0, 0.08, 0.22), 0.28, 0.20)
			c:box(Vector3.new(1.10, 0.30, 0.50), CFrame.new(0, 0.12, -1.16) * CFrame.Angles(0.35, 0, 0), p.base)
			c:box(Vector3.new(1.00, 0.04, 1.60), CFrame.new(0, 0.17, 0), p.dark)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.04, 0.08, 1.90), CFrame.new(0.61 * s, 0, 0), p.glow, NEON)
				c:box(Vector3.new(0.06, 0.40, 0.40), CFrame.new(0.45 * s, 0.45, -1.15), p.light)
				c:box(Vector3.new(0.20, 0.10, 0.04), CFrame.new(0.30 * s, 0.20, -1.42), p.glow, NEON)
				for _, z in ipairs({ 0.65, -0.65 }) do
					c:cyl(Vector3.new(0.16, 0.50, 0.50), CFrame.new(0.40 * s, -0.25, z) * UPRIGHT, p.dark)
					c:cyl(Vector3.new(0.06, 0.42, 0.42), CFrame.new(0.40 * s, -0.35, z) * UPRIGHT, p.glow, NEON)
					c:cone(Vector3.new(0.34, 0.44, 0.34), CFrame.new(0.40 * s, -0.62, z) * CFrame.Angles(math.pi, 0, 0), p.glow, NEON)
				end
			end
			for _, x in ipairs({ -0.40, 0, 0.40 }) do
				c:box(Vector3.new(0.04, 0.04, 0.60), CFrame.new(x, 0.05 + math.abs(x) * 0.3, -1.70), p.pale, NEON)
			end
			c:light(p.glow, 1.5, 8)
		end,
	}

	-- A jukebox with a stepped neon arch, a window of spinning records,
	-- selector buttons, a grille with a face, and notes floating off it.
	S.al_t_jukebox = {
		label = "Neon Jukebox",
		set = "arcade_legends",
		tint = C3(255, 150, 0),
		head = CFrame.new(0, 1.42, 0),
		neck = CFrame.new(0, -0.70, 0.72),
		back = CFrame.new(0, 0.20, -0.70),
		build = function(c, p)
			c:box(Vector3.new(1.90, 1.60, 1.30), CFrame.new(0, -0.25, 0), p.base)
			c:box(Vector3.new(1.70, 0.30, 1.20), CFrame.new(0, 0.70, 0), p.base)
			c:box(Vector3.new(1.30, 0.26, 1.10), CFrame.new(0, 0.98, 0), p.base)
			c:box(Vector3.new(0.80, 0.20, 1.00), CFrame.new(0, 1.21, 0), p.base)
			-- The neon tube climbing the arch.
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.08, 1.00, 0.04), CFrame.new(0.88 * s, 0.05, 0.67), p.glow, NEON)
				c:box(Vector3.new(0.08, 0.30, 0.04), CFrame.new(0.78 * s, 0.70, 0.62), p.glow, NEON)
				c:box(Vector3.new(0.08, 0.26, 0.04), CFrame.new(0.58 * s, 0.98, 0.57), p.glow, NEON)
			end
			c:box(Vector3.new(0.80, 0.08, 0.04), CFrame.new(0, 1.30, 0.52), p.glow, NEON)
			-- Record window.
			c:box(Vector3.new(1.30, 0.62, 0.04), CFrame.new(0, 0.25, 0.66), p.deep)
			for i = -1, 1 do
				c:cyl(Vector3.new(0.04, 0.36, 0.36), CFrame.new(i * 0.38, 0.25, 0.69) * FACE_Z, INK)
				c:cyl(Vector3.new(0.05, 0.12, 0.12), CFrame.new(i * 0.38, 0.25, 0.70) * FACE_Z, p.light)
			end
			for i, col in ipairs(BTN) do
				c:box(Vector3.new(0.14, 0.10, 0.04), CFrame.new(-0.51 + i * 0.204, -0.08, 0.66), col)
			end
			-- Grille with the face.
			c:box(Vector3.new(1.40, 0.70, 0.04), CFrame.new(0, -0.55, 0.66), p.dark)
			face(c, -0.48, 0.70, 0.34, 0.24)
			cheeks(c, 0.58, -0.68, 0.69)
			c:box(Vector3.new(2.00, 0.14, 1.40), CFrame.new(0, -1.10, 0), p.deep)
			for _, v in ipairs({ { -1.25, 0.90 }, { 1.20, 1.25 }, { 1.30, 0.40 } }) do
				c:box(Vector3.new(0.18, 0.14, 0.10), CFrame.new(v[1], v[2], 0.10), p.glow, NEON)
				c:box(Vector3.new(0.05, 0.34, 0.05), CFrame.new(v[1] + 0.07, v[2] + 0.16, 0.10), p.glow, NEON)
			end
			c:light(p.glow, 1.6, 8)
		end,
	}

	-- A vector-graphics starfighter: a neon wireframe arrowhead with a solid
	-- cockpit cube for the face, twin thrusters and two shots ahead of it.
	S.al_t_vector = {
		label = "Vector Fighter",
		set = "arcade_legends",
		tint = C3(60, 255, 120),
		scale = 1.15,
		head = CFrame.new(0, 0.70, -0.05),
		neck = CFrame.new(0, -0.30, 0.60),
		back = CFrame.new(0, 0.30, -0.70),
		build = function(c, p)
			c:box(Vector3.new(0.90, 0.70, 0.90), CFrame.new(0, 0.10, 0), p.base)
			c:box(Vector3.new(0.60, 0.20, 0.50), CFrame.new(0, 0.55, -0.05), p.pale)
			face(c, 0.12, 0.47, 0.20, 0.18)
			cheeks(c, 0.32, -0.04, 0.46)
			local V = {
				N = Vector3.new(0, 0.10, 1.30), L = Vector3.new(-1.30, -0.10, -0.80), R = Vector3.new(1.30, -0.10, -0.80),
				T = Vector3.new(0, 0.80, -0.55), B = Vector3.new(0, -0.45, -0.55),
			}
			for _, e in ipairs({ { "N", "L" }, { "N", "R" }, { "L", "T" }, { "R", "T" }, { "L", "B" }, { "R", "B" }, { "T", "B" }, { "L", "R" } }) do
				c:rod(V[e[1]], V[e[2]], 0.04, p.glow, NEON, false)
			end
			for _, k in ipairs({ "N", "L", "R", "T", "B" }) do
				c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(V[k]), p.light, NEON)
			end
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.45 * s, 0.00, -0.20), V[s < 0 and "L" or "R"], 0.06, p.deep, nil, false)
				c:box(Vector3.new(0.30, 0.30, 0.40), CFrame.new(0.40 * s, -0.05, -0.60), p.dark)
				c:cone(Vector3.new(0.24, 0.40, 0.24), CFrame.new(0.40 * s, -0.05, -0.98) * CFrame.Angles(-math.pi / 2, 0, 0), p.glow, NEON)
				c:box(Vector3.new(0.08, 0.08, 0.30), CFrame.new(0.25 * s, 0.10, 1.65), p.pale, NEON)
			end
			c:light(p.glow, 1.4, 7)
		end,
	}

	-- A plasma globe: lightning arcs crawling over a glass ball on a stepped
	-- base, a gold equator ring and sparks jumping off.
	S.al_t_plasma = {
		label = "Plasma Sphere",
		set = "arcade_legends",
		tint = C3(255, 60, 255),
		head = CFrame.new(0, 1.66, 0),
		neck = CFrame.new(0, -0.60, 0.72),
		back = CFrame.new(0, 0.40, -1.00),
		build = function(c, p)
			c:box(Vector3.new(1.40, 0.36, 1.40), CFrame.new(0, -0.88, 0), p.dark)
			c:box(Vector3.new(1.00, 0.30, 1.00), CFrame.new(0, -0.56, 0), p.base)
			for _, s in ipairs(SIDES) do
				c:cyl(Vector3.new(0.06, 0.16, 0.16), CFrame.new(0.40 * s, -0.88, 0.71) * FACE_Z, p.glow, NEON)
				for _, z in ipairs({ 0.50, -0.50 }) do
					c:box(Vector3.new(0.24, 0.12, 0.24), CFrame.new(0.50 * s, -1.12, z), p.deep)
				end
			end
			local C = Vector3.new(0, 0.48, 0)
			c:ball(Vector3.new(1.90, 1.90, 1.90), CFrame.new(C), p.base, GLASS)
			c:cyl(Vector3.new(0.06, 2.04, 2.04), CFrame.new(C) * UPRIGHT, GOLD, METAL)
			local function sph(x, y, z)
				return C + Vector3.new(x, y, z).Unit * 1.06
			end
			local top = C + Vector3.new(0, 1.06, 0)
			for _, arc in ipairs({
				{ sph(-0.5, 0.8, 0.25), sph(-0.95, 0.15, 0.1) },
				{ sph(0.5, 0.8, 0.2), sph(0.95, 0.25, -0.05) },
				{ sph(0.1, 0.7, -0.7), sph(-0.2, 0.0, -1.0) },
			}) do
				c:rod(top, arc[1], 0.035, p.glow, NEON, false)
				c:rod(arc[1], arc[2], 0.035, p.glow, NEON, false)
			end
			c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(top), p.glow, NEON)
			eyePair(c, CFrame.new(0, 0.62, 0.90), 0.32, 0.26)
			c:box(Vector3.new(0.30, 0.06, 0.05), CFrame.new(0, 0.30, 0.955), INK)
			cheeks(c, 0.50, 0.38, 0.82)
			bits(c, { { 1.25, 0.90, 0.20 }, { -1.25, 0.95, 0.10 }, { 1.10, 0.10, -0.30 }, { -1.10, 0.05, -0.30 } }, p.glow, NEON)
			c:light(p.glow, 2, 9)
		end,
	}

	-- The winners' podium: three steps with gold trim, a pixel "1", silver and
	-- bronze stars, laurels round the face and a crown hovering over the top.
	S.al_t_podium = {
		label = "Victory Podium",
		set = "arcade_legends",
		tint = C3(255, 210, 0),
		head = CFrame.new(0, 1.00, 0),
		neck = CFrame.new(0, -0.40, 0.62),
		back = CFrame.new(0, -0.20, -0.62),
		build = function(c, p)
			c:box(Vector3.new(0.90, 1.30, 1.20), CFrame.new(0, -0.35, 0), p.base)
			c:box(Vector3.new(0.80, 0.90, 1.10), CFrame.new(-0.85, -0.55, 0), p.light)
			c:box(Vector3.new(0.80, 0.60, 1.10), CFrame.new(0.85, -0.70, 0), p.dark)
			c:box(Vector3.new(0.94, 0.08, 1.24), CFrame.new(0, 0.30, 0), GOLD, METAL)
			c:box(Vector3.new(0.84, 0.08, 1.14), CFrame.new(-0.85, -0.10, 0), GOLD, METAL)
			c:box(Vector3.new(0.84, 0.08, 1.14), CFrame.new(0.85, -0.40, 0), GOLD, METAL)
			c:box(Vector3.new(0.10, 0.36, 0.04), CFrame.new(0, -0.66, 0.61), GOLD, NEON)
			c:box(Vector3.new(0.14, 0.08, 0.04), CFrame.new(-0.07, -0.52, 0.61), GOLD, NEON)
			c:star(Vector3.new(-0.85, -0.62, 0.57), 0.30, CHROME)
			c:star(Vector3.new(0.85, -0.76, 0.57), 0.26, C3(205, 127, 50))
			face(c, -0.10, 0.62, 0.22, 0.20)
			cheeks(c, 0.34, -0.28, 0.61)
			crown(c, 0.62, 0, 0.80, p.glow)
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.40 * s, -0.45, 0.62), Vector3.new(0.36 * s, 0.12, 0.62), 0.03, STEM, nil, false)
				for _, y in ipairs({ -0.25, 0.00 }) do
					c:box(Vector3.new(0.14, 0.06, 0.04), CFrame.new(0.34 * s, y, 0.63) * CFrame.Angles(0, 0, 0.6 * s), STEM)
				end
			end
			for i, v in ipairs({ { -1.10, 0.70, 0.20 }, { 1.05, 0.40, 0.30 }, { -0.60, 1.20, -0.10 }, { 0.70, 1.10, 0.10 }, { -1.20, 0.10, -0.20 }, { 0.30, 1.35, -0.30 } }) do
				bits(c, { { v[1], v[2], v[3], 0.12 } }, BTN[(i - 1) % #BTN + 1], NEON)
			end
			c:light(p.glow, 1.4, 7)
		end,
	}

	-- ===================================================================
	-- DIVINE: radiant -- halos, wings, beams of light.
	-- ===================================================================

	-- A save point: a floating diamond crystal over a glowing rune pad, sparks
	-- circling it and a halo above.
	S.al_t_savepoint = {
		label = "Save Point",
		set = "arcade_legends",
		tint = C3(120, 220, 255),
		head = CFrame.new(0, 1.82, 0),
		neck = CFrame.new(0, -0.30, 0.70),
		back = CFrame.new(0, 0.30, -0.70),
		build = function(c, p)
			c:box(Vector3.new(1.30, 0.60, 1.30), CFrame.new(0, 0.25, 0), p.light)
			c:cone(Vector3.new(1.30, 0.90, 1.30), CFrame.new(0, 1.00, 0), p.base)
			c:cone(Vector3.new(1.30, 0.90, 1.30), CFrame.new(0, -0.50, 0) * CFrame.Angles(math.pi, 0, 0), p.base)
			for _, y in ipairs({ 0.57, -0.07 }) do
				c:box(Vector3.new(1.36, 0.06, 1.36), CFrame.new(0, y, 0), p.pale)
			end
			face(c, 0.30, 0.67, 0.28, 0.22)
			cheeks(c, 0.50, 0.14, 0.66)
			c:cyl(Vector3.new(0.12, 2.00, 2.00), CFrame.new(0, -1.15, 0) * UPRIGHT, p.dark)
			c:cyl(Vector3.new(0.06, 2.20, 2.20), CFrame.new(0, -1.15, 0) * UPRIGHT, p.glow, NEON)
			for i = 0, 3 do
				local a = i * math.pi / 2 + math.pi / 4
				c:box(Vector3.new(0.20, 0.04, 0.20), CFrame.new(0.65 * math.cos(a), -1.08, 0.65 * math.sin(a)) * CFrame.Angles(0, a, 0), p.glow, NEON)
			end
			for i = 0, 5 do
				local a = i * math.pi / 3
				bits(c, { { 1.10 * math.cos(a), 0.25 + 0.35 * math.sin(a * 2), 1.10 * math.sin(a), 0.14 } }, p.glow, NEON)
			end
			halo(c, 1.70, 0.40, p.glow)
			c:sparkle(p.glow, 4, 1, 0.3)
			c:light(p.glow, 1.6, 8)
		end,
	}

	-- A synthwave sunset: a striped sun with a face sinking onto a neon grid,
	-- two palm silhouettes and a few stars.
	S.al_t_sunset = {
		label = "Sunset Grid",
		set = "arcade_legends",
		tint = C3(255, 90, 140),
		head = CFrame.new(0, 1.62, -0.25),
		neck = CFrame.new(0, -0.45, 1.00),
		back = CFrame.new(0, 0.40, -0.62),
		build = function(c, p)
			local sun = CFrame.new(0, 0.50, -0.25)
			c:cyl(Vector3.new(0.40, 2.00, 2.00), sun * FACE_Z, p.base)
			c:cyl(Vector3.new(0.10, 2.24, 2.24), sun * CFrame.new(0, 0, -0.18) * FACE_Z, p.glow, NEON)
			for i, y in ipairs({ -0.20, -0.45, -0.68 }) do
				local w = 2 * math.sqrt(1 - y * y) * 0.98
				c:box(Vector3.new(w, 0.06 + i * 0.02, 0.04), CFrame.new(0, 0.50 + y, -0.03), p.deep)
			end
			eyePair(c, CFrame.new(0, 0.80, -0.02), 0.34, 0.26)
			c:box(Vector3.new(0.30, 0.06, 0.05), CFrame.new(0, 0.50, -0.01), INK)
			cheeks(c, 0.58, 0.58, -0.02)
			c:box(Vector3.new(2.60, 0.10, 2.00), CFrame.new(0, -0.55, 0.20), p.dark)
			for _, z in ipairs({ 1.10, 0.60, 0.15 }) do
				c:box(Vector3.new(2.60, 0.03, 0.04), CFrame.new(0, -0.49, z), p.glow, NEON)
			end
			for _, x in ipairs({ -0.90, -0.30, 0.30, 0.90 }) do
				c:box(Vector3.new(0.04, 0.03, 2.00), CFrame.new(x, -0.49, 0.20), p.glow, NEON)
			end
			for _, s in ipairs(SIDES) do
				local crownAt = Vector3.new(1.00 * s, 0.58, 0.45)
				c:rod(Vector3.new(1.10 * s, -0.50, 0.50), crownAt, 0.05, p.deep, nil, false)
				for _, yaw in ipairs({ 0, 2.1, 4.2 }) do
					c:box(Vector3.new(0.70, 0.05, 0.18), CFrame.new(crownAt) * CFrame.Angles(0, yaw, 0) * CFrame.new(0.30, 0, 0) * CFrame.Angles(0, 0, -0.35), p.dark)
				end
			end
			bits(c, { { -1.00, 1.40, -0.40, 0.10 }, { 1.05, 1.30, -0.40, 0.12 }, { 0.50, 1.75, -0.50, 0.10 } }, p.pale, NEON)
			c:light(p.glow, 1.6, 8)
		end,
	}

	-- A floating arcade marquee: chase bulbs round a framed sign with a face,
	-- a star on top, chains, pixel wings and an arrow pointing to the coin slot.
	S.al_t_marquee = {
		label = "Neon Marquee",
		set = "arcade_legends",
		tint = C3(255, 240, 120),
		scale = 1.25,
		head = CFrame.new(0, 1.62, 0),
		neck = CFrame.new(0, -0.80, 0.30),
		back = CFrame.new(0, 0.20, -0.30),
		build = function(c, p)
			c:box(Vector3.new(2.20, 1.30, 0.30), CFrame.new(0, 0.10, 0), p.base)
			c:box(Vector3.new(2.40, 0.14, 0.40), CFrame.new(0, 0.82, 0), p.dark)
			c:box(Vector3.new(2.40, 0.14, 0.40), CFrame.new(0, -0.62, 0), p.dark)
			c:box(Vector3.new(0.14, 1.30, 0.40), CFrame.new(-1.13, 0.10, 0), p.dark)
			c:box(Vector3.new(0.14, 1.30, 0.40), CFrame.new(1.13, 0.10, 0), p.dark)
			for i = 0, 4 do
				local x = -0.88 + i * 0.44
				c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(x, 0.82, 0.22), p.glow, NEON)
				c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(x, -0.62, 0.22), p.glow, NEON)
			end
			face(c, 0.20, 0.17, 0.40, 0.30)
			cheeks(c, 0.72, -0.05, 0.16)
			c:star(Vector3.new(0, 1.30, 0), 0.60, p.glow)
			c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(0, 1.30, 0), GOLD, NEON)
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.90 * s, 0.89, 0), Vector3.new(0.60 * s, 1.55, 0), 0.03, CHROME, METAL, false)
				for i = 0, 2 do
					local w = 0.50 - i * 0.12
					c:box(Vector3.new(w, 0.16, 0.12), CFrame.new((1.20 + w * 0.5) * s, 0.40 - i * 0.18, -0.05), p.pale)
				end
			end
			c:box(Vector3.new(0.14, 0.30, 0.10), CFrame.new(0, -0.90, 0.05), p.glow, NEON)
			c:box(Vector3.new(0.26, 0.26, 0.10), CFrame.new(0, -1.08, 0.05) * CFrame.Angles(0, 0, math.pi / 4), p.glow, NEON)
			c:light(p.glow, 1.6, 8)
		end,
	}

	-- The legendary sword in a pixel stone: a stepped boulder with a face and
	-- glowing runes, the sword's hilt shining with rays and motes.
	S.al_t_swordstone = {
		label = "Legend Swordstone",
		set = "arcade_legends",
		tint = C3(110, 140, 255),
		scale = 1.25,
		head = CFrame.new(-0.50, 0.70, -0.20),
		neck = CFrame.new(0, -0.60, 0.84),
		back = CFrame.new(0, -0.20, -0.84),
		build = function(c, p)
			c:box(Vector3.new(2.00, 1.00, 1.60), CFrame.new(0, -0.50, 0), p.base)
			c:box(Vector3.new(1.50, 0.60, 1.20), CFrame.new(0.05, 0.25, -0.05), p.base)
			c:box(Vector3.new(0.90, 0.30, 0.80), CFrame.new(-0.05, 0.68, -0.10), p.base)
			c:box(Vector3.new(0.40, 0.10, 0.04), CFrame.new(-0.60, -0.10, 0.81), p.light)
			c:box(Vector3.new(0.30, 0.10, 0.04), CFrame.new(0.50, 0.38, 0.56), p.light)
			face(c, -0.42, 0.82, 0.36, 0.26)
			cheeks(c, 0.66, -0.62, 0.81)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.12, 0.24, 0.04), CFrame.new(0.82 * s, -0.25, 0.81), p.glow, NEON)
				c:box(Vector3.new(0.40, 0.16, 0.40), CFrame.new(0.60 * s, -1.06, 0.20), p.dark)
			end
			c:box(Vector3.new(0.24, 0.90, 0.08), CFrame.new(0, 1.20, 0), CHROME, METAL)
			c:box(Vector3.new(0.06, 0.70, 0.02), CFrame.new(0, 1.22, 0.05), p.glow, NEON)
			c:box(Vector3.new(0.80, 0.14, 0.20), CFrame.new(0, 1.72, 0), GOLD, METAL)
			c:box(Vector3.new(0.14, 0.14, 0.06), CFrame.new(0, 1.72, 0.12), p.glow, NEON)
			c:box(Vector3.new(0.14, 0.36, 0.14), CFrame.new(0, 1.97, 0), p.deep)
			c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(0, 2.22, 0), p.glow, NEON)
			for i = 0, 3 do
				local a = i * math.pi / 2 + math.pi / 4
				c:box(Vector3.new(0.06, 0.50, 0.06), CFrame.new(0, 1.72, -0.05) * CFrame.Angles(0, 0, a) * CFrame.new(0, 0.55, 0), p.glow, NEON)
			end
			bits(c, { { -1.10, 1.20, 0.20 }, { 1.05, 1.50, -0.10 }, { -0.80, 1.90, -0.20 }, { 0.90, 0.80, 0.30 } }, p.pale, NEON)
			c:light(p.glow, 1.6, 8)
		end,
	}

	-- A pixel firework mid-burst: a bright core with a face, eight stepped
	-- streaks flying out, sparkles between them and the rocket's trail below.
	S.al_t_firework = {
		label = "Pixel Firework",
		set = "arcade_legends",
		tint = C3(255, 60, 40),
		scale = 1.15,
		head = CFrame.new(0, 1.02, -0.10),
		neck = CFrame.new(0, -0.40, 0.60),
		back = CFrame.new(0, 0.30, -0.60),
		build = function(c, p)
			local core = Vector3.new(0, 0.30, 0)
			c:box(Vector3.new(1.10, 1.10, 1.10), CFrame.new(core), p.base)
			c:box(Vector3.new(0.90, 0.90, 0.04), CFrame.new(core + Vector3.new(0, 0, 0.56)), p.light)
			face(c, 0.36, 0.60, 0.22, 0.20)
			cheeks(c, 0.36, 0.14, 0.59)
			for i = 0, 7 do
				local a = i * math.pi / 4
				local d = Vector3.new(math.cos(a), math.sin(a), 0)
				local rot = CFrame.Angles(0, 0, a)
				c:box(Vector3.new(0.34, 0.20, 0.20), CFrame.new(core + d * 0.85) * rot, p.light)
				c:box(Vector3.new(0.20, 0.16, 0.16), CFrame.new(core + d * 1.20) * rot, p.glow, NEON)
			end
			for i = 0, 3 do
				local a = i * math.pi / 2 + math.pi / 8
				bits(c, { { 1.40 * math.cos(a), 0.30 + 1.40 * math.sin(a), -0.10, 0.12 } }, p.pale, NEON)
			end
			bits(c, { { 0.15, -1.15, -0.20, 0.14 }, { 0.25, -1.32, -0.20, 0.10 }, { 0.32, -1.46, -0.20, 0.08 } }, p.pale)
			c:sparkle(p.glow, 5, 2, 0.3)
			c:light(p.glow, 1.8, 9)
		end,
	}

	-- A power-up lightning bolt with a face on its middle stroke, pixel wings,
	-- a halo and crackling sparks.
	S.al_t_bolt = {
		label = "Power Bolt",
		set = "arcade_legends",
		tint = C3(255, 230, 0),
		scale = 1.20,
		head = CFrame.new(0, 1.92, 0),
		neck = CFrame.new(0, -0.20, 0.36),
		back = CFrame.new(0, 0.30, -0.36),
		build = function(c, p)
			local D = 0.60
			local up = CFrame.new(0.15, 0.95, 0) * CFrame.Angles(0, 0, -0.45)
			local mid = CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, -0.15)
			local low = CFrame.new(-0.15, -0.65, 0) * CFrame.Angles(0, 0, -0.45)
			c:box(Vector3.new(0.70, 1.10, D), up, p.base)
			c:box(Vector3.new(1.40, 0.60, D), mid, p.base)
			c:box(Vector3.new(0.60, 1.00, D), low, p.base)
			c:cone(Vector3.new(0.50, 0.50, D), low * CFrame.new(0, -0.70, 0) * CFrame.Angles(math.pi, 0, 0), p.base)
			c:box(Vector3.new(0.10, 0.90, 0.04), up * CFrame.new(0, 0, D * 0.5 + 0.01), p.glow, NEON)
			c:box(Vector3.new(0.10, 0.80, 0.04), low * CFrame.new(0, 0, D * 0.5 + 0.01), p.glow, NEON)
			c:box(Vector3.new(1.20, 0.06, 0.04), mid * CFrame.new(0, 0.26, D * 0.5 + 0.01), p.glow, NEON)
			faceAt(c, mid * CFrame.new(0, 0.02, D * 0.5 + 0.02), 0.30, 0.20)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.18, 0.10, 0.04), mid * CFrame.new(0.50 * s, -0.12, D * 0.5 + 0.02), BLUSH)
				for i = 0, 2 do
					local w = 0.56 - i * 0.14
					c:box(Vector3.new(w, 0.14, 0.12), CFrame.new((0.72 + w * 0.5) * s, 0.50 - i * 0.16, -0.10), p.pale)
				end
			end
			halo(c, 1.80, 0.35, p.glow)
			bits(c, { { -0.90, 1.20, 0.10 }, { 0.95, -0.50, 0.10 }, { -0.90, -0.70, -0.10 }, { 0.80, 1.40, -0.10 } }, p.glow, NEON)
			c:light(p.glow, 1.8, 9)
		end,
	}

	-- ===================================================================
	-- EXOTIC: the rarest -- overclocked, multicoloured, everything lit.
	-- ===================================================================

	-- An overclocked processor: a die with a face inside a neon trace, gold
	-- pins on every edge, heat-sink fins behind and electrons in orbit.
	S.al_t_chip = {
		label = "Overclock Chip",
		set = "arcade_legends",
		tint = C3(0, 255, 160),
		scale = 1.15,
		head = CFrame.new(0, 1.40, -0.10),
		neck = CFrame.new(0, -0.50, 0.30),
		back = CFrame.new(0, 0.20, -0.80),
		build = function(c, p)
			c:box(Vector3.new(1.70, 1.70, 0.40), CFrame.new(0, 0.20, 0), p.dark)
			c:box(Vector3.new(1.10, 1.10, 0.06), CFrame.new(0, 0.20, 0.22), p.base)
			c:box(Vector3.new(1.24, 0.05, 0.04), CFrame.new(0, 0.82, 0.22), p.glow, NEON)
			c:box(Vector3.new(1.24, 0.05, 0.04), CFrame.new(0, -0.42, 0.22), p.glow, NEON)
			c:box(Vector3.new(0.05, 1.24, 0.04), CFrame.new(-0.62, 0.20, 0.22), p.glow, NEON)
			c:box(Vector3.new(0.05, 1.24, 0.04), CFrame.new(0.62, 0.20, 0.22), p.glow, NEON)
			face(c, 0.30, 0.27, 0.26, 0.24)
			cheeks(c, 0.40, 0.04, 0.26)
			for i = -1, 1 do
				local t = i * 0.50
				c:box(Vector3.new(0.30, 0.12, 0.12), CFrame.new(-1.00, 0.20 + t, 0), GOLD, METAL)
				c:box(Vector3.new(0.30, 0.12, 0.12), CFrame.new(1.00, 0.20 + t, 0), GOLD, METAL)
				c:box(Vector3.new(0.12, 0.30, 0.12), CFrame.new(t, 1.20, 0), GOLD, METAL)
				c:box(Vector3.new(0.12, 0.30, 0.12), CFrame.new(t, -0.80, 0), GOLD, METAL)
			end
			for i = -2, 2 do
				c:box(Vector3.new(0.10, 1.30, 0.50), CFrame.new(i * 0.30, 0.20, -0.45), p.light, METAL)
			end
			for i = 0, 5 do
				local a = i * math.pi / 3 + math.pi / 6
				c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(1.45 * math.cos(a), 0.20 + 1.30 * math.sin(a), 0.10), p.glow, NEON)
			end
			c:sparkle(p.glow, 5, 1.5, 0.3)
			c:light(p.glow, 2, 9)
		end,
	}

	-- Multiball! A crowned core with a face and eight chrome pinballs whirling
	-- round it, each with a neon streak.
	S.al_t_multiball = {
		label = "Multiball Orbit",
		set = "arcade_legends",
		tint = C3(255, 120, 0),
		scale = 1.10,
		head = CFrame.new(0, 1.30, 0),
		neck = CFrame.new(0, -0.40, 0.66),
		back = CFrame.new(0, 0.20, -0.66),
		build = function(c, p)
			c:box(Vector3.new(1.20, 1.20, 1.20), CFrame.new(0, 0.10, 0), p.base)
			c:box(Vector3.new(1.30, 0.20, 1.30), CFrame.new(0, -0.35, 0), p.dark)
			face(c, 0.25, 0.62, 0.26, 0.24)
			cheeks(c, 0.42, 0.04, 0.61)
			crown(c, 0.78, 0, 0.80, p.glow)
			for _, v in ipairs({
				{ 1.30, 0.50, 0.30 }, { -1.25, 0.70, -0.20 }, { 0.90, -0.60, 0.80 }, { -0.95, -0.45, 0.75 },
				{ 0.40, 1.35, -0.60 }, { -0.50, -1.05, -0.40 }, { 1.10, 0.05, -0.85 }, { -0.60, 1.25, 0.55 },
			}) do
				local pos = Vector3.new(v[1], v[2], v[3])
				c:ball(Vector3.new(0.34, 0.34, 0.34), CFrame.new(pos), CHROME, METAL)
				local tangent = Vector3.new(-pos.Z, 0, pos.X).Unit * 0.28
				c:box(Vector3.new(0.10, 0.10, 0.10), CFrame.new(pos - tangent), p.glow, NEON)
			end
			c:sparkle(p.glow, 5, 1.5, 0.3)
			c:light(p.glow, 2, 9)
		end,
	}

	-- A totem of three arcade buttons, biggest at the bottom, each ringed in
	-- neon: the face on the middle one, pixel wings and a crown on top.
	S.al_t_totem = {
		label = "Button Totem",
		set = "arcade_legends",
		tint = C3(255, 40, 80),
		scale = 1.10,
		head = CFrame.new(0, 1.62, 0),
		neck = CFrame.new(0, -0.20, 0.76),
		back = CFrame.new(0, 0.00, -0.76),
		build = function(c, p)
			for _, t in ipairs({
				{ -0.75, 1.90, 0.50, 1.50, p.light }, { 0.05, 1.45, 0.60, 1.15, p.base }, { 0.75, 1.00, 0.40, 0.80, p.pale },
			}) do
				c:cyl(Vector3.new(t[3], t[2], t[2]), CFrame.new(0, t[1], 0) * UPRIGHT, p.dark)
				c:cyl(Vector3.new(0.20, t[4], t[4]), CFrame.new(0, t[1] + t[3] * 0.5 + 0.10, 0) * UPRIGHT, t[5])
				c:cyl(Vector3.new(0.06, t[2] + 0.08, t[2] + 0.08), CFrame.new(0, t[1] - t[3] * 0.5 + 0.06, 0) * UPRIGHT, p.glow, NEON)
			end
			face(c, 0.08, 0.72, 0.26, 0.22)
			cheeks(c, 0.44, -0.08, 0.60)
			for _, s in ipairs(SIDES) do
				for i = 0, 2 do
					local w = 0.50 - i * 0.12
					c:box(Vector3.new(w, 0.14, 0.12), CFrame.new((0.70 + w * 0.5) * s, 0.30 - i * 0.16, -0.05), p.pale)
				end
			end
			crown(c, 1.24, 0, 0.60, p.glow)
			bits(c, { { -1.10, 1.00, 0.10 }, { 1.15, 0.90, -0.10 }, { 0.90, -0.60, 0.40 } }, p.glow, NEON)
			c:sparkle(p.glow, 4, 1.5, 0.3)
			c:light(p.glow, 2, 9)
		end,
	}

	-- A graphic equalizer jumping to the beat: seven lit bars with floating
	-- peak caps, a face across the middle three, speakers in the base.
	S.al_t_equalizer = {
		label = "Neon Equalizer",
		set = "arcade_legends",
		tint = C3(100, 60, 255),
		head = CFrame.new(0, 1.82, 0),
		neck = CFrame.new(0, -0.55, 0.50),
		back = CFrame.new(0, 0.20, -0.50),
		build = function(c, p)
			c:box(Vector3.new(2.60, 0.50, 0.90), CFrame.new(0, -0.80, 0), p.dark)
			for _, s in ipairs(SIDES) do
				c:cyl(Vector3.new(0.06, 0.36, 0.36), CFrame.new(0.95 * s, -0.80, 0.46) * FACE_Z, p.deep)
				c:cyl(Vector3.new(0.08, 0.14, 0.14), CFrame.new(0.95 * s, -0.80, 0.47) * FACE_Z, p.glow, NEON)
			end
			for i, h in ipairs({ 0.70, 1.20, 1.70, 2.10, 1.60, 1.10, 0.60 }) do
				local x = (i - 4) * 0.36
				c:box(Vector3.new(0.32, h, 0.60), CFrame.new(x, -0.55 + h * 0.5, 0), p.base)
				c:box(Vector3.new(0.34, 0.10, 0.62), CFrame.new(x, -0.55 + h + 0.12, 0), p.glow, NEON)
			end
			eyePair(c, CFrame.new(0, 0.55, 0.32), 0.36, 0.26)
			c:box(Vector3.new(0.30, 0.06, 0.05), CFrame.new(0, 0.25, 0.33), INK)
			cheeks(c, 0.36, 0.20, 0.31)
			for _, v in ipairs({ { -1.20, 1.00 }, { 1.20, 1.20 } }) do
				c:box(Vector3.new(0.18, 0.14, 0.10), CFrame.new(v[1], v[2], 0.10), p.glow, NEON)
				c:box(Vector3.new(0.05, 0.34, 0.05), CFrame.new(v[1] + 0.07, v[2] + 0.16, 0.10), p.glow, NEON)
			end
			c:sparkle(p.glow, 4, 1.5, 0.3)
			c:light(p.glow, 2, 9)
		end,
	}

	return S
end
