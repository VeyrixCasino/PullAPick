--[[ PetBodies/HoloHavoc -- Holo Havoc's bodies. See tools/gen/sets/README.md.
	Chrome, glass and light: a mirror ball, a projected hologram, a camera bug,
	a glass jellyfish and a foil chameleon. Bodies are Metal or Glass with
	reflectance, so they catch the light; the tint still sets their colour. ]]
return function(K)
	local C3, block, ears = K.C3, K.block, K.ears
	local METAL, NEON, GLASS, INK, WHITE = K.METAL, K.NEON, K.GLASS, K.INK, K.WHITE
	local CHROME = C3(214, 220, 232)
	local FOIL_A, FOIL_B = C3(140, 240, 255), C3(255, 160, 236)
	local S = {}

	-- Restyle every part made since `from` (block()'s chassis), leaving the eyes.
	local function finish(c, from, mat, refl, transp)
		for i = from, c.count do
			local part = c.model:FindFirstChild("P" .. i)
			if part and not part:GetAttribute("Eye") then
				part.Material = mat
				part.Reflectance = refl or 0
				if transp then
					part.Transparency = transp
				end
			end
		end
	end

	-- A mirror ball on little feet: chrome body, bright tiles, a hanger and glints.
	S.hh_discoball = {
		label = "Disco Ball",
		set = "holo_havoc",
		tint = C3(196, 206, 228),
		head = CFrame.new(0, 1.30, 0.06),
		neck = CFrame.new(0, -0.46, 0.74),
		back = CFrame.new(0, 0.10, -0.74),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				shape = "round",
				bodySize = Vector3.new(1.90, 1.90, 1.90),
				eyeY = 0.12, mouthY = -0.34,
				legSize = Vector3.new(0.36, 0.24, 0.40), legX = 0.46, legY = -0.92, legZ = { 0.30, -0.30 }, legColor = p.deep,
				tail = false,
			})
			finish(c, from, METAL, 0.45)
			-- Mirror tiles over the top, sides and back.
			local tiles = {
				{ -0.40, 0.98, 0.40, 0, 0 }, { 0.40, 0.98, -0.40, 0, 0 }, { 0.40, 0.98, 0.40, 0, 0 }, { -0.40, 0.98, -0.40, 0, 0 },
				{ -0.98, 0.45, 0.30, 0, 1 }, { 0.98, 0.45, 0.30, 0, 1 }, { -0.98, -0.30, -0.30, 0, 1 }, { 0.98, -0.30, -0.30, 0, 1 },
				{ -0.40, 0.30, -0.92, 1, 0 }, { 0.40, -0.30, -0.92, 1, 0 },
			}
			for i, t in ipairs(tiles) do
				local size = (t[5] == 1) and Vector3.new(0.06, 0.36, 0.36) or ((t[4] == 1) and Vector3.new(0.36, 0.36, 0.06) or Vector3.new(0.36, 0.06, 0.36))
				local part = c:box(size, CFrame.new(t[1], t[2], t[3]), (i % 2 == 0) and p.pale or p.light, METAL)
				part.Reflectance = 0.6
			end
			c:star(Vector3.new(0.86, 0.84, 0.70), 0.40, WHITE)
			c:star(Vector3.new(-0.92, -0.40, 0.66), 0.28, WHITE)
			-- The hanger it came down from.
			c:cyl(Vector3.new(0.18, 0.50, 0.50), CFrame.new(0, 1.02, 0) * CFrame.Angles(0, 0, math.pi / 2), CHROME, METAL)
			c:rod(Vector3.new(-0.16, 1.10, 0), Vector3.new(0, 1.32, 0), 0.04, CHROME, METAL, false)
			c:rod(Vector3.new(0, 1.32, 0), Vector3.new(0.16, 1.10, 0), 0.04, CHROME, METAL, false)
		end,
	}

	-- A see-through hologram pup projected up from a chrome emitter puck.
	S.hh_holopup = {
		label = "Holo Pup",
		set = "holo_havoc",
		tint = C3(90, 220, 255),
		scale = 1.08,
		head = CFrame.new(0, 1.26, 0.06),
		neck = CFrame.new(0, -0.30, 0.62),
		back = CFrame.new(0, 0.20, -0.62),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				shape = "quad",
				bodySize = Vector3.new(1.90, 1.70, 1.76),
				bodyColor = p.light, shapeColor = p.light, eyeColor = p.deep,
				snout = { w = 0.60, h = 0.42, d = 0.48, color = p.pale, nose = p.deep },
				legColor = p.base, tailColor = p.base, tailSize = Vector3.new(0.30, 0.30, 0.60),
			})
			ears(c, p.light, "up")
			finish(c, from, GLASS, 0.15, 0.30)
			-- Scan lines sliced through the projection.
			for _, y in ipairs({ 0.58, 0.04, -0.46 }) do
				c:box(Vector3.new(2.00, 0.04, 1.86), CFrame.new(0, y, 0), p.pale, NEON).Transparency = 0.2
			end
			-- The emitter: a chrome puck, a glowing ring and a cone of light.
			c:cyl(Vector3.new(0.22, 1.70, 1.70), CFrame.new(0, -1.30, 0) * CFrame.Angles(0, 0, math.pi / 2), CHROME, METAL).Reflectance = 0.4
			c:cyl(Vector3.new(0.06, 1.30, 1.30), CFrame.new(0, -1.17, 0) * CFrame.Angles(0, 0, math.pi / 2), p.glow, NEON)
			c:cone(Vector3.new(1.50, 0.40, 1.50), CFrame.new(0, -1.00, 0) * CFrame.Angles(math.pi, 0, 0), p.glow, NEON).Transparency = 0.6
			-- Two stray pixels glitching off the edge.
			c:box(Vector3.new(0.18, 0.18, 0.18), CFrame.new(1.14, 0.62, -0.30), p.glow, NEON).Transparency = 0.2
			c:box(Vector3.new(0.14, 0.14, 0.14), CFrame.new(-1.08, -0.10, 0.40), p.glow, NEON).Transparency = 0.2
			c:light(p.glow, 1.4, 8)
		end,
	}

	-- A camera bug: chrome body, leatherette grip, a big lens for a nose, a flash,
	-- a shutter button, antennae and six little legs.
	S.hh_shutterbug = {
		label = "Shutterbug",
		set = "holo_havoc",
		tint = C3(74, 78, 98),
		head = CFrame.new(0, 1.24, -0.10),
		neck = CFrame.new(0, -0.56, 0.82),
		back = CFrame.new(0, 0.30, -0.72),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				square = true, bodySize = Vector3.new(2.10, 1.40, 1.50),
				eyeY = 0.42, eyeSize = Vector3.new(0.34, 0.40, 0.20), eyeSpread = 0.72, mouth = false,
				legSize = Vector3.new(0.22, 0.40, 0.26), legX = 0.80, legY = -0.70, legZ = { 0.50, 0, -0.50 }, legColor = p.deep,
				tail = false,
			})
			finish(c, from, METAL, 0.30)
			c:box(Vector3.new(2.14, 0.70, 1.54), CFrame.new(0, -0.20, 0), p.deep)
			c:box(Vector3.new(0.80, 0.36, 0.80), CFrame.new(0, 0.92, 0), p.base, METAL).Reflectance = 0.3
			-- The lens: chrome barrel, dark focus ring, coated glass and a glint.
			local axis = CFrame.Angles(0, math.pi / 2, 0)
			c:cyl(Vector3.new(0.50, 1.00, 1.00), CFrame.new(0, -0.08, 0.98) * axis, CHROME, METAL).Reflectance = 0.4
			c:cyl(Vector3.new(0.18, 1.08, 1.08), CFrame.new(0, -0.08, 1.06) * axis, INK)
			c:cyl(Vector3.new(0.06, 0.78, 0.78), CFrame.new(0, -0.08, 1.24) * axis, C3(70, 46, 150), GLASS).Reflectance = 0.5
			c:ball(Vector3.new(0.18, 0.18, 0.08), CFrame.new(0.16, 0.08, 1.28), WHITE)
			-- Flash, shutter button.
			c:box(Vector3.new(0.46, 0.22, 0.30), CFrame.new(-0.62, 0.86, 0.40), p.pale)
			c:box(Vector3.new(0.40, 0.16, 0.04), CFrame.new(-0.62, 0.86, 0.56), C3(255, 252, 230), NEON)
			c:cyl(Vector3.new(0.12, 0.24, 0.24), CFrame.new(0.66, 0.82, 0.20) * CFrame.Angles(0, 0, math.pi / 2), C3(220, 50, 60))
			-- Antennae with glowing tips.
			for _, s in ipairs({ -1, 1 }) do
				local tip = Vector3.new(0.46 * s, 1.50, 0.36)
				c:rod(Vector3.new(0.20 * s, 1.06, 0.10), tip, 0.035, p.dark, nil, false)
				c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(tip), p.glow, NEON)
			end
		end,
	}

	-- A glass jellyfish: a see-through bell with a glowing core, a frilled skirt,
	-- trailing tentacles and two ribbon arms.
	S.hh_jelly = {
		label = "Jellyfish",
		set = "holo_havoc",
		tint = C3(200, 150, 255),
		head = CFrame.new(0, 1.16, 0.06),
		neck = CFrame.new(0, -0.50, 0.70),
		back = CFrame.new(0, 0.20, -0.74),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				shape = "round",
				bodySize = Vector3.new(2.00, 1.50, 1.90),
				eyeY = 0.08, mouth = false, legs = false, tail = false,
			})
			c:box(Vector3.new(1.50, 0.40, 1.40), CFrame.new(0, 0.92, -0.04), p.base)
			finish(c, from, GLASS, 0.25, 0.30)
			c:box(Vector3.new(0.26, 0.12, 0.12), CFrame.new(0, -0.30, 0.95), INK)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.16, 0.08, 0.04), CFrame.new(0.62 * s, -0.18, 0.93), C3(255, 150, 190), NEON)
			end
			for _, v in ipairs({ { -0.40, 1.13, 0.20 }, { 0.36, 1.13, -0.24 }, { 0.02, 1.13, 0.42 } }) do
				c:box(Vector3.new(0.22, 0.04, 0.22), CFrame.new(v[1], v[2], v[3]), p.pale, NEON)
			end
			c:box(Vector3.new(0.90, 0.60, 0.80), CFrame.new(0, 0.10, -0.15), p.glow, NEON)
			local skirt = c:box(Vector3.new(2.16, 0.20, 2.04), CFrame.new(0, -0.66, 0), p.light, GLASS)
			skirt.Transparency = 0.2
			skirt.Reflectance = 0.2
			-- Tentacles: alternating glow and glass, each drifting a little.
			local roots = { { -0.66, 0.48 }, { 0.66, 0.48 }, { -0.66, -0.48 }, { 0.66, -0.48 }, { -0.86, 0 }, { 0.86, 0 } }
			for i, r in ipairs(roots) do
				local drift = (i % 2 == 0) and 0.14 or -0.14
				c:rod(
					Vector3.new(r[1], -0.70, r[2]),
					Vector3.new(r[1] * 1.14, -1.52, r[2] + drift),
					0.06,
					(i % 2 == 0) and p.glow or p.pale,
					(i % 2 == 0) and NEON or GLASS,
					false
				)
			end
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.22, 0.90, 0.22), CFrame.new(0.18 * s, -1.12, 0.10) * CFrame.Angles(0.15, 0, 0.12 * s), p.pale, GLASS).Transparency = 0.2
			end
			c:light(p.glow, 1.4, 8)
		end,
	}

	-- A chameleon in colour-shift foil: turret eyes, a casque crest, a curled tail
	-- and the tip of its tongue poking out.
	S.hh_chameleon = {
		label = "Chameleon",
		set = "holo_havoc",
		tint = C3(110, 226, 170),
		scale = 1.06,
		head = CFrame.new(0, 1.44, -0.10),
		neck = CFrame.new(0, -0.44, 0.70),
		back = CFrame.new(0, 0.40, -0.62),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				shape = "quad",
				bodySize = Vector3.new(1.96, 1.70, 1.86),
				eyeSize = Vector3.new(0.40, 0.46, 0.34), eyeSpread = 0.50, eyeY = 0.20,
				mouth = false,
				legSize = Vector3.new(0.40, 0.34, 0.44), legColor = p.dark,
				tail = false,
			})
			finish(c, from, METAL, 0.30)
			for _, s in ipairs({ -1, 1 }) do
				c:round(Vector3.new(0.66, 0.70, 0.26), CFrame.new(0.50 * s, 0.20, 0.92), p.light, METAL)
				-- Two foil stripes down each flank.
				for k = 0, 1 do
					local stripe = c:box(Vector3.new(0.06, 0.90, 0.20), CFrame.new(0.99 * s, 0.20, -0.20 - k * 0.42) * CFrame.Angles(0.40, 0, 0), (k == 0) and FOIL_A or FOIL_B, METAL)
					stripe.Reflectance = 0.5
				end
			end
			c:box(Vector3.new(1.00, 0.08, 0.10), CFrame.new(0, -0.32, 0.95), p.deep)
			c:rod(Vector3.new(0, -0.36, 0.96), Vector3.new(0, -0.44, 1.18), 0.06, C3(255, 120, 150), nil, false)
			c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0, -0.46, 1.24), C3(255, 120, 150))
			c:cone(Vector3.new(0.30, 0.70, 0.90), CFrame.new(0, 1.12, -0.10) * CFrame.Angles(-0.40, 0, 0), p.light, METAL).Reflectance = 0.3
			-- The tail rolls up into a spiral behind it.
			for k = 0, 5 do
				local a, r, sz = k * 1.15, 0.30 - k * 0.03, 0.38 - k * 0.035
				c:box(Vector3.new(sz, sz, sz), CFrame.new(0, -0.30 + r * math.cos(a), -1.18 - r * math.sin(a)), p.base, METAL).Reflectance = 0.3
			end
		end,
	}

	return S
end
