--[[ PetBodies/DivineRelicsExtra -- extra Divine Relics recolour bodies (staged 2026-10-12
	for the unique-bodies pass: recolours are Common/Uncommon/Rare only, in vastly
	different colours). Same locals as PetBodies/DivineRelics. ]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, WHITE, METAL, NEON, GLASS = K.INK, K.WHITE, K.METAL, K.NEON, K.GLASS
	local S = {}

	local GOLD = C3(246, 204, 92)
	local GEM = C3(64, 214, 226)
	local SUN = C3(255, 232, 140)
	local FLAME = C3(255, 150, 40)
	local BLUSH = C3(255, 150, 160)
	local SET = "divine_relics"

	-- A shrine bell: a stepped bronze bell with its face on the waist, a gold
	-- clapper peeking out below and a hanging loop on top.
	S.dv_bell = {
		label = "Shrine Bell",
		set = SET,
		tint = C3(200, 150, 70),
		head = CFrame.new(0, 1.50, 0),
		neck = CFrame.new(0, -0.30, 0.80),
		back = CFrame.new(0, 0.20, -0.80),
		build = function(c, p)
			c:box(Vector3.new(1.10, 0.50, 1.10), CFrame.new(0, 0.85, 0), p.light, METAL)
			c:box(Vector3.new(1.50, 1.00, 1.50), CFrame.new(0, 0.10, 0), p.base, METAL)
			c:box(Vector3.new(1.90, 0.30, 1.90), CFrame.new(0, -0.53, 0), p.dark, METAL)
			c:box(Vector3.new(1.56, 0.10, 1.56), CFrame.new(0, 0.42, 0), p.dark, METAL)
			c:cyl(Vector3.new(0.16, 0.56, 0.56), CFrame.new(0, 1.30, 0) * CFrame.Angles(0, math.pi / 2, 0), p.dark, METAL)
			c:ball(Vector3.new(0.50, 0.50, 0.50), CFrame.new(0, -0.82, 0), GOLD, METAL)
			c:eyes(0.12, 0.78, 0.34, 0.16)
			c:box(Vector3.new(0.28, 0.08, 0.06), CFrame.new(0, -0.18, 0.76), INK)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.18, 0.09, 0.04), CFrame.new(0.56 * s, -0.08, 0.76), BLUSH)
				c:box(Vector3.new(0.36, 0.36, 0.40), CFrame.new(0.58 * s, -0.86, 0.20), p.deep, METAL)
			end
		end,
	}

	-- A sage's scroll: a parchment sheet between two rollers, its face written
	-- on the page, a ribbon and wax seal hanging off the bottom roller.
	S.dv_scroll = {
		label = "Sage Scroll",
		set = SET,
		tint = C3(232, 212, 164),
		head = CFrame.new(0, 1.12, 0),
		neck = CFrame.new(0, -0.40, 0.40),
		back = CFrame.new(0, 0.10, -0.40),
		build = function(c, p)
			c:box(Vector3.new(1.50, 1.40, 0.44), CFrame.new(0, 0.04, 0), p.base)
			for _, y in ipairs({ 0.84, -0.76 }) do
				c:cyl(Vector3.new(1.84, 0.44, 0.44), CFrame.new(0, y, 0), p.dark)
				for _, s in ipairs({ -1, 1 }) do
					c:box(Vector3.new(0.14, 0.26, 0.26), CFrame.new(1.00 * s, y, 0) * CFrame.Angles(math.pi / 4, 0, 0), GOLD, METAL)
				end
			end
			c:eyes(0.30, 0.24, 0.34, 0.16)
			c:box(Vector3.new(0.28, 0.08, 0.06), CFrame.new(0, 0.00, 0.23), INK)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.18, 0.09, 0.04), CFrame.new(0.56 * s, 0.10, 0.23), BLUSH)
				c:box(Vector3.new(0.34, 0.24, 0.40), CFrame.new(0.46 * s, -1.06, 0.04), p.deep)
			end
			for _, y in ipairs({ -0.26, -0.42 }) do
				c:box(Vector3.new(0.90, 0.05, 0.04), CFrame.new(0, y, 0.23), p.deep)
			end
			c:box(Vector3.new(0.14, 0.56, 0.06), CFrame.new(0.52, -0.70, 0.27), p.light)
			c:cyl(Vector3.new(0.08, 0.30, 0.30), CFrame.new(0.52, -0.98, 0.30) * CFrame.Angles(0, math.pi / 2, 0), C3(200, 40, 50))
		end,
	}

	-- A little step pyramid on stubby feet: four tiers, a shrine door at the top
	-- under a gold capstone, and a face across its middle steps.
	S.dv_ziggurat = {
		label = "Step Pyramid",
		set = SET,
		tint = C3(214, 180, 120),
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, -0.40, 1.00),
		back = CFrame.new(0, 0.00, -0.96),
		build = function(c, p)
			c:box(Vector3.new(2.00, 0.50, 1.90), CFrame.new(0, -0.60, 0), p.dark)
			c:box(Vector3.new(1.60, 0.56, 1.50), CFrame.new(0, -0.07, 0), p.base)
			c:box(Vector3.new(1.20, 0.46, 1.10), CFrame.new(0, 0.44, 0), p.light)
			c:box(Vector3.new(0.70, 0.40, 0.66), CFrame.new(0, 0.87, 0), p.pale)
			c:box(Vector3.new(0.26, 0.28, 0.06), CFrame.new(0, 0.83, 0.34), p.deep)
			c:cone(Vector3.new(0.40, 0.30, 0.40), CFrame.new(0, 1.22, 0), GOLD, METAL)
			c:eyes(-0.04, 0.77, 0.36, 0.15)
			c:box(Vector3.new(0.40, 0.09, 0.06), CFrame.new(0, -0.48, 0.96), INK)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.18, 0.09, 0.04), CFrame.new(0.62 * s, -0.20, 0.76), BLUSH)
				for _, z in ipairs({ 0.56, -0.56 }) do
					c:box(Vector3.new(0.36, 0.24, 0.36), CFrame.new(0.66 * s, -0.96, z), p.deep)
				end
			end
		end,
	}

	-- A temple padlock: a stout lock body with an arched shackle on top, gold
	-- rivets, and a keyhole for a mouth.
	S.dv_padlock = {
		label = "Temple Padlock",
		set = SET,
		tint = C3(190, 150, 80),
		head = CFrame.new(0, 1.50, 0),
		neck = CFrame.new(0, -0.50, 0.56),
		back = CFrame.new(0, -0.10, -0.56),
		build = function(c, p)
			c:box(Vector3.new(1.60, 1.40, 0.90), CFrame.new(0, -0.20, 0), p.base, METAL)
			c:box(Vector3.new(1.30, 1.10, 0.08), CFrame.new(0, -0.20, 0.47), p.light, METAL)
			for _, s in ipairs({ -1, 1 }) do
				c:rod(Vector3.new(0.50 * s, 0.46, 0), Vector3.new(0.50 * s, 1.16, 0), 0.12, p.dark, METAL, false)
				c:ball(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0.50 * s, 1.18, 0), p.dark, METAL)
				c:box(Vector3.new(0.18, 0.09, 0.04), CFrame.new(0.48 * s, -0.20, 0.52), BLUSH)
				c:box(Vector3.new(0.40, 0.24, 0.50), CFrame.new(0.46 * s, -1.02, 0), p.deep, METAL)
				for _, y in ipairs({ 0.20, -0.60 }) do
					c:ball(Vector3.new(0.12, 0.12, 0.12), CFrame.new(0.56 * s, y, 0.52), GOLD, METAL)
				end
			end
			c:box(Vector3.new(1.00, 0.24, 0.24), CFrame.new(0, 1.30, 0), p.dark, METAL)
			c:eyes(0.06, 0.53, 0.30, 0.15)
			c:ball(Vector3.new(0.22, 0.22, 0.10), CFrame.new(0, -0.40, 0.52), INK)
			c:box(Vector3.new(0.10, 0.22, 0.04), CFrame.new(0, -0.54, 0.52), INK)
		end,
	}
	return S
end
