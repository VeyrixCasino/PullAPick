--[[ PetBodies/CrimsonEclipse -- Crimson Eclipse's bodies. See tools/gen/sets/README.md.
	Kid-friendly gothic: blood-red moons, an eclipse, a cathedral gargoyle, a
	spellbook and a dark rose. No bats, no fangs-and-capes (those are the
	Halloween bodies), and nothing gory. ]]
return function(K)
	local C3, block, spots = K.C3, K.block, K.spots
	local METAL, NEON, SLATE, INK = K.METAL, K.NEON, K.SLATE, K.INK
	local GOLD = C3(232, 186, 76)
	local BLOOD = C3(220, 30, 60)
	local BLUSH = C3(255, 140, 160)
	local S = {}

	local function finish(c, from, mat)
		for i = from, c.count do
			local part = c.model:FindFirstChild("P" .. i)
			if part and not part:GetAttribute("Eye") then
				part.Material = mat
			end
		end
	end

	-- A crescent moon with a face on its fat middle and a star on a thread.
	S.ce_crescent = {
		label = "Crescent",
		set = "crimson_eclipse",
		tint = C3(206, 44, 62),
		head = CFrame.new(0.16, 1.30, 0),
		neck = CFrame.new(-0.56, -0.42, 0.70),
		back = CFrame.new(-0.60, 0.10, -0.70),
		build = function(c, p)
			local cx, cy, R = 0.42, 0.10, 0.95
			local thick = { 0.34, 0.56, 0.78, 0.96, 1.08, 0.96, 0.78, 0.56, 0.34 }
			for i, t in ipairs(thick) do
				local a = math.rad(100 + (i - 1) * 20)
				c:box(
					Vector3.new(t, 0.56, 1.30),
					CFrame.new(cx + R * math.cos(a), cy + R * math.sin(a), 0) * CFrame.Angles(0, 0, a),
					(i % 2 == 0) and p.light or p.base
				)
			end
			-- The face sits on the widest part of the curve.
			local fx = cx - R
			c:eye(Vector3.new(fx - 0.22, cy + 0.14, 0.68), 0.13)
			c:eye(Vector3.new(fx + 0.22, cy + 0.14, 0.68), 0.13)
			c:box(Vector3.new(0.22, 0.08, 0.06), CFrame.new(fx, cy - 0.16, 0.66), INK)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.14, 0.08, 0.04), CFrame.new(fx + 0.34 * s, cy - 0.06, 0.66), BLUSH)
			end
			-- Craters.
			for _, v in ipairs({ { 140, 0.67 }, { 222, 0.67 }, { 180, -0.66 } }) do
				local a = math.rad(v[1])
				c:box(Vector3.new(0.22, 0.22, 0.06), CFrame.new(cx + (R + 0.18) * math.cos(a), cy + (R + 0.18) * math.sin(a), v[2]), p.dark)
			end
			-- Two stubby feet under the belly of the curve.
			for _, z in ipairs({ 0.32, -0.32 }) do
				c:box(Vector3.new(0.36, 0.24, 0.40), CFrame.new(-0.42, -0.94, z), p.deep)
			end
			-- A little star dangling from the top horn.
			local top = Vector3.new(cx + R * math.cos(math.rad(104)), cy + R * math.sin(math.rad(104)) - 0.10, 0)
			local star = Vector3.new(0.52, 0.30, 0)
			c:rod(top, star + Vector3.new(0, 0.14, 0), 0.02, C3(250, 236, 210), nil, false)
			c:box(Vector3.new(0.28, 0.28, 0.12), CFrame.new(star) * CFrame.Angles(0, 0, math.pi / 4), C3(255, 214, 150), NEON)
			c:light(p.glow, 1.3, 8)
		end,
	}

	-- A cathedral gargoyle pup crouched on its plinth, with stone feather-wings.
	S.ce_gargoyle = {
		label = "Gargoyle",
		set = "crimson_eclipse",
		tint = C3(124, 114, 132),
		scale = 1.06,
		head = CFrame.new(0, 1.20, 0.10),
		neck = CFrame.new(0, -0.30, 0.66),
		back = CFrame.new(0, 0.30, -0.62),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				shape = "quad",
				bodySize = Vector3.new(1.96, 1.80, 1.76),
				snout = { w = 0.80, h = 0.44, d = 0.42, color = p.light, nose = p.deep },
				brow = p.dark,
				legSize = Vector3.new(0.48, 0.36, 0.52), legY = -0.84, legColor = p.dark,
				tail = false,
			})
			finish(c, from, SLATE)
			local tusk = C3(236, 230, 214)
			for _, s in ipairs({ -1, 1 }) do
				-- An underbite: two tusks pointing up from the jaw.
				c:cone(Vector3.new(0.12, 0.22, 0.12), CFrame.new(0.24 * s, -0.40, 1.22), tusk)
				c:cone(Vector3.new(0.24, 0.56, 0.24), CFrame.new(0.40 * s, 1.16, 0.18) * CFrame.Angles(-0.35, 0, -0.35 * s), p.light, SLATE)
				c:cone(Vector3.new(0.20, 0.50, 0.30), CFrame.new(1.04 * s, 0.56, 0.30) * CFrame.Angles(0, 0, -1.15 * s), p.base, SLATE)
				-- Stone wings: three stepped feather slabs, folded up behind the shoulders.
				for k = 0, 2 do
					c:box(
						Vector3.new(0.18, 0.86 - k * 0.20, 0.56),
						CFrame.new((0.78 + k * 0.16) * s, 0.70 + k * 0.22, -0.48 - k * 0.12) * CFrame.Angles(0.20, 0, -0.45 * s),
						p.dark,
						SLATE
					)
				end
			end
			c:box(Vector3.new(2.14, 0.28, 1.96), CFrame.new(0, -1.16, 0), p.deep, SLATE)
			c:box(Vector3.new(0.22, 0.22, 0.10), CFrame.new(0, 0.80, 0.92) * CFrame.Angles(0, 0, math.pi / 4), BLOOD, NEON)
			-- Arrow-tipped tail curling onto the plinth.
			c:rod(Vector3.new(0, -0.50, -0.86), Vector3.new(0.40, -0.92, -1.14), 0.07, p.dark, SLATE, false)
			c:cone(Vector3.new(0.26, 0.30, 0.12), CFrame.new(0.50, -0.96, -1.22) * CFrame.Angles(0, 0, -1.2), p.dark, SLATE)
		end,
	}

	-- A dark rose: the bloom is the body, with a swirled bud on top and a stem below.
	S.ce_rose = {
		label = "Rose",
		set = "crimson_eclipse",
		tint = C3(190, 26, 50),
		head = CFrame.new(0, 1.42, 0),
		neck = CFrame.new(0, -0.62, 0.86),
		back = CFrame.new(0, 0.20, -0.72),
		build = function(c, p)
			local leaf = C3(52, 92, 58)
			block(c, p, {
				shape = "round",
				bodySize = Vector3.new(1.86, 1.60, 1.76),
				eyeY = 0.10, mouthY = -0.32, mouthSize = Vector3.new(0.28, 0.14, 0.14),
				legs = false, tail = false,
			})
			for _, s in ipairs({ -1, 1 }) do
				-- Side petals curling outward, and two lip petals under the chin.
				c:box(Vector3.new(0.30, 1.40, 1.40), CFrame.new(0.98 * s, 0.14, -0.08) * CFrame.Angles(0, 0, -0.22 * s), p.dark)
				c:box(Vector3.new(0.86, 0.36, 0.30), CFrame.new(0.46 * s, -0.62, 0.86) * CFrame.Angles(0.35, 0, 0.25 * s), p.dark)
				-- Leaf arms, a leaf foot each side, and a thorn on the stem.
				c:box(Vector3.new(0.70, 0.12, 0.40), CFrame.new(1.04 * s, -0.62, 0.20) * CFrame.Angles(0, 0, 0.40 * s), leaf)
				c:box(Vector3.new(0.40, 0.16, 0.70), CFrame.new(0.26 * s, -1.26, 0.06) * CFrame.Angles(0, 0.40 * s, 0), leaf)
				c:cone(Vector3.new(0.10, 0.18, 0.10), CFrame.new(0.14 * s, -0.96 - (s + 1) * 0.08, -0.05) * CFrame.Angles(0, 0, -1.57 * s), leaf)
			end
			c:box(Vector3.new(1.50, 1.40, 0.30), CFrame.new(0, 0.18, -0.96) * CFrame.Angles(-0.22, 0, 0), p.dark)
			-- The bud: three nested layers, each turned further, read as a swirl.
			c:box(Vector3.new(1.40, 0.30, 1.30), CFrame.new(0, 0.92, -0.06) * CFrame.Angles(0, 0.30, 0), p.base)
			c:box(Vector3.new(1.00, 0.30, 0.92), CFrame.new(0, 1.10, -0.06) * CFrame.Angles(0, 0.85, 0), p.light)
			c:box(Vector3.new(0.56, 0.30, 0.52), CFrame.new(0, 1.28, -0.06) * CFrame.Angles(0, 1.40, 0), p.deep)
			c:rod(Vector3.new(0, -0.70, -0.05), Vector3.new(0, -1.22, -0.05), 0.13, leaf, nil, false)
		end,
	}

	-- A spellbook standing on end: leather cover, page edges, gold corners,
	-- a crescent emblem and two ribbon bookmarks for a tail.
	S.ce_grimoire = {
		label = "Grimoire",
		set = "crimson_eclipse",
		tint = C3(116, 24, 44),
		head = CFrame.new(0, 1.20, 0),
		neck = CFrame.new(0, -0.52, 0.74),
		back = CFrame.new(0, 0.10, -0.72),
		build = function(c, p)
			local page = C3(240, 228, 200)
			c:box(Vector3.new(1.66, 1.84, 1.04), CFrame.new(0.06, 0.10, 0), page)
			for _, z in ipairs({ 0.58, -0.58 }) do
				c:box(Vector3.new(1.90, 2.04, 0.14), CFrame.new(0, 0.10, z), p.base)
			end
			c:box(Vector3.new(0.24, 2.04, 1.30), CFrame.new(-0.88, 0.10, 0), p.base)
			for _, y in ipairs({ 0.72, 0.10, -0.52 }) do
				c:box(Vector3.new(0.30, 0.12, 1.34), CFrame.new(-0.90, y, 0), p.dark)
			end
			-- Gold corner guards and a clasp across the fore-edge.
			for _, y in ipairs({ 1.00, -0.80 }) do
				c:box(Vector3.new(0.34, 0.34, 0.18), CFrame.new(0.82, y, 0.60), GOLD, METAL)
			end
			c:box(Vector3.new(0.18, 0.30, 1.40), CFrame.new(0.96, 0.10, 0), p.dark)
			c:box(Vector3.new(0.24, 0.34, 0.10), CFrame.new(0.86, 0.10, 0.68), GOLD, METAL)
			-- Face on the cover.
			c:eyes(0.24, 0.70, 0.30, 0.17)
			c:box(Vector3.new(0.34, 0.10, 0.06), CFrame.new(0, -0.16, 0.67), INK)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.18, 0.08, 0.04), CFrame.new(0.50 * s, -0.06, 0.66), BLUSH)
			end
			-- Crescent emblem: a red disc with a cover-coloured disc bitten out of it.
			c:cyl(Vector3.new(0.06, 0.42, 0.42), CFrame.new(0, 0.78, 0.67) * CFrame.Angles(0, math.pi / 2, 0), BLOOD, NEON)
			c:cyl(Vector3.new(0.06, 0.34, 0.34), CFrame.new(0.10, 0.84, 0.69) * CFrame.Angles(0, math.pi / 2, 0), p.base)
			-- Ribbon bookmarks hanging out of the bottom, and two feet.
			c:box(Vector3.new(0.14, 0.56, 0.04), CFrame.new(0.30, -0.96, 0.10) * CFrame.Angles(0, 0, 0.15), BLOOD)
			c:box(Vector3.new(0.14, 0.46, 0.04), CFrame.new(0.52, -0.92, -0.10) * CFrame.Angles(0, 0, -0.12), GOLD)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.40, 0.24, 0.60), CFrame.new(0.50 * s - 0.10, -1.04, 0), p.deep)
			end
		end,
	}

	-- An eclipse: a dark moon with a face, haloed by a glowing red corona.
	S.ce_eclipse = {
		label = "Eclipse",
		set = "crimson_eclipse",
		tint = C3(214, 40, 58),
		-- The corona is wider than the moon; scaled back up so the moon keeps its size.
		scale = 1.12,
		head = CFrame.new(0, 1.04, 0.10),
		neck = CFrame.new(0, -0.44, 0.70),
		back = CFrame.new(0, 0.10, -0.86),
		build = function(c, p)
			block(c, p, {
				shape = "round",
				bodySize = Vector3.new(1.76, 1.76, 1.56),
				bodyColor = p.dark,
				eyeY = 0.14, mouthY = -0.34,
				legs = false, tail = false,
			})
			-- Two glowing squares, one turned 45 degrees: an eight-point corona.
			c:box(Vector3.new(2.20, 2.20, 0.16), CFrame.new(0, 0.06, -0.62), p.glow, NEON)
			c:box(Vector3.new(2.00, 2.00, 0.14), CFrame.new(0, 0.06, -0.66) * CFrame.Angles(0, 0, math.pi / 4), p.base, NEON)
			-- Flares between the points.
			for k = 0, 7 do
				local a = math.rad(k * 45 + 22.5)
				c:cone(
					Vector3.new(0.26, 0.40, 0.12),
					CFrame.new(math.cos(a) * 1.18, 0.06 + math.sin(a) * 1.18, -0.60) * CFrame.Angles(0, 0, a - math.pi / 2),
					p.glow,
					NEON
				)
			end
			spots(c, p.deep, { { 0.02, 0.50, 0.77 }, { 0.40, -0.42, 0.77 } }, Vector3.new(0.22, 0.22, 0.10))
			c:light(p.glow, 1.8, 9)
		end,
	}

	return S
end
