--[[ PetBodies/Dragonfall -- Dragonfall's bodies: five kinds of dragon, each with its
	own outline (egg, hoard, fossil, wyvern, sky wyrm) so none reads as the
	roster's drake, wyrm, serpent or lizard. See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block, wings, ridge = K.C3, K.block, K.wings, K.ridge
	local INK, METAL, NEON = K.INK, K.METAL, K.NEON
	local S = {}

	-- Treasure, bone and the fossil's amber glow stay fixed; scales repaint.
	local GOLD = C3(246, 196, 64)
	local COIN = C3(255, 218, 96)
	local BONE = C3(244, 240, 230)
	local AMBER = C3(255, 170, 40)
	local SAPPHIRE = C3(70, 150, 255)
	local CLOUD = C3(240, 244, 252)
	local SET = "dragonfall"

	-- A baby dragon popping out of its egg: the bottom half of the shell still
	-- on, a shell cap on its head, two tiny wings and its hands on the rim.
	S.df_hatchling = {
		label = "Hatchling",
		set = SET,
		tint = C3(110, 196, 120),
		scale = 0.94,
		head = CFrame.new(0.20, 1.00, 0.20),
		neck = CFrame.new(0, -0.30, 1.04),
		back = CFrame.new(0, 0.30, -0.90),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.70, 1.60, 1.60),
				eyeY = 0.34, eyeSpread = 0.36, eyeSize = Vector3.new(0.46, 0.56, 0.20),
				snout = { w = 0.62, h = 0.36, d = 0.34, y = -0.06, color = p.light, nose = p.deep },
				legs = false, tail = false,
			})
			-- The eggshell, its jagged rim and speckles.
			c:box(Vector3.new(2.04, 0.90, 1.94), CFrame.new(0, -0.70, 0), p.pale)
			for _, t in ipairs({
				{ -0.62, 0.90 }, { 0.62, 0.90 }, { -0.66, -0.90 }, { 0, -0.90 }, { 0.66, -0.90 },
			}) do
				c:cone(Vector3.new(0.38, 0.36, 0.14), CFrame.new(t[1], -0.07, t[2]), p.pale)
			end
			for _, s in ipairs({ -1, 1 }) do
				c:cone(Vector3.new(0.14, 0.36, 0.40), CFrame.new(0.95 * s, -0.07, -0.20), p.pale)
				c:box(Vector3.new(0.06, 0.24, 0.24), CFrame.new(1.03 * s, -0.84, 0.30 * s), p.light)
			end
			c:box(Vector3.new(0.24, 0.22, 0.06), CFrame.new(-0.46, -0.66, 0.98), p.light)
			c:box(Vector3.new(0.20, 0.18, 0.06), CFrame.new(0.38, -0.92, 0.98), p.light)
			-- A piece of shell still stuck on its head, and two horn nubs.
			c:box(Vector3.new(0.80, 0.22, 0.74), CFrame.new(-0.12, 0.98, -0.24) * CFrame.Angles(0.10, 0, 0.18), p.pale)
			for _, s in ipairs({ -1, 1 }) do
				c:cone(Vector3.new(0.20, 0.30, 0.20), CFrame.new(0.42 * s, 0.98, 0.30), p.light)
				-- Tiny wings, and hands gripping the rim.
				c:box(Vector3.new(0.12, 0.50, 0.62), CFrame.new(0.92 * s, 0.36, -0.30) * CFrame.Angles(0, 0, -0.60 * s), p.dark)
				c:box(Vector3.new(0.26, 0.20, 0.26), CFrame.new(0.56 * s, -0.20, 0.88), p.base)
			end
		end,
	}

	-- A round, smug dragon sitting on its hoard: a pile of gold with coins and
	-- gems, a little crown, and a big sapphire hugged to its belly.
	S.df_hoarddragon = {
		label = "Hoard Dragon",
		set = SET,
		tint = C3(196, 64, 60),
		head = CFrame.new(0, 1.36, 0.04),
		neck = CFrame.new(0, -0.20, 0.92),
		back = CFrame.new(0, 0.30, -0.90),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.96, 1.76, 1.70),
				eyeY = 0.30, eyeSpread = 0.40, eyeSize = Vector3.new(0.44, 0.52, 0.20),
				snout = { w = 0.66, h = 0.42, d = 0.40, y = -0.10, color = p.light, nose = p.deep },
				bib = { w = 1.20, h = 0.80, y = -0.48, color = p.pale },
				legs = false, tail = false,
			})
			-- The hoard: two tiers of gold, loose coins, two gems.
			c:box(Vector3.new(2.40, 0.36, 2.10), CFrame.new(0, -0.94, -0.05), GOLD, METAL)
			c:box(Vector3.new(1.90, 0.24, 1.70), CFrame.new(0, -0.70, -0.10), GOLD, METAL)
			for _, v in ipairs({ { -0.96, -0.72, 0.70, 0.3 }, { 0.70, -0.74, 0.90, -0.2 }, { 1.02, -0.70, -0.60, 0.5 } }) do
				c:cyl(Vector3.new(0.06, 0.40, 0.40), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0, 0, math.pi / 2 + v[4]), COIN, METAL)
			end
			c:cyl(Vector3.new(0.06, 0.40, 0.40), CFrame.new(-0.70, -0.42, -0.86) * CFrame.Angles(0, math.pi / 2, 0.3), COIN, METAL)
			c:box(Vector3.new(0.26, 0.26, 0.26), CFrame.new(-0.86, -0.56, -0.52) * CFrame.Angles(0, 0.6, math.pi / 4), C3(230, 40, 80), NEON)
			c:box(Vector3.new(0.24, 0.24, 0.24), CFrame.new(0.92, -0.58, 0.30) * CFrame.Angles(0, 0.3, math.pi / 4), C3(60, 220, 120), NEON)
			-- The sapphire it hugs, and its paws.
			c:box(Vector3.new(0.40, 0.40, 0.28), CFrame.new(0, -0.52, 1.10) * CFrame.Angles(0, 0, math.pi / 4), SAPPHIRE, NEON)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.28, 0.26, 0.30), CFrame.new(0.30 * s, -0.50, 1.04), p.base)
				c:cone(Vector3.new(0.22, 0.46, 0.22), CFrame.new(0.62 * s, 1.10, -0.10) * CFrame.Angles(-0.30, 0, -0.25 * s), p.pale)
			end
			-- A small gold crown.
			c:box(Vector3.new(0.84, 0.16, 0.76), CFrame.new(0, 1.02, 0), GOLD, METAL)
			for _, x in ipairs({ -0.28, 0, 0.28 }) do
				c:cone(Vector3.new(0.18, 0.30, 0.18), CFrame.new(x, 1.24, 0.28), GOLD, METAL)
			end
			wings(c, p.dark, 0.22, 0.30, -0.36, 0.40)
			-- The tail, wrapped round the side of the pile.
			c:box(Vector3.new(0.40, 0.34, 0.80), CFrame.new(0.86, -0.56, -0.70) * CFrame.Angles(0, 0.6, 0), p.base)
			c:box(Vector3.new(0.30, 0.28, 0.50), CFrame.new(1.12, -0.58, -0.10) * CFrame.Angles(0, 0.2, 0), p.dark)
			c:light(GOLD, 1.4, 8)
		end,
	}

	-- A dragon fossil walking again: rock body, a long bony skull face with
	-- amber eyes in dark sockets, horns, ribs, a spine of vertebrae and bare
	-- wing bones.
	S.df_fossil = {
		label = "Fossil Dragon",
		set = SET,
		tint = C3(148, 124, 100),
		scale = 1.05,
		head = CFrame.new(0, 1.14, 0.30),
		neck = CFrame.new(0, -0.40, 0.70),
		back = CFrame.new(0, 0.30, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = Vector3.new(1.94, 1.70, 1.84),
				eyeColor = INK, eyeY = 0.18, eyeSpread = 0.44, eyeSize = Vector3.new(0.54, 0.60, 0.20),
				snout = { w = 0.86, h = 0.48, d = 0.62, y = -0.32, color = p.pale, nose = p.deep },
				legSize = Vector3.new(0.44, 0.36, 0.50), legColor = p.dark,
				tailSize = Vector3.new(0.36, 0.34, 0.60), tailColor = p.pale,
			})
			for _, s in ipairs({ -1, 1 }) do
				-- Amber eyes glowing in the sockets.
				c:box(Vector3.new(0.22, 0.26, 0.06), CFrame.new(0.44 * s, 0.14, 1.07), AMBER, NEON)
				-- Two fangs at the front of the jaw.
				c:cone(Vector3.new(0.12, 0.20, 0.12), CFrame.new(0.24 * s, -0.64, 1.30) * CFrame.Angles(math.pi, 0, 0), BONE)
				-- Horns sweeping back.
				c:rod(Vector3.new(0.40 * s, 0.88, 0.20), Vector3.new(0.66 * s, 1.26, -0.36), 0.10, p.pale, nil, false)
				c:cone(Vector3.new(0.18, 0.40, 0.18), CFrame.new(0.68 * s, 1.33, -0.55) * CFrame.Angles(-1.20, 0, 0), p.pale)
				-- Ribs down each flank.
				for _, z in ipairs({ -0.05, -0.45 }) do
					c:box(Vector3.new(0.10, 0.84, 0.16), CFrame.new(1.12 * s, -0.04, z) * CFrame.Angles(0.15, 0, 0), p.pale)
				end
				-- Bare wing bones.
				c:rod(Vector3.new(0.80 * s, 0.70, -0.20), Vector3.new(1.18 * s, 1.22, -0.50), 0.09, p.pale, nil, false)
				c:rod(Vector3.new(1.18 * s, 1.22, -0.50), Vector3.new(1.24 * s, 0.40, -0.90), 0.07, p.pale, nil, false)
			end
			-- Vertebrae along the spine.
			for _, z in ipairs({ 0.0, -0.40, -0.80 }) do
				c:box(Vector3.new(0.30, 0.20, 0.26), CFrame.new(0, 0.96, z), p.pale)
			end
		end,
	}

	-- A wyvern: stands upright on two legs, big wings raised behind like a cape,
	-- swept-back horns and a spade on the end of its tail.
	S.df_wyvern = {
		label = "Wyvern",
		set = SET,
		tint = C3(70, 92, 170),
		scale = 1.10,
		head = CFrame.new(0, 1.16, 0.20),
		neck = CFrame.new(0, -0.30, 0.86),
		back = CFrame.new(0, 0.20, -0.86),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = Vector3.new(1.86, 1.86, 1.70),
				eyeY = 0.18, eyeSpread = 0.40, eyeSize = Vector3.new(0.44, 0.52, 0.20),
				snout = { w = 0.66, h = 0.44, d = 0.44, y = -0.22, color = p.light, nose = p.deep },
				bib = { w = 0.90, h = 0.78, y = -0.48, color = p.pale },
				legSize = Vector3.new(0.50, 0.44, 0.56), legX = 0.48, legZ = { 0.06 }, legColor = p.dark,
				tail = false,
			})
			ridge(c, p.deep, 3, 1.04, -0.10, 0.32, 0.24)
			for _, s in ipairs({ -1, 1 }) do
				c:cone(Vector3.new(0.24, 0.62, 0.24), CFrame.new(0.40 * s, 1.16, -0.16) * CFrame.Angles(-0.70, 0, -0.20 * s), p.pale)
				-- Wing: arm bone, claw, finger strut and two membrane panels.
				c:rod(Vector3.new(0.78 * s, 0.62, -0.40), Vector3.new(1.16 * s, 1.46, -0.62), 0.09, p.deep, nil, false)
				c:cone(Vector3.new(0.14, 0.26, 0.14), CFrame.new(1.20 * s, 1.62, -0.62), p.pale)
				c:rod(Vector3.new(1.16 * s, 1.46, -0.62), Vector3.new(1.04 * s, 0.46, -1.12), 0.06, p.deep, nil, false)
				c:box(Vector3.new(0.10, 1.04, 0.86), CFrame.new(0.98 * s, 0.98, -0.80) * CFrame.Angles(0, -0.25 * s, -0.40 * s), p.dark)
				c:box(Vector3.new(0.10, 0.66, 0.66), CFrame.new(0.92 * s, 0.40, -0.98) * CFrame.Angles(0, -0.30 * s, -0.25 * s), p.dark)
			end
			-- Tail with a spade tip.
			c:box(Vector3.new(0.44, 0.38, 0.62), CFrame.new(0, -0.55, -1.02) * CFrame.Angles(0.35, 0, 0), p.base)
			c:cone(Vector3.new(0.52, 0.42, 0.10), CFrame.new(0, -0.32, -1.42) * CFrame.Angles(-1.05, 0, 0), p.deep)
		end,
	}

	-- A sky wyrm riding its own little cloud: a whiskered dragon with antlers and
	-- a mane, its long body looping up over its back and curling round.
	S.df_skywyrm = {
		label = "Sky Wyrm",
		set = SET,
		tint = C3(64, 172, 132),
		scale = 1.10,
		head = CFrame.new(0, 0.90, 0.40),
		neck = CFrame.new(0, -0.40, 0.84),
		back = CFrame.new(0, 0.40, -1.20),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.70, 1.56, 1.56),
				eyeY = 0.20, eyeSpread = 0.38, eyeSize = Vector3.new(0.44, 0.52, 0.20),
				snout = { w = 0.66, h = 0.44, d = 0.50, y = -0.24, color = p.light, nose = p.deep },
				bib = { w = 1.00, h = 0.60, y = -0.50, color = p.pale },
				legs = false, tail = false,
			})
			-- The body looping up over the back, down behind and round under.
			c:box(Vector3.new(1.20, 0.86, 1.00), CFrame.new(0, 0.80, -0.50) * CFrame.Angles(0.25, 0, 0), p.base)
			c:box(Vector3.new(1.06, 1.00, 0.84), CFrame.new(0, 0.30, -1.02) * CFrame.Angles(-0.30, 0, 0), p.base)
			c:box(Vector3.new(0.86, 0.66, 0.80), CFrame.new(0, -0.44, -0.92), p.base)
			c:box(Vector3.new(0.60, 0.44, 0.50), CFrame.new(0.66, -0.50, -0.50) * CFrame.Angles(0, -0.5, 0), p.base)
			c:cone(Vector3.new(0.40, 0.50, 0.40), CFrame.new(0.98, -0.40, -0.30) * CFrame.Angles(0, 0, -1.0), p.light)
			-- The cloud it rides on.
			c:box(Vector3.new(1.50, 0.36, 1.10), CFrame.new(0, -0.92, 0.10), CLOUD)
			c:box(Vector3.new(1.00, 0.34, 0.86), CFrame.new(-0.50, -0.96, -0.80), CLOUD)
			c:box(Vector3.new(0.86, 0.30, 0.76), CFrame.new(0.56, -1.00, -0.90), CLOUD)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.28, 0.24, 0.34), CFrame.new(0.50 * s, -0.64, 0.66), p.dark)
				-- Antlers: a main tine and a branch.
				c:rod(Vector3.new(0.30 * s, 0.76, 0.30), Vector3.new(0.42 * s, 1.24, 0.10), 0.07, p.pale, nil, false)
				c:rod(Vector3.new(0.36 * s, 1.00, 0.20), Vector3.new(0.62 * s, 1.14, 0.34), 0.06, p.pale, nil, false)
				-- Long drooping whiskers.
				c:rod(Vector3.new(0.30 * s, -0.18, 1.18), Vector3.new(0.80 * s, -0.32, 1.30), 0.045, p.pale, nil, false)
				c:rod(Vector3.new(0.80 * s, -0.32, 1.30), Vector3.new(1.00 * s, -0.70, 1.16), 0.045, p.pale, nil, false)
			end
			-- A mane of tufts along the loop.
			for _, m in ipairs({ { 1.30, -0.34, -0.3 }, { 1.24, -0.74, -0.7 }, { 0.86, -1.28, -1.2 }, { 0.24, -1.46, -1.6 } }) do
				c:cone(Vector3.new(0.30, 0.40, 0.30), CFrame.new(0, m[1], m[2]) * CFrame.Angles(m[3], 0, 0), p.light)
			end
		end,
	}

	return S
end
