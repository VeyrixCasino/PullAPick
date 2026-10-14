--[[ PetBodies/EternalRootsTop -- Eternal Roots' top bodies. See tools/gen/sets/README.md.
	One body per Epic-and-up pet: no other pet in the game wears any of these.
	The theme is world-scale roots, buried springs, root caverns, ancient life
	and cosmic nature, so the cast runs from seeds and fungi to fossils, cavern
	beasts and a tree with a world in its roots. Every silhouette differs from
	the set's six recolour bodies (stump, mole, capybara, snail, radish, whale)
	and from the wyrm, turtle and beetle it borrows. ]]
return function(K)
	local C3, block, ears, wings = K.C3, K.block, K.ears, K.wings
	local INK, WHITE, NOSE, NEON, GLASS, SLATE, WOOD, METAL = K.INK, K.WHITE, K.NOSE, K.NEON, K.GLASS, K.SLATE, K.WOOD, K.METAL
	local V3, CF, ANG, PI = Vector3.new, CFrame.new, CFrame.Angles, math.pi
	local LEAF, LEAF_DARK = C3(104, 186, 84), C3(64, 132, 58)
	local BARK = C3(118, 84, 58)
	local BLUSH = C3(255, 150, 170)
	local GOLD = C3(255, 204, 84)
	local WATER = C3(110, 214, 236)
	local IVORY = C3(250, 240, 214)
	local SIDES = { -1, 1 }
	local S = {}

	-- Two blush marks either side of a face.
	local function cheeks(c, y, z, x, w)
		for _, s in ipairs(SIDES) do
			c:box(V3(w or 0.22, 0.10, 0.04), CF(x * s, y, z), BLUSH)
		end
	end

	----------------------------------------------------------------------------
	-- EPIC: charming and clean.
	----------------------------------------------------------------------------

	S.er_t_acorn = {
		label = "Acorn Roller",
		set = "eternal_roots",
		tint = C3(204, 146, 64),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.50, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			-- The nut is the body; its point sticks out underneath.
			c:box(V3(1.80, 1.60, 1.70), CF(0, -0.14, 0), p.base)
			c:cone(V3(0.56, 0.30, 0.56), CF(0, -1.09, 0) * ANG(PI, 0, 0), p.dark)
			-- The cap: a wide lip, a stepped crown with scale nubs, a stalk and a leaf.
			c:box(V3(2.04, 0.50, 1.94), CF(0, 0.82, 0), p.dark)
			c:box(V3(1.36, 0.22, 1.30), CF(0, 1.17, 0), p.deep)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(V3(0.26, 0.08, 0.26), CF(0.84 * s, 1.09, 0.80 * t), p.deep)
				end
			end
			c:rod(V3(0, 1.26, 0), V3(0.10, 1.56, -0.04), 0.08, p.deep, nil, false)
			c:box(V3(0.40, 0.08, 0.24), CF(0.30, 1.56, -0.04) * ANG(0, 0, 0.35), LEAF)
			c:eyes(0.02, 0.86, 0.36, 0.15)
			c:box(V3(0.26, 0.10, 0.06), CF(0, -0.28, 0.87), INK)
			cheeks(c, -0.16, 0.86, 0.60)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.36, 0.22, 0.44), CF(0.56 * s, -0.98, 0.30), p.deep)
			end
		end,
	}

	S.er_t_pinehog = {
		label = "Pinecone Hog",
		set = "eternal_roots",
		tint = C3(168, 98, 52),
		head = CF(0, 0.98, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.30, -0.70),
		build = function(c, p)
			-- A hedgehog whose spines are pinecone scales, each lifted at the back edge.
			block(c, p, {
				bodySize = V3(1.90, 1.40, 1.90),
				eyeY = 0.10, eyeSpread = 0.38, eyeSize = V3(0.38, 0.46, 0.18),
				snout = { w = 0.56, h = 0.40, d = 0.50, y = -0.22, color = p.pale, nose = INK },
				legSize = V3(0.40, 0.26, 0.44), legY = -0.70, legX = 0.56,
				tail = false,
			})
			-- A pale face patch so the face reads against the scales.
			c:box(V3(1.40, 1.00, 0.06), CF(0, -0.02, 0.96), p.pale)
			for row, z in ipairs({ 0.50, 0.00, -0.50 }) do
				for col, x in ipairs({ -0.56, 0, 0.56 }) do
					c:box(V3(0.58, 0.14, 0.58), CF(x, 0.80, z) * ANG(0.30, 0, 0), ((row + col) % 2 == 0) and p.dark or p.deep)
				end
			end
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.25, -0.45 }) do
					c:box(V3(0.14, 0.50, 0.58), CF(0.98 * s, 0.20, z) * ANG(0.30, 0, 0), p.dark)
				end
			end
		end,
	}

	S.er_t_toadstool = {
		label = "Toadstool Tot",
		set = "eternal_roots",
		tint = C3(230, 52, 60),
		head = CF(0, 1.16, 0),
		neck = CF(0, -0.70, 0.62),
		back = CF(0, -0.30, -0.62),
		build = function(c, p)
			-- The stem is the body, face tucked under the brim of a spotted cap.
			c:box(V3(1.30, 1.20, 1.20), CF(0, -0.42, 0), p.pale)
			c:box(V3(2.20, 0.06, 2.00), CF(0, 0.22, 0), p.light)
			c:box(V3(2.40, 0.60, 2.20), CF(0, 0.54, 0), p.base)
			c:box(V3(1.70, 0.30, 1.56), CF(0, 0.98, 0), p.base)
			c:box(V3(0.36, 0.06, 0.36), CF(0.40, 1.14, 0.30), WHITE)
			c:box(V3(0.30, 0.06, 0.30), CF(-0.46, 1.14, -0.26), WHITE)
			c:box(V3(0.40, 0.30, 0.06), CF(-0.60, 0.56, 1.11), WHITE)
			c:box(V3(0.30, 0.24, 0.06), CF(0.66, 0.50, 1.11), WHITE)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.06, 0.28, 0.40), CF(1.21 * s, 0.56, -0.30 * s), WHITE)
			end
			c:eyes(-0.30, 0.62, 0.28, 0.14)
			c:box(V3(0.20, 0.08, 0.05), CF(0, -0.58, 0.61), INK)
			cheeks(c, -0.50, 0.61, 0.46, 0.18)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.20, 0.40, 0.24), CF(0.75 * s, -0.48, 0.10) * ANG(0, 0, 0.25 * s), p.pale)
				c:box(V3(0.40, 0.22, 0.50), CF(0.34 * s, -1.08, 0.12), p.light)
			end
		end,
	}

	S.er_t_glowworm = {
		label = "Cavern Glowworm",
		set = "eternal_roots",
		tint = C3(60, 220, 200),
		scale = 1.1,
		head = CF(0, 0.66, 0.70),
		neck = CF(0, -0.40, 1.20),
		back = CF(0, 0.30, -1.20),
		build = function(c, p)
			-- Four segments arching back from the face, spots glowing down each
			-- flank and a lamp at the tail, the way it lights the root caverns.
			local segs = {
				{ V3(1.20, 1.20, 1.10), CF(0, 0.00, 0.70), p.base },
				{ V3(1.10, 1.10, 0.80), CF(0, 0.14, -0.05), p.light },
				{ V3(1.00, 1.00, 0.70), CF(0, 0.02, -0.68), p.base },
				{ V3(0.86, 0.86, 0.60), CF(0, -0.14, -1.22), p.light },
			}
			for i, sg in ipairs(segs) do
				c:box(sg[1], sg[2], sg[3])
				if i > 1 then
					for _, s in ipairs(SIDES) do
						c:box(V3(0.06, 0.22, 0.22), sg[2] * CF(s * (sg[1].X / 2 + 0.02), 0.10, 0), p.glow, NEON)
					end
				end
			end
			c:box(V3(0.50, 0.50, 0.06), CF(0, -0.14, -1.53), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.24, 0.16, 0.24), CF(0.36 * s, -0.50, -0.05), p.dark)
				c:box(V3(0.24, 0.16, 0.24), CF(0.32 * s, -0.56, -0.68), p.dark)
				c:rod(V3(0.30 * s, 0.58, 0.95), V3(0.48 * s, 1.02, 1.12), 0.04, p.dark, nil, false)
				c:ball(V3(0.20, 0.20, 0.20), CF(0.48 * s, 1.04, 1.13), p.glow, NEON)
			end
			c:eyes(0.10, 1.26, 0.28, 0.15)
			c:box(V3(0.26, 0.08, 0.05), CF(0, -0.22, 1.26), INK)
			cheeks(c, -0.12, 1.26, 0.46, 0.18)
			c:light(p.glow, 1.2, 7)
		end,
	}

	S.er_t_axolotl = {
		label = "Spring Axolotl",
		set = "eternal_roots",
		tint = C3(255, 140, 196),
		head = CF(0, 0.84, 0.10),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			-- Wide and flat, with three feathery gill fronds on each side of its head.
			block(c, p, {
				bodySize = V3(2.10, 1.30, 1.70),
				eyeY = 0.18, eyeSpread = 0.58, eyeSize = V3(0.36, 0.42, 0.18),
				mouthY = -0.18, mouthSize = V3(0.74, 0.08, 0.10),
				legSize = V3(0.38, 0.20, 0.40), legX = 0.84, legY = -0.62, legZ = { 0.40, -0.40 },
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				for _, g in ipairs({ { 0.56, 0.30, 0.55 }, { 0.30, 0.10, 0.95 }, { 0.04, -0.10, 1.35 } }) do
					c:box(V3(0.14, 0.56, 0.16), CF(1.16 * s, g[1], g[2]) * ANG(0, 0, -g[3] * s), p.light)
				end
			end
			-- A long paddle tail with a fin, and a fin down the spine.
			c:box(V3(0.50, 0.56, 1.00), CF(0, -0.02, -1.30), p.base)
			c:box(V3(0.08, 0.84, 1.24), CF(0, 0.02, -1.40), p.pale)
			c:box(V3(0.08, 0.20, 1.20), CF(0, 0.80, -0.20), p.pale)
			c:box(V3(0.22, 0.06, 0.22), CF(0.40, 0.72, -0.20), p.dark)
			c:box(V3(0.22, 0.06, 0.22), CF(-0.36, 0.72, 0.20), p.dark)
			cheeks(c, -0.06, 0.86, 0.68)
		end,
	}

	S.er_t_frog = {
		label = "Lilypad Croaker",
		set = "eternal_roots",
		tint = C3(92, 204, 70),
		scale = 1.2,
		head = CF(0, 0.56, -0.10),
		neck = CF(0, -0.50, 0.74),
		back = CF(0, -0.20, -0.70),
		build = function(c, p)
			-- A frog sat on its lily pad, eyes up on top of its head.
			c:cyl(V3(0.10, 2.20, 2.20), CF(0, -0.92, 0) * ANG(0, 0, PI / 2), LEAF)
			c:box(V3(0.30, 0.20, 0.30), CF(0.80, -0.78, 0.50), BLUSH)
			c:box(V3(0.30, 0.20, 0.30), CF(0.80, -0.76, 0.50) * ANG(0, PI / 4, 0), BLUSH)
			c:box(V3(0.12, 0.12, 0.12), CF(0.80, -0.64, 0.50), GOLD)
			c:box(V3(1.60, 1.00, 1.40), CF(0, -0.36, 0), p.base)
			c:box(V3(1.10, 0.60, 0.06), CF(0, -0.46, 0.71), p.pale)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.56, 0.48, 0.52), CF(0.46 * s, 0.30, 0.30), p.base)
				c:eye(V3(0.46 * s, 0.32, 0.58), 0.17)
				c:box(V3(0.40, 0.44, 0.90), CF(0.86 * s, -0.62, -0.14), p.dark)
				c:box(V3(0.30, 0.10, 0.34), CF(0.42 * s, -0.82, 0.78), p.dark)
			end
			c:box(V3(0.90, 0.06, 0.05), CF(0, -0.08, 0.71), INK)
			cheeks(c, -0.18, 0.71, 0.64, 0.20)
		end,
	}

	S.er_t_squirrel = {
		label = "Hoarder Squirrel",
		set = "eternal_roots",
		tint = C3(236, 110, 40),
		scale = 1.1,
		head = CF(0, 1.06, 0.20),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.30, -0.70),
		build = function(c, p)
			-- Sat up, hugging an acorn, its tail curled right up over its head.
			block(c, p, {
				shape = "bird", bodySize = V3(1.70, 1.80, 1.50),
				eyeY = 0.24, eyeSpread = 0.38, eyeSize = V3(0.40, 0.48, 0.18),
				snout = { w = 0.50, h = 0.30, d = 0.30, y = -0.10, color = p.pale, nose = NOSE },
				bib = { w = 0.90, h = 0.70, y = -0.42, color = p.pale },
				legSize = V3(0.40, 0.24, 0.50), legX = 0.44, legY = -0.86, legZ = { 0.26 },
				tail = false,
			})
			ears(c, p.dark, "tuft")
			c:box(V3(0.40, 0.40, 0.36), CF(0, -0.56, 0.98), C3(196, 140, 80))
			c:box(V3(0.46, 0.14, 0.42), CF(0, -0.32, 0.98), C3(110, 74, 44))
			for _, s in ipairs(SIDES) do
				c:box(V3(0.22, 0.24, 0.22), CF(0.26 * s, -0.50, 0.94), p.base)
			end
			c:box(V3(0.80, 0.80, 0.70), CF(0, -0.30, -1.05), p.light)
			c:box(V3(0.86, 0.90, 0.70), CF(0, 0.50, -1.30), p.light)
			c:box(V3(0.80, 0.70, 0.70), CF(0, 1.20, -1.10), p.light)
			c:box(V3(0.66, 0.56, 0.56), CF(0, 1.50, -0.62), p.pale)
		end,
	}

	S.er_t_owl = {
		label = "Hollowbark Owl",
		set = "eternal_roots",
		tint = C3(118, 104, 196),
		head = CF(0, 1.10, 0.06),
		neck = CF(0, -0.36, 0.70),
		back = CF(0, 0.20, -0.70),
		build = function(c, p)
			-- A round owl on a root branch: pale face discs, ear tufts, folded wings.
			local _, fz = block(c, p, {
				shape = "bird", bodySize = V3(1.90, 1.90, 1.60),
				eyeY = 0.24, eyeSpread = 0.42, eyeSize = V3(0.44, 0.52, 0.20),
				mouth = false,
				bib = { w = 0.90, h = 0.62, y = -0.50, color = p.pale },
				legSize = V3(0.34, 0.16, 0.40), legX = 0.36, legY = -0.94, legZ = { 0.30 }, legColor = GOLD,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V3(0.72, 0.72, 0.06), CF(0.42 * s, 0.24, fz + 0.01), p.pale)
			end
			c:cone(V3(0.22, 0.26, 0.20), CF(0, -0.06, fz + 0.12) * ANG(PI, 0, 0), GOLD)
			ears(c, p.dark, "tuft")
			wings(c, p.dark, 0.22, -0.04, -0.10, 0.10)
			c:box(V3(0.70, 0.20, 0.44), CF(0, -0.62, -0.92) * ANG(-0.40, 0, 0), p.deep)
			c:rod(V3(-1.10, -1.06, 0.30), V3(1.10, -1.06, 0.30), 0.10, BARK, WOOD, false)
			c:box(V3(0.30, 0.06, 0.22), CF(0.90, -0.94, 0.44) * ANG(0, 0.40, 0), LEAF)
		end,
	}

	S.er_t_trilobite = {
		label = "Cave Trilobite",
		set = "eternal_roots",
		tint = C3(92, 128, 168),
		scale = 1.15,
		head = CF(0, 0.10, 0.10),
		neck = CF(0, -0.40, 1.24),
		back = CF(0, -0.10, -1.20),
		build = function(c, p)
			-- Flat, segmented, three lobes nose to tail: the oldest thing in the caverns.
			c:box(V3(1.90, 0.50, 2.10), CF(0, -0.44, -0.10), p.base)
			c:box(V3(0.62, 0.30, 1.90), CF(0, -0.06, -0.16), p.dark)
			c:box(V3(2.10, 0.56, 0.70), CF(0, -0.36, 0.86), p.light)
			for _, z in ipairs({ 0.24, -0.10, -0.44, -0.78 }) do
				c:box(V3(1.96, 0.06, 0.10), CF(0, -0.17, z), p.deep)
			end
			c:box(V3(1.10, 0.40, 0.50), CF(0, -0.48, -1.32), p.light)
			c:box(V3(0.24, 0.30, 0.24), CF(0, -0.16, -1.30) * ANG(0, PI / 4, 0), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.30, -0.20, -0.70 }) do
					c:box(V3(0.34, 0.08, 0.12), CF(1.05 * s, -0.66, z) * ANG(0, 0, -0.30 * s), p.deep)
				end
				c:rod(V3(0.30 * s, -0.30, 1.20), V3(0.72 * s, -0.12, 1.70), 0.04, p.deep, nil, false)
				c:box(V3(0.34, 0.16, 0.30), CF(0.56 * s, -0.02, 0.90), p.dark)
			end
			c:eyes(-0.30, 1.22, 0.42, 0.14)
			c:box(V3(0.24, 0.06, 0.04), CF(0, -0.54, 1.22), INK)
		end,
	}

	S.er_t_samara = {
		label = "Whirligig Seed",
		set = "eternal_roots",
		tint = C3(214, 44, 96),
		scale = 1.15,
		head = CF(0, 0.66, 0.10),
		neck = CF(0, -0.60, 0.70),
		back = CF(0, 0.00, -0.70),
		build = function(c, p)
			-- A maple key mid-spin: a fat seed with twin veined wings swept up behind.
			c:box(V3(1.40, 1.30, 1.30), CF(0, -0.20, 0), p.base)
			c:cone(V3(0.50, 0.40, 0.50), CF(0, -1.05, 0) * ANG(PI, 0, 0), p.dark)
			for _, s in ipairs(SIDES) do
				local root = CF(0.40 * s, 0.30, -0.40) * ANG(0, 0, -0.50 * s)
				c:box(V3(0.80, 1.40, 0.10), root * CF(0, 0.70, 0), p.light)
				c:box(V3(0.60, 0.40, 0.10), root * CF(0.10 * s, 1.50, 0), p.light)
				c:box(V3(0.08, 1.40, 0.16), root * CF(-0.20 * s, 0.76, 0), p.dark)
				c:box(V3(0.06, 0.60, 0.14), root * CF(0.10 * s, 0.90, 0) * ANG(0, 0, 0.50 * s), p.dark)
			end
			c:box(V3(0.16, 0.20, 0.16), CF(0, 0.54, 0.10), p.deep)
			c:eyes(-0.10, 0.66, 0.30, 0.15)
			c:box(V3(0.22, 0.08, 0.05), CF(0, -0.42, 0.66), INK)
			cheeks(c, -0.32, 0.66, 0.50, 0.18)
		end,
	}

	S.er_t_dandelion = {
		label = "Dandelion Puff",
		set = "eternal_roots",
		tint = C3(252, 226, 70),
		scale = 1.25,
		head = CF(0, 0.66, 0),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.10, -0.70),
		build = function(c, p)
			-- A seed head drifting free, its parachutes standing out all round it
			-- (none in front, so the face stays clear).
			c:box(V3(1.30, 1.30, 1.30), CF(0, 0, 0), p.base)
			local dirs = {
				V3(0, 1, 0), V3(0.87, 0.5, 0), V3(-0.87, 0.5, 0), V3(0.87, -0.5, 0),
				V3(-0.87, -0.5, 0), V3(0, 0.6, -0.8), V3(0, -0.6, -0.8), V3(0, -1, 0),
			}
			for _, d in ipairs(dirs) do
				c:rod(d * 0.62, d * 1.12, 0.035, p.light, nil, false)
				c:box(V3(0.44, 0.44, 0.44), CF(d * 1.30) * ANG(0.6, 0.6, 0), p.pale)
			end
			c:eyes(0.08, 0.66, 0.28, 0.15)
			c:box(V3(0.22, 0.08, 0.05), CF(0, -0.24, 0.66), INK)
			cheeks(c, -0.14, 0.66, 0.46, 0.16)
		end,
	}

	S.er_t_platypus = {
		label = "Brook Platypus",
		set = "eternal_roots",
		tint = C3(70, 170, 220),
		head = CF(0, 0.84, 0.10),
		neck = CF(0, -0.30, 0.90),
		back = CF(0, 0.20, -0.90),
		build = function(c, p)
			-- Low and flat: a broad duck bill in front, a paddle tail behind.
			block(c, p, {
				bodySize = V3(1.90, 1.30, 2.00),
				eyeY = 0.20, eyeSpread = 0.46, eyeSize = V3(0.34, 0.40, 0.18),
				snout = { w = 0.96, h = 0.22, d = 0.66, y = -0.12, color = p.deep, nose = p.deep },
				legSize = V3(0.52, 0.16, 0.56), legX = 0.82, legY = -0.62, legZ = { 0.46, -0.46 },
				legColor = p.dark,
				tail = false,
			})
			c:box(V3(1.00, 0.18, 0.96), CF(0, -0.36, -1.40), p.dark)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.06, 0.20, 0.80), CF(0.22 * s, -0.35, -1.40), p.deep)
			end
			cheeks(c, -0.02, 1.01, 0.66, 0.20)
			c:ball(V3(0.20, 0.24, 0.20), CF(0.40, 0.84, 0.30), WATER, GLASS)
		end,
	}

	S.er_t_bee = {
		label = "Blossom Bee",
		set = "eternal_roots",
		tint = C3(255, 186, 30),
		head = CF(0, 1.06, 0.10),
		neck = CF(0, -0.36, 0.80),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			-- A round bumblebee with a flower tucked behind one antenna.
			block(c, p, {
				shape = "round", bodySize = V3(1.90, 1.70, 1.80),
				eyeY = 0.20, eyeSpread = 0.42, eyeSize = V3(0.46, 0.54, 0.20),
				mouthY = -0.30, mouthSize = V3(0.26, 0.12, 0.12),
				legSize = V3(0.24, 0.30, 0.24), legX = 0.42, legY = -0.86, legZ = { 0.24 }, legColor = INK,
				tail = false,
			})
			for _, z in ipairs({ -0.20, -0.58 }) do
				c:box(V3(2.02, 1.80, 0.16), CF(0, 0.06, z), INK)
			end
			c:cone(V3(0.20, 0.34, 0.20), CF(0, -0.06, -1.06) * ANG(-PI / 2, 0, 0), INK)
			for _, s in ipairs(SIDES) do
				local w = c:box(V3(0.90, 0.06, 0.60), CF(0.50 * s, 1.02, -0.20) * ANG(0, 0, 0.45 * s), p.pale, GLASS)
				w.Transparency = 0.3
				c:rod(V3(0.22 * s, 0.90, 0.40), V3(0.40 * s, 1.36, 0.62), 0.035, INK, nil, false)
			end
			c:box(V3(0.44, 0.10, 0.16), CF(-0.50, 0.96, 0.40), BLUSH)
			c:box(V3(0.16, 0.10, 0.44), CF(-0.50, 0.96, 0.40), BLUSH)
			c:box(V3(0.14, 0.14, 0.14), CF(-0.50, 1.00, 0.40), GOLD)
		end,
	}

	S.er_t_otter = {
		label = "Hotspring Otter",
		set = "eternal_roots",
		tint = C3(150, 96, 70),
		head = CF(0, 1.16, 0.06),
		neck = CF(0, 0.00, 0.70),
		back = CF(0, 0.20, -0.60),
		build = function(c, p)
			-- Soaking in a washtub of hot spring water, towel folded on its head.
			c:box(V3(2.00, 0.94, 1.84), CF(0, -0.55, 0), C3(150, 104, 66), WOOD)
			for _, y in ipairs({ -0.30, -0.82 }) do
				c:box(V3(2.04, 0.10, 1.88), CF(0, y, 0), C3(120, 124, 132), METAL)
			end
			local water = c:box(V3(1.84, 0.06, 1.68), CF(0, -0.07, 0), WATER, GLASS)
			water.Transparency = 0.15
			c:box(V3(1.36, 1.20, 1.10), CF(0, 0.30, 0.06), p.base)
			c:box(V3(0.66, 0.34, 0.20), CF(0, 0.14, 0.66), p.pale)
			c:box(V3(0.20, 0.12, 0.08), CF(0, 0.27, 0.78), NOSE)
			c:eyes(0.48, 0.62, 0.30, 0.12)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.24, 0.20, 0.16), CF(0.56 * s, 0.94, 0.00), p.dark)
				c:box(V3(0.26, 0.20, 0.30), CF(0.48 * s, -0.02, 0.84), p.base)
			end
			c:box(V3(0.76, 0.16, 0.56), CF(0, 0.98, 0.04), WHITE)
			c:box(V3(0.76, 0.08, 0.22), CF(0, 1.09, 0.10), C3(140, 200, 240))
			for _, v in ipairs({ { 0.70, 0.36, -0.60, 0.36 }, { -0.70, 0.18, -0.50, 0.30 } }) do
				local puff = c:ball(V3(v[4], v[4], v[4]), CF(v[1], v[2], v[3]), WHITE)
				puff.Transparency = 0.35
			end
		end,
	}

	S.er_t_fiddle = {
		label = "Fiddlehead Sprite",
		set = "eternal_roots",
		tint = C3(160, 230, 80),
		head = CF(0, 0.30, -0.30),
		neck = CF(0, -0.70, 0.60),
		back = CF(0, -0.40, -0.60),
		build = function(c, p)
			-- A fern sprite: a leaf skirt below and an uncurling fiddlehead above,
			-- its spiral rolling forward over its face like a cowlick.
			c:box(V3(1.30, 1.20, 1.10), CF(0, -0.42, 0), p.base)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					local a = math.atan2(-0.52 * t, 0.72 * s)
					c:box(V3(0.56, 0.08, 0.34), CF(0.72 * s, -0.86, 0.52 * t) * ANG(0, a, -0.30), LEAF)
				end
			end
			local curl = {
				{ V3(0.30, 0.56, 0.30), CF(0, 0.46, -0.12), p.dark },
				{ V3(0.30, 0.44, 0.30), CF(0, 0.92, -0.08), p.dark },
				{ V3(0.30, 0.34, 0.38), CF(0, 1.20, 0.10) * ANG(-0.6, 0, 0), p.light },
				{ V3(0.30, 0.30, 0.30), CF(0, 1.26, 0.40), p.light },
				{ V3(0.30, 0.34, 0.30), CF(0, 1.06, 0.56), p.light },
				{ V3(0.26, 0.26, 0.26), CF(0, 0.86, 0.40), p.glow },
			}
			for _, k in ipairs(curl) do
				c:box(k[1], k[2], k[3])
			end
			for _, s in ipairs(SIDES) do
				c:box(V3(0.40, 0.08, 0.18), CF(0.28 * s, 0.50, -0.12) * ANG(0, 0, 0.30 * s), p.light)
				c:box(V3(0.32, 0.08, 0.16), CF(0.24 * s, 0.86, -0.08) * ANG(0, 0, 0.30 * s), p.light)
				c:box(V3(0.36, 0.18, 0.40), CF(0.32 * s, -1.08, 0.10), p.dark)
			end
			c:eyes(-0.30, 0.56, 0.28, 0.14)
			c:box(V3(0.20, 0.08, 0.05), CF(0, -0.60, 0.56), INK)
			cheeks(c, -0.52, 0.56, 0.44, 0.16)
		end,
	}

	S.er_t_koi = {
		label = "Wellspring Koi",
		set = "eternal_roots",
		tint = C3(255, 120, 70),
		head = CF(0, 0.78, 0.40),
		neck = CF(0, -0.50, 1.00),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			-- A calico koi from the buried spring: barbels, a fan tail, a bubble.
			c:box(V3(1.40, 1.40, 2.00), CF(0, 0, 0.10), p.base)
			c:box(V3(0.80, 0.06, 0.70), CF(0.20, 0.72, 0.30), p.pale)
			c:box(V3(0.70, 0.06, 0.60), CF(-0.24, 0.72, -0.50), p.deep)
			c:box(V3(0.06, 0.60, 0.70), CF(0.72, 0.10, -0.30), p.pale)
			c:box(V3(0.06, 0.50, 0.60), CF(-0.72, -0.10, 0.30), p.deep)
			c:box(V3(0.10, 0.50, 1.00), CF(0, 0.90, -0.20), p.light)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.56, 0.08, 0.40), CF(0.86 * s, -0.36, 0.40) * ANG(0, 0, -0.40 * s), p.light)
				c:box(V3(0.10, 0.84, 0.70), CF(0, 0.30 * s, -1.20) * ANG(-0.60 * s, 0, 0), p.light)
				c:rod(V3(0.30 * s, -0.32, 1.12), V3(0.46 * s, -0.66, 1.24), 0.03, p.dark, nil, false)
			end
			c:box(V3(0.30, 0.24, 0.10), CF(0, -0.26, 1.13), BLUSH)
			c:eyes(0.20, 1.12, 0.40, 0.15)
			local bubble = c:ball(V3(0.24, 0.24, 0.24), CF(0.30, 0.50, 1.40), WATER, GLASS)
			bubble.Transparency = 0.3
		end,
	}

	S.er_t_hermit = {
		label = "Nutshell Hermit",
		set = "eternal_roots",
		tint = C3(186, 70, 160),
		head = CF(0, 1.16, -0.36),
		neck = CF(0, -0.60, 0.90),
		back = CF(0, 0.30, -1.20),
		build = function(c, p)
			-- A hermit crab that moved into a walnut shell.
			c:box(V3(1.80, 1.60, 1.60), CF(0, 0.30, -0.36), p.base)
			c:box(V3(0.12, 1.68, 1.68), CF(0, 0.30, -0.36), p.dark)
			for _, s in ipairs(SIDES) do
				for _, v in ipairs({ { 0.60, 0.10 }, { 0.20, -0.70 } }) do
					c:box(V3(0.06, 0.70, 0.20), CF(0.92 * s, v[1], v[2]) * ANG(0.50, 0, 0), p.dark)
				end
				c:box(V3(0.50, 0.06, 0.16), CF(0.46 * s, 1.12, -0.36), p.dark)
			end
			c:box(V3(1.30, 0.60, 0.70), CF(0, -0.54, 0.50), p.light)
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.24 * s, -0.28, 0.70), V3(0.32 * s, 0.18, 0.86), 0.05, p.light, nil, false)
				c:eye(V3(0.32 * s, 0.26, 0.88), 0.14)
				for _, z in ipairs({ 0.30, -0.10 }) do
					c:rod(V3(0.62 * s, -0.70, z), V3(0.96 * s, -0.96, z - 0.20), 0.05, p.dark, nil, false)
				end
			end
			c:box(V3(0.24, 0.06, 0.04), CF(0, -0.56, 0.86), INK)
			c:box(V3(0.50, 0.40, 0.50), CF(0.80, -0.54, 0.86), p.dark)
			c:box(V3(0.40, 0.14, 0.30), CF(0.80, -0.26, 1.00), p.dark)
			c:box(V3(0.34, 0.30, 0.36), CF(-0.74, -0.58, 0.80), p.dark)
		end,
	}

	S.er_t_bat = {
		label = "Rootcave Bat",
		set = "eternal_roots",
		tint = C3(70, 58, 120),
		scale = 1.3,
		head = CF(0, 1.16, 0),
		neck = CF(0, -0.36, 0.64),
		back = CF(0, 0.20, -0.64),
		build = function(c, p)
			-- A cavern bat on the wing, carrying a glowing root-berry home.
			block(c, p, {
				shape = "round", bodySize = V3(1.60, 1.60, 1.40),
				eyeY = 0.16, eyeSpread = 0.36, eyeSize = V3(0.40, 0.48, 0.18),
				mouthY = -0.30, mouthSize = V3(0.28, 0.10, 0.10),
				legs = false, tail = false,
			})
			c:box(V3(0.08, 0.12, 0.05), CF(0.08, -0.40, 0.71), WHITE)
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.44, 0.70, 0.30), CF(0.42 * s, 1.16, 0.00), p.dark)
				c:box(V3(0.62, 0.84, 0.08), CF(1.00 * s, 0.24, -0.18) * ANG(0, 0, -0.30 * s), p.dark)
				c:box(V3(0.52, 0.66, 0.08), CF(1.40 * s, 0.50, -0.18) * ANG(0, 0, -0.70 * s), p.dark)
				c:rod(V3(0.76 * s, 0.62, -0.18), V3(1.66 * s, 0.86, -0.18), 0.04, p.deep, nil, false)
				c:box(V3(0.20, 0.16, 0.20), CF(0.20 * s, -0.80, 0.24), p.deep)
			end
			c:ball(V3(0.32, 0.32, 0.32), CF(0, -0.98, 0.26), p.glow, NEON)
			c:light(p.glow, 1, 6)
		end,
	}

	----------------------------------------------------------------------------
	-- LEGENDARY: more ornate.
	----------------------------------------------------------------------------

	S.er_t_stag = {
		label = "Mossantler Stag",
		set = "eternal_roots",
		tint = C3(222, 160, 96),
		scale = 1.1,
		head = CF(0, 1.00, 0.30),
		neck = CF(0, -0.30, 0.90),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			-- A young stag whose antlers are living roots, sprouting leaves and moss.
			block(c, p, {
				bodySize = V3(1.60, 1.40, 1.80),
				eyeY = 0.22, eyeSpread = 0.38, eyeSize = V3(0.36, 0.44, 0.18),
				snout = { w = 0.60, h = 0.40, d = 0.34, y = -0.20, color = p.pale, nose = INK },
				legSize = V3(0.30, 0.56, 0.32), legY = -0.80, legX = 0.52, legZ = { 0.56, -0.56 },
				tailSize = V3(0.30, 0.30, 0.20), tailColor = p.pale,
			})
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.30 * s, 0.76, 0.30), V3(0.62 * s, 1.30, 0.16), 0.07, p.dark, nil, false)
				c:rod(V3(0.62 * s, 1.30, 0.16), V3(1.00 * s, 1.56, 0.00), 0.06, p.dark, nil, false)
				c:rod(V3(0.50 * s, 1.10, 0.22), V3(0.40 * s, 1.46, 0.40), 0.05, p.dark, nil, false)
				c:rod(V3(0.62 * s, 1.30, 0.16), V3(0.70 * s, 1.66, 0.10), 0.05, p.dark, nil, false)
				c:box(V3(0.30, 0.06, 0.20), CF(1.04 * s, 1.60, 0) * ANG(0, 0, 0.40 * s), LEAF)
				c:box(V3(0.22, 0.06, 0.16), CF(0.40 * s, 1.50, 0.42), LEAF_DARK)
				c:box(V3(0.20, 0.16, 0.20), CF(0.56 * s, 1.22, 0.18), LEAF)
				c:box(V3(0.36, 0.18, 0.12), CF(0.88 * s, 0.56, 0.40) * ANG(0, 0, 0.35 * s), p.base)
			end
			-- Fawn spots along the back.
			for _, v in ipairs({ { 0.36, -0.20 }, { -0.30, -0.50 }, { 0.10, -0.72 } }) do
				c:box(V3(0.20, 0.06, 0.20), CF(v[1], 0.77, v[2]), p.pale)
			end
		end,
	}

	S.er_t_mammoth = {
		label = "Mossback Mammoth",
		set = "eternal_roots",
		tint = C3(110, 140, 66),
		scale = 1.1,
		head = CF(0, 1.18, 0.40),
		neck = CF(0, -0.60, 1.10),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			-- A woolly calf from the deep past with a moss garden growing on its back.
			block(c, p, {
				bodySize = V3(2.00, 1.70, 1.90),
				eyeY = 0.30, eyeSpread = 0.44, eyeSize = V3(0.32, 0.40, 0.18),
				mouth = false,
				legSize = V3(0.50, 0.40, 0.50), legY = -0.90, legX = 0.58, legZ = { 0.50, -0.50 }, legColor = p.dark,
				tailSize = V3(0.16, 0.40, 0.16), tailColor = p.dark,
			})
			-- The trunk, curling at the tip.
			c:box(V3(0.40, 0.50, 0.36), CF(0, -0.02, 1.08), p.base)
			c:box(V3(0.34, 0.40, 0.32), CF(0, -0.42, 1.18), p.base)
			c:box(V3(0.30, 0.22, 0.34), CF(0, -0.66, 1.30), p.light)
			c:box(V3(1.10, 0.26, 0.70), CF(0, 1.04, 0.50), p.base)
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.36 * s, -0.30, 0.96), V3(0.52 * s, -0.70, 1.26), 0.06, IVORY, nil, false)
				c:rod(V3(0.52 * s, -0.70, 1.26), V3(0.44 * s, -0.50, 1.56), 0.05, IVORY, nil, false)
				c:box(V3(0.10, 0.80, 0.70), CF(1.05 * s, 0.30, 0.40), p.dark)
				for _, z in ipairs({ 0.30, -0.40 }) do
					c:box(V3(0.14, 0.44, 0.44), CF(1.02 * s, -0.50, z), p.dark)
				end
			end
			-- Moss on its back, a sapling and a little toadstool.
			c:box(V3(1.50, 0.12, 1.00), CF(0, 0.97, -0.35), LEAF_DARK)
			c:rod(V3(0.30, 1.02, -0.40), V3(0.36, 1.50, -0.44), 0.05, BARK, nil, false)
			c:box(V3(0.40, 0.06, 0.22), CF(0.52, 1.50, -0.44) * ANG(0, 0, 0.30), LEAF)
			c:box(V3(0.36, 0.06, 0.20), CF(0.20, 1.44, -0.44) * ANG(0, 0, -0.30), LEAF)
			c:box(V3(0.24, 0.12, 0.24), CF(-0.50, 1.12, -0.30), BLUSH)
		end,
	}

	S.er_t_nautilus = {
		label = "Spring Nautilus",
		set = "eternal_roots",
		tint = C3(150, 230, 220),
		head = CF(0, 1.30, -0.30),
		neck = CF(0, -0.70, 1.00),
		back = CF(0, 0.30, -1.30),
		build = function(c, p)
			-- A living fossil drifting through the buried spring: a coiled shell
			-- behind, a soft face peeking from its mouth, tentacles trailing below.
			c:cyl(V3(1.00, 2.20, 2.20), CF(0, 0.20, -0.30), p.base)
			c:cyl(V3(1.08, 1.50, 1.50), CF(0, 0.36, -0.50), p.light)
			c:cyl(V3(1.16, 0.90, 0.90), CF(0, 0.46, -0.66), p.base)
			c:cyl(V3(1.24, 0.40, 0.40), CF(0, 0.52, -0.76), p.pale)
			-- Ribs radiating round the outer whorl.
			for _, a in ipairs({ 0.5, 1.6, 2.7, 3.8, 4.9 }) do
				c:box(V3(1.04, 0.06, 0.40), CF(0, 0.20 + 0.86 * math.sin(a), -0.30 + 0.86 * math.cos(a)) * ANG(-a, 0, 0), p.dark)
			end
			c:box(V3(1.10, 0.90, 0.60), CF(0, -0.20, 0.80), p.pale)
			c:box(V3(1.24, 0.20, 0.70), CF(0, 0.32, 0.80), p.dark)
			c:eyes(-0.06, 1.11, 0.30, 0.15)
			c:box(V3(0.22, 0.08, 0.05), CF(0, -0.40, 1.11), INK)
			cheeks(c, -0.30, 1.11, 0.46, 0.16)
			for _, x in ipairs({ -0.40, -0.14, 0.14, 0.40 }) do
				local mid = V3(x * 1.4, -1.06, 1.06 - math.abs(x) * 0.3)
				c:rod(V3(x, -0.60, 0.90), mid, 0.06, p.light, nil, false)
				c:rod(mid, mid + V3(0, 0.16, 0.22), 0.05, p.light, nil, false)
			end
			for _, b in ipairs({ { 0.40, 1.10, 1.30, 0.20 }, { 0.62, 1.40, 1.10, 0.14 } }) do
				local bubble = c:ball(V3(b[4], b[4], b[4]), CF(b[1], b[2], b[3]), WATER, GLASS)
				bubble.Transparency = 0.3
			end
		end,
	}

	S.er_t_dragonfly = {
		label = "Amber Dragonfly",
		set = "eternal_roots",
		tint = C3(40, 120, 255),
		scale = 1.25,
		head = CF(0, 0.84, 0.70),
		neck = CF(0, -0.36, 1.14),
		back = CF(0, 0.40, -0.50),
		build = function(c, p)
			-- A darter over the spring pools, four glassy wings out flat and a bead
			-- of amber sap carried on the tip of its tail.
			c:box(V3(1.20, 1.00, 0.86), CF(0, 0.20, 0.70), p.base)
			c:box(V3(0.90, 0.86, 0.80), CF(0, 0.16, -0.10), p.light)
			for i, sg in ipairs({ { 0.56, -0.62 }, { 0.48, -0.98 }, { 0.40, -1.30 }, { 0.32, -1.58 } }) do
				c:box(V3(sg[1], sg[1], 0.40), CF(0, 0.16 - i * 0.04, sg[2]), (i % 2 == 0) and p.dark or p.base)
			end
			c:ball(V3(0.34, 0.34, 0.34), CF(0, 0.02, -1.92), GOLD, GLASS)
			for _, s in ipairs(SIDES) do
				c:eye(V3(0.36 * s, 0.38, 1.12), 0.21)
				for _, w in ipairs({ { 0.16, 0.10 }, { -0.30, -0.12 } }) do
					local cf = CF(0.85 * s, 0.62, w[1]) * ANG(0, w[2] * s, 0.12 * s)
					local wing = c:box(V3(1.30, 0.04, 0.40), cf, p.pale, GLASS)
					wing.Transparency = 0.35
					c:box(V3(1.20, 0.06, 0.04), cf, p.dark)
				end
				for _, z in ipairs({ 0.10, -0.26 }) do
					c:rod(V3(0.30 * s, -0.24, z), V3(0.56 * s, -0.70, z + 0.10), 0.04, INK, nil, false)
				end
				c:rod(V3(0.20 * s, 0.70, 1.00), V3(0.34 * s, 1.00, 1.20), 0.03, p.dark, nil, false)
			end
			c:box(V3(0.30, 0.08, 0.05), CF(0, -0.10, 1.14), INK)
			cheeks(c, 0.04, 1.14, 0.48, 0.16)
		end,
	}

	S.er_t_beaver = {
		label = "Dam Beaver",
		set = "eternal_roots",
		tint = C3(140, 84, 50),
		head = CF(0, 1.04, 0.10),
		neck = CF(0, -0.10, 1.00),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			-- The spring's dam builder, hugging a fresh-cut log, its flat tail behind.
			block(c, p, {
				shape = "round", bodySize = V3(1.80, 1.60, 1.60),
				eyeY = 0.26, eyeSpread = 0.38, eyeSize = V3(0.36, 0.44, 0.18),
				snout = { w = 0.62, h = 0.36, d = 0.30, y = -0.02, color = p.pale, nose = INK },
				legSize = V3(0.40, 0.24, 0.46), legX = 0.50, legY = -0.80, legZ = { 0.30, -0.40 },
				tail = false,
			})
			ears(c, p.dark, "round")
			c:box(V3(0.24, 0.20, 0.06), CF(0, -0.30, 0.96), WHITE)
			c:box(V3(0.02, 0.20, 0.07), CF(0, -0.30, 0.96), INK)
			c:cyl(V3(1.90, 0.40, 0.40), CF(0, -0.56, 1.00), BARK, WOOD)
			for _, s in ipairs(SIDES) do
				c:cyl(V3(0.04, 0.34, 0.34), CF(0.96 * s, -0.56, 1.00), C3(226, 186, 128))
				c:box(V3(0.26, 0.24, 0.24), CF(0.42 * s, -0.30, 1.10), p.dark)
			end
			c:box(V3(0.26, 0.06, 0.16), CF(0.70, -0.32, 1.08) * ANG(0, 0, 0.50), LEAF)
			c:box(V3(0.90, 0.18, 1.10), CF(0, -0.66, -1.30), p.deep)
			for _, z in ipairs({ -1.00, -1.30, -1.60 }) do
				c:box(V3(0.80, 0.04, 0.05), CF(0, -0.56, z), p.dark)
			end
		end,
	}

	S.er_t_heron = {
		label = "Springwade Heron",
		set = "eternal_roots",
		tint = C3(200, 220, 240),
		scale = 1.1,
		head = CF(0, 1.20, 0.00),
		neck = CF(0, 0.10, 0.66),
		back = CF(0, 0.40, -0.66),
		build = function(c, p)
			-- A tall wading bird standing in its spring pool on stilt legs, a fish
			-- in its beak.
			c:box(V3(1.20, 1.50, 1.20), CF(0, 0.30, 0), p.base)
			c:box(V3(0.80, 0.50, 0.06), CF(0, -0.10, 0.62), p.pale)
			c:box(V3(1.22, 0.12, 1.22), CF(0, 1.06, 0), p.dark)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.10, 0.90, 1.00), CF(0.64 * s, 0.30, -0.10), p.light)
				c:box(V3(0.10, 0.30, 0.50), CF(0.64 * s, -0.10, -0.66), p.dark)
				c:rod(V3(0.26 * s, -0.40, 0.04), V3(0.26 * s, -1.02, 0.10), 0.05, GOLD, nil, false)
				c:box(V3(0.30, 0.06, 0.40), CF(0.26 * s, -1.06, 0.20), GOLD)
			end
			c:box(V3(0.70, 0.20, 0.50), CF(0, -0.20, -0.80) * ANG(0.40, 0, 0), p.dark)
			c:rod(V3(0, 1.00, -0.30), V3(0, 1.30, -0.90), 0.04, p.dark, nil, false)
			c:rod(V3(0, 1.00, -0.30), V3(0.10, 1.20, -0.96), 0.04, p.dark, nil, false)
			c:box(V3(0.24, 0.20, 0.70), CF(0, 0.56, 0.94), GOLD)
			c:cone(V3(0.22, 0.30, 0.20), CF(0, 0.56, 1.43) * ANG(PI / 2, 0, 0), GOLD)
			c:box(V3(0.40, 0.18, 0.10), CF(0.10, 0.48, 1.16), C3(255, 170, 90))
			c:box(V3(0.12, 0.24, 0.06), CF(0.34, 0.48, 1.16), C3(255, 170, 90))
			c:eyes(0.76, 0.62, 0.30, 0.13)
			cheeks(c, 0.40, 0.62, 0.44, 0.16)
			local pool = c:cyl(V3(0.10, 2.20, 2.20), CF(0, -1.12, 0.10) * ANG(0, 0, PI / 2), WATER, GLASS)
			pool.Transparency = 0.25
			c:rod(V3(-0.80, -1.10, -0.50), V3(-0.86, -0.30, -0.56), 0.04, LEAF_DARK, nil, false)
			c:box(V3(0.12, 0.30, 0.12), CF(-0.86, -0.20, -0.56), BARK)
			c:cyl(V3(0.04, 0.50, 0.50), CF(0.70, -1.05, 0.50) * ANG(0, 0, PI / 2), LEAF)
		end,
	}

	S.er_t_lantern = {
		label = "Rootlamp Lantern",
		set = "eternal_roots",
		tint = C3(255, 160, 40),
		scale = 1.1,
		head = CF(0, 1.30, 0.30),
		neck = CF(0, -0.70, 0.76),
		back = CF(0, 0.00, -0.76),
		build = function(c, p)
			-- A little lantern hung from a root deep in the caverns to light the way
			-- home: its glass glows on three sides and its face is on the fourth.
			c:box(V3(1.30, 1.30, 1.30), CF(0, -0.10, 0), p.base)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.04, 0.90, 0.90), CF(0.66 * s, -0.10, 0), p.glow, NEON)
				for _, t in ipairs(SIDES) do
					c:box(V3(0.18, 1.40, 0.18), CF(0.64 * s, -0.10, 0.64 * t), p.dark)
				end
			end
			c:box(V3(0.90, 0.90, 0.04), CF(0, -0.10, -0.66), p.glow, NEON)
			c:box(V3(1.56, 0.20, 1.56), CF(0, -0.86, 0), p.dark)
			c:box(V3(1.62, 0.16, 1.62), CF(0, 0.62, 0), p.dark)
			c:cone(V3(1.40, 0.56, 1.40), CF(0, 0.98, 0), p.deep)
			c:ball(V3(0.24, 0.24, 0.24), CF(0, 1.32, 0), GOLD, METAL)
			c:cyl(V3(0.08, 0.36, 0.36), CF(0, 1.52, 0), GOLD, METAL)
			c:rod(V3(-1.30, 1.70, -0.10), V3(1.30, 1.66, 0.10), 0.12, BARK, WOOD, false)
			c:box(V3(0.34, 0.06, 0.20), CF(-0.90, 1.84, -0.06) * ANG(0, 0, 0.30), LEAF)
			c:box(V3(0.30, 0.06, 0.18), CF(1.00, 1.80, 0.08) * ANG(0, 0, -0.30), LEAF_DARK)
			c:rod(V3(-0.96, 1.66, -0.06), V3(-0.84, 0.90, 0.30), 0.05, BARK, nil, false)
			c:eyes(0.06, 0.66, 0.30, 0.15)
			c:box(V3(0.24, 0.08, 0.05), CF(0, -0.30, 0.66), INK)
			cheeks(c, -0.16, 0.66, 0.44, 0.16)
			c:light(p.glow, 1.2, 8)
		end,
	}

	S.er_t_sloth = {
		label = "Rootswing Sloth",
		set = "eternal_roots",
		tint = C3(176, 160, 120),
		scale = 1.2,
		head = CF(0, 0.76, 0.10),
		neck = CF(0, -0.40, 0.66),
		back = CF(0, 0.00, -0.66),
		build = function(c, p)
			-- Hanging by both arms from a root across the cavern roof, smiling, in
			-- no hurry at all.
			c:rod(V3(-1.40, 1.30, 0), V3(1.40, 1.30, 0), 0.14, BARK, WOOD, false)
			c:box(V3(0.34, 0.06, 0.20), CF(-1.00, 1.46, 0.06) * ANG(0, 0, 0.30), LEAF)
			c:box(V3(0.30, 0.06, 0.18), CF(1.10, 1.42, -0.04) * ANG(0, 0, -0.30), LEAF_DARK)
			c:box(V3(1.40, 1.50, 1.20), CF(0, -0.10, 0), p.base)
			c:box(V3(1.20, 1.10, 0.10), CF(0, -0.10, -0.64), p.light)
			c:box(V3(0.70, 0.12, 0.60), CF(0, 0.70, 0), LEAF_DARK)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.12, 0.90, 0.80), CF(0.74 * s, -0.20, -0.10), p.light)
				c:rod(V3(0.52 * s, 0.40, 0.10), V3(0.56 * s, 1.16, 0.10), 0.17, p.base, nil, false)
				c:box(V3(0.30, 0.20, 0.34), CF(0.56 * s, 1.30, 0.12), p.deep)
				c:box(V3(0.34, 0.40, 0.36), CF(0.40 * s, -0.98, 0.20), p.base)
				c:box(V3(0.34, 0.20, 0.04), CF(0.26 * s, 0.20, 0.645) * ANG(0, 0, -0.25 * s), p.dark)
			end
			c:box(V3(1.04, 0.80, 0.06), CF(0, 0.12, 0.61), p.pale)
			c:eyes(0.20, 0.67, 0.26, 0.12)
			c:box(V3(0.20, 0.12, 0.06), CF(0, 0.02, 0.66), NOSE)
			c:box(V3(0.34, 0.06, 0.04), CF(0, -0.14, 0.66), INK)
			cheeks(c, -0.06, 0.65, 0.42, 0.14)
		end,
	}

	S.er_t_geode = {
		label = "Cavern Geode",
		set = "eternal_roots",
		tint = C3(170, 80, 230),
		head = CF(0, 1.50, -0.10),
		neck = CF(0, -0.50, 0.96),
		back = CF(0, 0.10, -0.96),
		build = function(c, p)
			-- A round cavern stone cracked open on top, its hollow full of crystals.
			c:box(V3(1.90, 1.50, 1.80), CF(0, -0.20, 0), p.deep)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.10, 0.70, 0.90), CF(0.98 * s, -0.20, 0.10) * ANG(0.20, 0, 0), p.dark)
				c:box(V3(0.40, 0.20, 0.44), CF(0.50 * s, -1.04, 0.20), p.dark)
			end
			c:box(V3(1.00, 0.60, 0.10), CF(0.20, -0.40, -0.93), p.dark)
			c:box(V3(1.98, 0.14, 1.88), CF(0, 0.56, 0), p.pale)
			local crystals = {
				{ V3(0.50, 1.00, 0.50), CF(0, 1.05, -0.20), p.base },
				{ V3(0.40, 0.76, 0.40), CF(0.46, 0.94, 0.10) * ANG(0, 0, -0.30), p.light },
				{ V3(0.40, 0.70, 0.40), CF(-0.50, 0.90, -0.10) * ANG(0, 0, 0.30), p.light },
				{ V3(0.34, 0.60, 0.34), CF(0.20, 0.86, -0.60) * ANG(-0.30, 0, 0), p.base },
				{ V3(0.30, 0.50, 0.30), CF(-0.40, 0.82, 0.40) * ANG(0.20, 0, 0.20), p.glow, NEON },
				{ V3(0.30, 0.54, 0.30), CF(0.60, 0.84, -0.50) * ANG(-0.20, 0, -0.30), p.glow, NEON },
			}
			for _, k in ipairs(crystals) do
				c:cone(k[1], k[2], k[3], k[4])
			end
			c:eyes(-0.10, 0.92, 0.36, 0.16)
			c:box(V3(0.30, 0.10, 0.05), CF(0, -0.46, 0.92), INK)
			cheeks(c, -0.32, 0.92, 0.62, 0.20)
			c:box(V3(0.14, 0.14, 0.04), CF(0.70, 0.30, 0.92), p.light)
			c:box(V3(0.14, 0.14, 0.04), CF(-0.72, -0.70, 0.92), p.light)
			c:light(p.glow, 1, 6)
		end,
	}

	S.er_t_can = {
		label = "Sprinkle Can",
		set = "eternal_roots",
		tint = C3(50, 160, 120),
		scale = 1.15,
		head = CF(-0.30, 1.40, 0),
		neck = CF(-0.30, -0.50, 0.80),
		back = CF(-0.30, 0.00, -0.80),
		build = function(c, p)
			-- The old gardener's watering can, still sprinkling the roots, with a
			-- sprout growing out of its lid.
			local cx = -0.30
			c:cyl(V3(1.60, 1.60, 1.60), CF(cx, -0.10, 0) * ANG(0, 0, PI / 2), p.base)
			for _, y in ipairs({ 0.62, -0.82 }) do
				c:cyl(V3(0.10, 1.66, 1.66), CF(cx, y, 0) * ANG(0, 0, PI / 2), p.dark)
			end
			c:cyl(V3(0.08, 1.20, 1.20), CF(cx, 0.74, 0) * ANG(0, 0, PI / 2), p.light)
			c:rod(V3(cx + 0.60, -0.50, 0), V3(cx + 1.50, 0.40, 0), 0.12, p.base, nil, false)
			c:cyl(V3(0.16, 0.40, 0.40), CF(cx + 1.56, 0.46, 0) * ANG(0, 0, PI / 4), p.dark)
			for _, d in ipairs({ { 1.70, 0.20, 0.10 }, { 1.80, -0.10, -0.10 }, { 1.66, -0.40, 0.05 } }) do
				c:ball(V3(0.14, 0.14, 0.14), CF(cx + d[1], d[2], d[3]), WATER, GLASS)
			end
			c:rod(V3(cx - 0.50, 0.74, -0.20), V3(cx - 0.30, 1.16, -0.20), 0.07, p.dark, nil, false)
			c:rod(V3(cx - 0.30, 1.16, -0.20), V3(cx + 0.30, 1.16, -0.20), 0.07, p.dark, nil, false)
			c:rod(V3(cx + 0.30, 1.16, -0.20), V3(cx + 0.50, 0.74, -0.20), 0.07, p.dark, nil, false)
			c:rod(V3(cx, 0.78, 0.30), V3(cx, 1.10, 0.30), 0.04, LEAF_DARK, nil, false)
			c:box(V3(0.30, 0.06, 0.18), CF(cx + 0.16, 1.12, 0.30) * ANG(0, 0, 0.40), LEAF)
			c:box(V3(0.30, 0.06, 0.18), CF(cx - 0.16, 1.12, 0.30) * ANG(0, 0, -0.40), LEAF)
			for _, s in ipairs(SIDES) do
				c:eye(V3(cx + 0.28 * s, 0.10, 0.76), 0.15)
				c:box(V3(0.18, 0.10, 0.04), CF(cx + 0.46 * s, -0.08, 0.66) * ANG(0, 0.60 * s, 0), BLUSH)
			end
			c:box(V3(0.24, 0.08, 0.05), CF(cx, -0.20, 0.79), INK)
		end,
	}

	S.er_t_angler = {
		label = "Cavern Angler",
		set = "eternal_roots",
		tint = C3(30, 50, 110),
		head = CF(0, 1.00, -0.30),
		neck = CF(0, -0.60, 1.00),
		back = CF(0, 0.20, -0.96),
		build = function(c, p)
			-- From the black lake under the roots: a round anglerfish with a grin of
			-- soft little teeth and a glowing lure to find its way.
			c:box(V3(1.60, 1.50, 1.60), CF(0, 0, 0), p.base)
			c:box(V3(1.66, 0.40, 0.60), CF(0, -0.56, 0.62), p.dark)
			for _, x in ipairs({ -0.50, -0.18, 0.18, 0.50 }) do
				c:cone(V3(0.14, 0.18, 0.10), CF(x, -0.28, 0.86), WHITE)
			end
			c:eyes(0.30, 0.82, 0.36, 0.17)
			cheeks(c, 0.06, 0.81, 0.60, 0.18)
			c:rod(V3(0, 0.74, 0.30), V3(0, 1.36, 0.60), 0.05, p.dark, nil, false)
			c:rod(V3(0, 1.36, 0.60), V3(0, 1.20, 1.10), 0.04, p.dark, nil, false)
			c:ball(V3(0.34, 0.34, 0.34), CF(0, 1.06, 1.18), p.glow, NEON)
			c:box(V3(0.08, 0.40, 0.70), CF(0, 0.90, -0.30), p.light)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.10, 0.50, 0.50), CF(0.86 * s, -0.20, 0.10) * ANG(0.30, 0, 0), p.light)
				c:box(V3(0.10, 0.60, 0.40), CF(0, 0.26 * s, -0.96) * ANG(-0.50 * s, 0, 0), p.light)
				c:box(V3(0.04, 0.20, 0.20), CF(0.81 * s, 0.30, -0.36), p.light)
			end
			c:box(V3(0.24, 0.06, 0.24), CF(0.40, 0.76, -0.20), p.light)
			c:box(V3(0.24, 0.06, 0.24), CF(-0.30, 0.76, 0.30), p.light)
			c:light(p.glow, 1, 7)
		end,
	}

	S.er_t_tardigrade = {
		label = "Moss Piglet",
		set = "eternal_roots",
		tint = C3(190, 230, 140),
		head = CF(0, 0.96, 0.20),
		neck = CF(0, -0.40, 1.04),
		back = CF(0, 0.20, -1.04),
		build = function(c, p)
			-- A water bear from the moss on the oldest roots: chubby, segmented,
			-- eight stubby legs, and nearly impossible to squash.
			for i, sg in ipairs({ { 1.70, 1.40, 0.62, 0.62 }, { 1.84, 1.54, 0.66, 0.02 }, { 1.70, 1.40, 0.62, -0.58 } }) do
				c:box(V3(sg[1], sg[2], sg[3]), CF(0, 0.06, sg[4]), (i == 2) and p.light or p.base)
			end
			c:box(V3(1.20, 1.00, 0.30), CF(0, 0.00, -0.98), p.base)
			c:cyl(V3(0.24, 0.44, 0.44), CF(0, -0.18, 1.04) * ANG(0, PI / 2, 0), p.pale)
			c:cyl(V3(0.25, 0.20, 0.20), CF(0, -0.18, 1.04) * ANG(0, PI / 2, 0), INK)
			c:eyes(0.30, 0.94, 0.36, 0.14)
			cheeks(c, 0.08, 0.94, 0.60, 0.18)
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.56, 0.06, -0.48 }) do
					c:box(V3(0.36, 0.40, 0.36), CF(0.70 * s, -0.80, z), p.base)
				end
				c:box(V3(0.34, 0.36, 0.30), CF(0.40 * s, -0.60, -1.06), p.base)
			end
			c:box(V3(0.40, 0.14, 0.40), CF(0.30, 0.84, 0.30), LEAF)
			c:box(V3(0.40, 0.14, 0.40), CF(-0.34, 0.90, -0.10), LEAF_DARK)
			c:box(V3(0.40, 0.14, 0.40), CF(0.20, 0.84, -0.56), LEAF)
			c:box(V3(0.14, 0.10, 0.14), CF(-0.34, 1.00, -0.10), BLUSH)
		end,
	}

	S.er_t_sailback = {
		label = "Leafsail Lizard",
		set = "eternal_roots",
		tint = C3(240, 90, 30),
		scale = 1.2,
		head = CF(0, 0.70, 0.76),
		neck = CF(0, -0.30, 1.06),
		back = CF(0, 0.30, -1.10),
		build = function(c, p)
			-- An ancient sail-backed lizard whose sail is one great veined leaf.
			block(c, p, {
				bodySize = V3(1.60, 1.00, 2.00),
				eyeY = 0.12, eyeSpread = 0.40, eyeSize = V3(0.34, 0.40, 0.18),
				mouthY = -0.20, mouthSize = V3(0.60, 0.08, 0.10),
				legSize = V3(0.40, 0.30, 0.40), legX = 0.88, legY = -0.54, legZ = { 0.56, -0.56 },
				tail = false,
			})
			c:box(V3(0.56, 0.46, 0.60), CF(0, -0.10, -1.26), p.base)
			c:box(V3(0.36, 0.32, 0.50), CF(0, -0.18, -1.76), p.base)
			c:box(V3(0.08, 1.00, 1.70), CF(0, 1.06, -0.10), p.light)
			c:box(V3(0.08, 0.30, 1.20), CF(0, 1.70, -0.10), p.light)
			c:box(V3(0.08, 0.20, 0.60), CF(0, 1.94, -0.10), p.light)
			c:rod(V3(0, 0.56, 0.50), V3(0, 1.98, -0.20), 0.05, p.deep, nil, false)
			for _, v in ipairs({
				{ 1.00, 0.33, 1.36, 0.72 },
				{ 1.00, 0.33, 1.10, -0.90 },
				{ 1.27, 0.15, 1.54, -0.86 },
				{ 1.45, 0.06, 1.74, 0.56 },
			}) do
				c:rod(V3(0, v[1], v[2]), V3(0, v[3], v[4]), 0.045, p.deep, nil, false)
			end
			for _, s in ipairs(SIDES) do
				c:box(V3(0.04, 0.24, 0.40), CF(0.81 * s, 0.10, -0.30), p.dark)
			end
		end,
	}

	S.er_t_mantis = {
		label = "Orchid Mantis",
		set = "eternal_roots",
		tint = C3(250, 170, 220),
		scale = 1.1,
		head = CF(0, 1.30, 0.20),
		neck = CF(0, -0.30, 1.00),
		back = CF(0, 0.30, -1.30),
		build = function(c, p)
			-- A mantis that looks just like an orchid: petal lobes on its legs, a
			-- flower-shaped abdomen, praying forelegs folded under a big-eyed face.
			c:box(V3(1.40, 1.20, 1.10), CF(0, 0.40, 0.30), p.base)
			c:box(V3(1.10, 0.80, 1.30), CF(0, -0.10, -0.80) * ANG(0.25, 0, 0), p.light)
			c:box(V3(0.50, 0.40, 0.30), CF(0, 0.30, -1.44), p.pale)
			c:cone(V3(0.40, 0.40, 0.30), CF(0, 1.20, 0.40), p.light)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.40, 0.08, 0.90), CF(0.66 * s, 0.00, -0.80) * ANG(0, 0, 0.40 * s), p.pale)
				c:eye(V3(0.46 * s, 0.80, 0.86), 0.19)
				c:rod(V3(0.20 * s, 1.00, 0.60), V3(0.50 * s, 1.50, 0.90), 0.03, p.dark, nil, false)
				c:rod(V3(0.40 * s, 0.00, 0.70), V3(0.46 * s, 0.30, 1.16), 0.08, p.light, nil, false)
				c:rod(V3(0.46 * s, 0.30, 1.16), V3(0.36 * s, -0.30, 1.12), 0.07, p.light, nil, false)
				for _, z in ipairs({ 0.00, -0.60 }) do
					c:rod(V3(0.50 * s, -0.10, z), V3(0.90 * s, -0.96, z + 0.10), 0.05, p.dark, nil, false)
					c:box(V3(0.26, 0.06, 0.36), CF(0.74 * s, -0.56, z + 0.05), p.pale)
				end
			end
			c:box(V3(0.20, 0.08, 0.05), CF(0, 0.26, 0.86), INK)
			cheeks(c, 0.44, 0.86, 0.50, 0.16)
		end,
	}

	----------------------------------------------------------------------------
	-- MYTHIC: spectacular, with glowing accents.
	----------------------------------------------------------------------------

	S.er_t_treant = {
		label = "Elder Treant",
		set = "eternal_roots",
		tint = C3(150, 100, 60),
		scale = 1.2,
		head = CF(0, 1.90, 0),
		neck = CF(0, -0.40, 0.66),
		back = CF(0, 0.20, -0.66),
		build = function(c, p)
			-- The oldest walking tree of the root lands: a face in its trunk, a mossy
			-- beard, branch arms, root feet and fireflies living in its crown.
			c:box(V3(1.40, 1.70, 1.20), CF(0, -0.10, 0), p.base)
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.26, -0.30 }) do
					c:box(V3(0.10, 1.50, 0.24), CF(0.72 * s, -0.10, z), p.dark)
				end
				c:box(V3(0.04, 0.40, 0.14), CF(0.76 * s, -0.30, -0.02), p.glow, NEON)
				c:rod(V3(0.66 * s, 0.20, 0), V3(1.16 * s, 0.70, 0.10), 0.12, p.dark, nil, false)
				c:box(V3(0.36, 0.30, 0.36), CF(1.20 * s, 0.74, 0.10), p.pale)
				c:box(V3(0.60, 0.40, 0.40), CF(0.80 * s, 0.70, 0.62), p.pale)
				for _, t in ipairs(SIDES) do
					c:box(V3(0.46, 0.22, 0.40), CF(0.56 * s, -1.02, 0.40 * t) * ANG(0, 0.50 * s * t, 0), p.dark)
				end
			end
			c:box(V3(0.24, 1.50, 0.10), CF(0, -0.10, -0.62), p.dark)
			c:box(V3(2.10, 0.80, 1.80), CF(0, 1.10, -0.06), p.light)
			c:box(V3(1.40, 0.50, 1.20), CF(0, 1.62, -0.06), p.light)
			c:eyes(0.24, 0.62, 0.30, 0.16)
			c:box(V3(1.00, 0.12, 0.08), CF(0, 0.50, 0.62), p.dark)
			c:box(V3(0.20, 0.20, 0.12), CF(0, 0.04, 0.66), p.dark)
			c:box(V3(0.30, 0.08, 0.05), CF(0, -0.12, 0.61), INK)
			c:box(V3(0.80, 0.50, 0.10), CF(0, -0.44, 0.64), LEAF)
			c:box(V3(0.40, 0.24, 0.10), CF(0, -0.76, 0.64), LEAF_DARK)
			for _, f in ipairs({ { 0.90, 1.70, 0.40 }, { -1.00, 1.30, -0.50 }, { 0.20, 2.06, -0.30 } }) do
				c:ball(V3(0.16, 0.16, 0.16), CF(f[1], f[2], f[3]), p.glow, NEON)
			end
			c:box(V3(0.20, 0.08, 0.20), CF(0.50, 1.88, 0.20), BLUSH)
			c:box(V3(0.20, 0.08, 0.20), CF(-0.86, 1.52, 0.30), BLUSH)
			c:light(p.glow, 0.8, 6)
		end,
	}

	S.er_t_octopus = {
		label = "Rootcoil Octopus",
		set = "eternal_roots",
		tint = C3(200, 60, 140),
		scale = 1.1,
		head = CF(0, 1.56, -0.20),
		neck = CF(0, -0.30, 0.80),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			-- It lives where the world-roots drink from the buried sea: eight arms
			-- that curl like roots, glowing tips, and a crown of sap pearls.
			c:box(V3(1.60, 1.40, 1.50), CF(0, 0.30, 0), p.base)
			c:box(V3(1.24, 0.40, 1.20), CF(0, 1.16, -0.10), p.base)
			c:box(V3(1.30, 0.12, 1.26), CF(0, 1.38, -0.10), p.deep)
			for _, x in ipairs({ -0.30, 0, 0.30 }) do
				c:ball(V3(0.22, 0.22, 0.22), CF(x, 1.52, (x == 0) and 0.10 or 0), p.glow, NEON)
			end
			c:eyes(0.34, 0.76, 0.36, 0.18)
			c:box(V3(0.20, 0.10, 0.05), CF(0, 0.00, 0.76), INK)
			cheeks(c, 0.12, 0.76, 0.60, 0.18)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.04, 0.24, 0.24), CF(0.81 * s, 0.50, -0.30), p.light)
			end
			for i = 0, 7 do
				local a = (i + 0.5) * PI / 4
				local x, z = math.sin(a), math.cos(a)
				local mid = V3(1.10 * x, -0.86, 1.00 * z)
				local tip = V3(1.30 * x, -0.56, 1.20 * z)
				c:rod(V3(0.60 * x, -0.30, 0.56 * z), mid, 0.10, p.base, nil, false)
				c:rod(mid, tip, 0.08, p.light, nil, false)
				if i % 2 == 0 then
					c:ball(V3(0.20, 0.20, 0.20), CF(tip), p.glow, NEON)
				end
			end
			c:light(p.glow, 1, 7)
		end,
	}

	S.er_t_drake = {
		label = "Grove Drake",
		set = "eternal_roots",
		tint = C3(40, 180, 90),
		scale = 1.25,
		head = CF(0, 1.16, 0.30),
		neck = CF(0, -0.30, 1.00),
		back = CF(0, 0.60, -0.50),
		build = function(c, p)
			-- A forest dragon hatched among the world-roots: branch horns, leaf wings,
			-- a glowing sap gem on its chest and a leaf for a tail tip.
			block(c, p, {
				bodySize = V3(1.70, 1.50, 1.80),
				eyeY = 0.24, eyeSpread = 0.40, eyeSize = V3(0.38, 0.46, 0.18),
				snout = { w = 0.70, h = 0.40, d = 0.34, y = -0.18, color = p.light, nose = p.deep },
				bib = { w = 0.80, h = 0.50, y = -0.46, color = p.pale },
				legSize = V3(0.42, 0.36, 0.46), legX = 0.54, legY = -0.82, legZ = { 0.50, -0.50 },
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:rod(V3(0.40 * s, 0.80, 0.30), V3(0.56 * s, 1.30, -0.10), 0.07, p.deep, nil, false)
				c:rod(V3(0.50 * s, 1.10, 0.06), V3(0.80 * s, 1.30, 0.20), 0.05, p.deep, nil, false)
				c:box(V3(0.20, 0.06, 0.14), CF(0.84 * s, 1.34, 0.22), LEAF)
				c:rod(V3(0.60 * s, 0.78, -0.20), V3(1.50 * s, 1.50, -0.40), 0.06, p.dark, nil, false)
				c:box(V3(1.00, 0.06, 0.70), CF(1.05 * s, 1.10, -0.56) * ANG(0, 0, 0.67 * s), p.light)
				c:box(V3(0.70, 0.06, 0.50), CF(1.24 * s, 0.86, -0.76) * ANG(0, 0, 0.35 * s), p.pale)
			end
			c:box(V3(0.56, 0.50, 0.40), CF(0, -0.30, -1.10), p.base)
			c:box(V3(0.36, 0.34, 0.36), CF(0, -0.40, -1.44), p.base)
			c:box(V3(0.50, 0.08, 0.40), CF(0, -0.40, -1.72) * ANG(0, PI / 4, 0), LEAF)
			for _, z in ipairs({ 0.50, 0.10, -0.30, -0.70 }) do
				c:cone(V3(0.20, 0.24, 0.20), CF(0, 0.92, z), p.glow, NEON)
			end
			c:box(V3(0.26, 0.26, 0.06), CF(0, -0.40, 0.93) * ANG(0, 0, PI / 4), p.glow, NEON)
			c:box(V3(0.20, 0.04, 0.14), CF(1.00, 0.20, 0.70) * ANG(0.30, 0.40, 0), LEAF)
			c:box(V3(0.20, 0.04, 0.14), CF(-0.90, 1.70, 0.30) * ANG(-0.30, 0.20, 0), LEAF)
			c:light(p.glow, 0.8, 6)
		end,
	}

	S.er_t_hourglass = {
		label = "Sap Hourglass",
		set = "eternal_roots",
		tint = C3(255, 190, 60),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.60, 0.80),
		back = CF(0, 0.00, -0.80),
		build = function(c, p)
			-- Ancient time itself, kept in a root-framed hourglass of glowing sap.
			-- Its face is on the lower bulb, where the sap gathers.
			c:box(V3(1.80, 0.24, 1.80), CF(0, 1.06, 0), p.dark)
			c:box(V3(1.80, 0.24, 1.80), CF(0, -0.96, 0), p.dark)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:rod(V3(0.76 * s, -0.84, 0.76 * t), V3(0.76 * s, 0.94, 0.76 * t), 0.09, p.deep, nil, false)
					c:box(V3(0.18, 0.18, 0.18), CF(0.80 * s, 1.20, 0.80 * t) * ANG(0, PI / 4, 0), p.glow, NEON)
				end
			end
			local top = c:box(V3(1.10, 0.76, 1.10), CF(0, 0.52, 0), p.pale, GLASS)
			top.Transparency = 0.4
			local bottom = c:box(V3(1.24, 0.80, 1.24), CF(0, -0.44, 0), p.pale, GLASS)
			bottom.Transparency = 0.4
			c:box(V3(0.36, 0.20, 0.36), CF(0, 0.06, 0), p.pale, GLASS)
			c:box(V3(0.96, 0.30, 0.96), CF(0, 0.38, 0), p.base)
			c:rod(V3(0, 0.22, 0), V3(0, -0.40, 0), 0.05, p.glow, NEON, false)
			c:box(V3(1.14, 0.40, 1.14), CF(0, -0.62, 0), p.base)
			c:cone(V3(0.70, 0.30, 0.70), CF(0, -0.27, 0), p.base)
			c:eyes(-0.30, 0.64, 0.28, 0.14)
			c:box(V3(0.22, 0.08, 0.05), CF(0, -0.62, 0.63), INK)
			cheeks(c, -0.50, 0.63, 0.44, 0.16)
			c:rod(V3(0, 1.18, 0), V3(0, 1.50, 0), 0.05, LEAF_DARK, nil, false)
			c:box(V3(0.36, 0.06, 0.20), CF(0.18, 1.50, 0) * ANG(0, 0, 0.40), LEAF)
			c:box(V3(0.36, 0.06, 0.20), CF(-0.18, 1.50, 0) * ANG(0, 0, -0.40), LEAF)
			c:ball(V3(0.16, 0.16, 0.16), CF(1.14, 0.50, 0.30), p.glow, NEON)
			c:ball(V3(0.12, 0.12, 0.12), CF(-1.12, 0.10, -0.30), p.glow, NEON)
			c:light(p.glow, 1, 7)
		end,
	}

	S.er_t_longneck = {
		label = "Treetop Longneck",
		set = "eternal_roots",
		tint = C3(110, 200, 180),
		scale = 1.25,
		head = CF(0, 1.56, 0.60),
		neck = CF(0, 0.30, 1.06),
		back = CF(0, 0.40, -0.70),
		build = function(c, p)
			-- A baby sauropod from the first forests, tall enough to nibble the
			-- world-tree's lowest leaves. Its face is at the top of its neck.
			c:box(V3(1.60, 1.20, 1.80), CF(0, -0.30, -0.30), p.base)
			c:box(V3(0.90, 1.50, 0.86), CF(0, 0.60, 0.60), p.base)
			c:box(V3(0.50, 1.00, 0.06), CF(0, 0.20, 1.04), p.pale)
			c:eyes(1.12, 1.04, 0.24, 0.14)
			c:box(V3(0.30, 0.06, 0.05), CF(0, 0.88, 1.04), INK)
			cheeks(c, 0.96, 1.04, 0.36, 0.14)
			for _, s in ipairs(SIDES) do
				for _, z in ipairs({ 0.30, -0.90 }) do
					c:box(V3(0.46, 0.30, 0.46), CF(0.50 * s, -1.05, z), p.dark)
				end
			end
			c:box(V3(0.50, 0.40, 0.60), CF(0, -0.36, -1.44), p.base)
			c:box(V3(0.30, 0.26, 0.50), CF(0, -0.44, -1.90), p.base)
			for _, z in ipairs({ -0.10, -0.50, -0.90 }) do
				c:box(V3(0.24, 0.06, 0.24), CF(0, 0.31, z), p.glow, NEON)
			end
			for _, y in ipairs({ 0.50, 0.90 }) do
				c:box(V3(0.24, 0.24, 0.06), CF(0, y, 0.16), p.glow, NEON)
			end
			c:rod(V3(-0.60, 0.84, 1.10), V3(0.60, 0.84, 1.10), 0.04, BARK, nil, false)
			c:box(V3(0.30, 0.20, 0.20), CF(-0.66, 0.88, 1.10), LEAF)
			c:box(V3(0.30, 0.20, 0.20), CF(0.66, 0.82, 1.10), LEAF)
			c:box(V3(0.70, 0.16, 0.60), CF(0, 1.42, 0.60), LEAF)
			c:box(V3(0.24, 0.20, 0.24), CF(0.20, 1.56, 0.50), LEAF_DARK)
			c:ball(V3(0.16, 0.16, 0.16), CF(0.90, 1.30, 0.40), p.glow, NEON)
			c:ball(V3(0.14, 0.14, 0.14), CF(-0.86, 0.80, 1.00), p.glow, NEON)
		end,
	}

	S.er_t_kitsune = {
		label = "Foxfire Kitsune",
		set = "eternal_roots",
		tint = C3(250, 240, 230),
		scale = 1.25,
		head = CF(0, 1.06, 0.20),
		neck = CF(0, -0.30, 0.90),
		back = CF(0, 0.40, -0.70),
		build = function(c, p)
			-- A cavern fox lit by foxfire, the glowing fungus of old roots: three
			-- tails fanned high, each tipped with cold flame.
			block(c, p, {
				bodySize = V3(1.60, 1.50, 1.70),
				eyeY = 0.20, eyeSpread = 0.38, eyeSize = V3(0.36, 0.44, 0.18),
				snout = { w = 0.56, h = 0.34, d = 0.36, y = -0.16, color = p.pale, nose = INK },
				bib = { w = 0.80, h = 0.50, y = -0.44, color = p.pale },
				legSize = V3(0.34, 0.40, 0.36), legX = 0.48, legY = -0.82, legZ = { 0.46, -0.46 }, legColor = p.dark,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.44, 0.60, 0.30), CF(0.46 * s, 1.10, 0.20), p.base)
				c:cone(V3(0.24, 0.40, 0.10), CF(0.46 * s, 1.04, 0.36), p.glow, NEON)
			end
			for _, a in ipairs({ -0.55, 0, 0.55 }) do
				local root = CF(0, 0.30, -0.80) * ANG(0, 0, a) * ANG(-0.70, 0, 0)
				c:box(V3(0.46, 1.20, 0.46), root * CF(0, 0.60, 0), p.base)
				c:box(V3(0.52, 0.44, 0.52), root * CF(0, 1.36, 0), p.glow, NEON)
			end
			c:box(V3(0.20, 0.30, 0.04), CF(0, 0.60, 0.86), p.glow, NEON)
			c:box(V3(0.10, 0.16, 0.10), CF(-0.20, 0.89, 0.30), p.pale)
			c:box(V3(0.30, 0.10, 0.30), CF(-0.20, 1.00, 0.30), p.glow, NEON)
			for _, f in ipairs({ { 1.00, 0.90, 0.40 }, { -1.06, 0.50, -0.30 }, { 0.70, 1.60, -0.40 } }) do
				c:ball(V3(0.24, 0.24, 0.24), CF(f[1], f[2], f[3]), p.glow, NEON)
			end
			c:light(p.glow, 1, 7)
		end,
	}

	S.er_t_ankylo = {
		label = "Mossclub Ankylo",
		set = "eternal_roots",
		tint = C3(60, 100, 76),
		scale = 1.25,
		head = CF(0, 1.00, 0.50),
		neck = CF(0, -0.30, 1.10),
		back = CF(0, 0.70, -0.60),
		build = function(c, p)
			-- An armoured giant of the first age: domed back plates studded with
			-- glowing gems, spikes down both flanks and a mossy club tail.
			block(c, p, {
				bodySize = V3(2.00, 1.20, 2.00),
				eyeY = 0.04, eyeSpread = 0.46, eyeSize = V3(0.34, 0.40, 0.18),
				brow = p.dark,
				snout = { w = 0.80, h = 0.36, d = 0.24, y = -0.28, color = p.pale, nose = p.deep },
				legSize = V3(0.50, 0.30, 0.50), legX = 0.66, legY = -0.70, legZ = { 0.56, -0.56 }, legColor = p.dark,
				tail = false,
			})
			for _, z in ipairs({ 0.50, 0.00, -0.50 }) do
				c:box(V3(1.30, 0.24, 0.42), CF(0, 0.78, z), p.dark)
				c:box(V3(0.20, 0.14, 0.20), CF(0, 0.96, z) * ANG(0, PI / 4, 0), p.glow, NEON)
				for _, s in ipairs(SIDES) do
					c:cone(V3(0.24, 0.40, 0.24), CF(1.14 * s, 0.30, z) * ANG(0, 0, -PI / 2 * s), p.pale)
				end
			end
			c:box(V3(0.50, 0.40, 0.50), CF(0, -0.10, -1.20), p.base)
			c:box(V3(0.80, 0.50, 0.50), CF(0, -0.10, -1.66), p.dark)
			c:box(V3(0.60, 0.10, 0.40), CF(0, 0.20, -1.66), LEAF)
			c:box(V3(0.14, 0.14, 0.14), CF(0.30, 0.10, -1.92) * ANG(0, PI / 4, 0), p.glow, NEON)
			cheeks(c, -0.10, 1.01, 0.70, 0.20)
			c:light(p.glow, 0.8, 6)
		end,
	}

	S.er_t_moth = {
		label = "Lunar Moth",
		set = "eternal_roots",
		tint = C3(180, 250, 200),
		scale = 1.3,
		head = CF(0, 1.00, 0.10),
		neck = CF(0, -0.40, 0.66),
		back = CF(0, 0.30, -0.66),
		build = function(c, p)
			-- A great moth of the moonlit root canopy: crescent moons glowing on each
			-- wing, long ribbon tails and feathery antennae.
			c:box(V3(1.20, 1.30, 1.20), CF(0, 0.10, 0), p.pale)
			c:box(V3(1.36, 0.36, 1.36), CF(0, 0.66, 0), p.light)
			c:box(V3(0.70, 0.60, 0.40), CF(0, -0.20, -0.76), p.light)
			for _, s in ipairs(SIDES) do
				local fore = CF(1.00 * s, 0.60, -0.30) * ANG(0, 0.25 * s, 0.35 * s)
				c:box(V3(1.10, 0.96, 0.08), fore, p.base)
				c:box(V3(1.14, 0.08, 0.10), fore * CF(0, 0.48, 0), p.dark)
				c:box(V3(0.30, 0.30, 0.04), fore * CF(0.12 * s, 0.02, 0.05), p.glow, NEON)
				local hind = CF(0.86 * s, -0.24, -0.36) * ANG(0, 0.25 * s, -0.25 * s)
				c:box(V3(0.86, 0.80, 0.08), hind, p.base)
				c:box(V3(0.20, 0.20, 0.04), hind * CF(0.10 * s, 0, 0.05), p.glow, NEON)
				c:box(V3(0.20, 0.80, 0.06), CF(1.06 * s, -0.86, -0.46) * ANG(0, 0, -0.30 * s), p.light)
				c:rod(V3(0.20 * s, 0.84, 0.40), V3(0.50 * s, 1.40, 0.60), 0.035, p.dark, nil, false)
				c:box(V3(0.06, 0.40, 0.20), CF(0.40 * s, 1.20, 0.54) * ANG(0, 0, -0.50 * s), p.light)
				c:box(V3(0.16, 0.30, 0.16), CF(0.30 * s, -0.66, 0.20), p.dark)
			end
			c:eyes(0.20, 0.62, 0.30, 0.16)
			c:box(V3(0.22, 0.08, 0.05), CF(0, -0.10, 0.61), INK)
			cheeks(c, 0.02, 0.61, 0.48, 0.16)
			c:ball(V3(0.14, 0.14, 0.14), CF(1.30, 1.30, 0.40), p.glow, NEON)
			c:ball(V3(0.12, 0.12, 0.12), CF(-1.20, -0.60, 0.50), p.glow, NEON)
			c:light(p.glow, 1, 7)
		end,
	}

	----------------------------------------------------------------------------
	-- DIVINE
	----------------------------------------------------------------------------

	S.er_t_willow = {
		label = "Willow Wisp",
		set = "eternal_roots",
		tint = C3(170, 230, 110),
		scale = 1.1,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.40, 0.76),
		back = CF(0, 0.20, -0.76),
		build = function(c, p)
			-- The spirit of a weeping willow by the sacred spring: a floating puff
			-- with long fronds trailing round it and a ring of blossoms for a halo.
			c:box(V3(1.50, 1.40, 1.40), CF(0, 0.20, 0), p.base)
			c:box(V3(1.70, 0.30, 1.60), CF(0, 0.92, 0), p.light)
			c:cone(V3(0.80, 0.60, 0.80), CF(0, -0.80, 0) * ANG(PI, 0, 0), p.pale)
			for _, f in ipairs({ { -0.80, 0.50 }, { 0.80, 0.50 }, { -0.86, 0 }, { 0.86, 0 }, { -0.80, -0.50 }, { 0.80, -0.50 }, { -0.30, -0.80 }, { 0.30, -0.80 } }) do
				local tip = V3(f[1] * 1.15, -0.76, f[2] * 1.15)
				c:rod(V3(f[1], 0.80, f[2]), tip, 0.05, p.light, nil, false)
				c:box(V3(0.14, 0.30, 0.14), CF(tip), p.pale)
			end
			for i = 0, 5 do
				local a = i * PI / 3
				c:box(V3(0.22, 0.10, 0.22), CF(0.62 * math.cos(a), 1.40, 0.62 * math.sin(a)) * ANG(0, a, 0), p.glow, NEON)
			end
			c:eyes(0.30, 0.71, 0.30, 0.15)
			c:box(V3(0.22, 0.08, 0.05), CF(0, -0.02, 0.71), INK)
			cheeks(c, 0.12, 0.71, 0.48, 0.16)
			c:light(p.glow, 1, 7)
		end,
	}

	S.er_t_lotus = {
		label = "Lotus Seraph",
		set = "eternal_roots",
		tint = C3(255, 180, 210),
		scale = 1.2,
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.30, 0.66),
		back = CF(0, 0.20, -0.66),
		build = function(c, p)
			-- A lotus that opened on the first spring: a seed-pod face in a cup of
			-- petals, two small feathered wings, floating on a ripple of light.
			local ripple = c:cyl(V3(0.06, 2.40, 2.40), CF(0, -0.92, 0) * ANG(0, 0, PI / 2), WATER, GLASS)
			ripple.Transparency = 0.35
			c:cyl(V3(0.10, 2.00, 2.00), CF(0, -0.84, 0) * ANG(0, 0, PI / 2), LEAF)
			for i = 0, 7 do
				local a = i * PI / 4 + PI / 8
				c:box(V3(0.50, 0.90, 0.14), CF(0, -0.40, 0) * ANG(0, a, 0) * CF(0, 0, 0.78) * ANG(0.55, 0, 0), p.light)
			end
			for i = 0, 3 do
				local a = i * PI / 2 + PI / 4
				c:box(V3(0.50, 0.90, 0.12), CF(0, -0.10, 0) * ANG(0, a, 0) * CF(0, 0, 0.56) * ANG(0.30, 0, 0), p.pale)
			end
			c:box(V3(1.00, 0.90, 1.00), CF(0, 0.10, 0), p.base)
			c:box(V3(1.04, 0.06, 1.04), CF(0, 0.57, 0), p.light)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(V3(0.14, 0.04, 0.14), CF(0.24 * s, 0.60, 0.24 * t), p.glow, NEON)
				end
				for k = 0, 2 do
					c:box(V3(0.14, 0.60 - k * 0.10, 0.30), CF(0.54 * s, 0.36, -0.30) * ANG(0, 0, -(0.50 + k * 0.40) * s) * CF(0, 0.32, 0), p.pale)
				end
			end
			c:eyes(0.20, 0.52, 0.24, 0.13)
			c:box(V3(0.20, 0.06, 0.05), CF(0, -0.06, 0.51), INK)
			cheeks(c, 0.04, 0.51, 0.38, 0.14)
			for i = 0, 3 do
				c:box(V3(0.56, 0.06, 0.08), CF(0, 1.00, 0) * ANG(0, i * PI / 2 + PI / 4, 0) * CF(0, 0, 0.36), GOLD, NEON)
			end
			c:light(p.glow, 1, 7)
		end,
	}

	S.er_t_qilin = {
		label = "Bloom Qilin",
		set = "eternal_roots",
		tint = C3(60, 200, 230),
		scale = 1.15,
		head = CF(0, 1.10, 0.30),
		neck = CF(0, -0.30, 1.00),
		back = CF(0, 0.60, -0.70),
		build = function(c, p)
			-- A sacred beast that walks on clouds: one twisting root horn tipped with
			-- light, a cloud mane, and a blossom on the end of its tail.
			block(c, p, {
				bodySize = V3(1.60, 1.50, 1.90),
				eyeY = 0.24, eyeSpread = 0.38, eyeSize = V3(0.36, 0.44, 0.18),
				snout = { w = 0.66, h = 0.38, d = 0.30, y = -0.18, color = p.pale, nose = p.deep },
				legSize = V3(0.32, 0.40, 0.34), legX = 0.52, legY = -0.82, legZ = { 0.56, -0.56 },
				tail = false,
			})
			c:box(V3(0.26, 0.26, 0.26), CF(0, 0.94, 0.50) * ANG(0, 0.40, 0), p.deep)
			c:box(V3(0.20, 0.26, 0.20), CF(0, 1.16, 0.56) * ANG(0, 1.00, 0), p.deep)
			c:box(V3(0.14, 0.24, 0.14), CF(0, 1.36, 0.62) * ANG(0, 1.60, 0), p.deep)
			c:ball(V3(0.16, 0.16, 0.16), CF(0, 1.52, 0.66), p.glow, NEON)
			for _, m in ipairs({ { 0, 0.86, 0.06, 0.44 }, { 0.40, 0.80, 0.24, 0.36 }, { -0.40, 0.80, 0.24, 0.36 }, { 0, 0.84, -0.36, 0.40 }, { 0, 0.80, -0.74, 0.34 } }) do
				c:ball(V3(m[4], m[4], m[4]), CF(m[1], m[2], m[3]), p.pale)
			end
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:ball(V3(0.42, 0.42, 0.42), CF(0.52 * s, -1.04, 0.56 * t), WHITE)
				end
				for _, z in ipairs({ 0.20, -0.30 }) do
					c:box(V3(0.04, 0.24, 0.24), CF(0.81 * s, 0.10, z), p.light)
				end
			end
			c:rod(V3(0, 0.30, -0.95), V3(0, 0.80, -1.40), 0.08, p.base, nil, false)
			c:ball(V3(0.40, 0.40, 0.40), CF(0, 0.90, -1.48), BLUSH)
			c:box(V3(0.14, 0.14, 0.14), CF(0, 0.90, -1.30), GOLD, NEON)
			c:box(V3(0.30, 0.28, 0.12), CF(0, -0.50, 1.06), p.pale)
			c:box(V3(0.16, 0.04, 0.16), CF(0.90, 1.20, 0.50) * ANG(0.40, 0.30, 0), BLUSH)
			c:box(V3(0.16, 0.04, 0.16), CF(-1.00, 0.40, -0.60) * ANG(-0.30, 0.50, 0), BLUSH)
			c:light(p.glow, 1, 7)
		end,
	}

	S.er_t_monkey = {
		label = "Banyan Monkey",
		set = "eternal_roots",
		tint = C3(220, 150, 80),
		scale = 1.15,
		head = CF(0, 1.16, 0.06),
		neck = CF(0, -0.20, 0.80),
		back = CF(0, 0.30, -0.80),
		build = function(c, p)
			-- A wise little monkey sitting cross-legged on a banyan root, hands
			-- together, a ring of glowing leaves behind it and its tail in a curl.
			c:rod(V3(-1.20, -0.86, 0), V3(1.20, -0.86, 0), 0.14, BARK, WOOD, false)
			c:box(V3(1.60, 1.40, 1.40), CF(0, 0.30, 0), p.base)
			c:box(V3(1.80, 0.40, 1.00), CF(0, -0.60, 0.20), p.dark)
			c:box(V3(1.20, 0.80, 0.06), CF(0, 0.34, 0.71), p.pale)
			c:box(V3(0.40, 0.20, 0.40), CF(0, 1.10, 0), p.dark)
			c:eyes(0.44, 0.75, 0.26, 0.14)
			c:box(V3(0.20, 0.10, 0.04), CF(0, 0.24, 0.75), p.deep)
			c:box(V3(0.30, 0.06, 0.04), CF(0, 0.08, 0.75), INK)
			cheeks(c, 0.20, 0.75, 0.44, 0.14)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.14, 0.40, 0.40), CF(0.86 * s, 0.46, 0.10), p.pale)
				c:box(V3(0.36, 0.20, 0.20), CF(0.50 * s, -0.56, 0.72), p.pale)
				c:rod(V3(0.70 * s, 0.40, 0.30), V3(0.20 * s, -0.10, 0.80), 0.12, p.base, nil, false)
				c:box(V3(0.20, 0.36, 0.20), CF(0.10 * s, -0.10, 0.82), p.pale)
			end
			c:rod(V3(0, -0.30, -0.70), V3(0, -0.20, -1.20), 0.08, p.dark, nil, false)
			c:rod(V3(0, -0.20, -1.20), V3(0, 0.30, -1.30), 0.08, p.dark, nil, false)
			c:rod(V3(0, 0.30, -1.30), V3(0, 0.40, -1.00), 0.08, p.dark, nil, false)
			for i = 0, 7 do
				c:box(V3(0.34, 0.20, 0.06), CF(0, 0.50, -0.86) * ANG(0, 0, i * PI / 4) * CF(0, 1.10, 0), p.glow, NEON)
			end
			c:light(p.glow, 1, 7)
		end,
	}

	S.er_t_phoenix = {
		label = "Sapfire Phoenix",
		set = "eternal_roots",
		tint = C3(255, 90, 40),
		scale = 1.3,
		head = CF(0, 1.10, 0.20),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.30, -0.70),
		build = function(c, p)
			-- Born from a drop of burning sap at the root of the world: wings up, a
			-- crest of flame leaves and three long glowing tail plumes.
			local _, fz = block(c, p, {
				shape = "bird", bodySize = V3(1.60, 1.60, 1.50),
				eyeY = 0.24, eyeSpread = 0.36, eyeSize = V3(0.36, 0.44, 0.18),
				mouth = false,
				bib = { w = 0.80, h = 0.60, y = -0.40, color = p.light },
				legSize = V3(0.24, 0.30, 0.30), legX = 0.30, legY = -0.86, legZ = { 0.20 }, legColor = GOLD,
				tail = false,
			})
			c:cone(V3(0.22, 0.28, 0.20), CF(0, -0.02, fz + 0.12) * ANG(PI, 0, 0), GOLD)
			cheeks(c, 0.00, fz + 0.01, 0.52, 0.16)
			for k, x in ipairs({ -0.20, 0, 0.20 }) do
				c:box(V3(0.14, 0.50, 0.30), CF(x, 1.06, 0.20 - k * 0.12) * ANG(-0.40, 0, -x * 1.5), p.glow, NEON)
			end
			for _, s in ipairs(SIDES) do
				for k = 0, 2 do
					local cf = CF(0.76 * s, 0.40, -0.10) * ANG(0, 0, -(0.30 + k * 0.40) * s) * CF(0, 0.55 - k * 0.08, 0)
					if k == 2 then
						c:box(V3(0.16, 0.70, 0.50), cf, p.glow, NEON)
					else
						c:box(V3(0.16, 1.10 - k * 0.20, 0.50), cf, (k == 0) and p.base or p.light)
					end
				end
			end
			for _, a in ipairs({ -0.35, 0, 0.35 }) do
				local tip = V3(a * 1.6, -0.30 + math.abs(a) * 0.4, -1.70)
				c:rod(V3(0, -0.20, -0.70), tip, 0.06, p.base, nil, false)
				c:box(V3(0.30, 0.30, 0.08), CF(tip) * ANG(0, 0, PI / 4), p.glow, NEON)
			end
			for _, e in ipairs({ { 0.90, 1.50, 0.30 }, { -1.10, 1.20, -0.40 }, { 0.50, -0.20, -1.40 } }) do
				c:ball(V3(0.14, 0.14, 0.14), CF(e[1], e[2], e[3]), p.glow, NEON)
			end
			c:light(p.glow, 1.2, 8)
		end,
	}

	S.er_t_fountain = {
		label = "Fountain Spirit",
		set = "eternal_roots",
		tint = C3(140, 200, 255),
		scale = 1.15,
		head = CF(0, 1.50, 0),
		neck = CF(0, -0.50, 0.60),
		back = CF(0, 0.00, -0.60),
		build = function(c, p)
			-- The sacred spring where the world-roots drink, given a face: a tiered
			-- fountain whose water arcs down into the basin and never runs dry.
			c:cyl(V3(0.50, 2.40, 2.40), CF(0, -0.84, 0) * ANG(0, 0, PI / 2), p.dark)
			local pool = c:cyl(V3(0.06, 2.10, 2.10), CF(0, -0.58, 0) * ANG(0, 0, PI / 2), WATER, GLASS)
			pool.Transparency = 0.2
			c:box(V3(1.00, 1.10, 1.00), CF(0, -0.10, 0), p.base)
			c:cyl(V3(0.30, 1.70, 1.70), CF(0, 0.58, 0) * ANG(0, 0, PI / 2), p.light)
			c:cyl(V3(0.20, 0.70, 0.70), CF(0, 0.84, 0) * ANG(0, 0, PI / 2), p.base)
			c:ball(V3(0.50, 0.50, 0.50), CF(0, 1.14, 0), p.glow, NEON)
			c:eyes(0.04, 0.52, 0.22, 0.13)
			c:box(V3(0.20, 0.06, 0.05), CF(0, -0.26, 0.51), INK)
			cheeks(c, -0.14, 0.51, 0.36, 0.12)
			for i = 0, 3 do
				local a = PI / 4 + i * PI / 2
				local x, z = math.sin(a), math.cos(a)
				local mid = V3(1.06 * x, 0.20, 1.06 * z)
				local r1 = c:rod(V3(0.80 * x, 0.66, 0.80 * z), mid, 0.07, WATER, GLASS, false)
				local r2 = c:rod(mid, V3(1.00 * x, -0.56, 1.00 * z), 0.07, WATER, GLASS, false)
				r1.Transparency, r2.Transparency = 0.3, 0.3
			end
			for _, d in ipairs({ { 0.30, 0 }, { -0.30, 0 }, { 0, 0.30 }, { 0, -0.30 } }) do
				c:ball(V3(0.12, 0.12, 0.12), CF(d[1], 1.42, d[2]), WATER, GLASS)
			end
			c:rod(V3(1.10, -0.60, -0.40), V3(1.30, -1.10, -0.60), 0.06, BARK, nil, false)
			c:rod(V3(-1.10, -0.60, -0.50), V3(-1.28, -1.10, -0.70), 0.06, BARK, nil, false)
			c:cyl(V3(0.04, 0.34, 0.34), CF(-0.70, -0.54, 0.40) * ANG(0, 0, PI / 2), LEAF)
			c:box(V3(0.12, 0.12, 0.12), CF(-0.70, -0.46, 0.40) * ANG(0, PI / 4, 0), BLUSH)
			c:light(p.glow, 1, 7)
		end,
	}

	----------------------------------------------------------------------------
	-- EXOTIC
	----------------------------------------------------------------------------

	S.er_t_heart = {
		label = "Rootbound Heart",
		set = "eternal_roots",
		tint = C3(230, 40, 90),
		scale = 1.2,
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.70, 0.66),
		back = CF(0, 0.20, -0.66),
		build = function(c, p)
			-- The Eternal Heart at the centre of the world-roots: held in a cradle
			-- of roots, beating light, circled by tiny seed worlds.
			for _, s in ipairs(SIDES) do
				c:box(V3(0.90, 1.30, 1.10), CF(0.34 * s, 0.24, 0) * ANG(0, 0, -0.62 * s), p.base)
				c:rod(V3(0.50 * s, -0.80, 0.30), V3(0.96 * s, 0.10, 0.40), 0.06, BARK, nil, false)
				c:rod(V3(0.96 * s, 0.10, 0.40), V3(0.80 * s, 0.86, 0.20), 0.05, BARK, nil, false)
				c:box(V3(0.30, 0.06, 0.20), CF(0.74 * s, 0.94, 0.16) * ANG(0, 0, 0.30 * s), LEAF)
			end
			c:box(V3(0.90, 0.90, 1.10), CF(0, -0.36, 0) * ANG(0, 0, PI / 4), p.base)
			c:box(V3(0.60, 0.60, 0.06), CF(0, 0.10, -0.57) * ANG(0, 0, PI / 4), p.glow, NEON)
			c:eyes(0.16, 0.57, 0.30, 0.15)
			c:box(V3(0.24, 0.08, 0.05), CF(0, -0.16, 0.57), INK)
			cheeks(c, 0.00, 0.56, 0.52, 0.16)
			for _, r in ipairs({ { 0.70, 0.40 }, { -0.70, 0.40 }, { 0.60, -0.50 }, { -0.60, -0.50 } }) do
				c:rod(V3(0, -0.90, 0), V3(r[1], -1.20, r[2]), 0.07, BARK, nil, false)
			end
			c:box(V3(0.70, 0.12, 0.40), CF(0, 0.86, 0), GOLD, METAL)
			for _, x in ipairs({ -0.24, 0, 0.24 }) do
				c:cone(V3(0.16, 0.30, 0.16), CF(x, (x == 0) and 1.06 or 0.98, 0), GOLD, NEON)
			end
			for _, o in ipairs({ { 1.30, 0.40, 0 }, { -1.30, -0.10, 0 }, { 0.50, 0.80, -1.00 }, { -0.60, -0.70, 0.90 }, { 0.80, -0.50, -0.80 }, { -0.70, 1.00, 0.60 } }) do
				c:ball(V3(0.20, 0.20, 0.20), CF(o[1], o[2], o[3]), p.glow, NEON)
			end
			c:light(p.glow, 1.5, 8)
			c:sparkle(p.glow, 4, 0.6, 0.2)
		end,
	}

	S.er_t_planet = {
		label = "Seedling Planet",
		set = "eternal_roots",
		tint = C3(80, 90, 220),
		scale = 1.25,
		head = CF(0, 1.70, 0),
		neck = CF(0, -0.60, 0.80),
		back = CF(0, 0.00, -0.80),
		build = function(c, p)
			-- A whole little world sprouted from one seed: oceans and green lands, a
			-- ring of stardust, a tree on top, roots dangling below and two moons.
			c:box(V3(1.60, 1.60, 1.60), CF(0, 0, 0), p.base)
			c:box(V3(0.40, 0.36, 0.06), CF(0.50, -0.50, 0.81), LEAF)
			c:box(V3(0.06, 0.70, 0.60), CF(0.81, 0.20, -0.20), LEAF)
			c:box(V3(0.06, 0.60, 0.50), CF(-0.81, -0.30, 0.30), LEAF_DARK)
			c:box(V3(0.90, 0.06, 0.80), CF(0, 0.81, 0), LEAF)
			c:box(V3(0.60, 0.50, 0.06), CF(-0.30, 0.30, -0.81), LEAF)
			local ring = c:cyl(V3(0.06, 2.70, 2.70), CF(0, -0.10, 0) * ANG(0.25, 0, PI / 2), p.pale, GLASS)
			ring.Transparency = 0.3
			c:cyl(V3(0.04, 2.80, 2.80), CF(0, -0.10, 0) * ANG(0.25, 0, PI / 2), p.glow, NEON)
			c:rod(V3(0, 0.80, 0), V3(0, 1.10, 0), 0.10, BARK, WOOD, false)
			c:box(V3(0.80, 0.40, 0.80), CF(0, 1.28, 0), LEAF)
			c:box(V3(0.44, 0.24, 0.44), CF(0, 1.56, 0), LEAF_DARK)
			c:ball(V3(0.16, 0.16, 0.16), CF(0.40, 1.22, 0.40), p.glow, NEON)
			c:ball(V3(0.16, 0.16, 0.16), CF(-0.36, 1.40, -0.30), p.glow, NEON)
			for _, r in ipairs({ { 0.40, 0.30 }, { -0.40, 0.20 }, { 0, -0.40 } }) do
				c:rod(V3(r[1], -0.80, r[2]), V3(r[1] * 1.3, -1.10, r[2] * 1.3), 0.05, BARK, nil, false)
			end
			c:ball(V3(0.36, 0.36, 0.36), CF(1.36, 0.70, -0.30), p.light)
			c:ball(V3(0.26, 0.26, 0.26), CF(-1.30, 0.70, 0.40), p.pale)
			c:eyes(0.30, 0.82, 0.30, 0.17)
			c:box(V3(0.24, 0.08, 0.05), CF(0, 0.02, 0.81), INK)
			cheeks(c, 0.12, 0.81, 0.50, 0.18)
			c:light(p.glow, 1.2, 8)
			c:sparkle(p.glow, 3, 0.5, 0.18)
		end,
	}

	S.er_t_egg = {
		label = "Cosmic Egg",
		set = "eternal_roots",
		tint = C3(160, 120, 255),
		scale = 1.15,
		head = CF(0, 1.56, 0),
		neck = CF(0, -0.60, 0.80),
		back = CF(0, 0.00, -0.80),
		build = function(c, p)
			-- The egg the first seed hatched from: speckled with stars, cracked open
			-- at the top where a fresh sprout pokes out, resting in a nest of roots.
			c:box(V3(1.30, 0.50, 1.30), CF(0, -0.80, 0), p.base)
			c:box(V3(1.60, 1.10, 1.50), CF(0, -0.10, 0), p.base)
			c:box(V3(1.40, 0.50, 1.30), CF(0, 0.70, 0), p.base)
			for _, k in ipairs({ { -0.50, 0.40 }, { 0, 0.50 }, { 0.50, 0.40 }, { 0.50, -0.40 }, { -0.50, -0.40 }, { 0, -0.50 } }) do
				c:cone(V3(0.30, 0.30, 0.30), CF(k[1], 1.08, k[2]), p.light)
			end
			for i, x in ipairs({ -0.40, 0, 0.40 }) do
				c:box(V3(0.40, 0.06, 0.04), CF(x, 0.48, 0.76) * ANG(0, 0, (i % 2 == 0) and -0.50 or 0.50), p.glow, NEON)
			end
			c:rod(V3(0, 0.95, 0), V3(0, 1.40, 0), 0.06, LEAF_DARK, nil, false)
			c:box(V3(0.40, 0.06, 0.24), CF(0.22, 1.42, 0) * ANG(0, 0, 0.40), LEAF)
			c:box(V3(0.40, 0.06, 0.24), CF(-0.22, 1.42, 0) * ANG(0, 0, -0.40), LEAF)
			c:ball(V3(0.18, 0.18, 0.18), CF(0, 1.48, 0), p.glow, NEON)
			c:eyes(0.02, 0.76, 0.30, 0.16)
			c:box(V3(0.24, 0.08, 0.05), CF(0, -0.32, 0.76), INK)
			cheeks(c, -0.18, 0.76, 0.52, 0.18)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.04, 0.14, 0.14), CF(0.81 * s, 0.10, 0.30), p.glow, NEON)
				c:box(V3(0.04, 0.14, 0.14), CF(0.81 * s, -0.30, -0.30), p.glow, NEON)
				c:box(V3(0.14, 0.14, 0.04), CF(0.30 * s, -0.20 + 0.30 * s, -0.76), p.glow, NEON)
			end
			for i = 0, 4 do
				local a = i * 2 * PI / 5
				local b = a + 1.4
				c:rod(V3(0.90 * math.cos(a), -1.00, 0.90 * math.sin(a)), V3(0.90 * math.cos(b), -0.90, 0.90 * math.sin(b)), 0.08, BARK, WOOD, false)
			end
			c:box(V3(0.30, 0.06, 0.24), CF(0.90, 1.30, 0.20) * ANG(0.40, 0.30, 0.60), p.light)
			c:box(V3(0.30, 0.06, 0.24), CF(-0.86, 1.20, -0.30) * ANG(-0.30, 0, -0.50), p.light)
			c:light(p.glow, 1.2, 8)
			c:sparkle(p.glow, 3, 0.5, 0.18)
		end,
	}

	S.er_t_hare = {
		label = "Moonroot Hare",
		set = "eternal_roots",
		tint = C3(230, 230, 255),
		scale = 1.2,
		head = CF(0, 1.86, 0.06),
		neck = CF(0, -0.30, 0.86),
		back = CF(0, 0.50, -0.70),
		build = function(c, p)
			-- A hare that leapt from the moon down the world-roots: long glowing ears,
			-- a crescent moon riding on its back and a comet's tail behind.
			block(c, p, {
				shape = "round", bodySize = V3(1.60, 1.50, 1.60),
				eyeY = 0.18, eyeSpread = 0.38, eyeSize = V3(0.38, 0.46, 0.18),
				mouthY = -0.24, mouthSize = V3(0.24, 0.10, 0.10),
				legSize = V3(0.36, 0.24, 0.50), legX = 0.44, legY = -0.80, legZ = { 0.40, -0.40 },
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V3(0.36, 1.10, 0.24), CF(0.34 * s, 1.30, 0.06) * ANG(0, 0, -0.18 * s), p.base)
				c:box(V3(0.18, 0.80, 0.06), CF(0.34 * s, 1.30, 0.19) * ANG(0, 0, -0.18 * s), p.glow, NEON)
				c:box(V3(0.04, 0.14, 0.14), CF(0.81 * s, 0.30, -0.20), p.glow, NEON)
				c:box(V3(0.04, 0.14, 0.14), CF(0.81 * s, -0.20, 0.30), p.glow, NEON)
			end
			c:box(V3(0.14, 0.10, 0.06), CF(0, -0.08, 0.83), BLUSH)
			cheeks(c, -0.12, 0.82, 0.54, 0.16)
			for _, t in ipairs({ -1.0, -0.5, 0, 0.5, 1.0 }) do
				local w = (math.abs(t) > 0.7) and 0.12 or 0.18
				c:box(V3(w, w + 0.10, w), CF(0, 1.10, -0.30) * ANG(t, 0, 0) * CF(0, 0, -0.36), GOLD, NEON)
			end
			for _, k in ipairs({ { 0.10, -0.96, 0.44 }, { 0.30, -1.30, 0.34 }, { 0.50, -1.56, 0.24 }, { 0.66, -1.76, 0.16 } }) do
				c:ball(V3(k[3], k[3], k[3]), CF(0, k[1], k[2]), p.glow, NEON)
			end
			c:ball(V3(0.14, 0.14, 0.14), CF(1.10, 1.40, 0.20), p.glow, NEON)
			c:ball(V3(0.12, 0.12, 0.12), CF(-1.10, 0.90, -0.40), p.glow, NEON)
			c:light(p.glow, 1.2, 8)
		end,
	}


	return S
end
