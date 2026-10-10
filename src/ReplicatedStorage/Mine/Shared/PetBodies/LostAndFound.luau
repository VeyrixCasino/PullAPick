--[[ PetBodies/LostAndFound -- Lost & Found's bodies. See tools/gen/sets/README.md.

	A treasure hunter's finds, each a shape a kid knows: a brass pocket compass
	with its lid up, a treasure map rolled at both ends, a message in a bottle,
	an old teapot from the attic and a coin pouch tied at the neck.
]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, METAL, GLASS, WOOD = K.INK, K.METAL, K.GLASS, K.WOOD
	local S = {}

	local GOLD = C3(246, 200, 80)
	local RED = C3(200, 44, 48)
	local UP = CFrame.Angles(0, 0, math.pi / 2) -- a cylinder standing on end
	local FACING = CFrame.Angles(0, math.pi / 2, 0) -- a cylinder facing forward

	-- A pocket compass lying flat: dial and needle on top, lid open behind.
	S.lf_compass = {
		label = "Compass",
		set = "lost_and_found",
		tint = C3(196, 156, 84),
		scale = 1.20,
		head = CFrame.new(0, 2.10, -0.95),
		neck = CFrame.new(0, -0.30, 0.92),
		back = CFrame.new(0, 1.20, -1.10),
		build = function(c, p)
			-- The case, its dial, and the four marks round the dial.
			c:cyl(Vector3.new(0.90, 1.80, 1.80), CFrame.new(0, -0.10, 0) * UP, p.base, METAL)
			c:cyl(Vector3.new(0.06, 1.50, 1.50), CFrame.new(0, 0.37, 0) * UP, C3(242, 232, 204))
			c:box(Vector3.new(0.12, 0.04, 0.22), CFrame.new(0, 0.41, 0.60), RED)
			for _, v in ipairs({ { 0.62, 0 }, { -0.62, 0 }, { 0, -0.62 } }) do
				c:box(Vector3.new(0.10, 0.04, 0.10), CFrame.new(v[1], 0.41, v[2]), p.deep)
			end
			-- The needle, swung a little off north, on a centre pin.
			local pin = CFrame.new(0, 0.44, 0) * CFrame.Angles(0, 0.45, 0)
			c:cone(Vector3.new(0.22, 0.62, 0.08), pin * CFrame.new(0, 0, 0.31) * CFrame.Angles(math.pi / 2, 0, 0), RED)
			c:cone(Vector3.new(0.22, 0.62, 0.08), pin * CFrame.new(0, 0, -0.31) * CFrame.Angles(-math.pi / 2, 0, 0), C3(70, 70, 80))
			c:ball(Vector3.new(0.16, 0.16, 0.16), pin, p.dark, METAL)
			-- The lid standing open behind, a little map inside it, and its hinge.
			c:cyl(Vector3.new(0.14, 1.80, 1.80), CFrame.new(0, 1.24, -0.98) * CFrame.Angles(-0.12, 0, 0) * FACING, p.base, METAL)
			c:cyl(Vector3.new(0.04, 1.44, 1.44), CFrame.new(0, 1.24, -0.90) * CFrame.Angles(-0.12, 0, 0) * FACING, p.pale)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.34, 0.07, 0.04), CFrame.new(0.10, 1.04, -0.84) * CFrame.Angles(-0.12, 0, 0.78 * s), RED)
			end
			c:box(Vector3.new(0.44, 0.16, 0.16), CFrame.new(0, 0.36, -0.90), p.dark, METAL)
			-- Face on the front of the case, and four stubby feet.
			for _, s in ipairs({ -1, 1 }) do
				c:eye(Vector3.new(0.34 * s, -0.04, 0.86), 0.16)
				for _, t in ipairs({ -1, 1 }) do
					c:box(Vector3.new(0.34, 0.24, 0.38), CFrame.new(0.46 * s, -0.64, 0.44 * t), p.deep)
				end
			end
			c:box(Vector3.new(0.30, 0.08, 0.08), CFrame.new(0, -0.32, 0.88), INK)
		end,
	}

	-- A treasure map rolled at the top and bottom: a trail, a mountain, a red X.
	S.lf_map = {
		label = "Map",
		set = "lost_and_found",
		tint = C3(222, 196, 146),
		head = CFrame.new(0, 1.30, 0.04),
		neck = CFrame.new(0, -0.50, 0.36),
		back = CFrame.new(0, 0.10, -0.36),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(2.00, 1.60, 0.50),
				eyeY = 0.24, eyeSpread = 0.34, eyeSize = Vector3.new(0.38, 0.46, 0.16),
				mouthY = -0.12, mouthSize = Vector3.new(0.26, 0.10, 0.10),
				legs = false, tail = false,
			})
			-- The two rolls, with darker ends.
			for _, y in ipairs({ 0.92, -0.80 }) do
				c:cyl(Vector3.new(2.20, 0.60, 0.60), CFrame.new(0, y, 0), p.light)
				for _, s in ipairs({ -1, 1 }) do
					c:cyl(Vector3.new(0.06, 0.62, 0.62), CFrame.new(1.12 * s, y, 0), p.dark)
				end
			end
			-- The map: a mountain, a dotted trail and X marks the spot.
			c:cone(Vector3.new(0.40, 0.32, 0.04), CFrame.new(-0.70, 0.46, 0.27), p.deep)
			for i, v in ipairs({ { -0.36, -0.36 }, { -0.06, -0.48 }, { 0.26, -0.42 } }) do
				c:box(Vector3.new(0.12, 0.05, 0.04), CFrame.new(v[1], v[2], 0.27) * CFrame.Angles(0, 0, i * 0.2 - 0.3), p.deep)
			end
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.36, 0.08, 0.04), CFrame.new(0.62, -0.36, 0.28) * CFrame.Angles(0, 0, 0.78 * s), RED)
				c:box(Vector3.new(0.30, 0.24, 0.36), CFrame.new(0.50 * s, -1.20, 0.10), p.deep)
			end
			-- A wax seal on the back, where a follower sees it.
			c:cyl(Vector3.new(0.10, 0.40, 0.40), CFrame.new(0, 0.06, -0.29) * FACING, C3(170, 40, 48))
		end,
	}

	-- A corked glass bottle with a rolled message and a little sand inside.
	S.lf_bottle = {
		label = "Bottle",
		set = "lost_and_found",
		tint = C3(120, 196, 170),
		head = CFrame.new(0, 1.82, 0.04),
		neck = CFrame.new(0, -0.30, 0.86),
		back = CFrame.new(0, 0.10, -0.86),
		build = function(c, p)
			local _, _, glass = block(c, p, {
				square = true, bodySize = Vector3.new(1.70, 1.70, 1.60),
				eyeY = 0.20, eyeSpread = 0.38, eyeSize = Vector3.new(0.40, 0.50, 0.18),
				mouthY = -0.20, mouthSize = Vector3.new(0.28, 0.12, 0.12),
				legs = false, tail = false,
			})
			glass.Material = GLASS
			glass.Transparency = 0.35
			-- Shoulders, neck, lip and cork.
			for _, row in ipairs({ { 1.36, 0.30, 1.26, 0.98 }, { 0.70, 0.48, 0.70, 1.30 } }) do
				local part = c:box(Vector3.new(row[1], row[2], row[3]), CFrame.new(0, row[4], 0), p.base, GLASS)
				part.Transparency = 0.35
			end
			c:box(Vector3.new(0.84, 0.14, 0.84), CFrame.new(0, 1.50, 0), p.light, GLASS)
			c:box(Vector3.new(0.56, 0.36, 0.56), CFrame.new(0, 1.72, 0), C3(190, 150, 100), WOOD)
			-- Inside: the rolled note with its ribbon, and a bed of sand.
			c:cyl(Vector3.new(1.10, 0.38, 0.38), CFrame.new(0, -0.10, -0.24) * CFrame.Angles(0, 0.3, 0), C3(238, 222, 184))
			c:cyl(Vector3.new(0.10, 0.42, 0.42), CFrame.new(0, -0.10, -0.24) * CFrame.Angles(0, 0.3, 0), RED)
			c:box(Vector3.new(1.50, 0.24, 1.40), CFrame.new(0, -0.66, 0), C3(226, 200, 140))
			-- A starfish stuck to one side, barnacles, and a gleam on the glass.
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.06, 0.40, 0.10), CFrame.new(0.88, 0.10, -0.30) * CFrame.Angles(0.6 * s, 0, 0), C3(240, 140, 80))
				c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.70 * s, -0.78, 0.76 * s), C3(232, 226, 210))
			end
			c:box(Vector3.new(0.08, 0.40, 0.06), CFrame.new(0.88, 0.10, -0.30), C3(240, 140, 80))
			c:box(Vector3.new(0.10, 0.60, 0.04), CFrame.new(-0.66, 0.30, 0.82), C3(240, 250, 250))
		end,
	}

	-- An old teapot: spout, loop handle, a lid with a knob, a painted band.
	S.lf_teapot = {
		label = "Teapot",
		set = "lost_and_found",
		tint = C3(118, 150, 204),
		scale = 1.22,
		head = CFrame.new(0, 1.50, 0.04),
		neck = CFrame.new(0, -0.30, 0.70),
		back = CFrame.new(0, 0.20, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.90, 1.60, 1.80),
				eyeY = 0.18, eyeSpread = 0.40, eyeSize = Vector3.new(0.42, 0.50, 0.20),
				mouthY = -0.24, mouthSize = Vector3.new(0.28, 0.12, 0.12),
				legSize = Vector3.new(0.40, 0.20, 0.44), legX = 0.50, legY = -0.80, legZ = { 0.40, -0.40 },
				legColor = p.dark, tail = false,
			})
			-- Lid, its dome and knob.
			c:box(Vector3.new(1.30, 0.20, 1.20), CFrame.new(0, 0.94, 0), p.light)
			c:box(Vector3.new(0.90, 0.24, 0.84), CFrame.new(0, 1.14, 0), p.light)
			c:ball(Vector3.new(0.32, 0.32, 0.32), CFrame.new(0, 1.38, 0), p.dark)
			-- Spout out to one side, a loop handle on the other.
			c:rod(Vector3.new(0.88, -0.14, 0), Vector3.new(1.42, 0.52, 0), 0.16, p.base)
			c:box(Vector3.new(0.30, 0.12, 0.30), CFrame.new(1.48, 0.66, 0) * CFrame.Angles(0, 0, -0.5), p.base)
			c:box(Vector3.new(0.16, 0.72, 0.24), CFrame.new(-1.32, 0.06, 0), p.base)
			for _, y in ipairs({ 0.38, -0.26 }) do
				c:box(Vector3.new(0.42, 0.16, 0.24), CFrame.new(-1.14, y, 0), p.base)
			end
			-- A painted band with little flowers.
			c:box(Vector3.new(1.94, 0.14, 1.84), CFrame.new(0, -0.56, 0), p.pale)
			for _, x in ipairs({ -0.50, 0, 0.50 }) do
				c:box(Vector3.new(0.14, 0.14, 0.06), CFrame.new(x, -0.56, 0.93) * CFrame.Angles(0, 0, 0.78), p.deep)
			end
		end,
	}

	-- A cloth coin pouch, cinched with a gold cord, coins peeking out of the top.
	S.lf_pouch = {
		label = "Pouch",
		set = "lost_and_found",
		tint = C3(150, 104, 70),
		head = CFrame.new(0, 1.62, 0.04),
		neck = CFrame.new(0, -0.30, 0.66),
		back = CFrame.new(0, 0.20, -0.66),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.96, 1.70, 1.80),
				eyeY = 0.10, eyeSpread = 0.40, eyeSize = Vector3.new(0.42, 0.50, 0.20),
				mouthY = -0.30, mouthSize = Vector3.new(0.30, 0.12, 0.12),
				legSize = Vector3.new(0.40, 0.26, 0.44), legX = 0.52, legY = -0.86,
				legColor = p.deep, tail = false,
			})
			-- Cinched neck, gold cord and knot, and the ruffled mouth of the bag.
			c:box(Vector3.new(1.00, 0.26, 0.96), CFrame.new(0, 1.00, 0), p.dark)
			c:box(Vector3.new(1.06, 0.08, 1.02), CFrame.new(0, 1.00, 0), GOLD)
			c:box(Vector3.new(0.24, 0.18, 0.14), CFrame.new(0.18, 1.00, 0.54), GOLD)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.08, 0.08, 0.40), CFrame.new(0.18 + 0.08 * s, 0.90, 0.70) * CFrame.Angles(0.6, 0, 0), GOLD)
			end
			c:box(Vector3.new(1.40, 0.40, 1.30), CFrame.new(0, 1.30, 0), p.base)
			c:box(Vector3.new(1.12, 0.04, 1.02), CFrame.new(0, 1.51, 0), p.deep)
			-- Coins poking out of the top.
			for _, v in ipairs({ { 0.20, 1.62, 0.10, 0.3 }, { -0.24, 1.60, -0.10, -0.4 }, { 0.02, 1.66, -0.30, 0.1 } }) do
				c:cyl(Vector3.new(0.06, 0.44, 0.44), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0, math.pi / 2 + v[4], v[4]), GOLD, METAL)
			end
			-- A sewn-on patch on one side.
			c:box(Vector3.new(0.06, 0.50, 0.50), CFrame.new(1.03, -0.10, -0.20), p.light)
			for _, y in ipairs({ 0.14, -0.34 }) do
				c:box(Vector3.new(0.07, 0.04, 0.44), CFrame.new(1.04, y, -0.20), p.deep)
			end
		end,
	}

	return S
end
