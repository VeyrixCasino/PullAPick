--[[ PetBodies/DragonfallExtra -- more recolour bodies for Dragonfall's Common,
	Uncommon and Rare pets, so two pets on one body can wear vastly different
	colours. Hoard and dragon-lore things rather than more dragons: a dragon
	fruit, a dragon vase, a gold ingot and a dragon spinning top.
	See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, METAL, NEON = K.INK, K.METAL, K.NEON
	local S = {}
	local SIDES = { -1, 1 }
	local V3, CF, ANG = Vector3.new, CFrame.new, CFrame.Angles
	local PI = math.pi

	-- Treasure, bone and the fossil's amber glow stay fixed; scales repaint.
	local GOLD = C3(246, 196, 64)
	local COIN = C3(255, 218, 96)
	local SAPPHIRE = C3(70, 150, 255)
	local CLOUD = C3(240, 244, 252)
	local LEAF = C3(86, 170, 70)
	local SET = "dragonfall"

	-- A dragon fruit with a face: round and plump, its scale-like bracts
	-- curling up its sides and back, a leafy crown and little feet.
	S.df_pitaya = {
		label = "Pitaya Pal",
		set = SET,
		tint = C3(240, 60, 140),
		head = CF(0, 1.10, 0),
		neck = CF(0, -0.36, 0.84),
		back = CF(0, 0.20, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V3(1.60, 1.70, 1.50),
				eyeY = 0.14, eyeSpread = 0.38, eyeSize = V3(0.42, 0.50, 0.20),
				mouthY = -0.26,
				legSize = V3(0.36, 0.22, 0.40), legX = 0.42, legZ = { 0.10 }, legY = -0.82, legColor = p.dark,
				tail = false,
			})
			for _, s in ipairs(SIDES) do
				c:cone(V3(0.30, 0.40, 0.12), CF(0.82 * s, -0.30, 0.30) * ANG(0, 0, -0.35 * s), p.light)
				c:cone(V3(0.30, 0.40, 0.12), CF(0.82 * s, 0.30, -0.25) * ANG(0, 0, -0.35 * s), p.light)
				c:cone(V3(0.30, 0.40, 0.12), CF(0.40 * s, -0.50, -0.78) * ANG(-0.3, 0, -0.2 * s), p.light)
				c:box(V3(0.20, 0.12, 0.04), CF(0.55 * s, -0.10, 0.76), p.pale)
				c:cone(V3(0.20, 0.44, 0.16), CF(0.22 * s, 0.98, 0) * ANG(0, 0, -0.45 * s), LEAF)
			end
			c:cone(V3(0.30, 0.40, 0.12), CF(0, 0.25, -0.80) * ANG(-0.3, 0, 0), p.light)
			c:cone(V3(0.24, 0.54, 0.20), CF(0, 1.02, 0), LEAF)
			c:cone(V3(0.20, 0.40, 0.16), CF(0, 0.96, -0.22) * ANG(-0.4, 0, 0), LEAF)
		end,
	}

	-- A dragon vase from the treasure hall: a round painted pot with a face,
	-- a band of painted scales, dragon-neck handles and a coin left inside.
	S.df_vase = {
		label = "Wyrm Vase",
		set = SET,
		tint = C3(60, 110, 220),
		head = CF(0, 1.12, 0),
		neck = CF(0, -0.40, 0.80),
		back = CF(0, 0.10, -0.80),
		build = function(c, p)
			c:box(V3(1.00, 0.20, 1.00), CF(0, -0.95, 0), p.dark)
			c:box(V3(1.60, 1.10, 1.50), CF(0, -0.25, 0), p.base)
			c:box(V3(1.20, 0.30, 1.10), CF(0, 0.45, 0), p.light)
			c:box(V3(0.70, 0.40, 0.70), CF(0, 0.78, 0), p.base)
			c:box(V3(0.90, 0.12, 0.90), CF(0, 1.02, 0), p.dark)
			c:box(V3(1.62, 0.20, 1.52), CF(0, -0.58, 0), p.pale)
			for _, x in ipairs({ -0.45, 0, 0.45 }) do
				c:box(V3(0.14, 0.14, 0.04), CF(x, -0.58, 0.77) * ANG(0, 0, PI / 4), p.dark)
			end
			c:eyes(0.0, 0.77, 0.36, 0.17)
			c:box(V3(0.30, 0.06, 0.04), CF(0, -0.26, 0.76), INK)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.14, 0.50, 0.20), CF(0.88 * s, 0.25, 0), p.dark)
				c:box(V3(0.20, 0.16, 0.26), CF(0.92 * s, 0.53, 0.05), p.dark)
			end
			c:cyl(V3(0.06, 0.34, 0.34), CF(0.10, 1.12, 0) * ANG(0.2, 0, 1.3), COIN, METAL)
		end,
	}

	-- A bar of hoard gold that woke up: a stepped ingot with a stamp on top,
	-- a face on its front, little cheeks and four stubby feet.
	S.df_ingot = {
		label = "Hoard Ingot",
		set = SET,
		tint = C3(246, 196, 64),
		head = CF(0, 0.42, 0),
		neck = CF(0, -0.70, 0.70),
		back = CF(0, -0.20, -0.66),
		build = function(c, p)
			c:box(V3(1.80, 0.80, 1.30), CF(0, -0.55, 0), p.base, METAL)
			c:box(V3(1.40, 0.50, 0.95), CF(0, 0.10, 0), p.base, METAL)
			c:box(V3(1.84, 0.08, 1.34), CF(0, -0.17, 0), p.light, METAL)
			c:box(V3(1.44, 0.06, 0.99), CF(0, 0.33, 0), p.light, METAL)
			c:box(V3(0.50, 0.04, 0.30), CF(0, 0.37, 0), p.dark)
			c:eyes(-0.42, 0.67, 0.40, 0.16)
			c:box(V3(0.30, 0.06, 0.04), CF(0, -0.72, 0.66), INK)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.18, 0.10, 0.04), CF(0.66 * s, -0.66, 0.66), p.pale)
				for _, z in ipairs({ 0.40, -0.40 }) do
					c:box(V3(0.30, 0.16, 0.30), CF(0.60 * s, -1.02, z), p.dark)
				end
			end
			c:box(V3(0.18, 0.18, 0.18), CF(0.40, 0.48, 0.10) * ANG(0.5, 0.5, 0), SAPPHIRE, NEON)
		end,
	}

	-- A spinning top painted like a little dragon: a wide body with a face,
	-- winglet fins, horn nubs, a gold tip, a knob to spin it by and swooshes
	-- of air as it whirls.
	S.df_spintop = {
		label = "Drakespin Top",
		set = SET,
		tint = C3(80, 200, 120),
		head = CF(0, 1.30, 0),
		neck = CF(0, -0.40, 0.86),
		back = CF(0, 0.10, -0.86),
		build = function(c, p)
			c:box(V3(1.70, 0.80, 1.70), CF(0, 0.10, 0), p.base)
			c:cone(V3(1.50, 0.90, 1.50), CF(0, -0.75, 0) * ANG(PI, 0, 0), p.dark)
			c:cone(V3(0.20, 0.20, 0.20), CF(0, -1.28, 0) * ANG(PI, 0, 0), GOLD, METAL)
			c:box(V3(1.20, 0.20, 1.20), CF(0, 0.60, 0), p.light)
			c:cyl(V3(0.50, 0.24, 0.24), CF(0, 0.95, 0) * ANG(0, 0, PI / 2), p.dark)
			c:ball(V3(0.30, 0.30, 0.30), CF(0, 1.25, 0), p.glow)
			c:box(V3(1.74, 0.14, 1.74), CF(0, -0.22, 0), p.pale)
			c:eyes(0.14, 0.87, 0.38, 0.17)
			c:box(V3(0.30, 0.06, 0.04), CF(0, -0.08, 0.86), INK)
			for _, s in ipairs(SIDES) do
				c:box(V3(0.50, 0.10, 0.40), CF(1.05 * s, 0.10, -0.20) * ANG(0, 0, 0.30 * s), p.light)
				c:cone(V3(0.14, 0.26, 0.14), CF(0.38 * s, 0.82, 0.30), p.pale)
				c:box(V3(0.80, 0.06, 0.10), CF(0.95 * s, -0.55, 0.60) * ANG(0, 0.6 * s, 0), CLOUD)
			end
		end,
	}

	return S
end
