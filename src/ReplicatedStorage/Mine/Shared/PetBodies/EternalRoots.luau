--[[ PetBodies/EternalRoots -- Eternal Roots' bodies (set 17, grade S). See tools/gen/sets/README.md.
	World-scale roots: bark, sap, seeds, buried springs and root caverns. Six
	silhouettes, each readable at follow distance: a ringed stump on root feet,
	a star-nosed cavern mole, a capybara with a hot spring on its back, an amber
	snail, a radish balanced on its own taproot, and a sky whale carrying a tree. ]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, WHITE, NEON, GLASS, SLATE = K.INK, K.WHITE, K.NEON, K.GLASS, K.SLATE
	local LEAF, LEAF_DARK = C3(104, 186, 84), C3(64, 132, 58)
	local BARK = C3(118, 84, 58)
	local BLUSH = C3(255, 150, 170)
	local S = {}

	S.er_stumpling = {
		label = "Stumpling",
		set = "eternal_roots",
		tint = C3(140, 96, 62),
		-- The splayed roots and the sprout are its widest and tallest points.
		scale = 1.08,
		head = CFrame.new(0, 1.12, 0.06),
		neck = CFrame.new(0, -0.30, 0.62),
		back = CFrame.new(0, 0.20, -0.62),
		build = function(c, p)
			block(c, p, {
				square = true, brow = p.dark, legs = false, tail = false,
				mouthSize = Vector3.new(0.36, 0.16, 0.14),
			})
			-- The cut top: growth rings, each one stepped a little proud of the last
			-- so they read as rings from the follow camera above.
			for i, r in ipairs({ { 1.96, 1.76, p.pale }, { 1.40, 1.24, p.light }, { 0.88, 0.78, p.pale }, { 0.38, 0.34, p.light } }) do
				c:box(Vector3.new(r[1], 0.06 + i * 0.02, r[2]), CFrame.new(0, 0.99 + i * 0.01, 0), r[3])
			end
			-- Bark ridges down both flanks.
			for _, s in ipairs({ -1, 1 }) do
				for _, z in ipairs({ 0.42, -0.36 }) do
					c:box(Vector3.new(0.10, 1.50, 0.26), CFrame.new(1.04 * s, 0.02, z), p.dark)
				end
			end
			-- Four roots for feet, splayed out to the corners and gripping the ground.
			for _, s in ipairs({ -1, 1 }) do
				for _, t in ipairs({ -1, 1 }) do
					local toe = Vector3.new(1.10 * s, -1.00, 0.92 * t)
					c:rod(Vector3.new(0.64 * s, -0.66, 0.56 * t), toe, 0.15, p.dark, nil, false)
					c:ball(Vector3.new(0.34, 0.26, 0.34), CFrame.new(toe), p.dark)
				end
			end
			-- A new sprout off-centre on the stump, two leaves in a V.
			c:rod(Vector3.new(0.48, 1.04, -0.36), Vector3.new(0.54, 1.42, -0.38), 0.05, LEAF_DARK, nil, false)
			c:box(Vector3.new(0.42, 0.10, 0.28), CFrame.new(0.36, 1.46, -0.38) * CFrame.Angles(0, 0, -0.45), LEAF)
			c:box(Vector3.new(0.42, 0.10, 0.28), CFrame.new(0.72, 1.46, -0.38) * CFrame.Angles(0, 0, 0.45), LEAF)
			-- A bracket fungus stepping up the left side.
			local cap = C3(232, 176, 104)
			c:box(Vector3.new(0.36, 0.12, 0.62), CFrame.new(-1.16, 0.08, -0.28), cap)
			c:box(Vector3.new(0.28, 0.10, 0.46), CFrame.new(-1.12, -0.26, -0.40), cap)
		end,
	}

	S.er_rootmole = {
		label = "Rootmole",
		set = "eternal_roots",
		tint = C3(92, 78, 96),
		head = CFrame.new(0, 0.94, 0.06),
		neck = CFrame.new(0, -0.40, 0.70),
		back = CFrame.new(0, 0.12, -0.66),
		build = function(c, p)
			local pink = C3(240, 146, 168)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(2.10, 1.62, 1.92),
				-- Tiny eyes set high: a mole barely needs them.
				eyeSize = Vector3.new(0.30, 0.34, 0.16), eyeY = 0.36, eyeSpread = 0.40,
				mouth = false,
				legSize = Vector3.new(0.42, 0.26, 0.46), legX = 0.60, legY = -0.80, legZ = { -0.44 },
				tailSize = Vector3.new(0.16, 0.16, 0.42), tailColor = pink,
			})
			-- The star nose: a pink button ringed by six feelers.
			local nose = Vector3.new(0, -0.10, 1.04)
			c:round(Vector3.new(0.30, 0.30, 0.20), CFrame.new(nose), pink)
			for i = 0, 5 do
				local a = i / 6 * math.pi * 2 + math.pi / 6
				c:round(Vector3.new(0.17, 0.17, 0.22), CFrame.new(nose + Vector3.new(math.cos(a) * 0.24, math.sin(a) * 0.24, -0.02)), pink)
			end
			-- Big shovel hands, palms out, three white claws each.
			for _, s in ipairs({ -1, 1 }) do
				local paw = CFrame.new(1.06 * s, -0.56, 0.56) * CFrame.Angles(0, 0.35 * s, 0)
				c:box(Vector3.new(0.20, 0.56, 0.58), paw, pink)
				for f = -1, 1 do
					c:cone(Vector3.new(0.12, 0.26, 0.12), paw * CFrame.new(0, f * 0.17, 0.38) * CFrame.Angles(math.pi / 2, 0, 0), WHITE)
				end
			end
			-- A root tendril curling over its head with a glowing seed-bulb on the
			-- end: the lamp it carries through the root caverns.
			c:rod(Vector3.new(0, 0.80, 0.06), Vector3.new(0.10, 1.24, 0.42), 0.06, p.dark, nil, false)
			c:rod(Vector3.new(0.10, 1.24, 0.42), Vector3.new(0.04, 1.26, 0.78), 0.05, p.dark, nil, false)
			c:ball(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0.04, 1.20, 0.86), p.glow, NEON)
			c:light(p.glow, 1.4, 7)
		end,
	}

	S.er_springback = {
		label = "Springback",
		set = "eternal_roots",
		tint = C3(176, 128, 84),
		head = CFrame.new(0, 0.96, 0.50),
		neck = CFrame.new(0, -0.34, 0.70),
		back = CFrame.new(0, 0.16, -0.70),
		build = function(c, p)
			local water, stone = C3(110, 214, 236), C3(146, 150, 160)
			-- A capybara: low barrel body, a tall blunt muzzle, no tail.
			block(c, p, {
				shape = "quad", bodySize = Vector3.new(2.06, 1.62, 1.98),
				snout = { w = 0.92, h = 0.60, d = 0.40, y = -0.22, color = p.dark, nose = p.deep },
				eyeY = 0.36, eyeSize = Vector3.new(0.44, 0.50, 0.20), eyeSpread = 0.48,
				legSize = Vector3.new(0.42, 0.30, 0.48), legY = -0.80, legX = 0.58,
				tail = false,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.30, 0.24, 0.20), CFrame.new(0.66 * s, 0.94, 0.42), p.dark)
			end
			-- A buried spring broke through on its back: a stone rim round a pool.
			local cz, w, d = -0.40, 1.40, 1.08
			c:box(Vector3.new(w, 0.24, 0.20), CFrame.new(0, 0.96, cz + d / 2), stone, SLATE)
			c:box(Vector3.new(w, 0.24, 0.20), CFrame.new(0, 0.96, cz - d / 2), stone, SLATE)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.20, 0.24, d), CFrame.new((w / 2 - 0.10) * s, 0.96, cz), stone, SLATE)
			end
			local pool = c:box(Vector3.new(w - 0.36, 0.10, d - 0.36), CFrame.new(0, 1.00, cz), water, GLASS)
			pool.Transparency = 0.1
			-- The spring bubbling up, with two drops falling back.
			c:rod(Vector3.new(0, 1.02, cz), Vector3.new(0, 1.42, cz), 0.07, water, NEON, false)
			c:ball(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0, 1.48, cz), water, NEON)
			for _, s in ipairs({ -1, 1 }) do
				c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.28 * s, 1.32, cz + 0.06), water, NEON)
			end
			-- A lily pad floating in the pool.
			c:cyl(Vector3.new(0.04, 0.34, 0.34), CFrame.new(0.30, 1.06, cz - 0.12) * CFrame.Angles(0, 0, math.pi / 2), LEAF)
		end,
	}

	S.er_sapshell = {
		label = "Sapshell",
		set = "eternal_roots",
		tint = C3(232, 150, 40),
		-- The hat sits on the snail's head, between its feelers, in front of the shell.
		head = CFrame.new(0, 0.22, 0.86),
		neck = CFrame.new(0, -0.62, 1.20),
		back = CFrame.new(0, 0.30, -1.10),
		build = function(c, p)
			-- Built from parts, not block(): a snail is a long low foot that rises
			-- at the front into a head, with the shell riding on top.
			c:box(Vector3.new(1.50, 0.56, 2.26), CFrame.new(0, -0.74, -0.03), p.pale)
			c:box(Vector3.new(1.36, 1.10, 0.74), CFrame.new(0, -0.38, 0.86), p.pale)
			c:eyes(-0.26, 1.25, 0.30, 0.15)
			c:box(Vector3.new(0.30, 0.08, 0.06), CFrame.new(0, -0.62, 1.24), INK)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.22, 0.10, 0.04), CFrame.new(0.50 * s, -0.50, 1.24), BLUSH)
				-- Feelers.
				local tip = Vector3.new(0.46 * s, 0.66, 1.12)
				c:rod(Vector3.new(0.30 * s, 0.10, 1.00), tip, 0.05, p.light, nil, false)
				c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(tip), p.deep)
			end
			-- The shell: hardened sap, amber you can nearly see through, with a seed
			-- glowing at its heart.
			local shell = c:box(Vector3.new(1.44, 1.44, 1.50), CFrame.new(0, 0.24, -0.34), p.base, GLASS)
			shell.Transparency = 0.2
			c:ball(Vector3.new(0.56, 0.56, 0.56), CFrame.new(0, 0.24, -0.34), p.glow, NEON)
			-- The spiral on each side: three nested diamonds, each turned a little
			-- further, so the pattern twists in toward a glowing centre.
			for _, s in ipairs({ -1, 1 }) do
				for i, r in ipairs({ { 0.96, p.deep, 0.20 }, { 0.62, p.light, 0.60 }, { 0.30, p.glow, 1.00 } }) do
					local part = c:box(
						Vector3.new(0.04 + i * 0.02, r[1], r[1]),
						CFrame.new((0.72 + i * 0.01) * s, 0.24, -0.34) * CFrame.Angles(r[3] * s, 0, 0),
						r[2]
					)
					if i == 3 then
						part.Material = NEON
					end
				end
			end
			-- A sprout on top, and a drip of sap running down the back.
			c:rod(Vector3.new(0, 0.94, -0.56), Vector3.new(0.04, 1.28, -0.60), 0.05, LEAF_DARK, nil, false)
			c:box(Vector3.new(0.36, 0.08, 0.24), CFrame.new(-0.14, 1.30, -0.60) * CFrame.Angles(0, 0, -0.45), LEAF)
			c:box(Vector3.new(0.36, 0.08, 0.24), CFrame.new(0.20, 1.30, -0.60) * CFrame.Angles(0, 0, 0.45), LEAF)
			c:box(Vector3.new(0.14, 0.40, 0.10), CFrame.new(0.34, 0.06, -1.10), p.base, GLASS)
			c:ball(Vector3.new(0.20, 0.22, 0.20), CFrame.new(0.34, -0.16, -1.11), p.base, GLASS)
			c:light(p.glow, 1.2, 7)
		end,
	}

	S.er_taproot = {
		label = "Taproot",
		set = "eternal_roots",
		tint = C3(214, 92, 128),
		-- Leaves above and a root point below make it the tallest body here.
		scale = 1.15,
		head = CFrame.new(0, 0.90, 0.20),
		neck = CFrame.new(0, -0.30, 0.62),
		back = CFrame.new(0, 0.10, -0.62),
		build = function(c, p)
			-- A radish of a creature, balanced on the point of its own taproot.
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.96, 1.54, 1.76),
				eyeY = 0.12, legs = false, tail = false,
				mouthY = -0.30, mouthSize = Vector3.new(0.28, 0.14, 0.14),
			})
			c:cone(Vector3.new(1.16, 0.56, 1.04), CFrame.new(0, -0.96, 0) * CFrame.Angles(math.pi, 0, 0), p.base)
			-- Rootlet feet keep it upright, and a hair-root curls off the tip.
			for _, s in ipairs({ -1, 1 }) do
				local foot = Vector3.new(0.80 * s, -1.08, 0.30)
				c:rod(Vector3.new(0.42 * s, -0.66, 0.18), foot, 0.07, p.dark, nil, false)
				c:ball(Vector3.new(0.20, 0.16, 0.24), CFrame.new(foot), p.dark)
				c:box(Vector3.new(0.24, 0.12, 0.06), CFrame.new(0.66 * s, -0.12, 0.76), BLUSH)
			end
			c:rod(Vector3.new(0, -1.18, 0), Vector3.new(0.18, -1.28, -0.16), 0.04, p.dark, nil, false)
			-- A crown of three big leaves fanned from the top, each with a midrib
			-- deep enough to show on both faces.
			for i, a in ipairs({ 0.55, 0, -0.55 }) do
				local h = (i == 2) and 0.76 or 0.62
				local cf = CFrame.new(0, 0.78, -0.06) * CFrame.Angles(0, 0, a) * CFrame.new(0, h / 2 + 0.04, 0)
				c:box(Vector3.new(0.44, h, 0.14), cf, LEAF)
				c:box(Vector3.new(0.08, h * 0.86, 0.18), cf, LEAF_DARK)
			end
		end,
	}

	S.er_groveback = {
		label = "Groveback",
		set = "eternal_roots",
		tint = C3(84, 128, 168),
		-- Tree above, roots below, fluke behind: every axis is long, so scale it back up.
		scale = 1.2,
		head = CFrame.new(0, 0.92, 0.50),
		neck = CFrame.new(0, -0.40, 0.84),
		back = CFrame.new(0, 0.10, -1.10),
		build = function(c, p)
			-- A sky whale old enough that a tree grew on its back, its roots hanging
			-- down beneath it like it once joined two worlds.
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.96, 1.60, 1.96),
				eyeY = 0.24, eyeSpread = 0.50, eyeSize = Vector3.new(0.46, 0.54, 0.20),
				mouthY = -0.14, mouthSize = Vector3.new(0.80, 0.12, 0.14),
				bib = { w = 1.30, h = 0.56, y = -0.48, color = p.pale },
				legs = false, tail = false,
			})
			-- Throat grooves across the pale belly.
			for _, y in ipairs({ -0.38, -0.58 }) do
				c:box(Vector3.new(1.10, 0.04, 0.04), CFrame.new(0, y, 1.10), p.light)
			end
			-- Tail stock and a swept-back fluke.
			c:box(Vector3.new(0.80, 0.62, 0.50), CFrame.new(0, 0.04, -1.16), p.base)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.80, 0.14, 0.44), CFrame.new(0.40 * s, 0.20, -1.50) * CFrame.Angles(0, 0.30 * s, 0.30 * s), p.dark)
				c:box(Vector3.new(0.56, 0.12, 0.40), CFrame.new(1.06 * s, -0.40, 0.30) * CFrame.Angles(0, -0.30 * s, -0.40 * s), p.dark)
			end
			-- The tree: a stout trunk and a stepped canopy with glowing sap-fruit.
			local canopy = C3(92, 170, 84)
			c:cyl(Vector3.new(0.34, 0.30, 0.30), CFrame.new(0, 1.00, -0.16) * CFrame.Angles(0, 0, math.pi / 2), BARK)
			c:box(Vector3.new(1.20, 0.48, 1.04), CFrame.new(0, 1.36, -0.16), canopy)
			c:box(Vector3.new(0.72, 0.30, 0.64), CFrame.new(0.06, 1.68, -0.16), canopy)
			c:box(Vector3.new(0.50, 0.32, 0.50), CFrame.new(-0.46, 1.52, -0.32), canopy)
			for _, v in ipairs({ { 0.36, 1.30, 0.38 }, { -0.30, 1.44, 0.38 }, { 0.20, 1.36, -0.70 } }) do
				c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(v[1], v[2], v[3]), p.glow, NEON)
			end
			-- Roots trailing from its belly.
			for _, r in ipairs({ { -0.46, 0.20, -0.04 }, { 0.10, -0.30, 0.10 }, { 0.50, 0.30, 0.04 } }) do
				c:rod(Vector3.new(r[1], -0.60, r[2]), Vector3.new(r[1] + r[3], -1.08, r[2] - 0.10), 0.07, BARK, nil, false)
			end
			c:light(p.glow, 1.2, 8)
		end,
	}

	return S
end
