--[[ PetBodies/ArcadeLegends -- Arcade Legends' bodies: retro games, pixel art and
	neon. See tools/gen/sets/README.md. ]]
return function(K)
	local C3 = K.C3
	local INK, WHITE, METAL, NEON = K.INK, K.WHITE, K.METAL, K.NEON
	local S = {}

	local FACE_Z = CFrame.Angles(0, math.pi / 2, 0) -- turns a cylinder's X axis to face +Z
	local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2) -- stands a cylinder's X axis up
	local DARK_KEY = C3(44, 44, 56)

	-- A pixel-art face: two square eyes with a highlight pixel, and a stepped smile.
	-- `at` is the CFrame of the face's centre, facing +Z; `u` is one pixel.
	local function pixelFace(c, at, u, spread, eyeCol)
		for _, s in ipairs({ -1, 1 }) do
			c:box(Vector3.new(u, u * 1.25, 0.06), at * CFrame.new(spread * s, u * 0.6, 0), eyeCol or INK):SetAttribute("Eye", true)
			c:box(Vector3.new(u * 0.4, u * 0.4, 0.04), at * CFrame.new(spread * s + u * 0.22, u * 0.95, 0.03), WHITE):SetAttribute("Eye", true)
			c:box(Vector3.new(u * 0.5, u * 0.5, 0.06), at * CFrame.new(u * 0.75 * s, -u * 0.7, 0), eyeCol or INK)
		end
		c:box(Vector3.new(u, u * 0.5, 0.06), at * CFrame.new(0, -u * 1.1, 0), eyeCol or INK)
	end

	-- An upright arcade cabinet: glowing marquee, a screen for a face, a control
	-- panel with a joystick and buttons, and a coin door.
	S.al_cabinet = {
		label = "Cabinet",
		set = "arcade_legends",
		tint = C3(122, 70, 206),
		head = CFrame.new(0, 1.30, -0.10),
		neck = CFrame.new(0, -0.40, 0.84),
		back = CFrame.new(0, 0.20, -0.86),
		build = function(c, p)
			-- The cabinet: tall rear block, a lower front, cheeks framing the screen, feet.
			c:box(Vector3.new(1.80, 2.30, 1.10), CFrame.new(0, 0.10, -0.26), p.base)
			c:box(Vector3.new(1.80, 0.96, 0.50), CFrame.new(0, -0.57, 0.53), p.base)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.12, 0.98, 0.40), CFrame.new(0.86 * s, 0.40, 0.46), p.dark)
				for _, z in ipairs({ 0.40, -0.56 }) do
					c:box(Vector3.new(0.40, 0.16, 0.40), CFrame.new(0.58 * s, -1.11, z), p.deep)
				end
				-- Neon side-art stripe.
				c:box(Vector3.new(0.04, 0.12, 1.30), CFrame.new(0.91 * s, -0.36, -0.12) * CFrame.Angles(0.42, 0, 0), p.glow, NEON)
			end
			-- Screen, tilted back in its bezel, with a pixel face on it.
			local scr = CFrame.new(0, 0.44, 0.34) * CFrame.Angles(-0.14, 0, 0)
			c:box(Vector3.new(1.62, 0.86, 0.10), scr, p.deep)
			c:box(Vector3.new(1.40, 0.68, 0.08), scr * CFrame.new(0, 0, 0.04), C3(18, 22, 46))
			pixelFace(c, scr * CFrame.new(0, 0.04, 0.09), 0.17, 0.30, C3(110, 255, 160))
			-- Marquee overhang with its light.
			c:box(Vector3.new(1.80, 0.38, 0.50), CFrame.new(0, 1.07, 0.48), p.dark)
			c:box(Vector3.new(1.50, 0.24, 0.06), CFrame.new(0, 1.07, 0.74), p.glow, NEON)
			-- Control panel, joystick and three buttons.
			c:box(Vector3.new(1.90, 0.20, 0.64), CFrame.new(0, -0.02, 0.62) * CFrame.Angles(0.18, 0, 0), p.dark)
			c:rod(Vector3.new(-0.42, 0.06, 0.66), Vector3.new(-0.42, 0.38, 0.66), 0.045, DARK_KEY, nil, false)
			c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(-0.42, 0.42, 0.66), C3(236, 52, 70))
			for i, col in ipairs({ C3(255, 220, 60), C3(80, 220, 120), C3(70, 150, 255) }) do
				c:cyl(Vector3.new(0.08, 0.16, 0.16), CFrame.new(0.02 + i * 0.20, 0.11, 0.66) * UPRIGHT, col)
			end
			-- Coin door with two lit slots.
			c:box(Vector3.new(0.56, 0.44, 0.04), CFrame.new(0, -0.58, 0.79), p.deep)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.06, 0.18, 0.04), CFrame.new(0.12 * s, -0.52, 0.81), C3(255, 160, 40), NEON)
			end
			-- Vent slats on the back.
			for _, y in ipairs({ 0.50, 0.20 }) do
				c:box(Vector3.new(1.00, 0.08, 0.04), CFrame.new(0, y, -0.83), p.deep)
			end
			c:light(p.glow, 1.4, 7)
		end,
	}

	-- A gamepad standing up: D-pad and four buttons either side of its face,
	-- the two grips splayed as legs, and its cable for a tail.
	S.al_gamepad = {
		label = "Gamepad",
		set = "arcade_legends",
		tint = C3(92, 100, 226),
		head = CFrame.new(0, 0.98, 0),
		neck = CFrame.new(0, -0.14, 0.52),
		back = CFrame.new(0, 0.40, -0.52),
		build = function(c, p)
			c:box(Vector3.new(2.36, 1.04, 0.92), CFrame.new(0, 0.34, 0), p.base)
			for _, s in ipairs({ -1, 1 }) do
				local grip = CFrame.new(0.82 * s, -0.40, -0.02) * CFrame.Angles(0, 0, 0.22 * s)
				c:box(Vector3.new(0.72, 1.06, 0.84), grip, p.base)
				c:box(Vector3.new(0.62, 0.22, 0.80), grip * CFrame.new(0, -0.52, 0), p.dark)
				-- Shoulder buttons, thumbsticks, start and select.
				c:box(Vector3.new(0.74, 0.14, 0.60), CFrame.new(0.78 * s, 0.90, -0.08), p.dark)
				c:cyl(Vector3.new(0.12, 0.26, 0.26), CFrame.new(0.42 * s, 0.02, 0.50) * FACE_Z, DARK_KEY)
				c:box(Vector3.new(0.14, 0.06, 0.04), CFrame.new(0.14 * s, 0.76, 0.47), p.dark)
				-- Eyes.
				c:round(Vector3.new(0.24, 0.32, 0.10), CFrame.new(0.22 * s, 0.44, 0.48), INK):SetAttribute("Eye", true)
				c:round(Vector3.new(0.08, 0.10, 0.06), CFrame.new(0.22 * s + 0.05, 0.52, 0.53), WHITE):SetAttribute("Eye", true)
			end
			c:box(Vector3.new(0.20, 0.06, 0.06), CFrame.new(0, 0.22, 0.47), INK)
			-- D-pad on the left.
			c:box(Vector3.new(0.46, 0.15, 0.08), CFrame.new(-0.78, 0.40, 0.48), DARK_KEY)
			c:box(Vector3.new(0.15, 0.46, 0.08), CFrame.new(-0.78, 0.40, 0.48), DARK_KEY)
			-- Four face buttons on the right.
			for _, b in ipairs({
				{ 0, 0.16, C3(255, 210, 60) }, { 0.16, 0, C3(236, 60, 70) },
				{ 0, -0.16, C3(80, 210, 110) }, { -0.16, 0, C3(70, 140, 255) },
			}) do
				c:cyl(Vector3.new(0.08, 0.15, 0.15), CFrame.new(0.78 + b[1], 0.40 + b[2], 0.48) * FACE_Z, b[3])
			end
			-- Player light.
			c:box(Vector3.new(0.12, 0.06, 0.04), CFrame.new(0, 0.62, 0.47), p.glow, NEON)
			-- Cable tail ending in a plug.
			local bend = Vector3.new(0, 0.88, -0.90)
			c:rod(Vector3.new(0, 0.70, -0.44), bend, 0.05, DARK_KEY, nil, false)
			c:ball(Vector3.new(0.10, 0.10, 0.10), CFrame.new(bend), DARK_KEY)
			c:rod(bend, Vector3.new(0.10, 0.56, -1.26), 0.05, DARK_KEY, nil, false)
			c:box(Vector3.new(0.18, 0.26, 0.14), CFrame.new(0.12, 0.46, -1.30) * CFrame.Angles(0.5, 0, 0), C3(200, 204, 214), METAL)
		end,
	}

	-- An arcade token on its edge: a milled rim, a smiling face, a star on the
	-- back, and little cartoon arms and shoes.
	S.al_token = {
		label = "Token",
		set = "arcade_legends",
		tint = C3(244, 192, 56),
		head = CFrame.new(0, 1.26, 0),
		neck = CFrame.new(0, -0.62, 0.40),
		back = CFrame.new(0, 0.16, -0.40),
		build = function(c, p)
			local centre = CFrame.new(0, 0.16, 0)
			c:cyl(Vector3.new(0.56, 2.10, 2.10), centre * FACE_Z, p.base, METAL)
			c:cyl(Vector3.new(0.66, 1.70, 1.70), centre * FACE_Z, p.light, METAL)
			-- Milled edge.
			for i = 0, 11 do
				c:box(Vector3.new(0.07, 0.12, 0.58), centre * CFrame.Angles(0, 0, i * math.pi / 6) * CFrame.new(0, 1.06, 0), p.dark, METAL)
			end
			-- Face.
			for _, s in ipairs({ -1, 1 }) do
				c:round(Vector3.new(0.34, 0.44, 0.12), CFrame.new(0.30 * s, 0.36, 0.36), INK):SetAttribute("Eye", true)
				c:round(Vector3.new(0.12, 0.14, 0.06), CFrame.new(0.30 * s + 0.07, 0.46, 0.42), WHITE):SetAttribute("Eye", true)
				c:box(Vector3.new(0.20, 0.10, 0.04), CFrame.new(0.56 * s, 0.10, 0.35), C3(255, 140, 120))
			end
			c:box(Vector3.new(0.40, 0.08, 0.06), CFrame.new(0, -0.02, 0.35), INK)
			-- A five-point star stamped on the back.
			local stamp = centre * CFrame.new(0, 0, -0.34)
			c:cyl(Vector3.new(0.04, 0.42, 0.42), stamp * FACE_Z, p.dark, METAL)
			for i = 0, 4 do
				c:cone(Vector3.new(0.30, 0.44, 0.04), stamp * CFrame.Angles(0, 0, i * math.pi * 2 / 5) * CFrame.new(0, 0.36, 0), p.dark, METAL)
			end
			-- Arms with white gloves, legs with red shoes.
			for _, s in ipairs({ -1, 1 }) do
				c:rod(Vector3.new(0.98 * s, 0.10, 0), Vector3.new(1.18 * s, -0.18, 0.08), 0.07, DARK_KEY, nil, false)
				c:ball(Vector3.new(0.26, 0.26, 0.26), CFrame.new(1.22 * s, -0.22, 0.10), WHITE)
				c:rod(Vector3.new(0.34 * s, -0.80, 0), Vector3.new(0.38 * s, -1.06, 0.02), 0.07, DARK_KEY, nil, false)
				c:box(Vector3.new(0.30, 0.16, 0.40), CFrame.new(0.40 * s, -1.12, 0.08), C3(230, 60, 70))
			end
		end,
	}

	-- An 8-bit heart with stepped pixel wings: the extra life.
	S.al_heartbit = {
		label = "Pixel Heart",
		set = "arcade_legends",
		tint = C3(236, 56, 84),
		-- The wings make it wide.
		scale = 1.28,
		head = CFrame.new(0, 1.00, 0.02),
		neck = CFrame.new(0, -0.40, 0.62),
		back = CFrame.new(0, 0.30, -0.62),
		build = function(c, p)
			local u, D = 0.30, 1.10
			-- Rows, top down: { centre column, width in pixels, row }.
			local rows = { { -1.5, 2, 0 }, { 1.5, 2, 0 }, { 0, 7, 1.5 }, { 0, 5, 3 }, { 0, 3, 4 }, { 0, 1, 5 } }
			for _, r in ipairs(rows) do
				local h = r[3] == 1.5 and 2 or 1
				local cf = CFrame.new(r[1] * u, 0.81 - r[3] * u, 0)
				c:box(Vector3.new(r[2] * u, h * u, D), cf, p.base)
				-- Dark pixel outline, set back so it only shows round the edge.
				c:box(Vector3.new(r[2] * u + 0.12, h * u + 0.12, D - 0.08), cf * CFrame.new(0, 0, -0.04), p.deep)
			end
			-- Highlight pixels on the upper left lobe.
			c:box(Vector3.new(u, u, 0.04), CFrame.new(-2 * u, 0.81 - u, D * 0.5 + 0.01), p.pale)
			c:box(Vector3.new(u * 0.6, u * 0.6, 0.04), CFrame.new(-u * 1.2, 0.81, D * 0.5 + 0.01), p.pale)
			pixelFace(c, CFrame.new(0, 0.12, D * 0.5 + 0.02), 0.22, 0.30)
			-- Stepped pixel wings, fanned like feathers: longest row on top,
			-- swept a little back.
			local w = 0.24
			for _, s in ipairs({ -1, 1 }) do
				local root = CFrame.new(1.08 * s, 0, -0.16) * CFrame.Angles(0, 0.35 * s, 0)
				for i, n in ipairs({ 3, 2, 1 }) do
					c:box(Vector3.new(n * w, w, 0.30), root * CFrame.new(n * w * 0.5 * s, 1.00 - (i - 1) * w, 0), WHITE)
				end
			end
			c:light(p.glow, 1.6, 8)
		end,
	}

	-- A pixel beetle: a stepped shell, square eyes, stair-step antennae with
	-- lit tips, and six blocky legs.
	S.al_bitbug = {
		label = "Bitbug",
		set = "arcade_legends",
		tint = C3(90, 220, 110),
		scale = 1.10,
		head = CFrame.new(0, 0.70, -0.08),
		neck = CFrame.new(0, -0.40, 0.84),
		back = CFrame.new(0, 0.10, -0.84),
		build = function(c, p)
			-- Three stepped slabs: belly and face, shell, crown.
			c:box(Vector3.new(1.92, 0.64, 1.60), CFrame.new(0, -0.30, 0), p.light)
			c:box(Vector3.new(1.60, 0.32, 1.36), CFrame.new(0, 0.18, -0.04), p.base)
			c:box(Vector3.new(0.96, 0.32, 1.04), CFrame.new(0, 0.50, -0.08), p.base)
			-- Shell spots.
			for _, v in ipairs({ { -0.56, 0.36, -0.36 }, { 0.56, 0.36, -0.36 }, { 0, 0.68, -0.30 } }) do
				c:box(Vector3.new(0.24, 0.06, 0.24), CFrame.new(v[1], v[2], v[3]), p.deep)
			end
			pixelFace(c, CFrame.new(0, -0.28, 0.82), 0.22, 0.36)
			for _, s in ipairs({ -1, 1 }) do
				-- Antennae, one pixel at a time.
				c:box(Vector3.new(0.16, 0.30, 0.16), CFrame.new(0.24 * s, 0.81, 0.24), p.dark)
				c:box(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.40 * s, 1.02, 0.30), p.dark)
				c:box(Vector3.new(0.22, 0.22, 0.22), CFrame.new(0.56 * s, 1.18, 0.34), p.glow, NEON)
				-- Six L-shaped legs.
				for _, z in ipairs({ 0.50, 0, -0.50 }) do
					c:box(Vector3.new(0.40, 0.20, 0.20), CFrame.new(1.12 * s, -0.48, z), p.dark)
					c:box(Vector3.new(0.20, 0.36, 0.20), CFrame.new(1.26 * s, -0.68, z), p.dark)
				end
			end
		end,
	}

	return S
end
