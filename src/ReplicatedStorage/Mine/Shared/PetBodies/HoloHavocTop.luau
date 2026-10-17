--[[ PetBodies/HoloHavocTop -- Holo Havoc's top bodies (Epic and up).
	Each of these is worn by exactly ONE pet in the game (owner, 2026-10-10:
	"ALL UNIQUE"). Holographic foil, polished chrome and optical tricks:
	balloon foil, mirror lenses, film reels, fibre optics, op-art stripes,
	infinity mirrors, after-images, anaglyph 3D and impossible shapes. No retro
	arcade gear (that is Arcade Legends) and no space (that is Starfront).
	Same chrome-and-foil house style as PetBodies/HoloHavoc.
	See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block, ears, wings = K.C3, K.block, K.ears, K.wings
	local METAL, NEON, GLASS, INK, WHITE = K.METAL, K.NEON, K.GLASS, K.INK, K.WHITE
	local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
	local PI = math.pi
	local CHROME = C3(214, 220, 232)
	local FOIL_A, FOIL_B = C3(140, 240, 255), C3(255, 160, 236)
	local BLUSH = C3(255, 150, 190)
	local GOLD = C3(255, 206, 96)
	local RED3D, CYAN3D = C3(255, 50, 70), C3(40, 220, 255)
	local SIDES = { -1, 1 }
	local UP = A(0, 0, PI / 2) -- stands a cylinder on its end (axis Y)
	local FACE = A(0, PI / 2, 0) -- turns a cylinder's flat face to the front (axis Z)
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

	-- Set a part's (or a cone group's) reflectance and hand it back.
	local function shine(part, r)
		part.Reflectance = r
		return part
	end

	-- Blush marks either side of a face (2 parts).
	local function cheeks(c, x, y, z)
		for _, s in ipairs(SIDES) do
			c:box(V(0.18, 0.08, 0.04), CF(x * s, y, z), BLUSH, NEON)
		end
	end

	-- A small smiling mouth (1 part).
	local function smile(c, y, z, w)
		return c:box(V(w or 0.28, 0.08, 0.06), CF(0, y, z), INK)
	end

	-- A cube turned onto its point (1 part).
	local function gem(c, pos, size, colour, mat)
		return c:box(V(size, size, size), CF(pos) * A(PI / 4, 0, PI / 4), colour, mat or GLASS)
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

	-- A ring of `n` rods round a circle in the XZ plane of `cf` (n parts).
	local function ring(c, cf, radius, n, r, colour, mat)
		local pts = {}
		for i = 0, n do
			local a = i / n * 2 * PI
			pts[i] = (cf * CF(radius * math.cos(a), 0, radius * math.sin(a))).Position
		end
		for i = 1, n do
			shine(c:rod(pts[i - 1], pts[i], r, colour, mat, false), 0.4)
		end
	end

	---------------------------------------------------------------- EPIC

	-- A twisted foil-balloon giraffe: sausage legs, a tall neck, knots at the twists.
	S.hh_t_giraffe = {
		label = "Balloon Giraffe",
		set = "holo_havoc",
		tint = C3(255, 200, 40),
		scale = 1.1,
		head = CF(0, 2.02, 0.70),
		neck = CF(0, -0.10, 0.62),
		back = CF(0, 0.56, -0.50),
		build = function(c, p)
			local function bal(size, cf, colour)
				return shine(c:round(size, cf, colour or p.base, METAL), 0.35)
			end
			bal(V(0.84, 0.80, 1.50), CF(0, 0.12, -0.12))
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.46, -0.66 }) do
					bal(V(0.38, 0.98, 0.38), CF(0.30 * s, -0.52, z) * A(0, 0, 0.08 * s))
				end
				bal(V(0.20, 0.30, 0.20), CF(0.30 * s, 1.82, 0.66) * A(0, 0, -0.4 * s), p.light)
				c:rod(V(0.10 * s, 1.78, 0.74), V(0.14 * s, 2.00, 0.72), 0.04, p.dark, METAL, false)
				c:ball(V(0.12, 0.12, 0.12), CF(0.14 * s, 2.02, 0.72), p.dark, METAL)
				c:box(V(0.04, 0.22, 0.26), CF(0.43 * s, 0.20, -0.20), p.dark, METAL)
			end
			bal(V(0.44, 1.30, 0.44), CF(0, 0.92, 0.48) * A(-0.22, 0, 0))
			bal(V(0.58, 0.54, 0.92), CF(0, 1.56, 0.80))
			-- Twist knots where the balloon turns.
			for _, z in ipairs({ 0.62, -0.86 }) do
				c:ball(V(0.22, 0.22, 0.22), CF(0, 0.18, z), p.dark, METAL)
			end
			c:eyes(1.68, 1.04, 0.24, 0.10)
			smile(c, 1.46, 1.24, 0.20)
			bal(V(0.18, 0.18, 0.40), CF(0, 0.30, -0.98) * A(0.6, 0, 0), p.dark)
			c:star(V(-0.30, 0.62, 0.20), 0.30, WHITE)
		end,
	}

	-- A gopher popping out of a chrome burrow ring, a periscope up over its head.
	S.hh_t_gopher = {
		label = "Periscope Gopher",
		set = "holo_havoc",
		tint = C3(220, 120, 60),
		scale = 1.15,
		head = CF(-0.30, 1.12, 0.10),
		neck = CF(0, -0.40, 0.72),
		back = CF(0, 0.30, -0.70),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				bodySize = V(1.50, 1.90, 1.30),
				eyeY = 0.36, eyeSize = V(0.36, 0.42, 0.20), eyeSpread = 0.34,
				snout = { w = 0.62, h = 0.40, d = 0.36, y = -0.06, color = p.pale, nose = INK },
				legs = false, tail = false,
			})
			finish(c, from, METAL, 0.2)
			for _, s in ipairs(SIDES) do
				c:box(V(0.10, 0.14, 0.04), CF(0.06 * s, -0.32, 0.82), WHITE)
				shine(c:round(V(0.34, 0.40, 0.34), CF(0.66 * s, -0.12, 0.42), p.light, METAL), 0.2)
				c:round(V(0.26, 0.26, 0.14), CF(0.56 * s, 1.04, 0.10), p.dark)
				c:round(V(0.30, 0.20, 0.26), CF(0.42 * s, -0.66, 0.74), p.pale)
			end
			-- The burrow: a chrome ring round a dark hole.
			shine(c:cyl(V(0.30, 2.20, 2.20), CF(0, -0.86, 0) * UP, CHROME, METAL), 0.5)
			c:cyl(V(0.32, 1.60, 1.60), CF(0, -0.84, 0) * UP, INK)
			-- The periscope: tube, strap, elbow and a glinting window.
			shine(c:cyl(V(0.70, 0.22, 0.22), CF(0.40, 1.35, -0.12) * UP, CHROME, METAL), 0.5)
			c:cyl(V(0.12, 0.30, 0.30), CF(0.40, 1.08, -0.12) * UP, p.dark)
			shine(c:box(V(0.32, 0.32, 0.46), CF(0.40, 1.80, 0.00), CHROME, METAL), 0.5)
			shine(c:box(V(0.24, 0.22, 0.04), CF(0.40, 1.80, 0.24), C3(130, 210, 255), GLASS), 0.6)
			c:star(V(0.56, 1.98, 0.26), 0.24, WHITE)
		end,
	}

	-- A liquid-chrome slug: a mirror hump, eyestalks and a trail of mercury drops.
	S.hh_t_slug = {
		label = "Mercury Slug",
		set = "holo_havoc",
		tint = C3(150, 170, 255),
		scale = 1.1,
		head = CF(0, 0.72, 0.40),
		neck = CF(0, -0.40, 1.00),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			shine(c:round(V(1.40, 1.00, 2.30), CF(0, -0.36, -0.20), p.base, METAL), 0.6)
			shine(c:round(V(1.30, 1.30, 1.10), CF(0, 0.02, 0.50), p.base, METAL), 0.6)
			shine(c:box(V(1.70, 0.14, 2.60), CF(0, -0.86, -0.12), p.dark, METAL), 0.5)
			for _, s in ipairs(SIDES) do
				c:rod(V(0.26 * s, 0.50, 0.70), V(0.44 * s, 1.24, 0.86), 0.07, p.light, METAL, false)
				shine(c:ball(V(0.30, 0.30, 0.30), CF(0.44 * s, 1.30, 0.84), p.light, METAL), 0.5)
				c:eye(V(0.44 * s, 1.30, 0.98), 0.13)
			end
			smile(c, -0.06, 1.06, 0.30)
			cheeks(c, 0.40, 0.04, 1.03)
			for i, z in ipairs({ -1.50, -1.74, -1.94 }) do
				local d = 0.42 - i * 0.08
				shine(c:ball(V(d, 0.10, d), CF((i % 2 == 0) and 0.12 or -0.12, -0.88, z), p.light, METAL), 0.7)
			end
			c:box(V(0.06, 0.40, 1.00), CF(0.71, -0.30, -0.40), WHITE).Reflectance = 0.4
			c:star(V(-0.40, 0.70, 0.40), 0.30, WHITE)
		end,
	}

	-- A shiny trading card on little legs: holo art window, a star and a rarity gem.
	S.hh_t_holocard = {
		label = "Trading Holocard",
		set = "holo_havoc",
		tint = C3(80, 228, 255),
		head = CF(0, 1.34, 0),
		neck = CF(0, -0.70, 0.20),
		back = CF(0, 0.20, -0.20),
		build = function(c, p)
			shine(c:box(V(1.60, 2.20, 0.16), CF(0, 0.10, 0), p.base, METAL), 0.3)
			c:box(V(1.40, 2.00, 0.04), CF(0, 0.10, -0.09), p.dark)
			c:cyl(V(0.04, 0.80, 0.80), CF(0, 0.20, -0.12) * FACE, p.light)
			shine(c:box(V(1.30, 1.10, 0.04), CF(0, 0.46, 0.09), p.pale, METAL), 0.6)
			for i, x in ipairs({ -0.40, 0, 0.40 }) do
				shine(c:box(V(0.12, 1.00, 0.02), CF(x, 0.46, 0.12) * A(0, 0, 0.6), (i % 2 == 0) and FOIL_B or FOIL_A, METAL), 0.6)
			end
			c:star(V(0, 0.52, 0.14), 0.46, p.glow)
			gem(c, V(0.56, 1.06, 0.12), 0.16, p.glow, NEON)
			c:box(V(1.30, 0.60, 0.04), CF(0, -0.56, 0.09), p.light)
			c:eyes(-0.48, 0.14, 0.30, 0.13)
			smile(c, -0.76, 0.12, 0.24)
			for _, s in ipairs(SIDES) do
				c:rod(V(0.80 * s, -0.10, 0), V(1.08 * s, -0.42, 0.14), 0.06, p.dark, nil, false)
				c:ball(V(0.20, 0.20, 0.20), CF(1.10 * s, -0.44, 0.15), p.pale)
				c:rod(V(0.40 * s, -1.00, 0), V(0.40 * s, -1.20, 0.02), 0.06, p.dark, nil, false)
				c:box(V(0.30, 0.14, 0.40), CF(0.40 * s, -1.26, 0.08), p.deep)
			end
		end,
	}

	-- Mirrored aviator shades that walk on their bent arms; eyes peek from the lenses.
	S.hh_t_shades = {
		label = "Aviator Shades",
		set = "holo_havoc",
		tint = C3(240, 140, 160),
		scale = 1.2,
		head = CF(0, 0.84, -0.10),
		neck = CF(0, -0.36, 0.20),
		back = CF(0, 0.55, -0.90),
		build = function(c, p)
			shine(c:box(V(2.36, 0.14, 0.14), CF(0, 0.66, 0), p.base, METAL), 0.5)
			for _, s in ipairs(SIDES) do
				shine(c:round(V(1.04, 0.92, 0.12), CF(0.58 * s, 0.20, -0.02), p.base, METAL), 0.5)
				shine(c:round(V(0.92, 0.80, 0.12), CF(0.58 * s, 0.20, 0.02), p.dark, GLASS), 0.7)
				c:eye(V(0.58 * s, 0.24, 0.12), 0.18)
				c:box(V(0.07, 0.46, 0.02), CF(0.80 * s, 0.24, 0.09) * A(0, 0, 0.6 * s), WHITE).Reflectance = 0.5
				-- The arms run back, then bend down to the ground as legs.
				shine(c:box(V(0.08, 0.10, 1.30), CF(1.12 * s, 0.60, -0.66), p.base, METAL), 0.4)
				c:rod(V(1.12 * s, 0.56, -1.28), V(1.00 * s, -0.80, -1.10), 0.05, p.base, METAL, false)
				c:rod(V(0.58 * s, -0.24, 0.00), V(0.62 * s, -0.80, 0.10), 0.05, p.base, METAL, false)
				c:box(V(0.24, 0.12, 0.34), CF(0.62 * s, -0.86, 0.18), p.deep)
				c:box(V(0.24, 0.12, 0.34), CF(1.00 * s, -0.86, -1.02), p.deep)
			end
			c:box(V(0.34, 0.12, 0.10), CF(0, 0.46, 0.02), p.base, METAL)
			c:box(V(0.40, 0.24, 0.12), CF(0, 0.02, 0.00), p.light, METAL)
			smile(c, -0.02, 0.07, 0.22)
			c:star(V(-0.96, 0.62, 0.12), 0.30, WHITE)
		end,
	}

	-- A soap bubble afloat over its wand: thin-film swirls and two baby bubbles.
	S.hh_t_bubble = {
		label = "Soapfilm Bubble",
		set = "holo_havoc",
		tint = C3(190, 240, 255),
		head = CF(0, 1.08, 0),
		neck = CF(0, -0.62, 0.74),
		back = CF(0, 0.10, -0.92),
		build = function(c, p)
			local mid = V(0, 0.10, 0)
			local b = c:ball(V(1.90, 1.90, 1.90), CF(mid), p.light, GLASS)
			b.Transparency = 0.45
			b.Reflectance = 0.3
			-- Thin-film swirls sliding over the skin.
			for _, w in ipairs({ { -0.62, 0.62, 0.22, FOIL_B }, { 0.70, 0.36, -0.40, FOIL_A }, { -0.30, -0.50, -0.70, p.glow }, { 0.20, 0.80, -0.50, FOIL_A } }) do
				local u = (V(w[1], w[2], w[3]) - mid).Unit
				local at = mid + u * 0.95
				c:box(V(0.46, 0.04, 0.24), CFrame.lookAt(at, at + u) * A(PI / 2, 0, 0.5), w[4], NEON).Transparency = 0.35
			end
			c:eyes(0.30, 0.84, 0.32, 0.17)
			smile(c, -0.10, 0.94, 0.26)
			cheeks(c, 0.56, 0.06, 0.76)
			c:round(V(0.40, 0.18, 0.10), CF(-0.42, 0.66, 0.64) * A(0, 0, 0.5), WHITE)
			-- The wand: a ring of chrome beads and a handle.
			for i = 0, 7 do
				local a = i / 8 * 2 * PI
				shine(c:ball(V(0.16, 0.16, 0.16), CF(0.56 * math.cos(a), -1.00, 0.56 * math.sin(a)), CHROME, METAL), 0.5)
			end
			c:rod(V(0.56, -1.00, 0), V(1.00, -1.42, 0.10), 0.05, p.dark, nil, false)
			for _, q in ipairs({ { 1.06, 0.86, -0.20, 0.36 }, { -1.02, 1.10, 0.10, 0.24 } }) do
				local baby = c:ball(V(q[4], q[4], q[4]), CF(q[1], q[2], q[3]), p.light, GLASS)
				baby.Transparency = 0.45
				baby.Reflectance = 0.3
			end
		end,
	}

	-- A chrome diner toaster: two slices up for ears, a lever, a dial and a bright band.
	S.hh_t_toaster = {
		label = "Diner Toaster",
		set = "holo_havoc",
		tint = C3(120, 240, 190),
		head = CF(0, 1.44, 0),
		neck = CF(0, -0.50, 0.70),
		back = CF(0, 0.10, -0.70),
		build = function(c, p)
			shine(c:box(V(2.00, 1.50, 1.30), CF(0, -0.10, 0), p.base, METAL), 0.5)
			for _, z in ipairs({ 0.26, -0.26 }) do
				c:box(V(1.40, 0.06, 0.22), CF(0, 0.66, z), INK)
				c:box(V(1.10, 0.66, 0.14), CF(0, 0.92, z), C3(230, 176, 104))
				c:box(V(1.16, 0.10, 0.18), CF(0, 1.27, z), C3(176, 112, 60))
			end
			c:eyes(0.06, 0.68, 0.44, 0.18)
			smile(c, -0.30, 0.68, 0.34)
			cheeks(c, 0.70, -0.18, 0.67)
			c:box(V(0.06, 0.70, 0.12), CF(1.02, 0.05, 0.30), INK)
			shine(c:box(V(0.22, 0.14, 0.26), CF(1.12, 0.26, 0.30), p.dark, METAL), 0.3)
			shine(c:cyl(V(0.12, 0.34, 0.34), CF(-1.05, -0.10, 0.30), CHROME, METAL), 0.5)
			shine(c:box(V(2.06, 0.16, 1.36), CF(0, -0.80, 0), CHROME, METAL), 0.6)
			for _, sx in ipairs(SIDES) do
				for _, sz in ipairs(SIDES) do
					c:box(V(0.24, 0.12, 0.24), CF(0.80 * sx, -0.94, 0.42 * sz), INK)
				end
			end
			c:star(V(-0.70, 0.40, 0.68), 0.30, WHITE)
		end,
	}

	-- A party popper in foil bands, bursting with confetti and streamers.
	S.hh_t_popper = {
		label = "Foil Popper",
		set = "holo_havoc",
		tint = C3(230, 30, 160),
		scale = 1.15,
		head = CF(0, 1.26, 0),
		neck = CF(0, -0.30, 0.46),
		back = CF(0, 0.40, -0.60),
		build = function(c, p)
			shine(c:cone(V(1.60, 2.00, 1.60), CF(0, 0, 0) * A(PI, 0, 0), p.base, METAL), 0.4)
			shine(c:box(V(1.30, 0.12, 1.30), CF(0, 0.55, 0), FOIL_A, METAL), 0.5)
			shine(c:box(V(0.66, 0.12, 0.66), CF(0, -0.25, 0), FOIL_B, METAL), 0.5)
			shine(c:box(V(1.66, 0.12, 1.66), CF(0, 1.00, 0), CHROME, METAL), 0.5)
			c:box(V(1.50, 0.06, 1.50), CF(0, 1.04, 0), p.deep)
			c:eyes(0.22, 0.52, 0.20, 0.13)
			smile(c, -0.04, 0.40, 0.18)
			local bits = { { -0.50, 1.40, 0.20 }, { 0.40, 1.55, -0.10 }, { 0.00, 1.85, 0.30 }, { -0.20, 1.70, -0.40 }, { 0.65, 1.30, 0.35 }, { -0.70, 1.65, -0.10 } }
			local shades = { FOIL_A, FOIL_B, p.glow, CHROME }
			for i, b in ipairs(bits) do
				local colour = shades[(i - 1) % 4 + 1]
				local bit = c:box(V(0.18, 0.18, 0.04), CF(b[1], b[2], b[3]) * A(i, i * 0.7, i * 0.3), colour, (colour == p.glow) and NEON or METAL)
				bit.Reflectance = (colour == p.glow) and 0 or 0.5
			end
			c:rod(V(-0.20, 1.05, 0), V(-0.75, 1.95, 0.15), 0.04, p.light, METAL, false)
			c:rod(V(0.25, 1.05, 0.10), V(0.80, 1.85, -0.15), 0.04, FOIL_B, METAL, false)
			c:rod(V(0, -1.00, 0), V(0.18, -1.24, 0.14), 0.03, WHITE, nil, false)
			for _, s in ipairs(SIDES) do
				c:box(V(0.22, 0.12, 0.30), CF(0.20 * s, -1.00, 0.10), p.deep)
				c:rod(V(0.52 * s, 0.30, 0), V(0.90 * s, 0.52, 0.18), 0.05, p.dark, nil, false)
			end
		end,
	}

	-- A sleek starling in oil-slick sheen, spangled with bright speckles.
	S.hh_t_starling = {
		label = "Sheen Starling",
		set = "holo_havoc",
		tint = C3(110, 60, 230),
		scale = 1.1,
		head = CF(0, 1.16, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				shape = "bird", bodySize = V(1.70, 1.70, 1.80),
				eyeY = 0.26, eyeSize = V(0.36, 0.44, 0.20), eyeSpread = 0.38, mouth = false,
				legSize = V(0.12, 0.40, 0.12), legX = 0.30, legY = -0.90, legZ = { 0.05 }, legColor = C3(240, 170, 60),
				tail = false,
			})
			finish(c, from, METAL, 0.35)
			c:cone(V(0.22, 0.70, 0.20), CF(0, 0.02, 1.22) * A(PI / 2, 0, 0), C3(250, 200, 60))
			for _, s in ipairs(SIDES) do
				shine(c:wedge(V(0.12, 0.50, 1.50), CF(0.94 * s, 0.24, -0.50) * A(0.25, 0, 0), p.dark, METAL), 0.4)
				shine(c:box(V(0.24, 0.06, 0.80), CF(0.16 * s, 0.10, -1.24) * A(0.30, 0.25 * s, 0), p.dark, METAL), 0.4)
			end
			local dots = { { 0.88, 0.40, 0.30 }, { -0.88, 0.40, 0.30 }, { 0.88, -0.10, -0.10 }, { -0.88, -0.10, -0.10 }, { 0.30, 0.94, -0.20 }, { -0.30, 0.94, 0.10 } }
			for i, d in ipairs(dots) do
				c:box(V(0.12, 0.12, 0.12), CF(d[1], d[2], d[3]) * A(PI / 4, 0, PI / 4), (i % 2 == 0) and FOIL_A or WHITE, NEON)
			end
			c:star(V(0.60, 0.90, 0.60), 0.28, WHITE)
		end,
	}

	-- A cuttlefish that strobes: rippling glass fins, curling arms, flashing bands.
	S.hh_t_cuttlefish = {
		label = "Strobe Cuttlefish",
		set = "holo_havoc",
		tint = C3(255, 110, 90),
		scale = 1.1,
		head = CF(0, 0.76, 0.30),
		neck = CF(0, -0.50, 1.30),
		back = CF(0, 0.30, -1.30),
		build = function(c, p)
			shine(c:round(V(1.50, 1.10, 2.20), CF(0, 0.10, -0.30), p.base, METAL), 0.3)
			shine(c:round(V(1.24, 0.94, 0.60), CF(0, 0.06, 0.88), p.base, METAL), 0.3)
			for _, s in ipairs(SIDES) do
				for k = 0, 2 do
					local f = c:box(V(0.40, 0.05, 0.66), CF(0.86 * s, -0.04, 0.30 - k * 0.66) * A(0, 0, ((k % 2 == 0) and 0.18 or -0.18) * s), p.light, GLASS)
					f.Transparency = 0.25
					f.Reflectance = 0.3
				end
				c:eye(V(0.44 * s, 0.30, 1.10), 0.17)
			end
			for i = 1, 6 do
				local x = -0.40 + (i - 1) * 0.16
				c:rod(V(x, -0.20, 1.06), V(x * 1.3, -0.60, 1.50), 0.06, p.light, METAL, false)
			end
			-- Strobe bands across the mantle: they flash.
			for i, z in ipairs({ 0.30, -0.10, -0.50, -0.90 }) do
				c:box(V(0.90, 0.06, 0.20), CF(0, 0.66, z), (i % 2 == 0) and p.deep or p.glow, (i % 2 == 0) and METAL or NEON)
			end
			for _, b in ipairs({ { 0.50, 0.90, 1.30, 0.20 }, { 0.80, 1.20, 1.10, 0.14 } }) do
				c:ball(V(b[4], b[4], b[4]), CF(b[1], b[2], b[3]), p.pale, GLASS).Transparency = 0.4
			end
		end,
	}

	-- A zebra in op-art: zig-zag flank stripes, a striped mane, a spinning bullseye rump.
	S.hh_t_zebra = {
		label = "Illusion Zebra",
		set = "holo_havoc",
		tint = C3(250, 250, 255),
		head = CF(0, 1.16, 0.10),
		neck = CF(0, -0.40, 0.92),
		back = CF(0, 0.30, -0.86),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				bodySize = V(1.90, 1.76, 1.80),
				eyeY = 0.26, eyeSpread = 0.42,
				snout = { w = 0.66, h = 0.48, d = 0.50, y = -0.30, color = p.deep, nose = INK },
				legColor = p.deep, legSize = V(0.40, 0.40, 0.44),
				tail = false,
			})
			finish(c, from, METAL, 0.2)
			ears(c, p.base, "up")
			for _, s in ipairs(SIDES) do
				for k = 0, 2 do
					c:box(V(0.05, 1.30, 0.18), CF(0.96 * s, 0.06, 0.42 - k * 0.42) * A((k % 2 == 0) and 0.35 or -0.35, 0, 0), p.deep, METAL)
				end
			end
			for k = 0, 2 do
				c:box(V(0.18, 0.30, 0.34), CF(0, 1.10, 0.40 - k * 0.40), (k % 2 == 0) and p.deep or p.pale, METAL)
			end
			-- A bullseye on the rump that seems to spin.
			for i, sz in ipairs({ 1.10, 0.74, 0.38 }) do
				c:box(V(sz, sz, 0.04), CF(0, 0.16, -0.92 - i * 0.012) * A(0, 0, 0.3 * i), (i % 2 == 1) and p.deep or p.pale, METAL)
			end
			c:rod(V(0, 0.40, -0.94), V(0, -0.10, -1.24), 0.05, p.deep, nil, false)
		end,
	}

	-- A fibre-optic anemone: a chrome column with a face, glowing-tipped strands.
	S.hh_t_anemone = {
		label = "Fiber Anemone",
		set = "holo_havoc",
		tint = C3(30, 210, 180),
		head = CF(0, 1.56, 0),
		neck = CF(0, -0.70, 0.80),
		back = CF(0, -0.40, -0.80),
		build = function(c, p)
			shine(c:cyl(V(1.40, 1.50, 1.50), CF(0, -0.42, 0) * UP, p.base, METAL), 0.4)
			shine(c:cyl(V(0.20, 1.90, 1.90), CF(0, 0.36, 0) * UP, p.dark, METAL), 0.4)
			shine(c:cyl(V(0.16, 1.80, 1.80), CF(0, -1.16, 0) * UP, CHROME, METAL), 0.5)
			c:eyes(-0.20, 0.72, 0.30, 0.17)
			smile(c, -0.56, 0.76, 0.26)
			cheeks(c, 0.50, -0.42, 0.58)
			for i = 0, 7 do
				local a = i / 8 * 2 * PI
				local tip = V(0.95 * math.cos(a), 1.20 + (i % 2) * 0.30, 0.95 * math.sin(a))
				c:rod(V(0.55 * math.cos(a), 0.46, 0.55 * math.sin(a)), tip, 0.04, p.light, GLASS, false).Transparency = 0.2
				c:ball(V(0.18, 0.18, 0.18), CF(tip), p.glow, NEON)
			end
			c:light(p.glow, 1.0, 6)
		end,
	}

	-- A film projector: twin reels for ears, a chrome lens and a cone of light.
	S.hh_t_projector = {
		label = "Reel Projector",
		set = "holo_havoc",
		tint = C3(255, 150, 40),
		scale = 1.1,
		head = CF(0, 1.66, 0),
		neck = CF(0, -0.60, 0.82),
		back = CF(0, 0.00, -0.84),
		build = function(c, p)
			shine(c:box(V(1.80, 1.20, 1.60), CF(0, -0.10, -0.06), p.base, METAL), 0.3)
			for _, z in ipairs({ 0.40, -0.50 }) do
				shine(c:cyl(V(0.14, 0.92, 0.92), CF(0, 1.06, z), p.dark, METAL), 0.4)
				shine(c:cyl(V(0.20, 0.26, 0.26), CF(0, 1.06, z), CHROME, METAL), 0.5)
				c:box(V(0.08, 0.40, 0.08), CF(0, 0.64, z), CHROME, METAL)
			end
			c:box(V(0.04, 0.04, 1.00), CF(0, 1.53, -0.05), INK)
			shine(c:cyl(V(0.36, 0.52, 0.52), CF(0, -0.06, 0.90) * FACE, CHROME, METAL), 0.5)
			c:cyl(V(0.04, 0.40, 0.40), CF(0, -0.06, 1.09) * FACE, p.glow, NEON)
			c:cone(V(0.80, 0.80, 0.80), CF(0, -0.06, 1.52) * A(-PI / 2, 0, 0), p.glow, NEON).Transparency = 0.7
			c:eyes(0.24, 0.80, 0.52, 0.15)
			smile(c, -0.50, 0.76, 0.26)
			for _, sx in ipairs(SIDES) do
				for _, sz in ipairs(SIDES) do
					c:box(V(0.26, 0.16, 0.26), CF(0.66 * sx, -0.78, 0.56 * sz), p.deep)
				end
			end
			shine(c:cyl(V(0.10, 0.30, 0.30), CF(0.94, -0.10, -0.30), CHROME, METAL), 0.5)
		end,
	}

	-- A disc standing on its edge: rainbow rings round the hole, little arms and legs.
	S.hh_t_platter = {
		label = "Optic Platter",
		set = "holo_havoc",
		tint = C3(210, 175, 255),
		scale = 1.15,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.60, 0.20),
		back = CF(0, 0.20, -0.16),
		build = function(c, p)
			shine(c:cyl(V(0.20, 2.10, 2.10), CF(0, 0.20, 0) * FACE, p.base, METAL), 0.6)
			shine(c:cyl(V(0.04, 1.70, 1.70), CF(0, 0.20, 0.11) * FACE, p.light, METAL), 0.6)
			shine(c:cyl(V(0.05, 1.12, 1.12), CF(0, 0.20, 0.12) * FACE, FOIL_A, METAL), 0.6)
			shine(c:cyl(V(0.06, 0.62, 0.62), CF(0, 0.20, 0.13) * FACE, FOIL_B, METAL), 0.6)
			c:cyl(V(0.08, 0.26, 0.26), CF(0, 0.20, 0.14) * FACE, INK)
			shine(c:cyl(V(0.04, 1.70, 1.70), CF(0, 0.20, -0.11) * FACE, p.light, METAL), 0.6)
			c:eyes(0.62, 0.16, 0.34, 0.15)
			smile(c, -0.20, 0.16, 0.28)
			c:box(V(0.06, 0.60, 0.02), CF(0.62, 0.70, 0.16) * A(0, 0, -0.7), WHITE).Transparency = 0.3
			for _, s in ipairs(SIDES) do
				c:rod(V(1.02 * s, 0.20, 0), V(1.34 * s, -0.16, 0.16), 0.06, p.dark, nil, false)
				c:ball(V(0.20, 0.20, 0.20), CF(1.36 * s, -0.18, 0.17), p.pale)
				c:rod(V(0.34 * s, -0.74, 0), V(0.40 * s, -1.04, 0.04), 0.06, p.dark, nil, false)
				c:box(V(0.26, 0.12, 0.36), CF(0.40 * s, -1.10, 0.10), p.deep)
			end
		end,
	}

	-- A chrome ibis with a tiny disco-ball crest and a pointed mirror bill (not a spoon).
	S.hh_t_ibis = {
		label = "Mirrorball Ibis",
		set = "holo_havoc",
		tint = C3(255, 120, 170),
		scale = 1.1,
		head = CF(0, 1.80, 0.60),
		neck = CF(0, 0.70, 0.62),
		back = CF(0, 0.92, -0.70),
		build = function(c, p)
			shine(c:round(V(1.30, 1.10, 1.60), CF(0, 0.40, -0.20), p.base, METAL), 0.25)
			for _, s in ipairs(SIDES) do
				shine(c:round(V(0.14, 0.80, 1.20), CF(0.66 * s, 0.46, -0.30), p.dark, METAL), 0.3)
				c:rod(V(0.24 * s, 0.00, -0.14), V(0.26 * s, -0.96, -0.06), 0.06, p.deep, nil, false)
				c:box(V(0.30, 0.06, 0.40), CF(0.26 * s, -0.99, 0.06), p.deep)
			end
			c:rod(V(0, 0.80, 0.40), V(0, 1.32, 0.56), 0.16, p.base, METAL, false)
			shine(c:round(V(0.62, 0.58, 0.62), CF(0, 1.46, 0.64), p.base, METAL), 0.25)
			c:eyes(1.54, 0.90, 0.18, 0.10)
			-- Pointed chrome bill, not a spoon bowl.
			shine(c:cone(V(0.22, 0.70, 0.22), CF(0, 1.36, 1.20) * A(PI / 2 + 0.25, 0, 0), CHROME, METAL), 0.65)
			c:wedge(V(0.50, 0.30, 0.50), CF(0, 0.60, -1.10), p.dark, METAL)
			cheeks(c, 0.24, 1.40, 0.92)
			-- Disco-ball crest: facets of foil and chrome.
			shine(c:ball(V(0.36, 0.36, 0.36), CF(0, 1.88, 0.56), CHROME, METAL), 0.55)
			for i = 0, 5 do
				local a = i / 6 * 2 * PI
				shine(c:box(V(0.10, 0.10, 0.04), CF(0.16 * math.cos(a), 1.88 + 0.16 * math.sin(a), 0.56 + 0.10) * A(a, a * 0.4, 0), (i % 2 == 0) and FOIL_A or FOIL_B, METAL), 0.6)
			end
			shine(c:cyl(V(0.06, 1.70, 1.70), CF(0, -1.04, 0) * UP, C3(160, 210, 255), GLASS), 0.6)
		end,
	}

	-- A little knight in crinkled tinfoil armour: visor, crest, plume, shield and sword.
	S.hh_t_knight = {
		label = "Tinfoil Knight",
		set = "holo_havoc",
		tint = C3(40, 70, 210),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.40, 0.86),
		back = CF(0, 0.20, -0.86),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				square = true, bodySize = V(1.80, 1.80, 1.70),
				eyeY = 0.12, eyeSize = V(0.34, 0.40, 0.20), eyeSpread = 0.36, mouth = false,
				legSize = V(0.44, 0.34, 0.50), legX = 0.50, legY = -0.90, legColor = p.dark,
				tail = false,
			})
			finish(c, from, METAL, 0.45)
			c:box(V(1.40, 0.50, 0.04), CF(0, 0.12, 0.86), INK)
			smile(c, -0.36, 0.87, 0.24)
			for _, s in ipairs(SIDES) do
				for _, v in ipairs({ { 0.40, 0.30 }, { -0.30, -0.30 } }) do
					shine(c:box(V(0.04, 0.40, 0.40), CF(0.91 * s, v[1], v[2]) * A(0.3, 0, 0.1 * s), p.light, METAL), 0.6)
				end
			end
			shine(c:box(V(0.16, 0.30, 1.40), CF(0, 1.10, 0), p.light, METAL), 0.5)
			shine(c:round(V(0.30, 0.60, 0.50), CF(0, 1.40, -0.50) * A(-0.4, 0, 0), FOIL_B, METAL), 0.4)
			shine(c:box(V(0.10, 0.90, 0.70), CF(-1.00, -0.10, 0.20), p.base, METAL), 0.5)
			c:star(V(-1.07, -0.08, 0.20), 0.36, p.glow)
			shine(c:box(V(0.08, 1.10, 0.16), CF(1.02, 0.30, 0.40) * A(0.2, 0, 0), CHROME, METAL), 0.6)
			c:box(V(0.10, 0.08, 0.44), CF(1.02, -0.22, 0.30), GOLD, METAL)
		end,
	}

	-- A lacewing under a tent of clear, rainbow-edged wings, with golden eyes.
	S.hh_t_lacewing = {
		label = "Sheer Lacewing",
		set = "holo_havoc",
		tint = C3(170, 255, 70),
		scale = 1.1,
		head = CF(0, 0.72, 0.90),
		neck = CF(0, -0.36, 1.12),
		back = CF(0, 0.96, -0.40),
		build = function(c, p)
			shine(c:round(V(0.90, 0.80, 0.90), CF(0, 0.00, 0.26), p.base, METAL), 0.3)
			shine(c:round(V(0.70, 0.60, 1.40), CF(0, -0.06, -0.76), p.base, METAL), 0.3)
			shine(c:round(V(0.90, 0.80, 0.70), CF(0, 0.10, 0.90), p.base, METAL), 0.3)
			for _, s in ipairs(SIDES) do
				c:eye(V(0.30 * s, 0.22, 1.18), 0.17, C3(255, 196, 60))
				for _, w in ipairs({ { 0.10, -0.10, 1.90 }, { -0.10, -0.40, 1.60 } }) do
					local wing = c:box(V(0.04, 0.80, w[3]), CF(0.48 * s, 0.56 + w[1], w[2]) * A(0, 0, 0.65 * s), p.pale, GLASS)
					wing.Transparency = 0.35
					wing.Reflectance = 0.4
				end
				c:box(V(0.03, 0.06, 1.70), CF(0.70 * s, 0.28, -0.10) * A(0, 0, 0.65 * s), FOIL_A, NEON)
				for _, z in ipairs({ 0.50, 0.26, 0.02 }) do
					c:rod(V(0.30 * s, -0.24, z), V(0.62 * s, -0.86, z + 0.10), 0.035, p.deep, nil, false)
				end
				local tip = V(0.56 * s, 1.18, 1.56)
				c:rod(V(0.14 * s, 0.44, 1.16), tip, 0.03, p.dark, nil, false)
				c:ball(V(0.14, 0.14, 0.14), CF(tip), p.glow, NEON)
			end
			smile(c, -0.12, 1.25, 0.20)
		end,
	}

	-- A glass light bulb with a glowing zig-zag filament and a chrome screw base.
	S.hh_t_bulb = {
		label = "Filament Bulb",
		set = "holo_havoc",
		tint = C3(255, 235, 110),
		head = CF(0, 1.38, 0),
		neck = CF(0, -0.40, 0.62),
		back = CF(0, 0.40, -0.92),
		build = function(c, p)
			local glass = c:ball(V(1.80, 1.80, 1.80), CF(0, 0.40, 0), p.light, GLASS)
			glass.Transparency = 0.35
			glass.Reflectance = 0.3
			c:cyl(V(0.60, 1.00, 1.00), CF(0, -0.56, 0) * UP, p.light, GLASS).Transparency = 0.35
			for _, b in ipairs({ { -0.92, 0.92, CHROME }, { -1.04, 0.98, p.dark }, { -1.14, 0.86, CHROME } }) do
				shine(c:cyl(V(0.14, b[2], b[2]), CF(0, b[1], 0) * UP, b[3], METAL), 0.5)
			end
			c:cyl(V(0.10, 0.40, 0.40), CF(0, -1.26, 0) * UP, INK)
			for _, s in ipairs(SIDES) do
				c:rod(V(0.18 * s, -0.40, 0), V(0.24 * s, 0.30, 0), 0.03, CHROME, METAL, false)
			end
			local zig = { V(-0.24, 0.30, 0), V(-0.08, 0.52, 0), V(0.08, 0.30, 0), V(0.24, 0.52, 0) }
			for i = 1, 3 do
				c:rod(zig[i], zig[i + 1], 0.04, p.glow, NEON, false)
			end
			c:ball(V(0.50, 0.50, 0.50), CF(0, 0.40, 0), p.glow, NEON).Transparency = 0.5
			c:eyes(0.50, 0.84, 0.32, 0.16)
			smile(c, 0.10, 0.88, 0.26)
			cheeks(c, 0.56, 0.28, 0.70)
			for _, s in ipairs(SIDES) do
				c:rod(V(0.80 * s, 0.10, 0), V(1.10 * s, -0.20, 0.16), 0.05, p.dark, nil, false)
				c:ball(V(0.18, 0.18, 0.18), CF(1.12 * s, -0.22, 0.18), p.pale)
			end
			c:light(p.glow, 1.2, 8)
		end,
	}

	---------------------------------------------------------------- LEGENDARY

	-- A kaleidoscope tube on stubby legs: a face on the cap, a gem rosette round
	-- the eyepiece, and its three inner mirrors standing up as a crest.
	S.hh_t_kaleidoscope = {
		label = "Twist Kaleidoscope",
		set = "holo_havoc",
		tint = C3(170, 100, 255),
		scale = 1.1,
		head = CF(0, 0.84, 0.40),
		neck = CF(0, -0.40, 1.16),
		back = CF(0, 0.74, -0.70),
		build = function(c, p)
			shine(c:cyl(V(2.20, 1.10, 1.10), CF(0, 0.10, 0) * FACE, p.base, METAL), 0.4)
			shine(c:cyl(V(0.12, 1.24, 1.24), CF(0, 0.10, 1.12) * FACE, CHROME, METAL), 0.5)
			c:eyes(0.28, 1.20, 0.24, 0.13)
			smile(c, -0.10, 1.20, 0.22)
			cheeks(c, 0.40, 0.02, 1.19)
			-- The turning chamber: a collar with grips, a back cap and the eyepiece.
			shine(c:cyl(V(0.36, 1.22, 1.22), CF(0, 0.10, -0.80) * FACE, p.dark, METAL), 0.4)
			for _, s in ipairs(SIDES) do
				c:box(V(0.08, 0.30, 0.30), CF(0.62 * s, 0.10, -0.80), p.light, METAL)
			end
			shine(c:cyl(V(0.10, 1.20, 1.20), CF(0, 0.10, -1.14) * FACE, CHROME, METAL), 0.5)
			shine(c:cyl(V(0.24, 0.40, 0.40), CF(0, 0.10, -1.28) * FACE, CHROME, METAL), 0.5)
			local hues = { FOIL_A, FOIL_B, p.glow, p.light, GOLD, p.pale }
			for i = 0, 5 do
				local a = i / 6 * 2 * PI
				gem(c, V(0.38 * math.cos(a), 0.10 + 0.38 * math.sin(a), -1.22), 0.18, hues[i + 1], (i == 2) and NEON or GLASS)
			end
			for _, z in ipairs({ 0.60, -0.10 }) do
				shine(c:cyl(V(0.10, 1.14, 1.14), CF(0, 0.10, z) * FACE, p.light, METAL), 0.6)
			end
			for k = -1, 1 do
				shine(c:wedge(V(0.06, 0.50, 0.40), CF(0.20 * k, 0.86, 0.10 - 0.30 * k * k) * A(0, 0, -0.25 * k), p.pale, GLASS), 0.6)
			end
			for _, sx in ipairs(SIDES) do
				for _, sz in ipairs({ 0.60, -0.50 }) do
					c:box(V(0.24, 0.40, 0.30), CF(0.30 * sx, -0.60, sz), p.deep)
				end
			end
		end,
	}

	-- A desk cradle of chrome balls on threads; the big middle ball has the face.
	S.hh_t_cradle = {
		label = "Pendulum Cradle",
		set = "holo_havoc",
		tint = C3(70, 200, 255),
		scale = 1.15,
		head = CF(0, 1.36, 0),
		neck = CF(0, -0.64, 0.50),
		back = CF(0, 0.20, -0.50),
		build = function(c, p)
			shine(c:box(V(2.80, 0.20, 1.10), CF(0, -0.98, 0), p.deep, METAL), 0.4)
			shine(c:box(V(0.80, 0.14, 0.04), CF(0, -0.98, 0.56), p.light, METAL), 0.5)
			gem(c, V(0, -0.98, 0.60), 0.10, p.glow, NEON)
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.40, -0.40 }) do
					c:rod(V(1.30 * s, -0.88, z), V(1.30 * s, 1.08, 0), 0.05, CHROME, METAL, false)
				end
				c:ball(V(0.22, 0.22, 0.22), CF(1.30 * s, 1.14, 0), p.glow, NEON)
			end
			shine(c:cyl(V(2.70, 0.10, 0.10), CF(0, 1.08, 0), CHROME, METAL), 0.6)
			for _, b in ipairs({ { -1.00, 0.40 }, { -0.60, 0.40 }, { 0.60, 0.40 }, { 1.00, 0.40 } }) do
				shine(c:ball(V(b[2], b[2], b[2]), CF(b[1], -0.24, 0), p.base, METAL), 0.6)
				c:rod(V(b[1], -0.04, 0), V(b[1], 1.04, 0), 0.015, INK, nil, false)
			end
			shine(c:ball(V(0.80, 0.80, 0.80), CF(0, -0.24, 0), p.base, METAL), 0.6)
			c:rod(V(0, 0.16, 0), V(0, 1.04, 0), 0.015, INK, nil, false)
			c:eyes(-0.14, 0.34, 0.15, 0.10)
			smile(c, -0.40, 0.36, 0.16)
			cheeks(c, 0.24, -0.30, 0.30)
			c:star(V(0.40, 0.30, 0.30), 0.26, WHITE)
		end,
	}

	-- A deep-keeled hatchetfish with mirror flanks, big upturned eyes and glowing dots.
	S.hh_t_hatchetfish = {
		label = "Silver Hatchetfish",
		set = "holo_havoc",
		tint = C3(120, 170, 255),
		head = CF(0, 0.98, 0.20),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.40, -0.90),
		build = function(c, p)
			shine(c:box(V(0.90, 1.10, 1.70), CF(0, 0.30, 0), p.base, METAL), 0.4)
			shine(c:cone(V(0.86, 1.00, 1.60), CF(0, -0.75, 0) * A(PI, 0, 0), p.base, METAL), 0.4)
			shine(c:box(V(0.94, 0.06, 1.74), CF(0, 0.86, 0), CHROME, METAL), 0.6)
			for _, s in ipairs(SIDES) do
				shine(c:box(V(0.04, 1.00, 1.40), CF(0.47 * s, 0.10, 0.02), p.light, METAL), 0.8)
				c:eye(V(0.36 * s, 0.66, 0.84), 0.20)
				c:box(V(0.04, 0.30, 0.90), CF(0.56 * s, -0.20, -0.10) * A(0.5, 0, 0.6 * s), p.pale, GLASS).Transparency = 0.3
				shine(c:box(V(0.06, 0.40, 0.50), CF(0.12 * s, 0.30, -1.06) * A(0, 0.4 * s, 0), p.dark, METAL), 0.4)
				for _, z in ipairs({ 0.50, 0.00, -0.50 }) do
					c:ball(V(0.10, 0.10, 0.10), CF(0.49 * s, -0.20, z), p.glow, NEON)
				end
			end
			c:box(V(0.24, 0.08, 0.06), CF(0, 0.20, 0.88) * A(0, 0, 0.2), INK)
			shine(c:wedge(V(0.10, 0.40, 0.70), CF(0, 1.05, -0.40), p.dark, METAL), 0.4)
			for _, b in ipairs({ { 0.30, 1.30, 0.70, 0.18 }, { 0.55, 1.55, 0.50, 0.12 } }) do
				c:ball(V(b[4], b[4], b[4]), CF(b[1], b[2], b[3]), p.pale, GLASS).Transparency = 0.4
			end
		end,
	}

	-- A funhouse mirror on legs: a wobbly frame and a stretched reflection for a face.
	S.hh_t_funhouse = {
		label = "Wobbly Funhouse",
		set = "holo_havoc",
		tint = C3(0, 190, 120),
		scale = 1.15,
		head = CF(0, 1.66, 0),
		neck = CF(0, -0.70, 0.20),
		back = CF(0, 0.30, -0.20),
		build = function(c, p)
			shine(c:round(V(1.46, 2.06, 0.08), CF(0, 0.25, 0.02), p.pale, GLASS), 0.8)
			local n = 10
			local pts = {}
			for i = 0, n do
				local a = i / n * 2 * PI
				local w = 1 + 0.10 * math.sin(4 * a)
				pts[i] = V(0.78 * math.cos(a) * w, 0.25 + 1.05 * math.sin(a) * w, 0)
			end
			for i = 1, n do
				shine(c:rod(pts[i - 1], pts[i], 0.09, (i % 2 == 0) and p.base or p.light, METAL, false), 0.4)
			end
			-- The stretched reflection: tall eyes and a wavy grin.
			for _, s in ipairs(SIDES) do
				c:round(V(0.30, 0.74, 0.08), CF(0.30 * s, 0.60, 0.08), INK):SetAttribute("Eye", true)
				c:round(V(0.12, 0.20, 0.04), CF(0.34 * s, 0.82, 0.12), WHITE):SetAttribute("Eye", true)
				c:rod(V(0.36 * s, -0.74, 0), V(0.42 * s, -1.06, 0.06), 0.05, CHROME, METAL, false)
				c:box(V(0.26, 0.12, 0.36), CF(0.42 * s, -1.12, 0.12), p.deep)
				c:rod(V(0.82 * s, 0.25, 0), V(1.18 * s, -0.08, 0.18), 0.05, p.base, METAL, false)
				c:ball(V(0.22, 0.22, 0.22), CF(1.20 * s, -0.10, 0.19), WHITE)
			end
			for k = -1, 1 do
				c:box(V(0.24, 0.07, 0.04), CF(0.19 * k, (k == 0) and -0.22 or -0.15, 0.08) * A(0, 0, -0.45 * k), INK)
			end
			c:cone(V(0.40, 0.36, 0.16), CF(0, 1.48, 0), p.glow, NEON)
			c:star(V(0, 1.78, 0.02), 0.26, WHITE)
		end,
	}

	-- A stage spotlight on a tripod: barn doors, cooling fins and a cone of light.
	S.hh_t_spotlight = {
		label = "Stage Spotlight",
		set = "holo_havoc",
		tint = C3(255, 60, 60),
		scale = 1.1,
		head = CF(0, 1.16, -0.10),
		neck = CF(0, -0.50, 0.60),
		back = CF(0, 0.30, -0.96),
		build = function(c, p)
			shine(c:cyl(V(1.50, 1.30, 1.30), CF(0, 0.30, 0) * FACE, p.base, METAL), 0.4)
			shine(c:cyl(V(0.14, 1.44, 1.44), CF(0, 0.30, 0.78) * FACE, CHROME, METAL), 0.5)
			c:cyl(V(0.06, 1.16, 1.16), CF(0, 0.30, 0.86) * FACE, p.glow, NEON)
			c:eyes(0.44, 0.92, 0.24, 0.14)
			smile(c, 0.10, 0.90, 0.24)
			-- Barn doors swung open round the lens.
			shine(c:box(V(1.30, 0.06, 0.50), CF(0, 1.14, 1.07) * A(-0.5, 0, 0), p.dark, METAL), 0.3)
			shine(c:box(V(1.30, 0.06, 0.50), CF(0, -0.54, 1.07) * A(0.5, 0, 0), p.dark, METAL), 0.3)
			for _, s in ipairs(SIDES) do
				shine(c:box(V(0.06, 1.10, 0.50), CF(0.84 * s, 0.30, 1.07) * A(0, 0.5 * s, 0), p.dark, METAL), 0.3)
				c:box(V(0.10, 0.90, 0.20), CF(0.74 * s, -0.10, 0), CHROME, METAL)
				c:cyl(V(0.10, 0.24, 0.24), CF(0.82 * s, 0.30, 0), INK)
			end
			c:cone(V(1.10, 0.90, 1.10), CF(0, 0.30, 1.50) * A(-PI / 2, 0, 0), p.glow, NEON).Transparency = 0.75
			c:box(V(1.58, 0.10, 0.20), CF(0, -0.55, 0), CHROME, METAL)
			shine(c:cyl(V(0.40, 0.14, 0.14), CF(0, -0.78, 0) * UP, CHROME, METAL), 0.5)
			for i = 0, 2 do
				local a = PI / 2 + i * 2 * PI / 3
				c:rod(V(0, -0.94, 0), V(0.70 * math.cos(a), -1.12, 0.70 * math.sin(a)), 0.04, p.deep, nil, false)
			end
			for _, z in ipairs({ -0.80, -0.90, -1.00 }) do
				shine(c:cyl(V(0.04, 1.10, 1.10), CF(0, 0.30, z) * FACE, p.dark, METAL), 0.3)
			end
			c:star(V(0.50, 0.70, 1.00), 0.30, WHITE)
		end,
	}

	-- A party streamer twisting up from its spool to a flat foil face with a bow.
	S.hh_t_streamer = {
		label = "Party Streamer",
		set = "holo_havoc",
		tint = C3(255, 90, 200),
		head = CF(0, 1.66, 0.56),
		neck = CF(0, 0.50, 0.72),
		back = CF(0, 0.00, -0.60),
		build = function(c, p)
			local pts = {}
			for i = 0, 12 do
				local t = i / 12
				pts[i] = V(0.80 * math.sin(t * 3 * PI), -0.86 + 1.66 * t, -0.90 + 1.40 * t)
			end
			for i = 1, 12 do
				local a, b = pts[i - 1], pts[i]
				shine(c:box(V(0.52, 0.06, (b - a).Magnitude + 0.08), CFrame.lookAt((a + b) * 0.5, b) * A(0, 0, i * 0.45), (i % 2 == 0) and p.base or p.light, METAL), 0.5)
			end
			shine(c:cyl(V(0.52, 0.36, 0.36), CF(0, -0.74, -1.02), p.light, METAL), 0.5)
			shine(c:box(V(0.95, 0.78, 0.16), CF(0, 1.10, 0.56), p.base, METAL), 0.5)
			c:eyes(1.18, 0.68, 0.20, 0.12)
			smile(c, 0.92, 0.66, 0.20)
			cheeks(c, 0.34, 0.98, 0.65)
			-- A foil bow on top.
			for _, s in ipairs(SIDES) do
				shine(c:cone(V(0.30, 0.36, 0.20), CF(0.18 * s, 1.62, 0.56) * A(0, 0, PI / 2 * s), (s > 0) and FOIL_A or FOIL_B, METAL), 0.5)
			end
			c:ball(V(0.14, 0.14, 0.14), CF(0, 1.62, 0.56), p.glow, NEON)
			for i, q in ipairs({ { -0.70, 1.30, 0.20 }, { 0.80, 1.10, -0.20 }, { 0.50, 1.70, 0.10 } }) do
				c:box(V(0.14, 0.14, 0.04), CF(q[1], q[2], q[3]) * A(i, i * 0.6, 0), (i % 2 == 0) and FOIL_B or FOIL_A, NEON)
			end
		end,
	}

	-- A polished aluminium caravan: ribbed shell, window eyes, wheels, an awning.
	S.hh_t_caravan = {
		label = "Aluminium Caravan",
		set = "holo_havoc",
		tint = C3(100, 140, 200),
		scale = 1.1,
		head = CF(0, 0.92, 0.20),
		neck = CF(0, -0.40, 1.28),
		back = CF(0, 0.20, -1.26),
		build = function(c, p)
			shine(c:round(V(1.60, 1.40, 2.40), CF(0, 0.12, 0), p.base, METAL), 0.6)
			for _, z in ipairs({ 0.60, 0, -0.60 }) do
				shine(c:round(V(1.66, 1.46, 0.06), CF(0, 0.12, z), p.light, METAL), 0.6)
			end
			for _, s in ipairs(SIDES) do
				shine(c:round(V(0.50, 0.38, 0.08), CF(0.36 * s, 0.38, 1.13), C3(150, 210, 255), GLASS), 0.5)
				c:eye(V(0.36 * s, 0.38, 1.18), 0.14)
				for _, z in ipairs({ 0.62, -0.62 }) do
					c:cyl(V(0.24, 0.60, 0.60), CF(0.78 * s, -0.56, z), INK)
					shine(c:cyl(V(0.26, 0.30, 0.30), CF(0.80 * s, -0.56, z), CHROME, METAL), 0.6)
				end
			end
			smile(c, -0.20, 1.18, 0.40)
			c:rod(V(0, -0.40, 1.10), V(0, -0.56, 1.56), 0.05, CHROME, METAL, false)
			c:ball(V(0.16, 0.16, 0.16), CF(0, -0.58, 1.60), INK)
			shine(c:box(V(0.04, 0.80, 0.40), CF(0.80, 0.05, -0.20), p.light, METAL), 0.5)
			c:cyl(V(0.04, 0.16, 0.16), CF(0.83, 0.25, -0.20), C3(150, 210, 255), GLASS)
			for k = -1, 1 do
				c:box(V(0.30, 0.04, 0.18), CF(0.92, 0.56, -0.20 + k * 0.18) * A(0, 0, -0.4), (k == 0) and FOIL_B or FOIL_A, METAL)
			end
			shine(c:box(V(0.40, 0.12, 0.40), CF(0, 0.86, -0.40), CHROME, METAL), 0.5)
			c:box(V(0.30, 0.12, 0.04), CF(0, -0.20, -1.20), C3(255, 60, 60), NEON)
			c:star(V(-0.50, 0.70, 0.50), 0.30, WHITE)
		end,
	}

	-- A fox folded from holographic paper: a ridged back, a diamond head, sharp ears.
	S.hh_t_origami = {
		label = "Holofold Origami",
		set = "holo_havoc",
		tint = C3(40, 220, 140),
		head = CF(0, 1.30, 0.90),
		neck = CF(0, 0.00, 1.24),
		back = CF(0, 0.70, -0.60),
		build = function(c, p)
			shine(c:prism(V(1.80, 1.10, 1.80), CF(0, 0.12, -0.10) * A(0, PI / 2, 0), p.base, METAL), 0.4)
			for _, s in ipairs(SIDES) do
				shine(c:box(V(0.03, 0.70, 1.20), CF(0.47 * s, 0.14, -0.10) * A(0, 0, 0.686 * s), (s > 0) and FOIL_A or FOIL_B, METAL), 0.6)
				c:eye(V(0.24 * s, 0.66, 1.30), 0.10)
				shine(c:cone(V(0.30, 0.55, 0.16), CF(0.26 * s, 1.20, 0.90) * A(0, 0, -0.2 * s), p.base, METAL), 0.4)
				for _, z in ipairs({ 0.50, -0.60 }) do
					c:box(V(0.18, 0.70, 0.26), CF(0.42 * s, -0.62, z) * A(0, 0, 0.1 * s), p.dark, METAL)
				end
			end
			shine(c:box(V(0.80, 0.80, 0.80), CF(0, 0.55, 0.95) * A(0, PI / 4, 0), p.light, METAL), 0.4)
			c:cone(V(0.40, 0.50, 0.40), CF(0, 0.40, 1.66) * A(PI / 2, 0, 0), p.light, METAL)
			c:box(V(0.10, 0.10, 0.10), CF(0, 0.40, 1.92), INK)
			c:cone(V(0.30, 1.00, 0.20), CF(0, 0.70, -1.25) * A(-0.6, 0, 0), p.light, METAL)
			c:box(V(0.06, 0.06, 1.80), CF(0, 0.68, -0.10), p.pale, NEON)
			c:wedge(V(0.80, 0.50, 0.30), CF(0, -0.10, 0.85), p.pale)
			c:star(V(0.60, 0.90, -0.40), 0.30, WHITE)
		end,
	}

	-- A narwhal whose spiral tusk is a laser, its tip shining a short beam.
	S.hh_t_narwhal = {
		label = "Laser Narwhal",
		set = "holo_havoc",
		tint = C3(60, 90, 200),
		scale = 1.3,
		head = CF(0, 0.78, 0.20),
		neck = CF(0, -0.42, 0.90),
		back = CF(0, 0.40, -1.00),
		build = function(c, p)
			shine(c:round(V(1.50, 1.30, 2.20), CF(0, 0, -0.10), p.base, METAL), 0.3)
			c:round(V(1.30, 0.70, 1.80), CF(0, -0.36, 0), p.pale)
			for _, s in ipairs(SIDES) do
				c:box(V(0.06, 0.12, 0.22), CF(0.76 * s, 0.24, -0.40), p.dark)
				c:box(V(0.06, 0.10, 0.18), CF(0.75 * s, 0.00, 0.10), p.dark)
				c:box(V(0.60, 0.08, 0.36), CF(0.30 * s, 0.10, -1.30) * A(0, 0.4 * s, 0.15 * s), p.dark, METAL)
				c:box(V(0.40, 0.08, 0.30), CF(0.80 * s, -0.30, 0.30) * A(0, 0, -0.4 * s), p.dark)
			end
			c:eyes(0.16, 0.94, 0.40, 0.14)
			smile(c, -0.20, 0.98, 0.26)
			cheeks(c, 0.50, -0.02, 0.74)
			-- The tusk: chrome with spiral ridges, a glowing tip and a beam.
			local from, to = V(0.10, 0.30, 0.95), V(0.22, 0.70, 1.60)
			local dir = (to - from).Unit
			shine(c:rod(from, to, 0.07, CHROME, METAL, false), 0.6)
			for _, t in ipairs({ 0.25, 0.50, 0.75 }) do
				local at = from + (to - from) * t
				c:cyl(V(0.04, 0.20 - t * 0.06, 0.20 - t * 0.06), CFrame.lookAt(at, at + dir) * A(0, PI / 2, 0), p.light, METAL)
			end
			c:ball(V(0.18, 0.18, 0.18), CF(to), p.glow, NEON)
			c:rod(to, to + dir * 0.30, 0.04, p.glow, NEON, false).Transparency = 0.3
			for _, b in ipairs({ { 0.50, 0.90, 0.80, 0.18 }, { 0.70, 1.20, 0.60, 0.12 } }) do
				c:ball(V(b[4], b[4], b[4]), CF(b[1], b[2], b[3]), p.pale, GLASS).Transparency = 0.4
			end
		end,
	}

	-- A shaggy yak hung all over with a party fringe of foil strips, chrome horns.
	S.hh_t_yak = {
		label = "Foilfringe Yak",
		set = "holo_havoc",
		tint = C3(255, 170, 80),
		scale = 1.1,
		head = CF(0, 1.36, 0.10),
		neck = CF(0, -0.46, 0.96),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				bodySize = V(2.00, 1.60, 1.86),
				eyeY = 0.20, eyeSpread = 0.46, eyeSize = V(0.40, 0.46, 0.20),
				snout = { w = 0.90, h = 0.50, d = 0.40, y = -0.30, color = p.pale, nose = INK },
				legColor = p.deep, legSize = V(0.46, 0.40, 0.50), legX = 0.60,
				tail = false,
			})
			finish(c, from, METAL, 0.25)
			shine(c:round(V(1.40, 0.60, 1.20), CF(0, 0.90, -0.10), p.base, METAL), 0.25)
			local strips = { FOIL_A, p.light, FOIL_B, p.pale, FOIL_A }
			for _, s in ipairs(SIDES) do
				c:rod(V(0.70 * s, 0.80, 0.30), V(1.20 * s, 1.00, 0.40), 0.09, CHROME, METAL, false)
				c:rod(V(1.20 * s, 1.00, 0.40), V(1.30 * s, 1.40, 0.30), 0.07, CHROME, METAL, false)
				for k = 0, 4 do
					shine(c:box(V(0.04, 1.10, 0.20), CF(1.03 * s, -0.10, 0.64 - k * 0.32) * A((k % 2 == 0) and 0.06 or -0.06, 0, 0), strips[k + 1], METAL), 0.6)
				end
			end
			for k = -1, 1 do
				shine(c:box(V(0.26, 0.40, 0.04), CF(0.32 * k, 0.70, 0.95) * A(0, 0, 0.12 * k), (k == 0) and FOIL_B or FOIL_A, METAL), 0.6)
			end
			c:round(V(0.40, 0.40, 0.50), CF(0, 0.20, -1.06), p.light, METAL)
		end,
	}

	-- A roll of kitchen foil in its box: the serrated edge is a toothy grin and a
	-- sheet rolls out like a tongue.
	S.hh_t_foilroll = {
		label = "Kitchen Foilroll",
		set = "holo_havoc",
		tint = C3(230, 230, 240),
		scale = 1.1,
		head = CF(0, 0.78, -0.10),
		neck = CF(0, -0.30, 0.66),
		back = CF(0, 0.20, -0.66),
		build = function(c, p)
			c:box(V(2.20, 0.90, 1.00), CF(0, -0.42, 0), p.dark)
			shine(c:cyl(V(2.00, 0.80, 0.80), CF(0, 0.12, -0.04), p.base, METAL), 0.6)
			for _, s in ipairs(SIDES) do
				c:cyl(V(0.06, 0.34, 0.34), CF(1.01 * s, 0.12, -0.04), C3(190, 150, 100))
			end
			c:box(V(2.20, 0.80, 0.06), CF(0, 0.24, -0.62) * A(-0.35, 0, 0), p.dark)
			c:eyes(0.28, 0.36, 0.40, 0.14)
			cheeks(c, 0.62, 0.16, 0.37)
			for k = -2, 2 do
				shine(c:box(V(0.11, 0.11, 0.04), CF(0.16 * k, 0.03, 0.52) * A(0, 0, PI / 4), CHROME, METAL), 0.5)
			end
			local a, b = V(0, 0.03, 0.50), V(0, -0.86, 1.20)
			shine(c:box(V(1.40, 0.04, (b - a).Magnitude), CFrame.lookAt((a + b) * 0.5, b), p.light, METAL), 0.7)
			for _, q in ipairs({ { -0.35, -0.40, 0.86 }, { 0.30, -0.64, 1.02 } }) do
				shine(c:box(V(0.20, 0.04, 0.16), CF(q[1], q[2], q[3]) * A(0.8, 0.5, 0.3), p.pale, METAL), 0.7)
			end
			for _, sx in ipairs(SIDES) do
				for _, sz in ipairs(SIDES) do
					c:box(V(0.30, 0.12, 0.30), CF(0.80 * sx, -0.92, 0.30 * sz), p.deep)
				end
			end
			c:star(V(-0.55, 0.40, 0.30), 0.30, WHITE)
		end,
	}

	-- A sequinned ostrich: a fan plume tipped with sequins, long legs, fluttery lashes.
	S.hh_t_ostrich = {
		label = "Sequin Ostrich",
		set = "holo_havoc",
		tint = C3(255, 80, 40),
		scale = 1.15,
		head = CF(0, 2.00, 0.70),
		neck = CF(0, 1.10, 0.62),
		back = CF(0, 0.92, -0.60),
		build = function(c, p)
			shine(c:round(V(1.40, 1.10, 1.50), CF(0, 0.30, -0.20), p.base, METAL), 0.3)
			local root = V(0, 0.40, -0.95)
			for i = -2, 2 do
				local a = i * 0.38
				local tip = V(1.05 * math.sin(a), 0.40 + 1.05 * math.cos(a), -1.05)
				shine(c:round(V(0.34, 0.80, 0.14), CF((root + tip) * 0.5) * A(0, 0, -a), (i % 2 == 0) and p.light or FOIL_B, METAL), 0.5)
				c:cyl(V(0.04, 0.24, 0.24), CF(tip) * FACE, (i % 2 == 0) and FOIL_A or p.glow, (i % 2 == 0) and METAL or NEON)
			end
			for _, s in ipairs(SIDES) do
				shine(c:round(V(0.16, 0.70, 1.00), CF(0.72 * s, 0.36, -0.30), p.light, METAL), 0.4)
				c:box(V(0.12, 0.03, 0.03), CF(0.17 * s, 1.88, 0.96) * A(0, 0, 0.4 * s), INK)
				c:rod(V(0.26 * s, -0.10, -0.20), V(0.30 * s, -1.00, -0.06), 0.07, p.deep, nil, false)
				c:box(V(0.26, 0.08, 0.40), CF(0.30 * s, -1.03, 0.10), p.deep)
				for _, v in ipairs({ { 0.71, 0.40, -0.20 }, { 0.61, 0.10, 0.20 } }) do
					shine(c:cyl(V(0.04, 0.20, 0.20), CF(v[1] * s, v[2], v[3]), FOIL_A, METAL), 0.6)
				end
			end
			c:rod(V(0, 0.76, 0.36), V(0, 1.56, 0.62), 0.12, p.pale, nil, false)
			shine(c:round(V(0.46, 0.44, 0.56), CF(0, 1.70, 0.70), p.pale, METAL), 0.2)
			c:box(V(0.20, 0.08, 0.30), CF(0, 1.62, 1.04), C3(255, 190, 120))
			c:eyes(1.76, 0.92, 0.14, 0.08)
			c:cone(V(0.10, 0.30, 0.10), CF(0, 2.04, 0.66), p.glow, NEON)
		end,
	}

	---------------------------------------------------------------- MYTHIC

	-- A walk-in infinity mirror: chrome frame, glass pane, and nested glowing rings.
	S.hh_t_infinity = {
		label = "Infinity Mirror",
		set = "holo_havoc",
		tint = C3(80, 200, 255),
		scale = 1.15,
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.60, 0.20),
		back = CF(0, 0.20, -0.20),
		build = function(c, p)
			shine(c:box(V(2.00, 2.40, 0.20), CF(0, 0.20, -0.10), CHROME, METAL), 0.5)
			shine(c:box(V(1.70, 2.10, 0.06), CF(0, 0.20, 0.02), p.pale, GLASS), 0.7)
			c:box(V(1.50, 1.90, 0.04), CF(0, 0.20, -0.16), INK)
			for i, r in ipairs({ 1.40, 1.00, 0.60, 0.28 }) do
				local col = (i % 2 == 0) and FOIL_A or FOIL_B
				shine(c:cyl(V(0.04, r, r), CF(0, 0.20, 0.06) * FACE, col, (i == 4) and NEON or METAL), 0.5)
			end
			c:eyes(0.50, 0.14, 0.36, 0.14)
			smile(c, -0.10, 0.12, 0.22)
			cheeks(c, 0.50, 0.10, 0.12)
			for _, s in ipairs(SIDES) do
				c:rod(V(0.80 * s, -0.80, 0), V(0.90 * s, -1.10, 0.08), 0.05, CHROME, METAL, false)
				c:box(V(0.28, 0.12, 0.36), CF(0.90 * s, -1.16, 0.12), p.deep)
				c:rod(V(1.02 * s, 0.20, 0), V(1.28 * s, -0.10, 0.16), 0.05, p.base, METAL, false)
				c:ball(V(0.20, 0.20, 0.20), CF(1.30 * s, -0.12, 0.17), WHITE)
			end
			c:star(V(0.70, 1.20, 0.14), 0.28, WHITE)
			c:light(p.glow, 1.2, 7)
		end,
	}

	-- A toucan whose beak splits into red and cyan anaglyph halves, offset in depth.
	S.hh_t_anaglyph = {
		label = "Anaglyph Toucan",
		set = "holo_havoc",
		tint = C3(255, 50, 70),
		scale = 1.12,
		head = CF(0, 1.50, 0.50),
		neck = CF(0, 0.40, 0.70),
		back = CF(0, 0.80, -0.70),
		build = function(c, p)
			shine(c:round(V(1.20, 1.00, 1.40), CF(0, 0.30, -0.20), p.base, METAL), 0.3)
			for _, s in ipairs(SIDES) do
				shine(c:round(V(0.12, 0.70, 1.00), CF(0.62 * s, 0.36, -0.30), p.dark, METAL), 0.35)
				c:rod(V(0.22 * s, -0.10, -0.10), V(0.26 * s, -0.96, 0), 0.06, p.deep, nil, false)
				c:box(V(0.28, 0.08, 0.36), CF(0.26 * s, -1.00, 0.08), p.deep)
			end
			c:rod(V(0, 0.70, 0.30), V(0, 1.20, 0.50), 0.14, p.base, METAL, false)
			shine(c:round(V(0.70, 0.64, 0.70), CF(0, 1.36, 0.56), p.base, METAL), 0.3)
			c:eyes(1.44, 0.84, 0.20, 0.11)
			cheeks(c, 0.26, 1.28, 0.86)
			-- Red/cyan 3D beak: one half pushed forward.
			shine(c:wedge(V(0.36, 0.40, 0.90), CF(-0.14, 1.20, 1.20) * A(0.2, 0.1, 0), RED3D, METAL), 0.4)
			shine(c:wedge(V(0.36, 0.40, 0.90), CF(0.18, 1.24, 1.34) * A(0.2, -0.1, 0), CYAN3D, METAL), 0.4)
			c:wedge(V(0.46, 0.28, 0.46), CF(0, 0.50, -1.00), p.dark, METAL)
			for _, q in ipairs({ { -0.40, 1.70, 0.40, RED3D }, { 0.44, 1.66, 0.50, CYAN3D } }) do
				c:ball(V(0.16, 0.16, 0.16), CF(q[1], q[2], q[3]), q[4], NEON)
			end
			c:star(V(-0.50, 0.80, 0.20), 0.26, WHITE)
		end,
	}

	-- A porcupine bristling with glowing fibre-optic quills tipped in foil beads.
	S.hh_t_porcupine = {
		label = "Fibreoptic Porcupine",
		set = "holo_havoc",
		tint = C3(160, 90, 255),
		scale = 1.1,
		head = CF(0, 0.90, 0.80),
		neck = CF(0, -0.30, 1.10),
		back = CF(0, 0.70, -0.70),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				bodySize = V(1.80, 1.40, 1.90),
				eyeY = 0.16, eyeSpread = 0.40, eyeSize = V(0.36, 0.40, 0.18),
				snout = { w = 0.70, h = 0.40, d = 0.36, y = -0.20, color = p.pale, nose = INK },
				legSize = V(0.40, 0.34, 0.44), legX = 0.52, legColor = p.deep,
				tail = false,
			})
			finish(c, from, METAL, 0.25)
			local tips = {
				{ -0.50, 1.10, -0.20 }, { 0, 1.20, -0.40 }, { 0.50, 1.10, -0.20 },
				{ -0.70, 0.80, -0.60 }, { 0.70, 0.80, -0.60 }, { 0, 0.90, -0.90 },
				{ -0.40, 1.00, 0.20 }, { 0.40, 1.00, 0.20 },
			}
			for i, tip in ipairs(tips) do
				local root = V(tip[1] * 0.4, 0.40, tip[3] * 0.3)
				local endP = V(tip[1], tip[2], tip[3])
				c:rod(root, endP, 0.035, (i % 2 == 0) and FOIL_A or FOIL_B, NEON, false)
				c:ball(V(0.12, 0.12, 0.12), CF(endP), (i % 3 == 0) and p.glow or CHROME, (i % 3 == 0) and NEON or METAL)
			end
			cheeks(c, 0.36, -0.06, 0.92)
			c:light(p.glow, 1.1, 6)
		end,
	}

	-- Overlapping stripe discs that moiré into ripples; a face peeks through the centre.
	S.hh_t_moire = {
		label = "Moire Ripple",
		set = "holo_havoc",
		tint = C3(40, 220, 180),
		scale = 1.12,
		head = CF(0, 0.90, 0.10),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			shine(c:cyl(V(0.16, 2.00, 2.00), CF(0, 0.10, 0) * FACE, p.base, METAL), 0.4)
			for i = 0, 7 do
				local a = i / 8 * PI
				local col = (i % 2 == 0) and INK or p.light
				shine(c:box(V(1.90, 0.08, 0.06), CF(0, 0.10, 0.04) * A(0, 0, a), col, METAL), 0.35)
			end
			shine(c:cyl(V(0.12, 1.70, 1.70), CF(0, 0.10, 0.10) * FACE * A(0, 0, 0.22), p.pale, GLASS), 0.5)
			for i = 0, 5 do
				local a = i / 6 * PI + 0.15
				shine(c:box(V(1.50, 0.06, 0.04), CF(0, 0.10, 0.14) * A(0, 0, a), (i % 2 == 0) and FOIL_A or FOIL_B, METAL), 0.55)
			end
			shine(c:ball(V(0.90, 0.90, 0.50), CF(0, 0.10, 0.30), p.base, METAL), 0.3)
			c:eyes(0.20, 0.52, 0.26, 0.12)
			smile(c, -0.10, 0.52, 0.20)
			cheeks(c, 0.30, 0.00, 0.48)
			for _, s in ipairs(SIDES) do
				c:box(V(0.24, 0.40, 0.30), CF(0.50 * s, -0.70, 0.20), p.deep)
				c:box(V(0.24, 0.40, 0.30), CF(0.50 * s, -0.70, -0.40), p.deep)
			end
			c:star(V(0.60, 0.80, 0.40), 0.26, WHITE)
		end,
	}

	---------------------------------------------------------------- DIVINE

	-- A radiant plano lens in a chrome mount, ringed by a soft aureole of light.
	S.hh_t_aureole = {
		label = "Aureole Lens",
		set = "holo_havoc",
		tint = C3(255, 220, 120),
		scale = 1.14,
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.50, 0.60),
		back = CF(0, 0.20, -0.60),
		build = function(c, p)
			shine(c:cyl(V(0.40, 1.80, 1.80), CF(0, 0.20, 0) * FACE, CHROME, METAL), 0.55)
			local glass = c:cyl(V(0.30, 1.50, 1.50), CF(0, 0.20, 0.10) * FACE, p.light, GLASS)
			glass.Transparency = 0.25
			glass.Reflectance = 0.5
			c:cyl(V(0.06, 1.20, 1.20), CF(0, 0.20, 0.28) * FACE, p.glow, NEON)
			c:eyes(0.36, 0.40, 0.30, 0.13)
			smile(c, -0.04, 0.38, 0.22)
			cheeks(c, 0.44, 0.08, 0.36)
			-- Soft aureole rings behind the lens.
			for _, r in ipairs({ 2.20, 2.50 }) do
				shine(c:cyl(V(0.04, r, r), CF(0, 0.20, -0.30) * FACE, (r > 2.3) and GOLD or FOIL_A, NEON), 0.3)
			end
			for i = 0, 5 do
				local a = i / 6 * 2 * PI
				c:ball(V(0.16, 0.16, 0.16), CF(1.10 * math.cos(a), 0.20 + 1.10 * math.sin(a), -0.20), p.glow, NEON)
			end
			for _, s in ipairs(SIDES) do
				c:rod(V(0.60 * s, -0.60, 0), V(0.70 * s, -1.00, 0.06), 0.05, CHROME, METAL, false)
				c:box(V(0.28, 0.12, 0.34), CF(0.70 * s, -1.06, 0.10), p.deep)
			end
			c:light(p.glow, 1.6, 9)
			c:sparkle(p.glow, 4, 0.5, 0.16)
		end,
	}

	-- A shallow chrome pool whose surface throws bright caustic blobs of light.
	S.hh_t_caustic = {
		label = "Caustic Pool",
		set = "holo_havoc",
		tint = C3(60, 180, 255),
		scale = 1.12,
		head = CF(0, 0.70, 0.10),
		neck = CF(0, -0.30, 0.90),
		back = CF(0, 0.10, -0.90),
		build = function(c, p)
			shine(c:cyl(V(0.50, 2.20, 2.20), CF(0, -0.50, 0) * UP, CHROME, METAL), 0.5)
			shine(c:cyl(V(0.20, 2.40, 2.40), CF(0, -0.20, 0) * UP, CHROME, METAL), 0.55)
			local water = c:cyl(V(0.10, 2.00, 2.00), CF(0, -0.08, 0) * UP, C3(120, 200, 255), GLASS)
			water.Transparency = 0.35
			water.Reflectance = 0.6
			shine(c:ball(V(1.00, 0.70, 1.00), CF(0, 0.20, 0), p.base, METAL), 0.4)
			c:eyes(0.30, 0.48, 0.28, 0.12)
			smile(c, 0.00, 0.48, 0.20)
			cheeks(c, 0.34, 0.10, 0.44)
			-- Caustic light blobs dancing on the rim.
			for i, q in ipairs({
				{ -0.70, 0.00, 0.60 }, { 0.60, 0.06, 0.70 }, { 0.80, -0.04, -0.30 },
				{ -0.50, 0.08, -0.70 }, { 0.10, 0.12, -0.90 }, { -0.90, 0.02, 0.10 },
			}) do
				c:ball(V(0.22, 0.08, 0.28), CF(q[1], q[2], q[3]) * A(0, i * 0.5, 0), (i % 2 == 0) and p.glow or FOIL_A, NEON)
			end
			for _, s in ipairs(SIDES) do
				c:box(V(0.20, 0.30, 0.24), CF(0.70 * s, -0.90, 0.40), p.deep)
				c:box(V(0.20, 0.30, 0.24), CF(0.70 * s, -0.90, -0.50), p.deep)
			end
			c:star(V(0.50, 0.50, 0.50), 0.28, WHITE)
			c:light(p.glow, 1.4, 8)
		end,
	}

	---------------------------------------------------------------- EXOTIC

	-- An impossible Penrose triangle standing on a chrome plinth, face in the gap.
	S.hh_t_penrose = {
		label = "Penrose Triangle",
		set = "holo_havoc",
		tint = C3(200, 200, 220),
		scale = 1.12,
		head = CF(0, 0.90, 0.20),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			shine(c:box(V(1.40, 0.20, 1.40), CF(0, -0.90, 0), CHROME, METAL), 0.5)
			local beams = {
				{ V(-0.70, -0.60, 0), V(0.70, -0.60, 0) },
				{ V(0.70, -0.60, 0), V(0, 0.90, 0) },
				{ V(0, 0.90, 0), V(-0.70, -0.60, 0) },
			}
			for i, b in ipairs(beams) do
				shine(c:rod(b[1], b[2], 0.16, (i == 2) and p.light or CHROME, METAL, false), 0.55)
			end
			-- Fake depth notches that sell the impossible join.
			shine(c:box(V(0.36, 0.16, 0.16), CF(0.50, -0.44, 0.10), p.dark, METAL), 0.4)
			shine(c:box(V(0.16, 0.36, 0.16), CF(-0.30, 0.20, 0.10), p.dark, METAL), 0.4)
			shine(c:ball(V(0.80, 0.80, 0.60), CF(0, 0.10, 0.30), p.base, METAL), 0.35)
			c:eyes(0.20, 0.56, 0.24, 0.12)
			smile(c, -0.10, 0.56, 0.18)
			cheeks(c, 0.26, 0.00, 0.52)
			for _, s in ipairs(SIDES) do
				c:rod(V(0.50 * s, -0.80, 0.30), V(0.60 * s, -1.10, 0.36), 0.05, CHROME, METAL, false)
				c:box(V(0.26, 0.10, 0.32), CF(0.60 * s, -1.14, 0.40), p.deep)
			end
			gem(c, V(0, 1.10, 0), 0.18, p.glow, NEON)
			c:star(V(0.70, 0.50, 0.40), 0.26, WHITE)
		end,
	}

	-- A sheet of dichroic film draped like a cape: cyan one way, magenta the other.
	S.hh_t_dichroic = {
		label = "Dichroic Film",
		set = "holo_havoc",
		tint = C3(255, 80, 200),
		scale = 1.1,
		head = CF(0, 1.20, 0.20),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				shape = "round", bodySize = V(1.40, 1.50, 1.40),
				eyeY = 0.20, eyeSpread = 0.36, eyeSize = V(0.34, 0.38, 0.18),
				legSize = V(0.36, 0.30, 0.40), legX = 0.42, legColor = p.deep,
				tail = false, mouth = false,
			})
			finish(c, from, METAL, 0.3)
			smile(c, -0.30, 0.72, 0.22)
			cheeks(c, 0.40, -0.10, 0.68)
			for _, s in ipairs(SIDES) do
				local cape = c:box(V(0.06, 1.40, 1.10), CF(0.78 * s, 0.10, -0.20) * A(0, 0, 0.25 * s), (s > 0) and FOIL_A or FOIL_B, METAL)
				cape.Reflectance = 0.65
				shine(c:box(V(0.04, 1.20, 0.90), CF(0.86 * s, 0.10, -0.20) * A(0, 0, 0.25 * s), (s > 0) and FOIL_B or FOIL_A, GLASS), 0.5)
			end
			shine(c:box(V(1.20, 0.06, 0.90), CF(0, 0.90, -0.40) * A(0.3, 0, 0), FOIL_A, METAL), 0.6)
			for i, q in ipairs({ { -0.40, 1.00, -0.20 }, { 0.40, 1.04, -0.30 }, { 0, 1.08, -0.55 } }) do
				gem(c, V(q[1], q[2], q[3]), 0.16, (i % 2 == 0) and FOIL_B or p.glow, GLASS)
			end
			c:star(V(-0.50, 0.70, 0.50), 0.28, WHITE)
		end,
	}

	-- A lenticular flip card on stubby legs: two faces interleaved in vertical slits.
	S.hh_t_lenticular = {
		label = "Lenticular Flip",
		set = "holo_havoc",
		tint = C3(100, 160, 255),
		scale = 1.1,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.60, 0.20),
		back = CF(0, 0.20, -0.20),
		build = function(c, p)
			shine(c:box(V(1.80, 2.20, 0.20), CF(0, 0.10, 0), p.base, METAL), 0.4)
			for i = -3, 3 do
				local col = (i % 2 == 0) and FOIL_A or FOIL_B
				shine(c:box(V(0.18, 1.90, 0.06), CF(0.24 * i, 0.10, 0.12), col, METAL), 0.55)
			end
			c:eyes(0.40, 0.20, 0.34, 0.13)
			smile(c, -0.20, 0.18, 0.22)
			-- Ghost second expression, offset.
			for _, s in ipairs(SIDES) do
				c:round(V(0.16, 0.20, 0.04), CF(0.30 * s, 0.55, 0.16), CYAN3D):SetAttribute("Eye", true)
			end
			c:box(V(0.30, 0.06, 0.04), CF(0.08, -0.05, 0.16), RED3D)
			for _, s in ipairs(SIDES) do
				c:rod(V(0.60 * s, -0.90, 0), V(0.70 * s, -1.16, 0.06), 0.05, CHROME, METAL, false)
				c:box(V(0.28, 0.12, 0.34), CF(0.70 * s, -1.22, 0.10), p.deep)
				c:rod(V(0.92 * s, 0.10, 0), V(1.20 * s, -0.20, 0.14), 0.05, p.dark, nil, false)
				c:ball(V(0.18, 0.18, 0.18), CF(1.22 * s, -0.22, 0.15), WHITE)
			end
			gem(c, V(0.60, 1.00, 0.14), 0.14, p.glow, NEON)
			c:star(V(-0.60, 0.90, 0.14), 0.26, WHITE)
		end,
	}

	-- A stepped Fresnel lens in a lantern housing, rings concentrating a bright core.
	S.hh_t_fresnel = {
		label = "Fresnel Lamp",
		set = "holo_havoc",
		tint = C3(255, 200, 80),
		scale = 1.12,
		head = CF(0, 1.30, 0.10),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			shine(c:cyl(V(1.40, 1.40, 1.40), CF(0, 0.20, 0) * UP, p.base, METAL), 0.4)
			shine(c:box(V(1.60, 0.16, 1.60), CF(0, -0.50, 0), CHROME, METAL), 0.5)
			for i, r in ipairs({ 1.50, 1.20, 0.90, 0.60 }) do
				local lens = c:cyl(V(0.06, r, r), CF(0, 0.30 + i * 0.12, 0.50) * FACE, p.light, GLASS)
				lens.Transparency = 0.3
				lens.Reflectance = 0.55
			end
			c:ball(V(0.40, 0.40, 0.40), CF(0, 0.60, 0.70), p.glow, NEON)
			c:eyes(0.50, 0.72, 0.28, 0.12)
			smile(c, 0.20, 0.70, 0.20)
			for _, s in ipairs(SIDES) do
				c:box(V(0.10, 0.80, 0.20), CF(0.76 * s, 0.10, 0), CHROME, METAL)
				c:rod(V(0.40 * s, -0.58, 0.40), V(0.50 * s, -1.00, 0.46), 0.05, p.deep, nil, false)
				c:box(V(0.26, 0.10, 0.30), CF(0.50 * s, -1.04, 0.50), p.deep)
			end
			c:cone(V(0.50, 0.40, 0.50), CF(0, 1.20, 0) * A(0, 0, 0), CHROME, METAL)
			c:star(V(0.50, 0.90, 0.80), 0.28, WHITE)
			c:light(p.glow, 1.5, 8)
		end,
	}

	-- Crossed polarizer filters as a cube; the face sits in a bright extinction cross.
	S.hh_t_polarizer = {
		label = "Polarizer Cube",
		set = "holo_havoc",
		tint = C3(140, 100, 255),
		scale = 1.1,
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			shine(c:box(V(1.70, 1.70, 1.70), CF(0, 0.10, 0), p.base, METAL), 0.35)
			for _, a in ipairs({ 0, PI / 2 }) do
				shine(c:box(V(1.80, 0.08, 1.80), CF(0, 0.10, 0) * A(0, a, 0), INK, METAL), 0.3)
			end
			for i = -2, 2 do
				shine(c:box(V(1.60, 0.06, 0.04), CF(0, 0.10 + 0.28 * i, 0.86), (i % 2 == 0) and FOIL_A or p.pale, GLASS), 0.5)
				shine(c:box(V(0.04, 1.60, 0.06), CF(0.28 * i, 0.10, 0.88) * A(0, 0, 0), (i % 2 == 0) and FOIL_B or CHROME, GLASS), 0.5)
			end
			c:eyes(0.30, 0.90, 0.32, 0.13)
			smile(c, -0.20, 0.88, 0.22)
			cheeks(c, 0.46, 0.00, 0.84)
			for _, s in ipairs(SIDES) do
				c:box(V(0.36, 0.36, 0.40), CF(0.55 * s, -0.90, 0.40), p.deep)
				c:box(V(0.36, 0.36, 0.40), CF(0.55 * s, -0.90, -0.40), p.deep)
			end
			gem(c, V(0, 1.10, 0), 0.20, p.glow, NEON)
			c:star(V(0.70, 0.80, 0.70), 0.26, WHITE)
		end,
	}

	-- A pocket spectroscope: slit, prism, and a rainbow strip for a smile.
	S.hh_t_spectro = {
		label = "Pocket Spectroscope",
		set = "holo_havoc",
		tint = C3(255, 140, 60),
		scale = 1.1,
		head = CF(0, 0.90, 0.40),
		neck = CF(0, -0.30, 1.00),
		back = CF(0, 0.20, -0.90),
		build = function(c, p)
			shine(c:box(V(1.00, 1.00, 2.20), CF(0, 0.10, 0), p.base, METAL), 0.4)
			shine(c:cyl(V(0.50, 0.70, 0.70), CF(0, 0.10, 1.20) * FACE, CHROME, METAL), 0.5)
			c:box(V(0.06, 0.50, 0.04), CF(0, 0.10, 1.48), INK)
			c:eyes(0.28, 1.30, 0.24, 0.11)
			-- Dispersing prism and spectrum band.
			shine(c:prism(V(0.60, 0.50, 0.60), CF(0, 0.20, 0.20) * A(0, PI / 4, 0), p.pale, GLASS), 0.55)
			local spectrum = { C3(255, 60, 60), C3(255, 160, 40), GOLD, C3(80, 220, 80), FOIL_A, FOIL_B }
			for i, col in ipairs(spectrum) do
				c:box(V(0.14, 0.10, 0.04), CF(-0.40 + (i - 1) * 0.16, -0.20, 1.30), col, NEON)
			end
			for _, s in ipairs(SIDES) do
				c:box(V(0.10, 0.50, 0.30), CF(0.56 * s, 0.10, -0.20), CHROME, METAL)
				c:rod(V(0.30 * s, -0.40, 0.50), V(0.36 * s, -0.96, 0.56), 0.05, p.deep, nil, false)
				c:box(V(0.26, 0.10, 0.30), CF(0.36 * s, -1.00, 0.60), p.deep)
			end
			shine(c:cyl(V(0.20, 0.50, 0.50), CF(0, 0.10, -1.20) * FACE, p.dark, METAL), 0.4)
			c:star(V(0.40, 0.60, 0.80), 0.26, WHITE)
			c:light(p.glow, 1.1, 6)
		end,
	}

	-- A spinning zoetrope drum with slit windows and a foil animation strip inside.
	S.hh_t_zoetrope = {
		label = "Chrome Zoetrope",
		set = "holo_havoc",
		tint = C3(220, 180, 255),
		scale = 1.12,
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			shine(c:cyl(V(1.20, 1.60, 1.60), CF(0, 0.20, 0) * UP, p.base, METAL), 0.45)
			shine(c:cyl(V(0.16, 1.70, 1.70), CF(0, 0.86, 0) * UP, CHROME, METAL), 0.55)
			shine(c:cyl(V(0.16, 1.70, 1.70), CF(0, -0.46, 0) * UP, CHROME, METAL), 0.55)
			for i = 0, 7 do
				local a = i / 8 * 2 * PI
				c:box(V(0.08, 0.70, 0.20), CF(0.82 * math.cos(a), 0.30, 0.82 * math.sin(a)) * A(0, -a, 0), INK)
				shine(c:box(V(0.04, 0.40, 0.30), CF(0.60 * math.cos(a), 0.20, 0.60 * math.sin(a)) * A(0, -a, 0), (i % 2 == 0) and FOIL_A or FOIL_B, METAL), 0.55)
			end
			shine(c:ball(V(0.90, 0.90, 0.90), CF(0, 0.20, 0), p.light, METAL), 0.3)
			c:eyes(0.30, 0.44, 0.26, 0.12)
			smile(c, -0.06, 0.44, 0.18)
			cheeks(c, 0.30, 0.04, 0.40)
			shine(c:cyl(V(0.40, 0.20, 0.20), CF(0, -0.70, 0) * UP, CHROME, METAL), 0.5)
			for _, s in ipairs(SIDES) do
				c:box(V(0.24, 0.30, 0.28), CF(0.50 * s, -1.00, 0.30), p.deep)
				c:box(V(0.24, 0.30, 0.28), CF(0.50 * s, -1.00, -0.30), p.deep)
			end
			c:star(V(0.70, 0.90, 0.50), 0.26, WHITE)
		end,
	}

	-- A Victorian stereoscope: twin lenses, a card holder, and a shared chrome hood.
	S.hh_t_stereo = {
		label = "Stereo Viewer",
		set = "holo_havoc",
		tint = C3(180, 120, 80),
		scale = 1.1,
		head = CF(0, 1.00, 0.40),
		neck = CF(0, -0.30, 0.90),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			shine(c:box(V(1.80, 1.20, 1.40), CF(0, 0.20, 0), p.base, METAL), 0.35)
			shine(c:box(V(1.90, 0.16, 1.50), CF(0, 0.86, 0), CHROME, METAL), 0.5)
			for _, s in ipairs(SIDES) do
				shine(c:cyl(V(0.20, 0.60, 0.60), CF(0.40 * s, 0.30, 0.80) * FACE, CHROME, METAL), 0.55)
				local lens = c:cyl(V(0.08, 0.48, 0.48), CF(0.40 * s, 0.30, 0.92) * FACE, C3(140, 200, 255), GLASS)
				lens.Transparency = 0.3
				lens.Reflectance = 0.6
				c:eye(V(0.40 * s, 0.30, 1.00), 0.12)
				c:rod(V(0.50 * s, -0.40, 0.30), V(0.56 * s, -0.96, 0.36), 0.05, p.deep, nil, false)
				c:box(V(0.28, 0.10, 0.32), CF(0.56 * s, -1.00, 0.40), p.deep)
			end
			shine(c:box(V(1.40, 0.90, 0.08), CF(0, 0.20, -0.80), p.light, METAL), 0.45)
			for i = 0, 3 do
				c:box(V(0.24, 0.50, 0.04), CF(-0.40 + i * 0.28, 0.20, -0.76), (i % 2 == 0) and FOIL_A or FOIL_B, NEON)
			end
			c:box(V(0.40, 0.08, 0.06), CF(0, -0.10, 0.72), INK)
			cheeks(c, 0.70, 0.10, 0.68)
			c:star(V(0.70, 0.70, 0.50), 0.26, WHITE)
		end,
	}

	-- A diffraction grating card: dense ruled lines that flash rainbow at an angle.
	S.hh_t_grating = {
		label = "Diffraction Grating",
		set = "holo_havoc",
		tint = C3(255, 100, 180),
		scale = 1.1,
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.50, 0.20),
		back = CF(0, 0.20, -0.20),
		build = function(c, p)
			shine(c:box(V(1.90, 2.00, 0.16), CF(0, 0.10, 0), CHROME, METAL), 0.5)
			for i = -5, 5 do
				local hues = { FOIL_A, FOIL_B, p.glow, GOLD, RED3D, CYAN3D }
				shine(c:box(V(0.06, 1.70, 0.04), CF(0.14 * i, 0.10, 0.10), hues[((i + 5) % 6) + 1], METAL), 0.6)
			end
			c:eyes(0.35, 0.18, 0.32, 0.12)
			smile(c, -0.15, 0.16, 0.20)
			cheeks(c, 0.48, 0.05, 0.14)
			for _, s in ipairs(SIDES) do
				c:rod(V(0.70 * s, -0.80, 0), V(0.80 * s, -1.12, 0.06), 0.05, CHROME, METAL, false)
				c:box(V(0.28, 0.12, 0.34), CF(0.80 * s, -1.18, 0.10), p.deep)
				c:rod(V(0.96 * s, 0.10, 0), V(1.24 * s, -0.16, 0.14), 0.05, p.dark, nil, false)
				c:ball(V(0.18, 0.18, 0.18), CF(1.26 * s, -0.18, 0.15), WHITE)
			end
			c:star(V(-0.60, 0.90, 0.14), 0.28, WHITE)
			c:light(p.glow, 1.2, 6)
		end,
	}

	-- Newton's rings: nested glass discs with rainbow interference fringes.
	S.hh_t_newton = {
		label = "Newton Rings",
		set = "holo_havoc",
		tint = C3(100, 220, 255),
		scale = 1.12,
		head = CF(0, 0.80, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			shine(c:cyl(V(0.20, 2.20, 2.20), CF(0, -0.60, 0) * UP, CHROME, METAL), 0.5)
			local rings = {
				{ 2.00, FOIL_A }, { 1.60, FOIL_B }, { 1.20, GOLD },
				{ 0.80, p.glow }, { 0.40, CYAN3D },
			}
			for i, r in ipairs(rings) do
				local disc = c:cyl(V(0.05, r[1], r[1]), CF(0, -0.10 + i * 0.06, 0) * UP, r[2], GLASS)
				disc.Transparency = 0.35
				disc.Reflectance = 0.55
			end
			shine(c:ball(V(0.90, 0.70, 0.90), CF(0, 0.30, 0), p.base, METAL), 0.35)
			c:eyes(0.40, 0.44, 0.26, 0.12)
			smile(c, 0.10, 0.44, 0.18)
			cheeks(c, 0.30, 0.20, 0.40)
			for _, s in ipairs(SIDES) do
				c:box(V(0.22, 0.30, 0.26), CF(0.60 * s, -0.90, 0.40), p.deep)
				c:box(V(0.22, 0.30, 0.26), CF(0.60 * s, -0.90, -0.40), p.deep)
			end
			c:star(V(0.50, 0.70, 0.40), 0.26, WHITE)
			c:light(p.glow, 1.3, 7)
		end,
	}

	-- A blob of ferrofluid on a magnet: chrome spikes radiating, face in the core.
	S.hh_t_ferrofluid = {
		label = "Ferrofluid Spike",
		set = "holo_havoc",
		tint = C3(40, 40, 50),
		scale = 1.12,
		head = CF(0, 1.00, 0.20),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			shine(c:cyl(V(0.30, 1.40, 1.40), CF(0, -0.70, 0) * UP, CHROME, METAL), 0.55)
			shine(c:ball(V(1.20, 1.00, 1.20), CF(0, 0.10, 0), INK, METAL), 0.7)
			local spikes = {
				{ 0, 1.10, 0 }, { -0.70, 0.70, 0.20 }, { 0.70, 0.70, 0.20 },
				{ -0.50, 0.50, -0.60 }, { 0.50, 0.50, -0.60 }, { 0, 0.40, 0.80 },
				{ -0.80, 0.20, -0.20 }, { 0.80, 0.20, -0.20 },
			}
			for _, tip in ipairs(spikes) do
				spike(c, V(tip[1] * 0.35, 0.20, tip[3] * 0.35), V(tip[1], tip[2], tip[3]) - V(tip[1] * 0.35, 0.20, tip[3] * 0.35), 0.28, 0.55, CHROME, METAL)
			end
			c:eyes(0.30, 0.56, 0.28, 0.12)
			smile(c, -0.06, 0.56, 0.18)
			cheeks(c, 0.34, 0.06, 0.50)
			for _, s in ipairs(SIDES) do
				c:rod(V(0.40 * s, -0.70, 0.30), V(0.50 * s, -1.06, 0.36), 0.05, CHROME, METAL, false)
				c:box(V(0.26, 0.10, 0.30), CF(0.50 * s, -1.10, 0.40), p.deep)
			end
			c:star(V(0.60, 0.60, 0.50), 0.24, WHITE)
		end,
	}

	-- A creature with a red/cyan afterimage twin ghosted beside it.
	S.hh_t_afterimage = {
		label = "Afterimage Twin",
		set = "holo_havoc",
		tint = C3(255, 70, 120),
		scale = 1.12,
		head = CF(-0.20, 1.10, 0.20),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				shape = "round", bodySize = V(1.50, 1.50, 1.50),
				eyeY = 0.16, eyeSpread = 0.34, eyeSize = V(0.34, 0.38, 0.18),
				legSize = V(0.38, 0.32, 0.42), legX = 0.44, legColor = p.deep,
				tail = false,
			})
			finish(c, from, METAL, 0.3)
			cheeks(c, 0.40, -0.10, 0.70)
			-- Ghost twin: translucent red/cyan offset copy of the silhouette.
			local ghost = c:round(V(1.40, 1.40, 1.40), CF(0.70, 0.20, -0.20), RED3D, GLASS)
			ghost.Transparency = 0.55
			ghost.Reflectance = 0.3
			local ghost2 = c:round(V(1.20, 1.20, 1.20), CF(-0.60, 0.30, -0.30), CYAN3D, GLASS)
			ghost2.Transparency = 0.6
			ghost2.Reflectance = 0.3
			for _, s in ipairs(SIDES) do
				c:ball(V(0.18, 0.18, 0.18), CF(0.70 + 0.30 * s, 0.40, 0.30), RED3D, NEON).Transparency = 0.4
				c:ball(V(0.14, 0.14, 0.14), CF(-0.60 + 0.24 * s, 0.50, 0.20), CYAN3D, NEON).Transparency = 0.4
			end
			c:star(V(0.50, 0.90, 0.50), 0.28, WHITE)
			c:light(p.glow, 1.2, 7)
		end,
	}

	return S
end
