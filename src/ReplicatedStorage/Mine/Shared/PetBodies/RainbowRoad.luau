--[[ PetBodies/RainbowRoad -- Rainbow Road's bodies. See tools/gen/sets/README.md.
	Natural rainbow crystal and colourful-world creatures, pastel to prismatic:
	a geode-shelled snail, a cloud under a rainbow, a crystal-quilled hedgehog,
	an axolotl with crystal gills and a rainbow-billed toucan. No chrome (that
	is Holo Havoc). The rainbow hues are blended toward each pet's own tint, so
	a pale pet wears a pastel rainbow and a bright one a vivid rainbow. ]]
return function(K)
	local C3, block = K.C3, K.block
	local GLASS, INK = K.GLASS, K.INK
	local HUES = {
		C3(255, 92, 92), C3(255, 164, 72), C3(255, 226, 90), C3(110, 220, 120),
		C3(90, 190, 255), C3(150, 120, 255), C3(230, 120, 230),
	}
	local BLUSH = C3(255, 150, 176)
	local S = {}

	-- Rainbow hue `i` (wrapping), pulled a little toward the pet's own colour.
	local function hue(p, i)
		return HUES[(i - 1) % #HUES + 1]:Lerp(p.pale, 0.28)
	end

	-- A crystal: a column with a pyramid tip, standing on `base`, tilted by `tilt`.
	local function crystal(c, base, tilt, w, h, colour)
		local cf = CFrame.new(base) * tilt
		c:box(Vector3.new(w, h, w), cf * CFrame.new(0, h * 0.5, 0), colour, GLASS).Reflectance = 0.1
		c:cone(Vector3.new(w, w * 0.9, w), cf * CFrame.new(0, h + w * 0.45, 0), colour, GLASS).Reflectance = 0.1
	end

	-- A snail carrying a geode shell, crystals growing out of the top.
	S.rd_snail = {
		label = "Snail",
		set = "rainbow_road",
		tint = C3(255, 196, 214),
		scale = 1.10,
		head = CFrame.new(0, 0.74, 0.62),
		neck = CFrame.new(0, -0.36, 0.86),
		back = CFrame.new(0, 0.70, -1.24),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.60, 1.20, 2.00),
				eyeY = 0.04, eyeSize = Vector3.new(0.44, 0.52, 0.22), eyeSpread = 0.38,
				mouthY = -0.30, mouthSize = Vector3.new(0.26, 0.12, 0.12),
				legs = false, tail = false,
			})
			-- The foot: a long slab with a tapered tail behind the shell.
			c:box(Vector3.new(1.80, 0.28, 2.30), CFrame.new(0, -0.62, -0.10), p.light)
			c:box(Vector3.new(1.10, 0.22, 0.40), CFrame.new(0, -0.64, -1.42), p.light)
			-- The shell, with a squared spiral on each side.
			c:box(Vector3.new(1.24, 1.16, 1.30), CFrame.new(0, 0.66, -0.52), p.base)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.08, 0.92, 0.98), CFrame.new(0.63 * s, 0.66, -0.52), p.dark)
				c:box(Vector3.new(0.10, 0.56, 0.56), CFrame.new(0.65 * s, 0.70, -0.48) * CFrame.Angles(math.pi / 4, 0, 0), p.light)
				c:box(Vector3.new(0.12, 0.24, 0.24), CFrame.new(0.67 * s, 0.74, -0.44), p.deep)
				-- Antennae with crystal-bead tips, and cheeks.
				local tip = Vector3.new(0.40 * s, 1.08, 0.86)
				c:rod(Vector3.new(0.24 * s, 0.60, 0.70), tip, 0.05, p.base, nil, false)
				c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(tip), hue(p, s < 0 and 5 or 1), GLASS)
				c:box(Vector3.new(0.18, 0.10, 0.04), CFrame.new(0.52 * s, -0.16, 1.01), BLUSH)
			end
			-- Rainbow crystals sprouting from the geode.
			local top = 1.24
			crystal(c, Vector3.new(0, top, -0.52), CFrame.Angles(0, math.pi / 4, 0), 0.28, 0.50, hue(p, 6))
			crystal(c, Vector3.new(-0.32, top - 0.02, -0.30), CFrame.Angles(0.30, 0, 0.35), 0.24, 0.34, hue(p, 1))
			crystal(c, Vector3.new(0.32, top - 0.02, -0.30), CFrame.Angles(0.30, 0, -0.35), 0.24, 0.38, hue(p, 3))
			crystal(c, Vector3.new(-0.30, top - 0.04, -0.82), CFrame.Angles(-0.30, 0, 0.35), 0.22, 0.30, hue(p, 4))
			crystal(c, Vector3.new(0.30, top - 0.04, -0.82), CFrame.Angles(-0.30, 0, -0.35), 0.22, 0.32, hue(p, 5))
		end,
	}

	-- A little cloud with a blocky rainbow arching over its back.
	S.rd_cloudling = {
		label = "Cloudling",
		set = "rainbow_road",
		tint = C3(236, 228, 255),
		scale = 1.08,
		head = CFrame.new(0, 1.16, 0.25),
		neck = CFrame.new(0, -0.40, 0.76),
		back = CFrame.new(0, 0.30, -0.82),
		build = function(c, p)
			block(c, p, {
				shape = "round",
				bodySize = Vector3.new(2.06, 1.30, 1.60),
				bodyColor = p.pale,
				eyeY = 0.04, eyeSize = Vector3.new(0.42, 0.50, 0.22), eyeSpread = 0.40,
				mouthY = -0.28, mouthSize = Vector3.new(0.28, 0.12, 0.12),
				legs = false, tail = false,
			})
			-- Soft lumps make the outline a cloud.
			c:round(Vector3.new(1.10, 0.80, 0.90), CFrame.new(0.05, 0.76, 0), p.pale)
			c:round(Vector3.new(0.84, 0.66, 0.90), CFrame.new(-0.62, 0.62, 0), p.pale)
			c:round(Vector3.new(0.80, 0.62, 0.86), CFrame.new(0.66, 0.58, 0.04), p.pale)
			for _, s in ipairs({ -1, 1 }) do
				c:round(Vector3.new(0.62, 0.86, 1.10), CFrame.new(1.06 * s, -0.04, 0), p.pale)
				c:box(Vector3.new(0.18, 0.10, 0.04), CFrame.new(0.66 * s, -0.16, 0.80), BLUSH)
			end
			-- Five nested square arches, red outside to blue inside.
			for i = 0, 4 do
				local w, top, th = 1.34 - 0.13 * i, 1.62 - 0.13 * i, 0.13
				local col = hue(p, i + 1)
				local legH = top - 0.30
				for _, s in ipairs({ -1, 1 }) do
					c:box(Vector3.new(th, legH, 0.24), CFrame.new((w - th * 0.5) * s, 0.30 + legH * 0.5, -0.62), col)
				end
				c:box(Vector3.new(w * 2, th, 0.24), CFrame.new(0, top - th * 0.5, -0.62), col)
			end
		end,
	}

	-- A hedgehog whose quills are rainbow crystal shards.
	S.rd_hedgehog = {
		label = "Hedgehog",
		set = "rainbow_road",
		tint = C3(214, 168, 128),
		head = CFrame.new(0, 1.24, 0.30),
		neck = CFrame.new(0, -0.40, 0.70),
		back = CFrame.new(0, 0.80, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				bodySize = Vector3.new(1.90, 1.60, 1.90),
				snout = { w = 0.44, h = 0.34, d = 0.56, y = -0.24, color = p.pale, nose = INK },
				bib = { w = 1.30, h = 1.10, y = -0.10, color = p.pale },
				legSize = Vector3.new(0.36, 0.26, 0.40), legY = -0.80, legColor = p.dark,
				tail = false,
			})
			local centre = Vector3.new(0, 0.10, -0.15)
			local dirs = {
				{ -0.40, 0.85, 0.30 }, { 0.40, 0.85, 0.30 }, { 0.05, 0.90, 0.10 },
				{ -0.75, 0.60, 0.00 }, { 0.75, 0.60, 0.00 }, { -0.35, 0.70, -0.55 }, { 0.35, 0.70, -0.55 },
				{ -0.85, 0.20, -0.40 }, { 0.85, 0.20, -0.40 }, { 0.00, 0.45, -0.85 },
				{ -0.45, 0.10, -0.85 }, { 0.45, 0.10, -0.85 }, { 0.02, -0.20, -0.95 },
			}
			for i, d in ipairs(dirs) do
				local u = Vector3.new(d[1], d[2], d[3]).Unit
				local at = centre + u * 0.92
				c:cone(
					Vector3.new(0.34, 0.62, 0.34),
					CFrame.lookAt(at, at + u) * CFrame.Angles(-math.pi / 2, 0, 0),
					hue(p, i),
					GLASS
				).Reflectance = 0.1
			end
		end,
	}

	-- An axolotl with crystal-tipped gill fronds, a wide smile and a finned tail.
	S.rd_axolotl = {
		label = "Axolotl",
		set = "rainbow_road",
		tint = C3(255, 184, 208),
		scale = 1.08,
		head = CFrame.new(0, 1.04, 0.20),
		neck = CFrame.new(0, -0.38, 0.72),
		back = CFrame.new(0, 0.30, -0.72),
		build = function(c, p)
			block(c, p, {
				shape = "round",
				bodySize = Vector3.new(2.06, 1.46, 1.90),
				eyeY = 0.10, eyeSize = Vector3.new(0.40, 0.46, 0.22), eyeSpread = 0.50,
				mouthY = -0.24, mouthSize = Vector3.new(0.70, 0.08, 0.12),
				legSize = Vector3.new(0.34, 0.28, 0.40), legX = 0.76, legY = -0.74, legColor = p.light,
				tail = false,
			})
			-- Three gill fronds a side, fanning up and out, each ending in a crystal.
			local fronds = { { 0.62, 0.20, 0.42 }, { 0.30, 0.28, 0.20 }, { -0.02, 0.26, -0.04 } }
			for _, s in ipairs({ -1, 1 }) do
				for k, f in ipairs(fronds) do
					local root = Vector3.new(0.92 * s, f[1], 0.30)
					local dir = Vector3.new(f[2] * s, f[3], -0.10)
					local tip = root + dir
					c:rod(root, tip, 0.07, p.dark, nil, false)
					c:cone(
						Vector3.new(0.22, 0.34, 0.22),
						CFrame.lookAt(tip, tip + dir) * CFrame.Angles(-math.pi / 2, 0, 0) * CFrame.new(0, 0.10, 0),
						hue(p, s < 0 and k or k + 3),
						GLASS
					)
				end
				c:box(Vector3.new(0.20, 0.10, 0.04), CFrame.new(0.66 * s, -0.12, 0.92), BLUSH)
			end
			-- Tail and its fin, and a frill down the back.
			c:box(Vector3.new(0.42, 0.46, 0.70), CFrame.new(0, -0.10, -1.20), p.base)
			c:box(Vector3.new(0.10, 0.80, 1.00), CFrame.new(0, -0.06, -1.30), p.pale)
			c:box(Vector3.new(0.10, 0.24, 1.40), CFrame.new(0, 0.88, -0.30), p.pale)
		end,
	}

	-- A toucan with a big striped rainbow bill.
	S.rd_toucan = {
		label = "Toucan",
		set = "rainbow_road",
		tint = C3(46, 50, 70),
		-- The bill makes it the longest body in the set.
		scale = 1.12,
		head = CFrame.new(0, 1.14, 0),
		neck = CFrame.new(0, -0.60, 0.70),
		back = CFrame.new(0, 0.20, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "bird",
				bodySize = Vector3.new(1.76, 1.90, 1.66),
				mouth = false, tail = false,
				bib = { w = 1.00, h = 0.80, y = -0.40, color = p.pale },
				legSize = Vector3.new(0.32, 0.24, 0.40), legZ = { 0.16 }, legColor = C3(110, 150, 230),
			})
			for _, s in ipairs({ -1, 1 }) do
				-- Coloured skin round each eye, and folded wings.
				c:box(Vector3.new(0.66, 0.74, 0.12), CFrame.new(0.44 * s, 0.16, 0.86), hue(p, 5))
				c:box(Vector3.new(0.24, 0.96, 0.86), CFrame.new(0.94 * s, -0.10, -0.08) * CFrame.Angles(0, 0, 0.14 * s), p.dark)
			end
			-- The bill: three bands, yellow-green at the root to red at the hooked tip.
			c:box(Vector3.new(0.62, 0.62, 0.40), CFrame.new(0, -0.16, 1.02), hue(p, 3))
			c:box(Vector3.new(0.54, 0.52, 0.36), CFrame.new(0, -0.20, 1.32) * CFrame.Angles(0.10, 0, 0), hue(p, 2))
			c:box(Vector3.new(0.44, 0.40, 0.32), CFrame.new(0, -0.28, 1.58) * CFrame.Angles(0.22, 0, 0), hue(p, 1))
			c:cone(Vector3.new(0.34, 0.26, 0.24), CFrame.new(0, -0.46, 1.70) * CFrame.Angles(math.pi, 0, 0), hue(p, 1))
			c:box(Vector3.new(0.56, 0.05, 0.96), CFrame.new(0, -0.30, 1.30), INK)
			-- A crest of three rainbow tufts.
			for i = -1, 1 do
				c:cone(Vector3.new(0.20, 0.40, 0.20), CFrame.new(i * 0.22, 1.12, -0.04) * CFrame.Angles(-0.4, 0, -i * 0.35), hue(p, i + 6))
			end
			-- Tail: dark feathers and a bright patch under them.
			c:box(Vector3.new(0.62, 0.92, 0.26), CFrame.new(0, -0.52, -0.86) * CFrame.Angles(-0.35, 0, 0), p.dark)
			c:box(Vector3.new(0.50, 0.24, 0.30), CFrame.new(0, -0.72, -0.78), hue(p, 1))
		end,
	}

	return S
end
