--[[ PetBodies/RainbowRoadTop -- Rainbow Road's top bodies (Epic and up).
	Each of these is worn by exactly ONE pet in the game (owner, 2026-10-10:
	"ALL UNIQUE"). Natural rainbow crystal, prisms and colourful-world
	creatures, pastel to prismatic; no chrome foil (that is Holo Havoc).
	Rainbow hues are blended a little toward each pet's own tint, as in
	PetBodies/RainbowRoad. See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block = K.C3, K.block
	local GLASS, NEON, METAL, WOOD, INK, WHITE = K.GLASS, K.NEON, K.METAL, K.WOOD, K.INK, K.WHITE
	local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
	local PI = math.pi
	local HUES = {
		C3(255, 92, 92), C3(255, 164, 72), C3(255, 226, 90), C3(110, 220, 120),
		C3(90, 190, 255), C3(150, 120, 255), C3(230, 120, 230),
	}
	local BLUSH = C3(255, 150, 176)
	local GOLD = C3(255, 206, 96)
	local CLOUD = C3(250, 250, 255)
	local SIDES = { -1, 1 }
	local S = {}

	-- Rainbow hue `i` (wrapping), pulled a little toward the pet's own colour.
	local function hue(p, i)
		return HUES[(i - 1) % #HUES + 1]:Lerp(p.pale, 0.28)
	end

	-- A crystal: a column with a pyramid tip, standing on `base`, tilted by `tilt` (3 parts).
	local function crystal(c, base, tilt, w, h, colour)
		local cf = CF(base) * tilt
		c:box(V(w, h, w), cf * CF(0, h * 0.5, 0), colour, GLASS).Reflectance = 0.1
		c:cone(V(w, w * 0.9, w), cf * CF(0, h + w * 0.45, 0), colour, GLASS).Reflectance = 0.1
	end

	-- A pyramid spike whose base sits at `at`, pointing along `dir` (2 parts).
	local function spike(c, at, dir, w, h, colour, mat)
		local u = dir.Unit
		local cf
		if u.Y > 0.999 then
			cf = CF(at)
		elseif u.Y < -0.999 then
			cf = CF(at) * A(PI, 0, 0)
		else
			cf = CFrame.lookAt(at, at + u) * A(-PI / 2, 0, 0)
		end
		return c:cone(V(w, h, w), cf * CF(0, h * 0.5, 0), colour, mat)
	end

	-- A cube turned onto its point (1 part).
	local function gem(c, pos, size, colour, mat)
		return c:box(V(size, size, size), CF(pos) * A(PI / 4, 0, PI / 4), colour, mat or GLASS)
	end

	-- Blush marks either side of a face (2 parts).
	local function cheeks(c, x, y, z)
		for _, s in ipairs(SIDES) do
			c:box(V(0.18, 0.10, 0.04), CF(x * s, y, z), BLUSH)
		end
	end

	---------------------------------------------------------------- EPIC

	-- A koi with rainbow saddle bands, barbels and a flared two-lobed tail.
	S.rd_t_koi = {
		label = "Rainbow Koi",
		set = "rainbow_road",
		tint = C3(255, 140, 40),
		scale = 1.20,
		head = CF(0, 0.92, 0.30),
		neck = CF(0, -0.42, 1.00),
		back = CF(0, 0.30, -1.00),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.30, 1.36, 2.00),
				eyeY = 0.12, eyeSize = V(0.36, 0.44, 0.20), eyeSpread = 0.34,
				mouthY = -0.28, mouthSize = V(0.34, 0.16, 0.12),
				legs = false, tail = false,
			})
			for i, z in ipairs({ 0.35, -0.10, -0.55 }) do
				c:box(V(1.36, 1.42, 0.22), CF(0, 0.06, z), hue(p, i * 2 - 1))
			end
			c:box(V(0.60, 0.70, 0.40), CF(0, 0.06, -1.15), p.base)
			for _, s in ipairs(SIDES) do
				c:box(V(0.12, 0.90, 0.70), CF(0, 0.06 + 0.32 * s, -1.55) * A(-0.55 * s, 0, 0), hue(p, s < 0 and 5 or 6))
				c:box(V(0.40, 0.08, 0.36), CF(0.78 * s, -0.30, 0.30) * A(0, 0, -0.40 * s), p.light)
				c:rod(V(0.22 * s, -0.36, 1.00), V(0.46 * s, -0.56, 1.18), 0.035, p.dark, nil, false)
			end
			c:box(V(0.10, 0.40, 0.90), CF(0, 0.86, -0.10), p.light)
			cheeks(c, 0.46, -0.20, 1.01)
			c:ball(V(0.26, 0.26, 0.26), CF(0.32, 1.22, 0.62), p.pale, GLASS)
		end,
	}

	-- A squat frog with bulging eye bumps and opal spots on its back.
	S.rd_t_frog = {
		label = "Opal Frog",
		set = "rainbow_road",
		tint = C3(70, 200, 150),
		head = CF(0, 1.02, 0.10),
		neck = CF(0, -0.30, 0.92),
		back = CF(0, 0.55, -0.80),
		build = function(c, p)
			block(c, p, {
				bodySize = V(2.00, 1.20, 1.70),
				eyeY = 0.46, eyeSize = V(0.42, 0.48, 0.22), eyeSpread = 0.50,
				mouthY = -0.12, mouthSize = V(1.00, 0.08, 0.12),
				bib = { w = 1.50, h = 0.30, y = -0.42, color = p.pale },
				legSize = V(0.56, 0.24, 0.60), legX = 0.76, legY = -0.58, legZ = { 0.50, -0.40 },
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V(0.62, 0.52, 0.56), CF(0.50 * s, 0.62, 0.52), p.base)
			end
			for i, xz in ipairs({ { -0.55, -0.15 }, { 0.55, -0.20 }, { 0.00, -0.55 }, { 0.00, 0.05 } }) do
				c:box(V(0.32, 0.08, 0.32), CF(xz[1], 0.68, xz[2]) * A(0, PI / 4, 0), hue(p, i * 2), GLASS).Reflectance = 0.15
			end
			crystal(c, V(0, 0.66, -0.25), A(0, PI / 4, 0), 0.22, 0.30, hue(p, 6))
			cheeks(c, 0.74, 0.08, 0.86)
		end,
	}

	-- A round bunny whose tall ears are rainbow crystals.
	S.rd_t_bunny = {
		label = "Prismear Bunny",
		set = "rainbow_road",
		tint = C3(255, 190, 150),
		head = CF(0, 1.02, 0.15),
		neck = CF(0, -0.42, 0.88),
		back = CF(0, 0.30, -0.88),
		build = function(c, p)
			block(c, p, {
				shape = "round",
				bodySize = V(1.80, 1.70, 1.70),
				eyeY = 0.14, eyeSize = V(0.42, 0.50, 0.22), eyeSpread = 0.38,
				snout = { w = 0.40, h = 0.26, d = 0.30, y = -0.22, color = p.pale, nose = BLUSH },
				legSize = V(0.42, 0.28, 0.60), legX = 0.48, legY = -0.80, legZ = { 0.34, -0.36 },
				tailSize = V(0.50, 0.50, 0.40), tailColor = p.pale,
			})
			for _, s in ipairs(SIDES) do
				crystal(c, V(0.34 * s, 0.80, -0.05), A(0, 0, -0.18 * s), 0.30, 0.70, hue(p, s < 0 and 7 or 5))
			end
			cheeks(c, 0.48, -0.20, 0.86)
		end,
	}

	-- A little butterfly whose wings are banded in rainbow stripes.
	S.rd_t_butterfly = {
		label = "Huewing Butterfly",
		set = "rainbow_road",
		tint = C3(170, 110, 255),
		scale = 1.20,
		head = CF(0, 0.70, 0.30),
		neck = CF(0, -0.40, 0.76),
		back = CF(0, 0.20, -1.30),
		build = function(c, p)
			block(c, p, {
				bodySize = V(0.90, 1.00, 1.40),
				eyeY = 0.10, eyeSize = V(0.30, 0.36, 0.20), eyeSpread = 0.22,
				mouthY = -0.22, mouthSize = V(0.18, 0.08, 0.10),
				legs = false, tail = false,
			})
			c:box(V(0.60, 0.60, 0.80), CF(0, 0.00, -1.05), p.dark)
			for _, s in ipairs(SIDES) do
				local up = CF(0.95 * s, 0.62, -0.15) * A(0, 0.30 * s, 0.30 * s)
				c:box(V(1.00, 0.95, 0.08), up, p.light)
				for k = 1, 2 do
					c:box(V(0.14, 0.86, 0.10), up * CF((0.02 + 0.24 * k) * s, 0, 0), hue(p, s < 0 and k or k + 3))
				end
				c:box(V(0.16, 0.16, 0.10), up * CF(-0.14 * s, 0.20, 0), p.glow, NEON)
				c:box(V(0.80, 0.70, 0.08), CF(0.78 * s, -0.20, -0.20) * A(0, 0.30 * s, -0.30 * s), p.base)
				local tip = V(0.32 * s, 1.10, 0.86)
				c:rod(V(0.12 * s, 0.50, 0.62), tip, 0.035, p.deep, nil, false)
				c:ball(V(0.18, 0.18, 0.18), CF(tip), hue(p, s < 0 and 1 or 5), GLASS)
			end
			cheeks(c, 0.30, -0.14, 0.71)
		end,
	}

	-- An owl with pale facial discs and rainbow crystal ear tufts.
	S.rd_t_owl = {
		label = "Huetuft Owl",
		set = "rainbow_road",
		tint = C3(120, 140, 240),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.50, 0.86),
		back = CF(0, 0.20, -0.86),
		build = function(c, p)
			block(c, p, {
				shape = "bird",
				bodySize = V(1.80, 2.00, 1.60),
				eyeY = 0.24, eyeSize = V(0.50, 0.56, 0.22), eyeSpread = 0.42,
				mouth = false,
				bib = { w = 1.10, h = 0.80, y = -0.50, color = p.pale },
				legSize = V(0.36, 0.20, 0.40), legZ = { 0.20 }, legY = -0.98, legColor = GOLD,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V(0.70, 0.74, 0.08), CF(0.42 * s, 0.24, 0.80), p.light)
				crystal(c, V(0.58 * s, 0.98, 0.05), A(0, 0, -0.35 * s), 0.24, 0.34, hue(p, s < 0 and 6 or 2))
				c:box(V(0.20, 1.10, 1.00), CF(0.92 * s, -0.05, -0.10) * A(0, 0, 0.10 * s), p.dark)
			end
			c:cone(V(0.22, 0.30, 0.20), CF(0, -0.02, 0.90) * A(PI, 0, 0), GOLD)
		end,
	}

	-- A diamond kite with a face, crossed spars behind and a tail of bows.
	S.rd_t_kite = {
		label = "Sunshower Kite",
		set = "rainbow_road",
		tint = C3(220, 60, 180),
		head = CF(0, 1.66, 0),
		neck = CF(0, -0.20, 0.30),
		back = CF(0, 0.50, -0.30),
		build = function(c, p)
			local face = CF(0, 0.55, 0) * A(0, 0, PI / 4)
			-- Quarters: top and bottom in the pet's colour, the sides in rainbow.
			c:box(V(0.76, 0.76, 0.36), face * CF(0.38, 0.38, 0), p.base)
			c:box(V(0.76, 0.76, 0.36), face * CF(-0.38, -0.38, 0), p.light)
			c:box(V(0.76, 0.76, 0.36), face * CF(-0.38, 0.38, 0), hue(p, 5))
			c:box(V(0.76, 0.76, 0.36), face * CF(0.38, -0.38, 0), hue(p, 3))
			c:eyes(0.70, 0.24, 0.26, 0.15)
			c:box(V(0.30, 0.08, 0.06), CF(0, 0.40, 0.20), INK)
			cheeks(c, 0.46, 0.50, 0.20)
			local SPAR = C3(196, 150, 100)
			c:box(V(0.08, 2.10, 0.06), CF(0, 0.55, -0.21), SPAR, WOOD)
			c:box(V(2.10, 0.08, 0.06), CF(0, 0.55, -0.21), SPAR, WOOD)
			local pts = { V(0, -0.52, -0.05), V(0.22, -0.85, -0.40), V(-0.12, -1.02, -0.80), V(0.10, -1.10, -1.20) }
			for i = 1, 3 do
				c:rod(pts[i], pts[i + 1], 0.03, p.deep, nil, false)
				c:box(V(0.22, 0.22, 0.08), CF(pts[i + 1]) * A(0, 0, PI / 4), hue(p, i * 2 - 1))
			end
		end,
	}

	-- A tortoise whose shell steps up in terraces, one rainbow band each.
	S.rd_t_tortoise = {
		label = "Rainstep Tortoise",
		set = "rainbow_road",
		tint = C3(90, 180, 80),
		head = CF(0, 1.62, -0.18),
		neck = CF(0, -0.32, 0.92),
		back = CF(0, 0.70, -1.10),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.70, 1.00, 1.80),
				eyeY = 0.04, eyeSize = V(0.36, 0.42, 0.20), eyeSpread = 0.36,
				mouthY = -0.26, mouthSize = V(0.36, 0.08, 0.10),
				legSize = V(0.50, 0.40, 0.50), legX = 0.80, legY = -0.50, legZ = { 0.50, -0.60 },
				tailSize = V(0.24, 0.24, 0.30), tailColor = p.base,
			})
			c:box(V(2.06, 0.22, 1.90), CF(0, 0.52, -0.18), p.dark)
			for i, st in ipairs({ { 1.70, 1.56, 1 }, { 1.34, 1.22, 3 }, { 0.98, 0.88, 5 }, { 0.60, 0.54, 6 } }) do
				c:box(V(st[1], 0.24, st[2]), CF(0, 0.52 + 0.23 * i, -0.18), hue(p, st[3]))
			end
			crystal(c, V(0, 1.56, -0.18), A(0, PI / 4, 0), 0.24, 0.26, hue(p, 7))
			cheeks(c, 0.58, -0.26, 0.91)
		end,
	}

	-- An otter sitting up, hugging a cracked geode full of rainbow crystal.
	S.rd_t_otter = {
		label = "Geodehug Otter",
		set = "rainbow_road",
		tint = C3(150, 100, 70),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.30, 1.10),
		back = CF(0, 0.20, -0.76),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.60, 2.00, 1.40),
				eyeY = 0.44, eyeSize = V(0.34, 0.40, 0.20), eyeSpread = 0.32,
				snout = { w = 0.60, h = 0.34, d = 0.30, y = 0.04, color = p.pale, nose = INK },
				bib = { w = 1.10, h = 0.90, y = -0.42, color = p.pale },
				legSize = V(0.46, 0.30, 0.60), legX = 0.42, legY = -0.96, legZ = { 0.30 },
				tail = false,
			})
			K.ears(c, p.dark, "round")
			c:box(V(0.44, 0.18, 0.90), CF(0, -0.86, -1.05), p.dark)
			c:box(V(0.72, 0.56, 0.36), CF(0, -0.36, 0.86), C3(150, 136, 156))
			c:box(V(0.54, 0.40, 0.06), CF(0, -0.34, 1.05), hue(p, 6), GLASS)
			for i, x in ipairs({ -0.14, 0.12 }) do
				c:cone(V(0.16, 0.24, 0.12), CF(x, -0.36 + 0.06 * i, 1.10), hue(p, i * 2 + 1), GLASS)
			end
			for _, s in ipairs(SIDES) do
				c:box(V(0.30, 0.26, 0.30), CF(0.40 * s, -0.26, 0.92), p.base)
			end
			cheeks(c, 0.50, 0.12, 0.71)
		end,
	}

	-- A round chick with a fan of rainbow crest feathers.
	S.rd_t_chick = {
		label = "Sunbeam Chick",
		set = "rainbow_road",
		tint = C3(255, 240, 130),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.40, 0.88),
		back = CF(0, 0.20, -0.88),
		build = function(c, p)
			local BEAK = C3(255, 150, 60)
			block(c, p, {
				shape = "round",
				bodySize = V(1.80, 1.70, 1.70),
				eyeY = 0.18, eyeSize = V(0.40, 0.48, 0.22), eyeSpread = 0.40,
				mouth = false,
				legSize = V(0.30, 0.20, 0.40), legZ = { 0.15 }, legX = 0.40, legY = -0.86, legColor = BEAK,
				tail = false,
			})
			c:cone(V(0.30, 0.30, 0.26), CF(0, -0.10, 0.92) * A(PI / 2, 0, 0), BEAK)
			for i = 1, 5 do
				c:box(V(0.14, 0.50, 0.14), CF(0, 0.82, 0.05) * A(0, 0, (i - 3) * 0.38) * CF(0, 0.26, 0), hue(p, i))
			end
			for _, s in ipairs(SIDES) do
				c:box(V(0.20, 0.50, 0.60), CF(0.92 * s, -0.06, -0.05) * A(0, 0, -0.25 * s), p.light)
			end
			cheeks(c, 0.50, -0.16, 0.86)
		end,
	}

	-- A glassy jellyfish trailing six ribbon tentacles, one per hue.
	S.rd_t_jelly = {
		label = "Rainbow Jelly",
		set = "rainbow_road",
		tint = C3(110, 230, 240),
		head = CF(0, 0.92, 0),
		neck = CF(0, -0.50, 0.86),
		back = CF(0, 0.20, -0.86),
		build = function(c, p)
			local _, _, bell = block(c, p, {
				shape = "round",
				bodySize = V(1.90, 1.30, 1.80),
				eyeY = 0.02, eyeSize = V(0.36, 0.42, 0.20), eyeSpread = 0.38,
				mouthY = -0.26, mouthSize = V(0.24, 0.10, 0.10),
				legs = false, tail = false,
			})
			bell.Reflectance = 0.15
			c:box(V(2.00, 0.14, 1.90), CF(0, -0.54, 0), p.pale)
			local i = 0
			for _, z in ipairs({ 0.40, -0.40 }) do
				for _, x in ipairs({ -0.60, 0.00, 0.60 }) do
					i += 1
					local sway = 0.12 * math.sin(i * 1.7)
					c:rod(V(x, -0.56, z), V(x + sway, -1.50 + 0.08 * (i % 2), z - 0.12), 0.07, hue(p, i), nil, false)
				end
			end
			for k, xz in ipairs({ { -0.45, -0.20 }, { 0.40, 0.10 }, { 0.00, -0.50 } }) do
				c:box(V(0.18, 0.08, 0.18), CF(xz[1], 0.70 + 0.02 * k, xz[2]), p.glow, NEON)
			end
			cheeks(c, 0.50, -0.18, 0.88)
		end,
	}

	-- A round bumblebee striped in rainbow bands, with glassy wings.
	S.rd_t_bumble = {
		label = "Rainbow Bumble",
		set = "rainbow_road",
		tint = C3(255, 190, 40),
		head = CF(0, 1.06, 0.20),
		neck = CF(0, -0.40, 0.96),
		back = CF(0, 0.20, -1.00),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.80, 1.60, 1.90),
				eyeY = 0.16, eyeSize = V(0.42, 0.50, 0.22), eyeSpread = 0.40,
				mouthY = -0.30, mouthSize = V(0.26, 0.12, 0.10),
				legSize = V(0.24, 0.30, 0.24), legX = 0.50, legY = -0.80,
				tail = false,
			})
			for i, z in ipairs({ 0.20, -0.25, -0.70 }) do
				c:box(V(1.84, 1.64, 0.22), CF(0, 0.06, z), hue(p, i * 2 + 1))
			end
			c:cone(V(0.24, 0.36, 0.24), CF(0, -0.10, -1.12) * A(-PI / 2, 0, 0), INK)
			for _, s in ipairs(SIDES) do
				local w = c:box(V(0.90, 0.06, 0.62), CF(0.62 * s, 0.98, -0.20) * A(0, 0, 0.50 * s), C3(236, 246, 255), GLASS)
				w.Transparency = 0.3
				local tip = V(0.30 * s, 1.30, 0.80)
				c:rod(V(0.20 * s, 0.80, 0.70), tip, 0.035, INK, nil, false)
				c:ball(V(0.18, 0.18, 0.18), CF(tip), hue(p, s < 0 and 6 or 1), GLASS)
			end
			cheeks(c, 0.58, -0.22, 0.96)
		end,
	}

	-- A mole in a miner's helmet with a glowing crystal lamp and glassy claws.
	S.rd_t_mole = {
		label = "Gemlamp Mole",
		set = "rainbow_road",
		tint = C3(110, 90, 160),
		head = CF(0, 1.16, 0.05),
		neck = CF(0, -0.40, 1.10),
		back = CF(0, 0.30, -1.00),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				bodySize = V(1.90, 1.40, 1.90),
				eyeY = 0.16, eyeSize = V(0.30, 0.26, 0.20), eyeSpread = 0.34,
				snout = { w = 0.50, h = 0.36, d = 0.42, y = -0.14, color = p.pale, nose = C3(255, 120, 160) },
				legs = false,
				tailSize = V(0.20, 0.20, 0.40), tailColor = p.pale,
			})
			local HAT = C3(255, 206, 70)
			c:box(V(1.50, 0.08, 1.40), CF(0, 0.78, 0.10), HAT)
			c:box(V(1.20, 0.34, 1.10), CF(0, 0.96, 0.05), HAT)
			c:box(V(0.28, 0.24, 0.14), CF(0, 0.96, 0.64), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V(0.56, 0.24, 0.50), CF(0.82 * s, -0.56, 0.55), p.pale)
				c:box(V(0.56, 0.12, 0.14), CF(0.82 * s, -0.60, 0.86), hue(p, s < 0 and 5 or 2), GLASS)
				c:box(V(0.42, 0.20, 0.40), CF(0.60 * s, -0.62, -0.55), p.dark)
			end
			cheeks(c, 0.56, -0.12, 0.96)
		end,
	}

	-- A kitten sitting up, crystal-eared, with a bell gem and a rainbow-ringed tail.
	S.rd_t_kitty = {
		label = "Rainbell Kitty",
		set = "rainbow_road",
		tint = C3(130, 200, 255),
		head = CF(0, 1.36, 0),
		neck = CF(0, -0.22, 0.86),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.70, 1.90, 1.50),
				eyeY = 0.36, eyeSize = V(0.42, 0.50, 0.22), eyeSpread = 0.38,
				mouthY = 0.02, mouthSize = V(0.20, 0.10, 0.10),
				bib = { w = 0.90, h = 0.70, y = -0.55, color = p.pale },
				legSize = V(0.36, 0.50, 0.36), legX = 0.36, legY = -0.70, legZ = { 0.66 },
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(V(0.44, 0.46, 0.30), CF(0.52 * s, 1.22, 0) * A(0, 0, -0.20 * s), p.base)
				c:cone(V(0.24, 0.28, 0.10), CF(0.52 * s, 1.18, 0.16) * A(0, 0, -0.20 * s), hue(p, s < 0 and 7 or 6), GLASS)
			end
			c:box(V(1.76, 0.16, 1.56), CF(0, -0.16, 0), hue(p, 1))
			gem(c, V(0, -0.34, 0.80), 0.22, hue(p, 5))
			for i, q in ipairs({ { 0.10, -0.62, -0.88 }, { 0.20, -0.24, -0.98 }, { 0.30, 0.14, -1.00 }, { 0.36, 0.50, -0.94 } }) do
				c:box(V(0.28, 0.40, 0.28), CF(q[1], q[2], q[3]), i % 2 == 1 and p.base or hue(p, i + 1))
			end
			c:cone(V(0.24, 0.30, 0.24), CF(0.38, 0.84, -0.92), hue(p, 5), GLASS)
			cheeks(c, 0.52, 0.04, 0.76)
		end,
	}

	-- A raindrop floating over its own puddle, rainbow beads splashing round it.
	S.rd_t_droplet = {
		label = "Dewbow Droplet",
		set = "rainbow_road",
		tint = C3(50, 110, 240),
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.40, 0.86),
		back = CF(0, 0.30, -0.86),
		build = function(c, p)
			local _, _, drop = block(c, p, {
				shape = "round",
				bodySize = V(1.70, 1.50, 1.60),
				eyeY = 0.06, eyeSize = V(0.40, 0.48, 0.22), eyeSpread = 0.36,
				mouthY = -0.30, mouthSize = V(0.26, 0.12, 0.10),
				legs = false, tail = false,
			})
			drop.Reflectance = 0.2
			c:box(V(1.10, 0.40, 1.04), CF(0, 0.90, 0), p.base)
			c:box(V(0.70, 0.36, 0.66), CF(0, 1.24, 0), p.light)
			c:cone(V(0.40, 0.40, 0.40), CF(0, 1.62, 0), p.light)
			c:box(V(2.10, 0.08, 1.90), CF(0, -0.82, 0), p.pale, GLASS)
			for i = 1, 4 do
				local a = i * PI / 2 + PI / 4
				c:ball(V(0.20, 0.20, 0.20), CF(math.cos(a) * 1.00, -0.62 + 0.08 * (i % 2), math.sin(a) * 0.90), hue(p, i * 2 - 1), GLASS)
			end
			cheeks(c, 0.48, -0.28, 0.81)
		end,
	}

	-- A wide crab with opal-set claws and a glassy-spotted shell.
	S.rd_t_crab = {
		label = "Gemclaw Crab",
		set = "rainbow_road",
		tint = C3(230, 60, 70),
		scale = 1.15,
		head = CF(0, 0.96, 0),
		neck = CF(0, -0.30, 0.76),
		back = CF(0, 0.40, -0.76),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.90, 1.00, 1.40),
				eyeY = 0.10, eyeSize = V(0.34, 0.40, 0.20), eyeSpread = 0.40,
				mouthY = -0.22, mouthSize = V(0.30, 0.08, 0.10),
				legs = false, tail = false,
			})
			c:box(V(1.60, 0.24, 1.16), CF(0, 0.66, -0.04), p.light)
			for i, x in ipairs({ -0.45, 0.00, 0.45 }) do
				c:box(V(0.26, 0.08, 0.26), CF(x, 0.80, i == 2 and -0.26 or -0.06) * A(0, PI / 4, 0), hue(p, i * 2), GLASS)
			end
			for _, s in ipairs(SIDES) do
				c:rod(V(0.86 * s, -0.10, 0.30), V(1.10 * s, -0.04, 0.56), 0.10, p.dark, nil, false)
				c:box(V(0.60, 0.50, 0.56), CF(1.20 * s, 0.02, 0.72), p.base)
				c:box(V(0.50, 0.18, 0.46), CF(1.22 * s, 0.34, 0.86) * A(0.35, 0, 0), p.light)
				c:box(V(0.20, 0.20, 0.06), CF(1.20 * s, 0.00, 1.01), hue(p, s < 0 and 5 or 3), GLASS)
				for k, z in ipairs({ 0.10, -0.22, -0.52 }) do
					c:rod(V(0.90 * s, -0.24, z), V(1.24 * s, -0.66, z - 0.06 * k), 0.07, p.dark, nil, false)
				end
			end
			cheeks(c, 0.62, -0.16, 0.71)
		end,
	}

	-- A woolly lamb whose fleece puffs are each a soft rainbow hue.
	S.rd_t_lamb = {
		label = "Cloudwool Lamb",
		set = "rainbow_road",
		tint = C3(255, 220, 240),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.40, 1.00),
		back = CF(0, 0.40, -0.96),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				bodySize = V(1.90, 1.60, 1.90),
				bodyColor = p.pale,
				eyeY = 0.16, eyeSize = V(0.34, 0.42, 0.20), eyeSpread = 0.32,
				snout = { w = 0.56, h = 0.36, d = 0.30, y = -0.20, color = p.light, nose = INK },
				legSize = V(0.34, 0.50, 0.34), legX = 0.50, legY = -0.86, legColor = p.dark,
				tail = false,
			})
			c:box(V(1.00, 0.92, 0.08), CF(0, -0.02, 0.97), p.base)
			for i, q in ipairs({ { -0.45, 0.95, 0.30 }, { 0.45, 0.95, 0.10 }, { -0.25, 0.90, -0.45 }, { 0.40, 0.88, -0.60 } }) do
				c:round(V(0.70, 0.46, 0.70), CF(q[1], q[2], q[3]), hue(p, i * 2 - 1))
			end
			for _, s in ipairs(SIDES) do
				c:box(V(0.50, 0.20, 0.30), CF(1.00 * s, 0.40, 0.50) * A(0, 0, -0.45 * s), p.base)
			end
			cheeks(c, 0.44, -0.18, 1.02)
		end,
	}

	-- An inchworm caterpillar, each humped segment a rainbow hue.
	S.rd_t_caterpillar = {
		label = "Arc Caterpillar",
		set = "rainbow_road",
		tint = C3(170, 230, 70),
		scale = 1.20,
		head = CF(0, 0.92, 0),
		neck = CF(0, -0.40, 0.64),
		back = CF(0, 0.86, -1.28),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.20, 1.20, 1.00),
				eyeY = 0.12, eyeSize = V(0.34, 0.40, 0.20), eyeSpread = 0.28,
				mouthY = -0.24, mouthSize = V(0.22, 0.10, 0.10),
				legs = false, tail = false,
			})
			for _, q in ipairs({ { -0.75, -0.02, 1.00, 1 }, { -1.28, 0.22, 0.92, 3 }, { -1.80, 0.04, 0.86, 5 }, { -2.25, -0.16, 0.70, 6 } }) do
				c:box(V(q[3], q[3], 0.62), CF(0, q[2], q[1]), hue(p, q[4]))
			end
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ -0.75, -1.80 }) do
					c:box(V(0.22, 0.20, 0.24), CF(0.36 * s, -0.50, z), p.dark)
				end
				local tip = V(0.34 * s, 1.04, 0.24)
				c:rod(V(0.20 * s, 0.62, 0.10), tip, 0.035, p.deep, nil, false)
				c:ball(V(0.18, 0.18, 0.18), CF(tip), hue(p, s < 0 and 2 or 6), GLASS)
			end
			crystal(c, V(0, 0.66, -1.28), A(0, PI / 4, 0), 0.22, 0.24, hue(p, 7))
			cheeks(c, 0.40, -0.16, 0.51)
		end,
	}

	-- A flamingo on one long leg, rainbow tips on its wings and tail.
	S.rd_t_flamingo = {
		label = "Pastel Flamingo",
		set = "rainbow_road",
		tint = C3(255, 110, 170),
		head = CF(0, 1.02, 0),
		neck = CF(0, -0.50, 0.80),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			block(c, p, {
				shape = "bird",
				bodySize = V(1.50, 1.40, 1.70),
				eyeY = 0.24, eyeSize = V(0.34, 0.40, 0.20), eyeSpread = 0.32,
				mouth = false, legs = false, tail = false,
			})
			c:box(V(0.30, 0.26, 0.36), CF(0, -0.06, 0.98), C3(255, 240, 232))
			c:box(V(0.26, 0.22, 0.22), CF(0, -0.20, 1.18) * A(0.6, 0, 0), INK)
			c:rod(V(0.24, -0.58, 0), V(0.24, -1.56, 0.05), 0.07, p.dark, nil, false)
			c:box(V(0.30, 0.08, 0.40), CF(0.24, -1.58, 0.14), p.dark)
			c:rod(V(-0.24, -0.58, 0), V(-0.30, -1.02, 0.30), 0.07, p.dark, nil, false)
			c:rod(V(-0.30, -1.02, 0.30), V(-0.26, -1.20, -0.06), 0.07, p.dark, nil, false)
			for _, s in ipairs(SIDES) do
				c:box(V(0.20, 0.86, 1.16), CF(0.76 * s, 0.06, -0.12) * A(0.20, 0, 0.08 * s), p.light)
				c:box(V(0.22, 0.22, 0.40), CF(0.78 * s, -0.30, -0.66), hue(p, s < 0 and 6 or 5))
			end
			for k = 1, 3 do
				c:box(V(0.16, 0.12, 0.70), CF(0, 0.26, -0.84) * A(0.40, (k - 2) * 0.40, 0) * CF(0, 0, -0.32), hue(p, k))
			end
			cheeks(c, 0.44, -0.08, 0.86)
		end,
	}

	---------------------------------------------------------------- LEGENDARY

	-- A chameleon with turret eyes, a casque crest, striped flanks and a coiled tail.
	S.rd_t_chameleon = {
		label = "Huecurl Chameleon",
		set = "rainbow_road",
		tint = C3(60, 200, 90),
		scale = 1.10,
		head = CF(0, 1.16, 0.25),
		neck = CF(0, -0.36, 0.96),
		back = CF(0, 0.80, -0.60),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.70, 1.30, 1.90),
				eyeY = 0.14, eyeSize = V(0.40, 0.44, 0.22), eyeSpread = 0.46,
				mouthY = -0.28, mouthSize = V(0.70, 0.08, 0.10),
				legSize = V(0.34, 0.40, 0.40), legX = 0.62, legY = -0.70, legZ = { 0.50, -0.50 }, legColor = p.dark,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				-- A turret socket round each eye, then three stripes down the flank.
				c:box(V(0.56, 0.58, 0.12), CF(0.46 * s, 0.14, 0.93), p.light)
				for k, y in ipairs({ 0.40, 0.08, -0.24 }) do
					c:box(V(0.06, 0.20, 1.50), CF(0.86 * s, y, -0.10), hue(p, k * 2 - 1 + (s < 0 and 0 or 1)))
				end
			end
			c:cone(V(0.30, 0.46, 0.96), CF(0, 0.94, 0.30), p.dark)
			gem(c, V(0, 0.80, -0.40), 0.24, hue(p, 6))
			-- The tail rolls up into a spiral behind.
			local pts = { V(0, 0.20, -0.90), V(0, 0.34, -1.30), V(0, 0.08, -1.62), V(0, -0.26, -1.48), V(0, -0.28, -1.16), V(0, -0.04, -1.20) }
			for i = 1, #pts - 1 do
				c:rod(pts[i], pts[i + 1], 0.15 - 0.018 * i, i % 2 == 1 and p.base or hue(p, i), nil, false)
			end
			c:ball(V(0.16, 0.16, 0.16), CF(pts[#pts]), hue(p, 7), GLASS)
			cheeks(c, 0.56, -0.16, 0.96)
		end,
	}

	-- A hummingbird hovering on blurred raised wings, with a needle beak and a jewel throat.
	S.rd_t_hummingbird = {
		label = "Glint Hummingbird",
		set = "rainbow_road",
		tint = C3(30, 190, 160),
		scale = 1.15,
		head = CF(0, 1.06, 0.10),
		neck = CF(0, -0.46, 0.80),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.40, 1.40, 1.50),
				eyeY = 0.20, eyeSize = V(0.34, 0.40, 0.20), eyeSpread = 0.30,
				mouth = false, legs = false, tail = false,
			})
			c:rod(V(0, 0.00, 0.74), V(0, -0.12, 1.66), 0.05, INK, nil, false)
			c:box(V(0.86, 0.40, 0.08), CF(0, -0.32, 0.77), hue(p, 1))
			c:box(V(0.20, 0.20, 0.06), CF(0, -0.30, 0.82) * A(0, 0, PI / 4), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				local w = CF(0.84 * s, 0.86, -0.10) * A(0, 0, -0.55 * s)
				c:box(V(0.08, 1.20, 0.62), w, p.light).Transparency = 0.15
				c:box(V(0.10, 0.20, 0.64), w * CF(0, 0.38, 0), hue(p, s < 0 and 5 or 6))
				c:box(V(0.10, 0.20, 0.64), w * CF(0, 0.00, 0), hue(p, s < 0 and 3 or 4))
				c:box(V(0.24, 0.10, 0.70), CF(0.14 * s, -0.24, -1.02) * A(0.30, 0.25 * s, 0), hue(p, s < 0 and 7 or 6))
				c:box(V(0.20, 0.14, 0.24), CF(0.24 * s, -0.70, 0.10), p.dark)
			end
			c:cone(V(0.20, 0.36, 0.20), CF(0, 0.92, 0.20) * A(-0.40, 0, 0), hue(p, 3))
			cheeks(c, 0.44, -0.08, 0.76)
		end,
	}

	-- An upright seahorse: tube snout, coronet, rainbow belly rings and a curled tail.
	S.rd_t_seahorse = {
		label = "Opaline Seahorse",
		set = "rainbow_road",
		tint = C3(255, 160, 70),
		scale = 1.10,
		head = CF(0, 1.30, -0.05),
		neck = CF(0, -0.10, 0.72),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.40, 1.70, 1.30),
				eyeY = 0.40, eyeSize = V(0.36, 0.42, 0.20), eyeSpread = 0.32,
				mouth = false, legs = false, tail = false,
			})
			c:box(V(0.34, 0.30, 0.56), CF(0, 0.14, 0.92), p.light)
			c:box(V(0.42, 0.36, 0.10), CF(0, 0.14, 1.22), p.dark)
			for i, x in ipairs({ -0.28, 0, 0.28 }) do
				local h = i == 2 and 0.42 or 0.30
				c:cone(V(0.22, h, 0.22), CF(x, 0.91 + h * 0.5, -0.05), hue(p, i * 2 - 1))
			end
			for k, y in ipairs({ -0.14, -0.36, -0.58 }) do
				c:box(V(1.10 - 0.12 * k, 0.10, 0.06), CF(0, y, 0.67), hue(p, k * 2))
			end
			c:box(V(0.08, 0.66, 0.50), CF(0, -0.20, -0.88), hue(p, 6), GLASS).Transparency = 0.2
			for _, s in ipairs(SIDES) do
				c:box(V(0.06, 0.32, 0.34), CF(0.73 * s, 0.30, 0.10) * A(0, 0.3 * s, 0), p.pale)
			end
			for _, y in ipairs({ 0.78, 0.50, 0.22 }) do
				c:cone(V(0.18, 0.24, 0.18), CF(0, y, -0.72) * A(-PI / 2, 0, 0), p.dark)
			end
			local pts = { V(0, -0.66, -0.20), V(0, -1.06, -0.36), V(0, -1.36, -0.14), V(0, -1.32, 0.18), V(0, -1.08, 0.24), V(0, -0.98, 0.04) }
			for i = 1, #pts - 1 do
				c:rod(pts[i], pts[i + 1], 0.20 - 0.025 * i, i % 2 == 1 and p.base or p.light, nil, false)
			end
			cheeks(c, 0.46, 0.12, 0.66)
		end,
	}

	-- A dragonfly: dome eyes, a rainbow-banded tail and four clear glassy wings.
	S.rd_t_dragonfly = {
		label = "Prism Dragonfly",
		set = "rainbow_road",
		tint = C3(50, 110, 255),
		scale = 1.25,
		head = CF(0, 0.90, 0.10),
		neck = CF(0, -0.40, 0.62),
		back = CF(0, 0.56, -0.80),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.10, 1.00, 1.10),
				eyeY = 0.10, eyeSize = V(0.36, 0.40, 0.20), eyeSpread = 0.26,
				mouthY = -0.28, mouthSize = V(0.20, 0.08, 0.10),
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:round(V(0.46, 0.40, 0.50), CF(0.30 * s, 0.58, 0.18), hue(p, s < 0 and 5 or 6), GLASS)
			end
			c:box(V(0.80, 0.80, 0.56), CF(0, 0.04, -0.80), p.dark)
			for k = 1, 4 do
				local w = 0.38 - 0.04 * k
				c:box(V(w, w, 0.30), CF(0, 0.04, -1.20 - 0.28 * (k - 1)), hue(p, k * 2 - 1))
			end
			gem(c, V(0, 0.04, -2.26), 0.20, p.glow, NEON)
			for _, s in ipairs(SIDES) do
				for k, z in ipairs({ -0.66, -1.00 }) do
					local w = CF(0.80 * s, 0.50, z) * A(0, (k == 1 and -0.22 or 0.22) * s, 0.10 * s)
					c:box(V(1.10, 0.06, 0.38), w, C3(236, 246, 255), GLASS).Transparency = 0.35
					c:box(V(1.00, 0.08, 0.08), w * CF(0.02 * s, 0, 0.08), hue(p, k == 1 and 1 or 3))
				end
				c:rod(V(0.30 * s, -0.36, -0.70), V(0.50 * s, -0.70, -0.60), 0.035, p.deep, nil, false)
			end
			cheeks(c, 0.34, -0.18, 0.56)
		end,
	}

	-- A chunky whale whose blowhole sprays an arch of rainbow droplets.
	S.rd_t_whale = {
		label = "Rainspout Whale",
		set = "rainbow_road",
		tint = C3(60, 100, 200),
		scale = 1.20,
		head = CF(0, 1.66, 0.30),
		neck = CF(0, -0.40, 1.06),
		back = CF(0, 0.80, -0.60),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.90, 1.40, 2.10),
				eyeY = 0.04, eyeSize = V(0.32, 0.38, 0.20), eyeSpread = 0.56,
				mouthY = -0.30, mouthSize = V(1.10, 0.08, 0.12),
				bib = { w = 1.50, h = 0.36, y = -0.46, color = p.pale },
				legs = false, tail = false,
			})
			c:box(V(0.60, 0.50, 0.60), CF(0, 0.12, -1.30), p.base)
			for _, s in ipairs(SIDES) do
				c:box(V(0.74, 0.12, 0.44), CF(0.34 * s, 0.30, -1.66) * A(0.35, 0, 0.22 * s), p.dark)
				c:box(V(0.64, 0.12, 0.36), CF(1.10 * s, -0.34, 0.30) * A(0, 0.30 * s, -0.50 * s), p.dark)
			end
			c:box(V(0.22, 0.36, 0.22), CF(0, 0.94, 0.30), C3(220, 240, 255), GLASS).Transparency = 0.2
			for i = 1, 7 do
				local a = (i - 4) * 0.36
				c:ball(V(0.22, 0.22, 0.22), CF(0.70 * math.sin(a), 0.96 + 0.56 * math.cos(a), 0.30), hue(p, i), GLASS)
			end
			cheeks(c, 0.70, -0.26, 1.06)
		end,
	}

	-- A hot-air balloon with a face, rainbow gores and a little wicker basket.
	S.rd_t_balloon = {
		label = "Skyhue Balloon",
		set = "rainbow_road",
		tint = C3(255, 90, 120),
		head = CF(0, 1.06, 0),
		neck = CF(0, -1.36, 0.36),
		back = CF(0, 0.20, -0.96),
		build = function(c, p)
			block(c, p, {
				shape = "round",
				bodySize = V(1.90, 1.80, 1.80),
				eyeY = 0.20, eyeSize = V(0.40, 0.48, 0.22), eyeSpread = 0.40,
				mouthY = -0.18, mouthSize = V(0.30, 0.12, 0.12),
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				for k, z in ipairs({ 0.30, -0.30 }) do
					c:box(V(0.06, 1.00, 0.40), CF(1.01 * s, 0.06, z), hue(p, s < 0 and k or k + 4))
				end
			end
			for k, x in ipairs({ -0.40, 0, 0.40 }) do
				c:box(V(0.40, 0.06, 1.20), CF(x, 0.94, 0), hue(p, k + 2))
			end
			c:box(V(1.00, 0.24, 0.90), CF(0, -0.94, 0), p.dark)
			local ROPE, WICKER = C3(150, 110, 70), C3(196, 150, 100)
			for _, x in ipairs(SIDES) do
				for _, z in ipairs(SIDES) do
					c:rod(V(0.40 * x, -1.00, 0.36 * z), V(0.26 * x, -1.42, 0.22 * z), 0.025, ROPE, nil, false)
				end
			end
			c:box(V(0.66, 0.40, 0.58), CF(0, -1.62, 0), WICKER, WOOD)
			c:box(V(0.74, 0.08, 0.66), CF(0, -1.42, 0), C3(150, 104, 60), WOOD)
			c:box(V(0.14, 0.22, 0.14), CF(0, -1.22, 0), C3(255, 190, 70), NEON)
			for _, s in ipairs(SIDES) do
				c:box(V(0.16, 0.20, 0.16), CF(0.42 * s, -1.60, 0.10), C3(214, 190, 150))
			end
			cheeks(c, 0.50, -0.08, 0.90)
		end,
	}

	-- A paint pot with a face, rainbow paint swirled on top and dripping down the sides.
	S.rd_t_paintpot = {
		label = "Drippy Paintpot",
		set = "rainbow_road",
		tint = C3(250, 220, 60),
		head = CF(0, 1.10, -0.10),
		neck = CF(0, -0.40, 0.90),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			block(c, p, {
				square = true,
				bodySize = V(1.70, 1.60, 1.70),
				eyeY = 0.10, eyeSize = V(0.40, 0.48, 0.22), eyeSpread = 0.36,
				mouthY = -0.28, mouthSize = V(0.36, 0.14, 0.12),
				legs = false, tail = false,
			})
			c:box(V(1.84, 0.16, 1.84), CF(0, 0.86, 0), p.light)
			c:box(V(1.56, 0.06, 1.56), CF(0, 0.95, 0), hue(p, 5))
			c:box(V(1.00, 0.06, 1.00), CF(0, 0.98, 0) * A(0, PI / 4, 0), hue(p, 1))
			c:box(V(0.46, 0.06, 0.46), CF(0, 1.01, 0), hue(p, 3))
			-- Drips: { x, z, length, hue, on the front? }
			local drips = {
				{ 0.70, 0.86, 0.36, 2, true }, { -0.70, 0.86, 0.56, 6, true },
				{ 0.86, 0.30, 0.70, 3, false }, { 0.86, -0.40, 0.40, 7, false },
				{ -0.86, 0.20, 0.50, 4, false }, { -0.86, -0.45, 0.80, 1, false },
			}
			for _, d in ipairs(drips) do
				local x, z, len = d[1], d[2], d[3]
				local col = hue(p, d[4])
				c:box(d[5] and V(0.20, len, 0.06) or V(0.06, len, 0.20), CF(x, 0.80 - len * 0.5, z), col)
				c:round(V(0.24, 0.24, 0.24), CF(x, 0.80 - len, z), col)
			end
			local HANDLE = C3(176, 184, 196)
			c:rod(V(-0.92, 0.50, 0), V(-0.62, 1.40, 0), 0.04, HANDLE, METAL, false)
			c:rod(V(-0.62, 1.40, 0), V(0.62, 1.40, 0), 0.04, HANDLE, METAL, false)
			c:rod(V(0.62, 1.40, 0), V(0.92, 0.50, 0), 0.04, HANDLE, METAL, false)
			c:rod(V(0.30, 0.90, -0.30), V(0.62, 1.66, -0.50), 0.06, C3(196, 150, 100), WOOD, false)
			c:box(V(0.20, 0.30, 0.16), CF(0.68, 1.80, -0.54) * A(-0.25, 0, -0.40), hue(p, 6))
			cheeks(c, 0.50, -0.14, 0.86)
		end,
	}

	-- A jewel beetle: a split shell with a rainbow sheen, a crystal horn and six legs.
	S.rd_t_beetle = {
		label = "Opalback Beetle",
		set = "rainbow_road",
		tint = C3(30, 170, 110),
		head = CF(0, 1.06, 0.20),
		neck = CF(0, -0.30, 1.04),
		back = CF(0, 1.00, -0.40),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.80, 1.20, 2.00),
				eyeY = 0.04, eyeSize = V(0.34, 0.40, 0.20), eyeSpread = 0.42,
				mouthY = -0.30, mouthSize = V(0.30, 0.08, 0.10),
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V(0.88, 0.30, 1.70), CF(0.45 * s, 0.80, -0.20), p.dark).Reflectance = 0.25
				for k, z in ipairs({ 0.20, -0.30, -0.80 }) do
					c:box(V(0.70, 0.04, 0.18), CF(0.45 * s, 0.97, z), hue(p, s < 0 and k * 2 - 1 or k * 2))
				end
				for _, z in ipairs({ 0.50, 0.00, -0.50 }) do
					c:rod(V(0.86 * s, -0.30, z), V(1.20 * s, -0.86, z + 0.10), 0.06, p.deep, nil, false)
				end
				local tip = V(0.46 * s, 0.86, 1.30)
				c:rod(V(0.22 * s, 0.40, 1.00), tip, 0.035, p.deep, nil, false)
				c:ball(V(0.16, 0.16, 0.16), CF(tip), hue(p, s < 0 and 5 or 2), GLASS)
			end
			c:box(V(0.06, 0.32, 1.72), CF(0, 0.80, -0.20), GOLD, METAL)
			c:cone(V(0.30, 0.70, 0.30), CF(0, 0.86, 0.84) * A(0.50, 0, 0), hue(p, 3), GLASS)
			cheeks(c, 0.58, -0.20, 1.01)
		end,
	}

	-- A mantis shrimp: boxing-glove clubs, stalk eyes and rainbow plates over its back.
	S.rd_t_shrimp = {
		label = "Spectrum Shrimp",
		set = "rainbow_road",
		tint = C3(255, 80, 110),
		head = CF(0, 1.30, 0.20),
		neck = CF(0, -0.50, 0.90),
		back = CF(0, 0.80, -0.80),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.40, 1.40, 1.40),
				eyeY = 0.10, eyeSize = V(0.34, 0.40, 0.20), eyeSpread = 0.30,
				mouthY = -0.26, mouthSize = V(0.26, 0.10, 0.10),
				legs = false, tail = false,
			})
			for i = 0, 3 do
				c:box(V(1.46 - 0.10 * i, 0.16, 0.44), CF(0, 0.80 - 0.10 * i, 0.36 - 0.40 * i) * A(-0.12 * i, 0, 0), hue(p, i * 2 + 1))
			end
			for k = 1, 3 do
				c:box(V(0.30, 0.10, 0.62), CF(0, -0.30, -0.80) * A(0.25, (k - 2) * 0.50, 0) * CF(0, 0, -0.28), hue(p, k + 4))
			end
			for _, s in ipairs(SIDES) do
				c:rod(V(0.56 * s, -0.36, 0.56), V(0.74 * s, -0.24, 0.98), 0.10, p.dark, nil, false)
				c:box(V(0.38, 0.38, 0.38), CF(0.76 * s, -0.20, 1.10), hue(p, s < 0 and 2 or 6))
				local tip = V(0.36 * s, 1.16, 0.44)
				c:rod(V(0.22 * s, 0.70, 0.40), tip, 0.06, p.dark, nil, false)
				c:ball(V(0.26, 0.22, 0.26), CF(tip), hue(p, s < 0 and 5 or 4), GLASS)
				c:rod(V(0.12 * s, 0.50, 0.70), V(0.70 * s, 1.20, 0.96), 0.025, p.light, nil, false)
				for _, z in ipairs({ 0.20, -0.30 }) do
					c:rod(V(0.40 * s, -0.60, z), V(0.52 * s, -0.94, z), 0.05, p.deep, nil, false)
				end
			end
			cheeks(c, 0.44, -0.16, 0.71)
		end,
	}

	-- A frilly sea slug: low and soft, with horn rhinophores and jewel-tipped papillae.
	S.rd_t_seaslug = {
		label = "Frilly Seaslug",
		set = "rainbow_road",
		tint = C3(170, 80, 255),
		head = CF(0, 1.06, 0.30),
		neck = CF(0, -0.30, 1.06),
		back = CF(0, 0.70, -1.00),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.50, 0.90, 2.00),
				eyeY = 0.00, eyeSize = V(0.32, 0.38, 0.20), eyeSpread = 0.30,
				mouthY = -0.24, mouthSize = V(0.30, 0.08, 0.10),
				legs = false, tail = false,
			})
			c:box(V(1.96, 0.14, 2.34), CF(0, -0.40, -0.12), p.light)
			for _, s in ipairs(SIDES) do
				c:box(V(0.10, 0.20, 2.10), CF(0.98 * s, -0.30, -0.12), hue(p, s < 0 and 6 or 2))
				c:box(V(0.16, 0.48, 0.16), CF(0.30 * s, 0.74, 0.62) * A(0.15, 0, -0.20 * s), p.dark)
				c:ball(V(0.20, 0.20, 0.20), CF(0.36 * s, 1.00, 0.66), hue(p, s < 0 and 7 or 5), GLASS)
				for k, z in ipairs({ 0.10, -0.38, -0.86 }) do
					local tip = V(0.66 * s, 0.98 - 0.06 * k, z - 0.08)
					c:rod(V(0.40 * s, 0.50, z), tip, 0.08, p.light, nil, false)
					c:ball(V(0.22, 0.22, 0.22), CF(tip), hue(p, s < 0 and k * 2 - 1 or k * 2), GLASS)
				end
			end
			c:box(V(0.66, 0.10, 0.50), CF(0, -0.30, -1.36), p.light)
			cheeks(c, 0.48, -0.14, 1.01)
		end,
	}

	-- An elephant with a stepped cube trunk, wide ears, crystal tusks and a layered saddle.
	S.rd_t_elephant = {
		label = "Gemtusk Elephant",
		set = "rainbow_road",
		tint = C3(140, 150, 230),
		scale = 1.10,
		head = CF(0, 1.50, -0.20),
		neck = CF(0, -0.50, 1.10),
		back = CF(0, 0.70, -1.00),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.90, 1.70, 1.90),
				eyeY = 0.26, eyeSize = V(0.32, 0.38, 0.20), eyeSpread = 0.40,
				mouth = false,
				legSize = V(0.46, 0.50, 0.46), legX = 0.56, legY = -0.84,
				tailSize = V(0.14, 0.40, 0.14),
			})
			c:box(V(0.40, 0.40, 0.30), CF(0, -0.06, 1.06), p.base)
			c:box(V(0.34, 0.36, 0.30), CF(0, -0.38, 1.16), p.base)
			c:box(V(0.30, 0.32, 0.28), CF(0, -0.66, 1.24), p.base)
			c:box(V(0.32, 0.18, 0.30), CF(0, -0.84, 1.32), p.light)
			for _, s in ipairs(SIDES) do
				local ear = CF(1.02 * s, 0.34, 0.36) * A(0, -1.0 * s, 0)
				c:box(V(0.10, 1.00, 0.86), ear, p.base)
				c:box(V(0.06, 0.70, 0.60), ear * CF(0.06 * s, 0, 0), hue(p, 7))
				c:cone(V(0.14, 0.50, 0.14), CF(0.28 * s, -0.40, 1.14) * A(PI / 2 - 0.5, 0, 0), hue(p, s < 0 and 5 or 3), GLASS)
			end
			c:box(V(1.40, 0.08, 1.10), CF(0, 0.95, -0.20), hue(p, 1))
			c:box(V(1.14, 0.08, 0.86), CF(0, 1.03, -0.20), hue(p, 3))
			c:box(V(0.88, 0.08, 0.62), CF(0, 1.11, -0.20), hue(p, 5))
			crystal(c, V(0, 1.15, -0.20), A(0, PI / 4, 0), 0.24, 0.30, hue(p, 6))
			cheeks(c, 0.50, -0.02, 0.96)
		end,
	}

	-- A sloth hanging by both arms from a floating rainbow bar, a cloud at each end.
	S.rd_t_sloth = {
		label = "Archhang Sloth",
		set = "rainbow_road",
		tint = C3(200, 150, 255),
		scale = 1.20,
		head = CF(0, 0.92, 0.05),
		neck = CF(0, -0.40, 0.66),
		back = CF(0, 0.20, -0.66),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.40, 1.50, 1.20),
				eyeY = 0.12, eyeSize = V(0.30, 0.36, 0.20), eyeSpread = 0.30,
				mouthY = -0.22, mouthSize = V(0.24, 0.08, 0.10),
				legSize = V(0.30, 0.50, 0.30), legX = 0.40, legY = -0.86, legZ = { 0.10 }, legColor = p.dark,
				tail = false,
			})
			c:box(V(1.04, 0.80, 0.04), CF(0, -0.02, 0.61), p.pale)
			for _, s in ipairs(SIDES) do
				c:box(V(0.46, 0.26, 0.06), CF(0.30 * s, 0.10, 0.63) * A(0, 0, 0.35 * s), p.dark)
				c:rod(V(0.56 * s, 0.50, 0), V(0.50 * s, 1.30, 0), 0.14, p.base, nil, false)
				c:round(V(0.30, 0.30, 0.34), CF(0.50 * s, 1.40, 0), p.dark)
				c:round(V(0.56, 0.44, 0.46), CF(1.20 * s, 1.40, 0), CLOUD)
			end
			for i = 1, 5 do
				c:box(V(0.42, 0.20, 0.22), CF(-0.84 + 0.42 * (i - 1), 1.40, 0), hue(p, i))
			end
			gem(c, V(-0.25, 1.60, 0), 0.18, hue(p, 6))
			cheeks(c, 0.40, -0.14, 0.65)
		end,
	}

	---------------------------------------------------------------- MYTHIC

	-- A griffin: eagle beak and swept crest, lion body, raised wings tipped in rainbow.
	S.rd_t_griffin = {
		label = "Huecrest Griffin",
		set = "rainbow_road",
		tint = C3(255, 196, 50),
		scale = 1.15,
		head = CF(0, 1.30, 0.20),
		neck = CF(0, -0.40, 1.04),
		back = CF(0, 0.96, -0.40),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				bodySize = V(1.80, 1.70, 1.90),
				eyeY = 0.28, eyeSize = V(0.34, 0.42, 0.20), eyeSpread = 0.38,
				mouth = false, legColor = p.dark, tail = false,
			})
			local BEAK = C3(255, 186, 70)
			c:box(V(0.42, 0.28, 0.34), CF(0, -0.04, 1.08), BEAK)
			c:cone(V(0.30, 0.24, 0.22), CF(0, -0.24, 1.18) * A(PI, 0, 0), BEAK)
			for i = 1, 3 do
				c:box(V(0.14, 0.56, 0.14), CF(0, 0.86, 0.40) * A(-0.70, 0, (i - 2) * 0.35) * CF(0, 0.26, 0), hue(p, i * 2 - 1))
			end
			for _, s in ipairs(SIDES) do
				local w = CF(0.98 * s, 0.82, -0.30) * A(0, 0, -0.50 * s)
				c:box(V(0.14, 1.00, 1.10), w, p.light)
				for k = 1, 3 do
					c:box(V(0.12, 0.56, 0.26), w * CF(0, 0.70, 0.40 - 0.36 * (k - 1)), hue(p, s < 0 and k or k + 3))
				end
			end
			c:rod(V(0, 0.30, -0.90), V(0, 0.76, -1.36), 0.08, p.base, nil, false)
			c:round(V(0.36, 0.36, 0.36), CF(0, 0.84, -1.42), hue(p, 6))
			gem(c, V(0, -0.50, 0.98), 0.22, p.glow, NEON)
			c:star(V(-0.80, 1.60, 0.30), 0.32, p.glow)
			c:star(V(0.86, 1.70, -0.20), 0.26, p.glow)
			cheeks(c, 0.52, 0.02, 0.97)
		end,
	}

	-- A lion whose mane is a ring of rainbow crystal shards, under a floating gold crown.
	S.rd_t_lion = {
		label = "Crystalmane Lion",
		set = "rainbow_road",
		tint = C3(255, 150, 40),
		scale = 1.10,
		head = CF(0, 1.66, 0.10),
		neck = CF(0, -0.50, 1.04),
		back = CF(0, 0.90, -0.50),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				bodySize = V(1.80, 1.60, 1.90),
				eyeY = 0.20, eyeSize = V(0.34, 0.42, 0.20), eyeSpread = 0.36,
				snout = { w = 0.56, h = 0.34, d = 0.30, y = -0.20, color = p.pale, nose = INK },
				legColor = p.dark, tail = false,
			})
			for i = 1, 8 do
				local a = (i - 0.5) * PI / 4
				c:box(
					V(0.34, 0.56, 0.30),
					CF(0.92 * math.cos(a), 0.10 + 0.86 * math.sin(a), 0.80) * A(0, 0, a - PI / 2),
					hue(p, i),
					GLASS
				).Reflectance = 0.15
			end
			K.ears(c, p.dark, "round")
			c:rod(V(0, 0.20, -0.92), V(0, 0.70, -1.30), 0.07, p.base, nil, false)
			gem(c, V(0, 0.80, -1.36), 0.30, hue(p, 6))
			-- A crown floating over the head.
			c:box(V(0.80, 0.12, 0.56), CF(0, 1.34, 0.10), GOLD, METAL)
			for i, x in ipairs({ -0.28, 0, 0.28 }) do
				local mid = i == 2
				gem(c, V(x, 1.50 + (mid and 0.06 or 0), 0.10), 0.18, mid and p.glow or GOLD, mid and NEON or METAL)
			end
			c:light(p.glow, 0.6, 6)
			cheeks(c, 0.50, -0.06, 0.97)
		end,
	}

	-- A floating lantern: gold frame, rainbow glass panes, beams of light below.
	S.rd_t_lantern = {
		label = "Prism Lantern",
		set = "rainbow_road",
		tint = C3(110, 220, 255),
		scale = 1.25,
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				square = true,
				bodySize = V(1.40, 1.50, 1.40),
				bodyColor = p.pale,
				eyeY = 0.12, eyeSize = V(0.36, 0.42, 0.20), eyeSpread = 0.30,
				mouthY = -0.24, mouthSize = V(0.24, 0.10, 0.10),
				legs = false, tail = false,
			})
			for _, x in ipairs(SIDES) do
				for _, z in ipairs(SIDES) do
					c:box(V(0.16, 1.62, 0.16), CF(0.70 * x, 0.06, 0.70 * z), GOLD, METAL)
				end
			end
			c:box(V(1.66, 0.16, 1.66), CF(0, 0.88, 0), GOLD, METAL)
			c:box(V(1.66, 0.16, 1.66), CF(0, -0.76, 0), GOLD, METAL)
			c:cone(V(1.36, 0.50, 1.36), CF(0, 1.21, 0), p.dark)
			c:ball(V(0.24, 0.24, 0.24), CF(0, 1.54, 0), GOLD, METAL)
			c:cone(V(0.56, 0.36, 0.56), CF(0, -1.02, 0) * A(PI, 0, 0), GOLD, METAL)
			for i, cf in ipairs({ CF(0.72, 0.06, 0), CF(-0.72, 0.06, 0), CF(0, 0.06, -0.72) * A(0, PI / 2, 0) }) do
				c:box(V(0.06, 1.20, 1.06), cf, hue(p, i * 2 - 1), GLASS).Transparency = 0.25
			end
			for i, x in ipairs({ -0.30, 0, 0.30 }) do
				c:box(V(0.08, 0.44, 0.08), CF(x * 1.6, -1.36, 0) * A(0, 0, -x), hue(p, i * 2), NEON)
			end
			for i, q in ipairs({ { 1.20, 0.30, 0.30 }, { -1.20, 0.50, -0.20 }, { 0.10, 0.80, -1.10 } }) do
				gem(c, V(q[1], q[2], q[3]), 0.22, hue(p, i + 4))
			end
			c:light(p.glow, 0.8, 8)
			cheeks(c, 0.40, -0.14, 0.71)
		end,
	}

	-- A baby peeking out of a cracked geode egg lined with rainbow crystals.
	S.rd_t_hatchling = {
		label = "Geode Hatchling",
		set = "rainbow_road",
		tint = C3(180, 100, 255),
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.30, 0.98),
		back = CF(0, 0.20, -0.98),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.40, 1.30, 1.30),
				eyeY = 0.30, eyeSize = V(0.36, 0.42, 0.20), eyeSpread = 0.30,
				mouthY = 0.02, mouthSize = V(0.22, 0.10, 0.10),
				legs = false, tail = false,
			})
			-- The bottom half of the egg, with a jagged rim and a glowing lining.
			c:box(V(1.90, 0.80, 1.80), CF(0, -0.56, 0), p.deep)
			for _, q in ipairs({ { 0.74, 0.68 }, { -0.74, 0.68 }, { 0.80, -0.50 }, { -0.80, -0.50 } }) do
				c:cone(V(0.34, 0.36, 0.30), CF(q[1], 0.02, q[2]), p.deep)
			end
			c:box(V(1.80, 0.04, 1.70), CF(0, -0.15, 0), p.glow, NEON)
			crystal(c, V(-0.62, -0.16, -0.50), A(-0.2, 0, 0.3), 0.22, 0.40, hue(p, 1))
			crystal(c, V(0.62, -0.16, -0.50), A(-0.2, 0, -0.3), 0.22, 0.44, hue(p, 3))
			crystal(c, V(0, -0.16, -0.72), A(-0.3, 0, 0), 0.24, 0.50, hue(p, 5))
			-- A bit of shell still on its head.
			c:box(V(0.80, 0.14, 0.74), CF(0, 0.78, 0), p.deep)
			c:cone(V(0.40, 0.30, 0.40), CF(0, 1.00, 0), p.deep)
			for _, s in ipairs(SIDES) do
				c:round(V(0.30, 0.22, 0.30), CF(0.48 * s, -0.12, 0.80), p.base)
			end
			c:star(V(-1.00, 0.90, 0.30), 0.30, p.glow)
			c:star(V(1.05, 0.60, -0.20), 0.24, p.glow)
			cheeks(c, 0.42, 0.06, 0.66)
		end,
	}

	-- A quetzal with a helmet crest and a long trailing rainbow train.
	S.rd_t_quetzal = {
		label = "Huetrain Quetzal",
		set = "rainbow_road",
		tint = C3(30, 200, 110),
		scale = 1.25,
		head = CF(0, 1.26, -0.10),
		neck = CF(0, -0.40, 0.82),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "bird",
				bodySize = V(1.50, 1.70, 1.50),
				eyeY = 0.26, eyeSize = V(0.34, 0.42, 0.20), eyeSpread = 0.32,
				mouth = false,
				bib = { w = 1.00, h = 0.70, y = -0.40, color = hue(p, 1) },
				legSize = V(0.26, 0.20, 0.30), legZ = { 0.15 }, legY = -0.88, legColor = GOLD,
				tail = false,
			})
			c:cone(V(0.24, 0.30, 0.22), CF(0, 0.00, 0.86) * A(PI / 2, 0, 0), GOLD)
			c:box(V(0.22, 0.34, 1.10), CF(0, 1.00, 0.00) * A(-0.15, 0, 0), p.light)
			c:box(V(0.14, 0.14, 0.14), CF(0, 1.18, 0.52), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V(0.16, 0.96, 1.10), CF(0.80 * s, 0.00, -0.10) * A(0, 0, 0.10 * s), p.dark)
				c:box(V(0.18, 0.24, 1.00), CF(0.82 * s, 0.30, -0.10) * A(0, 0, 0.10 * s), hue(p, s < 0 and 4 or 5))
			end
			-- Five long train feathers, each curling up at the end.
			for k = 1, 5 do
				local root = CF(0, -0.40, -0.72) * A(-0.35, (k - 3) * 0.14, 0)
				c:box(V(0.14, 0.06, 1.10), root * CF(0, 0, -0.55), hue(p, k + 1))
				c:box(V(0.16, 0.06, 0.44), root * CF(0, 0, -1.10) * A(0.60, 0, 0) * CF(0, 0, -0.20), hue(p, k + 1))
			end
			c:star(V(0.80, 1.40, 0.20), 0.30, p.glow)
			cheeks(c, 0.42, -0.02, 0.76)
		end,
	}

	-- A toadstool: a stout face-stem under a tiered cap studded with crystal gems.
	S.rd_t_toadstool = {
		label = "Prism Toadstool",
		set = "rainbow_road",
		tint = C3(240, 60, 80),
		scale = 1.10,
		head = CF(0, 1.90, 0),
		neck = CF(0, -0.30, 0.72),
		back = CF(0, 0.20, -0.72),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.30, 1.40, 1.30),
				bodyColor = p.pale,
				eyeY = 0.10, eyeSize = V(0.34, 0.42, 0.20), eyeSpread = 0.28,
				mouthY = -0.24, mouthSize = V(0.24, 0.10, 0.10),
				legSize = V(0.36, 0.20, 0.44), legX = 0.32, legY = -0.70, legZ = { 0.15 }, legColor = p.light,
				tail = false,
			})
			c:box(V(2.10, 0.06, 1.90), CF(0, 0.79, 0), p.light)
			c:box(V(2.30, 0.46, 2.10), CF(0, 1.05, 0), p.base)
			c:box(V(1.70, 0.34, 1.50), CF(0, 1.45, 0), p.base)
			c:box(V(1.00, 0.24, 0.90), CF(0, 1.72, 0), p.base)
			local spots = {
				{ V(-0.60, 1.06, 1.06), 1 }, { V(0.62, 1.04, 1.06), 3 }, { V(0.00, 1.46, 0.76), 5 },
				{ V(1.16, 1.04, -0.30), 6 }, { V(-1.16, 1.04, -0.30), 2 }, { V(0.30, 1.86, 0.00), 7 },
			}
			for _, sp in ipairs(spots) do
				gem(c, sp[1], 0.26, hue(p, sp[2]))
			end
			for _, s in ipairs(SIDES) do
				c:round(V(0.30, 0.40, 0.30), CF(0.72 * s, -0.10, 0.20), p.pale)
			end
			for _, q in ipairs({ { -1.10, 0.20, 0.40 }, { 1.06, 0.40, 0.20 }, { -0.80, -0.50, 0.60 } }) do
				c:ball(V(0.16, 0.16, 0.16), CF(q[1], q[2], q[3]), p.glow, NEON)
			end
			c:light(p.glow, 0.6, 6)
			cheeks(c, 0.38, -0.14, 0.66)
		end,
	}

	-- A pinwheel on a stick: a face in the hub, eight rainbow blades, a cloud to stand on.
	S.rd_t_pinwheel = {
		label = "Prism Pinwheel",
		set = "rainbow_road",
		tint = C3(255, 110, 200),
		scale = 1.20,
		head = CF(0, 1.16, 0),
		neck = CF(0, 0.10, 0.36),
		back = CF(0, 0.40, -0.40),
		build = function(c, p)
			local hub = CF(0, 0.50, 0)
			c:box(V(0.96, 0.96, 0.60), hub, p.base)
			c:eyes(0.60, 0.32, 0.20, 0.13)
			c:box(V(0.24, 0.08, 0.06), CF(0, 0.30, 0.31), INK)
			cheeks(c, 0.34, 0.38, 0.31)
			gem(c, V(0, 1.04, 0), 0.16, p.glow, NEON)
			for k = 1, 8 do
				local big = k % 2 == 1
				c:box(
					big and V(0.62, 0.62, 0.08) or V(0.44, 0.44, 0.08),
					hub * A(0, 0, (k - 1) * PI / 4) * CF(0, big and 0.82 or 0.70, -0.12) * A(0, 0.40, PI / 4),
					hue(p, k)
				)
			end
			c:box(V(0.14, 1.20, 0.14), CF(0, -0.46, -0.16), C3(196, 150, 100), WOOD)
			c:box(V(0.30, 0.10, 0.20), CF(0.14, -0.50, -0.16) * A(0, 0, 0.5), C3(110, 200, 110))
			c:round(V(1.00, 0.40, 0.80), CF(0, -1.12, -0.10), CLOUD)
			c:round(V(0.60, 0.34, 0.60), CF(0.50, -1.00, 0.10), CLOUD)
			c:star(V(-1.00, 1.20, 0.10), 0.30, p.glow)
			c:star(V(1.10, -0.30, 0.10), 0.24, p.glow)
			c:light(p.glow, 0.6, 6)
		end,
	}

	-- A penguin on a crystal ice floe, in a rainbow scarf and a bobble hat.
	S.rd_t_penguin = {
		label = "Iceprism Penguin",
		set = "rainbow_road",
		tint = C3(50, 70, 190),
		scale = 1.10,
		head = CF(0, 1.62, 0),
		neck = CF(0, -0.10, 0.86),
		back = CF(0, 0.20, -0.84),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.60, 1.90, 1.50),
				eyeY = 0.42, eyeSize = V(0.32, 0.38, 0.20), eyeSpread = 0.30,
				mouth = false,
				bib = { w = 1.16, h = 1.10, y = -0.30, color = CLOUD },
				legSize = V(0.40, 0.16, 0.50), legX = 0.36, legY = -0.96, legZ = { 0.20 }, legColor = GOLD,
				tail = false,
			})
			c:cone(V(0.26, 0.30, 0.24), CF(0, 0.16, 0.86) * A(PI / 2, 0, 0), GOLD)
			c:box(V(1.66, 0.22, 1.56), CF(0, -0.10, 0), hue(p, 1))
			c:box(V(0.26, 0.56, 0.08), CF(0.42, -0.44, 0.80), hue(p, 1))
			c:box(V(0.28, 0.10, 0.10), CF(0.42, -0.38, 0.80), hue(p, 3))
			c:box(V(0.28, 0.10, 0.10), CF(0.42, -0.60, 0.80), hue(p, 5))
			for _, s in ipairs(SIDES) do
				c:box(V(0.14, 0.96, 0.50), CF(0.86 * s, -0.20, 0) * A(0, 0, 0.30 * s), p.dark)
			end
			c:box(V(1.10, 0.30, 1.00), CF(0, 1.16, 0), hue(p, 5))
			c:box(V(1.16, 0.10, 1.06), CF(0, 1.04, 0), hue(p, 6))
			c:round(V(0.36, 0.36, 0.36), CF(0, 1.42, 0), CLOUD)
			c:box(V(2.10, 0.22, 1.80), CF(0, -1.16, 0), C3(214, 238, 255), GLASS).Transparency = 0.15
			crystal(c, V(-0.86, -1.05, 0.50), A(0.2, 0, 0.3), 0.20, 0.36, hue(p, 4))
			crystal(c, V(0.88, -1.05, -0.40), A(-0.2, 0, -0.3), 0.24, 0.46, hue(p, 6))
			crystal(c, V(-0.60, -1.05, -0.70), A(-0.3, 0, 0.1), 0.18, 0.30, hue(p, 2))
			c:star(V(0.96, 1.30, 0.20), 0.32, p.glow)
			cheeks(c, 0.42, 0.14, 0.76)
		end,
	}

	-- A round bat with tall ears and scalloped rainbow wings spread wide.
	S.rd_t_bat = {
		label = "Duskhue Bat",
		set = "rainbow_road",
		tint = C3(120, 50, 190),
		scale = 1.30,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "round",
				bodySize = V(1.40, 1.40, 1.30),
				eyeY = 0.12, eyeSize = V(0.36, 0.42, 0.20), eyeSpread = 0.28,
				mouthY = -0.22, mouthSize = V(0.24, 0.08, 0.10),
				legSize = V(0.22, 0.20, 0.24), legX = 0.30, legY = -0.70, legZ = { 0.10 }, legColor = p.dark,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(V(0.40, 0.60, 0.24), CF(0.36 * s, 0.98, 0) * A(0, 0, -0.25 * s), p.base)
				c:box(V(0.16, 0.30, 0.06), CF(0.37 * s, 0.92, 0.13) * A(0, 0, -0.25 * s), hue(p, s < 0 and 7 or 1))
				-- The wing: an arm bone, with three panels hanging under it.
				c:rod(V(0.60 * s, 0.30, -0.10), V(1.56 * s, 0.70, -0.20), 0.05, p.dark, nil, false)
				for k = 1, 3 do
					local x = 0.60 + 0.30 * k
					local h = 0.70 - 0.08 * k
					local top = 0.30 + (x - 0.60) * 0.4167
					c:box(V(0.32, h, 0.06), CF(x * s, top - h * 0.5, -0.20) * A(0, 0, 0.10 * s), hue(p, s < 0 and k or k + 3))
				end
				c:cone(V(0.08, 0.10, 0.06), CF(0.08 * s, -0.31, 0.68) * A(PI, 0, 0), WHITE)
			end
			gem(c, V(0, 1.30, -0.30), 0.30, p.glow, NEON)
			c:star(V(-0.70, 1.40, 0.20), 0.26, p.glow)
			cheeks(c, 0.40, -0.14, 0.68)
		end,
	}

	-- A sitting panda nibbling a stalk of crystal bamboo, gems circling its head.
	S.rd_t_panda = {
		label = "Gemboo Panda",
		set = "rainbow_road",
		tint = C3(255, 150, 200),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.36, 0.90),
		back = CF(0, 0.30, -0.86),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.80, 1.80, 1.60),
				bodyColor = p.pale,
				eyeY = 0.18, eyeSize = V(0.30, 0.36, 0.20), eyeSpread = 0.36,
				snout = { w = 0.50, h = 0.30, d = 0.24, y = -0.16, color = WHITE, nose = INK },
				legSize = V(0.50, 0.40, 0.56), legX = 0.50, legY = -0.80, legZ = { 0.50, -0.30 }, legColor = p.deep,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V(0.44, 0.54, 0.06), CF(0.36 * s, 0.16, 0.81) * A(0, 0, 0.35 * s), p.deep)
				c:box(V(0.48, 0.44, 0.30), CF(0.62 * s, 1.08, 0), p.deep)
				c:round(V(0.40, 0.70, 0.44), CF(0.86 * s, -0.10, 0.44) * A(0, 0, 0.30 * s), p.deep)
			end
			-- Crystal bamboo: three glass segments, two nodes, a leaf and a crystal tip.
			for k = 0, 2 do
				c:box(V(0.18, 0.50, 0.18), CF(0.72 + 0.06 * k, -0.20 + 0.52 * k, 0.92) * A(0, 0, -0.12), hue(p, k * 2 + 1), GLASS)
				if k < 2 then
					c:box(V(0.24, 0.06, 0.24), CF(0.75 + 0.06 * k, 0.06 + 0.52 * k, 0.92) * A(0, 0, -0.12), p.light)
				end
			end
			c:box(V(0.30, 0.06, 0.14), CF(0.98, 0.70, 0.92) * A(0, 0, 0.50), hue(p, 4))
			c:cone(V(0.18, 0.26, 0.18), CF(0.88, 1.24, 0.92) * A(0, 0, -0.12), hue(p, 6), GLASS)
			gem(c, V(-0.50, 1.50, 0.20), 0.20, hue(p, 5))
			gem(c, V(0.30, 1.60, -0.20), 0.20, hue(p, 7))
			gem(c, V(-0.10, 1.40, 0.50), 0.18, p.glow, NEON)
			cheeks(c, 0.48, -0.20, 0.83)
		end,
	}

	---------------------------------------------------------------- DIVINE

	-- A unicorn with a glowing gold-ringed horn, a rainbow mane and a rainbow tail.
	S.rd_t_unicorn = {
		label = "Rainmane Unicorn",
		set = "rainbow_road",
		tint = C3(255, 170, 225),
		scale = 1.10,
		head = CF(0, 1.30, 0.10),
		neck = CF(0, -0.46, 1.04),
		back = CF(0, 1.00, -0.50),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				bodySize = V(1.70, 1.70, 1.90),
				eyeY = 0.24, eyeSize = V(0.34, 0.44, 0.20), eyeSpread = 0.36,
				snout = { w = 0.70, h = 0.42, d = 0.30, y = -0.24, color = p.pale, nose = BLUSH },
				legSize = V(0.36, 0.60, 0.36), legColor = p.light, tail = false,
			})
			local horn = CF(0, 1.24, 0.50) * A(0.30, 0, 0)
			c:cone(V(0.28, 0.80, 0.28), horn, p.glow, NEON)
			c:box(V(0.30, 0.05, 0.30), horn * CF(0, -0.18, 0), GOLD, METAL)
			c:box(V(0.22, 0.05, 0.22), horn * CF(0, 0.04, 0), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				c:box(V(0.24, 0.36, 0.16), CF(0.44 * s, 1.04, 0.10) * A(0, 0, -0.25 * s), p.base)
			end
			-- The mane runs down the back, then spills over the right side.
			for i = 0, 4 do
				c:box(V(0.32, 0.34, 0.30), CF(i % 2 == 0 and 0.10 or -0.10, 0.96 - 0.04 * i, 0.10 - 0.26 * i), hue(p, i + 1))
			end
			c:box(V(0.10, 0.60, 0.30), CF(0.94, 0.50, 0.10), hue(p, 6))
			c:box(V(0.10, 0.44, 0.30), CF(0.94, 0.46, -0.20), hue(p, 7))
			for k = 1, 4 do
				c:box(V(0.16, 0.90, 0.16), CF(0, 0.40, -0.98) * A(0.55, 0, (k - 2.5) * 0.22) * CF(0, -0.40, 0), hue(p, k * 2 - 1))
			end
			c:star(V(-0.86, 1.50, 0.30), 0.32, p.glow)
			c:light(p.glow, 0.8, 8)
			cheeks(c, 0.50, -0.04, 0.97)
		end,
	}

	-- A phoenix with a flame crest, raised rainbow-tipped wings and a trailing fire tail.
	S.rd_t_phoenix = {
		label = "Huefire Phoenix",
		set = "rainbow_road",
		tint = C3(255, 80, 40),
		scale = 1.25,
		head = CF(0, 1.50, -0.10),
		neck = CF(0, -0.40, 0.82),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "bird",
				bodySize = V(1.50, 1.70, 1.50),
				eyeY = 0.26, eyeSize = V(0.34, 0.42, 0.20), eyeSpread = 0.32,
				mouth = false,
				legSize = V(0.24, 0.20, 0.30), legZ = { 0.15 }, legY = -0.88, legColor = GOLD,
				tail = false,
			})
			c:cone(V(0.24, 0.30, 0.22), CF(0, 0.00, 0.86) * A(PI / 2, 0, 0), GOLD)
			for i = 1, 3 do
				local mid = i == 2
				local h = mid and 0.60 or 0.44
				c:cone(
					V(0.24, h, 0.24),
					CF((i - 2) * 0.22, 0.82 + h * 0.5, 0.10) * A(-0.30, 0, (2 - i) * 0.35),
					mid and p.glow or hue(p, i),
					mid and NEON or nil
				)
			end
			for _, s in ipairs(SIDES) do
				local w = CF(0.92 * s, 0.70, -0.20) * A(0, 0, -0.70 * s)
				c:box(V(0.14, 1.00, 0.84), w, p.light)
				for k = 1, 3 do
					c:box(V(0.12, 0.50, 0.22), w * CF(0, 0.70, 0.30 - 0.30 * (k - 1)), hue(p, k + (s < 0 and 0 or 3)))
				end
			end
			-- Three tail plumes, each ending in a flame.
			for k = 1, 3 do
				local t = CF(0, -0.20, -0.66) * A(-0.15, (k - 2) * 0.30, 0)
				c:box(V(0.22, 0.10, 1.00), t * CF(0, 0, -0.50), hue(p, k * 2 - 1))
				gem(c, (t * CF(0, 0, -1.08)).Position, 0.22, p.glow, NEON)
			end
			c:light(p.glow, 0.8, 8)
			cheeks(c, 0.42, -0.02, 0.76)
		end,
	}

	-- A manta ray gliding on striped wings, with a crystal crown and glowing orbs below.
	S.rd_t_manta = {
		label = "Skyglide Manta",
		set = "rainbow_road",
		tint = C3(40, 190, 230),
		scale = 1.30,
		head = CF(0, 1.10, 0.10),
		neck = CF(0, -0.36, 0.90),
		back = CF(0, 0.60, -0.70),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.50, 0.90, 1.70),
				eyeY = 0.04, eyeSize = V(0.32, 0.38, 0.20), eyeSpread = 0.34,
				mouthY = -0.24, mouthSize = V(0.50, 0.08, 0.10),
				legs = false, tail = false,
			})
			c:box(V(1.40, 0.04, 1.50), CF(0, -0.40, 0), p.pale)
			for _, s in ipairs(SIDES) do
				local w = CF(0.98 * s, 0.10, -0.10) * A(0, 0, 0.15 * s)
				c:box(V(0.80, 0.20, 1.30), w, p.base)
				c:box(V(0.44, 0.14, 0.70), CF(1.46 * s, 0.22, -0.26) * A(0, 0, 0.30 * s), p.light)
				for k = 1, 3 do
					c:box(V(0.78, 0.04, 0.14), w * CF(0, 0.11, 0.42 - 0.30 * (k - 1)), hue(p, k + (s < 0 and 0 or 3)))
				end
				c:box(V(0.20, 0.36, 0.40), CF(0.66 * s, -0.12, 0.92), p.dark)
				c:ball(V(0.18, 0.18, 0.18), CF(1.30 * s, -0.60, 0.10), p.glow, NEON)
			end
			c:rod(V(0, 0.00, -0.84), V(0, -0.14, -1.80), 0.05, p.dark, nil, false)
			gem(c, V(0, -0.16, -1.88), 0.20, p.glow, NEON)
			crystal(c, V(0, 0.51, 0.10), A(0, PI / 4, 0), 0.22, 0.34, hue(p, 6))
			crystal(c, V(-0.30, 0.51, -0.05), A(0, 0, 0.30), 0.16, 0.22, hue(p, 2))
			crystal(c, V(0.30, 0.51, -0.05), A(0, 0, -0.30), 0.16, 0.22, hue(p, 4))
			c:ball(V(0.16, 0.16, 0.16), CF(0, -0.70, -0.60), p.glow, NEON)
			c:light(p.glow, 0.8, 8)
			cheeks(c, 0.40, -0.16, 0.86)
		end,
	}

	-- A stone golem with rainbow veins, crystal-capped shoulders and a glowing heart gem.
	S.rd_t_golem = {
		label = "Prismstone Golem",
		set = "rainbow_road",
		tint = C3(120, 110, 190),
		scale = 1.10,
		head = CF(0, 1.50, 0),
		neck = CF(0, -0.30, 0.76),
		back = CF(0, 0.20, -0.76),
		build = function(c, p)
			block(c, p, {
				square = true,
				bodySize = V(1.60, 1.50, 1.30),
				eyeY = 0.26, eyeSize = V(0.34, 0.40, 0.20), eyeSpread = 0.34,
				mouthY = 0.00, mouthSize = V(0.30, 0.10, 0.10),
				legSize = V(0.50, 0.50, 0.50), legX = 0.44, legY = -0.86, legZ = { 0.0 }, legColor = p.dark,
				tail = false,
			})
			gem(c, V(0, -0.34, 0.66), 0.30, p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V(0.60, 0.60, 0.70), CF(1.06 * s, 0.44, 0), p.dark)
				c:box(V(0.62, 0.62, 0.64), CF(1.14 * s, -0.36, 0.10), p.base)
				c:cone(V(0.22, 0.30, 0.22), CF(1.14 * s, -0.36, 0.52) * A(PI / 2, 0, 0), hue(p, s < 0 and 2 or 5), GLASS)
				crystal(c, V(1.06 * s, 0.74, 0), A(0, 0, -0.30 * s), 0.24, 0.40, hue(p, s < 0 and 1 or 4))
				c:box(V(0.06, 0.70, 0.08), CF(0.62 * s, -0.20, 0.66) * A(0, 0, 0.40 * s), hue(p, s < 0 and 3 or 6))
			end
			crystal(c, V(0, 0.81, 0), A(0, PI / 4, 0), 0.30, 0.50, hue(p, 7))
			crystal(c, V(-0.36, 0.81, -0.20), A(0, 0, 0.35), 0.20, 0.30, hue(p, 5))
			crystal(c, V(0.36, 0.81, -0.20), A(0, 0, -0.35), 0.20, 0.30, hue(p, 3))
			gem(c, V(-1.20, 1.20, 0.30), 0.22, p.glow, NEON)
			gem(c, V(1.30, 1.10, -0.30), 0.22, hue(p, 6))
			c:light(p.glow, 0.7, 8)
			cheeks(c, 0.46, -0.02, 0.66)
		end,
	}

	-- A wishing star with a smiling face, a back layer of points and a rainbow comet trail.
	S.rd_t_star = {
		label = "Wishbow Star",
		set = "rainbow_road",
		tint = C3(255, 220, 60),
		scale = 1.15,
		head = CF(0, 1.66, 0),
		neck = CF(0, -0.20, 0.40),
		back = CF(0, 0.30, -0.40),
		build = function(c, p)
			local mid = V(0, 0.36, 0)
			c:box(V(1.10, 1.10, 0.70), CF(mid), p.base)
			for k = 0, 4 do
				local a = k * 2 * PI / 5
				local u = V(math.sin(a), math.cos(a), 0)
				spike(c, mid + u * 0.50, u, 0.56, 0.74, p.base)
				local b = a + PI / 5
				local v = V(math.sin(b), math.cos(b), 0)
				spike(c, mid + v * 0.46 + V(0, 0, -0.20), v, 0.40, 0.50, p.dark)
			end
			c:eyes(0.52, 0.36, 0.22, 0.15)
			c:box(V(0.28, 0.08, 0.06), CF(0, 0.22, 0.36), INK)
			cheeks(c, 0.38, 0.30, 0.36)
			-- The comet trail: five rainbow streaks sweeping down and back.
			local dir = V(-0.70, -0.80, -0.90).Unit
			local side = V(0.75, -0.66, 0).Unit
			for k = 1, 5 do
				local from = mid + V(0, 0, -0.36) + side * ((k - 3) * 0.14)
				c:rod(from, from + dir * 1.40, 0.07, hue(p, k), NEON, false)
			end
			for _, q in ipairs({ { -1.10, -0.70, -1.10 }, { -0.70, -1.10, -0.90 }, { -1.30, -0.30, -0.80 } }) do
				c:ball(V(0.14, 0.14, 0.14), CF(q[1], q[2], q[3]), p.glow, NEON)
			end
			c:light(p.glow, 1, 8)
		end,
	}

	-- A wind chime: a bell with a face, seven rainbow glass rods and a star on a string.
	S.rd_t_windchime = {
		label = "Prism Windchime",
		set = "rainbow_road",
		tint = C3(80, 220, 160),
		scale = 1.25,
		head = CF(0, 1.96, 0),
		neck = CF(0, 0.30, 0.72),
		back = CF(0, 0.76, -0.66),
		build = function(c, p)
			c:box(V(1.40, 1.00, 1.20), CF(0, 0.76, 0), p.base)
			c:box(V(0.90, 0.36, 0.80), CF(0, 1.44, 0), p.light)
			c:box(V(0.30, 0.30, 0.08), CF(0, 1.76, 0), GOLD, METAL)
			c:box(V(1.70, 0.16, 1.50), CF(0, 0.22, 0), GOLD, METAL)
			c:eyes(0.86, 0.62, 0.30, 0.17)
			c:box(V(0.30, 0.08, 0.06), CF(0, 0.54, 0.61), INK)
			cheeks(c, 0.46, 0.58, 0.61)
			for k = 1, 7 do
				local a = (k - 0.5) * 2 * PI / 7
				local len = 0.60 + 0.18 * ((k * 3) % 4)
				local x, z = 0.58 * math.sin(a), 0.48 * math.cos(a)
				c:box(V(0.14, len, 0.14), CF(x, 0.14 - len * 0.5, z), hue(p, k), GLASS).Reflectance = 0.15
				local glow = k % 2 == 0
				c:ball(V(0.16, 0.16, 0.16), CF(x, 0.08 - len, z), glow and p.glow or hue(p, k), glow and NEON or GLASS)
			end
			c:rod(V(0, 0.14, 0), V(0, -0.90, 0), 0.03, GOLD, METAL, false)
			c:star(V(0, -1.10, 0), 0.40, p.glow)
			c:light(p.glow, 0.8, 8)
		end,
	}

	---------------------------------------------------------------- EXOTIC

	-- A fox spirit with seven fluffy rainbow tails, fox-fire orbs and a forehead jewel.
	S.rd_t_kitsune = {
		label = "Sevenbow Kitsune",
		set = "rainbow_road",
		tint = C3(255, 120, 50),
		scale = 1.15,
		head = CF(0, 1.40, 0.20),
		neck = CF(0, -0.36, 0.96),
		back = CF(0, 0.70, -0.60),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.70, 1.60, 1.80),
				eyeY = 0.20, eyeSize = V(0.34, 0.42, 0.20), eyeSpread = 0.36,
				snout = { w = 0.56, h = 0.34, d = 0.36, y = -0.22, color = p.pale, nose = INK },
				bib = { w = 1.10, h = 0.50, y = -0.56, color = p.pale },
				legColor = p.dark, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(V(0.44, 0.60, 0.26), CF(0.50 * s, 1.16, 0.10) * A(0, 0, -0.20 * s), p.base)
				c:box(V(0.20, 0.30, 0.06), CF(0.48 * s, 1.08, 0.24) * A(0, 0, -0.20 * s), p.pale)
				c:ball(V(0.26, 0.26, 0.26), CF(1.20 * s, 0.70, 0.40), p.glow, NEON)
			end
			gem(c, V(0, 0.62, 0.92), 0.20, p.glow, NEON)
			-- Seven tails fanned up behind, one per rainbow hue, each with a pale tip.
			for k = 1, 7 do
				local t = CF(0, 0.30, -0.86) * A(-0.45, 0, (k - 4) * 0.30)
				c:box(V(0.30, 1.00, 0.30), t * CF(0, 0.50, 0), hue(p, k))
				c:box(V(0.34, 0.30, 0.34), t * CF(0, 1.10, 0), p.pale)
			end
			cheeks(c, 0.50, -0.06, 0.91)
		end,
	}

	-- A long sky dragon: gold antlers, glowing whiskers, a pearl and a rainbow body coiling behind.
	S.rd_t_dragon = {
		label = "Huestream Dragon",
		set = "rainbow_road",
		tint = C3(70, 210, 190),
		scale = 1.20,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.40, 1.10),
		back = CF(0, 0.40, -1.10),
		build = function(c, p)
			block(c, p, {
				bodySize = V(1.40, 1.20, 1.40),
				eyeY = 0.20, eyeSize = V(0.34, 0.42, 0.20), eyeSpread = 0.34,
				snout = { w = 0.70, h = 0.40, d = 0.40, y = -0.22, color = p.light, nose = p.dark },
				legs = false, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:rod(V(0.30 * s, 0.60, -0.20), V(0.52 * s, 1.20, -0.40), 0.05, GOLD, nil, false)
				c:rod(V(0.42 * s, 0.94, -0.31), V(0.74 * s, 1.06, -0.16), 0.04, GOLD, nil, false)
				c:rod(V(0.30 * s, -0.24, 0.96), V(0.90 * s, -0.46, 1.16), 0.025, p.glow, NEON, false)
				c:box(V(0.10, 0.40, 0.50), CF(0.74 * s, 0.30, -0.30) * A(0, 0, -0.30 * s), hue(p, s < 0 and 6 or 2))
			end
			local path = {
				V(0, -0.10, -0.66), V(0.50, -0.20, -0.98), V(0.60, -0.30, -1.42), V(0.16, -0.36, -1.70),
				V(-0.40, -0.32, -1.68), V(-0.78, -0.16, -1.38), V(-0.90, 0.10, -0.98),
			}
			for i = 1, 6 do
				local a, b = path[i], path[i + 1]
				local sz = 0.80 - 0.08 * i
				local seg = CFrame.lookAt((a + b) * 0.5, b)
				c:box(V(sz, sz, 0.62), seg, hue(p, i))
				if i % 2 == 1 then
					c:cone(V(0.20, 0.30, 0.20), seg * CF(0, sz * 0.5 + 0.12, 0), p.light)
				end
			end
			c:box(V(0.10, 0.50, 0.50), CF(path[7]) * A(0, 0.5, 0), hue(p, 7))
			c:ball(V(0.36, 0.36, 0.36), CF(0, -0.70, 1.00), p.glow, NEON)
			c:light(p.glow, 0.8, 8)
			cheeks(c, 0.46, -0.04, 0.71)
		end,
	}

	-- A glass prism with a face: a white beam goes in one side, a rainbow fans out the other.
	S.rd_t_prism = {
		label = "Spectrum Prism",
		set = "rainbow_road",
		tint = C3(150, 250, 230),
		scale = 1.20,
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.36, 0.66),
		back = CF(0, 0.30, -0.66),
		build = function(c, p)
			-- Turned so its triangle faces the front.
			c:prism(V(1.20, 1.80, 2.00), CF(0, 0.30, 0) * A(0, PI / 2, 0), p.pale, GLASS).Transparency = 0.15
			c:eyes(0.10, 0.62, 0.24, 0.15)
			c:box(V(0.26, 0.08, 0.06), CF(0, -0.24, 0.62), INK)
			cheeks(c, 0.46, -0.14, 0.61)
			c:rod(V(-1.45, 0.06, 0), V(-0.40, 0.36, 0), 0.07, WHITE, NEON, false)
			for k = 1, 7 do
				local a = 0.20 - 0.15 * (k - 1)
				local from = V(0.40, 0.36, 0)
				c:rod(from, from + V(math.cos(a), math.sin(a), 0) * 0.95, 0.06, hue(p, k), NEON, false)
			end
			c:box(V(1.70, 0.20, 1.00), CF(0, -0.70, 0), p.dark)
			crystal(c, V(-0.60, -0.60, 0.20), A(0, 0, 0.3), 0.20, 0.30, hue(p, 2))
			crystal(c, V(0.66, -0.60, -0.20), A(0, 0, -0.3), 0.18, 0.26, hue(p, 5))
			gem(c, V(-0.80, 1.10, -0.20), 0.20, hue(p, 6))
			gem(c, V(0.90, 1.00, 0.10), 0.20, hue(p, 3))
			c:star(V(0, 1.42, 0), 0.30, WHITE)
			c:light(p.glow, 1, 8)
		end,
	}

	-- A peacock with a crest of jewel tips and a full fan of rainbow eye-feathers.
	S.rd_t_peacock = {
		label = "Kaleido Peacock",
		set = "rainbow_road",
		tint = C3(30, 110, 255),
		scale = 1.30,
		head = CF(0, 1.40, 0.20),
		neck = CF(0, -0.36, 0.80),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "bird",
				bodySize = V(1.40, 1.70, 1.40),
				eyeY = 0.30, eyeSize = V(0.32, 0.40, 0.20), eyeSpread = 0.30,
				mouth = false,
				legSize = V(0.24, 0.30, 0.30), legZ = { 0.15 }, legY = -0.90, legColor = GOLD,
				tail = false,
			})
			c:cone(V(0.22, 0.28, 0.20), CF(0, 0.06, 0.80) * A(PI / 2, 0, 0), GOLD)
			for i = 1, 3 do
				local tip = V((i - 2) * 0.20, 1.30, 0.10 - 0.06 * math.abs(i - 2))
				c:rod(V((i - 2) * 0.06, 0.80, 0.10), tip, 0.025, p.dark, nil, false)
				c:ball(V(0.16, 0.16, 0.16), CF(tip), hue(p, i * 2 + 1), GLASS)
			end
			-- The train: seven feathers fanned into a wheel, each with a glowing eye.
			for k = 1, 7 do
				local f = CF(0, 0.10, -0.76) * A(-0.25, 0, (k - 4) * 0.36) * CF(0, 0.90, 0)
				c:box(V(0.40, 1.50, 0.08), f, hue(p, k))
				c:box(V(0.28, 0.28, 0.06), f * CF(0, 0.50, 0.06) * A(0, 0, PI / 4), p.glow, NEON)
			end
			for _, s in ipairs(SIDES) do
				c:box(V(0.14, 0.90, 0.90), CF(0.74 * s, -0.04, -0.10) * A(0, 0, 0.10 * s), p.dark)
			end
			cheeks(c, 0.40, 0.00, 0.73)
		end,
	}

	return S
end
