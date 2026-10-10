--[[ PetBodies/ChaosTheory -- Chaos Theory's bodies (set 19, grade SSS). See tools/gen/sets/README.md.
	Reality distortion, on purpose: slipped slices, exploded shards, a cube
	inside a skewed cube, a pup whose back half fell upside down, a living
	doorway and a creature twisted like a whirlpool. The "broken" parts are
	deliberate and asymmetric; the faces stay clear and friendly. ]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, WHITE, NEON = K.INK, K.WHITE, K.NEON
	-- Fixed signal colours for the glitch accents (an RGB split never takes the pet's tint).
	local CYAN, MAGENTA = C3(0, 236, 255), C3(255, 46, 200)
	local PINK = C3(238, 160, 182)
	local S = {}

	S.ct_glitchcat = {
		label = "Glitch Cat",
		set = "chaos_theory",
		tint = C3(120, 110, 220),
		-- The slipped ear floats above it and the stray pixels hang off one side.
		scale = 1.12,
		head = CFrame.new(0.18, 1.08, 0.06),
		neck = CFrame.new(0.06, -0.40, 0.66),
		back = CFrame.new(0, 0.20, -0.66),
		build = function(c, p)
			-- One cat cut into three slices, each slipped sideways like a bad signal.
			for _, sl in ipairs({ { 0.18, 0.72, 0.62 }, { -0.14, 0.09, 0.64 }, { 0.06, -0.55, 0.62 } }) do
				c:box(Vector3.new(2.00, sl[3], 1.78), CFrame.new(sl[1], sl[2], 0), p.base)
			end
			-- The colour channels left behind where each slice slid away.
			c:box(Vector3.new(0.10, 0.62, 1.66), CFrame.new(0.18 - 1.04, 0.72, 0), CYAN, NEON)
			c:box(Vector3.new(0.10, 0.64, 1.66), CFrame.new(-0.14 + 1.04, 0.09, 0), MAGENTA, NEON)
			c:box(Vector3.new(0.10, 0.62, 1.66), CFrame.new(0.06 - 1.04, -0.55, 0), CYAN, NEON)
			-- The face sits on the middle slice, wherever it slid to.
			local fx = -0.14
			for _, s in ipairs({ -1, 1 }) do
				c:round(Vector3.new(0.50, 0.58, 0.20), CFrame.new(fx + 0.42 * s, 0.14, 0.95), INK):SetAttribute("Eye", true)
				c:round(Vector3.new(0.17, 0.17, 0.10), CFrame.new(fx + 0.42 * s - 0.08, 0.28, 1.04), WHITE):SetAttribute("Eye", true)
			end
			-- One eye has a magenta echo a frame behind it.
			c:round(Vector3.new(0.50, 0.58, 0.10), CFrame.new(fx + 0.54, 0.20, 0.91), MAGENTA, NEON):SetAttribute("Eye", true)
			-- Muzzle, nose and whiskers on the bottom slice.
			c:box(Vector3.new(0.54, 0.34, 0.30), CFrame.new(0.06, -0.40, 1.00), p.pale)
			c:box(Vector3.new(0.20, 0.14, 0.10), CFrame.new(0.06, -0.30, 1.16), INK)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.40, 0.04, 0.04), CFrame.new(0.06 + 0.46 * s, -0.42, 1.04) * CFrame.Angles(0, 0.30 * s, 0), p.pale)
			end
			-- The right ear is where it should be. The left one slipped a frame and
			-- floats loose; a cyan ghost marks where it used to sit.
			local ear = CFrame.new(0.72, 1.30, 0.04) * CFrame.Angles(0, 0, -0.16)
			c:cone(Vector3.new(0.50, 0.60, 0.30), ear, p.base)
			c:cone(Vector3.new(0.26, 0.34, 0.14), ear * CFrame.new(0, -0.04, 0.12), PINK)
			local slip = CFrame.new(-0.62, 1.42, 0.04) * CFrame.Angles(0, 0, 0.55)
			c:cone(Vector3.new(0.50, 0.60, 0.30), slip, p.base)
			c:cone(Vector3.new(0.26, 0.34, 0.14), slip * CFrame.new(0, -0.04, 0.12), PINK)
			c:cone(Vector3.new(0.50, 0.60, 0.10), CFrame.new(-0.36, 1.30, -0.20) * CFrame.Angles(0, 0, 0.16), CYAN, NEON)
			for _, s in ipairs({ -1, 1 }) do
				for _, z in ipairs({ 0.42, -0.42 }) do
					c:box(Vector3.new(0.44, 0.34, 0.50), CFrame.new(0.06 + 0.56 * s, -0.94, z), p.deep)
				end
			end
			-- A tail drawn in three chunky pixels, stepping up.
			c:box(Vector3.new(0.32, 0.32, 0.34), CFrame.new(0, -0.30, -1.04), p.base)
			c:box(Vector3.new(0.32, 0.32, 0.34), CFrame.new(0.14, 0.00, -1.20), p.base)
			c:box(Vector3.new(0.32, 0.32, 0.34), CFrame.new(0.00, 0.30, -1.36), CYAN, NEON)
			-- Stray pixels drifting off the right side.
			c:box(Vector3.new(0.22, 0.22, 0.22), CFrame.new(1.30, 0.80, 0.30), p.base)
			c:box(Vector3.new(0.16, 0.16, 0.16), CFrame.new(1.48, 0.46, -0.10), p.light)
			c:box(Vector3.new(0.14, 0.14, 0.14), CFrame.new(1.36, 1.10, -0.36), MAGENTA, NEON)
		end,
	}

	S.ct_shardling = {
		label = "Shardling",
		set = "chaos_theory",
		tint = C3(96, 200, 230),
		-- The shards hang out past the core on every side.
		scale = 1.12,
		head = CFrame.new(0, 0.88, 0.10),
		neck = CFrame.new(0, -0.36, 0.66),
		back = CFrame.new(0, 0.20, -0.66),
		build = function(c, p)
			-- A little cube whose shell has burst apart and stopped mid-air.
			block(c, p, {
				square = true, bodySize = Vector3.new(1.40, 1.40, 1.40),
				eyeY = 0.10, eyeSpread = 0.32, eyeSize = Vector3.new(0.42, 0.52, 0.20),
				mouthY = -0.32, mouthSize = Vector3.new(0.30, 0.14, 0.14),
				legs = false, tail = false,
			})
			-- Where the top broke away, the inside glows.
			c:box(Vector3.new(1.20, 0.06, 1.20), CFrame.new(0, 0.78, 0), p.glow, NEON)
			-- A chip in its forehead, cracked in light.
			c:box(Vector3.new(0.06, 0.30, 0.04), CFrame.new(0.50, 0.56, 0.71) * CFrame.Angles(0, 0, 0.5), p.glow, NEON)
			c:box(Vector3.new(0.06, 0.22, 0.04), CFrame.new(0.60, 0.36, 0.71) * CFrame.Angles(0, 0, -0.4), p.glow, NEON)
			-- Each shard keeps a glowing rim on its broken face, a little proud of
			-- the shard so the light shows round its edge.
			local function shard(size, cf, colour, axis, sign)
				c:box(size, cf, colour)
				local rim, off
				if axis == "X" then
					rim, off = Vector3.new(0.05, size.Y + 0.08, size.Z + 0.08), Vector3.new(sign * (size.X / 2 + 0.02), 0, 0)
				elseif axis == "Y" then
					rim, off = Vector3.new(size.X + 0.08, 0.05, size.Z + 0.08), Vector3.new(0, sign * (size.Y / 2 + 0.02), 0)
				else
					rim, off = Vector3.new(size.X + 0.08, size.Y + 0.08, 0.05), Vector3.new(0, 0, sign * (size.Z / 2 + 0.02))
				end
				c:box(rim, cf * CFrame.new(off), p.glow, NEON)
			end
			shard(Vector3.new(0.84, 0.46, 0.96), CFrame.new(-0.52, 1.24, -0.02) * CFrame.Angles(0.14, 0.30, 0.24), p.base, "Y", -1)
			shard(Vector3.new(0.64, 0.52, 0.78), CFrame.new(0.58, 1.24, 0.14) * CFrame.Angles(-0.16, -0.36, -0.20), p.light, "Y", -1)
			shard(Vector3.new(0.40, 0.86, 0.92), CFrame.new(1.06, 0.02, -0.04) * CFrame.Angles(0.10, 0.14, 0.18), p.base, "X", -1)
			shard(Vector3.new(0.40, 0.72, 0.80), CFrame.new(-1.06, -0.10, 0.10) * CFrame.Angles(-0.14, -0.18, -0.16), p.light, "X", 1)
			shard(Vector3.new(1.04, 0.70, 0.40), CFrame.new(0.06, 0.24, -1.14) * CFrame.Angles(0.32, 0.12, 0.18), p.base, "Z", 1)
			-- Two floating chunks for feet.
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.44, 0.30, 0.52), CFrame.new(0.44 * s, -0.92, 0.18) * CFrame.Angles(0.10 * s, 0.25 * s, 0.12), p.deep)
			end
			-- Specks of light still drifting outward.
			for _, v in ipairs({ { 0.98, 0.84, 0.50 }, { -0.96, 0.66, -0.56 }, { 0.30, 1.52, -0.40 } }) do
				c:box(Vector3.new(0.16, 0.16, 0.16), CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0.6, 0.6, 0), p.glow, NEON)
			end
			c:light(p.glow, 1.6, 8)
		end,
	}

	S.ct_hypercube = {
		label = "Hypercube",
		set = "chaos_theory",
		tint = C3(150, 90, 240),
		-- The skewed outer cube is wider than any face of it.
		scale = 1.12,
		head = CFrame.new(0, 0.86, 0.06),
		neck = CFrame.new(0, -0.40, 0.70),
		back = CFrame.new(0, 0.20, -0.70),
		build = function(c, p)
			-- The creature: a small cube with a big face and two diamond ears...
			block(c, p, {
				square = true, bodySize = Vector3.new(1.30, 1.30, 1.30),
				eyeSize = Vector3.new(0.40, 0.48, 0.18), eyeSpread = 0.30, eyeY = 0.08,
				mouthY = -0.28, mouthSize = Vector3.new(0.24, 0.12, 0.12),
				legs = false, tail = false,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.26, 0.26, 0.20), CFrame.new(0.42 * s, 0.82, 0) * CFrame.Angles(0, 0, math.pi / 4), p.base)
			end
			-- ...hanging inside a bigger cube that is turned the wrong way, joined
			-- corner to corner by threads of light: a tesseract, folded into a pet.
			local R = CFrame.new(0, 0.06, 0) * CFrame.Angles(0.16, 0.34, 0.10)
			local h, t = 1.00, 0.12
			for _, a in ipairs({ -1, 1 }) do
				for _, b in ipairs({ -1, 1 }) do
					c:box(Vector3.new(2 * h + t, t, t), R * CFrame.new(0, a * h, b * h), p.dark)
					c:box(Vector3.new(t, 2 * h + t, t), R * CFrame.new(a * h, 0, b * h), p.dark)
					c:box(Vector3.new(t, t, 2 * h + t), R * CFrame.new(a * h, b * h, 0), p.dark)
				end
			end
			for _, x in ipairs({ -1, 1 }) do
				for _, y in ipairs({ -1, 1 }) do
					for _, z in ipairs({ -1, 1 }) do
						local corner = R * CFrame.new(x * h, y * h, z * h)
						c:box(Vector3.new(0.22, 0.22, 0.22), corner, p.glow, NEON)
						c:rod(Vector3.new(x * 0.60, 0.06 + y * 0.60, z * 0.60), corner.Position, 0.04, p.glow, NEON, false)
					end
				end
			end
			c:light(p.glow, 1.6, 9)
		end,
	}

	S.ct_flipside = {
		label = "Flipside",
		set = "chaos_theory",
		tint = C3(240, 170, 60),
		scale = 1.05,
		head = CFrame.new(0, 1.04, 0.40),
		neck = CFrame.new(0, -0.30, 0.90),
		back = CFrame.new(0, 0.30, -1.10),
		build = function(c, p)
			-- The front half is an ordinary pup...
			c:box(Vector3.new(2.00, 1.86, 1.04), CFrame.new(0, 0.06, 0.40), p.base)
			-- ...the back half is the same pup upside down, as if it fell through a
			-- seam in the world: belly on top, paws to the sky, tail hanging down.
			local rear = CFrame.new(0.04, 0.10, -0.62) * CFrame.Angles(0, 0, math.pi + 0.14)
			c:box(Vector3.new(1.90, 1.76, 1.04), rear, p.base)
			c:box(Vector3.new(1.10, 0.10, 0.80), rear * CFrame.new(0, -0.90, 0.02), p.pale)
			-- The seam itself, glowing.
			c:box(Vector3.new(2.12, 1.98, 0.10), CFrame.new(0.02, 0.08, -0.12) * CFrame.Angles(0, 0, 0.07), p.glow, NEON)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.44, 0.36, 0.50), rear * CFrame.new(0.56 * s, -1.04, -0.10), p.deep)
				c:box(Vector3.new(0.30, 0.06, 0.32), rear * CFrame.new(0.56 * s, -1.23, -0.10), PINK)
			end
			c:box(Vector3.new(0.30, 0.74, 0.30), rear * CFrame.new(0, 0.56, -0.62) * CFrame.Angles(-0.35, 0, 0), p.base)
			c:box(Vector3.new(0.32, 0.26, 0.32), rear * CFrame.new(0, 0.92, -0.74), p.pale)
			-- The face: big eyes, a hound's muzzle, floppy ears, a little tongue.
			for _, s in ipairs({ -1, 1 }) do
				c:round(Vector3.new(0.52, 0.64, 0.22), CFrame.new(0.42 * s, 0.28, 0.96), INK):SetAttribute("Eye", true)
				c:round(Vector3.new(0.18, 0.19, 0.12), CFrame.new(0.42 * s - 0.09, 0.43, 1.06), WHITE):SetAttribute("Eye", true)
				c:box(Vector3.new(0.38, 0.86, 0.44), CFrame.new(1.10 * s, 0.30, 0.44) * CFrame.Angles(0, 0, -0.14 * s), p.dark)
				c:box(Vector3.new(0.44, 0.36, 0.50), CFrame.new(0.56 * s, -0.86, 0.50), p.deep)
			end
			c:box(Vector3.new(0.70, 0.46, 0.44), CFrame.new(0, -0.30, 1.04), p.pale)
			c:box(Vector3.new(0.26, 0.18, 0.16), CFrame.new(0, -0.16, 1.26), INK)
			c:box(Vector3.new(0.20, 0.06, 0.18), CFrame.new(0, -0.54, 1.14), PINK)
			-- Two sparks spitting from the seam.
			c:box(Vector3.new(0.14, 0.14, 0.14), CFrame.new(1.20, 0.60, -0.14) * CFrame.Angles(0.6, 0.6, 0), p.glow, NEON)
			c:box(Vector3.new(0.12, 0.12, 0.12), CFrame.new(-1.18, -0.40, -0.10) * CFrame.Angles(0.6, 0.6, 0), p.glow, NEON)
		end,
	}

	S.ct_riftling = {
		label = "Riftling",
		set = "chaos_theory",
		tint = C3(250, 90, 180),
		scale = 1.12,
		head = CFrame.new(0, 1.14, 0),
		neck = CFrame.new(0, -0.50, 0.54),
		back = CFrame.new(0, 0.20, -0.56),
		build = function(c, p)
			local VOID = C3(16, 10, 34)
			-- A living doorway: a chunky frame round a hole in space, with a shy
			-- face peering out of the dark.
			c:box(Vector3.new(2.06, 0.30, 1.00), CFrame.new(0, 0.98, 0), p.base)
			c:box(Vector3.new(2.06, 0.30, 1.00), CFrame.new(0, -0.74, 0), p.base)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.30, 1.42, 1.00), CFrame.new(0.88 * s, 0.12, 0), p.base)
				for _, y in ipairs({ 0.98, -0.74 }) do
					c:box(Vector3.new(0.36, 0.36, 1.06), CFrame.new(0.88 * s, y, 0), p.glow, NEON)
				end
			end
			c:box(Vector3.new(1.46, 1.42, 0.90), CFrame.new(0, 0.12, 0), VOID)
			-- Glowing eyes with a glint, and a crooked neon grin.
			for _, s in ipairs({ -1, 1 }) do
				c:round(Vector3.new(0.42, 0.52, 0.10), CFrame.new(0.32 * s, 0.30, 0.47), p.glow, NEON):SetAttribute("Eye", true)
				c:round(Vector3.new(0.14, 0.14, 0.06), CFrame.new(0.32 * s - 0.08, 0.42, 0.52), WHITE):SetAttribute("Eye", true)
				c:box(Vector3.new(0.16, 0.08, 0.06), CFrame.new(0.32 * s, -0.12, 0.47) * CFrame.Angles(0, 0, 0.6 * s), p.glow, NEON)
			end
			c:box(Vector3.new(0.56, 0.08, 0.06), CFrame.new(0, -0.18, 0.47), p.glow, NEON)
			-- Stars in the void, front and back.
			for _, v in ipairs({ { -0.50, 0.66, 0.46 }, { 0.52, -0.40, 0.46 }, { -0.36, -0.44, 0.46 }, { 0.40, 0.60, -0.46 }, { -0.30, -0.20, -0.46 } }) do
				c:box(Vector3.new(0.07, 0.07, 0.04), CFrame.new(v[1], v[2], v[3]), WHITE, NEON)
			end
			-- Feet, little arms, and two horns on the top corners.
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.46, 0.30, 0.56), CFrame.new(0.50 * s, -1.04, 0.10), p.deep)
				local paw = Vector3.new(1.22 * s, -0.20, 0.40)
				c:rod(Vector3.new(1.03 * s, 0.10, 0.10), paw, 0.08, p.base, nil, false)
				c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(paw), p.deep)
				c:cone(Vector3.new(0.24, 0.44, 0.24), CFrame.new(0.70 * s, 1.30, 0) * CFrame.Angles(0, 0, -0.30 * s), p.light)
			end
			-- Its tail went in one side and comes out of a tiny rift above its
			-- shoulder instead.
			local mini = CFrame.new(1.00, 1.30, -0.36) * CFrame.Angles(0, 0.5, 0.3)
			for _, v in ipairs({ { 0, 0.28, 0.60, 0.08 }, { 0, -0.28, 0.60, 0.08 }, { 0.28, 0, 0.08, 0.60 }, { -0.28, 0, 0.08, 0.60 } }) do
				c:box(Vector3.new(v[3], v[4], 0.08), mini * CFrame.new(v[1], v[2], 0), p.glow, NEON)
			end
			c:box(Vector3.new(0.40, 0.40, 0.04), mini, VOID)
			c:cone(Vector3.new(0.20, 0.46, 0.20), mini * CFrame.new(0, 0, 0.24) * CFrame.Angles(math.pi / 2, 0, 0), p.base)
			c:light(p.glow, 1.6, 8)
		end,
	}

	S.ct_twistling = {
		label = "Twistling",
		set = "chaos_theory",
		tint = C3(70, 210, 190),
		scale = 1.12,
		head = CFrame.new(0, 1.14, 0.06),
		neck = CFrame.new(0, 0.12, 0.84),
		back = CFrame.new(0, 0.40, -0.84),
		build = function(c, p)
			-- A whirlpool that grew a face: tiers narrowing to a point, each one
			-- twisted a little further round than the one above.
			for _, t in ipairs({
				{ 2.06, 0.80, 1.86, 0.50, 0.00, p.base },
				{ 1.62, 0.50, 1.46, -0.06, 0.38, p.light },
				{ 1.18, 0.44, 1.06, -0.50, 0.76, p.base },
				{ 0.74, 0.38, 0.66, -0.86, 1.14, p.light },
			}) do
				c:box(Vector3.new(t[1], t[2], t[3]), CFrame.new(0, t[4], 0) * CFrame.Angles(0, t[5], 0), t[6])
			end
			c:cone(Vector3.new(0.40, 0.26, 0.36), CFrame.new(0, -1.16, 0) * CFrame.Angles(math.pi, 1.52, 0), p.glow, NEON)
			-- Light leaking between the tiers, turned halfway between each pair.
			for _, b in ipairs({ { 1.84, 1.66, 0.10, 0.19 }, { 1.40, 1.26, -0.31, 0.57 }, { 0.96, 0.86, -0.72, 0.95 } }) do
				c:box(Vector3.new(b[1], 0.05, b[2]), CFrame.new(0, b[3], 0) * CFrame.Angles(0, b[4], 0), p.glow, NEON)
			end
			-- A cap twisted the other way, and an antenna with a glowing bead.
			c:box(Vector3.new(1.40, 0.24, 1.26), CFrame.new(0, 0.98, 0) * CFrame.Angles(0, -0.38, 0), p.light)
			c:rod(Vector3.new(0, 1.08, 0), Vector3.new(0.16, 1.38, 0.04), 0.05, p.dark, nil, false)
			c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(0.18, 1.44, 0.04), p.glow, NEON)
			-- Face on the top tier.
			for _, s in ipairs({ -1, 1 }) do
				c:round(Vector3.new(0.50, 0.56, 0.20), CFrame.new(0.44 * s, 0.56, 0.98), INK):SetAttribute("Eye", true)
				c:round(Vector3.new(0.17, 0.17, 0.10), CFrame.new(0.44 * s - 0.09, 0.70, 1.07), WHITE):SetAttribute("Eye", true)
				-- Stubby arms.
				c:box(Vector3.new(0.30, 0.26, 0.36), CFrame.new(1.16 * s, 0.40, 0.10) * CFrame.Angles(0, 0, 0.4 * s), p.base)
			end
			c:box(Vector3.new(0.30, 0.10, 0.10), CFrame.new(0, 0.22, 0.96), INK)
			-- Bits of the world caught in its spin.
			c:box(Vector3.new(0.18, 0.18, 0.18), CFrame.new(1.10, -0.30, 0.40) * CFrame.Angles(0.5, 0.5, 0), p.glow, NEON)
			c:box(Vector3.new(0.16, 0.16, 0.16), CFrame.new(-1.04, -0.56, -0.30) * CFrame.Angles(0.5, 0.5, 0), p.light)
			c:box(Vector3.new(0.14, 0.14, 0.14), CFrame.new(0.20, -0.20, -1.06) * CFrame.Angles(0.5, 0.5, 0), p.glow, NEON)
		end,
	}

	return S
end
