--[[ PetBodies/StarfrontTop -- Starfront's top bodies: one for each Epic-and-up
	pet, worn by that pet alone. Grounded space exploration: probes, landers,
	stations, small worlds and the critters that ride along with them.
	See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, WHITE, METAL, NEON, GLASS = K.INK, K.WHITE, K.METAL, K.NEON, K.GLASS
	local S = {}

	local V, CF = Vector3.new, CFrame.new
	local FACE_Z = CFrame.Angles(0, math.pi / 2, 0) -- turns a cylinder's X axis to face +Z
	local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2) -- stands a cylinder's X axis up
	local CELLS = C3(48, 80, 168) -- solar-cell blue
	local TYRE = C3(54, 52, 60)
	local FLAME, FLAME_CORE = C3(255, 150, 40), C3(255, 236, 120)
	local LEAF = C3(86, 196, 96)
	local BLUSH = C3(255, 150, 170)

	------------------------------------------------------------------ Epic

	-- A pocket cubesat: rails on its edges, fold-out panels like ears, whisker antennas.
	S.sf_t_cubesat = {
		label = "Pocket Cubesat",
		set = "starfront",
		tint = C3(64, 206, 226),
		head = CF(0, 0.92, 0),
		neck = CF(0, -0.36, 0.84),
		back = CF(0, 0.10, -0.84),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.60, 1.60, 1.60), legs = false, tail = false,
				eyeSpread = 0.36, eyeY = 0.18, eyeSize = V(0.44, 0.52, 0.20), mouthY = -0.32,
			})
			for _, x in ipairs({ -0.78, 0.78 }) do
				for _, z in ipairs({ -0.78, 0.78 }) do
					c:box(V(0.16, 1.66, 0.16), CF(x, 0.06, z), p.dark, METAL)
				end
			end
			for _, s in ipairs({ -1, 1 }) do
				local panel = CF(1.12 * s, 0.70, -0.10) * CFrame.Angles(0, 0, 0.55 * s)
				c:box(V(0.70, 0.08, 0.90), panel, p.light)
				c:box(V(0.56, 0.10, 0.76), panel, CELLS)
				local tip = V(1.10 * s, 1.18, 1.02)
				c:rod(V(0.62 * s, 0.80, 0.80), tip, 0.035, p.pale, METAL, false)
				c:ball(V(0.14, 0.14, 0.14), CF(tip), p.glow, NEON)
			end
			c:cyl(V(0.12, 0.40, 0.40), CF(0, 0.90, 0.20) * UPRIGHT, p.deep, GLASS)
		end,
	}

	-- A little Mars helicopter: splayed legs, a mast of counter-turning rotors, a solar cap.
	S.sf_t_rotor = {
		label = "Rotor Scout",
		set = "starfront",
		tint = C3(236, 132, 52),
		scale = 1.15,
		head = CF(0, 1.62, 0),
		neck = CF(0, -0.30, 0.68),
		back = CF(0, 0.10, -0.68),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.40, 1.10, 1.30), legs = false, tail = false,
				eyeSpread = 0.32, eyeY = 0.10, eyeSize = V(0.40, 0.46, 0.18), mouthY = -0.26,
			})
			for _, x in ipairs({ -1, 1 }) do
				for _, z in ipairs({ -1, 1 }) do
					local foot = V(0.92 * x, -0.94, 0.80 * z)
					c:rod(V(0.52 * x, -0.40, 0.48 * z), foot, 0.05, p.dark, METAL, false)
					c:box(V(0.26, 0.06, 0.26), CF(foot), p.deep)
				end
			end
			c:rod(V(0, 0.61, 0), V(0, 1.52, 0), 0.07, p.light, METAL, false)
			c:box(V(2.60, 0.05, 0.24), CF(0, 1.06, 0) * CFrame.Angles(0, 0.35, 0), p.pale)
			c:box(V(2.60, 0.05, 0.24), CF(0, 1.30, 0) * CFrame.Angles(0, -0.55, 0), p.pale)
			c:cyl(V(0.20, 0.30, 0.30), CF(0, 1.18, 0) * UPRIGHT, p.dark, METAL)
			c:box(V(0.70, 0.06, 0.50), CF(0, 1.56, 0), CELLS)
			c:cyl(V(0.08, 0.22, 0.22), CF(0, -0.52, 0.30) * UPRIGHT, p.glow, NEON)
		end,
	}

	-- A splashed-down crew capsule: cone cabin, scorched shield, float bags, a chute still open.
	S.sf_t_capsule = {
		label = "Splashdown Pod",
		set = "starfront",
		tint = C3(70, 148, 236),
		scale = 1.2,
		head = CF(0, 2.36, 0),
		neck = CF(0, -0.40, 0.94),
		back = CF(0, 0.10, -0.94),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.80, 1.10, 1.80), legs = false, tail = false,
				eyeY = 0.04, eyeSpread = 0.38, eyeSize = V(0.44, 0.50, 0.20), mouthY = -0.30,
			})
			c:cone(V(1.80, 0.80, 1.80), CF(0, 1.01, 0), p.light)
			c:cyl(V(0.30, 0.40, 0.40), CF(0, 1.48, 0) * UPRIGHT, p.dark, METAL)
			c:box(V(2.00, 0.20, 2.00), CF(0, -0.58, 0), p.deep)
			for _, x in ipairs({ -1, 1 }) do
				for _, z in ipairs({ -1, 1 }) do
					c:round(V(0.56, 0.48, 0.56), CF(0.86 * x, -0.32, 0.86 * z), C3(255, 140, 40))
				end
			end
			c:cone(V(1.30, 0.44, 1.30), CF(0, 2.12, 0), p.pale)
			c:box(V(1.36, 0.08, 1.36), CF(0, 1.91, 0), p.glow, NEON)
			for _, x in ipairs({ -1, 1 }) do
				for _, z in ipairs({ -1, 1 }) do
					c:rod(V(0.58 * x, 1.89, 0.58 * z), V(0.10 * x, 1.60, 0.10 * z), 0.02, p.pale, nil, false)
				end
			end
		end,
	}

	-- A radio telescope: a turret with a face, and a great dish tipped up to listen.
	S.sf_t_dish = {
		label = "Listening Dish",
		set = "starfront",
		tint = C3(176, 108, 236),
		scale = 1.15,
		head = CF(0, 0.72, 0.55),
		neck = CF(0, -0.36, 0.84),
		back = CF(0, 0.10, -0.84),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.60, 1.20, 1.60), legs = false, tail = false,
				eyeY = 0.02, eyeSpread = 0.36, eyeSize = V(0.42, 0.50, 0.20), mouthY = -0.30,
			})
			c:box(V(1.90, 0.22, 1.90), CF(0, -0.60, 0), p.dark)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.16, 0.66, 0.36), CF(0.70 * s, 0.94, -0.10), p.dark, METAL)
			end
			local dish = CF(0, 1.22, -0.10) * CFrame.Angles(0.55, 0, 0)
			c:cyl(V(0.12, 2.30, 2.30), dish * UPRIGHT, p.pale)
			c:cyl(V(0.14, 1.80, 1.80), dish * CF(0, 0.01, 0) * UPRIGHT, p.light)
			local focus = (dish * CF(0, 0.80, 0)).Position
			for i = 0, 2 do
				local a = i * 2 * math.pi / 3
				c:rod((dish * CF(math.cos(a) * 0.95, 0.06, math.sin(a) * 0.95)).Position, focus, 0.03, p.dark, METAL, false)
			end
			c:ball(V(0.24, 0.24, 0.24), CF(focus), p.glow, NEON)
			c:box(V(0.16, 0.10, 0.10), CF(0.70, -0.60, 0.96), C3(90, 255, 120), NEON)
		end,
	}

	-- The moon rabbit: tall ears and moon-walk goggles pushed up on its brow.
	S.sf_t_hare = {
		label = "Lunar Hare",
		set = "starfront",
		tint = C3(246, 178, 210),
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.36, 0.70),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				snout = { w = 0.56, h = 0.36, d = 0.30, y = -0.26, color = p.pale, nose = C3(255, 120, 150) },
				legSize = V(0.46, 0.32, 0.56), tailSize = V(0.44, 0.44, 0.36), tailColor = p.pale,
				bib = { w = 0.80, h = 0.56, y = -0.48, color = p.pale },
			})
			for _, s in ipairs({ -1, 1 }) do
				local ear = CF(0.36 * s, 1.42, -0.10) * CFrame.Angles(-0.12, 0, -0.10 * s)
				c:ovoid(V(0.34, 1.00, 0.22), ear, p.base)
				c:ovoid(V(0.18, 0.70, 0.08), ear * CF(0, -0.02, 0.12), p.pale)
				c:cyl(V(0.10, 0.32, 0.32), CF(0.28 * s, 0.70, 0.98) * FACE_Z, C3(120, 220, 255), GLASS)
			end
			c:box(V(1.40, 0.16, 0.10), CF(0, 0.68, 0.94), p.dark)
			c:box(V(0.08, 0.30, 0.30), CF(1.10, 0.10, -0.40), p.glow, NEON)
		end,
	}

	-- A tardigrade, the toughest space traveller: chubby folds, eight stubby legs.
	S.sf_t_waterbear = {
		label = "Star Waterbear",
		set = "starfront",
		tint = C3(112, 198, 92),
		head = CF(0, 1.00, 0.10),
		neck = CF(0, -0.30, 1.00),
		back = CF(0, 0.30, -0.96),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.90, 1.70, 2.00),
				eyeSize = V(0.30, 0.36, 0.16), eyeSpread = 0.40, eyeY = 0.26,
				snout = { w = 0.46, h = 0.40, d = 0.30, y = -0.18, color = p.pale, nose = C3(70, 40, 60) },
				legSize = V(0.36, 0.34, 0.32), legX = 0.66, legY = -0.80, legZ = { 0.66, 0.22, -0.22, -0.66 },
				legColor = p.dark, tail = false,
			})
			for _, z in ipairs({ 0.36, -0.10, -0.56 }) do
				c:box(V(1.70, 0.10, 0.14), CF(0, 0.92, z), p.dark)
			end
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.06, 0.22, 0.22), CF(1.00 * s, 0.20, -0.20), p.glow, NEON)
			end
		end,
	}

	-- A fuzzy moth whose four wings are solar panels.
	S.sf_t_moth = {
		label = "Solar Moth",
		set = "starfront",
		tint = C3(214, 84, 196),
		scale = 1.22,
		head = CF(0, 1.02, 0.10),
		neck = CF(0, -0.40, 0.90),
		back = CF(0, 0.20, -0.90),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.60, 1.60, 1.70), legs = false, tail = false,
				eyeSize = V(0.50, 0.60, 0.22), eyeSpread = 0.38, mouthSize = V(0.24, 0.12, 0.12),
				bib = { w = 0.90, h = 0.44, y = -0.42, color = p.pale },
			})
			c:box(V(1.30, 0.30, 0.50), CF(0, 0.86, 0.20), p.pale)
			for _, s in ipairs({ -1, 1 }) do
				local up = CF(1.14 * s, 0.52, -0.30) * CFrame.Angles(0, -0.25 * s, 0.45 * s)
				c:box(V(1.00, 0.08, 1.10), up, p.dark)
				c:box(V(0.84, 0.10, 0.08), up, p.light)
				c:box(V(0.08, 0.10, 0.94), up, p.light)
				c:box(V(0.70, 0.08, 0.70), CF(1.00 * s, -0.24, -0.36) * CFrame.Angles(0, 0.20 * s, -0.25 * s), p.deep)
				local tip = V(0.62 * s, 1.52, 0.66)
				c:rod(V(0.24 * s, 0.86, 0.50), tip, 0.035, p.dark, nil, false)
				c:box(V(0.30, 0.36, 0.05), CF(tip) * CFrame.Angles(0, 0, -0.4 * s), p.light)
			end
		end,
	}

	-- A pogo hopper bouncing across a crater on one big coil spring.
	S.sf_t_pogo = {
		label = "Crater Pogo",
		set = "starfront",
		tint = C3(60, 212, 158),
		scale = 1.12,
		head = CF(0, 0.90, 0),
		neck = CF(0, -0.40, 0.84),
		back = CF(0, 0.10, -0.84),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.70, 1.50, 1.60), legs = false, tail = false,
				eyeY = 0.18, eyeSpread = 0.36, eyeSize = V(0.46, 0.54, 0.20), mouthY = -0.28,
			})
			for i = 0, 3 do
				local tilt = (i % 2 == 0) and 0.12 or -0.12
				c:cyl(V(0.12, 0.74, 0.74), CF(0, -0.74 - i * 0.17, 0) * CFrame.Angles(0, i * 0.8, tilt) * UPRIGHT, (i % 2 == 0) and p.light or p.dark, METAL)
			end
			c:cyl(V(0.12, 1.00, 1.00), CF(0, -1.38, 0) * UPRIGHT, p.deep)
			for _, s in ipairs({ -1, 1 }) do
				c:cone(V(0.36, 0.40, 0.36), CF(0.98 * s, -0.10, -0.10), p.dark, METAL)
				c:ball(V(0.24, 0.24, 0.24), CF(0.98 * s, -0.40, -0.10), FLAME, NEON)
			end
			c:rod(V(0.30, 0.78, -0.20), V(0.46, 1.30, -0.30), 0.035, p.dark, METAL, false)
			c:ball(V(0.18, 0.18, 0.18), CF(0.46, 1.36, -0.30), p.glow, NEON)
		end,
	}

	-- An asteroid miner on tracks: a side-mounted drill and a hopper of glowing ore.
	S.sf_t_driller = {
		label = "Core Driller",
		set = "starfront",
		tint = C3(222, 94, 58),
		scale = 1.1,
		head = CF(0, 1.10, -0.10),
		neck = CF(0, -0.40, 0.92),
		back = CF(0, 0.20, -0.94),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.80, 1.30, 1.80), legs = false, tail = false,
				eyeY = 0.12, eyeSpread = 0.36, eyeSize = V(0.42, 0.48, 0.20), mouthY = -0.30,
				brow = p.deep,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.40, 0.56, 2.10), CF(1.10 * s, -0.56, 0), TYRE)
				for _, z in ipairs({ 0.60, -0.60 }) do
					c:cyl(V(0.42, 0.34, 0.34), CF(1.10 * s, -0.56, z), p.light, METAL)
				end
			end
			c:box(V(1.20, 0.30, 0.90), CF(0, 0.86, -0.30), p.dark)
			for i, v in ipairs({ V(-0.30, 1.04, -0.20), V(0.10, 1.08, -0.40), V(0.34, 1.02, -0.16) }) do
				c:box(V(0.24, 0.24, 0.24), CF(v) * CFrame.Angles(0.3 * i, 0.5 * i, 0), p.glow, NEON)
			end
			c:cyl(V(0.40, 0.54, 0.54), CF(0.70, -0.36, 1.04) * FACE_Z, p.dark, METAL)
			c:cone(V(0.46, 0.62, 0.46), CF(0.70, -0.36, 1.55) * CFrame.Angles(math.pi / 2, 0, 0), p.pale, METAL)
			c:cyl(V(0.06, 0.40, 0.40), CF(0.70, -0.36, 1.40) * FACE_Z, p.deep)
			c:box(V(0.40, 0.12, 0.08), CF(-0.50, 0.62, 0.92), FLAME_CORE, NEON)
		end,
	}

	-- A mission-control console: a screen for a face, a sloped keyboard, a gooseneck mic.
	S.sf_t_console = {
		label = "Mission Console",
		set = "starfront",
		tint = C3(52, 74, 170),
		head = CF(0, 0.82, 0),
		neck = CF(0, -0.50, 1.30),
		back = CF(0, 0.20, -0.66),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.80, 1.30, 1.20), legs = false, tail = false,
				eyeY = 0.20, eyeSpread = 0.36, eyeSize = V(0.40, 0.44, 0.18),
				eyeColor = C3(120, 240, 255), mouthY = -0.12, mouthColor = C3(120, 240, 255),
			})
			c:box(V(1.50, 0.96, 0.06), CF(0, 0.08, 0.61), C3(20, 28, 48))
			c:wedge(V(1.80, 0.36, 0.70), CF(0, -0.48, 0.95) * CFrame.Angles(0, math.pi, 0), p.dark)
			for i, col in ipairs({ C3(255, 84, 84), C3(255, 210, 70), C3(90, 224, 120) }) do
				c:box(V(0.30, 0.08, 0.20), CF((i - 2) * 0.46, -0.46, 0.95) * CFrame.Angles(0.475, 0, 0), col, NEON)
			end
			c:cyl(V(0.40, 0.46, 0.46), CF(0, -0.78, 0.10) * UPRIGHT, p.deep, METAL)
			c:box(V(1.30, 0.12, 1.20), CF(0, -1.02, 0.30), p.dark)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.12, 0.90, 0.80), CF(0.96 * s, 0.06, 0), p.light)
			end
			c:rod(V(-0.62, -0.36, 1.00), V(-0.72, 0.40, 1.20), 0.03, p.pale, METAL, false)
			c:ball(V(0.16, 0.16, 0.16), CF(-0.72, 0.44, 1.20), INK)
		end,
	}

	-- A space tug: grabber arms hauling a crate, twin engine bells behind.
	S.sf_t_tug = {
		label = "Cargo Tug",
		set = "starfront",
		tint = C3(250, 204, 44),
		head = CF(0, 1.00, 0),
		neck = CF(0, -0.50, 1.30),
		back = CF(0, 0.10, -1.30),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.70, 1.40, 1.60), legs = false, tail = false,
				eyeY = 0.24, eyeSpread = 0.36, eyeSize = V(0.42, 0.48, 0.20), mouthY = -0.12,
			})
			c:box(V(1.76, 0.14, 1.66), CF(0, -0.40, 0), p.deep)
			for _, s in ipairs({ -1, 1 }) do
				c:rod(V(0.62 * s, -0.48, 0.70), V(0.56 * s, -0.86, 1.22), 0.08, p.dark, METAL, false)
				c:box(V(0.12, 0.34, 0.14), CF(0.48 * s, -0.94, 1.30), p.light, METAL)
				c:cone(V(0.50, 0.40, 0.50), CF(0.42 * s, 0.06, -1.00) * CFrame.Angles(math.pi / 2, 0, 0), p.dark, METAL)
				c:ball(V(0.30, 0.30, 0.30), CF(0.42 * s, 0.06, -1.24), FLAME, NEON)
				c:box(V(0.14, 0.30, 0.30), CF(0.92 * s, 0.40, 0.30), p.light)
			end
			c:box(V(0.80, 0.56, 0.60), CF(0, -0.94, 1.30), p.pale)
			c:box(V(0.84, 0.60, 0.12), CF(0, -0.94, 1.30), p.dark)
			c:ball(V(0.20, 0.20, 0.20), CF(-0.50, 0.86, 0.40), C3(255, 70, 70), NEON)
			c:rod(V(0.10, 0.84, -0.50), V(0.60, 0.84, -0.50), 0.04, p.light, METAL)
		end,
	}

	-- A crescent moon in a nightcap, dozing between two stars.
	S.sf_t_crescent = {
		label = "Sleepy Crescent",
		set = "starfront",
		tint = C3(255, 228, 130),
		head = CF(0.30, 1.80, 0),
		neck = CF(-0.65, -0.34, 0.50),
		back = CF(-0.65, 0.06, -0.50),
		build = function(c, p)
			local O = V(0.35, 0.06, 0)
			for i, t in ipairs({ 0.42, 0.70, 0.92, 0.70, 0.42 }) do
				local a = math.rad(110 + (i - 1) * 35)
				c:box(V(t, 0.68, 0.90), CF(O + V(math.cos(a), math.sin(a), 0)) * CFrame.Angles(0, 0, a), (i == 3) and p.base or p.light)
			end
			c:eye(V(-0.84, 0.20, 0.47), 0.13)
			c:eye(V(-0.44, 0.20, 0.47), 0.13)
			c:box(V(0.18, 0.08, 0.06), CF(-0.64, -0.10, 0.47), C3(60, 40, 50))
			for _, x in ipairs({ -0.96, -0.32 }) do
				c:box(V(0.14, 0.08, 0.04), CF(x, -0.04, 0.46), BLUSH)
			end
			c:cone(V(0.50, 0.70, 0.50), CF(0.10, 1.40, 0) * CFrame.Angles(0, 0, -0.50), p.dark)
			c:ball(V(0.22, 0.22, 0.22), CF(0.30, 1.70, 0), p.pale)
			c:ball(V(0.20, 0.20, 0.20), CF(0.62, 0.50, 0.10), p.glow, NEON)
			c:ball(V(0.14, 0.14, 0.14), CF(0.80, -0.30, 0.20), p.glow, NEON)
		end,
	}

	-- A six-legged walker for rough lunar ground, with a sensor dome on top.
	S.sf_t_strider = {
		label = "Lunar Strider",
		set = "starfront",
		tint = C3(118, 136, 250),
		scale = 1.18,
		head = CF(0, 0.98, 0),
		neck = CF(0, -0.30, 0.98),
		back = CF(0, 0.20, -0.98),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.70, 0.90, 1.90), legs = false, tail = false,
				eyeY = 0.04, eyeSpread = 0.36, eyeSize = V(0.40, 0.42, 0.18), mouthY = -0.24,
			})
			for _, s in ipairs({ -1, 1 }) do
				for _, z in ipairs({ 0.62, 0, -0.62 }) do
					local knee = V(1.30 * s, 0.50, z * 1.1)
					c:rod(V(0.84 * s, 0.10, z), knee, 0.07, p.dark, METAL, false)
					c:rod(knee, V(1.52 * s, -0.92, z * 1.2), 0.06, p.light, METAL, false)
					c:ball(V(0.18, 0.18, 0.18), CF(knee), p.base)
				end
			end
			c:cyl(V(0.24, 0.80, 0.80), CF(0, 0.62, -0.10) * UPRIGHT, p.deep)
			c:ball(V(0.36, 0.36, 0.36), CF(0, 0.80, -0.10), p.glow, NEON)
		end,
	}

	-- A robot hound for crater patrol: a visor face, jointed legs, an antenna tail.
	S.sf_t_hound = {
		label = "Crater Hound",
		set = "starfront",
		tint = C3(160, 228, 72),
		head = CF(0, 0.94, 0.30),
		neck = CF(0, -0.30, 1.04),
		back = CF(0, 0.20, -1.04),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.60, 1.20, 2.00), legs = false, tail = false,
				eyeY = 0.16, eyeSpread = 0.32, eyeSize = V(0.36, 0.30, 0.16),
				eyeColor = C3(30, 40, 60), mouthY = -0.26, mouthSize = V(0.60, 0.08, 0.10),
			})
			c:box(V(1.30, 0.44, 0.06), CF(0, 0.16, 1.01), p.dark)
			for _, s in ipairs({ -1, 1 }) do
				c:wedge(V(0.12, 0.44, 0.40), CF(0.58 * s, 0.88, 0.60), p.light)
				for _, z in ipairs({ 0.62, -0.62 }) do
					local knee = V(0.70 * s, -0.78, z - 0.20)
					c:rod(V(0.62 * s, -0.44, z), knee, 0.09, p.dark, METAL, false)
					c:rod(knee, V(0.70 * s, -1.10, z + 0.06), 0.08, p.light, METAL, false)
					c:box(V(0.30, 0.10, 0.36), CF(0.70 * s, -1.14, z + 0.10), p.deep)
				end
			end
			c:rod(V(0, 0.40, -1.00), V(0, 1.00, -1.30), 0.04, p.dark, METAL, false)
			c:ball(V(0.18, 0.18, 0.18), CF(0, 1.04, -1.32), p.glow, NEON)
			c:box(V(0.70, 0.24, 0.80), CF(0, 0.78, -0.30), p.light)
		end,
	}

	-- A crab-shaped sample collector: two big claws, six legs, sample jars on its back.
	S.sf_t_crab = {
		label = "Sample Crab",
		set = "starfront",
		tint = C3(255, 118, 96),
		scale = 1.1,
		head = CF(0, 0.94, 0.20),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(2.00, 0.90, 1.50), legs = false, tail = false,
				eyeY = 0.10, eyeSpread = 0.40, eyeSize = V(0.38, 0.42, 0.18), mouthY = -0.22,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:rod(V(0.86 * s, -0.10, 0.50), V(1.18 * s, 0.00, 1.00), 0.08, p.dark, METAL, false)
				c:box(V(0.46, 0.40, 0.56), CF(1.22 * s, 0.02, 1.20), p.base)
				c:wedge(V(0.20, 0.22, 0.44), CF(1.22 * s, 0.32, 1.26) * CFrame.Angles(0, math.pi, 0), p.light)
				for _, z in ipairs({ 0.30, -0.12, -0.54 }) do
					c:rod(V(0.98 * s, -0.20, z), V(1.40 * s, -0.84, z - 0.10), 0.06, p.dark, METAL, false)
				end
				c:cyl(V(0.46, 0.34, 0.34), CF(0.42 * s, 0.74, -0.30) * UPRIGHT, p.pale, GLASS)
				c:cyl(V(0.10, 0.38, 0.38), CF(0.42 * s, 1.00, -0.30) * UPRIGHT, p.dark, METAL)
			end
			c:ball(V(0.18, 0.18, 0.18), CF(0, 0.60, -0.30), p.glow, NEON)
		end,
	}

	-- A greenhouse pod: a seedling growing under a glass dome, on stubby feet.
	S.sf_t_sprout = {
		label = "Sprout Pod",
		set = "starfront",
		tint = C3(188, 110, 64),
		head = CF(0, 1.96, 0),
		neck = CF(0, -0.36, 0.90),
		back = CF(0, 0.10, -0.90),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.70, 1.20, 1.70), legs = false, tail = false,
				eyeY = 0.04, eyeSpread = 0.36, eyeSize = V(0.42, 0.48, 0.20), mouthY = -0.30,
			})
			c:box(V(1.84, 0.16, 1.84), CF(0, 0.62, 0), p.dark)
			c:ball(V(1.40, 1.40, 1.40), CF(0, 0.70, 0), p.pale, GLASS)
			c:rod(V(0, 1.30, 0), V(0, 1.80, 0), 0.05, LEAF, nil, false)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.44, 0.08, 0.24), CF(0.22 * s, 1.62, 0) * CFrame.Angles(0, 0, 0.45 * s), LEAF)
			end
			c:ball(V(0.24, 0.24, 0.24), CF(0, 1.86, 0), p.glow, NEON)
			for _, x in ipairs({ -0.62, 0.62 }) do
				for _, z in ipairs({ -0.62, 0.62 }) do
					c:box(V(0.30, 0.18, 0.30), CF(x, -0.62, z), p.deep)
				end
				c:box(V(0.06, 0.40, 0.50), CF(x * 1.42, 0.06, 0), p.light)
			end
		end,
	}

	-- A manned manoeuvring unit with a mind of its own: arm rests, tanks, two flames.
	S.sf_t_jetpack = {
		label = "Jetpack Pal",
		set = "starfront",
		tint = C3(232, 58, 72),
		head = CF(0, 1.06, 0),
		neck = CF(0, -0.40, 0.62),
		back = CF(0, 0.20, -0.66),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.50, 1.70, 1.10), legs = false, tail = false,
				eyeY = 0.22, eyeSpread = 0.34, eyeSize = V(0.42, 0.50, 0.20), mouthY = -0.20,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.22, 0.22, 1.00), CF(0.86 * s, -0.12, 0.30), p.dark)
				c:ball(V(0.24, 0.24, 0.24), CF(0.86 * s, 0.04, 0.74), p.light)
				c:cyl(V(1.30, 0.40, 0.40), CF(0.96 * s, 0.24, -0.36) * UPRIGHT, p.light, METAL)
				c:cone(V(0.40, 0.34, 0.40), CF(0.40 * s, -0.94, -0.10), p.dark, METAL)
				c:cone(V(0.28, 0.42, 0.28), CF(0.40 * s, -1.30, -0.10) * CFrame.Angles(math.pi, 0, 0), FLAME, NEON)
				c:box(V(0.20, 0.20, 0.20), CF(0.70 * s, 0.98, 0.40), p.deep)
				c:box(V(0.20, 0.20, 0.20), CF(0.70 * s, 0.98, -0.40), p.deep)
			end
			c:box(V(0.40, 0.20, 0.06), CF(0, -0.52, 0.56), p.glow, NEON)
		end,
	}

	-- A tin robot helper: bolt ears, bezelled eyes, a chest dial and an antenna bulb.
	S.sf_t_rivetbot = {
		label = "Rivet Bot",
		set = "starfront",
		tint = C3(58, 168, 150),
		head = CF(0, 1.00, 0),
		neck = CF(0, -0.40, 0.76),
		back = CF(0, 0.20, -0.76),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.60, 1.60, 1.40), tail = false,
				eyeY = 0.26, eyeSpread = 0.36, eyeSize = V(0.40, 0.40, 0.18),
				mouthY = -0.10, mouthSize = V(0.60, 0.12, 0.10), mouthColor = p.dark,
				legSize = V(0.40, 0.46, 0.40), legX = 0.40, legY = -0.94, legZ = { 0 },
			})
			for _, s in ipairs({ -1, 1 }) do
				c:cyl(V(0.06, 0.60, 0.60), CF(0.36 * s, 0.26, 0.71) * FACE_Z, p.dark, METAL)
				c:cyl(V(0.20, 0.36, 0.36), CF(0.86 * s, 0.30, 0), p.light, METAL)
				c:rod(V(0.80 * s, 0.10, 0), V(1.14 * s, -0.40, 0.16), 0.10, p.dark, METAL, false)
				c:ball(V(0.32, 0.32, 0.32), CF(1.16 * s, -0.48, 0.18), p.light)
				c:box(V(0.50, 0.14, 0.60), CF(0.40 * s, -1.22, 0.06), p.deep)
			end
			c:rod(V(0, 0.86, 0), V(0, 1.36, 0), 0.04, p.dark, METAL, false)
			c:ball(V(0.22, 0.22, 0.22), CF(0, 1.42, 0), p.glow, NEON)
			c:cyl(V(0.06, 0.40, 0.40), CF(0, -0.44, 0.71) * FACE_Z, p.pale)
			c:box(V(0.12, 0.12, 0.06), CF(-0.40, -0.44, 0.72), C3(255, 84, 84), NEON)
			c:box(V(0.12, 0.12, 0.06), CF(0.40, -0.44, 0.72), C3(90, 224, 120), NEON)
		end,
	}

	------------------------------------------------------------- Legendary

	-- A gold-foil moon lander: descent stage, ascent cabin, four splayed legs, a flag.
	S.sf_t_lander = {
		label = "Foil Lander",
		set = "starfront",
		tint = C3(236, 150, 60),
		scale = 1.12,
		head = CF(0, 1.62, -0.10),
		neck = CF(0, -0.36, 0.92),
		back = CF(0, 0.10, -0.92),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.70, 1.00, 1.70), legs = false, tail = false,
				eyeY = 0.02, eyeSpread = 0.36, eyeSize = V(0.42, 0.46, 0.18), mouthY = -0.28,
			})
			c:box(V(1.76, 0.10, 1.76), CF(0, 0.38, 0), p.light)
			c:box(V(1.40, 0.76, 1.20), CF(0, 0.94, -0.10), p.pale)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.36, 0.28, 0.06), CF(0.30 * s, 1.04, 0.52), C3(30, 36, 60))
				c:box(V(0.16, 0.30, 0.30), CF(0.78 * s, 1.04, -0.10), p.dark)
			end
			c:cyl(V(0.30, 0.46, 0.46), CF(0, 1.46, -0.10) * UPRIGHT, p.dark, METAL)
			c:rod(V(-0.50, 1.32, -0.50), V(-0.62, 1.66, -0.62), 0.03, p.light, METAL, false)
			c:cyl(V(0.06, 0.40, 0.40), CF(-0.64, 1.70, -0.64) * CFrame.Angles(0, 0, 1.0), p.light)
			for _, x in ipairs({ -1, 1 }) do
				for _, z in ipairs({ -1, 1 }) do
					local pad = V(1.22 * x, -0.92, 1.22 * z)
					c:rod(V(0.70 * x, 0.10, 0.70 * z), pad, 0.06, p.light, METAL, false)
					c:cyl(V(0.08, 0.44, 0.44), CF(pad) * UPRIGHT, p.dark, METAL)
				end
			end
			c:cone(V(0.56, 0.30, 0.56), CF(0, -0.58, 0), p.deep, METAL)
			c:rod(V(0.62, 1.32, -0.40), V(0.62, 1.86, -0.40), 0.025, WHITE, nil, false)
			c:box(V(0.04, 0.22, 0.34), CF(0.62, 1.76, -0.24), p.glow)
		end,
	}

	-- A space telescope: aft shroud with a face, the optical tube, its door swung open.
	S.sf_t_telescope = {
		label = "Orbit Telescope",
		set = "starfront",
		tint = C3(170, 190, 255),
		scale = 1.15,
		head = CF(0, 0.82, 0.60),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.50, 1.40, 1.50), legs = false, tail = false,
				eyeY = 0.06, eyeSpread = 0.34, eyeSize = V(0.42, 0.48, 0.20), mouthY = -0.34,
			})
			c:cyl(V(0.14, 1.60, 1.60), CF(0, 0.78, 0) * UPRIGHT, p.dark, METAL)
			c:cyl(V(0.90, 1.36, 1.36), CF(0, 1.30, 0) * UPRIGHT, p.light)
			c:cyl(V(0.04, 1.10, 1.10), CF(0, 1.76, 0) * UPRIGHT, C3(16, 20, 40))
			c:box(V(1.20, 0.06, 1.10), CF(0, 1.78, -0.62) * CFrame.Angles(0.50, 0, 0) * CF(0, 0, -0.55), p.pale)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.06, 0.80, 0.06), CF(0.30 * s, 1.30, 0.69), p.pale)
				c:rod(V(0.68 * s, 1.20, 0), V(1.04 * s, 1.20, 0), 0.05, p.dark, METAL, false)
				c:box(V(0.48, 1.90, 0.06), CF(1.28 * s, 1.00, 0), p.dark)
				c:box(V(0.36, 1.78, 0.08), CF(1.28 * s, 1.00, 0), CELLS)
				c:rod(V(0.50 * s, -0.20, -0.75), V(0.70 * s, -0.40, -1.10), 0.03, p.light, METAL, false)
			end
			c:box(V(1.60, 0.12, 1.60), CF(0, -0.64, 0), p.deep)
			c:ball(V(0.24, 0.24, 0.24), CF(0, 1.86, 0.20), p.glow, NEON)
		end,
	}

	-- A winged orbiter: delta wings, black heat-tile belly, tail fin, three glowing engines.
	S.sf_t_shuttle = {
		label = "Delta Shuttle",
		set = "starfront",
		tint = C3(240, 242, 250),
		scale = 1.15,
		head = CF(0, 0.74, 0.40),
		neck = CF(0, -0.40, 1.16),
		back = CF(0, 0.20, -1.16),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.40, 1.20, 2.20), legs = false, tail = false,
				eyeY = 0.14, eyeSpread = 0.32, eyeSize = V(0.40, 0.44, 0.18), mouthY = -0.26,
			})
			c:box(V(1.44, 0.14, 2.24), CF(0, -0.50, 0), INK)
			c:box(V(0.90, 0.14, 0.34), CF(0, 0.68, 0.80), C3(30, 36, 60))
			local wing = V(0.12, 0.80, 1.70)
			c:wedge(wing, CF(1.10, -0.40, -0.20) * CFrame.Angles(math.pi, 0, 0) * CFrame.Angles(0, 0, -math.pi / 2), p.light)
			c:wedge(wing, CF(-1.10, -0.40, -0.20) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(0, 0, -math.pi / 2), p.light)
			c:wedge(V(0.12, 0.90, 0.90), CF(0, 1.11, -0.64) * CFrame.Angles(0, math.pi, 0), p.light)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.34, 0.30, 0.60), CF(0.44 * s, 0.80, -0.80), p.base)
			end
			for _, v in ipairs({ V(0, 0.30, -1.30), V(-0.34, -0.06, -1.30), V(0.34, -0.06, -1.30) }) do
				c:cone(V(0.40, 0.36, 0.40), CF(v) * CFrame.Angles(math.pi / 2, 0, 0), p.dark, METAL)
				c:ball(V(0.24, 0.24, 0.24), CF(v + V(0, 0, -0.20)), p.glow, NEON)
			end
			c:box(V(0.06, 0.04, 1.20), CF(0, 0.67, -0.20), p.dark)
		end,
	}

	-- A station robot arm: a turntable base with a face, its jointed arm curled overhead.
	S.sf_t_arm = {
		label = "Grapple Arm",
		set = "starfront",
		tint = C3(255, 122, 40),
		scale = 1.1,
		head = CF(0, 0.74, 0.30),
		neck = CF(0, -0.36, 0.92),
		back = CF(0, 0.20, -0.92),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.70, 1.20, 1.70), legs = false, tail = false,
				eyeY = 0.04, eyeSpread = 0.36, eyeSize = V(0.42, 0.48, 0.20), mouthY = -0.30,
				brow = p.dark,
			})
			c:cyl(V(0.20, 1.96, 1.96), CF(0, -0.60, 0) * UPRIGHT, p.dark, METAL)
			local shoulder, elbow, wrist, hand = V(0, 0.76, -0.62), V(0, 1.78, -0.92), V(0, 2.04, 0.06), V(0, 1.78, 0.62)
			c:cyl(V(0.56, 0.60, 0.60), CF(shoulder), p.dark, METAL)
			c:rod(shoulder, elbow, 0.15, p.light, nil, false)
			c:ball(V(0.40, 0.40, 0.40), CF(elbow), p.dark, METAL)
			c:rod(elbow, wrist, 0.13, p.light, nil, false)
			c:ball(V(0.34, 0.34, 0.34), CF(wrist), p.dark, METAL)
			c:rod(wrist, hand, 0.10, p.light, nil, false)
			c:box(V(0.40, 0.30, 0.30), CF(hand), p.dark, METAL)
			for _, o in ipairs({ V(-0.14, -0.24, 0), V(0.14, -0.24, 0), V(0, -0.24, 0.14) }) do
				c:box(V(0.08, 0.24, 0.08), CF(hand + o), p.pale, METAL)
			end
			c:box(V(0.22, 0.22, 0.22), CF(hand + V(0, -0.46, 0.04)) * CFrame.Angles(0.6, 0.7, 0), p.glow, NEON)
			c:box(V(0.12, 0.10, 0.06), CF(hand + V(0, 0.02, 0.16)), FLAME_CORE, NEON)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.06, 0.50, 0.70), CF(0.88 * s, 0.10, 0), p.dark)
			end
		end,
	}

	-- A station module: docking rings at each end, ribbed hull, a V of solar panels.
	S.sf_t_module = {
		label = "Dock Module",
		set = "starfront",
		tint = C3(110, 220, 255),
		scale = 1.1,
		head = CF(0, 1.90, -0.20),
		neck = CF(0, -0.40, 0.82),
		back = CF(0, 0.20, -0.82),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(2.00, 1.50, 1.50), legs = false, tail = false,
				eyeY = 0.06, eyeSpread = 0.40, eyeSize = V(0.42, 0.48, 0.20), mouthY = -0.32,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.14, 1.58, 1.58), CF(0.74 * s, 0.06, 0), p.light)
				c:cyl(V(0.14, 1.40, 1.40), CF(1.06 * s, 0.06, 0), p.dark, METAL)
				c:cyl(V(0.24, 0.80, 0.80), CF(1.24 * s, 0.06, 0), p.light, METAL)
				c:cyl(V(0.04, 0.50, 0.50), CF(1.37 * s, 0.06, 0), p.glow, NEON)
				local panel = CF(0.46 * s, 1.36, -0.20) * CFrame.Angles(0, 0, -0.35 * s)
				c:box(V(0.10, 1.00, 0.56), panel, p.dark)
				c:box(V(0.12, 0.88, 0.44), panel, CELLS)
			end
			c:box(V(0.80, 0.10, 0.20), CF(0, 0.86, -0.20), p.dark, METAL)
			c:box(V(1.30, 0.06, 0.06), CF(0, 0.70, 0.78), p.pale)
			c:box(V(1.30, 0.06, 0.06), CF(0, -0.58, 0.78), p.pale)
		end,
	}

	-- The golden record on edge, grooves and all, with its little probe riding behind.
	S.sf_t_record = {
		label = "Golden Record",
		set = "starfront",
		tint = C3(250, 212, 80),
		scale = 1.15,
		head = CF(0, 1.50, -0.20),
		neck = CF(0, -0.60, 0.20),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			local disc = CF(0, 0.30, 0) * FACE_Z
			c:cyl(V(0.24, 2.20, 2.20), disc, p.base, METAL)
			c:cyl(V(0.27, 1.70, 1.70), disc, p.dark, METAL)
			c:cyl(V(0.30, 1.30, 1.30), disc, p.base, METAL)
			c:cyl(V(0.33, 0.56, 0.56), disc, p.pale)
			c:eye(V(-0.40, 0.48, 0.20), 0.17)
			c:eye(V(0.40, 0.48, 0.20), 0.17)
			c:box(V(0.26, 0.10, 0.06), CF(0, 0.02, 0.18), C3(60, 30, 20))
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.18, 0.10, 0.04), CF(0.56 * s, 0.22, 0.17), BLUSH)
			end
			c:box(V(1.00, 1.00, 0.70), CF(0, 0.30, -0.50), p.dark, METAL)
			c:cyl(V(0.08, 1.00, 1.00), CF(0, 0.96, -0.62) * CFrame.Angles(-0.4, 0, 0) * UPRIGHT, p.pale)
			c:rod(V(0.40, 0.60, -0.70), V(1.46, 1.46, -0.90), 0.035, p.light, METAL, false)
			local a, b = V(-0.40, 0.00, -0.70), V(-1.30, -0.56, -0.90)
			c:rod(a, b, 0.05, p.light, METAL, false)
			for i = 1, 3 do
				c:cyl(V(0.14, 0.24, 0.24), CF(a:Lerp(b, 0.40 + i * 0.18)), p.deep, METAL)
			end
			c:rod(V(1.05, -0.30, 0.22), V(0.55, -0.20, 0.22), 0.035, p.light, METAL, false)
			c:box(V(0.12, 0.12, 0.10), CF(0.52, -0.20, 0.24), INK)
			c:ball(V(0.18, 0.18, 0.18), CF(1.30, 1.40, 0.10), p.glow, NEON)
			c:ball(V(0.14, 0.14, 0.14), CF(-1.20, 1.30, 0.10), p.glow, NEON)
		end,
	}

	-- A sky crane: four down-firing thrusters, lowering a tiny rover on cables.
	S.sf_t_skycrane = {
		label = "Sky Crane",
		set = "starfront",
		tint = C3(214, 70, 62),
		scale = 1.12,
		head = CF(0, 0.84, 0),
		neck = CF(0, -0.30, 0.86),
		back = CF(0, 0.10, -0.86),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.80, 0.80, 1.60), legs = false, tail = false,
				eyeY = 0.04, eyeSpread = 0.40, eyeSize = V(0.40, 0.38, 0.18),
				mouthY = -0.22, mouthSize = V(0.36, 0.08, 0.10),
			})
			for _, x in ipairs({ -1, 1 }) do
				for _, z in ipairs({ -1, 1 }) do
					c:box(V(0.40, 0.12, 0.12), CF(1.00 * x, 0.20, 0.62 * z), p.dark, METAL)
					c:cyl(V(0.36, 0.34, 0.34), CF(1.20 * x, 0.12, 0.62 * z) * UPRIGHT, p.light, METAL)
					c:ball(V(0.24, 0.24, 0.24), CF(1.20 * x, -0.14, 0.62 * z), FLAME, NEON)
					c:rod(V(0.40 * x, -0.34, 0.36 * z), V(0.36 * x, -1.06, 0.28 * z), 0.02, p.pale, nil, false)
					c:cyl(V(0.14, 0.26, 0.26), CF(0.50 * x, -1.40, 0.30 * z), TYRE)
				end
			end
			c:box(V(0.90, 0.36, 0.70), CF(0, -1.22, 0), p.pale)
			c:box(V(0.30, 0.16, 0.06), CF(0, -1.20, 0.36), p.glow, NEON)
			c:rod(V(-0.60, 0.46, -0.50), V(-0.60, 0.96, -0.50), 0.03, p.light, METAL, false)
			c:ball(V(0.16, 0.16, 0.16), CF(-0.60, 1.00, -0.50), C3(90, 255, 120), NEON)
		end,
	}

	-- A crawler-transporter: a tracked deck carrying a little rocket and its service tower.
	S.sf_t_crawler = {
		label = "Crawler Platform",
		set = "starfront",
		tint = C3(100, 182, 82),
		scale = 1.1,
		head = CF(0.30, 2.24, -0.20),
		neck = CF(0, -0.30, 1.00),
		back = CF(0, 0.10, -1.00),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(2.00, 0.80, 1.90), legs = false, tail = false,
				eyeY = 0.02, eyeSpread = 0.44, eyeSize = V(0.40, 0.38, 0.18), mouthY = -0.22,
				mouthSize = V(0.44, 0.10, 0.10),
			})
			for _, x in ipairs({ -1, 1 }) do
				for _, z in ipairs({ -1, 1 }) do
					c:box(V(0.60, 0.46, 0.76), CF(0.68 * x, -0.56, 0.58 * z), TYRE)
					c:box(V(0.64, 0.10, 0.80), CF(0.68 * x, -0.56, 0.58 * z), p.dark, METAL)
				end
				c:box(V(0.20, 0.12, 0.06), CF(0.78 * x, 0.30, 0.96), FLAME_CORE, NEON)
			end
			c:box(V(2.06, 0.10, 1.96), CF(0, 0.47, 0), p.dark)
			c:cyl(V(1.30, 0.50, 0.50), CF(0.30, 1.17, -0.20) * UPRIGHT, p.pale)
			c:cone(V(0.50, 0.42, 0.50), CF(0.30, 2.03, -0.20), p.dark)
			for _, s in ipairs({ -1, 1 }) do
				c:cyl(V(0.90, 0.24, 0.24), CF(0.30 + 0.36 * s, 0.97, -0.20) * UPRIGHT, p.light)
			end
			c:box(V(0.30, 1.70, 0.30), CF(-0.56, 1.37, -0.50), p.light, METAL)
			c:box(V(0.50, 0.08, 0.10), CF(-0.26, 1.50, -0.36), p.dark, METAL)
			c:box(V(0.50, 0.08, 0.10), CF(-0.26, 1.10, -0.36), p.dark, METAL)
			c:ball(V(0.20, 0.20, 0.20), CF(-0.56, 2.30, -0.50), C3(255, 70, 70), NEON)
		end,
	}

	-- A solar sail: a small pod rigged in front of a great diamond of shining film.
	S.sf_t_sail = {
		label = "Photon Sail",
		set = "starfront",
		tint = C3(192, 142, 255),
		scale = 1.12,
		head = CF(0, 0.80, 0.10),
		neck = CF(0, -0.36, 0.72),
		back = CF(0, 0.06, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.30, 1.30, 1.30), legs = false, tail = false,
				eyeSize = V(0.40, 0.48, 0.20), eyeSpread = 0.30, eyeY = 0.14, mouthY = -0.22,
				mouthSize = V(0.24, 0.12, 0.12),
			})
			c:cyl(V(0.10, 1.60, 1.60), CF(0, 0.06, -0.40) * FACE_Z, p.dark, METAL)
			local sail = CF(0, 0.06, -0.74) * CFrame.Angles(0, 0, math.pi / 4)
			c:box(V(1.90, 1.90, 0.04), sail, p.pale)
			c:box(V(1.10, 1.10, 0.05), sail, p.light)
			c:box(V(2.60, 0.06, 0.08), CF(0, 0.06, -0.72), p.dark, METAL)
			c:box(V(0.06, 2.60, 0.08), CF(0, 0.06, -0.72), p.dark, METAL)
			for _, v in ipairs({ V(1.32, 0.06, -0.72), V(-1.32, 0.06, -0.72), V(0, 1.38, -0.72), V(0, -1.26, -0.72) }) do
				c:ball(V(0.20, 0.20, 0.20), CF(v), p.glow, NEON)
			end
			c:cone(V(0.36, 0.30, 0.36), CF(0, -0.70, 0), p.dark, METAL)
			c:sparkle(p.glow, 4, 0.6, 0.18)
		end,
	}

	-- A crater greenhouse: a glass dome with crossed ribs, bushes round the rim, an airlock.
	S.sf_t_biodome = {
		label = "Glass Biodome",
		set = "starfront",
		tint = C3(76, 204, 150),
		head = CF(0, 1.50, 0),
		neck = CF(0, -0.36, 1.04),
		back = CF(0, 0.10, -1.30),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(2.00, 0.90, 2.00), legs = false, tail = false,
				eyeY = 0.00, eyeSpread = 0.44, eyeSize = V(0.40, 0.42, 0.18), mouthY = -0.24,
			})
			c:ball(V(1.84, 1.84, 1.84), CF(0, 0.51, 0), p.pale, GLASS)
			c:cyl(V(0.06, 1.90, 1.90), CF(0, 0.51, 0), p.light, METAL)
			c:cyl(V(0.06, 1.90, 1.90), CF(0, 0.51, 0) * FACE_Z, p.light, METAL)
			c:ball(V(0.24, 0.24, 0.24), CF(0, 1.46, 0), p.glow, NEON)
			for _, v in ipairs({ V(0.80, 0.66, 0.80), V(-0.80, 0.66, 0.80), V(0.80, 0.66, -0.80) }) do
				c:round(V(0.40, 0.36, 0.40), CF(v), LEAF)
			end
			c:ball(V(0.14, 0.14, 0.14), CF(0.80, 0.86, 0.80), p.glow, NEON)
			c:cyl(V(0.50, 0.56, 0.56), CF(0, -0.02, -1.20) * FACE_Z, p.dark)
			c:cyl(V(0.06, 0.40, 0.40), CF(0, -0.02, -1.46) * FACE_Z, p.glow, NEON)
			c:rod(V(-0.80, 0.51, -0.80), V(-0.80, 1.20, -0.80), 0.04, p.light, METAL, false)
			c:box(V(0.60, 0.06, 0.40), CF(-0.80, 1.22, -0.80) * CFrame.Angles(0.3, 0, 0), CELLS)
			for _, x in ipairs({ -0.80, 0.80 }) do
				for _, z in ipairs({ -0.80, 0.80 }) do
					c:box(V(0.22, 0.30, 0.22), CF(x, -0.52, z), p.deep)
				end
				c:box(V(0.06, 0.24, 0.60), CF(x * 1.26, 0.06, 0), C3(140, 210, 255), GLASS)
			end
		end,
	}

	-- A comms relay tower: a lattice mast with three dishes pointing three ways.
	S.sf_t_relay = {
		label = "Relay Tower",
		set = "starfront",
		tint = C3(255, 88, 120),
		scale = 1.12,
		head = CF(0, 2.40, 0),
		neck = CF(0, -0.30, 0.86),
		back = CF(0, 0.10, -0.86),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.60, 0.90, 1.60), legs = false, tail = false,
				eyeY = 0.02, eyeSpread = 0.36, eyeSize = V(0.40, 0.42, 0.18), mouthY = -0.24,
			})
			for _, x in ipairs({ -1, 1 }) do
				for _, z in ipairs({ -1, 1 }) do
					c:rod(V(0.36 * x, 0.51, 0.36 * z), V(0.14 * x, 2.00, 0.14 * z), 0.05, p.light, METAL, false)
				end
			end
			c:box(V(0.70, 0.06, 0.70), CF(0, 1.00, 0), p.dark)
			c:box(V(0.52, 0.06, 0.52), CF(0, 1.56, 0), p.dark)
			for _, d in ipairs({
				{ CF(0.46, 1.24, 0), V(0.10, 0, 0) },
				{ CF(-0.42, 1.74, 0) * CFrame.Angles(0, math.pi, 0), V(-0.10, 0, 0) },
				{ CF(0, 0.84, 0.44) * CFrame.Angles(0, -math.pi / 2, 0), V(0, 0, 0.10) },
			}) do
				c:cyl(V(0.06, 0.64, 0.64), d[1], p.pale)
				c:ball(V(0.12, 0.12, 0.12), CF(d[1].Position + d[2]), p.glow, NEON)
			end
			c:cone(V(0.36, 0.30, 0.36), CF(0, 2.15, 0), p.dark)
			c:ball(V(0.22, 0.22, 0.22), CF(0, 2.40, 0), p.glow, NEON)
			c:rod(V(0.14, 1.90, 0.14), V(0.78, 0.51, 0.78), 0.015, p.pale, nil, false)
			c:rod(V(-0.14, 1.90, 0.14), V(-0.78, 0.51, 0.78), 0.015, p.pale, nil, false)
			c:cyl(V(0.30, 0.40, 0.40), CF(0.62, -0.10, -0.86) * FACE_Z, p.dark)
		end,
	}

	-- An icy moonlet with blue cracks and geysers spouting from its crown.
	S.sf_t_moonlet = {
		label = "Geyser Moonlet",
		set = "starfront",
		tint = C3(170, 226, 255),
		scale = 1.1,
		head = CF(-0.30, 1.04, 0.20),
		neck = CF(0, -0.36, 0.92),
		back = CF(0, 0.20, -0.92),
		build = function(c, p)
			block(c, p, {
				shape = "round", legs = false, tail = false,
				eyeSize = V(0.48, 0.58, 0.22), eyeSpread = 0.40, mouthY = -0.30,
				mouthSize = V(0.30, 0.14, 0.12),
			})
			c:box(V(1.30, 0.05, 0.08), CF(-0.10, 0.97, -0.30) * CFrame.Angles(0, 0.5, 0), p.deep)
			c:box(V(0.08, 0.05, 1.00), CF(0.40, 0.97, 0.10), p.deep)
			c:box(V(0.06, 0.80, 0.06), CF(1.05, 0.10, 0.20) * CFrame.Angles(0.4, 0, 0), p.deep)
			c:box(V(0.06, 0.70, 0.06), CF(-1.05, -0.10, -0.20) * CFrame.Angles(-0.3, 0, 0), p.deep)
			for _, g in ipairs({
				{ V(0.40, 1.14, -0.20), 0.40 }, { V(0.46, 1.44, -0.26), 0.32 }, { V(0.52, 1.72, -0.32), 0.24 },
				{ V(-0.46, 1.12, -0.36), 0.36 }, { V(-0.52, 1.38, -0.40), 0.26 },
			}) do
				c:round(V(g[2], g[2], g[2]), CF(g[1]), p.pale)
			end
			c:ball(V(0.14, 0.14, 0.14), CF(0.58, 1.92, -0.36), p.glow, NEON)
			c:ball(V(0.12, 0.12, 0.12), CF(-0.56, 1.56, -0.44), p.glow, NEON)
			for _, v in ipairs({ V(-0.66, 0.92, 0.30), V(0.70, 0.84, -0.50), V(-0.20, 0.94, -0.62) }) do
				c:cone(V(0.26, 0.40, 0.26), CF(v), p.light)
			end
			c:box(V(0.30, 0.30, 0.30), CF(1.30, 0.80, -0.30) * CFrame.Angles(0.5, 0.6, 0.2), p.light)
		end,
	}

	---------------------------------------------------------------- Mythic

	-- A wheel space station: the hub is the face, eight lit segments turn round it.
	S.sf_t_wheel = {
		label = "Wheel Station",
		set = "starfront",
		tint = C3(122, 160, 255),
		scale = 1.15,
		head = CF(0, 0.80, 0.10),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.06, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.30, 1.30, 1.30), legs = false, tail = false,
				eyeSize = V(0.40, 0.48, 0.20), eyeSpread = 0.30, eyeY = 0.12, mouthY = -0.24,
				mouthSize = V(0.26, 0.12, 0.12),
			})
			for k = 0, 7 do
				local a = k * math.pi / 4 + math.pi / 8
				local seg = CF(math.cos(a) * 1.30, 0.06 + math.sin(a) * 1.30, -0.30) * CFrame.Angles(0, 0, a)
				c:box(V(0.34, 1.06, 0.44), seg, (k % 2 == 0) and p.light or p.base)
				if k % 2 == 1 then
					c:box(V(0.10, 0.40, 0.06), seg * CF(0, 0, 0.23), p.glow, NEON)
				end
			end
			for k = 0, 3 do
				local a = k * math.pi / 2 + math.pi / 4
				local dir = V(math.cos(a), math.sin(a), 0)
				c:rod(V(0, 0.06, -0.30) + dir * 0.56, V(0, 0.06, -0.30) + dir * 1.14, 0.06, p.dark, METAL, false)
			end
			c:cyl(V(0.60, 0.40, 0.40), CF(0, 0.06, -0.90) * FACE_Z, p.dark, METAL)
			c:cone(V(0.30, 0.40, 0.30), CF(0, 0.06, -1.30) * CFrame.Angles(-math.pi / 2, 0, 0), p.light, METAL)
			c:ball(V(0.24, 0.24, 0.24), CF(0, 0.80, 0.10), p.glow, NEON)
			c:light(p.glow, 1.4, 8)
		end,
	}

	-- A brass orrery: the sun in the middle is the face, three planets ride its arms.
	S.sf_t_orrery = {
		label = "Planet Orrery",
		set = "starfront",
		tint = C3(220, 168, 72),
		scale = 1.12,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.50, 0.74),
		back = CF(0, 0.06, -0.74),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.40, 1.40, 1.40), legs = false, tail = false,
				eyeSize = V(0.42, 0.50, 0.20), eyeSpread = 0.32, eyeY = 0.12, mouthY = -0.26,
				mouthSize = V(0.28, 0.12, 0.12),
			})
			for k = 0, 3 do
				local a = math.pi / 4 + k * math.pi / 2
				c:cone(V(0.30, 0.44, 0.30), CF(math.cos(a) * 0.94, 0.06 + math.sin(a) * 0.94, -0.10) * CFrame.Angles(0, 0, a - math.pi / 2), p.glow, NEON)
			end
			c:rod(V(0, -0.64, 0), V(0, -1.16, 0), 0.08, p.dark, METAL, false)
			c:cyl(V(0.04, 2.40, 2.40), CF(0, -0.84, 0) * UPRIGHT, p.light, METAL)
			c:cyl(V(0.20, 1.00, 1.00), CF(0, -1.22, 0) * UPRIGHT, p.deep, METAL)
			for _, pl in ipairs({
				{ V(1.30, -0.84, 0.30), 0.10, 0.42, p.dark },
				{ V(-1.16, -0.84, -0.40), 0.62, 0.52, p.pale },
				{ V(0.40, -0.84, -1.16), 1.04, 0.32, p.deep },
			}) do
				local foot = pl[1]
				local top = foot + V(0, pl[2] + 0.84, 0)
				c:rod(V(0, -0.84, 0), foot, 0.04, p.light, METAL, false)
				c:rod(foot, top, 0.035, p.light, METAL, false)
				c:ball(V(pl[3], pl[3], pl[3]), CF(top + V(0, pl[3] / 2, 0)), pl[4])
			end
			c:cyl(V(0.04, 0.90, 0.90), CF(-1.16, 0.88, -0.40) * CFrame.Angles(0.3, 0, 0.2) * UPRIGHT, p.light)
			c:light(p.glow, 1.6, 8)
		end,
	}

	-- A molten little world: glowing seams, a crust, an erupting volcano, two rock moons.
	S.sf_t_magma = {
		label = "Magma World",
		set = "starfront",
		tint = C3(255, 92, 36),
		scale = 1.1,
		head = CF(-0.30, 1.04, 0.20),
		neck = CF(0, -0.36, 0.94),
		back = CF(0, 0.20, -0.94),
		build = function(c, p)
			block(c, p, {
				shape = "round", legs = false, tail = false, brow = p.deep,
				eyeSize = V(0.48, 0.56, 0.22), eyeSpread = 0.40, mouthY = -0.32,
				mouthSize = V(0.36, 0.14, 0.12), mouthColor = p.glow,
			})
			for _, v in ipairs({
				{ V(0.60, 0.40, 0.08), CF(-0.50, -0.30, -0.88) },
				{ V(0.08, 0.50, 0.60), CF(1.05, -0.20, -0.30) },
				{ V(0.60, 0.08, 0.50), CF(-0.40, 0.97, -0.40) },
			}) do
				c:box(v[1], v[2], p.deep)
			end
			for _, v in ipairs({
				{ V(0.06, 0.70, 0.06), CF(1.06, 0.20, 0.40) * CFrame.Angles(0.5, 0, 0) },
				{ V(0.06, 0.60, 0.06), CF(-1.06, 0.10, -0.10) * CFrame.Angles(-0.4, 0, 0) },
				{ V(0.80, 0.06, 0.06), CF(0.10, 0.97, 0.40) * CFrame.Angles(0, 0.4, 0) },
				{ V(0.06, 0.06, 0.80), CF(0.30, 0.97, -0.40) },
				{ V(0.50, 0.06, 0.06), CF(0.40, -0.66, 0.90) },
			}) do
				c:box(v[1], v[2], p.glow, NEON)
			end
			c:cone(V(0.90, 0.60, 0.90), CF(0.30, 1.24, -0.20), p.dark)
			c:ball(V(0.30, 0.30, 0.30), CF(0.30, 1.52, -0.20), p.glow, NEON)
			for i, v in ipairs({ V(0.36, 1.78, -0.24), V(0.20, 2.00, -0.16), V(0.46, 2.12, -0.30) }) do
				local d = 0.24 - i * 0.04
				c:round(V(d, d, d), CF(v), FLAME, NEON)
			end
			c:box(V(0.34, 0.34, 0.34), CF(-1.36, 0.70, -0.20) * CFrame.Angles(0.4, 0.5, 0.2), p.dark)
			c:box(V(0.24, 0.24, 0.24), CF(1.36, -0.50, 0.30) * CFrame.Angles(0.2, 0.7, 0.5), p.dark)
			c:light(p.glow, 1.6, 8)
		end,
	}

	-- An ion-drive clipper: two glowing engine pods and stacked light sails on a mast.
	S.sf_t_clipper = {
		label = "Ion Clipper",
		set = "starfront",
		tint = C3(56, 220, 236),
		scale = 1.12,
		head = CF(0, 2.10, -0.10),
		neck = CF(0, -0.40, 1.14),
		back = CF(0, 0.10, -1.14),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.30, 1.00, 2.20), legs = false, tail = false,
				eyeY = 0.10, eyeSpread = 0.30, eyeSize = V(0.38, 0.42, 0.18), mouthY = -0.24,
			})
			c:wedge(V(0.20, 0.36, 1.60), CF(0, -0.62, -0.10) * CFrame.Angles(0, 0, math.pi), p.dark)
			c:box(V(0.70, 0.20, 0.50), CF(0, 0.64, 0.60), p.pale, GLASS)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.30, 0.12, 0.50), CF(0.76 * s, -0.10, -0.50), p.dark, METAL)
				c:cyl(V(1.10, 0.44, 0.44), CF(0.98 * s, -0.10, -0.50) * FACE_Z, p.light, METAL)
				c:cyl(V(0.10, 0.36, 0.36), CF(0.98 * s, -0.10, -1.08) * FACE_Z, p.glow, NEON)
				c:cone(V(0.30, 0.60, 0.30), CF(0.98 * s, -0.10, -1.40) * CFrame.Angles(math.pi / 2, 0, 0), p.glow, NEON)
				c:wedge(V(0.10, 0.50, 0.60), CF(0.70 * s, 0.30, -0.80) * CFrame.Angles(0, 0, -0.5 * s), p.base)
			end
			c:rod(V(0, 0.56, -0.10), V(0, 2.00, -0.10), 0.05, p.dark, METAL, false)
			c:box(V(1.50, 0.62, 0.06), CF(0, 1.04, -0.10), p.pale)
			c:box(V(1.56, 0.06, 0.08), CF(0, 1.36, -0.10), p.light, METAL)
			c:box(V(1.14, 0.50, 0.06), CF(0, 1.66, -0.10), p.pale)
			c:box(V(1.20, 0.06, 0.08), CF(0, 1.92, -0.10), p.light, METAL)
			c:ball(V(0.22, 0.22, 0.22), CF(0, 2.08, -0.10), p.glow, NEON)
			c:wedge(V(0.04, 0.20, 0.40), CF(0, 1.98, -0.36), p.glow, NEON)
			c:light(p.glow, 1.4, 8)
		end,
	}

	---------------------------------------------------------------- Divine

	-- A little sun: a ring of rays, a halo behind, a solar flare looping off its crown.
	S.sf_t_sun = {
		label = "Little Sun",
		set = "starfront",
		tint = C3(255, 196, 56),
		scale = 1.12,
		head = CF(0, 1.06, 0.10),
		neck = CF(0, -0.40, 0.94),
		back = CF(0, 0.20, -0.94),
		build = function(c, p)
			block(c, p, {
				shape = "round", legs = false, tail = false,
				eyeSize = V(0.48, 0.58, 0.22), eyeSpread = 0.40, mouthY = -0.30,
				mouthSize = V(0.40, 0.14, 0.12),
			})
			for k = 0, 5 do
				local a = k * math.pi / 3
				c:cone(V(0.40, 0.52, 0.40), CF(math.cos(a) * 1.28, 0.06 + math.sin(a) * 1.22, -0.10) * CFrame.Angles(0, 0, a - math.pi / 2), p.light, NEON)
			end
			c:cyl(V(0.06, 2.90, 2.90), CF(0, 0.06, -0.70) * FACE_Z, p.glow, NEON)
			c:cyl(V(0.08, 2.30, 2.30), CF(0, 0.06, -0.66) * FACE_Z, p.light)
			c:rod(V(-0.40, 0.98, 0), V(-0.20, 1.40, 0.10), 0.05, p.glow, NEON)
			c:rod(V(-0.20, 1.40, 0.10), V(0.30, 1.42, 0.10), 0.05, p.glow, NEON, false)
			c:rod(V(0.30, 1.42, 0.10), V(0.46, 0.98, 0), 0.05, p.glow, NEON)
			c:box(V(0.24, 0.24, 0.06), CF(0.70, 0.60, 0.80), p.deep)
			c:box(V(0.16, 0.16, 0.06), CF(-0.76, -0.40, 0.80), p.deep)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.22, 0.12, 0.06), CF(0.52 * s, -0.16, 0.88), BLUSH)
			end
			c:light(p.glow, 2, 10)
			c:sparkle(p.glow, 6, 0.8, 0.2)
		end,
	}

	-- A domed observatory: shutter rails, a telescope poking out, a ring of stars.
	S.sf_t_observatory = {
		label = "Dome Observatory",
		set = "starfront",
		tint = C3(150, 120, 255),
		scale = 1.1,
		head = CF(0, 1.56, -0.30),
		neck = CF(0, -0.36, 1.04),
		back = CF(0, 0.10, -1.04),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.90, 1.10, 1.90), legs = false, tail = false,
				eyeY = 0.02, eyeSpread = 0.42, eyeSize = V(0.42, 0.48, 0.20), mouthY = -0.30,
			})
			c:box(V(2.02, 0.12, 2.02), CF(0, 0.62, 0), p.dark)
			c:box(V(2.10, 0.16, 2.10), CF(0, -0.56, 0), p.deep)
			c:ball(V(1.80, 1.80, 1.80), CF(0, 0.66, 0), p.pale)
			for _, s in ipairs({ -1, 1 }) do
				c:cyl(V(0.06, 1.86, 1.86), CF(0.20 * s, 0.66, 0), p.dark)
				c:box(V(0.16, 1.10, 0.16), CF(0.86 * s, 0.06, 0.96), p.light)
				c:box(V(0.06, 0.30, 0.40), CF(0.96 * s, 0.10, -0.30), p.glow, NEON)
			end
			c:rod(V(0, 1.06, 0), V(0, 1.86, 0.72), 0.18, p.light, METAL, false)
			c:cyl(V(0.08, 0.40, 0.40), CF(0, 1.88, 0.74) * CFrame.Angles(0.733, 0, 0) * UPRIGHT, p.glow, NEON)
			for k = 0, 5 do
				local a = k * math.pi / 3 + math.pi / 6
				c:ball(V(0.18, 0.18, 0.18), CF(math.cos(a) * 1.36, 1.00 + ((k % 2 == 0) and 0.10 or -0.10), math.sin(a) * 1.36), p.glow, NEON)
			end
			c:rod(V(-0.50, 1.30, -0.40), V(-0.60, 1.80, -0.50), 0.03, p.dark, METAL, false)
			c:ball(V(0.16, 0.16, 0.16), CF(-0.60, 1.84, -0.50), C3(255, 70, 70), NEON)
			c:light(p.glow, 1.6, 8)
			c:sparkle(p.glow, 4, 0.5, 0.18)
		end,
	}

	---------------------------------------------------------------- Exotic

	-- Two planets sharing one orbit ring, the little one with a face of its own.
	S.sf_t_twins = {
		label = "Twin Planets",
		set = "starfront",
		tint = C3(124, 102, 255),
		scale = 1.15,
		head = CF(0, 0.90, 0.10),
		neck = CF(0, -0.50, 0.80),
		back = CF(0, 0.06, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.60, 1.60, 1.60), legs = false, tail = false,
				eyeSize = V(0.44, 0.52, 0.20), eyeSpread = 0.34, eyeY = 0.12, mouthY = -0.26,
			})
			c:box(V(1.40, 0.14, 1.40), CF(0, 0.66, 0), p.dark)
			c:box(V(1.44, 0.14, 1.40), CF(0, -0.48, 0), p.light)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.18, 0.10, 0.06), CF(0.40 * s, -0.10, 0.79), BLUSH)
			end
			local L = V(1.34, 0.72, -0.10)
			c:ball(V(0.90, 0.90, 0.90), CF(L), p.pale)
			c:eye(L + V(-0.16, 0.06, 0.40), 0.09)
			c:eye(L + V(0.16, 0.06, 0.40), 0.09)
			c:box(V(0.14, 0.06, 0.06), CF(L + V(0, -0.14, 0.43)), C3(60, 40, 50))
			local ring = CF(0.50, 0.30, -0.10) * CFrame.Angles(0.25, 0, 0.30) * UPRIGHT
			c:cyl(V(0.04, 2.80, 2.80), ring, p.light)
			c:cyl(V(0.05, 2.50, 2.50), ring, p.glow, NEON)
			c:rod(V(0.60, 0.50, -0.10), V(0.94, 0.62, -0.10), 0.05, p.glow, NEON, false)
			c:ball(V(0.24, 0.24, 0.24), CF(-1.10, 0.90, 0.10), p.light)
			c:ball(V(0.18, 0.18, 0.18), CF(1.50, -0.60, 0.30), p.light)
			for _, v in ipairs({ V(-1.00, -0.70, 0.30), V(0.40, 1.40, 0.10), V(-0.60, 1.30, -0.20) }) do
				c:ball(V(0.14, 0.14, 0.14), CF(v), WHITE, NEON)
			end
			c:light(p.glow, 1.4, 8)
		end,
	}

	-- A puff of star-forming gas: billowing lumps, a wispy tail, newborn stars twinkling.
	S.sf_t_nebula = {
		label = "Nebula Puff",
		set = "starfront",
		tint = C3(255, 108, 220),
		scale = 1.1,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.40, 0.96),
		back = CF(0, 0.20, -1.00),
		build = function(c, p)
			block(c, p, {
				shape = "round", legs = false, tail = false,
				eyeSize = V(0.46, 0.56, 0.22), eyeSpread = 0.38, eyeY = 0.10, mouthY = -0.28,
				mouthSize = V(0.26, 0.12, 0.12),
			})
			for i, v in ipairs({
				{ V(1.20, 0.60, 1.10), V(0, 1.06, -0.10) },
				{ V(0.80, 0.70, 0.80), V(0.80, 0.80, -0.20) },
				{ V(0.80, 0.70, 0.80), V(-0.80, 0.84, -0.10) },
				{ V(0.60, 0.90, 0.90), V(1.10, -0.06, -0.10) },
				{ V(0.60, 0.90, 0.90), V(-1.10, 0.00, -0.20) },
				{ V(0.80, 0.50, 0.80), V(0.70, -0.76, 0.00) },
				{ V(0.80, 0.50, 0.80), V(-0.70, -0.76, -0.10) },
				{ V(1.00, 0.80, 0.50), V(0, 0.20, -1.00) },
			}) do
				c:round(v[1], CF(v[2]), (i % 2 == 0) and p.light or p.pale)
			end
			c:round(V(0.60, 0.50, 0.60), CF(0.30, 0.40, -1.46), p.light)
			c:round(V(0.36, 0.32, 0.40), CF(0.50, 0.60, -1.80), p.pale)
			for _, v in ipairs({ V(0.40, 1.40, 0.20), V(-0.60, 1.20, 0.30), V(1.30, 0.30, 0.30), V(-1.30, -0.30, 0.20), V(0.90, -0.90, 0.40) }) do
				c:ball(V(0.16, 0.16, 0.16), CF(v), p.glow, NEON)
			end
			c:light(p.glow, 1.4, 8)
			c:sparkle(p.glow, 5, 0.5, 0.18)
		end,
	}

	-- A Venus cloud balloon: striped envelope, a gondola with propellers, cloud tops below.
	S.sf_t_aerostat = {
		label = "Cloud Aerostat",
		set = "starfront",
		tint = C3(255, 168, 76),
		scale = 1.15,
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.60, 0.94),
		back = CF(0, 0.20, -0.94),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(2.00, 1.60, 1.80), legs = false, tail = false,
				eyeSize = V(0.46, 0.56, 0.22), eyeSpread = 0.40, eyeY = 0.18, mouthY = -0.20,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.12, 1.64, 1.84), CF(0.74 * s, 0.06, 0), p.light)
			end
			c:box(V(2.06, 0.12, 1.86), CF(0, -0.50, 0), p.dark)
			c:cyl(V(0.14, 0.50, 0.50), CF(0, 0.88, 0) * UPRIGHT, p.dark, METAL)
			c:ball(V(0.20, 0.20, 0.20), CF(0, 1.02, 0), p.glow, NEON)
			for _, x in ipairs({ -1, 1 }) do
				for _, z in ipairs({ -1, 1 }) do
					c:rod(V(0.50 * x, -0.66, 0.40 * z), V(0.36 * x, -1.16, 0.26 * z), 0.02, p.pale, nil, false)
				end
			end
			c:box(V(0.90, 0.42, 0.70), CF(0, -1.36, 0), p.deep)
			c:box(V(0.50, 0.14, 0.06), CF(0, -1.32, 0.36), p.glow, NEON)
			for _, s in ipairs({ -1, 1 }) do
				c:cyl(V(0.20, 0.16, 0.16), CF(0.30 * s, -1.36, -0.44) * FACE_Z, p.dark, METAL)
				c:box(V(0.06, 0.56, 0.06), CF(0.30 * s, -1.36, -0.56) * CFrame.Angles(0, 0, 0.5), p.light)
				c:box(V(0.56, 0.06, 0.06), CF(0.30 * s, -1.36, -0.56) * CFrame.Angles(0, 0, 0.5), p.light)
			end
			for _, v in ipairs({ V(-0.80, -1.66, 0.10), V(0.80, -1.72, -0.10), V(0, -1.80, -0.40) }) do
				c:round(V(0.70, 0.36, 0.60), CF(v), p.pale)
			end
			c:light(p.glow, 1.2, 8)
		end,
	}

	-- An orbital foundry: a furnace-grate mouth, an anvil deck, stacks breathing starfire.
	S.sf_t_forge = {
		label = "Star Forge",
		set = "starfront",
		tint = C3(255, 112, 52),
		scale = 1.1,
		head = CF(0.40, 1.10, 0.30),
		neck = CF(0, -0.50, 0.96),
		back = CF(0, 0.20, -0.96),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(2.00, 1.40, 1.80), legs = false, tail = false, mouth = false,
				eyeY = 0.24, eyeSpread = 0.42, eyeSize = V(0.42, 0.48, 0.20), brow = p.deep,
			})
			c:box(V(0.90, 0.38, 0.06), CF(0, -0.30, 0.91), p.glow, NEON)
			for i = -1, 1 do
				c:box(V(0.08, 0.42, 0.08), CF(i * 0.24, -0.30, 0.94), p.dark, METAL)
			end
			c:box(V(2.30, 0.28, 1.30), CF(0, 0.90, -0.10), p.dark, METAL)
			c:wedge(V(0.80, 0.28, 0.50), CF(0, 0.90, 0.80) * CFrame.Angles(0, math.pi, 0), p.dark, METAL)
			for _, s in ipairs({ -1, 1 }) do
				c:cyl(V(0.56, 0.36, 0.36), CF(0.66 * s, 1.32, -0.50) * UPRIGHT, p.light, METAL)
				c:ball(V(0.30, 0.30, 0.30), CF(0.66 * s, 1.66, -0.50), p.glow, NEON)
				c:cyl(V(0.20, 1.00, 1.00), CF(1.10 * s, -0.10, -0.10), p.light, METAL)
				c:cyl(V(0.24, 0.36, 0.36), CF(1.12 * s, -0.10, -0.10), p.glow, NEON)
				c:box(V(0.50, 0.24, 0.60), CF(0.62 * s, -0.76, 0.40), p.deep)
				c:box(V(0.50, 0.24, 0.60), CF(0.62 * s, -0.76, -0.50), p.deep)
			end
			c:rod(V(-0.90, 1.04, -0.60), V(-0.20, 1.60, -0.20), 0.07, p.dark, METAL, false)
			c:box(V(0.30, 0.30, 0.50), CF(-0.14, 1.62, -0.16), p.base, METAL)
			for i, v in ipairs({ V(0.50, 1.40, 0.40), V(0.80, 1.80, 0.10), V(0.30, 2.10, -0.10) }) do
				c:box(V(0.24, 0.14, 0.14), CF(v) * CFrame.Angles(0.3 * i, 0.6 * i, 0.2), p.glow, NEON)
			end
			c:light(p.glow, 1.6, 8)
		end,
	}

	-- A mining rig clamped onto a lumpy asteroid: derrick, drill string, glowing ore veins.
	S.sf_t_rig = {
		label = "Asteroid Rig",
		set = "starfront",
		tint = C3(150, 255, 120),
		scale = 1.1,
		head = CF(0, 2.12, -0.10),
		neck = CF(0, -0.40, 0.94),
		back = CF(0, 0.20, -0.94),
		build = function(c, p)
			block(c, p, {
				shape = "round", legs = false, tail = false,
				eyeSize = V(0.46, 0.54, 0.22), eyeSpread = 0.40, mouthY = -0.30, brow = p.deep,
			})
			for _, v in ipairs({
				{ V(0.60, 0.50, 0.60), CF(-0.80, 0.70, -0.40) * CFrame.Angles(0.3, 0.4, 0.2) },
				{ V(0.50, 0.60, 0.50), CF(0.90, -0.40, -0.50) * CFrame.Angles(0.2, 0.6, 0.3) },
				{ V(0.50, 0.40, 0.50), CF(-0.60, -0.70, 0.30) * CFrame.Angles(0.5, 0.2, 0.1) },
			}) do
				c:box(v[1], v[2], p.dark)
			end
			for _, v in ipairs({ V(1.04, 0.30, 0.30), V(-1.04, 0.10, -0.10), V(0.50, 0.97, -0.50), V(0.70, -0.70, 0.70) }) do
				c:box(V(0.20, 0.20, 0.20), CF(v) * CFrame.Angles(0.6, 0.8, 0), p.glow, NEON)
			end
			for _, x in ipairs({ -1, 1 }) do
				for _, z in ipairs({ -1, 1 }) do
					c:rod(V(0.40 * x, 0.96, 0.36 * z - 0.10), V(0.06 * x, 1.86, 0.06 * z - 0.10), 0.04, p.light, METAL, false)
				end
			end
			c:box(V(0.30, 0.16, 0.30), CF(0, 1.90, -0.10), p.dark, METAL)
			c:cyl(V(0.90, 0.12, 0.12), CF(0, 1.40, -0.10) * UPRIGHT, p.pale, METAL)
			c:ball(V(0.20, 0.20, 0.20), CF(0, 2.06, -0.10), C3(255, 70, 70), NEON)
			for _, s in ipairs({ -1, 1 }) do
				c:cyl(V(0.40, 0.30, 0.30), CF(0.98 * s, -0.20, -0.50) * FACE_Z, p.light, METAL)
				c:cone(V(0.26, 0.30, 0.26), CF(0.98 * s, -0.20, -0.86) * CFrame.Angles(math.pi / 2, 0, 0), p.glow, NEON)
			end
			c:box(V(0.40, 0.30, 0.40), CF(1.22, 0.30, -0.10), p.deep, METAL)
			c:light(p.glow, 1.4, 8)
		end,
	}

	-- A fish-shaped submarine probe for the ocean under Europa's ice.
	S.sf_t_diver = {
		label = "Europa Diver",
		set = "starfront",
		tint = C3(40, 176, 255),
		scale = 1.1,
		head = CF(0, 0.92, 0.30),
		neck = CF(0, -0.50, 1.10),
		back = CF(0, 0.30, -1.10),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.50, 1.30, 2.20), legs = false, tail = false,
				eyeSize = V(0.42, 0.50, 0.20), eyeSpread = 0.34, eyeY = 0.10, mouthY = -0.24,
				mouthSize = V(0.30, 0.12, 0.12), bib = { w = 0.90, h = 0.40, y = -0.40, color = p.pale },
			})
			for _, s in ipairs({ -1, 1 }) do
				c:cyl(V(0.10, 0.22, 0.22), CF(0.40 * s, 0.56, 0.92) * FACE_Z, p.glow, NEON)
				c:rod(V(0.30 * s, -0.30, 1.08), V(0.80 * s, -0.60, 1.40), 0.025, p.dark, nil, false)
				c:box(V(0.60, 0.08, 0.50), CF(0.90 * s, -0.20, 0.10) * CFrame.Angles(0, 0.3 * s, -0.3 * s), p.light)
				c:cyl(V(0.06, 0.30, 0.30), CF(0.80 * s, 0.30, -0.40), C3(140, 210, 255), GLASS)
			end
			c:wedge(V(0.10, 0.50, 0.80), CF(0, 0.92, -0.40) * CFrame.Angles(0, math.pi, 0), p.light)
			c:wedge(V(0.10, 0.50, 0.50), CF(0, 0.46, -1.30) * CFrame.Angles(0, math.pi, 0), p.light)
			c:wedge(V(0.10, 0.50, 0.50), CF(0, -0.34, -1.30) * CFrame.Angles(0, 0, math.pi), p.light)
			c:cyl(V(0.30, 0.70, 0.70), CF(0, 0.06, -1.24) * FACE_Z, p.dark, METAL)
			c:box(V(0.80, 0.12, 0.06), CF(0, 0.06, -1.42) * CFrame.Angles(0, 0, 0.6), p.pale, METAL)
			c:box(V(0.80, 0.12, 0.06), CF(0, 0.06, -1.42) * CFrame.Angles(0, 0, -0.9), p.pale, METAL)
			c:ball(V(0.40, 0.40, 0.40), CF(0, -0.62, 0.30), p.glow, NEON)
			for i, v in ipairs({ V(0.40, 0.70, -1.50), V(0.56, 1.00, -1.66), V(0.44, 1.30, -1.80) }) do
				local d = 0.24 - i * 0.04
				c:ball(V(d, d, d), CF(v), p.pale, GLASS)
			end
			c:light(p.glow, 1.2, 8)
		end,
	}

	-- A space-elevator climber gripping its glowing ribbon, cargo racked on its flanks.
	S.sf_t_elevator = {
		label = "Sky Elevator",
		set = "starfront",
		tint = C3(200, 250, 110),
		scale = 1.18,
		head = CF(0.50, 0.86, 0.10),
		neck = CF(0, -0.40, 0.82),
		back = CF(0, 0.10, -0.90),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = V(1.70, 1.30, 1.50), legs = false, tail = false,
				eyeY = 0.10, eyeSpread = 0.40, eyeSize = V(0.42, 0.48, 0.20), mouthY = -0.28,
			})
			c:box(V(0.10, 2.60, 0.04), CF(0, 0.10, -0.80), p.glow, NEON)
			for _, y in ipairs({ 0.84, -0.74 }) do
				for _, s in ipairs({ -1, 1 }) do
					c:cyl(V(0.16, 0.36, 0.36), CF(0.16 * s, y, -0.80), p.dark, METAL)
				end
			end
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.10, 1.00, 1.10), CF(0.90 * s, 0.06, 0), p.dark, METAL)
				c:box(V(0.40, 0.40, 0.40), CF(1.14 * s, 0.30, 0.20), p.light)
				c:box(V(0.36, 0.36, 0.36), CF(1.12 * s, -0.20, -0.24), p.pale)
				c:box(V(0.24, 0.20, 0.06), CF(0.50 * s, 0.56, 0.76), p.glow, NEON)
			end
			c:cyl(V(0.08, 0.90, 0.90), CF(0, -0.64, 0.10) * UPRIGHT, p.pale)
			c:cone(V(0.50, 0.70, 0.50), CF(0, -1.04, 0.10), p.glow, NEON)
			c:box(V(0.60, 0.30, 0.40), CF(0, 1.46, -0.80), p.light, METAL)
			c:ball(V(0.20, 0.20, 0.20), CF(0, 1.66, -0.80), C3(255, 70, 70), NEON)
			c:box(V(0.50, 0.20, 0.40), CF(0, -1.26, -0.80), p.deep, METAL)
			c:light(p.glow, 1.4, 8)
		end,
	}

	-- A spinning pulsar: twin beams out of its poles, field loops, flecks of light.
	S.sf_t_pulsar = {
		label = "Pulsar Beacon",
		set = "starfront",
		tint = C3(120, 255, 236),
		scale = 1.25,
		head = CF(-0.40, 0.84, 0.20),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.06, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.50, 1.50, 1.50), legs = false, tail = false,
				eyeSize = V(0.44, 0.52, 0.20), eyeSpread = 0.34, eyeY = 0.12, mouthY = -0.26,
				mouthSize = V(0.26, 0.12, 0.12),
			})
			c:cone(V(0.50, 0.90, 0.50), CF(0.26, 1.24, 0) * CFrame.Angles(0, 0, -0.30) * CFrame.Angles(math.pi, 0, 0), p.glow, NEON)
			c:cone(V(0.50, 0.90, 0.50), CF(-0.26, -1.12, 0) * CFrame.Angles(0, 0, -0.30), p.glow, NEON)
			for _, s in ipairs({ -1, 1 }) do
				local top, mid, bot = V(0.40 * s, 0.76, 0), V(1.30 * s, 0.06, 0), V(0.40 * s, -0.64, 0)
				c:rod(top, mid, 0.04, p.light, NEON, false)
				c:rod(mid, bot, 0.04, p.light, NEON, false)
				c:ball(V(0.12, 0.12, 0.12), CF(mid), WHITE, NEON)
				c:box(V(0.18, 0.10, 0.06), CF(0.40 * s, -0.12, 0.74), BLUSH)
			end
			c:cyl(V(0.04, 2.20, 2.20), CF(0, 0.06, 0) * CFrame.Angles(0.15, 0, 0) * UPRIGHT, p.pale)
			for _, v in ipairs({ V(1.00, 0.90, 0.30), V(-1.00, 0.80, -0.20), V(1.00, -0.80, -0.20), V(-0.90, -0.90, 0.30) }) do
				c:box(V(0.14, 0.14, 0.14), CF(v) * CFrame.Angles(0.6, 0.6, 0), p.glow, NEON)
			end
			c:light(p.glow, 2, 10)
		end,
	}

	-- A comet: a frosty nucleus with a glowing ion tail and a paler dust tail.
	S.sf_t_comet = {
		label = "Tailed Comet",
		set = "starfront",
		tint = C3(150, 216, 255),
		scale = 1.15,
		head = CF(0, 0.92, 0.10),
		neck = CF(0, -0.40, 0.84),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.60, 1.50, 1.60), legs = false, tail = false,
				eyeSize = V(0.46, 0.54, 0.22), eyeSpread = 0.36, eyeY = 0.10, mouthY = -0.26,
				mouthSize = V(0.28, 0.12, 0.12), brow = p.light,
			})
			for _, v in ipairs({
				{ V(0.50, 0.40, 0.50), CF(0.56, 0.74, 0.20) * CFrame.Angles(0.3, 0.5, 0.2) },
				{ V(0.40, 0.40, 0.40), CF(-0.70, -0.50, 0.30) * CFrame.Angles(0.4, 0.2, 0.3) },
				{ V(0.44, 0.36, 0.44), CF(-0.50, 0.70, -0.40) * CFrame.Angles(0.2, 0.7, 0.1) },
			}) do
				c:box(v[1], v[2], p.pale)
			end
			for i, v in ipairs({
				{ V(1.20, 1.00, 0.60), V(0, 0.26, -0.92) },
				{ V(0.96, 0.80, 0.56), V(0, 0.46, -1.28) },
				{ V(0.70, 0.60, 0.50), V(0, 0.64, -1.60) },
				{ V(0.40, 0.36, 0.40), V(0, 0.80, -1.88) },
			}) do
				c:box(v[1], CF(v[2]), (i % 2 == 1) and p.glow or p.light, NEON)
			end
			for _, v in ipairs({
				{ V(0.60, 0.50, 0.50), V(0.76, -0.10, -1.00) },
				{ V(0.44, 0.36, 0.44), V(1.06, -0.04, -1.34) },
				{ V(0.28, 0.24, 0.30), V(1.28, 0.04, -1.62) },
			}) do
				c:round(v[1], CF(v[2]), p.pale)
			end
			for _, s in ipairs({ -1, 1 }) do
				c:cone(V(0.20, 0.36, 0.20), CF(0.62 * s, 0.70, 0.56) * CFrame.Angles(0.6, 0, -0.6 * s), WHITE, NEON)
			end
			c:light(p.glow, 1.6, 8)
			c:sparkle(p.glow, 6, 1, 0.2)
		end,
	}

	-- A tortoise carrying a whole moon base on its shell: dome, dish, panel, lit windows.
	S.sf_t_tortoise = {
		label = "Moonbase Tortoise",
		set = "starfront",
		tint = C3(92, 200, 112),
		scale = 1.1,
		head = CF(0.20, 1.70, -0.30),
		neck = CF(0, -0.40, 1.10),
		back = CF(0, 0.30, -1.10),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(1.90, 1.30, 2.00),
				snout = { w = 0.60, h = 0.40, d = 0.32, y = -0.14, color = p.pale },
				eyeY = 0.18, eyeSpread = 0.40, eyeSize = V(0.42, 0.50, 0.20),
				legSize = V(0.50, 0.40, 0.50), legX = 0.66, legY = -0.66, tailSize = V(0.24, 0.24, 0.36),
			})
			c:box(V(2.00, 0.50, 1.80), CF(0, 0.92, -0.20), p.dark)
			c:box(V(2.10, 0.12, 1.90), CF(0, 0.66, -0.20), p.deep)
			for _, v in ipairs({ V(1.01, 0.92, -0.50), V(1.01, 0.92, 0.20), V(-1.01, 0.92, -0.20) }) do
				c:box(V(0.04, 0.18, 0.30), CF(v), p.glow, NEON)
			end
			c:ball(V(1.00, 1.00, 1.00), CF(0.20, 1.17, -0.30), p.pale, GLASS)
			c:cyl(V(0.04, 1.04, 1.04), CF(0.20, 1.17, -0.30), p.light, METAL)
			c:rod(V(-0.60, 1.17, -0.70), V(-0.70, 1.62, -0.80), 0.03, p.light, METAL, false)
			c:cyl(V(0.06, 0.50, 0.50), CF(-0.72, 1.66, -0.82) * CFrame.Angles(0.4, 0, 0.9), p.pale)
			c:box(V(0.70, 0.06, 0.44), CF(-0.50, 1.24, 0.40) * CFrame.Angles(0.35, 0, 0), CELLS)
			c:ball(V(0.18, 0.18, 0.18), CF(0.80, 1.26, -0.90), C3(255, 70, 70), NEON)
		end,
	}

	return S
end
