--[[ PetBodies/LostAndFoundTop -- Lost & Found's top bodies. See tools/gen/sets/README.md.

	Epic and up: each body here is worn by exactly ONE pet in the game, so no
	two share a silhouette. The set is a treasure hunt through everyday finds,
	so the tiers climb the way its packs do:
	  Epic       the junk drawer and the beach: a sock, a jigsaw piece, a lost umbrella;
	  Legendary  a collector's shelf: a rotary phone, a cuckoo clock, a camera;
	  Mythic     the hidden chamber: a secret bookcase, a flying rug;
	  Divine     fables: a glass slipper, a golden goose, a lighthouse;
	  Exotic     the lost civilization: a jade jaguar, a desert oryx.
	Mythic and up carry small neon accents (p.glow) and floating bits.
]]
return function(K)
	local C3, block, ears, wings, spots = K.C3, K.block, K.ears, K.wings, K.spots
	local INK, WHITE, METAL, GLASS, WOOD, NEON, SLATE = K.INK, K.WHITE, K.METAL, K.GLASS, K.WOOD, K.NEON, K.SLATE
	local S = {}

	local V, CF, ANG = Vector3.new, CFrame.new, CFrame.Angles
	local PI = math.pi
	local UP = ANG(0, 0, PI / 2) -- a cylinder standing on end
	local FACING = ANG(0, PI / 2, 0) -- a cylinder facing forward
	local SIDES = { -1, 1 }

	local GOLD = C3(246, 200, 80)
	local BRASS = C3(200, 160, 80)
	local RED = C3(200, 44, 48)
	local PINK = C3(255, 150, 170)
	local PAPER = C3(240, 226, 192)
	local IVORY = C3(246, 240, 222)
	local SILVER = C3(206, 210, 220)
	local BROWN = C3(120, 84, 50)
	local LEATHER = C3(150, 104, 70)
	local ORANGE = C3(255, 150, 40)
	local LEAF = C3(70, 170, 80)
	local SAND = C3(232, 208, 150)
	local STONE = C3(150, 146, 140)
	local WATER = C3(150, 210, 240)

	-- Shared face bits: a little smile and two rosy cheeks.
	local function smile(c, y, z, w)
		c:box(V(w or 0.24, 0.07, 0.06), CF(0, y, z), INK)
	end
	local function cheeks(c, y, z, x)
		for _, s in ipairs(SIDES) do
			c:box(V(0.18, 0.10, 0.04), CF(x * s, y, z), PINK)
		end
	end

	----------------------------------------------------------------------------
	-- EPIC: the junk drawer, the attic and the beach. Charming and clean.
	----------------------------------------------------------------------------

	-- A lost striped sock that wriggled off on its own: toe for a head, a heel, a ribbed cuff.
	S.lf_t_sock = {
		label = "Runaway Sock",
		set = "lost_and_found",
		tint = C3(225, 45, 60),
		head = CF(0, 0.96, 0.60),
		neck = CF(0, 0.02, 1.02),
		back = CF(0, 0.00, -1.00),
		build = function(c, p)
			-- The toe end is the head, with a darker toe cap.
			c:round(V(1.00, 0.90, 0.86), CF(0, 0.40, 0.60), p.base)
			c:round(V(1.04, 0.30, 0.90), CF(0, 0.78, 0.58), p.dark)
			-- Striped body, curling round behind, and the heel.
			for _, s in ipairs({
				{ 0.00, -0.45, 0.40, 0.86, 0.90, 0.0, p.pale },
				{ 0.62, -0.50, -0.10, 0.80, 0.80, 0.6, p.base },
				{ 0.35, -0.52, -0.72, 0.78, 0.76, -0.3, p.pale },
				{ -0.35, -0.50, -0.78, 0.80, 0.80, 0.2, p.base },
			}) do
				c:box(V(s[4], s[5], 0.80), CF(s[1], s[2], s[3]) * ANG(0, s[6], 0), s[7])
			end
			c:round(V(0.50, 0.50, 0.44), CF(0.62, -0.50, -0.98), p.dark)
			-- The cuff, its opening and its ribbing.
			c:box(V(0.84, 1.10, 0.84), CF(-0.85, -0.35, -0.25), p.light)
			c:box(V(0.60, 0.06, 0.60), CF(-0.85, 0.21, -0.25), p.deep)
			for _, x in ipairs({ -1.05, -0.85, -0.65 }) do
				c:box(V(0.08, 0.90, 0.06), CF(x, -0.35, 0.18), p.deep)
			end
			c:eyes(0.44, 1.02, 0.24, 0.14)
			smile(c, 0.16, 1.03, 0.22)
			cheeks(c, 0.20, 1.02, 0.38)
		end,
	}

	-- A tape measure from the toolbox, its yellow tape stuck out like a tongue.
	S.lf_t_tape = {
		label = "Tape Measure",
		set = "lost_and_found",
		tint = C3(240, 90, 30),
		head = CF(0, 1.06, 0),
		neck = CF(0, -0.40, 0.96),
		back = CF(0, 0.10, -1.00),
		build = function(c, p)
			c:round(V(1.20, 1.70, 1.80), CF(0, 0.05, 0), p.base)
			for _, s in ipairs(SIDES) do
				c:cyl(V(0.06, 1.30, 1.30), CF(0.61 * s, 0.10, -0.05), p.light)
				c:cyl(V(0.08, 0.24, 0.24), CF(0.64 * s, 0.10, -0.05), SILVER, METAL)
				c:box(V(0.36, 0.24, 0.40), CF(0.35 * s, -0.86, -0.30), p.deep)
			end
			c:box(V(1.00, 0.60, 0.06), CF(0, -0.45, 0.90), p.dark)
			c:eyes(0.40, 0.92, 0.28, 0.16)
			cheeks(c, 0.18, 0.91, 0.42)
			-- The tape slot, the tape curling out along the ground, its hook and marks.
			c:box(V(0.60, 0.10, 0.06), CF(0, -0.30, 0.93), INK)
			c:box(V(0.50, 0.03, 0.56), CF(0, -0.58, 1.06) * ANG(1.0, 0, 0), C3(250, 220, 60))
			c:box(V(0.50, 0.03, 0.80), CF(0, -0.86, 1.48), C3(250, 220, 60))
			c:box(V(0.54, 0.20, 0.04), CF(0, -0.78, 1.90), SILVER, METAL)
			for _, z in ipairs({ 1.24, 1.44, 1.64 }) do
				c:box(V(0.20, 0.02, 0.03), CF(-0.14, -0.84, z), INK)
			end
			-- The lock button on top and the belt clip behind.
			c:box(V(0.30, 0.14, 0.40), CF(0, 0.94, 0.40), RED)
			c:box(V(0.80, 1.00, 0.06), CF(0, 0.10, -0.94), SILVER, METAL)
		end,
	}

	-- A sleepy mouse tucked up in a silver thimble for a bed, nightcap on.
	S.lf_t_thimble = {
		label = "Thimble Snoozer",
		set = "lost_and_found",
		tint = C3(225, 225, 235),
		head = CF(0.15, 0.96, 0.10),
		neck = CF(0, -0.50, 1.00),
		back = CF(0, 0.20, -1.20),
		build = function(c, p)
			-- The thimble on its side, its domed end, rim and dimples.
			c:cyl(V(1.50, 1.60, 1.60), CF(0, 0, -0.15) * FACING, p.light, METAL)
			c:ball(V(1.50, 1.50, 0.60), CF(0, 0, -0.90), p.light, METAL)
			c:cyl(V(0.14, 1.70, 1.70), CF(0, 0, 0.62) * FACING, p.dark, METAL)
			c:cyl(V(0.04, 1.40, 1.40), CF(0, 0, 0.66) * FACING, INK)
			for _, v in ipairs({ { -0.30, -0.50 }, { 0.20, -0.30 }, { -0.10, 0.05 }, { 0.30, 0.25 } }) do
				c:ball(V(0.12, 0.08, 0.12), CF(v[1], 0.78, v[2]), p.dark)
			end
			-- The mouse peeking out: head, round ears, sleepy eyes, pink nose.
			c:round(V(1.00, 0.80, 0.60), CF(0, -0.15, 0.74), p.base)
			for _, s in ipairs(SIDES) do
				c:cyl(V(0.08, 0.44, 0.44), CF(0.42 * s, 0.30, 0.78) * FACING, p.base)
				c:cyl(V(0.09, 0.26, 0.26), CF(0.42 * s, 0.30, 0.80) * FACING, PINK)
				c:box(V(0.28, 0.12, 0.06), CF(0.22 * s, 0.04, 1.08), p.base)
				c:round(V(0.24, 0.18, 0.24), CF(0.30 * s, -0.50, 0.98), p.pale)
			end
			c:eyes(-0.05, 1.02, 0.22, 0.12)
			c:ball(V(0.12, 0.10, 0.08), CF(0, -0.22, 1.05), PINK)
			-- A nightcap with a pom-pom, and a curly tail over the rim.
			c:cone(V(0.50, 0.70, 0.50), CF(0.20, 0.40, 0.70) * ANG(0.3, 0, -0.6), C3(120, 140, 220))
			c:ball(V(0.20, 0.20, 0.20), CF(0.52, 0.66, 0.80), WHITE)
			c:rod(V(0.60, -0.60, 0.70), V(1.00, -0.80, 0.90), 0.05, PINK, nil, false)
			c:rod(V(1.00, -0.80, 0.90), V(1.10, -0.60, 1.10), 0.05, PINK, nil, false)
		end,
	}

	-- A magnifying glass standing on its rim, eyes huge behind the lens.
	S.lf_t_lens = {
		label = "Lens Peeper",
		set = "lost_and_found",
		tint = C3(214, 170, 60),
		scale = 1.1,
		head = CF(0, 1.32, 0),
		neck = CF(0, -0.60, 0.30),
		back = CF(0, 0.30, -0.24),
		build = function(c, p)
			c:cyl(V(0.30, 2.00, 2.00), CF(0, 0.30, 0) * FACING, p.base, METAL)
			local lens = c:cyl(V(0.36, 1.66, 1.66), CF(0, 0.30, 0) * FACING, C3(200, 236, 250), GLASS)
			lens.Transparency = 0.25
			-- Magnified eyes, a smile, rosy cheeks and a gleam on the glass.
			c:eyes(0.44, 0.22, 0.36, 0.26)
			smile(c, -0.12, 0.20, 0.30)
			cheeks(c, 0.02, 0.19, 0.58)
			c:box(V(0.10, 0.46, 0.04), CF(-0.46, 0.84, 0.19) * ANG(0, 0, -0.7), WHITE)
			-- Four little screws round the rim.
			for _, a in ipairs({ 0.78, 2.36, 3.93, 5.50 }) do
				c:box(V(0.12, 0.12, 0.06), CF(0.92 * math.cos(a), 0.30 + 0.92 * math.sin(a), 0.16), p.light, METAL)
			end
			-- Stubby arms, two feet, and the wooden handle as a kickstand behind.
			for _, s in ipairs(SIDES) do
				c:round(V(0.30, 0.40, 0.30), CF(1.06 * s, 0.10, 0), p.base)
				c:box(V(0.34, 0.24, 0.40), CF(0.32 * s, -0.80, 0.12), p.deep)
			end
			c:cyl(V(0.24, 0.42, 0.42), CF(0, -0.74, -0.14) * FACING, p.dark, METAL)
			c:rod(V(0, -0.80, -0.20), V(0, -0.92, -0.95), 0.17, BROWN, WOOD)
		end,
	}

	-- A sausage dog made of a brass spyglass's sliding tubes; the big lens is its face.
	S.lf_t_spyglass = {
		label = "Spyglass Dachshund",
		set = "lost_and_found",
		tint = C3(150, 90, 50),
		scale = 1.1,
		head = CF(0, 0.70, 0.45),
		neck = CF(0, -0.40, 1.06),
		back = CF(0, 0.50, -0.70),
		build = function(c, p)
			c:cyl(V(1.00, 1.30, 1.30), CF(0, 0, 0.45) * FACING, p.base)
			c:cyl(V(0.80, 1.10, 1.10), CF(0, 0, -0.40) * FACING, p.light, METAL)
			c:cyl(V(0.60, 0.90, 0.90), CF(0, 0, -1.00) * FACING, p.base)
			c:cyl(V(0.30, 0.50, 0.50), CF(0, 0, -1.40) * FACING, p.dark, METAL)
			for _, z in ipairs({ 0.95, -0.02 }) do
				c:cyl(V(0.12, 1.40, 1.40), CF(0, 0, z) * FACING, p.light, METAL)
			end
			c:cyl(V(0.04, 1.10, 1.10), CF(0, 0, 1.02) * FACING, C3(190, 226, 246), GLASS)
			c:eyes(0.14, 1.08, 0.26, 0.15)
			c:box(V(0.22, 0.16, 0.08), CF(0, -0.10, 1.08), INK)
			smile(c, -0.28, 1.06, 0.22)
			-- Floppy ears and four short legs.
			for _, s in ipairs(SIDES) do
				c:box(V(0.20, 0.70, 0.44), CF(0.74 * s, 0.02, 0.55) * ANG(0, 0, 0.2 * s), p.dark)
				c:box(V(0.30, 0.40, 0.34), CF(0.40 * s, -0.72, 0.55), p.dark)
				c:box(V(0.28, 0.50, 0.32), CF(0.32 * s, -0.66, -0.85), p.dark)
			end
		end,
	}

	-- A folded paper plane that learned to fly by itself, a letter written on its wings.
	S.lf_t_glider = {
		label = "Paper Glider",
		set = "lost_and_found",
		tint = C3(170, 220, 70),
		scale = 1.15,
		head = CF(0, 0.42, 0.20),
		neck = CF(0, -0.40, 0.74),
		back = CF(0, 0.30, -1.00),
		build = function(c, p)
			c:box(V(0.90, 0.80, 1.70), CF(0, 0, -0.15), p.base)
			c:cone(V(0.40, 0.26, 0.24), CF(0, -0.30, 0.82) * ANG(PI / 2, 0, 0), p.light)
			c:box(V(0.08, 0.60, 0.70), CF(0, 0.66, -0.75), p.dark)
			for _, s in ipairs(SIDES) do
				local wing = CF(0.80 * s, 0.06, -0.30) * ANG(0, 0.35 * s, 0)
				c:box(V(1.10, 0.08, 1.30), wing, p.light)
				c:box(V(0.08, 0.40, 1.00), wing * CF(0.55 * s, 0.18, -0.10), p.pale)
				for _, z in ipairs({ 0.25, -0.05 }) do
					c:box(V(0.60, 0.02, 0.05), wing * CF(0.02 * s, 0.05, z), p.deep)
				end
				c:box(V(0.04, 0.04, 0.50), CF(0.30 * s, 0.20 * s, -1.30), WHITE)
			end
			c:eyes(0.16, 0.72, 0.24, 0.14)
			smile(c, -0.04, 0.71, 0.18)
			cheeks(c, 0.02, 0.70, 0.34)
			c:box(V(0.24, 0.03, 0.24), CF(-0.95, 0.12, -0.55) * ANG(0, 0.78, 0), GOLD)
		end,
	}

	-- A much-loved teddy from a trunk in the attic, sitting with its legs out.
	S.lf_t_teddy = {
		label = "Attic Teddy",
		set = "lost_and_found",
		tint = C3(240, 160, 110),
		head = CF(0, 1.04, 0.06),
		neck = CF(0, -0.44, 0.86),
		back = CF(0, 0.20, -0.82),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.90, 1.80, 1.60),
				snout = { w = 0.62, h = 0.42, d = 0.30, y = -0.12, color = p.pale, nose = INK },
				eyeY = 0.28, eyeSpread = 0.38, eyeSize = V(0.30, 0.34, 0.16),
				legSize = V(0.50, 0.44, 0.70), legX = 0.55, legY = -0.80, legZ = { 0.55 },
				tail = false,
			})
			ears(c, p.base, "round", p.pale)
			for _, s in ipairs(SIDES) do
				c:round(V(0.40, 0.70, 0.44), CF(1.00 * s, -0.10, 0.25) * ANG(0.4, 0, 0.2 * s), p.base)
				c:box(V(0.30, 0.30, 0.04), CF(0.55 * s, -0.80, 0.91), p.pale)
			end
			-- A sewn-on patch and a red bow tie.
			c:box(V(0.04, 0.40, 0.40), CF(1.01, 0.40, -0.25) * ANG(0.2, 0, 0), p.light)
			c:box(V(0.16, 0.16, 0.12), CF(0, -0.50, 0.86), RED)
			for _, s in ipairs(SIDES) do
				c:box(V(0.26, 0.24, 0.08), CF(0.20 * s, -0.50, 0.84) * ANG(0, 0, 0.3 * s), RED)
			end
		end,
	}

	-- A rubber duck washed up on the beach, a bottle cap for a hat, bobbing in a puddle.
	S.lf_t_duck = {
		label = "Beachcomb Ducky",
		set = "lost_and_found",
		tint = C3(255, 214, 40),
		head = CF(0.20, 1.12, 0.10),
		neck = CF(0, -0.30, 0.92),
		back = CF(0, 0.10, -1.00),
		build = function(c, p)
			c:round(V(1.60, 1.70, 1.50), CF(0, 0.10, 0.10), p.base)
			c:round(V(1.80, 0.90, 1.40), CF(0, -0.45, -0.40), p.base)
			c:cone(V(0.56, 0.60, 0.44), CF(0, 0.02, -1.12) * ANG(-0.9, 0, 0), p.base)
			c:box(V(0.70, 0.22, 0.40), CF(0, 0.20, 0.98), ORANGE)
			c:box(V(0.56, 0.12, 0.30), CF(0, 0.04, 0.94), C3(230, 110, 30))
			c:eyes(0.56, 0.86, 0.30, 0.15)
			cheeks(c, 0.32, 0.86, 0.54)
			for _, s in ipairs(SIDES) do
				c:round(V(0.20, 0.60, 0.80), CF(0.86 * s, -0.10, -0.12) * ANG(0.3, 0, 0), p.dark)
			end
			-- Bottle-cap hat at a jaunty angle, a strand of seaweed, a puddle to bob in.
			c:cyl(V(0.16, 0.72, 0.72), CF(0.20, 1.03, 0.10) * ANG(0, 0, 0.15) * UP, RED, METAL)
			c:cyl(V(0.06, 0.80, 0.80), CF(0.20, 0.97, 0.10) * ANG(0, 0, 0.15) * UP, SILVER, METAL)
			c:box(V(0.08, 0.70, 0.12), CF(-0.98, -0.20, -0.05) * ANG(0, 0, 0.2), LEAF)
			c:cyl(V(0.06, 2.30, 2.30), CF(0, -0.92, -0.10) * UP, WATER)
		end,
	}

	-- A wind-up tin robot from a box of old toys, key still in its back.
	S.lf_t_robot = {
		label = "Tin Toy Robot",
		set = "lost_and_found",
		tint = C3(140, 160, 190),
		head = CF(0, 0.92, 0),
		neck = CF(0, -0.50, 0.62),
		back = CF(0, 0.20, -0.60),
		build = function(c, p)
			c:box(V(1.40, 1.70, 1.10), CF(0, 0.05, 0), p.base, METAL)
			c:box(V(1.10, 0.52, 0.06), CF(0, 0.52, 0.56), p.pale)
			c:eyes(0.54, 0.62, 0.26, 0.14)
			c:box(V(0.40, 0.08, 0.06), CF(0, 0.12, 0.57), INK)
			-- A chest panel with three dials.
			c:box(V(0.90, 0.50, 0.06), CF(0, -0.38, 0.56), p.light)
			for i, x in ipairs({ -0.26, 0, 0.26 }) do
				c:cyl(V(0.06, 0.18, 0.18), CF(x, -0.38, 0.60) * FACING, ({ RED, GOLD, C3(80, 200, 120) })[i])
			end
			c:rod(V(0, 0.90, 0), V(0, 1.30, 0), 0.04, SILVER, METAL, false)
			c:ball(V(0.24, 0.24, 0.24), CF(0, 1.38, 0), p.light)
			for _, s in ipairs(SIDES) do
				c:cyl(V(0.12, 0.36, 0.36), CF(0.76 * s, 0.50, 0), p.dark, METAL)
				c:box(V(0.30, 0.80, 0.30), CF(0.86 * s, -0.10, 0.10) * ANG(0.3, 0, 0), p.dark, METAL)
				c:box(V(0.34, 0.20, 0.34), CF(0.86 * s, -0.54, 0.26), p.light, METAL)
				c:box(V(0.40, 0.30, 0.40), CF(0.36 * s, -0.92, 0), p.dark, METAL)
				c:box(V(0.46, 0.14, 0.60), CF(0.36 * s, -1.10, 0.08), p.deep)
			end
			-- The wind-up key.
			c:rod(V(0, 0.20, -0.55), V(0, 0.20, -0.86), 0.06, GOLD, METAL, false)
			for _, s in ipairs(SIDES) do
				c:box(V(0.08, 0.34, 0.24), CF(0.18 * s, 0.20, -0.90) * ANG(0, 0, 0.3 * s), GOLD, METAL)
			end
		end,
	}

	-- A lost umbrella that floats about on its own, a little face under the canopy.
	S.lf_t_brolly = {
		label = "Puddle Brolly",
		set = "lost_and_found",
		tint = C3(90, 190, 250),
		head = CF(0, 1.22, 0),
		neck = CF(0, -0.62, 0.46),
		back = CF(0, -0.30, -0.50),
		build = function(c, p)
			c:cone(V(2.30, 0.90, 2.30), CF(0, 0.55, 0), p.base)
			c:cone(V(1.96, 0.86, 1.96), CF(0, 0.56, 0) * ANG(0, PI / 4, 0), p.light)
			c:cyl(V(0.30, 0.14, 0.14), CF(0, 1.12, 0) * UP, p.dark, METAL)
			c:round(V(1.00, 0.95, 0.90), CF(0, -0.38, 0), p.pale)
			c:eyes(-0.26, 0.44, 0.22, 0.13)
			smile(c, -0.54, 0.45, 0.18)
			cheeks(c, -0.46, 0.44, 0.34)
			for _, s in ipairs(SIDES) do
				c:round(V(0.20, 0.36, 0.20), CF(0.56 * s, -0.42, 0.10) * ANG(0, 0, 0.5 * s), p.pale)
			end
			-- The crook handle hanging underneath.
			c:rod(V(0, -0.84, 0), V(0, -1.10, 0), 0.07, BROWN, WOOD, false)
			c:rod(V(0, -1.10, 0), V(0.18, -1.28, 0), 0.07, BROWN, WOOD, false)
			c:rod(V(0.18, -1.28, 0), V(0.38, -1.14, 0), 0.07, BROWN, WOOD, false)
			-- Raindrops falling past.
			for _, v in ipairs({ { -1.10, -0.40, 0.30 }, { 1.05, -0.70, -0.20 }, { 0.90, -0.15, 0.60 } }) do
				c:ball(V(0.16, 0.22, 0.16), CF(v[1], v[2], v[3]), WATER, GLASS)
			end
		end,
	}

	-- A packrat who keeps every shiny thing it finds, in a scout's backpack.
	S.lf_t_packrat = {
		label = "Trinket Packrat",
		set = "lost_and_found",
		tint = C3(170, 150, 130),
		head = CF(0, 0.92, 0.30),
		neck = CF(0, -0.40, 1.10),
		back = CF(0, 1.10, -0.85),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(1.80, 1.50, 1.80),
				snout = { w = 0.60, h = 0.40, d = 0.42, y = -0.18, color = p.pale, nose = PINK },
				eyeY = 0.20, eyeSpread = 0.36, eyeSize = V(0.36, 0.44, 0.18),
				legSize = V(0.36, 0.30, 0.40), legY = -0.76, tail = false,
			})
			ears(c, p.light, "round")
			-- Backpack, its flap, a rolled map and a spoon poking out.
			c:box(V(1.20, 1.00, 0.70), CF(0, 0.55, -0.85), p.deep)
			c:box(V(1.24, 0.30, 0.74), CF(0, 0.98, -0.85), p.dark)
			c:cyl(V(1.40, 0.26, 0.26), CF(0, 1.26, -0.80) * ANG(0, 0, 0.15), PAPER)
			c:rod(V(0.36, 1.00, -0.96), V(0.50, 1.56, -1.02), 0.04, SILVER, METAL, false)
			c:ball(V(0.20, 0.28, 0.10), CF(0.52, 1.64, -1.03), SILVER, METAL)
			-- A long pink tail with a curl.
			c:rod(V(0, -0.40, -0.88), V(0.40, -0.70, -1.40), 0.07, PINK, nil, false)
			c:rod(V(0.40, -0.70, -1.40), V(0.75, -0.40, -1.55), 0.07, PINK, nil, false)
		end,
	}

	-- The one jigsaw piece that always goes missing: a scrap of treasure map on its face.
	S.lf_t_jigsaw = {
		label = "Jigsaw Piece",
		set = "lost_and_found",
		tint = C3(235, 60, 170),
		head = CF(0, 1.46, 0),
		neck = CF(0, -0.40, 0.30),
		back = CF(0, 0.20, -0.30),
		build = function(c, p)
			c:box(V(1.60, 1.60, 0.50), CF(0, 0.10, 0), p.base)
			-- Two tabs out, two blanks in.
			c:cyl(V(0.50, 0.64, 0.64), CF(0, 1.12, 0) * FACING, p.base)
			c:box(V(0.34, 0.20, 0.50), CF(0, 0.92, 0), p.base)
			c:cyl(V(0.50, 0.64, 0.64), CF(1.12, 0.10, 0) * FACING, p.base)
			c:box(V(0.20, 0.34, 0.50), CF(0.86, 0.10, 0), p.base)
			c:cyl(V(0.52, 0.56, 0.56), CF(-0.58, 0.10, 0) * FACING, p.deep)
			c:cyl(V(0.52, 0.56, 0.56), CF(0, -0.42, 0) * FACING, p.deep)
			-- The map scrap: a dotted trail and half a red X.
			for i, v in ipairs({ { -0.40, -0.10 }, { -0.10, -0.30 }, { 0.22, -0.20 } }) do
				c:box(V(0.14, 0.05, 0.04), CF(v[1], v[2], 0.26) * ANG(0, 0, i * 0.3 - 0.6), p.light)
			end
			for _, s in ipairs(SIDES) do
				c:box(V(0.30, 0.07, 0.04), CF(0.50, -0.42, 0.26) * ANG(0, 0, 0.78 * s), RED)
			end
			c:eyes(0.42, 0.30, 0.30, 0.16)
			smile(c, 0.14, 0.27, 0.24)
			cheeks(c, 0.22, 0.26, 0.54)
			-- Stubby arms and feet.
			for _, s in ipairs(SIDES) do
				c:round(V(0.24, 0.40, 0.24), CF(0.92 * s, -0.42, 0), p.base)
				c:box(V(0.36, 0.24, 0.40), CF(0.48 * s, -0.82, 0.05), p.deep)
			end
		end,
	}

	-- One lost knitted mitten, now a kitten: thumb on one side, ears on top.
	S.lf_t_mitten = {
		label = "Kitten Mitten",
		set = "lost_and_found",
		tint = C3(40, 200, 210),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.50, 0.60),
		back = CF(0, 0.20, -0.56),
		build = function(c, p)
			c:round(V(1.50, 1.70, 1.00), CF(0, 0.20, 0), p.base)
			c:round(V(0.50, 0.80, 0.70), CF(0.88, 0.00, 0) * ANG(0, 0, -0.4), p.base)
			c:box(V(1.54, 0.14, 1.04), CF(0, -0.32, 0), p.pale)
			-- The ribbed cuff.
			c:box(V(1.60, 0.50, 1.10), CF(0, -0.72, 0), p.light)
			for _, x in ipairs({ -0.45, -0.15, 0.15, 0.45 }) do
				c:box(V(0.08, 0.46, 0.04), CF(x, -0.72, 0.56), p.dark)
			end
			-- Kitten ears, whiskers, eyes, a pink nose.
			for _, s in ipairs(SIDES) do
				c:cone(V(0.44, 0.50, 0.34), CF(0.42 * s, 1.24, 0), p.base)
				c:box(V(0.20, 0.26, 0.04), CF(0.42 * s, 1.16, 0.15), PINK)
				c:box(V(0.44, 0.03, 0.03), CF(0.52 * s, 0.10, 0.52) * ANG(0, 0, 0.15 * s), INK)
			end
			c:eyes(0.46, 0.50, 0.30, 0.15)
			c:box(V(0.14, 0.10, 0.06), CF(0, 0.20, 0.52), PINK)
			smile(c, 0.06, 0.52, 0.18)
			-- The string that once tied it to its twin, with a pom-pom.
			c:rod(V(0, -0.60, -0.56), V(0.20, -0.86, -1.00), 0.04, p.dark, nil, false)
			c:ball(V(0.36, 0.36, 0.36), CF(0.24, -0.92, -1.10), p.pale)
		end,
	}

	-- A lost rain boot, mud on the toe and a flower growing out of the top.
	S.lf_t_welly = {
		label = "Muddy Welly",
		set = "lost_and_found",
		tint = C3(50, 160, 70),
		scale = 1.1,
		head = CF(0, 1.24, -0.25),
		neck = CF(0, -0.30, 1.04),
		back = CF(0, 0.40, -0.84),
		build = function(c, p)
			c:box(V(1.20, 1.60, 1.10), CF(0, 0.30, -0.25), p.base)
			c:box(V(1.24, 0.70, 1.00), CF(0, -0.60, 0.50), p.base)
			c:round(V(1.26, 0.60, 0.50), CF(0, -0.62, 0.86), p.light)
			c:box(V(1.32, 0.16, 2.10), CF(0, -0.98, 0.15), p.deep)
			c:box(V(1.30, 0.20, 1.20), CF(0, 1.12, -0.25), p.dark)
			c:box(V(0.96, 0.04, 0.86), CF(0, 1.23, -0.25), INK)
			c:box(V(0.30, 0.40, 0.08), CF(0, 1.00, -0.84), p.dark)
			c:eyes(0.48, 0.32, 0.28, 0.15)
			smile(c, 0.14, 0.31, 0.22)
			cheeks(c, 0.20, 0.31, 0.46)
			-- Mud splats.
			c:box(V(0.26, 0.18, 0.06), CF(0.40, -0.40, 1.12), BROWN)
			c:box(V(0.26, 0.06, 0.20), CF(-0.35, -0.24, 0.60), BROWN)
			c:box(V(0.22, 0.14, 0.06), CF(-0.25, -0.78, 1.12), BROWN)
			-- A flower that took root inside.
			c:rod(V(0, 1.10, -0.25), V(0.08, 1.56, -0.20), 0.04, LEAF, nil, false)
			c:box(V(0.26, 0.06, 0.14), CF(0.16, 1.36, -0.22) * ANG(0, 0, 0.4), LEAF)
			c:ball(V(0.32, 0.32, 0.32), CF(0.10, 1.64, -0.20), PINK)
		end,
	}

	-- A homing pigeon who brings lost letters home, satchel at its side.
	S.lf_t_pigeon = {
		label = "Postbag Pigeon",
		set = "lost_and_found",
		tint = C3(120, 140, 220),
		head = CF(0, 1.12, 0.04),
		neck = CF(0, -0.30, 0.96),
		back = CF(0, 0.30, -0.95),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V(1.80, 1.70, 1.70), mouth = false,
				eyeY = 0.30, eyeSpread = 0.40, eyeSize = V(0.34, 0.40, 0.16),
				legSize = V(0.18, 0.30, 0.18), legX = 0.35, legY = -0.86, legZ = { 0.10 }, legColor = PINK,
				tail = false, bib = { w = 1.00, h = 0.60, y = -0.30, color = p.light },
			})
			-- Beak, and the letter it carries.
			c:box(V(0.30, 0.18, 0.30), CF(0, 0.02, 0.98), C3(80, 70, 76))
			c:box(V(0.70, 0.46, 0.05), CF(0, -0.22, 1.14) * ANG(0, 0, 0.15), WHITE)
			c:box(V(0.14, 0.14, 0.04), CF(0, -0.22, 1.18) * ANG(0, 0, 0.78), RED)
			wings(c, p.dark, 0.26, 0.05, -0.15, 0.30)
			c:box(V(0.80, 0.12, 0.60), CF(0, 0.05, -1.05) * ANG(0.3, 0, 0), p.deep)
			-- The satchel on its strap, and a postman's cap.
			c:box(V(0.28, 0.56, 0.70), CF(-1.10, -0.45, 0.05), BROWN)
			c:box(V(0.30, 0.20, 0.72), CF(-1.11, -0.24, 0.05), LEATHER)
			c:box(V(1.50, 0.10, 0.06), CF(-0.50, 0.30, -0.88) * ANG(0, 0, 0.78), LEATHER)
			c:cyl(V(0.24, 0.70, 0.70), CF(0, 0.98, 0) * UP, C3(50, 60, 110))
			c:box(V(0.56, 0.06, 0.30), CF(0, 0.88, 0.42), C3(40, 46, 90))
		end,
	}

	-- A sandcastle that crept down the beach on its own, flag flying, a moat round its feet.
	S.lf_t_sandcastle = {
		label = "Sandcastle",
		set = "lost_and_found",
		tint = C3(250, 215, 160),
		head = CF(0, 1.30, -0.15),
		neck = CF(0, -0.40, 0.70),
		back = CF(0, 0.10, -0.70),
		build = function(c, p)
			c:box(V(1.40, 1.10, 1.30), CF(0, -0.30, 0), p.base)
			-- Two bucket towers in front, a tall keep behind, crenels and a flag.
			for _, s in ipairs(SIDES) do
				c:cyl(V(1.30, 0.56, 0.56), CF(0.72 * s, -0.20, 0.55) * UP, p.light)
				c:cyl(V(0.12, 0.64, 0.64), CF(0.72 * s, 0.50, 0.55) * UP, p.light)
				c:box(V(0.10, 0.18, 0.04), CF(0.72 * s, -0.05, 0.84), p.deep)
				c:ball(V(0.20, 0.16, 0.12), CF(0.45 * s, -0.10, 0.66), PINK)
			end
			c:box(V(0.80, 0.70, 0.80), CF(0, 0.60, -0.15), p.base)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(V(0.18, 0.18, 0.18), CF(0.31 * s, 1.04, -0.15 + 0.31 * t), p.base)
				end
			end
			c:rod(V(0, 0.95, -0.15), V(0, 1.55, -0.15), 0.03, BROWN, nil, false)
			c:box(V(0.04, 0.22, 0.34), CF(0, 1.44, 0.02), RED)
			-- Face, the arched door for a mouth, and the moat.
			c:eyes(-0.10, 0.66, 0.26, 0.15)
			cheeks(c, -0.28, 0.66, 0.42)
			c:box(V(0.30, 0.34, 0.04), CF(0, -0.62, 0.66), p.deep)
			c:cyl(V(0.10, 2.30, 2.30), CF(0, -0.88, 0) * UP, WATER)
		end,
	}

	-- A china piggy bank with a coin halfway into the slot.
	S.lf_t_piggy = {
		label = "Penny Piggy",
		set = "lost_and_found",
		tint = C3(255, 150, 190),
		head = CF(0, 1.00, 0.10),
		neck = CF(0, -0.36, 1.10),
		back = CF(0, 0.20, -0.95),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(2.00, 1.60, 1.80),
				snout = { w = 0.62, h = 0.46, d = 0.32, y = -0.10, color = p.light, nose = p.light },
				eyeY = 0.30, eyeSpread = 0.42, eyeSize = V(0.30, 0.36, 0.16),
				legSize = V(0.40, 0.36, 0.40), legY = -0.80, tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:box(V(0.08, 0.14, 0.04), CF(0.12 * s, -0.10, 1.13), p.deep)
				c:box(V(0.40, 0.36, 0.20), CF(0.56 * s, 0.94, 0.30) * ANG(0.3, 0, -0.35 * s), p.base)
				c:box(V(0.04, 0.34, 0.34), CF(1.05 * s, 0.10, -0.10) * ANG(0.78, 0, 0), p.pale)
			end
			c:box(V(0.70, 0.04, 0.14), CF(0, 0.84, -0.10), INK)
			c:cyl(V(0.08, 0.56, 0.56), CF(0, 1.04, -0.10) * FACING, GOLD, METAL)
			c:rod(V(0, 0.10, -0.92), V(0.12, 0.30, -1.16), 0.06, p.base, nil, false)
			c:rod(V(0.12, 0.30, -1.16), V(-0.04, 0.42, -1.12), 0.06, p.base, nil, false)
		end,
	}

	-- A magician's hat left behind after the show, and the bunny still in it.
	S.lf_t_tophat = {
		label = "Bunny Top Hat",
		set = "lost_and_found",
		tint = C3(70, 40, 120),
		scale = 1.1,
		head = CF(0, 1.36, 0.05),
		neck = CF(0, 0.10, 0.80),
		back = CF(0, -0.20, -0.78),
		build = function(c, p)
			c:cyl(V(1.24, 1.50, 1.50), CF(0, -0.20, 0) * UP, p.base)
			c:cyl(V(0.26, 1.54, 1.54), CF(0, 0.18, 0) * UP, p.light)
			c:cyl(V(0.12, 2.10, 2.10), CF(0, 0.44, 0) * UP, p.dark)
			c:cyl(V(0.04, 1.40, 1.40), CF(0, 0.51, 0) * UP, INK)
			c:round(V(1.20, 0.95, 1.00), CF(0, 0.86, 0.05), p.pale)
			for _, s in ipairs(SIDES) do
				local ear = CF(0.26 * s, 1.62, 0) * ANG(0, 0, (s > 0 and -0.45 or 0.12))
				c:round(V(0.30, 0.82, 0.20), ear, p.pale)
				c:box(V(0.14, 0.56, 0.04), ear * CF(0, 0, 0.11), PINK)
				c:round(V(0.28, 0.20, 0.26), CF(0.42 * s, 0.50, 0.54), p.pale)
			end
			c:eyes(0.94, 0.55, 0.24, 0.13)
			c:box(V(0.12, 0.08, 0.06), CF(0, 0.78, 0.56), PINK)
			c:box(V(0.14, 0.10, 0.04), CF(0, 0.66, 0.55), WHITE)
			cheeks(c, 0.74, 0.55, 0.36)
			c:star(V(0.95, 1.30, 0.30), 0.30, GOLD)
		end,
	}

	----------------------------------------------------------------------------
	-- LEGENDARY: the collector's shelf. More ornate, brass and trim.
	----------------------------------------------------------------------------

	-- An old rotary telephone from the hall table, its handset worn like headphones.
	S.lf_t_phone = {
		label = "Rotary Phone",
		set = "lost_and_found",
		tint = C3(230, 90, 140),
		head = CF(0, 0.82, 0),
		neck = CF(0, -0.80, 0.84),
		back = CF(0, 0.00, -0.84),
		build = function(c, p)
			c:round(V(1.80, 1.20, 1.60), CF(0, -0.30, 0), p.base)
			-- The dial is the face: eyes in it, finger holes round the bottom, a finger stop.
			c:cyl(V(0.10, 1.00, 1.00), CF(0, -0.30, 0.80) * FACING, p.pale)
			for _, d in ipairs({ 200, 235, 270, 305, 340 }) do
				local a = math.rad(d)
				c:cyl(V(0.04, 0.16, 0.16), CF(0.36 * math.cos(a), -0.30 + 0.36 * math.sin(a), 0.85) * FACING, p.deep)
			end
			c:box(V(0.06, 0.16, 0.06), CF(0.42, -0.60, 0.86) * ANG(0, 0, 0.6), SILVER, METAL)
			c:eyes(-0.16, 0.88, 0.20, 0.12)
			smile(c, -0.36, 0.86, 0.16)
			cheeks(c, -0.10, 0.80, 0.70)
			-- The cradle, and the handset lying across it.
			for _, s in ipairs(SIDES) do
				c:box(V(0.20, 0.24, 0.30), CF(0.55 * s, 0.38, 0), p.dark)
				c:round(V(0.44, 0.40, 0.60), CF(0.95 * s, 0.62, 0), p.dark)
			end
			c:box(V(1.70, 0.24, 0.36), CF(0, 0.62, 0), p.dark)
			-- The curly cord for a tail, and four little feet.
			c:rod(V(-0.50, -0.40, -0.80), V(-0.60, -0.60, -1.10), 0.05, p.dark, nil, false)
			c:rod(V(-0.60, -0.60, -1.10), V(-0.40, -0.70, -1.30), 0.05, p.dark, nil, false)
			c:rod(V(-0.40, -0.70, -1.30), V(-0.55, -0.85, -1.45), 0.05, p.dark, nil, false)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(V(0.24, 0.10, 0.24), CF(0.62 * s, -0.92, 0.50 * t), p.deep)
				end
			end
		end,
	}

	-- An old cuckoo clock off the wall: a carved house, a dial face, pine-cone weights.
	S.lf_t_cuckoo = {
		label = "Cuckoo Chalet",
		set = "lost_and_found",
		tint = C3(170, 110, 60),
		scale = 1.2,
		head = CF(0, 1.52, 0),
		neck = CF(0, -0.60, 0.62),
		back = CF(0, 0.20, -0.60),
		build = function(c, p)
			c:box(V(1.60, 1.50, 1.10), CF(0, 0.05, 0), p.base, WOOD)
			c:cone(V(1.60, 0.55, 1.00), CF(0, 1.075, 0), p.base, WOOD)
			for _, s in ipairs(SIDES) do
				c:box(V(1.25, 0.14, 1.40), CF(0.475 * s, 1.03, 0) * ANG(0, 0, -0.60 * s), p.dark, WOOD)
				c:box(V(0.26, 0.12, 0.06), CF(0.62 * s, 0.56, 0.56) * ANG(0, 0, 0.5 * s), p.light)
				-- Pine-cone weights on their chains.
				c:rod(V(0.45 * s, -0.70, 0.20), V(0.45 * s, -1.02, 0.20), 0.03, GOLD, METAL, false)
				c:cone(V(0.24, 0.40, 0.24), CF(0.45 * s, -1.20, 0.20) * ANG(PI, 0, 0), BROWN)
			end
			c:ball(V(0.24, 0.24, 0.24), CF(0, 1.44, 0), GOLD, METAL)
			-- The dial is its face; the hours are four little marks.
			c:cyl(V(0.08, 1.00, 1.00), CF(0, -0.05, 0.56) * FACING, IVORY)
			for _, v in ipairs({ { 0, 0.38 }, { 0.43, 0 }, { 0, -0.43 }, { -0.43, 0 } }) do
				c:box(V(0.08, 0.08, 0.04), CF(v[1], -0.05 + v[2], 0.61), INK)
			end
			c:eyes(0.06, 0.64, 0.20, 0.12)
			smile(c, -0.26, 0.62, 0.20)
			-- The little door above, and the cuckoo popping out of it.
			c:box(V(0.40, 0.36, 0.06), CF(0, 0.70, 0.56), p.deep)
			c:round(V(0.30, 0.26, 0.30), CF(0, 0.72, 0.72), C3(250, 220, 90))
			c:box(V(0.08, 0.06, 0.12), CF(0, 0.72, 0.90), ORANGE)
			-- The pendulum.
			c:rod(V(0, -0.70, 0.30), V(0, -1.20, 0.30), 0.03, GOLD, METAL, false)
			c:cyl(V(0.06, 0.34, 0.34), CF(0, -1.28, 0.30) * FACING, GOLD, METAL)
		end,
	}

	-- A wind-up gramophone, its big brass horn opening like a flower.
	S.lf_t_gramophone = {
		label = "Gramophone Bud",
		set = "lost_and_found",
		tint = C3(240, 130, 40),
		scale = 1.2,
		head = CF(0.55, 0.12, 0.45),
		neck = CF(0, -0.50, 0.80),
		back = CF(0, 0.00, -0.80),
		build = function(c, p)
			c:box(V(1.60, 0.90, 1.50), CF(0, -0.40, 0), p.base, WOOD)
			c:box(V(1.30, 0.50, 0.04), CF(0, -0.45, 0.76), p.dark)
			c:cyl(V(0.06, 1.30, 1.30), CF(0, 0.08, 0) * UP, INK)
			c:cyl(V(0.07, 0.40, 0.40), CF(0, 0.09, 0) * UP, RED)
			c:rod(V(0.50, 0.15, -0.50), V(0, 0.86, -0.58), 0.08, GOLD, METAL, false)
			-- The horn: four widening rings and its dark mouth.
			local dir = V(0, 0.68, 0.73)
			local tilt = ANG(-0.75, 0, 0) * FACING
			for i, t in ipairs({ 0.20, 0.45, 0.70, 0.90 }) do
				local d = 0.40 + 0.34 * (i - 1)
				local at = V(0, 0.90, -0.55) + dir * t
				c:cyl(V(0.24, d, d), CF(at.X, at.Y, at.Z) * tilt, p.light, METAL)
			end
			local mouth = V(0, 0.90, -0.55) + dir * 1.03
			c:cyl(V(0.06, 1.20, 1.20), CF(mouth.X, mouth.Y, mouth.Z) * tilt, p.deep)
			-- Face on the cabinet front.
			c:eyes(-0.24, 0.80, 0.36, 0.16)
			smile(c, -0.56, 0.80, 0.26)
			cheeks(c, -0.46, 0.79, 0.60)
			-- The crank on its side, a note drifting up, four feet.
			c:rod(V(0.80, -0.40, 0.20), V(1.10, -0.40, 0.20), 0.05, GOLD, METAL, false)
			c:box(V(0.08, 0.36, 0.08), CF(1.12, -0.22, 0.20), GOLD, METAL)
			c:ball(V(0.16, 0.12, 0.10), CF(-0.95, 0.60, 0.40), INK)
			c:box(V(0.04, 0.32, 0.04), CF(-0.88, 0.76, 0.40), INK)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(V(0.24, 0.12, 0.24), CF(0.64 * s, -0.91, 0.58 * t), p.dark)
				end
			end
		end,
	}

	-- An old brass diving helmet found on the sea bed, someone small looking out.
	S.lf_t_helmet = {
		label = "Diving Helmet",
		set = "lost_and_found",
		tint = C3(230, 190, 70),
		scale = 1.1,
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.60, 0.94),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			c:ball(V(1.80, 1.80, 1.80), CF(0, 0.25, 0), p.base, METAL)
			c:box(V(2.00, 0.40, 1.80), CF(0, -0.70, 0), p.dark, METAL)
			for _, x in ipairs({ -0.75, -0.25, 0.25, 0.75 }) do
				c:cyl(V(0.08, 0.14, 0.14), CF(x, -0.70, 0.91) * FACING, BRASS, METAL)
			end
			-- The front porthole is the face.
			c:cyl(V(0.16, 1.10, 1.10), CF(0, 0.25, 0.86) * FACING, p.light, METAL)
			local glass = c:cyl(V(0.18, 0.90, 0.90), CF(0, 0.25, 0.88) * FACING, C3(170, 220, 240), GLASS)
			glass.Transparency = 0.3
			c:eyes(0.34, 1.00, 0.20, 0.12)
			smile(c, 0.06, 0.99, 0.18)
			-- Side portholes, lead boots, the air valve on top and the hose.
			for _, s in ipairs(SIDES) do
				c:cyl(V(0.14, 0.60, 0.60), CF(0.86 * s, 0.30, 0), p.light, METAL)
				c:cyl(V(0.16, 0.44, 0.44), CF(0.87 * s, 0.30, 0), C3(170, 220, 240), GLASS)
				c:box(V(0.50, 0.30, 0.70), CF(0.45 * s, -1.02, 0.10), p.deep)
			end
			c:cyl(V(0.20, 0.36, 0.36), CF(0, 1.18, 0) * UP, p.light, METAL)
			c:ball(V(0.18, 0.18, 0.18), CF(0, 1.32, 0), p.dark, METAL)
			c:rod(V(0, 0.40, -0.86), V(0.20, 0.00, -1.24), 0.10, C3(60, 60, 70), nil, false)
			c:rod(V(0.20, 0.00, -1.24), V(0.60, -0.46, -1.16), 0.10, C3(60, 60, 70), nil, false)
			-- A starfish stuck on, two barnacles, and bubbles rising.
			for _, a in ipairs({ 0, 1.26, 2.51 }) do
				c:box(V(0.06, 0.36, 0.08), CF(-0.62, 0.78, 0.46) * ANG(0, -0.6, 0) * ANG(0, 0, a), ORANGE)
			end
			for _, v in ipairs({ { 0.60, -0.10, 0.62 }, { -0.70, -0.20, 0.52 } }) do
				c:ball(V(0.18, 0.14, 0.18), CF(v[1], v[2], v[3]), IVORY)
			end
			for _, v in ipairs({ { 0.40, 1.40, 0.50 }, { 0.60, 1.72, 0.40 } }) do
				c:ball(V(0.18, 0.18, 0.18), CF(v[1], v[2], v[3]), WATER, GLASS)
			end
		end,
	}

	-- A traveller's trunk that walked home by itself, stickers from everywhere.
	S.lf_t_trunk = {
		label = "Steamer Trunk",
		set = "lost_and_found",
		tint = C3(30, 140, 150),
		head = CF(0, 0.92, 0),
		neck = CF(0, -0.40, 0.74),
		back = CF(0, 0.20, -0.74),
		build = function(c, p)
			c:box(V(1.90, 1.10, 1.40), CF(0, -0.10, 0), p.base, WOOD)
			c:round(V(1.92, 0.60, 1.40), CF(0, 0.48, 0), p.base)
			c:box(V(1.94, 0.06, 1.44), CF(0, 0.42, 0), p.dark)
			for _, s in ipairs(SIDES) do
				-- Leather straps and buckles, brass corners, stubby legs.
				c:box(V(0.20, 1.62, 1.46), CF(0.52 * s, 0.10, 0), p.deep)
				c:box(V(0.24, 0.20, 0.06), CF(0.52 * s, 0.10, 0.74), BRASS, METAL)
				for _, y in ipairs({ -0.60, 0.40 }) do
					c:box(V(0.22, 0.22, 0.10), CF(0.88 * s, y, 0.68), BRASS, METAL)
				end
				for _, z in ipairs({ 0.45, -0.45 }) do
					c:box(V(0.36, 0.36, 0.36), CF(0.66 * s, -0.82, z), p.dark)
				end
			end
			-- The lock plate is its nose.
			c:eyes(0.02, 0.74, 0.24, 0.14)
			c:box(V(0.22, 0.26, 0.06), CF(0, 0.42, 0.72), BRASS, METAL)
			smile(c, -0.32, 0.72, 0.24)
			-- Travel stickers.
			c:box(V(0.04, 0.34, 0.44), CF(0.96, -0.12, 0.30), C3(240, 90, 90))
			c:box(V(0.04, 0.30, 0.30), CF(-0.96, -0.30, -0.30) * ANG(0.3, 0, 0), C3(250, 210, 80))
			c:box(V(0.30, 0.26, 0.04), CF(-0.24, -0.50, 0.71) * ANG(0, 0, 0.2), C3(90, 170, 240))
			-- A carry handle on top and a luggage tag for a tail.
			c:box(V(0.60, 0.10, 0.14), CF(0, 0.84, 0), p.deep)
			c:rod(V(0, -0.10, -0.70), V(0, -0.30, -1.05), 0.03, INK, nil, false)
			c:box(V(0.30, 0.20, 0.04), CF(0, -0.42, -1.10) * ANG(0.3, 0, 0.2), PAPER)
		end,
	}

	-- A folding camera on its tripod, bellows out, the lens for a nose.
	S.lf_t_camera = {
		label = "Bellows Camera",
		set = "lost_and_found",
		tint = C3(200, 60, 50),
		head = CF(0, 1.22, -0.45),
		neck = CF(0, -0.10, 1.10),
		back = CF(0, 0.30, -0.92),
		build = function(c, p)
			c:box(V(1.40, 1.30, 0.90), CF(0, 0.30, -0.45), p.base)
			for i, v in ipairs({ { 1.20, 1.10, 0.10 }, { 1.04, 0.96, 0.34 }, { 0.88, 0.82, 0.58 } }) do
				c:box(V(v[1], v[2], 0.26), CF(0, 0.30, v[3]), i % 2 == 1 and p.dark or p.deep)
			end
			c:box(V(0.86, 0.86, 0.10), CF(0, 0.30, 0.76), p.light, METAL)
			c:cyl(V(0.30, 0.46, 0.46), CF(0, 0.20, 0.92) * FACING, INK, METAL)
			c:cyl(V(0.06, 0.34, 0.34), CF(0, 0.20, 1.08) * FACING, C3(150, 200, 230), GLASS)
			c:eyes(0.58, 0.84, 0.26, 0.11)
			smile(c, -0.06, 0.82, 0.20)
			-- Viewfinder, shutter button and the flash on top.
			c:box(V(0.40, 0.24, 0.50), CF(0, 1.07, -0.45), p.dark)
			c:cyl(V(0.10, 0.12, 0.12), CF(-0.50, 1.00, -0.30) * UP, SILVER, METAL)
			c:cyl(V(0.10, 0.56, 0.56), CF(0.50, 1.30, -0.55) * FACING, SILVER, METAL)
			c:ball(V(0.30, 0.30, 0.30), CF(0.50, 1.30, -0.46), WHITE, GLASS)
			c:rod(V(0.50, 0.95, -0.55), V(0.50, 1.04, -0.55), 0.04, SILVER, METAL, false)
			-- The tripod.
			c:box(V(0.50, 0.12, 0.50), CF(0, -0.41, -0.40), SILVER, METAL)
			for _, v in ipairs({ { -0.70, 0.10 }, { 0.70, 0.10 }, { 0, -1.05 } }) do
				c:rod(V(0, -0.42, -0.40), V(v[1], -1.12, v[2]), 0.06, BROWN, WOOD, false)
			end
		end,
	}

	-- A study's desk globe on its brass stand, a pin in the place it wants to visit.
	S.lf_t_globe = {
		label = "Desk Globe",
		set = "lost_and_found",
		tint = C3(40, 120, 220),
		head = CF(0, 1.42, 0),
		neck = CF(0, -0.70, 0.40),
		back = CF(0, 0.35, -0.90),
		build = function(c, p)
			c:ball(V(1.70, 1.70, 1.70), CF(0, 0.35, 0), p.base)
			for _, v in ipairs({ { -0.60, 0.80, 0.40 }, { 0.62, 0.05, 0.42 }, { 0.30, 0.95, -0.62 }, { -0.70, 0.05, -0.40 }, { 0.10, -0.30, -0.62 } }) do
				c:round(V(0.46, 0.40, 0.40), CF(v[1], v[2], v[3]), p.light)
			end
			-- Half a brass meridian ring and the axis pin.
			local pts = {}
			for i = 0, 4 do
				local a = -PI / 2 + i * PI / 4
				pts[i] = V(0.98 * math.cos(a), 0.35 + 0.98 * math.sin(a), 0)
			end
			for i = 1, 4 do
				c:rod(pts[i - 1], pts[i], 0.05, BRASS, METAL, false)
			end
			c:ball(V(0.16, 0.16, 0.16), CF(0, 1.36, 0), BRASS, METAL)
			-- Stand and base.
			c:cyl(V(0.36, 0.16, 0.16), CF(0, -0.80, 0) * UP, BRASS, METAL)
			c:cyl(V(0.18, 1.20, 1.20), CF(0, -1.04, 0) * UP, BROWN, WOOD)
			-- Face, and the pin flag.
			c:eyes(0.48, 0.80, 0.28, 0.15)
			smile(c, 0.14, 0.82, 0.22)
			cheeks(c, 0.30, 0.71, 0.50)
			c:rod(V(0.45, 0.95, 0.40), V(0.60, 1.35, 0.55), 0.03, SILVER, METAL, false)
			c:box(V(0.04, 0.18, 0.26), CF(0.60, 1.28, 0.68), RED)
		end,
	}

	-- A ship's parrot on a bit of driftwood, the treasure map clutched in its claws.
	S.lf_t_parrot = {
		label = "Chart Parrot",
		set = "lost_and_found",
		tint = C3(40, 200, 80),
		scale = 1.1,
		head = CF(0, 1.30, 0.04),
		neck = CF(0, -0.40, 0.90),
		back = CF(0, 0.30, -0.90),
		build = function(c, p)
			block(c, p, {
				shape = "bird", bodySize = V(1.60, 1.90, 1.50), mouth = false,
				eyeY = 0.40, eyeSpread = 0.36, eyeSize = V(0.30, 0.38, 0.16),
				legs = false, tail = false, bib = { w = 0.90, h = 0.90, y = -0.30, color = p.light },
			})
			-- Hooked beak and a three-feather crest.
			c:box(V(0.36, 0.34, 0.30), CF(0, 0.10, 0.88), C3(250, 210, 80))
			c:cone(V(0.30, 0.24, 0.20), CF(0, -0.12, 0.96) * ANG(PI, 0, 0), C3(60, 50, 50))
			for i, x in ipairs({ -0.16, 0, 0.16 }) do
				c:box(V(0.14, 0.50, 0.24), CF(x, 1.18, -0.05 - 0.05 * i) * ANG(-0.3, 0, -x * 1.5), p.pale)
			end
			-- Wings with darker tips, grey feet, and a long two-tone tail.
			for _, s in ipairs(SIDES) do
				c:box(V(0.24, 1.20, 0.90), CF(0.88 * s, 0.00, -0.10) * ANG(0.2, 0, 0.08 * s), p.dark)
				c:box(V(0.22, 0.50, 0.60), CF(0.88 * s, -0.62, -0.32), p.deep)
				c:box(V(0.24, 0.20, 0.30), CF(0.30 * s, -0.98, 0.22), C3(120, 120, 130))
			end
			c:box(V(0.50, 1.20, 0.16), CF(0, -0.95, -0.85) * ANG(-0.5, 0, 0), p.deep)
			c:box(V(0.30, 1.00, 0.12), CF(0, -0.92, -0.98) * ANG(-0.4, 0, 0), RED)
			-- Driftwood perch, the rolled map, and a compass pendant.
			c:cyl(V(2.00, 0.24, 0.24), CF(0, -1.14, 0.20), BROWN, WOOD)
			c:cyl(V(0.90, 0.26, 0.26), CF(0, -0.80, 0.82), PAPER)
			c:cyl(V(0.06, 0.28, 0.28), CF(0, -0.80, 0.82), RED)
			c:cyl(V(0.06, 0.28, 0.28), CF(0, -0.34, 0.90) * FACING, GOLD, METAL)
		end,
	}

	-- A beagle with headphones on, sweeping a metal detector for buried coins.
	S.lf_t_beagle = {
		label = "Detector Beagle",
		set = "lost_and_found",
		tint = C3(225, 160, 90),
		head = CF(0, 1.04, 0.10),
		neck = CF(0, -0.40, 1.00),
		back = CF(0, 0.94, -0.40),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(1.90, 1.60, 1.90),
				snout = { w = 0.66, h = 0.44, d = 0.46, y = -0.18, color = p.pale, nose = INK },
				eyeY = 0.24, eyeSpread = 0.38, eyeSize = V(0.34, 0.40, 0.16),
				bib = { w = 0.80, h = 0.60, y = -0.50, color = p.pale },
				legSize = V(0.40, 0.36, 0.46), tail = false,
			})
			ears(c, p.dark, "down")
			-- A darker saddle, and the white-tipped tail held high.
			c:box(V(1.94, 0.36, 1.00), CF(0, 0.74, -0.40), p.dark)
			c:box(V(0.16, 0.60, 0.16), CF(0, 0.66, -0.98) * ANG(-0.3, 0, 0), p.base)
			c:box(V(0.18, 0.20, 0.18), CF(0, 0.98, -1.08), WHITE)
			-- Headphones.
			c:box(V(1.70, 0.14, 0.20), CF(0, 0.94, 0.10), INK)
			for _, s in ipairs(SIDES) do
				c:cyl(V(0.20, 0.46, 0.46), CF(0.96 * s, 0.70, 0.10), RED)
			end
			-- The metal detector, its light blinking: found something!
			c:rod(V(0.80, -0.10, 0.70), V(0.95, -0.78, 1.15), 0.05, SILVER, METAL, false)
			c:box(V(0.24, 0.18, 0.30), CF(0.80, 0.02, 0.64), C3(250, 210, 60))
			c:ball(V(0.12, 0.12, 0.12), CF(0.80, 0.14, 0.66), C3(80, 255, 120), NEON)
			c:cyl(V(0.08, 0.66, 0.66), CF(0.95, -0.84, 1.20) * UP, INK)
			c:cyl(V(0.06, 0.30, 0.30), CF(0.40, -0.92, 1.25) * UP, GOLD, METAL)
		end,
	}

	-- The prize of a cabinet of curiosities: a horned hare on a labelled plinth.
	S.lf_t_jackalope = {
		label = "Curio Jackalope",
		set = "lost_and_found",
		tint = C3(160, 120, 220),
		scale = 1.1,
		head = CF(0, 1.00, 0.20),
		neck = CF(0, -0.40, 0.98),
		back = CF(0, 0.30, -0.92),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(1.70, 1.60, 1.70),
				snout = { w = 0.50, h = 0.34, d = 0.30, y = -0.16, color = p.pale, nose = PINK },
				eyeY = 0.24, eyeSpread = 0.36, eyeSize = V(0.32, 0.40, 0.16),
				legSize = V(0.40, 0.30, 0.50), legY = -0.80,
				tailSize = V(0.40, 0.40, 0.36), tailColor = p.pale,
			})
			for _, s in ipairs(SIDES) do
				-- Long ears out to the sides.
				local ear = CF(0.56 * s, 1.24, -0.30) * ANG(-0.2, 0, -0.35 * s)
				c:round(V(0.28, 0.90, 0.18), ear, p.base)
				c:box(V(0.12, 0.60, 0.04), ear * CF(0, 0, 0.10), PINK)
				-- Little antlers between them.
				c:rod(V(0.18 * s, 0.84, 0.20), V(0.36 * s, 1.50, 0.30), 0.05, IVORY, nil, false)
				c:rod(V(0.27 * s, 1.18, 0.25), V(0.56 * s, 1.36, 0.36), 0.04, IVORY, nil, false)
				c:rod(V(0.34 * s, 1.40, 0.29), V(0.22 * s, 1.70, 0.34), 0.04, IVORY, nil, false)
			end
			-- The museum plinth and its brass label.
			c:box(V(1.90, 0.30, 1.90), CF(0, -1.12, 0), BROWN, WOOD)
			c:box(V(0.70, 0.18, 0.04), CF(0, -1.12, 0.96), BRASS, METAL)
		end,
	}

	-- A scholar's inkwell with a feather quill, sitting on an unfinished letter.
	S.lf_t_inkwell = {
		label = "Inkwell Quill",
		set = "lost_and_found",
		tint = C3(40, 60, 160),
		scale = 1.2,
		head = CF(-0.40, 0.58, 0.20),
		neck = CF(0, -0.50, 0.94),
		back = CF(0, 0.00, -0.94),
		build = function(c, p)
			c:box(V(1.80, 1.10, 1.80), CF(0, -0.30, 0), p.base)
			c:box(V(1.30, 0.30, 1.30), CF(0, 0.40, 0), p.base)
			c:cyl(V(0.30, 0.80, 0.80), CF(0, 0.70, 0) * UP, GOLD, METAL)
			c:cyl(V(0.04, 0.60, 0.60), CF(0, 0.86, 0) * UP, INK)
			-- The quill: shaft, vane, inner barbs and the inky nib.
			local tilt = ANG(0, 0, -0.32)
			c:rod(V(0.10, 0.70, -0.05), V(0.55, 2.05, -0.05), 0.05, WHITE, nil, false)
			c:box(V(0.40, 1.10, 0.05), CF(0.40, 1.55, -0.05) * tilt, p.light)
			c:box(V(0.24, 0.80, 0.06), CF(0.42, 1.62, -0.05) * tilt, p.pale)
			c:box(V(0.08, 0.16, 0.08), CF(0.08, 0.66, -0.05) * tilt, INK)
			-- Face, label, and a drip of ink.
			c:eyes(-0.16, 0.92, 0.38, 0.16)
			smile(c, -0.44, 0.92, 0.26)
			cheeks(c, -0.36, 0.91, 0.62)
			c:box(V(0.90, 0.20, 0.04), CF(0, -0.70, 0.91), PAPER)
			c:round(V(0.16, 0.44, 0.06), CF(0.55, 0.06, 0.91), INK)
			-- The letter underneath, its written lines, and a little ink spill.
			c:box(V(2.40, 0.04, 1.60), CF(0.20, -0.87, 0.30) * ANG(0, 0.2, 0), PAPER)
			for _, v in ipairs({ { -0.40, 1.02 }, { 0.30, 1.00 }, { 1.10, 0.55 } }) do
				c:box(V(0.40, 0.02, 0.04), CF(v[1], -0.84, v[2]), INK)
			end
			c:cyl(V(0.04, 0.40, 0.40), CF(-1.00, -0.84, 0.00) * UP, INK)
		end,
	}

	-- A typewriter from the attic, still clacking out letters on its own.
	S.lf_t_typewriter = {
		label = "Clacky Typewriter",
		set = "lost_and_found",
		tint = C3(60, 170, 110),
		scale = 1.15,
		head = CF(0, 0.52, -0.20),
		neck = CF(0, -0.50, 0.92),
		back = CF(0, 0.10, -0.72),
		build = function(c, p)
			c:box(V(2.00, 0.70, 1.60), CF(0, -0.50, 0.10), p.base, METAL)
			c:box(V(1.80, 0.70, 1.00), CF(0, 0.15, -0.20), p.base, METAL)
			c:eyes(0.24, 0.32, 0.36, 0.15)
			smile(c, -0.02, 0.32, 0.28)
			cheeks(c, 0.04, 0.31, 0.64)
			-- Two rows of round keys and a space bar.
			for r, z in ipairs({ 0.45, 0.72 }) do
				for i = 1, 4 do
					c:cyl(V(0.10, 0.24, 0.24), CF(-0.69 + (i - 1) * 0.46 + (r - 1) * 0.12, -0.10, z) * UP, IVORY)
				end
			end
			c:box(V(0.80, 0.08, 0.14), CF(0, -0.12, 0.94), IVORY)
			-- Roller, knobs, the sheet in it, and the return lever.
			c:cyl(V(2.30, 0.40, 0.40), CF(0, 0.62, -0.30), INK)
			for _, s in ipairs(SIDES) do
				c:cyl(V(0.14, 0.44, 0.44), CF(1.22 * s, 0.62, -0.30), p.light, METAL)
			end
			local sheet = CF(0, 1.15, -0.40) * ANG(-0.15, 0, 0)
			c:box(V(1.20, 1.00, 0.04), sheet, PAPER)
			for _, y in ipairs({ 0.20, 0.06, -0.08 }) do
				c:box(V(0.80, 0.04, 0.02), sheet * CF(-0.10 + y * 0.5, y, 0.03), INK)
			end
			c:rod(V(-1.22, 0.70, -0.20), V(-1.42, 0.82, 0.25), 0.05, SILVER, METAL, false)
			c:ball(V(0.16, 0.16, 0.16), CF(-1.42, 0.82, 0.25), INK)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(V(0.24, 0.10, 0.24), CF(0.80 * s, -0.90, 0.10 + 0.60 * t), p.dark)
				end
			end
		end,
	}

	----------------------------------------------------------------------------
	-- MYTHIC: the hidden chamber. Neon glow, floating bits.
	----------------------------------------------------------------------------

	-- A forgotten snow globe with a whole tiny village inside, still snowing.
	S.lf_t_snowdome = {
		label = "Snowdome Hamlet",
		set = "lost_and_found",
		tint = C3(90, 170, 240),
		scale = 1.1,
		head = CF(0, 1.52, 0),
		neck = CF(0, -0.60, 0.98),
		back = CF(0, -0.50, -0.98),
		build = function(c, p)
			c:cyl(V(0.60, 1.90, 1.90), CF(0, -0.65, 0) * UP, p.base, WOOD)
			for _, y in ipairs({ -0.35, -0.95 }) do
				c:cyl(V(0.12, 2.00, 2.00), CF(0, y, 0) * UP, GOLD, METAL)
			end
			c:box(V(0.60, 0.24, 0.06), CF(0, -0.65, 0.96), GOLD, METAL)
			local dome = c:ball(V(1.90, 1.90, 1.90), CF(0, 0.55, 0), p.pale, GLASS)
			dome.Transparency = 0.55
			c:cyl(V(0.10, 1.60, 1.60), CF(0, -0.28, 0) * UP, WHITE)
			-- The village inside: a cottage with a lit window, two pines.
			c:box(V(0.50, 0.40, 0.40), CF(-0.25, 0.00, -0.25), p.dark)
			c:cone(V(0.60, 0.30, 0.50), CF(-0.25, 0.35, -0.25), p.deep)
			c:box(V(0.12, 0.12, 0.04), CF(-0.25, 0.00, -0.04), p.glow, NEON)
			c:cone(V(0.36, 0.60, 0.36), CF(0.35, 0.07, -0.30), C3(60, 140, 90))
			c:cone(V(0.30, 0.50, 0.30), CF(0.10, 0.02, -0.55), C3(50, 120, 80))
			-- Face on the glass.
			c:eyes(0.70, 0.88, 0.32, 0.17)
			smile(c, 0.36, 0.93, 0.24)
			cheeks(c, 0.48, 0.81, 0.50)
			-- Glowing snowflakes swirling inside, and a star on top.
			for _, v in ipairs({ { 0.50, 0.90, -0.20 }, { -0.50, 1.00, 0.10 }, { 0.00, 1.20, -0.40 }, { 0.45, 0.40, 0.30 }, { -0.60, 0.50, -0.40 } }) do
				c:box(V(0.10, 0.10, 0.10), CF(v[1], v[2], v[3]) * ANG(0.6, 0.6, 0), p.glow, NEON)
			end
			c:star(V(0, 1.72, 0), 0.40, p.glow)
			-- The wind-up key behind, and three bun feet.
			c:rod(V(0, -0.65, -0.95), V(0, -0.65, -1.20), 0.05, GOLD, METAL, false)
			c:box(V(0.08, 0.30, 0.30), CF(0, -0.65, -1.24) * ANG(PI / 4, 0, 0), GOLD, METAL)
			for _, a in ipairs({ 0.52, 2.62, 4.71 }) do
				c:ball(V(0.30, 0.20, 0.30), CF(0.70 * math.cos(a), -1.02, 0.70 * math.sin(a)), GOLD, METAL)
			end
			c:light(p.glow, 1, 6)
		end,
	}

	-- A little grand piano from a shut-up parlour, lid propped open, its tunes floating free.
	S.lf_t_piano = {
		label = "Parlour Piano",
		set = "lost_and_found",
		tint = C3(150, 40, 70),
		scale = 1.1,
		head = CF(-0.40, 0.48, -0.20),
		neck = CF(0, -0.30, 1.00),
		back = CF(0, 0.20, -1.40),
		build = function(c, p)
			c:box(V(1.80, 0.60, 1.60), CF(0, 0.10, -0.20), p.base)
			c:cyl(V(0.60, 1.20, 1.20), CF(0.30, 0.10, -0.90) * UP, p.base)
			c:box(V(1.40, 0.02, 1.20), CF(0, 0.41, -0.30), p.glow, NEON)
			c:box(V(1.80, 0.06, 1.70), CF(0.05, 0.80, -0.40) * ANG(0, 0, 0.5), p.base)
			c:rod(V(0.60, 0.40, -0.30), V(0.66, 0.92, -0.30), 0.03, GOLD, METAL, false)
			-- The keys, white and black, like a big toothy grin.
			c:box(V(1.60, 0.14, 0.40), CF(0, 0.00, 0.75), WHITE)
			for _, x in ipairs({ -0.56, -0.28, 0, 0.28, 0.56 }) do
				c:box(V(0.08, 0.06, 0.22), CF(x, 0.09, 0.68), INK)
			end
			-- The face above the keys, and a sheet of music on its stand.
			c:box(V(1.70, 0.40, 0.10), CF(0, 0.30, 0.60), p.dark)
			c:eyes(0.30, 0.66, 0.30, 0.13)
			cheeks(c, 0.22, 0.66, 0.56)
			c:box(V(0.70, 0.40, 0.04), CF(0, 0.70, 0.45) * ANG(-0.3, 0, 0), PAPER)
			for _, y in ipairs({ 0.76, 0.64 }) do
				c:box(V(0.50, 0.03, 0.02), CF(0, y, 0.48) * ANG(-0.3, 0, 0), INK)
			end
			-- Three legs, the pedals and their post.
			for _, v in ipairs({ { -0.70, 0.40 }, { 0.70, 0.40 }, { 0.30, -1.00 } }) do
				c:box(V(0.20, 0.70, 0.20), CF(v[1], -0.55, v[2]), p.dark)
			end
			c:box(V(0.12, 0.50, 0.12), CF(0, -0.55, 0.45), p.dark)
			c:box(V(0.30, 0.06, 0.10), CF(0, -0.82, 0.48), GOLD, METAL)
			-- Glowing notes drifting up.
			for _, v in ipairs({ { -0.95, 0.90, 0.30 }, { 0.95, 1.40, 0.10 }, { -0.40, 1.50, -0.20 } }) do
				c:ball(V(0.18, 0.14, 0.10), CF(v[1], v[2], v[3]), p.glow, NEON)
				c:box(V(0.04, 0.34, 0.04), CF(v[1] + 0.07, v[2] + 0.17, v[3]), p.glow, NEON)
			end
			c:light(p.glow, 1, 6)
		end,
	}

	-- A bookcase that is really a door: pull the right book and it swings open.
	S.lf_t_bookcase = {
		label = "Secret Bookcase",
		set = "lost_and_found",
		tint = C3(130, 70, 45),
		scale = 1.25,
		head = CF(0, 1.42, -0.10),
		neck = CF(0, -0.60, 0.46),
		back = CF(0, 0.30, -0.58),
		build = function(c, p)
			c:box(V(1.80, 2.20, 0.90), CF(0, 0.15, -0.10), p.base, WOOD)
			c:box(V(2.00, 0.20, 1.00), CF(0, 1.30, -0.10), p.dark, WOOD)
			c:box(V(1.60, 0.50, 0.06), CF(0, 0.95, 0.37), p.light)
			c:eyes(1.02, 0.42, 0.34, 0.14)
			smile(c, 0.80, 0.41, 0.24)
			-- Two shelves of books, one pulled halfway out, one leaning.
			local spines = { p.deep, RED, p.pale, C3(70, 100, 200), GOLD, C3(70, 150, 90), p.light, p.deep, C3(150, 60, 160), RED }
			local heights = { 0.50, 0.42, 0.56, 0.46, 0.52 }
			for r, y0 in ipairs({ 0.05, -0.70 }) do
				c:box(V(1.70, 0.08, 0.20), CF(0, y0 - 0.04, 0.30), p.dark, WOOD)
				for i = 1, 5 do
					local h = heights[i]
					local pulled = (r == 1 and i == 4) and 0.22 or 0
					local lean = (r == 2 and i == 5) and -0.25 or 0
					c:box(V(0.26, h, 0.24), CF(-0.62 + (i - 1) * 0.31, y0 + h / 2, 0.30 + pulled) * ANG(0, 0, lean), spines[(r - 1) * 5 + i])
				end
			end
			-- The glowing crack of the hidden door, light spilling on the floor.
			c:box(V(0.06, 2.00, 0.06), CF(0.92, 0.15, 0.36), p.glow, NEON)
			c:box(V(0.50, 0.03, 0.60), CF(1.10, -0.94, 0.40), p.glow, NEON)
			-- A candle on top, and a key floating out of the shadows.
			c:cyl(V(0.06, 0.34, 0.34), CF(-0.55, 1.43, -0.10) * UP, GOLD, METAL)
			c:cyl(V(0.40, 0.16, 0.16), CF(-0.55, 1.66, -0.10) * UP, IVORY)
			c:ball(V(0.14, 0.22, 0.14), CF(-0.55, 1.94, -0.10), p.glow, NEON)
			c:box(V(0.08, 0.50, 0.08), CF(0.50, 1.80, 0.10) * ANG(0, 0, -0.5), p.glow, NEON)
			c:cyl(V(0.06, 0.26, 0.26), CF(0.64, 2.06, 0.10), p.glow, NEON)
			-- Bracket feet.
			for _, s in ipairs(SIDES) do
				c:box(V(0.30, 0.12, 0.50), CF(0.75 * s, -1.01, -0.10), p.dark, WOOD)
			end
			c:light(p.glow, 1, 6)
		end,
	}

	-- A magic carpet rolled up in an attic for centuries, now flying again, front edge curled up into a face.
	S.lf_t_rug = {
		label = "Flying Rug",
		set = "lost_and_found",
		tint = C3(220, 120, 30),
		scale = 1.1,
		head = CF(0, 0.82, 1.10),
		neck = CF(0, -0.20, 1.10),
		back = CF(0, 0.10, -1.30),
		build = function(c, p)
			c:box(V(1.80, 0.12, 2.20), CF(0, -0.20, -0.10), p.base)
			c:cyl(V(1.80, 0.40, 0.40), CF(0, -0.05, -1.20), p.base)
			-- The curled-up front is its face.
			local front = CF(0, 0.18, 1.00) * ANG(-0.25, 0, 0)
			c:box(V(1.80, 0.80, 0.12), front, p.base)
			c:cyl(V(1.80, 0.30, 0.30), CF(0, 0.62, 1.12), p.light)
			for _, s in ipairs(SIDES) do
				c:eye(front * V(0.30 * s, 0.10, 0.10), 0.15)
				c:box(V(0.18, 0.10, 0.04), front * CF(0.52 * s, -0.08, 0.07), PINK)
			end
			c:box(V(0.26, 0.07, 0.06), front * CF(0, -0.16, 0.08), INK)
			-- Woven borders, diamonds and a glowing medallion.
			for _, z in ipairs({ 0.55, -0.75 }) do
				c:box(V(1.84, 0.13, 0.12), CF(0, -0.20, z), p.dark)
			end
			c:cyl(V(0.14, 0.70, 0.70), CF(0, -0.16, -0.10) * UP, p.glow, NEON)
			for _, z in ipairs({ 0.30, -0.50 }) do
				c:box(V(0.30, 0.14, 0.30), CF(0, -0.18, z) * ANG(0, PI / 4, 0), p.light)
			end
			-- Gold tassels at the corners.
			for _, s in ipairs(SIDES) do
				c:box(V(0.10, 0.24, 0.10), CF(0.92 * s, -0.30, -1.20), GOLD)
				c:box(V(0.10, 0.24, 0.10), CF(0.92 * s, -0.10, 0.98), GOLD)
			end
			-- A cushion with a glowing orb riding on it, and a trail of sparkle behind.
			c:box(V(0.50, 0.16, 0.50), CF(0.40, -0.06, -0.55), p.deep)
			c:ball(V(0.26, 0.26, 0.26), CF(0.40, 0.14, -0.55), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V(0.04, 0.04, 0.40), CF(0.50 * s, -0.30, -1.55), p.glow, NEON)
				c:round(V(0.40, 0.24, 0.34), CF(0.80 * s, -0.55, 0.30 - 0.50 * s), WHITE)
			end
			c:sparkle(p.glow, 3, 0.4, 0.15)
		end,
	}

	-- An explorer's airship, lost in the clouds a hundred years and still flying.
	S.lf_t_blimp = {
		label = "Explorer Blimp",
		set = "lost_and_found",
		tint = C3(90, 200, 160),
		scale = 1.15,
		head = CF(0, 1.06, 0.20),
		neck = CF(0, -0.10, 1.30),
		back = CF(0, 0.35, -1.40),
		build = function(c, p)
			c:round(V(1.50, 1.40, 2.50), CF(0, 0.35, -0.10), p.base)
			c:round(V(1.10, 1.00, 0.30), CF(0, 0.35, 1.15), p.light)
			c:eyes(0.48, 1.28, 0.26, 0.15)
			smile(c, 0.15, 1.30, 0.22)
			cheeks(c, 0.24, 1.29, 0.40)
			for _, z in ipairs({ 0.40, -0.60 }) do
				c:box(V(1.54, 1.44, 0.12), CF(0, 0.35, z), p.dark)
			end
			-- Tail fins.
			c:box(V(0.08, 0.60, 0.60), CF(0, 1.18, -1.20), p.deep)
			c:box(V(0.08, 0.50, 0.60), CF(0, -0.42, -1.20), p.deep)
			for _, s in ipairs(SIDES) do
				c:box(V(0.60, 0.08, 0.60), CF(0.80 * s, 0.35, -1.20), p.deep)
				-- A glowing compass emblem on each flank, and the gondola's hangers.
				c:cyl(V(0.04, 0.50, 0.50), CF(0.77 * s, 0.40, 0), p.glow, NEON)
				c:rod(V(0.25 * s, -0.30, 0.25), V(0.30 * s, -0.55, 0.25), 0.03, BROWN, nil, false)
			end
			-- The gondola, its lantern and windows, and the propeller.
			c:box(V(0.70, 0.36, 1.00), CF(0, -0.70, 0), BROWN, WOOD)
			c:ball(V(0.20, 0.24, 0.20), CF(0, -0.72, 0.56), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V(0.04, 0.12, 0.16), CF(0.36 * s, -0.66, 0.15), p.glow, NEON)
			end
			c:cyl(V(0.12, 0.12, 0.12), CF(0, -0.70, -0.56) * FACING, SILVER, METAL)
			for _, a in ipairs({ 0.5, 2.07 }) do
				c:box(V(0.10, 0.60, 0.04), CF(0, -0.70, -0.62) * ANG(0, 0, a), p.dark)
			end
			-- Puffs of cloud drifting by.
			for _, v in ipairs({ { -1.00, -0.60, 0.50 }, { 1.00, -0.40, -0.60 } }) do
				c:round(V(0.50, 0.30, 0.40), CF(v[1], v[2], v[3]), WHITE)
			end
		end,
	}

	-- A heart-shaped locket swung open, a glowing keepsake inside, flying on little wings.
	S.lf_t_locket = {
		label = "Heart Locket",
		set = "lost_and_found",
		tint = C3(240, 80, 140),
		scale = 1.1,
		head = CF(0, 1.42, 0.10),
		neck = CF(0, -0.80, 0.40),
		back = CF(0, 0.20, -0.60),
		build = function(c, p)
			local function heart(cf, col)
				c:box(V(1.10, 1.10, 0.40), cf * ANG(0, 0, PI / 4), col, METAL)
				for _, s in ipairs(SIDES) do
					c:cyl(V(0.40, 1.10, 1.10), cf * CF(0.39 * s, 0.39, 0) * FACING, col, METAL)
				end
			end
			heart(CF(0, 0, 0.20), p.base)
			-- The back half, hinged at the left and swung open behind.
			local back = CF(-0.94, 0, 0.20) * ANG(0, 0.55, 0) * CF(0.94, 0, -0.42)
			heart(back, p.dark)
			c:box(V(0.76, 0.76, 0.04), back * CF(0, 0.05, 0.22) * ANG(0, 0, PI / 4), p.glow, NEON)
			c:cyl(V(0.05, 0.50, 0.50), back * CF(0, 0.10, 0.25) * FACING, p.pale)
			-- Face on the front, and a gem at its point.
			c:eyes(0.18, 0.50, 0.30, 0.17)
			smile(c, -0.16, 0.42, 0.24)
			cheeks(c, -0.02, 0.41, 0.50)
			c:ball(V(0.20, 0.20, 0.16), CF(0, -0.46, 0.42), p.glow, NEON)
			-- The bail and its chain looping up.
			c:cyl(V(0.10, 0.30, 0.30), CF(0, 0.86, 0.20), GOLD, METAL)
			c:rod(V(0, 0.98, 0.20), V(-0.40, 1.32, 0.10), 0.04, GOLD, METAL, false)
			c:rod(V(-0.40, 1.32, 0.10), V(0.40, 1.32, 0.10), 0.04, GOLD, METAL, false)
			c:rod(V(0.40, 1.32, 0.10), V(0, 0.98, 0.20), 0.04, GOLD, METAL, false)
			-- Little wings, and two tiny hearts floating near.
			for _, s in ipairs(SIDES) do
				c:box(V(0.60, 0.36, 0.08), CF(1.06 * s, 0.40, 0.10) * ANG(0, 0, 0.4 * s), p.pale)
				c:box(V(0.44, 0.26, 0.08), CF(1.08 * s, 0.10, 0.10) * ANG(0, 0, 0.15 * s), p.pale)
				c:box(V(0.16, 0.16, 0.06), CF(1.15 * s, 1.05, 0.30) * ANG(0, 0, PI / 4), p.glow, NEON)
			end
			c:sparkle(p.glow, 3, 0.4, 0.15)
		end,
	}

	-- A ship's anchor lost on the sea bed, grown cosy with barnacles and glowing kelp.
	S.lf_t_anchor = {
		label = "Barnacle Anchor",
		set = "lost_and_found",
		tint = C3(60, 130, 140),
		scale = 1.15,
		head = CF(0, 1.72, 0),
		neck = CF(0, -0.30, 0.42),
		back = CF(0, 0.20, -0.36),
		build = function(c, p)
			c:box(V(0.70, 2.00, 0.60), CF(0, 0.10, 0), p.base, METAL)
			c:eyes(0.40, 0.34, 0.18, 0.12)
			smile(c, 0.12, 0.31, 0.18)
			-- The ring at the top and the cross stock.
			c:cyl(V(0.14, 0.64, 0.64), CF(0, 1.36, 0), p.light, METAL)
			c:cyl(V(0.16, 0.30, 0.30), CF(0, 1.36, 0), p.deep)
			c:box(V(1.90, 0.24, 0.24), CF(0, 0.95, 0), p.dark, METAL)
			for _, s in ipairs(SIDES) do
				c:ball(V(0.30, 0.30, 0.30), CF(1.00 * s, 0.95, 0), p.dark, METAL)
				-- The curved arms and their flukes.
				c:rod(V(0, -0.82, 0), V(0.75 * s, -0.66, 0), 0.14, p.base, METAL, false)
				c:rod(V(0.75 * s, -0.66, 0), V(0.95 * s, -0.20, 0), 0.14, p.base, METAL, false)
				c:cone(V(0.40, 0.46, 0.24), CF(0.98 * s, 0.02, 0) * ANG(0, 0, -0.3 * s), p.base, METAL)
			end
			c:ball(V(0.44, 0.44, 0.44), CF(0, -0.84, 0), p.base, METAL)
			-- Barnacles, a starfish on the stock, glowing kelp winding up.
			for _, v in ipairs({ { 0.24, -0.30, 0.30 }, { -0.24, 0.70, 0.30 }, { -0.80, -0.66, 0.12 } }) do
				c:ball(V(0.16, 0.12, 0.16), CF(v[1], v[2], v[3]), IVORY)
			end
			for _, a in ipairs({ 0, 1.26, 2.51 }) do
				c:box(V(0.06, 0.36, 0.08), CF(0.62, 0.95, 0.14) * ANG(0, 0, a), ORANGE)
			end
			c:rod(V(0.36, -0.70, 0.20), V(0.42, 0.00, 0.34), 0.05, p.glow, NEON, false)
			c:rod(V(0.42, 0.00, 0.34), V(0.30, 0.60, 0.32), 0.05, p.glow, NEON, false)
			c:rod(V(-0.36, -0.60, 0.20), V(-0.44, 0.10, 0.32), 0.05, p.glow, NEON, false)
			-- A glowing pearl in its crown, a sandy mound, bubbles.
			c:ball(V(0.26, 0.26, 0.26), CF(0, -0.84, 0.24), p.glow, NEON)
			c:cyl(V(0.14, 1.30, 1.30), CF(0, -1.06, 0) * UP, SAND)
			for _, v in ipairs({ { 0.55, 1.50, 0.20 }, { 0.75, 1.80, 0.10 } }) do
				c:ball(V(0.18, 0.18, 0.18), CF(v[1], v[2], v[3]), WATER, GLASS)
			end
			c:light(p.glow, 1, 6)
		end,
	}

	-- A puzzle box from a hidden chamber, half solved: blocks slid out, light leaking from its seams.
	S.lf_t_puzzlebox = {
		label = "Riddle Puzzlebox",
		set = "lost_and_found",
		tint = C3(150, 60, 200),
		scale = 1.15,
		head = CF(0.30, 1.04, 0.30),
		neck = CF(0, -0.50, 0.84),
		back = CF(0, 0.20, -0.84),
		build = function(c, p)
			c:box(V(1.60, 1.60, 1.60), CF(0, 0.20, 0), p.base, WOOD)
			c:box(V(0.80, 0.50, 0.80), CF(-0.40, 1.15, -0.40), p.light, WOOD)
			c:box(V(0.78, 0.05, 0.78), CF(-0.40, 0.92, -0.40), p.glow, NEON)
			c:box(V(0.40, 0.80, 0.80), CF(1.00, 0.40, -0.30), p.dark, WOOD)
			c:box(V(0.80, 0.40, 0.60), CF(0.35, -0.75, 0.30), p.light, WOOD)
			-- Glowing seams and a rune.
			c:box(V(1.62, 0.05, 0.05), CF(0, -0.40, 0.81), p.glow, NEON)
			c:box(V(0.05, 1.20, 0.05), CF(0.62, 0.40, 0.81), p.glow, NEON)
			c:box(V(0.05, 0.05, 1.62), CF(-0.81, 0.60, 0), p.glow, NEON)
			c:box(V(0.05, 0.30, 0.30), CF(-0.81, 0.10, -0.20) * ANG(PI / 4, 0, 0), p.glow, NEON)
			-- Brass corner caps.
			for _, s in ipairs(SIDES) do
				for _, y in ipairs({ -0.56, 0.96 }) do
					c:box(V(0.24, 0.24, 0.24), CF(0.72 * s, y, 0.72), GOLD, METAL)
				end
			end
			c:eyes(0.40, 0.84, 0.30, 0.17)
			smile(c, 0.02, 0.82, 0.26)
			cheeks(c, 0.10, 0.81, 0.48)
			-- Little cubes orbiting it, and the glowing key that opens it.
			for _, v in ipairs({ { -1.22, 0.80, 0.30, true }, { 1.25, 1.20, 0.20, false }, { -1.10, -0.50, -0.40, false }, { 0.90, -0.90, 0.70, true } }) do
				c:box(V(0.22, 0.22, 0.22), CF(v[1], v[2], v[3]) * ANG(0.6, 0.6, 0), v[4] and p.glow or p.light, v[4] and NEON or nil)
			end
			c:box(V(0.08, 0.46, 0.08), CF(0.55, 1.62, 0.20) * ANG(0, 0, 0.5), p.glow, NEON)
			c:cyl(V(0.06, 0.24, 0.24), CF(0.44, 1.84, 0.20), p.glow, NEON)
			c:light(p.glow, 1, 6)
		end,
	}

	----------------------------------------------------------------------------
	-- DIVINE: fables and legends.
	----------------------------------------------------------------------------

	-- A little lighthouse that wandered off its rock, lamp still guiding lost things home.
	S.lf_t_lighthouse = {
		label = "Lost Lighthouse",
		set = "lost_and_found",
		tint = C3(60, 100, 210),
		scale = 1.3,
		head = CF(0, 2.38, 0),
		neck = CF(0, -0.30, 0.66),
		back = CF(0, 0.10, -0.66),
		build = function(c, p)
			c:box(V(1.40, 0.70, 1.40), CF(0, -0.60, 0), p.base)
			c:box(V(1.20, 0.70, 1.20), CF(0, 0.10, 0), p.pale)
			c:box(V(1.00, 0.60, 1.00), CF(0, 0.75, 0), p.base)
			c:eyes(0.22, 0.62, 0.26, 0.15)
			smile(c, -0.10, 0.61, 0.22)
			cheeks(c, -0.02, 0.61, 0.44)
			c:box(V(0.36, 0.50, 0.04), CF(0, -0.70, 0.71), p.deep)
			for _, s in ipairs(SIDES) do
				c:box(V(0.04, 0.20, 0.16), CF(0.51 * s, 0.80, 0.10), p.glow, NEON)
			end
			-- The gallery, the lamp room and its great light.
			c:box(V(1.40, 0.12, 1.40), CF(0, 1.10, 0), p.dark)
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(V(0.06, 0.24, 0.06), CF(0.66 * s, 1.28, 0.66 * t), p.dark)
				end
			end
			local room = c:box(V(0.80, 0.60, 0.80), CF(0, 1.46, 0), C3(255, 250, 220), GLASS)
			room.Transparency = 0.3
			c:ball(V(0.50, 0.50, 0.50), CF(0, 1.46, 0), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				local beam = c:box(V(0.80, 0.26, 0.06), CF(0.80 * s, 1.46, 0.10) * ANG(0, 0.3 * s, 0), p.glow, NEON)
				beam.Transparency = 0.5
			end
			c:cone(V(1.00, 0.50, 1.00), CF(0, 2.01, 0), p.deep)
			c:ball(V(0.20, 0.20, 0.20), CF(0, 2.32, 0), GOLD, METAL)
			-- Its rocks, a lapping wave, and a gull keeping it company.
			for _, v in ipairs({ { 0.70, -0.90, 0.50, 0.50 }, { -0.75, -0.88, -0.30, 0.56 }, { 0.30, -0.92, -0.75, 0.44 } }) do
				c:round(V(v[4], v[4] * 0.6, v[4]), CF(v[1], v[2], v[3]), STONE, SLATE)
			end
			c:box(V(0.60, 0.10, 0.14), CF(-0.55, -0.92, 0.72), WATER)
			for _, s in ipairs(SIDES) do
				c:box(V(0.24, 0.05, 0.08), CF(0.85 + 0.10 * s, 0.70, 0.30) * ANG(0, 0, -0.35 * s), WHITE)
			end
			c:light(p.glow, 2, 10)
		end,
	}

	-- The wishing apple from the old tale, glowing, flying on two little wings, a worm friend peeking out of the bite.
	S.lf_t_apple = {
		label = "Wishing Apple",
		set = "lost_and_found",
		tint = C3(230, 30, 60),
		scale = 1.1,
		head = CF(0, 1.56, 0),
		neck = CF(0, -0.50, 0.78),
		back = CF(0, 0.10, -0.86),
		build = function(c, p)
			c:ball(V(1.70, 1.60, 1.70), CF(0, 0.05, 0), p.base)
			for _, s in ipairs(SIDES) do
				c:ball(V(0.90, 0.70, 1.00), CF(0.38 * s, 0.60, 0), p.base)
			end
			c:rod(V(0, 0.80, 0), V(0.10, 1.20, 0), 0.06, BROWN, nil, false)
			c:box(V(0.50, 0.06, 0.28), CF(0.36, 1.10, 0) * ANG(0, 0, 0.4), LEAF)
			-- Face.
			c:eyes(0.20, 0.80, 0.30, 0.16)
			smile(c, -0.10, 0.84, 0.24)
			cheeks(c, 0.02, 0.78, 0.52)
			-- A bite out of one side, and a tiny inchworm peeking out.
			c:round(V(0.30, 0.60, 0.50), CF(0.78, -0.10, 0.30), p.pale)
			c:round(V(0.22, 0.22, 0.22), CF(0.92, 0.06, 0.38), C3(150, 220, 90))
			c:round(V(0.18, 0.16, 0.16), CF(0.90, -0.12, 0.40), C3(130, 200, 80))
			-- Wings, a halo, sparkles and glowing seeds.
			for _, s in ipairs(SIDES) do
				c:box(V(0.80, 0.50, 0.08), CF(1.05 * s, 0.30, -0.10) * ANG(0, 0, 0.35 * s), p.pale)
				c:box(V(0.56, 0.30, 0.08), CF(1.10 * s, 0.00, -0.10) * ANG(0, 0, 0.12 * s), p.pale)
				c:star(V(0.95 * s, 1.10, 0.30), 0.30, p.glow)
			end
			c:cyl(V(0.06, 0.90, 0.90), CF(0, 1.45, 0) * UP, p.glow, NEON)
			for _, v in ipairs({ { -0.80, -0.60, 0.50 }, { 0.70, -0.80, -0.30 }, { -0.30, -0.95, -0.50 } }) do
				c:ball(V(0.12, 0.16, 0.12), CF(v[1], v[2], v[3]), p.glow, NEON)
			end
			c:light(p.glow, 1.5, 8)
		end,
	}

	-- The glass slipper left on the palace steps at midnight, sparkling, still looking for its owner.
	S.lf_t_slipper = {
		label = "Glass Slipper",
		set = "lost_and_found",
		tint = C3(170, 220, 255),
		scale = 1.1,
		head = CF(0, 0.66, -0.80),
		neck = CF(0, -0.60, 1.10),
		back = CF(0, 0.30, -1.05),
		build = function(c, p)
			c:box(V(1.20, 0.14, 2.20), CF(0, -0.45, 0.05) * ANG(0.3, 0, 0), p.dark, GLASS)
			c:round(V(1.20, 0.80, 1.10), CF(0, -0.38, 0.55), p.base, GLASS)
			c:box(V(1.10, 0.80, 0.40), CF(0, 0.20, -0.80), p.base, GLASS)
			c:box(V(0.24, 0.80, 0.24), CF(0, -0.50, -0.85), p.light, GLASS)
			for _, s in ipairs(SIDES) do
				c:box(V(0.10, 0.50, 0.90), CF(0.55 * s, -0.05, -0.30), p.base, GLASS)
			end
			c:box(V(1.00, 0.04, 1.00), CF(0, -0.18, -0.30) * ANG(0.3, 0, 0), p.pale)
			-- The face on the toe, and a glowing bow on top.
			c:eyes(-0.28, 1.08, 0.26, 0.14)
			smile(c, -0.54, 1.06, 0.20)
			cheeks(c, -0.46, 1.04, 0.42)
			c:box(V(0.20, 0.18, 0.16), CF(0, 0.06, 0.62), p.glow, NEON)
			for _, s in ipairs(SIDES) do
				c:box(V(0.28, 0.22, 0.10), CF(0.22 * s, 0.06, 0.62) * ANG(0, 0, 0.4 * s), p.light, GLASS)
				c:star(V(1.00 * s, 0.50 + 0.30 * s, 0.30), 0.30, p.glow)
			end
			-- A little gold clock floating near, hands at midnight.
			c:cyl(V(0.06, 0.44, 0.44), CF(-0.95, 1.05, 0.10) * FACING, GOLD, METAL)
			c:box(V(0.04, 0.18, 0.02), CF(-0.95, 1.12, 0.14), INK)
			c:box(V(0.04, 0.12, 0.02), CF(-0.94, 1.09, 0.15), INK)
			c:light(p.glow, 1.5, 8)
			c:sparkle(p.glow, 3, 0.4, 0.15)
		end,
	}

	-- The goose from the fable, crowned, on a straw nest with one glowing golden egg.
	S.lf_t_goose = {
		label = "Golden Goose",
		set = "lost_and_found",
		tint = C3(255, 220, 90),
		scale = 1.25,
		head = CF(0, 2.12, 0.45),
		neck = CF(0, 0.10, 0.80),
		back = CF(0, 0.20, -1.10),
		build = function(c, p)
			c:round(V(1.60, 1.10, 1.90), CF(0, -0.30, -0.25), p.base)
			for _, s in ipairs(SIDES) do
				c:round(V(0.30, 0.80, 1.40), CF(0.82 * s, -0.15, -0.35) * ANG(0.15, 0, 0), p.light)
				c:box(V(0.20, 0.20, 0.60), CF(0.80 * s, 0.15, -1.05) * ANG(0.6, 0, 0), p.light)
			end
			c:cone(V(0.60, 0.50, 0.30), CF(0, 0.05, -1.25) * ANG(-1.1, 0, 0), p.base)
			-- Long neck up to the head, face, orange beak.
			c:rod(V(0, 0.05, 0.40), V(0, 0.95, 0.52), 0.26, p.base, nil, false)
			c:round(V(0.80, 0.70, 0.80), CF(0, 1.35, 0.45), p.base)
			c:eyes(1.42, 0.86, 0.20, 0.11)
			cheeks(c, 1.26, 0.85, 0.30)
			c:box(V(0.40, 0.18, 0.36), CF(0, 1.24, 0.96), ORANGE)
			-- A little gold crown with a glowing gem.
			c:cyl(V(0.20, 0.50, 0.50), CF(0, 1.80, 0.45) * UP, GOLD, METAL)
			for _, a in ipairs({ 0, 2.09, 4.19 }) do
				c:box(V(0.10, 0.20, 0.10), CF(0.20 * math.sin(a), 2.00, 0.45 + 0.20 * math.cos(a)), GOLD, METAL)
			end
			c:ball(V(0.12, 0.12, 0.12), CF(0, 1.82, 0.71), p.glow, NEON)
			-- The straw nest and its twigs, the golden egg, and its twinkle.
			c:cyl(V(0.40, 2.20, 2.20), CF(0, -0.80, -0.10) * UP, C3(200, 160, 90))
			for _, s in ipairs(SIDES) do
				c:box(V(0.70, 0.06, 0.06), CF(0.70 * s, -0.58, 0.60) * ANG(0, 0.5 * s, 0.2 * s), BROWN)
			end
			c:ball(V(0.50, 0.66, 0.50), CF(0.75, -0.36, 0.70), p.glow, NEON)
			c:star(V(1.05, 0.10, 0.80), 0.30, GOLD)
			c:light(p.glow, 1.5, 8)
		end,
	}

	----------------------------------------------------------------------------
	-- EXOTIC: the lost civilization. The most spectacular finds.
	----------------------------------------------------------------------------

	-- The guardian of a lost jungle temple, carved from jade and woken up, sun crest blazing.
	S.lf_t_jaguar = {
		label = "Jade Jaguar",
		set = "lost_and_found",
		tint = C3(40, 190, 120),
		scale = 1.15,
		head = CF(0, 1.74, 0.40),
		neck = CF(0, -0.40, 1.10),
		back = CF(0, 0.90, -0.60),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(1.90, 1.60, 2.00),
				snout = { w = 0.70, h = 0.44, d = 0.40, y = -0.20, color = p.pale, nose = INK },
				eyeY = 0.24, eyeSpread = 0.40, eyeSize = V(0.36, 0.40, 0.16),
				legSize = V(0.44, 0.40, 0.50), legY = -0.82, tail = false,
			})
			ears(c, p.base, "round")
			spots(c, p.deep, { { 0.97, 0.30, -0.30 }, { -0.97, 0.10, -0.50 }, { 0.40, 0.82, -0.40 }, { -0.35, 0.82, 0.05 } }, V(0.24, 0.24, 0.24))
			-- A long tail curling up, its tip aglow.
			c:rod(V(0, -0.10, -0.98), V(0, 0.40, -1.40), 0.12, p.base, nil, false)
			c:rod(V(0, 0.40, -1.40), V(0, 1.00, -1.30), 0.12, p.base, nil, false)
			c:ball(V(0.30, 0.30, 0.30), CF(0, 1.06, -1.28), p.glow, NEON)
			-- The temple headdress: gold band, sun disc, a glowing gem and three feathers.
			c:box(V(1.30, 0.20, 0.30), CF(0, 0.94, 0.55), GOLD, METAL)
			c:cyl(V(0.10, 0.76, 0.76), CF(0, 1.34, 0.40) * FACING, GOLD, METAL)
			c:cyl(V(0.12, 0.30, 0.30), CF(0, 1.34, 0.46) * FACING, p.glow, NEON)
			for _, a in ipairs({ -0.5, 0, 0.5 }) do
				c:box(V(0.14, 0.62, 0.06), CF(0, 1.34, 0.32) * ANG(0, 0, a) * CF(0, 0.42, 0), p.light)
			end
			-- Glowing glyph marks on its flanks, and two carved tablets floating near.
			for _, s in ipairs(SIDES) do
				c:box(V(0.04, 0.10, 0.50), CF(1.02 * s, -0.20, 0.10), p.glow, NEON)
				c:box(V(0.30, 0.40, 0.10), CF(1.30 * s, 0.80, 0.30) * ANG(0, 0.4 * s, 0.2 * s), STONE, SLATE)
			end
			c:sparkle(p.glow, 3, 0.4, 0.15)
		end,
	}

	-- The oryx of a lost desert city, a golden sun between its long horns, its saddle cloth stitched with glowing glyphs.
	S.lf_t_oryx = {
		label = "Oasis Oryx",
		set = "lost_and_found",
		tint = C3(240, 190, 120),
		scale = 1.15,
		head = CF(0, 1.10, 0.30),
		neck = CF(0, -0.30, 1.10),
		back = CF(0, 1.00, -0.40),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = V(1.80, 1.50, 2.00),
				snout = { w = 0.60, h = 0.42, d = 0.40, y = -0.20, color = p.pale, nose = INK },
				eyeY = 0.22, eyeSpread = 0.38, eyeSize = V(0.34, 0.40, 0.16),
				legSize = V(0.34, 0.60, 0.40), legY = -0.92, legColor = p.dark, tail = false,
			})
			ears(c, p.base, "tuft")
			-- Long straight horns and the sun disc between them.
			for _, s in ipairs(SIDES) do
				c:rod(V(0.25 * s, 0.75, 0.10), V(0.45 * s, 1.85, -0.35), 0.06, p.deep, nil, false)
			end
			c:cyl(V(0.10, 0.60, 0.60), CF(0, 1.45, -0.15) * FACING, GOLD, METAL)
			c:cyl(V(0.12, 0.30, 0.30), CF(0, 1.45, -0.11) * FACING, p.glow, NEON)
			-- The saddle cloth with its glowing glyph hems.
			c:box(V(1.90, 0.12, 1.00), CF(0, 0.84, -0.20), p.light)
			for _, s in ipairs(SIDES) do
				c:box(V(0.06, 0.50, 1.00), CF(0.96 * s, 0.56, -0.20), p.light)
				c:box(V(0.04, 0.08, 0.90), CF(1.00 * s, 0.36, -0.20), p.glow, NEON)
				for _, z in ipairs({ 0.42, -0.42 }) do
					c:box(V(0.38, 0.08, 0.44), CF(0.56 * s, -1.02, z), GOLD, METAL)
				end
			end
			-- Tail with a dark tuft, and two glyph tiles floating near.
			c:box(V(0.12, 0.50, 0.12), CF(0, 0.10, -1.05) * ANG(0.3, 0, 0), p.base)
			c:box(V(0.18, 0.24, 0.18), CF(0, -0.18, -1.14), p.deep)
			for _, s in ipairs(SIDES) do
				c:box(V(0.24, 0.24, 0.04), CF(1.25 * s, 1.10, 0.30) * ANG(0, 0, PI / 4), p.glow, NEON)
			end
			c:sparkle(p.glow, 3, 0.4, 0.15)
		end,
	}

	-- A great bird of a lost sky-city, wings raised, a golden sun crest behind its head.
	S.lf_t_condor = {
		label = "Sunmask Condor",
		set = "lost_and_found",
		tint = C3(230, 110, 40),
		scale = 1.2,
		head = CF(0, 1.56, -0.10),
		neck = CF(0, 0.00, 0.62),
		back = CF(0, 0.30, -0.70),
		build = function(c, p)
			-- Its carved perch, glyphs glowing.
			c:box(V(0.90, 0.90, 0.90), CF(0, -0.60, 0), p.pale, SLATE)
			c:box(V(1.10, 0.20, 1.10), CF(0, -1.12, 0), p.dark, SLATE)
			for _, y in ipairs({ -0.45, -0.70 }) do
				c:box(V(0.50, 0.06, 0.04), CF(0, y, 0.46), p.glow, NEON)
			end
			-- Body, ruff, face and hooked golden beak.
			c:round(V(1.20, 1.10, 1.00), CF(0, 0.40, 0), p.base)
			c:box(V(1.30, 0.30, 1.10), CF(0, -0.02, 0), p.pale)
			c:eyes(0.58, 0.50, 0.24, 0.13)
			c:box(V(0.26, 0.22, 0.30), CF(0, 0.34, 0.62), GOLD, METAL)
			c:cone(V(0.20, 0.20, 0.16), CF(0, 0.16, 0.72) * ANG(PI, 0, 0), GOLD, METAL)
			c:ball(V(0.16, 0.16, 0.10), CF(0, -0.02, 0.57), p.glow, NEON)
			-- The sun crest rising behind its head.
			c:cyl(V(0.10, 0.90, 0.90), CF(0, 1.05, -0.12) * FACING, GOLD, METAL)
			for k = 0, 4 do
				local a = k * PI / 4
				c:box(V(0.12, 0.30, 0.08), CF(0.58 * math.cos(a), 1.05 + 0.58 * math.sin(a), -0.14) * ANG(0, 0, a - PI / 2), GOLD, METAL)
			end
			c:cyl(V(0.12, 0.30, 0.30), CF(0, 1.05, -0.06) * FACING, p.glow, NEON)
			-- Raised wings with glowing glyph bands, golden talons.
			for _, s in ipairs(SIDES) do
				local wing = CF(0.85 * s, 0.80, -0.25) * ANG(0, 0, 0.75 * s)
				c:box(V(1.20, 0.60, 0.12), wing, p.dark)
				c:box(V(0.90, 0.08, 0.14), wing * CF(0.05 * s, 0.10, 0), p.glow, NEON)
				c:box(V(0.80, 0.30, 0.12), wing * CF(0.10 * s, -0.38, 0), p.deep)
				c:box(V(0.20, 0.16, 0.30), CF(0.22 * s, -0.16, 0.40), GOLD, METAL)
				-- Glyph tablets drifting by.
				c:box(V(0.28, 0.36, 0.08), CF(1.05 * s, -0.62, 0.50) * ANG(0, 0.4 * s, 0.15 * s), STONE, SLATE)
			end
			c:box(V(0.60, 0.20, 0.60), CF(0, -0.05, -0.65) * ANG(0.4, 0, 0), p.dark)
			c:sparkle(p.glow, 3, 0.4, 0.15)
		end,
	}

	-- A capybara soaking in the glowing bath of a lost temple, an orange balanced on its head.
	S.lf_t_capybara = {
		label = "Ruin Capybara",
		set = "lost_and_found",
		tint = C3(190, 130, 70),
		scale = 1.1,
		head = CF(0, 1.02, 0.20),
		neck = CF(0, -0.30, 1.14),
		back = CF(0, 0.30, -0.86),
		build = function(c, p)
			-- The stone basin, its glowing water, the front step.
			c:box(V(2.20, 0.50, 2.20), CF(0, -0.70, 0), STONE, SLATE)
			c:box(V(1.90, 0.04, 1.90), CF(0, -0.43, 0), p.glow, NEON)
			c:box(V(0.80, 0.20, 0.30), CF(0, -0.85, 1.22), STONE, SLATE)
			-- The capybara: square body, big blunt snout, little ears.
			c:box(V(1.40, 1.00, 1.60), CF(0, 0.10, -0.05), p.base)
			c:box(V(0.90, 0.50, 0.40), CF(0, -0.05, 0.92), p.light)
			c:eyes(0.38, 0.78, 0.32, 0.12)
			for _, s in ipairs(SIDES) do
				c:box(V(0.08, 0.06, 0.04), CF(0.16 * s, 0.08, 1.13), INK)
				c:box(V(0.24, 0.20, 0.14), CF(0.50 * s, 0.68, 0.40), p.dark)
				c:box(V(0.04, 0.30, 0.60), CF(0.71 * s, 0.10, -0.20), p.glow, NEON)
			end
			smile(c, -0.14, 1.13, 0.22)
			-- An orange on its head, with a leaf.
			c:ball(V(0.36, 0.34, 0.36), CF(0, 0.76, 0.20), ORANGE)
			c:box(V(0.18, 0.04, 0.10), CF(0.08, 0.95, 0.20) * ANG(0, 0, 0.4), LEAF)
			-- Four ruined pillars round the bath, their tops aglow.
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(V(0.30, 0.80, 0.30), CF(0.95 * s, -0.30, 0.95 * t), STONE, SLATE)
					c:box(V(0.22, 0.10, 0.22), CF(0.95 * s, 0.15, 0.95 * t), p.glow, NEON)
				end
			end
			-- Bubbles rising from the water.
			for _, v in ipairs({ { -0.75, -0.30, 0.55 }, { 0.70, -0.20, 0.70 } }) do
				c:ball(V(0.14, 0.14, 0.14), CF(v[1], v[2], v[3]), WATER, GLASS)
			end
			c:light(p.glow, 1.5, 8)
			c:sparkle(p.glow, 3, 0.4, 0.15)
		end,
	}

	return S
end
