--[[ PetBodies/SugarRushExtra -- more Sugar Rush recolour bodies. See tools/gen/sets/README.md.

	Common, Uncommon and Rare pets share bodies, and two pets on one body must
	be vastly different colours. These four give the set's everyday pets more
	room: a sugar-coated gumdrop, a sugar mouse with a string tail, a frosted
	puppy and a foil-striped candy egg on chick feet.
]]
return function(K)
	local C3, block, ears = K.C3, K.block, K.ears
	local INK, WHITE, NEON, GLASS = K.INK, K.WHITE, K.NEON, K.GLASS
	local S = {}

	local BLUSH = C3(255, 150, 182)
	local SPRINKLES = { C3(255, 90, 110), C3(90, 190, 255), C3(255, 220, 80), C3(140, 230, 120), C3(200, 120, 255) }
	local ORANGE = C3(255, 166, 62)

	-- Rosy cheeks either side of a face.
	local function blush(c, x, y, z)
		for _, s in ipairs({ -1, 1 }) do
			c:box(Vector3.new(0.22, 0.12, 0.06), CFrame.new(x * s, y, z), BLUSH)
		end
	end

	-- Sprinkles: { x, y, z, roll } rows, colours cycling through the jar.
	local function sprinkles(c, list)
		for i, v in ipairs(list) do
			c:box(Vector3.new(0.18, 0.06, 0.06), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0, v[5] or 0, v[4]), SPRINKLES[(i - 1) % #SPRINKLES + 1])
		end
	end

	-- A stepped, sugar-coated gumdrop dome on two stubby feet.
	S.sr_gumdrop = {
		label = "Gumdrop",
		set = "sugar_rush",
		tint = C3(120, 220, 90),
		head = CFrame.new(0, 1.42, 0.02),
		neck = CFrame.new(0, -0.28, 0.82),
		back = CFrame.new(0, 0.10, -0.82),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.90, 1.10, 1.80),
				eyeY = 0.02, eyeSpread = 0.40, eyeSize = Vector3.new(0.40, 0.48, 0.18),
				mouthY = -0.28, mouthSize = Vector3.new(0.28, 0.12, 0.12),
				legSize = Vector3.new(0.44, 0.22, 0.50), legX = 0.46, legY = -0.58, legZ = { 0.20 },
				legColor = p.deep, tail = false,
			})
			-- The dome, in steps, and a glossy cap.
			c:box(Vector3.new(1.56, 0.40, 1.48), CFrame.new(0, 0.80, 0), p.base)
			c:box(Vector3.new(1.08, 0.30, 1.02), CFrame.new(0, 1.12, 0), p.base)
			c:box(Vector3.new(0.56, 0.18, 0.54), CFrame.new(0, 1.34, 0), p.light)
			-- Sugar crystals stuck all over the outside.
			for _, v in ipairs({
				{ -0.70, 0.40, 0.91 }, { 0.62, 0.48, 0.91 }, { 0.96, 0.20, 0.30 }, { -0.96, 0.10, -0.30 },
				{ 0.30, 1.01, 0.60 }, { -0.44, 1.28, 0.30 }, { 0.20, 1.44, -0.10 },
			}) do
				c:box(Vector3.new(0.12, 0.12, 0.12), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0.5, 0.5, 0), p.pale)
			end
			blush(c, 0.62, -0.18, 0.91)
		end,
	}

	-- A teardrop sugar mouse: pointed sugar nose, round ears, a string tail.
	S.sr_sugarmouse = {
		label = "Sugar Mouse",
		set = "sugar_rush",
		tint = C3(255, 170, 200),
		head = CFrame.new(0, 0.92, 0.00),
		neck = CFrame.new(0, -0.30, 0.90),
		back = CFrame.new(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.70, 1.44, 1.90),
				snout = { w = 0.54, h = 0.40, d = 0.56, y = -0.16, color = p.light, nose = C3(255, 110, 150) },
				eyeY = 0.18, eyeSpread = 0.36, eyeSize = Vector3.new(0.36, 0.44, 0.18),
				legSize = Vector3.new(0.30, 0.18, 0.36), legX = 0.44, legY = -0.70, legZ = { 0.44, -0.40 },
				legColor = p.dark, tail = false,
			})
			-- The point of a sugar mouse runs back along its spine.
			c:box(Vector3.new(0.70, 0.24, 1.30), CFrame.new(0, 0.86, -0.20), p.base)
			for _, s in ipairs({ -1, 1 }) do
				c:round(Vector3.new(0.58, 0.58, 0.16), CFrame.new(0.50 * s, 1.02, 0.18) * CFrame.Angles(0, 0, -0.20 * s), p.base)
				c:round(Vector3.new(0.32, 0.32, 0.10), CFrame.new(0.50 * s, 1.00, 0.27) * CFrame.Angles(0, 0, -0.20 * s), BLUSH)
				c:box(Vector3.new(0.40, 0.03, 0.03), CFrame.new(0.44 * s, -0.12, 1.14) * CFrame.Angles(0, 0, 0.18 * s), WHITE)
			end
			-- The string tail, looping up behind.
			local twine = C3(236, 224, 210)
			c:rod(Vector3.new(0, -0.30, -0.92), Vector3.new(0.10, -0.10, -1.30), 0.04, twine, nil, false)
			c:rod(Vector3.new(0.10, -0.10, -1.30), Vector3.new(0.30, 0.40, -1.40), 0.04, twine, nil, false)
			blush(c, 0.44, -0.12, 0.93)
		end,
	}

	-- A puppy wearing a cap of frosting that drips down its sides.
	S.sr_sprinklepup = {
		label = "Sprinkle Pup",
		set = "sugar_rush",
		tint = C3(180, 130, 255),
		head = CFrame.new(0, 1.22, 0.06),
		neck = CFrame.new(0, -0.36, 0.70),
		back = CFrame.new(0, 0.30, -0.66),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				snout = { w = 0.62, h = 0.44, d = 0.44, y = -0.22, color = p.pale },
				eyeY = 0.20, eyeSize = Vector3.new(0.42, 0.50, 0.20),
				legColor = p.dark, tailSize = Vector3.new(0.28, 0.28, 0.50), tailColor = p.dark,
			})
			ears(c, p.dark, "down")
			-- Frosting cap and drips.
			c:box(Vector3.new(2.10, 0.22, 1.80), CFrame.new(0, 1.02, -0.04), p.pale)
			for _, v in ipairs({ { 1.08, 0.80, 0.60, 0.40 }, { -1.08, 0.76, -0.50, 0.50 }, { 1.08, 0.78, -0.50, 0.44 }, { -0.30, 0.82, -0.98, 0.40 } }) do
				local side = math.abs(v[1]) > 0.5
				c:box(Vector3.new(side and 0.10 or 0.26, v[4], side and 0.26 or 0.10), CFrame.new(v[1], v[2], v[3]), p.pale)
			end
			sprinkles(c, {
				{ -0.40, 1.14, 0.30, 0.4 }, { 0.30, 1.14, 0.40, -0.6, 0.6 }, { 0.10, 1.14, -0.30, 1.1 },
				{ -0.50, 1.14, -0.40, -0.3, 1.0 }, { 0.56, 1.14, -0.10, 0.2, -0.8 },
			})
		end,
	}

	-- A foil-striped candy egg on little chick feet, with a ribbon bow on top.
	S.sr_candyegg = {
		label = "Candy Egg",
		set = "sugar_rush",
		tint = C3(90, 200, 230),
		scale = 1.10,
		head = CFrame.new(0, 1.66, 0.02),
		neck = CFrame.new(0, -0.40, 0.84),
		back = CFrame.new(0, 0.20, -0.82),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.70, 1.70, 1.60),
				eyeY = 0.08, eyeSpread = 0.36, eyeSize = Vector3.new(0.38, 0.46, 0.18),
				mouthY = -0.26, mouthSize = Vector3.new(0.26, 0.12, 0.12),
				legs = false, tail = false,
			})
			-- The egg narrows to its top.
			c:box(Vector3.new(1.30, 0.40, 1.22), CFrame.new(0, 1.10, 0), p.base)
			c:box(Vector3.new(0.82, 0.26, 0.78), CFrame.new(0, 1.42, 0), p.base)
			-- Foil band with a zig-zag edge.
			c:box(Vector3.new(1.76, 0.22, 1.66), CFrame.new(0, -0.48, 0), p.pale)
			for _, x in ipairs({ -0.62, 0.62 }) do
				c:cone(Vector3.new(0.30, 0.18, 0.08), CFrame.new(x, -0.28, 0.81), p.pale)
			end
			-- Wing flaps and chick feet.
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.14, 0.50, 0.70), CFrame.new(0.90 * s, -0.04, -0.02) * CFrame.Angles(0, 0, 0.25 * s), p.light)
				c:box(Vector3.new(0.34, 0.14, 0.44), CFrame.new(0.36 * s, -0.86, 0.20), ORANGE)
			end
			-- Ribbon bow on the top.
			c:box(Vector3.new(0.18, 0.18, 0.18), CFrame.new(0, 1.62, 0), p.dark)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.34, 0.22, 0.10), CFrame.new(0.22 * s, 1.64, 0) * CFrame.Angles(0, 0, 0.40 * s), p.dark)
			end
			blush(c, 0.56, -0.12, 0.81)
		end,
	}

	return S
end
