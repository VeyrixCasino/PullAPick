--[[ PetBodies/RoyalReserveExtra -- more Royal Reserve recolour bodies. See tools/gen/sets/README.md.
	Common to Rare pets share these, each in a VASTLY different colour, so the
	main colour is always p.*; gold trim stays fixed, the set's signature.
	Things you would find on a dressing table or in a jeweller's window. ]]
return function(K)
	local C3 = K.C3
	local METAL, INK = K.METAL, K.INK
	local GOLD = C3(240, 194, 70)
	local GOLD_DK = C3(196, 146, 48)
	local BLUSH = C3(255, 150, 172)
	local SIDES = { -1, 1 }
	local S = {}

	-- A tufted footstool on four gold cabriole legs.
	S.rr_tuffet = {
		label = "Tuffet",
		set = "royal_reserve",
		tint = C3(150, 60, 170),
		head = CFrame.new(0, 1.00, 0),
		neck = CFrame.new(0, -0.40, 0.92),
		back = CFrame.new(0, 0.10, -0.86),
		build = function(c, p)
			c:box(Vector3.new(1.90, 0.70, 1.70), CFrame.new(0, 0.05, 0), p.base) -- cushion
			c:box(Vector3.new(1.60, 0.26, 1.40), CFrame.new(0, 0.52, 0), p.light) -- domed top
			c:box(Vector3.new(1.96, 0.24, 1.76), CFrame.new(0, -0.38, 0), p.dark) -- skirt
			c:box(Vector3.new(2.00, 0.06, 1.80), CFrame.new(0, -0.52, 0), GOLD, METAL) -- piping
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(Vector3.new(0.14, 0.08, 0.14), CFrame.new(0.40 * s, 0.67, 0.34 * t), p.deep) -- buttons
					c:box(Vector3.new(0.22, 0.56, 0.22), CFrame.new(0.72 * s, -0.66, 0.58 * t) * CFrame.Angles(-0.12 * t, 0, 0.12 * s), GOLD, METAL)
				end
			end
			c:eyes(0.10, 0.89, 0.40, 0.15)
			c:box(Vector3.new(0.24, 0.07, 0.06), CFrame.new(0, -0.16, 0.86), INK)
		end,
	}

	-- A polished cabochon gem held in a gold bezel, its prongs for feet.
	S.rr_cabochon = {
		label = "Cabochon",
		set = "royal_reserve",
		tint = C3(40, 170, 120),
		head = CFrame.new(0, 1.10, 0),
		neck = CFrame.new(0, -0.40, 0.86),
		back = CFrame.new(0, 0.10, -0.80),
		build = function(c, p)
			c:box(Vector3.new(1.70, 0.80, 1.50), CFrame.new(0, 0.05, 0), p.base) -- the stone
			c:box(Vector3.new(1.34, 0.36, 1.14), CFrame.new(0, 0.58, 0), p.light) -- its dome
			c:box(Vector3.new(0.30, 0.10, 0.20), CFrame.new(-0.30, 0.79, 0.20), p.pale) -- shine
			c:box(Vector3.new(1.86, 0.30, 1.66), CFrame.new(0, -0.42, 0), GOLD, METAL) -- bezel
			for _, s in ipairs(SIDES) do
				for _, t in ipairs(SIDES) do
					c:box(Vector3.new(0.16, 0.56, 0.16), CFrame.new(0.82 * s, 0.00, 0.70 * t), GOLD, METAL) -- prongs
					c:box(Vector3.new(0.24, 0.36, 0.24), CFrame.new(0.60 * s, -0.74, 0.50 * t), GOLD_DK, METAL) -- feet
				end
			end
			c:eyes(0.10, 0.79, 0.38, 0.15)
			c:box(Vector3.new(0.24, 0.07, 0.06), CFrame.new(0, -0.16, 0.77), INK)
		end,
	}

	-- A lipstick: jewel-coloured case, gold collar, a slanted bullet on top.
	S.rr_lipstick = {
		label = "Lipstick",
		set = "royal_reserve",
		tint = C3(220, 30, 80),
		head = CFrame.new(0, 1.60, 0),
		neck = CFrame.new(0, -0.50, 0.76),
		back = CFrame.new(0, 0.00, -0.76),
		build = function(c, p)
			c:box(Vector3.new(1.40, 1.10, 1.40), CFrame.new(0, -0.38, 0), p.dark) -- the case
			c:box(Vector3.new(1.46, 0.18, 1.46), CFrame.new(0, 0.24, 0), GOLD, METAL) -- collar
			c:box(Vector3.new(1.00, 0.70, 1.00), CFrame.new(0, 0.66, 0), p.base) -- the bullet
			c:wedge(Vector3.new(1.00, 0.50, 1.00), CFrame.new(0, 1.26, 0) * CFrame.Angles(0, math.pi, 0), p.base) -- slanted tip
			c:box(Vector3.new(0.12, 0.60, 0.04), CFrame.new(-0.30, 0.66, 0.51), p.pale) -- shine
			c:eyes(-0.30, 0.74, 0.32, 0.15)
			c:box(Vector3.new(0.24, 0.07, 0.06), CFrame.new(0, -0.58, 0.71), INK)
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.20, 0.10, 0.05), CFrame.new(0.52 * s, -0.50, 0.71), BLUSH)
				c:box(Vector3.new(0.40, 0.14, 0.50), CFrame.new(0.36 * s, -0.98, 0.10), GOLD, METAL) -- feet
			end
		end,
	}

	-- An Elizabethan lace ruff: a pleated collar round a round little body.
	S.rr_ruff = {
		label = "Lace Ruff",
		set = "royal_reserve",
		tint = C3(240, 200, 230),
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, -0.40, 1.00),
		back = CFrame.new(0, 0.30, -0.70),
		build = function(c, p)
			c:box(Vector3.new(1.30, 1.20, 1.20), CFrame.new(0, 0.30, 0), p.base)
			for i = 0, 9 do
				local a = i * math.pi / 5
				c:box(Vector3.new(0.34, 0.30, 0.60), CFrame.Angles(0, a, 0) * CFrame.new(0, -0.36, 0.78) * CFrame.Angles(0, 0, math.pi / 4), (i % 2 == 0) and p.pale or p.light) -- pleats
			end
			for _, s in ipairs(SIDES) do
				c:box(Vector3.new(0.30, 0.30, 0.40), CFrame.new(0.30 * s, -0.75, 0.10), p.dark) -- feet
				c:box(Vector3.new(0.20, 0.10, 0.05), CFrame.new(0.44 * s, 0.22, 0.61), BLUSH)
			end
			c:box(Vector3.new(1.00, 0.20, 0.90), CFrame.new(0, 0.98, 0), p.dark) -- little cap
			c:box(Vector3.new(0.10, 0.60, 0.16), CFrame.new(0.35, 1.25, -0.10) * CFrame.Angles(0, 0, -0.5), p.light) -- its feather
			c:eyes(0.42, 0.64, 0.28, 0.14)
			c:box(Vector3.new(0.22, 0.07, 0.06), CFrame.new(0, 0.15, 0.61), INK)
		end,
	}

	return S
end
