--[[ PetBodies/CrystalHollowExtra -- more Crystal Hollow recolour bodies (Common,
	Uncommon, Rare): two cave formations, a dripping stalactite and a bubbly
	botryoidal cluster. See tools/gen/sets/README.md. ]]
return function(K)
	local C3, block = K.C3, K.block
	local WHITE, GLASS, SLATE, INK = K.WHITE, K.GLASS, K.SLATE, K.INK
	local V, CF, A = Vector3.new, CFrame.new, CFrame.Angles
	local BLUSH = C3(255, 150, 160)
	local S = {}

	-- A stalactite hanging from a chunk of cave ceiling: a long point with a
	-- face, growth rings, and a drop of water forming at its tip.
	S.ch_stalactite = {
		label = "Drip Stalactite",
		set = "crystal_hollow",
		tint = C3(222, 196, 150),
		scale = 1.10,
		head = CF(0, 1.40, 0),
		neck = CF(0, -0.40, 0.66),
		back = CF(0, 0.40, -0.66),
		build = function(c, p)
			c:box(V(2.00, 0.50, 1.60), CF(0, 1.10, 0) * A(0, 0.2, 0.04), p.dark, SLATE)
			c:box(V(1.10, 0.30, 0.90), CF(-0.40, 1.42, -0.10) * A(0, -0.3, 0), p.deep, SLATE)
			c:box(V(1.30, 1.00, 1.20), CF(0, 0.40, 0), p.base)
			c:cone(V(1.30, 1.30, 1.20), CF(0, -0.75, 0) * A(math.pi, 0, 0), p.base)
			c:box(V(1.36, 0.08, 1.26), CF(0, 0.74, 0), p.light)
			c:box(V(1.20, 0.08, 1.10), CF(0, -0.18, 0), p.light)
			c:eyes(0.44, 0.66, 0.28, 0.14)
			c:box(V(0.24, 0.08, 0.06), CF(0, 0.12, 0.62), INK)
			for _, s in ipairs({ -1, 1 }) do
				c:box(V(0.20, 0.10, 0.04), CF(0.44 * s, 0.26, 0.62), BLUSH)
				-- Soda-straw stalactites growing beside it.
				c:cone(V(0.14, 0.50, 0.14), CF(0.86 * s, 0.60, 0.30 - 0.50 * s) * A(math.pi, 0, 0), p.pale)
			end
			c:ball(V(0.20, 0.26, 0.20), CF(0, -1.52, 0), C3(170, 220, 255), GLASS)
		end,
	}

	-- Botryoidal: "like a bunch of grapes". Malachite and hematite grow as
	-- glossy round bubbles; this blob is made of them.
	S.ch_botryoid = {
		label = "Botryoid Blob",
		set = "crystal_hollow",
		tint = C3(40, 160, 110),
		head = CF(0, 1.20, 0),
		neck = CF(0, -0.30, 0.70),
		back = CF(0, 0.40, -0.80),
		build = function(c, p)
			block(c, p, {
				shape = "round", bodySize = V(1.70, 1.50, 1.60),
				eyeSize = V(0.38, 0.46, 0.20), eyeSpread = 0.36, eyeY = 0.12,
				mouthSize = V(0.24, 0.12, 0.12), mouthY = -0.28,
				legSize = V(0.40, 0.26, 0.40), legY = -0.74, legColor = p.dark, tail = false,
			})
			for i, b in ipairs({
				{ 0, 0.80, -0.10, 0.60 }, { -0.50, 0.72, 0.20, 0.44 }, { 0.50, 0.74, -0.30, 0.50 }, { -0.86, 0.30, -0.20, 0.50 },
				{ 0.88, 0.20, 0.10, 0.44 }, { -0.60, -0.10, -0.70, 0.50 }, { 0.50, 0.20, -0.78, 0.56 }, { 0, 0.50, -0.64, 0.50 },
			}) do
				c:ball(V(b[4], b[4], b[4]), CF(b[1], b[2], b[3]), i % 3 == 0 and p.pale or (i % 2 == 0 and p.light or p.base), GLASS)
			end
			c:ball(V(0.10, 0.10, 0.06), CF(-0.10, 1.04, 0.00), WHITE)
		end,
	}

	return S
end
