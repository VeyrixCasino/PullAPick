--[[ PetBodies/MythicMenagerie -- Mythic Menagerie's bodies (set 18, grade SS). See tools/gen/sets/README.md.
	The creature-collecting flagship: legendary species, each one a creature a
	kid can name on sight. A griffin, a phoenix chick, a kirin on cloud hooves, a
	three-headed hydra pup, a sphinx kitten in a pharaoh's headdress and a
	triceratops pup. None reuses an existing body's look (drake, wyrm, serpent,
	hawk, horse are already taken). ]]
return function(K)
	local C3, block, ears, wings, spots, ridge = K.C3, K.block, K.ears, K.wings, K.spots, K.ridge
	local METAL, NEON = K.METAL, K.NEON
	local S = {}

	S.mm_griffin = {
		label = "Griffin",
		set = "mythic_menagerie",
		tint = C3(196, 142, 72),
		-- The raised wings are its widest and tallest point.
		scale = 1.15,
		head = CFrame.new(0, 1.04, 0.40),
		neck = CFrame.new(0, -0.30, 0.66),
		back = CFrame.new(0, 0.30, -0.70),
		build = function(c, p)
			local beak, scaly = C3(250, 196, 60), C3(220, 160, 44)
			-- Lion behind, eagle in front.
			block(c, p, { shape = "quad", mouth = false, tail = false, legColor = p.dark })
			-- The eagle's pale feathered head, over the top of the face.
			c:box(Vector3.new(1.70, 0.90, 0.70), CFrame.new(0, 0.56, 0.58), p.pale)
			-- Hooked beak.
			c:cone(Vector3.new(0.40, 0.50, 0.44), CFrame.new(0, -0.08, 1.06) * CFrame.Angles(1.95, 0, 0), beak)
			c:box(Vector3.new(0.30, 0.16, 0.26), CFrame.new(0, -0.30, 0.98), scaly)
			for _, s in ipairs({ -1, 1 }) do
				-- Swept-back feather tufts where a lion's ears would be.
				c:cone(Vector3.new(0.26, 0.56, 0.22), CFrame.new(0.46 * s, 1.14, 0.20) * CFrame.Angles(-0.45, 0, -0.25 * s), p.pale)
				-- Wings raised in a V: a broad panel, then the long flight feathers.
				c:box(Vector3.new(0.20, 1.10, 1.06), CFrame.new(0.86 * s, 1.20, -0.34) * CFrame.Angles(0, 0, -0.42 * s), p.dark)
				c:box(Vector3.new(0.16, 0.86, 0.70), CFrame.new(1.10 * s, 1.40, -0.74) * CFrame.Angles(-0.25, 0, -0.48 * s), p.deep)
				-- Eagle's scaly yellow feet in front; the back paws stay lion.
				c:box(Vector3.new(0.50, 0.20, 0.58), CFrame.new(0.56 * s, -0.96, 0.46), scaly)
			end
			-- Lion's tail with a dark tuft.
			c:rod(Vector3.new(0, -0.20, -0.86), Vector3.new(0.12, 0.40, -1.36), 0.07, p.base, nil, false)
			c:box(Vector3.new(0.34, 0.40, 0.34), CFrame.new(0.14, 0.50, -1.40), p.deep)
		end,
	}

	S.mm_phoenix = {
		label = "Phoenix Chick",
		set = "mythic_menagerie",
		tint = C3(250, 112, 44),
		-- Its tail plumes reach well behind it.
		scale = 1.1,
		head = CFrame.new(0, 1.02, 0.06),
		neck = CFrame.new(0, -0.20, 0.58),
		back = CFrame.new(0, 0.20, -0.62),
		build = function(c, p)
			local gold = C3(255, 206, 70)
			block(c, p, {
				shape = "bird", bodySize = Vector3.new(1.84, 1.76, 1.70),
				eyeSize = Vector3.new(0.50, 0.62, 0.22), eyeSpread = 0.40,
				mouth = false, tail = false,
				bib = { w = 0.92, h = 0.72, y = -0.42, color = p.pale },
				legColor = gold, legSize = Vector3.new(0.38, 0.22, 0.48), legZ = { 0.20 },
			})
			c:cone(Vector3.new(0.30, 0.38, 0.34), CFrame.new(0, -0.20, 0.98) * CFrame.Angles(1.75, 0, 0), gold)
			-- A crest of flame, in the pet's own colour.
			c:cone(Vector3.new(0.32, 0.80, 0.32), CFrame.new(0, 1.24, 0.12) * CFrame.Angles(0.15, 0, 0), p.glow, NEON)
			for _, s in ipairs({ -1, 1 }) do
				c:cone(Vector3.new(0.26, 0.58, 0.26), CFrame.new(0.26 * s, 1.10, 0.04) * CFrame.Angles(0, 0, -0.38 * s), p.light, NEON)
			end
			c:cone(Vector3.new(0.24, 0.54, 0.24), CFrame.new(0, 1.10, -0.26) * CFrame.Angles(-0.45, 0, 0), p.glow, NEON)
			-- Three tail plumes fanned up and out, each ending in a flame tip.
			for _, x in ipairs({ -0.30, 0, 0.30 }) do
				local cf = CFrame.new(x, 0.02, -0.92) * CFrame.Angles(0.80, -x, 0) * CFrame.new(0, 0, -0.35)
				c:box(Vector3.new(0.22, 0.16, 0.70), cf, p.base)
				c:cone(Vector3.new(0.26, 0.34, 0.26), cf * CFrame.new(0, 0, -0.48) * CFrame.Angles(-math.pi / 2, 0, 0), p.glow, NEON)
			end
			wings(c, p.dark, 0.24, -0.04, -0.06, 0.18)
			c:light(p.glow, 1.8, 9)
			c:sparkle(p.glow, 5, 0.8, 0.22)
		end,
	}

	S.mm_kirin = {
		label = "Kirin",
		set = "mythic_menagerie",
		tint = C3(88, 196, 150),
		-- Swept horns, a flame tail and cloud hooves stretch every axis.
		scale = 1.18,
		head = CFrame.new(0, 1.12, 0.20),
		neck = CFrame.new(0, -0.30, 0.66),
		back = CFrame.new(0, 0.22, -0.66),
		build = function(c, p)
			local gold, cloud = C3(250, 210, 100), C3(242, 246, 255)
			-- A dragon-deer: slim legs, a long muzzle with whiskers.
			block(c, p, {
				shape = "quad",
				snout = { w = 0.62, h = 0.50, d = 0.58, color = p.light, nose = p.deep },
				bib = { w = 0.70, h = 0.56, y = -0.60, color = p.pale },
				legSize = Vector3.new(0.32, 0.44, 0.36), legColor = p.dark,
				tail = false,
			})
			for _, s in ipairs({ -1, 1 }) do
				-- Golden horns swept back along the head, each with one tine.
				c:cone(Vector3.new(0.20, 0.84, 0.20), CFrame.new(0.32 * s, 1.30, -0.06) * CFrame.Angles(-0.65, 0, -0.12 * s), gold, METAL)
				c:cone(Vector3.new(0.14, 0.40, 0.14), CFrame.new(0.42 * s, 1.16, 0.10) * CFrame.Angles(-0.10, 0, -0.55 * s), gold, METAL)
				-- Dragon whiskers trailing from the muzzle.
				c:rod(Vector3.new(0.28 * s, -0.24, 1.22), Vector3.new(0.66 * s, -0.48, 1.36), 0.035, gold, nil, false)
			end
			-- A mane of soft flame down the spine.
			for i, v in ipairs({ { 0.24, 0.20 }, { -0.14, 0.17 }, { -0.50, 0.14 }, { -0.84, 0.12 } }) do
				local w = v[2] * 2
				c:cone(Vector3.new(w, w * 1.7, w), CFrame.new(0, 1.02 - i * 0.03, v[1]) * CFrame.Angles(-0.70, 0, 0), p.glow, NEON)
			end
			-- It walks on little clouds.
			for _, s in ipairs({ -1, 1 }) do
				for _, z in ipairs({ 0.42, -0.42 }) do
					c:round(Vector3.new(0.58, 0.26, 0.56), CFrame.new(0.56 * s, -1.04, z), cloud)
				end
			end
			-- A tail that ends in a flame.
			c:rod(Vector3.new(0, -0.06, -0.90), Vector3.new(0, 0.30, -1.28), 0.07, p.base, nil, false)
			c:cone(Vector3.new(0.36, 0.54, 0.36), CFrame.new(0, 0.40, -1.34) * CFrame.Angles(-0.9, 0, 0), p.glow, NEON)
		end,
	}

	S.mm_hydra = {
		label = "Hydra Pup",
		set = "mythic_menagerie",
		tint = C3(52, 156, 150),
		-- The two side heads widen and heighten it.
		scale = 1.1,
		head = CFrame.new(0, 1.06, 0.06),
		neck = CFrame.new(0, -0.30, 0.62),
		back = CFrame.new(0, 0.20, -0.62),
		build = function(c, p)
			-- The middle head is the body itself, so its face stays on the front;
			-- the other two grow out on necks either side and look away.
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.80, 1.62, 1.80),
				eyeY = 0.18, eyeSpread = 0.38, eyeSize = Vector3.new(0.46, 0.56, 0.20),
				mouthY = -0.24, mouthSize = Vector3.new(0.40, 0.14, 0.14),
				bib = { w = 0.90, h = 0.50, y = -0.60, color = p.pale },
				legSize = Vector3.new(0.40, 0.30, 0.46), legX = 0.54, legY = -0.82,
				tail = false,
			})
			for _, s in ipairs({ -1, 1 }) do
				c:rod(Vector3.new(0.58 * s, 0.60, 0.20), Vector3.new(0.88 * s, 1.16, 0.40), 0.17, p.base, nil, false)
				local h = CFrame.new(0.92 * s, 1.36, 0.50) * CFrame.Angles(0, 0.30 * s, 0)
				c:box(Vector3.new(0.62, 0.52, 0.66), h, p.base)
				c:box(Vector3.new(0.36, 0.24, 0.26), h * CFrame.new(0, -0.12, 0.40), p.light)
				c:eye((h * CFrame.new(-0.15, 0.08, 0.34)).Position, 0.09)
				c:eye((h * CFrame.new(0.15, 0.08, 0.34)).Position, 0.09)
				c:cone(Vector3.new(0.14, 0.28, 0.16), h * CFrame.new(0, 0.36, -0.10) * CFrame.Angles(-0.4, 0, 0), p.light)
			end
			-- A finned back and a paddle tail: it lives in a lake.
			ridge(c, p.light, 3, 1.02, -0.10, 0.34, 0.24)
			c:rod(Vector3.new(0, -0.36, -0.80), Vector3.new(0.10, -0.10, -1.36), 0.15, p.base, nil, false)
			c:box(Vector3.new(0.12, 0.56, 0.44), CFrame.new(0.12, 0.02, -1.52) * CFrame.Angles(-0.4, 0, 0), p.light)
		end,
	}

	S.mm_sphinx = {
		label = "Sphinx Kitten",
		set = "mythic_menagerie",
		tint = C3(222, 184, 120),
		head = CFrame.new(0, 1.16, 0.30),
		neck = CFrame.new(0, -0.40, 0.66),
		back = CFrame.new(0, 0.30, -0.66),
		build = function(c, p)
			local gold, lapis = C3(246, 198, 72), C3(40, 84, 176)
			block(c, p, {
				shape = "quad",
				snout = { w = 0.54, h = 0.36, d = 0.40, color = p.pale },
				tail = false,
			})
			ears(c, p.base, "up", C3(238, 172, 182))
			-- The striped headdress: a gold cap the ears poke through, a lapis band,
			-- a little cobra on the brow, and lappets hanging beside the face.
			c:box(Vector3.new(1.96, 0.24, 1.10), CFrame.new(0, 1.00, 0.36), gold)
			c:box(Vector3.new(1.98, 0.08, 1.12), CFrame.new(0, 0.92, 0.36), lapis)
			c:cone(Vector3.new(0.16, 0.30, 0.14), CFrame.new(0, 1.12, 0.88), gold)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.34, 1.10, 0.36), CFrame.new(0.90 * s, 0.36, 0.76), gold)
				for _, y in ipairs({ 0.52, 0.16 }) do
					c:box(Vector3.new(0.36, 0.12, 0.38), CFrame.new(0.90 * s, y, 0.76), lapis)
				end
				-- Small feathered wings folded up behind the shoulders.
				c:box(Vector3.new(0.14, 0.80, 0.86), CFrame.new(0.70 * s, 1.08, -0.52) * CFrame.Angles(0, 0, -0.42 * s), p.light)
			end
			-- A broad jewelled collar.
			c:box(Vector3.new(1.30, 0.30, 0.20), CFrame.new(0, -0.62, 0.94), gold)
			c:box(Vector3.new(1.32, 0.10, 0.22), CFrame.new(0, -0.58, 0.95), lapis)
			-- A cat's upright tail with a gold ring.
			local tail = CFrame.new(0, 0.16, -1.12) * CFrame.Angles(-0.28, 0, 0)
			c:box(Vector3.new(0.28, 0.80, 0.28), tail, p.base)
			c:box(Vector3.new(0.32, 0.12, 0.32), tail * CFrame.new(0, 0.18, 0), gold)
		end,
	}

	S.mm_trihorn = {
		label = "Trihorn",
		set = "mythic_menagerie",
		tint = C3(122, 160, 96),
		-- The frill is wide and tall.
		scale = 1.15,
		head = CFrame.new(0, 1.00, 0.50),
		neck = CFrame.new(0, -0.40, 0.70),
		back = CFrame.new(0, 0.30, -0.70),
		build = function(c, p)
			local horn = C3(244, 234, 210)
			-- A triceratops pup: chunky legs, a beaky muzzle, a stubby tail.
			block(c, p, {
				shape = "quad", bodySize = Vector3.new(2.06, 1.72, 1.98),
				snout = { w = 0.74, h = 0.50, d = 0.48, y = -0.30, color = p.light, nose = p.deep },
				eyeY = 0.18,
				legSize = Vector3.new(0.56, 0.40, 0.60), legX = 0.62, legY = -0.84,
				tailSize = Vector3.new(0.44, 0.40, 0.60), tailColor = p.base,
			})
			c:box(Vector3.new(0.26, 0.24, 0.30), CFrame.new(0, -0.30, -1.40), p.base)
			-- The frill: a broad shield behind the face, leaning back, with a pale
			-- panel that shows from front and back and a row of knobs on its rim.
			local frill = CFrame.new(0, 1.06, 0.04) * CFrame.Angles(-0.38, 0, 0)
			c:box(Vector3.new(2.40, 1.30, 0.16), frill, p.dark)
			c:box(Vector3.new(1.80, 0.76, 0.20), frill * CFrame.new(0, 0.10, 0), p.light)
			for i = -2, 2 do
				c:cone(Vector3.new(0.24, 0.30, 0.18), frill * CFrame.new(i * 0.52, 0.72 - math.abs(i) * 0.06, 0), p.pale)
			end
			-- Two brow horns forward over the eyes, and a short one on the nose.
			for _, s in ipairs({ -1, 1 }) do
				c:cone(Vector3.new(0.22, 0.74, 0.22), CFrame.new(0.40 * s, 0.82, 1.02) * CFrame.Angles(1.05, 0, 0), horn)
			end
			c:cone(Vector3.new(0.20, 0.36, 0.20), CFrame.new(0, 0.06, 1.22) * CFrame.Angles(0.45, 0, 0), horn)
			spots(c, p.dark, { { -0.50, 0.94, -0.50 }, { 0.40, 0.96, -0.30 }, { 0.10, 0.92, -0.80 } }, Vector3.new(0.30, 0.10, 0.30))
		end,
	}

	return S
end
