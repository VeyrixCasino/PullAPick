--[[ PetBodies/Starfront -- Starfront's bodies: grounded space exploration
	(suits, rovers, orbital hardware, planets). See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block = K.C3, K.block
	local WHITE, METAL, NEON, GLASS = K.WHITE, K.METAL, K.NEON, K.GLASS
	local S = {}

	local FACE_Z = CFrame.Angles(0, math.pi / 2, 0) -- turns a cylinder's X axis to face +Z
	local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2) -- stands a cylinder's X axis up

	-- A puffy spacesuit with a round dark visor, a life-support pack and an antenna.
	S.sf_astronaut = {
		label = "Astronaut",
		set = "starfront",
		tint = C3(232, 236, 244),
		head = CFrame.new(0, 1.04, 0.06),
		neck = CFrame.new(0, -0.30, 0.66),
		back = CFrame.new(0, 0.20, -1.26),
		build = function(c, p)
			block(c, p, {
				shape = "round",
				eyeColor = C3(130, 236, 255), eyeSize = Vector3.new(0.42, 0.52, 0.20), eyeSpread = 0.34, eyeY = 0.16,
				mouth = false, tail = false,
				legSize = Vector3.new(0.52, 0.40, 0.60), legColor = p.dark,
			})
			-- Helmet ring, the dark visor the face looks out of, and a glint on it.
			c:cyl(Vector3.new(0.10, 1.62, 1.62), CFrame.new(0, 0.16, 0.90) * FACE_Z, p.dark)
			c:cyl(Vector3.new(0.12, 1.38, 1.38), CFrame.new(0, 0.16, 0.93) * FACE_Z, C3(34, 46, 84), GLASS)
			c:box(Vector3.new(0.10, 0.34, 0.04), CFrame.new(-0.40, 0.56, 1.00) * CFrame.Angles(0, 0, 0.7), WHITE)
			-- Chest control box with three lit buttons.
			c:box(Vector3.new(0.80, 0.30, 0.14), CFrame.new(0, -0.66, 0.80), p.light)
			for i, col in ipairs({ C3(255, 84, 84), C3(255, 210, 70), C3(90, 224, 120) }) do
				c:box(Vector3.new(0.13, 0.13, 0.06), CFrame.new((i - 2) * 0.22, -0.66, 0.88), col, NEON)
			end
			-- Life-support pack with two vents, and a whip antenna with a beacon.
			c:box(Vector3.new(1.40, 1.30, 0.44), CFrame.new(0, 0.16, -0.98), p.light)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.30, 0.74, 0.06), CFrame.new(0.36 * s, 0.12, -1.21), p.dark)
			end
			c:rod(Vector3.new(0.46, 0.78, -0.98), Vector3.new(0.46, 1.42, -0.98), 0.04, p.dark, METAL, false)
			c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.46, 1.48, -0.98), C3(255, 70, 70), NEON)
			-- Stubby suit arms with chunky gloves.
			for _, s in ipairs({ -1, 1 }) do
				c:ovoid(Vector3.new(0.38, 0.72, 0.50), CFrame.new(1.06 * s, -0.12, 0.10) * CFrame.Angles(0, 0, 0.22 * s), p.base)
				c:ovoid(Vector3.new(0.40, 0.30, 0.46), CFrame.new(1.16 * s, -0.52, 0.14), p.dark)
			end
		end,
	}

	-- A six-wheeled surface rover: camera-lens eyes, a solar deck and a camera mast.
	S.sf_rover = {
		label = "Rover",
		set = "starfront",
		tint = C3(224, 206, 166),
		head = CFrame.new(0, 0.80, 0.06),
		neck = CFrame.new(0, -0.24, 0.80),
		back = CFrame.new(0, 0.30, -0.98),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(2.00, 1.24, 1.90),
				eyeY = 0.04, eyeSpread = 0.46, eyeSize = Vector3.new(0.40, 0.40, 0.18),
				mouthY = -0.34, mouthSize = Vector3.new(0.34, 0.10, 0.12),
				legs = false, tail = false,
			})
			local tyre = C3(54, 52, 60)
			for _, s in ipairs({ -1, 1 }) do
				-- Lens bezels round the eyes.
				c:cyl(Vector3.new(0.10, 0.58, 0.58), CFrame.new(0.46 * s, 0.04, 0.97) * FACE_Z, p.dark, METAL)
				-- Three wheels a side under a rocker bar.
				for _, z in ipairs({ 0.62, 0, -0.62 }) do
					c:cyl(Vector3.new(0.30, 0.60, 0.60), CFrame.new(1.14 * s, -0.62, z), tyre)
					c:cyl(Vector3.new(0.34, 0.24, 0.24), CFrame.new(1.14 * s, -0.62, z), p.light, METAL)
				end
				c:box(Vector3.new(0.16, 0.14, 1.50), CFrame.new(1.14 * s, -0.24, 0), p.deep)
			end
			-- Solar deck with its cell grid.
			c:box(Vector3.new(2.36, 0.08, 1.70), CFrame.new(0, 0.72, -0.08), C3(44, 70, 150))
			c:box(Vector3.new(2.38, 0.10, 0.05), CFrame.new(0, 0.73, -0.08), p.light)
			for _, x in ipairs({ -0.60, 0, 0.60 }) do
				c:box(Vector3.new(0.05, 0.10, 1.72), CFrame.new(x, 0.73, -0.08), p.light)
			end
			-- Camera mast at the rear corner, looking forward.
			c:rod(Vector3.new(0.78, 0.76, -0.66), Vector3.new(0.78, 1.30, -0.66), 0.07, p.light, METAL, false)
			c:box(Vector3.new(0.50, 0.28, 0.34), CFrame.new(0.78, 1.40, -0.62), p.base)
			c:cyl(Vector3.new(0.10, 0.16, 0.16), CFrame.new(0.78, 1.40, -0.42) * FACE_Z, C3(120, 230, 255), NEON)
			-- Front bumper.
			c:box(Vector3.new(1.60, 0.16, 0.14), CFrame.new(0, -0.48, 1.00), p.deep)
		end,
	}

	-- A gold-foil satellite: two solar panels held out like wings, a dish on its back.
	S.sf_satellite = {
		label = "Satellite",
		set = "starfront",
		tint = C3(226, 180, 70),
		-- The panels make it the widest body in the set; scaled back up so the
		-- bus reads the size of every other pet.
		scale = 1.32,
		head = CFrame.new(0, 1.04, 0.30),
		neck = CFrame.new(0, -0.30, 0.62),
		back = CFrame.new(0, 0.20, -1.24),
		build = function(c, p)
			block(c, p, { square = true, legs = false, tail = false, mouthSize = Vector3.new(0.30, 0.12, 0.12) })
			local frame, cells = C3(196, 202, 214), C3(48, 80, 168)
			-- Foil seam round the bus.
			c:box(Vector3.new(2.06, 0.08, 1.84), CFrame.new(0, -0.54, 0), p.light)
			for _, s in ipairs({ -1, 1 }) do
				c:rod(Vector3.new(1.00 * s, 0.10, -0.10), Vector3.new(1.30 * s, 0.10, -0.10), 0.07, frame, METAL, false)
				c:box(Vector3.new(0.72, 1.10, 0.08), CFrame.new(1.62 * s, 0.10, -0.10), p.dark)
				for _, k in ipairs({ -1, 1 }) do
					c:box(Vector3.new(0.30, 0.98, 0.10), CFrame.new((1.62 + 0.17 * k) * s, 0.10, -0.10), cells)
				end
			end
			-- Dish on a stalk, tilted up and back, with a lit feed horn.
			local dish = CFrame.new(0, 1.30, -0.62) * CFrame.Angles(-0.55, 0, 0)
			c:rod(Vector3.new(0, 0.98, -0.52), dish.Position, 0.06, frame, METAL, false)
			c:cyl(Vector3.new(0.10, 1.00, 1.00), dish * UPRIGHT, p.pale)
			c:rod(dish.Position, (dish * CFrame.new(0, 0.40, 0)).Position, 0.035, frame, METAL, false)
			c:ball(Vector3.new(0.14, 0.14, 0.14), dish * CFrame.new(0, 0.44, 0), p.glow, NEON)
			-- Thruster bell behind, and a status light.
			c:cone(Vector3.new(0.56, 0.40, 0.56), CFrame.new(0, 0.06, -1.06) * CFrame.Angles(math.pi / 2, 0, 0), p.deep, METAL)
			c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.72, 1.02, 0.72), C3(90, 255, 120), NEON)
		end,
	}

	-- A little rocket: nose cone, four fins, a porthole and a puff of flame.
	S.sf_rocket = {
		label = "Rocket",
		set = "starfront",
		tint = C3(228, 72, 64),
		-- Nose and flame make it tall, which FIT_SIZE shrinks.
		scale = 1.30,
		head = CFrame.new(0, 1.84, 0.02),
		neck = CFrame.new(0, -0.30, 0.60),
		back = CFrame.new(0, 0.20, -0.96),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.76, 1.80, 1.76),
				eyeY = 0.20, eyeSpread = 0.38, eyeSize = Vector3.new(0.48, 0.58, 0.20),
				mouthY = -0.24, legs = false, tail = false,
			})
			-- Nose cone on a collar, tipped with a beacon.
			c:box(Vector3.new(1.86, 0.16, 1.86), CFrame.new(0, 0.96, 0), p.dark)
			c:cone(Vector3.new(1.56, 0.86, 1.56), CFrame.new(0, 1.47, 0), p.light)
			c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0, 1.86, 0), C3(255, 220, 90), NEON)
			-- Stripe round the hull.
			c:box(Vector3.new(1.82, 0.20, 1.82), CFrame.new(0, -0.56, 0), p.pale)
			-- Four swept fins on the diagonals, tall edge against the hull.
			for i = 0, 3 do
				local a = math.pi / 4 + i * math.pi / 2
				local ox, oz = math.cos(a), math.sin(a)
				c:wedge(
					Vector3.new(0.12, 0.90, 0.66),
					CFrame.new(ox * 1.40, -0.66, oz * 1.40) * CFrame.Angles(0, math.atan2(-ox, -oz), 0),
					p.dark
				)
			end
			-- Engine bell and flame.
			c:cone(Vector3.new(0.90, 0.36, 0.90), CFrame.new(0, -1.00, 0), p.deep, METAL)
			c:cone(Vector3.new(0.58, 0.46, 0.58), CFrame.new(0, -1.40, 0) * CFrame.Angles(math.pi, 0, 0), C3(255, 150, 40), NEON)
			c:cone(Vector3.new(0.34, 0.30, 0.34), CFrame.new(0, -1.30, 0) * CFrame.Angles(math.pi, 0, 0), C3(255, 236, 120), NEON)
			-- Porthole on the back, for the view from behind.
			c:cyl(Vector3.new(0.08, 0.60, 0.60), CFrame.new(0, 0.30, -0.89) * FACE_Z, p.dark, METAL)
			c:cyl(Vector3.new(0.10, 0.42, 0.42), CFrame.new(0, 0.30, -0.89) * FACE_Z, C3(140, 210, 255), GLASS)
			c:light(C3(255, 170, 60), 1.6, 7)
		end,
	}

	-- A small ringed planet with banded cloud tops, craters and its own pet moon.
	S.sf_planet = {
		label = "Planet",
		set = "starfront",
		tint = C3(232, 170, 98),
		-- The ring is the widest thing on it.
		scale = 1.22,
		head = CFrame.new(0, 1.04, 0.06),
		neck = CFrame.new(0, -0.20, 0.70),
		back = CFrame.new(0, 0.20, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "round", legs = false, tail = false,
				mouthY = -0.24, mouthSize = Vector3.new(0.34, 0.12, 0.14),
			})
			-- Cloud bands above the eyes and below the mouth.
			c:box(Vector3.new(1.76, 0.18, 1.56), CFrame.new(0, 0.70, 0), p.dark)
			c:box(Vector3.new(1.80, 0.18, 1.56), CFrame.new(0, -0.58, 0), p.light)
			-- The ring: three discs through the body, tilted so it passes under the face.
			local ring = CFrame.new(0, -0.26, 0) * CFrame.Angles(0.22, 0, 0.12) * UPRIGHT
			c:cyl(Vector3.new(0.06, 3.00, 3.00), ring, p.pale)
			c:cyl(Vector3.new(0.07, 2.72, 2.72), ring, p.dark)
			c:cyl(Vector3.new(0.08, 2.50, 2.50), ring, p.light)
			-- Craters on the back and crown.
			c:box(Vector3.new(0.36, 0.36, 0.08), CFrame.new(-0.40, 0.30, -0.88), p.deep)
			c:box(Vector3.new(0.28, 0.28, 0.08), CFrame.new(0.38, -0.10, -0.88), p.deep)
			c:box(Vector3.new(0.34, 0.08, 0.34), CFrame.new(0.30, 0.97, -0.24), p.deep)
			-- A tiny moon keeping it company.
			local moon = CFrame.new(1.30, 0.86, -0.36) * CFrame.Angles(0.4, 0.6, 0.2)
			c:box(Vector3.new(0.40, 0.40, 0.40), moon, C3(206, 206, 214))
			c:box(Vector3.new(0.16, 0.16, 0.06), moon * CFrame.new(0.06, 0.06, 0.20), C3(150, 150, 162))
		end,
	}

	return S
end
