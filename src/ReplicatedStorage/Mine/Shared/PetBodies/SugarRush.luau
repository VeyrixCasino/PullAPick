--[[ PetBodies/SugarRush -- Sugar Rush's bodies. See tools/gen/sets/README.md.

	Candy you can name from across the mine: a twist-wrapped sweet, a frosted
	cupcake, an ice-cream scoop on a cone, a see-through gummy bear and a swirl
	lollipop on its stick. Bright and glossy, never spooky.
]]
return function(K)
	local C3, block, ears = K.C3, K.block, K.ears
	local INK, WHITE, NEON, GLASS = K.INK, K.WHITE, K.NEON, K.GLASS
	local S = {}

	local BLUSH = C3(255, 150, 182)
	local SPRINKLES = { C3(255, 90, 110), C3(90, 190, 255), C3(255, 220, 80), C3(140, 230, 120), C3(200, 120, 255) }

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

	-- Turns every part made after `from` whose colour is one of `colours` into
	-- clear jelly, so a gummy reads as a gummy. Colours are compared loosely:
	-- a Part stores its Color as 8-bit, so a lerped palette shade comes back
	-- a hair off what was set.
	local function jelly(c, from, colours)
		local function near(a, b)
			return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.02
		end
		for _, part in ipairs(c.model:GetChildren()) do
			if part:IsA("BasePart") and not part:GetAttribute("Eye") then
				local n = tonumber(string.sub(part.Name, 2))
				if n and n > from then
					for _, col in ipairs(colours) do
						if near(part.Color, col) then
							part.Material = GLASS
							part.Transparency = 0.22
							break
						end
					end
				end
			end
		end
	end

	-- A round sweet with twisted wrapper ends flaring out either side.
	S.sr_bonbon = {
		label = "Bonbon",
		set = "sugar_rush",
		tint = C3(236, 92, 120),
		-- The wrapper ends make it the widest body, which FIT_SIZE shrinks.
		scale = 1.30,
		head = CFrame.new(0, 0.96, 0.06),
		neck = CFrame.new(0, -0.40, 0.70),
		back = CFrame.new(0, 0.20, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.70, 1.60, 1.60),
				eyeY = 0.14, eyeSpread = 0.36, eyeSize = Vector3.new(0.44, 0.54, 0.20),
				mouthY = -0.30, mouthSize = Vector3.new(0.30, 0.12, 0.12),
				legSize = Vector3.new(0.34, 0.24, 0.40), legX = 0.44, legY = -0.82, legZ = { 0.10 },
				legColor = p.deep, tail = false,
			})
			for _, s in ipairs({ -1, 1 }) do
				-- Candy stripe near each end.
				c:box(Vector3.new(0.14, 1.62, 1.62), CFrame.new(0.70 * s, 0.06, 0), p.pale)
				-- Pinch, flared wrapper, and a crinkled star-shaped rim.
				c:box(Vector3.new(0.24, 0.44, 0.44), CFrame.new(0.94 * s, 0.06, 0), p.light)
				c:cone(Vector3.new(0.96, 0.62, 0.96), CFrame.new(1.30 * s, 0.06, 0) * CFrame.Angles(0, 0, s * math.pi / 2), p.light)
				c:box(Vector3.new(0.10, 1.00, 1.00), CFrame.new(1.62 * s, 0.06, 0), p.pale)
				c:box(Vector3.new(0.10, 0.96, 0.96), CFrame.new(1.60 * s, 0.06, 0) * CFrame.Angles(math.pi / 4, 0, 0), p.pale)
			end
			blush(c, 0.46, -0.26, 0.80)
			c:box(Vector3.new(0.42, 0.06, 0.20), CFrame.new(-0.28, 0.88, 0.36) * CFrame.Angles(0, 0.4, 0), WHITE)
		end,
	}

	-- A pleated cupcake with three tiers of frosting, sprinkles and a cherry.
	S.sr_cupcake = {
		label = "Cupcake",
		set = "sugar_rush",
		tint = C3(240, 150, 190),
		scale = 1.18,
		head = CFrame.new(0, 1.62, 0.04),
		neck = CFrame.new(0, -0.30, 0.86),
		back = CFrame.new(0, 0.10, -0.86),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.80, 1.16, 1.70),
				eyeY = 0.10, eyeSpread = 0.38, eyeSize = Vector3.new(0.40, 0.48, 0.18),
				mouthY = -0.24, mouthSize = Vector3.new(0.28, 0.12, 0.12),
				legs = false, tail = false,
			})
			-- Paper liner: a rim and pleats round the sides and back.
			c:box(Vector3.new(1.92, 0.14, 1.82), CFrame.new(0, -0.48, 0), p.dark)
			for _, s in ipairs({ -1, 1 }) do
				for _, z in ipairs({ -0.50, 0, 0.50 }) do
					c:box(Vector3.new(0.08, 1.06, 0.10), CFrame.new(0.92 * s, 0.04, z), p.dark)
				end
				c:box(Vector3.new(0.10, 1.06, 0.08), CFrame.new(0.42 * s, 0.04, -0.87), p.dark)
				c:box(Vector3.new(0.42, 0.22, 0.46), CFrame.new(0.46 * s, -0.66, 0.20), p.deep)
			end
			-- Frosting tiers and the cherry on top.
			c:box(Vector3.new(2.04, 0.40, 1.92), CFrame.new(0, 0.82, 0), p.pale)
			c:box(Vector3.new(1.56, 0.34, 1.46), CFrame.new(0, 1.14, -0.02), p.pale)
			c:box(Vector3.new(1.02, 0.30, 0.96), CFrame.new(0, 1.42, -0.04), p.pale)
			c:ball(Vector3.new(0.46, 0.46, 0.46), CFrame.new(0, 1.78, -0.02), C3(214, 36, 58))
			c:rod(Vector3.new(0, 1.96, -0.02), Vector3.new(0.12, 2.18, -0.06), 0.03, C3(96, 140, 60), nil, false)
			sprinkles(c, {
				{ -0.62, 0.86, 0.97, 0.5 }, { 0.50, 0.76, 0.97, -0.6 }, { 0.84, 1.03, 0.30, 0.2, 0.8 },
				{ -0.80, 1.03, -0.40, -0.3, -0.6 }, { 0.22, 1.20, 0.74, 0.9 }, { -0.30, 1.58, 0.20, 0.1, 1.2 },
			})
			blush(c, 0.62, -0.10, 0.88)
		end,
	}

	-- An ice-cream scoop with drips over the lip of a waffle cone.
	S.sr_scoop = {
		label = "Scoop",
		set = "sugar_rush",
		tint = C3(150, 226, 190),
		scale = 1.18,
		head = CFrame.new(0, 0.96, 0.10),
		neck = CFrame.new(0, -0.46, 0.66),
		back = CFrame.new(0, 0.20, -0.80),
		build = function(c, p)
			local waffle, waffleDark = C3(222, 170, 96), C3(190, 132, 66)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.96, 1.50, 1.86),
				eyeY = 0.14, eyeSpread = 0.40, eyeSize = Vector3.new(0.44, 0.54, 0.20),
				mouthY = -0.26, mouthSize = Vector3.new(0.30, 0.14, 0.12),
				legs = false, tail = false,
			})
			-- The cone, point down, with a rolled lip.
			c:cone(Vector3.new(1.44, 1.10, 1.44), CFrame.new(0, -0.94, 0) * CFrame.Angles(math.pi, 0, 0), waffle)
			c:box(Vector3.new(1.56, 0.18, 1.56), CFrame.new(0, -0.46, 0), waffleDark)
			-- Melting drips over the lip.
			for _, v in ipairs({
				{ -0.62, -0.66, 0.82, 0.44 }, { 0.66, -0.74, 0.78, 0.58 }, { 0.92, -0.66, -0.10, 0.44 },
				{ -0.90, -0.70, -0.30, 0.52 }, { 0.20, -0.70, -0.86, 0.50 },
			}) do
				c:box(Vector3.new(0.30, v[4], 0.30), CFrame.new(v[1], v[2], v[3]), p.base)
			end
			-- A wafer stuck in the top, and sprinkles.
			c:box(Vector3.new(0.26, 0.90, 0.14), CFrame.new(0.46, 1.04, -0.30) * CFrame.Angles(0, 0, -0.35), C3(232, 196, 130))
			sprinkles(c, {
				{ -0.40, 0.84, 0.30, 0.4 }, { 0.10, 0.86, 0.56, -0.7 }, { -0.10, 0.85, -0.40, 1.1, 0.5 },
				{ -0.70, 0.80, -0.20, -0.2, 1.0 }, { 0.70, 0.80, 0.30, 0.6, -0.4 },
			})
			blush(c, 0.56, -0.12, 0.91)
		end,
	}

	-- A see-through gummy bear: sitting up, arms out, feet forward.
	S.sr_gummy = {
		label = "Gummy",
		set = "sugar_rush",
		tint = C3(255, 96, 96),
		head = CFrame.new(0, 1.18, 0.06),
		neck = CFrame.new(0, -0.30, 0.62),
		back = CFrame.new(0, 0.20, -0.62),
		build = function(c, p)
			local from = c.count
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.90, 1.86, 1.70),
				snout = { w = 0.58, h = 0.42, d = 0.34, y = -0.18, color = p.light, nose = p.deep },
				eyeY = 0.26, eyeSpread = 0.40, eyeSize = Vector3.new(0.42, 0.50, 0.20),
				bib = { w = 0.86, h = 0.50, y = -0.58, color = p.light },
				legSize = Vector3.new(0.52, 0.36, 0.62), legX = 0.50, legZ = { 0.30 }, legColor = p.base,
				tailSize = Vector3.new(0.30, 0.30, 0.30), tailColor = p.base,
			})
			ears(c, p.base, "round")
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.44, 0.62, 0.44), CFrame.new(1.00 * s, -0.10, 0.28) * CFrame.Angles(0.4, 0, -0.5 * s), p.base)
			end
			jelly(c, from, { p.base, p.light })
			-- The glow of light caught inside the jelly.
			c:box(Vector3.new(1.00, 1.00, 0.90), CFrame.new(0, 0.02, -0.04), p.glow, NEON)
		end,
	}

	-- A round swirl lollipop on its stick, with a bow and two little shoes.
	S.sr_lollipop = {
		label = "Lollipop",
		set = "sugar_rush",
		tint = C3(255, 120, 200),
		scale = 1.16,
		head = CFrame.new(0, 1.42, 0.04),
		neck = CFrame.new(0, -0.80, 0.24),
		back = CFrame.new(0, 0.34, -0.30),
		build = function(c, p)
			local disc = CFrame.new(0, 0.34, 0) * CFrame.Angles(0, math.pi / 2, 0)
			c:cyl(Vector3.new(0.46, 2.10, 2.10), disc, p.base)
			c:cyl(Vector3.new(0.50, 1.56, 1.56), disc, p.pale)
			c:cyl(Vector3.new(0.54, 1.04, 1.04), disc, p.base)
			c:cyl(Vector3.new(0.58, 0.52, 0.52), disc, p.pale)
			c:eyes(0.50, 0.34, 0.36, 0.16)
			c:box(Vector3.new(0.34, 0.10, 0.08), CFrame.new(0, 0.10, 0.31), INK)
			blush(c, 0.62, 0.24, 0.30)
			c:box(Vector3.new(0.36, 0.10, 0.04), CFrame.new(-0.56, 0.96, 0.24) * CFrame.Angles(0, 0, 0.6), WHITE)
			-- The stick, a bow where it meets the candy, and two shoes.
			c:rod(Vector3.new(0, -0.70, 0), Vector3.new(0, -1.36, 0), 0.10, C3(248, 246, 240))
			c:box(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0, -0.82, 0.06), p.dark)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.36, 0.24, 0.10), CFrame.new(0.22 * s, -0.82, 0.06) * CFrame.Angles(0, 0, 0.4 * s), p.dark)
				c:box(Vector3.new(0.30, 0.18, 0.40), CFrame.new(0.18 * s, -1.44, 0.08), p.dark)
			end
		end,
	}

	return S
end
