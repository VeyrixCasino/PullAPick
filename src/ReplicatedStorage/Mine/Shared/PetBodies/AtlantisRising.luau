--[[ PetBodies/AtlantisRising -- Atlantis Rising's bodies: sea creatures of a sunken
	city, in turquoise with gold trim, pearls and coral. See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, WHITE, METAL, NEON = K.INK, K.WHITE, K.METAL, K.NEON
	local S = {}

	-- Gold, pearl and coral are the set's jewellery: fixed, so they read on any tint.
	local GOLD = C3(240, 196, 84)
	local PEARL = C3(248, 242, 234)
	local CORAL = C3(255, 120, 112)
	local MANTLE = C3(255, 176, 186)
	local BLUSH = C3(255, 150, 172)
	local SET = "atlantis_rising"

	-- One block-style eye (rounded bead and glint) for bodies built without block().
	local function eyePair(c, y, z, spread, w, h)
		for _, s in ipairs({ -1, 1 }) do
			local ball = c:round(Vector3.new(w, h, 0.22), CFrame.new(spread * s, y, z), INK)
			local glint = c:round(Vector3.new(w * 0.34, h * 0.30, 0.12), CFrame.new((spread - w * 0.17) * s, y + h * 0.22, z + 0.09), WHITE)
			ball:SetAttribute("Eye", true)
			glint:SetAttribute("Eye", true)
		end
	end

	-- An upright seahorse: tube snout, gold coronet, pale ridged belly and a tail
	-- curling up behind.
	S.at_seahorse = {
		label = "Seahorse",
		set = SET,
		tint = C3(52, 196, 188),
		scale = 1.10,
		head = CFrame.new(0, 1.02, 0.12),
		neck = CFrame.new(0, -0.20, 0.76),
		back = CFrame.new(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				bodySize = Vector3.new(1.50, 1.60, 1.36),
				eyeY = 0.26, eyeSpread = 0.38, eyeSize = Vector3.new(0.44, 0.54, 0.20),
				snout = { w = 0.40, h = 0.34, d = 0.84, y = -0.10, color = p.light, nose = p.deep },
				mouth = false, legs = false, tail = false,
			})
			-- Belly bulging forward under the snout, with ridges across it.
			c:box(Vector3.new(1.24, 0.90, 0.50), CFrame.new(0, -0.62, 0.48), p.pale)
			for _, y in ipairs({ -0.42, -0.74 }) do
				c:box(Vector3.new(1.28, 0.06, 0.06), CFrame.new(0, y, 0.74), p.light)
			end
			-- The tail: tapering segments that curl up at the back.
			c:box(Vector3.new(1.00, 0.56, 0.90), CFrame.new(0, -1.00, -0.18), p.base)
			c:box(Vector3.new(0.74, 0.50, 0.70), CFrame.new(0, -1.30, -0.62), p.base)
			c:box(Vector3.new(0.54, 0.46, 0.50), CFrame.new(0, -1.16, -1.00), p.dark)
			c:box(Vector3.new(0.36, 0.36, 0.36), CFrame.new(0, -0.84, -1.04), p.light)
			-- Gold coronet with a pearl at the front.
			c:box(Vector3.new(0.72, 0.16, 0.60), CFrame.new(0, 0.94, -0.06), GOLD, METAL)
			for _, x in ipairs({ -0.24, 0, 0.24 }) do
				c:cone(Vector3.new(0.20, 0.34, 0.20), CFrame.new(x, 1.18, -0.06), GOLD, METAL)
			end
			c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(0, 0.96, 0.28), PEARL)
			-- Dorsal fan and two little ear fins.
			c:box(Vector3.new(0.10, 0.80, 0.56), CFrame.new(0, 0.02, -0.86) * CFrame.Angles(0.20, 0, 0), p.light)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.10, 0.36, 0.42), CFrame.new(0.80 * s, 0.30, -0.10) * CFrame.Angles(0, 0, -0.30 * s), p.light)
			end
		end,
	}

	-- A clam with its lid propped open on a big pearl, gold-lipped shells and
	-- two eyes perched on the lid's rim.
	S.at_pearlclam = {
		label = "Pearl Clam",
		set = SET,
		tint = C3(64, 200, 196),
		head = CFrame.new(0, 1.30, 0.10),
		neck = CFrame.new(0, -0.50, 0.94),
		back = CFrame.new(0, 0.40, -1.00),
		build = function(c, p)
			-- Bottom shell: the bowl, a darker underside step, the gold lip.
			c:box(Vector3.new(2.10, 0.66, 1.80), CFrame.new(0, -0.46, 0), p.base)
			c:box(Vector3.new(1.80, 0.20, 1.50), CFrame.new(0, -0.88, 0), p.dark)
			c:box(Vector3.new(2.18, 0.10, 1.88), CFrame.new(0, -0.12, 0), GOLD, METAL)
			for _, x in ipairs({ -0.62, 0, 0.62 }) do
				c:box(Vector3.new(0.14, 0.52, 0.08), CFrame.new(x, -0.48, 0.92), p.light)
			end
			-- The soft pink mantle and the pearl sitting on it.
			c:box(Vector3.new(1.80, 0.20, 1.50), CFrame.new(0, -0.02, 0), MANTLE)
			c:ball(Vector3.new(0.74, 0.74, 0.74), CFrame.new(0, 0.28, 0.46), PEARL)
			-- The lid, hinged at the back and propped open.
			local lid = CFrame.new(0, -0.08, -0.90) * CFrame.Angles(-0.50, 0, 0)
			c:box(Vector3.new(2.10, 0.50, 1.80), lid * CFrame.new(0, 0.25, 0.90), p.base)
			-- Pearly lining underneath, and a gold band that only shows at the rim.
			c:box(Vector3.new(1.94, 0.06, 1.70), lid * CFrame.new(0, -0.01, 0.92), p.pale)
			c:box(Vector3.new(2.18, 0.10, 1.88), lid * CFrame.new(0, 0.20, 0.90), GOLD, METAL)
			for _, x in ipairs({ -0.62, 0, 0.62 }) do
				c:box(Vector3.new(0.16, 0.10, 1.70), lid * CFrame.new(x, 0.52, 0.90) * CFrame.Angles(0, -x * 0.20, 0), p.light)
			end
			-- Eyes standing on the front of the lid.
			eyePair(c, 1.36, 0.46, 0.46, 0.46, 0.56)
			-- A sprig of coral growing on the lid.
			c:rod(Vector3.new(-0.62, 0.92, -0.36), Vector3.new(-0.70, 1.40, -0.40), 0.07, CORAL, nil, false)
			c:rod(Vector3.new(-0.66, 1.16, -0.38), Vector3.new(-0.90, 1.34, -0.30), 0.06, CORAL, nil, false)
			c:rod(Vector3.new(-0.68, 1.26, -0.39), Vector3.new(-0.50, 1.46, -0.44), 0.05, CORAL, nil, false)
			c:light(PEARL, 1.2, 7)
		end,
	}

	-- A round octopus with a leaning mantle, a gold circlet set with a pearl, and
	-- six curling arms.
	S.at_octopus = {
		label = "Octopus",
		set = SET,
		tint = C3(74, 182, 214),
		scale = 1.04,
		head = CFrame.new(0, 1.40, -0.10),
		neck = CFrame.new(0, -0.50, 0.90),
		back = CFrame.new(0, 0.30, -0.90),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.80, 1.60, 1.70),
				eyeY = 0.06, eyeSpread = 0.40, eyeSize = Vector3.new(0.50, 0.60, 0.22),
				mouthY = -0.40, mouthSize = Vector3.new(0.24, 0.16, 0.14),
				legs = false, tail = false,
			})
			-- The mantle, swelling up and back.
			c:box(Vector3.new(1.40, 1.10, 1.10), CFrame.new(0, 0.86, -0.40) * CFrame.Angles(-0.35, 0, 0), p.base)
			-- Gold circlet with a pearl in front.
			c:box(Vector3.new(1.90, 0.14, 1.76), CFrame.new(0, 0.60, 0), GOLD, METAL)
			c:ball(Vector3.new(0.28, 0.28, 0.28), CFrame.new(0, 0.60, 0.92), PEARL)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.22, 0.12, 0.06), CFrame.new(0.62 * s, -0.20, 0.87), BLUSH)
			end
			-- Six arms splayed around the base, each curling up at the tip.
			for _, deg in ipairs({ 40, -40, 95, -95, 150, -150 }) do
				local a = math.rad(deg)
				local dx, dz = math.sin(a), math.cos(a)
				c:box(Vector3.new(0.36, 0.28, 0.62), CFrame.new(dx * 0.92, -0.82, dz * 0.92) * CFrame.Angles(0, a, 0), p.base)
				c:box(Vector3.new(0.30, 0.40, 0.28), CFrame.new(dx * 1.20, -0.66, dz * 1.20) * CFrame.Angles(0, a, 0) * CFrame.Angles(-0.4, 0, 0), p.light)
			end
		end,
	}

	-- A glassy jellyfish: a stepped bell crowned with gold and a pearl, a glowing
	-- heart, and trailing strands.
	S.at_jellyfish = {
		label = "Jellyfish",
		set = SET,
		tint = C3(120, 214, 236),
		head = CFrame.new(0, 1.28, 0.04),
		neck = CFrame.new(0, -0.30, 1.00),
		back = CFrame.new(0, 0.30, -0.96),
		build = function(c, p)
			-- The bell, in steps, see-through over a glowing heart.
			for _, b in ipairs({ { 2.00, 0.80, 1.86, 0.10 }, { 1.60, 0.40, 1.50, 0.68 } }) do
				c:box(Vector3.new(b[1], b[2], b[3]), CFrame.new(0, b[4], 0), p.base).Transparency = 0.3
			end
			c:box(Vector3.new(1.00, 0.24, 0.94), CFrame.new(0, 0.98, 0), p.light)
			c:box(Vector3.new(1.10, 0.50, 1.00), CFrame.new(0, 0.12, 0), p.glow, NEON)
			-- Frilled rim.
			c:box(Vector3.new(2.20, 0.16, 2.06), CFrame.new(0, -0.34, 0), p.light)
			-- Gold band and a pearl on top.
			c:box(Vector3.new(1.04, 0.10, 0.98), CFrame.new(0, 1.13, 0), GOLD, METAL)
			c:ball(Vector3.new(0.28, 0.28, 0.28), CFrame.new(0, 1.30, 0), PEARL)
			-- Face on the bell.
			eyePair(c, 0.18, 0.98, 0.42, 0.44, 0.54)
			c:box(Vector3.new(0.24, 0.12, 0.08), CFrame.new(0, -0.12, 0.96), INK)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.22, 0.12, 0.06), CFrame.new(0.70 * s, -0.04, 0.95), BLUSH)
				-- Two frilly oral arms in the middle.
				c:box(Vector3.new(0.30, 0.90, 0.14), CFrame.new(0.20 * s, -0.86, 0.10) * CFrame.Angles(0, 0, 0.10 * s), p.pale)
			end
			-- Six wavy strands.
			for _, t in ipairs({ { -0.72, 0.50 }, { 0.72, 0.50 }, { -0.80, -0.42 }, { 0.80, -0.42 }, { -0.28, -0.74 }, { 0.28, -0.74 } }) do
				local x, z = t[1], t[2]
				c:rod(Vector3.new(x, -0.40, z), Vector3.new(x + 0.10, -0.86, z), 0.06, p.light, nil, false)
				c:rod(Vector3.new(x + 0.10, -0.86, z), Vector3.new(x - 0.04, -1.30, z), 0.06, p.light, nil, false)
			end
			c:light(p.glow, 1.6, 8)
		end,
	}

	-- A hermit crab that moved into a fallen temple column: fluted marble, a gold
	-- capital with its scroll rolls, coral growing out of the top.
	S.at_columncrab = {
		label = "Column Crab",
		set = SET,
		tint = C3(46, 176, 168),
		head = CFrame.new(0, 1.42, -0.36),
		neck = CFrame.new(0, -0.50, 0.94),
		back = CFrame.new(0, 0.40, -1.00),
		build = function(c, p)
			-- The column.
			c:cyl(Vector3.new(1.30, 1.24, 1.24), CFrame.new(0, 0.38, -0.36) * CFrame.Angles(0, 0, math.pi / 2), p.pale)
			for i = 0, 5 do
				local a = math.rad(30 + i * 60)
				c:box(Vector3.new(0.12, 1.24, 0.08), CFrame.new(math.sin(a) * 0.62, 0.38, -0.36 + math.cos(a) * 0.62) * CFrame.Angles(0, a, 0), p.light)
			end
			c:box(Vector3.new(1.50, 0.20, 1.50), CFrame.new(0, -0.30, -0.36), GOLD, METAL)
			c:box(Vector3.new(1.56, 0.24, 1.56), CFrame.new(0, 1.15, -0.36), GOLD, METAL)
			c:box(Vector3.new(1.66, 0.12, 1.66), CFrame.new(0, 1.33, -0.36), p.pale)
			for _, s in ipairs({ -1, 1 }) do
				c:cyl(Vector3.new(1.50, 0.34, 0.34), CFrame.new(0.80 * s, 1.12, -0.36) * CFrame.Angles(0, math.pi / 2, 0), GOLD, METAL)
			end
			-- Coral sprouting from the top.
			c:rod(Vector3.new(0.30, 1.38, -0.50), Vector3.new(0.38, 1.70, -0.52), 0.07, CORAL, nil, false)
			c:rod(Vector3.new(0.34, 1.56, -0.51), Vector3.new(0.56, 1.66, -0.42), 0.06, CORAL, nil, false)
			c:rod(Vector3.new(-0.34, 1.38, -0.16), Vector3.new(-0.42, 1.60, -0.12), 0.06, CORAL, nil, false)
			-- The crab, peeking out at the front.
			c:box(Vector3.new(1.44, 0.74, 0.92), CFrame.new(0, -0.48, 0.46), p.base)
			c:box(Vector3.new(0.30, 0.08, 0.06), CFrame.new(0, -0.58, 0.94), INK)
			for _, s in ipairs({ -1, 1 }) do
				c:rod(Vector3.new(0.26 * s, -0.14, 0.70), Vector3.new(0.32 * s, 0.28, 0.80), 0.07, p.dark, nil, false)
				c:round(Vector3.new(0.36, 0.42, 0.32), CFrame.new(0.32 * s, 0.42, 0.82), INK):SetAttribute("Eye", true)
				c:round(Vector3.new(0.13, 0.13, 0.08), CFrame.new(0.26 * s, 0.52, 0.98), WHITE):SetAttribute("Eye", true)
				-- Three walking legs a side.
				for _, z in ipairs({ 0.62, 0.30, -0.02 }) do
					c:box(Vector3.new(0.46, 0.14, 0.14), CFrame.new(0.90 * s, -0.80, z) * CFrame.Angles(0, 0, -0.50 * s), p.dark)
				end
			end
			-- One big claw, one small one, hermit-crab style.
			c:rod(Vector3.new(0.66, -0.50, 0.70), Vector3.new(0.98, -0.40, 1.00), 0.12, p.base, nil, false)
			c:box(Vector3.new(0.62, 0.56, 0.62), CFrame.new(1.02, -0.36, 1.10), p.base)
			c:box(Vector3.new(0.48, 0.22, 0.52), CFrame.new(1.02, -0.02, 1.16) * CFrame.Angles(-0.35, 0, 0), p.light)
			c:box(Vector3.new(0.40, 0.36, 0.40), CFrame.new(-0.86, -0.50, 0.96), p.base)
			c:box(Vector3.new(0.32, 0.14, 0.34), CFrame.new(-0.86, -0.28, 1.00) * CFrame.Angles(-0.35, 0, 0), p.light)
		end,
	}

	return S
end
