--[[ PetBodies/HoloHavocExtra -- more Holo Havoc recolour bodies (Common to Rare).
	Room for vastly different colours (owner, 2026-10-10: "recolors fore common,
	uncommon, rare. Vastly different colors tho."): a finch in crinkled glitter
	foil, a wombat stitched with sequins, a skunk with a spangled plume and a
	cheer pompom of foil strips. Same chrome-and-foil house style as
	PetBodies/HoloHavoc. See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block, ears, wings = K.C3, K.block, K.ears, K.wings
	local METAL, NEON, INK, WHITE = K.METAL, K.NEON, K.INK, K.WHITE
	local CHROME = C3(214, 220, 232)
	local FOIL_A, FOIL_B = C3(140, 240, 255), C3(255, 160, 236)
	local S = {}

	-- Restyle every part made since `from` (block()'s chassis), leaving the eyes.
	local function finish(c, from, mat, refl)
		for i = from, c.count do
			local part = c.model:FindFirstChild("P" .. i)
			if part and not part:GetAttribute("Eye") then
				part.Material = mat
				part.Reflectance = refl or 0
			end
		end
	end

	-- A flat foil sequin, its face turned along `axis` ("x", "y" or "z").
	local function sequin(c, pos, d, colour, axis)
		local turn = (axis == "y") and CFrame.Angles(0, 0, math.pi / 2) or ((axis == "z") and CFrame.Angles(0, math.pi / 2, 0) or CFrame.new())
		local part = c:cyl(Vector3.new(0.05, d, d), CFrame.new(pos) * turn, colour, METAL)
		part.Reflectance = 0.5
		return part
	end

	-- A round finch in crinkled glitter foil: foil wing panels, a crest, a fan tail.
	S.hh_glitterfinch = {
		label = "Glitter Finch",
		set = "holo_havoc",
		tint = C3(255, 196, 60),
		head = CFrame.new(0, 1.30, 0.04),
		neck = CFrame.new(0, -0.40, 0.70),
		back = CFrame.new(0, 0.30, -0.70),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				shape = "bird",
				bodySize = Vector3.new(1.80, 1.76, 1.70),
				eyeY = 0.24, eyeSize = Vector3.new(0.44, 0.54, 0.20), eyeSpread = 0.40, mouth = false,
				bib = { w = 0.96, h = 0.72, y = -0.36, color = p.pale },
				legSize = Vector3.new(0.14, 0.40, 0.14), legX = 0.34, legY = -0.94, legZ = { 0.10 }, legColor = p.deep,
				tail = false,
			})
			finish(c, from, METAL, 0.25)
			-- Beak, pointing forward.
			c:cone(Vector3.new(0.34, 0.42, 0.28), CFrame.new(0, -0.04, 1.02) * CFrame.Angles(math.pi / 2, 0, 0), C3(255, 170, 60))
			wings(c, p.dark, 0.24, 0.02, -0.16, 0.26)
			-- Crinkled foil panels on each wing, catching the light.
			for _, s in ipairs({ -1, 1 }) do
				for k = 0, 2 do
					local part = c:box(Vector3.new(0.06, 0.26, 0.24), CFrame.new(1.20 * s, 0.24 - k * 0.22, -0.02 - k * 0.18) * CFrame.Angles(0.3 * k, 0, -0.30 * s), (k % 2 == 0) and FOIL_A or FOIL_B, METAL)
					part.Reflectance = 0.6
				end
			end
			-- A spiky crest and a fanned tail.
			c:cone(Vector3.new(0.20, 0.42, 0.20), CFrame.new(-0.10, 1.08, 0.10) * CFrame.Angles(0.2, 0, 0.30), p.light, METAL)
			c:cone(Vector3.new(0.22, 0.52, 0.22), CFrame.new(0.10, 1.12, 0.00) * CFrame.Angles(-0.2, 0, -0.20), p.light, METAL)
			for _, a in ipairs({ -0.45, 0, 0.45 }) do
				c:box(Vector3.new(0.30, 0.08, 0.66), CFrame.new(0, 0.10, -1.02) * CFrame.Angles(0.45, a, 0) * CFrame.new(0, 0, -0.20), p.dark, METAL).Reflectance = 0.3
			end
			c:star(Vector3.new(0.70, 0.80, 0.70), 0.30, WHITE)
		end,
	}

	-- A chunky wombat stitched all over with foil sequins: a broad nose, round ears.
	S.hh_sequinwombat = {
		label = "Sequin Wombat",
		set = "holo_havoc",
		tint = C3(150, 104, 220),
		head = CFrame.new(0, 1.00, 0.10),
		neck = CFrame.new(0, -0.36, 0.86),
		back = CFrame.new(0, 0.14, -0.86),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				square = true,
				bodySize = Vector3.new(2.10, 1.56, 1.86),
				eyeY = 0.24, eyeSpread = 0.50, eyeSize = Vector3.new(0.40, 0.46, 0.20),
				snout = { w = 0.84, h = 0.46, d = 0.36, y = -0.26, color = p.pale, nose = INK },
				legSize = Vector3.new(0.50, 0.30, 0.56), legX = 0.66, legY = -0.80, legColor = p.deep,
				tail = false,
			})
			ears(c, p.dark, "round", p.pale)
			finish(c, from, METAL, 0.15)
			local shades = { FOIL_A, p.light, FOIL_B }
			local n = 0
			for _, s in ipairs({ -1, 1 }) do
				for _, v in ipairs({ { 0.40, 0.40 }, { 0.00, -0.10 }, { 0.40, -0.60 }, { -0.20, 0.20 } }) do
					n += 1
					sequin(c, Vector3.new(1.07 * s, v[1], v[2]), 0.30, shades[n % 3 + 1], "x")
				end
			end
			for _, v in ipairs({ { -0.50, 0.30 }, { 0.50, 0.30 }, { 0.00, -0.20 }, { -0.50, -0.60 }, { 0.50, -0.60 } }) do
				n += 1
				sequin(c, Vector3.new(v[1], 0.86, v[2]), 0.32, shades[n % 3 + 1], "y")
			end
			sequin(c, Vector3.new(0, 0.20, -0.95), 0.40, CHROME, "z")
		end,
	}

	-- A skunk with a spangled plume curling up over its back.
	S.hh_spangleskunk = {
		label = "Spangle Skunk",
		set = "holo_havoc",
		tint = C3(60, 64, 96),
		head = CFrame.new(0, 1.18, 0.30),
		neck = CFrame.new(0, -0.36, 0.76),
		back = CFrame.new(0, 0.30, -0.40),
		build = function(c, p)
			local from = c.count + 1
			block(c, p, {
				shape = "quad",
				bodySize = Vector3.new(1.86, 1.60, 1.70),
				eyeY = 0.18, eyeSpread = 0.42,
				snout = { w = 0.56, h = 0.40, d = 0.42, y = -0.24, color = p.pale, nose = INK },
				legColor = p.deep, legSize = Vector3.new(0.40, 0.34, 0.46),
				tail = false,
			})
			ears(c, p.base, "round", p.pale)
			finish(c, from, METAL, 0.20)
			-- The white stripe from brow to rump.
			c:box(Vector3.new(0.36, 0.08, 1.72), CFrame.new(0, 0.90, -0.02), p.pale, METAL).Reflectance = 0.3
			c:box(Vector3.new(0.16, 0.44, 0.06), CFrame.new(0, 0.50, 0.88), p.pale)
			-- The plume: three puffs climbing over the back, striped in foil.
			local plume = { { 0, 0.10, -1.10, 0.86 }, { 0, 0.80, -1.30, 0.96 }, { 0, 1.46, -1.00, 0.80 } }
			for i, t in ipairs(plume) do
				c:round(Vector3.new(t[4], t[4], t[4]), CFrame.new(t[1], t[2], t[3]), p.base, METAL).Reflectance = 0.2
				local band = c:box(Vector3.new(0.26, t[4] * 0.9, t[4] * 0.9), CFrame.new(0, t[2], t[3]), (i % 2 == 0) and FOIL_B or FOIL_A, METAL)
				band.Reflectance = 0.5
			end
			c:round(Vector3.new(0.44, 0.40, 0.40), CFrame.new(0, 1.86, -0.74), p.pale, METAL)
			c:star(Vector3.new(0.50, 1.70, -0.90), 0.32, WHITE)
		end,
	}

	-- A cheer pompom of foil strips round a chrome core, with a stubby handle.
	S.hh_foilpompom = {
		label = "Foil Pompom",
		set = "holo_havoc",
		tint = C3(80, 230, 200),
		head = CFrame.new(0, 1.30, 0.06),
		neck = CFrame.new(0, -0.50, 0.80),
		back = CFrame.new(0, 0.10, -0.86),
		build = function(c, p)
			c:ball(Vector3.new(1.80, 1.80, 1.80), CFrame.new(0, 0.06, 0), p.base, METAL).Reflectance = 0.3
			-- Strips fan out round the sides, top and back (the face stays clear).
			local dirs = {
				{ 1, 0.2, 0.3 }, { -1, 0.2, 0.3 }, { 1, -0.4, -0.2 }, { -1, -0.4, -0.2 },
				{ 0.6, 1, 0.2 }, { -0.6, 1, 0.2 }, { 0, 1, -0.5 }, { 0.3, 1, 0.6 }, { -0.3, 1, 0.6 },
				{ 0.7, 0.6, -0.7 }, { -0.7, 0.6, -0.7 }, { 0, 0, -1 }, { 0.6, -0.5, -0.8 }, { -0.6, -0.5, -0.8 },
				{ 0.9, 0.7, 0.4 }, { -0.9, 0.7, 0.4 },
			}
			local shades = { p.light, FOIL_A, p.base, FOIL_B }
			for i, d in ipairs(dirs) do
				local u = Vector3.new(d[1], d[2], d[3]).Unit
				local at = Vector3.new(0, 0.06, 0) + u * 0.92
				local strip = c:box(Vector3.new(0.14, 0.56, 0.04), CFrame.lookAt(at, at + u) * CFrame.Angles(-math.pi / 2, 0, 0) * CFrame.new(0, 0.20, 0), shades[(i % 4) + 1], METAL)
				strip.Reflectance = 0.5
			end
			c:eyes(0.24, 0.80, 0.34, 0.18)
			c:box(Vector3.new(0.30, 0.12, 0.10), CFrame.new(0, -0.18, 0.88), INK)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.18, 0.08, 0.04), CFrame.new(0.58 * s, -0.04, 0.72), C3(255, 150, 190), NEON)
			end
			-- The handle and two little feet.
			c:cyl(Vector3.new(0.50, 0.36, 0.36), CFrame.new(0, -0.94, -0.10) * CFrame.Angles(0, 0, math.pi / 2), CHROME, METAL).Reflectance = 0.4
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.36, 0.20, 0.44), CFrame.new(0.42 * s, -0.86, 0.30), p.deep, METAL)
			end
		end,
	}

	return S
end
