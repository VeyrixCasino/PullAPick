--[[ PetBodies/MosswoodExtra -- Mosswood's extra recolour bodies. See tools/gen/sets/README.md.

	More small forest-floor finds for the Common, Uncommon and Rare pets to
	share: a woodlouse rolled under bark, a squirrel behind its own tail, a fir
	cone standing on two feet and a fallen oak leaf. Muted, no glow.
]]
return function(K)
	local C3, block, ears = K.C3, K.block, K.ears
	local INK, NOSE, WOOD = K.INK, K.NOSE, K.WOOD
	local S = {}

	local MOSS = C3(108, 136, 74)
	local LEAF = C3(124, 150, 82)
	local BLUSH = C3(232, 150, 150)

	-- A woodlouse: an arch of banded plates, a little face, feelers and six feet.
	S.mw_barklouse = {
		label = "Barklouse",
		set = "mosswood",
		tint = C3(132, 128, 136),
		head = CFrame.new(0, 1.08, 0.10),
		neck = CFrame.new(0, -0.40, 0.98),
		back = CFrame.new(0, 0.40, -1.00),
		build = function(c, p)
			-- Six plates front to back, tallest in the middle, banded light and dark.
			for i, h in ipairs({ 1.10, 1.42, 1.60, 1.60, 1.42, 1.10 }) do
				local z = 0.76 - (i - 1) * 0.30
				c:box(Vector3.new(2.00 - math.abs(i - 3.5) * 0.08, h, 0.32), CFrame.new(0, -0.62 + h * 0.5, z), i % 2 == 1 and p.base or p.dark)
			end
			-- The face plate, its eyes, a smile and two curling feelers.
			c:box(Vector3.new(1.50, 0.80, 0.12), CFrame.new(0, -0.20, 0.97), p.deep)
			c:eyes(-0.08, 1.06, 0.36, 0.14)
			c:box(Vector3.new(0.30, 0.08, 0.06), CFrame.new(0, -0.42, 1.04), INK)
			for _, s in ipairs({ -1, 1 }) do
				c:rod(Vector3.new(0.30 * s, 0.10, 1.00), Vector3.new(0.78 * s, 0.70, 1.26), 0.045, p.deep, nil, false)
				-- Three little feet down each side, and the two tail prongs.
				for _, z in ipairs({ 0.50, 0, -0.50 }) do
					c:box(Vector3.new(0.24, 0.22, 0.22), CFrame.new(0.86 * s, -0.74, z), p.deep)
				end
				c:box(Vector3.new(0.18, 0.16, 0.34), CFrame.new(0.34 * s, -0.50, -1.04), p.deep)
			end
			c:box(Vector3.new(0.50, 0.10, 0.34), CFrame.new(-0.30, 0.99, 0.10) * CFrame.Angles(0, 0.4, 0), MOSS)
		end,
	}

	-- A red squirrel's shape: a small sitting body with a nut, behind a huge curled tail.
	S.mw_bushtail = {
		label = "Bushtail",
		set = "mosswood",
		tint = C3(176, 96, 52),
		head = CFrame.new(0, 1.06, 0.10),
		neck = CFrame.new(0, -0.30, 0.86),
		back = CFrame.new(0, 0.60, -1.30),
		build = function(c, p)
			block(c, p, {
				shape = "quad", bodySize = Vector3.new(1.66, 1.62, 1.56),
				snout = { w = 0.40, h = 0.30, d = 0.40, y = -0.18, color = p.pale, nose = NOSE },
				eyeY = 0.16, eyeSpread = 0.38, eyeSize = Vector3.new(0.40, 0.48, 0.18),
				bib = { w = 0.84, h = 0.64, y = -0.36, color = p.pale },
				legSize = Vector3.new(0.40, 0.26, 0.48), legX = 0.48, legY = -0.80, legZ = { 0.30 },
				legColor = p.deep, tail = false,
			})
			ears(c, p.base, "tuft")
			-- The tail: up the back in four fat steps, the tip curling forward over the head.
			c:box(Vector3.new(0.86, 0.66, 0.64), CFrame.new(0, -0.40, -1.02), p.dark)
			c:box(Vector3.new(0.96, 0.86, 0.66), CFrame.new(0, 0.30, -1.24), p.base)
			c:box(Vector3.new(0.90, 0.80, 0.64), CFrame.new(0, 1.04, -1.08), p.dark)
			c:box(Vector3.new(0.72, 0.52, 0.60), CFrame.new(0, 1.40, -0.56), p.light)
			-- A hazelnut held in both paws.
			c:ball(Vector3.new(0.38, 0.38, 0.38), CFrame.new(0, -0.56, 0.96), C3(166, 112, 62))
			c:box(Vector3.new(0.30, 0.10, 0.24), CFrame.new(0, -0.36, 0.96), LEAF)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.22, 0.20, 0.20), CFrame.new(0.26 * s, -0.52, 1.02), p.pale)
			end
		end,
	}

	-- A fir cone on two feet: the face on its fat base, scales stepping up to a tuft.
	S.mw_fircone = {
		label = "Fircone",
		set = "mosswood",
		tint = C3(150, 96, 56),
		scale = 1.1,
		head = CFrame.new(0, 1.82, 0),
		neck = CFrame.new(0, -0.50, 0.90),
		back = CFrame.new(0, 0.10, -0.90),
		build = function(c, p)
			c:box(Vector3.new(1.80, 0.96, 1.70), CFrame.new(0, -0.30, 0), p.base, WOOD)
			-- Scale tiers, every other one turned a quarter so the corners stick out.
			local tiers = {
				{ 1.30, 0.34, 0.30, true }, { 1.42, 0.34, 0.56, false }, { 1.02, 0.32, 0.84, true },
				{ 1.00, 0.30, 1.10, false }, { 0.64, 0.28, 1.34, true }, { 0.42, 0.26, 1.56, false },
			}
			for _, t in ipairs(tiers) do
				local cf = CFrame.new(0, t[3], 0) * (t[4] and CFrame.Angles(0, math.pi / 4, 0) or CFrame.new())
				c:box(Vector3.new(t[1], t[2], t[1] * 0.94), cf, t[4] and p.dark or p.base, WOOD)
			end
			c:box(Vector3.new(0.16, 0.30, 0.16), CFrame.new(0.04, 1.80, 0) * CFrame.Angles(0, 0, -0.3), LEAF)
			-- Face, cheeks, stubby arms and feet.
			c:eyes(-0.16, 0.90, 0.34, 0.14)
			c:box(Vector3.new(0.28, 0.08, 0.06), CFrame.new(0, -0.46, 0.87), INK)
			for _, s in ipairs({ -1, 1 }) do
				c:box(Vector3.new(0.20, 0.12, 0.05), CFrame.new(0.50 * s, -0.36, 0.86), BLUSH)
				c:box(Vector3.new(0.24, 0.40, 0.26), CFrame.new(0.98 * s, -0.36, 0.20) * CFrame.Angles(0, 0, 0.3 * s), p.deep)
				c:box(Vector3.new(0.40, 0.22, 0.50), CFrame.new(0.46 * s, -0.88, 0.16), p.deep)
			end
		end,
	}

	-- A fallen oak leaf standing up: lobed edges, veins, a stalk and twig feet.
	S.mw_oakleaf = {
		label = "Oakleaf",
		set = "mosswood",
		tint = C3(176, 136, 60),
		head = CFrame.new(0, 1.40, 0),
		neck = CFrame.new(0, -0.40, 0.44),
		back = CFrame.new(0, 0.20, -0.44),
		build = function(c, p)
			c:box(Vector3.new(1.30, 1.90, 0.70), CFrame.new(0, 0.10, 0), p.base)
			c:box(Vector3.new(0.66, 0.66, 0.62), CFrame.new(0, 1.04, 0) * CFrame.Angles(0, 0, math.pi / 4), p.base)
			-- Three rounded lobes down each side, smaller towards the stalk.
			for _, s in ipairs({ -1, 1 }) do
				for i, y in ipairs({ 0.62, 0.06, -0.48 }) do
					local w = 0.56 - i * 0.04
					c:box(Vector3.new(w, 0.46, 0.62), CFrame.new((0.62 + w * 0.40) * s, y, 0) * CFrame.Angles(0, 0, 0.25 * s), p.base)
					c:box(Vector3.new(w * 0.9, 0.06, 0.06), CFrame.new((0.52 + w * 0.30) * s, y + 0.06, 0.36) * CFrame.Angles(0, 0, 0.35 * s), p.light)
				end
				-- Twig feet.
				c:box(Vector3.new(0.30, 0.20, 0.44), CFrame.new(0.34 * s, -0.98, 0.08), p.deep, WOOD)
			end
			-- The midrib down the back, the stalk underneath, and the face.
			c:box(Vector3.new(0.12, 2.10, 0.08), CFrame.new(0, 0.18, -0.38), p.dark)
			c:box(Vector3.new(0.14, 0.40, 0.14), CFrame.new(0.10, -0.98, -0.10) * CFrame.Angles(0, 0, 0.3), p.dark, WOOD)
			c:eyes(0.24, 0.40, 0.30, 0.14)
			c:box(Vector3.new(0.26, 0.08, 0.06), CFrame.new(0, -0.06, 0.37), INK)
		end,
	}

	return S
end
