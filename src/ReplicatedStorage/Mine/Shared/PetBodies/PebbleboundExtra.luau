--[[ PetBodies/PebbleboundExtra -- more Pebblebound recolour bodies. See tools/gen/sets/README.md.

	Common, Uncommon and Rare pets share these, each pet in a colour VASTLY
	unlike the others on its body. Plain rock and earth, no glow, like the
	set's first five: a tortoise under a stone dome, a hedgehog of gravel
	spikes, a warty toad and a little cave bat clutching a pebble.
]]
return function(K)
	local C3, block, spots = K.C3, K.block, K.spots
	local SLATE = K.SLATE
	local SIDES = { -1, 1 }
	local S = {}

	-- A tortoise under a tall domed shell of stone plates; its face pokes out in front.
	S.pb_rocktoise = {
		label = "Rocktoise",
		set = "pebblebound",
		tint = C3(120, 132, 96),
		head = CFrame.new(0, 1.40, -0.12),
		neck = CFrame.new(0, -0.36, 1.02),
		back = CFrame.new(0, 0.80, -1.00),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.50, 1.00, 1.96),
				eyeY = 0.04, eyeSpread = 0.36, eyeSize = Vector3.new(0.34, 0.40, 0.20),
				mouthSize = Vector3.new(0.34, 0.08, 0.12), mouthY = -0.24,
				legX = 0.76, legY = -0.66, legSize = Vector3.new(0.50, 0.50, 0.50), legZ = { 0.50, -0.50 },
				tailSize = Vector3.new(0.24, 0.24, 0.30),
			})
			-- The shell: a rim, a high body and a dome, set back so the face stays out front.
			c:box(Vector3.new(2.06, 0.20, 1.80), CFrame.new(0, 0.10, -0.12), p.deep)
			c:box(Vector3.new(1.84, 0.70, 1.62), CFrame.new(0, 0.54, -0.12), p.dark, SLATE)
			c:box(Vector3.new(1.30, 0.40, 1.10), CFrame.new(0, 1.04, -0.12), p.base, SLATE)
			c:box(Vector3.new(0.56, 0.12, 0.56), CFrame.new(0, 1.26, -0.12) * CFrame.Angles(0, math.pi / 4, 0), p.light)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.10, 0.40, 0.50), CFrame.new(0.93 * s, 0.54, 0.20), p.light)
				c:box(Vector3.new(0.10, 0.40, 0.50), CFrame.new(0.93 * s, 0.54, -0.50), p.light)
			end
		end,
	}

	-- A round hedgehog whose spines are chips of gravel; a pale face and a pointed nose.
	S.pb_quarryhog = {
		label = "Quarryhog",
		set = "pebblebound",
		tint = C3(150, 120, 96),
		head = CFrame.new(0, 1.20, 0.10),
		neck = CFrame.new(0, -0.36, 0.96),
		back = CFrame.new(0, 0.30, -1.04),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.90, 1.60, 1.80),
				snout = { w = 0.46, h = 0.34, d = 0.50, y = -0.18, color = p.pale },
				eyeY = 0.16, eyeSpread = 0.40, eyeSize = Vector3.new(0.32, 0.40, 0.20),
				legSize = Vector3.new(0.40, 0.30, 0.44), legY = -0.80, tail = false,
			})
			c:box(Vector3.new(1.30, 1.00, 0.04), CFrame.new(0, -0.02, 0.91), p.pale)
			-- Gravel spines over the crown, the back and the flanks, all leaning back.
			for _, q in ipairs({
				{ -0.50, 0.92, 0.10, -0.5, 0.3 }, { 0.50, 0.92, 0.10, -0.5, -0.3 }, { 0, 0.98, -0.30, -0.7, 0 },
				{ -0.60, 0.70, -0.66, -1.0, 0.4 }, { 0.60, 0.70, -0.66, -1.0, -0.4 }, { 0, 0.40, -0.98, -1.4, 0 },
				{ -0.98, 0.30, -0.20, -0.3, 1.2 }, { 0.98, 0.30, -0.20, -0.3, -1.2 },
			}) do
				c:cone(Vector3.new(0.36, 0.52, 0.36), CFrame.new(q[1], q[2], q[3]) * CFrame.Angles(q[4], 0, q[5]), p.dark, SLATE)
			end
		end,
	}

	-- A squat warty toad: eye bumps on top, a wide grin, big back legs folded at its sides.
	S.pb_toadstone = {
		label = "Toadstone",
		set = "pebblebound",
		tint = C3(118, 150, 80),
		head = CFrame.new(0, 1.00, 0.10),
		neck = CFrame.new(0, -0.40, 0.94),
		back = CFrame.new(0, 0.30, -0.92),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(2.00, 1.20, 1.70),
				eyeY = 0.30, eyeSpread = 0.56, eyeSize = Vector3.new(0.40, 0.44, 0.20),
				mouthSize = Vector3.new(0.90, 0.08, 0.10), mouthY = -0.14,
				bib = { w = 1.40, h = 0.36, y = -0.40, color = p.pale },
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.56, 0.40, 0.56), CFrame.new(0.56 * s, 0.72, 0.46), p.base)
				c:box(Vector3.new(0.50, 0.56, 0.96), CFrame.new(1.10 * s, -0.24, -0.30), p.dark)
				c:box(Vector3.new(0.60, 0.14, 0.56), CFrame.new(1.16 * s, -0.56, 0.24), p.deep)
				c:box(Vector3.new(0.40, 0.14, 0.40), CFrame.new(0.58 * s, -0.58, 0.84), p.deep)
			end
			spots(c, p.dark, { { -0.30, 0.68, -0.30 }, { 0.40, 0.68, -0.10 }, { 0, 0.68, -0.60 }, { -0.66, 0.68, -0.10 } }, Vector3.new(0.20, 0.08, 0.20))
		end,
	}

	-- A round little cave bat with big ears and scalloped wings, clutching a pebble.
	S.pb_pebblebat = {
		label = "Pebblebat",
		set = "pebblebound",
		tint = C3(96, 84, 120),
		scale = 1.2,
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, -0.30, 0.76),
		back = CFrame.new(0, 0.20, -0.74),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.50, 1.50, 1.40),
				eyeY = 0.18, eyeSpread = 0.34, eyeSize = Vector3.new(0.38, 0.46, 0.20),
				mouthSize = Vector3.new(0.24, 0.10, 0.12), mouthY = -0.12,
				bib = { w = 0.80, h = 0.50, y = -0.46, color = p.pale },
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(Vector3.new(0.40, 0.66, 0.30), CFrame.new(0.42 * s, 1.10, 0) * CFrame.Angles(0, 0, -0.2 * s), p.dark)
				c:box(Vector3.new(0.20, 0.38, 0.06), CFrame.new(0.44 * s, 1.02, 0.12) * CFrame.Angles(0, 0, -0.2 * s), p.pale)
				-- A wing: the arm bone and two scalloped membrane panels.
				c:rod(Vector3.new(0.70 * s, 0.40, -0.10), Vector3.new(1.46 * s, 0.70, -0.10), 0.06, p.deep, nil, false)
				c:box(Vector3.new(0.54, 0.70, 0.06), CFrame.new(1.00 * s, 0.24, -0.10) * CFrame.Angles(0, 0, 0.15 * s), p.dark)
				c:box(Vector3.new(0.40, 0.54, 0.06), CFrame.new(1.34 * s, 0.38, -0.10) * CFrame.Angles(0, 0, 0.35 * s), p.dark)
				c:box(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0.30 * s, -0.80, 0), p.deep)
			end
			c:box(Vector3.new(0.40, 0.32, 0.34), CFrame.new(0, -1.02, 0.06) * CFrame.Angles(0.3, 0.6, 0.2), p.light)
		end,
	}

	return S
end
