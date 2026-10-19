--[[ PetBodies/ChaosTheoryTop -- Chaos Theory's top bodies: one body per
	Epic-and-up pet, so each one is worn by that pet alone and no two of them
	share a silhouette. The set is reality distortion, fractured geometry and
	cosmic anomalies -- broken geometry, distorted materials, impossible
	perspective -- so every body here is a cute glitch or paradox object, not
	horror. Faces stay friendly on the front; cyan/magenta accents are fixed
	(the set's RGB split); main volumes use p.* so each pet wears its own tint.

	NOT remakes of the base bodies (Glitch Cat, Shardling, Hypercube, Flipside,
	Riftling, Twistling). Epic stays charming and clean; Legendary adds
	fracture ornament; Mythic/Divine/Exotic lean into paradox showpieces,
	echoing the packs "Minor Glitch", "Broken Pattern", "Fracture Point",
	"Reality Shift", "Paradox Engine" and "Infinite Collapse".
	See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, WHITE, METAL, NEON, GLASS = K.INK, K.WHITE, K.METAL, K.NEON, K.GLASS
	local S = {}
	local SET = "chaos_theory"
	local SIDES = { -1, 1 }
	local V3, CF, ANG = Vector3.new, CFrame.new, CFrame.Angles
	local PI = math.pi
	local UP = ANG(0, 0, PI / 2)
	local FRONT = ANG(0, PI / 2, 0)
	local DIAMOND = ANG(0, 0, PI / 4)

	-- Fixed glitch accents: an RGB split never takes the pet's tint.
	local CYAN, MAGENTA = C3(0, 236, 255), C3(255, 46, 200)
	local BLUSH = C3(238, 160, 182)
	local VOID = C3(16, 10, 34)
	local HAZARD = C3(255, 220, 30)

	local function face(c, y, z, spread, r, iris)
		c:eyes(y, z + r * 0.3, spread, r, iris)
		c:box(V3(r * 1.6, r * 0.45, 0.06), CF(0, y - r * 2.0, z + 0.02), INK)
	end

	local function blush(c, x, y, z)
		for _, s in ipairs(SIDES) do
			c:box(V3(0.20, 0.10, 0.05), CF(x * s, y, z), BLUSH)
		end
	end

	local function feet(c, colour, x, y, z, sz)
		for _, s in ipairs(SIDES) do
			for _, t in ipairs(SIDES) do
				c:box(sz or V3(0.40, 0.22, 0.42), CF(x * s, y, z * t), colour)
			end
		end
	end

	-- A cyan or magenta rim on a broken edge.
	local function glitchRim(c, cf, size, colour)
		c:box(size, cf, colour or CYAN, NEON)
	end

	--------------------------------------------------------------------------
	-- EPIC: minor glitches and cute broken toys, charming and clean.
	--------------------------------------------------------------------------

	-- A chunky CRT with horizontal scanlines and a soft glow bezel.
	S.ct_t_crt = {
		label = "Scanline CRT",
		set = SET,
		tint = C3(110, 110, 120),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.50, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:box(V3(1.90, 1.60, 1.20), CF(0, 0.00, 0), p.base)
			c:box(V3(1.50, 1.20, 0.16), CF(0, 0.10, 0.62), VOID)
			for i = -3, 3 do
				c:box(V3(1.40, 0.06, 0.04), CF(0, 0.10 + i * 0.16, 0.72), (i % 2 == 0) and CYAN or MAGENTA, NEON)
			end
			c:box(V3(2.00, 0.14, 1.30), CF(0, 0.88, 0), p.dark)
			c:box(V3(1.40, 0.30, 1.00), CF(0, -0.96, 0), p.deep)
			face(c, 0.20, 0.76, 0.30, 0.13)
			blush(c, 0.48, -0.10, 0.74)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.16, 0.40, 0.16), CF(0.80 * s, -0.40, 0.40), p.light)
				c:box(V3(0.36, 0.20, 0.40), CF(0.50 * s, -1.18, 0.20), p.deep)
			end
			c:ball(V3(0.18, 0.18, 0.18), CF(0.70, -0.70, 0.62), MAGENTA, NEON)
		end,
	}

	-- A soft static-fuzz ball with RGB speckles and stubby feet.
	S.ct_t_fluff = {
		label = "Static Fluff",
		set = SET,
		tint = C3(200, 160, 255),
		scale = 1.1,
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:ball(V3(1.80, 1.70, 1.80), CF(0, 0.10, 0), p.base)
			c:ball(V3(1.40, 1.30, 1.40), CF(0, 0.10, 0.10), p.pale)
			for _, v in ipairs({
				{ -0.70, 0.60, 0.50 }, { 0.72, 0.40, 0.55 }, { 0.10, 0.90, 0.40 },
				{ -0.50, -0.20, 0.70 }, { 0.55, -0.30, 0.65 }, { -0.20, 0.50, -0.70 },
			}) do
				local col = (v[1] + v[2]) > 0 and CYAN or MAGENTA
				c:box(V3(0.18, 0.18, 0.18), CF(v[1], v[2], v[3]) * ANG(0.4, 0.4, 0), col, NEON)
			end
			face(c, 0.20, 0.90, 0.34, 0.15)
			blush(c, 0.52, -0.10, 0.86)
			feet(c, p.deep, 0.48, -0.90, 0.36, V3(0.38, 0.22, 0.40))
		end,
	}

	-- A round bug bristling with lag-spike bristles tipped in neon.
	S.ct_t_bristle = {
		label = "Lagspike Bristle",
		set = SET,
		tint = C3(255, 120, 20),
		scale = 1.1,
		head = CF(0, 0.90, 0.40),
		neck = CF(0, -0.30, 0.90),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			c:round(V3(1.60, 1.20, 1.80), CF(0, 0.10, 0), p.base)
			local tips = {
				{ -0.50, 1.00, -0.10 }, { 0, 1.10, -0.30 }, { 0.50, 1.00, -0.10 },
				{ -0.70, 0.70, -0.50 }, { 0.70, 0.70, -0.50 }, { 0, 0.80, -0.80 },
			}
			for i, tip in ipairs(tips) do
				local root = V3(tip[1] * 0.35, 0.30, tip[3] * 0.3)
				c:rod(root, V3(tip[1], tip[2], tip[3]), 0.04, (i % 2 == 0) and CYAN or MAGENTA, NEON, false)
				c:box(V3(0.12, 0.12, 0.12), CF(tip[1], tip[2], tip[3]), HAZARD, NEON)
			end
			c:box(V3(0.60, 0.36, 0.40), CF(0, -0.20, 0.90), p.pale)
			face(c, 0.16, 0.96, 0.28, 0.13)
			blush(c, 0.44, -0.16, 0.92)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.36, 0.28, 0.40), CF(0.48 * s, -0.82, 0.30), p.deep)
				c:box(V3(0.36, 0.28, 0.40), CF(0.48 * s, -0.82, -0.40), p.deep)
			end
		end,
	}

	-- A loading bar on stubby legs; the fill is a cyan glitch stripe.
	S.ct_t_buffer = {
		label = "Buffer Bar",
		set = SET,
		tint = C3(40, 110, 255),
		head = CF(0, 0.90, 0),
		neck = CF(0, -0.40, 0.50),
		back = CF(0, 0.20, -0.50),
		build = function(c, p)
			c:box(V3(2.20, 0.70, 0.80), CF(0, 0.00, 0), p.base)
			c:box(V3(2.00, 0.46, 0.60), CF(0, 0.00, 0.06), VOID)
			c:box(V3(1.20, 0.40, 0.50), CF(-0.36, 0.00, 0.12), CYAN, NEON)
			c:box(V3(0.20, 0.40, 0.50), CF(0.30, 0.00, 0.12), MAGENTA, NEON)
			face(c, 0.10, 0.42, 0.36, 0.12)
			blush(c, 0.70, -0.16, 0.40)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 0.30, 0.40), CF(0.70 * s, -0.56, 0.10), p.deep)
			end
			c:box(V3(0.30, 0.30, 0.30), CF(1.20, 0.40, 0), HAZARD, NEON)
		end,
	}

	-- A sealed data packet with a stamp face and a torn magenta flap.
	S.ct_t_packet = {
		label = "Packet Envelope",
		set = SET,
		tint = C3(255, 140, 190),
		head = CF(0, 1.00, 0),
		neck = CF(0, -0.40, 0.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			c:box(V3(2.00, 1.30, 0.50), CF(0, 0.00, 0), p.base)
			c:wedge(V3(2.00, 0.50, 0.40), CF(0, 0.70, 0.10) * ANG(0, 0, 0), p.light)
			c:box(V3(0.70, 0.70, 0.12), CF(0, 0.10, 0.28), p.pale)
			face(c, 0.24, 0.36, 0.22, 0.12)
			blush(c, 0.36, -0.06, 0.34)
			c:box(V3(0.50, 0.20, 0.08), CF(0.70, 0.40, 0.28), MAGENTA, NEON)
			c:box(V3(0.40, 0.08, 0.06), CF(-0.70, -0.30, 0.28), CYAN, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.36, 0.22, 0.40), CF(0.60 * s, -0.82, 0.10), p.deep)
			end
		end,
	}

	-- A chunky pixel moth: square wings and a square body.
	S.ct_t_flutter = {
		label = "Pixel Flutter",
		set = SET,
		tint = C3(120, 255, 60),
		scale = 1.1,
		head = CF(0, 0.90, 0.40),
		neck = CF(0, -0.20, 0.70),
		back = CF(0, 0.40, -0.70),
		build = function(c, p)
			c:box(V3(0.90, 0.90, 1.20), CF(0, 0.10, 0), p.base)
			for _, s in ipairs(SIDES) do
				c:box(V3(1.00, 0.80, 0.12), CF(0.95 * s, 0.30, -0.10), (s > 0) and p.light or p.pale)
				c:box(V3(0.30, 0.30, 0.08), CF(1.20 * s, 0.50, 0.00), CYAN, NEON)
				c:box(V3(0.24, 0.24, 0.08), CF(1.10 * s, 0.10, 0.00), MAGENTA, NEON)
				c:rod(V3(0.20 * s, 0.50, 0.40), V3(0.30 * s, 1.00, 0.50), 0.04, p.dark, nil, false)
				c:box(V3(0.14, 0.14, 0.14), CF(0.32 * s, 1.04, 0.52), HAZARD, NEON)
			end
			face(c, 0.20, 0.62, 0.22, 0.12)
			blush(c, 0.34, -0.10, 0.60)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.28, 0.24, 0.34), CF(0.30 * s, -0.60, 0.20), p.deep)
			end
		end,
	}

	-- A round jitter-bug with offset RGB shells.
	S.ct_t_jitter = {
		label = "Jitter Bug",
		set = SET,
		tint = C3(255, 40, 200),
		head = CF(0, 0.90, 0.30),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			c:round(V3(1.50, 1.20, 1.60), CF(0, 0.10, 0), p.base)
			c:round(V3(1.40, 1.10, 1.50), CF(0.16, 0.16, 0.04), CYAN, NEON).Transparency = 0.55
			c:round(V3(1.40, 1.10, 1.50), CF(-0.16, -0.10, -0.04), MAGENTA, NEON).Transparency = 0.55
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.20, 0.36, 0.20), CF(0.40 * s, 0.80, 0.20) * ANG(0, 0, -0.3 * s), p.light)
				c:box(V3(0.20, 0.16, 0.50), CF(0.70 * s, -0.20, 0.10), p.deep)
			end
			face(c, 0.20, 0.82, 0.28, 0.13)
			blush(c, 0.44, -0.10, 0.78)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 0.24, 0.36), CF(0.40 * s, -0.76, 0.30), p.deep)
				c:box(V3(0.34, 0.24, 0.36), CF(0.40 * s, -0.76, -0.40), p.deep)
			end
		end,
	}

	-- An open wireframe cuboid with a soft face ball inside the cage.
	S.ct_t_wireframe = {
		label = "Wireframe Cuboid",
		set = SET,
		tint = C3(0, 230, 255),
		scale = 1.12,
		head = CF(0, 1.00, 0),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			local h, t = 0.90, 0.10
			for _, a in ipairs(SIDES) do
				for _, b in ipairs(SIDES) do
					c:box(V3(2 * h + t, t, t), CF(0, a * h, b * h), p.dark)
					c:box(V3(t, 2 * h + t, t), CF(a * h, 0, b * h), p.dark)
					c:box(V3(t, t, 2 * h + t), CF(a * h, b * h, 0), p.dark)
				end
			end
			for _, x in ipairs(SIDES) do
				for _, y in ipairs(SIDES) do
					for _, z in ipairs(SIDES) do
						c:box(V3(0.18, 0.18, 0.18), CF(x * h, y * h, z * h), (x + y + z) > 0 and CYAN or MAGENTA, NEON)
					end
				end
			end
			c:ball(V3(0.90, 0.90, 0.90), CF(0, 0.00, 0.20), p.base)
			face(c, 0.10, 0.62, 0.24, 0.12)
			blush(c, 0.34, -0.16, 0.58)
			feet(c, p.deep, 0.50, -1.10, 0.40, V3(0.34, 0.18, 0.34))
		end,
	}

	-- A soft pillow torn along a glowing seam.
	S.ct_t_seam = {
		label = "Seam Rip",
		set = SET,
		tint = C3(150, 10, 50),
		head = CF(0, 0.90, 0),
		neck = CF(0, -0.30, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:round(V3(1.90, 1.20, 1.40), CF(-0.20, 0.00, 0), p.base)
			c:round(V3(1.40, 1.00, 1.20), CF(0.60, 0.10, 0.10) * ANG(0, 0, 0.25), p.light)
			glitchRim(c, CF(0.30, 0.10, 0.10) * ANG(0, 0, 0.4), V3(0.10, 1.30, 1.20), MAGENTA)
			for _, v in ipairs({ { 0.90, 0.50, 0.40 }, { 1.00, 0.10, -0.20 }, { 0.80, -0.30, 0.30 } }) do
				c:box(V3(0.16, 0.16, 0.16), CF(v[1], v[2], v[3]), CYAN, NEON)
			end
			face(c, 0.16, 0.72, 0.30, 0.14)
			blush(c, 0.48, -0.14, 0.68)
			feet(c, p.deep, 0.50, -0.80, 0.36, V3(0.38, 0.20, 0.40))
		end,
	}

	-- A bird folded from three skewed paper panels.
	S.ct_t_foldjay = {
		label = "Fold Jay",
		set = SET,
		tint = C3(90, 160, 230),
		scale = 1.1,
		head = CF(0, 1.20, 0.40),
		neck = CF(0, 0.20, 0.70),
		back = CF(0, 0.50, -0.70),
		build = function(c, p)
			c:box(V3(1.00, 0.90, 1.40), CF(0, 0.10, 0), p.base)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.90, 0.14, 0.70), CF(0.80 * s, 0.40, -0.20) * ANG(0, 0.2 * s, 0.35 * s), p.light)
				c:box(V3(0.50, 0.10, 0.40), CF(1.10 * s, 0.20, -0.40) * ANG(0, 0.3 * s, 0.2 * s), CYAN, NEON)
			end
			c:box(V3(0.60, 0.50, 0.60), CF(0, 0.70, 0.50), p.pale)
			c:wedge(V3(0.30, 0.20, 0.50), CF(0, 0.55, 0.90), HAZARD)
			face(c, 0.80, 0.80, 0.18, 0.10)
			blush(c, 0.28, 0.55, 0.76)
			c:box(V3(0.20, 0.50, 0.20), CF(0, 0.00, -0.80) * ANG(0.4, 0, 0), p.dark)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.24, 0.30, 0.30), CF(0.30 * s, -0.60, 0.20), p.deep)
			end
		end,
	}

	-- A bouquet of corrupted bit-flowers with neon stems.
	S.ct_t_bitrot = {
		label = "Bitrot Bouquet",
		set = SET,
		tint = C3(160, 255, 200),
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.50, 0.50),
		back = CF(0, 0.20, -0.50),
		build = function(c, p)
			c:cyl(V3(0.80, 0.70, 0.70), CF(0, -0.60, 0) * UP, p.deep)
			c:box(V3(1.00, 0.20, 1.00), CF(0, -0.90, 0), p.dark)
			local blooms = {
				{ 0, 0.90, 0, MAGENTA }, { -0.50, 0.70, 0.20, CYAN },
				{ 0.50, 0.70, 0.20, CYAN }, { 0, 0.60, -0.40, HAZARD },
			}
			for _, b in ipairs(blooms) do
				c:rod(V3(0, -0.20, 0), V3(b[1], b[2] - 0.20, b[3]), 0.05, p.light, nil, false)
				c:box(V3(0.36, 0.36, 0.36), CF(b[1], b[2], b[3]) * DIAMOND, b[4], NEON)
			end
			c:ball(V3(0.70, 0.70, 0.70), CF(0, 0.10, 0.30), p.base)
			face(c, 0.20, 0.62, 0.20, 0.11)
			blush(c, 0.30, -0.06, 0.58)
			feet(c, p.deep, 0.36, -1.14, 0.30, V3(0.32, 0.18, 0.32))
		end,
	}

	-- A honeycomb of hexel cubes with a face in the centre cell.
	S.ct_t_hexel = {
		label = "Hexel Hive",
		set = SET,
		tint = C3(255, 220, 30),
		scale = 1.1,
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			local cells = {
				{ 0, 0.10, 0 }, { -0.70, 0.40, 0 }, { 0.70, 0.40, 0 },
				{ -0.70, -0.30, 0 }, { 0.70, -0.30, 0 }, { 0, 0.70, -0.40 },
			}
			for i, v in ipairs(cells) do
				local col = i == 1 and p.base or (i % 2 == 0 and p.light or p.pale)
				c:box(V3(0.70, 0.70, 0.70), CF(v[1], v[2], v[3]) * ANG(0, 0, PI / 6), col)
			end
			glitchRim(c, CF(0.70, 0.40, 0.38) * ANG(0, 0, PI / 6), V3(0.74, 0.08, 0.08), CYAN)
			glitchRim(c, CF(-0.70, -0.30, 0.38) * ANG(0, 0, PI / 6), V3(0.74, 0.08, 0.08), MAGENTA)
			face(c, 0.20, 0.40, 0.20, 0.11)
			blush(c, 0.30, -0.10, 0.38)
			feet(c, p.deep, 0.50, -0.90, 0.30, V3(0.34, 0.18, 0.34))
		end,
	}

	-- A soft crash-pad cushion with a hazard stripe and an error blinker.
	S.ct_t_crash = {
		label = "Crash Cushion",
		set = SET,
		tint = C3(240, 40, 60),
		head = CF(0, 0.90, 0),
		neck = CF(0, -0.30, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:round(V3(2.00, 1.00, 1.40), CF(0, 0.00, 0), p.base)
			c:box(V3(2.00, 0.20, 1.40), CF(0, 0.40, 0), HAZARD, NEON)
			c:box(V3(0.40, 0.30, 0.20), CF(0.70, 0.60, 0.40), MAGENTA, NEON)
			c:box(V3(0.30, 0.20, 0.16), CF(-0.70, 0.55, 0.40), CYAN, NEON)
			face(c, 0.10, 0.72, 0.34, 0.14)
			blush(c, 0.54, -0.20, 0.68)
			feet(c, p.deep, 0.60, -0.70, 0.36, V3(0.40, 0.20, 0.40))
		end,
	}

	-- A standing glitch glyph tablet with a crooked neon rune.
	S.ct_t_glyph = {
		label = "Glitch Glyph",
		set = SET,
		tint = C3(130, 60, 230),
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.60, 0.30),
		back = CF(0, 0.20, -0.30),
		build = function(c, p)
			c:box(V3(1.40, 2.00, 0.30), CF(0, 0.10, 0), p.base)
			c:box(V3(1.10, 1.50, 0.12), CF(0, 0.20, 0.18), VOID)
			c:box(V3(0.50, 0.12, 0.08), CF(0, 0.50, 0.26), CYAN, NEON)
			c:box(V3(0.12, 0.70, 0.08), CF(0, 0.10, 0.26), MAGENTA, NEON)
			c:box(V3(0.40, 0.12, 0.08), CF(0.10, -0.30, 0.26) * ANG(0, 0, 0.4), CYAN, NEON)
			face(c, 0.40, 0.28, 0.28, 0.12)
			blush(c, 0.44, 0.10, 0.26)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 0.22, 0.40), CF(0.40 * s, -1.10, 0.10), p.deep)
			end
			c:box(V3(0.20, 0.20, 0.20), CF(0.60, 1.00, 0.20) * DIAMOND, HAZARD, NEON)
		end,
	}

	--------------------------------------------------------------------------
	-- LEGENDARY: fracture ornament and reality-shift props.
	--------------------------------------------------------------------------

	-- A tilted reality slab with a cyan/magenta offset copy.
	S.ct_t_shift = {
		label = "Reality Shift",
		set = SET,
		tint = C3(60, 200, 170),
		scale = 1.12,
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.50, 0.50),
		back = CF(0, 0.20, -0.50),
		build = function(c, p)
			c:box(V3(1.80, 1.80, 0.40), CF(-0.16, 0.10, 0) * ANG(0, 0, -0.12), p.base)
			c:box(V3(1.80, 1.80, 0.20), CF(0.20, 0.20, -0.10) * ANG(0, 0, 0.12), MAGENTA, NEON).Transparency = 0.45
			c:box(V3(1.80, 1.80, 0.16), CF(-0.40, 0.00, 0.10) * ANG(0, 0, -0.12), CYAN, NEON).Transparency = 0.45
			c:ball(V3(0.90, 0.90, 0.60), CF(0, 0.10, 0.30), p.pale)
			face(c, 0.20, 0.56, 0.26, 0.13)
			blush(c, 0.40, -0.10, 0.52)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.36, 0.24, 0.40), CF(0.50 * s, -1.00, 0.10), p.deep)
			end
			c:light(p.glow, 1.1, 6)
		end,
	}

	-- A cracked slab with a glowing fracture line and floating chips.
	S.ct_t_fracture = {
		label = "Fracture Crack",
		set = SET,
		tint = C3(170, 230, 255),
		scale = 1.1,
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.40, 0.60),
		back = CF(0, 0.20, -0.60),
		build = function(c, p)
			c:box(V3(1.00, 1.60, 1.20), CF(-0.50, 0.10, 0) * ANG(0, 0, -0.08), p.base)
			c:box(V3(1.00, 1.50, 1.10), CF(0.55, 0.05, 0.05) * ANG(0, 0, 0.12), p.light)
			glitchRim(c, CF(0.05, 0.10, 0.10) * ANG(0, 0, 0.5), V3(0.10, 1.70, 1.10), p.glow)
			for _, v in ipairs({ { 0.20, 1.10, 0.40 }, { -0.10, -0.60, 0.50 }, { 0.30, 0.40, -0.70 } }) do
				c:box(V3(0.22, 0.22, 0.22), CF(v[1], v[2], v[3]) * ANG(0.5, 0.5, 0), CYAN, NEON)
			end
			face(c, 0.20, 0.66, 0.28, 0.13)
			blush(c, 0.44, -0.12, 0.62)
			feet(c, p.deep, 0.50, -0.96, 0.36)
			c:light(p.glow, 1.2, 7)
		end,
	}

	-- A checkerboard whose tiles have slipped out of register.
	S.ct_t_pattern = {
		label = "Broken Pattern",
		set = SET,
		tint = C3(20, 16, 32),
		scale = 1.1,
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.40, 0.50),
		back = CF(0, 0.20, -0.50),
		build = function(c, p)
			for ix = -1, 1 do
				for iy = -1, 1 do
					local slip = ((ix + iy) % 2 == 0) and 0.10 or -0.10
					local col = ((ix + iy) % 2 == 0) and p.base or p.pale
					c:box(V3(0.70, 0.70, 0.50), CF(ix * 0.72 + slip, iy * 0.72, slip * 0.5), col)
				end
			end
			c:box(V3(0.20, 2.20, 0.08), CF(0.10, 0.00, 0.30), MAGENTA, NEON)
			c:box(V3(2.20, 0.20, 0.08), CF(0.00, 0.10, 0.32), CYAN, NEON)
			face(c, 0.20, 0.40, 0.24, 0.12)
			blush(c, 0.40, -0.10, 0.38)
			feet(c, p.deep, 0.60, -1.20, 0.30, V3(0.34, 0.18, 0.34))
		end,
	}

	-- A flat panel whose pixels have datamoshed into stripes.
	S.ct_t_datamosh = {
		label = "Datamosh Panel",
		set = SET,
		tint = C3(255, 40, 200),
		scale = 1.1,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.60, 0.30),
		back = CF(0, 0.20, -0.30),
		build = function(c, p)
			c:box(V3(1.80, 2.00, 0.24), CF(0, 0.10, 0), p.base)
			for i = -4, 4 do
				local h = 0.30 + (i % 3) * 0.20
				local col = (i % 2 == 0) and CYAN or MAGENTA
				c:box(V3(0.14, h, 0.08), CF(i * 0.18, 0.10 + (i % 2) * 0.20, 0.16), col, NEON)
			end
			face(c, 0.40, 0.24, 0.30, 0.13)
			blush(c, 0.48, 0.10, 0.22)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 0.22, 0.40), CF(0.50 * s, -1.10, 0.10), p.deep)
			end
			c:light(p.glow, 1.0, 6)
		end,
	}

	-- A dish radar sweeping for anomalies, face on the dish.
	S.ct_t_radar = {
		label = "Anomaly Radar",
		set = SET,
		tint = C3(120, 255, 60),
		scale = 1.12,
		head = CF(0, 1.40, 0.20),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:cyl(V3(0.40, 1.00, 1.00), CF(0, -0.70, 0) * UP, p.deep, METAL)
			c:cyl(V3(0.16, 1.80, 1.80), CF(0, 0.40, 0) * FRONT, p.base, METAL)
			c:cyl(V3(0.08, 1.40, 1.40), CF(0, 0.40, 0.10) * FRONT, VOID)
			c:box(V3(0.10, 0.80, 0.08), CF(0.20, 0.50, 0.20) * ANG(0, 0, 0.6), CYAN, NEON)
			c:ball(V3(0.24, 0.24, 0.24), CF(0.50, 0.80, 0.20), MAGENTA, NEON)
			face(c, 0.50, 0.22, 0.28, 0.12)
			blush(c, 0.44, 0.20, 0.20)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.36, 0.22, 0.40), CF(0.40 * s, -1.10, 0.10), p.deep)
			end
			c:light(CYAN, 1.2, 7)
		end,
	}

	-- A living doorway into void, distinct from base Riftling (no horns/arms).
	S.ct_t_portal = {
		label = "Void Portal",
		set = SET,
		tint = C3(40, 40, 120),
		scale = 1.12,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.50, 0.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			c:cyl(V3(0.30, 1.80, 1.80), CF(0, 0.10, 0) * FRONT, p.base)
			c:cyl(V3(0.20, 1.40, 1.40), CF(0, 0.10, 0.08) * FRONT, VOID)
			for i = 0, 5 do
				local a = i / 6 * 2 * PI
				c:box(V3(0.16, 0.16, 0.16), CF(0.90 * math.cos(a), 0.10 + 0.90 * math.sin(a), 0.10), (i % 2 == 0) and CYAN or MAGENTA, NEON)
			end
			face(c, 0.30, 0.28, 0.28, 0.13)
			blush(c, 0.44, 0.00, 0.26)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.36, 0.22, 0.40), CF(0.50 * s, -1.00, 0.10), p.deep)
			end
			c:light(p.glow, 1.3, 7)
		end,
	}

	-- Six dice faces scrambled onto one cuboid, pips glowing.
	S.ct_t_scramble = {
		label = "Scramble Dice",
		set = SET,
		tint = C3(255, 170, 60),
		scale = 1.1,
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:box(V3(1.60, 1.60, 1.60), CF(0, 0.10, 0), p.base)
			c:box(V3(1.00, 1.00, 1.00), CF(0.30, 0.40, 0.30) * ANG(0.2, 0.3, 0.1), p.light)
			local pips = {
				{ 0, 0.20, 0.84 }, { -0.40, 0.50, 0.84 }, { 0.40, -0.10, 0.84 },
				{ 0.84, 0.20, 0 }, { -0.84, 0.30, 0.20 },
			}
			for i, v in ipairs(pips) do
				c:ball(V3(0.20, 0.20, 0.20), CF(v[1], v[2], v[3]), (i % 2 == 0) and CYAN or MAGENTA, NEON)
			end
			face(c, 0.20, 0.84, 0.30, 0.13)
			blush(c, 0.50, -0.16, 0.80)
			feet(c, p.deep, 0.50, -0.96, 0.40)
		end,
	}

	-- A chronobit dial with hands spinning the wrong way.
	S.ct_t_chronobit = {
		label = "Chronobit Dial",
		set = SET,
		tint = C3(210, 170, 40),
		scale = 1.1,
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.50, 0.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			c:cyl(V3(0.30, 1.90, 1.90), CF(0, 0.10, 0) * FRONT, p.base, METAL)
			c:cyl(V3(0.16, 1.60, 1.60), CF(0, 0.10, 0.12) * FRONT, p.pale, GLASS)
			c:box(V3(0.10, 0.60, 0.06), CF(0.10, 0.30, 0.24) * ANG(0, 0, -0.5), CYAN, NEON)
			c:box(V3(0.10, 0.40, 0.06), CF(-0.20, 0.00, 0.24) * ANG(0, 0, 1.2), MAGENTA, NEON)
			c:ball(V3(0.20, 0.20, 0.20), CF(0, 0.10, 0.28), HAZARD, NEON)
			for i = 0, 7 do
				local a = i / 8 * 2 * PI
				c:box(V3(0.10, 0.10, 0.06), CF(0.70 * math.cos(a), 0.10 + 0.70 * math.sin(a), 0.20), p.dark)
			end
			face(c, 0.30, 0.28, 0.28, 0.12)
			blush(c, 0.44, 0.00, 0.26)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 0.22, 0.40), CF(0.50 * s, -1.00, 0.10), p.deep)
			end
		end,
	}

	-- A forced-perspective hallway trap that shrinks toward the back.
	S.ct_t_perspective = {
		label = "Perspective Trap",
		set = SET,
		tint = C3(150, 80, 40),
		scale = 1.12,
		head = CF(0, 1.20, 0.40),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.20, -0.90),
		build = function(c, p)
			c:box(V3(2.00, 1.80, 0.30), CF(0, 0.10, 0.70), p.base)
			c:box(V3(1.40, 1.30, 0.30), CF(0, 0.10, 0.20), p.light)
			c:box(V3(0.90, 0.80, 0.30), CF(0, 0.10, -0.30), p.pale)
			c:box(V3(0.50, 0.40, 0.30), CF(0, 0.10, -0.70), VOID)
			for _, z in ipairs({ 0.70, 0.20, -0.30 }) do
				glitchRim(c, CF(0, 0.10, z + 0.16), V3(0.08, (z > 0.5) and 1.70 or 1.20, 0.08), CYAN)
			end
			face(c, 0.30, 0.88, 0.30, 0.13)
			blush(c, 0.50, 0.00, 0.84)
			feet(c, p.deep, 0.60, -1.00, 0.50)
			c:light(p.glow, 1.1, 6)
		end,
	}

	-- A warped optic disc that bends light around a cute face.
	S.ct_t_optic = {
		label = "Warp Optic",
		set = SET,
		tint = C3(40, 200, 255),
		scale = 1.12,
		head = CF(0, 1.00, 0),
		neck = CF(0, -0.40, 0.60),
		back = CF(0, 0.20, -0.60),
		build = function(c, p)
			c:cyl(V3(0.40, 1.80, 1.80), CF(0, 0.10, 0) * FRONT, p.base, METAL)
			local glass = c:cyl(V3(0.24, 1.40, 1.40), CF(0, 0.10, 0.16) * FRONT, p.light, GLASS)
			glass.Transparency = 0.3
			glass.Reflectance = 0.5
			c:cyl(V3(0.08, 0.80, 0.80), CF(0.10, 0.20, 0.30) * FRONT, CYAN, NEON)
			c:cyl(V3(0.06, 0.50, 0.50), CF(-0.08, 0.00, 0.34) * FRONT, MAGENTA, NEON)
			face(c, 0.20, 0.40, 0.26, 0.12)
			blush(c, 0.42, -0.10, 0.38)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 0.22, 0.40), CF(0.50 * s, -0.96, 0.10), p.deep)
			end
			c:light(p.glow, 1.3, 7)
		end,
	}

	--------------------------------------------------------------------------
	-- MYTHIC: Paradox Engine pack — glow turned up.
	--------------------------------------------------------------------------

	-- A chunky paradox motor with spinning cyan/magenta rotors.
	S.ct_t_motor = {
		label = "Paradox Motor",
		set = SET,
		tint = C3(255, 40, 200),
		scale = 1.14,
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:box(V3(1.60, 1.40, 1.80), CF(0, 0.10, 0), p.base)
			c:cyl(V3(0.50, 1.20, 1.20), CF(0, 0.10, 0.70) * FRONT, p.dark, METAL)
			for i = 0, 3 do
				local a = i / 4 * PI
				c:box(V3(1.00, 0.12, 0.16), CF(0, 0.10, 0.90) * ANG(0, 0, a), (i % 2 == 0) and CYAN or MAGENTA, NEON)
			end
			c:ball(V3(0.40, 0.40, 0.40), CF(0, 0.10, 1.00), HAZARD, NEON)
			face(c, 0.30, 0.50, 0.30, 0.13)
			blush(c, 0.48, 0.00, 0.48)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.20, 0.50, 0.30), CF(0.90 * s, 0.10, -0.20), p.light)
				c:box(V3(0.36, 0.24, 0.40), CF(0.48 * s, -0.86, 0.30), p.deep)
				c:box(V3(0.36, 0.24, 0.40), CF(0.48 * s, -0.86, -0.40), p.deep)
			end
			c:light(p.glow, 1.4, 8)
			c:sparkle(CYAN, 3, 0.5, 0.14)
		end,
	}

	-- A Mandelbrot-ish bulb fractal with neon buds.
	S.ct_t_mandelbrot = {
		label = "Mandelbrot Fractal",
		set = SET,
		tint = C3(130, 60, 230),
		scale = 1.14,
		head = CF(0, 1.20, 0.20),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			c:ball(V3(1.40, 1.50, 1.40), CF(0, 0.20, 0), p.base)
			c:ball(V3(0.80, 0.90, 0.80), CF(0.70, -0.20, 0.20), p.light)
			c:ball(V3(0.50, 0.55, 0.50), CF(1.10, -0.50, 0.30), p.pale)
			c:ball(V3(0.60, 0.70, 0.60), CF(-0.60, 0.70, -0.20), p.light)
			for _, v in ipairs({
				{ 0.90, 0.60, 0.40, CYAN }, { -0.80, 0.20, 0.50, MAGENTA },
				{ 0.20, 1.00, -0.40, HAZARD }, { 1.20, -0.20, 0.10, CYAN },
			}) do
				c:box(V3(0.20, 0.20, 0.20), CF(v[1], v[2], v[3]) * DIAMOND, v[4], NEON)
			end
			face(c, 0.30, 0.72, 0.28, 0.13)
			blush(c, 0.44, 0.00, 0.68)
			feet(c, p.deep, 0.44, -0.80, 0.36)
			c:light(p.glow, 1.5, 8)
		end,
	}

	-- A timeslip gyro with nested rings spinning on different axes.
	S.ct_t_gyro = {
		label = "Timeslip Gyro",
		set = SET,
		tint = C3(0, 230, 255),
		scale = 1.14,
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:ball(V3(0.90, 0.90, 0.90), CF(0, 0.10, 0.20), p.base)
			c:cyl(V3(0.10, 2.00, 2.00), CF(0, 0.10, 0) * FRONT, CYAN, NEON)
			c:cyl(V3(0.10, 1.70, 1.70), CF(0, 0.10, 0) * UP, MAGENTA, NEON)
			c:cyl(V3(0.10, 1.40, 1.40), CF(0, 0.10, 0) * ANG(0, 0, PI / 4) * FRONT, HAZARD, NEON)
			face(c, 0.20, 0.62, 0.24, 0.12)
			blush(c, 0.36, -0.10, 0.58)
			feet(c, p.deep, 0.40, -0.70, 0.30, V3(0.32, 0.18, 0.32))
			c:light(p.glow, 1.5, 8)
			c:sparkle(MAGENTA, 3, 0.4, 0.12)
		end,
	}

	-- Two entangled orbs linked by a neon thread, sharing one face.
	S.ct_t_entangle = {
		label = "Entangle Pair",
		set = SET,
		tint = C3(200, 160, 255),
		scale = 1.12,
		head = CF(-0.30, 1.00, 0.20),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			c:ball(V3(1.20, 1.20, 1.20), CF(-0.50, 0.10, 0), p.base)
			c:ball(V3(1.00, 1.00, 1.00), CF(0.70, 0.20, -0.10), p.light)
			c:rod(V3(-0.10, 0.20, 0), V3(0.40, 0.30, -0.05), 0.06, CYAN, NEON, false)
			c:box(V3(0.16, 0.16, 0.16), CF(0.15, 0.50, 0.20), MAGENTA, NEON)
			c:box(V3(0.16, 0.16, 0.16), CF(0.15, -0.10, 0.20), CYAN, NEON)
			face(c, 0.20, 0.62, 0.26, 0.12)
			-- Tiny echo eyes on the twin.
			for _, s in ipairs(SIDES) do
				c:round(V3(0.18, 0.22, 0.08), CF(0.70 + 0.20 * s, 0.30, 0.40), MAGENTA, NEON):SetAttribute("Eye", true)
			end
			blush(c, 0.20, -0.10, 0.58)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 0.22, 0.36), CF((-0.40 + 0.20 * s), -0.76, 0.30), p.deep)
			end
			c:light(p.glow, 1.4, 8)
		end,
	}

	--------------------------------------------------------------------------
	-- DIVINE: Infinite Collapse and hyperspace tears, radiant.
	--------------------------------------------------------------------------

	-- Nested shells collapsing inward toward a bright core.
	S.ct_t_collapse = {
		label = "Infinite Collapse",
		set = SET,
		tint = C3(20, 16, 32),
		scale = 1.15,
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.50, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			for i, r in ipairs({ 2.00, 1.50, 1.00, 0.55 }) do
				local col = (i % 2 == 0) and p.base or p.dark
				c:cyl(V3(0.16, r, r), CF(0, 0.10, -0.10 * i) * FRONT, col)
			end
			c:ball(V3(0.50, 0.50, 0.50), CF(0, 0.10, 0.30), p.glow, NEON)
			for i = 0, 5 do
				local a = i / 6 * 2 * PI
				c:box(V3(0.14, 0.14, 0.14), CF(1.10 * math.cos(a), 0.10 + 1.10 * math.sin(a), 0.10), (i % 2 == 0) and CYAN or MAGENTA, NEON)
			end
			face(c, 0.20, 0.50, 0.24, 0.12)
			blush(c, 0.38, -0.10, 0.46)
			feet(c, p.deep, 0.50, -1.10, 0.40)
			c:light(p.glow, 1.8, 10)
			c:sparkle(p.glow, 4, 0.5, 0.16)
		end,
	}

	-- A hyperspace fold: accordion of glowing planes.
	S.ct_t_hyperspace = {
		label = "Hyperspace Fold",
		set = SET,
		tint = C3(40, 110, 255),
		scale = 1.14,
		head = CF(0, 1.20, 0.20),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			for i = 0, 4 do
				local z = 0.60 - i * 0.35
				local w = 1.80 - i * 0.20
				c:box(V3(w, 1.60 - i * 0.10, 0.12), CF(0.08 * (i % 2 == 0 and 1 or -1), 0.10, z) * ANG(0, 0.08 * i, 0), (i % 2 == 0) and p.base or p.light)
				glitchRim(c, CF(0, 0.10, z + 0.08), V3(w + 0.08, 0.08, 0.06), (i % 2 == 0) and CYAN or MAGENTA)
			end
			c:ball(V3(0.80, 0.80, 0.60), CF(0, 0.10, 0.70), p.pale)
			face(c, 0.20, 0.96, 0.24, 0.12)
			blush(c, 0.36, -0.10, 0.90)
			feet(c, p.deep, 0.50, -0.96, 0.50)
			c:light(p.glow, 1.6, 9)
		end,
	}

	-- A reality tear: a jagged neon rift with a shy face peeking through.
	S.ct_t_tear = {
		label = "Reality Tear",
		set = SET,
		tint = C3(255, 40, 200),
		scale = 1.14,
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.50, 0.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			c:box(V3(0.90, 2.00, 0.40), CF(-0.55, 0.10, 0) * ANG(0, 0, -0.1), p.base)
			c:box(V3(0.90, 2.00, 0.40), CF(0.55, 0.10, 0) * ANG(0, 0, 0.1), p.base)
			local zig = {
				{ 0, 0.90 }, { 0.16, 0.50 }, { -0.12, 0.10 }, { 0.14, -0.30 }, { -0.10, -0.70 },
			}
			for i = 1, #zig - 1 do
				c:rod(V3(zig[i][1], zig[i][2], 0.20), V3(zig[i + 1][1], zig[i + 1][2], 0.20), 0.08, (i % 2 == 0) and CYAN or MAGENTA, NEON, false)
			end
			c:box(V3(0.50, 1.60, 0.20), CF(0, 0.10, 0), VOID)
			face(c, 0.30, 0.28, 0.22, 0.12)
			blush(c, 0.34, 0.00, 0.26)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.36, 0.22, 0.40), CF(0.50 * s, -1.10, 0.10), p.deep)
			end
			c:light(MAGENTA, 1.6, 9)
			c:sparkle(CYAN, 4, 0.5, 0.14)
		end,
	}

	-- Cascading entropy shards falling in a neat, cute pile.
	S.ct_t_entropy = {
		label = "Entropy Cascade",
		set = SET,
		tint = C3(120, 255, 60),
		scale = 1.14,
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.50, 0.60),
		back = CF(0, 0.20, -0.60),
		build = function(c, p)
			c:box(V3(1.40, 0.50, 1.40), CF(0, -0.70, 0), p.deep)
			local shards = {
				{ 0, 0.90, 0, 0.2 }, { -0.40, 0.50, 0.20, -0.3 }, { 0.45, 0.40, -0.10, 0.4 },
				{ -0.20, 0.10, -0.30, 0.15 }, { 0.30, -0.10, 0.30, -0.25 }, { 0, -0.30, 0, 0 },
			}
			for i, s in ipairs(shards) do
				c:box(V3(0.70, 0.30, 0.60), CF(s[1], s[2], s[3]) * ANG(0, s[4], 0.1 * i), (i % 2 == 0) and p.base or p.light)
			end
			glitchRim(c, CF(0, 0.90, 0.36), V3(0.74, 0.08, 0.08), CYAN)
			glitchRim(c, CF(0.45, 0.40, 0.26), V3(0.74, 0.08, 0.08), MAGENTA)
			face(c, 0.00, 0.50, 0.26, 0.12)
			blush(c, 0.40, -0.24, 0.48)
			feet(c, p.dark, 0.50, -1.10, 0.40)
			c:light(p.glow, 1.5, 8)
			c:sparkle(p.glow, 3, 0.4, 0.14)
		end,
	}

	--------------------------------------------------------------------------
	-- EXOTIC: twelve impossible / paradox showstoppers (not Holo Havoc clones).
	--------------------------------------------------------------------------

	-- A Möbius ribbon loop with the face riding the twist.
	S.ct_t_mobius = {
		label = "Mobius Ribbon",
		set = SET,
		tint = C3(255, 40, 200),
		scale = 1.15,
		head = CF(0, 1.00, 0.30),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			for i = 0, 11 do
				local a = i / 12 * 2 * PI
				local twist = a * 0.5
				local x, z = 0.90 * math.cos(a), 0.90 * math.sin(a)
				local y = 0.20 * math.sin(a * 2)
				c:box(V3(0.50, 0.14, 0.28), CF(x, y, z) * ANG(0, -a, twist), (i % 2 == 0) and p.base or p.light)
			end
			c:ball(V3(0.80, 0.80, 0.70), CF(0, 0.10, 0.50), p.pale)
			face(c, 0.20, 0.82, 0.24, 0.12)
			blush(c, 0.36, -0.10, 0.76)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.32, 0.20, 0.34), CF(0.40 * s, -0.70, 0.30), p.deep)
			end
			c:box(V3(0.18, 0.18, 0.18), CF(0.90, 0.40, 0), CYAN, NEON)
			c:box(V3(0.18, 0.18, 0.18), CF(-0.90, -0.20, 0), MAGENTA, NEON)
			c:light(p.glow, 1.5, 8)
			c:sparkle(CYAN, 3, 0.4, 0.12)
		end,
	}

	-- A Klein-bottle flask silhouette (self-intersecting tube), kid-friendly.
	S.ct_t_klein = {
		label = "Klein Flask",
		set = SET,
		tint = C3(60, 200, 170),
		scale = 1.15,
		head = CF(0, 1.40, 0.20),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.40, -0.70),
		build = function(c, p)
			c:cyl(V3(1.20, 1.20, 1.20), CF(0, -0.20, 0) * UP, p.base, GLASS)
			c:cyl(V3(0.80, 0.50, 0.50), CF(0, 0.60, 0) * UP, p.light, GLASS)
			c:cyl(V3(0.90, 0.30, 0.30), CF(0.40, 0.90, 0.20) * ANG(0, 0, 0.9) * UP, p.pale, GLASS)
			c:cyl(V3(0.70, 0.24, 0.24), CF(0.70, 0.30, 0.40) * ANG(0, 0, 1.2) * UP, CYAN, NEON)
			c:ball(V3(0.40, 0.40, 0.40), CF(0.80, -0.20, 0.50), MAGENTA, NEON)
			c:ball(V3(0.90, 0.80, 0.80), CF(0, 0.10, 0.50), p.base)
			face(c, 0.20, 0.86, 0.24, 0.12)
			blush(c, 0.36, -0.10, 0.80)
			feet(c, p.deep, 0.44, -1.00, 0.36)
			c:light(p.glow, 1.5, 8)
		end,
	}

	-- Impossible ascending stairs that loop (Escher-ish, not Penrose Triangle).
	S.ct_t_stairs = {
		label = "Impossible Stairs",
		set = SET,
		tint = C3(190, 196, 206),
		scale = 1.14,
		head = CF(0, 1.20, 0.20),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			local steps = {
				{ -0.70, -0.60, 0.40 }, { -0.30, -0.30, 0.40 }, { 0.10, 0.00, 0.40 },
				{ 0.50, 0.30, 0.40 }, { 0.50, 0.30, 0.00 }, { 0.50, 0.30, -0.40 },
				{ 0.10, 0.00, -0.40 }, { -0.30, -0.30, -0.40 }, { -0.70, -0.60, -0.40 },
				{ -0.70, -0.60, 0.00 },
			}
			for i, s in ipairs(steps) do
				c:box(V3(0.50, 0.22, 0.50), CF(s[1], s[2], s[3]), (i % 2 == 0) and p.base or p.light)
			end
			glitchRim(c, CF(0.50, 0.42, 0.20), V3(0.54, 0.08, 0.54), CYAN)
			glitchRim(c, CF(-0.70, -0.48, 0.00), V3(0.54, 0.08, 0.54), MAGENTA)
			c:ball(V3(0.80, 0.80, 0.70), CF(0, 0.10, 0.20), p.pale)
			face(c, 0.20, 0.52, 0.24, 0.12)
			blush(c, 0.36, -0.10, 0.48)
			feet(c, p.deep, 0.40, -0.96, 0.30)
			c:light(p.glow, 1.4, 8)
		end,
	}

	-- A blivet / impossible fork: three prongs that become two.
	S.ct_t_blivet = {
		label = "Blivet Fork",
		set = SET,
		tint = C3(210, 170, 40),
		scale = 1.14,
		head = CF(0, 1.00, 0.40),
		neck = CF(0, -0.30, 0.90),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:box(V3(1.40, 0.50, 0.40), CF(0, 0.10, -0.50), p.base, METAL)
			for _, x in ipairs({ -0.45, 0, 0.45 }) do
				c:cyl(V3(1.20, 0.22, 0.22), CF(x, 0.10, 0.30) * FRONT, p.light, METAL)
			end
			-- The impossible join: two bars that read as three.
			c:box(V3(0.70, 0.22, 0.22), CF(-0.22, 0.10, -0.10), CYAN, NEON)
			c:box(V3(0.70, 0.22, 0.22), CF(0.22, 0.10, -0.10), MAGENTA, NEON)
			c:ball(V3(0.80, 0.70, 0.70), CF(0, 0.30, 0.70), p.pale)
			face(c, 0.40, 1.00, 0.24, 0.12)
			blush(c, 0.36, 0.10, 0.96)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.32, 0.20, 0.34), CF(0.40 * s, -0.50, 0.40), p.deep)
			end
			c:light(HAZARD, 1.3, 7)
		end,
	}

	-- A Necker-cube illusion: two overlapping cubes fighting for depth.
	S.ct_t_necker = {
		label = "Necker Illusion",
		set = SET,
		tint = C3(240, 244, 255),
		scale = 1.14,
		head = CF(0, 1.00, 0.20),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			local function wireCube(cf, colour)
				local h, t = 0.70, 0.08
				for _, a in ipairs(SIDES) do
					for _, b in ipairs(SIDES) do
						c:box(V3(2 * h + t, t, t), cf * CF(0, a * h, b * h), colour)
						c:box(V3(t, 2 * h + t, t), cf * CF(a * h, 0, b * h), colour)
						c:box(V3(t, t, 2 * h + t), cf * CF(a * h, b * h, 0), colour)
					end
				end
			end
			wireCube(CF(-0.20, 0.10, 0), p.base)
			wireCube(CF(0.30, 0.20, 0.20) * ANG(0.1, 0.2, 0), CYAN)
			c:ball(V3(0.80, 0.80, 0.70), CF(0, 0.10, 0.40), p.pale)
			face(c, 0.20, 0.72, 0.24, 0.12)
			blush(c, 0.36, -0.10, 0.66)
			feet(c, p.deep, 0.44, -0.90, 0.36)
			c:box(V3(0.16, 0.16, 0.16), CF(0.70, 0.70, 0.50), MAGENTA, NEON)
			c:light(p.glow, 1.4, 8)
		end,
	}

	-- Droste recursion: a picture frame holding a smaller copy of itself.
	S.ct_t_droste = {
		label = "Droste Recursion",
		set = SET,
		tint = C3(255, 120, 20),
		scale = 1.14,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.60, 0.30),
		back = CF(0, 0.20, -0.30),
		build = function(c, p)
			local sizes = { 2.00, 1.40, 0.90, 0.50 }
			for i, s in ipairs(sizes) do
				c:box(V3(s, s, 0.14), CF(0, 0.10, 0.08 * i), (i % 2 == 0) and p.base or p.light)
				c:box(V3(s - 0.24, s - 0.24, 0.08), CF(0, 0.10, 0.08 * i + 0.04), (i == #sizes) and p.glow or VOID, (i == #sizes) and NEON or nil)
			end
			face(c, 0.30, 0.40, 0.26, 0.12)
			blush(c, 0.42, 0.00, 0.38)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 0.22, 0.40), CF(0.55 * s, -1.10, 0.10), p.deep)
				c:box(V3(0.14, 0.14, 0.14), CF(0.90 * s, 0.90, 0.20), (s > 0) and CYAN or MAGENTA, NEON)
			end
			c:light(p.glow, 1.5, 8)
			c:sparkle(p.glow, 3, 0.4, 0.12)
		end,
	}

-- A strange loop: an ouroboros of cubes chasing its own glow.
	S.ct_t_strangeloop = {
		label = "Strange Loop",
		set = SET,
		tint = C3(130, 60, 230),
		scale = 1.15,
		head = CF(0, 1.10, 0.20),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			for i = 0, 7 do
				local a = i / 8 * 2 * PI
				local x, y = 0.85 * math.cos(a), 0.55 * math.sin(a)
				c:box(V3(0.40, 0.40, 0.40), CF(x, y, 0.10 * math.sin(a * 2)) * ANG(0, a, 0.2), (i % 2 == 0) and p.base or p.light)
			end
			c:rod(V3(0.85, 0, 0), V3(-0.85, 0, 0), 0.05, CYAN, NEON, false)
			c:ball(V3(0.70, 0.70, 0.70), CF(0, 0.10, 0.40), p.pale)
			face(c, 0.20, 0.72, 0.22, 0.12)
			blush(c, 0.34, -0.10, 0.66)
			feet(c, p.deep, 0.40, -0.80, 0.30, V3(0.32, 0.18, 0.32))
			c:box(V3(0.18, 0.18, 0.18), CF(0, 0.70, 0.20), MAGENTA, NEON)
			c:light(p.glow, 1.5, 8)
			c:sparkle(MAGENTA, 3, 0.4, 0.12)
		end,
	}

	-- An impossible tribar (Penrose-adjacent, but not that label).
	S.ct_t_tribar = {
		label = "Impossible Tribar",
		set = SET,
		tint = C3(200, 200, 220),
		scale = 1.14,
		head = CF(0, 0.90, 0.20),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			local beams = {
				{ V3(-0.70, -0.50, 0), V3(0.70, -0.50, 0) },
				{ V3(0.70, -0.50, 0), V3(0, 0.90, 0) },
				{ V3(0, 0.90, 0), V3(-0.70, -0.50, 0) },
			}
			for i, b in ipairs(beams) do
				c:rod(b[1], b[2], 0.16, (i == 2) and p.light or p.base, METAL, false)
			end
			c:box(V3(0.36, 0.16, 0.16), CF(0.50, -0.34, 0.10), CYAN, NEON)
			c:box(V3(0.16, 0.36, 0.16), CF(-0.30, 0.30, 0.10), MAGENTA, NEON)
			c:ball(V3(0.80, 0.80, 0.60), CF(0, 0.10, 0.30), p.pale)
			face(c, 0.20, 0.56, 0.24, 0.12)
			blush(c, 0.36, -0.10, 0.52)
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.50 * s, -0.70, 0.30), V3(0.56 * s, -1.00, 0.36), 0.05, p.deep, nil, false)
				c:box(V3(0.28, 0.12, 0.32), CF(0.56 * s, -1.06, 0.40), p.deep)
			end
			c:box(V3(0.18, 0.18, 0.18), CF(0, 1.10, 0) * DIAMOND, HAZARD, NEON)
			c:light(p.glow, 1.5, 8)
		end,
	}

	-- A paradox waterfall that flows up one side and down the other.
	S.ct_t_waterfall = {
		label = "Paradox Waterfall",
		set = SET,
		tint = C3(40, 110, 255),
		scale = 1.15,
		head = CF(0, 1.20, 0.20),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:box(V3(1.80, 0.30, 1.40), CF(0, 0.80, 0), p.base)
			c:box(V3(1.80, 0.30, 1.40), CF(0, -0.70, 0), p.dark)
			for i = 0, 4 do
				local y = 0.60 - i * 0.30
				c:box(V3(0.40, 0.28, 0.50), CF(-0.50, y, 0.20), CYAN, NEON)
				c:box(V3(0.40, 0.28, 0.50), CF(0.50, -y, 0.20), MAGENTA, NEON)
			end
			c:box(V3(0.30, 0.20, 1.00), CF(-0.50, 0.80, -0.20), p.light)
			c:box(V3(0.30, 0.20, 1.00), CF(0.50, -0.70, -0.20), p.light)
			c:ball(V3(0.80, 0.80, 0.70), CF(0, 0.10, 0.40), p.pale)
			face(c, 0.20, 0.72, 0.24, 0.12)
			blush(c, 0.36, -0.10, 0.66)
			feet(c, p.deep, 0.50, -1.06, 0.40)
			c:light(CYAN, 1.5, 8)
			c:sparkle(CYAN, 4, 0.5, 0.14)
		end,
	}

	-- Nested recursive frames stepping into depth.
	S.ct_t_frame = {
		label = "Recursive Frame",
		set = SET,
		tint = C3(255, 140, 190),
		scale = 1.14,
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.50, 0.40),
		back = CF(0, 0.20, -0.40),
		build = function(c, p)
			for i = 0, 3 do
				local s = 2.00 - i * 0.40
				local z = -0.10 + i * 0.14
				local rim = (i % 2 == 0) and p.base or CYAN
				local mat = (i % 2 == 0) and nil or NEON
				c:box(V3(s, 0.14, 0.14), CF(0, s / 2 - 0.10, z), rim, mat)
				c:box(V3(s, 0.14, 0.14), CF(0, -s / 2 + 0.10, z), (i % 2 == 0) and p.base or MAGENTA, mat)
				c:box(V3(0.14, s, 0.14), CF(s / 2 - 0.05, 0.00, z), p.light)
				c:box(V3(0.14, s, 0.14), CF(-s / 2 + 0.05, 0.00, z), p.light)
			end
			c:ball(V3(0.70, 0.70, 0.50), CF(0, 0.10, 0.40), p.pale)
			face(c, 0.20, 0.62, 0.22, 0.11)
			blush(c, 0.34, -0.10, 0.58)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.34, 0.22, 0.40), CF(0.50 * s, -1.10, 0.10), p.deep)
			end
			c:light(p.glow, 1.5, 8)
		end,
	}

	-- A singularity pit: dark funnel with a bright event rim.
	S.ct_t_singularity = {
		label = "Singularity Pit",
		set = SET,
		tint = C3(20, 16, 32),
		scale = 1.15,
		head = CF(0, 1.00, 0),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:cyl(V3(0.30, 2.00, 2.00), CF(0, -0.60, 0) * UP, p.deep, METAL)
			for i, r in ipairs({ 1.80, 1.30, 0.80 }) do
				c:cyl(V3(0.12, r, r), CF(0, -0.20 + i * 0.12, 0) * UP, (i == 1) and CYAN or (i == 2 and MAGENTA or HAZARD), NEON)
			end
			c:ball(V3(0.50, 0.40, 0.50), CF(0, 0.40, 0), VOID)
			c:ball(V3(0.90, 0.70, 0.90), CF(0, 0.20, 0.30), p.base)
			face(c, 0.30, 0.70, 0.26, 0.12)
			blush(c, 0.40, 0.00, 0.64)
			feet(c, p.dark, 0.60, -0.96, 0.50)
			c:light(p.glow, 1.8, 10)
			c:sparkle(MAGENTA, 4, 0.5, 0.16)
		end,
	}

	-- A wormhole torus: two linked glowing rings with a face in the throat.
	S.ct_t_wormhole = {
		label = "Wormhole Torus",
		set = SET,
		tint = C3(150, 90, 240),
		scale = 1.15,
		head = CF(0, 1.00, 0.20),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			c:cyl(V3(0.36, 1.80, 1.80), CF(0, 0.10, 0) * FRONT, CYAN, NEON)
			c:cyl(V3(0.36, 1.80, 1.80), CF(0, 0.10, 0) * UP, MAGENTA, NEON)
			c:cyl(V3(0.20, 1.20, 1.20), CF(0, 0.10, 0) * FRONT, VOID)
			c:cyl(V3(0.20, 1.20, 1.20), CF(0, 0.10, 0) * UP, VOID)
			c:ball(V3(0.80, 0.80, 0.70), CF(0, 0.10, 0.40), p.pale)
			face(c, 0.20, 0.72, 0.24, 0.12)
			blush(c, 0.36, -0.10, 0.66)
			for i = 0, 5 do
				local a = i / 6 * 2 * PI
				c:box(V3(0.14, 0.14, 0.14), CF(1.00 * math.cos(a), 0.10 + 1.00 * math.sin(a), 0.10), HAZARD, NEON)
			end
			feet(c, p.deep, 0.44, -0.90, 0.36)
			c:light(p.glow, 1.8, 10)
			c:sparkle(CYAN, 4, 0.5, 0.16)
		end,
	}

	return S
end
