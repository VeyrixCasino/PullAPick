--[[ PetBodies/LostAndFoundExtra -- Lost & Found's extra recolour bodies. See tools/gen/sets/README.md.

	More everyday finds for the Common, Uncommon and Rare pets, so two pets on
	one body can stay vastly different colours: a glass marble with a swirl
	inside, a wooden thread spool with a needle stuck in the top, a beach
	conch with a spiral spire, and a sand pail with its little spade.
]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, METAL, GLASS, WOOD = K.INK, K.METAL, K.GLASS, K.WOOD
	local S = {}

	local GOLD = C3(246, 200, 80)
	local RED = C3(200, 44, 48)
	local UP = CFrame.Angles(0, 0, math.pi / 2) -- a cylinder standing on end
	local FACING = CFrame.Angles(0, math.pi / 2, 0) -- a cylinder facing forward
	local PINK = C3(255, 150, 170)
	local SAND = C3(232, 208, 150)
	local SPOOLWOOD = C3(214, 172, 116)
	local SIDES = { -1, 1 }

	-- A big glass marble with a coloured swirl showing through, on two stubby feet.
	S.lf_marble = {
		label = "Marble",
		set = "lost_and_found",
		tint = C3(70, 120, 220),
		head = CFrame.new(0, 1.08, 0.04),
		neck = CFrame.new(0, -0.40, 0.80),
		back = CFrame.new(0, 0.20, -0.90),
		build = function(c, p)
			local glass = c:ball(Vector3.new(1.90, 1.90, 1.90), CFrame.new(0, 0.12, 0), p.light, GLASS)
			glass.Transparency = 0.3
			-- The swirl inside: three twisted ribbons.
			c:box(Vector3.new(1.50, 0.26, 0.34), CFrame.new(0, 0.12, -0.10) * CFrame.Angles(0, 0.3, 0.6), p.base)
			c:box(Vector3.new(1.40, 0.24, 0.30), CFrame.new(0, 0.12, -0.10) * CFrame.Angles(0, -0.5, -0.5), p.deep)
			c:box(Vector3.new(0.30, 1.30, 0.26), CFrame.new(0, 0.12, -0.12) * CFrame.Angles(0.4, 0.2, 0), p.base)
			-- Face, cheeks and a gleam on the glass.
			c:eyes(0.32, 0.86, 0.32, 0.17)
			c:box(Vector3.new(0.24, 0.07, 0.06), CFrame.new(0, -0.04, 0.93), INK)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.18, 0.10, 0.04), CFrame.new(0.52 * s, 0.06, 0.80) * CFrame.Angles(0, 0.55 * s, 0), PINK)
				c:box(Vector3.new(0.44, 0.24, 0.52), CFrame.new(0.40 * s, -0.84, 0.18), p.deep)
			end
			c:box(Vector3.new(0.12, 0.42, 0.06), CFrame.new(-0.45, 0.58, 0.70) * CFrame.Angles(-0.5, -0.45, 0.5), C3(255, 255, 255))
			c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(-0.22, 0.86, 0.60), C3(255, 255, 255))
		end,
	}

	-- A wooden thread spool, wound with thread, a needle stuck in the top.
	S.lf_spool = {
		label = "Thread Spool",
		set = "lost_and_found",
		tint = C3(220, 60, 90),
		head = CFrame.new(0, 1.00, 0.04),
		neck = CFrame.new(0, -0.30, 0.86),
		back = CFrame.new(0, 0.10, -0.86),
		build = function(c, p)
			-- Thread, its wound lines, and the two wooden flanges.
			c:cyl(Vector3.new(1.30, 1.70, 1.70), CFrame.new(0, 0.04, 0) * UP, p.base)
			for _, y in ipairs({ 0.58, -0.50 }) do
				c:cyl(Vector3.new(0.05, 1.74, 1.74), CFrame.new(0, y, 0) * UP, p.dark)
			end
			for _, y in ipairs({ 0.80, -0.72 }) do
				c:cyl(Vector3.new(0.24, 2.10, 2.10), CFrame.new(0, y, 0) * UP, SPOOLWOOD, WOOD)
			end
			c:cyl(Vector3.new(0.04, 0.44, 0.44), CFrame.new(0, 0.93, 0) * UP, C3(120, 84, 50))
			-- Face on the thread.
			c:eyes(0.18, 0.82, 0.32, 0.17)
			c:box(Vector3.new(0.24, 0.07, 0.06), CFrame.new(0, -0.14, 0.86), INK)
			-- A needle in the top and a loose end of thread curling away.
			c:rod(Vector3.new(0.30, 0.86, 0.10), Vector3.new(0.62, 1.62, -0.16), 0.05, C3(206, 210, 220), METAL, false)
			c:box(Vector3.new(0.06, 0.16, 0.10), CFrame.new(0.64, 1.66, -0.17) * CFrame.Angles(0, 0, -0.4), C3(206, 210, 220), METAL)
			c:rod(Vector3.new(0.84, -0.20, 0.20), Vector3.new(1.16, -0.48, 0.48), 0.04, p.base, nil, false)
			c:rod(Vector3.new(1.16, -0.48, 0.48), Vector3.new(1.26, -0.80, 0.28), 0.04, p.base, nil, false)
			-- Four button feet.
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:cyl(Vector3.new(0.14, 0.42, 0.42), CFrame.new(0.50 * s, -0.91, 0.46 * t) * UP, p.deep)
				end
			end
		end,
	}

	-- A beach conch: a soft whorl, a stepped spire, knobs, and a pink opening with a face.
	S.lf_conch = {
		label = "Beach Conch",
		set = "lost_and_found",
		tint = C3(240, 170, 120),
		head = CFrame.new(0, 1.70, -0.30),
		neck = CFrame.new(0, -0.40, 0.92),
		back = CFrame.new(0, 0.20, -0.90),
		build = function(c, p)
			c:round(Vector3.new(1.80, 1.30, 1.70), CFrame.new(0, -0.12, 0), p.base)
			-- The spire, stepping up and twisting as it goes.
			for i = 1, 4 do
				local s = 1.30 - 0.24 * i
				c:box(Vector3.new(s, 0.34, s), CFrame.new(0, 0.50 + 0.28 * (i - 1), -0.10 - 0.06 * i) * CFrame.Angles(0, 0.35 * i, 0), i % 2 == 0 and p.light or p.base)
			end
			c:cone(Vector3.new(0.24, 0.30, 0.24), CFrame.new(0, 1.55, -0.36), p.dark)
			-- Knobs round the shoulder and two bands round the whorl.
			for _, v in ipairs({ { 0.66, 0.34 }, { -0.66, 0.34 }, { 0.66, -0.40 }, { -0.66, -0.40 } }) do
				c:box(Vector3.new(0.22, 0.26, 0.22), CFrame.new(v[1], 0.60, v[2]) * CFrame.Angles(0, 0.78, 0), p.pale)
			end
			c:box(Vector3.new(1.84, 0.10, 1.10), CFrame.new(0, 0.14, -0.22), p.dark)
			c:box(Vector3.new(1.84, 0.10, 1.00), CFrame.new(0, -0.38, -0.26), p.dark)
			-- The pink opening at the front, its flared lip, and the face on it.
			c:box(Vector3.new(1.20, 1.00, 0.12), CFrame.new(0.06, -0.16, 0.86), PINK)
			c:box(Vector3.new(0.18, 1.20, 0.34), CFrame.new(0.70, -0.12, 0.80) * CFrame.Angles(0, -0.3, 0), p.pale)
			c:eyes(0.04, 0.96, 0.28, 0.16)
			c:box(Vector3.new(0.22, 0.07, 0.05), CFrame.new(0, -0.30, 0.94), INK)
			-- Little feet underneath.
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(Vector3.new(0.34, 0.20, 0.38), CFrame.new(0.50 * s, -0.84, 0.42 * t), p.deep)
				end
			end
		end,
	}

	-- A sand pail full of sand, with a carry handle and a toy spade stuck in it.
	S.lf_pail = {
		label = "Sand Pail",
		set = "lost_and_found",
		tint = C3(250, 210, 50),
		head = CFrame.new(0, 1.60, 0.04),
		neck = CFrame.new(0, -0.40, 0.90),
		back = CFrame.new(0, 0.10, -0.90),
		build = function(c, p)
			-- Pail, a darker foot band and the rolled rim.
			c:cyl(Vector3.new(1.50, 1.76, 1.76), CFrame.new(0, 0.06, 0) * UP, p.base)
			c:cyl(Vector3.new(0.30, 1.60, 1.60), CFrame.new(0, -0.76, 0) * UP, p.dark)
			c:cyl(Vector3.new(0.20, 1.96, 1.96), CFrame.new(0, 0.84, 0) * UP, p.light)
			-- Sand heaped on top.
			c:ball(Vector3.new(1.50, 0.60, 1.50), CFrame.new(0, 0.98, 0), SAND)
			-- The carry handle over the top, side to side.
			c:rod(Vector3.new(-0.92, 0.80, 0), Vector3.new(-0.60, 1.46, 0), 0.06, p.dark, nil, false)
			c:rod(Vector3.new(-0.60, 1.46, 0), Vector3.new(0.60, 1.46, 0), 0.06, p.dark, nil, false)
			c:rod(Vector3.new(0.60, 1.46, 0), Vector3.new(0.92, 0.80, 0), 0.06, p.dark, nil, false)
			-- A toy spade stuck in the sand behind.
			c:rod(Vector3.new(0.28, 1.04, -0.30), Vector3.new(0.50, 1.80, -0.50), 0.06, p.deep, nil, false)
			c:box(Vector3.new(0.34, 0.10, 0.10), CFrame.new(0.52, 1.84, -0.52) * CFrame.Angles(0, 0.7, 0), p.deep)
			-- Face, and a starfish sticker on one side.
			c:eyes(0.22, 0.86, 0.34, 0.18)
			c:box(Vector3.new(0.32, 0.12, 0.06), CFrame.new(0, -0.16, 0.89), INK)
			for _, a in ipairs({ 0, 1.26, 2.51 }) do
				c:box(Vector3.new(0.06, 0.40, 0.08), CFrame.new(0.89, 0.10, -0.10) * CFrame.Angles(a, 0, 0), GOLD)
			end
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.40, 0.18, 0.46), CFrame.new(0.42 * s, -0.96, 0.30), p.deep)
			end
			c:box(Vector3.new(0.10, 0.10, 0.10), CFrame.new(0.20, 1.24, 0.30), RED)
		end,
	}

	return S
end
