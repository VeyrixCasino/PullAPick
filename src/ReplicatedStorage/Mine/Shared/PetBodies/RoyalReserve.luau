--[[ PetBodies/RoyalReserve -- Royal Reserve's bodies. See tools/gen/sets/README.md.
	Luxury and prestige: engraved gold, black velvet, crowns and gems, all kept
	symmetrical. Gold trim is fixed (it is the set's signature); every body's
	main colour comes from p.* so each pet wears its own tint. ]]
return function(K)
	local C3, block = K.C3, K.block
	local METAL, NEON, INK = K.METAL, K.NEON, K.INK
	local GOLD = C3(240, 194, 70)
	local VELVET = C3(122, 20, 46)
	local RUBY, SAPPHIRE, EMERALD = C3(230, 40, 70), C3(60, 110, 255), C3(40, 210, 120)
	local S = {}

	-- Restyle every part made since `from` (block()'s chassis), leaving the eyes.
	local function finish(c, from, mat, refl)
		for i = from, c.count do
			local part = c.model:FindFirstChild("P" .. i)
			if part and not part:GetAttribute("Eye") then
				part.Material = mat
				if refl then
					part.Reflectance = refl
				end
			end
		end
	end

	-- A heraldic lion: the square mane framing the face is the whole read.
	S.rr_lion = {
		label = "Lion",
		set = "royal_reserve",
		tint = C3(226, 170, 84),
		head = CFrame.new(0, 1.36, 0.40),
		neck = CFrame.new(0, -0.62, 0.98),
		back = CFrame.new(0, 0.24, -0.62),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				snout = { w = 0.70, h = 0.46, d = 0.50, color = p.pale },
				legSize = Vector3.new(0.50, 0.38, 0.56), legX = 0.60, legColor = p.base,
				tail = false,
			})
			local mane = p.dark
			c:box(Vector3.new(2.30, 0.46, 0.56), CFrame.new(0, 1.10, 0.64), mane)
			c:box(Vector3.new(1.50, 0.30, 0.50), CFrame.new(0, -0.70, 0.70), mane)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.40, 1.86, 0.56), CFrame.new(1.12 * s, 0.14, 0.64), mane)
				-- Corner tufts set at 45 degrees so the frame reads round, not square.
				c:box(Vector3.new(0.46, 0.46, 0.50), CFrame.new(0.98 * s, 0.98, 0.66) * CFrame.Angles(0, 0, math.pi / 4), p.deep)
				c:box(Vector3.new(0.40, 0.40, 0.50), CFrame.new(0.92 * s, -0.62, 0.66) * CFrame.Angles(0, 0, math.pi / 4), p.deep)
				-- Little round ears poking out of the mane.
				c:box(Vector3.new(0.34, 0.30, 0.22), CFrame.new(0.56 * s, 1.42, 0.62), p.base)
			end
			-- A gold medallion with a ruby, hung on the chin ruff.
			c:cyl(Vector3.new(0.08, 0.38, 0.38), CFrame.new(0, -0.72, 0.97) * CFrame.Angles(0, math.pi / 2, 0), GOLD, METAL)
			c:box(Vector3.new(0.14, 0.14, 0.06), CFrame.new(0, -0.72, 1.02) * CFrame.Angles(0, 0, math.pi / 4), RUBY, NEON)
			-- Tail with a tuft.
			c:rod(Vector3.new(0, -0.10, -0.92), Vector3.new(0, 0.56, -1.22), 0.09, p.base, nil, false)
			c:box(Vector3.new(0.38, 0.42, 0.38), CFrame.new(0, 0.68, -1.28) * CFrame.Angles(0, math.pi / 4, 0), mane)
		end,
	}

	-- A pampered poodle: pom-pom pouf, ear puffs, ankle cuffs and a tail pom.
	S.rr_poodle = {
		label = "Poodle",
		set = "royal_reserve",
		tint = C3(244, 206, 222),
		head = CFrame.new(0, 1.64, 0.10),
		neck = CFrame.new(0, -0.62, 0.92),
		back = CFrame.new(0, 0.30, -0.62),
		build = function(c, p)
			block(c, p, {
				shape = "quad",
				bodySize = Vector3.new(1.84, 1.70, 1.76),
				snout = { w = 0.46, h = 0.40, d = 0.60, color = p.light, nose = INK },
				legSize = Vector3.new(0.30, 0.40, 0.34), legX = 0.52, legColor = p.base,
				tail = false,
			})
			local puff = p.pale
			c:ball(Vector3.new(1.20, 1.00, 1.10), CFrame.new(0, 1.12, 0.10), puff)
			for _, s in ipairs({ -1, 1 }) do
				c:ball(Vector3.new(0.62, 0.92, 0.62), CFrame.new(1.02 * s, 0.10, 0.30), puff)
				for _, z in ipairs({ 0.42, -0.42 }) do
					c:ball(Vector3.new(0.54, 0.50, 0.54), CFrame.new(0.52 * s, -0.94, z), puff)
				end
				-- Velvet bow on the pouf.
				c:box(Vector3.new(0.34, 0.30, 0.12), CFrame.new(0.20 * s, 1.42, 0.56) * CFrame.Angles(0, 0, 0.35 * s), VELVET)
			end
			c:box(Vector3.new(0.14, 0.14, 0.14), CFrame.new(0, 1.42, 0.60), GOLD, METAL)
			c:rod(Vector3.new(0, 0.30, -0.80), Vector3.new(0, 0.86, -1.08), 0.08, p.base, nil, false)
			c:ball(Vector3.new(0.62, 0.62, 0.62), CFrame.new(0, 0.98, -1.14), puff)
			-- A jewelled pendant on the chest.
			c:box(Vector3.new(0.34, 0.34, 0.10), CFrame.new(0, -0.62, 0.92) * CFrame.Angles(0, 0, math.pi / 4), GOLD, METAL)
			c:box(Vector3.new(0.18, 0.18, 0.08), CFrame.new(0, -0.62, 0.97) * CFrame.Angles(0, 0, math.pi / 4), SAPPHIRE, NEON)
		end,
	}

	-- A peacock with a fanned train of jewel-eyed feathers behind it.
	S.rr_peacock = {
		label = "Peacock",
		set = "royal_reserve",
		tint = C3(40, 112, 196),
		-- The train is the widest thing on it; scaled back up so the bird keeps its size.
		scale = 1.16,
		head = CFrame.new(0, 1.10, 0.30),
		neck = CFrame.new(0, -0.40, 0.70),
		back = CFrame.new(0, 0.30, -0.70),
		build = function(c, p)
			block(c, p, {
				shape = "bird",
				bodySize = Vector3.new(1.80, 1.84, 1.70),
				mouth = false, tail = false,
				bib = { w = 0.80, h = 0.70, y = -0.46, color = p.light },
				legSize = Vector3.new(0.34, 0.24, 0.44), legZ = { 0.20 }, legColor = p.deep,
			})
			c:cone(Vector3.new(0.26, 0.36, 0.30), CFrame.new(0, -0.12, 0.98) * CFrame.Angles(1.75, 0, 0), GOLD)
			-- Crest: three stalks with gold beads.
			for i = -1, 1 do
				local tip = Vector3.new(i * 0.24, 1.46, 0.10 - math.abs(i) * 0.06)
				c:rod(Vector3.new(i * 0.08, 0.90, 0.10), tip, 0.035, p.dark, nil, false)
				c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(tip), GOLD, METAL)
			end
			-- The train. Each eye spot goes right through its feather, so it shows
			-- from behind too, which is how a following pet is mostly seen.
			local pivot = CFrame.new(0, -0.30, -0.86) * CFrame.Angles(-0.32, 0, 0)
			for i = -3, 3 do
				local f = pivot * CFrame.Angles(0, 0, -i * 0.36)
				c:box(Vector3.new(0.40, 1.40, 0.10), f * CFrame.new(0, 0.80, 0), (i % 2 == 0) and p.dark or p.base)
				c:box(Vector3.new(0.26, 0.26, 0.16), f * CFrame.new(0, 1.30, 0) * CFrame.Angles(0, 0, math.pi / 4), p.glow, NEON)
			end
		end,
	}

	-- A velvet jewel case with its lid thrown open and a big gem on the cushion.
	S.rr_jewelbox = {
		label = "Jewel Box",
		set = "royal_reserve",
		tint = C3(42, 30, 52),
		-- The open lid makes it the tallest body in the set.
		scale = 1.12,
		head = CFrame.new(0, 1.40, 0.10),
		neck = CFrame.new(0, -0.40, 0.76),
		back = CFrame.new(0, 0.40, -0.80),
		build = function(c, p)
			block(c, p, {
				square = true, bodySize = Vector3.new(2.00, 1.30, 1.40),
				eyeY = 0.06, eyeSize = Vector3.new(0.46, 0.54, 0.22), eyeSpread = 0.44,
				mouthY = -0.30, mouthSize = Vector3.new(0.32, 0.14, 0.14),
				legs = false, tail = false,
			})
			-- Gold ball feet, rims and corner posts.
			for _, s in ipairs({ -1, 1 }) do
				for _, t in ipairs({ -1, 1 }) do
					c:ball(Vector3.new(0.36, 0.36, 0.36), CFrame.new(0.78 * s, -0.72, 0.52 * t), GOLD, METAL)
					c:box(Vector3.new(0.14, 1.30, 0.14), CFrame.new(1.00 * s, 0.06, 0.70 * t), GOLD, METAL)
				end
			end
			c:box(Vector3.new(2.08, 0.14, 1.48), CFrame.new(0, 0.66, 0), GOLD, METAL)
			c:box(Vector3.new(2.08, 0.14, 1.48), CFrame.new(0, -0.52, 0), GOLD, METAL)
			c:box(Vector3.new(0.30, 0.24, 0.08), CFrame.new(0, 0.48, 0.72), GOLD, METAL)
			-- The lid, swung back past upright on its hinge, satin lining facing out.
			local lid = CFrame.new(0, 0.74, -0.70) * CFrame.Angles(-1.95, 0, 0)
			c:box(Vector3.new(2.06, 0.18, 1.44), lid * CFrame.new(0, 0.09, 0.72), p.base)
			c:box(Vector3.new(1.80, 0.04, 1.24), lid * CFrame.new(0, -0.02, 0.72), p.light)
			c:box(Vector3.new(2.10, 0.12, 0.12), lid * CFrame.new(0, 0.09, 1.44), GOLD, METAL)
			-- Cushion and the gem: two pyramids, base to base.
			c:box(Vector3.new(1.40, 0.18, 1.00), CFrame.new(0, 0.78, 0.02), p.pale)
			c:cone(Vector3.new(0.66, 0.38, 0.66), CFrame.new(0, 1.18, 0.02) * CFrame.Angles(0, math.pi / 4, 0), C3(176, 236, 255), NEON)
			c:cone(Vector3.new(0.66, 0.22, 0.66), CFrame.new(0, 0.88, 0.02) * CFrame.Angles(math.pi, math.pi / 4, 0), C3(140, 210, 255), NEON)
			-- Two studs on the front corners.
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.16, 0.16, 0.08), CFrame.new(0.74 * s, 0.46, 0.72) * CFrame.Angles(0, 0, math.pi / 4), s < 0 and RUBY or EMERALD, NEON)
			end
		end,
	}

	-- A walking crown: band with points and pearls, velvet cap, ermine trim.
	S.rr_crownling = {
		label = "Crownling",
		set = "royal_reserve",
		tint = C3(244, 198, 72),
		head = CFrame.new(0, 1.62, 0),
		neck = CFrame.new(0, -0.50, 0.70),
		back = CFrame.new(0, 0.10, -0.72),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				square = true, bodySize = Vector3.new(2.00, 1.30, 1.80),
				eyeY = 0.10, eyeSize = Vector3.new(0.46, 0.56, 0.22), eyeSpread = 0.42,
				mouthY = -0.20, mouthSize = Vector3.new(0.26, 0.14, 0.14),
				legSize = Vector3.new(0.40, 0.30, 0.46), legY = -0.74, legColor = p.deep,
				tail = false,
			})
			finish(c, from, METAL, 0.22)
			-- Ermine band round the bottom, with its black tails.
			c:box(Vector3.new(2.12, 0.26, 1.92), CFrame.new(0, -0.46, 0), C3(248, 246, 240))
			for _, x in ipairs({ -0.62, 0, 0.62 }) do
				c:box(Vector3.new(0.10, 0.16, 0.06), CFrame.new(x, -0.46, 0.97), INK)
			end
			-- Points with pearl tips: three front, three back, one each side.
			local points = {
				{ -0.70, 0.78, 0 }, { 0, 0.78, 0 }, { 0.70, 0.78, 0 },
				{ -0.70, -0.78, 0 }, { 0, -0.78, 0 }, { 0.70, -0.78, 0 },
				{ -0.88, 0, math.pi / 2 }, { 0.88, 0, math.pi / 2 },
			}
			for _, pt in ipairs(points) do
				local tall = (pt[1] == 0) and 0.78 or 0.62
				c:cone(Vector3.new(0.40, tall, 0.20), CFrame.new(pt[1], 0.71 + tall * 0.5, pt[2]) * CFrame.Angles(0, pt[3], 0), p.base, METAL)
				c:ball(Vector3.new(0.18, 0.18, 0.18), CFrame.new(pt[1], 0.75 + tall, pt[2]), C3(250, 246, 236))
			end
			-- Velvet cap and a gold finial.
			c:box(Vector3.new(1.56, 0.56, 1.40), CFrame.new(0, 0.96, 0), VELVET)
			c:ball(Vector3.new(0.30, 0.30, 0.30), CFrame.new(0, 1.36, 0), p.base, METAL)
			-- Three jewels: a big one on the brow, one on each side.
			c:box(Vector3.new(0.28, 0.28, 0.12), CFrame.new(0, 0.50, 0.94) * CFrame.Angles(0, 0, math.pi / 4), RUBY, NEON)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.10, 0.24, 0.24), CFrame.new(1.03 * s, 0.30, 0) * CFrame.Angles(math.pi / 4, 0, 0), s < 0 and SAPPHIRE or EMERALD, NEON)
			end
		end,
	}

	return S
end
