--[[ PetBodies/RoyalReserveTop -- Royal Reserve's top bodies. See tools/gen/sets/README.md.

	Epic and up: each body here is worn by exactly ONE pet in the game, so no
	two of them share a silhouette. The set is luxury packaging, precious
	materials and prestige -- engraved gold, black velvet, sophisticated
	symmetry -- so every body is a treasure of the well-to-do: a perfume
	atomizer, a hatbox, a silver cloche, a state coach, a canopy bed, a
	brilliant-cut solitaire. Gold trim is fixed (it is the set's signature);
	each body's main colours come from p.* so its pet wears its own tint.
	Epic stays charming and clean; Legendary is ornate; Mythic, Divine and
	Exotic carry p.glow neon, jewels and floating sparkle, echoing the top
	packs, "Crown Jewels" and "Sovereign's Edition".
]]
return function(K)
	local C3, block, wings = K.C3, K.block, K.wings
	local INK, WHITE, METAL, NEON, GLASS = K.INK, K.WHITE, K.METAL, K.NEON, K.GLASS
	local S = {}

	local SIDES = { -1, 1 }
	local UP = CFrame.Angles(0, 0, math.pi / 2) -- a cylinder standing up
	local FRONT = CFrame.Angles(0, math.pi / 2, 0) -- a cylinder's flat face to the front
	local DIAMOND = CFrame.Angles(0, 0, math.pi / 4) -- a square turned onto its point, face-on
	local GOLD, GOLD_DK = C3(240, 194, 70), C3(196, 146, 48)
	local VELVET, CRIMSON = C3(34, 26, 40), C3(122, 20, 46)
	local RUBY, SAPPHIRE, EMERALD = C3(230, 40, 70), C3(60, 110, 255), C3(40, 210, 120)
	local PEARL, IVORY, SILVER = C3(250, 246, 236), C3(250, 244, 228), C3(214, 220, 232)
	local BLUSH, WOOD, BUBBLE = C3(255, 150, 172), C3(120, 78, 46), C3(240, 250, 255)
	local JEWELS = { RUBY, SAPPHIRE, EMERALD, C3(255, 180, 40) }

	-- Cartoon eyes and a small mouth on a flat front at depth `z`.
	local function face(c, y, z, spread, r)
		c:eyes(y, z + r * 0.3, spread, r)
		c:box(Vector3.new(r * 1.5, r * 0.45, 0.06), CFrame.new(0, y - r * 2.0, z + 0.02), INK)
	end

	-- Rosy cheeks either side of a face.
	local function blush(c, x, y, z)
		for _, s in ipairs(SIDES) do
			c:box(Vector3.new(0.20, 0.10, 0.05), CFrame.new(x * s, y, z), BLUSH)
		end
	end

	-- A cut jewel set face-on: a glowing square turned onto its point.
	local function jewel(c, cf, size, colour)
		return c:box(Vector3.new(size, size, size * 0.5), cf * DIAMOND, colour, NEON)
	end

	-- ===================================================================
	-- EPIC: charming and clean.
	-- ===================================================================

	-- A cut-glass perfume bottle with a silk bulb puffer hung off its shoulder.
	S.rr_t_atomizer = {
		label = "Scent Atomizer",
		set = "royal_reserve",
		tint = C3(186, 120, 250),
		head = CFrame.new(0, 1.30, 0),
		neck = CFrame.new(0, -0.46, 0.66),
		back = CFrame.new(0, 0.10, -0.66),
		build = function(c, p)
			c:box(Vector3.new(1.60, 1.30, 1.20), CFrame.new(0, -0.20, 0), p.base)
			c:box(Vector3.new(1.64, 0.46, 1.24), CFrame.new(0, -0.60, 0), p.light) -- the scent inside
			c:box(Vector3.new(1.20, 0.24, 0.90), CFrame.new(0, 0.57, 0), p.base) -- shoulder
			c:cyl(Vector3.new(0.30, 0.46, 0.46), CFrame.new(0, 0.82, 0) * UP, GOLD, METAL)
			c:box(Vector3.new(0.30, 0.22, 0.30), CFrame.new(0, 1.07, 0), GOLD, METAL) -- pump head
			c:rod(Vector3.new(0, 1.07, 0.12), Vector3.new(0, 1.07, 0.42), 0.05, GOLD, METAL, false)
			-- Silk tube to the bulb, and the bulb's gold tassel.
			c:rod(Vector3.new(0.14, 1.05, 0), Vector3.new(0.95, 0.70, 0), 0.05, p.deep, nil, false)
			c:ball(Vector3.new(0.50, 0.50, 0.50), CFrame.new(1.05, 0.48, 0), p.dark)
			c:cone(Vector3.new(0.22, 0.34, 0.22), CFrame.new(1.05, 0.10, 0) * CFrame.Angles(math.pi, 0, 0), GOLD)
			face(c, -0.10, 0.60, 0.34, 0.14)
			blush(c, 0.58, -0.30, 0.61)
			c:box(Vector3.new(0.70, 0.22, 0.04), CFrame.new(0, -0.62, 0.63), GOLD, METAL) -- label
			jewel(c, CFrame.new(0, -0.62, 0.66), 0.14, RUBY)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(0.62 * s, -0.88, 0.44 * t), GOLD, METAL)
				end
			end
		end,
	}

	-- A round hatbox with its lid worn at a jaunty tilt and a ribbon bow on top.
	S.rr_t_hatbox = {
		label = "Ribbon Hatbox",
		set = "royal_reserve",
		tint = C3(30, 186, 176),
		head = CFrame.new(0, 1.30, 0),
		neck = CFrame.new(0, -0.50, 0.96),
		back = CFrame.new(0, 0.00, -0.96),
		build = function(c, p)
			c:cyl(Vector3.new(1.10, 1.90, 1.90), CFrame.new(0, -0.24, 0) * UP, p.base)
			c:cyl(Vector3.new(0.18, 1.93, 1.93), CFrame.new(0, -0.62, 0) * UP, p.pale) -- stripe
			c:cyl(Vector3.new(0.30, 2.04, 2.04), CFrame.new(0, 0.44, 0) * CFrame.Angles(0, 0, 0.08) * UP, p.dark) -- lid
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.52, 0.34, 0.20), CFrame.new(0.30 * s, 0.82, 0) * CFrame.Angles(0, 0, 0.45 * s), p.light)
				c:box(Vector3.new(0.14, 0.50, 0.06), CFrame.new(0.20 * s, 0.40, 1.04) * CFrame.Angles(0, 0, 0.30 * s), p.light)
				for _, t in ipairs(SIDES) do
					c:box(Vector3.new(0.34, 0.22, 0.40), CFrame.new(0.50 * s, -0.86, 0.40 * t), p.deep)
				end
			end
			c:box(Vector3.new(0.24, 0.24, 0.24), CFrame.new(0, 0.74, 0), p.light) -- knot
			face(c, -0.18, 0.95, 0.30, 0.15)
			blush(c, 0.56, -0.36, 0.78)
			c:cyl(Vector3.new(0.06, 0.30, 0.30), CFrame.new(0, -0.62, 0.97) * FRONT, GOLD, METAL) -- monogram
		end,
	}

	-- A kiss-lock purse: the two clasp knobs read as little antennae.
	S.rr_t_purse = {
		label = "Clasp Purse",
		set = "royal_reserve",
		tint = C3(210, 30, 60),
		head = CFrame.new(0, 1.60, 0),
		neck = CFrame.new(0, -0.50, 0.66),
		back = CFrame.new(0, 0.00, -0.66),
		build = function(c, p)
			c:box(Vector3.new(1.90, 1.10, 1.20), CFrame.new(0, -0.30, 0), p.base)
			c:box(Vector3.new(1.60, 0.40, 1.04), CFrame.new(0, 0.42, 0), p.base)
			c:box(Vector3.new(1.94, 0.10, 1.24), CFrame.new(0, -0.80, 0), p.deep) -- base seam
			c:box(Vector3.new(1.70, 0.12, 1.10), CFrame.new(0, 0.66, 0), GOLD, METAL) -- frame
			for _, s in ipairs(SIDES) do
				c:ball(Vector3.new(0.26, 0.26, 0.26), CFrame.new(0.13 * s, 0.86, 0), GOLD, METAL)
			end
			-- Chain strap arching overhead.
			local chain = {
				Vector3.new(-0.80, 0.70, 0), Vector3.new(-0.62, 1.22, 0), Vector3.new(0, 1.46, 0),
				Vector3.new(0.62, 1.22, 0), Vector3.new(0.80, 0.70, 0),
			}
			for i = 1, #chain - 1 do
				c:rod(chain[i], chain[i + 1], 0.045, GOLD, METAL, false)
			end
			face(c, -0.10, 0.60, 0.36, 0.15)
			blush(c, 0.62, -0.32, 0.61)
			c:box(Vector3.new(0.34, 0.24, 0.06), CFrame.new(0, -0.62, 0.62), GOLD, METAL) -- turn-lock
			jewel(c, CFrame.new(0, -0.62, 0.66), 0.14, SAPPHIRE)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0.70 * s, -0.90, 0.40 * t), GOLD, METAL)
				end
			end
		end,
	}

	-- A silver dinner cloche on its gold platter, stepped like a little dome.
	S.rr_t_cloche = {
		label = "Silver Cloche",
		set = "royal_reserve",
		tint = C3(170, 196, 236),
		head = CFrame.new(0, 1.10, 0),
		neck = CFrame.new(0, -0.60, 0.86),
		back = CFrame.new(0, -0.10, -0.86),
		build = function(c, p)
			c:cyl(Vector3.new(0.14, 2.20, 2.20), CFrame.new(0, -0.74, 0) * UP, GOLD, METAL) -- platter
			c:box(Vector3.new(1.80, 0.66, 1.60), CFrame.new(0, -0.33, 0), p.base, METAL)
			c:box(Vector3.new(1.46, 0.40, 1.30), CFrame.new(0, 0.18, 0), p.light, METAL)
			c:box(Vector3.new(1.00, 0.26, 0.90), CFrame.new(0, 0.50, 0), p.base, METAL)
			c:box(Vector3.new(1.84, 0.08, 1.64), CFrame.new(0, -0.62, 0), GOLD, METAL) -- rim
			c:cyl(Vector3.new(0.14, 0.18, 0.18), CFrame.new(0, 0.70, 0) * UP, GOLD, METAL)
			c:ball(Vector3.new(0.32, 0.32, 0.32), CFrame.new(0, 0.90, 0), GOLD, METAL) -- knob
			face(c, -0.26, 0.80, 0.34, 0.12)
			blush(c, 0.58, -0.40, 0.81)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.20, 0.10, 0.40), CFrame.new(1.14 * s, -0.70, 0), GOLD, METAL) -- platter handles
				for _, t in ipairs(SIDES) do
					c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.66 * s, -0.88, 0.60 * t), GOLD, METAL)
				end
			end
			c:star(Vector3.new(0.46, 0.30, 0.68), 0.30, WHITE)
		end,
	}


	-- A prize rosette: pleats behind, a face on the centre, two ribbon tails for legs.
	S.rr_t_medal = {
		label = "Rosette Medal",
		set = "royal_reserve",
		tint = C3(40, 80, 230),
		scale = 1.1,
		head = CFrame.new(0, 1.60, 0),
		neck = CFrame.new(0, -0.30, 0.30),
		back = CFrame.new(0, 0.40, -0.30),
		build = function(c, p)
			local at = CFrame.new(0, 0.40, 0)
			c:box(Vector3.new(1.60, 1.60, 0.20), at * CFrame.new(0, 0, -0.06), p.dark)
			c:box(Vector3.new(1.60, 1.60, 0.20), at * CFrame.new(0, 0, -0.06) * DIAMOND, p.dark)
			c:cyl(Vector3.new(0.24, 1.90, 1.90), at * FRONT, p.base)
			c:cyl(Vector3.new(0.08, 1.30, 1.30), at * CFrame.new(0, 0, 0.14) * FRONT, GOLD, METAL)
			c:cyl(Vector3.new(0.08, 1.12, 1.12), at * CFrame.new(0, 0, 0.18) * FRONT, p.pale)
			face(c, 0.46, 0.22, 0.24, 0.12)
			blush(c, 0.32, 0.26, 0.23)
			c:box(Vector3.new(0.50, 0.12, 0.04), CFrame.new(0, 0.76, 0.23), GOLD, METAL) -- "first prize" bar
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.44, 1.10, 0.10), CFrame.new(0.30 * s, -0.55, -0.04) * CFrame.Angles(0, 0, 0.18 * s), p.base)
				c:box(Vector3.new(0.46, 0.08, 0.12), CFrame.new(0.35 * s, -0.78, -0.04) * CFrame.Angles(0, 0, 0.18 * s), GOLD, METAL)
			end
			c:star(Vector3.new(0.90, 1.20, 0.10), 0.34, p.glow)
		end,
	}

	-- A floating silk bow tie, its knot the face, a diamond tie pin on top.
	S.rr_t_bowtie = {
		label = "Silk Bowtie",
		set = "royal_reserve",
		tint = C3(210, 40, 180),
		head = CFrame.new(0, 0.90, 0),
		neck = CFrame.new(0, -0.60, 0.30),
		back = CFrame.new(0, 0.10, -0.50),
		build = function(c, p)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.50, 0.80, 0.56), CFrame.new(0.58 * s, 0.10, 0), p.base) -- pinched inner wing
				c:box(Vector3.new(0.56, 1.40, 0.62), CFrame.new(1.00 * s, 0.10, 0), p.base) -- flared outer wing
				c:box(Vector3.new(0.08, 1.20, 0.06), CFrame.new(0.84 * s, 0.10, 0.32), p.dark) -- fold
				c:box(Vector3.new(0.18, 0.18, 0.04), CFrame.new(1.04 * s, 0.50, 0.32), p.pale) -- polka dots
				c:box(Vector3.new(0.18, 0.18, 0.04), CFrame.new(1.04 * s, -0.30, 0.32), p.pale)
			end
			c:box(Vector3.new(0.86, 0.90, 0.76), CFrame.new(0, 0.10, 0.04), p.dark) -- the knot
			face(c, 0.18, 0.42, 0.18, 0.11)
			blush(c, 0.30, 0.00, 0.43)
			jewel(c, CFrame.new(0, 0.46, 0.43), 0.14, WHITE)
		end,
	}

	-- A hanging silk tassel: a knob for a head, a fringed skirt below.
	S.rr_t_tassel = {
		label = "Silk Tassel",
		set = "royal_reserve",
		tint = C3(255, 196, 40),
		scale = 1.1,
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, -0.10, 0.74),
		back = CFrame.new(0, 0.40, -0.56),
		build = function(c, p)
			c:box(Vector3.new(1.10, 0.90, 1.00), CFrame.new(0, 0.66, 0), p.base) -- the knob
			c:box(Vector3.new(1.24, 0.20, 1.14), CFrame.new(0, 0.18, 0), GOLD, METAL) -- wrapped neck
			c:box(Vector3.new(1.50, 0.80, 1.40), CFrame.new(0, -0.30, 0), p.base)
			c:box(Vector3.new(1.80, 0.36, 1.66), CFrame.new(0, -0.76, 0), p.light) -- flared hem
			for _, x in ipairs({ -0.66, -0.22, 0.22, 0.66 }) do
				c:box(Vector3.new(0.16, 0.30, 0.16), CFrame.new(x, -1.04, 0.52), p.light)
			end
			for _, x in ipairs({ -0.44, 0.44 }) do
				c:box(Vector3.new(0.16, 0.30, 0.16), CFrame.new(x, -1.04, -0.52), p.light)
			end
			c:cyl(Vector3.new(0.10, 0.46, 0.46), CFrame.new(0, 1.30, 0) * FRONT, GOLD, METAL) -- hanging loop
			face(c, 0.68, 0.50, 0.24, 0.12)
			blush(c, 0.38, 0.48, 0.51)
			jewel(c, CFrame.new(0, 0.18, 0.58), 0.16, RUBY)
		end,
	}

	-- A chess rook: a crenellated tower on a turned foot, flying a pennant.
	S.rr_t_rook = {
		label = "Ebony Rook",
		set = "royal_reserve",
		tint = C3(46, 40, 60),
		head = CFrame.new(0, 1.50, 0),
		neck = CFrame.new(0, -0.30, 0.76),
		back = CFrame.new(0, 0.10, -0.76),
		build = function(c, p)
			c:cyl(Vector3.new(0.26, 1.90, 1.90), CFrame.new(0, -0.82, 0) * UP, p.dark) -- foot
			c:cyl(Vector3.new(0.16, 1.62, 1.62), CFrame.new(0, -0.62, 0) * UP, GOLD, METAL)
			c:box(Vector3.new(1.40, 1.20, 1.40), CFrame.new(0, -0.02, 0), p.base) -- tower
			c:box(Vector3.new(1.46, 0.10, 1.46), CFrame.new(0, 0.48, 0), GOLD, METAL)
			c:box(Vector3.new(1.80, 0.30, 1.80), CFrame.new(0, 0.70, 0), p.base) -- parapet
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(Vector3.new(0.44, 0.40, 0.44), CFrame.new(0.68 * s, 1.05, 0.68 * t), p.base)
				end
			end
			for _, v in ipairs({ { 0, 0.68 }, { 0, -0.68 }, { 0.68, 0 }, { -0.68, 0 } }) do
				c:box(Vector3.new(0.36, 0.30, 0.36), CFrame.new(v[1], 1.00, v[2]), p.light)
			end
			face(c, 0.04, 0.70, 0.30, 0.15)
			blush(c, 0.50, -0.16, 0.71)
			c:rod(Vector3.new(0, 0.85, 0), Vector3.new(0, 1.55, 0), 0.04, GOLD, METAL, false)
			c:box(Vector3.new(0.40, 0.26, 0.04), CFrame.new(0.22, 1.42, 0), RUBY)
		end,
	}

	-- An old brass cash register: drawer for a chin, keys, a pop-up sign.
	S.rr_t_register = {
		label = "Brass Register",
		set = "royal_reserve",
		tint = C3(220, 150, 40),
		head = CFrame.new(0, 1.40, -0.20),
		neck = CFrame.new(0, -0.50, 0.86),
		back = CFrame.new(0, 0.20, -0.76),
		build = function(c, p)
			c:box(Vector3.new(2.00, 0.56, 1.50), CFrame.new(0, -0.60, 0), p.dark, METAL) -- cash drawer
			c:box(Vector3.new(1.70, 0.36, 0.04), CFrame.new(0, -0.60, 0.77), p.base, METAL)
			c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(0, -0.60, 0.82), GOLD, METAL)
			local bed = CFrame.new(0, -0.22, 0.42) * CFrame.Angles(0.45, 0, 0)
			c:box(Vector3.new(1.80, 0.24, 0.70), bed, p.deep, METAL) -- sloped key bed
			c:box(Vector3.new(1.50, 0.06, 0.14), bed * CFrame.new(0, 0.14, 0.15), p.pale)
			c:box(Vector3.new(1.50, 0.06, 0.14), bed * CFrame.new(0, 0.14, -0.15), p.pale)
			c:box(Vector3.new(1.60, 0.90, 0.90), CFrame.new(0, 0.30, -0.25), p.base, METAL)
			face(c, 0.42, 0.20, 0.30, 0.15)
			blush(c, 0.56, 0.22, 0.21)
			c:box(Vector3.new(0.90, 0.46, 0.06), CFrame.new(0, 1.02, -0.30), GOLD, METAL) -- sign frame
			c:box(Vector3.new(0.80, 0.36, 0.08), CFrame.new(0, 1.02, -0.25), p.pale) -- sign
			jewel(c, CFrame.new(0, 1.02, -0.20), 0.14, EMERALD)
			c:rod(Vector3.new(0.80, 0.10, -0.25), Vector3.new(1.08, 0.10, -0.25), 0.05, GOLD, METAL, false) -- crank
			c:rod(Vector3.new(1.08, 0.10, -0.25), Vector3.new(1.08, 0.36, -0.25), 0.05, GOLD, METAL, false)
			c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(1.08, 0.40, -0.25), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0.80 * s, -0.92, 0.60 * t), GOLD, METAL)
				end
			end
		end,
	}

	-- A boutique shopping bag: rope handles, tissue paper fluffing out the top.
	S.rr_t_bag = {
		label = "Boutique Bag",
		set = "royal_reserve",
		tint = C3(130, 230, 190),
		head = CFrame.new(0, 1.50, 0),
		neck = CFrame.new(0, -0.50, 0.56),
		back = CFrame.new(0, 0.10, -0.56),
		build = function(c, p)
			c:box(Vector3.new(1.70, 1.60, 1.00), CFrame.new(0, -0.12, 0), p.base)
			c:box(Vector3.new(1.74, 0.20, 1.04), CFrame.new(0, 0.62, 0), p.dark) -- turned-down cuff
			for _, z in ipairs({ 0.30, -0.30 }) do
				c:rod(Vector3.new(-0.42, 0.70, z), Vector3.new(0, 1.30, z), 0.05, p.deep, nil, false)
				c:rod(Vector3.new(0.42, 0.70, z), Vector3.new(0, 1.30, z), 0.05, p.deep, nil, false)
			end
			c:box(Vector3.new(0.60, 0.56, 0.06), CFrame.new(-0.32, 0.86, 0.10) * CFrame.Angles(0, 0.3, 0.35), p.pale)
			c:box(Vector3.new(0.60, 0.62, 0.06), CFrame.new(0.30, 0.88, -0.06) * CFrame.Angles(0, -0.3, -0.30), p.pale)
			c:box(Vector3.new(0.56, 0.50, 0.06), CFrame.new(0, 0.84, -0.20) * CFrame.Angles(0, 0, 0.05), p.pale)
			face(c, 0.10, 0.50, 0.32, 0.14)
			blush(c, 0.56, -0.10, 0.51)
			c:cyl(Vector3.new(0.06, 0.40, 0.40), CFrame.new(0, -0.48, 0.52) * FRONT, GOLD, METAL) -- boutique seal
			jewel(c, CFrame.new(0, -0.48, 0.56), 0.12, EMERALD)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.40, 0.18, 0.50), CFrame.new(0.50 * s, -0.98, 0.10), p.deep)
			end
		end,
	}

	-- A combination safe: the dial is its nose, the door handle a little wheel.
	S.rr_t_safe = {
		label = "Dial Safe",
		set = "royal_reserve",
		tint = C3(20, 100, 60),
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, -0.50, 0.96),
		back = CFrame.new(0, 0.20, -0.86),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.90, 1.80, 1.60),
				eyeY = 0.42, eyeSize = Vector3.new(0.42, 0.50, 0.22), eyeSpread = 0.40,
				mouth = false, tail = false,
				legSize = Vector3.new(0.40, 0.24, 0.40), legX = 0.66, legY = -0.90, legColor = GOLD,
			})
			c:box(Vector3.new(1.56, 1.50, 0.04), CFrame.new(0, 0.06, 0.81), p.dark) -- the door
			c:box(Vector3.new(0.22, 0.07, 0.06), CFrame.new(0, 0.12, 0.84), INK) -- mouth
			c:cyl(Vector3.new(0.08, 0.62, 0.62), CFrame.new(0, -0.26, 0.86) * FRONT, GOLD, METAL) -- dial
			c:cyl(Vector3.new(0.08, 0.24, 0.24), CFrame.new(0, -0.26, 0.91) * FRONT, p.deep)
			c:box(Vector3.new(0.04, 0.10, 0.04), CFrame.new(0, -0.02, 0.91), INK) -- tick
			c:box(Vector3.new(0.36, 0.06, 0.06), CFrame.new(0.54, -0.26, 0.86) * DIAMOND, GOLD, METAL) -- handle
			c:box(Vector3.new(0.06, 0.36, 0.06), CFrame.new(0.54, -0.26, 0.86) * DIAMOND, GOLD, METAL)
			c:ball(Vector3.new(0.12, 0.12, 0.12), CFrame.new(0.54, -0.26, 0.90), GOLD, METAL)
			for _, y in ipairs({ 0.55, -0.45 }) do
				c:box(Vector3.new(0.10, 0.26, 0.10), CFrame.new(-0.78, y, 0.82), GOLD, METAL) -- hinges
			end
			for _, s in ipairs(SIDES) do
				for _, y in ipairs({ 0.72, -0.60 }) do
					c:ball(Vector3.new(0.12, 0.12, 0.12), CFrame.new(0.64 * s, y, 0.84), GOLD, METAL) -- rivets
				end
			end
			c:box(Vector3.new(0.80, 0.26, 0.42), CFrame.new(0, 1.09, 0), GOLD, METAL) -- gold bars on top
			c:box(Vector3.new(0.60, 0.20, 0.32), CFrame.new(0.08, 1.31, 0), GOLD, METAL)
		end,
	}

	-- A plush chinchilla: a round fluffball with huge ears and a pearl necklace.
	S.rr_t_chinchilla = {
		label = "Plush Chinchilla",
		set = "royal_reserve",
		tint = C3(190, 180, 225),
		head = CFrame.new(0, 1.40, 0.10),
		neck = CFrame.new(0, -0.52, 0.92),
		back = CFrame.new(0, 0.30, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.90, 1.70, 1.70),
				snout = { w = 0.50, h = 0.32, d = 0.36, y = -0.20, color = p.pale, nose = BLUSH },
				legSize = Vector3.new(0.34, 0.22, 0.36), legX = 0.48, legY = -0.82, legColor = p.dark,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.66, 0.66, 0.16), CFrame.new(0.58 * s, 1.18, 0) * CFrame.Angles(0, 0, -0.25 * s), p.base)
				c:box(Vector3.new(0.40, 0.40, 0.06), CFrame.new(0.58 * s, 1.18, 0.10) * CFrame.Angles(0, 0, -0.25 * s), p.pale)
			end
			c:box(Vector3.new(0.50, 0.50, 0.50), CFrame.new(0, -0.30, -0.95), p.light) -- bushy tail
			c:box(Vector3.new(0.46, 0.60, 0.40), CFrame.new(0, 0.20, -1.10), p.light)
			for i, x in ipairs({ -0.30, 0, 0.30 }) do
				c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(x, i == 2 and -0.58 or -0.52, 0.90), PEARL)
			end
		end,
	}



	-- A gold-footed clawfoot bathtub, brimming with bubbles.
	S.rr_t_tub = {
		label = "Clawfoot Tub",
		set = "royal_reserve",
		tint = C3(100, 196, 255),
		head = CFrame.new(0, 1.10, 0),
		neck = CFrame.new(0, -0.50, 0.76),
		back = CFrame.new(0, 0.10, -0.76),
		build = function(c, p)
			c:box(Vector3.new(2.00, 0.90, 1.30), CFrame.new(0, -0.24, 0), p.base)
			c:box(Vector3.new(2.08, 0.14, 1.38), CFrame.new(0, 0.26, 0), p.pale) -- rolled rim
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.34, 0.30, 1.38), CFrame.new(0.92 * s, 0.40, 0), p.pale) -- raised ends
				for _, t in ipairs(SIDES) do
					c:box(Vector3.new(0.26, 0.38, 0.26), CFrame.new(0.74 * s, -0.84, 0.44 * t) * CFrame.Angles(0, 0, 0.25 * s), GOLD, METAL)
				end
			end
			for _, b in ipairs({ { -0.45, 0.48, 0.10, 0.44 }, { 0, 0.56, -0.10, 0.56 }, { 0.42, 0.46, 0.15, 0.40 }, { -0.15, 0.48, 0.42, 0.30 }, { 0.25, 0.72, -0.25, 0.34 } }) do
				c:ball(Vector3.new(b[4], b[4], b[4]), CFrame.new(b[1], b[2], b[3]), BUBBLE)
			end
			c:rod(Vector3.new(0, 0.30, -0.62), Vector3.new(0, 0.82, -0.62), 0.05, GOLD, METAL, false) -- gooseneck tap
			c:rod(Vector3.new(0, 0.82, -0.62), Vector3.new(0, 0.82, -0.38), 0.05, GOLD, METAL, false)
			for _, s in ipairs(SIDES) do
				c:ball(Vector3.new(0.14, 0.14, 0.14), CFrame.new(0.18 * s, 0.40, -0.62), GOLD, METAL)
			end
			face(c, -0.22, 0.65, 0.36, 0.15)
			blush(c, 0.62, -0.42, 0.66)
		end,
	}

	-- A spoonbill whose bill is a real silver spoon, and a napkin tucked in.
	S.rr_t_spoonbill = {
		label = "Silver Spoonbill",
		set = "royal_reserve",
		tint = C3(255, 140, 180),
		scale = 1.1,
		head = CFrame.new(0, 1.30, 0.10),
		neck = CFrame.new(0, -0.40, 0.86),
		back = CFrame.new(0, 0.30, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = Vector3.new(1.70, 1.60, 1.60),
				mouth = false, legs = false, tail = false, eyeY = 0.22,
			})
			c:rod(Vector3.new(0, -0.05, 0.80), Vector3.new(0, -0.22, 1.45), 0.07, SILVER, METAL, false)
			c:box(Vector3.new(0.40, 0.10, 0.46), CFrame.new(0, -0.26, 1.62), SILVER, METAL) -- the spoon's bowl
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.30 * s, -0.70, 0.05), Vector3.new(0.30 * s, -1.05, 0.05), 0.06, p.deep, nil, false)
				c:box(Vector3.new(0.30, 0.08, 0.36), CFrame.new(0.30 * s, -1.08, 0.15), p.deep)
			end
			wings(c, p.dark, 0.26, 0.10, -0.20, 0.30)
			for i = -1, 1 do
				c:box(Vector3.new(0.10, 0.40, 0.10), CFrame.new(i * 0.14, 1.02, -0.30) * CFrame.Angles(-0.5, 0, -i * 0.3), p.light)
			end
			c:cone(Vector3.new(0.70, 0.50, 0.10), CFrame.new(0, -0.44, 0.84) * CFrame.Angles(math.pi, 0, 0), WHITE) -- napkin
		end,
	}

	-- An auction gavel resting on its sound block: going, going, gone!
	S.rr_t_gavel = {
		label = "Auction Gavel",
		set = "royal_reserve",
		tint = C3(150, 70, 40),
		head = CFrame.new(0, 0.90, 0),
		neck = CFrame.new(0, -0.50, 0.66),
		back = CFrame.new(0, 0.10, -1.10),
		build = function(c, p)
			c:cyl(Vector3.new(1.80, 1.16, 1.16), CFrame.new(0, 0, 0), p.base) -- the head, axis across
			for _, s in ipairs(SIDES) do
				c:cyl(Vector3.new(0.14, 1.22, 1.22), CFrame.new(0.66 * s, 0, 0), GOLD, METAL)
				c:cyl(Vector3.new(0.12, 0.96, 0.96), CFrame.new(0.96 * s, 0, 0), p.dark)
			end
			c:rod(Vector3.new(0, 0.10, -0.50), Vector3.new(0, 0.34, -1.40), 0.12, p.dark, nil, false) -- handle
			c:ball(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0, 0.36, -1.46), GOLD, METAL)
			c:cyl(Vector3.new(0.32, 1.50, 1.50), CFrame.new(0, -0.74, 0) * UP, p.dark) -- sound block
			c:cyl(Vector3.new(0.08, 1.54, 1.54), CFrame.new(0, -0.62, 0) * UP, GOLD, METAL)
			face(c, 0.06, 0.58, 0.26, 0.14)
			c:box(Vector3.new(0.22, 0.30, 0.04), CFrame.new(0.66, -0.40, 0.62) * CFrame.Angles(0, 0, 0.2), p.pale) -- lot tag
		end,
	}

	-- ===================================================================
	-- LEGENDARY: more ornate, more gold.
	-- ===================================================================


	-- A queen angelfish: tall diamond body, sweeping fins, a gold crown spot.
	S.rr_t_angelfish = {
		label = "Queen Angelfish",
		set = "royal_reserve",
		tint = C3(0, 200, 210),
		scale = 1.1,
		head = CFrame.new(0, 1.20, 0.20),
		neck = CFrame.new(0, -0.60, 0.70),
		back = CFrame.new(0, 0.40, -0.60),
		build = function(c, p)
			c:box(Vector3.new(0.90, 1.30, 1.40), CFrame.new(0, 0.10, 0), p.base)
			c:box(Vector3.new(0.86, 1.10, 1.10), CFrame.new(0, 0.10, -0.10) * CFrame.Angles(math.pi / 4, 0, 0), p.base)
			for _, z in ipairs({ 0.15, -0.35 }) do
				c:box(Vector3.new(0.94, 1.32, 0.12), CFrame.new(0, 0.10, z), p.dark) -- stripes
			end
			c:box(Vector3.new(0.14, 1.00, 0.60), CFrame.new(0, 0.96, -0.40) * CFrame.Angles(-0.6, 0, 0), p.light) -- dorsal
			c:rod(Vector3.new(0, 1.30, -0.80), Vector3.new(0, 1.05, -1.40), 0.04, p.light, nil, false)
			c:box(Vector3.new(0.14, 0.90, 0.60), CFrame.new(0, -0.74, -0.40) * CFrame.Angles(0.6, 0, 0), p.light) -- anal fin
			c:rod(Vector3.new(0, -1.05, -0.80), Vector3.new(0, -0.85, -1.40), 0.04, p.light, nil, false)
			c:box(Vector3.new(0.12, 0.60, 0.50), CFrame.new(0, 0.35, -1.05) * CFrame.Angles(-0.5, 0, 0), p.light) -- tail
			c:box(Vector3.new(0.12, 0.60, 0.50), CFrame.new(0, -0.15, -1.05) * CFrame.Angles(0.5, 0, 0), p.light)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.10, 0.30, 0.50), CFrame.new(0.50 * s, -0.05, 0.15) * CFrame.Angles(0, -0.4 * s, 0), p.light)
			end
			c:eyes(0.26, 0.74, 0.22, 0.12)
			c:box(Vector3.new(0.26, 0.14, 0.12), CFrame.new(0, -0.04, 0.74), p.pale) -- pouty lips
			c:box(Vector3.new(0.22, 0.22, 0.06), CFrame.new(0, 0.60, 0.71) * DIAMOND, GOLD, METAL) -- crown spot
			jewel(c, CFrame.new(0, 0.60, 0.75), 0.12, SAPPHIRE)
			c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.25, 1.30, 0.55), BUBBLE)
			c:ball(Vector3.new(0.12, 0.12, 0.12), CFrame.new(0.12, 1.52, 0.62), BUBBLE)
		end,
	}

	-- A sturgeon baron: long armoured fish, gold scutes down its back, a medal.
	S.rr_t_sturgeon = {
		label = "Sturgeon Baron",
		set = "royal_reserve",
		tint = C3(100, 120, 190),
		scale = 1.25,
		head = CFrame.new(0, 0.80, 0.50),
		neck = CFrame.new(0, -0.60, 1.00),
		back = CFrame.new(0, 0.70, -0.60),
		build = function(c, p)
			c:box(Vector3.new(1.10, 1.00, 2.20), CFrame.new(0, 0, 0), p.base)
			c:box(Vector3.new(1.00, 0.24, 2.00), CFrame.new(0, -0.52, 0), p.pale) -- belly
			c:box(Vector3.new(0.70, 0.46, 0.50), CFrame.new(0, -0.22, 1.30), p.base) -- long snout
			c:box(Vector3.new(0.46, 0.30, 0.30), CFrame.new(0, -0.24, 1.66), p.light)
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.14 * s, -0.42, 1.40), Vector3.new(0.18 * s, -0.72, 1.44), 0.035, p.light, nil, false) -- barbels
				c:box(Vector3.new(0.50, 0.08, 0.40), CFrame.new(0.70 * s, -0.40, 0.50) * CFrame.Angles(0, 0, 0.4 * s), p.dark) -- pectorals
			end
			c:eyes(0.26, 1.14, 0.30, 0.13)
			blush(c, 0.44, -0.08, 1.11)
			for _, z in ipairs({ 0.80, 0.40, 0, -0.40, -0.80 }) do
				c:box(Vector3.new(0.22, 0.22, 0.22), CFrame.new(0, 0.52, z) * DIAMOND, GOLD, METAL) -- scutes
			end
			c:box(Vector3.new(0.14, 0.90, 0.50), CFrame.new(0, 0.40, -1.40) * CFrame.Angles(-0.6, 0, 0), p.dark) -- tail
			c:box(Vector3.new(0.14, 0.50, 0.40), CFrame.new(0, -0.22, -1.30) * CFrame.Angles(0.6, 0, 0), p.dark)
			c:box(Vector3.new(0.10, 0.40, 0.40), CFrame.new(0, 0.65, -0.85), p.dark) -- dorsal
			c:rod(Vector3.new(0, -0.45, 1.12), Vector3.new(0, -0.62, 1.13), 0.03, CRIMSON, nil, false) -- medal ribbon
			c:cyl(Vector3.new(0.06, 0.34, 0.34), CFrame.new(0, -0.74, 1.13) * FRONT, GOLD, METAL)
		end,
	}

	-- A concert cello standing on its endpin, bow at its side.
	S.rr_t_cello = {
		label = "Concert Cello",
		set = "royal_reserve",
		tint = C3(216, 104, 36),
		scale = 1.25,
		head = CFrame.new(0, 2.00, 0),
		neck = CFrame.new(0, -0.60, 0.40),
		back = CFrame.new(0, 0.20, -0.40),
		build = function(c, p)
			c:box(Vector3.new(1.60, 0.90, 0.60), CFrame.new(0, -0.40, 0), p.base) -- lower bout
			c:box(Vector3.new(1.10, 0.40, 0.56), CFrame.new(0, 0.18, 0), p.dark) -- waist
			c:box(Vector3.new(1.34, 0.76, 0.60), CFrame.new(0, 0.70, 0), p.base) -- upper bout
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.06, 0.40, 0.04), CFrame.new(0.40 * s, -0.30, 0.31), INK) -- f-holes
				c:box(Vector3.new(0.03, 0.50, 0.03), CFrame.new(0.08 * s, -0.55, 0.32), GOLD, METAL) -- strings
				c:box(Vector3.new(0.40, 0.06, 0.06), CFrame.new(0, 1.72 + s * 0.08, 0), GOLD, METAL) -- pegs
				c:box(Vector3.new(0.30, 0.20, 0.10), CFrame.new(0.16 * s, 1.10, 0.12) * CFrame.Angles(0, 0, 0.4 * s), CRIMSON) -- velvet bow
			end
			c:box(Vector3.new(0.50, 0.14, 0.10), CFrame.new(0, -0.30, 0.33), p.pale) -- bridge
			c:box(Vector3.new(0.30, 0.30, 0.06), CFrame.new(0, -0.70, 0.32), INK) -- tailpiece
			c:box(Vector3.new(0.24, 0.70, 0.22), CFrame.new(0, 1.40, 0), p.dark) -- neck
			c:box(Vector3.new(0.28, 0.30, 0.30), CFrame.new(0, 1.82, -0.04), p.base) -- scroll
			c:rod(Vector3.new(0, -0.85, 0), Vector3.new(0, -1.15, 0), 0.05, GOLD, METAL, false) -- endpin
			c:ball(Vector3.new(0.14, 0.14, 0.14), CFrame.new(0, -1.18, 0), GOLD, METAL)
			face(c, 0.72, 0.30, 0.32, 0.13)
			blush(c, 0.46, 0.50, 0.31)
			c:rod(Vector3.new(0.95, -0.95, 0.15), Vector3.new(0.70, 1.10, 0.15), 0.035, p.deep, nil, false) -- the bow
			c:box(Vector3.new(0.12, 0.20, 0.12), CFrame.new(0.93, -0.80, 0.15), GOLD, METAL)
		end,
	}

	-- A buttoned Chesterfield sofa with rolled arms; the face is on its backrest.
	S.rr_t_chesterfield = {
		label = "Chesterfield",
		set = "royal_reserve",
		tint = C3(110, 40, 180),
		head = CFrame.new(0, 1.30, -0.40),
		neck = CFrame.new(0, -0.40, 0.70),
		back = CFrame.new(0, 0.40, -0.70),
		build = function(c, p)
			c:box(Vector3.new(2.10, 0.50, 1.30), CFrame.new(0, -0.44, 0), p.base) -- seat base
			c:box(Vector3.new(1.60, 0.24, 1.00), CFrame.new(0, -0.07, 0.12), p.light) -- seat cushion
			c:box(Vector3.new(2.10, 1.00, 0.44), CFrame.new(0, 0.36, -0.44), p.base) -- backrest
			c:cyl(Vector3.new(2.10, 0.46, 0.46), CFrame.new(0, 0.86, -0.44), p.base) -- rolled top
			for _, s in ipairs(SIDES) do
				c:cyl(Vector3.new(1.34, 0.56, 0.56), CFrame.new(0.92 * s, 0.06, 0) * FRONT, p.base) -- rolled arms
				c:cyl(Vector3.new(0.06, 0.40, 0.40), CFrame.new(0.92 * s, 0.06, 0.68) * FRONT, GOLD, METAL)
				c:box(Vector3.new(0.12, 0.12, 0.06), CFrame.new(0.72 * s, 0.66, -0.21), p.deep) -- buttons
				c:box(Vector3.new(0.50, 0.50, 0.18), CFrame.new(0.76 * s, 0.26, -0.08) * CFrame.Angles(-0.2, 0, 0.4 * s), p.pale) -- cushions
				for _, t in ipairs(SIDES) do
					c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(0.90 * s, -0.78, 0.50 * t), GOLD, METAL)
				end
			end
			face(c, 0.42, -0.22, 0.30, 0.15)
			jewel(c, CFrame.new(0, 0.86, -0.20), 0.18, RUBY)
		end,
	}

	-- A palace sentry: scarlet coat, tall bearskin, gold epaulettes.
	S.rr_t_sentry = {
		label = "Palace Sentry",
		set = "royal_reserve",
		tint = C3(236, 40, 40),
		scale = 1.2,
		head = CFrame.new(0, 2.00, 0),
		neck = CFrame.new(0, -0.30, 0.72),
		back = CFrame.new(0, 0.10, -0.72),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(1.60, 1.30, 1.30),
				eyeY = 0.18, eyeSize = Vector3.new(0.40, 0.48, 0.22), eyeSpread = 0.34,
				mouthY = -0.14, mouthSize = Vector3.new(0.26, 0.10, 0.12),
				legSize = Vector3.new(0.44, 0.50, 0.50), legX = 0.38, legY = -0.80, legZ = { 0.05 }, legColor = VELVET,
				tail = false,
			})
			c:box(Vector3.new(1.30, 1.00, 1.20), CFrame.new(0, 1.20, -0.02), VELVET) -- bearskin
			c:box(Vector3.new(1.04, 0.20, 0.96), CFrame.new(0, 1.78, -0.02), VELVET)
			c:box(Vector3.new(0.90, 0.06, 0.06), CFrame.new(0, -0.30, 0.67), GOLD, METAL) -- chinstrap
			c:box(Vector3.new(1.64, 0.16, 1.34), CFrame.new(0, -0.45, 0), WHITE) -- belt
			c:box(Vector3.new(0.22, 0.18, 0.06), CFrame.new(0, -0.45, 0.68), GOLD, METAL)
			c:box(Vector3.new(0.12, 0.60, 0.20), CFrame.new(-0.68, 1.30, 0.10), p.light) -- plume
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.06, 0.92, 0.06), CFrame.new(0.62 * s, 0.20, 0.67), GOLD, METAL) -- chinstrap sides
				c:box(Vector3.new(0.40, 0.12, 0.50), CFrame.new(0.82 * s, 0.66, 0), GOLD, METAL) -- epaulettes
				c:box(Vector3.new(0.30, 0.80, 0.40), CFrame.new(0.95 * s, 0.05, 0), p.base) -- arms
				c:box(Vector3.new(0.30, 0.24, 0.40), CFrame.new(0.95 * s, -0.45, 0), WHITE) -- gloves
			end
		end,
	}

	-- A court jester: three-pointed belled cap, zig-zag collar, curly shoes.
	S.rr_t_jester = {
		label = "Court Jester",
		set = "royal_reserve",
		tint = C3(250, 220, 50),
		head = CFrame.new(0, 1.80, 0),
		neck = CFrame.new(0, -0.40, 0.90),
		back = CFrame.new(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = Vector3.new(1.80, 1.60, 1.60),
				legSize = Vector3.new(0.36, 0.26, 0.56), legX = 0.46, legY = -0.80, legZ = { 0.10 }, legColor = p.dark,
				tail = false,
			})
			c:box(Vector3.new(1.50, 0.26, 1.40), CFrame.new(0, 0.98, 0), p.dark) -- cap band
			c:rod(Vector3.new(-0.45, 1.08, 0), Vector3.new(-1.15, 1.55, 0), 0.13, p.base, nil, false)
			c:rod(Vector3.new(0.45, 1.08, 0), Vector3.new(1.15, 1.55, 0), 0.13, p.dark, nil, false)
			c:rod(Vector3.new(0, 1.10, -0.10), Vector3.new(0, 1.75, -0.45), 0.13, p.light, nil, false)
			for _, v in ipairs({ Vector3.new(-1.15, 1.55, 0), Vector3.new(1.15, 1.55, 0), Vector3.new(0, 1.75, -0.45) }) do
				c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(v), GOLD, METAL) -- bells
			end
			for _, s in ipairs(SIDES) do
				c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.46 * s, -0.76, 0.42), GOLD, METAL) -- shoe bells
			end
			for i, x in ipairs({ -0.54, -0.18, 0.18, 0.54 }) do
				c:box(Vector3.new(0.30, 0.30, 0.10), CFrame.new(x, -0.55, 0.84) * DIAMOND, i % 2 == 0 and p.dark or p.light) -- collar
			end
			blush(c, 0.58, -0.12, 0.82)
		end,
	}

	-- A powdered wig with a small face peeping out of the curls.
	S.rr_t_wig = {
		label = "Powdered Wig",
		set = "royal_reserve",
		tint = C3(160, 200, 255),
		head = CFrame.new(0, 1.60, 0),
		neck = CFrame.new(0, -0.62, 0.70),
		back = CFrame.new(0, 0.30, -0.80),
		build = function(c, p)
			c:box(Vector3.new(1.30, 1.30, 1.20), CFrame.new(0, -0.05, 0), p.pale)
			for _, s in ipairs(SIDES) do
				for i, y in ipairs({ 0.42, 0.00, -0.42 }) do
					c:cyl(Vector3.new(1.20, 0.46, 0.46), CFrame.new(0.86 * s, y, -0.02) * FRONT, i == 2 and p.light or p.base) -- side curls
				end
				c:box(Vector3.new(0.36, 0.26, 0.14), CFrame.new(0.20 * s, 0.30, -0.82) * CFrame.Angles(0, 0, 0.4 * s), CRIMSON) -- queue bow
				c:box(Vector3.new(0.40, 0.20, 0.56), CFrame.new(0.36 * s, -0.80, 0.12), VELVET) -- buckled shoes
				c:box(Vector3.new(0.18, 0.12, 0.06), CFrame.new(0.36 * s, -0.78, 0.41), GOLD, METAL)
			end
			c:box(Vector3.new(1.50, 0.62, 1.30), CFrame.new(0, 0.86, -0.04), p.base) -- pouf
			c:cyl(Vector3.new(1.50, 0.50, 0.50), CFrame.new(0, 1.18, 0.10), p.light) -- top roll
			c:box(Vector3.new(0.34, 0.70, 0.34), CFrame.new(0, -0.10, -0.76), p.base) -- queue
			face(c, -0.02, 0.60, 0.26, 0.13)
			blush(c, 0.40, -0.24, 0.61)
			c:box(Vector3.new(0.10, 0.10, 0.05), CFrame.new(0.32, -0.40, 0.61), INK) -- beauty mark
			c:rod(Vector3.new(-0.30, 0.86, 0.70), Vector3.new(-0.60, 1.30, 0.45), 0.035, GOLD, METAL, false) -- hairpin
			jewel(c, CFrame.new(-0.62, 1.32, 0.46), 0.20, p.glow)
		end,
	}

	-- A hotel bellhop's luggage cart: brass arch, plush deck, a suitcase with a face.
	S.rr_t_bellhop = {
		label = "Bellhop Cart",
		set = "royal_reserve",
		tint = C3(140, 50, 110),
		head = CFrame.new(0, 1.70, 0),
		neck = CFrame.new(0, -0.50, 0.76),
		back = CFrame.new(0, 0.10, -0.76),
		build = function(c, p)
			c:box(Vector3.new(2.00, 0.16, 1.30), CFrame.new(0, -0.68, 0), CRIMSON) -- carpeted deck
			c:box(Vector3.new(2.06, 0.08, 1.36), CFrame.new(0, -0.78, 0), GOLD, METAL)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:cyl(Vector3.new(0.12, 0.30, 0.30), CFrame.new(0.82 * s, -0.94, 0.50 * t), INK) -- casters
				end
				c:rod(Vector3.new(0.96 * s, -0.66, -0.40), Vector3.new(0.96 * s, 1.00, -0.40), 0.06, GOLD, METAL, false)
				c:rod(Vector3.new(0.96 * s, 1.00, -0.40), Vector3.new(0, 1.36, -0.40), 0.06, GOLD, METAL, false)
				c:box(Vector3.new(0.10, 0.98, 0.94), CFrame.new(0.48 * s, -0.12, 0.10), p.deep) -- straps
			end
			c:ball(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0, 1.46, -0.40), GOLD, METAL)
			jewel(c, CFrame.new(0, 1.46, -0.24), 0.16, RUBY)
			c:box(Vector3.new(1.50, 0.96, 0.90), CFrame.new(0, -0.12, 0.10), p.base) -- the big case
			c:box(Vector3.new(1.10, 0.50, 0.72), CFrame.new(-0.05, 0.62, 0.02), p.dark) -- small case
			c:box(Vector3.new(0.36, 0.10, 0.10), CFrame.new(-0.05, 0.92, 0.02), GOLD, METAL) -- handle
			face(c, -0.08, 0.55, 0.22, 0.13)
			c:box(Vector3.new(0.26, 0.20, 0.04), CFrame.new(0.40, 0.60, 0.40) * CFrame.Angles(0, 0, 0.3), p.pale) -- luggage tag
		end,
	}

	-- A wicker picnic hamper, its lid flaps up like ears, lunch peeking out.
	S.rr_t_hamper = {
		label = "Picnic Hamper",
		set = "royal_reserve",
		tint = C3(230, 190, 110),
		head = CFrame.new(0, 1.30, 0),
		neck = CFrame.new(0, -0.50, 0.76),
		back = CFrame.new(0, 0.10, -0.76),
		build = function(c, p)
			c:box(Vector3.new(1.90, 1.20, 1.40), CFrame.new(0, -0.28, 0), p.base)
			for _, y in ipairs({ -0.66, 0.10 }) do
				c:box(Vector3.new(1.94, 0.10, 1.44), CFrame.new(0, y, 0), p.dark) -- weave bands
			end
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.96, 0.12, 1.44), CFrame.new(0.43 * s, 0.53, 0) * CFrame.Angles(0, 0, 0.45 * s), p.dark) -- lid flaps
				c:box(Vector3.new(0.16, 0.60, 0.04), CFrame.new(0.62 * s, -0.10, 0.71), p.deep) -- straps
				c:box(Vector3.new(0.20, 0.14, 0.06), CFrame.new(0.62 * s, -0.22, 0.73), GOLD, METAL) -- buckles
				for _, t in ipairs(SIDES) do
					c:box(Vector3.new(0.24, 0.12, 0.24), CFrame.new(0.70 * s, -0.94, 0.50 * t), p.deep)
				end
			end
			c:box(Vector3.new(0.20, 0.80, 0.20), CFrame.new(-0.20, 0.55, -0.20) * CFrame.Angles(0, 0, 0.3), C3(222, 170, 100)) -- baguette
			c:box(Vector3.new(0.50, 0.30, 0.50), CFrame.new(0.20, 0.42, 0.15), WHITE) -- napkin
			c:box(Vector3.new(0.26, 0.32, 0.26), CFrame.new(0.32, 0.43, 0.27), RUBY)
			face(c, -0.22, 0.70, 0.30, 0.14)
		end,
	}

	-- A striped tourney pavilion: peaked roof, scalloped valance, a pennant.
	S.rr_t_pavilion = {
		label = "Tourney Pavilion",
		set = "royal_reserve",
		tint = C3(230, 60, 100),
		scale = 1.15,
		head = CFrame.new(0, 1.90, 0),
		neck = CFrame.new(0, -0.50, 0.96),
		back = CFrame.new(0, 0.00, -0.96),
		build = function(c, p)
			c:box(Vector3.new(1.90, 1.20, 1.90), CFrame.new(0, -0.34, 0), p.base)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.34, 1.20, 1.94), CFrame.new(0.66 * s, -0.34, 0), p.pale) -- stripes
				c:box(Vector3.new(0.08, 0.14, 0.04), CFrame.new(0.28 * s, -0.62, 0.97), GOLD, METAL) -- tie-backs
				c:box(Vector3.new(0.04, 0.40, 0.32), CFrame.new(0.97 * s, -0.30, 0), GOLD, METAL) -- side shields
			end
			c:cone(Vector3.new(2.30, 1.10, 2.30), CFrame.new(0, 0.81, 0), p.dark) -- roof
			for _, x in ipairs({ -0.66, 0, 0.66 }) do
				c:box(Vector3.new(0.40, 0.40, 0.06), CFrame.new(x, 0.26, 1.00) * DIAMOND, p.light) -- valance
			end
			c:rod(Vector3.new(0, 1.30, 0), Vector3.new(0, 1.70, 0), 0.05, GOLD, METAL, false)
			c:box(Vector3.new(0.50, 0.28, 0.04), CFrame.new(0.28, 1.58, 0), p.glow) -- pennant
			c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(0, 1.76, 0), GOLD, METAL)
			face(c, -0.12, 0.95, 0.30, 0.14)
			c:box(Vector3.new(0.50, 0.40, 0.04), CFrame.new(0, -0.74, 0.96), VELVET) -- doorway
		end,
	}

	-- A gilt steam locomotive: the face on the smokebox door, a gold-lipped chimney.
	S.rr_t_locomotive = {
		label = "Gilt Locomotive",
		set = "royal_reserve",
		tint = C3(30, 60, 140),
		scale = 1.2,
		head = CFrame.new(0, 1.30, -0.80),
		neck = CFrame.new(0, -0.50, 1.40),
		back = CFrame.new(0, 0.40, -1.40),
		build = function(c, p)
			c:cyl(Vector3.new(1.70, 1.00, 1.00), CFrame.new(0, 0, 0.30) * FRONT, p.base) -- boiler
			c:cyl(Vector3.new(0.30, 1.06, 1.06), CFrame.new(0, 0, 1.20) * FRONT, p.dark) -- smokebox
			for _, z in ipairs({ 0.00, 0.70 }) do
				c:cyl(Vector3.new(0.08, 1.04, 1.04), CFrame.new(0, 0, z) * FRONT, GOLD, METAL)
			end
			c:cyl(Vector3.new(0.50, 0.36, 0.36), CFrame.new(0, 0.70, 0.86) * UP, p.dark) -- chimney
			c:cyl(Vector3.new(0.08, 0.46, 0.46), CFrame.new(0, 0.96, 0.86) * UP, GOLD, METAL)
			c:ball(Vector3.new(0.40, 0.40, 0.40), CFrame.new(0, 0.50, 0.10), GOLD, METAL) -- steam dome
			c:box(Vector3.new(1.30, 1.30, 0.90), CFrame.new(0, 0.30, -0.90), p.base) -- cab
			c:box(Vector3.new(1.50, 0.12, 1.10), CFrame.new(0, 1.00, -0.90), p.dark)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.04, 0.40, 0.46), CFrame.new(0.66 * s, 0.56, -0.90), p.pale) -- cab windows
				for _, z in ipairs({ 0.70, -0.20 }) do
					c:cyl(Vector3.new(0.14, 0.76, 0.76), CFrame.new(0.52 * s, -0.56, z), p.deep) -- wheels
				end
			end
			c:box(Vector3.new(1.10, 0.14, 0.10), CFrame.new(0, -0.52, 1.36), GOLD, METAL) -- buffer beam
			c:wedge(Vector3.new(1.00, 0.30, 0.40), CFrame.new(0, -0.80, 1.40) * CFrame.Angles(0, math.pi, 0), GOLD, METAL) -- cowcatcher
			c:eyes(0.12, 1.39, 0.22, 0.12)
			c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0, -0.12, 1.38), GOLD, METAL) -- door handle nose
			c:box(Vector3.new(0.20, 0.06, 0.06), CFrame.new(0, -0.30, 1.37), INK)
			c:ball(Vector3.new(0.36, 0.36, 0.36), CFrame.new(0, 1.20, 0.86), BUBBLE) -- steam
			c:ball(Vector3.new(0.28, 0.28, 0.28), CFrame.new(0.10, 1.46, 0.70), BUBBLE)
		end,
	}

	-- ===================================================================
	-- MYTHIC: spectacular, with glowing jewels.
	-- ===================================================================

	-- A velvet rope come alive between two brass posts, on its own red carpet.
	S.rr_t_stanchion = {
		label = "Gala Stanchion",
		set = "royal_reserve",
		tint = C3(190, 16, 60),
		head = CFrame.new(0, 0.80, 0.10),
		neck = CFrame.new(0, -0.50, 0.56),
		back = CFrame.new(0, 0.20, -0.56),
		build = function(c, p)
			c:box(Vector3.new(2.50, 0.06, 1.00), CFrame.new(0, -0.97, 0), p.dark) -- the red carpet
			for _, s in ipairs(SIDES) do
				c:cyl(Vector3.new(0.12, 0.60, 0.60), CFrame.new(1.00 * s, -0.88, 0) * UP, GOLD, METAL) -- post foot
				c:rod(Vector3.new(1.00 * s, -0.84, 0), Vector3.new(1.00 * s, 0.40, 0), 0.07, GOLD, METAL, false)
				c:ball(Vector3.new(0.30, 0.30, 0.30), CFrame.new(1.00 * s, 0.52, 0), GOLD, METAL)
				jewel(c, CFrame.new(1.00 * s, 0.52, 0.16), 0.16, p.glow)
				c:box(Vector3.new(0.14, 0.16, 0.20), CFrame.new(0.88 * s, 0.38, 0), GOLD, METAL) -- rope clip
				c:rod(Vector3.new(0.86 * s, 0.36, 0), Vector3.new(0.50 * s, 0.06, 0.04), 0.13, p.base, nil, false) -- sagging rope
			end
			c:box(Vector3.new(1.00, 0.86, 0.80), CFrame.new(0, -0.08, 0.06), p.base)
			c:box(Vector3.new(0.84, 0.84, 0.76), CFrame.new(0, -0.08, 0.06) * DIAMOND, p.base)
			for _, x in ipairs({ -0.30, 0, 0.30 }) do
				c:box(Vector3.new(0.12, 0.30, 0.12), CFrame.new(x, -0.70, 0.30), GOLD, METAL) -- gold fringe
			end
			face(c, -0.06, 0.46, 0.22, 0.12)
			blush(c, 0.34, -0.22, 0.47)
			c:star(Vector3.new(-0.60, 0.95, 0.20), 0.36, p.glow)
			c:star(Vector3.new(0.62, 1.05, -0.10), 0.28, p.glow)
		end,
	}

	-- A spiral topiary clipped in tiers, each turned a little further, in a gold urn.
	S.rr_t_topiary = {
		label = "Spiral Topiary",
		set = "royal_reserve",
		tint = C3(60, 190, 70),
		scale = 1.15,
		head = CFrame.new(0, 1.90, 0),
		neck = CFrame.new(0, -0.40, 0.80),
		back = CFrame.new(0, 0.10, -0.80),
		build = function(c, p)
			c:cyl(Vector3.new(0.18, 0.80, 0.80), CFrame.new(0, -1.00, 0) * UP, GOLD, METAL) -- urn foot
			c:box(Vector3.new(1.20, 0.50, 1.20), CFrame.new(0, -0.68, 0), GOLD, METAL)
			c:box(Vector3.new(1.46, 0.14, 1.46), CFrame.new(0, -0.38, 0), GOLD_DK, METAL) -- rim
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.24, 0.30, 0.10), CFrame.new(0.72 * s, -0.64, 0), GOLD, METAL) -- handles
			end
			c:box(Vector3.new(1.50, 0.62, 1.50), CFrame.new(0, 0.00, 0), p.base)
			c:box(Vector3.new(1.54, 0.08, 1.54), CFrame.new(0, -0.27, 0), GOLD, METAL) -- gold ribbon
			c:box(Vector3.new(1.16, 0.46, 1.16), CFrame.new(0, 0.52, 0) * CFrame.Angles(0, 0.35, 0), p.light)
			c:box(Vector3.new(0.84, 0.38, 0.84), CFrame.new(0, 0.92, 0) * CFrame.Angles(0, 0.70, 0), p.base)
			c:box(Vector3.new(0.54, 0.30, 0.54), CFrame.new(0, 1.24, 0) * CFrame.Angles(0, 1.05, 0), p.light)
			face(c, 0.04, 0.75, 0.30, 0.13)
			for _, v in ipairs({ { -0.62, 0.20, 0.76 }, { 0.62, 0.20, 0.76 }, { -0.62, -0.16, 0.76 }, { 0.62, -0.16, 0.76 }, { 0.76, 0.05, 0.30 }, { -0.76, 0.05, -0.30 } }) do
				c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(v[1], v[2], v[3]), p.glow, NEON) -- roses
			end
			c:star(Vector3.new(0, 1.58, 0), 0.40, p.glow)
			c:star(Vector3.new(-0.95, 0.70, 0.20), 0.26, p.glow)
			c:star(Vector3.new(0.95, 0.95, -0.20), 0.22, p.glow)
		end,
	}


	-- A gilt-framed portrait on an easel; the painted noble's eyes follow you.
	S.rr_t_portrait = {
		label = "Gilt Portrait",
		set = "royal_reserve",
		tint = C3(70, 40, 130),
		scale = 1.15,
		head = CFrame.new(0, 1.90, 0),
		neck = CFrame.new(0, -0.80, 0.30),
		back = CFrame.new(0, 0.20, -0.40),
		build = function(c, p)
			local y0 = 0.30
			c:box(Vector3.new(1.60, 1.80, 0.12), CFrame.new(0, y0, 0), p.base) -- canvas
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(1.96, 0.20, 0.24), CFrame.new(0, y0 + 0.99 * s, 0), GOLD, METAL)
				c:box(Vector3.new(0.20, 1.80, 0.24), CFrame.new(0.89 * s, y0, 0), GOLD, METAL)
				for _, t in ipairs(SIDES) do
					jewel(c, CFrame.new(0.89 * s, y0 + 0.99 * t, 0.13), 0.18, p.glow)
				end
				c:rod(Vector3.new(0.50 * s, -0.84, 0.10), Vector3.new(0.70 * s, -1.05, 0.30), 0.06, WOOD, nil, false) -- easel legs
			end
			c:cone(Vector3.new(0.60, 0.36, 0.20), CFrame.new(0, y0 + 1.27, 0), GOLD, METAL) -- crest
			jewel(c, CFrame.new(0, y0 + 1.22, 0.11), 0.14, RUBY)
			c:box(Vector3.new(1.10, 0.46, 0.04), CFrame.new(0, y0 - 0.62, 0.07), p.dark) -- the sitter's shoulders
			c:box(Vector3.new(0.84, 0.84, 0.04), CFrame.new(0, y0 + 0.05, 0.07), p.pale) -- and face
			c:box(Vector3.new(0.70, 0.12, 0.04), CFrame.new(0, y0 - 0.38, 0.08), WHITE) -- lace collar
			face(c, y0 + 0.10, 0.09, 0.18, 0.11)
			blush(c, 0.26, y0 - 0.08, 0.095)
			c:rod(Vector3.new(0, 0.40, -0.10), Vector3.new(0, -1.05, -0.60), 0.06, WOOD, nil, false)
			c:box(Vector3.new(1.40, 0.10, 0.30), CFrame.new(0, -0.84, 0.10), WOOD) -- easel ledge
		end,
	}

	-- ===================================================================
	-- DIVINE: radiant, floating, haloed.
	-- ===================================================================

	-- A laurel wreath round a radiant medallion face, a ribbon bow below.
	S.rr_t_wreath = {
		label = "Laurel Wreath",
		set = "royal_reserve",
		tint = C3(180, 220, 60),
		scale = 1.1,
		head = CFrame.new(0, 1.50, 0),
		neck = CFrame.new(0, -0.80, 0.30),
		back = CFrame.new(0, 0.20, -0.30),
		build = function(c, p)
			local at = CFrame.new(0, 0.20, 0)
			for i = 0, 11 do
				local a = math.rad(30 + i * 300 / 11)
				c:box(Vector3.new(0.22, 0.46, 0.18), at * CFrame.Angles(0, 0, a) * CFrame.new(0, 0.92, 0) * CFrame.Angles(0, 0, 0.5), (i % 2 == 0) and p.base or p.light)
			end
			for _, d in ipairs({ 75, 150, 210, 285 }) do
				c:ball(Vector3.new(0.14, 0.14, 0.14), at * CFrame.Angles(0, 0, math.rad(d)) * CFrame.new(0, 0.74, 0.06), GOLD, METAL) -- berries
			end
			c:cyl(Vector3.new(0.10, 1.20, 1.20), at * CFrame.new(0, 0, -0.02) * FRONT, GOLD, METAL)
			c:cyl(Vector3.new(0.14, 1.10, 1.10), at * FRONT, p.pale)
			face(c, 0.26, 0.07, 0.20, 0.12)
			blush(c, 0.30, 0.08, 0.08)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.40, 0.26, 0.10), CFrame.new(0.20 * s, -0.72, 0.06) * CFrame.Angles(0, 0, 0.4 * s), p.deep) -- bow loops
				c:box(Vector3.new(0.14, 0.50, 0.06), CFrame.new(0.16 * s, -1.00, 0.04) * CFrame.Angles(0, 0, 0.25 * s), p.deep) -- tails
			end
			c:box(Vector3.new(0.16, 0.16, 0.12), CFrame.new(0, -0.72, 0.08), p.deep)
			jewel(c, CFrame.new(0, -0.72, 0.14), 0.12, RUBY)
			c:star(Vector3.new(0, 1.24, 0), 0.40, p.glow)
			c:star(Vector3.new(-1.05, 0.90, 0), 0.24, p.glow)
			c:star(Vector3.new(1.05, -0.40, 0), 0.24, p.glow)
		end,
	}

	-- A jewelled sceptre: a knop with the face, a great gem held in gold claws.
	S.rr_t_scepter = {
		label = "Jewelled Scepter",
		set = "royal_reserve",
		tint = C3(150, 70, 230),
		scale = 1.25,
		head = CFrame.new(0, 2.00, 0),
		neck = CFrame.new(0, -0.30, 0.50),
		back = CFrame.new(0, 0.20, -0.50),
		build = function(c, p)
			c:box(Vector3.new(0.96, 0.90, 0.90), CFrame.new(0, 0.20, 0), p.base) -- the knop
			for _, y in ipairs({ -0.27, 0.67 }) do
				c:box(Vector3.new(1.04, 0.10, 0.98), CFrame.new(0, y, 0), GOLD, METAL)
			end
			face(c, 0.24, 0.45, 0.22, 0.12)
			blush(c, 0.32, 0.04, 0.46)
			for i = 0, 3 do
				local arm = CFrame.Angles(0, i * math.pi / 2, 0)
				c:box(Vector3.new(0.10, 0.50, 0.10), arm * CFrame.new(0, 0.94, 0.24) * CFrame.Angles(0.45, 0, 0), GOLD, METAL) -- claws
			end
			c:cone(Vector3.new(0.58, 0.44, 0.58), CFrame.new(0, 1.40, 0) * CFrame.Angles(0, math.pi / 4, 0), p.glow, NEON)
			c:cone(Vector3.new(0.58, 0.30, 0.58), CFrame.new(0, 1.03, 0) * CFrame.Angles(math.pi, math.pi / 4, 0), p.glow, NEON)
			c:star(Vector3.new(0, 1.82, 0), 0.40, WHITE)
			c:rod(Vector3.new(0, -0.30, 0), Vector3.new(0, -0.85, 0), 0.10, GOLD, METAL, false) -- shaft
			for _, y in ipairs({ -0.45, -0.70 }) do
				c:cyl(Vector3.new(0.08, 0.34, 0.34), CFrame.new(0, y, 0) * UP, p.dark, METAL)
			end
			c:ball(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0, -0.92, 0), GOLD, METAL)
			for i = 0, 5 do
				local a = i * math.pi / 3 + math.pi / 6
				jewel(c, CFrame.new(math.cos(a) * 1.05, 0.20 + math.sin(a * 2) * 0.10, math.sin(a) * 1.05), 0.16, JEWELS[i % 3 + 1])
			end
		end,
	}

	-- A heraldic fleur-de-lis bound with a jewelled gold band.
	S.rr_t_fleur = {
		label = "Fleur Emblem",
		set = "royal_reserve",
		tint = C3(40, 130, 255),
		head = CFrame.new(0, 1.70, 0),
		neck = CFrame.new(0, -0.60, 0.40),
		back = CFrame.new(0, 0.20, -0.40),
		build = function(c, p)
			c:box(Vector3.new(0.80, 1.10, 0.56), CFrame.new(0, 0.30, 0), p.base) -- centre petal
			c:cone(Vector3.new(0.80, 0.60, 0.56), CFrame.new(0, 1.15, 0), p.base)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.46, 0.90, 0.46), CFrame.new(0.62 * s, 0.30, 0) * CFrame.Angles(0, 0, -0.55 * s), p.light) -- side petal
				c:box(Vector3.new(0.40, 0.50, 0.42), CFrame.new(1.00 * s, 0.50, 0) * CFrame.Angles(0, 0, -1.6 * s), p.light) -- its curl
				c:cone(Vector3.new(0.36, 0.40, 0.36), CFrame.new(1.08 * s, 0.14, 0) * CFrame.Angles(math.pi, 0, 0), p.light)
				c:box(Vector3.new(0.30, 0.40, 0.42), CFrame.new(0.40 * s, -0.66, 0) * CFrame.Angles(0, 0, 0.5 * s), p.base) -- lower stub
			end
			c:box(Vector3.new(0.40, 0.40, 0.46), CFrame.new(0, -0.70, 0), p.base)
			c:box(Vector3.new(1.70, 0.30, 0.66), CFrame.new(0, -0.36, 0), GOLD, METAL) -- the band
			for _, x in ipairs({ -0.50, 0, 0.50 }) do
				jewel(c, CFrame.new(x, -0.36, 0.34), 0.16, p.glow)
			end
			face(c, 0.32, 0.28, 0.20, 0.12)
			blush(c, 0.28, 0.10, 0.29)
			c:star(Vector3.new(-0.90, 1.20, 0), 0.32, p.glow)
			c:star(Vector3.new(0.90, 1.25, 0), 0.28, p.glow)
		end,
	}

	-- A heraldic shield with mantling, a plumed crest and a motto scroll.
	S.rr_t_escutcheon = {
		label = "Crest Escutcheon",
		set = "royal_reserve",
		tint = C3(170, 40, 140),
		scale = 1.15,
		head = CFrame.new(0, 1.80, 0),
		neck = CFrame.new(0, -1.00, 0.30),
		back = CFrame.new(0, 0.20, -0.40),
		build = function(c, p)
			c:box(Vector3.new(1.80, 1.10, 0.20), CFrame.new(0, 0.40, -0.06), GOLD, METAL) -- gold edge
			c:box(Vector3.new(1.10, 1.10, 0.20), CFrame.new(0, -0.30, -0.06) * DIAMOND, GOLD, METAL)
			c:box(Vector3.new(1.64, 1.00, 0.30), CFrame.new(0, 0.42, 0), p.base) -- the field
			c:box(Vector3.new(0.98, 0.98, 0.30), CFrame.new(0, -0.24, 0) * DIAMOND, p.base)
			c:box(Vector3.new(1.64, 0.28, 0.04), CFrame.new(0, 0.78, 0.16), p.dark) -- the chief
			for _, x in ipairs({ -0.50, 0, 0.50 }) do
				jewel(c, CFrame.new(x, 0.78, 0.19), 0.14, p.glow)
			end
			face(c, 0.30, 0.15, 0.26, 0.13)
			blush(c, 0.42, 0.10, 0.16)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.40, 0.60, 0.12), CFrame.new(1.05 * s, 0.70, -0.10) * CFrame.Angles(0, 0, 0.5 * s), p.dark) -- mantling
				c:box(Vector3.new(0.36, 0.70, 0.12), CFrame.new(1.10 * s, 0.10, -0.10) * CFrame.Angles(0, 0, -0.3 * s), p.dark)
				c:box(Vector3.new(0.24, 0.26, 0.08), CFrame.new(1.08 * s, -1.04, 0) * CFrame.Angles(0, 0, 0.3 * s), p.deep) -- scroll ends
				c:star(Vector3.new(1.15 * s, -0.55, 0), 0.26, p.glow)
			end
			c:cyl(Vector3.new(0.90, 0.24, 0.24), CFrame.new(0, 1.04, -0.04), p.light) -- torse
			for i = -1, 1 do
				c:box(Vector3.new(0.16, 0.56, 0.16), CFrame.new(i * 0.25, 1.36 + (i == 0 and 0.06 or 0), -0.04) * CFrame.Angles(0, 0, -i * 0.35), p.glow, NEON) -- plumes
			end
			c:box(Vector3.new(2.00, 0.26, 0.10), CFrame.new(0, -1.10, 0.08), p.pale) -- motto scroll
		end,
	}

	-- ===================================================================
	-- EXOTIC: the most spectacular -- neon, jewels, orbiting sparkle.
	-- ===================================================================



	-- A four-poster canopy bed; the face is on the footboard.
	S.rr_t_bed = {
		label = "Canopy Bed",
		set = "royal_reserve",
		tint = C3(255, 100, 150),
		head = CFrame.new(0, 1.70, 0),
		neck = CFrame.new(0, -0.40, 1.16),
		back = CFrame.new(0, 0.30, -1.16),
		build = function(c, p)
			c:box(Vector3.new(1.90, 0.26, 2.00), CFrame.new(0, -0.66, 0), p.dark) -- frame
			c:box(Vector3.new(1.80, 0.32, 1.86), CFrame.new(0, -0.37, -0.02), p.pale) -- mattress
			c:box(Vector3.new(1.86, 0.12, 1.20), CFrame.new(0, -0.17, 0.34), p.base) -- duvet
			c:box(Vector3.new(1.90, 1.20, 0.16), CFrame.new(0, 0.10, -1.02), p.base) -- headboard
			c:box(Vector3.new(1.90, 0.80, 0.16), CFrame.new(0, -0.38, 1.02), p.base) -- footboard
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.70, 0.30, 0.40), CFrame.new(0.42 * s, -0.08, -0.66), p.light) -- pillows
				c:box(Vector3.new(0.06, 0.30, 2.20), CFrame.new(1.06 * s, 1.10, 0), p.dark) -- side valances
				c:box(Vector3.new(0.30, 1.50, 0.24), CFrame.new(0.92 * s, 0.40, -0.88), p.light) -- drapes
				for _, t in ipairs(SIDES) do
					c:rod(Vector3.new(0.98 * s, -0.86, 1.02 * t), Vector3.new(0.98 * s, 1.24, 1.02 * t), 0.06, GOLD, METAL, false)
					c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.98 * s, -0.88, 1.02 * t), GOLD, METAL)
					c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.98 * s, 1.44, 1.02 * t), GOLD, METAL)
				end
			end
			c:box(Vector3.new(2.12, 0.14, 2.20), CFrame.new(0, 1.30, 0), p.base) -- canopy
			c:box(Vector3.new(2.12, 0.30, 0.06), CFrame.new(0, 1.10, 1.10), p.dark) -- front valance
			c:box(Vector3.new(0.40, 0.30, 0.06), CFrame.new(0, 1.10, 1.13), GOLD, METAL)
			jewel(c, CFrame.new(0, 1.10, 1.17), 0.16, p.glow)
			face(c, -0.30, 1.10, 0.36, 0.15)
			blush(c, 0.62, -0.48, 1.11)
			c:star(Vector3.new(-0.50, 0.45, 0.40), 0.30, p.glow)
			c:star(Vector3.new(0.55, 0.65, -0.20), 0.24, p.glow)
		end,
	}

	-- A jewel vitrine: velvet plinth with the face, a glowing gem under a glass case.
	S.rr_t_vitrine = {
		label = "Gem Vitrine",
		set = "royal_reserve",
		tint = C3(20, 110, 120),
		scale = 1.2,
		head = CFrame.new(0, 1.90, 0),
		neck = CFrame.new(0, -0.50, 0.66),
		back = CFrame.new(0, 0.00, -0.66),
		build = function(c, p)
			c:box(Vector3.new(1.50, 0.20, 1.50), CFrame.new(0, -1.00, 0), GOLD, METAL) -- plinth foot
			c:box(Vector3.new(1.20, 1.10, 1.20), CFrame.new(0, -0.35, 0), p.base) -- plinth
			c:box(Vector3.new(1.50, 0.16, 1.50), CFrame.new(0, 0.28, 0), GOLD, METAL) -- plinth cap
			face(c, -0.30, 0.60, 0.28, 0.14)
			blush(c, 0.42, -0.48, 0.61)
			c:box(Vector3.new(0.50, 0.12, 0.04), CFrame.new(0, -0.78, 0.61), GOLD, METAL) -- plaque
			c:box(Vector3.new(0.80, 0.18, 0.80), CFrame.new(0, 0.45, 0), p.dark) -- velvet cushion
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(Vector3.new(0.08, 0.16, 0.08), CFrame.new(0.40 * s, 0.38, 0.40 * t), GOLD, METAL) -- tassels
					c:rod(Vector3.new(0.62 * s, 0.36, 0.62 * t), Vector3.new(0.62 * s, 1.36, 0.62 * t), 0.04, GOLD, METAL, false) -- case frame
				end
			end
			c:cone(Vector3.new(0.56, 0.40, 0.56), CFrame.new(0, 1.00, 0) * CFrame.Angles(0, math.pi / 4, 0), p.glow, NEON) -- the gem
			c:cone(Vector3.new(0.56, 0.26, 0.56), CFrame.new(0, 0.67, 0) * CFrame.Angles(math.pi, math.pi / 4, 0), p.glow, NEON)
			local glass = c:box(Vector3.new(1.24, 1.00, 1.24), CFrame.new(0, 0.86, 0), p.pale, GLASS)
			glass.Transparency = 0.6
			c:box(Vector3.new(1.34, 0.10, 1.34), CFrame.new(0, 1.40, 0), GOLD, METAL) -- lid
			c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(0, 1.52, 0), GOLD, METAL)
			c:star(Vector3.new(0, 1.74, 0), 0.30, p.glow)
		end,
	}


	-- A bird of paradise mid-dance: iridescent breast shield, wire plumes, streamers.
	S.rr_t_paradise = {
		label = "Paradise Dancer",
		set = "royal_reserve",
		tint = C3(255, 210, 20),
		scale = 1.15,
		head = CFrame.new(0, 1.20, 0.10),
		neck = CFrame.new(0, -0.40, 0.86),
		back = CFrame.new(0, 0.30, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = Vector3.new(1.60, 1.60, 1.50),
				mouth = false, legs = false, tail = false, eyeY = 0.24,
				bib = { w = 1.10, h = 0.56, y = -0.40, color = p.glow },
			})
			c:cone(Vector3.new(0.24, 0.30, 0.26), CFrame.new(0, -0.02, 0.86) * CFrame.Angles(1.75, 0, 0), GOLD) -- beak
			jewel(c, CFrame.new(0, 0.66, 0.80), 0.18, p.glow)
			wings(c, p.dark, 0.24, 0.10, -0.15, 0.25)
			for _, s in ipairs(SIDES) do
				c:rod(Vector3.new(0.20 * s, 0.86, 0), Vector3.new(0.75 * s, 1.55, -0.20), 0.025, GOLD, METAL, false) -- head wires
				c:cyl(Vector3.new(0.06, 0.24, 0.24), CFrame.new(0.75 * s, 1.55, -0.20) * FRONT, p.glow, NEON)
				for i = 1, 3 do
					c:box(Vector3.new(0.36, 0.26, 1.00), CFrame.new(0.45 * s, 0.30 - i * 0.30, -0.75 - i * 0.12) * CFrame.Angles(0.6, 0, 0.1 * s * i), p.light) -- flank plumes
				end
				c:rod(Vector3.new(0.12 * s, -0.20, -0.80), Vector3.new(0.55 * s, -0.70, -1.65), 0.03, GOLD, METAL, false) -- streamers
				c:cyl(Vector3.new(0.06, 0.26, 0.26), CFrame.new(0.60 * s, -0.72, -1.70) * FRONT, p.glow, NEON)
				c:box(Vector3.new(0.24, 0.10, 0.36), CFrame.new(0.28 * s, -0.86, 0.15), p.deep) -- feet
			end
			c:star(Vector3.new(0.95, 1.05, 0.30), 0.30, p.glow)
		end,
	}


	-- A ballgown mid-waltz: tiered bell skirt, puffed sleeves, a tiara.
	S.rr_t_gown = {
		label = "Waltzing Gown",
		set = "royal_reserve",
		tint = C3(240, 60, 200),
		head = CFrame.new(0, 1.50, 0),
		neck = CFrame.new(0, 0.10, 0.50),
		back = CFrame.new(0, 0.30, -0.60),
		build = function(c, p)
			c:box(Vector3.new(1.80, 0.40, 1.80), CFrame.new(0, -0.80, 0) * CFrame.Angles(0, 0.40, 0), p.base)
			c:box(Vector3.new(1.84, 0.08, 1.84), CFrame.new(0, -1.02, 0) * CFrame.Angles(0, 0.40, 0), p.pale) -- lace hem
			c:box(Vector3.new(1.46, 0.38, 1.46), CFrame.new(0, -0.42, 0) * CFrame.Angles(0, 0.20, 0), p.light)
			c:box(Vector3.new(1.12, 0.36, 1.12), CFrame.new(0, -0.06, 0), p.base)
			c:box(Vector3.new(0.94, 0.12, 0.86), CFrame.new(0, 0.16, 0), p.dark) -- sash
			c:box(Vector3.new(0.90, 0.80, 0.80), CFrame.new(0, 0.60, 0), p.base) -- bodice
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.36, 0.26, 0.14), CFrame.new(0.18 * s, 0.16, -0.48) * CFrame.Angles(0, 0, 0.4 * s), p.dark) -- sash bow
				c:ball(Vector3.new(0.44, 0.44, 0.44), CFrame.new(0.58 * s, 0.82, 0), p.light) -- puffed sleeves
				c:box(Vector3.new(0.10, 0.22, 0.06), CFrame.new(0.20 * s, 1.14, 0.30) * DIAMOND, GOLD, METAL) -- tiara points
			end
			face(c, 0.64, 0.40, 0.20, 0.11)
			blush(c, 0.28, 0.48, 0.41)
			for i, x in ipairs({ -0.16, 0, 0.16 }) do
				c:ball(Vector3.new(0.10, 0.10, 0.10), CFrame.new(x, i == 2 and 0.26 or 0.29, 0.42), PEARL) -- pearls
			end
			c:box(Vector3.new(0.70, 0.08, 0.10), CFrame.new(0, 1.04, 0.30), GOLD, METAL) -- tiara band
			c:box(Vector3.new(0.14, 0.30, 0.06), CFrame.new(0, 1.18, 0.30) * DIAMOND, GOLD, METAL)
			jewel(c, CFrame.new(0, 1.18, 0.34), 0.12, p.glow)
			c:star(Vector3.new(-1.05, 0.30, 0.30), 0.30, p.glow)
			c:star(Vector3.new(1.05, -0.10, -0.20), 0.26, p.glow)
		end,
	}

	-- The sovereign's orb: enamel globe banded in gold and pearls, a gem on top.
	S.rr_t_globus = {
		label = "Globus",
		set = "royal_reserve",
		tint = C3(30, 70, 200),
		scale = 1.1,
		head = CFrame.new(0, 1.80, 0),
		neck = CFrame.new(0, -0.80, 0.50),
		back = CFrame.new(0, 0.10, -0.86),
		build = function(c, p)
			c:box(Vector3.new(1.60, 1.60, 1.60), CFrame.new(0, 0.05, 0), p.base)
			c:box(Vector3.new(1.20, 1.20, 1.50), CFrame.new(0, 0.05, 0) * DIAMOND, p.base)
			c:box(Vector3.new(1.70, 0.20, 1.70), CFrame.new(0, 0.05, 0), GOLD, METAL) -- equator band
			c:box(Vector3.new(0.20, 1.70, 1.70), CFrame.new(0, 0.05, 0), GOLD, METAL) -- meridian band
			face(c, 0.44, 0.80, 0.34, 0.13)
			blush(c, 0.62, 0.28, 0.81)
			for _, v in ipairs({ { 0.40, 0.05, 0.86 }, { -0.40, 0.05, 0.86 }, { 0.70, 0.05, 0.86 }, { -0.70, 0.05, 0.86 }, { 0, -0.30, 0.86 }, { 0, -0.55, 0.86 }, { 0, 0.91, 0.40 }, { 0, 0.91, -0.40 } }) do
				c:ball(Vector3.new(0.14, 0.14, 0.14), CFrame.new(v[1], v[2], v[3]), PEARL)
			end
			jewel(c, CFrame.new(0.86, 0.05, 0) * CFrame.Angles(0, math.pi / 2, 0), 0.20, RUBY)
			jewel(c, CFrame.new(-0.86, 0.05, 0) * CFrame.Angles(0, -math.pi / 2, 0), 0.20, SAPPHIRE)
			jewel(c, CFrame.new(0, 0.05, -0.86), 0.20, EMERALD)
			c:cyl(Vector3.new(0.16, 0.40, 0.40), CFrame.new(0, 0.93, 0) * UP, GOLD, METAL) -- collar
			c:rod(Vector3.new(0, 1.00, 0), Vector3.new(0, 1.24, 0), 0.06, GOLD, METAL, false)
			c:cone(Vector3.new(0.36, 0.30, 0.36), CFrame.new(0, 1.46, 0) * CFrame.Angles(0, math.pi / 4, 0), p.glow, NEON)
			c:cone(Vector3.new(0.36, 0.20, 0.36), CFrame.new(0, 1.21, 0) * CFrame.Angles(math.pi, math.pi / 4, 0), p.glow, NEON)
			c:star(Vector3.new(0, 1.78, 0), 0.34, WHITE)
			for _, v in ipairs({ { 1.15, 0.30, 0.20 }, { -1.15, 0.30, 0.20 }, { 1.00, -0.40, -0.40 }, { -1.00, -0.40, -0.40 } }) do
				c:ball(Vector3.new(0.14, 0.14, 0.14), CFrame.new(v[1], v[2], v[3]), p.glow, NEON) -- orbiting sparks
			end
		end,
	}


	-- ===================================================================
	-- More of every tier, kept apart from the other sets' concepts.
	-- ===================================================================

	-- EPIC. A painted front door wearing its brass knocker as a face, ring in mouth.
	S.rr_t_knocker = {
		label = "Door Knocker",
		set = "royal_reserve",
		tint = C3(120, 30, 70),
		head = CFrame.new(0, 1.70, 0),
		neck = CFrame.new(0, -0.50, 0.30),
		back = CFrame.new(0, 0.20, -0.30),
		build = function(c, p)
			c:box(Vector3.new(1.60, 1.90, 0.30), CFrame.new(0, 0.05, 0), p.base) -- the door
			c:cyl(Vector3.new(0.06, 1.20, 1.20), CFrame.new(0, 1.00, 0) * FRONT, p.pale) -- fanlight
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.55, 0.60, 0.04), CFrame.new(0.38 * s, -0.50, 0.16), p.dark) -- panels
			end
			c:cyl(Vector3.new(0.06, 0.90, 0.90), CFrame.new(0, 0.30, 0.18) * FRONT, GOLD, METAL) -- brass face plate
			c:eyes(0.40, 0.24, 0.18, 0.11)
			c:box(Vector3.new(0.14, 0.06, 0.04), CFrame.new(0, 0.12, 0.22), INK)
			blush(c, 0.30, 0.24, 0.22)
			-- The knocker ring, hanging from its mouth.
			local ring = { Vector3.new(0, 0.10, 0.25), Vector3.new(0.24, -0.14, 0.25), Vector3.new(0, -0.38, 0.25), Vector3.new(-0.24, -0.14, 0.25) }
			for i = 1, 4 do
				c:rod(ring[i], ring[i % 4 + 1], 0.04, GOLD, METAL, false)
			end
			c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.62, -0.05, 0.22), GOLD, METAL) -- doorknob
			c:box(Vector3.new(1.90, 0.12, 0.60), CFrame.new(0, -0.94, 0.10), p.pale) -- door step
		end,
	}

	-- EPIC. A gilded abacus: rows of beads, and one big bead in the middle with a face.
	S.rr_t_abacus = {
		label = "Gilded Abacus",
		set = "royal_reserve",
		tint = C3(255, 110, 130),
		head = CFrame.new(0, 1.30, 0),
		neck = CFrame.new(0, -0.60, 0.30),
		back = CFrame.new(0, 0.10, -0.30),
		build = function(c, p)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.20, 1.84, 0.40), CFrame.new(0.95 * s, 0.05, 0), p.dark) -- posts
				c:box(Vector3.new(0.30, 0.16, 0.40), CFrame.new(0.80 * s, -0.98, 0), GOLD, METAL) -- feet
			end
			c:box(Vector3.new(2.10, 0.20, 0.40), CFrame.new(0, 0.90, 0), GOLD, METAL)
			c:box(Vector3.new(2.10, 0.20, 0.40), CFrame.new(0, -0.80, 0), GOLD, METAL)
			for _, y in ipairs({ 0.50, 0.05, -0.40 }) do
				c:rod(Vector3.new(-0.86, y, 0), Vector3.new(0.86, y, 0), 0.03, GOLD, METAL, false)
			end
			for i, x in ipairs({ -0.60, -0.36, 0.55, -0.62, 0.40, 0.64, -0.62, 0.62 }) do
				local y = i <= 3 and 0.50 or (i <= 6 and -0.40 or 0.05)
				c:box(Vector3.new(0.24, 0.24, 0.30), CFrame.new(x, y, 0), i % 2 == 0 and p.light or p.base) -- beads
			end
			c:box(Vector3.new(0.64, 0.60, 0.50), CFrame.new(0, 0.05, 0), p.base) -- the big bead
			face(c, 0.12, 0.25, 0.15, 0.10)
		end,
	}

	-- EPIC. A silver christening rattle with a ribbon bow and a teething ring.
	S.rr_t_rattle = {
		label = "Christening Rattle",
		set = "royal_reserve",
		tint = C3(255, 190, 140),
		head = CFrame.new(0, 1.20, 0),
		neck = CFrame.new(0, -0.30, 0.30),
		back = CFrame.new(0, 0.40, -0.62),
		build = function(c, p)
			c:box(Vector3.new(1.30, 1.20, 1.20), CFrame.new(0, 0.45, 0), p.base)
			c:box(Vector3.new(1.00, 1.00, 1.16), CFrame.new(0, 0.45, 0) * DIAMOND, p.base)
			face(c, 0.50, 0.60, 0.26, 0.14)
			blush(c, 0.44, 0.30, 0.61)
			for _, s in ipairs(SIDES) do
				c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(0.72 * s, 0.45, 0), GOLD, METAL) -- bells
				c:box(Vector3.new(0.34, 0.22, 0.08), CFrame.new(0.20 * s, -0.20, 0.14) * CFrame.Angles(0, 0, 0.4 * s), p.dark) -- bow
			end
			c:box(Vector3.new(0.12, 0.12, 0.10), CFrame.new(0, -0.20, 0.16), p.dark)
			c:cyl(Vector3.new(0.14, 0.40, 0.40), CFrame.new(0, -0.20, 0) * UP, GOLD, METAL) -- collar
			c:rod(Vector3.new(0, -0.20, 0), Vector3.new(0, -0.75, 0), 0.12, p.light, nil, false) -- handle
			local ring = { Vector3.new(0, -0.75, 0), Vector3.new(0.30, -1.00, 0), Vector3.new(0, -1.25, 0), Vector3.new(-0.30, -1.00, 0) }
			for i = 1, 4 do
				c:rod(ring[i], ring[i % 4 + 1], 0.06, p.light, nil, false) -- teething ring
			end
			c:star(Vector3.new(0.75, 1.00, 0.20), 0.26, WHITE)
		end,
	}

	-- LEGENDARY. Opera glasses on a gold handle; the lenses ARE its eyes.
	S.rr_t_lorgnette = {
		label = "Lorgnette",
		set = "royal_reserve",
		tint = C3(0, 170, 120),
		head = CFrame.new(0, 1.30, 0),
		neck = CFrame.new(0, -0.20, 0.30),
		back = CFrame.new(0, 0.30, -0.30),
		build = function(c, p)
			for _, s in ipairs(SIDES) do
				c:cyl(Vector3.new(0.10, 1.10, 1.10), CFrame.new(0.55 * s, 0.40, -0.04) * FRONT, GOLD, METAL) -- gold rim
				c:cyl(Vector3.new(0.16, 1.00, 1.00), CFrame.new(0.55 * s, 0.40, 0) * FRONT, p.base) -- lens frame
				c:eye(Vector3.new(0.55 * s, 0.40, 0.10), 0.22)
				local lens = c:cyl(Vector3.new(0.04, 0.84, 0.84), CFrame.new(0.55 * s, 0.40, 0.12) * FRONT, C3(220, 240, 255), GLASS)
				lens.Transparency = 0.6
				jewel(c, CFrame.new(0.55 * s, 0.93, 0.06), 0.14, p.glow)
				c:box(Vector3.new(0.40, 0.10, 0.08), CFrame.new(0.55 * s, 1.06, 0.02) * CFrame.Angles(0, 0, -0.15 * s), p.dark) -- brows
				c:box(Vector3.new(0.26, 0.18, 0.08), CFrame.new(0.14 * s, -0.40, 0.04) * CFrame.Angles(0, 0, 0.4 * s), CRIMSON) -- bow
			end
			c:box(Vector3.new(0.30, 0.12, 0.12), CFrame.new(0, 0.55, 0), GOLD, METAL) -- bridge
			c:box(Vector3.new(0.36, 0.30, 0.20), CFrame.new(0, 0.15, 0), p.base) -- nose piece
			c:box(Vector3.new(0.16, 0.06, 0.04), CFrame.new(0, 0.12, 0.11), INK)
			c:rod(Vector3.new(0, 0.00, 0), Vector3.new(0, -0.95, 0), 0.07, GOLD, METAL, false) -- handle
			for _, y in ipairs({ -0.20, -0.62 }) do
				c:box(Vector3.new(0.20, 0.20, 0.10), CFrame.new(0, y, 0) * DIAMOND, GOLD_DK, METAL) -- filigree
			end
			c:ball(Vector3.new(0.22, 0.22, 0.22), CFrame.new(0, -1.00, 0), GOLD, METAL)
			c:cone(Vector3.new(0.22, 0.30, 0.22), CFrame.new(0, -1.24, 0) * CFrame.Angles(math.pi, 0, 0), p.glow) -- tassel
		end,
	}

	-- MYTHIC. A golden pineapple, the Georgian host's proudest ornament, on a plinth.
	S.rr_t_pineapple = {
		label = "Golden Pineapple",
		set = "royal_reserve",
		tint = C3(250, 170, 30),
		scale = 1.1,
		head = CFrame.new(0, 1.70, 0),
		neck = CFrame.new(0, -0.50, 0.72),
		back = CFrame.new(0, 0.10, -0.72),
		build = function(c, p)
			c:box(Vector3.new(1.40, 1.50, 1.30), CFrame.new(0, -0.05, 0), p.base)
			c:box(Vector3.new(1.10, 1.10, 1.26), CFrame.new(0, -0.05, 0) * DIAMOND, p.base)
			for _, s in ipairs(SIDES) do
				for _, y in ipairs({ 0.48, -0.48 }) do
					c:box(Vector3.new(0.20, 0.20, 0.06), CFrame.new(0.48 * s, y, 0.66) * DIAMOND, p.dark) -- crosshatch
					c:box(Vector3.new(0.06, 0.20, 0.20), CFrame.new(0.71 * s, y * 0.8, 0) * CFrame.Angles(math.pi / 4, 0, 0), p.dark)
				end
			end
			face(c, 0.05, 0.65, 0.28, 0.14)
			blush(c, 0.44, -0.14, 0.66)
			-- Crown of leaves, glowing.
			c:box(Vector3.new(0.22, 0.80, 0.22), CFrame.new(0, 1.10, 0), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.20, 0.64, 0.20), CFrame.new(0.25 * s, 1.00, 0) * CFrame.Angles(0, 0, -0.45 * s), p.glow, NEON)
				c:box(Vector3.new(0.18, 0.52, 0.18), CFrame.new(0.45 * s, 0.90, 0) * CFrame.Angles(0, 0, -0.90 * s), p.glow, NEON)
				c:box(Vector3.new(0.18, 0.56, 0.18), CFrame.new(0, 0.98, 0.25 * s) * CFrame.Angles(0.45 * s, 0, 0), p.glow, NEON)
			end
			c:box(Vector3.new(1.20, 0.10, 1.20), CFrame.new(0, -0.82, 0), GOLD, METAL) -- collar
			c:box(Vector3.new(1.00, 0.24, 1.00), CFrame.new(0, -0.98, 0), GOLD_DK, METAL) -- plinth
			c:star(Vector3.new(-0.90, 0.95, 0.20), 0.30, p.glow)
			c:star(Vector3.new(0.92, 0.40, -0.20), 0.24, p.glow)
		end,
	}

	-- EXOTIC. A coronation mantle: velvet drape, ermine collar and hem, a long train.
	S.rr_t_mantle = {
		label = "Ermine Mantle",
		set = "royal_reserve",
		tint = C3(120, 20, 200),
		head = CFrame.new(0, 1.40, -0.20),
		neck = CFrame.new(0, 0.00, 0.74),
		back = CFrame.new(0, 0.40, -0.70),
		build = function(c, p)
			c:box(Vector3.new(1.30, 0.70, 1.10), CFrame.new(0, 0.45, 0), p.base) -- shoulders
			c:box(Vector3.new(0.80, 0.56, 0.04), CFrame.new(0, 0.45, 0.56), p.pale) -- face panel
			c:box(Vector3.new(1.80, 1.00, 1.40), CFrame.new(0, -0.35, 0), p.base) -- the drape
			c:box(Vector3.new(1.50, 0.70, 0.20), CFrame.new(0, 0.85, -0.40), WHITE) -- standing ermine collar
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.20, 0.60, 0.80), CFrame.new(0.70 * s, 0.80, -0.10), WHITE)
				c:box(Vector3.new(0.18, 1.00, 0.06), CFrame.new(0.22 * s, -0.35, 0.71), WHITE) -- front bands
				c:cyl(Vector3.new(0.06, 0.20, 0.20), CFrame.new(0.30 * s, 0.10, 0.57) * FRONT, GOLD, METAL) -- clasp rosettes
			end
			c:box(Vector3.new(1.84, 0.16, 1.44), CFrame.new(0, -0.80, 0), WHITE) -- ermine hem
			c:box(Vector3.new(1.40, 0.12, 1.20), CFrame.new(0, -0.84, -1.10), p.dark) -- the train
			c:box(Vector3.new(1.44, 0.14, 0.14), CFrame.new(0, -0.84, -1.70), WHITE)
			for _, v in ipairs({ { -0.50, 1.00, -0.29 }, { 0.50, 1.00, -0.29 }, { 0, 0.70, -0.29 }, { -0.60, -0.80, 0.73 }, { 0.60, -0.80, 0.73 }, { 0, -0.84, -1.78 } }) do
				c:box(Vector3.new(0.08, 0.14, 0.04), CFrame.new(v[1], v[2], v[3]), INK) -- ermine tails
			end
			c:rod(Vector3.new(-0.30, 0.10, 0.59), Vector3.new(0.30, 0.10, 0.59), 0.025, GOLD, METAL, false) -- clasp chain
			jewel(c, CFrame.new(0, 0.10, 0.61), 0.14, p.glow)
			face(c, 0.48, 0.58, 0.20, 0.11)
			blush(c, 0.30, 0.34, 0.59)
			c:star(Vector3.new(-0.95, 0.90, 0.20), 0.30, p.glow)
			c:star(Vector3.new(0.95, 0.30, 0.30), 0.24, p.glow)
		end,
	}

	-- EXOTIC. A necklace of glowing jewels and pearls round a great pendant with a face.
	S.rr_t_necklace = {
		label = "Pendant Necklace",
		set = "royal_reserve",
		tint = C3(80, 240, 200),
		scale = 1.1,
		head = CFrame.new(0, 1.80, 0),
		neck = CFrame.new(0, -1.00, 0.30),
		back = CFrame.new(0, 0.40, -0.30),
		build = function(c, p)
			for i, a in ipairs({ 35, 65, 95, 125, 155, 205, 235, 265, 295, 325 }) do
				local r = math.rad(a)
				local at = CFrame.new(math.sin(r) * 1.0, 0.55 - math.cos(r) * 1.0, 0)
				if i % 2 == 0 then
					c:ball(Vector3.new(0.22, 0.22, 0.22), at, PEARL)
				else
					jewel(c, at, 0.24, p.glow)
				end
			end
			c:box(Vector3.new(0.20, 0.14, 0.14), CFrame.new(0, 1.55, 0), GOLD, METAL) -- clasp
			c:box(Vector3.new(1.04, 1.14, 0.40), CFrame.new(0, -0.35, -0.06), GOLD, METAL) -- bezel
			c:box(Vector3.new(0.90, 1.00, 0.50), CFrame.new(0, -0.35, 0), p.base) -- the pendant stone
			c:box(Vector3.new(0.80, 0.80, 0.48), CFrame.new(0, -0.35, 0) * DIAMOND, p.base)
			c:box(Vector3.new(0.30, 0.24, 0.30), CFrame.new(0, 0.26, 0), GOLD, METAL) -- bail
			c:box(Vector3.new(0.20, 0.08, 0.04), CFrame.new(-0.26, -0.02, 0.26), p.pale) -- shine
			face(c, -0.30, 0.25, 0.20, 0.12)
			blush(c, 0.30, -0.48, 0.26)
			c:ball(Vector3.new(0.24, 0.24, 0.24), CFrame.new(0, -1.00, 0), PEARL) -- pearl drop
			c:star(Vector3.new(0, 0.70, 0.10), 0.34, WHITE)
			c:star(Vector3.new(1.05, -0.60, 0), 0.26, p.glow)
		end,
	}

	-- EXOTIC. A veiltail betta: little body, enormous flowing fins edged in neon.
	S.rr_t_betta = {
		label = "Veiltail Betta",
		set = "royal_reserve",
		tint = C3(130, 60, 255),
		head = CFrame.new(0, 1.20, 0.30),
		neck = CFrame.new(0, -0.30, 0.70),
		back = CFrame.new(0, 0.80, -0.40),
		build = function(c, p)
			c:box(Vector3.new(0.90, 0.90, 1.30), CFrame.new(0, 0.30, 0), p.base)
			c:box(Vector3.new(0.86, 0.80, 0.80), CFrame.new(0, 0.30, 0) * CFrame.Angles(math.pi / 4, 0, 0), p.base)
			c:box(Vector3.new(0.10, 0.90, 1.20), CFrame.new(0, 1.00, -0.40) * CFrame.Angles(-0.4, 0, 0), p.light) -- dorsal sail
			c:box(Vector3.new(0.10, 1.00, 1.10), CFrame.new(0, -0.50, -0.40) * CFrame.Angles(0.4, 0, 0), p.light) -- trailing anal fin
			for _, a in ipairs({ -0.55, 0, 0.55 }) do
				local fan = CFrame.new(0, 0.30, -0.65) * CFrame.Angles(a, 0, 0)
				c:box(Vector3.new(0.08, 0.70, 0.90), fan * CFrame.new(0, 0, -0.45), a == 0 and p.dark or p.light) -- veil tail
				c:box(Vector3.new(0.10, 0.70, 0.08), fan * CFrame.new(0, 0, -0.92), p.glow, NEON)
			end
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.10, 0.30, 0.40), CFrame.new(0.50 * s, 0.10, 0.20) * CFrame.Angles(0, -0.4 * s, 0), p.pale) -- pectorals
				for _, z in ipairs({ 0.10, -0.30 }) do
					c:box(Vector3.new(0.04, 0.14, 0.14), CFrame.new(0.46 * s, 0.40, z) * CFrame.Angles(math.pi / 4, 0, 0), GOLD, METAL) -- gold scales
				end
			end
			c:eyes(0.40, 0.69, 0.22, 0.12)
			c:box(Vector3.new(0.24, 0.12, 0.10), CFrame.new(0, 0.12, 0.69), p.pale) -- lips
			blush(c, 0.32, 0.20, 0.66)
			c:ball(Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.25, 1.30, 0.55), BUBBLE)
			c:ball(Vector3.new(0.12, 0.12, 0.12), CFrame.new(0.12, 1.52, 0.62), BUBBLE)
			c:star(Vector3.new(-0.80, 1.20, -0.60), 0.30, p.glow)
			c:star(Vector3.new(0.80, -0.70, -0.80), 0.26, p.glow)
		end,
	}

	-- EXOTIC. An opera stage: gold proscenium, velvet curtains, a star in the spotlight.
	S.rr_t_curtain = {
		label = "Opera Curtain",
		set = "royal_reserve",
		tint = C3(220, 20, 50),
		head = CFrame.new(0, 1.70, 0),
		neck = CFrame.new(0, -0.40, 0.50),
		back = CFrame.new(0, 0.20, -0.50),
		build = function(c, p)
			c:box(Vector3.new(2.30, 0.16, 1.00), CFrame.new(0, -0.95, 0.10), p.deep) -- stage
			c:box(Vector3.new(2.34, 0.06, 0.06), CFrame.new(0, -0.88, 0.60), GOLD, METAL)
			c:box(Vector3.new(1.00, 1.60, 0.06), CFrame.new(0, -0.05, -0.10), VELVET) -- dark stage behind
			c:box(Vector3.new(2.34, 0.30, 0.40), CFrame.new(0, 1.05, 0), GOLD, METAL) -- proscenium
			c:cone(Vector3.new(0.50, 0.36, 0.30), CFrame.new(0, 1.38, 0), GOLD, METAL)
			jewel(c, CFrame.new(0, 1.30, 0.16), 0.16, p.glow)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.24, 2.00, 0.40), CFrame.new(1.05 * s, 0.00, 0), GOLD, METAL) -- columns
				c:box(Vector3.new(0.60, 1.70, 0.20), CFrame.new(0.62 * s, 0.05, 0.05), p.base) -- curtains
				c:box(Vector3.new(0.64, 0.08, 0.24), CFrame.new(0.62 * s, -0.30, 0.06), GOLD, METAL) -- tie-backs
				c:box(Vector3.new(0.10, 0.24, 0.10), CFrame.new(0.92 * s, -0.46, 0.18), GOLD, METAL) -- tassels
				c:box(Vector3.new(0.22, 0.14, 0.06), CFrame.new(0.12 * s, -0.36, 0.22) * CFrame.Angles(0, 0, 0.4 * s), GOLD, METAL) -- star's bow tie
			end
			for _, x in ipairs({ -0.70, 0, 0.70 }) do
				c:box(Vector3.new(0.50, 0.50, 0.10), CFrame.new(x, 0.82, 0.16) * DIAMOND, p.dark) -- swagged valance
			end
			c:box(Vector3.new(0.80, 0.80, 0.10), CFrame.new(0, 0.10, 0.15), p.pale) -- the star of the show
			c:eyes(0.18, 0.24, 0.18, 0.11)
			c:box(Vector3.new(0.16, 0.06, 0.04), CFrame.new(0, -0.06, 0.21), INK)
			blush(c, 0.26, 0.02, 0.21)
			c:cyl(Vector3.new(0.04, 0.90, 0.90), CFrame.new(0, -0.86, 0.15) * UP, p.glow, NEON) -- spotlight pool
			for _, x in ipairs({ -0.90, -0.30, 0.30, 0.90 }) do
				c:ball(Vector3.new(0.12, 0.12, 0.12), CFrame.new(x, -0.82, 0.54), p.glow, NEON) -- footlights
			end
			c:star(Vector3.new(-0.60, 1.30, 0.20), 0.26, WHITE)
			c:star(Vector3.new(0.62, 1.32, 0.20), 0.22, WHITE)
		end,
	}

	-- EXOTIC. A grand staircase: marble steps, a carpet runner, a gilded niche on the landing.
	S.rr_t_staircase = {
		label = "Grand Staircase",
		set = "royal_reserve",
		tint = C3(40, 200, 120),
		scale = 1.1,
		head = CFrame.new(0, 1.80, -0.70),
		neck = CFrame.new(0, -0.60, 0.92),
		back = CFrame.new(0, 0.40, -0.96),
		build = function(c, p)
			for i, v in ipairs({ { -0.85, 0.00, 1.80 }, { -0.55, -0.20, 1.40 }, { -0.25, -0.40, 1.00 }, { 0.05, -0.60, 0.60 } }) do
				c:box(Vector3.new(2.00, 0.30, v[3]), CFrame.new(0, v[1], v[2]), p.pale) -- marble steps
				c:box(Vector3.new(0.80, 0.04, v[3]), CFrame.new(0, v[1] + 0.17, v[2]), i % 2 == 0 and p.dark or p.base) -- runner
			end
			c:box(Vector3.new(1.44, 1.24, 0.20), CFrame.new(0, 0.76, -0.82), GOLD, METAL) -- niche frame
			c:box(Vector3.new(1.30, 1.10, 0.24), CFrame.new(0, 0.75, -0.78), p.base) -- the niche
			face(c, 0.78, -0.66, 0.26, 0.13)
			blush(c, 0.44, 0.60, -0.65)
			c:cone(Vector3.new(0.50, 0.36, 0.20), CFrame.new(0, 1.56, -0.82), GOLD, METAL) -- crest
			jewel(c, CFrame.new(0, 1.50, -0.70), 0.16, p.glow)
			for _, s in ipairs(SIDES) do
				local x = 0.95 * s
				c:rod(Vector3.new(x, -0.40, 0.80), Vector3.new(x, 0.55, -0.70), 0.04, GOLD, METAL, false) -- handrail
				c:rod(Vector3.new(x, -0.70, 0.80), Vector3.new(x, -0.30, 0.80), 0.07, GOLD, METAL, false) -- newel post
				c:ball(Vector3.new(0.20, 0.20, 0.20), CFrame.new(x, -0.24, 0.80), p.glow, NEON)
				c:rod(Vector3.new(x, -0.40, 0.30), Vector3.new(x, -0.08, 0.30), 0.03, GOLD, METAL, false) -- balusters
				c:rod(Vector3.new(x, -0.10, -0.20), Vector3.new(x, 0.23, -0.20), 0.03, GOLD, METAL, false)
			end
			c:star(Vector3.new(-0.70, 1.40, 0.20), 0.30, p.glow)
			c:star(Vector3.new(0.75, 1.20, 0.40), 0.24, p.glow)
		end,
	}

	return S
end
