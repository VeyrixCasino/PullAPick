--[[ PetBodies/RainbowRoadExtra -- more Rainbow Road recolour bodies (Common to Rare).
	Room for vastly different colours (owner, 2026-10-10: "recolors fore common,
	uncommon, rare. Vastly different colors tho."): a puppy in a rainbow
	bandana, a hamster with gem-stuffed cheeks, and a crystal-spotted fawn.
	Same house style and rainbow hues as PetBodies/RainbowRoad.
	See tools/gen/sets/README.md. ]]
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

	-- Blush marks either side of a face.
	local function cheeks(c, x, y, z)
		for _, s in ipairs({ -1, 1 }) do
			c:box(Vector3.new(0.18, 0.10, 0.04), CFrame.new(x * s, y, z), BLUSH)
		end
	end

	-- A puppy with floppy ears, a stepped rainbow bandana and a crystal on its back.
	S.rd_pup = {
		label = "Prismpup",
		set = "rainbow_road",
		tint = C3(236, 190, 120),
		scale = 1.10,
		head = CFrame.new(0, 1.04, 0.20),
		neck = CFrame.new(0, -0.40, 0.98),
		back = CFrame.new(0, 0.50, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				bodySize = Vector3.new(1.80, 1.60, 1.80),
				eyeY = 0.20, eyeSize = Vector3.new(0.36, 0.44, 0.20), eyeSpread = 0.36,
				snout = { w = 0.62, h = 0.38, d = 0.34, y = -0.22, color = p.pale, nose = INK },
				legColor = p.base,
				tailSize = Vector3.new(0.26, 0.26, 0.50), tailColor = p.dark,
			})
			K.ears(c, p.dark, "down", p.light)
			-- The bandana: four rainbow steps narrowing to a point under the chin.
			for k = 1, 4 do
				c:box(Vector3.new(0.92 - 0.20 * k, 0.10, 0.06), CFrame.new(0, -0.40 - 0.10 * k, 0.88), hue(p, k * 2 - 1))
			end
			crystal(c, Vector3.new(0, 0.80, -0.30), CFrame.Angles(0, math.pi / 4, 0), 0.22, 0.30, hue(p, 5))
			cheeks(c, 0.50, -0.08, 0.91)
		end,
	}

	-- A round hamster with gem-stuffed cheek pouches, hugging a big gem.
	S.rd_hamster = {
		label = "Gemster",
		set = "rainbow_road",
		tint = C3(240, 176, 110),
		head = CFrame.new(0, 1.10, 0.10),
		neck = CFrame.new(0, -0.30, 0.92),
		back = CFrame.new(0, 0.40, -0.86),
		build = function(c, p)
			block(c, p, {
				shape = "round",
				bodySize = Vector3.new(1.80, 1.50, 1.70),
				eyeY = 0.18, eyeSize = Vector3.new(0.32, 0.38, 0.20), eyeSpread = 0.34,
				mouthY = -0.14, mouthSize = Vector3.new(0.20, 0.08, 0.10),
				bib = { w = 1.00, h = 0.60, y = -0.42, color = p.pale },
				legSize = Vector3.new(0.30, 0.20, 0.34), legX = 0.46, legY = -0.70, legZ = { 0.30, -0.30 }, legColor = p.dark,
				tail = false,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.40, 0.36, 0.20), CFrame.new(0.50 * s, 0.92, 0.00), p.dark)
				c:box(Vector3.new(0.22, 0.20, 0.06), CFrame.new(0.50 * s, 0.90, 0.12), p.light)
				c:round(Vector3.new(0.44, 0.44, 0.40), CFrame.new(0.84 * s, -0.16, 0.50), p.light)
				c:round(Vector3.new(0.24, 0.20, 0.20), CFrame.new(0.24 * s, -0.48, 0.98), p.pale)
			end
			c:box(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0, -0.46, 0.98) * CFrame.Angles(math.pi / 4, 0, math.pi / 4), hue(p, 1), GLASS)
			-- A stripe of little gems down its back.
			for k, z in ipairs({ 0.30, -0.10, -0.50 }) do
				c:box(Vector3.new(0.30, 0.06, 0.30), CFrame.new(0, 0.79 - 0.02 * k, z) * CFrame.Angles(0, math.pi / 4, 0), hue(p, k * 2 + 1), GLASS)
			end
			cheeks(c, 0.44, -0.08, 0.86)
		end,
	}

	-- A long-legged fawn with wide ears, crystal spots and two crystal antler nubs.
	S.rd_fawn = {
		label = "Gemfawn",
		set = "rainbow_road",
		tint = C3(214, 150, 96),
		head = CFrame.new(0, 1.30, 0.10),
		neck = CFrame.new(0, -0.30, 0.94),
		back = CFrame.new(0, 0.80, -0.70),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.60, 1.50, 1.80),
				eyeY = 0.20, eyeSize = Vector3.new(0.38, 0.46, 0.20), eyeSpread = 0.34,
				snout = { w = 0.44, h = 0.30, d = 0.30, y = -0.24, color = p.pale, nose = INK },
				legSize = Vector3.new(0.30, 0.70, 0.30), legX = 0.48, legY = -0.90, legZ = { 0.50, -0.50 }, legColor = p.dark,
				tailSize = Vector3.new(0.24, 0.30, 0.20), tailColor = p.pale,
			})
			for _, s in ipairs({ -1, 1 }) do
				local ear = CFrame.new(0.92 * s, 0.70, 0.00) * CFrame.Angles(0, 0, -0.35 * s)
				c:box(Vector3.new(0.56, 0.26, 0.16), ear, p.base)
				c:box(Vector3.new(0.36, 0.14, 0.06), ear * CFrame.new(0.04 * s, 0, 0.08), p.pale)
				crystal(c, Vector3.new(0.28 * s, 0.81, 0.20), CFrame.Angles(0, 0, -0.25 * s), 0.16, 0.20, hue(p, s < 0 and 6 or 3))
			end
			-- Crystal spots: three diamonds on the back, one on each flank.
			for k, q in ipairs({ { -0.40, -0.20 }, { 0.30, -0.50 }, { 0.00, -0.80 } }) do
				c:box(Vector3.new(0.22, 0.06, 0.22), CFrame.new(q[1], 0.82, q[2]) * CFrame.Angles(0, math.pi / 4, 0), hue(p, k + 1), GLASS)
			end
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.06, 0.22, 0.22), CFrame.new(0.81 * s, 0.28, -0.45) * CFrame.Angles(math.pi / 4, 0, 0), hue(p, s < 0 and 5 or 7), GLASS)
			end
			cheeks(c, 0.48, -0.10, 0.91)
		end,
	}

	return S
end
