--[[ PetBodies/ShogunsOath -- Shogun's Oath's bodies: Japanese motifs, lacquer,
	gold leaf and honour; samurai and ninja flavour, all cute and bloodless. See
	tools/gen/sets/README.md. ]]
return function(K)
	local C3, block = K.C3, K.block
	local INK, WHITE, METAL = K.INK, K.WHITE, K.METAL
	local S = {}

	local GOLD = C3(236, 190, 76)
	local FACE_Z = CFrame.Angles(0, math.pi / 2, 0) -- turns a cylinder's X axis to face +Z

	-- A young samurai in lacquered armour: a kabuto helmet with a golden crest,
	-- turned-back wings and a flared neck guard, shoulder plates and a breastplate.
	S.so_samurai = {
		label = "Samurai",
		set = "shoguns_oath",
		tint = C3(198, 48, 54),
		-- The crest makes it tall.
		scale = 1.14,
		head = CFrame.new(0, 1.16, 0),
		neck = CFrame.new(0, -0.30, 0.66),
		back = CFrame.new(0, 0.20, -1.10),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodyColor = p.pale,
				mouthY = -0.22, mouthSize = Vector3.new(0.26, 0.12, 0.12),
				legColor = p.deep, tail = false,
			})
			-- Helmet bowl and its gold rim.
			c:box(Vector3.new(2.16, 0.44, 1.98), CFrame.new(0, 0.90, -0.04), p.base)
			c:box(Vector3.new(2.20, 0.08, 2.02), CFrame.new(0, 0.70, -0.04), GOLD, METAL)
			-- Crest: two flat golden horns rising from a crest disc.
			c:cyl(Vector3.new(0.08, 0.32, 0.32), CFrame.new(0, 0.94, 0.98) * FACE_Z, GOLD, METAL)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.13, 0.56, 0.06), CFrame.new(0.24 * s, 1.24, 0.96) * CFrame.Angles(0, 0, -0.62 * s), GOLD, METAL)
				c:box(Vector3.new(0.11, 0.52, 0.06), CFrame.new(0.50 * s, 1.66, 0.94) * CFrame.Angles(0, 0, -0.24 * s), GOLD, METAL)
				-- Fukigaeshi: the helmet's turned-back wings beside the face.
				c:box(Vector3.new(0.46, 0.42, 0.10), CFrame.new(1.16 * s, 0.84, 0.62) * CFrame.Angles(0, -0.55 * s, 0), p.base)
				-- Side flaps of the neck guard, flaring out at the bottom.
				c:box(Vector3.new(0.14, 0.60, 1.50), CFrame.new(1.12 * s, 0.46, -0.30) * CFrame.Angles(0, 0, 0.30 * s), p.base)
				-- Sode: shoulder plates with a gold lacing line.
				local sode = CFrame.new(1.16 * s, -0.22, 0.10) * CFrame.Angles(0, 0, 0.16 * s)
				c:box(Vector3.new(0.16, 0.74, 0.86), sode, p.base)
				c:box(Vector3.new(0.18, 0.05, 0.88), sode * CFrame.new(0, 0.12, 0), GOLD, METAL)
			end
			-- Rear of the neck guard, flared out.
			c:box(Vector3.new(2.30, 0.66, 0.14), CFrame.new(0, 0.44, -1.04) * CFrame.Angles(0.32, 0, 0), p.base)
			-- Breastplate with a gold edge.
			c:box(Vector3.new(1.40, 0.44, 0.12), CFrame.new(0, -0.62, 0.88), p.base)
			c:box(Vector3.new(1.42, 0.06, 0.14), CFrame.new(0, -0.42, 0.88), GOLD, METAL)
		end,
	}

	-- A ninja: hooded, only the eyes showing, a red headband whose tails stream
	-- behind, a sash, and a sheathed sword on its back with the hilt over a shoulder.
	S.so_ninja = {
		label = "Ninja",
		set = "shoguns_oath",
		tint = C3(54, 60, 104),
		head = CFrame.new(0, 1.04, 0.06),
		neck = CFrame.new(0, -0.30, 0.66),
		back = CFrame.new(0, 0.20, -0.96),
		build = function(c, p)
			local band, sheath = C3(206, 46, 58), C3(34, 30, 38)
			block(c, p, {
				shape = "round",
				eyeSize = Vector3.new(0.44, 0.46, 0.20), eyeY = 0.20, eyeSpread = 0.40,
				mouth = false, tail = false, legColor = p.deep,
			})
			-- The eye slit: a pale band of face showing through the hood.
			c:box(Vector3.new(1.70, 0.62, 0.12), CFrame.new(0, 0.20, 0.84), p.pale)
			for _, s in ipairs({ -1, 1 }) do
				-- Determined brows.
				c:box(Vector3.new(0.40, 0.08, 0.06), CFrame.new(0.40 * s, 0.48, 0.92) * CFrame.Angles(0, 0, 0.18 * s), INK)
				-- Headband tails streaming behind.
				c:box(Vector3.new(0.16, 0.06, 0.80), CFrame.new(0.16 * s, 0.54, -1.20) * CFrame.Angles(0.45, 0.30 * s, 0), band)
			end
			-- Headband, its metal plate, and the knot at the back.
			c:box(Vector3.new(1.76, 0.18, 1.56), CFrame.new(0, 0.68, 0), band)
			c:box(Vector3.new(0.50, 0.22, 0.06), CFrame.new(0, 0.68, 0.79), C3(190, 196, 206), METAL)
			c:box(Vector3.new(0.26, 0.26, 0.18), CFrame.new(0, 0.68, -0.84), band)
			-- Sash with its knot.
			c:box(Vector3.new(2.12, 0.20, 1.78), CFrame.new(0, -0.48, 0), p.dark)
			c:box(Vector3.new(0.24, 0.30, 0.14), CFrame.new(0.50, -0.56, 0.92) * CFrame.Angles(0, 0, 0.30), p.deep)
			-- Sheathed sword across the back: scabbard, guard, wrapped hilt, pommel.
			local tail, guard = Vector3.new(0.62, -0.62, -0.92), Vector3.new(-0.58, 0.86, -0.92)
			local dir = (guard - tail).Unit
			c:rod(tail, guard, 0.075, sheath, nil, false)
			c:rod(guard, guard + dir * 0.06, 0.15, GOLD, METAL, false)
			c:rod(guard + dir * 0.06, guard + dir * 0.44, 0.06, C3(236, 228, 210), nil, false)
			c:ball(Vector3.new(0.14, 0.14, 0.14), CFrame.new(guard + dir * 0.46), sheath)
		end,
	}

	-- A daruma doll: a round red tumbler with a white face, bold brows and
	-- whiskers, a weighted base, and gold-leaf marks on its sides and back.
	S.so_daruma = {
		label = "Daruma",
		set = "shoguns_oath",
		tint = C3(214, 40, 46),
		head = CFrame.new(0, 1.04, 0),
		neck = CFrame.new(0, -0.40, 0.78),
		back = CFrame.new(0, 0.16, -0.70),
		build = function(c, p)
			local face = C3(252, 244, 228)
			block(c, p, {
				shape = "round",
				eyeSize = Vector3.new(0.40, 0.44, 0.20), eyeSpread = 0.28, eyeY = 0.24,
				mouth = false, legs = false, tail = false,
			})
			-- Weighted base.
			c:box(Vector3.new(2.10, 0.56, 1.90), CFrame.new(0, -0.76, 0), p.base)
			c:box(Vector3.new(1.80, 0.20, 1.60), CFrame.new(0, -1.10, 0), p.dark)
			-- Gold-rimmed white face.
			c:round(Vector3.new(1.38, 1.12, 0.12), CFrame.new(0, 0.18, 0.86), GOLD)
			c:round(Vector3.new(1.22, 0.98, 0.12), CFrame.new(0, 0.18, 0.89), face)
			for _, s in ipairs({ -1, 1 }) do
				-- Bushy brows sweeping up, whiskers drooping.
				c:box(Vector3.new(0.42, 0.12, 0.06), CFrame.new(0.30 * s, 0.58, 0.95) * CFrame.Angles(0, 0, 0.22 * s), INK)
				c:box(Vector3.new(0.30, 0.10, 0.06), CFrame.new(0.17 * s, -0.06, 0.95) * CFrame.Angles(0, 0, -0.35 * s), INK)
				-- Gold-leaf circles on the sides.
				for _, z in ipairs({ 0.20, -0.30 }) do
					c:cyl(Vector3.new(0.06, 0.44, 0.44), CFrame.new(1.06 * s, -0.28, z), GOLD, METAL)
				end
			end
			c:box(Vector3.new(0.40, 0.10, 0.06), CFrame.new(0, -0.22, 0.95), INK)
			-- Gold diamond on the belly.
			c:box(Vector3.new(0.40, 0.40, 0.06), CFrame.new(0, -0.72, 0.97) * CFrame.Angles(0, 0, math.pi / 4), GOLD, METAL)
			-- Wave scales (seigaiha) in gold leaf on the back.
			for _, v in ipairs({ { -0.30, 0.10 }, { 0.30, 0.10 }, { 0, 0.42 } }) do
				c:cyl(Vector3.new(0.06, 0.40, 0.40), CFrame.new(v[1], v[2], -0.88) * FACE_Z, GOLD, METAL)
			end
		end,
	}

	-- A maneki-neko: a chubby sitting lucky cat with one paw raised to beckon, a
	-- red collar and gold bell, a gold koban coin held to its tummy, calico patches.
	S.so_luckycat = {
		label = "Lucky Cat",
		set = "shoguns_oath",
		tint = C3(248, 242, 230),
		head = CFrame.new(0, 1.04, 0.06),
		neck = CFrame.new(0, -0.20, 0.70),
		back = CFrame.new(0, 0.20, -0.66),
		build = function(c, p)
			local red, calico, pink = C3(214, 40, 52), C3(236, 146, 64), C3(238, 164, 176)
			block(c, p, {
				shape = "round",
				eyeY = 0.24, eyeSize = Vector3.new(0.48, 0.56, 0.20),
				snout = { w = 0.50, h = 0.30, d = 0.30, y = -0.12, color = p.light, nose = C3(240, 130, 150) },
				legSize = Vector3.new(0.42, 0.28, 0.46), legY = -0.90, legZ = { 0.36, -0.30 }, legColor = p.base,
				tail = false,
			})
			K.ears(c, p.base, "up", pink)
			for _, s in ipairs({ -1, 1 }) do
				for _, w in ipairs({ -0.5, 0.5 }) do
					c:box(Vector3.new(0.34, 0.035, 0.035), CFrame.new(0.50 * s, -0.10 + w * 0.10, 0.94) * CFrame.Angles(0, 0.35 * s, 0), INK)
				end
			end
			-- Red collar and its gold bell.
			c:box(Vector3.new(2.14, 0.16, 1.78), CFrame.new(0, -0.40, 0.02), red)
			c:ball(Vector3.new(0.28, 0.28, 0.28), CFrame.new(0, -0.54, 0.96), GOLD, METAL)
			-- The beckoning paw, raised beside the face.
			c:ovoid(Vector3.new(0.40, 0.80, 0.42), CFrame.new(-1.02, 0.30, 0.40) * CFrame.Angles(0.15, 0, 0.30), p.base)
			c:ovoid(Vector3.new(0.46, 0.42, 0.40), CFrame.new(-1.16, 0.86, 0.48), p.base)
			c:ovoid(Vector3.new(0.22, 0.20, 0.06), CFrame.new(-1.16, 0.84, 0.69), pink)
			-- The other paw holds a gold koban to its tummy.
			c:round(Vector3.new(0.46, 0.70, 0.08), CFrame.new(0.42, -0.62, 0.96), GOLD, METAL)
			c:box(Vector3.new(0.30, 0.04, 0.04), CFrame.new(0.42, -0.56, 1.01), C3(176, 132, 40))
			c:ovoid(Vector3.new(0.40, 0.34, 0.36), CFrame.new(0.72, -0.44, 0.84), p.base)
			-- Calico patches, and a short tail.
			c:box(Vector3.new(0.70, 0.08, 0.70), CFrame.new(-0.40, 0.98, -0.12), calico)
			c:box(Vector3.new(0.08, 0.50, 0.60), CFrame.new(1.06, 0.10, -0.30), calico)
			c:box(Vector3.new(0.60, 0.56, 0.08), CFrame.new(0.36, 0.30, -0.88), p.deep)
			c:ovoid(Vector3.new(0.30, 0.56, 0.30), CFrame.new(0, -0.50, -1.00) * CFrame.Angles(-0.4, 0, 0), p.base)
		end,
	}

	-- A koinobori: a carp streamer swimming in the wind, with a gold hoop for a
	-- mouth, big round eyes, scales, a pale koi pattern and a forked tail.
	S.so_koinobori = {
		label = "Koi Kite",
		set = "shoguns_oath",
		tint = C3(232, 92, 52),
		-- Long nose to tail.
		scale = 1.18,
		head = CFrame.new(0, 1.00, 0.30),
		neck = CFrame.new(0, -0.62, 0.90),
		back = CFrame.new(0, 0.30, -0.96),
		build = function(c, p)
			-- The windsock, tapering to the tail in three sections that ripple in the wind.
			local mid = CFrame.new(0.04, 0.12, -0.34) * CFrame.Angles(0, 0.12, 0.03)
			local rear = CFrame.new(-0.02, 0.10, -1.04) * CFrame.Angles(0, -0.12, -0.03)
			c:box(Vector3.new(1.70, 1.60, 1.04), CFrame.new(0, 0.16, 0.56), p.base)
			c:box(Vector3.new(1.50, 1.40, 0.90), mid, p.base)
			c:box(Vector3.new(1.18, 1.10, 0.70), rear, p.base)
			-- Koi pattern patches.
			c:box(Vector3.new(0.70, 0.08, 0.70), CFrame.new(-0.20, 0.97, 0.40), p.pale)
			c:box(Vector3.new(0.08, 0.56, 0.60), CFrame.new(0.86, 0.32, 0.40), p.pale)
			c:box(Vector3.new(0.60, 0.08, 0.50), rear * CFrame.new(0.14, 0.56, 0), p.pale)
			for _, s in ipairs({ -1, 1 }) do
				-- Scales: round discs along each flank.
				c:cyl(Vector3.new(0.06, 0.52, 0.52), mid * CFrame.new(0.75 * s, -0.12, 0), p.light)
				c:cyl(Vector3.new(0.06, 0.42, 0.42), rear * CFrame.new(0.59 * s, -0.08, 0), p.light)
				-- Eyes: white disc, pupil, glint.
				c:cyl(Vector3.new(0.08, 0.50, 0.50), CFrame.new(0.42 * s, 0.56, 1.10) * FACE_Z, WHITE)
				c:round(Vector3.new(0.26, 0.30, 0.10), CFrame.new(0.42 * s, 0.54, 1.15), INK):SetAttribute("Eye", true)
				c:round(Vector3.new(0.09, 0.10, 0.05), CFrame.new(0.42 * s + 0.06, 0.62, 1.20), WHITE):SetAttribute("Eye", true)
				-- Pectoral fins.
				c:cone(Vector3.new(0.08, 0.50, 0.50), CFrame.new(0.94 * s, -0.46, 0.30) * CFrame.Angles(0, 0, -2.2 * s), p.light)
				-- Forked tail.
				c:box(Vector3.new(0.08, 1.04, 0.86), rear * CFrame.new(0.20 * s, 0, -0.66) * CFrame.Angles(0, 0.50 * s, 0.12 * s), p.light)
				-- Hoop sides.
				c:box(Vector3.new(0.12, 0.60, 0.10), CFrame.new(0.36 * s, -0.12, 1.11), GOLD, METAL)
			end
			-- Gold hoop round the open mouth.
			c:box(Vector3.new(0.62, 0.62, 0.06), CFrame.new(0, -0.12, 1.09), C3(30, 26, 34))
			c:box(Vector3.new(0.84, 0.12, 0.10), CFrame.new(0, 0.24, 1.11), GOLD, METAL)
			c:box(Vector3.new(0.84, 0.12, 0.10), CFrame.new(0, -0.48, 1.11), GOLD, METAL)
			-- Dorsal fin.
			c:cone(Vector3.new(0.08, 0.40, 0.76), mid * CFrame.new(0, 0.88, 0), p.light)
		end,
	}

	return S
end
