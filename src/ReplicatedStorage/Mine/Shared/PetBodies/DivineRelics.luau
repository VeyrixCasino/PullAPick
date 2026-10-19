--[[ PetBodies/DivineRelics -- Divine Relics' bodies: living idols, golden guardians
	and ancient clockwork, the relics that shaped the world. See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, WHITE, METAL, NEON, GLASS = K.INK, K.WHITE, K.METAL, K.NEON, K.GLASS
	local S = {}

	-- Gold trim, gems and the sun glow stay fixed; the relic's own body repaints.
	local GOLD = C3(246, 204, 92)
	local GEM = C3(64, 214, 226)
	local SUN = C3(255, 232, 140)
	local FLAME = C3(255, 150, 40)
	local BLUSH = C3(255, 150, 160)
	local SET = "divine_relics"

	-- A squat temple idol: a stepped crown, a gem on its brow, arms folded on its
	-- belly, and a golden sun disc blazing behind it.
	S.dv_idol = {
		label = "Idol",
		set = SET,
		tint = C3(214, 170, 84),
		scale = 1.06,
		head = CFrame.new(0, 1.44, 0.04),
		neck = CFrame.new(0, -0.40, 0.82),
		back = CFrame.new(0, 0.10, -0.96),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.86, 1.70, 1.50),
				brow = p.dark, eyeY = 0.14, eyeSpread = 0.42, eyeSize = Vector3.new(0.46, 0.52, 0.20),
				mouthY = -0.30, mouthSize = Vector3.new(0.70, 0.14, 0.14), mouthColor = p.deep,
				legs = false, tail = false,
			})
			-- Stepped crown and the brow gem.
			c:box(Vector3.new(2.06, 0.22, 1.66), CFrame.new(0, 1.02, 0), p.light)
			c:box(Vector3.new(1.40, 0.30, 1.16), CFrame.new(0, 1.28, -0.04), p.base)
			c:box(Vector3.new(0.26, 0.26, 0.10), CFrame.new(0, 0.74, 0.78) * CFrame.Angles(0, 0, math.pi / 4), GEM, NEON)
			-- The sun disc behind, with its rays.
			c:cyl(Vector3.new(0.10, 2.20, 2.20), CFrame.new(0, 0.45, -0.84) * CFrame.Angles(0, math.pi / 2, 0), GOLD, METAL)
			for i = -3, 3 do
				local a = i * math.pi / 6
				c:cone(
					Vector3.new(0.26, 0.36, 0.10),
					CFrame.new(math.sin(a) * 1.24, 0.45 + math.cos(a) * 1.24, -0.84) * CFrame.Angles(0, 0, -a),
					GOLD,
					METAL
				)
			end
			-- Arms folded over the belly.
			for _, s in ipairs({ -1, 1 }) do
				c:rod(Vector3.new(0.96 * s, 0.20, 0.20), Vector3.new(0.66 * s, -0.54, 0.76), 0.15, p.base)
			end
			-- The pedestal it sits on.
			c:box(Vector3.new(2.10, 0.26, 1.80), CFrame.new(0, -0.90, 0), p.dark)
			c:light(SUN, 1.4, 8)
		end,
	}

	-- A wind-up clockwork critter: cog wheels for feet, a big brass key in its
	-- back, and two springy antennae.
	S.dv_windup = {
		label = "Windup",
		set = SET,
		tint = C3(206, 152, 72),
		head = CFrame.new(0, 0.86, 0.10),
		neck = CFrame.new(0, -0.40, 0.92),
		back = CFrame.new(0, 0.30, -0.96),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.80, 1.50, 1.70), bodyMat = METAL,
				eyeY = 0.14, eyeSpread = 0.40, eyeSize = Vector3.new(0.46, 0.54, 0.20),
				mouthY = -0.30, mouthSize = Vector3.new(0.40, 0.12, 0.12),
				legs = false, tail = false,
			})
			-- Tin-toy seam round the middle and a nub to rest on.
			c:box(Vector3.new(1.86, 0.10, 1.76), CFrame.new(0, -0.36, 0), p.dark, METAL)
			c:box(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0, -0.84, 0.50), p.deep, METAL)
			for _, s in ipairs({ -1, 1 }) do
				-- A cog wheel on each side, its teeth round the rim, a gold hub.
				c:cyl(Vector3.new(0.16, 1.30, 1.30), CFrame.new(0.98 * s, -0.40, 0), p.dark, METAL)
				for i = 0, 5 do
					local a = i * math.pi / 3
					c:box(
						Vector3.new(0.16, 0.24, 0.24),
						CFrame.new(0.98 * s, -0.40 + math.cos(a) * 0.70, math.sin(a) * 0.70) * CFrame.Angles(a, 0, 0),
						p.dark,
						METAL
					)
				end
				c:cyl(Vector3.new(0.12, 0.40, 0.40), CFrame.new(1.08 * s, -0.40, 0), GOLD, METAL)
				-- Springy antennae with gold knobs.
				c:rod(Vector3.new(0.40 * s, 0.80, 0.30), Vector3.new(0.56 * s, 1.16, 0.30), 0.05, p.dark, METAL, false)
				c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0.56 * s, 1.20, 0.30), GOLD, METAL)
				c:box(Vector3.new(0.22, 0.12, 0.06), CFrame.new(0.66 * s, -0.10, 0.86), BLUSH)
			end
			-- The wind-up key: a stem and two round bows.
			c:rod(Vector3.new(0, 0.30, -0.84), Vector3.new(0, 0.30, -1.20), 0.08, p.light, METAL, false)
			for _, s in ipairs({ -1, 1 }) do
				c:cyl(Vector3.new(0.10, 0.48, 0.48), CFrame.new(0.24 * s, 0.30, -1.24) * CFrame.Angles(0, math.pi / 2, 0), p.light, METAL)
			end
		end,
	}

	-- A wish lamp: a round brass oil lamp with its face above the spout, a little
	-- flame burning at the spout's tip, a jewelled lid and a curled handle.
	S.dv_lamp = {
		label = "Wish Lamp",
		set = SET,
		tint = C3(220, 168, 72),
		scale = 1.05,
		head = CFrame.new(0, 1.08, -0.04),
		neck = CFrame.new(0, -0.30, 0.86),
		back = CFrame.new(0, 0.20, -0.86),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.80, 1.10, 1.50), bodyMat = METAL,
				eyeY = 0.20, eyeSpread = 0.38, eyeSize = Vector3.new(0.40, 0.46, 0.20),
				mouth = false, legs = false, tail = false,
			})
			-- The spout, curving up to a flame.
			c:box(Vector3.new(0.38, 0.32, 0.56), CFrame.new(0, -0.10, 0.96) * CFrame.Angles(0.25, 0, 0), p.base, METAL)
			c:box(Vector3.new(0.24, 0.22, 0.34), CFrame.new(0, 0.06, 1.28) * CFrame.Angles(0.45, 0, 0), p.light, METAL)
			c:cone(Vector3.new(0.24, 0.40, 0.24), CFrame.new(0, 0.34, 1.40), FLAME, NEON)
			c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0, 0.20, 1.40), SUN, NEON)
			-- A gold band round the middle; lid, knob and a gem on the lid.
			c:box(Vector3.new(1.86, 0.10, 1.56), CFrame.new(0, -0.14, 0), GOLD, METAL)
			c:box(Vector3.new(1.00, 0.22, 0.90), CFrame.new(0, 0.70, -0.06), p.light, METAL)
			c:cone(Vector3.new(0.34, 0.36, 0.34), CFrame.new(0, 0.97, -0.06), GOLD, METAL)
			c:box(Vector3.new(0.20, 0.20, 0.08), CFrame.new(0, 0.70, 0.40) * CFrame.Angles(0, 0, math.pi / 4), GEM, NEON)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.20, 0.10, 0.06), CFrame.new(0.62 * s, -0.04, 0.76), BLUSH)
			end
			-- The curled handle at the back.
			c:rod(Vector3.new(0, 0.30, -0.72), Vector3.new(0, 0.46, -1.06), 0.08, p.light, METAL, false)
			c:rod(Vector3.new(0, 0.46, -1.06), Vector3.new(0, 0.06, -1.18), 0.08, p.light, METAL, false)
			c:rod(Vector3.new(0, 0.06, -1.18), Vector3.new(0, -0.16, -0.80), 0.08, p.light, METAL, false)
			-- The foot it stands on.
			c:box(Vector3.new(0.96, 0.28, 0.86), CFrame.new(0, -0.62, 0), p.dark, METAL)
			c:box(Vector3.new(1.30, 0.12, 1.20), CFrame.new(0, -0.82, 0), p.dark, METAL)
			c:light(FLAME, 1.6, 8)
		end,
	}

	-- A temple key come to life: the face is on its ornate round bow, a gold-ringed
	-- shaft runs back, and the toothed bit at the end stands in for back legs.
	S.dv_key = {
		label = "Relic Key",
		set = SET,
		tint = C3(214, 176, 92),
		scale = 0.96,
		head = CFrame.new(0, 1.12, 0.40),
		neck = CFrame.new(0, -0.40, 0.80),
		back = CFrame.new(0, 0.40, -0.70),
		build = function(c, p)
			-- The bow: a round plate with a gold rim, and five diamond lobes.
			c:cyl(Vector3.new(0.40, 1.70, 1.70), CFrame.new(0, 0.20, 0.50) * CFrame.Angles(0, math.pi / 2, 0), p.base, METAL)
			c:cyl(Vector3.new(0.30, 1.86, 1.86), CFrame.new(0, 0.20, 0.48) * CFrame.Angles(0, math.pi / 2, 0), GOLD, METAL)
			for _, v in ipairs({ { -0.58, 0.94 }, { 0, 1.14 }, { 0.58, 0.94 }, { -0.94, 0.20 }, { 0.94, 0.20 } }) do
				c:box(Vector3.new(0.38, 0.38, 0.34), CFrame.new(v[1], v[2], 0.50) * CFrame.Angles(0, 0, math.pi / 4), p.light, METAL)
			end
			c:box(Vector3.new(0.18, 0.18, 0.08), CFrame.new(0, 1.14, 0.69) * CFrame.Angles(0, 0, math.pi / 4), GEM, NEON)
			-- Its face.
			for _, s in ipairs({ -1, 1 }) do
				c:round(Vector3.new(0.40, 0.46, 0.16), CFrame.new(0.34 * s, 0.32, 0.74), INK):SetAttribute("Eye", true)
				c:round(Vector3.new(0.13, 0.13, 0.08), CFrame.new(0.28 * s, 0.42, 0.82), WHITE):SetAttribute("Eye", true)
				c:box(Vector3.new(0.18, 0.10, 0.04), CFrame.new(0.56 * s, 0.04, 0.72), BLUSH)
				-- Little feet under the bow.
				c:box(Vector3.new(0.36, 0.24, 0.40), CFrame.new(0.40 * s, -0.74, 0.50), p.dark, METAL)
			end
			c:box(Vector3.new(0.30, 0.10, 0.06), CFrame.new(0, -0.06, 0.73), INK)
			-- The shaft, with two gold collars.
			c:cyl(Vector3.new(1.60, 0.46, 0.46), CFrame.new(0, 0.10, -0.50) * CFrame.Angles(0, math.pi / 2, 0), p.base, METAL)
			for _, z in ipairs({ 0.16, -0.12 }) do
				c:cyl(Vector3.new(0.12, 0.62, 0.62), CFrame.new(0, 0.10, z) * CFrame.Angles(0, math.pi / 2, 0), GOLD, METAL)
			end
			-- The bit, with two teeth to stand on.
			c:box(Vector3.new(0.30, 0.66, 0.58), CFrame.new(0, -0.22, -1.02), p.light, METAL)
			for _, z in ipairs({ -0.84, -1.20 }) do
				c:box(Vector3.new(0.30, 0.30, 0.20), CFrame.new(0, -0.70, z), p.light, METAL)
			end
			c:light(GEM, 1.0, 6)
		end,
	}

	-- A living hourglass: the top bulb is full of sand and has the face, the
	-- bottom one is glass with a pile building up, all in a pillared frame.
	S.dv_hourglass = {
		label = "Hourglass",
		set = SET,
		tint = C3(232, 192, 112),
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, -0.40, 0.86),
		back = CFrame.new(0, 0.20, -0.86),
		build = function(c, p)
			-- Frame: caps top and bottom, four pillars, a finial and four feet.
			c:box(Vector3.new(1.90, 0.26, 1.70), CFrame.new(0, 1.04, 0), p.dark, METAL)
			c:box(Vector3.new(1.90, 0.26, 1.70), CFrame.new(0, -0.88, 0), p.dark, METAL)
			for _, s in ipairs({ -1, 1 }) do
				for _, t in ipairs({ -1, 1 }) do
					c:rod(Vector3.new(0.80 * s, -0.75, 0.68 * t), Vector3.new(0.80 * s, 0.91, 0.68 * t), 0.09, p.dark, METAL, false)
					c:box(Vector3.new(0.30, 0.20, 0.30), CFrame.new(0.76 * s, -1.10, 0.62 * t), p.deep, METAL)
				end
			end
			c:cone(Vector3.new(0.34, 0.36, 0.34), CFrame.new(0, 1.35, 0), GOLD, METAL)
			-- The top bulb, packed with sand: this is the face.
			c:box(Vector3.new(1.40, 0.55, 1.24), CFrame.new(0, 0.635, 0), p.base)
			c:cone(Vector3.new(1.40, 0.30, 1.24), CFrame.new(0, 0.21, 0) * CFrame.Angles(math.pi, 0, 0), p.base)
			for _, s in ipairs({ -1, 1 }) do
				c:round(Vector3.new(0.36, 0.40, 0.18), CFrame.new(0.32 * s, 0.68, 0.64), INK):SetAttribute("Eye", true)
				c:round(Vector3.new(0.12, 0.12, 0.08), CFrame.new(0.26 * s, 0.77, 0.73), WHITE):SetAttribute("Eye", true)
				c:box(Vector3.new(0.18, 0.10, 0.04), CFrame.new(0.50 * s, 0.50, 0.63), BLUSH)
			end
			c:box(Vector3.new(0.24, 0.10, 0.06), CFrame.new(0, 0.46, 0.63), INK)
			-- The glass bottom bulb, a falling thread of sand and the pile below.
			local glass = c:cone(Vector3.new(1.40, 0.40, 1.24), CFrame.new(0, -0.14, 0), C3(214, 238, 255), GLASS)
			glass.Transparency = 0.55
			local bowl = c:box(Vector3.new(1.40, 0.41, 1.24), CFrame.new(0, -0.545, 0), C3(214, 238, 255), GLASS)
			bowl.Transparency = 0.55
			c:box(Vector3.new(0.08, 0.50, 0.08), CFrame.new(0, -0.20, 0), p.light)
			c:cone(Vector3.new(1.00, 0.36, 0.90), CFrame.new(0, -0.57, 0), p.base)
			c:box(Vector3.new(1.30, 0.12, 1.14), CFrame.new(0, -0.69, 0), p.base)
		end,
	}

	return S
end
