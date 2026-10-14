--[[ PetBodies/SugarRushTop -- Sugar Rush's top bodies. See tools/gen/sets/README.md.

	Epic and up: each body here is worn by exactly ONE pet in the game, so no
	two of them share a silhouette. The set is candy, pastels and playful
	collecting, so every body is a sweet you could name across the mine:
	macarons, gumballs, sundaes, piñatas, a carousel. Epic stays charming and
	clean; Legendary gets frosting and gold; Mythic, Divine and Exotic get neon
	sugar-glow, halos and crowns, echoing the top packs, "Royal Confectionery"
	and "Infinite Sweetness".
]]
return function(K)
	local C3, block, ears, wings = K.C3, K.block, K.ears, K.wings
	local INK, WHITE, NEON, GLASS, METAL = K.INK, K.WHITE, K.NEON, K.GLASS, K.METAL
	local S = {}

	local SIDES = { -1, 1 }
	local UP = CFrame.Angles(0, 0, math.pi / 2) -- a cylinder standing up
	local FRONT = CFrame.Angles(0, math.pi / 2, 0) -- a cylinder's flat face to the front
	local BLUSH = C3(255, 150, 182)
	local SPRINKLES = { C3(255, 90, 110), C3(90, 190, 255), C3(255, 220, 80), C3(140, 230, 120), C3(200, 120, 255) }
	local GOLD, GOLD_DARK = C3(255, 206, 84), C3(214, 160, 56)
	local CREAM, CHERRY, STEM = C3(255, 248, 232), C3(214, 36, 58), C3(96, 140, 60)
	local ORANGE, CHOC, WAFER = C3(255, 166, 62), C3(96, 56, 36), C3(232, 196, 130)
	local DOUGH, COOKIE, STICK = C3(222, 164, 96), C3(214, 160, 92), C3(248, 246, 240)
	local BUBBLE, LEAF, BUTTER = C3(255, 140, 200), C3(110, 200, 90), C3(255, 240, 150)
	local GLASSY = C3(220, 240, 255)

	-- Rosy cheeks either side of a face.
	local function blush(c, x, y, z)
		for _, s in ipairs(SIDES) do
			c:box(Vector3.new(0.22, 0.12, 0.06), CFrame.new(x * s, y, z), BLUSH)
		end
	end

	-- Sprinkles: { x, y, z, roll, yaw } rows, colours cycling through the jar.
	local function sprinkles(c, list)
		for i, v in ipairs(list) do
			c:box(Vector3.new(0.18, 0.06, 0.06), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0, v[5] or 0, v[4]), SPRINKLES[(i - 1) % #SPRINKLES + 1])
		end
	end

	-- A cherry on its stem.
	local function cherry(c, x, y, z, d)
		c:ball(Vector3.new(d, d, d), CFrame.new(x, y, z), CHERRY)
		c:rod(Vector3.new(x, y + d * 0.4, z), Vector3.new(x + 0.10, y + d * 0.4 + 0.24, z - 0.04), 0.03, STEM, nil, false)
	end

	-- A floating square halo of four glowing bars.
	local function halo(c, y, z, r, colour)
		c:box(Vector3.new(r * 2 + 0.10, 0.08, 0.10), CFrame.new(0, y, z + r), colour, NEON)
		c:box(Vector3.new(r * 2 + 0.10, 0.08, 0.10), CFrame.new(0, y, z - r), colour, NEON)
		c:box(Vector3.new(0.10, 0.08, r * 2), CFrame.new(-r, y, z), colour, NEON)
		c:box(Vector3.new(0.10, 0.08, r * 2), CFrame.new(r, y, z), colour, NEON)
	end

	-- A little gold crown: a band, three diamond points and a glowing gem.
	local function crown(c, y, z, w, gem)
		c:box(Vector3.new(w, 0.14, w * 0.8), CFrame.new(0, y, z), GOLD, METAL)
		for _, x in ipairs({ -w * 0.34, 0, w * 0.34 }) do
			c:box(Vector3.new(0.13, 0.13, 0.10), CFrame.new(x, y + 0.13, z + w * 0.3) * CFrame.Angles(0, 0, math.pi / 4), GOLD, METAL)
		end
		c:ball(Vector3.new(0.14, 0.14, 0.14), CFrame.new(0, y, z + w * 0.4 + 0.02), gem, NEON)
	end

	----------------------------------------------------------------------------
	-- EPIC: charming and clean.
	----------------------------------------------------------------------------

	-- A macaron on tiny feet: two round shells, ruffled feet and a cream filling.
	S.sr_t_macaron = {
		label = "Macaron Tot",
		set = "sugar_rush",
		tint = C3(255, 150, 200),
		head = CFrame.new(0, 1.04, 0.10),
		neck = CFrame.new(0, 0.06, 0.98),
		back = CFrame.new(0, 0.10, -0.98),
		build = function(c, p)
			c:round(Vector3.new(2.00, 0.66, 1.90), CFrame.new(0, -0.42, 0), p.base)
			c:box(Vector3.new(2.06, 0.14, 1.96), CFrame.new(0, -0.12, 0), p.light)
			c:box(Vector3.new(1.88, 0.26, 1.78), CFrame.new(0, 0.06, 0), p.pale)
			c:box(Vector3.new(2.06, 0.14, 1.96), CFrame.new(0, 0.24, 0), p.light)
			c:round(Vector3.new(2.00, 0.70, 1.90), CFrame.new(0, 0.58, 0), p.base)
			c:eyes(0.62, 0.92, 0.36, 0.16)
			c:box(Vector3.new(0.26, 0.08, 0.06), CFrame.new(0, 0.40, 0.95), INK)
			blush(c, 0.56, 0.42, 0.80)
			for _, s in ipairs(SIDES) do
				c:ball(Vector3.new(0.30, 0.30, 0.30), CFrame.new(1.02 * s, 0.06, 0.30), p.pale)
				c:box(Vector3.new(0.40, 0.20, 0.50), CFrame.new(0.50 * s, -0.84, 0.20), p.deep)
				c:box(Vector3.new(0.36, 0.24, 0.12), CFrame.new(0.22 * s, 1.00, 0.20) * CFrame.Angles(0, 0, 0.4 * s), p.dark)
			end
			c:box(Vector3.new(0.18, 0.18, 0.16), CFrame.new(0, 1.00, 0.20), p.dark)
		end,
	}

	-- A ring donut lying flat: golden dough, a frosted top, sprinkles, a face.
	S.sr_t_donut = {
		label = "Sprinkle Donut",
		set = "sugar_rush",
		tint = C3(255, 80, 170),
		head = CFrame.new(0, 0.46, -0.66),
		neck = CFrame.new(0, -0.20, 1.04),
		back = CFrame.new(0, 0.10, -1.04),
		build = function(c, p)
			-- { x, z, w, d }: front, back and two sides of the ring.
			for _, v in ipairs({ { 0, 0.67, 2.00, 0.66 }, { 0, -0.67, 2.00, 0.66 }, { -0.67, 0, 0.66, 0.68 }, { 0.67, 0, 0.66, 0.68 } }) do
				c:box(Vector3.new(v[3], 0.62, v[4]), CFrame.new(v[1], -0.06, v[2]), DOUGH)
				c:box(Vector3.new(v[3] + 0.04, 0.20, v[4] + 0.04), CFrame.new(v[1], 0.32, v[2]), p.base)
			end
			c:eyes(-0.02, 1.00, 0.40, 0.15)
			c:box(Vector3.new(0.24, 0.08, 0.06), CFrame.new(0, -0.24, 1.01), INK)
			blush(c, 0.64, -0.18, 1.01)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.20, 0.26, 0.06), CFrame.new(0.86 * s, 0.12, 1.02), p.base)
				c:box(Vector3.new(0.34, 0.18, 0.40), CFrame.new(0.50 * s, -0.46, 0.66), p.deep)
			end
			sprinkles(c, {
				{ -0.60, 0.43, 0.68, 0, 0.5 }, { 0.40, 0.43, 0.76, 0, -0.8 }, { 0.70, 0.43, 0.10, 0, 1.2 },
				{ -0.72, 0.43, -0.20, 0, 0.2 }, { 0.10, 0.43, -0.70, 0, -0.3 }, { -0.40, 0.43, -0.64, 0, 1.0 },
			})
		end,
	}

	-- A gumball machine: a face on the base, a see-through globe of gumballs.
	S.sr_t_gumball = {
		label = "Gumball Bot",
		set = "sugar_rush",
		tint = C3(230, 30, 50),
		scale = 1.15,
		head = CFrame.new(0, 2.14, 0),
		neck = CFrame.new(0, -0.50, 0.74),
		back = CFrame.new(0, -0.30, -0.74),
		build = function(c, p)
			c:box(Vector3.new(1.50, 1.00, 1.40), CFrame.new(0, -0.40, 0), p.base)
			c:box(Vector3.new(1.60, 0.14, 1.50), CFrame.new(0, -0.86, 0), p.dark)
			c:eyes(-0.22, 0.72, 0.34, 0.15)
			c:box(Vector3.new(0.40, 0.20, 0.10), CFrame.new(0, -0.62, 0.72), p.deep)
			c:cyl(Vector3.new(0.12, 0.30, 0.30), CFrame.new(0.80, -0.40, 0.20), STICK, METAL)
			c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.90, -0.28, 0.20), p.light)
			c:box(Vector3.new(1.20, 0.16, 1.10), CFrame.new(0, 0.16, 0), p.dark)
			-- The gumballs sit inside a clear globe.
			for i, v in ipairs({
				{ -0.40, 0.56, 0.30 }, { 0.30, 0.50, 0.36 }, { 0, 0.62, -0.30 }, { 0.44, 0.86, -0.10 },
				{ -0.36, 0.92, -0.06 }, { 0.06, 1.10, 0.32 }, { -0.04, 0.48, -0.02 },
			}) do
				c:ball(Vector3.new(0.38, 0.38, 0.38), CFrame.new(v[1], v[2], v[3]), SPRINKLES[(i - 1) % #SPRINKLES + 1])
			end
			c:ball(Vector3.new(1.70, 1.70, 1.70), CFrame.new(0, 0.98, 0), GLASSY, GLASS).Transparency = 0.45
			c:box(Vector3.new(0.70, 0.18, 0.70), CFrame.new(0, 1.86, 0), p.base)
			c:ball(Vector3.new(0.26, 0.26, 0.26), CFrame.new(0, 2.02, 0), p.dark)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.40, 0.20, 0.50), CFrame.new(0.44 * s, -1.02, 0.10), p.deep)
			end
			blush(c, 0.56, -0.40, 0.71)
		end,
	}

	-- A caterpillar of jellybeans, each a shade apart, with bobbly antennae.
	S.sr_t_jellybean = {
		label = "Jellybean Crawler",
		set = "sugar_rush",
		tint = C3(160, 235, 40),
		scale = 1.15,
		head = CFrame.new(0, 0.72, 0.70),
		neck = CFrame.new(0, -0.30, 1.18),
		back = CFrame.new(0, 0.40, -0.80),
		build = function(c, p)
			-- { w, h, d, y, z, yaw, colour } from the head back.
			for i, b in ipairs({
				{ 1.20, 1.10, 0.96, 0.10, 0.74, 0.0, p.base },
				{ 1.04, 0.92, 0.80, -0.02, 0.02, 0.25, p.light },
				{ 0.92, 0.84, 0.72, -0.06, -0.62, -0.25, p.base },
				{ 0.80, 0.74, 0.62, -0.10, -1.14, 0.25, p.light },
				{ 0.62, 0.56, 0.50, -0.16, -1.56, -0.20, p.base },
			}) do
				c:round(Vector3.new(b[1], b[2], b[3]), CFrame.new(0, b[4], b[5]) * CFrame.Angles(0, b[6], 0), b[7])
				if i <= 3 then
					c:box(Vector3.new(0.30, 0.04, 0.12), CFrame.new(-0.18, b[4] + b[2] * 0.5 - 0.02, b[5]), WHITE)
				end
				if i >= 2 and i <= 4 then
					for _, s in ipairs(SIDES) do
						c:box(Vector3.new(0.18, 0.20, 0.20), CFrame.new(0.34 * s, -0.54, b[5]), p.deep)
					end
				end
			end
			c:eyes(0.20, 1.18, 0.28, 0.15)
			c:box(Vector3.new(0.22, 0.07, 0.05), CFrame.new(0, -0.12, 1.21), INK)
			blush(c, 0.40, -0.06, 1.10)
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.22 * s, 0.60, 0.80), Vector3.new(0.40 * s, 1.04, 0.96), 0.04, p.deep, nil, false)
				c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0.40 * s, 1.04, 0.96), p.glow)
			end
		end,
	}

	-- A square marshmallow chick with a toasted top that drips down its sides.
	S.sr_t_toastymallow = {
		label = "Toasty Mallow",
		set = "sugar_rush",
		tint = C3(255, 190, 140),
		head = CFrame.new(0, 1.30, 0.02),
		neck = CFrame.new(0, -0.30, 0.90),
		back = CFrame.new(0, 0.10, -0.90),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.80, 1.70, 1.70), bodyColor = p.pale,
				eyeY = 0.18, eyeSpread = 0.38, eyeSize = Vector3.new(0.40, 0.48, 0.18), mouth = false,
				legSize = Vector3.new(0.30, 0.20, 0.44), legX = 0.36, legY = -0.86, legZ = { 0.20 },
				legColor = ORANGE, tail = false,
			})
			c:box(Vector3.new(1.86, 0.26, 1.76), CFrame.new(0, 0.86, 0), p.base)
			c:box(Vector3.new(0.24, 0.30, 0.06), CFrame.new(-0.56, 0.60, 0.87), p.base)
			c:box(Vector3.new(0.20, 0.24, 0.06), CFrame.new(0.62, 0.63, 0.87), p.base)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.06, 0.34, 0.24), CFrame.new(0.91 * s, 0.58, 0.30 * s), p.base)
				c:box(Vector3.new(0.18, 0.56, 0.80), CFrame.new(0.96 * s, -0.04, 0) * CFrame.Angles(0, 0, -0.25 * s), p.light)
			end
			c:cone(Vector3.new(0.30, 0.30, 0.24), CFrame.new(0, -0.10, 0.94) * CFrame.Angles(math.pi / 2, 0, 0), ORANGE)
			c:cone(Vector3.new(0.20, 0.34, 0.20), CFrame.new(-0.14, 1.12, 0.10) * CFrame.Angles(0, 0, 0.35), p.base)
			c:cone(Vector3.new(0.20, 0.40, 0.20), CFrame.new(0, 1.16, 0.10), p.base)
			c:cone(Vector3.new(0.20, 0.34, 0.20), CFrame.new(0.14, 1.12, 0.10) * CFrame.Angles(0, 0, -0.35), p.base)
			blush(c, 0.60, -0.10, 0.86)
		end,
	}

	-- A candy-cane snake: two striped coils, a neck and a curled-over head.
	S.sr_t_candysnake = {
		label = "Peppermint Snake",
		set = "sugar_rush",
		tint = C3(20, 170, 110),
		head = CFrame.new(0, 1.70, 0.16),
		neck = CFrame.new(0, 0.66, 0.76),
		back = CFrame.new(0, -0.10, -0.86),
		build = function(c, p)
			c:box(Vector3.new(1.90, 0.56, 1.70), CFrame.new(0, -0.62, 0), p.pale)
			c:box(Vector3.new(1.44, 0.50, 1.26), CFrame.new(0, -0.10, -0.06), p.base)
			c:box(Vector3.new(0.76, 0.70, 0.76), CFrame.new(0, 0.48, -0.10), p.pale)
			c:box(Vector3.new(1.16, 0.86, 1.10), CFrame.new(0, 1.08, 0.18), p.base)
			-- Candy stripes wrap every coil.
			for _, x in ipairs({ -0.60, 0, 0.60 }) do
				c:box(Vector3.new(0.18, 0.60, 1.74), CFrame.new(x, -0.62, 0) * CFrame.Angles(0, 0, 0.5), p.base)
			end
			for _, x in ipairs({ -0.36, 0.36 }) do
				c:box(Vector3.new(0.16, 0.54, 1.30), CFrame.new(x, -0.10, -0.06) * CFrame.Angles(0, 0, 0.5), p.pale)
			end
			c:box(Vector3.new(0.80, 0.14, 0.80), CFrame.new(0, 0.50, -0.10) * CFrame.Angles(0, 0, 0.4), p.base)
			c:box(Vector3.new(0.50, 0.30, 0.40), CFrame.new(0, 1.58, 0.42) * CFrame.Angles(0.5, 0, 0), p.pale)
			c:eyes(1.14, 0.74, 0.28, 0.15)
			c:box(Vector3.new(0.30, 0.07, 0.05), CFrame.new(0, 0.86, 0.74), INK)
			c:box(Vector3.new(0.10, 0.04, 0.20), CFrame.new(0, 0.82, 0.84), C3(255, 90, 120))
			c:cone(Vector3.new(0.30, 0.50, 0.30), CFrame.new(0.80, -0.40, -0.80) * CFrame.Angles(0, 0, -0.6), p.base)
			blush(c, 0.40, 0.92, 0.74)
		end,
	}

	-- A snail carrying a peppermint swirl for a shell.
	S.sr_t_mintsnail = {
		label = "Mint Swirl Snail",
		set = "sugar_rush",
		tint = C3(110, 215, 255),
		head = CFrame.new(0, 1.40, -0.30),
		neck = CFrame.new(0, -0.30, 1.30),
		back = CFrame.new(0, 0.40, -1.24),
		build = function(c, p)
			c:box(Vector3.new(1.10, 0.44, 2.30), CFrame.new(0, -0.70, 0.10), p.light)
			c:box(Vector3.new(1.00, 0.86, 0.60), CFrame.new(0, -0.28, 0.98), p.light)
			c:box(Vector3.new(0.70, 0.30, 0.40), CFrame.new(0, -0.78, -1.18), p.light)
			c:eyes(-0.16, 1.28, 0.24, 0.14)
			c:box(Vector3.new(0.20, 0.06, 0.05), CFrame.new(0, -0.44, 1.29), INK)
			blush(c, 0.38, -0.36, 1.29)
			-- The shell: a disc with red wedges on both faces.
			c:cyl(Vector3.new(0.90, 1.90, 1.90), CFrame.new(0, 0.38, -0.32), p.pale)
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.24 * s, 0.12, 1.06), Vector3.new(0.36 * s, 0.56, 1.16), 0.05, p.light, nil, false)
				c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(0.36 * s, 0.56, 1.16), p.base)
				for _, a in ipairs({ 0, math.pi / 3, 2 * math.pi / 3 }) do
					c:box(Vector3.new(0.04, 1.72, 0.26), CFrame.new(0.47 * s, 0.38, -0.32) * CFrame.Angles(a, 0, 0), p.base)
				end
				c:cyl(Vector3.new(0.06, 0.40, 0.40), CFrame.new(0.48 * s, 0.38, -0.32), p.base)
			end
		end,
	}

	-- A chocolate bar standing up in its half-peeled wrapper.
	S.sr_t_chocobar = {
		label = "Chocobar Chomper",
		set = "sugar_rush",
		tint = C3(130, 74, 44),
		head = CFrame.new(0, 1.14, 0),
		neck = CFrame.new(0, -0.20, 0.58),
		back = CFrame.new(0, 0.30, -0.58),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.70, 2.10, 1.00),
				eyeY = 0.42, eyeSpread = 0.36, eyeSize = Vector3.new(0.40, 0.48, 0.18),
				mouthY = 0.04, mouthSize = Vector3.new(0.46, 0.14, 0.12),
				legSize = Vector3.new(0.40, 0.30, 0.50), legX = 0.44, legY = -1.10, legZ = { 0.0 },
				legColor = p.deep, tail = false,
			})
			-- Grooves between the squares.
			c:box(Vector3.new(1.72, 0.05, 0.04), CFrame.new(0, 0.84, 0.50), p.dark)
			c:box(Vector3.new(0.05, 0.27, 0.04), CFrame.new(0, 0.98, 0.50), p.dark)
			-- Wrapper, its label band, and foil peeking out of the top.
			c:box(Vector3.new(1.80, 0.84, 1.10), CFrame.new(0, -0.58, 0), p.light)
			c:box(Vector3.new(1.84, 0.22, 1.14), CFrame.new(0, -0.56, 0), p.pale)
			for _, x in ipairs({ -0.66, -0.36, 0.36, 0.66 }) do
				c:box(Vector3.new(0.16, 0.16, 0.04), CFrame.new(x, -0.12, 0.54) * CFrame.Angles(0, 0, math.pi / 4), STICK, METAL)
			end
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.30, 0.46, 0.36), CFrame.new(1.00 * s, -0.02, 0) * CFrame.Angles(0, 0, -0.4 * s), p.base)
			end
			blush(c, 0.58, 0.10, 0.51)
		end,
	}

	-- A penguin made of an ice pop: rounded top, white bib, wooden stick.
	S.sr_t_icepop = {
		label = "Ice Pop Penguin",
		set = "sugar_rush",
		tint = C3(30, 90, 255),
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, -0.30, 0.66),
		back = CFrame.new(0, 0.30, -0.62),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.50, 2.00, 1.10),
				eyeY = 0.46, eyeSpread = 0.32, eyeSize = Vector3.new(0.36, 0.44, 0.18), mouth = false,
				bib = { w = 0.90, h = 1.00, y = -0.30, color = p.pale },
				legs = false, tail = false,
			})
			c:round(Vector3.new(1.50, 0.60, 1.10), CFrame.new(0, 1.06, 0), p.base)
			for _, v in ipairs({ { -0.56, 0.86 }, { 0.58, 0.96 }, { 0.40, 0.80 } }) do
				c:box(Vector3.new(0.10, 0.10, 0.04), CFrame.new(v[1], v[2], 0.56) * CFrame.Angles(0, 0, math.pi / 4), WHITE)
			end
			c:cone(Vector3.new(0.26, 0.26, 0.20), CFrame.new(0, 0.16, 0.66) * CFrame.Angles(math.pi / 2, 0, 0), ORANGE)
			c:box(Vector3.new(0.34, 0.56, 0.14), CFrame.new(0, -1.18, 0), WAFER)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.18, 0.80, 0.50), CFrame.new(0.84 * s, -0.10, 0) * CFrame.Angles(0, 0, -0.30 * s), p.dark)
				c:box(Vector3.new(0.36, 0.14, 0.46), CFrame.new(0.34 * s, -0.98, 0.26), ORANGE)
			end
			c:box(Vector3.new(0.16, 0.30, 0.06), CFrame.new(-0.50, -0.60, 0.56), p.light)
			c:box(Vector3.new(0.16, 0.24, 0.06), CFrame.new(0.54, -0.72, 0.56), p.light)
			blush(c, 0.56, 0.18, 0.56)
		end,
	}

	-- A floating puff of candyfloss on a striped paper cone.
	S.sr_t_flosscloud = {
		label = "Candyfloss Cloud",
		set = "sugar_rush",
		tint = C3(200, 170, 255),
		scale = 1.15,
		head = CFrame.new(0, 1.52, -0.10),
		neck = CFrame.new(0, -0.40, 0.70),
		back = CFrame.new(0, 0.40, -1.10),
		build = function(c, p)
			c:ball(Vector3.new(1.60, 1.60, 1.60), CFrame.new(0, 0.30, 0), p.base)
			c:ball(Vector3.new(1.10, 1.10, 1.10), CFrame.new(-0.84, 0.10, -0.06), p.light)
			c:ball(Vector3.new(1.10, 1.10, 1.10), CFrame.new(0.84, 0.10, -0.06), p.light)
			c:ball(Vector3.new(1.10, 1.10, 1.10), CFrame.new(0.12, 0.96, -0.16), p.pale)
			c:ball(Vector3.new(1.20, 1.20, 1.20), CFrame.new(0, 0.42, -0.60), p.light)
			c:ball(Vector3.new(0.80, 0.80, 0.80), CFrame.new(-0.48, 0.94, -0.36), p.base)
			c:cone(Vector3.new(0.70, 1.00, 0.70), CFrame.new(0, -0.86, 0) * CFrame.Angles(math.pi, 0, 0), WHITE)
			c:box(Vector3.new(0.60, 0.10, 0.60), CFrame.new(0, -0.52, 0), p.deep)
			c:eyes(0.40, 0.76, 0.28, 0.15)
			c:box(Vector3.new(0.22, 0.07, 0.06), CFrame.new(0, 0.12, 0.78), INK)
			blush(c, 0.48, 0.16, 0.63)
			c:star(Vector3.new(-1.10, 1.20, 0.20), 0.36, p.glow)
			c:star(Vector3.new(1.00, 1.30, -0.20), 0.30, p.glow)
		end,
	}

	-- A turtle wearing a chocolate-chip cookie for a shell.
	S.sr_t_cookieturtle = {
		label = "Chocochip Turtle",
		set = "sugar_rush",
		tint = C3(30, 150, 150),
		scale = 1.10,
		head = CFrame.new(0, 1.30, -0.14),
		neck = CFrame.new(0, -0.30, 1.04),
		back = CFrame.new(0, 0.40, -1.10),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.80, 1.20, 1.80),
				snout = { w = 0.80, h = 0.40, d = 0.40, y = -0.20, color = p.light, nose = p.deep },
				eyeY = 0.28, eyeSpread = 0.36, eyeSize = Vector3.new(0.36, 0.42, 0.18),
				legSize = Vector3.new(0.50, 0.36, 0.50), legX = 0.62, legY = -0.62, legZ = { 0.50, -0.50 },
				legColor = p.dark, tailSize = Vector3.new(0.24, 0.24, 0.40), tailColor = p.dark,
			})
			c:cyl(Vector3.new(0.40, 2.10, 2.10), CFrame.new(0, 0.80, -0.10) * UP, COOKIE)
			c:cyl(Vector3.new(0.30, 1.50, 1.50), CFrame.new(0, 1.12, -0.14) * UP, COOKIE)
			for _, v in ipairs({
				{ 0.30, 1.28, 0.10 }, { -0.30, 1.28, -0.30 }, { 0.10, 1.28, -0.50 },
				{ 0.80, 1.01, -0.20 }, { -0.78, 1.01, 0.30 }, { 0.20, 1.01, 0.76 },
			}) do
				c:box(Vector3.new(0.18, 0.12, 0.18), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0, 0.6, 0), CHOC)
			end
			blush(c, 0.62, 0.0, 0.91)
		end,
	}

	-- A swiss roll on six little legs, its swirl showing at both ends.
	S.sr_t_swissroll = {
		label = "Swirlroll Pillbug",
		set = "sugar_rush",
		tint = C3(255, 120, 100),
		head = CFrame.new(0, 0.92, 0),
		neck = CFrame.new(0, -0.30, 0.82),
		back = CFrame.new(0, 0.20, -0.82),
		build = function(c, p)
			c:cyl(Vector3.new(2.00, 1.60, 1.60), CFrame.new(0, 0.10, 0), p.base)
			for _, s in ipairs(SIDES) do
				c:cyl(Vector3.new(0.06, 1.30, 1.30), CFrame.new(1.02 * s, 0.10, 0), p.pale)
				c:cyl(Vector3.new(0.08, 0.86, 0.86), CFrame.new(1.04 * s, 0.10, 0), p.base)
				c:cyl(Vector3.new(0.10, 0.42, 0.42), CFrame.new(1.06 * s, 0.10, 0), p.pale)
				for _, x in ipairs({ -0.60, 0, 0.60 }) do
					c:box(Vector3.new(0.18, 0.26, 0.20), CFrame.new(x, -0.72, 0.36 * s), p.deep)
				end
				c:rod(Vector3.new(0.20 * s, 0.70, 0.50), Vector3.new(0.36 * s, 1.20, 0.70), 0.04, p.deep, nil, false)
				c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.36 * s, 1.20, 0.70), p.glow)
			end
			c:eyes(0.26, 0.80, 0.34, 0.16)
			c:box(Vector3.new(0.24, 0.07, 0.06), CFrame.new(0, -0.10, 0.79), INK)
			blush(c, 0.58, 0.0, 0.79)
		end,
	}

	-- A wobbly flan on a plate: caramel top, drips, cream and a cherry.
	S.sr_t_flan = {
		label = "Flan Wobbler",
		set = "sugar_rush",
		tint = C3(255, 220, 90),
		scale = 1.12,
		head = CFrame.new(0, 1.84, 0),
		neck = CFrame.new(0, -0.40, 0.94),
		back = CFrame.new(0, 0.10, -0.94),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.90, 1.40, 1.80),
				eyeY = 0.04, eyeSpread = 0.40, eyeSize = Vector3.new(0.40, 0.48, 0.18),
				mouthY = -0.30, mouthSize = Vector3.new(0.30, 0.12, 0.12),
				legs = false, tail = false,
			})
			c:box(Vector3.new(1.80, 0.22, 1.70), CFrame.new(0, 0.86, 0), p.deep)
			for _, v in ipairs({ { -0.62, 0.58, 0.34 }, { 0.66, 0.54, 0.42 }, { 0.10, 0.62, 0.26 } }) do
				c:box(Vector3.new(0.20, v[3], 0.06), CFrame.new(v[1], v[2], 0.91), p.deep)
			end
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.06, 0.40, 0.22), CFrame.new(0.96 * s, 0.54, 0.20 * s), p.deep)
			end
			c:cyl(Vector3.new(0.10, 2.30, 2.30), CFrame.new(0, -0.69, 0) * UP, WHITE)
			c:box(Vector3.new(0.56, 0.16, 0.56), CFrame.new(0, 1.04, 0), CREAM)
			c:cone(Vector3.new(0.46, 0.40, 0.46), CFrame.new(0, 1.32, 0), CREAM)
			cherry(c, 0, 1.62, 0, 0.36)
			blush(c, 0.64, -0.16, 0.91)
		end,
	}

	-- A round mochi seal with a dusting of sugar and a blossom on its head.
	S.sr_t_mochiseal = {
		label = "Mochi Seal",
		set = "sugar_rush",
		tint = C3(250, 236, 244),
		head = CFrame.new(0, 0.86, 0.10),
		neck = CFrame.new(0, -0.36, 1.06),
		back = CFrame.new(0, 0.30, -0.96),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.90, 1.40, 2.00),
				snout = { w = 0.56, h = 0.36, d = 0.30, y = -0.18, color = p.pale, nose = INK },
				eyeY = 0.14, eyeSpread = 0.36, eyeSize = Vector3.new(0.34, 0.42, 0.18),
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.70, 0.14, 0.44), CFrame.new(0.98 * s, -0.50, 0.40) * CFrame.Angles(0, 0.3 * s, -0.3 * s), p.dark)
				c:box(Vector3.new(0.40, 0.12, 0.60), CFrame.new(0.30 * s, -0.50, -1.08) * CFrame.Angles(0, 0.5 * s, 0), p.dark)
				c:box(Vector3.new(0.36, 0.03, 0.03), CFrame.new(0.42 * s, -0.14, 1.12) * CFrame.Angles(0, 0, 0.15 * s), WHITE)
				c:box(Vector3.new(0.36, 0.03, 0.03), CFrame.new(0.42 * s, -0.24, 1.12) * CFrame.Angles(0, 0, -0.10 * s), WHITE)
			end
			c:box(Vector3.new(1.30, 0.06, 1.30), CFrame.new(0, 0.75, 0), p.pale)
			c:box(Vector3.new(0.50, 0.06, 0.30), CFrame.new(0.20, 0.80, 0.10) * CFrame.Angles(0, 0.4, 0.15), LEAF)
			c:box(Vector3.new(0.24, 0.08, 0.24), CFrame.new(0, 0.84, 0.20) * CFrame.Angles(0, math.pi / 4, 0), BLUSH)
			blush(c, 0.48, -0.10, 1.00)
		end,
	}

	-- A hedgehog whose quills are sticks of rock candy.
	S.sr_t_sugarquill = {
		label = "Sugarquill Hog",
		set = "sugar_rush",
		tint = C3(255, 140, 30),
		head = CFrame.new(0, 1.30, -0.10),
		neck = CFrame.new(0, -0.30, 0.96),
		back = CFrame.new(0, 0.40, -0.96),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.80, 1.50, 1.80),
				snout = { w = 0.50, h = 0.36, d = 0.46, y = -0.18, color = p.pale, nose = INK },
				eyeY = 0.18, eyeSpread = 0.38, eyeSize = Vector3.new(0.34, 0.42, 0.18),
				legSize = Vector3.new(0.36, 0.30, 0.40), legX = 0.50, legY = -0.70, legZ = { 0.40, -0.40 },
				legColor = p.deep, tail = false,
			})
			-- { x, y, z, tilt back, tilt out }
			local quills = { p.light, p.pale, p.glow }
			for i, v in ipairs({
				{ 0, 0.98, 0.10, 0.2, 0 }, { -0.46, 0.94, -0.16, -0.1, 0.5 }, { 0.46, 0.94, -0.16, -0.1, -0.5 },
				{ 0, 0.92, -0.50, -0.6, 0 }, { -0.42, 0.76, -0.80, -0.9, 0.4 }, { 0.42, 0.76, -0.80, -0.9, -0.4 },
			}) do
				c:cone(Vector3.new(0.36, 0.60, 0.36), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(v[4], 0, v[5]), quills[(i - 1) % 3 + 1])
			end
			blush(c, 0.60, -0.06, 0.91)
		end,
	}

	-- A frog blowing a big bubblegum bubble.
	S.sr_t_bubblefrog = {
		label = "Bubblepop Frog",
		set = "sugar_rush",
		tint = C3(80, 200, 70),
		head = CFrame.new(0, 1.06, 0.10),
		neck = CFrame.new(0, -0.40, 0.84),
		back = CFrame.new(0, 0.30, -0.80),
		build = function(c, p)
			for _, s in ipairs(SIDES) do
				c:round(Vector3.new(0.62, 0.50, 0.56), CFrame.new(0.46 * s, 0.80, 0.56), p.base)
			end
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.90, 1.40, 1.70),
				eyeY = 0.62, eyeSpread = 0.46, eyeSize = Vector3.new(0.40, 0.46, 0.18), mouth = false,
				bib = { w = 1.00, h = 0.50, y = -0.36, color = p.pale },
				legSize = Vector3.new(0.44, 0.26, 0.52), legX = 0.70, legY = -0.62, legZ = { 0.40, -0.30 },
				legColor = p.dark, tail = false,
			})
			c:ball(Vector3.new(0.90, 0.90, 0.90), CFrame.new(0.10, -0.06, 1.30), BUBBLE)
			c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(-0.12, 0.18, 1.62), WHITE)
			for _, v in ipairs({ { -0.40, -0.30 }, { 0.36, -0.10 }, { 0, -0.56 } }) do
				c:box(Vector3.new(0.26, 0.10, 0.26), CFrame.new(v[1], 0.74, v[2]), p.dark)
			end
			blush(c, 0.50, 0.30, 0.82)
		end,
	}

	-- A waffle duckling: grid on its back, a pat of butter, a drip of syrup.
	S.sr_t_waffleduck = {
		label = "Waffle Duckling",
		set = "sugar_rush",
		tint = C3(225, 170, 70),
		head = CFrame.new(0, 1.10, 0.14),
		neck = CFrame.new(0, -0.30, 0.94),
		back = CFrame.new(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = Vector3.new(1.80, 1.70, 1.70),
				eyeY = 0.30, eyeSpread = 0.36, eyeSize = Vector3.new(0.36, 0.44, 0.18), mouth = false,
				legSize = Vector3.new(0.40, 0.14, 0.56), legX = 0.36, legY = -0.76, legZ = { 0.24 },
				legColor = ORANGE, tail = false,
			})
			c:box(Vector3.new(0.66, 0.16, 0.40), CFrame.new(0, 0.0, 1.00), ORANGE)
			for _, z in ipairs({ 0.0, 0.34 }) do
				c:box(Vector3.new(1.20, 0.06, 0.08), CFrame.new(0, 0.88, z), p.dark)
			end
			for _, x in ipairs({ -0.22, 0.22 }) do
				c:box(Vector3.new(0.08, 0.06, 0.90), CFrame.new(x, 0.88, 0.16), p.dark)
			end
			c:box(Vector3.new(0.44, 0.14, 0.44), CFrame.new(0, 0.96, 0.18) * CFrame.Angles(0, 0.3, 0), BUTTER)
			c:box(Vector3.new(0.14, 0.36, 0.06), CFrame.new(-0.56, 0.66, 0.72), p.deep)
			wings(c, p.light, 0.24, 0.0, -0.10, 0.25)
			c:cone(Vector3.new(0.40, 0.40, 0.30), CFrame.new(0, 0.30, -0.92) * CFrame.Angles(-0.8, 0, 0), p.base)
			blush(c, 0.52, 0.06, 0.87)
		end,
	}

	-- A little squid of licorice: a round mantle, side fins, rope tentacles.
	S.sr_t_licorice = {
		label = "Licorice Squiddle",
		set = "sugar_rush",
		tint = C3(64, 52, 84),
		head = CFrame.new(0, 1.00, 0),
		neck = CFrame.new(0, -0.40, 0.88),
		back = CFrame.new(0, 0.30, -0.88),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.80, 1.50, 1.70),
				eyeY = 0.20, eyeSpread = 0.38, eyeSize = Vector3.new(0.40, 0.48, 0.18),
				mouthY = -0.20, mouthSize = Vector3.new(0.24, 0.12, 0.10), mouthColor = BLUSH,
				legs = false, tail = false,
			})
			-- White eye patches, so dark eyes still read on a dark sweet.
			for _, s in ipairs(SIDES) do
				c:round(Vector3.new(0.56, 0.64, 0.10), CFrame.new(0.38 * s, 0.20, 0.84), WHITE)
			end
			for i = 1, 5 do
				local a = (i - 0.5) * 2 * math.pi / 5 + math.pi / 2
				local from = Vector3.new(0.50 * math.cos(a), -0.56, 0.46 * math.sin(a))
				local to = Vector3.new(0.86 * math.cos(a), -1.10, 0.80 * math.sin(a))
				c:rod(from, to, 0.11, p.dark, nil, false)
				c:ball(Vector3.new(0.26, 0.26, 0.26), CFrame.new(to), p.light)
			end
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.50, 0.40, 0.12), CFrame.new(0.66 * s, 0.86, -0.10) * CFrame.Angles(0, 0, -0.6 * s), p.light)
			end
			blush(c, 0.48, -0.04, 0.86)
		end,
	}

	----------------------------------------------------------------------------
	-- LEGENDARY: more ornate, with frosting, gold trim and candy colours.
	----------------------------------------------------------------------------

	-- A sundae in a footed glass: two scoops, a wafer, whipped cream, a cherry.
	S.sr_t_sundae = {
		label = "Sundae Tower",
		set = "sugar_rush",
		tint = C3(255, 100, 130),
		scale = 1.30,
		head = CFrame.new(0, 2.18, -0.04),
		neck = CFrame.new(0, -0.30, 0.80),
		back = CFrame.new(0, 0.40, -0.80),
		build = function(c, p)
			c:cyl(Vector3.new(0.12, 1.10, 1.10), CFrame.new(0, -1.08, 0) * UP, GLASSY, GLASS)
			c:cyl(Vector3.new(0.40, 0.26, 0.26), CFrame.new(0, -0.84, 0) * UP, GLASSY, GLASS)
			c:box(Vector3.new(1.70, 0.80, 1.50), CFrame.new(0, -0.30, 0), p.light, GLASS)
			c:box(Vector3.new(1.80, 0.10, 1.60), CFrame.new(0, 0.10, 0), GOLD, METAL)
			c:round(Vector3.new(1.60, 0.90, 1.44), CFrame.new(0, 0.40, 0), p.base)
			c:eyes(0.46, 0.70, 0.32, 0.15)
			c:box(Vector3.new(0.24, 0.07, 0.06), CFrame.new(0, 0.20, 0.72), INK)
			blush(c, 0.52, 0.28, 0.56)
			c:round(Vector3.new(1.30, 0.74, 1.16), CFrame.new(0, 1.00, -0.04), p.light)
			c:box(Vector3.new(0.16, 0.34, 0.08), CFrame.new(0.40, 0.90, 0.44), p.deep)
			c:box(Vector3.new(0.16, 0.30, 0.08), CFrame.new(-0.30, 0.88, 0.48), p.deep)
			c:box(Vector3.new(0.08, 0.34, 0.16), CFrame.new(0.64, 0.92, -0.04), p.deep)
			c:cone(Vector3.new(0.90, 0.56, 0.90), CFrame.new(0, 1.58, -0.04), CREAM)
			cherry(c, 0, 1.98, -0.04, 0.36)
			c:box(Vector3.new(0.22, 0.90, 0.12), CFrame.new(0.50, 1.36, -0.34) * CFrame.Angles(0, 0, -0.35), WAFER)
			sprinkles(c, {
				{ -0.52, 1.30, 0.10, 0.4 }, { 0.20, 1.30, 0.48, -0.6 }, { 0.50, 1.30, -0.30, 1.1, 0.5 }, { -0.36, 1.28, -0.44, -0.2, 1.0 },
			})
		end,
	}

	-- A walking slice of layer cake, strawberries and cream rosettes on top.
	S.sr_t_shortcake = {
		label = "Shortcake Slice",
		set = "sugar_rush",
		tint = C3(180, 120, 255),
		head = CFrame.new(0, 1.22, 0.10),
		neck = CFrame.new(0, -0.30, 0.96),
		back = CFrame.new(0, 0.20, -0.96),
		build = function(c, p)
			-- The wedge in three steps narrowing to its point at the back:
			-- { width, z, depth }, each with a cream layer and frosting on top.
			for _, v in ipairs({ { 1.90, 0.55, 0.70 }, { 1.30, -0.10, 0.60 }, { 0.70, -0.65, 0.50 } }) do
				c:box(Vector3.new(v[1], 1.30, v[3]), CFrame.new(0, 0, v[2]), p.base)
				c:box(Vector3.new(v[1] + 0.04, 0.16, v[3] + 0.02), CFrame.new(0, 0.02, v[2]), p.pale)
				c:box(Vector3.new(v[1] + 0.04, 0.16, v[3] + 0.02), CFrame.new(0, 0.72, v[2]), p.pale)
			end
			c:eyes(0.34, 0.91, 0.40, 0.15)
			c:box(Vector3.new(0.26, 0.08, 0.06), CFrame.new(0, -0.26, 0.91), INK)
			blush(c, 0.64, -0.22, 0.91)
			for _, v in ipairs({ { -0.50, 0.50 }, { 0.50, 0.50 }, { 0, -0.12 } }) do
				c:ball(Vector3.new(0.40, 0.40, 0.40), CFrame.new(v[1], 0.98, v[2]), C3(236, 50, 70))
				c:box(Vector3.new(0.28, 0.06, 0.28), CFrame.new(v[1], 1.18, v[2]) * CFrame.Angles(0, math.pi / 4, 0), LEAF)
			end
			for _, s in ipairs(SIDES) do
				c:cone(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0.80 * s, 0.94, 0.70), CREAM)
				c:box(Vector3.new(0.40, 0.22, 0.46), CFrame.new(0.50 * s, -0.76, 0.50), p.deep)
			end
			c:box(Vector3.new(1.96, 0.10, 0.76), CFrame.new(0, -0.60, 0.55), GOLD, METAL)
		end,
	}

	-- A candy cottage: window eyes, a door, a frosted roof and gumdrops.
	S.sr_t_cottage = {
		label = "Candy Cottage",
		set = "sugar_rush",
		tint = C3(140, 235, 200),
		head = CFrame.new(0, 1.70, 0),
		neck = CFrame.new(0, -0.40, 0.86),
		back = CFrame.new(0, 0.20, -0.86),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.80, 1.40, 1.60),
				eyeY = 0.14, eyeSpread = 0.44, eyeSize = Vector3.new(0.36, 0.42, 0.18), mouth = false,
				legSize = Vector3.new(0.36, 0.24, 0.40), legX = 0.56, legY = -0.70, legZ = { 0.40, -0.40 },
				legColor = p.deep, tail = false,
			})
			for _, s in ipairs(SIDES) do
				-- Shutters either side of each window eye.
				for _, x in ipairs({ 0.18, 0.70 }) do
					c:box(Vector3.new(0.12, 0.50, 0.06), CFrame.new(x * s, 0.14, 0.81), p.pale)
				end
				-- A candy cane by the door, and one slope of the frosted roof.
				c:rod(Vector3.new(0.72 * s, -0.64, 0.86), Vector3.new(0.72 * s, -0.12, 0.86), 0.05, STICK, nil, false)
				c:rod(Vector3.new(0.72 * s, -0.12, 0.86), Vector3.new(0.60 * s, -0.02, 0.86), 0.05, CHERRY, nil, false)
				c:box(Vector3.new(1.16, 0.18, 1.90), CFrame.new(0.50 * s, 1.12, 0) * CFrame.Angles(0, 0, -0.62 * s), p.pale)
			end
			c:box(Vector3.new(0.46, 0.62, 0.08), CFrame.new(0, -0.32, 0.82), p.deep)
			c:ball(Vector3.new(0.10, 0.10, 0.10), CFrame.new(0.14, -0.32, 0.87), GOLD, METAL)
			c:box(Vector3.new(0.96, 0.50, 1.50), CFrame.new(0, 0.96, 0), p.base)
			for i, z in ipairs({ -0.60, 0, 0.60 }) do
				c:ball(Vector3.new(0.26, 0.26, 0.26), CFrame.new(0, 1.62, z), SPRINKLES[i])
			end
			c:box(Vector3.new(0.30, 0.46, 0.30), CFrame.new(0.56, 1.36, -0.40), p.dark)
			blush(c, 0.44, -0.16, 0.81)
		end,
	}

	-- A winged candy heart, a golden arrow through it and a halo above.
	S.sr_t_heartwing = {
		label = "Candy Heartwing",
		set = "sugar_rush",
		tint = C3(255, 40, 120),
		scale = 1.28,
		head = CFrame.new(0, 1.30, 0),
		neck = CFrame.new(0, -0.50, 0.50),
		back = CFrame.new(0, 0.30, -0.50),
		build = function(c, p)
			-- A diamond and two round lobes make a thick candy heart.
			c:box(Vector3.new(1.30, 1.30, 0.90), CFrame.Angles(0, 0, math.pi / 4), p.base)
			for _, s in ipairs(SIDES) do
				c:cyl(Vector3.new(0.90, 1.30, 1.30), CFrame.new(0.46 * s, 0.46, 0) * FRONT, p.base)
			end
			c:eyes(0.26, 0.47, 0.36, 0.15)
			c:box(Vector3.new(0.22, 0.07, 0.06), CFrame.new(0, -0.10, 0.46), INK)
			blush(c, 0.58, 0.04, 0.46)
			-- Feathered wings behind: { length, y, tilt, colour }.
			for _, s in ipairs(SIDES) do
				for k, f in ipairs({ { 0.64, 0.80, 0.55, p.pale }, { 0.58, 0.58, 0.28, WHITE }, { 0.48, 0.36, 0.0, p.pale } }) do
					c:box(Vector3.new(f[1], 0.24 - k * 0.02, 0.12), CFrame.new((1.06 + f[1] * 0.40) * s, f[2], -0.30) * CFrame.Angles(0, 0, f[3] * s), f[4])
				end
			end
			c:rod(Vector3.new(-1.30, -0.62, -0.40), Vector3.new(1.30, 0.36, -0.40), 0.05, GOLD, METAL, false)
			c:cone(Vector3.new(0.24, 0.30, 0.10), CFrame.new(1.38, 0.39, -0.40) * CFrame.Angles(0, 0, -1.21), GOLD, METAL)
			c:box(Vector3.new(0.26, 0.20, 0.06), CFrame.new(-1.34, -0.63, -0.40) * CFrame.Angles(0, 0, 0.36), p.pale)
			halo(c, 1.40, 0, 0.36, p.glow)
			c:star(Vector3.new(-0.90, -0.80, 0.30), 0.30, p.glow)
		end,
	}

	-- A camel whose humps are two glazed caramel drops, in a saddle cloth.
	S.sr_t_camel = {
		label = "Caramel Camel",
		set = "sugar_rush",
		tint = C3(190, 110, 30),
		head = CFrame.new(0, 1.40, -0.07),
		neck = CFrame.new(0, -0.56, 1.06),
		back = CFrame.new(0, 0.40, -1.06),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.70, 1.40, 2.00),
				snout = { w = 0.60, h = 0.42, d = 0.50, y = -0.12, color = p.light, nose = p.deep },
				eyeY = 0.32, eyeSpread = 0.40, eyeSize = Vector3.new(0.34, 0.42, 0.18),
				legSize = Vector3.new(0.30, 0.56, 0.34), legX = 0.52, legY = -0.86, legZ = { 0.62, -0.62 },
				legColor = p.dark, tail = false,
			})
			for _, z in ipairs({ 0.36, -0.50 }) do
				c:round(Vector3.new(0.86, 0.66, 0.74), CFrame.new(0, 0.96, z), p.base)
				c:round(Vector3.new(0.56, 0.20, 0.50), CFrame.new(0, 1.28, z), p.pale)
			end
			c:box(Vector3.new(1.80, 0.60, 0.40), CFrame.new(0, 0.50, -0.07), p.glow)
			c:box(Vector3.new(1.84, 0.08, 0.44), CFrame.new(0, 0.30, -0.07), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:ball(Vector3.new(0.14, 0.14, 0.14), CFrame.new(0.94 * s, 0.16, -0.07), GOLD, METAL)
				c:box(Vector3.new(0.16, 0.24, 0.12), CFrame.new(0.50 * s, 0.86, 0.80), p.dark)
			end
			c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0, -0.50, 1.02), GOLD, METAL)
			c:box(Vector3.new(0.12, 0.50, 0.12), CFrame.new(0, 0.06, -1.08) * CFrame.Angles(-0.3, 0, 0), p.dark)
			blush(c, 0.60, 0.02, 1.01)
		end,
	}

	-- A pufferfish studded with sugar-coated gumdrops.
	S.sr_t_puffer = {
		label = "Gumdrop Puffer",
		set = "sugar_rush",
		tint = C3(0, 200, 220),
		head = CFrame.new(0, 1.24, 0),
		neck = CFrame.new(0, -0.40, 0.92),
		back = CFrame.new(0, 0.30, -1.00),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.80, 1.70, 1.70),
				eyeY = 0.20, eyeSpread = 0.40, eyeSize = Vector3.new(0.44, 0.52, 0.20),
				mouthY = -0.28, mouthSize = Vector3.new(0.28, 0.22, 0.14), mouthColor = p.deep,
				bib = { w = 1.00, h = 0.40, y = -0.62, color = p.pale },
				legs = false, tail = false,
			})
			-- { x, y, z, tilt X, tilt Z }
			for i, v in ipairs({
				{ 0, 1.00, 0, 0, 0 }, { -0.50, 0.86, -0.36, -0.5, 0.6 }, { 0.50, 0.86, -0.36, -0.5, -0.6 },
				{ -1.00, 0.20, -0.10, 0, math.pi / 2 }, { 1.00, 0.20, -0.10, 0, -math.pi / 2 }, { 0, 0.64, -0.80, -0.9, 0 },
			}) do
				c:cone(Vector3.new(0.32, 0.38, 0.32), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(v[4], 0, v[5]), SPRINKLES[(i - 1) % #SPRINKLES + 1])
			end
			c:box(Vector3.new(0.10, 0.50, 0.40), CFrame.new(0, 0.30, -1.10) * CFrame.Angles(0.5, 0, 0), p.dark)
			c:box(Vector3.new(0.10, 0.50, 0.40), CFrame.new(0, -0.14, -1.10) * CFrame.Angles(-0.5, 0, 0), p.dark)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.10, 0.30, 0.40), CFrame.new(0.96 * s, -0.20, 0.30) * CFrame.Angles(0, 0.4 * s, 0), p.light)
			end
			blush(c, 0.50, -0.04, 0.86)
		end,
	}

	-- A plump meringue swan with a piped swirl crest and a gold bow.
	S.sr_t_swan = {
		label = "Meringue Swan",
		set = "sugar_rush",
		tint = C3(255, 205, 235),
		head = CFrame.new(0, 1.62, 0.06),
		neck = CFrame.new(0, -0.40, 1.00),
		back = CFrame.new(0, 0.40, -1.00),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = Vector3.new(1.80, 1.60, 1.90),
				eyeY = 0.24, eyeSpread = 0.36, eyeSize = Vector3.new(0.36, 0.44, 0.18), mouth = false,
				legs = false, tail = false,
			})
			c:cone(Vector3.new(0.30, 0.36, 0.24), CFrame.new(0, 0.0, 1.10) * CFrame.Angles(math.pi / 2, 0, 0), GOLD, METAL)
			c:box(Vector3.new(0.70, 0.24, 0.70), CFrame.new(0, 0.92, 0.10) * CFrame.Angles(0, 0.4, 0), p.pale)
			c:box(Vector3.new(0.48, 0.22, 0.48), CFrame.new(0, 1.12, 0.10) * CFrame.Angles(0, 0.8, 0), p.pale)
			c:cone(Vector3.new(0.34, 0.40, 0.34), CFrame.new(0, 1.42, 0.06) * CFrame.Angles(-0.3, 0, 0), p.pale)
			wings(c, p.light, 0.26, 0.10, -0.20, 0.30)
			for _, s in ipairs(SIDES) do
				c:cone(Vector3.new(0.30, 0.50, 0.30), CFrame.new(1.10 * s, 0.56, -0.40) * CFrame.Angles(-0.5, 0, -0.5 * s), p.pale)
				c:box(Vector3.new(0.30, 0.20, 0.08), CFrame.new(0.20 * s, -0.34, 0.99) * CFrame.Angles(0, 0, 0.4 * s), GOLD, METAL)
			end
			c:box(Vector3.new(0.16, 0.16, 0.12), CFrame.new(0, -0.34, 1.00), GOLD, METAL)
			c:cone(Vector3.new(0.34, 0.56, 0.34), CFrame.new(0, 0.50, -1.04) * CFrame.Angles(-0.7, 0, 0), p.pale)
			blush(c, 0.50, 0.02, 0.97)
		end,
	}

	-- A beetle whose shell is a jawbreaker, its candy layers showing as rings.
	S.sr_t_jawbreaker = {
		label = "Jawbreaker Beetle",
		set = "sugar_rush",
		tint = C3(120, 60, 220),
		head = CFrame.new(0, 1.22, -0.20),
		neck = CFrame.new(0, -0.50, 1.28),
		back = CFrame.new(0, 0.30, -1.16),
		build = function(c, p)
			c:box(Vector3.new(1.50, 0.50, 1.70), CFrame.new(0, -0.48, -0.10), p.dark)
			c:box(Vector3.new(1.10, 0.80, 0.60), CFrame.new(0, -0.24, 0.96), p.dark)
			c:eyes(-0.10, 1.27, 0.26, 0.15)
			c:box(Vector3.new(0.20, 0.06, 0.05), CFrame.new(0, -0.40, 1.27), INK)
			blush(c, 0.42, -0.30, 1.27)
			c:ball(Vector3.new(1.90, 1.90, 1.90), CFrame.new(0, 0.24, -0.20), p.base)
			c:cyl(Vector3.new(0.10, 1.94, 1.94), CFrame.new(0, 0.24, -0.20) * UP, p.light)
			c:cyl(Vector3.new(0.10, 1.70, 1.70), CFrame.new(0, 0.70, -0.20) * UP, p.pale)
			c:cyl(Vector3.new(0.10, 1.18, 1.18), CFrame.new(0, 1.00, -0.20) * UP, p.glow)
			c:cone(Vector3.new(0.26, 0.50, 0.26), CFrame.new(0, 0.30, 1.10) * CFrame.Angles(0.5, 0, 0), p.glow)
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.24 * s, 0.14, 1.10), Vector3.new(0.46 * s, 0.60, 1.30), 0.04, p.deep, nil, false)
				c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.46 * s, 0.60, 1.30), p.light)
				for _, z in ipairs({ 0.40, -0.10, -0.60 }) do
					c:rod(Vector3.new(0.70 * s, -0.50, z), Vector3.new(1.00 * s, -0.86, z + 0.10), 0.06, p.deep, nil, false)
				end
			end
		end,
	}

	-- A party piñata pony: fringe bands of colour, a party hat, streamers.
	S.sr_t_pinata = {
		label = "Pinata Pony",
		set = "sugar_rush",
		tint = C3(240, 60, 220),
		scale = 1.10,
		head = CFrame.new(0, 1.50, 0.60),
		neck = CFrame.new(0, -0.40, 1.04),
		back = CFrame.new(0, 0.40, -1.00),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.70, 1.60, 1.90),
				snout = { w = 0.58, h = 0.44, d = 0.46, y = -0.18, color = p.pale, nose = p.deep },
				eyeY = 0.26, eyeSpread = 0.40, eyeSize = Vector3.new(0.36, 0.44, 0.18),
				legSize = Vector3.new(0.34, 0.60, 0.38), legX = 0.50, legY = -0.96, legZ = { 0.56, -0.56 },
				legColor = p.dark, tail = false,
			})
			local bands = { p.light, p.glow, p.pale, p.deep }
			for i, z in ipairs({ 0.56, 0.18, -0.20, -0.58 }) do
				c:box(Vector3.new(1.76, 1.66, 0.18), CFrame.new(0, 0.06, z), bands[i])
			end
			ears(c, p.base, "up", p.pale)
			for i = 0, 2 do
				c:box(Vector3.new(0.20, 0.30, 0.34), CFrame.new(0, 0.98, 0.30 - i * 0.40), SPRINKLES[i + 1])
			end
			c:cone(Vector3.new(0.40, 0.56, 0.40), CFrame.new(0, 1.14, 0.60), GOLD)
			c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(0, 1.46, 0.60), WHITE)
			for i, x in ipairs({ -0.40, 0, 0.40 }) do
				c:rod(Vector3.new(0, 0.30, -0.95), Vector3.new(x, -0.30, -1.32), 0.04, SPRINKLES[i + 2], nil, false)
			end
			blush(c, 0.54, -0.04, 0.96)
		end,
	}

	-- A chunky rhino iced in fondant, with a piped horn and sugar flowers.
	S.sr_t_rhino = {
		label = "Fondant Rhino",
		set = "sugar_rush",
		tint = C3(70, 120, 200),
		head = CFrame.new(0, 1.12, -0.10),
		neck = CFrame.new(0, -0.50, 1.10),
		back = CFrame.new(0, 0.40, -1.00),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = Vector3.new(1.90, 1.60, 1.90),
				snout = { w = 0.80, h = 0.56, d = 0.50, y = -0.20, color = p.light, nose = p.deep },
				eyeY = 0.30, eyeSpread = 0.46, eyeSize = Vector3.new(0.34, 0.40, 0.18),
				legSize = Vector3.new(0.50, 0.40, 0.54), legX = 0.56, legY = -0.84,
				legColor = p.dark, tailSize = Vector3.new(0.20, 0.20, 0.40),
			})
			c:cone(Vector3.new(0.34, 0.60, 0.34), CFrame.new(0, 0.36, 1.12) * CFrame.Angles(0.25, 0, 0), p.pale)
			c:box(Vector3.new(0.30, 0.06, 0.30), CFrame.new(0, 0.16, 1.07), GOLD, METAL)
			ears(c, p.base, "tuft")
			c:box(Vector3.new(1.40, 0.14, 1.20), CFrame.new(0, 0.86, -0.10), p.pale)
			for _, v in ipairs({ { -0.36, 0.20 }, { 0.30, -0.40 } }) do
				c:box(Vector3.new(0.36, 0.06, 0.36), CFrame.new(v[1], 0.95, v[2]) * CFrame.Angles(0, math.pi / 4, 0), p.glow)
				c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(v[1], 0.98, v[2]), GOLD, METAL)
			end
			blush(c, 0.62, -0.08, 0.94)
		end,
	}

	----------------------------------------------------------------------------
	-- MYTHIC: spectacular, with neon sugar-glow.
	----------------------------------------------------------------------------

	-- A phoenix of pulled toffee: flame crest, fanned wings, glowing tail tips.
	S.sr_t_phoenix = {
		label = "Toffee Phoenix",
		set = "sugar_rush",
		tint = C3(255, 96, 24),
		scale = 1.25,
		head = CFrame.new(0, 1.40, 0.10),
		neck = CFrame.new(0, -0.30, 0.96),
		back = CFrame.new(0, 0.40, -0.92),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = Vector3.new(1.70, 1.80, 1.70),
				eyeY = 0.30, eyeSpread = 0.36, eyeSize = Vector3.new(0.38, 0.46, 0.18), mouth = false,
				bib = { w = 0.90, h = 0.60, y = -0.40, color = p.pale },
				legSize = Vector3.new(0.18, 0.30, 0.30), legX = 0.30, legY = -0.90, legZ = { 0.10 },
				legColor = GOLD, tail = false,
			})
			c:cone(Vector3.new(0.28, 0.34, 0.22), CFrame.new(0, 0.04, 1.02) * CFrame.Angles(math.pi / 2, 0, 0), GOLD, METAL)
			c:cone(Vector3.new(0.24, 0.44, 0.24), CFrame.new(-0.22, 1.04, 0.10) * CFrame.Angles(-0.2, 0, 0.35), p.light)
			c:cone(Vector3.new(0.24, 0.56, 0.24), CFrame.new(0, 1.14, 0.10) * CFrame.Angles(-0.2, 0, 0), p.glow, NEON)
			c:cone(Vector3.new(0.24, 0.44, 0.24), CFrame.new(0.22, 1.04, 0.10) * CFrame.Angles(-0.2, 0, -0.35), p.light)
			-- Wings: three feathers fanned from each shoulder { length, spread, colour }.
			for _, s in ipairs(SIDES) do
				for k, f in ipairs({ { 0.90, 0.55, p.base }, { 0.80, 0.95, p.light }, { 0.70, 1.35, p.pale } }) do
					c:box(Vector3.new(0.18, f[1], 0.42), CFrame.new(0.82 * s, 0.16, -0.10 - k * 0.10) * CFrame.Angles(0, 0, -f[2] * s) * CFrame.new(0, f[1] * 0.5, 0), f[3])
				end
				c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(0.82 * s, 0.16, -0.20) * CFrame.Angles(0, 0, -0.95 * s) * CFrame.new(0, 0.86, 0), p.glow, NEON)
			end
			-- Three long tail plumes trailing down behind, tipped with glow.
			for i, x in ipairs({ -0.24, 0, 0.24 }) do
				local cf = CFrame.new(x, -0.10, -0.80) * CFrame.Angles(-0.45, -x * 1.2, 0) * CFrame.new(0, 0, -0.45)
				c:box(Vector3.new(0.24, 0.10, 0.90), cf, i == 2 and p.base or p.light)
				c:ball(Vector3.new(0.22, 0.22, 0.22), cf * CFrame.new(0, 0, -0.48), p.glow, NEON)
			end
			c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(0, -0.30, 0.99), p.glow, NEON)
			blush(c, 0.52, 0.06, 0.88)
		end,
	}

	-- A wyrm whose body is folded ribbon candy, with gold horns and whiskers.
	S.sr_t_ribbonwyrm = {
		label = "Ribbon Candy Wyrm",
		set = "sugar_rush",
		tint = C3(0, 170, 210),
		scale = 1.25,
		head = CFrame.new(0, 0.62, 0.40),
		neck = CFrame.new(0, -0.40, 1.04),
		back = CFrame.new(0, 0.30, -1.00),
		build = function(c, p)
			-- Ribbon candy folded back and forth behind the head, striped.
			for i, z in ipairs({ -1.40, -1.08, -0.76, -0.44, -0.12 }) do
				local cf = CFrame.new(0, -0.16 + 0.22 * math.sin(i * 1.3), z) * CFrame.Angles(i % 2 == 0 and 0.7 or -0.7, 0, 0)
				c:box(Vector3.new(1.00, 0.72, 0.20), cf, i % 2 == 0 and p.light or p.base)
				c:box(Vector3.new(0.30, 0.74, 0.24), cf, p.pale)
			end
			c:box(Vector3.new(1.20, 1.00, 1.00), CFrame.new(0, 0.10, 0.50), p.base)
			c:eyes(0.24, 1.01, 0.30, 0.16)
			c:box(Vector3.new(0.30, 0.07, 0.06), CFrame.new(0, -0.12, 1.01), INK)
			blush(c, 0.44, 0.02, 1.01)
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.36 * s, -0.06, 1.00), Vector3.new(0.86 * s, 0.10, 1.20), 0.03, GOLD, METAL, false)
				c:cone(Vector3.new(0.20, 0.50, 0.20), CFrame.new(0.34 * s, 0.82, 0.40) * CFrame.Angles(-0.3, 0, -0.3 * s), GOLD, METAL)
			end
			for _, z in ipairs({ 0.24, -0.04 }) do
				c:cone(Vector3.new(0.22, 0.40, 0.22), CFrame.new(0, 0.74, z) * CFrame.Angles(-0.3, 0, 0), p.glow, NEON)
			end
			c:cone(Vector3.new(0.30, 0.50, 0.30), CFrame.new(0, 0.05, -1.78) * CFrame.Angles(-math.pi / 2, 0, 0), p.glow, NEON)
			for _, v in ipairs({ { -1.10, 0.80, -0.40 }, { 1.10, 0.50, -0.80 }, { 0, 1.20, -1.00 } }) do
				c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(v[1], v[2], v[3]), p.glow, NEON)
			end
		end,
	}

	-- A unicorn with a gold swirl horn and a mane and tail of sherbet scoops.
	S.sr_t_unicorn = {
		label = "Sherbet Unicorn",
		set = "sugar_rush",
		tint = C3(230, 140, 255),
		scale = 1.10,
		head = CFrame.new(0, 1.46, -0.20),
		neck = CFrame.new(0, -0.40, 1.04),
		back = CFrame.new(0, 0.40, -1.00),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = Vector3.new(1.80, 1.70, 1.90),
				snout = { w = 0.62, h = 0.46, d = 0.46, y = -0.20, color = p.pale, nose = p.deep },
				eyeY = 0.26, eyeSpread = 0.40, eyeSize = Vector3.new(0.36, 0.46, 0.18),
				legSize = Vector3.new(0.36, 0.50, 0.40), legX = 0.52, legY = -0.92,
				legColor = p.light, tail = false,
			})
			c:cone(Vector3.new(0.30, 0.80, 0.30), CFrame.new(0, 1.16, 0.56) * CFrame.Angles(0.3, 0, 0), GOLD, METAL)
			c:box(Vector3.new(0.26, 0.06, 0.26), CFrame.new(0, 1.00, 0.51) * CFrame.Angles(0.3, 0, 0.3), p.glow, NEON)
			c:box(Vector3.new(0.18, 0.06, 0.18), CFrame.new(0, 1.20, 0.57) * CFrame.Angles(0.3, 0, -0.3), p.glow, NEON)
			ears(c, p.base, "up", p.pale)
			-- { y, z, size, colour }: mane down the neck, then the tail.
			for _, v in ipairs({
				{ 1.00, 0.10, 0.56, p.light }, { 0.98, -0.32, 0.52, p.glow }, { 0.90, -0.70, 0.46, p.pale },
				{ 0.40, -1.00, 0.50, p.light }, { 0.02, -1.20, 0.44, p.glow }, { -0.32, -1.30, 0.38, p.pale },
			}) do
				c:ball(Vector3.new(v[3], v[3], v[3]), CFrame.new(0, v[1], v[2]), v[4])
			end
			c:star(Vector3.new(0.90, 1.30, 0.30), 0.34, p.glow)
			c:star(Vector3.new(-1.00, 1.00, -0.40), 0.28, p.glow)
			blush(c, 0.56, -0.08, 0.96)
		end,
	}

	-- A genie rising from a glass of cherry soda: foam, straw, fizz for legs.
	S.sr_t_sodagenie = {
		label = "Cherry Soda Genie",
		set = "sugar_rush",
		tint = C3(170, 10, 50),
		scale = 1.20,
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, -0.50, 0.76),
		back = CFrame.new(0, 0.20, -0.76),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.50, 1.50, 1.40),
				eyeY = 0.16, eyeSpread = 0.34, eyeSize = Vector3.new(0.38, 0.46, 0.18),
				mouthY = -0.24, mouthSize = Vector3.new(0.30, 0.14, 0.12),
				legs = false, tail = false,
			})
			c:box(Vector3.new(1.56, 0.10, 1.46), CFrame.new(0, -0.66, 0), GOLD, METAL)
			c:box(Vector3.new(1.62, 0.12, 1.52), CFrame.new(0, 0.80, 0), GLASSY, GLASS)
			c:round(Vector3.new(1.70, 0.56, 1.60), CFrame.new(0, 1.04, 0), p.pale)
			c:box(Vector3.new(0.24, 0.36, 0.06), CFrame.new(-0.46, 0.64, 0.71), p.pale)
			c:box(Vector3.new(0.24, 0.36, 0.06), CFrame.new(0.50, 0.60, 0.71), p.pale)
			c:box(Vector3.new(0.06, 0.36, 0.24), CFrame.new(0.76, 0.60, 0.20), p.pale)
			c:rod(Vector3.new(0.34, 0.90, -0.20), Vector3.new(0.56, 1.60, -0.36), 0.05, STICK, nil, false)
			c:rod(Vector3.new(0.56, 1.60, -0.36), Vector3.new(0.84, 1.70, -0.36), 0.05, CHERRY, nil, false)
			cherry(c, -0.30, 1.42, 0.10, 0.40)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.30, 0.60, 0.34), CFrame.new(0.92 * s, -0.02, 0.10) * CFrame.Angles(0, 0, -0.5 * s), p.light)
				c:box(Vector3.new(0.34, 0.10, 0.38), CFrame.new(0.85 * s, -0.15, 0.10) * CFrame.Angles(0, 0, -0.5 * s), GOLD, METAL)
			end
			c:box(Vector3.new(1.00, 0.36, 0.90), CFrame.new(0, -0.84, -0.04), p.light)
			c:cone(Vector3.new(0.40, 0.46, 0.40), CFrame.new(0.10, -1.20, -0.10) * CFrame.Angles(math.pi, 0, 0.3), p.glow, NEON)
			for _, v in ipairs({ { -0.96, 0.60, 0.30, 0.16 }, { 0.98, 0.90, -0.20, 0.20 }, { -0.80, 1.30, -0.30, 0.14 }, { 0.70, 1.50, 0.30, 0.18 }, { -1.06, 0.10, -0.10, 0.12 } }) do
				c:ball(Vector3.new(v[4], v[4], v[4]), CFrame.new(v[1], v[2], v[3]), p.glow, NEON)
			end
			blush(c, 0.52, -0.08, 0.71)
		end,
	}

	----------------------------------------------------------------------------
	-- DIVINE: heavenly sweets, haloes and glow.
	----------------------------------------------------------------------------

	-- A tiered angel food cake with feathered wings, a candle and a halo.
	S.sr_t_angelcake = {
		label = "Angel Food Cake",
		set = "sugar_rush",
		tint = C3(255, 240, 150),
		scale = 1.30,
		head = CFrame.new(0, 2.30, 0),
		neck = CFrame.new(0, -0.30, 0.96),
		back = CFrame.new(0, 0.40, -0.96),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.90, 1.10, 1.80),
				eyeY = 0.0, eyeSpread = 0.40, eyeSize = Vector3.new(0.36, 0.44, 0.18),
				mouthY = -0.28, mouthSize = Vector3.new(0.26, 0.12, 0.12),
				legs = false, tail = false,
			})
			c:box(Vector3.new(1.40, 0.62, 1.32), CFrame.new(0, 0.92, 0), p.light)
			c:box(Vector3.new(0.86, 0.46, 0.80), CFrame.new(0, 1.46, 0), p.base)
			c:box(Vector3.new(1.94, 0.12, 1.84), CFrame.new(0, 0.60, 0), p.pale)
			c:box(Vector3.new(1.44, 0.10, 1.36), CFrame.new(0, 1.22, 0), p.pale)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.16, 0.30, 0.06), CFrame.new(0.72 * s, 0.42, 0.91), p.pale)
				-- Feathered wings: { length, spread, colour }.
				for k, f in ipairs({ { 1.00, 0.35, WHITE }, { 0.90, 0.75, p.pale }, { 0.78, 1.15, WHITE } }) do
					c:box(Vector3.new(0.14, f[1], 0.34), CFrame.new(0.95 * s, 0.20, -0.30 - k * 0.08) * CFrame.Angles(0, 0, -f[2] * s) * CFrame.new(0, f[1] * 0.5, 0), f[3])
				end
			end
			c:cyl(Vector3.new(0.40, 0.14, 0.14), CFrame.new(0, 1.89, 0) * UP, STICK)
			c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0, 2.16, 0), p.glow, NEON)
			halo(c, 2.00, 0, 0.40, p.glow)
			c:star(Vector3.new(-1.20, 1.20, 0.30), 0.34, p.glow)
			c:star(Vector3.new(1.20, 1.40, -0.20), 0.28, p.glow)
			blush(c, 0.62, -0.16, 0.91)
		end,
	}

	-- A dragon of pulled taffy: striped wings, candy horns, glowing gumdrop spines.
	S.sr_t_taffydragon = {
		label = "Taffy Dragon",
		set = "sugar_rush",
		tint = C3(30, 240, 60),
		scale = 1.15,
		head = CFrame.new(0, 1.30, 0.10),
		neck = CFrame.new(0, -0.40, 1.12),
		back = CFrame.new(0, 0.50, -0.60),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = Vector3.new(1.90, 1.70, 1.90),
				snout = { w = 0.70, h = 0.48, d = 0.52, y = -0.20, color = p.light, nose = p.deep },
				eyeY = 0.26, eyeSpread = 0.42, eyeSize = Vector3.new(0.38, 0.46, 0.18),
				legColor = p.dark, tailSize = Vector3.new(0.34, 0.34, 0.60), tailColor = p.base,
			})
			for _, s in ipairs(SIDES) do
				c:cone(Vector3.new(0.24, 0.56, 0.24), CFrame.new(0.40 * s, 1.08, 0.30) * CFrame.Angles(-0.3, 0, -0.25 * s), p.pale)
				local wing = CFrame.new(1.20 * s, 0.70, -0.20) * CFrame.Angles(0, 0, -0.5 * s)
				c:box(Vector3.new(0.10, 0.90, 1.00), wing, p.light)
				c:box(Vector3.new(0.12, 0.92, 0.24), wing, p.pale)
				c:box(Vector3.new(0.12, 0.10, 1.02), wing * CFrame.new(0, 0.46, 0), p.glow, NEON)
			end
			for _, z in ipairs({ 0.10, -0.28, -0.66 }) do
				c:cone(Vector3.new(0.26, 0.36, 0.30), CFrame.new(0, 0.98, z), p.glow, NEON)
			end
			c:cone(Vector3.new(0.36, 0.40, 0.36), CFrame.new(0, -0.12, -1.36) * CFrame.Angles(-1.2, 0, 0), p.glow, NEON)
			blush(c, 0.60, -0.06, 0.96)
		end,
	}

	-- A whale blowing a bubblegum bubble from its spout.
	S.sr_t_bubblewhale = {
		label = "Bubblegum Whale",
		set = "sugar_rush",
		tint = C3(120, 170, 255),
		scale = 1.10,
		head = CFrame.new(0, 1.62, 0.10),
		neck = CFrame.new(0, -0.50, 1.10),
		back = CFrame.new(0, 0.30, -1.10),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(2.00, 1.50, 2.10),
				eyeY = 0.14, eyeSpread = 0.46, eyeSize = Vector3.new(0.36, 0.44, 0.18),
				mouthY = -0.24, mouthSize = Vector3.new(0.60, 0.10, 0.10),
				bib = { w = 1.30, h = 0.36, y = -0.56, color = p.pale },
				legs = false, tail = false,
			})
			c:box(Vector3.new(0.40, 0.30, 0.60), CFrame.new(0, 0.0, -1.20), p.base)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.70, 0.12, 0.40), CFrame.new(0.36 * s, 0.16, -1.50) * CFrame.Angles(0, 0.4 * s, 0.3 * s), p.dark)
				c:box(Vector3.new(0.60, 0.12, 0.36), CFrame.new(1.04 * s, -0.36, 0.30) * CFrame.Angles(0, 0.3 * s, -0.4 * s), p.dark)
			end
			c:box(Vector3.new(0.30, 0.12, 0.30), CFrame.new(0, 0.82, 0.10), p.dark)
			c:ball(Vector3.new(0.70, 0.70, 0.70), CFrame.new(0, 1.20, 0.10), BUBBLE)
			c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(-0.14, 1.36, 0.36), WHITE)
			for _, v in ipairs({ { -0.46, 1.00 }, { 0.46, 1.06 }, { 0, 1.70 } }) do
				c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(v[1], v[2], 0.10), p.glow, NEON)
			end
			for _, v in ipairs({ { -0.50, -0.30 }, { 0.40, -0.60 }, { -0.20, -0.74 } }) do
				c:box(Vector3.new(0.26, 0.06, 0.26), CFrame.new(v[1], 0.78, v[2]), p.light)
			end
			c:star(Vector3.new(-1.10, 1.10, 0.30), 0.32, p.glow)
			c:star(Vector3.new(1.10, 1.30, -0.30), 0.26, p.glow)
			blush(c, 0.52, -0.08, 1.02)
		end,
	}

	-- A yeti of shaved ice, syrup on its head, standing in a snow-cone cup.
	S.sr_t_yeti = {
		label = "Shaved Ice Yeti",
		set = "sugar_rush",
		tint = C3(10, 60, 170),
		scale = 1.10,
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, -0.20, 0.84),
		back = CFrame.new(0, 0.30, -0.84),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.70, 1.90, 1.50), bodyColor = p.pale,
				eyeY = 0.36, eyeSpread = 0.34, eyeSize = Vector3.new(0.36, 0.44, 0.18),
				mouthY = -0.02, mouthSize = Vector3.new(0.40, 0.18, 0.12),
				legs = false, tail = false,
			})
			c:box(Vector3.new(1.10, 0.80, 0.04), CFrame.new(0, 0.20, 0.76), p.light)
			c:round(Vector3.new(1.80, 0.56, 1.60), CFrame.new(0, 1.06, 0), p.base)
			c:box(Vector3.new(0.20, 0.40, 0.06), CFrame.new(-0.62, 0.70, 0.77), p.base)
			c:box(Vector3.new(0.20, 0.40, 0.06), CFrame.new(0.66, 0.66, 0.77), p.base)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.06, 0.44, 0.22), CFrame.new(0.86 * s, 0.66, 0.30), p.base)
				c:box(Vector3.new(0.20, 0.30, 0.30), CFrame.new(0.88 * s, 0.56, -0.20), p.pale)
				c:box(Vector3.new(0.44, 0.90, 0.48), CFrame.new(1.04 * s, 0.10, 0.10) * CFrame.Angles(0, 0, -0.6 * s), p.pale)
				c:ball(Vector3.new(0.36, 0.36, 0.36), CFrame.new(1.30 * s, 0.50, 0.10), p.light)
				c:box(Vector3.new(0.34, 0.16, 0.44), CFrame.new(0.40 * s, -1.10, 0.34), p.light)
			end
			-- The paper snow-cone cup it stands in.
			c:box(Vector3.new(1.82, 0.36, 1.62), CFrame.new(0, -0.46, 0), WHITE)
			c:box(Vector3.new(1.56, 0.40, 1.36), CFrame.new(0, -0.84, 0), WHITE)
			c:box(Vector3.new(1.84, 0.08, 1.64), CFrame.new(0, -0.34, 0), p.deep)
			c:star(Vector3.new(-1.30, 1.20, 0), 0.34, p.glow)
			c:star(Vector3.new(1.30, 1.30, -0.20), 0.28, p.glow)
			c:star(Vector3.new(-1.10, -0.20, 0.30), 0.24, p.glow)
			blush(c, 0.48, 0.06, 0.79)
		end,
	}

	-- A truffle owl in a pleated gold-foil cup, crowned, with a glowing gem.
	S.sr_t_truffleowl = {
		label = "Truffle Owl",
		set = "sugar_rush",
		tint = C3(160, 40, 110),
		head = CFrame.new(0, 1.40, 0.04),
		neck = CFrame.new(0, -0.30, 0.98),
		back = CFrame.new(0, 0.30, -0.90),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = Vector3.new(1.80, 1.90, 1.70),
				eyeY = 0.30, eyeSpread = 0.38, eyeSize = Vector3.new(0.40, 0.50, 0.20), mouth = false,
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:round(Vector3.new(0.70, 0.70, 0.12), CFrame.new(0.38 * s, 0.30, 0.86), p.light)
				c:cone(Vector3.new(0.30, 0.50, 0.24), CFrame.new(0.50 * s, 1.10, 0.10) * CFrame.Angles(0, 0, -0.3 * s), p.dark)
				c:box(Vector3.new(0.20, 1.00, 1.00), CFrame.new(0.98 * s, -0.04, -0.10) * CFrame.Angles(0, 0, -0.12 * s), p.dark)
			end
			c:cone(Vector3.new(0.22, 0.30, 0.20), CFrame.new(0, 0.02, 0.94) * CFrame.Angles(math.pi, 0, 0), GOLD, METAL)
			c:box(Vector3.new(0.80, 0.06, 0.06), CFrame.new(0, -0.14, 0.89) * CFrame.Angles(0, 0, 0.12), p.pale)
			c:box(Vector3.new(0.80, 0.06, 0.06), CFrame.new(0, -0.36, 0.88) * CFrame.Angles(0, 0, -0.12), p.pale)
			c:ball(Vector3.new(0.26, 0.26, 0.26), CFrame.new(0, -0.24, 0.94), p.glow, NEON)
			c:box(Vector3.new(1.86, 0.50, 1.76), CFrame.new(0, -0.74, 0), GOLD, METAL)
			for _, x in ipairs({ -0.60, -0.20, 0.20, 0.60 }) do
				c:box(Vector3.new(0.06, 0.52, 0.08), CFrame.new(x, -0.74, 0.89), GOLD_DARK, METAL)
			end
			crown(c, 1.02, 0.0, 0.60, p.glow)
			blush(c, 0.62, -0.12, 0.87)
		end,
	}

	-- A crab whose claws and back grow clusters of rock-candy crystals.
	S.sr_t_rockcrab = {
		label = "Rock Candy Crab",
		set = "sugar_rush",
		tint = C3(190, 0, 250),
		scale = 1.15,
		head = CFrame.new(0, 1.30, -0.20),
		neck = CFrame.new(0, -0.30, 0.86),
		back = CFrame.new(0, 0.30, -0.86),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.90, 1.00, 1.60),
				eyeY = 0.10, eyeSpread = 0.40, eyeSize = Vector3.new(0.36, 0.44, 0.18),
				mouthY = -0.24, mouthSize = Vector3.new(0.28, 0.10, 0.10),
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.90 * s, -0.04, 0.40), Vector3.new(1.20 * s, 0.20, 0.80), 0.08, p.dark, nil, false)
				c:box(Vector3.new(0.50, 0.40, 0.50), CFrame.new(1.24 * s, 0.36, 0.96), p.base)
				c:cone(Vector3.new(0.20, 0.50, 0.20), CFrame.new(1.14 * s, 0.70, 0.98) * CFrame.Angles(0, 0, 0.3 * s), p.glow, NEON)
				c:cone(Vector3.new(0.18, 0.40, 0.18), CFrame.new(1.38 * s, 0.64, 0.92) * CFrame.Angles(0, 0, -0.4 * s), p.pale)
				for _, z in ipairs({ 0.20, -0.20, -0.60 }) do
					c:rod(Vector3.new(0.90 * s, -0.30, z), Vector3.new(1.24 * s, -0.70, z - 0.10), 0.06, p.dark, nil, false)
				end
			end
			-- { x, z, tilt, colour, material }
			for _, v in ipairs({ { -0.40, -0.20, 0.3, p.pale }, { 0, -0.40, 0, p.glow, NEON }, { 0.40, -0.10, -0.3, p.light } }) do
				c:cone(Vector3.new(0.30, 0.60, 0.30), CFrame.new(v[1], 0.84, v[2]) * CFrame.Angles(0, 0, v[3]), v[4], v[5])
			end
			c:star(Vector3.new(0, 1.40, 0.40), 0.30, p.glow)
			blush(c, 0.62, -0.16, 0.81)
		end,
	}

	-- A queen bee with honeycomb-candy wings and a honey dipper for a sting.
	S.sr_t_honeybee = {
		label = "Honeycomb Bee",
		set = "sugar_rush",
		tint = C3(255, 190, 0),
		head = CFrame.new(0, 1.16, 0.10),
		neck = CFrame.new(0, -0.40, 0.88),
		back = CFrame.new(0, 0.30, -0.96),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.80, 1.60, 1.70),
				eyeY = 0.20, eyeSpread = 0.38, eyeSize = Vector3.new(0.40, 0.48, 0.18),
				mouthY = -0.24, mouthSize = Vector3.new(0.26, 0.12, 0.12),
				legSize = Vector3.new(0.24, 0.20, 0.30), legX = 0.40, legY = -0.78, legZ = { 0.20, -0.30 },
				legColor = p.deep, tail = false,
			})
			for _, z in ipairs({ -0.20, -0.60 }) do
				c:box(Vector3.new(1.92, 1.66, 0.22), CFrame.new(0, 0.06, z), p.deep)
			end
			for _, s in ipairs(SIDES) do
				local big = CFrame.new(0.50 * s, 1.10, -0.30) * CFrame.Angles(0.2, 0, -0.7 * s)
				c:box(Vector3.new(0.10, 0.80, 0.70), big, p.glow, GLASS).Transparency = 0.3
				c:box(Vector3.new(0.10, 0.56, 0.50), CFrame.new(0.80 * s, 0.80, -0.50) * CFrame.Angles(0.2, 0, -1.1 * s), p.glow, GLASS).Transparency = 0.3
				c:box(Vector3.new(0.12, 0.26, 0.26), big * CFrame.Angles(math.pi / 4, 0, 0), p.light)
				c:rod(Vector3.new(0.24 * s, 0.70, 0.50), Vector3.new(0.44 * s, 1.24, 0.74), 0.04, INK, nil, false)
				c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(0.44 * s, 1.24, 0.74), p.glow, NEON)
			end
			c:rod(Vector3.new(0, 0, -0.84), Vector3.new(0, 0, -1.26), 0.06, C3(190, 140, 80), nil, false)
			c:cyl(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0, 0, -1.40) * FRONT, GOLD, METAL)
			crown(c, 0.86, 0.04, 0.56, p.glow)
			blush(c, 0.50, -0.06, 0.86)
		end,
	}

	-- A sugarplum pixie: plum body, leaf cap, gossamer wings, tutu and wand.
	S.sr_t_pixie = {
		label = "Sugarplum Pixie",
		set = "sugar_rush",
		tint = C3(130, 40, 170),
		scale = 1.10,
		head = CFrame.new(0, 1.24, 0.04),
		neck = CFrame.new(0, -0.20, 0.80),
		back = CFrame.new(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.60, 1.70, 1.50),
				eyeY = 0.24, eyeSpread = 0.34, eyeSize = Vector3.new(0.38, 0.46, 0.18),
				mouthY = -0.18, mouthSize = Vector3.new(0.22, 0.10, 0.10),
				legSize = Vector3.new(0.26, 0.30, 0.30), legX = 0.28, legY = -0.92, legZ = { 0.10 },
				legColor = p.dark, tail = false,
			})
			for _, v in ipairs({ { -0.46, 0.88, 0.20 }, { 0.40, 0.88, -0.20 }, { 0.84, 0.40, 0.30 }, { -0.84, 0.20, -0.20 } }) do
				c:box(Vector3.new(0.10, 0.10, 0.10), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0.6, 0.6, 0), p.pale)
			end
			c:box(Vector3.new(0.66, 0.08, 0.34), CFrame.new(0.20, 0.92, 0) * CFrame.Angles(0, 0.3, 0.25), LEAF)
			c:rod(Vector3.new(0, 0.86, 0), Vector3.new(-0.06, 1.16, -0.04), 0.04, STEM, nil, false)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.90, 0.80, 0.06), CFrame.new(0.70 * s, 0.70, -0.74) * CFrame.Angles(0, 0, 0.4 * s), p.glow, GLASS).Transparency = 0.35
				c:box(Vector3.new(0.66, 0.56, 0.06), CFrame.new(0.60 * s, 0.0, -0.74) * CFrame.Angles(0, 0, -0.4 * s), p.glow, GLASS).Transparency = 0.35
			end
			c:box(Vector3.new(1.90, 0.12, 1.80), CFrame.new(0, -0.44, 0), p.light)
			c:box(Vector3.new(1.70, 0.12, 1.70), CFrame.new(0, -0.52, 0) * CFrame.Angles(0, math.pi / 4, 0), p.pale)
			c:rod(Vector3.new(0.96, -0.30, 0.30), Vector3.new(1.20, 0.50, 0.40), 0.04, GOLD, METAL, false)
			c:star(Vector3.new(1.22, 0.64, 0.40), 0.40, p.glow)
			c:star(Vector3.new(-1.10, 1.10, 0.20), 0.26, p.glow)
			blush(c, 0.48, -0.06, 0.74)
		end,
	}

	----------------------------------------------------------------------------
	-- EXOTIC: the showpieces of "Infinite Sweetness".
	----------------------------------------------------------------------------

	-- A carousel of sweets: a striped canopy, candy-stick poles, gummy ponies.
	S.sr_t_carousel = {
		label = "Bonbon Carousel",
		set = "sugar_rush",
		tint = C3(255, 120, 200),
		scale = 1.20,
		head = CFrame.new(0, 1.96, 0),
		neck = CFrame.new(0, -0.50, 0.56),
		back = CFrame.new(0, 0.20, -0.56),
		build = function(c, p)
			c:cyl(Vector3.new(0.24, 2.30, 2.30), CFrame.new(0, -0.86, 0) * UP, p.base)
			c:cyl(Vector3.new(0.10, 2.40, 2.40), CFrame.new(0, -0.92, 0) * UP, GOLD, METAL)
			c:box(Vector3.new(1.00, 1.30, 1.00), CFrame.new(0, -0.08, 0), p.pale)
			c:eyes(0.08, 0.51, 0.24, 0.14)
			c:box(Vector3.new(0.20, 0.07, 0.05), CFrame.new(0, -0.20, 0.51), INK)
			blush(c, 0.34, -0.14, 0.51)
			-- The striped canopy, its underside, scalloped trim and lights.
			c:cone(Vector3.new(2.40, 0.80, 2.40), CFrame.new(0, 1.04, 0), p.base)
			c:cyl(Vector3.new(0.10, 2.36, 2.36), CFrame.new(0, 0.62, 0) * UP, p.light)
			for i = 0, 3 do
				local a = math.pi / 4 + i * math.pi / 2
				c:box(Vector3.new(0.50, 0.18, 0.10), CFrame.new(0.83 * math.cos(a), 0.52, 0.83 * math.sin(a)) * CFrame.Angles(0, math.pi / 2 - a, 0), p.pale)
				local b = i * math.pi / 2
				c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(1.20 * math.cos(b), 0.66, 1.20 * math.sin(b)), p.glow, NEON)
			end
			c:ball(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0, 1.50, 0), GOLD, METAL)
			c:rod(Vector3.new(0, 1.60, 0), Vector3.new(0, 1.92, 0), 0.03, GOLD, METAL, false)
			c:box(Vector3.new(0.30, 0.20, 0.04), CFrame.new(0.16, 1.82, 0), p.glow, NEON)
			-- Candy-stick poles; gummy ponies ride the two at the sides.
			for _, v in ipairs({ { -0.84, 0 }, { 0.84, 0 }, { 0, -0.84 } }) do
				c:rod(Vector3.new(v[1], -0.74, v[2]), Vector3.new(v[1], 0.60, v[2]), 0.06, STICK, nil, false)
			end
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.26, 0.30, 0.54), CFrame.new(0.84 * s, -0.10, 0), p.light)
				c:box(Vector3.new(0.22, 0.30, 0.22), CFrame.new(0.84 * s, 0.14, 0.28), p.light)
				c:box(Vector3.new(0.10, 0.24, 0.30), CFrame.new(0.84 * s, 0.10, 0.06), p.deep)
			end
		end,
	}

	-- A crowned butterfly with stained-glass wings of hard candy.
	S.sr_t_monarch = {
		label = "Candy Monarch",
		set = "sugar_rush",
		tint = C3(250, 245, 20),
		scale = 1.20,
		head = CFrame.new(0, 1.56, 0.06),
		neck = CFrame.new(0, 0.10, 0.52),
		back = CFrame.new(0, 0.20, -0.50),
		build = function(c, p)
			c:round(Vector3.new(0.80, 0.90, 0.76), CFrame.new(0, -0.10, 0), p.dark)
			c:round(Vector3.new(0.62, 0.80, 0.60), CFrame.new(0, -0.80, -0.04), p.dark)
			for _, y in ipairs({ -0.70, -0.92 }) do
				c:box(Vector3.new(0.60, 0.08, 0.58), CFrame.new(0, y, -0.04), p.pale)
			end
			c:round(Vector3.new(1.10, 1.00, 0.96), CFrame.new(0, 0.76, 0.06), p.base)
			c:eyes(0.82, 0.52, 0.24, 0.15)
			c:box(Vector3.new(0.20, 0.06, 0.05), CFrame.new(0, 0.56, 0.55), INK)
			blush(c, 0.36, 0.62, 0.43)
			for _, s in ipairs(SIDES) do
				-- Upper wing: a dark rim, the candy pane, a glowing heart, two dots.
				local up = CFrame.new(0.84 * s, 0.40, -0.30) * CFrame.Angles(0, 0, 0.30 * s)
				c:box(Vector3.new(1.18, 1.08, 0.08), up * CFrame.new(0, 0, -0.04), p.deep)
				c:box(Vector3.new(1.10, 1.00, 0.10), up, p.base)
				c:box(Vector3.new(0.56, 0.48, 0.12), up * CFrame.new(0.06 * s, 0.04, 0), p.glow, NEON)
				c:ball(Vector3.new(0.16, 0.16, 0.16), up * CFrame.new(0.40 * s, 0.36, 0.04), p.pale)
				c:ball(Vector3.new(0.16, 0.16, 0.16), up * CFrame.new(0.44 * s, -0.30, 0.04), p.pale)
				-- Lower wing, and an antenna tipped with a swirl lollipop.
				local low = CFrame.new(0.66 * s, -0.56, -0.30) * CFrame.Angles(0, 0, -0.40 * s)
				c:box(Vector3.new(0.84, 0.84, 0.10), low, p.light)
				c:box(Vector3.new(0.42, 0.42, 0.12), low, p.pale)
				c:rod(Vector3.new(0.18 * s, 1.20, 0.10), Vector3.new(0.48 * s, 1.60, 0.20), 0.03, INK, nil, false)
				c:cyl(Vector3.new(0.08, 0.28, 0.28), CFrame.new(0.50 * s, 1.68, 0.20) * FRONT, p.glow, NEON)
			end
			crown(c, 1.30, 0.06, 0.56, p.glow)
			c:star(Vector3.new(-1.10, 1.30, 0.20), 0.32, p.glow)
			c:star(Vector3.new(1.20, -0.90, 0.20), 0.26, p.glow)
		end,
	}

	return S
end
